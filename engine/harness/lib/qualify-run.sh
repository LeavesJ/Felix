# The row runner of checker qualification: one row of qualification.tsv run in
# a scratch worktree of HEAD, and the tree thrown away after it.
#
# Split out of lib/qualify.sh along its run/read seam: that file reads the
# table, walks the rows and counts the verdicts; this one runs one row and
# answers pass, fail, unrunnable or inapplicable. lib/qualify.sh sources it, so
# a caller still sources lib/qualify.sh alone. What the columns are, what a
# premise means and what the runner hears are in lib/qualify.sh's header.
#
# The sweep that removes the trees of rows killed past their traps,
# _felix_qualify_sweep, is in lib/qualify-sweep.sh, sourced here.
. "${BASH_SOURCE[0]%/*}/qualify-sweep.sh"

# Throw one row's scratch tree away: the worktree, its registration in the
# root's repository, and the directory mktemp made to hold them.
#
# Until 2026-10-01 this was `git worktree remove --force` and `rmdir`, and a
# mutation beat both several ways. Each step below closes one, measured on
# git 2.54 and bash 3.2:
#
#   - `mkdir d && touch d/f && chmod a-w d`, a control with every reason to
#     stage an unwritable file, left git unable to unlink d/f: the remove
#     failed, the rmdir failed, the checkout stayed. A retry cannot mend it,
#     since git drops the registration on its way out of a failed remove. So
#     every directory short of the owner's rwx gets it back first, before git
#     runs; deleting needs the bits on the directory, not on the file. From
#     inside the base (_felix_qualify_in), the base itself as ., then the rest
#     one at a time from the top, so a 000 one is opened before find reads
#     it, every path relative to the directory entered; the base by name only
#     when it cannot be entered, its x gone, and only while it is no
#     symlink. Only directories: a file's mode is its inode's, and a hard
#     link a mutation made (`git clone . sub` makes them of the root's
#     objects) would carry chmod outside the base. find descends into no
#     symlink, and no user can hard-link a directory; but the chmod it runs
#     takes each path by name once find has looked, and follows a symlink
#     (below). A directory deeper than PATH_MAX is past chmod's reach, and is
#     left and said.
#   - A scratch tree or a base swapped for a symlink is unlinked, never
#     followed: `git worktree remove` resolves a path it does not list, and
#     through a link to another worktree of the root it deleted that
#     worktree, uncommitted work and all. The base gets its bits back before
#     the tree's link is unlinked, from inside the base, and a link that is
#     still there afterwards stops the drop, said: nothing is handed to git
#     or rm through it.
#   - git is handed the tree's path exactly as the root lists it, read off
#     its list just before (_felix_qualify_reg), and nothing when the root
#     lists no such entry. A path given as T was, through a symlink, was not
#     an entry; git resolved it, and a base or a tree swapped for a symlink a
#     moment before git ran led it to another worktree of the root, which it
#     removed (review round 2). Its exact entry, git takes as that entry, and
#     checks that the tree's .git names it before removing anything; through
#     a swapped link it names another, and git refuses.
#   - A base the mutation took away is made again, empty, so that $base/w
#     resolves to the path git registered.
#   - -f twice, so a tree the mutation locked is removed too.
#   - A remove git refuses (the tree's .git is gone) is tried again once the
#     directory is: git removes a registration whose directory is missing.
#
# Then the base goes whole: the column stderr file and whatever a mutation
# wrote beside the tree are the runner's own. Its owner record goes last
# (_felix_qualify_unown), so a base this cannot empty, or a drop killed half
# way, still names a process a later run's sweep can judge. Those steps, and
# the rm of a tree git would not remove, act inside the base, entered and
# checked to be the base itself (_felix_qualify_in): a base swapped for a
# symlink after the check above, by a process the row left running, is never
# followed into, where a glob through its name emptied the link's target
# (review 2026-10-01). What is still
# there after all that is said, on stderr, from what is there and not from an
# exit status: the base on disk, or the tree still in git worktree list.
# Nothing is pruned beyond this row's entry; other entries are not the
# runner's.
#
# What it cannot reach: a process the mutation left running, which can write
# into the base after this has removed it, and can swap a name for a symlink
# between a check here and the act on it: the chmod of the base by name, when
# it cannot be entered, after the test that it is no symlink; and each chmod
# the find walk runs, after find has looked at that directory. chmod follows
# the link, and gives its target the owner's rwx. And the instants inside
# git, once its check of the tree's .git has passed, and between this
# reading the root's list and git reading it, should the entry go in between.
_felix_qualify_drop() {   # root, base
  local root="$1" base="$2" pdir="" _felix_qualify_text
  [ -n "$base" ] || return 0
  if [ -L "$base" ]; then
    rm -f "$base" 2>/dev/null
    if [ -L "$base" ]; then
      printf 'felix: the scratch directory %s is a symlink that could not be removed, so nothing is removed through it\n' "$base" >&2
      return 0
    fi
    printf 'felix: the scratch directory %s had been replaced by a symlink, so whatever the row moved out of it is not removed\n' "$base" >&2
  fi
  [ -e "$base" ] || mkdir "$base" 2>/dev/null
  if ! _felix_qualify_in "$base" _felix_qualify_rwx; then
    [ -d "$base" ] && [ ! -L "$base" ] && chmod u+rwx "$base" 2>/dev/null
    _felix_qualify_in "$base" _felix_qualify_rwx
  fi
  if [ -L "$base/w" ]; then
    _felix_qualify_in "$base" _felix_qualify_unlinkw
    if [ -L "$base/w" ]; then
      printf 'felix: the scratch worktree %s is a symlink that could not be removed, so nothing is removed through it\n' "$base/w" >&2
      return 0
    fi
  fi
  _felix_qualify_phys "${base%/*}" && pdir="$_felix_qualify_text"
  _felix_qualify_reg "$root" "$base" "$pdir"
  if [ -n "$_felix_qualify_text" ] && ! git -C "$root" worktree remove -f -f "$_felix_qualify_text" >/dev/null 2>&1; then
    _felix_qualify_in "$base" _felix_qualify_rmw
    _felix_qualify_reg "$root" "$base" "$pdir"
    if [ -n "$_felix_qualify_text" ] && ! git -C "$root" worktree remove -f -f "$_felix_qualify_text" >/dev/null 2>&1; then
      _felix_qualify_reg "$root" "$base" "$pdir"
      [ -z "$_felix_qualify_text" ] ||
        printf 'felix: %s still lists the scratch worktree %s, which could not be removed\n' \
               "$root" "$base/w" >&2
    fi
  fi
  # Twice: a sweep that judged the record dead a moment before this base was
  # claimed may link its own claim here between the clear and the look, for
  # as long as its check of owner takes (lib/qualify-sweep.sh).
  _felix_qualify_clear "$base"
  _felix_qualify_unown "$base" || { _felix_qualify_clear "$base"; _felix_qualify_unown "$base"; }
  if [ -e "$base/w" ] || [ -L "$base/w" ]; then
    printf 'felix: the scratch worktree %s could not be deleted, and stays on disk\n' "$base/w" >&2
  elif [ -e "$base" ]; then
    printf 'felix: the scratch directory %s could not be deleted, and stays on disk\n' "$base" >&2
  fi
}

