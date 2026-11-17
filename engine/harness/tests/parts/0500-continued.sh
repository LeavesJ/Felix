# Armed: a declared control that does not hold refuses.
#
# This is the whole of the arming decision. Nothing else binds — a checker with
# no rows is untouched, so the day this landed it could not turn any gate red;
# the one project with rows met every one of them. What it can do is turn red
# the day a checker stops catching what it used to, which is the only moment a
# qualification suite earns its keep.
_qualify_unreadable_probe
_qualify_u8_probe
_qualify_shim_build
_widget_repo_build
cp "$FROOT/projects/widget/qualification.tsv" "$TMP/qual.keep" 2>/dev/null || true
printf 'demo\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt\n' "$_qcheck" \
  > "$FROOT/projects/widget/qualification.tsv"
( cd "$REPO" && "$FELIX" qualify --gate >/dev/null 2>&1 ); _qrc=$?
is "a met control passes the gate check" "$_qrc" "0"
# The same checker, asked to catch something it does not.
printf 'demo\t%s\talternate\tfail\tprintf harmless > other.txt\n' "$_qcheck" \
  >> "$FROOT/projects/widget/qualification.tsv"
_qo="$(cd "$REPO" && "$FELIX" qualify --gate 2>&1)"; _qrc=$?
is  "a held control refuses it"          "$_qrc" "1"
has "and says what a held control means" "$_qo"  "property the tree does not have"
# It must be the control that decides, not merely the presence of a table:
# the first row still passes in the same run.
has "while the control that holds is still reported met" "$_qo" "violation"
# Which of the checks the last gate reported has no row here, read off the
# receipt's roster and not off a roster somebody typed. felix_qualify_ungoverned
# had no caller anywhere in the engine, so the gap it was written to print had
# never been printed, and the count of unqualified checkers was kept by hand in
# a handoff — right until a checker was added.
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" "" "demo:ok,syntax:ok,executable:FAIL,tests:skipped,commission:stale" >/dev/null 2>&1 )
_qo="$(cd "$REPO" && "$FELIX" qualify 2>&1)"
_ql="$(printf '%s\n' "$_qo" | grep 'qualified by no row' || true)"
has "felix qualify names the reported checks no row qualifies" "$_ql" "qualified by no row: commission executable syntax tests"
case "$_ql" in
  *demo*) bad "and not the one a row covers" "$_ql" ;;
  *)      ok  "and not the one a row covers" ;;
esac
# A gap report, not a verdict: --gate is the arming decision, and says nothing
# about a checker nobody has qualified.
case "$(cd "$REPO" && "$FELIX" qualify --gate 2>&1)" in
  *"qualified by no row"*) bad "and --gate does not raise it" ;;
  *)                       ok  "and --gate does not raise it" ;;
esac
# felix qualify --gate read qualification.tsv four times and more in one run:
# the rows, the malformed rows, the rows it ran, and each checker's controls.
# When the first read held and a later one failed, the later status was never
# read, so the run could run no control and still count 0 of 0 held and exit
# 0, and felix gate printed qualified ok over a checker with a held control. A
# table rewritten between reads (a checkout in the same tree) splits a run the
# same way. So --gate makes one read, counted with the wrapper from the
# obligations block, and everything it runs, counts and decides comes from it.
# Without --gate the report may read the table once more, for the roster gap.
_qlgate()  { ( cd "$REPO" && "$FELIX" qualify --gate 2>&1 ); }
_qlplain() { ( cd "$REPO" && "$FELIX" qualify 2>&1 ); }
is  "felix qualify --gate reads qualification.tsv exactly once" "$(_qreads _qlgate)" "1"
_qlpr="$(_qreads _qlplain)"
case "$_qlpr" in
  1|2) ok  "plain felix qualify reads it once for its controls and at most once more for the roster gap" ;;
  *)   bad "plain felix qualify reads it once for its controls and at most once more for the roster gap" "$_qlpr read(s)" ;;
