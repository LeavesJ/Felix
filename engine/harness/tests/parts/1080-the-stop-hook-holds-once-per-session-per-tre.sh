# >>> hold-once
printf '\nthe Stop hook holds once per session per tree\n'
# Written blind (slot 2a, part B), from the contract alone. Today the Stop hook
# holds at every unflagged stop of a session whose tree no gate has passed, so
# each idle wake-up of a session on the same unverified tree is held again.
# The rule under test: it is held once per (session id, tree id), and the
# stops after that are debt, not holds. Numbers in the comments are the
# contract's rules.
#
# The fixtures are this block's own, so that nothing an earlier section left
# behind can leak in and the block runs the same cut out and run straight after
# the suite's preamble: a Felix home of its own beside a governed checkout, a
# clean checkout, an ungoverned one, and a second home that is itself the
# checkout it governs (rule 11 is only a question when state/ sits inside the
# tree whose identity is taken). Every hook run goes through one runner that
# kills a run that has not ended in 20 s, so a hang is a failure here and not a
# suite that never ends, and reports what the run printed, how it exited and
# what it added to verification.log.
HO="$TMP/hold-once"
HOMEM="$HO/memory"
HOROOT="$HO/home"
HOPROJ="$HOROOT/projects/hoproj"
HOREPO="$HO/repo"
HOCLEAN="$HO/clean"
HOPLAIN="$HO/plain"
HOSELF="$HO/self"
mkdir -p "$HOPROJ" "$HOMEM/hoproj" "$HOMEM/self" "$HOROOT/harness" "$HOREPO" "$HOCLEAN" "$HOPLAIN" \
         "$HOSELF/projects/self" "$HOSELF/harness"
_copy_content "$REAL_HARNESS" "$HOROOT/harness"
_copy_content "$REAL_HARNESS" "$HOSELF/harness"
cat > "$HOPROJ/project.json" <<'HO_PROJECT_JSON'
{
  "name": "hoproj",
  "gate": "sh -c 'test -f WORK.txt && echo hoproj-gate-ran'"
}
HO_PROJECT_JSON
printf '# hoproj\n' > "$HOPROJ/CLAUDE.md"
# One probe, so a receipt the helpers stamp carries an epoch: a project that
# declares none has a receipt resting on nothing, and that is stale by design.
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$HOPROJ/probes.tsv"
printf '{ "name": "self", "gate": "true" }\n' > "$HOSELF/projects/self/project.json"
printf '# self\n' > "$HOSELF/projects/self/CLAUDE.md"
printf 'code\t-\t-\tgit ls-files\ttest -e .git\n' > "$HOSELF/projects/self/probes.tsv"
for _ho_d in "$HOREPO" "$HOCLEAN"; do
  ( _fx_cd "${_ho_d:?}" && git init -q -b main && printf 'base\n' > WORK.txt && printf 'hoproj\n' > .felix \
    && git add -A >/dev/null 2>&1 && git -c user.name=t -c user.email=t@t commit -qm init >/dev/null 2>&1 )
done
( _fx_cd "${HOPLAIN:?}" && git init -q -b main && printf 'x\n' > a.txt \
  && git add -A >/dev/null 2>&1 && git -c user.name=t -c user.email=t@t commit -qm init >/dev/null 2>&1 )
( _fx_cd "${HOSELF:?}" && git init -q -b main && printf 'x\n' > code.txt && printf 'self\n' > .felix \
  && git add -A >/dev/null 2>&1 && git -c user.name=t -c user.email=t@t commit -qm init >/dev/null 2>&1 )
HOREPO="$(cd "${HOREPO:?}" && pwd -P)"
HOCLEAN="$(cd "${HOCLEAN:?}" && pwd -P)"
HOPLAIN="$(cd "${HOPLAIN:?}" && pwd -P)"
HOSELF="$(cd "${HOSELF:?}" && pwd -P)"
printf 'dirty\n' >> "$HOPLAIN/a.txt"
printf 'real work\n' >> "$HOSELF/code.txt"
HONIGHTS="$HOMEM/hoproj/overnight/nights"
HOTX="$HO/transcript.jsonl"; : > "$HOTX"

# Which fixture the helpers talk to: the external home (the default) or the
# home that is the checkout it governs.
_ho_use() {   # ext | self
  case "$1" in
    self) HOHOME="$HOSELF"; HODIR="$HOSELF"; HOLOG="$HOMEM/self/verification.log" ;;
    *)    HOHOME="$HOROOT"; HODIR="$HOREPO"; HOLOG="$HOMEM/hoproj/verification.log" ;;
  esac
  HOSTATE="$HOHOME/state"
}
_ho_use ext
_ho_lib() { ( export FELIX_HOME="$HOHOME" FELIX_MEMORY="$HOMEM"
              . "$HOHOME/harness/lib/resolve.sh"; . "$HOHOME/harness/lib/verify.sh"; "$@" ); }
