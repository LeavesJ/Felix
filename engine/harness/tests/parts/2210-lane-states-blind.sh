# >>> lane-states
printf '\nlane states: ok, short, zero, idle and unknown, each reason, and a table broken by hand (slice 0, design 6.4 and 6.6, C4, C5, L-RF3, L-NEVER-OK; blind)\n'
# Blind, written on 2026-10-29 from docs/2026-10-29-capability-lane-first-slices-design.md and the slice 0 plan's
# Contracts (C1-C13) alone, before lib/lane.sh existed, without reading lib/, hooks/, bin/ or felix. Felix is run as a
# black box; the builders are tests/lib/lane-fixture.sh's. C11's row for this part: section 6.4 and 6.6 "The state
# edges": C4's four edges, idle, an unreadable ref unknown; R1 to R10 (R9: a home that is not a git repository and holds
# lanes.tsv; R10: TMPDIR naming no directory); L-RF3; L-NEVER-OK; a fork that fails in the read of the landings (C9),
# with no scratch directory left after it (F1, F7).
#
# The home apart (C9): H holds project st, lanes.tsv (capability, ^engine/, 1/2, 14) and lane-next.tsv committed, and
# each checkout is bound to st by an untracked .felix. Every unknown case is asserted on the whole felix lane --tsv
# output (C5's thirteen columns, the reason exact) and, where its first row is the unknown one, on the last row of
# felix status --tsv, so L-NEVER-OK is asserted with the output it guards and is red on main (C10). Readings where the
# Contracts leave room:
# - The table cases run in one order in one home, so column 10 of a row is the commit of that case: each case's
#   capability lines differ from the case before it.
# - R1 is provoked four ways (no ref, a blob, a tree, a commit whose object is gone); a removed commit is the ref's own,
#   on a branch deleted before its object is removed, so HEAD stays readable.
# - Besides L-RF3's list: a lane cell that is no lane name (column 1 -), the order of the reasons (R5 before R7, R6
#   before R7, R5 before R6 on two rows of one lane, R8 before R1), a committed symlink (R4), a bad second row under a
#   comment and a blank line (row 2, the first row untouched), FELIX_LANE_NOW 12a and thirteen digits (R8), and 0, a
#   valid clock (idle).
# - The session-start halves of L-RF3 are controls (C10).
# - The review's second amendment (2026-10-30, design 11 item 45, still blind) adds C11's R10 (TMPDIR naming no
#   directory, F8) and no scratch directory left after a fork that fails (F7), each asserted with the output it guards.
# - The second review's round 2 (2026-10-30, still blind) adds, at the end, R2B-F2: the count's scratch directory taken
#   mid-count, in felix lane and the status row.
# - The second review's round 3 (2026-10-30, still blind) adds, at the end, R3-F1: a soft open-file limit from 10 to 24,
#   in felix lane --tsv and the status row.
LNSN=1793000000; LNSDAY=86400; LNSNEXT='take the lane item after this one'; LNSK=0
_lf_dir "$TMP/lane-2210"; LNSD="$LF_DIR"
_lf_stubs "$LNSD"; LNSB="$LF_BIN"
_lf_home "$LNSD/home" st 1792800000; LNSH="$LF_HOME"; LNSP="$LF_PROJ"
_lf_table "$LNSP" 1792800100 lanes.tsv $'capability\t^engine/\t1/2\t14\n'; LNSTAB="$LF_SHA"; LNSTABISO="$(_lf_iso 1792800100)"
_lf_table "$LNSP" 1792800200 lane-next.tsv "$(_lf_tsv capability "$LNSNEXT")"$'\n'
_lf_use "$LNSH" "$LNSD/memory" "$LNSD/user" "$LNSB"
LNSMARK='Felix-Lane: capability'
LNSR5="row 1 of lanes.tsv is not a lane name, an ERE, a share n/d and a window in days"
LNSR6="lane capability is named on more than one row of lanes.tsv"
LNSR7="the counts pattern of lane capability is not an ERE grep accepts"
LNSR8="FELIX_LANE_NOW is not a whole number of seconds"
LNSR4="$LNSP/lanes.tsv cannot be read as lanes.tsv"
_lns_py() { command -v python3 >/dev/null 2>&1; }
# COL1 W SHARE MARK NEXT CHANGED CHANGED-DATE REF-DATE REASON -> an unknown line of felix lane --tsv (C5): L, T and last -.
_lns_u() { _lf_tsv "$1" unknown - - "$2" "$3" - "$4" "$5" "$6" "$7" "$8" "$9"; }

# ---- the edges (C4, design 6.6) ------------------------------------------------------------------------------------------
# NAME SPEC... -> a checkout $LNSD/NAME: the root a month back, then SPEC's landings (_lf_chain) from five days before
# the clock, an hour apart, published. LNSR the checkout; LNSE "built" when its first-parent chain holds them all.
_lns_chk() {
  local n="$1"
  shift
  LNSE="not built: $n"; LNSR=""
  _lf_checkout "$LNSD/$n" st $((LNSN - 30 * LNSDAY)) || return 1
  LNSR="$LF_REPO"
  _lf_chain "$LNSR" capability $((LNSN - 5 * LNSDAY)) 3600 "$@" || return 1
  [ "$(_lf_spine "$LNSR" | LC_ALL=C awk '{ print NF }')" = "$(($# + 1))" ] && LNSE=built
}
# NAME -> LNSE|status|lines|columns 2, 3 and 4 of felix lane --tsv in LNSR at the clock.
_lns_read() {
  _lf_run "$LNSD/$1-run" "$LNSR" "$LNSN" "$FELIX" lane --tsv
  printf '%s|%s|%s|%s' "$LNSE" "$LF_RC" "$(_lf_count "$LNSD/$1-run.out")" "$(_lf_cols "$LNSD/$1-run.out" 1 2 3 4)"
}
_lns_chk edge-2of4 m m u u
is "lane states: share 1/2 with L 2 of T 4, so L*d = n*T with L at least 2, reads ok" "$(_lns_read edge-2of4)" "built|0|1|ok|2|4"
_lns_chk edge-1of4 m u u u
is "lane states: share 1/2 with one lane landing fewer, L 1 of T 4, reads short" "$(_lns_read edge-1of4)" "built|0|1|short|1|4"
_lns_chk edge-1of2 m u; LNSC="$LNSR"; LNSCE="$LNSE"; LNSREFD="$(_lf_iso $((LNSN - 5 * LNSDAY + 3600)))"
is "lane states: share 1/2 with L 1 of T 2, so L*d = n*T at L = 1, reads ok" "$(_lns_read edge-1of2)" "built|0|1|ok|1|2"
_lns_chk edge-0of2 u u
is "lane states: share 1/2 with one lane landing fewer at L = 1, L 0 of T 2, reads zero" "$(_lns_read edge-0of2)" "built|0|1|zero|0|2"
_lns_chk edge-docs md ud
is "lane states: T 0, two docs-only landings (one marked), reads idle" "$(_lns_read edge-docs)" "built|0|1|idle|0|0"
_lns_chk edge-none
is "lane states: T 0, no landing in the window at all (the root a month back), reads idle" "$(_lns_read edge-none)" "built|0|1|idle|0|0"

# ---- R1, R2 and R3: the ref and the landings cannot be read -------------------------------------------------------------
# NAME -> LNSR a checkout $LNSD/NAME with the root and one marked engine landing two days back, nothing published.
_lns_bare() {
  LNSR=""
  _lf_checkout "$LNSD/$1" st $((LNSN - 30 * LNSDAY)) || return 1
  LNSR="$LF_REPO"
  _lf_commit "$LNSR" $((LNSN - 2 * LNSDAY)) $'engine: x\n\nFelix-Lane: capability\n' engine/x.sh
}
# LABEL DIR WANT-LINE WANT-ROW [BUILT] -> felix lane --tsv in DIR prints WANT-LINE, and felix status --tsv ends with WANT-ROW.
_lns_two() {
  local l="$1" d="$2" w="$3" s="$4" b="${5:-built}" f
  LNSK=$((LNSK + 1)); f="$LNSD/two-$LNSK"
  _lf_run "$f-tsv" "$d" "$LNSN" "$FELIX" lane --tsv
  is "lane states L-NEVER-OK: $l: felix lane --tsv reads unknown with the C5 reason, never ok" "$b|$LF_RC|$(cat "$f-tsv.out")" "built|0|$w"
  _lf_run "$f-st" "$d" "$LNSN" "$FELIX" status --tsv
  is "lane states L-NEVER-OK: $l: the status row is lane unknown - with that reason, never the value ok" "$b|$LF_RC|$(_lf_last "$f-st.out")" "built|0|$s"
}
_lns_bare r1-none; LNSR1N="$LNSR"
LNSa="$( _fx_cd "$LNSR" || exit 1; _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main >/dev/null 2>&1 && echo has-ref || echo built )"
LNSa2="refs/remotes/origin/main cannot be read in $LNSR"
_lns_two "R1, a checkout with no refs/remotes/origin/main" "$LNSR" \
  "$(_lns_u capability 14 1/2 "$LNSMARK" "$LNSNEXT" "$LNSTAB" "$LNSTABISO" - "$LNSa2")" "$(_lf_tsv lane unknown - "$LNSa2")" "$LNSa"

