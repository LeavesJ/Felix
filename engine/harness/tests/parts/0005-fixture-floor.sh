# ----------------------------------------------------------- fixture floor ----
# Every fixture line in this file that edits a repository does it from a
# directory a variable names: `( cd "$_fs_wr" && git remote set-url origin ... )`.
# On 2026-10-08 one of those variables was empty. Bash 3.2 takes `cd ""` as a
# success and stays where it is, and where it was is wherever the suite was
# started: a developer's worktree. git then edited that repository's config,
# which every worktree of it shares, and the real origin came back as
# acme/widget. Two other shapes do the same with no empty variable at all: a
# fixture directory that exists but where `git init` never ran, from which git
# walks up to the first repository that encloses it, and a GIT_DIR inherited
# from the caller, which names a repository whatever the working directory is.
#
# The preamble closes all three before any fixture is built. _fixture_floor
# moves the suite into $TMP/cwd, unsets the GIT_DIR family, and exports the
# parent of $TMP as GIT_CEILING_DIRECTORIES, so git stops looking before it
# leaves $TMP from any directory inside it. The parent, not $TMP itself,
# measured on git 2.54: a ceiling stops git entering that directory from below
# it, so a working directory EQUAL to the ceiling is not covered, and git walks
# straight up past it.
#
# This section runs first so that a floor which did not hold is the first
# thing a run says. Whatever it does to a repository it does to stand-ins
# under $TMP, and the probes that could reach past $TMP are rev-parse, which
# only reads. Every mutating probe below first asks git which repository it
# would touch, from the same directory and with the same environment, and
# runs only when the answer is none or one under $TMP: a broken floor has to
# fail these assertions, not repeat the incident they describe.
#
# Paths are compared physically. On macOS mktemp says /var/folders/..., the
# filesystem and git say /private/var/folders/..., and both are right.
printf '\nfixture floor\n'

# A gate run inside a Claude Code cloud VM has CLAUDE_CODE_REMOTE=true in its
# environment, and every hook this suite runs would take the cloud's branch and
# be judged against local behaviour (audit b07, B12). The suite judges a local
# session. A part that wants the cloud sets it on its own command.
unset CLAUDE_CODE_REMOTE

_ff_family="GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES"
# A directory's physical path, or nothing when the name is empty or names no
# directory. The emptiness test is the point: `cd ""` is the bug.
_ff_phys()  { [ -n "${1:-}" ] && [ -d "$1" ] && ( cd "$1" && pwd -P ); }
# What a child process is handed for a variable, which is what git sees; a
# value only the suite's own shell holds protects nothing. (unset) when absent.
_ff_child() { command printenv "$1" 2>/dev/null || printf '(unset)'; }
# git for the stand-ins' own upkeep: building and reading them must not lean
# on the floor these assertions are judging, so it sheds the family itself.
_ff_git()   { ( unset $_ff_family GIT_CONFIG; git "$@" ); }
# One key's value from the key-a-line reports the subshells below print.
_ff_get()   { printf '%s\n' "$1" | sed -n "s/^$2 //p"; }
# The incident was bash 3.2's: `cd ""` succeeded and stayed put. POSIX.1-2024
# made that an error, and bash 5.3 (the ubuntu-26.04 runners') answers
# "cd: null directory" with status 1. The probes below model the incident, so
# a probe that runs `cd` on an empty name must see 3.2's answer or it never gets
# to the git commands it exists to run, and its assertion passes or fails for
# the wrong reason. Called first inside the ( ) or $( ) of such a probe, this
# defines a cd there that returns 0 for exactly one empty operand and hands
# everything else to the builtin. It does nothing where the shell's own cd
# already takes an empty name, so bash 3.2 runs the real thing. Called at the
# top level it would replace cd for the whole suite, so only a subshell calls it.
_ff_oldcd() {
  ( cd "" ) 2>/dev/null && return 0
  cd() { if [ "$#" -eq 1 ] && [ -z "$1" ]; then return 0; fi; builtin cd "$@"; }
}
_ff_tmp="$(_ff_phys "$TMP")"

# 1. Where the suite stands, and what git finds from there.
_ff_here="$(pwd -P)"; _ff_want="$(_ff_phys "$TMP/cwd")"
if [ -n "$_ff_want" ] && [ "$_ff_here" = "$_ff_want" ]; then
  ok  "fixture floor: the suite's working directory is cwd inside its own temporary directory"
else
  bad "fixture floor: the suite's working directory is cwd inside its own temporary directory" \
      "it stands in [$_ff_here]; $TMP/cwd is [${_ff_want:-not a directory}]"
