# >>> lane-pulse
printf '\nlane pulse: a lane line per row of the home project'"'"'s lanes.tsv, last, in the output, the log and the record (slice 0, design 6.5 item 5 and 6.6, C8, L-NEVER-OK; blind)\n'
# Blind, written on 2026-10-29 from docs/2026-10-29-capability-lane-first-slices-design.md and the slice 0 plan's
# Contracts (C1-C13) alone, before lib/lane.sh existed, without reading lib/, hooks/, bin/ or felix. Felix is run as a
# black box; the builders are tests/lib/lane-fixture.sh's. C11's row for this part: section 6.5 item 5 and 6.6 "The
# pulse": the pulse lines, in the log and in the record, last, each with the state, L and T that felix lane --tsv prints
# at the same FELIX_LANE_NOW; unknown with -; no line without a committed lanes.tsv; no line for a project other than
# the home's.
#
# The self-governed layout (C9): S is one repository, the home and the checkout, with .felix (pl) committed at its top;
# its root a month before the clock, its tables committed 29 days before it, then five landings from five days before
# it, an hour apart (_lf_chain: m u u md ud, the marks capability's), with refs/remotes/origin/main at the last. The
# memory root sits beside S, outside every repository. felix pulse runs as C9 says (_lf_run: the fixture HOME, the stubs
# first on PATH, uname and launchctl among them), from S unless a case says otherwise, then waits for the discovery
# lock. On this engine a run prints a pulse header, a backup line and a settings line; its record is "# ran <epoch>"
# and every line it printed after the header, and the log gains every line it printed. Readings where the Contracts
# leave room:
# - "Last" is asserted as: from the first line whose first field is lane to the end, the lines are exactly the lane
#   lines expected, and a backup and a settings line come before them.
# - The four-row table holds a valid lane counting engine/, one counting docs/, a row whose share is 3/2 (lane bad, R5)
#   and a row whose lane cell .x is no lane name (R5, column 1 -), so it shows unknown with - per row.
# - "Writes nothing it did not write before" is read as: nothing newer in S outside state/, .git included, and S's refs
#   and worktree list unchanged, asserted with the lane lines the run printed.
# - The no-line cases are controls (C10): lanes.tsv only in the working tree, a committed one with no row, a home that is
#   not a git checkout, a git home that binds no project, and a home whose own project has no lanes.tsv while another
#   project in it, whose checkout the pulse runs from, has one.
# - The review's second amendment (2026-10-30, design 11 item 45, still blind) adds C11's count that ends early (F1),
#   at the end, in a home of its own.
# - The second review's round 2 (2026-10-30, still blind) adds, at the end, R2B-F1 (a home bound by remote_match alone
#   whose resolution does not finish) and R2B-F2 (the count's scratch directory taken mid-count), each in its own home.
# - The second review's round 3 (2026-10-30, still blind) adds, at the end, R3-F1: a soft open-file limit from 10 to 24
#   set in the shell that execs felix pulse, in a home of its own.
# - Design item 46 (2026-10-30, still blind) adds, at the end, I46-21 to I46-30: C8's single line for a resolution of the
#   home's project that did not finish, under C9's probes inside felix_resolve_project, and no line for the misses (C2).
# - The third review's round 1 (2026-10-30, still blind) adds, at the end, V3R1-F1 and V3R1-F2: the pulse's lane lines
#   when the reads of a project.json's remote_match fail under the resolver, or under it and the lane's check (C2, C8).
LNPN=1793000000; LNPDAY=86400; LNPK=0
_lf_dir "$TMP/lane-2250"; LNPD="$LF_DIR"
_lf_stubs "$LNPD"; LNPB="$LF_BIN"
_lf_self "$LNPD/home" pl $((LNPN - 30 * LNPDAY)); LNPH="$LF_HOME"; LNPP="$LF_PROJ"
_lf_use "$LNPH" "$LNPD/memory" "$LNPD/user" "$LNPB"
LNP1=$'capability\t^engine/\t1/2\t14\n'
LNP4=$'# The lanes the home counts.\ncapability\t^engine/\t1/2\t14\n\ndocs\t^docs/\t1/3\t7\nbad\t^engine/\t3/2\t14\n.x\t^engine/\t1/2\t14\n'
LNPW1="$(_lf_tsv lane capability short 1 3)"
LNPW4="$LNPW1"$'\n'"$(_lf_tsv lane docs zero 0 2)"$'\n'"$(_lf_tsv lane bad unknown - -)"$'\n'"$(_lf_tsv lane - unknown - -)"
LNPU4="$(_lf_tsv lane capability unknown - -)"$'\n'"$(_lf_tsv lane docs unknown - -)"$'\n'"$(_lf_tsv lane bad unknown - -)"$'\n'"$(_lf_tsv lane - unknown - -)"

# HOME PROJ REL LABEL BYTES -> PROJ/REL holds BYTES, committed in HOME at the next time; LNPT "built" when HOME's HEAD
# holds exactly them. REL - instead: PROJ's lanes.tsv removed by a commit, LNPT "built" when HEAD holds none.
_lnp_put() {
  local h="$1" p="$2" r="$3" t
  LNPK=$((LNPK + 1)); t=$((LNPN - 29 * LNPDAY + 100 * LNPK)); LNPT="not built: $4"
  if [ "$r" = - ]; then
    ( _fx_cd "$h" && _lf_g 1700000000 cat-file -e "HEAD:${p#"$h"/}/lanes.tsv" ) >/dev/null 2>&1 \
      && { _lf_commit "$p" "$t" "lanes.tsv removed: $4"$'\n' -lanes.tsv || return 1; }
    ( _fx_cd "$h" && _lf_g 1700000000 cat-file -e "HEAD:${p#"$h"/}/lanes.tsv" ) >/dev/null 2>&1 || LNPT=built
    return 0
  fi
  rm -f "$p/$r"
  _lf_table "$p" "$t" "$r" "$5" "$r: $4"$'\n' || return 1
  printf '%s' "$5" > "$LNPD/put.want"
  ( _fx_cd "$h" || exit 1; _lf_g 1700000000 cat-file blob "HEAD:${p#"$h"/}/$r" ) > "$LNPD/put.got" 2>/dev/null
  cmp -s "$LNPD/put.want" "$LNPD/put.got" && LNPT=built
}
# OUT [DIR [NOW]] -> felix pulse from DIR (the home of _lf_use) at the clock LNPN (or NOW; - unset), then the
# discovery lock waited for. OUT.out and OUT.err, LF_RC; LNPL0 the log's lines before the run.
_lnp_pulse() {
  LNPL0="$(_lf_count "$LF_H/state/pulse.log")"; [ -n "$LNPL0" ] || LNPL0=0
  _lf_run "$1" "${2:-$LF_H}" "${3-$LNPN}" "$FELIX" pulse
  _lf_calm "$LF_H"
}
# FILE -> its lines from the first whose first field is lane to its end; _lnp_lanes FILE -> its lane lines only.
_lnp_tail() { LC_ALL=C awk -F'\t' 'f || $1 == "lane" { f = 1; print }' "$1" 2>/dev/null; }
_lnp_lanes() { LC_ALL=C awk -F'\t' '$1 == "lane"' "$1" 2>/dev/null; }
# FILE -> "backup settings" when a backup line and a settings line come before its first lane line.
_lnp_before() {
  LC_ALL=C awk -F'\t' '$1 == "lane" { f = 1 } !f && $1 == "backup" { b = 1 } !f && $1 == "settings" { s = 1 }
    END { printf "%s %s", (f && b) ? "backup" : "no-backup-before-a-lane-line", (f && s) ? "settings" : "no-settings-before-a-lane-line" }' "$1" 2>/dev/null
}
# OUT -> LNPRS "same" when the record holds # ran <epoch> and then every line OUT printed after its header, else
# "differ"; LNPRT the record's lines from the first lane line on.
_lnp_rec() {
  local r="$LF_H/state/pulse.status.tsv"
  tail -n +2 "$r" > "$LNPD/rec.rest" 2>/dev/null; tail -n +2 "$1.out" > "$LNPD/out.rest" 2>/dev/null
  LNPRT="$(_lnp_tail "$r")"; LNPRS=differ
  if [ -n "$(LC_ALL=C awk 'NR == 1 && /^# ran [0123456789]+$/' "$r" 2>/dev/null)" ] && cmp -s "$LNPD/rec.rest" "$LNPD/out.rest"; then LNPRS=same; fi
}
# OUT -> LNPLS "same" when the log grew by exactly the lines OUT printed, and they are its last, else "differ"; LNPLT
# those lines from the first lane line on.
_lnp_log() {
  local l="$LF_H/state/pulse.log" n m
  n="$(_lf_count "$1.out")"; [ -n "$n" ] || n=0
  m="$(_lf_count "$l")"; [ -n "$m" ] || m=0
  tail -n "$n" "$l" > "$LNPD/log.last" 2>/dev/null
  LNPLT="$(_lnp_tail "$LNPD/log.last")"; LNPLS=differ
  if [ "$((m - LNPL0))" = "$n" ] && cmp -s "$LNPD/log.last" "$1.out"; then LNPLS=same; fi
}

