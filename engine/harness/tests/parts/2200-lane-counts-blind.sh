# >>> lane-counts
printf '\nlane counts: which landings on origin/main count, and which are the lane'"'"'s (slice 0, design 6.2 and 6.6, C3, L-RF1, L-RF5; blind)\n'
# Blind, written on 2026-10-29 from docs/2026-10-29-capability-lane-first-slices-design.md and the slice 0 plan's
# Contracts (C1-C13) alone, before lib/lane.sh existed, without reading lib/, hooks/, bin/ or felix. Felix is run as a
# black box; the builders are tests/lib/lane-fixture.sh's. C11's row for this part: section 6.2 and 6.6 "The counts",
# with C11's worked expectation exact at the clock and a second before it; L-RF1; a real merge read through its merged
# commits; a merge whose marked commits change no counted path; a rename out of a counted path; L-RF5.
#
# The home apart (C9): H holds project lx, with lanes.tsv (capability, ^engine/, 1/2, 14) and lane-next.tsv committed,
# and each checkout is bound to lx by an untracked .felix. L and T are columns 3 and 4 of felix lane --tsv. Every
# assertion that reads an output first checks that its fixture was built as named (the chain, the dates, the marks),
# and says "built" when it was. Readings where the Contracts leave room:
# - (g)'s branch forks from the root and carries its mark only on a merge of main into it, so the felix merge squash
#   copies its one non-merge commit and no mark (C3).
# - "A merge whose marked commits change no counted path" is read both ways C3 allows: a merge that brings in only a
#   marked docs commit is not counted (idle), and one that brings in a marked docs commit beside an unmarked engine
#   commit is counted by what it changed against its first parent and marked by the commit it brought in (L 1).
# - A mark that is the subject line of a commit landed directly is a message line, so it marks (C3); the same commit
#   squashed by felix merge lands as "* Felix-Lane: capability", which does not.
# - The session-start halves of L-RF5 are controls (C10).
LNCN=1793000000; LNCDAY=86400; LNCT0=$((LNCN - 7 * LNCDAY)); LNCNEXT='count the lane, then the next slice'
_lf_dir "$TMP/lane-2200"; LNCD="$LF_DIR"
_lf_stubs "$LNCD"; LNCB="$LF_BIN"
_lf_home "$LNCD/home" lx 1792900000; LNCH="$LF_HOME"; LNCP="$LF_PROJ"
_lf_table "$LNCP" 1792900100 lanes.tsv $'# The lanes this fixture counts.\ncapability\t^engine/\t1/2\t14\n'; LNCTAB="$LF_SHA"
_lf_table "$LNCP" 1792900200 lane-next.tsv "$(_lf_tsv capability "$LNCNEXT")"$'\n'
_lf_use "$LNCH" "$LNCD/memory" "$LNCD/user" "$LNCB"
LNCF=""   # the first build step that failed, by its words
_lnc_do() { "$@" || [ -n "$LNCF" ] || LNCF="$*"; }
_lnc_py() { command -v python3 >/dev/null 2>&1; }

