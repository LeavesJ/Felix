# A lookup that could not be made is unknown, never a no.
#
# felix_commission_state decides a row from lookups made inside $(...), and
# under load a fork inside one fails with EAGAIN: the substitution prints
# nothing and returns 128. Three lookups read that as a valid answer. The
# declared capabilities came back as none, so a row whose capability is
# declared read not-applicable and the receipt said commissioned; the run's
# empty-state guard cannot see it, because not-applicable is a state. The
# engine functions a check names came back as none when the grep that reads
# them ran and failed, so a check over a function that is not loaded ran and
# read done. (Amended after review: a fork that failed there skipped the
# `|| true` and, under the CLI's pipefail, read unknown naming no function;
# done only without pipefail. The stub below models the grep that failed.)
# And the count of an answer's rows came
# back empty, the comparison with its done line errored and was false, and the
# answer read answered, whole or not, which is the state every ingestion
# reads. The adversarial reviewer of the empty-state fix above found the
# first on bash 3.2; the other two were found by surveying the same shape. Here
# nothing is starved of processes: inside _cm the lookup is replaced by one
# that fails as a substitution whose fork could not be made fails, printing
# nothing and returning 128, and the engine is called after it. A list that was
# read and is empty is still a no; one that could not be read is unknown. These
# assertions were written blind, from the contract, before the fix, and each
# was run against main's engine first.
# Everything this touches is restored below and everything it defines unset.
_commissioning_build alpha12
_cmlfad="$MEM/cmproj/commission"
_cmlffixture() { local _cmlff
  for _cmlff in "$CMP/capabilities" "$CMP/commissioning.tsv" "$FROOT/state/commission/cmproj" \
                "$MEM/cmproj/commissioning.log"; do
    if [ -f "$_cmlff" ]; then printf '%s %s | ' "$(cksum < "$_cmlff")" "$(ls -l "$_cmlff" | cut -c1-10)"
    else printf 'absent | '; fi
  done
  if [ -d "$_cmlfad" ]; then find "$_cmlfad" -type f -exec cksum {} + | sort | tr '\n' ' '
  else printf 'no answer directory '; fi
  printf '| %s | %s\n' "$(find "$FROOT/state/commission" -name 'cmproj*' -exec cksum {} + 2>/dev/null | sort | tr '\n' ' ')" \
                       "$(ls -a "$TMP" | grep -c '^cmlf-')"; }
_cmlffound="$(_cmlffixture)"
rm -f "$TMP/cmlf-caps.keep" "$TMP/cmlf-table.keep" "$TMP/cmlf-receipt.keep" "$TMP/cmlf-log.keep"
[ -f "$CMP/capabilities" ] && mv "$CMP/capabilities" "$TMP/cmlf-caps.keep"
[ -f "$CMP/commissioning.tsv" ] && cp "$CMP/commissioning.tsv" "$TMP/cmlf-table.keep"
[ -f "$FROOT/state/commission/cmproj" ] && cp "$FROOT/state/commission/cmproj" "$TMP/cmlf-receipt.keep"
[ -f "$MEM/cmproj/commissioning.log" ] && cp "$MEM/cmproj/commissioning.log" "$TMP/cmlf-log.keep"
_cmlfmade=''; [ -d "$_cmlfad" ] || { mkdir -p "$_cmlfad"; _cmlfmade=made; }
# $1 names the lookup to break and the rest is the engine call made after it.
# Every stub is defined inside the _cm subshell, never in this shell.
_cmlfstub() { local _cmlfmode="$1"; shift
  case "$_cmlfmode" in
    declared)     felix_declared() { return 128; } ;;
    declared-api) felix_declared() { printf 'api\n'; return 128; } ;;
    has-line)     felix_has_line() { return 1; } ;;
    names)        grep() { case "$1" in -oE) return 128 ;; esac; command grep "$@"; } ;;
    names-nopf)   set +o pipefail
                  grep() { case "$1" in -oE) return 128 ;; esac; command grep "$@"; } ;;
    count)        grep() { case "$1" in -vc) return 128 ;; esac; command grep "$@"; } ;;
    cap-3)        _felix_cap_active() { return 3; } ;;
    present-1)    _felix_commission_functions_present() { return 1; } ;;
    present-3)    _felix_commission_functions_present() { return 3; } ;;
    tab)          IFS=$'\t' ;;
    declared-exit0) felix_declared() { exit 0; } ;;
    present-exit0)  _felix_commission_functions_present() { exit 0; } ;;
    declared-cat2)  mkdir -p "$TMP/cmlfcat2"
                    printf '#!/bin/bash\nfor a in "$@"; do case "$a" in *capabilities) exit 2 ;; esac; done\nexec %s "$@"\n' \
                      "$(type -P cat)" > "$TMP/cmlfcat2/cat"
                    chmod +x "$TMP/cmlfcat2/cat"; PATH="$TMP/cmlfcat2:$PATH" ;;
    count-first)    grep() { case "$1$2" in '-vE^[[:space:]]*(#|$)') return 2 ;; esac; command grep "$@"; } ;;
    count-first-two) grep() { case "$1$2" in '-vE^[[:space:]]*(#|$)') command grep "$@" | awk 'NR <= 2'; return 2 ;; esac
                      command grep "$@"; } ;;
    count-printed)  grep() { case "$1" in -vc) command grep "$@"; return 2 ;; esac; command grep "$@"; } ;;
    bracket-exit0)  grep() { case "$1" in -oE) return 1 ;; esac; command grep "$@"; }
                    [() { exit 0; } ;;
  esac
  "$@"; }
# What a call printed and the status it returned, as "status [output]".
_cmlfrc()   { local _cmlfo _cmlfs; _cmlfo="$("$@" 2>/dev/null)"; _cmlfs=$?; printf '%s [%s]\n' "$_cmlfs" "$_cmlfo"; }
_cmlff()    { printf '%s\n' "$1" | awk -F'\t' -v n="$2" -v f="$3" '$1 == n { print $f }'; }
_cmlfsays() { case "$1" in *"$2"*) printf 'said\n' ;; *) printf 'silent\n' ;; esac; }
_cmlfnz()   { case "$1" in '0 '*) printf 'returned 0\n' ;; *' []') printf 'nonzero, nothing\n' ;; *) printf '%s\n' "$1" ;; esac; }

# The declared capabilities.
_cmtable $'cmlf_cap\tapi\t-\t-\t-\ttrue\t9' \
         $'cmlf_plain\t-\t-\t-\t-\ttest -f src/a.txt\t9'
printf 'api\n' > "$CMP/capabilities"
_cmlfrun0="$(_cm felix_commission_run "$CMP" "$CMR" -)"
_cmlfrun1="$(_cm _cmlfstub declared felix_commission_run "$CMP" "$CMR" - 2>/dev/null)"
_cmlfrun2="$(_cm _cmlfstub declared-api felix_commission_run "$CMP" "$CMR" - 2>/dev/null)"
is  "with api declared and nothing stubbed, a row grounded on api and the row beside it are done, and the receipt is commissioned" \
    "$(_cmlff "$_cmlfrun0" cmlf_cap 2) $(_cmlff "$_cmlfrun0" cmlf_plain 2) $(_cm felix_commission_receipt_write "$FROOT" "$CMP" "$CMR" "$_cmlfrun0" "")" \
    "done done commissioned"
is  "a declared list that could not be read makes a row grounded on a declared capability unknown, not not-applicable" \
    "$(_cmlff "$_cmlfrun1" cmlf_cap 2) $(_cmlff "$_cmlfrun1" cmlf_cap 3)" "unknown UNKNOWN"
has "and it says the capabilities this project declares could not be read" \
    "$(_cmlff "$_cmlfrun1" cmlf_cap 6)" "the capabilities this project declares could not be read"
is  "and the receipt over it, every other row done, is indeterminate and not commissioned" \
    "$(_cmlff "$_cmlfrun1" cmlf_plain 2) $(_cm felix_commission_receipt_write "$FROOT" "$CMP" "$CMR" "$_cmlfrun1" "")" \
    "done indeterminate"
is  "a declared list that names api but came back with a failure is not trusted: the row is unknown, not done" \
    "$(_cmlff "$_cmlfrun2" cmlf_cap 2)" "unknown"

_cmlfca() { _cm _cmlfstub "$1" _cmlfrc _felix_cap_active "$2" "$CMP"; }
is  "_felix_cap_active returns 2 when felix_declared fails, whether it printed nothing or printed the capability" \
    "$(_cmlfca declared api) $(_cmlfca declared-api api)" "2 [] 2 []"
