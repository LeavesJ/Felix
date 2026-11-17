printf '\nqualification: does a check fail when what it protects is broken\n'
# v3.2's conformance amendments call this the largest gap in the spec. Every
# layer above narrows what a model may WRITE; none asks whether the checker
# judging the writing works, and a check that passes over a violation is worse
# than no check because the report says the property holds.
QLP="$TMP/qualproj"; QLR="$TMP/qualrepo"; mkdir -p "$QLP" "$QLR" "$MEM/qualproj"
( _fx_cd "$QLR" && git init -q -b main && printf 'clean\n' > a.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
QLR="$(cd "$QLR" && pwd -P)"
_ql() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
          felix_qualify_run "$QLP" "$QLR" "$@" ); }
is "a project declaring no qualification qualifies nothing" \
   "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
       felix_qualify_rows "$QLP" | wc -l | tr -d ' ')" "0"
# A checker that does what it claims, and one control it does not catch. Both
# in one table, because a suite that only ever shows `met` cannot tell a
# working runner from one that reports met unconditionally.
_qc='! grep -rqI FORBIDDEN . 2>/dev/null'
{ printf 'demo\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt\n' "$_qc"
  printf 'demo\t%s\trestoration\tpass\ttrue\n' "$_qc"
  printf 'demo\t%s\talternate\tfail\tprintf harmless > other.txt\n' "$_qc"
} > "$QLP/qualification.tsv"
_qo="$(_ql)"
has "a control the checker meets is met" \
    "$(printf '%s\n' "$_qo" | awk -F'\t' '$2 == "violation" { print $5 }')" "met"
has "and one it passes over is held, not silently counted"  \
    "$(printf '%s\n' "$_qo" | awk -F'\t' '$2 == "alternate" { print $5 }')" "held"
is  "a control needing no mutation still runs"  \
    "$(printf '%s\n' "$_qo" | awk -F'\t' '$2 == "restoration" { print $5 }')" "met"
# The tree the mutations ran in is thrown away, or the next control inherits
# the last one's violation and every verdict after the first is about the
# wrong tree.
is  "each control runs against a tree of its own" \
    "$([ -f "$QLR/bad.txt" ] && echo leaked || echo clean)" "clean"
# Four of six is not qualified, and the two usually missing are the two that
# separate the marker from the property.
_qm="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
        felix_qualify_missing_controls "$QLP" demo | tr '\n' ' ')"
has "the controls a checker declares nothing for are named" "$_qm" "decoupled_violation"
has "including the one that stops reject-everything winning" "$_qm" "decoupled_satisfaction"
case "$_qm" in
  *violation*) : ;; *) bad "and a declared control is not reported missing" "$_qm" ;;
esac
case " $_qm " in
  *" restoration "*) bad "and a declared control is not reported missing" "$_qm" ;;
  *)                 ok  "and a declared control is not reported missing" ;;
esac
# Membership is a read of the table, never a race with it. A declared control
# was once reported missing when grep -q found it and left before the printf
# feeding it had finished, and pipefail turned the writer's SIGPIPE into "not
# found". A list longer than a pipe holds makes that certain: twenty thousand
# violation rows, then one row for each other control, written by one awk.
QBP="$TMP/qual-big"; mkdir -p "$QBP"
awk 'BEGIN { for (i = 0; i < 20000; i++) print "big\ttrue\tviolation\tfail\ttrue"
             n = split("restoration:pass irrelevant:pass alternate:fail decoupled_violation:fail decoupled_satisfaction:pass", c, " ")
             for (i = 1; i <= n; i++) { split(c[i], kv, ":"); print "big\ttrue\t" kv[1] "\t" kv[2] "\ttrue" } }' \
  > "$QBP/qualification.tsv"
_qmc() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
           felix_qualify_missing_controls "$@"; printf 'rc=%s' "$?" ) 2>"$TMP/qmc.err"; }
