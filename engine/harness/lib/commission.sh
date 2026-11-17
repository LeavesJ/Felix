# Commissioning: the first-encounter moment, as a table.
#
# v3.2 §8 names a ten-step pipeline that runs the first time Felix binds a
# checkout, and every stage of it already existed here as a separate command
# a person had to type in the right order — felix new printed the sequence
# instead of running it, which invariant 3 calls a defect. This file is the
# moment those commands answer to. A row names a NEED, the capability it
# serves, the INSTRUMENT the question requires on this machine, a `when`
# that switches it off, the engine stage that ANSWERS it, an independent
# CHECK that decides, and the §8 step it belongs to. The engine never
# decides a row is done: the check does, after the answer ran.
#
# Five computed states, never stored. `done` and `held` are observations —
# the check said yes or no. `not-applicable` asked nothing. `unknown` is the
# state this table exists to make reachable: an instrument that is not
# installed here, a `when` or check whose command does not exist, a `when`
# that answers neither yes nor no, a `when` or check that does not parse, a
# check that says it could not be asked (it exits 2), an engine function a
# check names that this process has not loaded, a checkout that cannot be
# entered, or a lookup the state is read from that could not be made: the
# declared capabilities, or the engine functions a check names. It blocks the
# receipt until the row can be asked: the machine changes, or, for a check
# that said it could not be asked, a run whose answer makes it askable (a
# discovery cache filled). `malformed` counts toward nothing and fails the run.
# A row whose answer is a provider — a skill a session's model runs — is a
# separate class by construction: it is `awaiting` until a file it cannot
# write appears, it holds nothing, and awaiting, stale, partial or answered it
# never decides the receipt (the first three are counted in its awaiting
# field). One whose answer could not be read is `unknown` like any row, and
# makes the receipt indeterminate.
#
# The install policy is not here. Answers call the commands that already
# hold it (stack apply --yes, ready --fix, discover --adopt) and this file
# only asks afterwards whether the check now passes.

for _cml in resolve detect stack probes verify; do
  case "$_cml" in
    resolve) command -v felix_mem_dir       >/dev/null 2>&1 && continue ;;
    detect)  command -v felix_detect        >/dev/null 2>&1 && continue ;;
    stack)   command -v _felix_cap_active   >/dev/null 2>&1 && continue ;;
    probes)  command -v felix_probe_source  >/dev/null 2>&1 && continue ;;
    verify)  command -v _felix_hash         >/dev/null 2>&1 && continue ;;
  esac
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/$_cml.sh"
done
unset _cml
command -v felix_final_filter_lead >/dev/null 2>&1 \
  || . "$(dirname "${BASH_SOURCE[0]:-$0}")/final-filter.sh"

# The table set a receipt is bound to, in fixed order. Every file that decides
# what this project reads, refuses, or installs.
FELIX_COMMISSION_TABLES='project.json capabilities commissioning.tsv stack.tsv profiles.tsv routes.tsv setup.tsv probes.tsv risk.tsv evidence.tsv deny.tsv obligations.tsv'

# The engine stages an answer may name. A form outside this list is malformed:
# the answer column is engine wiring, not a place to write a command.
felix_commission_instruments() {
  printf '%s\n' '-' 'felix:discover --adopt' 'felix:stack apply --yes' \
    'felix:ready --fix' 'felix:toolbox --route' 'felix:obligations --seed' \
    'provider:<plugin>:<skill>'
}

_felix_commission_answer_ok() {
  local LC_ALL=C
  case "${1:-}" in
    -) return 0 ;;
    'felix:discover --adopt'|'felix:stack apply --yes'|'felix:ready --fix'|'felix:toolbox --route') return 0 ;;
    'felix:obligations --seed') return 0 ;;
    provider:[A-Za-z0-9._-]*:[A-Za-z0-9._-]*) return 0 ;;
  esac
  return 1
}

# A check that cannot fail is not a check. A negated pipeline reads met when
# its producer dies. And a final filter, which succeeds whatever came before
# it, can leave a check unable to fail: the second argument is why
# final-filter.sh refused the row, or `-`. It used to be text patterns for
# `| head`, which refused a head inside `$( )` or mid-pipeline, where the check
# can still fail, and let every other filter by. Prints why a check is
# refused, and returns 1 then.
_felix_commission_check_ok() {
  local c="${1:-}" ff="${2:--}"
  [ -n "$c" ] || { printf 'check is empty, so it could not fail'; return 1; }
  case "$c" in '!'*) printf 'check is negated, so it reads met when its producer dies'; return 1 ;; esac
  [ "$ff" = "-" ] || { printf '%s' "$ff"; return 1; }
  return 0
}

# Each commissioning line, led by `-` or the sentence refusing its check, so
# the classifier runs once over the table and not once per row.
_felix_commission_judged() {
  _felix_commission_lines "$1" | felix_final_filter_lead commissioning.tsv
}

_felix_commission_step_ok() {
  case "${1:-}" in -|[123456789]|10) return 0 ;; esac
  return 1
}

_felix_commission_lines() {
  [ -f "$1/commissioning.tsv" ] || return 0
  LC_ALL=C grep -vE '^[[:space:]]*(#|$)' "$1/commissioning.tsv" 2>/dev/null
  return 0
}

