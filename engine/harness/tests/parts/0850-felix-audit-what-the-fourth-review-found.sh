printf '\nfelix audit: what the fourth review found\n'
_au_build
_au_resume
_rv_build
_nc_build

# A << that opens no here-document, a shift in $(( )) or one in quoted text,
# reads the same on either side of 256K. Beyond it, one no line in the first
# 64K closed was taken for a body running past that window, and where no line
# ever closed it the rest of the command went unread: the runner at its end,
# and a sed -i after a check. Each shape twice, under the size and over it: a
# shift at the start, one in quotes, one in the last 64K, one in a -c script,
# and a sed -i after a check.
mkdir -p "$RV/r4/shift/-p"
awk -v d="$RV/r4/shift/-p" "$_rv_bigawk"'
  BEGIN { for (k = 1; k <= 2; k++) {
            n = (k == 1) ? 15000 : 23000; f = rep("echo filler; ", n); l = rep("echo filler\\n", n)
            one(d "/a" k ".jsonl", "a" k, "x=$((1<<n)); " f "npm test")
            one(d "/b" k ".jsonl", "b" k, "echo \047a<<b\047; " f "npm test")
            one(d "/c" k ".jsonl", "c" k, l "x=$((1<<n))\\nnpm test")
            one(d "/e" k ".jsonl", "e" k, "bash -c \047x=$((1<<n)); " f "npm test\047")
            one(d "/s" k ".jsonl", "s" k, "npm test; x=$((1<<n)); " f "sed -i s/a/b/ src/app.js") } }'
is  "a << that opens no here-document, a shift or one in quotes, reads the same on either side of 256K: the runner after it is a check, and a sed -i after a check leaves the stop stale" \
    "$(_au_counts "$(_au --dir "$RV/r4/shift")")" "8 0 2 0"

# A -c script whose here-document body runs past the first 64K goes on after
# the line that closes the body, to the quote that closes the script, and the
# runner there is the script's: where the body closes in the last 64K, where
# it closes before it, and under 256K. Beside two whose runner follows the
# script, after a ; and on a line of its own.
mkdir -p "$RV/r4/bchd/-p"
awk -v d="$RV/r4/bchd/-p" "$_rv_bigawk"'
  BEGIN { one(d "/u.jsonl", "u", "bash -c \047cat > a.txt <<EOF\\n" rep("row\\n", 40000) "EOF\\nnpm test\047")
          one(d "/t.jsonl", "t", "bash -c \047cat > a.txt <<EOF\\n" rep("row\\n", 70000) "EOF\\nnpm test\047")
          one(d "/m.jsonl", "m", "bash -c \047cat > a.txt <<EOF\\n" rep("row\\n", 30000) "EOF\\n" rep("echo filler; ", 12000) "npm test\047")
          one(d "/a.jsonl", "a", "bash -c \047cat > a.txt <<EOF\\n" rep("row\\n", 70000) "EOF\\necho done\047; npm test")
          one(d "/n.jsonl", "n", "bash -c \047cat > a.txt <<EOF\\n" rep("row\\n", 70000) "EOF\\necho done\047\\nnpm test") }'
is  "a -c script whose here-document body runs past the first 64K goes on after the body to its closing quote, over 256K as under it: the runner there is a check" \
    "$(_au_counts "$(_au --dir "$RV/r4/bchd")")" "5 0 0 0"

# An escaped quote in a double-quoted -c script does not close it, even where
# the cut after the first 64K falls inside the escape: the backslashes before
# the quote are counted from where their run starts, not from the cut. The
# escape across the cut, and five bytes after it.
mkdir -p "$RV/r4/esc/-p"
awk -v d="$RV/r4/esc/-p" "$_rv_bigawk"'
  BEGIN { s = "sh -c \\\"echo "; e = "\\\\\\\""
          for (k = 0; k <= 5; k += 5)
            one(d "/e" k ".jsonl", "e" k, s rep("a", 65534 - length(s) + k) e "; " rep("echo filler; ", 23000) "npm test\\\"") }'
