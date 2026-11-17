printf '\nb18 review round: a failed run never folds as zero, an incomplete session is never followed, a failed lookup is never clear (blind)\n'
# Written blind on 2026-10-26 from the contract's "Review round" section (R1 to R3) and the reviewer's
# three scenarios, without reading hooks/post-tool, lib/ledger.sh, lib/monitor.sh, lib/status.sh or
# felix. Each name begins with its item. An item marked (control) holds before the fix as after it;
# every other one is red on the tree the review read (942ca2db).
#
# Fixtures. Everything is under $TMP/b18-review: the homes, a memory root of this part's own, a user
# home with no plugin registry, and copies of the fixture's harness with one library left out. Nothing
# is put in $FROOT or $MEM. R1c holds post-tool to one process (ulimit -u 1), as part 1500 holds its
# pins. Root ignores that limit, so there R1c is skipped, and so are R3a to R3d, whose mode-000
# folders root can read. R1c's run goes in the background and is waited for at most 60 s. It is
# stopped (its own pid, nothing else) once its alive line is in the state file, because bash 5 retries
# a failed fork for about fifteen seconds; a run still going at 60 s is named in the assertion.
#
# Readings, where the contract leaves room: a fixed post-tool might still record the Skill call in
# spite of the failure, and the fold would then hold the play as reached. That is no measured zero
# either, so R1 asserts that a row for the play exists and that none has CALLS 0.

RV="$TMP/b18-review"; RVU="$RV/u"; RVM="$RV/mem"
mkdir -p "$RVU" "$RVM" "$RV/cwd" "$RV/aux"
_rv_play=superpowers:test-driven-development
_rv_bash() { printf '{"session_id":"%s","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"ls"}}' "$1"; }
_rv_skill() { printf '{"session_id":"%s","hook_event_name":"PostToolUse","tool_name":"Skill","tool_input":{"skill":"%s"}}' "$1" "$_rv_play"; }

_rv_pt() {   # HOOK FELIX_HOME PAYLOAD: one post-tool run, its payload handed from a file
  printf '%s' "$3" > "$RV/aux/payload"
  ( cd "$RV/cwd" && env -u FELIX_HOME_DIR FELIX_HOME="$2" HOME="$RVU" "$1" ) \
    < "$RV/aux/payload" > "$RV/aux/pt.out" 2> "$RV/aux/pt.err"
  return 0
}
_rv_lib() {  # COMMAND ARGS...: run with resolve.sh and ledger.sh sourced, FELIX_MEMORY this part's, HOME=RVU
  ( export FELIX_MEMORY="$RVM"; HOME="$RVU"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
    "$@" ) 2>/dev/null
}
_rv_alive() { [ -f "$1" ] || { printf '0'; return 0; }; LC_ALL=C awk -F'\t' '$1 == "alive" { n++ } END { print n + 0 }' "$1"; }

# ---- R1: a run that cannot load a library or cannot fork never leaves a measured zero -------------
# A case TAG is a home RV/TAG whose project TAG declares B6's one row. Session TAG is named the play by
# the prompt hook's writer, then one Bash call goes through the real post-tool; the Skill call for the
# play is the run that fails. _rv_sum folds the session and says what the fold holds for the play.
_rv_case() {
  mkdir -p "$RV/$1/projects/$1"
  printf 'plugin\tother@x\t-\tlow\talways\n' > "$RV/$1/projects/$1/stack.tsv"
  _rv_lib felix_ledger_note_named "$RV/$1" "$1" "$_rv_play" >/dev/null
  _rv_pt "$FROOT/harness/hooks/post-tool" "$RV/$1" "$(_rv_bash "$1")"
}
_rv_sum() {
  local f="$RVM/$1/ledger.d/$1.tsv"
  _rv_lib felix_ledger_rollup "$RV/$1/projects/$1" "$RV/$1" "$1" 2026-10-01 >/dev/null
  [ -f "$f" ] || { printf 'no fold at %s' "${f#$RV/}"; return 0; }
  LC_ALL=C awk -F'\t' -v p="$_rv_play" '
    $4 == p { n++; if ($5 == "0") z++ }
    $3 == "tool" && $4 == "Bash" { b = $5 "/" $6 }
    END { printf "rows for the play: %s, at 0 calls: %d; tool Bash: %s", (n ? "present" : "absent"), z + 0, (b == "" ? "none" : b) }' "$f"
}
_rv_want='rows for the play: present, at 0 calls: 0; tool Bash: 1/0'
_rv_copy() {   # NAME MISSING: RV/NAME/harness, the fixture's harness without tests/ and without lib/MISSING
  local d="$RV/$1/harness" e
  mkdir -p "$d/lib"
  for e in "$FROOT/harness/"*; do
    case "${e##*/}" in tests|lib) ;; *) cp -R "$e" "$d/" ;; esac
  done
  for e in "$FROOT/harness/lib/"*; do [ "${e##*/}" = "$2" ] || cp -R "$e" "$d/lib/"; done
}

