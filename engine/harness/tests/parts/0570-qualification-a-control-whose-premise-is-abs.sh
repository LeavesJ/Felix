printf '\nqualification: a control whose premise is absent\n'
# A control that plants a governed project's name cannot be met in a checkout
# that governs only itself: there is nothing there for the mutation to break.
# Counting it held turns a correct engine red, and counting it met would be a
# lie about a check that never ran. So a row may carry a premise, evaluated in
# the worktree of HEAD before the mutation, and a premise that does not hold
# makes the control inapplicable.
#
# The trap in a third verdict is that it stops a control failing without fixing
# anything: a premise that always fails silences its control forever. That is
# why a premise that errors is unrunnable rather than inapplicable, and why a
# checker whose every fail control was inapplicable is named as never shown
# failing and refuses the gate. Writing a fail control is the claim that the
# checker catches something, and anything that claims to verify is shown
# failing before it is believed; a gate reading ok over a checker nobody has
# seen fail breaks that. The remedy is a control that stages its own premise.
#
# Authored by a subagent given this behaviour in prose and forbidden the
# runner's source. That records the method; it is not a property anyone can
# check from here.
_widget_repo_build
_qualify_unreadable_probe
_qualify_shim_build
_qualify_gshim_build
QPP="$TMP/premproj"; QPR="$TMP/premrepo"; mkdir -p "$QPP" "$QPR" "$MEM/premproj"
( _fx_cd "$QPR" && git init -q -b main && printf 'clean\n' > a.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
QPR="$(cd "$QPR" && pwd -P)"
# Present in the checkout and absent from HEAD, so a premise that finds it was
# not evaluated where the spec says.
printf 'loose\n' > "$QPR/loose.txt"
# Marks a skipped step must not leave, written outside every worktree. The path
# goes into the table already expanded, so it does not matter how the runner
# evaluates a row.
QPS="$TMP/premside"; mkdir -p "$QPS"
_qpc='! grep -rqI FORBIDDEN . 2>/dev/null'
_qp5() { printf '%s\t%s\t%s\t%s\t%s\n' "$@"; }
_qp6() { printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$@"; }
{ _qp5 five      "$_qpc" violation fail 'printf FORBIDDEN > bad.txt'
  _qp6 dashed    "$_qpc" violation fail 'printf FORBIDDEN > bad.txt' '-'
  _qp6 blanked   "$_qpc" violation fail 'printf FORBIDDEN > bad.txt' ''
  _qp6 affirmed  "printf x >> '$QPS/checker-applied'; $_qpc" violation fail \
                 "printf x >> '$QPS/mutation-applied'; printf FORBIDDEN > bad.txt" true
  _qp6 affirmed  "$_qpc" alternate fail 'printf harmless > other.txt' true
  _qp6 denied    "printf x >> '$QPS/checker-inapplicable'; $_qpc" violation fail \
                 "printf x >> '$QPS/mutation-inapplicable'; printf FORBIDDEN > bad.txt" false
  _qp6 headtree  "$_qpc" violation fail 'printf FORBIDDEN > bad.txt' 'test -f a.txt'
  _qp6 mutated   "$_qpc" violation fail 'printf FORBIDDEN > made.txt' 'test -f made.txt'
  _qp6 loosefile "$_qpc" violation fail 'printf FORBIDDEN > bad.txt' 'test -f loose.txt'
  _qp6 errtwo    "$_qpc" violation fail 'printf FORBIDDEN > bad.txt' "sh -c 'exit 2'"
  _qp6 nocommand "$_qpc" violation fail 'printf FORBIDDEN > bad.txt' 'felix-no-such-premise-command'
  # For the never-shown-failing report. lonely has a pass control that applied,
  # so "every control inapplicable" and "every fail control inapplicable" give
  # different answers; mixed puts its inapplicable row last, so a last-row-wins
  # reading names it.
  _qp5 lonely    "$_qpc" restoration pass true
  _qp6 lonely    "$_qpc" violation fail 'printf FORBIDDEN > bad.txt' false
  _qp6 passonly  "$_qpc" restoration pass true false
  _qp5 mixed     "$_qpc" violation fail 'printf FORBIDDEN > bad.txt'
  _qp6 mixed     "$_qpc" decoupled_violation fail 'printf FORBIDDEN > deep.txt' false
  _qp5 heldfail  "$_qpc" alternate fail 'printf harmless > other.txt'
  _qp6 heldfail  "$_qpc" violation fail 'printf FORBIDDEN > bad.txt' false
} > "$QPP/qualification.tsv"
_qpo="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
         felix_qualify_run "$QPP" "$QPR" 2>/dev/null )"
# Column $3 of the row for checker $1, control $2. awk, because read collapses
# empty fields.
_qpv() { printf '%s\n' "$_qpo" | awk -F'\t' -v c="$1" -v k="$2" -v f="$3" '$1 == c && $2 == k { print $f }'; }
_qpe() { [ -e "$1" ] && echo ran || echo absent; }

is  "a qualification row of five columns has no premise and is met as before" \
    "$(_qpv five violation 5)" "met"
is  "a premise of a single dash is no premise"            "$(_qpv dashed violation 5)"   "met"
is  "and neither is an empty premise column"              "$(_qpv blanked violation 5)"  "met"
is  "a premise that holds lets its control run and be met" "$(_qpv affirmed violation 5)" "met"
is  "and leaves a control its checker passes over held"   "$(_qpv affirmed alternate 5)" "held"
is  "a premise that exits 1 makes its control inapplicable" "$(_qpv denied violation 5)" "inapplicable"
is  "and an inapplicable control reports no result, not a pass or a fail" \
    "$(_qpv denied violation 4)" "-"
is  "an inapplicable control never applies its mutation" \
    "$(_qpe "$QPS/mutation-inapplicable")" "absent"
is  "nor runs the checker the control was written against" \
    "$(_qpe "$QPS/checker-inapplicable")" "absent"
# Absence is evidence only if the same technique shows presence.
is  "while an applicable control runs both, so that absence is measured" \
    "$(_qpe "$QPS/mutation-applied") $(_qpe "$QPS/checker-applied")" "ran ran"
is  "a premise can see the files HEAD has"                "$(_qpv headtree violation 5)" "met"
is  "and is evaluated before the mutation, so a file only the mutation makes is not there" \
    "$(_qpv mutated violation 5)" "inapplicable"
is  "and reads HEAD, not the checkout's uncommitted files" \
    "$(_qpv loosefile violation 5)" "inapplicable"
# A premise that errors is not a premise that is false. Read as inapplicable, a
# typo in a premise would retire its control without anyone deciding to.
is  "a premise that exits 2 is unrunnable, not inapplicable" \
    "$(_qpv errtwo violation 4) $(_qpv errtwo violation 5)" "unrunnable unrunnable"
is  "and so is a premise whose command does not exist" \
    "$(_qpv nocommand violation 4) $(_qpv nocommand violation 5)" "unrunnable unrunnable"

_qpu="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
         felix_qualify_unshown "$QPP" "$_qpo" )"
