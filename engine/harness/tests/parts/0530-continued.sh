printf '\nqualification: a row'"'"'s scratch tree never outlives the row\n'
# A row checks its control in a scratch worktree of the root's HEAD, made under
# a base directory of its own, and throws both away when it is done. Two things
# left them behind. A mutation that takes permission away inside its base,
# `chmod a-w d` over a file, left git unable to delete the file: the tree stayed
# on disk, and on some git versions in the root's worktree list as well. And
# nothing handled INT, TERM or HUP: a row signalled while a column ran died on
# the spot, its tree on disk and still registered in the root. Three such trees
# were found in the founder's own checkout. A row stopped by a signal, with its
# caller still running the rows, reached no verdict, so it reads unrunnable,
# never held and never met.
#
# A review then found what else a mutation can do to its own base. It can
# delete the tree's .git file, lock the worktree, delete the whole base, swap
# the tree for a symlink to another worktree, which git then removes in its
# place, uncommitted work and all, or hard-link files from outside into it,
# whose mode a careless chmod -R then changes outside. It can make the file a
# column's stderr goes to unwritable, which turned a checker that never ran
# into a fail, or a symlink to a file outside, which a later column then
# truncated, or whose contents faked a verdict. None of it may leave anything,
# change anything outside, or change a verdict. A felix: line on stderr speaks
# only of a tree or registration that is really left.
#
# Every path mktemp hands the runner is logged, by a function that wraps it in
# the shell that calls the runner. A leftover is any of those paths still there,
# or any worktree the root lists beside itself, live, prunable or locked; this
# root is the section's own and starts with none. A signalled run starts in a
# process group of its own, made by perl with INT, TERM and HUP back at their
# defaults: a background job starts with INT ignored, and a signal ignored at
# entry cannot be trapped. The held column marks itself running and waits on a
# release file made as soon as the signal has gone, with a bound of its own, so
# an unsignalled column runs on to its end and is never asserted cut short.
# Every wait has a deadline. Only processes of that group, walked down from the
# pid started here, are ever signalled. Whatever an old runner leaves behind,
# the section gives directories their permissions back (never a file, which may
# be a hard link to one outside), clears an immutable flag, removes it, and
# unlocks and prunes its own roots alone. Authored blind to the fix, from the
# contract in prose.
QTRS="$TMP/qual-tree-side"; QTRR="$TMP/qual-tree-repo"
# Every row run here has a TMPDIR of its own. A run now sweeps its TMPDIR
# for bases whose owner is dead, so in the machine's another session's run
# could remove a base this section left before the section looked at it.
QTRT="$TMP/qual-tree-tmp"
mkdir -p "$QTRS" "$QTRR" "$QTRT"
( _fx_cd "$QTRR" && git init -q -b main && printf 'clean\n' > base.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
QTRR="$(cd "$QTRR" && pwd -P)"
_qtr5() { printf '%s\t%s\t%s\t%s\t%s\n' "$@"; }
_qtr6() { printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$@"; }
_qtre() { if [ -e "$1" ]; then echo ran; else echo absent; fi; }
_qtrd() { mkdir -p "$QTRS/$1/proj"; printf '%s/proj/qualification.tsv' "$QTRS/$1"; }
_qtrmode() { ls -ld "$1" 2>/dev/null | cut -c1-10; }
# Whether mktemp handed the runner anything and which of those paths are still
# there; how many worktrees the root lists beside its own, and how many of those
# git calls prunable or locked; and how many lines of a stderr begin felix:.
_qtrpaths() {   # made-log
  local p left=""
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    if [ -e "$p" ] || [ -L "$p" ]; then left="$left $p"; fi
  done < "$1"
  printf '%s left:[%s]' "$([ -s "$1" ] && echo made || echo none-made)" "$left"
}
_qtrwt() {   # root
  git -C "$1" worktree list --porcelain 2>/dev/null \
    | awk '/^worktree / { w++ } /^prunable/ { p++ } /^locked/ { l++ } END { printf "wt:%d prunable:%d locked:%d", w - 1, p, l }'
}
_qtrleft() { printf '%s %s' "$(_qtrpaths "$1")" "$(_qtrwt "$2")"; }
_qtrfelix() { awk '/^felix:/ { n++ } END { print n + 0 }' "$1" 2>/dev/null; }
# What an old runner leaves: each directory given u+rwx, top down so a 000
# one opens before it is read, an immutable flag cleared where chflags exists,
# the path removed, and the root named, always one of this section's, unlocked
# and pruned. No file's mode is touched: it may be a hard link to one outside.
_qtrclean() {   # made-log, root
  local p
  while IFS= read -r p; do
    case "$p" in /?*) ;; *) continue ;; esac
    if [ -e "$p" ] || [ -L "$p" ]; then
      find "$p" -type d -exec chmod u+rwx {} \; 2>/dev/null
      if command -v chflags >/dev/null 2>&1; then chflags -R nouchg "$p" 2>/dev/null; fi
      rm -rf "$p" 2>/dev/null
    fi
  done < "$1"
  rm -f "$2"/.git/worktrees/*/locked 2>/dev/null
  _fx_git "$2" worktree prune >/dev/null 2>&1
}
# The runner as the CLI calls it, from inside the root under set -uo pipefail,
# with mktemp wrapped after the libraries are read.
_qtrrun() {   # proj, root, made-log, stderr file
  ( cd "$2" || exit 1; set -uo pipefail; _qtrlog="$3"; export TMPDIR="$QTRT"
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
    mktemp() { local p; p="$(command mktemp "$@")" || return
               printf '%s\n' "$p" >> "$_qtrlog"; printf '%s\n' "$p"; }
    felix_qualify_run "$1" "$2" ) 2>"$4"
}
# Run one table, then say what each row read, what was left once they had all
# returned, and how many felix: lines stderr carried, and clear away whatever
# was left.
_qtrcase() {   # tag, [root]
  local d="$QTRS/$1" root="${2:-$QTRR}" out
  : > "$d/made"
  out="$(_qtrrun "$d/proj" "$root" "$d/made" "$d/stderr")"
  _qtrres="$(printf '%s\n' "$out" | awk -F'\t' 'NF >= 5 { printf "%s %s; ", $4, $5 }')$(_qtrleft "$d/made" "$root") said:$(_qtrfelix "$d/stderr")"
  _qtrclean "$d/made" "$root"
}
_qtrok="made left:[] wt:0 prunable:0 locked:0"
_qtrquiet="$_qtrok said:0"
# Every spelling of the scratch path of a row whose mutation wrote its pwd to
# DIR/pwd and DIR/pwdp: as the column saw it, as mktemp spelt the base, and as
# the filesystem resolves that base. And whether any line of a stderr that
# begins felix: names one of them.
_qtrnames() {   # dir
  { cat "$1/pwd" "$1/pwdp" 2>/dev/null
    while IFS= read -r _qtrp; do
      [ -n "$_qtrp" ] || continue
      printf '%s/w\n' "$_qtrp"
      printf '%s/%s/w\n' "$(cd "$(dirname "$_qtrp")" 2>/dev/null && pwd -P)" "$(basename "$_qtrp")"
    done < "$1/made"
  } > "$1/names"
}
_qtrsaid() {   # stderr file, names file -> named | unnamed
  local l n
  while IFS= read -r l; do
    case "$l" in felix:*) ;; *) continue ;; esac
    while IFS= read -r n; do
      [ -n "$n" ] || continue
      case "$l" in *"$n"*) echo named; return 0 ;; esac
    done < "$2"
  done < "$1"
  echo unnamed
}

# C5, unchanged: a row that runs to its end leaves nothing, whatever it reads,
# and so does one whose worktree could not be added. C13: neither says felix:.
{ _qtr5 plainmet   '! test -f bad.txt' violation fail 'printf FORBIDDEN > bad.txt'
  _qtr5 plainpass  'test -f base.txt' restoration pass true
  _qtr5 plainheld  'test -f base.txt' violation fail true
  _qtr6 plaininapp 'test -f base.txt' violation fail true 'exit 1'
  _qtr6 plainunrun 'test -f base.txt' violation fail true 'exit 2'
} > "$(_qtrd plain)"
_qtrcase plain
is  "a run whose rows read fail and met, pass and met, pass and held, inapplicable, and unrunnable leaves no path mktemp handed the runner and no worktree registered in the root, live, prunable or locked, and its stderr carries no felix: line" \
    "$_qtrres" "fail met; pass met; pass held; - inapplicable; unrunnable unrunnable; $_qtrquiet"
QTRU="$TMP/qual-tree-unborn"; mkdir -p "$QTRU"; ( _fx_cd "$QTRU" && git init -q -b main ) >/dev/null 2>&1
QTRU="$(cd "$QTRU" && pwd -P)"
_qtr5 unborn 'test -f base.txt' restoration pass true > "$(_qtrd unborn)"
_qtrcase unborn "$QTRU"
is  "a row whose worktree add fails, in a repository with no commit yet, reads unrunnable and leaves no path mktemp handed it and no worktree registered, and its stderr carries no felix: line" \
    "$_qtrres" "unrunnable unrunnable; $_qtrquiet"

# C1: a permission taken away anywhere inside the row's base. Each shape runs
# as a pass control whose checker passes and a fail control whose checker
# fails; neither checker reads anything the permission guards.
{ _qtr5 unwpass 'test -f base.txt' restoration pass 'mkdir -p d && printf x > d/f && chmod a-w d'
  _qtr5 unwfail '! test -f bad.txt' violation fail 'printf FORBIDDEN > bad.txt && mkdir -p d && printf x > d/f && chmod a-w d'
} > "$(_qtrd unwritable)"
_qtrcase unwritable
is  "a mutation that makes a directory in its scratch tree unwritable, with a file inside, leaves no scratch tree, base directory or worktree registration, live, prunable or locked, once its rows return, its pass and fail controls still read pass and met, fail and met, and stderr carries no felix: line" \
    "$_qtrres" "pass met; fail met; $_qtrquiet"
{ _qtr5 nopermpass 'test -f base.txt' restoration pass 'mkdir -p d/e/f && printf x > d/e/f/g && chmod 000 d'
  _qtr5 nopermfail '! test -f bad.txt' violation fail 'printf FORBIDDEN > bad.txt && mkdir -p d/e/f && printf x > d/e/f/g && chmod 000 d'
} > "$(_qtrd noperm)"
_qtrcase noperm
is  "a mutation that takes every permission from a directory with a file two levels down inside it leaves no scratch tree, base directory or worktree registration, its pass and fail controls still read pass and met, fail and met, and stderr carries no felix: line" \
    "$_qtrres" "pass met; fail met; $_qtrquiet"
{ _qtr5 rootropass 'test -f base.txt' restoration pass 'chmod a-w .'
  _qtr5 rootrofail '! test -f bad.txt' violation fail 'printf FORBIDDEN > bad.txt && chmod a-w .'
} > "$(_qtrd rootro)"
_qtrcase rootro
is  "a mutation that makes its scratch tree's own root unwritable leaves no scratch tree, base directory or worktree registration, its pass and fail controls still read pass and met, fail and met, and stderr carries no felix: line" \
    "$_qtrres" "pass met; fail met; $_qtrquiet"
{ _qtr5 basero-pass 'test -f base.txt' restoration pass 'chmod a-w ..'
  _qtr5 basero-fail '! test -f bad.txt' violation fail 'printf FORBIDDEN > bad.txt && chmod a-w ..'
} > "$(_qtrd basero)"
_qtrcase basero
is  "a mutation that makes its row's base directory unwritable leaves no scratch tree, base directory or worktree registration, its pass and fail controls still read pass and met, fail and met, and stderr carries no felix: line" \
    "$_qtrres" "pass met; fail met; $_qtrquiet"
{ _qtr6 prembase  'test -f base.txt' restoration pass true 'chmod a-w ..'
  _qtr5 cmdnoperm 'mkdir -p d/e/f && printf x > d/e/f/g && chmod 000 d && ! test -f bad.txt' violation fail 'printf FORBIDDEN > bad.txt'
} > "$(_qtrd columns)"
_qtrcase columns
is  "a premise that makes its row's base directory unwritable, and a checker that takes every permission from a nested directory before it decides, leave no scratch tree, base directory or worktree registration, their controls still read pass and met, fail and met, and stderr carries no felix: line" \
    "$_qtrres" "pass met; fail met; $_qtrquiet"

# C2: giving permissions back never reaches outside the base. The mutation
# plants symlinks to a file and a directory outside the tree, at its root and
# inside a directory, then makes both unwritable.
QTRO="$QTRS/outside"; mkdir -p "$QTRO/dir"
printf 'kept\n' > "$QTRO/file"; printf 'kept\n' > "$QTRO/dir/inner"
chmod 0444 "$QTRO/file" "$QTRO/dir/inner"; chmod 0555 "$QTRO/dir"
_qtr5 links 'test -f base.txt' restoration pass \
      "mkdir -p d && ln -s '$QTRO/file' lf && ln -s '$QTRO/dir' ld && ln -s '$QTRO/file' d/lf && ln -s '$QTRO/dir' d/ld && chmod a-w d ." \
      > "$(_qtrd links)"
_qtrcase links
is  "a mutation that plants symlinks to a 0444 file and a 0555 directory outside its tree, beside and inside a directory it makes unwritable, still has its scratch tree, base directory and registration removed, and stderr carries no felix: line" \
    "$_qtrres" "pass met; $_qtrquiet"
is  "and the file and the directory those symlinks point at keep their modes, 0444 and 0555, and still exist with the file inside the directory: giving permissions back never reaches outside the row's base directory" \
    "$(_qtrmode "$QTRO/file") $(_qtrmode "$QTRO/dir") $(_qtrmode "$QTRO/dir/inner") $(cat "$QTRO/file" "$QTRO/dir/inner" 2>/dev/null | tr '\n' ' ')" \
    "-r--r--r-- dr-xr-xr-x -r--r--r-- kept kept "
chmod -R u+rwX "$QTRO" 2>/dev/null

# C6, revised: a tree git no longer knows as a worktree, its .git file gone,
# is removed all the same, and with nothing left there is nothing to say.
_qtr5 gitgone 'test -f base.txt' restoration pass 'rm -f .git' > "$(_qtrd gitgone)"
_qtrcase gitgone
is  "a mutation that deletes its scratch tree's .git file leaves no scratch tree, base directory or registration, live, prunable or locked, its verdict still pass and met, and stderr carries no felix: line" \
    "$_qtrres" "pass met; $_qtrquiet"

# C8: hard links. A file outside, 0444, hard-linked into the tree, and a local
# clone of the tree, whose objects are hard links to the root's own. Each
# mutation also makes a directory unwritable, so whatever gives permissions
# back has work to do. The objects' modes are read before the run and after.
QTRH="$QTRS/hard-out"; printf 'kept\n' > "$QTRH"; chmod 0444 "$QTRH"
_qtrobj() {   # root -> how many object files, and each one's mode and path
  find "$1/.git/objects" -type f 2>/dev/null | LC_ALL=C sort | while IFS= read -r _qtrf; do
    printf '%s %s\n' "$(_qtrmode "$_qtrf")" "${_qtrf#"$1"/}"; done
}
_qtrobjwas="$(_qtrobj "$QTRR")"
{ _qtr5 hardlink 'test -f base.txt' restoration pass "ln '$QTRH' h && chmod a-w ."
  _qtr5 hardclone 'test -f base.txt' restoration pass 'git clone -q . sub && chmod a-w sub'
} > "$(_qtrd hard)"
_qtrcase hard
is  "a mutation that hard-links a 0444 file from outside into its tree, and one that clones the tree with git, each then making a directory unwritable, leave no scratch tree, base directory or registration, read pass and met, and say no felix: line" \
    "$_qtrres" "pass met; pass met; $_qtrquiet"
_qtrobjnow="$(_qtrobj "$QTRR")"
is  "and the outside file keeps mode 0444 and its content, and every file under the root's .git/objects, of which there are some, keeps the mode it had before the run: giving permissions back never reaches a file through a hard link" \
    "$(_qtrmode "$QTRH") $(cat "$QTRH" 2>/dev/null) objects:$(printf '%s' "$_qtrobjwas" | awk 'NF { n++ } END { print (n > 0 ? "some" : "none") }') $([ "$_qtrobjnow" = "$_qtrobjwas" ] && echo same || echo changed)" \
    "-r--r--r-- kept objects:some same"
chmod u+w "$QTRH" 2>/dev/null

# C9: a mutation that swaps its tree for a symlink to another worktree of the
# same root, one holding uncommitted work. That worktree must come through
# untouched and still registered, and the row's own tree and registration go.
# The root is one of its own, so its other worktree counts against no other
# case.
QTR9="$TMP/qual-tree-repo9"; mkdir -p "$QTR9"
( _fx_cd "$QTR9" && git init -q -b main && printf 'clean\n' > base.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
QTR9="$(cd "$QTR9" && pwd -P)"
QTR9O="$TMP/qual-tree-other"
_fx_git "$QTR9" worktree add --detach -q "$QTR9O" HEAD >/dev/null 2>&1
QTR9O="$(cd "$QTR9O" 2>/dev/null && pwd -P)"
printf 'mine\n' > "$QTR9O/uncommitted.txt"
_qtr5 swap 'test -f base.txt' restoration pass "w=\"\$PWD\"; cd .. && mv \"\$w\" w.orig && ln -s '$QTR9O' w" > "$(_qtrd swap)"
: > "$QTRS/swap/made"
_qtrrun "$QTRS/swap/proj" "$QTR9" "$QTRS/swap/made" "$QTRS/swap/stderr" >/dev/null
is  "a mutation that swaps its scratch tree for a symlink to another worktree of the root leaves that worktree there, its uncommitted file intact and still registered, while the row's own tree, base and registration are gone and stderr carries no felix: line" \
    "other:$(cat "$QTR9O/uncommitted.txt" 2>/dev/null || echo gone) $(git -C "$QTR9" worktree list --porcelain 2>/dev/null | awk -v r="$QTR9" -v o="$QTR9O" '
       /^worktree / { p = substr($0, 10); if (p == o) reg = "yes"; else if (p != r) own++ }
       /^prunable/ { pr++ } /^locked/ { lk++ }
       END { printf "registered:%s own:%d prunable:%d locked:%d", (reg == "" ? "no" : reg), own, pr, lk }') $(_qtrpaths "$QTRS/swap/made") said:$(_qtrfelix "$QTRS/swap/stderr")" \
    "other:mine registered:yes own:0 prunable:0 locked:0 made left:[] said:0"
_qtrclean "$QTRS/swap/made" "$QTR9"

# C10: the row's own working files outside its tree. The base and everything
# in it made unwritable, which once kept a column's stderr from opening and
# read the checker that never ran as fail; and the file beside the tree that
# a column's stderr went to, replaced by a symlink to a file outside, which a
# later column truncated, or whose words faked a verdict.
QTRX="$QTRS/err-out"; printf 'kept\n' > "$QTRX"; chmod 0644 "$QTRX"
QTRXF="$QTRS/err-fake"; printf 'felix-qualify: line 1: qtr_fake_tool: command not found\n' > "$QTRXF"; chmod 0644 "$QTRXF"
{ _qtr5 errro   "printf x > '$QTRS/errfile/checked'; test -f base.txt" violation fail 'chmod -R a-w ..'
  _qtr5 errlink 'test -f base.txt' restoration pass "ln -sf '$QTRX' ../err && chmod a-w .."
  _qtr5 errfake 'test -f base.txt' restoration pass "ln -sf '$QTRXF' ../err && chmod a-w .."
} > "$(_qtrd errfile)"
_qtrcase errfile
_qtrxv="$(printf '%s' "$_qtrres" | awk -F'; ' '{ print $1 " " $2 " " $3 }')"
is  "a fail control whose mutation makes its base and everything in it unwritable still runs its checker, which passes, so it reads pass and held, never fail and met" \
    "$(printf '%s' "$_qtrxv" | awk '{ print $1 " " $2 }') $(_qtre "$QTRS/errfile/checked")" "pass held ran"
is  "a mutation that makes the file beside its tree a symlink to a file outside, and its base unwritable, leaves its verdict pass and met, even when that file reads like a name not found" \
    "$(printf '%s' "$_qtrxv" | awk '{ print $3 " " $4 "; " $5 " " $6 }')" "pass met; pass met"
is  "and both files outside keep their modes and every byte they held" \
    "$(_qtrmode "$QTRX") $(_qtrmode "$QTRXF") $(cat "$QTRX" "$QTRXF" 2>/dev/null | tr '\n' '|')" \
    "-rw-r--r-- -rw-r--r-- kept|felix-qualify: line 1: qtr_fake_tool: command not found|"
is  "and none of the three leaves a scratch tree, base directory or registration, or says a felix: line" \
    "${_qtrres#*; *; *; }" "$_qtrquiet"

# C11: a mutation that locks its own worktree.
_qtr5 lockself 'test -f base.txt' restoration pass 'git worktree lock --reason x "$PWD"' > "$(_qtrd lockself)"
_qtrcase lockself
is  "a mutation that locks its own worktree still leaves no scratch tree, base directory or registration, live, prunable or locked, reads pass and met, and says no felix: line" \
    "$_qtrres" "pass met; $_qtrquiet"

# C12: a mutation that deletes its row's whole base. It works out the base as
# the parent of where it runs, and acts only in a linked worktree named w that
# is not the root, inside a base of a few entries.
_qtr5 basegone '! test -f bad.txt' violation fail \
      "d=\$(pwd -P) && [ \"\$d\" != '$QTRR' ] && [ \"\${d##*/}\" = w ] && test -f .git && test -f base.txt && b=\$(dirname \"\$d\") && [ \"\$(ls -A \"\$b\" | wc -l | tr -d ' ')\" -le 4 ] && cd / && rm -rf \"\$b\"" \
      > "$(_qtrd basegone)"
