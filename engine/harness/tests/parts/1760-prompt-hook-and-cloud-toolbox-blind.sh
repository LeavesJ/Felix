# >>> b07-prompt-and-toolbox
printf '\na prompt hook that did not finish, a skill used by its bare name, and the cloud toolbox (audit b07, blind)\n'
# Blind, written 2026-10-24 from docs/2026-10-24-audit-fixes/b07-stop-hook-and-cloud-session-never-let-go.md
# alone (sections 2 and 4, A47 to A83, and section 9's review round, A84 to A87), without reading
# hooks/, lib/, felix or .claude/cloud/provision
# (only toolbox.json, for its layout, which the contract points to). Fixture P2 for the prompt hook and
# the route lib; the provision fixture under $TMP/b07p for the cloud toolbox.
#
# Readings, where the contract leaves room:
# - hook runs get HOME set to a fixture directory; provision runs stand in the case's copy P, with
#   CLAUDE_PROJECT_DIR=P as the platform sets it, so no run can reach a checkout outside $TMP;
# - a cut run (B13) is ended once the git stub was reached; whether it was is part of each assertion,
#   so a run that never reached git cannot pass for one that was cut. A48 counts the says.log rows
#   added from the start of the cut run to the end of the stop;
# - the curl stub writes the tarball to stdout as the contract says, and to -o/--output when a run
#   names one, as curl would; a git fetch with no hang plan is refused;
# - "MISSING lines for alpha and beta" are two distinct lines, each beginning MISSING; a run that my
#   60 s limit had to kill has not ended its network calls itself (A74);
# - an item marked (jq skip), and every provision item that needs a well-formed toolbox, is skipped
#   whole where jq is absent; a systemMessage is read with jq, else python3, else stdout as it stands.
B7B="$TMP/b07u"; B7BH="$B7B/home"; B7BM="$B7B/mem"; B7BR="$B7B/repo"; B7BX="$B7B/stub"; B7BU="$B7B/user"
mkdir -p "$B7BH/projects/p2" "$B7BM" "$B7BR" "$B7BX" "$B7BU"
_copy_content "$REAL_HARNESS" "$B7BH/harness"
printf '{"name": "p2", "gate": "true"}\n' > "$B7BH/projects/p2/project.json"
printf '# p2\n' > "$B7BH/projects/p2/CLAUDE.md"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$B7BH/projects/p2/probes.tsv"
( _fx_cd "$B7BR" && git init -q -b main && printf 'base\n' > WORK.txt && printf 'p2\n' > .felix && git add -A \
  && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm init ) >/dev/null 2>&1
B7BR="$(cd "$B7BR" && pwd -P)"
B7BG="$(type -P git)"
{ printf '#!/bin/bash\n'
  printf 'if [ -e %s ]; then : > %s; exec sleep 60; fi\n' "'$B7B/sentinel'" "'$B7B/reached'"
  printf 'exec %s "$@"\n' "'$B7BG'"; } > "$B7BX/git"
chmod +x "$B7BX/git"
B7BS="$B7BM/p2/says.log"

