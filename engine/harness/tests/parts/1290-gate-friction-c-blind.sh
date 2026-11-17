# >>> gate-friction-c-blind
printf '\ngate friction C: the suite reads tests/lib, and nothing in it runs when sourced (blind)\n'
# Blind, written on 2026-10-16 from contract C alone (docs/2026-10-16-gate-
# friction-contract-c.md, C2 and C3) and the interface decided for it, before
# any implementation existed. Nothing here was read off one. The interface:
#
# - tests/run sources every tests/lib/*.sh by one line, . "$HERE/lib/NAME.sh",
#   in LC_ALL=C name order, all of them between the line sourcing
#   parts/0005-fixture-floor.sh and the line sourcing parts/0010-resolution.sh,
#   and no line names a file that is not there;
# - _suite_files, in the driver or a prelude part, prints the path of the
#   driver, of every tests/parts/*.sh and of every tests/lib/*.sh, one a line,
#   and nothing else;
# - _suite_src prints the text of every part, every lib file and the driver;
#   _suite_flat gives the driver with each part line and each lib line
#   replaced by the text of the file it names;
# - _lib_runs_nothing FILE sources FILE in a subshell, in a scratch directory
#   standing in for $TMP, with TMP, FROOT, MEM and REPO pointed under it, and
#   returns 0 only when that printed nothing, created, changed or removed
#   nothing under the scratch directory and left PASS, FAIL and SKIP as they
#   were; otherwise 1, with one line naming FILE and what it did.
#
# Readings taken where the interface leaves room. The lib-line check below is
# this part's own function, run on the real driver and on planted copies of it,
# so a planted copy proves the same code bites. A lib line is one whole line of
# exactly that form; any other spelling is not a line for the file. Paths
# _suite_files prints are compared as files, with their directories resolved
# physically, in no particular order. A copy of the tree is pointed at the way
# _suite_src and _suite_flat read today, HERE and REAL_HARNESS both, in a
# subshell with a TMP of its own, so _suite_flat's cache under $TMP is the
# copy's and not this run's. Each planted file for _lib_runs_nothing does one
# thing, silently where the thing is not printing, so it is caught for that
# thing: the ok case's output is thrown away, so only PASS can give it away.
# Its git init goes through _fx_git, as every fixture git write does, so it
# runs only where the scratch directory lies below a fixture root such as
# $TMP; elsewhere _fx_git refuses it, the record makes the run's end red, and
# the case reads as not caught. Those calls run in a subshell of this part's
# whose FELIX_TEST_RAN is a sink of its own, so a planted ok never reaches the
# run's list of names.
#
# Before the implementation, the lib-line checks pass (the real tree has no
# lib and no lib line, and the planted copies test this part's own check); the
# rest FAIL, and the check of the real lib files skips, saying there are none.
#
# Amended 2026-10-16, blind again, from an amended interface, after a reviewer
# found how much a lib file can do at source time that the judge missed. It
# replaces the _lib_runs_nothing bullet above and adds the rest:
# - _lib_runs_nothing FILE judges FILE in a new /bin/bash --noprofile --norc,
#   under env -i with only PATH, and HOME, TMPDIR, TMP, FROOT, MEM, REPO,
#   FELIX_HOME and FELIX in a fresh scratch directory under $TMP, with set -u
#   and pipefail. 0 only when every command run while sourcing is a plain
#   assignment (NAME=VALUE words only, no $( , backtick, <( or >( in a value;
#   a function definition runs none), nothing was printed, nothing under the
#   scratch directory was created, changed or removed, and the shell did not
#   end before the source returned. Otherwise 1, and one line naming FILE and
#   the first thing it did;
# - the driver writes $TMP/lib-before.names at the start of its lib block,
#   after the 0005 line and before its first lib line, or the 0010 line when
#   it has none: every variable and function name defined there, one a line;
# - _lib_clashes prints NAME<TAB>LIBFILE<TAB>WHAT for a name a lib file
#   assigns or defines that lib-before.names holds (WHAT: defined before the
#   lib block), and for a function a lib file defines that another file of
#   _suite_files defines too (WHAT: that file's path); nothing when none. A
#   variable a later part sets too is no clash.
# Readings. (e) gains one assertion a hole, named for what the planted file
# does. Three holes are names, not commands, and go to _lib_clashes. Each new
# judge call runs in a subshell with HOME, TMPDIR, FELIX_HOME and FELIX under
# $GCI, so a judge that leaves one alone lets the write land there, outside
# its scratch directory and still inside $TMP; the guarded build runs with its
# guard exported as set, as a lib block that built it leaves it. (g) plants its
# clashes and (e)'s three in the copy (c) made, each with its lib line, and runs
# _lib_clashes there once, with a TMP holding this run's lib-before.names;
# paths are compared as files. (h) reads "the line that writes" as the one
# driver line outside a comment that names lib-before.names. Before the
# amended implementation most hole cases, (g) and (h) FAIL.
#
# Amended again 2026-10-16, a third round, blind, after two reviews of the
# judges found a lib file could still weaken the serial run. C2 now reads: a
# lib file, sourced, defines functions and nothing else; it runs no command and
# sets no variable, not even a plain assignment. It replaces both judges'
# bullets above:
# - _lib_runs_nothing FILE judges FILE in a new /bin/bash --noprofile --norc
#   under env -i, with PATH, and HOME, TMPDIR, TMP, FROOT, MEM, REPO,
#   FELIX_HOME and FELIX in a fresh scratch directory under $TMP; set -u,
#   pipefail, extdebug and a DEBUG trap that records each command and skips it;
#   a 10 s limit. 0 only when no command was recorded, nothing was printed,
#   nothing under the scratch directory changed, the child's variable names
#   are the same after sourcing as before, and it ended normally within the
#   limit; otherwise 1, and one line naming FILE and the first thing it did;
# - _lib_clashes takes a lib file's names from a judging child (the functions
#   it holds after sourcing and not before) and prints NAME<TAB>LIBFILE<TAB>WHAT
#   for each that lib-before.names holds (defined before the lib block), that
#   is a builtin, keyword, alias or command on PATH (a builtin, a keyword, an
#   alias, or the command's path), that another lib file defines, or that
#   another file of _suite_files defines by its text (that file's path).
# Readings. Each assertion that passed a plain assignment now refuses it, on
# the same planted file. A clash case that sets a variable is refused by
# _lib_runs_nothing, and _lib_clashes, naming functions only, prints no line
# for it. A builtin's WHAT is "a builtin"; git's is the path type -P finds here,
# on the PATH the judge is handed. Files both judges must pass are planted in
# the copy with function names made at run time, so no file of the tree holds
# their definitions. Every _gci_judge call runs under ulimit -t 20, so a judge
# with no limit of its own meets the endless loop as a FAIL, not a hang; that
# case also times the call and allows the 10 s limit and 10 s more. (h) reads
# "a function that part 0006 defines" as the two judges, each defined by a line
# of 0006 at its left margin. Before the third-round judges, most new cases FAIL.
GCI="$TMP/gci"; mkdir -p "$GCI"
GCI_NO="no function by that name in the prelude"