_qtrcase basegone
is  "a mutation that deletes its row's whole base directory reads unrunnable, leaves no registration, prunable included, and says no felix: line" \
    "$_qtrres" "unrunnable unrunnable; $_qtrquiet"

# C13: a tree that really cannot be removed, a file in it made immutable, is
# named on stderr in a line beginning felix:. If a runner does remove it after
# all, nothing is left and nothing need be said; what may not happen is a
# tree left in silence, or a line about a tree that is gone.
if command -v chflags >/dev/null 2>&1; then
  _qtr5 pinned 'test -f base.txt' restoration pass \
        "pwd > '$QTRS/pinned/pwd'; pwd -P > '$QTRS/pinned/pwdp'; printf x > pinned && chflags uchg pinned" > "$(_qtrd pinned)"
  : > "$QTRS/pinned/made"
  _qtrrun "$QTRS/pinned/proj" "$QTRR" "$QTRS/pinned/made" "$QTRS/pinned/stderr" >/dev/null
  _qtrnames "$QTRS/pinned"
  case "$(_qtrleft "$QTRS/pinned/made" "$QTRR")" in
    "$_qtrok") _qtrpin=clean ;;
    *)         _qtrpin=left ;;
  esac
  _qtrpin="$_qtrpin $(_qtrsaid "$QTRS/pinned/stderr" "$QTRS/pinned/names") $(_qtrfelix "$QTRS/pinned/stderr")"
  case "$_qtrpin" in
    "left named "[1-9]*|"clean unnamed 0") ok "a scratch tree holding a file made immutable with chflags uchg is either removed with nothing said, or, when any of it is left, named on stderr in a line beginning felix:" ;;
    *) bad "a scratch tree holding a file made immutable with chflags uchg is either removed with nothing said, or, when any of it is left, named on stderr in a line beginning felix:" \
           "what was left, whether a felix: line named it, how many felix: lines: [$_qtrpin] $(_qtrleft "$QTRS/pinned/made" "$QTRR")" ;;
  esac
  _qtrclean "$QTRS/pinned/made" "$QTRR"
