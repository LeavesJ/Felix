_mislog_vars
_cmstub_build
_probes_build end
out="$(cd "$BARE" && "$FELIX" probes 2>&1)"; rc=$?
is  "felix probes refuses a project that asks reality nothing" "$rc" "1"
has "and says what is missing rather than printing a clean report" \
    "$out" "read from reality"
out="$(cd "$BARE" && "$FELIX" probes --gate 2>&1)"; rc=$?
is  "and refuses in gate mode as well" "$rc" "1"

# A table that exists and holds only comments is the same fact wearing a file.
printf '# nothing yet\n' > "$FROOT/projects/bare/probes.tsv"
out="$(cd "$BARE" && "$FELIX" probes 2>&1)"; rc=$?
is  "a probes.tsv holding no rows is refused too" "$rc" "1"
has "and is named as a shelf with nothing on it"  "$out" "declares no probe"

# Two: the merge boundary, the strongest refusal Felix reaches offline.
_pbblockers() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
                  . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/evidence.sh"
                  . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"
                  felix_merge_blockers "$1" "" "$2" "$FROOT" ) 2>/dev/null; }
has "a merge is blocked while the project reads nothing from reality" \
    "$(_pbblockers "$PBE" "$PBR")" "probes"
has "and blocked by a probe that cannot see what a witness proves is there" \
    "$(_pbblockers "$PBP" "$PBR")" "pyfile"
has "and blocked by a row nothing could establish at all" \
    "$(_pbblockers "$PBP" "$PBR")" "nowitness"

# Fails closed rather than skipping. The `reviewed` lookup in the same function
# guards itself with command -v because what it does is WIDEN, and skipping it
# withholds a clearance. Skipping this would drop a blocker: an engine that
# cannot evaluate probes has not established there is nothing to block on.
PBNL="$TMP/lib-without-probes"; mkdir -p "$PBNL"
for _l in resolve detect verify evidence escape review; do
  cp "$FROOT/harness/lib/$_l.sh" "$PBNL/$_l.sh" 2>/dev/null
done
_pbnolib() { ( . "$PBNL/resolve.sh"; . "$PBNL/detect.sh"
               . "$PBNL/verify.sh"; . "$PBNL/evidence.sh"; . "$PBNL/escape.sh"
               felix_merge_blockers "$PBP" "" "$PBR" "$FROOT" ) 2>/dev/null; }
has "an engine shipped without the probe library blocks rather than passing" \
    "$(_pbnolib)" "probe library is not loaded"

# Three: the gate. The wiring, not only the exit status — the status is
# reachable from anywhere, and the call site is what actually runs in CI. This
# reaches out of the harness into Felix's own project directory, which the
# independence rule permits precisely here: `felix` is the one project the
# engine may name, because it is the product governing itself.
# Three: the gate — and the ENGINE's gate, not one project's script. For one
# night projects/felix/gate.sh carried this check alone, which made it an
# instance: every other project's gate would have had to copy it by hand, and
# none did. cmd_gate now runs it for every project that has a table, after the
# project's own gate and in its own line shape, so a probe failure lands in
# mistakes.log under its own name. The tolerance for an engine that predates
# the command is no longer needed inside the engine, and it is gone.
cp "$TMP/probes.keep" "$FROOT/projects/widget/probes.tsv"
out="$(cd "$REPO" && "$FELIX" gate 2>&1)"; rc=$?
has "felix gate runs the probes for a project with a table" "$out" "probes"
has "and reports them in the gate's own line shape"          "$out" "  probes             ok"
is  "and a clean table leaves the gate green"                 "$rc" "0"
# A blind row turns the gate red through the engine, with no project script
# involved, and the failure is recorded under its own name like any other.
{ printf 'present\t-\t-\tls -1 WIDGET.txt\ttest -f WIDGET.txt\n'
  printf 'blindrow\t-\t-\tls -1 nothing-here.rs\ttest -f WIDGET.txt\n'
} > "$FROOT/projects/widget/probes.tsv"
: > "$MISLOG"
out="$(cd "$REPO" && "$FELIX" gate 2>&1)"; rc=$?
has "a blind probe fails the gate from the engine"  "$out" "  probes             FAIL"
is  "and the gate exits red"                         "$rc" "1"
has "and the failure is recorded under the check's own name" \
    "$(cat "$MISLOG" 2>/dev/null)" "probes"
cp "$TMP/probes.keep" "$FROOT/projects/widget/probes.tsv"
# A project with NO table is skipped and says so. The instruction was every
# project WITH a table, and a skip that names itself is the rule this gate
# already holds for a missing scanner. felix probes and the merge boundary
# still refuse the absent table; the gate declines to be the third place that
# turns a new project red on day one.
rm -f "$FROOT/projects/widget/probes.tsv"
out="$(cd "$REPO" && "$FELIX" gate 2>&1)"; rc=$?
has "a project with no table is skipped, and the skip names itself" \
    "$out" "skipped (no probes.tsv"