is  "a checker with twenty thousand violation rows before its other five controls is missing none" \
    "$(_qmc "$QBP" big | tr '\n' ' ')" "rc=0"
is  "and none without the caller's pipefail either" "$(set +o pipefail; _qmc "$QBP" big | tr '\n' ' ')" "rc=0"
# The same line did the same in felix_qualify_ungoverned, against the list of
# every checker the table declares: a reported name that sorts first is the one
# grep finds on its first line. Twenty thousand checkers, named in letters,
# because the gate line a name is read from takes no digit.
QGV="$TMP/qual-many"; mkdir -p "$QGV"
awk 'BEGIN { print "alpha\ttrue\tviolation\tfail\ttrue"
             for (i = 0; i < 20000; i++) {
               s = i ""; n = ""
               for (j = 1; j <= length(s); j++) n = n substr("abcdefghij", substr(s, j, 1) + 1, 1)
               print "zz-" n "\ttrue\tviolation\tfail\ttrue" } }' > "$QGV/qualification.tsv"
_qgv="$(printf '  alpha              ok\n  omega              FAIL\n')"
_qug() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
           felix_qualify_ungoverned "$@"; printf 'rc=%s' "$?" ) 2>"$TMP/qug.err"; }
is  "a reported checker with a row is never called unqualified among twenty thousand, and one with none still is" \
    "$(_qug "$QGV" "$_qgv" | tr '\n' ' ')" "omega rc=0"
# Membership is of a whole name, never part of one. violation is part of
# decoupled_violation, so a match on parts reads a checker declaring only the
# two decoupled controls as declaring the one with teeth; and a reported alpha
# would read as qualified by a row for alphabet.
QDC="$TMP/qual-parts"; mkdir -p "$QDC"
{ printf 'dec\ttrue\tdecoupled_violation\tfail\ttrue\n'
  printf 'dec\ttrue\tdecoupled_satisfaction\tpass\ttrue\n'
  printf 'alphabet\ttrue\tviolation\tfail\ttrue\n'; } > "$QDC/qualification.tsv"
is  "a checker declaring only the two decoupled controls is missing violation and the three others" \
    "$(_qmc "$QDC" dec | tr '\n' ' ')" "violation restoration irrelevant alternate rc=0"
is  "and a reported checker whose name is part of a declared one's is still unqualified" \
    "$(_qug "$QDC" "$(printf '  alpha              ok\n')" | tr '\n' ' ')" "alpha rc=0"
# A byte that is not UTF-8, in a mutation, leaves a row a row. BSD cut in a
# UTF-8 locale stops at it with "Illegal byte sequence", and ungoverned read
# that as a table it could not read: a false cause, every time, for such a
# table. Where no en_US UTF-8 locale is installed there is nothing to show.
_qualify_u8_probe
QL8="$TMP/qual-not-utf8"; mkdir -p "$QL8"
{ printf 'alpha\ttrue\tviolation\tfail\tprintf caf\351 > x\n'
  printf 'beta\ttrue\tviolation\tfail\ttrue\n'; } > "$QL8/qualification.tsv"
if [ -n "$_u8" ]; then
  is  "in a UTF-8 locale, a row holding a byte that is not UTF-8 is read, and ungoverned names only the unqualified" \
      "$( export LC_ALL="$_u8"; _qug "$QL8" "$(printf '  alpha  ok\n  beta  ok\n  omega  ok\n')" | tr '\n' ' ')" "omega rc=0"
else
  skip "in a UTF-8 locale, a row holding a byte that is not UTF-8 is read, and ungoverned names only the unqualified" "$_u8none"