esac
# What a failed read of the table leaves felix qualify saying, whichever read
# it is: exit 2, a line naming the table and saying it could not be read, no
# verdict row and no count, because nothing read means nothing run; and not
# that the table declares no control, which nobody read it to know, nor awk's
# own error. Prints what was wrong, or nothing. Counted with grep -c, not
# grep -q: a printf into grep -q loses the race under pipefail.
_qlwt="/projects/widget/qualification.tsv"
_qlunread() {
  [ "$_qsrc" = 2 ] || printf 'exit %s; ' "$_qsrc"
  [ "$(printf '%s\n' "$_qsout" | grep -F 'could not be read' | grep -cF "$_qlwt")" -ge 1 ] \
    || printf 'no line saying %s could not be read; ' "$_qlwt"
  case "$_qsout" in *"declares no control"*) printf 'says something declares no control; ' ;; esac
  case "$_qsout" in *"awk:"*|*"can't open file"*) printf "shows awk's own error; " ;; esac
  [ "$(printf '%s\n' "$_qsout" | grep -cE '^  [^ ]+ +[a-z_]+ +(pass|fail) +[^ ]+ +(ok|HELD|UNRUNNABLE|n/a)$')" -eq 0 ] \
    || printf 'prints a verdict row; '
  case "$_qsout" in *"control(s) held"*) printf 'prints a held count; ' ;; esac
}
# This read was the one saying which controls demo declares, and it printed
# demo's controls could not be read beside a run it went on to count. That
# assertion is rewritten, not dropped: there is one read now, the last is the
# first, and its failure is the table's, not demo's.
if [ "$_unreadable" -eq 1 ] && _qstage 0 _qlgate; then
  is  "when the last read felix qualify --gate makes of the table fails, it says the table could not be read and exits 2" \
      "$(_qlunread)" ""
  case "$_qsout" in
    *"demo declares no control for:"*)
      bad "and names none of demo's controls missing" "$(printf '%s\n' "$_qsout" | grep 'declares no control for')" ;;
    *) ok  "and names none of demo's controls missing" ;;
  esac
else
  for a in "when the last read felix qualify --gate makes of the table fails, it says the table could not be read and exits 2" \
           "and names none of demo's controls missing"; do
    if [ "$_unreadable" -eq 1 ]; then bad "$a" "$_qsnone"; else skip "$a" "$_noread"; fi; done
fi
# Without --gate the last read is the one that says which reported checks have
# a row, and there both answers the report can give would be false: a gap it
# did not see, or no gap. It said so, and exited 0 as if it had read it.
if [ "$_unreadable" -eq 1 ] && _qstage 0 _qlplain; then
  has "felix qualify says which checks have a row could not be read when that read fails" \
      "$_qsout" "which checks have a row here could not be read"
  _qlc="$(printf '%s\n' "$_qsout" | grep -e 'qualified by no row' -e 'Every check the last gate reported' || true)"
  is  "and claims neither a check no row qualifies nor that every check has one" "$_qlc" ""
  is  "and plain felix qualify exits 2 when the roster gap could not be read" "$_qsrc" "2"
else
  for a in "felix qualify says which checks have a row could not be read when that read fails" \
           "and claims neither a check no row qualifies nor that every check has one" \
           "and plain felix qualify exits 2 when the roster gap could not be read"; do
    if [ "$_unreadable" -eq 1 ]; then bad "$a" "$_qsnone"; else skip "$a" "$_noread"; fi; done
fi
# Every read, from the first. This replaces an assertion that failed each read
# from the second and wanted demo's shortfall or its could-not-be-read line
# each time: with one read there is no second, and the first failing read the
# table as one declaring no control that can be run, which was the old answer
# to read 1 and is false. Each read that fails refuses, exit 2, and says so.
_qlplainsays() {
  [ "$_qsrc" = 2 ] || printf 'exit %s; ' "$_qsrc"
  [ "$(printf '%s\n' "$_qsout" | grep -c 'could not be read')" -ge 1 ] || printf 'nothing says what could not be read; '
  case "$_qsout" in *"awk:"*|*"can't open file"*) printf "shows awk's own error; " ;; esac
}
if [ "$_unreadable" -eq 1 ]; then
  is  "whichever read of the table felix qualify --gate makes fails, it runs nothing, says the table could not be read, and exits 2" \
      "$(_qeach 1 _qlunread _qlgate)" ""
  is  "and whichever read plain felix qualify makes fails, it says what could not be read and exits 2" \
      "$(_qeach 1 _qlplainsays _qlplain)" ""
