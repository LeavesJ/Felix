printf '\nunattended readiness\n'
# #87. Two of the five readiness rows were printf constants. This is the report
# a person reads when deciding whether to switch on a loop that invokes a model
# unattended, and `felix unattended` says outright that Felix will not flip that
# switch for them - so the rows have to be true.
#
# `scope bound` was fully literal, mark and text both, so it stayed checked for a
# project that declares no red path at all - i.e. exactly when nothing is out of
# scope and the bound it names does not exist.
#
# `budget ceiling` is a subtler case and the fix is different. Its [x] was not
# wrong about what it said - a ceiling IS configured, and felix_budget_limit can
# never return "none" - but readiness means the bound HOLDS, and in CI it does
# not: the ledger lives in a checkout made fresh every run (#84). Felix cannot
# determine that mechanically, so the honest mark is neither [x] nor [ ].
UNB="$TMP/unattgh"; mkdir -p "$UNB"
# `gh api` answers the way the server does for what the drift rows below ask:
# the workflow list from UNSTUB_WORKFLOWS through jq for the -q expression, a
# file under UNSTUB_FILES as its raw contents or gh's own 404, and no answer at
# all for an endpoint containing UNSTUB_UNANSWERED.
cat > "$UNB/gh" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
  "variable list") ;;
  "secret list")   printf 'ANTHROPIC_API_KEY\n' ;;
  "run list")      printf '0\n' ;;
  "api "*)
    ep=""; q="."; prev=""
    for a in "$@"; do
      case "$prev" in -q|--jq) q="$a" ;; esac
      case "$a" in repos/*) ep="$a" ;; esac
      prev="$a"
    done
    if [ -n "${UNSTUB_UNANSWERED:-}" ]; then
      case "$ep" in *"$UNSTUB_UNANSWERED"*) printf 'error connecting to api.github.com\n' >&2; exit 1 ;; esac
    fi
    case "$ep" in
      */actions/workflows) printf '%s\n' "${UNSTUB_WORKFLOWS:-}" | jq -r "$q" ;;
      */contents/*)
        f="${UNSTUB_FILES:-/nonexistent}/${ep#*/contents/}"
        [ -f "$f" ] || { printf 'gh: Not Found (HTTP 404)\n' >&2; exit 1; }
        cat "$f" ;;
    esac ;;
esac
exit 0
STUB
chmod +x "$UNB/gh"
# The fixture has no origin at this point and cmd_unattended dies without one -
# which made two of these assertions pass on the error text rather than on the
# behaviour. Added here and removed at the end of the block.
( _fx_cd "$REPO" && git remote add origin https://github.com/example/widget.git ) 2>/dev/null
_unatt() { ( cd "$REPO" && PATH="$UNB:$PATH" "$FELIX" unattended 2>&1 ); }
# Asserted, not assumed: if the command still cannot run, everything below is
# testing an error message.
has "the readiness report runs at all" "$(_unatt)" "repo:"

cp "$FROOT/projects/widget/risk.tsv" "$TMP/risk.unatt.keep" 2>/dev/null || : > "$TMP/risk.unatt.keep"

# A table that declares red paths: the bound exists and the row may say so.
{ printf '# tier\tkind\tpattern\treason\n'
  printf 'red\tpath\t^secrets/\tsecret material\n'
} > "$FROOT/projects/widget/risk.tsv"
# The ROW, not the whole report. A glob like *"[x]"*"scope bound"* matches
# because `[x] api key` appears earlier in the output, so it was true whatever
# the scope row said.
_row() { printf '%s\n' "$1" | grep -F "$2" | head -1; }
out="$(_unatt)"
has "a project with red paths reports the scope bound" "$(_row "$out" 'scope bound')" "[x]"

# A table with no red path at all: nothing is refused, so nothing is bound.
{ printf '# tier\tkind\tpattern\treason\n'
  printf 'green\tpath\t^docs/\tprose\n'
} > "$FROOT/projects/widget/risk.tsv"
out="$(_unatt)"
case "$(_row "$out" 'scope bound')" in
  *"[x]"*) bad "and a project with none does not claim it" "$(_row "$out" 'scope bound')" ;;
  *)       ok  "and a project with none does not claim it" ;;
esac
has "saying what is missing" "$out" "no red rule"

