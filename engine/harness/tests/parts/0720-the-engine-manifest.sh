printf '\nthe engine manifest\n'
# The plugin manifest is what felix install deploys under, and an empty one
# deployed the engine under a commit sha with no version at all — written by
# an edit that opened the file for writing before reading it. Neither the
# gate nor the suite had ever asked whether the manifest parses.
_mf="$REAL_HARNESS/../.claude-plugin/plugin.json"
[ -s "$_mf" ] && ok "the engine manifest is not empty" || bad "the engine manifest is not empty" "$_mf"
has "and declares a version"  "$(cat "$_mf" 2>/dev/null)" '"version"'
has "and a name"              "$(cat "$_mf" 2>/dev/null)" '"name"'
is  "and the version is a dotted number" \
    "$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9][0-9.]*\)".*/\1/p' "$_mf" 2>/dev/null | grep -c .)" "1"

# ------------------------------------------ executable-check, the bit that ships ---
# Felix runs entirely through scripts something else invokes: the CLI, this
# suite, every scanner under bin/ and every hook under hooks/. A lost executable
# bit does not fail here — it fails in somebody else's session, silently, once
# the plugin is deployed. So the check must (a) enumerate what is actually on
# disk, or a scanner added next week is unprotected the day it lands, (b) judge
# by the shebang rather than the directory, or a README turns the gate red, and
# (c) distinguish "every script is fine" from "I could not look", which is the
# failure this repository keeps rediscovering under a green line.
#
# The fixture is a small invented engine, not a copy of the real one: the count
# it reports is then a number the assertions can name, and a check that silently
# stopped enumerating would have to lie about it rather than merely look busy.
printf '\nexecutable-check: the bit that fails in somebody else session\n'
EXC="$TMP/executable-check"
mkdir -p "$EXC/engine/harness/bin" "$EXC/engine/harness/hooks" \
         "$EXC/engine/harness/tests" "$EXC/deep/nested"
for _xf in felix tests/run bin/alpha-scan bin/beta-check hooks/session-start hooks/pre-tool; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$EXC/engine/harness/$_xf"
  chmod 755 "$EXC/engine/harness/$_xf"
done
# Two files that live in those same directories and are not scripts. Both are
# created 644, which is the whole point: if the check reads names or directories
# instead of first lines, these are the false alarms it raises.
printf '# notes\n\nWhat lives under bin/, and why.\n' > "$EXC/engine/harness/bin/NOTES.md"
printf 'event\tpurpose\nPreToolUse\tdeny\n'           > "$EXC/engine/harness/hooks/events.tsv"
( _fx_cd "$EXC" && git init -q -b main && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm seed ) >/dev/null 2>&1
# macOS resolves /var to /private/var and the engine resolves the same way, so
# compare against what the filesystem calls this directory, not what mktemp did.
EXC="$(cd "$EXC" && pwd -P)"
_xc()   { ( cd "$1" && "$REAL_HARNESS/bin/executable-check" 2>&1; echo "rc=$?" ); }
# Exact, for the reason the deploy-check block gives: "rc=1" as a substring is
# satisfied by rc=126 and rc=127, which are a checker that never ran at all.
_xcrc() { printf '%s' "${1##*rc=}"; }
# Committed after every mutation, so a reading of the index and a reading of the
# worktree cannot disagree about what this fixture says.
_xcc()  { ( _fx_cd "$EXC" && git add -A \
            && git -c user.name=t -c user.email=t@t commit -qm case ) >/dev/null 2>&1; }

