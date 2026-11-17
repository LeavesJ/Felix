# The table validator: one definition of a row, and the shapes it refuses.
#
# The engine is tab-separated the whole way down and had no shared reader. On
# 2026-09-22 there were 507 sites parsing rows in 52 files, in about a dozen
# idioms, and they did not agree about what a row is. Two readers of one deny
# table disagreed about its last rule: the enforcing path reads the file with
# `while read ... done < file`, which drops a final line that has no newline,
# and the escape check reads it with grep, which keeps it. Remove the final
# newline and the rule stops refusing anything while the check that guards the
# table sees an identical set of lines.
#
# docs/2026-09-19-direction-decisions.md §1 chose rows first, in bash: a
# validator before a reader, a table declaring every table's columns, and a
# gate check that fails on a table nobody declared. This is the validator.
# Nothing here is migrated onto it yet. An existing reader moves when a row
# forces it, and the kill test in the suite is what makes that move safe.
#
# THE ROW. A data row is any line, including bytes after the last newline,
# that does not match `^[[:space:]]*(#|$)` in the C locale. Its cells are the
# exact tab-separated substrings, awk -F'\t' semantics: an empty cell is kept,
# nothing is trimmed, a CR is not stripped. That is byte-identical to the 42
# sites that filter with `grep -vE '^[[:space:]]*(#|$)'` (or `\s`) and to the
# awk scans in obligations.sh and exceptions.sh, the largest family.
#
# THE REFUSALS. Each is a shape on which two reader families already in the
# engine read different rows, or put a cell boundary in different places, so
# on a table this accepts every family reads the same rows split at the same
# tabs:
#
#   indented-comment   whitespace before `#`. The `IFS=$'\t' read` + `case
#                      ''|'#'*` loops read a space-indented comment as a row;
#                      the grep family skips it; the raw `case` loops read a
#                      tab-indented one as a row.
#   whitespace-line    a line of only whitespace that is not empty. The raw
#                      `case` loops and qualify's awk read it as data.
#   nonascii-lead      a line whose first byte after ASCII whitespace is not
#                      ASCII. None of those readers pins a locale, and in a
#                      UTF-8 one some of them take a Unicode space before `#`
#                      for whitespace and some do not, so what kind of line it
#                      is depends on the machine. Every first cell the engine
#                      writes is ASCII.
#   carriage-return    a CR anywhere. The tab-IFS reads keep it in the last
#                      cell, and exceptions.sh alone strips it.
#   no-final-newline   the last byte of a non-empty file is not a newline.
#                      The `done < file` loops drop that line and grep, awk
#                      and cut keep it; and the appenders that do not check
#                      glue their next row onto it.
#   nul-byte           a NUL anywhere. grep calls such a file binary and prints
#                      no rows at all, while a read loop reads on.
#   encoding           a line that is not UTF-8 as RFC 3629 has it: no
#                      overlong form, no surrogate, nothing past U+10FFFF. In a
#                      UTF-8 locale grep drops such a line and some cut and sed
#                      builds stop there, while the read loops go on; and macOS
#                      awk aborts on a code point past U+10FFFF and reads no
#                      rows at all, which is why this is checked here, byte by
#                      byte, and not by the platform's iconv, which lets those
#                      through.
#   empty-cell         a leading tab, a trailing tab, or two tabs together.
#                      `IFS=$'\t' read` collapses a run of tabs, so every
#                      later column moves left one; awk and cut keep the empty
#                      cell where it is.
#   cells              fewer cells than the table's required columns, or more
#                      than all of them. `cut -fN` passes a line with no tab
#                      through whole for every N.
#   symlink            the table is a link. What the escape check compares is
#                      the link's text, and what a reader reads is its target.
#
# What this does NOT promise. A reader that assigns fewer variables than a
# table has columns folds the rest into its last one — a four-variable read of
# a six-column risk row puts channel and confine inside the reason — and the
# engine does that on purpose in places that only want the first columns.
# Accepted means the cells are where the tabs say; which cells a given reader
# asks for is that reader's business, and an inventory of reader arities waits
# until readers move onto this one.
#
# NOT refused: trailing spaces inside a cell (a governed project's risk table
# carries load-bearing ones in a regex), a `#` in a later cell, a truly empty
# line, non-ASCII text that is UTF-8 and not at the start of a line. Nothing
# here rewrites or normalises a file: the commissioning policy is a hash of
# these files' bytes, and a validator that tidied them would change what it
# certified.
#
# THE SCHEMA. Columns come from one row in templates/schemas.tsv, never from a
# table's own header comment: header comments in use write their tabs as the
# literal text `<TAB>`, and one table has two header forms.
#
# Bash 3.2, and awk and grep as BSD, BWK, mawk and GNU share them. No function
# here writes anything. Every file is handed to awk and tail on standard input,
# never as an operand: awk takes an operand shaped like `k=v` for an assignment
# and `-` for standard input, and tail takes one starting with `-` for an
# option, and each of those skipped the file it was given without a word.