fi
_ff_gd="$(git rev-parse --git-dir 2>/dev/null)"; _ff_rc=$?
if [ "$_ff_rc" -ne 0 ] && [ -z "$_ff_gd" ]; then
  ok  "fixture floor: git finds no repository from the suite's working directory"
else
  bad "fixture floor: git finds no repository from the suite's working directory" \
      "from [$_ff_here] git rev-parse --git-dir exited $_ff_rc and found [$_ff_gd]"
fi
_ff_cv="$(_ff_child GIT_CEILING_DIRECTORIES)"; _ff_cw="$(_ff_phys "$(dirname "$TMP")")"
if [ -n "$_ff_cw" ] && [ "$(_ff_phys "$_ff_cv")" = "$_ff_cw" ]; then
  ok  "fixture floor: a child process sees GIT_CEILING_DIRECTORIES as the parent of the suite's temporary directory"
else
  bad "fixture floor: a child process sees GIT_CEILING_DIRECTORIES as the parent of the suite's temporary directory" \
      "a child sees [$_ff_cv]; the parent of $TMP is [$_ff_cw]"
fi
_ff_leak=""
for _ff_v in $_ff_family; do
  _ff_x="$(_ff_child "$_ff_v")"; [ "$_ff_x" = "(unset)" ] || _ff_leak="$_ff_leak $_ff_v=$_ff_x"
done
[ -z "$_ff_leak" ] && ok "fixture floor: a child process inherits none of the GIT_DIR family" \
                   || bad "fixture floor: a child process inherits none of the GIT_DIR family" "a child is handed:$_ff_leak"

# 2. The incident's own shape, run from the suite's shell: a fixture root that
# came out empty. Read-only, because with no floor this reaches a real
# repository, and the one it would reach is the checkout the suite was started
# from, which REAL_HARNESS sits in. Two questions, because they part company:
# the toplevel is the checkout, but the common git dir is where the config the
# incident rewrote lives, shared by every worktree, and a GIT_DIR in the
# environment reaches it while --show-toplevel reports only the cwd.
_ff_empty=""
_ff_top="$(_ff_oldcd; cd "$_ff_empty" && git rev-parse --show-toplevel 2>/dev/null)"; _ff_rc=$?
_ff_cmn="$(_ff_oldcd; cd "$_ff_empty" && git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
if [ "$_ff_rc" -ne 0 ] && [ -z "$_ff_top" ] && [ -z "$_ff_cmn" ]; then
  ok  "fixture floor: an empty fixture root, cd to an empty name, reaches no repository"
else
  bad "fixture floor: an empty fixture root, cd to an empty name, reaches no repository" \
      "from [$_ff_here], cd \"\" then git rev-parse found toplevel [$_ff_top] (exit $_ff_rc) and git common dir [$_ff_cmn]"
fi
_ff_real="$(git -C "$REAL_HARNESS" rev-parse --show-toplevel 2>/dev/null)"
_ff_realc="$(git -C "$REAL_HARNESS" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
if [ -z "$_ff_real" ] && [ -z "$_ff_realc" ]; then
  skip "fixture floor: an empty fixture root does not reach the checkout the suite was started from" \
       "$REAL_HARNESS is in no git checkout"
elif [ -n "$_ff_top" ] && [ -n "$_ff_real" ] && [ "$(_ff_phys "$_ff_top")" = "$(_ff_phys "$_ff_real")" ]; then
  bad "fixture floor: an empty fixture root does not reach the checkout the suite was started from" \
      "cd \"\" then git rev-parse --show-toplevel found [$_ff_top], the checkout of $REAL_HARNESS"
elif [ -n "$_ff_cmn" ] && [ -n "$_ff_realc" ] && [ "$(_ff_phys "$_ff_cmn")" = "$(_ff_phys "$_ff_realc")" ]; then
  bad "fixture floor: an empty fixture root does not reach the checkout the suite was started from" \
      "cd \"\" then git rev-parse --git-common-dir found [$_ff_cmn], the shared git dir of $REAL_HARNESS's checkout"
else
  ok  "fixture floor: an empty fixture root does not reach the checkout the suite was started from"
fi

# 3. _fixture_floor on a directory INSIDE a checkout, which is where the suite
# would stand if $TMP ever sat inside one. The stand-in carries what the
# incident destroyed: an origin, a ref under refs/remotes/origin, and a branch
# whose upstream is origin. No fetch, so the URL is never dialled.
if declare -F _fixture_floor >/dev/null 2>&1; then
  ok  "fixture floor: _fixture_floor is defined in the suite's shell"
