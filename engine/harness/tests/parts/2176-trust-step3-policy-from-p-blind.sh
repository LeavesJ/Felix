# >>> trust-step3-policy-from-p
printf '\ntrust plane step 3, slice 1: the merge boundary reads its policy and its instruments from P (spec sections 1-2; blind)\n'
# Blind, written on 2026-11-07 from .felix/memory/felix/audits/2026-11-08-trust-plane-step3/spec.md alone (sections 0-3),
# before the change. Not read: engine/harness/felix, lib/*.sh, hooks, bin, projects/*/gate.sh, any lib/policy.sh. How to
# drive felix merge was learned from tests/lib/judge-refs.sh and parts 0340, 0360, 1400 and 1870; rule C9's gh stub is
# part 1250's, answering `pr view` as _js_build's does. Every fixture is this part's own, under $TS3, and its memory
# $MEM/ts3 and $MEM/ts32 are removed at the end of part 2177; it adds nothing under $FROOT/projects. The cases from the
# spec's amendments (S1.7 added; S1.7 amended, S1.8-S1.10 and S2.1 amended after review round 1, S2.1 widened after the
# security review) were added blind the same way, from the amended spec alone. Part 2177 continues this one in the same
# shell (group ts3 in tests/groups.tsv) and holds S2.1, S3, S4, the workflows control, S1.8 for a product (its own
# product, home and memory $MEM/ts3p) and S1.5; the readings for S2.1 and the product cases are its.
#
# R is built as section 2 says, the project ts3: _js_build's shape (the harness under test as engine/, a manifest at
# 1.0.0, a github.com origin, refs/remotes/origin/main at main), and on main projects/ts3/ (project.json ending with
# "gate_workflow": "gate.yml", CLAUDE.md, probes.tsv, obligations.tsv, commissioning.tsv, risk.tsv = the template plus
# the exfil row), .felix, .gitignore (state/ and *.log), tools/check-fx, tools/lib.sh, tools/applies-fx, MARKER, and
# what this part adds: tools/probe-fx, PROBE.txt and .github/workflows/gate.yml. The entry K/1.0.0 is main's engine cut
# from the commit as _js_entry cuts one. Each run: a green gate receipt and a commission receipt for the tree as it
# stands with the home R (_jr_record's calls, read against P's project directory: see the first reading), then
# `felix merge --dry-run` from K/1.0.0/harness/felix in the candidate's checkout, FELIX_HOME=R, a fresh empty physical
# TMPDIR, a scratch HOME, FELIX_KERNEL and FELIX_MERGE_HANDED unset, gh the stub.
#
# Readings, where the spec leaves room:
# - The receipts. Section 2 says to record them as _jr_record does with the home R, which takes the epoch and the
#   commission's table set from the project directory in the home's working tree. Where that directory differs from
#   P's (S1's three cases, S3 and its control, the workflow control), such a receipt is current for today's reader and
#   stale for the reader S1.6 makes of the receipt's epoch. And a stale epoch stops rule C9 before it asks gh: measured
#   on main 2026-11-07, such a run prints `unverified tree ... the table set moved` and calls no gh, so the C9 case
#   could not go green after the change. So every receipt here is read against P's project directory, a git archive of
#   projects/ts3 at main: felix_epoch and felix_epoch_components over it for the gate receipt (passed to
#   felix_verify_record as part 1520's _grf_rec passes them), and it as the project directory of felix_commission_run
#   and felix_commission_receipt_write. Where the home's tables are P's this gives the epoch _jr_record's call gives
#   (measured: the S2 controls pass on main). On main the table-editing cases therefore also print the stale-receipt
#   lines; escape, probe and obligation lines are printed beside them (measured), so those cases do not rest on this.
# - S1.7's case is the exception, as the spec and the coordinator ask: its receipts are recorded with the plain
#   directory $TS3H as the home and its projects/ts3 as the project directory, so on main they are current and the
#   loosened row is read (the dry run passes). After the change the boundary reads P's tables, against which those
#   receipts may read stale; so the assertion holds the refusal and the obligations line for fx only, and says nothing
#   of stale-receipt lines beside it. The plain home is made under $TS3, outside R, and the fixture control asks git
#   that no repository holds it. The candidate is a worktree of R on a branch that only deletes MARKER; R is on main.
#   The round-1 cases S1.8, S1.7 (the name BASE gives) and S1.9 record theirs the same way, with the home and its
#   project directory as they stand (the link; the plain home's projects/ts32; R's working tree one commit behind), as
#   the spec says, and hold only the line each asserts. S1.10 and S2.1 read P's tables, so they keep the first reading.
# - S1.8's link points at $TS3/moved-ts3x, outside R; the directory is moved out of R, loosened there, and put back
#   after with git checkout. S1.7's name case uses the project name ts32 and a second plain home; its refusal is held
#   to either line the spec offers (obligations for fx, or an escape line naming .felix). S1.9's P is a commit M3 off
#   main adding one yellow risk.tsv row, with origin/main moved to it and R's main left at M; the candidate is a
#   worktree branch off M3 adding NOTES.md; the control fast-forwards R's main to M3 and records again. Both are put
#   back after (main reset to M, origin/main to M).
# - S1.10 calls felix_merge_blockers loaded as part 1250's _gfcBlk loads it, plus lib/policy.sh when the entry has one
#   (sourcing it is not reading it), over R with MARKER deleted, home R. On main 2026-11-07 a base naming nothing
#   printed `unknown <base> this base names nothing here` and an empty base printed no unknown row (both measured); the
#   spec's section 2 was corrected to match (a base naming no commit: unknown and obligations; an empty base:
#   obligations and no policy row). Both hold on main, as S1.10 says they are judged as before this slice.
# - "Refused" is a non-zero exit with `not merging` printed. A blocker line is a line of the output beginning with two
#   spaces; its kind is its first field. "A KIND line for NAME" is read as NAME being its second field (the shape of
#   part 1250's `unverified tests`); "naming X" as X appearing anywhere on that line.
# - The probe of S2's probe case is fxprobe: when `-`, probe `tools/probe-fx` (P's lists PROBE.txt when the file is
#   there), witness `test -d tools`. The candidate deletes PROBE.txt and rewrites tools/probe-fx to list a member, so
#   its own probe reads ok, while P's lists nothing over a surface the witness says exists: blind, which blocks.
# - The obligations table holds the fx row alone; probes.tsv the marker row of every merge fixture and fxprobe;
#   commissioning.tsv the marker row of every merge fixture.
# - C9's edit must remove no row (so the verifier channel stays quiet) and must make today's engine ask lint.yml (the
#   spec says today's dry run asks it and passes). The first reading, a new last key "gate_workflow": "lint.yml" after
#   the old last line gained the comma, did not: measured on main 2026-11-07, today's engine then asked gate.yml and
#   refused. So the candidate inserts "gate_workflow": "lint.yml", with its comma, as the line before the unchanged
#   last key; with a receipt read from the working tree, today's engine then asked lint.yml and passed (measured). With
#   the receipt read against P (first reading) it refuses on main for the stale table set and asks no gh. The refusal
#   is held to the reason naming the failed run (part 1250's "concluded failure"), which only gate.yml's run gives.
#   The receipt reports syntax:ok,tests:reused,secret:ok, as part 1250's does. Without jq the stub cannot answer, and
#   that case is a skip.
# - S1's fail-closed case moves refs/remotes/origin/main to a commit off main that removes projects/ts3/; the candidate
#   is a branch off main adding NOTES.md, checked out in R, so the project directory is in its working tree.
# - S1's home case also asks that the escape line name danger/x, the path P's row fired on.
# - S3's row is the first `green` row of risk.tsv (the template's), a comma appended to its last cell; S3's control adds
#   "note" as project.json's new last key, and holds that the run reached a verdict (exit 0, or not merging printed).
# - S1.5 "nothing left" is held over every run, together with the one thing that makes it more than vacuous: in the
#   passing control, P's tools/check-fx ran (it logs its $0 when TS3_FXLOG is set, an addition to section 2's script)
#   from a felix-policy.* directory directly under that run's TMPDIR (S2.3). That half is also asserted on its own.
# - The workflow control's candidate also adds a green row for ^\.github/ to its risk.tsv: what its tables say.
# - S4 runs R/engine/harness/felix (the candidate's) with the same environment and the entry in the cache.
TS3="$TMP/ts3"; rm -rf "${TS3:?}"; mkdir -p "$TS3/repo" "$TS3/gh" "$TS3/home" "$TS3/kc" "$TS3/t" "$TS3/calls"
TS3="$(cd "${TS3:?}" && pwd -P)"; TS3R="$TS3/repo"; TS3K="$TS3/kc"; TS3P="$TS3/repo/projects/ts3"; TS3W="$TS3/wt"
TS3_TN=0; TS3T=""; TS3RC=0; TS3_LEFT=""; TS3_RUNS=0; TS3_M=""; TS3_M2=""; TS3_RH=""; TS3_RP=""; TS3H="$TS3/plainhome"
TS3_JQ=0; command -v jq >/dev/null 2>&1 && TS3_JQ=1
mkdir -p "$MEM/ts3"

