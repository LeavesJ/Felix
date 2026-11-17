# felix status: ten rows a surface can poll, and the settings check the pulse
# shares.
#
# The status surface is a Claude Code mod, built outside this repository. Its
# whole contract with Felix is the TSV below; it never parses pulse.log or a
# cache file, so what a row cannot say grows a detail or a new row at the end.
#
#   <row> TAB <state> TAB <value> TAB <detail>
#
# One line per row, no header, in this order: settings, schedule, pulse, reach,
# gate, land, hooks, alerts, icloud, lane. state is value, none or unknown. value is a bare
# word (no spaces) when state is value, and `-` otherwise; detail is never
# empty. A consumer ignores rows it does not know. Weekly spend is not a row:
# felix cost has its own --tsv and takes about twenty seconds, so a surface
# runs it on its own timer.
#
# Read-only. It writes nothing, takes no network, and never runs claude, the
# suite, felix gate, claude mcp list or felix cost: every row reads a file, a
# table, a git object or launchd's own list (the land row asks launchctl print
# and lib/status-land.sh says how; the hooks row reads the checkout's two
# settings files and lib/status-hooks.sh says how). Its one slow row is the gate,
# because a receipt that matches the tree makes felix_verify_current recompute
# the decision epoch, which runs the project's probes. The CLI exports
# GIT_OPTIONAL_LOCKS=0 before any of this so git refreshes no index.
#
# Unknown is its own answer. A parser that is missing, a launchctl that cannot
# answer, a cache nobody wrote: each is `unknown` and never a zero or an ok.

# Libraries a row needs, sourced at call time and never at load: pulse.sh
# sources this file at load for the settings check, so a load-time source back
# would be a cycle. At call time every file is complete.
_felix_status_need() {
  command -v "$1" >/dev/null 2>&1 || . "$(dirname "${BASH_SOURCE[0]:-$0}")/$2.sh"
}

