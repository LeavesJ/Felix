# >>> driver-room-blind
printf '\nroom in the driver: its count, its comment runs and its pointers (audit b00, A1-A12, blind)\n'
# Written blind on 2026-10-24 from docs/2026-10-24-audit-fixes/b00-driver-room.md
# alone (B1 to B3, and section 4's A1 to A12), before the driver was edited. No
# engine code was read. The driver (tests/run) is read as text and never run.
# The three checks are this part's own, each written from the contract's words:
# _dr10_count (B1), _dr10_runs (B2) and _dr10_ptrs (B3). A1, A2, A5, A6 and A9
# read the real driver against $HERE; A3, A4, A7, A8 and A10 to A12 are their
# controls, on plants this part writes under $DR10 with exactly the contract's
# text. A1 and A5 are red on the base driver (257 other lines, 19 long runs)
# and green once it is edited; the rest hold on both.
#
# Readings, where the contract leaves room. A part pointer is the word `part`
# or `parts`, lower case, not preceded by a letter, a digit or an underscore,
# then one space and four digits. Leading and trailing characters of a path
# word are stripped as many times as they stand. A missing or unreadable
# receipt.sh is reported once when the driver holds a receipt.sh pointer, and
# then every such pointer is reported as well. "The files in $HERE/parts" are
# the regular files its `*` lists. B3's check refuses a driver with no line
# exactly `set -uo pipefail`, as B2's does: no opening block ends, so what to
# read is unknown, and that is never "nothing found". Each check refuses a
# driver it cannot read with status 2 and a reason naming it, and every
# assertion on it then fails with that reason.
#
# It reads only $HERE/run, $HERE/parts, $HERE/lib, $HERE/receipt.sh, paths
# under $REAL_HARNESS/../.. and its own plants, and writes only under $DR10 and
# where part 0003's _suite_flat keeps the flat suite, $TMP/suite-flat.run (A22).
DR10="$TMP/driver-room-1610"; mkdir -p "$DR10/t12/parts"
_dr10_nl=$'\n'

# _dr10_count DRIVER -> "OTHER PARTS LIBS LINES" (B1's regex for OTHER; lines
# as awk counts NR), or a reason naming DRIVER and status 2.
_dr10_count() {
  local o rc
  [ -f "$1" ] && [ -r "$1" ] || { printf 'cannot read the driver %s: no readable file there\n' "$1"; return 2; }
  o="$(LC_ALL=C awk '
    !/^\. "\$HERE\/(parts|lib)\/[^"\/]+"$/ { x++ }
    /^\. "\$HERE\/parts\/[^"\/]+"$/ { p++ }
    /^\. "\$HERE\/lib\/[^"\/]+"$/ { l++ }
    END { print x + 0, p + 0, l + 0, NR }' "$1")"; rc=$?
  if [ "$rc" -ne 0 ] || [ -z "$o" ]; then printf 'awk could not count the lines of %s (status %s)\n' "$1" "$rc"; return 2; fi
  printf '%s\n' "$o"
}

# _dr10_runs DRIVER -> "no long run" (status 0); or a line "run at line N, L
# lines" for each comment run after the opening block longer than two lines
# (status 1); or a reason naming DRIVER (status 2): no readable file, or no line
# exactly set -uo pipefail.
_dr10_runs() {
  local o rc
  [ -f "$1" ] && [ -r "$1" ] || { printf 'cannot read the driver %s: no readable file there\n' "$1"; return 2; }
  o="$(LC_ALL=C awk '
    !on && $0 == "set -uo pipefail" { on = 1; next }
    !on { next }
    /^[ \t]*#/ { if (!n) s = NR; n++; next }
    { if (n > 2) printf "run at line %d, %d lines\n", s, n; n = 0 }
    END { if (n > 2) printf "run at line %d, %d lines\n", s, n; if (!on) exit 3 }' "$1")"; rc=$?
  if [ "$rc" -eq 3 ]; then
    printf '%s has no line exactly `set -uo pipefail`, so no opening block ends and no run after one was read\n' "$1"; return 2
  fi
  if [ "$rc" -ne 0 ]; then printf 'awk could not read the comment runs of %s (status %s)\n' "$1" "$rc"; return 2; fi
  if [ -z "$o" ]; then printf 'no long run\n'; return 0; fi
  printf '%s\n' "$o"; return 1
}