_qpn() { printf '%s\n' "$_qpu" | awk -v n="$1" '$0 == n { f = 1 } END { print (f ? "named" : "not named") }'; }
# The positive case comes first and shares the output with every negative
# below, so an empty report cannot pass them.
is  "a checker whose every fail control did not apply is named as never shown failing" \
    "$(_qpn lonely)" "named"
is  "a checker whose fail control was met is not named"    "$(_qpn five)"     "not named"
is  "nor one whose fail control applied and was held"      "$(_qpn heldfail)" "not named"
# A checker with no fail control at all is a missing control, which another
# report names. "Every fail control inapplicable" is vacuously true of it.
is  "nor one that declares no fail control at all"         "$(_qpn passonly)" "not named"
is  "nor one with two fail controls of which one applied"  "$(_qpn mixed)"    "not named"
is  "nor one whose fail control could not run"             "$(_qpn errtwo)"   "not named"

# A sixth column is allowed, so a row carrying one is not short or long. The
# short row is there so that silence from the malformed report is measured.
printf 'short\tonly-two\n' >> "$QPP/qualification.tsv"
_qpm="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
         felix_qualify_malformed "$QPP" )"
case "$_qpm" in
  *short*)
    case "$_qpm" in
      *dashed*|*blanked*|*affirmed*|*denied*) bad "a row carrying a premise is not reported malformed" "$_qpm" ;;
      *) ok "a row carrying a premise is not reported malformed" ;;
    esac ;;
  *) bad "a row carrying a premise is not reported malformed" "the short row was not reported either, so nothing was measured: [$_qpm]" ;;
