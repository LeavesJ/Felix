printf '\ndenial reads the command the shell runs\n'
# A Bash row was matched against the payload's JSON string, where a line break
# is a backslash and an n and everything the command only carries reads as if
# it ran. The marker row refused a commit message on 2026-09-22 because its
# `<name>` placeholder holds a `>`; of 175 refusals logged by then, about
# thirty were text of that kind. A command a row matches is now read again as
# the shell reads it, and refused only if the row still matches there. Each
# payload below is the JSON the hook receives, verbatim, so a line break is
# written \n and a backslash in the command \\.
#
# Both directions are asserted, and the second one is the one that matters:
# every "still refused" case is code that an earlier draft of the reader set
# aside as data, and each was a real command in the refusals that were logged.
{ printf 'Bash\t%s\tforce push drops commits\n' 'git push ([^;&|]* )?(--force|-f)( |$)'
  printf 'Bash\t%s\trewriting the binding by hand\n' "(>|tee|cp |mv |rm |ln |truncate|sed -i|install |dd of=)[^;&|]*[\"']?\\.felix(-home)?[\"']?([[:space:];&|)]|\$)"
  printf 'Bash\t%s\ta timed read never returns under zsh\n' 'read -t [0-9]+ [^;&|]*< <\('
} > "$FROOT/projects/widget/deny.tsv"
_prb() { _pre "$(cat)"; }

( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"git commit -F - <<'EOF'\ndocs: felix new <name> writes a .felix marker\nEOF"}}
J
is "a commit message in a here-document is not read as a command" "$rc" "0"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"git commit -m \"$(cat <<'EOF'\nfix: never git push --force here\nEOF\n)\""}}
J
is "nor is one in the \$(cat <<EOF) form of Claude Code's commit template" "$rc" "0"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"for c in 'git push --force origin main' 'git status'; do echo \"$c\"; done"}}
J
is "a quoted argument naming a denied command is data" "$rc" "0"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"ls # git push --force origin"}}
J
is "a comment is not a command" "$rc" "0"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"git push -q\ngh api repos/x/pages -f source=main"}}
J
is "a row no longer runs across a line break into the next command" "$rc" "0"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"sed -n '/git push --force /p' log.md"}}
J
is "a sed script that starts with a slash is not taken for a path" "$rc" "0"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"printf '%s' '{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git push --force origin main\"}}' | bash hooks/pre-tool"}}
J
is "a payload piped into a shell handed a script file is data to that script" "$rc" "0"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"git commit -m 'the reader doesn'\\''t refuse git push --force in a message'"}}
J
is "a message quoted in pieces round an apostrophe is still a message" "$rc" "0"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"echo \"$n logged refusals named git push --force here\""}}
J
is "a message that starts with a variable is not taken for a path" "$rc" "0"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"cat <<'EOF'\n$(git push --force origin main)\nEOF"}}
J
is "a quoted here-document word leaves the body unexpanded, so it is data" "$rc" "0"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"cat > \"$S/t.md\" <<'EOF'\nprintf 'x\\n' > .felix && true\nEOF\nls"}}
J
is "a here-document written to a file nothing runs is data" "$rc" "0"

( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}
J
is "a force push is still refused" "$rc" "2"
has "and says why" "$(cat "$FROOT/.deny-err")" "force push drops commits"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"bash -c 'git push --force origin main'"}}
J
is "a shell's -c script is still read as a command" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"eval 'git push --force origin main'"}}
J
is "and so is what eval is handed" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"git commit -m \"$(git push --force origin HEAD)\""}}
J
is "a \$( ) inside a quoted message still runs, and is refused" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"printf 'p\\n' > \"$T/repo/.felix\""}}
J
is "a quoted redirect target still writes the marker, and is refused" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"cat > \"$S/t.sh\" <<'EOF'\nprintf 'x\\n' > .felix && true\nEOF\nbash \"$S/t.sh\""}}
J
is "a here-document written to a file the command then runs is code" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"printf '%s\\n' 'git push --force origin main' > f.sh; bash f.sh"}}
J
is "and so is quoted text printed into a file the command then runs" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"cp seed \"/tmp/a b/.felix\""}}
J
is "a quoted path with a blank is still the file cp writes" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"cat <<E\"OF\"\nnotes\nEOF\ngit push -f origin topic"}}
J
is "a here-document word quoted in part ends where bash ends it" "$rc" "2"
# A file that writes a file the command then runs. Reading the first opens
# the command that writes the second, while the list of written files is being
# walked, and whether a for-in loop sees a key added under it differs between
# awks: this refused or allowed by hash order until the walk went by number.
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"echo \"echo 'git push -f x' > u.sh\" > t.sh; bash t.sh; bash u.sh"}}
J
is "a file written by a file the command runs is followed there as well" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"bash <<'EOF'\ngit push --force origin main\nEOF"}}
J
is "a here-document a shell reads is code" "$rc" "2"
# With -s the words after the shell are positional parameters, not a script
# file, so the body is still its script. 0.49.152 took the first of them for a
# file and read the body as data; found by the session scoping deny rows.
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"bash -s \"/tmp/gov\" <<'EOF'\ngit push --force origin main\nEOF"}}
J
is "and so is one handed to bash -s with arguments" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"cat <<EOF\n$(git push --force origin main)\nEOF"}}
J
is "an unquoted here-document word expands the body, so its \$( ) runs" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"echo 'git push --force origin main' | bash"}}
J
is "text piped into a shell is its script" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"until [ -f x ]; do read -t 5 -r _ < <(tail -f /dev/null); done"}}
J
is "a process substitution keeps the shape a row is written about" "$rc" "2"
rm -f "$FROOT/projects/widget/deny.tsv" "$FROOT/.deny-err"

printf '\ndenial reads every command\n'
# The reading above was, at first, consulted only after the payload's string
# had matched a row, so it could narrow a refusal and never widen one: a
# command the shell runs, that a row names, went unrefused wherever the
# string put something other than a blank at the end of a word the row
# wanted ended by one. Now the reading is the whole verdict for a Bash row,
# and the reader prints each separator as a token of its own.
#
# The rows are the ten Bash rows felix and another governed project carried on main on
# 2026-09-23, as written there. The refuse-side cases are the founder's own
# twelve, in the order of his list of that day, and none was refused before.
# The allow-side cases were written blind, from the rows alone, by an author
# who had not seen the reader; four of the forty-five it wrote (a read-only
# update-ref and symbolic-ref naming refs/remotes/, and a cat and a bash -n
# of the rival gate's path) are refused by the rows as written under any
# reader, which is the rows' problem, and are not asserted here. The first
# two are asserted at the end of this section, against the narrowed row.
cat > "$FROOT/projects/widget/deny.tsv" <<'EOF'
# tool	pattern	reason
Bash	git push ([^;&|]* )?(--force|-f)( |$)	force push drops commits
Bash	git commit ([^;&|]* )?--no-verify	--no-verify is how a gate stops being a gate
Bash	(>|tee|cp |mv |rm |ln |truncate|sed -i|install |dd of=)[^;&|]*["']?\.felix(-home)?["']?([[:space:];&|)]|$)	rewriting the binding by hand
Bash	read -t [0-9]+ [^;&|]*< <\(	a timed read never returns under zsh
Bash	git( +-[^ ]+( +[^ ]+)?)* +(update-ref|symbolic-ref|fetch|push)[^;&|]*refs/remotes/	a remote-tracking ref is what the remote said
Bash	git( +-[^ ]+( +[^ ]+)?)* +remote +(add|set-url|rename|remove|rm)( |$)	the remote is where the person is
Bash	git( +-[^ ]+( +[^ ]+)?)* +push[^;&|]* \+?([^ ]*:)?(refs/heads/)?main([[:space:];&|)]|$)	main is merged through felix merge and a person
Bash	(^|[;&| ])\./scripts/gate\.sh	that is not the gate Felix runs
Bash	git add ([^;&|]* )?(-A|--all|\.)( |$)	stage explicit paths
Bash	git add ([^;&|]* )?-f( |$)	never force-add an ignored file
EOF
is "the reader prints a command separator as a token of its own, an operator of two characters whole" \
   "$( . "$FROOT/harness/lib/deny.sh"; felix_deny_code 'git status;(ls)&&true' )" \
   "git status ;  ( ls )  && true"

( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"git add -A;"}}
J
is "the founder's case 1: a separator glued to the last word ends it, as the shell does" "$rc" "2"
has "and the row's reason is given" "$(cat "$FROOT/.deny-err")" "stage explicit paths"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"{ git add -A; }"}}
J
is "the founder's case 2: a group's separator ends the word too" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"git push -f\ngit status"}}
J
is "the founder's case 3: a line break ends a word as a blank does" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"sh -c \"git add -A\""}}
J
is "the founder's case 4: a shell's -c script is a command of its own, quotes and all" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"bash -c \"git push --force\""}}
J
is "the founder's case 5: and so under bash -c" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"find . -exec sh -c 'git add -A' \\;"}}
J
is "the founder's case 6: a -c script handed to find's -exec is still a command" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"x=\"$(git add -A)\""}}
J
is "the founder's case 7: a \$( ) assigned to a variable runs" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"\"git\" push -f origin main"}}
J
is "the founder's case 8: a quoted program name is the program" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"\"./scripts/gate.sh\""}}
J
is "the founder's case 9: a quoted path in command position runs" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"sh <<'EOF'\ngit add -A\nEOF"}}
J
is "the founder's case 10: a here-document a shell reads is its script" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"sh -s <<'EOF'\ngit add -A\nEOF"}}
J
is "the founder's case 11: and so with -s" "$rc" "2"
( cd "$REPO" && _prb ) <<'J'; rc=$?
{"tool_name":"Bash","tool_input":{"command":"cat <<'EOF' > .felix\nwidget\nEOF"}}
J
is "the founder's case 12: a redirect's target is written whatever line the here-document ends on" "$rc" "2"