# ---- C11's worked expectation: (a) to (k) on one first-parent chain ------------------------------------------------
_lf_checkout "$LNCD/worked" lx $((LNCN - 30 * LNCDAY)); LNCW="$LF_REPO"
_lnc_do _lf_branch "$LNCW" lg main
_lnc_do _lf_commit "$LNCW" $((LNCT0 - 7200)) $'engine: g, the change\n\nNo mark here.\n' engine/g.sh
_lnc_do _lf_switch "$LNCW" main
_lnc_do _lf_branch "$LNCW" la main   # (a) felix merge squash, the mark a body line of a branch commit
_lnc_do _lf_commit "$LNCW" $((LNCT0 - 3600)) $'engine: the a change\n\nWhat it changes.\nFelix-Lane: capability\n' engine/a.sh
_lnc_do _lf_switch "$LNCW" main
_lnc_do _lf_squash "$LNCW" $((LNCT0 + 1)) felix la 'engine: a (#1)'
_lnc_do _lf_branch "$LNCW" lb main   # (b) GitHub's default squash, the same
_lnc_do _lf_commit "$LNCW" $((LNCT0 - 3500)) $'engine: the b change\n\nFelix-Lane: capability\n' engine/b.sh
_lnc_do _lf_commit "$LNCW" $((LNCT0 - 3400)) $'docs: a note on b\n' docs/b.md
_lnc_do _lf_switch "$LNCW" main
_lnc_do _lf_squash "$LNCW" $((LNCT0 + 2)) github lb 'engine: b (#2)'
_lnc_do _lf_commit "$LNCW" $((LNCT0 + 3)) $'docs: c\n\nFelix-Lane: capability\n' docs/c.md   # (c) marked, docs only
_lnc_do _lf_commit "$LNCW" $((LNCT0 + 4)) $'engine: d\n\nNo mark.\n' engine/d.sh               # (d) unmarked engine
_lnc_do _lf_commit "$LNCW" $((LNCT0 + 5)) $'docs: e\n' docs/e.md                                 # (e) unmarked docs
_lnc_do _lf_branch "$LNCW" lf main   # (f) a real merge whose merged commit carries the mark and changes engine/
_lnc_do _lf_commit "$LNCW" $((LNCT0 - 3300)) $'engine: the f change\n\nFelix-Lane: capability\n' engine/f.sh
_lnc_do _lf_switch "$LNCW" main
_lnc_do _lf_merge "$LNCW" $((LNCT0 + 6)) lf $'Merge branch lf\n'
_lnc_do _lf_switch "$LNCW" lg        # (g) the mark only on a merge commit of the branch
_lnc_do _lf_merge "$LNCW" $((LNCT0 + 6)) main $'Merge main into lg\n\nFelix-Lane: capability\n'
_lnc_do _lf_switch "$LNCW" main
_lnc_do _lf_squash "$LNCW" $((LNCT0 + 7)) felix lg 'engine: g (#7)'; LNCgm="$LF_MSG"
_lnc_do _lf_commit "$LNCW" $((LNCT0 + 8)) $'engine: h\n\nThis is no lane landing, though this sentence names Felix-Lane: capability.\n' engine/h.sh
_lnc_do _lf_commit "$LNCW" $((LNCN - 14 * LNCDAY)) $'engine: i\n\nFelix-Lane: capability\n' engine/i.sh       # (i) exactly 14 days back
_lnc_do _lf_commit "$LNCW" $((LNCN - 14 * LNCDAY + 1)) $'engine: j\n\nFelix-Lane: capability\n' engine/j.sh   # (j) a second later
_lnc_do _lf_commit "$LNCW" "$LNCN" $'engine: k\n\nFelix-Lane: capability\n' engine/k.sh                     # (k) at the clock
_lnc_do _lf_publish "$LNCW"
LNCSPINE="$LNCN:1 $((LNCN - 14 * LNCDAY + 1)):1 $((LNCN - 14 * LNCDAY)):1 $((LNCT0 + 8)):1 $((LNCT0 + 7)):1 $((LNCT0 + 6)):2"
LNCSPINE="$LNCSPINE $((LNCT0 + 5)):1 $((LNCT0 + 4)):1 $((LNCT0 + 3)):1 $((LNCT0 + 2)):1 $((LNCT0 + 1)):1 $((LNCN - 30 * LNCDAY)):0"
# The marks of (a), (b), (g) and (h), found by their places on the chain: origin/main~10, ~9, ~4 and ~3.
LNCa="$(_lf_spine "$LNCW")"
if [ -z "$LNCF" ] && [ "$LNCa" = "$LNCSPINE" ]; then
  LNCBUILT="$(_lf_marks "$LNCW" "refs/remotes/origin/main~10" capability)$(_lf_marks "$LNCW" "refs/remotes/origin/main~9" capability)"
  LNCBUILT="$LNCBUILT$(_lf_marks "$LNCW" "refs/remotes/origin/main~4" capability)$(_lf_marks "$LNCW" "refs/remotes/origin/main~3" capability)"
  case "$LNCBUILT|$LNCgm" in
    "1100|"*"* engine: g, the change"*) LNCBUILT=built ;;
    *) LNCBUILT="not built: the marks of (a), (b), (g), (h) read [$LNCBUILT], or (g)'s message lacks its entry" ;;
  esac
else
  LNCBUILT="not built: ${LNCF:-the first-parent chain reads [$LNCa], not [$LNCSPINE]}"
