printf '\nthe unattended repair acts only on a brief\n'
# The ceiling above is enforced by felix repair's exit status, and the one
# thing that reads that status in CI is the scope step of
# templates/unattended.yml. It proceeded on everything but 3, so read under
# plain bash, exit 2, CEILING REACHED, still spent the budget and handed a
# model the brief that told it to stop: the ceiling held only as long as a
# model read a sentence. Nothing to repair exited 0 until 2026-09-23, so a
# green branch would have done the same with a brief saying nothing was wrong;
# it exits 5 now.
# The step is taken out of the shipped template as it stands and run against a
# stub felix that exits with each status repair can return, with gh stubbed to
# record what it is asked. Its brief goes to the fixture, not to /tmp. It runs
# under bash -e, as Actions runs a step that names no shell (the shell line of
# every step in a gate run's log). Under plain bash it read every status; under
# -e with pipefail it ended at felix repair's first non-zero one, so the
# escalation asserted below had never run in CI.
SC="$TMP/scope"; mkdir -p "$SC/repo" "$SC/felix/engine/harness" "$SC/bin"
awk '/- name: Scope the failure/ { f = 1 } f && /^        run: \|/ { r = 1; next }
     r && /^      [^ ]/ { exit } r { sub(/^          /, ""); print }' \
  "$REAL_HARNESS/templates/unattended.yml" \
  | sed "s#/tmp/brief.txt#$SC/brief.txt#; s#/tmp/implicated.txt#$SC/implicated.txt#g" > "$SC/step.sh"
# felix repair as the step calls it: --implicated names a file it empties, and
# a brief (0) writes the named files into it. SCOPE_NAMED is that set, and
# SCOPE_NOFILE a Felix from before --implicated, which writes nothing.
cat > "$SC/felix/engine/harness/felix" <<'STUB'
#!/usr/bin/env bash
prev=""
for a in "$@"; do
  if [ "$prev" = "--implicated" ] && [ -z "${SCOPE_NOFILE:-}" ]; then
    : > "$a"
    if [ "${SCOPE_RC:-0}" = "0" ] && [ -n "${SCOPE_NAMED:-}" ]; then
      printf '%s\n' "$SCOPE_NAMED" > "$a"
    fi
  fi
  prev="$a"
done
printf "brief\n"; exit "${SCOPE_RC:-0}"
STUB
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s/gh.log"\ncase "$1 $2" in "pr list") printf "7\\n" ;; esac\nexit 0\n' "$SC" > "$SC/bin/gh"
chmod +x "$SC/felix/engine/harness/felix" "$SC/bin/gh"
_scope() { : > "$SC/out"; : > "$SC/gh.log"
  ( cd "$SC/${2:-repo}" && SCOPE_RC="$1" SCOPE_NAMED="${_snamed-src/a.py}" SCOPE_NOFILE="${_snofile:-}" \
      GITHUB_OUTPUT="$SC/out" BRANCH=fix/x PATH="$SC/bin:$PATH" \
      bash -e "$SC/step.sh" ) >/dev/null 2>"$SC/err"; }
_sres=""; _snot=""
for _r in 0 1 2 3 4 5; do
  _scope "$_r"; _src=$?
  _sres="$_sres $_r:$(sed -n 's/^proceed=//p' "$SC/out" | head -1)"
  _snot="$_snot $_r:$(sed -n 's/^nothing=//p' "$SC/out" | head -1)"
  case "$_r" in
    0) _s0brief="$(cat "$SC/brief.txt" 2>/dev/null)"
       _s0set="$(awk '/^implicated<</ { d = substr($0, 13); f = 1; next } f && $0 == d { exit } f' "$SC/out")" ;;
    1) _s1rc="$_src" ;;
    2) _s2gh="$(cat "$SC/gh.log")" ;;
    3) _s3gh="$(cat "$SC/gh.log")" ;;
    5) _s5rc="$_src"; _s5gh="$(cat "$SC/gh.log")"
       _s5p="$(sed -n 's/^proceed=//p' "$SC/out" | head -1)" ;;
  esac