esac

# The CLI, against the fixture project. What the table was is recorded before
# anything touches it, and compared at the end.
_qpw="$FROOT/projects/widget/qualification.tsv"
_qpwas="$(cat "$_qpw" 2>/dev/null || printf '<absent>')"
cp "$_qpw" "$TMP/qualprem.keep" 2>/dev/null || true
# The part of any line from the phrase on, so a name is only counted when it
# follows the phrase.
_qpshown() { printf '%s\n' "$1" | awk '{ i = index($0, "never shown failing in this checkout"); if (i) print substr($0, i) }'; }
# The number nearest phrase $2 in $1: the last one in the clause before it, or
# else the first one after it. Not merely the right digit somewhere on the line,
# which a report folding the count into another would also print.
_qpnear() { printf '%s\n' "$1" | awk -v p="$2" '{
  i = index($0, p); if (!i) next
  n = split(substr($0, 1, i - 1), part, /[;,.]/); s = (n ? part[n] : "")
  if (match(s, /[0-9]+[^0-9]*$/)) { s = substr(s, RSTART); sub(/[^0-9].*$/, "", s); print s; exit }
  t = substr($0, i); if (match(t, /[0-9]+/)) { print substr(t, RSTART, RLENGTH); exit }
}'; }
# Controls did not apply, and every checker that declares a fail control has
# one that applied and was met. passer declares only a pass control, and it did
# not apply: a checker with no fail control is a missing control, which another
# report names, not one never shown failing. Three inapplicable, a number no
# other count can take (two met, two checkers, none held, none unrunnable).
_qptab_shown() {
  _qp5 demo   "$_qpc" violation           fail 'printf FORBIDDEN > bad.txt'
  _qp6 demo   "$_qpc" restoration         pass true '-'
  _qp6 demo   "$_qpc" decoupled_violation fail 'printf FORBIDDEN > deep.txt' false
  _qp6 demo   "$_qpc" alternate           fail 'printf FORBIDDEN > alt.txt' false
  _qp6 passer "$_qpc" restoration         pass true false
}
# Nothing held and nothing unrunnable; the one thing wrong is ghost, whose every
# control did not apply, two fail and one pass. demo shows failing once and has
# a fail control that did not apply. Four inapplicable in all (two met, two
# checkers).
_qptab_ghost() {
  _qp5 demo  "$_qpc" violation           fail 'printf FORBIDDEN > bad.txt'
  _qp6 demo  "$_qpc" restoration         pass true '-'
  _qp6 demo  "$_qpc" decoupled_violation fail 'printf FORBIDDEN > deep.txt' false
  _qp6 ghost "$_qpc" alternate           fail 'printf FORBIDDEN > alt.txt' false
  _qp6 ghost "$_qpc" decoupled_violation fail 'printf FORBIDDEN > deep.txt' false
  _qp6 ghost "$_qpc" irrelevant          pass true false
}
_qptab_shown > "$_qpw"
( cd "$REPO" && "$FELIX" qualify --gate >/dev/null 2>&1 ); _qprc=$?
is  "inapplicable controls do not refuse the gate while every checker is shown failing" "$_qprc" "0"
_qptab_ghost > "$_qpw"
_qpg="$(cd "$REPO" && "$FELIX" qualify --gate 2>&1)"; _qprc=$?
is  "a checker never shown failing refuses the gate with nothing held or unrunnable" "$_qprc" "1"
has "--gate names the checker never shown failing in this checkout" "$(_qpshown "$_qpg")" "ghost"
_qpr="$(cd "$REPO" && "$FELIX" qualify 2>&1)"
has "and felix qualify names it as well" "$(_qpshown "$_qpr")" "ghost"
case "$(_qpshown "$_qpg") $(_qpshown "$_qpr")" in
  *demo*) bad "but neither names a checker shown failing beside a control that did not apply" \
              "$(_qpshown "$_qpg") $(_qpshown "$_qpr")" ;;
  *)      ok  "but neither names a checker shown failing beside a control that did not apply" ;;
esac
has "the qualify report says a control did not apply in this checkout" "$_qpr" "did not apply in this checkout"
is  "and counts every control that did not apply, pass or fail" \
    "$(_qpnear "$_qpr" "did not apply in this checkout")" "4"
