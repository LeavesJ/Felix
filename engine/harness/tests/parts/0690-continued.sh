# The rule the blind section above was amended to, and what review found. A
# text is refused only when it cannot fail and a final filter is why, so a
# guard that can fail admits it, and a constant run on a hidden status
# decides nothing. A bare exit returns the status before it; set -e anywhere
# counts from the start; `! !` is a bash 3.2 syntax error; tr and uniq with an
# operand count they refuse fail every time. Written by the implementer, not
# blind, after the rule changed.
#
# The second review's findings follow FFAUTHOR's first block, each admitted
# case measured on macOS 26.3.1 under /bin/bash 3.2, and each with a refused
# partner where one shows the rule still bites: an exit in a for or case
# whose words ran a command returns their status; exec ends the script; kill
# can; quotes and expansions cannot hide pipefail; hash, shopt and PATH can
# change what a name runs; a redirect reading any fd, closing one or
# duplicating fd 3 or above can fail; bash-4 redirects bash 3.2 misreads;
# usage errors on either platform; and nounset, which commissioning runs
# under, ending a text at an unset name.
#
# The verification pass found the same classes under other spellings, and
# commands before the last that end the shell: ${y:?}, arithmetic, [[ ]],
# readonly, a kill from any process. The rows after `HOME is always set` take
# one spelling per class, each admitted one measured failing under /bin/bash
# 3.2 but the two GNU-only refusals, and red against the classifier before
# that fix; the refused rows beside them are what still bites.
# A second verification pass found read-only names, POSIX mode in sh,
# quoted builtin names, nice values, awk arrays and syntax, and killpg; its
# rows follow the fuzzing find, each admitted one red against the classifier
# before that fix.
_ffa() {   # text -> "<exit>|<what it printed>"
  local _o _r
  _o="$( . "$REAL_HARNESS/lib/final-filter.sh" 2>/dev/null || exit 3
         felix_final_filter "$1" </dev/null 2>/dev/null )"; _r=$?
  printf '%s|%s' "$_r" "$_o"
}
while IFS= read -r _ffl; do
  case "$_ffl" in ''|'#'*) continue ;; esac
  _ffstage="${_ffl%%@@*}"; _ffl="${_ffl#*@@}"; _fftx="${_ffl%%@@*}"; _ffwhy="${_ffl#*@@}"
  if [ "$_ffstage" = "-" ]; then
    is "the classifier admits [$_fftx]: $_ffwhy" "$(_ffa "$_fftx")" "1|"
  else
    is "the classifier refuses [$_fftx] and names $_ffstage: $_ffwhy" "$(_ffa "$_fftx")" "0|$_ffstage"
  fi