# ---- helpers ----
_b7b_rows() { [ -f "$1" ] || { printf '0'; return 0; }; LC_ALL=C awk 'END { print NR + 0 }' "$1" 2>/dev/null || printf '0'; }
_b7b_tree() {   # pid -> it and everything below it
  ps -A -o pid= -o ppid= 2>/dev/null | LC_ALL=C awk -v root="$1" '
    { kids[$2] = kids[$2] " " $1 }
    END { q = root; out = ""
          while (q != "") { n = split(q, a, " "); q = ""
                            for (i = 1; i <= n; i++) if (a[i] != "") { out = out " " a[i]; q = q kids[a[i]] } }
          print out }'
}
_b7b_in() { case "$1" in *"$2"*) printf yes ;; *) printf no ;; esac; }
_b7b_j() {   # FILE FIELD: a field of the JSON in FILE (.a or .a.b), or FILE itself with neither jq nor python3
  if command -v jq >/dev/null 2>&1; then jq -r "$2 // empty" < "$1" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys
try:
  d = json.load(open(sys.argv[1]))
  for k in sys.argv[2].strip(".").split("."): d = d[k]
  print(d)
except Exception: pass' "$1" "$2"
  else cat "$1" 2>/dev/null; fi
}
_b7b_obj() { if jq -se 'length == 1 and (.[0] | type) == "object"' < "$1" >/dev/null 2>&1; then printf yes; else printf no; fi; }
_b7b_pp() { printf '{"session_id":"%s","transcript_path":"%s","prompt":"%s"}' "$1" "${2:-}" "${3:-tidy the readme please}"; }
_b7b_bg() {   # HOOK PAYLOAD: one run in R2, in the background (B7B_PID), with the git stub first on PATH
  rm -f "$B7B/o" "$B7B/rc"
  ( cd "$B7BR" && printf '%s' "$2" | env -u FELIX_ALLOW_RED -u CLAUDE_CODE_REMOTE FELIX_HOME="$B7BH" FELIX_MEMORY="$B7BM" \
      HOME="$B7BU" PATH="$B7BX:$PATH" "$1" > "$B7B/o" 2>/dev/null
    echo "$?" > "$B7B/rc" ) &
  B7B_PID=$!
}
_b7b_run() {   # HOOK PAYLOAD: one run, killed at 20 s. B7B_RC, B7B_O, B7B_OB, B7B_NS (says rows added)
  local s0 n=0 k
  s0="$(_b7b_rows "$B7BS")"
  _b7b_bg "$1" "$2"
  while kill -0 "$B7B_PID" 2>/dev/null && [ "$n" -lt 200 ]; do sleep 0.1; n=$((n + 1)); done
  if kill -0 "$B7B_PID" 2>/dev/null; then
    for k in $(_b7b_tree "$B7B_PID"); do kill -9 "$k" 2>/dev/null; done
    wait "$B7B_PID" 2>/dev/null; B7B_RC=124
  else wait "$B7B_PID" 2>/dev/null; B7B_RC="$(cat "$B7B/rc" 2>/dev/null)"; B7B_RC="${B7B_RC:-none}"; fi
  B7B_O="$(cat "$B7B/o" 2>/dev/null)"; B7B_OB="$(wc -c < "$B7B/o" 2>/dev/null | tr -d ' ')"; B7B_OB="${B7B_OB:-0}"
  B7B_NS="$(( $(_b7b_rows "$B7BS") - s0 ))"
  return 0
}
_b7b_stop() { _b7b_run "$B7BH/harness/hooks/stop" "$(printf '{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"%s"}' "$1")"; }
_b7b_up() { _b7b_run "$B7BH/harness/hooks/user-prompt" "$(_b7b_pp "$@")"; }
_b7b_cut() {   # KILL|TERM SID: a prompt run ended with that signal, with its tree, once it reached git
  local n=0 k ks
  : > "$B7B/sentinel"; rm -f "$B7B/reached"
  _b7b_bg "$B7BH/harness/hooks/user-prompt" "$(_b7b_pp "$2")"
  while [ ! -e "$B7B/reached" ] && kill -0 "$B7B_PID" 2>/dev/null && [ "$n" -lt 100 ]; do sleep 0.1; n=$((n + 1)); done
  B7B_REACHED=no; [ -e "$B7B/reached" ] && B7B_REACHED=yes
  ks="$(_b7b_tree "$B7B_PID")"
  for k in $ks; do kill -"$1" "$k" 2>/dev/null; done
  wait "$B7B_PID" 2>/dev/null
  for k in $ks; do kill -0 "$k" 2>/dev/null && kill -9 "$k" 2>/dev/null; done
  rm -f "$B7B/sentinel"
}
_b7b_says() { _b7b_in "$(_b7b_j "$B7B/o" .systemMessage)" "$1"; }
_b7b_hold() { case "$B7B_O" in *'"decision"'*'"block"'*) printf yes ;; *) printf no ;; esac; }
_b7b_is() {
  if [ "$2" = "$3" ]; then ok "$1"
  else bad "$1" "expected [$3] got [$2]; exit [$B7B_RC] stdout [${B7B_O:0:400}]"; fi
}
_b7b_jis() { if command -v jq >/dev/null 2>&1; then _b7b_is "$@"; else skip "$1" "jq is not on PATH"; fi; }
B7BF="Felix's prompt hook did not finish"

# ---- C102: a prompt hook that did not finish (B13 to B18) ----
_b7b_s0="$(_b7b_rows "$B7BS")"
_b7b_cut KILL u1; _b7b_w="$B7B_REACHED"; _b7b_stop u1; _b7b_first="$(_b7b_says "$B7BF")"
_b7b_jis "b07 A47: after a prompt run killed by SIGKILL, the clean stop exits 0 with one JSON object, no decision, saying Felix's prompt hook did not finish" \
  "reached=$_b7b_w exit=$B7B_RC says=$(_b7b_says "$B7BF") decision=$(_b7b_in "$B7B_O" '"decision"') json=$(_b7b_obj "$B7B/o")" \
  "reached=yes exit=0 says=yes decision=no json=yes"
_b7b_x="$(tail -n "+$((_b7b_s0 + 1))" "$B7BS" 2>/dev/null | LC_ALL=C awk -F'\t' '$2 == "prompt-unfinished" && $3 == "u1" { n++ } END { print n + 0 }')"
_b7b_is "b07 A48: and says.log gains one row of kind prompt-unfinished for session u1" "$_b7b_x" "1"
_b7b_stop u1
_b7b_is "b07 A49: it is said once: said at u1's first stop, and u1's next stop prints nothing" "first=$_b7b_first next=$B7B_OB" "first=yes next=0"
_b7b_cut TERM u2; _b7b_w="$B7B_REACHED"; _b7b_stop u2
_b7b_is "b07 A50: after a prompt run ended by SIGTERM, the stop says Felix's prompt hook did not finish" \
  "reached=$_b7b_w says=$(_b7b_says "$B7BF")" "reached=yes says=yes"
