# >>> evidence-readers-agree
printf '\nthe evidence readers agree with the judge: a path that stands and is no table is not judged, never absent (contract 2026-11-05, blind)\n'
# Blind, written on 2026-11-05 from docs/2026-11-05-evidence-readers-agree-contract.md alone. No engine code was
# read: felix, lib/, hooks/, templates/ and the project gates were not opened. Every command is driven as a black
# box, lib/evidence.sh is sourced in subshells to call its functions, and D3 greps the engine's tracked text for a
# pattern as its target. Each assertion is named by its contract number and the behaviour, and every name is
# emitted on every run; a state that cannot be built skips its names and says why. The controls (C1 to C6, each
# "R armed", "A4 armed", "D2 armed", "D3 armed" and the control halves of A5) hold before the fix; D1, D2, D3, A1 to
# A4 and the state halves of A5 fail on the tree the contract was cut from.
#
# Readings, where the contract leaves room:
# - Each state's change is written in the widget checkout and committed by _stage, and undone by _reset, as 1830
#   F2 does; every file it writes holds a line no earlier commit held. The base is refs/heads/era-base, a branch at
#   HEAD~1, the commit the change was cut from, made before the readers run and removed after. felix incident
#   reads a trace, not a diff, so it takes no base; the trace names src/thing.js, which a commit of this part's
#   own puts in the checkout first and which is undone at the end.
# - The green change touches README.md only (the shipped risk table's documentation row, green). C2 and C4's
#   change touches src/a.ts, which the rule code (^src/, wants ^tests/) reaches and does not meet.
# - felix merge --dry-run runs over a green gate receipt and a fresh commission receipt (1830 A21), and only the
#   lines whose first word is evidence are read.
# - "not judged" in felix receipt is read as evidence listed under unknown, as the contract's Words say the
#   receipt marks the reference case; its JSON never carries the words, the reference case C5 included.
# - A5's "the three controls" are read as C1, C3 and C5: the controls whose change is green, so that felix
#   classify on a green change can be read in them. C2 and C4's merge lists a gap as an evidence blocker with no
#   "not judged", which A5's agreement is not about.
# - C1's clause that felix_evidence_table_present exits 1 cannot hold before the fix, since the function does not
#   exist there; it is asserted as D1's case for the widget project in C1's state, and fails red with D1.
# - A1's "a [?] row" is exactly one row; "a line saying 1 row not judged" and A2's "1 evidence row was not judged"
#   are the reference case's own words, 1 row(s) not judged and 1 evidence row(s) not judged, as C5 shows them.
#   A4's section is its heading's following lines up to the first blank line, a row's name first on each; "one
#   row named evidence.tsv" is one of them whose first word is evidence.tsv and whose reason holds cannot be read
#   and not judged.
# - C6's file holds C2's table at mode 000 and its change is green; it skips where a mode-000 file is still
#   readable (root).
# - D1 runs on project directories of its own. Every call runs in the background under a 30 s watchdog, so a
#   function that opens the FIFO fails D1 instead of hanging the suite; "it reads no file" is asserted by the FIFO.
#   "Prints nothing" is read on stdout and stderr together.
# - D2 drives the judge through felix_evidence_check PROJ BASE REPO, which runs it (1830 F1), in a repository of
#   its own; "prints nothing" is read on stdout.
# - D3's "tests evidence.tsv" is a line where [, [[ or test is followed by -f, -e, -L, -s, -r or -d (since
#   amendment 5, any unary file operator), an optional
#   ! between, and an operand word that holds evidence.tsv. The files are what git ls-files lists under felix and
#   lib/ in the checkout the suite runs from. "Every reader asks felix_evidence_table_present" is read as the
#   consequence of the first sentence, shown by A1 to A4 and D2, not as a second grep.
#
# Arming: a negative assertion here never stands alone. A1, A2 and A3's "does not print" and "no gap" clauses
# share one assertion with their positive claim on the same output; each state of R has an "R armed" assertion
# that the path was built and felix merge --dry-run lists the not-judged row, so the judge saw the state. C1's
# "no evidence line" and "no unknown" are paired with C2 and C5, which list them over the same base and fixture;
# C3's are paired with C2 and share their assertions with "No evidence gaps" and "no evidence is owed". A4 is
# paired with "A4 armed": the same trace reaches the section in C5's state. D2's "prints nothing" is paired with
# "D2 armed": as shipped, the same checks print the gap and the met row. D3 is paired with "D3 armed": the pattern
# finds each form in a planted text, and the file list holds felix and lib/evidence.sh.
#
# Every part runs alone: this one makes the widget checkout's first commit with _widget_repo_build, moves aside
# whatever stands at the widget's evidence.tsv and puts it back at the end, leaves nothing it made at that path,
# and makes every other fixture under $TMP/era.
#
# The amendments of 2026-11-06, written blind on that day from the amended contract alone, the same way:
# - Amendment 1: R's fourth state is a FIFO made by mkfifo; R armed and A1 to A5 are run for it as for the other
#   three. Every command over the widget (each reader, and the gate and commission receipts before them) and every
#   D1 call runs under _era_wd's watchdog, whatever the state: at its deadline (60 s a reader, 30 s a D1 call)
#   every process in the command's tree is stopped and then killed, the shell and its children alike, and the
#   FIFO is opened read-write for a moment and closed unread, so an opener that left the tree is released before
#   the path is removed. The release also runs after every command over a FIFO that returned. The part never
#   reads the FIFO. A command the watchdog ended fails its assertions with a line saying so, and R armed also
#   names it: "none of these may hang" is read as part of the arming, which never fires for the other states.
#   The watchdog is armed itself by "R armed (FIFO, the watchdog, control)", on FIFOs of its own: a command whose
#   child blocks opening one is ended with that child, and an opener with no parent left is released.
# - Amendment 2: "prints its implicated files" is read as felix incident's output naming src/thing.js, the file
#   the trace names; the heading is the same "the fix will have to prove" A4 reads.
# - Amendment 3: felix next runs with --base, PATH and HOME as 1830 A25 runs it. "A row saying an evidence row
#   cannot be judged, naming evidence.tsv" is a line of its output that names evidence.tsv and holds "not judged"
#   or "cannot be judged". A5's extension reads "that row" as a line saying an evidence row was not judged (or
#   cannot be), whichever row it names, so that C5's row, named unit, is the yes the reference case owes; it is
#   one assertion a state, over R, C1, C3 and C5, named "A5 agreement, felix next". Since 2026-11-14 the PATH is
#   A25's /usr/bin:/bin behind $ERA/git, a directory holding only the git every other reader here runs; why is
#   above _era_read.
# - Amendment 4: felix brief reads, on stdin, an issue naming src/thing.js, as 1830 A33 drives it. Its section is
#   the lines after the heading "what a fix must prove" up to the first blank line, as A4 reads incident's. C1's
#   "no such section" is paired with the brief naming src/thing.js. A5's extension is "not judged" in that
#   section, over R, C1, C3 and C5, named "A5 agreement, felix brief".
# - Amendment 5: D3's operators are bash's unary file tests, -a -b -c -d -e -f -g -h -k -p -r -s -t -u -w -x -G -L
#   -N -O -S; the armed control plants -p and -h beside the six, and a string test (-z) it must not find. The
#   two D3 names are widened to say so.
# - Amendment 6: D4 runs bash -c in a subshell, sourcing lib/resolve.sh and then lib/receipt.sh and nothing else,
#   and calls felix_receipt PROJECT BASE CHECKOUT HOME as 0370 calls it, over the same base the CLI reads. (a)
#   runs in C1 and in C2 (a readable table whose rule the change does not meet); "prints nothing on stderr" is
#   paired with its stdout being a receipt, JSON. (a) asks nothing of the receipt's evidence: on the tree this was
#   written against, the receipt sourced alone lists no gap in C2 where felix receipt lists code, and the contract
#   does not say it must. (b) runs in R's directory state.