done <<'FFAUTHOR'
tail@@x | tail && echo ok@@a constant run on tail's status decides nothing
tail@@x | tail && exit 0 || exit 1@@nor does an exit whose code is fixed
tail@@if ! x | tail; then exit 1; fi@@the then branch never runs
tail@@if x | tail; then echo ok; else exit 1; fi@@nor does the else branch
tail@@x | tail; exit@@a bare exit returns tail's status
tail@@test -f a || x | tail@@either way it ends in success
tail@@set -e; npm test | tail -5@@set -e does not reach a pipeline's first stage
the last stage@@x | { tail; }@@a group ending in a filter is one too
-@@cd dir && npm test 2>&1 | tail -20@@the cd can fail, so the text can
-@@command -v jq >/dev/null && jq --version | cut -d- -f2@@it fails when jq is absent
-@@out=$(npm test 2>&1) && printf '%s\n' "$out" | tail -20@@it fails when the tests do
-@@set -e; npm ci; npm test 2>&1 | tail -5@@npm ci can end the script
-@@if grep -q ok log; then :; else exit; fi; x | tail@@a bare exit in an else returns the failure
-@@a || { exit; }; x | tail@@and so does one after ||
-@@d | tail -1 && for i in 1 2; do d; set -e || a; done@@set -e in a loop ends its second pass
-@@( set -e; false; true ) && exit 1 || x | tail@@bash ignores set -e in a subshell left of &&, so exit 1 runs
-@@set -e & ( false; true ) && exit 1 || x | tail@@set -e in a background job leaves this shell's subshell to go on
-@@! ! x | tail@@bash 3.2 rejects a doubled !
-@@x | tr a@@tr with one set and no -d or -s fails every time
tr@@x | tr -d a@@tr -d takes one set
-@@x | uniq in.txt@@uniq reading a file
uniq@@x | uniq - out.txt@@uniq reading standard input into a file
-@@. ./strict.sh; x | tail@@a sourced file can set anything
-@@x | ./bin/sort@@a relative path is the project's own script
-@@x | tail; case $(exit 3) in *) exit;; esac@@an exit in a case returns its word's status, here 3
-@@x | tail; for i in $(exit 3) a; do exit; done@@and in a for, its words' status
tail@@x | tail; for i in a; do exit; done@@with literal words it returns tail's
-@@exec false || x | tail@@exec ends the script with false's status
-@@x | tail && exec :@@exec cannot run a builtin, and the shell ends there with 127
tail@@true || exec false; x | tail@@an exec that never runs ends nothing
-@@kill $$ || x | tail@@kill can end the script by a signal
-@@set -o pipe""fail; false | tail@@quotes cannot hide pipefail
-@@set -o "$o"; x | tail@@nor can an expansion
tail@@set -o noglob; x | tail@@a literal option name is still read
-@@hash -p /usr/bin/false tail; x | tail@@hash can point tail anywhere
-@@shopt -s lastpipe; x | tail@@shopt is not read
-@@PATH=./bin:$PATH; x | tail@@PATH can make tail a project script
-@@x | env PATH=./bin tail@@and so can env
-@@x | tail 3<in.txt@@a file read on any fd can be missing
-@@x | tail >&-@@tail writing to a closed output fails
-@@x | tail >&3@@fd 3 may not be open
tail@@x | tail -1 2>&1@@a duplicate of fd 1 is open
-@@x | tail {fd}>log.txt@@bash 3.2 reads {fd} as tail's file operand
-@@x &>>log.txt | tail@@bash 3.2 cannot parse &>>
tail@@x &>log.txt | tail@@and reads &>
-@@x | cat $'-\n'@@$'...' escapes are not decoded, and this one is a newline cat rejects
tail@@x | tail $'-5'@@with no escape it is literal
-@@x | head -n 0@@macOS head refuses a count of 0
head@@x | head -n 1@@and takes 1
-@@x | cut -d,@@cut needs one of -b, -c or -f
cut@@x | cut -d, -f1@@cut -d with -f
-@@x | sort -k0@@a sort key starts at field 1
sort@@x | sort -k1,1@@and may
-@@x | cat --number@@macOS cat takes no long option
-@@x | tee >(grep -q y)@@a process substitution can close early, and tee dies of SIGPIPE
tee@@x | tee out.txt@@tee writing a named file
-@@x | awk '{ NF -= 1; print }'@@NF can go negative, exit 2 on macOS for an empty line
awk@@x | awk '{ print NF }'@@reading NF is safe
-@@x | awk 'BEGIN { ARGV[1] = "f" } { print }'@@ARGV can name a file
-@@x | sed y/ab/c/@@y with sets of different lengths is an error
sed@@x | sed y/ab/cd/@@and with equal ones is not
-@@x | sed -n 0p@@GNU sed refuses line 0
sed@@x | sed -n 1p@@line 1 is fine
-@@set -u; x | tail && echo "$U"@@under set -u an unset name ends the script
tail@@x | tail && echo "$U"@@without nounset it expands empty, and the run is constant
tail@@set -u; x | tail && echo "${U:-}"@@a default keeps it set
tail@@set -u; x | tail && echo "$HOME"@@HOME is always set
-@@x | tail; v=$(exit 3) exit@@an exit after an assignment that ran a command returns its status
tail@@x | tail; v=1 exit@@and after one that ran none, tail's
-@@x | tail; { exit; } 2>/dev/null$(exit 3)@@and after a redirect that ran one
-@@x | tail; for ((i=0$(exit 3); i<1; i++)); do exit; done@@arithmetic is not read
-@@o="o pipe"; set -${o}fail; x | tail@@an option built from an expansion may be pipefail
-@@set $'-\x6f' pipe''fail; x | tail@@and so may one spelled with an escape
-@@eval "$(echo exit 3)"; x | tail@@eval of an expansion can exit
-@@$(echo exit) 3; x | tail@@and so can a name that is one
-@@set -''e; false; x | tail@@errexit spelled with quotes
-@@set -''u; : $y; x | tail@@and nounset
-@@set -o pipefial && x | tail@@set fails on an option it does not know
-@@builtin hash -p /usr/bin/false tail; x | tail@@builtin reaches hash
-@@builtin trap 'exit 3' EXIT; x | tail@@and trap
tail@@builtin echo a; x | tail@@and echo, which changes nothing
-@@(kill $$); x | tail@@a kill in a subshell still ends the shell
-@@echo $$ | xargs kill; x | tail@@and through xargs
-@@exec bash -c 'exit 1'; x | tail@@exec of a shell ends with its status
-@@exec >&-; x | tail@@exec with only a redirect closes the output for what follows
-@@export PA''TH=/x; x | tail@@PATH with quotes in it
-@@read PATH <<< /x; x | tail@@or set by read
tail@@export LC_ALL=C; x | tail@@export of another name changes nothing
-@@ulimit -n 3; x | tail@@ulimit can starve what follows
-@@x | stdbuf -oL tail@@macOS has no stdbuf
-@@x | tail >&0@@a duplicate of fd 0 is not an output
-@@x | tail 2>&1-@@moving fd 1 closes it
tail@@x | tail >&2@@a duplicate of fd 2 is open
-@@x | tail 99999>&1@@an fd past the limit
-@@x | cat > >(true)@@a process substitution can close early, and cat dies of SIGPIPE
-@@x | cat - -n@@macOS reads an option after an operand as a file
cat@@x | cat -n -@@and before one, as an option
-@@x | sort -nM@@two orderings at once
sort@@x | sort -k1,1n@@one is fine
-@@x | sed 's/a/b/gg'@@g twice
sed@@x | sed 's/a/b/gp'@@g and p once each
-@@x | awk '{print'@@an unbalanced brace
-@@x | awk -v foo '{print}'@@-v without an assignment
awk@@x | awk -v n=1 '{print}'@@-v with one
-@@x | awk '{print}' NF=-1@@an operand assigning NF
-@@x | head -n 99999999999999999999@@a count past the integer range
head@@x | head -n 999999999@@a large count within it
-@@[[ a b ]]; x | tail@@[[ ]] can be a syntax error, which ends the shell
-@@: ${HOME,,}; x | tail@@bash 3.2 has no case conversion, and ends the shell
-@@: "${y:?}"; x | tail@@${y:?} ends the shell when y is unset
tail@@: "${y:-}"; x | tail@@a default cannot
-@@: $((1/0)); x | tail@@an arithmetic error ends the shell
-@@readonly v=1; v=2; x | tail@@so does assigning a readonly name
-@@x | uniq -cD@@GNU refuses -c with -D
-@@x | sort -dn@@GNU refuses -d with -n
-@@x | tail; ! true & exit@@bash 3.2 leaves status 1 after a negated pipeline sent to the background, found by fuzzing
tail@@! true & x | tail@@and what follows it still decides
-@@UID=$(id -u); x | tail@@UID is read-only, and assigning it ends the shell
-@@sh -c ': > /nonexistent/f; x | tail'@@sh runs in POSIX mode, where a redirect error on : ends the shell
-@@set -o posix; : > /nonexistent/f; x | tail@@and so does set -o posix
-@@x | nice -n abc tail@@nice with a value that is not a number
tail@@x | nice -n 5 tail@@and with one that is
-@@'set' -e; false; x | tail@@a builtin named with quotes
-@@x | awk '{ x = 1; x[1] = 2 }'@@a scalar used as an array fails at the first line read
awk@@x | awk '{ c[$1]++ } END { for (k in c) print k, c[k] }'@@an array used as one
-@@x | awk 'END { next }'@@next in END
-@@x | awk '{print 1 +}'@@an operator with nothing after it
-@@python3 -c 'import os; os.killpg(0, 15)'; x | tail@@killpg can signal the shell's own group, not run here
FFAUTHOR

