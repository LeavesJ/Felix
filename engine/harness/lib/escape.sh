# What a revert cannot undo.
#
# A tier used to be a function of which file you touched. That is what sent a
# one-line dependency-floor correction to the founder and left it there for a
# day: `pyproject.toml` was yellow because the row said "dependency change", a
# premise about consumers that the path could not carry and nobody re-read.
#
# The question a stop has to answer is not "is this file important". It is
# whether merging writes something outside this tree that `git revert` cannot
# reach. Everything a revert undoes, Felix merges and reports. Everything else
# stops, and the reason it stops is a channel with a name.
#
# Emits: channel <TAB> path <TAB> reason, one line per escape.
# Empty output means nothing escaped and Felix may merge.
#
# Two properties this file exists to hold:
#
#   - **Channels are engine constants.** A project may add escapes through its
#     own table and may never declare one away. A stop a project can argue with
#     is not a stop; it is a default. The engine still names no project — it
#     names states of the world, and `disclose` means the same thing in a Rust
#     repository as in this one.
#   - **Failing to demote is safe; failing to stop is not.** Every uncertain
#     path here escapes. A confinement test that cannot parse a diff withholds
#     the demotion and the row fires, which costs a founder one look. The
#     opposite mistake costs a secret.

# Resolved from this file rather than from PWD, because escapes are computed
# while standing in the governed checkout, never in the harness.
# felix_changed_paths lives in resolve.sh, which every hook and the CLI source
# first. Sourced here too rather than assumed: a lib whose helper is missing
# returns an empty path list, which reads as "nothing changed" and silently
# stops enforcing. That is the same shape as a test that is green because it
# cannot reach the branch it names, and it cost 15 assertions to notice.
if ! command -v felix_changed_paths >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

# Same idiom, and the same argument one notch stronger: what the probe library
# contributes to felix_merge_blockers is a REFUSAL, and a caller that forgot the
# import would lose it. The guard below still stands for the case this cannot
# fix — an engine shipped without the file at all — which fails closed rather
# than passing quietly.
if ! command -v felix_probes_run >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/probes.sh" 2>/dev/null
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/commission.sh" 2>/dev/null
fi
# And the obligation library, for the same reason: the merge boundary asks
# what the project owes, and a judge that could not ask has not shown that
# nothing is owed — the blocker below fails closed on exactly that. Found by
# the self-governed merge fixture, where the pinned kernel is the only copy
# of the engine the judge has.
if ! command -v felix_obligations_run >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/obligations.sh" 2>/dev/null
fi
# And where the merge boundary reads its policy from (policy.sh, trust-plane step 3). Loaded always,
# never "unless felix_policy_open exists": the judge's child shell imports the functions a session
# exported, so that guard would let one of them choose the policy directory. A judge that could not
# load it refuses below rather than reading the working tree.
. "$(dirname "${BASH_SOURCE[0]:-$0}")/policy.sh" 2>/dev/null || :
# And what binds the merge to the provider's base and to objects that hash to their names (bind.sh, trust-plane
# step 3, slice 2), loaded always for the same reason. felix merge refuses when it is not loaded.
. "$(dirname "${BASH_SOURCE[0]:-$0}")/bind.sh" 2>/dev/null || :
# And P's instrument parts run over the candidate (instrument.sh, trust-plane step 3, slice 3), loaded always for
# the same reason. felix merge refuses a self-governed merge when it is not loaded.
. "$(dirname "${BASH_SOURCE[0]:-$0}")/instrument.sh" 2>/dev/null || :

FELIX_ESCAPE_SCAN="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../bin" 2>/dev/null && pwd)/secret-scan"

# Enforcing tables: the files that decide what stops. Shrinking one is the edit
# that cannot be checked by the thing it shrank, because a green produced by a
# narrowed judge certifies itself. Named by shape, not by project.
#
# qualification.tsv is the plainest case of that sentence. Its rows are the
# controls `qualified` holds each checker to, and the gate reads the table the
# branch edited. A branch that deletes a checker's controls or flips what one
# expects is therefore judged by the table it weakened, and passes. A contract
# review found it on 2026-09-22 with nothing on the merge path to stop it.
# Adding a control is free, as it is everywhere else here. Adding a control
# takes on a commitment and does not withdraw one.
#
# An entry is a basename, matched in every governed repository, or a path,
# which has a slash and is matched as the end of the changed path. The schema
# table is a path because it is the engine's own: it judges every other
# table's shape, so a row removed from it is a table the schema check stops
# reading, and a row loosened in place removes the old line, so both fire, and
# adding a row for a new table is free. By basename it would also stop the
# merge of any product that keeps a data file called schemas.tsv.
FELIX_ESCAPE_TABLES='risk.tsv evidence.tsv deny.tsv project.json probes.tsv ecosystem.tsv commissioning.tsv obligations.tsv qualification.tsv engine/harness/templates/schemas.tsv land.tsv'

# The subset whose rows are EXEMPTIONS, and for which "adding is free" is
# backwards. A row in the ecosystem table says "this word is not a stack name"
# or "this file may say it": every row added to it is a case the check stops
# seeing, so the narrowing direction there is growth. The removal-only rule
# above would have let a branch add an allow row for the very file it was
# about to break invariant 1 in, and merge green. Any change to one of these
# fires — the conformance amendments say so in as many words — because there
# is no direction of edit to such a table that a reviewer need not look at.
# "Any change" is every change to a row, compared as the reader reads it: in
# file order and byte for byte (_felix_escape_changed). Only comments and blank
# lines are free.
#
# land.tsv (lib/land-table.sh) is the same case twice over. A resolver row is
# a path the landing actor may settle without a session; a founder or session
# row is one it may not. So adding a resolver row widens, removing a narrowing
# row widens too, and no direction of edit is free: the landing-actor design
# says "any change fires, additions included". A basename, like its siblings,
# because every project keeps its table at projects/<name>/land.tsv and the
# engine names none of them. That errs toward the founder: a product's own
# data file called land.tsv escapes on every change, as one called risk.tsv
# does.
#
# The membership binds from the first engine that carries it. The pull request
# that adds land.tsv here is judged by the engine main already holds, where
# land.tsv is in no list, and its schemas.tsv row is an addition, which is
# free; so that pull request does not escape by itself and is carried to the
# founder by hand.
#
# It is deliberately NOT in FELIX_COMMISSION_TABLES (commission.sh).
# felix_commission_policy_version hashes a header for every name listed there
# whether or not the file exists, so adding the name would move every governed
# project's policy hash on deploy and stale every commission receipt at once.
FELIX_ESCAPE_EXEMPTION_TABLES='ecosystem.tsv land.tsv'