# Content rules bound scope exactly as path rules do (#100) — felix scope
# classifies the whole diff and refuses on either kind. Counting paths alone
# told a project whose red tier is all content rules — secrets, destructive
# SQL, the material the red tier exists for — that nothing was out of scope,
# on the checklist read before switching on unattended model runs. another governed project
# declares 2 red content rules today.
{ printf '# tier\tkind\tpattern\treason\n'
  printf 'red\tcontent\tDROP[[:space:]]+TABLE\tdestructive sql\n'
} > "$FROOT/projects/widget/risk.tsv"
out="$(_unatt)"
has "a project bounded only by content rules reports the bound" \
    "$(_row "$out" 'scope bound')" "[x]"

# The budget row must not read as a satisfied precondition, because whether the
# ceiling survives where the loop runs is not something this can check.
case "$(_row "$out" 'budget ceiling')" in
  *"[x]"*) bad "the budget row is not reported as satisfied" "$(_row "$out" 'budget ceiling')" ;;
  *)       ok  "the budget row is not reported as satisfied" ;;
esac
has "and is marked unknown rather than unmet" "$(_row "$out" 'budget ceiling')" "[?]"
# And it reads the ledger rather than only the configured number, so the row
# says what has been spent and not merely what was declared.
has "and reports what has been spent" "$out" "spent"

# Deployed copies drift in silence. A person copies templates/unattended.yml
# into a repository once, and the engine it checks out moves on without it.
# another governed project's copy did exactly that, measured 2026-09-23: its scope step still
# proceeded on every exit of felix repair but 3, a behaviour #323 and #329
# had fixed in the template, while nothing here could say so. The repair's
# push also starts no ordinary run of the gate, since GitHub creates none
# from an event the workflow token causes except a dispatch, so whether the
# gate workflow takes workflow_dispatch is a fact about the loop too. Both
# rows read the repository's default branch, where a workflow_run trigger
# and a dispatch are both taken from.
if ! command -v jq >/dev/null 2>&1; then
  for a in "a gate workflow that takes workflow_dispatch is reported as taking one" \
           "and one that does not is reported unmet" \
           "an on: line naming workflow_dispatch counts as taking one" \
           "workflow_dispatch named only in an if: expression does not" \
           "a gate workflow that cannot be read is unknown, not unmet" \
           "a deployed copy that is the template with its placeholders filled matches it" \
           "and still matches with its comments changed" \
           "a copy whose scope step drifted is unmet" \
           "and the row names the line it drifted at" \
           "a copy with no Felix pin does not match" \
           "a copy with a placeholder left unfilled does not match" \
           "a repository with no unattended workflow says so" \
           "a workflow list that cannot be read is unknown, not unmet"; do
    skip "$a" "no jq here to evaluate gh's -q expressions"
  done
else
UNF="$TMP/unattfiles"; mkdir -p "$UNF/.github/workflows"
export UNSTUB_FILES="$UNF" \
       UNSTUB_WORKFLOWS='{"workflows":[{"name":"gate","path":".github/workflows/gate.yml","state":"active"},{"name":"unattended repair","path":".github/workflows/unattended.yml","state":"active"}]}'
_tpl="$FROOT/harness/templates/unattended.yml"
_fill() { sed -e 's#{{FELIX_REPO}}#example/felix-home#' \
              -e 's#{{FELIX_REF}}#0123456789abcdef0123456789abcdef01234567#' "$_tpl"; }
_dr() { _row "$(_unatt)" 'gate takes a dispatch'; }
_tr() { _row "$(_unatt)" 'workflow matches template'; }

printf 'on:\n  pull_request:\n  push:\n    branches: [main]\n  workflow_dispatch:\njobs: {}\n' \
  > "$UNF/.github/workflows/gate.yml"
has "a gate workflow that takes workflow_dispatch is reported as taking one" "$(_dr)" "[x]"
printf 'on:\n  pull_request:\n  push:\n    branches: [main]\njobs: {}\n' \
  > "$UNF/.github/workflows/gate.yml"
has "and one that does not is reported unmet" "$(_dr)" "[ ]"
printf 'on: [pull_request, workflow_dispatch]\njobs: {}\n' > "$UNF/.github/workflows/gate.yml"
has "an on: line naming workflow_dispatch counts as taking one" "$(_dr)" "[x]"
printf "on:\n  pull_request:\njobs:\n  gate:\n    if: github.event_name != 'workflow_dispatch'\n" \
  > "$UNF/.github/workflows/gate.yml"
has "workflow_dispatch named only in an if: expression does not" "$(_dr)" "[ ]"
rm -f "$UNF/.github/workflows/gate.yml"
has "a gate workflow that cannot be read is unknown, not unmet" "$(_dr)" "[?]"

