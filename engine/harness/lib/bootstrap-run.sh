# felix bootstrap: what it finds, what it holds back, and what it changes.
#
# The reads and writes against GitHub are in bootstrap-gh.sh; the workflow, the
# pin and the permission policy are in bootstrap.sh. This is the order they are
# used in, and the rule that joins them: a branch is made to require the `gate`
# check only when CI can pass it.
#
# CI can pass it when it can resolve the project. The workflow checks Felix out
# at a commit, and `felix which` there finds the project only in that checkout's
# own projects/. So the commit has to be on a Felix repository CI can fetch and
# has to hold projects/<name>. From a plain clone of someone else's Felix,
# `felix new` leaves projects/<name> untracked, the pin is empty, and no commit
# anywhere holds the project: a required check that fails at checkout on every
# pull request, whatever the code. Bootstrap says so, on the `ci project:` line,
# and holds the rule back until it is true. The same goes for a workflow that is
# not yet on the default branch (the check would never report, and every other
# pull request would wait on it) and one that still reads {{FELIX_REF}}.
#
# What CI runs is the workflow on the default branch, not what this machine
# would pin today. So when that workflow names its Felix checkout, it is judged
# by what it names: the repository it checks out has to be the one the engine
# checkout's origin names, and the commit it pins has to hold the project. A
# checkout that is a commit ahead of its origin, or behind it, does not make a
# workflow that is already right wrong. And what this clone has not fetched is
# not known, which is never read as absent.
#
# The branch is the repository's default branch as GitHub names it, not the
# branch the session has checked out: a worktree on claude/adopt-x used to
# protect claude/adopt-x and leave the default branch open.

# ENGINE_DIR: the commit of the engine checkout's origin default branch (origin's
# HEAD, else origin/main), or nothing and status 1.
_felix_bs_engine_default() {
  git -C "$1" rev-parse --verify -q 'refs/remotes/origin/HEAD^{commit}' 2>/dev/null \
    || git -C "$1" rev-parse --verify -q 'refs/remotes/origin/main^{commit}' 2>/dev/null
}

# NAME FELIX_REPO PIN ENGINE_DIR: whether the pin is a commit CI resolves the
# project from, in _bs_ci_ok (1 or 0), and when not, why, in _bs_ci_why (the
# reasons are in the order they are looked for). _bs_dt is the engine checkout's
# default branch and _bs_ci_dt is 1 when it holds the project. When it does and
# the pin does not, the engine checkout is the thing that is out of date, not
# the Felix repository, and _bs_ci_off says how: "not on" or "behind".
_felix_bs_ci_judge() {
  _bs_ci_ok=0; _bs_ci_why=""; _bs_ci_off=""; _bs_ci_dt=0; _bs_dt=""
  if [ -z "$2" ]; then _bs_ci_why="Felix has no GitHub remote for CI to fetch"; return 0; fi
  _bs_dt="$(_felix_bs_engine_default "$4")" || _bs_dt=""
  if [ -n "$_bs_dt" ] && git -C "$4" cat-file -e "$_bs_dt:projects/$1/project.json" 2>/dev/null; then _bs_ci_dt=1; fi
  if [ -z "$3" ]; then _bs_ci_why="no commit is pinned"
  elif git -C "$4" cat-file -e "$3:projects/$1/project.json" 2>/dev/null; then _bs_ci_ok=1; return 0
  else _bs_ci_why="the pinned commit does not hold projects/$1"; fi
  if [ "$_bs_ci_dt" -eq 1 ]; then
    if git -C "$4" merge-base --is-ancestor HEAD "$_bs_dt" 2>/dev/null; then _bs_ci_off=behind; else _bs_ci_off="not on"; fi
    _bs_ci_why="$_bs_ci_why: the engine checkout is $_bs_ci_off its default branch, which holds projects/$1"
  fi
}