fi
_lf_run "$LNCD/w0" "$LNCW" "$LNCN" "$FELIX" lane --tsv
is "lane counts: at the pinned clock, landings (a) to (k) give L 5 (a, b, f, j, k) and T 8 (a, b, d, f, g, h, j, k), state ok, and the last lane landing is (k)'s date" \
   "$LNCBUILT|$LF_RC|$(_lf_count "$LNCD/w0.out")|$(_lf_cols "$LNCD/w0.out" 1 1 2 3 4 7)" \
   "built|0|1|capability|ok|5|8|$(_lf_iso "$LNCN")"
_lf_run "$LNCD/w1" "$LNCW" $((LNCN - 1)) "$FELIX" lane --tsv
is "lane counts: a second before the clock, (k) is after now and (i) is inside: L 5 (a, b, f, i, j), T 8 (a, b, d, f, g, h, i, j), and the last lane landing is (f)'s date" \
   "$LNCBUILT|$LF_RC|$(_lf_count "$LNCD/w1.out")|$(_lf_cols "$LNCD/w1.out" 1 1 2 3 4 7)" \
   "built|0|1|capability|ok|5|8|$(_lf_iso $((LNCT0 + 6)))"
_lf_run "$LNCD/w2" "$LNCW" $((LNCN + 1)) "$FELIX" lane --tsv
is "lane counts: a second after the clock, (j) sits exactly 14 days back and is out: L 4 (a, b, f, k), T 7 (a, b, d, f, g, h, k), the last lane landing (k)'s date" \
   "$LNCBUILT|$LF_RC|$(_lf_count "$LNCD/w2.out")|$(_lf_cols "$LNCD/w2.out" 1 1 2 3 4 7)" \
   "built|0|1|capability|ok|4|7|$(_lf_iso "$LNCN")"

# ---- one landing a checkout, a day before the clock ------------------------------------------------------------------
# NAME MESSAGE [SPEC...] -> $LNCD/NAME: the root, then one landing with MESSAGE changing SPEC (engine/x.sh), published.
# LNCR the checkout, LNCS the landing (empty when it was not built as named).
_lnc_one() {
  local n="$1" m="$2"
  shift 2
  LNCS=""; LNCR=""
  _lf_checkout "$LNCD/$n" lx $((LNCN - 30 * LNCDAY)) || return 1
  LNCR="$LF_REPO"
  if [ "$#" -eq 0 ]; then _lf_commit "$LNCR" $((LNCN - LNCDAY)) "$m" engine/x.sh || return 1
  else _lf_commit "$LNCR" $((LNCN - LNCDAY)) "$m" "$@" || return 1; fi
  _lf_publish "$LNCR" && LNCS="$LF_SHA"
}
# NAME -> "built" when $LNCS was made, then |status|lines|columns 2, 3 and 4 of felix lane --tsv in $LNCR at the clock.
_lnc_read() {
  _lf_run "$LNCD/$1-run" "$LNCR" "$LNCN" "$FELIX" lane --tsv
  printf '%s|%s|%s|%s' "${LNCS:+built}" "$LF_RC" "$(_lf_count "$LNCD/$1-run.out")" "$(_lf_cols "$LNCD/$1-run.out" 1 2 3 4)"
}

# ---- L-RF1: the mark as people write it --------------------------------------------------------------------------------
_lnc_one rf1-spaces $'engine: x\n\nFelix-Lane: capability   \n'
is "lane counts L-RF1: a mark line ending in three spaces counts in L: L 1 of T 1" "$(_lnc_read rf1-spaces)" "built|0|1|ok|1|1"
_lnc_one rf1-tab $'engine: x\n\nFelix-Lane: capability\t\n'
is "lane counts L-RF1: a mark line ending in a tab counts in L: L 1 of T 1" "$(_lnc_read rf1-tab)" "built|0|1|ok|1|1"
_lnc_one rf1-cr $'engine: x\n\nFelix-Lane: capability\r\n'
is "lane counts L-RF1: a mark line ending in a CR counts in L: L 1 of T 1" "$(_lnc_read rf1-cr)" "built|0|1|ok|1|1"
_lnc_one rf1-mixed $'engine: x\n\nFelix-Lane: capability \t \r\n'
is "lane counts L-RF1: a mark line ending in a space, a tab, a space and a CR counts in L: L 1 of T 1" "$(_lnc_read rf1-mixed)" "built|0|1|ok|1|1"
_lnc_one rf1-subject $'Felix-Lane: capability\n\nThe mark is this landing\'s own subject line.\n'
is "lane counts L-RF1: a mark that is the subject line of a landing committed straight to main is a message line, and counts in L: L 1 of T 1" \
   "$(_lnc_read rf1-subject)" "built|0|1|ok|1|1"
