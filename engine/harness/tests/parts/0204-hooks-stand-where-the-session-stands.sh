# >>> hook-payload-cwd
printf '\nhooks stand where the session stands\n'
# Claude Desktop starts every session with --project-config-root naming the
# main checkout, and Claude Code then spawns every command hook with its cwd
# there, whatever directory the session works in. The session's own directory,
# a worktree as often as not, reaches a hook only as the payload's top-level
# "cwd" (measured 2026-10-02 against the real binary and a mock API). So every
# hook that resolved from $PWD judged the main checkout: a Stop hook told a
# worktree session that the gate had passed "on this exact tree" about the
# main checkout's receipt, ninety seconds after the worktree's own green one.
#
# Written from the contract alone, before any implementation existed. The
# shape is Desktop's: the hook runs in a launch directory, either PCA, a
# governed main checkout, or PCU, a checkout nothing governs, and the
# payload's cwd names PCB, a `git worktree add` of PCA on a commit of its own.
# A home and a memory of its own, set on every call, so nothing here is seen
# by a later section.
#
# The controls, where the payload's cwd equals the launch directory, is absent
# or unusable, or names a directory nothing governs, pass on the engine before
# this change by design: they are the behaviour that must not move.
PC="$TMP/payload-cwd"; mkdir -p "$PC"; PC="$(cd "$PC" && pwd -P)"
PH="$PC/home"; PM="$PC/memory"; PT="$PC/transcripts"; PX="$PC/fx"
mkdir -p "$PH/projects/pcwd" "$PH/projects/pcwdremote" "$PM/pcwd" "$PT" "$PX"
cat > "$PH/projects/pcwd/project.json" <<'EOF'
{
  "name": "pcwd",
  "remote_match": "example.invalid/pcwd-marker-only",
  "gate": "sh -c 'test -f OK.txt && echo pcwd-gate-ran'"
}
EOF
printf '# pcwd\n' > "$PH/projects/pcwd/CLAUDE.md"
# The widget's probe row. Without one every receipt carries no epoch, no green
# receipt is ever current, and every stop below would take the gate's hold.
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$PH/projects/pcwd/probes.tsv"
printf 'Bash\t(^|[;&| ])npm publish\tpcwd refuses a publish\n' > "$PH/projects/pcwd/deny.tsv"
cat > "$PH/projects/pcwdremote/project.json" <<'EOF'
{
  "name": "pcwdremote",
  "remote_match": "example.invalid/pcwd-remote"
}
EOF
printf -- '- **L1 The quokka ledger in pcwd is reconciled by hand.** Evidence would follow here.\n' \
  > "$PM/pcwd/lessons.md"

_pcwd_git() { git -c user.name=t -c user.email=t@t "$@"; }
PCA="$PX/main"; PCB="$PX/wt"; PCU="$PX/plain"; PCN="$PX/nogit"; PCK="$PX/broken"
PCR="$PX/remote"; PCQ="$PX/sealed"; PCBS="$PX/back\\slash"; PCW2="$PX/wt-broken"
mkdir -p "$PCA" "$PCU" "$PCN" "$PCK" "$PCR" "$PCQ" "$PCBS"
( _fx_cd "$PCA" && git init -q -b main && printf 'ok\n' > OK.txt && printf 'pcwd\n' > .felix \
  && git add -A && _pcwd_git commit -qm init && git worktree add -q -b side "$PCB" ) >/dev/null 2>&1
( _fx_cd "$PCB" && mkdir -p sub && printf 'kept\n' > sub/keep.txt \
  && printf '# the worktree handoff\n' > HANDOFF.md \
  && git add -A && _pcwd_git commit -qm side ) >/dev/null 2>&1
# A second worktree of the main checkout, whose marker somebody broke.
_fx_git "$PCA" worktree add -q -b broken-side "$PCW2" >/dev/null 2>&1
printf 'pcwd-no-such-project\n' > "$PCW2/.felix"
( _fx_cd "$PCU" && git init -q -b main && printf 'u\n' > u.txt && git add -A && _pcwd_git commit -qm init ) >/dev/null 2>&1
( _fx_cd "$PCK" && git init -q -b main && printf 'pcwd-no-such-project\n' > .felix \
  && git add -A && _pcwd_git commit -qm init ) >/dev/null 2>&1
( _fx_cd "$PCR" && git init -q -b main && printf 'r\n' > r.txt && git add -A && _pcwd_git commit -qm init \
  && git remote add origin https://example.invalid/pcwd-remote.git ) >/dev/null 2>&1
( _fx_cd "$PCQ"  && git init -q -b main && printf 'pcwd\n' > .felix ) >/dev/null 2>&1
( _fx_cd "$PCBS" && git init -q -b main && printf 'pcwd\n' > .felix ) >/dev/null 2>&1
# The main checkout's own handoff, untracked so the worktree does not carry it,
# and a link a relative cwd would follow from there into the worktree.
printf '# the main checkout handoff\n' > "$PCA/HANDOFF.md"
ln -s "$PCB" "$PCA/to-b"
printf 'a-edit\n' >> "$PCA/OK.txt"; printf 'b-edit\n' >> "$PCB/OK.txt"
PCHA="$(git -C "$PCA" rev-parse HEAD 2>/dev/null)"; PCHB="$(git -C "$PCB" rev-parse HEAD 2>/dev/null)"

# The platform's envelope, cwd third; a cwd of `-` leaves the key out.
_pcwd_pay() {   # event sid cwd [more fields]
  local c=""; [ "$3" = - ] || c="\"cwd\":\"$3\","
  printf '{"session_id":"%s","transcript_path":"%s/%s.jsonl",%s"permission_mode":"default","hook_event_name":"%s"%s}' \
    "$2" "$PT" "$2" "$c" "$1" "${4:+,$4}"
}
# A hook run where the platform would start it, with the fixture's own home.
_pcwd_hook() {   # launch dir, hook, payload -> stdout and stderr together
  ( cd "$1" && FELIX_HOME="$PH" FELIX_MEMORY="$PM" "$FROOT/harness/hooks/$2" <<<"$3" 2>&1 )
}
_pcwd_pre() {    # launch dir, payload -> exit status; stderr in $PC/pre.err
  ( cd "$1" && FELIX_HOME="$PH" FELIX_MEMORY="$PM" "$FROOT/harness/hooks/pre-tool" <<<"$2" >/dev/null 2>"$PC/pre.err" )
  printf '%s' "$?"
}
_pcwd_tid() { ( . "$FROOT/harness/lib/verify.sh"; felix_tree_id "$1" "$PH" ) 2>/dev/null; }
_pcwd_gate() { ( cd "$1" && FELIX_HOME="$PH" FELIX_MEMORY="$PM" "$FELIX" gate >/dev/null 2>&1 ); }
_pcwd_current() { ( . "$FROOT/harness/lib/verify.sh"; felix_verify_current "$1" "$PH" "$PH/projects/pcwd" ) 2>/dev/null | cut -f1; }
_pcwd_res() { local p; p="$( . "$FROOT/harness/lib/resolve.sh"; felix_resolve_project "$1" "$PH" 2>/dev/null )"; printf '%s' "${p##*/}"; }
# What a stop decided, and the one row it wrote: which tree it judged, and why.
_pcwd_vlog="$PM/pcwd/verification.log"
_pcwd_rows() { if [ -f "$_pcwd_vlog" ]; then awk 'END { print NR }' "$_pcwd_vlog"; else printf '0'; fi; }
_pcwd_stop() {   # launch dir, payload -> "block|silent +rows verdict tree reason"
  local n0 o
  n0="$(_pcwd_rows)"; o="$(_pcwd_hook "$1" stop "$2")"
  case "$o" in
    *'"decision"'*'"block"'*) printf 'block' ;;
    '')                       printf 'silent' ;;
    *)                        printf 'other[%s]' "$(printf '%s' "$o" | head -c 200)" ;;
  esac
  printf ' +%s %s' "$(( $(_pcwd_rows) - n0 ))" "$(tail -1 "$_pcwd_vlog" 2>/dev/null | cut -f2-4 | tr '\t' ' ')"
}
_pcwd_sp() { _pcwd_pay Stop "$1" "$2" '"stop_hook_active":false'; }