# ---- (a) and (b): the driver's lib lines
# <driver> <lib dir>: silent, status 0, when the driver sources each
# <lib dir>/*.sh, as ls lists them, by one line, in LC_ALL=C name order, every
# such line after the line sourcing part 0005 and before the line sourcing
# part 0010, and no such line names a file that is not there. Otherwise one
# line a problem, and status 1.
_gci_lib_lines() {
  local want=""
  if [ -n "${2:-}" ] && [ -d "$2" ]; then
    want="$(cd "$2" && LC_ALL=C ls | LC_ALL=C awk '/\.sh$/' | LC_ALL=C sort)"
  fi
  [ -n "${1:-}" ] && [ -f "$1" ] || { printf 'no driver at [%s]\n' "${1:-}"; return 1; }
  GCI_WANT="$want" LC_ALL=C awk '
    BEGIN {
      k = split(ENVIRON["GCI_WANT"], w, "\n")
      for (i = 1; i <= k; i++) if (w[i] != "") { want[++nw] = w[i]; there[w[i]] = 1 }
      A5 = ". \"$HERE/parts/0005-fixture-floor.sh\""; A10 = ". \"$HERE/parts/0010-resolution.sh\""
    }
    $0 == A5  { n5++;  at5 = FNR }
    $0 == A10 { n10++; at10 = FNR }
    /^\. "\$HERE\/lib\/[^"]*"$/ { g++; got[g] = substr($0, 14, length($0) - 14); at[g] = FNR; cnt[got[g]]++ }
    END {
      if (n5 != 1)  { print "the driver has " (n5 + 0) " lines sourcing parts/0005-fixture-floor.sh, not one"; bad = 1 }
      if (n10 != 1) { print "the driver has " (n10 + 0) " lines sourcing parts/0010-resolution.sh, not one"; bad = 1 }
      for (i = 1; i <= nw; i++) if (!(want[i] in cnt)) { print "no line sources lib/" want[i]; bad = 1 }
      for (i = 1; i <= g; i++) {
        n = got[i]
        if (!(n in there)) { print "line " at[i] " sources lib/" n ", which is not there"; bad = 1 }
        else if (cnt[n] > 1 && !(n in said)) { said[n] = 1; print "lib/" n " is sourced by " cnt[n] " lines, not one"; bad = 1 }
        if (n5 == 1 && at[i] < at5) { print "line " at[i] " sources lib/" n " before the line sourcing parts/0005-fixture-floor.sh, line " at5; bad = 1 }
        if (n10 == 1 && at[i] > at10) { print "line " at[i] " sources lib/" n " after the line sourcing parts/0010-resolution.sh, line " at10; bad = 1 }
      }
      if (!bad) for (i = 1; i <= g; i++) if (got[i] != want[i]) {
        print "the lib lines are out of name order: line " at[i] " sources lib/" got[i] " where lib/" want[i] " comes next by name"
        bad = 1; break
      }
      exit bad
    }' "$1"
}
_gci_o="$(_gci_lib_lines "$HERE/run" "$HERE/lib")"; _gci_rc=$?
_gci_n="the driver sources every tests/lib/*.sh by one line each, in name order, between the lines sourcing parts 0005 and 0010, and no line names a lib file that is not there"
if [ "$_gci_rc" -eq 0 ]; then ok "$_gci_n"
else bad "$_gci_n" "the check returned $_gci_rc: $(LC_ALL=C tr '\n' ' ' <<<"$_gci_o")"; fi

# Planted copies: the real driver with its own lib lines dropped and lines for
# three planted lib files, gci-a.sh, gci-b.sh and gci-c.sh, put where a case
# says, against a lib directory that holds just those three.
GCI_PL="$GCI/plant-lib"; mkdir -p "$GCI_PL"
: > "$GCI_PL/gci-a.sh"; : > "$GCI_PL/gci-b.sh"; : > "$GCI_PL/gci-c.sh"
_gci_plant() {   # <out> <lib names before the 0005 line> <after it> <after the 0010 line>
  GCI_B="$2" GCI_W="$3" GCI_A="$4" LC_ALL=C awk '
    function put(list,   n, i, w) { n = split(list, w, " "); for (i = 1; i <= n; i++) print ". \"$HERE/lib/" w[i] "\"" }
    /^\. "\$HERE\/lib\/[^"]*"$/ { next }
    $0 == ". \"$HERE/parts/0005-fixture-floor.sh\"" { put(ENVIRON["GCI_B"]); print; put(ENVIRON["GCI_W"]); next }
    $0 == ". \"$HERE/parts/0010-resolution.sh\"" { print; put(ENVIRON["GCI_A"]); next }
    { print }' "$HERE/run" > "$1"
}
_gci_bites() {   # <assertion name> <words the reason must hold> <before 0005> <after 0005> <after 0010>
  local o rc
  _gci_plant "$GCI/plant-run" "$3" "$4" "$5"
  o="$(_gci_lib_lines "$GCI/plant-run" "$GCI_PL")"; rc=$?
  case "$rc|$o" in
    "1|"*"$2"*) ok "$1" ;;
    *) bad "$1" "the check returned $rc and said [$(LC_ALL=C tr '\n' ' ' <<<"$o")]; a defect wants 1 and a reason holding [$2]" ;;
  esac
}
_gci_plant "$GCI/plant-run" "" "gci-a.sh gci-b.sh gci-c.sh" ""
_gci_o="$(_gci_lib_lines "$GCI/plant-run" "$GCI_PL")"; _gci_rc=$?
is  "the lib-line check passes a planted copy of the driver whose three lib files have one line each, in name order, inside the window (control)" \
    "$_gci_rc|$_gci_o" "0|"
_gci_bites "the lib-line check catches, in a planted copy of the driver, a lib file with no line" \
    "no line sources lib/gci-b.sh" "" "gci-a.sh gci-c.sh" ""
_gci_bites "the lib-line check catches, in a planted copy of the driver, a line naming a lib file that is not there" \
    "lib/gci-d-gone.sh, which is not there" "" "gci-a.sh gci-b.sh gci-c.sh gci-d-gone.sh" ""
_gci_bites "the lib-line check catches, in a planted copy of the driver, two lib lines out of name order" \
    "out of name order" "" "gci-b.sh gci-a.sh gci-c.sh" ""
_gci_bites "the lib-line check catches, in a planted copy of the driver, a lib line after the line sourcing part 0010" \
    "sources lib/gci-c.sh after the line sourcing parts/0010-resolution.sh" "" "gci-a.sh gci-b.sh" "gci-c.sh"
_gci_bites "the lib-line check catches, in a planted copy of the driver, a lib line before the line sourcing part 0005" \
    "sources lib/gci-a.sh before the line sourcing parts/0005-fixture-floor.sh" "gci-a.sh" "gci-b.sh gci-c.sh" ""
_gci_bites "the lib-line check catches, in a planted copy of the driver, a lib file sourced by two lines" \
    "lib/gci-b.sh is sourced by 2 lines" "" "gci-a.sh gci-b.sh gci-b.sh gci-c.sh" ""