_lns_bare r1-blob
LNSa="$( _fx_cd "$LNSR" || exit 1; b="$(printf 'not a commit\n' | _lf_g 1700000000 hash-object -w --stdin)" && _lf_g 1700000000 update-ref refs/remotes/origin/main "$b" \
         && [ "$(_lf_g 1700000000 cat-file -t refs/remotes/origin/main)" = blob ] && echo built )"
LNSa2="refs/remotes/origin/main cannot be read in $LNSR"
_lf_run "$LNSD/r1-blob-run" "$LNSR" "$LNSN" "$FELIX" lane --tsv
is "lane states L-NEVER-OK: R1, refs/remotes/origin/main naming a blob: felix lane --tsv reads unknown with R1, column 12 -" \
   "$LNSa|$LF_RC|$(cat "$LNSD/r1-blob-run.out")" "built|0|$(_lns_u capability 14 1/2 "$LNSMARK" "$LNSNEXT" "$LNSTAB" "$LNSTABISO" - "$LNSa2")"

_lns_bare r1-tree
LNSa="$( _fx_cd "$LNSR" || exit 1; _lf_g 1700000000 update-ref refs/remotes/origin/main "HEAD^{tree}" \
         && [ "$(_lf_g 1700000000 cat-file -t refs/remotes/origin/main)" = tree ] && echo built )"
LNSa2="refs/remotes/origin/main cannot be read in $LNSR"
_lf_run "$LNSD/r1-tree-run" "$LNSR" "$LNSN" "$FELIX" lane --tsv
is "lane states L-NEVER-OK: R1, refs/remotes/origin/main naming a tree: felix lane --tsv reads unknown with R1, column 12 -" \
   "$LNSa|$LF_RC|$(cat "$LNSD/r1-tree-run.out")" "built|0|$(_lns_u capability 14 1/2 "$LNSMARK" "$LNSNEXT" "$LNSTAB" "$LNSTABISO" - "$LNSa2")"

_lns_bare r1-gone; LNSa=""
if _lf_branch "$LNSR" side && _lf_commit "$LNSR" $((LNSN - LNSDAY)) $'engine: y\n\nFelix-Lane: capability\n' engine/y.sh \
   && _lf_publish "$LNSR" && _lf_switch "$LNSR" main \
   && ( _fx_cd "$LNSR" && _lf_g 1700000000 branch -q -D side ) >/dev/null 2>&1 && _lf_unobject "$LNSR" refs/remotes/origin/main; then
  LNSa="$( _fx_cd "$LNSR" || exit 1; _lf_g 1700000000 cat-file -e refs/remotes/origin/main 2>/dev/null && echo still-there || echo built )"
fi
LNSa2="refs/remotes/origin/main cannot be read in $LNSR"
_lf_run "$LNSD/r1-gone-run" "$LNSR" "$LNSN" "$FELIX" lane --tsv
is "lane states L-NEVER-OK: R1, refs/remotes/origin/main naming a commit whose object is gone: felix lane --tsv reads unknown with R1, column 12 -" \
   "${LNSa:-not built}|$LF_RC|$(cat "$LNSD/r1-gone-run.out")" "built|0|$(_lns_u capability 14 1/2 "$LNSMARK" "$LNSNEXT" "$LNSTAB" "$LNSTABISO" - "$LNSa2")"

# ---- the review's F4: a tag or a branch named refs/remotes/origin/main is not the ref (C2, R1) ------------------------
# Added on 2026-10-30 from the adversarial review of the first build, still blind. C2 reads refs/remotes/origin/main by
# its full name, with no fallback to another ref. git's lookup of a short name finds refs/tags/refs/remotes/origin/main
# and refs/heads/refs/remotes/origin/main under that spelling, so each is made in a checkout that has no
# refs/remotes/origin/main, at its HEAD, a marked engine landing, and must read R1 as that checkout does without it.
# NAME REF -> LNSR a checkout as _lns_bare builds it, REF naming its HEAD. LNSa "built" when REF exists, no
# refs/remotes/origin/main does, and git's lookup of the short name refs/remotes/origin/main finds HEAD.
_lns_decoy() {
  LNSa=""
  _lns_bare "$1" && LNSa="$( _fx_cd "$LNSR" || exit 1; h="$(_lf_g 1700000000 rev-parse --verify -q HEAD)" \
    && _lf_g 1700000000 update-ref "$2" "$h" && _lf_g 1700000000 show-ref --verify -q "$2" \
    && ! _lf_g 1700000000 show-ref --verify -q refs/remotes/origin/main \
    && [ "$(_lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main 2>/dev/null)" = "$h" ] && echo built )"
  [ -n "$LNSa" ] || LNSa="not built: $1"
}
_lns_decoy f4-tag refs/tags/refs/remotes/origin/main
LNSa2="refs/remotes/origin/main cannot be read in $LNSR"
_lns_two "F4-decoy-ref-name-read-as-origin-main: R1, no refs/remotes/origin/main and a tag named refs/remotes/origin/main at a marked engine landing" \
  "$LNSR" "$(_lns_u capability 14 1/2 "$LNSMARK" "$LNSNEXT" "$LNSTAB" "$LNSTABISO" - "$LNSa2")" "$(_lf_tsv lane unknown - "$LNSa2")" "$LNSa"
_lns_decoy f4-branch refs/heads/refs/remotes/origin/main
LNSa2="refs/remotes/origin/main cannot be read in $LNSR"
_lns_two "F4-decoy-ref-name-read-as-origin-main: R1, no refs/remotes/origin/main and a branch named refs/remotes/origin/main at a marked engine landing" \
  "$LNSR" "$(_lns_u capability 14 1/2 "$LNSMARK" "$LNSNEXT" "$LNSTAB" "$LNSTABISO" - "$LNSa2")" "$(_lf_tsv lane unknown - "$LNSa2")" "$LNSa"

_lns_chk r2 m u u u; LNSa="not built: r2"
[ "$LNSE" = built ] && _lf_unobject "$LNSR" refs/remotes/origin/main~2 \
  && LNSa="$( _fx_cd "$LNSR" || exit 1; _lf_g 1700000000 cat-file -e refs/remotes/origin/main~2 2>/dev/null && echo still-there || echo built )"
LNSa2="git could not read the landings on refs/remotes/origin/main in $LNSR"
_lns_two "R2, the commit two first parents below the ref removed from the object store" "$LNSR" \
  "$(_lns_u capability 14 1/2 "$LNSMARK" "$LNSNEXT" "$LNSTAB" "$LNSTABISO" "$(_lf_iso $((LNSN - 5 * LNSDAY + 3 * 3600)))" "$LNSa2")" \
  "$(_lf_tsv lane unknown - "$LNSa2")" "$LNSa"

# ---- the review's F1: a fork that fails in the read of the landings (C3, R2) ------------------------------------------
# Added on 2026-10-30 from the adversarial review of the first build, still blind. C3 counts a fork that fails among the
# git reads that do not finish: the lane reads unknown with R2, never no lane, never a count, and felix lane still exits
# 0 with its line (C5). The fault is the review's: a bash function git, exported into felix, that lowers the process
# limit to 1 (ulimit -S -u 1) in the shell running it when its words hold --first-parent and refs/remotes/origin/main,
# the read of the landings, and then runs git, which that shell cannot fork. It writes "fired" to a file (a builtin, no
# fork) first, and "ran <status>" after git if the shell gets there; "ran 0" would mean the fault did not stop git. Every
# other git read is left alone. Columns 10 to 12 are not compared: C3 does not say whether a read after the failed one,
# in the same shell, is made. The checkout reads zero, L 0 of T 2, without the fault.
# OUT CMD... -> CMD run from LNSR at the clock as _lf_run runs it, with that function exported; LF_RC its status, LNSFIRE
# "fired" when the function fired and git did not run to a clean exit after it.
_lns_fork() {
  local o="$1" f="$1.fired"
  shift
  rm -f "$f"
  ( eval "git() { local z='' r; case \" \$* \" in *' --first-parent '*) case \" \$* \" in *' refs/remotes/origin/main'*) z=1; printf 'fired\n' >> $(printf '%q' "$f"); ulimit -S -u 1 ;; esac ;; esac; command git \"\$@\"; r=\$?; [ -z \"\$z\" ] || printf 'ran %s\n' \"\$r\" >> $(printf '%q' "$f"); return \"\$r\"; }"
    export -f git
    _lf_run "$o" "$LNSR" "$LNSN" "$@"
    exit "$LF_RC" )
  LF_RC=$?
  LNSFIRE="$(LC_ALL=C awk '$0 == "fired" { f = 1 } $0 == "ran 0" { r = 1 }
    END { s = "not fired"; if (f && r) s = "fired, but git ran to a clean exit after it"; if (f && !r) s = "fired"; print s }' "$f" 2>/dev/null)"
  [ -n "$LNSFIRE" ] || LNSFIRE="not fired"
}
_lns_chk f1-fork u u
LNSa2="git could not read the landings on refs/remotes/origin/main in $LNSR"
_lns_fork "$LNSD/f1-tsv" "$FELIX" lane --tsv
is "lane states F1-fork-reads-as-no-lane L-NEVER-OK: a fork that fails in the read of the landings on refs/remotes/origin/main makes felix lane --tsv exit 0 with one line, unknown with R2, L and T -, never no line and never a count" \
   "$LNSE|$LNSFIRE|$LF_RC|$(_lf_count "$LNSD/f1-tsv.out")|$(_lf_cols "$LNSD/f1-tsv.out" 1 1 2 3 4 5 6 7 8 9 13)" \
   "built|fired|0|1|capability|unknown|-|-|14|1/2|-|$LNSMARK|$LNSNEXT|$LNSa2"