_b7b_cut KILL u3; _b7b_w="$B7B_REACHED"; printf 'an edit\n' >> "$B7BR/WORK.txt"; _b7b_stop u3; printf 'base\n' > "$B7BR/WORK.txt"
_b7b_is "b07 A51: a stop that holds after a killed prompt run still says Do not describe this work as complete, and also says Felix's prompt hook did not finish" \
  "reached=$_b7b_w hold=$(_b7b_hold) reason=$(_b7b_in "$(_b7b_j "$B7B/o" .reason)" 'Do not describe this work as complete') says=$(_b7b_says "$B7BF")" \
  "reached=yes hold=yes reason=yes says=yes"
_b7b_cut KILL u4; _b7b_w="$B7B_REACHED"; _b7b_up u4; _b7b_n="$B7B_RC"; _b7b_stop u4
_b7b_is "b07 A52: a killed run, then a run of the same session that ends normally, and the stop still says Felix's prompt hook did not finish" \
  "reached=$_b7b_w normal=$_b7b_n says=$(_b7b_says "$B7BF")" "reached=yes normal=0 says=yes"
_b7b_up u5; _b7b_n="$B7B_RC"; _b7b_stop u5
_b7b_is "b07 A53: a prompt run that ends normally leaves nothing to report: the clean stop prints nothing and adds no says.log row (control)" \
  "normal=$_b7b_n out=$B7B_OB says=$B7B_NS" "normal=0 out=0 says=0"
_b7b_x="$(_fx_git "$B7BR" rev-parse HEAD 2>/dev/null)"; _b7b_y="$(cat "$B7BH/state/session/u5" 2>/dev/null)"
if [ -z "$_b7b_x" ]; then _b7b_y="R2's HEAD could not be read"; else _b7b_y="$(_b7b_in "$_b7b_y" "$_b7b_x")"; fi
_b7b_is "b07 A54: after a normal prompt run the session mark state/session/u5 holds R2's HEAD (control)" "$_b7b_y" "yes"
_b7b_run "$B7BH/harness/hooks/session-start" '{"source":"startup","session_id":"u6"}'
_b7b_x=absent; { [ -e "$B7BH/state/session/u6" ] || [ -L "$B7BH/state/session/u6" ]; } && _b7b_x=present
_b7b_is "b07 A55: SessionStart writes no session mark for its session (control)" "$_b7b_x" "absent"

