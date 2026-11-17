printf '\nno engine test reads a pipe through a grep that can stop early\n'
# Under pipefail, `producer | grep -q x` reads "absent" for a value that is
# there whenever grep matches and exits while the producer still has output to
# write: the producer's next write breaks the pipe, it dies of SIGPIPE (141),
# and pipefail hands that status to the `if`, `&&`, `||` or `!` reading it.
# The first pair below pins that on the machine running the suite, because the
# lint after it is only worth having while it holds.
#
# _spl_scan is the lint's one matcher, and the same code reads the samples and
# the engine. It prints file:line wherever a `|` that is not half of `||` is
# followed, after optional `command`, `env`, `nice`, `timeout N`, `if` and `!`
# words, VAR=value prefixes and a leading backslash, by grep, egrep or fgrep
# that can stop reading early. One way is an option that lets it: -q, -m, -l or
# -L, alone or inside a cluster (-qxF, -Eq, -m1), or --quiet, --silent,
# --max-count, --files-with-matches or --files-without-match. Options are read
# letter by letter, and one that takes an argument (-e, -f, -A, -B, -C, -d, -D,
# --regexp, --file, --context and its halves) takes the rest of its word, or
# the next word, with it: `-e pat -q` is flagged, and `-eline` is not read as
# -l. The other is a standard output on /dev/null, whatever the options: GNU
# grep, the grep on Linux, reads that as -q and stops at its first match, even
# given -c. So `>/dev/null`, `> /dev/null`, `1>`, `>>`, `&>`, `>&` or `>|`,
# before or after `2>&1`, anywhere in grep's own command is named. That command
# runs to the first `|`, `;` or `&&` outside quotes, or to a comment, and on
# past a backslash that ends its line; it does not stop at `)` or a lone `&`.
# A digit glued to a word before `>` is
# part of the word, so `y2>/dev/null` is standard output; `2>/dev/null` alone
# is not named, since where grep's errors go changes nothing. A pipe that ends
# one line, or ends its code before a comment, carries onto the next line of
# code, and a line may start with the pipe; bash reads both as one chain, and
# it carries a pipe across blank and comment lines too. Comment lines are
# skipped.
#
# What it does not see: `head`, `sed q` or an awk that exits early at the end of
# a pipeline whose status is tested (there were two, felix_overnight_field's
# `cut | head -1` read with `|| return 1` and felix_marketplace_root's
# `sed | sed | head -1` read with `|| mroot=""`, safe only because each reads
# one line, and both now read to the end; a new one would pass this lint); a
# grep whose standard output reaches /dev/null only through a redirect on its
# caller, on a brace group around it, on a subshell that closes on a later line
# (one that closes on grep's own line is named), or through exec; a quoted
# target (`>"/dev/null"`, `>'/dev/null'`); a pipe into
# a brace group or subshell that holds the grep; a grep named by its path or
# through a variable; a wrapper given options of its own (`env -i`,
# `nice -n 5`, `timeout -s KILL 5`); a VAR= prefix whose quoted value holds a
# space; an early option placed after the pattern, or on a continuation line
# inside grep's own arguments; a producer whose status is tested through a
# variable; code built at run time with eval. What it names that is no pipe:
# looking for the pipe and the grep, it reads quoted strings and here-doc
# bodies as code, so a message or a pattern holding `| grep -q` is named, and
# so is the line after a code line whose trailing comment ends in `|`; and
# since grep's command runs past `)` and a lone `&`, a redirect to /dev/null
# that belongs to a later command on the line is named, as is `/dev/nullx`.
_spl_scan() {
  awk '
    # grep, after the words that may stand before it, able to stop early.
    function early(s) {
      sub(/^[ \t]+/, "", s)
      while (s ~ /^(command|env|nice|if|!)[ \t]/ || s ~ /^timeout[ \t]+[0-9.]+[smhd]?[ \t]/ ||
             s ~ /^[A-Za-z_][A-Za-z0-9_]*=[^ \t]*[ \t]/) {
        if (s ~ /^timeout[ \t]/) sub(/^timeout[ \t]+/, "", s)
        sub(/^[^ \t]*[ \t]+/, "", s)
      }
      sub(/^\\/, "", s)
      if (s !~ /^[ef]?grep[ \t]/) return 0
      sub(/^[ef]?grep[ \t]+/, "", s)
      if (quits(s) || devnull(s)) return 1
      if (cont) gpc = 1
      return 0
    }
    # An option among the words that lets grep stop early.
    function quits(s,   w, n, i, k, c) {
      n = split(s, w, /[ \t]+/)
      for (i = 1; i <= n; i++) {
        if (w[i] == "--") return 0
        if (w[i] ~ /^--(quiet|silent|max-count|files-with-matches|files-without-match)(=|$)/) return 1
        if (w[i] ~ /^--(regexp|file|after-context|before-context|context)$/) { i++; continue }
        if (w[i] ~ /^--/) continue
        if (w[i] !~ /^-[A-Za-z0-9]/) return 0
        for (k = 2; k <= length(w[i]); k++) {
          c = substr(w[i], k, 1)
          if (c ~ /[qmlL]/) return 1
          if (c ~ /[efABCdD]/) { if (k == length(w[i])) i++; break }
        }
      }
      return 0
    }
    # A standard output on /dev/null in the words, up to where the command ends.
    # Quoted strings become one letter first, so a | or ; inside a pattern ends
    # nothing and a digit after a quote stays glued to a word. Sets cont when the
    # command runs on past a backslash that ends the line.
    function devnull(s,   t, m, pre, d) {
      t = s
      gsub(/\047[^\047]*\047/, "Q", t)
      gsub(/"([^"\\]|\\.)*"/, "Q", t)
      gsub(/>\|/, ">", t)
      sub(/(\||;|&&|[ \t]#).*/, "", t)
      cont = (t ~ /\\[ \t]*$/)
      while (match(t, /&?[0-9]*>>?&?[ \t]*\/dev\/null/)) {
        m = substr(t, RSTART, RLENGTH)
        pre = (RSTART > 1) ? substr(t, RSTART - 1, 1) : ""
        t = substr(t, RSTART + RLENGTH)
        if (m ~ /^&/) return 1
        d = m; sub(/>.*/, "", d)
        if (d == "" || d == "1" || pre ~ /[^ \t]/) return 1
      }
      return 0
    }
    FNR == 1 { open = 0; gp = 0 }
    /^[ \t]*(#|$)/ { gp = 0; next }
    {
      # A line a backslash carried a grep onto: a redirect here is the grep one.
      if (gp) {
        if (devnull($0)) { print FILENAME ":" gp; gp = 0 }
        else if (!cont) gp = 0
      }
      gpc = 0
      hit = open && early($0)
      rest = $0
      while (!hit && (j = index(rest, "|")) > 0) {
        if (substr(rest, j + 1, 1) == "|") { rest = substr(rest, j + 2); continue }
        rest = substr(rest, j + 1)
        hit = early(rest)
      }
      if (hit) print FILENAME ":" FNR
      else if (gpc) gp = FNR
      t = $0; sub(/[ \t]*(\\[ \t]*)?$/, "", t)
      open = (t ~ /(^|[^|])[|]([ \t]+#.*)?$/)
    }
  ' "$@"
}

# ~1 MB with the match on line 1: the writer fills the pipe and blocks, grep
# reads, matches and exits, and the writer's next write always breaks. That
# takes the race out, so the first check fails every time the premise holds.
_spl_big="$(seq 1 160000)"
_spl_ps="$( set -o pipefail
            printf '%s\n' "$_spl_big" 2>/dev/null | grep -qx 1
            printf '%s %s' "$?" "${PIPESTATUS[1]}" )"
case "$_spl_ps" in
  0\ *) bad "under pipefail, printf of a megabyte piped into grep -q reads a match on its first line as absent" \
            "the pipe read the line as present (statuses: $_spl_ps), so nothing here shows the shape the lint refuses can fail" ;;
  *\ 0) ok  "under pipefail, printf of a megabyte piped into grep -q reads a match on its first line as absent" ;;
  *)    bad "under pipefail, printf of a megabyte piped into grep -q reads a match on its first line as absent" \
            "grep itself did not report the match (pipeline status, grep status: $_spl_ps), so this is not the broken pipe" ;;
