# Not blind: written by the fixer, from a third review of the audit and of
# felix new, one assertion per confirmed finding, each shown failing against
# the engine before its fix. Fixtures sit under $RV, as the reviews' do.
printf '\nfelix audit: what the third review found\n'
_au_build
_rv_build
_rv_hid_build
_nc_build

# An assignment's value ends where a word does, at a blank, a line break or
# ; & | ( ): past that is the next command, not more of the value. And a path
# assigned to a variable is not run by the assignment.
_rv_one r3/assign r3-as1 'W=/w/proj\ncp scripts/gate.sh /tmp/gate.bak'
_rv_one r3/assign r3-as2 'G=projects/felix/gate.sh\nwc -l \"$G\"'
_rv_one r3/assign r3-as3 'X=a;echo \"./tests/run\"'
_rv_one r3/assign r3-as4 'W=/w/proj ./scripts/gate.sh'
_rv_one r3/assign r3-as5 'W=/w\n./scripts/gate.sh'
is  "a VAR=value ends at ; or a line break, and assigning a gate's path is not running it: a copy or a quote after one is no check" \
    "$(_au_counts "$(_au --dir "$RV/r3/assign")")" "2 0 0 3"

# The shell's reserved words stand where a command does, so the runner after
# one is run. An if, a loop and a ! each take the runner's exit status, and a
# { } group hands it on. The words as text are still text.
_rv_one r3/words r3-kw1 'if npm test; then echo ok; else echo FAILED; fi'
_rv_one r3/words r3-kw2 'for d in a b; do pytest $d; done'
_rv_one r3/words r3-kw3 '! npm test'
_rv_one r3/words r3-kw4 '{ npm test; }'
_rv_one r3/words r3-kw5 'echo if npm test'
_rv_one r3/words r3-kw6 'grep -n \"do pytest\" notes.md'
_rvo="$(_au --dir "$RV/r3/words")"
[ "$(_au_counts "$_rvo")" = "4 0 0 2" ] && _au_nums "$_rvo" 'pipe|background' 3 \
  && ok  "a runner after if, do, ! or { is a check, and 3 of the 4 hand their status to the if, the loop or the !" \
  || bad "a runner after if, do, ! or { is a check, and 3 of the 4 hand their status to the if, the loop or the !" "$_rvo"

# A program path quoted at command position is the program: the runner may be
# its last word or the word after it. A quoted span holding a blank is not one
# command name, so "npm test" run as a name is not npm.
_rv_one r3/qpath r3-qp1 'W=/w/proj\n\"$W/.venv/bin/python\" -m pytest -q'
_rv_one r3/qpath r3-qp2 '\"$FELIX_HOME/harness/felix\" gate'
_rv_one r3/qpath r3-qp3 '\"/usr/bin/python3\" -m pytest tests'
_rv_one r3/qpath r3-qp4 '\"./tests/run\"'
_rv_one r3/qpath r3-qp5 '\"npm test\"'
is  "a quoted program path at command position is the program: \"\$W/.venv/bin/python\" -m pytest and \"\$FELIX_HOME/harness/felix\" gate are checks, \"npm test\" as a name is not" \
    "$(_au_counts "$(_au --dir "$RV/r3/qpath")")" "4 0 0 1"

# A backslash that ends a line joins it to the next, so the && list goes on
# and the argument on the next line is still an argument. Two backslashes are
# one escaped backslash, and the line break after them does end the command.
_rv_one r3/contd r3-cn1 'npm test > /tmp/t.log 2>&1 && \\\ngit commit -q -m \"fix\" && echo committed'
_rv_one r3/contd r3-cn2 'awk '"'"'{print}'"'"' \\\n  tests/run > /tmp/run.copy'
_rv_one r3/contd r3-cn3 'npm \\\ntest'
_rv_one r3/contd r3-cn4 'echo a \\\\\nnpm test\necho b'
_rvo="$(_au --dir "$RV/r3/contd")"
[ "$(_au_counts "$_rvo")" = "3 0 0 1" ] && _au_nums "$_rvo" 'pipe|background' 1 \
  && ok  "a line ending in one backslash goes on to the next: an && list across it can fail, and a path on the next line is an argument" \
  || bad "a line ending in one backslash goes on to the next: an && list across it can fail, and a path on the next line is an argument" "$_rvo"

