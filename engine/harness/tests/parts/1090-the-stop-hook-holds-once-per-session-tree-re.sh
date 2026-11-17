# >>> held-reason
printf '\nthe Stop hook holds once per session, tree, reason and checkout\n'
# Written blind (slot 2a, part B, the addendum A to I), from the contract alone.
# The first round of this work covers rules 1 to 11: a session is held once per
# tree, and the stops after that are debt. The addendum made the key finer and
# closed the holes an adversarial review found:
#
#   A  a hold is the tree id, the reason and the checkout; debt needs all three
#   B  the same tree with a new reason is held again, once
#   C  a session that holds a night is never let through as debt
#   D  an unborn HEAD and a coarse tree id are held at every stop
#   E  the record is written only after the block JSON has been printed
#   F  a person's prompt clears the record, a runtime message does not
#   G  a link at the record is neither read nor written through
#   H  the debt row names the session by its first eight characters
#   I  the monitor page shows a debt row with the warning class
#
# Every assertion states what the contract says and drives the real hooks. A
# negative ("the stop is held") passes on the code before the change too, since
# that code holds at every stop, so wherever the contract's point is that
# something is NOT debt or NOT recorded, the same assertion also needs the
# counterpart that is debt or is recorded, or it says nothing about the change.
# Where an assertion passes before the change on purpose, because it guards the
# change against over-reaching, its name ends in (control).
#
# The fixtures are this block's own, so that nothing an earlier section left
# behind can leak in and the block runs the same cut out and run straight after
# the suite's preamble: a Felix home of its own with one project, a checkout
# bound to it, a second checkout that stands on the very same commit, a checkout
# with no commit yet and one with more untracked files than a tree id counts.
# Every hook run goes through one runner that kills a run that has not ended in
# 20 s (or the limit a case sets, for the cases that mean to stop a hook), so a
# hang is a failure here and not a suite that never ends.
HR_DIR="$TMP/held-reason"
HR_MEM="$HR_DIR/memory"
HR_ROOT="$HR_DIR/home"
HR_PROJ="$HR_ROOT/projects/hrproj"
HR_REPO="$HR_DIR/repo"
HR_REPO2="$HR_DIR/repo2"
HR_UNB="$HR_DIR/unborn"
HR_BIG="$HR_DIR/big"
HR_SP="$HR_DIR/a checkout with spaces"
mkdir -p "$HR_PROJ" "$HR_MEM/hrproj" "$HR_ROOT/harness" "$HR_REPO" "$HR_REPO2" "$HR_UNB" "$HR_BIG" "$HR_SP"
_copy_content "$REAL_HARNESS" "$HR_ROOT/harness"
cat > "$HR_PROJ/project.json" <<'HR_PROJECT_JSON'
{
  "name": "hrproj",
  "gate": "sh -c 'test -f WORK.txt && echo hrproj-gate-ran'"
}
HR_PROJECT_JSON
printf '# hrproj\n' > "$HR_PROJ/CLAUDE.md"
# One probe, so a receipt the helpers stamp carries an epoch: a project that
# declares none has a receipt resting on nothing, and that is stale by design.
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$HR_PROJ/probes.tsv"
# Two checkouts on one commit: the same author, committer, dates and message
# make the same commit object, so with the same edit they have one tree id and
# only the checkout tells them apart.
for _hr_d in "$HR_REPO" "$HR_REPO2" "$HR_BIG" "$HR_SP"; do
  ( _fx_cd "${_hr_d:?}" && git init -q -b main && printf 'base\n' > WORK.txt && printf 'hrproj\n' > .felix \
    && git add -A >/dev/null 2>&1 \
    && GIT_AUTHOR_DATE=2026-01-01T00:00:00Z GIT_COMMITTER_DATE=2026-01-01T00:00:00Z \
       git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm init >/dev/null 2>&1 )
done
# No commit yet: what `git init` leaves.
( _fx_cd "${HR_UNB:?}" && git init -q -b main && printf 'base\n' > WORK.txt && printf 'hrproj\n' > .felix )
# Exactly as many untracked files as a tree id counts before it gives up on them.
( cd "${HR_BIG:?}" && mkdir bulk && cd bulk && seq 1 500 | sed 's/^/f/' | xargs touch )
HR_REPO="$(cd "${HR_REPO:?}" && pwd -P)"
HR_REPO2="$(cd "${HR_REPO2:?}" && pwd -P)"
HR_UNB="$(cd "${HR_UNB:?}" && pwd -P)"
HR_BIG="$(cd "${HR_BIG:?}" && pwd -P)"
HR_SP="$(cd "${HR_SP:?}" && pwd -P)"
mkdir -p "$HR_REPO/sub/deep"
HR_STATE="$HR_ROOT/state"
HR_LOG="$HR_MEM/hrproj/verification.log"
HR_SAYS="$HR_MEM/hrproj/says.log"
HR_NIGHTS="$HR_MEM/hrproj/overnight/nights"
HR_TX="$HR_DIR/transcript.jsonl"; : > "$HR_TX"
HR_WORK="$HR_REPO"     # the checkout the stop helpers run in
HR_FIFO=""
HR_LIMIT=200           # a run is killed after this many tenths of a second

_hr_lib() { ( export FELIX_HOME="$HR_ROOT" FELIX_MEMORY="$HR_MEM"
              . "$HR_ROOT/harness/lib/resolve.sh"; . "$HR_ROOT/harness/lib/verify.sh"; "$@" ); }