# A carriage return, as the last column of a row saved on Windows carries,
# joins the last word: `tail -1\r` is an offset tail rejects. A text holding
# one is admitted rather than guessed at.
is  "the classifier admits a text holding a carriage return" "$(_ffa "$(printf 'x | tail -1\r')")" "1|"
# Each outcome is kept once. Without that, alternating && and || doubled the
# set at every operator, and thirty of them ran past ten seconds of CPU.
_ffl=""; for _ffstage in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
  _ffl="$_ffl a || true && "; done
is  "the classifier reads thirty alternating || and && inside ten seconds of CPU" \
    "$( ulimit -t 10; _ffa "$_ffl x | tail" )" "0|tail"
# Commissioning evaluates under set -u, so there an unset name can end the
# check, and the row is admitted; a default, or a name the runner exports, is
# not unset, and the row is still refused.
_ffcrow() { printf '%s\t-\t-\t-\t-\t%s\t1' "$1" "$2"; }
is  "a commissioning check that expands an unset name is admitted, since set -u can end it" \
    "$( . "$REAL_HARNESS/lib/final-filter.sh"; _ffcrow nu 'x | tail && echo "$U"' | felix_final_filter_lead commissioning.tsv | cut -f1 )" "-"
has "and one whose name has a default is still refused" \
    "$( . "$REAL_HARNESS/lib/final-filter.sh"; _ffcrow nu 'x | tail && echo "${U:-}"' | felix_final_filter_lead commissioning.tsv | cut -f1 )" "check cannot fail"
has "as is one naming FELIX_PROJECT, which the runner exports" \
    "$( . "$REAL_HARNESS/lib/final-filter.sh"; _ffcrow nu 'x | tail && echo "$FELIX_PROJECT"' | felix_final_filter_lead commissioning.tsv | cut -f1 )" "check cannot fail"
is  "and the same text in a setup check, which runs without set -u, is refused" \
    "$( . "$REAL_HARNESS/lib/final-filter.sh"; printf 'a\tb\tc\t%s\n' 'x | tail && echo "$U"' | felix_final_filter_lead setup.tsv | cut -c1-17 )" "check cannot fail"
unset -f _ffcrow

# The same reading, per table and at the gate. felix_final_filter_table names
# the refused lines of a table by its basename, and schema-check refuses them
# in the tree that holds them, so a setup or maintenance check nothing runs
# yet still stops at the pull request that writes it.
_ffat="$TMP/ff-author"; mkdir -p "$_ffat/engine/harness/templates" "$_ffat/p"
printf '# table\tlives\tcolumns\tempty\nschemas.tsv\ttree\ttable lives columns empty\trefused\nsetup.tsv\ttree\tid title capability check\tallowed\nmaintenance.tsv\ttree\tname cadence capability description check?\tallowed\n' \
  > "$_ffat/engine/harness/templates/schemas.tsv"
printf '# id\ttitle\tcapability\tcheck\nok1\tT\talways\ttest -f x\nbad1\tT\talways\tx | tail -1\n' > "$_ffat/p/setup.tsv"
printf 'm1\t7\talways\td\tx | tail\nm2\t 0\talways\td\tx | tail\n' > "$_ffat/p/maintenance.tsv"
( _fx_cd "$_ffat" && git init -q -b main && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm seed ) >/dev/null 2>&1
is  "felix_final_filter_table names the refused line of a setup table, and why" \
    "$( . "$REAL_HARNESS/lib/final-filter.sh"; felix_final_filter_table "$_ffat/p/setup.tsv" | cut -c1-25 )" \
    "3	check cannot fail: it c"
is  "and reads a maintenance cadence of \" 0\" as the runner does, an event row, and 7 as not one" \
    "$( . "$REAL_HARNESS/lib/final-filter.sh"; felix_final_filter_table "$_ffat/p/maintenance.tsv" | cut -f1 | tr '\n' ' ' )" "2 "
_ffao="$( cd "$_ffat" && "$REAL_HARNESS/bin/schema-check" 2>&1; echo "rc=$?" )"
is  "schema-check fails a tree holding a check that cannot fail" "${_ffao##*rc=}" "1"
has "naming the line and the refusal" "$_ffao" "p/setup.tsv:3	unfailable	check cannot fail"
has "in maintenance too" "$_ffao" "p/maintenance.tsv:2	unfailable"
printf '# id\ttitle\tcapability\tcheck\nok1\tT\talways\ttest -f x\n' > "$_ffat/p/setup.tsv"
printf 'm1\t7\talways\td\tx | tail\n' > "$_ffat/p/maintenance.tsv"
( _fx_cd "$_ffat" && git add -A && git -c user.name=t -c user.email=t@t commit -qm fix ) >/dev/null 2>&1
_ffao="$( cd "$_ffat" && "$REAL_HARNESS/bin/schema-check" 2>&1; echo "rc=$?" )"
is  "and passes once the rows are fixed" "${_ffao##*rc=}" "0"

# A runner that could not judge its table must not run its checks as though
# it had: when the judging pass fails, every row leads with that fact.
is  "felix_final_filter_lead leads every row with the failure when its awk cannot run" \
    "$( . "$REAL_HARNESS/lib/final-filter.sh"; FELIX_FINAL_FILTER_AWK='BEGIN {'
        printf 'a\tb\tc\tx | grep -q y\n' | felix_final_filter_lead setup.tsv | cut -f1 )" \
    "check could not be judged: the final-filter reader failed on setup.tsv"
