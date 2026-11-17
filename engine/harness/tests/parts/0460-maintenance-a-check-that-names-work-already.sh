printf '\nmaintenance: a check that names work already in flight is not due\n'
# The upkeep row `handoff` came due for every session at once: while main held
# three pending sections, every session start printed "Maintenance due:
# handoff", and with twenty sessions running several of them folded the same
# set independently. Only one fold can land; the rest were wasted work and
# queue slots. A check can now say WHO already holds the routine: exit 0 with
# lines on stdout is `inflight`, and the routine is not due. Exit 0 and silent
# is `ok`, and any other exit is `due` whatever it printed, because a check
# that broke must stay loud — output never rescues a due row.
#
# Sections 3 and 4 of the contract are tested here with checks that are plain
# shell, so a failure names the maintenance lib or a reader and never the
# handoff git logic. Section 5, at the end, is the felix project's row run
# against a real git fixture through the real bin.
mkdir -p "$TMP/_bim"
_bim_P="$TMP/_bim/proj"; mkdir -p "$_bim_P"
_bim_R="$TMP/_bim/root"; mkdir -p "$_bim_R"
( _fx_cd "$_bim_R" && git init -q -b main ) >/dev/null 2>&1
_bim_R="$(cd "$_bim_R" && pwd -P)"
_bim_row() { printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5"; }
# Sourced from the fixture home's copy of the engine, the way the CLI and the
# hooks source it there.
_bim_st() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
              . "$FROOT/harness/lib/maintenance.sh"; felix_maint_status "$1" "${2:-}" ) 2>/dev/null; }
# And from the engine under test in place, a different directory with the same
# files, so a harness dir that is hard-coded rather than derived shows up.
_bim_st_real() { ( . "$REAL_HARNESS/lib/resolve.sh"; . "$REAL_HARNESS/lib/detect.sh"
                   . "$REAL_HARNESS/lib/maintenance.sh"; felix_maint_status "$1" "${2:-}" ) 2>/dev/null; }
_bim_line() { printf '%s\n' "$1" | awk -F'\t' -v n="$2" '$2 == n'; }
_bim_f() { printf '%s\n' "$1" | cut -f"$2"; }
# A path compared physically: macOS reaches $TMP through /var and /private/var
# both, and either is the same directory.
_bim_phys() { if [ -n "$1" ] && [ -d "$1" ]; then ( cd "$1" && pwd -P ); else printf 'not-a-directory:[%s]' "$1"; fi; }

{
  _bim_row bimone      0 always 'one holder'          "printf 'holder one\\n'"
  _bim_row bimtwo      0 always 'two holders'         "printf 'first holder\\nsecond holder\\n'"
  _bim_row bimblank    0 always 'blank lines between' "printf '\\nalpha\\n\\n\\nbeta\\n\\n'"
  _bim_row bimnonl     0 always 'no trailing newline' "printf 'gamma'"
  _bim_row bimtab      0 always 'tabs inside a line'  "printf 'x\\ty\\tz\\n'"
  _bim_row bimsplit    0 always 'stdout and stderr'   "printf 'out line\\n'; printf 'err line\\n' >&2"
  _bim_row bimsilent   0 always 'silent pass'         'true'
  _bim_row bimonlynl   0 always 'only blank lines'    "printf '\\n\\n\\n'"
  _bim_row bimstderr   0 always 'stderr only'         "printf 'only on stderr\\n' >&2"
  _bim_row bimexit1    0 always 'exit one, talking'   "printf 'looks held\\n'; exit 1"
  _bim_row bimexit2    0 always 'exit two, talking'   "printf 'looks held\\n'; exit 2"
  _bim_row bimexit127  0 always 'exit 127, talking'   "printf 'looks held\\n'; exit 127"
  _bim_row bimmissing  0 always 'a script not there'  "printf 'looks held\\n'; \"\$FELIX_HARNESS_DIR/bin/bim-no-such-script\""
  _bim_row bimenv      0 always 'harness dir'         "printf '%s\\n' \"\$FELIX_HARNESS_DIR\""
  _bim_row bimlib      0 always 'harness has a lib'   "test -f \"\$FELIX_HARNESS_DIR/lib/maintenance.sh\" && printf 'lib found\\n'"
  _bim_row bimpwd      0 always 'where it runs'       'pwd -P'
  _bim_row bimdash     0 always 'a dash for a check'  '-'
  _bim_row bimweekly   7 always 'a weekly routine'    "printf 'held\\n'"
  _bim_row bimdormant  0 billing 'waits on billing'   "printf 'held\\n'"
  printf 'bimevent\t0\talways\tno check column\n'
} > "$_bim_P/maintenance.tsv"
_bim_s="$(_bim_st "$_bim_P" "$_bim_R")"

