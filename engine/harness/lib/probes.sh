# Ground truth: what this checkout actually contains, asked of the thing that
# knows rather than of a table somebody wrote.
#
# The rule this file exists to obey is one level stricter than the one
# procedures.tsv obeys. There, Felix may hold stances and may never author the
# enumeration. Here:
#
#   Felix may declare which question to ask reality.
#   Felix may never author the answer.
#
# A row names a predicate and the command that enumerates its members. The
# members come back from the command. Nothing in this file can add one, and a
# row that returns nothing is never quietly treated as a row that returned
# nothing to worry about — which is the entire failure class this is for.
#
# That class stood at five instances by 2026-09-03. Three of them: a security
# audit named a missing request ceiling and the command built to answer it
# dropped the finding; a governed project WROTE the ceiling check and ended it
# with
# `exit 0`, so its scanner printed "All gates passed" while naming four
# unlimited services; a vocabulary grep reported a ceiling absent that was
# shipping and armed. Every one of those is a check that reported clean by
# finding nothing, and no amount of adding checks fixes it. What fixes it is
# refusing to let "found nothing" and "could not look" render the same.
#
# ----------------------------------------------------------------- states ---
#
# Five, and exactly one of them is a claim that nothing is there.
#
#   not-applicable   the `when` command says this probe does not apply here.
#                    No fact, no claim, silent.
#   found            the probe ran and returned members. OBSERVED.
#   empty            the probe ran, returned nothing, AND an independent
#                    witness agrees the surface is absent. OBSERVED, and
#                    still printed every time: empty is never clean.
#   blind            the probe returned nothing while the witness proves the
#                    surface EXISTS. The probe is wrong about reality. BLOCKS.
#   unknown          nothing could be established: the probe failed and no
#                    witness proves the surface either way, the row carries no
#                    witness at all so `empty` was never available to it, or a
#                    command in the probe, the witness or the `when` test does
#                    not exist on this machine. BLOCKS.
#
# The last one is the load-bearing one and it is deliberately expensive. A row
# with no witness can never report `empty`, because a probe with nothing to
# check it against has no way to tell an absent surface from a broken command,
# and every system that guesses there guesses "absent" — which is the
# permissive direction. Supply a witness or accept that the row blocks. That
# is also why the witness cannot be dropped to quiet a row: dropping it turns
# a green `empty` into a blocking `unknown`.
#
# `unknown` is the engine's reserved word for "nothing was scanned" and
# escape.sh already holds it under the same contract: no table may declare it
# and nothing may demote it.
#
# ---------------------------------------------------------------- residual --
#
# Stated here because this is where the system reports its own trustworthiness.
# A probe that FABRICATES members reads as `found` and nothing here can tell.
# The witness catches a probe that sees too little; nothing catches a probe
# that claims too much. Enumeration is the weakest joint of any checker, and it
# cannot be made behavioural — an entrypoint never found is never executed.
# What contains it is that rows are founder-authored, live in an enforcing
# table, and shrinking that table escapes to a person.
#
# And one level up, because the same joint exists there and the report would
# otherwise imply it does not. What says a probe is MISSING is
# felix_probes_gaps,
# whose enumeration comes from felix_detect — patterns somebody wrote. A surface
# no pattern matches produces no capability, so it produces no gap and nobody is
# ever told to probe it. This reports the probes nobody wrote for surfaces Felix
# can already name, and says nothing whatever about a surface Felix cannot name.
# That is the same joint moved one level, not a joint that was removed.

# Sourced rather than assumed, and for the reason escape.sh records at the same
# point: a lib whose helper is missing does not error, it returns empty — and an
# empty answer reads as "nothing to report", which is always the permissive
# direction. felix_has_line and felix_mem_dir come from resolve.sh, felix_detect
# and felix_declared from detect.sh, and the gap report is silently wrong
# without either.
if ! command -v felix_has_line >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi
if ! command -v felix_detect >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/detect.sh"
fi

# Rows a project has written. predicate <TAB> grounds <TAB> when <TAB> probe
# <TAB> witness
#
# Read with awk rather than `IFS=$'\t' read`, for the reason procedures.sh
# records: tab is an IFS *whitespace* character, so bash coalesces runs of it
# and strips trailing ones. `a<TAB><TAB>c` would parse as two fields and shift
# every later column left — silently, and in the direction that turns a
# witness into a probe.
#
# And an empty predicate or probe cell is not a row either — malformed names
# them, and this must not also run them. It did: a five-field row with an empty
# fourth cell was handed to `bash -c ""`, which exits 0 having enumerated
# nothing, and the verdict then came from the witness alone. A witness that
# said "absent" made the row `empty`, which is green. Found by the review, not
# by the suite, which had only ever built the four-field shape of that defect.
#
# Five fields, and SIX is malformed rather than generously truncated. A tab
# inside a probe command splits it in two: awk would hand back a command cut
# off at the tab and read the remainder as the witness, so the row would run
# something nobody wrote and check it against something else nobody wrote. A
# row that cannot be read is not a row to read half of.
felix_probe_rows() {
  local proj="$1"
  [ -f "$proj/probes.tsv" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$proj/probes.tsv" 2>/dev/null \
    | awk -F'\t' 'NF >= 4 && NF <= 5 && $1 != "" && $4 != "" { printf "%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, (NF == 5 ? $5 : "-") }'
  return 0
}