# The identity of a tree as it stands, taken the way the hook takes it and not
# read back from anything the hook wrote.
_hr_tid()       { _hr_lib felix_tree_id "${1:-$HR_REPO}" "$HR_ROOT"; }
_hr_receipt()   { _hr_lib felix_verify_record "${2:-$HR_REPO}" "$HR_ROOT" "$1" hr-gate "$(_hr_tid "${2:-$HR_REPO}")" "" >/dev/null 2>&1; }
_hr_noreceipt() { rm -f "$(_hr_lib _felix_receipt_path "${1:-$HR_REPO}" "$HR_ROOT")"; }
# The work tree is the committed "base" plus at most one line, so a tree named
# by its line is the same tree whenever it comes back.
_hr_edit()      { printf 'base\n%s\n' "$1" > "${2:-$HR_REPO}/WORK.txt"; }
# The record file of a session, the tree ids it holds, how many lines it has,
# and whether it holds one exact line.
_hr_file()      { printf '%s/held-tree/%s' "$HR_STATE" "$1"; }
_hr_rec()       { cut -f1 "$(_hr_file "$1")" 2>/dev/null; }
_hr_lines()     { awk 'END { print NR + 0 }' "$(_hr_file "$1")" 2>/dev/null || printf '0'; }
_hr_has_line()  { if grep -qxF -- "$2" "$(_hr_file "$1")" 2>/dev/null; then printf yes; else printf no; fi; }
_hr_present()   { if [ -e "$(_hr_file "$1")" ] || [ -L "$(_hr_file "$1")" ]; then printf present; else printf gone; fi; }
# One record line as the contract writes it: tree id, reason, checkout.
_hr_triple()    { printf '%s\t%s\t%s' "$1" "$2" "${3:-$HR_REPO}"; }
# A record laid by hand: the whole file is this one line (_hr_seed) or this line
# is added to what is there (_hr_seed_add).
_hr_seed()      { mkdir -p "$HR_STATE/held-tree" && _hr_triple "$2" "${3:-never checked}" "${4:-$HR_REPO}" > "$(_hr_file "$1")" \
                    && printf '\n' >> "$(_hr_file "$1")"; }
_hr_seed_add()  { mkdir -p "$HR_STATE/held-tree" && { _hr_triple "$2" "${3:-never checked}" "${4:-$HR_REPO}"; printf '\n'; } >> "$(_hr_file "$1")"; }
# What the record file is made of, in one word per fact: the lines, the fields
# in the first line and whether the last byte is a newline.
_hr_shape() {
  local f; f="$(_hr_file "$1")"
  printf '%s:%s:%s' "$(_hr_lines "$1")" "$(awk -F'\t' 'NR == 1 { print NF }' "$f" 2>/dev/null)" \
    "$(if [ -s "$f" ] && [ "$(tail -c 1 "$f" | od -An -tx1 | tr -d ' \n')" = 0a ]; then printf yes; else printf no; fi)"
}
# Rows in verification.log; a log that is absent, or a pipe nobody may read, has none.
_hr_rows()  { [ -f "$HR_LOG" ] || { printf '0'; return 0; }; awk 'END { print NR + 0 }' "$HR_LOG" 2>/dev/null || printf '0'; }
_hr_field() { printf '%s' "$HR_ROW" | cut -f"$1"; }
_hr_pay() {   # session id [, flag [, transcript]] -> a Stop payload
  local t=""
  [ -n "${3:-}" ] && t=",\"transcript_path\":\"$3\""
  printf '{"hook_event_name":"Stop","stop_hook_active":%s,"session_id":"%s"%s}' "${2:-false}" "$1" "$t"
}
_hr_tool() { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash"}]}}\n' >> "$HR_TX"; }
_hr_tree_of() {   # pid -> it and everything below it
  ps -A -o pid= -o ppid= 2>/dev/null | awk -v root="$1" '
    { kids[$2] = kids[$2] " " $1 }
    END { q = root; out = ""
          while (q != "") { n = split(q, a, " "); q = ""
                            for (i = 1; i <= n; i++) if (a[i] != "") { out = out " " a[i]; q = q kids[a[i]] } }
          print out }'
}
# One hook run. Sets HR_OUT (stdout), HR_RC (exit status, or 124 when the run
# had not ended after HR_LIMIT tenths of a second and was killed), HR_NEW (rows
# it added to verification.log) and HR_ROW (the last of them). HR_FIFO, when
# set, is opened read-write after a kill, which lets go of anything left on it.
_hr_run() {   # hook, dir, payload [, NAME=value ...]
  local hook="$1" dir="$2" payload="$3" pid n=0 k n0
  shift 3
  n0="$(_hr_rows)"
  rm -f "$HR_DIR/hook.out" "$HR_DIR/hook.err" "$HR_DIR/hook.rc"
  ( cd "${dir:?}" && printf '%s' "$payload" \
      | env -u FELIX_ALLOW_RED FELIX_HOME="$HR_ROOT" FELIX_MEMORY="$HR_MEM" "$@" "$hook" \
          > "$HR_DIR/hook.out" 2> "$HR_DIR/hook.err"
    echo "$?" > "$HR_DIR/hook.rc" ) &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$n" -lt "$HR_LIMIT" ]; do sleep 0.1; n=$((n + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    for k in $(_hr_tree_of "$pid"); do kill -9 "$k" 2>/dev/null; done
    wait "$pid" 2>/dev/null
    [ -n "${HR_FIFO:-}" ] && [ -p "$HR_FIFO" ] && ( exec 9<>"$HR_FIFO" ) 2>/dev/null
    HR_RC=124
  else
    wait "$pid" 2>/dev/null
    HR_RC="$(cat "$HR_DIR/hook.rc" 2>/dev/null)"; HR_RC="${HR_RC:-none}"
  fi
  HR_OUT="$(cat "$HR_DIR/hook.out" 2>/dev/null)"
  HR_NEW=$(( $(_hr_rows) - n0 ))
  HR_ROW=""
  [ "$HR_NEW" -gt 0 ] && HR_ROW="$(tail -1 "$HR_LOG" 2>/dev/null)"
  return 0
}
_hr_stop()  { _hr_run "$HR_ROOT/harness/hooks/stop" "$HR_WORK" "$(_hr_pay "$@")"; }   # session id [, flag [, transcript]]
# What the last run did, in one word per fact:
#   <block|silent|other>:<exit status>:<rows added>:<verdict of the last row, or ->
# or "hung". A hold is block:0:1:blocked, debt is silent:0:1:debt.
_hr_sum() {
  local kind v
  [ "$HR_RC" = 124 ] && { printf 'hung'; return 0; }
  case "$HR_OUT" in
    '')                      kind=silent ;;
    *'"decision": "block"'*) kind=block ;;
    *)                       kind=other ;;
  esac
  v="-"
  [ "$HR_NEW" -gt 0 ] && v="$(_hr_field 2)"
  printf '%s:%s:%s:%s' "$kind" "$HR_RC" "$HR_NEW" "$v"
}
_hr_end() {   # session id: SessionEnd
  _hr_run "$HR_ROOT/harness/hooks/session-end" "$HR_REPO" \
          "$(printf '{"hook_event_name":"SessionEnd","session_id":"%s","reason":"other"}' "$1")"
}
_hr_prompt() {   # session id, text: UserPromptSubmit
  _hr_run "$HR_ROOT/harness/hooks/user-prompt" "$HR_REPO" \
          "$(printf '{"hook_event_name":"UserPromptSubmit","session_id":"%s","prompt":"%s"}' "$1" "$2")"
}
_hr_night() {   # session id, continuations
  ( export FELIX_HOME="$HR_ROOT" FELIX_MEMORY="$HR_MEM"
    . "$HR_ROOT/harness/lib/resolve.sh"; . "$HR_ROOT/harness/lib/overnight.sh"
    felix_overnight_start "$HR_PROJ" 8 "$2" "$1" "the held-reason block's night" ) >/dev/null 2>&1
}
_hr_night_end() {
  ( export FELIX_HOME="$HR_ROOT" FELIX_MEMORY="$HR_MEM"
    . "$HR_ROOT/harness/lib/resolve.sh"; . "$HR_ROOT/harness/lib/overnight.sh"
    felix_overnight_end "$HR_PROJ" "the held-reason block is over" "$1" ) >/dev/null 2>&1
}
_hr_night_left() { awk -F'\t' 'NR == 1 { print $3 }' "$HR_NIGHTS/$1" 2>/dev/null; }
# The receipt state of the tree as it stands, in the four ways a gate leaves a
# tree unpassed. The tree is left at "one".
_hr_prepare() {   # never | stale | failed | epoch
  rm -f "$HR_PROJ/stack.tsv"
  _hr_noreceipt
  case "$1" in
    stale)  _hr_edit zero; _hr_receipt 0; _hr_edit one ;;
    failed) _hr_edit one;  _hr_receipt 1 ;;
    epoch)  _hr_edit one;  _hr_receipt 0
            printf 'plugin\tsomething-else@x\t-\tlow\talways\n' > "$HR_PROJ/stack.tsv" ;;
    *)      _hr_edit one ;;
  esac
}
# A session in the checkout with a commit, which is held once and then is debt,
# after it was somewhere the hook does not count: the sum of its two stops here
# and the lines its record holds, with the checkout the first of them names.
_hr_contrast() {   # session id
  local a b
  HR_WORK="$HR_REPO"
  _hr_stop "$1"; a="$(_hr_sum)"
  _hr_stop "$1"; b="$(_hr_sum)"
  printf '%s %s:%s:%s' "$a" "$b" "$(_hr_lines "$1")" "$(cut -f3 "$(_hr_file "$1")" 2>/dev/null | head -1)"
}