_lnc_one rf1-lead $'engine: x\n\n Felix-Lane: capability\n'
is "lane counts L-RF1: a mark line with a leading space does not count in L and the landing still counts in T: L 0 of T 1" "$(_lnc_read rf1-lead)" "built|0|1|zero|0|1"
_lnc_one rf1-leadtab $'engine: x\n\n\tFelix-Lane: capability\n'
is "lane counts L-RF1: a mark line with a leading tab does not count in L and the landing still counts in T: L 0 of T 1" "$(_lnc_read rf1-leadtab)" "built|0|1|zero|0|1"
_lnc_one rf1-case $'engine: x\n\nfelix-lane: capability\n'
is "lane counts L-RF1: felix-lane: capability in lower case does not count in L, and the landing still counts in T: L 0 of T 1" "$(_lnc_read rf1-case)" "built|0|1|zero|0|1"
_lnc_one rf1-nospace $'engine: x\n\nFelix-Lane:capability\n'
is "lane counts L-RF1: Felix-Lane:capability with no space after the colon does not count in L, and still counts in T: L 0 of T 1" "$(_lnc_read rf1-nospace)" "built|0|1|zero|0|1"
_lnc_one rf1-twospace $'engine: x\n\nFelix-Lane:  capability\n'
is "lane counts L-RF1: Felix-Lane: with two spaces before the lane does not count in L, and still counts in T: L 0 of T 1" "$(_lnc_read rf1-twospace)" "built|0|1|zero|0|1"
_lnc_one rf1-more $'engine: x\n\nFelix-Lane: capability lane\n'
is "lane counts L-RF1: a mark line with more text after the lane name does not count in L, and still counts in T: L 0 of T 1" "$(_lnc_read rf1-more)" "built|0|1|zero|0|1"
_lnc_one rf1-docs $'docs: x\n\nFelix-Lane: capability   \n' docs/x.md
is "lane counts L-RF1: a well-formed mark on a landing that changed no counted path counts in neither: L 0 of T 0, idle" "$(_lnc_read rf1-docs)" "built|0|1|idle|0|0"

# ---- the review's F5: a control byte on another line of the message never drops the mark (C3 Marked) -------------------
# Added on 2026-10-30 from the adversarial review of the first build, still blind. C3 asks only whether some line is the
# mark; what the other lines hold, a record separator (0x1E) among them, does not matter. The second message carries
# the other separators and two more control bytes on one line, so a mark kept for 0x1E alone is not enough.
# NAME -> "built" when $LNCS was made, then |status|lines|columns 2, 3, 4 and 7 of felix lane --tsv in $LNCR at the clock.
_lnc_read7() {
  _lf_run "$LNCD/$1-run" "$LNCR" "$LNCN" "$FELIX" lane --tsv
  printf '%s|%s|%s|%s' "${LNCS:+built}" "$LF_RC" "$(_lf_count "$LNCD/$1-run.out")" "$(_lf_cols "$LNCD/$1-run.out" 1 2 3 4 7)"
}
_lnc_one f5-rs $'rs\n\nsee \036 here\nFelix-Lane: capability\n'
is "lane counts F5-0x1e-in-a-message-drops-the-mark: a landing whose message holds the line see <0x1E> here above the whole line Felix-Lane: capability counts in L: ok, L 1 of T 1, the last lane landing its date" \
   "$(_lnc_read7 f5-rs)" "built|0|1|ok|1|1|$(_lf_iso $((LNCN - LNCDAY)))"
_lnc_one f5-ctl $'engine: x\n\nbytes \001 \034 \035 \036 \037 \177 on one line\nFelix-Lane: capability\n'
is "lane counts F5-0x1e-in-a-message-drops-the-mark: a line holding 0x01, 0x1C, 0x1D, 0x1E, 0x1F and DEL above the whole mark line drops nothing: ok, L 1 of T 1, the last lane landing its date" \
   "$(_lnc_read7 f5-ctl)" "built|0|1|ok|1|1|$(_lf_iso $((LNCN - LNCDAY)))"