# REPO_ROOT BRANCH WORKFLOW_FILE: how the gate workflow stands on origin/BRANCH as
# this clone last fetched it, in _bs_wf: noref (the clone has no origin/BRANCH, so
# nothing is known), absent, unread, placeholder (it still reads {{FELIX_REF}}) or
# ok. Only a line that is not a comment counts as reading the placeholder: the
# workflow bootstrap renders explains it in a comment, so a filled one names it
# too. _bs_wf_names is 1 when a line that is not a comment has repository: as its
# first word; _bs_wf_rw is that first value and _bs_wf_yw the value of the first
# ref: line after it, quotes and a trailing comment removed.
_felix_bs_wf_read() {
  local ref="refs/remotes/origin/$2:.github/workflows/$3" txt facts l
  _bs_wf=ok; _bs_wf_names=0; _bs_wf_rw=""; _bs_wf_yw=""
  if ! git -C "$1" rev-parse -q --verify "refs/remotes/origin/$2^{commit}" >/dev/null 2>&1; then _bs_wf=noref; return 0; fi
  git -C "$1" cat-file -e "$ref" 2>/dev/null || { _bs_wf=absent; return 0; }
  txt="$(git -C "$1" cat-file blob "$ref" 2>/dev/null)" || { _bs_wf=unread; return 0; }
  facts="$(printf '%s\n' "$txt" | LC_ALL=C awk '
    function val(s,   c, i) {
      sub(/^[ \t]*[A-Za-z]+:[ \t]*/, "", s)
      c = substr(s, 1, 1)
      if (c == "\047" || c == "\"") { s = substr(s, 2); i = index(s, c); if (i) s = substr(s, 1, i - 1) }
      else { if (match(s, /[ \t]#/)) s = substr(s, 1, RSTART - 1); sub(/[ \t]+$/, "", s) }
      return s
    }
    { sub(/\r$/, "") }
    /^[ \t]*#/ { next }
    index($0, "{{FELIX_REF}}") { p = 1 }
    $1 == "repository:" && !r { r = 1; print "R:" val($0); next }
    r && $1 == "ref:" && !y { y = 1; print "Y:" val($0) }
    END { if (p) print "P" }')" || { _bs_wf=unread; return 0; }
  while IFS= read -r l; do
    case "$l" in
      P)   _bs_wf=placeholder ;;
      R:*) _bs_wf_names=1; _bs_wf_rw="${l#R:}" ;;
      Y:*) _bs_wf_yw="${l#Y:}" ;;
    esac
  done <<<"$facts"
}

# NAME FELIX_REPO ENGINE_DIR BRANCH: whether CI resolves the project from the
# checkout the committed workflow names (it is filled and names one), in _bs_wj:
# ok, none (with _bs_wjwhy) or unknown (with _bs_wjwhy). In order: the repository
# is the one the engine checkout's origin names, the ref is a full sha of a commit
# the engine checkout has and its default branch contains, and that commit holds
# the project. What the engine checkout cannot vouch for is unknown, not wrong.
_felix_bs_wf_checkout() {
  local rw="$_bs_wf_rw" yw="$_bs_wf_yw" lrw lf why
  _bs_wj=unknown; _bs_wjwhy=""
  case "$rw" in
    ''|*'${{'*) _bs_wjwhy="the repository: of the workflow on origin/$4 (${rw:-empty}) could not be read"; return 0 ;;
  esac
  lrw="$(printf '%s' "$rw" | LC_ALL=C tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"
  lf="$(printf '%s' "$2" | LC_ALL=C tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"
  if [ "$lrw" != "$lf" ]; then _bs_wj=none; _bs_wjwhy="the workflow on origin/$4 checks out $rw, not $2"; return 0; fi
  if [ -z "$yw" ]; then _bs_wjwhy="the workflow on origin/$4 sets no ref: for $2, so the commit it pins could not be read"; return 0; fi
  why="the commit $yw that the workflow on origin/$4 pins could not be read in the engine checkout"
  case "$yw" in *[!0123456789abcdefABCDEF]*) _bs_wjwhy="$why (it is not a full sha)"; return 0 ;; esac
  [ "${#yw}" -eq 40 ] || { _bs_wjwhy="$why (it is not a full sha)"; return 0; }
  git -C "$3" rev-parse --verify -q "$yw^{commit}" >/dev/null 2>&1 \
    || { _bs_wjwhy="$why (the engine checkout does not have it)"; return 0; }
  [ -n "$_bs_dt" ] || { _bs_wjwhy="$why (the engine checkout has no default branch to check it against)"; return 0; }
  git -C "$3" merge-base --is-ancestor "$yw" "$_bs_dt" 2>/dev/null \
    || { _bs_wjwhy="$why (the engine checkout's default branch does not contain it)"; return 0; }
  if git -C "$3" cat-file -e "$yw:projects/$1/project.json" 2>/dev/null; then _bs_wj=ok
  else _bs_wj=none; _bs_wjwhy="the workflow on origin/$4 pins $yw, which does not hold projects/$1"; fi
}