# ---- review round M1: a held stop with a note due, where TMPDIR cannot be written (B30, B31) ----
# The stop runs with TMPDIR naming a directory that does not exist, so no temporary file can be made.
# "Delivered" is what the platform can read: stdout is one JSON object (jq -s reads one value) whose
# decision is block. A stop that delivered no hold is followed by an unflagged stop, as the platform
# would send; one that did is followed by the flagged stop of its chain.
B7BV="$B7BM/p2/verification.log"; B7BT="$B7B/no-such-dir/x"
printf '#!/bin/sh\nTMPDIR=%s; export TMPDIR\nexec %s\n' "'$B7BT'" "'$B7BH/harness/hooks/stop'" > "$B7B/stop-notmp"
chmod +x "$B7B/stop-notmp"
_b7m_stop() {   # SID FLAG: one stop of R2 under that TMPDIR. B7M_NV: the verification rows it added
  local v0
  v0="$(_b7b_rows "$B7BV")"
  _b7b_run "$B7B/stop-notmp" "$(printf '{"hook_event_name":"Stop","stop_hook_active":%s,"session_id":"%s"}' "$2" "$1")"
  B7M_NV="$(tail -n "+$((v0 + 1))" "$B7BV" 2>/dev/null)"
}
_b7m_n() { LC_ALL=C awk -F'\t' -v k="$1" '$2 == k { n++ } END { print n + 0 }' <<< "$B7M_NV"; }
_b7m_one() {   # [NOTE] -> yes when stdout is one JSON object that holds, and whose systemMessage says NOTE
  if jq -se --arg n "${1:-}" 'length == 1 and (.[0] | type) == "object" and .[0].decision == "block"
        and ($n == "" or ((.[0].systemMessage // "") | tostring | contains($n)))' < "$B7B/o" >/dev/null 2>&1
  then printf yes; else printf no; fi
}
_b7m_tmp="$([ -e "$B7B/no-such-dir" ] && echo exists || echo absent)"
printf 'an edit for the review round\n' >> "$B7BR/WORK.txt"; _b7m_stop r5 false; printf 'base\n' > "$B7BR/WORK.txt"
_b7b_jis "b07 A84: with TMPDIR naming no directory and no note due, a dirty stop prints one JSON object that holds and logs one blocked row (control)" \
  "tmp=$_b7m_tmp exit=$B7B_RC one=$(_b7m_one) blocked=$(_b7m_n blocked)" "tmp=absent exit=0 one=yes blocked=1"
_b7b_s0="$(_b7b_rows "$B7BS")"
_b7b_cut KILL r4; _b7b_w="$B7B_REACHED"
printf 'an edit for the review round\n' >> "$B7BR/WORK.txt"; _b7m_stop r4 false
_b7m_d="$(_b7m_one)"; _b7m_dn="$(_b7m_one "$B7BF")"; _b7m_nb="$(_b7m_n blocked)"
_b7m_nr="$(tail -n "+$((_b7b_s0 + 1))" "$B7BS" 2>/dev/null | LC_ALL=C awk -F'\t' '$2 == "prompt-unfinished" && $3 == "r4" { n++ } END { print n + 0 }')"
_b7b_jis "b07 A85: after a prompt run cut off, a dirty stop under that TMPDIR prints one JSON object that holds, with Do not describe this work as complete in its reason, and says Felix's prompt hook did not finish" \
  "tmp=$_b7m_tmp reached=$_b7b_w exit=$B7B_RC one=$_b7m_d reason=$(_b7b_in "$(_b7b_j "$B7B/o" .reason)" 'Do not describe this work as complete') says=$_b7m_dn" \
  "tmp=absent reached=yes exit=0 one=yes reason=yes says=yes"
_b7m_x=consistent; [ "$_b7m_nr" -gt 0 ] && [ "$_b7m_dn" != yes ] && _b7m_x="$_b7m_nr prompt-unfinished row(s) for a note it did not deliver"
_b7b_jis "b07 A86: and its records say only what it delivered: one blocked row with the hold delivered, and no prompt-unfinished row for r4 unless the note was in that object" \
  "blocked=$_b7m_nb hold=$_b7m_d note=$_b7m_x" "blocked=1 hold=yes note=consistent"
_b7m_e=0; _b7m_f=false; [ "$_b7m_d" = yes ] && _b7m_f=true
for _b7m_i in 1 2; do
  _b7m_stop r4 "$_b7m_f"
  [ "$_b7m_d" = yes ] || _b7m_e="$(( _b7m_e + $(_b7m_n debt) ))"
  if [ "$(_b7m_one)" = yes ]; then _b7m_d=yes; _b7m_f=true; else _b7m_f=false; fi
done
printf 'base\n' > "$B7BR/WORK.txt"
_b7b_jis "b07 A87: r4 is let go as debt only after a hold it was given: its next two stops, flagged after a delivered hold and unflagged otherwise, write no debt row before one" \
  "early-debt=$_b7m_e held=$_b7m_d" "early-debt=0 held=yes"

# ---- C106: a skill used under its bare name counts as used (B19 to B21) ----
_b7b_tx() { printf '{"type":"assistant","attributionSkill":"%s"}\n' "$@" > "$B7B/tx.jsonl"; }
_b7b_used() {   # STEP -> the status felix_route_step_used returns over $B7B/tx.jsonl
  ( export FELIX_HOME="$B7BH" FELIX_MEMORY="$B7BM"; . "$B7BH/harness/lib/resolve.sh"; . "$B7BH/harness/lib/route.sh"
    felix_route_step_used "$B7B/tx.jsonl" "$1" ) >/dev/null 2>&1
  printf '%s' "$?"
}
_b7b_tx brainstorming
_b7b_is "b07 A56: a bare attribution of brainstorming counts as a use of superpowers:brainstorming" "$(_b7b_used superpowers:brainstorming)" "0"
_b7b_is "b07 A57: but not as a use of superpowers:writing-plans (control)" "$(_b7b_used superpowers:writing-plans)" "1"
_b7b_tx brainstorming-extra
_b7b_is "b07 A58: a bare attribution that only begins with brainstorming is no use of superpowers:brainstorming (control)" "$(_b7b_used superpowers:brainstorming)" "1"
_b7b_tx writing-plans
_b7b_is "b07 A59: a bare attribution of another skill is no use of superpowers:brainstorming (control)" "$(_b7b_used superpowers:brainstorming)" "1"
printf '{"type":"assistant","attributionPlugin":"superpowers"}\n' > "$B7B/tx.jsonl"
_b7b_is "b07 A60: an attributionPlugin of superpowers alone is no use of superpowers:brainstorming (control)" "$(_b7b_used superpowers:brainstorming)" "1"
_b7b_tx superpowers:brainstorming
_b7b_is "b07 A61: a qualified attribution still counts as a use of superpowers:brainstorming (control)" "$(_b7b_used superpowers:brainstorming)" "0"
_b7b_tx brainstorming writing-plans
_b7b_x="$( ( export FELIX_HOME="$B7BH" FELIX_MEMORY="$B7BM"; . "$B7BH/harness/lib/resolve.sh"; . "$B7BH/harness/lib/route.sh"
             felix_route_skipped "$B7B/tx.jsonl" "superpowers:brainstorming superpowers:writing-plans superpowers:executing-plans" ) 2>/dev/null)"
_b7b_is "b07 A62: felix_route_skipped leaves out the two steps used by their bare names and prints superpowers:executing-plans" "$_b7b_x" "superpowers:executing-plans"
printf 'build\tbuild implement feature create\tcore\tsuperpowers:brainstorming superpowers:writing-plans superpowers:executing-plans\n' > "$B7BH/projects/p2/routes.tsv"
printf 'plugin\tsuperpowers@claude-plugins-official\tclaude-plugins-official\tlow\talways\n' > "$B7BH/projects/p2/stack.tsv"
_b7b_tx brainstorming; _b7b_up u7 "$B7B/tx.jsonl" 'build and implement the new feature'
_b7b_is "b07 A63: after a bare attribution of brainstorming the router names the next step: Use this now: superpowers:writing-plans" \
  "$(_b7b_in "$(_b7b_j "$B7B/o" .hookSpecificOutput.additionalContext)" 'Use this now: superpowers:writing-plans')" "yes"
: > "$B7B/tx0.jsonl"; _b7b_up u8 "$B7B/tx0.jsonl" 'build and implement the new feature'
_b7b_is "b07 A64: with an empty transcript it names the first: Use this now: superpowers:brainstorming (control)" \
  "$(_b7b_in "$(_b7b_j "$B7B/o" .hookSpecificOutput.additionalContext)" 'Use this now: superpowers:brainstorming')" "yes"

# ---- C107: provision says what did not arrive, inside the hook's time (B22 to B29) ----
B7P="$TMP/b07p"; B7PS="$(cd "$REAL_HARNESS/../.." && pwd)/.claude/cloud/provision"; B7PG="$(type -P git)"
B7P1=1111111111111111111111111111111111111111; B7P2=2222222222222222222222222222222222222222
B7PA="$B7P/srv/a/superpowers-$B7P1"; B7PB="$B7P/srv/b/plugins-$B7P2"; B7PC="$B7P/c/none"
mkdir -p "$B7P/home" "$B7P/tpl" "$B7P/c" "$B7PA/hooks" "$B7PA/skills/brainstorming" \
         "$B7PB/plugins/alpha/skills/alpha-skill" "$B7PB/plugins/beta/agents"
cat > "$B7PA/hooks/session-start" <<'B7_SP_HOOK'
#!/bin/sh
printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"SP-CONTEXT-B07"}}'
B7_SP_HOOK
chmod +x "$B7PA/hooks/session-start"; "$B7PA/hooks/session-start" > "$B7P/srv/sp.out"
printf -- '---\nname: brainstorming\n---\nb07\n' > "$B7PA/skills/brainstorming/SKILL.md"
printf -- '---\nname: alpha-skill\n---\nb07\n' > "$B7PB/plugins/alpha/skills/alpha-skill/SKILL.md"
printf -- '---\nname: beta-agent\n---\nb07\n' > "$B7PB/plugins/beta/agents/beta-agent.md"
( cd "$B7P/srv/a" && COPYFILE_DISABLE=1 tar -czf "$B7P/srv/superpowers.tgz" "superpowers-$B7P1" )
( cd "$B7P/srv/b" && COPYFILE_DISABLE=1 tar -czf "$B7P/srv/plugins.tgz" "plugins-$B7P2" )
( _fx_cd "$B7P/tpl" && git init -q -b main && printf 'b07\n' > README && git add README \
  && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm init \
  && git update-ref refs/remotes/origin/main HEAD && git remote add origin "$B7P/no-origin" ) >/dev/null 2>&1
