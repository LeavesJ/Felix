# 2026-10-18 (judge refs): felix merge takes a full ref name as its base and
# refuses an expression such as HEAD~1, which git reads in its short-name order.
# The commit before the tip is therefore named by a branch made at it.
_mbase() { _fx_git "$1" update-ref refs/heads/jr-mbase HEAD~1 >/dev/null 2>&1; printf 'refs/heads/jr-mbase'; }
printf '\na reused tests verdict merges only on a green CI gate (contract A2, blind)\n'
# Written from docs/2026-10-12-gate-friction-contract-a2.md alone, C9.1 to
# C9.5. felix-home has no branch protection and `felix merge` asks CI nothing:
# its boundary is the receipt. Contract A lets the receipt's tests verdict come
# from a reused suite run (`tests:reused` in the sixth field), so a merge on
# such a receipt also needs the gate workflow to have passed on the exact head.
#
# Everything here is this part's own: a project, a checkout, a stub gh first
# on PATH that records every call and answers from a file, and nothing that
# reaches a network. The checkout's origin names github.com so a slug can be
# read from it, and GIT_ALLOW_PROTOCOL keeps git itself from ever going there.
# The judge is loaded the way the merge boundary loads it for felix-home
# (_felix_kernel_blockers): six libraries, set -uo pipefail, a child bash.
_gfcP="$FROOT/projects/gfcw"
_gfcR="$TMP/gfc-repo"
_gfcG="$TMP/gfc-gh"
mkdir -p "${_gfcP:?}" "${_gfcR:?}" "${_gfcG:?}/bin" "$MEM/gfcw"
cp "$TMP/probes.keep" "$_gfcP/probes.tsv"
cp "$TMP/obligations.keep" "$_gfcP/obligations.tsv"
cp "$TMP/commissioning.keep" "$_gfcP/commissioning.tsv"
cp "$REAL_HARNESS/templates/risk.tsv" "$_gfcP/risk.tsv"
printf '# gfcw\n' > "$_gfcP/CLAUDE.md"
# A gate workflow that is not the default, so a call that names gate.yml, or
# no workflow at all, is told apart from one that asks felix_gate_workflow.
cat > "$_gfcP/project.json" <<'EOF'
{
  "name": "gfcw",
  "remote_match": "example.invalid/gfcw",
  "gate": "true",
  "gate_workflow": "ci-gate.yml"
}
EOF
( _fx_cd "${_gfcR:?}" && git init -q -b main && printf 'gfcw\n' > .felix && printf 'one\n' > NOTES.txt \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base \
  && git checkout -q -b gfc-topic && printf 'two\n' >> NOTES.txt \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm change \
  && git remote add origin https://github.com/gfc-owner/gfcw.git ) >/dev/null 2>&1
_gfcR="$(cd "${_gfcR:?}" && pwd -P)"
_gfcH="$(git -C "${_gfcR:?}" rev-parse HEAD 2>/dev/null)"
_gfcO="$(git -C "${_gfcR:?}" rev-parse HEAD~1 2>/dev/null)"
_gfcH8="$(printf '%s' "$_gfcH" | cut -c1-8)"
_gfcPre="the gate reused a suite run for this tree (tests:reused), and the gate workflow has not passed on $_gfcH8:"

# The stub. Every call is one line in calls. mode decides the answer: runs
# answers `gh run list` from runs.json the way gh does (filtered by
# --workflow, --commit, --branch and --status, newest first, cut to --limit,
# --json fields checked against the ones gh knows and kept, --jq applied by
# jq -r), fail exits 1 with nothing on stdout, empty prints nothing and exits
# 0, garbage prints a page that is not JSON and exits 0. `auth status` and
# `repo view` are answered so a preflight does not read as GitHub failing.
cat > "$_gfcG/bin/gh" <<'GFCSTUB'
#!/usr/bin/env bash
d="$(cd "$(dirname "$0")/.." && pwd)"
printf '%s\n' "$*" >> "$d/calls"
mode="$(cat "$d/mode" 2>/dev/null)"
case "$mode" in
  fail)    printf 'HTTP 502: Bad Gateway (https://api.github.com/graphql)\n' >&2; exit 1 ;;
  empty)   exit 0 ;;
  garbage) printf '<html><body><h1>502 Bad Gateway</h1></body></html>\n'; exit 0 ;;