# Seven fields exactly. A provider row carries `-` as its check; every other
# row carries a real one. Rows are emitted in file order, because later rows
# consume earlier writes.
felix_commission_rows() {
  local proj="$1" ff need grounds instrument when answer check step
  _felix_commission_judged "$proj" | awk -F'\t' 'NF == 8' \
    | while IFS=$'\t' read -r ff need grounds instrument when answer check step; do
        [ -n "$need" ] || continue
        _felix_commission_answer_ok "$answer" || continue
        _felix_commission_step_ok "$step" || continue
        case "$answer" in
          provider:*) [ "$check" = "-" ] || continue ;;
          *)          _felix_commission_check_ok "$check" "$ff" >/dev/null || continue ;;
        esac
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
          "$need" "${grounds:--}" "${instrument:--}" "${when:--}" "$answer" "$check" "$step"
      done
  return 0
}

# need <TAB> reason, for every line that is not a row.
felix_commission_malformed() {
  local proj="$1" line ff n need grounds instrument when answer check step why
  _felix_commission_judged "$proj" | while IFS= read -r line; do
    ff="${line%%$'\t'*}"; line="${line#*$'\t'}"
    n="$(printf '%s\n' "$line" | awk -F'\t' '{ print NF }')"
    need="$(printf '%s\n' "$line" | cut -f1)"
    if [ "$n" -ne 7 ]; then
      printf '%s\t%s fields where the format has seven\n' "${need:-(unnamed)}" "$n"; continue
    fi
    IFS=$'\t' read -r need grounds instrument when answer check step <<EOF
$line
EOF
    if [ -z "$need" ]; then printf '(unnamed)\tno need named\n'
    elif ! _felix_commission_answer_ok "$answer"; then
      printf '%s\tanswer "%s" is not an engine stage this table may name\n' "$need" "$answer"
    elif ! _felix_commission_step_ok "$step"; then
      printf '%s\tstep "%s" is not one of 1-10 or -\n' "$need" "$step"
    else
      case "$answer" in
        provider:*) [ "$check" = "-" ] || printf '%s\ta provider row carries no check; a file it cannot write decides it\n' "$need" ;;
        *) why="$(_felix_commission_check_ok "$check" "$ff")" || printf '%s\t%s\n' "$need" "$why" ;;
      esac
    fi
  done
  return 0
}

# Every engine function a check names must exist in THIS process, or the row
# is unknown before anything runs. A missing function inside `$(…)` is
# swallowed by the test around it — `[ -z "$(felix_gone)" ]` is true — so the
# exit status alone cannot say the question was never asked.
#
# 0 when every name is loaded, 1 printing the first that is not, and 2 when
# the names could not be read from the text at all. Until 2026-10-01 a grep
# that ran and failed (exit 2 or more, or killed) was swallowed by the
# `|| true` that keeps a check naming no function (grep's 1) from reading
# missing, so a check over a function that is not loaded ran and read done. A
# fork that failed there ended the group before that `|| true`, and read
# unknown under the CLI's pipefail but named no function, and done without it.
# Now the names carry a `.` written only when grep's status says they were
# read, because on bash 3.2 a substitution that cannot make its pipe expands to
# nothing with status 0 (measured). The same with pipefail on or off, and the
# names are walked with no further fork.
#
# IFS is set here because this runs inside command substitutions whose caller
# may have IFS set to a tab for a `read`, and a `for w in $(…)` there sees
# every name as one word, fails on it, and prints a multi-line "missing" that
# the caller's read then truncates. Measured.
_felix_commission_functions_present() {
  local names w IFS=$' \t\n'
  names="$(printf '%s' "$1" | LC_ALL=C grep -oE '(felix_[a-z_]+|cmd_[a-z_]+)'; [ "$?" -le 1 ] && printf .)"
  case "$names" in *.) names="${names%.}" ;; *) return 2 ;; esac
  for w in $names; do
    command -v "$w" >/dev/null 2>&1 || { printf '%s' "$w"; return 1; }
  done
  return 0
}

# One commissioning run at a time, per project.
#
# The run is a sequence of appends — stack.tsv twice, commissioning.log, and a
# play into routes.tsv — and an append is neither atomic nor idempotent. Two
# runs interleaving do not produce a conflict anybody sees; they produce a
# manifest with a row written half by each, or the same capability declared
# twice, and both look like a table somebody typed wrong.
#
# A directory, because mkdir is atomic everywhere and a lock FILE needs a
# create-exclusive that /bin/sh does not portably have.
#
# The pid is written inside it, and that is the difference between this and the
# background refresh's lock. That one may sit there: a refresh that never
# finishes costs a stale cache. This one is taken by a command a person typed,
# and a lock left behind by a killed run would lock the person out of their own
# project with no way to tell that from a run in progress. So a lock whose
# owner is gone is taken over, and only a live owner refuses.
#
# Keyed on the project, not the home: one governed project commissioning must
# not silence another's.
felix_commission_lock() {   # proj, home -> 0 taken, 1 held by a live run
  local proj="$1" home="$2" dir owner
  dir="$home/state/commission/$(basename "$proj").lock"
  mkdir -p "$(dirname "$dir")" 2>/dev/null || return 0
  if mkdir "$dir" 2>/dev/null; then
    printf '%s\n' "$$" > "$dir/pid" 2>/dev/null
    printf '%s' "$dir"; return 0
  fi
  owner="$(head -1 "$dir/pid" 2>/dev/null)"
  # No pid, or a pid nothing answers to: the run that made this is gone.
  case "$owner" in
    ''|*[!0123456789]*) ;;
    *) if kill -0 "$owner" 2>/dev/null; then printf '%s' "$owner"; return 1; fi ;;
  esac
  rm -rf "$dir" 2>/dev/null
  if mkdir "$dir" 2>/dev/null; then
    printf '%s\n' "$$" > "$dir/pid" 2>/dev/null
    printf '%s' "$dir"; return 0
  fi
  # Lost the race to take over. Whoever won is live by definition.
  printf 'another'; return 1
}

