# What each moment has to answer for, and what nothing answers yet.
#
# Written after a failure of method rather than of code. A governed project's
# security audit found five things four days before its launch; Felix was
# handed the list and grew a command with checks for the two that were
# mechanizable — a stray listener, a file mode — and silently dropped the
# third, a missing request ceiling. Not because the check was hard. Because
# there was no table of what a deploy moment must answer, so nothing could
# say a question had gone unasked. A list of checks cannot report the check
# nobody wrote.
#
# The fix is not a better list, and this is the part worth holding on to.
# `lifecycle.tsv` already solves exactly this shape for hook events, and it
# does not work by being well written: `felix_coverage_events` reads what the
# PLATFORM actually binds, the table carries only stances, and the gap is
# whatever reality has that the table does not. That is why it named
# SubagentStop without anybody thinking of SubagentStop.
#
# So the rule here, and it is the whole design:
#
#   Felix may hold stances. Felix may never author the enumeration.
#
# Items come from two sources it does not control — what the checkout HAS
# (capabilities, read off the tree by detection) and what has actually BITTEN
# (the distinct checks in mistakes.log, written by gate failures as they
# happened). Both grow without anybody deciding they should.
#
# A stance is judgement: at which moment this item is answered, and by what.
# It is authored, arguable, and recorded, which is precisely what an
# enumeration must not be. An item with no stance is not an error and not a
# defect — it is the product. On a project that has never taken one, this
# reports every item, which is the output that would have named the request
# ceiling on the first day rather than after the audit.

# Moments a person has declared. Data, not code: the set is a table so that
# adding one is an edit rather than a release.
felix_procedures_moments() {
  local tpl="$1"
  [ -f "$tpl/moments.tsv" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$tpl/moments.tsv" 2>/dev/null | cut -f1
}

# Everything this project could be asked about. One `kind:name` per line.
#
# Neither half is a list Felix wrote. Capabilities are detected from the
# checkout or adopted from that detection; failures are whatever the gate
# caught, recorded as it caught them. Add a surface and an item appears; break
# something new and an item appears. Nothing here has an opinion about which
# of them matter.
felix_procedures_items() {
  local proj="$1" root="${2:-}" mem cap
  {
    # Both what the tree shows and what the project declared. The first
    # version read the declared file alone, which is a curated snapshot — so
    # a surface the checkout grew after adoption produced no item, no gap,
    # and a clean bill, and the claim that items come from reality was false
    # for half of them. The union is deliberate in the other direction too: a
    # capability somebody declared that the tree no longer shows is still
    # something to answer for, not something to forget.
    [ -n "$root" ] && felix_detect "$root" 2>/dev/null | while IFS= read -r cap; do
      [ -n "$cap" ] || continue
      printf 'capability:%s\n' "$cap"
    done
    while IFS= read -r cap; do
      [ -n "$cap" ] || continue
      printf 'capability:%s\n' "$cap"
    done <<EOF
$(felix_declared "$proj")
EOF
    mem="$(felix_mem_dir "$proj")"
    if [ -f "$mem/mistakes.log" ]; then
      # Column four holds every check that failed in one run, space separated.
      awk -F'\t' '{ n = split($4, t, " "); for (i = 1; i <= n; i++)
                    if (t[i] != "") print "failure:" t[i] }' \
          "$mem/mistakes.log" 2>/dev/null
    fi
  } | LC_ALL=C sort -u
  return 0
}

# item <TAB> moment <TAB> answered-by <TAB> note, for stances a person took.
felix_procedures_stances() {
  local proj="$1"
  [ -f "$proj/procedures.tsv" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$proj/procedures.tsv" 2>/dev/null
}

# Stances that record an actual judgement: an item, a moment, and something
# that answers it. Emits item <TAB> moment <TAB> answered-by.
#
# Read with awk rather than `IFS=$'\t' read`, and that is not a style choice.
# Tab is an IFS *whitespace* character, so bash coalesces runs of it and
# strips trailing ones — `a<TAB><TAB>c` parses as two fields, silently
# shifting every later column left. awk -F'\t' gives the field semantics the
# file format actually has.
felix_procedures_wellformed() {
  local proj="$1"
  felix_procedures_stances "$proj" \
    | awk -F'\t' 'NF >= 3 && $1 != "" && $2 != "" && $3 != "" {
                    printf "%s\t%s\t%s\n", $1, $2, $3 }'
  return 0
}