_fill > "$UNF/.github/workflows/unattended.yml"
has "a deployed copy that is the template with its placeholders filled matches it" "$(_tr)" "[x]"
# The comment a local copy keeps about its own Felix, and one of the template's
# own comments gone: neither changes what the workflow does.
_fill | sed -e '/^      # Pinned, to the full sha/i\
      # felix-home, not felix: see the Felix checkout in gate.yml.' \
            -e '/^# Wired, and off\./d' > "$UNF/.github/workflows/unattended.yml"
has "and still matches with its comments changed" "$(_tr)" "[x]"
# another governed project's shape on 2026-09-23: the scope step before #323.
_fill | sed 's#if \[ "\$rc" = "0" \]; then#if [ "$rc" != "3" ]; then#' \
  > "$UNF/.github/workflows/unattended.yml"
_ln="$(grep -n 'if \[ "$rc" != "3" \]' "$UNF/.github/workflows/unattended.yml" | cut -d: -f1)"
out="$(_tr)"
has "a copy whose scope step drifted is unmet" "$out" "[ ]"
has "and the row names the line it drifted at" "$out" "line ${_ln:-?}"
_fill | grep -v "ref: '0123456789abcdef" > "$UNF/.github/workflows/unattended.yml"
has "a copy with no Felix pin does not match" "$(_tr)" "[ ]"
cp "$_tpl" "$UNF/.github/workflows/unattended.yml"
has "a copy with a placeholder left unfilled does not match" "$(_tr)" "[ ]"
_fill > "$UNF/.github/workflows/unattended.yml"
out="$(UNSTUB_WORKFLOWS='{"workflows":[{"name":"gate","path":".github/workflows/gate.yml","state":"active"}]}' _unatt)"
has "a repository with no unattended workflow says so" \
    "$(_row "$out" 'workflow matches template')" "no workflow named"
has "a workflow list that cannot be read is unknown, not unmet" \
    "$(UNSTUB_UNANSWERED=actions/workflows _tr)" "[?]"
unset UNSTUB_FILES UNSTUB_WORKFLOWS
fi

cp "$TMP/risk.unatt.keep" "$FROOT/projects/widget/risk.tsv"
( _fx_cd "$REPO" && git remote remove origin ) 2>/dev/null

printf '\ngenerated CI points at a path that exists\n'
# Moving the engine broke every generated workflow at once, in other
# repositories, where this suite never looks. Felix's own gate stayed green
# because it tests Felix. The caller lived elsewhere.
#
# So the generator's output is checked against the filesystem: whatever path it
# tells CI to run must actually resolve inside the engine.
gen="$( . "$FROOT/engine/harness/lib/detect.sh" 2>/dev/null || . "$FROOT/harness/lib/detect.sh"
        . "$FROOT/engine/harness/lib/bootstrap.sh" 2>/dev/null || . "$FROOT/harness/lib/bootstrap.sh"
        felix_bs_render_workflow node someone/repo )"
has "the workflow invokes felix" "$gen" "harness/felix"
felix_path="$(printf '%s' "$gen" | grep -oE '\.\./felix/[a-z/]*harness/felix' | head -1)"
resolved="${felix_path#../felix/}"
# Checked against the real checkout, not the fixture. A generated workflow runs
# against a clone of the actual repository, so that is the layout that has to be
# right, and the fixture flattens the engine in a way no clone does.
REAL_ROOT="$(cd "$REAL_HARNESS/../.." && pwd)"
if [ -x "$REAL_ROOT/$resolved" ]; then
  ok "and that path resolves in a real checkout"
else
  bad "and that path resolves in a real checkout" "generated $resolved, absent from $REAL_ROOT"
fi

printf '\ngenerated CI drops the credentials its checkouts fetched with\n'
# actions/checkout keeps what it fetched with unless told otherwise: the job
# token in repo/.git/config, and the Felix deploy key in a file felix/.git/config
# names. The gate then runs the pull request's own test code in that same job,
# which can read either, and nothing after the fetch needs them.
#
# So every checkout step is found in the rendered text and its own with: block
# is read. A key in a comment, in another step or in the header is not that
# step's input, and a render with no checkout step at all fails, not passes.
_wf_render() { ( . "$FROOT/engine/harness/lib/detect.sh" 2>/dev/null || . "$FROOT/harness/lib/detect.sh"
                 . "$FROOT/engine/harness/lib/bootstrap.sh" 2>/dev/null || . "$FROOT/harness/lib/bootstrap.sh"
                 felix_bs_render_workflow "$1" someone/repo ); }