ERA="$TMP/era"; mkdir -p "$ERA"
_widget_repo_build
_era_wp="$FROOT/projects/widget"; _era_ev="$_era_wp/evidence.tsv"
_era_kept=""
if [ -e "$_era_ev" ] || [ -L "$_era_ev" ]; then mv "$_era_ev" "$ERA/evidence.keep" && _era_kept=1; fi
_era_T="$(printf 'code\t^src/\t^tests/\tbehaviour needs a test')"
_era_T3="$(printf 'unit\t^src/\t^tests/')"
_era_trace="$(printf 'Error: boom\n    at run (/home/runner/work/x/x/src/thing.js:44:9)')"
_era_k=0; _era_why=""; ERA_CH=""

# NAME GOT WANT [TEXT]: is, with TEXT shown on a failure; a skip by NAME while _era_why says why it cannot run.
_era_is() {
  if [ -n "$_era_why" ]; then skip "$1" "$_era_why"
  elif [ "$2" = "$3" ]; then ok "$1"
  else bad "$1" "expected [$3] got [$2]${4:+ in [$4]}"; fi
}
# NAME TEXT +PHRASE|-PHRASE...: one assertion that TEXT holds every +PHRASE and no -PHRASE.
_era_hl() {
  local n="$1" t="$2" p miss=""
  shift 2
  for p in "$@"; do
    case "$p" in
      +*) case "$t" in *"${p#+}"*) ;; *) miss="$miss lacks [${p#+}];" ;; esac ;;
      -*) case "$t" in *"${p#-}"*) miss="$miss holds [${p#-}];" ;; esac ;;
    esac
  done
  if [ -n "$_era_why" ]; then skip "$n" "$_era_why"
  elif [ -z "$miss" ]; then ok "$n"; else bad "$n" "it$miss in [$t]"; fi
}
# TEXT AWK-CONDITION: how many non-empty lines of TEXT meet the condition, fields split on blanks.
_era_c() { printf '%s\n' "$1" | LC_ALL=C awk 'NF && ('"$2"') { n++ } END { print n + 0 }'; }

# The watchdog (amendment 1, and the fixtures' FIFO bullet). PID: PID and every process under it, parents first.
_era_tree() { local c; printf '%s\n' "$1"; for c in $(pgrep -P "$1" 2>/dev/null); do _era_tree "$c"; done; }
# PATH: when PATH is a FIFO, it is held open read-write for a fifth of a second and closed without a read or a
# write, which releases any process blocked opening it (an open for reading or for writing returns once both
# ends are held; the hold gives a woken opener the time to see them before they close).
_era_release() {
  if [ -p "$1" ] && [ ! -L "$1" ]; then ( exec 3<>"$1"; sleep 0.2 ) </dev/null >/dev/null 2>&1; fi
  return 0
}
# FIFO SECS MODE IN CMD...: CMD in a background subshell, stdin from IN, its stdout in $ERA/w.out (MODE both: with
# its stderr; MODE split: its stderr in $ERA/w.err) and its status in $ERA/w.rc. 0 when it returned, 1 when the
# watchdog ended it at SECS seconds: every process in its tree stopped, then killed, the shell and its children
# alike, and FIFO released, so no opener blocked in it outlives the call. FIFO is released after a return too.
_era_wd() {
  local f="$1" s="$2" m="$3" in="$4" j i=0 p
  shift 4
  rm -f "$ERA/w.out" "$ERA/w.err" "$ERA/w.rc"
  if [ "$m" = split ]; then
    ( "$@" < "$in" > "$ERA/w.out" 2> "$ERA/w.err"; printf '%s\n' "$?" > "$ERA/w.rc" ) </dev/null >/dev/null 2>&1 &
  else
    ( "$@" < "$in" > "$ERA/w.out" 2>&1; printf '%s\n' "$?" > "$ERA/w.rc" ) </dev/null >/dev/null 2>&1 &
  fi
  j=$!
  while [ ! -s "$ERA/w.rc" ] && kill -0 "$j" 2>/dev/null && [ "$i" -lt $((s * 10)) ]; do sleep 0.1; i=$((i + 1)); done
  if [ ! -s "$ERA/w.rc" ] && kill -0 "$j" 2>/dev/null; then
    # The group's stderr also takes the shell's own notice that the job was killed.
    { kill -STOP "$j"
      for p in $(_era_tree "$j"); do kill -STOP "$p"; done
      for p in $(_era_tree "$j"); do kill -KILL "$p"; done
      _era_release "$f"
      wait "$j"; } 2>/dev/null
    return 1
  fi
  wait "$j" 2>/dev/null
  _era_release "$f"
  return 0
}