done
is  "the unattended repair proceeds on a brief, and on no other exit of felix repair" "$_sres" " 0:yes 1:no 2:no 3:no 4:no 5:no"
is  "and the brief it proceeds on is the file the repair step hands a model" "$_s0brief" "brief"
# The set goes on as a step output, which nothing after the step can rewrite,
# whatever the model's tools could reach.
is  "and the set it proceeds on is handed on as the step's output" "$_s0set" "src/a.py"
has "a reached repair ceiling is escalated to a person" "$_s2gh" "pr edit 7 --add-label needs-founder"
has "a failure on a red path is escalated to a person" "$_s3gh" "pr edit 7 --add-label needs-founder"
[ "${_s1rc:-0}" -ne 0 ] && ok  "a run felix repair could not read fails the job rather than passing quietly" \
                        || bad "a run felix repair could not read fails the job rather than passing quietly" "exit ${_s1rc:-?}"
[ "${_s5rc:-1}" -eq 0 ] && [ "${_s5p:-}" = "no" ] && [ -z "${_s5gh:-}" ] \
  && ok  "nothing to repair ends the job clean: not acted on, not failed, not escalated" \
  || bad "nothing to repair ends the job clean: not acted on, not failed, not escalated" \
         "exit ${_s5rc:-?}, proceed=${_s5p:-(unset)}, gh asked: ${_s5gh:-nothing}"
# Under the name the report reads: every steps.scope.outputs key the template
# reads is one the step writes, since an output never written reads as empty.
_sread="$(grep -o 'steps\.scope\.outputs\.[a-z_]*' "$REAL_HARNESS/templates/unattended.yml" \
          | sed 's/.*\.//' | sort -u)"
_sunwritten=""
for _k in $_sread; do grep -qE "echo \"$_k(=|<<)" "$SC/step.sh" || _sunwritten="$_sunwritten $_k"; done
[ "$_snot" = " 0: 1: 2: 3: 4: 5:yes" ] && [ -z "$_sunwritten" ] \
  && ok  "and only nothing to repair tells the report so, under the name the report reads" \
  || bad "and only nothing to repair tells the report so, under the name the report reads" \
         "written:$_snot; read and never written:${_sunwritten:- none}"

# A brief that names no file in the checkout. The model would be told to edit
# only the files the brief lists, it lists none, and the verify step refuses
# any other, so every change would be refused after the budget and a model run
# were spent. It stops at scope instead, and without a label: the failure is
# already red on the pull request, and nothing risky is known about it.
_snamed=""; _scope 0; _src=$?; unset _snamed
is  "a brief that names no file stops at scope: not acted on, not failed, not escalated" \
    "exit $_src, proceed=$(sed -n 's/^proceed=//p' "$SC/out" | head -1), unnamed=$(sed -n 's/^unnamed=//p' "$SC/out" | head -1), gh [$(tr '\n' ' ' < "$SC/gh.log")]" \
    "exit 0, proceed=no, unnamed=yes, gh []"
# A Felix that never writes the set, one pinned from before --implicated, with
# a set left over from an earlier run on the same runner. Read as this run's,
# the leftover would hold a repair to files the failing log never named.
printf 'src/a.py\n' > "$SC/implicated.txt"
_snofile=1; _scope 0; _src=$?; unset _snofile
is  "a Felix that writes no implicated set fails the job, and a set left from an earlier run does not stand in" \
    "exit $_src, proceed=$(sed -n 's/^proceed=//p' "$SC/out" | head -1), gh [$(tr '\n' ' ' < "$SC/gh.log")]" \
    "exit 1, proceed=no, gh []"

# The step above branches on felix repair's statuses, and the engine answering
# is whatever the Felix checkout fetched. With no ref that was the default
# branch on the day the job ran, and those statuses changed four times on
# 2026-09-23 under copies that had not changed. The pin is what keeps a copy
# and the engine it reads on the same commit.
_sfx="$(grep -A1 'repository: {{FELIX_REPO}}' "$REAL_HARNESS/templates/unattended.yml" | sed -n 2p)"
is  "the unattended template checks Felix out at a pinned ref, not the default branch" \
    "$(printf '%s' "$_sfx" | tr -d ' ')" "ref:'{{FELIX_REF}}'"