# The pointers of B3 in the comment lines after the opening block, one row
# KIND:LINE:VALUE each: part:N:NNNN, rcp:N:TEXT, rcpbad:N: (no closing quote on
# its line) and path:N:WORD. Status 3: no line exactly set -uo pipefail. Quotes
# and backquotes are written as \047 and \140, so the program is one shell word.
_dr10_rows_awk='
BEGIN { Q = "\047"; LEAD = "([\"\047\140"; TRAIL = ")],.:;\"\047\140" }
!on && $0 == "set -uo pipefail" { on = 1; next }
!on || $0 !~ /^[ \t]*#/ { next }
{
  s = $0; lc = ""
  while (match(s, /parts? [0123456789][0123456789][0123456789][0123456789]/)) {
    pc = (RSTART > 1) ? substr(s, RSTART - 1, 1) : lc
    m = substr(s, RSTART, RLENGTH); lc = substr(m, RLENGTH, 1); s = substr(s, RSTART + RLENGTH)
    if (pc !~ /[A-Za-z0-9_]/) print "part:" NR ":" substr(m, length(m) - 3)
  }
  s = $0
  while ((i = index(s, "receipt.sh, \"")) > 0) {
    s = substr(s, i + 13); j = index(s, "\"")
    if (j == 0) { print "rcpbad:" NR ":"; break }
    print "rcp:" NR ":" substr(s, 1, j - 1); s = substr(s, j + 1)
  }
  k = split(substr($0, index($0, "#") + 1), w, /[ \t]+/)
  for (q = 1; q <= k; q++) {
    x = w[q]
    if (x == "" || index(x, "*") || index(x, "$")) continue
    while (x != "" && index(LEAD, substr(x, 1, 1))) x = substr(x, 2)
    while (x != "" && index(TRAIL, substr(x, length(x), 1))) x = substr(x, 1, length(x) - 1)
    if (length(x) >= 2 && substr(x, length(x) - 1) == Q "s") x = substr(x, 1, length(x) - 2)
    while (x != "" && index(TRAIL, substr(x, length(x), 1))) x = substr(x, 1, length(x) - 1)
    if (x ~ /\.sh$/ || index(x, "tests/") == 1 || index(x, "engine/") == 1) print "path:" NR ":" x
  }
}
END { if (!on) exit 3 }'