esac
case "${1:-} ${2:-}" in
  "auth status") printf 'github.com\n  Logged in to github.com account gfc-owner\n'; exit 0 ;;
  "repo view")   printf 'gfc-owner/gfcw\n'; exit 0 ;;
  "run list")    shift 2 ;;
  *) printf 'gh stub: not answered here: %s\n' "$*" >&2; exit 1 ;;
esac
wf=""; c=""; b=""; s=""; n=20; json=""; q=""; jsonset=0
while [ $# -gt 0 ]; do
  case "$1" in
    -w|--workflow) wf="${2:-}"; shift 2 ;;  --workflow=*) wf="${1#*=}"; shift ;;
    -c|--commit)   c="${2:-}"; shift 2 ;;   --commit=*)   c="${1#*=}"; shift ;;
    -b|--branch)   b="${2:-}"; shift 2 ;;   --branch=*)   b="${1#*=}"; shift ;;
    -s|--status)   s="${2:-}"; shift 2 ;;   --status=*)   s="${1#*=}"; shift ;;
    -L|--limit)    n="${2:-}"; shift 2 ;;   --limit=*)    n="${1#*=}"; shift ;;
    --json)        json="${2:-}"; jsonset=1; shift 2 ;; --json=*) json="${1#*=}"; jsonset=1; shift ;;
    -q|--jq)       q="${2:-}"; shift 2 ;;   --jq=*)       q="${1#*=}"; shift ;;
    -R|--repo|-e|--event|-u|--user|--created) shift 2 ;;
    *) shift ;;
  esac
done
case "$n" in ''|*[!0-9]*) printf 'invalid value for --limit: %s\n' "$n" >&2; exit 1 ;; esac
[ -z "$q" ] || [ "$jsonset" -eq 1 ] || { printf 'cannot use `--jq` without specifying `--json`\n' >&2; exit 1; }
for f in $(printf '%s' "$json" | tr ',' ' '); do
  case " attempt conclusion createdAt databaseId displayTitle event headBranch headSha name number startedAt status updatedAt url workflowDatabaseId workflowName " in
    *" $f "*) ;;
    *) printf 'Unknown JSON field: "%s"\n' "$f" >&2; exit 1 ;;
  esac
done
sel="$(jq -c --arg wf "$wf" --arg c "$c" --arg b "$b" --arg s "$s" --argjson n "$n" --arg f "$json" '
  [ .[] | select(($wf == "" or ._wf == $wf or .workflowName == $wf)
             and ($c == "" or .headSha == $c) and ($b == "" or .headBranch == $b)
             and ($s == "" or .status == $s or .conclusion == $s)) ] | .[:$n]
  | if $f == "" then . else map(with_entries(select(.key as $k | ($f | split(",")) | index($k)))) end
' "$d/runs.json")" || exit 1
if [ "$jsonset" -eq 0 ]; then
  printf '%s\n' "$sel" | jq -r '.[] | "\(.status)\t\(.conclusion)\t\(.displayTitle)\t\(.workflowName)\t\(.headBranch)\t\(.event)\t\(.databaseId)\t1m0s\t\(.createdAt)"'
elif [ -n "$q" ]; then
  printf '%s\n' "$sel" | jq -r "$q"
else
  printf '%s\n' "$sel"
fi
GFCSTUB
chmod +x "$_gfcG/bin/gh"