# The stub: every call one line in calls; run list answered from runs.json as gh would (part 1250's), pr view as
# _js_build's stub answers it, anything else silently.
cat > "$TS3/gh/gh" <<'TS3GH'
#!/usr/bin/env bash
d="${TS3_GHDIR:?TS3_GHDIR is not set}"
printf '%s\n' "$*" >> "$d/calls"
# The provider's two reads at the merge (lib/bind.sh, spec S5.2), answered with git at call time from the checkout
# the stub runs in: the pull request open at this HEAD into main, and main at the commit it names here.
case "$*" in
  "pr view "*"--json number,state,baseRefName,headRefOid"*)
    printf '7\tOPEN\t%s\t%s\n' "${GHSTUB_BASE:-main}" "$(git rev-parse HEAD)"; exit 0 ;;
  "api repos/"*"/git/ref/heads/"*)
    n="${2#*/git/ref/heads/}"
    printf 'commit\t%s\n' "$(git rev-parse --verify -q "refs/remotes/origin/$n^{commit}" || git rev-parse --verify -q "refs/heads/$n^{commit}")"
    exit 0 ;;
esac
case "${1:-} ${2:-}" in
  "pr view")     printf '{"number":7,"state":"OPEN"}\n'; exit 0 ;;
  "pr merge")    printf 'merged\n'; exit 0 ;;
  "auth status") printf 'github.com\n  Logged in to github.com account example\n'; exit 0 ;;
  "repo view")   printf 'example/ts3\n'; exit 0 ;;
  "run list")    shift 2 ;;
  *) exit 0 ;;
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
[ -f "$d/runs.json" ] || printf '[]\n' > "$d/runs.json"
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
TS3GH
chmod +x "$TS3/gh/gh"
_ts3_ghrun() {   # ID SHA STATUS CONCLUSION WORKFLOW-FILE BRANCH -> one run as gh's JSON knows it (part 1250's _gfcRun)
  printf '{"databaseId":%s,"number":%s,"attempt":1,"status":"%s","conclusion":"%s","headSha":"%s","headBranch":"%s","event":"pull_request","displayTitle":"ts3 change","name":"%s","workflowName":"%s","workflowDatabaseId":7,"_wf":"%s","createdAt":"2026-11-07T20:%02d:00Z","startedAt":"2026-11-07T20:%02d:00Z","updatedAt":"2026-11-07T20:%02d:30Z","url":"https://github.com/example/ts3/actions/runs/%s"}' \
    "$1" "$1" "$3" "$4" "$2" "$6" "${5%.yml}" "${5%.yml}" "$5" "$1" "$1" "$1" "$1"
}