_lns_fork "$LNSD/f1-st" "$FELIX" status --tsv
is "lane states F1-fork-reads-as-no-lane L-NEVER-OK: the same fault in felix status --tsv makes the lane row lane unknown - with R2, the last of ten, never none and never a value" \
   "$LNSE|$LNSFIRE|$LF_RC|$(_lf_count "$LNSD/f1-st.out")|$(_lf_last "$LNSD/f1-st.out")" "built|fired|0|10|$(_lf_tsv lane unknown - "$LNSa2")"

# ---- the review's F7: a fork that fails in a git read leaves no scratch directory (C2) ---------------------------------
# Added on 2026-10-30 from the review's second amendment, still blind. C2: scratch files go under ${TMPDIR:-/tmp}, in
# one directory named felix-lane.XXXXXX, and a fork that fails inside a git read leaves none. The fault is F1's above,
# through _lf_fault, with TMPDIR a directory of the fixture's own, empty before each run; after it the felix-lane.*
# entries there are named. Each is asserted with the R2 output it guards, which main cannot print (C10).
LNSF1="$LNSR"; LNSF1E="$LNSE"
# NAME CMD... -> CMD run from the F1 checkout at the clock under the fork fault, TMPDIR $LNSD/NAME-tmp made empty first;
# LF_RC and LF_FIRE as _lf_fault sets them, LNSLEFT the felix-lane.* entries left in that TMPDIR, or none.
_lns_f7() {
  local n="$1" t="$LNSD/$1-tmp" e
  shift
  rm -rf "$t"; mkdir -p "$t"
  _lf_fault fork "$LNSD/$n.fired" "$t" _lf_run "$LNSD/$n" "$LNSF1" "$LNSN" "$@"
  LNSLEFT=""
  for e in "$t"/felix-lane.*; do [ ! -e "$e" ] || LNSLEFT="$LNSLEFT${LNSLEFT:+ }${e##*/}"; done
  [ -n "$LNSLEFT" ] || LNSLEFT=none
}
LNSa2="git could not read the landings on refs/remotes/origin/main in $LNSF1"
_lns_f7 f7-tsv "$FELIX" lane --tsv
is "lane states F7-scratch-left-when-a-fork-fails L-NEVER-OK: after a fork that fails in the read of the landings, with TMPDIR a directory of the fixture's own, no felix-lane.* entry is left there, and felix lane --tsv exited 0 with its one R2 line" \
   "$LNSF1E|$LF_FIRE|$LF_RC|$(_lf_count "$LNSD/f7-tsv.out")|$(_lf_cols "$LNSD/f7-tsv.out" 1 1 2 3 4 5 6 7 8 9 13)|left[$LNSLEFT]" \
   "built|fired|0|1|capability|unknown|-|-|14|1/2|-|$LNSMARK|$LNSNEXT|$LNSa2|left[none]"
_lns_f7 f7-st "$FELIX" status --tsv
is "lane states F7-scratch-left-when-a-fork-fails L-NEVER-OK: the same in felix status --tsv leaves no felix-lane.* entry in that TMPDIR, and the lane row was lane unknown - with R2, the last of ten" \
   "$LNSF1E|$LF_FIRE|$LF_RC|$(_lf_count "$LNSD/f7-st.out")|$(_lf_last "$LNSD/f7-st.out")|left[$LNSLEFT]" \
   "built|fired|0|10|$(_lf_tsv lane unknown - "$LNSa2")|left[none]"

_lns_chk r3-source m u m; LNSa="not built: r3"
if [ "$LNSE" = built ] && ( _fx_cd "$LNSD" && _lf_g 1700000000 clone -q --depth 2 "file://$LNSR" r3 ) >/dev/null 2>&1; then
  { printf 'st\n' > "$LNSD/r3/.felix"; } 2>/dev/null
  LNSa="$( _fx_cd "$LNSD/r3" || exit 1; [ "$(_lf_g 1700000000 rev-parse --is-shallow-repository)" = true ] \
           && _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main >/dev/null && echo built )"
fi
LNSa2="$LNSD/r3 is a shallow clone, so its landings cannot all be read"
_lns_two "R3, a --depth 2 clone" "$LNSD/r3" \
  "$(_lns_u capability 14 1/2 "$LNSMARK" "$LNSNEXT" "$LNSTAB" "$LNSTABISO" "$(_lf_iso $((LNSN - 5 * LNSDAY + 2 * 3600)))" "$LNSa2")" \
  "$(_lf_tsv lane unknown - "$LNSa2")" "${LNSa:-not built: r3}"

# ---- R9: a home git cannot read ------------------------------------------------------------------------------------------
# DIR [init] -> a home at DIR holding projects/st/project.json and CLAUDE.md, outside any repository (with init: an
# empty repository, HEAD naming no commit). LNSa "built" when it is as named.
_lns_home9() {
  LNSa="not built: $1"
  rm -rf "$1"; mkdir -p "$1/projects/st" || return 1
  [ "${2:-}" != init ] || _lf_init "$1" || return 1
  printf '{"name":"st","gate":"true"}\n' > "$1/projects/st/project.json"; printf '# st\n' > "$1/projects/st/CLAUDE.md"
  if [ "${2:-}" = init ]; then
    ( _fx_cd "$1" && _lf_g 1700000000 rev-parse --verify -q HEAD ) >/dev/null 2>&1 || LNSa=built
  else
    ( _fx_cd "$1" && _lf_g 1700000000 rev-parse --git-dir ) >/dev/null 2>&1 || LNSa=built
  fi
}
_lns_home9 "$LNSD/home9"; printf 'capability\t^engine/\t1/2\t14\n' > "$LNSD/home9/projects/st/lanes.tsv"
_lf_use "$LNSD/home9" "$LNSD/memory" "$LNSD/user" "$LNSB"
LNSa2="$LNSD/home9/projects/st/lanes.tsv cannot be read as committed in the Felix home"
_lns_two "R9, a home that is not a git repository and holds lanes.tsv" "$LNSC" "$(_lns_u - - - - - - - "$LNSREFD" "$LNSa2")" \
  "$(_lf_tsv lane unknown - "$LNSa2")" "$LNSa"
_lns_home9 "$LNSD/home9u" init; printf 'capability\t^engine/\t1/2\t14\n' > "$LNSD/home9u/projects/st/lanes.tsv"
_lf_use "$LNSD/home9u" "$LNSD/memory" "$LNSD/user" "$LNSB"
LNSa2="$LNSD/home9u/projects/st/lanes.tsv cannot be read as committed in the Felix home"
_lf_run "$LNSD/r9u-run" "$LNSC" "$LNSN" "$FELIX" lane --tsv
is "lane states L-NEVER-OK: R9, a home whose repository has no commit and which holds lanes.tsv: felix lane --tsv reads unknown with R9" \
   "$LNSa|$LF_RC|$(cat "$LNSD/r9u-run.out")" "built|0|$(_lns_u - - - - - - - "$LNSREFD" "$LNSa2")"
_lns_home9 "$LNSD/home9n"
_lf_use "$LNSD/home9n" "$LNSD/memory" "$LNSD/user" "$LNSB"
_lf_run "$LNSD/r9n-run" "$LNSC" "$LNSN" "$FELIX" lane --tsv
is "lane states: a home that is not a git repository and holds no lanes.tsv counts no lane: felix lane --tsv prints nothing and exits 0" \
   "$LNSa|$LF_RC|$(wc -c < "$LNSD/r9n-run.out" | tr -d ' ')" "built|0|0"
_lf_use "$LNSH" "$LNSD/memory" "$LNSD/user" "$LNSB"

# ---- the review's F8: R10, a scratch directory that cannot be made (C2, C5, C6) ----------------------------------------
# Added on 2026-10-30 from the review's second amendment, still blind. With TMPDIR naming a directory that does not
# exist, given on the felix command alone, and the home readable with its valid table committed, the table reads R10
# with TMPDIR as the environment gives it: the single - line of C5, column 12 the ref's date as on an R9 line, and the
# status row lane unknown - R10. Never R9, which is for a home git cannot read.
LNSNT="$LNSD/no-such-tmp"; rm -rf "$LNSNT"; LNSa2="no scratch directory could be made under $LNSNT"
_lf_run "$LNSD/r10-tsv" "$LNSC" "$LNSN" TMPDIR="$LNSNT" "$FELIX" lane --tsv
is "lane states F8-unusable-tmpdir-reads-r9 L-NEVER-OK: R10, TMPDIR naming a directory that does not exist over a valid committed table: felix lane --tsv prints the one - line, unknown with R10, never R9" \
   "$LNSCE|$([ -e "$LNSNT" ] && echo made || echo absent)|$LF_RC|$(cat "$LNSD/r10-tsv.out")" "built|absent|0|$(_lns_u - - - - - - - "$LNSREFD" "$LNSa2")"
