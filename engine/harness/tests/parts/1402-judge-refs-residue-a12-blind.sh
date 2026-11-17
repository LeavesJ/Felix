# >>> judge-refs-residue-a12
printf '\njudge refs and residue: felix merge refuses a base it cannot resolve by full name (contract A12, blind)\n'
# Blind, from item A12 of docs/2026-10-18-judge-refs-residue-contract.md and
# the coordinator's cases for it. Not read: lib/resolve.sh, lib/exceptions.sh,
# the merge body of the felix CLI, and projects/felix/gate.sh. The merge is
# driven as part 1400's A9 drives it (0340's self-governed shape). The phrase
# "full ref name" is the coordinator's wording for case 3. This part builds
# its own fixture and project, jr12, and removes both at its end.
#
# The checkout: m0 (this tree's engine, 1.0.0) <- m1 (main, and
# refs/remotes/origin/main) <- the prose branch, checked out. d1 is off m1, and
# its resolve.sh defines a felix_accepted_deploy_diff that writes a line to
# $J12/decoy-ran, prints the entry and exits 0; d2 is a child of d1. The cache
# entry for 1.0.0 is cut from m1, so with a base read by full name every dry
# run below passes the judge, and the only thing a case changes is --base.
J12="$TMP/jr12"; J12K="$J12/kc"; J12LOG="$J12/decoy-ran"
mkdir -p "$J12/repo" "$J12/gh" "$J12K"; J12R="$(cd "$J12/repo" && pwd -P)"
_j12_commit() {   # REPO MSG FILE TEXT: FILE written with TEXT, then one commit of everything
  mkdir -p "$(dirname "$1/$3")"; printf '%s\n' "$4" > "$1/$3"
  _fx_git "$1" add -A >/dev/null 2>&1
  _fx_git "$1" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm "$2" >/dev/null 2>&1
}
_j12_sha() { git -C "$1" rev-parse --verify -q "$2^{commit}" 2>/dev/null; }   # REPO REV -> its commit, or nothing
_j12_on()  { local s="$1" f; shift; for f in "$@"; do _fx_git "$J12R" update-ref "$f" "$s" >/dev/null 2>&1; done; }
_j12_off() { local f; for f in "$@"; do _fx_git "$J12R" update-ref -d "$f" >/dev/null 2>&1; done; }

J12P="$FROOT/projects/jr12"; mkdir -p "$J12P" "$MEM/jr12"
printf '{\n  "name": "jr12",\n  "remote_match": "example.com/jr12",\n  "gate": "true"\n}\n' > "$J12P/project.json"
printf '# jr12\n' > "$J12P/CLAUDE.md"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$J12P/probes.tsv"
printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds\n' > "$J12P/obligations.tsv"
printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n' > "$J12P/commissioning.tsv"
cp "$REAL_HARNESS/templates/risk.tsv" "$J12P/risk.tsv"
_j12_record() {   # a green gate receipt and a commissioning stamp for the checkout as it stands
  ( cd "$J12R" && . "$FROOT/harness/lib/verify.sh"
    felix_verify_record "$J12R" "$FROOT" 0 "true" "$(felix_tree_id "$J12R" "$FROOT")" ) >/dev/null 2>&1
  ( cd "$J12R" && FELIX_HOME_DIR="$FROOT"; . "$FROOT/harness/lib/commission.sh"
    _o="$(felix_commission_run "$J12P" "$J12R" -)"
    felix_commission_receipt_write "$FROOT" "$J12P" "$J12R" "$_o" "" ) >/dev/null 2>&1
}
cat > "$J12/gh/gh" <<'J12STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GHSTUB_LOG"
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
case "$1 $2" in "pr view") printf '{"number":7,"state":"OPEN"}\n' ;; "pr merge") printf 'merged\n' ;; esac
exit 0
J12STUB
chmod +x "$J12/gh/gh"