# Rows that name a predicate and then fail to say what to run. The same defect
# procedures.sh found inside its own fix: a row that records no judgement still
# looked like one, closed a gap, and rendered nowhere. Here a malformed row
# must not be able to stand in for a probe, so it is reported separately and
# counts toward nothing.
felix_probe_malformed() {
  local proj="$1"
  [ -f "$proj/probes.tsv" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$proj/probes.tsv" 2>/dev/null \
    | awk -F'\t' 'NF < 4 || NF > 5 || $1 == "" || $4 == "" { print ($1 == "" ? "(unnamed)" : $1) }'
  return 0
}

# Run one command in the checkout being examined and say only whether it
# succeeded. Used for `when` and for the witness, both of which are yes/no.
#
# Never in the harness directory. A probe that inspects "the tree it lives in"
# instead of "the tree it was pointed at" answers about the wrong code, which
# is the mistake cmd_gate already documents at length.
#
# stdin is /dev/null, here and for the probe itself. A command that reads input
# and finds a terminal WAITS, and this runs inside a gate — so one row spelt
# `grep foo` instead of `grep foo file` would hang every gate run on the
# project forever, with no output and nothing to read. Closing stdin turns that
# into an immediate empty result, which the witness then correctly calls blind.
#
# It is not a timeout, and there is no timeout. `timeout(1)` is GNU coreutils
# and is absent from a stock macOS, so a wall-clock limit here would mean either
# a dependency the enforcing path must not have or a background-kill dance
# inside the one code path that has to be boring. A probe that genuinely loops
# still hangs the gate. That is a known limit rather than a solved problem, and
# closing stdin removes the overwhelmingly common cause of it.
#
# Three answers, not two. A `when` or witness command that does not exist on
# this machine exits 127, and that was being read as a plain "no" — so a
# witness spelt `tset -f Cargo.toml` said "the surface is absent" and a row
# that should have blocked went green as `empty`, and a `when` with the same
# typo switched its row off as not-applicable. 127 says nothing about the
# surface; it says the question could not be asked. A root that cannot be
# entered is a third thing again, and was being reported as a missing
# command. Callers read the code: 0 yes, 1 no, 126 unenterable, 127 unaskable.
_felix_probe_ask() {
  local root="$1" cmd="$2" rc
  [ -n "$cmd" ] && [ "$cmd" != "-" ] || return 2
  ( cd "$root" 2>/dev/null || exit 126
    bash -c "$cmd" felix-probe </dev/null >/dev/null 2>&1 )
  rc=$?
  case "$rc" in 0|126|127) return "$rc" ;; *) return 1 ;; esac
}

