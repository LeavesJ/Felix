printf '\nthe unattended repair leaves the model no credential to copy\n'
_attempt_build
# Both checkouts left a credential on the runner for the model step to read.
# actions/checkout persists what it fetched with unless told otherwise: the
# job's token as an http.extraheader in repo/.git/config, and the deploy key as
# a file under $RUNNER_TEMP that felix/.git/config's core.sshCommand names by
# path. The model step runs `claude -p` with Read and Edit allowed, and a
# tool-name allow rule matches every path. Measured on the pinned 2.1.37
# (2026-09-23, the real binary against a scripted Messages API): Read returned
# all three files, Edit put their contents in a tracked file, and
# bin/secret-scan passed the diff, since a base64 header and a ghs_ token are
# shapes it does not know; the push step then commits every tracked change.
# Without Read in --allowedTools the two paths outside the working directory
# were refused, so the allow rule is what opens them, and the model needs it.
# The fix is upstream of the model: neither checkout persists, so the key file
# is gone before the scope step runs, and the push step hands git the token
# itself, from its own environment, through a credential helper, so it is in
# no file and no argument.
UC="$TMP/uncred"; mkdir -p "$UC/repo" "$UC/bin" "$UC/felix/engine/harness"
# Every checkout, enumerated. A rule read off the two there are stops holding
# the day a third is added.
_ucblocks="$(awk '/^      - uses: actions\/checkout@/ { if (n) print (p ? "dropped" : "kept"); n = 1; p = 0; next }
                  n && /^      - / { print (p ? "dropped" : "kept"); n = 0; next }
                  n && /persist-credentials: false/ { p = 1 }
                  END { if (n) print (p ? "dropped" : "kept") }' "$REAL_HARNESS/templates/unattended.yml")"
is  "every checkout in the unattended template drops its credential once the fetch is done" \
    "$(printf '%s\n' "$_ucblocks" | grep -c kept) of $(printf '%s\n' "$_ucblocks" | grep -c .) keep one" "0 of 2 keep one"
# The token may reach the model step neither as environment nor as text.
_ucstep="$(awk '/- name: Attempt a repair/ { f = 1; next } f && /^      - / { exit } f' "$REAL_HARNESS/templates/unattended.yml")"
case "$_ucstep" in
  *GITHUB_TOKEN*|*GH_TOKEN*|*github.token*|*secrets.GITHUB*)
     bad "and the model step is handed no token, in its environment or its text" \
         "$(printf '%s\n' "$_ucstep" | grep -n 'TOKEN\|github\.token\|secrets\.GITHUB')" ;;
  *) ok  "and the model step is handed no token, in its environment or its text" ;;
esac
# The rules the model runs under, read off the step as shipped. What they mean
# was measured on the binary, which this suite has neither of (no network, no
# model): a bare tool name matches every path; `./**` as an allow stops at the
# working directory, so -p refuses the rest as ungranted; `.git/**` as a deny
# matches under the working directory and nowhere else, which is why the deny
# alone left ../felix/.git/config editable and core.hooksPath landed in it.
# The allow list is held exactly, since any widening is the thing guarded; the
# deny lists are joined, so another rule beside these two is not a failure.
_ucallow="$(printf '%s\n' "$_ucstep" | sed -n 's/.*--allowedTools "\([^"]*\)".*/\1/p' | tr '\n' ',')"
_ucdeny="$(printf '%s\n' "$_ucstep" | sed -n 's/.*--disallowedTools "\([^"]*\)".*/\1/p' | tr '\n' ',')"
is  "the model's tools are allowed inside the checkout and nowhere else" "$_ucallow" "Read(./**),Edit(./**),"
has "and reading the checkout's .git is denied" ",$_ucdeny" ",Read(.git/**),"
has "and editing it is denied"                   ",$_ucdeny" ",Edit(.git/**),"
# The push step, taken out of the shipped template as it stands and run under
# bash -e with the gate green and a git that records each call. On push the
# stub runs the credential helper the call configured exactly as git would,
# `sh -c 'HELPER "$@"' -- get`, so the helper is exercised and not just named.
awk '/- name: Verify and push/ { f = 1 } f && /^        run: \|/ { r = 1; next }
     r && /^      [^ ]/ { exit } r { sub(/^          /, ""); print }' \
  "$REAL_HARNESS/templates/unattended.yml" > "$UC/step.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$UC/felix/engine/harness/felix"
cat > "$UC/bin/git" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$UC_LOG"
case "$1 $2 $3" in "diff --quiet "*) exit 1 ;; esac
# What the verify step asks before it pushes: the commit it starts from, and
# what changed, one file, the one the brief named. Its workflow-file check
# asks `diff --name-only -- .github/workflows`, which names nothing here.
case " $* " in
  *" rev-parse HEAD "*) echo 0123456789abcdef0123456789abcdef01234567; exit 0 ;;
  *" diff --name-only --no-renames HEAD "*) echo src/a.txt; exit 0 ;;
esac
helper=""
while [ $# -gt 0 ]; do
  case "$1" in
    -c) case "$2" in credential.helper=!*) helper="${2#credential.helper=!}" ;; esac; shift 2 ;;
    push) [ -n "$helper" ] && sh -c "$helper \"\$@\"" -- get >> "${UC_LOG%.log}.cred" </dev/null
          # Only the push the step is meant to make succeeds, so "a green
          # gate pushes" can fail on the push and not just on the shell.
          [ "$*" = "push origin HEAD:$BRANCH" ] && exit 0; echo "unexpected push: $*" >&2; exit 7 ;;
    *) shift ;;
  esac