# A directory's physical path, every byte of it, in _felix_qualify_text,
# which the caller makes local: $(...) drops every trailing newline, and a
# path may end in one, so a sentinel keeps them. Non-zero when it cannot be
# had.
_felix_qualify_phys() {   # dir
  local t nl='
'
  _felix_qualify_text=""
  t="$(CDPATH='' cd -P -- "$1" 2>/dev/null && pwd -P && printf x)" || return 1
  t="${t%x}"; _felix_qualify_text="${t%"$nl"}"
  [ -n "$_felix_qualify_text" ]
}

# Run a function inside a base: entered by cd, then checked to be the base
# itself, its physical path its parent's and its own name. A base swapped for
# a symlink is never entered, and every name after is taken relative to the
# directory entered, which a later swap of the base's name cannot change. Its
# own process, so neither the cd nor the glob options reach a caller: the
# globs inside list a base whatever the caller set (_felix_qualify_globs).
# The function gets the base's physical path. Non-zero when the base cannot
# be entered so.
_felix_qualify_in() {   # base, function
  ( case "$1" in */*) ;; *) exit 1 ;; esac
    _felix_qualify_phys "${1%/*}" || exit 1
    want="$_felix_qualify_text/${1##*/}"
    CDPATH='' cd -P -- "$1" 2>/dev/null || exit 1
    _felix_qualify_phys . && [ "$_felix_qualify_text" = "$want" ] || exit 1
    _felix_qualify_globs
    "$2" "$want" )
}

