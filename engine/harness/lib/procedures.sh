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
#
# 0 with the items on stdout, and 2 with nothing printed when the declared list
# could not be read, or when the pipeline that sorts the items did not run whole.
# Until 2026-10-01 an unread list dropped the declared capabilities from the
# items, so the gap list shrank, a stance on one was an orphan, and the report
# could say every item had a stance. The list is read once with
# felix_declared_into and walked in this shell, where a here-document is a
# temporary file on bash 3.2 and one that cannot be written reads as nothing
# declared. The group ends in `:` because the detect loop's and the mistakes
# log's own statuses are other lookups and are left as they were; what is asked
# of the pipeline is that the group and the sort both ran, and their statuses are
# taken whole before the first test resets them.
felix_procedures_items() {
  local proj="$1" root="${2:-}" mem cap declared="" rest nl=$'\n'
  felix_declared_into declared "$proj" || return 2
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
    rest="$declared"
    while [ -n "$rest" ]; do
      cap="${rest%%$nl*}"
      if [ "$cap" = "$rest" ]; then rest=""; else rest="${rest#*$nl}"; fi
      [ -n "$cap" ] || continue
      printf 'capability:%s\n' "$cap"
    done
    mem="$(felix_mem_dir "$proj")"
    if [ -f "$mem/mistakes.log" ]; then
      # Column four holds every check that failed in one run, space separated.
      # Read through felix_mem_mistake_rows, so a failure an older engine
      # wrote as a split row on an unborn HEAD is an item too (U44).
      felix_mem_mistake_rows "$mem/mistakes.log" \
        | awk -F'\t' '{ n = split($4, t, " "); for (i = 1; i <= n; i++)
                    if (t[i] != "") print "failure:" t[i] }' 2>/dev/null
    fi
    :
  } | LC_ALL=C sort -u
  set -- "${PIPESTATUS[@]}"
  [ "${1:-1}" -eq 0 ] && [ "${2:-1}" -eq 0 ] || return 2
  return 0
}

# item <TAB> moment <TAB> answered-by <TAB> note, for stances a person took.
felix_procedures_stances() {
  local proj="$1"
  [ -f "$proj/procedures.tsv" ] || return 0
  LC_ALL=C grep -vE '^[[:space:]]*(#|$)' "$proj/procedures.tsv" 2>/dev/null
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
#
# The stances are read once and walked as a string in this shell, the moment
# tested against the declared ones by case. Until 2026-10-08 they went through a
# here-document and felix_has_line, which is another, and on a bash that writes a
# here-document to a temporary file (3.2 among them) one that could not be
# written ended the walk before its first stance, so no stance answered anything
# and every item that had one was called a gap.
felix_procedures_effective() {
  local proj="$1" tpl="${2:-}" known line moment stances rest nl=$'\n' tab=$'\t'
  known="$(felix_procedures_moments "$tpl")"
  stances="$(felix_procedures_wellformed "$proj")"
  rest="$stances"
  while [ -n "$rest" ]; do
    line="${rest%%$nl*}"
    if [ "$line" = "$rest" ]; then rest=""; else rest="${rest#*$nl}"; fi
    [ -n "$line" ] || continue
    moment="${line#*$tab}"; moment="${moment%%$tab*}"
    if [ -n "$tpl" ]; then
      case "$nl$known$nl" in *"$nl$moment$nl"*) ;; *) continue ;; esac
    fi
    printf '%s\n' "$line"
  done
  return 0
}