# One row per actions/checkout step, whatever its version: ordinal, whether its
# with: sets persist-credentials to false, whether its with: holds ssh-key, and
# its path. Comment lines and block-scalar bodies (a run: | script) are skipped.
_wf_checkouts() { awk -v q="'" '
  function unq(v) { return (v ~ /^".*"$/ || (length(v) > 1 && substr(v, 1, 1) == q && substr(v, length(v)) == q)) ? substr(v, 2, length(v) - 2) : v }
  function flush() { if (ck) printf "%d\t%d\t%d\t%s\n", ++n, pc, ssh, (p == "" ? "-" : p); ck = 0 }
  BEGIN { bs = st = sd = -1 }
  /^[ \t]*#/ || /^[ \t]*$/ { next }
  {
    match($0, /^ */); ind = RLENGTH; body = substr($0, ind + 1)
    if (bs >= 0) { if (ind > bs) next; bs = -1 }
    sub(/[ \t]+#.*$/, "", body)
    item = 0; dash = ind
    if (body == "-" || substr(body, 1, 2) == "- ") {
      item = 1; body = substr(body, 2); match(body, /^ */); ind += 1 + RLENGTH; body = substr(body, RLENGTH + 1)
    }
    key = body; val = ""
    if (match(body, /^[^:]+:/) && (substr(body, RLENGTH + 1, 1) == "" || substr(body, RLENGTH + 1, 1) == " ")) {
      key = substr(body, 1, RLENGTH - 1); val = substr(body, RLENGTH + 1); sub(/^ +/, "", val); val = unq(val)
    }
    lead = item ? dash : ind
    if (st >= 0) {
      if (item && (sd < 0 ? (dash >= st) : (dash == sd))) { flush(); sd = dash; ki = ind; instep = 1; pc = ssh = 0; p = ""; wi = wc = -1 }
      else if (sd >= 0 ? (lead <= sd) : (lead <= st)) { flush(); st = sd = -1; instep = 0 }
    }
    if (instep && ind == ki) {
      if (key == "uses") ck = (val == "actions/checkout" || val ~ /^actions\/checkout@/)
      wi = (key == "with" && val == "") ? ind : -1; wc = -1
    } else if (instep && wi >= 0 && ind > wi) {
      if (wc < 0) wc = ind
      if (ind == wc && key == "persist-credentials" && val == "false") pc = 1
      if (ind == wc && key == "ssh-key" && val != "") ssh = 1
      if (ind == wc && key == "path") p = val
    }
    if (key == "steps" && val == "") { flush(); st = ind; sd = -1; instep = 0 }
    if (val ~ /^[|>][-+0-9]*$/) bs = ind
  }
  END { flush() }'; }
_wf_all=""; _wf_felix=""; _wf_repo=""
for _wf_eco in node python rust go nosuch; do
  _wf_rows="$(_wf_render "$_wf_eco" | _wf_checkouts)"
  [ -n "$_wf_rows" ] || _wf_all="$_wf_all, $_wf_eco renders no checkout step"
  _wf_hasf=0; _wf_hasr=0
  while IFS=$'\t' read -r _wf_n _wf_pc _wf_ssh _wf_path; do
    [ -n "$_wf_n" ] || continue
    _wf_at="$_wf_eco checkout $_wf_n (path: $_wf_path)"
    [ "$_wf_pc" = 1 ] || _wf_all="$_wf_all, $_wf_at keeps its credential"
    if [ "$_wf_ssh" = 1 ]; then
      _wf_hasf=1; [ "$_wf_pc" = 1 ] || _wf_felix="$_wf_felix, $_wf_at keeps the deploy key"
    fi
    if [ "$_wf_path" = repo ]; then
      _wf_hasr=1; [ "$_wf_pc" = 1 ] || _wf_repo="$_wf_repo, $_wf_at keeps the job token"
    fi
  done <<< "$_wf_rows"
  [ "$_wf_hasf" = 1 ] || _wf_felix="$_wf_felix, $_wf_eco renders no checkout with ssh-key"
  [ "$_wf_hasr" = 1 ] || _wf_repo="$_wf_repo, $_wf_eco renders no checkout at path: repo"
done
if [ -z "$_wf_all" ]; then ok "every checkout step in the generated workflow sets persist-credentials: false in its own with"
else bad "every checkout step in the generated workflow sets persist-credentials: false in its own with" "${_wf_all#, }"; fi
if [ -z "$_wf_felix" ]; then ok "and the Felix checkout, which holds the deploy key, drops it"
else bad "and the Felix checkout, which holds the deploy key, drops it" "${_wf_felix#, }"; fi
if [ -z "$_wf_repo" ]; then ok "and the project's own checkout drops the job token"
else bad "and the project's own checkout drops the job token" "${_wf_repo#, }"; fi

printf '\ngenerated CI grades against a pinned Felix\n'
# With no ref the Felix checkout took the default branch at the moment the job
# ran, so the verdict on one commit depended on when it was graded, and a merge
# in Felix nobody in the governed repository reviewed redefined its green. The
# line after repository: is read, not the whole output: the comment above the
# step names the placeholder too, so matching the output passed with the ref
# line deleted.
_pinwf() { ( . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/bootstrap.sh"
             felix_bs_render_workflow node someone/repo "$@" ) \
           | grep -A1 'repository: someone/repo' | sed -n 2p | tr -d ' '; }
_PINSHA="0123456789abcdef0123456789abcdef01234567"
is  "the generated workflow checks Felix out at the commit it was given" \
    "$(_pinwf "$_PINSHA")" "ref:'$_PINSHA'"
# Quoted, and the quotes are the assertion. Unquoted, YAML reads {{FELIX_REF}}
# as a mapping and GitHub refuses the whole file, so a required check that
# never reports stood where a failing checkout was meant to.
is  "and with no commit to give, at the placeholder, quoted so YAML reads a string" \
    "$(_pinwf)" "ref:'{{FELIX_REF}}'"
# Pinned to a commit, a checkout names its release only in the comment after
# the sha, so that is what is read. The comment is a claim a reviewer checks
# against the sha when the pin moves; nothing offline can.
is  "every checkout in the generated workflow is v5, the lowest major on Node 24" \
    "$(printf '%s\n' "$gen" | grep -c -E 'actions/checkout@[0-9a-f]{40} # v5\.')/$(printf '%s\n' "$gen" | grep -c 'actions/checkout@')" "2/2"

# The commit bootstrap pins is the engine source's HEAD, and only when origin's
# default branch holds it. Any remote branch would do for the checkout to
# succeed, which is why a pushed branch nobody merged is the case that matters:
# it fetches, and grades with an engine nobody reviewed.
_PS="$TMP/pinsrc"; _PC="$TMP/pinclone"
( git init -q -b main "$_PS" && _fx_cd "$_PS" \
  && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m one \
  && git checkout -q -b side && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m side \
  && git checkout -q main && git clone -q "$_PS" "$_PC" ) >/dev/null 2>&1
_pinref() { ( . "$FROOT/harness/lib/bootstrap.sh"; felix_bs_pin_ref "$1" || printf 'NONE' ); }
is  "a source whose HEAD is origin's default branch pins that commit, in full" \
    "$(_pinref "$_PC")" "$(git -C "$_PS" rev-parse main)"
( _fx_cd "$_PC" && git checkout -q --detach origin/side ) >/dev/null 2>&1
is  "a HEAD on a pushed branch the default branch does not hold pins nothing" \
    "$(_pinref "$_PC")" "NONE"
( _fx_cd "$_PC" && git checkout -q main \
  && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m local ) >/dev/null 2>&1
is  "a HEAD only this machine holds pins nothing" "$(_pinref "$_PC")" "NONE"
# A clone made some other way may carry no origin/HEAD, and origin/main is
# still the default branch's name here.
( _fx_cd "$_PC" && git reset -q --hard origin/main && git remote set-head origin -d ) >/dev/null 2>&1
is  "and with no origin/HEAD, origin/main is the branch asked" \
    "$(_pinref "$_PC")" "$(git -C "$_PS" rev-parse main)"
# Bounded, because a $TMP under a directory that is itself a repository would
# otherwise answer for it.
mkdir -p "$TMP/pinnone"
is  "a source that is not a checkout pins nothing" \
    "$(GIT_CEILING_DIRECTORIES="$TMP" _pinref "$TMP/pinnone")" "NONE"

# origin/HEAD first. Every fixture above has a default branch named main, where
# the order cannot show; here it is trunk, and a main beside it holds a commit
# the default branch does not.
_PT="$TMP/pintrunk"; _PTC="$TMP/pintrunkclone"
( git init -q -b trunk "$_PT" && _fx_cd "$_PT" \
  && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m one \
  && git checkout -q -b main && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m two \
  && git checkout -q trunk && git clone -q "$_PT" "$_PTC" \
  && _fx_cd "$_PTC" && git checkout -q --detach origin/main ) >/dev/null 2>&1
is  "a HEAD only a branch named main holds, when the default branch is another, pins nothing" \
    "$(_pinref "$_PTC")" "NONE"

# The project, when asked about. CI resolves the project from the Felix it
# checked out, so a commit from before the project merged cannot govern it.
_pinproj() { ( . "$FROOT/harness/lib/bootstrap.sh"; felix_bs_pin_ref "$1" "$2" || printf 'NONE' ); }
( _fx_cd "$_PS" && mkdir -p projects/w && printf '{}\n' > projects/w/project.json && git add projects \
  && git -c user.name=t -c user.email=t@t commit -q -m project \
  && _fx_cd "$_PC" && git fetch -q origin && git checkout -q --detach origin/main ) >/dev/null 2>&1
is  "a commit holding the project it is asked about pins" \
    "$(_pinproj "$_PC" projects/w)" "$(git -C "$_PS" rev-parse main)"
( _fx_cd "$_PC" && git checkout -q --detach origin/main~1 ) >/dev/null 2>&1
is  "a commit on the default branch from before the project merged pins nothing" \
    "$(_pinproj "$_PC" projects/w)" "NONE"

printf '\ngenerated CI runs the action code its pins name, and no other\n'
# A tag is a ref its owner can move, so `actions/checkout@v5` runs whatever
# that repository points v5 at on the day the job runs, and one of those
# checkouts fetches Felix with FELIX_DEPLOY_KEY. Felix itself is checked out
# at a commit so the verdict is a function of the commit; an action on a tag
# is the same hole one line up. semgrep's github-actions-mutable-action-tag
# (1.175, p/github-actions) flags it. The unattended template is held to the
# same rule above, by the same reader of uses: keys.
#
# For every stack the workflow can be rendered for, and the stacks are read
# from bootstrap rather than listed here: each arm of the setup-step case, and
# each stack detection can report, which is how `none` reaches the fall-through
# arm. A stack added to either is held to the pin without this section being
# edited. No stack found, or a render with no uses: line, fails: a read that
# matched nothing would pass every file.
_gpstacks="$( . "$FROOT/harness/lib/bootstrap.sh"
              { declare -f _felix_bs_setup_block | awk '/^[ \t]*[A-Za-z0-9_| \t-]+\)$/ {
                  v = $0; gsub(/[ \t]/, "", v); sub(/\)$/, "", v); n = split(v, a, "|")
                  for (i = 1; i <= n; i++) if (a[i] != "") print a[i] }'
                declare -f felix_guess_ecosystem | awk '/^[ \t]*echo [A-Za-z0-9_-]+;?$/ {
                  v = $0; sub(/^[ \t]*echo /, "", v); sub(/;$/, "", v); print v }'
              } | LC_ALL=C sort -u )"
