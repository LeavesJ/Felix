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
  [ -n "$(git -C "$root" status --porcelain -- . "${exargs[@]+"${exargs[@]}"}" 2>/dev/null)" ]
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

felix_tree_id() {
  local root="$1" home="${2:-}" head diff untracked n meta="" prefix="" f
  git -C "$root" rev-parse --git-dir >/dev/null 2>&1 || return 1
  local ex; ex="$(_felix_tree_excludes "$root" "$home")"
  local exargs=()
  while IFS= read -r f; do [ -n "$f" ] && exargs+=("$f"); done <<EOF
$ex
EOF

  head="$(git -C "$root" rev-parse HEAD 2>/dev/null)" || head=""
  if [ -z "$head" ]; then
    # An unborn HEAD has nothing to diff against. A repository with no commits is
    # a real state — it is what `git init` leaves, and what this suite's own
    # fixture is — and every naive implementation of this dies there.
    head="unborn"
    diff="$(git -C "$root" diff -- . "${exargs[@]+"${exargs[@]}"}" 2>/dev/null)"
  else
    diff="$(git -C "$root" diff HEAD -- . "${exargs[@]+"${exargs[@]}"}" 2>/dev/null)"
  fi

  untracked="$(git -C "$root" ls-files --others --exclude-standard \
                 -- . "${exargs[@]+"${exargs[@]}"}" 2>/dev/null | LC_ALL=C sort)"
  n="$(printf '%s' "$untracked" | grep -c . 2>/dev/null)" || n=0

  if [ "${n:-0}" -gt "$FELIX_UNTRACKED_CAP" ]; then
    # A repository in this state has larger problems than receipt precision, and
    # the hook has to stay fast whatever it is handed.
    prefix="coarse:"
    meta="$n untracked"
  elif [ "${n:-0}" -gt 0 ]; then
    local files=()
    while IFS= read -r f; do
      [ -n "$f" ] && files+=("$root/$f")
    done <<EOF
$untracked
EOF
    meta="$(_felix_meta_all "${files[@]}")"
  fi

  printf '%s%s' "$prefix" \
    "$(printf '%s\n%s\n%s' "$head" "$diff" "$meta" | _felix_hash)"
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
felix_verify_record() {
  local root="$1" home="$2" rc="$3" gate="$4" tid="$5" skipped="${6:-}" reported="${7:-}" path result
  [ -n "$tid" ] || return 0
  path="$(_felix_receipt_path "$root" "$home")"
  mkdir -p "$(dirname "$path")" 2>/dev/null || return 0
  result=green; [ "$rc" -eq 0 ] || result=red
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$tid" "$result" "$(_felix_now)" "$gate" \
    "${skipped:--}" "${reported:--}" > "$path" 2>/dev/null || true
}

felix_verify_receipt() { cat "$(_felix_receipt_path "$1" "$2")" 2>/dev/null; }

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