esac
if ( set -o pipefail; grep -qx 1 <<<"$_spl_big" ); then
  ok  "and the same test fed a here-string finds it"
else
  bad "and the same test fed a here-string finds it" \
      "the here-string form missed line 1 of the megabyte, so it is no replacement for the pipe"
fi

# The matcher on shapes written out, so a change to it that drops one shows as
# a named miss rather than as a quiet engine scan. Each sample is a file; the
# answer is the line numbers flagged in it.
mkdir -p "$TMP/_spl"
_spl_flags() {
  printf '%s\n' "$1" > "$TMP/_spl/sample"
  ( cd "$TMP/_spl" && _spl_scan sample ) | awk -F: '{ printf "%s%s", s, $NF; s = " " }'
}
is "the lint flags a pipe into grep -q as a cluster, with no space after the pipe, or after another flag" \
   "$(_spl_flags 'x | grep -qxF y
x |grep -Eq y
x | grep -qvE y
x | grep -E -q y')" "1 2 3 4"
is "the lint flags grep reached through command or a VAR=value prefix" \
   "$(_spl_flags 'x | command grep -q y
x | LC_ALL=C grep -q y
x | LC_ALL=C command grep -qx y')" "1 2 3"
is "the lint flags grep reached through env, timeout, nice, if, ! or a leading backslash" \
   "$(_spl_flags 'x | \grep -q y