felix_commission_unlock() { [ -n "${1:-}" ] && rm -rf "$1" 2>/dev/null; return 0; }

# The unattended resume lives in own.sh, beside the rule that decides whether it
# may run in a checkout. Sourced by path so a caller of this file alone finds it.
command -v felix_commission_resume_bg >/dev/null 2>&1 \
  || { [ -r "$(dirname "${BASH_SOURCE[0]:-$0}")/own.sh" ] && . "$(dirname "${BASH_SOURCE[0]:-$0}")/own.sh"; }

# Run a check or a `when` in the checkout, in-process, with stdin closed, and
# return the status as the text left it: what it returned, what the shell
# ended with if it ended inside the text, or 126 when the checkout cannot be
# entered. 0 is yes and 1 is no; what any other status means is the caller's.
#
# In-process because a row may call the engine (felix_json_str,
# felix_probe_rows, cmd_bootstrap), which a fresh shell does not have. But that
# handed the row the CLI's pipefail, which no other table runner has: probes,
# obligations, setup and maintenance each start a `bash -c`, where
# `producer | grep -q x` is grep's answer. Here grep matching and leaving first
# killed the producer with SIGPIPE, and pipefail turned a line that was found
# into a miss: a done step read held, and a `when` read not-applicable and
# skipped its step. Deterministic once the producer writes more than a pipe
# holds with the match early; three seeded rows have the shape.
#
# So the row runs without pipefail, and so do the engine functions it calls,
# as six of them already do under bin/probes-check and bin/obligations-check.
# Keeping pipefail for those functions alone was built and dropped in review:
# the pipeline statuses the engine reads end, nearly all, in a grep that
# pipefail can only turn from a match into a miss, and carrying it took an
# alias per name, which changed what `type` says inside a row and stopped a row
# defining or sourcing an engine function. nounset stays, so a mistyped
# variable holds a check rather than passing it. What follows, as in a probe, is
# that a pipeline's status is its last stage's, so a check ending in a stage
# that succeeds whatever it is fed (`| tail`) cannot fail unless something
# before it can; the template says so, and _felix_commission_check_ok refuses
# one that cannot (final-filter.sh).
#
# Given a variable name as $3, it also says in that variable how the text
# ended: `returned`, `ended`, `unentered`, or `unasked` when its answer could
# not be read, which returns 2. The status cannot say it. On bash 3.2 an unset
# variable ends the shell running the text with 1, which is what a no returns,
# and so do `exit 1` and the engine's die. So that run writes `returned N` down
# a pipe once the eval is back, the group around it writes `ended N` once the
# run has exited, and the first line is the answer. The reader never waits for
# the pipe to close: bash marks the copy of stdout it saves around the eval
# close-on-exec, so a program the text starts does not hold it, but a job the
# text forks as a shell keeps it (measured: `{ sleep 3; :; } &` held a reader
# waiting for end of file 3 s). What the text writes to its stdout and stderr
# goes nowhere. A text that writes to that saved copy (fd 10) or answers from
# an EXIT trap can forge its answer, and nothing in its process can stop it.
# No locals, because one would hide the caller's variable of that name from
# printf -v.
felix_commission_ask() {
  [ -n "$2" ] && [ "$2" != "-" ] || return 2
  if [ -z "${3:-}" ]; then
    ( cd "$1" 2>/dev/null || exit 126
      set +o pipefail
      eval "$2" ) </dev/null >/dev/null 2>&1
    return
  fi
  set -- "$1" "$2" "$3" "$( { ( exec </dev/null 2>/dev/null
        cd "$1" >/dev/null || { printf 'unentered 126\n'; exit 126; }
        set +o pipefail
        eval "$2" >/dev/null
        printf 'returned %s\n' "$?" )
      printf 'ended %s\n' "$?"; } 2>/dev/null | { read -r _l; printf '%s' "$_l"; } )"
  case "${4##* }" in ''|*[!0123456789]*) set -- "$1" "$2" "$3" "unasked 2" ;; esac
  case "${4% *}" in returned|ended|unentered) ;; *) set -- "$1" "$2" "$3" "unasked 2" ;; esac
  printf -v "$3" '%s' "${4% *}"
  return "${4##* }"
}

# The detail of a row whose check exited 2: with no argument, printed; with
# one, whether that detail is it. felix_commission_state prints it and
# felix_commission_run recognises it, because that is the one unknown a row's
# answer may still change, so it is one string in one place. A function and
# not a variable, so a session's environment cannot stand in for it, and
# printing it forks nothing.
_felix_commission_unasked() {
  local d='the check says it could not be asked here, so whether this is answered is not known'
  [ "$#" -eq 0 ] && { printf '%s' "$d"; return 0; }
  [ "$1" = "$d" ]
}