else
  for a in "whichever read of the table felix qualify --gate makes fails, it runs nothing, says the table could not be read, and exits 2" \
           "and whichever read plain felix qualify makes fails, it says what could not be read and exits 2"; do
    skip "$a" "$_noread"; done
fi
# A table that is not there at a read, or not there after one, or not the
# table it was. Each is staged by awk and cat wrappers counting the reads as
# the ones above do: aside moves the table away for the Kth read and puts it
# back, after moves it away once the Kth read is done and it is put back when
# the run returns, and swap puts another table in its place once the Kth read
# is done. A table gone between reads read as one declaring nothing, because the
# reader returns early on a table that is not a file, and the rest of the run
# ran nothing and passed. The table here has a met control and a held one, so
# every right answer refuses.
_QMSHIM="$TMP/awk-shim-moves"; mkdir -p "$_QMSHIM"
for _qsn in $_qsreaders; do
  _qsreal="$(command -v "$_qsn")"
  cat > "$_QMSHIM/$_qsn" <<EOF
#!/bin/sh
for a in "\$@"; do
  case "\$a" in
    qualification.tsv|*/qualification.tsv)
      printf x >> "\$QSHIM_COUNT"
      if [ "\$((\$(wc -c < "\$QSHIM_COUNT")))" -eq "\${QSHIM_FAIL:-0}" ]; then
        case "\$QSHIM_MODE" in
          aside) mv "\$a" "\$a.aside"; "$_qsreal" "\$@"; rc=\$?; mv "\$a.aside" "\$a"; exit \$rc ;;
          after) "$_qsreal" "\$@"; rc=\$?; mv "\$a" "\$a.gone"; exit \$rc ;;
          swap)  "$_qsreal" "\$@"; rc=\$?; cp "\$a" "\$a.was"; cp "\$QSHIM_WITH" "\$a"; exit \$rc ;;
        esac
      fi
      break ;;
  esac
done
exec "$_qsreal" "\$@"
EOF
  chmod +x "$_QMSHIM/$_qsn"
done
# _qmeach MODE PRED CMD...: CMD with each of its reads, in turn, staged by MODE,
# and the widget table put back after each; PRED as for _qeach.
_qmeach() {
  local mode="$1" pred="$2" n k said; shift 2
  n="$(_qreads "$@")"
  [ "$n" -ge 1 ] || { printf 'a clean run made no read of the table by name\n'; return 0; }
  k=1
  while [ "$k" -le "$n" ]; do
    : > "$_QSC"
    _qsout="$( PATH="$_QMSHIM:$PATH"; QSHIM_COUNT="$_QSC"; QSHIM_FAIL="$k"; QSHIM_MODE="$mode"
               QSHIM_WITH="$TMP/qual-swap-with"
               export PATH QSHIM_COUNT QSHIM_FAIL QSHIM_MODE QSHIM_WITH; "$@" 2>"$_QSE" )"; _qsrc=$?
    [ -f "$_qlw.gone" ] && mv "$_qlw.gone" "$_qlw"
    [ -f "$_qlw.was" ] && mv "$_qlw.was" "$_qlw"
    if [ "$(( $(wc -c < "$_QSC") ))" -lt "$k" ]; then printf 'read %s of %s: never reached\n' "$k" "$n"
    else said="$("$pred")"; [ -z "$said" ] || printf 'read %s of %s: %s\n' "$k" "$n" "$said"; fi
    k=$((k + 1))
  done
}
_qlrefused() { [ "$_qsrc" != 0 ] || printf 'exit 0'; }
_qlheld() {
  [ "$_qsrc" = 1 ] || printf 'exit %s; ' "$_qsrc"
  [ "$(printf '%s\n' "$_qsout" | grep -cE ' alternate .*HELD$')" -ge 1 ] || printf 'the held control is not shown; '
}
cp "$_qlw" "$TMP/qual-moves.keep"
printf 'demo\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt\n' "$_qcheck" > "$TMP/qual-swap-with"
is  "a table moved away for any one read felix qualify --gate makes never passes it" \
    "$(_qmeach aside _qlrefused _qlgate)" ""