x | env LC_ALL=C grep -q y
x | timeout 5 grep -q y
x | nice grep -q y
x | if grep -q y; then :; fi
x | ! grep -q y')" "1 2 3 4 5 6"
is "the lint flags an early option after an option that takes an argument, attached or apart" \
   "$(_spl_flags 'x | grep -e pat -q y
x | grep -f pats -q
x | grep -A 2 -q y
x | grep --regexp pat -q
x | grep -epat -m1')" "1 2 3 4 5"
is "the lint takes no option's argument for an option: -eline is not -l, and a pattern -quux is not -q" \
   "$(_spl_flags 'x | grep -eline f
x | grep -e -quux f
x | grep -A 2 y')" ""
is "the lint flags every option that lets grep stop early, in egrep and fgrep as well" \
   "$(_spl_flags 'x | grep -m1 y
x | grep --quiet y
x | grep --silent y
x | grep --max-count=1 y
x | egrep -l y
x | fgrep -L y
x | grep --files-with-matches y')" "1 2 3 4 5 6 7"
is "the lint flags a grep -q on the line after a pipe that ends a line, with or without a backslash" \
   "$(_spl_flags 'x |
  grep -q y
z | \
  grep -qx y')" "2 4"
is "the lint flags a grep -q on the line after a pipe that a comment follows" \
   "$(_spl_flags 'x |   # why it is piped
  grep -q y')" "2"
is "the lint flags a line that starts with a pipe into grep -qxF, continuing the line above" \
   "$(_spl_flags 'x \
| grep -qxF y')" "2"
is "the lint leaves an ||, a grep that reads to the end, a pattern after -- and a comment line alone" \
   "$(_spl_flags 'a || grep -q x f
x | grep -c y
x | grep -v y
x | grep -- -q
# x | grep -q y')" ""
is "the lint carries neither an || nor a comment's trailing pipe onto the next line" \
   "$(_spl_flags 'a ||
  grep -q y
# a |
  grep -q y')" ""
# Named on purpose, as the comment above says: pinned so a matcher that learns
# to skip them also has to change what that comment promises.
is "the lint reads a quoted string and a code line's trailing comment as code" \
   "$(_spl_flags "printf 'use: x | grep -q y\\n'
grep -E 'a| grep -q' f
foo  # see a |
grep -q y file")" "1 2 4"
# A grep with no early option whose standard output is /dev/null stops at its
# first match on GNU grep, even with -c, so each of these is the same shape.
is "the lint flags a piped grep whose standard output goes to /dev/null, in each spelling of the redirect" \
   "$(_spl_flags 'x | grep -xF y >/dev/null
x | grep -xF y > /dev/null
x | grep -xF y 1>/dev/null
x | grep -xF y &>/dev/null
x | grep -xF y >/dev/null 2>&1
x | grep -xF y 2>&1 >/dev/null
x | grep -xF y >>/dev/null
x | grep -xF y >& /dev/null
x | grep -xF y >|/dev/null')" "1 2 3 4 5 6 7 8 9"
is "the lint flags it in an if, after a sed, after a quoted | or ;, after --, and given -c" \
   "$(_spl_flags "if printf '%s\\n' \"\$l\" | grep -xF \"\$v\" >/dev/null 2>&1; then :; fi
