# A `when` that answers neither yes nor no is unknown, as in a probe.
#
# felix_commission_state read every status of a `when` other than 0, 126 and
# 127 as the grounded state saying no, and skipped the row's step, so a `when`
# that crashed failed open. Probes and obligations already read anything that
# is neither 0 nor 1 as unknown. The status alone could not carry it either:
# the row runs in-process and inherits the CLI's `set -u`, so a `when` naming
# an unset variable ended the shell running it with 1, which is what a real no
# returns, and felix_commission_ask folded every status but 0, 126 and 127 to 1
# before the state saw it. So the ask keeps the status and, asked, says whether
# the text returned it, ended the shell with it, or was never run because the
# checkout could not be entered; a `when` that does not parse is unknown and
# never run; a `when` that ended the shell with 0 still applies. The check
# column was pinned here, anything but 0, 126 and 127 there held, until
# 2026-10-08: a check that exits 2 could not be asked and is unknown, and so
# is one that does not parse, parsed first as a `when` is. Every other
# status still holds, and held fails closed. Everything this touches is
# restored below and everything it defines unset.
_commissioning_build alpha12
cp "$CMP/commissioning.tsv" "$TMP/cmwc-table.keep"
_cmwcrow() { printf '%s\t-\t-\t%s\t-\t%s\t9' "$1" "$2" "$3"; }   # need, when, check
_cmwcst()  { printf '%s\n' "$1" | awk -F'\t' -v n="$2" '$1 == n { print $2 }'; }
_cmwcdt()  { printf '%s\n' "$1" | awk -F'\t' -v n="$2" '$1 == n { print $6 }'; }
# An engine function that ends the shell running it, as the engine's die does.
felix_cmwc_die() { exit 5; }
# The status this bash ends a shell with on an unset variable under set -u,
# measured the way the engine meets it rather than assumed: 1 on bash 3.2.
_cmwcu="$( ( eval '[ -n "$cmwc_never_set_anywhere" ]' ) 2>/dev/null; printf '%s' "$?" )"
# A text that writes what an honest run is read by into its descriptors 1 to
# 9, then ends the shell. Amended after review: the first line was a bare
# `returned`, which no reading accepts, so a run whose own stdout reached the
# answer went unseen. fd 10 stays out: that is bash's saved copy of the
# answer's pipe, and a text writing there can forge it, which nothing that runs
# in its process can prevent.
_cmwcfake="for _cmwcd in 1 2 3 4 5 6 7 8 9; do printf 'returned 0\nreturned 1\n' >&\"\$_cmwcd\"; done; exit 1"
_cmtable "$(_cmwcrow cmwc_unset     '[ -n "$cmwc_never_set_anywhere" ]' true)" \
         "$(_cmwcrow cmwc_colon     ': "${cmwc_never_set_anywhere:?}"' true)" \
         "$(_cmwcrow cmwc_infn      '_cmwc_inner() { [ -n "$cmwc_never_set_anywhere" ]; }; _cmwc_inner' true)" \
         "$(_cmwcrow cmwc_die       'felix_cmwc_die' true)" \
         "$(_cmwcrow cmwc_exit1     'exit 1' true)" \
         "$(_cmwcrow cmwc_exit3     'exit 3' true)" \
         "$(_cmwcrow cmwc_exit127   'exit 127' true)" \
         "$(_cmwcrow cmwc_exec      'exec false' true)" \
         "$(_cmwcrow cmwc_exit0     'exit 0' true)" \
         "$(_cmwcrow cmwc_exit0_no  'exit 0' 'test -f cmwc-no-such-file')" \
         "$(_cmwcrow cmwc_two       'grep -q x cmwc-no-such-file' true)" \
         "$(_cmwcrow cmwc_three     "sh -c 'exit 3'" true)" \
         "$(_cmwcrow cmwc_r126      "sh -c 'exit 126'" true)" \
         "$(_cmwcrow cmwc_r130      "sh -c 'exit 130'" true)" \
         "$(_cmwcrow cmwc_no        'test -f cmwc-no-such-file' true)" \
         "$(_cmwcrow cmwc_no_grep   'grep -q cmwcnope src/a.txt' true)" \
         "$(_cmwcrow cmwc_yes       'test -f src/a.txt' true)" \
         "$(_cmwcrow cmwc_yes_no    'test -f src/a.txt' 'test -f cmwc-no-such-file')" \
         "$(_cmwcrow cmwc_missing   'cmwc-no-such-command-xyz' true)" \
         "$(_cmwcrow cmwc_parse     'touch cmwc-parse-ran; if then' true)" \
         "$(_cmwcrow cmwc_parse2    'case x in' true)" \
         "$(_cmwcrow cmwc_fake      "$_cmwcfake" true)" \
         "cmwc_grounds	billing	-	sh -c 'exit 3'	-	true	9" \
         "cmwc_instr	-	cmwc-no-such-instrument-xyz	sh -c 'exit 3'	-	true	9" \
         "$(_cmwcrow cmwc_efn       'test -f cmwc-no-such-file' '[ -z "$(felix_cmwc_no_such_function)" ]')" \
         "$(_cmwcrow cmwc_c_unset   - 'test -n "$cmwc_never_set_anywhere"')" \
         "$(_cmwcrow cmwc_c_two     - 'grep -q x cmwc-no-such-file')" \
         "$(_cmwcrow cmwc_c_exit3   - 'exit 3')" \
         "$(_cmwcrow cmwc_c_die     - 'felix_cmwc_die')" \
         "$(_cmwcrow cmwc_c_parse   - 'if then')" \
         "$(_cmwcrow cmwc_c_fake    - "$_cmwcfake")" \
         "$(_cmwcrow cmwc_c_missing - 'cmwc-no-such-command-xyz')"
