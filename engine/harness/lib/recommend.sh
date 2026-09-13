# Advisory tooling recommendations.
#
# Section 1 of the guidebook wants a router that decides which capabilities
# become active for a task. Claude Code has no runtime switch for mounting and
# unmounting an MCP mid-session, so a router that claimed to do it would be
# theatre. Advisory is the honest shape: Felix says what this project's stack
# implies, and a person or a session decides.
#
# Felix recommends only from its own catalogue, which is small and deliberately
# so. For anything beyond it there is already a skill that does this properly,
# with far broader knowledge than a fifteen-row table. Rather than reimplement a
# worse version, Felix hands off, and hands off with the facts it already
# established so the recommender is not re-deriving the ecosystem, the
# capabilities, or what is already mounted.
#
# Everything here reports. Nothing installs.

# Catalogue rows this project has not declared, with the reason each applies.
felix_recommend_missing() {
  local proj="$1" tpl="$2"
  [ -f "$tpl/catalog.tsv" ] || return 0
  while IFS=$'\t' read -r kind name src risk cap kw; do
    [ -n "${kind:-}" ] || continue
    grep -qF "	$name	" "$proj/stack.tsv" 2>/dev/null && continue
    printf '%s\t%s\t%s\t%s\n' "$kind" "$name" "$risk" "${cap:-always}"
  done <<EOF
$(grep -vE '^\s*(#|$)' "$tpl/catalog.tsv")
EOF
}

# Free-text intent against the catalogue. Word-level matching against name,
# capability and keywords, scored by how many of the asked-for words hit.
#
# Crude on purpose. A fuzzy matcher that guessed confidently would recommend
# tooling nobody asked for, and the failure mode of recommending too little is a
# person asking again.
felix_recommend_intent() {
  local tpl="$1" want="$2"
  [ -f "$tpl/catalog.tsv" ] || return 0
  local words; words="$(printf '%s' "$want" | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9' '\n' | grep -vE '^(a|an|the|for|and|with|to|of|i|we|need|want|some|my|our|use|using)$' \
    | grep -E '^.{3,}$' | sort -u)"
  [ -n "$words" ] || return 0
  while IFS=$'\t' read -r kind name src risk cap kw; do
    [ -n "${kind:-}" ] || continue
    local hay score=0 w
    hay="$(printf '%s %s %s' "$name" "${cap:-}" "${kw:-}" | tr '[:upper:]' '[:lower:]')"
    while IFS= read -r w; do
      [ -n "$w" ] || continue
      case "$hay" in *"$w"*) score=$((score+1)) ;; esac
    done <<EOF
$words
EOF
    [ "$score" -gt 0 ] && printf '%s\t%s\t%s\t%s\t%s\n' "$score" "$kind" "$name" "$risk" "${cap:-always}"
  done <<EOF
$(grep -vE '^\s*(#|$)' "$tpl/catalog.tsv")
EOF
}