is  "an escaped quote in a -c script is not its close where the cut after the first 64K falls inside the escape: the runner at the script's end is a check" \
    "$(_au_counts "$(_au --dir "$RV/r4/esc")")" "2 0 0 0"

# The log a check's own pipeline writes is not a write after the check where
# the check stands in a group or a compound command whose output is sent on:
# a ( ) or { } group, one with a cd in it, an if and a loop, redirected or
# piped to tee. A write after the group is still after the check.
_rv_one r4/glog r4-gl1 '(npm test) > t.log'
_rv_one r4/glog r4-gl2 '{ npm test; } > t.log'
_rv_one r4/glog r4-gl3 '(npm test) 2>&1 | tee t.log'
_rv_one r4/glog r4-gl4 '(cd web && npm test) > t.log'
_rv_one r4/glog r4-gl5 'if npm test; then echo ok; fi > t.log'
_rv_one r4/glog r4-gl6 'for p in a b; do npm test; done > t.log'
_rv_one r4/glog r4-gl7 '(npm test); echo x > src/a.js'
is  "the log a group's or a compound's own output goes to is not a write after the check in it: 6 such read passed, and a write after the group is still stale" \
    "$(_au_counts "$(_au --dir "$RV/r4/glog")")" "6 0 1 0"

# A cd in a subshell, a $( ), a -c script or a script a shell reads from a
# here-document ends with it, so a relative write after it lands where the
# command started: an edit after the check, not a scratch file. A cd in a
# { } group, or in the command itself, does carry on to the write.
_rv_one r4/cdsub r4-cd1 'npm test; (cd /tmp && ls); echo x > src/a.js'
_rv_one r4/cdsub r4-cd2 'npm test; bash -c '"'"'cd /tmp'"'"'; echo x > src/a.js'
_rv_one r4/cdsub r4-cd3 'npm test; d=$(cd /tmp; pwd); echo x > src/a.js'
_rv_one r4/cdsub r4-cd4 'npm test; bash <<EOF\ncd /tmp\nEOF\necho x > src/a.js'
_rv_one r4/cdsub r4-cd5 'npm test; { cd /tmp; }; echo x > src/a.js'
_rv_one r4/cdsub r4-cd6 'npm test; cd /tmp && echo x > src/a.js'
is  "a cd inside a subshell, a \$( ), a -c script or a shell's here-document ends with it: the relative write after it is an edit after the check, and one after a cd in a { } group or the command itself is scratch" \
    "$(_au_counts "$(_au --dir "$RV/r4/cdsub")")" "2 0 4 0"

# A backslash that ends a comment is the comment's: the line break after it
# still ends the comment, and the next line is a command of its own. So the
# runner there is run, and a --silent on the line after a commented-out flag
# runs after npm test and takes its status. Outside a comment a backslash
# still joins the lines. And over 256K, where the last 64K is read raw from
# after its last quote: 40,000 such comment lines before the runner.
_rv_one r4/cmtbs r4-cb1 '# note \\\nnpm test'
_rv_one r4/cmtbs r4-cb2 'echo start # a note ending in a backslash \\\n./tests/run'
_rv_one r4/cmtbs r4-cb3 'npm test \\\n  # --coverage \\\n  --silent'
_rv_one r4/cmtbs r4-cb4 'npm \\\ntest'
mkdir -p "$RV/r4/cmtbs/-p"
awk -v d="$RV/r4/cmtbs/-p" "$_rv_bigawk"' BEGIN { one(d "/big.jsonl", "cb5", rep("# x \\\\\\n", 40000) "npm test") }'
_rvo="$(_au --dir "$RV/r4/cmtbs")"
[ "$(_au_counts "$_rvo")" = "5 0 0 0" ] && _au_nums "$_rvo" 'pipe|background' 1 \
  && ok  "a backslash at the end of a comment does not join the next line to it: the runner there is a check, and a --silent after a commented-out flag takes npm test's status" \
  || bad "a backslash at the end of a comment does not join the next line to it: the runner there is a check, and a --silent after a commented-out flag takes npm test's status" "$_rvo"