rm -f "$CMR/cmwc-parse-ran"
_cmwcrun="$(_cm felix_commission_run "$CMP" "$CMR" -)"

is  "the when-status rows are read as rows, none of them malformed" \
    "$(_cm felix_commission_malformed "$CMP")" ""
is  "the shell this suite runs ends on an unset variable with a status that is not 0" \
    "$([ -n "$_cmwcu" ] && [ "$_cmwcu" != 0 ] && printf measured)" "measured"

is  "a when naming an unset variable is unknown, not not-applicable" "$(_cmwcst "$_cmwcrun" cmwc_unset)" "unknown"
has "and it says the when ended the shell, with the status it ended with" \
    "$(_cmwcdt "$_cmwcrun" cmwc_unset)" "the \`when\` test ended the shell with status $_cmwcu before it answered"
has "and it names an unset variable under set -u as a cause" "$(_cmwcdt "$_cmwcrun" cmwc_unset)" "set -u"
is  "a when whose \${x:?} fails is unknown"                           "$(_cmwcst "$_cmwcrun" cmwc_colon)" "unknown"
is  "a when whose own function reads an unset variable is unknown"    "$(_cmwcst "$_cmwcrun" cmwc_infn)"  "unknown"
is  "a when whose engine function ends the shell is unknown"          "$(_cmwcst "$_cmwcrun" cmwc_die)"   "unknown"
has "and it says the shell ended with that function's status" \
    "$(_cmwcdt "$_cmwcrun" cmwc_die)" "ended the shell with status 5"
is  "a when written as exit 1 is unknown, because bash's own fatal errors end the shell with 1" \
    "$(_cmwcst "$_cmwcrun" cmwc_exit1)" "unknown"
has "and it says the shell ended with status 1" "$(_cmwcdt "$_cmwcrun" cmwc_exit1)" "ended the shell with status 1"
is  "a when that exits 3 is unknown"                                  "$(_cmwcst "$_cmwcrun" cmwc_exit3)" "unknown"
has "and it says the shell ended with status 3" "$(_cmwcdt "$_cmwcrun" cmwc_exit3)" "ended the shell with status 3"
is  "a when that exits 127 is unknown"                                "$(_cmwcst "$_cmwcrun" cmwc_exit127)" "unknown"
has "and it says the shell ended, not that a command is missing" \
    "$(_cmwcdt "$_cmwcrun" cmwc_exit127)" "ended the shell with status 127"
is  "a when that replaces its shell with false is unknown"            "$(_cmwcst "$_cmwcrun" cmwc_exec)"  "unknown"
is  "a when that exits 0 applies, and a check that passes makes it done" "$(_cmwcst "$_cmwcrun" cmwc_exit0)" "done"
is  "and a when that exits 0 leaves a check that fails to hold it"    "$(_cmwcst "$_cmwcrun" cmwc_exit0_no)" "held"

is  "a when that returns 2 is unknown"                                "$(_cmwcst "$_cmwcrun" cmwc_two)"   "unknown"
has "and it names the 2 and says it is neither yes nor no" \
    "$(_cmwcdt "$_cmwcrun" cmwc_two)" "the \`when\` test exited 2, which is neither yes nor no"
