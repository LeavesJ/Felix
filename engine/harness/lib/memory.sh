# Project memory: the devlog, the lessons, the handoff.
#
# The guidebook's promotion ladder (p4) routes a one-off to the handoff, a
# recurring lesson to the lessons file, a repeated rule violation into the
# constitution, and a repeatable procedure into a skill.
#
# Most projects have none of these files, and the reason is friction rather than
# disagreement: everyone believes in a devlog and nobody opens an editor at the
# end of a session to write one. So the first job here is not analysis, it is
# making the entry one command, with the branch and commit filled in.
#
# Promotion detection is a prompt, never a conclusion. Recurrence is a hint that
# something might be a lesson; deciding whether it is durable takes judgment, and
# a tool that auto-promoted would fill the lessons file with noise and teach
# people to stop reading it. The value of a lessons file is entirely in its
# signal-to-noise, so the failure mode of writing too much is the fatal one.

# Where a memory row was written, spelled one way for every row that says so: a
# devlog header, a gate's catch, the owner of a lesson. The branch is the one
# HEAD names, which a checkout with no commit yet still has, HEAD when detached
# and ? outside git; the commit is `unborn` when there is none yet and ? outside
# git. `rev-parse --abbrev-ref` prints HEAD and then fails in a checkout with no
# commit yet, and its fallback wrote a second line into whatever it was part of.
#
# Both come from felix_head_branch and felix_head_commit in resolve.sh, which
# this file already needs for felix_mem_dir. They were written here first and
# moved, not copied, when receipt.sh held the same defect and could not reach
# them: a fallback is assigned and never appended. The second pair this file
# grew for written.log's owner rows is gone, so a catch and the entry that
# settles it are never spelled by two readers that drift apart (the guard reads
# a branch back through the same one, _felix_guard_branch, lib/guard.sh). They
# differed in one place: with no commit yet the commit was `?` here and is
# `unborn` in resolve.sh, felix_tree_id's word for that state. That one stays,
# so every row on such a tree is one occasion to felix_mem_recurring_mistakes;
# the guard matches a row by branch and session, never by commit.
_felix_mem_stamp() {
  local root="$1"
  printf '%s %s %s' \
    "$(date +%Y-%m-%d)" \
    "$(felix_head_branch "$root")" \
    "$(felix_head_commit "$root")"
}

# The session the platform exports to this shell, which a subagent's shell
# inherits from its parent. A dash when there is none, or when the id holds
# anything that could break a row.
_felix_mem_sid() {
  local sid="${CLAUDE_CODE_SESSION_ID:-}" LC_ALL=C
  case "$sid" in ''|*[!A-Za-z0-9._-]*) sid=- ;; esac
  printf '%s' "$sid"
}

felix_mem_log() {
  local proj="$1" root="$2" text="$3"
  mkdir -p "$(felix_mem_dir "$proj")"
  printf '\n## %s\n\n%s\n' "$(_felix_mem_stamp "$root")" "$text" >> "$(felix_mem_dir "$proj")/DEVLOG.md" || return 1
  _felix_mem_written "$proj" "$root" log || return 2
}

felix_mem_lesson() {
  local proj="$1" root="$2" text="$3"
  mkdir -p "$(felix_mem_dir "$proj")"
  printf '\n- **%s** %s\n' "$(date +%Y-%m-%d)" "$text" >> "$(felix_mem_dir "$proj")/lessons.md" || return 1
  _felix_mem_written "$proj" "$root" lesson || return 2
}