if [ -f "$PCB/.git" ] && [ -f "$PCW2/.git" ] && [ -n "$PCHB" ] && [ "$PCHA" != "$PCHB" ] \
   && [ "$(cd "$(git -C "$PCB" rev-parse --git-common-dir 2>/dev/null)" 2>/dev/null && pwd -P)" = "$PCA/.git" ]; then
  ok  "the payload-cwd fixture has a main checkout and a worktree of it on a commit of its own"
else
  bad "the payload-cwd fixture has a main checkout and a worktree of it on a commit of its own" \
      "worktree [$PCB] heads [$PCHA] [$PCHB]"
fi
is "and in its own home the checkouts resolve as the cases below assume" \
   "$(_pcwd_res "$PCA") $(_pcwd_res "$PCB") $(_pcwd_res "$PCR") $(_pcwd_res "$PCBS") [$(_pcwd_res "$PCU")] [$(_pcwd_res "$PCK")] [$(_pcwd_res "$PCW2")] [$(_pcwd_res "$PCN")]" \
   "pcwd pcwd pcwdremote pcwd [] [] [] []"
chmod 000 "$PCQ/.felix"

# ---- felix_hook_dir, rule by rule (C1). Each answer is the directory printed,
# a dot, the status, a bar, and whatever reached stderr, so one case checks
# that it prints one directory with no newline, returns 0 and says nothing.
# The suite's FELIX_HOME still names the widget home, so the remote-bound case
# can only pass where the function resolves in the home it is handed.
_pcwd_hd() {   # stand-in dir, payload
  ( cd "$1" || exit 0
    . "$FROOT/harness/lib/resolve.sh"
    o="$(felix_hook_dir "$2" "$PH" 2>"$PC/hd.err"; printf '.%s' "$?")"
    printf '%s|%s' "$o" "$(cat "$PC/hd.err" 2>/dev/null)" )
}
_pcwd_hdp() { _pcwd_pay PreToolUse hd "$1" '"tool_name":"Bash","tool_input":{"command":"true"},"tool_use_id":"toolu_hd"'; }
is "felix_hook_dir prints the payload's worktree when its marker names a project" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCB")")" "$PCB.0|"
is "felix_hook_dir prints a subdirectory of that worktree as given, not its root" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCB/sub")")" "$PCB/sub.0|"
is "felix_hook_dir prints a checkout whose marker is broken, since Felix has that to say about it" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCK")")" "$PCK.0|"
# Launched where nothing governs: Amendment 1 keeps a governed launch directory
# when the candidate's project is another one, and round two asserts that.
is "felix_hook_dir prints a checkout bound by its remote alone, resolved in the home it is handed, when the launch directory governs nothing" \
   "$(_pcwd_hd "$PCU" "$(_pcwd_hdp "$PCR")")" "$PCR.0|"
is "felix_hook_dir prints a checkout whose marker cannot be read, and writes nothing to stderr about it" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCQ")")" "$PCQ.0|"
is "felix_hook_dir keeps the launch directory for a git checkout nothing governs" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCU")")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory for a plain directory nothing governs" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCN")")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory when the payload's cwd is empty" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "")")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory when the payload carries no cwd" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp -)")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory for a relative cwd, though from there it names a governed worktree" \
   "$(_pcwd_hd "$PX" "$(_pcwd_hdp wt)")" "$PX.0|"
is "felix_hook_dir keeps the launch directory for a cwd spelt with escaped slashes, which it does not decode" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$(printf '%s' "$PCB" | sed 's|/|\\/|g')")")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory for a cwd holding a backslash, though that directory exists and is governed" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCBS")")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory for an escaped backslash that only decoding would make a governed directory" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PX/back\\\\slash")")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory for a cwd that does not exist" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCB/no-such-directory")")" "$PCA.0|"
is "felix_hook_dir keeps the launch directory for a cwd naming a file inside a governed worktree" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCB/OK.txt")")" "$PCA.0|"
# Payloads holding a brace and a comma are built in an assignment first: bash
# 3.2 brace-expands such a word inside "$(...)" in a command's arguments, and
# the assertion then compares two halves of a payload with each other.
_pcwd_p="{\"session_id\":\"hd\",\"transcript_path\":\"$PT/hd.jsonl\",\"cwd\" :  \"$PCB\",\"hook_event_name\":\"Stop\"}"
is "felix_hook_dir reads the top-level cwd with whitespace around its colon" "$(_pcwd_hd "$PCU" "$_pcwd_p")" "$PCB.0|"
_pcwd_p="$(_pcwd_pay PreToolUse hd "$PCU" "\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"true\",\"cwd\":\"$PCB\"}")"
is "felix_hook_dir reads the leftmost cwd: a governed directory named again inside tool_input does not move it" \
   "$(_pcwd_hd "$PCA" "$_pcwd_p")" "$PCA.0|"