# ---- A: a hold is the tree id, the reason and the checkout ----
# The record line, for each reason the hook gives for holding.
for _hr_k in never stale failed epoch; do
  case "$_hr_k" in
    never)  _hr_lab="the gate never ran";                               _hr_det="never checked" ;;
    stale)  _hr_lab="the receipt is for a different tree";              _hr_det="stale receipt" ;;
    failed) _hr_lab="the gate failed on this tree";                     _hr_det="failed" ;;
    epoch)  _hr_lab="the gate passed on this tree and the epoch moved"; _hr_det="epoch moved" ;;
  esac
  _hr_prepare "$_hr_k"
  _hr_t="$(_hr_tid)"
  _hr_stop "hr-a-$_hr_k"
  is  "the Stop hook records the tree id, a tab, \"$_hr_det\", a tab and the checkout for a hold when $_hr_lab" \
      "$(cat "$(_hr_file "hr-a-$_hr_k")" 2>/dev/null)" "$(_hr_triple "$_hr_t" "$_hr_det")"
done
rm -f "$HR_PROJ/stack.tsv"
_hr_prepare never
HR_T1="$(_hr_tid)"
_hr_stop hr-a-shape
is  "the Stop hook's record of a hold is one line of three tab-separated fields that ends in a newline" \
    "$(_hr_shape hr-a-shape)" "1:3:yes"
is  "the Stop hook's record line for a hold holds the very reason the blocked row gives" \
    "$(cut -f2 "$(_hr_file hr-a-shape)" 2>/dev/null)" "$(_hr_field 4)"

# Each of the three fields matters on its own. A session whose record differs
# from the stop in one field only is held, and what it is held on is recorded
# beside what was there; the stop after that is debt. The case where all three
# are equal is the one debt.
_hr_edit two; HR_T2="$(_hr_tid)"; _hr_edit one
HR_ELSE="$HR_DIR/elsewhere"
_hr_seed hr-m-all "$HR_T1"
_hr_stop hr-m-all
is  "the Stop hook counts debt, and holds nothing, for a record line with this tree, this reason and this checkout" \
    "$(_hr_sum)" "silent:0:1:debt"
for _hr_c in tree reason checkout; do
  case "$_hr_c" in
    tree)     _hr_seed "hr-m-$_hr_c" "$HR_T2";  _hr_lab="a different tree id" ;;
    reason)   _hr_seed "hr-m-$_hr_c" "$HR_T1" "failed"; _hr_lab="a different reason" ;;
    checkout) _hr_seed "hr-m-$_hr_c" "$HR_T1" "never checked" "$HR_ELSE"; _hr_lab="a different checkout" ;;
  esac
  _hr_stop "hr-m-$_hr_c"
  is  "the Stop hook holds a stop whose record line differs from it only in $_hr_lab, and records the hold on a line of its own" \
      "$(_hr_sum):$(_hr_has_line "hr-m-$_hr_c" "$(_hr_triple "$HR_T1" 'never checked')")" "block:0:1:blocked:yes"
  _hr_stop "hr-m-$_hr_c"
  is  "the Stop hook counts the stop after that hold as debt when the record had differed only in $_hr_lab" \
      "$(_hr_sum)" "silent:0:1:debt"
done
# A line that does not hold all three fields matches nothing.
mkdir -p "$HR_STATE/held-tree"
printf '%s\n' "$HR_T1" > "$(_hr_file hr-m-onlytid)"
_hr_stop hr-m-onlytid
is  "the Stop hook holds a stop whose record line holds only the tree id, and records the hold in full" \
    "$(_hr_sum):$(_hr_has_line hr-m-onlytid "$(_hr_triple "$HR_T1" 'never checked')")" "block:0:1:blocked:yes"
_hr_stop hr-m-onlytid
is  "the Stop hook counts the stop after that hold as debt when the record had held only the tree id" \
    "$(_hr_sum)" "silent:0:1:debt"