_gploose=""
[ -n "$_gpstacks" ] || _gploose=", no stack read from bootstrap"
for _gpst in $_gpstacks; do
  _gpuses="$( ( . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/bootstrap.sh"
                felix_bs_render_workflow "$_gpst" someone/repo ) \
              | awk '/^[ \t]*#/ { next }
                     /^[ \t]*(-[ \t]+)?uses:/ { v = $0
                       sub(/^[ \t]*(-[ \t]+)?uses:[ \t]*/, "", v); sub(/[ \t]+#.*$/, "", v)
                       print NR ": " v }' | tr -d "\"'")"
  if [ -z "$_gpuses" ]; then _gploose="$_gploose, $_gpst: no uses: line found"; continue; fi
  _gpbad="$(printf '%s\n' "$_gpuses" | grep -v -E '^[0-9]+: [^@[:space:]]+@[0-9a-f]{40}$')"
  [ -z "$_gpbad" ] || _gploose="$_gploose, $_gpst: $(printf '%s' "$_gpbad" | tr '\n' ';')"
done
if [ -z "$_gploose" ]; then
  ok  "every uses: in the gate workflow bootstrap renders names a full commit sha, for every stack it can render"
else
  bad "every uses: in the gate workflow bootstrap renders names a full commit sha, for every stack it can render" \
      "${_gploose#, }"
fi
# A sha fixes the code an action runs, and its action.yml fixes what runs it:
# setup-node v4.4.0, setup-python v5.6.0 and setup-go v5.6.0 were pinned in
# full and ran on Node 20 while the comment above the checkouts said the file
# had moved to Node 24. The runtime is not in the sha and cannot be read
# offline, so each commit a workflow Felix writes may name is listed here with
# the release that named it and the `using:` its action.yml held, read with gh
# api repos/OWNER/NAME/contents/action.yml?ref=SHA on 2026-10-08. A pin moved
# to a commit missing from the list fails until that read is recorded; a
# recorded runtime other than node24 or composite fails; a comment naming
# another release than the list fails. Every stack the gate workflow renders
# for is read, as above, and the unattended template beside them. A uses: key
# in a shape the reader does not parse, `uses :` or a flow mapping, fails
# rather than being skipped, and so does a render or reader that exits non-zero:
# a reader that never ran prints nothing, which is what a clean file prints.
_gprtrows='actions/checkout fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09 v5.1.0 node24
actions/setup-node a0853c24544627f65ddf259abe73b1d18a591444 v5.0.0 node24
actions/setup-python ece7cb06caefa5fff74198d8649806c4678c61a1 v6.3.0 node24
actions/setup-go 924ae3a1cded613372ab5595356fb5720e22ba16 v6.5.0 node24
dtolnay/rust-toolchain 7e38f4b43b4db5c8dd498af069a4f6196df1d067 v1 composite'
_gprt() { tr -d "\"'\r" | _GPRT="$_gprtrows" awk '
  BEGIN { n = split(ENVIRON["_GPRT"], r, "\n")
          for (i = 1; i <= n; i++) if (split(r[i], f, " ") == 4) { k = f[1] "@" f[2]; rel[k] = f[3]; rt[k] = f[4] } }
  /^[ \t]*#/ { next }
  !/^[ \t]*(-[ \t]+)?uses:/ && /(^|[^A-Za-z0-9_.-])uses[ \t]*:/ { seen++
    print NR ": a uses: key in a shape this reader does not parse"; next }
  /^[ \t]*(-[ \t]+)?uses:/ { v = $0; c = ""; seen++
    sub(/^[ \t]*(-[ \t]+)?uses:[ \t]*/, "", v)
    if (match(v, /[ \t]+#[ \t]*/)) { c = substr(v, RSTART + RLENGTH); v = substr(v, 1, RSTART - 1) }
    sub(/[ \t]+$/, "", v); sub(/[ \t]+$/, "", c)
    if (!(v in rt)) print NR ": " v " has no runtime read for it"
    else if (rt[v] != "node24" && rt[v] != "composite") print NR ": " v " runs on " rt[v]
    else if (c != rel[v]) print NR ": " v " says " (c == "" ? "no release" : c) ", read as " rel[v] }
  END { if (!seen) print "no uses: line found" }'; }
_gprtloose=""; _gprterr=""
[ -n "$_gpstacks" ] || _gprtloose=", no stack read from bootstrap"
for _gpst in $_gpstacks; do
  _gprtout="$( ( . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/bootstrap.sh"
                 felix_bs_render_workflow "$_gpst" someone/repo ) 2>"$TMP/gprt.err" | _gprt )"
  _gprtrc=$?; [ "$_gprtrc" -eq 0 ] || _gprtout="${_gprtout:+$_gprtout
}the render or its reader exited $_gprtrc"
  [ -z "$_gprtout" ] || _gprtloose="$_gprtloose, $_gpst: $(printf '%s' "$_gprtout" | tr '\n' ';')"
  [ ! -s "$TMP/gprt.err" ] || _gprterr="$_gprterr, $_gpst: $(head -1 "$TMP/gprt.err")"
done
_gprtout="$(_gprt < "$REAL_HARNESS/templates/unattended.yml")"
_gprtrc=$?; [ "$_gprtrc" -eq 0 ] || _gprtout="${_gprtout:+$_gprtout
}the reader exited $_gprtrc"
[ -z "$_gprtout" ] || _gprtloose="$_gprtloose, unattended.yml: $(printf '%s' "$_gprtout" | tr '\n' ';')"
if [ -z "$_gprtloose" ]; then
  ok  "and each of those, and each in the unattended template, is a commit read as running on Node 24 or composite, under the release its comment names"
