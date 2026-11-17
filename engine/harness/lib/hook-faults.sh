# What a hook could not judge or finish, said where the person can read it
# (audit b07). "Nothing due" and "nothing is being checked" must not look the
# same, and a stop that ended with no output, no hold and no row looked exactly
# like a session that changed nothing.
#
# Sourced by hooks/stop and hooks/user-prompt. The stop lists this file among
# the libraries it cannot do without and says so itself when it is missing, so
# nothing here has to work for that to be said.

# ----------------------------------------------------- the stop's message ----
# A stop prints one JSON object. Several branches print their own and exit, and
# a note about the stop (a prompt hook that did not finish, a let-go in the
# cloud) has to ride on whichever one runs, or stand alone when none does. So
# the first note puts the stop's stdout in a file for the rest of the run and
# an EXIT trap prints it again with the notes added as a systemMessage. A stop
# with no note runs as it always did, and this costs it nothing.
#
# A note is only ever given a place to ride, never printed ahead of what the
# stop prints: that made a hold two JSON objects, which the platform does not
# read as a hold, while the record said it was held. So when no file can be
# made anywhere, felix_stop_say says so by its status and changes nothing, and
# its caller either keeps its record for a later stop (a cut prompt hook) or,
# when the note is the stop's last word, prints it alone (felix_stop_last).
_FELIX_STOP_CAP=""; _FELIX_STOP_SAYS=""

_felix_stop_esc() {
  local s="$1"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

_felix_stop_flush() {
  local f="$_FELIX_STOP_CAP" o m
  [ -n "$f" ] || return 0
  _FELIX_STOP_CAP=""
  exec >&3 3>&-
  o="$(cat "$f" 2>/dev/null)"; rm -f "$f" 2>/dev/null
  m="$(_felix_stop_esc "$_FELIX_STOP_SAYS")"
  case "$o" in
    '')      printf '{\n  "systemMessage": "%s"\n}\n' "$m" ;;
    '{'*'}') o="${o%\}}"; o="${o%"${o##*[![:space:]]}"}"
             printf '%s,\n  "systemMessage": "%s"\n}\n' "$o" "$m" ;;
    *)       printf '%s\n{\n  "systemMessage": "%s"\n}\n' "$o" "$m" ;;
  esac
}

# The first place that takes a file: TMPDIR, then Felix's own state (where the
# stop's other records go), then /tmp. Prints its path; 1 when none does.
_felix_stop_place() {
  local d f
  for d in "${TMPDIR:-}" "${FELIX_HOME_DIR:+$FELIX_HOME_DIR/state}" /tmp; do
    [ -n "$d" ] || continue
    f="$(mktemp "$d/felix-stop.XXXXXX" 2>/dev/null)" || continue
    if [ -n "$f" ] && [ -w "$f" ]; then printf '%s' "$f"; return 0; fi
    [ -z "$f" ] || rm -f "$f" 2>/dev/null
  done
  return 1
}

felix_stop_say() {   # text: shown to the person with whatever else this stop prints; starts no model turn. 1, and nothing changed, when the stop's output has nowhere to be held
  local f
  if [ -z "$_FELIX_STOP_CAP" ]; then
    f="$(_felix_stop_place)" || return 1
    _FELIX_STOP_CAP="$f"
    exec 3>&1 >"$f"
    trap _felix_stop_flush EXIT
  fi
  _FELIX_STOP_SAYS="${_FELIX_STOP_SAYS:+$_FELIX_STOP_SAYS$'\n\n'}$1"
  return 0
}

felix_stop_last() {   # text: the stop's last word, the caller exits next. Rides on what is held, or stands alone when nothing else is printed.
  felix_stop_say "$1" && return 0
  printf '{\n  "systemMessage": "%s"\n}\n' "$(_felix_stop_esc "$1")"
}

# ------------------------------------------------ a project.json it cannot read ----
# The project is bound by its directory alone, so a project.json that is gone,
# is a pipe or a directory, or cannot be read left the gate empty, and an empty
# gate is the exit for "declares no gate". Called once the tree is known to
# hold work, and it ends the stop.
felix_stop_unjudged() {   # proj, project.json, sid, chain
  local m="Felix could not judge this stop: $2 cannot be read (it is missing, or not a regular file Felix may open), so no gate is known for this project; nothing was held."
  [ "${4:-0}" = "1" ] && exit 0
  felix_verify_log "$1" "unjudged" "" "project.json cannot be read: $2"
  felix_say "$1" "unjudged" "$m" "" "$3"
  felix_stop_last "$m"
  exit 0
}

