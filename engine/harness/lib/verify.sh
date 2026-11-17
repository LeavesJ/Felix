# Verification receipts.
#
# The guidebook's central rule is that an agent must never declare a task
# complete while a required deterministic verification step is failing. Felix
# has had the verification step since the beginning; what it lacked was anything
# that noticed when the step had not run. `felix gate` was a command an agent
# could simply not choose.
#
# The mechanism is a receipt rather than a re-run. Re-running the gate at the
# moment someone tries to finish would cost a full test suite every time, which
# on a real project means the hook gets removed, and a removed hook enforces
# nothing. A receipt costs a diff and two small files.
#
# A receipt also answers the question a re-run cannot. Re-running says "the gate
# passes now". The receipt says "this exact tree has been verified", which is a
# different claim, and the common failure is not a red gate but a gate nobody
# ran. A re-run silently converts that failure into a pass.
#
# Dependencies stay bash and git. `git hash-object --stdin` is used rather than
# shasum or sha1sum because those differ across platforms and git is already
# required.

FELIX_UNTRACKED_CAP="${FELIX_UNTRACKED_CAP:-500}"

# Every read of the working tree here goes through _felix_git_read, which lives
# in resolve.sh. The CLI and every hook source that first. Sourced here too
# rather than assumed, as escape.sh does for felix_changed_paths: a missing
# helper would make every tree unknown, which is safe and useless.
if ! command -v _felix_git_read >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

_felix_hash() { git hash-object --stdin 2>/dev/null; }

_felix_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Size and mtime for one file, portably.
#
# GNU must be probed first. `stat -f` on GNU means --file-system, so it succeeds
# with entirely unrelated output rather than failing, and a BSD-first probe would
# silently return filesystem statistics for every file on Linux.
_FELIX_STAT=""
_felix_stat_mode() {
  [ -n "$_FELIX_STAT" ] && return 0
  if stat -c '%s' /dev/null >/dev/null 2>&1; then _FELIX_STAT=gnu
  elif stat -f '%z' /dev/null >/dev/null 2>&1; then _FELIX_STAT=bsd
  else _FELIX_STAT=none; fi
}
# Every path in one call, not one call per path.
#
# The first version asked for metadata per file from inside a command
# substitution, which is a subshell, so the capability probe above never cached:
# each file cost three `stat` processes rather than one. On a repository with a
# couple of untracked backup directories that was 510 spawns and close to two
# seconds on every attempt to finish. Both stat implementations accept many
# paths at once, so this is one process regardless of count.
_felix_meta_all() {
  _felix_stat_mode
  case "$_FELIX_STAT" in
    gnu) stat -c '%n %s %Y' "$@" 2>/dev/null ;;
    bsd) stat -f '%N %z %m' "$@" 2>/dev/null ;;
    *)   printf '%s\n' "$@" ;;
  esac
}

# The HEAD a session began at.
#
# Stop needs to tell "this session changed something" from "this tree happens to
# be clean", and those come apart the instant anybody commits — which is what
# you do at the end, so the sessions that finished properly were the ones never
# asked to verify anything. Dirtiness cannot answer it; only a mark from the
# start of the session can.
#
# Best effort throughout. No session id, no git, no writable home: no record,
# and Stop falls back to its old behaviour rather than starting to block trees
# it has nothing to say about.
_felix_session_path() { printf '%s/state/session/%s' "$1" "$2"; }

felix_session_mark() {
  local home="$1" sid="$2" root="$3" head path
  [ -n "$sid" ] && [ -n "$home" ] || return 0
  head="$(git -C "$root" rev-parse HEAD 2>/dev/null)" || return 0
  [ -n "$head" ] || return 0
  path="$(_felix_session_path "$home" "$sid")"
  mkdir -p "$(dirname "$path")" 2>/dev/null || return 0
  [ -f "$path" ] && return 0   # first mark wins; a compact must not reset it
  printf '%s\n' "$head" > "$path" 2>/dev/null || true
}

# A session nobody in it typed into.
#
# The platform's summary request starts a session of its own and types into it
# (#264). The prompt hook records nothing for that, but the session still ends
# like any other, and nothing at its end knew it for one: Stop held it in a tree
# with unverified work and told the summarising model to run the gate, and a
# tool call made on that advice was folded into ledger.d at SessionEnd, the
# phantom back in the denominator. So the prompt hook leaves this marker in
# place of a record, and Stop and SessionEnd consult it first and do nothing at
# all for the session. SessionEnd takes it away. State under the home, never
# memory: it describes a session that is running, not one that happened.
#
# Honoured only while the session has no mark. Every prompt a person types
# marks the session and a summary request never does, so a marker beside a mark
# is not what it says, and the session is judged as it always was. A session
# can write its own state as easily as its code; this is the floor and not a
# wall, and forging the exemption takes removing the session's own mark too.
#
# No session id, no marker: the prompt hook still records nothing for the
# request, since what it may do with a prompt is the prompt's kind and not the
# id's, and Stop and SessionEnd keep their old behaviour for the session.
_felix_machine_path() { printf '%s/state/machine/%s' "$1" "$2"; }

