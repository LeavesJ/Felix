printf '\nqualification: a row runs in a shell of its own\n'
# A row's premise, mutation and command ran inside the process that called the
# runner, so they took that process's options, and the felix CLI's are
# set -uo pipefail. Under pipefail `producer | grep -q x` fails when x is
# there: grep leaves at its first match and the producer dies of SIGPIPE. Under
# nounset a name the row never set stops the row. Each column moves a verdict
# its own way. A premise that misfires skips its control, or applies it where
# the premise is absent. A mutation cut short leaves a pass control met over a
# change the checker never saw. A command that misfires reads fail, and on a
# fail control fail is met, which is exactly what a working checker says, so
# nothing later can tell the two apart. Probes, obligations and maintenance
# run their rows in a fresh bash with nothing on stdin, and a row here runs the
# same way. There a command or mutation that exits 126 or 127 ran nothing, so
# it is unrunnable, never a verdict.
#
# Every call is made from a shell that sets -uo pipefail itself, whatever the
# suite's own options are. The producer writes about 2.7 MB with the match on
# its first line. That is far more than a pipe holds, so the producer is
# certainly still writing when grep leaves, and the miss does not depend on
# load. Authored blind to the runner's source, from the contract in prose.
_widget_repo_build
QFRP="$TMP/qual-fresh"; QFRR="$TMP/qual-fresh-repo"; QFRS="$TMP/qual-fresh-side"
mkdir -p "$QFRP" "$QFRR" "$QFRS" "$MEM/qual-fresh"
( _fx_cd "$QFRR" && git init -q -b main && printf 'clean\n' > base.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
QFRR="$(cd "$QFRR" && pwd -P)"
_qfrhead="$(git -C "$QFRR" rev-parse HEAD 2>/dev/null)"
_qfr5() { printf '%s\t%s\t%s\t%s\t%s\n' "$@"; }
_qfr6() { printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$@"; }
# Called from inside the root, as the CLI is, so a row that ran where it was
# called from would run there, and the root would show it.
_qfrrun() { ( cd "$2" || exit 1; set -uo pipefail; unset QFR_NEVER_SET
              . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
              felix_qualify_run "$@" ) 2>/dev/null; }
# A checker that catches FORBIDDEN anywhere in the tree, and the producer.
_qfrc='! grep -rqI FORBIDDEN . 2>/dev/null'
_qfrbig="awk 'BEGIN { print \"QFR-FOUND\"; for (i = 0; i < 60000; i++) print \"filler past the one line grep needs to read\" }'"
_qfrgrep="$_qfrbig | grep -q QFR-FOUND"
# The schema-check rows' shape: a finding the checker prints first, above more
# output than a pipe holds, and a command that passes only when it is absent.
_qfrneg="! { [ -f qfr-finding.txt ] && $_qfrbig | grep -qE '^QFR-FOUND\$'; }"
_qfrlocals='"${scratch:-}|${cmd:-}|${1:-}"'
{ _qfr6 bigpremise    "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' "$_qfrgrep"
  _qfr6 bignotpremise "$_qfrc" violation fail \
        "printf x >> '$QFRS/bignotpremise-mutated'; printf FORBIDDEN > bad.txt" "! $_qfrgrep"
  _qfr5 bigmutation   "$_qfrc" violation fail "$_qfrgrep && printf FORBIDDEN > bad.txt"
  _qfr5 bigmutpass    "$_qfrc" restoration pass "$_qfrgrep && printf FORBIDDEN > bad.txt"
  _qfr5 bigcommand    "$_qfrgrep" restoration pass true
  _qfr5 bigcmdfail    "$_qfrgrep" violation fail true
  _qfr5 bigschema     "$_qfrneg" violation fail 'printf planted > qfr-finding.txt'
  _qfr6 unsetpremise  "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' '[ -z "$QFR_NEVER_SET" ]'
  _qfr5 unsetmutation "$_qfrc" violation fail '[ -z "$QFR_NEVER_SET" ] && printf FORBIDDEN > bad.txt'
  _qfr5 unsetcommand  '[ -z "$QFR_NEVER_SET" ]' restoration pass true
  _qfr5 unsetcmdfail  '[ -z "$QFR_NEVER_SET" ]' violation fail true
  _qfr5 enginefn      'felix_qualify_rows .' violation fail 'printf FORBIDDEN > bad.txt'
  _qfr5 runnerlocals  "printf '%s' $_qfrlocals > '$QFRS/locals-seen'; [ $_qfrlocals = '||' ]" restoration pass true
  _qfr5 nocheckfail   './qfr-no-such-checker' violation fail 'printf FORBIDDEN > bad.txt'
  _qfr5 nocheckpass   './qfr-no-such-checker' restoration pass true
  _qfr5 cmdexit126    'exit 126' violation fail 'printf FORBIDDEN > bad.txt'
  _qfr5 cmdnoexec     './qfr-noexec.sh' irrelevant pass 'printf "exit 0" > qfr-noexec.sh'
  _qfr5 cmdexitone    'exit 1' violation fail true
  _qfr5 cmdexittwo    'exit 2' violation fail true
  _qfr5 mutmissing    "printf x >> '$QFRS/mutmissing-checked'; $_qfrc" irrelevant pass 'qfr-no-such-mutation-tool FORBIDDEN'
  _qfr5 mutexit126    "$_qfrc" irrelevant pass 'exit 126'
  _qfr5 mutexitone    "printf x >> '$QFRS/mutexitone-checked'; $_qfrc" violation fail 'printf FORBIDDEN > bad.txt; exit 1'
  _qfr6 premzero      "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' 'exit 0'
  _qfr6 premone       "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' 'exit 1'
  _qfr6 premtwo       "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' 'exit 2'
  _qfr6 wherefrom     "pwd -P > '$QFRS/pwd-command'; $_qfrc" violation fail \
        "pwd -P > '$QFRS/pwd-mutation'; printf FORBIDDEN > bad.txt" "pwd -P > '$QFRS/pwd-premise'; test -f base.txt"
} > "$QFRP/qualification.tsv"
_qfro="$(_qfrrun "$QFRP" "$QFRR")"
# What checker $1's one row got and its verdict, and whether a mark was made.
_qfrv() { printf '%s\n' "$_qfro" | awk -F'\t' -v c="$1" '$1 == c { print $4 " " $5 }'; }
_qfre() { [ -e "$1" ] && echo ran || echo absent; }

# The premise. A plain pipeline whose match is there read 141, unrunnable; a
# negated one read 0, and applied its control where the premise is absent.
is  "a premise piping big output into grep -q that finds its match lets its control run and be met, never unrunnable" \
    "$(_qfrv bigpremise)" "fail met"
is  "a premise negating that pipeline makes its control inapplicable and never applies its mutation" \
    "$(_qfrv bignotpremise) $(_qfre "$QFRS/bignotpremise-mutated")" "- inapplicable absent"
# The mutation. An && after the pipeline never ran, so the tree carried none of
# the change: a fail control read held, and a pass control read met over a
# change the checker was never shown.
is  "a mutation that starts with that pipeline and an && makes its whole change, so a checker that catches it is met, not held" \
    "$(_qfrv bigmutation)" "fail met"
is  "and on a pass control the same mutation is seen whole: a checker rejecting it is held, never met over a tree the mutation did not reach" \
    "$(_qfrv bigmutpass)" "fail held"
# The command. The plain shape read fail when it should pass, which on a fail
# control is met; the negated schema shape read pass when it should fail.
is  "a command that is that pipeline passes a pass control and is met, rather than failing and held" \
    "$(_qfrv bigcommand)" "pass met"
is  "and on a fail control it reads pass and held, never fail and met, which is what a working checker says" \
    "$(_qfrv bigcmdfail)" "pass held"
is  "a command in the schema rows' negated shape over big output fails when its mutation plants the finding, and the control is met, not held" \
    "$(_qfrv bigschema)" "fail met"
# nounset. A name nobody set is empty to a fresh shell, not an error.
is  "a premise testing a name nobody set applies its control rather than reading as inapplicable" \
    "$(_qfrv unsetpremise)" "fail met"
is  "a mutation testing a name nobody set runs to the end, so the checker catches its change" \
    "$(_qfrv unsetmutation)" "fail met"
is  "a command testing a name nobody set passes, rather than failing and held" \
    "$(_qfrv unsetcommand)" "pass met"
is  "and on a fail control that command passes and is held, never fail and met because nounset stopped it" \
    "$(_qfrv unsetcmdfail)" "pass held"
# The runner's own functions, locals and positional parameters. A row that
# called an engine function would run the installed engine, which the
# mutation cannot reach, rather than the checker in the tree it mutated.
is  "a command naming an engine function finds no such command and reads unrunnable, neither pass nor fail" \
    "$(_qfrv enginefn)" "unrunnable unrunnable"
is  "a command sees none of the runner's locals or positional parameters: scratch, cmd and 1 are empty to it" \
    "$(_qfrv runnerlocals) [$(cat "$QFRS/locals-seen" 2>/dev/null)]" "pass met [||]"
# A command that exits 126 or 127 ran no checker. Read as fail, a checker path
# with a typo in it would be met on every fail control.
is  "a checker that does not exist, exit 127, reads unrunnable on a fail control, never fail and met" \
    "$(_qfrv nocheckfail)" "unrunnable unrunnable"
is  "and unrunnable on a pass control, never fail and held" \
    "$(_qfrv nocheckpass)" "unrunnable unrunnable"
is  "a command exiting 126, or a checker file that is not executable, reads unrunnable, while one exiting 1 or 2 still reads fail and met" \
    "$(_qfrv cmdexit126); $(_qfrv cmdnoexec); $(_qfrv cmdexitone); $(_qfrv cmdexittwo)" \
    "unrunnable unrunnable; unrunnable unrunnable; fail met; fail met"
# A mutation that exits 126 or 127 made no change, so its control was never
# shown anything. Its other statuses are still ignored.
is  "a mutation whose command does not exist, exit 127, makes its pass control unrunnable, never met over a tree it did not change" \
    "$(_qfrv mutmissing)" "unrunnable unrunnable"
is  "and no checker runs after a mutation that exited 127" \
    "$(_qfre "$QFRS/mutmissing-checked")" "absent"
is  "a mutation exiting 126 is unrunnable too, while one exiting 1 still has its status ignored and its checker decides the row" \
    "$(_qfrv mutexit126); $(_qfrv mutexitone) $(_qfre "$QFRS/mutexitone-checked")" \
    "unrunnable unrunnable; fail met ran"
# Unchanged, and green before this change as after it.
is  "a premise exiting 0 still applies its control, 1 still makes it inapplicable, and 2 still makes it unrunnable" \
    "$(_qfrv premzero); $(_qfrv premone); $(_qfrv premtwo)" \
    "fail met; - inapplicable; unrunnable unrunnable"
_qfrwd="$(cat "$QFRS/pwd-premise" 2>/dev/null)"
is  "premise, mutation and command run in one scratch worktree of HEAD, never in the root" \
    "$(_qfrv wherefrom) $([ -n "$_qfrwd" ] && [ "$_qfrwd" = "$(cat "$QFRS/pwd-mutation" 2>/dev/null)" ] \
       && [ "$_qfrwd" = "$(cat "$QFRS/pwd-command" 2>/dev/null)" ] && echo one-tree || echo apart) $(
       [ "$_qfrwd" = "$QFRR" ] && echo root || echo elsewhere)" \
    "fail met one-tree elsewhere"
# Nothing on stdin, in any column. The marker is on the caller's stdin and in
# the rows after each reader, so a column given either one finds it.
QFRI="$TMP/qual-fresh-stdin"; mkdir -p "$QFRI"
{ _qfr6 premreader "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' '! grep -q QFR-STDIN'
  _qfr5 mutreader  "$_qfrc" violation fail 'grep -q QFR-STDIN || printf FORBIDDEN > bad.txt'
  _qfr5 cmdreader  '! grep -q QFR-STDIN' restoration pass true
  _qfr5 trailer    'true QFR-STDIN' restoration pass 'true QFR-STDIN'
} > "$QFRI/qualification.tsv"
is  "no column reads the caller's stdin or the table: a premise, a mutation and a command that grep their stdin find nothing" \
    "$(printf 'QFR-STDIN\n' | _qfrrun "$QFRI" "$QFRR" | awk -F'\t' '{ printf "%s %s %s; ", $1, $4, $5 }')" \
    "premreader fail met; mutreader fail met; cmdreader pass met; trailer pass met; "
# A column that ran nothing is unrunnable, whatever status its text ended on.
# In a fresh bash a name only the engine has is not found, and in a pipeline,
# an if, or behind a !, the final status hides that. The column's own shell
# still says so, under the felix-qualify $0 the runner gives it; a checker's
# complaints carry the checker's own path and decide nothing. Text that does
# not parse, or is blank, runs nothing either, and the fresh bash takes no
# SHELLOPTS or BASH_ENV from its caller. The rest pin what the fresh shell
# already does: -- before the text, a mutation's other statuses ignored and
# never carried, bash rather than sh, a tree that is gone, stdout kept out of
# the verdict, and a premise's 126. Authored blind, from the contract in prose.
QFRX="$TMP/qual-fresh-more"; mkdir -p "$QFRX"
# A tool outside the tree that complains, under its own path, of a command it
# cannot find, and then exits with the status it is handed.
_qfrcnf="$QFRS/qfr-cnf-tool"
printf '#!/bin/bash\nqfr_cnf_missing_tool\nexit "${1:-0}"\n' > "$_qfrcnf"; chmod +x "$_qfrcnf"
# A line shaped like a verdict for the row that prints it.
_qfrfake="printf 'stdoutrow\\tviolation\\tfail\\tpass\\theld\\n'"
_qfrpreml='"${scratch:-}|${premise:-}|${1:-}"'
_qfrmutl='"${scratch:-}|${mut:-}|${1:-}"'
{ _qfr5 cnfpipecmd   'felix_qualify_rows . | grep -q QFR-FOUND' violation fail 'printf FORBIDDEN > bad.txt'
  _qfr5 cnfnegpass   '! { felix_qualify_rows . | grep -q QFR-FOUND; }' restoration pass true
  _qfr6 cnfpipeprem  "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' 'felix_qualify_rows . | grep -q QFR-FOUND'
  _qfr5 cnfifmut     "$_qfrc" restoration pass 'if felix_qualify_rows .; then printf FORBIDDEN > bad.txt; fi'
  _qfr5 cnfbarename  'qfr_no_such_cmd . | grep -q QFR-FOUND' violation fail 'printf FORBIDDEN > bad.txt'
  _qfr5 toolcnfpass  "'$_qfrcnf' 0" restoration pass true
  _qfr5 toolcnffail  "'$_qfrcnf' 1" violation fail 'printf FORBIDDEN > bad.txt'
  _qfr6 toolcnfprem  "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' "'$_qfrcnf' 0"
  _qfr5 toolcnfmut   "$_qfrc" violation fail "'$_qfrcnf' 0; printf FORBIDDEN > bad.txt"
  _qfr5 parsecmd     "$_qfrc '" violation fail 'printf FORBIDDEN > bad.txt'
  _qfr5 parsemut     "printf x >> '$QFRS/parsemut-checked'; $_qfrc" restoration pass "printf 'FORBIDDEN > bad.txt"
  _qfr6 parseprem    "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' "test -f base.txt '"
  _qfr5 emptycmd     '' restoration pass true
  _qfr5 spacecmd     '   ' restoration pass true
  _qfr5 spacemut     "$_qfrc" restoration pass '   '
  _qfr6 spaceprem    "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' '   '
  _qfr6 emptyprem    "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' ''
  _qfr6 dashprem     "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' '-'
  _qfr5 dashcmd      '-x ./qfr-no-such-checker' violation fail 'printf FORBIDDEN > bad.txt'
  _qfr5 mutonepass   true violation fail 'exit 1'
  _qfr5 mutexittwo   "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt; exit 2'
  _qfr6 premenginefn "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' 'felix_contains engine gin'
  _qfr6 premmutlocal true restoration pass "printf '%s' $_qfrmutl > '$QFRS/mut-locals-seen'" \
        "printf '%s' $_qfrpreml > '$QFRS/prem-locals-seen'"
  _qfr5 procsubcmd   'grep -qx clean <(cat base.txt)' restoration pass true
  _qfr6 stdoutrow    "$_qfrfake; $_qfrc" violation fail "$_qfrfake; printf FORBIDDEN > bad.txt" "$_qfrfake; test -f base.txt"
  _qfr6 premexit126  "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' 'exit 126'
} > "$QFRX/qualification.tsv"
_qfrx="$(_qfrrun "$QFRX" "$QFRR")"
_qfrxv() { printf '%s\n' "$_qfrx" | awk -F'\t' -v c="$1" '$1 == c { print $4 " " $5 }'; }
# Not found where the final status hides it. The old runner ran the function in
# its own process; in a fresh bash it is gone, and grep's 1 was all that showed.
is  "a command piping an engine function into grep -q reads unrunnable on a fail control, never fail and met with no checker run" \
    "$(_qfrxv cnfpipecmd)" "unrunnable unrunnable"
is  "a pass control's command negating that pipeline reads unrunnable, never pass and met" \
    "$(_qfrxv cnfnegpass)" "unrunnable unrunnable"
is  "a premise piping an engine function into grep -q reads unrunnable, never inapplicable" \
    "$(_qfrxv cnfpipeprem)" "unrunnable unrunnable"
is  "a mutation testing an engine function in an if makes its pass control unrunnable, never met over a change it never made" \
    "$(_qfrxv cnfifmut)" "unrunnable unrunnable"
is  "a name that exists nowhere, in a pipeline, counts as an engine function does: the command reads unrunnable, never fail and met" \
    "$(_qfrxv cnfbarename)" "unrunnable unrunnable"
# Only the column's own shell is heard. A tool that is not found inside a
# checker is the checker's business, and its status still decides.
is  "a checker whose own stderr says command not found, under its own path, still decides by its status: pass and met at 0, fail and met at 1" \
    "$(_qfrxv toolcnfpass); $(_qfrxv toolcnffail)" "pass met; fail met"
is  "and a premise and a mutation running that tool still apply the control and make the change, so the checker is met" \
    "$(_qfrxv toolcnfprem); $(_qfrxv toolcnfmut)" "fail met; fail met"
# Text that does not parse ran nothing. As a command it exited 2 and read fail;
# as a mutation its 2 was ignored, and a pass control was met over no change.
is  "a command that does not parse, a stray quote after its checker, reads unrunnable, never fail and met" \
    "$(_qfrxv parsecmd)" "unrunnable unrunnable"
is  "a mutation that does not parse makes its pass control unrunnable, and no checker runs after it" \
    "$(_qfrxv parsemut) $(_qfre "$QFRS/parsemut-checked")" "unrunnable unrunnable absent"
is  "a premise that does not parse reads unrunnable, never inapplicable" \
    "$(_qfrxv parseprem)" "unrunnable unrunnable"
# Blank text ran nothing and exited 0. A premise that is absent, empty or - is
# no premise; one of spaces is text that runs nothing.
is  "an empty command and a command of spaces each read unrunnable, never pass and met with no checker run" \
    "$(_qfrxv emptycmd); $(_qfrxv spacecmd)" "unrunnable unrunnable; unrunnable unrunnable"
is  "a mutation of spaces makes its pass control unrunnable, never met over no change" \
    "$(_qfrxv spacemut)" "unrunnable unrunnable"
is  "a premise of spaces reads unrunnable, never applied as a premise that held" \
    "$(_qfrxv spaceprem)" "unrunnable unrunnable"
is  "an empty premise and a premise of - still mean no premise: the control applies and is met" \
    "$(_qfrxv emptyprem); $(_qfrxv dashprem)" "fail met; fail met"
# Already so in the fresh shell, and pinned.
is  "a command whose text begins with a dash runs as a command and reads unrunnable, never taken for bash's own options and read fail and met" \
    "$(_qfrxv dashcmd)" "unrunnable unrunnable"
is  "a mutation exiting 1 on a fail control whose checker passes reads pass and held: the mutation's status never becomes the command's" \
    "$(_qfrxv mutonepass)" "pass held"
is  "a mutation that plants its change and then exits 2 still has its status ignored, and the checker that catches the change is met" \
    "$(_qfrxv mutexittwo)" "fail met"
is  "a premise that is an engine function alone reads unrunnable: a premise's shell has none of the runner's functions" \
    "$(_qfrxv premenginefn)" "unrunnable unrunnable"
is  "a premise and a mutation see none of the runner's locals or positional parameters: each writes || for scratch, its own text and 1" \
    "[$(cat "$QFRS/prem-locals-seen" 2>/dev/null)] [$(cat "$QFRS/mut-locals-seen" 2>/dev/null)]" "[||] [||]"
is  "a command that needs bash, a process substitution, passes its pass control and is met: a row runs in bash, never sh" \
    "$(_qfrxv procsubcmd)" "pass met"
is  "a row whose premise, mutation and command each print a line shaped like a verdict yields one verdict line, fail and met: a row's stdout never reaches the verdict" \
    "$(printf '%s\n' "$_qfrx" | awk '/stdoutrow/ { gsub(/\t/, " "); printf "%s%s", s, $0; s = "; " }')" \
    "stdoutrow violation fail fail met"
is  "a premise exiting 126 reads unrunnable, never inapplicable" \
    "$(_qfrxv premexit126)" "unrunnable unrunnable"
# The caller's options reach a child bash two ways besides inheritance: an
# exported SHELLOPTS, and a BASH_ENV file every child sources. Each is exported
# only inside the subshell that calls the runner, so nothing later sees it.
QFRE="$TMP/qual-fresh-env"; mkdir -p "$QFRE"
_qfr5 envbig "$_qfrgrep" restoration pass true > "$QFRE/qualification.tsv"
printf 'set -o pipefail\n' > "$QFRS/qfr-bash-env"
_qfrenv() { ( cd "$QFRR" || exit 1; set -uo pipefail; unset QFR_NEVER_SET
              case "$1" in
                shellopts) export SHELLOPTS ;;
                bashenv)   export BASH_ENV="$QFRS/qfr-bash-env" ;;
              esac
              . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
              felix_qualify_run "$QFRE" "$QFRR" ) 2>/dev/null \
              | awk -F'\t' '$1 == "envbig" { print $4 " " $5 }'; }