# A # that starts a word, outside quotes, starts a comment to the end of the
# line. Its apostrophe opens no quote, its ( and ; make no command position,
# and a # inside a word is not one.
_rv_one r3/comment r3-cm1 '# run the project'"'"'s tests\nnpm test'
_rv_one r3/comment r3-cm2 '# see README (npm test) for the full suite\nls -la'
_rv_one r3/comment r3-cm3 'npm test  # quick; full run later'
_rv_one r3/comment r3-cm4 'echo a#b; npm test'
_rv_one r3/comment r3-cm5 'python3 - <<'"'"'PY'"'"'\nprint(1)\nPY\n# the test'"'"'s expectation\npython3 - <<'"'"'PY'"'"'\nprint(2)\nPY\nbash engine/harness/tests/run'
_rvo="$(_au --dir "$RV/r3/comment")"
[ "$(_au_counts "$_rvo")" = "4 0 0 1" ] && ! _rv_says "$_rvo" 'could not have' \
  && ok  "a shell comment is not code: its apostrophe opens no quote, its (npm test) runs nothing, and its ; takes no status" \
  || bad "a shell comment is not code: its apostrophe opens no quote, its (npm test) runs nothing, and its ; takes no status" "$_rvo"

# The runners a session in another ecosystem uses, the wrappers and flags a
# runner is reached through, and a loop: each a check by default. A report
# that calls them never-checked says no check ran where one did. Beside two
# commands of the same tools that run no tests.
_rv_i=0
for _c in 'until npm test; do :; done' 'env CI=1 npm test' 'nohup npm test' 'timeout -s KILL 600 npm test' \
          'sudo -E npm test' 'make -C engine test' 'npm --prefix web test' 'pnpm -r test' 'pnpm --filter web test' \
          'yarn workspace web test' 'npx -y jest' 'python -m unittest' 'deno test' 'forge test' 'npx hardhat test' \
          'flutter test' 'dart test' 'sbt test' 'stack test' 'cabal test' 'zig build test' 'lein test' \
          'bazel test //...' 'rake test' 'bin/rails test' 'php artisan test' 'mocha' 'npx playwright test' \
          'npm --prefix web install' 'make -C engine build'; do
  _rv_i=$((_rv_i + 1)); _rv_one r3/eco "r3-ec$_rv_i" "$_c"
done
is  "the default checks reach the runners of more ecosystems, and the flags and wrappers before them: 28 commands, each a check, beside 2 that run none" \
    "$(_au_counts "$(_au --dir "$RV/r3/eco")")" "28 0 0 2"
# And no roster names every runner, so the never line claims only what the
# roster recognises, and --verify ERE adds a project's own runner to it, in
# every project a run reads: the report, felix audit --help, the README and
# the ecosystem.tsv row say so, and none of them, nor lib/audit.sh, says the
# roster covers every ecosystem or that --verify replaces it. What it does to
# the counts is pinned above, beside the first fixture.
_rvo="$(_au --dir "$RV/r3/eco")"; _rvh="$(_au --help)"
_rvr="$(awk '/^## / { p = ($0 ~ /^## Try it/); next } p' "$REAL_HARNESS/../../README.md" 2>/dev/null | tr -d '`')"
_rve="$(awk -F'\t' '$2 == "lib/audit.sh" { print $4 }' "$REAL_HARNESS/ecosystem.tsv" 2>/dev/null)"
_rvn="the never line claims only what the roster recognises, and --verify ERE adds a project's own runner to it, in every project read, as the report, the help, the README and ecosystem.tsv say; none claims every ecosystem"
if grep -E '^ *never ' <<<"$_rvo" | grep -qi 'no check the roster recognises had run' \
   && _rv_says "$_rvo" 'verify ere adds a project.s own[^.]*every project' && _rv_says "$_rvr" 'verify ere adds a project.s own[^.]*every project' \
   && _rv_says "$_rvh" 'verify ere[^.]*beside the default runners' && _rv_says "$_rve" 'verify adds' \
   && ! _rv_says "$_rvo $_rvr $_rvh $_rve $(cat "$REAL_HARNESS"/lib/audit.sh "$REAL_HARNESS"/lib/audit-read.sh "$REAL_HARNESS"/lib/audit-count.sh)" 'every ecosystem|replaces (the|that) (roster|list)|in place of the default'; then
  ok  "$_rvn"
else
  bad "$_rvn" "never: $(printf '%s\n' "$_rvo" | grep -E '^ *never ') | $(printf '%s\n' "$_rvo" "$_rvr" "$_rvh" "$_rve" | grep -i -e 'verify' -e 'ecosystem' | tr '\n' ' ' | head -c 900)"
fi