if [ -x "$REAL_HARNESS/bin/executable-check" ]; then
  out="$(_xc "$EXC")"
  is  "an engine whose every script carries its bit exits 0" "$(_xcrc "$out")" "0"
  has "and says how many scripts it examined" "$out" "6 script"

  # Enumerated from the directory, never from a list of names. A fixed list
  # cannot contain a file that did not exist when the list was written, so the
  # count moving is the only evidence that the enumeration is real.
  printf '#!/usr/bin/env bash\nexit 0\n' > "$EXC/engine/harness/bin/newly-added-scanner"
  chmod 755 "$EXC/engine/harness/bin/newly-added-scanner"; _xcc
  out="$(_xc "$EXC")"
  has "a scanner added today is examined without anyone editing the check" "$out" "7 script"
  chmod 644 "$EXC/engine/harness/bin/newly-added-scanner"; _xcc
  out="$(_xc "$EXC")"
  is  "and one that arrives without its bit fails, where a fixed list saw nothing" \
      "$(_xcrc "$out")" "1"
  has "naming the scanner nobody listed" "$out" "engine/harness/bin/newly-added-scanner"
  chmod 755 "$EXC/engine/harness/bin/newly-added-scanner"; _xcc

  # The same claim for hooks, which are the half nobody runs by hand.
  printf '#!/usr/bin/env bash\nexit 0\n' > "$EXC/engine/harness/hooks/brand-new-hook"
  chmod 644 "$EXC/engine/harness/hooks/brand-new-hook"; _xcc
  out="$(_xc "$EXC")"
  is  "a hook added today without its bit fails the same way" "$(_xcrc "$out")" "1"
  rm -f "$EXC/engine/harness/hooks/brand-new-hook"; _xcc

  # The two named entry points, bare at the same time. One report that stops at
  # the first bad file leaves the second to be found by whoever it breaks.
  chmod 644 "$EXC/engine/harness/felix" "$EXC/engine/harness/tests/run"; _xcc
  out="$(_xc "$EXC")"
  is  "the entry point and the suite runner, both bare, fail" "$(_xcrc "$out")" "1"
  has "naming the entry point" "$out" "engine/harness/felix"
  has "and the suite runner beside it, rather than stopping at the first" \
      "$out" "engine/harness/tests/run"
  chmod 755 "$EXC/engine/harness/felix" "$EXC/engine/harness/tests/run"; _xcc

  # What makes a file a script is its first line. NOTES.md has sat in bin/ at 644
  # through every assertion above without turning anything red — but so would a
  # check that skipped the directory, or skipped every name it did not know. So
  # arm that exact path first: same file, same 644 mode, a shebang added. Caught
  # with the shebang and ignored without it is the only pair of results that says
  # the first line is what is being read.
  printf '#!/usr/bin/env bash\nexit 0\n' > "$EXC/engine/harness/bin/NOTES.md"; _xcc
  out="$(_xc "$EXC")"
  is  "a file under bin/ that begins with a shebang is a script, and its bare mode is caught" \
      "$(_xcrc "$out")" "1"
  has "named as the script it is" "$out" "engine/harness/bin/NOTES.md"
  printf '# notes\n\nWhat lives under bin/, and why.\n' > "$EXC/engine/harness/bin/NOTES.md"; _xcc
  out="$(_xc "$EXC")"
  is  "while the same path without one is documentation, and the run stays green" \
      "$(_xcrc "$out")" "0"

  # Could not look is not nothing wrong. Both ways in.
  is  "outside a git repository it cannot look, exit 2" "$(_xcrc "$(_xc "$TMP")")" "2"
  EXN="$TMP/executable-check-no-engine"; mkdir -p "$EXN"
  ( _fx_cd "$EXN" && git init -q -b main && printf 'x\n' > README.md && git add -A \
    && git -c user.name=t -c user.email=t@t commit -qm s ) >/dev/null 2>&1
  is  "a checkout with no engine directory cannot look either, exit 2" \
      "$(_xcrc "$(_xc "$EXN")")" "2"

  # And the emptiness this project keeps finding dressed as an all-clear: the
  # directories are there, they hold nothing it recognises, and zero scripts
  # examined is a checker that answered about itself rather than about the tree.
  EXZ="$TMP/executable-check-empty"
  mkdir -p "$EXZ/engine/harness/bin" "$EXZ/engine/harness/hooks"
  printf '# notes\n'          > "$EXZ/engine/harness/bin/NOTES.md"
  printf 'event\tpurpose\n'   > "$EXZ/engine/harness/hooks/events.tsv"
  ( _fx_cd "$EXZ" && git init -q -b main && git add -A \
    && git -c user.name=t -c user.email=t@t commit -qm s ) >/dev/null 2>&1
  is  "an engine holding nothing it recognises is emptiness, not an all clear" \
      "$(_xcrc "$(_xc "$EXZ")")" "2"
  # Armed: the same tree, one real script. If this does not flip, the assertion
  # above was measuring a fixture the check could never have read.
  printf '#!/usr/bin/env bash\nexit 0\n' > "$EXZ/engine/harness/bin/gamma-scan"
  chmod 755 "$EXZ/engine/harness/bin/gamma-scan"
  ( _fx_cd "$EXZ" && git add -A && git -c user.name=t -c user.email=t@t commit -qm one ) >/dev/null 2>&1
  is  "and one real script in that same tree is examined, so it was the emptiness" \
      "$(_xcrc "$(_xc "$EXZ")")" "0"

  # From anywhere inside the checkout. A search rooted at the working directory
  # finds nothing from deep/nested, which by rule 6 is exit 2 rather than 0.
  is  "from a nested subdirectory the verdict is unchanged" \
      "$(_xcrc "$(_xc "$EXC/deep/nested")")" "0"
  chmod 644 "$EXC/engine/harness/bin/alpha-scan"; _xcc
  out="$(_xc "$EXC/engine/harness")"
  is  "and a bare script is still caught from inside the engine itself" "$(_xcrc "$out")" "1"
  chmod 755 "$EXC/engine/harness/bin/alpha-scan"; _xcc