# Is Felix switched on in ~/.claude/settings.json? That file is what enables the
# plugin (enabledPlugins["felix@felix"]), so a broken hand edit there silently
# removes Felix, and nothing inside Felix can say so because its hooks never
# load. Prints `<value><TAB><detail>` and returns 0, always:
#   ok        parses, and enabledPlugins["felix@felix"] is true
#   felix-off parses, and that key is not true (a hook registered by hand is
#             named, since that is the other way Felix can be live)
#   hooks-off parses, and disableAllHooks is true: Claude Code runs no hook at
#             all, Felix's included. It wins over ok and felix-off. A
#             disableAllHooks that is neither true nor false is unknown.
#   invalid   does not parse, is empty, or its top level is not an object
#   missing   there is no file
#   unknown   no parser on this machine, or the file cannot be read
# ok is printed only on an answer ending in exactly `ok` from a parser that
# exited 0, so a parser that is absent, empty, stubbed or wrong can never read as
# fine. Only
# the user settings file is read (CLAUDE_CONFIG_DIR when set): a checkout's own
# settings files are the hooks row's (lib/status-hooks.sh).
# FELIX_JQ names the parser, because on macOS 15 and later jq is always on PATH
# and without a knob "no parser" could never be exercised.
felix_settings_state() {
  local f="${CLAUDE_CONFIG_DIR:-${HOME:-}/.claude}/settings.json" jq="${FELIX_JQ:-jq}" out rc first v t d=""
  local nl=$'\n' tab=$'\t' cr=$'\r'
  if [ -z "${CLAUDE_CONFIG_DIR:-}" ] && [ -z "${HOME:-}" ]; then
    printf 'unknown\tno home directory to look for settings.json in\n'; return 0
  fi
  if [ ! -e "$f" ]; then printf 'missing\t%s does not exist\n' "$f"; return 0; fi
  if [ ! -r "$f" ]; then printf 'unknown\t%s is not readable\n' "$f"; return 0; fi
  if ! command -v "$jq" >/dev/null 2>&1; then
    printf 'unknown\tno JSON parser on this machine (jq); %s was not read\n' "$f"; return 0
  fi
  out="$("$jq" -r 'if type == "object" then "object\t" + (if has("disableAllHooks") then (.disableAllHooks | tojson) else "absent" end) + "\t" + (if (try (.enabledPlugins["felix@felix"] == true) catch false) then "ok" else "felix-off \(try (.enabledPlugins["felix@felix"] | tojson) catch "null")" end) else "not-object" end' "$f" 2>&1)"; rc=$?
  if [ "$rc" -ne 0 ]; then
    first="${out%%$nl*}"; first="${first//$tab/ }"; first="${first//$cr/ }"
    printf 'invalid\t%s does not parse as JSON: %s\n' "$f" "$first"; return 0
  fi
  # An object comes back as `object<TAB><disableAllHooks's JSON or absent><TAB><the answer below>`.
  case "$out" in "object$tab"*"$tab"*)
    d="${out#object$tab}"; out="${d#*$tab}"; d="${d%%$tab*}"
    case "$d" in
      true) printf 'hooks-off\t%s sets disableAllHooks to true: Claude Code runs no hook, Felix'\''s included, unless a project'\''s own settings set it back to false\n' "$f"; return 0 ;;
      absent|false) ;;
      *) printf 'unknown\t%s sets disableAllHooks to %s, which this check does not read\n' "$f" "$d"; return 0 ;;
    esac ;;
  esac
  case "$out" in
    '')         printf 'invalid\t%s is empty\n' "$f" ;;
    not-object) printf 'invalid\t%s parses, and its top level is not an object\n' "$f" ;;
    ok)         case "$d" in absent|false) printf 'ok\t%s enables felix@felix\n' "$f" ;; *) printf 'unknown\tthe parser answered something this check does not know\n' ;; esac ;;
    "felix-off "*)
      v="${out#felix-off }"; v="${v//$tab/ }"
      t="$(cat "$f" 2>/dev/null)"
      case "$t" in
        *harness/hooks/session-start*)
          printf 'felix-off\t%s does not enable felix@felix (enabledPlugins["felix@felix"] reads %s); a session-start hook is registered by hand\n' "$f" "$v" ;;
        *)
          printf 'felix-off\t%s does not enable felix@felix (enabledPlugins["felix@felix"] reads %s)\n' "$f" "$v" ;;
      esac ;;
    *) printf 'unknown\tthe parser answered something this check does not know\n' ;;
  esac
  return 0
}

# Is the felix.pulse LaunchAgent loaded, and how did its last run end? Prints
# `<state><TAB><value><TAB><detail>`. One `launchctl list` call, read whole and
# matched on the exact label in its third field: the table's Status column is
# already decoded (negative for a signal), where `launchctl list <label>` reports
# the raw wait status, in which exit 1 is 256.
felix_schedule_state() {
  local plist="${HOME:-}/Library/LaunchAgents/felix.pulse.plist" un list line pid rest st detail value
  local tab=$'\t' nl=$'\n'
  un="$(uname 2>/dev/null)"
  if [ "$un" != "Darwin" ]; then printf 'unknown\t-\tno launchd on %s\n' "${un:-this machine}"; return 0; fi
  if [ -z "${HOME:-}" ]; then printf 'unknown\t-\tno home directory to look for the agent in\n'; return 0; fi
  if [ ! -e "$plist" ]; then
    printf 'none\t-\tno felix.pulse agent; felix pulse --install schedules one\n'; return 0
  fi
  if ! command -v launchctl >/dev/null 2>&1 || ! list="$(launchctl list 2>/dev/null)" \
     || [ "${list%%$nl*}" != "PID${tab}Status${tab}Label" ]; then
    printf 'unknown\t-\tlaunchctl could not answer\n'; return 0
  fi
  line="$(printf '%s\n' "$list" | LC_ALL=C awk -F'\t' '!f && $3 == "felix.pulse" { print; f = 1 }')"
  if [ -z "$line" ]; then
    printf 'value\tnot-loaded\tthe agent'\''s plist exists and launchd has not loaded it\n'; return 0
  fi
  pid="${line%%$tab*}"; rest="${line#*$tab}"; st="${rest%%$tab*}"
  case "$st" in
    0)
      value=loaded; detail="last exit 0" ;;
    -[123456789]*)
      case "${st#-}" in
        *[!0123456789]*) value=""; detail="launchctl reported a status this check does not read: $st" ;;
        *)        value="signal-${st#-}"; detail="loaded; the last run was stopped by signal ${st#-}" ;;
      esac ;;
    [123456789]*)
      case "$st" in
        *[!0123456789]*) value=""; detail="launchctl reported a status this check does not read: $st" ;;
        *)        value="exit-$st"; detail="loaded; the last run exited $st" ;;
      esac ;;
    *)
      value=""; detail="launchctl reported a status this check does not read: $st" ;;
  esac
  case "$pid" in ''|*[!0123456789]*) ;; *) detail="$detail; running now, pid $pid" ;; esac
  if [ -n "$value" ]; then printf 'value\t%s\t%s\n' "$value" "$detail"
  else printf 'unknown\t-\t%s\n' "$detail"; fi
  return 0
}

