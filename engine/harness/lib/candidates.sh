# Candidate obligations: what a model proposed, and nothing admitted.
#
# docs/2026-09-16-discovery-baseline-design.md is the design; this is its
# reader. v3.2 §3 gives an obligation a lifecycle — CANDIDATE, ADMITTED,
# REJECTED, SUPERSEDED — and until this file existed the engine had one state
# of it: a row in obligations.tsv is admitted, and nothing anywhere proposed a
# row. The north-star eval breaks at its first step for that reason: an
# obligation nobody named has no way to exist.
#
# The mechanism is the commissioning provider protocol, because it is the only
# legal surface on which a model answers the engine (constitution invariant 2):
# the engine writes a request under the memory root, a session's model writes
# an answer file in a fixed shape, and this reads the answer back offline. A
# candidate is a row in that answer. This file validates each row, records the
# accepted ones to candidates.tsv with provenance and the decision epoch they
# were proposed under, and reports them. It does not, and may not, write
# obligations.tsv: admission is a person copying a row into the ledger and
# committing, which is the supersession event that opens a new epoch. Every
# candidate is pathway `probabilistic` — a single model finding is advisory
# only (§4) — and the engine stamps that rather than reading it from the
# model, because a column the model writes is a claim.
#
# What is refused is refused with a reason, never downgraded: a RELEASE_BLOCKING
# candidate is not quietly turned ADVISORY, because a downgrade hides an
# overclaim inside an accepted row. And nothing here ever runs a candidate's
# `applies` or `evidence`. The provider rows' ban on shell metacharacters is
# not applied to those two fields — no evidence command could be proposed
# under it — so non-execution is the property the suite asserts instead.
#
# The answer file:
#
#   # topology <hash>
#   # epoch <hash>
#   <obligation> <TAB> <class> <TAB> <applies> <TAB> <evidence> <TAB> <grounds> <TAB> <failure_mode> <TAB> <reason>
#   done <TAB> <n>
#
# candidates.tsv, provenance first the way facts.log is laid out:
#
#   stamp <TAB> tree <TAB> epoch <TAB> proposed_by <TAB> answer_prov <TAB>
#   obligation <TAB> class <TAB> probabilistic <TAB> applies <TAB> evidence
#   <TAB> grounds <TAB> failure_mode <TAB> reason

FELIX_CANDIDATES_NEED='obligations_surveyed'
FELIX_CANDIDATES_CLASSES='INFO ADVISORY'
FELIX_CANDIDATES_REASON_MAX=300

if ! command -v felix_probe_rows >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/probes.sh"
fi
if ! command -v felix_obligation_names >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/obligations.sh"
fi
if ! command -v felix_epoch >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/epoch.sh"
fi
# The provider protocol's paths, state and provenance live in
# commission-provider.sh, not commission.sh, and epoch.sh brings only the
# latter: a guard keyed on the wrong file sourced the wrong file and every
# path here came back empty, which the blind assertions found on their first
# run. The registry reader the provenance needs is toolbox.sh's.
if ! command -v felix_commission_answer_path >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/commission-provider.sh"
fi
if ! command -v felix_registry_field >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/toolbox.sh"
fi

felix_candidates_answer_path() { felix_commission_answer_path "$1" "$FELIX_CANDIDATES_NEED"; }
felix_candidates_path()        { printf '%s/candidates.tsv' "$(felix_mem_dir "$1")"; }

# The epoch the answer was proposed under: its second line, or nothing.
_felix_candidates_answer_epoch() {
  sed -n '2s/^# epoch \([0-9a-f]\{40\}\)$/\1/p' "$1" 2>/dev/null | head -1
}