# Merging this causes a job to run holding whatever secrets the repository has.
# The revert restores the YAML. It does not un-run the job or un-read the key.
FELIX_ESCAPE_EXECUTE='^\.github/(workflows|actions)/'

# Merging this grants Felix a power it then holds in every session after it,
# and the stamp beside it says which table the grant was read against.
#
# The file IS the permission: writing it is granting it. That is why it exists
# as a file a person edits rather than a flag a command sets, and why nothing
# else in the engine may write it. But a file a person edits is also a file a
# `git add -A` sweeps up, and that is what happened: a grant created while
# testing the granted path was committed in a pull request whose own body said
# the grant was ungranted and the founder's to make. Nothing stopped it,
# because nothing here named the file.
#
# So it is an escape, on any change in either direction. A revert takes the
# word back and does not un-run the sessions Felix ran with it — the marker's
# own argument, one file over. A revoke is the safe direction and fires too,
# on the rule this file already holds: failing to demote costs one look, and
# failing to stop costs the thing the governance exists for.
#
# Named by shape. projects/<name>/autonomy exists for every governed project,
# and the engine names none of them.
#
# The shape also matches autonomy.lock, felix autonomy's writer lock
# (felix_autonomy_lock, autonomy.sh). That is an empty directory, which git
# does not track, so it never reaches a diff and this never fires on it.
FELIX_ESCAPE_AUTHORITY='(^|/)projects/[^/]+/autonomy(\.[a-z]+)?$'

# exception: the table of grants that clear a TASK_BLOCKING obligation at the
# task moment (amendments §3). The engine reads it from the base ref, never
# the working tree, so writing a row does nothing; MERGING the row is what
# makes it a grant, and that is the act a session may not perform for itself.
# Any change fires, additions included — the amendment says so in those
# words, and a path channel is the shape that cannot be argued down by a
# confine: creation, a new row, a comment, a deletion, all escape.
FELIX_ESCAPE_EXCEPTION='(^|/)projects/[^/]+/exceptions\.tsv$'

# Rows already written are not restored by reverting the code that wrote them.
FELIX_ESCAPE_DURABLE_PATH='(^|/)(migrations|alembic)(/|$)|^prisma/migrations/'
FELIX_ESCAPE_DURABLE_ADDED='(DROP TABLE|TRUNCATE |DELETE FROM [^W]*$)'