# Does the Felix home sit where iCloud renames files, and has it? Prints
# `<state><TAB><value><TAB><detail>` and returns 0; reads and writes nothing else.
# iCloud's Desktop & Documents sync keeps a conflicting copy of a file it saw
# change in the middle of a write as `NAME 2` (`NAME 2.ext`), and Felix writes
# refs, records and tables there: on 2026-10-14 `main 2` refs broke every clone
# and 121 `* 2` copies turned a suite part red, and nothing said why.
#   copies-N  N names under state/ and .git (objects not read) are shaped like
#             one: the last component ends in a space, digits, and either
#             nothing or a dot and more than a dot
#   synced    none, and the home's physical path is inside iCloud Drive, or
#             inside Desktop or Documents that iCloud Drive links to
#   clear     none, and it is not
#   unknown   no home; or the walk could not read every directory; or none, and
#             nothing says whether the home is synced: no HOME, or iCloud Drive cannot be entered
# Physical means every link resolved (pwd -P), so a home reached through a link
# to ~/Documents/x is inside Documents. Desktop and Documents count only when
# the iCloud Drive folder holds a LINK of that name to the same directory as the
# user's own: with sync off it holds a plain directory. The scan walks state/ and
# .git from inside the home, so a path glob in the home's own name cannot reach
# it, and it prunes .git/objects. N is every path found, files and directories,
# once each; the first three in C order are named.
felix_icloud_state() {
  local h="${1:-}" nl=$'\n' tab=$'\t' hp="" scan="" rc=x names="" n=0 list="" l f="" d a b mdp
  local c s md cdr x=""
  if [ -z "$h" ] || [ ! -d "$h" ]; then
    printf 'unknown\t-\tno Felix home resolved\n'; return 0
  fi
  case "$h" in /*) ;; *) h="./$h" ;; esac
  hp="$(cd "$h" 2>/dev/null && pwd -P)"
  [ -n "$hp" ] || hp="$h"
  scan="$(cd "$h" 2>/dev/null || { printf '\n.rc=1'; exit 0; }
          set --
          [ -d state ] && set -- state
          [ -d .git ] && set -- "$@" .git
          if [ "$#" -gt 0 ]; then
            LC_ALL=C find "$@" -path .git/objects -prune -o -name '* [0123456789]*' -print 2>/dev/null
            printf '\n.rc=%s' "$?"
          else
            printf '\n.rc=0'
          fi)"
  case "$scan" in
    *"$nl.rc="[0123456789]*) rc="${scan##*"$nl.rc="}"; names="${scan%"$nl.rc="*}" ;;
  esac
  if [ "$rc" = 0 ]; then
    names="$(printf '%s\n' "$names" \
             | LC_ALL=C awk '{ b = $0; sub(/^.*\//, "", b) } b ~ / [0123456789]+(\.[^ ]+)?$/' | LC_ALL=C sort
             [ "${PIPESTATUS[0]}${PIPESTATUS[1]}${PIPESTATUS[2]}" = 000 ] && printf '\n.')"
    case "$names" in *"$nl.") names="${names%"$nl."}" ;; *) rc=x ;; esac
  fi
  if [ "$rc" = 0 ]; then
    while IFS= read -r l; do
      [ -n "$l" ] || continue
      n=$((n + 1))
      [ "$n" -gt 3 ] || list="${list:+$list, }${l//$tab/ }"
    done <<EOF
$names
EOF
  fi
  # Where the home is. F is the folder, or empty when it is in none.
  if [ -z "${HOME:-}" ]; then
    s="whether the home is inside an iCloud-synced folder is not known: no home directory to look in"
  else
    md="$HOME/Library/Mobile Documents"; cdr="$md/com~apple~CloudDocs"
    mdp="$(cd "$md" 2>/dev/null && pwd -P)"
    if [ -n "$mdp" ]; then case "$hp" in "$mdp"/*) f="iCloud Drive" ;; esac; fi
    # Only the folder the home is in needs looking up. If iCloud Drive exists and cannot be
    # entered (Mobile Documents, or the folder in it), the link that would say is out of reach.
    for d in Documents Desktop; do
      [ -z "$f" ] || break
      b="$(cd "$HOME/$d" 2>/dev/null && pwd -P)"; [ -n "$b" ] || continue
      case "$hp" in "$b"|"$b"/*) ;; *) continue ;; esac
      if [ -d "$md" ] && { [ -z "$mdp" ] || { [ -d "$cdr" ] && [ -z "$(cd "$cdr" 2>/dev/null && pwd)" ]; }; }; then x=1; break; fi
      [ -L "$cdr/$d" ] || continue
      a="$(cd "$cdr/$d" 2>/dev/null && pwd -P)"; [ -n "$a" ] && [ "$a" = "$b" ] && f="$d"
    done
    if [ -n "$f" ]; then
      s="the home is inside iCloud-synced $f, which renames files Felix writes; a home outside Desktop, Documents and iCloud Drive avoids it"
    elif [ -n "$x" ]; then
      s="whether the home is inside an iCloud-synced folder is not known: the iCloud Drive folder could not be read"
    else
      s="the home is not inside iCloud Drive or an iCloud-synced Desktop or Documents"
    fi
  fi
  c="no name shaped like an iCloud copy under state/ and .git (objects not read)"
  if [ "$rc" != 0 ]; then
    printf 'unknown\t-\tthe scan of state/ and .git could not read every directory, so how many names are shaped like an iCloud copy is not known; %s\n' "$s"
  elif [ "$n" -gt 0 ]; then
    c="$n name(s) shaped like an iCloud copy under state/ and .git (objects not read): $list"
    [ "$n" -le 3 ] || c="$c and $((n - 3)) more"
    printf 'value\tcopies-%s\t%s; %s\n' "$n" "$c" "$s"
  elif [ -n "$f" ]; then
    printf 'value\tsynced\t%s; %s\n' "$c" "$s"
  elif [ -n "${HOME:-}" ] && [ -z "$x" ]; then
    printf 'value\tclear\t%s; %s\n' "$c" "$s"
  else
    printf 'unknown\t-\t%s; %s\n' "$c" "$s"
  fi
  return 0
}

_felix_status_utc() {
  date -u -r "$1" +%Y-%m-%dT%H:%MZ 2>/dev/null || date -u -d "@$1" +%Y-%m-%dT%H:%MZ 2>/dev/null
}

# One row, normalised: value is `-` unless state is value, detail is one line
# and never empty.
_felix_status_row() {
  local row="$1" state="$2" value="$3" detail="$4" tab=$'\t' nl=$'\n' cr=$'\r'
  [ "$state" = value ] || value="-"
  [ -n "$value" ] || value="-"
  detail="${detail//$tab/ }"; detail="${detail//$nl/ }"; detail="${detail//$cr/ }"
  [ -n "$detail" ] || detail="-"
  printf '%s\t%s\t%s\t%s\n' "$row" "$state" "$value" "$detail"
}

# Split the `<a><TAB><b>[<TAB><c>]` a state function printed and emit the row.
_felix_status_from3() {
  local row="$1" r="$2" tab=$'\t' state value detail
  state="${r%%$tab*}"; r="${r#*$tab}"; value="${r%%$tab*}"; detail="${r#*$tab}"
  case "$state" in
    value|none|unknown) _felix_status_row "$row" "$state" "$value" "$detail" ;;
    *) _felix_status_row "$row" unknown - "the $row check printed nothing this check can read" ;;
  esac
}

_felix_status_settings() {
  local r value detail tab=$'\t'
  r="$(felix_settings_state)"
  if [ -z "$r" ]; then _felix_status_row settings unknown - "the settings check could not run"; return 0; fi
  value="${r%%$tab*}"; detail="${r#*$tab}"
  case "$value" in
    ok|felix-off|hooks-off|invalid|missing) _felix_status_row settings value "$value" "$detail" ;;
    *) _felix_status_row settings unknown - "$detail" ;;
  esac
}

# Days since the memory last reached its remote (felix_pulse_backup_age: whole
# days, or never), where that copy is (state/pulse.last-push.where, written beside
# the stamp: a path on this machine is only as far from this disk as whatever
# syncs it), whether the last run left part of memory out, and when the pulse last
# ran, from the record it writes.
_felix_status_pulse() {
  local home="$1" age rec first="" ep="" last tab=$'\t' wf w="" place="" nb=""
  _felix_status_need felix_pulse_backup_age pulse
  if [ -z "$home" ] || [ ! -d "$home" ]; then
    _felix_status_row pulse unknown - "no Felix home resolved"; return 0
  fi
  rec="$home/state/pulse.status.tsv"
  if [ ! -e "$home/state/pulse.log" ] && [ ! -e "$rec" ]; then
    _felix_status_row pulse none - "the pulse has never run here"; return 0
  fi
  # Empty only when the stamp and the log are both absent, which beside a
  # record means the pulse ran and no push was ever verified.
  age="$(felix_pulse_backup_age "$home")"
  [ -n "$age" ] || age=never
  if [ -f "$rec" ] && [ -r "$rec" ]; then
    { IFS= read -r first || [ -n "$first" ]; } < "$rec" 2>/dev/null
    case "$first" in "# ran "*) ep="${first#"# ran "}" ;; esac
    case "$ep" in ''|*[!0123456789]*) ep="" ;; esac
    [ "${#ep}" -le 12 ] || ep=""
  fi
  last=""
  [ -z "$ep" ] || last="$(_felix_status_utc "$ep")"
  wf="$home/state/pulse.last-push.where"
  case "$age" in ''|*[!0123456789]*) ;; *)
    if [ -e "$wf" ]; then
      if [ -f "$wf" ] && [ -r "$wf" ]; then { IFS= read -r w || :; } 2>/dev/null < "$wf"; else w="?"; fi
      case "$w" in
        disk)    place=", a path on this machine" ;;
        network) ;;
        *)       place=", a remote whose place could not be read" ;;
      esac
    fi ;;
  esac
  if [ -f "$rec" ] && [ -r "$rec" ] && LC_ALL=C awk -F'\t' '$1 == "backup" && index($0, "NOT backed up") { f = 1 } END { exit f ? 0 : 1 }' "$rec" 2>/dev/null; then
    nb="; the last run did not back up all of memory (felix pulse says why)"
  fi
  if [ -n "$last" ]; then
    _felix_status_row pulse value "$age" "days since memory reached its remote$place$nb; last run $last"
  else
    _felix_status_row pulse value "$age" "days since memory reached its remote$place$nb; last run not recorded"
  fi
}

_felix_status_reach() {
  local proj="$1" home="$2"
  if [ -z "$proj" ]; then
    _felix_status_row reach none - "this directory is not a governed checkout"; return 0
  fi
  _felix_status_need felix_reach_summary reach
  _felix_status_from3 reach "$(felix_reach_summary "$proj" "$home")"
}

# The iCloud row: felix_icloud_state for the home, whatever it printed.
_felix_status_icloud() {
  _felix_status_from3 icloud "$(felix_icloud_state "$1")"
}

# felix_verify_current's answer, without git touching the checkout's index.
# GIT_OPTIONAL_LOCKS=0 stops git status from refreshing the index and does not
# stop git diff, which felix_tree_id runs: measured on git 2.54, a tracked file
# that is only stat-dirty (touched, not edited) has `git diff HEAD` rewrite
# .git/index under it. So when a receipt exists, and the tree id has to be
# computed, it is computed against a scratch copy of the index, removed after.
# A receipt that cannot be checked without writing the real index is not
# checked: empty output, which the caller reads as unknown.
_felix_status_verify() {
  local root="$1" home="$2" proj="$3" idx tmp="" out rc=0
  if [ -n "$(felix_verify_receipt "$root" "$home" 2>/dev/null)" ]; then
    idx="$(git -C "$root" rev-parse --git-path index 2>/dev/null)"
    case "$idx" in /*|'') ;; *) idx="$root/$idx" ;; esac
    if [ -n "$idx" ] && [ -f "$idx" ]; then
      tmp="$(mktemp "${TMPDIR:-/tmp}/felix-status-index.XXXXXX" 2>/dev/null)" || return 0
      cp "$idx" "$tmp" 2>/dev/null || { rm -f "$tmp"; return 0; }
    fi
  fi
  if [ -n "$tmp" ]; then
    out="$(GIT_INDEX_FILE="$tmp"; export GIT_INDEX_FILE; felix_verify_current "$root" "$home" "$proj" 2>/dev/null)" || rc=$?
    rm -f "$tmp"
  else
    out="$(felix_verify_current "$root" "$home" "$proj" 2>/dev/null)" || rc=$?
  fi
  printf '%s' "$out"; return "$rc"   # its status too: 2 is a git that could not run, and that row is unknown (2026-11-14)
}

# felix_verify_current's answer for the checkout: current, stale with its reason,
# red, or none-run when no gate has recorded a receipt here; no-gate when the
# project declares none, which is not a gate that has not run.
_felix_status_gate() {
  local root="$1" home="$2" proj="$3" v kind reason pj="$3/project.json" tab=$'\t' vrc=0
  if [ -z "$proj" ]; then
    _felix_status_row gate none - "this directory is not a governed checkout"; return 0
  fi
  # No gate declared is read before any receipt, with the Stop hook's own reading
  # (felix_json_str), because the Stop hook checks no stop for such a project.
  if [ ! -e "$pj" ] && [ ! -L "$pj" ]; then
    _felix_status_row gate value no-gate "$pj does not exist, so no gate is declared: the Stop hook checks no stop here"; return 0
  elif [ ! -f "$pj" ] || [ ! -r "$pj" ]; then
    _felix_status_row gate unknown - "$pj cannot be read, so whether a gate is declared is not known; the Stop hook reads no gate from it and checks no stop here"; return 0
  elif [ -z "$(felix_json_str "$pj" gate 2>/dev/null)" ]; then
    _felix_status_row gate value no-gate "${proj##*/} declares no gate in $pj: the Stop hook checks no stop here; set \"gate\" there"; return 0
  fi
  _felix_status_need felix_verify_current verify
  v="$(_felix_status_verify "$root" "$home" "$proj")" || vrc=$?
  kind="${v%%$tab*}"; reason="${v#*$tab}"
  [ "$reason" != "$v" ] || reason=""
  case "$kind" in
    current) _felix_status_row gate value current "-" ;;
    red)     _felix_status_row gate value red "the last gate run here was red" ;;
    stale)   if [ "$vrc" -eq 2 ]; then _felix_status_row gate unknown - "$reason"; else _felix_status_row gate value stale "${reason:-the receipt is not current}"; fi ;;
    none)    _felix_status_row gate value none-run "no gate has run in this checkout" ;;
    *)       _felix_status_row gate unknown - "the receipt could not be read" ;;
  esac
}