fi
# A table that exists and cannot be read is said, not resolved. Read as empty it
# named all six controls missing and every reported checker unqualified: what a
# table declaring nothing says, said about one nobody read.
_qualify_unreadable_probe
QUT="$TMP/qual-unreadable"; mkdir -p "$QUT"
printf 'alpha\ttrue\tviolation\tfail\ttrue\n' > "$QUT/qualification.tsv"
if [ "$_unreadable" -eq 1 ]; then
  chmod 000 "$QUT/qualification.tsv"
  is  "a table that cannot be read names no control missing, rather than all six, and exits 2" \
      "$(_qmc "$QUT" alpha | tr '\n' ' ')" "rc=2"
  has "and missing_controls says on stderr which table could not be read" \
      "$(grep 'could not be read' "$TMP/qmc.err")" "$QUT/qualification.tsv"
  is  "and that is the one line missing_controls writes there" "$(grep -c . "$TMP/qmc.err")" "1"
  is  "and missing_controls says so without the caller's pipefail" \
      "$(set +o pipefail; _qmc "$QUT" alpha | tr '\n' ' ')" "rc=2"
  is  "ungoverned over a table that cannot be read names no reported checker, and exits 2" \
      "$(_qug "$QUT" "$_qgv" | tr '\n' ' ')" "rc=2"
  has "and ungoverned says on stderr which table could not be read" \
      "$(grep 'could not be read' "$TMP/qug.err")" "$QUT/qualification.tsv"
  is  "and that is the one line ungoverned writes there" "$(grep -c . "$TMP/qug.err")" "1"
  is  "and ungoverned says so without the caller's pipefail" \
      "$(set +o pipefail; _qug "$QUT" "$_qgv" | tr '\n' ' ')" "rc=2"
  chmod 644 "$QUT/qualification.tsv"
else
  for a in "a table that cannot be read names no control missing, rather than all six, and exits 2" \
           "and missing_controls says on stderr which table could not be read" \
           "and that is the one line missing_controls writes there" \
           "and missing_controls says so without the caller's pipefail" \
           "ungoverned over a table that cannot be read names no reported checker, and exits 2" \
           "and ungoverned says on stderr which table could not be read" \
           "and that is the one line ungoverned writes there" \
           "and ungoverned says so without the caller's pipefail"; do skip "$a" "$_noread"; done
fi
# No table at all is an answer, and stays one: nothing is declared.
is  "with no qualification.tsv at all a checker is missing all six, and that exits 0" \
    "$(_qmc "$TMP/no-such-proj" alpha | tr '\n' ' ')" \
    "violation restoration irrelevant alternate decoupled_violation decoupled_satisfaction rc=0"
is  "and every reported checker is unqualified, and that exits 0" \
    "$(_qug "$TMP/no-such-proj" "$_qgv" | tr '\n' ' ')" "alpha omega rc=0"
# A row that names a checker and not enough to run one is a control nobody is
# applying, and silence about it reads as a control that passed.
printf 'demo\tonly-two\n' >> "$QLP/qualification.tsv"
has "a row too short to run anything is reported, not skipped" \
    "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
        felix_qualify_malformed "$QLP")" "demo"
# A line was skipped as blank when its first field was empty, so a row with a
# tab in front of it was never run and never called malformed. A table whose
# lines end in a bare carriage return is one line to awk, and every row after
# the first rode in fields past the sixth, which nothing reads. A checker that
# is not an id was split in two, or expanded to the files of the checkout, by
# what walks the checkers. Each is malformed now, and each table here holds a
# row that would otherwise run, so a reader that runs it or skips it says so.
QRD="$TMP/qual-reader"; mkdir -p "$QRD"
_qrd() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
           printf 'rows=%s ' "$(felix_qualify_rows "$QRD" | wc -l | tr -d ' ')"
           felix_qualify_malformed "$QRD" | tr '\t\n' '| ' ) 2>/dev/null; }
printf '\tdemo\ttrue\tviolation\tfail\ttrue\n' > "$QRD/qualification.tsv"
is  "a row with a tab in front of its checker is malformed, never skipped as a blank line" \
    "$(_qrd)" "rows=0 |no checker name "
printf 'demo\ttrue\tviolation\tfail\ttrue\rdemo\ttrue\talternate\tfail\ttrue\r' > "$QRD/qualification.tsv"
is  "a table whose lines end in a bare carriage return is malformed, never one row with the rest unread" \
    "$(_qrd)" "rows=0 demo|a carriage return; a row ends at a newline alone "