#
# 0 with the gaps on stdout, and 2 with nothing printed when the items could not
# be read, because the declared list could not. Until 2026-10-01 the items came
# back without the declared capabilities, and the gap list was shorter than the
# real one. The items are captured with felix_capture, since a substitution can
# end with nothing printed and status 0 when its fork fails, and walked in this
# shell, where a here-document that cannot be written ends the loop before its
# first item and no gap is named. The stances come from felix_procedures_effective
# in a plain substitution: a table with none closes nothing, and what it says of
# itself is not the declared list's. That function walked them through
# here-documents too, until 2026-10-08, and with one that could not be written
# every item that had a stance was called a gap; it walks them in the shell now.
felix_procedures_gaps() {
  local proj="$1" root="${2:-}" tpl="${3:-}" item stanced items="" rest nl=$'\n'
  felix_capture items felix_procedures_items "$proj" "$root" || return 2
  stanced="$(felix_procedures_effective "$proj" "$tpl" | cut -f1)"
  rest="$items"
  while [ -n "$rest" ]; do
    item="${rest%%$nl*}"
    if [ "$item" = "$rest" ]; then rest=""; else rest="${rest#*$nl}"; fi
    [ -n "$item" ] || continue
    case "$nl$stanced$nl" in *"$nl$item$nl"*) continue ;; esac
    printf '%s\n' "$item"
  done
  return 0
}

# Stances for something nothing enumerates: a claim about a surface that is
# gone, or a name that never existed. The other direction of the same
# question, and the precedent this design copies checks both — a table is
# wrong when it lacks a row reality has, and equally wrong when it keeps one
# reality dropped.
#
# 0 with the orphans on stdout, and 2 with nothing printed when the items could
# not be read, because the declared list could not. Until 2026-10-01 the items
# came back without the declared capabilities, so a stance on a declared
# capability was called an orphan, a claim about a surface that is gone. The
# items are captured with felix_capture, since a substitution can end with
# nothing printed and status 0 when its fork fails, and the stances are walked
# in this shell, where a here-document that cannot be written ends the loop
# before its first stance and no orphan is named.
felix_procedures_orphans() {
  local proj="$1" root="${2:-}" item items="" stanced rest nl=$'\n'
  felix_capture items felix_procedures_items "$proj" "$root" || return 2
  stanced="$(felix_procedures_wellformed "$proj" | cut -f1)"
  rest="$stanced"
  while [ -n "$rest" ]; do
    item="${rest%%$nl*}"
    if [ "$item" = "$rest" ]; then rest=""; else rest="${rest#*$nl}"; fi
    [ -n "$item" ] || continue
    case "$nl$items$nl" in *"$nl$item$nl"*) continue ;; esac
    printf '%s\n' "$item"
  done
  return 0
}

# Stances pointing at a moment nobody declared.
#
# A typo answers nothing while looking like an answer, which is the same
# defect one level up — a stance that cannot be reached is a gap wearing a
# stance's clothes.
#
# 0 with the rows on stdout, and 2 with nothing printed when the stances did not
# come back whole. Until 2026-10-08 the stances came through a here-document and
# each moment was tested with felix_has_line, another one, and on bash 3.2 a
# here-document is a temporary file: one that could not be written printed no
# row, and once felix_procedures_effective walked its stances in the shell, felix
# procedures could close on every item having a stance over a stance at a moment
# nobody declared. Now the stances are captured with felix_capture and walked in
# this shell, as in felix_procedures_effective; a wellformed row has three
# non-empty fields, so taking them by expansion shifts no column.
felix_procedures_unknown_moments() {
  local proj="$1" tpl="$2" known line item moment stances="" rest nl=$'\n' tab=$'\t'
  known="$(felix_procedures_moments "$tpl")"
  felix_capture stances felix_procedures_wellformed "$proj" || return 2
  rest="$stances"
  while [ -n "$rest" ]; do
    line="${rest%%$nl*}"
    if [ "$line" = "$rest" ]; then rest=""; else rest="${rest#*$nl}"; fi
    [ -n "$line" ] || continue
    item="${line%%$tab*}"; moment="${line#*$tab}"; moment="${moment%%$tab*}"
    [ -n "$moment" ] || continue
    case "$nl$known$nl" in *"$nl$moment$nl"*) continue ;; esac
    printf '%s\t%s\n' "$moment" "$item"
  done
  return 0
}
