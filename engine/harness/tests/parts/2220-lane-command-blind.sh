# >>> lane-command
printf '\nfelix lane: its usage, exits, thirteen columns and human line, the last change of a row, next, and read-only bytes (slice 0, design 6.5 item 1 and 6.6, C5, L-DET, L-RO; blind)\n'
# Blind, written on 2026-10-29 from docs/2026-10-29-capability-lane-first-slices-design.md and the slice 0 plan's
# Contracts (C1-C13) alone, before lib/lane.sh existed, without reading lib/, hooks/, bin/ or felix. Felix is run as a
# black box; the builders are tests/lib/lane-fixture.sh's. C11's row for this part: section 6.5 item 1 and 6.6 "The
# last change" and "Determinism": the usage line and exits; the thirteen columns and the human line; the last lane
# landing, and column 7 unknown with the state unchanged (C11's second worked expectation); next none and unknown; the
# commit that last changed a lane's row, unmoved by a comment line or another lane's row; an uncommitted edit changes
# nothing printed; L-DET; L-RO; no committed lanes.tsv prints nothing.
#
# The home apart (C9): H holds project ck with lanes.tsv (capability, ^engine/, 1/2, 14) and lane-next.tsv committed,
# and stays as built until the uncommitted edits at the end; the checkout C (bound by an untracked .felix) holds the
# root, a marked engine landing three days back, an unmarked one two days back and a marked docs one a day back, so
# capability reads ok, L 1 of T 2. The usage text is read from felix help, whose stdout is the general usage
# (felix --help prints the same on main). Readings where the Contracts leave room:
# - "In any directory" is a governed checkout and a directory under the fixture that no project governs.
# - The last change is asserted in a home of its own, whose history is commit A (the row), B (a comment line), C
#   (another lane's row), D (another file) and E (the row's share): capability names A until E, the other lane C; a
#   home whose root commit holds the row names its root. A --depth 1 clone of H is a shallow home: column 10 unknown.
# - L-RO's marker is touched a second after the fixture's last write, and what it finds newer is printed in the
#   assertion, so a write is named, not only counted.
# - The --help and -h exits are controls (C10); every other assertion here is red on main.
# - The review's second amendment (2026-10-30, design 11 item 45, still blind) adds C11's next texts exactly none and
#   unknown (F9), 1 day in the human line (F11), and a count that ends early (F1), at the end of the part.
# - The second review's round 2 (2026-10-30, still blind) adds, at the end, R2B-F3 (a caller's GIT_GRAFT_FILE), R2B-F4
#   (lanes named 1 and 01) and R2B-F5 (the repository root's substitution ended early).
# - The second review's round 3 (2026-10-30, still blind) adds, at the end, R3-F2: the project's resolution ended early,
#   in a checkout its .felix binds and in one remote_match alone binds.
# - Design item 46 (2026-10-30, still blind) adds, at the end, I46-1 to I46-10: C5's line for a resolution that did not
#   finish, under C9's probes inside felix_resolve_project, and the misses that stand (C2's bullet The lane's resolution).
# - The third review's round 1 (2026-10-30, still blind) adds, at the end, V3R1-F1 and V3R1-F2 (the check of a resolution
#   whose remote_match reads failed) and V3R1-F5 (C5's sentence for a .felix marker that cannot be opened).
# - The third review's round 2 (2026-10-30, still blind) adds, at the end, V3R2-F1 and V3R2-F2: a miss said from the lane
#   check's own reads, in C5's sentence for its layout, and nothing written under the memory root.
LNKN=1793000000; LNKDAY=86400
LNKNEXT='obligation intake, slice 1: felix situations --change (branch claude/lane-situations-owed)'
LNKMARK='Felix-Lane: capability'
LNKUSE='    felix lane [--tsv]     read-only: each lane'"'"'s share of engine landings on origin/main, against its target'
_lf_dir "$TMP/lane-2220"; LNKD="$LF_DIR"; mkdir -p "$LNKD/plain"
_lf_stubs "$LNKD"; LNKB="$LF_BIN"
_lf_home "$LNKD/home" ck 1792700000; LNKH="$LF_HOME"; LNKP="$LF_PROJ"
LNKLANES=$'# The lanes this fixture counts.\ncapability\t^engine/\t1/2\t14\n'
LNKNEXTS="$(_lf_tsv capability "$LNKNEXT")"$'\n'
_lf_table "$LNKP" 1792700100 lanes.tsv "$LNKLANES"; LNKTAB="$LF_SHA"; LNKTABISO="$(_lf_iso 1792700100)"
_lf_table "$LNKP" 1792700200 lane-next.tsv "$LNKNEXTS"
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"
_lf_checkout "$LNKD/c" ck $((LNKN - 30 * LNKDAY)); LNKC="$LF_REPO"
_lf_chain "$LNKC" capability $((LNKN - 3 * LNKDAY)) "$LNKDAY" m u md
if [ -n "$LNKTAB" ] && [ "$(_lf_spine "$LNKC")" = "$((LNKN - LNKDAY)):1 $((LNKN - 2 * LNKDAY)):1 $((LNKN - 3 * LNKDAY)):1 $((LNKN - 30 * LNKDAY)):0" ]; then
  LNKBUILT=built; else LNKBUILT="not built: the checkout reads [$(_lf_spine "$LNKC")]"; fi
LNKREFD="$(_lf_iso $((LNKN - LNKDAY)))"; LNKLASTD="$(_lf_iso $((LNKN - 3 * LNKDAY)))"
LNKLINE="$(_lf_tsv capability ok 1 2 14 1/2 "$LNKLASTD" "$LNKMARK" "$LNKNEXT" "$LNKTAB" "$LNKTABISO" "$LNKREFD" -)"
LNKCHG="its lanes.tsv row last changed by $(printf '%.12s' "$LNKTAB") at $LNKTABISO"
LNKHUMAN="capability: ok, 1 of 2 engine landings in 14 days, target 1/2; last lane landing $LNKLASTD; mark $LNKMARK; next: $LNKNEXT; $LNKCHG; refs/remotes/origin/main at $LNKREFD"
LNKROW="$(_lf_tsv lane value ok '1 of 2 engine landings in 14 days, target 1/2')"
# OUT -> status|bytes on stdout|stderr, of the run whose files are OUT.out and OUT.err.
_lnk_res() { printf '%s|%s|%s' "$LF_RC" "$(wc -c < "$1.out" | tr -d ' ')" "$(cat "$1.err")"; }

# ---- usage and exits ------------------------------------------------------------------------------------------------------
_lf_run "$LNKD/help" "$LNKC" - "$FELIX" help
LNKa="$(LC_ALL=C awk 'p { print; exit } index($0, "felix status [--tsv]") { p = 1 }' "$LNKD/help.out")"
is "lane command: felix help lists felix lane [--tsv] byte for byte, its text from column 28, on the line right after the one holding felix status [--tsv]" \
   "$LF_RC|$LNKa" "0|$LNKUSE"
_lf_run "$LNKD/lh1" "$LNKC" - "$FELIX" lane --help; LNKa="$LF_RC|$(cmp -s "$LNKD/lh1.out" "$LNKD/help.out" && echo usage || echo other)"
_lf_run "$LNKD/lh2" "$LNKC" - "$FELIX" lane -h x; LNKa="$LNKa|$LF_RC|$(cmp -s "$LNKD/lh2.out" "$LNKD/help.out" && echo usage || echo other)"
is "lane command: in a governed checkout felix lane --help and felix lane -h x print the general usage on stdout and exit 0 (control)" \
   "$LNKa" "0|usage|0|usage"
_lf_run "$LNKD/lh3" "$LNKD/plain" - "$FELIX" lane -h; LNKa="$LF_RC|$(cmp -s "$LNKD/lh3.out" "$LNKD/help.out" && echo usage || echo other)"
_lf_run "$LNKD/lh4" "$LNKD/plain" - "$FELIX" lane --help --tsv; LNKa="$LNKa|$LF_RC|$(cmp -s "$LNKD/lh4.out" "$LNKD/help.out" && echo usage || echo other)"
is "lane command: in a directory no project governs felix lane -h and felix lane --help --tsv print the general usage on stdout and exit 0 (control)" \
   "$LNKa" "0|usage|0|usage"
LNKUERR='felix: usage: felix lane [--tsv]'
# LABEL ARGS... -> felix lane ARGS is a usage error, in the checkout and in the ungoverned directory.
_lnk_usage() {
  local l="$1" g
  shift
  _lf_run "$LNKD/ug" "$LNKC" - "$FELIX" lane "$@"; g="$(_lnk_res "$LNKD/ug")"
  _lf_run "$LNKD/up" "$LNKD/plain" - "$FELIX" lane "$@"
  is "lane command: felix lane $l is a usage error, in a governed checkout and where no project governs: nothing on stdout, the usage line alone on stderr, exit 2" \
     "$g||$(_lnk_res "$LNKD/up")" "2|0|$LNKUERR||2|0|$LNKUERR"
}
_lnk_usage --json --json
_lnk_usage '--tsv --tsv' --tsv --tsv
_lnk_usage x x
_lnk_usage '--tsv --help' --tsv --help
_lf_run "$LNKD/ng1" "$LNKD/plain" - "$FELIX" lane; LNKa="$LF_RC|$(wc -c < "$LNKD/ng1.out" | tr -d ' ')|$(LC_ALL=C awk 'NR == 1' "$LNKD/ng1.err")|$(_lf_count "$LNKD/ng1.err")"
_lf_run "$LNKD/ng2" "$LNKD/plain" - "$FELIX" lane --tsv; LNKa="$LNKa||$LF_RC|$(wc -c < "$LNKD/ng2.out" | tr -d ' ')|$(LC_ALL=C awk 'NR == 1' "$LNKD/ng2.err")|$(_lf_count "$LNKD/ng2.err")"
LNKb="felix: no project governs $LNKD/plain."
is "lane command: where no project governs, felix lane and felix lane --tsv exit 2 with nothing on stdout and three lines on stderr, the first felix: no project governs <dir>." \
   "$LNKa" "2|0|$LNKb|3||2|0|$LNKb|3"

# ---- no committed lanes.tsv: nothing printed ----------------------------------------------------------------------------
_lf_home "$LNKD/home-none" ck 1792700000; LNKH2="$LF_HOME"; LNKP2="$LF_PROJ"
_lf_use "$LNKH2" "$LNKD/memory" "$LNKD/user" "$LNKB"
# LABEL -> felix lane and felix lane --tsv in C print nothing and exit 0.
_lnk_none() {
  _lf_run "$LNKD/none1" "$LNKC" "$LNKN" "$FELIX" lane; LNKa="$LF_RC|$(wc -c < "$LNKD/none1.out" | tr -d ' ')"
  _lf_run "$LNKD/none2" "$LNKC" "$LNKN" "$FELIX" lane --tsv
  is "lane command: $1: felix lane and felix lane --tsv print nothing and exit 0" "$LNKBUILT|$LNKa|$LF_RC|$(wc -c < "$LNKD/none2.out" | tr -d ' ')" "built|0|0|0|0"
}
_lnk_none "a home that never held lanes.tsv counts no lane"
printf '%s' "$LNKLANES" > "$LNKP2/lanes.tsv"
_lnk_none "a lanes.tsv with a row in the home's working tree, never committed, counts no lane"
_lf_table "$LNKP2" 1792700300 lanes.tsv $'# No lane is counted yet.\n\n'
_lnk_none "a committed lanes.tsv holding only a comment and a blank line counts no lane"
_lf_table "$LNKP2" 1792700400 lanes.tsv "$LNKLANES" && _lf_commit "$LNKP2" 1792700500 $'lanes.tsv removed\n' -lanes.tsv
printf '%s' "$LNKLANES" > "$LNKP2/lanes.tsv"
_lnk_none "a lanes.tsv committed, then removed by a later commit and left in the working tree, counts no lane"
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- the thirteen columns and the human line --------------------------------------------------------------------------
_lf_run "$LNKD/tsv" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command: felix lane --tsv prints one line of thirteen columns: lane, ok, L 1, T 2, window, share, the last lane landing's date, the mark, next, the commit that last changed the row and its date, the ref's date, and -" \
   "$LNKBUILT|$LF_RC|$(cat "$LNKD/tsv.out")" "built|0|$LNKLINE"
_lf_run "$LNKD/human" "$LNKC" "$LNKN" "$FELIX" lane
is "lane command: felix lane prints the human line built from those columns, the commit shortened to twelve characters" \
   "$LNKBUILT|$LF_RC|$(cat "$LNKD/human.out")" "built|0|$LNKHUMAN"

# ---- the review's F2: git variables the caller exported change nothing (C2) ------------------------------------------
# Added on 2026-10-30 from the adversarial review of the first build, still blind. C2 names the repository, the one
# holding the current directory, and where the tables are read, HEAD of the repository holding <PROJ>, whatever git
# variables the caller exported. Each setting below, given on the felix command alone, must leave felix lane --tsv's
# line and the status row as they are without it. O is another repository, with one commit of its own.
LNKa="not built: another repository"
_lf_init "$LNKD/f2-other" && _lf_commit "$LNKD/f2-other" 1792700000 $'another repository\n' other.txt \
  && LNKO="$(cd -P "$LNKD/f2-other" && pwd -P)" && [ -n "$LNKO" ] && LNKa="$LNKBUILT"
LNKb=""; LNKc=""; LNKw=""; LNKv=""
# LABEL ASSIGNMENT... -> felix lane --tsv and felix status --tsv in C with the ASSIGNMENTs on the felix command alone:
# LNKb and LNKc gain " [LABEL] <status>|<output>" and " [LABEL] <status>|<last row>", LNKw and LNKv the same unchanged.
_lnk_env() {
  local l="$1"
  shift
  _lf_run "$LNKD/f2" "$LNKC" "$LNKN" "$@" "$FELIX" lane --tsv
  LNKb="$LNKb [$l] $LF_RC|$(cat "$LNKD/f2.out")"; LNKw="$LNKw [$l] 0|$LNKLINE"
  _lf_run "$LNKD/f2s" "$LNKC" "$LNKN" "$@" "$FELIX" status --tsv
  LNKc="$LNKc [$l] $LF_RC|$(_lf_last "$LNKD/f2s.out")"; LNKv="$LNKv [$l] 0|$LNKROW"
}
_lnk_env 'GIT_DIR=<C>/.git' "GIT_DIR=$LNKC/.git"
_lnk_env 'GIT_DIR=<H>/.git' "GIT_DIR=$LNKH/.git"
_lnk_env 'GIT_DIR=.git' GIT_DIR=.git
_lnk_env 'GIT_WORK_TREE=<C>' "GIT_WORK_TREE=$LNKC"
_lnk_env 'GIT_DIR=<C>/.git and GIT_WORK_TREE=<C>' "GIT_DIR=$LNKC/.git" "GIT_WORK_TREE=$LNKC"
_lnk_env 'GIT_DIR=<O>/.git' "GIT_DIR=$LNKO/.git"
_lnk_env 'GIT_OBJECT_DIRECTORY=<O>/.git/objects' "GIT_OBJECT_DIRECTORY=$LNKO/.git/objects"
is "lane command F2-caller-git-dir: GIT_DIR naming the checkout, the home, .git or another repository, GIT_WORK_TREE, both, or GIT_OBJECT_DIRECTORY of another repository, exported by the caller, leave felix lane --tsv's exit 0 and line as they are without them" \
   "$LNKa$LNKb" "built$LNKw"