else
  for a in "an engine whose every script carries its bit exits 0" \
           "and says how many scripts it examined" \
           "a scanner added today is examined without anyone editing the check" \
           "and one that arrives without its bit fails, where a fixed list saw nothing" \
           "naming the scanner nobody listed" \
           "a hook added today without its bit fails the same way" \
           "the entry point and the suite runner, both bare, fail" \
           "naming the entry point" \
           "and the suite runner beside it, rather than stopping at the first" \
           "a file under bin/ that begins with a shebang is a script, and its bare mode is caught" \
           "named as the script it is" \
           "while the same path without one is documentation, and the run stays green" \
           "outside a git repository it cannot look, exit 2" \
           "a checkout with no engine directory cannot look either, exit 2" \
           "an engine holding nothing it recognises is emptiness, not an all clear" \
           "and one real script in that same tree is examined, so it was the emptiness" \
           "from a nested subdirectory the verdict is unchanged" \
           "and a bare script is still caught from inside the engine itself"; do
    skip "$a" "no bin/executable-check beside this harness"; done
fi

# --------------------------------------------- the table validator, rows first ---
# docs/2026-09-19-direction-decisions.md §1: a validator before a reader, one
# schema row per table, and a gate check that fails on a table nobody declared.
# The claim the whole layer rests on is narrow and checkable: on a table
# lib/table.sh accepts, every reader family already in the engine reads the
# same rows, and the shapes it refuses are ones on which two of them read
# different ones. Both halves are asserted, the second against each refusal:
# a refusal no two readers need is a rule somebody made up.
printf '\ntable: one row, and the shapes two readers disagree about\n'
TBL="$REAL_HARNESS/lib/table.sh"
TBS="$REAL_HARNESS/templates/schemas.tsv"
TBM="$TMP/table-mut"; mkdir -p "$TBM"
# One table.sh function, in a subshell, so nothing it defines leaks into the
# rest of the suite; and its exit status alone.
_tb()   { ( . "$TBL" 2>/dev/null; "$@" ); }
_tbrc() { ( . "$TBL" 2>/dev/null; "$@" >/dev/null 2>&1; echo $? ); }
# The reader families, each spelled as the engine spells it and, like the
# engine, pinning no locale: the caller's LC_ALL decides, and the kill test
# runs them under two. _tf_cells prints the cells an IFS read assigns,
# rejoined, so a collapsed empty cell shows as a changed row; _tf_cr is
# exceptions.sh's scan, the one reader that strips a CR.
_tf_grep()  { grep -vE '^[[:space:]]*(#|$)' "$1"; }
_tf_awk()   { awk '!/^[[:space:]]*(#|$)/' "$1"; }
_tf_case()  { while IFS=$'\t' read -r _tl; do case "$_tl" in ''|'#'*) continue ;; esac
                printf '%s\n' "$_tl"; done < "$1"; }
_tf_cells() { while IFS=$'\t' read -r _c1 _c2 _c3 _c4 _c5 _c6 _c7 _c8 _c9 _cx; do
                case "$_c1" in ''|'#'*) continue ;; esac
                _to="$_c1"; for _c in "$_c2" "$_c3" "$_c4" "$_c5" "$_c6" "$_c7" "$_c8" "$_c9" "$_cx"; do
                  [ -n "$_c" ] && _to="$_to	$_c"; done
                printf '%s\n' "$_to"; done < "$1"; }