# The identity of the tree as it stands, taken the way the hook takes it and
# not read back from anything the hook wrote.
_ho_tid()       { _ho_lib felix_tree_id "$HODIR" "$HOHOME"; }
_ho_receipt()   { _ho_lib felix_verify_record "$HODIR" "$HOHOME" "$1" ho-gate "$(_ho_tid)" "" >/dev/null 2>&1; }
_ho_noreceipt() { rm -f "$(_ho_lib _felix_receipt_path "$HODIR" "$HOHOME")"; }
# The work tree is the committed "base" plus at most one line, so a tree named
# by its line is the same tree whenever it comes back.
_ho_edit()  { printf 'base\n%s\n' "$1" > "$HOREPO/WORK.txt"; }
# Restated after the review, not blind (the contract's addendum A): a record
# line is the tree id, the reason and the checkout, tab-separated. _ho_rec reads
# the tree ids a record holds, and _ho_seed lays a whole line, the reason "never
# checked" and the checkout the helpers talk to unless it is told otherwise.
_ho_rec()   { cut -f1 "$HOSTATE/held-tree/$1" 2>/dev/null; }
_ho_seed()  { mkdir -p "$HOSTATE/held-tree" \
                && printf '%s\t%s\t%s\n' "$2" "${3:-never checked}" "${4:-$HODIR}" > "$HOSTATE/held-tree/$1"; }
_ho_rows()  { awk 'END { print NR + 0 }' "$HOLOG" 2>/dev/null || printf '0'; }
_ho_field() { printf '%s' "$HO_ROW" | cut -f"$1"; }
_ho_pay() {   # session id [, flag [, transcript]] -> a Stop payload
  local t=""
  [ -n "${3:-}" ] && t=",\"transcript_path\":\"$3\""
  printf '{"hook_event_name":"Stop","stop_hook_active":%s,"session_id":"%s"%s}' "${2:-false}" "$1" "$t"
}
_ho_tool() { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash"}]}}\n' >> "$HOTX"; }
_ho_tree_of() {   # pid -> it and everything below it
  ps -A -o pid= -o ppid= 2>/dev/null | awk -v root="$1" '
    { kids[$2] = kids[$2] " " $1 }
    END { q = root; out = ""
          while (q != "") { n = split(q, a, " "); q = ""
                            for (i = 1; i <= n; i++) if (a[i] != "") { out = out " " a[i]; q = q kids[a[i]] } }
          print out }'
}
# One hook run. Sets HO_OUT (stdout), HO_RC (exit status, or 124 when the run
# had not ended in 20 s and was killed), HO_NEW (rows it added to
# verification.log) and HO_ROW (the last of them). HO_FIFO, when set, is
# opened read-write after a kill, which lets go of anything left on it.
_ho_run() {   # hook, dir, payload [, NAME=value ...]
  local hook="$1" dir="$2" payload="$3" pid n=0 k n0
  shift 3
  n0="$(_ho_rows)"
  rm -f "$HO/hook.out" "$HO/hook.err" "$HO/hook.rc"
  ( cd "${dir:?}" && printf '%s' "$payload" \
      | env -u FELIX_ALLOW_RED FELIX_HOME="$HOHOME" FELIX_MEMORY="$HOMEM" "$@" "$hook" \
          > "$HO/hook.out" 2> "$HO/hook.err"
    echo "$?" > "$HO/hook.rc" ) &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$n" -lt 200 ]; do sleep 0.1; n=$((n + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    for k in $(_ho_tree_of "$pid"); do kill -9 "$k" 2>/dev/null; done
    wait "$pid" 2>/dev/null
    [ -n "${HO_FIFO:-}" ] && [ -p "$HO_FIFO" ] && ( exec 9<>"$HO_FIFO" ) 2>/dev/null
    HO_RC=124
  else
    wait "$pid" 2>/dev/null
    HO_RC="$(cat "$HO/hook.rc" 2>/dev/null)"; HO_RC="${HO_RC:-none}"
  fi
  HO_OUT="$(cat "$HO/hook.out" 2>/dev/null)"
  HO_NEW=$(( $(_ho_rows) - n0 ))
  HO_ROW=""
  [ "$HO_NEW" -gt 0 ] && HO_ROW="$(tail -1 "$HOLOG" 2>/dev/null)"
  return 0
}
_ho_stop()  { _ho_run "$HOHOME/harness/hooks/stop" "$HODIR" "$(_ho_pay "$@")"; }   # session id [, flag [, transcript]]
_ho_stopp() { local dir="$1" pay="$2"; shift 2; _ho_run "$HOHOME/harness/hooks/stop" "$dir" "$pay" "$@"; }
# What the last run did, in one word per fact:
#   <block|silent|other>:<exit status>:<rows added>:<verdict of the last row, or ->
# or "hung". A hold is block:0:1:blocked, debt is silent:0:1:debt, and a stop
# that ends at the flag with nothing said is silent:0:0:-.
_ho_sum() {
  local kind v
  [ "$HO_RC" = 124 ] && { printf 'hung'; return 0; }
  case "$HO_OUT" in
    '')                      kind=silent ;;
    *'"decision": "block"'*) kind=block ;;
    *)                       kind=other ;;
  esac
  v="-"
  [ "$HO_NEW" -gt 0 ] && v="$(_ho_field 2)"
  printf '%s:%s:%s:%s' "$kind" "$HO_RC" "$HO_NEW" "$v"
}
_ho_night() {   # session id, continuations
  ( export FELIX_HOME="$HOROOT" FELIX_MEMORY="$HOMEM"
    . "$HOROOT/harness/lib/resolve.sh"; . "$HOROOT/harness/lib/overnight.sh"
    felix_overnight_start "$HOPROJ" 8 "$2" "$1" "the hold-once block's night" ) >/dev/null 2>&1
}
_ho_night_end() {
  ( export FELIX_HOME="$HOROOT" FELIX_MEMORY="$HOMEM"
    . "$HOROOT/harness/lib/resolve.sh"; . "$HOROOT/harness/lib/overnight.sh"
    felix_overnight_end "$HOPROJ" "the hold-once block is over" "$1" ) >/dev/null 2>&1
}
_ho_night_left() { awk -F'\t' 'NR == 1 { print $3 }' "$HONIGHTS/$1" 2>/dev/null; }
# The receipt state of the tree as it stands, in the four ways a gate leaves a
# tree unpassed. The tree is left at "one".
_ho_prepare() {   # never | stale | failed | epoch
  rm -f "$HOPROJ/stack.tsv"
  _ho_noreceipt
  case "$1" in
    stale)  _ho_edit zero; _ho_receipt 0; _ho_edit one ;;
    failed) _ho_edit one;  _ho_receipt 1 ;;
    epoch)  _ho_edit one;  _ho_receipt 0
            printf 'plugin\tsomething-else@x\t-\tlow\talways\n' > "$HOPROJ/stack.tsv" ;;
    *)      _ho_edit one ;;
  esac
}