is  "with SHELLOPTS exported by its caller, carrying nounset and pipefail, a command piping big output into grep -q still passes its pass control and is met" \
    "$(_qfrenv shellopts)" "pass met"
is  "and with BASH_ENV exported by its caller, naming a file that sets pipefail, that command still passes and is met" \
    "$(_qfrenv bashenv)" "pass met"
# Text that fails to parse only once it runs, inside a command substitution,
# ran nothing, and the column's own shell says syntax error under its
# felix-qualify prefix. Text that is only a comment ran nothing and exited 0.
# A caller's POSIXLY_CORRECT would put the row's bash in posix mode, where a
# process substitution does not parse. The rest pin what the fresh shell
# already does: no temporary path outlives a run, a stderr file that is gone
# counts as nothing run, a checker the row runs takes no SHELLOPTS or BASH_ENV
# either, and only a line that begins with the prefix is heard. Authored
# blind, from the contract in prose.
QFRK="$TMP/qual-fresh-three"; mkdir -p "$QFRK" "$QFRS/qfr-anchor"
# A checker outside the tree whose own file is named felix-qualify, and which
# complains, under that path, of a tool it cannot find before it passes.
_qfrkanchor="$QFRS/qfr-anchor/felix-qualify"
printf '#!/bin/bash\nqfr_anchor_missing_tool\neval "fi"\nexit 0\n' > "$_qfrkanchor"; chmod +x "$_qfrkanchor"
# A checker that ran and prints what it found, "N files hold FORBIDDEN". A row
# that does arithmetic on that output makes its own shell print a syntax error
# quoting the checker's data; the checker still decided the row.
_qfrkcount="$QFRS/qfr-count-checker"
printf '#!/bin/bash\nn=$(grep -rl FORBIDDEN . 2>/dev/null | wc -l | tr -d " ")\nif [ "$n" -gt 0 ]; then echo "$n files hold FORBIDDEN"; else echo 0; fi\n' > "$_qfrkcount"; chmod +x "$_qfrkcount"
{ _qfr5 cssyntaxcmd '[ "$(! grep -rqI FORBIDDEN . 2>/dev/null && echo clean; fi)" = clean ]' violation fail 'printf FORBIDDEN > bad.txt'
  _qfr5 cssyntaxmut "printf x >> '$QFRS/cssyntaxmut-checked'; $_qfrc" restoration pass \
        'x=$(printf FORBIDDEN; fi) && printf "%s" "$x" > bad.txt'
  _qfr5 commentcmd  '# nothing' restoration pass true
  _qfr5 commentmut  "printf x >> '$QFRS/commentmut-checked'; $_qfrc" restoration pass '  # nothing'
  _qfr6 commentprem "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' '# nothing'
  _qfr5 anchorscan  "'$_qfrkanchor'" restoration pass true
  _qfr5 arithdata   "[ \$(( \$('$_qfrkcount') )) -eq 0 ]" violation fail 'printf FORBIDDEN > bad.txt'
} > "$QFRK/qualification.tsv"
_qfrkx="$(_qfrrun "$QFRK" "$QFRR")"
_qfrkv() { printf '%s\n' "$_qfrkx" | awk -F'\t' -v c="$1" '$1 == c { print $4 " " $5 }'; }
# bash -n does not look inside a command substitution, so the text parses,
# and the error comes only when the substitution runs, with no checker run.
is  "a command whose checker sits in a command substitution holding a syntax error found only when it runs reads unrunnable on a fail control, never fail and met" \
    "$(_qfrkv cssyntaxcmd)" "unrunnable unrunnable"
