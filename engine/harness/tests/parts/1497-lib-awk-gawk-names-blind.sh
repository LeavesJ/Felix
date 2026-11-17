# >>> lib-awk-gawk-names-blind
printf '\nno gawk builtin name in the awk of lib/*.sh: the _awk_names lint (contract B12, B9.42, blind)\n'
# Written blind on 2026-10-19 from docs/2026-10-18-lost-work-page-contract.md
# alone: B12's "Tests" items 1 to 6, which B9.42 points at. _awk_names is
# defined in tests/lib/awk-names.sh, which did not exist when this was written;
# every run below goes through _an97_run, which records a status of "undefined"
# when the function is not there, so each assertion still runs and fails.
#
# A run's rows are read as B12's output table gives them: name FILE LINE IDENT,
# unread FILE LINE WHAT, open FILE LINE WHAT, then programs N last. WHAT is free
# text, so an unread or open row is compared on its kind, file and line only.
# Each fixture below is its own file under this part's temporary directory and
# its own run, so a row can only come from the form that fixture holds; FILE is
# the path as given, and every path given here is absolute. input.txt and the
# other files the fixtures name are never read: the lint reads text and runs
# nothing.
AN97="$TMP/awk-names-1497"; AN97F="$AN97/f"; AN97O="$AN97/out"; AN97L="$AN97/lib-rt"
mkdir -p "$AN97F" "$AN97O" "$AN97L"

# _an97_run NAME FILE...: _awk_names FILE... in a subshell, its stdout, stderr and status in $AN97O/NAME.*
_an97_run() {
  local n="$1"; shift
  if declare -F _awk_names >/dev/null 2>&1; then
    ( _awk_names "$@" ) < /dev/null > "$AN97O/$n.out" 2> "$AN97O/$n.err"
    printf '%s\n' "$?" > "$AN97O/$n.rc"
  else
    printf 'no _awk_names: tests/lib/awk-names.sh does not define it\n' > "$AN97O/$n.out"
    : > "$AN97O/$n.err"; printf 'undefined\n' > "$AN97O/$n.rc"
  fi
}
_an97_join() { LC_ALL=C awk '{ printf "%s%s", (NR > 1 ? " ; " : ""), $0 }'; }
# _an97_got NAME: "STATUS|ROWS", the rows other than programs as name:FILE:LINE:IDENT
# or KIND:FILE:LINE, sorted, each once, joined by " ; ".
_an97_got() {
  printf '%s|%s' "$(cat "$AN97O/$1.rc" 2>/dev/null)" "$(LC_ALL=C awk -F'\t' '
      NF == 0 || $1 == "programs" { next }
      $1 == "name" { print $1 ":" $2 ":" $3 ":" $4; next }
      { print $1 ":" $2 ":" $3 }' "$AN97O/$1.out" 2>/dev/null | LC_ALL=C sort -u | _an97_join)"
}
# _an97_want ROW...: the same rows as _an97_got prints them.
_an97_want() { printf '%s\n' "$@" | LC_ALL=C sort -u | _an97_join; }
# _an97_last NAME: "last" when the run printed one programs row, a whole number, as its last row.
_an97_last() {
  LC_ALL=C awk -F'\t' '
    NF == 0 { next }
    { n++; last = $0 }
    $1 == "programs" { p++; if (NF == 2 && $2 ~ /^[0123456789]+$/) pl = n }
    END { if (p == 1 && pl == n && n > 0) print "last"; else printf "not last: %d programs rows, last row [%s]\n", p, last }' "$AN97O/$1.out" 2>/dev/null
}
# _an97_n NAME: the N of the run's programs row, or nothing.
_an97_n() { LC_ALL=C awk -F'\t' '$1 == "programs" && NF == 2 && $2 ~ /^[0123456789]+$/ { n = $2 } END { print n }' "$AN97O/$1.out" 2>/dev/null; }
# _an97_put NAME: stdin to the fixture file NAME.
_an97_put() { cat > "$AN97F/$1"; }

