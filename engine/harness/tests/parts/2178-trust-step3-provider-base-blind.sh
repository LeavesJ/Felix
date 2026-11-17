# >>> trust-step3-provider-base
printf '\ntrust plane step 3, slice 2: what the merge judges is what the provider holds (spec-slice2 sections 1-2; blind)\n'
# Blind, written on 2026-11-08 from .felix/memory/felix/audits/2026-11-08-trust-plane-step3/spec-slice2.md, sections 0-2,
# before the change, by the spec's author, who has not read its implementation (lib/bind.sh, cmd_merge as changed).
# How to build R and drive felix merge was learned from part 2176 and tests/lib/judge-refs.sh. Every fixture is this
# part's own, under $TPB, and its memory $MEM/tpb is removed at the end; it adds nothing under $FROOT/projects.
#
# R is section 2's fixture: the harness under test as engine/ at 1.0.0, a github.com origin (example/tpb),
# refs/remotes/origin/main at main, projects/tpb/ with the obligation fx (tools/applies-fx; tools/check-fx, which sources
# tools/lib.sh, where fx_check is test -f MARKER) and risk.tsv's exfil row (^danger/), the entry K/1.0.0 cut from main.
# Main's history is two commits: M0 holds danger/x, and M (main) removes it; the graft case needs that. Each run records
# a green gate receipt and a commission receipt for the tree as it stands, read against P's project directory (part
# 2176's first reading), then runs `felix merge` (a merge) or `felix merge --dry-run` from K/1.0.0/harness/felix in R.
#
# Readings, where the spec leaves room:
# - The provider stub answers call A from ctl/a and call Q from ctl/q, one line per call in order (the last line again
#   after the list ends); ctl/a.exit or ctl/q.exit makes that call exit with the code it holds. The defaults: the pull
#   request open on main with R's HEAD as its head, and main at M. Any other pr view answers as _js_build's stub does.
# - The cases with another base (S5: --base, the local ref moved) take their candidate off the branch tpb-evil, whose
#   tools/lib.sh makes fx_check true, and record their receipts against tpb-evil's project directory, so that on an engine
#   without S5 nothing but the base stands between the candidate (MARKER deleted) and the squash: the home's tables,
#   checked out in R, are tpb-evil's, and P is tpb-evil.
# - The object whose loose file is rewritten is P's tools/lib.sh, not obligations.tsv: obligations.tsv is a commission
#   table, and slice 1's S1.9 refuses a P whose commission tables differ from the home's, for a reason of its own.
#   tools/lib.sh is an instrument P runs (slice 1, S2), so its rewritten body (fx_check is true) is what decides on an
#   engine without S6.
# - The replace ref replaces the candidate's own head commit with one whose tree is main's, so a diff read with
#   replacement on sees no change; the candidate adds danger/x, which the exfil row refuses.
# - "Naming both commits" is read as each commit's first seven hex digits on the line.
TPB="$TMP/tpb"; rm -rf "${TPB:?}"; mkdir -p "$TPB/repo" "$TPB/gh" "$TPB/home" "$TPB/kc" "$TPB/t" "$TPB/ctl"
TPB="$(cd "${TPB:?}" && pwd -P)"; TPBR="$TPB/repo"; TPBK="$TPB/kc"; TPBP="$TPB/repo/projects/tpb"
TPB_TN=0; TPBT=""; TPBRC=0; TPB_LEFT=""; TPB_RUNS=0; TPB_ENV=""; TPB_PDIR=""
mkdir -p "$MEM/tpb"