# The shell's options a glob or a case pattern here depends on, set as this
# code reads them, in a process of its own: the felix CLI and the row loop
# run under whatever the user's BASH_ENV, SHELLOPTS or BASHOPTS set. Under
# failglob a glob that matched nothing stopped the run before its first row;
# under noglob nothing was listed, so a base was never emptied and the sweep
# found nothing (review 2026-10-01). Globbing on, no failglob, no case
# folding in a glob or a case pattern, no dotglob, nullglob, no GLOBIGNORE.
_felix_qualify_globs() {
  set +f
  shopt -u failglob nocaseglob nocasematch dotglob 2>/dev/null
  shopt -s nullglob 2>/dev/null
  unset GLOBIGNORE
}

# A tree git would not remove, removed from inside its base: rm -rf takes a
# symlink operand as the link.
_felix_qualify_rmw() { rm -rf ./w 2>/dev/null; return 0; }

# From inside a base: the owner's rwx on it and on every directory below it,
# one at a time from the top, so a 000 one is opened before find reads it.
# find descends into no symlink, and every path it hands chmod is relative
# to the directory entered; chmod itself follows a directory swapped for a
# symlink after find looked (the drop's header). And a tree that is a
# symlink, unlinked.
_felix_qualify_rwx() {
  chmod u+rwx . 2>/dev/null
  find . -type d ! -perm -0700 -exec chmod u+rwx {} \; 2>/dev/null
  return 0
}
_felix_qualify_unlinkw() { [ -L w ] && rm -f ./w 2>/dev/null; return 0; }

# The path this root's git lists a base's tree at, exactly as it lists it, in
# _felix_qualify_text, which the caller makes local: under T's physical path,
# as git records it, or else as the base was given. Empty when the root lists
# neither or its list cannot be had. git worktree remove takes a path it
# lists exactly as that entry, and only a path it does not list is resolved
# and matched against every entry resolved: through a base or a tree swapped
# for a symlink that resolution reached another worktree of the root, and
# removed it, uncommitted work and all, when T was given through a symlink
# (review round 2). Given its own exact entry, git checks that the tree's
# .git names that entry before it removes anything, and through a swapped
# link it names another, so git refuses.
_felix_qualify_reg() {   # root, base, T's physical path or empty
  local listed nl='
'
  _felix_qualify_text=""
  listed="$(git -C "$1" worktree list --porcelain 2>/dev/null)" || return 0
  if [ -n "$3" ]; then
    case "$nl$listed$nl" in
      *"${nl}worktree $3/${2##*/}/w$nl"*) _felix_qualify_text="$3/${2##*/}/w"; return 0 ;;
    esac
  fi
  case "$nl$listed$nl" in *"${nl}worktree $2/w$nl"*) _felix_qualify_text="$2/w" ;; esac
  return 0
}

# Every entry of a base but its owner record, removed: _felix_qualify_clear
# from outside, _felix_qualify_clear_here inside. rm -rf takes a symlink
# operand as the link, so nothing is followed out of the base. The three
# globs are every name but . and ..; under the nullglob _felix_qualify_in
# sets, one that matched nothing gives no name.
_felix_qualify_clear() { _felix_qualify_in "$1" _felix_qualify_clear_here; }
_felix_qualify_clear_here() {
  local e
  for e in * .[!.]* ..?*; do
    [ "$e" = owner ] && [ -L owner ] && continue
    [ -e "$e" ] || [ -L "$e" ] || continue
    rm -rf "./$e" 2>/dev/null
  done
  return 0
}

# A base's owner record removed only once it is the base's last entry, then
# the base. Non-zero while anything else is in it, with the record kept, and
# when the base will not go: an entry that appeared between the look and the
# rmdir is a writer the drop never saw, and the record is put back, so the
# base still names a process a later sweep can judge. The rmdir names the
# base by its physical path, and fails on a symlink put in its place; the
# record goes back into the directory entered, wherever its name now is, with
# ln -n, so an owner put there meanwhile as a symlink to a directory makes ln
# fail rather than lead the record into that directory (review round 3).
_felix_qualify_unown() { _felix_qualify_in "$1" _felix_qualify_unown_here; }
_felix_qualify_unown_here() {   # the base's physical path -> 0 once it is gone
  local e rec=""
  for e in * .[!.]* ..?*; do
    [ "$e" = owner ] && [ -L owner ] && continue
    if [ -e "$e" ] || [ -L "$e" ]; then return 1; fi
  done
  if [ -L owner ]; then
    rec="$(readlink -n owner 2>/dev/null; printf x)"; rec="${rec%x}"
    rm -f owner 2>/dev/null
  fi
  rmdir -- "$1" 2>/dev/null && return 0
  if [ -n "$rec" ] && [ ! -e owner ] && [ ! -L owner ]; then
    ln -s -n -- "$rec" owner 2>/dev/null
  fi
  return 1
}