else
  skip "a scratch tree holding a file made immutable with chflags uchg is either removed with nothing said, or, when any of it is left, named on stderr in a line beginning felix:" "no chflags here"
fi

# C3: a row signalled while a column runs. The launcher traps the three
# signals, so it outlives every run and is never reaped as a job a signal
# killed. Below it the caller either runs the rows as the CLI does, in a
# subshell at the signals' defaults that dies at once of TERM or HUP (run), or
# is the launcher itself, calling the row runner as the rows are called, with
# got="$(...)", and living to write the row's status and what it printed
# (one). The git shim holds a git call made after the arm file exists until
# release2, so a second INT can land while the row is removing its tree; a
# shim that inherits INT at its default dies of it, as git itself would.
QTRL="$QTRS/launch"
cat > "$QTRL" <<'EOF'
set -uo pipefail
qtr_mode="$1"; qtr_froot="$2"; qtr_root="$3"; qtr_made="$4"; qtr_st="$5"; shift 5
cd "$qtr_root" || exit 1
. "$qtr_froot/harness/lib/resolve.sh"; . "$qtr_froot/harness/lib/qualify.sh"
mktemp() { local p; p="$(command mktemp "$@")" || return
           printf '%s\n' "$p" >> "$qtr_made"; printf '%s\n' "$p"; }