# ------------------------------------------------------------------ helpers ---
_ts3_check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]${4:+: $4}"; fi; }   # NAME GOT WANT [DETAIL]
_ts3_why() { printf 'exit %s; out: %s; err: %s' "$TS3RC" "$(head -c 900 "$TS3/out" 2>/dev/null | tr '\n' ' ')" "$(head -c 400 "$TS3/err" 2>/dev/null | tr '\n' ' ')"; }
_ts3_refused() {   # -> refused when the last run exited non-zero and printed not merging, else what it did
  if [ "$TS3RC" -ne 0 ] && [ "$(cat "$TS3/out" "$TS3/err" | LC_ALL=C awk 'index($0, "not merging") { n++ } END { print n + 0 }')" -gt 0 ]; then
    printf 'refused'
  else printf 'exit %s' "$TS3RC"; fi
}
_ts3_passed() {   # -> passed when the last run exited 0 saying felix merge would squash this now.
  if [ "$TS3RC" -eq 0 ] && [ "$(LC_ALL=C awk 'index($0, "felix merge would squash this now.") { n++ } END { print n + 0 }' "$TS3/out")" -gt 0 ]; then
    printf 'passed'
  else printf 'exit %s' "$TS3RC"; fi
}
_ts3_bl() {   # KIND NAME WORD WORD2 -> yes when the last run printed a blocker line of KIND whose second field is NAME
              # (- for any) and that holds WORD and WORD2 (- for none), else no
  cat "$TS3/out" "$TS3/err" | LC_ALL=C awk -v k="$1" -v nm="$2" -v a="$3" -v b="$4" '
    index($0, "  ") == 1 && $1 == k && (nm == "-" || $2 == nm) && (a == "-" || index($0, a)) && (b == "-" || index($0, b)) { f = 1 }
    END { print (f ? "yes" : "no") }'
}
_ts3_commit() {   # REPO MSG: one commit of everything, as _jr_commit makes one, with maintenance off
  _fx_git "$1" add -A >/dev/null 2>&1
  _fx_git "$1" -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c maintenance.auto=false commit -qm "$2" >/dev/null 2>&1
}
_ts3_case() {   # BRANCH: a fresh branch off main, checked out in R
  ( _fx_cd "$TS3R" && git checkout -q -f main && git checkout -q -B "$1" main ) >/dev/null 2>&1
}
_ts3_record() {   # REPO [REPORTED]: a green gate receipt and a commission receipt for REPO as it stands, home R, both
                  # read against P's project directory $TS3PP (see the readings above); TS3_RH and TS3_RP, when set,
                  # name another home and the project directory read instead (S1.7's case)
  local h="${TS3_RH:-$TS3R}" p="${TS3_RP:-$TS3PP}"
  ( cd "$1" && FELIX_HOME="$h"; . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/epoch.sh"
    felix_verify_record "$1" "$h" 0 "true" "$(felix_tree_id "$1" "$h")" "" "${2:-}" "$(felix_epoch "$p" "$1")" \
      "$(felix_epoch_components "$p" "$1" | cut -f2 | paste -sd, -)" ) >/dev/null 2>&1
  ( cd "$1" && FELIX_HOME="$h"; FELIX_HOME_DIR="$h"; . "$FROOT/harness/lib/commission.sh"
    _o="$(felix_commission_run "$p" "$1" -)"
    felix_commission_receipt_write "$h" "$p" "$1" "$_o" "" ) >/dev/null 2>&1
}
# _ts3_run LABEL DIR FELIX [REPORTED]: felix merge --dry-run from FELIX in DIR, home R, a fresh TMPDIR, after a fresh
# receipt; TS3RC, $TS3/out and $TS3/err; what the run left under its TMPDIR goes onto TS3_LEFT.
_ts3_run() {
  local l="$1" d="$2" fx="$3" left
  _ts3_record "$d" "${4:-}"
  TS3_TN=$((TS3_TN + 1)); mkdir -p "$TS3/t/$TS3_TN"; TS3T="$(cd "$TS3/t/$TS3_TN" && pwd -P)"
  : > "$TS3/fx.log"; : > "$TS3/calls/calls"
  ( cd "$d" && env -u FELIX_KERNEL -u FELIX_MERGE_HANDED HOME="$TS3/home" PATH="$TS3/gh:$PATH" TS3_GHDIR="$TS3/calls" \
      TS3_FXLOG="$TS3/fx.log" FELIX_HOME="${TS3_RH:-$TS3R}" FELIX_KERNEL_CACHE="$TS3K" TMPDIR="$TS3T" GIT_ALLOW_PROTOCOL=file \
      "$fx" merge --dry-run ) > "$TS3/out" 2> "$TS3/err"; TS3RC=$?
  TS3_RUNS=$((TS3_RUNS + 1))
  if [ -d "$TS3T" ]; then
    left="$(find "$TS3T" -name 'felix-policy.*' -print 2>/dev/null | LC_ALL=C sed "s|^$TS3T/||" | tr '\n' ' ')"
    [ -z "$left" ] || TS3_LEFT="${TS3_LEFT}$l left [$left]; "
  fi
}
_ts3_entry() { _ts3_run "$1" "${2:-$TS3R}" "$TS3K/1.0.0/harness/felix" "${3:-}"; }   # LABEL [DIR] [REPORTED]: from the entry
_ts3_pcopy() {   # -> yes when the last run's fx log holds a check-fx run from a felix-policy.* directory under its TMPDIR
  LC_ALL=C awk -v p="$TS3T/felix-policy." 'index($0, p) == 1 && substr($0, length($0) - 14) == "/tools/check-fx" { f = 1 }
    END { print (f ? "yes" : "no") }' "$TS3/fx.log" 2>/dev/null
}

# ---------------------------------------------------------------- fixture R ---
( _fx_cd "$TS3R" && git init -q -b main && git remote add origin https://github.com/example/ts3.git \
  && git config gc.auto 0 && git config maintenance.auto false ) >/dev/null 2>&1