is  "a table gone after any read felix qualify --gate makes never passes it" \
    "$(_qmeach after _qlrefused _qlgate)" ""
is  "a table rewritten to one that passes, after any read felix qualify --gate makes, leaves the run it read refusing on its held control" \
    "$(_qmeach swap _qlheld _qlgate)" ""
is  "and the widget table is put back after each" "$(cmp -s "$_qlw" "$TMP/qual-moves.keep" && echo same || echo changed)" "same"
# BSD cut in a UTF-8 locale stops at the first byte it cannot decode, and a
# mutation may hold one. The checkers listed with it stopped there, and every
# checker after that row went unreported, silently.
if [ -n "$_u8" ]; then
  cp "$FROOT/projects/widget/qualification.tsv" "$TMP/qual-u8.keep"
  { printf 'aaa\tfalse\tviolation\tfail\tprintf caf\351 > x\n'; cat "$TMP/qual-u8.keep"; } \
    > "$FROOT/projects/widget/qualification.tsv"
  has "in a UTF-8 locale, a row holding a byte that is not UTF-8 hides no checker after it from felix qualify" \
      "$( export LC_ALL="$_u8"; _qlgate )" "  demo declares no control for: "
  cp "$TMP/qual-u8.keep" "$FROOT/projects/widget/qualification.tsv"
else
  skip "in a UTF-8 locale, a row holding a byte that is not UTF-8 hides no checker after it from felix qualify" "$_u8none"
fi
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" "" "" >/dev/null 2>&1 )
has "a receipt with no roster is said to have none, never read as nothing left" \
    "$(cd "$REPO" && "$FELIX" qualify 2>&1)" "carries no roster"
# A malformed row refuses too. It was written as a control, so by the ratchet
# it binds, and it is never run, so it cannot be met. It sits beside a control
# that is met, so the malformed row is what decides.
{ printf 'demo\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt\n' "$_qcheck"
  printf 'demo\t%s\tviolation\tpass\ttrue\n' "$_qcheck"
} > "$FROOT/projects/widget/qualification.tsv"
_qo="$(cd "$REPO" && "$FELIX" qualify --gate 2>&1)"; _qrc=$?
is  "a violation row expecting pass refuses --gate rather than counting as met" "$_qrc" "1"
has "and --gate names the row and the verdict its control demands" \
    "$_qo" "MALFORMED  violation must expect fail, not [pass]"
# With no control left to run, the report still says which rows and why,
# rather than reading as a table that declares nothing.
printf 'demo\t%s\tviolation\tpass\ttrue\n' "$_qcheck" > "$FROOT/projects/widget/qualification.tsv"
_qo="$(cd "$REPO" && "$FELIX" qualify --gate 2>&1)"; _qrc=$?
is  "a table whose every row is malformed refuses --gate" "$_qrc" "1"
has "and names the rows it could not read" "$_qo" "MALFORMED"
# A held row the reader dropped. Behind a tab it was skipped as a blank line,
# and after a bare carriage return it rode in the met row's unread fields; either
# way it never ran and was never refused, and --gate passed on the met row.
{ printf 'demo\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt\n' "$_qcheck"
  printf '\tdemo\ttrue\talternate\tfail\ttrue\n'; } > "$_qlw"
