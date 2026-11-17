# ------------------------------------------------- red, the recorded red run ---
# tests/red runs the calling tree's assertions against the engine a base commit
# holds and writes down which of them fail, so a red assertion is a claim on
# file rather than a surprise on CI. Written blind from the contract, against a
# fixture repository rather than this checkout: its committed engine carries an
# old marker and a run that announces itself if anything executes it; its
# working tree moves the marker on, uncommitted, and brings a run that reads
# its lib relative to its own path the way the real suite does. Against the
# base's lib that run must go red on exactly the lib-derived assertions, and
# against the tree's it would not — which is the whole point of the script.
printf '\nred: the recorded red run\n'
RED="$TMP/red"; mkdir -p "$RED/tmpdir"
# The base's own run. It is never to be executed, and if it is, it leaves a
# name behind that red.tsv would have to carry.
_red_base_run() { cat <<'EOF'
#!/usr/bin/env bash
printf '  FAIL  the base run was executed\n'
printf '0 passed, 1 failed\n'
EOF
}
# The tree's run, suite-shaped: a header, a detail line under a failure that
# must not read as a name, one name that fails twice, one upper-case name to
# pin the C collation, a skip, and a totals line with or without a skipped
# clause. It reports a manifest-shaped failure only when the variable red must
# set is absent, so a red that forgot it shows one failure too many. It exits
# 1 on any failure, as a real suite would, which red must not mistake for a
# run that could not happen. And it prints the real suite's completion marker,
# an empty line and then a line that is exactly "reached", after its last
# assertion and before its totals, so each run built from it is of a suite
# that finished.
_red_tree_run() { cat <<'EOF'
#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"
P=0; F=0; S=0
printf 'marker suite\n\n'
if grep -q new "$HERE/../lib/marker.sh"; then printf '  ok    a marker exists\n'; P=$((P+1))
else printf '  FAIL  a marker exists\n        expected [new] got [old]\n'; F=$((F+1)); fi
for i in 1 2; do
  if grep -q new "$HERE/../lib/marker.sh"; then printf '  ok    Each pass sees the new marker\n'; P=$((P+1))
  else printf '  FAIL  Each pass sees the new marker\n'; F=$((F+1)); fi
done
printf '  ok    always fine\n'; P=$((P+1))
printf '  ok    a new assertion the tree added\n'; P=$((P+1))
[ -z "${FELIX_TEST_NO_MANIFEST:-}" ] && { printf '  FAIL  assertion did not run: x\n'; F=$((F+1)); }
printf '  skip  needs claude (no cli)\n'; S=$((S+1)) # SKIPLINE
printf '\nreached\n'
if [ "$S" -gt 0 ]; then printf '%d passed, %d failed, %d skipped\n' "$P" "$F" "$S"
else printf '%d passed, %d failed\n' "$P" "$F"; fi
[ "$F" -eq 0 ]
EOF
}
# dir branch version: a repository whose one commit holds the old marker, the
# base's run, the red under test, and a red.tsv making a claim that is stale.
_red_seed() {
  mkdir -p "$1/engine/.claude-plugin" "$1/engine/harness/lib" "$1/engine/harness/tests"
  printf '{\n  "name": "felix",\n  "description": "fixture",\n  "version": "%s"\n}\n' "$3" > "$1/engine/.claude-plugin/plugin.json"
  printf 'marker=old\n' > "$1/engine/harness/lib/marker.sh"
  _red_base_run > "$1/engine/harness/tests/run"; chmod +x "$1/engine/harness/tests/run"
  cp "$FROOT/harness/tests/red" "$1/engine/harness/tests/red"
  printf '# stale\nbase\tmain\tdeadbeef\t0.0.0\nrun\t1\t0\t0\nstale claim\t9\n' > "$1/engine/harness/tests/red.tsv"
  ( _fx_cd "$1" && git init -q -b "$2" && git add -A && git -c user.name=t -c user.email=t@t commit -qm seed ) >/dev/null 2>&1
}
# names on stdin -> manifest rows, as tests/run --record-assertions writes
# them, through the same helper: how many times each name was given, a tab,
# the name, in c order.
_red_rows() { _ran_rows; }
# dir name...: the fixture's manifest, in its working tree beside its tests/red,
# which is where tests/red reads it, before the suite runs.
_red_man() { local d="$1"; shift; printf '%s\n' "$@" | _red_rows > "$d/engine/harness/tests/assertions.tsv"; }
# dir [skips]: the working tree moves on without a commit — a new marker, the
# tree's run, a version the base does not declare, and the manifest that run
# records against the new marker, the skip among its names when it prints one.
_red_dirty() {
  printf 'marker=new\n' > "$1/engine/harness/lib/marker.sh"
  if [ "${2:-}" = skips ]; then _red_tree_run; else _red_tree_run | grep -v SKIPLINE; fi > "$1/engine/harness/tests/run"
  printf '{\n  "name": "felix",\n  "description": "fixture",\n  "version": "9.9.9"\n}\n' > "$1/engine/.claude-plugin/plugin.json"
  if [ "${2:-}" = skips ]; then
    _red_man "$1" "a marker exists" "Each pass sees the new marker" "Each pass sees the new marker" "always fine" \
      "a new assertion the tree added" "needs claude"
  else
    _red_man "$1" "a marker exists" "Each pass sees the new marker" "Each pass sees the new marker" "always fine" \
      "a new assertion the tree added"
  fi
}
# dir cmd...: stdout to $RED/out, exit status to $RED/rc. The manifest variable
# is unset on the way in, because the suite running this block may carry it,
# and the run under test must set it itself. TMPDIR is a directory of this
# block's own, so what red leaves behind can be counted.
_red()      { ( cd "$1" && shift && env -u FELIX_TEST_NO_MANIFEST TMPDIR="$RED/tmpdir" "$@" >"$RED/out" 2>"$RED/err"; echo $? >"$RED/rc" ); }
_red_rc()   { cat "$RED/rc"; }
_red_sum()  { grep '^red: ' "$RED/out" | head -1 | sed 's/ ([0-9a-f]*) / (SHA) /'; }
_red_sha()  { grep '^red: ' "$RED/out" | head -1 | sed -n 's/.* (\([0-9a-f]*\)) at engine.*/\1/p'; }
_red_body() { grep -v '^#' "$1/engine/harness/tests/red.tsv" 2>/dev/null; }
_red_stat() { ( cd "$1" && git status --porcelain | grep -v 'red\.tsv' ); }
# full short: yes when short is a non-empty prefix of full at least 7 long.
_red_abbr() { case "$1" in "$2"*) [ "${#2}" -ge 7 ] && echo yes ;; esac; }
# dir: the working tree's run becomes a script whose body is read from stdin.
# The base, the stale claim and the red under test are still the ones
# _red_seed committed.
_red_cut() { { printf '#!/usr/bin/env bash\n'; cat; } > "$1/engine/harness/tests/run"; chmod +x "$1/engine/harness/tests/run"; }
# stdout whole: how many lines it holds, a bar, then what they say, so a
# trailing line that $(cat) would strip is still counted.
_red_said() { printf '%s|%s' "$(awk 'END{print NR}' "$RED/out")" "$(cat "$RED/out")"; }
# The manifest red compares names against is written by _ran_rows, and red
# compares them with the lines the suite printed, byte for byte. A writer that
# folded a name's blanks, as the one before 2026-10-01 did, would make red read
# that name as never reached on every run, so the writer is asked directly, and
# the suite's own last step is asked whether it writes through it.
is  "the manifest writer keeps each name as the suite printed it, blanks inside and at either end, so red never reads one as unreached" \
    "$(printf '%s\n' 'a  b' ' lead' 'trail ' 'a  b' | _ran_rows)" "$(printf '1\t lead\n2\ta  b\n1\ttrail ')"
is  "and the suite writes the manifest it compares and records through that writer" \
    "$(grep -c '^_ran_rows < "\$FELIX_TEST_RAN" > "\$_ran_counts"$' "$HERE/run")" "1"