_pcwd_p="$(_pcwd_pay PreToolUse hd "$PCB" "\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"true\",\"cwd\":\"$PCU\"}")"
is "felix_hook_dir reads the leftmost cwd: an ungoverned directory named again inside tool_input does not undo it" \
   "$(_pcwd_hd "$PCA" "$_pcwd_p")" "$PCB.0|"
_pcwd_p="$(_pcwd_pay Stop hd - "\"stop_hook_active\":false,\"last_assistant_message\":\"cd there: \\\"cwd\\\":\\\"$PCB\\\"\"")"
is "felix_hook_dir does not read a cwd spelt inside a message, where the key's quotes are escaped" \
   "$(_pcwd_hd "$PCA" "$_pcwd_p")" "$PCA.0|"
# The CLI case, where the two directories are one: it must cost nothing, so
# nothing that resolves is called. Spies stand in for each.
#
# The git spy notes the call and forwards it, through a function of its own and
# not `command git "$@"` inside the group that cds. The lint reads a git whose
# subcommand is a parameter as a write, which would make these cds sites, and
# the second spy's cd is meant to stay a plain cd: it stands in a symlink and
# the answer is read by the logical spelling, which _fx_cd, a cd -P, would turn
# into the physical one. What the spy forwards is only ever asked to read.
_pcwd_realgit() { command git "$@"; }
_pco="$( cd "$PCA" && . "$FROOT/harness/lib/resolve.sh"; : > "$PC/spy"
         felix_repo_root()       { printf 'felix_repo_root ' >> "$PC/spy"; printf '%s' "${1:-$PWD}"; }
         felix_resolve_project() { printf 'felix_resolve_project ' >> "$PC/spy"; return 1; }
         felix_binding_broken()  { printf 'felix_binding_broken ' >> "$PC/spy"; }
         git()                   { printf 'git ' >> "$PC/spy"; _pcwd_realgit "$@"; }
         o="$(felix_hook_dir "$(_pcwd_hdp "$PCA")" "$PH" 2>"$PC/hd.err"; printf '.%s' "$?")"
         printf '%s|%s|%s' "$o" "$(cat "$PC/hd.err")" "$(cat "$PC/spy")" )"
is "felix_hook_dir answers a cwd equal to the launch directory without resolving anything" "$_pco" "$PCA.0||"

# About a megabyte: a last message full of escaped "cwd" keys, each naming a
# checkout Felix has something to say about, behind the real key in the first
# payload and with no real one in the second. Child CPU, under
# a watchdog, so neither the load on this machine nor a scan that never ends
# can decide it; the work is a few milliseconds and the bound is three seconds.
_pcwd_killtree() { local c; for c in $(pgrep -P "$1" 2>/dev/null); do _pcwd_killtree "$c"; done; kill "$1" 2>/dev/null; }
_pcwd_bounded() {   # seconds, outfile, command... -> done | killed
  local lim="$1" of="$2" i=0 pid; shift 2
  ( "$@" ) > "$of" 2>&1 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$i" -lt $((lim * 10)) ]; do sleep 0.1; i=$((i + 1)); done
  if kill -0 "$pid" 2>/dev/null; then _pcwd_killtree "$pid"; wait "$pid" 2>/dev/null; printf 'killed'; return; fi
  wait "$pid" 2>/dev/null; printf 'done'
}
_pcwd_big_one() {
  cd "$PCA" && . "$FROOT/harness/lib/resolve.sh"; raw="$(cat "$1")"
  o="$(felix_hook_dir "$raw" "$PH" 2>/dev/null)"; printf '%s' "$o" > "$1.out"; times > "$1.cpu"
}
_pcwd_big() {   # payload file -> "<printed> <cpu ms>", or killed
  [ "$(_pcwd_bounded 60 "$1.log" _pcwd_big_one "$1")" = done ] || { printf 'killed'; return; }
  printf '%s %s' "$(cat "$1.out" 2>/dev/null)" \
    "$(awk '{ for (i = 1; i <= NF; i++) { split($i, t, "m"); sub(/s$/, "", t[2]); ms += (t[1] * 60 + t[2]) * 1000 } }
            END { printf "%d", ms }' "$1.cpu" 2>/dev/null)"
}
_pcwd_msg() { awk -v p="$PCK" 'BEGIN { u = "x \\\"cwd\\\":\\\"" p "\\\" y "; for (n = 0; n < 1100000; n += length(u)) printf "%s", u }'; }
_pcwd_bigp() { _pcwd_pay Stop big "$1" "\"stop_hook_active\":false,\"last_assistant_message\":\"$(_pcwd_msg)\""; }
_pcwd_bigp "$PCB" > "$PC/big-cwd.json"; _pcwd_bigp - > "$PC/big-none.json"
_pcwd_bigsz="$(wc -c < "$PC/big-cwd.json" | tr -d ' ')"
[ "$_pcwd_bigsz" -gt 1000000 ] && ok  "the payload-cwd fixture's megabyte payloads hold over a million bytes" \
                               || bad "the payload-cwd fixture's megabyte payloads hold over a million bytes" "$_pcwd_bigsz bytes"
_pco="$(_pcwd_big "$PC/big-cwd.json")"
if [ "${_pco% *}" = "$PCB" ] && [ "${_pco##* }" -lt 3000 ] 2>/dev/null; then
  ok  "felix_hook_dir finds the top-level cwd ahead of a megabyte of message in under three CPU seconds"
else
  bad "felix_hook_dir finds the top-level cwd ahead of a megabyte of message in under three CPU seconds" \
      "got [$_pco], want [$PCB] under 3000 ms"
fi
_pco="$(_pcwd_big "$PC/big-none.json")"
if [ "${_pco% *}" = "$PCA" ] && [ "${_pco##* }" -lt 3000 ] 2>/dev/null; then
  ok  "felix_hook_dir answers a megabyte payload with no cwd by the launch directory in under three CPU seconds"
else
  bad "felix_hook_dir answers a megabyte payload with no cwd by the launch directory in under three CPU seconds" \
      "got [$_pco], want [$PCA] under 3000 ms"
fi