# One line of output is one holder, in the third field, where a due row keeps
# `check` and an ok row keeps a dash. The cadence stays 0 and the description
# is the row's own, so a reader can print it without looking the row up again.
is  "a check that exits 0 naming one holder is inflight, holder in field 3" \
    "$(_bim_line "$_bim_s" bimone)" "$(printf 'inflight\tbimone\tholder one\t0\tone holder')"
# Two holders are both named, in order, joined so the line stays one line.
is  "two non-empty lines are joined by '; ', in the order printed" \
    "$(_bim_line "$_bim_s" bimtwo)" "$(printf 'inflight\tbimtwo\tfirst holder; second holder\t0\ttwo holders')"
# Blank lines are not holders. A join that kept them would read "alpha; ; beta"
# or start with "; ", and a reader would print an empty name.
is  "blank lines, leading, inner and trailing, are dropped from the holders" \
    "$(_bim_line "$_bim_s" bimblank)" "$(printf 'inflight\tbimblank\talpha; beta\t0\tblank lines between')"
# A last line with no newline is still a line. A `while read` loop drops it,
# and the row would read ok while something held it.
is  "a holder printed with no trailing newline still counts" \
    "$(_bim_line "$_bim_s" bimnonl)" "$(printf 'inflight\tbimnonl\tgamma\t0\tno trailing newline')"
# A tab in a holder would split the emitted row into more than five fields and
# shift the description of every reader that cuts on tabs. Every tab, not the
# first one only.
is  "every tab inside a holder line becomes a space" \
    "$(_bim_line "$_bim_s" bimtab)" "$(printf 'inflight\tbimtab\tx y z\t0\ttabs inside a line')"
# Field count and status together: an ok row has five fields as well, so the
# count alone could not fail for the reason it names.
is  "and the emitted inflight row keeps exactly five fields" \
    "$(_bim_line "$_bim_s" bimtab | awk -F'\t' '{ print NF ":" $1 }')" "5:inflight"
# stderr is still discarded: a check's complaint is not a holder. A capture
# that took 2>&1 would name "err line" as the session holding the routine.
is  "only stdout names holders; what the check said on stderr is not one" \
    "$(_bim_line "$_bim_s" bimsplit)" "$(printf 'inflight\tbimsplit\tout line\t0\tstdout and stderr')"

# Unchanged by contract: a silent pass is ok, and so is one that printed only
# blank lines, because there is nobody named. These pass on the old engine too.
is  "unchanged: exit 0 with no output is ok, as before" \
    "$(_bim_line "$_bim_s" bimsilent)" "$(printf 'ok\tbimsilent\t-\t0\tsilent pass')"
is  "unchanged: exit 0 with only blank lines is ok, not inflight with no holder" \
    "$(_bim_line "$_bim_s" bimonlynl)" "$(printf 'ok\tbimonlynl\t-\t0\tonly blank lines')"
is  "unchanged: exit 0 with output on stderr only is ok" \
    "$(_bim_line "$_bim_s" bimstderr)" "$(printf 'ok\tbimstderr\t-\t0\tstderr only')"