# Whether a changed path is one of a list's tables: an entry without a slash is
# a basename and matches in any directory; one with a slash is a path and
# matches only as the whole path or its end. The list is split by awk, never
# by an unquoted expansion, so no entry is ever a glob.
_felix_escape_listed() {
  printf '%s\n' "$2" | P="$1" LC_ALL=C awk '
    { for (i = 1; i <= NF; i++) {
        t = $i; p = ENVIRON["P"]
        if (index(t, "/")) { if (p == t || substr(p, length(p) - length(t)) == "/" t) found = 1 }
        else { sub(/.*\//, "", p); if (p == t) found = 1 } } }
    END { exit !found }'
}

# Whether every changed line in a file stays inside what a row said was safe.
#
# Returns 0 when the change is confined and the row should NOT fire. The
# manifest case is the reason this exists: `pyproject.toml` genuinely is
# dangerous, because it configures the gate as well as declaring dependencies,
# and one added `addopts` line deletes tests without touching a test. So the row
# stays and stops firing only for the shape it was demoted for.
#
# Package-name equality is checked alongside the line pattern. Without it,
# swapping one dependency for another passes the constraint regex while changing
# what the code actually imports.
_felix_escape_confined() {
  local root="$1" base="$2" f="$3" confine="$4" hunk plus minus
  [ -n "$confine" ] && [ "$confine" != "-" ] || return 1

  # Each source read to the end, or the row fires (2026-10-08). With the file
  # itself replaced by a named pipe, the working-tree diff exited 128 and gave
  # nothing. The committed hunk alone was confined, so the row was demoted over
  # a change nobody could read. The committed hunk is asked only where it can
  # exist. With no base, or no commit yet, `...HEAD` fails for want of a
  # commit, and an empty answer there was always the right one.
  #
  # No external diff, no textconv and no colour (2026-10-08): the first two could
  # print a confined-looking hunk for a change that is not one. A textconv that printed
  # `liba>=1.0` for the old deps.txt and `liba>=2.0` for one that added evilpkg
  # demoted the row. Why per call: above _felix_git_patch in resolve.sh. A
  # binary marking leaves no +/- line here, so the row fires, as it should.
  local one all=""
  if [ -n "$base" ] && git -C "$root" rev-parse -q --verify HEAD >/dev/null 2>&1; then
    _felix_git_read one git -C "$root" diff --no-ext-diff --no-textconv --no-color -U0 "$base...HEAD" -- "$f" || return 1
    all="$one"
  fi
  _felix_git_read one git -C "$root" diff --no-ext-diff --no-textconv --no-color -U0 --cached -- "$f" || return 1
  all="$all
$one"
  _felix_git_read one git -C "$root" diff --no-ext-diff --no-textconv --no-color -U0 -- "$f" || return 1
  all="$all
$one"
  hunk="$(printf '%s\n' "$all" | LC_ALL=C grep -E '^[-+]' | LC_ALL=C grep -vE '^(\+\+\+|---)')"
  [ -n "$hunk" ] || return 1

  # Any line outside the confine means the row fires. A here-string, not a
  # pipe: grep -q stops at the first such line, and a printf still writing a
  # long hunk dies of SIGPIPE, which pipefail reads as every line confined.
  LC_ALL=C grep -qvE "$confine" <<<"$hunk" && return 1

  plus="$(printf '%s\n' "$hunk"  | LC_ALL=C grep '^+' \
          | LC_ALL=C sed -E 's/^\+[^A-Za-z0-9]*([A-Za-z0-9._-]+).*/\1/' | LC_ALL=C sort)"
  minus="$(printf '%s\n' "$hunk" | LC_ALL=C grep '^-' \
          | LC_ALL=C sed -E 's/^-[^A-Za-z0-9]*([A-Za-z0-9._-]+).*/\1/' | LC_ALL=C sort)"
  [ "$plus" = "$minus" ] || return 1
  return 0
}

# Did the number of lines matching a pattern go down?
#
# Reached by a `confine` written as `count:<pattern>`. A confine always names
# what must still be true for the row not to fire; the prefix says how to read
# it. Bare means "every changed line looks like this". `count:` means "there are
# at least as many of these as there were".
#
# Spelled in the value rather than inferred from the channel. Inferring it was
# tried first and made one column mean two things depending on a different
# column, which is unreadable in a table somebody edits by hand.
#
# Counting rather than comparing identity, because a verifier is judged by how
# much it checks and not by which lines it is written on. Comparing identity
# fires on every refactor and on most ordinary edits, and a stop that fires
# constantly is one people learn to route around — which is worse than no stop,
# since it also teaches them to route around the ones that matter.
_felix_escape_fewer() {
  local root="$1" base="$2" f="$3" pattern="$4" before after
  before="$(git -C "$root" show "$base:$f" 2>/dev/null | LC_ALL=C grep -cE "$pattern")"
  after="$( felix_file_at "$root" HEAD "$f" | LC_ALL=C grep -cE "$pattern")"
  [ "${after:-0}" -lt "${before:-0}" ]
}

# Non-comment, non-blank lines present at base and gone at HEAD.
#
# Static blobs on both sides, never two live runs. Running the gate twice to
# compare is nondeterministic against the plugin cache and the two runs clobber
# each other's log; a comparison whose inputs move is not a comparison.
#
# Trailing commas are stripped before comparing, and that is not cosmetic. JSON
# has no trailing comma, so adding a key rewrites the line above it — meaning a
# literal comparison reads every addition to project.json as a removal and fires
# on the most ordinary edit there is. Caught on the commit that declared
# `consumers`, which added two keys and removed nothing. A genuine removal takes
# its whole line with it and is still caught.
# Locale, 2026-10-08: sed stopped at a byte that was not UTF-8 and hid every
# removal below it. The rules are above felix_json_str in resolve.sh.
#
# Only a JSON file forgives the comma (trust-plane step 3, spec S3). Stripped
# from every table, it made a TSV row and the same row with `,` appended read
# as one: appending a comma to a risk.tsv row's `count:` confine stops that
# row counting anything (no line ends in a comma), and the edit that did it
# was no change here, so it landed on green and loosened every merge after it.
_felix_escape_lines() {
  local strip='s/[[:space:]]*,[[:space:]]*$//'
  case "$3" in *.json) ;; *) strip='s/^//' ;; esac
  felix_file_at "$1" "$2" "$3" \
    | LC_ALL=C grep -vE '^[[:space:]]*(#|$)' \
    | LC_ALL=C sed -E "$strip" \
    | LC_ALL=C sort -u
}

_felix_escape_shrank() {
  local root="$1" base="$2" f="$3" before after
  before="$(_felix_escape_lines "$root" "$base" "$f")"
  [ -n "$before" ] || return 1
  after="$(_felix_escape_lines "$root" HEAD "$f")"
  # 2026-10-08: comm compares in its locale's collation, and both sides are
  # sorted in C. Under LANG=en_US.UTF-8, an added row that sorts before an
  # existing one in bytes and after it in the locale (Zulu and _under) made
  # comm print a row nobody removed, so a pure addition read as a removal.
  # Every sort, comm, join and uniq in the engine runs as LC_ALL=C <tool>,
  # which tests/run lints.
  [ -n "$(LC_ALL=C comm -23 <(printf '%s\n' "$before") <(printf '%s\n' "$after"))" ]
}

# Any change to the rows of an exemption table: the non-comment, non-blank
# lines of the two sides, in file order and byte for byte, differ. Same static
# blobs and the same comment stripping, so a reworded comment is still free.
#
# Deliberately not _felix_escape_lines. Its comma stripping is for project.json,
# which is no exemption table, and its sort -u makes order and repetition
# invisible, while the readers of these tables see both. A land table's reader
# refuses a row whose last cell gained a comma, so the row it bound is gone;
# and it keeps the first of two rows on one path, so swapping them changes the
# row that stands. Compared as sets, both edits read as no change, and a
# founder or session row could be dropped or overridden with nobody asked.
# grep -a and the C locale, so a byte that is not text is compared as a byte
# and never turns one side into grep's "Binary file matches".
_felix_escape_rows_exact() {
  felix_file_at "$1" "$2" "$3" | LC_ALL=C grep -avE '^[[:space:]]*(#|$)'
}

_felix_escape_changed() {
  local root="$1" base="$2" f="$3" before after
  before="$(_felix_escape_rows_exact "$root" "$base" "$f"; printf .)"
  after="$(_felix_escape_rows_exact "$root" HEAD "$f"; printf .)"
  [ "$before" != "$after" ]
}

felix_escapes() {
  local proj="$1" base="$2" root="$3" home="${4:-}"
  local paths added f tier kind pattern reason channel confine reviewed=""

  # Before any channel, because a base this repository cannot resolve makes the
  # whole scan unanswerable rather than empty. felix_changed_paths swallows the
  # git error, so the `[ -n "$paths" ]` line below used to return "no escapes"
  # for a branch adding a workflow — `execute`, the one channel risk.tsv's own
  # header calls unconditional — and felix merge printed "nothing in it escaped
  # the tree". The same emptiness cleared every evidence row to n/a.
  #
  # Latent while both governed repositories sit on `main`; live on a --base
  # typo, on a default branch named `master` or `trunk`, on a clone with no
  # local `main`, and on the next governed project. Only a clean tree shows it,
  # because a dirty one still yields a working-tree diff — and a clean tree is
  # what felix merge requires, so that is not a mitigation.
  #
  # `unknown` is a reserved channel, not a risk.tsv one: no table can declare
  # it, so nothing can demote it, and neither `reviewed` nor a confine clause
  # reaches it. Callers must route it away from the founder — it is a typo, not
  # a decision about writing outside the tree.
  #
  # A git that could not run is the same unanswerable scan and not the same
  # typo (2026-11-14), so its row is named GIT and says so, with git's status.
  if [ -n "$base" ]; then
    local brc=0 gwhy=""
    felix_base_resolves "$root" "$base" gwhy || brc=$?
    case "$brc" in
      0) ;;
      2) printf 'unknown\tGIT\t%s, so the base %s was not looked up and nothing was scanned; no channel was consulted\n' "$gwhy" "$base"
         return 0 ;;
      *) printf 'unknown\t%s\tthis base names nothing here, so nothing was scanned; no channel was consulted\n' "$(felix_base_subject "$base")"
         return 0 ;;
    esac
  fi

  # A change git could not read to the end is unknown, on the same reserved
  # channel as a base that names nothing (2026-10-08). A tracked named pipe at
  # A.txt ended `git diff` there, so every line added after it was gone. This
  # scanned an empty change and found it clean, credential and SQL included.
  # The paths it did read still go through every channel below. The unknown row
  # is said once, before them, and blocks the merge however they come out.
  # The reason is git's own (felix_change_why), since a path, an index and a
  # missing merge base each need a different fix.
  local unread=""
  if ! paths="$(felix_changed_paths "$root" "$base")"; then
    unread=1
    printf 'unknown\tCHANGED-PATHS\tgit could not list every path this change touches (%s), so the change was not scanned in full\n' \
      "$(felix_change_why "$root" "$base")"
  fi
  [ -n "$paths" ] || return 0

  if ! added="$(felix_added_lines "$root" "$base")" && [ -z "$unread" ]; then
    unread=1
    printf 'unknown\tADDED-LINES\tgit could not read every line this change adds (%s), so they were not scanned\n' \
      "$(felix_change_why "$root" "$base")"
  fi

  # disclose. Already tuned against real false positives and already in the
  # gate, so this is the same verdict the gate reaches, not a second opinion.
  # Exit 1 is a finding. Any other failure is a scan that did not read the
  # change (2026-10-08), so it is unknown, not a credential and not clean.
  # secret-scan exits 2 for that.
  if [ -x "$FELIX_ESCAPE_SCAN" ]; then
    local scan=0
    ( cd "$root" && "$FELIX_ESCAPE_SCAN" "$base" >/dev/null 2>&1 ) || scan=$?
    case "$scan" in
      0) ;;
      1) printf 'disclose\tADDED-LINES\ta credential in the added lines; history keeps the blob\n' ;;
      *) [ -n "$unread" ] \
           || printf 'unknown\tADDED-LINES\tthe secret scan could not read the added lines, so nothing says they hold no credential\n' ;;
    esac
  fi

  while IFS= read -r f; do
    [ -n "$f" ] || continue

    LC_ALL=C grep -qE "$FELIX_ESCAPE_EXECUTE" <<<"$f" \
      && printf 'execute\t%s\tmerging runs this job holding the repository secrets\n' "$f"

    LC_ALL=C grep -qE "$FELIX_ESCAPE_AUTHORITY" <<<"$f" \
      && printf 'authority\t%s\tmerging grants Felix a power it then holds in every session; a revert does not un-run them\n' "$f"

    LC_ALL=C grep -qE "$FELIX_ESCAPE_EXCEPTION" <<<"$f" \
      && printf 'exception\t%s\tmerging turns a written row into a grant that clears an obligation, and only a person may give one\n' "$f"

    LC_ALL=C grep -qE "$FELIX_ESCAPE_DURABLE_PATH" <<<"$f" \
      && printf 'durable\t%s\trows already written are not restored by a revert\n' "$f"

    # verifier, for the tables that decide what stops. Adding is free — except
    # to a table of exemptions, where adding is the removal.
    if _felix_escape_listed "$f" "$FELIX_ESCAPE_TABLES"; then
      if _felix_escape_listed "$f" "$FELIX_ESCAPE_EXEMPTION_TABLES"; then
        _felix_escape_changed "$root" "$base" "$f" \
          && printf 'verifier\t%s\tits rows exempt things from a check, so any change to it changes what is checked\n' "$f"
      else
        _felix_escape_shrank "$root" "$base" "$f" \
          && printf 'verifier\t%s\tthis decides what stops, and the change removes from it\n' "$f"
      fi
    fi
  done <<EOF
