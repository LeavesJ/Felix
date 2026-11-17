# ------------------------------------- obligations name what discharges them ---
# Roadmap Phase 1, first item. An optional eighth column, `needs`, names the
# checker ids in qualification.tsv that would discharge a row, and each
# resolves as complete (a row for every control), short (declared, some
# missing, named) or absent (no checker by that id). Report only. So the
# controls here hold on the engine before the column existed as much as after
# it: a seven-column row is still a row, and discharge and blocking do not
# move whatever a need resolves to. Fresh fixture dirs, as for the asks above.
printf '\nobligations: what would discharge each, by name\n'
NDP="$TMP/needs-proj"; NDR="$TMP/needs-repo"; mkdir -p "$NDP" "$NDR" "$MEM/needs-proj"
( _fx_cd "$NDR" && git init -q -b main && printf 'x\n' > x && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm x ) >/dev/null 2>&1
NDR="$(cd "$NDR" && pwd -P)"
printf 'thing\t-\t-\tls -1 x\ttest -f x\n' > "$NDP/probes.tsv"
# One checker with a row for every control, one with a violation only, and one
# whose only row is malformed. Nothing here runs them: resolution reads what
# the table declares and qualifies nothing.
: > "$NDP/qualification.tsv"
for _c in violation:fail restoration:pass irrelevant:pass alternate:fail \
          decoupled_violation:fail decoupled_satisfaction:pass; do
  printf 'whole\ttrue\t%s\t%s\ttrue\n' "${_c%%:*}" "${_c##*:}" >> "$NDP/qualification.tsv"
done
printf 'part\ttrue\tviolation\tfail\ttrue\n'   >> "$NDP/qualification.tsv"
printf 'broken\ttrue\tviolation\tpass\ttrue\n' >> "$NDP/qualification.tsv"
_nd()      { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"
               . "$FROOT/harness/lib/obligations.sh"; "$@" ) 2>/dev/null; }
_ndrun()   { _nd felix_obligations_run "$NDP" "$NDR"; }
_ndneeds() { _nd felix_obligations_needs "$NDP"; }
_ndblk()   { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
               . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/evidence.sh"
               . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/probes.sh"
               . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"
               felix_merge_blockers "$NDP" "" "$NDR" "$FROOT" ) 2>/dev/null | grep '^obligations'; }