# The two halves together: the real felix repair on a green branch, read by the
# step as shipped. Each half can pass its own assertions while the pair does
# not, as when repair's status and the step's reading of it change apart.
if command -v jq >/dev/null 2>&1; then
  _gate_workflow_stub_build; _gate_workflow_repo_build
  sed "s#\.\./felix/engine/harness/felix#$FELIX#" "$SC/step.sh" > "$SC/step-real.sh"
  printf 'gate.yml\tgate\tfix/y\t211\tcompleted\tsuccess\n' > "$SC/runs"
  : > "$SC/out"
  ( cd "$WFR" && GITHUB_OUTPUT="$SC/out" BRANCH=fix/y WFSTUB_LOG="$SC/wf.log" \
      WFSTUB_RUNS="$SC/runs" WFSTUB_WORKFLOWS="gate.yml" PATH="$WFB:$PATH" \
      bash -e "$SC/step-real.sh" ) >/dev/null 2>&1; _serc=$?
  _sep="$(sed -n 's/^proceed=//p' "$SC/out" | head -1)"
  _sen="$(sed -n 's/^nothing=//p' "$SC/out" | head -1)"
  [ "$_serc" -eq 0 ] && [ "$_sep" = "no" ] && [ "$_sen" = "yes" ] \
    && ok  "a green branch stops the shipped step at scope, read from the real felix repair" \
    || bad "a green branch stops the shipped step at scope, read from the real felix repair" \
           "exit $_serc, proceed=${_sep:-(unset)}, nothing=${_sen:-(unset)}"
else
  skip "a green branch stops the shipped step at scope, read from the real felix repair" \
       "no jq here to evaluate gh's -q expressions"
fi

# A checkout Felix cannot resolve, through the real felix repair rather than a
# stub's chosen status. Resolution exited 2 there, which this step's case read
# as the ceiling and escalated to a person under that reason. It is wiring,
# and true of every branch at once, so the job fails, no pull request is
# labelled, and the message names the binding. Both ways resolution fails: no
# project claims the checkout, and a .felix marker names a project the home
# does not hold.
printf '#!/usr/bin/env bash\nexec "%s" "$@"\n' "$FELIX" > "$SC/felix/engine/harness/felix"
chmod +x "$SC/felix/engine/harness/felix"
mkdir -p "$SC/unbound" "$SC/misbound"
( _fx_cd "$SC/unbound" && git init -q -b main )
( _fx_cd "$SC/misbound" && git init -q -b main && printf 'nonexistent\n' > .felix )
for _w in unbound misbound; do
  _scope 0 "$_w"; _src=$?
  _sgot="exit $_src, proceed=$(sed -n 's/^proceed=//p' "$SC/out" | head -1), gh [$(tr '\n' ' ' < "$SC/gh.log")]"
  is  "the unattended job on the $_w checkout fails and labels no pull request" \
      "$_sgot" "exit 1, proceed=no, gh []"
  case "$(cat "$SC/err")" in
    *ceiling*) bad "and the $_w job says the binding failed, not the ceiling" "$(cat "$SC/err")" ;;
    *"governs this repository"*) ok "and the $_w job says the binding failed, not the ceiling" ;;
    *) bad "and the $_w job says the binding failed, not the ceiling" "$(cat "$SC/err")" ;;
  esac
done

printf '\nthe unattended repair says why it stopped before the model\n'
# The attempt step installs the pinned claude-code with every line of npm's
# output thrown away, and Actions runs a step that names no shell as `bash -e`.
# A failed install therefore ended the step at that line with nothing printed,
# after the budget step had already recorded the run's spend. The step is taken
# out of the shipped template as it stands and run under `bash -e`, with npm
# and claude stubbed.
_attempt_build
_attempt 1; _arc=$?
[ "$_arc" -ne 0 ] && ok  "a failed install fails the repair step" \
                  || bad "a failed install fails the repair step" "exit 0: $(cat "$AT/out")"
has "and says the install failed rather than ending in silence" "$(cat "$AT/out")" "could not install"
has "and passes on npm's own reason" "$(cat "$AT/out")" "E404"
is  "and no model is run" "$(wc -l < "$AT/claude.log" | tr -d ' ')" "0"
_attempt ""
is  "an install that succeeds goes on to the model" "$(wc -l < "$AT/claude.log" | tr -d ' ')" "1"