( _fx_cd "$J12R" && git init -q -b main && git remote add origin https://github.com/example/jr12.git ) >/dev/null 2>&1
_copy_content "$REAL_HARNESS" "$J12R/engine/harness"; _copy_content "$REAL_HARNESS/../hooks" "$J12R/engine/hooks"
[ -d "$REAL_HARNESS/../commands" ] && _copy_content "$REAL_HARNESS/../commands" "$J12R/engine/commands"
printf '*.log\n.DS_Store\n' > "$J12R/.gitignore"; printf 'jr12\n' > "$J12R/.felix"
_j12_commit "$J12R" base engine/.claude-plugin/plugin.json '{ "name": "felix", "version": "1.0.0" }'; J12_M0="$(_j12_sha "$J12R" HEAD)"
_j12_commit "$J12R" two README.md 'main, a second commit'; J12_M1="$(_j12_sha "$J12R" HEAD)"
_j12_on "$J12_M1" refs/remotes/origin/main
( _fx_cd "$J12R" && git checkout -q -b jr12-decoy "$J12_M1" ) >/dev/null 2>&1
printf '\nfelix_accepted_deploy_diff() { printf "%%s\\n" "J12-DECOY-RAN" >> "%s"; printf "%%s\\n" "%s"; return 0; }\n' \
  "$J12LOG" "$J12K/1.0.0" >> "$J12R/engine/harness/lib/resolve.sh"
_j12_commit "$J12R" decoy-judge engine/harness/DECOY 'the decoy'; J12_D1="$(_j12_sha "$J12R" HEAD)"
_j12_commit "$J12R" decoy-child d2.txt 'a child of the decoy'; J12_D2="$(_j12_sha "$J12R" HEAD)"
( _fx_cd "$J12R" && git checkout -q -b jr12-prose "$J12_M1" && git branch -q -D jr12-decoy ) >/dev/null 2>&1
_j12_commit "$J12R" prose NOTES.md 'prose notes'

_j12_entry() {   # -> the cache entry for 1.0.0 is m1's engine, cut from the commit
  rm -rf "$J12K/1.0.0" "$J12/x" "$J12/x.tar"; mkdir -p "$J12K/1.0.0" "$J12/x"
  _fx_git "$J12R" archive -o "$J12/x.tar" "$J12_M1" engine >/dev/null 2>&1 && tar -x -C "$J12/x" -f "$J12/x.tar"
  for _d in harness hooks commands .claude-plugin; do [ -d "$J12/x/engine/$_d" ] && cp -R "$J12/x/engine/$_d" "$J12K/1.0.0/$_d"; done
  rm -rf "$J12/x" "$J12/x.tar"
}
_j12_dry() {   # [BASE] -> J12RC and $J12/out: felix merge --dry-run (--base BASE when given), a fresh receipt first
  _j12_record; : > "$J12/gh.log"; : > "$J12LOG"
  if [ "$#" -gt 0 ]; then
    ( cd "$J12R" && env -u FELIX_KERNEL PATH="$J12/gh:$PATH" GHSTUB_LOG="$J12/gh.log" FELIX_KERNEL_CACHE="$J12K" \
        "$FELIX" merge --dry-run --base "$1" ) > "$J12/out" 2>&1; J12RC=$?
  else
    ( cd "$J12R" && env -u FELIX_KERNEL PATH="$J12/gh:$PATH" GHSTUB_LOG="$J12/gh.log" FELIX_KERNEL_CACHE="$J12K" \
        "$FELIX" merge --dry-run ) > "$J12/out" 2>&1; J12RC=$?
  fi
}
_j12_flags() {   # -> what the last dry run did: exit, the judge's acceptance, the decoy's code, the full-name phrase
  local e=0 a="" d="" f=""
  [ "$J12RC" -eq 0 ] || e=X
  ! LC_ALL=C grep -Fq 'byte-identical to main' "$J12/out" || a=accepted
  [ ! -s "$J12LOG" ] || d=decoy-ran
  ! LC_ALL=C grep -Fiq 'full ref name' "$J12/out" || f=full-ref-name
  printf '%s|%s|%s|%s' "$e" "$a" "$d" "$f"
}
_j12_why() { printf 'exit %s: %s' "$J12RC" "$(head -6 "$J12/out" | tr '\n' ' ')"; }
_j12_refused() {   # NAME -> ok when the last dry run exited non-zero, no judge accepted, and the decoy's code never ran
  local g; g="$(_j12_flags)"
  case "$g" in X\|\|\|*) ok "$1" ;; *) bad "$1" "expected [X|||any] got [$g], $(_j12_why)" ;; esac
}
_j12_fullname() {   # NAME -> as _j12_refused, and the output says it needs a full ref name
  local g; g="$(_j12_flags)"
  if [ "$g" = "X|||full-ref-name" ]; then ok "$1"; else bad "$1" "expected [X|||full-ref-name] got [$g], $(_j12_why)"; fi
}
_j12_passes() {   # NAME -> ok when the last dry run exited 0, the judge byte-identical to main, the decoy's code never ran
  local g; g="$(_j12_flags)"
  case "$g" in 0\|accepted\|\|*) ok "$1" ;; *) bad "$1" "expected [0|accepted||any] got [$g], $(_j12_why)" ;; esac
}
_j12_judged() {   # NAME -> ok when the last dry run exited non-zero saying the judge is not the engine main accepted
  local g j=""; g="$(_j12_flags)"
  ! LC_ALL=C grep -Fq 'the judge is not the engine main accepted' "$J12/out" || j=judge
  case "$g|$j" in X\|\|\|*\|judge) ok "$1" ;; *) bad "$1" "expected [X|||any|judge] got [$g|$j], $(_j12_why)" ;; esac
}

# ------------------------------------------------------- fixture controls ---
is "A12 (fixture control): m0, m1 (main and refs/remotes/origin/main), the prose branch checked out, and the decoy d1 off m1 with its child d2" \
   "$(_j12_sha "$J12R" refs/heads/main)|$(_j12_sha "$J12R" refs/remotes/origin/main)|$(_j12_sha "$J12R" HEAD~1)|$(_j12_sha "$J12R" "$J12_M1~1")|$(_j12_sha "$J12R" "$J12_D1~1")|$(_j12_sha "$J12R" "$J12_D2~1")|$(git -C "$J12R" rev-parse --abbrev-ref HEAD 2>&1)" \
   "$J12_M1|$J12_M1|$J12_M1|$J12_M0|$J12_M1|$J12_D1|jr12-prose"