_copy_content "$REAL_HARNESS" "$TS3R/engine/harness"; _copy_content "$REAL_HARNESS/../hooks" "$TS3R/engine/hooks"
[ -d "$REAL_HARNESS/../commands" ] && _copy_content "$REAL_HARNESS/../commands" "$TS3R/engine/commands"
# R's engine carries no suite (a fixture change for slice 3, not blind): with one, a candidate that edits a workflow
# changes the machinery, and felix merge runs every part of the real suite over R (lib/instrument.sh, S8.4).
rm -rf "${TS3R:?}/engine/harness/tests"
mkdir -p "$TS3R/engine/.claude-plugin" "$TS3P" "$TS3R/tools" "$TS3R/.github/workflows"
printf '{ "name": "felix", "version": "1.0.0" }\n' > "$TS3R/engine/.claude-plugin/plugin.json"
printf 'state/\n*.log\n' > "$TS3R/.gitignore"; printf 'ts3\n' > "$TS3R/.felix"
printf '{\n  "name": "ts3",\n  "remote_match": "example.com/ts3",\n  "gate": "true",\n  "gate_workflow": "gate.yml"\n}\n' > "$TS3P/project.json"
printf '# ts3\n' > "$TS3P/CLAUDE.md"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\nfxprobe\t-\t-\ttools/probe-fx\ttest -d tools\n' > "$TS3P/probes.tsv"
printf 'fx\tRELEASE_BLOCKING\tdeterministic\ttools/applies-fx\ttools/check-fx\t-\ta reason\n' > "$TS3P/obligations.tsv"
printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n' > "$TS3P/commissioning.tsv"
cp "$REAL_HARNESS/templates/risk.tsv" "$TS3P/risk.tsv"
printf 'red\tpath\t^danger/\ta danger path\texfil\n' >> "$TS3P/risk.tsv"
cat > "$TS3R/tools/check-fx" <<'TS3CHK'
#!/usr/bin/env bash
[ -z "${TS3_FXLOG:-}" ] || printf '%s\n' "$0" >> "$TS3_FXLOG"
. "$(dirname "$0")/lib.sh"
fx_check
TS3CHK
printf 'fx_check() { test -f MARKER; }\n' > "$TS3R/tools/lib.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TS3R/tools/applies-fx"
printf '#!/usr/bin/env bash\n[ ! -f PROBE.txt ] || printf '"'"'PROBE.txt\\n'"'"'\nexit 0\n' > "$TS3R/tools/probe-fx"
chmod 755 "$TS3R/tools/check-fx" "$TS3R/tools/applies-fx" "$TS3R/tools/probe-fx"
printf 'a marker the fx check reads\n' > "$TS3R/MARKER"
printf 'a member the fx probe lists\n' > "$TS3R/PROBE.txt"
printf 'on: pull_request\njobs: {}\n' > "$TS3R/.github/workflows/gate.yml"
_ts3_commit "$TS3R" base; TS3_M="$(_jr_sha "$TS3R" HEAD)"
_fx_git "$TS3R" update-ref refs/remotes/origin/main "$TS3_M" >/dev/null 2>&1
mkdir -p "$TS3/p"; _fx_git "$TS3R" archive -o "$TS3/p.tar" "$TS3_M" projects/ts3 >/dev/null 2>&1 && tar -x -C "$TS3/p" -f "$TS3/p.tar"
rm -f "$TS3/p.tar"; TS3PP="$TS3/p/projects/ts3"
rm -rf "$TS3K/1.0.0" "$TS3/x" "$TS3/x.tar"; mkdir -p "$TS3K/1.0.0" "$TS3/x"
_fx_git "$TS3R" archive -o "$TS3/x.tar" "$TS3_M" engine >/dev/null 2>&1 && tar -x -C "$TS3/x" -f "$TS3/x.tar"
for _ts3_d in harness hooks commands .claude-plugin; do [ -d "$TS3/x/engine/$_ts3_d" ] && cp -R "$TS3/x/engine/$_ts3_d" "$TS3K/1.0.0/$_ts3_d"; done
rm -rf "$TS3/x" "$TS3/x.tar"
_ts3_check "trust-step3: (fixture control) R's main holds the project's tables, the tools, MARKER and PROBE.txt, origin/main is main, the tools are executable, and the entry holds main's felix" \
  "$(git -C "$TS3R" ls-tree -r --name-only "$TS3_M" -- projects tools MARKER PROBE.txt .felix .gitignore 2>&1 | tr '\n' ' ')|$(_jr_sha "$TS3R" refs/remotes/origin/main)|$(git -C "$TS3R" ls-tree "$TS3_M" tools/ 2>/dev/null | LC_ALL=C awk '{ print $1 }' | tr '\n' ' ')|$(cmp -s "$TS3K/1.0.0/harness/felix" "$TS3R/engine/harness/felix" && echo entry)" \
  ".felix .gitignore MARKER PROBE.txt projects/ts3/CLAUDE.md projects/ts3/commissioning.tsv projects/ts3/obligations.tsv projects/ts3/probes.tsv projects/ts3/project.json projects/ts3/risk.tsv tools/applies-fx tools/check-fx tools/lib.sh tools/probe-fx |$TS3_M|100755 100755 100644 100755 |entry"
_ts3_v="$( cd "$TS3R" && TS3_FXLOG="$TS3/fx.log" tools/check-fx >/dev/null 2>&1; printf '%s' "$?")"
_ts3_v="$_ts3_v|$( cd "$TS3R" && TS3_FXLOG="" bash tools/applies-fx >/dev/null 2>&1; printf '%s' "$?")|$( cd "$TS3R" && tools/probe-fx 2>&1)"
_ts3_check "trust-step3: (fixture control) in main's checkout tools/check-fx and tools/applies-fx exit 0 and tools/probe-fx lists PROBE.txt" \
  "$_ts3_v" "0|0|PROBE.txt"

# ------------------------------------------------------------- S2, controls ---
_ts3_case ts3-notes; printf 'notes the candidate adds\n' > "$TS3R/NOTES.md"; _ts3_commit "$TS3R" notes
_ts3_entry S2-unrelated; TS3_PCOPY="$(_ts3_pcopy)"; TS3_FXRAN="$(LC_ALL=C awk 'END { print NR }' "$TS3/fx.log" 2>/dev/null)"
_ts3_check "trust-step3: S2 (the subject is still the candidate's, control): a candidate that adds an unrelated file and changes no script passes the dry run" \
  "$(_ts3_passed)" "passed" "$(_ts3_why)"
_ts3_check "trust-step3: S2 (fixture control): in that run the fx evidence instrument ran and logged its \$0" \
  "$([ "${TS3_FXRAN:-0}" -gt 0 ] 2>/dev/null && echo ran || echo 'did not run')" "ran" "$(_ts3_why)"
_ts3_check "trust-step3: S2.3: in that run tools/check-fx ran as P's copy, from a felix-policy.* directory under the run's TMPDIR" \
  "$TS3_PCOPY" "yes" "fx log: $(tr '\n' ' ' < "$TS3/fx.log" 2>/dev/null)"

_ts3_case ts3-nomarker; _fx_git "$TS3R" rm -q MARKER >/dev/null 2>&1; _ts3_commit "$TS3R" no-marker
_ts3_entry S2-nomarker
_ts3_check "trust-step3: S2 (the subject is still the candidate's, control): a candidate that deletes MARKER and changes no script is refused with an obligations line for fx" \
  "$(_ts3_refused)|$(_ts3_bl obligations fx - -)" "refused|yes" "$(_ts3_why)"