printf '\nthe unattended repair gets its push gated\n'
# The repair pushes with the GITHUB_TOKEN actions/checkout leaves in the
# checkout, and GitHub starts no workflow for an event that token causes,
# workflow_dispatch and repository_dispatch excepted. On github.com a pull
# request the token updates gets a pull_request run that waits for a person to
# approve it. So a repaired commit reached its pull request with no gate
# verdict, and the ceiling counted gate runs people caused, not repair
# attempts. The same token cannot push a change under .github/workflows, so a
# repair that edited one failed at the push, after the gate had passed it.
# Both rules are GitHub's, from "Triggering a workflow from a workflow".
#
# The verify step is taken out of the shipped template and run under bash -e
# in a clone of a bare remote, with felix stubbed to a gate of the test's
# choosing. A bare remote takes a workflow file from anyone, so a refusal here
# is the step's own and not the server's.
UT="$REAL_HARNESS/templates/unattended.yml"
VP="$TMP/verify"; mkdir -p "$VP/felix/engine/harness" "$VP/bin" "$VP/vbin"
awk '/- name: Verify and push/ { f = 1 } f && /^        run: \|/ { r = 1; next }
     r && /^      [^ ]/ { exit } r { sub(/^          /, ""); print }' "$UT" > "$VP/step.sh"
# The gate is stubbed to a status of the test's choosing. Everything else is
# the real felix, so the verify step's own scope check is the real classifier
# reading the real risk table: the fixture checkout is bound to widget, whose
# table is the shipped template's for the length of this section.
printf '#!/usr/bin/env bash\n[ "$1" = gate ] || exec "%s" "$@"\nprintf "gate\\n" >> "%s/gate.log"\nexit "${VERIFY_GATE_RC:-0}"\n' \
  "$FELIX" "$VP" > "$VP/felix/engine/harness/felix"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s/gh.log"\ncase "$1 $2" in "pr list") printf "7\\n" ;; esac\nexit 0\n' \
  "$VP" > "$VP/vbin/gh"
chmod +x "$VP/felix/engine/harness/felix" "$VP/vbin/gh"
# The step's `named="$(mktemp)"` is never removed, and on macOS a template-less mktemp ignores
# TMPDIR, so the step runs with a mktemp first on its PATH that gives it the template
# "$TMPDIR/tmp.XXXXXXXXXX" (TMPDIR a directory of this part's own) and logs each path it made.
mkdir -p "$VP/tmpd"; _vmkreal="$(command -v mktemp)"
cat > "$VP/vbin/mktemp" <<'VPMK'
#!/bin/sh
# mktemp for R41: the host's ($VP_MKREAL), logging each path it made to $VP_MKLOG. With no template argument (only options) it passes the same options and the template "$TMPDIR/tmp.XXXXXXXXXX".
t=0
for a in "$@"; do case "$a" in -*) ;; *) t=1 ;; esac; done
if [ "$t" = 0 ] && [ -n "${TMPDIR:-}" ]; then
  set -- "$@" "${TMPDIR%/}/tmp.XXXXXXXXXX"
fi
out="$("$VP_MKREAL" "$@")" || exit $?
printf '%s\n' "$out" >> "$VP_MKLOG"
printf '%s\n' "$out"
VPMK
chmod +x "$VP/vbin/mktemp"; : > "$VP/mktemp.log"
# The judge the verify step checks is unchanged: a checkout, as in the job,
# with a risk table of its own in it.
mkdir -p "$VP/felix/projects/widget"
cp "$REAL_HARNESS/templates/risk.tsv" "$VP/felix/projects/widget/risk.tsv"
( _fx_cd "$VP/felix" && git init -q -b main && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm felix ) >/dev/null 2>&1
# Kept only where it exists: run alone it is absent, and it is then taken away again at the end.
_vrisk_had=0; if [ -f "$FROOT/projects/widget/risk.tsv" ]; then cp "$FROOT/projects/widget/risk.tsv" "$VP/risk.keep"; _vrisk_had=1; fi
cp "$REAL_HARNESS/templates/risk.tsv" "$FROOT/projects/widget/risk.tsv"
# The implicated set the scope step would hand on as its output, src/a.txt
# unless a test says otherwise; _verify passes it in as the job would.
_vfix() { rm -rf "$VP/remote.git" "$VP/repo"
  git init -q --bare "$VP/remote.git"
  git init -q -b fix/x "$VP/repo"
  ( _fx_cd "$VP/repo" && git remote add origin "$VP/remote.git" \
    && mkdir -p .github/workflows src tests && printf 'on: push\n' > .github/workflows/gate.yml \
    && printf 'a\n' > src/a.txt && printf 'def test_a(): pass\n' > tests/test_a.py \
    && printf 'c\n' > "src/caf$(printf '\303\251').txt" && printf '*.local\n' > .gitignore \
    && printf 'widget\n' > .felix && git add -A \
    && git -c user.name=t -c user.email=t@t commit -qm base && git push -q origin fix/x ) >/dev/null 2>&1
  printf 'src/a.txt\n' > "$VP/implicated.txt"
  _v0="$(git --git-dir="$VP/remote.git" rev-parse fix/x)"; }