FELIX_TABLE_SKIP='^[[:space:]]*(#|$)'

# A whole line of well-formed UTF-8, as bytes in the C locale: ASCII except NUL
# (refused on its own), then the two- to four-byte forms of RFC 3629 §4. No
# interval expressions, which not every awk here has. Written with $'...', so no fork can fail at load:
# one did leave it empty, and an empty pattern refused no encoding (felix_table_check refuses to examine then).
FELIX_TABLE_UTF8=$'^([\001-\177]|[\302-\337][\200-\277]|\340[\240-\277][\200-\277]|[\341-\354\356\357][\200-\277][\200-\277]|\355[\200-\237][\200-\277]|\360[\220-\277][\200-\277][\200-\277]|[\361-\363][\200-\277][\200-\277][\200-\277]|\364[\200-\217][\200-\277][\200-\277])*$'

# The rows of a table, byte for byte, one per line. A final row with no newline
# comes out with one, as grep and awk print it.
felix_table_rows() {
  [ -f "$1" ] || return 0
  LC_ALL=C awk -v skip="$FELIX_TABLE_SKIP" '$0 !~ skip' < "$1"
}

# The schema row for a table, looked up by basename: the key a table's readers
# and FELIX_ESCAPE_TABLES already use. Empty when there is none. One awk with no
# pipe (felix_table_rows' skip and the lookup together), so its status is the
# lookup's own: non-zero only when the awk did not run to its end.
felix_table_schema() {
  local schemas="$1" table="$2"
  [ -f "$schemas" ] || return 0
  T="$table" LC_ALL=C awk -F'\t' -v skip="$FELIX_TABLE_SKIP" '$0 ~ skip { next } $1 == ENVIRON["T"] { print; exit }' < "$schemas"
}

# Cell N of a schema row as cut -fN gives it, into _FELIX_TC: the whole row when
# it holds no tab, empty past its last cell. In this shell, so it cannot fail.
_felix_table_cell() {   # ROW N
  local r="$1" i=1
  case "$r" in *"	"*) ;; *) _FELIX_TC="$r"; return 0 ;; esac
  while [ "$i" -lt "$2" ]; do case "$r" in *"	"*) r="${r#*	}" ;; *) r=""; break ;; esac; i=$((i + 1)); done
  _FELIX_TC="${r%%	*}"
}

# Required and total columns of a columns cell, into _FELIX_TA_R and _FELIX_TA_T:
# its words as awk splits them (blanks), one with a final ? optional. Counted in
# this shell with no unquoted expansion: a column written `name?` is a glob, and
# an expansion would match it against the files in the caller's directory.
_felix_table_arity() {   # COLUMNS
  local s="$1" c LC_ALL=C
  _FELIX_TA_R=0; _FELIX_TA_T=0
  while [ -n "$s" ]; do
    case "$s" in [[:blank:]]*) s="${s#?}"; continue ;; esac
    c="${s%%[[:blank:]]*}"; s="${s#"$c"}"; _FELIX_TA_T=$((_FELIX_TA_T + 1))
    case "$c" in *\?) ;; *) _FELIX_TA_R=$((_FELIX_TA_R + 1)) ;; esac
  done
}

# felix_capture (lib/detect.sh), from beside this file when the caller has not
# loaded it (bin/schema-check sources this file alone); 0 when it is defined.
_felix_table_cap() {
  declare -F felix_capture >/dev/null && return 0
  local f="${BASH_SOURCE[0]:-}" d
  d="${f%/*}"; [ "$d" != "$f" ] || d=.
  [ -f "$d/detect.sh" ] && . "$d/detect.sh" 2>/dev/null
  declare -F felix_capture >/dev/null
}
# The check's reads of FILE, each run by felix_capture: its size, the size less
# its NULs (the pipe's two statuses read here, whatever the caller's pipefail),
# and the byte at an offset, each with no pipe to the shell.
_felix_table_wc() { LC_ALL=C wc -c < "$1"; }
_felix_table_nonul() { LC_ALL=C tr -d '\000' < "$1" | wc -c; set -- "${PIPESTATUS[@]}"; [ "$1:$2" = 0:0 ]; }
_felix_table_byte() { LC_ALL=C od -An -tx1 -j "$2" -N 1 < "$1"; }
_felix_table_dec() { _FELIX_TN="${1#"${1%%[![:blank:]]*}"}"; case "$_FELIX_TN" in ''|*[!0123456789]*) return 1 ;; esac; }   # wc pads with blanks