_rv_copy eng-whole ""; _rv_case r1w
_rv_pt "$RV/eng-whole/harness/hooks/post-tool" "$RV/r1w" "$(_rv_skill r1w)"
is "b18 R1 (control): a whole copy of the harness, made as R1a's is, records the Skill call, so the copy is not the failure" \
   "$(_rv_sum r1w)" "$_rv_want"

_rv_copy eng-noledger ledger.sh; _rv_case r1a
_rv_pt "$RV/eng-noledger/harness/hooks/post-tool" "$RV/r1a" "$(_rv_skill r1a)"
is "b18 R1a (M1): the Skill run from a harness whose lib/ledger.sh will not load leaves the play unknown or reached, never at 0 calls" \
   "$(_rv_sum r1a)" "$_rv_want"

_rv_copy eng-noresolve resolve.sh; _rv_case r1b
_rv_pt "$RV/eng-noresolve/harness/hooks/post-tool" "$RV/r1b" "$(_rv_skill r1b)"
is "b18 R1b (M1): the Skill run from a harness whose lib/resolve.sh will not load leaves the play unknown or reached, never at 0 calls" \
   "$(_rv_sum r1b)" "$_rv_want"

# R1c. The method's own control first, which forks nothing: held to one process, a shell can still
# exec a command. Where that fails the assertion is skipped rather than read as the hook's failure.
_rv_probe() { ( ulimit -u 1 2>/dev/null || { printf '(unlimited)'; exit 0; }; exec env printf probe ) 2>/dev/null; }
_rv_nf=""
if [ "${EUID:-0}" -eq 0 ]; then _rv_nf="root ignores the process limit"
else
  case "$(_rv_probe)" in
    probe) ;;
    "(unlimited)") _rv_nf="processes cannot be limited here" ;;
    *) _rv_nf="a process held to one cannot exec a command here" ;;
  esac