_lf_run "$LNSD/r10-st" "$LNSC" "$LNSN" TMPDIR="$LNSNT" "$FELIX" status --tsv
is "lane states F8-unusable-tmpdir-reads-r9 L-NEVER-OK: R10: the same TMPDIR makes the status row lane unknown - with R10, the last of ten, never R9 and never a value" \
   "$LNSCE|$([ -e "$LNSNT" ] && echo made || echo absent)|$LF_RC|$(_lf_count "$LNSD/r10-st.out")|$(_lf_last "$LNSD/r10-st.out")" \
   "built|absent|0|10|$(_lf_tsv lane unknown - "$LNSa2")"

# ---- L-RF3: a table broken by hand, committed, in the base checkout (L 1 of T 2) ---------------------------------------
# LABEL BYTES -> lanes.tsv holds BYTES, committed in the home at the next time. LNSSHA the commit, LNSISO its date, and
# LNSBUILT "built" when the home's HEAD holds exactly BYTES and the base checkout was built.
_lns_put() {
  local t f
  LNSK=$((LNSK + 1)); t=$((1792801000 + 100 * LNSK)); f="$LNSD/put-$LNSK"
  LNSSHA=""; LNSISO="$(_lf_iso "$t")"; LNSBUILT="not built: $1"
  rm -f "$LNSP/lanes.tsv"
  _lf_table "$LNSP" "$t" lanes.tsv "$2" "lanes.tsv: $1"$'\n' || return 1
  LNSSHA="$LF_SHA"
  printf '%s' "$2" > "$f.want"
  ( _fx_cd "$LNSH" || exit 1; _lf_g 1700000000 cat-file blob "HEAD:projects/st/lanes.tsv" ) > "$f.got" 2>/dev/null
  cmp -s "$f.want" "$f.got" && [ "$LNSCE" = built ] && LNSBUILT=built
}
# LABEL WANT-LINES WANT-ROW [NOW] -> in the base checkout: felix lane --tsv prints WANT-LINES, felix status --tsv ends with
# WANT-ROW, and session start says nothing of the lane (the control).
_lns_three() {
  local l="$1" w="$2" s="$3" n="${4:-$LNSN}" f="$LNSD/case-$LNSK"
  _lf_run "$f-tsv" "$LNSC" "$n" "$FELIX" lane --tsv
  is "lane states L-RF3 L-NEVER-OK: $l: felix lane --tsv reads unknown with the C5 reason, never ok" "$LNSBUILT|$LF_RC|$(cat "$f-tsv.out")" "built|0|$w"
  _lf_run "$f-st" "$LNSC" "$n" "$FELIX" status --tsv
  is "lane states L-RF3 L-NEVER-OK: $l: the status row is lane unknown - with that reason, never the value ok" "$LNSBUILT|$LF_RC|$(_lf_last "$f-st.out")" "built|0|$s"
  if _lns_py; then
    _lf_start "$f-ss" "$LNSC" "$n" startup
    is "lane states L-RF3: $l: session start exits 0 with valid JSON and neither a lane paragraph nor a lane token (control)" \
       "$LNSBUILT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|0|ok|none"
  else
    skip "lane states L-RF3: $l: session start exits 0 with valid JSON and neither a lane paragraph nor a lane token (control)" "python3 is absent, and the hook's JSON is read with it"
  fi
}
# SHARE -> the case of one row whose share is SHARE (R5); _lns_window W -> the case of one row whose window is W (R5).
_lns_share() {
  _lns_put "share $1" "$(_lf_tsv capability '^engine/' "$1" 14)"$'\n'
  _lns_three "share $1 committed" "$(_lns_u capability - - - - "$LNSSHA" "$LNSISO" "$LNSREFD" "$LNSR5")" "$(_lf_tsv lane unknown - "$LNSR5")"
}
_lns_window() {
  _lns_put "window $1" "$(_lf_tsv capability '^engine/' 1/2 "$1")"$'\n'
  _lns_three "window $1 committed" "$(_lns_u capability - - - - "$LNSSHA" "$LNSISO" "$LNSREFD" "$LNSR5")" "$(_lf_tsv lane unknown - "$LNSR5")"
}
_lns_share 1/0
_lns_share 3/2
_lns_share 0/2
_lns_share 1/2/3
_lns_window 0
_lns_window 14d
_lns_window 014
_lns_put "counts (" $'capability\t(\t1/2\t14\n'
_lns_three "counts ( committed" "$(_lns_u capability - - - - "$LNSSHA" "$LNSISO" "$LNSREFD" "$LNSR7")" "$(_lf_tsv lane unknown - "$LNSR7")"
_lns_put "a lane named twice" $'capability\t^engine/\t1/2\t14\ncapability\t^engine/\t1/2\t14\n'
LNSa="$(_lns_u capability - - - - "$LNSSHA" "$LNSISO" "$LNSREFD" "$LNSR6")"
_lns_three "the lane named on two rows" "$LNSa"$'\n'"$LNSa" "$(_lf_tsv lane unknown - "$LNSR6")"
_lns_put "a CR in a row" $'capability\t^engine/\t1/2\t14\r\n'
_lns_three "a CR at the end of the row" "$(_lns_u - - - - - - - "$LNSREFD" "$LNSR4")" "$(_lf_tsv lane unknown - "$LNSR4")"
_lns_put "no final newline" $'capability\t^engine/\t1/2\t14'
_lns_three "no newline after the last row" "$(_lns_u - - - - - - - "$LNSREFD" "$LNSR4")" "$(_lf_tsv lane unknown - "$LNSR4")"
_lns_put "an empty cell" $'capability\t\t1/2\t14\n'
_lns_three "an empty counts cell" "$(_lns_u - - - - - - - "$LNSREFD" "$LNSR4")" "$(_lf_tsv lane unknown - "$LNSR4")"
_lns_put "a row of three cells" $'capability\t^engine/\t1/2\n'
_lns_three "a row of three cells" "$(_lns_u - - - - - - - "$LNSREFD" "$LNSR4")" "$(_lf_tsv lane unknown - "$LNSR4")"
_lns_put "valid again" $'capability\t^engine/\t1/2\t14\n'; LNSVALID="$LNSSHA"; LNSVALIDISO="$LNSISO"
_lns_three "FELIX_LANE_NOW=0123 over a valid table" \
  "$(_lns_u capability 14 1/2 "$LNSMARK" "$LNSNEXT" "$LNSSHA" "$LNSISO" "$LNSREFD" "$LNSR8")" "$(_lf_tsv lane unknown - "$LNSR8")" 0123

# ---- R8 and a valid clock, over the valid table -----------------------------------------------------------------------
_lf_run "$LNSD/r8-a" "$LNSC" 12a "$FELIX" lane --tsv
is "lane states L-NEVER-OK: FELIX_LANE_NOW=12a reads unknown with R8" "$LNSBUILT|$LF_RC|$(cat "$LNSD/r8-a.out")" \
   "built|0|$(_lns_u capability 14 1/2 "$LNSMARK" "$LNSNEXT" "$LNSVALID" "$LNSVALIDISO" "$LNSREFD" "$LNSR8")"
_lf_run "$LNSD/r8-13" "$LNSC" 1234567890123 "$FELIX" lane --tsv
is "lane states L-NEVER-OK: FELIX_LANE_NOW of thirteen digits reads unknown with R8" "$LNSBUILT|$LF_RC|$(cat "$LNSD/r8-13.out")" \
   "built|0|$(_lns_u capability 14 1/2 "$LNSMARK" "$LNSNEXT" "$LNSVALID" "$LNSVALIDISO" "$LNSREFD" "$LNSR8")"
_lf_run "$LNSD/r8-0" "$LNSC" 0 "$FELIX" lane --tsv
is "lane states: FELIX_LANE_NOW=0 is a valid clock, before every landing: idle, L 0 of T 0, last lane landing none" \
   "$LNSBUILT|$LF_RC|$(_lf_cols "$LNSD/r8-0.out" 1 1 2 3 4 7 13)" "built|0|capability|idle|0|0|none|-"
_lf_run "$LNSD/r8-r1" "$LNSR1N" 0123 "$FELIX" lane --tsv
is "lane states L-NEVER-OK: FELIX_LANE_NOW=0123 in a checkout with no ref reads R8, tried before R1, column 12 -" \
   "$LNSBUILT|$LF_RC|$(cat "$LNSD/r8-r1.out")" "built|0|$(_lns_u capability 14 1/2 "$LNSMARK" "$LNSNEXT" "$LNSVALID" "$LNSVALIDISO" - "$LNSR8")"

# ---- more tables: a lane cell that is no lane name, the reasons' order, a symlink, a bad second row ---------------------
_lns_put "a lane cell that is no lane name" $'.x\t^engine/\t1/2\t14\n'
_lns_two "a lane cell .x that is no lane name: R5, column 1 -" "$LNSC" "$(_lns_u - - - - - - - "$LNSREFD" "$LNSR5")" \
  "$(_lf_tsv lane unknown - "$LNSR5")" "$LNSBUILT"