_verify() { : > "$VP/out"; : > "$VP/gate.log"; : > "$VP/gh.log"
  ( cd "$VP/repo" && IMPLICATED="$(cat "$VP/implicated.txt" 2>/dev/null)" VERIFY_GATE_RC="$1" \
      GITHUB_OUTPUT="$VP/out" BRANCH=fix/x PATH="$VP/vbin:$PATH" \
      TMPDIR="$VP/tmpd" VP_MKREAL="$_vmkreal" VP_MKLOG="$VP/mktemp.log" \
      bash -e "$VP/step.sh" ) > "$VP/log" 2>&1; _vrc=$?
  _vgot="exit $_vrc, remote $([ "$(git --git-dir="$VP/remote.git" rev-parse fix/x)" = "$_v0" ] \
    && echo unchanged || echo moved), gate $(wc -l < "$VP/gate.log" | tr -d ' '), pushed=$(sed -n 's/^pushed=//p' "$VP/out" | head -1)"
  _vtree="tree $( cd "$VP/repo" && [ "$(git rev-parse HEAD)" = "$_v0" ] && [ -z "$(git status --porcelain --ignored)" ] \
    && echo "at base" || echo "not at base" ), refused=$(sed -n 's/^refused=//p' "$VP/out" | head -1)"
  _vlab="$(tr '\n' ' ' < "$VP/gh.log")"; }

# Named in the set, so what stops it is the workflow-file check and not the
# set: a project whose risk table does not call .github/workflows red lets the
# scope step hand such a file on.
_vfix; printf '.github/workflows/gate.yml\n' > "$VP/implicated.txt"
printf 'on: [push, workflow_dispatch]\n' > "$VP/repo/.github/workflows/gate.yml"
_verify 0
is  "a repair that edits a workflow file is not pushed, and the gate is not spent on it" \
    "$_vgot, tree $(cd "$VP/repo" && git diff --quiet && echo clean || echo dirty)" \
    "exit 1, remote unchanged, gate 0, pushed=, tree clean"
has "and it names the workflow file it will not push" "$(cat "$VP/log")" ".github/workflows/gate.yml"
_vfix; printf 'b\n' >> "$VP/repo/src/a.txt"
_verify 0
is  "a repair the gate passes is pushed, and says so to the job that runs the gate again" \
    "$_vgot" "exit 0, remote moved, gate 1, pushed=yes"
_vfix; printf 'b\n' >> "$VP/repo/src/a.txt"
_verify 1
is  "a repair the gate fails is not pushed, and asks for no second gate run" \
    "$_vgot" "exit 1, remote unchanged, gate 1, pushed="

# What the attempt may touch, checked on its own diff before the gate. The
# prompt tells the model to edit only the files the brief names, and until
# 2026-09-24 nothing else did: whatever it changed was pushed once the gate
# was green, red paths included, and a gate can be turned green by editing
# what it reads. A file outside the set is refused whatever its tier, so the
# one here is a file the risk rules call green.
_vfix; printf 'b\n' >> "$VP/repo/src/a.txt"; printf 'import pytest; pytest.skip()\n' >> "$VP/repo/tests/test_a.py"
_verify 0
is  "a repair that changes a file the brief did not name is not pushed, and the gate is not spent on it" \
    "$_vgot, $_vtree" "exit 1, remote unchanged, gate 0, pushed=, tree at base, refused=yes"
is  "and it is refused though the risk rules call that file green" \
    "$(cd "$VP/repo" && "$FELIX" scope tests/test_a.py 2>&1 | sed -n 's/^highest tier: //p')" "green"