trap 'qtr_sig=1' INT TERM HUP
if [ "$qtr_mode" = run ]; then
  ( felix_qualify_run "$1" "$qtr_root" > "$qtr_st" )
else
  qtr_got="$(_felix_qualify_one "$qtr_root" "$@")"; qtr_rc=$?
  printf '%s %s\n' "$qtr_rc" "$qtr_got" > "$qtr_st"
fi
exit 0
EOF
QTRSHIM="$QTRS/shim"; mkdir -p "$QTRSHIM"
QTRGIT="$(command -v git)"
cat > "$QTRSHIM/git" <<EOF
#!$BASH
if [ -n "\${QTR_GITHOLD:-}" ] && [ -e "\$QTR_GITHOLD/arm" ]; then
  printf '%s\n' "\$*" >> "\$QTR_GITHOLD/in-git"
  i=0; while [ ! -e "\$QTR_GITHOLD/release2" ] && [ \$i -lt 60 ]; do sleep 1; i=\$((i + 1)); done
fi
exec '$QTRGIT' "\$@"
EOF
chmod +x "$QTRSHIM/git"
# The columns of a signalled row. The held one becomes a process that marks
# itself running, waits for the release file, never more than 60 seconds, and
# exits 0 when base.txt is there, as a checker would. It dies of a signal that
# reaches it, as a checker does: a bash loop ends on INT with a plain exit
# 130, and a shell above it then carries on as if nothing had happened. The
# mark comes from that process itself, so a signal sent once it is there
# always finds the checker running. Each other column marks that it started.
_qtrcols() {   # dir, column held: prem | mut | cmd
  local hold="exec perl -e 'open(my \$f, q(>), \$ARGV[1]) or exit 3; print \$f q(held); close \$f; for (1 .. 60) { last if -e \$ARGV[0]; sleep 1 } exit((-e q(base.txt)) ? 0 : 1)' '$1/release' '$1/at-$2'"
  _qtrprem=""; _qtrmut="printf x > '$1/ran-mut'"; _qtrcmd="printf x > '$1/ran-cmd'; test -f base.txt"
  case "$2" in
    prem) _qtrprem="$hold" ;;
    mut)  _qtrmut="printf x > '$1/ran-mut'; $hold" ;;
    cmd)  _qtrcmd="printf x > '$1/ran-cmd'; $hold" ;;
  esac
}
# The processes of group $1 that have not exited; the direct children of $1;
# and every process below $1, walked down by parent pid. The last two keep to
# group $2, the run's, so nothing outside the run started here is ever named.
_qtrgroup() { ps -A -o pid=,pgid=,stat= 2>/dev/null | awk -v g="$1" '$2 == g && $3 !~ /^Z/ { print $1 }'; }
_qtrkids()  { ps -A -o pid=,ppid=,pgid= 2>/dev/null | awk -v r="$1" -v g="$2" '$2 == r && $3 == g { print $1 }'; }
_qtrbelow() { ps -A -o pid=,ppid=,pgid= 2>/dev/null | awk -v r="$1" -v g="$2" '
  { par[$1] = $2; grp[$1] = $3; ids[++n] = $1 }
  END { want[r] = 1; more = 1
        while (more) { more = 0
          for (i = 1; i <= n; i++) if (!(ids[i] in want) && (par[ids[i]] in want)) { want[ids[i]] = 1; more = 1 } }
        for (i = 1; i <= n; i++) if (ids[i] != r && (ids[i] in want) && grp[ids[i]] == g) print ids[i] }'; }
_qtrlive()  { case "$(ps -o stat= -p "$1" 2>/dev/null | tr -d ' ')" in ''|Z*) return 1 ;; esac; return 0; }
_qtrheld()  { [ -s "$1" ] || ! _qtrlive "$2"; }
_qtringit() { [ -s "$1" ] || [ -z "$(_qtrgroup "$2")" ]; }
_qtrempty() { [ -z "$(_qtrgroup "$1")" ]; }
_qtrtill() {   # seconds, test...: poll once a second until it holds; 1 at the deadline
  local t0=$SECONDS lim="$1"; shift
  while ! "$@"; do [ $((SECONDS - t0)) -lt "$lim" ] || return 1; sleep 1; done
}
# KILL whatever of the run is left, in its group or below it, then reap it.
_qtrstop() {
  local k
  [ -n "$(_qtrgroup "$1")" ] && kill -s KILL -- "-$1" 2>/dev/null
  for k in $(_qtrbelow "$1" "$1"); do kill -s KILL "$k" 2>/dev/null; done
  kill -s KILL "$1" 2>/dev/null
  wait "$1" 2>/dev/null
}
# One signalled run. Says, in _qtrres: a second INT's fate when asked for one;
# the row's status and what it printed (one), or its verdict line when the
# caller was left alive (run, row or below); whether the mutation and the
# checker started; whether every process of the run exited by the deadline;
# and what was left. The row is a pass control whose checker passes, or with
# fail a fail control whose mutation takes base.txt away, so its checker fails.
_qtrsig() {   # tag, run | one, INT | TERM | HUP, group | row | below, prem | cmd | mut, [twice | fail]
  local d="$QTRS/$1" mode="$2" sig="$3" to="$4" hold="$5" twice="${6:-}"
  local pid caller k path="$PATH" exited=exited second="" control=restoration expect=pass
  mkdir -p "$d/proj"; : > "$d/made"
  _qtrcols "$d" "$hold"
  [ "$twice" = fail ] && { control=violation; expect=fail; _qtrmut="$_qtrmut; rm -f base.txt"; }
  if [ -n "$_qtrprem" ]; then _qtr6 sig "$_qtrcmd" "$control" "$expect" "$_qtrmut" "$_qtrprem"
  else _qtr5 sig "$_qtrcmd" "$control" "$expect" "$_qtrmut"; fi > "$d/proj/qualification.tsv"
  if [ "$mode" = run ]; then set -- "$d/proj"
  elif [ -n "$_qtrprem" ]; then set -- "$_qtrcmd" "$_qtrmut" "$_qtrprem"
  else set -- "$_qtrcmd" "$_qtrmut"; fi
  [ "$twice" = twice ] && path="$QTRSHIM:$PATH"
  PATH="$path" QTR_GITHOLD="$d" TMPDIR="$QTRT" perl -e '$SIG{INT} = $SIG{TERM} = $SIG{HUP} = "DEFAULT"; setpgrp(0, 0) or exit 97; exec @ARGV or exit 98' \
    "$BASH" "$QTRL" "$mode" "$FROOT" "$QTRR" "$d/made" "$d/status" "$@" </dev/null >/dev/null 2>"$d/stderr" &
  pid=$!
  _qtrtill 60 _qtrheld "$d/at-$hold" "$pid"
  if [ ! -s "$d/at-$hold" ] || [ "$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d ' ')" != "$pid" ]; then
    _qtrres="the $hold column was never reached in a group of its own"
    : > "$d/release"; _qtrstop "$pid"; _qtrclean "$d/made" "$QTRR"; return 0
  fi
  [ "$twice" = twice ] && : > "$d/arm"
  # The caller that runs the rows: the launcher (one), or its subshell (run).
  caller="$pid"; [ "$mode" = run ] && caller="$(_qtrkids "$pid" "$pid")"
  case "$to" in
    group) kill -s "$sig" -- "-$pid" 2>/dev/null ;;
    row)   for k in $(_qtrkids "$caller" "$pid"); do kill -s "$sig" "$k" 2>/dev/null; done ;;
    below) for k in $(_qtrbelow "$caller" "$pid"); do kill -s "$sig" "$k" 2>/dev/null; done ;;
  esac
  : > "$d/release"
  if [ "$twice" = twice ]; then
    if _qtrtill 60 _qtringit "$d/in-git" "$pid" && [ -s "$d/in-git" ]; then
      kill -s INT -- "-$pid" 2>/dev/null; second="second:sent "
    else second="second:never "; fi
    : > "$d/release2"
  fi
  _qtrtill 60 _qtrempty "$pid" || exited=stuck
  _qtrstop "$pid"
  case "$mode:$to" in
    one:*)   _qtrres="rc:$(awk 'NR == 1 { print $1 }' "$d/status" 2>/dev/null) got:$(awk 'NR == 1 { print $2 }' "$d/status" 2>/dev/null) " ;;
    run:group) _qtrres="" ;;
    *)       _qtrres="line:$(awk -F'\t' '$1 == "sig" { print $4 " " $5 }' "$d/status" 2>/dev/null) " ;;
  esac
  _qtrres="$second${_qtrres}mut:$(_qtre "$d/ran-mut") cmd:$(_qtre "$d/ran-cmd") $exited $(_qtrleft "$d/made" "$QTRR")"
  _qtrclean "$d/made" "$QTRR"
}