# The suite's last step compares that manifest with what ran. It was a loop of
# one awk per manifest row, 88 s of the gate on 2026-10-09; it is one pass over
# both files now, and these ask it what the loop answered. The loop's answers
# on every case below were read off it before it was replaced, bar three it got
# wrong and the pass does not: a tab inside a name reached by the run, which
# the loop reported unreached, a last row with no newline, which it dropped, and
# a name that is a number written another way, "1e0" for "1", which it took to
# be reached because awk compared the two as numbers.
_ms="$TMP/ms"; mkdir -p "$_ms"
printf '1\talpha\n3\tbeta\n1\tgamma\n2\ta\\back [x] star.*\n1\tread a.b\n1\ta name\twith a tab\n1\t1e0' > "$_ms/want"
printf '1\talpha\n2\tbeta\n2\ta\\back [x] star.*\n1\tread aXb\n1\ta name\twith a tab\n5\textra name\n1\t1\n' > "$_ms/got"
is  "a name the run reached fewer times than the manifest lists is said with both counts, in the manifest's order, and one reached more often, or listed nowhere, is not" \
    "$(_manifest_short "$_ms/want" "$_ms/got")" "$(printf '3\t2\tbeta\n1\t0\tgamma\n1\t0\tread a.b\n1\t0\t1e0')"
: > "$_ms/none"
is  "and with nothing reached, every name listed is said once, a row with no name or a count that is no number listing none" \
    "$(printf '1\tone\n\n1\n\tno count\nx\tnot a number\n2\ttwo\n' > "$_ms/odd"; _manifest_short "$_ms/odd" "$_ms/none" | tr '\t' '|')" "1|0|one
2|0|two"
is  "and the suite's last step asks it, rather than running an awk for each name the manifest lists" \
    "$(grep -c '^  done < <(_manifest_short "\$FELIX_TEST_MANIFEST" "\$_ran_counts")$' "$HERE/run")" "1"
# Timed as CPU, children's user and system both: the loop's time was forks. At
# 7,000 names it ran for over a minute, so 5 s stays far from both.
awk 'BEGIN { for (i = 1; i <= 7000; i++) printf "1\tassertion number %d, and a few words more\n", i }' > "$_ms/big.want"
head -6997 "$_ms/big.want" > "$_ms/big.got"
_msn="$(_manifest_short "$_ms/big.want" "$_ms/big.got"; times > "$_ms/big.cpu")"
_msc="$(awk '{ for (i = 1; i <= NF; i++) { split($i, t, "m"); sub(/s$/, "", t[2]); ms += (t[1] * 60 + t[2]) * 1000 } } END { printf "%d", ms }' "$_ms/big.cpu")"
_msv="the manifest of 7,000 names is read against a run that missed three in under 5 seconds of CPU"
if [ "$(printf '%s\n' "$_msn" | grep -c .)" = "3" ]; then
  [ "$_msc" -le 5000 ] && ok "$_msv" || bad "$_msv" "took ${_msc} ms of CPU"
else
  bad "$_msv" "it did not say the three, so its speed says nothing"
fi
if [ -x "$FROOT/harness/tests/red" ]; then
  _red_seed "$RED/repo" main 0.0.7; _red_dirty "$RED/repo" skips
  RSHA="$(cd "$RED/repo" && git rev-parse main)"
  before="$(_red_stat "$RED/repo")"
  _red "$RED/repo" engine/harness/tests/red
  is  "a red run against main exits 0 once the suite has run" "$(_red_rc)" "0"
  is  "and stdout is the one summary line" "$(awk 'END{print NR}' "$RED/out")" "1"
  is  "and the summary counts three of six assertions failing against main at the engine version main declares" \
      "$(_red_sum)" "red: 3 of 6 assertions fail against main (SHA) at engine 0.0.7"
  is  "and the sha it parenthesises abbreviates main's commit" "$(_red_abbr "$RSHA" "$(_red_sha)")" "yes"
  is  "the base row names main, its full sha and the version at that commit, not the tree's" \
      "$(_red_body "$RED/repo" | sed -n 1p)" "$(printf 'base\tmain\t%s\t0.0.7' "$RSHA")"
  is  "the run row counts three failed, two passed, one skipped" "$(_red_body "$RED/repo" | sed -n 2p)" "$(printf 'run\t3\t2\t1')"
  is  "the failed names follow in c order, once each, with the times they failed" \
      "$(_red_body "$RED/repo" | sed -n '3,$p')" "$(printf 'Each pass sees the new marker\t2\na marker exists\t1')"
  is  "the tree's run executed against main's lib, never the base's own run" \
      "$(grep -c 'the base run was executed' "$RED/repo/engine/harness/tests/red.tsv")" "0"
  is  "the manifest variable reached the run" "$(grep -c 'assertion did not run' "$RED/repo/engine/harness/tests/red.tsv")" "0"
  is  "a stale red.tsv is overwritten, not appended to" "$(grep -c 'stale claim' "$RED/repo/engine/harness/tests/red.tsv")" "0"
  is  "nothing in the tree but red.tsv changed" "$(_red_stat "$RED/repo")" "$before"
  is  "and no temporary directory is left under the tmpdir it was given" "$(ls -A "$RED/tmpdir" | wc -l | tr -d ' ')" "0"
  # A second repository with no main and no origin: standing inside it while
  # calling the first's red by absolute path, a red that read $PWD would find
  # no base and retract; and red.tsv is removed first so a stale row cannot
  # answer for a run that wrote elsewhere.
  _red_seed "$RED/trunk" trunk 0.0.9; _red_dirty "$RED/trunk"
  rm -f "$RED/repo/engine/harness/tests/red.tsv"
  _red "$RED/trunk" "$RED/repo/engine/harness/tests/red"
  is  "invoked from inside another repository it still reads its own" \
      "$(_red_body "$RED/repo" | sed -n 1p)" "$(printf 'base\tmain\t%s\t0.0.7' "$RSHA")"
  _red "$RED/repo/engine/harness/lib" ../tests/red
  is  "invoked by a relative path from a subdirectory it still finds its root" \
      "$(_red_sum)" "red: 3 of 6 assertions fail against main (SHA) at engine 0.0.7"
  # The trunk repository: an explicit ref works where the defaults would not,
  # its run prints no skipped clause, and then the defaults are tried.
  _red "$RED/trunk" engine/harness/tests/red trunk
  is  "an explicit base argument names the ref to run against" "$(_red_sum)" "red: 3 of 5 assertions fail against trunk (SHA) at engine 0.0.9"
  is  "and a totals line without a skipped clause records skipped as 0" "$(_red_body "$RED/trunk" | sed -n 2p)" "$(printf 'run\t3\t2\t0')"
  _red "$RED/trunk" engine/harness/tests/red
  is  "with neither origin/main nor main to fall back on the red run cannot run, exit 2" "$(_red_rc)" "2"
  has "and says so on stdout" "$(cat "$RED/out")" "red: not run: "
  is  "and red.tsv retracts the earlier claim rather than keeping it" "$(_red_body "$RED/trunk")" "$(printf 'base\t-\t-\t-\nrun\t-\t-\t-')"
  # No run beside red: main resolves, so the only thing missing is the suite.
  _red_seed "$RED/norun" main 0.0.7; rm -f "$RED/norun/engine/harness/tests/run"
  _red "$RED/norun" engine/harness/tests/red
  is  "with no run beside it the red run cannot run, exit 2" "$(_red_rc)" "2"
  is  "and the file then states that no red run was possible" "$(_red_body "$RED/norun")" "$(printf 'base\t-\t-\t-\nrun\t-\t-\t-')"
  # It has no manifest either, and the run is asked for first.
  is  "with neither a run nor a manifest beside it, the missing run is the reason it gives" \
      "$(cat "$RED/out")" "red: not run: no tests/run beside $(cd "$RED/norun/engine/harness/tests" && pwd)/red"
  # A clone of the first repository, so origin/main exists, then a commit on
  # its main that moves the marker and the version: the two refs now disagree,
  # and only one of them makes the tree's run pass.
  git clone -q "$RED/repo" "$RED/clone" >/dev/null 2>&1
  printf '{\n  "name": "felix",\n  "description": "fixture",\n  "version": "0.0.8"\n}\n' > "$RED/clone/engine/.claude-plugin/plugin.json"
  printf 'marker=new\n' > "$RED/clone/engine/harness/lib/marker.sh"
  ( _fx_cd "$RED/clone" && git -c user.name=t -c user.email=t@t commit -qam bump ) >/dev/null 2>&1
  CSHA="$(cd "$RED/clone" && git rev-parse main)"
  _red_dirty "$RED/clone" skips
  _red "$RED/clone" engine/harness/tests/red
  is  "with both refs present origin/main is the default base" \
      "$(_red_body "$RED/clone" | sed -n 1p)" "$(printf 'base\torigin/main\t%s\t0.0.7' "$RSHA")"
  _red "$RED/clone" engine/harness/tests/red main
  is  "naming main explicitly runs against the local branch, whose lib the tree's run passes" \
      "$(_red_body "$RED/clone")" "$(printf 'base\tmain\t%s\t0.0.8\nrun\t0\t5\t1' "$CSHA")"
  is  "and zero failures is still exit 0" "$(_red_rc)" "0"
  is  "and the summary then counts zero of six" "$(_red_sum)" "red: 0 of 6 assertions fail against main (SHA) at engine 0.0.8"
  # A suite that stops before its end is not a red run, whatever it printed
  # first. On 2026-09-25 a suite stopped at assertion 270 was written down as
  # 0 of 270 failing, and an earlier one, very likely cut off by a fork
  # failure, as 0 of 1320, when the whole suite holds some 3,700. What tells a
  # finished suite from a dead one is the line it prints after its last
  # assertion, exactly "reached", and not its exit status, since a finished
  # red run exits 1. Each run here is in a fresh repository whose red.tsv
  # starts with a stale claim. Red must refuse one that stops short of that
  # line, retract the claim and clean up; the empty, late and strayend runs
  # reach the line on purpose. Each is given a well-formed manifest, since red
  # reads one before the suite runs and refuses to start without it.
  _red_seed "$RED/dead" main 0.0.7
  _red_cut "$RED/dead" <<'EOF'