has "and it names the file it will not push" "$(cat "$VP/log")" "tests/test_a.py"
has "and it hands the change to a person on the branch's pull request" "$_vlab" "pr edit 7 --add-label needs-founder"

# A file the model created is in neither `git diff` nor `git commit -a`, so it
# is never pushed, but the gate reads it: a conftest.py that skips the failing
# test would turn the gate green on a commit that never carried it.
_vfix; printf 'b\n' >> "$VP/repo/src/a.txt"; printf 'collect_ignore = ["src"]\n' > "$VP/repo/src/conftest.py"
_verify 0
is  "a file the attempt created is outside the brief too, and is not left for anything to read" \
    "$_vgot, $_vtree" "exit 1, remote unchanged, gate 0, pushed=, tree at base, refused=yes"

# Inside the set, the diff is classified with its content, not only its paths.
# A credential written into a file the brief named is red whatever the file is
# called, and scoping the path alone passed it (#100's defect, one step later).
# `sk-` and not `sk-ant-`, as in the scope section: must_flag excuses a fixture
# line to secret-scan only when no hard shape is on it, and `sk-ant-` is one.
_vfix; printf 'api_key = "sk-QQQQQQQQQQQQQQQQQQQQQQQQ"\n' >> "$VP/repo/src/a.txt"   # must_flag
_verify 0
is  "a credential written into a file the brief named is red, and is not pushed" \
    "$_vgot, $_vtree" "exit 1, remote unchanged, gate 0, pushed=, tree at base, refused=yes"
has "and it says the risk rules called the diff red" "$(cat "$VP/log")" "call the attempt's own diff red"
has "and it hands that to a person too" "$_vlab" "pr edit 7 --add-label needs-founder"

# An ignored file is untracked too, and the gate reads it the same way: a
# *.local a test run picks up passed the gate, and the named edit beside it
# was pushed, since neither the diff nor the untracked list showed it.
_vfix; printf 'b\n' >> "$VP/repo/src/a.txt"; printf 'fixed\n' > "$VP/repo/gate.local"
_verify 0
is  "an ignored file the attempt created is outside the brief as well, and is removed" \
    "$_vgot, $_vtree" "exit 1, remote unchanged, gate 0, pushed=, tree at base, refused=yes"
# The judge: the scope check and the gate run from the Felix checkout beside
# this one, and a green row added to its risk table would clear the change it
# judges. No command the job runs writes there.
_vfix; printf 'b\n' >> "$VP/repo/src/a.txt"
printf 'green\tpath\t.*\tanything goes\n' >> "$VP/felix/projects/widget/risk.tsv"
_verify 0
( _fx_cd "$VP/felix" && git checkout -q -- . )
is  "a change to the Felix checkout that judges the repair is refused before it judges" \
    "$_vgot, $_vtree" "exit 1, remote unchanged, gate 0, pushed=, tree at base, refused=yes"
# git quotes a name outside ASCII, so the file the brief named never matched
# its own entry and every such repair was refused and labelled.
_vfix; _vcafe="src/caf$(printf '\303\251').txt"
printf '%s\n' "$_vcafe" > "$VP/implicated.txt"; printf 'd\n' >> "$VP/repo/$_vcafe"
_verify 0
is  "a named file whose name is not ASCII is pushed like any other" \
    "$_vgot, refused=$(sed -n 's/^refused=//p' "$VP/out" | head -1)" "exit 0, remote moved, gate 1, pushed=yes, refused="

# Wiring, not the change, so no label: the scope step left no set, or felix
# scope could not classify. Neither is pushed on the strength of a check that
# did not run.
_vfix; rm -f "$VP/implicated.txt"; printf 'b\n' >> "$VP/repo/src/a.txt"
_verify 0
is  "with no implicated set from the scope step, nothing is pushed and no pull request is labelled" \
    "$_vgot, $_vtree, gh [$_vlab]" "exit 1, remote unchanged, gate 0, pushed=, tree at base, refused=, gh []"