printf 'demo\ttrue\tviolation\tfail\ttrue\r\n' > "$QRD/qualification.tsv"
is  "and so is a row ending in a carriage return and a newline" \
    "$(_qrd)" "rows=0 demo|a carriage return; a row ends at a newline alone "
printf 'demo\ttrue\tviolation\tfail\ttrue\t-\ttrue\n' > "$QRD/qualification.tsv"
is  "a row of more than six fields is malformed" \
    "$(_qrd)" "rows=0 demo|7 field(s); a control has five, or six with a premise "
{ for _qrn in 'my check' '*' 'Demo' 'HELDOUT' '9lives' '-x'; do
    printf '%s\ttrue\tviolation\tfail\ttrue\n' "$_qrn"; done; } > "$QRD/qualification.tsv"
is  "a checker that is not an id is malformed, a space, a glob, a capital, a digit or a dash first" \
    "$( ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
          felix_qualify_malformed "$QRD" ) 2>/dev/null | grep -c 'is not a checker name')" "6"
is  "and none of those rows is run" "$(_qrd | cut -d' ' -f1)" "rows=0"
# What is still skipped, by the whole line: a blank one, spaces and tabs
# included, and a comment, with or without a tab in front of it.
{ printf '\n   \n\t\n# a comment\n  # indented\n\t# behind a tab\n'
  printf 'my-check_2\ttrue\tviolation\tfail\ttrue\t-\n'; } > "$QRD/qualification.tsv"
is  "a blank line and a comment are still skipped, and an id with digits, _ and - is a checker" \
    "$(_qrd)" "rows=1 "
# A NUL byte anywhere in the table, through the readers that answer for one.
# Each prints nothing, says in one stderr line which table holds a NUL, and
# exits 2, with the caller's pipefail and without; the three the others are
# built on exit non-zero. Every table has a met control on a clean line, so a
# reader that refuses only the line with the NUL in it still ran something.
# The tables are _qznul's, from the needs block.
QZL="$TMP/qual-nul"; mkdir -p "$QZL"
_qzl() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
           "$@"; printf 'rc=%s' "$?" ) 2>"$TMP/qzl.err"; }
# _qzeach PRED CMD...: CMD over each NUL table, PRED handed its output with the
# stderr in qzl.err; a line for each table PRED finds the result wrong for.
_qzeach() {
  local pred="$1" w out said; shift
  for w in $_qzwhere; do
    _qznul "$w" > "$QZL/qualification.tsv"; rm -f "$_qzmark"
    out="$("$@")"
    said="$("$pred" "$out")"; [ -z "$said" ] || printf '%s: %s\n' "$w" "$said"
  done
}
_qzrefused() {
  [ "$1" = rc=2 ] || printf 'printed [%s]; ' "$(printf '%s' "$1" | tr '\n\t' '/ ')"
  { [ "$(grep -c . "$TMP/qzl.err")" = 1 ] \
      && [ "$(grep -F "$QZL/qualification.tsv" "$TMP/qzl.err" | grep -c 'NUL')" = 1 ]; } \
    || printf 'stderr [%s]; ' "$(tr '\n' '/' < "$TMP/qzl.err")"
  [ ! -e "$_qzmark" ] || printf 'ran a control; '
}
_qzgv="$(printf '  demo  ok\n  held  ok\n  omega  ok\n')"
is  "felix_qualify_missing_controls over a table holding a NUL byte anywhere prints nothing, exits 2, and says in one stderr line naming the table that it holds a NUL" \
    "$(_qzeach _qzrefused _qzl felix_qualify_missing_controls "$QZL" demo)" ""
is  "and missing_controls refuses it so without the caller's pipefail" \
    "$(set +o pipefail; _qzeach _qzrefused _qzl felix_qualify_missing_controls "$QZL" demo)" ""
