# felix status's hooks row: do the checkout's own settings files switch Felix's
# hooks off (audit b04, C014; docs/2026-10-24-audit-fixes/b04-*.md B17).
#
# Claude Code reads a checkout's .claude/settings.json (committed) and
# .claude/settings.local.json (not), and either can set disableAllHooks, or set
# enabledPlugins["felix@felix"] to false, with no Felix hook left to say so: a
# stranger's repository can commit the second. For each of the two keys the local
# file wins over the project file when it holds the key, which is Claude Code's
# documented precedence. The user's own file is felix_settings_state's.
#
# Read-only: it reads two files and writes nothing. A file that cannot be read,
# a parser that is missing, a file that is not a JSON object and a value that is
# not a boolean are each `unknown` and never `clear`. What it cannot see (managed
# settings, a --settings file, --bare, an untrusted workspace) the clear detail
# says. FELIX_JQ names the parser, as the settings check's knob does. Sourced by
# lib/status.sh when the row or felix doctor needs it, never at load.

# One settings file through the parser, in one line: `object<TAB><disableAllHooks>
# <TAB><felix@felix>`, each the value's JSON, or `absent` when the file's object
# does not hold the key. `not-object` for any other top level.
_FELIX_HOOKS_JQ='if type == "object" then "object\t" + (if has("disableAllHooks") then (.disableAllHooks | tojson) else "absent" end) + "\t" + (if ((.enabledPlugins | type) == "object") and (.enabledPlugins | has("felix@felix")) then (.enabledPlugins["felix@felix"] | tojson) else "absent" end) else "not-object" end'

# Prints `<state><TAB><value><TAB><detail>` for the checkout rooted at $1.
felix_hooks_state() {   # ROOT
  local root="$1" jq="${FELIX_JQ:-jq}" pf lf f files="" out rc rest tab=$'\t' nl=$'\n'
  local pd="absent" pe="absent" ld="absent" le="absent" dah dsrc fx fsrc unread
  if [ -z "$root" ]; then printf 'unknown\t-\tthe checkout root could not be found, so its settings files are not known\n'; return 0; fi
  pf="$root/.claude/settings.json"; lf="$root/.claude/settings.local.json"
  for f in "$pf" "$lf"; do
    [ -e "$f" ] || [ -L "$f" ] || continue
    if [ ! -f "$f" ] || [ ! -r "$f" ]; then
      printf 'unknown\t-\t%s cannot be read, so whether it turns hooks off is not known\n' "$f"; return 0
    fi
    files="${files:+$files and }$f"
  done
  unread="; managed settings, a --settings file, --bare and an untrusted workspace are not read here"
  if [ -z "$files" ]; then
    printf 'value\tclear\tno project or local settings file in %s/.claude turns hooks off%s\n' "$root" "$unread"; return 0
  fi
  if ! command -v "$jq" >/dev/null 2>&1; then
    printf 'unknown\t-\tno JSON parser on this machine (jq); %s not read, so whether they turn hooks off is not known\n' "$files"; return 0
  fi
  for f in "$pf" "$lf"; do
    [ -e "$f" ] || [ -L "$f" ] || continue
    out="$("$jq" -r "$_FELIX_HOOKS_JQ" "$f" 2>/dev/null)"; rc=$?
    case "$out" in
      '' | "not-object" | *"$nl"*)
        printf 'unknown\t-\t%s does not parse as a JSON object, so whether it turns hooks off is not known\n' "$f"; return 0 ;;
    esac
    if [ "$rc" -ne 0 ]; then
      printf 'unknown\t-\t%s does not parse as a JSON object, so whether it turns hooks off is not known\n' "$f"; return 0
    fi
    case "$out" in
      "object$tab"*"$tab"*) ;;
      *) printf 'unknown\t-\tthe parser answered something this check does not know about %s, so whether it turns hooks off is not known\n' "$f"; return 0 ;;
    esac
    rest="${out#object$tab}"
    if [ "$f" = "$pf" ]; then pd="${rest%%$tab*}"; pe="${rest#*$tab}"; else ld="${rest%%$tab*}"; le="${rest#*$tab}"; fi
  done
  dah="$pd"; dsrc="$pf"; [ "$ld" = absent ] || { dah="$ld"; dsrc="$lf"; }
  fx="$pe"; fsrc="$pf"; [ "$le" = absent ] || { fx="$le"; fsrc="$lf"; }
  case "$dah" in absent|true|false) ;; *)
    printf 'unknown\t-\t%s sets disableAllHooks to %s, which this check does not read\n' "$dsrc" "$dah"; return 0 ;; esac
  case "$fx" in absent|true|false) ;; *)
    printf 'unknown\t-\t%s sets enabledPlugins["felix@felix"] to %s, which this check does not read\n' "$fsrc" "$fx"; return 0 ;; esac
  if [ "$dah" = true ]; then
    printf 'value\toff\t%s sets disableAllHooks to true: Claude Code runs no hook in a session here, Felix'\''s included\n' "$dsrc"; return 0
  fi
  if [ "$fx" = false ]; then
    printf 'value\tfelix-off\t%s sets enabledPlugins["felix@felix"] to false: Felix'\''s hooks do not load in a session here\n' "$fsrc"; return 0
  fi
  printf 'value\tclear\t%s turn no hook off%s\n' "$files" "$unread"
  return 0
}