# ---- squash messages, real merges, a rename ----------------------------------------------------------------------------
LNCF=""; LNCS=""
_lf_checkout "$LNCD/sq-subject" lx $((LNCN - 30 * LNCDAY)); LNCR="$LF_REPO"
_lnc_do _lf_branch "$LNCR" ls main
_lnc_do _lf_commit "$LNCR" $((LNCN - 2 * LNCDAY)) $'Felix-Lane: capability\n\nThe mark is this branch commit\'s subject.\n' engine/s.sh
_lnc_do _lf_switch "$LNCR" main
_lnc_do _lf_squash "$LNCR" $((LNCN - 3600)) felix ls 'engine: s (#9)'; LNCS="$LF_SHA"
_lnc_do _lf_publish "$LNCR"
case "$LF_MSG" in *$'\n* Felix-Lane: capability\n'*) ;; *) LNCF="${LNCF:-the squash message lacks the line * Felix-Lane: capability}" ;; esac
[ -z "$LNCF" ] || LNCS=""
is "lane counts: a branch commit whose subject is the mark lands in a felix merge squash as * Felix-Lane: capability, which does not mark: L 0 of T 1" \
   "$(_lnc_read sq-subject)" "built|0|1|zero|0|1"

# NAME MERGE-MESSAGE BRANCH-COMMIT... (MESSAGE SPEC pairs) -> $LNCD/NAME: the root, a branch with those commits two days
# before the clock, then a real merge of it into main a day before the clock, published. LNCR, LNCS as _lnc_one's.
_lnc_merged() {
  local n="$1" m="$2" k=0
  shift 2
  LNCS=""; LNCR=""; LNCF=""
  _lf_checkout "$LNCD/$n" lx $((LNCN - 30 * LNCDAY)) || return 1
  LNCR="$LF_REPO"
  _lnc_do _lf_commit "$LNCR" $((LNCN - 3 * LNCDAY)) $'docs: main moves on\n' docs/main.md
  _lnc_do _lf_branch "$LNCR" side "refs/heads/main~1"
  while [ "$#" -ge 2 ]; do
    k=$((k + 1))
    _lnc_do _lf_commit "$LNCR" $((LNCN - 2 * LNCDAY + k)) "$1" "$2"
    shift 2
  done
  _lnc_do _lf_switch "$LNCR" main
  _lnc_do _lf_merge "$LNCR" $((LNCN - LNCDAY)) side "$m"
  LNCS="$LF_SHA"
  _lnc_do _lf_publish "$LNCR"
  [ -z "$LNCF" ] && [ "$(_lf_spine "$LNCR")" = "$((LNCN - LNCDAY)):2 $((LNCN - 3 * LNCDAY)):1 $((LNCN - 30 * LNCDAY)):0" ] || LNCS=""
}
_lnc_merged merge-in $'Merge branch side\n' $'engine: y\n\nFelix-Lane: capability\n' engine/y.sh
is "lane counts: a real merge is read through the commits it merged: one of them carries the mark and changes engine/, the merge's own message none: L 1 of T 1" \
   "$(_lnc_read merge-in)" "built|0|1|ok|1|1"
_lnc_merged merge-own $'Merge branch side\n\nFelix-Lane: capability\n' $'engine: y\n\nNo mark.\n' engine/y.sh
is "lane counts: a real merge whose own message carries the mark, over an unmarked engine commit, is a lane landing: L 1 of T 1" \
   "$(_lnc_read merge-own)" "built|0|1|ok|1|1"
_lnc_merged merge-docs $'Merge branch side\n' $'docs: y\n\nFelix-Lane: capability\n' docs/y.md
is "lane counts: a real merge whose marked commit changes no counted path, and which changes none against its first parent, counts in neither: L 0 of T 0, idle" \
   "$(_lnc_read merge-docs)" "built|0|1|idle|0|0"
_lnc_merged merge-split $'Merge branch side\n' $'docs: y\n\nFelix-Lane: capability\n' docs/y.md $'engine: z\n\nNo mark.\n' engine/z.sh
is "lane counts: a real merge whose only marked commit changes docs, beside an unmarked engine commit, is counted by what it changed against its first parent and marked by what it merged: L 1 of T 1" \
   "$(_lnc_read merge-split)" "built|0|1|ok|1|1"