# ---- (c): _suite_files
# Paths on stdin, one a line -> each with its directory made physical, a
# relative one read from where the shell stands. One fork per directory met.
_gci_canon() {
  local p d b last="" lastp="" pd
  while IFS= read -r p; do
    case "$p" in /*) ;; *) p="$PWD/$p" ;; esac
    d="${p%/*}"; b="${p##*/}"
    if [ -n "$last" ] && [ "$d" = "$last" ]; then pd="$lastp"
    else
      pd="$(cd -P -- "${d:-/}" 2>/dev/null && pwd -P)" || pd="(no directory ${d:-/})"
      last="$d"; lastp="$pd"
    fi
    printf '%s/%s\n' "$pd" "$b"
  done
}
_gci_want_files() {   # <tests dir>: its driver, every parts/*.sh and every lib/*.sh, one path a line
  local f
  printf '%s\n' "$1/run"
  for f in "$1"/parts/*.sh "$1"/lib/*.sh; do [ -f "$f" ] && printf '%s\n' "$f"; done
  return 0
}
_gci_same() {   # <assertion name> <got> <want>, files of lines sorted in C: ok when they are the same lines
  local m x
  if cmp -s "$2" "$3"; then ok "$1"; return 0; fi
  m="$(LC_ALL=C comm -13 "$2" "$3" | head -3 | cut -c1-160 | LC_ALL=C tr '\n' ' ')"
  x="$(LC_ALL=C comm -23 "$2" "$3" | head -3 | cut -c1-160 | LC_ALL=C tr '\n' ' ')"
  bad "$1" "$(LC_ALL=C comm -13 "$2" "$3" | wc -l | tr -d ' ') line(s) missing, the first [$m]; $(LC_ALL=C comm -23 "$2" "$3" | wc -l | tr -d ' ') extra, the first [$x]"
}
_gci_want_files "$HERE" | _gci_canon | LC_ALL=C sort > "$GCI/files.want"
_gci_n="_suite_files lists exactly the driver, every tests/parts/*.sh and every tests/lib/*.sh, one path a line, as ls finds them"
if declare -F _suite_files >/dev/null; then
  _suite_files 2>/dev/null | _gci_canon | LC_ALL=C sort > "$GCI/files.got"
  _gci_same "$_gci_n" "$GCI/files.got" "$GCI/files.want"
else
  bad "$_gci_n" "_suite_files: $GCI_NO"
fi

# The copy: this tree's tests directory, then a lib file planted in it with
# its line in the driver, last in the window, and beside it a file in lib that
# is not a .sh. The planted file's first line holds a value made at run time,
# so no file of the tree holds it, this one included.
GCI_T="$GCI/tree/tests"; GCI_PN="zz-gci-planted.sh"; GCI_NONCE="$$.$RANDOM.$RANDOM"
GCI_MARK="# gci planted lib file $GCI_NONCE: one definition and one plain assignment"
_copy_content "$HERE" "$GCI_T"; mkdir -p "$GCI_T/lib"
printf '%s\n_gci_planted_fn() { :; }\n_gci_planted_var=planted\n' "$GCI_MARK" > "$GCI_T/lib/$GCI_PN"
printf 'not a lib file\n' > "$GCI_T/lib/gci-planted-notes.txt"
GCI_PN="$GCI_PN" LC_ALL=C awk '$0 == ". \"$HERE/parts/0010-resolution.sh\"" { print ". \"$HERE/lib/" ENVIRON["GCI_PN"] "\"" } { print }' \
  "$GCI_T/run" > "$GCI/run.planted" && cat "$GCI/run.planted" > "$GCI_T/run"
mkdir -p "$GCI/tmp-files" "$GCI/tmp-src" "$GCI/tmp-flat"
GCI_PP="$(printf '%s\n' "$GCI_T/lib/$GCI_PN" | _gci_canon)"
_gci_n1="_suite_files, pointed at a copy of the tree, lists a lib file planted in the copy"
_gci_n2="and lists exactly that copy's driver, parts and lib files, leaving out a file in lib that is not a .sh"
if declare -F _suite_files >/dev/null; then
  ( HERE="$GCI_T"; REAL_HARNESS="${GCI_T%/tests}"; TMP="$GCI/tmp-files"; _suite_files ) 2>/dev/null \
    | _gci_canon | LC_ALL=C sort > "$GCI/copy-files.got"
  if LC_ALL=C grep -qxF -e "$GCI_PP" "$GCI/copy-files.got"; then ok "$_gci_n1"
  else bad "$_gci_n1" "[$GCI_PP] is not among the $(LC_ALL=C awk 'END { print NR }' "$GCI/copy-files.got") path(s) it printed"; fi
  _gci_want_files "$GCI_T" | _gci_canon | LC_ALL=C sort > "$GCI/copy-files.want"
  _gci_same "$_gci_n2" "$GCI/copy-files.got" "$GCI/copy-files.want"
else
  bad "$_gci_n1" "_suite_files: $GCI_NO"; bad "$_gci_n2" "_suite_files: $GCI_NO"
fi
rm -f "$GCI_T/lib/gci-planted-notes.txt"

# ---- (d): _suite_src and _suite_flat, in the same copy
_gci_n1="_suite_src, pointed at a copy of the tree, prints the text of a lib file planted there"
_gci_n2="and prints exactly the copy's driver, parts and lib files, line for line, in whatever order"
if declare -F _suite_src >/dev/null; then
  ( HERE="$GCI_T"; REAL_HARNESS="${GCI_T%/tests}"; TMP="$GCI/tmp-src"; _suite_src ) > "$GCI/src.out" 2>/dev/null
  _gci_c="$(LC_ALL=C grep -cxF -e "$GCI_MARK" "$GCI/src.out")"
  [ "${_gci_c:-0}" -ge 1 ] 2>/dev/null && ok "$_gci_n1" \
    || bad "$_gci_n1" "the planted file's first line is not in the $(LC_ALL=C awk 'END { print NR }' "$GCI/src.out") line(s) it printed"
  LC_ALL=C sort "$GCI/src.out" > "$GCI/src.got"
  cat "$GCI_T/run" "$GCI_T"/parts/*.sh "$GCI_T"/lib/*.sh | LC_ALL=C sort > "$GCI/src.want"
  _gci_same "$_gci_n2" "$GCI/src.got" "$GCI/src.want"
else
  bad "$_gci_n1" "_suite_src: $GCI_NO"; bad "$_gci_n2" "_suite_src: $GCI_NO"
fi
# The copy's driver with each part line and each lib line replaced by the
# text of the file it names, built here on its own, to compare whole.
LC_ALL=C awk -v d="$GCI_T/" '
  /^\. "\$HERE\/parts\/[^"\/]+"$/ { f = d "parts/" substr($0, 16, length($0) - 16) }
  /^\. "\$HERE\/lib\/[^"\/]+"$/   { f = d "lib/" substr($0, 14, length($0) - 14) }
  f != "" { while ((getline l < f) > 0) print l; close(f); f = ""; next }
  { print }' "$GCI_T/run" > "$GCI/flat.want"
_gci_n1="_suite_flat, pointed at a copy of the tree with a TMP of its own, holds the text of a lib file planted and sourced there"
_gci_n2="and is exactly the copy's driver with each part line and each lib line replaced by the text of the file it names"
if declare -F _suite_flat >/dev/null; then
  ( HERE="$GCI_T"; REAL_HARNESS="${GCI_T%/tests}"; TMP="$GCI/tmp-flat"
    _gci_f="$(_suite_flat)" || exit 1; cat "$_gci_f" ) > "$GCI/flat.out" 2>/dev/null; _gci_rc=$?
  _gci_c="$(LC_ALL=C grep -cxF -e "$GCI_MARK" "$GCI/flat.out")"
  if [ "$_gci_rc" -ne 0 ]; then bad "$_gci_n1" "_suite_flat returned non-zero for the copy"
  elif [ "${_gci_c:-0}" -ge 1 ] 2>/dev/null; then ok "$_gci_n1"
  else bad "$_gci_n1" "the planted file's first line is not in it; the line sourcing it reads [$(LC_ALL=C grep -cF -e "lib/$GCI_PN" "$GCI/flat.out")] time(s)"; fi
  if [ "$_gci_rc" -eq 0 ] && cmp -s "$GCI/flat.out" "$GCI/flat.want"; then ok "$_gci_n2"
  else bad "$_gci_n2" "status $_gci_rc; $(cmp "$GCI/flat.out" "$GCI/flat.want" 2>&1 | head -1)"; fi
else
  bad "$_gci_n1" "_suite_flat: $GCI_NO"; bad "$_gci_n2" "_suite_flat: $GCI_NO"
fi

# ---- (e): _lib_runs_nothing on planted lib files
GCI_L="$GCI/lrn"; mkdir -p "$GCI_L"; : > "$GCI/lrn-ran"
cat > "$GCI_L/gci-lrn-clean.sh" <<'GCI_LRN_CLEAN'
# planted: definitions and plain assignments, nothing that runs
_gci_lrn_fn() {
  printf 'gci: _gci_lrn_fn ran, which only a call does\n'
  mkdir -p "$TMP/gci-lrn-fn-ran"
  ok "gci: _gci_lrn_fn ran"
}
_gci_lrn_var="a plain value"
_gci_lrn_two='one two'
_gci_lrn_three=3
GCI_LRN_CLEAN
cat > "$GCI_L/gci-lrn-prints.sh" <<'GCI_LRN_PRINTS'
printf 'gci: a line printed at source time\n'
GCI_LRN_PRINTS
cat > "$GCI_L/gci-lrn-writes.sh" <<'GCI_LRN_WRITES'
{ printf 'gci\n' > "$TMP/gci-lrn-written"; } 2>/dev/null
GCI_LRN_WRITES
cat > "$GCI_L/gci-lrn-mkdir.sh" <<'GCI_LRN_MKDIR'
mkdir "$TMP/gci-lrn-made" 2>/dev/null
GCI_LRN_MKDIR
cat > "$GCI_L/gci-lrn-ok.sh" <<'GCI_LRN_OK'
ok "gci: an ok called at source time" >/dev/null 2>&1
GCI_LRN_OK
cat > "$GCI_L/gci-lrn-git-init.sh" <<'GCI_LRN_GIT'
_fx_git "$TMP" init -q >/dev/null 2>&1
GCI_LRN_GIT

_gci_n1="_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that holds only definitions and plain assignments"
_gci_n2="_lib_runs_nothing leaves its caller as it was: no function or variable from the file, and TMP, FROOT, MEM and REPO unchanged"
if declare -F _lib_runs_nothing >/dev/null; then
  _gci_was="${TMP-}|${FROOT-}|${MEM-}|${REPO-}"
  _lib_runs_nothing "$GCI_L/gci-lrn-clean.sh" > "$GCI/lrn.clean" 2>&1; _gci_rc=$?
  _gci_v="$_gci_rc|$(LC_ALL=C awk 'END { print NR }' "$GCI/lrn.clean") line(s)|"
  if LC_ALL=C grep -qF -e gci-lrn-clean.sh "$GCI/lrn.clean"; then _gci_v="${_gci_v}names the file"; else _gci_v="${_gci_v}does not name the file"; fi
  [ "$_gci_v" = "1|1 line(s)|names the file" ] && ok "$_gci_n1" \
    || bad "$_gci_n1" "status|lines|naming: [$_gci_v], wanted [1|1 line(s)|names the file]; it said [$(head -3 "$GCI/lrn.clean" | LC_ALL=C tr '\n' ' ')]"
  _gci_v="$(declare -F _gci_lrn_fn >/dev/null && printf 'the function is defined; ')$([ -n "${_gci_lrn_var+x}" ] && printf 'the variable is set; ')"
  [ "${TMP-}|${FROOT-}|${MEM-}|${REPO-}" = "$_gci_was" ] || _gci_v="${_gci_v}TMP|FROOT|MEM|REPO went from [$_gci_was] to [${TMP-}|${FROOT-}|${MEM-}|${REPO-}]"
  [ -z "$_gci_v" ] && ok "$_gci_n2" || bad "$_gci_n2" "$_gci_v"
else
  bad "$_gci_n1" "_lib_runs_nothing: $GCI_NO"; bad "$_gci_n2" "_lib_runs_nothing: $GCI_NO"
fi
# <assertion name> <planted file>: it returns 1 and prints one line, which
# names the file. Run in a subshell whose FELIX_TEST_RAN is a sink.
_gci_caught() {
  local o="$GCI/lrn.out.${2##*/}" rc lines named v
  if ! declare -F _lib_runs_nothing >/dev/null; then bad "$1" "_lib_runs_nothing: $GCI_NO"; return 0; fi
  ( FELIX_TEST_RAN="$GCI/lrn-ran"; _lib_runs_nothing "$2" ) > "$o" 2>&1; rc=$?
  lines="$(LC_ALL=C awk 'END { print NR }' "$o")"
  if LC_ALL=C grep -qF -e "${2##*/}" "$o"; then named="names the file"; else named="does not name the file"; fi
  v="$rc|$lines line(s)|$named"
  [ "$v" = "1|1 line(s)|names the file" ] && ok "$1" \
    || bad "$1" "status|lines|naming: [$v], wanted [1|1 line(s)|names the file]; it said [$(head -3 "$o" | LC_ALL=C tr '\n' ' ')]"
}
_gci_caught "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that prints a line when sourced" \
    "$GCI_L/gci-lrn-prints.sh"