is  "and grounds always are active, 0, without reading the failing list" "$(_cmlfca declared always)" "0 []"
_cmlfalone="$(_cmlfca none api)"
printf 'web\napi\nml\n' > "$CMP/capabilities"
is  "it returns 0 for a list that was read and holds the capability as a line, alone or among others" \
    "$_cmlfalone $(_cmlfca none api)" "0 [] 0 []"
printf 'web\napis\nmy-api\n# api\n' > "$CMP/capabilities"
is  "and 1 for a list that was read and holds other capabilities, or the name only inside a longer one or a comment" \
    "$(_cmlfca none api)" "1 []"
printf '# cmlf a capabilities file with no capability in it\n\n# api\n\n' > "$CMP/capabilities"
is  "and 1 for a list of only comments and blank lines" "$(_cmlfca none api)" "1 []"
is  "felix_declared over a file of only comments and blank lines prints nothing and returns 0: it was read, and holds none" \
    "$(_cm _cmlfrc felix_declared "$CMP")" "0 []"
is  "a capabilities file of only comments and blank lines still makes the row not-applicable" \
    "$(_cmlff "$(_cm felix_commission_run "$CMP" "$CMR" -)" cmlf_cap 2)" "not-applicable"
rm -f "$CMP/capabilities"
is  "felix_declared over an absent capabilities file prints nothing and returns 0" \
    "$(_cm _cmlfrc felix_declared "$CMP")" "0 []"
is  "and _felix_cap_active reads an absent file as a list without the capability, 1" "$(_cmlfca none api)" "1 []"
printf 'api\n# cmlf a comment\n\nweb\n' > "$CMP/capabilities"
is  "felix_declared still prints the lines that are not blank and not comments, and returns 0" \
    "$(_cm _cmlfrc felix_declared "$CMP")" "$(printf '0 [api\nweb]')"

# A capabilities file that exists and cannot be read, with nothing stubbed.
printf 'api\n' > "$CMP/capabilities"; chmod 000 "$CMP/capabilities"
if [ -r "$CMP/capabilities" ]; then
  skip "felix_declared returns nonzero and prints nothing over a capabilities file that exists and cannot be read" \
       "the file is readable at mode 000 here, as it is to root"
  skip "and _felix_cap_active returns 2 there, and the row grounded on it is unknown, not not-applicable" \
       "the file is readable at mode 000 here, as it is to root"
else
  _cmlfur="$(_cm _cmlfrc felix_declared "$CMP")"
  is  "felix_declared returns nonzero and prints nothing over a capabilities file that exists and cannot be read" \
      "$(_cmlfnz "$_cmlfur")" "nonzero, nothing"
  is  "and _felix_cap_active returns 2 there, and the row grounded on it is unknown, not not-applicable" \
      "$(_cmlfca none api) $(_cm felix_commission_state "$CMP" "$CMR" cmlf_cap api - - - true 2>/dev/null | cut -f1)" \
      "2 [] unknown"
fi
rm -f "$CMP/capabilities"

# The membership itself makes no here-document, which on bash 3.2 is a
# temporary file: one that cannot be written leaves the read loop unread, as
# felix_has_line returning 1 does here.
printf 'api\n' > "$CMP/capabilities"
is  "with felix_has_line failing as an unwritable here-document makes it fail, a declared api is still active and its row done" \
    "$(_cmlfca has-line api) $(_cm _cmlfstub has-line felix_commission_state "$CMP" "$CMR" cmlf_cap api - - - true 2>/dev/null | cut -f1)" \
    "0 [] done"
_cmlfc3="$(_cm _cmlfstub cap-3 felix_commission_state "$CMP" "$CMR" cmlf_cap api - - - true 2>/dev/null)"
is  "a capability lookup that answers neither 0 nor 1 makes the row unknown, and says the declared list could not be read" \
    "$(printf '%s\n' "$_cmlfc3" | cut -f1) $(_cmlfsays "$(printf '%s\n' "$_cmlfc3" | cut -f2)" 'the capabilities this project declares could not be read')" \
    "unknown said"

# The engine functions a check names.
felix_cmlf_one() { return 0; }
felix_cmlf_two() { return 0; }
_cmlfgone='[ -z "$(felix_cmlf_gone)" ]'
_cmlfefn()  { _cm _cmlfstub "$1" felix_commission_state "$CMP" "$CMR" cmlf_efn - - - - "$2" 2>/dev/null; }
_cmlfpres() { _cm _cmlfstub "$1" _cmlfrc _felix_commission_functions_present "$2"; }
_cmlfe0="$(_cmlfefn none "$_cmlfgone")"
_cmlfe1="$(_cmlfefn names "$_cmlfgone")"
_cmlfe2="$(_cmlfefn names-nopf "$_cmlfgone")"
is  "unstubbed, a check over an engine function that is not loaded is unknown and names it" \
    "$(printf '%s\n' "$_cmlfe0" | cut -f1) $(_cmlfsays "$(printf '%s\n' "$_cmlfe0" | cut -f2)" felix_cmlf_gone)" "unknown said"
is  "when the names a check holds could not be read from it, the row is unknown, not done" \
    "$(printf '%s\n' "$_cmlfe1" | cut -f1)" "unknown"
has "and it says the engine functions the check names could not be read" \
    "$(printf '%s\n' "$_cmlfe1" | cut -f2)" "the engine functions the check names could not be read"
is  "and so with pipefail off in the caller" "$(printf '%s\n' "$_cmlfe2" | cut -f1)" "unknown"
is  "the lookup of the names returns 2 and names nothing when its grep fails, with pipefail on or off" \
    "$(_cmlfpres names "$_cmlfgone") $(_cmlfpres names-nopf "$_cmlfgone")" "2 [] 2 []"
is  "unstubbed it returns 1 naming the one not loaded, and 0 naming nothing for a check of none or of loaded ones" \
    "$(_cmlfpres none "$_cmlfgone") $(_cmlfpres none 'test -f src/a.txt') $(_cmlfpres none 'felix_cmlf_one && felix_cmlf_two')" \
    "1 [felix_cmlf_gone] 0 [] 0 []"
is  "a check naming two loaded engine functions is done with IFS a tab in the calling shell" \
    "$(_cmlfpres tab 'felix_cmlf_one && felix_cmlf_two') $(_cmlfefn tab 'felix_cmlf_one && felix_cmlf_two' | cut -f1)" "0 [] done"
_cmlfp1="$(_cmlfefn present-1 "$_cmlfgone")"
_cmlfp3="$(_cmlfefn present-3 "$_cmlfgone")"
is  "a names lookup that returns 1 naming nothing, or 3, makes the row unknown and says the names could not be read" \
    "$(printf '%s\n' "$_cmlfp1" | cut -f1) $(_cmlfsays "$(printf '%s\n' "$_cmlfp1" | cut -f2)" 'the engine functions the check names could not be read') $(printf '%s\n' "$_cmlfp3" | cut -f1) $(_cmlfsays "$(printf '%s\n' "$_cmlfp3" | cut -f2)" 'the engine functions the check names could not be read')" \
    "unknown said unknown said"

# The rows of a provider's answer.
_cmlfprov='provider:claude-code-setup:claude-automation-recommender'
_cmlftopo="$(_cm felix_commission_topology "$CMP" "$CMR")"
_cmlfans() { printf '# topology %s\n' "$_cmlftopo"; printf '%s\n' "$@"; }
_cmlfans $'plugin\tcmlfone\t-\tllm\twhy' $'plugin\tcmlftwo\t-\tllm\twhy' $'done\t2' > "$_cmlfad/cmlf_whole.tsv"
_cmlfans $'plugin\tcmlfone\t-\tllm\twhy' $'done\t2' > "$_cmlfad/cmlf_part.tsv"
_cmlfans $'done\t0' > "$_cmlfad/cmlf_zero.tsv"
# A twin of the whole answer with rows of its own, for the ingestion control:
# a file already ingested is not ingested again, so the control cannot share
# the stubbed call's file.
_cmlfans $'plugin\tcmlfthree\t-\tllm\twhy' $'plugin\tcmlffour\t-\tllm\twhy' $'done\t2' > "$_cmlfad/cmlf_twin.tsv"
_cmlfps() { _cm _cmlfstub "$1" felix_commission_provider_state "$CMP" "$CMR" "$2" 2>/dev/null; }
_cmlfpw="$(_cmlfps count cmlf_whole)"
is  "unstubbed, a whole answer of two rows is answered and one of its two rows is partial" \
    "$(_cmlfps none cmlf_whole | cut -f1) $(_cmlfps none cmlf_part | cut -f1)" "answered partial"