else
  bad "and each of those, and each in the unattended template, is a commit read as running on Node 24 or composite, under the release its comment names" \
      "${_gprtloose#, }"
fi
# The workflow is an unquoted heredoc, so a backquote or a $ in it expands when
# it renders, and the adopting repository gets whatever that printed in place
# of the text. One that fails says so on stderr, which the first assertion
# reads. One that succeeds says nothing: `pwd` or $HOME in a comment renders a
# path into the file. So the heredoc's source is read too: every $ and
# backquote in it is escaped, or is one of the three expansions it means, the
# repository, the ref and the setup step. The setup step's printf formats hold
# no % to fill, since they are given no arguments.
is  "and rendering it for any stack writes nothing to stderr" "${_gprterr#, }" ""
_gpxp="$(awk '
  function strip(s, t,   i) { while ((i = index(s, t)) > 0) s = substr(s, 1, i - 1) substr(s, i + length(t)); return s }
  /^felix_bs_render_workflow\(\)/ { f = 1 }
  f && /cat <<YAML$/ { b = 1; next }
  b && /^YAML$/ { b = 0; f = 0; wdone = 1; next }
  b { n++; v = strip(strip($0, "\\$"), "\\`")
      v = strip(strip(strip(v, "${felix_repo}"), "${felix_ref}"), "$(_felix_bs_setup_block \"$eco\")")
      if (index(v, "$") || index(v, "`")) print NR ": " $0 }
  /^_felix_bs_setup_block\(\)/ { s = 1 }
  s && /^}/ { s = 0; sdone = 1 }
  s && index($0, "%") { print NR ": " $0 }
  END { if (!wdone || !n) print "no workflow heredoc found"; if (!sdone) print "no setup block found" }' \
  "$FROOT/harness/lib/bootstrap.sh")"