_gci_caught "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that silently writes a file under TMP when sourced" \
    "$GCI_L/gci-lrn-writes.sh"
_gci_caught "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that silently creates a directory when sourced" \
    "$GCI_L/gci-lrn-mkdir.sh"
_gci_caught "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that calls ok when sourced, its output thrown away" \
    "$GCI_L/gci-lrn-ok.sh"
_gci_caught "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that silently runs git init in the scratch directory when sourced" \
    "$GCI_L/gci-lrn-git-init.sh"

# ---- (e), amended: the reviewer's holes, one planted file each, and three
# files the judge must still pass.
GCI_E="$GCI/lrn-env"; mkdir -p "$GCI_E/home" "$GCI_E/tmpdir" "$GCI_E/felix-home" "$GCI/lrn-outside"
_gci_put() { printf '%s\n' "$2" > "$GCI_L/$1"; }   # <file name> <text>: a planted lib file in $GCI_L
_gci_judge() {   # <planted file> <out> [NAME=VALUE the caller exports] -> the judge's status in _gci_rc
  ( ulimit -c 0 2>/dev/null; ulimit -t 20 2>/dev/null
    FELIX_TEST_RAN="$GCI/lrn-ran"; HOME="$GCI_E/home"; TMPDIR="$GCI_E/tmpdir"
    FELIX_HOME="$GCI_E/felix-home"; FELIX="$GCI_E/felix"; export HOME TMPDIR FELIX_HOME FELIX
    [ -z "${3:-}" ] || export "$3"
    _lib_runs_nothing "$1" ) > "$2" 2>&1
  _gci_rc=$?
}
_gci_refuses() {   # <assertion name> <planted file name> [NAME=VALUE]: 1, and one line naming the file
  local o="$GCI/lrn.out.$2" v
  if ! declare -F _lib_runs_nothing >/dev/null; then bad "$1" "_lib_runs_nothing: $GCI_NO"; return 0; fi
  _gci_judge "$GCI_L/$2" "$o" "${3:-}"
  v="$_gci_rc|$(LC_ALL=C awk 'END { print NR }' "$o") line(s)|"
  if LC_ALL=C grep -qF -e "$2" "$o"; then v="${v}names the file"; else v="${v}does not name the file"; fi
  if [ "$v" = "1|1 line(s)|names the file" ]; then ok "$1"
  else bad "$1" "status|lines|naming: [$v], wanted [1|1 line(s)|names the file]; it said [$(head -3 "$o" | LC_ALL=C tr '\n' ' ')]"; fi
}
_gci_passes() {   # <assertion name> <planted file name>: status 0
  if ! declare -F _lib_runs_nothing >/dev/null; then bad "$1" "_lib_runs_nothing: $GCI_NO"; return 0; fi
  _gci_judge "$GCI_L/$2" "$GCI/lrn.out.$2"
  if [ "$_gci_rc" -eq 0 ]; then ok "$1"
  else bad "$1" "it returned $_gci_rc and said [$(head -3 "$GCI/lrn.out.$2" | LC_ALL=C tr '\n' ' ')]"; fi
}
_gci_put gci-lrn-h02-fail-arith.sh 'FAIL=$((0))'
_gci_put gci-lrn-h03-trap-cleared.sh 'trap - EXIT'
_gci_put gci-lrn-h04-trap-prints.sh "trap 'printf x' EXIT"
_gci_put gci-lrn-h05-exec.sh 'exec >/dev/null 2>&1'
_gci_put gci-lrn-h06-set-u-off.sh 'set +u'
_gci_put gci-lrn-h07-shopt.sh 'shopt -s nullglob'
_gci_put gci-lrn-h08-umask.sh 'umask 000'
_gci_put gci-lrn-h09-cd.sh 'cd /'
_gci_put gci-lrn-h10-export.sh 'export GIT_DIR=/nonexistent'
_gci_put gci-lrn-h12-late-write.sh '( sleep 1; : > "$TMP/late" ) &'
_gci_put gci-lrn-h13-sleep.sh 'sleep 30 &'
_gci_put gci-lrn-h14-home.sh ': > "$HOME/x"'
_gci_put gci-lrn-h14-fixed-path.sh ": > \"$GCI/lrn-outside/x\""
_gci_put gci-lrn-h15-felix-home.sh 'mkdir -p "$FELIX_HOME/state/x"'
_gci_put gci-lrn-h16-subst.sh '_v="$(git --version)"'
_gci_put gci-lrn-h17-made-and-gone.sh ': > "$TMP/t"; rm -f "$TMP/t"'
_gci_put gci-lrn-h18-guarded-build.sh '[ -n "${_zz_built:-}" ] || { mkdir -p "$TMP/zz-fixture"; _zz_built=1; }'
_gci_put gci-lrn-h19-exit.sh 'exit 0'
_gci_put gci-lrn-h20-readonly.sh 'readonly X=1'
_gci_put gci-lrn-h20-declare.sh 'declare -x X=1'
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets FAIL, the driver's counter, through an arithmetic expansion" gci-lrn-h02-fail-arith.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that clears the EXIT trap" gci-lrn-h03-trap-cleared.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets an EXIT trap which prints when the shell ends" gci-lrn-h04-trap-prints.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sends the shell's stdout and stderr to /dev/null with exec" gci-lrn-h05-exec.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that turns set -u off" gci-lrn-h06-set-u-off.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that turns on a shell option with shopt" gci-lrn-h07-shopt.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that changes the umask" gci-lrn-h08-umask.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that changes directory" gci-lrn-h09-cd.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that exports GIT_DIR" gci-lrn-h10-export.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that starts a background subshell which writes under TMP a second later" gci-lrn-h12-late-write.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that leaves a background sleep running" gci-lrn-h13-sleep.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that writes a file under HOME" gci-lrn-h14-home.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that writes a file at a fixed absolute path outside the scratch directory" gci-lrn-h14-fixed-path.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that creates a directory under FELIX_HOME" gci-lrn-h15-felix-home.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that runs git in a command substitution inside an assignment" gci-lrn-h16-subst.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that creates a file under TMP and removes it again" gci-lrn-h17-made-and-gone.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that builds a fixture behind a guard variable the caller has set and exported" \
    gci-lrn-h18-guarded-build.sh _zz_built=1
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that calls exit at top level" gci-lrn-h19-exit.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets a variable with readonly" gci-lrn-h20-readonly.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets a variable with declare -x" gci-lrn-h20-declare.sh