# ---- D1: felix_evidence_table_present -----------------------------------------------------------------------
printf '\n  felix_evidence_table_present says whether anything stands at PROJ/evidence.tsv, and reads nothing (D1)\n'
# PROJ: felix_evidence_table_present PROJ after lib/resolve.sh and lib/evidence.sh, whose own output is dropped.
_era_tpc() {
  { . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/evidence.sh"; } </dev/null >/dev/null 2>&1
  felix_evidence_table_present "$1"
}
# PROJ: _era_tpc PROJ under a 30 s watchdog over PROJ/evidence.tsv, as rc=N out=[its stdout and stderr], or a
# phrase saying it did not return.
_era_tp() {
  if ! _era_wd "$1/evidence.tsv" 30 both /dev/null _era_tpc "$1"; then printf 'did not return within 30 s'
  elif [ ! -s "$ERA/w.rc" ]; then printf 'ended before it wrote a status'
  else printf 'rc=%s out=[%s]' "$(cat "$ERA/w.rc")" "$(cat "$ERA/w.out")"; fi
}
# KIND: $ERA/d1-KIND, a project directory whose evidence.tsv is KIND; _era_why empty when it was built.
_era_d1() {
  local d="$ERA/d1-$1" p="$ERA/d1-$1/evidence.tsv"
  mkdir -p "$d"; _era_why="evidence.tsv could not be made $1 here"
  case "$1" in
    file)     printf '%s\n' "$_era_T" > "$p"; [ -f "$p" ] && [ ! -L "$p" ] && _era_why="" ;;
    dir)      mkdir -p "$p"; [ -d "$p" ] && [ ! -L "$p" ] && _era_why="" ;;
    link)     printf '%s\n' "$_era_T" > "$ERA/d1-target.tsv"; ln -s "$ERA/d1-target.tsv" "$p"
              [ -L "$p" ] && [ -f "$p" ] && _era_why="" ;;
    linkdir)  mkdir -p "$ERA/d1-target-dir"; ln -s "$ERA/d1-target-dir" "$p"; [ -L "$p" ] && [ -d "$p" ] && _era_why="" ;;
    dangling) ln -s "$ERA/d1-no-such-name-anywhere" "$p"; [ -L "$p" ] && [ ! -e "$p" ] && _era_why="" ;;
    fifo)     mkfifo "$p" 2>/dev/null; [ -p "$p" ] && [ ! -L "$p" ] && _era_why="" ;;
    none)     [ -e "$p" ] || [ -L "$p" ] || _era_why="" ;;
  esac
  return 0
}
for _era_x in "file|a regular file" "dir|a directory" "link|a link that resolves to a file" \
              "linkdir|a link that resolves to a directory" "dangling|a dangling link"; do
  _era_d1 "${_era_x%%|*}"
  _era_is "D1 felix_evidence_table_present (${_era_x#*|}): exits 0 and prints nothing" \
          "$(_era_tp "$ERA/d1-${_era_x%%|*}")" "rc=0 out=[]"
done
_era_d1 fifo
_era_is "D1 felix_evidence_table_present (a FIFO): exits 0, prints nothing, and returns without reading it" \
        "$(_era_tp "$ERA/d1-fifo")" "rc=0 out=[]"
_era_release "$ERA/d1-fifo/evidence.tsv"; rm -f "$ERA/d1-fifo/evidence.tsv"
_era_d1 none
_era_is "D1 felix_evidence_table_present (nothing at the path): exits 1 and prints nothing" \
        "$(_era_tp "$ERA/d1-none")" "rc=1 out=[]"
_era_why=""

# ---- D2: the judge asks that function and nothing else ----------------------------------------------------
printf '\n  the judge asks felix_evidence_table_present whether to say anything (D2)\n'
# NAME PATH...: a fresh repository $ERA/NAME, main holding README, work one commit on top adding each PATH.
_era_g() {
  local d="$ERA/$1" p
  shift
  mkdir -p "$d"; printf 'a readme\n' > "$d/README"
  ( _fx_cd "$d" && git init -q -b main && git add -A && git -c user.name=t -c user.email=t@t commit -qm main \
    && git checkout -q -b work ) >/dev/null 2>&1
  for p in "$@"; do mkdir -p "$(dirname "$d/$p")"; printf 'x\n' > "$d/$p"; done
  ( _fx_cd "$d" && git add -A && git -c user.name=t -c user.email=t@t commit -qm work ) >/dev/null 2>&1
}
# MODE PROJ REPO: felix_evidence_check PROJ main REPO, its stdout; MODE 0 or 1 replaces felix_evidence_table_present,
# after lib/evidence.sh is sourced and inside this subshell only, by one that always exits MODE; MODE - leaves it.
_era_chk() {
  ( cd "$3" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/evidence.sh"
    case "$1" in
      0) felix_evidence_table_present() { return 0; } ;;
      1) felix_evidence_table_present() { return 1; } ;;
    esac
    felix_evidence_check "$2" main "$3" ) </dev/null 2>/dev/null
}
_era_g d2-unmet src/a.ts; _era_g d2-met src/a.ts tests/a_test.py
_era_GU="$(cd "$ERA/d2-unmet" && pwd -P)"; _era_GM="$(cd "$ERA/d2-met" && pwd -P)"
mkdir -p "$ERA/d2-p" "$ERA/d2-p0"; printf '%s\n' "$_era_T" > "$ERA/d2-p/evidence.tsv"
_era_is "D2 armed (control): as shipped, the check prints the gap row for the unmet change, the met row for the met one, and nothing for a project with no evidence.tsv" \
        "$(_era_chk - "$ERA/d2-p" "$_era_GU" | cut -f1,2)|$(_era_chk - "$ERA/d2-p" "$_era_GM" | cut -f1,2)|[$(_era_chk - "$ERA/d2-p0" "$_era_GU")]" \
        "$(printf 'gap\tcode|met\tcode|[]')"
_era_is "D2 the judge, felix_evidence_table_present replaced by one that always exits 1: prints nothing for a readable table whose rule is unmet" \
        "$(_era_chk 1 "$ERA/d2-p" "$_era_GU")" ""
_era_is "D2 the judge, felix_evidence_table_present replaced by one that always exits 1: prints nothing for a readable table whose rule is met" \
        "$(_era_chk 1 "$ERA/d2-p" "$_era_GM")" ""
_era_v="$(_era_chk 0 "$ERA/d2-p0" "$_era_GU")"
_era_is "D2 the judge, felix_evidence_table_present replaced by one that always exits 0: prints the not-judged row, unknown evidence.tsv cannot be read not judged, for a project with no evidence.tsv" \
        "lines $(printf '%s' "$_era_v" | awk 'END { print NR }'), row $(printf '%s\n' "$_era_v" | LC_ALL=C awk -F'\t' 'NR == 1 { printf "%s %s %s %s", $1, $2, (index($3, "cannot be read") ? "cannot-be-read" : "-"), (index($3, "not judged") ? "not-judged" : "-") }')" \
        "lines 1, row unknown evidence.tsv cannot-be-read not-judged" "$_era_v"