is  "and that alone does not fail the gate"          "$rc" "0"
cp "$TMP/probes.keep" "$FROOT/projects/widget/probes.tsv"
# The gate that carried the check alone no longer does: one mechanism.
PBGATE="$REAL_HARNESS/../../projects/felix/gate.sh"
if [ -f "$PBGATE" ]; then
  case "$(cat "$PBGATE")" in
    *"probes --gate"*) bad "felix's own gate no longer carries a private copy of the check" \
                           "the block is still in projects/felix/gate.sh" ;;
    *)                 ok  "felix's own gate no longer carries a private copy of the check" ;;
  esac
else
  skip "felix's own gate no longer carries a private copy of the check" "no projects/felix/gate.sh beside this harness"
fi

# The table decides what stops, so shrinking it escapes to a person — the same
# contract risk.tsv, deny.tsv and evidence.tsv already sit under.
has "probes.tsv is one of the tables whose shrinkage escapes" \
    "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
        printf '%s' "$FELIX_ESCAPE_TABLES" )" "probes.tsv"

# ---------------------------------------------------------------------------
# obligations: the first admission rule. v3.2 §3's three axes, two of them
# derived on every run and never stored; the merge boundary refuses the empty
# ledger; a dormant row is reported and blocks nothing; unknown blocks; and
# shrinking the ledger escapes to a person.
_oblig_build

# The axes, derived.
printf 'a\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\tthing\tholds\n' > "$OBP/obligations.tsv"
is  "an always-applicable obligation whose evidence holds is ACTIVE SATISFIED" \
    "$(_obrun | cut -f4,5)" "ACTIVE	SATISFIED"
is  "and blocks nothing" "$(_obblk)" ""
printf 'a\tRELEASE_BLOCKING\tdeterministic\t-\tfalse\tthing\tfails\n' > "$OBP/obligations.tsv"
is  "one whose evidence fails is ACTIVE UNSATISFIED" "$(_obrun | cut -f4,5)" "ACTIVE	UNSATISFIED"
has "and blocks a release" "$(_obblk)" "obligations	a	ACTIVE UNSATISFIED"
printf 'a\tRELEASE_BLOCKING\tdeterministic\ttest -f nope\ttouch ran\tthing\tdormant\n' > "$OBP/obligations.tsv"
is  "an obligation the grounded state does not make applicable is DORMANT" "$(_obrun | cut -f4)" "DORMANT"
[ ! -f "$OBR/ran" ] && ok  "and its evidence is never run" \
                    || bad "and its evidence is never run" "the evidence ran on a dormant row"
is  "and a dormant row blocks nothing" "$(_obblk)" ""
printf 'a\tRELEASE_BLOCKING\tunknown\ttest -f nope\ttrue\tthing\thold\n' > "$OBP/obligations.tsv"
is  "even on the unknown pathway, which holds only while the row applies" "$(_obblk)" ""
printf 'a\tRELEASE_BLOCKING\tunknown\t-\ttrue\tthing\thold\n' > "$OBP/obligations.tsv"
has "an applicable unknown-pathway row holds even when its evidence passes" \
    "$(_obblk)" "obligations	a	ACTIVE SATISFIED"
printf 'a\tRELEASE_BLOCKING\tdeterministic\ttest -f flag\ttrue\tthing\tflips\n' > "$OBP/obligations.tsv"
is  "applicability follows the grounded state: absent, dormant" "$(_obrun | cut -f4)" "DORMANT"
: > "$OBR/flag"
is  "present, active — nothing was stored between the two" "$(_obrun | cut -f4)" "ACTIVE"

# Unknown is never clean.
printf 'a\tRELEASE_BLOCKING\tdeterministic\tno-such-command-xyz\ttrue\tthing\t?\n' > "$OBP/obligations.tsv"
is  "an applies command that does not exist here is UNKNOWN on both axes" \
    "$(_obrun | cut -f4,5)" "UNKNOWN	UNKNOWN"
has "and blocks" "$(_obblk)" "obligations	a	UNKNOWN UNKNOWN"
printf 'a\tRELEASE_BLOCKING\tdeterministic\t-\tno-such-command-xyz\tthing\t?\n' > "$OBP/obligations.tsv"
is  "an evidence command that does not exist here is ACTIVE UNKNOWN" "$(_obrun | cut -f4,5)" "ACTIVE	UNKNOWN"
printf 'a\tRELEASE_BLOCKING\tdeterministic\t-\techo cannot; exit 2\tthing\t?\n' > "$OBP/obligations.tsv"
is  "evidence that says it cannot examine is UNKNOWN, not failed" "$(_obrun | cut -f5)" "UNKNOWN"
has "carrying the evidence's own last line" "$(_obrun | cut -f6)" "cannot"