# The whole process group, as a terminal's Ctrl-C, timeout or a tool's kill
# sends it, while the checker runs. Under TERM and HUP the caller's own shell
# dies at once, and the row cleans up with no one left reading it.
_qtrsig gint run INT group cmd
is  "a row whose checker is running when INT reaches its run's whole process group removes its scratch tree: once every process of the run has exited, no path mktemp handed the runner is left and the root lists no worktree for it, live or prunable" \
    "$_qtrres" "mut:ran cmd:ran exited $_qtrok"
_qtrsig gterm run TERM group cmd
is  "a row whose checker is running when TERM reaches its run's whole process group removes its scratch tree though the caller's shell dies at once: once every process of the run has exited, nothing mktemp handed the runner is left and the root lists no worktree for it" \
    "$_qtrres" "mut:ran cmd:ran exited $_qtrok"
_qtrsig ghup run HUP group cmd
is  "a row whose checker is running when HUP reaches its run's whole process group removes its scratch tree just the same, with nothing mktemp handed the runner left and no worktree listed in the root, live or prunable" \
    "$_qtrres" "mut:ran cmd:ran exited $_qtrok"
_qtrsig oint one INT group cmd
is  "a row whose process gets INT from its run's process group while its checker runs exits 130 with unrunnable as its verdict, after removing its scratch tree" \
    "$_qtrres" "rc:130 got:unrunnable mut:ran cmd:ran exited $_qtrok"
