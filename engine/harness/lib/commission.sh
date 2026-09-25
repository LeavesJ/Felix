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
# installed here, a `when` or check whose command does not exist, an engine
# function a check names that this process has not loaded, or a checkout
# that cannot be entered. It blocks the receipt and nothing can demote it but
# the machine changing. `malformed` counts toward nothing and fails the run.
# A row whose answer is a provider — a skill a session's model runs — is a
# separate class by construction: it is `awaiting` until a file it cannot
# write appears, it holds nothing, and it never reaches the receipt.
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
  case "${1:-}" in
    -) return 0 ;;
    'felix:discover --adopt'|'felix:stack apply --yes'|'felix:ready --fix'|'felix:toolbox --route') return 0 ;;
    'felix:obligations --seed') return 0 ;;
    provider:[A-Za-z0-9._-]*:[A-Za-z0-9._-]*) return 0 ;;
  esac
  return 1
}

# A check that cannot fail is not a check. A negated pipeline reads met when
# its producer dies, and one ending in `head` reports head's status, which is
# success whatever came before it.
_felix_commission_check_ok() {
  local c="${1:-}"
  [ -n "$c" ] || return 1
  case "$c" in '!'*) return 1 ;; esac
  case "$c" in *'| head'|*'|head'|*'| head -'*|*'|head -'*) return 1 ;; esac
  return 0
}

_felix_commission_step_ok() {
  case "${1:-}" in -|[1-9]|10) return 0 ;; esac
  return 1
}

_felix_commission_lines() {
  [ -f "$1/commissioning.tsv" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$1/commissioning.tsv" 2>/dev/null
  return 0
}

# Seven fields exactly. A provider row carries `-` as its check; every other
# row carries a real one. Rows are emitted in file order, because later rows
# consume earlier writes.
felix_commission_rows() {
  local proj="$1" need grounds instrument when answer check step
  _felix_commission_lines "$proj" | awk -F'\t' 'NF == 7' \
    | while IFS=$'\t' read -r need grounds instrument when answer check step; do
        [ -n "$need" ] || continue
        _felix_commission_answer_ok "$answer" || continue
        _felix_commission_step_ok "$step" || continue
        case "$answer" in
          provider:*) [ "$check" = "-" ] || continue ;;
          *)          _felix_commission_check_ok "$check" || continue ;;
        esac
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
          "$need" "${grounds:--}" "${instrument:--}" "${when:--}" "$answer" "$check" "$step"
      done
  return 0
}

# need <TAB> reason, for every line that is not a row.
felix_commission_malformed() {
  local proj="$1" line n need grounds instrument when answer check step
  _felix_commission_lines "$proj" | while IFS= read -r line; do
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
        *) _felix_commission_check_ok "$check" \
             || printf '%s\tcheck is empty, negated, or ends in head, so it could not fail\n' "$need" ;;
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
# Read line by line rather than word-split: this runs inside command
# substitutions whose caller may have IFS set to a tab for a `read`, and a
# `for w in $(…)` there sees every name as one word, fails on it, and prints
# a multi-line "missing" that the caller's read then truncates. Measured.
_felix_commission_functions_present() {
  local w
  # `|| true`: a check naming no engine function makes grep exit 1, and under
  # pipefail that read as "function '' is missing" — every plain check was
  # unknown. The only status that matters is the loop's.
  { printf '%s' "$1" | grep -oE '(felix_[a-z_]+|cmd_[a-z_]+)' || true; } | LC_ALL=C sort -u \
    | while IFS= read -r w; do
        [ -n "$w" ] || continue
        command -v "$w" >/dev/null 2>&1 || { printf '%s' "$w"; exit 1; }
      done
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
    ''|*[!0-9]*) ;;
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