# ---- the home: tables, landings, one lane ---------------------------------------------------------------------------------
_lnp_put "$LNPH" "$LNPP" lanes.tsv "one lane" "$LNP1"; LNPT1="$LNPT"
_lnp_put "$LNPH" "$LNPP" lane-next.tsv "the next item" "$(_lf_tsv capability 'the next capability item')"$'\n'
_lf_chain "$LNPH" capability $((LNPN - 5 * LNPDAY)) 3600 m u u md ud; LNPTIP="$LF_SHA"
LNPE="not built: the home's landings [$(_lf_spine "$LNPH")]"
case "$(_lf_spine "$LNPH")" in
  "$((LNPN - 5 * LNPDAY + 4 * 3600)):1 $((LNPN - 5 * LNPDAY + 3 * 3600)):1 $((LNPN - 5 * LNPDAY + 2 * 3600)):1 $((LNPN - 5 * LNPDAY + 3600)):1 $((LNPN - 5 * LNPDAY)):1 "*" $((LNPN - 30 * LNPDAY)):0")
    [ "$LNPT1" = built ] && [ -n "$LNPTIP" ] && LNPE=built ;;
esac
_lnp_pulse "$LNPD/p1"
is "lane pulse: one lane, capability, L 1 of T 3: felix pulse exits 0 and its last line is lane capability short 1 3, after its backup and settings lines" \
   "$LNPE|$LF_RC|$(_lnp_tail "$LNPD/p1.out")|$(_lnp_before "$LNPD/p1.out")" "built|0|$LNPW1|backup settings"
_lf_run "$LNPD/t1" "$LNPH" "$LNPN" "$FELIX" lane --tsv
is "lane pulse: the line carries the state, L and T that felix lane --tsv prints in the home at the same FELIX_LANE_NOW" \
   "$LNPE|$(_lnp_lanes "$LNPD/p1.out")|$(LC_ALL=C awk -F'\t' '{ printf "%slane\t%s\t%s\t%s\t%s", (NR > 1 ? "\n" : ""), $1, $2, $3, $4 }' "$LNPD/t1.out")" \
   "built|$LNPW1|$LNPW1"
_lnp_rec "$LNPD/p1"; _lnp_log "$LNPD/p1"
is "lane pulse: state/pulse.status.tsv opens # ran <epoch>, holds every line the run printed after its header, and ends with the lane line" \
   "$LNPE|$LNPRS|$LNPRT" "built|same|$LNPW1"
is "lane pulse: state/pulse.log gains exactly the lines the run printed, the lane line last" \
   "$LNPE|$LNPLS|$LNPLT" "built|same|$LNPW1"

# ---- four rows: a line each, in file order, unknown with - ------------------------------------------------------------------
_lnp_put "$LNPH" "$LNPP" lanes.tsv "four rows" "$LNP4"; LNPT4="$LNPT"
_lnp_pulse "$LNPD/p2"
is "lane pulse L-NEVER-OK: four rows give four lines, last and in file order: capability short 1 3, docs zero 0 2, lane bad unknown - - (share 3/2) and lane - unknown - - (a lane cell that is no lane name)" \
   "$LNPE|$LNPT4|$LF_RC|$(_lnp_tail "$LNPD/p2.out")|$(_lnp_before "$LNPD/p2.out")" "built|built|0|$LNPW4|backup settings"
_lf_run "$LNPD/t2" "$LNPH" "$LNPN" "$FELIX" lane --tsv
is "lane pulse L-NEVER-OK: each of the four lines is lane, then columns 1 to 4 of the felix lane --tsv line of its row at the same FELIX_LANE_NOW" \
   "$LNPE|$LNPT4|$(_lnp_lanes "$LNPD/p2.out")|$(LC_ALL=C awk -F'\t' '{ printf "%slane\t%s\t%s\t%s\t%s", (NR > 1 ? "\n" : ""), $1, $2, $3, $4 }' "$LNPD/t2.out")" \
   "built|built|$LNPW4|$LNPW4"
_lnp_rec "$LNPD/p2"; _lnp_log "$LNPD/p2"
is "lane pulse L-NEVER-OK: the record ends with the four lane lines, and the log gains the run's lines, the four lane lines last" \
   "$LNPE|$LNPT4|$LNPRS|$LNPRT|$LNPLS|$LNPLT" "built|built|same|$LNPW4|same|$LNPW4"
_lnp_pulse "$LNPD/p3"
is "lane pulse: a second run appends its four lane lines to the log (nine there, after one and four), and the record, rewritten, holds four" \
   "$LNPE|$LNPT4|$LF_RC|$(_lnp_lanes "$LF_H/state/pulse.log" | LC_ALL=C awk 'END { print NR }')|$(_lnp_lanes "$LF_H/state/pulse.status.tsv")" \
   "built|built|0|9|$LNPW4"

# ---- the review's F1: a fork that fails in the read of the landings (C3, C8) ----------------------------------------------
# Added on 2026-10-30 from the adversarial review of the first build, still blind. C3 counts a fork that fails among the
# git reads that do not finish, so every lane the fault reaches reads unknown with - for L and T, and C8 still gives a
# line per row, last. The fault is part 2210's: a bash function git, exported into felix pulse, that lowers the process
# limit to 1 (ulimit -S -u 1) in the shell running it when its words hold --first-parent and refs/remotes/origin/main,
# then runs git, which that shell cannot fork; "fired" and, if the shell gets there, "ran <status>" go to a file. It
# runs here, after the log's count above, so that count stays as it was; the table is the four-row one.
_lnp_fork() {
  local f="$1.fired"
  rm -f "$f"
  LNPL0="$(_lf_count "$LF_H/state/pulse.log")"; [ -n "$LNPL0" ] || LNPL0=0
  ( eval "git() { local z='' r; case \" \$* \" in *' --first-parent '*) case \" \$* \" in *' refs/remotes/origin/main'*) z=1; printf 'fired\n' >> $(printf '%q' "$f"); ulimit -S -u 1 ;; esac ;; esac; command git \"\$@\"; r=\$?; [ -z \"\$z\" ] || printf 'ran %s\n' \"\$r\" >> $(printf '%q' "$f"); return \"\$r\"; }"
    export -f git
    _lf_run "$1" "$LF_H" "$LNPN" "$FELIX" pulse
    exit "$LF_RC" )
  LF_RC=$?
  _lf_calm "$LF_H"
  LNPFIRE="$(LC_ALL=C awk '$0 == "fired" { f = 1 } $0 == "ran 0" { r = 1 }
    END { s = "not fired"; if (f && r) s = "fired, but git ran to a clean exit after it"; if (f && !r) s = "fired"; print s }' "$f" 2>/dev/null)"
  [ -n "$LNPFIRE" ] || LNPFIRE="not fired"
}
_lnp_fork "$LNPD/f1"
is "lane pulse F1-fork-reads-as-no-lane L-NEVER-OK: a fork that fails in the read of the landings on refs/remotes/origin/main still gives the four lane lines last, each unknown with L and T -, after the backup and settings lines, never no line" \
   "$LNPE|$LNPT4|$LNPFIRE|$LF_RC|$(_lnp_tail "$LNPD/f1.out")|$(_lnp_before "$LNPD/f1.out")" "built|built|fired|0|$LNPU4|backup settings"