is "A12 (fixture control): the decoy's resolve.sh, sourced on its own, prints the entry, exits 0 and leaves its line" \
   "$( ( : > "$J12LOG"; git -C "$J12R" show "$J12_D1:engine/harness/lib/resolve.sh" > "$J12/decoy.sh" 2>/dev/null; . "$J12/decoy.sh" >/dev/null 2>&1
        felix_accepted_deploy_diff "$J12R" main; printf '|%s|' "$?"; cat "$J12LOG" ) 2>/dev/null )" "$J12K/1.0.0
|0|J12-DECOY-RAN"
_j12_entry
_j12_dry
_j12_passes "A12 (4, control): with the default base and the cache entry main's engine, the dry run passes the judge as before"
_j12_dry main
_j12_passes "A12 (4, control): with --base main and refs/remotes/origin/main present, the dry run passes the judge as before"
_j12_dry origin/main
_j12_passes "A12 (4, control): with --base origin/main, the dry run passes the judge as before"
_j12_dry refs/remotes/origin/main
_j12_passes "A12 (4, control): with --base refs/remotes/origin/main, the dry run passes the judge as before"
printf '# one more line than main accepted\n' >> "$J12K/1.0.0/harness/lib/say.sh"
_j12_dry
_j12_judged "A12 (4, control): with the default base and the cache entry one comment off, the dry run refuses for the judge as before"
_j12_dry main
_j12_judged "A12 (4, control): with --base main and the cache entry one comment off, the dry run refuses for the judge as before"
_j12_entry

# ------------------- case 1: origin/X with no remote-tracking ref, a decoy ---
# refs/remotes/origin/jr12 never exists. Each decoy is a ref git's own
# short-name order reads for origin/jr12 (the last one is what prefixing
# origin/ to the name as given would reach).
for _j12_v in "refs/tags/origin/jr12" "refs/heads/origin/jr12" "refs/tags/origin/jr12 refs/heads/origin/jr12" \
              "refs/origin/jr12" "refs/remotes/origin/origin/jr12"; do
  _j12_on "$J12_D1" $_j12_v
  _j12_n="origin/jr12"; [ "$_j12_v" = "refs/remotes/origin/origin/jr12" ] && _j12_n="origin/origin/jr12"
  is "A12 (1, decoys: $_j12_v) (fixture control): there is no refs/remotes/origin/jr12, and git's own $_j12_n names the decoy" \
     "$(_j12_sha "$J12R" refs/remotes/origin/jr12)|$(_j12_sha "$J12R" "$_j12_n")" "|$J12_D1"
  _j12_dry origin/jr12
  _j12_refused "A12 (1, decoys: $_j12_v): felix merge --dry-run --base origin/jr12 refuses, no judge accepts, and the decoy's resolve.sh never runs"
  _j12_off $_j12_v
done

# ------------------------------------------- case 2: a base that is nowhere ---
for _j12_n in origin/jr12-nowhere jr12-nowhere refs/heads/jr12-nowhere refs/remotes/origin/jr12-nowhere; do
  _j12_dry "$_j12_n"
  _j12_refused "A12 (2): felix merge --dry-run --base $_j12_n, which names nothing, refuses and no judge accepts"
done
is "A12 (2) (fixture control): none of those names a commit" \
   "$(_j12_sha "$J12R" origin/jr12-nowhere)$(_j12_sha "$J12R" jr12-nowhere)$(_j12_sha "$J12R" refs/heads/jr12-nowhere)$(_j12_sha "$J12R" refs/remotes/origin/jr12-nowhere)" ""

# -------------------------------------- case 3: a name only A4 resolves ---
_j12_dry "$J12_M1"
_j12_fullname "A12 (3): felix merge --dry-run --base <main's own sha> refuses, saying it needs a full ref name"
_j12_dry HEAD~1
_j12_fullname "A12 (3): felix merge --dry-run --base HEAD~1, which is main's commit, refuses, saying it needs a full ref name"
_j12_dry main~1
_j12_fullname "A12 (3, no decoy): felix merge --dry-run --base main~1 refuses, saying it needs a full ref name"
_j12_on "$J12_D2" refs/tags/main
is "A12 (3, refs/tags/main at d2) (fixture control): git's own main~1 is the decoy d1, not main's m0" \
   "$(_j12_sha "$J12R" main~1 2>/dev/null)" "$J12_D1"
_j12_dry main~1
_j12_fullname "A12 (3, refs/tags/main at d2): felix merge --dry-run --base main~1 refuses, saying it needs a full ref name, and the decoy's resolve.sh never runs"
_j12_off refs/tags/main
_j12_dry main
_j12_passes "A12 (4, control): after the decoys are gone, --base main passes the judge again"

rm -rf "$J12P" "$MEM/jr12" "$J12"