else
  bad "fixture floor: _fixture_floor is defined in the suite's shell" "no function by that name; every floor assertion below calls it"
fi
_ff_url="https://example.invalid/ff/stand-in.git"
_ff_build() {   # <dir>: a stand-in checkout at <dir>, with <dir>/fixtures inside it
  mkdir -p "$1/fixtures" && _ff_git init -q -b main "$1" >/dev/null 2>&1 && [ -d "$1/.git" ] || return 1
  _ff_git -C "$1" -c user.name=t -c user.email=t@t -c commit.gpgsign=false \
          commit -q --allow-empty -m stand-in >/dev/null 2>&1 \
    && _ff_git -C "$1" remote add origin "$_ff_url" \
    && _ff_git -C "$1" update-ref refs/remotes/origin/main HEAD \
    && _ff_git -C "$1" config branch.main.remote origin \
    && _ff_git -C "$1" config branch.main.merge refs/heads/main
}
_ff_snap() {    # <checkout>: sets _ff_s_cfg _ff_s_url _ff_s_refs _ff_s_up from what git reads there
  _ff_s_cfg=""; _ff_s_cfgt=""; _ff_s_url=""; _ff_s_refs=""; _ff_s_up=""
  [ -d "$1/.git" ] || return 0
  _ff_s_cfgt="$(_ff_git -C "$1" config --list --local 2>/dev/null)"
  _ff_s_cfg="$(printf '%s\n' "$_ff_s_cfgt" | cksum | tr -s ' ' ' ')"
  _ff_s_url="$(_ff_git -C "$1" config --get remote.origin.url 2>/dev/null)"
  _ff_s_refs="$(_ff_git -C "$1" for-each-ref refs/remotes/origin 2>/dev/null | wc -l | tr -d ' ')"
  _ff_s_up="$(_ff_git -C "$1" rev-parse --abbrev-ref 'main@{upstream}' 2>/dev/null)"
}
_ff_sp="$TMP/floor-stand-in"
_ff_build "$_ff_sp"; _ff_snap "$_ff_sp"
_ff_p_cfg="$_ff_s_cfg"; _ff_p_url="$_ff_s_url"; _ff_p_refs="$_ff_s_refs"; _ff_p_up="$_ff_s_up"
_ff_p_top="$(_ff_git -C "$_ff_sp" rev-parse --show-toplevel 2>/dev/null)"
if [ -n "$_ff_p_cfg" ] && [ "$_ff_p_url" = "$_ff_url" ] && [ "$_ff_p_refs" = "1" ] \
   && [ "$_ff_p_up" = "origin/main" ] && [ -n "$_ff_p_top" ] && [ "$(_ff_phys "$_ff_p_top")" = "$(_ff_phys "$_ff_sp")" ]; then
  _ff_built=1; ok "fixture floor: the stand-in checkout has an origin, an origin ref and a branch tracking origin"
else
  _ff_built=0; bad "fixture floor: the stand-in checkout has an origin, an origin ref and a branch tracking origin" \
                   "toplevel [$_ff_p_top], origin [$_ff_p_url], origin refs [$_ff_p_refs], main tracks [$_ff_p_up]"
fi

# What the floor does to the shell that calls it. The caller has exported the
# whole family at the stand-in and has an OLDPWD, as a shell that has moved
# does; nothing here writes.
_ff_dir="$_ff_sp/fixtures"
_ff_o="$(cd "$_ff_dir" && cd "$_ff_sp" || exit 0
         export GIT_DIR="$_ff_sp/.git" GIT_WORK_TREE="$_ff_sp" GIT_COMMON_DIR="$_ff_sp/.git" \
                GIT_INDEX_FILE="$_ff_sp/.git/index" GIT_OBJECT_DIRECTORY="$_ff_sp/.git/objects" \
                GIT_ALTERNATE_OBJECT_DIRECTORIES="$_ff_sp/.git/objects"
         _fixture_floor "$_ff_dir" >/dev/null 2>&1; printf 'floor %s\n' "$?"
         printf 'pwd %s\n' "$(pwd -P)"
         printf 'ceiling %s\n' "$(_ff_child GIT_CEILING_DIRECTORIES)"
         _ff_l=""; for _ff_v in $_ff_family; do [ "$(_ff_child "$_ff_v")" = "(unset)" ] || _ff_l="$_ff_l $_ff_v"; done
         [ -n "$_ff_l" ] || _ff_l=" none"; printf 'leaked %s\n' "$_ff_l"
         printf 'oldpwd %s\n' "${OLDPWD-(unset)}")"