# The blind allow cases, numbered as the author numbered them.
_allowed() { ( cd "$REPO" && _prb ); is "blind allow case $1: $2" "$?" "0"; }
_allowed 1 "a push named in a commit message is a message" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git commit -m \"hook: refuse git push --force and git push -f to main\""}}
J
_allowed 2 "a here-document handed to git commit -F is a message" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git commit -F - <<'EOF'\nhook: refuse bypassed commits\n\nThe hook now refuses git commit --no-verify, git push --force\nand git add -A. Fix failing checks instead of skipping them.\nEOF"}}
J
_allowed 3 "the commit template's \$(cat <<'EOF') is a message" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git commit -m \"$(cat <<'EOF'\nRefuse force-push and whole-tree staging\n\nThe hook now blocks git push --force and git push -f, whole-tree\nstaging with git add -A, git add --all or git add ., and any write\nto .felix or .felix-home.\n\nCo-Authored-By: Claude <noreply@anthropic.com>\nEOF\n)\""}}
J
_allowed 4 "a pull request body from a quoted here-document is text" <<'J'
{"tool_name":"Bash","tool_input":{"command":"gh pr create --base main --head feature/hook-hardening --title \"Harden the command-refusal hook\" --body \"$(cat <<'EOF'\n## Summary\n- Refuse git push --force origin main and any push to main\n- Refuse git remote add and git remote set-url\n- Refuse writes to .felix via cp, mv, rm or sed -i\n\n## Test plan\n- [x] git push -f is refused\n- [x] git push --force-with-lease on a feature branch is allowed\nEOF\n)\""}}
J
_allowed 5 "a redirect character inside a quoted message is text" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git commit -m \"Protect .felix from agent edits\" -m \"Refuses cp, mv, rm, ln, truncate and sed -i on .felix or .felix-home, and redirections such as > .felix.\""}}
J
_allowed 6 "lines naming the marker inside a here-document body are data" <<'J'
{"tool_name":"Bash","tool_input":{"command":"cat > notes.md <<'EOF'\n# Session notes\n- Never edit .felix by hand\n- Never run git push --force origin main\n- Stage files by name, not with git add -A\nEOF"}}
J
_allowed 7 "an append to .gitignore whose body names the marker writes .gitignore" <<'J'
{"tool_name":"Bash","tool_input":{"command":"cat >> .gitignore <<'EOF'\n.felix\n.felix-home\nEOF"}}
J
_allowed 8 "tee writes the file it names, and the body is data" <<'J'
{"tool_name":"Bash","tool_input":{"command":"tee docs/hook-rules.md <<'EOF' >/dev/null\nDo not edit .felix or .felix-home by hand.\nDo not run ./scripts/gate.sh from an agent session.\nEOF"}}
J
_allowed 9 "wc reads a here-document and runs none of it" <<'J'
{"tool_name":"Bash","tool_input":{"command":"wc -l <<'EOF'\ngit commit --no-verify -m wip\ngit add -A\nrm .felix\nEOF"}}
J
_allowed 10 "a python program in a here-document runs no shell" <<'J'
{"tool_name":"Bash","tool_input":{"command":"python3 - <<'EOF'\nimport re\npattern = r\"git push ([^;&|]* )?(--force|-f)( |$)\"\nfor cmd in [\"git push -f origin main\", \"git push --force-with-lease origin dev\"]:\n    print(cmd, bool(re.search(pattern, cmd)))\nEOF"}}
J
_allowed 11 "JSON on jq's stdin is data" <<'J'
{"tool_name":"Bash","tool_input":{"command":"jq -r '.[] | .cmd' <<'EOF'\n[{\"cmd\": \"git add -A\"}, {\"cmd\": \"git push --force origin main\"}]\nEOF"}}
J
_allowed 12 "grep's search phrase is data" <<'J'
{"tool_name":"Bash","tool_input":{"command":"grep -rn \"git push --force\" ."}}
J
_allowed 13 "rg's quoted pattern is data" <<'J'
{"tool_name":"Bash","tool_input":{"command":"rg -n 'git add -A' docs/"}}
J
_allowed 14 "git log's --grep value is data" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git log --oneline --grep='--no-verify'"}}
J
_allowed 15 "a JSON body sent by curl is data" <<'J'
{"tool_name":"Bash","tool_input":{"command":"curl -s -X POST http://localhost:8080/audit -H 'Content-Type: application/json' -d '{\"cmd\": \"git push -f origin main\", \"verdict\": \"refuse\"}'"}}
J
_allowed 16 "a quoted issue comment holding a flag and a semicolon is one value" <<'J'
{"tool_name":"Bash","tool_input":{"command":"gh api repos/{owner}/{repo}/issues/12/comments -f body='Please stop running git add -f on ignored build output; fix .gitignore instead.'"}}
J
_allowed 17 "an issue body holding two commands and && is one value" <<'J'
{"tool_name":"Bash","tool_input":{"command":"gh issue create --title \"Hook misses remote rewrites\" --body \"Repro: git remote add upstream https://github.com/example/repo.git && git push upstream main\""}}
J
_allowed 18 "git push -u is not a force" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git push -u origin my-branch"}}
J
_allowed 19 "--force-with-lease is not --force" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git push --force-with-lease origin feature/hook-fix"}}
J
_allowed 20 "in main:release the destination is release" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git push origin main:release"}}
J
_allowed 21 "git add -p stages by patch" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git add -p"}}
J
_allowed 22 "named paths are named paths" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git add src/hook.py tests/test_hook.py"}}
J
_allowed 23 "./src is a directory, not a bare dot" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git add ./src"}}
J
_allowed 24 "-N is not -f" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git add -N src/new_module.py"}}
J
_allowed 25 "a plain fetch names no remote-tracking ref" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git fetch origin"}}
J
_allowed 28 "git remote -v and show change no remote" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git remote -v && git remote show origin"}}
J
_allowed 29 "ls and cat only read the marker" <<'J'
{"tool_name":"Bash","tool_input":{"command":"ls -la .felix && cat .felix"}}
J
_allowed 30 "test, grep and diff only read the marker" <<'J'
{"tool_name":"Bash","tool_input":{"command":"test -f .felix && grep felix .felix && diff -u .felix .felix.orig"}}
J
_allowed 31 "sed -i on another file, with the marker in its script, edits that file" <<'J'
{"tool_name":"Bash","tool_input":{"command":"sed -i.bak 's/\\.felix-home/.felix/g' docs/setup.md"}}
J
_allowed 32 "truncate on debug.log, with the marker only in a comment" <<'J'
{"tool_name":"Bash","tool_input":{"command":"truncate -s 0 debug.log  # leaves .felix alone"}}
J
_allowed 33 "a timed read from a plain file" <<'J'
{"tool_name":"Bash","tool_input":{"command":"read -t 5 -r line < input.txt"}}
J
_allowed 34 "a read from a process substitution with no timeout" <<'J'
{"tool_name":"Bash","tool_input":{"command":"read -r head_sha < <(git rev-parse HEAD)"}}
J
_allowed 35 "a read -t line inside a quoted printf argument is text" <<'J'
{"tool_name":"Bash","tool_input":{"command":"printf '%s\\n' 'read -t 5 line < <(git status)' >> docs/pitfalls.md"}}
J
_allowed 36 "bash on another script is not the rival gate" <<'J'
{"tool_name":"Bash","tool_input":{"command":"bash scripts/other.sh"}}
J
_allowed 39 "a push whose force is named only in a trailing comment" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git push origin feature-branch  # don't git push -f here"}}
J
_allowed 40 "a force push on a comment line among plain commands" <<'J'
{"tool_name":"Bash","tool_input":{"command":"set -e\n# manual step, never automated: git push --force origin main\ngit status --short\ngit log --oneline -5"}}
J
_allowed 41 "a flag stored in a variable and echoed is text" <<'J'
{"tool_name":"Bash","tool_input":{"command":"MSG=\"git push -f\"; echo \"$MSG\""}}
J
_allowed 42 "a flag echoed into a file is text" <<'J'
{"tool_name":"Bash","tool_input":{"command":"echo 'git push -f' > note.txt"}}
J
_allowed 43 "an sh -c script that only echoes a quoted string" <<'J'
{"tool_name":"Bash","tool_input":{"command":"sh -c 'echo \"git add -A is banned\"'"}}
J
_allowed 44 "a shell fed a here-document that only echoes a quoted string and lists remotes" <<'J'
{"tool_name":"Bash","tool_input":{"command":"bash <<'EOF'\necho \"never run: git remote add evil https://example.com/x.git\"\ngit remote -v\nEOF"}}
J
_allowed 45 "a bash -c script built by printf that only echoes" <<'J'
{"tool_name":"Bash","tool_input":{"command":"bash -c \"$(printf '%s' 'echo git add -A')\""}}
J