_ndrow()   {   # evidence [needs]
  if [ $# -ge 2 ]; then printf 'a\tRELEASE_BLOCKING\tdeterministic\t-\t%s\tthing\towed\t%s\n' "$1" "$2"
  else                  printf 'a\tRELEASE_BLOCKING\tdeterministic\t-\t%s\tthing\towed\n' "$1"; fi > "$NDP/obligations.tsv"; }
_ndtc()    { ( . "$FROOT/harness/lib/table.sh" 2>/dev/null
               felix_table_check "$FROOT/harness/templates/schemas.tsv" "$NDP/obligations.tsv" >/dev/null 2>&1; echo $? ); }

# Controls: the seven-column row, and discharge, exactly as before.
_ndrow true
is  "needs: a seven-column row is still a row"                  "$(_nd felix_obligation_rows "$NDP" | grep -c .)" "1"
is  "and nothing about it is refused"                           "$(_nd felix_obligation_malformed "$NDP")" ""
is  "and the schema check accepts it"                           "$(_ndtc)" "0"
_nd7="$(_ndrun)"
is  "and it is evaluated on its axes as before"                 "$(printf '%s\n' "$_nd7" | cut -f4,5)" "ACTIVE	SATISFIED"
is  "a seven-column row names nothing that would discharge it"  "$(_ndneeds)" "a	-	none	-"
_ndrow true gone
is  "an eighth column of well-formed ids is not refused"        "$(_nd felix_obligation_malformed "$NDP")" ""
is  "and discharge does not move: the row reads as it did without one" "$(_ndrun)" "$_nd7"
is  "the schema check accepts the eighth column as needs"       "$(_ndtc)" "0"
_ndrow false gone
has "a failing row that names an absent capability blocks a release as before" \
    "$(_ndblk)" "obligations	a	ACTIVE UNSATISFIED"
_ndrow false whole
has "and one whose checker declares every control blocks all the same" \
    "$(_ndblk)" "obligations	a	ACTIVE UNSATISFIED"
is  "complete is not discharge: the row is still UNSATISFIED"   "$(_ndrun | cut -f5)" "UNSATISFIED"
_ndrow true ''
is  "an empty needs cell is not refused by the scan"            "$(_nd felix_obligation_malformed "$NDP")" ""
is  "and reads as naming nothing"                               "$(_ndneeds)" "a	-	none	-"

# Resolution, against what qualification.tsv declares.
_ndrow true -
is  "a dash names nothing"                                      "$(_ndneeds)" "a	-	none	-"
_ndrow true whole
is  "a checker with a row for every control resolves complete"  "$(_ndneeds)" "a	whole	complete	-"
_ndrow true part
is  "a checker short of controls resolves short, naming what it lacks" \
    "$(_ndneeds)" "a	part	short	restoration,irrelevant,alternate,decoupled_violation,decoupled_satisfaction"
_ndrow true gone
is  "an id no checker carries resolves absent"                  "$(_ndneeds)" "a	gone	absent	-"
_ndrow true broken
is  "a checker whose only row is malformed is short, not absent" "$(_ndneeds | cut -f3)" "short"
_ndrow true 'whole,part,gone'
is  "a row needing three capabilities resolves each of them" \
    "$(_ndneeds | cut -f2,3 | tr '\n' ' ')" "whole	complete part	short gone	absent "
{ printf 'a\tINFO\tdeterministic\t-\ttrue\t-\tr\twhole\n'
  printf 'b\tINFO\tdeterministic\t-\ttrue\t-\tr\twhole,gone\n'
  printf 'c\tINFO\tdeterministic\t-\ttrue\t-\tr\tpart\n'
  printf 'd\tINFO\tdeterministic\t-\ttrue\t-\tr\n'
  printf 'e\tINFO\tdeterministic\t-\ttrue\t-\tr\t-\n'; } > "$NDP/obligations.tsv"
is  "the count is one per obligation, by its weakest need" \
    "$(_ndneeds | _nd felix_obligations_needs_count)" "3	1	1	1	2"
# A copy of the engine without the qualification library cannot resolve, and
# says nothing and fails rather than calling every checker absent.
NDNL="$TMP/lib-without-qualify"; mkdir -p "$NDNL"
for _l in resolve probes obligations exceptions; do cp "$FROOT/harness/lib/$_l.sh" "$NDNL/" 2>/dev/null; done
is  "an engine shipped without the qualification library resolves nothing, rather than absent" \
    "$( ( . "$NDNL/resolve.sh"; . "$NDNL/probes.sh"; . "$NDNL/obligations.sh"
          felix_obligations_needs "$NDP"; printf 'rc=%s' "$?" ) 2>/dev/null )" "rc=1"

# The count above failed once in a full gate on a loaded Mac: 3 0 2 1 2, row a
# resolved short against a checker declaring all six. Membership was printf of
# the declared list into grep -qxF, and grep -q leaves on its first match; a
# printf still writing is killed by SIGPIPE, and under pipefail, which this
# suite and the felix CLI both set, `||` then names a control the checker
# declares. A list longer than a pipe holds makes the race certain, because the
# writer has to block: twenty thousand violation rows first, then one row for
# each other control. One awk writes them; a loop here would cost minutes.
NDB="$TMP/needs-big"; mkdir -p "$NDB"
awk 'BEGIN { for (i = 0; i < 20000; i++) print "big\ttrue\tviolation\tfail\ttrue"
             n = split("restoration:pass irrelevant:pass alternate:fail decoupled_violation:fail decoupled_satisfaction:pass", c, " ")
             for (i = 1; i <= n; i++) { split(c[i], kv, ":"); print "big\ttrue\t" kv[1] "\t" kv[2] "\ttrue" } }' \
  > "$NDB/qualification.tsv"
printf 'a\tINFO\tdeterministic\t-\ttrue\t-\tr\tbig\n' > "$NDB/obligations.tsv"
is  "a checker declaring every control resolves complete however many rows precede its last" \
    "$(_nd felix_obligations_needs "$NDB")" "a	big	complete	-"

