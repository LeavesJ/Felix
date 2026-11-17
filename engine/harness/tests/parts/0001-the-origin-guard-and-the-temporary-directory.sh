# The command line, read before anything is made (contract D1, D2, D5). This is
# the one place that reads it: the driver's argument loop only passes -j N and
# --part over, after the refusals here, and the refusals exit 2 with one line on
# stderr before $TMP exists, so a refused run leaves nothing behind. The words
# are the driver's own: --record-assertions, --reuse, and what this reads, -j N
# and --part NAME... A word the driver does not know ends the reading, as it
# ends the driver's loop. What it leaves for the lines after it:
# - _suite_jobs, N: 1 to 64 in plain decimal, from -j N, else from
#   FELIX_TEST_JOBS, else 1. The variable is read once and unset at once, and
#   a bad one is refused whether or not -j was given. Nothing else sets
#   _suite_jobs; every other file reads it as an expansion.
# - _pm1 to _pm6, part mode's names (--part NAME...), empty when it is off, and
#   the FELIX_TEST_PART_ variables, read here and unset: _pm_log, _pm_ranf,
#   _pm_endf and _pm_rec. Part mode is keyed on the argument alone.
# - with N above 1, _sj_ord (the parts the driver sources, in its order, as
#   " NAME NAME "), and _sj_units: the units of D2, one a line in the driver's
#   order, UNIT, a tab, then its part file names with a blank between. A unit
#   is a group of tests/groups.tsv (D5) or a part in none, 0010 and later,
#   9990 left to the parent. groups.tsv is read only here and only for N above
#   1; a missing, unreadable or broken one is a refusal naming the rule.
# - FELIX_TEST_RED_JOBS, N, exported for a record run under -j N until part 0004
#   unsets it: the one variable red reads (tests/red).
_sj_die() { printf 'tests/run: %s\n' "$1" >&2; exit 2; }
_sj_n() { case "$1" in [123456789]|[12345][0123456789]|6[01234]) return 0 ;; esac; return 1; }
# -> _sj_ord is the driver's part lines, in order, each name between blanks.
_sj_order() {
  local l pre='. "$HERE/parts/' q='"'
  _sj_ord=" "
  [ -r "$HERE/run" ] || _sj_die "cannot read the driver [$HERE/run] for the order of its parts"
  while IFS= read -r l || [ -n "$l" ]; do
    case "$l" in "$pre"*"$q") l="${l#"$pre"}"; _sj_ord="$_sj_ord${l%"$q"} " ;; esac
  done < "$HERE/run"
}
# NAME -> 0 when it is a part the driver sources that a unit may run: not 0001
# to 0009, not 9990; a refusal naming WHAT otherwise.
_sj_member() {
  case "$1" in *[!abcdefghijklmnopqrstuvwxyz0123456789.-]*|"") _sj_die "$2: [$1] is not a part file name" ;; esac
  case "$_sj_ord" in *" $1 "*) ;; *) _sj_die "$2: the driver does not source [$1]" ;; esac
  case "$1" in 000[0123456789]-*|9990-*) _sj_die "$2: [$1] is a prelude part or 9990, which a unit does not run" ;; esac
}
# -> _sj_gof is " FILE=GROUP " for each member of tests/groups.tsv, read against
# the driver's order, or a refusal. One rule a refusal: a line is a group's
# name, a tab and a part's file name; the part is one the driver sources, not
# 0001 to 0009 and not 9990; it is in no other group; a group's lines are
# adjacent; its members follow one another in the driver's order with no part
# between; a group has two to six members. Lines starting # are comments, empty
# lines are ignored (R9), and an empty file is no groups.
_sj_groups() {
  local f="$HERE/groups.tsv" l g m ln=0 pg="" pm="" n=0 gs=" " cb="" h="groups.tsv line "
  _sj_gof=" "
  [ -f "$f" ] && [ -r "$f" ] || _sj_die "tests/groups.tsv is missing, not a regular file or unreadable, and -j above 1 reads it"
  while IFS= read -r l || [ -n "$l" ]; do
    ln=$((ln + 1))
    case "$l" in ""|"#"*) continue ;; esac
    case "$l" in *$'\t'*) ;; *) _sj_die "$h$ln has no tab: a line is a group's name, a tab and a part's file name" ;; esac
    g="${l%%$'\t'*}"; m="${l#*$'\t'}"
    case "$m" in *$'\t'*) _sj_die "$h$ln has more than two fields" ;; esac
    case "$g" in ""|*[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-]*|*.sh) _sj_die "$h$ln: [$g] is not a group name (letters, digits, . _ -, not ending .sh)" ;; esac
    _sj_member "$m" "$h$ln"
    case "$_sj_gof" in *" $m="*) _sj_die "$h$ln: [$m] is in more than one group, or listed twice" ;; esac
    if [ "$g" != "$pg" ]; then
      case "$gs" in *" $g "*) _sj_die "$h$ln: the lines of group [$g] are not adjacent" ;; esac
      if [ -n "$pg" ] && { [ "$n" -lt 2 ] || [ "$n" -gt 6 ]; }; then cb="${cb:-groups.tsv: group [$pg] has $n member(s): a group has two to six}"; fi
      gs="$gs$g "; pg="$g"; pm=""; n=0
    fi
    [ -z "$pm" ] || case "$_sj_ord" in *" $pm $m "*) ;; *) _sj_die "$h$ln: [$m] does not follow [$pm] in the driver's order, so the group is not contiguous" ;; esac
    _sj_gof="$_sj_gof$m=$g "; pm="$m"; n=$((n + 1))
  done < "$f"
  if [ -n "$pg" ] && { [ "$n" -lt 2 ] || [ "$n" -gt 6 ]; }; then cb="${cb:-groups.tsv: group [$pg] has $n member(s): a group has two to six}"; fi
  [ -z "$cb" ] || _sj_die "$cb"
}
# -> _sj_units, from _sj_ord and _sj_gof.
_sj_mkunits() {
  local p g cg="" cm="" u=""
  for p in $_sj_ord; do
    case "$p" in 000[0123456789]-*|9990-*) continue ;; esac
    g=""; case "$_sj_gof" in *" $p="*) g="${_sj_gof#*" $p="}"; g="${g%% *}" ;; esac
    if [ -n "$cg" ] && [ "$g" = "$cg" ]; then cm="$cm $p"; continue; fi
    [ -z "$cg" ] || u="$u$cg"$'\t'"$cm"$'\n'
    if [ -n "$g" ]; then cg="$g"; cm="$p"; else cg=""; cm=""; u="$u$p"$'\t'"$p"$'\n'; fi
  done
  [ -z "$cg" ] || u="$u$cg"$'\t'"$cm"$'\n'
  _sj_units="$u"
}
_suite_jobs=""; _sj_given=""; _sj_st=""; _sj_part=""; _sj_flags=""; _sj_ord=" "; _sj_units=""; _sj_gof=" "
_pm1=""; _pm2=""; _pm3=""; _pm4=""; _pm5=""; _pm6=""; _pm_n=0
_pm_log=""; _pm_ranf=""; _pm_endf=""; _pm_rec=""; _pm_f0=0; _pm_out=-; _pm_chg=""; _pm_path0=""
for _sj_a in "$@"; do
  if [ "$_sj_st" = j ]; then
    _sj_n "$_sj_a" || _sj_die "-j takes a number from 1 to 64 in plain decimal as its next word, not [$_sj_a]"
    _suite_jobs="$_sj_a"; _sj_st=""; continue
  fi
  case "$_sj_a" in
    -j)  [ -z "$_sj_given" ] || _sj_die "-j is given twice"
         _sj_given=1; _sj_st=j ;;
    -j*) _sj_die "-j takes its number as the next word, not in one word with it [$_sj_a]" ;;
    --record-assertions|--reuse) _sj_flags="$_sj_flags $_sj_a "; _sj_st="" ;;
    --part) [ -z "$_sj_part" ] || _sj_die "--part is given twice"
            _sj_part=1; _sj_st=p ;;
    -*)  break ;;
    *)   [ "$_sj_st" = p ] || break
         case "$_sj_a" in ""|*[!abcdefghijklmnopqrstuvwxyz0123456789.-]*) _sj_die "--part: [$_sj_a] is not a part file name" ;; esac
         _pm_n=$((_pm_n + 1))
         case "$_pm_n" in 1) _pm1="$_sj_a" ;; 2) _pm2="$_sj_a" ;; 3) _pm3="$_sj_a" ;; 4) _pm4="$_sj_a" ;; 5) _pm5="$_sj_a" ;; 6) _pm6="$_sj_a" ;;
           *) _sj_die "--part takes one to six names" ;; esac ;;
  esac