done
exit 0
STUB
chmod +x "$UC/felix/engine/harness/felix" "$UC/bin/git"
# The step's `named="$(mktemp)"` is never removed, and on macOS a template-less mktemp ignores
# TMPDIR: the step runs with a mktemp first on its PATH that gives it the template
# "$TMPDIR/tmp.XXXXXXXXXX" (TMPDIR a directory of this part's own) and logs each path it made.
mkdir -p "$UC/tmpd"; _ucmkreal="$(command -v mktemp)"
cat > "$UC/bin/mktemp" <<'UCMK'
#!/bin/sh
# mktemp for R41: the host's ($UC_MKREAL), logging each path it made to $UC_MKLOG. With no template argument (only options) it passes the same options and the template "$TMPDIR/tmp.XXXXXXXXXX".
t=0
for a in "$@"; do case "$a" in -*) ;; *) t=1 ;; esac; done
if [ "$t" = 0 ] && [ -n "${TMPDIR:-}" ]; then
  set -- "$@" "${TMPDIR%/}/tmp.XXXXXXXXXX"
fi
out="$("$UC_MKREAL" "$@")" || exit $?
printf '%s\n' "$out" >> "$UC_MKLOG"
printf '%s\n' "$out"
UCMK
chmod +x "$UC/bin/mktemp"; : > "$UC/mktemp.log"
# A placeholder by secret-scan's own rule (an "example" in the value): since
# #342 taught the scan ghs_ tokens, a real-looking value here was a line the
# public snapshot's credential scan refused to publish.
_uctok="ghs_exampletokenexampletokenexample"
: > "$UC/git.log"; : > "$UC/git.cred"
( cd "$UC/repo" && UC_LOG="$UC/git.log" GITHUB_TOKEN="$_uctok" IMPLICATED=src/a.txt GITHUB_OUTPUT="$UC/out.gh" \
    BRANCH=fix/x PATH="$UC/bin:$PATH" \
    TMPDIR="$UC/tmpd" UC_MKREAL="$_ucmkreal" UC_MKLOG="$UC/mktemp.log" \
    bash -e "$UC/step.sh" ) > "$UC/out" 2>&1; _ucrc=$?
[ "$_ucrc" -eq 0 ] && ok  "a green gate pushes the repair" \
                   || bad "a green gate pushes the repair" "exit $_ucrc: $(cat "$UC/out")"
has "and pushes it to the branch the run repaired" "$(cat "$UC/git.log")" "push origin HEAD:fix/x"
has "the push step hands git the token itself, through a helper reading the step's environment" \
    "$(cat "$UC/git.cred")" "password=$_uctok"
case "$(cat "$UC/git.log")" in
  *"$_uctok"*) bad "and the token is in no argument git was given" "$(grep -n "$_uctok" "$UC/git.log")" ;;
  *)           ok  "and the token is in no argument git was given" ;;