# A value may hold a $( ) or a backquoted command, blanks and all, and still
# end where its word does: the runner after PYTHONPATH=$(pwd) or after a
# backquoted git rev-parse is run, and one after a double-quoted value that
# holds a $( ) too. Assigning a path built from one is still not running it.
_rv_one r4/assign r4-as1 'PYTHONPATH=$(pwd) pytest -q'
_rv_one r4/assign r4-as2 'cd /w && PYTHONPATH=$(pwd)/src python3 -m pytest tests -q'
_rv_one r4/assign r4-as3 'ROOT=$(git rev-parse --show-toplevel) npm test'
_rv_one r4/assign r4-as4 'ROOT=`git rev-parse --show-toplevel` npm test'
_rv_one r4/assign r4-as5 'PYTHONPATH=\"$(pwd)/src\" pytest -q'
_rv_one r4/assign r4-as6 'G=$(pwd)/tests/run\nls \"$G\"'
is  "a VAR=\$( ) or a backquoted value before a runner is an assignment, so the runner is a check; assigning a path built from one is not" \
    "$(_au_counts "$(_au --dir "$RV/r4/assign")")" "5 0 0 1"

# A redirect hands the status on, on a group as on a command: bash returns a
# { } or ( ) group's status wherever its output goes. So a check that ends a
# group sent to a log could have failed and been seen, and only the one that
# another command in the group follows could not.
_rv_one r4/grp r4-gr1 '{ npm test; } > /tmp/log 2>&1'
_rv_one r4/grp r4-gr2 '{ ./tests/run; } 2>&1'
_rv_one r4/grp r4-gr3 '(npm test) > /tmp/log'
_rv_one r4/grp r4-gr4 'npm test > /tmp/log 2>&1'
_rv_one r4/grp r4-gr5 '{ npm test; echo done; } > /tmp/log'
_rvo="$(_au --dir "$RV/r4/grp")"
[ "$(_au_counts "$_rvo")" = "5 0 0 0" ] && _au_nums "$_rvo" 'pipe|background' 1 \
  && ok  "a check that ends a { } or ( ) group whose output is redirected could have been seen to fail; only the one another command in the group follows is counted as could not" \
  || bad "a check that ends a { } or ( ) group whose output is redirected could have been seen to fail; only the one another command in the group follows is counted as could not" "$_rvo"

# A $( ) in a double-quoted span that stands where a command does runs what
# it holds, and a path built on one, quoted or not, is the program: so
# "$(npm test)" runs npm test, and "$(pwd)/scripts/gate.sh" and a gate under
# $(git rev-parse --show-toplevel) are the gate. A path so built to a script
# that runs no tests is no check.
_rv_one r4/subpath r4-sp1 '\"$(npm test)\"'
_rv_one r4/subpath r4-sp2 '\"$(pwd)/scripts/gate.sh\"'
_rv_one r4/subpath r4-sp3 '$(git rev-parse --show-toplevel)/tests/run'
_rv_one r4/subpath r4-sp4 '\"$(pwd)/scripts/build.sh\" --fast'
is  "a \$( ) standing as the command, quoted, runs what it holds, and a path built on one is the program: 3 checks beside a built path that runs no tests" \
    "$(_au_counts "$(_au --dir "$RV/r4/subpath")")" "3 0 0 1"

# The script a shell is handed in double quotes is what those quotes hold
# with their escapes taken off, as the shell hands it on: an escaped quote
# in it is a quote, so a program path quoted inside it is the program, and
# text quoted inside it is still text.
_rv_one r4/dqc r4-dq1 'bash -c \"cd /w && \\\"$W/.venv/bin/python\\\" -m pytest\"'
_rv_one r4/dqc r4-dq2 'bash -c \"cd /w && \\\"$FELIX_HOME/harness/felix\\\" gate\"'
_rv_one r4/dqc r4-dq3 'sh -c \"echo \\\"npm test\\\"\"'
is  "a double-quoted -c script is read with its escapes taken off: a program path quoted inside it is the program, and text quoted inside it is text" \
    "$(_au_counts "$(_au --dir "$RV/r4/dqc")")" "2 0 0 1"