is "lane command F2-caller-git-dir: the same settings leave felix status --tsv's exit 0 and its lane row as they are without them" \
   "$LNKa$LNKc" "built$LNKv"

_lf_checkout "$LNKD/noref" ck $((LNKN - 30 * LNKDAY)); LNKR="$LF_REPO"
_lf_commit "$LNKR" $((LNKN - LNKDAY)) $'engine: x\n\nFelix-Lane: capability\n' engine/x.sh && LNKa=built || LNKa="not built"
_lf_run "$LNKD/noref-h" "$LNKR" "$LNKN" "$FELIX" lane
is "lane command: an unknown line in human form reads <lane>: unknown, the reason, the last change, and the ref at -" \
   "$LNKa|$LF_RC|$(cat "$LNKD/noref-h.out")" \
   "built|0|capability: unknown, refs/remotes/origin/main cannot be read in $LNKR; $LNKCHG; refs/remotes/origin/main at -"

_lf_home "$LNKD/home-r4" ck 1792700000; LNKH4="$LF_HOME"; LNKP4="$LF_PROJ"
_lf_table "$LNKP4" 1792700100 lanes.tsv $'capability\t^engine/\t1/2\n' && LNKa=built || LNKa="not built"
_lf_use "$LNKH4" "$LNKD/memory" "$LNKD/user" "$LNKB"
_lf_run "$LNKD/r4-h" "$LNKC" "$LNKN" "$FELIX" lane
is "lane command: an R4 line in human form has lane -, and no last-change part since column 10 is -" \
   "$LNKa|$LF_RC|$(cat "$LNKD/r4-h.out")" "built|0|-: unknown, $LNKP4/lanes.tsv cannot be read as lanes.tsv; refs/remotes/origin/main at $LNKREFD"

LNKa="not built"
if ( _fx_cd "$LNKD" && _lf_g 1700000000 clone -q --depth 1 "file://$LNKH" home-shallow ) >/dev/null 2>&1; then
  LNKa="$( _fx_cd "$LNKD/home-shallow" || exit 1; [ "$(_lf_g 1700000000 rev-parse --is-shallow-repository)" = true ] \
           && _lf_g 1700000000 cat-file -e HEAD:projects/ck/lanes.tsv && echo built )"
fi
_lf_use "$LNKD/home-shallow" "$LNKD/memory" "$LNKD/user" "$LNKB"
_lf_run "$LNKD/hs-t" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command: with the home a shallow clone, column 10 reads unknown and 11 -, and the state and every other column stand" \
   "${LNKa:-not built}|$LF_RC|$(cat "$LNKD/hs-t.out")" \
   "built|0|$(_lf_tsv capability ok 1 2 14 1/2 "$LNKLASTD" "$LNKMARK" "$LNKNEXT" unknown - "$LNKREFD" -)"
_lf_run "$LNKD/hs-h" "$LNKC" "$LNKN" "$FELIX" lane
is "lane command: with the home a shallow clone, the human line says its lanes.tsv row's last change cannot be read" \
   "${LNKa:-not built}|$LF_RC|$(cat "$LNKD/hs-h.out")" \
   "built|0|capability: ok, 1 of 2 engine landings in 14 days, target 1/2; last lane landing $LNKLASTD; mark $LNKMARK; next: $LNKNEXT; its lanes.tsv row's last change cannot be read; refs/remotes/origin/main at $LNKREFD"
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- the last lane landing ------------------------------------------------------------------------------------------------
_lf_checkout "$LNKD/zero" ck $((LNKN - 30 * LNKDAY)); LNKR="$LF_REPO"
_lf_chain "$LNKR" capability $((LNKN - 2 * LNKDAY)) 3600 u u && LNKa=built || LNKa="not built"
_lf_run "$LNKD/zero-t" "$LNKR" "$LNKN" "$FELIX" lane --tsv
is "lane command: with no marked engine landing anywhere on the chain, the last lane landing reads none" \
   "$LNKa|$LF_RC|$(_lf_cols "$LNKD/zero-t.out" 1 2 3 4 7)" "built|0|zero|0|2|none"
_lf_checkout "$LNKD/old" ck $((LNKN - 30 * LNKDAY)); LNKR="$LF_REPO"
_lf_commit "$LNKR" $((LNKN - 20 * LNKDAY)) $'engine: old\n\nFelix-Lane: capability\n' engine/old.sh \
  && _lf_commit "$LNKR" $((LNKN - LNKDAY)) $'engine: new\n' engine/new.sh && _lf_publish "$LNKR" && LNKa=built || LNKa="not built"
_lf_run "$LNKD/old-t" "$LNKR" "$LNKN" "$FELIX" lane --tsv
is "lane command: a lane landing twenty days back is out of the window and is still the last lane landing: zero, L 0 of T 1, its date in column 7" \
   "$LNKa|$LF_RC|$(_lf_cols "$LNKD/old-t.out" 1 2 3 4 7)" "built|0|zero|0|1|$(_lf_iso $((LNKN - 20 * LNKDAY)))"

# C11's worked expectation: B root at -50 d, M the only marked landing at -40 d (engine/m), N docs/n at -39 d, W engine/w
# at -1 d; M's root tree removed, which only the last-landing search reads.
_lf_checkout "$LNKD/tree" ck $((LNKN - 50 * LNKDAY)); LNKR="$LF_REPO"; LNKa="not built"
if _lf_commit "$LNKR" $((LNKN - 40 * LNKDAY)) $'engine: m\n\nFelix-Lane: capability\n' engine/m && LNKM="$LF_SHA" \
   && _lf_commit "$LNKR" $((LNKN - 39 * LNKDAY)) $'docs: n\n' docs/n && LNKNS="$LF_SHA" \
   && _lf_commit "$LNKR" $((LNKN - LNKDAY)) $'engine: w\n' engine/w && _lf_publish "$LNKR"; then
  LNKb="$( _fx_cd "$LNKR" || exit 1; printf '%s %s' "$(_lf_g 1700000000 rev-parse "$LNKM^{tree}")" "$(_lf_g 1700000000 rev-parse "$LNKNS^{tree}")" )"
  if [ "${LNKb% *}" != "${LNKb#* }" ] && _lf_unobject "$LNKR" "$LNKM^{tree}"; then
    ( _fx_cd "$LNKR" && _lf_g 1700000000 cat-file -e "${LNKb% *}" ) >/dev/null 2>&1 || LNKa=built
  fi
fi
_lf_run "$LNKD/tree-t" "$LNKR" "$LNKN" "$FELIX" lane --tsv
is "lane command: with M's root tree gone, which only the last-landing search reads, column 7 reads unknown and the state stays zero, L 0 of T 1, columns 10 to 13 as before" \
   "$LNKa|$LF_RC|$(cat "$LNKD/tree-t.out")" \
   "built|0|$(_lf_tsv capability zero 0 1 14 1/2 unknown "$LNKMARK" "$LNKNEXT" "$LNKTAB" "$LNKTABISO" "$(_lf_iso $((LNKN - LNKDAY)))" -)"
_lf_run "$LNKD/tree-h" "$LNKR" "$LNKN" "$FELIX" lane
is "lane command: with M's root tree gone, the human line reads last lane landing unknown and the state zero" \
   "$LNKa|$LF_RC|$(cat "$LNKD/tree-h.out")" \
   "built|0|capability: zero, 0 of 1 engine landings in 14 days, target 1/2; last lane landing unknown; mark $LNKMARK; next: $LNKNEXT; $LNKCHG; refs/remotes/origin/main at $(_lf_iso $((LNKN - LNKDAY)))"
_lf_run "$LNKD/tree-s" "$LNKR" "$LNKN" "$FELIX" status --tsv
is "lane command: with M's root tree gone, the status row still reads the value zero, 0 of 1 engine landings in 14 days, target 1/2" \
   "$LNKa|$LF_RC|$(_lf_last "$LNKD/tree-s.out")" "built|0|$(_lf_tsv lane value zero '0 of 1 engine landings in 14 days, target 1/2')"

# ---- next: none and unknown, never a state ---------------------------------------------------------------------------------
_lf_home "$LNKD/home-next" ck 1792700000; LNKH6="$LF_HOME"; LNKP6="$LF_PROJ"
_lf_table "$LNKP6" 1792700100 lanes.tsv "$LNKLANES"; LNKa="${LF_SHA:+built}"
_lf_use "$LNKH6" "$LNKD/memory" "$LNKD/user" "$LNKB"
# LABEL WANT -> columns 2, 3, 4 and 9 of felix lane --tsv in C read ok, 1, 2 and WANT.
_lnk_next() {
  _lf_run "$LNKD/next" "$LNKC" "$LNKN" "$FELIX" lane --tsv
  is "lane command: $1: next reads $2 and the state stays ok, L 1 of T 2" "${LNKa:-not built}|$LF_RC|$(_lf_cols "$LNKD/next.out" 1 2 3 4 9)" "built|0|ok|1|2|$2"
}
_lnk_next "no lane-next.tsv committed" none
printf '%s' "$LNKNEXTS" > "$LNKP6/lane-next.tsv"
_lnk_next "a lane-next.tsv in the home's working tree, never committed" none
_lf_table "$LNKP6" 1792700200 lane-next.tsv "$LNKNEXTS" || LNKa=""
_lnk_next "one committed row for the lane" "$LNKNEXT"
_lf_table "$LNKP6" 1792700300 lane-next.tsv "$LNKNEXTS$(_lf_tsv capability 'a second item')"$'\n' || LNKa=""
_lnk_next "two committed rows for the lane" unknown
_lf_table "$LNKP6" 1792700400 lane-next.tsv "$(_lf_tsv capability "$LNKNEXT")"$'\r\n' || LNKa=""
_lnk_next "a committed lane-next.tsv the shape check refuses, a CR in its row" unknown
_lf_table "$LNKP6" 1792700500 lane-next.tsv "$(_lf_tsv docs 'a lane this table does not hold')"$'\n' || LNKa=""
_lnk_next "a committed lane-next.tsv whose only row names a lane lanes.tsv does not hold" none

# ---- the last change of a lane's row ----------------------------------------------------------------------------------------
_lf_home "$LNKD/home-chg" ck 1792700000; LNKH5="$LF_HOME"; LNKP5="$LF_PROJ"; LNKa=built
_lf_use "$LNKH5" "$LNKD/memory" "$LNKD/user" "$LNKB"
_lf_table "$LNKP5" 1792710000 lanes.tsv "$LNKLANES" && LNKA="$LF_SHA" || LNKa="not built"
_lf_run "$LNKD/chg-a" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command: after commit A adds the lane's row, columns 10 and 11 name A and its committer date" \
   "$LNKa|$LF_RC|$(_lf_cols "$LNKD/chg-a.out" 1 1 10 11)" "built|0|capability|${LNKA:-A}|$(_lf_iso 1792710000)"
_lf_run "$LNKD/chg-ah" "$LNKC" "$LNKN" "$FELIX" lane
is "lane command: after commit A, the human line names A's first twelve characters and its date" \
   "$LNKa|$LF_RC|$(cat "$LNKD/chg-ah.out")" \
   "built|0|capability: ok, 1 of 2 engine landings in 14 days, target 1/2; last lane landing $LNKLASTD; mark $LNKMARK; next: none; its lanes.tsv row last changed by $(printf '%.12s' "$LNKA") at $(_lf_iso 1792710000); refs/remotes/origin/main at $LNKREFD"
_lf_table "$LNKP5" 1792720000 lanes.tsv $'# The lanes, reworded.\ncapability\t^engine/\t1/2\t14\n' || LNKa="not built"
_lf_table "$LNKP5" 1792730000 lanes.tsv $'# The lanes, reworded.\ncapability\t^engine/\t1/2\t14\ndocs\t^docs/\t1/2\t14\n' && LNKC3="$LF_SHA" || LNKa="not built"
_lf_commit "$LNKP5" 1792740000 $'notes beside the tables\n' notes.md || LNKa="not built"
_lf_run "$LNKD/chg-d" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command: commits that change only a comment line, another lane's row and another file leave capability's columns 10 and 11 at A; the other lane names its own commit" \
   "$LNKa|$LF_RC|$(_lf_cols "$LNKD/chg-d.out" 1 1 10 11)|$(_lf_cols "$LNKD/chg-d.out" 2 1 10 11)" \
   "built|0|capability|${LNKA:-A}|$(_lf_iso 1792710000)|docs|${LNKC3:-C}|$(_lf_iso 1792730000)"
_lf_table "$LNKP5" 1792750000 lanes.tsv $'# The lanes, reworded.\ncapability\t^engine/\t1/4\t14\ndocs\t^docs/\t1/2\t14\n' && LNKE="$LF_SHA" || LNKa="not built"
_lf_run "$LNKD/chg-e" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command: commit E lowers capability's share to 1/4: columns 10 and 11 name E and its date, and the other lane's stay" \
   "$LNKa|$LF_RC|$(_lf_cols "$LNKD/chg-e.out" 1 1 6 10 11)|$(_lf_cols "$LNKD/chg-e.out" 2 1 10 11)" \
   "built|0|capability|1/4|${LNKE:-E}|$(_lf_iso 1792750000)|docs|${LNKC3:-C}|$(_lf_iso 1792730000)"
LNKa="not built"; LNKh="$LNKD/home-root"
if _lf_init "$LNKh" && mkdir -p "$LNKh/projects/ck"; then
  printf '{"name":"ck","gate":"true"}\n' > "$LNKh/projects/ck/project.json"; printf '# ck\n' > "$LNKh/projects/ck/CLAUDE.md"
  printf '%s' "$LNKLANES" > "$LNKh/projects/ck/lanes.tsv"
  _lf_commit "$LNKh" 1792760000 $'the home, its lane table from the start\n' =projects/ck/project.json =projects/ck/CLAUDE.md =projects/ck/lanes.tsv \
    && LNKRT="$LF_SHA" && LNKa=built