rm -rf "$_ffat"
unset -f _ffa
unset _ffl _ffstage _fftx _ffwhy _ffat _ffao

# The answer runs in-process through a runner the caller names, and the check
# decides afterwards. The stub stands in for felix:toolbox --route.
_commissioning_build alpha12
_unwritable_probe
_cmstub() { touch "$CMR/src/made-by-answer"; return 0; }
_cmout="$(_cm felix_commission_run "$CMP" "$CMR" _cmstub)"
is  "a held row whose answer ran and whose check now passes is done" \
    "$(printf '%s\n' "$_cmout" | awk -F'\t' '$1 == "beta" { print $2 }')" "done"
has "and the row says what ran"  "$(printf '%s\n' "$_cmout" | awk -F'\t' '$1 == "beta" { print $6 }')" "ran toolbox --route"
rm -f "$CMR/src/made-by-answer"

# The record: nine fields, one row per row, count-verified.
_cm felix_commission_record "$CMP" tree1 policy1 "$_cmout" && ok "the record is written" || bad "the record is written"
is  "one log row per table row"       "$(grep -c . "$MEM/cmproj/commissioning.log")" "8"
is  "nine fields per log row"         "$(head -1 "$MEM/cmproj/commissioning.log" | awk -F'\t' '{ print NF }')" "9"
has "a felix-answered row names felix as the actor"   "$(grep '	beta	' "$MEM/cmproj/commissioning.log")" "	felix	"
has "a provider row is UNKNOWN until its file appears" "$(grep '	prov	' "$MEM/cmproj/commissioning.log")" "	UNKNOWN	"
# An if, not `&& bad || ok`: bad returns 1 when it is given no detail, so that
# shape reported this assertion twice, FAIL and then ok, whenever it failed.
if [ "$_unwritable" -eq 1 ]; then
  chmod 444 "$MEM/cmproj/commissioning.log"
  if _cm felix_commission_record "$CMP" tree1 policy1 "$_cmout" >/dev/null 2>&1; then
    bad "a record that could not be appended is reported" "the record exited 0"
  else
    ok  "a record that could not be appended is reported"
  fi
  chmod 644 "$MEM/cmproj/commissioning.log"
else
  skip "a record that could not be appended is reported" "$_nowrite"
fi

# The receipt: written after the run, valid only by derivation.
_cmres="$(_cm felix_commission_receipt_write "$FROOT" "$CMP" "$CMR" "$_cmout" "$_cmmal")"
is  "unknown or malformed rows make the receipt indeterminate" "$_cmres" "indeterminate"
is  "the receipt has ten fields" "$(awk -F'\t' '{ print NF }' "$FROOT/state/commission/cmproj")" "10"
_cmtable 'alpha	-	-	-	-	test -f src/a.txt	3' \
         'automation_surveyed	-	-	-	provider:claude-code-setup:claude-automation-recommender	-	4'
_cmout="$(_cm felix_commission_run "$CMP" "$CMR" -)"
is  "every check passing, with a provider still awaiting, is commissioned" \
    "$(_cm felix_commission_receipt_write "$FROOT" "$CMP" "$CMR" "$_cmout" "")" "commissioned"
is  "and the receipt reads valid" "$(_cm felix_commission_receipt_valid "$FROOT" "$CMP" "$CMR")" "commissioned"
printf 'api\n' >> "$CMP/capabilities"
has "editing a table in the set makes it stale, with nothing under state/ changing" \
    "$(_cm felix_commission_receipt_valid "$FROOT" "$CMP" "$CMR")" "stale (table set moved"
grep -v '^api$' "$CMP/capabilities" > "$CMP/caps.tmp"; mv "$CMP/caps.tmp" "$CMP/capabilities"
printf '' > "$CMR/main.tf"
has "a surface appearing in the checkout makes it stale the other way" \
    "$(_cm felix_commission_receipt_valid "$FROOT" "$CMP" "$CMR")" "stale (detected surfaces moved"
rm -f "$CMR/main.tf"
is  "and restoring both makes it valid again" "$(_cm felix_commission_receipt_valid "$FROOT" "$CMP" "$CMR")" "commissioned"
printf '\n# one more byte\n' >> "$CMSTUB/claude"
_cmv="$(_cm felix_commission_receipt_valid "$FROOT" "$CMP" "$CMR")"; _cmvrc=$?
is  "the claude cli changing is announced and never invalidates" "$_cmvrc" "0"
has "and the announcement names the change"                     "$_cmv" "changed since"

# A run that reported fewer rows than its table lists, and counts or a receipt
# that are not numbers.
#
# felix_commission_run prints one line per row from a loop in a shell of its
# own, and returns 0 whatever became of that shell. On bash 3.2 a fork that
# fails there, or a pipe it cannot make, ends that shell with status 128: the
# rows after it are never printed, the run still returns 0, and the receipt
# was written over the rows that were. A reviewer measured a table of three
# rows giving one line and a receipt that read commissioned, the held row
# gone. Only the reader of the output can catch that, by asking for every need
# the table lists, once each and in order. Here nothing is starved of
# processes: the check on a row's state, which the loop calls in its own
# shell, is replaced inside _cm by one that ends that shell on the second row,
# as a failed fork does.
#
# The counts are six substitutions read back with one split. When one came
# back empty the split merged the gap and every count after it moved one place
# left; when all of them did, the tests compared empty strings, said so on
# stderr, and fell through to commissioned, and the reader accepted the
# receipt that resulted. Here the counts function is replaced inside _cm by
# one that prints the broken line, a count is made to come back empty by a
# grep that prints nothing for the unknown rows, and a receipt is rewritten in
# place with counts or a result no run writes. For the command, two stubs are
# appended to the fixture's copy of the library for the length of five runs,
# and the copy is put back byte for byte.
# These assertions were written blind, from the contract, before the fix.
# Everything this touches is restored below and everything it defines unset.
_cmrcrc="$FROOT/state/commission/cmproj"
_cmrclib="$FROOT/harness/lib/commission.sh"
_cmrclog="$MEM/cmproj/commissioning.log"
_cmrcfixture() { printf '%s | %s | %s | %s | %s\n' "$(cksum < "$CMP/commissioning.tsv")" \
                   "$(if [ -f "$_cmrcrc" ]; then cksum < "$_cmrcrc"; else printf 'no receipt'; fi)" \
                   "$(cksum < "$_cmrclib")" \
                   "$(if [ -f "$_cmrclog" ]; then cksum < "$_cmrclog"; else printf 'no log'; fi)" \
                   "$(ls -a "$CMR" "$TMP" | grep -c '^cmrc-')"; }
