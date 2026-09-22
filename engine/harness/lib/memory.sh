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

_felix_mem_stamp() {
  local root="$1"
  printf '%s %s %s' \
    "$(date +%Y-%m-%d)" \
    "$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')" \
    "$(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo '?')"
}

felix_mem_log() {
  local proj="$1" root="$2" text="$3"
  mkdir -p "$(felix_mem_dir "$proj")"
  printf '\n## %s\n\n%s\n' "$(_felix_mem_stamp "$root")" "$text" >> "$(felix_mem_dir "$proj")/DEVLOG.md"
}

felix_mem_lesson() {
  local proj="$1" root="$2" text="$3"
  mkdir -p "$(felix_mem_dir "$proj")"
  printf '\n- **%s** %s\n' "$(date +%Y-%m-%d)" "$text" >> "$(felix_mem_dir "$proj")/lessons.md"
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
      "$f" "$(wc -c < "$f" | tr -d ' ')" >&2
    printf 'it does not open with the header this command writes, "# Handoff" and then\n' >&2
    printf '"Regenerated <date>." on the third line. Move it aside, or pass --replace to\n' >&2
    printf 'overwrite it with the regenerated handoff.\n' >&2
    return 1
  fi
  if [ -z "$note" ] && [ -f "$f" ]; then
    note="$(sed -n 's/^- what was in progress: //p' "$f" | head -1)"
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

# The text of a regenerated handoff, from what git knows of ROOT. A function of
# its own so the caller can build it before any file exists: written inline in
# a command substitution, bash 3.2 misreads the apostrophes in its comments.
_felix_mem_handoff_text() {
  local root="$1" gate="$2" note="$3"
  printf '# Handoff\n\nRegenerated %s. Anything below is the state of the tree,\nnot a summary of intent.\n\n' "$(date +%Y-%m-%d)"
  printf '## Where\n\n'
  printf -- '- branch: `%s`\n' "$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  printf -- '- head: `%s`\n' "$(git -C "$root" log -1 --format='%h %s' 2>/dev/null)"
  printf -- '- tree: `%s`\n' "$root"
  printf '\n## Uncommitted\n\n'
  local dirty; dirty="$(git -C "$root" status --short 2>/dev/null | grep -v '^??' || true)"
  if [ -n "$dirty" ]; then printf '```\n%s\n```\n' "$dirty"
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
  sed -n 3p "$1" | grep -qE '^Regenerated [0-9]{4}-[0-9]{2}-[0-9]{2}\.'
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
felix_mem_mistake() {
  local proj="$1" root="$2" what="$3"
  mkdir -p "$(felix_mem_dir "$proj")"
  printf '%s\t%s\t%s\t%s\n' \
    "$(date +%Y-%m-%d)" \
    "$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')" \
    "$(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo '?')" \
    "$what" >> "$(felix_mem_dir "$proj")/mistakes.log"
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
felix_mem_recurring_mistakes() {
  local proj="$1" min="${2:-2}" days="${3:-14}" cutoff
  [ -f "$(felix_mem_dir "$proj")/mistakes.log" ] || return 0
  cutoff="$(date -v-"${days}"d +%Y-%m-%d 2>/dev/null \
            || date -d "${days} days ago" +%Y-%m-%d 2>/dev/null)"
  awk -F'\t' -v MIN="$min" -v CUT="$cutoff" '
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
  ' "$(felix_mem_dir "$proj")/mistakes.log" 2>/dev/null | sort -rn
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
    | sort -rn \
    | while IFS=$'\t' read -r n term; do
        [ -n "${term:-}" ] || continue
        case "$lessons" in *"$term"*) continue ;; esac
        printf '%s\t%s\n' "$n" "$term"
      done | head -12
}
