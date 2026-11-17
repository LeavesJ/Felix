printf '\nb18: a dead PostToolUse hook reads as unknown, not zero (blind)\n'
# Written blind on 2026-10-24 from docs/2026-10-24-audit-fixes/b18-ledger-reads-dead-hooks-and-icloud-
# dupli.md alone (sections 2 to 5, A1 to A27), before the fix and without reading hooks/post-tool,
# lib/ledger.sh, lib/monitor.sh or felix. One assertion per contract item, and each name begins with its
# item and the behaviour it pins. An item marked (control) holds before the fix as after it; every other
# one is red on the tree the contract was written against.
#
# Fixtures. Everything is under $TMP/b18-ledger: the homes the hook runs and the rollups use, a memory
# root of this part's own for their folds, and a user home with no plugin registry (HOME in every run,
# so nothing reads the machine's ~/.claude). The readers of B11 to B14 read projects b18q, b18k and
# b18u, which live in $FROOT/projects with their rows in $MEM, as A24 places them, because felix ledger
# reads them there; they are removed at the end, so $FROOT and $MEM are left as this part found them.
# The hook is handed its payload from a file, so a hook that exits before reading stdin cannot turn a
# printf's broken pipe into the run's status.
#
# Readings, where the contract leaves room: a state file's lines end in a newline, so "exactly" compares
# bytes, the last newline included; the felix ledger runs merge stderr into stdout, as part 0330's do;
# compliance's c2 row is dated 2026-08-02 (the contract gives it none).

B18L="$TMP/b18-ledger"; B18LU="$B18L/u"; B18LM="$B18L/mem"
mkdir -p "$B18LU" "$B18LM" "$B18L/cwd" "$B18L/aux"

# A file's bytes with a | after them, so a missing last newline shows; or "no file".
_lu_cat() { if [ -f "$1" ]; then cat "$1"; printf '|'; else printf 'no file at %s' "${1#$B18L/}"; fi; }
# Lines, one an argument, with \t read as a tab; $( ) drops the last newline.
_lu_want() { printf '%b\n' "$@"; }
_lu_bash() { printf '{"session_id":"%s","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"ls"}}' "$1"; }

# post-tool, once: TAG FELIX_HOME PAYLOAD. Anything but exit 0 with both streams empty is noted in _lu_noise.
_lu_noise=""
_lu_pt() {
  local rc
  printf '%s' "$3" > "$B18L/aux/payload"
  ( cd "$B18L/cwd" && env -u FELIX_HOME_DIR FELIX_HOME="$2" HOME="$B18LU" "$FROOT/harness/hooks/post-tool" \
      < "$B18L/aux/payload" > "$B18L/aux/pt.out" 2> "$B18L/aux/pt.err" ); rc=$?
  if [ "$rc" != 0 ] || [ -s "$B18L/aux/pt.out" ] || [ -s "$B18L/aux/pt.err" ]; then
    _lu_noise="$_lu_noise [$1: exit $rc, stdout $(wc -c < "$B18L/aux/pt.out" | tr -d ' ') byte(s), stderr: $(head -c 200 "$B18L/aux/pt.err")]"
  fi
  return 0
}

# ---- recording: A1 to A7 -------------------------------------------------------------------------
_lu_H1="$B18L/h1"; mkdir -p "$_lu_H1"
_lu_pt A1 "$_lu_H1" "$(_lu_bash pt1)"
is "b18 A1 (B1): post-tool makes state/ledger in a home that has none, and writes the alive line, then tool Bash" \
   "$(_lu_cat "$_lu_H1/state/ledger/pt1.tsv")" "$(printf 'alive\tpost-tool\ntool\tBash\n|')"

_lu_H2="$B18L/h2"; mkdir -p "$_lu_H2"
_lu_pt A2a "$_lu_H2" "$(_lu_bash pt1b)"; _lu_pt A2b "$_lu_H2" "$(_lu_bash pt1b)"
is "b18 A2 (B1): two Bash runs leave four lines: alive, tool Bash, alive, tool Bash" \
   "$(_lu_cat "$_lu_H2/state/ledger/pt1b.tsv")" "$(printf 'alive\tpost-tool\ntool\tBash\nalive\tpost-tool\ntool\tBash\n|')"