done
[ "$_sj_st" != j ] || _sj_die "-j takes a number from 1 to 64 in plain decimal as its next word"
[ -z "$_sj_part" ] || [ -n "$_pm1" ] || _sj_die "--part takes one to six names"
if [ -n "${FELIX_TEST_JOBS+x}" ]; then
  _sj_env="$FELIX_TEST_JOBS"; unset FELIX_TEST_JOBS
  _sj_n "$_sj_env" || _sj_die "FELIX_TEST_JOBS is [$_sj_env]: it must be a number from 1 to 64 in plain decimal"
  [ -n "$_suite_jobs" ] || _suite_jobs="$_sj_env"
fi
[ -n "$_suite_jobs" ] || _suite_jobs=1
if [ -n "$_sj_part" ]; then
  [ -z "$_sj_given" ] || _sj_die "--part does not go with -j"
  case "$_sj_flags" in *" --record-assertions "*) _sj_die "--part does not go with --record-assertions" ;; esac
  case "$_sj_flags" in *" --reuse "*) _sj_die "--part does not go with --reuse" ;; esac
  _sj_order
  _pm_p=""
  for _sj_a in "$_pm1" "$_pm2" "$_pm3" "$_pm4" "$_pm5" "$_pm6"; do
    [ -n "$_sj_a" ] || break
    _sj_member "$_sj_a" "--part"
    [ -z "$_pm_p" ] || case "$_sj_ord" in *" $_pm_p $_sj_a "*) ;; *) _sj_die "--part: [$_sj_a] does not follow [$_pm_p] in the driver's order: the names are contiguous" ;; esac
    _pm_p="$_sj_a"
  done
  _suite_jobs=1
  _pm_log="${FELIX_TEST_PART_LOG-}"; _pm_ranf="${FELIX_TEST_PART_RAN-}"; _pm_endf="${FELIX_TEST_PART_END-}"; _pm_rec="${FELIX_TEST_PART_RECORD-}"
  unset FELIX_TEST_PART_LOG FELIX_TEST_PART_RAN FELIX_TEST_PART_END FELIX_TEST_PART_RECORD
  [ -z "$_pm_ranf" ] || : >> "$_pm_ranf" 2>/dev/null || _sj_die "the ran file [$_pm_ranf] cannot be written"
  if [ -n "$_pm_log" ]; then
    : >> "$_pm_log" 2>/dev/null || _sj_die "the log file [$_pm_log] cannot be written"
    exec >> "$_pm_log" 2>&1
  fi