is  "and an answer of done 0 with no rows is answered" "$(_cmlfps none cmlf_zero | cut -f1)" "answered"
is  "a whole answer whose rows could not be counted is unknown, not answered" \
    "$(printf '%s\n' "$_cmlfpw" | cut -f1)" "unknown"
has "and it says the rows could not be counted" "$(printf '%s\n' "$_cmlfpw" | cut -f2)" "could not be counted"
is  "a partial answer whose rows could not be counted is unknown, not answered" \
    "$(_cmlfps count cmlf_part | cut -f1)" "unknown"
is  "through felix_commission_state, unstubbed, the provider row over the whole answer is answered" \
    "$(_cm felix_commission_state "$CMP" "$CMR" cmlf_whole - - - "$_cmlfprov" - 2>/dev/null | cut -f1)" "answered"
is  "and with its rows uncountable it is unknown" \
    "$(_cm _cmlfstub count felix_commission_state "$CMP" "$CMR" cmlf_whole - - - "$_cmlfprov" - 2>/dev/null | cut -f1)" "unknown"
_cmlfsum() { if [ -f "$1" ]; then cksum < "$1"; else printf 'absent\n'; fi; }
_cmlflogt="$(_cmlfsum "$MEM/cmproj/commissioning.log")"
_cmlfrect="$(_cm felix_commission_record_provider "$CMP" "$CMR" cmlf_twin "$_cmlfprov" cmlf-tree cmlf-policy 2>/dev/null)"
_cmlflog0="$(_cmlfsum "$MEM/cmproj/commissioning.log")"
is  "unstubbed, a whole answer of two rows is ingested: the record prints 2 and appends to the log" \
    "$_cmlfrect $([ "$_cmlflog0" = "$_cmlflogt" ] && printf unchanged || printf appended)" "2 appended"
_cmlfrec1="$(_cm _cmlfstub count felix_commission_record_provider "$CMP" "$CMR" cmlf_whole "$_cmlfprov" cmlf-tree cmlf-policy 2>/dev/null)"
_cmlflog1="$(_cmlfsum "$MEM/cmproj/commissioning.log")"
is  "an answer whose rows could not be counted is not ingested: the record prints 0 and appends nothing to the log" \
    "$_cmlfrec1 $([ "$_cmlflog1" = "$_cmlflog0" ] && printf unchanged || printf appended)" "0 unchanged"

# Added after review, not blind. The reviewers found four ways the first fix
# still read a lookup that was not made as one that was, and two ways a wrong
# implementation passed the block.
# - On bash 3.2 a substitution that cannot make its pipe (no file descriptor
#   left) expands to nothing with status 0 (measured), so a status read alone
#   takes it for a list read and empty. Modelled by a lookup that ends its
#   substitution with exit 0 before it answers; the engine has to see that
#   the answer never came.
# - A count of an answer's rows taken over a first grep that failed is a
#   number all the same, whether that grep printed nothing or some of the rows.
# - A capabilities link whose target is gone was called absent, so the list
#   was empty.
# - felix_declared swallowing grep's exit 2 was caught only at mode 000, which
#   root can still read. This one stubs the grep and runs as anybody.
#   (Restated 2026-10-08, blind from the contract in
#   docs/handoff/pending/20261008T191950Z-claude-declared-not-text.md, rule 7:
#   the file is read once, by cat on PATH, so the stub is a cat that fails.)
# - A walk of the names through a second substitution or a here-document
#   passed every assertion, and so did a membership test that inlined
#   felix_has_line's here-document. Each lookup is read here as bash prints it:
#   one substitution, no here-document, and no pipe but the one that reads
#   the names.
#
# Added after a second review and a review of that, also not blind:
# - The names lookup's own substitution failing to make its pipe, which a note
#   here called beyond any stub. Two ways now. `[` runs in that substitution's
#   shell before the `.`, and bash lets a function named `[` shadow the
#   builtin, so a `[` that exits 0 while grep answers "no names" gives what a
#   substitution with no pipe gives: no text, status 0. That holds only while
#   the lookup tests its status with `[`, as the shape check below pins. The
#   second takes every descriptor below a lowered limit, so the pipe really
#   cannot be made, however the lookup is spelled (measured on 3.2.57).
# - A count whose grep printed it and then failed is no count either, however
#   right the number looks.
# - A second channel the shape check did not see. With no descriptor left, a
#   backquote expands to nothing at status 0 as `$(` does, and a `< <(...)`
#   redirect fails at status 1 without running its loop (measured on 3.2.57),
#   so a walk over either sees no names. Nor did it see a walk moved into a
#   helper, whose body it never reads, so it now names every engine function
#   a lookup calls.
# - That a provider row whose rows could not be counted makes the receipt
#   indeterminate, which commission.sh's header and escape.sh say and nothing
#   asserted end to end. A count that skips provider rows' unknowns fails only
#   this one.
printf 'api\n' > "$CMP/capabilities"
is  "a declared list whose substitution ended before it answered, with status 0, makes _felix_cap_active return 2 and the row unknown" \
    "$(_cmlfca declared-exit0 api) $(_cm _cmlfstub declared-exit0 felix_commission_state "$CMP" "$CMR" cmlf_cap api - - - true 2>/dev/null | cut -f1)" \
    "2 [] unknown"
is  "a names lookup whose substitution ended with status 0 and no text makes the row unknown, not done" \
    "$(_cmlfefn present-exit0 "$_cmlfgone" | cut -f1)" "unknown"
is  "felix_declared returns nonzero and prints nothing when its read fails, a cat on PATH failing, as any user, and _felix_cap_active returns 2" \
    "$(_cmlfnz "$(_cm _cmlfstub declared-cat2 _cmlfrc felix_declared "$CMP")") $(_cmlfca declared-cat2 api)" \
    "nonzero, nothing 2 []"
rm -rf "$TMP/cmlfcat2"
rm -f "$CMP/capabilities"; ln -s "$TMP/cmlf-no-such-target" "$CMP/capabilities"
is  "a capabilities link whose target is gone is not an absent file: _felix_cap_active returns 2 and the row is unknown" \
    "$(_cmlfca none api) $(_cm felix_commission_state "$CMP" "$CMR" cmlf_cap api - - - true 2>/dev/null | cut -f1)" \
    "2 [] unknown"
# And only a regular file is read. A directory or a pipe named capabilities is
# something there that is no list; a pipe must not even be opened, because
# grep waits on it for a writer, which is what the first `-e` in place of `-f`
# did here, hanging (found after review). So the pipe is asked under a
# watchdog that ends the whole tree it started.
_cmlfkill() { local _cmlfc; for _cmlfc in $(pgrep -P "$1" 2>/dev/null); do _cmlfkill "$_cmlfc"; done; kill "$1" 2>/dev/null; }
rm -f "$CMP/capabilities"; mkfifo "$CMP/capabilities"
( _cmlfca none api > "$TMP/cmlf-fifo.out" 2>/dev/null ) & _cmlfw=$!
_cmlfi=0; while kill -0 "$_cmlfw" 2>/dev/null && [ "$_cmlfi" -lt 100 ]; do sleep 0.1; _cmlfi=$((_cmlfi + 1)); done
if kill -0 "$_cmlfw" 2>/dev/null; then _cmlfkill "$_cmlfw"; wait "$_cmlfw" 2>/dev/null; _cmlffifo='still waiting after ten seconds'
else wait "$_cmlfw" 2>/dev/null; _cmlffifo="$(cat "$TMP/cmlf-fifo.out")"; fi
rm -f "$CMP/capabilities" "$TMP/cmlf-fifo.out"; mkdir "$CMP/capabilities"
is  "a capabilities pipe or directory is no list: _felix_cap_active returns 2 at once for each, neither waiting on the pipe nor reading either as absent" \
    "$_cmlffifo $(_cmlfca none api)" "2 [] 2 []"