printf '%s\t%s\n' "$HR_T1" "never checked" > "$(_hr_file hr-m-twof)"
_hr_stop hr-m-twof
is  "the Stop hook holds a stop whose record line holds the tree id and the reason but no checkout, and records the hold in full" \
    "$(_hr_sum):$(_hr_has_line hr-m-twof "$(_hr_triple "$HR_T1" 'never checked')")" "block:0:1:blocked:yes"
# The line that matches may be any line of the record.
_hr_seed hr-m-multi "$HR_T2"
_hr_seed_add hr-m-multi "$HR_T1" "failed"
_hr_seed_add hr-m-multi "$HR_T1" "never checked" "$HR_ELSE"
_hr_seed_add hr-m-multi "$HR_T1"
_hr_seed_add hr-m-multi "$HR_T2" "failed"
_hr_stop hr-m-multi
is  "the Stop hook counts debt when the matching line is one of several in the record, with others on both sides of it" \
    "$(_hr_sum)" "silent:0:1:debt"

# The checkout is a field of its own in practice too: a second checkout that
# stands on the same commit with the same edit has the tree id of the first.
_hr_edit one "$HR_REPO2"
_hr_noreceipt "$HR_REPO2"
is  "the Stop hook's two checkouts stand on one commit (control)" \
    "$(git -C "$HR_REPO" rev-parse HEAD):x" "$(git -C "$HR_REPO2" rev-parse HEAD):x"
is  "the Stop hook's two checkouts have one tree id (control)" "$(_hr_tid "$HR_REPO2")" "$HR_T1"
_hr_stop hr-x
is  "the Stop hook holds the session in the first of two checkouts that share a tree id, and records the hold" \
    "$(_hr_sum):$(_hr_field 3):$(_hr_has_line hr-x "$(_hr_triple "$HR_T1" 'never checked' "$HR_REPO")")" "block:0:1:blocked:$HR_T1:yes"
HR_WORK="$HR_REPO2"
_hr_stop hr-x
is  "the Stop hook holds the same session again in a second checkout with the same tree id and the same reason, and records that hold" \
    "$(_hr_sum):$(_hr_field 3):$(_hr_has_line hr-x "$(_hr_triple "$HR_T1" 'never checked' "$HR_REPO2")")" "block:0:1:blocked:$HR_T1:yes"
is  "the Stop hook records both checkouts, each on a line of its own" \
    "$(cat "$(_hr_file hr-x)" 2>/dev/null)" "$(_hr_triple "$HR_T1" 'never checked' "$HR_REPO")
$(_hr_triple "$HR_T1" 'never checked' "$HR_REPO2")"
_hr_stop hr-x
is  "the Stop hook counts debt for the second checkout once it was held there" "$(_hr_sum)" "silent:0:1:debt"
HR_WORK="$HR_REPO"
_hr_stop hr-x
is  "the Stop hook counts debt for the first checkout once it was held there" "$(_hr_sum)" "silent:0:1:debt"

# The checkout is the top level of the repository the hook judged, not the
# directory the session happened to stand in.
HR_WORK="$HR_REPO/sub/deep"
_hr_stop hr-sub
is  "the Stop hook holds a stop made from a directory below the top of the checkout, and records the top level of the checkout, not that directory" \
    "$(_hr_sum):$(cut -f3 "$(_hr_file hr-sub)" 2>/dev/null)" "block:0:1:blocked:$HR_REPO"
HR_WORK="$HR_REPO"
_hr_stop hr-sub
is  "the Stop hook counts a stop from the top of the checkout as debt once a stop from a directory below it was held" \
    "$(_hr_sum)" "silent:0:1:debt"

# A path with spaces in it: the record names the checkout whole.
_hr_edit one "$HR_SP"
HR_WORK="$HR_SP"
_hr_stop hr-sp; _hr_a="$(_hr_sum)"
_hr_stop hr-sp; _hr_b="$(_hr_sum)"
HR_WORK="$HR_REPO"
is  "the Stop hook holds a checkout whose path holds spaces once and then counts debt, and records the path whole" \
    "$_hr_a $_hr_b:$(cut -f3 "$(_hr_file hr-sp)" 2>/dev/null)" "block:0:1:blocked silent:0:1:debt:$HR_SP"

# ---- B: the same tree with a new reason is held again, once ----
for _hr_b in never-failed stale-failed failed-epoch; do
  case "$_hr_b" in
    never-failed) _hr_from="never checked"; _hr_to="failed";      _hr_prepare never ;;
    stale-failed) _hr_from="stale receipt";  _hr_to="failed";      _hr_prepare stale ;;
    failed-epoch) _hr_from="failed";         _hr_to="epoch moved"; _hr_prepare failed ;;
  esac
  _hr_t="$(_hr_tid)"
  _hr_stop "hr-b-$_hr_b"
  is  "the Stop hook holds the first stop on a tree as \"$_hr_from\" (control)" "$(_hr_sum):$(_hr_field 3):$(_hr_field 4)" "block:0:1:blocked:$_hr_t:$_hr_from"
  case "$_hr_b" in
    failed-epoch) _hr_receipt 0; printf 'plugin\tsomething-else@x\t-\tlow\talways\n' > "$HR_PROJ/stack.tsv" ;;
    *)            _hr_receipt 1 ;;
  esac
  is  "the Stop hook's fixture for \"$_hr_from\" then \"$_hr_to\" leaves the tree as it was (control)" "$(_hr_tid)" "$_hr_t"
  _hr_stop "hr-b-$_hr_b"
  is  "the Stop hook holds the same session on the same tree again when the reason has become \"$_hr_to\" after \"$_hr_from\", and records that hold" \
      "$(_hr_sum):$(_hr_field 3):$(_hr_field 4):$(_hr_has_line "hr-b-$_hr_b" "$(_hr_triple "$_hr_t" "$_hr_to")")" "block:0:1:blocked:$_hr_t:$_hr_to:yes"
  _hr_stop "hr-b-$_hr_b"
  is  "the Stop hook holds that tree only once for \"$_hr_to\" after \"$_hr_from\": the next stop is debt" "$(_hr_sum)" "silent:0:1:debt"
  is  "the Stop hook records both holds, \"$_hr_from\" and then \"$_hr_to\", on lines of their own" \
      "$(cat "$(_hr_file "hr-b-$_hr_b")" 2>/dev/null)" "$(_hr_triple "$_hr_t" "$_hr_from")