is  "an inapplicable row is rendered n/a, never ok, HELD or UNRUNNABLE" \
    "$(printf '%s\n' "$_qpr" | awk '$NF == "n/a"' | wc -l | tr -d ' ')" "4"
# The remedy the refusal points to: a fail control for ghost with no premise,
# whose mutation stages the violation itself.
_qp5 ghost "$_qpc" violation fail 'printf FORBIDDEN > bad.txt' >> "$_qpw"
_qpg="$(cd "$REPO" && "$FELIX" qualify --gate 2>&1)"; _qprc=$?
is  "a control that stages its own violation lifts the refusal" "$_qprc" "0"
# The line was printed for this table one row ago, so its absence is measured.
case "$(_qpshown "$_qpg")" in
  *ghost*) bad "and the checker it shows failing is no longer named" "$(_qpshown "$_qpg")" ;;
  *)       ok  "and the checker it shows failing is no longer named" ;;
esac
# The held row comes before the inapplicable ones, so a runner that lets a later
# inapplicable verdict reset the refusal is caught. Every checker here is shown
# failing, so the refusal can only be the held row's.
{ _qp5 demo  "$_qpc" violation           fail 'printf FORBIDDEN > bad.txt'
  _qp5 demo  "$_qpc" alternate           fail 'printf harmless > other.txt'
  _qp6 demo  "$_qpc" decoupled_violation fail 'printf FORBIDDEN > deep.txt' false
  _qp6 demo  "$_qpc" irrelevant          pass true false
} > "$_qpw"
( cd "$REPO" && "$FELIX" qualify --gate >/dev/null 2>&1 ); _qprc=$?
is  "a held control still refuses the gate when inapplicable rows follow it" "$_qprc" "1"
# broken also has a fail control that was met. Read as inapplicable, its
# erroring premise would leave it shown failing and the gate would pass; so only
# an unrunnable verdict refuses here.
{ _qp6 broken "$_qpc" decoupled_violation fail 'printf FORBIDDEN > deep.txt' "sh -c 'exit 2'"
  _qp5 broken "$_qpc" violation           fail 'printf FORBIDDEN > bad.txt'
  _qp6 broken "$_qpc" irrelevant          pass true false
} > "$_qpw"
( cd "$REPO" && "$FELIX" qualify --gate >/dev/null 2>&1 ); _qprc=$?
is  "a premise that errors refuses the gate rather than reading as absent" "$_qprc" "1"
rm -f "$_qpw"
[ -f "$TMP/qualprem.keep" ] && mv "$TMP/qualprem.keep" "$_qpw"
is  "and the widget table is as the premise block found it" \
    "$(cat "$_qpw" 2>/dev/null || printf '<absent>')" "$_qpwas"