_qo="$(_qlgate)"; _qrc=$?
is  "a held row with a tab in front of it refuses --gate, named malformed" \
    "$_qrc:$(printf '%s\n' "$_qo" | grep -c 'MALFORMED  no checker name$')" "1:1"
printf 'demo\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt\rdemo\ttrue\talternate\tfail\ttrue\r' "$_qcheck" > "$_qlw"
_qo="$(_qlgate)"; _qrc=$?
is  "and so does a held row after a bare carriage return" \
    "$_qrc:$(printf '%s\n' "$_qo" | grep -c 'MALFORMED  a carriage return')" "1:1"
# And a held row, or a met one, behind a NUL byte, which awk ends the line at:
# the held row skipped as blank, a mutation or a premise cut short and met, and
# --gate passing on what was left. The table holding a NUL is refused whole,
# the met control on its clean line included: nothing runs, no verdict row or
# held count is printed, a felix: line names the table and says it holds a
# NUL, and felix qualify exits 2. Not that the table declares no control, and
# not that it could not be read: both are false of a table read to the end.
# Each table's twin, the NUL taken out, reads as before, so a refusal here is
# the NUL's and not the fixture's. The tables are _qznul's, from the needs block.
cp "$_qlw" "$TMP/qual-nul.keep"
_qlnul() {
  [ "$_qsrc" = 2 ] || printf 'exit %s; ' "$_qsrc"
  [ "$(printf '%s\n' "$_qsout" | grep '^felix: ' | grep -F "$_qlwt" | grep -c 'NUL')" -ge 1 ] \
    || printf 'no felix: line saying %s holds a NUL; ' "$_qlwt"
  case "$_qsout" in *"declares no control"*) printf 'says the table declares no control; ' ;; esac
  case "$_qsout" in *"could not be read"*) printf 'says something could not be read; ' ;; esac
  [ "$(printf '%s\n' "$_qsout" | grep -cE '^  [^ ]+ +[a-z_]+ +(pass|fail) +[^ ]+ +(ok|HELD|UNRUNNABLE|n/a)$')" -eq 0 ] \
    || printf 'prints a verdict row; '
  case "$_qsout" in *"control(s) held"*) printf 'prints a held count; ' ;; esac
  [ ! -e "$_qzmark" ] || printf 'ran a control; '
}
for _qzw in $_qzwhere; do
  _qznul "$_qzw" > "$_qlw"; rm -f "$_qzmark"
  _qsout="$(_qlgate)"; _qsrc=$?
  is  "felix qualify --gate over a table with $(_qzsaid "$_qzw") runs no control, says on a felix: line naming the table that it holds a NUL, and exits 2" \
      "$(_qlnul)" ""
done
_qlnulplain() {
  local w said
  for w in $_qzwhere; do
    _qznul "$w" > "$_qlw"; rm -f "$_qzmark"
    _qsout="$(_qlplain)"; _qsrc=$?
    said="$(_qlnul)"; [ -z "$said" ] || printf '%s: %s\n' "$w" "$said"
  done
}
is  "and plain felix qualify over each of those tables runs no control, says the table holds a NUL, and exits 2" \
    "$(_qlnulplain)" ""
# The twins: a held row HELD and a premise that errors UNRUNNABLE, each
# refusing with exit 1, and a table whose NUL sat on a blank or comment line
# passing, each having run demo's met control.
_qltwin() {
  local w want row said
  for w in $_qzwhere; do
    case "$w" in
      field)         want=1; row='^  held +violation +fail +unrunnable +UNRUNNABLE$' ;;
      alone|comment) want=0; row='^  demo +violation +fail +fail +ok$' ;;
      *)             want=1; row='^  held +violation +fail +pass +HELD$' ;;
    esac
    _qznul "$w" clean > "$_qlw"; rm -f "$_qzmark"
    _qsout="$(_qlgate)"; _qsrc=$?
    said=""
    [ "$_qsrc" = "$want" ] || said="${said}exit $_qsrc, not $want; "
    [ "$(printf '%s\n' "$_qsout" | grep -cE "$row")" = 1 ] || said="${said}no row matching $row; "
    [ -e "$_qzmark" ] || said="${said}demo's met control never ran; "
    [ -z "$said" ] || printf '%s: %s\n' "$w" "$said"
  done
}
is  "each of those tables with its NUL taken out reads through felix qualify --gate as before, refusing on its held or unrunnable row and passing when the NUL sat on a blank or comment line" \
    "$(_qltwin)" ""
