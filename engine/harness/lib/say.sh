# What Felix actually said, kept verbatim.
#
# Everything Felix tells a session goes out as additionalContext, which reaches
# the model and never the terminal. That is the correct channel — it is an
# instruction, not an announcement — and it means the founder has no way of
# knowing what their governance layer is saying on their behalf. The logs
# recorded decisions: which route fired, what the score was. They did not record
# the words, so "why did Claude suddenly start using that skill" was
# unanswerable from anything Felix kept.
#
# So the speech is kept. One line per utterance, newlines escaped, because a
# record you cannot grep is a record that gets read once.

# The prompt that caused it is recorded, not inferred.
#
# The first version left it out and the page paired each utterance with the
# nearest prompt by timestamp. Two prompts arriving in the same second are
# indistinguishable that way, and the page confidently attributed a frontend
# briefing to a question about permutation tests. The hook already holds the
# prompt; guessing at what it already knows is how a record becomes fiction.
#
# The session is recorded so the page can show the one you are in and file the
# rest. Without it every utterance Felix has ever made shares one undifferentiated
# feed, and "what is happening right now" is unanswerable.
#
# proj, kind, text, [what caused it], [session]
felix_say() {
  local proj="$1" kind="$2" text="$3" cause="${4:-}" sess="${5:-}"
  [ -n "$text" ] || return 0
  local mem; mem="$(felix_mem_dir "$proj")"
  [ -d "$mem" ] || mkdir -p "$mem" 2>/dev/null || return 0
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$kind" "${sess:-unknown}" \
    "$(printf '%s' "$cause" | tr '\t\n' '  ' | cut -c1-200)" \
    "$(printf '%s' "$text" | sed 's/\\/\\\\/g' | awk '{printf "%s\\n", $0}')" \
    >> "$mem/says.log" 2>/dev/null || true
}