_vfix; printf 'b\n' >> "$VP/repo/src/a.txt"
mv "$FROOT/projects/widget/risk.tsv" "$VP/risk.away"
_verify 0
mv "$VP/risk.away" "$FROOT/projects/widget/risk.tsv"
is  "a diff felix scope cannot classify is not pushed, and no pull request is labelled" \
    "$_vgot, $_vtree, gh [$_vlab]" "exit 1, remote unchanged, gate 0, pushed=, tree at base, refused=, gh []"

# The set reaches the verify step as the scope step's output, never as a file.
# With `Read,Edit` unscoped the model read and edited /tmp and the Felix
# checkout (measured on the pinned CLI), so a set read back from disk after it
# ran, as the first version of this step read /tmp/implicated.txt, held only
# while the attempt step's scoping does.
_vimpenv="$(awk '/- name: Verify and push/ { f = 1 } f && /^ *IMPLICATED: / { sub(/^ *IMPLICATED: /, ""); print; exit }' "$UT")"
is  "the verify step takes the implicated set from the scope step's output, and reads no file for it" \
    "$_vimpenv, $(grep -c '/tmp/' "$VP/step.sh" | tr -d ' ') /tmp reads" \
    "\${{ steps.scope.outputs.implicated }}, 0 /tmp reads"
# And the report reads the refusal under the name the step writes it.
_vpunwritten=""
for _k in $(grep -o 'steps\.push\.outputs\.[a-z_]*' "$UT" | sed 's/.*\.//' | sort -u); do
  grep -q "echo \"$_k=" "$VP/step.sh" || _vpunwritten="$_vpunwritten $_k"
done
is  "every steps.push output the template reads is one the verify step writes" "${_vpunwritten:-none}" "none"
# R41 (b): the stand-in mktemp was reached by the step, and every path it logged is under $TMP
_mkx="$(LC_ALL=C awk -v p="$TMP/" '{ t++; if (index($0, p) != 1) { o++; if (o <= 3) b = b " [" $0 "]" } } END { if (t == 0) print "no path logged"; else if (o) print o " of " t " outside:" b; else print "ok" }' "$VP/mktemp.log" 2>/dev/null)"
is "R41: every path the mktemp stand-in logged for the verify step's runs is under \$TMP, and it logged some" "${_mkx:-no log}" ok
if [ "$_vrisk_had" = 1 ]; then cp "$VP/risk.keep" "$FROOT/projects/widget/risk.tsv"; else rm -f "$FROOT/projects/widget/risk.tsv"; fi

# The job that runs the gate again, read out of the template: what it waits
# for, what its token may do, and what it asks GitHub for. It holds actions:
# write, which dispatching a workflow needs, and nothing else; the job with the
# model and the push holds none of it.
_ujob() { awk -v j="  $1:" '$0 == j { f = 1; next } f && (/^  [^ ]/ || /^[^ ]/) { exit } f' "$UT"; }
_rg="$(_ujob regate)"
_rgperm="$(printf '%s\n' "$_rg" | awk '/^    permissions:/ { p = 1; next }
  p && /^      [a-z-]+:/ { gsub(/ /, ""); printf "%s ", $0; next } p { exit }')"
is  "a job runs the gate again only after the repair job pushed" \
    "$(printf '%s\n' "$_rg" | sed -n 's/^    needs: //p; s/^    if: //p' | tr '\n' ';')" \
    "repair;needs.repair.outputs.pushed == 'yes';"
is  "and its token may dispatch workflows and do nothing else" "$_rgperm" "actions:write "
_rtop="$(awk '/^permissions:/ { p = 1; next } p && /^  [a-z-]+:/ { gsub(/ /, ""); printf "%s ", $0; next } p { exit }' "$UT")"
case "$_rtop $(_ujob repair | grep -c 'permissions:')" in
  *actions*|*" "[1-9]*) bad "and the job that runs the model holds no actions permission" "workflow: $_rtop" ;;
  *) ok "and the job that runs the model holds no actions permission" ;;
esac
# The output it waits on is one the repair job hands on from the step that
# pushed, and that step writes it. An output never written reads as empty, and
# the gate would never run again.
_rpid="$(awk '/- name: Verify and push/ { f = 1; next } f && /^        id: / { print $2; exit } f && /^      - / { exit }' "$UT")"
_rpout="$(_ujob repair | sed -n 's/^      pushed: //p')"
[ -n "$_rpid" ] && [ "$_rpout" = "\${{ steps.$_rpid.outputs.pushed }}" ] \
  && grep -q 'echo "pushed=yes" >> "$GITHUB_OUTPUT"' "$VP/step.sh" \
  && ok  "and that output is handed on from the step that pushed, which writes it" \
  || bad "and that output is handed on from the step that pushed, which writes it" \
         "push step id [$_rpid], job output [$_rpout]"