x | sed 's/:.*//' | grep -xF \"\$v\" >/dev/null 2>&1
x | grep -E 'a|b' >/dev/null
x | grep -xF \"a;b\" >/dev/null
x | grep -- -q >/dev/null
x | grep -c y >/dev/null")" "1 2 3 4 5 6"
is "the lint reads a digit before > as a descriptor only standing alone: 2>/dev/null is not named, y2>/dev/null is" \
   "$(_spl_flags 'x | grep -xF y 2>/dev/null
x | grep -xF y 2> /dev/null
x | grep -xF y2>/dev/null
x | grep -xF "$v"2>/dev/null')" "3 4"
is "the lint flags a redirect on the line a backslash carries the grep onto, and one after a pipe that ends a line" \
   "$(_spl_flags 'x | grep -xF y \
  >/dev/null 2>&1
x |
  grep -xF y >/dev/null')" "1 4"
is "the lint leaves grep -c with its errors on /dev/null, and a redirect that is another command's or a comment's" \
   "$(_spl_flags 'x | grep -c y 2>/dev/null
n="$(x | grep -c . 2>/dev/null)" || n=0
x | grep -xF y | wc -l >/dev/null
x | grep -xF y; z >/dev/null
x | grep -xF y && z >/dev/null
x | grep -xF y || z >/dev/null
grep -xF y file >/dev/null
a || grep -xF y >/dev/null
x | grep -xF y   # not >/dev/null
x | grep -xF y \

>/dev/null')" ""