# ---- D3: no second copy of the question --------------------------------------------------------------------
printf '\n  no engine file but lib/evidence.sh asks its own file test of evidence.tsv (D3)\n'
# Every unary file operator a [, [[ or test takes in bash (amendment 5): -a -b -c -d -e -f -g -h -k -p -r -s -t -u -w
# -x -G -L -N -O -S. The string tests (-z, -n), -o and -v are not file tests.
_era_re='(\[\[?|test)[[:space:]]+(![[:space:]]+)?-[abcdefghkprstuwxGLNOS][[:space:]]+[^[:space:]]*evidence\.tsv'
_era_fl="$(cd "$REAL_HARNESS" 2>/dev/null && git ls-files -- felix lib 2>/dev/null)"
{ printf '%s\n' '[ -f "$p/evidence.tsv" ] || exit 1'
  printf '%s\n' 'if [ ! -e "$d/evidence.tsv" ] && [ ! -L "$d/evidence.tsv" ]; then :; fi'
  printf '%s\n' '[[ -s $pd/evidence.tsv ]] && echo y'
  printf '%s\n' 'test -r "$x/evidence.tsv" || :'
  printf '%s\n' '[ -d "${p}/evidence.tsv" ] && :'
  printf '%s\n' 'felix_evidence_table_present "$p" || exit 1'
  printf '%s\n' "printf 'declares no evidence.tsv\\n'"
  printf '%s\n' 'if [[ ! -p $p/evidence.tsv ]]; then :; fi'
  printf '%s\n' 'test -h "$p/evidence.tsv" && :'
  printf '%s\n' '[ -z "$p/evidence.tsv" ] && :'
} > "$ERA/d3-plant.txt"
_era_v="$(LC_ALL=C grep -nE "$_era_re" "$ERA/d3-plant.txt" 2>/dev/null | cut -d: -f1 | tr '\n' ' ')"
_era_a=no; _era_b=no
while IFS= read -r _era_x; do
  case "$_era_x" in felix) _era_a=yes ;; lib/evidence.sh) _era_b=yes ;; esac
done <<ERA_FILES_EOF
$_era_fl
ERA_FILES_EOF
_era_is "D3 armed (control): the pattern finds -f, -e, -L, -s, -r, -d and the unary file tests the six left out, -p and -h among them, on evidence.tsv under [, [[ and test in a planted text and nothing else there, not a string test, and git lists felix and lib/evidence.sh among the files read" \
        "lines $_era_v| felix $_era_a, lib/evidence.sh $_era_b" "lines 1 2 3 4 5 8 9 | felix yes, lib/evidence.sh yes"
_era_v=""
while IFS= read -r _era_x; do
  [ -n "$_era_x" ] && [ "$_era_x" != lib/evidence.sh ] && [ -f "$REAL_HARNESS/$_era_x" ] || continue
  _era_y="$(LC_ALL=C grep -nE "$_era_re" "$REAL_HARNESS/$_era_x" 2>/dev/null)"
  [ -z "$_era_y" ] || _era_v="$_era_v$(printf '%s\n' "$_era_y" | sed "s|^|$_era_x:|") / "
done <<ERA_FILES_EOF
$_era_fl
ERA_FILES_EOF
_era_is "D3 no tracked file under engine/harness/felix or engine/harness/lib/ but lib/evidence.sh tests evidence.tsv with any unary file operator (-a -b -c -d -e -f -g -h -k -p -r -s -t -u -w -x -G -L -N -O -S) under test, [[ or [" \
        "$_era_v" ""