rmdir "$CMP/capabilities"
# ---- declared-not-text: begin
# Written blind from the contract in
# docs/handoff/pending/20261008T191950Z-claude-declared-not-text.md (rules 0 to
# 8), before the fix, and run against main's engine and the pre-fix base first:
# a capabilities file that is not a list of names. Every fixture is built with
# printf octal escapes. "status [stdout]" is what felix_declared printed on
# stdout, byte for byte (a NUL it printed shows as <NUL>), and the status it
# returned. Each rule is asserted under LC_ALL=C and under a UTF-8 locale this
# machine has (skipped, saying so, when it has none), and each felix_declared
# call is made with the caller's pipefail on and then off. Every helper is
# _dnt-prefixed and unset at the end; every stub is a PATH entry set inside a
# _cm subshell, never a function in this shell; $CMP/capabilities is left
# absent, as the line above leaves it, and $CMP/stack.tsv and the cli stub's
# log as they were found.
_dntu=''
for _dntl in en_US.UTF-8 C.UTF-8 en_US.utf8 C.utf8; do
  if [ "$(LC_ALL="$_dntl" "$BASH" -c 'x="$(printf "\303\251")"; printf "%s" "${#x}"' 2>/dev/null)" = 1 ]; then
    _dntu="$_dntl"; break
  fi
done
cp -p "$CMP/stack.tsv" "$TMP/dnt-stack.keep"
cp -p "$CMSTUB_LOG" "$TMP/dnt-cmstub.keep"
# The commands rule 7 names, each a PATH stub that logs its own name when an
# argument names the capabilities file or its stdin is that file, then runs
# the real command. And two cats that fail when asked for the file: one
# printing nothing, one printing its first line.
mkdir -p "$TMP/dnt-bin" "$TMP/dnt-cat-none" "$TMP/dnt-cat-part"
cat > "$TMP/dnt-isit" <<'DNTSTUB'
# 0 when an argument names the capabilities file or stdin is that file.
_dntid() { stat -L -c '%d:%i' "$1" 2>/dev/null || stat -L -f '%d:%i' "$1" 2>/dev/null; }
_dntisit() { local _dnta
  for _dnta in "$@"; do case "$_dnta" in *capabilities*) return 0 ;; esac; done
  [ -n "${DNT_CAPS:-}" ] && [ -e "$DNT_CAPS" ] || return 1
  [ "$(_dntid /dev/stdin)" = "$(_dntid "$DNT_CAPS")" ]; }
DNTSTUB
for _dntc in cat grep sed awk head tail wc od tr cut; do
  _dntreal="$(type -P "$_dntc")"
  cat > "$TMP/dnt-bin/$_dntc" <<DNTSTUB
#!/bin/bash
. "$TMP/dnt-isit"
if _dntisit "\$@"; then printf '%s\n' $_dntc >> "\$DNT_LOG"; fi
exec "$_dntreal" "\$@"
DNTSTUB
done
_dntreal="$(type -P cat)"
cat > "$TMP/dnt-cat-none/cat" <<DNTSTUB
#!/bin/bash
. "$TMP/dnt-isit"
if _dntisit "\$@"; then exit 1; fi
exec "$_dntreal" "\$@"
DNTSTUB
cat > "$TMP/dnt-cat-part/cat" <<DNTSTUB
#!/bin/bash
. "$TMP/dnt-isit"
if _dntisit "\$@"; then IFS= read -r _dntline < "\$DNT_CAPS"; printf '%s\n' "\$_dntline"; exit 1; fi
exec "$_dntreal" "\$@"
DNTSTUB
chmod +x "$TMP/dnt-bin/"* "$TMP/dnt-cat-none/cat" "$TMP/dnt-cat-part/cat"

# The caller's locale in this subshell: C is LC_ALL=C; utf8, ctype and lang
# name the UTF-8 locale in LC_ALL, LC_CTYPE or LANG alone.
_dntenv() { unset LC_ALL LC_CTYPE LANG
  case "$1" in
    C)     export LC_ALL=C ;;
    utf8)  export LC_ALL="$_dntu" ;;
    ctype) export LC_CTYPE="$_dntu" ;;
    lang)  export LANG="$_dntu" ;;
  esac
  export DNT_CAPS="$CMP/capabilities" DNT_LOG="$TMP/dnt-opens"; }
_dntfill() { local _dnti=0
  while [ "$_dnti" -lt 1100 ]; do
    printf '# filler comment, here only to push what follows past 64 KiB\n'; _dnti=$((_dnti + 1))
  done; }
# A fixture: a printf format written to the file, or @absent, @dir, @dangling,
# @keep (the file as it is), @link:FORMAT (a link to a regular file holding
# it) or @big:FORMAT (67100 bytes of comment lines, then it).
_dntput() { local _dntf="$CMP/capabilities"
  [ "$1" = @keep ] && return 0
  if [ -d "$_dntf" ] && [ ! -L "$_dntf" ]; then rmdir "$_dntf"; fi
  rm -f "$_dntf" "$TMP/dnt-target"
  case "$1" in
    @absent)   ;;
    @dir)      mkdir "$_dntf" ;;
    @dangling) ln -s "$TMP/dnt-no-such-target" "$_dntf" ;;
    @link:*)   printf "${1#@link:}" > "$TMP/dnt-target"; ln -s "$TMP/dnt-target" "$_dntf" ;;
    @big:*)    { _dntfill; printf "${1#@big:}"; } > "$_dntf" ;;
    *)         printf "$1" > "$_dntf" ;;
  esac; }
# "status [stdout]" of a call made in this shell.
_dntrc() { local _dnts _dntv=''
  "$@" > "$TMP/dnt-out" 2>/dev/null; _dnts=$?
  if [ -s "$TMP/dnt-out" ]; then
    { _dntv="$(cat "$TMP/dnt-out"; printf .)"; } 2>/dev/null; _dntv="${_dntv%.}"
    [ "$(LC_ALL=C tr -d '\000' < "$TMP/dnt-out" | LC_ALL=C wc -c)" = "$(LC_ALL=C wc -c < "$TMP/dnt-out")" ] || _dntv="$_dntv<NUL>"
  fi
  printf '%s [%s]' "$_dnts" "$_dntv"; }
# $1 the locale, the rest fixtures: per fixture felix_declared with pipefail
# on, then off, and the fixtures joined by " | ".
_dntmany() { local _dntf _dntsep=''; _dntenv "$1"; shift
  for _dntf in "$@"; do
    _dntput "$_dntf"
    printf '%s%s %s' "$_dntsep" "$(set -o pipefail; _dntrc felix_declared "$CMP")" "$(set +o pipefail; _dntrc felix_declared "$CMP")"
    _dntsep=' | '
  done; }
# NAME, then FIXTURE EXPECTED pairs: one assertion under LC_ALL=C and one
# under the UTF-8 locale.
_dntcheck() { local _dntn="$1" _dntx='' _dntsep=''; local -a _dntfs=(); shift
  while [ "$#" -ge 2 ]; do _dntfs+=("$1"); _dntx="$_dntx$_dntsep$2 $2"; _dntsep=' | '; shift 2; done
  is "$_dntn, under LC_ALL=C" "$(_cm _dntmany C "${_dntfs[@]}")" "$_dntx"
  if [ -n "$_dntu" ]; then is "$_dntn, under a UTF-8 locale" "$(_cm _dntmany utf8 "${_dntfs[@]}")" "$_dntx"
  else skip "$_dntn, under a UTF-8 locale" "no UTF-8 locale here"; fi; }
# Under one locale, the stubbed commands that named the file while
# felix_declared ran once, as [name name].
_dntopens() { local _dntp="$PATH"; _dntenv "$1"; _dntput "$2"; : > "$DNT_LOG"
  PATH="$TMP/dnt-bin:$_dntp"
  felix_declared "$CMP" > /dev/null 2>&1
  PATH="$_dntp"
  printf '[%s]' "$(tr '\n' ' ' < "$DNT_LOG" | sed 's/ $//')"; }
# Under one locale, over 'storage\nbilling\n', with the cat in $TMP/dnt-cat-$2
# first on PATH: felix_declared with pipefail on and off, the status alone
# when $3 is status, then _felix_cap_active storage and felix_declared_into.
_dntcatfail() { local _dntr _dnts _dntv; _dntenv "$1"; _dntput 'storage\nbilling\n'; PATH="$TMP/dnt-cat-$2:$PATH"
  if [ "${3:-}" = status ]; then
    _dntr="$(set -o pipefail; _dntrc felix_declared "$CMP")"; _dnts="$(set +o pipefail; _dntrc felix_declared "$CMP")"
    _dntr="${_dntr%% *} ${_dnts%% *}"
  else
    _dntr="$(set -o pipefail; _dntrc felix_declared "$CMP") $(set +o pipefail; _dntrc felix_declared "$CMP")"
  fi
  _dntv=untouched; felix_declared_into _dntv "$CMP"; _dnts=$?
  printf '%s %s %s|%s|' "$_dntr" "$(_dntrc _felix_cap_active storage "$CMP")" "$_dnts" "$_dntv"; }
_dntcap()  { _dntenv "$1"; _dntput "$2"; _dntrc _felix_cap_active storage "$CMP"; }
_dntinto() { local _dnts _dntv=untouched; _dntenv "$1"; _dntput "$2"
  felix_declared_into _dntv "$CMP"; _dnts=$?; printf '%s|%s|' "$_dnts" "$_dntv"; }
_dntplan() { _dntenv "$1"; _dntput "$2"
  felix_stack_plan "$CMP" 2>/dev/null | awk -F'\t' '$3 == "dnt-skill-absent" { print $1 }'; }