printf '\ncandidates: what a model proposed, and nothing admitted\n'
# Obligation discovery, first increment (docs/2026-09-16-discovery-baseline-
# design.md). A session's model answers a provider request with candidate
# obligations; the engine reads the answer offline, refuses row by row with a
# printed reason, appends what it accepted to candidates.tsv under the memory
# root with the epoch it was proposed under, and reports. Nothing here reaches
# obligations.tsv, nothing here runs a candidate's command, and a candidate
# whose epoch has moved reads stale from a comparison made now, never from a
# stored state. Authored blind, from the prose, before the reader existed.
CDP="$TMP/cand-proj"; CDR="$TMP/cand-repo"
mkdir -p "$CDP" "$CDR/routes" "$MEM/cand-proj/commission"
printf 'a\n' > "$CDR/routes/a"
( _fx_cd "$CDR" && git init -q -b main && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
CDR="$(cd "$CDR" && pwd -P)"
printf '{\n  "name": "cand-proj",\n  "remote_match": "example.com/cand-proj",\n  "gate": "true"\n}\n' \
  > "$CDP/project.json"
# Two predicates, so a candidate can ground on both, whose count moves when a
# file is added under routes/ — that is how the epoch is made to move below.
{ printf '# predicate\tgrounds\twhen\tprobe\twitness\n'
  printf 'http_route\t-\t-\tls -1 routes\ttest -d routes\n'
  printf 'ceiling_site\t-\t-\tls -1 routes\ttest -d routes\n'; } > "$CDP/probes.tsv"
printf 'lifecycle_wired\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\thttp_route\tthe fixture admits one thing, and it holds\n' \
  > "$CDP/obligations.tsv"
printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\nobligations_surveyed\t-\t-\t-\tprovider:felix:obligations\t-\t4\n' \
  > "$CDP/commissioning.tsv"
cp "$CDP/obligations.tsv" "$TMP/cand-oblig.keep"; cp "$CDP/probes.tsv" "$TMP/cand-probes.keep"
CDANS="$MEM/cand-proj/commission/obligations_surveyed.tsv"
CDTAB="$MEM/cand-proj/candidates.tsv"

# The sourcing shape the reader is specified under: resolve, probes,
# obligations, epoch, then the reader. epoch.sh brings commission.sh and what
# that carries.
_cd() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"
          . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/epoch.sh"
          . "$FROOT/harness/lib/candidates.sh"; "$@" ) 2>/dev/null; }
# _cdlib, _cdtopo and _cdepoch, the topology and the epoch an answer is keyed
# to, are in tests/lib/candidates.sh.
_cdps()    { ( _cdlib; felix_commission_provider_state "$CDP" "$CDR" obligations_surveyed | cut -f1 ) 2>/dev/null; }
# Fields joined by a tab, so a row reads as its columns and an empty cell is
# an empty cell rather than whitespace that may or may not be a tab.
_cdr()   { local IFS=$'\t'; printf '%s' "$*"; }
_cdw()   { printf 'w%.0s' $(seq 1 "$1"); }
# The answer file, in the shape the design gives it: topology and epoch as
# they are now, the rows given, and a done count — `-` for the honest count,
# a number to make the file disagree with itself.
_cdans() { local n="$1" r; shift
           { printf '# topology %s\n# epoch %s\n' "$(_cdtopo)" "$(_cdepoch)"
             for r in "$@"; do printf '%s\n' "$r"; done
             [ "$n" = "-" ] && n=$#
             printf 'done\t%s\n' "$n"; } > "$CDANS"; }
_cdwhy()  { printf '%s\n' "$1" | awk -F'\t' -v n="$2" '$1 == "refuse" && $2 == n { print $3 }'; }
_cdacc()  { printf '%s\n' "$1" | awk -F'\t' -v n="$2" '$1 == "accept" && $2 == n' | grep -c .; }
_cdcnt()  { grep -o '[0-9][0-9]*' | head -1; }
_cdsame() { cmp -s "$1" "$2" && echo same || echo different; }

_cde0="$(_cdepoch)"; _cdt0="$(_cdtopo)"
is  "the candidate fixture's epoch is a hash" "$(printf '%s' "$_cde0" | grep -c '^[0-9a-f]\{40\}$')" "1"
[ -n "$_cdt0" ] && ok "and its topology is non-empty" || bad "and its topology is non-empty"