is "_fixture_floor returns 0 for a directory inside a checkout" "$(_ff_get "$_ff_o" floor)" "0"
_ff_x="$(_ff_get "$_ff_o" pwd)"; _ff_w="$(_ff_phys "$_ff_dir/cwd")"
[ -n "$_ff_w" ] && [ "$_ff_x" = "$_ff_w" ] && ok "_fixture_floor moves the calling shell into DIR/cwd" \
  || bad "_fixture_floor moves the calling shell into DIR/cwd" "the caller stands in [$_ff_x]; $_ff_dir/cwd is [${_ff_w:-not a directory}]"
_ff_x="$(_ff_get "$_ff_o" ceiling)"
if [ "$(_ff_phys "$_ff_x")" = "$(_ff_phys "$_ff_sp")" ] && [ -n "$(_ff_phys "$_ff_sp")" ]; then
  ok  "_fixture_floor exports DIR's parent, not DIR, as GIT_CEILING_DIRECTORIES"
else
  bad "_fixture_floor exports DIR's parent, not DIR, as GIT_CEILING_DIRECTORIES" "a child sees [$_ff_x]; DIR is [$_ff_dir], its parent [$_ff_sp]"
fi
_ff_x="$(_ff_get "$_ff_o" leaked)"
[ "$_ff_x" = " none" ] && ok "_fixture_floor unsets every variable of the GIT_DIR family the caller exported" \
  || bad "_fixture_floor unsets every variable of the GIT_DIR family the caller exported" "a child is still handed:${_ff_x:- (no report)}"
is "_fixture_floor leaves no OLDPWD for cd - to return to" "$(_ff_get "$_ff_o" oldpwd)" "(unset)"
# And it says no when git would still find a repository from DIR/cwd, as it
# does when DIR itself is one: the ceiling stops git above DIR, not at it.
_ff_isco="$TMP/floor-is-a-checkout"; mkdir -p "$_ff_isco"; _ff_git init -q "$_ff_isco" >/dev/null 2>&1
_ff_rc="$(cd "$TMP" && _fixture_floor "$_ff_isco" >/dev/null 2>&1; printf '%s' "$?")"
if [ ! -d "$_ff_isco/.git" ]; then
  bad "_fixture_floor returns non-zero when DIR is itself a checkout" "the checkout was not made at [$_ff_isco]"
elif [ "$_ff_rc" -ne 0 ]; then
  ok  "_fixture_floor returns non-zero when DIR is itself a checkout"
else
  bad "_fixture_floor returns non-zero when DIR is itself a checkout" "it returned 0 for [$_ff_isco], which holds a .git of its own"
fi