_tf_raw()   { while IFS= read -r _tl || [ -n "$_tl" ]; do case "$_tl" in ''|'#'*) continue ;; esac
                printf '%s\n' "$_tl"; done < "$1"; }
_tf_first() { awk -F'\t' '$1 !~ /^[[:space:]]*#/ && $1 != ""' "$1"; }
_tf_cr()    { awk '/^[[:space:]]*(#|$)/ { next } { sub(/\r$/, ""); print }' "$1"; }
TBFAMS="_tf_awk _tf_case _tf_cells _tf_raw _tf_first _tf_cr"
# Which families read <file> differently from the grep filter, under the
# locale in $2 (C when absent), by name.
_tfsplit() { local _f _s="" _lc="${2:-C}"
  LC_ALL="$_lc" _tf_grep "$1" > "$TBM/want" 2>&1
  for _f in $TBFAMS; do LC_ALL="$_lc" "$_f" "$1" > "$TBM/got" 2>&1; cmp -s "$TBM/want" "$TBM/got" || _s="$_s $_f"; done
  printf '%s' "$_s"; }
# A UTF-8 locale this machine has, for the half of the kill test where the
# readers run as a founder's shell runs them. None is a skip, said as one.
TBU8="$(locale -a 2>/dev/null | grep -iE '^(C|en_US)\.utf-?8$' | head -1)"

# The kill test, over every table in this repository: every *.tsv, and every
# file a schema row declares under another name.
_engine_manifest_build
if [ -n "$TBROOT" ] && [ -f "$TBROOT/engine/harness/templates/schemas.tsv" ]; then
  _tbnames="$(_tb felix_table_rows "$TBROOT/engine/harness/templates/schemas.tsv" | cut -f1)"
  _tbdiff=""; _tbfam=""; _tbfam8=""; _tbn=0
  while IFS= read -r _tbf; do
    [ -f "$TBROOT/$_tbf" ] || continue
    case "$_tbf" in
      *.tsv) ;;
      *) grep -qxF "${_tbf##*/}" <<<"$_tbnames" || continue ;;
    esac
    _tbn=$((_tbn+1))
    _tb felix_table_rows "$TBROOT/$_tbf" > "$TBM/rows" 2>&1
    LC_ALL=C _tf_grep "$TBROOT/$_tbf" > "$TBM/grep" 2>&1
    cmp -s "$TBM/rows" "$TBM/grep" || _tbdiff="$_tbdiff $_tbf"
    _tbs="$(_tfsplit "$TBROOT/$_tbf" C)"; [ -z "$_tbs" ] || _tbfam="$_tbfam $_tbf:$_tbs"
    if [ -n "$TBU8" ]; then
      _tbs="$(_tfsplit "$TBROOT/$_tbf" "$TBU8")"; [ -z "$_tbs" ] || _tbfam8="$_tbfam8 $_tbf:$_tbs"
    fi
  done <<EOF
$(git -C "$TBROOT" ls-files)
EOF
  [ "$_tbn" -gt 20 ] && ok "the kill test reads every table in the tree" \
                     || bad "the kill test reads every table in the tree" "only $_tbn found under $TBROOT"
  is  "over every table, felix_table_rows is byte-identical to the grep filter 42 readers use" "$_tbdiff" ""
  is  "and on every table, every other reader family reads those same rows" "$_tbfam" ""
  if [ -n "$TBU8" ]; then
    is "and they still do in a UTF-8 locale, as a founder's shell runs them" "$_tbfam8" ""
  else
    skip "and they still do in a UTF-8 locale, as a founder's shell runs them" "no UTF-8 locale on this machine"
  fi
else
  for a in "the kill test reads every table in the tree" \
           "over every table, felix_table_rows is byte-identical to the grep filter 42 readers use" \
           "and on every table, every other reader family reads those same rows" \
           "and they still do in a UTF-8 locale, as a founder's shell runs them"; do
    skip "$a" "no git checkout with a schemas.tsv above this harness"; done
fi

# Each refusal, on a copy of a table the engine ships. risk.tsv declares four
# to six columns, so it can carry every shape at once. For each: refused, and
# refused for that reason; and where the refusal is about which rows are read,
# some family reads the copy apart from the grep filter.
_tbmut() {  # <text to append, printf format>
  cp "$REAL_HARNESS/templates/risk.tsv" "$TBM/risk.tsv"; printf "$1" >> "$TBM/risk.tsv"; }