# A table that exists and cannot be read is said, not resolved. awk's "can't
# open file" went to a stderr every caller discards and its status was never
# read, so the declared list came back empty and every capability read absent:
# a claim about a table nobody read. root reads a file whose mode is 000, and
# then no table here can be made unreadable; those assertions skip, not pass.
_qualify_unreadable_probe
NDU="$TMP/needs-unreadable"; mkdir -p "$NDU"
cp "$NDP/qualification.tsv" "$NDU/qualification.tsv"
# A row naming nothing first, which needs no read of the table to report: a
# resolution that stops part way must not leave it behind as a partial report.
{ printf 'n\tINFO\tdeterministic\t-\ttrue\t-\tr\t-\n'
  printf 'a\tINFO\tdeterministic\t-\ttrue\t-\tr\tpart,whole\n'; } > "$NDU/obligations.tsv"
_ndu() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"
           . "$FROOT/harness/lib/obligations.sh"
           felix_obligations_needs "$NDU"; printf 'rc=%s' "$?" ) 2>"$TMP/ndu.err"; }
if [ "$_unreadable" -eq 1 ]; then
  chmod 000 "$NDU/qualification.tsv"
  is  "needs over a table that cannot be read resolves nothing, not every capability absent, and exits 2" \
      "$(_ndu)" "rc=2"
  has "and needs says on stderr which table could not be read" \
      "$(grep 'could not be read' "$TMP/ndu.err")" "$NDU/qualification.tsv"
  is  "and that is the one line needs writes there"        "$(grep -c . "$TMP/ndu.err")" "1"
  is  "and needs says so without the caller's pipefail"    "$(set +o pipefail; _ndu)" "rc=2"
  chmod 644 "$NDU/qualification.tsv"
else
  for a in "needs over a table that cannot be read resolves nothing, not every capability absent, and exits 2" \
           "and needs says on stderr which table could not be read" \
           "and that is the one line needs writes there" \
           "and needs says so without the caller's pipefail"; do skip "$a" "$_noread"; done
fi
# No table at all is still an answer: nothing is declared, so everything named
# is absent, and that is what a project without qualification looks like.
NDN="$TMP/needs-no-table"; mkdir -p "$NDN"
cp "$NDU/obligations.tsv" "$NDN/obligations.tsv"
is  "with no qualification.tsv at all, every capability named resolves absent, and exits 0" \
    "$( ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"
          . "$FROOT/harness/lib/obligations.sh"
          felix_obligations_needs "$NDN"; printf 'rc=%s' "$?" ) 2>/dev/null )" \
    "$(printf 'n\t-\tnone\t-\na\tpart\tabsent\t-\na\twhole\tabsent\t-\nrc=0')"

# A table holding a NUL byte. macOS awk keeps each record as a C string, so a
# NUL ends the line there for everything awk does with it, and the table is
# read through awk: a row starting with one read as a blank line and was
# skipped, never run and never called malformed, and one later in a row cut the
# row there, dropping its premise or running a shorter mutation. git calls a
# file with a NUL in its first 8000 bytes binary, so a reviewer saw no row of
# it, and mawk and gawk keep the NUL, so the same table read otherwise on Linux.
# A table holding one anywhere is not read as a table, by anything here.
#
# _qznul, _qzsaid, _qzwhere and _qzmark: tests/lib/qualify-needs.sh.
# The fixture first: one NUL in each table, its twin the same bytes without it,
# and git calling each binary but the one whose NUL is past byte 8000, which
# is the case a reviewer reading a diff would be shown.
NDZ="$TMP/needs-nul"; mkdir -p "$NDZ"
_qzfix() {
  local w g
  for w in $_qzwhere; do
    _qznul "$w" > "$NDZ/fix.nul"; _qznul "$w" clean > "$NDZ/fix.clean"
    LC_ALL=C tr -d '\000' < "$NDZ/fix.nul" > "$NDZ/fix.stripped"
    g="$(git diff --no-index --numstat /dev/null "$NDZ/fix.nul" 2>/dev/null | cut -f1)"
    printf '%s:%s:%s:%s ' "$w" "$(LC_ALL=C tr -cd '\000' < "$NDZ/fix.nul" | wc -c | tr -d ' ')" \
      "$(cmp -s "$NDZ/fix.clean" "$NDZ/fix.stripped" && echo twin || echo other)" \
      "$([ "$g" = - ] && echo binary || echo text)"
  done
  rm -f "$NDZ/fix.nul" "$NDZ/fix.clean" "$NDZ/fix.stripped"
}
is  "each NUL table holds one NUL, its twin is the same bytes without it, and git calls it binary unless the NUL is past byte 8000" \
    "$(_qzfix)" "start:1:twin:binary row:1:twin:binary field:1:twin:binary alone:1:twin:binary comment:1:twin:binary far:1:twin:text "