# ---- the widget: the readers over each state ----------------------------------------------------------------
printf '\n  felix evidence, classify, receipt and incident read a path that stands and is no table as the judge does (A1 to A5, C1 to C6)\n'
_era_head() { ( _fx_cd "$REPO" && git rev-parse -q --verify HEAD ) 2>/dev/null; }
# PATH...: each written in $REPO with a line no earlier commit held, committed by _stage; 1 when HEAD did not move.
_era_ch() {
  local p h
  h="$(_era_head)"; _era_k=$((_era_k + 1))
  for p in "$@"; do mkdir -p "$(dirname "$REPO/$p")"; printf 'era change %s\n' "$_era_k" > "$REPO/$p"; done
  _stage
  [ -n "$(_era_head)" ] && [ "$(_era_head)" != "$h" ]
}
# nothing at the path: a file or a link goes with rm -f, a directory with rmdir; 1 when something still stands.
_era_clear() {
  rm -f "$_era_ev" 2>/dev/null; rmdir "$_era_ev" 2>/dev/null
  if [ -e "$_era_ev" ] || [ -L "$_era_ev" ]; then return 1; fi
  return 0
}
# KIND ROWS: the path made KIND from nothing (ROWS the rows of a table KIND writes); _era_why empty when it was.
_era_put() {
  _era_why="the widget's evidence.tsv could not be cleared"
  _era_clear || return 0
  _era_why="the widget's evidence.tsv could not be made $1 here"
  case "$1" in
    none)     _era_why="" ;;
    file)     printf '%s\n' "$2" > "$_era_ev"; [ -f "$_era_ev" ] && [ ! -L "$_era_ev" ] && [ -r "$_era_ev" ] && _era_why="" ;;
    linkfile) printf '%s\n' "$2" > "$ERA/c4-table.tsv"; ln -s "$ERA/c4-table.tsv" "$_era_ev"
              [ -L "$_era_ev" ] && [ -f "$_era_ev" ] && [ -r "$_era_ev" ] && _era_why="" ;;
    mode000)  printf '%s\n' "$2" > "$_era_ev"; chmod 000 "$_era_ev"
              if [ -r "$_era_ev" ]; then _era_why="a mode-000 file is still readable here (root)"
              elif [ -f "$_era_ev" ] && [ ! -L "$_era_ev" ]; then _era_why=""; fi ;;
    dir)      mkdir "$_era_ev"; [ -d "$_era_ev" ] && [ ! -L "$_era_ev" ] && _era_why="" ;;
    dangling) rm -f "$ERA/no-such-name-anywhere"; ln -s "$ERA/no-such-name-anywhere" "$_era_ev"
              [ -L "$_era_ev" ] && [ ! -e "$_era_ev" ] && _era_why="" ;;
    linkdir)  mkdir -p "$ERA/a-directory"; ln -s "$ERA/a-directory" "$_era_ev"
              [ -L "$_era_ev" ] && [ -d "$_era_ev" ] && _era_why="" ;;
    fifo)     mkfifo "$_era_ev" 2>/dev/null; [ -p "$_era_ev" ] && [ ! -L "$_era_ev" ] && _era_why="" ;;
  esac
  return 0
}
# JSON: four lines, yes or no for evidence under unknown, then unknown, evidence.gap and evidence.met as compact JSON.
_era_rj() {
  printf '%s' "$1" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print("not json\nnot json\nnot json\nnot json"); sys.exit(0)
u = d.get("unknown")
e = d.get("evidence") if isinstance(d.get("evidence"), dict) else {}
c = lambda o: json.dumps(o, separators=(",", ":"))
print("yes" if isinstance(u, list) and "evidence" in u else "no")
print(c(u)); print(c(e.get("gap"))); print(c(e.get("met")))' 2>&1
}
# N: line N of the receipt's _era_rj.
_era_rf() { printf '%s\n' "$ERA_RJ" | sed -n "${1}p"; }
# CMD...: CMD run in the widget checkout.
_era_in() { cd "$REPO" && "$@"; }
# The gate and commission receipts for the tree at HEAD: a green gate receipt and a fresh commission receipt.
_era_prep() {
  ( . "$FROOT/harness/lib/verify.sh"
    felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" >/dev/null 2>&1 )
  _cm_stamp
}
# WHAT MODE IN CMD...: CMD in the widget checkout under the watchdog over the widget's path (60 s), MODE and IN as
# _era_wd takes them: ERA_O its output, ERA_OE its stderr (MODE split), ERA_RC its status. When the watchdog ended
# it, ERA_O starts with a line saying so, ERA_RC is hung, and WHAT is added to ERA_WD.
_era_rr() {
  local n="$1" m="$2" in="$3"
  shift 3
  if _era_wd "$_era_ev" 60 "$m" "$in" _era_in "$@"; then
    ERA_O="$(cat "$ERA/w.out" 2>/dev/null)"; ERA_OE="$(cat "$ERA/w.err" 2>/dev/null)"; ERA_RC="$(cat "$ERA/w.rc" 2>/dev/null)"
  else
    ERA_O="$(printf '(the watchdog ended %s after 60 s)\n' "$n"; cat "$ERA/w.out" 2>/dev/null)"
    ERA_OE="$(printf '(the watchdog ended %s after 60 s)\n' "$n"; cat "$ERA/w.err" 2>/dev/null)"; ERA_RC=hung
    ERA_WD="${ERA_WD:+$ERA_WD, }$n"
  fi
}
printf '%s\n' "$_era_trace" > "$ERA/trace.in"
printf 'src/thing.js throws when it loads\n' > "$ERA/issue.in"
mkdir -p "$ERA/home"
# felix next runs under A25's narrowed PATH, which is there so that no claude CLI is found, and which also hands it
# /usr/bin/git where every other reader here runs the suite's git. On a Mac /usr/bin/git is Xcode's shim, and from
# an Xcode update until its licence is accepted it exits 69 on every call; felix next then says the base names
# nothing and the tree has no gate receipt. In a full gate on 2026-11-14 that failed the nine next assertions of
# R and C5: Xcode 27.2 was installed at 09:36:10Z, its licence accepted at 09:39:14Z, and the seven next calls ran
# at 09:36:57Z to 09:37:58Z. So $ERA/git holds the suite's git alone, and next finds it before /usr/bin.
mkdir -p "$ERA/git"; _era_git="$(type -P git)"; [ -z "$_era_git" ] || ln -sf "$_era_git" "$ERA/git/git"
# READER...: the change at HEAD read by each READER (evidence classify receipt merge incident next brief d4) over
# the base refs/heads/era-base at HEAD~1, after a green gate receipt and a fresh commission receipt (1830 A21).
_era_read() {
  local x b=refs/heads/era-base
  ERA_E=""; ERA_ERC=""; ERA_C=""; ERA_R=""; ERA_RJ=""; ERA_M=""; ERA_ML=""; ERA_I=""
  ERA_N=""; ERA_B=""; ERA_D=""; ERA_DE=""; ERA_DJ=""; ERA_WD=""
  _fx_git "$REPO" update-ref "$b" HEAD~1 >/dev/null 2>&1
  _era_rr "the gate and commission receipts" both /dev/null _era_prep
  for x in "$@"; do
    case "$x" in
      evidence) _era_rr "felix evidence" both /dev/null "$FELIX" evidence --base "$b"; ERA_E="$ERA_O"; ERA_ERC="$ERA_RC" ;;
      classify) _era_rr "felix classify" both /dev/null "$FELIX" classify --base "$b"; ERA_C="$ERA_O" ;;
      receipt)  _era_rr "felix receipt" split /dev/null "$FELIX" receipt --base "$b"; ERA_R="$ERA_O"; ERA_RJ="$(_era_rj "$ERA_R")" ;;
      merge)    _era_rr "felix merge --dry-run" both /dev/null "$FELIX" merge --base "$b" --dry-run; ERA_M="$ERA_O"
                ERA_ML="$(printf '%s\n' "$ERA_M" | LC_ALL=C awk '$1 == "evidence"')" ;;
      incident) _era_rr "felix incident" both "$ERA/trace.in" "$FELIX" incident; ERA_I="$ERA_O" ;;
      next)     _era_rr "felix next" both /dev/null env PATH="$ERA/git:/usr/bin:/bin" HOME="$ERA/home" "$FELIX" next --base "$b"
                ERA_N="$ERA_O" ;;
      brief)    _era_rr "felix brief" both "$ERA/issue.in" "$FELIX" brief --from - --title t; ERA_B="$ERA_O" ;;
      d4)       _era_rr "felix_receipt with lib/receipt.sh sourced alone" split /dev/null \
                  bash -c '. "$1/lib/resolve.sh"; . "$1/lib/receipt.sh"; felix_receipt "$2" "$3" "$4" "$5"' \
                  _ "$FROOT/harness" "$_era_wp" "$b" "$REPO" "$FROOT"
                ERA_D="$ERA_O"; ERA_DE="$ERA_OE"; ERA_DJ="$(_era_rj "$ERA_D")" ;;
    esac
  done
  _fx_git "$REPO" update-ref -d "$b" >/dev/null 2>&1
}
# KIND ROWS PATH -- READER...: the path made KIND, then, when it was, PATH changed and committed and the READERs run.
_era_begin() {
  local k="$1" r="$2" p="$3"
  shift 4
  ERA_CH=""; ERA_E=""; ERA_ERC=""; ERA_C=""; ERA_R=""; ERA_RJ=""; ERA_M=""; ERA_ML=""; ERA_I=""
  ERA_N=""; ERA_B=""; ERA_D=""; ERA_DE=""; ERA_DJ=""; ERA_WD=""
  _era_put "$k" "$r"
  [ -z "$_era_why" ] || return 0
  if _era_ch "$p"; then ERA_CH=1; else _era_why="the change to $p could not be committed"; return 0; fi
  _era_read "$@"
}
_era_end() { [ -z "$ERA_CH" ] || _reset; ERA_CH=""; _era_release "$_era_ev"; _era_clear; _era_why=""; }
# The rows of felix incident's section the fix will have to prove: the lines after its heading up to the first blank
# line, each a row's name and its reason; or a line saying the output has no such heading.
_era_isec() {
  case "$ERA_I" in
    *"the fix will have to prove"*)
      printf '%s\n' "$ERA_I" | LC_ALL=C awk 'f == 1 && !NF { f = 2 } f == 1 { print } !f && index($0, "the fix will have to prove") { f = 1 }' ;;
    *) printf '(no heading the fix will have to prove)' ;;
  esac
}
# NAME: A5 over the current state: felix evidence, felix classify and felix receipt (evidence under unknown) say not
# judged exactly when felix merge --dry-run lists an evidence blocker.
_era_agree() {
  local e c m
  case "$ERA_E" in *"not judged"*) e=yes ;; *) e=no ;; esac
  case "$ERA_C" in *"not judged"*) c=yes ;; *) c=no ;; esac
  if [ -n "$ERA_ML" ]; then m=yes; else m=no; fi
  _era_is "$1" "merge $m: evidence $e, classify $c, receipt $(_era_rf 1)" "merge $m: evidence $m, classify $m, receipt $m"
}
_era_A5='felix evidence, felix classify (green change) and felix receipt (evidence under unknown) say not judged exactly when felix merge --dry-run lists an evidence blocker'
# The lines of felix next that say an evidence row was not judged or cannot be judged (amendment 3), one a line.
_era_nrows() { printf '%s\n' "$ERA_N" | LC_ALL=C awk 'index($0, "not judged") || index($0, "cannot be judged")'; }
# The rows of felix brief's section what a fix must prove: the lines after its heading up to the first blank
# line; or a line saying the output has no such heading (amendment 4).
_era_bsec() {
  case "$ERA_B" in
    *"what a fix must prove"*)
      printf '%s\n' "$ERA_B" | LC_ALL=C awk 'f == 1 && !NF { f = 2 } f == 1 { print } !f && index($0, "what a fix must prove") { f = 1 }' ;;
    *) printf '(no heading what a fix must prove)' ;;
  esac
}
# NAME: A5 extended to felix next and felix brief over the current state (amendments 3 and 4): a row of next saying
# an evidence row was not judged, and "not judged" in brief's section, each exactly when merge lists an evidence
# blocker. Two assertions, NAME's next and brief halves.
_era_agree2() {
  local n b m
  if [ -n "$(_era_nrows)" ]; then n=yes; else n=no; fi
  case "$(_era_bsec)" in *"not judged"*) b=yes ;; *) b=no ;; esac
  if [ -n "$ERA_ML" ]; then m=yes; else m=no; fi
  _era_is "A5 agreement, felix next ($1): felix next prints a row saying an evidence row was not judged exactly when felix merge --dry-run lists an evidence blocker" \
          "merge $m: next $n" "merge $m: next $m" "$ERA_N"
  _era_is "A5 agreement, felix brief ($1): felix brief, given an issue that names src/thing.js, says not judged in its what a fix must prove section exactly when felix merge --dry-run lists an evidence blocker" \
          "merge $m: brief $b" "merge $m: brief $m" "$ERA_B"
}
# NAME: D4 (a) over the current state: felix_receipt with lib/receipt.sh sourced alone prints a receipt, JSON, on
# stdout and nothing on stderr.
_era_d4a() {
  local j=json
  [ "$(printf '%s\n' "$ERA_DJ" | LC_ALL=C sed -n 1p)" != "not json" ] || j="not json"
  _era_is "$1" "stdout $j, stderr [$ERA_DE]" "stdout json, stderr []" "$ERA_D"
}