# Two of those four were felix's refs/remotes row, which refused any mention
# of refs/remotes/ after update-ref or symbolic-ref, the value a command reads
# as much as the ref it writes. The row is narrowed in projects/felix/deny.tsv
# and asserted here against the rows that ship there, not a copy, so each
# verdict below is the table's. Three columns are kept: a fourth may scope a
# row to the governed checkout, and this fixture's repository sits in the
# temporary directory such a scope passes over.
_DRR="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/deny.tsv"
[ -f "$_DRR" ] && awk -F'\t' -v OFS='\t' '$1 == "Bash" && $2 ~ /refs\/remotes\// { print $1, $2, $3 }' \
  "$_DRR" > "$FROOT/projects/widget/deny.tsv"
_rr() {
  if [ -f "$_DRR" ]; then ( cd "$REPO" && _prb ); is "$2" "$?" "$1"
  else cat >/dev/null; skip "$2" "no projects/felix/deny.tsv beside this harness"; fi
}
_rr 0 "blind allow case 26: update-ref writes refs/heads/backup, and the remote-tracking ref is only the value it reads" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git update-ref refs/heads/backup refs/remotes/origin/main"}}
J
_rr 0 "blind allow case 27: symbolic-ref with one ref reads it and prints" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git symbolic-ref --short refs/remotes/origin/HEAD"}}
J
_rr 0 "the target of a redirect after that read is a file, not a second ref" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git symbolic-ref --short refs/remotes/origin/HEAD > head.txt"}}
J
_rr 0 "and so when its errors go to /dev/null: the 2 of 2>/dev/null is no second ref" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || echo main"}}
J
_rr 0 "a fetch from a plain remote moves the remote-tracking refs itself, and is allowed" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git fetch --prune origin"}}
J
_rr 2 "update-ref writing a remote-tracking ref is still refused" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git update-ref refs/remotes/origin/main HEAD"}}
J
_rr 2 "and so behind a global option and a quoted -m reason" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git -C \"$R\" update-ref -m \"reset to local\" refs/remotes/origin/main HEAD"}}
J
_rr 2 "and so when it deletes one, quoted and ended by a separator" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git update-ref -d \"refs/remotes/origin/main\"; git log -1"}}
J
_rr 2 "symbolic-ref with two refs writes the first, and a remote-tracking one is refused" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/trunk"}}
J
_rr 2 "pointing HEAD at a remote-tracking ref is refused, since the next commit would move it" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git symbolic-ref HEAD refs/remotes/origin/main"}}
J
_rr 2 "symbolic-ref --delete with one ref deletes it, and is refused" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git symbolic-ref --delete refs/remotes/origin/HEAD"}}
J
_rr 2 "a redirect between symbolic-ref's two refs does not hide the second" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null refs/remotes/origin/trunk"}}
J
_rr 2 "a fetch with a refspec into refs/remotes/ is still refused" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git fetch origin main:refs/remotes/origin/main"}}
J
_rr 2 "a push to refs/remotes/ is still refused" <<'J'
{"tool_name":"Bash","tool_input":{"command":"git push origin HEAD:refs/remotes/origin/main"}}
J
rm -f "$FROOT/projects/widget/deny.tsv" "$FROOT/.deny-err"