# state <TAB> detail <TAB> provenance, without running the answer.
felix_commission_state() {
  local proj="$1" root="$2" need="$3" grounds="$4" instrument="$5" when="$6" answer="$7" check="$8"
  local rc how prov="-" missing
  # Only a list that was read can say a capability is not active. One that
  # could not be read is unknown, never not-applicable (2026-10-01).
  if [ "$grounds" != "-" ]; then
    _felix_cap_active "$grounds" "$proj"; rc=$?
    case "$rc" in
      0) ;;
      1) printf 'not-applicable\tcapability %s is not active here\t-\n' "$grounds"; return 0 ;;
      *) printf 'unknown\tthe capabilities this project declares could not be read, so whether %s is active here is not known\t-\n' "$grounds"; return 0 ;;
    esac
  fi
  if [ "$instrument" != "-" ]; then
    if ! ( cd "$root" 2>/dev/null && command -v "$instrument" >/dev/null 2>&1 ); then
      printf 'unknown\tcould not be asked on this machine: %s is not installed\t-\n' "$instrument"; return 0
    fi
    prov="$(felix_probe_source "$root" "$instrument")"
  fi
  if [ "$check" != "-" ]; then
    # The status rides in the text, after a `/` no name holds: a substitution
    # that could not make its pipe gives status 0 and no text, and that must
    # read as not asked, not as every function present.
    missing="$(_felix_commission_functions_present "$check"; printf '/%s' "$?")"
    case "$missing" in */0) rc=0 ;; */1) rc=1 ;; *) rc=2 ;; esac
    missing="${missing%/*}"
    if [ "$rc" -eq 1 ] && [ -n "$missing" ]; then
      printf 'unknown\tthe engine function %s is not loaded here, so the check could not be asked\t%s\n' "$missing" "$prov"; return 0
    elif [ "$rc" -ne 0 ]; then
      printf 'unknown\tthe engine functions the check names could not be read from it, so whether they are loaded here is not known\t%s\n' "$prov"; return 0
    fi
  fi
  # A `when` says no by returning 1, and nothing else skips the row: anything
  # else is unknown, as a probe's `when` and an obligation's `applies` are.
  # Until 2026-09-25 every status but 0, 126 and 127 read not-applicable, so a
  # `when` that crashed skipped its step. A shell that ended inside the text is
  # unknown even at 1, since an unset variable ends it with 1 too, and applies
  # at 0, which only the text's own exit gives. Parsing is asked first because
  # eval hands a syntax error back as 1 on bash 3.2. The check below is read
  # by its status alone, so a row that reads a lookup's text has to turn that
  # text into a status itself, as the template's rows have since #393.
  if [ "$when" != "-" ]; then
    if ! BASH_ENV= "${BASH:-bash}" -n -c "$when" </dev/null 2>/dev/null; then
      printf 'unknown\tthe `when` test does not parse, so it was not run and whether this applies is not known\t%s\n' "$prov"; return 0
    fi
    felix_commission_ask "$root" "$when" how; rc=$?
    case "$how $rc" in
      'returned 0'|'ended 0') ;;
      'returned 1') printf 'not-applicable\tthe `when` test says this does not apply here\t%s\n' "$prov"; return 0 ;;
      'returned 127') printf 'unknown\ta command in the `when` test does not exist here\t%s\n' "$prov"; return 0 ;;
      unentered\ *) printf 'unknown\tthe checkout could not be entered\t%s\n' "$prov"; return 0 ;;
      unasked\ *) printf 'unknown\tthe answer of the `when` test could not be read\t%s\n' "$prov"; return 0 ;;
      ended\ *) printf 'unknown\tthe `when` test ended the shell with status %s before it answered, as an unset variable under set -u does, so whether this applies is not known\t%s\n' "$rc" "$prov"; return 0 ;;
      *) printf 'unknown\tthe `when` test exited %s, which is neither yes nor no, so whether this applies is not known\t%s\n' "$rc" "$prov"; return 0 ;;
    esac
  fi
  case "$answer" in
    provider:*)
      # The provider library decides from the answer file alone — awaiting,
      # stale, partial, answered or unknown — and is loaded by the command and
      # the hook. Sourced alone, this file still knows the row is a provider's.
      if command -v felix_commission_provider_state >/dev/null 2>&1; then
        local pst pdetail pline
        # Captured before the tab-split read, as in felix_commission_run: inside
        # its heredoc the topology was hashed under the tab IFS, and a checkout
        # path with a space then read an answer stale that session-start and
        # the request call current.
        pline="$(felix_commission_provider_state "$proj" "$root" "$need")"
        IFS=$'\t' read -r pst pdetail <<PROV
$pline
PROV
        [ "$pst" = "answered" ] && prov="$(felix_commission_answer_provenance "$proj" "$need")"
        printf '%s\t%s\t%s\n' "$pst" "$pdetail" "$prov"
      else
        printf 'awaiting\ta session runs %s and records its answer; nothing here can\t%s\n' \
          "${answer#provider:}" "$prov"
      fi
      return 0 ;;
  esac
  # A check says yes with 0 and no with any status but these three, which say
  # it could not be asked: 126 and 127, and 2, which a check returns for
  # itself (2026-10-08). Until then 2 was a no, so a row whose lookup said it
  # could not answer, as felix_toolbox_unwired does over a declared list it
  # could not read, read held: a person's queue, OBSERVED, and a receipt that
  # passed. 2 is what grep, test, diff and make -q return when they could not
  # answer, and what the `when` above already reads as unknown. The check is
  # parsed first, as the `when` is, because eval hands a syntax error back as
  # 1 on bash 3.2 and as 2 on bash 5, and a check that does not parse would
  # then read held on one and unknown on the other.
  if ! BASH_ENV= "${BASH:-bash}" -n -c "$check" </dev/null 2>/dev/null; then
    printf 'unknown\tthe check does not parse, so it was not run and whether this is answered is not known\t%s\n' "$prov"; return 0
  fi
  felix_commission_ask "$root" "$check"; rc=$?
  case "$rc" in
    0)   printf 'done\tthe check passes\t%s\n' "$prov" ;;
    2)   printf 'unknown\t'; _felix_commission_unasked; printf '\t%s\n' "$prov" ;;
    126) printf 'unknown\tthe checkout could not be entered\t%s\n' "$prov" ;;
    127) printf 'unknown\ta command in the check does not exist here\t%s\n' "$prov" ;;
    *)   printf 'held\tthe check does not pass\t%s\n' "$prov" ;;
  esac
  return 0
}