# One run as gh's JSON knows it. _wf is the workflow's file, which gh matches
# --workflow against and never prints. conclusion is "" until a run completes.
_gfcRun() {   # id sha status conclusion workflow-file
  printf '{"databaseId":%s,"number":%s,"attempt":1,"status":"%s","conclusion":"%s","headSha":"%s","headBranch":"gfc-topic","event":"pull_request","displayTitle":"gfc change","name":"%s","workflowName":"%s","workflowDatabaseId":7,"_wf":"%s","createdAt":"2026-10-12T20:%02d:00Z","startedAt":"2026-10-12T20:%02d:00Z","updatedAt":"2026-10-12T20:%02d:30Z","url":"https://github.com/gfc-owner/gfcw/actions/runs/%s"}' \
    "$1" "$1" "$3" "$4" "$2" "${5%.yml}" "${5%.yml}" "$5" "$1" "$1" "$1" "$1"
}
_gfcCase() {  # mode [run...]: what gh answers, newest run first; empties the record
  local IFS=,
  printf '%s\n' "$1" > "${_gfcG:?}/mode"; shift
  printf '[%s]\n' "$*" > "$_gfcG/runs.json"
  : > "$_gfcG/calls"
}
_gfcCalls() { cat "${_gfcG:?}/calls" 2>/dev/null; }

# A receipt for this exact tree, reporting what the gate reported. The
# commission receipt beside it, which every green merge fixture has, is keyed
# to the tables and the checkout, neither of which moves here, so it is
# stamped once.
_gfcRcpt() {  # rc reported [tree id]
  ( cd "${_gfcR:?}" && . "$FROOT/harness/lib/verify.sh"
    felix_verify_record "$_gfcR" "$FROOT" "$1" "gate.sh" "${3:-$(felix_tree_id "$_gfcR" "$FROOT")}" "" "$2" ) >/dev/null 2>&1
}
( cd "${_gfcR:?}" && FELIX_HOME_DIR="$FROOT"; . "$FROOT/harness/lib/commission.sh"
  _o="$(felix_commission_run "$_gfcP" "$_gfcR" -)"
  felix_commission_receipt_write "$FROOT" "$_gfcP" "$_gfcR" "$_o" "" ) >/dev/null 2>&1