_lns_put "R5 before R7" $'capability\t(\t3/2\t14\n'
_lns_two "counts ( beside share 3/2: R5, tried before R7" "$LNSC" "$(_lns_u capability - - - - "$LNSSHA" "$LNSISO" "$LNSREFD" "$LNSR5")" \
  "$(_lf_tsv lane unknown - "$LNSR5")" "$LNSBUILT"
_lns_put "R6 before R7" $'capability\t(\t1/2\t14\ncapability\t(\t1/2\t14\n'
LNSa="$(_lns_u capability - - - - "$LNSSHA" "$LNSISO" "$LNSREFD" "$LNSR6")"
_lns_two "counts ( on two rows of one lane: R6 on both, tried before R7" "$LNSC" "$LNSa"$'\n'"$LNSa" "$(_lf_tsv lane unknown - "$LNSR6")" "$LNSBUILT"
_lns_put "R5 then R6" $'capability\t^engine/\t3/2\t14\ncapability\t^engine/\t1/2\t14\n'
_lns_two "two rows of one lane, the first with share 3/2: R5 on row 1, R6 on row 2" "$LNSC" \
  "$(_lns_u capability - - - - "$LNSSHA" "$LNSISO" "$LNSREFD" "$LNSR5")"$'\n'"$(_lns_u capability - - - - "$LNSSHA" "$LNSISO" "$LNSREFD" "$LNSR6")" \
  "$(_lf_tsv lane unknown - "$LNSR5")" "$LNSBUILT"
LNSK=$((LNSK + 1)); LNSBUILT="not built: a symlink"; rm -f "$LNSP/lanes.tsv" "$LNSP/elsewhere.tsv"
printf 'capability\t^engine/\t1/2\t14\n' > "$LNSP/elsewhere.tsv"
if ln -s elsewhere.tsv "$LNSP/lanes.tsv" && _lf_commit "$LNSP" $((1792801000 + 100 * LNSK)) $'lanes.tsv: a symlink\n' =elsewhere.tsv =lanes.tsv; then
  case "$( _fx_cd "$LNSH" && _lf_g 1700000000 ls-tree HEAD projects/st/lanes.tsv )" in (120000*) LNSBUILT=built ;; esac
fi
_lns_two "lanes.tsv committed as a symlink: R4" "$LNSC" "$(_lns_u - - - - - - - "$LNSREFD" "$LNSR4")" "$(_lf_tsv lane unknown - "$LNSR4")" "$LNSBUILT"
_lns_put "valid again" $'capability\t^engine/\t1/2\t14\n'; LNSVALID="$LNSSHA"; LNSVALIDISO="$LNSISO"
_lns_put "a bad second row" $'# the lanes, the second one broken\ncapability\t^engine/\t1/2\t14\n\ndocs\t^docs/\t1/2\t014\n'
_lf_run "$LNSD/row2" "$LNSC" "$LNSN" "$FELIX" lane --tsv
is "lane states: a second data row with window 014, under a comment and a blank line, reads R5 as row 2, and the first row keeps its state ok and its last change" \
   "$LNSBUILT|$LF_RC|$(cat "$LNSD/row2.out")" \
   "built|0|$(_lf_tsv capability ok 1 2 14 1/2 "$(_lf_iso $((LNSN - 5 * LNSDAY)))" "$LNSMARK" "$LNSNEXT" "$LNSVALID" "$LNSVALIDISO" "$LNSREFD" -)
$(_lns_u docs - - - - "$LNSSHA" "$LNSISO" "$LNSREFD" "row 2 of lanes.tsv is not a lane name, an ERE, a share n/d and a window in days")"

# ---- the second review's round 1: forks that fail outside the read of the landings (R2-F1, R2-F4, R2-F9) ---------------
# Added on 2026-10-30 from the second review's findings (their inputs and observed output only), still blind. Each runs in
# the review's home-apart fixture (_lf_r2): lanes cap (^engine/, 1/2, 14) and sec (^docs/, 1/2, 7), a checkout where cap
# reads zero, L 0 of T 2, and sec short, L 1 of T 3, its landings dated from the machine clock at build time, so that
# R2-F1 can leave FELIX_LANE_NOW unset. The faults are the review's fork probes (_lf_fork), each at the read its finding
# names, by the words and the calling function it names: inputs of the finding, not read from the engine. Each assertion
# also compares the same command without the fault, so it is red on main, which prints no lane. Readings: a fork that
# fails is a read that did not finish (C3), so the accepted endings are an unknown line or row, or C3's count that did
# not finish, never a count from what was not read; where the shape check itself could not run, R9 (C2's table that
# cannot be read) stands beside R4 for a table the check would refuse, and never R4 for one it would accept (R2-F9).
LNSRN="$(date +%s)"; LNSRT="$LNSD/r2-tmp"; mkdir -p "$LNSRT"; LNSRA="not built: the second review's fixture"
_lf_r2 "$LNSD/r2" p "$LNSRN" && LNSRA=built
LNSRC="$LF_REPO"; LNSRH="$LF_HOME"; LNSRP="$LF_PROJ"; LNSRL="$LF_R2"; LNSRLU="$LF_R2AU"$'\n'"$LF_R2BU"
LNSRREF="$(_lf_iso $((LNSRN - LNSDAY)))"; LNSRV="$(_lf_tsv lane value zero '0 of 2 engine landings in 14 days, target 1/2')"
LNSRR9="$LNSRP/lanes.tsv cannot be read as committed in the Felix home"; LNSREND="the lane count did not finish in $LNSRC"
_lf_use "$LNSRH" "$LNSD/memory" "$LNSD/user" "$LNSB"
# OUT -> "unknown or ended" when the felix lane --tsv run whose files are OUT.out and OUT.err ended as C3's count that did
# not finish, or exited 0 with one line for cap and one for sec, each unknown with L, T and the last lane landing - and a
# reason; else what it printed.
_lns_r2u() {
  if [ "$(_lf_ended "$1" "$LNSRC")" = ended ] || { [ "$LF_RC" = 0 ] && [ "$(LC_ALL=C awk -F'\t' '((NR == 1 && $1 == "cap") || (NR == 2 && $1 == "sec")) && NF == 13 && $2 == "unknown" && $3 == "-" && $4 == "-" && $7 == "-" && $13 != "" && $13 != "-" { n++ } END { print n + 0, NR }' "$1.out")" = "2 2" ]; }; then
    printf 'unknown or ended'; return 0
  fi
  printf 'status %s, stdout [%s], stderr [%s]' "$LF_RC" "$(cat "$1.out")" "$(cat "$1.err")"
}
# OUT ROW... -> "one of them" when the felix status --tsv run whose files are OUT.* exited 0 with ten rows, the last one of
# the ROWs; a ROW that is "unknown" stands for any lane unknown - row with a reason. Else the status, rows and last row.
_lns_r2row() {
  local o="$1" l n w tb=$'\t'
  l="$(_lf_last "$o.out")"; n="$(_lf_count "$o.out")"
  shift
  for w in "$@"; do
    if [ "$w" = unknown ]; then
      case "$l" in ("lane${tb}unknown${tb}-${tb}"*) case "${l##*"$tb"}" in (''|-) ;; (*) w="$l" ;; esac ;; esac
    fi
    [ "$LF_RC|$n|$l" != "0|10|$w" ] || { printf 'one of them'; return 0; }
  done
  printf 'status %s, %s rows, last [%s]' "$LF_RC" "$n" "$l"
}

# R2-F1: the count's read of the machine clock. FELIX_LANE_NOW unset, as in real use; the probe is an exported date that
# acts on the words -u +%s with _lane_rows on the call stack (the review's names).
_lf_run "$LNSD/r2f1-0" "$LNSRC" - "$FELIX" lane --tsv; LNSb="$LF_RC|$(cat "$LNSD/r2f1-0.out")"
_lf_fork fork date "' -u +%s '" "*' _lane_rows '*" "$LNSD/r2f1-t.fired" "$LNSRT" _lf_run "$LNSD/r2f1-t" "$LNSRC" - "$FELIX" lane --tsv
is "lane states R2-F1-clock-fork-reads-idle L-NEVER-OK: with FELIX_LANE_NOW unset, a fork that fails in the count's read of the machine clock (date -u +%s) makes felix lane --tsv read cap and sec unknown with a reason, or end as C3's count that did not finish; never idle from an empty clock, where without the fault cap reads zero and sec short" \
   "$LNSRA|unfaulted $LNSb|$LF_FIRE|$(_lns_r2u "$LNSD/r2f1-t")" "built|unfaulted 0|$LNSRL|fired|unknown or ended"