_qtrsig oterm one TERM group cmd
is  "a row whose process gets TERM from its run's process group while its checker runs exits 143 with unrunnable as its verdict, after removing its scratch tree" \
    "$_qtrres" "rc:143 got:unrunnable mut:ran cmd:ran exited $_qtrok"
_qtrsig ohup one HUP group cmd
is  "a row whose process gets HUP from its run's process group while its checker runs exits 129 with unrunnable as its verdict, after removing its scratch tree" \
    "$_qtrres" "rc:129 got:unrunnable mut:ran cmd:ran exited $_qtrok"
# The premise is where a group INT lands, so neither later column may start.
_qtrsig pint run INT group prem
is  "a row whose premise is running when INT reaches its run's whole process group removes its scratch tree, and neither its mutation nor its checker starts afterwards" \
    "$_qtrres" "mut:absent cmd:absent exited $_qtrok"
# The row's own process alone, its caller left running the rows. The column
# the signal did not reach runs on until it is released; the row then removes
# its tree, starts no later column, and reads unrunnable.
_qtrsig rterm run TERM row mut
is  "a row whose own process alone gets TERM while its mutation runs, its caller still running the rows, reads unrunnable in both the got and verdict columns, never held, removes its scratch tree once that mutation returns, and never starts its checker" \
    "$_qtrres" "line:unrunnable unrunnable mut:ran cmd:absent exited $_qtrok"