# Dueness is the exit status alone. A check that printed a name and then failed
# is due: "cannot examine" must never read as "someone has it". These pass on
# the old engine too, and must keep passing — an implementation that looked at
# the output first would turn each of them inflight.
is  "unchanged: exit 1 with output is due, the output rescues nothing" \
    "$(_bim_line "$_bim_s" bimexit1)" "$(printf 'due\tbimexit1\tcheck\t0\texit one, talking')"
is  "unchanged: exit 2 with output is due" \
    "$(_bim_line "$_bim_s" bimexit2)" "$(printf 'due\tbimexit2\tcheck\t0\texit two, talking')"
is  "unchanged: exit 127 with output is due" \
    "$(_bim_line "$_bim_s" bimexit127)" "$(printf 'due\tbimexit127\tcheck\t0\texit 127, talking')"
# The engine-without-the-script case of section 5: the row calls a bin the
# harness does not hold, the shell answers 127, and the row is due.
is  "unchanged: a check whose script is missing from the harness is due though it printed" \
    "$(_bim_line "$_bim_s" bimmissing)" "$(printf 'due\tbimmissing\tcheck\t0\ta script not there')"

# FELIX_HARNESS_DIR is what lets a project row call an engine script without
# naming a path that differs per machine. It is the harness whose lib/ held the
# maintenance.sh that ran: here the fixture home's copy.
_bim_env="$(_bim_f "$(_bim_line "$_bim_s" bimenv)" 3)"
is  "the check runs with FELIX_HARNESS_DIR set to the harness the lib was sourced from" \
    "$(_bim_phys "$_bim_env")" "$(_bim_phys "$FROOT/harness")"
is  "and that row reads inflight, since the check printed it and exited 0" \
    "$(_bim_f "$(_bim_line "$_bim_s" bimenv)" 1)" "inflight"
# A directory that merely exists is not enough: the row will call bin/ under it,
# so it has to be an engine harness.
is  "FELIX_HARNESS_DIR holds lib/maintenance.sh, so it is an engine harness" \
    "$(_bim_line "$_bim_s" bimlib)" "$(printf 'inflight\tbimlib\tlib found\t0\tharness has a lib')"
# The check still runs in the checkout root, as every checked row always has;
# the handoff row's `git ls-tree refs/remotes/origin/main` depends on it.
is  "the check runs in the checkout root it was given" \
    "$(_bim_phys "$(_bim_f "$(_bim_line "$_bim_s" bimpwd)" 3)")" "$_bim_R"

# Derived, not hard-coded: the engine under test, sourced in place, names
# itself — a different directory from the fixture home's copy.
mkdir -p "$TMP/_bim/envproj"
_bim_row bimenv 0 always 'harness dir' "printf '%s\\n' \"\$FELIX_HARNESS_DIR\"" > "$TMP/_bim/envproj/maintenance.tsv"
_bim_sr="$(_bim_st_real "$TMP/_bim/envproj" "$_bim_R")"
is  "sourced from another harness, FELIX_HARNESS_DIR names that harness instead" \
    "$(_bim_phys "$(_bim_f "$(_bim_line "$_bim_sr" bimenv)" 3)")" "$(_bim_phys "$REAL_HARNESS")"
# A value left in the caller's environment by some other engine must not reach
# the check: the row would call that engine's script, not this one's.
_bim_si="$(FELIX_HARNESS_DIR="$TMP/_bim/not-a-harness" _bim_st "$TMP/_bim/envproj" "$_bim_R")"
is  "a FELIX_HARNESS_DIR inherited from the caller is replaced by the lib's own" \
    "$(_bim_phys "$(_bim_f "$(_bim_line "$_bim_si" bimenv)" 3)")" "$(_bim_phys "$FROOT/harness")"

# Rows that are not checked rows behave exactly as before; all of these pass on
# the old engine too. A cadence row ignores a fifth column — it is on a clock —
# and a dormant row is dormant before any check is asked.
is  "unchanged: a row with a dash for its check is event" \
    "$(_bim_line "$_bim_s" bimdash)" "$(printf 'event\tbimdash\t-\t0\ta dash for a check')"