_cmrcfound="$(_cmrcfixture)"
cp "$CMP/commissioning.tsv" "$TMP/cmrc-table.keep"
cp "$_cmrclib" "$TMP/cmrc-lib.keep"
rm -f "$TMP/cmrc-receipt.keep" "$TMP/cmrc-log.keep"
[ -f "$_cmrcrc" ] && cp "$_cmrcrc" "$TMP/cmrc-receipt.keep"
[ -f "$_cmrclog" ] && cp "$_cmrclog" "$TMP/cmrc-log.keep"

# exit code, then what felix_commission_run_complete printed, for an output
# against the table as it stands.
_cmrccomplete() { local _cmrcsaid _cmrcc
  _cmrcsaid="$(felix_commission_run_complete "$CMP" "$1" 2>/dev/null)"; _cmrcc=$?
  printf '%s [%s]' "$_cmrcc" "$_cmrcsaid"; }
_cmrcwrite() { felix_commission_receipt_write "$FROOT" "$CMP" "$CMR" "$1" "" 2>/dev/null; }
_cmrcresult() { cut -f5 "$_cmrcrc" 2>/dev/null; }
_cmrcline() { printf '%s\n' "$1" | awk -F'\t' -v n="$2" '$1 == n'; }

_cmtable 'alpha	-	-	-	-	test -f src/a.txt	3' \
         'automation_surveyed	-	-	-	provider:claude-code-setup:claude-automation-recommender	-	4'
_cmrcfull="$(_cm felix_commission_run "$CMP" "$CMR" -)"
_cmrcalpha="$(_cmrcline "$_cmrcfull" alpha)"; _cmrcauto="$(_cmrcline "$_cmrcfull" automation_surveyed)"
_cmrcstray="$(printf 'cmrc_stray\tdone\tOBSERVED\t-\t9\t\t-')"

is  "a run that printed every row the table lists, in order, still gives a commissioned receipt" \
    "$(_cm _cmrcwrite "$_cmrcfull")" "commissioned"
is  "and a blank line or a line with no need in that output is not a row, and changes nothing" \
    "$(_cm _cmrcwrite "$(printf '%s\n\n%s\n\tdone\tOBSERVED\t-\t9\t\t-\n' "$_cmrcalpha" "$_cmrcauto")")" "commissioned"
is  "a run that printed every row the table lists is complete, and nothing is said" \
    "$(_cm _cmrccomplete "$_cmrcfull")" "0 []"
is  "an output missing a row the table lists is not complete, and says how many of how many it reported" \
    "$(_cm _cmrccomplete "$_cmrcalpha")" "1 [1 of 2]"
is  "an output that carries a row twice the table lists once is not complete" \
    "$(_cm _cmrccomplete "$(printf '%s\n%s\n%s' "$_cmrcalpha" "$_cmrcalpha" "$_cmrcauto")")" "1 [3 of 2]"
is  "an output that carries a need the table does not list is not complete" \
    "$(_cm _cmrccomplete "$(printf '%s\n%s\n%s' "$_cmrcalpha" "$_cmrcauto" "$_cmrcstray")")" "1 [3 of 2]"
is  "an output whose rows are those the table lists, in another order, is not complete" \
    "$(_cm _cmrccomplete "$(printf '%s\n%s' "$_cmrcauto" "$_cmrcalpha")")" "1 [2 of 2]"
# Added after review, not blind: K counts rows, so a blank line and a line
# naming no need in a short output are not counted toward it.
is  "an output missing a row, with a blank line and a line naming no need, reports 1 of 2" \
    "$(_cm _cmrccomplete "$(printf '%s\n\n\tdone\tOBSERVED\t-\t9\t\t-\n' "$_cmrcalpha")")" "1 [1 of 2]"
is  "a receipt over an output missing a row the table lists is indeterminate, printed and written" \
    "$(_cm _cmrcwrite "$_cmrcalpha") $(_cmrcresult)" "indeterminate indeterminate"
is  "a receipt over an output carrying a row twice is indeterminate" \
    "$(_cm _cmrcwrite "$(printf '%s\n%s\n%s' "$_cmrcalpha" "$_cmrcalpha" "$_cmrcauto")")" "indeterminate"
is  "a receipt over an output carrying a need the table does not list is indeterminate" \
    "$(_cm _cmrcwrite "$(printf '%s\n%s\n%s' "$_cmrcalpha" "$_cmrcauto" "$_cmrcstray")")" "indeterminate"
is  "a receipt over the table's rows in another order is indeterminate" \
    "$(_cm _cmrcwrite "$(printf '%s\n%s' "$_cmrcauto" "$_cmrcalpha")")" "indeterminate"

# Added after review, not blind. A need holding a byte that is not UTF-8, read
# under a UTF-8 locale. The first fix read the table's needs with cut, and BSD
# cut stops at that byte, so on macOS an honest run of this table read 3 of 1
# and its receipt was indeterminate on every run. Where cut reads bytes, or the
# locale is not installed, this passes either way.
_cmtable 'alpha	-	-	-	-	test -f src/a.txt	3' \
         "$(printf 'cmrc_caf\351\t-\t-\t-\t-\ttest -f src/a.txt\t3')" \
         "$(printf 'cmrc_gamma\t-\t-\t-\t-\ttest -f src/a.txt\t3')"