# ---- felix_hook_enter (C2'): the calling shell moves, and keeps no record of
# whence. Amendment 1 dropped FELIX_HOOK_LAUNCH: nothing reads it once pre-tool
# resolves from where it was started, and state nobody reads is a claim nobody
# checks. So the variable must come back unset, not merely empty.
_pcwd_he() {   # payload -> "PWD|unset, or set to FELIX_HOOK_LAUNCH's value|status|output"
  ( cd "$PCA" && . "$FROOT/harness/lib/resolve.sh"; unset FELIX_HOOK_LAUNCH
    felix_hook_enter "$1" "$PH" > "$PC/he.out" 2>&1; rc=$?
    printf '%s|%s|%s|%s' "$PWD" "${FELIX_HOOK_LAUNCH+set to }${FELIX_HOOK_LAUNCH-unset}" "$rc" "$(cat "$PC/he.out")" )
}
is "felix_hook_enter moves the calling shell into the payload's worktree, says nothing, and leaves FELIX_HOOK_LAUNCH unset" \
   "$(_pcwd_he "$(_pcwd_hdp "$PCB")")" "$PCB|unset|0|"
is "felix_hook_enter leaves the calling shell where it was for a directory nothing governs, says nothing, and sets no FELIX_HOOK_LAUNCH" \
   "$(_pcwd_he "$(_pcwd_hdp "$PCU")")" "$PCA|unset|0|"

# ---- Stop, first with the main checkout green and the worktree unverified.
_pcwd_gate "$PCA"
PCTA1="$(_pcwd_tid "$PCA")"; PCTB1="$(_pcwd_tid "$PCB")"
is "the payload-cwd fixture's main checkout carries a current green receipt, and its worktree none" \
   "$(_pcwd_current "$PCA") $(_pcwd_current "$PCB")" "current none"
is "Stop with the payload's cwd at the launch checkout judges that checkout as before, and it is green" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-s1 "$PCA")")" "silent +1 allowed $PCTA1 green"
is "Stop judges the worktree the payload names, so its unverified work blocks though the main checkout is green" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-s2 "$PCB")")" "block +1 blocked $PCTB1 never checked"
_pco="$(_pcwd_hook "$PCA" stop "$(_pcwd_sp pc-s3 "$PCW2")")"
case "$_pco" in
  *'"decision"'*'"block"'*) ok  "Stop refuses a broken marker in the payload's worktree though the launch checkout is green" ;;
  *)                        bad "Stop refuses a broken marker in the payload's worktree though the launch checkout is green" "got [$_pco]" ;;
esac
has "and the refusal names that worktree's marker" "$_pco" "The .felix marker in $PCW2 names"
# Entered before the flag is read: a flagged stop in a chain Felix did not
# start is judged, and the project it is judged under is the worktree's.
is "Stop launched in a directory nothing governs judges a flagged stop by the worktree the payload names" \
   "$(_pcwd_stop "$PCU" "$(_pcwd_pay Stop pc-s6 "$PCB" '"stop_hook_active":true')")" "block +1 blocked $PCTB1 never checked"

# SubagentStop asks the same of the tree, and says so rather than holding.
has "SubagentStop judges the payload's worktree, so its unverified work is declared though the launch checkout is green" \
    "$(_pcwd_hook "$PCA" subagent-stop "$(_pcwd_pay SubagentStop pc-ss1 "$PCB" '"stop_hook_active":false,"agent_id":"a1"')")" \
    "A subagent report is about to be integrated"
has "SubagentStop launched in a directory nothing governs resolves the governed worktree the payload names" \
    "$(_pcwd_hook "$PCU" subagent-stop "$(_pcwd_pay SubagentStop pc-ss2 "$PCB" '"stop_hook_active":false,"agent_id":"a2"')")" \
    "A subagent report is about to be integrated"

# ---- Then the other way round: the worktree green, the main checkout not.
_pcwd_gate "$PCB"
printf 'a-again\n' >> "$PCA/OK.txt"
PCTA2="$(_pcwd_tid "$PCA")"; PCTB2="$(_pcwd_tid "$PCB")"
is "the payload-cwd fixture's worktree now carries a current green receipt, and its main checkout a stale one" \
   "$(_pcwd_current "$PCB") $(_pcwd_current "$PCA")" "current stale"
is "Stop allows when the worktree the payload names is green, though the launch checkout holds unverified work" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-s4 "$PCB")")" "silent +1 allowed $PCTB2 green"
is "Stop judges the worktree when the payload's cwd is a subdirectory of it" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-s5 "$PCB/sub")")" "silent +1 allowed $PCTB2 green"
_pcwd_held="block +1 blocked $PCTA2 stale receipt"
is "Stop with the payload's cwd at the launch checkout judges it as before, and holds its stale receipt" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c1 "$PCA")")" "$_pcwd_held"
is "Stop with no cwd in the payload judges the launch checkout as before" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c2 -)")" "$_pcwd_held"
is "Stop with an empty cwd judges the launch checkout as before" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c3 "")")" "$_pcwd_held"
is "Stop with a relative cwd judges the launch checkout, though from there that path leads to the green worktree" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c4 to-b)")" "$_pcwd_held"
is "Stop with a cwd spelt in JSON escapes judges the launch checkout, though decoding it leads to the green worktree" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c5 "$(printf '%s' "$PCB" | sed 's|/|\\/|g')")")" "$_pcwd_held"
is "Stop with a cwd that does not exist judges the launch checkout as before" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c6 "$PCB/no-such-directory")")" "$_pcwd_held"
is "Stop with a cwd in a git checkout nothing governs judges the launch checkout as before" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c7 "$PCU")")" "$_pcwd_held"
is "Stop with a cwd in a plain directory nothing governs judges the launch checkout as before" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-c8 "$PCN")")" "$_pcwd_held"

# ---- PreToolUse. A deny row with no scope, so where the command acts does
# not matter and only which project's rows apply does.
_pcwd_ptp() { _pcwd_pay PreToolUse "$1" "$2" "\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"npm publish\"${3:-}},\"tool_use_id\":\"toolu_pcwd\""; }
is "PreToolUse launched in a directory nothing governs refuses by the rows of the governed worktree the payload names" \
   "$(_pcwd_pre "$PCU" "$(_pcwd_ptp pc-p1 "$PCB")")" "2"
has "and the refusal names that project's deny table" "$(cat "$PC/pre.err" 2>/dev/null)" \
    "This is a rule in $PH/projects/pcwd/deny.tsv"
is "PreToolUse reads the top-level cwd, so a later cwd inside tool_input does not lift the worktree's refusal" \
   "$(_pcwd_pre "$PCU" "$(_pcwd_ptp pc-p2 "$PCB" ",\"cwd\":\"$PCU\"")")" "2"