is  "a when that returns 3 is unknown"                                "$(_cmwcst "$_cmwcrun" cmwc_three)" "unknown"
has "and it names the 3 and says it is neither yes nor no" \
    "$(_cmwcdt "$_cmwcrun" cmwc_three)" "the \`when\` test exited 3, which is neither yes nor no"
is  "a when that returns 126 is unknown"                              "$(_cmwcst "$_cmwcrun" cmwc_r126)"  "unknown"
has "and it names the 126 as the when's own, not a checkout that could not be entered" \
    "$(_cmwcdt "$_cmwcrun" cmwc_r126)" "the \`when\` test exited 126, which is neither yes nor no"
is  "a when that returns 130 is unknown"                              "$(_cmwcst "$_cmwcrun" cmwc_r130)"  "unknown"
has "and it names the 130"  "$(_cmwcdt "$_cmwcrun" cmwc_r130)" "the \`when\` test exited 130"
is  "a when whose test returns 1 is still not-applicable"             "$(_cmwcst "$_cmwcrun" cmwc_no)"    "not-applicable"
has "and still says the when test says it does not apply" \
    "$(_cmwcdt "$_cmwcrun" cmwc_no)" "the \`when\` test says this does not apply here"
is  "a when whose grep -q finds nothing is still not-applicable"      "$(_cmwcst "$_cmwcrun" cmwc_no_grep)" "not-applicable"
is  "a when whose test returns 0 applies, and the check decides done" "$(_cmwcst "$_cmwcrun" cmwc_yes)"   "done"
is  "and a when whose test returns 0 leaves a failing check held"     "$(_cmwcst "$_cmwcrun" cmwc_yes_no)" "held"
is  "a when naming a command that is not here is still unknown"       "$(_cmwcst "$_cmwcrun" cmwc_missing)" "unknown"
has "and still says a command in it does not exist here" \
    "$(_cmwcdt "$_cmwcrun" cmwc_missing)" "a command in the \`when\` test does not exist here"
_cmwcgone="$(_cm felix_commission_run "$CMP" "$TMP/cmwc-no-such-dir" -)"
is  "a when over a checkout that cannot be entered is still unknown"  "$(_cmwcst "$_cmwcgone" cmwc_yes)" "unknown"
has "and still says the checkout could not be entered" \
    "$(_cmwcdt "$_cmwcgone" cmwc_yes)" "the checkout could not be entered"

is  "a when that does not parse is unknown"                           "$(_cmwcst "$_cmwcrun" cmwc_parse)" "unknown"
has "and it says the when does not parse"                             "$(_cmwcdt "$_cmwcrun" cmwc_parse)" "does not parse"
# Amended after review: a table cell is one line, and eval parses a whole line
# before it runs any of it, so through the table nothing ran with or without
# the parse check. A text of two lines, asked directly, would have run.
_cmwcpr="$(_cm felix_commission_state "$CMP" "$CMR" cmwc_parse_nl - - "$(printf 'touch cmwc-parse-ran\nif then')" - true | cut -f1)"
is  "and no part of a when that does not parse was run" \
    "$_cmwcpr $([ -e "$CMR/cmwc-parse-ran" ] && printf ran || printf 'not run')" "unknown not run"
is  "an unterminated case in a when is unknown"                       "$(_cmwcst "$_cmwcrun" cmwc_parse2)" "unknown"
has "and it too says the when does not parse"                         "$(_cmwcdt "$_cmwcrun" cmwc_parse2)" "does not parse"
is  "a when that writes returned to its descriptors 1 to 9 and then exits 1 is still unknown" \
    "$(_cmwcst "$_cmwcrun" cmwc_fake)" "unknown"

is  "an inactive capability still makes a row not-applicable before its when is read" \
    "$(_cmwcst "$_cmwcrun" cmwc_grounds)" "not-applicable"
has "an absent instrument is still asked before the when, and says so" \
    "$(_cmwcdt "$_cmwcrun" cmwc_instr)" "could not be asked on this machine"
# Amended after review: this row's when says no, so reading it first would
# make the row not-applicable, and only the order makes it unknown.
is  "a check's missing engine function is still found before the when is read" \
    "$(_cmwcst "$_cmwcrun" cmwc_efn)" "unknown"
has "and the missing function is named, not the when's status" \
    "$(_cmwcdt "$_cmwcrun" cmwc_efn)" "felix_cmwc_no_such_function"