# _dr10_ptrs DRIVER TESTS -> a first line "read P part, R receipt.sh, W path",
# then one finding a line ("line N: ..." or "receipt.sh: ..."); status 0 with no
# finding, 1 with one or more, 2 with a reason naming DRIVER when nothing could
# be read. TESTS is the tests directory the pointers are read against.
_dr10_ptrs() {
  local rows rc row k l v rest f hit np=0 nr=0 nw=0 found="" rok=1
  [ -f "$1" ] && [ -r "$1" ] || { printf 'cannot read the driver %s: no readable file there\n' "$1"; return 2; }
  rows="$(LC_ALL=C awk "$_dr10_rows_awk" "$1")"; rc=$?
  if [ "$rc" -eq 3 ]; then
    printf '%s has no line exactly `set -uo pipefail`, so no opening block ends and no pointer after one was read\n' "$1"; return 2
  fi
  if [ "$rc" -ne 0 ]; then printf 'awk could not read the pointers of %s (status %s)\n' "$1" "$rc"; return 2; fi
  { [ -f "$2/receipt.sh" ] && [ -r "$2/receipt.sh" ]; } || rok=0
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    k="${row%%:*}"; rest="${row#*:}"; l="${rest%%:*}"; v="${rest#*:}"
    if [ "$k" = part ]; then
      np="$((np + 1))"; hit=0
      for f in "$2"/parts/"$v"-*.sh; do [ ! -f "$f" ] || hit=1; done
      [ "$hit" -eq 1 ] || found="${found}line $l: part $v: no parts/$v-*.sh in $2$_dr10_nl"
    elif [ "$k" = rcp ]; then
      nr="$((nr + 1))"
      if [ "$rok" -eq 0 ]; then found="${found}line $l: receipt.sh, \"$v\": not passed, receipt.sh cannot be read$_dr10_nl"
      elif ! LC_ALL=C grep -Fq -e "$v" "$2/receipt.sh"; then found="${found}line $l: receipt.sh, \"$v\": no such text in $2/receipt.sh$_dr10_nl"
      fi
    elif [ "$k" = rcpbad ]; then
      nr="$((nr + 1))"; found="${found}line $l: a receipt.sh pointer that could not be read: no closing quote on its line$_dr10_nl"
    else
      nw="$((nw + 1))"
      [ -f "$REAL_HARNESS/../../$v" ] || [ -d "$REAL_HARNESS/../../$v" ] || [ -f "$REAL_HARNESS/$v" ] \
        || [ -d "$REAL_HARNESS/$v" ] || [ -f "$2/$v" ] || [ -d "$2/$v" ] \
        || found="${found}line $l: path $v: under none of the checkout root, the harness and $2$_dr10_nl"
    fi
  done <<< "$rows"
  [ "$nr" -eq 0 ] || [ "$rok" -eq 1 ] || found="${found}receipt.sh: $2/receipt.sh is missing or cannot be read, so no receipt.sh pointer passes$_dr10_nl"
  printf 'read %s part, %s receipt.sh, %s path\n' "$np" "$nr" "$nw"
  [ -n "$found" ] || return 0
  printf '%s' "$found"; return 1
}

# _dr10_has OUT LINE TEXT -> "found" when a line of OUT begins LINE and holds TEXT, else "missing".
_dr10_has() {
  local f
  while IFS= read -r f; do
    case "$f" in "$2"*"$3"*) printf 'found'; return 0 ;; esac
  done <<< "$1"
  printf 'missing'
}
# _dr10_nf OUT -> the number of findings in what _dr10_ptrs printed (its lines after the first).
_dr10_nf() { printf '%s\n' "$1" | LC_ALL=C awk 'NR > 1 && $0 != "" { n++ } END { print n + 0 }'; }
# _dr10_join TEXT -> its lines joined by "; ".
_dr10_join() { printf '%s\n' "$1" | LC_ALL=C awk '{ printf "%s%s", (NR > 1 ? "; " : ""), $0 }'; }

# ---- the plants, exactly the contract's text
# A3's lines are quoted arguments, one a line, so none begins a line of this
# file: _suite_flat would read such a line as the driver's (review round, M1).
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -uo pipefail' \
  '. "$HERE/parts/0010-a.sh"' \
  '. "$HERE/lib/a.sh"' \
  '# a comment' \
  '. "$HERE/parts/0020-b.sh"' \
  '' \
  '  . "$HERE/parts/0030-c.sh"' \
  '. "$HERE/parts/0040-d.sh" # a trailing comment' \
  '. "$HERE/lib/b.sh"' \
  '. "$HERE/parts/0050-e.sh"' \
  '. "$HERE/parts/sub/f.sh"' > "$DR10/a3.run"
printf '%s' "$(cat "$DR10/a3.run")" > "$DR10/a3-unended.run"
cat > "$DR10/a7.run" <<'DR10_A7'
#!/usr/bin/env bash
# opening one
# opening two
# opening three
# opening four
set -uo pipefail
x=1
# two
# lines
y=2 # a trailing comment is code
# three
  # indented
# lines

# two again
# after a blank
z=3
# three at
# the end
# of the file
DR10_A7
cat > "$DR10/a8.run" <<'DR10_A8'
#!/usr/bin/env bash
  set -uo pipefail