# The owner record of the process running this: `<pid> <start>`, or `<pid>`
# when no start can be had, set in _felix_qualify_rec, which the caller makes
# local. Non-zero when no pid can be had.
#
# The pid is the process's own, never $$, which a subshell keeps from its
# parent: a row runs in the $(...) the row loop calls it in, and the CLI that
# owns $$ outlives a row it lost to a kill. Bash 4 and later name it BASHPID.
# Bash 3.2, the engine's floor on macOS, has no BASHPID, and a variable of
# that name there is only one the environment brought; a sh exec'd in a
# $(...) of this process is its child, and its PPID is this process (measured
# 2026-10-01 on bash 3.2.57). It is set here, never printed: a $(...) around
# this function would be a process of its own and record that. The sh is
# /bin/sh by its path, never one PATH names: a wrapper that runs sh without
# exec forks, and the PPID it reports is the wrapper's own, gone once the
# $(...) returns, so a live row would record a dead pid and another run's
# sweep would take its tree. And the pid must be a live process when it is
# read back, else no record is made and the row runs nothing.
#
# The start tells a pid the kernel has handed to another process since from
# the process that wrote it, and on Linux names the pid namespace the pid
# means something in (_felix_qualify_since, lib/qualify-sweep.sh).
_felix_qualify_me() {   # -> _felix_qualify_rec
  local p s _felix_qualify_text
  _felix_qualify_rec=""
  if [ "${BASH_VERSINFO[0]:-3}" -ge 4 ] 2>/dev/null; then
    p="${BASHPID:-}"
  else
    p="$(exec /bin/sh -c 'echo "$PPID"' 2>/dev/null)"
  fi
  case "$p" in ''|0*|*[!0123456789]*) return 1 ;; esac
  [ "${#p}" -le 10 ] || return 1
  kill -0 "$p" 2>/dev/null || return 1
  _felix_qualify_since "$p"; s="$_felix_qualify_text"
  _felix_qualify_rec="$p${s:+ $s}"
}

# A row's base made to name the row's own process: `owner`, a symlink whose
# text is the record. One symlink(2), so a sweep reads the text whole or not
# at all; the link points at nothing and is never followed. Non-zero when it
# cannot be made.
_felix_qualify_own() {   # base
  local _felix_qualify_rec
  _felix_qualify_me || return 1
  ln -s -- "$_felix_qualify_rec" "$1/owner" 2>/dev/null && [ -L "$1/owner" ]
}

# The traps that throw a row's tree away when the row is stopped, set in the
# row's own process, because that is the one place that can act on them in
# time. A trap in cmd_qualify or the row loop runs only once the $(...) it
# waits on returns: measured 2026-10-01 on bash 3.2, a caller's TERM trap ran
# six seconds late, after the row had finished. The row's process is in the
# process group that a terminal's Ctrl-C, timeout and a tool's kill all
# signal, and it carries the CLI's command line, so a kill by pattern reaches
# it too. The trap runs once the column in flight has ended: at once when the
# signal went to the group and the column does not catch it, and otherwise at
# the column's own end. Then the tree goes, no later column runs, and the row
# exits 128+N.
#
# It ignores the three first: a child inherits an ignored signal, so a second
# Ctrl-C cannot cut git off half way through the tree. And it prints
# unrunnable, because a row loop that was not signalled itself is still
# reading, and a row that printed nothing was counted held, a claim about a
# checker that never finished. PIPE is ignored for that one write: when the
# loop is gone, the write fails rather than ending the row with SIGPIPE.
#
# What no trap reaches. SIGKILL. And a signal sent to the CLI's process alone,
# which leaves the row to run to its end and throw its tree away there, as
# every row always has. Without a trap, TERM and HUP ended the row where it
# stood (a group INT did not, on bash 3.2: the row went on and removed its
# tree), and three trees from runs stopped mid-row were found in the
# founder's checkout on 2026-09-25, still registered.
_felix_qualify_arm() {   # root, base
  local r b s n
  printf -v r '%q' "$1"; printf -v b '%q' "$2"
  for s in INT:130 TERM:143 HUP:129; do
    n="${s#*:}"; s="${s%%:*}"
    trap "trap '' INT TERM HUP PIPE; _felix_qualify_drop $r $b; printf unrunnable 2>/dev/null; exit $n" "$s"
  done
}