_lu_H3="$B18L/h3"; mkdir -p "$_lu_H3"
_lu_pt A3 "$_lu_H3" '{"session_id":"pt2","hook_event_name":"PostToolUse"}'
is "b18 A3 (B2): a run with a session and no tool_name still leaves its alive line, and nothing else" \
   "$(_lu_cat "$_lu_H3/state/ledger/pt2.tsv")" "$(printf 'alive\tpost-tool\n|')"

# A4: B3's title is that nothing is written, so a home this run falls back to (the fixture root's own)
# gaining pt1.tsv is named as well; it is removed again if it appeared.
_lu_had=0; [ -e "$FROOT/state/ledger/pt1.tsv" ] && _lu_had=1
_lu_H4a="$B18L/h4a"; _lu_H4b="$B18L/h4b"; _lu_H4c="$B18L/h4c"; mkdir -p "$_lu_H4a" "$_lu_H4b" "$_lu_H4c"
_lu_pt A4-empty-stdin "$_lu_H4a" ""
_lu_pt A4-no-session "$_lu_H4b" '{"hook_event_name":"PostToolUse","tool_name":"Bash"}'
_lu_pt A4-missing-home "$_lu_H4c/missing" "$(_lu_bash pt1)"
_lu_o=""
for _lu_d in "$_lu_H4a" "$_lu_H4b" "$_lu_H4c"; do
  _lu_l="$(ls -A "$_lu_d/state/ledger" 2>/dev/null | tr '\n' ' ')"
  [ -z "$_lu_l" ] || _lu_o="$_lu_o [${_lu_d##*/}/state/ledger holds: $_lu_l]"
done
{ [ -e "$_lu_H4c/missing" ] || [ -L "$_lu_H4c/missing" ]; } && _lu_o="$_lu_o [h4c/missing was created]"
if [ "$_lu_had" = 0 ] && [ -e "$FROOT/state/ledger/pt1.tsv" ]; then
  _lu_o="$_lu_o [the fixture root's state/ledger gained pt1.tsv]"; rm -f "$FROOT/state/ledger/pt1.tsv"
fi
is "b18 A4 (B3) (control): empty stdin, a payload with no session_id, or a home that is not a directory writes no ledger entry and makes no missing home" \
   "$_lu_o" ""

_lu_H5="$B18L/h5"; mkdir -p "$_lu_H5"
_lu_pt A5 "$_lu_H5" '{"session_id":"s-top","hook_event_name":"PostToolUse","tool_name":"mcp__ccd_session_mgmt__get_session","tool_input":{"session_id":"local_in"},"tool_response":{"session_id":"local_out"}}'
_lu_o="$(_lu_cat "$_lu_H5/state/ledger/s-top.tsv") local_in.tsv: $([ -e "$_lu_H5/state/ledger/local_in.tsv" ] && echo exists || echo absent) local_out.tsv: $([ -e "$_lu_H5/state/ledger/local_out.tsv" ] && echo exists || echo absent)"
is "b18 A5 (B4): the payload's first session_id is the session, so an mcp call whose input and response carry session_id lands in s-top.tsv alone" \
   "$_lu_o" "$(printf 'alive\tpost-tool\nmcp\tccd_session_mgmt\n|') local_in.tsv: absent local_out.tsv: absent"

is "b18 A6 (B5) (control): every post-tool run of A1 to A5 exits 0 and prints nothing on stdout or stderr" "$_lu_noise" ""

_lu_H7="$B18L/h7"; mkdir -p "$_lu_H7"
( export FELIX_MEMORY="$B18LM"; HOME="$B18LU"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
  felix_ledger_record "$_lu_H7" r1 "$(printf 'tool\tBash')"
  felix_ledger_note_named "$_lu_H7" r1 code-review ) >/dev/null 2>&1
is "b18 A7 (B5) (control): felix_ledger_record and felix_ledger_note_named write their own lines and no alive line" \
   "$(_lu_cat "$_lu_H7/state/ledger/r1.tsv")" "$(printf 'tool\tBash\nnamed\tcode-review\n|')"

