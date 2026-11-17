printf '\nthe EXIT trap removes the temporary directory and reports only in the shell that set it\n'
# 2026-10-17, slot 3f, blind and red-first: written from the slot's contract
# alone, with no fix read or written. The EXIT trap part 0001 sets and part
# 0003 replaces removes $TMP and, through _fx_exit, prints the end-of-run
# report. 0003 says EXIT traps are not inherited by subshells, so it runs in
# the suite's own shell and nowhere else. That is not so. For `( ... ) &`
# bash forks a child that holds the parent's traps until execute_in_subshell
# resets them, and with an EXIT trap set a non-interactive bash takes an
# untrapped INT or TERM in termsig_sighandler; the child acts on one
# (CHECK_TERMSIG) before reset_signal_handlers (bash 5.2's source). A child
# sent INT or TERM in that window runs the suite's trap itself: it prints the
# report and removes $TMP, and the suite runs on without it. Part 0573's
# _lwsweep sends INT to a just-forked run's process group at delay 0, and on
# the Linux runner (run 38957354055, attempt 1) that took $TMP away inside
# the part: every assertion from L12 on failed, with "no FIFO" and "No such
# file or directory" under $FROOT.
#
# No timing from here can aim at that window, so this builds the state the
# child is in when the signal lands: a subshell of this suite, with its
# variables and functions, carrying the trap this shell has now, read back
# from `trap -p EXIT` rather than written out here, and exiting through it.
# Its $$ and $PPID are the suite's, as they are in the real child. One child
# also reads BASH_SUBSHELL 0, as a child bash has not yet counted reads it, so
# a trap that tells its own shell by subshell depth reads as wrong too. Each
# child is handed a refusal record holding a line, so the report has
# something to print if it runs, and one exits 7, so a trap that quiets a
# child by exiting 0 reads as wrong as well.
#
# The trap removes "$TMP". In each child TMP names a scratch directory under
# the real one, set before the trap is, so a trap that runs there removes the
# scratch directory and nothing else; _fx_exit, which it calls, only reads.
# The trap's text may change, so before any child runs, every variable that
# text names besides TMP is checked: one whose value is the suite's temporary
# directory, or a path inside it, stops the children before they start.
#
# That the trap still removes $TMP and reports in the shell that set it is
# pinned in parts 0200 and 0201, by section runners whose own shell runs it:
# "a section runner whose remotes did not move exits 0, its trap silent, its
# temporary directory removed", "a red section runner's trap still removes its
# temporary directory", and "a section runner with a refusal exits 1, its trap
# listing the recorded line ...". It is not repeated here.
_xt="$TMP/exit-trap"; mkdir -p "$_xt"; _xtnl=$'\n'
trap -p EXIT > "$_xt/suite.trap"
_xttext=""; IFS= read -r -d '' _xttext < "$_xt/suite.trap"
# The variables the trap's text names, TMP aside, whose value is the suite's
# temporary directory or a path inside it, physically or as mktemp named it.
_xtreach=""; _xtrest="$_xttext"; _xtphys="${_fx_tmp:-$TMP}"
while :; do
  case "$_xtrest" in *'$'*) _xtrest="${_xtrest#*\$}" ;; *) break ;; esac
  _xtrest="${_xtrest#\{}"; _xtname="${_xtrest%%[!A-Za-z0-9_]*}"
  case "$_xtname" in ""|TMP|[!A-Za-z_]*) continue ;; esac
  _xtval="${!_xtname-}"
  case "$_xtval" in "$TMP"|"$TMP"/*|"$_xtphys"|"$_xtphys"/*) _xtreach="$_xtreach $_xtname" ;; esac
done
is "fixture control: this shell has an EXIT trap, and no variable its text names besides TMP points into the suite's temporary directory, so a child can run it with TMP moved" \
   "$([ -s "$_xt/suite.trap" ] && printf set || printf none):[${_xtreach# }]" "set:[]"

# NAME STATUS [uncounted]: a subshell of this suite, with TMP a scratch
# directory under $_xt/NAME and a refusal record holding a line, takes on the
# trap read above and exits STATUS through it; with uncounted it first reads
# BASH_SUBSHELL 0. Its stdout and stderr go to NAME/out, the trap it carried
# to NAME/carried. Sets _xtrc to its status, or "not run".
_xtkid() {
  local d="$_xt/$1"
  _xtrc="not run"
  [ -z "$_xtreach" ] && [ -s "$_xt/suite.trap" ] || return 0
  mkdir -p "$d/tmp" && printf 'stand-in\n' > "$d/tmp/kept" \
    && printf 'xt-seeded-refusal\t%s\tseeded by part 0575\n' "$d" > "$d/refused" || return 0
  (
    TMP="$d/tmp"; FELIX_TEST_FXREFUSED="$d/refused"; unset _fx_final
    [ "${3:-}" != uncounted ] || BASH_SUBSHELL=0
    . "$_xt/suite.trap"
    trap -p EXIT > "$d/carried"
    exit "$2"
  ) > "$d/out" 2>&1
  _xtrc=$?
}
_xtkept() {   # NAME -> kept when the stand-in and the file in it are still there
  [ -e "$_xt/$1" ] || { printf 'not run'; return 0; }
  [ -f "$_xt/$1/tmp/kept" ] && printf kept || printf gone
}
_xtsaid() {   # NAME -> nothing when the child printed none of the report, else what it printed, on one line
  local o=""
  [ -f "$_xt/$1/out" ] || { printf 'not run'; return 0; }
  IFS= read -r -d '' o < "$_xt/$1/out"
  case "$o" in
    *"tests/run:"*|*xt-seeded-refusal*) printf '%s' "${o//"$_xtnl"/ | }" ;;
    *) printf nothing ;;
  esac
}

for _xtk in counted uncounted seven; do
  case "$_xtk" in
    counted)   _xts=0; _xtkid "$_xtk" 0
               _xtwho="a child of the suite that exits 0 through the suite's EXIT trap" ;;
    uncounted) _xts=0; _xtkid "$_xtk" 0 uncounted
               _xtwho="a child of the suite that reads BASH_SUBSHELL 0, as a child bash has not yet counted does, and exits 0 through the suite's EXIT trap" ;;
    seven)     _xts=7; _xtkid "$_xtk" 7
               _xtwho="a child of the suite that exits 7 through the suite's EXIT trap" ;;
  esac
  is "$_xtwho leaves the directory standing in for the temporary directory, and the file in it, where they were" \
     "$(_xtkept "$_xtk")" "kept"
  is "$_xtwho prints nothing of the end-of-run report, on stdout or stderr, though the refusal record it was handed holds a line" \
     "$(_xtsaid "$_xtk")" "nothing"
  is "$_xtwho still ends, with status $_xts, the status it exited with" "$_xtrc" "$_xts"
done

_xtcarried=""
for _xtk in counted uncounted seven; do
  cmp -s "$_xt/suite.trap" "$_xt/$_xtk/carried" 2>/dev/null && _xtcarried="$_xtcarried $_xtk"
done
is "fixture control: each child carried exactly this shell's EXIT trap when it exited, and the suite's own temporary directory and run record are still there" \
   "${_xtcarried# }:$([ -d "$TMP/cwd" ] && [ -f "$FELIX_TEST_RAN" ] && printf there || printf gone)" \
   "counted uncounted seven:there"