# ---- item 1: lib/*.sh, read together ------------------------------------------------
_an97_run lib "$REAL_HARNESS"/lib/*.sh
_an97_l1="$(_an97_got lib)"
is "B12.1: on engine/harness/lib/*.sh read together, _awk_names exits 0 and prints no name, unread or open row" "${_an97_l1:0:600}" "0|"
_an97_k="$(_an97_n lib)"
is "B12.1: and it reads at least 200 programs, said on its last row" \
   "$(_an97_last lib)|$(case "$_an97_k" in ('') printf 'no count' ;; (*) if [ "$_an97_k" -ge 200 ]; then printf 'at least 200'; else printf '%s' "$_an97_k"; fi ;; esac)" \
   "last|at least 200"

# ---- item 2: the defect replayed -------------------------------------------------------
# The same files, copied, with every RTAG in the copy of lost-work.sh written RT.
cp "$REAL_HARNESS"/lib/*.sh "$AN97L/" 2>/dev/null
LC_ALL=C sed 's/RTAG/RT/g' "$REAL_HARNESS/lib/lost-work.sh" > "$AN97L/lost-work.sh" 2>/dev/null
_an97_run librt "$AN97L"/*.sh
is "B12.2: with RTAG written RT in a copy of lib/lost-work.sh, _awk_names over the copies exits 1" "$(cat "$AN97O/librt.rc" 2>/dev/null)" 1
is "B12.2: and every name row it prints is for that copy and RT" \
   "$(LC_ALL=C awk -F'\t' '$1 == "name" { print $2 ":" $4 }' "$AN97O/librt.out" 2>/dev/null | LC_ALL=C sort -u | _an97_join)" "$AN97L/lost-work.sh:RT"
_an97_ng="$(LC_ALL=C awk 'index($0, "n = ++NG[g]") { printf "%s%s", s, FNR; s = " " }' "$AN97L/lost-work.sh" 2>/dev/null)"
_an97_on="$(LC_ALL=C awk -F'\t' -v f="$AN97L/lost-work.sh" -v ls=" $_an97_ng " '$1 == "name" && $2 == f && $4 == "RT" && index(ls, " " $3 " ") { y = 1 } END { print (y ? "on it" : "not on it") }' "$AN97O/librt.out" 2>/dev/null)"
is "B12.2: and one of them stands on the line of that copy's n = ++NG[g]" "${_an97_ng:-no such line}|$_an97_on" "$_an97_ng|on it"

# ---- item 3: each form is caught, on the identifier's line -------------------------------
_an97_put inline.sh <<'AN97A'
# inline.sh: an inline program
awk '{ print RT }' input.txt
AN97A
_an97_put lines.sh <<'AN97A'
# lines.sh: one program across lines
awk '
  { n++ }
  END { print n, FPAT }
' input.txt
AN97A
_an97_put assign.sh <<'AN97A'
# assign.sh: after an assignment
LC_ALL=C awk '{ print IGNORECASE }' input.txt
AN97A
_an97_put bang.sh <<'AN97A'
# bang.sh: after the bang word
! awk 'BEGIN { print ARGIND }'
AN97A
_an97_put if.sh <<'AN97A'
# if.sh: after if
if awk 'BEGIN { exit BINMODE }' input.txt; then
  printf 'yes\n'
fi
AN97A
_an97_put then.sh <<'AN97A'
# then.sh: after then
if [ -f input.txt ]
then awk 'BEGIN { print LINT }' input.txt
fi
AN97A
_an97_put brace.sh <<'AN97A'
# brace.sh: after an opening brace
{ awk 'BEGIN { print PREC }'; }
AN97A
_an97_put xargs.sh <<'AN97A'
# xargs.sh: under xargs -0
printf '%s\0' input.txt | xargs -0 awk '{ print ROUNDMODE }'
AN97A
_an97_put subst.sh <<'AN97A'
# subst.sh: in a command substitution inside double quotes
printf 'rows: %s\n' "$(awk 'END { print SYMTAB }' input.txt)"
AN97A
_an97_put heredoc.sh <<'AN97A'
# heredoc.sh: in a command substitution in an unquoted here-document body
cat <<EOT
total: $(awk 'END { print TEXTDOMAIN }' input.txt)
EOT
AN97A
_an97_put prog-g1.sh <<'AN97A'
# prog-g1.sh: a program assigned here and run in prog-g2.sh
PROG_G='{ print FIELDWIDTHS }'
AN97A
_an97_put prog-g2.sh <<'AN97A'
# prog-g2.sh: an awk command whose program another file assigns

awk "$PROG_G" input.txt
AN97A
_an97_put local.sh <<'AN97A'
# local.sh: a program assigned with local
count_h() {
  local prog_h='{ a[NR] = $0 } END { n = asort(a); print n }'
  awk "$prog_h" input.txt
}
count_h
AN97A
_an97_put joined.sh <<'AN97A'
# joined.sh: a program joined from a variable and a single-quoted part
JOIN_I='BEGIN { m = lshift(1, 4) } '
awk "$JOIN_I"'{ print rshift($1, 1) }' input.txt
AN97A
_an97_put chained.sh <<'AN97A'
# chained.sh: a variable assigned from another
BASE_J='{ print strtonum($1) }'
PROG_J="$BASE_J"
awk "$PROG_J" input.txt
AN97A
_an97_put func.sh <<'AN97A'
# func.sh: the second argument of a function, passed by its callers
run_k() {
  LC_ALL=C awk "$2" "$1"
}
run_k input.txt '{ print typeof($1) }'
run_k other.txt '{ print isarray(seen) }'
AN97A
_an97_put v.sh <<'AN97A'
# v.sh: a listed name as the variable of -v
awk -v RT=1 'BEGIN { print "set" }'
AN97A
_an97_put errno.sh <<'AN97A'
# errno.sh: ERRNO as an awk variable
awk 'END { print ERRNO }' input.txt
AN97A
_an97_put procinfo.sh <<'AN97A'
# procinfo.sh: PROCINFO as an array
awk 'BEGIN { print PROCINFO["version"] }'
AN97A
_an97_put and.sh <<'AN97A'
# and.sh: and as a call
awk '{ print and($1, 1) }' input.txt
AN97A
_an97_put mktime.sh <<'AN97A'
# mktime.sh: mktime as a call
awk 'BEGIN { print mktime("2026 10 19 0 0 0") }'
AN97A
_an97_put or.sh <<'AN97A'
# or.sh: or as a parameter name
awk 'function pick(v, or) { return v } { print pick($1, 2) }' input.txt
AN97A
for _an97_x in inline lines assign bang if then brace xargs subst heredoc local joined chained func v errno procinfo and mktime or; do
  _an97_run "$_an97_x" "$AN97F/$_an97_x.sh"
done
_an97_run other "$AN97F/prog-g2.sh" "$AN97F/prog-g1.sh"
# _an97_case NAME RUN ROW...: the run exits 1 and its rows are ROW... exactly.
_an97_case() { is "$1" "$(_an97_got "$2")" "1|$(shift 2; _an97_want "$@")"; }
_an97_case "B12.3: an inline program: its name row on the identifier's line, exit 1" inline "name:$AN97F/inline.sh:2:RT"
_an97_case "B12.3: a program across lines: the row is on the line the identifier stands on, not the line awk is on" lines "name:$AN97F/lines.sh:4:FPAT"
_an97_case "B12.3: a program after LC_ALL=C is caught" assign "name:$AN97F/assign.sh:2:IGNORECASE"
_an97_case "B12.3: a program after ! is caught" bang "name:$AN97F/bang.sh:2:ARGIND"
_an97_case "B12.3: a program after if is caught" if "name:$AN97F/if.sh:2:BINMODE"
_an97_case "B12.3: a program after then is caught" then "name:$AN97F/then.sh:3:LINT"
_an97_case "B12.3: a program after an opening brace is caught" brace "name:$AN97F/brace.sh:2:PREC"
_an97_case "B12.3: a program under xargs -0 is caught" xargs "name:$AN97F/xargs.sh:2:ROUNDMODE"
_an97_case "B12.3: a program in a command substitution inside double quotes is caught" subst "name:$AN97F/subst.sh:2:SYMTAB"
_an97_case "B12.3: a program in a command substitution in an unquoted here-document body is caught" heredoc "name:$AN97F/heredoc.sh:3:TEXTDOMAIN"
_an97_case "B12.3: a program variable assigned in another file given in the same call is caught in the file that assigns it" other "name:$AN97F/prog-g1.sh:2:FIELDWIDTHS"
_an97_case "B12.3: a program assigned with local is caught on the assignment's line" local "name:$AN97F/local.sh:3:asort"
_an97_case "B12.3: a program joined from a variable and a single-quoted part: both parts are read" joined "name:$AN97F/joined.sh:2:lshift" "name:$AN97F/joined.sh:3:rshift"
_an97_case "B12.3: a variable assigned from another is followed to the first assignment" chained "name:$AN97F/chained.sh:2:strtonum"
_an97_case "B12.3: a function's second argument, passed by its callers: a row on each caller's line" func "name:$AN97F/func.sh:5:typeof" "name:$AN97F/func.sh:6:isarray"
_an97_case "B12.3: -v RT=1 is caught on the line of that word" v "name:$AN97F/v.sh:2:RT"
_an97_case "B12.3: ERRNO as an awk variable is caught" errno "name:$AN97F/errno.sh:2:ERRNO"
_an97_case "B12.3: PROCINFO as an array is caught" procinfo "name:$AN97F/procinfo.sh:2:PROCINFO"
_an97_case "B12.3: and( as a call is caught" and "name:$AN97F/and.sh:2:and"
_an97_case "B12.3: mktime( as a call is caught" mktime "name:$AN97F/mktime.sh:2:mktime"
_an97_case "B12.3: or as a parameter name is caught" or "name:$AN97F/or.sh:2:or"
_an97_bad=""
for _an97_x in inline lines assign bang if then brace xargs subst heredoc other local joined chained func v errno procinfo and mktime or; do
  _an97_k="$(_an97_n "$_an97_x")"
  if [ "$(_an97_last "$_an97_x")" != last ] || [ -z "$_an97_k" ] || [ "$_an97_k" -lt 1 ]; then _an97_bad="$_an97_bad $_an97_x"; fi
done
is "B12.3: every run over a form's fixture ends with its one programs row, a count above 0" "${_an97_bad# }" ""

# ---- item 4: none of these is a name row ---------------------------------------------------
# Each file also holds at least one awk command with nothing listed in it, so a
# lint that reads it as the contract says reads a program, prints no row but
# programs, and exits 0.
_an97_put x-string.sh <<'AN97A'
# x-string.sh: listed names inside awk strings
awk '{ print "RT", "FPAT and PROCINFO", "and(1, 2)" }' input.txt
AN97A
_an97_put x-regex.sh <<'AN97A'
# x-regex.sh: listed names inside regular-expression literals
awk '/RT/ { n++ } $1 ~ /FPAT/ { m++ } { k += split($0, parts, /PROCINFO/) } END { print n, m, k }' input.txt
AN97A
_an97_put x-comment.sh <<'AN97A'
# x-comment.sh: listed names inside an awk comment
awk '
  # ERRNO and mktime( are named here in a comment only
  { n++ } END { print n }
' input.txt
AN97A
_an97_put x-near.sh <<'AN97A'
# x-near.sh: identifiers that hold a listed name and are none of them
awk '{ RTAG[NR] = $1; PRT = 1; ORT_ = 2; and_x = 3 } END { print RTAG[1], PRT, ORT_, and_x }' input.txt
AN97A
_an97_put x-bashcomment.sh <<'AN97A'
# awk '{ print RT }' input.txt is not run: this line is a bash comment
awk 'END { print NR }' input.txt   # and FPAT here is a bash comment too
AN97A
_an97_put x-printf.sh <<'AN97A'
# x-printf.sh: listed names in printf formats
printf 'RT %s FPAT %s\n' one two
awk 'END { printf "ERRNO %d\n", NR }' input.txt
AN97A
_an97_put x-sedgrep.sh <<'AN97A'
# x-sedgrep.sh: listed names in sed and grep arguments
sed -e 's/RT/rt/' input.txt
grep -c 'FPAT' input.txt
awk 'END { print NR }' input.txt
AN97A
_an97_put x-unused.sh <<'AN97A'
# x-unused.sh: a single-quoted program assigned to a variable no awk command reads
UNUSED_X='{ print RT }'
awk 'END { print NR }' input.txt
AN97A
_an97_put x-quotedhd.sh <<'AN97A'
# x-quotedhd.sh: quoted here-document bodies are skipped whole
cat <<'BODY'
$(awk '{ print RT }' input.txt)
BODY
cat <<"B2"
$(awk '{ print FPAT }' input.txt)
B2
awk 'END { print NR }' input.txt
AN97A
_an97_put x-bashvar.sh <<'AN97A'
# x-bashvar.sh: RT as a bash variable outside awk
RT=1
printf '%s %s\n' "$RT" "${RT}"
awk 'END { print NR }' input.txt
AN97A
for _an97_x in string regex comment near bashcomment printf sedgrep unused quotedhd bashvar; do
  _an97_run "x-$_an97_x" "$AN97F/x-$_an97_x.sh"
done
is "B12.4: a listed name inside an awk string is no name row" "$(_an97_got x-string)" "0|"
is "B12.4: a listed name inside a regular-expression literal is no name row" "$(_an97_got x-regex)" "0|"
is "B12.4: a listed name inside an awk comment is no name row" "$(_an97_got x-comment)" "0|"
is "B12.4: RTAG, PRT, ORT_ and and_x are no name rows" "$(_an97_got x-near)" "0|"
is "B12.4: a listed name in a bash comment is no name row" "$(_an97_got x-bashcomment)" "0|"
is "B12.4: a listed name in a printf format is no name row" "$(_an97_got x-printf)" "0|"
is "B12.4: a listed name in a sed or grep argument is no name row" "$(_an97_got x-sedgrep)" "0|"
is "B12.4: a listed name in a single-quoted string assigned to a variable no awk command reads is no name row" "$(_an97_got x-unused)" "0|"
is "B12.4: a listed name in a quoted here-document body is no name row" "$(_an97_got x-quotedhd)" "0|"
is "B12.4: RT as a bash variable outside awk is no name row" "$(_an97_got x-bashvar)" "0|"

# ---- item 5: what the lint cannot read, and what is left open --------------------------------
_an97_put u-subst.sh <<'AN97A'
# u-subst.sh: the program is what a command prints
awk "$(cat prog.awk)" input.txt
AN97A
_an97_put u-f.sh <<'AN97A'
# u-f.sh: the program is a file
awk -f prog.awk input.txt
AN97A
_an97_put u-args.sh <<'AN97A'
# u-args.sh: every argument handed on, the program among them
awk "$@"
AN97A
_an97_put o-quote.sh <<'AN97A'
# o-quote.sh: the file ends inside a single quote
awk 'END { print NR }' input.txt
printf 'this quote is never closed\n
and the file ends inside it
AN97A
_an97_put o-heredoc.sh <<'AN97A'
# o-heredoc.sh: the file ends inside a here-document
awk 'END { print NR }' input.txt
cat <<EOT
the body never ends
AN97A
for _an97_x in u-subst u-f u-args o-quote o-heredoc; do _an97_run "$_an97_x" "$AN97F/$_an97_x.sh"; done
_an97_run u-var "$AN97F/prog-g2.sh"
is "B12.5: a program in a command substitution is unread, on its word's line, exit 1" "$(_an97_got u-subst)" "1|unread:$AN97F/u-subst.sh:2"
is "B12.5: awk -f is unread, exit 1" "$(_an97_got u-f)" "1|unread:$AN97F/u-f.sh:2"
is "B12.5: a program variable nothing assigns is unread: prog-g2.sh given without the file that assigns it, exit 1" "$(_an97_got u-var)" "1|unread:$AN97F/prog-g2.sh:3"
is 'B12.5: $@ as a program is unread, exit 1' "$(_an97_got u-args)" "1|unread:$AN97F/u-args.sh:2"
is "B12.5: a file ending inside a single quote is open on the line the quote opened, exit 1" "$(_an97_got o-quote)" "1|open:$AN97F/o-quote.sh:3"
is "B12.5: a file ending inside a here-document is open on the line of its operator, exit 1" "$(_an97_got o-heredoc)" "1|open:$AN97F/o-heredoc.sh:3"

# ---- item 6: a file with no awk command ---------------------------------------------------
_an97_put none.sh <<'AN97A'
# none.sh: no program here
printf '%s\n' "nothing to read"
count=0
AN97A
_an97_run none "$AN97F/none.sh"
is "B12.6: a file with no awk command: exit 1, and programs 0 is its one row" \
   "$(cat "$AN97O/none.rc" 2>/dev/null)|$(cat "$AN97O/none.out" 2>/dev/null)" "1|$(printf 'programs\t0')"
# <<< lib-awk-gawk-names-blind