_tbrefuse() {  # <label> <reason> [split]
  local _o _r _s
  _o="$(_tb felix_table_check "$TBS" "$TBM/risk.tsv")"; _r=$?
  _s="$(_tfsplit "$TBM/risk.tsv" C)"
  if [ "$_r" = "1" ] && cut -f2 <<<"$_o" | grep -qx "$2" \
     && { [ "${3:-}" != "split" ] || [ -n "$_s" ]; }; then
    ok "$1"
  else
    bad "$1" "rc=$_r reasons=[$(printf '%s' "$_o" | cut -f2 | tr '\n' ' ')] families apart=[$_s]"
  fi
}
_tbmut '  # red\tpath\t^x/\tan indented comment\n'
_tbrefuse "an indented comment is refused, and the read-and-case loops take it for a row" indented-comment split
_tbmut '\t# red\tpath\t^x/\ta tab-indented comment\n'
_tbrefuse "a tab-indented comment is refused, and the raw case loops take it for a row" indented-comment split
_tbmut '  \n'
_tbrefuse "a line of spaces is refused, and the raw case loops take it for a row" whitespace-line split
_tbmut 'red\tpath\t^cr/\ta row ending in CR\r\n'
_tbrefuse "a CR is refused, and only exceptions.sh strips it from the last cell" carriage-return split
_tbmut 'red\tpath\t^nl/\ta last row with no newline'
_tbrefuse "a missing final newline is refused, and the done-< loops drop that row" no-final-newline split
_tbmut 'red\tpath\t^n\000ul/\ta NUL\n'
_tbrefuse "a NUL is refused, and grep reads the whole table as binary" nul-byte split
_tbmut 'red\t\tpath\t^e/\tan empty cell\n'
_tbrefuse "an empty cell is refused, and an IFS read moves every later column" empty-cell split
# Whether a UTF-8 locale takes U+3000 for a space is the machine's business,
# which is the reason for the refusal, so no split is demanded of this one.
_tbmut '\343\200\200# red\tpath\t^u/\tan ideographic space before the hash\n'
_tbrefuse "a line that begins with a non-ASCII byte is refused, since whether it is a comment depends on the locale" nonascii-lead
_tbmut 'red\tpath\t^enc/\ta Latin-1 byte \351 in a cell\n'
_tbrefuse "bytes that are not UTF-8 are refused, since grep drops such a line in a UTF-8 locale" encoding
# macOS iconv, the first instrument, still accepts the forms RFC 2279 had and
# RFC 3629 dropped, and macOS awk in a UTF-8 locale aborts on them and reads no
# rows at all. Found by a blind author's test, so it is pinned here.
_tbmut 'red\tpath\t^u8/\ta code point past U+10FFFF: \364\220\200\200\n'
_tbrefuse "a code point past U+10FFFF is refused as not UTF-8, which the platform's iconv lets through" encoding
printf 'a\tb\n\000' > "$TBM/risk.tsv"
is  "a file that ends in a NUL is refused for its last byte as well as for the NUL" \
    "$(_tb felix_table_check "$TBS" "$TBM/risk.tsv" | cut -f2 | grep -xE 'no-final-newline|nul-byte' | LC_ALL=C sort | tr '\n' ' ')" "no-final-newline nul-byte "
_tbmut 'red\tpath\t^w/\treason\tverifier\tcount:x\ta seventh cell\n'
_tbrefuse "a row wider than the schema is refused" cells
# The readers that split on a wide row do not differ in which rows they read,
# only in what a cell holds, so they are asked directly: the reason column, as
# a four-variable read assigns it and as cut reads it.
_tbw="$(grep '^red	path	\^w/' "$TBM/risk.tsv")"
IFS=$'\t' read -r _ _ _ _tbr4 <<EOF
$_tbw
EOF
is  "and on it the reason a four-variable read assigns is not the reason cut -f4 reads" \
    "$([ "$_tbr4" = "$(printf '%s\n' "$_tbw" | cut -f4)" ] && echo same || echo apart)" "apart"