$paths
EOF

  # A here-string for the reason _felix_escape_confined gives: SQL on an early
  # line of a long diff would otherwise read as no SQL at all.
  [ -n "$added" ] && LC_ALL=C grep -qE "$FELIX_ESCAPE_DURABLE_ADDED" <<<"$added" \
    && printf 'durable\tADDED-LINES\tdestructive SQL in the added lines\n'

  # One lookup for the whole diff. `reviewed` is the only channel a verdict can
  # clear, and only a passing one for this exact tree — see lib/review.sh for
  # why this is the single place a model's output permits rather than restricts.
  if [ -n "$home" ] && command -v felix_review_passed >/dev/null 2>&1 \
       && command -v felix_tree_id >/dev/null 2>&1; then
    felix_review_passed "$home" "$proj" "$(felix_tree_id "$root" "$home" 2>/dev/null)" \
      && reviewed=pass
  fi

  # Project-declared escapes: a risk.tsv row carrying a channel. A row with no
  # channel is advisory — it sets a tier and stops nothing — which is what every
  # table written before this column existed is, and they must keep working.
  [ -f "$proj/risk.tsv" ] || return 0
  while IFS=$'\t' read -r tier kind pattern reason channel confine; do
    [ -n "${tier:-}" ] || continue
    [ -n "${channel:-}" ] && [ "${channel}" != "-" ] || continue
    [ "${kind:-}" = "path" ] || continue
    # `unknown` is the engine's word for "nothing was scanned", and every caller
    # keys its whole explanation off it — felix merge says nothing was compared
    # and that no finding above describes the branch. A table declaring it would
    # make a path rule that DID fire render as a scan that never ran, which is
    # the same false all-clear one layer up.
    #
    # Renamed rather than skipped. Skipping would silence a row a project wrote
    # deliberately, and clause 2 of the constitution runs the other way: a table
    # may add to the escapes and may never declare one away. So it still blocks,
    # still escalates, and merely cannot wear the reserved name. Enforced rather
    # than documented, because a convention nothing checks is one the next table
    # anybody writes will break.
    [ "$channel" = "unknown" ] && channel="declared-unknown"
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      LC_ALL=C grep -qE "$pattern" <<<"$f" || continue
      [ "$channel" = "reviewed" ] && [ "$reviewed" = "pass" ] && continue
      case "${confine:-}" in
        count:*) _felix_escape_fewer "$root" "$base" "$f" "${confine#count:}" || continue ;;
        *)       _felix_escape_confined "$root" "$base" "$f" "${confine:-}" && continue ;;
      esac
      printf '%s\t%s\t%s\n' "$channel" "$f" "$reason"
    done <<EOF2