_lf_run "$LNSD/r2f1-s0" "$LNSRC" - "$FELIX" status --tsv; LNSb="$(_lns_r2row "$LNSD/r2f1-s0" "$LNSRV")"
_lf_fork fork date "' -u +%s '" "*' _lane_rows '*" "$LNSD/r2f1-s.fired" "$LNSRT" _lf_run "$LNSD/r2f1-s" "$LNSRC" - "$FELIX" status --tsv
is "lane states R2-F1-clock-fork-reads-idle L-NEVER-OK: the same fault in felix status --tsv makes the lane row lane unknown - with a reason, the last of ten; never the value idle, where without the fault it reads value zero 0 of 2" \
   "$LNSRA|unfaulted $LNSb|$LF_FIRE|$(_lns_r2row "$LNSD/r2f1-s" unknown)" "built|unfaulted one of them|fired|one of them"

# R2-F4: a lanes.tsv the shape check refuses (a comment line that is not UTF-8), with the fork failing in the check's one
# awk pass (the words hold u8=, felix_table_check on the stack). Without the fault every surface reads R4.
LNSF4B=$'# a comment \377 that is not UTF-8\ncap\t^engine/\t1/2\t14\n'; LNSF4A="not built: R2-F4's home"
if [ "$LNSRA" = built ] && _lf_home "$LNSD/r2f4" p $((LNSRN - 40 * LNSDAY)); then
  LNSF4H="$LF_HOME"; LNSF4P="$LF_PROJ"
  _lf_table "$LNSF4P" $((LNSRN - 29 * LNSDAY)) lanes.tsv "$LNSF4B" && _lf_table "$LNSF4P" $((LNSRN - 29 * LNSDAY + 60)) lane-next.tsv $'cap\tnext item\n' \
    && printf '%s' "$LNSF4B" > "$LNSD/r2f4.want" \
    && ( _fx_cd "$LNSF4H" || exit 1; _lf_g 1700000000 cat-file blob HEAD:projects/p/lanes.tsv ) > "$LNSD/r2f4.got" 2>/dev/null \
    && cmp -s "$LNSD/r2f4.want" "$LNSD/r2f4.got" && LNSF4A=built
fi
_lf_use "${LNSF4H:-$LNSD/r2f4}" "$LNSD/memory" "$LNSD/user" "$LNSB"
LNSF4R4="$(_lns_u - - - - - - - "$LNSRREF" "${LNSF4P:-}/lanes.tsv cannot be read as lanes.tsv")"
LNSF4R9="$(_lns_u - - - - - - - "$LNSRREF" "${LNSF4P:-}/lanes.tsv cannot be read as committed in the Felix home")"
_lf_run "$LNSD/r2f4-0" "$LNSRC" "$LNSRN" "$FELIX" lane --tsv; LNSb="$LF_RC|$(cat "$LNSD/r2f4-0.out")"
_lf_fork fork awk '*u8=*' "*' felix_table_check '*" "$LNSD/r2f4-t.fired" "$LNSRT" _lf_run "$LNSD/r2f4-t" "$LNSRC" "$LNSRN" "$FELIX" lane --tsv
case "$LF_RC|$(cat "$LNSD/r2f4-t.out")" in
  ("0|$LNSF4R4"|"0|$LNSF4R9") LNSa="R4, R9 or ended" ;;
  (*) [ "$(_lf_ended "$LNSD/r2f4-t" "$LNSRC")" = ended ] && LNSa="R4, R9 or ended" || LNSa="status $LF_RC, stdout [$(cat "$LNSD/r2f4-t.out")]" ;;
esac
is "lane states R2-F4-shape-check-accepts-what-it-never-read L-RF3 L-NEVER-OK: a committed lanes.tsv the shape check refuses (a comment line that is not UTF-8), with a fork failing in the check's awk pass: felix lane --tsv prints the - line with R4, or R9, or ends as C3's count that did not finish; never a count of the row the check never accepted, where without the fault it reads R4" \
   "$LNSF4A|unfaulted $LNSb|$LF_FIRE|$LNSa" "built|unfaulted 0|$LNSF4R4|fired|R4, R9 or ended"
_lf_run "$LNSD/r2f4-s0" "$LNSRC" "$LNSRN" "$FELIX" status --tsv; LNSb="$(_lns_r2row "$LNSD/r2f4-s0" "$(_lf_tsv lane unknown - "${LNSF4P:-}/lanes.tsv cannot be read as lanes.tsv")")"
_lf_fork fork awk '*u8=*' "*' felix_table_check '*" "$LNSD/r2f4-s.fired" "$LNSRT" _lf_run "$LNSD/r2f4-s" "$LNSRC" "$LNSRN" "$FELIX" status --tsv
is "lane states R2-F4-shape-check-accepts-what-it-never-read L-RF3 L-NEVER-OK: the same fault in felix status --tsv makes the lane row lane unknown - with R4, R9 or the lane count did not finish, the last of ten; never the value zero" \
   "$LNSF4A|unfaulted $LNSb|$LF_FIRE|$(_lns_r2row "$LNSD/r2f4-s" "$(_lf_tsv lane unknown - "${LNSF4P:-}/lanes.tsv cannot be read as lanes.tsv")" \
     "$(_lf_tsv lane unknown - "${LNSF4P:-}/lanes.tsv cannot be read as committed in the Felix home")" "$(_lf_tsv lane unknown - "$LNSREND")")" \
   "built|unfaulted one of them|fired|one of them"

# R2-F9: a valid table, with the fork failing in the shape check's schema lookup (the awk program holds ENVIRON["T"],
# felix_table_schema on the stack). The table is not malformed, so the reading is the count (every next may read
# unknown, as for a lane-next.tsv the check could not read), R9, or C3's count that did not finish; never R4.
_lf_use "$LNSRH" "$LNSD/memory" "$LNSD/user" "$LNSB"
LNSF9R9="$(_lns_u - - - - - - - "$LNSRREF" "$LNSRR9")"
_lf_run "$LNSD/r2f9-0" "$LNSRC" "$LNSRN" "$FELIX" lane --tsv; LNSb="$LF_RC|$(cat "$LNSD/r2f9-0.out")"
_lf_fork fork awk "*'ENVIRON[\"T\"]'*" "*' felix_table_schema '*" "$LNSD/r2f9-t.fired" "$LNSRT" _lf_run "$LNSD/r2f9-t" "$LNSRC" "$LNSRN" "$FELIX" lane --tsv
case "$LF_RC|$(cat "$LNSD/r2f9-t.out")" in
  ("0|$LNSRL"|"0|$LNSRLU"|"0|$LNSF9R9") LNSa="the count, R9 or ended" ;;
  (*) [ "$(_lf_ended "$LNSD/r2f9-t" "$LNSRC")" = ended ] && LNSa="the count, R9 or ended" || LNSa="status $LF_RC, stdout [$(cat "$LNSD/r2f9-t.out")]" ;;
esac
is "lane states R2-F9-fork-in-shape-check-reads-R4 L-NEVER-OK: a valid committed lanes.tsv, with a fork failing in the shape check's schema lookup: felix lane --tsv prints the count, or the - line with R9, or ends as C3's count that did not finish; never R4, which says the committed table is malformed" \
   "$LNSRA|unfaulted $LNSb|$LF_FIRE|$LNSa" "built|unfaulted 0|$LNSRL|fired|the count, R9 or ended"
_lf_run "$LNSD/r2f9-s0" "$LNSRC" "$LNSRN" "$FELIX" status --tsv; LNSb="$(_lns_r2row "$LNSD/r2f9-s0" "$LNSRV")"
_lf_fork fork awk "*'ENVIRON[\"T\"]'*" "*' felix_table_schema '*" "$LNSD/r2f9-s.fired" "$LNSRT" _lf_run "$LNSD/r2f9-s" "$LNSRC" "$LNSRN" "$FELIX" status --tsv
is "lane states R2-F9-fork-in-shape-check-reads-R4 L-NEVER-OK: the same fault in felix status --tsv makes the lane row the value zero 0 of 2, or lane unknown - with R9 or the lane count did not finish, the last of ten; never R4" \
   "$LNSRA|unfaulted $LNSb|$LF_FIRE|$(_lns_r2row "$LNSD/r2f9-s" "$LNSRV" "$(_lf_tsv lane unknown - "$LNSRR9")" "$(_lf_tsv lane unknown - "$LNSREND")")" \
   "built|unfaulted one of them|fired|one of them"