is  "unchanged: a four-column row is event" \
    "$(_bim_line "$_bim_s" bimevent)" "$(printf 'event\tbimevent\t-\t0\tno check column')"
is  "unchanged: a cadence row is due on its clock, never inflight from a fifth column" \
    "$(_bim_line "$_bim_s" bimweekly)" "$(printf 'due\tbimweekly\tnever\t7\ta weekly routine')"
is  "unchanged: a dormant row is dormant, never inflight" \
    "$(_bim_line "$_bim_s" bimdormant)" "$(printf 'dormant\tbimdormant\t-\t0\twaits on billing')"
# With no checkout given the check is not asked at all, so it cannot name
# anybody: unchecked, as before, and the command never ran.
_bim_row bimsentinel 0 always 'writes when run' "printf x > '$TMP/_bim/sentinel'; printf 'held\\n'" >> "$_bim_P/maintenance.tsv"
rm -f "$TMP/_bim/sentinel"
_bim_su="$(_bim_st "$_bim_P" "")"
is  "unchanged: with no root an inflight-shaped row is unchecked" \
    "$(_bim_line "$_bim_su" bimone)" "$(printf 'unchecked\tbimone\t-\t0\tone holder')"
[ -e "$TMP/_bim/sentinel" ] \
  && bad "unchanged: with no root the check is never run" "the sentinel was written" \
  || ok  "unchanged: with no root the check is never run"
case "$_bim_su" in
  *inflight*) bad "unchanged: and nothing reads inflight when nothing was asked" "$_bim_su" ;;
  *)          ok  "unchanged: and nothing reads inflight when nothing was asked" ;;
esac

printf '\nmaintenance in flight: what each reader shows\n'
# Every reader that keeps `due` must keep only due, so a row somebody already
# holds is absent from the due list, the badge, the overnight list, the pulse
# and felix next; and the session start says who holds it, on a line of its
# own, so a session reading it does not start a second fold.
_bim_wt="$FROOT/projects/widget/maintenance.tsv"
if [ -f "$_bim_wt" ]; then cp "$_bim_wt" "$TMP/_bim/widget-maint.keep"; _bim_wt_had=1; else _bim_wt_had=0; fi
_bim_held='claude/handoff-fold-bim (folded to 0cn; tip 2h old)'
_bim_held2='claude/other-fold-bim (folded to 0co; tip 5m old)'
_bim_tableA() {
  _bim_row bimdue  0 always 'the due one'  "printf 'not a holder\\n'; exit 1"
  _bim_row bimheld 0 always 'the held one' "printf '%s\\n' '$_bim_held'"
  _bim_row bimok   0 always 'the ok one'   'true'
}
_bim_tableA > "$_bim_wt"
_bim_ctx() { printf '%s' "$1" | python3 -c 'import json,sys
d = json.load(sys.stdin)
print(d["hookSpecificOutput"]["additionalContext"] if sys.argv[1] == "ctx" else d.get("systemMessage", ""))' "$2" 2>/dev/null; }

_bim_out="$(cd "$REPO" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
_bim_c="$(_bim_ctx "$_bim_out" ctx)"; _bim_m="$(_bim_ctx "$_bim_out" sys)"
has "session start names the holder: 'Already in flight, so not due: <name> on <holders>'" \
    "$_bim_c" "Already in flight, so not due: bimheld on $_bim_held"
# Leading whitespace is stripped: the contract fixes the words, not an indent.
is  "and says it once, on a line of its own" \
    "$(printf '%s\n' "$_bim_c" | grep 'Already in flight, so not due: ' | sed 's/^[[:space:]]*//')" \
    "Already in flight, so not due: bimheld on $_bim_held"
# Unchanged: the due line lists due rows only. The old engine passes this too,
# reading the held row as ok; the new one must not add it back.
is  "unchanged: the 'Maintenance due:' line lists only the due row" \
    "$(printf '%s\n' "$_bim_c" | grep '^Maintenance due:')" "Maintenance due: bimdue"
is  "unchanged: the badge counts only due rows, so an inflight row adds nothing" \
    "$(printf '%s' "$_bim_m" | sed -n 's/.*· \([0-9][0-9]*\) due.*/\1/p')" "1"

# Shown whether or not anything is due: the session that most needs to hear a
# fold is in flight is the one with nothing else on its plate.
{ _bim_row bimheld  0 always 'the held one'  "printf '%s\\n' '$_bim_held'"
  _bim_row bimheld2 0 always 'the other one' "printf '%s\\n' '$_bim_held2'"
  _bim_row bimok    0 always 'the ok one'    'true'; } > "$_bim_wt"
_bim_out="$(cd "$REPO" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
_bim_c="$(_bim_ctx "$_bim_out" ctx)"; _bim_m="$(_bim_ctx "$_bim_out" sys)"
has "the in-flight line appears when nothing is due" \
    "$_bim_c" "Already in flight, so not due: bimheld on $_bim_held"
# One line per row, not one line for the first row found.
is  "each inflight row adds a line of its own" \
    "$(printf '%s\n' "$_bim_c" | grep -c 'Already in flight, so not due: ')" "2"
has "naming the second row with its own holder" \
    "$_bim_c" "Already in flight, so not due: bimheld2 on $_bim_held2"
case "$_bim_c" in
  *"Maintenance due"*) bad "unchanged: with only inflight and ok rows there is no due line" "$_bim_c" ;;
  *)                   ok  "unchanged: with only inflight and ok rows there is no due line" ;;