# Run the pipeline with nobody present, when a person has said it may.
#
# Deliberately thin. It takes no lock of its own: cmd_commission takes one, so
# this is just another caller and a run that arrives while a person is
# commissioning gives up quietly — which is the right answer, where two writers
# appending to one manifest is not.
#
# Three refusals before it starts, and each is a different question.
#   - Is it granted at all.
#   - Does the grant still cover the table on disk? An ordinary edit to
#     commissioning.tsv must not inherit a person's consent, because two of its
#     columns are eval'd.
#   - Is there a table to run.
#
# The outcome is written down. A detached run whose output goes to /dev/null
# fails where nobody can see it, which is the shape this repository keeps
# finding: a silence that reads as success. One line per run, so the next
# session can say what the last unattended one did.
felix_commission_resume_bg() {
  local proj="$1" home="$2" bin="${3:-}" log root
  [ -n "$bin" ] && [ -x "$bin" ] || return 0
  command -v felix_autonomy_commission_current >/dev/null 2>&1 || return 0
  felix_autonomy_commission_current "$proj" || return 0
  [ -f "$proj/commissioning.tsv" ] || return 0
  root="$(felix_repo_root "$PWD")"; [ -n "$root" ] || return 0
  log="$home/state/commission/$(basename "$proj").bg.log"
  mkdir -p "$(dirname "$log")" 2>/dev/null || return 0
  (
    felix_close_inherited_fds
    cd "$root" 2>/dev/null || exit 0
    if "$bin" commission >/dev/null 2>&1; then
      printf '%s\tran\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$root" >> "$log"
    else
      printf '%s\tdeclined-or-failed\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$root" >> "$log"
    fi
  ) </dev/null >/dev/null 2>&1 &
  return 0
}

# Run a check or a `when` in the checkout, in-process, with stdin closed.
# 0 yes, 1 no, 126 cannot enter, 127 a command does not exist.
felix_commission_ask() {
  local root="$1" expr="$2" rc
  [ -n "$expr" ] && [ "$expr" != "-" ] || return 2
  ( cd "$root" 2>/dev/null || exit 126
    eval "$expr" ) </dev/null >/dev/null 2>&1
  rc=$?
  case "$rc" in 0|126|127) return "$rc" ;; *) return 1 ;; esac
}

# state <TAB> detail <TAB> provenance, without running the answer.
felix_commission_state() {
  local proj="$1" root="$2" need="$3" grounds="$4" instrument="$5" when="$6" answer="$7" check="$8"
  local rc prov="-" missing
  if [ "$grounds" != "-" ] && ! _felix_cap_active "$grounds" "$proj"; then
    printf 'not-applicable\tcapability %s is not active here\t-\n' "$grounds"; return 0
  fi
  if [ "$instrument" != "-" ]; then
    if ! ( cd "$root" 2>/dev/null && command -v "$instrument" >/dev/null 2>&1 ); then
      printf 'unknown\tcould not be asked on this machine: %s is not installed\t-\n' "$instrument"; return 0
    fi
    prov="$(felix_probe_source "$root" "$instrument")"
  fi
  if [ "$check" != "-" ] && ! missing="$(_felix_commission_functions_present "$check")"; then
    printf 'unknown\tthe engine function %s is not loaded here, so the check could not be asked\t%s\n' "$missing" "$prov"; return 0
  fi
  if [ "$when" != "-" ]; then
    felix_commission_ask "$root" "$when"; rc=$?
    case "$rc" in
      0) ;;
      126) printf 'unknown\tthe checkout could not be entered\t%s\n' "$prov"; return 0 ;;
      127) printf 'unknown\ta command in the `when` test does not exist here\t%s\n' "$prov"; return 0 ;;
      *) printf 'not-applicable\tthe `when` test says this does not apply here\t%s\n' "$prov"; return 0 ;;
    esac
  fi
  case "$answer" in
    provider:*)
      # The provider library decides from the answer file alone — awaiting,
      # stale, partial or answered — and is loaded by the command and the
      # hook. Sourced alone, this file still knows the row is a provider's.
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
  felix_commission_ask "$root" "$check"; rc=$?
  case "$rc" in
    0)   printf 'done\tthe check passes\t%s\n' "$prov" ;;
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
  local need grounds instrument when answer check step st detail prov out arc line
  export FELIX_PROJECT="$proj" FELIX_PROJECT_NAME="$(basename "$proj")" \
         FELIX_ROOT_DIR="$root" FELIX_MEMORY_DIR="$(felix_mem_dir "$proj")"
  [ -n "${FELIX_HOME_DIR:-}" ] && export FELIX_HOME_DIR
  felix_commission_rows "$proj" | while IFS=$'\t' read -r need grounds instrument when answer check step; do
    [ -n "$need" ] || continue
    # The state line is captured BEFORE the tab-split read, never inside its
    # heredoc: a substitution expanded under `IFS=$'\t' read` inherits that
    # IFS, and the guard above then read four function names as one.
    line="$(felix_commission_state "$proj" "$root" "$need" "$grounds" "$instrument" "$when" "$answer" "$check")"
    IFS=$'\t' read -r st detail prov <<EOF