# The file the trace names, committed once under every state's change and undone at the end.
_era_thing=""
_era_ch src/thing.js && _era_thing=1

# C1: nothing at the path.
_era_begin none - README.md -- evidence classify receipt merge incident next brief d4
_era_l="nothing at the path, control"
_era_hl "C1 evidence ($_era_l): says the project declares no evidence.tsv" "$ERA_E" '+declares no evidence.tsv'
_era_hl "C1 classify ($_era_l): on a green change says no evidence is owed" "$ERA_C" '+tier:  green' '+no evidence is owed'
_era_is "C1 receipt ($_era_l): lists no unknown" "$(_era_rf 2)" "[]" "$ERA_R"
_era_is "C1 merge --dry-run ($_era_l): lists no evidence line, where C2 and C5 list one over the same base" \
        "$(_era_c "$ERA_ML" 1)" 0 "$ERA_M"
_era_agree "A5 agreement (C1, $_era_l): $_era_A5"
_era_is "D1 felix_evidence_table_present (C1, nothing at the widget project's path): exits 1 and prints nothing" \
        "$(_era_tp "$_era_wp")" "rc=1 out=[]"
_era_hl "C1 incident ($_era_l): given a trace that names src/thing.js, prints its implicated file src/thing.js and not the heading the fix will have to prove, where C5 prints it over the same trace" \
        "$ERA_I" '+src/thing.js' '-the fix will have to prove'
_era_is "A6 next (C1, $_era_l): prints its rows, and no row saying an evidence row cannot be judged naming evidence.tsv, where R's states print one" \
        "rows $(_era_c "$ERA_N" 1 | LC_ALL=C sed 's/^[123456789][0123456789]*$/some/'), evidence.tsv not judged rows $(_era_c "$(_era_nrows)" 'index($0, "evidence.tsv")')" \
        "rows some, evidence.tsv not judged rows 0" "$ERA_N"
_era_hl "A7 brief (C1, $_era_l): given an issue that names src/thing.js, briefs src/thing.js and prints no what a fix must prove section, where R's states print one" \
        "$ERA_B" '+src/thing.js' '-what a fix must prove'
_era_agree2 "C1, $_era_l"
_era_d4a "D4 receipt.sh sourced alone after lib/resolve.sh (C1, $_era_l): felix_receipt prints a receipt, JSON, and nothing on stderr"
_era_end