$paths
EOF2
  done <<EOF
$(LC_ALL=C grep -vE '^[[:space:]]*(#|$)' "$proj/risk.tsv")
EOF
}

# Everything standing between this branch and a merge Felix performs itself.
#
# Emits: kind <TAB> subject <TAB> reason. Empty means merge.
#
# Computed from the working tree, the diff and the receipt, so it refuses with
# no network and no credentials. A merge command that learns its own
# preconditions from the network cannot refuse offline, and offline is exactly
# when somebody is most likely to reach for it.
#
# One rule asks GitHub, and only for one kind of receipt: rule C9, below, for a
# gate that reused a suite run (tests:reused). It is the only place this
# function reaches the network, a gate that ran its suite never asks, and where
# GitHub cannot be asked the rule refuses, so offline still refuses.
#
# Three kinds, and they are not the same kind of thing:
#
#   escape      merging writes outside the tree. A founder decision.
#   not-green   no green receipt for this exact tree. Run the gate. (It was
#               named unverified until 2026-11-07, docs/2026-11-07-not-green-deploy-failed-contract.md.)
#   evidence    the change owes a test. That is Felix's work, not a queue item
#               for anybody — the charter calls handing it back a defect — but
#               it is still a blocker, because merging first would ship the
#               unproven thing and the debt would never be collected.
# What a merge is standing on: the branch it would merge, the commit that branch
# points at, and the identity of the tree every verdict below is computed from.
#
# It exists to be compared with itself. `felix merge` runs for about a third of
# a second and shares a working copy with whoever else has a terminal open in
# it, and all three of these can move inside that. Reading them once at the
# start and once again immediately before the merge turns "somebody checked out
# another branch while this ran" from an ungated merge reported as verified into
# a refusal — which is how the rest of this file already behaves.
#
# The tree id is included rather than the branch alone: a peer can leave the
# branch and the commit alone and still edit an uncommitted file, and the
# receipt that was just accepted describes a tree that no longer exists.
felix_merge_checkout() {
  local root="$1" home="${2:-}" tid=""
  command -v felix_tree_id >/dev/null 2>&1 && tid="$(felix_tree_id "$root" "$home" 2>/dev/null)"
  printf '%s\t%s\t%s\n' \
    "$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null)" \
    "$(git -C "$root" rev-parse HEAD 2>/dev/null)" \
    "$tid"
}

