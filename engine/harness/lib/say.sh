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

# No credential is kept. A prompt, a refused command and a reason are written
# verbatim, so a token typed into one reached the log, and the next pulse pushed
# the log to the memory remote, where history keeps it (audit b06, C080). Every
# substring in the shape bin/secret-scan reads is written as [redacted]. The
# shapes are read from that script's one definition (the line that begins
# FELIX_SCAN_PATTERNS=), so a shape added there reaches this with no second edit.
_felix_scan_re() {
  [ -z "${_FELIX_SCAN_RE:-}" ] || return 0
  local f; f="$(dirname "${BASH_SOURCE[0]:-$0}")/../bin/secret-scan"
  [ -r "$f" ] || return 1
  _FELIX_SCAN_RE="$(unset FELIX_SCAN_PATTERNS; eval "$(LC_ALL=C sed -n '/^FELIX_SCAN_PATTERNS=/{p;q;}' "$f")" 2>/dev/null; printf '%s' "${FELIX_SCAN_PATTERNS:-}")"
  [ -n "$_FELIX_SCAN_RE" ]
}

# The text with each credential-shaped substring written as [redacted], into VAR.
# Unknown is said and never passed: where the shapes cannot be read, or a grep
# cannot answer, or a substring survives the passes, VAR holds a sentence in the
# text's place and the status is 1, so nothing unredacted is handed back.
felix_redact_into() {   # VAR TEXT
  local _v="$1" _t="${2-}" _o _rc _m _i=0 _nl=$'\n' _no='[not recorded: the credential shapes could not be checked]'
  [ -n "$_t" ] || { printf -v "$_v" '%s' ""; return 0; }
  _felix_scan_re || { printf -v "$_v" '%s' "$_no"; return 1; }
  while [ "$_i" -lt 5 ]; do
    _o="$(printf '%s' "$_t" | LC_ALL=C grep -oiE -- "$_FELIX_SCAN_RE" 2>/dev/null; _rc="${PIPESTATUS[1]}"; printf '\n.%s' "$_rc")"
    _rc="${_o##*"$_nl."}"; _o="${_o%"$_nl.$_rc"}"
    case "$_rc" in
      1) printf -v "$_v" '%s' "$_t"; return 0 ;;
      0) ;;
      *) printf -v "$_v" '%s' "$_no"; return 1 ;;
    esac
    while [ -n "$_o" ]; do
      _m="${_o%%"$_nl"*}"
      case "$_o" in *"$_nl"*) _o="${_o#*"$_nl"}" ;; *) _o="" ;; esac
      [ -z "$_m" ] || _t=${_t//"$_m"/[redacted]}
    done
    _i=$((_i + 1))
  done
  printf -v "$_v" '%s' "$_no"; return 1
}

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
  # Redacted before the cause is cut to 200, so a key cannot straddle the cut.
  felix_redact_into text "$text"; felix_redact_into cause "$cause"
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$kind" "${sess:-unknown}" \
    "$(printf '%s' "$cause" | tr '\t\n' '  ' | cut -c1-200)" \
    "$(printf '%s' "$text" | sed 's/\\/\\\\/g' | awk '{printf "%s\\n", $0}')" \
    >> "$mem/says.log" 2>/dev/null || true
}