# ---- (e), third round: a lib file that sets any variable, by any route.
_gci_put gci-lrn-t01-literal.sh 'X=literal'
_gci_put gci-lrn-t02-froot.sh 'X="$FROOT/projects/widget"'
_gci_put gci-lrn-t03-brace.sh '{ FAIL=0; }'
_gci_put gci-lrn-t04-if.sh 'if FAIL=0; then _x=1; fi'
_gci_put gci-lrn-t05-bang.sh '! PASS=0'
_gci_put gci-lrn-t06-until.sh 'until FAIL=0; do _x=1; done'
_gci_put gci-lrn-t07-subscript.sh '_x=${_a[SKIP=0]-}'
_gci_put gci-lrn-t08-default.sh '_y=${FELIX_TEST_RAN:=/dev/null}'
_gci_put gci-lrn-t09-globignore.sh "GLOBIGNORE='*'"
_gci_put gci-lrn-t10-posixly.sh 'POSIXLY_CORRECT=1'
_gci_put gci-lrn-t11-cdpath.sh 'CDPATH=/'
_gci_put gci-lrn-t12-no-manifest.sh 'FELIX_TEST_NO_MANIFEST=1'
_gci_put gci-lrn-t14-blind.sh "$(printf '%s\n' '_lrn_log=/dev/null' 'cd /')"
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets a variable to a literal at top level" gci-lrn-t01-literal.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets a variable to a path under FROOT at top level" gci-lrn-t02-froot.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets FAIL inside a brace group" gci-lrn-t03-brace.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets FAIL in the condition of an if" gci-lrn-t04-if.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets PASS behind a !" gci-lrn-t05-bang.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets FAIL in the condition of an until loop" gci-lrn-t06-until.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets SKIP in an array subscript inside an expansion" gci-lrn-t07-subscript.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets FELIX_TEST_RAN through a := expansion" gci-lrn-t08-default.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets GLOBIGNORE" gci-lrn-t09-globignore.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets POSIXLY_CORRECT" gci-lrn-t10-posixly.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets CDPATH" gci-lrn-t11-cdpath.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets FELIX_TEST_NO_MANIFEST" gci-lrn-t12-no-manifest.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that sets _lrn_log to /dev/null and then changes directory, to blind the judge" gci-lrn-t14-blind.sh
# An endless loop: timed, and its one line must name the command or the limit.
_gci_put gci-lrn-t13-loop.sh 'while _x=1; do _y=1; done'
_gci_n="_lib_runs_nothing returns 1 within its 10 s limit and 10 s more, with one line naming the file and the command or the limit, for a lib file whose while loop never ends"
if ! declare -F _lib_runs_nothing >/dev/null; then bad "$_gci_n" "_lib_runs_nothing: $GCI_NO"
else
  _gci_o="$GCI/lrn.out.gci-lrn-t13-loop.sh"; _gci_t=$SECONDS
  _gci_judge "$GCI_L/gci-lrn-t13-loop.sh" "$_gci_o"; _gci_t=$((SECONDS - _gci_t))
  _gci_v="$_gci_rc|$(LC_ALL=C awk 'END { print NR }' "$_gci_o") line(s)|"
  if LC_ALL=C grep -qF -e gci-lrn-t13-loop.sh "$_gci_o"; then _gci_v="${_gci_v}names the file|"; else _gci_v="${_gci_v}does not name the file|"; fi
  if LC_ALL=C grep -qE -e '_x=1|_y=1|while|limit' "$_gci_o"; then _gci_v="${_gci_v}names the command or the limit|"; else _gci_v="${_gci_v}names neither|"; fi
  if [ "$_gci_t" -le 20 ]; then _gci_v="${_gci_v}within 20 s"; else _gci_v="${_gci_v}took $_gci_t s"; fi
  if [ "$_gci_v" = "1|1 line(s)|names the file|names the command or the limit|within 20 s" ]; then ok "$_gci_n"
  else bad "$_gci_n" "[$_gci_v], wanted [1|1 line(s)|names the file|names the command or the limit|within 20 s]; it said [$(head -3 "$_gci_o" | cut -c1-200 | LC_ALL=C tr '\n' ' ')]"; fi
fi
# A write outside the scratch directory: refused, and never carried out.
GCI_W15="$GCI/lrn-outside/t15-written"; rm -f "$GCI_W15"
_gci_put gci-lrn-t15-outside.sh "printf 'gci\\n' > \"$GCI_W15\""
_gci_n="_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that writes a file at a fixed absolute path outside the scratch directory, and the file is not there afterwards: the judge did not carry the write out"
if ! declare -F _lib_runs_nothing >/dev/null; then bad "$_gci_n" "_lib_runs_nothing: $GCI_NO"
else
  _gci_judge "$GCI_L/gci-lrn-t15-outside.sh" "$GCI/lrn.out.gci-lrn-t15-outside.sh"
  _gci_v="$_gci_rc|$(LC_ALL=C awk 'END { print NR }' "$GCI/lrn.out.gci-lrn-t15-outside.sh") line(s)|"
  if LC_ALL=C grep -qF -e gci-lrn-t15-outside.sh "$GCI/lrn.out.gci-lrn-t15-outside.sh"; then _gci_v="${_gci_v}names the file|"; else _gci_v="${_gci_v}does not name the file|"; fi
  if [ -e "$GCI_W15" ]; then _gci_v="${_gci_v}the file was written"; else _gci_v="${_gci_v}no file"; fi
  if [ "$_gci_v" = "1|1 line(s)|names the file|no file" ]; then ok "$_gci_n"
  else bad "$_gci_n" "[$_gci_v], wanted [1|1 line(s)|names the file|no file]; it said [$(head -3 "$GCI/lrn.out.gci-lrn-t15-outside.sh" | LC_ALL=C tr '\n' ' ')]"; fi