# Whole, not by the line: a NUL in a comment between two met controls on clean
# lines refuses the table, and neither control runs, where the same table
# without the NUL passes having run both.
_qlboth() {   # [clean]: exit:runs of felix qualify --gate over two met controls with a comment between
  { printf 'demo\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt\n' "printf x >> '$_qzmark'; $_qcheck"
    printf '# between the two'; [ "${1:-}" = clean ] || printf '\000'; printf ' met controls\n'
    printf 'demo\t%s\trestoration\tpass\ttrue\n' "printf x >> '$_qzmark'; $_qcheck"; } > "$_qlw"
  rm -f "$_qzmark"; ( cd "$REPO" && "$FELIX" qualify --gate >/dev/null 2>&1 ); _qsrc=$?
  printf '%s:%s' "$_qsrc" "$( [ -e "$_qzmark" ] && wc -c < "$_qzmark" | tr -d ' ' || printf 0 )"
}
is  "a NUL refuses the whole table: with it in a comment between two met controls on clean lines neither runs and --gate exits 2, where without it both run and pass" \
    "nul $(_qlboth) twin $(_qlboth clean)" "nul 2:0 twin 0:2"
# One read, NUL or no NUL, counted by the wrapper from the obligations block.
_qlnulreads() {
  local w
  for w in $_qzwhere; do
    _qznul "$w" > "$_qlw";       printf '%s %s' "$w" "$(_qreads _qlgate)"
    _qznul "$w" clean > "$_qlw"; printf '/%s ' "$(_qreads _qlgate)"
  done
}
is  "felix qualify --gate opens a table holding a NUL exactly once, and its twin without the NUL once" \
    "$(_qlnulreads)" "start 1/1 row 1/1 field 1/1 alone 1/1 comment 1/1 far 1/1 "
# A table at mode 000 is still one that could not be read, never one said to
# hold a NUL, which nobody read it to know.
_qlnot() { case "$_qsout" in *NUL*) printf 'says NUL; ' ;; esac; }
if [ "$_unreadable" -eq 1 ]; then
  _qznul start clean > "$_qlw"
  chmod 000 "$_qlw"; _qsout="$(_qlgate)"; _qsrc=$?; chmod 644 "$_qlw"
  is  "felix qualify --gate over a table at mode 000 still says it could not be read, never that it holds a NUL, and exits 2" \
      "$(_qlunread)$(_qlnot)" ""
else
  skip "felix qualify --gate over a table at mode 000 still says it could not be read, never that it holds a NUL, and exits 2" "$_noread"