# The caller's state after a call made in this shell, not a substitution.
_dntstate() { local _dntg=glob _dntx=-
  case "$-" in *f*) _dntg=noglob ;; esac
  case "$(export -p)" in *'declare -x LC_ALL='*) _dntx=exported ;; esac
  printf '%s|%s|%s|%s|%s|%s|%s|%s|%s' "${LC_ALL-unset}" "${LC_CTYPE-unset}" "${LANG-unset}" "$_dntx" \
    "${IFS-unset}" "$#" "${1-}" "${2-}" "$_dntg"; }
_dntkeepset() { _dntput "$1"; export LC_ALL="${_dntu:-C}" LC_CTYPE=C LANG="${_dntu:-C}"
  IFS=':'; set -- 'a b' c; set -f
  felix_declared "$CMP" > /dev/null 2>&1; _dntstate "$@"; }
_dntkeepunset() { _dntput "$1"; unset LC_ALL LC_CTYPE LANG IFS; set --; set +f
  felix_declared "$CMP" > /dev/null 2>&1; _dntstate "$@"; }

# Rule 0, unchanged.
_dntcheck "felix_declared over no capabilities file prints nothing and returns 0, and over a directory or a link whose target is gone prints nothing and returns 2" \
  @absent '0 []' @dir '2 []' @dangling '2 []'
_dntcheck "a capabilities link to a regular file is read as that file: its list is printed, and one holding a NUL is no list" \
  '@link:storage\nbilling\n' $'0 [storage\nbilling\n]' '@link:storage\nau\000th\n' '2 []'
is  "a capabilities directory or a link whose target is gone is not opened by any command felix_declared runs" \
    "$(_cm _dntopens C @dir) $(_cm _dntopens C @dangling)" "[] []"
rm -f "$CMP/capabilities"; printf 'storage\n' > "$CMP/capabilities"; chmod 000 "$CMP/capabilities"
if [ -r "$CMP/capabilities" ]; then
  skip "felix_declared over a capabilities file that cannot be opened prints nothing and returns 2, under LC_ALL=C" \
       "the file is readable at mode 000 here, as it is to root"
  skip "felix_declared over a capabilities file that cannot be opened prints nothing and returns 2, under a UTF-8 locale" \
       "the file is readable at mode 000 here, as it is to root"
else
  _dntcheck "felix_declared over a capabilities file that cannot be opened prints nothing and returns 2" @keep '2 []'
fi
chmod 644 "$CMP/capabilities"; rm -f "$CMP/capabilities"

# Rule 1: a NUL byte makes it no list.
_dntcheck "a capabilities file holding a NUL is no list, nothing printed and 2, whether the NUL is its first byte, inside a name, a comment or a blank line, or in a last line with no newline" \
  '\000storage\nbilling\n' '2 []' \
  'storage\nau\000th\nbilling\n' '2 []' \
  'storage\n# a \000 comment\nbilling\n' '2 []' \
  'storage\n \000\t\nbilling\n' '2 []' \
  'storage\n\000\nbilling\n' '2 []' \
  'storage\nbilling\000' '2 []' \
  'storage\nbill\000ing' '2 []' \
  '\000' '2 []'
_dntcheck "a NUL right after a UTF-8 lead byte, or past the first 64 KiB in a name or a comment, makes the file no list too" \
  '\303\000storage\nbilling\n' '2 []' \
  'storage\ncaf\303\000\n' '2 []' \
  '@big:storage\nau\000th\nbilling\n' '2 []' \
  '@big:storage\n# late \000 comment\nbilling\n' '2 []' \
  '@big:storage\nbilling\000' '2 []'
_dntcheck "a UTF-16 capabilities file in either byte order, with its byte-order mark or without, and a UTF-32 one, are no list" \
  '\377\376s\000t\000o\000r\000a\000g\000e\000\n\000' '2 []' \
  's\000t\000o\000r\000a\000g\000e\000\n\000' '2 []' \
  '\376\377\000s\000t\000o\000r\000a\000g\000e\000\n' '2 []' \
  '\000s\000t\000o\000r\000a\000g\000e\000\n' '2 []' \
  '\377\376\000\000s\000\000\000t\000\000\000\n\000\000\000' '2 []' \
  '\000\000\000s\000\000\000t\000\000\000\n' '2 []'

# Rule 2: byte for byte, in the C locale, whatever the caller's.
_dnt2f=('\303\000storage\n' 'storage\n\302\240\nbilling\n' '# caf\351 \377\376 latin-1 in a comment\nstorage\n'
        '\357\273\277storage\nbilling\n' 'storage\ncaf\303\251\n' 'storage\nbil\377ling\n' 'storage\r\nbilling\r\n')
_dnt2x=$'2 [] 2 [] | 2 [] 2 [] | 0 [storage\n] 0 [storage\n] | 0 [storage\nbilling\n] 0 [storage\nbilling\n] | 2 [] 2 [] | 2 [] 2 [] | 2 [] 2 []'
if [ -n "$_dntu" ]; then
  is  "one capabilities file gives one stdout and one status whether LC_ALL is C or the UTF-8 locale, or LC_CTYPE or LANG alone names it" \
      "$(_cm _dntmany C "${_dnt2f[@]}") || $(_cm _dntmany utf8 "${_dnt2f[@]}") || $(_cm _dntmany ctype "${_dnt2f[@]}") || $(_cm _dntmany lang "${_dnt2f[@]}")" \
      "$_dnt2x || $_dnt2x || $_dnt2x || $_dnt2x"
else
  skip "one capabilities file gives one stdout and one status whether LC_ALL is C or the UTF-8 locale, or LC_CTYPE or LANG alone names it" \
       "no UTF-8 locale here"
fi
_dntall=''; _dnti=1
while [ "$_dnti" -le 255 ]; do [ "$_dnti" -eq 10 ] || _dntall="$_dntall$(printf '\\%03o' "$_dnti")"; _dnti=$((_dnti + 1)); done
_dnthigh=''; _dnti=128
while [ "$_dnti" -le 255 ]; do _dnthigh="$_dnthigh$(printf '\\%03o' "$_dnti")"; _dnti=$((_dnti + 1)); done
_dntcheck "no byte sends the read into a binary mode: a comment holding every byte but NUL and newline is skipped and the names after it printed, and a name holding every byte from 200 up is no list, never a Binary file line or a path" \
  "# every byte: $_dntall\nstorage\nbilling\n" $'0 [storage\nbilling\n]' \
  "storage\nx$_dnthigh\n" '2 []'
_dntkx="${_dntu:-C}|C|${_dntu:-C}|exported|:|2|a b|c|noglob"
# Renamed after review: the positional parameters are printed but are no
# evidence, since a function's `set --` never reaches its caller's.
is  "after a call in the current shell the caller's LC_ALL, LC_CTYPE, LANG, IFS and set -f are as they were, over a marked list and over a NUL" \
    "$(_cm _dntkeepset '\357\273\277storage\n') $(_cm _dntkeepset 'storage\nau\000th\n')" "$_dntkx $_dntkx"
is  "and with LC_ALL, LC_CTYPE, LANG and IFS unset and set +f, they stay so" \
    "$(_cm _dntkeepunset '\357\273\277storage\n') $(_cm _dntkeepunset 'storage\nau\000th\n')" \
    "unset|unset|unset|-|unset|0|||glob unset|unset|unset|-|unset|0|||glob"

# Rule 3: a leading byte-order mark is not part of the first line.
_dntcheck "a byte-order mark at the very start is dropped once: before a comment, a blank line or a name the file reads as if it were not there, and alone it is an empty list" \
  '\357\273\277# c\nstorage\n' $'0 [storage\n]' \
  '\357\273\277\nstorage\n' $'0 [storage\n]' \
  '\357\273\277storage\nbilling\n' $'0 [storage\nbilling\n]' \
  '\357\273\277' '0 []'
_dntcheck "the same three bytes anywhere else are bytes of their line: a second mark, or one inside or starting a later line, makes the file no list" \
  '\357\273\277\357\273\277storage\n' '2 []' \
  'storage\n\357\273\277billing\n' '2 []' \
  'storage\n\357\273\277# c\n' '2 []' \
  'stor\357\273\277age\n' '2 []'

# Rule 4: a listed line is tab and printable ASCII, or the file is no list.
_dntcheck "a listed line holding a byte outside tab and printable ASCII makes the whole file no list: a line of only a no-break space, names ending in a CR, a byte from 200 up, DEL" \
  'storage\n\302\240\nbilling\n' '2 []' \
  'storage\r\nbilling\r\n' '2 []' \
  'storage\nbilling\r\n' '2 []' \
  'storage\ncaf\303\251\n' '2 []' \
  'caf\303\251\nstorage\n' '2 []' \
  'storage\nbil\177ling\n' '2 []' \
  'storage\n\377billing\n' '2 []'