felix_session_machine_mark() {   # home, sid
  local path
  [ -n "${1:-}" ] && [ -n "${2:-}" ] || return 0
  path="$(_felix_machine_path "$1" "$2")"
  mkdir -p "$(dirname "$path")" 2>/dev/null || return 0
  : > "$path" 2>/dev/null || true
}

felix_session_machine() {   # home, sid -> 0 when nobody in the session typed into it
  [ -n "${1:-}" ] && [ -n "${2:-}" ] || return 1
  [ -f "$(_felix_machine_path "$1" "$2")" ] || return 1
  [ ! -f "$(_felix_session_path "$1" "$2")" ]
}

felix_session_machine_clear() {   # home, sid
  local path
  [ -n "${1:-}" ] && [ -n "${2:-}" ] || return 0
  path="$(_felix_machine_path "$1" "$2")"
  [ -f "$path" ] || return 0
  rm -f "$path" 2>/dev/null || true
}

# Felix's own hold, written down so that Stop can tell its own chain from
# another hook's.
#
# The platform sets stop_hook_active on the stop that ends a turn a hook
# started, and Stop used to leave at the flag whoever had started it. Felix's
# own hold is one such start. An asyncRewake hook that exits 2 is another: its
# rewake arrives as a turn of its own with the flag already set, measured on
# Claude Code 2.1.260 and 2.1.280 for a Stop and a PostToolUse hook alike (a
# rewake folded into a running turn sets nothing, and a hook merely in flight
# sets nothing). security-guidance, which commissioning installs for every
# project, is such a hook. So the turn in which a model fixes what a background
# review found ended with no check and no record, however dirty the tree.
#
# The flag is now honoured at the one stop a hold of Felix's started. Stop
# marks each hold before it is made, the next flagged stop takes the mark away
# and ends there, and an unflagged stop, which begins a chain afresh, clears
# whatever is left. A flagged stop with no mark to take belongs to someone
# else's chain and is judged like any other stop. Every hold is followed by a
# stop Felix lets through, so it never holds twice in a row, and the
# platform's rule still holds for every chain of Felix's own.
#
# The id arrives in a payload, so a path built from it is checked first, and an
# id that cannot name a file reads as unknown: the flag ends the stop, as it
# always did. So does a record that cannot be taken away. Where state/held
# cannot be written, nothing here can be told apart, and every flagged stop
# ends at the flag as it did before any of this existed.
_felix_hold_path() {   # home, sid -> path, or 1 when the id cannot name a file
  local LC_ALL=C
  [ -n "${1:-}" ] || return 1
  case "${2:-}" in ''|.|..|-*|*[!A-Za-z0-9._-]*) return 1 ;; esac
  [ "${#2}" -le 128 ] || return 1
  printf '%s/state/held/%s' "$1" "$2"
}

felix_hold_mark() {   # home, sid -> 0 when the hold is on record
  local path
  path="$(_felix_hold_path "${1:-}" "${2:-}")" || return 1
  mkdir -p "$(dirname "$path")" 2>/dev/null || return 1
  : > "$path" 2>/dev/null
}

# 0 when a hold of Felix's was on record, and it is taken away; 1 when none was;
# 2 when the id cannot say, or the record is still there after taking it.
felix_hold_take() {   # home, sid -> 0 | 1 | 2
  local path
  path="$(_felix_hold_path "${1:-}" "${2:-}")" || return 2
  [ -f "$path" ] || return 1
  rm -f "$path" 2>/dev/null
  [ ! -e "$path" ] || return 2
  return 0
}

felix_hold_clear() {   # home, sid
  local path
  path="$(_felix_hold_path "${1:-}" "${2:-}")" || return 0
  [ -f "$path" ] || return 0
  rm -f "$path" 2>/dev/null || true
}