is  "a check that ends the shell on an unset variable is held, as before" "$(_cmwcst "$_cmwcrun" cmwc_c_unset)" "held"
is  "a check that returns 2 could not be asked, and is unknown"        "$(_cmwcst "$_cmwcrun" cmwc_c_two)"    "unknown"
is  "a check that exits 3 is held, as before"                         "$(_cmwcst "$_cmwcrun" cmwc_c_exit3)"  "held"
is  "a check whose engine function ends the shell is held"            "$(_cmwcst "$_cmwcrun" cmwc_c_die)"    "held"
is  "a check that does not parse is unknown, on bash 3.2 as on 5"    "$(_cmwcst "$_cmwcrun" cmwc_c_parse)"  "unknown"
is  "a check that writes returned to its descriptors 1 to 9 and exits 1 is held" "$(_cmwcst "$_cmwcrun" cmwc_c_fake)" "held"
is  "a check naming a command that is not here is unknown, as before" "$(_cmwcst "$_cmwcrun" cmwc_c_missing)" "unknown"
has "and it says a command in the check does not exist here" \
    "$(_cmwcdt "$_cmwcrun" cmwc_c_missing)" "a command in the check does not exist here"

# The ask itself, called as the engine calls it.
_cmwcask()  { felix_commission_ask "$@"; printf '%s\n' "$?"; }
_cmwcaskv() { local _cmwch=kept; felix_commission_ask "$1" "$2" _cmwch; printf '%s %s\n' "$?" "$_cmwch"; }
is  "felix_commission_ask returns a text's 2 as 2, not folded to 1" \
    "$(_cm _cmwcask "$CMR" 'grep -q x cmwc-no-such-file')" "2"
is  "and returns a text's 3 as 3"          "$(_cm _cmwcask "$CMR" "sh -c 'exit 3'")" "3"
is  "and returns a text's own exit 4 as 4" "$(_cm _cmwcask "$CMR" 'exit 4')"        "4"
is  "and still returns a no as 1"          "$(_cm _cmwcask "$CMR" 'false')"         "1"
is  "and still returns a yes as 0"         "$(_cm _cmwcask "$CMR" 'true')"          "0"
is  "and still returns 126 for a checkout it cannot enter" \
    "$(_cm _cmwcask "$TMP/cmwc-no-such-dir" 'true')" "126"
is  "an ask told a variable name sets it to returned when the text came back with 3" \
    "$(_cm _cmwcaskv "$CMR" "sh -c 'exit 3'")" "3 returned"
is  "and to returned for a no"             "$(_cm _cmwcaskv "$CMR" 'false')"        "1 returned"
is  "and to returned for a yes"            "$(_cm _cmwcaskv "$CMR" 'true')"         "0 returned"
is  "and to returned for a missing command, with 127" \
    "$(_cm _cmwcaskv "$CMR" 'cmwc-no-such-command-xyz')" "127 returned"
is  "and to returned for a text that itself returned 126" \
    "$(_cm _cmwcaskv "$CMR" "sh -c 'exit 126'")" "126 returned"
is  "and to ended when the text exits 4, with 4" "$(_cm _cmwcaskv "$CMR" 'exit 4')" "4 ended"
is  "and to ended when the text exits 0, with 0" "$(_cm _cmwcaskv "$CMR" 'exit 0')" "0 ended"
is  "and to ended when an unset variable ends the shell, with its status" \
    "$(_cm _cmwcaskv "$CMR" '[ -n "$cmwc_never_set_anywhere" ]')" "$_cmwcu ended"
is  "and to ended when an engine function the text names ends the shell" \
    "$(_cm _cmwcaskv "$CMR" 'felix_cmwc_die')" "5 ended"
is  "and to ended when the text wrote returned to its descriptors 1 to 9 before exiting 1" \
    "$(_cm _cmwcaskv "$CMR" "$_cmwcfake")" "1 ended"
is  "and to unentered, with 126, when the checkout cannot be entered" \
    "$(_cm _cmwcaskv "$TMP/cmwc-no-such-dir" 'true')" "126 unentered"
is  "an ask with no variable name prints nothing on stdout" \
    "$(_cm felix_commission_ask "$CMR" "echo cmwc-said; sh -c 'exit 3'")" ""
is  "and an ask with one prints nothing on stdout either" \
    "$(_cm felix_commission_ask "$CMR" 'echo cmwc-said; exit 4' _cmwcw)" ""