elif [ "$_suite_jobs" -gt 1 ]; then
  _sj_order; _sj_groups; _sj_mkunits
fi
# A record run under -j N hands N to red as FELIX_TEST_RED_JOBS (D4). It is
# exported here, between the argument check and red's start (the driver, after
# part 0003), and unset by the head of part 0004, so no part sees it. One the
# caller left in the environment is dropped first.
unset FELIX_TEST_RED_JOBS
if [ "$_suite_jobs" -gt 1 ]; then case "$_sj_flags" in *" --record-assertions "*) export FELIX_TEST_RED_JOBS="$_suite_jobs" ;; esac; fi
# Part mode's functions (_pm_where, _pm_start, _pm_done, _pm_fin and the shell comparison) are in part 0007.

# The remotes of the checkout this run started in, as they stood when it began.
# On 2026-10-08 at 12:47:41 a section runner took this preamble and one cut
# block, the block's fixture roots came out empty, and `( cd "" && git remote
# ... )` edited the config of the worktree the runner stood in, which every
# worktree shares: origin read acme/widget, packed-refs was rewritten, every
# refs/remotes/origin/* was gone and every branch's upstream with them. Nothing
# in the run said so; a person noticed that fetch had failed everywhere.
#
# So a run records what the config files it can reach say about their remotes
# before it does anything, and compares at the end. W, the files watched, holds
# the config in the common git directory of the checkout that encloses the
# directory the run was started in, and of the one that encloses this suite's
# own tree. They are often one file. "Encloses" is found by walking the
# physical path up for a .git entry, a directory or a file as a worktree has
# it, in the shell and with no fork; the common directory is then asked of
# git. Where the walk finds no .git, git is asked once whether the directory
# is in a repository anyway, a bare one, and its config is watched if so. When
# the common config sets extensions.worktreeConfig, the config.worktree of the
# start checkout's own git dir is watched as well, if there is one.
#
# For each file the snapshot keeps, includes followed and in file order, the
# entries that say where a remote is and what it moves: remote.<name>.url,
# pushurl, fetch, push and mirror, url.<base>.insteadOf and pushInsteadOf,
# include.path and includeIf.<condition>.path, and extensions.worktreeConfig.
# For each remote name it keeps whether a ref exists under
# refs/remotes/<name>/, and whether some branch.<b>.remote names it. A remote
# that gains refs or trackers has not moved, since a concurrent fetch or a new
# branch does that; one that had refs and has none, one a branch tracked and
# none does, or a changed entry, has. Not watched, on purpose: the other
# branch.* keys, which sessions change all day; keys outside the list, such as
# the remote.<name>.gh-resolved the gh CLI writes; and the values of remote
# refs, which concurrent fetches move.
#
# It only reads, because it runs before $TMP exists and again in the floor's
# child probes, and it prints nothing and never exits. The one thing it does
# to the shell is a cd -P to learn a physical path, undone at once, OLDPWD
# included. And it fails closed: when a .git was found and the common
# directory, the config or the refs could not be read, the snapshot is marked
# unreadable and the end of the run says so. An empty snapshot would read as
# "nothing to protect".
_og_nl=$'\n'
_og_start="$PWD"
_og_n=0; _og_cfg=(); _og_dir=(); _og_su=(); _og_sr=(); _og_st=(); _og_sok=()
_og_unread=""; _og_git=""
# The keys watched, as git config --get-regexp names them: what says where a
# remote is and what it fetches, what rewrites a url, what pulls another file
# in, and the switch that makes git read config.worktree.
_og_re='^(remote\..*\.(url|pushurl|fetch|push|mirror)|url\..*\.(insteadof|pushinsteadof)|include\.path|includeif\..*\.path|extensions\.worktreeconfig)$'
# DIR -> _og_p is its physical path, empty when it cannot be entered.
_og_phys() {
  local was="$PWD" old="${OLDPWD-}" hadold="${OLDPWD+x}"
  _og_p=""
  cd -P -- "$1" 2>/dev/null || return 1
  _og_p="$PWD"
  cd -- "$was" 2>/dev/null
  if [ -n "$hadold" ]; then OLDPWD="$old"; else unset OLDPWD; fi
  return 0
}
# PHYSICAL DIR -> _og_root is the nearest directory at or above it holding a
# .git, found by the walk felix_repo_root does; returns 1 when there is none.
_og_up() {
  _og_root="$1"
  while :; do
    [ -e "${_og_root:-/}/.git" ] && { _og_root="${_og_root:-/}"; return 0; }
    [ -n "$_og_root" ] || return 1
    _og_root="${_og_root%/*}"
  done
}
# CONFIG COMMONDIR -> _og_u holds the watched entries, one a line in file order,
# includes followed, so a value an included file supplies counts; _og_r the
# remote names with at least one ref under refs/remotes/<name>/, and _og_t
# those at least one branch.<b>.remote names, each as " a b ". Returns 1 when
# the file or the refs cannot be read: for-each-ref prints nothing and exits 0
# when refs/remotes is mode 000, so a ref directory or packed-refs that exists
# and cannot be read is unreadable, not empty. The absolute git is the one the
# run found at the start: a fixture that puts a stub git on PATH must not be
# asked about the real config. --git-dir names the repository, so an includeIf
# on gitdir reads the same at the start and at the end.
_og_rdir() { [ ! -e "$1" ] || { [ -r "$1" ] && [ -x "$1" ]; }; }
_og_read() {
  local rest line key name seen=" " out rc tr
  _og_u=""; _og_r=" "; _og_t=" "
  [ -f "$1" ] && [ -r "$1" ] || return 1
  _og_u="$("$_og_git" --git-dir="$2" config --file "$1" --includes --get-regexp "$_og_re" 2>/dev/null)"; rc=$?
  [ "$rc" -le 1 ] || return 1
  tr="$("$_og_git" --git-dir="$2" config --file "$1" --includes --get-regexp '^branch\..*\.remote$' 2>/dev/null)"; rc=$?
  [ "$rc" -le 1 ] || return 1
  { [ ! -e "$2/packed-refs" ] || [ -r "$2/packed-refs" ]; } && _og_rdir "$2/refs/remotes" || return 1
  tr="$_og_nl$tr$_og_nl"
  rest="$_og_u"
  while [ -n "$rest" ]; do
    line="${rest%%"$_og_nl"*}"
    case "$rest" in *"$_og_nl"*) rest="${rest#*"$_og_nl"}" ;; *) rest="" ;; esac
    key="${line%% *}"
    case "$key" in remote.*.*) ;; *) continue ;; esac
    name="${key#remote.}"; name="${name%.*}"
    case "$seen" in *" $name "*) continue ;; esac
    seen="$seen$name "
    _og_rdir "$2/refs/remotes/$name" || return 1
    out="$("$_og_git" --git-dir="$2" for-each-ref --count=1 --format=x "refs/remotes/$name/" 2>/dev/null)" || return 1
    [ -z "$out" ] || _og_r="$_og_r$name "
    case "$tr" in *" $name$_og_nl"*) _og_t="$_og_t$name " ;; esac
  done
  return 0
}
# CONFIG COMMONDIR -> CONFIG joins the watched files, read now, unless it is
# there already.
_og_watch() {
  local i=0
  while [ "$i" -lt "$_og_n" ]; do
    [ "${_og_cfg[$i]}" != "$1" ] || return 0
    i=$((i+1))
  done
  _og_dir[$_og_n]="$2"; _og_cfg[$_og_n]="$1"
  if _og_read "$1" "$2"; then _og_sok[$_og_n]=1; else _og_sok[$_og_n]=0; _og_unread="$_og_unread$1$_og_nl"; fi
  _og_su[$_og_n]="$_og_u"; _og_sr[$_og_n]="$_og_r"; _og_st[$_og_n]="$_og_t"
  _og_n=$((_og_n+1))
}
# DIR [start] -> the config of the repository enclosing DIR joins the watched
# files, or the snapshot is marked unreadable. A start directory that cannot be
# entered encloses nothing. When the walk finds no .git, git is asked once,
# read-only, whether DIR is in a repository all the same, a bare one: status
# 128 with "not a git repository" on its stderr, read in the C locale, is no;
# 0 with a directory named is yes; anything else is unreadable. Status 128
# alone is not a no: a fork that fails inside the capture gives 128 with
# nothing said, and git gives 128 too for a repository it finds and will not
# open.
# For the start directory, when the common config sets
# extensions.worktreeConfig, the config.worktree of its own git dir is watched
# too, if it exists. Nothing here prints, and nothing exits.
_og_add() {
  local root at c rc g k
  _og_phys "$1" || return 0
  [ -n "$_og_git" ] || _og_git="$(command -v git 2>/dev/null)"
  [ -n "$_og_git" ] || return 0
  if _og_up "$_og_p"; then root="$_og_root"; at="$root/.git"; else root="$_og_p"; at=""; fi
  if [ -n "$at" ]; then
    c="$( unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR; "$_og_git" -C "$root" rev-parse --git-dir --git-common-dir 2>/dev/null )"; rc=$?
  else
    # Both streams, so the no can be read; on status 0 a line git wrote to
    # stderr spoils the two paths, and that reads as unreadable, not as no.
    c="$( unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR; LC_ALL=C "$_og_git" -C "$root" rev-parse --git-dir --git-common-dir 2>&1 )"; rc=$?
    if [ "$rc" -eq 128 ]; then
      case "$c" in *"not a git repository"*) return 0 ;; esac
    fi
    at="$root"
  fi
  [ "$rc" -eq 0 ] || c=""
  case "$c" in *"$_og_nl"?*) g="${c%%"$_og_nl"*}"; c="${c#*"$_og_nl"}" ;; *) g=""; c="" ;; esac
  case "$g" in ""|/*) ;; *) g="$root/$g" ;; esac
  case "$c" in ""|/*) ;; *) c="$root/$c" ;; esac
  if [ -z "$c" ] || ! _og_phys "$c" || [ ! -f "$_og_p/config" ]; then
    _og_unread="$_og_unread$at$_og_nl"
    return 0
  fi
  k="$_og_p"
  _og_watch "$k/config" "$k"
  [ "${2:-}" = start ] || return 0
  [ "$("$_og_git" config --file "$k/config" --type=bool --get extensions.worktreeconfig 2>/dev/null)" = true ] || return 0
  [ -n "$g" ] && _og_phys "$g" && [ -f "$_og_p/config.worktree" ] || return 0
  _og_watch "$_og_p/config.worktree" "$k"
}
_og_add "$_og_start" start
_og_add "$REAL_HARNESS"

# This shell's pid, never $$, which a child keeps from its parent: BASHPID in
# bash 4 and later, and in bash 3.2, which has none, the PPID of a sh exec'd
# in a $(...) of this shell, which is this shell (lib/qualify-run.sh reads its
# own the same way). _tmp_pid is that read as text, so each EXIT trap below
# can make it again in whichever process runs it. No pid, no suite: those
# traps tell this shell from a child by it.
_tmp_pid='if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then _tmp_me="$BASHPID"; else _tmp_me="$(exec /bin/sh -c '\''echo "$PPID"'\'' 2>/dev/null)"; fi'
eval "$_tmp_pid"; _tmp_by="$_tmp_me"
case "$_tmp_by" in ''|*[!0123456789]*)
  printf 'tests/run: could not read this shell'\''s pid ([%s]); not starting\n' "$_tmp_by" >&2
  exit 1 ;;
esac
# R29: GNU mktemp honours TMPDIR and names a relative one relatively. Made absolute
# against the start directory, once, before $TMP is, so that mktemp, the slots
# directory and every child, units and parts included, see one path. (An empty
# TMPDIR stays as it is: mktemp reads it as unset.)
case "${TMPDIR-}" in ''|/*) ;; *) TMPDIR="$_og_start/$TMPDIR"; export TMPDIR ;; esac
TMP="$(mktemp -d)"
# No directory, no suite. The substitution forks twice, and when the inner fork
# fails under load it hands back nothing with status 128 while this shell
# carries on (bash 3.2.57). Every path below is "$TMP/...", and the trap
# removes "$TMP": an empty one turned into "$PWD/" would remove the checkout
# the suite was started from.
[ -n "$TMP" ] && [ -d "$TMP" ] || {
  printf 'tests/run: mktemp -d gave no directory ([%s]); not starting\n' "$TMP" >&2
  exit 1
}
# GNU mktemp names a relative TMPDIR relatively, and the suite is about to
# leave the directory that name is relative to.
case "$TMP" in /*) ;; *) TMP="$PWD/$TMP" ;; esac
# Only the shell that made $TMP removes it. A child bash forks keeps this trap
# until it resets the traps it inherited, and bash 5.2 acts on an INT or TERM
# that reached it before then: execute_in_subshell checks for a terminating
# signal first, and runs the EXIT trap it still holds. Part 0573 sends INT to
# a run it forked a moment before, and on 2026-10-16 that child removed $TMP
# on Linux CI while the suite carried on without it (slot 3f). So the trap
# reads the pid of the process running it and removes $TMP only when that is
# _tmp_by. One that cannot read it leaves $TMP: a leak, never a removal from
# under a suite still running. Not BASH_SUBSHELL: nothing says a child bash
# has counted itself a subshell by the time it acts on the signal.
trap "$_tmp_pid"'; [ "$_tmp_me" != "$_tmp_by" ] || rm -rf "$TMP"' EXIT
# No fixture git command reaches a repository outside $TMP. On 2026-10-08 one
# did. A section runner took this preamble and the setup block, but not the
# helpers that make the block's fixture directories, so its roots came out
# empty, and in bash 3.2 `( cd "" && git remote set-url origin ... )` exits 0
# where it stands. The runner stood in a developer's worktree, and every
# worktree shares one .git/config. So felix-home's origin came to read
# https://github.com/acme/widget.git, with no refs/remotes/origin left and no
# branch's upstream. That block's own lines, run with both roots empty from a
# worktree of a scratch clone, do exactly that. A fork that fails inside
# `$(_fh_root ...)` under load is a second way to an empty root. A fixture
# directory whose `git init` never ran does the same damage with no empty
# variable, since git walks up to whatever repository encloses it. So does a
# GIT_DIR the caller left in the environment.
#
# A guard on each line would leave the next line written unguarded, so this
# closes the class for every fixture that names its repository by the
# directory it stands in:
# - the suite stands in $TMP/cwd, so an empty root resolves inside $TMP. A
#   root with something after it is not covered: `cd "$empty/x"` lands at /x,
#   or fails;
# - GIT_CEILING_DIRECTORIES is $TMP's PARENT, so no git command run at or
#   below $TMP walks up out of it. A ceiling is a directory git will not climb
#   INTO. With $TMP as the ceiling, a cwd of $TMP itself, which
#   `cd "$TMP/$empty"` reaches, still climbs into its parent (measured, git
#   2.54). And a ceiling alone, with the suite left in the worktree, stops
#   nothing, since the worktree is not below it;
# - the variables that point git at a repository whatever the cwd are unset.
#   So is GIT_CONFIG, which `git config` writes to even with no repository at
#   all (git 2.54), and OLDPWD, which `cd -` would follow back to the worktree.
# Then the floor is tried: from where the suite now stands, git must say, in
# its own words, that this is not a git repository. Its status alone will not
# do. Git exits 128 too for a repository it finds and refuses to open (dubious
# ownership, a broken .git file), and a git that could not run at all says
# nothing about where the suite stands. Any other answer, and the suite
# refuses to start. A fork that fails inside that capture leaves it empty, and
# empty is a refusal.
#
# The parent is read from $PWD once the shell stands in DIR/cwd, not from
# `$(dirname ...)`, so no fork can fail into an empty ceiling under load. And
# bash has already folded a trailing or doubled slash, which would otherwise
# leave DIR as its own parent. A simple command whose fork fails here kills
# the shell with status 128 (bash 3.2.57), so the suite stops rather than
# starts.
_fixture_floor() {   # DIR -> this shell stands in DIR/cwd, and git cannot walk out of DIR
  local said
  [ -n "${1:-}" ] && [ -d "$1" ] || return 1
  mkdir -p "$1/cwd" && cd "$1/cwd" || return 1
  unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
        GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG OLDPWD
  GIT_CEILING_DIRECTORIES="${PWD%/cwd}"; GIT_CEILING_DIRECTORIES="${GIT_CEILING_DIRECTORIES%/*}"
  export GIT_CEILING_DIRECTORIES
  # The same test the origin guard puts to a start with no .git above it:
  # status 128 and "not a git repository" in the C locale, both.
  said="$(LC_ALL=C git rev-parse --git-dir 2>&1 >/dev/null)"
  [ "$?" -eq 128 ] || return 1
  case "$said" in *"not a git repository"*) return 0 ;; esac
  return 1
}
# The ceiling binds git and nothing else. felix_repo_root, which the CLI
# calls before most of what it writes, climbs the physical path for a .git by
# itself and asks git only when it finds none. So a fixture that runs the CLI
# from an empty root would reach any checkout that encloses $TMP, ceiling or
# not. On macOS `mktemp -d` ignores TMPDIR, and nothing above /private/var/folders
# is a checkout. Elsewhere TMPDIR can sit inside one, and then the suite does
# not start. The walk is the engine's, done from where the shell stands, with
# no fork: `cd -P .` makes $PWD physical in place. It also looks at / itself,
# which the engine's stops short of and git would not.
_fixture_enclosed() {   # -> 0 when this directory or one above it, physically, holds a .git; _fixture_at names it
  cd -P . || return 2
  # A directory gone from under the shell: bash prints an error and returns 0,
  # and leaves PWD empty (3.2.57, which the loop would read as /) or the gone
  # path itself (5.x on the Linux runner, which the loop would walk up from as
  # if it stood). Either way PWD is not the directory the shell stands in.
  [ -n "$PWD" ] && [ -d "$PWD" ] && [ "$PWD" -ef . ] || return 2
  _fixture_at="$PWD"
  while :; do
    [ -e "${_fixture_at:-/}/.git" ] && { _fixture_at="${_fixture_at:-/}"; return 0; }
    [ -n "$_fixture_at" ] || return 1
    _fixture_at="${_fixture_at%/*}"
  done
}
_fixture_floor "$TMP" || {
  printf 'tests/run: could not stand in %s/cwd out of git'"'"'s reach (it stands in %s); not starting\n' "$TMP" "$PWD" >&2
  exit 1
}
_fixture_enclosed; case $? in
  1) ;;
  0) printf 'tests/run: %s holds a .git, and %s is below it. Felix walks up to it past any ceiling, so a fixture could edit it. Run where mktemp -d lands outside every checkout (TMPDIR, where mktemp honours it); not starting\n' "$_fixture_at" "$PWD" >&2
     exit 1 ;;
  *) printf 'tests/run: could not read where %s sits; not starting\n' "$PWD" >&2
     exit 1 ;;
esac
# Every assertion that RAN is recorded by name, whatever its verdict (the driver
# defines _ran and compares the record at its end).
#
# #67: two assertions execute on macOS and never run on the Linux runner — no
# pass, no fail, no skip line. Measured as a constant gap of 2 across three
# unrelated commits, including a pre-session main, and not caused by the
# `claude` CLI: hiding claude locally converts four passes into four skips and
# leaves the attempted total unchanged, while CI attempts two fewer.
#
# A total alone cannot say which two. This records names so the suite can
# compare what it ran against what it is supposed to run, and name the
# difference. A count that silently drops is indistinguishable from a passing
# run, which is the property this repository most needs not to have.
#
# The comparison at the end of the driver goes one way only: a manifest
# assertion that did not run is the silent defect, and fails; one that ran and
# is not listed is a forgotten record, and is noted. It counts per name, not as
# a set: some names appear more than once (nineteen on 2026-10-01).
#
# Appended to a file rather than accumulated in a variable, because a shell
# variable does not survive the subshells some of these assertions run inside —
# the same reason PASS and FAIL are incremented in the main shell only.
#
# Some assertions describe the machine, not Felix: whether a real plugin is
# installed depends on the claude CLI existing. Skipping is honest; passing them
# by accident on a runner that has no CLI would be worse than not running them.
# A skip counts as REACHED here: the distinction that matters is between an
# assertion the suite decided about and one it never got to.
FELIX_TEST_RAN="$TMP/ran"; : > "$FELIX_TEST_RAN"
