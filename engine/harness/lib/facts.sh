# The fact log: what a probe saw, kept, and read back.
#
# Split out of probes.sh when that file reached the 500-line limit, and the
# split is along the real seam rather than at a convenient line. probes.sh asks
# reality a question and computes a state. This file is everything that happens
# to the answer afterwards: what class of knowledge it is, how it is written
# down, and what can be said by holding two of them side by side.
#
# A log nothing reads is `procedures.tsv` one level down — a surface that
# accumulates rows forever while nothing ever consults them — so the reader
# lives here beside the writer, and neither ships without the other.

# Sourced rather than assumed. felix_mem_dir and felix_has_line come from
# resolve.sh, and a lib whose helper is missing does not error — it returns
# empty, which reads as "nothing to report" and is always the permissive
# direction.
if ! command -v felix_mem_dir >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

# The epistemic class of a state, in v3.2's vocabulary. A probe can only ever
# produce two of the four: it observes, or it fails to. It never declares and
# never infers, and writing either into this log would be the fabrication the
# header refuses.
felix_probe_class() {
  case "${1:-}" in
    found|empty)     printf 'OBSERVED' ;;
    unknown|blind)   printf 'UNKNOWN' ;;
    *)               printf 'n/a' ;;
  esac
}

# Append the run to the project's fact log, with provenance.
#
# Append-only and never rewritten. A log a command can rewrite is a log that
# can be made to agree with whatever ran last, and the whole point of keeping
# facts over time is to be able to see one change.
#
# Provenance is what a later reader needs in order to decide whether this fact
# still means anything: when it was taken, which tree it was taken from, what
# state was computed, which INSTRUMENT answered, and the exact command that
# produced it. v3.2 §2 asks for freshness and dependencies as well; the tree id
# is what this increment can honestly supply for both, and saying so is better
# than a column holding a guess.
#
# The instrument column was APPENDED rather than inserted, and that is the whole
# reason it is column nine rather than eight. This log is append-only, so rows
# written before instruments were identified are still in it and always will be
# — and inserting a column would have made every one of those read its probe
# command as its instrument, so the first run after the change reported that
# every single predicate had changed instrument. Reproduced, not reasoned:
# inserting it printed `git ls-files -> git@3662256` for a tool nobody touched.
# Appended, an old row simply has no ninth field, the comparison is skipped,
# and the log says nothing rather than something false.
#
# It grows, and by design. The gate calls this on every run, so the file gains
# one line per row per gate — a few hundred lines a week on a project worked on
# daily. Nothing rotates it, and nothing should yet: the whole value of an
# append-only record is that the old rows are still there, and a rotation
# written before anybody has read a year of it would be deciding what to forget
# before knowing what was worth keeping. When it needs bounding it belongs in
# maintenance.tsv, which is where this project already puts upkeep with a
# cadence.
#
# Returns non-zero when the append did not happen. That is issue #84's shape
# exactly — `felix budget --record` reported success when its append failed and
# the ceiling silently became no ceiling — and a fact log that can lose a row
# while reporting a clean run is worse than no log, because it is trusted.
felix_probes_record() {
  local proj="$1" root="$2" tid="${3:-}" rows="$4"
  local dir log stamp line pred grounds state count detail probe source before after n
  dir="$(felix_mem_dir "$proj")"
  mkdir -p "$dir" 2>/dev/null || return 1
  log="$dir/facts.log"
  [ -f "$log" ] || : > "$log" 2>/dev/null || return 1

  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  [ -n "$tid" ] || tid="unknown-tree"
  before="$(wc -l < "$log" 2>/dev/null | tr -dc '0-9')"; [ -n "$before" ] || before=0
  n=0

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    pred="$(printf '%s\n' "$line" | cut -f1)"
    grounds="$(printf '%s\n' "$line" | cut -f2)"
    state="$(printf '%s\n' "$line" | cut -f3)"
    count="$(printf '%s\n' "$line" | cut -f4)"
    detail="$(printf '%s\n' "$line" | cut -f5)"
    probe="$(printf '%s\n' "$line" | cut -f6)"
    source="$(printf '%s\n' "$line" | cut -f7)"
    n=$((n + 1))
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$stamp" "$tid" "$pred" "$(felix_probe_class "$state")" \
      "$state" "$count" "${grounds:--}" "$probe" "${source:--}" >> "$log" || return 1
  done <<EOF
$rows
EOF

  [ "$n" -gt 0 ] || return 0
  after="$(wc -l < "$log" 2>/dev/null | tr -dc '0-9')"; [ -n "$after" ] || after=0
  # Counted rather than trusted. `>>` on a full disk, a read-only volume or a
  # path that stopped being a file reports through an exit status this loop can
  # miss inside a subshell; the line count cannot be misread.
  [ "$((after - before))" -eq "$n" ]
}