is "PreToolUse is not moved by a governed directory named only inside tool_input" \
   "$(_pcwd_pre "$PCU" "$(_pcwd_ptp pc-p3 "$PCU" ",\"cwd\":\"$PCB\"")")" "0"
is "PreToolUse still refuses by the launch checkout's rows when the payload's worktree has a broken marker" \
   "$(_pcwd_pre "$PCA" "$(_pcwd_ptp pc-p4 "$PCW2")")" "2"
_pcwd_pre "$PCA" "$(_pcwd_ptp pc-p5 -)" >/dev/null; _pcwd_err0="$(cat "$PC/pre.err" 2>/dev/null)"
is "PreToolUse refuses by the launch checkout's rows when the payload's cwd is a directory nothing governs, as before" \
   "$(_pcwd_pre "$PCA" "$(_pcwd_ptp pc-p6 "$PCU")")" "2"
is "and says exactly what it says when the payload carries no cwd" "$(cat "$PC/pre.err" 2>/dev/null)" "$_pcwd_err0"

# ---- SessionStart: the banner and the record are the worktree's.
_pcwd_handoffs() {   # the HANDOFF.md paths a banner names, in order, once each
  printf '%s' "$1" | awk '{ gsub(/\\n/, " ")
    for (i = 1; i <= NF; i++) if ($i ~ /HANDOFF\.md$/ && !s[$i]++) { printf "%s%s", sep, $i; sep = " " } }'
}
_pco="$(_pcwd_hook "$PCA" session-start "$(_pcwd_pay SessionStart pc-st1 "$PCB" '"source":"startup"')")"
is "SessionStart names the handoff of the worktree the payload names, and not the launch checkout's" \
   "$(_pcwd_handoffs "$_pco")" "$PCB/HANDOFF.md"
is "and records the session at the worktree's HEAD" \
   "$(tail -1 "$PM/pcwd/lifecycle.log" 2>/dev/null | cut -f3,6 | tr '\t' ' ')" "pc-st1 $PCHB"
has "SessionStart launched in a directory nothing governs binds the governed worktree the payload names" \
    "$(_pcwd_hook "$PCU" session-start "$(_pcwd_pay SessionStart pc-st2 "$PCB" '"source":"startup"')")" \
    "Project: pcwd"
is "SessionStart with a cwd that does not exist reads the launch checkout as before" \
   "$(_pcwd_handoffs "$(_pcwd_hook "$PCA" session-start "$(_pcwd_pay SessionStart pc-st3 "$PX/no-such" '"source":"startup"')")")" \
   "$PCA/HANDOFF.md"

# ---- UserPromptSubmit: it used to resolve before it had read the payload.
has "UserPromptSubmit launched in a directory nothing governs mounts the lessons of the governed worktree the payload names" \
    "$(_pcwd_hook "$PCU" user-prompt "$(_pcwd_pay UserPromptSubmit pc-up1 "$PCB" '"prompt":"reconcile the quokka ledger"')")" \
    "The rest are in $PM/pcwd/lessons.md."
is "and marks the session at the worktree's HEAD" "$(cat "$PH/state/session/pc-up1" 2>/dev/null)" "$PCHB"
is "UserPromptSubmit launched in a directory nothing governs says nothing when the payload's cwd is ungoverned too, as before" \
   "$(_pcwd_hook "$PCU" user-prompt "$(_pcwd_pay UserPromptSubmit pc-up2 "$PCN" '"prompt":"reconcile the quokka ledger"')")" ""

# ---- SubagentStart: it read no payload at all.
has "SubagentStart launched in a directory nothing governs names the governed worktree's project to the subagent" \
    "$(_pcwd_hook "$PCU" subagent-start "$(_pcwd_pay SubagentStart pc-sa1 "$PCB" '"agent_id":"a1","agent_type":"general-purpose"')")" \
    "Constitution: $PH/projects/pcwd/CLAUDE.md"
is "SubagentStart says nothing when the payload's cwd is the ungoverned directory it was launched in, as before" \
   "$(_pcwd_hook "$PCU" subagent-start "$(_pcwd_pay SubagentStart pc-sa2 "$PCU" '"agent_id":"a2","agent_type":"general-purpose"')")" ""
_pcwd_closed() { cd "$PCA" && : | FELIX_HOME="$PH" FELIX_MEMORY="$PM" "$FROOT/harness/hooks/subagent-start"; }
_pco="$(_pcwd_bounded 60 "$PC/closed.out" _pcwd_closed)"
case "$(cat "$PC/closed.out" 2>/dev/null)" in
  *"Constitution: $PH/projects/pcwd/CLAUDE.md"*) _pco="$_pco binds" ;;
  *)                                             _pco="$_pco silent" ;;
esac
is "SubagentStart given a closed pipe with nothing in it finishes, and binds the launch checkout" "$_pco" "done binds"

# ---- SessionEnd folds what the session reached for into the worktree's ledger.
mkdir -p "$PH/state/ledger"; printf 'skill\tpcwd-probe:used\n' > "$PH/state/ledger/pc-se1.tsv"
_pcwd_hook "$PCU" session-end "$(_pcwd_pay SessionEnd pc-se1 "$PCB" '"reason":"other"')" >/dev/null
is "SessionEnd launched in a directory nothing governs folds the session into the governed worktree's ledger" \
   "$(cut -f3,4 "$PM/pcwd/ledger.d/pc-se1.tsv" 2>/dev/null | tr '\t' ' ')" "skill pcwd-probe:used"

# round two: Amendment 1
# Written from Amendment 1 alone, after three reviews of round one. A hook now
# leaves the directory the platform started it in only for another checkout of
# that directory's own project, for a governed directory when that directory
# governs nothing, or for a broken marker. It reads only the first 4096 bytes
# and only the first "cwd" key, and only when that key's value is a string.
# The launch directory however it is spelt resolves nothing. pre-tool resolves
# from where it was started before anything else.
#
# Fixtures on top of the block's: a project that declares no gate, bound by the
# marker of a checkout nested in the main checkout. The main checkout excludes
# it, as it would a scratch clone, so its own tree does not move. A broken-marker
# checkout's subdirectory, and a link to the main checkout.
mkdir -p "$PH/projects/pcwdnogate"
cat > "$PH/projects/pcwdnogate/project.json" <<'EOF'
{
  "name": "pcwdnogate",
  "remote_match": "example.invalid/pcwd-nogate"
}
EOF
PCNEST="$PCA/nest"; mkdir -p "$PCNEST" "$PCA/.git/info" "$PCK/sub"
( _fx_cd "$PCNEST" && git init -q -b main && printf 'pcwdnogate\n' > .felix && printf 'n\n' > n.txt \
  && git add -A && _pcwd_git commit -qm init ) >/dev/null 2>&1