# ---- folding: A8 to A15 ----------------------------------------------------------------------------
# A case is a home of its own, $B18L/TAG, holding projects/TAG whose stack.tsv is B6's one line.
_lu_case() {
  mkdir -p "$B18L/$1/projects/$1" "$B18L/$1/state/ledger"
  printf 'plugin\tother@x\t-\tlow\talways\n' > "$B18L/$1/projects/$1/stack.tsv"
}
_lu_state() {   # TAG SID LINE...: the state file by hand, one LINE a line, \t a tab
  local f="$B18L/$1/state/ledger/$2.tsv" _l; shift 2
  : > "$f"; for _l in "$@"; do printf '%b\n' "$_l" >> "$f"; done
}
_lu_roll() {    # TAG SID: felix_ledger_rollup P H SID 2026-10-01, into this part's memory root
  ( export FELIX_MEMORY="$B18LM"; HOME="$B18LU"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
    felix_ledger_rollup "$B18L/$1/projects/$1" "$B18L/$1" "$2" 2026-10-01 ) >/dev/null 2>&1
}
_lu_fold() {    # TAG SID -> fields 3 to 6 of each row of the fold, LC_ALL=C sorted; or "no fold"
  local f="$B18LM/$1/ledger.d/$2.tsv"
  if [ -f "$f" ]; then LC_ALL=C cut -f3-6 "$f" | LC_ALL=C sort; else printf 'no fold at %s' "${f#$B18L/}"; fi
}
_lu_alive() {   # TAG SID -> how many fold rows are of KIND alive or NAME post-tool
  LC_ALL=C awk -F'\t' '$3 == "alive" || $4 == "post-tool" { n++ } END { print n + 0 }' "$B18LM/$1/ledger.d/$2.tsv" 2>/dev/null || printf 'unread'
}

_lu_case b18a8; _lu_state b18a8 s8 'alive\tpost-tool' 'tool\tBash' 'named\tsuperpowers:brainstorming'; _lu_roll b18a8 s8
is "b18 A8 (B6): a complete record with an alive line folds as today, and no fold row is the alive line" \
   "alive rows: $(_lu_alive b18a8 s8)"$'\n'"$(_lu_fold b18a8 s8)" \
   "alive rows: 0"$'\n'"$(_lu_want 'named\tsuperpowers:brainstorming\t0\t1' 'plugin\tother@x\t0\t0' 'tool\tBash\t1\t0')"

_lu_case b18a9; _lu_state b18a9 s9 'named\tsuperpowers:brainstorming'; _lu_roll b18a9 s9
is "b18 A9 (B7): a record with nothing from PostToolUse folds its named row and its declared row as unknown" \
   "$(_lu_fold b18a9 s9)" "$(_lu_want 'named\tsuperpowers:brainstorming\t-\t1' 'plugin\tother@x\t-\t0')"

_lu_case b18a10
_lu_state b18a10 s10 'alive\tpost-tool' 'alive\tpost-tool' 'skill\tsuperpowers:test-driven-development' 'named\tcode-review'
_lu_roll b18a10 s10
is "b18 A10 (B8): two alive lines and one call line fold every unreached row as unknown, and the call keeps its count" \
   "$(_lu_fold b18a10 s10)" \
   "$(_lu_want 'named\tcode-review\t-\t1' 'plugin\tother@x\t-\t0' 'skill\tsuperpowers:test-driven-development\t1\t0')"

_lu_case b18a11
( export FELIX_MEMORY="$B18LM"; HOME="$B18LU"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
  felix_ledger_note_named "$B18L/b18a11" s11 code-review ) >/dev/null 2>&1
_lu_pt A11-bash "$B18L/b18a11" "$(_lu_bash s11)"
_lu_pt A11-no-tool "$B18L/b18a11" '{"session_id":"s11","hook_event_name":"PostToolUse"}'
_lu_roll b18a11 s11
is "b18 A11 (B8): note_named, a Bash post-tool run and a run with no tool_name, then the rollup, fold the unreached rows as unknown and no alive row" \
   "alive rows: $(_lu_alive b18a11 s11)"$'\n'"$(_lu_fold b18a11 s11)" \
   "alive rows: 0"$'\n'"$(_lu_want 'named\tcode-review\t-\t1' 'plugin\tother@x\t-\t0' 'tool\tBash\t1\t0')"

_lu_case b18a12; _lu_state b18a12 s12 'tool\tBash' 'named\tcode-review'; _lu_roll b18a12 s12
is "b18 A12 (B9) (control): a record from before the alive line, with a call line, is complete and folds with zeros" \
   "$(_lu_fold b18a12 s12)" "$(_lu_want 'named\tcode-review\t0\t1' 'plugin\tother@x\t0\t0' 'tool\tBash\t1\t0')"

