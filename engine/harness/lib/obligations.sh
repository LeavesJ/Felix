# What a project has admitted it owes, and whether it owes it in this checkout.
#
# v3.2 §3 gives an obligation three axes and forbids the one overloaded status
# that lets a requirement be waived by whoever last edited it:
#
#   lifecycle      CANDIDATE / ADMITTED / REJECTED / SUPERSEDED
#   applicability  ACTIVE / DORMANT / UNKNOWN
#   discharge      UNSATISFIED / SATISFIED / UNKNOWN
#
# Only presence is stored. A row in obligations.tsv is ADMITTED; a row removed
# is SUPERSEDED, and removing one escapes to a person, because the epoch rule
# says admitted obligations may stay constant or increase and never quietly
# decrease. Applicability is DERIVED here on every run from the `applies`
# command and never written anywhere (amendments §1.4: a stored ACTIVE→DORMANT
# transition is a second widening channel). Discharge is derived the same way
# from the evidence contract. Nothing in this file can make a row disappear;
# the grounded state can make it stop applying, and that is reported, not
# hidden.
#
# One row:
#
#   obligation <TAB> class <TAB> pathway <TAB> applies <TAB> evidence
#                                              <TAB> grounds <TAB> reason
#
#   class     INFO ADVISORY TASK_BLOCKING RELEASE_BLOCKING AUTHORITY_BLOCKING
#   pathway   deterministic witness corroborated probabilistic unknown
#   applies   a command; exit 0 applies, non-zero does not, 126/127 unknown.
#             `-` means it always applies.
#   evidence  a command; exit 0 holds, 1 fails, 2 cannot examine, 126/127
#             unknown. Its output is the coverage report: what it examined
#             and a verdict per member.
#   grounds   the probe predicate(s) the applicability rests on, comma
#             separated, each declared in probes.tsv; `-` is ungrounded and
#             is counted rather than refused.
#
# The order of questions is the probe's (probes.sh): applicability first, and
# an obligation that does not apply never has its evidence run. Then the
# evidence. `unknown` on either axis is never read as clean — the critical
# unknown pathway holds on authority rather than inventing a verdict.
#
# A single probabilistic finding is advisory only (v3.2 §4, pathway 4), so a
# row that pairs `probabilistic` with a blocking class is malformed and refused
# rather than evaluated: a model's guess may trigger measurement and may not
# stop a release.

FELIX_OBLIGATION_CLASSES='INFO ADVISORY TASK_BLOCKING RELEASE_BLOCKING AUTHORITY_BLOCKING'
FELIX_OBLIGATION_PATHWAYS='deterministic witness corroborated probabilistic unknown'

# One scan decides both what is a row and what is refused, so the two can
# never disagree about a line. mode `rows` prints the well-formed lines
# verbatim; mode `bad` prints one reason per refused line.
_felix_obligation_scan() {
  local table="$1/obligations.tsv" mode="$2"
  [ -f "$table" ] || return 0
  awk -F'\t' -v mode="$mode" \
      -v classes=" $FELIX_OBLIGATION_CLASSES " -v paths=" $FELIX_OBLIGATION_PATHWAYS " '
    /^[[:space:]]*(#|$)/ { next }
    {
      why = ""
      if ($1 == "")
        why = "a row with no obligation name"
      else if (NF < 5 || $5 == "" || $5 == "-")
        why = $1 ": no evidence contract, so nothing could ever discharge it"
      else if (index(classes, " " $2 " ") == 0)
        why = $1 ": class \047" $2 "\047 is not one of" classes
      else if (index(paths, " " $3 " ") == 0)
        why = $1 ": pathway \047" $3 "\047 is not one of" paths
      else if ($3 == "probabilistic" && $2 ~ /_BLOCKING$/)
        why = $1 ": a single probabilistic finding is advisory only and may not block"
      if (mode == "rows" && why == "") print
      if (mode == "bad"  && why != "") print why
    }' "$table"
  return 0
}

felix_obligation_rows()      { _felix_obligation_scan "$1" rows; }
felix_obligation_malformed() { _felix_obligation_scan "$1" bad; }

# The obligations a table admits, by name.
felix_obligation_names() {
  felix_obligation_rows "$1" | cut -f1
  return 0
}

# The two derived axes of one row: applicability <TAB> discharge <TAB> detail.
#
# Exit codes are read the way probes.sh reads them: 126 is a checkout that
# could not be entered and 127 a command that does not exist here, and neither
# says anything about the obligation. Both are UNKNOWN, and UNKNOWN blocks.
felix_obligation_state() {
  local root="$1" applies="$2" evidence="$3" rc out last

  if [ -n "$applies" ] && [ "$applies" != "-" ]; then
    _felix_probe_ask "$root" "$applies"; rc=$?
    case "$rc" in
      0) ;;
      126) printf 'UNKNOWN\tUNKNOWN\tthe checkout could not be entered, so whether this applies is not known\n'; return 0 ;;
      127) printf 'UNKNOWN\tUNKNOWN\ta command in `applies` does not exist here, so whether this applies is not known\n'; return 0 ;;
      *)   printf 'DORMANT\t-\tthe grounded state says this does not apply here\n'; return 0 ;;
    esac
  fi

  out="$( cd "$root" 2>/dev/null || exit 126
          bash -c "$evidence" felix-obligation </dev/null 2>&1 )"
  rc=$?
  last="$(printf '%s\n' "$out" | grep '[^[:space:]]' | tail -1)"
  case "$rc" in
    0)   printf 'ACTIVE\tSATISFIED\tthe evidence contract holds\n' ;;
    2)   printf 'ACTIVE\tUNKNOWN\tthe evidence could not be examined%s\n' "${last:+: $last}" ;;
    126) printf 'ACTIVE\tUNKNOWN\tthe checkout could not be entered, so the evidence was not examined\n' ;;
    127) printf 'ACTIVE\tUNKNOWN\ta command in the evidence contract does not exist here, so nothing was examined\n' ;;
    *)   printf 'ACTIVE\tUNSATISFIED\tthe evidence contract fails (exit %s)%s\n' "$rc" "${last:+: $last}" ;;
  esac
  return 0
}