# ---- 1 and 3: the first stop holds as it always did, and leaves a record ----
_ho_prepare never
HOT1="$(_ho_tid)"
_ho_stop ho-a
is  "the Stop hook still holds the first unflagged stop of a session on a tree no gate has passed, with the block decision and exit status 0" \
    "$(_ho_sum)" "block:0:1:blocked"
has "the Stop hook still gives that first hold the reason it gave when the gate never ran" \
    "$HO_OUT" '"reason": "The gate has never run in this checkout.'
has "the Stop hook still tells the held session not to describe the work as complete" \
    "$HO_OUT" "Do not describe this work as complete until it has passed."
has "the Stop hook still names felix gate as the way to pass" "$HO_OUT" '\n\n  felix gate\n\n'
has "the Stop hook still says the way past a red gate is the founder's FELIX_ALLOW_RED and not the session's" \
    "$HO_OUT" "they can set FELIX_ALLOW_RED=1 in the environment they"
has "the Stop hook still says a session cannot grant itself an exceptions.tsv row" \
    "$HO_OUT" "a session cannot grant itself one."
_ho_nl=$'\n'
case "$HO_OUT" in
  '{'"$_ho_nl"'  "decision": "block",'"$_ho_nl"'  "reason": "'*'"'"$_ho_nl"'}')
    ok  "the Stop hook still prints the block as a JSON object with the decision on its second line and the reason on its third" ;;
  *)
    bad "the Stop hook still prints the block as a JSON object with the decision on its second line and the reason on its third" "[$HO_OUT]" ;;
esac
is  "the Stop hook's first hold writes a blocked row naming the tree and never checked as the reason" \
    "$(_ho_field 2-4)" "$(printf 'blocked\t%s\tnever checked' "$HOT1")"
is  "the Stop hook records the tree id of a first hold in state/held-tree under the session id" \
    "$(_ho_rec ho-a)" "$HOT1"
is  "the Stop hook's record of a first hold is exactly one line" \
    "$(awk 'END { print NR + 0 }' "$HOSTATE/held-tree/ho-a" 2>/dev/null)" "1"

# 2: the flagged stop right after Felix's own hold ends at the flag.
_ho_stop ho-a true
is  "the Stop hook ends the flagged stop right after its own hold at the flag: silent, exit status 0, no row" \
    "$(_ho_sum)" "silent:0:0:-"

# 3: a later unflagged stop of the same session on the same tree is debt.
_ho_stop ho-a
is  "the Stop hook does not hold a later unflagged stop of the same session on the same tree: it is silent, exits 0 and adds a debt row" \
    "$(_ho_sum)" "silent:0:1:debt"
is  "the Stop hook prints nothing to stdout for a stop it does not hold" "$HO_OUT" ""
is  "the Stop hook's debt row has the verdict debt in its second field and the tree the session was held on in its third" \
    "$(_ho_field 2-3)" "$(printf 'debt\t%s' "$HOT1")"