# Run one row: a real worktree of HEAD, the mutation applied to it, the checker
# run in it, the tree thrown away.
#
# A worktree rather than a copy, because a checker may read git — history, what
# is tracked, what is ignored — and a bare directory of files would make every
# such checker fail for a reason that has nothing to do with the mutation. It
# shares the object store, so this costs a checkout and not a clone.
#
# Each column runs in a bash of its own (_felix_qualify_sh). Until 2026-09-25
# each was an eval in the caller's process, which for felix qualify and felix
# gate is the felix CLI and its set -uo pipefail. Under pipefail
# `producer | grep -q x` fails with x present: grep leaves at its first match
# and the producer dies of SIGPIPE, 141, certain past a pipe's 64 KB with the
# match early and load-dependent below it, as bash 3.2's printf writes a
# multi-line value one write() per line. So a premise read unrunnable, or,
# negated, applied its control where its premise is absent; a mutation's &&
# chain stopped short and a pass control was met over a change the checker
# never saw; a command read fail, which on a fail control is met, exactly what
# a working checker says, or in the schema rows' negated shape pass, a false
# held. nounset stopped a row at a name it never set, with exit 1, the same
# ways.
#
# A fresh bash also sees none of the engine's functions or variables, and for
# qualification that is right. The checker under test is the one in the tree
# the mutation changed, engine/harness/bin/* as the mutation left it, run as a
# process of its own that sets its own options. An engine function a row named
# would be the installed engine's code, which no mutation reaches, so the row
# would qualify the wrong code.
#
# Whatever the header says is heard, _felix_qualify_sh returns as 127, save a
# final 126, which it returns as it is. Read by its status, a command that ran
# no checker was fail, met on every fail control, the dangerous direction again,
# and a mutation that made no change left its pass control met over nothing, so
# no command runs after one. In a fresh bash an engine function is command not
# found, as is a checker path with a typo; 126 is a file that is not executable,
# or a tree that could not be entered. In a pipeline, an if, or behind ! or ||,
# the final status hides a name not found, and bash -n does not look inside
# $( ), backticks or eval, so the column's stderr goes to a file beside the
# tree and is scanned. Only the column's own shell prints under the $0 it is
# given; a checker's messages carry its path. A stderr that cannot be read
# reads as nothing run. The file is left for the next column's
# _felix_qualify_errfile or the drop to take, never removed here by its
# path: a column that swapped the base for a symlink to a directory outside
# had that rm delete a file named err there (review round 3). Every other
# status keeps its meaning.
#
# That file sits beside the tree, where a mutation can reach it as ../err,
# so each column makes it new before it runs (_felix_qualify_errfile). A
# redirection that fails runs nothing and returns 1, which on the command
# reads fail, met on a fail control: `chmod -R a-w ..` did that with the
# checker never run. And a 2> follows a link, so `ln -s $OUT ../err` sent
# the next column's stderr into a file outside the base. A file that cannot
# be made new, plain and empty, is a column that ran nothing. Both ends are
# opened on it before the column runs, 8 to write and 9 to read, and the
# column gets 8 as its stderr and neither descriptor besides. So a link or a
# fifo the column puts in the file's place changes neither what the scan
# reads nor the verdict, and grep cannot be left waiting on a fifo; what the
# column writes into the file through the path is the hidden-stderr case
# above. An end that will not open leaves said at 2, a column that ran
# nothing, with bash's own line about it. The write end is 8>|, since a
# caller's noclobber would refuse to write over the file just made.
#
# The parse and the row run without SHELLOPTS or BASHOPTS, which carry the
# caller's set and shopt options into a child bash, BASH_ENV, whose file a
# child bash runs first, or POSIXLY_CORRECT, whose posix mode before bash 5.1
# cannot parse <( ). And `--`, because bash reads a text that begins with a dash as its own
# options, and "invalid option" exits 2.
_felix_qualify_sh() {   # dir, text, stderr file outside dir -> the text's own status; 127 if it ran nothing
  local rc said
  case "${2#"${2%%[![:space:]]*}"}" in ''|'#'*) return 127 ;; esac
  env -u SHELLOPTS -u BASHOPTS -u BASH_ENV -u POSIXLY_CORRECT \
    bash -n -c -- "$2" felix-qualify </dev/null >/dev/null 2>&1 || return 127
  _felix_qualify_errfile "$3" || return 127
  said=2
  { ( cd "$1" 2>/dev/null || exit 126
      env -u SHELLOPTS -u BASHOPTS -u BASH_ENV -u POSIXLY_CORRECT \
        bash -c -- "$2" felix-qualify ) </dev/null >/dev/null 2>&8 8>&- 9<&-
    rc=$?
    LC_ALL=C grep -qE \
      '^felix-qualify: ((line [0-9]+: )?[^:]+: command not found$|((line [0-9]+: )?(command substitution|eval|-c): )?(line [0-9]+: )?(syntax error near unexpected token|syntax error: unexpected end of file|unexpected EOF while looking for matching))' \
      <&9 8>&- 2>/dev/null
    said=$?
  } 8>|"$3" 9<"$3" 2>/dev/null
  [ "$said" = 1 ] || return 127
  return "$rc"
}