is  "a mutation with such a command substitution in its && chain makes its pass control unrunnable, never met over no change, and no checker runs after it" \
    "$(_qfrkv cssyntaxmut) $(_qfre "$QFRS/cssyntaxmut-checked")" "unrunnable unrunnable absent"
is  "a command that is only a comment reads unrunnable, never pass and met with no checker run" \
    "$(_qfrkv commentcmd)" "unrunnable unrunnable"
is  "a mutation that is only a comment, after leading spaces, makes its pass control unrunnable, never met over no change, and no checker runs after it" \
    "$(_qfrkv commentmut) $(_qfre "$QFRS/commentmut-checked")" "unrunnable unrunnable absent"
is  "a premise that is only a comment reads unrunnable, never applied as a premise that held" \
    "$(_qfrkv commentprem)" "unrunnable unrunnable"
is  "a checker whose own file is named felix-qualify, complaining under its own path of a tool it cannot find and of a syntax error, still decides by its status and is pass and met at 0: only a line that begins with the prefix is heard" \
    "$(_qfrkv anchorscan)" "pass met"
is  "a checker that ran, whose output a row's arithmetic cannot read, still decides the row: its fail control is met, never unrunnable, since only the parser refusing the row's own text is heard" \
    "$(_qfrkv arithdata)" "fail met"