# ---- the clock, and unknown ----------------------------------------------------------------------------------------------------
_lnp_pulse "$LNPD/p4" "$LNPH" $((LNPN + 20 * LNPDAY))
is "lane pulse: with FELIX_LANE_NOW twenty days on, no landing is in either window: capability and docs read idle 0 0, the broken rows still unknown" \
   "$LNPE|$LNPT4|$LF_RC|$(_lnp_tail "$LNPD/p4.out")" \
   "built|built|0|$(_lf_tsv lane capability idle 0 0)"$'\n'"$(_lf_tsv lane docs idle 0 0)"$'\n'"$(_lf_tsv lane bad unknown - -)"$'\n'"$(_lf_tsv lane - unknown - -)"
_lnp_pulse "$LNPD/p5" "$LNPH" 0123
is "lane pulse L-NEVER-OK: FELIX_LANE_NOW=0123 (R8) gives every row unknown, L and T -, never a count" \
   "$LNPE|$LNPT4|$LF_RC|$(_lnp_tail "$LNPD/p5.out")" "built|built|0|$LNPU4"
LNPa="not built: the ref deleted"
( _fx_cd "$LNPH" && _lf_g 1700000000 update-ref -d refs/remotes/origin/main ) >/dev/null 2>&1 \
  && ! ( _fx_cd "$LNPH" && _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main ) >/dev/null 2>&1 && LNPa=built
_lnp_pulse "$LNPD/p6"
is "lane pulse L-NEVER-OK: with refs/remotes/origin/main deleted in the home (R1), every row reads unknown, L and T -" \
   "$LNPa|$LNPT4|$LF_RC|$(_lnp_tail "$LNPD/p6.out")" "built|built|0|$LNPU4"
_lf_publish "$LNPH" "$LNPTIP" && [ "$( _fx_cd "$LNPH" && _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main )" = "$LNPTIP" ] \
  || LNPE="not built: refs/remotes/origin/main not put back at the last landing"
_lnp_put "$LNPH" "$LNPP" lanes.tsv "a CR in a row" $'capability\t^engine/\t1/2\t14\r\n'
_lnp_pulse "$LNPD/p7"
is "lane pulse L-NEVER-OK: a committed lanes.tsv the shape check refuses (a CR in its row, R4) gives the one line lane - unknown - -" \
   "$LNPE|$LNPT|$LF_RC|$(_lnp_tail "$LNPD/p7.out")" "built|built|0|$(_lf_tsv lane - unknown - -)"