has "the Stop hook's debt row says in its fourth field that the tree was held once on this tree already" \
    "$(_ho_field 4)" "held once on this tree already"
for _ho_i in 3 4; do
  _ho_stop ho-a
  is  "the Stop hook adds a debt row and holds nothing at unflagged stop number $_ho_i of the same session on the same tree" \
      "$(_ho_sum)" "silent:0:1:debt"
done
# The record read, not the writer: a record laid by hand in the contract's
# shape, one line holding the tree id, the reason and the checkout, is all a
# session needs to be past its hold. Restated after the review, not blind.
_ho_seed ho-seed "$HOT1"
_ho_stop ho-seed
is  "the Stop hook treats a record line holding the tree id, the reason and the checkout as a hold already made, and adds a debt row" \
    "$(_ho_sum)" "silent:0:1:debt"
_ho_seed ho-other "0000000000000000000000000000000000000000"
_ho_stop ho-other
is  "the Stop hook holds a session whose record names a different tree" "$(_ho_sum)" "block:0:1:blocked"
has "the Stop hook records the tree it held on in a record that named a different tree" "$(_ho_rec ho-other)" "$HOT1"

# 1 and 3 again, for each way a gate leaves a tree unpassed: held once, then debt.
for _ho_k in never stale failed epoch; do
  case "$_ho_k" in
    never)  _ho_lab="the gate never ran";                          _ho_det="never checked" ;;
    stale)  _ho_lab="the receipt is for a different tree";         _ho_det="stale receipt" ;;
    failed) _ho_lab="the gate failed on this tree";                _ho_det="failed" ;;
    epoch)  _ho_lab="the gate passed on this tree and the epoch moved"; _ho_det="epoch moved" ;;
  esac
  _ho_prepare "$_ho_k"
  _ho_t="$(_ho_tid)"
  _ho_stop "ho-k-$_ho_k"
  is  "the Stop hook holds the first stop once when $_ho_lab, and the blocked row says $_ho_det" \
      "$(_ho_sum):$(_ho_field 3):$(_ho_field 4)" "block:0:1:blocked:$_ho_t:$_ho_det"
  is  "the Stop hook records the tree for that first hold when $_ho_lab" "$(_ho_rec "ho-k-$_ho_k")" "$_ho_t"
  _ho_stop "ho-k-$_ho_k"
  is  "the Stop hook does not hold the second stop on the same tree when $_ho_lab, and the debt row names that tree" \
      "$(_ho_sum):$(_ho_field 3)" "silent:0:1:debt:$_ho_t"
done
rm -f "$HOPROJ/stack.tsv"

# ---- 4: a changed tree is held once more, and a tree already held on is debt ----
_ho_prepare never
_ho_stop ho-chg
is  "the Stop hook holds the first stop of a session that will see three trees" "$(_ho_sum)" "block:0:1:blocked"
_ho_edit two
HOT2="$(_ho_tid)"
_ho_stop ho-chg
is  "the Stop hook holds the same session again at the next unflagged stop once the tree has changed" "$(_ho_sum)" "block:0:1:blocked"
is  "the Stop hook's second hold of that session names the changed tree" "$(_ho_field 3)" "$HOT2"
has "the Stop hook keeps the first tree in the session's record when it records the changed one" "$(_ho_rec ho-chg)" "$HOT1"
has "the Stop hook records the changed tree too" "$(_ho_rec ho-chg)" "$HOT2"
_ho_stop ho-chg
is  "the Stop hook holds the changed tree only once: the next unflagged stop on it is debt" "$(_ho_sum)" "silent:0:1:debt"
_ho_edit one
_ho_stop ho-chg
is  "the Stop hook does not hold a session when the tree returns to one the session was held on" "$(_ho_sum)" "silent:0:1:debt"
is  "the Stop hook's debt row for the returning tree names the returning tree" \
    "$(_ho_field 2-3)" "$(printf 'debt\t%s' "$HOT1")"
_ho_edit two
_ho_stop ho-chg
is  "the Stop hook does not hold a session when the tree moves forward again to the other tree it was held on" \
    "$(_ho_sum)" "silent:0:1:debt"
_ho_edit three
HOT3="$(_ho_tid)"
_ho_stop ho-chg
is  "the Stop hook holds a third tree once, and names it in the blocked row" "$(_ho_sum):$(_ho_field 3)" "block:0:1:blocked:$HOT3"
_ho_stop ho-chg
is  "the Stop hook does not hold the third tree a second time" "$(_ho_sum)" "silent:0:1:debt"

# ---- 5: another session on the same tree is held once for itself ----
_ho_edit one
_ho_stop ho-s2
is  "the Stop hook holds a second session on a tree the first session was already held on" "$(_ho_sum):$(_ho_field 3)" "block:0:1:blocked:$HOT1"
is  "the Stop hook keeps a record of its own for the second session" "$(_ho_rec ho-s2)" "$HOT1"
_ho_stop ho-s2
is  "the Stop hook holds the second session only once on that tree" "$(_ho_sum)" "silent:0:1:debt"
_ho_stop ho-s3
is  "the Stop hook holds a third session on the same tree once for itself too" "$(_ho_sum)" "block:0:1:blocked"
_ho_stop ho-a
is  "the Stop hook leaves the first session's debt as it was while other sessions are held on the tree" "$(_ho_sum)" "silent:0:1:debt"