# What a session was held on for a gate that had not passed, one line a hold:
# the tree id, the reason (never checked, stale receipt, failed, epoch moved)
# and the checkout, tab-separated. So a session is held once for each, not at
# every stop after it.
#
# Every wake-up of an idle session (a background task finishing, another
# session's message) ends in a stop of its own, and each was judged afresh, so
# a tree whose gate had not run was held again at each one. Counted over 13.5
# hours of 2026-10-08 by replay_holds.py (audits/2026-10-09-token-burn in the
# memory root): 366 holds in 41 sessions, a median of 7 a session and 48 at
# most, each a model turn of about 69K tokens, 2.8% of a week's allowance.
# The first hold says everything a hold can; the rest only cost. So the next
# stop on the same tree, for the same reason, in the same checkout, lets the
# session go and puts the unrun gate on record as a debt (felix_verify_log).
# A changed tree is held again, and so is the same tree when the reason moved:
# held as never checked, the gate then failed on it, and that is news. A
# person's prompt clears the record (hooks/user-prompt), since a person asking
# is a new question about the work, and so does SessionEnd. hooks/stop does not
# hold once where the tree id cannot tell work apart (an unborn HEAD, a coarse
# id) or for a session that holds a night, whose own bounds govern it. The
# same script, replaying this rule: 157 holds, a median of 2 a session and 18
# at most.
#
# Under state/, which tree identity excludes, so marking a tree cannot change
# it. A record that cannot be read or written holds as before, and so does a
# path that is not a regular file or is a link: nothing here may open a pipe or
# write through a link out of state/.
_felix_hold_tree_path() {   # home, sid -> path, or 1 when the id cannot name a file
  _felix_hold_path "${1:-}" "${2:-}" >/dev/null || return 1
  printf '%s/state/held-tree/%s' "$1" "$2"
}

felix_hold_tree_seen() {   # home, sid, tid, reason, checkout -> 0 when held on just that
  local path
  [ -n "${3:-}" ] || return 1
  path="$(_felix_hold_tree_path "${1:-}" "${2:-}")" || return 1
  [ -f "$path" ] && [ ! -L "$path" ] || return 1
  # Before 0.49.327 hooks/stop named the first reason by the word Felix no
  # longer prints (decision 1 of 2026-10-31), and a record written before that
  # deploy is the same hold, not news.
  if [ "${4:-}" = "never checked" ]; then
    grep -Fxq -e "$3	never checked	${5:-}" -e "$3	never verified	${5:-}" "$path" 2>/dev/null
  else
    grep -Fxq -e "$3	${4:-}	${5:-}" "$path" 2>/dev/null
  fi
}

felix_hold_tree_mark() {   # home, sid, tid, reason, checkout
  local path
  [ -n "${3:-}" ] || return 0
  path="$(_felix_hold_tree_path "${1:-}" "${2:-}")" || return 0
  mkdir -p "$(dirname "$path")" 2>/dev/null || return 0
  [ ! -L "$path" ] || return 0
  [ ! -e "$path" ] || [ -f "$path" ] || return 0
  printf '%s\t%s\t%s\n' "$3" "${4:-}" "${5:-}" >> "$path" 2>/dev/null || true
}

felix_hold_tree_clear() {   # home, sid
  local path
  path="$(_felix_hold_tree_path "${1:-}" "${2:-}")" || return 0
  [ -f "$path" ] || [ -L "$path" ] || return 0
  rm -f "$path" 2>/dev/null || true
}

# Did this session commit anything? Returns 1 when unknown, so the caller keeps
# whatever it did before rather than treating ignorance as a change.
felix_session_committed() {
  local home="$1" sid="$2" root="$3" start now
  [ -n "$sid" ] || return 1
  start="$(cat "$(_felix_session_path "$home" "$sid")" 2>/dev/null)" || return 1
  [ -n "$start" ] || return 1
  now="$(git -C "$root" rev-parse HEAD 2>/dev/null)" || return 1
  [ -n "$now" ] && [ "$now" != "$start" ]
}

# Does this tree hold anything the gate has not seen committed?
#
# Excludes Felix's own bookkeeping for the same reason tree identity does: a
# session that appended one line to a log has not changed the work, and treating
# it as dirty would demand a gate run for having recorded that a gate ran.
felix_tree_dirty() {
  local root="$1" home="${2:-}" f
  git -C "$root" rev-parse --git-dir >/dev/null 2>&1 || return 1
  local exargs=()
  while IFS= read -r f; do [ -n "$f" ] && exargs+=("$f"); done <<EOF
$(_felix_tree_excludes "$root" "$home")
EOF
  # A status git could not finish is not a clean tree (2026-10-08). A corrupt
  # index made `git status` exit 128 with nothing on stdout, and this read the
  # empty answer as clean, so Stop let the session go without asking about the
  # tree. Not a repository at all is still `1`, above: nothing is known there.
  local st
  _felix_git_read st git -C "$root" status --porcelain -- . "${exargs[@]+"${exargs[@]}"}" || return 0
  [ -n "$st" ]
}