# ---- the run writes nothing else -------------------------------------------------------------------------------------------------
_lnp_put "$LNPH" "$LNPP" lanes.tsv "four rows again" "$LNP4"
sleep 1; touch "$LNPD/ro.marker"
LNPa="$( _fx_cd "$LNPH" && _lf_g 1700000000 for-each-ref )"; LNPb="$( _fx_cd "$LNPH" && _lf_g 1700000000 worktree list --porcelain )"
_lnp_pulse "$LNPD/p8"
LNPc="$(find "$LNPH" -newer "$LNPD/ro.marker" ! -path "$LNPH/state" ! -path "$LNPH/state/*" 2>&1)"
LNPa="$([ -n "$LNPa" ] && [ "$LNPa" = "$( _fx_cd "$LNPH" && _lf_g 1700000000 for-each-ref )" ] && echo same || echo changed)"
LNPb="$([ -n "$LNPb" ] && [ "$LNPb" = "$( _fx_cd "$LNPH" && _lf_g 1700000000 worktree list --porcelain )" ] && echo same || echo changed)"
is "lane pulse: a run leaves nothing newer in the home outside state/, .git included, its refs and worktree list as they were, and prints the four lane lines last" \
   "$LNPE|$LNPT|$LF_RC|newer[$LNPc]|$LNPa|$LNPb|$(_lnp_tail "$LNPD/p8.out")" "built|built|0|newer[]|same|same|$LNPW4"

# ---- only the home's project ------------------------------------------------------------------------------------------------------
LNPa="not built: project qo"
mkdir -p "$LNPH/projects/qo"; printf '{"name":"qo","gate":"true"}\n' > "$LNPH/projects/qo/project.json"; printf '# qo\n' > "$LNPH/projects/qo/CLAUDE.md"
printf 'other\t^engine/\t1/2\t14\n' > "$LNPH/projects/qo/lanes.tsv"
_lf_commit "$LNPH" $((LNPN - 29 * LNPDAY + 9000)) $'project qo, with a lane of its own\n' \
  =projects/qo/project.json =projects/qo/CLAUDE.md =projects/qo/lanes.tsv && LNPa=built
_lf_checkout "$LNPD/qo" qo $((LNPN - 30 * LNPDAY)); LNPQ="$LF_REPO"
_lf_chain "$LNPQ" other $((LNPN - 3 * LNPDAY)) 3600 m u || LNPa="not built: qo's checkout"
_lnp_pulse "$LNPD/p9" "$LNPQ"
is "lane pulse: run from the checkout of another project of the home, whose own lanes.tsv has a row, the lane lines are the home project's four and no other" \
   "$LNPE|$LNPa|$LF_RC|$(_lnp_tail "$LNPD/p9.out")" "built|built|0|$LNPW4"

# ---- no lane line (controls) ------------------------------------------------------------------------------------------------------
# OUT LABEL BUILT [DIR] -> a pulse run from DIR (the home): it exits 0 and prints no lane line, nor does its record hold one.
_lnp_none() {
  _lnp_pulse "$1" "${4:-$LF_H}"
  is "lane pulse: $2: felix pulse exits 0 with no lane line in its output or its record (control)" \
     "$3|$LF_RC|$(_lnp_lanes "$1.out")|$(_lnp_lanes "$LF_H/state/pulse.status.tsv")" "built|0||"
}
_lnp_put "$LNPH" "$LNPP" lanes.tsv "comments and a blank line, no row" $'# No lane is counted yet.\n\n'
_lnp_none "$LNPD/n1" "a committed lanes.tsv holding only a comment and a blank line" "$LNPT"
_lnp_put "$LNPH" "$LNPP" - "removed"; printf '%s' "$LNP4" > "$LNPP/lanes.tsv"
_lnp_none "$LNPD/n2" "lanes.tsv with four rows in the home's working tree, removed from HEAD by a commit" "$LNPT"

LNPa="not built: a home that is not a git checkout"; LNPG="$LNPD/plain-home"
mkdir -p "$LNPG/projects/pl" && printf 'pl\n' > "$LNPG/.felix" && printf '{"name":"pl","gate":"true"}\n' > "$LNPG/projects/pl/project.json" \
  && printf '# pl\n' > "$LNPG/projects/pl/CLAUDE.md" && printf '%s' "$LNP1" > "$LNPG/projects/pl/lanes.tsv" \
  && ! ( _fx_cd "$LNPG" && _lf_g 1700000000 rev-parse --git-dir ) >/dev/null 2>&1 && LNPa=built
_lf_use "$LNPG" "$LNPD/memory" "$LNPD/user" "$LNPB"
_lnp_none "$LNPD/n3" "a home that is not a git checkout, with .felix and a lanes.tsv holding a row" "$LNPa"

_lf_home "$LNPD/apart-home" pl $((LNPN - 30 * LNPDAY)); LNPA="$LF_HOME"; LNPa="not built: a home that binds no project"
_lnp_put "$LNPA" "$LF_PROJ" lanes.tsv "one lane, in a home that binds no project" "$LNP1"
_lf_chain "$LNPA" capability $((LNPN - 5 * LNPDAY)) 3600 m u u && [ "$LNPT" = built ] && [ ! -e "$LNPA/.felix" ] && LNPa=built
_lf_use "$LNPA" "$LNPD/memory" "$LNPD/user" "$LNPB"
_lnp_none "$LNPD/n4" "a git home with engine landings on origin/main and pl's lanes.tsv committed, which binds no project (no .felix, no remote)" "$LNPa"

_lf_self "$LNPD/other-home" pl $((LNPN - 30 * LNPDAY)); LNPO="$LF_HOME"; LNPa="not built: a home whose project has no lanes.tsv"
mkdir -p "$LNPO/projects/qo"; printf '{"name":"qo","gate":"true"}\n' > "$LNPO/projects/qo/project.json"; printf '# qo\n' > "$LNPO/projects/qo/CLAUDE.md"
_lf_commit "$LNPO" $((LNPN - 29 * LNPDAY)) $'project qo\n' =projects/qo/project.json =projects/qo/CLAUDE.md
_lnp_put "$LNPO" "$LNPO/projects/qo" lanes.tsv "qo's lane" "$LNP1"
_lf_chain "$LNPO" capability $((LNPN - 5 * LNPDAY)) 3600 m u u && [ "$LNPT" = built ] \
  && ! ( _fx_cd "$LNPO" && _lf_g 1700000000 cat-file -e HEAD:projects/pl/lanes.tsv ) >/dev/null 2>&1 && LNPa=built
_lf_checkout "$LNPD/qo2" qo $((LNPN - 30 * LNPDAY)); LNPQ2="$LF_REPO"
_lf_chain "$LNPQ2" capability $((LNPN - 3 * LNPDAY)) 3600 m u || LNPa="not built: qo's checkout"
_lf_use "$LNPO" "$LNPD/memory" "$LNPD/user" "$LNPB"
_lnp_none "$LNPD/n5" "run from a checkout of project qo, whose lanes.tsv has a row, in a home bound to pl, which has none" "$LNPa" "$LNPQ2"
_lf_use "$LNPH" "$LNPD/memory" "$LNPD/user" "$LNPB"

# ---- the review's F1: a count that ends early (C3, C8, C9) -------------------------------------------------------------
# Added on 2026-10-30 from the review's second amendment, still blind, last in this part and in a self-governed home of
# its own, because a run ended early may leave state behind. Its lanes: capability (^engine/, 1/2, 14) and docs
# (^docs/, 1/4, 7); its landings, five days back and an hour apart, an unmarked engine change and a docs change marked
# for capability, so without the fault the pulse ends with lane capability zero 0 1 and lane docs zero 0 1. Then C9's
# fault through _lf_fault kill, with TMPDIR a directory of the fixture's own: when a read of the landings starts, the
# shell that runs it has its parent, then itself, killed. C8 and C9 allow two endings, and the assertion accepts exactly
# these after the backup and settings lines: the single line lane - unknown - -, or, where each process ended was one
# read's own, one R2 line per lane, lane <lane> unknown - -. The pulse still exits 0.
LNPa="not built: the home for a count that ends early"
LNPKZ=$'capability\t^engine/\t1/2\t14\ndocs\t^docs/\t1/4\t7\n'
if _lf_self "$LNPD/kill-home" pl $((LNPN - 30 * LNPDAY)); then
  LNPKH="$LF_HOME"
  _lnp_put "$LNPKH" "$LF_PROJ" lanes.tsv "two lanes, for a count that ends early" "$LNPKZ"
  _lf_chain "$LNPKH" capability $((LNPN - 5 * LNPDAY)) 3600 u md && [ "$LNPT" = built ] \
    && [ "$(_lf_spine "$LNPKH" | LC_ALL=C awk '{ print NF }')" = 4 ] && LNPa=built
  _lf_use "$LNPKH" "$LNPD/memory" "$LNPD/user" "$LNPB"
  _lnp_pulse "$LNPD/k0"; LNPb="$LF_RC|$(_lnp_tail "$LNPD/k0.out")"
  LNPkt="$LNPD/f1k-tmp"; rm -rf "$LNPkt"; mkdir -p "$LNPkt"
  _lf_fault kill "$LNPD/f1k.fired" "$LNPkt" _lf_run "$LNPD/f1k" "$LNPKH" "$LNPN" "$FELIX" pulse
  _lf_calm "$LNPKH"
  LNPc="$(_lnp_tail "$LNPD/f1k.out")"
  case "$LNPc" in
    ("$(_lf_tsv lane - unknown - -)"|"$(_lf_tsv lane capability unknown - -)"$'\n'"$(_lf_tsv lane docs unknown - -)") LNPc="C3 or R2" ;;
    (*) LNPc="lane lines [$LNPc]" ;;
  esac
else
  LNPb="not run"; LNPc="not run"; LF_FIRE="not run"; LF_RC=125
fi
is "lane pulse F1-count-ends-early L-NEVER-OK: where the pulse ends with lane capability zero 0 1 and lane docs zero 0 1, the parent of the shell that runs a read of the landings, then that shell, killed (C9): felix pulse exits 0 and its last lines, after its backup and settings lines, are the single lane - unknown - -, or one R2 line per lane; never a count and never no lane line" \
   "$LNPa|unfaulted $LNPb|$LF_FIRE|$LF_RC|$LNPc|$(_lnp_before "$LNPD/f1k.out")" \
   "built|unfaulted 0|$(_lf_tsv lane capability zero 0 1)"$'\n'"$(_lf_tsv lane docs zero 0 1)|fired|0|C3 or R2|backup settings"
_lf_use "$LNPH" "$LNPD/memory" "$LNPD/user" "$LNPB"

# ---- the second review's round 1: forks that fail as the pulse finds the home's project (R2-F2) -----------------------
# Added on 2026-10-30 from the second review's findings (their inputs and observed output only), still blind, last, in a
# self-governed home of its own: R holds .felix (p), lanes.tsv (cap ^engine/ 1/2 14, sec ^docs/ 1/2 7) committed, and the
# review's landings (_lf_r2land), so that the pulse ends with lane cap zero 0 2 and lane sec short 1 3. The faults are
# the review's fork probes (_lf_fork), by the words and calling functions it names, inputs of the finding: (b) git
# rev-parse --git-dir with felix_lane_pulse on the stack; (c) tr -d [:space:] in felix_resolve_project called from
# felix_lane_pulse. C8 gives no lane line only for a home with no committed lanes.tsv or no row, or one that is not a git
# checkout bound to a project, and this home is none of them; a read that did not finish never reads as one (C3). So
# the pulse ends with its two lane lines, the single lane - unknown - - (C8), or one unknown line per lane, after its
# backup and settings lines; or, as C3 says of a fork that fails in the surface's own shell, it ends with 128. Each
# assertion also compares the pulse without the fault, so it is red on main.
LNPRT="$LNPD/r2-tmp"; mkdir -p "$LNPRT"; LNPRA="not built: R2-F2's home"; LNPRH=""
if _lf_self "$LNPD/r2" p $((LNPN - 30 * LNPDAY)); then
  LNPRH="$LF_HOME"
  _lnp_put "$LNPRH" "$LF_PROJ" lanes.tsv "R2-F2's two lanes" $'cap\t^engine/\t1/2\t14\nsec\t^docs/\t1/2\t7\n'
  LNPa="$((LNPN - LNPDAY)):1 $((LNPN - 2 * LNPDAY)):1 $((LNPN - 3 * LNPDAY)):1 $((LNPN - 4 * LNPDAY)):1 $((LNPN - 5 * LNPDAY)):1"
  _lf_r2land "$LNPRH" "$LNPN" && [ "$LNPT" = built ] \
    && case "$(_lf_spine "$LNPRH")" in ("$LNPa $((LNPN - 20 * LNPDAY)):1 "*" $((LNPN - 30 * LNPDAY)):0") LNPRA=built ;; esac
fi
_lf_use "${LNPRH:-$LNPD/r2}" "$LNPD/r2-memory" "$LNPD/r2-user" "$LNPB"
LNPRW="$(_lf_tsv lane cap zero 0 2)"$'\n'"$(_lf_tsv lane sec short 1 3)"
_lnp_pulse "$LNPD/r2-0"; LNPb="$LF_RC|$(_lnp_tail "$LNPD/r2-0.out")|$(_lnp_before "$LNPD/r2-0.out")"
# OUT -> "lane lines or 128" when the faulted pulse whose files are OUT.* ended as the readings above accept, else its
# status, its lines from the first lane line on, and what came before them.
_lnp_r2() {
  local t
  t="$(_lnp_tail "$1.out")"
  if [ "$LF_RC" = 128 ] && [ -z "$(LC_ALL=C awk -F'\t' '$1 == "lane" && $3 != "unknown"' "$1.out" 2>/dev/null)" ]; then printf 'lane lines or 128'; return 0; fi
  if [ "$LF_RC" = 0 ] && [ "$(_lnp_before "$1.out")" = "backup settings" ]; then
    case "$t" in
      ("$LNPRW"|"$(_lf_tsv lane - unknown - -)"|"$(_lf_tsv lane cap unknown - -)"$'\n'"$(_lf_tsv lane sec unknown - -)") printf 'lane lines or 128'; return 0 ;;
    esac
  fi
  printf 'status %s, lane lines [%s], %s' "$LF_RC" "$t" "$(_lnp_before "$1.out")"
}
_lf_fork fork git "*' rev-parse --git-dir '*" "*' felix_lane_pulse '*" "$LNPD/r2f2b.fired" "$LNPRT" _lf_run "$LNPD/r2f2b" "$LNPRH" "$LNPN" "$FELIX" pulse
_lf_calm "$LNPRH"
is "lane pulse R2-F2-pulse-drops-lane-lines L-NEVER-OK: (b) a fork that fails in the pulse's git read of the home (rev-parse --git-dir, felix_lane_pulse on the stack), where without it the pulse ends with lane cap zero 0 2 and lane sec short 1 3: felix pulse ends with those lines, lane - unknown - -, or an unknown line per lane, after its backup and settings lines, or ends with 128; never exit 0 with no lane line" \
   "$LNPRA|unfaulted $LNPb|$LF_FIRE|$(_lnp_r2 "$LNPD/r2f2b")" "built|unfaulted 0|$LNPRW|backup settings|fired|lane lines or 128"
_lf_fork fork tr "*' -d [:space:] '*" "*' felix_resolve_project felix_lane_pulse '*|*' felix_resolve_project '*' felix_lane_pulse '*" \
  "$LNPD/r2f2c.fired" "$LNPRT" _lf_run "$LNPD/r2f2c" "$LNPRH" "$LNPN" "$FELIX" pulse
_lf_calm "$LNPRH"
is "lane pulse R2-F2-pulse-drops-lane-lines L-NEVER-OK: (c) a fork that fails as the pulse reads the home's .felix (tr -d [:space:] in felix_resolve_project, called from felix_lane_pulse): felix pulse ends with the two lane lines, lane - unknown - -, or an unknown line per lane, after its backup and settings lines, or ends with 128; never exit 0 with no lane line" \
   "$LNPRA|unfaulted $LNPb|$LF_FIRE|$(_lnp_r2 "$LNPD/r2f2c")" "built|unfaulted 0|$LNPRW|backup settings|fired|lane lines or 128"
_lf_use "$LNPH" "$LNPD/memory" "$LNPD/user" "$LNPB"

# ---- the second review's round 2: a home bound by remote_match alone, and a scratch directory taken (R2B-F1, R2B-F2) ---
# Added on 2026-10-30 from the second review's round 2 findings (their inputs and observed output only), still blind,
# last, each in a home of its own. R2B-F1: a home with no .felix, bound to p by remote_match alone (C2: the marker first,
# then a project.json remote_match): p's project.json names remote_match o/r (written in its working tree, as _lf_match
# does) and its origin is https://github.com/o/r.git, never fetched; lanes.tsv and the landings are R2-F2's, so without
# the fault the pulse ends with lane cap zero 0 2 and lane sec short 1 3. The fault is the review's fork probe (_lf_fork)
# at the one git call whose words hold get-url, made under felix_resolve_project. A resolution that did not finish is
# not a home bound to no project (C8, C9: never no line), so the pulse ends as _lnp_r2 accepts: the two lines, lane -
# unknown - -, an unknown line per lane, or 128. R2B-F2: a self-governed home (project g, lanes.tsv cap ^engine/ 1/2 14,
# no lane-next.tsv, a marked and an unmarked engine landing five days back), where the pulse ends with lane cap ok 1 2;
# the fault (_lf_gone) removes the count's scratch directory at the read of lanes.tsv's rows (A: skip=,
# felix_table_rows) or at the tally of the window (B: t[$2]++, _lane_window). A gives lane - unknown - - (C3's count
# that did not finish, or R9's one line); B that line or lane cap unknown - - (R2). Never no line, and never idle 0 0.
LNPMA="not built: R2B-F1's home"; LNPMH="$LNPD/r2bm"
if _lf_home "$LNPD/r2bm" p $((LNPN - 30 * LNPDAY)); then
  LNPMH="$LF_HOME"
  _lnp_put "$LNPMH" "$LF_PROJ" lanes.tsv "R2B-F1's two lanes" $'cap\t^engine/\t1/2\t14\nsec\t^docs/\t1/2\t7\n'
  LNPa="$((LNPN - LNPDAY)):1 $((LNPN - 2 * LNPDAY)):1 $((LNPN - 3 * LNPDAY)):1 $((LNPN - 4 * LNPDAY)):1 $((LNPN - 5 * LNPDAY)):1"
  _lf_r2land "$LNPMH" "$LNPN" && [ "$LNPT" = built ] && _lf_match "$LF_PROJ" o/r && _lf_origin "$LNPMH" https://github.com/o/r.git \
    && [ ! -e "$LNPMH/.felix" ] && case "$(_lf_spine "$LNPMH")" in ("$LNPa $((LNPN - 20 * LNPDAY)):1 "*" $((LNPN - 30 * LNPDAY)):0") LNPMA=built ;; esac
fi
_lf_use "$LNPMH" "$LNPD/r2bm-memory" "$LNPD/r2bm-user" "$LNPB"
_lnp_pulse "$LNPD/r2bm-0"; LNPb="$LF_RC|$(_lnp_tail "$LNPD/r2bm-0.out")|$(_lnp_before "$LNPD/r2bm-0.out")"
_lf_fork fork git '*get-url*' "*' felix_resolve_project '*" "$LNPD/r2bmf.fired" "$LNPRT" _lf_run "$LNPD/r2bmf" "$LNPMH" "$LNPN" "$FELIX" pulse
_lf_calm "$LNPMH"
is "lane pulse R2B-F1-remote-match-resolution-reads-ungoverned L-NEVER-OK: in a home bound to p by remote_match alone, where without the fault the pulse ends with lane cap zero 0 2 and lane sec short 1 3, a fork that fails in the git read of the origin's URL (get-url, felix_resolve_project on the stack): felix pulse ends with those lines, lane - unknown - -, or an unknown line per lane, after its backup and settings lines, or ends with 128; never exit 0 with no lane line" \
   "$LNPMA|unfaulted $LNPb|$LF_FIRE|$(_lnp_r2 "$LNPD/r2bmf")" "built|unfaulted 0|$LNPRW|backup settings|fired|lane lines or 128"

LNPGA="not built: R2B-F2's home"; LNPGH="$LNPD/r2bg"; LNPGT="$LNPD/r2bg-tmp"
if _lf_self "$LNPD/r2bg" g $((LNPN - 30 * LNPDAY)); then
  LNPGH="$LF_HOME"
  _lnp_put "$LNPGH" "$LF_PROJ" lanes.tsv "R2B-F2's lane" $'cap\t^engine/\t1/2\t14\n'
  _lf_chain "$LNPGH" cap $((LNPN - 5 * LNPDAY)) 3600 m u && [ "$LNPT" = built ] \
    && ! ( _fx_cd "$LNPGH" && _lf_g 1700000000 cat-file -e HEAD:projects/g/lane-next.tsv ) >/dev/null 2>&1 \
    && [ "$(_lf_spine "$LNPGH" | LC_ALL=C awk '{ print NF }')" = 4 ] && LNPGA=built
fi
_lf_use "$LNPGH" "$LNPD/r2bg-memory" "$LNPD/r2bg-user" "$LNPB"
_lnp_pulse "$LNPD/r2bg-0"; LNPb="$LF_RC|$(_lnp_tail "$LNPD/r2bg-0.out")|$(_lnp_before "$LNPD/r2bg-0.out")"
# CASE WORDS STACK -> felix pulse under _lf_gone, with a fresh TMPDIR; LNPc "unknown" when it exited 0 and its lines from
# the first lane line on are lane - unknown - - (either case) or lane cap unknown - - (case B), after its backup and
# settings lines, else what it printed.
_lnp_gone() {
  rm -rf "$LNPGT"; mkdir -p "$LNPGT"
  _lf_gone "$2" "$3" "$LNPD/r2bg-$1.fired" "$LNPGT" _lf_run "$LNPD/r2bg-$1" "$LNPGH" "$LNPN" "$FELIX" pulse
  _lf_calm "$LNPGH"
  LNPc="$LF_RC|$(_lnp_tail "$LNPD/r2bg-$1.out")|$(_lnp_before "$LNPD/r2bg-$1.out")"
  case "$1|$LNPc" in
    ("A|0|$(_lf_tsv lane - unknown - -)|backup settings"|"B|0|$(_lf_tsv lane - unknown - -)|backup settings"|"B|0|$(_lf_tsv lane cap unknown - -)|backup settings") LNPc=unknown ;;
  esac
}
_lnp_gone A '*skip=*' "*' felix_table_rows '*"
is "lane pulse R2B-F2-scratch-gone-reads-none-or-idle L-NEVER-OK: (A) the count's scratch directory removed at the read of lanes.tsv's rows (skip=, felix_table_rows), where without it the pulse ends with lane cap ok 1 2: felix pulse exits 0 and ends with lane - unknown - - after its backup and settings lines; never no lane line" \
   "$LNPGA|unfaulted $LNPb|$LF_FIRE|$LNPc" "built|unfaulted 0|$(_lf_tsv lane cap ok 1 2)|backup settings|fired|unknown"
_lnp_gone B "*'t[\$2]++'*" "*' _lane_window '*"
is "lane pulse R2B-F2-scratch-gone-reads-none-or-idle L-NEVER-OK: (B) the count's scratch directory removed at the tally of the window (t[\$2]++, _lane_window): felix pulse exits 0 and ends with lane - unknown - - or lane cap unknown - - after its backup and settings lines; never lane cap idle 0 0" \
   "$LNPGA|unfaulted $LNPb|$LF_FIRE|$LNPc" "built|unfaulted 0|$(_lf_tsv lane cap ok 1 2)|backup settings|fired|unknown"
_lf_use "$LNPH" "$LNPD/memory" "$LNPD/user" "$LNPB"

# ---- the second review's round 3: an open-file limit that drops the marks (R3-F1) -----------------------------------
# Added on 2026-10-30 from the second review's round 3 findings (their inputs and observed output only), still blind,
# last, in a self-governed home of its own: R holds .felix (p), lanes.tsv (cap ^engine/ 1/2 14, then sec ^docs/ 1/2 7)
# and lane-next.tsv committed, then the review's landings (_lf_r2land) dated from the machine clock at build time, and
# the pulse runs with FELIX_LANE_NOW unset, as the finding ran: without the fault it ends with lane cap zero 0 2 and lane
# sec short 1 3. The fault is the finding's: a soft open-file limit N, for each N from 10 to 24, set in the shell that
# execs felix pulse (_lf_nfprog, that shell first closing the descriptors from 3 up it inherited), with TMPDIR a
# directory of the fixture's own; no other fault. Readings (C3, C8): a read that did not finish never yields a count. So
# at every N the lane lines the pulse prints are, in order, lane cap zero 0 2 or lane cap unknown - -, then lane sec short
# 1 3 or lane sec unknown - -, or the single lane - unknown - -; a run that exits 0 prints all of them, last; a run that
# ends early (exit other than 0) may print fewer or none; a run that printed nothing at all said nothing of the lane (at
# the lowest limits felix cannot load its libraries). Never lane sec zero 0 3, and never exit 0 after lines with no lane
# line.
LNPN3="$(date +%s)"; LNPN3T="$LNPD/r3-tmp"; LNPN3A="not built: R3-F1's home"; LNPN3H="$LNPD/r3"
if _lf_self "$LNPD/r3" p $((LNPN3 - 40 * LNPDAY)); then
  LNPN3H="$LF_HOME"
  LNPa="$((LNPN3 - LNPDAY)):1 $((LNPN3 - 2 * LNPDAY)):1 $((LNPN3 - 3 * LNPDAY)):1 $((LNPN3 - 4 * LNPDAY)):1 $((LNPN3 - 5 * LNPDAY)):1"
  _lf_table "$LF_PROJ" $((LNPN3 - 29 * LNPDAY)) lanes.tsv $'cap\t^engine/\t1/2\t14\nsec\t^docs/\t1/2\t7\n' \
    && _lf_table "$LF_PROJ" $((LNPN3 - 29 * LNPDAY + 60)) lane-next.tsv $'cap\tcap next item\nsec\tsec next item\n' \
    && _lf_r2land "$LNPN3H" "$LNPN3" \
    && case "$(_lf_spine "$LNPN3H")" in ("$LNPa $((LNPN3 - 20 * LNPDAY)):1 "*" $((LNPN3 - 40 * LNPDAY)):0") LNPN3A=built ;; esac
fi
_lf_use "$LNPN3H" "$LNPD/r3-memory" "$LNPD/r3-user" "$LNPB"
_lnp_pulse "$LNPD/r3-0" "$LNPN3H" -; LNPb="$LF_RC|$(_lnp_tail "$LNPD/r3-0.out")|$(_lnp_before "$LNPD/r3-0.out")"
# OUT -> "unfaulted or unknown" when the pulse run whose files are OUT.* ended as the readings above accept, else its
# status and its lines from the first lane line on.
_lnp_r3() {
  if [ ! -s "$1.out" ] || [ "$(LC_ALL=C awk -F'\t' -v rc="$LF_RC" '
      $1 == "lane" { k++; l[k] = $0; next }
      k { x = 1 }
      END { t = "\t"; d = "lane" t "-" t "unknown" t "-" t "-"
        c1 = "lane" t "cap" t "zero" t "0" t "2"; u1 = "lane" t "cap" t "unknown" t "-" t "-"
        c2 = "lane" t "sec" t "short" t "1" t "3"; u2 = "lane" t "sec" t "unknown" t "-" t "-"
        if (k == 0) ok = (rc != "0")
        else if (l[1] == d) ok = (k == 1)
        else ok = ((l[1] == c1 || l[1] == u1) && k <= 2 && (k < 2 || l[2] == c2 || l[2] == u2) && (rc != "0" || k == 2))
        if (rc == "0" && x) ok = 0
        print (ok ? "yes" : "no") }' "$1.out")" = yes ]; then printf 'unfaulted or unknown'; return 0; fi
  printf 'status %s, lane lines [%s]' "$LF_RC" "$(_lnp_tail "$1.out")"
}
LNPa3=""; LNPl=""
for LNPm in 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24; do
  rm -rf "$LNPN3T"; mkdir -p "$LNPN3T"
  _lf_run "$LNPD/r3-$LNPm" "$LNPN3H" - TMPDIR="$LNPN3T" /bin/bash -c "$(_lf_nfprog)" "$LNPm" "$FELIX" pulse
  _lf_calm "$LNPN3H"
  [ "$(LC_ALL=C awk 'NR == 1' "$LNPD/r3-$LNPm.err")" = "limit $LNPm" ] || LNPl="$LNPl $LNPm"
  LNPx="$(_lnp_r3 "$LNPD/r3-$LNPm")"; [ "$LNPx" = 'unfaulted or unknown' ] || LNPa3="$LNPa3 [N=$LNPm: $LNPx]"
done
if [ -z "$LNPl" ]; then LNPl="the limit set at every N"; else LNPl="the limit not set at$LNPl"; fi
is "lane pulse R3-F1-open-file-limit-drops-marks L-NEVER-OK: with FELIX_LANE_NOW unset and a soft open-file limit N from 10 to 24 set in the shell that execs felix pulse, where without it the pulse ends with lane cap zero 0 2 and lane sec short 1 3: at every N its lane lines are those or unknown ones, in order, all of them and last when it exits 0; never lane sec zero 0 3" \
   "$LNPN3A|unfaulted $LNPb|$LNPl|${LNPa3:- unfaulted or unknown at every N}" "built|unfaulted 0|$LNPRW|backup settings|the limit set at every N| unfaulted or unknown at every N"
_lf_use "$LNPH" "$LNPD/memory" "$LNPD/user" "$LNPB"

# ---- design item 46: the pulse's line for a resolution that did not finish, and the misses that stand -------------------
# Added on 2026-10-30 from design 11 item 46 (C2's bullet The lane's resolution, C8's single line), still blind, last, in
# a home of its own that is its own checkout: LNPI holds p (remote_match o/r, as _lf_match writes it), lanes.tsv (cap
# ^engine/ 1/2 14, sec ^docs/ 1/2 7) committed and the review's landings (_lf_r2land); _lf_bind puts the home in a layout.
# Bound by its .felix alone (felix) or by remote_match alone (remote), the pulse ends with lane cap zero 0 2 and lane sec
# short 1 3. Readings:
# - I46-21 to I46-24: C9's fork and kill probes (_lf_probe) every time a read the miss stands on is made inside
#   felix_resolve_project (felix: tr -d [:space:], the read of the marker; remote: git remote get-url origin): felix pulse
#   exits 0, and its lines from the first lane line to the end, after its backup and settings lines, are exactly lane -
#   unknown - -, as are its record's. Only where a probe reached felix itself (LF_SELF) may it end with 137 (kill, C9) or
#   128 (fork, C3) and no lane line.
# - I46-25 to I46-30, no fault: in the layouts none, other, tie, nosuch, empty and closed the home binds no project (C2,
#   C8): felix pulse exits 0, prints its backup and settings lines and no lane line, and its record holds none. Each first
#   runs a layout that binds, so it is red on main, whose pulse prints no lane line.
LNPIA="not built: item 46's home"; LNPIH="$LNPD/i46"; LNPIT="$LNPD/i46-tmp"
LNPIW="$(_lf_tsv lane cap zero 0 2)"$'\n'"$(_lf_tsv lane sec short 1 3)"; LNPIU="$(_lf_tsv lane - unknown - -)"
if _lf_home "$LNPD/i46" p $((LNPN - 30 * LNPDAY)); then
  LNPIH="$LF_HOME"
  LNPa="$((LNPN - LNPDAY)):1 $((LNPN - 2 * LNPDAY)):1 $((LNPN - 3 * LNPDAY)):1 $((LNPN - 4 * LNPDAY)):1 $((LNPN - 5 * LNPDAY)):1"
  _lf_table "$LF_PROJ" $((LNPN - 29 * LNPDAY)) lanes.tsv $'cap\t^engine/\t1/2\t14\nsec\t^docs/\t1/2\t7\n' && _lf_r2land "$LNPIH" "$LNPN" \
    && case "$(_lf_spine "$LNPIH")" in ("$LNPa $((LNPN - 20 * LNPDAY)):1 "*" $((LNPN - 30 * LNPDAY)):0") LNPIA=built ;; esac
fi
_lf_use "$LNPIH" "$LNPD/i46-memory" "$LNPD/i46-user" "$LNPB"
# LAYOUT MODE NAME WORDS -> the home in LAYOUT; felix pulse there; then felix pulse under _lf_probe MODE NAME WORDS,
# felix_resolve_project on the stack, with a fresh TMPDIR. LNPa what was built and the unfaulted lane lines, LNPb the
# probe's LF_FIRE and "one unknown line" when the run ended as the readings above say, else its status and lines.
_lnp_i46f() {
  local t r
  _lf_bind "$LNPIH" "$LNPIH" p "$1"; LNPa="$LNPIA|$LF_BOUND"
  _lnp_pulse "$LNPD/i46-0"; LNPa="$LNPa|unfaulted $LF_RC|$(_lnp_tail "$LNPD/i46-0.out")"
  rm -rf "$LNPIT"; mkdir -p "$LNPIT"
  _lf_probe "$2" "$3" "$4" "*' felix_resolve_project '*" "$LNPD/i46f.fired" "$LNPIT" _lf_run "$LNPD/i46f" "$LNPIH" "$LNPN" "$FELIX" pulse
  _lf_calm "$LNPIH"
  t="$(_lnp_tail "$LNPD/i46f.out")"; r="$(_lnp_tail "$LNPIH/state/pulse.status.tsv")"
  LNPb="$LF_FIRE|status $LF_RC, lane lines [$t], record [$r], $(_lnp_before "$LNPD/i46f.out")"
  if [ "$LF_RC|$t|$r|$(_lnp_before "$LNPD/i46f.out")" = "0|$LNPIU|$LNPIU|backup settings" ]; then LNPb="$LF_FIRE|one unknown line"
  elif [ "$LF_SELF" = self ] && [ -z "$(_lnp_lanes "$LNPD/i46f.out")" ]; then
    case "$2:$LF_RC" in (kill:137|fork:128) LNPb="$LF_FIRE|one unknown line" ;; esac
  fi
}
LNPa5='felix pulse exits 0, and after its backup and settings lines its lane lines, last, are exactly the one line lane - unknown - -, in its output and its record'
_lnp_i46f felix fork tr "*' -d [:space:] '*"
is "I46-21 lane pulse, in a home its .felix alone binds, with C9's fork probe at the read of the marker inside felix_resolve_project (tr -d [:space:]): $LNPa5 (or 128 with no lane line, where the fork failed in felix's own shell); the probe fired, and unfaulted the pulse ends with lane cap zero 0 2 and lane sec short 1 3" \
   "$LNPa|$LNPb" "built|built|unfaulted 0|$LNPIW|fired|one unknown line"
_lnp_i46f felix kill tr "*' -d [:space:] '*"
is "I46-22 lane pulse, in a home its .felix alone binds, with C9's kill probe at the read of the marker inside felix_resolve_project (tr -d [:space:]): $LNPa5 (or 137 with no lane line, where the kill reached felix itself); the probe fired, and unfaulted the pulse ends with lane cap zero 0 2 and lane sec short 1 3" \
   "$LNPa|$LNPb" "built|built|unfaulted 0|$LNPIW|fired|one unknown line"
_lnp_i46f remote fork git "*' remote get-url origin '*"
is "I46-23 lane pulse, in a home remote_match alone binds, with C9's fork probe at git remote get-url origin inside felix_resolve_project: $LNPa5 (or 128 with no lane line, where the fork failed in felix's own shell); the probe fired, and unfaulted the pulse ends with lane cap zero 0 2 and lane sec short 1 3" \
   "$LNPa|$LNPb" "built|built|unfaulted 0|$LNPIW|fired|one unknown line"
_lnp_i46f remote kill git "*' remote get-url origin '*"
is "I46-24 lane pulse, in a home remote_match alone binds, with C9's kill probe at git remote get-url origin inside felix_resolve_project: $LNPa5 (or 137 with no lane line, where the kill reached felix itself); the probe fired, and unfaulted the pulse ends with lane cap zero 0 2 and lane sec short 1 3" \
   "$LNPa|$LNPb" "built|built|unfaulted 0|$LNPIW|fired|one unknown line"

# MISS BIND -> the home in BIND and felix pulse there, then in MISS and felix pulse there. LNPa what was built and BIND's
# lane lines, LNPb MISS's status, whether it printed its backup and settings lines, and its and its record's lane lines.
_lnp_i46m() {
  _lf_bind "$LNPIH" "$LNPIH" p "$2"; LNPa="$LNPIA|$2 $LF_BOUND"
  _lnp_pulse "$LNPD/i46b"; LNPa="$LNPa|$LF_RC|$(_lnp_tail "$LNPD/i46b.out")"
  _lf_bind "$LNPIH" "$LNPIH" p "$1"; LNPa="$LNPa|$1 $LF_BOUND"
  _lnp_pulse "$LNPD/i46m"
  LNPb="$LF_RC|$(LC_ALL=C awk -F'\t' '$1 == "backup" { b = 1 } $1 == "settings" { s = 1 } END { printf "%s %s", (b ? "backup" : "no-backup"), (s ? "settings" : "no-settings") }' "$LNPD/i46m.out")"
  LNPb="$LNPb|lane lines [$(_lnp_lanes "$LNPD/i46m.out")]|record [$(_lnp_lanes "$LNPIH/state/pulse.status.tsv")]"
}
LNPa5='felix pulse exits 0 with its backup and settings lines and no lane line, in its output or its record'
_lnp_i46m none felix
is "I46-25 lane pulse, a miss that stands: in a home with no .felix and no origin remote, $LNPa5; with its .felix naming p the pulse ends with its two lane lines" \
   "$LNPa|$LNPb" "built|felix built|0|$LNPIW|none built|0|backup settings|lane lines []|record []"
_lnp_i46m other remote
is "I46-26 lane pulse, a miss that stands: in a home whose origin no project's remote_match names, $LNPa5; with an origin p's remote_match names the pulse ends with its two lane lines" \
   "$LNPa|$LNPb" "built|remote built|0|$LNPIW|other built|0|backup settings|lane lines []|record []"
_lnp_i46m tie remote
is "I46-27 lane pulse, a miss that stands: in a home whose origin two projects' remote_match name equally, a tie, $LNPa5; with p's alone naming it the pulse ends with its two lane lines" \
   "$LNPa|$LNPb" "built|remote built|0|$LNPIW|tie built|0|backup settings|lane lines []|record []"
_lnp_i46m nosuch felix
is "I46-28 lane pulse, a miss that stands: in a home whose .felix names no project, $LNPa5; with its .felix naming p the pulse ends with its two lane lines" \
   "$LNPa|$LNPb" "built|felix built|0|$LNPIW|nosuch built|0|backup settings|lane lines []|record []"
_lnp_i46m empty felix
is "I46-29 lane pulse, a miss that stands: in a home whose .felix is empty, $LNPa5; with its .felix naming p the pulse ends with its two lane lines" \
   "$LNPa|$LNPb" "built|felix built|0|$LNPIW|empty built|0|backup settings|lane lines []|record []"
LNPa6="I46-30 lane pulse, a miss that stands: in a home whose .felix exists and cannot be opened (mode 000), $LNPa5; with its .felix naming p the pulse ends with its two lane lines"
if [ "$(id -u)" = 0 ]; then skip "$LNPa6" "the suite runs as root, which opens a .felix of mode 000"
else
  _lnp_i46m closed felix
  is "$LNPa6" "$LNPa|$LNPb" "built|felix built|0|$LNPIW|closed built|0|backup settings|lane lines []|record []"
fi
_lf_bind "$LNPIH" "$LNPIH" p felix
_lf_use "$LNPH" "$LNPD/memory" "$LNPD/user" "$LNPB"

# ---- the third review's round 1: the lane's own check of the home's resolution (V3R1-F1, V3R1-F2) -----------------------
# Added on 2026-10-30 from the third review's round 1 findings (their inputs and observed output only) and C2 as 777e6c2d
# amended it, still blind, last. Readings:
# - V3R1-F1: item 46's home bound by remote_match alone (_lf_bind remote), with C9's fork probe (_lf_probe) at every sed
#   whose words hold remote_match, whatever calls it: the resolver's read and the check's own (a sed of its own, C2) both
#   fail, so the resolution of the home's project did not finish (C8): felix pulse exits 0 and, after its backup and
#   settings lines, its lane lines, last, are exactly lane - unknown - -, in its output and its record; or it ends with
#   128 and no lane line where the fork failed in felix's own shell. Never no lane line with exit 0.
# - V3R1-F2: _lf_two's self-governed home of two projects (self), which remote_match alone binds to z, whose
#   github.com/o/rr is longer than p's o/rr: unfaulted the pulse ends with lane zz zero 0 1. C9's fork and kill probes at
#   sed naming projects/z/project.json inside felix_resolve_project let the resolver bind p while the check binds z,
#   another project, so the resolution of the home's project did not finish (C2; design item 47): lane - unknown - - (or
#   128 or 137 with no lane line, where the probe reached felix itself); never p's lane cap zero 0 1, and never z's line
#   as without the fault (from the disputes on round 1: an engine that put its own binding in place of the resolver's
#   would print it).
# HOME STACK MODE NAME WORDS -> felix pulse in HOME under _lf_probe MODE NAME WORDS STACK with a fresh TMPDIR. LNPb the
# probe's LF_FIRE and "as C8 says" when the run ended as the readings say, else its status, lane lines, record and what
# came before them.
_lnp_v3() {
  local t r b
  rm -rf "$LNPIT"; mkdir -p "$LNPIT"
  _lf_probe "$3" "$4" "$5" "$2" "$LNPD/v3f.fired" "$LNPIT" _lf_run "$LNPD/v3f" "$1" "$LNPN" "$FELIX" pulse
  _lf_calm "$1"
  t="$(_lnp_tail "$LNPD/v3f.out")"; r="$(_lnp_tail "$1/state/pulse.status.tsv")"; b="$(_lnp_before "$LNPD/v3f.out")"
  LNPb="$LF_FIRE|status $LF_RC, lane lines [$t], record [$r], $b"
  case "$LF_RC|$t|$r|$b" in
    ("0|$LNPIU|$LNPIU|backup settings") LNPb="$LF_FIRE|as C8 says" ;;
    (*) if [ "$LF_SELF" = self ] && [ -z "$(_lnp_lanes "$LNPD/v3f.out")" ]; then
          case "$3:$LF_RC" in (kill:137|fork:128) LNPb="$LF_FIRE|as C8 says" ;; esac
        fi ;;
  esac
}
_lf_use "$LNPIH" "$LNPD/i46-memory" "$LNPD/i46-user" "$LNPB"
_lf_bind "$LNPIH" "$LNPIH" p remote; LNPa="$LNPIA|$LF_BOUND"
_lnp_pulse "$LNPD/v3-0"; LNPa="$LNPa|unfaulted $LF_RC|$(_lnp_tail "$LNPD/v3-0.out")"
_lnp_v3 "$LNPIH" '*' fork sed '*remote_match*'
is "lane pulse V3R1-F1-remote-match-read-fault-reads-ungoverned L-NEVER-OK: in a home remote_match alone binds, C9's fork probe at every sed whose words hold remote_match, the resolver's read and the lane check's own: felix pulse exits 0, and after its backup and settings lines its lane lines, last, are exactly the one line lane - unknown - -, in its output and its record (or 128 with no lane line, where the fork failed in felix's own shell); never exit 0 with no lane line; the probe fired, and unfaulted the pulse ends with lane cap zero 0 2 and lane sec short 1 3" \
   "$LNPa|$LNPb" "built|built|unfaulted 0|$LNPIW|fired|as C8 says"
_lf_bind "$LNPIH" "$LNPIH" p felix

LNPVA="not built: V3R1-F2's home"; LNPVH="$LNPD/v3f2/home"
_lf_two "$LNPD/v3f2" self "$LNPN" && LNPVA=built
_lf_use "$LNPVH" "$LNPD/v3f2-memory" "$LNPD/v3f2-user" "$LNPB"
LNPVZ="$(_lf_tsv lane zz zero 0 1)"
_lnp_pulse "$LNPD/v3f2-0"; LNPa="$LNPVA|unfaulted $LF_RC|$(_lnp_tail "$LNPD/v3f2-0.out")|$(_lnp_before "$LNPD/v3f2-0.out")"
LNPa6='felix pulse exits 0, and after its backup and settings lines its lane lines, last, are exactly the one line lane - unknown - -, in its output and its record, since the check binds z where the resolver found p (C2, C8)'
_lnp_v3 "$LNPVH" "*' felix_resolve_project '*" fork sed '*projects/z/project.json*'
is "lane pulse V3R1-F2-shorter-remote-match-binds L-NEVER-OK: in a self-governed home whose origin two projects' remote_match name, z's github.com/o/rr the longer, so the pulse ends with lane zz zero 0 1, C9's fork probe at sed naming projects/z/project.json inside felix_resolve_project, where the resolver can bind p's shorter o/rr: $LNPa6 (or 128 with no lane line, where the fork failed in felix's own shell); never p's lane cap zero 0 1, nor z's line as without the fault; the probe fired" \
   "$LNPa|$LNPb" "built|unfaulted 0|$LNPVZ|backup settings|fired|as C8 says"
_lnp_v3 "$LNPVH" "*' felix_resolve_project '*" kill sed '*projects/z/project.json*'
is "lane pulse V3R1-F2-shorter-remote-match-binds L-NEVER-OK: the same home, C9's kill probe at sed naming projects/z/project.json inside felix_resolve_project: $LNPa6 (or 137 with no lane line, where the kill reached felix itself); never p's lane cap zero 0 1, nor z's line as without the fault; the probe fired" \
   "$LNPa|$LNPb" "built|unfaulted 0|$LNPVZ|backup settings|fired|as C8 says"
_lf_use "$LNPH" "$LNPD/memory" "$LNPD/user" "$LNPB"
# <<< lane-pulse