printf 'marker suite\n\n'
for i in 1 2 3 4; do printf '  ok    assertion %s before the kill\n' "$i"; done
kill -9 $$
printf '\nreached\n\n4 passed, 0 failed\n'
EOF
  _red_man "$RED/dead" "assertion 1 before the kill" "assertion 2 before the kill" \
    "assertion 3 before the kill" "assertion 4 before the kill"
  RLEFT="$(ls -A "$RED/tmpdir" | wc -l | tr -d ' ')"
  _red "$RED/dead" engine/harness/tests/red
  is  "a suite killed before it printed reached is not a red run, exit 2" "$(_red_rc)" "2"
  is  "and stdout is the one line naming main, the kill's exit 137 and the four assertions it reached" \
      "$(_red_said)" "1|red: not run: the suite against main did not finish (exit 137 after 4 assertions)"
  is  "and red.tsv holds only the two rows saying no red run was made, the stale claim retracted" \
      "$(_red_body "$RED/dead")" "$(printf 'base\t-\t-\t-\nrun\t-\t-\t-')"
  is  "and that exit 2 leaves no temporary directory behind either" \
      "$(_red_rc) $(ls -A "$RED/tmpdir" | wc -l | tr -d ' ')" "2 $RLEFT"
  # One that exits 0 early has not finished either, though it printed a totals
  # line, and the skip it printed counts among the assertions it reached.
  _red_seed "$RED/early" main 0.0.7
  _red_cut "$RED/early" <<'EOF'
printf 'marker suite\n\n  ok    one\n  ok    two\n  skip  three (no cli)\n\n2 passed, 0 failed, 1 skipped\n'
exit 0
EOF
  _red_man "$RED/early" one two three
  _red "$RED/early" engine/harness/tests/red
  is  "a suite that exits 0 with a totals line but no reached line is refused too, exit 2" "$(_red_rc)" "2"
  is  "and its reason names exit 0 and the three assertions it printed, a skip among them" \
      "$(cat "$RED/out")" "red: not run: the suite against main did not finish (exit 0 after 3 assertions)"
  is  "and red.tsv again holds only the two rows saying no red run was made" \
      "$(_red_body "$RED/early")" "$(printf 'base\t-\t-\t-\nrun\t-\t-\t-')"
  # The marker is a whole line. An assertion whose name holds the word, as the
  # suite's own manifest line does, the word with anything around it, or the
  # word alone in another case, is not the marker. This one then ends on SIGTERM.
  _red_seed "$RED/word" main 0.0.7
  _red_cut "$RED/word" <<'EOF'
printf '  ok    every assertion in the manifest was reached\n  FAIL  the end is reached\n'
printf 'reached: 2 of 3\n  reached\nreached \nunreached\nReached\nREACHED\n'
kill -TERM $$
EOF
  _red_man "$RED/word" "every assertion in the manifest was reached" "the end is reached"
  _red "$RED/word" engine/harness/tests/red
  is  "a line that only contains the word reached is not the marker, exit 2" "$(_red_rc)" "2"
  is  "and a suite ended by sigterm is reported as exit 143 after its two assertions" \
      "$(cat "$RED/out")" "red: not run: the suite against main did not finish (exit 143 after 2 assertions)"
  is  "and red.tsv holds the two rows saying no red run was made for it as well" \
      "$(_red_body "$RED/word")" "$(printf 'base\t-\t-\t-\nrun\t-\t-\t-')"
  # Killed before its first assertion, a suite is refused as unfinished: the
  # marker is asked for before the count, so the older refusal of a run that
  # reached no assertion does not answer for a suite that died.
  _red_seed "$RED/cold" main 0.0.7
  _red_cut "$RED/cold" <<'EOF'
printf 'marker suite\n\n'
kill -9 $$
EOF
  _red_man "$RED/cold" "the first assertion, which the kill comes before"
  _red "$RED/cold" engine/harness/tests/red
  is  "a suite killed before its first assertion is refused as unfinished, not as empty" \
      "$(cat "$RED/out")" "red: not run: the suite against main did not finish (exit 137 after 0 assertions)"
  # And that older refusal still stands behind the new one: a suite that
  # prints the marker having run no assertion is no red run either.
  _red_seed "$RED/empty" main 0.0.7
  _red_cut "$RED/empty" <<'EOF'
printf 'marker suite\n\nreached\n\n0 passed, 0 failed\n'
EOF
  _red_man "$RED/empty" "an assertion it never runs"
  _red "$RED/empty" engine/harness/tests/red
  is  "a suite that prints reached having run no assertion is still refused, exit 2" "$(_red_rc)" "2"
  is  "and it is refused as empty, not as unfinished" \
      "$(grep -c '^red: not run: ' "$RED/out") $(grep -c 'did not finish' "$RED/out")" "1 0"
  # A suite that stops with exit 1 before reached ends as a finished red run
  # does, failures behind it and a totals line after them, so only the missing
  # line tells the two apart.
  _red_seed "$RED/one" main 0.0.7
  _red_cut "$RED/one" <<'EOF'
printf 'marker suite\n\n  ok    one\n  FAIL  two\n        expected [a] got [b]\n  ok    three\n\n2 passed, 1 failed\n'
exit 1
EOF
  _red_man "$RED/one" one two three
  _red "$RED/one" engine/harness/tests/red
  is  "a suite that exits 1 without reached, as a finished red run exits, is refused, exit 2" "$(_red_rc)" "2"
  is  "and its reason names exit 1 and the three assertions it printed, the failure among them, on one line" \
      "$(_red_said)" "1|red: not run: the suite against main did not finish (exit 1 after 3 assertions)"
  is  "and red.tsv holds the two rows saying no red run was made, not the failure it printed" \
      "$(_red_body "$RED/one")" "$(printf 'base\t-\t-\t-\nrun\t-\t-\t-')"
  # The other way round: a suite killed after it printed reached, in its
  # manifest step or its totals, did reach its end, and its record stands
  # whatever the exit status says.
  _red_seed "$RED/late" main 0.0.7
  _red_cut "$RED/late" <<'EOF'
