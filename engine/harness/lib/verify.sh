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
    name="$(head -1 "$root/.felix" 2>/dev/null | tr -d '[:space:]')"
    proj="$home/projects/$name"
    if [ -n "$name" ] && [ -d "$proj" ]; then
      fields="$(felix_verify_epoch_fields "$proj" "$root")"
      epoch="$(printf '%s' "$fields" | cut -f1)"; comps="$(printf '%s' "$fields" | cut -f2)"
    fi
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$tid" "$result" "$(_felix_now)" "$gate" \
    "${skipped:--}" "${reported:--}" "${epoch:--}" "${comps:--}" > "$path" 2>/dev/null || true
}

felix_verify_receipt() { cat "$(_felix_receipt_path "$1" "$2")" 2>/dev/null; }

# Is the receipt for this root a current green? One line, and 0 only for
# `current`:
#
#   none                    no receipt
#   red                     the receipt is not green
#   stale <TAB> reason      the tree changed; the receipt predates the epoch or
#                           carries none; the epoch cannot be read now; or a
#                           component moved — the grounded facts, the table
#                           set, the subject, the release target, in that
#                           order of precedence
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
felix_verify_current() {
  local root="$1" home="$2" proj="$3" tid receipt r_tid r_res r_epoch r_comps comps now_epoch
  receipt="$(felix_verify_receipt "$root" "$home" 2>/dev/null)"
  [ -n "$receipt" ] || { printf 'none\n'; return 1; }
  r_res="$(printf '%s' "$receipt" | cut -f2)"
  [ "$r_res" = "green" ] || { printf 'red\n'; return 1; }
  tid="$(felix_tree_id "$root" "$home" 2>/dev/null)" || tid=""
  r_tid="$(printf '%s' "$receipt" | cut -f1)"
  if [ -z "$tid" ] || [ "$r_tid" != "$tid" ]; then
    printf 'stale\tthe tree changed since the receipt\n'; return 1
  fi
  # Six fields: written before the epoch existed, by an engine that could not
  # say what its verdict rested on. Not current; one gate run rewrites it.
  if [ "$(printf '%s' "$receipt" | awk -F'\t' '{ print NF }')" -lt 7 ]; then
    printf 'stale\tthe receipt predates the epoch, so what it rests on is not recorded; run felix gate\n'; return 1
  fi
  r_epoch="$(printf '%s' "$receipt" | cut -f7)"
  r_comps="$(printf '%s' "$receipt" | cut -f8)"
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
  if printf '%s\n' "$comps" | cut -f2 | grep -qx -- '-'; then
    printf 'stale\tthe grounded facts cannot be read now, so the receipt cannot be confirmed; run felix gate\n'; return 1
  fi
  now_epoch="$(printf '%s\n' "$comps" | _felix_hash)"
  if [ "$now_epoch" = "$r_epoch" ]; then printf 'current\n'; return 0; fi
  # Which component moved, in the order a reader can act on: the world first,
  # then the tables, then the two that almost never move.
  local s t p r
  s="$(printf '%s' "$r_comps" | cut -d, -f1)"; t="$(printf '%s' "$r_comps" | cut -d, -f2)"
  p="$(printf '%s' "$r_comps" | cut -d, -f3)"; r="$(printf '%s' "$r_comps" | cut -d, -f4)"
  if [ "$(printf '%s\n' "$comps" | awk -F'\t' '$1 == "topology_version" { print $2 }')" != "$t" ]; then
    printf 'stale\tthe grounded facts moved since the receipt; run felix gate\n'
  elif [ "$(printf '%s\n' "$comps" | awk -F'\t' '$1 == "policy_version" { print $2 }')" != "$p" ]; then
    printf 'stale\tthe table set moved since the receipt; run felix gate\n'
  elif [ "$(printf '%s\n' "$comps" | awk -F'\t' '$1 == "subject_identity" { print $2 }')" != "$s" ]; then
    printf 'stale\tthe subject moved since the receipt; run felix gate\n'
  elif [ "$(printf '%s\n' "$comps" | awk -F'\t' '$1 == "release_target" { print $2 }')" != "$r" ]; then
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
  if [ -z "$comps" ] || printf '%s\n' "$comps" | cut -f2 | grep -qx -- '-'; then
    printf -- '-\t-\n'; return 0
  fi
  printf '%s\t%s\n' "$(printf '%s\n' "$comps" | _felix_hash)" \
    "$(printf '%s\n' "$comps" | cut -f2 | paste -sd, -)"
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