# One line per row: need state class answer step detail provenance.
# $3 names a function that runs a `felix:` answer in-process and returns its
# status; `-` runs nothing, which is what --status and the gate use.
felix_commission_run() {
  local proj="$1" root="$2" runner="${3:--}" tpl="${4:-}"
  local need grounds instrument when answer check step st detail prov out arc line rrc
  local uncomputed="this row's state could not be computed, so whether it holds is not known"
  export FELIX_PROJECT="$proj" FELIX_PROJECT_NAME="$(basename "$proj")" \
         FELIX_ROOT_DIR="$root" FELIX_MEMORY_DIR="$(felix_mem_dir "$proj")"
  [ -n "${FELIX_HOME_DIR:-}" ] && export FELIX_HOME_DIR
  felix_commission_rows "$proj" | while IFS=$'\t' read -r need grounds instrument when answer check step; do
    [ -n "$need" ] || continue
    # The state line is captured BEFORE the tab-split read, never inside its
    # heredoc: a substitution expanded under `IFS=$'\t' read` inherits that
    # IFS, and the guard above then read four function names as one.
    line="$(felix_commission_state "$proj" "$root" "$need" "$grounds" "$instrument" "$when" "$answer" "$check")"
    # Cleared first, because a read that never ran leaves the previous row's
    # values in place. On bash 3.2 a here-document is a temporary file, and a
    # reviewer measured one that could not be written carrying the row before's
    # `done` onto a row whose check failed.
    st=''; detail=''; prov=''
    IFS=$'\t' read -r st detail prov <<EOF
$line
EOF
    # A state line is read, never trusted. Until 2026-09-25 one that came back
    # empty, as it does when a fork inside the state function fails with
    # EAGAIN (measured with ulimit -u 1), gave a row with no state and class
    # n/a that the counts skipped, so the receipt read commissioned over a row
    # nobody asked. The guard forks nothing, since a failed fork is what it
    # catches. A fork that fails in this loop's own shell is not caught here:
    # it ends the loop, and the rows after it go missing rather than blank.
    # felix_commission_run_complete is how a reader finds them missing.
    _felix_commission_state_known "$st" || { st=unknown; detail="$uncomputed"; prov=-; }
    # A real run writes every provider row's request afresh — the topology it
    # carries is what makes an answer current — and never in --status, which
    # writes nothing. A missing template is a row nobody can answer.
    #
    # And a request that returned 2 is one that could not be written because the
    # declared list could not be read, which is not a missing template. Until
    # 2026-10-01 the request wrote itself over an empty list and this branch
    # never saw the difference; now the row says what happened to the request.
    if [ "$runner" != "-" ] && [ -n "$tpl" ] && command -v felix_commission_request >/dev/null 2>&1; then
      case "$answer" in
        provider:*)
          felix_commission_request "$proj" "$root" "$need" "$tpl" >/dev/null; rrc=$?
          case "$rrc" in
            0) ;;
            2) st=unknown; detail="the request for $need could not be written: the capabilities this project declares could not be read" ;;
            *) st=unknown; detail="no request template for $need under $tpl/commission, so no session can answer it" ;;
          esac ;;
      esac
    fi
    # A row's answer runs when its check said no, and when its check said it
    # could not be asked, because the answer may be what makes it askable:
    # discover --adopt fills the cache the discover check reads. Before
    # 2026-10-08 such a check read held, so this runs the same answers as
    # before and reports them truthfully. No other unknown runs its answer: an
    # instrument, a command or a function that is missing, a checkout that
    # cannot be entered, or a check that does not parse (held until
    # 2026-10-08, so its answer ran then) is not anything an engine stage can
    # change.
    if [ "$runner" != "-" ] && { [ "$st" = "held" ] || { [ "$st" = "unknown" ] && _felix_commission_unasked "$detail"; }; }; then
      case "$answer" in
        felix:*)
          out="$( cd "$root" && "$runner" "$answer" 2>&1 )"; arc=$?
          line="$(felix_commission_state "$proj" "$root" "$need" "$grounds" "$instrument" "$when" "$answer" "$check")"
          st=''; detail=''; prov=''
          IFS=$'\t' read -r st detail prov <<EOF
$line
EOF
          _felix_commission_state_known "$st" || { st=unknown; detail="$uncomputed"; prov=-; }
          detail="ran ${answer#felix:} (exit $arc); $detail" ;;
      esac
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$need" "$st" "$(felix_commission_class "$st" "$answer")" "$answer" "$step" "$detail" "$prov"
  done
  return 0
}

felix_commission_class() {
  case "${1:-}" in
    done|held)                      printf 'OBSERVED' ;;
    unknown|awaiting|stale|partial) printf 'UNKNOWN' ;;
    answered)                       printf 'INFERRED' ;;
    *)                              printf 'n/a' ;;
  esac
}

# The eight states a row can have: done, held, unknown and not-applicable,
# which felix_commission_state computes, and awaiting, stale, partial and
# answered, which a provider row gives (a provider row can be unknown too).
# Anything else is a state line nobody could read. A builtin case, so asking
# forks nothing.
_felix_commission_state_known() {
  case "${1:-}" in
    done|held|unknown|not-applicable|awaiting|stale|partial|answered) return 0 ;;
  esac
  return 1
}

felix_commission_actor() {
  case "${1:-}" in
    felix:*)    printf 'felix' ;;
    provider:*) printf '%s' "$1" ;;
    -)          printf 'person' ;;
    *)          printf -- '-' ;;
  esac
}

