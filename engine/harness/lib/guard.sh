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
    | LC_ALL=C sort | LC_ALL=C uniq -c \
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
# Compared by time: if a catch is newer than every lesson and devlog entry its
# owner wrote, then something failed and nobody said what it meant. An entry
# dated after now is after nothing, so a clock set back cannot settle catches
# that have not happened yet.
#
# Whose catch, though. Every session's gate appends to the one mistakes.log a
# project has, so the file's own time is whoever wrote last. Compared whole,
# a session that had recorded its lesson was asked about a peer's failure: on
# 2026-09-25 the one that merged #339 was prompted three times over a `tests`
# catch another branch logged eight minutes after its lesson.
#
# So each row now says when it was caught and which session ran the gate, and
# only this session's rows count, each at its own second. The session is the
# owner wherever the gate stood. The branch the row names was the first attempt
# at an owner, and review found it failing open on this session's own catch: a
# session gating the branch it was handed and then making its own, gating a
# second checkout, or running checkout -B, which a reflog walk over renames and
# checkouts could not follow. A row that names no session, written by an older
# engine or by a gate typed outside every session, belongs to the checkout that
# has its branch checked out now.
#
# Not whether the row's commit is in this checkout's history. The gate records
# HEAD and gates the working tree, so that commit is often the base every
# branch shares, and a detached gate on main's tip is an ancestor of every
# branch cut after it.
#
# The caller names the conversation's sessions, space separated, because one
# conversation can hold more than one: the desktop app has been seen carrying a
# conversation on under a new id, its transcript still opening under the old.
# /clear is not that. It starts a conversation with a new id and none of the
# old one's context, so a catch made before it is left to the id that made it,
# and the conversation after it is not asked to explain what it never saw.
#
# The settling side has the same owner. The lessons and the devlog are
# project-wide, and their modification times said only that somebody wrote:
# review measured the real lessons.md gaining 5 to 16 lessons a day against 2
# to 21 catches, so a peer's lesson landed within hours of nearly any catch
# and silenced it, failing open on the very catch this is for. So an entry
# settles a catch only when the catch's owner wrote it, after it. `felix
# lesson` and `felix log` put each entry's owner in written.log
# (_felix_mem_written, lib/memory.sh), and that owner is matched the way the
# catch was found to be this session's: by the session, where the catch names
# one, and by the branch, where it names none. Where it was known by neither,
# no entry settles it. An edit by hand, a consolidation rewriting lessons.md,
# and an entry from before written.log existed name no owner, and settle
# nothing.
#
# The newest catch of each kind of owner is weighed on its own, and not only
# the newest of all. A catch naming no session is settled by anyone's entry on
# its branch, so when one lands after this session's own, a peer's lesson on
# that branch settled the lot, and review showed this session's catch going
# quiet unexplained. Rows naming no session keep coming while sessions run an
# engine older than the one that files the session, and two detached checkouts
# share the branch HEAD. The newest catch still owed is the one named.
#
# Every way of not knowing errs toward asking, as the whole file did: no
# session and no checkout, one git cannot name, or a row written before rows
# carried a time, which is taken at the file's time and aged by its own date.
felix_guard_unrecorded() {
  local proj="$1" root="${2:-}" sids="${3:-}"
  local m="$(felix_mem_dir "$proj")/mistakes.log"
  local l="$(felix_mem_dir "$proj")/lessons.md"
  local w="$(felix_mem_dir "$proj")/written.log"
  [ -s "$m" ] || return 0

  local cur="" rows row at day how rb what="" owed=""
  [ -n "$root" ] && cur="$(_felix_guard_branch "$root")"
  # `at<TAB>day<TAB>how<TAB>branch<TAB>what`, one line for each way a row can
  # be this session's, holding the newest such row, the newest line first: `s`
  # known by the session it names, `b` by its branch, `-` by nothing. A time
  # is digits with no leading zero and at most twelve of them, because
  # anything else reaches shell arithmetic as an error or as octal.
  #
  # Rows, not lines: read through felix_mem_mistake_rows, because an older
  # engine's split row on an unborn HEAD is two lines, `<date>-HEAD` and
  # `?-?-<what>`, and read a line at a time neither has column four, so the
  # catch was announced with nothing named, and the second half, branch `?`,
  # is no checkout's (U44). Joined, it is one row of four fields, on branch
  # HEAD with no second and no session, judged as every such row is.
  rows="$(felix_mem_mistake_rows "$m" | awk -F'\t' -v C="$cur" -v S="$sids" '
    BEGIN { ns = split(S, sv, " "); for (i = 1; i <= ns; i++) mine[sv[i]] = 1 }
    {
      rs = ($6 == "-") ? "" : $6
      if (ns > 0 && rs != "") { if (!(rs in mine)) next; how = "s" }
      else if (C != "") { if ($2 != C) next; how = "b" }
      else how = "-"
      at = ($5 ~ /^[1-9][0-9]*$/ && length($5) <= 12) ? $5 : "-"
      what = $4; gsub(/^[ \t]+|[ \t]+$/, "", what)
      r[how] = at "\t" $1 "\t" how "\t" $2 "\t" what; n[how] = NR
    }
    END {
      for (;;) {
        k = ""; for (h in n) if (k == "" || n[h] > n[k]) k = h
        if (k == "") break
        print r[k]; delete n[k]
      }
    }
  ' 2>/dev/null)"
  [ -n "$rows" ] || return 0
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    at="${row%%$'\t'*}"; row="${row#*$'\t'}"
    day="${row%%$'\t'*}"; row="${row#*$'\t'}"
    how="${row%%$'\t'*}"; row="${row#*$'\t'}"
    rb="${row%%$'\t'*}"; row="${row#*$'\t'}"
    if _felix_guard_owed "$m" "$w" "$at" "$day" "$how" "$rb" "$sids" </dev/null; then
      what="$row"; owed=1; break
    fi
  done <<EOF
$rows
EOF
  [ -n "$owed" ] || return 0

  printf 'The gate caught something here and nothing has been written down since.\n\n'
  [ -n "$what" ] && printf '  last caught   %s\n' "$what"
  printf '  lessons       %s\n' "$l"
  printf '\nA failure nobody explains is one this project gets to have again. That is\n'
  printf 'not hypothetical: a bug was repeated here within a day because its first\n'
  printf 'fix was explained in a commit message, which nothing ever reads back.\n'
  printf '\nIf it would change what someone does next time:\n\n  felix lesson "..."\n'
  printf '\nIf it was a one-off, say so and move on — but say it:\n\n  felix log "..."\n'
  printf '\nOnly an entry written with one of those settles it, and only when written by\n'
  printf 'the session the catch is filed under (for a catch filed under no session,\n'
  printf 'on its branch). An edit to the file by hand settles nothing.\n'
}