# ------------------------------------------------------------- the rules ----
# Every refusal is printed with a reason, never silently skipped; every
# accepted line carries the row whole. Twenty data rows: five that pass and
# fifteen that each break one rule.
CDNS_EV='for r in routes/*; do echo "$r ceiling-armed"; done'
CDNS_WHY='a route reachable by a stranger with a link is unbounded unless the process serving it arms the ceiling'
CD_NS="$(_cdr route_behind_ceiling ADVISORY - "$CDNS_EV" http_route,ceiling_site uncontrolled_cost "$CDNS_WHY")"
CD_INFO="$(_cdr info_row INFO - 'ls routes' http_route unread_route 'a route nobody lists is a route nobody reads')"
CD_PIPED="$(_cdr piped_evidence ADVISORY 'ls routes | grep -q .' 'printf x | grep -q x; true & wait' ceiling_site pipe_in_a_command 'a pipe, a semicolon and an ampersand are how evidence is spelt, and none of it runs here')"
CD_MARK="$(_cdr marker_row ADVISORY "touch $TMP/ran-cand-applies" "touch $TMP/ran-cand-evidence" http_route ran_anyway 'if either column is ever run, a file appears')"
CD_MAX="$(_cdr at_ceiling ADVISORY - true http_route at_the_line "$(_cdw 300)")"
CD_BLOCK="$(_cdr blocker RELEASE_BLOCKING - true http_route overclaim 'a model proposing a blocking class is refused, not downgraded')"
_cdans - "$CD_NS" "$CD_INFO" "$CD_PIPED" "$CD_MARK" "$CD_MAX" \
  "$(_cdr six_fields ADVISORY - true http_route 'six fields, no reason')" \
  "$(_cdr eight_fields ADVISORY - true http_route fm 'seven and one more' extra)" \
  "$(_cdr Bad_Name ADVISORY - true http_route fm 'a capital')" \
  "$(_cdr route-x ADVISORY - true http_route fm 'a hyphen')" \
  "$(_cdr '' ADVISORY - true http_route fm 'no name at all')" \
  "$(_cdr lifecycle_wired ADVISORY - true http_route fm 'already in the ledger')" \
  "$CD_BLOCK" \
  "$(_cdr task_blocker TASK_BLOCKING - true http_route fm 'a task-blocking class is blocking too')" \
  "$(_cdr odd_class SEVERE - true http_route fm 'a class the ledger does not know')" \
  "$(_cdr dash_evidence ADVISORY - - http_route fm 'a dash for evidence')" \
  "$(_cdr empty_evidence ADVISORY - '' http_route fm 'nothing for evidence')" \
  "$(_cdr paid_route ADVISORY - true paid_model_path fm 'a probe nobody declared')" \
  "$(_cdr ungrounded ADVISORY - true - fm 'a dash for grounds')" \
  "$(_cdr half_grounded ADVISORY - true http_route,paid_model_path fm 'one declared, one not')" \
  "$(_cdr long_reason ADVISORY - true http_route fm "$(_cdw 301)")"
_cdo="$(_cd felix_candidates_rules "$CDP" "$CDR")"
is  "the rules print one line per data row, none for the header lines or the done row" \
    "$(printf '%s\n' "$_cdo" | grep -c .)" "20"
is  "the done row is not a candidate" "$(printf '%s\n' "$_cdo" | awk -F'\t' '$2 == "done"' | grep -c .)" "0"
is  "five rows are accepted, by name" \
    "$(printf '%s\n' "$_cdo" | awk -F'\t' '$1 == "accept" { print $2 }' | LC_ALL=C sort | paste -sd, -)" \
    "at_ceiling,info_row,marker_row,piped_evidence,route_behind_ceiling"
is  "an accepted line carries the row whole, seven fields after the verdict" \
    "$(printf '%s\n' "$_cdo" | awk -F'\t' '$1 == "accept" && $2 == "route_behind_ceiling"' | cut -f2-)" "$CD_NS"
is  "fifteen are refused, each with a reason" \
    "$(printf '%s\n' "$_cdo" | awk -F'\t' '$1 == "refuse" && $3 != ""' | grep -c .)" "15"
has "six fields is refused for its field count"                       "$(_cdwhy "$_cdo" six_fields)"     "fields"
has "eight fields is refused for its field count, never cut to seven" "$(_cdwhy "$_cdo" eight_fields)"   "fields"
has "a capital in the name is not a name"                             "$(_cdwhy "$_cdo" Bad_Name)"       "not a name"
has "a hyphen in the name is not a name"                              "$(_cdwhy "$_cdo" route-x)"        "not a name"
is  "a row with no name is refused as unnamed" \
    "$(printf '%s\n' "$_cdo" | awk -F'\t' '$1 == "refuse" && $2 == "(unnamed)"' | grep -c .)" "1"