set -uo pipefail # with a comment
# one
# two
# three
x=1
DR10_A8
cat > "$DR10/a10.run" <<'DR10_A10'
#!/usr/bin/env bash
set -uo pipefail
# see part 9999 for why
# and (receipt.sh, "no such section here")
# and tests/no-such-file.sh, which is gone
x=1
DR10_A10
cat > "$DR10/a11.run" <<'DR10_A11'
#!/usr/bin/env bash
# part 9999 in the opening block is not read
set -uo pipefail
# why: part 1040, and (part 0003's) helpers
# (receipt.sh, "red, beside a record run")
# `tests/receipt.sh`, engine/harness/felix's and tests/lib/*.sh and "$HERE/run"
x=1
DR10_A11
cat > "$DR10/a12.run" <<'DR10_A12'
#!/usr/bin/env bash
set -uo pipefail
# (receipt.sh, "red, beside a record run
# x")
x=1
DR10_A12
cat > "$DR10/a12-closed.run" <<'DR10_A12C'
#!/usr/bin/env bash
set -uo pipefail
# (receipt.sh, "red, beside a record run")
x=1
DR10_A12C

# ---- B1: room for part and lib lines
_dr10_c="$(_dr10_count "$HERE/run")"; _dr10_cs=$?
_dr10_n="driver room A1: the driver holds at most 197 lines that are neither a part line nor a lib line"
if [ "$_dr10_cs" -ne 0 ]; then bad "$_dr10_n" "$_dr10_c"
elif [ "${_dr10_c%% *}" -le 197 ]; then ok "$_dr10_n"
else bad "$_dr10_n" "$HERE/run holds ${_dr10_c%% *} lines that are neither, of ${_dr10_c##* } (other, part, lib, all: $_dr10_c)"
fi