printf 'marker suite\n\n  ok    one\n  FAIL  two\n  skip  three (no cli)\n\nreached\n'
kill -9 $$
EOF
  _red_man "$RED/late" one two three
  LSHA="$(cd "$RED/late" && git rev-parse main)"
  _red "$RED/late" engine/harness/tests/red
  is  "a suite killed after it printed reached is still a red run, exit 0" "$(_red_rc)" "0"
  is  "and its record counts one failed, one passed and one skipped, the failed name below" \
      "$(_red_body "$RED/late")" "$(printf 'base\tmain\t%s\t0.0.7\nrun\t1\t1\t1\ntwo\t1' "$LSHA")"
  # Reached is the end only when no assertion follows it. A child that wrote
  # the word to stderr early, which the log shares with stdout, and a suite
  # that printed it and then went on, are both refused when they die.
  _red_seed "$RED/stray" main 0.0.7
  _red_cut "$RED/stray" <<'EOF'
printf 'marker suite\n\n'
sh -c 'echo reached >&2'
printf '  ok    one\n  ok    two\n  FAIL  three\n'
kill -9 $$
EOF
  _red_man "$RED/stray" one two three
  _red "$RED/stray" engine/harness/tests/red
  is  "a reached line a child wrote to stderr early does not make a suite killed after it a red run, exit 2" "$(_red_rc)" "2"
  is  "and its reason counts the three assertions printed after that stray line" \
      "$(_red_said)" "1|red: not run: the suite against main did not finish (exit 137 after 3 assertions)"
  is  "and red.tsv holds the two rows saying no red run was made, the stray reached notwithstanding" \
      "$(_red_body "$RED/stray")" "$(printf 'base\t-\t-\t-\nrun\t-\t-\t-')"
  _red_seed "$RED/past" main 0.0.7
  _red_cut "$RED/past" <<'EOF'
printf 'marker suite\n\n  ok    one\n\nreached\n  FAIL  two\n'
kill -9 $$
EOF
  _red_man "$RED/past" one two
  _red "$RED/past" engine/harness/tests/red
  is  "a suite that printed an assertion after reached and was killed is refused, exit 2" "$(_red_rc)" "2"
  is  "and its reason counts both assertions, the one after reached among them" \
      "$(_red_said)" "1|red: not run: the suite against main did not finish (exit 137 after 2 assertions)"
  is  "and red.tsv holds the two rows saying no red run was made for the suite that went on past reached" \
      "$(_red_body "$RED/past")" "$(printf 'base\t-\t-\t-\nrun\t-\t-\t-')"
  # A stray reached is outrun by any assertion line after it, an ok or a skip
  # as much as a failure, so a word a child wrote early that only passes or
  # only skips follow is still not the suite's end. And the reached that
  # counts is the last one, not the first: a suite with a stray one early that
  # prints the real one after its last assertion did finish, and is recorded.
  _red_seed "$RED/strayok" main 0.0.7
  _red_cut "$RED/strayok" <<'EOF'
printf 'marker suite\n\n'
sh -c 'echo reached >&2'
printf '  ok    one\n  ok    two\n  ok    three\n'
kill -9 $$
EOF
  _red_man "$RED/strayok" one two three
  _red "$RED/strayok" engine/harness/tests/red
  is  "a stray reached followed only by ok lines does not make a suite killed after them a red run, exit 2" "$(_red_rc)" "2"
  is  "and red.tsv holds the two rows saying no red run was made, the ok lines after the stray reached notwithstanding" \
      "$(_red_body "$RED/strayok")" "$(printf 'base\t-\t-\t-\nrun\t-\t-\t-')"
  _red_seed "$RED/strayskip" main 0.0.7
  _red_cut "$RED/strayskip" <<'EOF'
printf 'marker suite\n\n'
sh -c 'echo reached >&2'
printf '  skip  one (no cli)\n  skip  two (no cli)\n'
kill -9 $$
EOF
  _red_man "$RED/strayskip" one two
  _red "$RED/strayskip" engine/harness/tests/red
  is  "a stray reached followed only by skip lines does not make a suite killed after them a red run, exit 2" "$(_red_rc)" "2"
  is  "and red.tsv holds the two rows saying no red run was made, the skip lines after the stray reached notwithstanding" \
      "$(_red_body "$RED/strayskip")" "$(printf 'base\t-\t-\t-\nrun\t-\t-\t-')"
  _red_seed "$RED/strayend" main 0.0.7
  _red_cut "$RED/strayend" <<'EOF'