# NAME FELIX_REPO ENGINE_DIR ROOT BRANCH WORKFLOW_FILE: the value of the ci project:
# line, and why protection is held back, if it is. Run after _felix_bs_ci_judge,
# with BRANCH empty when the default branch could not be read (nothing is held
# then: the protection row says so). Leaves _bs_cv (the line's value), _bs_kind
# (0 nothing held, 2 CI cannot resolve the project, 3 the workflow is not on the
# default branch yet, 4 it still reads the placeholder or could not be read, 5 it
# is not known), _bs_hold and _bs_remedy. The reasons are looked for in this
# order: Felix has no remote, the clone lacks origin/BRANCH, then the workflow
# on it if it names a checkout; else the pin, then absent, then placeholder.
_felix_bs_decide() {
  local name="$1" f="$2" e="$3" d="$5" wfp=".github/workflows/$6"
  _bs_kind=0; _bs_hold=""; _bs_remedy=""
  if [ "$_bs_ci_ok" -eq 1 ]; then _bs_cv="projects/$name is in the pinned commit, so CI resolves the project"
  elif [ -n "$_bs_ci_off" ]; then _bs_cv="none: $_bs_ci_why; check that branch out and pull it, then re-run"
  else _bs_cv="none: $_bs_ci_why; commit projects/$name to the default branch of a Felix repository on GitHub that you can push to (from a clone of someone else's Felix, a fork that the engine checkout's origin names, with the workflow's repository: set to that fork), then re-run"; fi
  [ -n "$d" ] || return 0
  if [ -z "$f" ]; then
    _bs_kind=2; _bs_hold="CI cannot resolve $name because $_bs_ci_why"; _bs_remedy="see ci project: above"; return 0
  fi
  _felix_bs_wf_read "$4" "$d" "$6"
  if [ "$_bs_wf" = noref ]; then
    _bs_kind=5; _bs_hold="origin/$d could not be read in this clone"; _bs_remedy="git fetch origin, then re-run"; return 0
  fi
  if [ "$_bs_wf" = ok ] && [ "$_bs_wf_names" -eq 1 ]; then
    _felix_bs_wf_checkout "$name" "$f" "$e" "$d"
    if [ "$_bs_wj" = ok ]; then
      _bs_cv="projects/$name is in $_bs_wf_yw, the commit the workflow on origin/$d checks out, so CI resolves the project"
    elif [ "$_bs_wj" = none ]; then
      _bs_kind=2; _bs_hold="CI cannot resolve $name because $_bs_wjwhy"; _bs_remedy="see ci project: above"
      _bs_cv="none: $_bs_wjwhy; set repository: and ref: in $wfp to a Felix repository CI can fetch and a commit of it that holds projects/$name, then re-run"
    else
      _bs_kind=5; _bs_hold="$_bs_wjwhy"; _bs_remedy="see ci project: above"
      _bs_cv="unknown: $_bs_wjwhy; set ref: in $wfp to a full sha of a commit of $f that holds projects/$name, or fetch the engine checkout, then re-run"
    fi
    return 0
  fi
  # No checkout named in what CI runs (a project's own workflow, or a Felix
  # home's, which runs the Felix in its own tree): the pin, or the engine
  # checkout's default branch when the pin is what is out of date.
  if [ "$_bs_ci_ok" -ne 1 ] && { [ "$_bs_wf" != ok ] || [ "$_bs_ci_dt" -ne 1 ]; }; then
    _bs_kind=2; _bs_hold="CI cannot resolve $name because $_bs_ci_why"; _bs_remedy="see ci project: above"
  elif [ "$_bs_wf" = absent ]; then
    _bs_kind=3; _bs_hold="$wfp is not on origin/$d"; _bs_remedy="merge it there, then re-run"
  elif [ "$_bs_wf" = placeholder ]; then
    _bs_kind=4; _bs_hold="$wfp on origin/$d still reads {{FELIX_REF}}"
    _bs_remedy="set ref: there (and repository: when it is not $f) to a commit of $f that holds projects/$name, then re-run"
  elif [ "$_bs_wf" = unread ]; then
    _bs_kind=4; _bs_hold="$wfp on origin/$d could not be read"; _bs_remedy="fetch, then re-run"
  fi
}