esac
case "$_bim_m" in
  *" due"*) bad "unchanged: and no due badge" "$_bim_m" ;;
  *)        ok  "unchanged: and no due badge" ;;
esac

# felix maintenance: the held row is shown as held, with who holds it on the
# line under it, and is not counted. Rendered as `ok  check passed` it would
# say the routine is done when it is only claimed.
_bim_tableA > "$_bim_wt"
_bim_mo="$(cd "$REPO" && "$FELIX" maintenance 2>&1)"
has "felix maintenance marks the row in-flt" "$_bim_mo" "in-flt  bimheld"
# Read off the in-flt line itself, so "in flight" printed anywhere else (a
# holder, a footer) cannot satisfy it; the description stays on that line.
has "and says in flight on that row"         "$(printf '%s\n' "$_bim_mo" | grep 'in-flt  bimheld')" "in flight"
has "and keeps the row's description there" "$(printf '%s\n' "$_bim_mo" | grep 'in-flt  bimheld')" "the held one"
# One held row, one in-flt line: the silent ok row is not marked held.
is  "only the inflight row is marked in-flt, not the silent ok row" \
    "$(printf '%s\n' "$_bim_mo" | grep -c 'in-flt')" "1"
has "and names the holders: on <holders>"    "$_bim_mo" "on $_bim_held"
has "on the line directly under the in-flt row" \
    "$(printf '%s\n' "$_bim_mo" | grep -A1 'in-flt  bimheld' | tail -1)" "on $_bim_held"
case "$_bim_mo" in
  *"ok      bimheld"*) bad "an inflight row is not rendered as a passed check" "$_bim_mo" ;;
  *)                   ok  "an inflight row is not rendered as a passed check" ;;
esac
is  "unchanged: only the due row is DUE" \
    "$(printf '%s\n' "$_bim_mo" | grep -c '^  DUE ')" "1"
has "unchanged: and the count says one" "$_bim_mo" "1 routine(s) due."
# With nothing due but rows held, ok, event-driven and dormant, the answer is
# still "Nothing due." — a held routine is not outstanding work for this
# session. The old engine prints it too, reading the held rows as ok.
{ _bim_row bimheld  0 always 'the held one'  "printf '%s\\n' '$_bim_held'"
  _bim_row bimheld2 0 always 'the other one' "printf '%s\\n' '$_bim_held2'"
  _bim_row bimok    0 always 'the ok one'    'true'
  printf 'bimevent\t0\talways\ton a trigger\n'
  printf 'bimlater\t7\tbilling\tonly once payments exist\n'; } > "$_bim_wt"