fi
_rv_starved() {   # TAG: the Skill run for session TAG, held to one process, waited for at most 60 s
  _rv_skill "$1" > "$RV/aux/starved.json"
  (
    f="$RV/$1/state/ledger/$1.tsv"; base="$(_rv_alive "$f")"; n=0
    ( cd "$RV/cwd" && ulimit -u 1 2>/dev/null \
        && exec env -u FELIX_HOME_DIR FELIX_HOME="$RV/$1" HOME="$RVU" "$FROOT/harness/hooks/post-tool" ) \
      < "$RV/aux/starved.json" > "$RV/aux/starved.out" 2> "$RV/aux/starved.err" &
    pid=$!
    while kill -0 "$pid" 2>/dev/null; do
      [ "$(_rv_alive "$f")" -gt "$base" ] && break
      if [ "$n" -ge 60 ]; then printf '; post-tool held to one process was still running after 60 s' > "$RV/aux/starved.hang"; break; fi
      sleep 1; n=$((n + 1))
    done
    kill -KILL "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  ) 2>/dev/null
  return 0
}
if [ -n "$_rv_nf" ]; then
  skip "b18 R1c (M1): the Skill run held to one process, so it cannot fork, leaves the play unknown or reached, never at 0 calls" "$_rv_nf"
else
  _rv_case r1c; _rv_starved r1c
  is "b18 R1c (M1): the Skill run held to one process, so it cannot fork, leaves the play unknown or reached, never at 0 calls" \
     "$(_rv_sum r1c)$(cat "$RV/aux/starved.hang" 2>/dev/null)" "$_rv_want"
fi

# ---- R2: compliance never reads an incomplete session as followed --------------------------------
_rv_cmp() {   # PROJECT-DIR: felix_monitor_compliance over this part's memory root
  ( export FELIX_MEMORY="$RVM"; HOME="$RVU"; . "$FROOT/harness/lib/resolve.sh"
    . "$FROOT/harness/lib/monitor.sh"; . "$FROOT/harness/lib/ledger.sh"; felix_monitor_compliance "$1" ) 2>/dev/null
}
# R2a, by hand, project b18x: x1 complete; x2 the shape an incomplete fold has (the reached row counted,
# the unreached one -); x3 a known 0 beside a - (the mix B13's c1 had); x4 only an unknown row.
mkdir -p "$RV/q/b18x" "$RVM/b18x/ledger.d"
printf 'x1\t2026-10-01\tskill\tsuperpowers:brainstorming\t1\t1\nx1\t2026-10-01\tnamed\tcode-review\t0\t1\n' > "$RVM/b18x/ledger.d/x1.tsv"
printf 'x2\t2026-10-01\tskill\tsuperpowers:brainstorming\t1\t1\nx2\t2026-10-01\tnamed\tcode-review\t-\t1\n' > "$RVM/b18x/ledger.d/x2.tsv"
printf 'x3\t2026-10-01\tplugin\tfollowed@x\t4\t2\nx3\t2026-10-01\tplugin\tign@x\t0\t3\nx3\t2026-10-01\tnamed\tunk\t-\t2\n' > "$RVM/b18x/ledger.d/x3.tsv"
printf 'x4\t2026-10-01\tnamed\tonlyunk\t-\t1\n' > "$RVM/b18x/ledger.d/x4.tsv"
is "b18 R2a (M2): compliance prints no line for a session that holds an unknown row, whatever its known rows say, and still prints a complete one" \
   "$(_rv_cmp "$RV/q/b18x")" "$(printf 'x1\t2026-10-01\t2\t1\t1')"

# R2b, through the rollup, project b18s (no declared rows): S2 is the reviewer's session, whose last
# post-tool run died after its alive line; S3 is the same session without that run.
mkdir -p "$RV/s/projects/b18s" "$RV/s/state/ledger"; : > "$RV/s/projects/b18s/stack.tsv"
printf 'named\tsuperpowers:brainstorming\nnamed\tcode-review\nalive\tpost-tool\nskill\tsuperpowers:brainstorming\nalive\tpost-tool\ntool\tRead\n' \
  > "$RV/s/state/ledger/S3.tsv"
cp "$RV/s/state/ledger/S3.tsv" "$RV/s/state/ledger/S2.tsv"; printf 'alive\tpost-tool\n' >> "$RV/s/state/ledger/S2.tsv"
_rv_lib felix_ledger_rollup "$RV/s/projects/b18s" "$RV/s" S2 2026-10-01 >/dev/null
_rv_lib felix_ledger_rollup "$RV/s/projects/b18s" "$RV/s" S3 2026-10-01 >/dev/null
_rv_f2="$(LC_ALL=C awk -F'\t' '$3 != "tool" { print $3 "/" $4 "/" $5 "/" $6 }' "$RVM/b18s/ledger.d/S2.tsv" 2>/dev/null | LC_ALL=C sort | tr '\n' ' ')"
is "b18 R2b (M2): through the rollup, a session whose last run died after its alive line prints no compliance line, and the same session complete prints 2 1 1" \
   "S2 fold: [$_rv_f2] compliance: [$(_rv_cmp "$RV/s/projects/b18s")]" \
   "S2 fold: [named/code-review/-/1 skill/superpowers:brainstorming/1/1 ] compliance: [$(printf 'S3\t2026-10-01\t2\t1\t1')]"

# ---- R3: an iCloud Drive folder that cannot be looked into makes the answer unknown, not clear ----
_rv_C0='no name shaped like an iCloud copy under state/ and .git (objects not read)'
_rv_SN='the home is not inside iCloud Drive or an iCloud-synced Desktop or Documents'
_rv_SX='whether the home is inside an iCloud-synced folder is not known: the iCloud Drive folder could not be read'
_rv_line() { printf '%s\t%s\t%s; %s|rc=0' "$1" "$2" "$3" "$4"; }   # STATE VALUE COPIES SYNCED
_rv_md() { printf '%s/Library/Mobile Documents' "$1"; }             # U -> U/Library/Mobile Documents
_rv_lay() {   # CASE FOLDER: U is RV/ic/CASE/u, the home U/FOLDER/fh, CD/FOLDER a link to U/FOLDER
  local u="$RV/ic/$1/u"
  mkdir -p "$u/$2/fh/projects" "$u/$2/fh/state" "$u/$2/fh/.git" "$(_rv_md "$u")/com~apple~CloudDocs"
  ln -s "$u/$2" "$(_rv_md "$u")/com~apple~CloudDocs/$2"
}
_rv_ic() {   # U H: felix_icloud_state H as "<output>|rc=<status>", with HOME=U
  ( cd "$RV/cwd" && env -u FELIX_HOME_DIR -u CLAUDE_CONFIG_DIR HOME="$1" FELIX_HOME="$2" FELIX_MEMORY="$RVM" \
      "$BASH" -c '. "$1/lib/resolve.sh"; . "$1/lib/ledger.sh"; . "$1/lib/status.sh"
        _o="$(felix_icloud_state "$2")"; _r=$?; printf "%s|rc=%s" "$_o" "$_r"' _rv "$FROOT/harness" "$2" ) 2>/dev/null
}
_rv_locked() {   # U H DIR: felix_icloud_state H with DIR at mode 000 for the call, then 755 again
  chmod 000 "$3"; _rv_ic "$1" "$2"; chmod 755 "$3"
}
_rv_names=(
  "b18 R3a (M3): a home under Documents, which CD/Documents links to, with ~/Library/Mobile Documents unreadable, reads unknown, not clear"
  "b18 R3b (M3): the same home with CD itself unreadable reads unknown, not clear"
  "b18 R3c (M3): a home under a linked Desktop with ~/Library/Mobile Documents unreadable reads unknown, not clear"
  "b18 R3d (M3): with ~/Library/Mobile Documents unreadable a copy is still counted, and the detail ends saying the sync is not known"
)
if [ "$(id -u)" = 0 ]; then
  for _rv_n in "${_rv_names[@]}"; do skip "$_rv_n" "root reads a mode-000 directory"; done
else
  _rv_U="$RV/ic/r3a/u"; _rv_lay r3a Documents
  is "${_rv_names[0]}" "$(_rv_locked "$_rv_U" "$_rv_U/Documents/fh" "$(_rv_md "$_rv_U")")" \
     "$(_rv_line unknown - "$_rv_C0" "$_rv_SX")"
  _rv_U="$RV/ic/r3b/u"; _rv_lay r3b Documents
  is "${_rv_names[1]}" "$(_rv_locked "$_rv_U" "$_rv_U/Documents/fh" "$(_rv_md "$_rv_U")/com~apple~CloudDocs")" \
     "$(_rv_line unknown - "$_rv_C0" "$_rv_SX")"
  _rv_U="$RV/ic/r3c/u"; _rv_lay r3c Desktop
  is "${_rv_names[2]}" "$(_rv_locked "$_rv_U" "$_rv_U/Desktop/fh" "$(_rv_md "$_rv_U")")" \
     "$(_rv_line unknown - "$_rv_C0" "$_rv_SX")"
  _rv_U="$RV/ic/r3d/u"; _rv_lay r3d Documents; : > "$_rv_U/Documents/fh/state/x 2"
  is "${_rv_names[3]}" "$(_rv_locked "$_rv_U" "$_rv_U/Documents/fh" "$(_rv_md "$_rv_U")")" \
     "$(_rv_line value copies-1 "1 name(s) shaped like an iCloud copy under state/ and .git (objects not read): state/x 2" "$_rv_SX")"
fi
_rv_U="$RV/ic/r3e/u"; mkdir -p "$_rv_U/Documents/fh/projects" "$_rv_U/Documents/fh/state" "$_rv_U/Documents/fh/.git" "$(_rv_md "$_rv_U")"
is "b18 R3e (M3) (control): a readable ~/Library/Mobile Documents that holds no iCloud Drive folder reads clear, not unknown" \
   "$(_rv_ic "$_rv_U" "$_rv_U/Documents/fh")" "$(_rv_line value clear "$_rv_C0" "$_rv_SN")"