# --since chooses which stops are counted, not what happened before them: a
# check the day before the cutoff still ran in that session, and an edit the
# day before still precedes a stop after it. A stop before the cutoff is not
# counted, and still ends its turn.
_rv_new r3/since r3-sn1
_au_edit 2026-09-19T22:00:00.000Z msg_r3sn1a toolu_r3sn1a; _au_bash 2026-09-19T22:30:00.000Z msg_r3sn1b toolu_r3sn1b 'npm test'
_au_res  2026-09-19T22:31:00.000Z toolu_r3sn1b ok; _au_stop 2026-09-19T23:00:00.000Z msg_r3sn1c
_au_edit 2026-09-20T01:00:00.000Z msg_r3sn1d toolu_r3sn1d; _au_stop 2026-09-20T02:00:00.000Z msg_r3sn1e
_rv_new r3/since r3-sn2
_au_edit 2026-09-19T22:00:00.000Z msg_r3sn2a toolu_r3sn2a; _au_stop 2026-09-20T01:00:00.000Z msg_r3sn2b
_rvo="$(_au --dir "$RV/r3/since" --since 2026-09-20)"
[ "$(_au_counts "$(_au --dir "$RV/r3/since")")" = "1 0 1 1" ] && [ "$(_au_counts "$_rvo")" = "0 0 1 1" ] && _au_nums "$_rvo" 'came after' 2 2 \
  && ok  "--since counts the stops on or after the cutoff, read against what came before it: a check the day before is stale, not never" \
  || bad "--since counts the stops on or after the cutoff, read against what came before it: a check the day before is stale, not never" "$_rvo"

# A resumed session copies the history it resumes, stop, hold and sessionId
# as they were, and then stops again. The same two files, named so that one
# sorts first in one directory and the other in the next: each stop and hold
# belongs to the session its record names, whichever file is read first.
_rv_resume() {  # dir original resumed
  _rv_new "$1" "$2"
  _au_edit "$_rv_ts:01.000Z" msg_r3rs1 toolu_r3rs1; _au_stop "$_rv_ts:02.000Z" msg_r3rs2
  _au_hold "$_rv_ts:03.000Z" 'Stop hook feedback:\nThe gate has never run in this checkout.'
  cp "$_AU_F" "${_AU_F%/*}/$3.jsonl"; _AU_F="${_AU_F%/*}/$3.jsonl"; _AU_SID="$3"
  _au_say  "$_rv_ts:05.000Z" 'go on'; _au_edit "$_rv_ts:06.000Z" msg_r3rs3 toolu_r3rs3
  _au_stop "$_rv_ts:07.000Z" msg_r3rs4
  _au_hold "$_rv_ts:08.000Z" 'Stop hook feedback:\nThe gate has never run in this checkout.'; }
_rv_resume r3/resume1 r3-o1 r3-r2; _rv_resume r3/resume2 r3-o2 r3-a1
_rvo="$(_au --dir "$RV/r3/resume1")"; _rvo2="$(_au --dir "$RV/r3/resume2")"
_au_nums "$_rvo" 'came after' 2 2 && _au_nums "$_rvo2" 'came after' 2 2 \
  && _au_nums "$_rvo" 'held' 2 2 && _au_nums "$_rvo2" 'held' 2 2 \
  && ok  "a stop and a hold copied into a resumed session belong to the session their record names, whichever transcript sorts first: 2 stops and 2 holds in 2 sessions both ways" \
  || bad "a stop and a hold copied into a resumed session belong to the session their record names, whichever transcript sorts first: 2 stops and 2 holds in 2 sessions both ways" \
         "$(printf '%s\n' "$_rvo" | grep -E 'came after|held') | $(printf '%s\n' "$_rvo2" | grep -E 'came after|held')"

# A transcript of summary records holds records, none with a timestamp, so
# no session: the sessions line says it was skipped for that, counted and in
# the right number, whether or not other transcripts made sessions. And under
# --since, one whose every timestamp is before the cutoff is skipped for
# holding none on or after it.
mkdir -p "$RV/r3/nots/-p" "$RV/r3/nots2/-p"
printf '%s\n' '{"type":"summary","summary":"a","leafUuid":"u-1"}' '{"type":"summary","summary":"b","leafUuid":"u-2"}' > "$RV/r3/nots/-p/s1.jsonl"
cp "$RV/r3/nots/-p/s1.jsonl" "$RV/r3/nots2/-p/s1.jsonl"; cp "$RV/r3/nots/-p/s1.jsonl" "$RV/r3/nots2/-p/s2.jsonl"
cp "$RV/hid/-Users-dev-rv/h1.jsonl" "$RV/r3/nots2/-p/h1.jsonl"
_rvo="$(printf '%s\n' "$(_au --dir "$RV/r3/nots")" | grep -E '^ *sessions ')"
_rvo2="$(printf '%s\n' "$(_au --dir "$RV/r3/nots2")" | grep -E '^ *sessions ')"
_rvo3="$(printf '%s\n' "$(_au --dir "$RV/r3/nots2" --since 2026-05-01)" | grep -E '^ *sessions ')"
_rvn="a transcript with no timestamped record is said to be skipped for it, counted and in the singular or plural, beside sessions or none"
case "$_rvo|$_rvo2|$_rvo3" in
  *"sessions"*" 0"*"1 transcript with no timestamped record was skipped"*"|"*"sessions"*" 1"*"2 transcripts with no timestamped record were skipped"*"|"*"sessions"*" 0"*"3 transcripts with no timestamped record on or after 2026-05-01 were skipped"*)
       ok  "$_rvn" ;;
  *)   bad "$_rvn" "$_rvo | $_rvo2 | $_rvo3" ;;