# The incident's commands, from four places a fixture can end up after the
# floor, each against its own copy of the stand-in so one case's damage cannot
# hide another's. The caller starts INSIDE the stand-in, so a floor that does
# not move it leaves git one step from the stand-in's .git rather than at a
# real repository.
_ff_case() {    # <how> <checkout>: key-a-line report of what the floor and the commands did
  local how="$1" r="$2" e=""
  ( _fx_cd "$r" || exit 0
    mkdir -p "$r/fixtures/uninit"
    [ "$how" = gitdir ] && { GIT_DIR="$r/.git"; export GIT_DIR; }
    _fixture_floor "$r/fixtures" >/dev/null 2>&1; _ff_frc=$?
    printf 'floor %s\n' "$_ff_frc"; [ "$_ff_frc" -eq 0 ] || exit 0
    case "$how" in
      empty|gitdir) cd "$e" ;;
      dir)          cd "$r/fixtures/$e" ;;
      uninit)       cd "$r/fixtures/uninit" ;;
    esac || { printf 'cd failed\n'; exit 0; }
    printf 'pwd %s\n' "$(pwd -P)"
    _ff_gd="$(git rev-parse --absolute-git-dir 2>/dev/null)"
    printf 'found %s\n' "${_ff_gd:--}"
    # Which repository a write from here would land in, asked first. A git
    # dir or common dir outside $TMP, or a GIT_CONFIG outside it (git config
    # writes there even with no repository at all), and nothing is run.
    [ -n "$_ff_tmp" ] || { printf 'unsafe no physical path for %s\n' "$TMP"; exit 0; }
    if [ -n "$_ff_gd" ]; then
      _ff_gp="$(_ff_phys "$_ff_gd")"
      _ff_cp="$(_ff_phys "$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)")"
      case "$_ff_gp/" in "$_ff_tmp"/*) ;; *) printf 'unsafe git dir %s\n' "$_ff_gd"; exit 0 ;; esac
      case "$_ff_cp/" in "$_ff_tmp"/*) ;; *) printf 'unsafe common dir [%s] of %s\n' "$_ff_cp" "$_ff_gd"; exit 0 ;; esac
    fi
    if [ -n "${GIT_CONFIG:-}" ]; then
      case "$(_ff_phys "$(dirname "$GIT_CONFIG")")/" in "$_ff_tmp"/*) ;; *) printf 'unsafe GIT_CONFIG %s\n' "$GIT_CONFIG"; exit 0 ;; esac
    fi
    git remote remove origin >/dev/null 2>&1;                           printf 'remove %s\n' "$?"
    git remote add origin https://github.com/acme/widget.git >/dev/null 2>&1; printf 'add %s\n' "$?"
    git config branch.main.remote x >/dev/null 2>&1;                    printf 'config %s\n' "$?" )
}
for _ff_how in empty dir uninit gitdir; do
  case "$_ff_how" in
    empty)  _ff_lab="an empty variable as the directory" ;;
    dir)    _ff_lab="cwd equal to DIR itself" ;;
    uninit) _ff_lab="a directory under DIR where git init never ran" ;;
    gitdir) _ff_lab="GIT_DIR at the stand-in exported before the floor" ;;
  esac
  _ff_n1="_fixture_floor, then $_ff_lab: git finds no repository"
  _ff_n2="_fixture_floor, then $_ff_lab: git remote remove origin fails"
  _ff_n3="_fixture_floor, then $_ff_lab: git remote add origin https://github.com/acme/widget.git fails"
  _ff_n4="_fixture_floor, then $_ff_lab: git config branch.main.remote x fails"
  _ff_n5="_fixture_floor, then $_ff_lab: the stand-in's local config is unchanged"
  _ff_n6="_fixture_floor, then $_ff_lab: the stand-in's origin URL is unchanged"
  _ff_n7="_fixture_floor, then $_ff_lab: the stand-in keeps its refs/remotes/origin ref"
  _ff_n8="_fixture_floor, then $_ff_lab: the stand-in's main still tracks origin/main"
  _ff_r="$TMP/floor-case-$_ff_how"
  _ff_why=""
  if [ "$_ff_built" -ne 1 ] || ! cp -R "$_ff_sp" "$_ff_r" 2>/dev/null; then
    _ff_why="not exercised: the stand-in checkout was not built"
  else
    _ff_o="$(_ff_oldcd; _ff_case "$_ff_how" "$_ff_r")"
    _ff_f="$(_ff_get "$_ff_o" floor)"; _ff_u="$(_ff_get "$_ff_o" unsafe)"
    if [ "$_ff_f" != "0" ]; then
      _ff_why="not exercised: _fixture_floor returned [${_ff_f:-nothing}] for $_ff_r/fixtures"
    elif [ -n "$(_ff_get "$_ff_o" cd)" ]; then
      _ff_why="not exercised: the case's own cd failed after the floor"
    elif [ -n "$_ff_u" ]; then
      _ff_why="not run: from [$(_ff_get "$_ff_o" pwd)] a write would land outside the suite's temporary directory, in $_ff_u"
    fi
  fi
  if [ -n "$_ff_why" ]; then
    for _ff_n in "$_ff_n1" "$_ff_n2" "$_ff_n3" "$_ff_n4" "$_ff_n5" "$_ff_n6" "$_ff_n7" "$_ff_n8"; do bad "$_ff_n" "$_ff_why"; done
    continue
  fi
  _ff_x="$(_ff_get "$_ff_o" pwd)"; _ff_v="$(_ff_get "$_ff_o" found)"
  [ "$_ff_v" = "-" ] && ok "$_ff_n1" || bad "$_ff_n1" "from [$_ff_x] git rev-parse found [$_ff_v]"
  for _ff_k in remove:"$_ff_n2" add:"$_ff_n3" config:"$_ff_n4"; do
    _ff_v="$(_ff_get "$_ff_o" "${_ff_k%%:*}")"
    [ -n "$_ff_v" ] && [ "$_ff_v" -ne 0 ] && ok "${_ff_k#*:}" \
      || bad "${_ff_k#*:}" "from [$_ff_x] it exited [${_ff_v:-not run}]"
  done
  _ff_snap "$_ff_r"
  [ -n "$_ff_s_cfg" ] && [ "$_ff_s_cfg" = "$_ff_p_cfg" ] && ok "$_ff_n5" \
    || bad "$_ff_n5" "checksum [$_ff_p_cfg] is now [$_ff_s_cfg], and it reads: $(printf '%s\n' "$_ff_s_cfgt" | tr '\n' ' ')"
  is "$_ff_n6" "$_ff_s_url"  "$_ff_p_url"
  is "$_ff_n7" "$_ff_s_refs" "$_ff_p_refs"
  is "$_ff_n8" "$_ff_s_up"   "$_ff_p_up"
done

# 4. What the floor refuses before it acts, an empty or a missing DIR, and
# that such a refusal leaves the caller exactly as it was: where it stands,
# what it exports, and what is on disk. A refusal after the cd, when git still
# finds a repository, has already moved the caller; the preamble exits on it.
_ff_caller="$TMP/floor-caller"; mkdir -p "$_ff_caller"
_ff_refuse() {  # <dir>: key-a-line report of what _fixture_floor <dir> did to its caller
  ( cd "$_ff_caller" || exit 0
    GIT_CEILING_DIRECTORIES="$TMP/floor-ceiling-before"; GIT_DIR="$TMP/floor-git-dir-before"
    export GIT_CEILING_DIRECTORIES GIT_DIR
    _fixture_floor "$1" >/dev/null 2>&1; printf 'floor %s\n' "$?"
    printf 'pwd %s\n' "$(pwd -P)"
    printf 'env %s|%s\n' "$(_ff_child GIT_CEILING_DIRECTORIES)" "$(_ff_child GIT_DIR)"
    printf 'entries %s\n' "$(ls -A "$_ff_caller" | wc -l | tr -d ' ')" )
}
_ff_cwant="$(_ff_phys "$_ff_caller")"; _ff_ewant="$TMP/floor-ceiling-before|$TMP/floor-git-dir-before"
_ff_o="$(_ff_refuse "")"
_ff_f="$(_ff_get "$_ff_o" floor)"
[ -n "$_ff_f" ] && [ "$_ff_f" -ne 0 ] && ok "_fixture_floor refuses an empty argument with a non-zero status" \
  || bad "_fixture_floor refuses an empty argument with a non-zero status" "it returned [$_ff_f]"
is "_fixture_floor given an empty argument leaves the caller where it stood" "$(_ff_get "$_ff_o" pwd)" "$_ff_cwant"
is "_fixture_floor given an empty argument leaves the caller's GIT_CEILING_DIRECTORIES and GIT_DIR as they were" \
   "$(_ff_get "$_ff_o" env)" "$_ff_ewant"
is "_fixture_floor given an empty argument writes nothing into the caller's directory" "$(_ff_get "$_ff_o" entries)" "0"
_ff_miss="$TMP/does-not-exist"
_ff_o="$(_ff_refuse "$_ff_miss")"
_ff_f="$(_ff_get "$_ff_o" floor)"
[ -n "$_ff_f" ] && [ "$_ff_f" -ne 0 ] && ok "_fixture_floor refuses a directory that does not exist with a non-zero status" \
  || bad "_fixture_floor refuses a directory that does not exist with a non-zero status" "it returned [$_ff_f]"
is "_fixture_floor given a directory that does not exist leaves the caller where it stood" "$(_ff_get "$_ff_o" pwd)" "$_ff_cwant"
is "_fixture_floor given a directory that does not exist leaves the caller's GIT_CEILING_DIRECTORIES and GIT_DIR as they were" \
   "$(_ff_get "$_ff_o" env)" "$_ff_ewant"
[ ! -e "$_ff_miss" ] && ok "_fixture_floor given a directory that does not exist does not create it" \
  || bad "_fixture_floor given a directory that does not exist does not create it" "it now holds: $(find "$_ff_miss" -print 2>/dev/null | tr '\n' ' ')"

# 5. GIT_CONFIG names a file that `git config` writes to with no repository at
# all (git 2.54), so a caller's GIT_CONFIG is a way out that needs no cwd. The
# floor drops it with the GIT_DIR family. The file it names is under $TMP, so a
# floor that kept it writes only there.
_ff_gcf="$TMP/floor-git-config"; : > "$_ff_gcf"; mkdir -p "$TMP/floor-gc"
_ff_o="$(GIT_CONFIG="$_ff_gcf"; export GIT_CONFIG
         _fixture_floor "$TMP/floor-gc" >/dev/null 2>&1 || { printf 'refused'; exit 0; }
         git config branch.main.remote x >/dev/null 2>&1; printf '%s|%s' "$?" "$(_ff_child GIT_CONFIG)")"
if [ "$_ff_o" = refused ]; then
  bad "_fixture_floor drops a GIT_CONFIG the caller exported, so git config from the floor writes nowhere" \
      "the floor refused [$TMP/floor-gc]"
elif [ "${_ff_o%%|*}" != 0 ] && [ "${_ff_o#*|}" = "(unset)" ] && [ ! -s "$_ff_gcf" ]; then
  ok  "_fixture_floor drops a GIT_CONFIG the caller exported, so git config from the floor writes nowhere"
else
  bad "_fixture_floor drops a GIT_CONFIG the caller exported, so git config from the floor writes nowhere" \
      "git config exited [${_ff_o%%|*}], a child sees GIT_CONFIG [${_ff_o#*|}], and the file holds [$(tr '\n' ' ' < "$_ff_gcf")]"
fi

# 6. The engine's own walk, which no ceiling binds. From a directory inside a
# checkout, under a ceiling that hides the checkout from git, git finds
# nothing and _fixture_enclosed still names the checkout, as felix_repo_root
# would. From the suite's own directory it names nothing.
_ffw="$TMP/floor-walk"; mkdir -p "$_ffw/a/b"; _ff_git init -q "$_ffw" >/dev/null 2>&1
_ff_o="$(cd "$_ffw/a/b" || exit 0; GIT_CEILING_DIRECTORIES="$_ffw/a"; export GIT_CEILING_DIRECTORIES
         git rev-parse --git-dir >/dev/null 2>&1; _ff_g=$?
         _fixture_enclosed; printf '%s|%s|%s' "$_ff_g" "$?" "${_fixture_at:-}")"
if [ "${_ff_o%%|*}" = 128 ] && [ "$(printf '%s' "$_ff_o" | cut -d'|' -f2)" = 0 ] \
   && [ -n "$(_ff_phys "$_ffw")" ] && [ "${_ff_o##*|}" = "$(_ff_phys "$_ffw")" ]; then
  ok  "_fixture_enclosed names the checkout above a directory even where git's ceiling hides it"
else
  bad "_fixture_enclosed names the checkout above a directory even where git's ceiling hides it" \
      "git exited, _fixture_enclosed returned, and it named: [$_ff_o]; the checkout is [$(_ff_phys "$_ffw")]"
fi
_ff_o="$(_fixture_enclosed; printf '%s|%s' "$?" "${_fixture_at:-}")"
is "_fixture_enclosed finds no checkout at or above the suite's working directory" "${_ff_o%%|*}" "1"

# 7 and 8. The suite's own opening lines, up to the first one after the floor,
# run as a child. A section runner's $HERE holds no suite, and there both are
# skipped.
#
# 7. The preamble acts on what the walk finds. The child's `mktemp -d` lands
# inside a checkout, which the floor's ceiling hides from git, so only the
# walk can see it. The child must refuse to start and name that checkout.
#
# 8. A `mktemp -d` that gives no directory stops the suite at once and removes
# nothing. The child starts in a directory holding one file, and its mktemp
# prints nothing. Before this stop existed, an empty $TMP became "$PWD/", and
# the exit trap removed the directory the suite was started from.
_ff_self="$(_suite_flat)"
_ff_end="$(grep -n '^FELIX_TEST_RAN="\$TMP/ran"' "$_ff_self" 2>/dev/null | head -1 | cut -d: -f1)"
if [ -z "$_ff_self" ]; then
  bad "the preamble refuses to start when its temporary directory sits inside a checkout" \
      "_suite_flat could not rebuild the suite as one file, so its preamble was not read"
  bad "a mktemp -d that gives no directory stops the suite and removes nothing" \
      "_suite_flat could not rebuild the suite as one file, so its preamble was not read"
elif [ -z "$_ff_end" ]; then
  skip "the preamble refuses to start when its temporary directory sits inside a checkout" \
       "$_ff_self is not this suite"
  skip "a mktemp -d that gives no directory stops the suite and removes nothing" \
       "$_ff_self is not this suite"
else
  _ffp="$TMP/floor-preamble"; mkdir -p "$_ffp/t"; _ff_git init -q "$_ffp" >/dev/null 2>&1
  # head.sh's REAL_HARNESS is $_ffp, which must look like a harness to get past
  # the check that follows REAL_HARNESS: a felix file and a lib/ directory.
  : > "$_ffp/felix"; mkdir -p "$_ffp/lib"
  sed -n "1,$((_ff_end - 1))p" "$_ff_self" > "$_ffp/t/head.sh"
  _ff_o="$(cd "$_ffp/t" && FFP_T="$_ffp/t" bash -c \
             'mktemp() { command mktemp -d "$FFP_T/tmp.XXXXXX"; }; export -f mktemp; bash ./head.sh' 2>&1
           printf '|rc=%s' "$?")"
  _ff_w="$(_ff_phys "$_ffp")"
  case "$_ff_o" in
    *"tests/run: $_ff_w holds a .git"*"|rc=1")
      [ -n "$_ff_w" ] && ok "the preamble refuses to start when its temporary directory sits inside a checkout" \
        || bad "the preamble refuses to start when its temporary directory sits inside a checkout" "the stand-in [$_ffp] was not made" ;;
    *)
      bad "the preamble refuses to start when its temporary directory sits inside a checkout" \
          "the suite's first $((_ff_end - 1)) lines, with mktemp inside [$_ff_w], said: [$(printf '%s' "$_ff_o" | tr '\n' ' ')]" ;;
  esac
  _ffm="$TMP/floor-nomktemp/start"; mkdir -p "$_ffm"; : > "$_ffm/sentinel"
  _ff_o="$(cd "$_ffm" && bash -c 'mktemp() { return 1; }; export -f mktemp; bash "$1"' _ "$_ffp/t/head.sh" 2>&1
           printf '|rc=%s' "$?")"
  case "$_ff_o" in
    *"mktemp -d gave no directory"*"|rc=1")
      [ -f "$_ffm/sentinel" ] && ok "a mktemp -d that gives no directory stops the suite and removes nothing" \
        || bad "a mktemp -d that gives no directory stops the suite and removes nothing" "it stopped, and [$_ffm] is gone" ;;
    *)
      bad "a mktemp -d that gives no directory stops the suite and removes nothing" \
          "with mktemp printing nothing the suite's first lines said: [$(printf '%s' "$_ff_o" | tr '\n' ' ')], and the start directory $([ -f "$_ffm/sentinel" ] && echo is intact || echo is gone)" ;;
  esac
fi

# 9. Only git's own words are a floor. A git that could not run at all says
# nothing about where the suite stands. On a PATH that has mkdir and no git,
# the floor must get past mkdir and still refuse.
_ffn="$TMP/floor-nogit"; mkdir -p "$_ffn/bin" "$_ffn/d"; ln -s "$(command -v mkdir)" "$_ffn/bin/mkdir"
_ff_o="$(PATH="$_ffn/bin"; _fixture_floor "$_ffn/d" >/dev/null 2>&1; printf '%s' "$?")"
if [ ! -d "$_ffn/d/cwd" ]; then
  bad "_fixture_floor refuses when git cannot run at all, rather than reading that as no repository" \
      "it never got past mkdir (returned [$_ff_o]), so git was not asked"
elif [ -n "$_ff_o" ] && [ "$_ff_o" -ne 0 ]; then
  ok  "_fixture_floor refuses when git cannot run at all, rather than reading that as no repository"
else
  bad "_fixture_floor refuses when git cannot run at all, rather than reading that as no repository" "it returned [$_ff_o] with no git on PATH"
fi

# 10. Nor is git's status. A .git that git cannot open makes git exit 128, as
# no repository does, and the floor must still refuse a DIR that holds one.
_ffb="$TMP/floor-badgit"; mkdir -p "$_ffb/cwd"; printf 'not a gitfile\n' > "$_ffb/.git"
_ff_g="$(cd "$_ffb/cwd" && GIT_CEILING_DIRECTORIES="$TMP" git rev-parse --git-dir >/dev/null 2>&1; printf '%s' "$?")"
_ff_o="$(_fixture_floor "$_ffb" >/dev/null 2>&1; printf '%s' "$?")"
if [ "$_ff_g" != 128 ]; then
  bad "_fixture_floor refuses a DIR whose .git git cannot open, though git exits 128 there" \
      "git exited [$_ff_g] there, so this is not the case it names"
elif [ -n "$_ff_o" ] && [ "$_ff_o" -ne 0 ]; then
  ok  "_fixture_floor refuses a DIR whose .git git cannot open, though git exits 128 there"
else
  bad "_fixture_floor refuses a DIR whose .git git cannot open, though git exits 128 there" "it returned [$_ff_o]"
fi

# 11. A walk that cannot say where it stands is no walk. With the directory
# gone from under the shell, `cd -P .` returns 0 and leaves PWD empty (bash
# 3.2.57), which the loop would read as / and answer "no checkout", or leaves
# the gone path (bash 5 on the Linux runner, found by #435's CI), which the
# loop would walk up from and answer the same.
_ffg="$TMP/floor-gone"; mkdir -p "$_ffg"
_ff_o="$(cd "$_ffg" && rmdir "$_ffg" && { _fixture_enclosed 2>/dev/null; printf '%s' "$?"; })"
is "_fixture_enclosed refuses when the directory it stands in is gone, rather than reading that as /" "$_ff_o" "2"