_bim_mo="$(cd "$REPO" && "$FELIX" maintenance 2>&1)"
has "with only inflight, ok, event and dormant rows, felix maintenance shows the inflight row" \
    "$_bim_mo" "in-flt  bimheld2"
has "unchanged: and still ends Nothing due." "$_bim_mo" "Nothing due."
case "$_bim_mo" in
  *"routine(s) due"*) bad "unchanged: and counts no routine as due" "$_bim_mo" ;;
  *)                  ok  "unchanged: and counts no routine as due" ;;
esac

if [ "$_bim_wt_had" = 1 ]; then cp "$TMP/_bim/widget-maint.keep" "$_bim_wt"; else rm -f "$_bim_wt"; fi

# The stop hook feeds the overnight continuation only the due rows, with
# `awk -F'\t' '$1 == "due"'` over felix_maint_status — a session doing upkeep
# overnight must not start a fold that is already in flight. Driving the real
# stop hook needs a live night; this applies that filter, verbatim, to the
# status the hook reads. It passes on the old engine as well (the held row
# read ok there) and fails on any status that leaves the row due.
_bim_SP="$TMP/_bim/stopproj"; mkdir -p "$_bim_SP"
_bim_tableA > "$_bim_SP/maintenance.tsv"
is  "unchanged: the stop hook's due filter yields the due row and not the inflight one" \
    "$(_bim_st "$_bim_SP" "$_bim_R" | awk -F'\t' '$1 == "due" { printf "%s%s", sep, $2; sep = ", " }')" "bimdue"

# felix pulse keeps only due (and unchecked). The home is a checkout bound to
# its one project, so the pulse offers that project its root and the checks
# are really asked: the due row reading due is the proof the held row was
# asked too, and not merely left unchecked.
_bim_PH="$TMP/_bim/pulsehome"; mkdir -p "$_bim_PH/projects/bimpulse"
( _fx_cd "$_bim_PH" && git init -q -b main ) >/dev/null 2>&1
_bim_PH="$(cd "$_bim_PH" && pwd -P)"
printf 'bimpulse\n' > "$_bim_PH/.felix"
printf '{"name": "bimpulse", "remote_match": "example.com/bimpulse", "gate": "true"}\n' \
  > "$_bim_PH/projects/bimpulse/project.json"
_bim_tableA > "$_bim_PH/projects/bimpulse/maintenance.tsv"
_bim_po="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
            . "$FROOT/harness/lib/stack.sh"; . "$FROOT/harness/lib/maintenance.sh"
            . "$FROOT/harness/lib/discover.sh"; . "$FROOT/harness/lib/pulse.sh"
            felix_pulse_report "$_bim_PH" 2>/dev/null )"
is  "unchanged: the pulse names the due row, asked in its own checkout" \
    "$(printf '%s\n' "$_bim_po" | grep '^due	')" "$(printf 'due\tbimpulse\tbimdue')"
is  "unchanged: and does not name the inflight row anywhere" \
    "$(printf '%s\n' "$_bim_po" | grep -c 'bimheld')" "0"

# felix next ranks upkeep at 4 from due rows only.
_bim_NP="$TMP/_bim/bimnext"; mkdir -p "$_bim_NP" "$MEM/bimnext"
printf '{"name":"bimnext","gate":"true"}\n' > "$_bim_NP/project.json"
: > "$_bim_NP/routes.tsv"; : > "$_bim_NP/stack.tsv"
_bim_tableA > "$_bim_NP/maintenance.tsv"
_bim_n="$( cd "$REPO" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
           . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
           . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/evidence.sh"
           . "$FROOT/harness/lib/maintenance.sh"; . "$FROOT/harness/lib/stack.sh"
           . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/ledger.sh"
           . "$FROOT/harness/lib/coverage.sh"; . "$FROOT/harness/lib/deny.sh"
           . "$FROOT/harness/lib/route.sh"; . "$FROOT/harness/lib/next.sh"
           felix_next "$_bim_NP" "$FROOT" "$REPO" HEAD~1 2>/dev/null )"