esac

# A person who pastes the hook's feedback as the first words of their own
# message is quoting it: only the hook's meta record is a hold. Beside a real
# hold in another session, so exactly one is counted. Their times differ, since
# a record copied into a resumed session is known by its uuid and time.
_rv_new r3/paste r3-ps1
_au_stop "$_rv_ts:01.000Z" msg_r3ps1a
_au_say  "$_rv_ts:02.000Z" 'Stop hook feedback:\nThe gate has never run in this checkout.\n\nwhy did I get this?'
_au_stop "$_rv_ts:03.000Z" msg_r3ps1b
_rv_new r3/paste r3-ps2
_au_stop "$_rv_ts:04.000Z" msg_r3ps2a
_au_hold "$_rv_ts:05.000Z" 'Stop hook feedback:\nThe gate has never run in this checkout.'
_au_nums "$(_au --dir "$RV/r3/paste")" 'held' 1 1 \
  && ok  "a person's message that starts with pasted stop hook feedback is not a hold; the hook's own meta record is" \
  || bad "a person's message that starts with pasted stop hook feedback is not a hold; the hook's own meta record is" "$(_au --dir "$RV/r3/paste" | grep -i held)"

# The Stop hook holds nothing where project.json names no gate, and felix new
# --no-commission leaves it empty where none was guessed. So the help's lines
# for it, the audit's closing line and the README's Try it section say when
# its sessions are held in the same words: once felix install has run, only
# where a gate was guessed, and where none was, set gate in project.json
# first. That clause is the only place any of them says held.
_rv_sq() { printf '%s\n' "$1" | tr -d '`' | tr -s ' \n' '  '; }
# The indent is measured, not matched. mawk 1.3.4, Ubuntu's awk, fails an
# anchored repeat whose minimum is two or more once the text runs past that
# minimum: /^ {20,}[^ ]/ matches twenty spaces and not the help's twenty-seven,
# so there the help read as empty.
_rvh="$(_rv_sq "$("$FELIX" 2>&1 | awk '/--no-commission$/ { p = 1; next } p && match($0, /[^ ]/) - 1 < 20 { p = 0 } p')")"
_rvl="$(_rv_sq "$(_au_last "$(_au --dir "$RV/r3/paste")")")"
_rvr="$(_rv_sq "$(awk '/^## / { p = ($0 ~ /^## Try it/); next } p' "$REAL_HARNESS/../../README.md" 2>/dev/null)")"
_rvre='where a gate was guessed, its sessions are held once felix install has run; where none was, set gate in project[.]json first'
_rvx=""
for _t in "help|$_rvh" "audit|$_rvl" "README|$_rvr"; do
  _rv_says "${_t#*|}" "$_rvre" && [ "$(printf '%s' "${_t#*|}" | awk '{ n += gsub(/held/, "") } END { print n + 0 }')" = 1 ] \
    || _rvx="$_rvx [${_t%%|*}: $(printf '%s' "${_t#*|}" | tr -s ' ' | grep -oiE '[^.;]*held[^.]*' | head -2 | tr '\n' ' ')]"
done
[ -z "$_rvx" ] \
  && ok  "the help, the audit and the README say in the same words that a --no-commission project's sessions are held once felix install has run where a gate was guessed, and to set gate in project.json first where none was" \
  || bad "the help, the audit and the README say in the same words that a --no-commission project's sessions are held once felix install has run where a gate was guessed, and to set gate in project.json first where none was" "$_rvx"

# A file changed through Bash in place is an edit: sed -i, perl -i, a > or
# >> to a named path, tee to one, patch and git apply, each at command
# position. So a sed -i, a git apply, a patch or a >> after a passing check
# leaves the stop stale; a turn whose only change was a redirect into a
# source file is among the stops; a write to scratch is left out, as an Edit
# to scratch is; and neither the log a check's own pipeline writes, nor a
# write to /dev/null, a dry run, a > in (( )), a > in text kept from a quoted
# $( ), nor a write after a cd to a place not named, is an edit at all. The
# report and the README say, in one line, that other writes through Bash are
# not seen.
_rv_bw() {  # session edit? command...: an Edit if edit? is e, each command ok, a stop
  local s="$1" e="$2" k=0 c; shift 2; _rv_new r3/bashed "$s"
  [ "$e" = e ] && _au_edit "$_rv_ts:01.000Z" "msg_${s}e" "toolu_${s}e"
  for c in "$@"; do k=$((k + 1)); _au_bash "$_rv_ts:0$((k + 1)).000Z" "msg_${s}$k" "toolu_${s}$k" "$c"; _au_res "$_rv_ts:0$((k + 1)).500Z" "toolu_${s}$k" ok; done
  _au_stop "$_rv_ts:09.000Z" "msg_${s}s"; }
_rv_bw r3-bw1 e 'npm test' 'sed -i \"\" s/retries = 3/retries = 0/ src/app.js'
_rv_bw r3-bw2 - 'cat > src/util.js <<EOF\nexport const x = 1\nEOF'
_rv_bw r3-bw3 e 'perl -pi -e '"'"'s/a/b/'"'"' lib/x.pm && npm test'
_rv_bw r3-bw4 e 'npm test 2>&1 | tee test.log'
_rv_bw r3-bw5 - 'echo x > /tmp/scratch.txt'
_rv_bw r3-bw6 e 'npm test' 'git apply fix.diff'
_rv_bw r3-bw7 e 'npm test' 'echo done > /dev/null; grep -c x src/a.js > /dev/null 2>&1'
_rv_bw r3-bw8 e 'npm test' 'git apply --check fix.diff'
_rv_bw r3-bw9 e 'npm test' 'patch -p1 < fix.diff'
_rv_bw r3-bw10 e 'npm test' 'echo '"'"'{}'"'"' >> config/app.json'
_rv_bw r3-bw11 - 'if (( n > 0 )); then echo big; fi'
_rv_bw r3-bw12 e 'npm test' 'echo \"sites: $(grep -c '"'"'<loc>'"'"' sitemap.xml) of >=3\"'
_rv_bw r3-bw13 - 'cd \"$SP\" && cat > fix.sh <<EOF\necho x\nEOF'
_rvo="$(_au --dir "$RV/r3/bashed")"
_rvr="$(awk '/^## / { p = ($0 ~ /^## Try it/); next } p' "$REAL_HARNESS/../../README.md" 2>/dev/null | tr -d '`')"
_rvn="sed -i, perl -i, a > or >> to a named path, tee, patch and git apply are edits: after a passing check the stop is stale, alone it is a stop, to scratch it is left out; the report and the README say other writes through Bash are not seen"
if [ "$(_au_counts "$_rvo")" = "5 0 4 1" ] && _au_nums "$_rvo" 'came after' 10 && _au_nums "$_rvo" 'left out' 1 \
   && _rv_says "$_rvo" 'other writes through bash are not seen' && _rv_says "$_rvr" 'other writes through bash are not seen' \
   && ! _rv_says "$_rvo" 'sed -i[^.]*not seen' && ! _rv_says "$_rvr" 'sed -i[^.]*not seen'; then
  ok  "$_rvn"
else
  bad "$_rvn" "$(printf '%s\n' "$_rvo" | grep -iE 'came after|^ *(passed|failed|stale|never) |left out|bash') | $(printf '%s\n' "$_rvr" | grep -iE 'bash')"
fi

# The README says the audit needs bash and awk. A PATH holding those two and
# nothing else, from the plain clone, answers the same report.
mkdir -p "$RV/r3/onlyba"
ln -sf "$(command -v bash)" "$RV/r3/onlyba/bash"; ln -sf "$(command -v awk)" "$RV/r3/onlyba/awk"
_rvo="$(cd "$AU/cwd" && env -i HOME="$AU/home" PATH="$RV/r3/onlyba" "$AUF" audit --dir "$RV/r3/assign" 2>&1)"; _rvrc=$?
[ "$_rvrc" -eq 0 ] && [ "$(_au_counts "$_rvo")" = "2 0 0 3" ] \
  && ok  "felix audit runs with bash and awk alone on PATH, as the README says, and answers the same report" \
  || bad "felix audit runs with bash and awk alone on PATH, as the README says, and answers the same report" "rc=$_rvrc $(printf '%s' "$_rvo" | head -c 300)"

# And the README names all it runs: bash, which the first line of felix finds
# through /usr/bin/env, awk, and readlink, which the prelude calls only to
# follow a symlink to felix, as felix install tells a person to make. Through
# a symlink, bash, awk and readlink on PATH answer the same report, and bash
# and awk alone cannot.
mkdir -p "$RV/r3/onlybar" "$RV/r3/lnk"
for _c in bash awk readlink; do ln -sf "$(command -v "$_c")" "$RV/r3/onlybar/$_c"; done
ln -sf "$AUF" "$RV/r3/lnk/felix"
_rvo="$(cd "$AU/cwd" && env -i HOME="$AU/home" PATH="$RV/r3/onlybar" "$RV/r3/lnk/felix" audit --dir "$RV/r3/assign" 2>&1)"; _rvrc=$?
_rvo2="$(cd "$AU/cwd" && env -i HOME="$AU/home" PATH="$RV/r3/onlyba" "$RV/r3/lnk/felix" audit --dir "$RV/r3/assign" 2>&1)"; _rvrc2=$?
_rvr="$(awk '/^## / { p = ($0 ~ /^## Try it/); next } p' "$REAL_HARNESS/../../README.md" 2>/dev/null | tr -d '`')"
_rvn="the README names all felix audit runs, bash through /usr/bin/env, awk, and readlink where felix is reached through a symlink, which bash and awk alone cannot follow"
[ "$_rvrc" -eq 0 ] && [ "$(_au_counts "$_rvo")" = "2 0 0 3" ] && [ "$_rvrc2" -ne 0 ] \
   && _rv_says "$_rvr" 'bash[^.]*/usr/bin/env[^.]*awk[^.]*readlink[^.]*symlink' \
  && ok  "$_rvn" \
  || bad "$_rvn" "bash awk readlink: rc=$_rvrc $(printf '%s' "$_rvo" | head -c 200) | bash awk: rc=$_rvrc2 | README: $(printf '%s\n' "$_rvr" | grep -i -A1 'bash and')"

# felix new takes a name and a path. A third word, where the synopsis puts
# the flag, is refused before anything is made: a mistyped --no-commission
# there used to be dropped without a word, and full commissioning ran, with
# a marketplace added and plugins installed at user scope.
_nc_repo r-third
_ncx="$(_nc "$NC/r-third" ncthird . --no-comission)"; _ncxrc=$?; _ncxcalls="$(_nc_calls)"
_ncxmade=no; [ -e "$NC/home/projects/ncthird" ] && _ncxmade=yes
_ncw="$(_nc "$NC/r-third" ncextra . extra-arg --no-commission)"; _ncwrc=$?
_ncv="$(_nc "$NC/r-third" ncthird . --no-commission)"; _ncvrc=$?
if [ "$_ncxrc" -ne 0 ] && [ "$_ncxcalls" = "0" ] && [ "$_ncxmade" = no ] \
   && [ "$_ncwrc" -ne 0 ] && [ ! -e "$NC/home/projects/ncextra" ] \
   && [ "$_ncvrc" -eq 0 ] && _nc_bound r-third ncthird; then
  ok  "felix new refuses a third argument, a mistyped --no-commission or any other, before it makes anything or calls claude; spelled right, the same command binds"
else
  bad "felix new refuses a third argument, a mistyped --no-commission or any other, before it makes anything or calls claude; spelled right, the same command binds" \
      "typo: rc=$_ncxrc calls=$_ncxcalls made=$_ncxmade $(printf '%s' "$_ncx" | head -c 200) | extra: rc=$_ncwrc | right: rc=$_ncvrc $(printf '%s' "$_ncv" | tail -c 200)"
fi

# Any word but --no-commission that starts with - is a flag felix new does
# not take, wherever it stands, and the refusal names it as one beside the
# synopsis: a typo in the third or fourth place was an "unexpected argument",
# which left the person to work out that their flag was the word it meant.
# Refused before anything is made or any claude is called, in every place.
_nc_repo r-flag
_rvn="felix new refuses any flag but --no-commission, first, second, third or fourth, naming it as a flag beside the synopsis, before it makes anything or calls claude"
_rvx=""
for _a in "--no-comission ncflag" "ncflag --no-comission" "ncflag . --no-comission" "ncflag . --no-commission --dry-run" "ncflag -n ."; do
  # shellcheck disable=SC2086
  _ncx="$(_nc "$NC/r-flag" $_a)"; _ncxrc=$?; _ncxcalls="$(_nc_calls)"
  # shellcheck disable=SC2086
  _f="$(printf '%s\n' $_a | grep -e '^-' | grep -vx -e '--no-commission')"
  case "$_ncx" in *"usage: felix new"*"flag"*"$_f"*) _m=1 ;; *) _m=0 ;; esac
  if [ "$_ncxrc" -eq 0 ] || [ "$_ncxcalls" != "0" ] || [ -e "$NC/home/projects/ncflag" ] || [ -e "$NC/r-flag/.felix" ] || [ "$_m" -eq 0 ]; then
    _rvx="$_rvx [$_a: rc=$_ncxrc calls=$_ncxcalls $(printf '%s' "$_ncx" | head -c 160)]"
  fi
done
[ -z "$_rvx" ] && ok "$_rvn" || bad "$_rvn" "$_rvx"

# What is left out as no gate's: everything under Claude's configuration
# directory, a skill's script as much as a memory note, and Felix's own memory
# too. The report and the README name that whole scope, not memory and plans.
_rv_new r3/own r3-ow1
_au_tool toolu_r3ow1 Edit "{\"file_path\":\"$AU/cfg/skills/tool/scripts/run.py\",\"old_string\":\"a\",\"new_string\":\"b\"}"
_au_a "$_rv_ts:01.000Z" msg_r3ow1a '"tool_use"' "$_AU_B"; _au_stop "$_rv_ts:02.000Z" msg_r3ow1b
_rv_new r3/own r3-ow2
_au_tool toolu_r3ow2 Edit "{\"file_path\":\"$AU/home/.felix/memory/proj/DEVLOG.md\",\"old_string\":\"a\",\"new_string\":\"b\"}"
_au_a "$_rv_ts:01.000Z" msg_r3ow2a '"tool_use"' "$_AU_B"; _au_stop "$_rv_ts:02.000Z" msg_r3ow2b
_rvo="$(_au --dir "$RV/r3/own")"
_rvr="$(awk '/^## / { p = ($0 ~ /^## Try it/); next } p' "$REAL_HARNESS/../../README.md" 2>/dev/null)"
_au_nums "$_rvo" 'came after' 0 0 && _au_nums "$_rvo" 'left out' 2 \
  && _rv_says "$_rvo" 'left out[^.]*skills[^.]*felix' && _rv_says "$_rvr" 'leaves out[^.]*skills[^.]*felix' \
  && ok  "an edit to a skill under Claude's configuration directory or to Felix's memory is left out as no gate's, and the report and the README name that scope" \
  || bad "an edit to a skill under Claude's configuration directory or to Felix's memory is left out as no gate's, and the report and the README name that scope" \
         "$(printf '%s\n' "$_rvo" | grep -iE 'came after|left out|never ') | $(printf '%s\n' "$_rvr" | grep -i -A1 'leaves out')"
# And the README lists exactly what is left out, by the paths the audit
# compares: /tmp and TMPDIR, CLAUDE_CONFIG_DIR or ~/.claude where it is
# unset, and FELIX_MEMORY or ~/.felix/memory, not scratch files by name alone.
_rvr="$(awk '/^## / { p = ($0 ~ /^## Try it/); next } p' "$REAL_HARNESS/../../README.md" 2>/dev/null | tr -d '`')"
_rv_says "$_rvr" 'leaves out[^:]*:[^:]*/tmp[^:]*tmpdir[^:]*claude_config_dir[^:]*~/[.]claude[^:]*felix_memory[^:]*~/[.]felix/memory' \
  && ok  "the README lists by path exactly what the audit leaves out: /tmp, TMPDIR, CLAUDE_CONFIG_DIR or ~/.claude, FELIX_MEMORY or ~/.felix/memory" \
  || bad "the README lists by path exactly what the audit leaves out: /tmp, TMPDIR, CLAUDE_CONFIG_DIR or ~/.claude, FELIX_MEMORY or ~/.felix/memory" "$(printf '%s\n' "$_rvr" | grep -i -A3 'leaves out')"

# Here-documents are looked for within the size a command is read whole at,
# 256K, and beyond it in the windows read from its ends: splitting 5 MB on
# << and on line breaks cost minutes on BWK awk. Three 5 MB commands: one of
# 1.6 million << shifts, one of 700,000 lines that each open a here-document,
# and one here-document of 560,000 lines with the runner after it. Each is
# read, each passes, and the three take seconds.
mkdir -p "$RV/r3/hdbig/-p"
awk -v d="$RV/r3/hdbig/-p" "$_rv_bigawk"'
  BEGIN {
    one(d "/shifts.jsonl", "hs", "npm test; echo $((1" rep("<<1", 1600000) "))")
    one(d "/opens.jsonl", "ho", "npm test; cat <<EOF\\n" rep("<<EOF\\n", 700000) "EOF")
    one(d "/body.jsonl", "hb", "cat > ids.txt <<\047EOF\047\\n" rep("1234567\\n", 560000) "EOF\\nnpm test")
  }'
# Timed as CPU: 1.5 s for the three at a load average near 340. Past finding
# where each command ends, what they reach first is heredocs() on the 64K
# read from each end, nearly 22,000 << in each window of the first. With
# each << found again from the start of its window, the three still passed
# and took 185 s (2026-09-23), so 10 s stays far from both.
_rvo="$(_au --dir "$RV/r3/hdbig"; times > "$RV/r3/hdbig.cpu")"; _rv_ms="$(_au_ms "$RV/r3/hdbig.cpu")"
_rvn="three 5 MB commands dense in << or in line breaks are read in seconds, not minutes, and each still passes: under 10 seconds of CPU for the three"
if [ "$(_au_counts "$_rvo")" = "3 0 0 0" ]; then
  [ "$_rv_ms" -le 10000 ] && ok "$_rvn" || bad "$_rvn" "took ${_rv_ms} ms of CPU"
else
  bad "$_rvn" "it did not count them, so its speed says nothing: $(_au_counts "$_rvo") in ${_rv_ms} ms of CPU"
fi

# Over 256K the first 64K is read, and a script handed to a shell with -c
# that is still open at its end is script, not text the quote has not closed
# yet; the runner at the script's other end, in the last 64K, is read too.
# Three -c scripts just over the size holding a runner at either end, beside
# one holding none.
mkdir -p "$RV/r3/bigc/-p"
awk -v d="$RV/r3/bigc/-p" "$_rv_bigawk"'
  BEGIN {
    one(d "/c1.jsonl", "c1", "bash -c \047" rep("npm test;", 29200) "\047")
    one(d "/c2.jsonl", "c2", "bash -c \047" rep("echo filler; ", 23000) "npm test\047")
    one(d "/c3.jsonl", "c3", "sh -c \\\"npm test; " rep("echo filler; ", 23000) "\\\"")
    one(d "/c4.jsonl", "c4", "bash -c \047" rep("echo filler; ", 23000) "\047")
  }'
is  "a script handed to bash -c or sh -c over 256K is read at both ends: a runner at its start or its end is a check" \
    "$(_au_counts "$(_au --dir "$RV/r3/bigc")")" "3 0 0 1"

# The last check in a command is found without re-reading the rest of the
# command after each one, so a command's cost does not grow with the runners
# in it. Four commands just under 256K of 26,000 runners each after a ;,
# beside four of the same length and the same ; in the same places holding
# one; and four of one runner whose 26,000 arguments are tests/run, beside
# four whose arguments are tests/ruX. Each shape is a pair of its own, since a
# regression in one is diluted by the other. With hidden() made to read every
# command whole from its start, the ; shape took 2.7 to 2.8 times the CPU of
# the one beside it, the other 1.0, and the two mixed 2.0; made to find each
# match without the = before the rest, the tests/run shape took 3.0 to 3.1
# times, the other 0.9, and mixed 1.8, which one mixed pair passed three times
# in three. Both still counted every stop (2026-09-24, load average 200-340).
# Timed as CPU, so load slows both sides alike, but not always alike: one gate
# at a load near 300 read the mixed runners at 7.2 s against 3.3 s, where
# sixteen mixed pairs on the same engine at the same load read 0.93 to 0.95.
# Contention adds CPU time to the same work and never takes it away, so each
# set is read three times in turn and its least is compared. A correct engine
# fails only if all three reads of one set are slowed, and a slow one passes
# only if all three of the set beside it are; a correct one read 0.9 and 1.0.
mkdir -p "$RV/r3/smany/-p" "$RV/r3/sonce/-p" "$RV/r3/tmany/-p" "$RV/r3/tonce/-p"
awk -v d="$RV/r3" "$_rv_bigawk"'
  BEGIN { a = rep("pytest t; ", 26000); b = "pytest t; " rep("pyxest t; ", 25999)
          c = "pytest" rep(" tests/run", 26000); e = "pytest" rep(" tests/ruX", 26000)
          for (i = 1; i <= 4; i++) {
            one(d "/smany/-p/s" i ".jsonl", "m" i, a); one(d "/sonce/-p/s" i ".jsonl", "o" i, b)
            one(d "/tmany/-p/t" i ".jsonl", "n" i, c); one(d "/tonce/-p/t" i ".jsonl", "p" i, e) } }'
_rvset=(smany sonce tmany tonce); _rvlo=(0 0 0 0); _rvq=""
for _i in 1 2 3; do
  for _j in 0 1 2 3; do
    _rvo="$(_au --dir "$RV/r3/${_rvset[_j]}"; times > "$RV/r3/${_rvset[_j]}.cpu")"; _rvt="$(_au_ms "$RV/r3/${_rvset[_j]}.cpu")"
    [ "$_i" -eq 1 ] && _rvq="$_rvq $(_au_counts "$_rvo")"
    { [ "$_i" -eq 1 ] || [ "$_rvt" -lt "${_rvlo[_j]}" ]; } && _rvlo[_j]="$_rvt"
  done
done
_rvn="a command of 26,000 runners costs no more than twice the CPU of one of the same shape holding one: the last is found in one read"
if [ "$_rvq" != " 4 0 0 0 4 0 0 0 4 0 0 0 4 0 0 0" ]; then
  bad "$_rvn" "it did not count them, so their times say nothing:$_rvq"
elif [ "${_rvlo[1]}" -le 0 ] || [ "${_rvlo[3]}" -le 0 ]; then
  bad "$_rvn" "no CPU was read for the commands holding one: ${_rvlo[*]}"
elif [ "${_rvlo[0]}" -le $((2 * _rvlo[1])) ] && [ "${_rvlo[2]}" -le $((2 * _rvlo[3])) ]; then
  ok "$_rvn"
else
  bad "$_rvn" "least ms of CPU in three reads: 26,000 runners after a ; ${_rvlo[0]}, one ${_rvlo[1]}; one runner and 26,000 tests/run ${_rvlo[2]}, 26,000 tests/ruX ${_rvlo[3]}"
fi