_dntcheck "and so does any other control byte in a name: 001, ESC, VT or FF inside it, before it or after it" \
  'storage\nbil\001ling\n' '2 []' \
  'storage\nbil\033ling\n' '2 []' \
  'storage\nbil\013ling\n' '2 []' \
  'storage\nbil\014ling\n' '2 []' \
  'storage\n\033[31mbilling\n' '2 []' \
  'storage\n\014billing\n' '2 []' \
  'storage\nbilling\013\n' '2 []'
_dntpr=''; _dnti=32
while [ "$_dnti" -le 126 ]; do _dntpr="$_dntpr$(printf '\\%03o' "$_dnti")"; _dnti=$((_dnti + 1)); done
_dntcheck "tab and every byte from space to tilde are name bytes: a line holding all of them is printed as it stands" \
  "\t$_dntpr\n" "$(printf "0 [\t$_dntpr\n]")"

# Rule 5: blank and comment lines are skipped byte-wise.
_dntcheck "a comment is skipped whatever it holds but a NUL: an em dash, a no-break space after the #, a CR at its end, control bytes and bytes from 200 up" \
  '# caps \342\200\224 the founder\nstorage\n' $'0 [storage\n]' \
  '  # x\r\nstorage\n' $'0 [storage\n]' \
  '#\302\240x\nstorage\n' $'0 [storage\n]' \
  '# \001\033\177\377\376 x\nstorage\n' $'0 [storage\n]' \
  '\r# led by a CR\n\013# led by a VT\n\014\t # led by an FF and a tab\nstorage\n' $'0 [storage\n]'
_dntcheck "a line of only a CR, only a VT, only an FF, or of spaces, tabs and those, is blank" \
  '\r\nstorage\n' $'0 [storage\n]' \
  '\013\nstorage\n' $'0 [storage\n]' \
  '\014\nstorage\n' $'0 [storage\n]' \
  ' \t\r\013\014 \nstorage\n' $'0 [storage\n]' \
  '\r\n\013\n\014\n' '0 []'
_dntcheck "a # after a no-break space does not make a comment: that line is listed, holds bytes from 200 up, and the file is no list" \
  '\302\240# x\nstorage\n' '2 []' \
  'storage\n\302\240\302\240# x\n' '2 []'

# Rule 6: everything else as before.
_dntcheck "each listed line is printed verbatim in file order, spaces, tabs and an inline remark kept, and a last line with no newline is given one" \
  'deploy   # only staging\n' $'0 [deploy   # only staging\n]' \
  '  storage \t\n\tbilling\n' $'0 [  storage \t\n\tbilling\n]' \
  'zeta\nalpha\nzeta\n' $'0 [zeta\nalpha\nzeta\n]' \
  'storage\nbilling' $'0 [storage\nbilling\n]' \
  '# c\n\nstorage\n  # d\n\nbilling' $'0 [storage\nbilling\n]'
_dntcheck "a capabilities file with no listed line, empty or only comments and blanks, prints nothing and returns 0" \
  '' '0 []' \
  '# only a comment\n\n   \n\t# another\n' '0 []'
_dntcheck "a capabilities file past 64 KiB with no NUL is read whole" \
  '@big:storage\nbilling\n' $'0 [storage\nbilling\n]'

# Rule 7: one read, by cat. The cat failures run under C and under the UTF-8
# locale, or under C twice where there is none.
_dntul=C; [ -n "$_dntu" ] && _dntul=utf8
_dnt7() { printf '%s %s %s %s %s' "$(_cm _dntopens "$1" 'storage\nbilling\n')" "$(_cm _dntopens "$1" '\357\273\277storage\n')" \
            "$(_cm _dntopens "$1" 'storage\nau\000th\n')" "$(_cm _dntopens "$1" 'storage\r\nbilling\r\n')" \
            "$(_cm _dntopens "$1" '@big:storage\n')"; }
is  "the capabilities file is opened once, by cat, and named by no other command felix_declared runs, as a list, with a mark, holding a NUL or a CR, or past 64 KiB, under LC_ALL=C" \
    "$(_dnt7 C)" "[cat] [cat] [cat] [cat] [cat]"
if [ -n "$_dntu" ]; then
  is  "the capabilities file is opened once, by cat, and named by no other command felix_declared runs, under a UTF-8 locale" \
      "$(_dnt7 utf8)" "[cat] [cat] [cat] [cat] [cat]"
else
  skip "the capabilities file is opened once, by cat, and named by no other command felix_declared runs, under a UTF-8 locale" \
       "no UTF-8 locale here"
fi
is  "a cat that prints nothing and fails, as any user, makes felix_declared print nothing and return 2 with pipefail on and off, _felix_cap_active return 2 and felix_declared_into return 2 leaving its variable alone" \
    "$(_cm _dntcatfail C none) $(_cm _dntcatfail "$_dntul" none)" \
    "2 [] 2 [] 2 [] 2|untouched| 2 [] 2 [] 2 [] 2|untouched|"
is  "a cat that prints part of the file and then fails makes felix_declared return 2 whatever it printed, and its readers return 2" \
    "$(_cm _dntcatfail C part status) $(_cm _dntcatfail "$_dntul" part status)" \
    "2 2 2 [] 2|untouched| 2 2 2 [] 2|untouched|"

# Rule 8: its readers follow.
_dnt8() { printf '%s %s %s %s %s' "$(_cm _dntcap "$1" 'storage\nau\000th\nbilling\n')" "$(_cm _dntcap "$1" 'storage\r\nbilling\r\n')" \
            "$(_cm _dntcap "$1" 'storage\ncaf\303\251\n')" "$(_cm _dntcap "$1" '\377\376s\000t\000o\000r\000a\000g\000e\000\n\000')" \
            "$(_cm _dntcap "$1" '\357\273\277storage\n')"; }
is  "_felix_cap_active storage returns 2 over a file holding a NUL, a CR, a byte from 200 up or UTF-16, and 0 over a marked storage, under LC_ALL=C" \
    "$(_dnt8 C)" "2 [] 2 [] 2 [] 2 [] 0 []"
if [ -n "$_dntu" ]; then
  is  "_felix_cap_active storage returns 2 over a file that is no list and 0 over a marked storage, under a UTF-8 locale" \
      "$(_dnt8 utf8)" "2 [] 2 [] 2 [] 2 [] 0 []"
else
  skip "_felix_cap_active storage returns 2 over a file that is no list and 0 over a marked storage, under a UTF-8 locale" \
       "no UTF-8 locale here"
fi
_dntin() { printf '%s %s %s %s' "$(_cm _dntinto "$1" 'storage\nau\000th\nbilling\n')" "$(_cm _dntinto "$1" 'storage\r\nbilling\r\n')" \
             "$(_cm _dntinto "$1" 'storage\n\302\240\nbilling\n')" "$(_cm _dntinto "$1" '\357\273\277storage\nbilling\n')"; }
is  "felix_declared_into returns 2 leaving its variable as the caller had it over a NUL, a CR or a no-break space, and assigns a marked list without its mark, under LC_ALL=C" \
    "$(_dntin C)" $'2|untouched| 2|untouched| 2|untouched| 0|storage\nbilling|'
if [ -n "$_dntu" ]; then
  is  "felix_declared_into returns 2 leaving its variable alone over a file that is no list, and assigns a marked list without its mark, under a UTF-8 locale" \
      "$(_dntin utf8)" $'2|untouched| 2|untouched| 2|untouched| 0|storage\nbilling|'
else
  skip "felix_declared_into returns 2 leaving its variable alone over a file that is no list, and assigns a marked list without its mark, under a UTF-8 locale" \
       "no UTF-8 locale here"
fi
printf '# k\tn\ts\tr\tc\nskill\tdnt-skill-absent\t-\tlow\tstorage\n' > "$CMP/stack.tsv"
_dntsp() { printf '%s %s %s %s %s' "$(_cm _dntplan "$1" 'storage\nau\000th\nbilling\n')" "$(_cm _dntplan "$1" 'storage\r\nbilling\r\n')" \
             "$(_cm _dntplan "$1" 'storage\n')" "$(_cm _dntplan "$1" '\357\273\277storage\n')" "$(_cm _dntplan "$1" 'billing\n')"; }
is  "a stack-plan row grounded on storage reads unknown over a file naming it beside a NUL or with a CR, manual over storage plain or marked, dormant over billing, under LC_ALL=C" \
    "$(_dntsp C)" "unknown unknown manual manual dormant"