# The land row (lib/status-land.sh), under the status home (wave-1-combine C6), and the hooks row
# (lib/status-hooks.sh).
_felix_status_land() {   # PROJ HOME
  if [ -z "$1" ]; then _felix_status_row land none - "this directory is not a governed checkout"; return 0; fi
  _felix_status_need felix_lander_state status-land
  _felix_status_from3 land "$(felix_lander_state "$1" "${2:-}")"
}
_felix_status_hooks() {
  if [ -z "$1" ]; then _felix_status_row hooks none - "this directory is not a governed checkout"; return 0; fi
  _felix_status_need felix_hooks_state status-hooks
  _felix_status_from3 hooks "$(felix_hooks_state "$2")"
}

# session start's landing badge (lib/status-land.sh): `<value><TAB><detail>` when
# the land row reads paused, not-loaded, not-ticking or not-home, else nothing.
felix_land_notice() { _felix_status_need felix_lander_notice status-land; felix_lander_notice "$@"; }

# felix doctor's three lines after `project:`: the declared gate, the user's
# settings and this checkout's hooks, each label padded to 14 columns. No tr:
# the doctor's output must not depend on it.
felix_doctor_lines() {   # PROJ ROOT GATE
  local r st v d tab=$'\t'
  if [ -n "$3" ]; then printf '%-14s%s\n' 'gate:' "$3"
  else printf '%-14s%s\n' 'gate:' "none declared: no stop is checked; set \"gate\" in $1/project.json"; fi
  r="$(felix_settings_state)"
  if [ -n "$r" ]; then printf '%-14s%s: %s\n' 'settings:' "${r%%$tab*}" "${r#*$tab}"
  else printf '%-14s%s\n' 'settings:' "unknown: the settings check could not run"; fi
  _felix_status_need felix_hooks_state status-hooks
  r="$(_felix_status_from3 hooks "$(felix_hooks_state "$2")")"   # hooks TAB state TAB value TAB detail
  r="${r#*$tab}"; st="${r%%$tab*}"; r="${r#*$tab}"; v="${r%%$tab*}"; d="${r#*$tab}"
  [ "$st" = value ] || v="$st"
  printf '%-14s%s: %s\n' 'hooks:' "$v" "$d"
}