$(_hr_triple "$_hr_t" "$_hr_to")"
  rm -f "$HR_PROJ/stack.tsv"
done
# A reason the session was already held on comes back: debt, not a third hold.
_hr_prepare never
_hr_stop hr-b-back
_hr_receipt 1
_hr_stop hr-b-back
_hr_noreceipt
_hr_stop hr-b-back
is  "the Stop hook counts debt when the reason returns to one the session was already held on, on the same tree" \
    "$(_hr_sum)" "silent:0:1:debt"

# ---- C: a session that holds a night is never let through as debt ----
_hr_prepare never
HR_T1="$(_hr_tid)"
_hr_night hr-c-n1 12
is  "the Stop hook's second night fixture starts with twelve continuations (control)" "$(_hr_night_left hr-c-n1)" "12"
_hr_stop hr-c-n1
is  "the Stop hook holds a session that holds a night at its first unflagged stop (control)" "$(_hr_sum)" "block:0:1:blocked"
_hr_stop hr-c-n1
is  "the Stop hook holds a session that holds a night at its second unflagged stop too, and does not count debt (control)" \
    "$(_hr_sum)" "block:0:1:blocked"
_hr_tool
_hr_run "$HR_ROOT/harness/hooks/stop" "$HR_WORK" "$(_hr_pay hr-c-n1 true "$HR_TX")"
is  "the Stop hook holds a night's flagged stop and charges it to the night (control)" \
    "$(_hr_sum):$(_hr_night_left hr-c-n1)" "block:0:1:blocked:11"
is  "the Stop hook writes no record for a session while it holds a night (control)" "$(_hr_present hr-c-n1)" "gone"
# A record laid by hand, naming the tree, the reason and the checkout.
_hr_seed hr-c-n1 "$HR_T1"
_hr_stop hr-c-n1
is  "the Stop hook holds a night's unflagged stop though the record holds this tree, this reason and this checkout (control)" \
    "$(_hr_sum)" "block:0:1:blocked"
_hr_tool
_hr_run "$HR_ROOT/harness/hooks/stop" "$HR_WORK" "$(_hr_pay hr-c-n1 true "$HR_TX")"
is  "the Stop hook holds a night's flagged stop though the record holds this tree, this reason and this checkout, and charges it (control)" \
    "$(_hr_sum):$(_hr_night_left hr-c-n1)" "block:0:1:blocked:10"
is  "the Stop hook leaves a record it did not write as it was while the session holds a night (control)" \
    "$(cat "$(_hr_file hr-c-n1)" 2>/dev/null)" "$(_hr_triple "$HR_T1" 'never checked')"
_hr_night_end hr-c-n1
# What the night wrote: nothing. Held through a night, then free of it, the
# session is held once and then is debt, which a record the night wrote would
# have made debt from the first stop on.
_hr_night hr-c-n2 12
_hr_stop hr-c-n2; _hr_a="$(_hr_sum)"
_hr_stop hr-c-n2; _hr_b="$(_hr_sum)"
_hr_night_end hr-c-n2
_hr_stop hr-c-n2; _hr_c="$(_hr_sum)"
_hr_stop hr-c-n2; _hr_d="$(_hr_sum)"
is  "the Stop hook holds a session at two stops of its night, then once and only once after the night: the night wrote no record" \
    "$_hr_a $_hr_b $_hr_c $_hr_d" "block:0:1:blocked block:0:1:blocked block:0:1:blocked silent:0:1:debt"
# A record that was there before the night began is no reason to let the night through.
_hr_stop hr-c-n3; _hr_a="$(_hr_sum)"
_hr_stop hr-c-n3; _hr_b="$(_hr_sum)"
is  "the Stop hook holds a session once and then counts debt, before the session is given a night" \
    "$_hr_a $_hr_b" "block:0:1:blocked silent:0:1:debt"
_hr_night hr-c-n3 12
_hr_stop hr-c-n3
is  "the Stop hook holds the unflagged stop of a session whose night began after its record was made (control)" "$(_hr_sum)" "block:0:1:blocked"
_hr_tool
_hr_run "$HR_ROOT/harness/hooks/stop" "$HR_WORK" "$(_hr_pay hr-c-n3 true "$HR_TX")"
is  "the Stop hook holds the flagged stop of a session whose night began after its record was made (control)" "$(_hr_sum)" "block:0:1:blocked"
_hr_night_end hr-c-n3

# ---- D: where the tree id cannot tell work apart, every stop is held ----
# A checkout whose HEAD is unborn.
_hr_prepare never
is  "the Stop hook's unborn checkout has no commit (control)" \
    "$(git -C "$HR_UNB" rev-parse --verify -q HEAD >/dev/null 2>&1 && printf has || printf none)" "none"
HR_WORK="$HR_UNB"
_hr_stop hr-d-u; _hr_a="$(_hr_sum)"; _hr_t="$(_hr_field 3)"
_hr_stop hr-d-u; _hr_b="$(_hr_sum)"
_hr_stop hr-d-u; _hr_c="$(_hr_sum)"
is  "the Stop hook holds a checkout with no commit at every unflagged stop, three in a row (control)" \
    "$_hr_a $_hr_b $_hr_c" "block:0:1:blocked block:0:1:blocked block:0:1:blocked"
case "$_hr_t" in
  coarse:*) bad "the Stop hook's unborn checkout has an ordinary tree id (control)" "[$_hr_t]" ;;
  ?*)       ok  "the Stop hook's unborn checkout has an ordinary tree id (control)" ;;
  *)        bad "the Stop hook's unborn checkout has an ordinary tree id (control)" "the blocked row names no tree" ;;
esac
is  "the Stop hook records nothing for a checkout with no commit (control)" "$(_hr_present hr-d-u)" "gone"
is  "the Stop hook records nothing for a checkout with no commit, though the same session is held and then counted as debt in a checkout with a commit" \
    "$(_hr_contrast hr-d-u)" "block:0:1:blocked silent:0:1:debt:1:$HR_REPO"