_b7p_box() {
  cat > "$1" <<B7_TOOLBOX
{
  "about": ["the audit b07 fixture's toolbox"],
  "tools": [
    {"name": "superpowers", "carry": "fetch", "source": "fx/superpowers", "sha": "$B7P1", "subdir": ".", "note": "skills and the session-start context"},
    {"name": "alpha", "carry": "fetch", "source": "fx/plugins", "sha": "$B7P2", "subdir": "plugins/alpha", "note": "one skill"},
    {"name": "beta", "carry": "fetch", "source": "fx/plugins", "sha": "$B7P2", "subdir": "plugins/beta", "note": "one agent"},
    {"name": "gamma", "carry": "builtin", "note": "Claude Code ships gamma itself"}
  ]
}
B7_TOOLBOX
}
_b7p_case() {   # NAME SUPERPOWERS-PLAN PLUGINS-PLAN GIT-FETCH-PLAN: a fresh P, its stubs and its plan
  local c="$B7P/c/$1"
  mkdir -p "$c/bin"; cp -R "$B7P/tpl" "$c/P"; mkdir -p "$c/P/.claude/cloud"
  cp "$B7PS" "$c/P/.claude/cloud/provision" 2>/dev/null
  _b7p_box "$c/P/.claude/cloud/toolbox.json"
  printf 'fx/superpowers %s\nfx/plugins %s\ngit-fetch %s\n' "$2" "$3" "$4" > "$c/plan"
  : > "$c/calls"; : > "$c/fetches"; : > "$c/pids"
  { printf '#!/bin/bash\nC=%s; S=%s\n' "'$c'" "'$B7P/srv'"; cat <<'B7_CURL'
url=""; m=""; out=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -m|--max-time) m="${2-}"; shift ;;
    --max-time=*) m="${1#*=}" ;;
    -o|--output) out="${2-}"; shift ;;
    --output=*) out="${1#*=}" ;;
    http*) url="$1" ;;
  esac
  shift
done
r="${url#https://codeload.github.com/}"; o="${r%%/*}"; r="${r#*/}"; n="${r%%/*}"; h="${r##*/}"
printf '%s/%s@%s\n' "$o" "$n" "$h" >> "$C/calls"
p="$(awk -v s="$o/$n" '$1 == s { print $2; exit }' "$C/plan")"
if [ "$p" = serve ]; then
  if [ -n "$out" ]; then cat "$S/$n.tgz" > "$out"; else cat "$S/$n.tgz"; fi
  exit 0