# MARK NAME TEXT: one row. Every row that is not done is a step outstanding, and
# one that could not be read is also counted as that.
_felix_bs_row() {
  printf '  [%s] %-12s %s\n' "$1" "$2" "$3"
  [ "$1" = "x" ] && return 0
  _bs_todo=$((_bs_todo + 1))
  [ "$1" = "?" ] && _bs_unk=$((_bs_unk + 1))
  return 0
}

# PROJECT_DIR [--yes]: the plan, or with --yes the plan applied. Exits 1 for a
# step that failed, a read that could not be made, a rule held back because CI
# could not pass it, or a rule that is on and cannot be passed; 0 otherwise,
# which includes waiting for the workflow to reach the default branch.
felix_bootstrap() {
  local proj="$1" yes=0 a; shift
  for a in "$@"; do [ "$a" = "--yes" ] && yes=1; done
  local root slug eco gwf wfp name esrc felix_repo felix_ref etop pdir prel="" ref_none hint
  root="$(felix_repo_root "$PWD")"
  slug="$(felix_repo_slug "$root")"
  eco="$(felix_guess_ecosystem "$root")"
  # The file the repair loop and the auto-merge streak read the gate's runs
  # from, so the one this looks for and writes. Resolved before anything is
  # printed: a refused gate_workflow is a fact about the project to fix first.
  gwf="$(felix_gate_workflow "$proj")" || die "$gwf"
  wfp=".github/workflows/$gwf"
  name="$(basename "${proj%/}")"
  # The Felix checkout, not the directory this script happens to sit in. #65:
  # `felix_repo_slug "$FELIX_ROOT"` asked git for a remote inside the running
  # engine, which from the deployed CLI is the plugin cache — no remote, so this
  # printed "none, CI cannot fetch the harness" about an engine whose remote
  # exists. Worse on a machine whose home directory is itself a git repository
  # with an origin: that slug would be returned instead and interpolated into
  # the generated workflow's `repository:`, beside a deploy key. Resolve the
  # tree first, then slug the tree.
  esrc="$(felix_engine_source "$FELIX_ROOT" "$FELIX_HOME_DIR")" || esrc=""
  felix_repo=""; felix_ref=""
  [ -n "$esrc" ] && felix_repo="$(felix_repo_slug "$esrc")"
  # The commit CI checks Felix out at, from the same checkout as the slug, and
  # holding this project when the project lives in that checkout. Physical
  # paths on both sides: macOS spells /var as /private/var, and git reports
  # the resolved form.
  if [ -n "$esrc" ]; then
    etop="$(git -C "$esrc" rev-parse --show-toplevel 2>/dev/null)" || etop=""
    pdir="$(cd "$proj" 2>/dev/null && pwd -P)" || pdir=""
    case "$pdir" in "$etop"/?*) [ -n "$etop" ] && prel="${pdir#"$etop"/}" ;; esac
    felix_ref="$(felix_bs_pin_ref "$esrc" "$prel")" || felix_ref=""
  fi
  ref_none="none: no commit of the engine checkout that origin's default branch holds${prel:+ with $prel in it}; the workflow gets {{FELIX_REF}} to fill"
  # Whether the pin is a commit CI can resolve the project from. The pin only
  # says the commit is on origin's default branch; the project has to be in it.
  _felix_bs_ci_judge "$name" "$felix_repo" "$felix_ref" "$esrc"

  # What GitHub says is read before anything prints, because the default branch
  # and the workflow on it decide what the ci project: line says.
  local d="" pst="" lst="" lmiss="" hold="" remedy="" kind=0 rc=0 pwhy="" lwhy="" dwhy="" wfhave=no
  if [ -n "$slug" ]; then
    if _felix_bs_labels_read "$slug"; then lst="$_bs_lst"; lmiss="$_bs_lmiss"
    else lst=unknown; lwhy="$_bs_why"; fi
    if _felix_bs_default_branch "$slug"; then
      d="$_bs_d"
      _felix_bs_prot_read "$slug" "$d"; pst="$_bs_pst"; pwhy="$_bs_why"
    else dwhy="$_bs_why"; fi
  fi
  # Held back: the first reason that is so. A workflow this run writes is not on
  # the default branch yet, so it counts as not there.
  _felix_bs_decide "$name" "$felix_repo" "$esrc" "$root" "$d" "$gwf"
  hold="$_bs_hold"; remedy="$_bs_remedy"; kind="$_bs_kind"

  printf 'repo:        %s\n' "${slug:-no github remote}"
  printf 'ecosystem:   %s\n' "$eco"
  printf 'felix repo:  %s\n' "${felix_repo:-none, CI cannot fetch the harness}"
  printf 'felix ref:   %s\n' "${felix_ref:-$ref_none}"
  printf 'ci project:  %s\n\n' "$_bs_cv"

  _bs_todo=0; _bs_unk=0
  if _felix_bs_have_workflow "$root" "$gwf"; then wfhave=yes; a=x; else a=" "; fi
  _felix_bs_row "$a" ci-workflow "$wfp calling felix gate"
  if [ -n "$slug" ]; then
    case "$lst" in
      yes) _felix_bs_row x labels "escalation and risk labels the repair loop applies" ;;
      no)  _felix_bs_row " " labels "escalation and risk labels the repair loop applies; missing: $lmiss" ;;
      *)   _felix_bs_row "?" labels "could not be read: escalation and risk labels the repair loop applies ($lwhy)" ;;
    esac
    if [ -z "$d" ]; then
      _felix_bs_row "?" protection "could not be read: the default branch of $slug ($dwhy)"
    else
      case "$pst" in
        gate)   _felix_bs_row x protection "$d requires the gate" ;;
        nogate) _felix_bs_row " " protection "$d is protected but does not require the gate${hold:+; held back: $hold}" ;;
        none)   _felix_bs_row " " protection "require the gate on $d, block force pushes${hold:+; held back: $hold}" ;;
        *)      _felix_bs_row "?" protection "could not be read: the protection of $d ($pwhy)" ;;
      esac
    fi
  else
    printf '  [-] %-12s no github remote; labels and protection skipped\n' "github"
  fi
  if _felix_bs_have_perms "$root"; then a=x; else a=" "; fi
  _felix_bs_row "$a" permissions ".claude/settings.json deny and ask policy"

  # A rule that is on and cannot be passed is not a baseline, nor is one that
  # may not be passable because what decides it could not be read.
  local unpass=0
  if [ "$pst" = gate ] && [ -n "$hold" ]; then
    unpass=1; rc=1
    if [ "$kind" -eq 5 ]; then
      printf '\n%s requires the gate, but whether CI can pass it is not known: %s; %s.\n' "$d" "$hold" "$remedy"
    else
      printf '\n%s requires the gate, which CI cannot pass: %s.\n' "$d" "$hold"
    fi
  fi
  if [ "$_bs_todo" -eq 0 ]; then
    [ "$unpass" -eq 1 ] || printf '\nBaseline already in place.\n'
    [ "$yes" -eq 1 ] && return "$rc"
    return 0
  fi
  if [ "$yes" -ne 1 ]; then
    if [ "$_bs_unk" -gt 0 ]; then printf '\n%s step(s) outstanding (%s could not be read). Nothing changed.\n' "$_bs_todo" "$_bs_unk"
    else printf '\n%s step(s) outstanding. Nothing changed.\n' "$_bs_todo"; fi
    printf 'apply with: felix bootstrap --yes\n'
    return 0
  fi

  printf '\napplying\n'
  if [ "$wfhave" = no ]; then
    if [ -z "$felix_repo" ]; then
      printf '  skipped    ci-workflow (Felix has no remote for CI to fetch)\n'
    else
      mkdir -p "$root/.github/workflows"
      felix_bs_render_workflow "$eco" "$felix_repo" "$felix_ref" > "$root/$wfp"
      printf '  wrote      %s (review, then commit it)\n' "$wfp"
      if [ "$_bs_ci_ok" -eq 1 ]; then :
      elif [ -n "$_bs_ci_off" ]; then
        if [ -z "$felix_ref" ]; then hint="its ref: is {{FELIX_REF}}"; else hint="CI cannot resolve $name at that ref"; fi
        printf "             %s; the engine checkout is %s its default branch, which holds projects/%s: check that branch out and pull, then re-run to render the workflow again\n" \
          "$hint" "$_bs_ci_off" "$name"
      elif [ -z "$felix_ref" ]; then
        printf "             its ref: is {{FELIX_REF}}; set the full sha of a commit on %s's default branch that holds projects/%s, and set its repository: to your fork of Felix when %s is not one you can push to\n" "$felix_repo" "$name" "$felix_repo"
      else
        printf "             CI cannot resolve %s at that ref; it needs a commit on %s's default branch that holds projects/%s, and its repository: set to your fork of Felix when %s is not one you can push to\n" "$name" "$felix_repo" "$name" "$felix_repo"
      fi
    fi
  fi
  case "$lst" in
    no)      for a in needs-founder needs-architecture risk-green risk-yellow risk-red; do
               felix_contains " $lmiss " " $a " && { _felix_bs_label_create "$slug" "$a" || rc=1; }
             done ;;
    unknown) printf '  skipped    labels (could not be read: %s)\n' "$lwhy" ;;
  esac
  if [ -n "$slug" ]; then
    if [ -z "$d" ]; then
      printf '  skipped    protection (could not be read: the default branch of %s, %s)\n' "$slug" "$dwhy"
    elif [ "$pst" = unknown ]; then
      printf '  skipped    protection (could not be read: the protection of %s, %s)\n' "$d" "$pwhy"
    elif [ "$pst" != gate ]; then
      if [ -n "$hold" ]; then
        printf '  skipped    protection (%s; %s)\n' "$hold" "$remedy"
        [ "$kind" -eq 3 ] || rc=1
      else
        _felix_bs_protect "$slug" "$d" "$pst" || rc=1
      fi
    fi
  fi
  [ "$_bs_unk" -eq 0 ] || rc=1
  if ! _felix_bs_have_perms "$root"; then
    mkdir -p "$root/.claude"
    if [ -f "$root/.claude/settings.json" ]; then
      printf '  skipped    permissions (settings.json exists; merge by hand rather than clobber it)\n'
    else
      felix_bs_render_perms > "$root/.claude/settings.json"
      printf '  wrote      .claude/settings.json\n'
    fi
  fi
  printf '\nRe-run felix bootstrap to confirm.\n'
  return "$rc"
}