is  "unchanged: felix next ranks the due row as upkeep" \
    "$(printf '%s\n' "$_bim_n" | awk -F'\t' '$1 == 4 { print $3 }')" "upkeep due: bimdue — the due one"
is  "unchanged: and never names the inflight row" \
    "$(printf '%s\n' "$_bim_n" | grep -c 'bimheld')" "0"

printf '\nmaintenance in flight: the handoff row, end to end\n'
# The felix project's own row, verbatim, against a checkout whose remote-
# tracking main holds three pending sections: due with no fold anywhere; held,
# naming the branch, once a fold cut from main's tip is on the remote; ok once
# main holds fewer than three. The row reaches the engine's script through
# FELIX_HARNESS_DIR, which the lib sets — nothing here sets it.
_bim_E="$TMP/_bim/e2e"; mkdir -p "$_bim_E/docs/handoff/pending"
_bim_git() { _fx_git "$_bim_E" -c core.hooksPath=/dev/null -c commit.gpgsign=false "$@"; }
( _fx_cd "$_bim_E" && git init -q -b main && git config user.name t && git config user.email t@example.invalid ) >/dev/null 2>&1
_bim_E="$(cd "$_bim_E" && pwd -P)"
_bim_handoff() {
  printf '# Handoff\n\nWrite your section with felix handoff --section; the fold gives it the next id\n'
  printf '(after %s comes %s).\n\n---\n\n## Current state\n\n### %s. the session before\n\nWhat it did.\n' "$1" "$2" "$1"
}
_bim_now="$(date +%s)"
_bim_handoff 0cg 0ch > "$_bim_E/HANDOFF.md"
for _bim_p in a b c; do printf '## %s\n\nA pending section.\n' "$_bim_p" > "$_bim_E/docs/handoff/pending/$_bim_p.md"; done
_bim_git add -A >/dev/null 2>&1
GIT_COMMITTER_DATE="@$((_bim_now - 86400)) +0000" GIT_AUTHOR_DATE="@$((_bim_now - 86400)) +0000" \
  _bim_git commit -qm "main with three pending" >/dev/null 2>&1
_bim_main="$(_bim_git rev-parse HEAD)"
_bim_git update-ref refs/remotes/origin/main "$_bim_main"
_bim_git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
_bim_EP="$TMP/_bim/e2eproj"; mkdir -p "$_bim_EP"
_bim_check='test "$(git ls-tree --name-only refs/remotes/origin/main docs/handoff/pending/ 2>/dev/null | grep -c '"'"'\.md$'"'"')" -lt 3 || "$FELIX_HARNESS_DIR/bin/handoff-in-flight" --within 48'
# A second row runs the same check and reports its exit status as a holder,
# because `due` alone cannot say WHY: an engine without the script is due too
# (127), and so is one that cannot examine (2). The contract's due here is the
# script answering "none in flight", exit 1. Asked through the lib like the
# real row, so FELIX_HARNESS_DIR is still the lib's to set.
{ _bim_row handoff   0 always 'fold the pending handoff sections' "$_bim_check"
  _bim_row handoffrc 0 always 'the same check, its exit status'   "( $_bim_check ) >/dev/null 2>&1; printf 'rc=%s\\n' \"\$?\""
} > "$_bim_EP/maintenance.tsv"
_bim_rc() { _bim_f "$(_bim_line "$1" handoffrc)" 3; }
# The row as written, so a fixture that mangled it is not what is being tested.
# A fixture self-check: it passes on any engine.
is  "fixture: the row carries the section-5 check verbatim" \
    "$(awk -F'\t' '$1 == "handoff" { print $5 }' "$_bim_EP/maintenance.tsv")" "$_bim_check"
_bim_es="$(_bim_st "$_bim_EP" "$_bim_E")"
is  "with three pending and no fold branch the handoff row is due" \
    "$(_bim_line "$_bim_es" handoff)" \
    "$(printf 'due\thandoff\tcheck\t0\tfold the pending handoff sections')"