# needs over such a table resolves nothing, as over one it cannot read: the
# declared list read from it is a list of what awk saw.
{ printf 'n\tINFO\tdeterministic\t-\ttrue\t-\tr\t-\n'
  printf 'a\tINFO\tdeterministic\t-\ttrue\t-\tr\tdemo,held\n'; } > "$NDZ/obligations.tsv"
_ndz() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"
           . "$FROOT/harness/lib/obligations.sh"
           felix_obligations_needs "$NDZ"; printf 'rc=%s' "$?" ) 2>"$TMP/ndz.err"; }
_ndzsays() {
  local w out
  for w in $_qzwhere; do
    _qznul "$w" > "$NDZ/qualification.tsv"
    out="$(_ndz)"
    [ "$out" = rc=2 ] || printf '%s: printed [%s]\n' "$w" "$(printf '%s' "$out" | tr '\n\t' '/ ')"
    { [ "$(grep -c . "$TMP/ndz.err")" = 1 ] \
        && [ "$(grep -F "$NDZ/qualification.tsv" "$TMP/ndz.err" | grep -c 'NUL')" = 1 ]; } \
      || printf '%s: stderr [%s]\n' "$w" "$(tr '\n' '/' < "$TMP/ndz.err")"
  done
}
is  "needs over a table holding a NUL byte anywhere resolves nothing, exits 2, and says in one stderr line naming the table that it holds a NUL" \
    "$(_ndzsays)" ""
is  "and needs refuses such a table without the caller's pipefail too" "$(set +o pipefail; _ndzsays)" ""
_ndztwin() {
  local w
  for w in $_qzwhere; do
    _qznul "$w" clean > "$NDZ/qualification.tsv"
    printf '%s:%s ' "$w" "$(_ndz | awk -F'\t' 'NF >= 3 { printf "%s/%s ", $2, $3 } /^rc=/ { print }')"
  done
}
is  "and needs over each twin, its NUL taken out, resolves as before and exits 0" "$(_ndztwin)" \
    "start:-/none demo/short held/short rc=0 row:-/none demo/short held/short rc=0 field:-/none demo/short held/short rc=0 alone:-/none demo/short held/absent rc=0 comment:-/none demo/short held/absent rc=0 far:-/none demo/short held/short rc=0 "

# The reader shim, _qreads, _qfailat, _qstage and _qeach: tests/lib/qualify-needs.sh.
_qualify_shim_build
if [ "$_unreadable" -eq 1 ]; then
  if _qstage 0 _nd felix_obligations_needs "$NDU"; then
    is  "needs whose last read of one checker's controls fails prints nothing and exits 2" "$_qsrc:$_qsout" "2:"
  else bad "needs whose last read of one checker's controls fails prints nothing and exits 2" "$_qsnone"; fi
  if _qstage 1 _nd felix_obligations_needs "$NDU"; then
    is  "and the same when the read that fails is an earlier one, with a later one read" "$_qsrc:$_qsout" "2:"
  else bad "and the same when the read that fails is an earlier one, with a later one read" "$_qsnone"; fi
else
  for a in "needs whose last read of one checker's controls fails prints nothing and exits 2" \
           "and the same when the read that fails is an earlier one, with a later one read"; do
    skip "$a" "$_noread"; done
fi
# And every read, not only the last two: the list of declared checkers and the
# malformed rows are read first, and a status dropped on either still resolved
# and exited 0. With the caller's pipefail and without it, because a status that
# reaches the caller only through a pipeline is lost without. The stderr line
# is needs' own, and one: a checker's read that let the qualification
# library's line through as well would say it twice.
_ndv()   { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"
             . "$FROOT/harness/lib/obligations.sh"; felix_obligations_needs "$NDU" ); }