# A tree with more untracked files than a tree id counts. At the limit, 500, it
# is an ordinary tree id.
_hr_noreceipt "$HR_BIG"
HR_WORK="$HR_BIG"
HR_TB="$(_hr_tid "$HR_BIG")"
case "$HR_TB" in
  coarse:*) bad "the Stop hook's checkout with exactly 500 untracked files has an ordinary tree id (control)" "[$HR_TB]" ;;
  *)        ok  "the Stop hook's checkout with exactly 500 untracked files has an ordinary tree id (control)" ;;
esac
_hr_stop hr-d-500; _hr_a="$(_hr_sum)"
_hr_stop hr-d-500; _hr_b="$(_hr_sum)"
is  "the Stop hook holds a checkout with 500 untracked files once and then counts debt, as it does any ordinary tree" \
    "$_hr_a $_hr_b" "block:0:1:blocked silent:0:1:debt"
: > "$HR_BIG/bulk/f501"
HR_TB="$(_hr_tid "$HR_BIG")"
case "$HR_TB" in
  coarse:*) ok  "the Stop hook's checkout with 501 untracked files has a coarse tree id (control)" ;;
  *)        bad "the Stop hook's checkout with 501 untracked files has a coarse tree id (control)" "[$HR_TB]" ;;
esac
HR_WORK="$HR_BIG"
_hr_stop hr-d-c; _hr_a="$(_hr_sum)"; _hr_t="$(_hr_field 3)"
case "$_hr_t" in
  coarse:*) ok  "the Stop hook's blocked row for the coarse tree names a tree id that starts with coarse: (control)" ;;
  *)        bad "the Stop hook's blocked row for the coarse tree names a tree id that starts with coarse: (control)" "[$_hr_t]" ;;
esac
_hr_stop hr-d-c; _hr_b="$(_hr_sum)"
_hr_stop hr-d-c; _hr_c="$(_hr_sum)"
is  "the Stop hook holds a coarse tree at every unflagged stop, three in a row (control)" \
    "$_hr_a $_hr_b $_hr_c" "block:0:1:blocked block:0:1:blocked block:0:1:blocked"
is  "the Stop hook records nothing for a coarse tree (control)" "$(_hr_present hr-d-c)" "gone"
is  "the Stop hook records nothing for a coarse tree, though the same session is held and then counted as debt in an ordinary tree" \
    "$(_hr_contrast hr-d-c)" "block:0:1:blocked silent:0:1:debt:1:$HR_REPO"
HR_WORK="$HR_REPO"

# ---- E: the record is written only after the block JSON has been printed ----
# A hook stopped while it writes its rows, which is before it prints. The log
# is made a pipe nobody reads, so the write blocks until the runner kills the
# run, and the runner lets go of the pipe the way the first round's runner does.
_hr_prepare never
HR_T1="$(_hr_tid)"
rm -f "$HR_LOG"; mkfifo "$HR_LOG"
HR_FIFO="$HR_LOG"; HR_LIMIT=60
_hr_stop hr-e-v
HR_FIFO=""; HR_LIMIT=200
_hr_a="$HR_RC:[$HR_OUT]"
rm -f "$HR_LOG"
is  "the Stop hook's fixture stops a hold in the middle of writing its verification row, before the JSON is printed (control)" "$_hr_a" "124:[]"
is  "the Stop hook leaves no record behind when it was stopped while writing its verification row (control)" "$(_hr_present hr-e-v)" "gone"
_hr_stop hr-e-v; _hr_a="$(_hr_sum)"
_hr_stop hr-e-v; _hr_b="$(_hr_sum)"
is  "the Stop hook holds the stop after one that was stopped while writing its verification row, and only then counts debt" \
    "$_hr_a $_hr_b" "block:0:1:blocked silent:0:1:debt"
# The same with the says row, which is written after the verification row: the
# row is on the log, the JSON is not printed, and the hold is not on record.
rm -f "$HR_SAYS"; mkfifo "$HR_SAYS"
HR_FIFO="$HR_SAYS"; HR_LIMIT=60
_hr_stop hr-e-s
HR_FIFO=""; HR_LIMIT=200
_hr_a="$HR_RC:[$HR_OUT]:$HR_NEW:$(_hr_field 2)"
rm -f "$HR_SAYS"
is  "the Stop hook's fixture stops a hold after its verification row and in the middle of its says row, before the JSON is printed (control)" \
    "$_hr_a" "124:[]:1:blocked"
is  "the Stop hook leaves no record behind when it was stopped while writing its says row (control)" "$(_hr_present hr-e-s)" "gone"
_hr_stop hr-e-s; _hr_a="$(_hr_sum)"
_hr_stop hr-e-s; _hr_b="$(_hr_sum)"
is  "the Stop hook holds the stop after one that was stopped while writing its says row, and only then counts debt" \
    "$_hr_a $_hr_b" "block:0:1:blocked silent:0:1:debt"
is  "the Stop hook's record, once a hold was printed, holds the tree it was held on" "$(_hr_rec hr-e-s)" "$HR_T1"

# ---- F: a person's prompt clears the record, a runtime message does not ----
_hr_prepare never
_hr_seed hr-f-other "$HR_T1"
_hr_stop hr-f-1; _hr_a="$(_hr_sum)"
_hr_stop hr-f-1; _hr_b="$(_hr_sum)"
is  "the Stop hook holds a session once and then counts debt, before any prompt is typed into it" \
    "$_hr_a $_hr_b" "block:0:1:blocked silent:0:1:debt"
# A runtime message is not a person: it lands in the session on the same
# channel as a prompt and must leave the record alone.
_hr_prompt hr-f-1 '<task-notification>\n<task-id>b1</task-id>\n<status>completed</status>\n</task-notification>'
_hr_stop hr-f-1
is  "the Stop hook still counts debt after a task notification arrives as a prompt: it does not clear the record" \
    "$(_hr_sum):$(_hr_present hr-f-1)" "silent:0:1:debt:present"
_hr_prompt hr-f-1 'Stop hook feedback:\nThe gate has never run in this checkout.'
_hr_stop hr-f-1
is  "the Stop hook still counts debt after its own feedback arrives as a prompt: it does not clear the record" \
    "$(_hr_sum):$(_hr_present hr-f-1)" "silent:0:1:debt:present"
_hr_prompt hr-f-1 '<system-reminder>\nThe task tools have not been used recently.\n</system-reminder>'
_hr_stop hr-f-1
is  "the Stop hook still counts debt after a system reminder arrives as a prompt: it does not clear the record" \
    "$(_hr_sum):$(_hr_present hr-f-1)" "silent:0:1:debt:present"