# Whatever the caller calls its variable, that one is set and no other moves,
# including names an ask might use for its own.
_cmwcnamed() { local rc st out how var root text word ended status _cmwcn _cmwcm _cmwcr=''
  for _cmwcn in rc st out how var root text word ended status; do
    for _cmwcm in rc st out how var root text word ended status; do eval "$_cmwcm=kept"; done
    felix_commission_ask "$CMR" 'false' "$_cmwcn"
    for _cmwcm in rc st out how var root text word ended status; do
      [ "$_cmwcm" = "$_cmwcn" ] || [ "${!_cmwcm}" = kept ] || _cmwcr="$_cmwcr $_cmwcm-moved-by-$_cmwcn"
    done
    _cmwcr="$_cmwcr $_cmwcn=${!_cmwcn}"
  done
  printf '%s\n' "$_cmwcr"; }
_cmwcnm="$(_cm _cmwcnamed)"
is  "the variable an ask is told to set is set, whatever the caller named it" \
    "$(printf '%s\n' "$_cmwcnm" | tr ' ' '\n' | grep '=' | tr '\n' ' ')" \
    "rc=returned st=returned out=returned how=returned var=returned root=returned text=returned word=returned ended=returned status=returned "
is  "and no other variable of the caller's moves" \
    "$(printf '%s\n' "$_cmwcnm" | tr ' ' '\n' | grep -c 'moved')" "0"
_cmwckept() { local _cmwcb _cmwcw; _cmwcb="$(set +o)"
              felix_commission_ask "$CMR" 'exit 1' _cmwcw
              felix_commission_ask "$CMR" '[ -n "$cmwc_never_set_anywhere" ]'
              felix_commission_ask "$CMR" "$_cmwcfake" _cmwcw
              felix_commission_ask "$TMP/cmwc-no-such-dir" 'true' _cmwcw
              if [ "$(set +o)" = "$_cmwcb" ]; then printf 'kept\n'; else printf 'moved\n'; fi; }
is  "an ask whose text ended the shell leaves every option of the caller as it was" "$(_cm _cmwckept)" "kept"

# And through the real command, whose own shell is `set -uo pipefail` and a
# script file, which is where an unset variable ends a shell with 1.
_cmtable "$(_cmwcrow cmwc_cli_unset '[ -n "$cmwc_never_set_anywhere" ]' true)" \
         "$(_cmwcrow cmwc_cli_no    'test -f cmwc-no-such-file' true)"
_cmwccli="$( cd "$CMR" && PATH="$CMSTUB:$PATH" "$FELIX" commission --status 2>&1 )"
is  "felix commission --status reads a when naming an unset variable unknown" \
    "$(printf '%s\n' "$_cmwccli" | awk '$2 == "cmwc_cli_unset" { print $1 }')" "unknown"
is  "and still reads a when whose test says no not-applicable" \
    "$(printf '%s\n' "$_cmwccli" | awk '$2 == "cmwc_cli_no" { print $1 }')" "not-applicable"

cp "$TMP/cmwc-table.keep" "$CMP/commissioning.tsv"
rm -f "$TMP/cmwc-table.keep" "$CMR/cmwc-parse-ran"
unset -f _cmwcrow _cmwcst _cmwcdt _cmwcask _cmwcaskv _cmwcnamed _cmwckept felix_cmwc_die
unset _cmwcu _cmwcfake _cmwcrun _cmwcgone _cmwcnm _cmwccli _cmwcpr

# Added with the fix, and after review, not blind: parts of it that mutations
# showed nothing above could fail.
#   - What a `when` prints goes nowhere, so the state reads neither it as the
#     answer nor noise in place of one.
#   - The answer is read without waiting for a job the `when` left running.
#     bash marks the copy of stdout it saves around the eval close-on-exec, so
#     a program such as `sleep 30 &` never holds it; a job that is itself a
#     forked shell does, and a reader waiting for end of file waits for it.
#     The job below reaps its own sleep when it is stopped.
#   - A `when` reads nothing from its caller's stdin, which in a run is the
#     table: one that read it would eat the rows after it.
#   - Its stderr goes nowhere, an ask that is given no variable sets none, a
#     garbled answer line is unknown, and a checkout that cannot be entered is
#     unknown even for a row no check follows.
cp "$CMP/commissioning.tsv" "$TMP/cmwcx-table.keep"
rm -f "$TMP/cmwcx-bg.pid"
_cmwcxbg="( trap 'kill \"\$!\" 2>/dev/null; exit 0' TERM; sleep 30 & wait ) & printf '%s' \"\$!\" > \"\$TMP/cmwcx-bg.pid\"; true"
_cmtable "$(printf 'cmwcx_print\t-\t-\t%s\t-\ttrue\t9' 'echo cmwcx-noise; test -f src/a.txt')" \
         "$(printf 'cmwcx_forge\t-\t-\t%s\t-\ttrue\t9' "echo 'returned 0'; false")" \
         "$(printf 'cmwcx_bg\t-\t-\t%s\t-\ttrue\t9' "$_cmwcxbg")" \
         "$(printf 'cmwcx_eat\t-\t-\t%s\t-\ttrue\t9' 'cat >/dev/null; true')" \
         "$(printf 'cmwcx_after\t-\t-\t-\t-\ttrue\t9')"