# felix gate carries the same verdict. It runs in a home of its own, built the
# way the self-governed fixture is, because a gate run writes a receipt and a
# red one writes mistakes.log, and the widget checkout is read by everything
# after this block.
QGH="$TMP/premgatehome"; QGR="$TMP/premgaterepo"
mkdir -p "$QGH/projects/premgate" "$QGH/harness" "$MEM/premgate" "$QGR"
cp -R "$FROOT/harness/." "$QGH/harness/"
printf '{ "name": "premgate", "gate": "true" }\n' > "$QGH/projects/premgate/project.json"
printf '# premgate\n' > "$QGH/projects/premgate/CLAUDE.md"
( _fx_cd "$QGR" && git init -q -b main && printf 'clean\n' > a.txt && printf 'premgate\n' > .felix \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
QGR="$(cd "$QGR" && pwd -P)"
_qpgate() { ( cd "$QGR" && FELIX_HOME="$QGH" "$QGH/harness/felix" gate 2>&1 ); }
# The qualified check's own line with status $2, and the lines under it up to
# the next check's line (two spaces, a name, a status).
_qpunder() { printf '%s\n' "$1" | awk -v s="$2" '
  on && /^  [a-z][a-z_-]* +(ok|FAIL|skipped|stale)/ { on = 0 }
  $0 ~ ("^ *qualified +" s) { on = 1 }
  on { print }'; }
_qptab_ghost > "$QGH/projects/premgate/qualification.tsv"
_qpgo="$(_qpgate)"
has "felix gate fails qualification over a checker never shown failing" "$(_qpunder "$_qpgo" FAIL)" "qualified"
has "and prints the line naming it under qualified FAIL" "$(_qpshown "$(_qpunder "$_qpgo" FAIL)")" "ghost"
_qptab_shown > "$QGH/projects/premgate/qualification.tsv"
_qpgo="$(_qpgate)"
has "felix gate reads qualified ok over controls that did not apply" "$(_qpunder "$_qpgo" ok)" "qualified"
is  "and says under it how many did not apply here" \
    "$(_qpnear "$(_qpunder "$_qpgo" ok)" "did not apply here")" "3"
# A checker short of the six is reported and not refused; lib/qualify.sh says
# why. demo declares four, so the ok line must not read as six of six.
has "and names under it a checker short of the six controls, without refusing" \
    "$(_qpunder "$_qpgo" ok)" "demo declares no control for: irrelevant decoupled_satisfaction"
# A checker whose declared controls could not be read was named here, under
# qualified ok, and ok with that under it is still ok: the gate passed over a
# checker nobody knew the controls of. That assertion is rewritten, not
# dropped: a failed read, of the table or of what a checker declares, is a
# refusal now, under qualified FAIL. And the gate read the table again for its
# checker count, and when that read failed it said across 0 checker(s) and
# showed awk's own error. Every read this gate makes is its qualified check's
# (premgate has no probes or obligations table), so each is failed in turn with
# the counting awk from the obligations block. PRED tags what it finds, c6 for
# the verdict and c7 for the count, so one sweep serves both assertions.
_qgt="$QGH/projects/premgate/qualification.tsv"
_qpfails() {
  local f r
  [ -z "$(_qpunder "$_qsout" ok)" ] || printf '[c6 qualified ok] '
  f="$(_qpunder "$_qsout" FAIL)"
  if [ -z "$f" ]; then printf '[c6 no qualified FAIL] '
  else
    r="$(printf '%s\n' "$f" | sed 1d | grep -v '^gate:' | grep -c 'could not be read')"
    [ "$r" -ge 1 ] || printf '[c6 nothing under qualified FAIL says what could not be read] '
  fi
  case "$_qsout" in *"across 0 checker(s)"*) printf '[c7 across 0 checker(s)] ' ;; esac
  case "$_qsout" in *"awk:"*|*"can't open file"*) printf "[c7 awk's own error] " ;; esac
}
if [ "$_unreadable" -eq 1 ]; then
  _qpeach="$(_qeach 1 _qpfails _qpgate)"
  is  "whichever read of the table felix gate's qualified check makes fails, it prints qualified FAIL with a line under it saying what could not be read" \
      "$(printf '%s\n' "$_qpeach" | awk '/\[c6/ || (NF && !/\[c7/)')" ""
  is  "and whichever read fails, felix gate never says across 0 checker(s) nor shows awk's own error" \
      "$(printf '%s\n' "$_qpeach" | awk '/\[c7/ || (NF && !/\[c6/)')" ""
else
  for a in "whichever read of the table felix gate's qualified check makes fails, it prints qualified FAIL with a line under it saying what could not be read" \
           "and whichever read fails, felix gate never says across 0 checker(s) nor shows awk's own error"; do
    skip "$a" "$_noread"; done
fi
# The same from the start: a table at mode 000 failed qualified with nothing
# under FAIL, because the lines the gate lifts from felix qualify's output were
# only held, unrunnable, malformed and never shown.
if [ "$_unreadable" -eq 1 ]; then
  chmod 000 "$_qgt"; _qsout="$(_qpgate)"; chmod 644 "$_qgt"
  is  "felix gate over a table it cannot read fails qualified and says under it that the table could not be read" \
      "$(_qpfails)" ""
else
  skip "felix gate over a table it cannot read fails qualified and says under it that the table could not be read" "$_noread"