# The two hashes validity is derived from. The table set, with a header line
# per file so that where one table ends and the next begins is hashed too (the
# header does not tell an absent file from an empty one: both are the header
# alone); and the detected surfaces.
#
# A table is its bytes when it is a regular file, nothing when it is absent, and
# the one marker line when something is there that is not a regular file, which
# is never opened. Until 2026-10-01 each was `cat`, so a `capabilities` link
# whose target is gone hashed as no file at all, the same as a project that never
# declared one, and a pipe by a table's name was opened and waited on for a writer
# that never came, which hung every receipt check. A regular file, a link to one,
# and no file hash as they did.
#
# A regular file that cannot be read hashes as a second marker line after
# whatever `cat` did print, none for a mode with no read. Until 2026-10-08 its
# errors were discarded and nothing followed, so it hashed exactly as no file and
# as an empty one, and the table set could move from a table to nothing with the
# receipt still current.
felix_commission_policy_version() {
  local proj="$1" f
  # Each table is read only as a regular file. A pipe at any table's path held
  # the cat open for a writer that never came, so every caller of the policy
  # version (the commission grant, the epoch, merge) waited on it forever, and
  # a link to a device read without end (2026-10-01). Anything else at the
  # path is never opened and hashes as the marker line above, not as an absent
  # table; a regular file, a link to one and no file hash as they always did.
  for f in $FELIX_COMMISSION_TABLES; do
    printf '== %s ==\n' "$f"
    if [ -f "$proj/$f" ]; then cat "$proj/$f" 2>/dev/null || printf '<unreadable>\n'
    elif [ -e "$proj/$f" ] || [ -L "$proj/$f" ]; then printf '<not a regular file>\n'
    fi
  done | _felix_hash
}
felix_commission_caps_hash() { felix_detect "$1" 2>/dev/null | LC_ALL=C sort -u | _felix_hash; }
felix_commission_toolchain() { felix_probe_source "$1" claude; }

# Append-only, count-verified, in the shape facts.log holds (facts.sh).
felix_commission_record() {
  local proj="$1" tid="${2:-unknown-tree}" policy="$3" rows="$4"
  local dir log stamp n=0 before after need st cls answer step detail prov
  dir="$(felix_mem_dir "$proj")"; mkdir -p "$dir" 2>/dev/null || return 1
  log="$dir/commissioning.log"
  [ -f "$log" ] || : > "$log" 2>/dev/null || return 1
  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  before="$(wc -l < "$log" 2>/dev/null | tr -dc '0-9')"; [ -n "$before" ] || before=0
  while IFS=$'\t' read -r need st cls answer step detail prov; do
    [ -n "$need" ] || continue
    n=$((n + 1))
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$stamp" "$tid" "$policy" "$need" "$st" "$cls" \
      "$(felix_commission_actor "$answer")" "${prov:--}" "$detail" >> "$log" || return 1
  done <<EOF
$rows
EOF
  [ "$n" -gt 0 ] || return 0
  after="$(wc -l < "$log" 2>/dev/null | tr -dc '0-9')"; [ -n "$after" ] || after=0
  [ "$((after - before))" -eq "$n" ]
}

# Whether a run reported every row the table lists: the same needs, in the
# same order, as many times. felix_commission_run prints its rows from a loop
# in a shell of its own and returns 0 whatever became of that shell, and on
# bash 3.2 a fork that fails there (a state or class substitution, a
# provider's request, the runner) or a pipe it cannot make ends it with 128.
# The rows after that are never printed, missing rather than blank, and
# nothing inside the loop can see it. A reviewer measured a table of three
# rows giving one line, and the receipt read commissioned with the held row
# gone. So the reader counts, against the table read again. A table that lists
# nothing never has a complete run: a run that asked nothing certifies
# nothing. Prints `K of N` when the run is short or wrong, nothing when whole,
# and only the status when given a third argument: the receipt needs no more,
# and every fork it skips is one fewer place for a starved run to die.
#
# Both sides are read by the same awk. The table's side was `cut -f1` until
# review, and BSD cut under a UTF-8 locale stops at the first need holding a
# byte that is not UTF-8, so an honest run of such a table read `3 of 1` on
# every run and no rerun could clear it. awk passes those bytes through, and
# counting records rather than matching `.` counts that row too.
felix_commission_run_complete() {   # proj, out[, quiet] -> 0 whole; 1 and "K of N" otherwise
  local want='' got=''
  want="$(felix_commission_rows "$1" | awk -F'\t' '$1 != "" { print $1 }')"
  got="$(printf '%s\n' "${2:-}" | awk -F'\t' '$1 != "" { print $1 }')"
  [ -n "$want" ] && [ "$want" = "$got" ] && return 0
  [ -z "${3:-}" ] || return 1
  printf '%s of %s' "$(printf '%s' "$got" | awk 'END { print NR }')" \
    "$(printf '%s' "$want" | awk 'END { print NR }')"
  return 1
}

# done held unknown malformed awaiting not-applicable, space separated, and
# always six of them. A count that could not be read prints as `?` in its own
# place, and the function returns 1. Until 2026-10-01 a substitution that came
# back empty left a gap the reader's split closed up, so every count after it
# moved one place left: `2 0 '' 0 0 0` read unknown as 0, and the receipt said
# commissioned.
felix_commission_counts() {
  local rows="$1" malformed="$2" c='' out='' rc=0
  for c in \
    "$(printf '%s\n' "$rows" | LC_ALL=C awk -F'\t' '$2 == "done"' | LC_ALL=C grep -c .)" \
    "$(printf '%s\n' "$rows" | LC_ALL=C awk -F'\t' '$2 == "held"' | LC_ALL=C grep -c .)" \
    "$(printf '%s\n' "$rows" | LC_ALL=C awk -F'\t' '$2 == "unknown"' | LC_ALL=C grep -c .)" \
    "$(printf '%s\n' "$malformed" | LC_ALL=C grep -c .)" \
    "$(printf '%s\n' "$rows" | LC_ALL=C awk -F'\t' '$2 == "awaiting" || $2 == "stale" || $2 == "partial"' | LC_ALL=C grep -c .)" \
    "$(printf '%s\n' "$rows" | LC_ALL=C awk -F'\t' '$2 == "not-applicable"' | LC_ALL=C grep -c .)"; do
    case "$c" in ''|*[!0123456789]*) c='?'; rc=1 ;; esac
    out="$out${out:+ }$c"
  done
  printf '%s' "$out"
  return "$rc"
}