# A person's prompt.
_hr_a="$(_hr_present hr-f-1)"
_hr_prompt hr-f-1 'please carry on with the migration of the schema'
is  "the Stop hook's record of a session is there before a person types into it and gone after, and another session's record is as it was" \
    "$_hr_a:$(_hr_present hr-f-1):$(_hr_rec hr-f-other)" "present:gone:$HR_T1"
_hr_stop hr-f-1; _hr_a="$(_hr_sum)"
_hr_stop hr-f-1; _hr_b="$(_hr_sum)"
is  "the Stop hook holds the session once again at its next stop after a person's prompt, and then counts debt" \
    "$_hr_a $_hr_b" "block:0:1:blocked silent:0:1:debt"
# The whole record goes, not the last tree in it.
_hr_edit two
_hr_stop hr-f-2; _hr_a="$(_hr_sum)"
_hr_edit one
_hr_stop hr-f-2; _hr_b="$(_hr_sum)"
_hr_edit two
_hr_stop hr-f-2; _hr_c="$(_hr_sum)"
_hr_prompt hr-f-2 'now tidy up the commit message'
_hr_edit one
_hr_stop hr-f-2; _hr_d="$(_hr_sum)"
_hr_edit two
_hr_stop hr-f-2; _hr_e="$(_hr_sum)"
is  "the Stop hook holds a session again on every tree it was held on once a person has typed into it, not on the last only" \
    "$_hr_a $_hr_b $_hr_c $_hr_d $_hr_e" "block:0:1:blocked block:0:1:blocked silent:0:1:debt block:0:1:blocked block:0:1:blocked"
_hr_edit one
# The prompt of one session is not another's.
_hr_stop hr-f-3
_hr_stop hr-f-4
_hr_prompt hr-f-3 'a question typed into the third session only'
is  "the Stop hook leaves another session's record as it was when a person types into a session" \
    "$(_hr_present hr-f-3):$(_hr_rec hr-f-4)" "gone:$HR_T1"
# No session id, or one that cannot name a file: nothing is removed. Records
# laid by hand, so this holds whatever the hook does or does not write.
_hr_seed hr-f-laid "$HR_T1"
printf 'keep\n' > "$HR_STATE/hr-keep"
_hr_run "$HR_ROOT/harness/hooks/user-prompt" "$HR_REPO" '{"hook_event_name":"UserPromptSubmit","prompt":"a prompt that names no session"}'
_hr_prompt '../hr-keep' 'a prompt whose session id names a file beside the records'
_hr_prompt '..' 'a prompt whose session id names the parent directory'
is  "the Stop hook leaves every record and every file beside the records as it was for a prompt with no session id or an id that is a path (control)" \
    "$(_hr_rec hr-f-other):$(_hr_rec hr-f-laid):$(cat "$HR_STATE/hr-keep" 2>/dev/null)" "$HR_T1:$HR_T1:keep"
rm -f "$HR_STATE/hr-keep"

# ---- G: a link at the record is neither read nor written through ----
_hr_prepare never
HR_TARGET="$HR_DIR/link-target"
mkdir -p "$HR_STATE/held-tree"
_hr_triple "$HR_T1" 'never checked' > "$HR_TARGET"; printf '\n' >> "$HR_TARGET"
HR_SUM0="$(cksum < "$HR_TARGET")"
ln -s "$HR_TARGET" "$(_hr_file hr-g-link)"
_hr_stop hr-g-link; _hr_a="$(_hr_sum)"
_hr_seed hr-g-reg "$HR_T1"
_hr_stop hr-g-reg; _hr_b="$(_hr_sum)"
is  "the Stop hook holds a session whose record is a link to a file holding this very line, where the same line in a plain file is debt" \
    "$_hr_a $_hr_b" "block:0:1:blocked silent:0:1:debt"
is  "the Stop hook leaves the file a record link points to byte for byte as it was (control)" "$(cksum < "$HR_TARGET")" "$HR_SUM0"
rm -f "$(_hr_file hr-g-link)" "$HR_TARGET"
ln -s "$HR_TARGET" "$(_hr_file hr-g-dangle)"
_hr_stop hr-g-dangle
is  "the Stop hook holds a session whose record is a link to nothing (control)" "$(_hr_sum)" "block:0:1:blocked"
[ ! -e "$HR_TARGET" ] \
  && ok  "the Stop hook does not create the file a dangling record link points to (control)" \
  || bad "the Stop hook does not create the file a dangling record link points to (control)" "$(cat "$HR_TARGET" 2>/dev/null)"
rm -f "$(_hr_file hr-g-dangle)"
# SessionEnd takes the link itself and nothing it points at.
_hr_triple "$HR_T1" 'never checked' > "$HR_TARGET"; printf '\n' >> "$HR_TARGET"
HR_SUM0="$(cksum < "$HR_TARGET")"
ln -s "$HR_TARGET" "$(_hr_file hr-g-end)"
_hr_end hr-g-end
is  "the Stop hook's SessionEnd removes a link at the session's record and leaves the file it points to as it was" \
    "$(_hr_present hr-g-end):$(cksum < "$HR_TARGET" 2>/dev/null)" "gone:$HR_SUM0"
rm -f "$HR_TARGET"
ln -s "$HR_TARGET" "$(_hr_file hr-g-end2)"
_hr_end hr-g-end2
is  "the Stop hook's SessionEnd removes a link at the session's record that points to nothing" "$(_hr_present hr-g-end2)" "gone"
rm -f "$(_hr_file hr-g-end2)"

# ---- H: the debt row names the session ----
_hr_edit one
HR_LONG='a1b2c3d4-e5f6-4789-9abc-def012345678'
_hr_stop "$HR_LONG"
_hr_stop "$HR_LONG"
is  "the Stop hook counts the second stop of a session whose id is longer than eight characters as debt" "$(_hr_sum)" "silent:0:1:debt"
has "the Stop hook's debt row names the session as (session a1b2c3d4), the first eight characters of its id" \
    "$(_hr_field 4)" "(session a1b2c3d4)"