# Every admitted row, evaluated. Emits:
#   obligation <TAB> class <TAB> pathway <TAB> applicability <TAB> discharge
#     <TAB> detail <TAB> grounds
_felix_obligation_field() { printf '%s\n' "$1" | cut -f"$2"; }
felix_obligations_run() {
  local proj="$1" root="$2" line name cls pw applies ev grounds st
  felix_obligation_rows "$proj" | while IFS= read -r line; do
    [ -n "$line" ] || continue
    # cut per field rather than `IFS=$'\t' read`: tab is IFS whitespace, so an
    # empty cell would shift every later column left.
    name="$(_felix_obligation_field "$line" 1)"
    cls="$(_felix_obligation_field "$line" 2)"
    pw="$(_felix_obligation_field "$line" 3)"
    applies="$(_felix_obligation_field "$line" 4)"
    ev="$(_felix_obligation_field "$line" 5)"
    grounds="$(_felix_obligation_field "$line" 6)"
    st="$(felix_obligation_state "$root" "$applies" "$ev")"
    printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$cls" "$pw" "$st" "${grounds:--}"
  done
  return 0
}

# What stops. With no argument, everything a task may not complete under —
# TASK_BLOCKING and above. With `release`, only what a release may not land
# under: RELEASE_BLOCKING and AUTHORITY_BLOCKING.
#
# A row applies (ACTIVE) or cannot say (UNKNOWN), and is not SATISFIED. A
# DORMANT row never blocks, and is the whole reason the axes are separate: the
# requirement is still admitted and still printed, and the grounded state has
# made it inapplicable. Pathway `unknown` is an authority hold and blocks
# whatever its discharge says, because the row exists to hold, not to pass.
felix_obligations_blocking() {
  local mode="${1:-}"
  awk -F'\t' -v mode="$mode" '
    $2 !~ /_BLOCKING$/ { next }
    mode == "release" && $2 == "TASK_BLOCKING" { next }
    $4 == "DORMANT" { next }
    $3 == "unknown" { print; next }
    $5 != "SATISFIED" { print }'
  return 0
}

# Rows grounded on a probe the project does not declare. A grounding ref is
# the row's claim about which fact its applicability rests on; one that names
# nothing in probes.tsv rests on nothing, and the table is refused for it.
felix_obligations_orphans() {
  local proj="$1" preds g
  preds="$(felix_probe_rows "$proj" 2>/dev/null | cut -f1 | LC_ALL=C sort -u)"
  felix_obligation_rows "$proj" | cut -f6 | tr ',' '\n' | grep -v '^-\?$' \
    | LC_ALL=C sort -u | while IFS= read -r g; do
        [ -n "$g" ] || continue
        felix_has_line "$preds" "$g" && continue
        printf '%s\n' "$g"
      done
  return 0
}

# Rows that ground on no probe at all. Counted, not refused: an obligation
# whose applicability is a command over the tree still applies or not by
# something checkable, and demanding a probe from every row would only produce
# invented ones. But a count nobody prints is a count nobody reads.
felix_obligations_ungrounded() {
  felix_obligation_rows "$1" | awk -F'\t' '$6 == "" || $6 == "-" { print $1 }'
  return 0
}