# ---- 6: a stop inside another hook's chain ----
# The hold Felix makes is followed by one flagged stop that ends at the flag.
# A flagged stop after that one belongs to someone else's chain.
_ho_stop ho-fgn
is  "the Stop hook holds the first stop of a session that will later be stopped inside another hook's chain" "$(_ho_sum)" "block:0:1:blocked"
_ho_stop ho-fgn true
is  "the Stop hook ends the flagged stop after that hold at the flag" "$(_ho_sum)" "silent:0:0:-"
_ho_stop ho-fgn true
is  "the Stop hook does not hold a flagged stop inside another hook's chain on a tree already held on for the session: it is debt" \
    "$(_ho_sum):$(_ho_field 3)" "silent:0:1:debt:$HOT1"
has "the Stop hook's debt row for a stop inside another hook's chain says the tree was held once already" \
    "$(_ho_field 4)" "held once on this tree already"
_ho_seed ho-fgn2 "$HOT1"
_ho_stop ho-fgn2 true
is  "the Stop hook treats a flagged stop with no hold of Felix's on record as debt when the session's record names the tree" \
    "$(_ho_sum)" "silent:0:1:debt"
# A debt stop is not a hold of Felix's, so the flagged stop after it is not
# Felix's own chain either: it is another hook's, on a tree already held on.
_ho_stop ho-fgn5
_ho_stop ho-fgn5
is  "the Stop hook has the session of the next case on debt before the flagged stop reaches it (control)" \
    "$(_ho_sum)" "silent:0:1:debt"
_ho_stop ho-fgn5 true
is  "the Stop hook treats a flagged stop right after a debt stop as another hook's chain on a held tree: debt, not silence at the flag" \
    "$(_ho_sum)" "silent:0:1:debt"
# The other half: a tree not recorded for the session is judged as today. The
# session is held once on one tree, its flagged stop ends at the flag, and then
# the tree changes and a flagged stop with no hold of Felix's behind it arrives.
_ho_stop ho-fgn4
_ho_stop ho-fgn4 true
_ho_edit two
_ho_stop ho-fgn4 true
is  "the Stop hook still judges a flagged stop inside another hook's chain on a tree not recorded for the session, and holds it" \
    "$(_ho_sum):$(_ho_field 3)" "block:0:1:blocked:$HOT2"
has "the Stop hook records the tree it held inside another hook's chain, as it does for any first hold" \
    "$(_ho_rec ho-fgn4)" "$HOT2"
_ho_edit one
_ho_stop ho-fgn3 true
is  "the Stop hook still holds a flagged stop in another hook's chain for a session it has never held" "$(_ho_sum)" "block:0:1:blocked"

# ---- 7: what does not change ----
# A night's chain: the session holds a night, so a hold is charged to the night
# every time, whatever the session's record says. The record is laid by hand,
# naming the tree, so that only the night keeps the hold a hold.
_ho_prepare never
HOT1="$(_ho_tid)"
_ho_night ho-night 12
is  "the Stop hook's night fixture starts with twelve continuations (control)" "$(_ho_night_left ho-night)" "12"
_ho_seed ho-night "$HOT1"
for _ho_i in 1 2 3; do
  _ho_tool
  _ho_run "$HOHOME/harness/hooks/stop" "$HODIR" "$(_ho_pay ho-night true "$HOTX")"
  is  "the Stop hook holds the night's chain again at its flagged stop number $_ho_i though the tree is on the session's record" \
      "$(_ho_sum)" "block:0:1:blocked"
  is  "the Stop hook charges flagged stop number $_ho_i of the night's chain to the night" \
      "$(_ho_night_left ho-night)" "$((12 - _ho_i))"
done
_ho_night_end ho-night

# FELIX_ALLOW_RED: an override row, no hold, nothing recorded.
_ho_stopp "$HODIR" "$(_ho_pay ho-red)" FELIX_ALLOW_RED=1
is  "the Stop hook lets a founder's FELIX_ALLOW_RED stop through in silence with an override row" "$(_ho_sum)" "silent:0:1:override"
is  "the Stop hook's override row names the tree" "$(_ho_field 3)" "$HOT1"
[ ! -e "$HOSTATE/held-tree/ho-red" ] \
  && ok  "the Stop hook records nothing for a stop the override let through" \
  || bad "the Stop hook records nothing for a stop the override let through" "$(_ho_rec ho-red)"
_ho_stopp "$HODIR" "$(_ho_pay ho-red)" FELIX_ALLOW_RED=1
is  "the Stop hook lets the override through again at the next stop, still an override and not debt" "$(_ho_sum)" "silent:0:1:override"
_ho_stop ho-red
is  "the Stop hook holds the session once the override is gone, for the first time, because the override recorded nothing" \
    "$(_ho_sum)" "block:0:1:blocked"