fi
# A NUL right after a byte that starts a UTF-8 character. bash 4 to 5.2 read
# the byte after a lead byte as the rest of the character without asking
# whether it is the delimiter, so in a UTF-8 locale `\303\000` hid the NUL
# from the read: it ran on to the end of input, said it found none, and every
# row after it was dropped with a status of 0, a held one included. Found by
# review on 2026-09-25; the reader pins the C locale for its read. macOS's
# bash 3.2 never had the flaw, so this fails only on a newer bash, which is
# what Linux CI runs.
_qlu8="$_u8"
[ -n "$_qlu8" ] || _qlu8="$(locale -a 2>/dev/null | awk '/^C\.(UTF-8|utf8)$/ && !n++')"
_qllead() {   # [clean]: a met row, a comment ending in a lead byte and a NUL, a held row
  printf 'demo\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt\n' "$_qcheck"
  printf '# reviewed by Jos\303'; [ "${1:-}" = clean ] || printf '\000'; printf '\n'
  printf 'held\ttrue\tviolation\tfail\ttrue\n'
}
if [ -n "$_qlu8" ]; then
  _qllead > "$_qlw"; rm -f "$_qzmark"
  _qsout="$( export LC_ALL="$_qlu8"; _qlgate )"; _qsrc=$?
  is  "in a UTF-8 locale, felix qualify --gate over a table with a NUL right after a UTF-8 lead byte runs no control, says it holds a NUL, and exits 2" \
      "$(_qlnul)" ""
  _qlrows="$( export LC_ALL="$_qlu8"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
              felix_qualify_rows "$FROOT/projects/widget" 2>/dev/null )"; _qlrc=$?
  is  "and in that locale the library reads no row of it and exits non-zero" \
      "$([ "$_qlrc" -ne 0 ] && printf refused || printf 'exit 0')$([ -z "$_qlrows" ] || printf ', rows read')" "refused"
  _qllead clean > "$_qlw"
  _qsout="$( export LC_ALL="$_qlu8"; _qlgate )"; _qsrc=$?
  is  "and without the NUL the same table runs, refusing --gate on the held row after the lead byte" \
      "$_qsrc:$(printf '%s\n' "$_qsout" | grep -cE '^  held +violation +fail +pass +HELD$')" "1:1"
else
  for a in "in a UTF-8 locale, felix qualify --gate over a table with a NUL right after a UTF-8 lead byte runs no control, says it holds a NUL, and exits 2" \
           "and in that locale the library reads no row of it and exits non-zero" \
           "and without the NUL the same table runs, refusing --gate on the held row after the lead byte"; do
    skip "$a" "no UTF-8 locale is installed here"; done
fi
cp "$TMP/qual-nul.keep" "$_qlw"
# A present, empty table is a table declaring no control, and refuses as it
# always has; the tests below it change what a table nobody read says, not this.
: > "$_qlw"
_qo="$(cd "$REPO" && "$FELIX" qualify --gate 2>&1)"; _qrc=$?
is  "a present, empty table refuses felix qualify --gate, as before" "$_qrc" "1"
has "and says it declares no control that can be run" "$_qo" "declares no control that can be run"
( cd "$REPO" && "$FELIX" qualify >/dev/null 2>&1 ); _qrc=$?
is  "and plain felix qualify over it returns 1, as before" "$_qrc" "1"

# A table that cannot be read from the start. It refused, but it said the table
# declares no control that can be run, which nobody read it to know, and showed
# awk's own error. Mode 000 stages it.
{ printf 'demo\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt\n' "$_qcheck"
  printf 'demo\t%s\talternate\tfail\tprintf harmless > other.txt\n' "$_qcheck"; } > "$_qlw"
if [ "$_unreadable" -eq 1 ]; then
  chmod 000 "$_qlw"
  _qsout="$(_qlgate)"; _qsrc=$?
  is  "felix qualify --gate over a table it cannot read runs nothing, says it could not be read naming it, and exits 2" \
      "$(_qlunread)" ""
  _qsout="$(_qlplain)"; _qsrc=$?
  is  "and plain felix qualify over it does the same" "$(_qlunread)" ""
  chmod 644 "$_qlw"
else
  for a in "felix qualify --gate over a table it cannot read runs nothing, says it could not be read naming it, and exits 2" \
           "and plain felix qualify over it does the same"; do skip "$a" "$_noread"; done
fi