has "a name the ledger already admits is refused as already admitted" "$(_cdwhy "$_cdo" lifecycle_wired)" "already admitted"
has "a RELEASE_BLOCKING candidate is refused because it may not block" "$(_cdwhy "$_cdo" blocker)"        "may not block"
has "and TASK_BLOCKING may not block either"                          "$(_cdwhy "$_cdo" task_blocker)"   "may not block"
is  "refused, not downgraded: the blocking row is accepted nowhere"    "$(_cdacc "$_cdo" blocker)"        "0"
has "a class the ledger does not know is refused for its class"       "$(_cdwhy "$_cdo" odd_class)"      "class"
has "a dash for evidence is no evidence"                              "$(_cdwhy "$_cdo" dash_evidence)"  "no evidence"
has "an empty evidence cell is no evidence"                           "$(_cdwhy "$_cdo" empty_evidence)" "no evidence"
has "a ground the probe table does not declare is refused"            "$(_cdwhy "$_cdo" paid_route)"     "not a declared probe"
has "a dash for grounds is refused, where the ledger would only count it" "$(_cdwhy "$_cdo" ungrounded)" "not a declared probe"
has "one undeclared ground among declared ones refuses the row"       "$(_cdwhy "$_cdo" half_grounded)"  "not a declared probe"
has "a reason past 300 characters is refused, not shortened"          "$(_cdwhy "$_cdo" long_reason)"    "longer than"
is  "a reason of exactly 300 is accepted"                              "$(_cdacc "$_cdo" at_ceiling)"     "1"
is  "an INFO candidate is accepted"                                    "$(_cdacc "$_cdo" info_row)"       "1"
is  "a pipe, a semicolon and an ampersand in applies or evidence refuse nothing" "$(_cdacc "$_cdo" piped_evidence)" "1"
is  "the north-star row is accepted: ADVISORY, always applies, grounded on http_route and ceiling_site" \
    "$(_cdacc "$_cdo" route_behind_ceiling)" "1"

# ------------------------------------------------------------ the record ----
# Thirteen fields, provenance first like facts.log, the pathway stamped by the
# engine, the epoch read off the answer file rather than computed again.
_cdans - "$CD_NS" "$CD_INFO" "$CD_PIPED" "$CD_MARK" "$CD_MAX" "$CD_BLOCK"
_cde1="$(sed -n '2s/^# epoch //p' "$CDANS")"
is  "the generic reader reads a seven-field answer as answered, not as five fields short" "$(_cdps)" "answered"
_cdn="$(_cd felix_candidates_record "$CDP" "$CDR" | _cdcnt)"
is  "recording an answered file appends the accepted rows and says how many" "$_cdn" "5"
is  "five rows in candidates.tsv under the memory root"      "$(grep -c . "$CDTAB" 2>/dev/null)" "5"
is  "thirteen fields per row" \
    "$(awk -F'\t' '{ print NF }' "$CDTAB" | LC_ALL=C sort -u | paste -sd, -)" "13"
is  "the eighth field is probabilistic on every row, stamped by the engine and never read from the model" \
    "$(cut -f8 "$CDTAB" | LC_ALL=C sort -u)" "probabilistic"
is  "the third field is the epoch the answer file named"     "$(cut -f3 "$CDTAB" | LC_ALL=C sort -u)" "$_cde1"
is  "the first field is a UTC stamp" \
    "$(cut -f1 "$CDTAB" | head -1 | grep -c '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}Z$')" "1"