_ndvnp() { ( set +o pipefail; _ndv ); }
_ndvsays() {
  [ "$_qsrc:$_qsout" = "2:" ] \
    || printf 'exit %s with [%s] on stdout; ' "$_qsrc" "$(printf '%s' "$_qsout" | tr '\n\t' '/ ')"
  { [ "$(grep -c . "$_QSE")" = 1 ] && grep -qF "$NDU/qualification.tsv could not be read" "$_QSE"; } \
    || printf 'stderr [%s]' "$(tr '\n' '/' < "$_QSE")"
}
if [ "$_unreadable" -eq 1 ]; then
  is  "whichever read of the table fails, needs prints nothing, exits 2, and says so in one stderr line naming it" \
      "$(_qeach 1 _ndvsays _ndv)" ""
  is  "and so without the caller's pipefail" "$(_qeach 1 _ndvsays _ndvnp)" ""
else
  for a in "whichever read of the table fails, needs prints nothing, exits 2, and says so in one stderr line naming it" \
           "and so without the caller's pipefail"; do skip "$a" "$_noread"; done
fi

# A cell that is not an id refuses the row, as every other malformed cell does.
for _b in Deploy 'a,,b' 'x, y' 9lives 'ok,'; do
  _ndrow true "$_b"
  has "needs [$_b] refuses the row with the reason" "$(_nd felix_obligation_malformed "$NDP")" "needs '$_b'"
done
_ndrow true Deploy
is  "a row refused for its needs is never evaluated"            "$(_ndrun)" ""
has "and is refused at the merge boundary"                      "$(_ndblk)" "needs 'Deploy'"

# The CLI, on the bound fixture: a need nobody declares and a row naming none.
WNP="$FROOT/projects/widget"
cp "$WNP/obligations.tsv" "$TMP/needs-w-oblig.keep"
{ printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds\tgone\n'
  printf 'second\tADVISORY\tdeterministic\t-\ttrue\t-\tand one that names nothing\n'; } > "$WNP/obligations.tsv"
_ndcount="1 name what discharges them: 0 complete, 0 short, 1 absent; 1 name nothing"
out="$(cd "$REPO" && "$FELIX" obligations 2>&1)"; rc=$?
is  "felix obligations exits 0 with a need nobody declares"     "$rc" "0"
has "and shows each row's need with its resolution"             "$(printf '%s\n' "$out" | grep ' gone ')" "absent"
has "and the row that names nothing, saying so"                 "$out" "names nothing that would discharge it"
has "and says complete is declared, not run"                    "$out" "DECLARED, not that one ran"
has "and the summary line counts them"                          "$(printf '%s\n' "$out" | grep 'obligation(s):')" "$_ndcount"
out="$(cd "$REPO" && "$FELIX" obligations --gate 2>&1)"; rc=$?
is  "felix obligations --gate exits 0 whatever the needs resolve to" "$rc" "0"
has "and its summary line carries the same count"               "$(printf '%s\n' "$out" | grep 'obligation(s):')" "$_ndcount"
case "$out" in
  *"what would discharge each"*) bad "and the gate's copy carries no needs table" "$out" ;;
  *)                             ok  "and the gate's copy carries no needs table" ;;
esac
out="$(cd "$REPO" && "$FELIX" gate 2>&1)"
has "the gate's obligations check stays ok with every need absent" "$out" "  obligations        ok"
has "and prints the count under it" \
    "$(printf '%s\n' "$out" | awk '/^  obligations  / { getline; print; exit }')" "$_ndcount"