# --------------------------------------------------- S2, P's instruments ---
_ts3_case ts3-applies; printf '#!/usr/bin/env bash\nexit 1\n' > "$TS3R/tools/applies-fx"
_fx_git "$TS3R" rm -q MARKER >/dev/null 2>&1; _ts3_commit "$TS3R" applies
_ts3_entry S2-applies
_ts3_check "trust-step3: S2 (an applies command): a candidate that rewrites tools/applies-fx to exit 1 and deletes MARKER is refused with an obligations line for fx" \
  "$(_ts3_refused)|$(_ts3_bl obligations fx - -)" "refused|yes" "$(_ts3_why)"

_ts3_case ts3-check; printf '#!/usr/bin/env bash\nexit 0\n' > "$TS3R/tools/check-fx"
_fx_git "$TS3R" rm -q MARKER >/dev/null 2>&1; _ts3_commit "$TS3R" check
_ts3_entry S2-evidence
_ts3_check "trust-step3: S2 (an evidence instrument): a candidate that rewrites tools/check-fx to exit 0 and deletes MARKER is refused with an obligations line for fx" \
  "$(_ts3_refused)|$(_ts3_bl obligations fx - -)" "refused|yes" "$(_ts3_why)"

_ts3_case ts3-closure; printf 'fx_check() { true; }\n' > "$TS3R/tools/lib.sh"
_fx_git "$TS3R" rm -q MARKER >/dev/null 2>&1; _ts3_commit "$TS3R" closure
_ts3_entry S2-closure
_ts3_check "trust-step3: S2 (the instrument's closure): a candidate that rewrites tools/lib.sh so fx_check is true, keeps tools/check-fx and deletes MARKER is refused with an obligations line for fx" \
  "$(_ts3_refused)|$(_ts3_bl obligations fx - -)" "refused|yes" "$(_ts3_why)"

_ts3_case ts3-probe; printf '#!/usr/bin/env bash\nprintf '"'"'member\\n'"'"'\nexit 0\n' > "$TS3R/tools/probe-fx"
_fx_git "$TS3R" rm -q PROBE.txt >/dev/null 2>&1; _ts3_commit "$TS3R" probe
_ts3_v="$( cd "$TS3R" && tools/probe-fx 2>&1)|$( cd "$TS3R" && test -d tools; printf '%s' "$?")|$( cd "$TS3R" && git show "$TS3_M:tools/probe-fx" > "$TS3/p-probe" 2>/dev/null && bash "$TS3/p-probe" 2>&1)"
_ts3_check "trust-step3: S2 (a probe) (fixture control): over the candidate's tree its own tools/probe-fx lists a member, the witness exits 0, and P's tools/probe-fx lists nothing" \
  "$_ts3_v" "member|0|"
_ts3_entry S2-probe
_ts3_check "trust-step3: S2 (a probe): a candidate whose rewritten tools/probe-fx would pass, with P's probe and witness blocking over its tree, is refused with a probes line naming fxprobe" \
  "$(_ts3_refused)|$(_ts3_bl probes - fxprobe -)" "refused|yes" "$(_ts3_why)"

# ------------------------------------------------------------- S1, tables ---
_ts3_case ts3-table
LC_ALL=C awk -F'\t' '!($1 == "red" && $5 == "exfil")' "$TS3P/risk.tsv" > "$TS3/risk.tmp" && cat "$TS3/risk.tmp" > "$TS3P/risk.tsv"
mkdir -p "$TS3R/danger"; printf 'x\n' > "$TS3R/danger/x"; _ts3_commit "$TS3R" table
_ts3_entry S1-candidate-table
_ts3_check "trust-step3: S1 (a table in the candidate): checked out in the home, a candidate that removes the exfil row from risk.tsv and adds danger/x is refused with an escape line naming exfil and danger/x" \
  "$(_ts3_refused)|$(_ts3_bl escape - exfil danger/x)" "refused|yes" "$(_ts3_why)"

( _fx_cd "$TS3R" && git checkout -q -f main ) >/dev/null 2>&1
_fx_git "$TS3R" worktree add -q -b ts3-wt "$TS3W" main >/dev/null 2>&1
LC_ALL=C awk -F'\t' '!($1 == "red" && $5 == "exfil")' "$TS3P/risk.tsv" > "$TS3/risk.tmp" && cat "$TS3/risk.tmp" > "$TS3P/risk.tsv"
mkdir -p "$TS3W/danger"; printf 'x\n' > "$TS3W/danger/x"; _ts3_commit "$TS3W" wt-danger
_ts3_check "trust-step3: S1 (the home's uncommitted edit) (fixture control): R stays on main with risk.tsv's exfil row removed and uncommitted, and the worktree's branch adds danger/x" \
  "$(git -C "$TS3R" rev-parse --abbrev-ref HEAD 2>&1)|$(git -C "$TS3R" status --porcelain 2>&1 | tr '\n' ' ')|$(LC_ALL=C awk -F'\t' '$5 == "exfil" { n++ } END { print n + 0 }' "$TS3P/risk.tsv")|$(git -C "$TS3W" diff --name-only main HEAD 2>&1 | tr '\n' ' ')" \
  "main| M projects/ts3/risk.tsv |0|danger/x "
_ts3_entry S1-home-uncommitted "$TS3W"
_ts3_check "trust-step3: S1 (the home's uncommitted edit): the candidate in a worktree of R adds danger/x while the home's risk.tsv lacks the exfil row uncommitted, and is refused with an escape line naming exfil (and danger/x)" \
  "$(_ts3_refused)|$(_ts3_bl escape - exfil danger/x)" "refused|yes" "$(_ts3_why)"
_fx_git "$TS3R" worktree remove --force "$TS3W" >/dev/null 2>&1; rm -rf "${TS3W:?}"
( _fx_cd "$TS3R" && git checkout -q -- projects/ts3/risk.tsv && git worktree prune && git branch -q -D ts3-wt ) >/dev/null 2>&1

_ts3_case ts3-c9
LC_ALL=C awk '$0 == "  \"gate_workflow\": \"gate.yml\"" { print "  \"gate_workflow\": \"lint.yml\","; print; next } { print }' \
  "$TS3P/project.json" > "$TS3/pj.tmp" && cat "$TS3/pj.tmp" > "$TS3P/project.json"