# Identity of a working tree: the commit it sits on, the content of every
# uncommitted change, and the presence of every untracked file.
#
# `git status --porcelain` alone was rejected. Two different edits to the same
# file produce byte-identical status output, so a receipt keyed on it stays valid
# across a change it never saw. The diff content has to be in the hash.
#
# Untracked file *contents* are deliberately not hashed. Felix governs projects
# in languages it does not know, and an untracked directory in one of them may be
# a virtualenv, a build output, or a multi-gigabyte model artifact. Hashing bytes
# would make this hook's cost a function of somebody else's project layout. Size
# and mtime both change on any write, which is sufficient, and cost one stat.
#
# Felix's own bookkeeping is excluded when Felix's home lives inside the tree
# being identified, which is the case whenever Felix governs itself. Writing a
# receipt is a change to the tree; without this, recording a verdict invalidates
# the verdict it just recorded and no receipt can ever be valid. The same goes
# for the verification log and the route log, which are records *about* the work
# rather than the work. When home is elsewhere — every governed project that is
# not Felix — nothing is excluded, so a project with its own `state/` keeps it.
_felix_tree_excludes() {
  local root="$1" home="${2:-}" rel
  [ -n "$home" ] || return 0
  case "$home" in
    "$root")   rel="" ;;
    "$root"/*) rel="${home#"$root"/}/" ;;
    *)         return 0 ;;
  esac
  printf ':(exclude)%sstate/**\n'                 "$rel"
  printf ':(exclude)%sprojects/*/memory/*.log\n'  "$rel"
  printf ':(exclude)%sprojects/*/maintenance.log\n' "$rel"
}

# A tree git could not read in full has no identity (2026-10-08): this prints
# nothing and returns 2 (1 still means not a repository). With a named pipe at
# projects/x/deny.tsv and an edit to src.txt, `git diff HEAD` printed nothing
# and exited 128, and the id of that silence was the clean commit's, so a green
# receipt read current over an edit no gate had seen. A mode-000 file and a
# corrupt index did the same. Every caller treats an empty id as unknown: no
# receipt is written, felix_verify_current calls it stale, and Stop holds.
# Leaving the unreadable path out would be the defect itself, a tree id that
# silently ignores a path. An untracked pipe is no part of any tree (git lists
# none), and a path the excludes leave out is no part of the id.
#
# A tree git reads in full hashes the bytes it hashed before, with two
# exceptions found by the review of this change, each a tree whose old id left
# something out. An unborn HEAD with something staged hashed only index against
# tree, so two staged contents shared the id of an empty `git init`. And an
# untracked name git quoted, every name past ASCII by default, a macOS
# screenshot included, went to stat under a spelling that names no file.
#
# The diff runs with no external diff, no textconv, no colour, and every
# submodule shown (2026-10-08). Under `diff.external`, GIT_EXTERNAL_DIFF, a
# driver command or a textconv that prints nothing, git printed nothing for the
# edited file, so an edit hashed exactly as the clean tree did. Under
# diff.ignoreSubmodules=all, or `ignore = all` in a committed .gitmodules, a
# moved submodule pointer did the same. Why per call, and what else was
# measured: above _felix_git_patch in resolve.sh. A binary marking needs nothing
# here, because the patch's `index` line still names both blobs. That line is
# all the id sees of a binary file's edit, so core.abbrev is pinned to auto,
# git's default: core.abbrev=4 cut it to 16 bits of each blob id, and an edit
# found to share them hashed as the edit a receipt was written for. For a
# default configuration the bytes are unchanged, so this too staled no receipt.
#
# Arguments after the second are pathspecs added to the exclusions, for the
# diff and for the untracked list alike, each exactly as given: `:(exclude)x`
# names a path to leave out, and nothing here adds the prefix. The suite's
# receipt (tests/receipt.sh) asks for a tree id with the two record files
# left out, so a record run can say that nothing else moved while red rewrote
# them. With two arguments or fewer this is the function it was, and no caller
# that exists passes a third.
felix_tree_id() {
  local root="$1" home="${2:-}"
  if [ "$#" -gt 2 ]; then shift 2; else set --; fi
  _felix_tree_id_on "$root" "" "$home" "$@"
}

# The id felix_tree_id would print for this checkout as it is now if HEAD named
# <commit> instead: the same exclusions, the diff of the working tree against
# <commit>, the same untracked files, the same hashing, because it is the same
# code with the commit as an input. The suite's receipt asks it for a commit's
# parent (tests/receipt.sh, rule C10): the id hashes HEAD, so committing the
# tree a run passed moves the id although the content is the run's. Status 1
# and nothing when <commit> is empty (it never falls back to HEAD) or no commit.
felix_tree_id_on() {   # <root> <commit> [home] [pathspec...]
  local root="$1" at="${2:-}" home="${3:-}"
  [ -n "$at" ] || return 1
  if [ "$#" -gt 3 ]; then shift 3; else set --; fi
  _felix_tree_id_on "$root" "$at" "$home" "$@"
}