# A run that dies part way. It counted what it had: a run killed after one of
# two met controls said 1 of 1, and one killed before its first said 0 of 0,
# and both exited 0. git is wrapped so that the Kth worktree add kills a
# process of the felix CLI above it and then fails. The processes from that git
# up to the CLI itself all run the CLI's command line, a subshell for each
# $(...), so they are walked up while they do; the one QKILL_BELOW (1 unless
# said) below the CLI is killed. Under felix qualify that is the row loop; under
# felix gate the one below the CLI is felix qualify --gate itself, and the one
# below that its row loop. It never kills the CLI, nor the suite, and leaves a
# mark when it has killed, so a run it never reached is a failure and not a
# pass. Both controls are met, so the death is the only reason to refuse.
_qualify_gshim_build
_qkill() {   # K: felix qualify --gate with its Kth worktree add killing the row loop
  : > "$_QSC"; rm -f "$_QSC.killed"
  _qsout="$( cd "$REPO" && PATH="$_QGSHIM:$PATH" QKILL_COUNT="$_QSC" QKILL_AT="$1" \
             QKILL_FELIX="$FELIX" QKILL_SPARE="$$" "$FELIX" qualify --gate 2>&1 )"; _qsrc=$?
  [ -s "$_QSC.killed" ]
}
{ printf 'demo\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt\n' "$_qcheck"
  printf 'demo\t%s\trestoration\tpass\ttrue\n' "$_qcheck"; } > "$_qlw"
( cd "$REPO" && "$FELIX" qualify --gate >/dev/null 2>&1 ); _qrc=$?
is  "two met controls pass --gate when nothing cuts the run short" "$_qrc" "0"
if _qkill 1; then
  [ "$_qsrc" != 0 ] && ok "a felix qualify --gate run killed at its first control refuses, never counting none of none as met" \
                    || bad "a felix qualify --gate run killed at its first control refuses, never counting none of none as met" "$_qsout"
else bad "a felix qualify --gate run killed at its first control refuses, never counting none of none as met" "$_qknone"; fi
if _qkill 2; then
  [ "$_qsrc" != 0 ] && ok "and one killed at its second refuses, never counting one met as the table" \
                    || bad "and one killed at its second refuses, never counting one met as the table" "$_qsout"
  # When the kill reached the CLI itself it died, and a CLI that died has
  # nothing left to say; the line is asked of a run that lived to report.
  if [ "$_qsrc" -ge 128 ]; then
    skip "and says it ran 1 of the 2 controls, exiting 1" "the kill reached the felix CLI itself, exit $_qsrc"
  else
    _qk="$(printf '%s\n' "$_qsout" | awk '/(^|[^0-9])1 of [^0-9]*2([^0-9]|$)/ && /ran/')"
    [ "$_qsrc" = 1 ] && [ -n "$_qk" ] && ok "and says it ran 1 of the 2 controls, exiting 1" \
      || bad "and says it ran 1 of the 2 controls, exiting 1" "exit $_qsrc: $(printf '%s' "$_qsout" | tr '\n' '/')"
  fi
else
  for a in "and one killed at its second refuses, never counting one met as the table" \
           "and says it ran 1 of the 2 controls, exiting 1"; do bad "$a" "$_qknone"; done
fi
# A checker named with no row ran nothing, and 0 of 0 held passed the gate.
_qsout="$(cd "$REPO" && "$FELIX" qualify --gate nobody 2>&1)"; _qsrc=$?
_qk="$(printf '%s\n' "$_qsout" | awk '/nobody/ && (/no control/ || /no row/)')"
[ "$_qsrc" = 1 ] && [ -n "$_qk" ] \
  && ok  "felix qualify --gate naming a checker with no row refuses, and says no control is declared for it" \
  || bad "felix qualify --gate naming a checker with no row refuses, and says no control is declared for it" \
         "exit $_qsrc: $(printf '%s' "$_qsout" | tr '\n' '/')"

# The stdin case above, through the CLI: the checker that read to the end took
# the held row with it, and the gate passed.
{ printf 'demo\tcat >/dev/null; false\tviolation\tfail\ttrue\n'
  printf 'demo\ttrue\tviolation\tfail\ttrue\n'; } > "$_qlw"
_qsout="$(_qlgate)"; _qsrc=$?
is  "felix qualify --gate refuses a held row after a checker that reads its stdin" "$_qsrc" "1"
is  "and shows that row held" "$(printf '%s\n' "$_qsout" | grep -cE '^  demo +violation +fail +pass +HELD$')" "1"