_ts3_commit "$TS3R" c9; TS3_H="$(_jr_sha "$TS3R" HEAD)"
printf '[%s,%s]\n' "$(_ts3_ghrun 41 "$TS3_H" completed failure gate.yml ts3-c9)" "$(_ts3_ghrun 40 "$TS3_H" completed success lint.yml ts3-c9)" > "$TS3/calls/runs.json"
_ts3_c9a="trust-step3: S1 (the workflow C9 reads) (fixture control): the stub answers gate.yml's newest run on the head as failure and lint.yml's as success, and the candidate's project.json edit removes no line and puts lint.yml on the line before the last key"
_ts3_c9b="trust-step3: S1 (the workflow C9 reads): on a tests:reused receipt, a candidate whose project.json names lint.yml (success on the head) over P's gate.yml (failure) is refused with a not-green line for tests saying its run concluded failure"
if [ "$TS3_JQ" = 1 ]; then
  _ts3_v="$(TS3_GHDIR="$TS3/calls" "$TS3/gh/gh" run list --workflow gate.yml --commit "$TS3_H" --json conclusion -q '.[0].conclusion' 2>&1)"
  _ts3_v="$_ts3_v|$(TS3_GHDIR="$TS3/calls" "$TS3/gh/gh" run list --workflow lint.yml --commit "$TS3_H" --json conclusion -q '.[0].conclusion' 2>&1)"
  _ts3_v="$_ts3_v|removed $(git -C "$TS3R" diff main HEAD 2>/dev/null | LC_ALL=C awk '/^-/ && !/^---/ { n++ } END { print n + 0 }')"
  _ts3_check "$_ts3_c9a" "$_ts3_v|$(tail -n 3 "$TS3P/project.json" | tr '\n' ' ')" \
    "failure|success|removed 0|  \"gate_workflow\": \"lint.yml\",   \"gate_workflow\": \"gate.yml\" } "
  _ts3_entry S1-c9 "$TS3R" "syntax:ok,tests:reused,secret:ok"
  _ts3_check "$_ts3_c9b" "$(_ts3_refused)|$(_ts3_bl not-green tests 'concluded failure' -)" "refused|yes" \
    "$(_ts3_why); gh: $(tr '\n' ' ' < "$TS3/calls/calls")"
else
  skip "$_ts3_c9a" "no jq here for the gh stub"
  skip "$_ts3_c9b" "no jq here for the gh stub"
fi
printf '[]\n' > "$TS3/calls/runs.json"

( _fx_cd "$TS3R" && git checkout -q -f -B ts3-nopolicy main && git rm -r -q projects/ts3 ) >/dev/null 2>&1
_ts3_commit "$TS3R" no-policy; TS3_M2="$(_jr_sha "$TS3R" HEAD)"
_ts3_case ts3-closed; printf 'notes the candidate adds\n' > "$TS3R/NOTES.md"; _ts3_commit "$TS3R" closed
_fx_git "$TS3R" update-ref refs/remotes/origin/main "$TS3_M2" >/dev/null 2>&1
_ts3_check "trust-step3: S1 (fail closed) (fixture control): origin/main names a commit without projects/ts3, which the candidate's working tree holds, and with the same engine as main" \
  "$(git -C "$TS3R" ls-tree -d --name-only refs/remotes/origin/main -- projects/ts3 2>&1)|$([ -f "$TS3P/obligations.tsv" ] && echo present)|$(git -C "$TS3R" rev-parse "$TS3_M:engine" "$TS3_M2:engine" 2>/dev/null | LC_ALL=C sort -u | LC_ALL=C awk 'END { print NR }')" \
  "|present|1"
_ts3_entry S1-closed
_ts3_check "trust-step3: S1 (fail closed): with the home's project directory not at BASE, the dry run is refused with a policy line" \
  "$(_ts3_refused)|$(_ts3_bl policy - - -)" "refused|yes" "$(_ts3_why)"
_fx_git "$TS3R" update-ref refs/remotes/origin/main "$TS3_M" >/dev/null 2>&1

# ------------------------------------------------------------------- S1.7 ---
( _fx_cd "$TS3R" && git checkout -q -f main ) >/dev/null 2>&1
_fx_git "$TS3R" worktree add -q -b ts3-wt2 "$TS3W" main >/dev/null 2>&1
_fx_git "$TS3W" rm -q MARKER >/dev/null 2>&1; _ts3_commit "$TS3W" wt-no-marker
mkdir -p "$TS3H/projects"; cp -R "$TS3PP" "$TS3H/projects/ts3"
LC_ALL=C awk -F'\t' -v OFS='\t' '$1 == "fx" { $5 = "true" } { print }' "$TS3PP/obligations.tsv" > "$TS3H/projects/ts3/obligations.tsv"
_ts3_v="$(git -C "$TS3H" rev-parse --git-dir >/dev/null 2>&1 && echo 'in a repository' || echo 'no repository')"
_ts3_v="$_ts3_v|$(LC_ALL=C awk -F'\t' '$1 == "fx" { print $5 }' "$TS3PP/obligations.tsv") -> $(LC_ALL=C awk -F'\t' '$1 == "fx" { print $5 }' "$TS3H/projects/ts3/obligations.tsv")"
_ts3_v="$_ts3_v|$(diff -r "$TS3PP" "$TS3H/projects/ts3" 2>&1 | LC_ALL=C awk '/^[<>]/ { n++ } END { print n + 0 }') lines differ"
_ts3_v="$_ts3_v|$(git -C "$TS3W" diff --name-status main HEAD 2>&1 | tr '\t\n' ' ;')"
_ts3_check "trust-step3: S1.7 (a home elsewhere) (fixture control): the plain home is in no repository, its project directory differs from P's only in the fx row's evidence contract, now true, and the worktree's branch only deletes MARKER" \
  "$_ts3_v" "no repository|tools/check-fx -> true|2 lines differ|D MARKER;"
TS3_RH="$TS3H"; TS3_RP="$TS3H/projects/ts3"
_ts3_entry S1.7-plain-home "$TS3W"
TS3_RH=""; TS3_RP=""
_ts3_check "trust-step3: S1.7 (a home elsewhere): with FELIX_HOME a plain directory whose fx row's evidence contract is true, a candidate in a worktree of R that deletes MARKER is refused with an obligations line for fx (P's row judged)" \
  "$(_ts3_refused)|$(_ts3_bl obligations fx - -)" "refused|yes" "$(_ts3_why)"