elif [ "$p" = hang ]; then
  printf '%s\n' "$$" >> "$C/pids"
  [ -n "$m" ] && exec perl -e 'sleep $ARGV[0]; exit 28' "$m"
  exec sleep 300
fi
printf 'curl: (22) The requested URL returned error: 403\n' >&2
exit 22
B7_CURL
  } > "$c/bin/curl"
  { printf '#!/bin/bash\nC=%s; G=%s\n' "'$c'" "'$B7PG'"; cat <<'B7_GIT'
s=""; k=""
for a in "$@"; do
  if [ -n "$k" ]; then k=""; continue; fi
  case "$a" in
    -C|-c|--git-dir|--work-tree|--namespace|--config-env) k=1 ;;
    -*) ;;
    *) s="$a"; break ;;
  esac
done
if [ "$s" = fetch ]; then
  printf '%s\n' "$*" >> "$C/fetches"
  if [ "$(awk '$1 == "git-fetch" { print $2; exit }' "$C/plan")" = hang ]; then printf '%s\n' "$$" >> "$C/pids"; exec sleep 300; fi
  exit 1
fi
exec "$G" "$@"
B7_GIT
  } > "$c/bin/git"
  chmod +x "$c/bin/curl" "$c/bin/git"
}
_b7p_run() {   # NAME SOURCE MODE BUDGET|- [outside]: one run in the case's P, killed at 60 s. B7P_RC, B7P_SEC, B7PC
  local c="$B7P/c/$1" pid n=0 k t0 f="FELIX_CLOUD_FORCE=1" b="B7P_NO_BUDGET=1"
  [ "${5:-}" = outside ] && f="B7P_NOT_FORCED=1"
  [ "$4" = - ] || b="FELIX_CLOUD_BUDGET=$4"
  t0="$(date +%s)"
  ( cd "$c/P" && printf '{"source":"%s"}' "$2" | env -u CLAUDE_CODE_REMOTE -u FELIX_CLOUD_FORCE -u FELIX_CLOUD_BUDGET \
      PATH="$c/bin:$PATH" HOME="$B7P/home" CLAUDE_PROJECT_DIR="$c/P" FELIX_CLOUD_CACHE="$c/cache" "$f" "$b" \
      bash "$c/P/.claude/cloud/provision" "$3" > "$c/out" 2> "$c/err"
    echo "$?" > "$c/rc" ) &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$n" -lt 600 ]; do sleep 0.1; n=$((n + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    for k in $(_b7b_tree "$pid"); do kill -9 "$k" 2>/dev/null; done
    wait "$pid" 2>/dev/null; B7P_RC=124
  else wait "$pid" 2>/dev/null; B7P_RC="$(cat "$c/rc" 2>/dev/null)"; B7P_RC="${B7P_RC:-none}"; fi
  B7P_SEC="$(( $(date +%s) - t0 ))"; B7PC="$c"; B7P_O="$(cat "$c/out" 2>/dev/null)"
  return 0
}
# Not blind: the public snapshot does not ship .claude/cloud, so where the
# directory is absent each is skipped saying so, as part 2070 does. A directory
# without its provision script is still bad.
_b7p_is() {   # jq|any NAME GOT WANT
  if [ ! -d "${B7PS%/provision}" ]; then skip "$2" "no .claude/cloud beside this harness (the public snapshot does not ship it)"
  elif [ ! -f "$B7PS" ]; then bad "$2" "no provision script at $B7PS"
  elif [ "$1" = jq ] && ! command -v jq >/dev/null 2>&1; then skip "$2" "jq is not on PATH, and provision reads the toolbox with jq"
  elif [ "$3" = "$4" ]; then ok "$2"
  else bad "$2" "expected [$4] got [$3]; exit [$B7P_RC] stdout [${B7P_O:0:400}] stderr [$(head -c 200 "$B7PC/err" 2>/dev/null)]"; fi
}
_b7p_names() {   # TEXT NAME... -> "all" when TEXT names each, else the names it lacks
  local t="$1" n miss=""
  shift
  for n in "$@"; do case "$t" in *"$n"*) ;; *) miss="$miss $n" ;; esac; done
  printf '%s' "${miss:-all}"
}
_b7p_lead() {   # TEXT PREFIX NAME... -> "all" when, for each NAME, a line begins PREFIX and names it
  local t="$1" p="$2" n miss=""
  shift 2
  for n in "$@"; do
    [ "$(LC_ALL=C awk -v p="$p" -v n="$n" 'index($0, p) == 1 && index($0, n) { f = 1 } END { print f + 0 }' <<< "$t")" = 1 ] || miss="$miss $n"
  done
  printf '%s' "${miss:-all}"
}
_b7p_two() {   # TEXT A B -> yes when a MISSING line names A and another MISSING line names B
  LC_ALL=C awk -v a="$2" -v b="$3" 'index($0, "MISSING") == 1 { x = index($0, a); y = index($0, b); if (x) na++; if (y) nb++; if (x || y) ne++ }
    END { print (na && nb && ne >= 2) ? "yes" : "no" }' <<< "$1"
}
_b7p_msg() { _b7b_j "$B7PC/out" .systemMessage; }
_b7p_ctx() { _b7b_j "$B7PC/out" .hookSpecificOutput.additionalContext; }
_b7p_nz() { case "$1" in 0|124|none) printf '%s' "$1" ;; *) printf nonzero ;; esac; }