# A --verify that matches a backslash has decode() put each escaped one back
# with a split on \001, and BWK awk, which macOS ships, splits a string at
# every line break as well when its separator is one character. So every
# line break of a command holding an escaped backslash became a backslash,
# and its lines one: the runner on the line after echo a\b was no check, the
# sed -i on a line after npm test no write after it, and the line after a
# check did not take its status. Read under x\\z and under x_z, which match
# nothing here and differ only in the backslash, and counted the same. gawk
# and mawk never split there, so only a Mac shows this red.
_rv_one bwk/nlbs bwk-nb1 'echo a\\b\nnpm test'
_rv_one bwk/nlbs bwk-nb2 'npm test\necho a\\b\nsed -i s/a/b/ src/app.js'
_rv_one bwk/nlbs bwk-nb3 'npm test\necho a\\b'
_rvo="$(_au --dir "$RV/bwk/nlbs" --verify 'x_z')"; _rvo2="$(_au --dir "$RV/bwk/nlbs" --verify 'x\\z')"
_rvn="a multi-line command holding an escaped backslash reads the same under a --verify that matches a backslash as under one that does not: its line breaks stay line breaks"
[ "$(_au_counts "$_rvo")" = "2 0 1 0" ] && _au_nums "$_rvo" 'pipe|background' 1 \
  && [ "$(_au_counts "$_rvo2")" = "2 0 1 0" ] && _au_nums "$_rvo2" 'pipe|background' 1 \
  && ok  "$_rvn" \
  || bad "$_rvn" "x_z: $(_au_counts "$_rvo"), x\\\\z: $(_au_counts "$_rvo2"); passed, failed, stale, never, where each should read 2 0 1 0 with one check whose status a later line took"

printf '\nfelix new: what the reviews left open\n'
# A marker that cannot be written is said and exits non-zero. The same
# command, once the checkout is writable, then binds it, rather than refusing
# as already there a project it made half way.
_nc_repo r-ro; chmod 555 "$NC/r-ro"
_rvn="felix new --no-commission that could not write its marker binds the checkout when run again, once it is writable"
if ( : > "$NC/r-ro/.probe" ) 2>/dev/null; then
  rm -f "$NC/r-ro/.probe"; chmod 755 "$NC/r-ro"
  skip "$_rvn" "running as a user who writes a mode-555 directory"
else
  _ncr="$(_nc "$NC/r-ro" ncro --no-commission)"; _ncrrc=$?
  chmod 755 "$NC/r-ro"
  _ncr2="$(_nc "$NC/r-ro" ncro --no-commission)"; _ncr2rc=$?
  [ "$_ncrrc" -ne 0 ] && [ "$_ncr2rc" -eq 0 ] && _nc_bound r-ro ncro && ok "$_rvn" \
    || bad "$_rvn" "unwritable: rc=$_ncrrc; again: rc=$_ncr2rc $_ncr2"
fi

# The read-only checks again, after the last run of this engine. The first
# section's snapshot was taken before the reviews' runs, so a write or a call
# made only on one of their paths passed it. Everything under the scratch root
# but the fixtures in rv/, which those runs read and this cannot tell from
# their making; the scratch HOME; and the stub log, which nothing has cleared
# since the first run. A write to a fixed absolute path outside the scratch
# root is seen by none of these.
_rv_norv() { printf '%s\n' "$1" | awk '$0 !~ /^\.\/rv(\/|$)/ && $0 !~ / \.\/rv\//'; }
_rvn="after the last audit run as after the first: nothing changed under the scratch root outside the review fixtures, nothing in the scratch HOME, and no claude, gh, curl or wget was called"
if [ "$_au_report" -eq 1 ]; then
  _rv_b="$(_rv_norv "$_au_before")"; _rv_e="$(_rv_norv "$(_au_snap "$AU")")"
  [ "$_rv_b" = "$_rv_e" ] && [ "$_au_home_before" = "$(_au_snap "$AU/home")" ] && [ ! -s "$AUSTUB_LOG" ] \
    && ok  "$_rvn" \
    || bad "$_rvn" "$(diff <(printf '%s\n' "$_rv_b") <(printf '%s\n' "$_rv_e") | head -10); home: $(ls -A "$AU/home"); stub log: $(head -3 "$AUSTUB_LOG")"