# C2: a readable table whose rule the change touches and does not meet.
_era_begin file "$_era_T" src/a.ts -- evidence receipt merge d4
_era_l="a readable table, a rule the change touches and does not meet, control"
_era_hl "C2 evidence ($_era_l): names the gap, [!] code, and not not judged" "$ERA_E" '+[!] code' '-not judged'
_era_is "C2 receipt ($_era_l): lists the gap code, and evidence not under unknown" \
        "gap $(_era_rf 3), evidence under unknown $(_era_rf 1)" 'gap ["code"], evidence under unknown no' "$ERA_R"
_era_is "C2 merge --dry-run ($_era_l): lists the gap as one evidence line named code, and no evidence line says not judged" \
        "$(_era_c "$ERA_ML" '$2 == "code"')|$(_era_c "$ERA_ML" 'index($0, "not judged")')" "1|0" "$ERA_M"
_era_d4a "D4 receipt.sh sourced alone after lib/resolve.sh (C2, a readable table): felix_receipt prints a receipt, JSON, and nothing on stderr"
_era_end

# C3: the same table, a change the rule does not reach.
_era_begin file "$_era_T" README.md -- evidence classify receipt merge next brief
_era_l="the same table, a change the rule does not reach, control"
_era_hl "C3 evidence ($_era_l): says No evidence gaps, with no [!] row and not not judged" "$ERA_E" '+No evidence gaps' '-[!]' '-not judged'
_era_hl "C3 classify ($_era_l): on a green change says no evidence is owed, and not not judged" \
        "$ERA_C" '+tier:  green' '+no evidence is owed' '-not judged'
_era_is "C3 receipt ($_era_l): lists no gap, and evidence not under unknown" \
        "gap $(_era_rf 3), evidence under unknown $(_era_rf 1)" "gap [], evidence under unknown no" "$ERA_R"
_era_is "C3 merge --dry-run ($_era_l): lists no evidence line, where C2 lists the gap over the same table" \
        "$(_era_c "$ERA_ML" 1)" 0 "$ERA_M"
_era_agree "A5 agreement (C3, $_era_l): $_era_A5"
_era_is "A6 next (C3, $_era_l): prints its rows, and no row saying an evidence row cannot be judged naming evidence.tsv, where R's states print one" \
        "rows $(_era_c "$ERA_N" 1 | LC_ALL=C sed 's/^[123456789][0123456789]*$/some/'), evidence.tsv not judged rows $(_era_c "$(_era_nrows)" 'index($0, "evidence.tsv")')" \
        "rows some, evidence.tsv not judged rows 0" "$ERA_N"
_era_agree2 "C3, $_era_l"
_era_end

# C4: a link that resolves to the file of C2.
_era_begin linkfile "$_era_T" src/a.ts -- evidence receipt merge
_era_l="a link that resolves to C2's file, control"
_era_hl "C4 evidence ($_era_l): names the gap, [!] code, and not not judged" "$ERA_E" '+[!] code' '-not judged'
_era_is "C4 receipt ($_era_l): lists the gap code, and evidence not under unknown" \
        "gap $(_era_rf 3), evidence under unknown $(_era_rf 1)" 'gap ["code"], evidence under unknown no' "$ERA_R"
_era_is "C4 merge --dry-run ($_era_l): lists the gap as one evidence line named code, and no evidence line says not judged" \
        "$(_era_c "$ERA_ML" '$2 == "code"')|$(_era_c "$ERA_ML" 'index($0, "not judged")')" "1|0" "$ERA_M"
_era_end

# C5: a regular file with a row that is not four cells, the reference case.
_era_begin file "$_era_T3" README.md -- evidence classify receipt merge incident next brief
_era_l="a row that is not four cells, the reference, control"
_era_hl "C5 evidence ($_era_l): prints the [?] unit row not judged and 1 row(s) not judged" \
        "$ERA_E" '+[?] unit' '+not judged' '+1 row(s) not judged'
_era_hl "C5 classify ($_era_l): on a green change says 1 evidence row(s) not judged and Not auto-merge eligible" \
        "$ERA_C" '+tier:  green' '+ 1 evidence row(s) not judged' '+Not auto-merge eligible' '-Eligible for auto-merge'
_era_is "C5 receipt ($_era_l): lists evidence under unknown" "$(_era_rf 1)" yes "$ERA_R"
_era_is "C5 merge --dry-run ($_era_l): lists one evidence line, named unit, saying not judged" \
        "$(_era_c "$ERA_ML" 1)|$(_era_c "$ERA_ML" '$2 == "unit" && index($0, "not judged")')" "1|1" "$ERA_M"
_era_v="$(_era_isec)"
_era_is "A4 armed (C5, control): felix incident given the trace that names src/thing.js prints the fix will have to prove section, with the unit row not judged" \
        "$(_era_c "$_era_v" '$1 == "unit" && index($0, "not judged")')" 1 "$ERA_I"
_era_agree "A5 agreement (C5, $_era_l): $_era_A5"
_era_agree2 "C5, $_era_l"
_era_end

# C6: a regular file at mode 000.
_era_begin mode000 "$_era_T" README.md -- evidence classify receipt merge
_era_l="a regular file at mode 000, control"
_era_hl "C6 evidence ($_era_l): says not judged" "$ERA_E" '+not judged'
_era_hl "C6 classify ($_era_l): on a green change says not judged and Not auto-merge eligible" \
        "$ERA_C" '+tier:  green' '+not judged' '+Not auto-merge eligible'
_era_is "C6 receipt ($_era_l): lists evidence under unknown" "$(_era_rf 1)" yes "$ERA_R"
_era_is "C6 merge --dry-run ($_era_l): lists an evidence line saying not judged" \
        "$(_era_c "$ERA_ML" 'index($0, "not judged")')" 1 "$ERA_M"
_era_end