$line
EOF
    # A real run writes every provider row's request afresh — the topology it
    # carries is what makes an answer current — and never in --status, which
    # writes nothing. A missing template is a row nobody can answer.
    if [ "$runner" != "-" ] && [ -n "$tpl" ] && command -v felix_commission_request >/dev/null 2>&1; then
      case "$answer" in
        provider:*)
          if ! felix_commission_request "$proj" "$root" "$need" "$tpl" >/dev/null; then
            st=unknown; detail="no request template for $need under $tpl/commission, so no session can answer it"
          fi ;;
      esac
    fi
    if [ "$st" = "held" ] && [ "$runner" != "-" ]; then
      case "$answer" in
        felix:*)
          out="$( cd "$root" && "$runner" "$answer" 2>&1 )"; arc=$?
          line="$(felix_commission_state "$proj" "$root" "$need" "$grounds" "$instrument" "$when" "$answer" "$check")"
          IFS=$'\t' read -r st detail prov <<EOF
$line
EOF
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

felix_commission_actor() {
  case "${1:-}" in
    felix:*)    printf 'felix' ;;
    provider:*) printf '%s' "$1" ;;
    -)          printf 'person' ;;
    *)          printf -- '-' ;;
  esac
}

# The two hashes validity is derived from. The table set, with a header per
# file so an absent file differs from an empty one; and the detected surfaces.
felix_commission_policy_version() {
  local proj="$1" f
  for f in $FELIX_COMMISSION_TABLES; do
    printf '== %s ==\n' "$f"; cat "$proj/$f" 2>/dev/null
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

# done held unknown malformed awaiting not-applicable, space separated.
felix_commission_counts() {
  local rows="$1" malformed="$2"
  printf '%s %s %s %s %s %s' \
    "$(printf '%s\n' "$rows" | awk -F'\t' '$2 == "done"' | grep -c .)" \
    "$(printf '%s\n' "$rows" | awk -F'\t' '$2 == "held"' | grep -c .)" \
    "$(printf '%s\n' "$rows" | awk -F'\t' '$2 == "unknown"' | grep -c .)" \
    "$(printf '%s\n' "$malformed" | grep -c .)" \
    "$(printf '%s\n' "$rows" | awk -F'\t' '$2 == "awaiting" || $2 == "stale" || $2 == "partial"' | grep -c .)" \
    "$(printf '%s\n' "$rows" | awk -F'\t' '$2 == "not-applicable"' | grep -c .)"
}

# The project_commissioned receipt (§8 step 10). One line, ten fields, written
# after the last table write of a run. Its validity is never stored: it is
# derived on every read from the two hashes, so a table or a surface moving
# is seen the moment anybody looks.
felix_commission_receipt_path() { printf '%s/state/commission/%s' "$1" "$(basename "$2")"; }
felix_commission_receipt() { cat "$(felix_commission_receipt_path "$1" "$2")" 2>/dev/null; }

felix_commission_receipt_write() {
  local home="$1" proj="$2" root="$3" rows="$4" malformed="$5" path result
  local n_done n_held n_unk n_mal n_await n_na
  IFS=' ' read -r n_done n_held n_unk n_mal n_await n_na <<EOF
$(felix_commission_counts "$rows" "$malformed")
EOF
  if [ "$n_unk" -gt 0 ] || [ "$n_mal" -gt 0 ]; then result=indeterminate
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
  if [ "$tool" != "$(felix_commission_toolchain "$root")" ]; then
    printf '%s (the claude cli changed since: %s, now %s)' "$result" "$tool" "$(felix_commission_toolchain "$root")"
  else
    printf '%s' "$result"
  fi
  return 0
}

# What nothing serves, reaches, or grounds — enumerated from the checkout and
# the declaration, never from this table. cap <TAB> served <TAB> reached <TAB> grounded.
felix_commission_gaps() {
  local proj="$1" root="$2" cap served reached grounded probed
  probed="$(command -v felix_probe_rows >/dev/null 2>&1 && felix_probe_rows "$proj" | cut -f2 | LC_ALL=C sort -u)"
  { felix_detect "$root" 2>/dev/null; felix_declared "$proj" 2>/dev/null; } | LC_ALL=C sort -u \
    | while IFS= read -r cap; do
        [ -n "$cap" ] || continue
        served=no; reached=no; grounded=no
        _felix_stack_rows "$proj" 2>/dev/null | awk -F'\t' -v c="$cap" '$5 == c' | grep -q . && served=yes
        [ -n "$(felix_toolbox_route_for "$proj" "$cap" 2>/dev/null)" ] && reached=yes
        felix_has_line "$probed" "$cap" && grounded=yes
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
