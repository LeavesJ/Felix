# Noticing when somebody else's plugin is breaking the session.
#
# A plugin that ships hooks is a dependency on that plugin working. When one
# fails it does not fail quietly in its own corner: a PreToolUse hook that
# refuses stops the edit, and the reason surfaces as an error against the tool
# rather than against the plugin that caused it. The obvious reading is that
# the editor is broken.
#
# That is not hypothetical here. A security plugin installed on request began
# refusing every Write and Edit because it was not signed in, and the way to
# find out was to fail a dozen times and go looking. Switching it off is the
# cure and only takes effect next session, which is worth saying out loud
# rather than letting someone discover it by retrying.
#
# Claude Code records these properly, so this is reading rather than guessing:
# an attachment of type hook_blocking_error carrying hookName, hookEvent and
# the message. Read with grep at the finish line, where the count is already
# known and nothing is waiting on it.

# count <TAB> hook <TAB> message, worst first.
felix_guard_blocks() {
  local transcript="$1"
  [ -n "$transcript" ] && [ -f "$transcript" ] || return 0
  # Line-oriented. Carving the attachment object out with a brace-bounded
  # pattern matched nothing: the record nests an object inside itself and
  # escapes quotes inside the recorded command, so counting braces gets it
  # wrong. One record per line is what the transcript already guarantees.
  grep 'hook_blocking_error' "$transcript" 2>/dev/null \
    | sed -n 's/.*"hookName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*"blockingError"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1\t\2/p' \
    | LC_ALL=C sort | uniq -c \
    | sed -E 's/^[[:space:]]*([0-9]+)[[:space:]]+/\1\t/' \
    | LC_ALL=C sort -k1,1nr
}

# Which installed plugin most likely produced a message.
#
# The recorded command holds ${CLAUDE_PLUGIN_ROOT} unexpanded, so it names no
# plugin. The message usually does — "Not logged into Semgrep Guardian" — so
# this matches installed names against it and says nothing when unsure. A wrong
# name here would send someone to disable the wrong thing.
felix_guard_culprit() {
  local msg="$1" hay name
  hay="$(printf '%s' "$msg" | tr '[:upper:]' '[:lower:]')"
  felix_ready_inventory 2>/dev/null | cut -f2 | while IFS= read -r name; do
    [ -n "$name" ] || continue
    case "${#name}" in 1|2|3) continue ;; esac
    case "$hay" in *"$name"*) printf '%s\n' "$name"; return 0 ;; esac
  done | head -1
}

# Whether a blocking message is Felix's own.
#
# The report that consumes this exists to name a hook belonging to ANOTHER
# plugin, and it never checked. Felix's own Stop hook holds a chain until the
# gate has seen the tree — working exactly as designed — and that block was
# handed to the founder under the headline "and it was not Felix", attributed to
# the felix plugin two lines below, with the remedy `felix quarantine felix`.
# A report contradicting itself within four lines, whose advice is to switch off
# the system that produced it. It fired twice in the session that fixed it.
#
# Two independent tests, because either alone misses. Felix's refusals name one
# of its own commands or the variable that releases them, which no other
# plugin's message would; and the culprit resolver already matches installed
# plugin names against the text, so it answers `felix` when the prose does not.
#
# Failing toward "own" is the safe direction. A false positive costs one missed
# report about another plugin; a false negative sends somebody to disable Felix.
felix_guard_is_own() {
  local msg="$1" hay
  [ -n "$msg" ] || return 1
  hay="$(printf '%s' "$msg" | tr '[:upper:]' '[:lower:]')"
  case "$hay" in
    *felix_allow_red*|*"felix gate"*|*"felix quarantine"*|*"felix which"*|\
    *"felix merge"*|*"felix:"*) return 0 ;;
  esac
  [ "$(felix_guard_culprit "$msg" 2>/dev/null)" = "felix" ]
}

# ------------------------------------------------- a debt nobody recorded ---
#
# Felix has had `felix lesson` and `felix log` from the beginning, and having a
# mechanism is not the same as using it. Sixty commits were made in one day
# with an empty devlog, and the one bug repeated that day was repeated
# precisely because its first fix was explained in a commit message rather than
# in the file that gets mounted.
#
# So the discipline stops depending on memory. Not on every session — most
# sessions teach nothing, and a prompt that fires every time is one people
# learn to dismiss. Only when the gate actually caught something and nothing
# was written down since.
#
# Compared by modification time, which needs no state and cannot drift: if the
# record of failures is newer than both the lessons and the devlog, then
# something failed and nobody said what it meant.
felix_guard_unrecorded() {
  local proj="$1"
  local m="$(felix_mem_dir "$proj")/mistakes.log"
  local l="$(felix_mem_dir "$proj")/lessons.md"
  local d="$(felix_mem_dir "$proj")/DEVLOG.md"
  [ -s "$m" ] || return 0

  # An old debt should surface once, not forever. Past a week it is history
  # rather than something this session is in a position to explain.
  [ -n "$(find "$m" -mtime -7 2>/dev/null)" ] || return 0

  if [ -f "$l" ]; then
    [ -n "$(find "$m" -newer "$l" 2>/dev/null)" ] || return 0
  fi
  if [ -f "$d" ] && [ -s "$d" ]; then
    [ -n "$(find "$m" -newer "$d" 2>/dev/null)" ] || return 0
  fi

  local what
  what="$(tail -1 "$m" | cut -f4 | tr -d '[:space:]')"
  printf 'The gate caught something here and nothing has been written down since.\n\n'
  [ -n "$what" ] && printf '  last caught   %s\n' "$what"
  printf '  lessons       %s\n' "$l"
  printf '\nA failure nobody explains is one this project gets to have again. That is\n'
  printf 'not hypothetical: a bug was repeated here within a day because its first\n'
  printf 'fix was explained in a commit message, which nothing ever reads back.\n'
  printf '\nIf it would change what someone does next time:\n\n  felix lesson "..."\n'
  printf '\nIf it was a one-off, say so and move on — but say it.\n'
}