# The stderr file of the column about to run: its directory, the row's base,
# is a plain directory with the owner's bits back, and the file is new, plain
# and empty. Non-zero when it cannot be made so, which the caller reads as
# nothing run.
_felix_qualify_errfile() {   # path
  local d="${1%/*}"
  [ -d "$d" ] && [ ! -L "$d" ] || return 1
  chmod u+rwx "$d" 2>/dev/null
  rm -f "$1" 2>/dev/null
  [ ! -e "$1" ] && [ ! -L "$1" ] || return 1
  { : > "$1"; } 2>/dev/null
}

_felix_qualify_one() {   # root, command, mutation, [premise] -> pass | fail | unrunnable | inapplicable
  local root="$1" cmd="$2" mut="$3" premise="${4:-}" base scratch err got rc
  # A template under $TMPDIR: a bare mktemp on macOS ignores TMPDIR, and the
  # suite points TMPDIR at a fixture to count what is left there.
  local tmpd="${TMPDIR:-/tmp}"
  base="$(mktemp -d "${tmpd%/}/felix-qualify.XXXXXX" 2>/dev/null)" || { printf 'unrunnable'; return 0; }
  scratch="$base/w"; err="$base/err"
  # Which process owns the base, written before the traps and the add, so
  # every base that ever holds a tree names its owner first: no trap reaches
  # SIGKILL, and a later run's sweep (lib/qualify-sweep.sh) removes a base
  # only when the process it names is shown dead. A row that could not be
  # swept if it were killed is not started.
  if ! _felix_qualify_own "$base"; then
    printf 'felix: the row was not run, because the process that owns its scratch directory %s could not be recorded there\n' "$base" >&2
    chmod u+rwx "$base" 2>/dev/null
    _felix_qualify_unown "$base" ||
      printf 'felix: the scratch directory %s could not be deleted, and stays on disk\n' "$base" >&2
    printf 'unrunnable'; return 0
  fi
  # Before the add, so a row stopped while git checks the tree out goes too.
  # Every way out of this function lifts them, though it runs in a $(...).
  _felix_qualify_arm "$root" "$base"
  if ! git -C "$root" worktree add --detach -q "$scratch" HEAD 2>/dev/null; then
    _felix_qualify_unown "$base"; trap - INT TERM HUP; printf 'unrunnable'; return 0
  fi
  got=""
  if [ -n "$premise" ] && [ "$premise" != "-" ]; then
    _felix_qualify_sh "$scratch" "$premise" "$err"; rc=$?
    case "$rc" in
      0) : ;;
      1) got=inapplicable ;;
      *) got=unrunnable ;;
    esac
  fi
  # The mutation may legitimately fail (a control whose point is that the tree
  # already satisfies the obligation), so its status is not the verdict, save
  # the 126 or 127 that says it ran nothing.
  #
  # No column is given anything to read. The mutation and the command inherited
  # the pipe the rows arrived on, and a checker that read to the end of its
  # stdin took every row after its own with it: a met row and a held one ran
  # the met one alone, and the gate counted one control met of one. Nor may
  # a command that reads stdin wait on a terminal under felix gate.
  if [ -z "$got" ]; then
    _felix_qualify_sh "$scratch" "$mut" "$err"; rc=$?
    case "$rc" in 126|127) got=unrunnable ;; esac
  fi
  if [ -z "$got" ]; then
    _felix_qualify_sh "$scratch" "$cmd" "$err"; rc=$?
    case "$rc" in
      0)       got=pass ;;
      126|127) got=unrunnable ;;
      *)       got=fail ;;
    esac
  fi
  _felix_qualify_drop "$root" "$base"
  trap - INT TERM HUP
  printf '%s' "$got"
}