# The caller's environment again. Each variable is exported only inside the
# subshell that calls the runner, after the libraries are read.
QFRKP="$TMP/qual-fresh-three-posix"; QFRKC="$TMP/qual-fresh-three-checker"; mkdir -p "$QFRKP" "$QFRKC"
{ _qfr5 posixplain   'test -f base.txt' restoration pass true
  _qfr5 posixprocsub 'grep -qx clean <(cat base.txt)' restoration pass true
} > "$QFRKP/qualification.tsv"
# A checker outside the tree whose own body pipes big output into grep -q.
_qfrkbig="$QFRS/qfr-big-checker"
printf '#!/bin/bash\n%s\n' "$_qfrgrep" > "$_qfrkbig"; chmod +x "$_qfrkbig"
_qfr5 bigchecker "'$_qfrkbig'" restoration pass true > "$QFRKC/qualification.tsv"
_qfrkenv() { ( cd "$QFRR" || exit 1; set -uo pipefail
               . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
               case "$1" in
                 shellopts) export SHELLOPTS ;;
                 bashenv)   export BASH_ENV="$QFRS/qfr-bash-env" ;;
                 posix)     export POSIXLY_CORRECT=1 ;;
               esac
               felix_qualify_run "$2" "$QFRR" ) 2>/dev/null \
               | awk -F'\t' '{ printf "%s%s %s", s, $4, $5; s = "; " }'; }
