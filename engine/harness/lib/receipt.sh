# The receipt: what changed, why, what it risks, and whether anything verified it.
#
# v3.0's domain-OS contract asks every harness for a machine-readable record of
# "what changed, why, evidence, risk, and result" that a peer or a control plane
# can consume without being made to understand Felix's internals. Felix computed
# all of it and emitted none of it: `classify` holds the risk, `evidence` holds
# what is owed, the gate holds the result, `escape` holds the authority question.
# Nothing here discovers a new fact. It serialises facts that already exist and
# gives them a version, so a reader can refuse a shape it does not know.
#
# Two fields are here because of what the transports cannot do, established by
# reading them rather than assumed. Neither MCP `2026-07-28` nor A2A `1.0.1`
# carries a bounded authority claim, and neither signs task output — so
# `authority` travels in the receipt or nowhere. And neither models verification
# as distinct from completion, which is the one thing Felix has that they lack,
# so `verification` is its own object rather than a status word meaning "done".
#
# THE RULE THIS EXISTS TO KEEP, which matters more than the shape.
#
# A receipt may not claim more than it knows. Every input that could not be read
# puts its own name in `unknown` and forces `status` to `indeterminate`. An
# absent gate receipt is `none`, never green. An unresolvable base is
# `changed.known: false`, never an empty changeset. An unreadable risk table is
# tier `unknown`, never `green` — which this project shipped once already.
#
# Six defects found in a single day were one species: an emptiness reported as
# an all-clear. Everywhere else that costs a person one confusing report. Here it
# would be a wire contract other systems build on, so the rule is asserted rather
# than intended.
#
# The same guard escape.sh, classify.sh and evidence.sh each carry, and for the
# reason escape.sh states: a lib whose helper is missing returns an empty path
# list, which reads as "nothing changed" and silently stops enforcing.
if ! command -v felix_changed_paths >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

# Strict JSON string escaping.
#
# Deliberately not the monitor's `_felix_json_esc`, which also escapes < and >
# for embedding in an HTML page. That is a different requirement, and each has
# exactly one caller, so these are two functions with one job each rather than
# one job with two implementations.
_felix_rcpt_esc() {
  printf '%s' "$1" \
    | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' -e 's/\r//g' \
    | tr '\n' ' '
}

# A JSON array of strings, from newline-separated input on stdin.
_felix_rcpt_arr() {
  local first=1 line
  printf '['
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    [ "$first" -eq 1 ] || printf ','
    first=0
    printf '"%s"' "$(_felix_rcpt_esc "$line")"
  done
  printf ']'
}

# Column N of a tab-separated stream, as a JSON array.
_felix_rcpt_col() {
  cut -f"$1" | _felix_rcpt_arr
}

# Rows of `a<TAB>b<TAB>c` as JSON objects under the three given key names.
#
# The third field is cut at the next tab. `risk.tsv` carries `channel` and
# `confine` after the reason, and every reader takes the reason as "the rest of
# the line", so it arrives with those columns glued on behind two tabs. A human
# report survives that. A contract with a version number on it does not: a
# consumer reading `reason` would get three fields in one string.
_felix_rcpt_rows() {
  local k1="$1" k2="$2" k3="$3" first=1 a b c
  printf '['
  while IFS=$'\t' read -r a b c; do
    [ -n "${a:-}" ] || continue
    c="${c%%	*}"
    [ "$first" -eq 1 ] || printf ','
    first=0
    printf '{"%s":"%s","%s":"%s","%s":"%s"}' \
      "$k1" "$(_felix_rcpt_esc "$a")" \
      "$k2" "$(_felix_rcpt_esc "$b")" \
      "$k3" "$(_felix_rcpt_esc "$c")"
  done
  printf ']'
}