fi
cat > "$GCI_L/gci-lrn-p1-defs.sh" <<'GCI_P1_DEFS'
_gci_p1_a() {
  printf 'gci: _gci_p1_a ran\n'
  mkdir -p "$TMP/gci-p1-ran"
}
_gci_p1_b () { trap 'printf x' EXIT; cd /; }
function _gci_p1_c {
  : > "$HOME/gci-p1-c"
}
GCI_P1_DEFS
cat > "$GCI_L/gci-lrn-p2-assign.sh" <<'GCI_P2_ASSIGN'
_gci_p2_widget="$FROOT/projects/widget"
_gci_p2_lit='a literal, with $ and spaces'
_gci_p2_n=3
_gci_p2_empty=
_gci_p2_repo="$REPO" _gci_p2_mem="${MEM}/x"
_gci_p2_home="$HOME/.gci" _gci_p2_tmp="$TMP/gci-p2" _gci_p2_tmpdir="$TMPDIR"
_gci_p2_fh="$FELIX_HOME/state" _gci_p2_cli="$FELIX"
_gci_p2_again="$_gci_p2_widget/again"
GCI_P2_ASSIGN
cat > "$GCI_L/gci-lrn-p3-mixed.sh" <<'GCI_P3_MIXED'
# planted: a lib file of the shape C2 allowed before its third round

# a builder and its settings
_gci_p3_root="$FROOT/projects"

_gci_p3_build() {
  # builds only when called
  mkdir -p "$_gci_p3_root/widget"
  : > "$_gci_p3_root/widget/built"
}
	# an indented comment
_gci_p3_name=widget   # a trailing comment

_gci_p3_path="$_gci_p3_root/$_gci_p3_name"
GCI_P3_MIXED
_gci_passes "_lib_runs_nothing returns 0 for a lib file of function definitions only" gci-lrn-p1-defs.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file of plain assignments whose values are literal strings or name variables" gci-lrn-p2-assign.sh
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file mixing definitions and plain assignments with comments and blank lines" gci-lrn-p3-mixed.sh

# The clash cases, (e)'s three and (g)'s, planted in the copy (c) made, named
# to sort after its planted file, each with a line in the copy's driver just
# before the 0010 line, in name order. The twins' function is named at run
# time, so no file of the tree holds its definition.
GCI_FN="_gci_twin_$$_$RANDOM"
_gci_cput() { printf '%s\n' "$2" > "$GCI_T/lib/zz-gci-x-$1.sh"; }   # <case> <text>
_gci_cput e01-bad 'bad() { :; }'
_gci_cput e02-fail 'FAIL=0'
_gci_cput e11-path 'PATH=/nonexistent:$PATH'
cat > "$GCI_T/lib/zz-gci-x-g1-bad.sh" <<'GCI_G1_BAD'
# planted: helpers, one of them over the driver's bad
_gci_g1_helper() { :; }
bad() {
  printf '  FAIL  %s\n' "$1"
}
GCI_G1_BAD
cat > "$GCI_T/lib/zz-gci-x-g2-fail.sh" <<'GCI_G2_FAIL'
# planted: settings, one of them the driver's counter
_gci_g2_root="$FROOT/projects"
FAIL=0
_gci_g2_name=widget
GCI_G2_FAIL
_gci_cput g3-ifs "IFS=\$'\\n'"
_gci_cput g4-part-fn '_gci_lib_lines() { :; }'
_gci_cput g5-twin-a "$GCI_FN() { :; }"
_gci_cput g5-twin-b "$GCI_FN() { return 0; }"
_gci_cput g6-later-var 'GCI_NO="also set by part 1290, after the lib block"'
# Third round: a definition inside braces, four names bash or PATH already
# has, and two files both judges must pass, whose function names are made at
# run time.
_gci_cput e03-brace-bad '{ bad() { :; }; }'
_gci_cput b1-bracket '[() { return 0; }'
_gci_cput b2-dot '.() { :; }'
_gci_cput b3-printf 'printf() { :; }'
_gci_cput b4-git 'git() { :; }'
GCI_U="_gci_u$$_$RANDOM"
cat > "$GCI_T/lib/zz-gci-x-p4-defs.sh" <<GCI_P4_DEFS
# planted: function definitions only, with comments and blank lines

# the first helper
${GCI_U}_a() {
  :
}

  # an indented comment
${GCI_U}_b () { return 0; }

function ${GCI_U}_c {
  # a comment inside a body
  printf '%s\n' "\$1"
}
# a last comment
GCI_P4_DEFS
cat > "$GCI_T/lib/zz-gci-x-p5-body.sh" <<GCI_P5_BODY
# planted: a builder whose body sets variables, calls commands and writes files
${GCI_U}_build() {
  local _w="\$FROOT/projects/gci-widget"
  ${GCI_U}_root="\$_w"; FAIL=\$((FAIL + 0))
  mkdir -p "\$_w/sub"
  printf 'built\n' > "\$_w/built"
  _fx_git "\$_w" init -q
  ok "gci: ${GCI_U}_build ran"
}
GCI_P5_BODY
for _gci_f in "$GCI_T"/lib/zz-gci-x-*.sh; do printf '%s\n' "${_gci_f##*/}"; done | LC_ALL=C sort > "$GCI/clash.libs"
GCI_LIST="$GCI/clash.libs" LC_ALL=C awk '$0 == ". \"$HERE/parts/0010-resolution.sh\"" { while ((getline l < (ENVIRON["GCI_LIST"])) > 0) print ". \"$HERE/lib/" l "\"" } { print }' \
  "$GCI_T/run" > "$GCI/run.clash" && cat "$GCI/run.clash" > "$GCI_T/run"
mkdir -p "$GCI/tmp-clash"; GCI_LBN=""
if [ -f "$TMP/lib-before.names" ]; then cp "$TMP/lib-before.names" "$GCI/tmp-clash/lib-before.names"
else GCI_LBN="; this run has no lib-before.names under TMP to hand it"; fi
GCI_CL="$(cd -P "$GCI_T/lib" && pwd -P)"; GCI_CP="$(cd -P "$GCI_T/parts" && pwd -P)"
: > "$GCI/clash.out"; : > "$GCI/clash.norm"
if declare -F _lib_clashes >/dev/null; then
  ( HERE="$GCI_T"; REAL_HARNESS="${GCI_T%/tests}"; TMP="$GCI/tmp-clash"; _lib_clashes ) > "$GCI/clash.out" 2>"$GCI/clash.err"
  while IFS=$'\t' read -r _gci_cn _gci_cf _gci_cw || [ -n "$_gci_cn" ]; do
    _gci_cf="$(printf '%s\n' "$_gci_cf" | _gci_canon)"
    case "$_gci_cw" in */*) _gci_cw="$(printf '%s\n' "$_gci_cw" | _gci_canon)" ;; esac
    printf '%s\t%s\t%s\n' "$_gci_cn" "$_gci_cf" "$_gci_cw" >> "$GCI/clash.norm"
  done < "$GCI/clash.out"
fi
_gci_cline() {   # <NAME> <lib file, physical> <WHAT, physical when a path; - for any>: 0 when _lib_clashes printed it
  LC_ALL=C awk -F'\t' -v n="$1" -v f="$2" -v w="$3" '$1 == n && $2 == f && (w == "-" || $3 == w) { hit = 1 } END { exit !hit }' "$GCI/clash.norm"
}
_gci_cwhy() { printf '%s line(s) printed, the first [%s]%s' "$(LC_ALL=C awk 'END { print NR }' "$GCI/clash.out")" "$(head -3 "$GCI/clash.out" | LC_ALL=C tr '\n\t' '  ')" "$GCI_LBN"; }
_gci_named() {   # <assertion name> <NAME> <case> <WHAT: a literal, a path, or ->
  if ! declare -F _lib_clashes >/dev/null; then bad "$1" "_lib_clashes: $GCI_NO"
  elif _gci_cline "$2" "$GCI_CL/zz-gci-x-$3.sh" "$4"; then ok "$1"
  else bad "$1" "no line [$2 | lib/zz-gci-x-$3.sh | $4]: $(_gci_cwhy)"; fi
}
# <assertion name> <case>: _lib_runs_nothing returns 1 for the copy's planted
# file with one line naming it, and _lib_clashes printed no line for it.
_gci_varcase() {
  local f="zz-gci-x-$2.sh" v=""
  if ! declare -F _lib_runs_nothing >/dev/null; then v="_lib_runs_nothing: $GCI_NO; "
  else
    _gci_judge "$GCI_T/lib/$f" "$GCI/lrn.out.$f"
    v="$_gci_rc|$(LC_ALL=C awk 'END { print NR }' "$GCI/lrn.out.$f") line(s)|"
    if LC_ALL=C grep -qF -e "$f" "$GCI/lrn.out.$f"; then v="${v}names the file"; else v="${v}does not name the file"; fi
    if [ "$v" = "1|1 line(s)|names the file" ]; then v=""
    else v="_lib_runs_nothing: [$v], wanted [1|1 line(s)|names the file], and said [$(head -3 "$GCI/lrn.out.$f" | LC_ALL=C tr '\n' ' ')]; "; fi
  fi
  if ! declare -F _lib_clashes >/dev/null; then v="${v}_lib_clashes: $GCI_NO"
  elif LC_ALL=C awk -F'\t' -v f="$GCI_CL/$f" '$2 == f { hit = 1 } END { exit !hit }' "$GCI/clash.norm"; then
    v="${v}_lib_clashes named it: [$(LC_ALL=C grep -F -e "$f" "$GCI/clash.out" | head -3 | LC_ALL=C tr '\n\t' '  ')]"
  fi
  if [ -z "$v" ]; then ok "$1"; else bad "$1" "$v"; fi
}
_gci_named "_lib_clashes names a lib file that defines bad, a function the driver defines before the lib block" bad e01-bad -
_gci_varcase "_lib_runs_nothing returns 1 and prints one line naming the file, and _lib_clashes prints no line for it, for a lib file that sets FAIL, a counter the driver owns, by a plain literal assignment" e02-fail
_gci_varcase "_lib_runs_nothing returns 1 and prints one line naming the file, and _lib_clashes prints no line for it, for a lib file that sets PATH by a plain assignment, PATH being defined before the lib block" e11-path

# ---- (f): every real tests/lib/*.sh
_gci_k=0; _gci_names=""; _gci_failed=""
for _gci_f in "$HERE"/lib/*.sh; do
  [ -f "$_gci_f" ] || continue
  _gci_k=$((_gci_k + 1)); _gci_names="$_gci_names ${_gci_f##*/}"
  declare -F _lib_runs_nothing >/dev/null || continue
  ( FELIX_TEST_RAN="$GCI/lrn-ran"; _lib_runs_nothing "$_gci_f" ) > "$GCI/lrn.real" 2>&1 \
    || _gci_failed="$_gci_failed [${_gci_f##*/}: $(head -1 "$GCI/lrn.real")]"