# The project_commissioned receipt (§8 step 10). One line, ten fields, written
# after the last table write of a run. Its validity is never stored: it is
# derived on every read from the two hashes, so a table or a surface moving
# is seen the moment anybody looks.
felix_commission_receipt_path() { printf '%s/state/commission/%s' "$1" "$(basename "$2")"; }
felix_commission_receipt() { cat "$(felix_commission_receipt_path "$1" "$2")" 2>/dev/null; }

# Two things are read before any count is believed, because each failed open
# once. The run must have reported every row the table lists
# (felix_commission_run_complete). And every count must be digits: the counts
# line is read back however it arrived, never trusted to have six numbers,
# since a line with a gap shifts under the split and a line that never came is
# six empty strings that `[ -gt ]` compares, complains about, and falls through
# to commissioned. A count that is not digits is written as `?`, and so is
# every count of a line that was not six words, so the receipt keeps its ten
# fields and never shows a number in a place it did not come from.
felix_commission_receipt_write() {
  local home="$1" proj="$2" root="$3" rows="$4" malformed="$5" path result='' counts=''
  local n_done='' n_held='' n_unk='' n_mal='' n_await='' n_na='' unread=0
  counts="$(felix_commission_counts "$rows" "$malformed")"
  IFS=' ' read -r n_done n_held n_unk n_mal n_await n_na <<EOF
$counts
EOF
  # Fewer than six words is a gap the split closed up, and more is a line
  # nobody wrote, so no count in it is where it says it is.
  case "$n_na" in ''|*' '*) n_done='' n_held='' n_unk='' n_mal='' n_await='' n_na='' ;; esac
  case "$n_done"  in ''|*[!0123456789]*) n_done='?';  unread=1 ;; esac
  case "$n_held"  in ''|*[!0123456789]*) n_held='?';  unread=1 ;; esac
  case "$n_unk"   in ''|*[!0123456789]*) n_unk='?';   unread=1 ;; esac
  case "$n_mal"   in ''|*[!0123456789]*) n_mal='?';   unread=1 ;; esac
  case "$n_await" in ''|*[!0123456789]*) n_await='?'; unread=1 ;; esac
  case "$n_na"    in ''|*[!0123456789]*) n_na='?';    unread=1 ;; esac
  if [ "$unread" -ne 0 ]; then result=indeterminate
  elif ! felix_commission_run_complete "$proj" "$rows" quiet; then result=indeterminate
  elif [ "$n_unk" -gt 0 ] || [ "$n_mal" -gt 0 ]; then result=indeterminate
  elif [ "$n_held" -gt 0 ]; then result=held
  else result=commissioned; fi
  path="$(felix_commission_receipt_path "$home" "$proj")"
  mkdir -p "$(dirname "$path")" 2>/dev/null || return 1
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$(felix_commission_policy_version "$proj")" "$(felix_commission_caps_hash "$root")" \
    "$(felix_commission_toolchain "$root")" "$result" "$n_done" "$n_held" "$n_unk" "$n_mal" "$n_await" > "$path" 2>/dev/null \
    || return 1
  printf '%s' "$result"
}

# Prints one word or reason; returns 0 only when the receipt is current.
felix_commission_receipt_valid() {
  local home="$1" proj="$2" root="$3" line policy caps tool result
  line="$(felix_commission_receipt "$home" "$proj")"
  [ -n "$line" ] || { printf 'never commissioned on this machine'; return 1; }
  policy="$(printf '%s' "$line" | cut -f2)"; caps="$(printf '%s' "$line" | cut -f3)"
  tool="$(printf '%s' "$line" | cut -f4)"; result="$(printf '%s' "$line" | cut -f5)"
  if [ "$policy" != "$(felix_commission_policy_version "$proj")" ]; then
    printf 'stale (table set moved; run felix commission)'; return 1
  fi
  if [ "$caps" != "$(felix_commission_caps_hash "$root")" ]; then
    printf 'stale (detected surfaces moved; run felix commission)'; return 1
  fi
  if [ "$result" = "indeterminate" ]; then
    printf 'indeterminate (a row could not be asked here; run felix commission)'; return 1
  fi
  # A receipt this engine writes says commissioned, held or indeterminate, over
  # five counts that are digits. Anything else was written by a run whose
  # counts never came back, or by something that is not a run, and until
  # 2026-10-01 it was read as valid: `commissioned` over five empty counts
  # passed here. One awk, so that a fork failing reads as unreadable too.
  case "$result" in
    commissioned|held) ;;
    *) printf 'unreadable (the receipt says "%s", which no run writes; run felix commission)' "$result"; return 1 ;;
  esac
  if ! printf '%s\n' "$line" | awk -F'\t' '{ for (i = 6; i <= 10; i++) if ($i !~ /^[0-9]+$/) bad = 1 } END { exit bad }'; then
    printf 'unreadable (the receipt'"'"'s counts are not numbers; run felix commission)'; return 1
  fi
  if [ "$tool" != "$(felix_commission_toolchain "$root")" ]; then
    printf '%s (the claude cli changed since: %s, now %s)' "$result" "$tool" "$(felix_commission_toolchain "$root")"
  else
    printf '%s' "$result"
  fi
  return 0
}