is  "felix_qualify_run over a table holding a NUL byte anywhere runs nothing, prints nothing, exits 2, and says in one stderr line naming the table that it holds a NUL" \
    "$(_qzeach _qzrefused _qzl felix_qualify_run "$QZL" "$QLR")" ""
is  "and felix_qualify_run refuses it so without the caller's pipefail" \
    "$(set +o pipefail; _qzeach _qzrefused _qzl felix_qualify_run "$QZL" "$QLR")" ""
is  "felix_qualify_ungoverned over a table holding a NUL byte anywhere names no checker, exits 2, and says in one stderr line naming the table that it holds a NUL" \
    "$(_qzeach _qzrefused _qzl felix_qualify_ungoverned "$QZL" "$_qzgv")" ""
is  "and ungoverned refuses it so without the caller's pipefail" \
    "$(set +o pipefail; _qzeach _qzrefused _qzl felix_qualify_ungoverned "$QZL" "$_qzgv")" ""
_qzraw() {
  local r s
  for r in felix_qualify_rows felix_qualify_malformed felix_qualify_snapshot; do
    s="$( ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
            "$r" "$QZL" >/dev/null 2>&1; printf '%s' "$?" ) )"
    [ "$s" != 0 ] || printf '%s exits 0; ' "$r"
  done
}
is  "felix_qualify_rows, felix_qualify_malformed and felix_qualify_snapshot each exit non-zero over a table holding a NUL byte anywhere, with the caller's pipefail and without" \
    "$(_qzeach _qzraw :)$(set +o pipefail; _qzeach _qzraw : | sed 's/^/without pipefail, /')" ""
# The twin of each, the NUL taken out, reads as the rows it holds: the held row
# held, the erroring premise unrunnable, the blank and the comment skipped.
_qztwin() {
  local w
  for w in $_qzwhere; do
    _qznul "$w" clean > "$QZL/qualification.tsv"
    printf '%s:%s ' "$w" "$(_qzl felix_qualify_run "$QZL" "$QLR" | awk -F'\t' 'NF >= 5 { printf "%s ", $5 } /^rc=/ { print }')"
  done
}
is  "each NUL table's twin, the NUL taken out, is run by the library as before, every row of it, and exits 0" "$(_qztwin)" \
    "start:met held rc=0 row:met held rc=0 field:met unrunnable rc=0 alone:met rc=0 comment:met rc=0 far:met held rc=0 "
# Anywhere is past a pipe's 64 KB too: the big table above, a NUL on a line of
# its own after its last row.
QZB="$TMP/qual-nul-big"; mkdir -p "$QZB"
{ cat "$QBP/qualification.tsv"; printf '\000\n'; } > "$QZB/qualification.tsv"
_qzbig="$(_qzl felix_qualify_missing_controls "$QZB" big)"
is  "a NUL after more than a pipe's 64 KB of rows refuses the table all the same, in one stderr line naming it" \
    "$_qzbig:$(grep -c . "$TMP/qzl.err"):$(grep -F "$QZB/qualification.tsv" "$TMP/qzl.err" | grep -c 'NUL')" "rc=2:1:1"
# A table with no NUL reads exactly as before, byte for byte: the same rows and
# the same malformed rows, with a mutation holding a byte that is not UTF-8,
# backslashes, spaces around a field, a premise, blank lines and comments
# skipped, a carriage return malformed, and a last line with no newline read
# as a row. What refuses a NUL must not be what reads the rest.
QZ7="$TMP/qual-no-nul"; mkdir -p "$QZ7"
_qz5() { printf '%s\t%s\t%s\t%s\t%s\n' "$@"; }
{ printf '\n   \n# a comment\n\t# behind a tab\n'
  printf 'alpha\ttrue\tviolation\tfail\tprintf caf\351 > x\n'
  _qz5 beta true violation fail 'printf "a\b\\c\t" > y'
  _qz5 gamma '  true  ' violation fail '  printf x > z  '
  printf 'eps\ttrue\tviolation\tfail\ttrue\r\n'
  printf 'delta\ttrue\tviolation\tfail\ttrue\t test -f a.txt \n'
  printf 'zeta\tonly-two\n'
  printf 'omega\ttrue\tviolation\tfail\ttrue'; } > "$QZ7/qualification.tsv"
{ printf 'alpha\ttrue\tviolation\tfail\tprintf caf\351 > x\n'
  _qz5 beta true violation fail 'printf "a\b\\c\t" > y'
  _qz5 gamma '  true  ' violation fail '  printf x > z  '
  printf 'delta\ttrue\tviolation\tfail\ttrue\t test -f a.txt \n'
  printf 'omega\ttrue\tviolation\tfail\ttrue\n'; } > "$TMP/qz7.rows"