_dr10_pf=0; for _dr10_f in "$HERE"/parts/*; do [ ! -f "$_dr10_f" ] || _dr10_pf="$((_dr10_pf + 1))"; done
_dr10_lf=0; for _dr10_f in "$HERE"/lib/*.sh; do [ ! -f "$_dr10_f" ] || _dr10_lf="$((_dr10_lf + 1))"; done
_dr10_n="driver room A2: the driver's part lines are as many as the files in parts, its lib lines as the .sh files in lib, and it was read (control)"
if [ "$_dr10_cs" -ne 0 ]; then bad "$_dr10_n" "$_dr10_c"
else
  _dr10_r="${_dr10_c#* }"; _dr10_p="${_dr10_r%% *}"; _dr10_r="${_dr10_r#* }"; _dr10_l="${_dr10_r%% *}"; _dr10_t="${_dr10_c##* }"
  _dr10_v="$_dr10_p part lines for $_dr10_pf files in parts, $_dr10_l lib lines for $_dr10_lf .sh files in lib"
  [ "$_dr10_t" -gt 0 ] || _dr10_v="$_dr10_v, but no line was read"
  is "$_dr10_n" "$_dr10_v" "$_dr10_pf part lines for $_dr10_pf files in parts, $_dr10_lf lib lines for $_dr10_lf .sh files in lib"
fi

_dr10_a="$(_dr10_count "$DR10/a3.run" 2>&1)"; _dr10_a="$_dr10_a (status $?)"
_dr10_b="$(_dr10_count "$DR10/a3-unended.run" 2>&1)"; _dr10_b="$_dr10_b (status $?)"
_dr10_e="$(LC_ALL=C tail -c 1 "$DR10/a3-unended.run" | LC_ALL=C od -An -c | tr -d ' ')"
[ "$_dr10_e" != '\n' ] || _dr10_b="the unended plant ends in a newline, so it tests nothing"
is "driver room A3: a planted driver counts 7 other lines, 3 part lines, 2 lib lines and 12 lines, with or without a newline after its last line (control)" \
   "$_dr10_a | $_dr10_b" "7 3 2 12 (status 0) | 7 3 2 12 (status 0)"

_dr10_o="$(_dr10_count "$DR10/no-such-driver" 2>&1)"; _dr10_s=$?
if [ "$_dr10_s" -ne 0 ]; then _dr10_v="refused"; else _dr10_v="status 0"; fi
case "$_dr10_o" in *"$DR10/no-such-driver"*) _dr10_v="$_dr10_v, naming the path" ;; *) _dr10_v="$_dr10_v, [$_dr10_o] does not name the path" ;; esac
case "$_dr10_o" in [0123456789]*) _dr10_v="$_dr10_v, and gives a count [$_dr10_o]" ;; esac
is "driver room A4: the count over a driver that is not there is refused with a message naming its path, never a count of 0 (control)" \
   "$_dr10_v" "refused, naming the path"

# ---- B2: no long explanation left in the driver
_dr10_o="$(_dr10_runs "$HERE/run")"; _dr10_s=$?
_dr10_n="driver room A5: after the opening block no comment run in the driver is longer than two lines"
if [ "$_dr10_s" -eq 0 ] && [ "$_dr10_o" = "no long run" ]; then ok "$_dr10_n"
elif [ "$_dr10_s" -eq 1 ]; then bad "$_dr10_n" "$(_dr10_join "$_dr10_o") ($(printf '%s\n' "$_dr10_o" | LC_ALL=C awk 'END { print NR }') run(s))"
else bad "$_dr10_n" "status $_dr10_s: $_dr10_o"
fi

_dr10_n="driver room A6: the driver has a line exactly set -uo pipefail and comment lines after it, so its runs were read (control)"
if [ -f "$HERE/run" ] && [ -r "$HERE/run" ]; then
  _dr10_v="$(LC_ALL=C awk '!on && $0 == "set -uo pipefail" { on = 1; next } on && /^[ \t]*#/ { c++ }
    END { if (!on) print "no line exactly set -uo pipefail"; else if (!c) print "no comment line after set -uo pipefail"; else print "read" }' "$HERE/run")"
  is "$_dr10_n" "$_dr10_v" "read"
else bad "$_dr10_n" "cannot read the driver $HERE/run: no readable file there"
fi

_dr10_o="$(_dr10_runs "$DR10/a7.run")"; _dr10_s=$?
is "driver room A7: a planted driver reports exactly the runs at lines 11 and 18, three lines each, not its opening block or its runs of two (control)" \
   "status $_dr10_s: $(_dr10_join "$_dr10_o")" "status 1: run at line 11, 3 lines; run at line 18, 3 lines"

_dr10_o="$(_dr10_runs "$DR10/a8.run" 2>&1)"; _dr10_s=$?
if [ "$_dr10_s" -ne 0 ]; then _dr10_v="refused"; else _dr10_v="status 0"; fi
case "$_dr10_o" in
  *'no line exactly `set -uo pipefail`'*) _dr10_v="$_dr10_v, saying no line is exactly set -uo pipefail" ;;
  *) _dr10_v="$_dr10_v, [$_dr10_o] does not say no line is exactly set -uo pipefail" ;;
esac
case "$_dr10_o" in *"no long run"*) _dr10_v="$_dr10_v, and reports no long run" ;; esac
is "driver room A8: a driver with no line exactly set -uo pipefail is refused, and never reported as having no long run (control)" \
   "$_dr10_v" "refused, saying no line is exactly set -uo pipefail"

# ---- B3: every pointer in a driver comment resolves
_dr10_o="$(_dr10_ptrs "$HERE/run" "$HERE")"; _dr10_s=$?
_dr10_n="driver room A9: every part, receipt.sh and path pointer in the driver's comments resolves, and part pointers were read (control)"
_dr10_np="$(printf '%s\n' "$_dr10_o" | LC_ALL=C awk 'NR == 1 && $1 == "read" { print $2 + 0 }')"
if [ "$_dr10_s" -eq 0 ] && [ "${_dr10_np:-0}" -gt 0 ]; then ok "$_dr10_n"
elif [ "$_dr10_s" -eq 0 ]; then bad "$_dr10_n" "no part pointer was read: $_dr10_o"
else bad "$_dr10_n" "status $_dr10_s: $(_dr10_join "$_dr10_o")"
fi

_dr10_o="$(_dr10_ptrs "$DR10/a10.run" "$HERE")"; _dr10_s=$?
_dr10_v="status $_dr10_s, $(_dr10_nf "$_dr10_o") finding(s); $(_dr10_has "$_dr10_o" 'line 3: ' 'part 9999')"
_dr10_v="$_dr10_v; $(_dr10_has "$_dr10_o" 'line 4: ' 'no such section here'); $(_dr10_has "$_dr10_o" 'line 5: ' 'tests/no-such-file.sh')"
is "driver room A10: a planted driver's three broken pointers are reported, each with its line, and nothing else (control)" \
   "$_dr10_v" "status 1, 3 finding(s); found; found; found"

_dr10_o="$(_dr10_ptrs "$DR10/a11.run" "$HERE")"; _dr10_s=$?
is "driver room A11: a planted driver's good pointers, and those in its opening block or holding a star or a dollar, report nothing (control)" \
   "status $_dr10_s: $(_dr10_join "$_dr10_o")" "status 0: read 2 part, 1 receipt.sh, 3 path"

_dr10_o="$(_dr10_ptrs "$DR10/a12.run" "$HERE")"; _dr10_s=$?
_dr10_v="status $_dr10_s, $(_dr10_nf "$_dr10_o") finding(s); $(_dr10_has "$_dr10_o" 'line 3: ' 'could not be read')"
_dr10_o="$(_dr10_ptrs "$DR10/a12-closed.run" "$DR10/t12")"; _dr10_s=$?
_dr10_v="$_dr10_v | status $_dr10_s; $(_dr10_has "$_dr10_o" 'receipt.sh: ' 'cannot be read'); $(_dr10_has "$_dr10_o" 'line 3: ' 'red, beside a record run')"
is "driver room A12: a receipt.sh pointer with no closing quote is reported as unread, and with no receipt.sh to read a whole one is not passed (control)" \
   "$_dr10_v" "status 1, 1 finding(s); found | status 1; found; found"

# ---- Review round, M1: a part never holds a line that begins like the driver's
# Written blind from the contract's section 9. Part 0003's _suite_flat puts each
# part and lib file where the driver's line naming it stood, and part 0203's B2
# child flattens that flat file once more; _suite_copy_driver and
# _suite_copy_tree take a line beginning with either prefix as the driver's.
# _dr10_shape TESTS -> "read P part and L lib files", then one row FILE:LINE
# (FILE relative to TESTS) for each line of TESTS/parts/*.sh or TESTS/lib/*.sh
# whose first bytes are a part line's or a lib line's prefix: status 1 with a
# row, 0 with none, 2 with a reason naming TESTS when it holds no part file or
# awk fails. The prefixes are only ever written here inside a quoted string.
_dr10_shape() {
  local f o rc np=0 nl=0
  local -a fs
  fs=()
  for f in "$1"/parts/*.sh; do [ ! -f "$f" ] || { fs[${#fs[@]}]="$f"; np="$((np + 1))"; }; done
  [ "$np" -gt 0 ] || { printf 'no part file under %s/parts, so no line was read\n' "$1"; return 2; }
  for f in "$1"/lib/*.sh; do [ ! -f "$f" ] || { fs[${#fs[@]}]="$f"; nl="$((nl + 1))"; }; done
  o="$(DR10_D="$1/" LC_ALL=C awk '
    BEGIN { d = ENVIRON["DR10_D"] }
    index($0, ". \"$HERE/parts/") == 1 || index($0, ". \"$HERE/lib/") == 1 {
      f = FILENAME; if (index(f, d) == 1) f = substr(f, length(d) + 1); print f ":" FNR }' "${fs[@]}")"; rc=$?
  if [ "$rc" -ne 0 ]; then printf 'awk could not read the part and lib files under %s (status %s)\n' "$1" "$rc"; return 2; fi
  printf 'read %s part and %s lib files\n' "$np" "$nl"
  [ -n "$o" ] || return 0
  printf '%s\n' "$o"; return 1
}

_dr10_o="$(_dr10_shape "$HERE")"; _dr10_s=$?
_dr10_n="driver room A20: no line of a part file or a tests/lib file begins with a part line's or a lib line's prefix, so a flat suite flattens again (review M1)"
if [ "$_dr10_s" -eq 0 ]; then ok "$_dr10_n"
elif [ "$_dr10_s" -eq 1 ]; then bad "$_dr10_n" "$(_dr10_nf "$_dr10_o") line(s) begin with one: $(_dr10_join "$_dr10_o")"
else bad "$_dr10_n" "status $_dr10_s: $_dr10_o"
fi

# A21's plant: each line is a quoted argument, so none begins a line of this file.
mkdir -p "$DR10/m1/parts" "$DR10/m1/lib" "$DR10/m1-empty/parts"
printf '%s\n' \
  '. "$HERE/parts/0010-a.sh"' \
  '  . "$HERE/parts/0030-c.sh"' \
  '. "$HERE/lib/b.sh" # a trailing comment' \
  'echo . "$HERE/parts/0040-d.sh"' > "$DR10/m1/parts/0010-x.sh"
printf '\t%s\n' '. "$HERE/lib/a.sh"' >> "$DR10/m1/parts/0010-x.sh"
printf '%s\n' 'x=1' '. "$HERE/parts/sub/f.sh"' > "$DR10/m1/lib/a.sh"
_dr10_o="$(_dr10_shape "$DR10/m1")"; _dr10_s=$?
_dr10_v="status $_dr10_s: $(_dr10_join "$_dr10_o")"
_dr10_o="$(_dr10_shape "$DR10/m1-empty")"; _dr10_s=$?
if [ "$_dr10_s" -eq 2 ]; then _dr10_v="$_dr10_v | refused"; else _dr10_v="$_dr10_v | status $_dr10_s"; fi
case "$_dr10_o" in
  *"$DR10/m1-empty"*) _dr10_v="$_dr10_v, naming the directory" ;;
  *) _dr10_v="$_dr10_v, [$_dr10_o] does not name the directory" ;;
esac
is "driver room A21: a planted tests directory reports exactly its three lines that begin with either prefix, and one with no part file is refused (control)" \
   "$_dr10_v" "status 1: read 1 part and 1 lib files; parts/0010-x.sh:1; parts/0010-x.sh:3; lib/a.sh:2 | refused, naming the directory"

_dr10_n="driver room A22: the suite flattened once, then flattened again from a harness whose tests/run is that flat file, exits 0 and gives the same bytes (review M1)"
_dr10_f1="$(_suite_flat)"; _dr10_s=$?
if [ "$_dr10_s" -ne 0 ] || [ ! -s "$_dr10_f1" ]; then
  bad "$_dr10_n" "the first flatten, part 0003's _suite_flat, exited $_dr10_s and gave [$_dr10_f1], so nothing was flattened again"
else
  mkdir -p "$DR10/m1h/tests" "$DR10/m1t"; cp "$_dr10_f1" "$DR10/m1h/tests/run"
  _dr10_f2="$(REAL_HARNESS="$DR10/m1h"; TMP="$DR10/m1t"; _suite_flat)"; _dr10_s=$?
  _dr10_l0="$(LC_ALL=C awk 'END { print NR }' "$REAL_HARNESS/tests/run")"; _dr10_l1="$(LC_ALL=C awk 'END { print NR }' "$_dr10_f1")"
  _dr10_x="$(LC_ALL=C awk 'index($0, ". \"$HERE/parts/") == 1 || index($0, ". \"$HERE/lib/") == 1 { print "line " NR ": " $0; exit }' "$_dr10_f1")"
  if [ "$_dr10_s" -ne 0 ] || [ ! -f "$_dr10_f2" ]; then
    bad "$_dr10_n" "the second flatten exited $_dr10_s and gave [$_dr10_f2]; the flat suite's first line beginning like a part or lib line: [${_dr10_x:-none}]"
  elif ! LC_ALL=C cmp -s "$_dr10_f1" "$_dr10_f2"; then
    bad "$_dr10_n" "the two flattens differ: $(LC_ALL=C cmp "$_dr10_f1" "$_dr10_f2" 2>&1 | head -1)"
  elif [ "$_dr10_l1" -le "$_dr10_l0" ]; then
    bad "$_dr10_n" "the flat suite has $_dr10_l1 lines and the driver $_dr10_l0, so the first flatten put no file in"
  else ok "$_dr10_n"
  fi
fi