# Whether the project's gate workflow has passed on one commit: rule C9 of
# felix_merge_blockers, asked only of a receipt that reports tests:reused.
#
# felix-home has no branch protection, since the plan does not allow it on a
# private repository, and `felix merge` does not ask CI: its boundary needs a
# current green receipt for the exact tree and the evidence rows, and "merge on
# green CI" has been a convention that nothing in the merge path read. Contract
# A lets the receipt's tests verdict come from a suite receipt, a second file a
# session can write. Forging that grants nothing that writing the gate receipt
# does not already grant, but a defect that reused a run it should not have
# would reach a merge with nothing independent behind it. The push security
# review of 2026-10-12 asked for the independent verdict, and the gate
# workflow's own run on this exact commit is it.
#
# Prints nothing and returns 0 when the newest run of that workflow on the
# commit is completed and concluded success. The newest run is the one that
# counts, and an older green one never stands in for it (review finding C9-R1):
# a second run on one head appears when a pull request is reopened after main
# moved, or when the same head sits in two of them, and it tests the head in a
# different base. Otherwise returns 1 and prints what held, as the tail of the
# blocker's reason:
#
#   no run on this commit
#   its run is <status>                 the newest run on it has not completed
#   its run concluded <conclusion>      the newest run on it completed and did not succeed
#   GitHub could not be asked (<what failed>)
#
# Asked the way lib/repair.sh and lib/automerge.sh ask: `gh run list` for the
# workflow felix_gate_workflow names and no other, because without --workflow
# it lists every workflow's runs on the commit, and the unattended repair's or
# GitHub's Dependency Graph passing is no verdict of the gate. The commit is
# asked for with --commit, and each run's own headSha is read as well, so an
# answer about another commit is no evidence however it came to be listed. A run
# whose headSha is not exactly the commit is not a run on it, and one whose
# headSha gh did not give at all cannot be placed, which is unreadable and never
# a pass (review finding C9-R2).
#
# Unreadable is never "no run" and never a pass, and pass is the one word
# anything here is compared to. The count is printed first, as repair.sh does
# for the same reason: `.[]` over an empty list prints nothing, and gh printing
# nothing because it failed would otherwise read as a commit nobody ran.
_felix_merge_gate_held() {
  local proj="$1" root="$2" sha="$3" wf slug runs rc=0 verdict key val tab=$'\t' lib
  lib="$(dirname "${BASH_SOURCE[0]:-$0}")"
  command -v gh >/dev/null 2>&1 || { printf 'GitHub could not be asked (gh is not on PATH)'; return 1; }
  # Sourced when the rule fires, not at load: they name functions and run
  # nothing, and every hook and the CLI load this file, almost none of them to
  # judge a merge. Fails closed on a library that cannot be loaded, like the
  # probe and obligation libraries above.
  command -v felix_gate_workflow >/dev/null 2>&1 || . "$lib/bootstrap.sh" 2>/dev/null
  command -v felix_repo_slug >/dev/null 2>&1 || . "$lib/detect.sh" 2>/dev/null
  if ! command -v felix_gate_workflow >/dev/null 2>&1 || ! command -v felix_repo_slug >/dev/null 2>&1; then
    printf 'GitHub could not be asked (the engine could not load what names the gate workflow and the repository)'
    return 1
  fi
  wf="$(felix_gate_workflow "$proj" 2>/dev/null)" || {
    printf 'GitHub could not be asked (%s)' "$(printf '%s' "$wf" | LC_ALL=C tr '\t\r\n' '   ')"
    return 1
  }
  slug="$(felix_repo_slug "$root" 2>/dev/null)"
  [ -n "$slug" ] || { printf 'GitHub could not be asked (this checkout has no github remote)'; return 1; }
  [ -n "$sha" ] || { printf 'GitHub could not be asked (git could not read the head commit)'; return 1; }
  runs="$(gh run list --repo "$slug" --workflow "$wf" --commit "$sha" --limit 20 \
            --json status,conclusion,headSha \
            -q 'def v: if . == null or . == "" then "-" else . end;
                length, (.[] | "\(.status | v)\t\(.conclusion | v)\t\(.headSha | v)")' 2>/dev/null)" || rc=$?
  [ "$rc" -eq 0 ] || { printf 'GitHub could not be asked (gh run list failed with status %s)' "$rc"; return 1; }
  [ -n "$runs" ] || { printf 'GitHub could not be asked (gh run list printed nothing)'; return 1; }
  # The first line is the count; the rest are runs, newest first as gh lists
  # them, as status, conclusion and the commit the run is on, with `-` for a
  # field gh left empty so no field is ever missing between two tabs.
  #
  # The first run that is on this commit decides, and nothing after it is read:
  # a run before it that cannot be read or placed might have been the newest on
  # this commit, so it is unreadable and not skipped, and an older success never
  # outvotes a newer run that failed or has not finished.
  verdict="$(printf '%s\n' "$runs" | LC_ALL=C awk -F'\t' -v sha="$sha" '
    NR == 1 { if ($0 !~ /^[0-9]+$/) { bad = "gh run list printed no run count"; exit }
              total = $0 + 0; next }
    { lines++
      st = $1; co = $2; on = $3
      if (st !~ /^[A-Za-z0-9_]+$/) { bad = "gh run list listed a run whose status cannot be read"; exit }
      if (on == "-" || on == "") { bad = "gh run list listed a run without the commit it is on"; exit }
      if (on != sha) { other++; next }
      if (st != "completed") { newest = "status\t" st; exit }
      if (co !~ /^[A-Za-z0-9_]+$/) { bad = "gh run list listed a completed run without a conclusion"; exit }
      newest = (co == "success") ? "pass" : ("concluded\t" co)
      exit
    }
    END {
      if (NR == 0) { print "unreadable\tgh run list printed nothing"; exit }
      if (bad != "") { print "unreadable\t" bad; exit }
      if (newest != "") { print newest; exit }
      if (total == 0) { print "none"; exit }
      if (lines == 0) { print "unreadable\tgh run list counted runs and listed none"; exit }
      if (other == lines) { print "none"; exit }
      print "unreadable\tgh run list listed runs that cannot be read"
    }')"
  key="${verdict%%"$tab"*}"; val="${verdict#*"$tab"}"
  case "$key" in
    pass)       return 0 ;;
    none)       printf 'no run on this commit' ;;
    status)     printf 'its run is %s' "$val" ;;
    concluded)  printf 'its run concluded %s' "$val" ;;
    unreadable) printf 'GitHub could not be asked (%s)' "$val" ;;
    *)          printf 'GitHub could not be asked (the answer could not be read)' ;;
  esac
  return 1
}

# The tables and the instruments come from P (policy.sh, trust-plane step 3,
# spec S1 and S2): the body below reads every table from POL, the snapshot of
# the project directory as P holds it, and the commands those tables hold run
# P's instruments. PROJ stays the project's own path for what is said, and the
# snapshot keeps its name, so memory and receipts are found by name as before.
# A policy that cannot be read is one blocker, and nothing else is judged:
# no table in a working tree stands in for it. Always 0, as before, because
# the judge's exit status says whether it could judge, not what it found.
felix_merge_blockers() {
  local proj="$1" base="$2" root="$3" home="$4"
  local _FELIX_POL_TMP="" _FELIX_POL_DIR="" _FELIX_P_TREE="" _FELIX_P_WORDS=""
  # Spec S1.10. A base that names no commit has no P: it is judged as it was before, from the
  # directory, and the escape scan's unknown line refuses it (#56). An empty base, which only a
  # library caller passes (cmd_merge refuses one), reads the directory as before too.
  if [ -z "$base" ] || ! git -C "$root" rev-parse --verify --quiet "$base^{commit}" >/dev/null 2>&1 </dev/null; then
    _felix_merge_blockers_at "$proj" "$base" "$root" "$home" "$proj"
    return 0
  fi
  # No policy library: one policy line, which refuses, and the rest from the directory, so the other
  # libraries' faults are named beside it.
  if ! command -v felix_policy_open >/dev/null 2>&1; then
    printf 'policy\tengine\tthe policy library is not loaded, so nothing says which tables are the authorized ones\n'
    _felix_merge_blockers_at "$proj" "$base" "$root" "$home" "$proj"
    return 0
  fi
  if felix_policy_open "$proj" "$base" "$root" && felix_policy_instruments "$root" "$base"; then
    _felix_merge_blockers_at "$proj" "$base" "$root" "$home" "$_FELIX_POL_DIR"
  fi
  felix_policy_close
  return 0
}