# A current green gate: allowed, nothing recorded.
_ho_receipt 0
_ho_stop ho-green
is  "the Stop hook allows a stop on a tree the gate has passed, in silence, with an allowed row" "$(_ho_sum)" "silent:0:1:allowed"
is  "the Stop hook's allowed row for a current green gate says green and names the tree" \
    "$(_ho_field 3):$(_ho_field 4)" "$HOT1:green"
[ ! -e "$HOSTATE/held-tree/ho-green" ] \
  && ok  "the Stop hook records nothing for a stop the green gate allowed" \
  || bad "the Stop hook records nothing for a stop the green gate allowed" "$(_ho_rec ho-green)"
_ho_noreceipt
_ho_stop ho-green
is  "the Stop hook holds the session once the green receipt is gone, for the first time, because the green gate recorded nothing" \
    "$(_ho_sum)" "block:0:1:blocked"

# The override and the green gate speak before the hold does, whatever the
# session's record says: a session held on this tree is let through by either.
_ho_stop ho-late
is  "the Stop hook holds the first stop of the session the override and the green gate will later let through" "$(_ho_sum)" "block:0:1:blocked"
_ho_stopp "$HODIR" "$(_ho_pay ho-late)" FELIX_ALLOW_RED=1
is  "the Stop hook still writes an override row, and not debt, for a session already held on this tree" "$(_ho_sum)" "silent:0:1:override"
_ho_receipt 0
_ho_stop ho-late
is  "the Stop hook still writes an allowed row, and not debt, for a session already held on this tree once the gate has passed it" \
    "$(_ho_sum):$(_ho_field 4)" "silent:0:1:allowed:green"
_ho_noreceipt

# A clean tree with nothing committed by the session: silent, nothing recorded.
_ho_stopp "$HOCLEAN" "$(_ho_pay ho-clean)"
is  "the Stop hook stays silent on a clean tree the session committed nothing to, adds no row and exits 0" "$(_ho_sum)" "silent:0:0:-"
[ ! -e "$HOSTATE/held-tree/ho-clean" ] \
  && ok  "the Stop hook records nothing for a clean tree" \
  || bad "the Stop hook records nothing for a clean tree" "$(_ho_rec ho-clean)"

# A directory nothing governs, with an unverified change in it.
_ho_stopp "$HOPLAIN" "$(_ho_pay ho-plain)"
is  "the Stop hook stays silent in a directory nothing governs, adds no row and exits 0" "$(_ho_sum)" "silent:0:0:-"
[ ! -e "$HOSTATE/held-tree/ho-plain" ] \
  && ok  "the Stop hook records nothing for a directory nothing governs" \
  || bad "the Stop hook records nothing for a directory nothing governs" "$(_ho_rec ho-plain)"

# ---- 8: an id that cannot name a file is held at every stop ----
_ho_edit one
_ho_before="$(ls -A "$HOSTATE/held-tree" 2>/dev/null | LC_ALL=C sort)"
_ho_long="ho-$(printf '%0126d' 0)"
is  "the Stop hook's over-long session id is 129 characters (control)" "${#_ho_long}" "129"
for _ho_id in '..' '.' '-ho-dash' 'ho sp ace' 'ho/slash' '../ho-escape' "$_ho_long" ''; do
  case "$_ho_id" in
    '')                _ho_idl="an empty" ;;
    "$_ho_long")       _ho_idl="a 129-character" ;;
    *)                 _ho_idl="the" ;;
  esac
  _ho_stop "$_ho_id"; _ho_a="$(_ho_sum)"
  _ho_stop "$_ho_id"; _ho_b="$(_ho_sum)"
  is  "the Stop hook holds both of two unflagged stops in a row for $_ho_idl session id [${_ho_id:0:12}]" \
      "$_ho_a $_ho_b" "block:0:1:blocked block:0:1:blocked"
done
_ho_run "$HOHOME/harness/hooks/stop" "$HODIR" '{"hook_event_name":"Stop","stop_hook_active":false}'; _ho_a="$(_ho_sum)"
_ho_run "$HOHOME/harness/hooks/stop" "$HODIR" '{"hook_event_name":"Stop","stop_hook_active":false}'; _ho_b="$(_ho_sum)"
is  "the Stop hook holds both of two unflagged stops in a row that carry no session id at all" \
    "$_ho_a $_ho_b" "block:0:1:blocked block:0:1:blocked"
is  "the Stop hook leaves no record behind for any id that cannot name a file" \
    "$(ls -A "$HOSTATE/held-tree" 2>/dev/null | LC_ALL=C sort)" "$_ho_before"
[ ! -e "$HOSTATE/ho-escape" ] && [ ! -e "$HOSTATE/held-tree/ho" ] \
  && ok  "the Stop hook writes no record outside state/held-tree for an id that names a parent directory or a path" \
  || bad "the Stop hook writes no record outside state/held-tree for an id that names a parent directory or a path" \
         "$(ls -A "$HOSTATE" 2>/dev/null | tr '\n' ' ')"