_b7p_case ok serve serve refuse; _b7p_run ok startup --session-start -
_b7p_is jq "b07 A65: with both sources served, a startup run exits 0 and prints exactly what the plugin's session-start hook prints (control)" \
  "exit=$B7P_RC same=$(cmp -s "$B7PC/out" "$B7P/srv/sp.out" && echo yes || echo no)" "exit=0 same=yes"
_b7p_x=no; LC_ALL=C grep -qxF '/.claude/skills/brainstorming' "$B7PC/P/.git/info/exclude" 2>/dev/null && _b7p_x=yes
_b7p_is jq "b07 A66: and it carries brainstorming, alpha-skill and beta-agent into .claude, and excludes /.claude/skills/brainstorming from git (control)" \
  "$(_b7p_names "$(ls "$B7PC/P/.claude/skills/brainstorming/SKILL.md" "$B7PC/P/.claude/skills/alpha-skill/SKILL.md" "$B7PC/P/.claude/agents/beta-agent.md" 2>/dev/null)" brainstorming/SKILL.md alpha-skill/SKILL.md beta-agent.md) exclude=$_b7p_x" \
  "all exclude=yes"
_b7p_run ok resume --session-start -
_b7p_is jq "b07 A67: a resume run with everything carried prints nothing (control)" "exit=$B7P_RC out=${#B7P_O}" "exit=0 out=0"
_b7p_case ref serve refuse refuse; _b7p_run ref startup --session-start -
_b7p_is jq "b07 A68: with fx/plugins refused, the run exits 0 with one JSON object whose systemMessage names alpha, beta and the log" \
  "exit=$B7P_RC json=$(_b7b_obj "$B7PC/out") names=$(_b7p_names "$(_b7p_msg)" alpha beta "$B7PC/cache/provision.log")" "exit=0 json=yes names=all"
_b7p_is jq "b07 A69: and its context has MISSING lines for alpha and for beta, still holds SP-CONTEXT-B07, and is a SessionStart event" \
  "missing=$(_b7p_two "$(_b7p_ctx)" alpha beta) sp=$(_b7b_in "$(_b7p_ctx)" SP-CONTEXT-B07) event=$(_b7b_j "$B7PC/out" .hookSpecificOutput.hookEventName)" \
  "missing=yes sp=yes event=SessionStart"
_b7p_x="$(LC_ALL=C grep -cxF "fx/plugins@$B7P2" "$B7PC/calls" 2>/dev/null)"
_b7p_is jq "b07 A70: a source that failed is fetched once in the run, not again for its second entry" "${_b7p_x:-0}" "1"
_b7p_case rsm serve refuse refuse; _b7p_run rsm resume --session-start -
_b7p_is jq "b07 A71: on resume the same report is given, without SP-CONTEXT-B07" \
  "msg=$(_b7p_names "$(_b7p_msg)" alpha beta) missing=$(_b7p_two "$(_b7p_ctx)" alpha beta) sp=$(_b7b_in "$B7P_O" SP-CONTEXT-B07)" "msg=all missing=yes sp=no"
_b7p_case all refuse refuse refuse; _b7p_run all startup --session-start -
_b7p_is jq "b07 A72: with every source refused the report names superpowers, alpha and beta, and holds no SP-CONTEXT-B07" \
  "exit=$B7P_RC names=$(_b7p_names "$B7P_O" superpowers alpha beta) sp=$(_b7b_in "$B7P_O" SP-CONTEXT-B07)" "exit=0 names=all sp=no"
_b7p_case hang hang hang hang; _fx_git "$B7P/c/hang/P" update-ref -d refs/remotes/origin/main >/dev/null 2>&1
_b7p_run hang startup --session-start 4
_b7p_is jq "b07 A73: with every fetch hanging and a budget of 4 s, the run exits 0 within 30 s and names superpowers, alpha, beta and origin/main" \
  "exit=$B7P_RC within=$([ "$B7P_SEC" -le 30 ] && echo yes || echo "no, $B7P_SEC s") names=$(_b7p_names "$B7P_O" superpowers alpha beta origin/main)" \
  "exit=0 within=yes names=all"
if [ "$B7P_RC" = 124 ]; then _b7p_x="the run did not end by itself and was killed at 60 s"
else sleep 2; _b7p_x=""; for _b7p_k in $(cat "$B7PC/pids" 2>/dev/null); do kill -0 "$_b7p_k" 2>/dev/null && _b7p_x="$_b7p_x $_b7p_k"; done
  _b7p_x="${_b7p_x:-none running}"; fi
_b7p_is jq "b07 A74: two seconds after it exits, no curl or git fetch it started is still running" "$_b7p_x" "none running"
for _b7p_k in $(cat "$B7PC/pids" 2>/dev/null); do kill -0 "$_b7p_k" 2>/dev/null && kill -9 "$_b7p_k" 2>/dev/null; done
_b7p_case zero serve serve refuse; _b7p_run zero startup --session-start 0
_b7p_is jq "b07 A75: with a budget of 0 the run exits 0 within 10 s, calls nothing, and says not tried for superpowers, alpha and beta" \
  "exit=$B7P_RC within=$([ "$B7P_SEC" -le 10 ] && echo yes || echo "no, $B7P_SEC s") calls=$(_b7b_rows "$B7PC/calls") nottried=$(_b7b_in "$B7P_O" 'not tried') names=$(_b7p_names "$B7P_O" superpowers alpha beta)" \
  "exit=0 within=yes calls=0 nottried=yes names=all"