_fx_git "$TS3R" worktree remove --force "$TS3W" >/dev/null 2>&1; rm -rf "${TS3W:?}"
( _fx_cd "$TS3R" && git worktree prune && git branch -q -D ts3-wt2 ) >/dev/null 2>&1

# ------------------------------------------------------ review round 1 cases ---
_ts3_wt() {   # BRANCH FROM: a worktree of R at $TS3W on a new branch BRANCH off FROM, R itself back on main
  ( _fx_cd "$TS3R" && git checkout -q -f main ) >/dev/null 2>&1
  _fx_git "$TS3R" worktree add -q -b "$1" "$TS3W" "$2" >/dev/null 2>&1
}
_ts3_wt_done() {   # BRANCH: that worktree and its branch removed
  _fx_git "$TS3R" worktree remove --force "$TS3W" >/dev/null 2>&1; rm -rf "${TS3W:?}"
  ( _fx_cd "$TS3R" && git worktree prune && git branch -q -D "$1" ) >/dev/null 2>&1
}
_ts3_loosen() {   # DIR: the fx row's evidence contract in DIR/obligations.tsv becomes true
  LC_ALL=C awk -F'\t' -v OFS='\t' '$1 == "fx" { $5 = "true" } { print }' "$1/obligations.tsv" > "$TS3/ob.tmp" && cat "$TS3/ob.tmp" > "$1/obligations.tsv"
}
_ts3_ndiff() { diff -r "$1" "$2" 2>&1 | LC_ALL=C awk '/^[<>]/ { n++ } END { print n + 0 }'; }   # DIR DIR -> lines that differ
_ts3_ns() { git -C "$1" diff --name-status "$2" HEAD 2>&1 | tr '\t\n' ' ;'; }                   # REPO BASE -> what the branch changes

# S1.8: R/projects/ts3 a link, uncommitted, to a loosened copy under another name outside R.
_ts3_wt ts3-wt-link main; _fx_git "$TS3W" rm -q MARKER >/dev/null 2>&1; _ts3_commit "$TS3W" wt-link
mv "$TS3P" "$TS3/moved-ts3x"; _ts3_loosen "$TS3/moved-ts3x"; ln -s "$TS3/moved-ts3x" "$TS3P"
_ts3_check "trust-step3: S1.8 (a linked project directory) (fixture control): R is on main, R/projects/ts3 is an uncommitted link to a directory outside R under another name that differs from P's only in the fx row's evidence contract, now true, and the worktree's branch only deletes MARKER" \
  "$(git -C "$TS3R" rev-parse --abbrev-ref HEAD 2>&1)|$([ -L "$TS3P" ] && echo link)|$(readlink "$TS3P" 2>&1)|$(_ts3_ndiff "$TS3PP" "$TS3/moved-ts3x") lines differ|$(_ts3_ns "$TS3W" main)" \
  "main|link|$TS3/moved-ts3x|2 lines differ|D MARKER;"
TS3_RP="$TS3P"; _ts3_entry S1.8-linked "$TS3W"; TS3_RP=""
_ts3_check "trust-step3: S1.8 (a linked project directory): the candidate in a worktree of R deletes MARKER while the home's projects/ts3 is a link to a loosened copy, and is refused with an obligations line for fx" \
  "$(_ts3_refused)|$(_ts3_bl obligations fx - -)" "refused|yes" "$(_ts3_why)"
rm -f "$TS3P"; rm -rf "${TS3:?}/moved-ts3x"; ( _fx_cd "$TS3R" && git checkout -q -- projects/ts3 ) >/dev/null 2>&1
_ts3_wt_done ts3-wt-link

# S1.7, the name BASE gives: the candidate's .felix names ts32, which a plain home holds loosened.
TS3H2="$TS3/plainhome2"; mkdir -p "$TS3H2/projects" "$MEM/ts32"; cp -R "$TS3PP" "$TS3H2/projects/ts32"; _ts3_loosen "$TS3H2/projects/ts32"
LC_ALL=C awk -F'\t' '!($5 == "verifier" && index($3, "felix$"))' "$TS3PP/risk.tsv" > "$TS3H2/projects/ts32/risk.tsv"
_ts3_wt ts3-wt-name main; printf 'ts32\n' > "$TS3W/.felix"; _fx_git "$TS3W" rm -q MARKER >/dev/null 2>&1; _ts3_commit "$TS3W" wt-name
_ts3_check "trust-step3: S1.7 (the name BASE gives) (fixture control): the plain home is in no repository, its projects/ts32 is P's tables with the fx row's evidence contract true and no .felix row in risk.tsv, and the worktree's branch names ts32 in .felix and deletes MARKER" \
  "$(git -C "$TS3H2" rev-parse --git-dir >/dev/null 2>&1 && echo 'in a repository' || echo 'no repository')|$(LC_ALL=C awk -F'\t' '$1 == "fx" { print $5 }' "$TS3H2/projects/ts32/obligations.tsv")|.felix rows $(LC_ALL=C awk -F'\t' 'index($3, "felix$") { n++ } END { print n + 0 }' "$TS3PP/risk.tsv") -> $(LC_ALL=C awk -F'\t' 'index($3, "felix$") { n++ } END { print n + 0 }' "$TS3H2/projects/ts32/risk.tsv")|$(_ts3_ndiff "$TS3PP" "$TS3H2/projects/ts32") lines differ|$(_ts3_ns "$TS3W" main)|$(cat "$TS3W/.felix")" \
  "no repository|true|.felix rows 1 -> 0|3 lines differ|M .felix;D MARKER;|ts32"
TS3_RH="$TS3H2"; TS3_RP="$TS3H2/projects/ts32"; _ts3_entry S1.7-name "$TS3W"; TS3_RH=""; TS3_RP=""
_ts3_check "trust-step3: S1.7 (the name BASE gives): a candidate whose .felix names ts32, held loosened by a plain home, and which deletes MARKER, is refused by P's projects/ts3: an obligations line for fx or an escape line naming .felix" \
  "$(_ts3_refused)|$(if [ "$(_ts3_bl obligations fx - -)" = yes ] || [ "$(_ts3_bl escape - .felix -)" = yes ]; then echo yes; else echo no; fi)" "refused|yes" "$(_ts3_why)"
_ts3_wt_done ts3-wt-name