printf 'marker suite\n\n'
sh -c 'echo reached >&2'
printf '  ok    one\n  FAIL  two\n        expected [a] got [b]\n  ok    three\n'
printf '\nreached\n'
printf '  manifest comparison off (FELIX_TEST_NO_MANIFEST): this is a red run\n\n2 passed, 1 failed\n'
exit 1
EOF
  _red_man "$RED/strayend" one two three
  ESHA="$(cd "$RED/strayend" && git rev-parse main)"
  _red "$RED/strayend" engine/harness/tests/red
  is  "a suite with a stray reached early and the real one after its last assertion is a red run, exit 0" "$(_red_rc)" "0"
  is  "and its record is the base row, one failed and two passed, and the failed name, the stray reached notwithstanding" \
      "$(_red_body "$RED/strayend")" "$(printf 'base\tmain\t%s\t0.0.7\nrun\t1\t2\t0\ntwo\t1' "$ESHA")"
  # Reached proves the suite's main shell got to its end, not that every
  # assertion in it ran. In bash, 3.2 as 5, an arithmetic error inside $(( ))
  # prints to stderr and discards the rest of the top-level command it sits
  # in, and the script carries on, $? 1 right after and only the suite's own
  # final exit unaffected: at top level the whole line's list goes, `a; b`
  # both and `cond && ok || bad` both verdicts, and inside an if or a for
  # every statement left in that block, in every round the loop had left.
  # This suite's own `is ... "$((_cma_before - 1))"` reads a field the engine
  # under test wrote, and against a base that wrote - there it vanished,
  # reached was printed, and red wrote a run row of 0 failed for a fixture
  # whose one vanished assertion was red (2026-09-25, after #371). So red
  # reads the tree's manifest before the suite runs, and an assertion it lists
  # that the base run never reached is recorded red, by the times it fell
  # short. These fixtures commit a count of - beside the old marker, as an
  # engine writes - for a field it has no number for, read 5 and the new
  # marker in the working tree, and carry this file's own ok, bad, is and
  # skip, so a statement vanishes exactly as it does in the suite.
  _red_helpers() { awk '/^PASS=0; FAIL=0/ { on = 1 } on { print } on && /^skip\(\)/ { exit }' "$HERE/run"; }
  # dir: _red_seed, then a second commit on main holding lib/count.sh at -,
  # then the working tree's count of 5 and new marker, and a run whose body is
  # read from stdin, behind the suite's helpers and both libs.
  _red_count() {
    _red_seed "$1" main 0.0.7 </dev/null
    printf 'count=-\n' > "$1/engine/harness/lib/count.sh"
    ( _fx_cd "$1" && git add -A && git -c user.name=t -c user.email=t@t commit -qm count ) </dev/null >/dev/null 2>&1
    printf 'count=5\n' > "$1/engine/harness/lib/count.sh"; printf 'marker=new\n' > "$1/engine/harness/lib/marker.sh"
    { printf 'set -uo pipefail\n'; _red_helpers
      printf '%s\n' 'HERE="$(cd "$(dirname "$0")" && pwd)"' '. "$HERE/../lib/marker.sh"; . "$HERE/../lib/count.sh"'
      cat; } | _red_cut "$1"
  }
  # dir: what the fixture's run prints against its own working tree, its ok
  # and FAIL lines as manifest rows.
  _red_reach() { ( cd "$1" && bash engine/harness/tests/run 2>/dev/null ) | sed -n -e 's/^  ok    //p' -e 's/^  FAIL  //p' | _red_rows; }
  # dir: the run row's failed count, and what the names below it add up to.
  _red_whole() { awk -F'\t' '/^#/ || !NF { next } $1 == "base" { next } $1 == "run" { f = $2; next } { s += $NF }
                   END { printf "%s=%d", f, s }' "$1/engine/harness/tests/red.tsv"; }
  _red_count "$RED/arith" <<'EOF'
printf 'arithmetic suite\n\n'
ok "the arithmetic suite starts"
is "one less than the count the engine wrote is four" "$((count - 1))" "4"
ok "the arithmetic suite ends"
printf '\nreached\n\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
EOF
  _red_man "$RED/arith" "the arithmetic suite starts" "one less than the count the engine wrote is four" \
    "the arithmetic suite ends"
  ASHA="$(cd "$RED/arith" && git rev-parse main)"
  _red "$RED/arith" engine/harness/tests/red
  is  "an assertion whose arithmetic errors on the base's - and so never runs is recorded red, by the one time it never ran" \
      "$(_red_body "$RED/arith")" \
      "$(printf 'base\tmain\t%s\t0.0.7\nrun\t1\t2\t0\none less than the count the engine wrote is four\t1' "$ASHA")"
  is  "and its summary is one line, one of three failing against main, one of them never reached" \
      "$(awk 'END{print NR}' "$RED/out")|$(_red_sum)" \
      "1|red: 1 of 3 assertions fail against main (SHA) at engine 0.0.7, 1 of them never reached"
  is  "and a red run holding an assertion it never reached exits 0, recorded and not refused" "$(_red_rc)" "0"
  is  "and red.tsv's header says an assertion the manifest lists and the base run never reached counts as failed" \
      "$(grep -c -x -F '#   an assertion the manifest lists that the base run never reached counts as failed, by its shortfall' \
         "$RED/arith/engine/harness/tests/red.tsv")" "1"
  # Inside a for and an if the error takes the rest of the block: the round it
  # struck in and every round after it, and the if's statements below it. The
  # marker's assertion fails in the first round against the old marker, so one
  # name is both a failure the base printed and a time it never reached.
  _red_count "$RED/block" <<'EOF'
printf 'block suite\n\n'
ok "a block suite starts"
for i in 1 2; do
is "each round sees the new marker" "$marker" "new"
is "each round counts down from four" "$((count - 1))" "4"
ok "each round ends"
done
if [ -n "$count" ]; then
ok "the if block opens"
is "the if block counts down from four" "$((count - 1))" "4"
ok "the if block goes on after its arithmetic"
ok "and the if block closes"
fi
ok "a block suite ends"
printf '\nreached\n\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
EOF
  _red_man "$RED/block" "a block suite starts" "each round sees the new marker" "each round sees the new marker" \
    "each round counts down from four" "each round counts down from four" "each round ends" "each round ends" \
    "the if block opens" "the if block counts down from four" "the if block goes on after its arithmetic" \
    "and the if block closes" "a block suite ends"
  _red "$RED/block" engine/harness/tests/red
  is  "after an arithmetic error inside a for and an if, every assertion left in each block is recorded red, by the times the base never reached it" \
      "$(_red_body "$RED/block" | sed -n '3,$p')" \
      "$(printf 'and the if block closes\t1\neach round counts down from four\t2\neach round ends\t2\neach round sees the new marker\t2\nthe if block counts down from four\t1\nthe if block goes on after its arithmetic\t1')"
  is  "and the run row counts the one failure the base printed and the eight times it never reached as nine failed" \
      "$(_red_body "$RED/block" | sed -n 2p)" "$(printf 'run\t9\t3\t0')"
  is  "and the summary counts twelve, nine failing, eight of them never reached" \
      "$(_red_sum)" "red: 9 of 12 assertions fail against main (SHA) at engine 0.0.7, 8 of them never reached"
  # What the base run reached is counted per name against the manifest's
  # count. A name the base's marker gates is short by the times it was not
  # asked. A skip line is reached, and counts for the longest listed name it
  # begins with followed by a space and a parenthesis, whatever parentheses
  # the name and the reason hold. A name reached more often than listed, or
  # not listed at all, is not compared, and its failures count as before.
  _red_count "$RED/gate" <<'EOF'
printf 'gate suite\n\n'
ok "printed once, or twice where the marker is new"
[ "$marker" = new ] && ok "printed once, or twice where the marker is new"
is "fails where the marker is old, and is asked again only where it is new" "$marker" "new"
[ "$marker" = new ] && is "fails where the marker is old, and is asked again only where it is new" "$marker" "new"
ok "said three times, listed once"; ok "said three times, listed once"; ok "said three times, listed once"
ok "a pass the manifest does not list"
bad "a failure the manifest does not list"
skip "skipped alone" "no cli"
skip "skipped alone (in two parts" "needs (a) cli"
printf '\nreached\n\n%d passed, %d failed, %d skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
EOF
  _red_man "$RED/gate" "printed once, or twice where the marker is new" "printed once, or twice where the marker is new" \
    "fails where the marker is old, and is asked again only where it is new" \
    "fails where the marker is old, and is asked again only where it is new" \
    "said three times, listed once" "skipped alone" "skipped alone (in two parts"
  _red "$RED/gate" engine/harness/tests/red
  is  "a name the manifest lists twice that the base run reaches once is a row counting the one time it never reached it" \
      "$(_red_body "$RED/gate" | grep -c -x -F "$(printf 'printed once, or twice where the marker is new\t1')")" "1"
  is  "a name that fails once and is not asked its second time against the base is one row counting both" \
      "$(_red_body "$RED/gate" | grep -c -x -F "$(printf 'fails where the marker is old, and is asked again only where it is new\t2')")" "1"
  is  "a skip line counts as reached, a name holding a parenthesis and a reason holding its own among them, so no skipped name is red" \
      "$(_red_body "$RED/gate" | grep -c '^skipped alone')" "0"
  is  "a name reached more often than listed offsets no other name's shortfall, so the run row counts two never reached among four failed" \
      "$(_red_body "$RED/gate" | sed -n 2p)" "$(printf 'run\t4\t5\t2')"
  is  "names the manifest does not list are not compared, and the one that fails is still a failed row" \
      "$(_red_body "$RED/gate" | sed -n '3,$p')" \
      "$(printf 'a failure the manifest does not list\t1\nfails where the marker is old, and is asked again only where it is new\t2\nprinted once, or twice where the marker is new\t1')"
  is  "and that summary counts eleven, four failing, two of them never reached" \
      "$(_red_sum)" "red: 4 of 11 assertions fail against main (SHA) at engine 0.0.7, 2 of them never reached"
  # One skip line is one reach. A skip counted twice passed every fixture
  # above, and would read a name listed twice and skipped once against the
  # base as reached in full (#371's follow-up, its review).
  _red_count "$RED/skiptwice" <<'EOF'
printf 'skip twice suite\n\n'
ok "one assertion that passes"
skip "skipped once, listed twice" "no cli"
printf '\nreached\n\n%d passed, %d failed, %d skipped\n' "$PASS" "$FAIL" "$SKIP"
EOF
  _red_man "$RED/skiptwice" "one assertion that passes" "skipped once, listed twice" "skipped once, listed twice"
  _red "$RED/skiptwice" engine/harness/tests/red
  is  "a name listed twice that the base run skips once is red by the one time it never reached it, one skip line counting once" \
      "$(_red_body "$RED/skiptwice" | sed -n '2,$p')" "$(printf 'run\t1\t1\t1\nskipped once, listed twice\t1')"
  # Names are compared byte for byte: a backslash, brackets and a star are
  # themselves, a dot matches a dot and nothing else, and a tab after the
  # first in a manifest row belongs to the name.
  _red_count "$RED/bytes" <<'EOF'
printf 'bytes suite\n\n'
ok 'a back\slash, a [bracket] and a star.*'
ok "read a.b twice"
[ "$marker" = new ] && ok "read a.b twice"
ok "read aXb twice"
ok "$(printf 'a name\twith a tab after its first')"
printf '\nreached\n\n%d passed, %d failed\n' "$PASS" "$FAIL"
EOF
  _red_man "$RED/bytes" 'a back\slash, a [bracket] and a star.*' "read a.b twice" "read a.b twice" "read aXb twice" \
    "$(printf 'a name\twith a tab after its first')"
  _red "$RED/bytes" engine/harness/tests/red
  is  "manifest names are compared byte for byte, a backslash, brackets, a star, a dot and a tab each itself" \
      "$(_red_body "$RED/bytes" | sed -n '2,$p')" "$(printf 'run\t1\t4\t0\nread a.b twice\t1')"
  is  "the arithmetic, block and byte fixtures' runs reach, against their own working trees, every name their manifests list and as often" \
      "$(_red_reach "$RED/arith")|$(_red_reach "$RED/block")|$(_red_reach "$RED/bytes")" \
      "$(cat "$RED/arith/engine/harness/tests/assertions.tsv")|$(cat "$RED/block/engine/harness/tests/assertions.tsv")|$(cat "$RED/bytes/engine/harness/tests/assertions.tsv")"
  is  "each record with names never reached is one record, its run row's failed count what its names add up to" \
      "$(_red_whole "$RED/arith") $(_red_whole "$RED/block") $(_red_whole "$RED/gate") $(_red_whole "$RED/bytes")" "1=1 9=9 4=4 1=1"
  # Byte for byte means no near miss counts either. Each listed name below that
  # the base never reaches sits beside one it does reach: a strict prefix of
  # it, a part of its middle, the same letters in another case, the start of
  # a skip of a name the manifest does not list followed by a space and not
  # " (", and a line that opens like the name's skip and does not close. The
  # suite's own manifest held 48 pairs where one name begins another on
  # 2026-10-01, "and blocks" and "and blocks a release" among them. Counts go
  # past nine, so a count compared as a string, where 10 sorts below 9 and 2
  # above 10, would tell.
  _red_count "$RED/near" <<'EOF'
printf 'near suite\n\n'
ok "a short name and more after it"
ok "a name with a middle part inside"
ok "Differs Only In Case"
if [ "$marker" = new ]; then
ok "a short name"
ok "middle part"
ok "differs only in case"
ok "the tool runs"
ok "a line that only opens like a skip"
else
skip "the tool runs lite" "no full mode"
printf '  skip  a line that only opens like a skip (and goes on\n'
fi
for i in 1 2 3 4 5 6 7 8 9 10; do
{ [ "$marker" = new ] || [ "$i" -lt 10 ]; } && ok "asked ten times, nine of them against the base"
{ [ "$marker" = old ] || [ "$i" -le 2 ]; } && ok "asked twice, and ten times against the base"
done
printf '\nreached\n\n%d passed, %d failed, %d skipped\n' "$PASS" "$FAIL" "$SKIP"
EOF
  { printf '%s\n' "a short name and more after it" "a name with a middle part inside" "Differs Only In Case" \
      "a short name" "middle part" "differs only in case" "the tool runs" "a line that only opens like a skip" \
      "asked twice, and ten times against the base" "asked twice, and ten times against the base"
    for i in 1 2 3 4 5 6 7 8 9 10; do printf '%s\n' "asked ten times, nine of them against the base"; done
  } | _red_rows > "$RED/near/engine/harness/tests/assertions.tsv"
  _red "$RED/near" engine/harness/tests/red
  is  "a listed name the base never reaches is red, though a name it reaches begins with it, holds it in its middle, or is it in another case" \
      "$(_red_body "$RED/near" | grep -x -F -e "$(printf 'a short name\t1')" -e "$(printf 'middle part\t1')" -e "$(printf 'differs only in case\t1')")" \
      "$(printf 'a short name\t1\ndiffers only in case\t1\nmiddle part\t1')"
  is  "a skip of a name the manifest does not list is no skip of a listed name it begins with, unless a space and a parenthesis follow that name" \
      "$(_red_body "$RED/near" | grep -c -x -F "$(printf 'the tool runs\t1')")" "1"
  is  "a line that opens like a listed name's skip and does not end in a parenthesis is not its skip, so the name is still red" \
      "$(_red_body "$RED/near" | grep -c -x -F "$(printf 'a line that only opens like a skip\t1')")" "1"
  is  "a name listed ten times that the base reaches nine times is red by one, the counts compared as numbers" \
      "$(_red_body "$RED/near" | grep -c -x -F "$(printf 'asked ten times, nine of them against the base\t1')")" "1"
  is  "a name listed twice that the base reaches ten times takes nothing off the other shortfalls, six of thirty failing, all six never reached" \
      "$(_red_body "$RED/near" | sed -n '2,$p')|$(_red_sum)" \
      "$(printf 'run\t6\t22\t2\na line that only opens like a skip\t1\na short name\t1\nasked ten times, nine of them against the base\t1\ndiffers only in case\t1\nmiddle part\t1\nthe tool runs\t1')|red: 6 of 30 assertions fail against main (SHA) at engine 0.0.7, 6 of them never reached"
  # The log is read once, a copy taken after the strays are ended. A stray the
  # pattern misses still holds the log open, and this one, left behind by the
  # base's branch of the run, waits for red's comparison file to appear and
  # then writes the ok line of the name the base never reached. The run before
  # it prints enough lines that reading them takes a while, as the real
  # suite's log does. While red read the log again for the comparison, it held
  # that line in 5 of 5 runs and the shortfall was cancelled (2026-10-01). The
  # suite runs from the base's checkout, $TMP/tree, so ../red.cmp is red's
  # comparison file, and a command line that does not name $TMP escapes the
  # pattern. It gives up once red has removed that checkout, looked up from
  # the root, since a tests/red that writes no comparison file, as the base's
  # does in a real red run, would leave it spinning after the cleanup.
  _red_count "$RED/strayline" <<'EOF'
printf 'stray suite\n\n'
ok "an assertion before the stray"
awk 'BEGIN { for (i = 0; i < 30000; i++) print "        a line that is no assertion " i }'
[ "$marker" = new ] || sh -c 'i=0; while [ ! -e ../red.cmp ] && [ -e "$PWD/engine" ] && [ $i -lt 3000000 ]; do i=$((i+1)); done; j=0; while [ $j -lt 200 ]; do printf "  ok    a name the base never reaches, said late by a stray\n"; j=$((j+1)); done' &
[ "$marker" = new ] && ok "a name the base never reaches, said late by a stray"
printf '\nreached\n\n%d passed, %d failed\n' "$PASS" "$FAIL"
EOF
  _red_man "$RED/strayline" "an assertion before the stray" "a name the base never reaches, said late by a stray"
  _red "$RED/strayline" engine/harness/tests/red
  is  "a line a stray writes to the log after red has read it is not counted, so the name it says is still red, the log being read once" \
      "$(_red_body "$RED/strayline" | sed -n '2,$p')|$(_red_sum)" \
      "$(printf 'run\t1\t1\t0\na name the base never reaches, said late by a stray\t1')|red: 1 of 2 assertions fail against main (SHA) at engine 0.0.7, 1 of them never reached"
  is  "the near-name and stray fixtures' runs reach, against their own working trees, every name their manifests list and as often" \
      "$(_red_reach "$RED/near")|$(_red_reach "$RED/strayline")" \
      "$(cat "$RED/near/engine/harness/tests/assertions.tsv")|$(cat "$RED/strayline/engine/harness/tests/assertions.tsv")"
  is  "and the near-name and stray records are each one record, the run row's failed count what the names add up to" \
      "$(_red_whole "$RED/near") $(_red_whole "$RED/strayline")" "6=6 1=1"
  # The manifest compared is the one read before the suite ran. This run
  # rewrites it while it runs, as a run by hand could, to list a name it never
  # prints in place of the one it never reached.
  _red_seed "$RED/snap" main 0.0.7
  { _red_helpers; printf '_red_m=%q\n' "$RED/snap/engine/harness/tests/assertions.tsv"; cat <<'EOF'
printf 'snapshot suite\n\n'
ok "one assertion before the manifest is rewritten"
printf '1\tone assertion before the manifest is rewritten\n1\tadded to the manifest while the suite ran\n' > "$_red_m"
printf '\nreached\n\n%d passed, %d failed\n' "$PASS" "$FAIL"
EOF
  } | _red_cut "$RED/snap"
  _red_man "$RED/snap" "one assertion before the manifest is rewritten" "listed before the run and never reached"
  _red "$RED/snap" engine/harness/tests/red
  is  "the manifest compared is the one read before the suite ran, not the one the run rewrote while it ran" \
      "$(_red_body "$RED/snap" | sed -n '2,$p')|$(cut -f2 "$RED/snap/engine/harness/tests/assertions.tsv" | tr '\n' ';')" \
      "$(printf 'run\t1\t1\t0\nlisted before the run and never reached\t1')|one assertion before the manifest is rewritten;added to the manifest while the suite ran;"
  # The comparison comes after the checks #371 added and never answers for
  # them: a suite that died short of reached is refused as unfinished, however
  # many of its manifest's names it never reached.
  _red_seed "$RED/unfin" main 0.0.7
  _red_cut "$RED/unfin" <<'EOF'
printf 'marker suite\n\n  ok    the first of three\n'
kill -9 $$
printf '  ok    the second of three\n  ok    the third of three\n\nreached\n'
EOF
  _red_man "$RED/unfin" "the first of three" "the second of three" "the third of three"
  _red "$RED/unfin" engine/harness/tests/red
  is  "a suite killed short of reached is refused as unfinished, not recorded with the names it never reached, exit 2" \
      "$(_red_rc)|$(_red_said)" "2|1|red: not run: the suite against main did not finish (exit 137 after 1 assertions)"
  is  "and red.tsv holds the two rows saying no red run was made, none of the names it never reached" \
      "$(_red_body "$RED/unfin")" "$(printf 'base\t-\t-\t-\nrun\t-\t-\t-')"
  # The manifest is read before the base is resolved or the suite run, so a
  # bad one costs seconds and not a run. Each refusal is exit 2, one line on
  # stdout naming why, red.tsv's two rows of -, nothing left in the tmpdir or
  # changed in the tree, and the fixture's run never executed: it leaves a
  # file beside the repository when it does, as the first run here shows.
  _red_seed "$RED/mf" main 0.0.7
  { printf ': > %q\n' "$RED/mf.ran"; cat <<'EOF'
printf 'marker suite\n\n  ok    the one assertion it prints\n\nreached\n\n1 passed, 0 failed\n'
EOF
  } | _red_cut "$RED/mf"
  _red_mfp="$RED/mf/engine/harness/tests/assertions.tsv"
  _red_mfh="$(cd "$RED/mf/engine/harness/tests" && pwd)"
  # dir [base]: a red run that must stop before the suite, and what it left,
  # on one line.
  _red_pre() {
    local left st; rm -f "$1.ran"
    left="$(ls -A "$RED/tmpdir" | wc -l | tr -d ' ')"; st="$(_red_stat "$1")"
    _red "$1" engine/harness/tests/red "${@:2}"
    printf '%s|%s|%s|%s|%s' "$(_red_rc)" "$(_red_said)" "$(_red_body "$1" | tr '\t\n' ' ;')" \
      "$([ -e "$1.ran" ] && echo ran || echo not run)" \
      "$([ "$(ls -A "$RED/tmpdir" | wc -l | tr -d ' ')" = "$left" ] && [ "$(_red_stat "$1")" = "$st" ] && echo as it was || echo changed)"
  }
  # reason: what _red_pre prints for a refusal that gives it.
  _red_no() { printf '2|1|red: not run: %s|base - - -;run - - -;|not run|as it was' "$1"; }
  _red_man "$RED/mf" "the one assertion it prints"
  rm -f "$RED/mf.ran"; _red "$RED/mf" engine/harness/tests/red
  is  "the refusals' fixture run, given a manifest naming what it prints, executes, leaves its file, and is recorded with the summary of before" \
      "$(_red_rc)|$([ -e "$RED/mf.ran" ] && echo ran)|$(_red_body "$RED/mf" | sed -n 2p)|$(_red_sum)" \
      "0|ran|$(printf 'run\t0\t1\t0')|red: 0 of 1 assertions fail against main (SHA) at engine 0.0.7"
  rm -f "$_red_mfp"
  is  "with no assertions.tsv beside it the red run is refused before the suite runs, exit 2, the claim retracted and nothing left" \
      "$(_red_pre "$RED/mf")" "$(_red_no "no readable assertions.tsv beside $_red_mfh/red")"
  is  "and a missing manifest is the reason given ahead of a base that does not resolve" \
      "$(_red_pre "$RED/mf" no-such-ref)" "$(_red_no "no readable assertions.tsv beside $_red_mfh/red")"
  mkdir "$_red_mfp"
  is  "an assertions.tsv that is a directory is refused as no readable manifest, before the suite runs" \
      "$(_red_pre "$RED/mf")" "$(_red_no "no readable assertions.tsv beside $_red_mfh/red")"
  rmdir "$_red_mfp"
  printf '1\tthe one assertion it prints\n' > "$_red_mfp"; chmod 000 "$_red_mfp"
  if [ -r "$_red_mfp" ]; then
    skip "an assertions.tsv it cannot read is refused as no readable manifest, before the suite runs" "this user reads a file of mode 000"
  else
    is  "an assertions.tsv it cannot read is refused as no readable manifest, before the suite runs" \
        "$(_red_pre "$RED/mf")" "$(_red_no "no readable assertions.tsv beside $_red_mfh/red")"
  fi
  chmod 644 "$_red_mfp"
  printf '1\tthe one assertion it prints\nx\tanother\n' > "$_red_mfp"
  is  "a manifest row whose count is not a number is refused naming its line, before the suite runs" \
      "$(_red_pre "$RED/mf")" "$(_red_no "assertions.tsv line 2 is not a count, a tab and a name")"
  printf '1 the one assertion it prints\n' > "$_red_mfp"
  is  "a manifest row with no tab between its count and its name is refused naming its line" \
      "$(_red_pre "$RED/mf")" "$(_red_no "assertions.tsv line 1 is not a count, a tab and a name")"
  printf '1\tthe one assertion it prints\n1\t\n' > "$_red_mfp"
  is  "a manifest row whose name is empty is refused naming its line" \
      "$(_red_pre "$RED/mf")" "$(_red_no "assertions.tsv line 2 is not a count, a tab and a name")"
  printf '1\tthe one assertion it prints\n\n01\tanother\n' > "$_red_mfp"
  is  "a manifest count with a leading zero is refused naming its line, the empty line above it counted" \
      "$(_red_pre "$RED/mf")" "$(_red_no "assertions.tsv line 3 is not a count, a tab and a name")"
  printf '0\tthe one assertion it prints\n' > "$_red_mfp"
  is  "a manifest count of zero is refused naming its line" \
      "$(_red_pre "$RED/mf")" "$(_red_no "assertions.tsv line 1 is not a count, a tab and a name")"
  # A count is digits alone, so one that reads as a number with more around it
  # is not one either.
  printf '1\tthe one assertion it prints\n1x\tanother\n' > "$_red_mfp"; _red_c1="$(_red_pre "$RED/mf")"
  printf '1\tthe one assertion it prints\n1.5\tanother\n' > "$_red_mfp"; _red_c2="$(_red_pre "$RED/mf")"
  printf '1\tthe one assertion it prints\n 1\tanother\n' > "$_red_mfp"; _red_c3="$(_red_pre "$RED/mf")"
  is  "a manifest count of 1x, of 1.5 or led by a space is refused naming its line, before the suite runs" \
      "$_red_c1#$_red_c2#$_red_c3" \
      "$(_red_no "assertions.tsv line 2 is not a count, a tab and a name")#$(_red_no "assertions.tsv line 2 is not a count, a tab and a name")#$(_red_no "assertions.tsv line 2 is not a count, a tab and a name")"
  printf '1\tthe one assertion it prints\n2\tanother\n1\tthe one assertion it prints\n' > "$_red_mfp"
  is  "a manifest row repeating a name an earlier row holds is refused naming the later line, before the suite runs" \
      "$(_red_pre "$RED/mf")" "$(_red_no "assertions.tsv line 3 repeats a name an earlier line holds")"
  printf '1\tthe one assertion it prints\n1\tthe one assertion it prints\nnot a row\n' > "$_red_mfp"
  is  "the first faulty manifest line is the one named, a repeat on line 2 ahead of a malformed line 3" \
      "$(_red_pre "$RED/mf")" "$(_red_no "assertions.tsv line 2 repeats a name an earlier line holds")"
  : > "$_red_mfp"
  is  "an empty assertions.tsv is refused as listing no assertion, before the suite runs" \
      "$(_red_pre "$RED/mf")" "$(_red_no "assertions.tsv beside $_red_mfh/red lists no assertion")"
  printf '\n\n\n' > "$_red_mfp"
  is  "an assertions.tsv of empty lines alone is refused as listing no assertion too" \
      "$(_red_pre "$RED/mf")" "$(_red_no "assertions.tsv beside $_red_mfh/red lists no assertion")"
  # The line these cases stand for is this suite's own, and it must be the last
  # line of this file shaped like a section's header: every top-level header is
  # a printf of a newline, a title and a newline, and so is the marker. A section
  # added after the marker, or the marker deleted or reworded, leaves another
  # line last and fails here rather than in a red run. The fixtures' copies of
  # the marker sit earlier in this file.
  _red_own="$(_RP="^printf '\\\\n[^%']*\\\\n'\$" awk '$0 ~ ENVIRON["_RP"] { l = $0 } END { print l }' <(_suite_src))"
  is  "the suite's own completion marker, the reached line tests/red requires, still follows its last section" \
      "$_red_own" "printf '\\nreached\\n'"