cat > "$TPB/gh/gh" <<'TPBGH'
#!/usr/bin/env bash
d="${TPB_GHDIR:?TPB_GHDIR is not set}"
printf '%s\n' "$*" >> "$d/calls"
case "${1:-} ${2:-}" in
  "pr view")
    case " $* " in
      *baseRefName*) [ ! -f "$d/a.exit" ] || exit "$(cat "$d/a.exit")"; cat "$d/a"; exit 0 ;;
    esac
    printf '{"number":7,"state":"OPEN"}\n'; exit 0 ;;
  "pr merge")    printf '%s\n' "${GIT_CONFIG_PARAMETERS-unset}" > "$d/pm.env"; printf 'merged\n'; exit 0 ;;
  "auth status") printf 'github.com\n  Logged in to github.com account example\n'; exit 0 ;;
  "repo view")   printf 'example/tpb\n'; exit 0 ;;
  api\ repos/*/git/ref/heads/*)
    [ ! -f "$d/q.exit" ] || exit "$(cat "$d/q.exit")"
    n=0; [ -f "$d/q.n" ] && n="$(cat "$d/q.n")"; n=$((n + 1)); printf '%s\n' "$n" > "$d/q.n"
    l="$(sed -n "${n}p" "$d/q")"; [ -n "$l" ] || l="$(tail -1 "$d/q")"
    printf '%s\n' "$l"; exit 0 ;;
esac
exit 0
TPBGH
chmod +x "$TPB/gh/gh"

# ------------------------------------------------------------------ helpers ---
_tpb_check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]${4:+: $4}"; fi; }   # NAME GOT WANT [DETAIL]
_tpb_why() { printf 'exit %s; out: %s; err: %s; calls: %s' "$TPBRC" "$(head -c 900 "$TPB/out" 2>/dev/null | tr '\n' ' ')" \
  "$(head -c 300 "$TPB/err" 2>/dev/null | tr '\n' ' ')" "$(cut -c1-60 "$TPB/ctl/calls" 2>/dev/null | head -8 | tr '\n' '|')"; }
_tpb_refused() {   # -> refused when the last run exited non-zero and printed not merging, else what it did
  if [ "$TPBRC" -ne 0 ] && [ "$(cat "$TPB/out" "$TPB/err" | LC_ALL=C awk 'index($0, "not merging") { n++ } END { print n + 0 }')" -gt 0 ]; then
    printf 'refused'
  else printf 'exit %s' "$TPBRC"; fi
}
_tpb_passed() {   # -> passed when the last run exited 0 saying felix merge would squash this now.
  if [ "$TPBRC" -eq 0 ] && [ "$(LC_ALL=C awk 'index($0, "felix merge would squash this now.") { n++ } END { print n + 0 }' "$TPB/out")" -gt 0 ]; then
    printf 'passed'
  else printf 'exit %s' "$TPBRC"; fi
}
_tpb_pm() { LC_ALL=C awk 'index($0, "pr merge ") == 1 { n++ } END { print n + 0 }' "$TPB/ctl/calls" 2>/dev/null; }   # -> pr merge lines
_tpb_merged() {   # H -> merged when the last run exited 0 and the log holds one pr merge line carrying --match-head-commit H
  local n; n="$(LC_ALL=C awk -v h="--match-head-commit $1" 'index($0, "pr merge ") == 1 && index($0, h) { c++ } END { print c + 0 }' "$TPB/ctl/calls")"
  if [ "$TPBRC" -eq 0 ] && [ "$n" -eq 1 ] && [ "$(_tpb_pm)" -eq 1 ]; then printf 'merged'; else printf 'exit %s, %s pr merge lines' "$TPBRC" "$(_tpb_pm)"; fi
}
_tpb_asked() {   # -> "A Q": how many call-A and call-Q lines the last run's log holds
  LC_ALL=C awk 'index($0, "pr view ") == 1 && index($0, "baseRefName") { a++ } index($0, "api repos/") == 1 && index($0, "/git/ref/heads/") { q++ }
    END { printf "%d %d", a, q }' "$TPB/ctl/calls" 2>/dev/null
}
_tpb_bl() {   # KIND NAME WORD WORD2 -> yes when the last run printed a blocker line of KIND whose second field is NAME
              # (- for any) and that holds WORD and WORD2 (- for none), else no
  cat "$TPB/out" "$TPB/err" | LC_ALL=C awk -v k="$1" -v nm="$2" -v a="$3" -v b="$4" '
    index($0, "  ") == 1 && $1 == k && (nm == "-" || $2 == nm) && (a == "-" || index($0, a)) && (b == "-" || index($0, b)) { f = 1 }
    END { print (f ? "yes" : "no") }'
}
_tpb_commit() {   # REPO MSG: one commit of everything, with maintenance off
  _fx_git "$1" add -A >/dev/null 2>&1
  _fx_git "$1" -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c maintenance.auto=false commit -qm "$2" >/dev/null 2>&1
}
_tpb_case() { ( _fx_cd "$TPBR" && git checkout -q -f main && git checkout -q -B "$1" "${2:-main}" ) >/dev/null 2>&1; }   # BRANCH [FROM]
_tpb_record() {   # REPO PDIR: a green gate receipt and a commission receipt for REPO as it stands, home R, read against PDIR
  local p="$2"
  ( cd "$1" && FELIX_HOME="$TPBR"; . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/epoch.sh"
    felix_verify_record "$1" "$TPBR" 0 "true" "$(felix_tree_id "$1" "$TPBR")" "" "" "$(felix_epoch "$p" "$1")" \
      "$(felix_epoch_components "$p" "$1" | cut -f2 | paste -sd, -)" ) >/dev/null 2>&1
  ( cd "$1" && FELIX_HOME="$TPBR"; FELIX_HOME_DIR="$TPBR"; . "$FROOT/harness/lib/commission.sh"
    _o="$(felix_commission_run "$p" "$1" -)"
    felix_commission_receipt_write "$TPBR" "$p" "$1" "$_o" "" ) >/dev/null 2>&1
}
_tpb_provider() {   # A-LINE Q-LINE...: what the stub answers next; clears the exit controls and the call-Q counter
  rm -f "$TPB/ctl/a.exit" "$TPB/ctl/q.exit" "$TPB/ctl/q.n"; printf '%s\n' "$1" > "$TPB/ctl/a"; shift
  : > "$TPB/ctl/q"; for _tpb_l in "$@"; do printf '%s\n' "$_tpb_l" >> "$TPB/ctl/q"; done
}
_tpb_a() { printf '7\t%s\tmain\t%s' "${2:-OPEN}" "$1"; }   # HEAD [STATE] -> a call-A answer
_tpb_q() { printf 'commit\t%s' "$1"; }                     # SHA -> a call-Q answer
_tpb_default() { _tpb_provider "$(_tpb_a "$(_jr_sha "$TPBR" HEAD)")" "$(_tpb_q "$TPB_M")"; }
# _tpb_run LABEL MODE [ARG...]: felix merge (MODE merge) or felix merge --dry-run (MODE dry) from the entry in R, home R,
# a fresh TMPDIR, after a fresh receipt read against TPB_PDIR (P's project directory by default); TPB_ENV, when set,
# is one NAME=VALUE more in its environment. What the run left under its TMPDIR goes onto TPB_LEFT.
_tpb_run() {
  local l="$1" mode="$2" left; shift 2
  _tpb_record "$TPBR" "${TPB_PDIR:-$TPBPP}"
  TPB_TN=$((TPB_TN + 1)); mkdir -p "$TPB/t/$TPB_TN"; TPBT="$(cd "$TPB/t/$TPB_TN" && pwd -P)"
  : > "$TPB/ctl/calls"
  if [ "$mode" = dry ]; then set -- --dry-run "$@"; fi
  ( cd "$TPBR" && env -u FELIX_KERNEL -u FELIX_MERGE_HANDED HOME="$TPB/home" PATH="$TPB/gh:$PATH" TPB_GHDIR="$TPB/ctl" \
      FELIX_HOME="$TPBR" FELIX_KERNEL_CACHE="$TPBK" TMPDIR="$TPBT" GIT_ALLOW_PROTOCOL=file ${TPB_ENV:+"$TPB_ENV"} \
      "$TPBK/1.0.0/harness/felix" merge "$@" ) > "$TPB/out" 2> "$TPB/err"; TPBRC=$?
  TPB_RUNS=$((TPB_RUNS + 1))
  if [ -d "$TPBT" ]; then
    left="$(find "$TPBT" -name 'felix-objects.*' -print 2>/dev/null | LC_ALL=C sed "s|^$TPBT/||" | tr '\n' ' ')"
    [ -z "$left" ] || TPB_LEFT="${TPB_LEFT}$l left [$left]; "
  fi
}
_tpb_loose() { printf '%s/%s/%s' "$2" "$(printf '%s' "$1" | cut -c1-2)" "$(printf '%s' "$1" | cut -c3-)"; }   # SHA OBJDIR -> its loose file
_tpb_rewrite() {   # FILE CONTENT: FILE, a loose object, rewritten to hold a blob of CONTENT under the name it already has
  chmod u+w "$1" 2>/dev/null
  perl -MCompress::Zlib -e 'my $c = $ARGV[0]; binmode STDOUT; print compress("blob " . length($c) . "\0" . $c)' "$2" > "$1"
}

# ---------------------------------------------------------------- fixture R ---
( _fx_cd "$TPBR" && git init -q -b main && git remote add origin https://github.com/example/tpb.git \
  && git config gc.auto 0 && git config maintenance.auto false ) >/dev/null 2>&1
_copy_content "$REAL_HARNESS" "$TPBR/engine/harness"; _copy_content "$REAL_HARNESS/../hooks" "$TPBR/engine/hooks"
[ -d "$REAL_HARNESS/../commands" ] && _copy_content "$REAL_HARNESS/../commands" "$TPBR/engine/commands"
mkdir -p "$TPBR/engine/.claude-plugin" "$TPBP" "$TPBR/tools" "$TPBR/.github/workflows" "$TPBR/danger"
printf '{ "name": "felix", "version": "1.0.0" }\n' > "$TPBR/engine/.claude-plugin/plugin.json"
printf 'state/\n*.log\n' > "$TPBR/.gitignore"; printf 'tpb\n' > "$TPBR/.felix"
printf '{\n  "name": "tpb",\n  "remote_match": "example.com/tpb",\n  "gate": "true",\n  "gate_workflow": "gate.yml"\n}\n' > "$TPBP/project.json"
printf '# tpb\n' > "$TPBP/CLAUDE.md"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$TPBP/probes.tsv"
printf 'fx\tRELEASE_BLOCKING\tdeterministic\ttools/applies-fx\ttools/check-fx\t-\ta reason\n' > "$TPBP/obligations.tsv"
printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n' > "$TPBP/commissioning.tsv"
cp "$REAL_HARNESS/templates/risk.tsv" "$TPBP/risk.tsv"
printf 'red\tpath\t^danger/\ta danger path\texfil\n' >> "$TPBP/risk.tsv"
printf '#!/usr/bin/env bash\n. "$(dirname "$0")/lib.sh"\nfx_check\n' > "$TPBR/tools/check-fx"
printf 'fx_check() { test -f MARKER; }\n' > "$TPBR/tools/lib.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TPBR/tools/applies-fx"
chmod 755 "$TPBR/tools/check-fx" "$TPBR/tools/applies-fx"
printf 'a marker the fx check reads\n' > "$TPBR/MARKER"
printf 'on: pull_request\njobs: {}\n' > "$TPBR/.github/workflows/gate.yml"
printf 'the danger file main once held\n' > "$TPBR/danger/x"
_tpb_commit "$TPBR" base0; TPB_M0="$(_jr_sha "$TPBR" HEAD)"
_fx_git "$TPBR" rm -q -r danger >/dev/null 2>&1; _tpb_commit "$TPBR" base; TPB_M="$(_jr_sha "$TPBR" HEAD)"
_fx_git "$TPBR" update-ref refs/remotes/origin/main "$TPB_M" >/dev/null 2>&1
# M2, a commit R holds one ahead of main (the provider's main in the stale and last-moment cases), on a branch of its own.
_tpb_case tpb-ahead; printf 'another change on main\n' > "$TPBR/OTHER.md"; _tpb_commit "$TPBR" ahead; TPB_M2="$(_jr_sha "$TPBR" HEAD)"
# E, the branch tpb-evil: main with fx_check made true. (An emptied obligations.tsv would not do: a ledger that
# admits no obligation is refused before any base is compared, so the base would not be what stops the candidate.)
_tpb_case tpb-evil; printf 'fx_check() { true; }\n' > "$TPBR/tools/lib.sh"; _tpb_commit "$TPBR" evil; TPB_E="$(_jr_sha "$TPBR" HEAD)"
( _fx_cd "$TPBR" && git checkout -q -f main ) >/dev/null 2>&1
mkdir -p "$TPB/p" "$TPB/pe"
_fx_git "$TPBR" archive -o "$TPB/p.tar" "$TPB_M" projects/tpb >/dev/null 2>&1 && tar -x -C "$TPB/p" -f "$TPB/p.tar"
_fx_git "$TPBR" archive -o "$TPB/pe.tar" "$TPB_E" projects/tpb >/dev/null 2>&1 && tar -x -C "$TPB/pe" -f "$TPB/pe.tar"
rm -f "$TPB/p.tar" "$TPB/pe.tar"; TPBPP="$TPB/p/projects/tpb"; TPBPE="$TPB/pe/projects/tpb"
rm -rf "$TPBK/1.0.0" "$TPB/x" "$TPB/x.tar"; mkdir -p "$TPBK/1.0.0" "$TPB/x"
_fx_git "$TPBR" archive -o "$TPB/x.tar" "$TPB_M" engine >/dev/null 2>&1 && tar -x -C "$TPB/x" -f "$TPB/x.tar"
for _tpb_d in harness hooks commands .claude-plugin; do [ -d "$TPB/x/engine/$_tpb_d" ] && cp -R "$TPB/x/engine/$_tpb_d" "$TPBK/1.0.0/$_tpb_d"; done
rm -rf "$TPB/x" "$TPB/x.tar"
_tpb_check "ts3b: (fixture control) R's main holds the tables and tools without danger/x, M0 before it holds danger/x, origin/main is main, tpb-evil's fx_check is true, M2 is one ahead of main, and the entry holds main's felix" \
  "$(git -C "$TPBR" ls-tree -r --name-only "$TPB_M" -- projects tools MARKER danger 2>&1 | tr '\n' ' ')|$(git -C "$TPBR" ls-tree -r --name-only "$TPB_M0" -- danger 2>&1)|$(_jr_sha "$TPBR" refs/remotes/origin/main)|$(git -C "$TPBR" show "$TPB_E:tools/lib.sh" 2>&1)|$(git -C "$TPBR" rev-parse "$TPB_M2^" 2>&1)|$(cmp -s "$TPBK/1.0.0/harness/felix" "$TPBR/engine/harness/felix" && echo entry)" \
  "MARKER projects/tpb/CLAUDE.md projects/tpb/commissioning.tsv projects/tpb/obligations.tsv projects/tpb/probes.tsv projects/tpb/project.json projects/tpb/risk.tsv tools/applies-fx tools/check-fx tools/lib.sh |danger/x|$TPB_M|fx_check() { true; }|$TPB_M|entry"

# ------------------------------------------------------------------- S5 ---
_tpb_case tpb-notes; printf 'notes the candidate adds\n' > "$TPBR/NOTES.md"; _tpb_commit "$TPBR" notes; TPB_HN="$(_jr_sha "$TPBR" HEAD)"
_tpb_default; _tpb_run S5-control merge
_tpb_check "ts3b: S5 (control): an honest candidate whose pull request the provider holds open on main at M is merged, with --match-head-commit naming its head" \
  "$(_tpb_merged "$TPB_HN")" "merged" "$(_tpb_why)"
_tpb_check "ts3b: S5.1 (control): the squash body's Felix-Judge trailer names main's commit in full" \
  "$(LC_ALL=C awk -v m="$TPB_M" 'index($0, "Felix-Judge:") && index($0, m) { f = 1 } END { print (f ? "yes" : "no") }' "$TPB/ctl/calls")" "yes" "$(_tpb_why)"
# Not blind (slice 2's review): the engine's colour pin reaches the provider, a child of felix merge, past S6.1's scrub.
_tpb_check "ts3b-x: S6.1 (the engine's own pin survives the scrub): the gh that squashed saw GIT_CONFIG_PARAMETERS holding color.ui=never" \
  "$(LC_ALL=C awk 'index($0, "color.ui=never") { f = 1 } END { print (f ? "pinned" : "not pinned: " $0) }' "$TPB/ctl/pm.env" 2>/dev/null)" "pinned"

_tpb_case tpb-nomarker; _fx_git "$TPBR" rm -q MARKER >/dev/null 2>&1; _tpb_commit "$TPBR" no-marker
_tpb_default; _tpb_run S5-blockers merge
_tpb_check "ts3b: S5.5 (blockers first): a candidate that deletes MARKER is refused by the fx obligation, with no base or moved line, and the provider is not asked" \
  "$(_tpb_refused)|$(_tpb_bl obligations fx - -)|$(_tpb_bl base - - -)$(_tpb_bl moved - - -)|asked $(_tpb_asked)|pr merge $(_tpb_pm)" \
  "refused|yes|nono|asked 0 0|pr merge 0" "$(_tpb_why)"

_tpb_case tpb-evil-cand tpb-evil; _fx_git "$TPBR" rm -q MARKER >/dev/null 2>&1; _tpb_commit "$TPBR" evil-no-marker
TPB_PDIR="$TPBPE"; _tpb_default; _tpb_run S5-base merge --base refs/heads/tpb-evil
_tpb_check "ts3b: S5.3 (another base): judged with --base refs/heads/tpb-evil while the provider names main at M as the base, a candidate off tpb-evil that deletes MARKER is refused with a base line, and nothing is merged" \
  "$(_tpb_refused)|$(_tpb_bl base - - -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"
_tpb_default; _tpb_run S5-base-dry dry --base refs/heads/tpb-evil
_tpb_check "ts3b: S5.3 (another base, a dry run): the same, with --dry-run, is refused with a base line" \
  "$(_tpb_refused)|$(_tpb_bl base - - -)" "refused|yes" "$(_tpb_why)"
_fx_git "$TPBR" update-ref refs/remotes/origin/main "$TPB_E" >/dev/null 2>&1
_tpb_default; _tpb_run S5-ref-moved merge
_tpb_check "ts3b: S5.3 (the local ref moved): with refs/remotes/origin/main moved to tpb-evil and no --base, the same candidate is refused with a base line, and nothing is merged" \
  "$(_tpb_refused)|$(_tpb_bl base - - -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"
_fx_git "$TPBR" update-ref refs/remotes/origin/main "$TPB_M" >/dev/null 2>&1; TPB_PDIR=""

( _fx_cd "$TPBR" && git checkout -q -f tpb-notes ) >/dev/null 2>&1
_tpb_provider "$(_tpb_a "$TPB_M")" "$(_tpb_q "$TPB_M")"; _tpb_run S5-head merge
_tpb_check "ts3b: S5.3 (the head differs): the provider names a head commit that is not the checkout's HEAD, and the merge is refused with a moved line, and nothing is merged" \
  "$(_tpb_refused)|$(_tpb_bl moved - - -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"

_tpb_default; printf '1\n' > "$TPB/ctl/q.exit"; _tpb_run S5-noq merge
_tpb_check "ts3b: S5.3 (no answer, in a merge): call Q exits 1, and an honest candidate is refused with a base line, and nothing is merged" \
  "$(_tpb_refused)|$(_tpb_bl base - - -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"
_tpb_default; printf '1\n' > "$TPB/ctl/a.exit"; _tpb_run S5-noa merge
_tpb_check "ts3b: S5.3 (no answer, in a merge): call A exits 1, and an honest candidate is refused with a base line, and nothing is merged" \
  "$(_tpb_refused)|$(_tpb_bl base - - -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"
_tpb_provider "$(_tpb_a "$TPB_HN" CLOSED)" "$(_tpb_q "$TPB_M")"; _tpb_run S5-closed merge
_tpb_check "ts3b: S5.2 (no answer, in a merge): call A answers the state CLOSED, and an honest candidate is refused with a base line, and nothing is merged" \
  "$(_tpb_refused)|$(_tpb_bl base - - -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"

_tpb_default; printf '1\n' > "$TPB/ctl/q.exit"; _tpb_run S5-noq-dry dry
_tpb_check "ts3b: S5.3 (no answer, in a dry run): call Q exits 1, and an honest candidate's dry run exits 0, says it was not compared with the provider, and still says felix merge would squash this now." \
  "$(_tpb_passed)|$(LC_ALL=C awk 'index($0, "not compared with the provider") { f = 1 } END { print (f ? "said" : "not said") }' "$TPB/out")" \
  "passed|said" "$(_tpb_why)"

_tpb_provider "$(_tpb_a "$TPB_HN")" "$(_tpb_q "$TPB_M")" "$(_tpb_q "$TPB_M2")"; _tpb_run S5-last merge
_tpb_check "ts3b: S5.4 (the base moves at the last moment): call Q answers M, then M2, and the merge is refused with a moved line after asking Q twice, and nothing is merged" \
  "$(_tpb_refused)|$(_tpb_bl moved - - -)|asked $(_tpb_asked | cut -d' ' -f2) Q|pr merge $(_tpb_pm)" "refused|yes|asked 2 Q|pr merge 0" "$(_tpb_why)"

_tpb_provider "$(_tpb_a "$TPB_HN")" "$(_tpb_q "$TPB_M2")"; _tpb_run S5-stale merge
_tpb_check "ts3b: S5.3 (a stale local ref): the provider's main is M2, one ahead of R's origin/main, and an honest candidate is refused with a base line naming both commits, and nothing is merged" \
  "$(_tpb_refused)|$(_tpb_bl base - "$(printf '%s' "$TPB_M" | cut -c1-7)" "$(printf '%s' "$TPB_M2" | cut -c1-7)")|pr merge $(_tpb_pm)" \
  "refused|yes|pr merge 0" "$(_tpb_why)"
_fx_git "$TPBR" update-ref refs/remotes/origin/main "$TPB_M2" >/dev/null 2>&1
_tpb_provider "$(_tpb_a "$TPB_HN")" "$(_tpb_q "$TPB_M2")"; _tpb_run S5-stale-fetched merge
_tpb_check "ts3b: S5.3 (a stale local ref, the remedy): with origin/main brought to M2 and fresh receipts, the same candidate is merged" \
  "$(_tpb_merged "$TPB_HN")" "merged" "$(_tpb_why)"
_fx_git "$TPBR" update-ref refs/remotes/origin/main "$TPB_M" >/dev/null 2>&1

# ------------------------------------------------------------------- S6 ---
( _fx_cd "$TPBR" && git checkout -q -f tpb-nomarker ) >/dev/null 2>&1
TPB_OBJ="$(git -C "$TPBR" rev-parse --path-format=absolute --git-path objects 2>/dev/null)"
TPB_LIB="$(git -C "$TPBR" rev-parse "$TPB_M:tools/lib.sh" 2>/dev/null)"; TPB_LF="$(_tpb_loose "$TPB_LIB" "$TPB_OBJ")"
cp -p "$TPB_LF" "$TPB/lib.loose" 2>/dev/null
_tpb_rewrite "$TPB_LF" 'fx_check() { true; }
'
_tpb_check "ts3b: S6.3 (an object whose content is not its name) (fixture control): with the loose file for main's tools/lib.sh rewritten, a plain git show of main's tools/lib.sh in R prints the rewritten body" \
  "$(git -C "$TPBR" show "$TPB_M:tools/lib.sh" 2>&1)" "fx_check() { true; }"
_tpb_default; _tpb_run S6-object merge
_tpb_check "ts3b: S6.3 (an object whose content is not its name): a candidate that deletes MARKER, with the loose file for P's tools/lib.sh rewritten so fx_check is true, is refused with an objects line naming that blob, and nothing is merged" \
  "$(_tpb_refused)|$(_tpb_bl objects - "$TPB_LIB" -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"
chmod u+w "$TPB_LF" 2>/dev/null; cat "$TPB/lib.loose" > "$TPB_LF"; chmod 444 "$TPB_LF" 2>/dev/null
_tpb_check "ts3b: S6 (fixture control): the loose file is put back, and main's tools/lib.sh reads as written again" \
  "$(git -C "$TPBR" show "$TPB_M:tools/lib.sh" 2>&1)" "fx_check() { test -f MARKER; }"

mkdir -p "$TPB/objcopy"; cp -R "$TPB_OBJ/." "$TPB/objcopy/" 2>/dev/null
_tpb_rewrite "$(_tpb_loose "$TPB_LIB" "$TPB/objcopy")" 'fx_check() { true; }
'
_tpb_check "ts3b: S6.1 (the caller's environment) (fixture control): git show of main's tools/lib.sh with GIT_OBJECT_DIRECTORY naming the copy prints the rewritten body, and without it the body as written" \
  "$(GIT_OBJECT_DIRECTORY="$TPB/objcopy" git -C "$TPBR" show "$TPB_M:tools/lib.sh" 2>&1)|$(git -C "$TPBR" show "$TPB_M:tools/lib.sh" 2>&1)" \
  "fx_check() { true; }|fx_check() { test -f MARKER; }"
TPB_ENV="GIT_OBJECT_DIRECTORY=$TPB/objcopy"; _tpb_default; _tpb_run S6-env merge; TPB_ENV=""
_tpb_check "ts3b: S6.1 (the caller's environment): a candidate that deletes MARKER, run with GIT_OBJECT_DIRECTORY naming a copy of R's objects where P's tools/lib.sh is rewritten, is refused by the fx obligation or an objects line, and nothing is merged" \
  "$(_tpb_refused)|$( [ "$(_tpb_bl obligations fx - -)$(_tpb_bl objects - - -)" != nono ] && echo line || echo 'no line')|pr merge $(_tpb_pm)" \
  "refused|line|pr merge 0" "$(_tpb_why)"

_tpb_case tpb-replaced; mkdir -p "$TPBR/danger"; printf 'the danger file main once held\n' > "$TPBR/danger/x"
_tpb_commit "$TPBR" danger; TPB_HR="$(_jr_sha "$TPBR" HEAD)"
TPB_F="$(_fx_git "$TPBR" -c user.name=t -c user.email=t@t commit-tree "$TPB_M^{tree}" -p "$TPB_M" -m same 2>/dev/null)"
_fx_git "$TPBR" replace "$TPB_HR" "$TPB_F" >/dev/null 2>&1; _fx_git "$TPBR" read-tree "$TPB_F" >/dev/null 2>&1
_tpb_check "ts3b: S6.2 (a replace ref) (fixture control): with the candidate's head replaced by a commit holding main's tree, and the index read from it, plain git diff --name-only main...HEAD and --cached in R print nothing, and HEAD is still the candidate's commit" \
  "[$(git -C "$TPBR" diff --name-only "$TPB_M...HEAD" 2>&1 | tr '\n' ' ')]|[$(git -C "$TPBR" diff --cached --name-only 2>&1 | tr '\n' ' ')]|$(_jr_sha "$TPBR" HEAD)" "[]|[]|$TPB_HR"
_tpb_default; _tpb_run S6-replace merge
_tpb_check "ts3b: S6.2 (a replace ref): a candidate that adds danger/x, its head replaced by a commit holding main's tree and its index read from that, is refused with an escape line naming danger/x, and nothing is merged" \
  "$(_tpb_refused)|$(_tpb_bl escape - danger/x -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"
_fx_git "$TPBR" replace -d "$TPB_HR" >/dev/null 2>&1; _fx_git "$TPBR" read-tree "$TPB_HR" >/dev/null 2>&1

_tpb_case tpb-regraft; mkdir -p "$TPBR/danger"; git -C "$TPBR" show "$TPB_M0:danger/x" > "$TPBR/danger/x" 2>/dev/null
_tpb_commit "$TPBR" danger-again; TPB_HG="$(_jr_sha "$TPBR" HEAD)"
_tpb_default; _tpb_run S6-graft-control merge
_tpb_check "ts3b: S6.2 (a graft, control): without a graft, a candidate that adds danger/x back with the bytes M0 held is refused with an escape line naming danger/x" \
  "$(_tpb_refused)|$(_tpb_bl escape - danger/x -)" "refused|yes" "$(_tpb_why)"
printf '%s %s\n' "$TPB_HG" "$TPB_M0" > "$TPBR/.git/info/grafts"
_tpb_check "ts3b: S6.2 (a graft) (fixture control): with the candidate's parent grafted onto M0, a plain git diff --name-only main...HEAD in R prints nothing" \
  "[$(git -C "$TPBR" diff --name-only "$TPB_M...HEAD" 2>/dev/null | tr '\n' ' ')]" "[]"
_tpb_default; _tpb_run S6-graft merge
_tpb_check "ts3b: S6.2 (a graft): the same candidate, with its parent grafted onto M0, is still refused with an escape line naming danger/x, and nothing is merged" \
  "$(_tpb_refused)|$(_tpb_bl escape - danger/x -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"
rm -f "$TPBR/.git/info/grafts"

# ------------------------------- not blind: fixtures for three surviving mutants ---
# The mutant run of 2026-11-08 left five mutants alive for want of a fixture (measurement, section 3). These build
# three of them, before git gc, while every object here is loose: M's tree left out of V (S6.3), the commits since M
# left out of V (S6.3), and the copy never read after it is checked (S6.4).
_tpb_rewrite_as() {   # FILE TYPE CONTENT: FILE, a loose object, rewritten to hold an object of TYPE and CONTENT
  chmod u+w "$1" 2>/dev/null
  perl -MCompress::Zlib -e 'my ($t, $c) = @ARGV; binmode STDOUT; print compress("$t " . length($c) . "\0" . $c)' "$2" "$3" > "$1"
}
# S6.3, M's tree: B4 and H4 both drop stale/z, which only their merge base M4 holds, so its blob is in no tree but M's.
_tpb_case tpb-m4; mkdir -p "$TPBR/stale"; printf 'only the merge base holds this\n' > "$TPBR/stale/z"; _tpb_commit "$TPBR" m4
TPB_M4="$(_jr_sha "$TPBR" HEAD)"; TPB_Z="$(git -C "$TPBR" rev-parse "$TPB_M4:stale/z" 2>/dev/null)"
_tpb_case tpb-b4 tpb-m4; _fx_git "$TPBR" rm -q -r stale >/dev/null 2>&1; _tpb_commit "$TPBR" b4; TPB_B4="$(_jr_sha "$TPBR" HEAD)"
_tpb_case tpb-h4 tpb-m4; _fx_git "$TPBR" rm -q -r stale >/dev/null 2>&1; printf 'h4\n' > "$TPBR/H4.md"; _tpb_commit "$TPBR" h4
TPB_H4="$(_jr_sha "$TPBR" HEAD)"; TPB_ZF="$(_tpb_loose "$TPB_Z" "$TPB_OBJ")"; cp -p "$TPB_ZF" "$TPB/z.loose" 2>/dev/null
_tpb_rewrite_as "$TPB_ZF" blob 'not what this name holds'
_tpb_check "ts3b-x: S6.3 (M's tree) (fixture control): the merge base of B4 and H4 is M4, stale/z is in neither B4's tree nor H4's, and its loose file now reads otherwise" \
  "$(git -C "$TPBR" merge-base "$TPB_B4" "$TPB_H4" 2>&1)|$(git -C "$TPBR" ls-tree -r --name-only "$TPB_B4" -- stale 2>&1)$(git -C "$TPBR" ls-tree -r --name-only "$TPB_H4" -- stale 2>&1)|$(git -C "$TPBR" show "$TPB_M4:stale/z" 2>&1)" \
  "$TPB_M4||not what this name holds"
_fx_git "$TPBR" update-ref refs/remotes/origin/main "$TPB_B4" >/dev/null 2>&1
_tpb_provider "$(_tpb_a "$TPB_H4")" "$(_tpb_q "$TPB_B4")"; _tpb_run X-mtree merge
_tpb_check "ts3b-x: S6.3 (M's tree): a candidate cut from an older main, whose merge base alone holds an object that does not hash to its name, is refused with an objects line naming it, and nothing is merged" \
  "$(_tpb_refused)|$(_tpb_bl objects - "$TPB_Z" -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"
chmod u+w "$TPB_ZF" 2>/dev/null; cat "$TPB/z.loose" > "$TPB_ZF"; chmod 444 "$TPB_ZF" 2>/dev/null
_fx_git "$TPBR" update-ref refs/remotes/origin/main "$TPB_M" >/dev/null 2>&1

# S6.3, the commits since M: a candidate of two commits, the first one's loose file rewritten with its parent kept.
_tpb_case tpb-two; printf 'one\n' > "$TPBR/TWO1.md"; _tpb_commit "$TPBR" two-1; TPB_T1="$(_jr_sha "$TPBR" HEAD)"
printf 'two\n' > "$TPBR/TWO2.md"; _tpb_commit "$TPBR" two-2
TPB_T1F="$(_tpb_loose "$TPB_T1" "$TPB_OBJ")"; cp -p "$TPB_T1F" "$TPB/t1.loose" 2>/dev/null
_tpb_rewrite_as "$TPB_T1F" commit "$(git -C "$TPBR" cat-file commit "$TPB_T1" 2>/dev/null | LC_ALL=C sed 's/^two-1$/not the message this name holds/')
"
_tpb_check "ts3b-x: S6.3 (the commits since M) (fixture control): the first commit's loose file now reads with another message and the same parent" \
  "$(git -C "$TPBR" log -1 --format='%s|%P' "$TPB_T1" 2>&1)" "not the message this name holds|$TPB_M"
_tpb_default; _tpb_run X-since merge
_tpb_check "ts3b-x: S6.3 (the commits since M): a candidate of two commits, the first of which does not hash to its name, is refused with an objects line naming it, and nothing is merged" \
  "$(_tpb_refused)|$(_tpb_bl objects - "$TPB_T1" -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"
chmod u+w "$TPB_T1F" 2>/dev/null; cat "$TPB/t1.loose" > "$TPB_T1F"; chmod 444 "$TPB_T1F" 2>/dev/null

# S6.4, the copy is read: a git ahead on PATH puts P's tools/lib.sh back as written before each pack-objects, so every
# copy is made from the bytes its name says, and rewrites it (fx_check true) after each index-pack, so the checkout
# holds the other bytes whenever the judgement reads. A run that reads the copy is refused by the fx obligation.
cp -p "$TPB_LF" "$TPB/lib.honest" 2>/dev/null; _tpb_rewrite "$TPB_LF" 'fx_check() { true; }
'; cp "$TPB_LF" "$TPB/lib.evil" 2>/dev/null; chmod u+w "$TPB_LF" 2>/dev/null; cat "$TPB/lib.honest" > "$TPB_LF"
_tpb_realgit="$(type -P git)"
cat > "$TPB/gh/git" <<TPBGIT6
#!/bin/bash
case " \$* " in
  *" pack-objects "*) chmod u+w "$TPB_LF" 2>/dev/null; cat "$TPB/lib.honest" > "$TPB_LF" ;;
  *" index-pack "*) "$_tpb_realgit" "\$@"; rc=\$?; chmod u+w "$TPB_LF" 2>/dev/null; cat "$TPB/lib.evil" > "$TPB_LF"
                    : > "$TPB/ctl/flipped"; exit \$rc ;;
esac
exec "$_tpb_realgit" "\$@"
TPBGIT6
chmod +x "$TPB/gh/git"; rm -f "$TPB/ctl/flipped"
( _fx_cd "$TPBR" && git checkout -q -f tpb-nomarker ) >/dev/null 2>&1
_tpb_default; _tpb_run X-copyread merge
_tpb_check "ts3b-x: S6.4 (the copy is read): with the checkout's loose file for P's tools/lib.sh rewritten after each copy is checked, a candidate that deletes MARKER is refused by the fx obligation, and nothing is merged" \
  "$(_tpb_refused)|$(_tpb_bl obligations fx - -)|pr merge $(_tpb_pm)|$([ -f "$TPB/ctl/flipped" ] && echo flipped)" "refused|yes|pr merge 0|flipped" "$(_tpb_why)"
rm -f "$TPB/gh/git" "$TPB/ctl/flipped"; chmod u+w "$TPB_LF" 2>/dev/null; cat "$TPB/lib.honest" > "$TPB_LF"; chmod 444 "$TPB_LF" 2>/dev/null
_tpb_check "ts3b-x: S6 (fixture control): the three rewritten loose files are put back, and main's tools/lib.sh reads as written" \
  "$(git -C "$TPBR" show "$TPB_M:tools/lib.sh" 2>&1)|$(git -C "$TPBR" cat-file -t "$TPB_T1" 2>&1)|$(git -C "$TPBR" show "$TPB_M4:stale/z" 2>&1)" \
  "fx_check() { test -f MARKER; }|commit|only the merge base holds this"


( _fx_cd "$TPBR" && git checkout -q -f main && git gc -q --prune=now ) >/dev/null 2>&1
_tpb_check "ts3b: S6 (packed objects) (fixture control): after git gc, R holds no loose object for main's tools/lib.sh" \
  "$([ -e "$TPB_LF" ] && echo loose || echo packed)" "packed"
_tpb_case tpb-notes2; printf 'more notes\n' > "$TPBR/NOTES2.md"; _tpb_commit "$TPBR" notes2; TPB_HN2="$(_jr_sha "$TPBR" HEAD)"
_tpb_default; _tpb_run S6-packed merge
_tpb_check "ts3b: S6 (packed objects, a control for false blocks): after git gc, an honest candidate is merged" \
  "$(_tpb_merged "$TPB_HN2")" "merged" "$(_tpb_why)"

# ------------------------------------- not blind: the mutant run (slice 2 review) ---
# Written by the mutation run of 2026-11-08 after the blind part, each to kill a mutant the blind cases let
# survive (the measurement, section 3, names them). The labels say ts3b-x to keep them apart from the blind ones.
# ---------------------------------------------- extra cases (mutation run) ---
# Spec S5.2: answers that are not answers; S5.3/S5.4: ids that share only a prefix with B; S5.1: a ref moved mid-run.
_tpb_x7="$(printf '%s' "$TPB_M" | cut -c1-7)$(printf '%s' "$TPB_M" | cut -c8- | tr '0-9a-f' '1-9a-f0')"
_tpb_provider "$(_tpb_a "$TPB_HN2")" "$(_tpb_q "$_tpb_x7")"; _tpb_run X-q7 merge
_tpb_check "ts3b-x: S5.3 (Q names a commit that shares only B's first seven digits): refused with a base line, nothing merged" \
  "$(_tpb_refused)|$(_tpb_bl base - - -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"
_tpb_provider "$(_tpb_a "$TPB_HN2")" "$(_tpb_q "$TPB_M")" "$(_tpb_q "$_tpb_x7")"; _tpb_run X-last7 merge
_tpb_check "ts3b-x: S5.4 (the second Q shares only B's first seven digits): refused with a moved line, nothing merged" \
  "$(_tpb_refused)|$(_tpb_bl moved - - -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"
_tpb_provider "$(_tpb_a "$TPB_HN2")" "$(_tpb_q "$TPB_M")" "nonsense"; _tpb_run X-lastnone merge
_tpb_check "ts3b-x: S5.4 (the second Q gives no answer): refused with a moved line, nothing merged" \
  "$(_tpb_refused)|$(_tpb_bl moved - - -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"
_tpb_provider "$(_tpb_a "$TPB_HN2")" "$(printf 'tag\t%s' "$TPB_M")"; _tpb_run X-qtag merge
_tpb_check "ts3b-x: S5.2 (Q answers type tag, not commit): no answer, refused with a base line, nothing merged" \
  "$(_tpb_refused)|$(_tpb_bl base - - -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"
_tpb_provider "$(printf 'x7\tOPEN\tmain\t%s' "$TPB_HN2")" "$(_tpb_q "$TPB_M")"; _tpb_run X-anum merge
_tpb_check "ts3b-x: S5.2 (A's number is not digits only): no answer, refused with a base line, nothing merged" \
  "$(_tpb_refused)|$(_tpb_bl base - - -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"
_tpb_provider "$(printf '7\tOPEN\tma..in\t%s' "$TPB_HN2")" "$(_tpb_q "$TPB_M")"; _tpb_run X-abase merge
_tpb_check "ts3b-x: S5.2 (A's base name fails git check-ref-format --branch): no answer, refused with a base line, nothing merged" \
  "$(_tpb_refused)|$(_tpb_bl base - - -)|pr merge $(_tpb_pm)" "refused|yes|pr merge 0" "$(_tpb_why)"

# S5.1: refs/remotes/origin/main moves to tpb-evil right after the pin's own read of B (a git on PATH ahead of the real
# one moves it once, after the first call that names $TPB_M^{commit}). A run that judges B is refused by fx, with no base line.
( _fx_cd "$TPBR" && git checkout -q -f tpb-nomarker ) >/dev/null 2>&1
_tpb_realgit="$(type -P git)"
cat > "$TPB/gh/git" <<TPBGIT
#!/bin/bash
case " \$* " in
  *" $TPB_M^{commit} "*)
    c=\$(cat "$TPB/ctl/mc" 2>/dev/null || echo 0); c=\$((c + 1)); echo "\$c" > "$TPB/ctl/mc"
    if [ -f "$TPB/ctl/move" ] && [ ! -f "$TPB/ctl/moved" ] && [ "\$c" -eq 2 ]; then
      "$_tpb_realgit" "\$@"; rc=\$?; : > "$TPB/ctl/moved"
      "$_tpb_realgit" -C "$TPBR" update-ref refs/remotes/origin/main "$TPB_E" >/dev/null 2>&1; exit \$rc
    fi ;;
esac
exec "$_tpb_realgit" "\$@"
TPBGIT
chmod +x "$TPB/gh/git"; : > "$TPB/ctl/move"; rm -f "$TPB/ctl/moved" "$TPB/ctl/mc"
_tpb_default; _tpb_run X-refmove merge
_tpb_check "ts3b-x: S5.1 (the ref moves after the pin): refused by the fx obligation, with no base line, the move having happened" \
  "$(_tpb_refused)|$(_tpb_bl obligations fx - -)|$(_tpb_bl base - - -)|pr merge $(_tpb_pm)|$([ -f "$TPB/ctl/moved" ] && echo moved)|$(_jr_sha "$TPBR" refs/remotes/origin/main)" \
  "refused|yes|no|pr merge 0|moved|$TPB_E" "$(_tpb_why)"
rm -f "$TPB/gh/git" "$TPB/ctl/move" "$TPB/ctl/moved" "$TPB/ctl/mc"; _fx_git "$TPBR" update-ref refs/remotes/origin/main "$TPB_M" >/dev/null 2>&1

_tpb_check "ts3b: S6.5: no felix-objects.* entry remains under any run's TMPDIR after it ends" "runs $TPB_RUNS|left [$TPB_LEFT]" "runs $TPB_RUNS|left []"

( _fx_cd "$TPBR" && git checkout -q -f main ) >/dev/null 2>&1
rm -rf "$MEM/tpb" "${TPB:?}"
# <<< trust-step3-provider-base