else
  bad "$_rvn" "no report was produced, so an untouched tree proves nothing"
fi

# The read-only checks at the top of this section, shown able to fail for the
# reason they name: the same snapshot and the same stub log, around a copy of
# the engine whose audit writes one file under HOME and calls claude. Their
# red run only ever showed them failing because the base had no audit at all.
RVM="$TMP/audit-mutant"; mkdir -p "$RVM/home" "$RVM/cwd"; RVM="$(cd "$RVM" && pwd -P)"
cp -R "$AU/clone/felix/engine/harness" "$RVM/harness"
awk '{ print } /^felix_audit\(\) \{$/ { print "  : > \"$HOME/.felix-home\"; claude --version >/dev/null 2>&1" }' \
  "$AU/clone/felix/engine/harness/lib/audit.sh" > "$RVM/audit.sh"
cp "$RVM/audit.sh" "$RVM/harness/lib/audit.sh"
_rvb="$(_au_snap "$RVM/home")"; : > "$AUSTUB_LOG"
( cd "$RVM/cwd" && HOME="$RVM/home" CLAUDE_CONFIG_DIR="$AU/cfg" TMPDIR="$AU/tmp" PATH="$AUSTUB:$PATH" \
    "$RVM/harness/felix" audit --dir "$AUD" ) >/dev/null 2>&1
if [ "$_rvb" != "$(_au_snap "$RVM/home")" ] && grep -q '^claude ' "$AUSTUB_LOG"; then
  ok  "the read-only checks can fail: an audit that writes under HOME and calls claude changes the snapshot and the stub log"
else
  bad "the read-only checks can fail: an audit that writes under HOME and calls claude changes the snapshot and the stub log" \
      "home: $(ls -A "$RVM/home"); stub log: $(head -3 "$AUSTUB_LOG")"
fi
: > "$AUSTUB_LOG"

# And the runs above are wired to those checks: the same writing, calling
# engine, run through _au itself, lands in the HOME it was given and in the
# stub log. The check above proves the detector; this proves the wrapper every
# run used feeds it. A _au that lost the stubs from PATH would otherwise leave
# every read-only check green while the real claude answered.
mkdir -p "$RVM/home2"; : > "$AUSTUB_LOG"
_au --engine "$RVM/harness/felix" --home "$RVM/home2" --dir "$AUD" >/dev/null
[ -e "$RVM/home2/.felix-home" ] && grep -q '^claude ' "$AUSTUB_LOG" \
  && ok  "the audit runs above are wired to the read-only checks: an engine that writes under HOME and calls claude, run through the same wrapper, shows in that HOME and in the stub log" \
  || bad "the audit runs above are wired to the read-only checks: an engine that writes under HOME and calls claude, run through the same wrapper, shows in that HOME and in the stub log" \
         "home: $(ls -A "$RVM/home2"); stub log: $(head -3 "$AUSTUB_LOG")"
: > "$AUSTUB_LOG"

# ------------------------------------------------------ felix inventory ----
# Where unlanded work is, derived rather than registered: a session that dies
# registers nothing, so felix inventory reads disk, git, gh and the host's
# session records, and writes nothing anywhere. Written blind, from the spec
# alone (audits/2026-09-24-lost-work-sweep/inventory-spec.md), while the
# command was being written by someone else, so each assertion names the
# contract and none reads a wording.
#
# Rows are read from --tsv (kind repo ref states owner age_h content detail). A row is
# found by the name the fixture gave its item: a worktree by its directory, a
# branch by its name, a pull request by its number, first in the ref column
# and else anywhere on the line. A state is a token of the states column, in
# the spec's vocabulary; a pull request's words are whole words of its detail.
# Every check needs the row to exist, so an item left out never passes as an
# item without the state. Placed after the audit section, whose transcript
# helpers (_au_open and the rest) it uses.