# Everything wrong with one file as an instance of one table. One line per
# refusal: <file>:<line> TAB <reason> TAB <detail>, with `-` for the line of a
# refusal about the whole file.
#
#   exit 0  accepted
#   exit 1  refused
#   exit 2  cannot examine: no such file, or no schema row for the table, or a
#           read of the check's own that did not finish (the one line
#           <file>:- TAB cannot-examine TAB a read of the check's own did not
#           finish, and no refusal line before it). Never read as accepted; a
#           table nobody declared, or one not read whole, is not a clean one.
#
# Every read is made, and checked, before anything is printed (2026-10-31): each
# ran in a command substitution whose status nobody read, and one that failed or
# could not fork read as an empty answer, which accepted a malformed table or
# refused a valid one. The schema lookup, the main pass and the file-level reads
# run under felix_capture; the row's cells, the arity, hi and the refusal lines
# are made in this shell, with no fork to fail.
felix_table_check() {
  local schemas="$1" file="$2" table="${3:-}" unk nl=$'\n'
  [ -n "$table" ] || table="${file##*/}"
  if [ -L "$file" ]; then
    printf '%s:-\tsymlink\ta link, so the escape check compares its text and a reader reads its target\n' "$file"; return 1
  fi
  if [ ! -f "$file" ] || [ ! -r "$file" ]; then
    printf '%s:-\tcannot-examine\tno readable file\n' "$file"; return 2
  fi
  printf -v unk '%s:-\tcannot-examine\ta read of the check'\''s own did not finish' "$file"
  local row
  _felix_table_cap && [ -n "${FELIX_TABLE_UTF8:-}" ] && felix_capture row felix_table_schema "$schemas" "$table" \
    || { printf '%s\n' "$unk"; return 2; }
  if [ -z "$row" ]; then
    printf '%s:-\tno-schema\t%s has no row in %s\n' "$file" "$table" "${schemas##*/}"; return 2
  fi
  local req tot empty cols hi
  _felix_table_cell "$row" 3; cols="$_FELIX_TC"
  _felix_table_cell "$row" 4; empty="$_FELIX_TC"
  _felix_table_arity "$cols"; req="$_FELIX_TA_R"; tot="$_FELIX_TA_T"
  hi=$'[\200-\377]'

  # One pass classifies every line and applies every per-line refusal. The last
  # line it prints is the row count, which the shell splits off; a pass whose
  # last line is not TAB and digits did not run to its end.
  local out rows
  felix_capture out _felix_table_pass "$file" "$req" "$tot" "$cols" "$hi" || { printf '%s\n' "$unk"; return 2; }
  rows="${out##*"$nl"}"
  case "$rows" in "	"[0123456789]*) ;; *) printf '%s\n' "$unk"; return 2 ;; esac
  out="${out%"$rows"}"; out="${out%"$nl"}"; rows="${rows#	}"
  case "$rows" in *[!0123456789]*) printf '%s\n' "$unk"; return 2 ;; esac

  # File-level shapes one awk pass cannot see: it reads a final line with no
  # newline as a line like any other, and stops or truncates at a NUL
  # depending on its build. Its size, the last byte and the size less its NULs,
  # each a number or one hex byte, or the check cannot tell.
  local more="" line size byte nonul
  felix_capture size _felix_table_wc "$file" && _felix_table_dec "$size" || { printf '%s\n' "$unk"; return 2; }
  size="$_FELIX_TN"
  # The last byte, read as a number: a command substitution drops a newline and
  # a NUL alike, so a file ending in a NUL looked like one ending in a newline.
  byte=""
  if [ -s "$file" ]; then
    felix_capture byte _felix_table_byte "$file" "$((size - 1))" || { printf '%s\n' "$unk"; return 2; }
    byte="${byte//[[:space:]]/}"
    case "$byte" in [0123456789abcdef][0123456789abcdef]) ;; *) printf '%s\n' "$unk"; return 2 ;; esac
    if [ "$byte" != "0a" ]; then
      printf -v line '%s:-\tno-final-newline\tthe last line has no newline, and the done-< loops drop it while grep and awk keep it' "$file"
      more="$more$line$nl"
    fi
  fi
  # The size less its NULs is at most its size, and at least 1 when its last byte is not a NUL.
  felix_capture nonul _felix_table_nonul "$file" && _felix_table_dec "$nonul" || { printf '%s\n' "$unk"; return 2; }
  nonul="$_FELIX_TN"
  [ "$nonul" -le "$size" ] && { [ "$nonul" -gt 0 ] || [ -z "$byte" ] || [ "$byte" = 00 ]; } || { printf '%s\n' "$unk"; return 2; }
  if [ "$nonul" -ne "$size" ]; then
    printf -v line '%s:-\tnul-byte\ta NUL byte, which makes grep treat the file as binary and print no rows' "$file"
    more="$more$line$nl"
  fi
  if [ "${rows:-0}" -eq 0 ] && [ "$empty" = "refused" ]; then
    printf -v line '%s:-\tempty\tno rows, and %s declares that emptiness is never legitimate' "$file" "$table"
    more="$more$line$nl"
  fi
  out="${out:+$out
}${more%
}"
  out="${out%
}"

  [ -n "$out" ] || return 0
  printf '%s\n' "$out"
  return 1
}