_cmwcxrun="$(_cm felix_commission_run "$CMP" "$CMR" -)"
_cmwcxpid="$(cat "$TMP/cmwcx-bg.pid" 2>/dev/null)"
_cmwcxalive='no pid'
case "$_cmwcxpid" in
  ''|*[!0-9]*) ;;
  *) if kill -0 "$_cmwcxpid" 2>/dev/null; then _cmwcxalive=running; kill "$_cmwcxpid" 2>/dev/null
     else _cmwcxalive=gone; fi ;;
esac
_cmwcxst() { printf '%s\n' "$_cmwcxrun" | awk -F'\t' -v n="$1" '$1 == n { print $2 }'; }
is  "a when that prints and then says yes applies, and the check decides done" "$(_cmwcxst cmwcx_print)" "done"
is  "a when that prints returned 0 and then says no is not-applicable"         "$(_cmwcxst cmwcx_forge)" "not-applicable"
is  "a when that leaves a forked shell running applies, and the check decides done" "$(_cmwcxst cmwcx_bg)" "done"
is  "and its answer was read while that shell was still running"              "$_cmwcxalive" "running"
is  "a when that reads its stdin applies, and the check decides done"          "$(_cmwcxst cmwcx_eat)" "done"
is  "and the row after it is still read"                                       "$(_cmwcxst cmwcx_after)" "done"
_cmwcxaskv() { local _cmwcxh=kept; felix_commission_ask "$1" "$2" _cmwcxh; printf '%s %s\n' "$?" "$_cmwcxh"; }
_cmwcxnone() { local how=kept; felix_commission_ask "$CMR" 'false'; printf '%s %s\n' "$?" "$how"; }
is  "an ask told a variable reads no stdin from its caller" \
    "$(printf 'cmwcx-input\n' | _cm _cmwcxaskv "$CMR" 'read -r _cmwcxin')" "1 returned"
is  "and prints nothing of the text's stderr" \
    "$(_cm _cmwcxaskv "$CMR" 'echo cmwcx-err >&2; exit 4' 2>&1)" "4 ended"
is  "an ask given no variable sets none, even one named how" "$(_cm _cmwcxnone)" "1 kept"
is  "an ask whose answer line comes back garbled says unasked, with 2" \
    "$(_cm _cmwcxaskv "$CMR" 'for _d in 10 11 12 13 14 15 16 17 18 19; do printf x >&$_d; done 2>/dev/null; exit 1')" "2 unasked"
_cmwcxgarble="$(_cm felix_commission_state "$CMP" "$CMR" cmwcx_garble - - 'for _d in 10 11 12 13 14 15 16 17 18 19; do printf x >&$_d; done 2>/dev/null; exit 1' - true)"
is  "and a when whose answer comes back garbled is unknown" "$(printf '%s' "$_cmwcxgarble" | cut -f1)" "unknown"
has "and says its answer could not be read" "$(printf '%s' "$_cmwcxgarble" | cut -f2)" "could not be read"
is  "a when over a checkout that cannot be entered is unknown on a row no check follows" \
    "$(_cm felix_commission_state "$CMP" "$TMP/cmwc-no-such-dir" cmwcx_gone - - true provider:cmwcx-p:cmwcx-s - | cut -f1)" "unknown"
cp "$TMP/cmwcx-table.keep" "$CMP/commissioning.tsv"
rm -f "$TMP/cmwcx-table.keep" "$TMP/cmwcx-bg.pid"
unset -f _cmwcxst _cmwcxaskv _cmwcxnone
unset _cmwcxrun _cmwcxpid _cmwcxalive _cmwcxbg _cmwcxgarble