# ---- the second review's round 2: the count's scratch directory taken mid-count (R2B-F2) ------------------------------
# Added on 2026-10-30 from the second review's round 2 findings (their inputs and observed output only), still blind. A
# self-governed home of its own (C9): project g, lanes.tsv cap (^engine/, 1/2, 14) committed 29 days before the clock,
# no lane-next.tsv, then a marked and an unmarked engine landing five days back, an hour apart: cap reads ok, L 1 of T 2.
# The fault is the review's (_lf_gone): an exported awk that, at the awk call the finding names by its words and calling
# function, removes the count's scratch directory (C2: TMPDIR/felix-lane.*), as a cleaner of TMPDIR or a full disk
# would, then runs the real awk. Case A: the read of lanes.tsv's rows (skip= in its words, felix_table_rows on the
# stack); case B: the tally of the window (t[$2]++, _lane_window). Readings: a read the count depends on that did not
# finish never yields a count, none, idle or a table with no row (C3, C9). Accepted: C3's count that did not finish
# (felix lane: nothing on stdout, C3's line on stderr, exit 1 as C3 says; the finding's exit 2 is not the Contract's),
# or the reason C3 gives the read: R9 for case A (a read of lanes.tsv, the - line), R2 for case B (a read of the
# landings); beside them column 12 may read -, and in case B columns 10 and 11 unknown and -. Each assertion also
# compares the command without the fault, so it is red on main.
LNSGN=1793000000; LNSGT="$LNSD/r2b-tmp"; LNSGA="not built: R2B-F2's home"; LNSGH="$LNSD/r2b"; LNSGP=""; LNSGS=""
if _lf_self "$LNSD/r2b" g $((LNSGN - 30 * LNSDAY)); then
  LNSGH="$LF_HOME"; LNSGP="$LF_PROJ"
  _lf_table "$LNSGP" $((LNSGN - 29 * LNSDAY)) lanes.tsv $'cap\t^engine/\t1/2\t14\n' && LNSGS="$LF_SHA" \
    && _lf_chain "$LNSGH" cap $((LNSGN - 5 * LNSDAY)) 3600 m u \
    && [ "$(_lf_spine "$LNSGH")" = "$((LNSGN - 5 * LNSDAY + 3600)):1 $((LNSGN - 5 * LNSDAY)):1 $((LNSGN - 29 * LNSDAY)):1 $((LNSGN - 30 * LNSDAY)):0" ] \
    && ! ( _fx_cd "$LNSGH" && _lf_g 1700000000 cat-file -e HEAD:projects/g/lane-next.tsv ) >/dev/null 2>&1 && LNSGA=built
fi
_lf_use "$LNSGH" "$LNSD/r2b-memory" "$LNSD/r2b-user" "$LNSB"
LNSGREF="$(_lf_iso $((LNSGN - 5 * LNSDAY + 3600)))"; LNSGTI="$(_lf_iso $((LNSGN - 29 * LNSDAY)))"
LNSGL="$(_lf_tsv cap ok 1 2 14 1/2 "$(_lf_iso $((LNSGN - 5 * LNSDAY)))" 'Felix-Lane: cap' none "$LNSGS" "$LNSGTI" "$LNSGREF" -)"
LNSGHU="cap: ok, 1 of 2 engine landings in 14 days, target 1/2; last lane landing $(_lf_iso $((LNSGN - 5 * LNSDAY))); mark Felix-Lane: cap; next: none; its lanes.tsv row last changed by $(printf '%.12s' "$LNSGS") at $LNSGTI; refs/remotes/origin/main at $LNSGREF"
LNSGR9="$LNSGP/lanes.tsv cannot be read as committed in the Felix home"; LNSGR2="git could not read the landings on refs/remotes/origin/main in $LNSGH"
_lf_run "$LNSD/r2bf2-t0" "$LNSGH" "$LNSGN" "$FELIX" lane --tsv; LNSb="$LF_RC|$(cat "$LNSD/r2bf2-t0.out")"
_lf_run "$LNSD/r2bf2-h0" "$LNSGH" "$LNSGN" "$FELIX" lane; LNSb="$LNSb|$LF_RC|$(cat "$LNSD/r2bf2-h0.out")"
_lf_run "$LNSD/r2bf2-s0" "$LNSGH" "$LNSGN" "$FELIX" status --tsv
LNSc="$(_lns_r2row "$LNSD/r2bf2-s0" "$(_lf_tsv lane value ok '1 of 2 engine landings in 14 days, target 1/2')")"
# OUT FORM CASE -> "unknown or ended" when the faulted felix lane run whose files are OUT.* ended as the readings above
# accept for CASE (A or B) in FORM (tsv or human), else its status, stdout and stderr.
_lns_gone() {
  local o="$1" c12
  if [ "$(_lf_ended "$o" "$LNSGH")" = ended ]; then printf 'unknown or ended'; return 0; fi
  if [ "$LF_RC" = 0 ] && [ "$(_lf_count "$o.out")" = 1 ]; then
    c12="$(_lf_cols "$o.out" 1 12)"
    case "$2$3|$c12|$(_lf_cols "$o.out" 1 1 2 3 4 5 6 7 8 9 10 11 13)" in
      ("tsvA|$LNSGREF|-|unknown|-|-|-|-|-|-|-|-|-|$LNSGR9"|"tsvA|-|-|unknown|-|-|-|-|-|-|-|-|-|$LNSGR9") printf 'unknown or ended'; return 0 ;;
      ("tsvB|$LNSGREF|cap|unknown|-|-|14|1/2|-|Felix-Lane: cap|none|$LNSGS|$LNSGTI|$LNSGR2"|"tsvB|-|cap|unknown|-|-|14|1/2|-|Felix-Lane: cap|none|$LNSGS|$LNSGTI|$LNSGR2") printf 'unknown or ended'; return 0 ;;
      ("tsvB|$LNSGREF|cap|unknown|-|-|14|1/2|-|Felix-Lane: cap|none|unknown|-|$LNSGR2"|"tsvB|-|cap|unknown|-|-|14|1/2|-|Felix-Lane: cap|none|unknown|-|$LNSGR2") printf 'unknown or ended'; return 0 ;;
    esac
    case "$2$3|$(cat "$o.out")" in
      ("humanA|-: unknown, $LNSGR9; refs/remotes/origin/main at $LNSGREF"|"humanA|-: unknown, $LNSGR9; refs/remotes/origin/main at -"|"humanB|cap: unknown, $LNSGR2; "*) printf 'unknown or ended'; return 0 ;;
    esac
  fi
  printf 'status %s, stdout [%s], stderr [%s]' "$LF_RC" "$(cat "$o.out")" "$(cat "$o.err")"
}
# CASE WORDS STACK -> the felix lane --tsv, felix lane and felix status --tsv runs under the fault, each with a fresh
# TMPDIR; LNSa their readings, LNSGF the fault's firing in each, joined by +.
_lns_gonerun() {
  local m
  LNSa=""; LNSGF=""
  for m in tsv human status; do
    rm -rf "$LNSGT"; mkdir -p "$LNSGT"
    case "$m" in
      (tsv) _lf_gone "$2" "$3" "$LNSD/r2bf2-$1t.fired" "$LNSGT" _lf_run "$LNSD/r2bf2-$1t" "$LNSGH" "$LNSGN" "$FELIX" lane --tsv
            LNSa="$(_lns_gone "$LNSD/r2bf2-$1t" tsv "$1")" ;;
      (human) _lf_gone "$2" "$3" "$LNSD/r2bf2-$1h.fired" "$LNSGT" _lf_run "$LNSD/r2bf2-$1h" "$LNSGH" "$LNSGN" "$FELIX" lane
            LNSa="$LNSa|$(_lns_gone "$LNSD/r2bf2-$1h" human "$1")" ;;
      (status) _lf_gone "$2" "$3" "$LNSD/r2bf2-$1s.fired" "$LNSGT" _lf_run "$LNSD/r2bf2-$1s" "$LNSGH" "$LNSGN" "$FELIX" status --tsv
            if [ "$1" = A ]; then LNSa="$LNSa|$(_lns_r2row "$LNSD/r2bf2-$1s" "$(_lf_tsv lane unknown - "the lane count did not finish in $LNSGH")" "$(_lf_tsv lane unknown - "$LNSGR9")")"
            else LNSa="$LNSa|$(_lns_r2row "$LNSD/r2bf2-$1s" "$(_lf_tsv lane unknown - "the lane count did not finish in $LNSGH")" "$(_lf_tsv lane unknown - "$LNSGR2")")"; fi ;;
    esac
    LNSGF="$LNSGF${LNSGF:++}$LF_FIRE"
  done
}
_lns_gonerun A '*skip=*' "*' felix_table_rows '*"
is "lane states R2B-F2-scratch-gone-reads-none-or-idle L-NEVER-OK: (A) the count's scratch directory removed at the read of lanes.tsv's rows (skip=, felix_table_rows), where without it cap reads ok 1 of 2: felix lane --tsv and felix lane end as C3's count that did not finish, or print the - line with R9; never nothing with exit 0" \
   "$LNSGA|unfaulted $LNSb|$LNSGF|${LNSa%|*}" "built|unfaulted 0|$LNSGL|0|$LNSGHU|fired+fired+fired|unknown or ended|unknown or ended"
is "lane states R2B-F2-scratch-gone-reads-none-or-idle L-NEVER-OK: (A) the same in felix status --tsv: the lane row is lane unknown - the lane count did not finish in <repo>, or lane unknown - with R9, the last of ten; never the none row of a table with no row" \
   "$LNSGA|unfaulted $LNSc|${LNSGF##*+}|${LNSa##*|}" "built|unfaulted one of them|fired|one of them"
_lns_gonerun B "*'t[\$2]++'*" "*' _lane_window '*"
is "lane states R2B-F2-scratch-gone-reads-none-or-idle L-NEVER-OK: (B) the count's scratch directory removed at the tally of the window (t[\$2]++, _lane_window): felix lane --tsv and felix lane end as C3's count that did not finish, or print cap unknown with R2; never idle 0 of 0" \
   "$LNSGA|unfaulted $LNSb|$LNSGF|${LNSa%|*}" "built|unfaulted 0|$LNSGL|0|$LNSGHU|fired+fired+fired|unknown or ended|unknown or ended"