done
_gci_n="every tests/lib/*.sh in this tree defines functions and nothing else when sourced, as _lib_runs_nothing judges it"
if [ "$_gci_k" -eq 0 ]; then
  skip "$_gci_n" "tests/lib holds no *.sh on this branch yet: 0 files to judge"
elif ! declare -F _lib_runs_nothing >/dev/null; then
  bad "$_gci_n" "$_gci_k lib file(s), and _lib_runs_nothing: $GCI_NO"
elif [ -n "$_gci_failed" ]; then
  bad "$_gci_n" "of $_gci_k lib file(s), these ran something:$_gci_failed"
else
  ok "$_gci_n"
  printf '        %s lib file(s) judged:%s\n' "$_gci_k" "$_gci_names"
fi

# ---- (g): _lib_clashes, on the real tree and on the copy planted above
_gci_n="_lib_clashes prints nothing for the real tree"
if ! declare -F _lib_clashes >/dev/null; then bad "$_gci_n" "_lib_clashes: $GCI_NO"
else
  ( _lib_clashes ) > "$GCI/clash.real" 2>&1
  if [ -s "$GCI/clash.real" ]; then
    bad "$_gci_n" "it printed $(LC_ALL=C awk 'END { print NR }' "$GCI/clash.real") line(s), the first [$(head -3 "$GCI/clash.real" | LC_ALL=C tr '\n\t' '  ')]"
  else ok "$_gci_n"; fi
fi
GCI_BEFORE="defined before the lib block"
_gci_named "_lib_clashes, pointed at a copy of the tree, prints bad, the lib file and defined before the lib block, for a lib file that defines bad among other functions" \
    bad g1-bad "$GCI_BEFORE"
_gci_varcase "_lib_runs_nothing returns 1 and prints one line naming the file, and _lib_clashes, pointed at a copy of the tree, prints no line for it, for a lib file that sets FAIL among other plain assignments" \
    g2-fail
_gci_varcase "_lib_runs_nothing returns 1 and prints one line naming the file, and _lib_clashes, pointed at a copy of the tree, prints no line for it, for a lib file that sets IFS" \
    g3-ifs
_gci_named "_lib_clashes, pointed at a copy of the tree, prints the function, the lib file and the part's path, for a lib file that defines a function part 1290 defines" \
    _gci_lib_lines g4-part-fn "$GCI_CP/1290-gate-friction-c-blind.sh"
_gci_n="_lib_clashes, pointed at a copy of the tree, prints the function, one lib file and the other's path, for two lib files that define the same function"
if ! declare -F _lib_clashes >/dev/null; then bad "$_gci_n" "_lib_clashes: $GCI_NO"
elif _gci_cline "$GCI_FN" "$GCI_CL/zz-gci-x-g5-twin-a.sh" "$GCI_CL/zz-gci-x-g5-twin-b.sh" \
  || _gci_cline "$GCI_FN" "$GCI_CL/zz-gci-x-g5-twin-b.sh" "$GCI_CL/zz-gci-x-g5-twin-a.sh"; then ok "$_gci_n"
else bad "$_gci_n" "no line [$GCI_FN | one twin | the other]: $(_gci_cwhy)"; fi
_gci_n="_lib_clashes, pointed at a copy of the tree, does not name a lib file that sets a variable a later part also sets"
if ! declare -F _lib_clashes >/dev/null; then bad "$_gci_n" "_lib_clashes: $GCI_NO"
elif LC_ALL=C awk -F'\t' -v f="$GCI_CL/zz-gci-x-g6-later-var.sh" '$2 == f { hit = 1 } END { exit !hit }' "$GCI/clash.norm"; then
  bad "$_gci_n" "it named lib/zz-gci-x-g6-later-var.sh: [$(LC_ALL=C grep -F -e zz-gci-x-g6 "$GCI/clash.out" | head -3 | LC_ALL=C tr '\n\t' '  ')]"
else ok "$_gci_n"; fi

# ---- (g), third round
_gci_refuses_c() {   # <assertion name> <case>: _gci_refuses on the copy's planted lib file
  local f="zz-gci-x-$2.sh" v
  if ! declare -F _lib_runs_nothing >/dev/null; then bad "$1" "_lib_runs_nothing: $GCI_NO"; return 0; fi
  _gci_judge "$GCI_T/lib/$f" "$GCI/lrn.out.$f"
  v="$_gci_rc|$(LC_ALL=C awk 'END { print NR }' "$GCI/lrn.out.$f") line(s)|"
  if LC_ALL=C grep -qF -e "$f" "$GCI/lrn.out.$f"; then v="${v}names the file"; else v="${v}does not name the file"; fi
  if [ "$v" = "1|1 line(s)|names the file" ]; then ok "$1"
  else bad "$1" "status|lines|naming: [$v], wanted [1|1 line(s)|names the file]; it said [$(head -3 "$GCI/lrn.out.$f" | LC_ALL=C tr '\n' ' ')]"; fi
}
# Amended after the third round's build and review (2026-10-16): on bash 3.2 a
# brace group that holds only a definition fires no DEBUG trap, so it runs
# nothing and meets C2's rule; the one harm in it, taking the name bad, is the
# _lib_clashes assertion below.
_gci_n="_lib_runs_nothing returns 0 for a lib file that defines bad inside a brace group, which runs no command (the name is _lib_clashes' to refuse)"
if ! declare -F _lib_runs_nothing >/dev/null; then bad "$_gci_n" "_lib_runs_nothing: $GCI_NO"
else _gci_judge "$GCI_T/lib/zz-gci-x-e03-brace-bad.sh" "$GCI/lrn.out.e03-pass"; is "$_gci_n" "$_gci_rc" "0"; fi
_gci_named "_lib_clashes, pointed at a copy of the tree, prints bad, the lib file and defined before the lib block, for a lib file that defines bad inside a brace group" \
    bad e03-brace-bad "$GCI_BEFORE"