_lu_case b18a13; _lu_state b18a13 s13 'tool\tRead' 'alive\tpost-tool' 'tool\tBash' 'named\tcode-review'; _lu_roll b18a13 s13
is "b18 A13 (B9): a resumed record with more call lines than alive lines is complete, folds with zeros, and has no alive row" \
   "alive rows: $(_lu_alive b18a13 s13)"$'\n'"$(_lu_fold b18a13 s13)" \
   "alive rows: 0"$'\n'"$(_lu_want 'named\tcode-review\t0\t1' 'plugin\tother@x\t0\t0' 'tool\tBash\t1\t0' 'tool\tRead\t1\t0')"

_lu_case b18a14; _lu_state b18a14 s14 'named\tsuperpowers:brainstorming'; _lu_roll b18a14 s14
_lu_f="$B18LM/b18a14/ledger.d/s14.tsv"
if [ -f "$_lu_f" ]; then
  cp "$_lu_f" "$B18L/aux/a14.first"; _lu_roll b18a14 s14
  if cmp -s "$B18L/aux/a14.first" "$_lu_f"; then _lu_o="byte-identical"; else _lu_o="the second fold differs: $(cat "$_lu_f")"; fi
else _lu_o="no fold after the first rollup"; fi
is "b18 A14 (B9) (control): rolling the B7 record twice leaves a byte-identical fold" "$_lu_o" "byte-identical"

# A15: a repository R with one commit; the session's mark holds R's HEAD; state/ledger holds only s15.tsv.
_lu_R="$B18L/r15"; mkdir -p "$_lu_R"
( _fx_cd "$_lu_R" && git init -q -b main && printf 'b18 r15\n' > r15.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm "b18 A15 repository" ) >/dev/null 2>&1
_lu_R="$(cd "$_lu_R" && pwd -P)"; _lu_head="$(git -C "$_lu_R" rev-parse HEAD 2>/dev/null)"
_lu_case b18a15; mkdir -p "$B18L/b18a15/state/session"
printf '%s\n' "$_lu_head" > "$B18L/b18a15/state/session/s15"
_lu_state b18a15 s15 'alive\tpost-tool' 'named\tcode-review'; _lu_roll b18a15 s15
_lu_first="$(_lu_fold b18a15 s15)"
touch -t 202601010000 "$B18LM/b18a15/ledger.d/s15.tsv" 2>/dev/null
printf 'tool\tBash\n' >> "$B18L/b18a15/state/ledger/s15.tsv"
_lu_lgx() {   # FUNCTION: FUNCTION P H R for the A15 case
  ( export FELIX_MEMORY="$B18LM"; HOME="$B18LU"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
    "$1" "$B18L/b18a15/projects/b18a15" "$B18L/b18a15" "$_lu_R" ) 2>/dev/null
}
_lu_str="$(_lu_lgx felix_ledger_stranded)"; _lu_cat15="$(_lu_lgx felix_ledger_catchup)"
is "b18 A15 (B10): an unknown fold clears when the late call line lands: stranded 1, catch-up 1, then zeros and the call" \
   "head: $([ -n "$_lu_head" ] && echo made || echo none)"$'\n'"first: $_lu_first"$'\n'"stranded: $_lu_str, catch-up: $_lu_cat15"$'\n'"final: $(_lu_fold b18a15 s15)" \
   "head: made"$'\n'"first: $(_lu_want 'named\tcode-review\t-\t1' 'plugin\tother@x\t-\t0')"$'\n'"stranded: 1, catch-up: 1"$'\n'"final: $(_lu_want 'named\tcode-review\t0\t1' 'plugin\tother@x\t0\t0' 'tool\tBash\t1\t0')"

# ---- reading: A16 to A27 ---------------------------------------------------------------------------
# The B11 fixture: project b18q (no stack.tsv), its rows in $MEM/b18q/ledger.d, one file a session, all
# dated 2026-10-01. b18k holds alpha's rows only and b18u beta's only. Each is a project under $FROOT,
# so a checkout can be bound to it for felix ledger.
_lu_proj() {
  mkdir -p "$FROOT/projects/$1" "$MEM/$1/ledger.d"
  printf '{"name": "%s", "remote_match": "example.com/%s", "gate": "true"}\n' "$1" "$1" > "$FROOT/projects/$1/project.json"
  printf '# %s\n' "$1" > "$FROOT/projects/$1/CLAUDE.md"
}
_lu_row() {   # PROJECT SID KIND NAME CALLS NAMED
  printf '%s\t2026-10-01\t%s\t%s\t%s\t%s\n' "$2" "$3" "$4" "$5" "$6" >> "$MEM/$1/ledger.d/$2.tsv"
}
for _lu_p in b18q b18k b18u; do _lu_proj "$_lu_p"; done
for _lu_i in 1 2 3 4 5; do
  _lu_row b18q "k$_lu_i" named alpha 0 1; _lu_row b18k "k$_lu_i" named alpha 0 1
  _lu_row b18q "u$_lu_i" named beta - 1;  _lu_row b18u "u$_lu_i" named beta - 1