# A state line that comes back empty is unknown, not a row without a state.
#
# felix_commission_run split the line felix_commission_state printed and took
# its first field as the row's state without asking whether it was one. When
# the state function printed nothing, as it does when a fork inside it fails
# with EAGAIN, the row printed with no state and
# class n/a, felix_commission_counts counted it as nothing, and the receipt
# read commissioned once every other row was done: a row nobody asked
# certified it. A reviewer measured that with ulimit -u 1. Here nothing is
# starved of processes. Inside _cm the state function is replaced by one that
# prints nothing for one need and hands every other row to the real function,
# copied under a name of its own. A first field that is any other word is
# unknown too, and so is the line read again after a felix: answer ran. These
# assertions were written blind, from the contract, before the fix.
# Everything this touches is restored below and everything it defines unset.
# Added after review, not blind: what the block found, so its end can assert
# it left the table, the receipt and every cmes- file as they were.
_cmesfixture() { printf '%s | %s | %s\n' "$(cksum < "$CMP/commissioning.tsv")" \
                   "$(if [ -f "$FROOT/state/commission/cmproj" ]; then cksum < "$FROOT/state/commission/cmproj"; else printf 'no receipt'; fi)" \
                   "$(ls -a "$CMR" "$TMP" | grep -c '^cmes-')"; }
_cmesfound="$(_cmesfixture)"
cp "$CMP/commissioning.tsv" "$TMP/cmes-table.keep"
_cmesrc="$FROOT/state/commission/cmproj"
rm -f "$TMP/cmes-receipt.keep"; [ -f "$_cmesrc" ] && cp "$_cmesrc" "$TMP/cmes-receipt.keep"
rm -f "$CMR/cmes-answered"
# $1 names what the one line becomes and $2 is the runner. The state function
# runs inside $(...) and keeps nothing between calls, so the re-read is told
# from the first read by the file the runner leaves.
_cmesrun() { local _cmesmode="$1" _cmesdef
  _cmesdef="$(declare -f felix_commission_state)"
  eval "_cmes_real_state${_cmesdef#felix_commission_state}"
  felix_commission_state() {
    case "$_cmesmode:${3:-}" in
      empty:cmes_gap)    return 0 ;;
      word:cmes_gap)     printf 'finished\tcmes a word that is no state\t-\n'; return 0 ;;
      second:cmes_again) [ -e "$CMR/cmes-answered" ] && return 0 ;;
    esac
    _cmes_real_state "$@"; }
  felix_commission_run "$CMP" "$CMR" "$2"; }
_cmes_answer() { touch "$CMR/cmes-answered"; return 0; }
_cmesf()    { printf '%s\n' "$1" | awk -F'\t' -v n="$2" -v f="$3" '$1 == n { print $f }'; }
_cmesline() { printf '%s\n' "$1" | awk -F'\t' -v n="$2" '$1 == n'; }
_cmessaid() { case "$1" in *'could not be computed'*) printf 'said\n' ;; *) printf 'silent\n' ;; esac; }
_cmtable "$(printf 'cmes_done\t-\t-\t-\t-\ttest -f src/a.txt\t9')" \
         "$(printf 'cmes_gap\t-\t-\t-\t-\ttrue\t9')" \
         "$(printf 'cmes_after\t-\t-\t-\t-\ttest -f src/a.txt\t9')"
_cmesnone="$(_cm _cmesrun none -)"
_cmesempty="$(_cm _cmesrun empty -)"
_cmesword="$(_cm _cmesrun word -)"

is  "with the state function replaced and every line it gives well formed, both rows are done and the receipt is commissioned" \
    "$(_cmesf "$_cmesnone" cmes_done 2) $(_cmesf "$_cmesnone" cmes_gap 2) $(_cm felix_commission_receipt_write "$FROOT" "$CMP" "$CMR" "$_cmesnone" "")" \
    "done done commissioned"
is  "a state line that comes back empty makes its row unknown" "$(_cmesf "$_cmesempty" cmes_gap 2)" "unknown"
is  "and its class is UNKNOWN, not n/a"                         "$(_cmesf "$_cmesempty" cmes_gap 3)" "UNKNOWN"
has "and it says the row's state could not be computed"        "$(_cmesf "$_cmesempty" cmes_gap 6)" "could not be computed"
is  "and the row beside it, whose line is well formed, reads as it does with no line empty" \
    "$(_cmesline "$_cmesempty" cmes_done)" "$(_cmesline "$_cmesnone" cmes_done)"
# Added after review, not blind: a row after the bad one too, since what goes
# wrong reading one row can reach the rows that follow it.
is  "and the row after an empty or unreadable state line is still read, and done" \
    "$(_cmesf "$_cmesempty" cmes_after 2) $(_cmesf "$_cmesword" cmes_after 2)" "done done"
is  "and the receipt over those rows, every other row done, is indeterminate and not commissioned" \
    "$(_cm felix_commission_receipt_write "$FROOT" "$CMP" "$CMR" "$_cmesempty" "")" "indeterminate"