_felix_merge_blockers_at() {
  local proj="$1" base="$2" root="$3" home="$4" pol="$5"
  local tid receipt line
  # owed and behind (lib/land-table.sh), report-only: they write says.log
  # would-refuse rows and print nothing here. A subshell, so nothing either
  # does, an unset variable under the judge's set -u included, can reach this
  # function's output, its status, or the shell that called it; and no input,
  # so nothing it runs can wait on a terminal.
  # The land table reads its own rows at refs/remotes/origin/main (land-table.sh), so it is handed the
  # project's own path: the snapshot sits in no repository it could ask.
  ( felix_land_would_refuse "$proj" "$base" "$root" ) </dev/null >/dev/null 2>&1

  felix_escapes "$pol" "$base" "$root" "$home" | while IFS=$'\t' read -r ch path reason; do
    [ -n "${ch:-}" ] || continue
    # `unknown` blocks like everything else here, and is deliberately not an
    # escape. cmd_merge counts escapes as founder escalations — interruptions
    # per session is the declared objective — and tells the reader that merging
    # writes outside the tree and only they can decide that. An unresolvable
    # base is neither: nobody has to decide a typo, and Felix owes the fix.
    # Reporting it as an escape would inflate the one number this project steers
    # by, with the one kind of event that should never reach a person.
    case "$ch" in
      unknown) printf 'unknown\t%s\t%s\n' "$path" "$reason" ;;
      *)       printf 'escape\t%s\t%s: %s\n' "$ch" "$path" "$reason" ;;
    esac
  done

  # One reader for what a current receipt is (verify.sh), so the boundary and
  # the Stop hook cannot disagree. Stale for a fact that moved outside the tree
  # is named as such, because "run felix gate" on a tree that did not change
  # reads as the hook being broken until the reason is beside it.
  #
  # The receipt is read once, here, and that text is what is judged and what
  # rule C9 reads its reported checks from. felix_verify_current runs the
  # project's probes, about a third of a second, and the gate rewrites the
  # receipt with a truncating `>`: a second read after the judgement need not be
  # the receipt that was judged, and an empty one would have dropped C9 and
  # merged (review finding C9-R3).
  local cur rcpt
  rcpt="$(felix_verify_receipt "$root" "$home" 2>/dev/null)"
  cur="$(felix_verify_current "$root" "$home" "$pol" "$rcpt" 2>/dev/null)" || true
  # A remedy that names a file names it where the reader can open it: the snapshot is gone by then.
  [ "$pol" = "$proj" ] || cur="${cur//"$pol"/"$proj"}"
  # Spec S1.9: receipts are written over the home's tables and read here against P's. Where the two
  # differ, re-running the gate in that home records the same mismatch again, so the one remedy that
  # clears it is named: bring the home to the base first.
  if [ "$pol" != "$proj" ] && command -v felix_commission_policy_version >/dev/null 2>&1 \
     && [ "$(felix_commission_policy_version "$proj")" != "$(felix_commission_policy_version "$pol")" ]; then
    printf 'not-green\thome\tthe home'"'"'s tables at %s are not the ones %s holds, so no receipt written there can be current; bring the home to %s, then run felix gate\n' "$proj" "$base" "$base"
  fi
  case "$cur" in
    current) ;;
    stale*)  printf 'not-green\ttree\t%s\n' "$(printf '%s' "$cur" | cut -f2)" ;;
    *)       printf 'not-green\ttree\tno green receipt for this exact tree; run felix gate\n' ;;
  esac

  # C9 (contract A2, the push security review of 2026-10-12): a gate that
  # reused a suite run (the receipt reports tests:reused) merges only when the
  # project's gate workflow has passed on the exact commit being merged. This
  # repository has no branch protection and `felix merge` asks CI nothing
  # otherwise, so without it a reused verdict would reach a merge with nothing
  # independent behind it. Only a current green receipt is asked about, since
  # any other already blocks above, and only the exact pair tests:reused
  # counts: a receipt that ran its suite, tests:ok included, is judged as it
  # always was and makes no call to gh.
  if [ "$cur" = "current" ]; then
    local rfield hsha held
    rfield="$(printf '%s' "$rcpt" | cut -f6)"
    case ",${rfield}," in
      *,tests:reused,*)
        hsha="$(git -C "$root" rev-parse HEAD 2>/dev/null)"
        if ! held="$(_felix_merge_gate_held "$pol" "$root" "$hsha")"; then
          printf 'not-green\ttests\tthe gate reused a suite run for this tree (tests:reused), and the gate workflow has not passed on %s: %s\n' \
            "$(printf '%s' "${hsha:-HEAD}" | cut -c1-8)" "$held"
        fi ;;
    esac
  fi

  felix_evidence_check "$pol" "$base" "$root" 2>/dev/null \
    | while IFS=$'\t' read -r status name reason; do
        case "${status:-}:${reason:-}" in gap:*|unknown:*"not judged"*) printf 'evidence\t%s\t%s\n' "$name" "$reason" ;; esac
      done

  # probes: the merge boundary is the third place the empty case is refused,
  # and the strongest one Felix reaches without a network. A branch may not
  # land while the project reads nothing from reality, or while a probe cannot
  # see a surface a witness proves is there.
  #
  # Fails closed on a missing library rather than skipping. The `reviewed`
  # lookup above guards itself with command -v because what it does is WIDEN —
  # skipping it withholds a clearance, which is safe. Skipping this would drop
  # a blocker, and an engine that cannot evaluate probes has not established
  # that there is nothing to block on; it has established nothing.
  if ! command -v felix_probes_run >/dev/null 2>&1; then
    printf 'probes\tengine\tthe probe library is not loaded, so nothing was asked of reality\n'
  elif [ ! -f "$pol/probes.tsv" ]; then
    printf 'probes\ttable\tthis project asks reality nothing; write %s/probes.tsv\n' "$proj"
  elif [ -z "$(felix_probe_rows "$pol")" ]; then
    printf 'probes\ttable\t%s/probes.tsv declares no probe, which is a shelf with nothing on it\n' "$proj"
  else
    # A malformed row is not skipped on the way to the rows that parse. It is
    # a predicate somebody meant to read and nothing reads, and cmd_probes
    # --gate already refuses it; a merge boundary that let it through would
    # be the weaker of the two checks on the same table, which is the order
    # they must never be in.
    felix_probe_malformed "$pol" | while IFS= read -r line; do
      [ -n "$line" ] || continue
      printf 'probes\ttable\t%s/probes.tsv: the row for %s names a predicate and no command, or a command and no predicate\n' \
        "$proj" "$line"
    done
    felix_probes_run "$pol" "$root" | felix_probes_blocking \
      | while IFS= read -r line; do
          [ -n "$line" ] || continue
          printf 'probes\t%s\t%s: %s\n' \
            "$(printf '%s\n' "$line" | cut -f1)" \
            "$(printf '%s\n' "$line" | cut -f3)" \
            "$(printf '%s\n' "$line" | cut -f5)"
        done
  fi

  # obligations: what the project has admitted it owes. Only presence and
  # discharge are stored; whether each row applies is recomputed here from
  # the grounded state, so a requirement stops blocking when the tree stops
  # making it applicable and never because somebody wrote it out. A blocking
  # row that applies, or cannot say whether it applies, and is not discharged
  # stops the merge. Absent and empty tables are refused for the reason the
  # probes block gives, and the library failing to load fails closed for the
  # same reason: an engine that could not ask what is owed has not shown that
  # nothing is.
  if ! command -v felix_obligations_run >/dev/null 2>&1; then
    printf 'obligations\tengine\tthe obligation library is not loaded, so what this project owes was not asked\n'
  elif [ ! -f "$pol/obligations.tsv" ]; then
    printf 'obligations\ttable\tthis project admits no obligation; write %s/obligations.tsv\n' "$proj"
  else
    # Refused rows first, before the table is called empty: a row somebody
    # wrote and nothing reads is the more specific fact, and a ledger whose
    # only row is refused should say which row, not just that nothing is owed.
    felix_obligation_malformed "$pol" | while IFS= read -r line; do
      [ -n "$line" ] || continue
      printf 'obligations\ttable\t%s/obligations.tsv: %s\n' "$proj" "$line"
    done
    if [ -z "$(felix_obligation_rows "$pol")" ]; then
      printf 'obligations\ttable\t%s/obligations.tsv admits no obligation, which is a ledger with nothing owed\n' "$proj"
    fi
    felix_obligations_orphans "$pol" | while IFS= read -r line; do
      [ -n "$line" ] || continue
      printf 'obligations\ttable\ta row grounds on %s, which %s/probes.tsv does not declare\n' "$line" "$proj"
    done
    felix_obligations_run "$pol" "$root" release | felix_obligations_blocking release \
      | while IFS= read -r line; do
          [ -n "$line" ] || continue
          printf 'obligations\t%s\t%s %s: %s\n' \
            "$(printf '%s\n' "$line" | cut -f1)" \
            "$(printf '%s\n' "$line" | cut -f4)" \
            "$(printf '%s\n' "$line" | cut -f5)" \
            "$(printf '%s\n' "$line" | cut -f6)"
        done
  fi

  # commission: the fourth consumer of the first-encounter table, and the
  # second place its empty case is refused. A branch may not land while the
  # project has never been commissioned on this machine, while its table set
  # or detected surfaces have moved since it was, or while a row could not be
  # asked here (indeterminate). Never on held rows: a toolbox that is not yet
  # installed is a fact about a machine, not about the code being merged. A
  # row whose check said it could not be asked (exit 2, since 2026-10-08) is
  # unknown, not held, and blocks like any unknown: a discover row whose run
  # could not fill the discovery cache (offline, a marketplace that cannot be
  # read) is one, where until then it read held and did not block. And
  # never on a provider row's answer, which holds nothing by class; a provider
  # row whose answer could not be read is unknown like any row, and blocks
  # through the indeterminate receipt. Fails closed on a missing library for
  # the same reason the probes block does.
  if ! command -v felix_commission_rows >/dev/null 2>&1; then
    printf 'commission\tengine\tthe commissioning library is not loaded, so nothing was asked of this project\n'
  elif [ ! -f "$pol/commissioning.tsv" ]; then
    printf 'commission\ttable\tthis project was never commissioned; write %s/commissioning.tsv (felix commission says how)\n' "$proj"
  elif [ -z "$(felix_commission_rows "$pol")" ]; then
    printf 'commission\ttable\t%s/commissioning.tsv declares no need, which is a shelf with nothing on it\n' "$proj"
  else
    felix_commission_malformed "$pol" | while IFS=$'\t' read -r need why; do
      [ -n "$need" ] || continue
      printf 'commission\ttable\t%s/commissioning.tsv: %s: %s\n' "$proj" "$need" "$why"
    done
    local cwhy
    if ! cwhy="$(felix_commission_receipt_valid "$home" "$pol" "$root")"; then
      printf 'commission\treceipt\t%s\n' "$cwhy"
    fi
  fi
}

# The land table and its report-only checks, which felix_merge_blockers calls
# above. Loaded here, after every function this file defines, so the judge's
# child shell, which sources escape.sh and not land-table.sh, has them; and
# land-table.sh, which loads this file when felix_escapes is missing, finds it
# already loaded. A land library that cannot be loaded costs the report and
# nothing else: the status of sourcing this file stays 0, so the judge does
# not read it as an engine that could not be loaded.
#
# Always, never "unless felix_land_rows exists". The judge's child shell
# imports the functions the session exported, so that guard would let one of
# them stand in for the library. When land-table.sh was sourced first and
# loads this file, it is read a second time, which defines the same functions
# again and stops there, since felix_escapes is defined by then.
. "$(dirname "${BASH_SOURCE[0]:-$0}")/land-table.sh" 2>/dev/null || :