# The main pass of felix_table_check over FILE, every file on standard input (above).
_felix_table_pass() {   # FILE REQ TOT COLS HI
  LC_ALL=C awk -F'\t' -v f="$1" -v req="$2" -v tot="$3" -v cols="$4" -v hi="$5" -v u8="$FELIX_TABLE_UTF8" '
    $0 !~ u8 { printf "%s:%d\tencoding\ta line that is not UTF-8, which grep drops in a UTF-8 locale and macOS awk cannot read\n", f, NR }
    /\r/ { printf "%s:%d\tcarriage-return\ta CR byte, which a tab-IFS read keeps in the last cell\n", f, NR }
    $0 ~ ("^[ \t\v\f\r]*" hi) { printf "%s:%d\tnonascii-lead\ta line that starts with a non-ASCII byte, which is whitespace to some locales and not others\n", f, NR }
    /^[[:space:]]+#/ { printf "%s:%d\tindented-comment\twhitespace before #, which the read-and-case loops take for a row\n", f, NR; next }
    /^#/ { next }
    /^[[:space:]]+$/ { printf "%s:%d\twhitespace-line\ta line of only whitespace, which the raw case loops take for a row\n", f, NR; next }
    /^$/ { next }
    {
      rows++
      if ($0 ~ /^\t/ || $0 ~ /\t$/ || $0 ~ /\t\t/)
        printf "%s:%d\tempty-cell\ta leading, trailing or doubled tab, which moves every later column under an IFS read\n", f, NR
      if (NF < req || NF > tot)
        printf "%s:%d\tcells\t%d cell(s); %s declares %s\n", f, NR, NF, (req == tot ? "exactly " req : req " to " tot), cols
    }
    END { printf "\t%d\n", rows + 0 }
  ' < "$1"
}

# What is wrong with schemas.tsv's own rows, beyond what its row in itself
# already says. <line> TAB <reason> TAB <detail>. The generic check covers cell
# counts and shapes; these are the values only a schema row can get wrong.
felix_table_schema_malformed() {
  local schemas="$1"
  [ -f "$schemas" ] || return 0
  LC_ALL=C awk -F'\t' -v skip="$FELIX_TABLE_SKIP" '
    $0 ~ skip { next }
    {
      if (NF != 4)
        printf "%d\tcells\t%d cell(s); a schema row has four: table lives columns empty\n", NR, NF
      if ($3 !~ /^[^ ]+( [^ ]+)*$/)
        printf "%d\tcolumns\tnames separated by single spaces, with none before or after\n", NR
      if ($1 !~ /^[A-Za-z0-9._-]+$/)
        printf "%d\ttable\t\"%s\" is not a basename\n", NR, $1
      if ($1 in seen)
        printf "%d\tduplicate\t%s already has a row at line %d\n", NR, $1, seen[$1]
      else seen[$1] = NR
      if ($2 != "tree" && $2 != "memory")
        printf "%d\tlives\t\"%s\" is neither tree nor memory\n", NR, $2
      if ($4 != "refused" && $4 != "allowed")
        printf "%d\tempty\t\"%s\" is neither refused nor allowed\n", NR, $4
      n = split($3, c, " "); opt = 0; req = 0
      for (i = 1; i <= n; i++) {
        if (c[i] !~ /^[a-z][a-z0-9_-]*\??$/)
          printf "%d\tcolumns\t\"%s\" is not a column name\n", NR, c[i]
        if (c[i] ~ /\?$/) opt = 1
        else { req++; if (opt) printf "%d\tcolumns\t\"%s\" is required after an optional column\n", NR, c[i] }
      }
      # One column, or at least two that every row must carry. A row allowed
      # to stop after its first cell is a line with no tab, and cut -f2 hands
      # such a line back whole as its second column.
      if (n == 0)
        printf "%d\tcolumns\tno columns\n", NR
      else if (n > 1 && req < 2)
        printf "%d\tcolumns\tfewer than two required columns, so a row may have no tab\n", NR
    }
  ' < "$schemas"
}