fi
# And a table holding a NUL byte, which felix qualify --gate passed whenever
# the rows awk saw were met, so the gate printed qualified ok. It fails now,
# with the felix: line saying the table holds a NUL lifted under the FAIL. The
# twins, the NUL taken out, fail on their held or unrunnable row or pass as
# before, so the FAIL is the NUL's. The tables are _qznul's, from the needs block.
cp "$_qgt" "$TMP/premgate-nul.keep"
_qpnul() {
  local f
  [ -z "$(_qpunder "$_qsout" ok)" ] || printf 'qualified ok; '
  f="$(_qpunder "$_qsout" FAIL)"
  if [ -z "$f" ]; then printf 'no qualified FAIL; '
  else
    [ "$(printf '%s\n' "$f" | sed 1d | grep -E '^ +felix: ' | grep -F '/projects/premgate/qualification.tsv' | grep -c 'NUL')" -ge 1 ] \
      || printf 'no felix: line under qualified FAIL naming the table and saying it holds a NUL; '
  fi
}
_qptwin() {   # WHERE
  case "$1" in
    alone|comment) [ -n "$(_qpunder "$_qsout" ok)" ] || printf 'no qualified ok; ' ;;
    field) [ "$(_qpunder "$_qsout" FAIL | grep -cE ' held +violation +fail +unrunnable +UNRUNNABLE$')" = 1 ] \
             || printf 'no UNRUNNABLE row under qualified FAIL; ' ;;
    *)     [ "$(_qpunder "$_qsout" FAIL | grep -cE ' held +violation +fail +pass +HELD$')" = 1 ] \
             || printf 'no HELD row under qualified FAIL; ' ;;
  esac
}
_qpnuls() {   # PRED [clean]: felix gate over each table, a line for each PRED finds wrong
  local w said
  for w in $_qzwhere; do
    _qznul "$w" ${2:+"$2"} > "$_qgt"; _qsout="$(_qpgate)"
    said="$("$1" "$w")"; [ -z "$said" ] || printf '%s: %s\n' "$w" "$said"
  done
}
is  "felix gate over a table holding a NUL byte anywhere fails qualified, never ok, and shows under it the felix: line naming the table and its NUL" \
    "$(_qpnuls _qpnul)" ""
is  "and over each twin, its NUL taken out, felix gate reads as before: qualified FAIL over the held or unrunnable row, and qualified ok when the NUL sat on a blank or comment line" \
    "$(_qpnuls _qptwin clean)" ""
cp "$TMP/premgate-nul.keep" "$_qgt"
# And a present, empty table, which failed the same way with nothing under it.
cp "$_qgt" "$TMP/premgate-qual.keep"
: > "$_qgt"
_qsout="$(_qpgate)"
_qpwhy="$(_qpunder "$_qsout" FAIL | sed 1d | grep -v '^gate:' | grep -v '^ *$')"
has "felix gate over a present, empty table fails qualified and says under it that no checker here is qualified" \
    "$_qpwhy" "No checker here is qualified"
# The sentence runs onto a second line, and the first alone ended at the
# table's path, a reason that never said what was wrong with the table.
has "and says why, that it declares no control that can be run" \
    "$_qpwhy" "declares no control that can be run"
# The lines lifted under qualified FAIL were picked by a word anywhere in the
# line, so a checker whose name held HELD took its met rows for held ones: eight
# of them filled the eight lines, and the reason, a checker never shown failing,
# was cut off below them. A checker is an id now, lowercase, so no met row can
# hold HELD, UNRUNNABLE or MALFORMED, and a checker named HELDOUT is itself a
# malformed row, a reason in its own right (the reader's assertions above).
# That leaves the lift picking each word where it sits as defence in depth,
# which no assertion can turn red alone; this one guards what it is for, eight
# met rows ahead of the reason and none of them lifted. The reason comes
# second, so a lift that keeps the first eight matches loses it.
{ for _qpi in 1 2 3 4 5 6 7 8; do _qp5 heldout "$_qpc" violation fail 'printf FORBIDDEN > bad.txt'; done
  _qp6 zz "$_qpc" violation fail 'printf FORBIDDEN > bad.txt' false; } > "$_qgt"
_qpwhy="$(_qpunder "$(_qpgate)" FAIL | sed 1d | grep -v '^gate:' | grep -v '^ *$')"
has "felix gate names under qualified FAIL a checker never shown failing, beside eight met rows of a checker named heldout" \
    "$_qpwhy" "never shown failing in this checkout: zz"
is  "and lifts none of those met rows as a reason" "$(printf '%s\n' "$_qpwhy" | grep -cE ' ok$')" "0"
cp "$TMP/premgate-qual.keep" "$_qgt"
# A row that ran and was met before the verdict was the control's: the gate
# read ok over it. Now it refuses, and says which row and why.
{ _qptab_shown; _qp5 demo "$_qpc" violation pass true; } > "$QGH/projects/premgate/qualification.tsv"
_qpgo="$(_qpgate)"
has "felix gate fails qualification over a row whose verdict is not its control's" \
    "$(_qpunder "$_qpgo" FAIL)" "qualified"