printf 'eps\ta carriage return; a row ends at a newline alone\nzeta\t2 field(s); a control needs five\n' > "$TMP/qz7.mal"
{ LC_ALL=C awk 'NR <= 3 { print "R\t" $0 }' "$TMP/qz7.rows"
  LC_ALL=C awk 'NR == 1 { print "M\t" $0 }' "$TMP/qz7.mal"
  LC_ALL=C awk 'NR == 4 { print "R\t" $0 }' "$TMP/qz7.rows"
  LC_ALL=C awk 'NR == 2 { print "M\t" $0 }' "$TMP/qz7.mal"
  LC_ALL=C awk 'NR == 5 { print "R\t" $0 }' "$TMP/qz7.rows"; } > "$TMP/qz7.snap"
_qz7() {   # locale, or empty for the suite's own: what reads otherwise than before
  ( [ -z "$1" ] || export LC_ALL="$1"
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
    felix_qualify_rows      "$QZ7" > "$TMP/qz7.rows.got" 2>/dev/null; r=$?
    felix_qualify_malformed "$QZ7" > "$TMP/qz7.mal.got"  2>/dev/null; m=$?
    felix_qualify_snapshot  "$QZ7" > "$TMP/qz7.snap.got" 2>/dev/null; s=$?
    [ "$r $m $s" = "0 0 0" ] || printf 'exit %s %s %s; ' "$r" "$m" "$s"
    cmp -s "$TMP/qz7.rows.got" "$TMP/qz7.rows" || printf 'rows differ; '
    cmp -s "$TMP/qz7.mal.got"  "$TMP/qz7.mal"  || printf 'malformed rows differ; '
    cmp -s "$TMP/qz7.snap.got" "$TMP/qz7.snap" || printf 'snapshot differs; ' )
}
is  "a table with no NUL is read byte for byte as before: its rows, its malformed rows and its snapshot" "$(_qz7 '')" ""
is  "and a table with no NUL is read so in the C locale as well" "$(_qz7 C)" ""
if [ -n "$_u8" ]; then
  is  "and so in a UTF-8 locale, a mutation holding a byte that is not UTF-8 included" "$(_qz7 "$_u8")" ""
else
  skip "and so in a UTF-8 locale, a mutation holding a byte that is not UTF-8 included" "$_u8none"
fi
_qzbig7() {
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
    felix_qualify_rows     "$QBP" > "$TMP/qzbig.rows" 2>/dev/null || printf 'rows exit non-zero; '
    felix_qualify_snapshot "$QBP" > "$TMP/qzbig.snap" 2>/dev/null || printf 'snapshot exits non-zero; ' )
  LC_ALL=C awk '{ print "R\t" $0 }' "$QBP/qualification.tsv" > "$TMP/qzbig.want"
  cmp -s "$TMP/qzbig.rows" "$QBP/qualification.tsv" || printf 'rows differ; '
  cmp -s "$TMP/qzbig.snap" "$TMP/qzbig.want"       || printf 'snapshot differs; '
}
is  "a table larger than a pipe's 64 KB with no NUL is read byte for byte, every row and the snapshot" "$(_qzbig7)" ""
_qzgone() {
  local r
  for r in felix_qualify_rows felix_qualify_malformed felix_qualify_snapshot; do
    printf '%s:%s ' "$r" "$(_qzl "$r" "$TMP/no-such-proj")"
  done
  printf 'run:%s' "$(_qzl felix_qualify_run "$TMP/no-such-proj" "$QLR")"
}
is  "with no qualification.tsv at all, rows, malformed, snapshot and the runner print nothing and exit 0" "$(_qzgone)" \
    "felix_qualify_rows:rc=0 felix_qualify_malformed:rc=0 felix_qualify_snapshot:rc=0 run:rc=0"