has "the Stop hook's debt row still says the tree was held once already" "$(_hr_field 4)" "held once on this tree already"
case "$(_hr_field 2):$(_hr_field 4)" in
  debt:*"a1b2c3d4-"*|debt:*"e5f6"*) bad "the Stop hook's debt row gives only the first eight characters of the session id, never more" "[$(_hr_field 4)]" ;;
  debt:*)                           ok  "the Stop hook's debt row gives only the first eight characters of the session id, never more" ;;
  *)                                bad "the Stop hook's debt row gives only the first eight characters of the session id, never more" "the last row is [$HR_ROW], not a debt row" ;;
esac
_hr_stop abcd1234
_hr_stop abcd1234
has "the Stop hook's debt row names a session id of exactly eight characters in full" "$(_hr_field 4)" "(session abcd1234)"
_hr_stop hr-h-chain
_hr_stop hr-h-chain true
_hr_stop hr-h-chain true
is  "the Stop hook counts a flagged stop inside another hook's chain as debt for a session held once already" "$(_hr_sum)" "silent:0:1:debt"
has "the Stop hook's debt row for a stop inside another hook's chain names the session too" "$(_hr_field 4)" "(session hr-h-cha)"

# ---- I: the monitor page shows a debt row with the warning class ----
# The page's own script is run, with a stand-in for the document, and the log
# panel it draws is read back: the class each verification row got.
if command -v node >/dev/null 2>&1; then
  cat > "$HR_DIR/monitor-class.js" <<'HR_MONITOR_JS'
'use strict';
const fs = require('fs');
const vm = require('vm');
const html = fs.readFileSync(process.argv[2], 'utf8');
const verdicts = process.argv.slice(3);
const m = html.match(/<script>([\s\S]*?)<\/script>/);
if (!m) { console.log('ERR no script element'); process.exit(0); }
const marker = '/*{{FELIX_DATA}}*/';
if (m[1].indexOf(marker) < 0) { console.log('ERR no data marker'); process.exit(0); }
const rows = verdicts.map((v, i) => ({ t: '2026-10-11T10:0' + i + ':00Z', verdict: v, reason: 'a row for ' + v }));
const data = { generated: '', projects: [{ name: 'p', says: [], routes: [], routeLog: [], mistakes: [], stack: [], lessons: 0, verifyLog: rows }] };
const src = m[1].split(marker).join(JSON.stringify(data));
const any = new Proxy(function () {}, {
  get: (t, k) => (k === 'valueOf' ? () => 0 : k === 'toString' ? () => '' : typeof k === 'symbol' ? (k === Symbol.toPrimitive ? () => 0 : undefined) : any),
  apply: () => any, construct: () => any, set: () => true,
});
const els = {};
function mk(tag) {
  const t = { tag, className: '', textContent: '', children: [], firstChild: null, dataset: {}, style: {}, value: '', scrollTop: 0 };
  t.appendChild = c => { t.children.push(c); t.firstChild = t.children[0] || null; return c; };
  t.removeChild = c => { const i = t.children.indexOf(c); if (i >= 0) t.children.splice(i, 1); t.firstChild = t.children[0] || null; return c; };
  t.setAttribute = () => {}; t.addEventListener = () => {};
  return new Proxy(t, { get: (o, k) => (k in o ? o[k] : any), set: (o, k, v) => { o[k] = v; return true; } });
}
const doc = { createElement: t => mk(t), getElementById: id => (els[id] = els[id] || mk('#' + id)), addEventListener() {} };
const ctx = vm.createContext({
  document: new Proxy(doc, { get: (o, k) => (k in o ? o[k] : any) }),
  window: any, location: any, localStorage: any, sessionStorage: any, navigator: any,
  setInterval: () => 0, setTimeout: () => 0, clearTimeout() {}, clearInterval() {}, requestAnimationFrame: () => 0,
  console: { log() {}, error() {}, warn() {} },
});
/* The page's start-up draws on a canvas and reads a clock; a stand-in that
   lacks something may stop it after every function and constant it defines
   is in place, which is all the log panel needs. */
try { vm.runInContext(src, ctx, { timeout: 5000 }); } catch (e) { /* see above */ }
try { vm.runInContext('renderLog()', ctx, { timeout: 5000 }); } catch (e) { console.log('ERR renderLog: ' + e.message); process.exit(0); }
const box = els['log'];
if (!box) { console.log('ERR the page has no log panel'); process.exit(0); }
for (const c of box.children) {
  if (/^gate /.test(c.textContent)) console.log(c.textContent.split(' ')[1] + '\t' + c.className);
}
HR_MONITOR_JS
  HR_CLS="$(node "$HR_DIR/monitor-class.js" "$REAL_HARNESS/templates/monitor.html" allowed blocked override debt 2>&1)"
  _hr_cls() { printf '%s\n' "$HR_CLS" | awk -F'\t' -v v="$1" '$1 == v { print $2 }'; }
  # Whether a row's class list holds one class, a class being a whole word of it.
  _hr_tok() { case " $(_hr_cls "$1") " in *" $2 "*) printf yes ;; *) printf no ;; esac; }
  is  "the monitor page gives a passed gate its own class, and the page's log panel lists all four rows (control)" \
      "$(_hr_cls allowed)|$(_hr_cls blocked)|$(_hr_cls override)" "m ok|m bad|m warn"
  is  "the monitor page shows a debt verification row with the warning class" "$(_hr_tok debt warn)" "yes"
  is  "the monitor page does not show a debt verification row with the class a passed gate has" "$(_hr_tok debt ok)" "no"
  is  "the monitor page does not show a debt verification row with the class a blocked gate has (control)" "$(_hr_tok debt bad)" "no"
else
  skip "the monitor page shows a debt verification row with the warning class" "node is not on PATH"
  skip "the monitor page does not show a debt verification row with the class a passed gate has" "node is not on PATH"
  skip "the monitor page does not show a debt verification row with the class a blocked gate has (control)" "node is not on PATH"
fi

# ---- the restore ----
chmod -R u+rwX "$HR_DIR" 2>/dev/null
rm -f "$HR_LOG" "$HR_SAYS" "$HR_DIR/hook.out" "$HR_DIR/hook.err" "$HR_DIR/hook.rc"
for _hr_v in $(compgen -v | grep -E '^(HR_[A-Za-z0-9_]*|_hr_[A-Za-z0-9_]*)$'); do unset "$_hr_v"; done
for _hr_f in $(compgen -A function | grep -E '^_hr_'); do unset -f "$_hr_f"; done
unset _hr_v _hr_f
# <<< held-reason