_gpxprc=$?; [ "$_gpxprc" -eq 0 ] || _gpxp="${_gpxp:+$_gpxp
}the reader exited $_gpxprc"
is  "and the workflow's text expands only the repository, the ref and the setup step, which expands nothing" \
    "$(printf '%s' "$_gpxp" | tr '\n' ';')" ""
# dtolnay/rust-toolchain chose the toolchain by the ref's name: @stable was a
# branch whose action.yml defaults it. At a commit on master, the history its
# README says a pin must come from, the input is required, so the step names it.
_gprust="$( ( . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/bootstrap.sh"
              felix_bs_render_workflow rust someone/repo ) \
            | awk '/uses: dtolnay\/rust-toolchain@/ { s = 1; next }
                   s && /^[ \t]*- / { s = 0 }
                   s && /^[ \t]*toolchain:[ \t]*stable[ \t]*$/ { n++ }
                   END { print n + 0 }')"
is  "and the rust toolchain step names stable itself, since a commit carries no channel" "$_gprust" "1"

printf '\nthe CI that gates this checkout runs the action code its pins name, and no other\n'
# The two sections above hold what Felix renders into other repositories. The
# workflows beside this harness, the ones that gate the engine itself, were
# left on actions/checkout@v4 after both templates moved to a commit (#354,
# #403): a change under .github/workflows is an execute escape a person merges,
# and nothing here read those files. Every .yml and .yaml in that directory is
# read, every uses: key in each, by the same reader, so a workflow or an action
# added later is held to the pin without this section being edited. A snapshot's
# verification clone holds the public repository's own workflows there, and
# they are held to it too. No workflow file, a file awk could not read, or
# files with no uses: line between them, fails: a read that matched nothing
# would pass every tree.
_owf=()
for _owp in "$REAL_HARNESS"/../../.github/workflows/*.yml "$REAL_HARNESS"/../../.github/workflows/*.yaml; do
  [ -f "$_owp" ] && _owf+=("$_owp")
done
_owuses=""; _owrc=1
if [ "${#_owf[@]}" -gt 0 ]; then
  _owuses="$(awk -v q="'" '/^[ \t]*#/ { next }
                           /^[ \t]*(-[ \t]+)?uses:/ { v = $0; f = FILENAME; sub(/.*\//, "", f)
                             sub(/^[ \t]*(-[ \t]+)?uses:[ \t]*/, "", v); sub(/[ \t]+#.*$/, "", v)
                             gsub(/"/, "", v); gsub(q, "", v)
                             print f ":" FNR ": " v }' "${_owf[@]}")"; _owrc=$?
fi
_owloose="$(grep -v -E '@[0-9a-f]{40}$' <<<"$_owuses")"
if [ "$_owrc" -eq 0 ] && [ -n "$_owuses" ] && [ -z "$_owloose" ]; then
  ok  "every uses: in the workflows beside this harness names a full commit sha, not a ref its owner can move"
else
  bad "every uses: in the workflows beside this harness names a full commit sha, not a ref its owner can move" \
      "$(if [ "${#_owf[@]}" -eq 0 ]; then printf 'no workflow file under %s' "$REAL_HARNESS/../../.github/workflows"
         elif [ "$_owrc" -ne 0 ]; then printf 'awk could not read every workflow (exit %s)' "$_owrc"
         else printf '%s' "${_owloose:-no uses: line found}" | tr '\n' ';'; fi)"
fi