# The one hashing path. <at> empty is HEAD, as felix_tree_id always read it,
# the unborn case included; otherwise it is the commit that stands in for HEAD,
# in the hash and as the base of the diff.
_felix_tree_id_on() {   # <root> <at> <home> [pathspec...]
  local root="$1" at="$2" home="${3:-}" head diff cached untracked n=0 meta="" quoted="" prefix="" f id base=HEAD
  shift 3
  git -C "$root" rev-parse --git-dir >/dev/null 2>&1 || return 1
  local ex; ex="$(_felix_tree_excludes "$root" "$home")"
  local exargs=()
  while IFS= read -r f; do [ -n "$f" ] && exargs+=("$f"); done <<EOF
$ex
EOF
  for f in "$@"; do exargs+=("$f"); done

  if [ -n "$at" ]; then
    head="$(git -C "$root" rev-parse -q --verify "$at^{commit}" 2>/dev/null)" || return 1
    [ -n "$head" ] || return 1
    base="$head"
  else
    head="$(git -C "$root" rev-parse HEAD 2>/dev/null)" || head=""
  fi
  if [ -z "$head" ]; then
    # An unborn HEAD has nothing to diff against. A repository with no commits is
    # a real state — it is what `git init` leaves, and what this suite's own
    # fixture is — and every naive implementation of this dies there.
    head="unborn"
    _felix_git_read diff git -C "$root" -c core.abbrev=auto diff --no-ext-diff --no-textconv --no-color --ignore-submodules=none -- . "${exargs[@]+"${exargs[@]}"}" || return 2
    # What is staged, against nothing. Added only when there is any, so the id
    # of a bare `git init` is the one it always was.
    _felix_git_read cached git -C "$root" -c core.abbrev=auto diff --no-ext-diff --no-textconv --no-color --ignore-submodules=none --cached -- . "${exargs[@]+"${exargs[@]}"}" || return 2
    [ -z "$cached" ] || diff="$cached
$diff"
  else
    _felix_git_read diff git -C "$root" -c core.abbrev=auto diff --no-ext-diff --no-textconv --no-color --ignore-submodules=none "$base" -- . "${exargs[@]+"${exargs[@]}"}" || return 2
  fi

  # quotePath off, so a name past ASCII is listed as the bytes stat can open.
  _felix_git_read untracked git -c core.quotePath=false -C "$root" ls-files --others --exclude-standard \
    -- . "${exargs[@]+"${exargs[@]}"}" || return 2
  if [ -n "$untracked" ]; then
    # A sort or a count that died reads as no untracked file, so either one
    # coming back empty over a list that was not is unknown too.
    untracked="$(printf '%s\n' "$untracked" | LC_ALL=C sort)"
    n="$(printf '%s' "$untracked" | grep -c .)"
    case "$n" in ''|0|*[!0123456789]*) return 2 ;; esac
  fi

  if [ "$n" -gt "$FELIX_UNTRACKED_CAP" ]; then
    # A repository in this state has larger problems than receipt precision, and
    # the hook has to stay fast whatever it is handed.
    prefix="coarse:"
    meta="$n untracked"
  elif [ "$n" -gt 0 ]; then
    local files=()
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      # git still quotes a name holding a control character, `"` or `\`,
      # quotePath or not, and that spelling names no file. Such a file is
      # counted by its presence, and a change to its bytes is not seen.
      case "$f" in
        \"*) quoted="$quoted$f ?
" ;;
        *)   files+=("$root/$f") ;;
      esac
    done <<EOF
$untracked
EOF
    if [ "${#files[@]}" -gt 0 ]; then
      meta="$(_felix_meta_all "${files[@]}")"
      # Every file stat was given and none answered: a stat that never ran.
      # One vanished between the listing and stat is simply not there.
      [ -n "$meta" ] || return 2
    fi
    [ -z "$quoted" ] || meta="$meta${meta:+
}${quoted%
}"
  fi

  id="$(printf '%s\n%s\n%s' "$head" "$diff" "$meta" | _felix_hash)"
  [ -n "$id" ] || return 2
  printf '%s%s' "$prefix" "$id"
}