# The edge of the rule: 128 characters can name a file, and a mix of the allowed
# characters can too, so both are held once and then are debt.
_ho_ok128="ho-$(printf '%0125d' 0)"
is  "the Stop hook's longest usable session id is 128 characters (control)" "${#_ho_ok128}" "128"
_ho_stop "$_ho_ok128"; _ho_a="$(_ho_sum)"
_ho_stop "$_ho_ok128"; _ho_b="$(_ho_sum)"
is  "the Stop hook holds a 128-character session id once and then adds debt, as it does for any id that can name a file" \
    "$_ho_a $_ho_b" "block:0:1:blocked silent:0:1:debt"
_ho_stop 'ho.v_1-Z'; _ho_a="$(_ho_sum)"
_ho_stop 'ho.v_1-Z'; _ho_b="$(_ho_sum)"
is  "the Stop hook holds a session id made of letters, digits, dot, dash and underscore once and then adds debt" \
    "$_ho_a $_ho_b" "block:0:1:blocked silent:0:1:debt"

# ---- 9: where the record cannot be read or written, the hook holds as today ----
# Never hangs, never treats the tree as already held. Each case is a session of
# its own on a tree no gate has passed.
_ho_edit one
rm -rf "${HOSTATE:?}/held-tree"
: > "$HOSTATE/held-tree"
_ho_stop ho-file; _ho_a="$(_ho_sum)"
_ho_stop ho-file; _ho_b="$(_ho_sum)"
is  "the Stop hook holds both of two stops in a row when state/held-tree is a regular file and not a directory" \
    "$_ho_a $_ho_b" "block:0:1:blocked block:0:1:blocked"
rm -f "$HOSTATE/held-tree"
if [ "$(id -u)" = "0" ]; then
  skip "the Stop hook holds both of two stops in a row when state/held-tree is not writable" "running as root"
  skip "the Stop hook holds a stop whose record is a file it cannot read" "running as root"
else
  mkdir -p "$HOSTATE/held-tree" && chmod 555 "$HOSTATE/held-tree"
  _ho_stop ho-ro; _ho_a="$(_ho_sum)"
  _ho_stop ho-ro; _ho_b="$(_ho_sum)"
  chmod 755 "$HOSTATE/held-tree"
  is  "the Stop hook holds both of two stops in a row when state/held-tree is not writable" \
      "$_ho_a $_ho_b" "block:0:1:blocked block:0:1:blocked"
  _ho_seed ho-unread "$HOT1"
  chmod 000 "$HOSTATE/held-tree/ho-unread"
  _ho_stop ho-unread
  chmod 644 "$HOSTATE/held-tree/ho-unread"
  is  "the Stop hook holds a stop whose record is a file it cannot read" "$(_ho_sum)" "block:0:1:blocked"
fi
rm -rf "${HOSTATE:?}/held-tree"; mkdir -p "$HOSTATE/held-tree"
: > "$HOSTATE/held-tree/ho-empty"
_ho_stop ho-empty
is  "the Stop hook holds a stop whose record is an empty file, which holds no tree" "$(_ho_sum)" "block:0:1:blocked"
mkfifo "$HOSTATE/held-tree/ho-fifo"
HO_FIFO="$HOSTATE/held-tree/ho-fifo"
_ho_stop ho-fifo
is  "the Stop hook holds, and does not hang, when the session's record is a FIFO" "$(_ho_sum)" "block:0:1:blocked"
rm -f "$HO_FIFO"; HO_FIFO=""
mkdir "$HOSTATE/held-tree/ho-dir"
_ho_stop ho-dir
is  "the Stop hook holds, and does not hang, when the session's record is a directory" "$(_ho_sum)" "block:0:1:blocked"
rm -rf "${HOSTATE:?}/held-tree/ho-dir"
mkfifo "$HO/fifo-target"
ln -s "$HO/fifo-target" "$HOSTATE/held-tree/ho-link"
HO_FIFO="$HO/fifo-target"
_ho_stop ho-link
is  "the Stop hook holds, and does not hang, when the session's record is a link to a FIFO" "$(_ho_sum)" "block:0:1:blocked"
rm -f "$HOSTATE/held-tree/ho-link" "$HO/fifo-target"; HO_FIFO=""
rm -rf "${HOSTATE:?}/held-tree"

# ---- 10: SessionEnd removes the record of its own session ----
_ho_end() {   # session id
  _ho_run "$HOHOME/harness/hooks/session-end" "$HODIR" \
          "$(printf '{"hook_event_name":"SessionEnd","session_id":"%s","reason":"other"}' "$1")"
}
_ho_edit one
_ho_stop ho-end1
_ho_stop ho-end2
is  "the Stop hook's two sessions each have a record before the first one ends (control)" \
    "$(_ho_rec ho-end1):$(_ho_rec ho-end2)" "$HOT1:$HOT1"