done
for _lu_i in 1 2 3 4; do _lu_row b18q "g$_lu_i" named gamma 0 1; done
_lu_row b18q g5 named gamma - 1
_lu_row b18q d1 plugin delta@x 0 0; _lu_row b18q d2 plugin delta@x 0 0; _lu_row b18q d3 named delta - 1
_lu_row b18q e1 plugin epsilon@x 0 0; _lu_row b18q e2 plugin epsilon@x - 0
_lu_row b18q m1 mcp ctx - 1; _lu_row b18q m2 mcp ctx 3 0
B18Q="$FROOT/projects/b18q"; B18K="$FROOT/projects/b18k"; B18U="$FROOT/projects/b18u"

_lu_read() {   # FUNCTION PROJECT: a ledger reader over the suite's memory root, with this part's user home
  ( HOME="$B18LU"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"; "$1" "$2" ) 2>/dev/null
}
_lu_retire() {   # MIN: felix_ledger_retire over b18q with FELIX_LEDGER_MIN=MIN
  ( export FELIX_LEDGER_MIN="$1"; HOME="$B18LU"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
    felix_ledger_retire "$B18Q" ) 2>/dev/null
}

is "b18 A16 (B11): felix_ledger_summary reads known rows only, and a capability with only unknown rows gets no line" \
   "$(_lu_read felix_ledger_summary "$B18Q")" \
   "$(_lu_want 'alpha\t5\t0\t5' 'ctx\t1\t3\t0' 'delta\t2\t0\t0' 'epsilon\t1\t0\t0' 'gamma\t4\t0\t4')"

_lu_o="MIN 5: [$(_lu_retire 5)] MIN 4: [$(_lu_retire 4)] lines beginning delta at MIN 3: $(_lu_retire 3 | LC_ALL=C awk 'index($0, "delta") == 1 { n++ } END { print n + 0 }')"
is "b18 A17 (B11): retire lists alpha at MIN 5, alpha and gamma at MIN 4, and not delta at MIN 3, since unknown rows are no evidence of disuse" \
   "$_lu_o" "MIN 5: [$(_lu_want 'alpha\t5\t5')] MIN 4: [$(_lu_want 'alpha\t5\t5' 'gamma\t4\t4')] lines beginning delta at MIN 3: 0"

is "b18 A18 (B11): felix_ledger_mcp counts the known mcp row only" "$(_lu_read felix_ledger_mcp "$B18Q")" "$(_lu_want 'ctx\t1\t3\t0')"

is "b18 A19 (B11) (control): felix_ledger_sessions still counts all 22 sessions, unknown ones included" \
   "$(_lu_read felix_ledger_sessions "$B18Q")" "22"

_lu_unr="$(_lu_read felix_ledger_unrouted "$B18Q")"
is "b18 A20 (B12): felix_ledger_unrouted lists epsilon on its one known row, and nothing an unknown row names" \
   "$_lu_unr" "$(_lu_want 'epsilon\t1')"
is "b18 A21 (B12) (control): felix_ledger_unrouted never lists delta, which an unknown row names" \
   "$(printf '%s\n' "$_lu_unr" | LC_ALL=C awk 'index($0, "delta") == 1 { n++ } END { print n + 0 }')" "0"

# B13: project Q2 is b18c, read from this part's memory root. Review round (R2): c1 no longer holds
# `named unk - 2`. A session with an unknown row now prints no line at all, and the rollup never puts a
# `-` row beside a known `0` one, so part 1985 (R2a) pins that mix instead.
_lu_Q2="$B18L/q2/b18c"; mkdir -p "$_lu_Q2" "$B18LM/b18c/ledger.d"
printf 'c1\t2026-08-01\tplugin\tfollowed@x\t4\t2\nc1\t2026-08-01\tplugin\tign@x\t0\t3\n' \
  > "$B18LM/b18c/ledger.d/c1.tsv"
printf 'c2\t2026-08-02\tnamed\tonlyunk\t-\t1\n' > "$B18LM/b18c/ledger.d/c2.tsv"
is "b18 A22 (B13): compliance counts known rows only, and a session whose named rows are all unknown prints no line" \
   "$( ( export FELIX_MEMORY="$B18LM"; HOME="$B18LU"; . "$FROOT/harness/lib/resolve.sh"
         . "$FROOT/harness/lib/monitor.sh"; . "$FROOT/harness/lib/ledger.sh"; felix_monitor_compliance "$_lu_Q2" ) 2>/dev/null )" \
   "$(_lu_want 'c1\t2026-08-01\t2\t1\t1')"