fi
_lf_use "$LNKh" "$LNKD/memory" "$LNKD/user" "$LNKB"
_lf_run "$LNKD/chg-r" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command: in a home whose root commit holds the row, columns 10 and 11 name the root and its date" \
   "$LNKa|$LF_RC|$(_lf_cols "$LNKD/chg-r.out" 1 1 10 11)" "built|0|capability|${LNKRT:-root}|$(_lf_iso 1792760000)"
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- the review's F6: a last change that cannot be read is unknown, never another commit (C5 column 10, C3) ----------
# Added on 2026-10-30 from the adversarial review of the first build, still blind. Column 10 is unknown when git could
# not finish its search, a read that did not finish never yields a value (C3), and a commit that changes only a comment
# line does not move the column. A home's history: A adds the row (share 1/2), B changes it (1/3), C adds only a comment
# line; with every object there, column 10 names B, and the checkout C reads ok, L 1 of T 2 at 1/3. (i) B's lanes.tsv
# blob, a loose object only the search reads, is removed. (ii) In a second home of the same history, then D adding
# notes.md, C's root tree, which only the search reads, is removed. The state and every other column stand.
LNKF6L1=$'capability\t^engine/\t1/2\t14\n'; LNKF6L2=$'capability\t^engine/\t1/3\t14\n'
LNKF6L3=$'# The lanes, with a comment.\ncapability\t^engine/\t1/3\t14\n'
LNKF6LINE="$(_lf_tsv capability ok 1 2 14 1/3 "$LNKLASTD" "$LNKMARK" none unknown - "$LNKREFD" -)"
# DIR -> a home at DIR (project ck), its history A, B and C as above. LNKF6H the home, LNKF6B B and LNKF6C C, empty
# when not made.
_lnk_f6home() {
  LNKF6H=""; LNKF6B=""; LNKF6C=""
  _lf_home "$1" ck 1792700000 || return 1
  _lf_table "$LF_PROJ" 1792780000 lanes.tsv "$LNKF6L1" || return 1
  _lf_table "$LF_PROJ" 1792781000 lanes.tsv "$LNKF6L2" || return 1
  LNKF6B="$LF_SHA"
  _lf_table "$LF_PROJ" 1792782000 lanes.tsv "$LNKF6L3" || return 1
  LNKF6C="$LF_SHA"; LNKF6H="$LF_HOME"
}
# HOME REV -> 0 when REV names an object HOME's repository can read.
_lnk_has() { ( _fx_cd "$1" && _lf_g 1700000000 cat-file -e "$2" ) >/dev/null 2>&1; }
LNKa="not built: F6 (i)"; LNKb=""
if _lnk_f6home "$LNKD/home-f6"; then
  _lf_use "$LNKF6H" "$LNKD/memory" "$LNKD/user" "$LNKB"
  _lf_run "$LNKD/f6-0" "$LNKC" "$LNKN" "$FELIX" lane --tsv; LNKb="$(_lf_cols "$LNKD/f6-0.out" 1 10)"
  _lf_unobject "$LNKF6H" "$LNKF6B:projects/ck/lanes.tsv" && ! _lnk_has "$LNKF6H" "$LNKF6B:projects/ck/lanes.tsv" \
    && _lnk_has "$LNKF6H" "$LNKF6C:projects/ck/lanes.tsv" && _lnk_has "$LNKF6H" "HEAD:projects/ck/lanes.tsv" && LNKa=built
fi
_lf_run "$LNKD/f6-i" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command F6-column-10-names-a-wrong-commit-when-history-objects-are-missing: with B's lanes.tsv blob gone from the home, column 10 reads unknown and 11 -, never C, the comment-only commit; with it there, column 10 named B; the state ok and every other column stand" \
   "$LNKa|before ${LNKb:-none}|$LF_RC|$(cat "$LNKD/f6-i.out")" "built|before ${LNKF6B:-B}|0|$LNKF6LINE"
_lf_run "$LNKD/f6-ih" "$LNKC" "$LNKN" "$FELIX" lane
is "lane command F6-column-10-names-a-wrong-commit-when-history-objects-are-missing: with B's lanes.tsv blob gone, the human line says its lanes.tsv row's last change cannot be read" \
   "$LNKa|$LF_RC|$(cat "$LNKD/f6-ih.out")" \
   "built|0|capability: ok, 1 of 2 engine landings in 14 days, target 1/3; last lane landing $LNKLASTD; mark $LNKMARK; next: none; its lanes.tsv row's last change cannot be read; refs/remotes/origin/main at $LNKREFD"
LNKa="not built: F6 (ii)"; LNKb=""
if _lnk_f6home "$LNKD/home-f6t" && _lf_commit "$LNKF6H" 1792783000 $'notes beside the tables\n' notes.md; then
  _lf_use "$LNKF6H" "$LNKD/memory" "$LNKD/user" "$LNKB"
  _lf_run "$LNKD/f6-1" "$LNKC" "$LNKN" "$FELIX" lane --tsv; LNKb="$(_lf_cols "$LNKD/f6-1.out" 1 10)"
  _lf_unobject "$LNKF6H" "$LNKF6C^{tree}" && ! _lnk_has "$LNKF6H" "$LNKF6C^{tree}" && _lnk_has "$LNKF6H" "HEAD^{tree}" \
    && _lnk_has "$LNKF6H" "HEAD:projects/ck/lanes.tsv" && LNKa=built
fi
_lf_run "$LNKD/f6-ii" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command F6-column-10-names-a-wrong-commit-when-history-objects-are-missing: with C's root tree gone from the home, below D, which adds notes.md, column 10 reads unknown and 11 -, never D; with it there, column 10 named B; the state ok and every other column stand" \
   "$LNKa|before ${LNKb:-none}|$LF_RC|$(cat "$LNKD/f6-ii.out")" "built|before ${LNKF6B:-B}|0|$LNKF6LINE"
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- partial clones: the review's F6 (no object fetched, a search that cannot finish is unknown) and F3 (an old git) ---
# Added on 2026-10-30 from the adversarial review of the first build, still blind. The source S is self-governed (C9):
# its root holds .felix (ck), then lanes.tsv commits A (share 1/2), B (1/3) and C (a comment line only), then E, one
# unmarked engine landing a day before the clock; uploadpack.allowFilter lets it serve partial clones. Each clone is the
# home and the checkout; its refs/remotes/origin/main is S's main. Its remote.origin.uploadpack is a logger that writes
# a line and fails, so a fetch is seen and fetches nothing, and nothing reaches a network. In a --filter=blob:none clone
# B's lanes.tsv blob is missing and HEAD's is there; in a --filter=tree:0 clone C's root tree is missing.
# - F6, with the suite's git: the blobless clone reads zero, L 0 of T 1, column 10 unknown, never C; the tree:0 clone
#   reads unknown with R2 (E's changed paths need C's tree), column 10 unknown, never E. Nothing is fetched.
# - F3: a git before 2.44 ignores GIT_NO_LAZY_FETCH (C3). The stand-in, first on PATH, says git version 2.43.0, refuses
#   --no-lazy-fetch as such a git does, and drops GIT_NO_LAZY_FETCH before it runs the suite's git. (a) In the blobless
#   clone a partial clone is not read: R2, column 10 unknown. (b) A full clone of S as the checkout, the blobless clone
#   as the home: the full clone is counted, zero, L 0 of T 1, and column 10 is unknown. Column 12 is not compared in
#   (a): C3 does not say whether the ref's date is read there. Nothing is fetched in either.
LNKRG="$(type -P git)"; LNKFL="$LNKD/fetch.log"; LNKa="not built: the partial clones"
mkdir -p "$LNKD/oldgit"
printf '#!/bin/sh\nprintf '"'"'upload-pack ran: %%s\\n'"'"' "$*" >> %s\nexit 1\n' "$(printf '%q' "$LNKFL")" > "$LNKD/logger"
{ printf '#!/bin/bash\n# A git that says it is 2.43.0: it refuses --no-lazy-fetch and ignores GIT_NO_LAZY_FETCH, as git before 2.44 does.\n'
  printf 's=0\nfor a in "$@"; do\n  if [ "$s" = 1 ]; then s=0; continue; fi\n  case "$a" in\n'
  printf '    --version|version) printf '"'"'git version 2.43.0\\n'"'"'; exit 0 ;;\n'
  printf '    --no-lazy-fetch) printf '"'"'unknown option: --no-lazy-fetch\\n'"'"' >&2; exit 129 ;;\n'
  printf '    -c|-C) s=1 ;;\n    -*) ;;\n    *) break ;;\n  esac\ndone\nunset GIT_NO_LAZY_FETCH\nexec %s "$@"\n' "$(printf '%q' "$LNKRG")"; } > "$LNKD/oldgit/git"
chmod +x "$LNKD/logger" "$LNKD/oldgit/git"
LNKS=""
if [ -n "$LNKRG" ] && _lf_self "$LNKD/pc-src" ck $((LNKN - 40 * LNKDAY)); then
  LNKS="$LF_HOME"
  _lf_table "$LF_PROJ" $((LNKN - 35 * LNKDAY)) lanes.tsv "$LNKF6L1" && _lf_table "$LF_PROJ" $((LNKN - 30 * LNKDAY)) lanes.tsv "$LNKF6L2" \
    && LNKPB="$LF_SHA" && _lf_table "$LF_PROJ" $((LNKN - 20 * LNKDAY)) lanes.tsv "$LNKF6L3" && LNKPC="$LF_SHA" \
    && _lf_commit "$LNKS" $((LNKN - LNKDAY)) $'engine: e\n\nNo mark.\n' engine/e.sh && LNKPE="$LF_SHA" \
    && ( _fx_cd "$LNKS" && _lf_g 1700000000 config uploadpack.allowFilter true ) >/dev/null 2>&1 || LNKS=""
fi
# NAME [FILTER] -> a clone of S at $LNKD/NAME (with --filter=FILTER), its uploadpack the logger; 0 when it holds
# refs/remotes/origin/main at E, and a partial one is a promisor.
_lnk_clone() {
  [ -n "$LNKS" ] || return 1
  ( unset GIT_NO_LAZY_FETCH; _fx_cd "$LNKD" && _lf_g 1700000000 clone -q ${2:+"--filter=$2"} "file://$LNKS" "$1" ) >/dev/null 2>&1 || return 1
  ( _fx_cd "$LNKD/$1" || exit 1; _lf_g 1700000000 config remote.origin.uploadpack "$LNKD/logger" || exit 1
    [ "$(_lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main)" = "$LNKPE" ] || exit 1
    [ -z "${2:-}" ] || [ "$(_lf_g 1700000000 config --get remote.origin.promisor)" = true ] ) >/dev/null 2>&1
}
# NAME REV -> 0 when the clone NAME can read REV without fetching it.
_lnk_lazy() { ( _fx_cd "$LNKD/$1" && GIT_NO_LAZY_FETCH=1 _lf_g 1700000000 cat-file -e "$2" ) >/dev/null 2>&1; }
_lnk_clone pc-blob blob:none && _lnk_clone pc-tree tree:0 && _lnk_clone pc-full \
  && ! _lnk_lazy pc-blob "$LNKPB:projects/ck/lanes.tsv" && _lnk_lazy pc-blob "HEAD:projects/ck/lanes.tsv" \
  && ! _lnk_lazy pc-tree "$LNKPC^{tree}" && _lnk_lazy pc-tree "HEAD:projects/ck/lanes.tsv" \
  && _lnk_lazy pc-full "$LNKPB:projects/ck/lanes.tsv" && [ ! -e "$LNKFL" ] \
  && [ "$("$LNKD/oldgit/git" --version)" = 'git version 2.43.0' ] && LNKa=built
LNKPBD="$(_lf_iso $((LNKN - LNKDAY)))"
# The suite's own git must be 2.44 or later: before it, C3 reads every partial clone as R2, and GIT_NO_LAZY_FETCH, which
# the checks above lean on, does not exist. Then these assertions skip, with the version.
LNKRGV="$("$LNKRG" --version 2>/dev/null)"
LNKGV="$(printf '%s\n' "$LNKRGV" | LC_ALL=C awk '{ n = split($3, v, "."); s = "old"; if (n >= 2 && (v[1] + 0 > 2 || (v[1] + 0 == 2 && v[2] + 0 >= 44))) s = "new"; print s }')"
_lnk_is() { if [ "$LNKGV" = new ]; then is "$1" "$2" "$3"; else skip "$1" "the suite's git says [$LNKRGV], before 2.44, where C3 reads a partial clone as R2"; fi; }
# OUT DIR HOME [PATH-FIRST] -> felix lane --tsv run from $LNKD/DIR with the home $LNKD/HOME (and PATH-FIRST before the
# stubs on PATH), the fetch log cleared first; LNKf "fetch[<what the logger wrote>]".
_lnk_pc() {
  rm -f "$LNKFL"
  _lf_use "$LNKD/$3" "$LNKD/memory" "$LNKD/user" "$LNKB"
  if [ -n "${4:-}" ]; then _lf_run "$LNKD/$1" "$LNKD/$2" "$LNKN" PATH="$4:$LNKB:$PATH" "$FELIX" lane --tsv
  else _lf_run "$LNKD/$1" "$LNKD/$2" "$LNKN" "$FELIX" lane --tsv; fi
  LNKf="fetch[$(cat "$LNKFL" 2>/dev/null)]"
}
_lnk_pc pc-b pc-blob pc-blob
_lnk_is "lane command F6-column-10-names-a-wrong-commit-when-history-objects-are-missing: a --filter=blob:none clone as home and checkout reads zero, L 0 of T 1, column 10 unknown and 11 -, never C, the comment-only commit, and fetches nothing" \
   "$LNKa|$LNKf|$LF_RC|$(cat "$LNKD/pc-b.out")" \
   "built|fetch[]|0|$(_lf_tsv capability zero 0 1 14 1/3 none "$LNKMARK" none unknown - "$LNKPBD" -)"
_lnk_pc pc-t pc-tree pc-tree
_lnk_is "lane command F6-column-10-names-a-wrong-commit-when-history-objects-are-missing L-NEVER-OK: a --filter=tree:0 clone as home and checkout reads unknown with R2, column 10 unknown and 11 -, never E, the latest landing, and fetches nothing" \
   "$LNKa|$LNKf|$LF_RC|$(cat "$LNKD/pc-t.out")" \
   "built|fetch[]|0|$(_lf_tsv capability unknown - - 14 1/3 - "$LNKMARK" none unknown - "$LNKPBD" \
      "git could not read the landings on refs/remotes/origin/main in $LNKD/pc-tree")"
_lnk_pc pc-oa pc-blob pc-blob "$LNKD/oldgit"
_lnk_is "lane command F3-old-git-lazy-fetch-through-the-home L-NEVER-OK: (a) with a git that says 2.43.0, the --filter=blob:none clone as home and checkout is not read: unknown with R2, column 10 unknown, and nothing is fetched" \
   "$LNKa|$LNKf|$LF_RC|$(_lf_count "$LNKD/pc-oa.out")|$(_lf_cols "$LNKD/pc-oa.out" 1 1 2 3 4 5 6 7 8 9 10 11 13)" \
   "built|fetch[]|0|1|capability|unknown|-|-|14|1/3|-|$LNKMARK|none|unknown|-|git could not read the landings on refs/remotes/origin/main in $LNKD/pc-blob"