# The newest alert the lander tried to send off this Mac (lib/notify.sh, audit b05 B13), read from
# the home's project's alerts.tsv alone: no gh, no git, nothing written. A started run of the
# felix-alert workflow shows dispatched (not delivered: GitHub reports no push delivery); one the
# repository has no workflow for yet shows no-alert-workflow, the alert not sent; a failure shows its
# note. Any other state, an older "posted" too, is a record that cannot be read.
_felix_status_alerts() {
  local home="$1" p land f
  if [ -z "$home" ] || [ ! -d "$home" ]; then
    _felix_status_row alerts unknown - "no Felix home resolved"; return 0
  fi
  felix_resolve_read p "$home" "$home" 2>/dev/null; case "$?" in 0) ;;   # 2: the resolution did not finish
    1) _felix_status_row alerts unknown - "the home $home resolves no project, so no alert record was looked for"; return 0 ;;
    *) _felix_status_row alerts unknown - "the project that governs the home $home could not be resolved: a read it stands on did not finish"; return 0 ;; esac
  p="${p##*/}"; land="$(felix_mem_dir "$p")/land"; f="$land/alerts.tsv"
  if [ ! -e "$f" ]; then _felix_status_row alerts none - "no alert has been tried for $p"; return 0; fi
  if [ ! -f "$f" ] || [ ! -r "$f" ]; then _felix_status_row alerts unknown - "$f cannot be read"; return 0; fi
  _felix_status_from3 alerts "$(LC_ALL=C awk -F'\t' -v p="$p" '
    { n = NF; for (i = 1; i <= 8; i++) f[i] = $i }
    END {
      if (NR == 0) { print "none\t-\tno alert has been tried for " p; exit }
      if (n != 8 || (f[2] != "dispatched" && f[2] != "no-alert-workflow" && f[2] != "failed")) { print "unknown\t-\tthe newest alert record of " p " cannot be read"; exit }
      w = f[1] " " f[3]; if (f[4] != "-") w = w " #" f[4]
      if (f[2] == "failed") { print "value\tfailed\t" w " " f[7]; exit }
      if (f[2] == "no-alert-workflow") { print "value\tno-alert-workflow\t" w ": the alert was not sent: .github/workflows/felix-alert.yml is not on the repository yet, so it waits until the founder merges it"; exit }
      print "value\tdispatched\t" w " " f[6] }' "$f" 2>/dev/null)"
}