# And a table that cannot be read is still that, never one said to hold a NUL,
# which nobody read it to know.
_qzunread() {
  [ "$1" = rc=2 ] || printf 'printed [%s]; ' "$(printf '%s' "$1" | tr '\n\t' '/ ')"
  [ "$(grep -F "$QUT/qualification.tsv" "$TMP/qzl.err" | grep -c 'could not be read')" = 1 ] \
    || printf 'no line saying the table could not be read; '
  [ "$(grep -c 'NUL' "$TMP/qzl.err")" = 0 ] || printf 'says NUL; '
}
if [ "$_unreadable" -eq 1 ]; then
  chmod 000 "$QUT/qualification.tsv"
  _qzu="missing:$(_qzunread "$(_qzl felix_qualify_missing_controls "$QUT" alpha)") run:$(_qzunread "$(_qzl felix_qualify_run "$QUT" "$QLR")") ungoverned:$(_qzunread "$(_qzl felix_qualify_ungoverned "$QUT" "$_qgv")")"
  chmod 644 "$QUT/qualification.tsv"
  is  "a table at mode 000 is still one that could not be read, never one said to hold a NUL, and each reader exits 2" \
      "$_qzu" "missing: run: ungoverned:"
else
  skip "a table at mode 000 is still one that could not be read, never one said to hold a NUL, and each reader exits 2" "$_noread"
fi

# The verdict is the control's, not the row's. `expect` was free text, so a
# violation row expecting `pass` over a mutation that changed nothing ran,
# passed, and was counted met: a control that tests nothing, reported as one
# that held. A contract review found it on 2026-09-22. Every control is written
# here with the verdict it may not have, beside a row pairing it rightly, so
# silence about the right rows is measured against noise about the wrong ones.
QMP="$TMP/qualmal"; mkdir -p "$QMP"
{ for _qmc in violation alternate decoupled_violation; do
    printf 'wrong-%s\t%s\t%s\tpass\ttrue\n' "$_qmc" "$_qc" "$_qmc"
    printf 'right\t%s\t%s\tfail\tprintf FORBIDDEN > bad.txt\n' "$_qc" "$_qmc"
  done
  for _qmc in restoration irrelevant decoupled_satisfaction; do
    printf 'wrong-%s\t%s\t%s\tfail\ttrue\n' "$_qmc" "$_qc" "$_qmc"
    printf 'right\t%s\t%s\tpass\ttrue\n' "$_qc" "$_qmc"
  done
  printf 'misspelt\t%s\tviolaton\tfail\tprintf FORBIDDEN > bad.txt\n' "$_qc"
  printf 'noop\t%s\tviolation\tpass\ttrue\n' "$_qc"
} > "$QMP/qualification.tsv"
_qmm="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
         felix_qualify_malformed "$QMP" )"
for _qmc in violation alternate decoupled_violation restoration irrelevant decoupled_satisfaction; do
  has "a row for $_qmc given the verdict it may not have is malformed" "$_qmm" "wrong-$_qmc	"
done
has "and the report says which verdict the control demands" "$_qmm" "violation must expect fail, not [pass]"
case "$_qmm" in
  *right*) bad "while a row pairing each control with its own verdict is not" "$_qmm" ;;
  *)       ok  "while a row pairing each control with its own verdict is not" ;;