# Which instrument answered, and a token that changes when it is replaced.
#
# v3.2 §2 asks a fact to carry where it was observed from, and §5 makes a
# provider upgrade an invalidation event. Without it the drift reader can say a
# count moved and cannot say WHY — and "seven more members" reads as the code
# changing when it may be the toolchain changing, which is an hour spent
# looking for a route that was never added.
#
# DERIVED, never declared, and that is the whole design decision here. A sixth
# column would have carried the answer, and it would also have cost the one
# thing the fifth column bought: a tab inside a probe command splits it in two,
# and only a fixed field count catches that. Widening the format to allow six
# would let a tab-corrupted five-column row parse as a valid six-column one.
# The protection is worth more than the resolution.
#
# So this reads the first word of the probe and asks the shell where it is. A
# probe that begins with an assignment, a subshell or a variable identifies
# nothing and says `-`, which is honest and visible: one governed project's
# route probe begins `PY=.venv/bin/python; ...` and gets no identity. Inferring
# one from a shell fragment is the parsing this project already refuses
# elsewhere.
#
# And the limit that matters most, because the report would otherwise imply
# more than this does. The first word is the OUTERMOST command, which is not
# always the authority being consulted. `git ls-files` really is answered by
# git. `python -c "import fastapi; ..."` is answered by FastAPI, and this would
# name python — so a FastAPI upgrade that changes the route count would show a
# moved count and an unchanged instrument, which is the wrong answer stated
# confidently. Rewriting such a row to begin with a bare command would buy the
# appearance of instrument tracking and not the substance. The honest output is
# the one the report gives: those rows identify no instrument, and it says how
# many.
#
# The token is the size in bytes of the resolved file. Not a hash: hashing a
# 40MB binary on every gate run is a cost with no matching benefit, since the
# question is only "is this the same instrument as last time". Not mtime, which
# moves when nothing changed and is not comparable between machines. `wc -c` is
# portable where `stat` is not.
felix_probe_source() {
  local root="$1" cmd="$2" word path size
  word="${cmd%% *}"
  # Anything that is not a bare command name identifies no instrument.
  case "$word" in
    ''|*=*|*'$'*|'('*|'{'*|'"'*|"'"*) printf -- '-'; return 0 ;;
  esac
  path="$( cd "$root" 2>/dev/null && command -v "$word" 2>/dev/null )"
  [ -n "$path" ] || { printf -- '-'; return 0; }
  # A builtin or a function resolves to its own name rather than a path. It is
  # still an identity, and it is one that cannot be versioned — say so by
  # naming it without a token rather than by pretending it has one.
  #
  # A path under the checkout — `engine/harness/bin/hooks-events` — comes back
  # from command -v as written, relative, and is a file all the same: it is
  # the one kind of instrument whose token should move with the tree, because
  # the tree is where it is versioned.
  case "$path" in
    /*) ;;
    */*) path="$root/$path" ;;
    *)  printf '%s' "$word"; return 0 ;;
  esac
  size="$(wc -c < "$path" 2>/dev/null | tr -dc '0-9')"
  [ -n "$size" ] || { printf '%s' "$word"; return 0; }
  printf '%s@%s' "$word" "$size"
}

# The computed state of one row, as: state <TAB> count <TAB> detail
#
# The order of questions is the design. Applicability first, because a probe
# that does not apply must never be run — running it would spend time and, for
# a row whose command only makes sense in the presence of the surface, produce
# a failure that reads as blindness. Then the probe. Then, only when the probe
# came back with nothing, the witness — which is the one question that decides
# between "there is nothing here" and "I cannot see".
felix_probe_state() {
  local root="$1" when="$2" probe="$3" witness="$4"
  local out rc n

  local ask
  if [ -n "$when" ] && [ "$when" != "-" ]; then
    _felix_probe_ask "$root" "$when"; ask=$?
    case "$ask" in
      0) ;;
      126) printf 'unknown\t0\tthe checkout could not be entered, so nothing was asked\n'; return 0 ;;
      127) printf 'unknown\t0\ta command in the `when` test does not exist here, so whether this row applies is not known\n'; return 0 ;;
      *) printf 'not-applicable\t0\tthe `when` command says this does not apply here\n'; return 0 ;;
    esac
  fi

  out="$( cd "$root" 2>/dev/null || exit 126
          bash -c "$probe" felix-probe </dev/null 2>/dev/null )"
  rc=$?
  if [ "$rc" -eq 126 ]; then
    printf 'unknown\t0\tthe checkout could not be entered, so nothing was asked\n'
    return 0
  fi
  # Blank lines are not members. A command that prints a trailing newline and
  # nothing else has enumerated nothing, and counting it as one member is how a
  # probe passes by finding nothing while looking like it found something.
  n="$(printf '%s\n' "$out" | grep -c '[^[:space:]]')"
  [ -n "$n" ] || n=0

  if [ "$rc" -eq 0 ] && [ "$n" -gt 0 ]; then
    printf 'found\t%s\t%s member(s) enumerated\n' "$n" "$n"
    return 0
  fi

  # 127 is never evidence about the surface. bash returns it when a command in
  # the probe does not exist on this machine, which says the probe could not
  # look and says nothing at all about what is there. Deciding this before the
  # witness is consulted matters, because the obvious witness for a tool-shaped
  # probe is that same tool — `cargo metadata` witnessed by `cargo --version` —
  # and on a machine without it both fail together and agree the surface is
  # absent. Two failures with one cause are one failure.
  if [ "$rc" -eq 127 ]; then
    printf 'unknown\t0\ta command in the probe does not exist here, so nothing could be looked at\n'
    return 0
  fi

  # Members AND a failure. `ls -1 a.txt missing` prints a.txt and exits 1, and
  # that is a real shape rather than a corner: any probe spelt as `ls` over
  # several paths takes it the day one of them goes. The enumeration is partial, so
  # it cannot be `found`, and every sentence below this point would say the
  # probe returned nothing, which is false. A report
  # that states something untrue about what it saw is the failure this whole
  # file exists to refuse, so the partial case gets its own words.
  #
  # `unknown` rather than `blind`: blind means the probe saw NONE of a surface
  # the witness proves is there, and this one saw some. How much it missed is
  # exactly what nothing here can say.
  if [ "$n" -gt 0 ]; then
    printf 'unknown\t%s\tthe probe printed %s member(s) and then exited %s, so the enumeration is partial\n' \
      "$n" "$n" "$rc"
    return 0
  fi

  # Nothing came back, one way or the other. Everything from here is about
  # which kind of nothing it was, and the witness is the only thing that can
  # say. A row with none has already lost that argument.
  if [ -z "$witness" ] || [ "$witness" = "-" ]; then
    if [ "$rc" -ne 0 ]; then
      printf 'unknown\t0\tthe probe exited %s and no witness says whether the surface exists\n' "$rc"
    else
      printf 'unknown\t0\tthe probe found nothing and no witness says whether that is true\n'
    fi
    return 0
  fi

  _felix_probe_ask "$root" "$witness"; ask=$?
  case "$ask" in
    0)
      if [ "$rc" -ne 0 ]; then
        printf 'blind\t0\tthe witness proves this surface exists and the probe exited %s\n' "$rc"
      else
        printf 'blind\t0\tthe witness proves this surface exists and the probe enumerated none of it\n'
      fi
      return 0 ;;
    126|127)
      # The witness could not be asked. That is not "absent" — it is the one
      # question that decides between absent and blind, unanswered — and a
      # witness with a typo in it must not be a way of making a row green.
      printf 'unknown\t0\ta command in the witness does not exist here, so absent and blind cannot be told apart\n'
      return 0 ;;
  esac

  # The witness itself may be unaskable — an empty string reaches _felix_probe_ask
  # as a refusal rather than a verdict. Guarded above, so a non-zero here is the
  # witness genuinely reporting the surface absent.
  printf 'empty\t0\tthe probe found nothing and the witness agrees the surface is absent\n'
  return 0
}