_b7p_case soon refuse refuse refuse; _b7p_run soon startup --session-start soon
_b7p_is jq "b07 A76: a budget that is not a whole number reads as the default: with refusals the report still names all three" \
  "exit=$B7P_RC names=$(_b7p_names "$B7P_O" superpowers alpha beta)" "exit=0 names=all"
_b7p_case nob serve serve refuse; _fx_git "$B7P/c/nob/P" update-ref -d refs/remotes/origin/main >/dev/null 2>&1
_b7p_run nob startup --session-start -
_b7p_x="$(LC_ALL=C awk 'index($0, "MISSING") == 1 && index($0, "origin/main") { f = 1 } END { print f ? "yes" : "no" }' <<< "$(_b7p_ctx)")"
_b7p_is jq "b07 A77: with origin/main absent and its fetch refused, the systemMessage and a MISSING line name origin/main, and SP-CONTEXT-B07 is still there" \
  "msg=$(_b7b_in "$(_b7p_msg)" origin/main) missing=$_b7p_x sp=$(_b7b_in "$(_b7p_ctx)" SP-CONTEXT-B07)" "msg=yes missing=yes sp=yes"
_b7p_case bad serve serve refuse; printf '{ not json\n' > "$B7P/c/bad/P/.claude/cloud/toolbox.json"
_b7p_run bad startup --report -
_b7p_is any "b07 A78: with a toolbox.json that cannot be read, --report exits non-zero with a MISSING line naming toolbox.json" \
  "exit=$(_b7p_nz "$B7P_RC") missing=$(_b7p_lead "$B7P_O" MISSING toolbox.json)" "exit=nonzero missing=all"
_b7p_run bad startup --session-start -
_b7p_is any "b07 A79: and --session-start exits 0 with a systemMessage naming toolbox.json" "exit=$B7P_RC msg=$(_b7b_in "$(_b7p_msg)" toolbox.json)" "exit=0 msg=yes"
_b7p_case outside serve serve refuse; _b7p_run outside startup --session-start - outside
_b7p_is any "b07 A80: outside a cloud session provision exits 0, prints nothing, makes no cache directory and calls nothing (control)" \
  "exit=$B7P_RC out=${#B7P_O} cache=$([ -e "$B7PC/cache" ] && echo made || echo none) calls=$(_b7b_rows "$B7PC/calls")" "exit=0 out=0 cache=none calls=0"
_b7p_run ok startup --report -
_b7p_is jq "b07 A81: --report on the served run's cache exits 0, with a carried line for each fetch entry, gamma's line and a base line (control)" \
  "exit=$B7P_RC carried=$(_b7p_lead "$B7P_O" carried superpowers alpha beta) gamma=$(_b7b_in "$B7P_O" gamma) base=$(_b7p_lead "$B7P_O" base base)" \
  "exit=0 carried=all gamma=yes base=all"
_b7p_run ref startup --report -
_b7p_is jq "b07 A82: --report on the refused run's cache exits non-zero, with MISSING lines for alpha and beta (control)" \
  "exit=$(_b7p_nz "$B7P_RC") missing=$(_b7p_lead "$B7P_O" MISSING alpha beta)" "exit=nonzero missing=all"
_b7p_case own serve serve refuse
mkdir -p "$B7P/c/own/P/.claude/skills/brainstorming"; printf 'OWN\n' > "$B7P/c/own/P/.claude/skills/brainstorming/SKILL.md"
_fx_git "$B7P/c/own/P" add .claude/skills/brainstorming/SKILL.md >/dev/null 2>&1
_fx_git "$B7P/c/own/P" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm own >/dev/null 2>&1
_b7p_run own startup --session-start -
_b7p_is jq "b07 A83: a skill the repository tracks is never overwritten: its SKILL.md still reads OWN (control)" \
  "$(cat "$B7PC/P/.claude/skills/brainstorming/SKILL.md" 2>/dev/null)" "OWN"

# ---- the restore: any stub still running is ended by its pid ----
for _b7p_k in $(cat "$B7P"/c/*/pids 2>/dev/null); do kill -0 "$_b7p_k" 2>/dev/null && kill -9 "$_b7p_k" 2>/dev/null; done
rm -f "$B7B/sentinel"; chmod -R u+rwX "$B7B" "$B7P" 2>/dev/null
for _b7b_v in $(compgen -v | LC_ALL=C grep -E '^(B7[A-Z0123456789_]*|_b7[bmp]_[A-Za-z0123456789_]*)$'); do unset "$_b7b_v"; done
for _b7b_f in $(compgen -A function | LC_ALL=C grep -E '^_b7[bmp]_'); do unset -f "$_b7b_f"; done
unset _b7b_v _b7b_f
# <<< b07-prompt-and-toolbox