printf 'nest/\n' >> "$PCA/.git/info/exclude"
ln -s "$PCA" "$PC/via-link"
is "the round-two fixture binds the nested checkout and the remote-bound one to projects of their own, and the main checkout's tree has not moved" \
   "$(_pcwd_res "$PCNEST") $(_pcwd_res "$PCR") $(_pcwd_tid "$PCA")" "pcwdnogate pcwdremote $PCTA2"

# ---- felix_hook_dir, rule 1': the first "cwd" key, and only a string value.
_pcwd_p="{\"session_id\":\"hd\",\"transcript_path\":\"$PT/hd.jsonl\",\"cwd\":null,\"permission_mode\":\"default\",\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"true\",\"cwd\":\"$PCB\"},\"tool_use_id\":\"toolu_hd\"}"
is "felix_hook_dir keeps the launch directory when the first cwd is null, though a governed worktree is named in tool_input after it" \
   "$(_pcwd_hd "$PCA" "$_pcwd_p")" "$PCA.0|"
_pcwd_p="{\"session_id\":\"hd\",\"transcript_path\":\"$PT/hd.jsonl\",\"cwd\":42,\"permission_mode\":\"default\",\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"true\",\"cwd\":\"$PCB\"},\"tool_use_id\":\"toolu_hd\"}"
is "felix_hook_dir keeps a launch directory nothing governs when the first cwd is a number, though a governed worktree is named in tool_input after it" \
   "$(_pcwd_hd "$PCU" "$_pcwd_p")" "$PCU.0|"

# Only the first 4096 bytes are read. The envelope's transcript path is padded
# so that the top-level cwd's closing quote is byte 4096 in one payload, and its
# key starts at byte 4097 in the other.
_pcwd_at() {   # byte the "cwd" key starts at, cwd -> payload
  local h="{\"session_id\":\"hd\",\"transcript_path\":\"$PT/" t='.jsonl",' n
  n=$(( $1 - 1 - ${#h} - ${#t} ))
  printf '%s%s%s"cwd":"%s"%s' "$h" "$(awk -v n="$n" 'BEGIN { while (n-- > 0) printf "x" }')" "$t" "$2" \
    ',"permission_mode":"default","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"true"},"tool_use_id":"toolu_hd"}'
}
_pcwd_in="$(_pcwd_at $(( 4096 - 7 - ${#PCB} )) "$PCB")"; _pcwd_out="$(_pcwd_at 4097 "$PCB")"
is "the payload-cwd fixture's padded payloads end the cwd at byte 4096 in one and start its key at byte 4097 in the other" \
   "$(head -c 4096 <<<"$_pcwd_in" | tail -c $(( ${#PCB} + 8 ))) $(head -c 4096 <<<"$_pcwd_out" | LC_ALL=C command grep -c '"cwd"') $(head -c 4101 <<<"$_pcwd_out" | tail -c 5)" \
   "\"cwd\":\"$PCB\" 0 \"cwd\""
is "felix_hook_dir still reads a top-level cwd whose closing quote is the payload's 4096th byte" \
   "$(_pcwd_hd "$PCA" "$_pcwd_in")" "$PCB.0|"
is "felix_hook_dir keeps the launch directory when the top-level cwd starts past the payload's first 4096 bytes" \
   "$(_pcwd_hd "$PCA" "$_pcwd_out")" "$PCA.0|"

# ---- rule 3': the launch directory, however it is spelt, resolves nothing.
# The round-one spy, with the shell standing where the first argument says.
_pcwd_spy() {   # launch dir as the shell reaches it, payload cwd -> "printed.status|stderr|calls"
  ( cd "$1" && . "$FROOT/harness/lib/resolve.sh"; : > "$PC/spy"
    felix_repo_root()       { printf 'felix_repo_root ' >> "$PC/spy"; printf '%s' "${1:-$PWD}"; }
    felix_resolve_project() { printf 'felix_resolve_project ' >> "$PC/spy"; return 1; }
    felix_binding_broken()  { printf 'felix_binding_broken ' >> "$PC/spy"; }
    git()                   { printf 'git ' >> "$PC/spy"; _pcwd_realgit "$@"; }
    o="$(felix_hook_dir "$(_pcwd_hdp "$2")" "$PH" 2>"$PC/hd.err"; printf '.%s' "$?")"
    printf '%s|%s|%s' "$o" "$(cat "$PC/hd.err")" "$(cat "$PC/spy")" )
}
is "felix_hook_dir answers a launch directory reached through a symlink by that logical spelling, resolving nothing, when the payload names its physical path" \
   "$(_pcwd_spy "$PC/via-link" "$PCA")" "$PC/via-link.0||"
is "felix_hook_dir answers a payload cwd naming the launch directory with a trailing slash by the launch directory, resolving nothing" \
   "$(_pcwd_spy "$PCA" "$PCA/")" "$PCA.0||"

# ---- rule 4': a governed launch directory is left only for its own project.
is "felix_hook_dir keeps a governed launch directory when the payload's cwd is a checkout nested in it whose marker names another project" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCNEST")")" "$PCA.0|"
is "felix_hook_dir keeps a governed launch directory when the payload's cwd is a checkout bound to another project by its remote alone" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCR")")" "$PCA.0|"
is "felix_hook_dir prints that nested checkout of another project when the launch directory governs nothing" \
   "$(_pcwd_hd "$PCU" "$(_pcwd_hdp "$PCNEST")")" "$PCNEST.0|"
is "felix_hook_dir prints a subdirectory of a checkout whose marker is broken, though the launch directory is governed" \
   "$(_pcwd_hd "$PCA" "$(_pcwd_hdp "$PCK/sub")")" "$PCK/sub.0|"

# ---- Stop: a nested checkout of another project does not trade away the
# launch checkout's gate for a project that declares none.
is "Stop launched in a governed checkout holding unverified work still blocks on it when the payload's cwd is a nested checkout of a project that declares no gate" \
   "$(_pcwd_stop "$PCA" "$(_pcwd_sp pc-r2s1 "$PCNEST")")" "$_pcwd_held"

# ---- pre-tool (C3'): the launch checkout's rows first, whatever the payload says.
is "PreToolUse launched in a governed checkout refuses by its own row when the payload's cwd is a checkout of another project with no deny table" \
   "$(_pcwd_pre "$PCA" "$(_pcwd_ptp pc-r2p1 "$PCR")")" "2"
has "and that refusal names the launch checkout's deny table" "$(cat "$PC/pre.err" 2>/dev/null)" \
    "This is a rule in $PH/projects/pcwd/deny.tsv"
printf 'Bash\t(^|[;&| ])cargo publish\tpcwdremote refuses a crate publish\n' > "$PH/projects/pcwdremote/deny.tsv"
is "PreToolUse launched in a governed checkout refuses by its own row when the payload's cwd is a checkout of another project whose deny table lacks that row" \
   "$(_pcwd_pre "$PCA" "$(_pcwd_ptp pc-r2p2 "$PCR")")" "2"
has "and that refusal also names the launch checkout's deny table" "$(cat "$PC/pre.err" 2>/dev/null)" \
    "This is a rule in $PH/projects/pcwd/deny.tsv"
rm -f "$PH/projects/pcwdremote/deny.tsv"
# Launched where nothing governs, with a row scoped to the checkout. The
# worktree the payload names lies under the temporary root lib/where.sh lifts
# scratch in, so only standing in it makes it the governed checkout.
cp "$PH/projects/pcwd/deny.tsv" "$PC/deny.keep"
printf 'Bash\tgit add ([^;&|]* )?(-A|--all|\\.)( |$)\tpcwd refuses staging all of its checkout\tcheckout\n' \
  >> "$PH/projects/pcwd/deny.tsv"
_pcwd_tr="$(cd -P "${TMPDIR:-/tmp}" 2>/dev/null && pwd -P)"
if [ -n "$_pcwd_tr" ] && case "$PCB/" in "${_pcwd_tr%/}/"*) true ;; *) false ;; esac; then
  ok  "the payload-cwd fixture's worktree lies under the TMPDIR the suite was given"