is  "and due because the script answered none in flight (exit 1), not because it could not run" \
    "$(_bim_rc "$_bim_es")" "rc=1"
# A session's ordinary branch adds a pending file and leaves the marker alone;
# twenty of those must not read as a fold.
_bim_git checkout -q -b claude/pending-only-bim >/dev/null 2>&1
printf '## d\n\nAnother.\n' > "$_bim_E/docs/handoff/pending/d.md"
_bim_git add -A >/dev/null 2>&1; _bim_git commit -qm "a pending section" >/dev/null 2>&1
_bim_git update-ref refs/remotes/origin/claude/pending-only-bim "$(_bim_git rev-parse HEAD)"
# The fold itself, cut from main's tip, two hours old: it moves the marker on
# and removes the files it folded. Local only, first.
_bim_git checkout -q main >/dev/null 2>&1
_bim_git checkout -q -b claude/handoff-fold-bim >/dev/null 2>&1
_bim_handoff 0ci 0cj > "$_bim_E/HANDOFF.md"
_bim_git rm -q docs/handoff/pending/a.md docs/handoff/pending/b.md docs/handoff/pending/c.md >/dev/null 2>&1
_bim_git add -A >/dev/null 2>&1
GIT_COMMITTER_DATE="@$((_bim_now - 7300)) +0000" GIT_AUTHOR_DATE="@$((_bim_now - 7300)) +0000" \
  _bim_git commit -qm "fold" >/dev/null 2>&1
_bim_fold="$(_bim_git rev-parse HEAD)"
_bim_git checkout -q main >/dev/null 2>&1
_bim_es="$(_bim_st "$_bim_EP" "$_bim_E")"
is  "a branch that only adds a pending file, and a fold not yet pushed, leave the row due" \
    "$(_bim_f "$(_bim_line "$_bim_es" handoff)" 1)" "due"
is  "and the script says none in flight for them (exit 1)" "$(_bim_rc "$_bim_es")" "rc=1"
_bim_git update-ref refs/remotes/origin/claude/handoff-fold-bim "$_bim_fold"
is  "once the fold is on the remote the row is inflight, naming the branch, its id and its age" \
    "$(_bim_line "$(_bim_st "$_bim_EP" "$_bim_E")" handoff)" \
    "$(printf 'inflight\thandoff\tclaude/handoff-fold-bim (folded to 0ci; tip 2h old)\t0\tfold the pending handoff sections')"
# The row's bound is 48 hours: a fold nobody has touched for longer is
# abandoned, and the routine falls due again rather than staying silenced.
_bim_old="$(GIT_COMMITTER_DATE="@$((_bim_now - 50 * 3600)) +0000" GIT_AUTHOR_DATE="@$((_bim_now - 50 * 3600)) +0000" \
            _bim_git commit-tree "$(_bim_git rev-parse "$_bim_fold^{tree}")" -p "$_bim_main" -m "old fold")"
_bim_git update-ref refs/remotes/origin/claude/handoff-fold-bim "$_bim_old"
_bim_es="$(_bim_st "$_bim_EP" "$_bim_E")"
is  "a fold whose tip is older than the row's 48 hours leaves the row due" \
    "$(_bim_f "$(_bim_line "$_bim_es" handoff)" 1)" "due"
is  "and the script says none in flight for it (exit 1)" "$(_bim_rc "$_bim_es")" "rc=1"
_bim_git update-ref refs/remotes/origin/claude/handoff-fold-bim "$_bim_fold"
# Fewer than three pending on main: the check's first half answers, silently.
_bim_git rm -q docs/handoff/pending/c.md >/dev/null 2>&1
_bim_git commit -qm "two pending" >/dev/null 2>&1
_bim_git update-ref refs/remotes/origin/main "$(_bim_git rev-parse HEAD)"
is  "unchanged: with fewer than three pending on main the row is ok" \
    "$(_bim_line "$(_bim_st "$_bim_EP" "$_bim_E")" handoff)" \
    "$(printf 'ok\thandoff\t-\t0\tfold the pending handoff sections')"