# What nothing serves, reaches, or grounds — enumerated from the checkout and
# the declaration, never from this table. cap <TAB> served <TAB> reached <TAB> grounded.
#
# 0 with the rows on stdout, and 2 with nothing printed when the declared list
# could not be read, or the union of it and what felix_detect shows could not be
# made. Until 2026-10-01 an unread list was an empty one, so every capability only
# the project declares dropped out of the union and out of "surfaces nothing
# serves", and the section said fewer did than do. Both are read once with
# felix_capture and the union walked in this shell. The first pass had no
# here-document loop here, a pipe fed the loop; the failure it had was
# felix_has_line's here-document on the probe rows, which is a temporary file on
# bash 3.2, and one that could not be written called every grounded capability
# ungrounded. The fix that mattered is membership by case. The probe rows are a
# plain substitution, since a pipeline that ends in a sort has no status worth
# asking of an absent table.
felix_commission_gaps() {
  local proj="$1" root="$2" cap served reached grounded probed declared="" union="" rest nl=$'\n'
  felix_declared_into declared "$proj" || return 2
  felix_capture union _felix_capability_union "$root" "$declared" || return 2
  probed="$(command -v felix_probe_rows >/dev/null 2>&1 && felix_probe_rows "$proj" | cut -f2 | LC_ALL=C sort -u)"
  rest="$union"
  while [ -n "$rest" ]; do
    cap="${rest%%$nl*}"
    if [ "$cap" = "$rest" ]; then rest=""; else rest="${rest#*$nl}"; fi
    [ -n "$cap" ] || continue
    served=no; reached=no; grounded=no
    # One awk that decides at the end, not awk into grep -q: grep quitting
    # at the first row can kill awk mid-write, and pipefail reads that as
    # nothing serving the capability.
    _felix_stack_rows "$proj" 2>/dev/null | awk -F'\t' -v c="$cap" '$5 == c { s = 1 } END { exit !s }' && served=yes
    [ -n "$(felix_toolbox_route_for "$proj" "$cap" 2>/dev/null)" ] && reached=yes
    case "$nl$probed$nl" in *"$nl$cap$nl"*) grounded=yes ;; esac
    [ "$served$reached$grounded" = "yesyesyes" ] && continue
    printf '%s\t%s\t%s\t%s\n' "$cap" "$served" "$reached" "$grounded"
  done
  return 0
}

# Needs the template asks that this project's table lacks.
felix_commission_template_missing() {
  local proj="$1" tpl="$2" have need
  have="$(felix_commission_rows "$proj" | cut -f1)"
  [ -f "$tpl/commissioning.tsv" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$tpl/commissioning.tsv" | cut -f1 | while IFS= read -r need; do
    [ -n "$need" ] || continue
    felix_has_line "$have" "$need" || printf '%s\n' "$need"
  done
  return 0
}

# Rows whose need the template also asks but whose columns differ from the
# template's row for it: need <TAB> the differing columns, in table order.
# A table is cut from the template once; when the template later corrects a
# row, every table cut before keeps the old one and the id-only comparison
# above cannot see it. A project may keep a row on purpose, so this is a
# report and nothing here writes or refuses. Exit 1 with no output when the
# template yields no rows: nothing compared must not read as nothing differs.
# Both tables come through felix_commission_rows, so a row the engine would
# not run is not compared, and the template's first row is its row for a
# need. Each is read once, into a variable, so the exit status is decided
# before anything is compared; the awk reads to the end, so no writer is cut
# off under pipefail. The sentinel (one field, where a row has seven)
# separates the two tables. Fields are compared as strings: awk compares two
# that look like numbers as numbers, and `1` against `1.0` is a difference.
felix_commission_template_drift() {
  local proj="$1" tpl="$2" trows prows
  trows="$(felix_commission_rows "$tpl")"
  [ -n "$trows" ] || return 1
  prows="$(felix_commission_rows "$proj")"
  [ -n "$prows" ] || return 0
  { printf '%s\n' "$trows"; printf '@@\n'; printf '%s\n' "$prows"; } | awk -F'\t' '
    BEGIN { split("grounds instrument when answer check step", name, " ") }
    NF == 1 { mine = 1; next }
    !mine { if (!($1 in seen)) { seen[$1] = 1; for (i = 2; i <= 7; i++) t[$1, i] = $i "" }; next }
    $1 in seen {
      out = ""
      for (i = 2; i <= 7; i++) if (($i "") != t[$1, i]) out = out (out == "" ? "" : " ") name[i - 1]
      if (out != "") printf "%s\t%s\n", $1, out
    }'
  return 0
}

# §8 steps the template marks `rows` that no row here carries: step <TAB> description.
felix_commission_steps_unanswered() {
  local proj="$1" tpl="$2" steps step desc by
  [ -f "$tpl/commission/steps.tsv" ] || return 0
  steps="$(felix_commission_rows "$proj" | cut -f7 | LC_ALL=C sort -u)"
  grep -vE '^[[:space:]]*(#|$)' "$tpl/commission/steps.tsv" | while IFS=$'\t' read -r step desc by; do
    [ -n "$step" ] || continue
    [ "$by" = "rows" ] || { [ "$by" = "none" ] && printf '%s\t%s (nothing built answers it)\n' "$step" "$desc"; continue; }
    felix_has_line "$steps" "$step" || printf '%s\t%s\n' "$step" "$desc"
  done
  return 0
}