# ------------------------------------------------------- a cloud session ----
# What the hold adds when CLAUDE_CODE_REMOTE is exactly true. The gate runs
# longer than one Bash call waits, and what the session records dies with its
# VM, so the hold names the gate by path, says to run it detached, and asks
# the session to say it if it stops without a pass.
felix_stop_cloud_note() {   # engine dir
  [ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || return 0
  printf '\n\nThis is a cloud session. The gate can run longer than one Bash call waits (ten minutes), and `felix` may not be on PATH here, so run it by path, detached, and read its log:\n\n  nohup bash %s/felix gate > /tmp/felix-gate.log 2>&1 &\n  tail -n 20 /tmp/felix-gate.log\n\nIf you stop before the gate passes on this tree, say so in your last message: nothing else records it, because what this session writes under its memory ends with the VM.' "$1"
}

felix_stop_debt() {   # proj, reason, sid: the let-go of a cloud session; a local one says nothing, as before
  local m
  [ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || return 0
  m="This cloud session was let go with the gate not passed on this tree ($2). Felix held it once and the gate did not run. The record of that sits in this session's memory, which ends with the VM, so nothing outside it says the gate has not passed on this work. Run the gate before the VM goes, or open a pull request so CI judges the branch."
  felix_say "$1" "debt" "$m" "" "$3"
  felix_stop_last "$m"
}

# ------------------------------------------------- a prompt hook cut short ----
# The platform ends a prompt hook that runs past its limit, and until now
# nothing said it had. A run puts its pid in state/prompt-start/<session>.<pid>
# on entry and takes the file away when it ends. A run that is cut off leaves
# it, and the session's next stop finds it, finds the pid gone, says so once and
# takes it away. One file a run, so a later run that ends well cannot hide an
# earlier one that did not. Not state/session/: the first mark there wins, and
# a mark is what ends the exemption for a summary request (lib/verify.sh).
_felix_ps_dir() { printf '%s/state/prompt-start' "$1"; }

felix_prompt_start() {   # home, payload
  local sid dir
  _FELIX_PS_FILE=""
  sid="$(printf '%s' "${2:-}" | LC_ALL=C sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  _felix_hold_path "${1:-}" "$sid" >/dev/null 2>&1 || return 0
  dir="$(_felix_ps_dir "$1")"
  [ -d "$dir" ] || mkdir -p "$dir" 2>/dev/null || return 0
  _FELIX_PS_FILE="$dir/$sid.$$"
  printf '%s\n' "$$" > "$_FELIX_PS_FILE" 2>/dev/null || _FELIX_PS_FILE=""
  return 0
}

felix_prompt_end() {
  [ -z "${_FELIX_PS_FILE:-}" ] || rm -f "$_FELIX_PS_FILE" 2>/dev/null
  _FELIX_PS_FILE=""
  return 0
}

# 0 when a run of this session did not finish; the records are taken away,
# unless the third argument is keep. A run whose pid still lives and whose file
# is young is still running, and is left. A pid that lives on an old file was
# reused by something else.
felix_prompt_unfinished() {   # home, sid [keep]
  local dir f pid n=0
  _felix_hold_path "${1:-}" "${2:-}" >/dev/null 2>&1 || return 1
  dir="$(_felix_ps_dir "$1")"
  for f in "$dir/$2".*; do
    [ -f "$f" ] && [ ! -L "$f" ] || continue
    pid=""; IFS= read -r pid < "$f" 2>/dev/null
    case "$pid" in
      ''|*[!0123456789]*) ;;
      *) if kill -0 "$pid" 2>/dev/null && [ -z "$(find "$f" -mmin +3 2>/dev/null)" ]; then continue; fi ;;
    esac
    [ "${3:-}" = "keep" ] || rm -f "$f" 2>/dev/null
    n=$((n + 1))
  done
  [ "$n" -gt 0 ]
}

felix_stop_unfinished() {   # proj, home, sid
  local m="Felix's prompt hook did not finish on this session's last prompt: it was cut off, most likely at the platform's 30 second limit, so that prompt may have got no route, lessons or brief. This stop was judged as usual."
  felix_prompt_unfinished "$2" "$3" keep || return 0
  # The record goes only once the note has a place to ride on the stop's one
  # object. With none, it stays, and a later stop says it; the row in says.log
  # likewise waits for a note that will be printed.
  felix_stop_say "$m" || return 0
  felix_prompt_unfinished "$2" "$3"
  felix_say "$1" "prompt-unfinished" "$m" "" "$3"
}