else
  bad "the payload-cwd fixture's worktree lies under the TMPDIR the suite was given" "worktree [$PCB] TMPDIR [${TMPDIR:-}]"
fi
_pcwd_ptc() { _pcwd_pay PreToolUse "$1" "$2" "\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$3\"},\"tool_use_id\":\"toolu_pcwd\""; }
is "PreToolUse launched in a directory nothing governs refuses a command acting in the governed worktree the payload names by that worktree's checkout-scoped row" \
   "$(_pcwd_pre "$PCU" "$(_pcwd_ptc pc-r2p3 "$PCB" 'git add -A')")" "2"
has "and that refusal is the checkout-scoped row of the worktree's project" "$(cat "$PC/pre.err" 2>/dev/null)" \
    "pcwd refuses staging all of its checkout"
is "and the same row lifts for a command that acts only in a scratch checkout under that TMPDIR" \
   "$(_pcwd_pre "$PCU" "$(_pcwd_ptc pc-r2p4 "$PCB" "cd $PCU && git add -A")")" "0"
cp "$PC/deny.keep" "$PH/projects/pcwd/deny.tsv"

# ---- #392's unrecorded-catch prompt in the Desktop shape: the Stop hook
# started in the main checkout on main, the session in the worktree on side,
# both green and current. The guard reads the branch from the root the hook
# judges, so which branch a catch is filed under says which root that was.
# Both gated again: deny.tsv is one of the tables the decision epoch hashes,
# and it was edited above.
_pcwd_gate "$PCA"; _pcwd_gate "$PCB"
PCTA4="$(_pcwd_tid "$PCA")"; PCTB4="$(_pcwd_tid "$PCB")"
is "the payload-cwd fixture's main checkout on main and its worktree on side are both green and current" \
   "$(git -C "$PCA" symbolic-ref --short HEAD 2>/dev/null) $(_pcwd_current "$PCA") $(git -C "$PCB" symbolic-ref --short HEAD 2>/dev/null) $(_pcwd_current "$PCB")" \
   "main current side current"
# One catch the gate filed ten minutes ago under no session: day, branch,
# commit, checks, second, session. Nothing in written.log settles it.
_pcwd_catch() {   # branch -> a mistakes.log holding that one catch, named quokka-<branch>
  local at d; at=$(( $(date +%s) - 600 ))
  d="$(date -r "$at" +%Y-%m-%d 2>/dev/null || date -d "@$at" +%Y-%m-%d)"
  printf '%s\t%s\tabc1234\tquokka-%s\t%s\t-\n' "$d" "$1" "$1" "$at" > "$PM/pcwd/mistakes.log"
}
_pcwd_stopu() {   # launch dir, payload -> "prompt[last caught]|silent|block +rows verdict tree reason"
  local n0 o
  n0="$(_pcwd_rows)"; o="$(_pcwd_hook "$1" stop "$2")"
  case "$o" in
    *'The gate caught something here and nothing has been written down since.'*)
      printf 'prompt[%s]' "$(printf '%s\n' "$o" | sed -n 's/.*  last caught   \([^\\]*\)\\n.*/\1/p' | head -1)" ;;
    *'"decision"'*'"block"'*) printf 'block' ;;
    '')                       printf 'silent' ;;
    *)                        printf 'other[%s]' "$(printf '%s' "$o" | head -c 200)" ;;
  esac
  printf ' +%s %s' "$(( $(_pcwd_rows) - n0 ))" "$(tail -1 "$_pcwd_vlog" 2>/dev/null | cut -f2-4 | tr '\t' ' ')"
}
_pcwd_catch side
is "Stop in the Desktop shape asks about a recent session-less catch filed under the worktree's branch" \
   "$(_pcwd_stopu "$PCA" "$(_pcwd_sp pc-r2u1 "$PCB")")" "prompt[quokka-side] +1 allowed $PCTB4 green"
_pcwd_catch main
is "Stop in the Desktop shape does not ask about a session-less catch filed under the main checkout's branch only" \
   "$(_pcwd_stopu "$PCA" "$(_pcwd_sp pc-r2u2 "$PCB")")" "silent +1 allowed $PCTB4 green"
rm -f "$PM/pcwd/mistakes.log"