_lnk_pc pc-ob pc-full pc-blob "$LNKD/oldgit"
_lnk_is "lane command F3-old-git-lazy-fetch-through-the-home: (b) with a git that says 2.43.0, a full clone as the checkout and the --filter=blob:none clone as the home: zero, L 0 of T 1, column 10 unknown and 11 -, and nothing is fetched" \
   "$LNKa|$LNKf|$LF_RC|$(_lf_count "$LNKD/pc-ob.out")|$(_lf_cols "$LNKD/pc-ob.out" 1 1 2 3 4 10 11 13)" \
   "built|fetch[]|0|1|capability|zero|0|1|unknown|-|-"
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- the review's F9: a next text that is exactly none or unknown (C1) ------------------------------------------------
# Added on 2026-10-30 from the review's second amendment, still blind. C1: such a cell cannot be told from those two
# values, and column 9 prints it as given. In a home of its own, lanes.tsv as H's, then lane-next.tsv committed with
# one row for capability whose next cell is exactly unknown, then exactly none: column 9 and the human line's next read
# the word, and the state stays ok, L 1 of T 2.
_lf_home "$LNKD/home-f9" ck 1792700000; LNKP9="$LF_PROJ"; LNKa="not built: F9's home"; LNKF9T=""
_lf_table "$LNKP9" 1792700100 lanes.tsv "$LNKLANES" && LNKF9T="$LF_SHA" && LNKa="$LNKBUILT"
_lf_use "$LF_HOME" "$LNKD/memory" "$LNKD/user" "$LNKB"
# WORD T -> lane-next.tsv holding capability<TAB>WORD, committed at T in F9's home; then felix lane --tsv and felix lane in C.
_lnk_f9() {
  local b="$LNKa" w
  w="$(_lf_tsv capability "$1")"$'\n'
  _lf_table "$LNKP9" "$2" lane-next.tsv "$w" || b="not built: lane-next.tsv $1"
  printf '%s' "$w" > "$LNKD/f9.want"
  ( _fx_cd "$LNKP9" || exit 1; _lf_g 1700000000 cat-file blob HEAD:projects/ck/lane-next.tsv ) > "$LNKD/f9.got" 2>/dev/null
  cmp -s "$LNKD/f9.want" "$LNKD/f9.got" || b="not built: lane-next.tsv $1 is not at HEAD"
  _lf_run "$LNKD/f9-$1-t" "$LNKC" "$LNKN" "$FELIX" lane --tsv; LNKb="$LF_RC|$(_lf_count "$LNKD/f9-$1-t.out")|$(_lf_cols "$LNKD/f9-$1-t.out" 1 1 2 3 4 9)"
  _lf_run "$LNKD/f9-$1-h" "$LNKC" "$LNKN" "$FELIX" lane
  is "lane command F9-next-text-none-or-unknown-literally: a committed lane-next.tsv whose one row for the lane has next exactly $1: column 9 prints $1 as the cell gives it, the human line says next: $1, and the state stays ok, L 1 of T 2" \
     "$b|$LNKb|$LF_RC|$(cat "$LNKD/f9-$1-h.out")" \
     "built|0|1|capability|ok|1|2|$1|0|capability: ok, 1 of 2 engine landings in 14 days, target 1/2; last lane landing $LNKLASTD; mark $LNKMARK; next: $1; its lanes.tsv row last changed by $(printf '%.12s' "$LNKF9T") at $(_lf_iso 1792700100); refs/remotes/origin/main at $LNKREFD"
}
_lnk_f9 unknown 1792700200
_lnk_f9 none 1792700300
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- the review's F11: a window of one day reads 1 day (the Contracts' preamble) --------------------------------------
# Added on 2026-10-30 from the review's second amendment, still blind. In a home of its own, lanes.tsv with window 1 and
# lane-next.tsv as H's: C's landings are three, two and exactly one day back, so none is in (now - 86400, now] and the
# lane reads idle, 0 of 0; the last lane landing is still the marked one three days back.
_lf_home "$LNKD/home-f11" ck 1792700000; LNKP11="$LF_PROJ"; LNKa="not built: F11's home"; LNKF11T=""
_lf_table "$LNKP11" 1792700100 lanes.tsv $'capability\t^engine/\t1/2\t1\n' && LNKF11T="$LF_SHA" \
  && _lf_table "$LNKP11" 1792700200 lane-next.tsv "$LNKNEXTS" && LNKa="$LNKBUILT"
_lf_use "$LF_HOME" "$LNKD/memory" "$LNKD/user" "$LNKB"
_lf_run "$LNKD/f11-t" "$LNKC" "$LNKN" "$FELIX" lane --tsv; LNKb="$LF_RC|$(_lf_cols "$LNKD/f11-t.out" 1 1 2 3 4 5 6)"
_lf_run "$LNKD/f11-h" "$LNKC" "$LNKN" "$FELIX" lane
is "lane command F11-one-day-reads-1-days: with window 1 the human line says in 1 day, never 1 days: capability: idle, 0 of 0 engine landings in 1 day, target 1/2, and the rest of the line as C5 builds it" \
   "$LNKa|$LNKb|$LF_RC|$(cat "$LNKD/f11-h.out")" \
   "built|0|capability|idle|0|0|1|1/2|0|capability: idle, 0 of 0 engine landings in 1 day, target 1/2; last lane landing $LNKLASTD; mark $LNKMARK; next: $LNKNEXT; its lanes.tsv row last changed by $(printf '%.12s' "$LNKF11T") at $(_lf_iso 1792700100); refs/remotes/origin/main at $LNKREFD"
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- L-DET -------------------------------------------------------------------------------------------------------------------
for LNKk in 1 2; do
  _lf_run "$LNKD/det-h$LNKk" "$LNKC" "$LNKN" "$FELIX" lane
  _lf_run "$LNKD/det-t$LNKk" "$LNKC" "$LNKN" "$FELIX" lane --tsv
  _lf_run "$LNKD/det-s$LNKk" "$LNKC" "$LNKN" "$FELIX" status --tsv
done
LNKa=""
for LNKk in det-h det-t det-s; do cmp -s "$LNKD/${LNKk}1.out" "$LNKD/${LNKk}2.out" && LNKa="$LNKa|same" || LNKa="$LNKa|differ"; done
is "lane command L-DET: two runs each of felix lane, felix lane --tsv and felix status --tsv print identical bytes, the expected human line, TSV line and lane row" \
   "$LNKBUILT$LNKa|$(cat "$LNKD/det-h1.out")|$(cat "$LNKD/det-t1.out")|$(_lf_last "$LNKD/det-s1.out")" \
   "built|same|same|same|$LNKHUMAN|$LNKLINE|$LNKROW"

# ---- L-RO and the uncommitted edit ------------------------------------------------------------------------------------------
# LABEL -> a marker touched a second after the last write, then felix lane, felix lane --tsv and felix status --tsv in C;
# what they left newer under H, the memory root and C (.git included), and C's refs and worktree list before and after.
_lnk_ro() {
  local f="$LNKD/ro" r1 r2 w1 w2 nw
  sleep 1; touch "$f.marker"
  r1="$( _fx_cd "$LNKC" && _lf_g 1700000000 for-each-ref )"; w1="$( _fx_cd "$LNKC" && _lf_g 1700000000 worktree list --porcelain )"
  _lf_run "$f-h" "$LNKC" "$LNKN" "$FELIX" lane
  _lf_run "$f-t" "$LNKC" "$LNKN" "$FELIX" lane --tsv
  _lf_run "$f-s" "$LNKC" "$LNKN" "$FELIX" status --tsv
  r2="$( _fx_cd "$LNKC" && _lf_g 1700000000 for-each-ref )"; w2="$( _fx_cd "$LNKC" && _lf_g 1700000000 worktree list --porcelain )"
  nw="$(find "$LNKH" "$LNKD/memory" "$LNKC" -newer "$f.marker" 2>&1)"
  is "lane command L-RO: $1: felix lane and felix status leave nothing newer under the home, the memory root and the checkout, its refs and worktree list unchanged, and print the expected lines" \
     "$LNKBUILT|newer[${nw}]|$([ -n "$r1" ] && [ "$r1" = "$r2" ] && echo same || echo changed)|$([ -n "$w1" ] && [ "$w1" = "$w2" ] && echo same || echo changed)|$(cat "$f-h.out")|$(cat "$f-t.out")|$(_lf_last "$f-s.out")" \
     "built|newer[]|same|same|$LNKHUMAN|$LNKLINE|$LNKROW"
}
_lnk_ro "as built"
touch "$LNKP/lanes.tsv"
_lnk_ro "after touch of lanes.tsv, its content unchanged"
printf '%s' $'# The lanes this fixture counts.\ncapability\t^engine/\t1/4\t7\n' > "$LNKP/lanes.tsv"
printf '%s' "$(_lf_tsv capability 'an item never committed')"$'\n' > "$LNKP/lane-next.tsv"
_lnk_ro "after uncommitted edits to lanes.tsv (share 1/4, window 7) and lane-next.tsv"
rm -f "$LNKP/lanes.tsv"
_lf_run "$LNKD/gone" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command: with lanes.tsv deleted from the home's working tree and still committed, felix lane --tsv prints the committed row's line unchanged" \
   "$LNKBUILT|$LF_RC|$(cat "$LNKD/gone.out")" "built|0|$LNKLINE"
printf '%s' "$LNKLANES" > "$LNKP/lanes.tsv"; printf '%s' "$LNKNEXTS" > "$LNKP/lane-next.tsv"

# ---- the second review's round 1: next, dates, an old git's partial home, a log encoding, a closed stdout ------------
# Added on 2026-10-30 from the second review's findings (their inputs and observed output only), still blind, in the
# review's home-apart fixture (_lf_r2, the clock at LNKN): cap reads zero, L 0 of T 2, sec short, L 1 of T 3. R2-F5 and
# R2-F6 are the review's fork probes (_lf_fork): at the read of a lane's next text (awk, its words holding lane=cap,
# _lane_next on the stack) and at each formatting of a date (date, its words holding -r, _lane_iso on the stack), the
# names being inputs of the findings, not read from the engine. Each assertion also compares the command without the
# fault or the setting, so it is red on main, which prints no lane. Readings:
# - R2-F5: column 9 is the next text or unknown (C5), and C3 makes every next unknown when a read of lane-next.tsv does
#   not finish, so sec's may read unknown too; every other column stands, and the human line is built from the columns.
# - R2-F6: a printed line keeps column 12, the ref's date (C5 fills columns 10 to 12 on every line); column 7 may read
#   unknown, columns 10 and 11 unknown and -, a line may read unknown with a reason, or the run may end as C3's count
#   that did not finish; never none for a lane landing that exists, an empty column, or - for a readable ref.
# - R2-F8: C3's git before 2.44, with the home a partial clone whose HEAD's lanes.tsv blob was never fetched: nothing
#   is fetched, and the table reads R9 (C2), as the review accepts.
# - R2-F10: i18n.logOutputEncoding or i18n.commitEncoding UTF-16, in the caller's ~/.gitconfig or as git -c, changes no
#   byte: the ref is a readable commit, so R1 (C5) is never its reading.
# - R2-F12: with its stdout closed felix lane --tsv cannot print its lines, and exit 0 says it printed them (C5); a
#   status from 1 to 124 is one felix sets, not 0 and not the shell's 125 to 127.
LNKRT="$LNKD/r2-tmp"; mkdir -p "$LNKRT"; LNKRA="not built: the second review's fixture"
_lf_r2 "$LNKD/r2" p "$LNKN" && LNKRA=built
LNKRC="$LF_REPO"; LNKRL="$LF_R2"; LNKRCAP="$LF_R2A"; LNKRCAPU="$LF_R2AU"; LNKRSEC="$LF_R2B"; LNKRSECU="$LF_R2BU"
LNKRV="$(_lf_tsv lane value zero '0 of 2 engine landings in 14 days, target 1/2')"
_lf_use "$LF_HOME" "$LNKD/memory" "$LNKD/user" "$LNKB"
# LINE... -> the human form of felix lane (C5) built from each TSV line, a newline after each.
_lnk_human() {
  printf '%s\n' "$@" | LC_ALL=C awk -F'\t' '{ c = ""
    if ($10 == "unknown") c = "; its lanes.tsv row" sprintf("%c", 39) "s last change cannot be read"
    else if ($10 != "-") c = "; its lanes.tsv row last changed by " substr($10, 1, 12) " at " $11
    if ($2 == "unknown") { printf "%s: unknown, %s%s; refs/remotes/origin/main at %s\n", $1, $13, c, $12; next }
    printf "%s: %s, %s of %s engine landings in %s %s, target %s; last lane landing %s; mark %s; next: %s%s; refs/remotes/origin/main at %s\n", $1, $2, $3, $4, $5, ($5 == "1" ? "day" : "days"), $6, $7, $8, $9, c, $12 }'
}
_lf_run "$LNKD/r2-t0" "$LNKRC" "$LNKN" "$FELIX" lane --tsv; LNKRU0="$LF_RC|$(cat "$LNKD/r2-t0.out")"
_lf_run "$LNKD/r2-h0" "$LNKRC" "$LNKN" "$FELIX" lane; LNKRH0="$LF_RC|$(cat "$LNKD/r2-h0.out")"
_lf_run "$LNKD/r2-s0" "$LNKRC" "$LNKN" "$FELIX" status --tsv; LNKRS0="$LF_RC|$(_lf_last "$LNKD/r2-s0.out")"

# R2-F5: a fork that fails in the read of cap's next text.
_lf_fork fork awk '*lane=cap*' "*' _lane_next '*" "$LNKD/r2f5-t.fired" "$LNKRT" _lf_run "$LNKD/r2f5-t" "$LNKRC" "$LNKN" "$FELIX" lane --tsv
LNKa="status $LF_RC, stdout [$(cat "$LNKD/r2f5-t.out")]"
for LNKx in "$LNKRCAP" "$LNKRCAPU"; do for LNKy in "$LNKRSEC" "$LNKRSECU"; do
  [ "$LF_RC|$(cat "$LNKD/r2f5-t.out")" != "0|$LNKx"$'\n'"$LNKy" ] || LNKa="next or unknown"
done; done
is "lane command R2-F5-next-cell-empties-and-shifts-columns: a fork that fails in the read of cap's next text: felix lane --tsv exits 0 with cap's column 9 cap next item or unknown, never empty, sec's its own text or unknown, and every other column of both lines as without the fault" \
   "$LNKRA|unfaulted $LNKRU0|$LF_FIRE|$LNKa" "built|unfaulted 0|$LNKRL|fired|next or unknown"
_lf_fork fork awk '*lane=cap*' "*' _lane_next '*" "$LNKD/r2f5-h.fired" "$LNKRT" _lf_run "$LNKD/r2f5-h" "$LNKRC" "$LNKN" "$FELIX" lane
LNKa="status $LF_RC, stdout [$(cat "$LNKD/r2f5-h.out")]"
for LNKx in "$LNKRCAP" "$LNKRCAPU"; do for LNKy in "$LNKRSEC" "$LNKRSECU"; do
  [ "$LF_RC|$(cat "$LNKD/r2f5-h.out")" != "0|$(_lnk_human "$LNKx" "$LNKy")" ] || LNKa="next or unknown"