is  "with POSIXLY_CORRECT exported by its caller, a command using a process substitution still passes its pass control and is met, as a plain command beside it does" \
    "$(_qfrkenv posix "$QFRKP")" "pass met; pass met"
is  "a checker the row runs, whose own body pipes big output into grep -q, passes its pass control and is met with BASH_ENV exported by the caller naming a file that sets pipefail, and again with SHELLOPTS exported: the checker inherits neither" \
    "bashenv: $(_qfrkenv bashenv "$QFRKC"); shellopts: $(_qfrkenv shellopts "$QFRKC")" "bashenv: pass met; shellopts: pass met"
# Every temporary path the runner makes is gone after a run whose rows reach
# each verdict, unrunnable from each column. mktemp is wrapped, inside the
# subshell that calls the runner, by a function that notes each path it hands
# back, however it was called.
QFRKM="$TMP/qual-fresh-three-mktemp"; _qfrkmade="$TMP/qual-fresh-three-made"
mkdir -p "$QFRKM"; : > "$_qfrkmade"
{ _qfr5 tmpmet     "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt'
  _qfr5 tmpheld    true violation fail 'printf FORBIDDEN > bad.txt'
  _qfr6 tmpinapp   "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' 'exit 1'
  _qfr6 tmppremcnf "$_qfrc" violation fail 'printf FORBIDDEN > bad.txt' 'qfr_no_such_cmd . | grep -q QFR-FOUND'
  _qfr5 tmpmutcnf  "$_qfrc" restoration pass 'qfr_no_such_cmd . | grep -q QFR-FOUND'
  _qfr5 tmpcmdcnf  'qfr_no_such_cmd . | grep -q QFR-FOUND' violation fail 'printf FORBIDDEN > bad.txt'
} > "$QFRKM/qualification.tsv"
_qfrkmk="$( ( cd "$QFRR" || exit 1; set -uo pipefail
              . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
              mktemp() { local p; p="$(command mktemp "$@")" || return
                         printf '%s\n' "$p" >> "$_qfrkmade"; printf '%s\n' "$p"; }
              felix_qualify_run "$QFRKM" "$QFRR" ) 2>/dev/null | awk -F'\t' '{ printf "%s ", $5 }')"