_cmrcl1() { LC_ALL=en_US.UTF-8; export LC_ALL
  _cmrcwrite "$(felix_commission_run "$CMP" "$CMR" - 2>/dev/null)"; }
is  "a need holding a byte that is not UTF-8, under a UTF-8 locale, is a complete run and a commissioned receipt" \
    "$(_cm _cmrcl1 2>/dev/null)" "commissioned"

# A need the table itself lists twice is asked twice, and both are owed.
_cmtable 'alpha	-	-	-	-	test -f src/a.txt	3' \
         'alpha	-	-	-	-	test -f src/a.txt	3' \
         'automation_surveyed	-	-	-	provider:claude-code-setup:claude-automation-recommender	-	4'
_cmrctwice="$(_cm felix_commission_run "$CMP" "$CMR" -)"
is  "a need the table lists twice, printed twice, is a complete run and a commissioned receipt" \
    "$(_cm _cmrcwrite "$_cmrctwice")" "commissioned"

# A table that lists no need: a run that asked nothing certifies nothing.
_cmtable
is  "a table that lists no need never has a complete run" "$(_cm _cmrccomplete "")" "1 [0 of 0]"
is  "and a receipt over it is indeterminate, not commissioned" "$(_cm _cmrcwrite "")" "indeterminate"

# The loop's own shell ending on its second row. The middle row is held, so
# the receipt over the rows that were printed read commissioned.
_cmrcdie() { local _cmrcat="$1" _cmrcn=0 _cmrcdef
  _cmrcdef="$(declare -f _felix_commission_state_known)"
  eval "_cmrc_real_known${_cmrcdef#_felix_commission_state_known}"
  _felix_commission_state_known() {
    _cmrcn=$((_cmrcn + 1))
    [ "$_cmrcn" -lt "$_cmrcat" ] || exit 128
    _cmrc_real_known "$@"; }
  felix_commission_run "$CMP" "$CMR" - 2>/dev/null; }
_cmtable "$(printf 'cmrc_first\t-\t-\t-\t-\ttest -f src/a.txt\t9')" \
         "$(printf 'cmrc_held\t-\t-\t-\t-\ttest -f cmrc-no-such-file\t9')" \
         "$(printf 'cmrc_last\t-\t-\t-\t-\ttest -f src/a.txt\t9')"
_cmrcshort="$(_cm _cmrcdie 2)"
_cmrcwhole="$(_cm _cmrcdie 99)"
is  "with the check replaced and nothing ended, the run prints all three rows and the receipt is held" \
    "$(printf '%s\n' "$_cmrcwhole" | awk -F'\t' '$1 != "" { printf "%s ", $2 }')$(_cm _cmrcwrite "$_cmrcwhole")" "done held done held"
is  "a run whose loop ended on its second row printed only the first" \
    "$(printf '%s\n' "$_cmrcshort" | awk -F'\t' '$1 != "" { printf "%s ", $1 }')" "cmrc_first "
is  "and that output is not complete: one of three" "$(_cm _cmrccomplete "$_cmrcshort")" "1 [1 of 3]"
is  "and the receipt over it is indeterminate, printed and written, not commissioned with the held row gone" \
    "$(_cm _cmrcwrite "$_cmrcshort") $(_cmrcresult)" "indeterminate indeterminate"

# Counts that are not numbers. The output under them is complete, so the only
# thing wrong is the counts line.
_cmtable 'alpha	-	-	-	-	test -f src/a.txt	3' \
         'automation_surveyed	-	-	-	provider:claude-code-setup:claude-automation-recommender	-	4'
_cmrccounts() { local _cmrcgiven="$1"
  felix_commission_counts() { printf '%s' "$_cmrcgiven"; }
  felix_commission_receipt_write "$FROOT" "$CMP" "$CMR" "$_cmrcfull" "" 2>"$TMP/cmrc-stderr"; }
_cmrcfields() { awk -F'\t' '{ ok = "digits"
                               for (i = 6; i <= 10; i++) if ($i !~ /^([0-9]+|[?])$/) ok = "not digits"
                               print NF, ok }' "$_cmrcrc" 2>/dev/null; }
_cmrcerr() { case "$(cat "$TMP/cmrc-stderr" 2>/dev/null)" in
               *'integer expression expected'*) printf 'said' ;; *) printf 'silent' ;; esac; }
is  "counts that read as numbers still give commissioned, and nothing on stderr" \
    "$(_cm _cmrccounts '2 0 0 0 0 0') $(_cmrcerr)" "commissioned silent"
is  "and a held count still gives held" "$(_cm _cmrccounts '1 1 0 0 0 0')" "held"
is  "counts that come back empty give an indeterminate receipt, not commissioned" \
    "$(_cm _cmrccounts '')" "indeterminate"
is  "and no test on stderr says integer expression expected" "$(_cmrcerr)" "silent"
is  "and the receipt keeps ten fields, each count digits or ?" "$(_cmrcfields)" "10 digits"
is  "one count come back empty, so the rest would shift into its place, gives indeterminate" \
    "$(_cm _cmrccounts '2 0  0 0 0')" "indeterminate"
is  "and that receipt still keeps ten fields, each count digits or ?" "$(_cmrcfields)" "10 digits"
# Added after review, not blind: the counts after a gap sit one place left, so
# none of them is written as if it were the count its field names.
is  "and every count in it is ?, not a number moved into its neighbour's place" \
    "$(cut -f6-10 "$_cmrcrc" 2>/dev/null | tr '\t' ' ')" "? ? ? ? ?"
is  "a count that reads ? gives indeterminate, not commissioned" \
    "$(_cm _cmrccounts '2 0 ? 0 0 0')" "indeterminate"
is  "and no test on stderr says integer expression expected over the ?" "$(_cmrcerr)" "silent"
is  "a sixth count that is a word gives indeterminate, though the receipt never writes it" \
    "$(_cm _cmrccounts '2 0 0 0 0 x')" "indeterminate"