_tbmut 'red\n'
_tbrefuse "a row with no tab is refused" cells
_tbn1="$(printf 'red\n' | cut -f2)"
IFS=$'\t' read -r _ _tbn2 <<EOF
red
EOF
is  "and on it cut -f2 reads the first cell where an IFS read reads nothing" "$_tbn1|$_tbn2" "red|"
mkdir -p "$TBM/link"; cp "$REAL_HARNESS/templates/risk.tsv" "$TBM/link/target.tsv"
ln -s target.tsv "$TBM/link/risk.tsv"
is  "a table that is a link is refused: the escape check compares the link's text and a reader reads its target" \
    "$(_tb felix_table_check "$TBS" "$TBM/link/risk.tsv" | cut -f2)" "symlink"

# What it must not refuse, and why each is safe: every family reads it alike.
_tbmut 'red\tpath\t^t/ \ta reason with a # inside, \303\251t\303\251 in UTF-8, and trailing spaces  \n\nyellow\tpath\t^four/\tfour cells of six\n'
out="$(_tb felix_table_check "$TBS" "$TBM/risk.tsv")"; rc=$?
is  "a # in a later cell, UTF-8 text, trailing spaces, a blank line and an optional column left off are accepted" "$rc" "0"
is  "and every reader family reads that table alike" "$(_tfsplit "$TBM/risk.tsv" C)" ""

# Emptiness means what the table's row says it means.
grep '^#' "$REAL_HARNESS/templates/probes.tsv" > "$TBM/probes.tsv"
out="$(_tb felix_table_check "$TBS" "$TBM/probes.tsv")"; rc=$?
is  "a probes table with comments and no row is refused, since its row says emptiness is" "$rc" "1"
has "and says so as emptiness" "$out" "	empty	"
: > "$TBM/probes.tsv"
is  "and so is a zero-byte one" "$(_tbrc felix_table_check "$TBS" "$TBM/probes.tsv")" "1"
cp "$REAL_HARNESS/templates/exceptions.tsv" "$TBM/exceptions.tsv"
is  "while the exception table's seeded, rowless state is accepted" \
    "$(_tbrc felix_table_check "$TBS" "$TBM/exceptions.tsv")" "0"
is  "an absent file cannot be examined, exit 2" \
    "$(_tbrc felix_table_check "$TBS" "$TBM/not-there.tsv")" "2"
printf 'a\tb\n' > "$TBM/undeclared.tsv"
is  "and a table with no schema row cannot be examined either: undeclared is not clean" \
    "$(_tbrc felix_table_check "$TBS" "$TBM/undeclared.tsv")" "2"
# A one-column table is a list: a row of one cell is the row, and a tab in it
# is a second cell nobody declared.
printf 'ci\ntests\n' > "$TBM/capabilities"
is  "a one-column table of one-cell rows is accepted" "$(_tbrc felix_table_check "$TBS" "$TBM/capabilities")" "0"
printf 'ci\tand more\n' > "$TBM/capabilities"
is  "and a tab in one of its rows is a refused second cell" "$(_tbrc felix_table_check "$TBS" "$TBM/capabilities")" "1"

# A column written `grounding?` is a glob. Counted by a shell loop over an
# unquoted list, it would match whatever files sit where the caller stands, and
# two of them would widen the table by one: a seven-cell stack row accepted.
mkdir -p "$TBM/glob"; : > "$TBM/glob/groundingA"; : > "$TBM/glob/groundingB"
printf 'plugin\tx@m\tm\tlow\tcore\tDECLARED\ta seventh cell\n' > "$TBM/glob/stack.tsv"
is  "a column marked optional is not a glob: a seven-cell stack row is refused beside files it would match" \
    "$(cd "$TBM/glob" && _tbrc felix_table_check "$TBS" stack.tsv)" "1"

# schemas.tsv's own rows: the values only a schema row can get wrong.
printf 'a.tsv\tnowhere\tx y\tallowed\na.tsv\ttree\tx y\tsometimes\nb/c.tsv\ttree\tx? y\tallowed\nd.tsv\ttree\tx Y\tallowed\n' > "$TBM/schemas.tsv"
out="$(_tb felix_table_schema_malformed "$TBM/schemas.tsv" | cut -f2 | LC_ALL=C sort -u | tr '\n' ' ')"
is  "a schema row with a bad place, a bad emptiness, a path, a required column after an optional one, a bad name or a duplicate is malformed" \
    "$out" "columns duplicate empty lives table "