esac
# One misspelt letter would otherwise take a row out of the rule: a control
# that is none of the six has no verdict to be held to.
has "a control that is not one of the six is malformed" "$_qmm" "misspelt	[violaton] is not one of the six controls"
# The case the review measured. Before this, the row ran and was met.
is  "a violation row expecting pass over a no-op mutation is never run, so never met" \
    "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
        felix_qualify_run "$QMP" "$QLR" noop )" ""
is  "while every rightly paired row still runs and is met" \
    "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
        felix_qualify_run "$QMP" "$QLR" right | awk -F'\t' '$5 == "met"' | wc -l | tr -d ' ')" "6"

# A checker or a mutation that reads its stdin read the rows. They reached the
# loop that ran them through a pipe, and each row's commands inherited it, so a
# checker that read to the end swallowed every row after its own: a met row and
# then a held one ran only the met one, one line of met, and the gate read one
# control met of one. Each is now given nothing to read. The held row comes
# second, so a run that stops after the first has nothing held to say, and the
# verdicts are read in order, so two lines of anything else do not pass.
QSI="$TMP/qual-stdin"; mkdir -p "$QSI"
_qsi() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
           felix_qualify_run "$QSI" "$QLR" ) 2>/dev/null | cut -f5 | tr '\n' ' '; }
{ printf 'demo\tcat >/dev/null; false\tviolation\tfail\ttrue\n'
  printf 'demo\ttrue\tviolation\tfail\ttrue\n'; } > "$QSI/qualification.tsv"
is  "a checker that reads its stdin leaves the row after it to run, and that row is held" \
    "$(_qsi)" "met held "
{ printf 'demo\t%s\tviolation\tfail\tcat >/dev/null; printf FORBIDDEN > bad.txt\n' "$_qc"
  printf 'demo\ttrue\tviolation\tfail\ttrue\n'; } > "$QSI/qualification.tsv"
is  "and so does a mutation that reads its stdin" "$(_qsi)" "met held "
# The premise was already given nothing to read; this keeps it so.
{ printf 'demo\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt\tcat >/dev/null\n' "$_qc"
  printf 'demo\ttrue\tviolation\tfail\ttrue\n'; } > "$QSI/qualification.tsv"
is  "and so does a premise that reads its stdin" "$(_qsi)" "met held "
# The rows reach the loop by no pipe now, so a command reading stdin would find
# none of them whether or not it is given /dev/null. What giving it /dev/null
# does is shown by handing the runner a line to read: a checker that passes
# only at end of input, and a mutation that stages the violation only there,
# each come out as with nothing to read.
_qsin() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
            printf 'x\n' | felix_qualify_run "$QSI" "$QLR" ) 2>/dev/null | cut -f4,5 | tr '\t\n' '  '; }
printf 'demo\t! read -r _\tviolation\tfail\ttrue\n' > "$QSI/qualification.tsv"
is  "a checker reads nothing, even with a line waiting on felix's own stdin" "$(_qsin)" "pass held "
printf 'demo\t%s\tviolation\tfail\tread -r _ || printf FORBIDDEN > bad.txt\n' "$_qc" > "$QSI/qualification.tsv"
is  "and nor does a mutation" "$(_qsin)" "fail met "
# The runner's own read of a table that cannot be read. Its status was a
# pipeline's, so with the caller's pipefail it said 2 and without it said 0,
# having run nothing: the empty run a table declaring nothing makes.
if [ "$_unreadable" -eq 1 ]; then
  chmod 000 "$QSI/qualification.tsv"
  _qsir() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
              felix_qualify_run "$QSI" "$QLR"; printf 'rc=%s' "$?" ) 2>/dev/null; }
  is  "felix_qualify_run over a table it cannot read runs nothing and exits 2, with the caller's pipefail and without" \
      "$(_qsir) $(set +o pipefail; _qsir)" "rc=2 rc=2"
  chmod 644 "$QSI/qualification.tsv"
else
  skip "felix_qualify_run over a table it cannot read runs nothing and exits 2, with the caller's pipefail and without" "$_noread"
fi