felix_receipt() {
  local proj="$1" base="$2" root="$3" home="${4:-}"
  local unknown="" pname branch head tid

  pname="$(basename "$proj")"
  branch="$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || printf '?')"
  head="$(git -C "$root" rev-parse --short HEAD 2>/dev/null || printf '?')"
  tid="$(felix_tree_id "$root" "$home" 2>/dev/null || true)"

  # ---- what changed. An unresolvable base is a question nobody can answer, and
  # an empty list is an answer. Reporting the first as the second is the defect
  # this whole file is shaped around, so the two are different fields.
  #
  # This file had the check first, inline, and the reasoning for `^{commit}` now
  # lives with felix_base_resolves in resolve.sh — moved there rather than
  # copied, because escape.sh needed the same test and one of the two would have
  # drifted. That is #56: the identical lesson sat in felix_kernel_dir one
  # function away from felix_changed_paths and was never propagated, so an
  # unresolvable base cleared every escape channel there.
  local base_ok=0 paths=""
  if felix_base_resolves "$root" "$base"; then
    base_ok=1
    paths="$(felix_changed_paths "$root" "$base" 2>/dev/null || true)"
  else
    unknown="$unknown changed"
  fi

  # ---- risk. No table is not "no risk"; it is nothing known about risk.
  local tier="unknown" findings=""
  if [ "$base_ok" -eq 1 ] && [ -f "$proj/risk.tsv" ]; then
    findings="$(felix_classify_diff "$proj" "$base" "$root" 2>/dev/null || true)"
    tier="$(felix_classify_tier "$findings" 2>/dev/null || printf 'unknown')"
    [ -n "$tier" ] || tier="unknown"
  else
    unknown="$unknown risk"
  fi

  # ---- verification, kept separate from completion because no protocol does it
  # for us. Three states, and the difference between them is the point: `none`
  # means nothing ran, `stale` means something ran against a different tree, and
  # only `current` means this exact tree was judged.
  local vstate="none" vres="null" vwhen="null" vtree="null" rres=""
  local rec rtid
  rec="$(felix_verify_receipt "$root" "$home" 2>/dev/null || true)"
  if [ -n "$rec" ]; then
    rtid="$(printf '%s' "$rec" | cut -f1)"
    rres="$(printf '%s' "$rec" | cut -f2)"
    vres="\"$(_felix_rcpt_esc "$rres")\""
    vwhen="\"$(_felix_rcpt_esc "$(printf '%s' "$rec" | cut -f3)")\""
    vtree="\"$(_felix_rcpt_esc "$rtid")\""
    # Current only by verify.sh's reading, which also asks whether the facts
    # the verdict rests on have moved; a receipt that cannot be confirmed is
    # stale, never current, because this document may not claim more than it
    # knows. A red receipt for this exact tree still reads as current here —
    # the state says which tree was judged, and the result says how it went.
    case "$(felix_verify_current "$root" "$home" "$proj" 2>/dev/null)" in
      current) vstate="current" ;;
      red)     if [ -n "$tid" ] && [ "$rtid" = "$tid" ]; then vstate="current"; else vstate="stale"; fi ;;
      *)       vstate="stale" ;;
    esac
  fi

  # ---- evidence
  local ev="" gaps=""
  if [ "$base_ok" -eq 1 ] && [ -f "$proj/evidence.tsv" ]; then
    ev="$(felix_evidence_check "$proj" "$base" "$root" 2>/dev/null || true)"
    gaps="$(printf '%s\n' "$ev" | awk -F'\t' '$1=="gap"{print $2}')"
  fi

  # ---- authority. Carried here because no transport carries it, and refused
  # rather than assumed: anything unread means this cannot be called autonomous.
  local esc="" founder="false" autonomous="true" granted="none"
  if [ "$base_ok" -eq 1 ]; then
    esc="$(felix_escapes "$proj" "$base" "$root" "$home" 2>/dev/null || true)"
    # What granted the authority, computed rather than asserted. `granted_by`
    # was the string literal "none" and no code path ever produced anything
    # else, while the `reviewed` channel genuinely grants — it is the one place
    # in Felix where a model's output widens permission rather than narrowing it
    # (constitution invariant 2, the exception added 2026-08-12). So a receipt
    # that reached autonomous:true because a verdict cleared a red doctrine
    # surface was byte-identical to one where nothing was granted, and the only
    # field in the contract that exists to name that could never name it (#57).
    #
    # Computed by asking the same question twice rather than by re-implementing
    # the table loop. felix_escapes uses `home` for exactly one thing — the
    # review lookup — so passing an empty home yields the escape set as it would
    # be if no verdict existed. If the two differ, a verdict removed something,
    # and that difference IS the grant.
    #
    # So this says a review changed the outcome, not merely that one exists. A
    # passing verdict that cleared nothing is still "none", which is the honest
    # answer: nothing was granted.
    if [ -n "$home" ]; then
      local esc_ungranted
      esc_ungranted="$(felix_escapes "$proj" "$base" "$root" "" 2>/dev/null || true)"
      [ "$esc" = "$esc_ungranted" ] || granted="reviewed"
    fi
  fi
  # The founder is required where a channel escapes, and nowhere else: tier is
  # advice and felix merge never reads it. A red tier with no channel used to
  # set founder_required, which no merge honoured and which contradicted the
  # founder's direction that Felix merges its own pull requests. An input that
  # was never read still refuses autonomy — not knowing is not permission — but
  # it is not a claim that a person must approve.
  if [ -n "$esc" ]; then founder="true"; fi
  if [ -n "$esc" ] || [ -n "$unknown" ]; then autonomous="false"; fi

  # ---- status. Precedence is deliberate. Not knowing outranks everything,
  # because a blocked-or-verified verdict computed from inputs that were never
  # read is exactly the confident wrong answer this is built to refuse.
  local status quality
  if   [ -n "$unknown" ]; then status="indeterminate"; quality="unknown"
  elif [ -n "$esc" ];     then status="blocked";       quality="high"
  elif [ "$vstate" = "current" ] && [ "$rres" = "green" ] && [ -z "$gaps" ]; then
    status="verified"; quality="high"
  else
    status="unverified"; quality="low"
  fi

  printf '{\n'
  printf '  "schema": "felix.receipt/1",\n'
  printf '  "domain": "engineering",\n'
  printf '  "project": "%s",\n'   "$(_felix_rcpt_esc "$pname")"
  printf '  "status": "%s",\n'    "$status"
  printf '  "unknown": %s,\n'     "$(printf '%s\n' $unknown | _felix_rcpt_arr)"
  printf '  "subject": {"branch": "%s", "head": "%s", "base": "%s", "tree": "%s"},\n' \
         "$(_felix_rcpt_esc "$branch")" "$(_felix_rcpt_esc "$head")" \
         "$(_felix_rcpt_esc "$base")"   "$(_felix_rcpt_esc "$tid")"
  printf '  "changed": {"known": %s, "paths": %s},\n' \
         "$([ "$base_ok" -eq 1 ] && printf 'true' || printf 'false')" \
         "$(printf '%s\n' "$paths" | _felix_rcpt_arr)"
  printf '  "risk": {"tier": "%s", "findings": %s},\n' \
         "$tier" "$(printf '%s\n' "$findings" | _felix_rcpt_rows tier path reason)"
  printf '  "verification": {"state": "%s", "result": %s, "tree": %s, "when": %s},\n' \
         "$vstate" "$vres" "$vtree" "$vwhen"
  printf '  "evidence": {"met": %s, "gap": %s},\n' \
         "$(printf '%s\n' "$ev" | awk -F'\t' '$1=="met"{print $2}' | _felix_rcpt_arr)" \
         "$(printf '%s\n' "$gaps" | _felix_rcpt_arr)"
  printf '  "authority": {"autonomous": %s, "founder_required": %s, "granted_by": "%s", "escapes": %s},\n' \
         "$autonomous" "$founder" "$granted" \
         "$(printf '%s\n' "$esc" | _felix_rcpt_rows channel path reason)"
  printf '  "confidence": {"evidence_quality": "%s"},\n' "$quality"
  # The limit that survives every layer above it, carried by the document that
  # makes the claim rather than left in a design note beside it.
  #
  # v3.2's conformance amendments close on it: after every amendment, one
  # authority still writes both the work and the judgement of the work. Every
  # layer narrows what a model may write; none changes who writes it. And
  # enumeration is the weakest joint of any checker, because it cannot be
  # behavioural — an entrypoint never found is never executed, and nothing
  # downstream of the finding can notice that it was never found.
  #
  # "State this plainly wherever the system reports its own trustworthiness."
  # A receipt is exactly that, and it is the one that travels: it is what a
  # peer consumes, so the caveat has to travel with it or the peer reads a
  # confidence figure with no idea what bounds it.
  printf '  "limits": {"authority": "one authority writes both the work and the judgement of the work", "enumeration": "an entrypoint never found is never executed"}\n'
  printf '}\n'
}