# The engine itself: the CLI, its libraries, its hooks and its bin scripts. Not
# tests/, which #364 scans once it lands, and not templates/, which is table
# data.
_spl_sites="$( cd "$REAL_HARNESS" 2>/dev/null && [ -f felix ] \
                 || { printf 'no engine to scan at %s\n' "$REAL_HARNESS"; exit 0; }
               set --
               for _spl_x in felix lib/*.sh hooks/* bin/*; do [ -f "$_spl_x" ] && set -- "$@" "$_spl_x"; done
               _spl_scan "$@" || printf 'the scan itself failed, exit %s\n' "$?" )"
_spl_nl='
'
if [ -z "$_spl_sites" ]; then
  ok  "no engine test pipes into a grep that can stop reading early"
else
  bad "no engine test pipes into a grep that can stop reading early" \
      "a false miss under pipefail is possible at: ${_spl_sites//$_spl_nl/ }"
fi

# The project scripts as well: every file git tracks under projects/ that
# starts with #!, the set the project-gates section reads. Each sets pipefail
# itself, and the gates among them are what felix gate runs. #381 converted
# their sites by hand and nothing scanned them after it, so the cloud check
# that #385 wrote into Felix's own gate a week later fed its hook pairs and its
# toolbox to grep -qxF through a pipe. On 2026-10-29, at load near 190, that
# gate printed `cloud FAIL` for code-review, which toolbox.json lists. Tracked
# files only, as there: an untracked script in somebody's home checkout is not
# this suite's verdict to give. A tree where git lists none fails, since a scan
# of nothing would pass.
_spl_psites="$( cd "$REAL_HARNESS/../.." 2>/dev/null && [ -d projects ] \
                  || { printf 'no projects/ beside the engine at %s\n' "$REAL_HARNESS"; exit 0; }
                git ls-files -z -- projects 2>/dev/null | {
                  set --
                  while IFS= read -r -d '' _spl_x; do
                    [ -f "$_spl_x" ] && [ "$(head -c2 "$_spl_x")" = '#!' ] && set -- "$@" "$_spl_x"
                  done
                  [ "$#" -gt 0 ] || { printf 'git lists no script under projects/ at %s\n' "$PWD"; exit 0; }
                  _spl_scan "$@" || printf 'the scan itself failed, exit %s\n' "$?"
                } )"
if [ -z "$_spl_psites" ]; then
  ok  "no project script pipes into a grep that can stop reading early"
else
  bad "no project script pipes into a grep that can stop reading early" \
      "a false miss under pipefail is possible at: ${_spl_psites//$_spl_nl/ }"
fi

printf '\nan escape or a tier over a diff larger than a pipe\n'
# A test that pipes a value into `grep -q` answers "not found" for a value that
# is there whenever grep matches and exits while the writer still has lines to
# write: the writer dies of SIGPIPE, pipefail makes the pipeline 141, and the
# `&&` or `if` reads no match. Past a pipe's capacity with the match early it
# happens every time, and a diff is the value most likely to get that big.
# Three places read one, and each fails open: the confine that demotes a risk
# row, the destructive-SQL escape over the added lines, and a risk table's
# content rows. Each is driven here with 20,000 changed lines (well past the
# 64 KB a pipe holds), the match as early as the producer's order allows, and
# the same fixture with the match on the LAST line as the control. The last
# line cannot be missed, so the control proves the fixture reaches the line
# under test and that a red is the race, not an unreachable branch.
_spd_dir="$TMP/_spd"; mkdir -p "$_spd_dir"
_spd_t="$(printf '\t')"
# has(), with the failure saying what the miss did rather than only what the
# output lacked.
_spd_has() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "$4; got [$2]" ;; esac; }
_spd_nofix() { _spd_why="$1"; shift; for _spd_a in "$@"; do bad "$_spd_a" "$_spd_why"; done; }
_spd_esc() { ( cd "$1" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/escape.sh"
               . "$FROOT/harness/lib/obligations.sh"; felix_escapes "$2" HEAD~1 "$1" ) 2>/dev/null; }

# _spd_deps DIR FIRST LAST: a repository whose one commit rewrites every line of
# a 20,001-line manifest from 1.0 to 2.0, FIRST replacing the first line and
# LAST the last. The unchanged second line ends the first hunk there, so FIRST
# is the hunk's second line, straight after the line it replaced.
_spd_deps() {
  mkdir -p "$1" && ( _fx_cd "$1" && git init -q -b main \
    && awk 'BEGIN { print "pkg00000 = 1.0"; print "# pinned below"
                    for (i = 1; i <= 20000; i++) printf "pkg%05d = 1.0\n", i }' > deps.txt \
    && git add -A && git -c user.name=t -c user.email=t@t commit -qm base \
    && _SPD_F="$2" _SPD_L="$3" awk 'BEGIN { print ENVIRON["_SPD_F"]; print "# pinned below"
                    for (i = 1; i < 20000; i++) printf "pkg%05d = 2.0\n", i
                    print ENVIRON["_SPD_L"] }' > deps.txt \
    && git add -A && git -c user.name=t -c user.email=t@t commit -qm change ) >/dev/null 2>&1
}

# A verifier row demoted to fire only when every changed line is a version bump
# and the package names pair up. The smuggled flag keeps its line's package
# name, so the names still pair and the confine's line pattern is the only
# thing between it and a merge.
_spd_n1="a line outside a risk row's confine near the top of a diff larger than a pipe still fires the row"
_spd_n2="a line outside a risk row's confine on the last line of a diff larger than a pipe fires the row"
_spd_n3="a diff larger than a pipe whose every line is inside the confine still escapes nothing"
mkdir -p "$_spd_dir/proj"
printf 'red\tpath\t^deps\\.txt$\ta manifest that also configures the gate\tverifier\t^[-+]pkg[0-9]+ = [0-9.]+$\n' \
  > "$_spd_dir/proj/risk.tsv"
_spd_deps "$_spd_dir/early" 'pkg00000 = 2.0 --ignore=tests/test_judgment.py' 'pkg20000 = 2.0'
_spd_deps "$_spd_dir/late"  'pkg00000 = 2.0' 'pkg20000 = 2.0 --ignore=tests/test_judgment.py'
_spd_deps "$_spd_dir/clean" 'pkg00000 = 2.0' 'pkg20000 = 2.0'
if [ "$(git -C "$_spd_dir/early" diff -U0 HEAD~1 HEAD 2>/dev/null | wc -c | tr -d ' ')" -gt 262144 ] \
   && [ "$(git -C "$_spd_dir/late"  diff -U0 HEAD~1 HEAD 2>/dev/null | wc -c | tr -d ' ')" -gt 262144 ] \
   && [ "$(git -C "$_spd_dir/clean" diff -U0 HEAD~1 HEAD 2>/dev/null | wc -c | tr -d ' ')" -gt 262144 ]; then
  _spd_has "$_spd_n1" "$(_spd_esc "$_spd_dir/early" "$_spd_dir/proj")" "verifier${_spd_t}deps.txt" \
    "the line outside the confine was missed, the diff read as a version bump, and the row did not fire"
  _spd_has "$_spd_n2" "$(_spd_esc "$_spd_dir/late" "$_spd_dir/proj")" "verifier${_spd_t}deps.txt" \
    "the row did not fire on a line outside its confine that cannot be raced"
  is "$_spd_n3" "$(_spd_esc "$_spd_dir/clean" "$_spd_dir/proj")" ""
else
  _spd_nofix "the fixture was not built: three repositories each with a diff over 256 KB" \
    "$_spd_n1" "$_spd_n2" "$_spd_n3"
fi

# Destructive SQL in the added lines escapes as durable. The first added line of
# the whole diff is the first added line of its first file, so one new file with
# the statement on line 1 puts it first; the control puts it last.
#
# The statement and the row's pattern are put together at run time, never
# written whole here: this file's own added lines are what felix merge reads for
# destructive SQL, and a fixture spelled out would escape the branch that adds it.
_spd_stmt="$(printf '%s%s' 'DROP ' 'TABLE users;')"
_spd_sql() {
  mkdir -p "$1" && ( _fx_cd "$1" && git init -q -b main && printf 'notes\n' > README.md \
    && git add -A && git -c user.name=t -c user.email=t@t commit -qm base \
    && _SPD_W="$2" _SPD_S="$_spd_stmt" awk 'BEGIN { w = ENVIRON["_SPD_W"]; s = ENVIRON["_SPD_S"]
                    if (w == "first") print s
                    for (i = 1; i <= 20000; i++) printf "INSERT INTO t VALUES (%d);\n", i
                    if (w == "last") print s }' > seed.sql \
    && git add -A && git -c user.name=t -c user.email=t@t commit -qm change ) >/dev/null 2>&1
}
_spd_n4="destructive SQL on the first added line of a diff larger than a pipe still escapes as durable"
_spd_n5="destructive SQL on the last added line of a diff larger than a pipe escapes as durable"
mkdir -p "$_spd_dir/none"
_spd_sql "$_spd_dir/sqlfirst" first
_spd_sql "$_spd_dir/sqllast"  last
if [ "$(git -C "$_spd_dir/sqlfirst" diff HEAD~1 HEAD 2>/dev/null | wc -c | tr -d ' ')" -gt 262144 ] \
   && [ "$(git -C "$_spd_dir/sqllast" diff HEAD~1 HEAD 2>/dev/null | wc -c | tr -d ' ')" -gt 262144 ]; then
  _spd_has "$_spd_n4" "$(_spd_esc "$_spd_dir/sqlfirst" "$_spd_dir/none")" "durable${_spd_t}ADDED-LINES" \
    "the destructive statement was missed and the branch would merge without a person seeing it"
  _spd_has "$_spd_n5" "$(_spd_esc "$_spd_dir/sqllast" "$_spd_dir/none")" "durable${_spd_t}ADDED-LINES" \
    "a destructive statement that cannot be raced did not escape"
else
  _spd_nofix "the fixture was not built: two repositories each with a diff over 256 KB" "$_spd_n4" "$_spd_n5"
fi

# A content row raises the tier when its pattern is anywhere in the added lines.
# The row is the shipped template's destructive-SQL row; the added lines are
# handed to the pass directly, in the shape felix_classify_diff hands them.
_spd_cls() { ( . "$FROOT/harness/lib/classify.sh"; _felix_classify_pass "$1" "$2" "$3" ) 2>/dev/null; }
_spd_row="$(printf 'red\tcontent\t^\\+.*(DROP %s|TRUNC%s |DELETE %s [^W]*$)\tdestructive SQL' TABLE ATE FROM)"
_spd_big="$(awk 'BEGIN { for (i = 1; i <= 20000; i++) printf "+INSERT INTO t VALUES (%d);\n", i }')"
_spd_has "a content row matching the first of more added lines than a pipe holds still raises the tier" \
  "$(_spd_cls "$_spd_row" seed.sql "+$_spd_stmt
$_spd_big")" "red${_spd_t}ADDED-LINES${_spd_t}destructive SQL" \
  "the content row's match was missed and the diff kept the default tier"
_spd_has "a content row matching the last of more added lines than a pipe holds raises the tier" \
  "$(_spd_cls "$_spd_row" seed.sql "$_spd_big
+$_spd_stmt")" "red${_spd_t}ADDED-LINES${_spd_t}destructive SQL" \
  "a content row's match that cannot be raced did not raise the tier"