# Every row, run. Emits:
#   predicate <TAB> grounds <TAB> state <TAB> count <TAB> detail <TAB> probe
#     <TAB> source
felix_probes_run() {
  local proj="$1" root="$2" line pred grounds when probe witness st
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    pred="$(printf '%s\n' "$line" | cut -f1)"
    grounds="$(printf '%s\n' "$line" | cut -f2)"
    when="$(printf '%s\n' "$line" | cut -f3)"
    probe="$(printf '%s\n' "$line" | cut -f4)"
    witness="$(printf '%s\n' "$line" | cut -f5)"
    st="$(felix_probe_state "$root" "$when" "$probe" "$witness")"
    printf '%s\t%s\t%s\t%s\t%s\n' \
      "$pred" "$grounds" "$st" "$probe" "$(felix_probe_source "$root" "$probe")"
  done <<EOF
$(felix_probe_rows "$proj")
EOF
  return 0
}

# The states that stop work. Named once, here, so that a caller cannot quietly
# disagree about which ones they are.
felix_probes_blocking() {
  awk -F'\t' '$3 == "unknown" || $3 == "blind"'
  return 0
}

# Surfaces this checkout has that no probe reads.
#
# The enumeration is felix_detect's, not this file's, which is the same
# borrowing procedures.tsv does and for the same reason: a gap list Felix wrote
# cannot report the gap Felix did not think of. A capability is a claim about
# what exists here that was reached by pattern-matching filenames and manifests.
# A probe grounding it is the difference between believing that claim and having
# asked the thing that knows.
felix_probes_gaps() {
  local proj="$1" root="$2" grounded cap
  grounded="$(felix_probe_rows "$proj" | cut -f2 | grep -v '^-\?$' | LC_ALL=C sort -u)"
  while IFS= read -r cap; do
    [ -n "$cap" ] || continue
    felix_has_line "$grounded" "$cap" && continue
    printf '%s\n' "$cap"
  done <<EOF
$( { felix_detect "$root" 2>/dev/null; felix_declared "$proj" 2>/dev/null; } | LC_ALL=C sort -u )
EOF
  return 0
}

# And the other direction: a probe claiming to ground a capability that nothing
# enumerates any more. The precedent checks both, because a table is wrong when
# it lacks a row reality has and equally wrong when it keeps one reality
# dropped.
felix_probes_orphans() {
  local proj="$1" root="$2" caps cap
  caps="$( { felix_detect "$root" 2>/dev/null; felix_declared "$proj" 2>/dev/null; } \
           | LC_ALL=C sort -u )"
  while IFS= read -r cap; do
    [ -n "$cap" ] || continue
    felix_has_line "$caps" "$cap" && continue
    printf '%s\n' "$cap"
  done <<EOF
$(felix_probe_rows "$proj" | cut -f2 | grep -v '^-\?$' | LC_ALL=C sort -u)
EOF
  return 0
}