_ho_had="no"; [ -f "$HOSTATE/held-tree/ho-end1" ] && _ho_had="yes"
_ho_end ho-end1
is  "the Stop hook's SessionEnd exits 0 for a session that has a record" "$HO_RC" "0"
_ho_gone="present"; [ -e "$HOSTATE/held-tree/ho-end1" ] || [ -L "$HOSTATE/held-tree/ho-end1" ] || _ho_gone="gone"
is  "the Stop hook's SessionEnd removes the record the session had" "$_ho_had:$_ho_gone" "yes:gone"
is  "the Stop hook's SessionEnd leaves another session's record as it was" "$(_ho_rec ho-end2)" "$HOT1"
_ho_stop ho-end1
is  "the Stop hook holds a session again on the same tree once SessionEnd has removed its record, and records it afresh" \
    "$(_ho_sum):$(_ho_rec ho-end1)" "block:0:1:blocked:$HOT1"
_ho_end ho-never-held
is  "the Stop hook's SessionEnd exits 0 for a session that was never held" "$HO_RC" "0"
# Records laid by hand, so these hold whatever else is on record: an id that
# cannot name a file takes nothing with it, neither a neighbour's record nor
# anything beside the directory.
_ho_seed ho-keep-rec "$HOT1"
printf '%s\n' keep > "$HOSTATE/ho-keep"
for _ho_id in '.' '..' '../ho-keep'; do
  _ho_end "$_ho_id"
  [ "$(_ho_rec ho-keep-rec)" = "$HOT1" ] && [ "$(cat "$HOSTATE/ho-keep" 2>/dev/null)" = "keep" ] \
    && ok  "the Stop hook's SessionEnd removes nothing at all for a session id that cannot name a file [$_ho_id]" \
    || bad "the Stop hook's SessionEnd removes nothing at all for a session id that cannot name a file [$_ho_id]" \
           "ho-keep-rec record [$(_ho_rec ho-keep-rec)], ho-keep [$(cat "$HOSTATE/ho-keep" 2>/dev/null)]"
done
rm -f "$HOSTATE/ho-keep"

# ---- 11: the record is not part of the tree's identity ----
# With the home outside the checkout this is trivially so. The second home is
# the checkout it governs, so state/ is inside the tree and only the exclusion
# keeps a record from changing the tree the next stop judges.
_ho_use self
HOS0="$(_ho_tid)"
_ho_stop ho-self
is  "the Stop hook holds the first stop in a home that is the checkout it governs, and names the tree as it stood" \
    "$(_ho_sum):$(_ho_field 3)" "block:0:1:blocked:$HOS0"
is  "the Stop hook's record in the governed home holds the tree id the blocked row names" "$(_ho_rec ho-self)" "$HOS0"
is  "the Stop hook's record inside the tree leaves the tree's identity as it was" \
    "$(_ho_rec ho-self):$(_ho_tid)" "$HOS0:$HOS0"
_ho_stop ho-self
is  "the Stop hook judges the same tree at the stop after a hold in a home that is the checkout it governs: debt" \
    "$(_ho_sum):$(_ho_field 3)" "silent:0:1:debt:$HOS0"
is  "the Stop hook's debt row, its record and the tree id taken independently all name one tree" \
    "$(_ho_field 3):$(_ho_rec ho-self):$(_ho_tid)" "$HOS0:$HOS0:$HOS0"
_ho_use ext
_ho_edit one
_ho_stop ho-ids
_ho_a="$(_ho_field 3)"
_ho_stop ho-ids
is  "the Stop hook's blocked row, debt row, record and independently taken tree id are one tree id" \
    "$_ho_a:$(_ho_field 3):$(_ho_rec ho-ids)" "$HOT1:$HOT1:$HOT1"

# ---- the restore ----
chmod -R u+rwX "$HO" 2>/dev/null
rm -f "$HO/fifo-target" "$HO/hook.out" "$HO/hook.err" "$HO/hook.rc"
unset HO HOMEM HOROOT HOPROJ HOREPO HOCLEAN HOPLAIN HOSELF HONIGHTS HOTX HOHOME HODIR HOLOG HOSTATE \
      HOT1 HOT2 HOT3 HOS0 HO_OUT HO_RC HO_NEW HO_ROW HO_FIFO \
      _ho_d _ho_i _ho_k _ho_lab _ho_det _ho_t _ho_a _ho_b _ho_id _ho_idl _ho_long _ho_ok128 _ho_before \
      _ho_nl _ho_had _ho_gone
unset -f _ho_use _ho_lib _ho_tid _ho_receipt _ho_noreceipt _ho_edit _ho_rec _ho_seed _ho_rows \
         _ho_field _ho_pay _ho_tool _ho_tree_of _ho_run _ho_stop _ho_stopp _ho_sum _ho_night _ho_night_end \
         _ho_night_left _ho_prepare _ho_end
# <<< hold-once