_qtrsig rhup run HUP row cmd
is  "a row whose own process alone gets HUP while its checker runs reads unrunnable in both columns once that checker has ended, never pass and met, and removes its scratch tree" \
    "$_qtrres" "line:unrunnable unrunnable mut:ran cmd:ran exited $_qtrok"
# INT is the one a shell lets a waiting child answer for it: a row whose column
# was told and exited plainly runs on. A fail control's checker that fails once
# it is let go must not then be counted as a checker that caught its mutation.
_qtrsig rint run INT row cmd fail
is  "a fail control whose own process alone gets INT while its checker runs reads unrunnable in both columns once that checker has failed, never fail and met, and removes its scratch tree" \
    "$_qtrres" "line:unrunnable unrunnable mut:ran cmd:ran exited $_qtrok"
_qtrsig oterm1 one TERM row mut
is  "a row whose own process alone gets TERM while its mutation runs exits 143 with unrunnable as its verdict, after removing its scratch tree, and never starts its checker" \
    "$_qtrres" "rc:143 got:unrunnable mut:ran cmd:absent exited $_qtrok"
_qtrsig belowterm one TERM below prem
is  "a row whose processes below its caller all get TERM while its premise runs exits 143 with unrunnable as its verdict, removes its scratch tree, and starts neither its mutation nor its checker" \
    "$_qtrres" "rc:143 got:unrunnable mut:absent cmd:absent exited $_qtrok"
# A second INT while the row removes its tree: the first git call the row
# makes after the first INT is held, the group gets INT again, then the call
# is let go.
_qtrsig twice one INT group cmd twice
is  "a second INT to the run's process group while the row is removing its scratch tree, with git at work on it, does not cut the removal short: the row exits 130, unrunnable, and nothing of the tree is left" \
    "$_qtrres" "second:sent rc:130 got:unrunnable mut:ran cmd:ran exited $_qtrok"

# Nothing the section made keeps a permission it took away, and its roots
# list no worktree a run left behind.
for _qtrp in "$QTRS"/*/made; do [ -f "$_qtrp" ] && _qtrclean "$_qtrp" "$QTRR"; done
_fx_git "$QTRU" worktree prune >/dev/null 2>&1
_fx_git "$QTR9" worktree prune >/dev/null 2>&1
chmod -R u+rwX "$QTRS" "$QTRT" 2>/dev/null