_qfrkleft=""
while IFS= read -r _qfrkp; do [ -e "$_qfrkp" ] && _qfrkleft="$_qfrkleft $_qfrkp"; done < "$_qfrkmade"
is  "no temporary path outlives a run whose rows are met, held, inapplicable, and unrunnable from each column: every path mktemp handed the runner is gone, and it was handed at least one" \
    "$_qfrkmk$([ -s "$_qfrkmade" ] && echo made || echo none-made) left:[$_qfrkleft]" \
    "met held inapplicable unrunnable unrunnable unrunnable made left:[]"
# A stderr file that cannot be read counts as nothing run. The mutation takes
# away its row's base directory, the scratch tree's parent, only when that
# holds the scratch tree and one file besides, its owner record not counted;
# otherwise it does nothing, and
# the checker passes and is held.
QFRKB="$TMP/qual-fresh-three-base"; mkdir -p "$QFRKB"
_qfr5 basegone "$_qfrc" violation fail \
      "d=\$(pwd -P) && [ \"\$d\" != '$QFRR' ] && test -f .git && test -f base.txt && b=\$(dirname \"\$d\") && [ \"\$(ls -A \"\$b\" | grep -vx owner | wc -l | tr -d ' ')\" = 2 ] && [ \"\$(find \"\$b\" -mindepth 1 -maxdepth 1 -type f | wc -l | tr -d ' ')\" = 1 ] && cd / && rm -rf \"\$b\"" \
      > "$QFRKB/qualification.tsv"