esac
# R41 (b): the stand-in mktemp was reached by the step, and every path it logged is under $TMP
_mkx="$(LC_ALL=C awk -v p="$TMP/" '{ t++; if (index($0, p) != 1) { o++; if (o <= 3) b = b " [" $0 "]" } } END { if (t == 0) print "no path logged"; else if (o) print o " of " t " outside:" b; else print "ok" }' "$UC/mktemp.log" 2>/dev/null)"
is "R41: every path the mktemp stand-in logged for the push step's run is under \$TMP, and it logged some" "${_mkx:-no log}" ok
printf '\nthe unattended repair denies the model its own environment\n'
# The attempt step runs with ANTHROPIC_API_KEY in its environment, so the
# claude process it starts carries the key, and on Linux a process's
# environment is a file, /proc/self/environ. A tool-name allow rule matches
# every path, and `--allowedTools "Read,Edit"` is one. Measured on the pinned
# 2.1.37 on ubuntu-latest (2026-09-24, the real binary against a scripted
# Messages API, run in a throwaway Actions repository; the rig is in the pull
# request): Read on /proc/self/environ returned the environment, key included,
# and Edit put the key in a tracked file, which the push step commits. A model
# steered by a hostile failing log is the reader to plan for. A deny rule is
# read before the allow rule, and the same measurement chose the spelling:
# `Read(//proc/**)` refused the path however it was written (/proc/self/environ,
# /proc/self/../self/environ, a relative path climbing to /proc,
# /proc//self/environ, /proc/thread-self/environ), each as a tool_use_error
# reading "File is in a directory that is denied by your permission settings"
# with the result line's permission_denials left empty, and left the
# repository's own files readable; `Read(/proc/**)`, one slash, refused
# nothing, since one slash names a path under the working directory. The
# measurement is the pin's: when the claude-code version moves, measure again.
# The claude stub records each argument on a line of its own, so what is
# asserted is what the shell handed the binary, not the template's text.
# Every --disallowedTools value is read, and every --allowedTools value, so
# a second deny rule beside this one, in the same list or its own flag, and
# an allow list that scopes Read and Edit to a path, keep passing.
printf '#!/usr/bin/env bash\nprintf "claude\\n" >> "%s/claude.log"\nprintf "%%s\\n" "$@" > "%s/claude.args"\n' "$AT" "$AT" > "$AT/bin/claude"
_attempt ""
_atrules() { awk -v f="$1" 'p { print; p = 0; next } $0 == f { p = 1 }' "$AT/claude.args" | tr ', ' '\n\n' | grep -v '^$'; }
_atdeny="$(_atrules --disallowedTools)"
if grep -q -x -F 'Read(//proc/**)' <<<"$_atdeny"; then
  ok  "the model step disallows Read under /proc, in the spelling 2.1.37 honours"
else
  bad "the model step disallows Read under /proc, in the spelling 2.1.37 honours" \
      "--disallowedTools ${_atdeny:-(absent)}"
fi
_atallow="$(_atrules --allowedTools)"
if grep -q -x -E 'Read(\(.*\))?' <<<"$_atallow" \
   && grep -q -x -E 'Edit(\(.*\))?' <<<"$_atallow"; then
  ok  "and Read and Edit stay allowed, since the repair needs both"
else
  bad "and Read and Edit stay allowed, since the repair needs both" "--allowedTools ${_atallow:-(absent)}"
fi