is  "the second is a tree id, forty hex"  "$(cut -f2 "$CDTAB" | LC_ALL=C sort -u | grep -c '^[0-9a-f]\{40\}$')" "1"
is  "and it is this checkout's tree id"   "$(cut -f2 "$CDTAB" | LC_ALL=C sort -u)" "$(_cd felix_tree_id "$CDR" "$FROOT")"
case "$(cut -f4 "$CDTAB" | LC_ALL=C sort -u)" in
  felix@*/*) ok  "the fourth names the engine as proposer: felix at a version and a sha" ;;
  *)         bad "the fourth names the engine as proposer: felix at a version and a sha" "$(cut -f4 "$CDTAB" | LC_ALL=C sort -u)" ;;
esac
case "$(cut -f5 "$CDTAB" | LC_ALL=C sort -u)" in
  obligations_surveyed.tsv@?*) ok  "the fifth is the answer file's name at its hash" ;;
  *)                           bad "the fifth is the answer file's name at its hash" "$(cut -f5 "$CDTAB" | LC_ALL=C sort -u)" ;;
esac
_cdns="$(awk -F'\t' '$6 == "route_behind_ceiling"' "$CDTAB" | head -1)"
is  "the north-star row's own columns follow, in the ledger's order" \
    "$(printf '%s\n' "$_cdns" | cut -f7,9,11,12)" "$(_cdr ADVISORY - http_route,ceiling_site uncontrolled_cost)"
is  "with its evidence whole"                    "$(printf '%s\n' "$_cdns" | cut -f10)" "$CDNS_EV"
is  "and its reason whole"                       "$(printf '%s\n' "$_cdns" | cut -f13)" "$CDNS_WHY"
is  "the 300-character reason survives the record whole" \
    "$(awk -F'\t' '$6 == "at_ceiling" { print length($13) }' "$CDTAB")" "300"
_cdn2="$(_cd felix_candidates_record "$CDP" "$CDR" | _cdcnt)"
is  "recording the same file again appends nothing"        "$(grep -c . "$CDTAB")" "5"
is  "and says so"                                          "${_cdn2:-0}" "0"
is  "read prints the recorded rows" \
    "$(_cd felix_candidates_read "$CDP" | awk -F'\t' 'NF == 13 && $8 == "probabilistic" { print $6 }' | LC_ALL=C sort | paste -sd, -)" \
    "at_ceiling,info_row,marker_row,piped_evidence,route_behind_ceiling"
is  "every recorded row is current under the epoch it was proposed under" \
    "$(_cd felix_candidates_stale "$CDP" "$CDR" | cut -f2 | LC_ALL=C sort -u)" "current"
is  "stale prints one line per recorded row"               "$(_cd felix_candidates_stale "$CDP" "$CDR" | grep -c .)" "5"
[ ! -e "$TMP/ran-cand-applies" ] && [ ! -e "$TMP/ran-cand-evidence" ] \
  && ok  "no candidate's applies or evidence ran through rules, record, read or stale" \
  || bad "no candidate's applies or evidence ran through rules, record, read or stale" "a marker file appeared"
is  "obligations.tsv is byte-identical after all four"    "$(_cdsame "$CDP/obligations.tsv" "$TMP/cand-oblig.keep")" "same"

# -------------------------------------------------------------- the epoch ----
# Stale is a comparison made now. A probe count moving makes every row stale;
# the re-run that asks for is recorded again under the new epoch, same names
# and all, because the store is per answer file and a proposal under a new
# epoch is a new proposal; and moving the count back flips the reading,
# because nothing about staleness was ever written down.
printf 'b\n' > "$CDR/routes/b"
is  "a probe count moving makes every recorded row stale" \
    "$(_cd felix_candidates_stale "$CDP" "$CDR" | cut -f2 | LC_ALL=C sort -u)" "stale"
_cdans - "$CD_NS" "$CD_INFO" "$CD_PIPED" "$CD_MARK" "$CD_MAX" \
  "$(_cdr rerun_only ADVISORY - true ceiling_site seen_second_time 'a row the second pass found and the first did not')"
_cde2="$(sed -n '2s/^# epoch //p' "$CDANS")"
[ -n "$_cde2" ] && [ "$_cde2" != "$_cde1" ] \
  && ok  "the re-run's answer names a different epoch" \
  || bad "the re-run's answer names a different epoch" "[$_cde2] against [$_cde1]"
is  "a re-run under the new epoch is recorded, same names and all" \
    "$(_cd felix_candidates_record "$CDP" "$CDR" | _cdcnt)" "6"
is  "eleven rows now"                                        "$(grep -c . "$CDTAB")" "11"
is  "the first five read stale and the new six current" \
    "$(_cd felix_candidates_stale "$CDP" "$CDR" | cut -f2 | LC_ALL=C sort | uniq -c | awk '{ print $2 "=" $1 }' | paste -sd, -)" \
    "current=6,stale=5"
rm -f "$CDR/routes/b"
is  "with the count back, the second pass's row is the stale one" \
    "$(_cd felix_candidates_stale "$CDP" "$CDR" | awk -F'\t' '$1 == "rerun_only" { print $2 }')" "stale"
is  "and the first five are current again: nothing about staleness was stored" \
    "$(_cd felix_candidates_stale "$CDP" "$CDR" | cut -f2 | grep -c '^current$')" "5"

# An answer naming an epoch that is not this one is provenance, not a defect:
# ingested with the epoch it named, and stale at once.
{ printf '# topology %s\n# epoch %s\n' "$(_cdtopo)" "0000000000000000000000000000000000000000"
  printf '%s\n' "$(_cdr foreign_epoch ADVISORY - true http_route said_elsewhere 'proposed under an epoch that is not this one')"
  printf 'done\t1\n'; } > "$CDANS"
is  "an answer naming an epoch that is not the current one is still ingested" \
    "$(_cd felix_candidates_record "$CDP" "$CDR" | _cdcnt)" "1"
is  "with the epoch it named, as provenance" \
    "$(awk -F'\t' '$6 == "foreign_epoch" { print $3 }' "$CDTAB")" "0000000000000000000000000000000000000000"
is  "and it reads stale at once" \
    "$(_cd felix_candidates_stale "$CDP" "$CDR" | awk -F'\t' '$1 == "foreign_epoch" { print $2 }')" "stale"

# A file that disagrees with itself, and one keyed to another topology: the
# provider state's own words, and nothing recorded from either.
_cdans 3 "$(_cdr partial_row ADVISORY - true http_route counted_wrong 'the done count says three and there are two')" \
         "$(_cdr partial_row_two ADVISORY - true http_route counted_wrong 'the done count says three and there are two')"
is  "a done count that disagrees with the rows reads partial"  "$(_cdps)" "partial"
_cdn3="$(_cd felix_candidates_record "$CDP" "$CDR" | _cdcnt)"
is  "and a partial answer records nothing"                     "${_cdn3:-0}" "0"
is  "the table did not grow"                                   "$(grep -c . "$CDTAB")" "12"
is  "and neither partial row is in it"                         "$(grep -c 'partial_row' "$CDTAB")" "0"
{ printf '# topology 0000\n# epoch %s\n' "$(_cdepoch)"
  printf '%s\n' "$(_cdr other_topology ADVISORY - true http_route keyed_elsewhere 'an answer for a topology this is not')"
  printf 'done\t1\n'; } > "$CDANS"
is  "an answer keyed to another topology reads stale"          "$(_cdps)" "stale"
_cd felix_candidates_record "$CDP" "$CDR" >/dev/null
is  "and records nothing either"                               "$(grep -c 'other_topology' "$CDTAB")" "0"

# No probes, no epoch, and an epoch that cannot be computed now makes every
# row stale rather than current by default.
rm -f "$CDP/probes.tsv"
is  "with no probes.tsv the epoch cannot be computed, and every recorded row is stale" \
    "$(_cd felix_candidates_stale "$CDP" "$CDR" | cut -f2 | LC_ALL=C sort -u)" "stale"
is  "still one line per recorded row"                          "$(_cd felix_candidates_stale "$CDP" "$CDR" | grep -c .)" "12"
cp "$TMP/cand-probes.keep" "$CDP/probes.tsv"
is  "obligations.tsv is byte-identical at the end of the block" "$(_cdsame "$CDP/obligations.tsv" "$TMP/cand-oblig.keep")" "same"
[ ! -e "$TMP/ran-cand-applies" ] && [ ! -e "$TMP/ran-cand-evidence" ] \
  && ok  "and still no candidate command has run" \
  || bad "and still no candidate command has run" "a marker file appeared"

# ---------------------------------------------------------------- the CLI ----
# On the bound fixture. --request writes a request for a session, refuses
# when the epoch cannot be computed, and touches no table; the report ingests
# an answered file offline and shows it; the gate's copy shows none of it.
WDP="$FROOT/projects/widget"
WDANS="$MEM/widget/commission/obligations_surveyed.tsv"
WDREQ="$MEM/widget/commission/requests/obligations_surveyed.md"
WDTAB="$MEM/widget/candidates.tsv"
mkdir -p "$MEM/widget/commission"
rm -f "$WDANS" "$WDREQ" "$WDTAB" "$TMP/ran-cand-cli"
cp "$WDP/obligations.tsv" "$TMP/cand-w-oblig.keep"; cp "$WDP/probes.tsv" "$TMP/cand-w-probes.keep"
cp "$WDP/commissioning.tsv" "$TMP/cand-w-cm.keep"
_wd()  { ( cd "$REPO" && PATH="$CMSTUB:$PATH" "$FELIX" obligations "$@" 2>&1 ); }
_wde="$(_cdepoch "$WDP" "$REPO")"; _wdt="$(_cdtopo "$WDP" "$REPO")"
is  "the widget's epoch is a hash" "$(printf '%s' "$_wde" | grep -c '^[0-9a-f]\{40\}$')" "1"
[ -n "$_wdt" ] && ok "and the widget's topology is non-empty" || bad "and the widget's topology is non-empty"

_wdo="$(_wd --request)"; _wdrc=$?
is  "felix obligations --request exits 0 on a project whose epoch computes" "$_wdrc" "0"
[ -f "$WDREQ" ] && ok  "and writes the request under the memory root" \
                || bad "and writes the request under the memory root" "$_wdo"
has "the request carries the epoch it was asked under"      "$(tr -d '`' < "$WDREQ" 2>/dev/null)" "Epoch $_wde"
has "and the topology it is keyed to"                       "$(tr -d '`' < "$WDREQ" 2>/dev/null)" "Topology $_wdt"
is  "and every placeholder in it was filled"                "$(grep -c '{{' "$WDREQ" 2>/dev/null)" "0"
has "it names the candidate answer file to write"           "$(cat "$WDREQ" 2>/dev/null)" "$WDANS"
has "it lists the probe predicate a candidate may ground on" "$(cat "$WDREQ" 2>/dev/null)" "marker"
has "and the admitted row not to re-propose"                "$(cat "$WDREQ" 2>/dev/null)" "fixture"
has "and states the reason ceiling a candidate is held to"  "$(cat "$WDREQ" 2>/dev/null)" "300"
is  "--request writes no table: obligations.tsv is byte-identical" "$(_cdsame "$WDP/obligations.tsv" "$TMP/cand-w-oblig.keep")" "same"
is  "nor probes.tsv"                                        "$(_cdsame "$WDP/probes.tsv" "$TMP/cand-w-probes.keep")" "same"
is  "nor commissioning.tsv"                                 "$(_cdsame "$WDP/commissioning.tsv" "$TMP/cand-w-cm.keep")" "same"
[ ! -s "$WDTAB" ] && ok  "nor candidates.tsv, with no answer to ingest" \
                  || bad "nor candidates.tsv, with no answer to ingest" "$(cat "$WDTAB")"
rm -f "$WDP/probes.tsv" "$WDREQ"
_wdo="$(_wd --request)"; _wdrc=$?
[ "$_wdrc" -ne 0 ] && ok  "--request refuses when the epoch cannot be computed" \
                   || bad "--request refuses when the epoch cannot be computed" "exit 0: $_wdo"
has "and says it is the epoch it lacks"     "$_wdo" "epoch"
[ ! -e "$WDREQ" ] && ok  "and writes no request for a topology the probes could not read" \
                  || bad "and writes no request for a topology the probes could not read" "$(cat "$WDREQ")"
cp "$TMP/cand-w-probes.keep" "$WDP/probes.tsv"

: > "$CMSTUB_LOG"
{ printf '# topology %s\n# epoch %s\n' "$_wdt" "$_wde"
  printf '%s\n' "$(_cdr route_behind_ceiling ADVISORY - "touch $TMP/ran-cand-cli" marker uncontrolled_cost "$CDNS_WHY")"
  printf 'done\t1\n'; } > "$WDANS"
_wdo="$(_wd)"; _wdrc=$?
is  "felix obligations ingests an answered file and still exits 0"  "$_wdrc" "0"
has "and prints a candidates section"                                "$_wdo" "candidates"
has "with the row by name, current under this epoch"                 "$(printf '%s\n' "$_wdo" | grep 'route_behind_ceiling')" "current"
has "and the footer: discovered one, admitted one"                   "$_wdo" "discovered 1, admitted 1"
is  "the row is in candidates.tsv under the widget's memory" \
    "$(awk -F'\t' '$6 == "route_behind_ceiling"' "$WDTAB" 2>/dev/null | grep -c .)" "1"
is  "with no cli call at all"                                        "$(grep -c . "$CMSTUB_LOG")" "0"
[ ! -e "$TMP/ran-cand-cli" ] && ok  "and the candidate's evidence did not run in the report" \
                             || bad "and the candidate's evidence did not run in the report" "the marker appeared"
is  "obligations.tsv is byte-identical after the report"             "$(_cdsame "$WDP/obligations.tsv" "$TMP/cand-w-oblig.keep")" "same"
_wdg="$(_wd --gate)"; _wdgrc=$?
is  "--gate still passes with an answer file present"                "$_wdgrc" "0"
case "$_wdg" in
  *candidates*) bad "and the gate's copy carries no candidates section" "$_wdg" ;;
  *)            ok  "and the gate's copy carries no candidates section" ;;
esac
{ printf '# topology %s\n# epoch %s\n' "$_wdt" "$_wde"
  printf '%s\n' "$(_cdr blocker RELEASE_BLOCKING - true marker overclaim 'a model proposing a blocking class is refused, not downgraded')"
  printf 'done\t1\n'; } > "$WDANS"
_wdo="$(_wd)"; _wdrc=$?
is  "a refused candidate does not fail the report"                   "$_wdrc" "0"
has "the refused row is shown with its reason"                       "$(printf '%s\n' "$_wdo" | grep 'blocker')" "may not block"
is  "and recorded nowhere"                                           "$(awk -F'\t' '$6 == "blocker"' "$WDTAB" 2>/dev/null | grep -c .)" "0"
is  "the store still holds the one row"                              "$(grep -c . "$WDTAB")" "1"
has "and the footer still counts one discovered, one admitted"       "$_wdo" "discovered 1, admitted 1"
rm -f "$WDANS" "$WDREQ" "$WDTAB" "$TMP/ran-cand-cli"