# And over a table that cannot be read. The needs report is report only and
# moves no verdict, so the exit is what it would have been had it resolved; the
# table of what would discharge each is left off, and the summary line says
# what could not be read where the count was, since a count of what nobody read
# would read as one. Not run through felix gate here: a red qualified check
# would write this checkout's mistakes.log, which later blocks read, and the
# gate prints this same summary line.
_ndsays="; what would discharge them could not be read"
if [ "$_unreadable" -eq 1 ]; then
  cp "$WNP/qualification.tsv" "$TMP/needs-w-qual.keep" 2>/dev/null || true
  cp "$NDP/qualification.tsv" "$WNP/qualification.tsv"
  ( cd "$REPO" && "$FELIX" obligations >/dev/null 2>&1 );        _ndrc=$?
  ( cd "$REPO" && "$FELIX" obligations --gate >/dev/null 2>&1 ); _ndrcg=$?
  chmod 000 "$WNP/qualification.tsv"
  out="$(cd "$REPO" && "$FELIX" obligations 2>&1)"; rc=$?
  outg="$(cd "$REPO" && "$FELIX" obligations --gate 2>&1)"; rcg=$?
  chmod 644 "$WNP/qualification.tsv"
  is  "felix obligations over a table it cannot read exits as it does over one it can" "$rc" "$_ndrc"
  case "$out" in
    *"what would discharge each"*) bad "and leaves off the table of what would discharge each" "$out" ;;
    *)                             ok  "and leaves off the table of what would discharge each" ;;
  esac
  _ndsum="$(printf '%s\n' "$out" | grep 'obligation(s):')"
  case "$_ndsum" in
    *"$_ndsays") ok  "and its summary line ends saying what would discharge them could not be read" ;;
    *)           bad "and its summary line ends saying what would discharge them could not be read" "$_ndsum" ;;
  esac
  case "$_ndsum" in
    *"name what discharges them"*) bad "and counts nothing it could not read" "$_ndsum" ;;
    *)                             ok  "and counts nothing it could not read" ;;
  esac
  is  "felix obligations --gate over a table it cannot read exits as it does over one it can" "$rcg" "$_ndrcg"
  _ndsum="$(printf '%s\n' "$outg" | grep 'obligation(s):')"
  case "$_ndsum" in
    *"$_ndsays") ok  "and the gate's summary line ends saying what would discharge them could not be read" ;;
    *)           bad "and the gate's summary line ends saying what would discharge them could not be read" "$_ndsum" ;;
  esac
  case "$_ndsum" in
    *"name what discharges them"*) bad "and the gate's summary counts nothing it could not read" "$_ndsum" ;;
    *)                             ok  "and the gate's summary counts nothing it could not read" ;;
  esac
  rm -f "$WNP/qualification.tsv"
  [ -f "$TMP/needs-w-qual.keep" ] && mv "$TMP/needs-w-qual.keep" "$WNP/qualification.tsv"
else
  for a in "felix obligations over a table it cannot read exits as it does over one it can" \
           "and leaves off the table of what would discharge each" \
           "and its summary line ends saying what would discharge them could not be read" \
           "and counts nothing it could not read" \
           "felix obligations --gate over a table it cannot read exits as it does over one it can" \
           "and the gate's summary line ends saying what would discharge them could not be read" \
           "and the gate's summary counts nothing it could not read"; do skip "$a" "$_noread"; done
fi
cp "$TMP/needs-w-oblig.keep" "$WNP/obligations.tsv"

# Felix's own ledger names what would discharge its two rows. Neither has a
# checker in qualification.tsv yet, and absent is the honest reading.
_REALP="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix"
if [ -f "$_REALP/obligations.tsv" ]; then
  _ndf="$(_nd felix_obligations_needs "$_REALP")"
  is  "felix's lifecycle_wired needs lifecycle, which no checker declares" \
      "$(printf '%s\n' "$_ndf" | awk -F'\t' '$1 == "lifecycle_wired" { print $2 "\t" $3 }')" "lifecycle	absent"
  is  "and engine_deployed needs deploy, absent the same way" \
      "$(printf '%s\n' "$_ndf" | awk -F'\t' '$1 == "engine_deployed" { print $2 "\t" $3 }')" "deploy	absent"
else
  for a in "felix's lifecycle_wired needs lifecycle, which no checker declares" \
           "and engine_deployed needs deploy, absent the same way"; do
    skip "$a" "no projects/felix/obligations.tsv beside this harness"; done
fi
has "the template documents the needs column" \
    "$(grep '^# obligation' "$FROOT/harness/templates/obligations.tsv")" "reason	needs"