# One line per data row: accept <TAB> row, or refuse <TAB> name <TAB> reason.
# The rules in the order a reader can act on them; each reason is distinct so
# a refused row says what to change.
felix_candidates_rules() {
  local proj="$1" root="$2" f line n name cls applies ev grounds reason g bad preds admitted
  f="$(felix_candidates_answer_path "$proj")"
  [ -f "$f" ] || return 0
  preds="$(felix_probe_rows "$proj" 2>/dev/null | cut -f1 | LC_ALL=C sort -u)"
  admitted="$(felix_obligation_names "$proj" 2>/dev/null)"
  grep -vE '^[[:space:]]*(#|$)' "$f" | grep -v $'^done\t' | while IFS= read -r line; do
    [ -n "$line" ] || continue
    n="$(printf '%s\n' "$line" | awk -F'\t' '{ print NF }')"
    name="$(printf '%s\n' "$line" | cut -f1)"
    if [ "$n" -ne 7 ]; then
      printf 'refuse\t%s\t%s fields where the shape has 7\n' "${name:-(unnamed)}" "$n"; continue
    fi
    if ! printf '%s' "$name" | grep -qE '^[a-z][a-z0-9_]*$'; then
      printf 'refuse\t%s\tnot a name: an obligation is lowercase letters, digits and underscores\n' "${name:-(unnamed)}"; continue
    fi
    if printf '%s\n' "$admitted" | grep -qxF "$name"; then
      printf 'refuse\t%s\talready admitted in obligations.tsv\n' "$name"; continue
    fi
    cls="$(printf '%s\n' "$line" | cut -f2)"
    case "$cls" in
      *_BLOCKING) printf 'refuse\t%s\tclass %s may not block: a single model finding is advisory only, and a person admits it with the class they can defend\n' "$name" "$cls"; continue ;;
    esac
    case " $FELIX_CANDIDATES_CLASSES " in
      *" $cls "*) ;;
      *) printf 'refuse\t%s\tclass "%s" is not one of %s\n' "$name" "$cls" "$FELIX_CANDIDATES_CLASSES"; continue ;;
    esac
    ev="$(printf '%s\n' "$line" | cut -f4)"
    if [ -z "$ev" ] || [ "$ev" = "-" ]; then
      printf 'refuse\t%s\tno evidence: a candidate nothing could ever discharge is a wish\n' "$name"; continue
    fi
    grounds="$(printf '%s\n' "$line" | cut -f5)"
    bad=""
    for g in $(printf '%s' "$grounds" | tr ',' ' '); do
      printf '%s\n' "$preds" | grep -qxF "$g" || bad="$g"
    done
    [ -z "$grounds" ] && bad="-"
    if [ -n "$bad" ]; then
      printf 'refuse\t%s\tground "%s" is not a declared probe: a proposal grounded on nothing Felix reads is the fabrication the spec forbids\n' "$name" "$bad"; continue
    fi
    reason="$(printf '%s\n' "$line" | cut -f7)"
    if [ "${#reason}" -gt "$FELIX_CANDIDATES_REASON_MAX" ]; then
      printf 'refuse\t%s\ta reason longer than %s characters, which the log could not hold whole\n' "$name" "$FELIX_CANDIDATES_REASON_MAX"; continue
    fi
    printf 'accept\t%s\n' "$line"
  done
  return 0
}

# Append every accepted row of an answered file to candidates.tsv, once per
# answer-file hash. Prints the number appended this call. A partial or stale
# answer records nothing: the provider state decides that, the same way it
# does for every other provider need.
felix_candidates_record() {
  local proj="$1" root="$2" f hash prov epoch stamp tid out n=0 line
  f="$(felix_candidates_answer_path "$proj")"
  [ -f "$f" ] || { printf 0; return 0; }
  [ "$(felix_commission_provider_state "$proj" "$root" "$FELIX_CANDIDATES_NEED" | cut -f1)" = "answered" ] \
    || { printf 0; return 0; }
  hash="$(_felix_hash < "$f")"
  prov="$(basename "$f")@$hash"
  out="$(felix_candidates_path "$proj")"
  if [ -f "$out" ] && grep -qF "	$prov	" "$out" 2>/dev/null; then printf 0; return 0; fi
  mkdir -p "$(dirname "$out")" 2>/dev/null || { printf 0; return 1; }
  epoch="$(_felix_candidates_answer_epoch "$f")"
  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  tid="$(felix_tree_id "$root" "${FELIX_HOME_DIR:-}" 2>/dev/null)" || tid=""
  while IFS= read -r line; do
    case "$line" in accept*) ;; *) continue ;; esac
    line="${line#accept	}"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\tprobabilistic\t%s\n' \
      "$stamp" "${tid:-unknown-tree}" "${epoch:--}" "$(felix_commission_provider_provenance felix)" "$prov" \
      "$(printf '%s\n' "$line" | cut -f1)" "$(printf '%s\n' "$line" | cut -f2)" \
      "$(printf '%s\n' "$line" | cut -f3-)" >> "$out" || { printf '%s' "$n"; return 1; }
    n=$((n + 1))
  done <<ROWS
$(felix_candidates_rules "$proj" "$root")
ROWS
  printf '%s' "$n"
}

felix_candidates_read() {
  local f; f="$(felix_candidates_path "$1")"
  [ -f "$f" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$f"
  return 0
}

# obligation <TAB> current|stale, by the epoch each row was proposed under
# against the epoch now. An epoch that cannot be computed now makes every row
# stale: a proposal about a topology the probes cannot read grounds on
# nothing, and unknown holds.
felix_candidates_stale() {
  local proj="$1" root="$2" now line
  now="$(felix_epoch "$proj" "$root" 2>/dev/null)" || now=""
  felix_candidates_read "$proj" | while IFS= read -r line; do
    [ -n "$line" ] || continue
    if [ -n "$now" ] && [ "$(printf '%s\n' "$line" | cut -f3)" = "$now" ]; then
      printf '%s\tcurrent\n' "$(printf '%s\n' "$line" | cut -f6)"
    else
      printf '%s\tstale\n' "$(printf '%s\n' "$line" | cut -f6)"
    fi
  done
  return 0
}

# Write the request for this need. Refuses when the epoch cannot be computed:
# the request carries the epoch the answer will be proposed under, and a
# request about a topology the probes could not read would ask for a proposal
# grounded on nothing. Prints the request path.
felix_candidates_request() {
  local proj="$1" root="$2" tpl="$3" ep
  ep="$(felix_epoch "$proj" "$root" 2>/dev/null)" || ep=""
  [ -n "$ep" ] || return 2
  felix_commission_request "$proj" "$root" "$FELIX_CANDIDATES_NEED" "$tpl"
}