is "b18 A23 (B14): felix_ledger_unknown counts the 9 sessions that hold an unknown row, and 0 where none does" \
   "$(_lu_read felix_ledger_unknown "$B18Q") $(_lu_read felix_ledger_unknown "$B18K")" "9 0"

# felix ledger, in a checkout whose root .felix binds it to the project: PROJECT -> $B18L/aux/ledger-PROJECT.out,
# and its exit status in _lu_lrc.
_lu_ledger() {
  local c="$B18L/chk-$1"
  mkdir -p "$c"
  ( _fx_cd "$c" && git init -q -b main && printf '%s\n' "$1" > .felix && printf 'b18 %s\n' "$1" > b18.txt \
    && git add -A && git -c user.name=t -c user.email=t@t commit -qm "b18 checkout bound to $1" ) >/dev/null 2>&1
  c="$(cd "$c" && pwd -P)"
  ( cd "$c" && HOME="$B18LU" PATH="/usr/bin:/bin" "$FELIX" ledger ) > "$B18L/aux/ledger-$1.out" 2>&1; _lu_lrc=$?
}
_lu_begins() {   # FILE PREFIX [ALSO]: how many lines begin with PREFIX (and hold ALSO)
  LC_ALL=C awk -v p="$2" -v a="${3:-}" 'index($0, p) == 1 && (a == "" || index($0, a)) { n++ } END { print n + 0 }' "$1" 2>/dev/null || printf 'unread'
}
_lu_ledger b18q; _lu_rq="$_lu_lrc"; _lu_oq="$B18L/aux/ledger-b18q.out"
is "b18 A24 (B14a): felix ledger exits 0 and prints one line beginning unknown, not zero: 9 session(s), which says incomplete" \
   "exit $_lu_rq; lines beginning it: $(_lu_begins "$_lu_oq" 'unknown, not zero: 9 session(s)'); of them saying incomplete: $(_lu_begins "$_lu_oq" 'unknown, not zero: 9 session(s)' incomplete)" \
   "exit 0; lines beginning it: 1; of them saying incomplete: 1"

_lu_ledger b18k
is "b18 A25 (B14b) (control): with no unknown row felix ledger exits 0 and prints no line beginning unknown, not zero:" \
   "exit $_lu_lrc; lines beginning it: $(_lu_begins "$B18L/aux/ledger-b18k.out" 'unknown, not zero:')" "exit 0; lines beginning it: 0"

is "b18 A26 (B14c): a capability whose rows are all unknown, beta, is not a line of felix ledger's table" \
   "$(_lu_begins "$_lu_oq" '  beta ')" "0"

_lu_ledger b18u
is "b18 A27 (B14d): when every row is unknown felix ledger exits 0, prints no nothing yet line, and says unknown, not zero: 5 session(s)" \
   "exit $_lu_lrc; nothing yet lines: $(LC_ALL=C awk '$0 == "  nothing yet" { n++ } END { print n + 0 }' "$B18L/aux/ledger-b18u.out" 2>/dev/null); lines beginning unknown, not zero: 5 session(s): $(_lu_begins "$B18L/aux/ledger-b18u.out" 'unknown, not zero: 5 session(s)')" \
   "exit 0; nothing yet lines: 0; lines beginning unknown, not zero: 5 session(s): 1"

# The projects and rows this part put in $FROOT and $MEM go; its own fixtures stay under $TMP.
rm -rf "$FROOT/projects/b18q" "$FROOT/projects/b18k" "$FROOT/projects/b18u" \
       "${MEM:?}/b18q" "${MEM:?}/b18k" "${MEM:?}/b18u"
