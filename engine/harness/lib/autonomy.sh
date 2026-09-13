# What Felix may do here without being asked.
#
# Felix removing a file from somebody's product repository, unattended, at
# session start, is the sharpest trust boundary in the system. Everything else
# it does unattended is additive: it injects text, appends a log, or refuses a
# command. This deletes.
#
# So it is opted into per project and never inferred. An absent `autonomy` file
# means nothing is permitted, which is the state every project starts in and
# the state one stays in until somebody types the opt-in themselves. Felix does
# not write this file on a project's behalf, because a permission a system
# grants itself is not a permission.
#
# projects/<p>/autonomy: one capability per line.
#   tidy        remove a lookalike script when Felix already holds that file
#   commission  run the commissioning pipeline with nobody present
#
# Reporting is not listed and never needs opting into. Saying "this exists and
# nothing can reach it" changes nothing on disk.

# The commission grant, and the table it was granted over.
#
# Every other grant here names an action the engine defines. This one names a
# pipeline whose steps come from a project's own commissioning.tsv, and two of
# that table's columns — `when` and `check` — are eval'd in the checkout
# (commission.sh). Today nothing on a hook path evaluates them; the session
# hook says so in as many words, and felix_commission_run has exactly two
# callers, both in the CLI. Granting this puts them on a hook path.
#
# That is the whole of the risk, and it is not about today's table: every check
# in it is a read-only predicate, and the run declares stack.tsv rows without
# installing anything — felix_commission_apply_declares writes a row and a log
# line, and no installer is downstream of it. The risk is that
# projects/<p>/commissioning.tsv is ORDINARY-tier by this project's own
# constitution, so a routine edit to it would otherwise become code that runs
# unattended, forever, with nothing on any surface to show it.
#
# So the grant is bound to the table it was granted over. The policy version —
# already a hash across the table set — is stamped when a person types the
# command, and a background run refuses when the current hash differs. A table
# edited after the grant does not inherit it, and re-arming is a person's act
# of reading what changed. The same shape as the discovery cache's stamp: a
# stale verdict is not a verdict.
felix_autonomy_stamp_path() { printf '%s/autonomy.%s' "$1" "$2"; }

# Does the grant still cover what is on disk?
felix_autonomy_commission_current() {   # proj -> 0 when the stamp matches
  local proj="$1" stamped now
  felix_autonomy_allows "$proj" commission || return 1
  stamped="$(head -1 "$(felix_autonomy_stamp_path "$proj" commission)" 2>/dev/null)"
  [ -n "$stamped" ] || return 1
  command -v felix_commission_policy_version >/dev/null 2>&1 || return 1
  now="$(felix_commission_policy_version "$proj" 2>/dev/null)"
  [ -n "$now" ] && [ "$stamped" = "$now" ]
}

felix_autonomy_allows() {
  local proj="$1" want="$2" line
  [ -n "$want" ] || return 1
  [ -f "$proj/autonomy" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|'#'*) continue ;; esac
    # Trimmed, because a trailing space in a hand-edited file should not be the
    # difference between a permission holding and silently not.
    line="${line%"${line##*[![:space:]]}"}"
    line="${line#"${line%%[![:space:]]*}"}"
    [ "$line" = "$want" ] && return 0
  done < "$proj/autonomy"
  return 1
}

# Remove lookalike scripts, and only where every check holds.
#
# The checks, in order, each one able to stop the removal on its own:
#
#   1. The project opted in. No file, no removal, however safe it looks.
#   2. Felix holds a file of that exact name for this project, so the copy that
#      matters survives regardless of what happens next.
#   3. Git does not track it. A tracked file is part of the repository's stated
#      contents, and deleting one is a change to the project rather than the
#      removal of a stray — a different and much larger act, whoever is right
#      about which copy is better.
#   4. It is not the declared gate, and does not live inside Felix's own home.
#   5. The backup was written and is readable. Nothing is removed on the
#      strength of a copy nobody confirmed.
#
# Emits one line per removal. Silence means nothing was touched.
felix_tidy_safe() {
  local proj="$1" root="$2" home="$3"
  felix_autonomy_allows "$proj" tidy || return 0

  local gate; gate="$(felix_json_str "$proj/project.json" gate 2>/dev/null)"
  local rivals; rivals="$(_felix_rival_gates "$root" "$proj" "$gate" 2>/dev/null)"
  [ -n "$rivals" ] || return 0

  local state f note base backup
  while IFS=$'\t' read -r state f note; do
    [ -n "${f:-}" ] || continue
    # 3. Tracked stays. _felix_rival_gates reports both, and only one of them
    #    is a stray file somebody left behind.
    [ "${state:-}" = "untracked" ] || continue
    base="${f##*/}"
    # 2. Felix holds the copy that matters.
    [ -f "$proj/$base" ] || continue
    # 4. Never the gate, never Felix's own storage.
    [ "$root/$f" -ef "$proj/$gate" ] 2>/dev/null && continue
    # The same repository test as the reporter, and it matters more here. A
    # prefix match against the home is true only when standing in the home, so
    # from a worktree of Felix this guard lapsed entirely — on the one path in
    # the system that deletes. Guard 3 above still held it back (Felix's stored
    # files are tracked, and only untracked ones are removed), so nothing was
    # ever lost; a defence that only works from one directory is not a defence.
    case "$f" in
      projects/*) felix_same_repo "$root" "${home:-/nonexistent}" && continue ;;
    esac

    # 5. Copy first, confirm the copy, then remove. A backup nobody checked is
    #    the same as no backup at the moment it turns out to matter.
    mkdir -p "$home/state/rivals" 2>/dev/null || continue
    backup="$home/state/rivals/$(basename "$proj")-$(printf '%s' "$f" | tr '/' '-')"
    cp "$root/$f" "$backup" 2>/dev/null || continue
    [ -s "$backup" ] || [ ! -s "$root/$f" ] || continue

    rm -f "$root/$f" 2>/dev/null || continue
    printf '%s\n' "$f"
  done <<EOF
$rivals
EOF
}