# What changed since the last tree this was asked about.
#
# The fact log exists to be read, and a log nothing reads is `procedures.tsv`
# one level down: a surface that accumulates rows forever while nothing ever
# consults them. So this is the reader, and it is the whole reason the log
# carries a tree id and a count rather than a verdict.
#
# It reports and never blocks, and that is the specification rather than
# timidity: relations produce facts, not obligations. A member disappearing can
# be somebody deleting a file on purpose, and a stop that fires on every
# ordinary deletion is one people learn to route around — which is worse than
# no stop, because it teaches them to route around the ones that matter. The
# states already block where blocking is right: a surface that could be seen
# and now cannot is `blind`, and that is not a drift, it is a refusal.
#
# What it catches that nothing else does: a count that fell. `hook_binding`
# going from eight to six is a floor that stopped running for two events, and
# no check anywhere greps for a hook that was deleted — absence has no line
# number. The predicate had eight members yesterday and has six today, and that
# sentence is only available to something holding both numbers.
#
# Compared against the last run on a DIFFERENT tree. Comparing against the last
# run of any kind would compare a tree with itself the second time anybody runs
# the command in one sitting, and report that nothing ever changes.
felix_probes_drift() {
  local proj="$1" tid="$2" rows="$3"
  local log key when tree line pred state count source was seen_now=""
  # No tree id is not "no drift". It is a run that cannot be placed against
  # any other, and a reader that fell silent here rendered exactly like a tree
  # that had not moved — the one shape this file's own header refuses.
  if [ -z "$tid" ]; then
    printf -- '-\t-\t-\tthis run has no tree id, so nothing was compared against the last tree\n'
    return 0
  fi
  log="$(felix_mem_dir "$proj")/facts.log"
  [ -f "$log" ] || return 0

  # One run is one timestamp and one tree together. The timestamp alone would
  # merge two runs that happened inside the same second on different trees,
  # which is not hypothetical: a gate and a merge check can land together.
  key="$(awk -F'\t' -v t="$tid" '$2 != "" && $2 != t { k = $1 "\t" $2 } END { if (k != "") print k }' "$log")"
  [ -n "$key" ] || return 0
  when="$(printf '%s' "$key" | cut -f1)"
  tree="$(printf '%s' "$key" | cut -f2)"

  # Iterated in table order rather than with awk's `for (p in array)`, whose
  # order is unspecified — a report whose lines move between runs cannot be
  # diffed, and being diffable is the entire point of a log.
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    pred="$(printf '%s\n' "$line" | cut -f1)"
    state="$(printf '%s\n' "$line" | cut -f3)"
    count="$(printf '%s\n' "$line" | cut -f4)"
    source="$(printf '%s\n' "$line" | cut -f7)"
    seen_now="$seen_now
$pred"
    was="$(awk -F'\t' -v w="$when" -v tr="$tree" -v p="$pred" \
             '$1 == w && $2 == tr && $3 == p { print $5 "\t" $6 "\t" (NF >= 9 ? $9 : "-") }' \
             "$log" | head -1)"
    if [ -z "$was" ]; then
      printf '%s\t-\t%s\tnothing had been recorded for this predicate\n' "$pred" "$state"
      continue
    fi
    local wstate wcount wsource
    wstate="$(printf '%s' "$was" | cut -f1)"
    wcount="$(printf '%s' "$was" | cut -f2)"
    wsource="$(printf '%s' "$was" | cut -f3)"

    # The instrument, before anything about the numbers. A count that moved
    # because the tool was replaced is a different fact from one that moved
    # because the project did, and reporting the second when it was the first
    # sends somebody looking for a route that was never added. Said first
    # because it is the explanation for whatever follows it.
    if [ -n "$wsource" ] && [ "$wsource" != "-" ] && [ -n "$source" ] \
         && [ "$source" != "-" ] && [ "$wsource" != "$source" ]; then
      printf '%s\t%s\t%s\tthe instrument changed, so any count below it may be the tool rather than the tree\n' \
        "$pred" "$wsource" "$source"
    fi
    if [ "$wstate" != "$state" ]; then
      printf '%s\t%s\t%s\tthe state changed\n' "$pred" "$wstate" "$state"
      continue
    fi
    # Both sides have to be numbers before they can be compared, and a pair
    # that is not says so. `[ a -gt b ]` on a non-number errors, the error is
    # redirected, and the false status then falls through every branch — so a
    # count nothing could read renders exactly like a count that did not move.
    # That is this whole file's failure class appearing inside its own reader.
    case "${wcount}${count}" in
      *[!0-9]*|'')
        printf '%s\t%s\t%s\tone of these counts is not a number, so nothing was compared\n' \
          "$pred" "${wcount:-?}" "${count:-?}"
        continue ;;
    esac
    if [ "$wcount" -gt "$count" ]; then
      printf '%s\t%s members\t%s members\t%s fewer than on the last tree\n' \
        "$pred" "$wcount" "$count" "$((wcount - count))"
    elif [ "$wcount" -lt "$count" ]; then
      printf '%s\t%s members\t%s members\t%s more than on the last tree\n' \
        "$pred" "$wcount" "$count" "$((count - wcount))"
    fi
  done <<EOF
$rows
EOF

  # The other direction: a predicate this project was reading and no row reads
  # now. Reported rather than blocked, because the table it was removed from is
  # in the escape set and shrinking it already stops a merge for a person to
  # look at. A second stop here would be one that can be waited out — the log
  # only remembers the last run, so running the command twice would clear it.
  awk -F'\t' -v w="$when" -v tr="$tree" '$1 == w && $2 == tr { print $3 "\t" $5 }' "$log" \
    | while IFS= read -r line; do
        [ -n "$line" ] || continue
        pred="$(printf '%s\n' "$line" | cut -f1)"
        felix_has_line "$seen_now" "$pred" && continue
        printf '%s\t%s\tnot read\tthis was being read here and no row reads it now\n' \
          "$pred" "$(printf '%s\n' "$line" | cut -f2)"
      done
  return 0
}