# Who wrote each lesson and devlog entry, and when: one row per entry in
# written.log, in mistakes.log's shape with the kind where the checks go.
# felix_mem_lesson and felix_mem_log return 1 when the entry itself was not
# written and 2 when it was but this row was not, so the command can say the
# entry is there and must not be written twice.
#
# felix_guard_unrecorded lets an entry settle only the catches of whoever wrote
# it (its session, or for a catch filed under no session its branch), and
# neither file can say who that was. lessons.md is prose mounted into
# sessions and names only the day; a devlog header names the day and the
# branch, never the second or the session. Their modification times say only
# that somebody wrote, and on a project with many sessions somebody always
# has: review measured the real lessons.md gaining 5 to 16 lessons a day
# against 2 to 21 catches, so a peer's lesson landed within hours of nearly
# every catch and silenced it. So the prose stays exactly as it was and the
# owner is written beside it.
_felix_mem_written() {
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$(date +%Y-%m-%d)" "$(felix_head_branch "$2")" "$(felix_head_commit "$2")" "$3" "$(date +%s)" "$(_felix_mem_sid)" \
    >> "$(felix_mem_dir "$1")/written.log"
}

# Regenerate the handoff from what git already knows. A handoff written by hand
# is a handoff written optimistically: it records what someone meant to have
# done. This records the branch, the head, what is uncommitted, and the command
# to pick up with.
# The one line git cannot tell you was also the one line this command erased.
# It regenerates the whole file, so anybody who filled in "what was in progress"
# lost it the next time anything ran — and the mechanical half, which git can
# reconstruct at any moment, survived. Now the note is passed in, or carried
# forward from the file being replaced.
#
# And it replaces only what it wrote. A handoff written by hand — 212,864 bytes
# of one, with no "Regenerated" line, in a memory directory another checkout's
# docs/ symlinks into — would have been truncated to about 565 bytes of git
# state by one run of this, and the next pulse commit would have buried the
# original. So a file that is neither empty (the placeholder `felix new`
# writes) nor in the generated shape is refused, with its size named, unless
# REPLACE is 1, which is what --replace passes.
#
# The write lands beside the file and is renamed over it, so a write that
# fails part way leaves the old handoff whole rather than truncated. Three
# things the redirection did for free are kept by hand:
#   - A handoff that is a symlink, or a chain of them, is written through to
#     the file at the end, each hop read relative to the link it came from.
#     Renamed onto a link, the link would become a regular file and its target
#     would go stale without a word.
#   - The mode is carried across, because a rename puts a new file in place
#     and a handoff somebody closed to other users should stay closed.
#   - The text is built before the temporary file exists, so that file lives
#     only between one printf and the rename. The git calls are the slow part
#     and the part a person interrupts, and a temporary file stranded there
#     would be committed by the next pulse.
felix_mem_handoff() {
  local proj="$1" root="$2" gate="$3" note="${4:-}" replace="${5:-0}"
  local f dest link hops=0 body tmp
  mkdir -p "$(felix_mem_dir "$proj")"
  f="$(felix_mem_dir "$proj")/SESSION_HANDOFF.md"
  if [ "$replace" != 1 ] && felix_mem_handoff_foreign "$f"; then
    printf 'felix handoff: not replacing %s, %s bytes that felix handoff did not write:\n' \
      "$f" "$(wc -c < "$f" | LC_ALL=C tr -d ' ')" >&2
    printf 'it does not open with the header this command writes, "# Handoff" and then\n' >&2
    printf '"Regenerated <date>." on the third line. Move it aside, or pass --replace to\n' >&2
    printf 'overwrite it with the regenerated handoff.\n' >&2
    return 1
  fi
  if [ -z "$note" ] && [ -f "$f" ]; then
    note="$(LC_ALL=C sed -n 's/^- what was in progress: //p' "$f" | head -1)"
    case "$note" in _fill*) note="" ;; esac
  fi
  body="$(_felix_mem_handoff_text "$root" "$gate" "$note")"
  dest="$f"
  while [ -L "$dest" ] && [ "$hops" -lt 16 ]; do
    link="$(readlink "$dest")"
    case "$link" in /*) dest="$link" ;; *) dest="${dest%/*}/$link" ;; esac
    hops=$((hops + 1))
  done
  tmp="${dest}.tmp.$$"
  # Copied first only for its mode; the redirection below replaces the text.
  [ -f "$dest" ] && cp -p "$dest" "$tmp" 2>/dev/null
  # The substitution dropped the one newline the last printf ended with.
  printf '%s\n' "$body" > "$tmp" || { rm -f "$tmp"; return 1; }
  mv -f "$tmp" "$dest" || { rm -f "$tmp"; return 1; }
}

# The tracked changes of ROOT, one per line, into VAR (empty when clean). Porcelain
# with no untracked files prints no branch line whatever status.branch says.
# Returns 1 when git did not finish (it exits non-zero, or ROOT is no repository),
# VAR holding why: git's first error: or fatal: line, else "git status did not finish".
_felix_mem_tree() {
  local o w
  _felix_git_read o git -C "$2" status --porcelain --untracked-files=no && { printf -v "$1" '%s' "$o"; return 0; }
  w="$(LC_ALL=C git -C "$2" status --porcelain --untracked-files=no 2>&1 >/dev/null | LC_ALL=C awk '!p && /^(error|fatal): / { print; p = 1 }')" || :
  printf -v "$1" '%s' "${w:-git status did not finish}"; return 1
}

# The text of a regenerated handoff, from what git knows of ROOT. A function of
# its own so the caller can build it before any file exists: written inline in
# a command substitution, bash 3.2 misreads the apostrophes in its comments.
_felix_mem_handoff_text() {
  local root="$1" gate="$2" note="$3"
  printf '# Handoff\n\nRegenerated %s. Anything below is the state of the tree,\nnot a summary of intent.\n\n' "$(date +%Y-%m-%d)"
  printf '## Where\n\n'
  # The same reader as the row below: this line printed git's answer as the
  # branch, and on an unborn HEAD that answer is `HEAD`, git's word for having
  # no commit to abbreviate. A handoff is written exactly there at commission.
  printf -- '- branch: `%s`\n' "$(felix_head_branch "$root")"
  printf -- '- head: `%s`\n' "$(git -C "$root" log -1 --format='%h %s' 2>/dev/null)"
  printf -- '- tree: `%s`\n' "$root"
  printf '\n## Uncommitted\n\n'
  local dirty; if ! _felix_mem_tree dirty "$root"; then printf 'Whether the tree is clean is not known: %s\n' "$dirty"
  elif [ -n "$dirty" ]; then printf '```\n%s\n```\n' "$dirty"
  else printf 'Nothing. The tree is clean.\n'; fi
  printf '\n## Recent\n\n```\n%s\n```\n' \
    "$(git -C "$root" log -8 --format='%h %ad %s' --date=short 2>/dev/null)"
  printf '\n## Next\n\n'
  # The command, not the key. `verify: gate.sh` was project.json's gate value
  # copied verbatim, and there is no gate.sh at any root a session would look
  # in; the command that runs it is felix gate, and that is what is printed.
  if [ -n "$gate" ]; then printf -- '- verify: `felix gate` (runs `%s`)\n' "$gate"
  else printf -- '- verify: declare a gate in project.json, then `felix gate`\n'; fi
  if [ -n "$note" ]; then
    printf -- '- what was in progress: %s\n' "$note"
  else
    printf -- '- what was in progress: _fill this in with `felix handoff --was "..."`; it is the one part git cannot tell you_\n'
  fi
}

# The shape every version of felix_mem_handoff has written: `# Handoff` alone on
# the first line, and `Regenerated <date>.` opening the third. Two exact lines
# rather than the word found anywhere, because a hand-written handoff can say
# "regenerated" and still be the only copy of what it holds. What sits below
# the header may have been edited by hand, and is replaced as it always was.
_felix_mem_handoff_generated() {
  [ "$(sed -n 1p "$1")" = "# Handoff" ] || return 1
  # Read, then matched, not piped into grep -q, whose early exit can kill the
  # writer and have pipefail read a match as none.
  local l3; l3="$(sed -n 3p "$1")" || return 1
  grep -qE '^Regenerated [0-9]{4}-[0-9]{2}-[0-9]{2}\.' <<<"$l3"
}

# 0 when the handoff at F is one this command did not write: not the empty
# placeholder, and not in the generated shape. felix_mem_handoff refuses
# exactly these unless told to replace them. Named apart so that felix handoff
# can ask the same question before the write, which is the only moment the
# answer can be had, and record whether it refused or replaced.
felix_mem_handoff_foreign() {
  [ -s "$1" ] && ! _felix_mem_handoff_generated "$1"
}

# A mistake the gate caught, recorded without anyone deciding it was worth
# recording. Judgement at write time is the wrong shape: it asks for a decision
# at the exact moment someone is trying to finish something else, so it does not
# happen, and the lesson is lost while the file stays tidy.
#
# Write cheaply, consolidate on a cadence. The maintenance routine does the
# curating with the whole file in view, which is when the judgement is actually
# available.
#
# One row per call, six fields, whatever git or the caller hands over: the
# branch and commit come through resolve.sh's two readers, and `what` has any
# tab or newline turned into the space that already separates the checks it
# names.
#
# The fifth and sixth columns are the second it was caught and the session
# whose gate caught it. Every session on the project appends here, so the
# file's own time is whoever wrote last, and felix_guard_unrecorded needs both
# to tell this session's catch from a peer's. The session is the one the
# platform exports to the gate's shell, which a subagent's shell inherits from
# its parent; a dash when there is none, or when the id holds anything that
# could break the row. Appended last, so every reader of the first four is
# unchanged. The branch, commit and session are spelled by the same readers
# as the owner of a lesson (_felix_mem_written above), so the guard can match
# the one against the other.
#
# The append is made holding the log's lock, the one felix_mem_mistakes_heal
# below takes to rewrite the file, so a row written by this engine can never
# land on the inode a heal is about to rename away (U44). The fields are read
# before the lock, because the git calls are the slow part, and so the second
# is the one the gate caught it in rather than the one the lock was won in.
# The wait is bounded, about three seconds, and then the row is appended
# anyway: a lock is there to protect rows, and one that could cost a row would
# be the defect it exists to prevent. The heal's tail recovery picks up an
# unlocked append in all but a microsecond window. The first four fields are
# byte for byte what #267 writes, and a heal passes a row of five or six
# fields through byte for byte: it joins only the split pair an older engine
# left, which is four fields once joined.
#
# Curated means rewritten by hand or by a session, so its last line can arrive
# without a newline. This row then fused onto it, and `cut -f4` and the
# ranking's $4 read neither mistake (2026-10-01). Ended first, under the same
# lock; a log that cannot be ended takes no row, as one that cannot be written
# takes none.
felix_mem_mistake() {
  local proj="$1" root="$2" what="$3" dir d b c w at sid held=0 tries=0 rc
  dir="$(felix_mem_dir "$proj")"
  mkdir -p "$dir"
  d="$(date +%Y-%m-%d)"
  b="$(felix_head_branch "$root")"
  c="$(felix_head_commit "$root")"
  w="$(printf '%s' "$what" | tr '\t\n\r' '   ')"
  at="$(date +%s)"
  sid="$(_felix_mem_sid)"
  while [ "$tries" -lt 30 ]; do
    if _felix_mem_lock "$dir/.mistakes.lock"; then held=1; break; fi
    sleep 0.1
    tries=$((tries + 1))
  done
  if felix_end_line "$dir/mistakes.log"; then
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$d" "$b" "$c" "$w" "$at" "$sid" >> "$dir/mistakes.log"; rc=$?
  else
    rc=1
  fi
  [ "$held" -eq 1 ] && _felix_mem_unlock "$dir/.mistakes.lock"
  return "$rc"
}

# The mistakes log's lock: a directory, `<memory>/.mistakes.lock`, holding one
# file, `pid`, with the owner's pid. The name is a contract, because the suite
# makes one by hand to stand in for a holder.
#
# The shape of felix_commission_lock, and for its reason: mkdir is atomic
# everywhere, and a lock left by a killed process must not stand forever. So a
# lock is stale, and taken over, when its pid names a process that is gone, or
# when the directory is more than a minute old whatever it holds. The age rule
# covers what a pid cannot: a pid the system has since reused, and a holder
# that died between the mkdir and writing its pid. Nothing that takes this lock
# holds it for more than the few milliseconds a rename or an append costs.
# Anything else is live, a lock with no pid included while it is young, because
# its owner may be between the two steps. Losing the race to take over a stale
# lock means someone else holds it now, and that is live too.
#
# Two takers can still both see one stale lock and both take it over, the
# window every mkdir lock with takeover has. What that costs here is bounded:
# two appends interleave safely under O_APPEND, and two heals are kept apart
# by the heal's own `-ef` check, not by this lock.
_felix_mem_lock() {   # lock-dir -> 0 taken, 1 held by a live owner
  local lock="$1" owner stale=0
  if mkdir "$lock" 2>/dev/null; then
    printf '%s\n' "$$" > "$lock/pid" 2>/dev/null
    return 0
  fi
  [ -d "$lock" ] || return 1
  # Read only as a regular file, as _felix_mem_unlock reads it (2026-10-08);
  # otherwise no owner, and the age rule below decides.
  owner=""
  [ -f "$lock/pid" ] && owner="$(head -n 1 "$lock/pid" 2>/dev/null)"
  case "$owner" in
    ''|*[!0123456789]*) ;;
    *) kill -0 "$owner" 2>/dev/null || stale=1 ;;
  esac
  if [ "$stale" -eq 0 ] && [ -n "$(find "$lock" -maxdepth 0 -mmin +1 2>/dev/null)" ]; then
    stale=1
  fi
  [ "$stale" -eq 1 ] || return 1
  rm -rf "$lock" 2>/dev/null
  if mkdir "$lock" 2>/dev/null; then
    printf '%s\n' "$$" > "$lock/pid" 2>/dev/null
    return 0
  fi
  return 1
}

# Called only by the process that took the lock, and it removes the lock only
# while it still names that process: a holder that was taken over as stale and
# comes back to release must not remove the lock its successor now holds. A
# lock whose pid file is missing or empty is removed too, because the write of
# the pid can fail (a full disk), and a lock this call left behind would have
# every writer wait out its three seconds, and every heal decline, until the
# lock aged past a minute. A pid that is not a regular file is not read, and
# reads as missing: a pipe there would hold the release, and the gate behind
# it, forever (2026-10-08).
_felix_mem_unlock() {
  local owner=""
  [ -f "$1/pid" ] && owner="$(head -n 1 "$1/pid" 2>/dev/null)"
  case "$owner" in
    ''|"$$") rm -rf "$1" 2>/dev/null ;;
  esac
  return 0
}

# Heal the split rows an engine before #267 left in a project's mistakes.log,
# joining each pair into the one row #267 would have written (U44, U42).
#
# Why on disk, and not only in the readers: templates/commissioning.tsv's
# gate_shown_failing row reads the file with `cut -f4`, and that table is an
# escape table, so its check cannot learn the split shape. And the writer
# cannot fix it, because a gate that passes writes no row: an install stuck on
# a split row stays stuck however often its gate goes green. So this runs where
# every install passes whatever the gate did: every session start, every gate,
# pass or fail, and every full commission run. The lib readers read through
# felix_mem_mistake_rows as well, because this can decline.
#
# It rewrites a memory file, so it is written to decline rather than risk a
# row. Silent, always 0, and nothing it does changes a caller's status:
#
#   - Read-only first. A missing, empty, symlinked or non-regular log, one whose
#     last byte is not a newline, and one with no pair all return here, with no
#     lock, no temporary, and the file's bytes, mode and mtime untouched. That
#     is every well-formed log in every session. A symlink is left alone
#     because a rename onto it would make the link a regular file; the readers
#     still read it joined.
#   - Then the lock. A live owner means someone is appending or healing, and
#     this leaves it to them.
#   - The inode is pinned with a hard link, and the rewrite is built from
#     exactly the bytes that link held at one moment. The result must be one
#     line shorter and three bytes longer per pair (`\n?\t?\t` out, `\tunborn\t`
#     in), and the log must still be that inode, or nothing is replaced. A
#     prototype that skipped this renamed an empty file over a log.
#   - The rename is atomic, in the same directory, and `mv` is resolved on PATH
#     like felix_mem_handoff's, which the suite relies on to land an append in
#     the middle of it.
#   - An append that landed on the old inode after the snapshot, from a writer
#     that takes no lock (an older engine in a session not yet restarted, or a
#     person's >>), is still on the pinned inode, and is copied onto the end of
#     the new file. What remains is only an append opened on the old inode
#     before the rename and written after the last read of it, and only for a
#     writer that takes no lock. This engine's writer takes it.
#   - The mode is carried across as felix_mem_handoff carries it, and the mtime
#     is restored from the pinned inode, because felix_guard_unrecorded reads
#     it: a row written before rows carried their second, which every healed
#     row is, is taken to have been caught at the file's time. A heal that
#     bumped it would make every such catch newer than every entry written
#     before the heal, and have the Stop hook announce a failure nobody had in
#     this session.
#
# No trap: cmd_commission owns an EXIT trap and a function that set its own
# would clobber it, so every path below cleans up after itself. The engine's
# own temporaries a killed heal left, over a minute old, are cleared while the
# lock is held. They are never memory, so this is not deleting a memory root.
felix_mem_mistakes_heal() {
  local proj="$1" dir f lock pin tmp n0 n1 l0 lt nt pairs i
  dir="$(felix_mem_dir "$proj")"
  f="$dir/mistakes.log"
  [ -f "$f" ] && [ ! -L "$f" ] || return 0
  [ -s "$f" ] || return 0
  [ "$(tail -c 1 "$f" 2>/dev/null | od -An -tx1 | tr -d ' \n')" = "0a" ] || return 0
  felix_mem_mistake_rows "$f" | cmp -s - "$f" 2>/dev/null && return 0

  lock="$dir/.mistakes.lock"
  _felix_mem_lock "$lock" || return 0
  find "$dir" -maxdepth 1 -type f \( -name '.mistakes.log.heal.*' -o -name '.mistakes.log.orig.*' \) \
    -mmin +1 -exec rm -f {} + 2>/dev/null

  pin="$dir/.mistakes.log.orig.$$"
  tmp="$dir/.mistakes.log.heal.$$"
  if ! ln "$f" "$pin" 2>/dev/null; then
    _felix_mem_unlock "$lock"; return 0
  fi
  n0="$(wc -c < "$pin" 2>/dev/null | tr -dc '0-9')"
  if [ -z "$n0" ] || [ "$(tail -c 1 "$pin" 2>/dev/null | od -An -tx1 | tr -d ' \n')" != "0a" ]; then
    rm -f "$pin"; _felix_mem_unlock "$lock"; return 0
  fi
  # Copied first only for its mode; the redirection below replaces the text.
  if ! cp -p "$pin" "$tmp" 2>/dev/null \
     || ! head -c "$n0" "$pin" 2>/dev/null | _felix_mem_mistake_join > "$tmp" 2>/dev/null; then
    rm -f "$tmp" "$pin"; _felix_mem_unlock "$lock"; return 0
  fi
  l0="$(head -c "$n0" "$pin" 2>/dev/null | wc -l | tr -dc '0-9')"
  lt="$(wc -l < "$tmp" 2>/dev/null | tr -dc '0-9')"
  nt="$(wc -c < "$tmp" 2>/dev/null | tr -dc '0-9')"
  pairs=$(( ${l0:-0} - ${lt:-0} ))
  if [ -z "$l0" ] || [ -z "$lt" ] || [ -z "$nt" ] || [ "$pairs" -lt 1 ] \
     || [ "$nt" -ne $((n0 + 3 * pairs)) ] || [ ! "$f" -ef "$pin" ]; then
    rm -f "$tmp" "$pin"; _felix_mem_unlock "$lock"; return 0
  fi
  if ! mv -f "$tmp" "$f" 2>/dev/null; then
    rm -f "$tmp" "$pin"; _felix_mem_unlock "$lock"; return 0
  fi
  i=0
  while [ "$i" -lt 5 ]; do
    n1="$(wc -c < "$pin" 2>/dev/null | tr -dc '0-9')"
    [ -n "$n1" ] && [ "$n1" -gt "$n0" ] || break
    tail -c +"$((n0 + 1))" "$pin" 2>/dev/null >> "$f"
    n0="$n1"
    i=$((i + 1))
  done
  touch -r "$pin" "$f" 2>/dev/null
  rm -f "$pin"
  _felix_mem_unlock "$lock"
  return 0
}

# What the gate keeps catching. A far better promotion signal than counting words:
# a check that fails repeatedly is a habit, and a habit is what a lesson is for.
#
# Emits `occasions<TAB>term<TAB>last-seen<TAB>runs`, heaviest first, and only
# for terms that are still recurring.
#
# Two numbers because they answer two questions and only one of them earns a
# promotion. `runs` is how many gate runs the check cost — a fact about time
# spent. `occasions` is how many DISTINCT trees it was caught on, which is the
# only one of the two that means "again".
#
# The threshold reads occasions. A tree gated five times without being fixed
# cost five runs and recurred once, and this list's rank in `next.sh` is the
# one that tells a person to write a lesson — advice that asks them to
# generalise from a single incident. Felix's own log had `ecosystem` five
# times, every one of them the same branch at the same sha, sitting in "already
# cost time more than once" beside `installed` at twenty-two separate commits.
# The rule of three this project already holds is about occasions, not
# attempts.
#
# The count is for all time and the liveness test is not, because they answer
# different questions. "It has cost time twice" is a fact about history and does
# not expire. "It is costing time" is a fact about now, and only the second one
# earns a place in a ranked list. Felix's own log had `installed` nine times,
# every one of them before the two mechanisms that address it landed, and it sat
# at the rank `next.sh` calls the strongest promotion signal there is — above
# whatever was actually costing time that day. Nothing would ever have removed
# it: an append-only log has no way to say a thing was dealt with. A permanent
# row at the top rank is not a strong signal, it is a list people stop reading.
#
# Fourteen days rather than the seven `felix_guard_unrecorded` uses, because
# that one fires unprompted in a session and this one is read on request. The
# window errs long on purpose: a fix a few days old has not yet had the chance
# to fail, and dropping it early would be this project's own overclaiming
# failure — converting "nobody has caught it again yet" into "it is fixed".
#
# No usable `date` means no window and everything is reported, which shows more
# rather than less. That is the safe direction for a signal about mistakes.
#
# Read through felix_mem_mistake_rows, so a split row an older engine wrote is
# counted as the one row it was, with `unborn` in column three, whether or not
# a heal has run on the file yet (U44).
felix_mem_recurring_mistakes() {
  local proj="$1" min="${2:-2}" days="${3:-14}" cutoff
  [ -f "$(felix_mem_dir "$proj")/mistakes.log" ] || return 0
  cutoff="$(date -v-"${days}"d +%Y-%m-%d 2>/dev/null \
            || date -d "${days} days ago" +%Y-%m-%d 2>/dev/null)"
  felix_mem_mistake_rows "$(felix_mem_dir "$proj")/mistakes.log" | awk -F'\t' -v MIN="$min" -v CUT="$cutoff" '
    {
      # Column 4 holds every check that failed in one run, space separated.
      n = split($4, terms, " ")
      for (i = 1; i <= n; i++) {
        t = terms[i]
        if (t == "") continue
        runs[t]++
        # Column 3 is the commit. One tree gated twice is one occasion, and
        # the same failure on two trees is two.
        k = t SUBSEP $3
        if (!(k in occseen)) { occseen[k] = 1; count[t]++ }
        # Forced to strings: a date is compared as one, never as arithmetic.
        if (($1 "") > (last[t] "")) last[t] = $1
      }
    }
    END {
      for (t in count) {
        if (count[t] < MIN) continue
        if (CUT != "" && (last[t] "") < (CUT "")) continue
        printf "%d\t%s\t%s\t%d\n", count[t], t, last[t], runs[t]
      }
    }
  ' 2>/dev/null | LC_ALL=C sort -rn
}

# Whether the lessons file holds a lesson about a check of this name.
#
# This was a substring search over the whole file, and the terms it is asked
# about are gate check names that are also ordinary English words. `installed`
# matched "executing the installed hooks by hand" and "cannot be uninstalled",
# neither of which is a lesson about the `installed` check — so a check nobody
# had written anything about read as one whose lesson was being ignored. The two
# cases lead opposite ways: write the prose, versus stop writing prose because
# it is not working and build the mechanism instead. Sending someone to build a
# mechanism on the strength of a coincidence is the more expensive direction.
#
# A check named in prose is written as code, because that is what it is, and the
# house style for that is backticks. That is what separates "`installed` check"
# from "the installed hooks". Matching a following `-`, `_`, `.` or `/` means
# `secret` finds `secret-scan` and `tests` finds `tests/run`: a lesson about the
# file a check runs is a lesson about the check.
#
# The slash was missing at first, and it mattered more than the others, because
# a check name is most often written as the head of a path. Two of Felix's own
# seven gate checks — `tests` and `memory` — read as "no lesson mentions it"
# against a lessons file that discusses `tests/run` and
# `memory/verification.log` at length, and the advice that follows a false
# negative here is to write prose that is already written.
#
# It can still be wrong, and the direction it is wrong in matters. An unquoted
# mention of a real lesson reads as no lesson and asks for one to be written —
# a duplicate paragraph. The old failure sent you to build machinery you did not
# need. Prefer the cheap mistake.
felix_mem_lesson_names() {
  local proj="$1" term="$2" esc
  [ -f "$(felix_mem_dir "$proj")/lessons.md" ] || return 1
  [ -n "$term" ] || return 1
  esc="$(printf '%s' "$term" | sed 's/[][\.*^$(){}?+|\\/-]/\\&/g')"
  grep -qE '`'"$esc"'([`._/-]|$)' "$(felix_mem_dir "$proj")/lessons.md" 2>/dev/null
}

# Terms recurring across distinct devlog entries and absent from the lessons.
# Crude frequency counting, stated as such wherever it is printed.
felix_mem_promotable() {
  local proj="$1" min="${2:-3}"
  [ -f "$(felix_mem_dir "$proj")/DEVLOG.md" ] || return 0
  local lessons=""
  [ -f "$(felix_mem_dir "$proj")/lessons.md" ] && lessons="$(tr '[:upper:]' '[:lower:]' < "$(felix_mem_dir "$proj")/lessons.md")"
  # Count the number of distinct entries a term appears in, not how often it
  # appears. Fifty mentions inside one entry is one story being told at length;
  # the promotion signal is a thing that keeps coming back on different days.
  awk '
    /^## / { entry++ }
    {
      line = tolower($0)
      gsub(/[^a-z0-9_-]+/, " ", line)
      n = split(line, w, " ")
      for (i = 1; i <= n; i++) {
        t = w[i]
        if (length(t) < 5) continue
        if (t ~ /^[0-9-]+$/) continue
        key = t SUBSEP entry
        if (!(key in seen)) { seen[key] = 1; entries[t]++ }
      }
    }
    END { for (t in entries) if (entries[t] >= MIN) printf "%d\t%s\n", entries[t], t }
  ' MIN="$min" "$(felix_mem_dir "$proj")/DEVLOG.md" \
    | grep -vE $'\t(about|after|again|against|because|before|being|between|could|during|every|first|found|from|going|instead|into|might|other|rather|really|should|since|still|than|that|their|them|then|there|these|they|thing|think|this|those|through|under|until|were|what|when|where|which|while|with|would|your|commit|change|changes|added|update|updated|files|file|version|branch|already|actually|something|because|makes|making|which|there|where|point|second)$' \
    | LC_ALL=C sort -rn \
    | while IFS=$'\t' read -r n term; do
        [ -n "${term:-}" ] || continue
        case "$lessons" in *"$term"*) continue ;; esac
        printf '%s\t%s\n' "$n" "$term"
      done | head -12
}