has "and shows the row and the verdict under qualified FAIL" \
    "$(_qpunder "$_qpgo" FAIL)" "violation must expect fail, not [pass]"
# The checker count under qualified ok is the table's, however it is reached:
# one read, and the checkers whose controls ran. Three checkers over four met
# controls, so a count of rows or of met controls cannot pass for it.
{ _qp5 alpha "$_qpc" violation   fail 'printf FORBIDDEN > bad.txt'
  _qp5 alpha "$_qpc" restoration pass true
  _qp5 beta  "$_qpc" violation   fail 'printf FORBIDDEN > bad.txt'
  _qp5 gamma "$_qpc" violation   fail 'printf FORBIDDEN > bad.txt'; } > "$QGH/projects/premgate/qualification.tsv"
_qpgo="$(_qpgate)"
is  "a clean felix gate counts across as many checkers as the table's well-formed rows name" \
    "$(_qpunder "$_qpgo" ok | grep -o '[0-9]* control(s) met across [0-9]* checker(s)')" "4 control(s) met across 3 checker(s)"
# A checker that is not an id. Six controls met by `my check` were met across
# 0 checkers, because the count took one word before the control; the checkers
# were walked by an unquoted for, which split the name into two checkers
# declaring nothing and read a checker named * as the files in the checkout,
# a.txt among them. Such a row is malformed now, so felix qualify --gate refuses
# it and the gate shows it under qualified FAIL. The count taking what is left
# of a row once its last four columns are off, and the checkers walked a line
# at a time, stay as defence in depth: no well-formed row reaches either with a
# space or a glob in its checker, so no assertion here turns red on them alone.
{ for _qpx in violation alternate decoupled_violation; do _qp5 'my check' "$_qpc" "$_qpx" fail 'printf FORBIDDEN > bad.txt'; done
  for _qpx in restoration irrelevant decoupled_satisfaction; do _qp5 'my check' "$_qpc" "$_qpx" pass true; done
  _qp5 '*' "$_qpc" violation fail 'printf FORBIDDEN > bad.txt'
  _qp5 demo "$_qpc" violation fail 'printf FORBIDDEN > bad.txt'
} > "$_qgt"
( cd "$QGR" && FELIX_HOME="$QGH" "$QGH/harness/felix" qualify --gate >/dev/null 2>&1 ); _qprc=$?
is  "felix qualify --gate refuses rows whose checker is my check or *, rather than running them" "$_qprc" "1"
_qpgo="$(_qpgate)"
_qpwhy="$(_qpunder "$_qpgo" FAIL | sed 1d | grep -v '^gate:')"
is  "and felix gate fails qualified showing each such row MALFORMED under it" \
    "$(printf '%s\n' "$_qpwhy" | grep -cE '^  +(my check|\*) +MALFORMED  \[(my check|\*)\] is not a checker name')" "7"
case "$_qpgo" in
  *"across 0 checker(s)"*|*"a.txt"*) bad "and never counts across 0 checkers nor names a file of the checkout" "$_qpgo" ;;
  *) ok "and never counts across 0 checkers nor names a file of the checkout" ;;