# Why felix_tree_id could not identify this tree, in git's own words: the first
# `error:` or `fatal:` line git prints for the same reads, or nothing when every
# one of them succeeds now. With a pipe at m.txt that is "error: m.txt:
# unsupported file type". Only a caller already holding an unknown id asks, so
# the cost of a second diff lands where the first one failed.
felix_tree_why() {
  local root="$1" home="${2:-}" f err
  local exargs=()
  while IFS= read -r f; do [ -n "$f" ] && exargs+=("$f"); done <<EOF
$(_felix_tree_excludes "$root" "$home")
EOF
  if git -C "$root" rev-parse -q --verify HEAD >/dev/null 2>&1; then
    err="$(git -C "$root" diff --no-ext-diff --no-textconv --stat HEAD -- . "${exargs[@]+"${exargs[@]}"}" 2>&1 >/dev/null)"
  else
    err="$(git -C "$root" diff --no-ext-diff --no-textconv --stat -- . "${exargs[@]+"${exargs[@]}"}" 2>&1 >/dev/null)"
  fi
  [ -n "$err" ] \
    || err="$(git -C "$root" ls-files --others --exclude-standard -- . "${exargs[@]+"${exargs[@]}"}" 2>&1 >/dev/null)"
  # awk reads to the end, so nothing upstream is cut off for pipefail to misread.
  printf '%s\n' "$err" | awk '!p && /^(error|fatal): / { print; p = 1 }'
}

# One receipt per repository, overwritten each run. History of decisions lives in
# the verification log; the receipt only answers "what was verified last".
_felix_receipt_path() {
  printf '%s/state/gate/%s' "$2" "$(printf '%s' "$1" | _felix_hash)"
}