# The judge, loaded as the merge boundary loads it. $1 is the PATH it runs on.
_gfcBlk() {
  ( cd "${_gfcR:?}" && GIT_ALLOW_PROTOCOL=file PATH="$1" bash -c '
      set -uo pipefail
      k="$1"
      for f in resolve verify review classify evidence escape; do . "$k/lib/$f.sh" 2>/dev/null || exit 3; done
      felix_merge_blockers "$2" HEAD~1 "$3" "$4"
    ' _ "$FROOT/harness" "$_gfcP" "$_gfcR" "$FROOT" ) 2>/dev/null
}
_gfcPATH="$_gfcG/bin:$PATH"

# A PATH with no gh on it at all: every directory that holds one is replaced
# by a copy of its entries, as links, without gh.
_gfcNoGh=""; _gfci=0
_gfcIFS="$IFS"; IFS=:
for _gfcd in $PATH; do
  [ -n "$_gfcd" ] || continue
  if [ -e "$_gfcd/gh" ] || [ -L "$_gfcd/gh" ]; then
    _gfci=$((_gfci+1)); mkdir -p "${_gfcG:?}/nogh$_gfci"
    ln -s "$_gfcd"/* "$_gfcG/nogh$_gfci/" 2>/dev/null; rm -f "$_gfcG/nogh$_gfci/gh"
    _gfcNoGh="${_gfcNoGh:+$_gfcNoGh:}$_gfcG/nogh$_gfci"
  else
    _gfcNoGh="${_gfcNoGh:+$_gfcNoGh:}$_gfcd"
  fi
done
IFS="$_gfcIFS"

# What a reused receipt's blockers came to: `held` when they are exactly one
# row, not-green/tests, whose reason begins with the contract's sentence and
# then says what held; otherwise what came instead.
_gfcHeld() {  # blockers tail
  local n r
  n="$(printf '%s\n' "$1" | LC_ALL=C awk 'NF { c++ } END { print c + 0 }')"
  r="$(printf '%s\n' "$1" | LC_ALL=C awk -F'\t' '$1 == "not-green" && $2 == "tests" { print $3; exit }')"
  if [ "$n" != 1 ] || [ -z "$r" ]; then printf 'rows=%s [%s]' "$n" "$(printf '%s' "$1" | LC_ALL=C tr '\t\n' ' |')"; return 0; fi
  case "$r" in
    "$_gfcPre"*"$2"*) printf 'held' ;;
    *) printf 'reason [%s]' "$r" ;;
  esac
}
_gfcLacks() { case "$2" in *"$3"*) bad "$1" "[$2] holds [$3]" ;; *) ok "$1" ;; esac; }

_gfcRO="syntax:ok,tests:reused,secret:ok"
_gfcFail="$(_gfcRun 41 "$_gfcH" completed failure ci-gate.yml)"

is "the A2 fixture has two commits and a head sha to name" \
   "$(printf '%s %s' "${#_gfcH}" "${#_gfcO}")" "40 40"
is "the A2 fixture's PATH without gh finds no gh" \
   "$(PATH="$_gfcNoGh" command -v gh >/dev/null 2>&1 && echo found || echo none)" "none"

# The stub answers a run list through jq. Where there is none, every
# assertion that needs an answered run list is a skip, by name, and the rest
# still run.
_gfcJq=0; command -v jq >/dev/null 2>&1 && _gfcJq=1
_gfcIs()  { if [ "$_gfcJq" = 1 ]; then is "$@";  else skip "$1" "no jq here for the gh stub"; fi; }
_gfcHas() { if [ "$_gfcJq" = 1 ]; then has "$@"; else skip "$1" "no jq here for the gh stub"; fi; }

# The stub itself, asked directly: on today's engine nothing else reaches its
# run-list answer, so a stub that answered wrongly would hold a correct rule.
_gfcCase runs "$(_gfcRun 40 "$_gfcH" completed success ci-gate.yml)" "$(_gfcRun 39 "$_gfcO" completed failure ci-gate.yml)" \
              "$(_gfcRun 38 "$_gfcH" completed failure lint.yml)"
_gfcIs "the A2 stub answers the gate workflow's runs on one commit as gh would" \
   "$(PATH="$_gfcPATH" gh run list --repo gfc-owner/gfcw --workflow ci-gate.yml --commit "$_gfcH" \
        --json status,conclusion,headSha -q '.[] | "\(.status) \(.conclusion) \(.headSha)"' 2>&1)" "completed success $_gfcH"

# Each judge call costs two to three seconds of CPU, so each case below is
# one call, and the cases are the contract's: one per bullet of C9.3 (in
# progress stands for every status that is not completed), the two that C9.1
# and C9.4 name, the three ways gh cannot answer, and one dry run.

# ---- C9.4: a receipt without tests:reused asks nothing ---------------------
# gh is set to fail, so a rule that asked would show it twice: in the
# blockers and in the record.
_gfcRcpt 0 "syntax:ok,tests:ok,secret:ok"; _gfcCase fail
is "C9.4: a green receipt reading tests:ok clears every blocker, as today" "$(_gfcBlk "$_gfcPATH")" ""
is "C9.4: and gh is not called at all" "$(_gfcCalls)" ""

# ---- C9.1, C9.2: a completed success on the exact head ---------------------
_gfcRcpt 0 "$_gfcRO"
_gfcCase runs "$(_gfcRun 40 "$_gfcH" completed success ci-gate.yml)"
_gfcIs "C9.2: a reused receipt with the gate workflow's success on the head clears every blocker" \
   "$(_gfcBlk "$_gfcPATH")" ""
_gfcC="$(_gfcCalls)"
_gfcHas "C9.1: and that was asked of gh run list" "$_gfcC" "run list"
_gfcHas "C9.1: for the workflow felix_gate_workflow names (ci-gate.yml here)" "$_gfcC" "ci-gate.yml"

# ---- C9.3: each way the head has no passing gate run -----------------------
_gfcCase runs
_gfcB="$(_gfcBlk "$_gfcPATH")"
_gfcIs "C9.3: no gate run at all holds the merge: no run on this commit" "$(_gfcHeld "$_gfcB" "no run on this commit")" "held"
_gfcIs "C9.3: the reason begins with the contract's sentence and the head's first 8" \
   "$(printf '%s\n' "$_gfcB" | LC_ALL=C awk -F'\t' '$2 == "tests" { print substr($3, 1, length(p)) }' p="$_gfcPre")" "$_gfcPre"

# A gate success on another commit, and another workflow's success on this
# one: neither is the gate workflow passing on the head.
_gfcCase runs "$(_gfcRun 41 "$_gfcH" completed success lint.yml)" "$(_gfcRun 40 "$_gfcO" completed success ci-gate.yml)"
_gfcIs "C9.3: a gate success on another commit only (and lint's on this one) is no run on this commit" \
   "$(_gfcHeld "$(_gfcBlk "$_gfcPATH")" "no run on this commit")" "held"

_gfcCase runs "$(_gfcRun 40 "$_gfcH" in_progress "" ci-gate.yml)"
_gfcIs "C9.3: a gate run in progress on the head holds: its run is in_progress" \
   "$(_gfcHeld "$(_gfcBlk "$_gfcPATH")" "its run is in_progress")" "held"

_gfcCase runs "$(_gfcRun 40 "$_gfcH" completed failure ci-gate.yml)"
_gfcIs "C9.3: a failed gate run on the head holds: its run concluded failure" \
   "$(_gfcHeld "$(_gfcBlk "$_gfcPATH")" "its run concluded failure")" "held"

# ---- C9.3: GitHub could not be asked: unreadable is never no runs, never a pass
# The runs file holds a success on the head each time, so a rule that read
# past the failure to it would pass.
_gfcCase runs "$(_gfcRun 40 "$_gfcH" completed success ci-gate.yml)"
_gfcB="$(_gfcBlk "$_gfcNoGh")"
is "C9.3: gh missing holds the merge: GitHub could not be asked (...)" \
   "$(_gfcHeld "$_gfcB" "GitHub could not be asked (")" "held"
_gfcLacks "C9.3: and gh missing is not read as no run" "$_gfcB" "no run on this commit"
for _gfcm in fail empty; do
  _gfcCase "$_gfcm" "$(_gfcRun 40 "$_gfcH" completed success ci-gate.yml)"
  _gfcB="$(_gfcBlk "$_gfcPATH")"
  is "C9.3: gh answering $_gfcm holds the merge: GitHub could not be asked (...)" \
     "$(_gfcHeld "$_gfcB" "GitHub could not be asked (")" "held"
  _gfcLacks "C9.3: and gh answering $_gfcm is not read as no run" "$_gfcB" "no run on this commit"
done

# ---- C9.5: felix merge --dry-run reports it as it reports the others --------
# The dry run also carries the cancelled conclusion, so it is judged once,
# through the CLI, and not again through the judge.
_gfcCase runs "$(_gfcRun 40 "$_gfcH" completed cancelled ci-gate.yml)"
_gfcOut="$( cd "${_gfcR:?}" && GIT_ALLOW_PROTOCOL=file PATH="$_gfcPATH" "$FELIX" merge --base "$(_mbase "${_gfcR:?}")" --dry-run 2>&1 )"; _gfcRc=$?
_gfcIs "C9.5: felix merge --dry-run refuses a reused receipt whose head's gate run was cancelled" "$_gfcRc" "3"
_gfcHas "C9.5: and prints the blocker on its own line, as the others are printed" "$_gfcOut" \
    "$(printf '  %-11s %-22s %s' not-green tests "$_gfcPre")"
_gfcHas "C9.3/C9.5: saying what held: its run concluded cancelled" "$_gfcOut" "its run concluded cancelled"

# ==== not blind: the review of the first build of C9 (779d7f39) ===============
# Everything above is the blind block, written from the contract alone. What
# follows is not: four findings of the review that came after the build, each
# written with the defect in view and named in its assertions. Each is red on
# 779d7f39 and green on the fix, and the cases the fix keeps are marked
# (control).

# ---- C9-R1: the newest run on the head is the verdict ----------------------
# A second run on one head appears when a pull request is reopened after main
# moved, or when the head sits in two of them. An older green run must not
# stand in for a newer one that failed or has not finished.
_gfcRcpt 0 "$_gfcRO"
_gfcCase runs "$(_gfcRun 42 "$_gfcH" completed failure ci-gate.yml)" "$(_gfcRun 40 "$_gfcH" completed success ci-gate.yml)"
_gfcIs "not blind: review finding C9-R1: a newer failed gate run on the head is not outvoted by an older success: its run concluded failure" \
   "$(_gfcHeld "$(_gfcBlk "$_gfcPATH")" "its run concluded failure")" "held"
_gfcCase runs "$(_gfcRun 42 "$_gfcH" in_progress "" ci-gate.yml)" "$(_gfcRun 40 "$_gfcH" completed success ci-gate.yml)"
_gfcIs "not blind: review finding C9-R1: nor is a newer gate run still in progress: its run is in_progress" \
   "$(_gfcHeld "$(_gfcBlk "$_gfcPATH")" "its run is in_progress")" "held"
_gfcCase runs "$(_gfcRun 42 "$_gfcH" completed success ci-gate.yml)" "$(_gfcRun 40 "$_gfcH" completed failure ci-gate.yml)"
_gfcIs "not blind: review finding C9-R1: a newer success after an older failure clears every blocker (control)" \
   "$(_gfcBlk "$_gfcPATH")" ""

# ---- C9-R2: a run whose commit cannot be read is not a run on this commit ---
# The stub below answers whatever --commit says, as a gh that is not GitHub's
# or an API anomaly would, with the one run's headSha taken out three ways.
# Real gh always fills headSha; the only thing that would tie such a run to the
# head is the --commit filter, and the rule says it reads headSha itself.
mkdir -p "${_gfcG:?}/raw"
cat > "$_gfcG/raw/gh" <<'GFCRAW'
#!/usr/bin/env bash
d="$(cd "$(dirname "$0")/.." && pwd)"
printf '%s\n' "$*" >> "$d/calls"
case "${1:-} ${2:-}" in
  "auth status"|"repo view") exit 0 ;;
  "run list") shift 2 ;;
  *) exit 1 ;;
esac
q=""
while [ $# -gt 0 ]; do case "$1" in -q|--jq) q="${2:-}"; shift 2 ;; *) shift ;; esac; done
jq -r "$q" "$d/runs.json"
GFCRAW
chmod +x "$_gfcG/raw/gh"
_gfcRawPATH="$_gfcG/raw:$PATH"
_gfcOne="$(_gfcRun 40 "$_gfcH" completed success ci-gate.yml)"
_gfcNoSha=0; command -v jq >/dev/null 2>&1 && _gfcNoSha=1
if [ "$_gfcNoSha" = 1 ]; then
  _gfcRcpt 0 "$_gfcRO"
  _gfcCase runs "$_gfcOne"
  is "not blind: review finding C9-R2: the raw stub's answer holds a success whose headSha is the head (control)" \
     "$(_gfcBlk "$_gfcRawPATH")" ""
  for _gfcv in 'null:.headSha = null' 'empty:.headSha = ""' 'absent:del(.headSha)'; do
    _gfcCase runs "$(printf '%s' "$_gfcOne" | jq -c "${_gfcv#*:}")"
    _gfcB="$(_gfcBlk "$_gfcRawPATH")"
    is "not blind: review finding C9-R2: a success whose headSha is ${_gfcv%%:*} is not a pass: GitHub could not be asked (...)" \
       "$(_gfcHeld "$_gfcB" "GitHub could not be asked (")" "held"
  done
  # Mutants the blind block let through, found by hand after it was written:
  # the blind stub filters by --commit as gh does, so a rule that dropped its
  # own reading of headSha, or dropped --commit, still met only runs on the
  # head. A gh that answers about another commit anyway shows both.
  _gfcCase runs "$(_gfcRun 40 "$_gfcO" completed success ci-gate.yml)"
  is "not blind: mutant, accept a run on another commit: a success the answer puts on the parent commit is no run on this commit" \
     "$(_gfcHeld "$(_gfcBlk "$_gfcRawPATH")" "no run on this commit")" "held"
  _gfcCase runs "$(_gfcRun 40 "$_gfcH8" completed success ci-gate.yml)"
  is "not blind: mutant, accept a run on another commit: nor is one on the head's first 8, which is not the head" \
     "$(_gfcHeld "$(_gfcBlk "$_gfcRawPATH")" "no run on this commit")" "held"
  has "not blind: mutant, accept a run on another commit: and gh was asked for the head's full sha" "$(_gfcCalls)" "$_gfcH"
else
  skip "not blind: review finding C9-R2: a success whose headSha is missing is not a pass" "no jq here for the gh stub"
fi

# ---- the pair is tests:reused, not a string that contains it ----------------
# A mutant that matched `tests:reused` as a substring of the reported field
# passed the blind block, which only ever reports tests:ok and tests:reused.
# The gate reports neither of these; a receipt that did must not be taken for a
# reused one (contract A2, item 1: "holds the pair"). gh fails, so a rule that
# asked would show in the blockers and in the record.
_gfcRcpt 0 "syntax:ok,xtests:reused,tests:reusedx,secret:ok"; _gfcCase fail
is "not blind: mutant, tests:reused as a substring: a pair that only contains it (xtests:reused, tests:reusedx) clears every blocker" \
   "$(_gfcBlk "$_gfcPATH")" ""
is "not blind: mutant, tests:reused as a substring: and gh is not called at all" "$(_gfcCalls)" ""

# ---- C9-R3: the receipt C9 reads is the receipt that was judged -------------
# felix_verify_current takes about a third of a second and the gate rewrites
# the receipt with a truncating `>`. The judge below is the merge boundary's,
# loaded the same way, with that one function wrapped so that the receipt
# vanishes, or is truncated, the moment it has said `current`. The receipt
# judged current said tests:reused, gh answers an empty list, and the rule must
# still have asked.
_gfcBlkRace() {   # PATH, rm|empty: what happens to the receipt right after it is judged
  ( cd "${_gfcR:?}" && GIT_ALLOW_PROTOCOL=file PATH="$1" bash -c '
      set -uo pipefail
      k="$1"; p="$2"; r="$3"; h="$4"; m="$5"
      for f in resolve verify review classify evidence escape; do . "$k/lib/$f.sh" 2>/dev/null || exit 3; done
      # The copy of the function below cannot find epoch.sh by its own path, as
      # the original does at call time, so it is loaded here.
      . "$k/lib/epoch.sh" 2>/dev/null || exit 3
      eval "_gfcOrigCurrent() $(declare -f felix_verify_current | sed 1d)"
      felix_verify_current() {
        _gfcOrigCurrent "$@"; local rc=$?
        case "$m" in
          rm)    rm -f "$(_felix_receipt_path "$r" "$h")" ;;
          empty) : > "$(_felix_receipt_path "$r" "$h")" ;;
        esac
        return $rc
      }
      felix_merge_blockers "$p" HEAD~1 "$r" "$h"
    ' _ "$FROOT/harness" "$_gfcP" "$_gfcR" "$FROOT" "$2" ) 2>/dev/null
}
for _gfcm in rm empty; do
  _gfcRcpt 0 "$_gfcRO"
  _gfcCase runs
  _gfcIs "not blind: review finding C9-R3: a receipt judged current as tests:reused still asks GitHub when it is $([ "$_gfcm" = rm ] && echo removed || echo truncated) a moment later: no run on this commit" \
     "$(_gfcHeld "$(_gfcBlkRace "$_gfcPATH" "$_gfcm")" "no run on this commit")" "held"
done
_gfcRcpt 0 "$_gfcRO"
_gfcCase runs "$(_gfcRun 40 "$_gfcH" completed success ci-gate.yml)"
_gfcIs "not blind: review finding C9-R3: and with the gate's success on the head the same wrapped judge clears every blocker (control)" \
   "$(_gfcBlkRace "$_gfcPATH" rm)" ""

# ---- C9-R4: a reused suite is reported reused whatever is in front of it ----
# projects/felix/gate.sh, whole, in a checkout of its own with a stub for
# tests/run, as part 1130 does it. The stub writes `warning: something` to
# stderr with no newline ahead of the suite's first line, which is what a git
# warning or BASH_ENV can do: the log then holds the sentence on a line that
# does not begin with it. A gate that reports ok for it writes tests:ok in its
# receipt and C9 asks nothing.
GFH="$TMP/gfh-gate"; GFH_C="$GFH/c"; mkdir -p "$GFH/tmp" "$GFH/home"
GFH_GATE="$REAL_HARNESS/../../projects/felix/gate.sh"
mkdir -p "$GFH_C/engine/harness/bin" "$GFH_C/engine/harness/lib" "$GFH_C/engine/harness/tests" "$GFH_C/projects/felix"
if [ ! -f "$GFH_GATE" ]; then
  skip "not blind: review finding C9-R4: a reused suite behind a line fragment is reported reused" "no projects/felix/gate.sh beside this engine"
else
  cp "$GFH_GATE" "$GFH_C/projects/felix/gate.sh"
  printf '#!/bin/sh\nexit 0\n' > "$GFH_C/engine/harness/bin/schema-check"
  printf '#!/bin/sh\n[ "${1:-}" = --paths ] && echo engine/harness/bin\nexit 0\n' > "$GFH_C/engine/harness/bin/independence-scan"
  printf '_gfh_probe() {\n  _felix_dep_grep "$root" "gfhzzword"\n}\n' > "$GFH_C/engine/harness/lib/detect.sh"
  printf '# kind\tfile\ttoken\treason\n' > "$GFH_C/engine/harness/ecosystem.tsv"
  cat > "$GFH_C/engine/harness/tests/run" <<'GFHRUN'
#!/usr/bin/env bash
case "$(cat "${GFH_MODE:?}")" in
  prefixed)    printf 'warning: something' >&2
               printf 'reused the suite run that ended 09:41 on this tree (normal), not run again\n\n12 passed, 0 failed (reused)\n'; exit 0 ;;
  summaryonly) printf 'the first line was lost\n\n12 passed, 0 failed (reused)\n'; exit 0 ;;
  ranfull)     printf 'not reused: no receipt\n\n  ok    the line that says reused the suite run that ended is not this one\n\n12 passed, 0 failed\n'; exit 0 ;;
esac
exit 3
GFHRUN
  chmod +x "$GFH_C/engine/harness/bin/schema-check" "$GFH_C/engine/harness/bin/independence-scan" "$GFH_C/engine/harness/tests/run"
  ( _fx_cd "${GFH_C:?}" && git -c user.name=gfh -c user.email=gfh@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null init -q -b main \
      && git add -A && git -c user.name=gfh -c user.email=gfh@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm fixture ) >/dev/null 2>&1
  _gfhGate() {   # name mode: the gate's output in $GFH/<name>.out
    local pid c=0
    printf '%s\n' "$2" > "$GFH/mode"
    ( cd "${GFH_C:?}" && exec env HOME="$GFH/home" FELIX_KERNEL_CACHE="$GFH/nocache" TMPDIR="$GFH/tmp" \
        GFH_MODE="$GFH/mode" bash projects/felix/gate.sh ) > "$GFH/$1.out" 2>&1 &
    pid=$!
    while kill -0 "$pid" 2>/dev/null && [ "$c" -lt 300 ]; do sleep 0.1; c=$((c + 1)); done
    kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
  }
  _gfhReused="$(printf '  %-18s reused' tests)"
  _gfhOk="$(printf '  %-18s ok' tests)"
  _gfhGate prefixed prefixed
  is "not blind: review finding C9-R4: a reused suite whose first line follows a line fragment is reported tests reused, not ok" \
     "$(grep -cxF -e "$_gfhReused" "$GFH/prefixed.out") $(grep -cxF -e "$_gfhOk" "$GFH/prefixed.out")" "1 0"
  _gfhGate summaryonly summaryonly
  is "not blind: review finding C9-R4: a log whose summary says (reused) is reported tests reused though its first line is lost" \
     "$(grep -cxF -e "$_gfhReused" "$GFH/summaryonly.out") $(grep -cxF -e "$_gfhOk" "$GFH/summaryonly.out")" "1 0"
  _gfhGate ranfull ranfull
  is "not blind: review finding C9-R4: a suite that ran, with a test name that mentions the reuse line, is still reported ok (control)" \
     "$(grep -cxF -e "$_gfhReused" "$GFH/ranfull.out") $(grep -cxF -e "$_gfhOk" "$GFH/ranfull.out")" "0 1"
fi

rm -rf "${_gfcP:?}" "${MEM:?}/gfcw"