# S1.9: origin/main holds one more risk.tsv row than the home, which stands at the commit before it.
( _fx_cd "$TS3R" && git checkout -q -f -B ts3-p3 main ) >/dev/null 2>&1
printf 'yellow\tpath\t^extra/\ta row P holds and the home does not yet\n' >> "$TS3P/risk.tsv"; _ts3_commit "$TS3R" p3; TS3_M3="$(_jr_sha "$TS3R" HEAD)"
_fx_git "$TS3R" update-ref refs/remotes/origin/main "$TS3_M3" >/dev/null 2>&1
_ts3_wt ts3-wt-behind "$TS3_M3"; printf 'notes the candidate adds\n' > "$TS3W/NOTES.md"; _ts3_commit "$TS3W" wt-behind
_ts3_check "trust-step3: S1.9 (a home behind BASE) (fixture control): origin/main's risk.tsv has one row more than the home's working tree, the home's HEAD is the commit before origin/main, and the worktree's branch only adds NOTES.md" \
  "rows +$(( $(git -C "$TS3R" show refs/remotes/origin/main:projects/ts3/risk.tsv 2>/dev/null | LC_ALL=C awk 'END { print NR }') - $(LC_ALL=C awk 'END { print NR }' "$TS3P/risk.tsv") ))|$([ "$(_jr_sha "$TS3R" HEAD)" = "$(_jr_sha "$TS3R" refs/remotes/origin/main~1)" ] && echo behind by one)|$(_ts3_ns "$TS3W" refs/remotes/origin/main)" \
  "rows +1|behind by one|A NOTES.md;"
TS3_RP="$TS3P"; _ts3_entry S1.9-behind "$TS3W"
_ts3_check "trust-step3: S1.9 (a home behind BASE): with receipts recorded for the home as it stands, one commit behind origin/main, an unrelated candidate is refused with a not-green line whose subject is home" \
  "$(_ts3_refused)|$(_ts3_bl not-green home - -)" "refused|yes" "$(_ts3_why)"
( _fx_cd "$TS3R" && git merge -q --ff-only "$TS3_M3" ) >/dev/null 2>&1
_ts3_entry S1.9-brought "$TS3W"; TS3_RP=""
_ts3_check "trust-step3: S1.9 (a home behind BASE, control): with the home brought to origin/main and the receipts recorded again, the same candidate passes the dry run" \
  "$(_jr_sha "$TS3R" HEAD | cut -c1-12)|$(_ts3_passed)" "$(printf '%s' "$TS3_M3" | cut -c1-12)|passed" "$(_ts3_why)"
_ts3_wt_done ts3-wt-behind
( _fx_cd "$TS3R" && git reset -q --hard "$TS3_M" && git branch -q -D ts3-p3 ) >/dev/null 2>&1
_fx_git "$TS3R" update-ref refs/remotes/origin/main "$TS3_M" >/dev/null 2>&1

# S1.10: felix_merge_blockers called directly, loaded as part 1250's _gfcBlk loads it (and lib/policy.sh when the
# entry has one), over a candidate whose fx obligation fails, with an empty base and with a base naming no commit.
_ts3_case ts3-nobase; _fx_git "$TS3R" rm -q MARKER >/dev/null 2>&1; _ts3_commit "$TS3R" no-base
_ts3_blk() {   # BASE -> felix_merge_blockers' rows for the candidate in R, home R, in a fresh TMPDIR (left onto TS3_LEFT)
  local left
  TS3_TN=$((TS3_TN + 1)); mkdir -p "$TS3/t/$TS3_TN"; TS3T="$(cd "$TS3/t/$TS3_TN" && pwd -P)"
  ( cd "$TS3R" && FELIX_HOME="$TS3R" TMPDIR="$TS3T" GIT_ALLOW_PROTOCOL=file PATH="$TS3/gh:$PATH" TS3_GHDIR="$TS3/calls" bash -c '
      set -uo pipefail
      k="$1"
      for f in resolve verify review classify evidence escape; do . "$k/lib/$f.sh" 2>/dev/null || exit 3; done
      if [ -f "$k/lib/policy.sh" ]; then . "$k/lib/policy.sh" 2>/dev/null || exit 3; fi
      felix_merge_blockers "$2" "$3" "$4" "$5"
    ' _ "$TS3K/1.0.0/harness" "$TS3P" "$1" "$TS3R" "$TS3R" ) 2>/dev/null
  left="$(find "$TS3T" -name 'felix-policy.*' -print 2>/dev/null | tr '\n' ' ')"
  [ -z "$left" ] || TS3_LEFT="${TS3_LEFT}S1.10 [$1] left [$left]; "
  return 0
}
_ts3_rows() { LC_ALL=C awk -F'\t' -v a="$2" -v b="$3" '($1 == a || a == "-") && ($2 == b || b == "-") { n++ } END { print n + 0 }' <<< "$1"; }
_ts3_record "$TS3R"; TS3_B="$(_ts3_blk refs/remotes/origin/main)"
_ts3_check "trust-step3: S1.10 (no base) (fixture control): with BASE, the directly called judge prints an obligations row for fx over this candidate" \
  "$(_ts3_rows "$TS3_B" obligations fx)" "1" "rows: $(printf '%s' "$TS3_B" | tr '\t\n' '| ')"
TS3_B="$(_ts3_blk "")"
_ts3_check "trust-step3: S1.10 (an empty base, control): felix_merge_blockers called with an empty base prints the obligations row for fx and no policy row, as before this slice" \
  "obligations $(_ts3_rows "$TS3_B" obligations fx)|policy $(_ts3_rows "$TS3_B" policy -)" "obligations 1|policy 0" "rows: $(printf '%s' "$TS3_B" | tr '\t\n' '| ')"
TS3_B="$(_ts3_blk refs/heads/ts3-names-nothing)"
_ts3_check "trust-step3: S1.10 (no base): with a base that names no commit, felix_merge_blockers prints an unknown row and the obligations row for fx, as before this slice" \
  "unknown $([ "$(_ts3_rows "$TS3_B" unknown -)$(_ts3_rows "$TS3_B" - unknown)" != 00 ] && echo yes || echo no)|obligations $(_ts3_rows "$TS3_B" obligations fx)" \
  "unknown yes|obligations 1" "rows: $(printf '%s' "$TS3_B" | tr '\t\n' '| ')"
# <<< trust-step3-policy-from-p