# Rows that name an item and then record nothing. The review's red, and it was
# this design's own defect reproduced inside the fix: a row closed its item's
# gap the moment column one matched, whether or not it said anything else —
# and every display path keys on the moment, so the row then appeared in no
# section at all. One item vanished from the gap list, the stance list and the
# unknown-moment list simultaneously, and the report said every item had a
# stance. A row that records no judgement is not a stance; it is a gap wearing
# a stance's clothes, which is the sentence this file already contained.
felix_procedures_malformed() {
  local proj="$1"
  felix_procedures_stances "$proj" \
    | awk -F'\t' 'NF < 3 || $1 == "" || $2 == "" || $3 == "" { print $1 }'
  return 0
}

# Items nothing answers. The product.
#
# Absence is reported rather than assumed away, which is the property whose
# lack caused this file to be written: a surface that exists, or a failure
# that has already happened, and no moment at which anybody says it is
# handled. Only a well-formed stance closes one.
# Stances that actually answer: well formed AND at a moment that exists.
#
# A row pointing at a moment nobody declared is unreachable, and this file's
# own sentence says an unreachable stance is a gap wearing a stance's
# clothes. It was reported and still closed the gap, which is that sentence
# half-applied — the report named the typo while the item quietly left the
# unanswered list.
felix_procedures_effective() {
  local proj="$1" tpl="${2:-}" known line moment
  known="$(felix_procedures_moments "$tpl")"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    moment="$(printf '%s\n' "$line" | cut -f2)"
    [ -n "$tpl" ] && ! felix_has_line "$known" "$moment" && continue
    printf '%s\n' "$line"
  done <<EOF
$(felix_procedures_wellformed "$proj")
EOF
  return 0
}

felix_procedures_gaps() {
  local proj="$1" root="${2:-}" tpl="${3:-}" item stanced
  stanced="$(felix_procedures_effective "$proj" "$tpl" | cut -f1)"
  while IFS= read -r item; do
    [ -n "$item" ] || continue
    felix_has_line "$stanced" "$item" && continue
    printf '%s\n' "$item"
  done <<EOF
$(felix_procedures_items "$proj" "$root")
EOF
  return 0
}

# Stances for something nothing enumerates: a claim about a surface that is
# gone, or a name that never existed. The other direction of the same
# question, and the precedent this design copies checks both — a table is
# wrong when it lacks a row reality has, and equally wrong when it keeps one
# reality dropped.
felix_procedures_orphans() {
  local proj="$1" root="${2:-}" item items
  items="$(felix_procedures_items "$proj" "$root")"
  while IFS= read -r item; do
    [ -n "$item" ] || continue
    felix_has_line "$items" "$item" && continue
    printf '%s\n' "$item"
  done <<EOF
$(felix_procedures_wellformed "$proj" | cut -f1)
EOF
  return 0
}

# Stances pointing at a moment nobody declared.
#
# A typo answers nothing while looking like an answer, which is the same
# defect one level up — a stance that cannot be reached is a gap wearing a
# stance's clothes.
felix_procedures_unknown_moments() {
  local proj="$1" tpl="$2" known line item moment
  known="$(felix_procedures_moments "$tpl")"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    item="$(printf '%s\n' "$line" | cut -f1)"
    moment="$(printf '%s\n' "$line" | cut -f2)"
    [ -n "$moment" ] || continue
    felix_has_line "$known" "$moment" && continue
    printf '%s\t%s\n' "$moment" "$item"
  done <<EOF
$(felix_procedures_wellformed "$proj")
EOF
  return 0
}