# The counts themselves: a count that comes back empty keeps its place.
_cmrcrows="$(printf 'cmrc_d\tdone\tOBSERVED\t-\t9\t\t-\ncmrc_unk\tunknown\tUNKNOWN\t-\t9\tcmrc\t-')"
_cmrcblank() { grep() {
    case " $* " in
      *' -c '*) local _cmrcin; _cmrcin="$(cat)"
                case "$_cmrcin" in *cmrc_unk*) return 1 ;; esac
                printf '%s\n' "$_cmrcin" | command grep "$@" ;;
      *) command grep "$@" ;;
    esac; }
  felix_commission_counts "$1" ""; printf '|%s' "$?"; }
_cmrcplain() { felix_commission_counts "$1" ""; printf '|%s' "$?"; }
is  "counts every grep answers are six numbers, and return 0" "$(_cm _cmrcplain "$_cmrcrows")" "1 0 1 0 0 0|0"
_cmrcgap="$(_cm _cmrcblank "$_cmrcrows")"
is  "a count that comes back empty still leaves six tokens" \
    "$(printf '%s' "${_cmrcgap%|*}" | awk '{ print NF }')" "6"
is  "and the unknown count reads ?, with every other count in its own place" \
    "$(printf '%s' "${_cmrcgap%|*}" | awk '{ print $1, $2, $3, $4, $5, $6 }')" "1 0 ? 0 0 0"
is  "and the counts return 1" "${_cmrcgap##*|}" "1"


# The reader. A current receipt, rewritten in place.
_cm _cmrcwrite "$_cmrcfull" >/dev/null
cp "$_cmrcrc" "$TMP/cmrc-good.receipt"
_cmrcvalid() { local _cmrcv _cmrcvr
  _cmrcv="$(_cm felix_commission_receipt_valid "$FROOT" "$CMP" "$CMR" 2>/dev/null)"; _cmrcvr=$?
  printf '%s %s' "$_cmrcvr" "$_cmrcv"; }
_cmrcredo() { awk -F'\t' -v OFS='\t' "$1" "$TMP/cmrc-good.receipt" > "$TMP/cmrc-redo.receipt" \
                && mv "$TMP/cmrc-redo.receipt" "$_cmrcrc"; }
_cmrcbegins() { case "$2" in "$3"*) ok "$1" ;; *) bad "$1" "[$2] does not begin [$3]" ;; esac; }
_cmrcbegins "a current well-formed receipt still reads valid" "$(_cmrcvalid)" "0 commissioned"
_cmrcredo '{ $5 = "held"; $7 = "1"; print }'
_cmrcbegins "and a current well-formed held receipt still reads valid, held" "$(_cmrcvalid)" "0 held"
_cmrcredo '{ for (i = 6; i <= 10; i++) $i = ""; print }'
_cmrcbegins "a receipt whose counts are empty is unreadable, not valid" "$(_cmrcvalid)" "1 unreadable ("
_cmrcredo '{ $8 = "?"; print }'
_cmrcbegins "a receipt whose unknown count is ? is unreadable" "$(_cmrcvalid)" "1 unreadable ("
_cmrcredo '{ $5 = "finished"; print }'
_cmrcbegins "a receipt whose result is a word no run writes is unreadable" "$(_cmrcvalid)" "1 unreadable ("
_cmrcredo '{ $5 = "indeterminate"; $8 = ""; print }'
_cmrcbegins "an indeterminate receipt with a count missing still reads indeterminate first" "$(_cmrcvalid)" "1 indeterminate"
_cmrcredo '{ $2 = "cmrc-not-the-table"; $8 = ""; print }'
_cmrcbegins "a stale receipt with a count missing still reads stale first" "$(_cmrcvalid)" "1 stale (table set moved"
# Added after review, not blind: each end of the count fields alone, and the
# claude cli having changed since, which announces and returns 0 for a
# well-formed receipt and must not for one whose counts no run wrote.
_cmrcredo '{ $6 = ""; print }'
_cmrcbegins "a receipt whose done count alone is empty is unreadable" "$(_cmrcvalid)" "1 unreadable ("
_cmrcredo '{ $10 = "?"; print }'
_cmrcbegins "a receipt whose awaiting count alone is ? is unreadable" "$(_cmrcvalid)" "1 unreadable ("
_cmrcredo '{ $4 = "cmrc-older-claude"; print }'
_cmrcbegins "a well-formed receipt from an older claude cli still reads valid, and says so" "$(_cmrcvalid)" "0 commissioned (the claude cli changed since"
_cmrcredo '{ $4 = "cmrc-older-claude"; for (i = 6; i <= 10; i++) $i = ""; print }'
_cmrcbegins "a receipt from an older claude cli whose counts are empty is unreadable, not announced" "$(_cmrcvalid)" "1 unreadable ("

# The command. Two stubs appended to the fixture's copy of the library, each
# idle unless the run is handed its variable: the check on a row's state ends
# the loop's shell at the call FELIX_CMRC_DIE_AT names, and the counts print
# FELIX_CMRC_COUNTS. The copy is put back the moment the last run returns.
_cmtable "$(printf 'cmrc_first\t-\t-\t-\t-\ttest -f src/a.txt\t9')" \
         "$(printf 'cmrc_held\t-\t-\t-\t-\ttest -f cmrc-no-such-file\t9')" \
         "$(printf 'cmrc_last\t-\t-\t-\t-\ttest -f src/a.txt\t9')"
cat >> "$_cmrclib" <<'CMRCLIB'
_cmrc_known_def="$(declare -f _felix_commission_state_known)"
eval "_cmrc_real_known${_cmrc_known_def#_felix_commission_state_known}"
_felix_commission_state_known() {
  if [ -n "${FELIX_CMRC_DIE_AT:-}" ]; then
    _cmrc_known_n=$(( ${_cmrc_known_n:-0} + 1 ))
    [ "$_cmrc_known_n" -lt "$FELIX_CMRC_DIE_AT" ] || exit 128
  fi
  _cmrc_real_known "$@"; }
