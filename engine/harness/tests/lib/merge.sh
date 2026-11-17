# tests/lib/merge.sh: the fixtures felix merge and felix receipt are driven against.
# Used by 0340 (builds the gh stub and the merge checkout, MR), 0350 (GHB and MR,
# for the race it injects between the receipt and the branch read) and 0360 (builds
# the staged repository, STG), which 0370 reads for its receipt.
# Moved from parts/0340-the-line-that-does-the-work.sh lines 15-36 (the gh stub)
# and 40-49 (the merge checkout), and from
# parts/0360-what-felix-merge-records-and-what-it-hands-g.sh lines 468-480 (the
# staged repository) and 487-495 (the source and test staged in it), all verbatim
# in the function bodies below.
# Definitions only. Each builder sets its variables first and does nothing more once
# its fixture is there, so in the serial run only 0340's and 0360's calls build.

# _merge_repo_build: GHB holds a `gh` that reproduces gh's refusal of a merge with
# no pull request selector; MR is a checkout with a github remote, two commits on
# main (base, c) and the .felix marker, which felix merge is run in.
# gh is stubbed rather than called. The point is not that gh works; it is
# that Felix hands it something it will accept, which is exactly the half no
# test covered.
_merge_repo_build() {
  GHB="$TMP/ghstub"; MR="$TMP/mergerepo"
  if [ ! -x "$GHB/gh" ]; then
    mkdir -p "$GHB"
    cat > "$GHB/gh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GHSTUB_LOG"
# The provider's two reads at the merge (lib/bind.sh, spec S5.2), answered from the checkout the stub runs in, with
# git at call time: the pull request open at this HEAD into GHSTUB_BASE (jr-mbase, the base every caller of this
# stub names through _mbase), and that branch at the commit it names here, remote-tracking ref first.
case "$*" in
  "pr view "*"--json number,state,baseRefName,headRefOid"*)
    printf '7\tOPEN\t%s\t%s\n' "${GHSTUB_BASE:-jr-mbase}" "$(git rev-parse HEAD)"; exit 0 ;;
  "api repos/"*"/git/ref/heads/"*)
    n="${2#*/git/ref/heads/}"
    printf 'commit\t%s\n' "$(git rev-parse --verify -q "refs/remotes/origin/$n^{commit}" || git rev-parse --verify -q "refs/heads/$n^{commit}")"
    exit 0 ;;
esac
case "$1 $2" in
  "pr view") printf '{"number":7,"state":"OPEN"}\n' ;;
  "pr merge")
    # Reproduce gh's own precondition rather than trusting it: --repo demands a
    # PR selector, and a selector is any bare argument after `merge`.
    sel=0; skip=0
    for a in "${@:3}"; do
      [ "$skip" -eq 1 ] && { skip=0; continue; }
      case "$a" in --repo|--body|--subject) skip=1 ;; --*) ;; *) sel=1 ;; esac
    done
    case " $* " in *" --repo "*) [ "$sel" -eq 1 ] || {
        echo "argument required when using the --repo flag" >&2; exit 1; } ;;
    esac
    printf 'merged\n' ;;
esac
exit 0
STUB
    chmod +x "$GHB/gh"
  fi

  # Its own checkout, because the main fixture is deliberately remote-less and
  # felix merge dies on "no github remote" long before it reaches gh.
  if [ ! -d "$MR/.git" ]; then
    mkdir -p "$MR"
    ( _fx_cd "$MR" && git init -q -b main \
      && git remote add origin https://github.com/example/widget.git )
    MR="$(cd "$MR" && pwd -P)"
    printf 'widget\n' > "$MR/.felix"; printf 'contents\n' > "$MR/WIDGET.txt"
    ( _fx_cd "$MR" && git add -A >/dev/null 2>&1 \
      && git -c user.name=t -c user.email=t@t commit -qm base >/dev/null 2>&1 )
    printf 'a change to merge\n' > "$MR/README.md"
    ( _fx_cd "$MR" && git add -A >/dev/null 2>&1 \
      && git -c user.name=t -c user.email=t@t commit -qm c >/dev/null 2>&1 )
  fi
  MR="$(cd "$MR" && pwd -P)"
}

# _staged_repo_build [state]: STG is a repository with a base commit (BASE_SHA) and
# one commit ahead of it, so that `base...HEAD` is non-empty and the fallback is
# dead. State "workflow", the default, stages a workflow file and commits nothing
# more. State "full" stages in addition a source file and its test, which is the
# state 0360 leaves it in after the evidence cases.
_staged_repo_build() {
  STG="$TMP/stagedrepo"
  if [ ! -d "$STG/.git" ]; then
    mkdir -p "$STG"
    ( _fx_cd "$STG" && git init -q -b main )
    STG="$(cd "$STG" && pwd -P)"
    printf 'widget\n' > "$STG/.felix"; printf 'x\n' > "$STG/seed.txt"
    ( _fx_cd "$STG" && git add -A >/dev/null 2>&1 && git -c user.name=t -c user.email=t@t commit -qm base >/dev/null 2>&1 )
    BASE_SHA="$( _fx_cd "$STG" && git rev-parse HEAD )"
    # A commit ahead of base, so `base...HEAD` is non-empty and the fallback is dead.
    printf 'notes\n' > "$STG/README.md"
    ( _fx_cd "$STG" && git add -A >/dev/null 2>&1 && git -c user.name=t -c user.email=t@t commit -qm ahead >/dev/null 2>&1 )

    mkdir -p "$STG/.github/workflows"
    printf 'on: push\n' > "$STG/.github/workflows/ci.yml"
    ( _fx_cd "$STG" && git add .github >/dev/null 2>&1 )   # staged, deliberately not committed
  else
    STG="$(cd "$STG" && pwd -P)"
    [ -n "${BASE_SHA:-}" ] || BASE_SHA="$( _fx_cd "$STG" && git rev-list --max-parents=0 HEAD )"
  fi
  [ "${1:-workflow}" = full ] || return 0
  [ -f "$STG/tests/test_a.py" ] && return 0
  mkdir -p "$STG/src" "$STG/tests"; printf 'x=1\n' > "$STG/src/a.py"
  ( _fx_cd "$STG" && git add src >/dev/null 2>&1 )
  printf 'def test_a(): pass\n' > "$STG/tests/test_a.py"
  ( _fx_cd "$STG" && git add tests >/dev/null 2>&1 )
}