esac
cp "$TMP/premgate-qual.keep" "$_qgt"
# A run of the controls that did not finish, and one that finished having given
# fewer verdicts than rows, each refused alone. A kill part way gives both at
# once, so each refusal stood behind the other and neither was shown to hold by
# itself. A kill after the loop's last verdict would show the first alone, but
# nothing outside the shell runs between that verdict and the loop's end to
# stage it from, so the row loop is doctored instead, in a copy of this home:
# once to return 3 having given every verdict, once to return 0 having dropped
# its last. Two met controls each time, so what was doctored is the only reason
# to refuse, and the verdicts it did give are counted, so a doctoring that broke
# the loop cannot pass for one that did what it says.
_qdoc() {   # HOME BODY: a copy of the premgate home whose row loop is BODY, the real one being _qdoc_run_rows
  rm -rf "$1"; cp -R "$QGH" "$1"
  { printf '%s\n' 'eval "_qdoc_run_rows () $(declare -f _felix_qualify_run_rows | sed 1d)"'
    printf '_felix_qualify_run_rows() { %s; }\n' "$2"; } >> "$1/harness/lib/qualify.sh"
  { _qp5 demo "$_qpc" violation fail 'printf FORBIDDEN > bad.txt'
    _qp5 demo "$_qpc" restoration pass true; } > "$1/projects/premgate/qualification.tsv"
}
_qdq() { ( cd "$QGR" && FELIX_HOME="$1" "$1/harness/felix" qualify --gate 2>&1 ); }
_qdn() {   # exit:ok rows:did-not-finish lines:ran-fewer lines, of _qsout and _qsrc
  printf '%s:%s:%s:%s' "$_qsrc" "$(printf '%s\n' "$_qsout" | grep -cE ' ok$')" \
    "$(printf '%s\n' "$_qsout" | grep -c '^felix: the run of the controls did not finish$')" \
    "$(printf '%s\n' "$_qsout" | grep -c '^only 1 of 2 declared control(s) ran')"
}
_qdoc "$TMP/qual-doc-unfinished" '_qdoc_run_rows "$@"; return 3'
_qsout="$(_qdq "$TMP/qual-doc-unfinished")"; _qsrc=$?
is  "a row loop that gave every verdict and then failed refuses --gate by itself, saying the run did not finish" \
    "$(_qdn)" "1:2:1:0"
_qdoc "$TMP/qual-doc-short" '_qdoc_run_rows "$@" | awk "NR == 1"'
_qsout="$(_qdq "$TMP/qual-doc-short")"; _qsrc=$?
is  "and one that finished having given 1 verdict of 2 refuses by itself, saying 1 of 2 ran" \
    "$(_qdn)" "1:1:0:1"
# felix gate over a felix qualify --gate cut short. Its row loop killed at the
# second of two met controls leaves felix qualify saying the run did not finish
# and that 1 of 2 ran, and each is lifted under qualified FAIL. felix qualify
# --gate itself killed at the first says nothing a line is lifted for, and the
# FAIL still says where to read why rather than standing alone.
_qpk() {   # K BELOW: felix gate with its Kth worktree add killing the process BELOW under the CLI
  : > "$_QSC"; rm -f "$_QSC.killed"
  _qsout="$( cd "$QGR" && PATH="$_QGSHIM:$PATH" QKILL_COUNT="$_QSC" QKILL_AT="$1" QKILL_BELOW="$2" \
             QKILL_FELIX="$QGH/harness/felix" QKILL_SPARE="$$" FELIX_HOME="$QGH" "$QGH/harness/felix" gate 2>&1 )"
  [ -s "$_QSC.killed" ]
}
{ _qp5 demo "$_qpc" violation fail 'printf FORBIDDEN > bad.txt'
  _qp5 demo "$_qpc" restoration pass true; } > "$_qgt"
_qpa="felix gate over a felix qualify --gate whose row loop was killed says under qualified FAIL that the run did not finish and 1 of 2 ran"
if _qpk 2 2; then
  is  "$_qpa" "$(_qpunder "$_qsout" FAIL | sed 1d \
      | grep -cE '^  felix: the run of the controls did not finish$|^  only 1 of 2 declared control\(s\) ran')" "2"
else bad "$_qpa" "$_qknone"; fi
_qpa="and over a felix qualify --gate killed before it said anything, qualified FAIL still says where to read why"
if _qpk 1 1; then
  is  "$_qpa" "$(_qpunder "$_qsout" FAIL | sed 1d | grep -c '^  felix qualify --gate refused; run it to read why$')" "1"
else bad "$_qpa" "$_qknone"; fi
cp "$TMP/premgate-qual.keep" "$_qgt"
printf '\nautonomy is opted into, never assumed\n'
AUP="$TMP/autoproj"; mkdir -p "$AUP"
a() { ( . "$FROOT/harness/lib/autonomy.sh"; felix_autonomy_allows "$AUP" "$1" && echo yes || echo no ); }
is "nothing is allowed by default"    "$(a tidy)" "no"
printf '# what Felix may do here unattended\ntidy\n' > "$AUP/autonomy"
is "an opted-in capability is allowed" "$(a tidy)" "yes"
is "and one that was not is still not" "$(a route)" "no"
printf 'tidy\n' > "$AUP/autonomy"; printf '\n\n# comment\n' >> "$AUP/autonomy"
is "comments and blanks are not capabilities" "$(a comment)" "no"