if [ -n "$_dntu" ]; then
  is  "a stack-plan row grounded on storage reads unknown over a file that is no list, and as before over a list, under a UTF-8 locale" \
      "$(_dntsp utf8)" "unknown unknown manual manual dormant"
else
  skip "a stack-plan row grounded on storage reads unknown over a file that is no list, and as before over a list, under a UTF-8 locale" \
       "no UTF-8 locale here"
fi

# Added after review, not blind. Each was shown red against a wrong
# implementation the blind block passed (2026-10-08):
# - a split with globbing left on read `*` as the files in the caller's
#   directory, and output through echo lost `-n` and turned `-e` empty;
# - a mark stripped from the first line after the split, or after leading
#   whitespace, instead of from the file's first bytes;
# - the name check stopping at an inline `#`, so a remark's bytes went unread;
# - a NUL decided by a second open of the file (a redirect no PATH stub can
#   see), so what was judged was not what cat printed.
# Not asserted: a { } group in place of the ( ) differs only under lastpipe
# (bash 4.2 and later), and no bash here can show that red.
mkdir -p "$TMP/dnt-glob" "$TMP/dnt-cat-clean" "$TMP/dnt-cat-nul"
: > "$TMP/dnt-glob/storage-x"; : > "$TMP/dnt-glob/stor.bak"; : > "$TMP/dnt-glob/a"; : > "$TMP/dnt-glob/b"
_dntreal="$(type -P cat)"
cat > "$TMP/dnt-cat-clean/cat" <<DNTSTUB
#!/bin/bash
. "$TMP/dnt-isit"
if _dntisit "\$@"; then printf 'storage\nbilling\n'; exit 0; fi
exec "$_dntreal" "\$@"
DNTSTUB
cat > "$TMP/dnt-cat-nul/cat" <<DNTSTUB
#!/bin/bash
. "$TMP/dnt-isit"
if _dntisit "\$@"; then printf 'storage\nau\000th\n'; exit 0; fi
exec "$_dntreal" "\$@"
DNTSTUB
chmod +x "$TMP/dnt-cat-clean/cat" "$TMP/dnt-cat-nul/cat"
_dntglobmany() { cd "$TMP/dnt-glob" || return 1; _dntmany "$@"; }
_dntglobx=$'0 [*\n?\n[a-z]*\nstor*\n-n\n-e\n-E\n%s\n]'
is  "a name that is a glob, reads as an echo option or is a printf format is printed as it stands, never the files it would match, from a directory holding such files, under LC_ALL=C" \
    "$(_cm _dntglobmany C '*\n?\n[a-z]*\nstor*\n-n\n-e\n-E\n%%s\n')" "$_dntglobx $_dntglobx"
if [ -n "$_dntu" ]; then
  is  "a name that is a glob, reads as an echo option or is a printf format is printed as it stands, under a UTF-8 locale" \
      "$(_cm _dntglobmany utf8 '*\n?\n[a-z]*\nstor*\n-n\n-e\n-E\n%%s\n')" "$_dntglobx $_dntglobx"
else
  skip "a name that is a glob, reads as an echo option or is a printf format is printed as it stands, under a UTF-8 locale" "no UTF-8 locale here"
fi
_dntcheck "a mark that is not the file's first bytes is bytes of its line even where a blank line or whitespace comes before it, so the file is no list" \
  '\n\357\273\277storage\n' '2 []' \
  '\n\n\357\273\277# c\nstorage\n' '2 []' \
  ' \357\273\277storage\n' '2 []' \
  '\t\357\273\277storage\n' '2 []'
_dntcheck "an inline remark is part of its listed line: a byte outside tab and printable ASCII in it makes the file no list" \
  'storage   # caf\303\251\n' '2 []' \
  'storage # x\r\n' '2 []' \
  'storage\t# \001\n' '2 []'
_dntcatsays() { _dntenv "$1"; _dntput "$3"; PATH="$TMP/dnt-cat-$2:$PATH"
  printf '%s %s' "$(set -o pipefail; _dntrc felix_declared "$CMP")" "$(set +o pipefail; _dntrc felix_declared "$CMP")"; }
_dntcs="$(_cm _dntcatsays C clean 'storage\nau\000th\n') | $(_cm _dntcatsays C clean 'storage\r\nbilling\r\n') | $(_cm _dntcatsays C clean 'caf\303\251\n')"
_dntcl=$'0 [storage\nbilling\n] 0 [storage\nbilling\n]'
is  "what felix_declared judges is what cat printed: a cat printing a clean list over a file holding a NUL, a CR or a byte from 200 up gives that list" \
    "$_dntcs" "$_dntcl | $_dntcl | $_dntcl"
is  "and a cat printing a NUL over a clean file makes it no list, nothing printed and 2" \
    "$(_cm _dntcatsays C nul 'storage\nbilling\n')" "2 [] 2 []"
# Added after a second review, not blind: a function named cat in the caller,
# a readonly LC_ALL, and a line long enough to show a cost that grows with its
# square. Each was shown red against the guard taken out (2026-10-08).
_dntfuncat() { local _dnts _dntv; _dntenv C; _dntput 'billing\n'
  cat() { printf 'storage\n'; }
  felix_declared "$CMP" > "$TMP/dnt-out" 2>/dev/null; _dnts=$?; unset -f cat
  _dntv="$(command cat "$TMP/dnt-out"; printf .)"; printf '%s [%s]' "$_dnts" "${_dntv%.}"; }
is  "a function named cat in the caller does not stand in for the reader: the file's own list is printed" \
    "$(_cm _dntfuncat)" $'0 [billing\n]'
_dntro() { local _dnts; _dntput 'storage\n'; export LC_ALL="$1"; readonly LC_ALL
  felix_declared "$CMP" > "$TMP/dnt-out" 2> "$TMP/dnt-err"; _dnts=$?
  printf '%s [%s] [%s]' "$_dnts" "$(command cat "$TMP/dnt-out")" "$(command cat "$TMP/dnt-err")"; }
if [ -n "$_dntu" ]; then
  is  "a caller whose LC_ALL is readonly and not C gets 2 with nothing on stdout or stderr, never a read in its own locale" \
      "$(_cm _dntro "$_dntu")" "2 [] []"
else
  skip "a caller whose LC_ALL is readonly and not C gets 2 with nothing on stdout or stderr, never a read in its own locale" \
       "no UTF-8 locale here"