_cmrc_counts_def="$(declare -f felix_commission_counts)"
eval "_cmrc_real_counts${_cmrc_counts_def#felix_commission_counts}"
felix_commission_counts() {
  if [ -n "${FELIX_CMRC_COUNTS:-}" ]; then printf '%s' "$FELIX_CMRC_COUNTS"; return 0; fi
  _cmrc_real_counts "$@"; }
CMRCLIB
_cmrccli() { local _cmrcd="$1" _cmrck="$2"; shift 2
  ( cd "$CMR" && FELIX_CMRC_DIE_AT="$_cmrcd" FELIX_CMRC_COUNTS="$_cmrck" PATH="$CMSTUB:$PATH" \
      "$FELIX" commission "$@" 2>&1 ); }
_cmrcclean="$(_cmrccli '' '')"; _cmrccleanx=$?; _cmrccleanr="$(_cmrcresult)"
_cmrcstat="$(_cmrccli 2 '' --status)"
_cmrcshortcli="$(_cmrccli 2 '')"; _cmrcshortx=$?; _cmrcshortr="$(_cmrcresult)"
_cmrcqcli="$(_cmrccli '' '1 1 ? 0 0 0')"; _cmrcqx=$?; _cmrcqr="$(_cmrcresult)"
_cmrcallq="$(_cmrccli '' '? ? ? ? ? ?')"; _cmrcallqx=$?; _cmrcallqr="$(_cmrcresult)"
cp "$TMP/cmrc-lib.keep" "$_cmrclib"
is  "and the engine copy the command ran from is put back byte for byte" \
    "$(cksum < "$_cmrclib")" "$(cksum < "$TMP/cmrc-lib.keep")"

case "$_cmrcclean" in
  *'the run reported'*) bad "a full run that printed every row says nothing about rows missing" \
                            "$(printf '%s\n' "$_cmrcclean" | grep 'the run reported')" ;;
  *)                    ok  "a full run that printed every row says nothing about rows missing" ;;
esac
is  "and writes held over the held row, exiting 0" "$_cmrccleanr $_cmrccleanx" "held 0"
_cmrcreported() { printf '%s\n' "$1" | grep -o 'the run reported [0-9]* of [0-9]* rows' | head -1; }
is  "--status over a run whose loop ended on its second row says it reported 1 of 3 rows" \
    "$(_cmrcreported "$_cmrcstat")" "the run reported 1 of 3 rows"
is  "a full run whose loop ended on its second row says it reported 1 of 3 rows" \
    "$(_cmrcreported "$_cmrcshortcli")" "the run reported 1 of 3 rows"
is  "and writes the receipt indeterminate and exits 1" "$_cmrcshortr $_cmrcshortx" "indeterminate 1"
case "$_cmrcqcli" in
  *'integer expression expected'*)
     bad "a full run whose unknown count reads ? writes no integer expression expected anywhere" \
         "$(printf '%s\n' "$_cmrcqcli" | grep 'integer expression expected')" ;;
  *) ok  "a full run whose unknown count reads ? writes no integer expression expected anywhere" ;;
esac
is  "and writes the receipt indeterminate and exits 1, not held" "$_cmrcqr $_cmrcqx" "indeterminate 1"
# Added after review, not blind. The summary line and the two sections after
# it test the held, malformed, awaiting and unknown counts, and only the
# unknown one was ever ?. And the sentence under a short run says only what is
# true of the receipt: --status writes none, so it may not say indeterminate.
case "$_cmrcallq" in
  *'integer expression expected'*)
     bad "a full run whose every count reads ? writes no integer expression expected anywhere" \
         "$(printf '%s\n' "$_cmrcallq" | grep 'integer expression expected')" ;;
  *) ok  "a full run whose every count reads ? writes no integer expression expected anywhere" ;;
esac
is  "and writes the receipt indeterminate and exits 1" "$_cmrcallqr $_cmrcallqx" "indeterminate 1"
has "--status over a short run says a receipt over it would be indeterminate" "$_cmrcstat" "would be indeterminate"
case "$_cmrcstat" in
  *'was written indeterminate'*) bad "and does not say one was written" "$(printf '%s\n' "$_cmrcstat" | grep 'was written')" ;;
  *)                             ok  "and does not say one was written" ;;
esac
has "a full run over a short run says the receipt was written indeterminate" "$_cmrcshortcli" "The receipt was written indeterminate"

cp "$TMP/cmrc-table.keep" "$CMP/commissioning.tsv"
if [ -f "$TMP/cmrc-receipt.keep" ]; then mv "$TMP/cmrc-receipt.keep" "$_cmrcrc"; else rm -f "$_cmrcrc"; fi
if [ -f "$TMP/cmrc-log.keep" ]; then mv "$TMP/cmrc-log.keep" "$_cmrclog"; else rm -f "$_cmrclog"; fi
rm -f "$TMP/cmrc-table.keep" "$TMP/cmrc-lib.keep" "$TMP/cmrc-stderr" "$TMP/cmrc-good.receipt" "$TMP/cmrc-redo.receipt"
is  "and this block leaves the table, the receipt, the log, the engine copy and every cmrc- file as it found them" \
    "$(_cmrcfixture)" "$_cmrcfound"
unset -f _cmrcfixture _cmrccomplete _cmrcwrite _cmrcresult _cmrcline _cmrcdie _cmrccounts _cmrcfields _cmrcerr \
         _cmrcblank _cmrcplain _cmrcvalid _cmrcredo _cmrcbegins _cmrccli _cmrcreported _cmrcl1
unset _cmrcrc _cmrclib _cmrclog _cmrcfound _cmrcfull _cmrcalpha _cmrcauto _cmrcstray _cmrctwice _cmrcshort _cmrcwhole \
      _cmrcrows _cmrcgap _cmrcclean _cmrccleanx _cmrccleanr _cmrcstat _cmrcshortcli _cmrcshortx _cmrcshortr \
      _cmrcqcli _cmrcqx _cmrcqr _cmrcallq _cmrcallqx _cmrcallqr