is  "a mutation that takes away its row's base directory, and with it the file its stderr went to, makes its fail control unrunnable, never fail and met" \
    "$(_qfrrun "$QFRKB" "$QFRR" | awk -F'\t' '$1 == "basegone" { print $4 " " $5 }')" "unrunnable unrunnable"
# A mutation that takes its own tree away. It removes only a linked worktree
# that is not the root, and the root's check below shows it did no more.
QFRU="$TMP/qual-fresh-gone"; mkdir -p "$QFRU"
_qfr5 treegone "$_qfrc" violation fail \
      "d=\$(pwd -P) && [ \"\$d\" != '$QFRR' ] && test -f .git && test -f base.txt && cd / && rm -rf \"\$d\"" \
      > "$QFRU/qualification.tsv"
is  "a mutation that removes its own scratch tree leaves nowhere to run the checker, so its fail control reads unrunnable, never fail and met" \
    "$(_qfrrun "$QFRU" "$QFRR" | awk -F'\t' '$1 == "treegone" { print $4 " " $5 }')" "unrunnable unrunnable"
is  "and the root's tree is left as it was, with nothing a row wrote in it" \
    "$(git -C "$QFRR" status --porcelain --untracked-files=all 2>&1 | tr '\n' ' ')$(git -C "$QFRR" rev-parse HEAD 2>&1)" \
    "$_qfrhead"

# End to end, through the felix CLI, which sets pipefail itself: a fail control
# in the schema rows' shape, over a checker that catches its mutation.
_qfrw="$FROOT/projects/widget/qualification.tsv"
_qfrwas="$(cat "$_qfrw" 2>/dev/null || printf '<absent>')"
cp "$_qfrw" "$TMP/qual-fresh.keep" 2>/dev/null || true
_qfr5 bigneg "$_qfrneg" violation fail 'printf planted > qfr-finding.txt' > "$_qfrw"
_qfrout="$(cd "$REPO" && "$FELIX" qualify --gate 2>&1)"; _qfrrc=$?
is  "felix qualify --gate passes a fail control in the schema rows' negated shape over big output when its checker catches the mutation" \
    "$_qfrrc" "0"
is  "and shows that control met, its checker failing" \
    "$(printf '%s\n' "$_qfrout" | grep -cE '^  bigneg +violation +fail +fail +ok$')" "1"
rm -f "$_qfrw"
[ -f "$TMP/qual-fresh.keep" ] && mv "$TMP/qual-fresh.keep" "$_qfrw"
is  "and the widget table is as the fresh-shell block found it" \
    "$(cat "$_qfrw" 2>/dev/null || printf '<absent>')" "$_qfrwas"