fi
is  "and one whose LC_ALL is readonly C is read as any other caller is" "$(_cm _dntro C)" "0 [storage] []"
# Child CPU from bash's times, in milliseconds, never wall time: load here
# runs to 700.
_dntms() { local _dntm="${1%%m*}" _dnts="${1#*m}" _dntf; _dnts="${_dnts%s}"; _dntf="${_dnts#*.}000"
  printf '%d' $(( (10#$_dntm * 60 + 10#${_dnts%.*}) * 1000 + 10#${_dntf:0:3} )); }
_dntcost() { local _dntw='' _dnti=0 _dntt=0 _dntx
  _dntenv C
  while [ "$_dnti" -lt 5000 ]; do _dntw="${_dntw}x"$'\t'; _dnti=$((_dnti + 1)); done
  { printf 'storage\n%s\n' "$_dntw"; printf '%40000s\n' ''; } > "$CMP/capabilities"
  ( felix_declared "$CMP" > /dev/null 2>&1; times > "$TMP/dnt-times" )
  for _dntx in $(cat "$TMP/dnt-times"); do _dntt=$((_dntt + $(_dntms "$_dntx"))); done
  [ "$_dntt" -lt 1000 ] && printf 'under a second' || printf '%s ms' "$_dntt"; }
is  "a 50 KB file holding a line of 5,000 tabs and a blank line of 40,000 spaces is read in under a second of CPU, where a cost growing with the square of a line took 4.4 s" \
    "$(_cm _dntcost)" "under a second"

rm -f "$CMP/capabilities"
mv "$TMP/dnt-stack.keep" "$CMP/stack.tsv"; mv "$TMP/dnt-cmstub.keep" "$CMSTUB_LOG"
rm -rf "$TMP/dnt-bin" "$TMP/dnt-cat-none" "$TMP/dnt-cat-part" "$TMP/dnt-glob" "$TMP/dnt-cat-clean" "$TMP/dnt-cat-nul"
rm -f "$TMP/dnt-isit" "$TMP/dnt-out" "$TMP/dnt-opens" "$TMP/dnt-target" "$TMP/dnt-no-such-target" \
      "$TMP/dnt-err" "$TMP/dnt-times"
unset -f _dntenv _dntfill _dntput _dntrc _dntmany _dntcheck _dntopens _dntcatfail _dntcap _dntinto _dntplan \
         _dntstate _dntkeepset _dntkeepunset _dnt7 _dnt8 _dntin _dntsp _dntglobmany _dntcatsays \
         _dntfuncat _dntro _dntms _dntcost
unset _dntu _dntul _dntl _dntc _dntreal _dnt2f _dnt2x _dntall _dnthigh _dnti _dntkx _dntpr _dntglobx _dntcs _dntcl
# ---- declared-not-text: end
# The answers below are keyed to the topology taken with api declared.
rm -f "$CMP/capabilities"; printf 'api\n' > "$CMP/capabilities"
_cmlfans $'plugin\tcmlfone\t-\tllm\twhy' $'plugin\tcmlftwo\t-\tllm\twhy' $'done\t0' > "$_cmlfad/cmlf_zero2.tsv"
_cmlfans $'plugin\tcmlfone\t-\tllm\twhy' $'plugin\tcmlftwo\t-\tllm\twhy' $'plugin\tcmlfthree\t-\tllm\twhy' $'done\t2' \
  > "$_cmlfad/cmlf_three.tsv"
is  "unstubbed, an answer saying done 0 over two rows and one saying done 2 over three are partial" \
    "$(_cmlfps none cmlf_zero2 | cut -f1) $(_cmlfps none cmlf_three | cut -f1)" "partial partial"
is  "a count over a first grep that failed is not a count: done 0 over two rows is unknown when that grep printed nothing, not answered" \
    "$(_cmlfps count-first cmlf_zero2 | cut -f1)" "unknown"
is  "and done 2 over three rows is unknown when that grep printed two of them and failed, not answered" \
    "$(_cmlfps count-first-two cmlf_three | cut -f1)" "unknown"
is  "a whole answer whose counting grep printed its count and then failed is unknown, not answered" \
    "$(_cmlfps count-printed cmlf_whole | cut -f1)" "unknown"
is  "a \`[\` that ends the names lookup's own substitution before it answers, at status 0 with no text, makes it return 2 naming nothing" \
    "$(_cmlfpres bracket-exit0 "$_cmlfgone")" "2 []"
# Every descriptor below the limit taken, so the lookup's substitution cannot
# make its pipe however the lookup is spelled. What it printed and returned go
# to a file opened before the limit.
_cmlffd() { ( exec 0</dev/null 1>"$TMP/cmlf-fd.out" 2>/dev/null; ulimit -Sn 10
    for _cmlfd in 3 4 5 6 7 8 9; do eval "exec $_cmlfd</dev/null"; done
    "$@"; printf ' %s' "$?" ); cat "$TMP/cmlf-fd.out"; rm -f "$TMP/cmlf-fd.out"; }
is  "with no descriptor left for its pipe, the names lookup returns 2 and names nothing" \
    "$(_cm _cmlffd _felix_commission_functions_present "$_cmlfgone")" " 2"
_cmlfshape() { local _cmlfb _cmlfr _cmlfg _cmlfn=0 _cmlfp=0
  _cmlfb="$(declare -f "$1")"; _cmlfr="$_cmlfb"
  while :; do case "$_cmlfr" in *'$('*) _cmlfr="${_cmlfr#*\$(}"; _cmlfn=$((_cmlfn + 1)) ;; *) break ;; esac; done
  _cmlfr="$_cmlfb"
  while :; do case "$_cmlfr" in *' | '*) _cmlfr="${_cmlfr#* | }"; _cmlfp=$((_cmlfp + 1)) ;; *) break ;; esac; done
  printf '%s subs %s pipes' "$_cmlfn" "$_cmlfp"
  case "$_cmlfb" in *'<<'*) printf ', a here-document' ;; esac
  case "$_cmlfb" in *'<('*|*'>('*) printf ', a process substitution' ;; esac
  case "$_cmlfb" in *'`'*) printf ', a backquote' ;; esac
  for _cmlfg in $(declare -F | cut -d' ' -f3); do
    case "$_cmlfg" in "$1") continue ;; felix_*|_felix_*|cmd_*) ;; *) continue ;; esac
    case " $_cmlfb " in *[!A-Za-z0-9_]"$_cmlfg"[!A-Za-z0-9_]*) printf ', calls %s' "$_cmlfg" ;; esac
  done
  printf '\n'; }
is  "the capability lookup is one substitution, with no pipe, here-document, process substitution or backquote, calling no engine function but felix_declared" \
    "$(_cm _cmlfshape _felix_cap_active)" "1 subs 0 pipes, calls felix_declared"
is  "and the names lookup is one substitution whose one pipe reads the names, with no here-document, process substitution or backquote, calling no engine function" \
    "$(_cm _cmlfshape _felix_commission_functions_present)" "1 subs 1 pipes"
# The answer is keyed to the topology over this table, which holds it.
_cmtable "$(printf 'cmlf_rcpt\t-\t-\t-\t%s\t-\t4' "$_cmlfprov")" $'cmlf_plain\t-\t-\t-\t-\ttest -f src/a.txt\t9'
_cmlftopo="$(_cm felix_commission_topology "$CMP" "$CMR")"
_cmlfans $'plugin\tcmlfone\t-\tllm\twhy' $'plugin\tcmlftwo\t-\tllm\twhy' $'done\t2' > "$_cmlfad/cmlf_rcpt.tsv"
_cmlfrr0="$(_cm felix_commission_run "$CMP" "$CMR" - 2>/dev/null)"
_cmlfrr1="$(_cm _cmlfstub count felix_commission_run "$CMP" "$CMR" - 2>/dev/null)"
is  "unstubbed, the run over a provider row with a whole answer and a done row reads answered and the receipt is commissioned" \
    "$(_cmlff "$_cmlfrr0" cmlf_rcpt 2) $(_cm felix_commission_receipt_write "$FROOT" "$CMP" "$CMR" "$_cmlfrr0" "")" "answered commissioned"
is  "and with the answer's rows uncountable the provider row is unknown and the receipt indeterminate, not commissioned" \
    "$(_cmlff "$_cmlfrr1" cmlf_rcpt 2) $(_cm felix_commission_receipt_write "$FROOT" "$CMP" "$CMR" "$_cmlfrr1" "")" "unknown indeterminate"

rm -f "$_cmlfad/cmlf_whole.tsv" "$_cmlfad/cmlf_part.tsv" "$_cmlfad/cmlf_zero.tsv" "$_cmlfad/cmlf_twin.tsv" \
      "$_cmlfad/cmlf_zero2.tsv" "$_cmlfad/cmlf_three.tsv" "$_cmlfad/cmlf_rcpt.tsv"
[ -n "$_cmlfmade" ] && rmdir "$_cmlfad"
rm -f "$CMP/capabilities"; [ -f "$TMP/cmlf-caps.keep" ] && mv "$TMP/cmlf-caps.keep" "$CMP/capabilities"
if [ -f "$TMP/cmlf-table.keep" ]; then cp "$TMP/cmlf-table.keep" "$CMP/commissioning.tsv"; else rm -f "$CMP/commissioning.tsv"; fi
if [ -f "$TMP/cmlf-receipt.keep" ]; then mv "$TMP/cmlf-receipt.keep" "$FROOT/state/commission/cmproj"
else rm -f "$FROOT/state/commission/cmproj"; fi
if [ -f "$TMP/cmlf-log.keep" ]; then cp "$TMP/cmlf-log.keep" "$MEM/cmproj/commissioning.log"
else rm -f "$MEM/cmproj/commissioning.log"; fi
rm -f "$TMP/cmlf-table.keep" "$TMP/cmlf-log.keep"
is  "and this block leaves the capabilities, the table, the receipt, the log and every answer file as it found them" \
    "$(_cmlffixture)" "$_cmlffound"
unset -f _cmlffixture _cmlfstub _cmlfrc _cmlff _cmlfsays _cmlfnz _cmlfca _cmlfefn _cmlfpres _cmlfps _cmlfans _cmlfsum _cmlfshape _cmlfkill \
         _cmlffd felix_cmlf_one felix_cmlf_two
unset _cmlfad _cmlffound _cmlfmade _cmlfrun0 _cmlfrun1 _cmlfrun2 _cmlfc3 _cmlfgone _cmlfe0 _cmlfe1 _cmlfe2 \
      _cmlfrr0 _cmlfrr1 _cmlfw _cmlfi _cmlffifo _cmlfp1 _cmlfp3 _cmlfprov _cmlftopo _cmlfpw _cmlflogt _cmlflog0 _cmlflog1 _cmlfrect _cmlfrec1 _cmlfur _cmlfalone