# ---- SubagentStart with a terminal on stdin, as when a person runs it by hand.
# The closed pipe above ends a read whether or not it is guarded; a terminal
# held open does not. python3's pty gives the hook one as stdin, with stdout and
# stderr in a file, and kills the one process it forked if that has not exited
# within its bound, so a read that waits on the terminal fails here rather than
# hanging the suite. Measured on 2026-10-02: a subagent-start that reads its
# stdin unguarded fails this as `hung silent`, and the closed pipe stays green.
_pcwd_tty() {   # launch dir, hook, output file -> "exited <status>" or "hung"
  FELIX_HOME="$PH" FELIX_MEMORY="$PM" python3 - "$1" "$FROOT/harness/hooks/$2" "$3" <<'PY'
import os, pty, sys, time
where, hook, out = sys.argv[1:4]
pid, fd = pty.fork()
if pid == 0:
    try:
        os.chdir(where)
        o = os.open(out, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)
        os.dup2(o, 1)
        os.dup2(o, 2)
        os.execv(hook, [hook])
    finally:
        os._exit(127)
end = time.time() + 45
while time.time() < end:
    done, status = os.waitpid(pid, os.WNOHANG)
    if done:
        print('exited %d' % (os.WEXITSTATUS(status) if os.WIFEXITED(status) else 128 + os.WTERMSIG(status)))
        sys.exit(0)
    time.sleep(0.05)
os.kill(pid, 9)
os.waitpid(pid, 0)
print('hung')
PY
}
if command -v python3 >/dev/null 2>&1; then
  _pco="$(_pcwd_tty "$PCA" subagent-start "$PC/tty.out" 2>&1)"
  case "$(cat "$PC/tty.out" 2>/dev/null)" in
    *"Constitution: $PH/projects/pcwd/CLAUDE.md"*) _pco="$_pco binds" ;;
    *)                                             _pco="$_pco silent" ;;
  esac
  is "SubagentStart with a terminal on its stdin finishes without waiting on it, and binds the launch checkout" "$_pco" "exited 0 binds"
else
  skip "SubagentStart with a terminal on its stdin finishes without waiting on it, and binds the launch checkout" "python3 is not installed"
fi

# ---- round-two review pins. Written after the review, from its findings, not
# blind: three things the round-two reviewer measured that nothing above could
# see.
# A launch directory whose marker is broken was meant to be governed. Stepping
# over it into a healthy worktree left the breakage reported nowhere.
is "felix_hook_dir keeps a launch directory whose marker is broken, though the payload names a governed worktree" \
   "$(_pcwd_hd "$PCK" "$(_pcwd_hdp "$PCB")")" "$PCK.0|"
# The CLI shortcut must not fork: it runs on every tool call. Measured by
# refusing forks rather than by timing them, because the child CPU of a few
# hundred tiny subshells sat under any threshold that load would not also
# cross. Held to one process, a shortcut that forks nothing answers; one that
# asks a subshell where the directory is cannot, and the shell says so. Root
# ignores the limit, so there it is skipped rather than passed.
_pcwd_nofork="$( cd "$PC/via-link" || exit 1
                 . "$FROOT/harness/lib/resolve.sh"
                 p="{\"session_id\":\"pc-fork\",\"transcript_path\":\"$PT/pc-fork.jsonl\",\"cwd\":\"$PCA\",\"hook_event_name\":\"PreToolUse\"}"
                 [ "${EUID:-0}" -ne 0 ] && ulimit -u 1 2>/dev/null || { printf 'unlimited'; exit 0; }
                 _felix_hook_dir_set "$p" "$PH" 2>&1
                 [ "$_felix_hd" = "$PWD" ] && printf 'stayed' )"
if [ "$_pcwd_nofork" = unlimited ]; then
  skip "the same-directory shortcut forks nothing: held to one process, a symlinked launch path still stays" "processes cannot be limited here"
else
  is "the same-directory shortcut forks nothing: held to one process, a symlinked launch path still stays" \
     "$_pcwd_nofork" "stayed"
fi
# pre-tool in a repository nothing governs, which is most of them, asks for its
# remote once, as main does: the hook did not move, so there is nothing to ask
# again. Counted at git itself, through a shim first on PATH.
PCUR="$PX/plain-remote"; mkdir -p "$PCUR"; _pcwd_git -C "$PCUR" init -q -b main
_fx_git "$PCUR" config remote.origin.url https://example.invalid/nobody.git
PCUR="$(cd "$PCUR" && pwd -P)"
mkdir -p "$PC/gitspy"
printf '#!/bin/sh\ncase "$*" in *"remote get-url"*) echo x >> "$PCWD_SPY_LOG" ;; esac\nexec "$PCWD_REAL_GIT" "$@"\n' > "$PC/gitspy/git"
chmod +x "$PC/gitspy/git"; : > "$PC/gitspy.log"
( cd "$PCUR" && printf '{"session_id":"pc-once","transcript_path":"%s/pc-once.jsonl","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Read","tool_input":{"file_path":"%s/x"}}' "$PT" "$PCUR" "$PCUR" \
    | PATH="$PC/gitspy:$PATH" PCWD_REAL_GIT="$(command -v git)" PCWD_SPY_LOG="$PC/gitspy.log" \
      FELIX_HOME="$PH" FELIX_MEMORY="$PM" "$FROOT/harness/hooks/pre-tool" >/dev/null 2>&1 )
is "PreToolUse in a checkout nothing governs asks git for its remote once, as main does, when the payload's cwd is that checkout" \
   "$(wc -l < "$PC/gitspy.log" | tr -d ' ')" "1"
unset _pcwd_nofork PCUR

# Left as found: the sealed marker readable again, and nothing of this section's
# by name for a later one to read.
chmod 644 "$PCQ/.felix" 2>/dev/null
unset PC PH PM PT PX PCA PCB PCU PCN PCK PCR PCQ PCBS PCW2 PCHA PCHB PCTA1 PCTB1 PCTA2 PCTB2 \
      _pco _pcwd_p _pcwd_vlog _pcwd_bigsz _pcwd_held _pcwd_err0 \
      PCNEST PCTA4 PCTB4 _pcwd_in _pcwd_out _pcwd_tr
unset -f _pcwd_git _pcwd_pay _pcwd_hook _pcwd_pre _pcwd_tid _pcwd_gate _pcwd_current _pcwd_res \
         _pcwd_rows _pcwd_stop _pcwd_sp _pcwd_hd _pcwd_hdp _pcwd_killtree _pcwd_bounded \
         _pcwd_big_one _pcwd_big _pcwd_msg _pcwd_bigp _pcwd_he _pcwd_ptp _pcwd_handoffs _pcwd_closed \
         _pcwd_at _pcwd_spy _pcwd_ptc _pcwd_catch _pcwd_stopu _pcwd_tty _pcwd_realgit
# <<< hook-payload-cwd