# Whether one catch is still owed: inside its week, and settled by no entry its
# owner wrote after it. AT is its second or `-`, DAY the day its row names,
# HOW and BRANCH how it is this session's and the branch it names.
_felix_guard_owed() {
  local m="$1" w="$2" at="$3" day="$4" how="$5" rb="$6" sids="$7" cutoff mt LC_ALL=C
  if [ "$at" = "-" ]; then
    # An old debt should surface once, not forever. Past a week it is history
    # rather than something this session is in a position to explain. Aged by
    # the day the row names as well as by the file, which a peer keeps fresh,
    # and settled by an entry written on a later day than that, since the
    # catch was made by the end of it. A day that is not a date names nothing,
    # and no usable `date` means no cutoff: neither calls a row history.
    [ -n "$(find "$m" -mtime -7 2>/dev/null)" ] || return 1
    [[ "$day" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || day=""
    cutoff="$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d 2>/dev/null)"
    if [ -n "$day" ] && [ -n "$cutoff" ] && [[ "$day" < "$cutoff" ]]; then return 1; fi
    # Taken at the file's time. A file whose time cannot be read gives none,
    # rather than the epoch's first second, which every entry is after.
    mt="$(_felix_guard_mtime "$m")"; [ "$mt" -gt 0 ] || mt=""
    _felix_guard_settled "$w" "$how" "$rb" "$sids" "$mt" "$day" && return 1
  else
    # The same week, measured from the catch. An entry in the very second of
    # the catch is not taken to be after it.
    [ $(( $(date +%s) - at )) -lt 604800 ] || return 1
    _felix_guard_settled "$w" "$how" "$rb" "$sids" "$at" "" && return 1
  fi
  return 0
}

# Whether written.log holds an entry that settles the catch: written by its
# owner, and after it. HOW is how the catch was known to be this session's,
# BRANCH the branch its row names, SIDS the conversation's sessions. AFTER is
# the second the entry must be later than, and DAY, when given, a day any
# entry dated later than settles it too. An entry naming no session, `-`, is
# never a session's. A time that is not a time is after no second, though its
# row's day may still be after DAY; a time after now, or a day after today, is
# after nothing at all.
_felix_guard_settled() {
  local w="$1" how="$2" br="$3" sids="$4" after="$5" day="$6"
  [ -s "$w" ] || return 1
  case "$how" in s|b) ;; *) return 1 ;; esac
  awk -F'\t' -v H="$how" -v B="$br" -v S="$sids" -v A="$after" -v D="$day" \
      -v N="$(date +%s)" -v T="$(date +%Y-%m-%d)" '
    BEGIN { ns = split(S, sv, " "); for (i = 1; i <= ns; i++) if (sv[i] != "-") mine[sv[i]] = 1 }
    {
      if (H == "s") { if ($6 == "" || $6 == "-" || !($6 in mine)) next }
      else if ($2 != B) next
      e = ($5 ~ /^[1-9][0-9]*$/ && length($5) <= 12) ? $5 + 0 : 0
      if (e > N + 0) e = 0
      if (A != "" && e > A + 0) { found = 1; exit }
      if (D != "" && $1 ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ && $1 > D && $1 <= T) { found = 1; exit }
    }
    END { exit (found ? 0 : 1) }
  ' "$w" 2>/dev/null
}

# The branch a checkout's gate files its rows under, spelled as the writer
# spells it (felix_mem_mistake), by the writer's own reader, felix_head_branch
# in resolve.sh: the branch HEAD names, which a checkout with no commit yet
# still has, or HEAD when detached. Nothing when git cannot say, which makes
# every row that names no session count, rather than felix_head_branch's `?`
# there, which would count only the rows written outside git.
_felix_guard_branch() {
  git -C "$1" rev-parse --git-dir >/dev/null 2>&1 || return 0
  felix_head_branch "$1"
}

# A file's modification time in whole seconds. GNU first, because `stat -f` on
# GNU means --file-system and succeeds with something else entirely (verify.sh
# has the longer account). Unreadable reads 0, which settles no catch.
_felix_guard_mtime() {
  local t
  t="$(stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null)"
  case "$t" in ''|*[!0123456789]*) t=0 ;; esac
  printf '%s' "$t"
}
