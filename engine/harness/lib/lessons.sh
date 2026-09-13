# Mounting the lessons.
#
# A lessons file exists to be read before implementation, and "open it when you
# are working a surface it covers" is a manual step, which means it does not
# happen. A lesson nobody reads is indistinguishable from a lesson nobody wrote.
#
# So it is mounted, not offered. The hard part is that mounting all of it is also
# a way of mounting none of it: a few hundred lines injected every turn is
# context nobody reads either, and it crowds out the thing actually being worked
# on. Relevance is what makes automatic mounting possible rather than merely
# well-intentioned.
#
# Selection is deterministic token overlap, and deliberately not clever. A
# semantic index would rank better and would make Felix depend on a per-machine
# artifact it cannot require. Under-selecting costs a lesson someone can still
# grep for; over-selecting costs attention on every single turn, which is the
# resource this whole design is trying to protect.

FELIX_LESSONS_MAX="${FELIX_LESSONS_MAX:-4}"

# Entries are L-numbered bullets, plus any section short enough to stand alone.
# Continuation lines belong to the bullet above them.
_felix_lessons_entries() {
  awk '
    /^- \*\*/ { if (buf != "") print buf; buf = $0; next }
    /^#{1,3} / { if (buf != "") print buf; buf = ""; next }
    /^[[:space:]]*$/ { if (buf != "") { print buf; buf = "" } next }
    { if (buf != "") buf = buf " " $0 }
    END { if (buf != "") print buf }
  ' "$1"
}

# The part that binds regardless of what is being touched. Every lessons file
# grows a checklist at the top, and a checklist is by definition not conditional.
felix_lessons_always() {
  local file="$1" lines="${2:-24}"
  [ -f "$file" ] || return 0
  # Everything before the first numbered lesson. Counting sections was arbitrary:
  # it happened to be right for one file and swallowed the whole lessons list in
  # a smaller one, mounting on every turn exactly what relevance exists to avoid.
  # The boundary that actually means something is where the entries begin.
  awk '/^- \*\*/ { exit } /^## / { started = 1 } started' "$file" 2>/dev/null \
    | head -"$lines"
}

# Entries overlapping the context, best first.
felix_lessons_for() {
  local file="$1" context="$2" max="${3:-$FELIX_LESSONS_MAX}"
  [ -f "$file" ] || return 0
  local words
  words="$(printf '%s' "$context" | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9_-' '\n' \
    | grep -E '^.{4,}$' \
    | grep -vE '^(this|that|with|from|have|been|will|when|what|there|their|would|could|should|about|into|then|than|they|them|your|make|does|just|also|only|some|more|most|need|want|please|help|file|code|test|tests|change|changes|update|fix|fixes)$' \
    | sort -u)"
  [ -n "$words" ] || return 0

  _felix_lessons_entries "$file" | while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    local hay score=0 w
    hay="$(printf '%s' "$entry" | tr '[:upper:]' '[:lower:]')"
    while IFS= read -r w; do
      [ -n "$w" ] || continue
      case "$hay" in *"$w"*) score=$((score+1)) ;; esac
    done <<EOF
$words
EOF
    [ "$score" -gt 0 ] && printf '%s\t%s\n' "$score" "$entry"
  done | sort -rn | head -"$max" | cut -f2- | _felix_lessons_headline
}

# A well-written lesson states itself in its first sentence and spends the rest
# on evidence. Mounting the evidence every turn is how a helpful injection
# becomes an ignored one, so only the claim is mounted; the file is one grep
# away when the evidence is wanted.
_felix_lessons_headline() {
  sed -E 's/^(- \*\*[^*]*\*\*).*/\1/' | cut -c1-240
}

# What the session is about, without asking: the prompt, what is already changed,
# and the branch name, which is usually a sentence someone wrote about intent.
felix_lessons_context() {
  local root="$1" extra="${2:-}"
  printf '%s ' "$extra"
  git -C "$root" diff --name-only 2>/dev/null | tr '\n' ' '
  git -C "$root" diff --name-only --cached 2>/dev/null | tr '\n' ' '
  git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null | tr '/-_' '   '
}