done; done
is "lane command R2-F5-next-cell-empties-and-shifts-columns: the same fault in felix lane: each human line says next: and its text or unknown, then the rest as C5 builds it from the columns, never a line shifted by an empty next" \
   "$LNKRA|unfaulted $LNKRH0|$LF_FIRE|$LNKa" "built|unfaulted 0|$(_lnk_human "$LNKRCAP" "$LNKRSEC")|fired|next or unknown"

# R2-F6: a fork that fails in each formatting of a date. OUT -> "dates or unknown" when the run ended as the readings
# above accept for R2-F6, else its status and stdout.
_lnk_r2date() {
  if [ "$(_lf_ended "$1" "$LNKRC")" = ended ]; then printf 'dates or unknown'; return 0; fi
  printf '%s\n' "$LNKRL" > "$1.want"
  if [ "$LF_RC" = 0 ] && [ "$(LC_ALL=C awk -F'\t' 'NR == FNR { w[FNR] = $0; next }
      { m = FNR; k = split(w[FNR], e, "\t"); ok = (NF == 13 && k == 13 && $1 == e[1] && $12 == e[12])
        ok = ok && (($10 == e[10] && $11 == e[11]) || ($10 == "unknown" && $11 == "-"))
        kn = ($2 == e[2] && $3 == e[3] && $4 == e[4] && $5 == e[5] && $6 == e[6] && $8 == e[8] && $9 == e[9] && $13 == "-" && ($7 == e[7] || $7 == "unknown"))
        un = ($2 == "unknown" && $3 == "-" && $4 == "-" && $7 == "-" && $13 != "" && $13 != "-")
        if (ok && (kn || un)) n++ }
      END { print n + 0, m + 0 }' "$1.want" "$1.out")" = "2 2" ]; then printf 'dates or unknown'; return 0; fi
  printf 'status %s, stdout [%s]' "$LF_RC" "$(cat "$1.out")"
}
_lf_fork fork date "*' -r '*" "*' _lane_iso '*" "$LNKD/r2f6-t.fired" "$LNKRT" _lf_run "$LNKD/r2f6-t" "$LNKRC" "$LNKN" "$FELIX" lane --tsv
is "lane command R2-F6-dates-become-none-empty-or-dash L-NEVER-OK: a fork that fails in each formatting of a date: felix lane --tsv keeps column 12, the ref's date, on each line, column 7 the last lane landing's date or unknown, never none, columns 10 and 11 the commit and its date or unknown and -, or reads a line unknown with a reason, or ends as C3's count that did not finish; never an empty column" \
   "$LNKRA|unfaulted $LNKRU0|$LF_FIRE|$(_lnk_r2date "$LNKD/r2f6-t")" "built|unfaulted 0|$LNKRL|fired|dates or unknown"

# R2-F10: the caller's log encoding. LABEL ASSIGNMENT... -> as _lnk_env, in the fixture's checkout: LNKb and LNKc gain
# " [LABEL] <status>|<output>" and " [LABEL] <status>|<last row>", LNKw and LNKv the same without the setting.
_lnk_r2env() {
  local l="$1"
  shift
  _lf_run "$LNKD/r2e" "$LNKRC" "$LNKN" "$@" "$FELIX" lane --tsv
  LNKb="$LNKb [$l] $LF_RC|$(cat "$LNKD/r2e.out")"; LNKw="$LNKw [$l] 0|$LNKRL"
  _lf_run "$LNKD/r2es" "$LNKRC" "$LNKN" "$@" "$FELIX" status --tsv
  LNKc="$LNKc [$l] $LF_RC|$(_lf_last "$LNKD/r2es.out")"; LNKv="$LNKv [$l] 0|$LNKRV"
}
mkdir -p "$LNKD/r2u16a" "$LNKD/r2u16b"
printf '[i18n]\n\tlogOutputEncoding = UTF-16\n' > "$LNKD/r2u16a/.gitconfig"; printf '[i18n]\n\tcommitEncoding = UTF-16\n' > "$LNKD/r2u16b/.gitconfig"
LNKb=""; LNKc=""; LNKw=""; LNKv=""
_lnk_r2env '~/.gitconfig i18n.logOutputEncoding UTF-16' HOME="$LNKD/r2u16a"
_lnk_r2env '~/.gitconfig i18n.commitEncoding UTF-16' HOME="$LNKD/r2u16b"
_lnk_r2env 'git -c i18n.logOutputEncoding=UTF-16' GIT_CONFIG_PARAMETERS="${GIT_CONFIG_PARAMETERS:+$GIT_CONFIG_PARAMETERS }'i18n.logOutputEncoding=UTF-16'"
is "lane command R2-F10-utf16-log-encoding-reads-R1: i18n.logOutputEncoding or i18n.commitEncoding UTF-16 in the caller's ~/.gitconfig, or i18n.logOutputEncoding=UTF-16 as git -c, leave felix lane --tsv's exit 0 and its two lines as they are without it; never R1, for a ref that is a readable commit" \
   "$LNKRA|unfaulted $LNKRU0|$LNKb" "built|unfaulted 0|$LNKRL|$LNKw"
is "lane command R2-F10-utf16-log-encoding-reads-R1: the same settings leave felix status --tsv's exit 0 and its lane row the value zero 0 of 2 engine landings in 14 days, target 1/2" \
   "$LNKRA|unfaulted $LNKRS0|$LNKc" "built|unfaulted 0|$LNKRV|$LNKv"

# R2-F12: felix lane --tsv with its stdout closed, standing in for a stdout that cannot be written. Closed is a descriptor 1 not open for writing: bash 5.3
# opens a closed descriptor 1 on /dev/null, where the write succeeds, so `>&-` misses the fault; 1< a file (part 0574) fails it with EBADF on every bash.
: > "$LNKD/r2f12.ro"; LNKm="*the lane lines could not be written*"   # felix's sentence: a status alone could be sh's, from a stand-in it could not set up
_lf_run "$LNKD/r2f12" "$LNKRC" "$LNKN" /bin/sh -c "exec \"\$0\" \"\$@\" 1< \"$LNKD/r2f12.ro\"" "$FELIX" lane --tsv
case "$LF_RC:$(cat "$LNKD/r2f12.err" 2>/dev/null)" in
  ([123456789]:$LNKm|[123456789][0123456789]:$LNKm|1[01][0123456789]:$LNKm|12[01234]:$LNKm) LNKa="a status from 1 to 124" ;;
  (*) LNKa="status $LF_RC, stderr [$(cat "$LNKD/r2f12.err" 2>/dev/null)]" ;;
esac
is "lane command R2-F12-write-failure-exits-0: felix lane --tsv with its stdout closed, where its lines cannot be written, exits with a status felix sets other than 0, never 0 as though it had printed them" \
   "$LNKRA|unfaulted $LNKRU0|$LNKa" "built|unfaulted 0|$LNKRL|a status from 1 to 124"

# R2-F8: C3's git before 2.44 (the stand-in above), the home a --filter=blob:none clone of a source S8 whose later
# lanes.tsv commit (share 1/4) the home fetched with the same filter and moved main to, so HEAD's lanes.tsv blob was
# never fetched while the old file stays in its working tree; the checkout a full clone of S8, bound by its committed
# .felix. The home's remote.origin.uploadpack is the logger, set after its own fetch.
rm -f "$LNKFL"; LNK8S=""; LNK8N=""; LNKa="not built: R2-F8's partial home"
if [ -n "$LNKRG" ] && _lf_self "$LNKD/f8-src" ck $((LNKN - 40 * LNKDAY)); then
  LNK8S="$LF_HOME"; printf '%s' "$LNKF6L1" > "$LNKD/f8.want"
  _lf_table "$LF_PROJ" $((LNKN - 35 * LNKDAY)) lanes.tsv "$LNKF6L1" && _lf_commit "$LNK8S" $((LNKN - LNKDAY)) $'engine: e\n\nNo mark.\n' engine/e.sh \
    && ( _fx_cd "$LNK8S" && _lf_g 1700000000 config uploadpack.allowFilter true ) >/dev/null 2>&1 \
    && ( unset GIT_NO_LAZY_FETCH; _fx_cd "$LNKD" && _lf_g 1700000000 clone -q --filter=blob:none "file://$LNK8S" f8-home ) >/dev/null 2>&1 \
    && _lf_table "$LNK8S/projects/ck" $((LNKN - 43200)) lanes.tsv $'capability\t^engine/\t1/4\t14\n' && LNK8N="$LF_SHA" \
    && ( unset GIT_NO_LAZY_FETCH; _fx_cd "$LNKD/f8-home" || exit 1; _lf_g 1700000000 fetch -q origin \
         && _lf_g 1700000000 update-ref refs/heads/main refs/remotes/origin/main \
         && _lf_g 1700000000 config remote.origin.uploadpack "$LNKD/logger" ) >/dev/null 2>&1 \
    && ( _fx_cd "$LNKD" && _lf_g 1700000000 clone -q "file://$LNK8S" f8-full ) >/dev/null 2>&1 \
    && [ "$( _fx_cd "$LNKD/f8-home" && _lf_g 1700000000 rev-parse --verify -q HEAD )" = "$LNK8N" ] \
    && [ "$( _fx_cd "$LNKD/f8-full" && _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main )" = "$LNK8N" ] \
    && ! _lnk_lazy f8-home "HEAD:projects/ck/lanes.tsv" && cmp -s "$LNKD/f8.want" "$LNKD/f8-home/projects/ck/lanes.tsv" \
    && [ -f "$LNKD/f8-full/.felix" ] && [ ! -e "$LNKFL" ] && LNKa=built
fi
LNK8R9="$(_lf_tsv - unknown - - - - - - - - - "$(_lf_iso $((LNKN - 43200)))" "$LNKD/f8-home/projects/ck/lanes.tsv cannot be read as committed in the Felix home")"
_lnk_pc f8-t f8-full f8-home "$LNKD/oldgit"
_lnk_is "lane command R2-F8-partial-home-table-read-still-fetches L-NEVER-OK: with a git that says 2.43.0 and the home a --filter=blob:none clone whose HEAD's lanes.tsv blob was never fetched, felix lane --tsv in a full clone runs no upload-pack and reads the - line with R9" \
   "$LNKa|$LNKf|$LF_RC|$(cat "$LNKD/f8-t.out")" "built|fetch[]|0|$LNK8R9"
rm -f "$LNKFL"
_lf_run "$LNKD/f8-s" "$LNKD/f8-full" "$LNKN" PATH="$LNKD/oldgit:$LNKB:$PATH" "$FELIX" status --tsv
_lnk_is "lane command R2-F8-partial-home-table-read-still-fetches L-NEVER-OK: the same in felix status --tsv runs no upload-pack, and its lane row is lane unknown - with R9" \
   "$LNKa|fetch[$(cat "$LNKFL" 2>/dev/null)]|$LF_RC|$(_lf_last "$LNKD/f8-s.out")" \
   "built|fetch[]|0|$(_lf_tsv lane unknown - "$LNKD/f8-home/projects/ck/lanes.tsv cannot be read as committed in the Felix home")"
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- the review's F1: a count that ends early (C3, C5, C9) --------------------------------------------------------------
# Added on 2026-10-30 from the review's second amendment, still blind, last in this part because a run ended early may
# leave state behind. C9's fault through _lf_fault kill, with TMPDIR a directory of the fixture's own: when the read of
# the landings starts, the shell that runs it has its parent, then itself, killed. C3 and C9 allow two outcomes, and
# each assertion accepts exactly these: nothing on stdout, the line felix: the lane count did not finish in <repo> on
# stderr (other lines may sit beside it there), exit 1; or, where the process ended was one read's own, exit 0 and one
# line, unknown with R2 (--tsv: columns 1 to 9 and 13, as F1's fork above in part 2210 compares them; the human form:
# the line up to the reason and its ;). Never a count, no line, or exit 0 with nothing on stdout.
LNKR2="git could not read the landings on refs/remotes/origin/main in $LNKC"; LNKEND="felix: the lane count did not finish in $LNKC"
LNKkt="$LNKD/f1k-tmp"; rm -rf "$LNKkt"; mkdir -p "$LNKkt"
# OUT FORM -> "C3 or R2" when the run whose files are OUT.out and OUT.err, with status LF_RC, ended as C3 allows (FORM
# tsv or human), else its status, stdout and stderr.
_lnk_ended() {
  local o="$1" e
  e="$(LC_ALL=C awk -v w="$LNKEND" '$0 == w { f = 1 } END { print (f ? "line" : "no line") }' "$o.err" 2>/dev/null)"
  if [ "$LF_RC" = 1 ] && [ ! -s "$o.out" ] && [ "$e" = line ]; then printf 'C3 or R2'; return 0; fi
  if [ "$LF_RC" = 0 ] && [ "$(_lf_count "$o.out")" = 1 ]; then
    case "$2" in
      (tsv) if [ "$(_lf_cols "$o.out" 1 1 2 3 4 5 6 7 8 9 13)" = "capability|unknown|-|-|14|1/2|-|$LNKMARK|$LNKNEXT|$LNKR2" ]; then
              printf 'C3 or R2'; return 0; fi ;;
      (human) case "$(cat "$o.out")" in ("capability: unknown, $LNKR2; "*) printf 'C3 or R2'; return 0 ;; esac ;;
    esac
  fi
  printf 'status %s, stdout [%s], stderr [%s]' "$LF_RC" "$(cat "$o.out")" "$(cat "$o.err")"
}
_lf_fault kill "$LNKD/f1k-t.fired" "$LNKkt" _lf_run "$LNKD/f1k-t" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command F1-count-ends-early L-NEVER-OK: the parent of the shell that runs the read of the landings, then that shell, killed (C9): felix lane --tsv prints nothing on stdout, felix: the lane count did not finish in <repo> on stderr, and exits 1, or exits 0 with its one R2 line; never a count, no line, or exit 0 with nothing" \
   "$LNKBUILT|$LF_FIRE|$(_lnk_ended "$LNKD/f1k-t" tsv)" "built|fired|C3 or R2"
_lf_fault kill "$LNKD/f1k-h.fired" "$LNKkt" _lf_run "$LNKD/f1k-h" "$LNKC" "$LNKN" "$FELIX" lane
is "lane command F1-count-ends-early L-NEVER-OK: the same in felix lane, the human form: nothing on stdout, felix: the lane count did not finish in <repo> on stderr, and exit 1, or exit 0 with its one line capability: unknown, the R2 reason; never a count, no line, or exit 0 with nothing" \
   "$LNKBUILT|$LF_FIRE|$(_lnk_ended "$LNKD/f1k-h" human)" "built|fired|C3 or R2"

# ---- the second review's round 2: a graft file, lanes named 1 and 01, a repository root that ends early ----------------
# Added on 2026-10-30 from the second review's round 2 findings (their inputs and observed output only), still blind,
# last, after F1, because a run ended early may leave state behind. Each assertion also compares the command without
# the fault or the setting, so it is red on main, which prints no lane. Readings:
# - R2B-F3: C2 names the repository and C3 its first-parent chain; nothing the caller exports changes which commits are
#   read (F2's class). GIT_GRAFT_FILE, in the review's checkout (_lf_r2), naming B (engine/b.sh, four days back) alone,
#   which makes B a root, or "Y B", which gives Y (docs/y.md, two days back) the single parent B: git's own walk changes
#   under it (checked), and felix lane --tsv and the status row print the bytes they print without it.
# - R2B-F4: C1's lane names 1 and 01 are two lanes, each its own mark, its own next and its own row (C5 columns 7, 9 and
#   10). A home of its own: lanes.tsv 1 (^engine/, 1/2, 14) and 01 (^docs/, 1/2, 14) as commit A, lane-next.tsv 1 first
#   item and 01 second item, then commit B changing only 01's share to 1/3; a checkout whose one landing, two days back,
#   changes docs/n.md and carries Felix-Lane: 01. Lane 1 reads idle 0 0, last none, next first item, row last changed by
#   A; lane 01 ok 1 1 at 1/3, last the landing, next second item, row last changed by B. In a second home lanes.tsv holds
#   lane 1 alone and lane-next.tsv a row for 01 alone, which C1 ignores, so lane 1's next reads none.
# - R2B-F5: the review's kill (_lf_kill, C9's kill) at pwd with felix_repo_root called from cmd_lane, or from
#   felix_status_rows, on the stack: the substitution that finds the repository ends early, every other read finishes.
#   A reason names <repo>, the checkout (C3, C5, C6), never an empty one, and git never ran, so R2 is not its reason.
#   felix lane --tsv ends as C3's count that did not finish, naming the checkout, exit 1 (the finding's exit 2 is not the
#   Contract's), or prints the lines it prints without the fault; the status row reads lane unknown - the lane count did
#   not finish in <repo>, or the value.
LNKGA="not built: R2B-F3's grafts"; LNKGY=""; LNKGB=""
if [ "$LNKRA" = built ]; then
  LNKGY="$( _fx_cd "$LNKRC" && _lf_g 1700000000 rev-parse --verify -q 'refs/remotes/origin/main~1' )"
  LNKGB="$( _fx_cd "$LNKRC" && _lf_g 1700000000 rev-parse --verify -q 'refs/remotes/origin/main~3' )"
fi
printf '%s\n' "$LNKGB" > "$LNKD/r2b-graft-a"; printf '%s %s\n' "$LNKGY" "$LNKGB" > "$LNKD/r2b-graft-b"
# [FILE] -> the committer times of the first-parent chain of refs/remotes/origin/main in the review's checkout, newest
# first, with GIT_GRAFT_FILE FILE when given.
_lnk_graft() {
  ( _fx_cd "$LNKRC" || exit 1
    if [ -n "${1-}" ]; then GIT_GRAFT_FILE="$1" _lf_g 1700000000 log --first-parent --format=%ct refs/remotes/origin/main
    else _lf_g 1700000000 log --first-parent --format=%ct refs/remotes/origin/main; fi ) 2>/dev/null \
    | LC_ALL=C awk '{ printf "%s%s", (NR > 1 ? " " : ""), $1 }'
}
LNKa="$((LNKN - LNKDAY)) $((LNKN - 2 * LNKDAY))"
[ -n "$LNKGY" ] && [ -n "$LNKGB" ] \
  && [ "$(_lnk_graft)" = "$LNKa $((LNKN - 3 * LNKDAY)) $((LNKN - 4 * LNKDAY)) $((LNKN - 5 * LNKDAY)) $((LNKN - 20 * LNKDAY)) $((LNKN - 30 * LNKDAY))" ] \
  && [ "$(_lnk_graft "$LNKD/r2b-graft-a")" = "$LNKa $((LNKN - 3 * LNKDAY)) $((LNKN - 4 * LNKDAY))" ] \
  && [ "$(_lnk_graft "$LNKD/r2b-graft-b")" = "$LNKa $((LNKN - 4 * LNKDAY)) $((LNKN - 5 * LNKDAY)) $((LNKN - 20 * LNKDAY)) $((LNKN - 30 * LNKDAY))" ] \
  && LNKGA=built
_lf_use "$LNKD/r2/home" "$LNKD/memory" "$LNKD/user" "$LNKB"
LNKb=""; LNKc=""; LNKw=""; LNKv=""
_lnk_r2env 'GIT_GRAFT_FILE: B a root' GIT_GRAFT_FILE="$LNKD/r2b-graft-a"
_lnk_r2env 'GIT_GRAFT_FILE: Y B' GIT_GRAFT_FILE="$LNKD/r2b-graft-b"
is "lane command R2B-F3-graft-file-changes-landings: GIT_GRAFT_FILE exported by the caller, making B (engine/b.sh, four days back) a root, or giving Y (docs/y.md, two days back) the single parent B, each of which changes the first-parent chain git walks, leaves felix lane --tsv's exit 0 and its two lines byte for byte as they are without it" \
   "$LNKGA|unfaulted $LNKRU0|$LNKb" "built|unfaulted 0|$LNKRL|$LNKw"
is "lane command R2B-F3-graft-file-changes-landings: the same GIT_GRAFT_FILE settings leave felix status --tsv's exit 0 and its lane row the value zero 0 of 2 engine landings in 14 days, target 1/2" \
   "$LNKGA|unfaulted $LNKRS0|$LNKc" "built|unfaulted 0|$LNKRV|$LNKv"

LNKNA="not built: R2B-F4's home and checkout"; LNKNH="$LNKD/home-num"; LNKNC="$LNKD/num"; LNKNSA=""; LNKNSB=""
if _lf_home "$LNKD/home-num" ck 1792700000; then
  LNKNH="$LF_HOME"
  _lf_table "$LF_PROJ" 1792700100 lanes.tsv $'1\t^engine/\t1/2\t14\n01\t^docs/\t1/2\t14\n' && LNKNSA="$LF_SHA" \
    && _lf_table "$LF_PROJ" 1792700200 lane-next.tsv $'1\tfirst item\n01\tsecond item\n' \
    && _lf_table "$LF_PROJ" 1792700300 lanes.tsv $'1\t^engine/\t1/2\t14\n01\t^docs/\t1/3\t14\n' && LNKNSB="$LF_SHA" \
    && _lf_checkout "$LNKD/num" ck $((LNKN - 30 * LNKDAY)) && LNKNC="$LF_REPO" \
    && _lf_commit "$LNKNC" $((LNKN - 2 * LNKDAY)) $'docs: n\n\nFelix-Lane: 01\n' docs/n.md && _lf_publish "$LNKNC" \
    && [ "$(_lf_spine "$LNKNC")" = "$((LNKN - 2 * LNKDAY)):1 $((LNKN - 30 * LNKDAY)):0" ] \
    && [ "$(_lf_marks "$LNKNC" HEAD 01)|$(_lf_marks "$LNKNC" HEAD 1)" = "1|0" ] && LNKNA=built
fi
LNKa="$(_lf_iso $((LNKN - 2 * LNKDAY)))"
LNKN1="$(_lf_tsv 1 idle 0 0 14 1/2 none 'Felix-Lane: 1' 'first item' "$LNKNSA" "$(_lf_iso 1792700100)" "$LNKa" -)"
LNKN01="$(_lf_tsv 01 ok 1 1 14 1/3 "$LNKa" 'Felix-Lane: 01' 'second item' "$LNKNSB" "$(_lf_iso 1792700300)" "$LNKa" -)"
_lf_use "$LNKNH" "$LNKD/memory" "$LNKD/user" "$LNKB"
_lf_run "$LNKD/r2bf4" "$LNKNC" "$LNKN" "$FELIX" lane --tsv
is "lane command R2B-F4-numeric-lane-names-collide: lanes named 1 and 01 are two lanes: felix lane --tsv prints 1 idle 0 0, last none, next first item, its row last changed by A, and 01 ok 1 1 at 1/3, last the Felix-Lane: 01 landing, next second item, its row last changed by B; never 1 taking 01's landing, next or row change" \
   "$LNKNA|$LF_RC|$(cat "$LNKD/r2bf4.out")" "built|0|$LNKN1"$'\n'"$LNKN01"
LNKNV="not built: R2B-F4's second home"; LNKNH2="$LNKD/home-num2"; LNKNSV=""
if _lf_home "$LNKD/home-num2" ck 1792700000; then
  LNKNH2="$LF_HOME"
  _lf_table "$LF_PROJ" 1792700100 lanes.tsv $'1\t^engine/\t1/2\t14\n' && LNKNSV="$LF_SHA" \
    && _lf_table "$LF_PROJ" 1792700200 lane-next.tsv $'01\tsecond item\n' && [ "$LNKNA" = built ] && LNKNV=built
fi
_lf_use "$LNKNH2" "$LNKD/memory" "$LNKD/user" "$LNKB"
_lf_run "$LNKD/r2bf4v" "$LNKNC" "$LNKN" "$FELIX" lane --tsv
is "lane command R2B-F4-numeric-lane-names-collide: with lanes.tsv holding lane 1 alone and lane-next.tsv a row for 01 alone, a lane lanes.tsv does not hold (C1: ignored), lane 1's next reads none, never unknown" \
   "$LNKNV|$LF_RC|$(cat "$LNKD/r2bf4v.out")" \
   "built|0|$(_lf_tsv 1 idle 0 0 14 1/2 none 'Felix-Lane: 1' none "$LNKNSV" "$(_lf_iso 1792700100)" "$LNKa" -)"

_lf_use "$LNKD/r2/home" "$LNKD/memory" "$LNKD/user" "$LNKB"
LNKPT="$LNKD/r2b-kill-tmp"; rm -rf "$LNKPT"; mkdir -p "$LNKPT"
_lf_kill pwd '*' "*' felix_repo_root cmd_lane '*" "$LNKD/r2bf5-t.fired" "$LNKPT" _lf_run "$LNKD/r2bf5-t" "$LNKRC" "$LNKN" "$FELIX" lane --tsv
if [ "$(_lf_ended "$LNKD/r2bf5-t" "$LNKRC")" = ended ] || [ "$LF_RC|$(cat "$LNKD/r2bf5-t.out")" = "0|$LNKRL" ]; then LNKa="ended naming the checkout, or the lines"
else LNKa="status $LF_RC, stdout [$(cat "$LNKD/r2bf5-t.out")], stderr [$(cat "$LNKD/r2bf5-t.err")]"; fi
is "lane command R2B-F5-repo-root-ends-early-names-no-repo L-NEVER-OK: felix_repo_root's substitution under cmd_lane ended early (C9's kill at its pwd), every other read left to finish: felix lane --tsv prints nothing on stdout, felix: the lane count did not finish in <repo> naming the checkout on stderr, and exits 1, or prints the two lines it prints without the fault; never R2 naming an empty repository" \
   "$LNKRA|unfaulted $LNKRU0|$LF_FIRE|$LNKa" "built|unfaulted 0|$LNKRL|fired|ended naming the checkout, or the lines"
rm -rf "$LNKPT"; mkdir -p "$LNKPT"
_lf_kill pwd '*' "*' felix_repo_root felix_status_rows '*" "$LNKD/r2bf5-s.fired" "$LNKPT" _lf_run "$LNKD/r2bf5-s" "$LNKRC" "$LNKN" "$FELIX" status --tsv
LNKa="status $LF_RC, last [$(_lf_last "$LNKD/r2bf5-s.out")]"
case "$LF_RC|$(_lf_last "$LNKD/r2bf5-s.out")" in
  ("0|$LNKRV"|"0|$(_lf_tsv lane unknown - "the lane count did not finish in $LNKRC")") LNKa="did not finish naming the checkout, or the value" ;;
esac
is "lane command R2B-F5-repo-root-ends-early-names-no-repo L-NEVER-OK: felix_repo_root's substitution under felix_status_rows ended early the same way: felix status --tsv exits 0 and its last row is lane unknown - the lane count did not finish in <repo>, naming the checkout, or the value zero 0 of 2; never a reason naming an empty repository" \
   "$LNKRA|unfaulted $LNKRS0|$LF_FIRE|$LNKa" "built|unfaulted 0|$LNKRV|fired|did not finish naming the checkout, or the value"

# ---- the second review's round 3: a resolution that ended early reads as no project (R3-F2) ---------------------------
# Added on 2026-10-30 from the second review's round 3 findings (their inputs and observed output only), still blind,
# last, after R2B-F5, because a run ended early may leave state behind. The review's checkout C above (_lf_r2: bound by
# its .felix, p's own, remote_match o/r) and a checkout CR beside it, bound to p by remote_match alone: no .felix, its
# origin https://github.com/o/r.git, the same root and landings at the same times, so felix lane --tsv prints in CR the
# two lines it prints in C. The fault is C9's kill (_lf_kill) at a read made inside felix_resolve_project, by the words
# the finding names: in C, tr -d [:space:], the read of the .felix marker; in CR, git remote get-url origin. It kills the
# parent of the shell that made the read, the process felix_resolve_project runs in, then that shell. Readings (C3, C5):
# a directory a .felix marker or a remote_match governs is never one no project governs, and a resolution that did not
# finish is not one that found no project. So felix lane and felix lane --tsv print nothing on stdout and end as C3's
# count that did not finish (exit 1), or exit 2 with a first stderr line of felix's naming the checkout that is not C5's
# felix: no project governs <dir>.; or, if the process the kill ended was felix itself, exit 137 with nothing on stdout;
# or print what they print without the fault. Never the line felix: no project governs <dir>. on stderr. The review also
# saw this fault once in 48 runs under a real process limit, a race no fixture pins; it is not asserted.
LNKXA="not built: R3-F2's checkouts"; LNKXR="$LNKD/r3cr"; LNKXT="$LNKD/r3f2-tmp"
if [ "$LNKRA" = built ] && [ -f "$LNKRC/.felix" ] && _lf_checkout "$LNKD/r3cr" p $((LNKN - 30 * LNKDAY)); then
  LNKXR="$LF_REPO"; rm -f "$LNKXR/.felix"
  _lf_origin "$LNKXR" https://github.com/o/r.git && _lf_r2land "$LNKXR" "$LNKN" && [ ! -e "$LNKXR/.felix" ] \
    && [ -n "$(LC_ALL=C awk '/"remote_match":"o\/r"/' "$LNKD/r2/home/projects/p/project.json")" ] \
    && [ "$(_lf_spine "$LNKXR")" = "$(_lf_spine "$LNKRC")" ] && LNKXA=built
fi
_lf_use "$LNKD/r2/home" "$LNKD/memory" "$LNKD/user" "$LNKB"
_lf_run "$LNKD/r3f2-x0" "$LNKXR" "$LNKN" "$FELIX" lane --tsv; LNKb="$LF_RC|$(cat "$LNKD/r3f2-x0.out")"
# OUT DIR WANT -> "unresolved, ended or the lines" when the faulted felix lane run in DIR whose files are OUT.* ended as
# the readings above accept, WANT the file of what it prints without the fault; else its status, stdout and stderr.
_lnk_r3f2() {
  local o="$1" e s
  e="$(LC_ALL=C awk 'NR == 1' "$o.err")"
  s="$(LC_ALL=C awk -v w="felix: no project governs $2." '$0 == w { f = 1 } END { print (f ? "said" : "not said") }' "$o.err" 2>/dev/null)"
  if [ "$s" = "not said" ]; then
    if [ "$(_lf_ended "$o" "$2")" = ended ] || { [ "$LF_RC" = 0 ] && cmp -s "$o.out" "$3"; }; then printf 'unresolved, ended or the lines'; return 0; fi
    if [ ! -s "$o.out" ]; then
      case "$LF_RC|$e" in ("2|felix: "*"$2"*|"137|"*) printf 'unresolved, ended or the lines'; return 0 ;; esac
    fi
  fi
  printf 'status %s, stdout [%s], stderr [%s]' "$LF_RC" "$(cat "$o.out")" "$(cat "$o.err")"
}
rm -rf "$LNKXT"; mkdir -p "$LNKXT"
_lf_kill tr "*' -d [:space:] '*" "*' felix_resolve_project '*" "$LNKD/r3f2-ct.fired" "$LNKXT" _lf_run "$LNKD/r3f2-ct" "$LNKRC" "$LNKN" "$FELIX" lane --tsv
LNKa="$(_lnk_r3f2 "$LNKD/r3f2-ct" "$LNKRC" "$LNKD/r2-t0.out")"; LNKc="$LF_FIRE"
rm -rf "$LNKXT"; mkdir -p "$LNKXT"
_lf_kill tr "*' -d [:space:] '*" "*' felix_resolve_project '*" "$LNKD/r3f2-ch.fired" "$LNKXT" _lf_run "$LNKD/r3f2-ch" "$LNKRC" "$LNKN" "$FELIX" lane
LNKa="$LNKa|$(_lnk_r3f2 "$LNKD/r3f2-ch" "$LNKRC" "$LNKD/r2-h0.out")"; LNKc="$LNKc+$LF_FIRE"
is "lane command R3-F2-ended-resolution-reads-ungoverned L-NEVER-OK: in the checkout its .felix binds, C9's kill at the read of the marker inside felix_resolve_project (tr -d [:space:]): felix lane --tsv and felix lane print nothing on stdout and end as C3's count that did not finish, or exit 2 with a first stderr line naming the checkout that is not felix: no project governs <dir>., or exit 137, or print their unfaulted lines; never felix: no project governs <dir>." \
   "$LNKRA|unfaulted $LNKRU0|unfaulted $LNKRH0|$LNKc|$LNKa" \
   "built|unfaulted 0|$LNKRL|unfaulted 0|$(_lnk_human "$LNKRCAP" "$LNKRSEC")|fired+fired|unresolved, ended or the lines|unresolved, ended or the lines"
rm -rf "$LNKXT"; mkdir -p "$LNKXT"
_lf_kill git "*' remote get-url origin '*" "*' felix_resolve_project '*" "$LNKD/r3f2-xt.fired" "$LNKXT" _lf_run "$LNKD/r3f2-xt" "$LNKXR" "$LNKN" "$FELIX" lane --tsv
is "lane command R3-F2-ended-resolution-reads-ungoverned L-NEVER-OK: in a checkout bound by remote_match alone, C9's kill at git remote get-url origin inside felix_resolve_project: felix lane --tsv prints nothing on stdout and ends as C3's count that did not finish, or exits 2 with a first stderr line naming the checkout that is not felix: no project governs <dir>., or exits 137, or prints its unfaulted lines; never felix: no project governs <dir>." \
   "$LNKXA|unfaulted $LNKb|$LF_FIRE|$(_lnk_r3f2 "$LNKD/r3f2-xt" "$LNKXR" "$LNKD/r3f2-x0.out")" "built|unfaulted 0|$LNKRL|fired|unresolved, ended or the lines"
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- design item 46: the lane's resolution, C5's line, and the misses that stand ---------------------------------------
# Added on 2026-10-30 from design 11 item 46 (C2's bullet The lane's resolution, C5's bullet Resolution did not finish),
# still blind, last. A home-apart fixture of its own (_lf_r2: LNKI/home holds p, remote_match o/r; LNKI/c its checkout),
# whose checkout _lf_bind puts in a layout: felix (its .felix alone binds it) and remote (remote_match alone) print
# _lf_r2's two lines. The faults are C9's fork and kill probes (_lf_probe), every time a read the miss stands on is made
# inside felix_resolve_project: in felix, tr -d [:space:], the read of the marker (as R3-F2 builds it), where no origin is
# left for the resolver to bind instead; in remote, git remote get-url origin. Readings:
# - I46-1 to I46-4: felix lane and felix lane --tsv exit 2, print nothing on stdout, and the first line of stderr is C5's
#   line, <dir> as $PWD names it. Only where a probe reached felix itself (LF_SELF: the shell it killed or the parent of
#   it, or the shell its fork failed in, is felix) may felix end with 137 (C9) or 128 (C3) and nothing on stdout.
# - I46-5 to I46-10, no fault: in the layouts none, other, tie, nosuch, empty and closed the miss stands: exit 2, nothing
#   on stdout, and stderr's first line felix: no project governs <dir>. (none, other); in the others, that line or one of
#   felix's naming <dir> and the binding that missed (the .felix marker; the remote_match of a tie); never C5's line. Each
#   first runs a layout that binds, the marker's or remote_match's, so it is red on main, where felix lane does not exist.
LNKIA="not built: item 46's fixture"; LNKIT="$LNKD/i46-tmp"
_lf_r2 "$LNKD/i46" p "$LNKN" && LNKIA=built
LNKIH="$LF_HOME"; LNKIC="$LF_REPO"; LNKIL="$LF_R2"
_lf_use "$LNKIH" "$LNKD/memory" "$LNKD/user" "$LNKB"
# OUT DIR MODE -> "unresolved" when the faulted run whose files are OUT.* said C5's line (_lf_said), or the probe reached
# felix itself and it ended with 137 (MODE kill) or 128 (fork) with nothing on stdout and no line saying no project
# governs DIR; else what it said.
_lnk_unres() {
  local s
  s="$(_lf_said "$1" "$2")"
  if [ "$s" != unresolved ] && [ "$LF_SELF" = self ] && [ ! -s "$1.out" ] \
     && [ -z "$(LC_ALL=C awk -v w="felix: no project governs $2." '$0 == w' "$1.err")" ]; then
    case "$3:$LF_RC" in (kill:137|fork:128) s=unresolved ;; esac
  fi
  printf '%s' "$s"
}
# LAYOUT MODE NAME WORDS -> the checkout in LAYOUT; felix lane --tsv there; then felix lane --tsv and felix lane, each
# under _lf_probe MODE NAME WORDS, felix_resolve_project on the stack, with a fresh TMPDIR. LNKa what was built and the
# unfaulted run, LNKb what each faulted run said (_lnk_unres), LNKc each probe's LF_FIRE.
_lnk_i46f() {
  _lf_bind "$LNKIC" "$LNKIH" p "$1"; LNKa="$LNKIA|$LF_BOUND"
  _lf_run "$LNKD/i46-0" "$LNKIC" "$LNKN" "$FELIX" lane --tsv; LNKa="$LNKa|unfaulted $LF_RC|$(cat "$LNKD/i46-0.out")"
  rm -rf "$LNKIT"; mkdir -p "$LNKIT"
  _lf_probe "$2" "$3" "$4" "*' felix_resolve_project '*" "$LNKD/i46t.fired" "$LNKIT" _lf_run "$LNKD/i46t" "$LNKIC" "$LNKN" "$FELIX" lane --tsv
  LNKb="$(_lnk_unres "$LNKD/i46t" "$LNKIC" "$2")"; LNKc="$LF_FIRE"
  rm -rf "$LNKIT"; mkdir -p "$LNKIT"
  _lf_probe "$2" "$3" "$4" "*' felix_resolve_project '*" "$LNKD/i46h.fired" "$LNKIT" _lf_run "$LNKD/i46h" "$LNKIC" "$LNKN" "$FELIX" lane
  LNKb="$LNKb|$(_lnk_unres "$LNKD/i46h" "$LNKIC" "$2")"; LNKc="$LNKc+$LF_FIRE"
}
LNKa5='exit 2, nothing on stdout, and the first line of stderr exactly felix: the project that governs <dir> could not be resolved: a read it stands on did not finish.'
_lnk_i46f felix fork tr "*' -d [:space:] '*"
is "I46-1 felix lane, in a checkout its .felix alone binds, with C9's fork probe at the read of the marker inside felix_resolve_project (tr -d [:space:]): felix lane --tsv and felix lane $LNKa5 (or 128 with nothing on stdout, where the fork failed in felix's own shell); the probe fired" \
   "$LNKa|$LNKc|$LNKb" "built|built|unfaulted 0|$LNKIL|fired+fired|unresolved|unresolved"
_lnk_i46f felix kill tr "*' -d [:space:] '*"
is "I46-2 felix lane, in a checkout its .felix alone binds, with C9's kill probe at the read of the marker inside felix_resolve_project (tr -d [:space:]): felix lane --tsv and felix lane $LNKa5 (or 137 with nothing on stdout, where the kill reached felix itself); the probe fired" \
   "$LNKa|$LNKc|$LNKb" "built|built|unfaulted 0|$LNKIL|fired+fired|unresolved|unresolved"
_lnk_i46f remote fork git "*' remote get-url origin '*"
is "I46-3 felix lane, in a checkout remote_match alone binds, with C9's fork probe at git remote get-url origin inside felix_resolve_project: felix lane --tsv and felix lane $LNKa5 (or 128 with nothing on stdout, where the fork failed in felix's own shell); the probe fired" \
   "$LNKa|$LNKc|$LNKb" "built|built|unfaulted 0|$LNKIL|fired+fired|unresolved|unresolved"
_lnk_i46f remote kill git "*' remote get-url origin '*"
is "I46-4 felix lane, in a checkout remote_match alone binds, with C9's kill probe at git remote get-url origin inside felix_resolve_project: felix lane --tsv and felix lane $LNKa5 (or 137 with nothing on stdout, where the kill reached felix itself); the probe fired" \
   "$LNKa|$LNKc|$LNKb" "built|built|unfaulted 0|$LNKIL|fired+fired|unresolved|unresolved"

# OUT DIR LAYOUT -> "a miss" when the run whose files are OUT.* ended as a miss that stands, as the readings above say for
# LAYOUT; else what it said (_lf_said).
_lnk_miss() {
  local s e
  s="$(_lf_said "$1" "$2")"
  [ "$s" != ungoverned ] || { printf 'a miss'; return 0; }
  e="$(LC_ALL=C awk 'NR == 1' "$1.err")"
  if [ "$s" != unresolved ] && [ "$LF_RC" = 2 ] && [ ! -s "$1.out" ]; then
    case "$e" in ("felix: "*"$2"*) ;; (*) e="" ;; esac
    case "$3:$e" in (tie:*remote_match*|nosuch:*.felix*|empty:*.felix*|closed:*.felix*) printf 'a miss'; return 0 ;; esac
  fi
  printf '%s' "$s"
}
# MISS BIND -> the checkout in BIND and felix lane --tsv there, then in MISS and felix lane --tsv and felix lane there.
# LNKa what was built and BIND's run, LNKb what MISS's two runs said (_lnk_miss).
_lnk_i46m() {
  _lf_bind "$LNKIC" "$LNKIH" p "$2"; LNKa="$LNKIA|$2 $LF_BOUND"
  _lf_run "$LNKD/i46b" "$LNKIC" "$LNKN" "$FELIX" lane --tsv; LNKa="$LNKa|$LF_RC|$(cat "$LNKD/i46b.out")"
  _lf_bind "$LNKIC" "$LNKIH" p "$1"; LNKa="$LNKa|$1 $LF_BOUND"
  _lf_run "$LNKD/i46m" "$LNKIC" "$LNKN" "$FELIX" lane --tsv; LNKb="$(_lnk_miss "$LNKD/i46m" "$LNKIC" "$1")"
  _lf_run "$LNKD/i46m" "$LNKIC" "$LNKN" "$FELIX" lane; LNKb="$LNKb|$(_lnk_miss "$LNKD/i46m" "$LNKIC" "$1")"
}
LNKa5='exit 2 with nothing on stdout, and never the line for a resolution that did not finish'
_lnk_i46m none felix
is "I46-5 felix lane, a miss that stands: in a checkout with no .felix and no origin remote, felix lane --tsv and felix lane $LNKa5: the first line of stderr is felix: no project governs <dir>.; with its .felix naming p the checkout prints its lines" \
   "$LNKa|$LNKb" "built|felix built|0|$LNKIL|none built|a miss|a miss"
_lnk_i46m other remote
is "I46-6 felix lane, a miss that stands: in a checkout whose origin no project's remote_match names, felix lane --tsv and felix lane $LNKa5: the first line of stderr is felix: no project governs <dir>.; with an origin p's remote_match names the checkout prints its lines" \
   "$LNKa|$LNKb" "built|remote built|0|$LNKIL|other built|a miss|a miss"
_lnk_i46m tie remote
is "I46-7 felix lane, a miss that stands: in a checkout whose origin two projects' remote_match name equally, a tie, felix lane --tsv and felix lane $LNKa5: the first line of stderr is felix: no project governs <dir>. or names <dir> and the remote_match; with p's alone naming it the checkout prints its lines" \
   "$LNKa|$LNKb" "built|remote built|0|$LNKIL|tie built|a miss|a miss"
_lnk_i46m nosuch felix
is "I46-8 felix lane, a miss that stands: in a checkout whose .felix names no project, felix lane --tsv and felix lane $LNKa5: the first line of stderr is felix: no project governs <dir>. or names <dir> and the .felix marker; with its .felix naming p the checkout prints its lines" \
   "$LNKa|$LNKb" "built|felix built|0|$LNKIL|nosuch built|a miss|a miss"
_lnk_i46m empty felix
is "I46-9 felix lane, a miss that stands: in a checkout whose .felix is empty, felix lane --tsv and felix lane $LNKa5: the first line of stderr is felix: no project governs <dir>. or names <dir> and the .felix marker; with its .felix naming p the checkout prints its lines" \
   "$LNKa|$LNKb" "built|felix built|0|$LNKIL|empty built|a miss|a miss"
LNKa6="I46-10 felix lane, a miss that stands: in a checkout whose .felix exists and cannot be opened (mode 000), felix lane --tsv and felix lane $LNKa5: the first line of stderr is felix: no project governs <dir>. or names <dir> and the .felix marker; with its .felix naming p the checkout prints its lines"
if [ "$(id -u)" = 0 ]; then skip "$LNKa6" "the suite runs as root, which opens a .felix of mode 000"
else
  _lnk_i46m closed felix
  is "$LNKa6" "$LNKa|$LNKb" "built|felix built|0|$LNKIL|closed built|a miss|a miss"
fi
_lf_bind "$LNKIC" "$LNKIH" p felix
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- the third review's round 1: the lane's own check of the resolution (V3R1-F1, V3R1-F2, V3R1-F5) --------------------
# Added on 2026-10-30 from the third review's round 1 findings (their inputs and observed output only) and C2 and C5 as
# 777e6c2d amended them, still blind, last. Readings:
# - V3R1-F1: item 46's checkout bound by remote_match alone (_lf_bind remote), with C9's fork probe (_lf_probe) at every
#   sed whose words hold remote_match, whatever calls it: the resolver's read and the check's own (C2: a sed of its own,
#   no pipe) both fail, so the check did not finish; or at every head -1, the end of the shared reader's pipe, where the
#   resolver misses and the check reads with no head. Either way the resolution did not finish: felix lane --tsv and
#   felix lane say C5's line (_lnk_unres: or 128 with nothing on stdout, where the fork failed in felix's own shell).
# - V3R1-F2: a home of two projects, p (remote_match o/r, lane cap ^engine/ 1/2 14) and z (github.com/o/r, the longer, so
#   z binds; lane zz ^docs/ 1/2 7), and a checkout remote_match alone binds (_lf_two apart), where felix lane --tsv prints
#   zz zero 0 1 7 1/2. C9's fork and kill probes at sed naming projects/z/project.json inside felix_resolve_project let
#   the resolver bind p while the check binds z, another project, so the resolution did not finish (C2; design item 47:
#   the check must finish and bind the same project): C5's line, or 128 or 137 where the probe reached felix itself;
#   never p's figures, cap zero 0 1 14 1/2, and never z's lines as without the fault (from the disputes on round 1: an
#   engine that put its own binding in place of the resolver's would print them).
# - V3R1-F5: item 46's checkout with a .felix of mode 000 holding p, and no origin: C5's sentence for a marker that cannot
#   be opened, exactly, <root> the checkout. Beside it, a .felix naming no project gives a line of felix's naming <dir>
#   and the .felix marker that is not that sentence, and no .felix gives felix: no project governs <dir>.
_lf_use "$LNKIH" "$LNKD/memory" "$LNKD/user" "$LNKB"
# MODE NAME WORDS STACK DIR -> felix lane --tsv, then felix lane, in DIR under _lf_probe MODE NAME WORDS STACK, each with
# a fresh TMPDIR. LNKb what each said (_lnk_unres), LNKc each probe's LF_FIRE.
_lnk_v3() {
  rm -rf "$LNKIT"; mkdir -p "$LNKIT"
  _lf_probe "$1" "$2" "$3" "$4" "$LNKD/v3t.fired" "$LNKIT" _lf_run "$LNKD/v3t" "$5" "$LNKN" "$FELIX" lane --tsv
  LNKb="$(_lnk_unres "$LNKD/v3t" "$5" "$1")"; LNKc="$LF_FIRE"
  rm -rf "$LNKIT"; mkdir -p "$LNKIT"
  _lf_probe "$1" "$2" "$3" "$4" "$LNKD/v3h.fired" "$LNKIT" _lf_run "$LNKD/v3h" "$5" "$LNKN" "$FELIX" lane
  LNKb="$LNKb|$(_lnk_unres "$LNKD/v3h" "$5" "$1")"; LNKc="$LNKc+$LF_FIRE"
}
LNKa5='felix lane --tsv and felix lane exit 2, print nothing on stdout, and say first on stderr felix: the project that governs <dir> could not be resolved: a read it stands on did not finish.'
_lf_bind "$LNKIC" "$LNKIH" p remote; LNKa="$LNKIA|$LF_BOUND"
_lf_run "$LNKD/v3-0" "$LNKIC" "$LNKN" "$FELIX" lane --tsv; LNKa="$LNKa|unfaulted $LF_RC|$(cat "$LNKD/v3-0.out")"
_lnk_v3 fork sed '*remote_match*' '*' "$LNKIC"
is "lane command V3R1-F1-remote-match-read-fault-reads-ungoverned L-NEVER-OK: in a checkout remote_match alone binds, C9's fork probe at every sed whose words hold remote_match, the resolver's read and the lane check's own: $LNKa5 (or 128 with nothing on stdout, where the fork failed in felix's own shell); never felix: no project governs <dir>.; the probe fired, and unfaulted the checkout prints its lines" \
   "$LNKa|$LNKc|$LNKb" "built|built|unfaulted 0|$LNKIL|fired+fired|unresolved|unresolved"
_lnk_v3 fork head "*' -1 '*" '*' "$LNKIC"
is "lane command V3R1-F1-remote-match-read-fault-reads-ungoverned L-NEVER-OK: the same checkout, C9's fork probe at every head -1, the end of the shared reader's pipe after its sed, so the resolver misses while the check reads remote_match with a sed of its own and no pipe (C2): $LNKa5 (or 128 with nothing on stdout, where the fork failed in felix's own shell); never felix: no project governs <dir>.; the probe fired" \
   "$LNKa|$LNKc|$LNKb" "built|built|unfaulted 0|$LNKIL|fired+fired|unresolved|unresolved"

LNKVA="not built: V3R1-F2's home and checkout"; LNKVC="$LNKD/v3f2/c"
_lf_two "$LNKD/v3f2" apart "$LNKN" && LNKVA=built
_lf_use "$LNKD/v3f2/home" "$LNKD/memory" "$LNKD/user" "$LNKB"
_lf_run "$LNKD/v3f2-t" "$LNKVC" "$LNKN" "$FELIX" lane --tsv
LNKa="$LNKVA|unfaulted $LF_RC|$(_lf_count "$LNKD/v3f2-t.out")|$(_lf_cols "$LNKD/v3f2-t.out" 1 1 2 3 4 5 6)"
_lf_run "$LNKD/v3f2-h" "$LNKVC" "$LNKN" "$FELIX" lane
case "$LF_RC|$(cat "$LNKD/v3f2-h.out")" in
  ("0|zz: zero, 0 of 1 engine landings in 7 days, target 1/2; "*) LNKa="$LNKa|z's human line" ;;
  (*) LNKa="$LNKa|human [$LF_RC|$(cat "$LNKD/v3f2-h.out")]" ;;
esac
LNKa6='felix lane --tsv and felix lane exit 2 with nothing on stdout and C5'"'"'s line felix: the project that governs <dir> could not be resolved: a read it stands on did not finish. first on stderr, since the check binds z where the resolver found p (C2)'
_lnk_v3 fork sed '*projects/z/project.json*' "*' felix_resolve_project '*" "$LNKVC"
is "lane command V3R1-F2-shorter-remote-match-binds L-NEVER-OK: in a checkout whose origin two projects' remote_match name, z's github.com/o/r the longer, so felix lane --tsv prints zz zero 0 1 7 1/2, C9's fork probe at sed naming projects/z/project.json inside felix_resolve_project, where the resolver can bind p's shorter o/r: $LNKa6 (or 128 with nothing on stdout, where the fork failed in felix's own shell); never p's figures, cap zero 0 1 14 1/2, nor z's lines as without the fault; the probe fired" \
   "$LNKa|$LNKc|$LNKb" "built|unfaulted 0|1|zz|zero|0|1|7|1/2|z's human line|fired+fired|unresolved|unresolved"
_lnk_v3 kill sed '*projects/z/project.json*' "*' felix_resolve_project '*" "$LNKVC"
is "lane command V3R1-F2-shorter-remote-match-binds L-NEVER-OK: the same checkout, C9's kill probe at sed naming projects/z/project.json inside felix_resolve_project: $LNKa6 (or 137 with nothing on stdout, where the kill reached felix itself); never p's figures, cap zero 0 1 14 1/2, nor z's lines as without the fault; the probe fired" \
   "$LNKa|$LNKc|$LNKb" "built|unfaulted 0|1|zz|zero|0|1|7|1/2|z's human line|fired+fired|unresolved|unresolved"

_lf_use "$LNKIH" "$LNKD/memory" "$LNKD/user" "$LNKB"
LNKb="felix: The .felix marker in $LNKIC cannot be read, so it does not resolve to a project."
# LAYOUT -> the checkout in LAYOUT, then felix lane --tsv and felix lane there; LNKa gains what was built and, per run, its
# status, its bytes on stdout and the first line of its stderr, written "a broken binding" when LAYOUT is nosuch and it
# is a line of felix's naming the checkout and the .felix marker that is neither LNKb, nor no project governs, nor C5's
# unresolved line.
_lnk_v3m() {
  local o e
  _lf_bind "$LNKIC" "$LNKIH" p "$1"; LNKa="$LNKa|$1 $LF_BOUND"
  for o in --tsv -; do
    if [ "$o" = - ]; then _lf_run "$LNKD/v3f5" "$LNKIC" "$LNKN" "$FELIX" lane; else _lf_run "$LNKD/v3f5" "$LNKIC" "$LNKN" "$FELIX" lane --tsv; fi
    e="$(LC_ALL=C awk 'NR == 1' "$LNKD/v3f5.err")"
    case "$e" in
      ("$LNKb"|"felix: no project governs $LNKIC."|"felix: the project that governs $LNKIC could not be resolved: a read it stands on did not finish.") ;;
      ("felix: "*"$LNKIC"*) case "$1:$e" in (nosuch:*.felix*) e="a broken binding" ;; esac ;;
    esac
    LNKa="$LNKa|$LF_RC $(wc -c < "$LNKD/v3f5.out" | tr -d ' ') $e"
  done
}
LNKa6="lane command V3R1-F5-unreadable-marker-called-empty: in a checkout whose .felix holds p, exists and cannot be opened (mode 000), with no origin, felix lane --tsv and felix lane exit 2, print nothing on stdout, and say first on stderr exactly felix: The .felix marker in <root> cannot be read, so it does not resolve to a project.; a .felix naming no project gives a line of felix's naming <dir> and the marker, never that sentence; no .felix gives felix: no project governs <dir>.; with its .felix naming p the checkout prints its lines"
if [ "$(id -u)" = 0 ]; then skip "$LNKa6" "the suite runs as root, which opens a .felix of mode 000"
else
  _lf_bind "$LNKIC" "$LNKIH" p felix; LNKa="$LNKIA|felix $LF_BOUND"
  _lf_run "$LNKD/v3f5-0" "$LNKIC" "$LNKN" "$FELIX" lane --tsv; LNKa="$LNKa|$LF_RC|$(cat "$LNKD/v3f5-0.out")"
  _lnk_v3m closed; _lnk_v3m nosuch; _lnk_v3m none
  is "$LNKa6" "$LNKa" "built|felix built|0|$LNKIL|closed built|2 0 $LNKb|2 0 $LNKb|nosuch built|2 0 a broken binding|2 0 a broken binding|none built|2 0 felix: no project governs $LNKIC.|2 0 felix: no project governs $LNKIC."
fi
_lf_bind "$LNKIC" "$LNKIH" p felix
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- the third review's round 2: a miss said from the lane check's own reads (V3R2-F1, V3R2-F2) -----------------------
# Added on 2026-10-30 from its findings (inputs and observed output only) and C5 as 5e632334 amended it, still blind, last.
# _lf_v3r2's checkouts: T (origin o/r, which p's and q's remote_match name equally) and N (.felix naming nope, no origin)
# under H; MK (that .felix and that origin) under H2. felix lane runs no felix_binding_broken (C5), so a probe keyed to it
# may never fire: each run (_lf_spoke) exits 2 with nothing on stdout, says first on stderr C5's sentence for the layout
# (faulted, or C5's line for a resolution that did not finish), and leaves its memory root, empty before it, empty.
LNKWA="not built: V3R2's homes and checkouts"; _lf_v3r2 "$LNKD/v3r2" "$LNKN" && LNKWA=built
LNKWM=' A marker is present, so this tree was meant to be governed, and right now nothing is checking it.'; LNKWK="*' felix_binding_broken '*"; LNKa5='as C5 says memory[]|as C5 says memory[]'; LNKa6='as C5 says|as C5 says|as C5 says'
_lf_spoke "$LNKN" "$LF_V3H" "$LF_V3T" "felix: The origin of the checkout at $LF_V3T fits p, q equally well: each declares a remote_match that names it, with the same length. So no project is bound, and nothing is checking this tree." sed '*projects/q/project.json*' "$LNKWK" none fork kill; LNKb="$LF_SAID"
is "lane command V3R2-F1-binding-broken-writes-bindings-tsv L-RO: in a checkout whose origin p's and q's remote_match name equally (a tie), with C9's fork and kill probes at sed naming projects/q/project.json while felix_binding_broken is on the stack, felix lane --tsv and felix lane exit 2 with nothing on stdout, say first on stderr C5's tie sentence (or C5's line for a resolution that did not finish), and leave the memory root empty, no bindings.tsv; unfaulted, the tie sentence" "$LNKWA|$LF_SPOKE" "built|$LNKa5|$LNKa5|$LNKa5"
_lf_spoke "$LNKN" "$LF_V3H2" "$LF_V3MK" "felix: The .felix marker in $LF_V3MK names \"nope\", and that does not resolve to a project under $LF_V3H2/projects.$LNKWM" pwd "*' -P '*" "$LNKWK" none kill
is "lane command V3R2-F1-binding-broken-writes-bindings-tsv L-RO: in a checkout whose .felix names nope, no project, and whose origin p's remote_match names, with C9's kill probe at pwd -P while felix_binding_broken is on the stack, felix lane --tsv and felix lane exit 2 with nothing on stdout, say first on stderr C5's sentence for a marker that names no project (or C5's line for a resolution that did not finish), and leave the memory root empty, no bindings.tsv; unfaulted, that sentence" "$LNKWA|$LF_SPOKE" "built|$LNKa5|$LNKa5"
_lf_spoke "$LNKN" "$LF_V3H" "$LF_V3N" "felix: The .felix marker in $LF_V3N names \"nope\", and that does not resolve to a project under $LF_V3H/projects.$LNKWM" tr "*' -d [:space:] '*" "$LNKWK" none fork kill
is "lane command V3R2-F2-marker-and-tie-said-as-ungoverned: in a checkout whose .felix names nope, with no origin, under C9's fork and kill probes at tr -d [:space:] while felix_binding_broken is on the stack, and in the tie checkout under V3R2-F1's probes, felix lane --tsv and felix lane exit 2 with nothing on stdout and say first on stderr C5's sentence for the layout, names \"nope\" or the tie's (or C5's line for a resolution that did not finish); never is empty, never felix: no project governs <dir>.; unfaulted, the sentence" "$LNKWA|$LF_SAID|$LNKb" "built|$LNKa6|$LNKa6|$LNKa6|$LNKa6"
# <<< lane-command