# The ten rows for the directory <cwd> under the Felix home <home>.
felix_status_rows() {
  local home="$1" cwd="$2" root proj lproj prc rrc pst r u="could not be resolved: a read it stands on did not finish"
  _felix_status_need felix_resolve_read resolve; root="$(felix_repo_root "$cwd" 2>/dev/null; printf '/%s' "$?")"; rrc="${root##*/}"; root="${root%/*}"
  felix_resolve_read proj "$cwd" "$home" 2>/dev/null; pst=$?   # the nine rows' project, before any lane code runs; 2: it did not finish
  _felix_status_settings
  _felix_status_from3 schedule "$(felix_schedule_state)"
  _felix_status_pulse "$home"
  for r in reach gate land hooks; do case "$pst:$rrc:$r" in   # unknown when the project did not resolve, or the root gate and hooks read
    2:*) _felix_status_row "$r" unknown - "the project that governs $cwd $u"; continue ;; 0:0:*|0:*:reach|0:*:land) ;;
    0:*) _felix_status_row "$r" unknown - "the checkout root of $cwd ${u/resolved/read}"; continue ;; esac
    case "$r" in reach) _felix_status_reach "$proj" "$home" ;; gate) _felix_status_gate "$root" "$home" "$proj" ;; land) _felix_status_land "$proj" "$home" ;; *) _felix_status_hooks "$proj" "$root" ;; esac; done
  _felix_status_alerts "$home"
  _felix_status_icloud "$home"
  _felix_status_need felix_lane_resolve lane-resolve; _felix_status_need felix_lane_status_row lane
  lproj="$(felix_lane_resolve "$cwd" "$home")"; prc=$?; [ "$prc" -eq 0 ] || lproj=""   # only the lane row reads the lane's resolution (C6); 2: it did not finish
  felix_lane_status_row "$lproj" "$root" "$prc"
}

# felix status [--tsv]: the rows as written, or aligned for a person, with the
# value shown when there is one and the state word otherwise. No header.
felix_status_command() {
  local home="$1" cwd="$2" tsv="${3:-0}" lrc rrc pst
  if [ "$tsv" -eq 1 ]; then felix_status_rows "$home" "$cwd"; return 0; fi
  felix_status_rows "$home" "$cwd" | { seen=0
    while IFS=$'\t' read -r row state value detail; do
      [ -n "$row" ] || continue
      [ "$row" != lane ] || seen=1
      [ "$state" = value ] || value="$state"
      printf '%-9s %-12s %s\n' "$row" "$value" "$detail"
    done
    [ "$seen" -eq 1 ]; }
  # A fork that fails ends the pipe's left shell (128, or 1 in a substitution) with the rows not yet printed lost:
  # 128, or no lane row (the right side's 1), is this command's status too, as in --tsv. A reader that closes early is not.
  pst=("${PIPESTATUS[@]}"); lrc="${pst[0]}"; rrc="${pst[1]:-1}"
  [ "$lrc" -ne 128 ] && [ "$rrc" -ne 1 ] || return 128
  return 0
}