printf '\nthe unattended repair runs the action code its pins name, and no other\n'
# A tag is a ref its owner can move, so `actions/checkout@v5` runs whatever
# that repository points v5 at on the day the job runs, and it runs inside the
# step that fetches Felix with the deploy key, in a job holding a write token.
# The template pins the Felix ref and the claude-code install for that reason;
# semgrep's github-actions-mutable-action-tag (1.175, p/github-actions, run
# 2026-09-24) found the two checkouts had been left on a tag. Every `uses:` key
# in the file is read, a step's or a job's, so an action added later is held
# to the same pin without this list being edited. A read that found none is a
# failure too: an enumeration that matched nothing would pass every file.
_uauses="$(awk '/^[ \t]*#/ { next }
                /^[ \t]*(-[ \t]+)?uses:/ { v = $0
                  sub(/^[ \t]*(-[ \t]+)?uses:[ \t]*/, "", v); sub(/[ \t]+#.*$/, "", v)
                  print NR ": " v }' "$REAL_HARNESS/templates/unattended.yml" | tr -d "\"'")"
_ualoose="$(printf '%s\n' "$_uauses" | grep -v -E '^[0-9]+: [^@[:space:]]+@[0-9a-f]{40}$')"
if [ -n "$_uauses" ] && [ -z "$_ualoose" ]; then
  ok  "every uses: in the unattended template names a full commit sha, not a ref its owner can move"
else
  bad "every uses: in the unattended template names a full commit sha, not a ref its owner can move" \
      "${_ualoose:-no uses: line found}"
fi

printf '\nunattended budget\n'
# The ceiling worth having fails between runs, not during one, and counts
# repetition rather than money: ten deliberate attempts in a day is a working
# system, two hundred is a loop whatever each one cost.
rm -f "$FROOT/projects/widget/budget.log"
python3 - "$FROOT/projects/widget/project.json" <<'PYJ'
import json,sys,pathlib
p=pathlib.Path(sys.argv[1]); d=json.loads(p.read_text())
d["unattended_daily_limit"]="2"; p.write_text(json.dumps(d,indent=2))
PYJ
out="$(cd "$REPO" && "$FELIX" budget 2>&1)"
has "reads the per-project limit" "$out" "limit:  2"
has "and reports what is left"    "$out" "left:   2"

( cd "$REPO" && "$FELIX" budget --record >/dev/null 2>&1 )
( cd "$REPO" && "$FELIX" budget --record >/dev/null 2>&1 )
out="$(cd "$REPO" && "$FELIX" budget 2>&1)"; rc=$?
has "spending is counted" "$out" "used:   2"
is  "exhausted exits 3"   "$rc" "3"

out="$(cd "$REPO" && "$FELIX" budget --record 2>&1)"; rc=$?
is  "and refuses to spend past the ceiling" "$rc" "3"
has "saying why"                            "$out" "budget exhausted"

# A ceiling in a runner's ephemeral filesystem resets every job, invisibly.
[ -f "$FROOT/projects/widget/budget.log" ] \
  && ok "the ledger is durable state in the project" \
  || bad "the ledger is durable state in the project"

# Old entries age out rather than accumulating forever.
printf '1\t1970-01-01T00:00\tancient\n' >> "$FROOT/projects/widget/budget.log"
out="$(cd "$REPO" && "$FELIX" budget 2>&1)"
has "entries older than a day do not count" "$out" "used:   2"

# #84, the half that is mechanical. The append was unchecked and the caller
# reported `used + 1` - arithmetic on a value read BEFORE the write, not a
# reading of what landed. So a record that never landed printed
# `recorded. 1 of 10 used` and exited 0; `used` stayed 0 forever; and the
# ceiling silently became no ceiling. budget.sh's own header names that exact
# outcome as the thing to prevent - "which is the same as no ceiling, and it
# resets invisibly."
#
# An unwritable project directory is the cheapest real cause. A full disk or a
# read-only mount reach the same place, and one of them is how this would
# actually happen on a runner.
#
# A write refused by a mode is asked of this machine first, the way a read is
# further down: root writes through a directory at 555 and a file at 444, and
# a cloud session runs as root, so there the refusal cannot be built. Those
# assertions skip, not pass, and not fail on a write that was never refused,
# which also left the probe's row in the log for the control below to count.
_unwritable_probe
rm -f "$FROOT/projects/widget/budget.log"
python3 - "$FROOT/projects/widget/project.json" <<'PYJ'
import json,sys,pathlib
p=pathlib.Path(sys.argv[1]); d=json.loads(p.read_text())
d["unattended_daily_limit"]="10"; p.write_text(json.dumps(d,indent=2))
PYJ
if [ "$_unwritable" -eq 1 ]; then
  chmod 555 "$FROOT/projects/widget"
  out="$(cd "$REPO" && "$FELIX" budget --record --why "probe" 2>&1)"; rc=$?
  chmod 755 "$FROOT/projects/widget"

  [ "$rc" -ne 0 ] && ok "a record that could not be written does not exit 0" \
                  || bad "a record that could not be written does not exit 0" \
                         "exit $rc after: $out"
  case "$out" in
    *"recorded."*) bad "and does not say it recorded" "$out" ;;
    *)             ok  "and does not say it recorded" ;;
  esac
  # The number is the tell. `used + 1` reports a spend that never happened, and it
  # reports it in the same words a real one uses.
  case "$out" in
    *"1 of 10"*) bad "nor report a spend that did not happen" "$out" ;;
    *)           ok  "nor report a spend that did not happen" ;;
  esac
  is "and nothing was written" \
     "$([ -f "$FROOT/projects/widget/budget.log" ] && echo present || echo absent)" "absent"
else
  for a in "a record that could not be written does not exit 0" "and does not say it recorded" \
           "nor report a spend that did not happen" "and nothing was written"; do
    skip "$a" "$_nowrite"; done