has "and it dispatches the workflow whose failure started the repair" "$_rg" \
    "GATE: \${{ github.event.workflow_run.workflow_id || 'gate' }}"
is  "and on the branch the repair pushed to" \
    "$(printf '%s\n' "$_rg" | sed -n 's/^ *BRANCH: //p')" \
    "$(awk '/- name: Verify and push/ { f = 1 } f && /^ *BRANCH: / { sub(/^ *BRANCH: /, ""); print; exit }' "$UT")"

awk '/- name: Run the gate on the pushed commit/ { f = 1 } f && /^        run: \|/ { r = 1; next }
     r && /^      [^ ]/ { exit } r { sub(/^          /, ""); print }' "$UT" > "$VP/regate.sh"
cat > "$VP/bin/gh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$REGATE_LOG"
[ -z "${REGATE_FAILS:-}" ] && exit 0
printf "could not create workflow dispatch event: HTTP 422: Workflow does not have 'workflow_dispatch' trigger\n" >&2
exit 1
STUB
chmod +x "$VP/bin/gh"
_regate() { : > "$VP/gh.log"
  ( cd "$VP" && REGATE_FAILS="$1" REGATE_LOG="$VP/gh.log" GATE=4242 BRANCH=fix/x \
      GITHUB_REPOSITORY=example/widget GH_TOKEN=t PATH="$VP/bin:$PATH" bash -e "$VP/regate.sh" ) \
    > "$VP/regate.out" 2>&1; }
_regate ""; _rgrc=$?
is  "the gate is dispatched on the pushed branch" "exit $_rgrc: $(cat "$VP/gh.log")" \
    "exit 0: workflow run 4242 --repo example/widget --ref fix/x"
_regate 1; _rgrc=$?
[ "$_rgrc" -ne 0 ] && ok  "a gate that cannot be dispatched fails the job" \
                   || bad "a gate that cannot be dispatched fails the job" "exit 0: $(cat "$VP/regate.out")"
has "and says the pushed commit has no gate verdict" "$(cat "$VP/regate.out")" "no gate verdict"
has "and passes on GitHub's own reason" "$(cat "$VP/regate.out")" "HTTP 422"

# The gate workflow bootstrap writes has to accept the dispatch, or every
# repository bootstrapped from it fails the job above on its first push.
has "the gate workflow bootstrap writes can be dispatched" \
    "$( . "$REAL_HARNESS/lib/detect.sh"; . "$REAL_HARNESS/lib/bootstrap.sh"
        felix_bs_render_workflow none someone/repo )" "  workflow_dispatch:"

# Each push leaves a gate run on the pull request that waits for a person's
# approval, so on github.com the branch reads, newest first: the dispatched
# run, the waiting one, the run before. The count stopped at the waiting run,
# so however many repairs failed it read as the failures since the last push,
# and the ceiling never came.
if command -v jq >/dev/null 2>&1; then
  { printf 'gate.yml\tgate\tfix/z\t405\tcompleted\tfailure\n'
    printf 'gate.yml\tgate\tfix/z\t404\tcompleted\taction_required\n'
    printf 'gate.yml\tgate\tfix/z\t403\tcompleted\tfailure\n'
    printf 'gate.yml\tgate\tfix/z\t402\tcompleted\taction_required\n'
    printf 'gate.yml\tgate\tfix/z\t401\tcompleted\tfailure\n'
    printf 'gate.yml\tgate\tfix/z\t400\tcompleted\tsuccess\n'
  } > "$VP/runs"
  is "a gate run waiting for approval does not end the count of failures behind it" \
     "$( export WFSTUB_LOG="$VP/wf.log" WFSTUB_RUNS="$VP/runs" WFSTUB_WORKFLOWS=gate.yml
         _wfatt fix/z gate.yml )" "3"
else
  skip "a gate run waiting for approval does not end the count of failures behind it" \
       "no jq here to evaluate gh's -q expressions"
fi