LNCF=""; LNCS=""
_lf_checkout "$LNCD/rename" lx $((LNCN - 30 * LNCDAY)); LNCR="$LF_REPO"
_lnc_do _lf_commit "$LNCR" $((LNCN - 20 * LNCDAY)) $'engine: x arrives\n' engine/x.sh   # outside the window: the rename is the only landing in it
_lnc_do _lf_commit "$LNCR" $((LNCN - LNCDAY)) $'docs: x moves out of engine/\n\nFelix-Lane: capability\n' 'engine/x.sh>docs/x.sh'
LNCS="$LF_SHA"
_lnc_do _lf_publish "$LNCR"
[ -z "$LNCF" ] || LNCS=""
is "lane counts: a marked landing that only moves engine/x.sh to docs/x.sh changed engine/x.sh (renames off), so it counts: L 1 of T 1" \
   "$(_lnc_read rename)" "built|0|1|ok|1|1"

# ---- L-RF5: a shallow clone ----------------------------------------------------------------------------------------------
LNCF=""
_lf_checkout "$LNCD/source" lx $((LNCN - 30 * LNCDAY)); LNCSRC="$LF_REPO"
_lnc_do _lf_chain "$LNCSRC" capability $((LNCN - 3 * LNCDAY)) 3600 m u m
LNCTIP="$LF_SHA"
( _fx_cd "$LNCD" && _lf_g 1700000000 clone -q --depth 2 "file://$LNCSRC" shallow ) >/dev/null 2>&1 || LNCF="${LNCF:-the clone}"
{ printf 'lx\n' > "$LNCD/shallow/.felix"; } 2>/dev/null
LNCSH="$(cd -P "$LNCD/shallow" 2>/dev/null && pwd -P)"
LNCa="$( _fx_cd "$LNCSH" || exit 1; printf '%s|%s' "$(_lf_g 1700000000 rev-parse --is-shallow-repository)" "$(_lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main)" )"
if [ -z "$LNCF" ] && [ -n "$LNCTIP" ] && [ "$LNCa" = "true|$LNCTIP" ]; then LNCBUILT=built; else LNCBUILT="not built: ${LNCF:-the clone reads [$LNCa]}"; fi
LNCR3="$LNCSH is a shallow clone, so its landings cannot all be read"
LNCWANT="$(_lf_tsv capability unknown - - 14 1/2 - 'Felix-Lane: capability' "$LNCNEXT" "$LNCTAB" "$(_lf_iso 1792900100)" \
             "$(_lf_iso $((LNCN - 3 * LNCDAY + 7200)))" "$LNCR3")"
_lf_run "$LNCD/sh-tsv" "$LNCSH" "$LNCN" "$FELIX" lane --tsv
is "lane counts L-RF5 L-NEVER-OK: a --depth 2 clone holding refs/remotes/origin/main reads unknown with R3 in felix lane --tsv, L and T -, never a count and never ok" \
   "$LNCBUILT|$LF_RC|$(cat "$LNCD/sh-tsv.out")" "built|0|$LNCWANT"
_lf_run "$LNCD/sh-human" "$LNCSH" "$LNCN" "$FELIX" lane
is "lane counts L-RF5 L-NEVER-OK: the shallow clone's human line reads unknown with R3, the last change of its row and the ref's date" \
   "$LNCBUILT|$LF_RC|$(cat "$LNCD/sh-human.out")" \
   "built|0|capability: unknown, $LNCR3; its lanes.tsv row last changed by $(printf '%.12s' "$LNCTAB") at $(_lf_iso 1792900100); refs/remotes/origin/main at $(_lf_iso $((LNCN - 3 * LNCDAY + 7200)))"
_lf_run "$LNCD/sh-status" "$LNCSH" "$LNCN" "$FELIX" status --tsv
is "lane counts L-RF5 L-NEVER-OK: in the shallow clone felix status --tsv ends with the lane row unknown, value -, and R3, never the value ok" \
   "$LNCBUILT|$LF_RC|$(_lf_last "$LNCD/sh-status.out")" "built|0|$(_lf_tsv lane unknown - "$LNCR3")"
if _lnc_py; then
  _lf_start "$LNCD/sh-start" "$LNCSH" "$LNCN" startup
  is "lane counts L-RF5: in the shallow clone session start exits 0 with valid JSON and neither a lane paragraph nor a lane token (control)" \
     "$LNCBUILT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|0|ok|none"
else
  skip "lane counts L-RF5: in the shallow clone session start exits 0 with valid JSON and neither a lane paragraph nor a lane token (control)" "python3 is absent, and the hook's JSON is read with it"
fi
# <<< lane-counts