_gci_named "_lib_clashes, pointed at a copy of the tree, prints [, the lib file and a builtin, for a lib file that defines a function named [" \
    '[' b1-bracket "a builtin"
_gci_named "_lib_clashes, pointed at a copy of the tree, prints ., the lib file and a builtin, for a lib file that defines a function named ." \
    '.' b2-dot "a builtin"
_gci_named "_lib_clashes, pointed at a copy of the tree, prints printf, the lib file and a builtin, for a lib file that defines a function named printf" \
    printf b3-printf "a builtin"
GCI_GIT="$(type -P git 2>/dev/null)"
[ -n "$GCI_GIT" ] && GCI_GIT="$(printf '%s\n' "$GCI_GIT" | _gci_canon)"
_gci_named "_lib_clashes, pointed at a copy of the tree, prints git, the lib file and the path of git on PATH, for a lib file that defines a function named git" \
    git b4-git "${GCI_GIT:-(no git on PATH here)}"
_gci_both() {   # <assertion name> <case>: _lib_runs_nothing returns 0 for the copy's planted file, and _lib_clashes printed no line naming it
  local f="zz-gci-x-$2.sh" v=""
  if ! declare -F _lib_runs_nothing >/dev/null; then v="_lib_runs_nothing: $GCI_NO; "
  else
    _gci_judge "$GCI_T/lib/$f" "$GCI/lrn.out.$f"
    [ "$_gci_rc" -eq 0 ] || v="_lib_runs_nothing returned $_gci_rc and said [$(head -3 "$GCI/lrn.out.$f" | LC_ALL=C tr '\n' ' ')]; "
  fi
  if ! declare -F _lib_clashes >/dev/null; then v="${v}_lib_clashes: $GCI_NO"
  elif LC_ALL=C awk -F'\t' -v f="$GCI_CL/$f" '$2 == f || $3 == f { hit = 1 } END { exit !hit }' "$GCI/clash.norm"; then
    v="${v}_lib_clashes named it: [$(LC_ALL=C grep -F -e "$f" "$GCI/clash.out" | head -3 | LC_ALL=C tr '\n\t' '  ')]"
  fi
  if [ -z "$v" ]; then ok "$1"; else bad "$1" "$v"; fi
}
_gci_both "_lib_runs_nothing returns 0 and _lib_clashes prints no line for a lib file of function definitions only, with comments and blank lines" p4-defs
_gci_both "_lib_runs_nothing returns 0 and _lib_clashes prints no line for a lib file whose one function's body sets variables, calls commands and writes files" p5-body
# Conditions 2 to 5, each alone: every case above that is refused runs a
# command, so without these a judge that dropped its check of printed output,
# of the scratch directory, of the variable set or its time limit would pass.
# From the third review's probes (2026-10-16).
_gci_put gci-lrn-c2-parse.sh 'zgci_c2() { :; '
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that does not parse, so sourcing it only prints an error" gci-lrn-c2-parse.sh
_gci_put gci-lrn-c3-redir.sh '{ zgci_c3() { :; }; } > zz-gci-c3-out'
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file whose brace group of definitions writes a file through a redirect" gci-lrn-c3-redir.sh
_gci_put gci-lrn-c4-var.sh '{ zgci_c4() { :; }; } > "${ZGCI_C4:=/dev/null}"'
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file whose brace group of definitions sets a variable in its redirect" gci-lrn-c4-var.sh
_gci_put gci-lrn-c5-spin.sh 'while { zgci_c5() { :; }; }; do zgci_c5b() { :; }; done'
_gci_refuses "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that loops without running a command, ended by the time limit (1 s here)" gci-lrn-c5-spin.sh _lrn_limit=1

# ---- (h): the driver writes lib-before.names at the start of its lib block
_gci_o="$(LC_ALL=C awk '
  $0 == ". \"$HERE/parts/0005-fixture-floor.sh\"" { n5++; at5 = FNR }
  $0 == ". \"$HERE/parts/0010-resolution.sh\"" { n10++; at10 = FNR }
  /^\. "\$HERE\/lib\/[^"]*"$/ && !lib1 { lib1 = FNR }
  /lib-before\.names/ && !/^[ \t]*#/ { nw++; atw = FNR }
  END {
    if (n5 != 1 || n10 != 1) { print "the driver has " (n5 + 0) " lines sourcing part 0005 and " (n10 + 0) " sourcing part 0010, not one each"; exit 1 }
    if (nw != 1) { print "the driver has " (nw + 0) " lines outside a comment naming lib-before.names, not one"; exit 1 }
    lim = lib1 ? lib1 : at10; what = lib1 ? "its first lib line" : "the 0010 line, there being no lib line"
    if (atw <= at5 || atw >= lim) { print "it is line " atw ", and must come after line " at5 ", the 0005 line, and before line " lim ", " what; exit 1 }
  }' "$HERE/run")"; _gci_rc=$?
_gci_n="the driver's one line writing lib-before.names under TMP sits after the line sourcing part 0005 and before its first lib line, or before the 0010 line when it has none"
if [ "$_gci_rc" -eq 0 ]; then ok "$_gci_n"; else bad "$_gci_n" "$_gci_o"; fi
_gci_n="lib-before.names exists under TMP in this run"
if [ -f "$TMP/lib-before.names" ]; then ok "$_gci_n"; else bad "$_gci_n" "there is no $TMP/lib-before.names"; fi
_gci_v=""
for _gci_x in PASS FAIL bad TMP; do
  LC_ALL=C grep -qxF -e "$_gci_x" "$TMP/lib-before.names" 2>/dev/null || _gci_v="$_gci_v $_gci_x"
done
_gci_n="lib-before.names under TMP names PASS, FAIL, bad and TMP, each on a line of its own"
if [ -z "$_gci_v" ]; then ok "$_gci_n"; else bad "$_gci_n" "it has no line for:$_gci_v"; fi
_gci_n="lib-before.names under TMP is in LC_ALL=C order"
if [ ! -f "$TMP/lib-before.names" ]; then bad "$_gci_n" "there is no $TMP/lib-before.names"
elif _gci_o="$(LC_ALL=C sort -c "$TMP/lib-before.names" 2>&1)"; then ok "$_gci_n"
else bad "$_gci_n" "sort -c says [$(printf '%s\n' "$_gci_o" | head -2 | LC_ALL=C tr '\n' ' ')]"; fi
_gci_p6=""; for _gci_f in "$HERE"/parts/0006-*.sh; do [ -f "$_gci_f" ] && _gci_p6="$_gci_f"; done
_gci_v=""
for _gci_x in _lib_runs_nothing _lib_clashes; do
  if [ -z "$_gci_p6" ]; then _gci_v="$_gci_v $_gci_x (there is no part 0006)"
  elif ! LC_ALL=C awk -v n="$_gci_x" '$0 ~ ("^" n "[ \t]*\\(\\)") || $0 ~ ("^function[ \t]+" n "([ \t({]|$)") { hit = 1 } END { exit !hit }' "$_gci_p6"; then
    _gci_v="$_gci_v $_gci_x (no line of ${_gci_p6##*/} defines it)"
  elif ! LC_ALL=C grep -qxF -e "$_gci_x" "$TMP/lib-before.names" 2>/dev/null; then
    _gci_v="$_gci_v $_gci_x (not in lib-before.names)"
  fi
done
_gci_n="lib-before.names under TMP names _lib_runs_nothing and _lib_clashes, the judges part 0006 defines, so a lib file that takes either name is a clash"
if [ -z "$_gci_v" ]; then ok "$_gci_n"; else bad "$_gci_n" "for:$_gci_v"; fi
# <<< gate-friction-c-blind