is "lane states R2B-F2-scratch-gone-reads-none-or-idle L-NEVER-OK: (B) the same in felix status --tsv: the lane row is lane unknown - the lane count did not finish in <repo>, or lane unknown - with R2, the last of ten; never the value idle 0 of 0" \
   "$LNSGA|unfaulted $LNSc|${LNSGF##*+}|${LNSa##*|}" "built|unfaulted one of them|fired|one of them"
_lf_use "$LNSH" "$LNSD/memory" "$LNSD/user" "$LNSB"

# ---- the second review's round 3: an open-file limit that drops the marks (R3-F1) -----------------------------------
# Added on 2026-10-30 from the second review's round 3 findings (their inputs and observed output only), still blind.
# The review's fixture (_lf_r3): its home-apart layout with lanes.tsv holding sec (^docs/ 1/2 7) before cap (^engine/
# 1/2 14), the checkout bound by .felix and p's own, its landings dated from the machine clock at build time and
# FELIX_LANE_NOW unset, as the finding ran: felix lane --tsv prints sec short 1 3 and cap zero 0 2, and the status row is
# the value short 1 of 3. The fault is the finding's: a soft open-file limit N (ulimit -S -n N) set in the shell that
# execs felix, for each N from 10 to 24, that shell first closing the descriptors from 3 up it inherited, so that the N
# at which a read gives out does not hang on what the suite holds open (_lf_nfprog); TMPDIR a directory of the
# fixture's own; no other fault. Readings (C3, C4, C5, C6): a read that did not finish never yields a count. So at
# every N, felix lane --tsv exits 0 with its unfaulted lines, or with lines that differ from them only where C5 lets a
# column read unknown (7, 9, and 10 with 11 -), or with lines unknown with L, T and column 7 - and a reason, or the -
# line; or it exits other than 0 with no more on stdout than a start of its unfaulted lines (C3: nothing). Never exit 0
# with another count, column 7 none for a lane landing that exists, or nothing. The status row is the unfaulted value
# row or lane unknown - with a reason, last, whenever a lane row is printed; a run that ends before its lane row exits
# other than 0; a run that printed no row at all said nothing of the lane (at the lowest limits felix cannot load its
# libraries). Each assertion also compares the run without the limit, so it is red on main.
LNSN3="$(date +%s)"; LNSN3T="$LNSD/r3-tmp"; LNSN3A="not built: R3-F1's fixture"; LNSN3C="$LNSD/r3/c"; LNSN3L=""
if _lf_r3 "$LNSD/r3" p "$LNSN3"; then LNSN3A=built; LNSN3C="$LF_REPO"; LNSN3L="$LF_R3"; fi
LNSN3V="$(_lf_tsv lane value short '1 of 3 engine landings in 7 days, target 1/2')"
_lf_use "$LNSD/r3/home" "$LNSD/r3-memory" "$LNSD/r3-user" "$LNSB"
printf '%s\n' "$LNSN3L" > "$LNSD/r3.want"
_lf_run "$LNSD/r3-t0" "$LNSN3C" - "$FELIX" lane --tsv; LNSb="$LF_RC|$(cat "$LNSD/r3-t0.out")"
_lf_run "$LNSD/r3-s0" "$LNSN3C" - "$FELIX" status --tsv; LNSc="$(_lns_r2row "$LNSD/r3-s0" "$LNSN3V")"
# OUT -> "unfaulted or unknown" when the felix lane --tsv run whose files are OUT.* ended as the readings above accept,
# else its status and stdout.
_lns_r3t() {
  local o="$1" s
  if [ "$LF_RC" != 0 ]; then
    s="$(wc -c < "$o.out" | tr -d ' ')"
    if [ "$(head -c "$s" "$LNSD/r3.want"; printf x)" = "$(cat "$o.out"; printf x)" ]; then printf 'unfaulted or unknown'; return 0; fi
  elif [ "$(LC_ALL=C awk -F'\t' 'NR == FNR { w[FNR] = $0; next }
      { m = FNR; k = split(w[FNR], e, "\t"); a = (NF == 13 && k == 13 && $1 == e[1])
        kn = ($2 == e[2] && $3 == e[3] && $4 == e[4] && $5 == e[5] && $6 == e[6] && ($7 == e[7] || $7 == "unknown") && $8 == e[8] &&
          ($9 == e[9] || $9 == "unknown") && (($10 == e[10] && $11 == e[11]) || ($10 == "unknown" && $11 == "-")) && $12 == e[12] && $13 == "-")
        un = ($2 == "unknown" && $3 == "-" && $4 == "-" && $7 == "-" && $13 != "" && $13 != "-")
        if (a && (kn || un)) n++
        if (NF == 13 && $1 == "-" && $2 == "unknown" && $3 == "-" && $4 == "-" && $7 == "-" && $13 != "" && $13 != "-") d++ }
      END { print (((m == 2 && n == 2) || (m == 1 && d == 1)) ? "yes" : "no") }' "$LNSD/r3.want" "$o.out")" = yes ]; then
    printf 'unfaulted or unknown'; return 0
  fi
  printf 'status %s, stdout [%s]' "$LF_RC" "$(cat "$o.out")"
}
# OUT -> "the row or unknown" when the felix status --tsv run whose files are OUT.* ended as the readings above accept,
# else its status, its number of rows and of lane rows, and its last row.
_lns_r3s() {
  local o="$1" n l u
  n="$(LC_ALL=C awk -F'\t' '$1 == "lane" { n++ } END { print n + 0 }' "$o.out")"; l="$(_lf_last "$o.out")"
  u="$(printf '%s\n' "$l" | LC_ALL=C awk -F'\t' '{ print ((NF == 4 && $1 == "lane" && $2 == "unknown" && $3 == "-" && $4 != "" && $4 != "-") ? "unknown" : "other") }')"
  if [ ! -s "$o.out" ] || { [ "$n" = 0 ] && [ "$LF_RC" != 0 ]; } || { [ "$n" = 1 ] && { [ "$l" = "$LNSN3V" ] || [ "$u" = unknown ]; }; }; then
    printf 'the row or unknown'; return 0
  fi
  printf 'status %s, %s rows, %s lane rows, last [%s]' "$LF_RC" "$(_lf_count "$o.out")" "$n" "$l"
}
LNSa=""; LNSc3=""; LNSl=""
for LNSn in 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24; do
  rm -rf "$LNSN3T"; mkdir -p "$LNSN3T"
  _lf_run "$LNSD/r3-t$LNSn" "$LNSN3C" - TMPDIR="$LNSN3T" /bin/bash -c "$(_lf_nfprog)" "$LNSn" "$FELIX" lane --tsv
  [ "$(LC_ALL=C awk 'NR == 1' "$LNSD/r3-t$LNSn.err")" = "limit $LNSn" ] || LNSl="$LNSl t$LNSn"
  LNSx="$(_lns_r3t "$LNSD/r3-t$LNSn")"; [ "$LNSx" = 'unfaulted or unknown' ] || LNSa="$LNSa [N=$LNSn: $LNSx]"
  rm -rf "$LNSN3T"; mkdir -p "$LNSN3T"
  _lf_run "$LNSD/r3-s$LNSn" "$LNSN3C" - TMPDIR="$LNSN3T" /bin/bash -c "$(_lf_nfprog)" "$LNSn" "$FELIX" status --tsv
  [ "$(LC_ALL=C awk 'NR == 1' "$LNSD/r3-s$LNSn.err")" = "limit $LNSn" ] || LNSl="$LNSl s$LNSn"
  LNSx="$(_lns_r3s "$LNSD/r3-s$LNSn")"; [ "$LNSx" = 'the row or unknown' ] || LNSc3="$LNSc3 [N=$LNSn: $LNSx]"
done
if [ -z "$LNSl" ]; then LNSl="the limit set at every N"; else LNSl="the limit not set at$LNSl"; fi
is "lane states R3-F1-open-file-limit-drops-marks L-NEVER-OK: with FELIX_LANE_NOW unset and a soft open-file limit N from 10 to 24 set in the shell that execs felix, felix lane --tsv prints at every N its unfaulted lines sec short 1 3 and cap zero 0 2, or unknown forms of C5, or exits other than 0 with no more than a start of them; never sec zero 0 3, column 7 none for a lane landing that exists, or nothing with exit 0" \
   "$LNSN3A|unfaulted $LNSb|$LNSl|${LNSa:- unfaulted or unknown at every N}" "built|unfaulted 0|$LNSN3L|the limit set at every N| unfaulted or unknown at every N"
is "lane states R3-F1-open-file-limit-drops-marks L-NEVER-OK: the same limits in felix status --tsv: whenever a lane row is printed it is the last, the value short 1 of 3 engine landings in 7 days, target 1/2, or lane unknown - with a reason; never the value zero 0 of 3, and never exit 0 after rows with no lane row" \
   "$LNSN3A|unfaulted $LNSc|$LNSl|${LNSc3:- the row or unknown at every N}" "built|unfaulted one of them|the limit set at every N| the row or unknown at every N"
_lf_use "$LNSH" "$LNSD/memory" "$LNSD/user" "$LNSB"
# <<< lane-states