fi

# The control, and the half a careless fix breaks: a writable project still
# records, still exits 0, and the count it prints is the one the log holds
# rather than one it worked out in advance.
out="$(cd "$REPO" && "$FELIX" budget --record --why "real" 2>&1)"; rc=$?
is  "a writable project still records" "$rc" "0"
has "and says so"                      "$out" "recorded."
is  "the log holds exactly one entry" \
    "$( . "$FROOT/harness/lib/budget.sh"; felix_budget_used "$FROOT/projects/widget" )" "1"
has "which is the number it printed"   "$out" "1 of 10"

# And the library says so on its own, so the fix cannot be a message change in
# the command while the function still swallows the failure.
#
# The log is removed first, and that is not tidiness. Directory permissions gate
# CREATION, not appends to a file that already exists - so with the control's
# budget.log still in place, chmod 555 on the directory leaves the append
# perfectly writable and the probe tests nothing. This assertion passed for that
# reason before the log was removed.
rm -f "$FROOT/projects/widget/budget.log"
if [ "$_unwritable" -eq 1 ]; then
  chmod 555 "$FROOT/projects/widget"
  ( . "$FROOT/harness/lib/budget.sh"
    felix_budget_record "$FROOT/projects/widget" "lib probe" 2>/dev/null ); librc=$?
  chmod 755 "$FROOT/projects/widget"
  [ "$librc" -ne 0 ] && ok "felix_budget_record itself reports the failure" \
                     || bad "felix_budget_record itself reports the failure" "exit $librc"
else
  skip "felix_budget_record itself reports the failure" "$_nowrite"
fi
rm -f "$FROOT/projects/widget/budget.log"

# #84, the race. cmd_budget is check-then-act with no lock: it reads the count,
# compares it to the limit, then appends. Two callers that both read 9 against a
# limit of 10 both pass the comparison and both append, and the ceiling - the
# only mechanical bound on unattended model runs - is overrun.
#
# Reproduced against shipped code on ONE machine, no CI involved: seeded at 9 of
# 10, three concurrent callers, all three recorded, ledger left at 12.
#
# Driven with real concurrent processes rather than a stub, because the defect
# IS the interleaving; a sequential fixture cannot express it. It is made
# deterministic by seeding the ledger so exactly one slot remains, which makes
# the correct outcome exact rather than probabilistic: at most one caller may
# record, however the three interleave.
_seed_budget() {   # $1 = how many entries to seed
  local n="$1" now i
  now="$(date +%s)"
  : > "$FROOT/projects/widget/budget.log"
  i=0; while [ "$i" -lt "$n" ]; do
    printf '%s\t%s\tseed\n' "$now" "1970-01-01T00:00" >> "$FROOT/projects/widget/budget.log"
    i=$((i + 1))
  done
}
_seed_budget 9
RACE="$TMP/race"; rm -rf "$RACE"; mkdir -p "$RACE"
for _r in 1 2 3; do
  ( cd "$REPO" && "$FELIX" budget --record --why "racer$_r" >"$RACE/out$_r" 2>&1
    printf '%s' "$?" > "$RACE/rc$_r" ) &
done
wait

_recorded=0
for _r in 1 2 3; do
  [ "$(cat "$RACE/rc$_r" 2>/dev/null)" = "0" ] && _recorded=$((_recorded + 1))
done
# At most one, because exactly one slot was left. Zero is allowed and safe: if
# every caller observes the ledger after every append, they all refuse, and the
# window reopens on the next invocation. More than one is the overrun.
[ "$_recorded" -le 1 ] \
  && ok "at most one caller records when one slot is left" \
  || bad "at most one caller records when one slot is left" \
         "$_recorded of 3 recorded; ledger has $(grep -c . "$FROOT/projects/widget/budget.log") entries"

# And no caller may claim success while reporting a count past the ceiling. That
# sentence is what a workflow step reads as permission to invoke a model.
_overclaim=0
for _r in 1 2 3; do
  if [ "$(cat "$RACE/rc$_r" 2>/dev/null)" = "0" ]; then
    case "$(cat "$RACE/out$_r")" in
      *"1"[1-9]" of 10"*|*"2"[0-9]" of 10"*) _overclaim=$((_overclaim + 1)) ;;
    esac
  fi
done
is "and none reports a spend past the ceiling as recorded" "$_overclaim" "0"
rm -f "$FROOT/projects/widget/budget.log"