else
  for a in "a red run against main exits 0 once the suite has run" "and stdout is the one summary line" \
           "and the summary counts three of six assertions failing against main at the engine version main declares" \
           "and the sha it parenthesises abbreviates main's commit" \
           "the base row names main, its full sha and the version at that commit, not the tree's" \
           "the run row counts three failed, two passed, one skipped" \
           "the failed names follow in c order, once each, with the times they failed" \
           "the tree's run executed against main's lib, never the base's own run" \
           "the manifest variable reached the run" "a stale red.tsv is overwritten, not appended to" \
           "nothing in the tree but red.tsv changed" "and no temporary directory is left under the tmpdir it was given" \
           "invoked from inside another repository it still reads its own" \
           "invoked by a relative path from a subdirectory it still finds its root" \
           "an explicit base argument names the ref to run against" \
           "and a totals line without a skipped clause records skipped as 0" \
           "with neither origin/main nor main to fall back on the red run cannot run, exit 2" \
           "and says so on stdout" "and red.tsv retracts the earlier claim rather than keeping it" \
           "with no run beside it the red run cannot run, exit 2" "and the file then states that no red run was possible" \
           "with neither a run nor a manifest beside it, the missing run is the reason it gives" \
           "with both refs present origin/main is the default base" \
           "naming main explicitly runs against the local branch, whose lib the tree's run passes" \
           "and zero failures is still exit 0" "and the summary then counts zero of six" \
           "a suite killed before it printed reached is not a red run, exit 2" \
           "and stdout is the one line naming main, the kill's exit 137 and the four assertions it reached" \
           "and red.tsv holds only the two rows saying no red run was made, the stale claim retracted" \
           "and that exit 2 leaves no temporary directory behind either" \
           "a suite that exits 0 with a totals line but no reached line is refused too, exit 2" \
           "and its reason names exit 0 and the three assertions it printed, a skip among them" \
           "and red.tsv again holds only the two rows saying no red run was made" \
           "a line that only contains the word reached is not the marker, exit 2" \
           "and a suite ended by sigterm is reported as exit 143 after its two assertions" \
           "and red.tsv holds the two rows saying no red run was made for it as well" \
           "a suite killed before its first assertion is refused as unfinished, not as empty" \
           "a suite that prints reached having run no assertion is still refused, exit 2" \
           "and it is refused as empty, not as unfinished" \
           "a suite that exits 1 without reached, as a finished red run exits, is refused, exit 2" \
           "and its reason names exit 1 and the three assertions it printed, the failure among them, on one line" \
           "and red.tsv holds the two rows saying no red run was made, not the failure it printed" \
           "a suite killed after it printed reached is still a red run, exit 0" \
           "and its record counts one failed, one passed and one skipped, the failed name below" \
           "a reached line a child wrote to stderr early does not make a suite killed after it a red run, exit 2" \
           "and its reason counts the three assertions printed after that stray line" \
           "and red.tsv holds the two rows saying no red run was made, the stray reached notwithstanding" \
           "a suite that printed an assertion after reached and was killed is refused, exit 2" \
           "and its reason counts both assertions, the one after reached among them" \
           "and red.tsv holds the two rows saying no red run was made for the suite that went on past reached" \
           "a stray reached followed only by ok lines does not make a suite killed after them a red run, exit 2" \
           "and red.tsv holds the two rows saying no red run was made, the ok lines after the stray reached notwithstanding" \
           "a stray reached followed only by skip lines does not make a suite killed after them a red run, exit 2" \
           "and red.tsv holds the two rows saying no red run was made, the skip lines after the stray reached notwithstanding" \
           "a suite with a stray reached early and the real one after its last assertion is a red run, exit 0" \
           "and its record is the base row, one failed and two passed, and the failed name, the stray reached notwithstanding" \
           "an assertion whose arithmetic errors on the base's - and so never runs is recorded red, by the one time it never ran" \
           "and its summary is one line, one of three failing against main, one of them never reached" \
           "and a red run holding an assertion it never reached exits 0, recorded and not refused" \
           "and red.tsv's header says an assertion the manifest lists and the base run never reached counts as failed" \
           "after an arithmetic error inside a for and an if, every assertion left in each block is recorded red, by the times the base never reached it" \
           "and the run row counts the one failure the base printed and the eight times it never reached as nine failed" \
           "and the summary counts twelve, nine failing, eight of them never reached" \
           "a name the manifest lists twice that the base run reaches once is a row counting the one time it never reached it" \
           "a name that fails once and is not asked its second time against the base is one row counting both" \
           "a skip line counts as reached, a name holding a parenthesis and a reason holding its own among them, so no skipped name is red" \
           "a name reached more often than listed offsets no other name's shortfall, so the run row counts two never reached among four failed" \
           "names the manifest does not list are not compared, and the one that fails is still a failed row" \
           "and that summary counts eleven, four failing, two of them never reached" \
           "a name listed twice that the base run skips once is red by the one time it never reached it, one skip line counting once" \
           "manifest names are compared byte for byte, a backslash, brackets, a star, a dot and a tab each itself" \
           "the arithmetic, block and byte fixtures' runs reach, against their own working trees, every name their manifests list and as often" \
           "each record with names never reached is one record, its run row's failed count what its names add up to" \
           "a listed name the base never reaches is red, though a name it reaches begins with it, holds it in its middle, or is it in another case" \
           "a skip of a name the manifest does not list is no skip of a listed name it begins with, unless a space and a parenthesis follow that name" \
           "a line that opens like a listed name's skip and does not end in a parenthesis is not its skip, so the name is still red" \
           "a name listed ten times that the base reaches nine times is red by one, the counts compared as numbers" \
           "a name listed twice that the base reaches ten times takes nothing off the other shortfalls, six of thirty failing, all six never reached" \
           "a line a stray writes to the log after red has read it is not counted, so the name it says is still red, the log being read once" \
           "the near-name and stray fixtures' runs reach, against their own working trees, every name their manifests list and as often" \
           "and the near-name and stray records are each one record, the run row's failed count what the names add up to" \
           "the manifest compared is the one read before the suite ran, not the one the run rewrote while it ran" \
           "a suite killed short of reached is refused as unfinished, not recorded with the names it never reached, exit 2" \
           "and red.tsv holds the two rows saying no red run was made, none of the names it never reached" \
           "the refusals' fixture run, given a manifest naming what it prints, executes, leaves its file, and is recorded with the summary of before" \
           "with no assertions.tsv beside it the red run is refused before the suite runs, exit 2, the claim retracted and nothing left" \
           "and a missing manifest is the reason given ahead of a base that does not resolve" \
           "an assertions.tsv that is a directory is refused as no readable manifest, before the suite runs" \
           "an assertions.tsv it cannot read is refused as no readable manifest, before the suite runs" \
           "a manifest row whose count is not a number is refused naming its line, before the suite runs" \
           "a manifest row with no tab between its count and its name is refused naming its line" \
           "a manifest row whose name is empty is refused naming its line" \
           "a manifest count with a leading zero is refused naming its line, the empty line above it counted" \
           "a manifest count of zero is refused naming its line" \
           "a manifest count of 1x, of 1.5 or led by a space is refused naming its line, before the suite runs" \
           "a manifest row repeating a name an earlier row holds is refused naming the later line, before the suite runs" \
           "the first faulty manifest line is the one named, a repeat on line 2 ahead of a malformed line 3" \
           "an empty assertions.tsv is refused as listing no assertion, before the suite runs" \
           "an assertions.tsv of empty lines alone is refused as listing no assertion too" \
           "the suite's own completion marker, the reached line tests/red requires, still follows its last section"; do
    skip "$a" "no tests/red beside this harness"; done
fi