# The watchdog's own arming (the fixtures' FIFO bullet), on FIFOs of its own under $ERA, never read: a command whose
# child blocks opening one for writing is ended at a 2 s deadline, that child too; an opener that left every tree
# (its parent gone) is freed by the release. PID: gone, or alive (then it is killed here, so nothing outlives this),
# or unknown when PID is not a process number above 1 (never 0, which would name the suite's own process group).
_era_gone() {
  local i=0
  case "$1" in ''|*[!0123456789]*|0|1) printf unknown; return 0 ;; esac
  while kill -0 "$1" 2>/dev/null && [ "$i" -lt 30 ]; do sleep 0.1; i=$((i + 1)); done
  if kill -0 "$1" 2>/dev/null; then kill -KILL "$1" 2>/dev/null; printf alive; else printf gone; fi
}
_era_wdt() { ( printf 'x\n' > "$ERA/wd1.fifo" ) </dev/null >/dev/null 2>&1 & printf '%s\n' "$!" > "$ERA/wd1.pid"; wait; }
rm -f "$ERA/wd1.fifo" "$ERA/wd2.fifo" "$ERA/wd1.pid" "$ERA/wd2.pid"
if mkfifo "$ERA/wd1.fifo" "$ERA/wd2.fifo" 2>/dev/null && [ -p "$ERA/wd1.fifo" ] && [ -p "$ERA/wd2.fifo" ]; then
  if _era_wd "$ERA/wd1.fifo" 2 both /dev/null _era_wdt; then _era_a="returned"; else _era_a="ended"; fi
  _era_b="$(_era_gone "$(cat "$ERA/wd1.pid" 2>/dev/null)")"
  ( ( printf 'x\n' > "$ERA/wd2.fifo" ) </dev/null >/dev/null 2>&1 & printf '%s\n' "$!" > "$ERA/wd2.pid" )
  sleep 0.3; _era_release "$ERA/wd2.fifo"
  _era_v="$(_era_gone "$(cat "$ERA/wd2.pid" 2>/dev/null)")"
  _era_is "R armed (FIFO, the watchdog, control): a command whose child blocks opening a FIFO is ended at its deadline with that child, and an opener outside the command's tree is released, so neither outlives the call" \
          "command $_era_a, its blocked child $_era_b, the opener outside its tree $_era_v" \
          "command ended, its blocked child gone, the opener outside its tree gone"
else
  skip "R armed (FIFO, the watchdog, control): a command whose child blocks opening a FIFO is ended at its deadline with that child, and an opener outside the command's tree is released, so neither outlives the call" \
       "mkfifo could not make a FIFO under \$TMP here"
fi
rm -f "$ERA/wd1.fifo" "$ERA/wd2.fifo"

# R: a directory, a dangling link, a link that resolves to a directory, and (amendment 1) a FIFO.
for _era_x in "dir|directory" "dangling|dangling link" "linkdir|link to a directory" "fifo|FIFO"; do
  _era_l="${_era_x#*|}"
  _era_k4=""; [ "${_era_x%%|*}" != dir ] || _era_k4=d4
  _era_begin "${_era_x%%|*}" - README.md -- evidence classify receipt merge incident next brief $_era_k4
  _era_is "R armed ($_era_l, control): the path is a $_era_l, and felix merge --dry-run lists one evidence line, named evidence.tsv, saying cannot be read and not judged" \
          "$(_era_c "$ERA_ML" 1)|$(_era_c "$ERA_ML" '$2 == "evidence.tsv" && index($0, "cannot be read") && index($0, "not judged")')${ERA_WD:+, the watchdog ended $ERA_WD}" "1|1" "$ERA_M"
  _era_n="$(_era_c "$ERA_E" '$1 == "[?]" && $2 == "evidence.tsv" && index($0, "cannot be read") && index($0, "not judged")')"
  _era_m="$(_era_c "$ERA_E" '$1 == "1" && $2 == "row(s)" && $3 == "not" && $4 ~ /^judged/')"
  case "$ERA_E" in *"declares no evidence.tsv"*) _era_s=yes ;; *) _era_s=no ;; esac
  _era_is "A1 evidence ($_era_l): exits 1, prints one [?] row named evidence.tsv whose reason holds cannot be read and not judged and a line saying 1 row(s) not judged, and does not print declares no evidence.tsv" \
          "exit $ERA_ERC, [?] evidence.tsv rows $_era_n, 1 row(s) not judged lines $_era_m, declares no evidence.tsv $_era_s" \
          "exit 1, [?] evidence.tsv rows 1, 1 row(s) not judged lines 1, declares no evidence.tsv no" "$ERA_E"
  _era_hl "A2 classify ($_era_l): on a green change says 1 evidence row(s) not judged and Not auto-merge eligible, and prints neither no evidence is owed nor Eligible for auto-merge" \
          "$ERA_C" '+tier:  green' '+ 1 evidence row(s) not judged' '+Not auto-merge eligible' '-no evidence is owed' '-Eligible for auto-merge'
  _era_is "A3 receipt ($_era_l): lists evidence under unknown, and no evidence gap and no met row" \
          "evidence under unknown $(_era_rf 1), gap $(_era_rf 3), met $(_era_rf 4)" "evidence under unknown yes, gap [], met []" "$ERA_R"
  _era_v="$(_era_isec)"
  _era_is "A4 incident ($_era_l): given a trace that names src/thing.js, prints the fix will have to prove section with one row named evidence.tsv whose reason holds cannot be read and not judged" \
          "$(_era_c "$_era_v" '$1 == "evidence.tsv" && index($0, "cannot be read") && index($0, "not judged")')" 1 "$ERA_I"
  _era_agree "A5 agreement ($_era_l): $_era_A5"
  _era_is "A6 next ($_era_l): prints a row saying an evidence row cannot be judged, naming evidence.tsv" \
          "evidence.tsv not judged rows $(_era_c "$(_era_nrows)" 'index($0, "evidence.tsv")' | LC_ALL=C sed 's/^[123456789][0123456789]*$/some/')" \
          "evidence.tsv not judged rows some" "$ERA_N"
  _era_v="$(_era_bsec)"
  _era_is "A7 brief ($_era_l): given an issue that names src/thing.js, prints the what a fix must prove section with one row named evidence.tsv whose reason holds cannot be read and not judged" \
          "$(_era_c "$_era_v" '$1 == "evidence.tsv" && index($0, "cannot be read") && index($0, "not judged")')" 1 "$ERA_B"
  _era_agree2 "$_era_l"
  if [ -n "$_era_k4" ]; then
    _era_is "D4 receipt.sh sourced alone after lib/resolve.sh ($_era_l): felix_receipt lists evidence under unknown, as felix receipt does" \
            "$(printf '%s\n' "$ERA_DJ" | LC_ALL=C sed -n 1p)" yes "$ERA_D"
  fi
  _era_end
done

# The widget as this part found it: the trace's file undone, nothing this part made at the path, the original back.
[ -z "$_era_thing" ] || _reset
_era_release "$_era_ev"
_era_clear
[ -z "$_era_kept" ] || mv "$ERA/evidence.keep" "$_era_ev"
unset -f _era_is _era_hl _era_c _era_tp _era_d1 _era_g _era_chk _era_head _era_ch _era_clear _era_put _era_rj _era_rf \
         _era_read _era_begin _era_end _era_isec _era_agree _era_tree _era_release _era_wd _era_tpc _era_in _era_prep \
         _era_rr _era_nrows _era_bsec _era_agree2 _era_d4a _era_gone _era_wdt
# <<< evidence-readers-agree