# Called by the gate. Failure to write is never fatal: a gate that cannot record
# its own result is still a gate, and refusing to run would be a worse trade.
# A fifth field: which checks the gate reported as SKIPPED, comma-separated,
# or `-` when it reported none.
#
# The verdict alone is one bit, and `felix gate --quick` skips the test suite
# and still exits 0 — so its receipt was byte-identical to a full run's, and
# everything downstream spoke as if the suite had passed. A green that cannot
# be told from a partial green is the shape invariant 5 is about.
#
# Appended rather than inserted because every reader takes fields 1 to 3 by
# position (`cut -f1`, `-f2`, `-f3`), so a fifth field disturbs none of them —
# asserted in the suite rather than assumed.
#
# What this cannot say, and the readers must not imply otherwise: it records
# what the gate REPORTED. A gate that skips something without saying so is
# still invisible here, and no absence of skip lines proves nothing was
# skipped.
#
# A sixth field: every check the gate reported, with the verdict it printed,
# as `name:verdict` pairs comma-separated, or `-` when none was recorded. The
# gate's output was a temporary file the command threw away, so the only
# roster of what the gate checks was one somebody typed into a handoff — and a
# typed roster is wrong the day a checker is added. `felix qualify` reads this
# field to say which reported checks no qualification row covers. Same source
# and same limit as the fifth field: a check that runs without printing a line
# is not here.
#
# A seventh and eighth field: the decision epoch (epoch.sh) the gate ran under,
# and its four component hashes comma-joined in the spec's order — subject,
# topology, policy, target. v3.2 §5 binds a receipt to what its verdict rests
# on and invalidates it when a dependency moves; the tree id covers the tree
# and nothing else, so an ignored file a probe counts, a `$HOME`-dependent
# probe, or a table in the Felix home for a governed product could all move
# while an old green rode on. Supplied by the gate, and computed here from the
# checkout's own binding when a caller does not supply them, so a receipt
# without an epoch cannot be written by accident: the first draft let a
# six-field receipt stay current "until the next gate run", and the blind
# author of the assertions refused it as the old engine's receipts riding on.
# A gate with no epoch to record writes `-`, which on a green receipt means
# the project declares no probes, and the reader says what to write.
felix_verify_record() {
  local root="$1" home="$2" rc="$3" gate="$4" tid="$5" skipped="${6:-}" reported="${7:-}" path result
  local epoch="${8:-}" comps="${9:-}"
  [ -n "$tid" ] || return 0
  path="$(_felix_receipt_path "$root" "$home")"
  mkdir -p "$(dirname "$path")" 2>/dev/null || return 0
  result=green; [ "$rc" -eq 0 ] || result=red
  if [ $# -lt 8 ]; then
    local name proj fields
    name="$(head -1 "$root/.felix" 2>/dev/null | LC_ALL=C tr -d '[:space:]')"
    proj="$home/projects/$name"
    if [ -n "$name" ] && [ -d "$proj" ]; then
      fields="$(felix_verify_epoch_fields "$proj" "$root")"
      epoch="$(printf '%s' "$fields" | LC_ALL=C cut -f1)"; comps="$(printf '%s' "$fields" | LC_ALL=C cut -f2)"
    fi
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$tid" "$result" "$(_felix_now)" "$gate" \
    "${skipped:--}" "${reported:--}" "${epoch:--}" "${comps:--}" > "$path" 2>/dev/null || true
}

felix_verify_receipt() { cat "$(_felix_receipt_path "$1" "$2")" 2>/dev/null; }

# Is the receipt for this root a current green? One line, and 0 only for
# `current`; 2 only where git could not run, 1 for every other answer:
#
#   none                    no receipt
#   red                     the receipt is not green
#   stale <TAB> reason      the tree changed; the receipt predates the epoch or
#                           carries none; the epoch cannot be read now; or a
#                           component moved — the grounded facts, the table
#                           set, the subject, the release target, in that
#                           order of precedence
#   stale <TAB> reason, 2   git could not run, so the receipt could not be
#                           found or the tree has no id; the reason starts
#                           with felix_git_runs's clause
#   current
#
# Every reader that used to compare field 1 to the tree id and field 2 to
# `green` reads this instead, so the five of them cannot disagree about what
# current means. The epoch is recomputed here, which runs the project's
# probes: a third of a second on the engine's own project, and only on the
# path that would otherwise have said verified.
#
# epoch.sh is sourced at call time rather than at load, because it pulls
# commission.sh in behind it and commission.sh sources this file: a load-time
# source from here would be a cycle, and at call time this file is complete.
#
# A fourth argument, when one is given, is the receipt's text as the caller
# already read it, and is judged in place of reading the file again. It exists
# for a caller that also wants a field of the receipt it asks about (the merge
# boundary reads the reported checks for rule C9): this function takes a third
# of a second, the gate rewrites the receipt with a truncating `>`, and a
# second read after this one is not the receipt that was judged (review finding
# C9-R3). Absent, it reads the file as it always did; an empty fourth argument
# is a receipt of nothing, which is `none`.
felix_verify_current() {
  local root="$1" home="$2" proj="$3" tid receipt r_tid r_res r_epoch r_comps comps now_epoch rpath gwhy=""
  # The receipt's path is a hash git makes, so a git that could not run finds
  # no receipt whatever the file holds, and `none` would be a fact nobody read
  # (2026-11-14: an Xcode update left /usr/bin/git exiting 69, and felix next
  # said this tree had no green receipt). The probe runs only when the hash
  # came back empty. Status 2 tells it apart for a caller whose remedy differs:
  # no gate can run until git does.
  if [ $# -ge 4 ]; then receipt="$4"
  else
    rpath="$(_felix_receipt_path "$root" "$home")"
    case "$rpath" in
      */) if command -v felix_git_runs >/dev/null 2>&1 && ! felix_git_runs gwhy; then
            printf 'stale\t%s, so this tree cannot be identified and no receipt can be confirmed for it\n' "$gwhy"; return 2
          fi ;;
    esac
    receipt="$(cat "$rpath" 2>/dev/null)"
  fi
  [ -n "$receipt" ] || { printf 'none\n'; return 1; }
  r_res="$(printf '%s' "$receipt" | LC_ALL=C cut -f2)"
  [ "$r_res" = "green" ] || { printf 'red\n'; return 1; }
  tid="$(felix_tree_id "$root" "$home" 2>/dev/null)" || tid=""
  r_tid="$(printf '%s' "$receipt" | LC_ALL=C cut -f1)"
  # An empty id from a git that could not run is no news about the tree either,
  # and "the tree changed" would be the same unread fact. A receipt handed in
  # reaches this line with git never asked.
  if [ -z "$tid" ] && command -v felix_git_runs >/dev/null 2>&1 && ! felix_git_runs gwhy; then
    printf 'stale\t%s, so this tree cannot be identified and no receipt can be confirmed for it\n' "$gwhy"; return 2
  fi
  if [ -z "$tid" ] || [ "$r_tid" != "$tid" ]; then
    printf 'stale\tthe tree changed since the receipt\n'; return 1
  fi
  # Six fields: written before the epoch existed, by an engine that could not
  # say what its verdict rested on. Not current; one gate run rewrites it.
  if [ "$(printf '%s' "$receipt" | LC_ALL=C awk -F'\t' '{ print NF }')" -lt 7 ]; then
    printf 'stale\tthe receipt predates the epoch, so what it rests on is not recorded; run felix gate\n'; return 1
  fi
  r_epoch="$(printf '%s' "$receipt" | LC_ALL=C cut -f7)"
  r_comps="$(printf '%s' "$receipt" | LC_ALL=C cut -f8)"
  # `-`: the gate had no epoch to record, which with a green result means the
  # project declares no probes — a probe that could not run turns the gate
  # red, and a red receipt never reaches this line. A verdict resting on
  # nothing Felix reads from reality cannot be confirmed, and running the gate
  # again would write the same `-`, so the remedy named is the table.
  if [ -z "$r_epoch" ] || [ "$r_epoch" = "-" ]; then
    printf 'stale\tthe receipt carries no epoch: this project declares no probes, so nothing here can be confirmed; write %s/probes.tsv\n' "$proj"; return 1
  fi
  if ! command -v felix_epoch_components >/dev/null 2>&1; then
    . "$(dirname "${BASH_SOURCE[0]:-$0}")/epoch.sh" 2>/dev/null || true
  fi
  if ! command -v felix_epoch_components >/dev/null 2>&1; then
    printf 'stale\tthe epoch cannot be read now: epoch.sh is not loaded\n'; return 1
  fi
  comps="$(felix_epoch_components "$proj" "$root" 2>/dev/null)"
  # awk, not grep -q, here and in felix_verify_epoch_fields: it reads every
  # value before it answers, so no writer is cut off for pipefail to misread.
  if printf '%s\n' "$comps" | LC_ALL=C cut -f2 | LC_ALL=C awk '$0 == "-" { u = 1 } END { exit !u }'; then
    printf 'stale\tthe grounded facts cannot be read now, so the receipt cannot be confirmed; run felix gate\n'; return 1
  fi
  now_epoch="$(printf '%s\n' "$comps" | _felix_hash)"
  if [ "$now_epoch" = "$r_epoch" ]; then printf 'current\n'; return 0; fi
  # Which component moved, in the order a reader can act on: the world first,
  # then the tables, then the two that almost never move.
  local s t p r
  s="$(printf '%s' "$r_comps" | LC_ALL=C cut -d, -f1)"; t="$(printf '%s' "$r_comps" | LC_ALL=C cut -d, -f2)"
  p="$(printf '%s' "$r_comps" | LC_ALL=C cut -d, -f3)"; r="$(printf '%s' "$r_comps" | LC_ALL=C cut -d, -f4)"
  if [ "$(printf '%s\n' "$comps" | LC_ALL=C awk -F'\t' '$1 == "topology_version" { print $2 }')" != "$t" ]; then
    printf 'stale\tthe grounded facts moved since the receipt; run felix gate\n'
  elif [ "$(printf '%s\n' "$comps" | LC_ALL=C awk -F'\t' '$1 == "policy_version" { print $2 }')" != "$p" ]; then
    printf 'stale\tthe table set moved since the receipt; run felix gate\n'
  elif [ "$(printf '%s\n' "$comps" | LC_ALL=C awk -F'\t' '$1 == "subject_identity" { print $2 }')" != "$s" ]; then
    printf 'stale\tthe subject moved since the receipt; run felix gate\n'
  elif [ "$(printf '%s\n' "$comps" | LC_ALL=C awk -F'\t' '$1 == "release_target" { print $2 }')" != "$r" ]; then
    printf 'stale\tthe release target moved since the receipt; run felix gate\n'
  else
    printf 'stale\tthe epoch moved since the receipt and no component says why; run felix gate\n'
  fi
  return 1
}

# The two receipt fields the gate records, from one computation: the epoch and
# its components, or `-` and `-` when a component is unknown.
felix_verify_epoch_fields() {
  local proj="$1" root="$2" comps
  if ! command -v felix_epoch_components >/dev/null 2>&1; then
    . "$(dirname "${BASH_SOURCE[0]:-$0}")/epoch.sh" 2>/dev/null || true
  fi
  command -v felix_epoch_components >/dev/null 2>&1 || { printf -- '-\t-\n'; return 0; }
  comps="$(felix_epoch_components "$proj" "$root" 2>/dev/null)"
  if [ -z "$comps" ] || printf '%s\n' "$comps" | LC_ALL=C cut -f2 | LC_ALL=C awk '$0 == "-" { u = 1 } END { exit !u }'; then
    printf -- '-\t-\n'; return 0
  fi
  printf '%s\t%s\n' "$(printf '%s\n' "$comps" | _felix_hash)" \
    "$(printf '%s\n' "$comps" | LC_ALL=C cut -f2 | LC_ALL=C paste -sd, -)"
}

# Every decision, allowed or refused, appended and committed. Nothing else in
# Claude Code records whether verification passed: transcripts carry is_error on
# tool results and Bash results carry no exit code at all. This file is the only
# place the fact exists.
felix_verify_log() {
  local proj="$1" verdict="$2" tid="$3" reason="$4"
  local mem; mem="$(felix_mem_dir "$proj")"
  [ -d "$mem" ] || mkdir -p "$mem" 2>/dev/null || return 0
  printf '%s\t%s\t%s\t%s\n' "$(_felix_now)" "$verdict" "${tid:-none}" "$reason" \
    >> "$mem/verification.log" 2>/dev/null || true
}