is  "a state line whose first field is none of the eight states makes its row unknown, and says it could not be computed" \
    "$(_cmesf "$_cmesword" cmes_gap 2) $(_cmesf "$_cmesword" cmes_gap 3) $(_cmessaid "$(_cmesf "$_cmesword" cmes_gap 6)")" \
    "unknown UNKNOWN said"

# The re-read: the first line says held, the runner answers, and the line read
# after it comes back empty.
_cmtable "$(printf 'cmes_again\t-\t-\t-\tfelix:toolbox --route\ttest -f cmes-answered\t5')"
_cmesagain="$(_cm _cmesrun second _cmes_answer)"
# Amended after review: that the answer ran is part of what the name claims,
# and without it a first read gone unknown passed here too.
_cmesran="$([ -e "$CMR/cmes-answered" ] && printf ran || printf 'not run')"
rm -f "$CMR/cmes-answered"
is  "a state line that comes back empty on the re-read after a felix answer ran makes the row unknown" \
    "$(_cmesf "$_cmesagain" cmes_again 2) $(_cmesf "$_cmesagain" cmes_again 3) $_cmesran" "unknown UNKNOWN ran"
_cmesdt="$(_cmesf "$_cmesagain" cmes_again 6)"
case "$_cmesdt" in
  'ran toolbox --route (exit 0); '*'could not be computed'*)
     ok  "and it says what ran, then that the row's state could not be computed" ;;
  *) bad "and it says what ran, then that the row's state could not be computed" "got [$_cmesdt]" ;;
esac

# Added after review, not blind. The read of a state line is syntax, not a
# function, so it cannot be stubbed. A here-document that cannot be made means
# the read never runs, and on bash 3.2, where a here-document is a temporary
# file, the reviewer measured that leaving the row before's `done` in place on
# a row whose check fails. The one function the run's own shell calls between
# one read and the next is the check on the state it read, so the first call
# to it sets a file size limit of 0 there, for the rest of that loop and
# nothing else. Where a here-document this small is a pipe (bash 5.1 and
# later) nothing fails, and this says so rather than passing.
_cmeshdrun() { local _cmeshddef _cmeshdn=0
  _cmeshddef="$(declare -f _felix_commission_state_known)"
  [ -n "$_cmeshddef" ] && eval "_cmes_real_known${_cmeshddef#_felix_commission_state_known}"
  _felix_commission_state_known() {
    _cmeshdn=$((_cmeshdn + 1))
    if [ "$_cmeshdn" -eq 1 ]; then
      trap '' XFSZ; ulimit -f 0
      read -r _cmeshdx <<CMESHD 2>/dev/null || : > "$TMP/cmes-hd-failed"
probe
CMESHD
    fi
    _cmes_real_known "$@"; }
  felix_commission_run "$CMP" "$CMR" - 2>/dev/null; }
rm -f "$TMP/cmes-hd-failed"
_cmtable "$(printf 'cmes_hd_done\t-\t-\t-\t-\ttest -f src/a.txt\t9')" \
         "$(printf 'cmes_hd_held\t-\t-\t-\t-\ttest -f cmes-no-such-file\t9')"
_cmeshd="$(_cm _cmeshdrun)"
if [ -e "$TMP/cmes-hd-failed" ]; then
  is  "a row whose state line was never read is unknown, not the state of the row before it" \
      "$(_cmesf "$_cmeshd" cmes_hd_done 2) $(_cmesf "$_cmeshd" cmes_hd_held 2)" "done unknown"
else
  skip "a row whose state line was never read is unknown, not the state of the row before it" \
       "no here-document failed in the run's loop on bash $BASH_VERSION: a pipe there, or no check called between reads"
fi

cp "$TMP/cmes-table.keep" "$CMP/commissioning.tsv"
if [ -f "$TMP/cmes-receipt.keep" ]; then mv "$TMP/cmes-receipt.keep" "$_cmesrc"; else rm -f "$_cmesrc"; fi
rm -f "$TMP/cmes-table.keep" "$CMR/cmes-answered" "$TMP/cmes-hd-failed"
is  "and this block leaves the table, the receipt and every cmes- file as it found them" \
    "$(_cmesfixture)" "$_cmesfound"
unset -f _cmesrun _cmes_answer _cmesf _cmesline _cmessaid _cmesfixture _cmeshdrun
unset _cmesrc _cmesnone _cmesempty _cmesword _cmesagain _cmesdt _cmesran _cmeshd _cmesfound