printf 'e.tsv\ttree\tname note?\tallowed\nf\ttree\tone\tallowed\n' > "$TBM/schemas.tsv"
is  "and so is one whose rows may stop after one cell, while a true one-column table is not" \
    "$(_tb felix_table_schema_malformed "$TBM/schemas.tsv" | cut -f1,2 | tr '\t\n' ': ')" "1:columns "
printf 'g.tsv\ttree\tx y\tallowed\textra\nh.tsv\ttree\tx  y\tallowed\n' > "$TBM/schemas.tsv"
is  "a schema row of five cells, and columns with a doubled space, are malformed on their own terms" \
    "$(_tb felix_table_schema_malformed "$TBM/schemas.tsv" | cut -f1,2 | tr '\t\n' ': ')" "1:cells 2:columns "
is  "the shipped schema has none of those" \
    "$(_tb felix_table_schema_malformed "$TBS" | grep -c .)" "0"

# The writers of the two memory stores the schema declares, checked against
# their rows: the recorder's rows from this suite's own sessions, and a decline.
if [ -s "$MEM/widget/lifecycle.log" ]; then
  out="$(_tb felix_table_check "$TBS" "$MEM/widget/lifecycle.log")"; rc=$?
  is "every lifecycle.log row the recorder wrote in this suite is a row its schema accepts" "$rc" "0"
else
  bad "every lifecycle.log row the recorder wrote in this suite is a row its schema accepts" "no lifecycle.log was written"
fi
if [ -s "$MEM/widget/decisions.log" ]; then
  is "every decisions.log row felix route --ack wrote in this suite is a row its schema accepts" \
     "$(_tbrc felix_table_check "$TBS" "$MEM/widget/decisions.log")" "0"
else
  bad "every decisions.log row felix route --ack wrote in this suite is a row its schema accepts" "no decisions.log was written"
fi
# A reason is the one field a session writes freely. A tab in it was a fifth
# cell, and a newline a second row made of the end of a sentence.
( FELIX_MEMORY="$TBM/ackmem"; export FELIX_MEMORY
  . "$REAL_HARNESS/lib/resolve.sh"; . "$REAL_HARNESS/lib/route.sh"
  felix_route_ack ackp "$TBM/ackroot" "$TBM/ackhome" "$(printf 'not this\tone, since\nit has no browser surface\r')" ) >/dev/null 2>&1
_tbd="$TBM/ackmem/ackp/decisions.log"
is  "a decline whose reason holds a tab, a newline and a CR is one row" "$(grep -c . "$_tbd" 2>/dev/null)" "1"
is  "of four cells, as its schema row says" "$(awk -F'\t' '{print NF}' "$_tbd" 2>/dev/null)" "4"
is  "which the validator accepts" "$(_tbrc felix_table_check "$TBS" "$_tbd")" "0"

# A newborn project: every table felix new seeds has a row, and is accepted.
# A home of its own, so the fixture home later assertions count projects in
# is not changed by this one.
_cmstub_build
NB="$TMP/newborn"; NBH="$TMP/newborn-home"; mkdir -p "$NB" "$NBH/projects"
( _fx_cd "$NB" && git init -q -b main )
( cd "$NB" && FELIX_HOME="$NBH" PATH="$CMSTUB:$PATH" "$FELIX" new newborn ) >/dev/null 2>&1
_nbn=0; _nbbad=""
for _nbf in "$NBH/projects/newborn/"*.tsv "$NBH/projects/newborn/capabilities"; do
  [ -f "$_nbf" ] || continue
  _nbn=$((_nbn+1))
  _tb felix_table_check "$TBS" "$_nbf" >/dev/null 2>&1 || _nbbad="$_nbbad ${_nbf##*/}"
done
[ "$_nbn" -ge 9 ] && ok "felix new seeds its tables in a home of its own" \
                  || bad "felix new seeds its tables in a home of its own" "only $_nbn table(s) in $NBH/projects/newborn"
is  "and every one has a schema row and is accepted" "$_nbbad" ""
[ -f "$NBH/projects/newborn/schemas.tsv" ] && bad "and schemas.tsv is not among them: a project declares no schema" \
                                            || ok  "and schemas.tsv is not among them: a project declares no schema"

