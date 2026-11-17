printf '\ndenial refuses what a command changes, not what it reads\n'
# The tables that ship, not a copy of a row. Every projects/*/deny.tsv beside
# this harness is put in front of the real hook in turn, so the red run, which
# checks the base out whole, runs these lines against the rows the base holds.
# Until 2026-09-23 three rows refused commands that change nothing: a grep
# -rln over the marker, whose ln was taken for a link; the read the engine
# resolves its home with, whose 2>/dev/null was taken for a write of the
# pointer; a dry run of git add; a listing of a script. Each was reproduced
# with argv-logging shims and a hash of the files, and most are in the
# refusals the hooks logged.
#
# The first column says which way: 0, the command is allowed; 2, refused.
# The second set keeps the first honest. A narrowed row that refused nothing
# would pass every line of the first, so each real write the old rows refused
# is asserted still refused, a line for each verb they name, and a line for a
# write on a later line of the command: a row reads the payload's JSON, where
# a line break is a backslash and an n, and the first draft of these rows let
# every such write through.
#
# The second column says which tables a line is about. A 0 line holds for
# every table (-). A 2 line holds for every table with a Bash row whose
# pattern contains that text, and skips when there is none, because a table
# only ever refuses what it has a row about: the public snapshot ships one
# project's table, and a line about another's rows has nothing to ask there.
# An exit that is neither 0 nor 2, or a table that could not be put in place,
# is named in the failure and never read as either answer.
#
# A refused line writes into no directory under /tmp. The marker rows and
# the git add row carry deny.tsv's `checkout` scope, which passes over a
# command whose every target is a throwaway fixture under /tmp or $TMPDIR,
# so a refusal asserted about such a path would assert what that scope
# lifts. These lines are about how far a row's pattern reaches, and a path
# under $HOME keeps them about that whatever the scope decides. `mv .felix
# /tmp/x` stays: it moves this checkout's own marker, which no scope lifts.
_dtabs=""
for _dt in "$REAL_HARNESS"/../../projects/*/deny.tsv; do
  [ -f "$_dt" ] && _dtabs="$_dtabs$_dt
"
done
_dkeyed() {
  local t
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    [ "$1" = "-" ] \
      || awk -F'\t' -v k="$1" '$1 == "Bash" && index($2, k) { f = 1 } END { exit !f }' "$t" \
      || continue
    printf '%s\n' "$t"
  done <<EOF
$_dtabs
EOF
}
# Every table on stdin whose exit through the hook is not the one wanted, as
# " project:exit".
_dmiss() {
  local want="$1" cmd="$2" t rc out=""
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    if cp "$t" "$FROOT/projects/widget/deny.tsv"; then
      ( cd "$REPO" && _pre "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$cmd\"}}" ); rc=$?
    else
      rc=nocopy
    fi
    t="${t%/deny.tsv}"
    [ "$rc" = "$want" ] || out="$out ${t##*/}:$rc"
  done
  printf '%s' "$out"
}
while IFS=$'\t' read -r _dw _dk _dn _dc; do
  case "$_dw" in 0|2) ;; *) continue ;; esac
  _dks="$(_dkeyed "$_dk")"
  if [ -z "$_dks" ]; then
    if [ "$_dk" = "-" ]; then skip "$_dn" "no projects/*/deny.tsv beside this harness"
    else skip "$_dn" "no table beside this harness has a Bash row about $_dk"; fi
    continue
  fi
  is "$_dn" "$(printf '%s\n' "$_dks" | _dmiss "$_dw" "$_dc")" ""
done <<'J'
0	-	no shipped table refuses grep -rln over the marker, whose ln is a flag	grep -rln '\\.felix' engine/harness
0	-	nor grep -ln over the pointer	grep -ln '\\.felix-home' engine/harness/lib/resolve.sh
0	-	nor the read the engine resolves its home with, whose 2>/dev/null writes no pointer	tr -d '[:space:]' 2>/dev/null < \"$HOME/.felix-home\"
0	-	nor a > inside a quoted log format	git log --format='%h>%s' -- .felix
0	-	nor cp reading the marker into a backup	cp .felix /tmp/backup
0	-	nor a find whose 2>/dev/null comes before its -name .felix	find . -maxdepth 2 2>/dev/null -name .felix
0	-	nor an ls whose 2>/dev/null comes before the pointer it lists	ls -la 2>/dev/null ~/.felix-home
0	-	nor tee copying the marker it reads on stdin	tee /tmp/copy < .felix
0	-	nor dd reading the marker	dd of=/tmp/x if=.felix
0	-	nor git add -n -A, which stages nothing	git add -n -A
0	-	nor git add -A --dry-run	git add -A --dry-run
0	-	nor listing scripts/gate.sh, which runs nothing	ls -la ./scripts/gate.sh
0	-	nor a backslash-n typed into quoted text before the script's path, which is no line break	printf 'run:\\n./scripts/gate.sh\\n' > /tmp/notes
0	-	nor a grep for its subshell spelling	grep -rn '(./scripts/gate.sh)' docs
0	-	nor a brace expansion that names it	ls -la {./scripts/gate.sh,./scripts/x.sh}
2	felix(-home)	a table with a row about the marker still refuses printf x > .felix	printf x > .felix
2	felix(-home)	and a redirect to a quoted marker path	printf 'p\\n' > \"$T/repo/.felix\"
2	felix(-home)	and to one quoted in part	printf x > \"$HOME\"/.felix-home
2	felix(-home)	and to one quoted round a blank	printf x > \"$HOME/a b/.felix\"
2	felix(-home)	and an append to the marker	echo p >> .felix
2	felix(-home)	and a clobbering redirect, which the old row let through	printf x >| .felix
2	felix(-home)	and a redirect on a later line of the command	cd ~/r\nprintf x > .felix
2	felix(-home)	and tee onto the marker	tee .felix
2	felix(-home)	and cp onto the marker	cp x .felix
2	felix(-home)	and cp onto one quoted round a blank	cp seed \"$HOME/a b/.felix\"
2	felix(-home)	and cp onto the marker with its errors sent away	cp x .felix 2>/dev/null
2	felix(-home)	and cp of a marker into the current directory, where it lands as one	cp ../other/.felix .
2	felix(-home)	and cp of a marker into a directory named with its slash	cp /x/.felix \"$T/repo/\"
2	felix(-home)	and cp onto the marker on a later line of the command	cd ~/r\ncp x .felix
2	felix(-home)	and scp onto the marker	scp host:seed .felix
2	felix(-home)	and ln -s onto the marker	ln -s x .felix
2	felix(-home)	and install onto the marker	install -m 644 seed .felix
2	felix(-home)	and mv onto the pointer	mv x \"$HOME/.felix-home\"
2	felix(-home)	and mv of the marker away	mv .felix /tmp/x
2	felix(-home)	and rm of the marker	rm -f .felix
2	felix(-home)	and rm of the marker on a later line of the command	cd ~/r\nrm -f .felix
2	felix(-home)	and rm of the marker on a tab-indented later line	cd ~/r\n\trm -f .felix
2	felix(-home)	and a write with another line after it, which the old row let through	cp x .felix\necho ok
2	felix(-home)	and a redirect with another line after it, which the old row let through	printf x > .felix\nls
2	felix(-home)	and cp onto the marker before a comment	cp x .felix # seed
2	felix(-home)	and truncate of the pointer	truncate -s 0 \"$HOME/.felix-home\"
2	felix(-home)	and sed -i on the marker	sed -i s/a/b/ .felix
2	felix(-home)	and dd of= the marker	dd of=.felix
2	felix(-home)	and dd with its of= after another operand, which the old row let through	dd if=/dev/zero of=.felix
2	git add	a table with a row about git add still refuses git add -A	git add -A
2	git add	and git add --all	git add --all
2	git add	and git add .	git add .
2	git add	and git add -A behind another flag	git add -v -A
2	git add	and git add -A before an &&	git add -A && git commit -m wip
2	git add	and git add -A on a later line of the command	cd ~/r\ngit add -A
2	git add	and git add -A with another line after it, which the old row let through	git add -A\ngit commit -m wip
2	scripts/gate	a table with a row about scripts/gate.sh still refuses running it	./scripts/gate.sh --quick
2	scripts/gate	and running it after a cd	cd ~/x && ./scripts/gate.sh
2	scripts/gate	and running it under bash	bash ./scripts/gate.sh
2	scripts/gate	and running it on a later line, inside an if	if true; then\n  ./scripts/gate.sh\nfi
2	scripts/gate	and running it after a line continuation	cd ~/x && \\\n  ./scripts/gate.sh
2	scripts/gate	and running it in a brace group	{ ./scripts/gate.sh; }
2	scripts/gate	and running it in a command substitution	x=$( ./scripts/gate.sh )
2	scripts/gate	and running it on a tab-indented later line, which the old row let through	cd ~/x\n\t./scripts/gate.sh
J
rm -f "$FROOT/projects/widget/deny.tsv" "$FROOT/.deny-err"

# The wiring itself, read off the file that ships rather than the fixture copy.
# Correct code behind a matcher that never fires is this project's oldest and
# most expensive failure mode.
HOOKS_JSON="$(cd "$REAL_HARNESS/.." && pwd)/hooks/hooks.json"
mj="$(sed -n '/"PreToolUse"/,/]/p' "$HOOKS_JSON" | sed -n 's/.*"matcher"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
for t in Bash Edit Write Read NotebookEdit; do
  case "$mj" in *"$t"*) ok "PreToolUse is bound for $t" ;; *) bad "PreToolUse is bound for $t" "matcher is [$mj]" ;; esac
done

printf '\ndenial scoped to the checkout\n'
# Most deny rows protect the governed checkout — its binding, its remote, its
# remote-tracking refs, its index — and a regex over the command text cannot
# tell which repository a command acts on. Of the 175 refusals the hooks had
# logged by 2026-09-23, more than a hundred were real commands run in fixtures
# under the session scratchpad: binding a scratch repository, giving a fresh
# `git init` a remote, moving a scratch clone's refs, staging a fixture. A row
# may now say `checkout` in a fourth column, and lib/where.sh decides where a
# matched command acts. The first block of cases below was written from the
# contract alone, by an author who never saw lib/where-read.sh or lib/where.sh.
SC="$TMP/scoped"; GOV="$SC/gov"; GWT="$SC/gov-wt"; SCR="$SC/scr"; SC_ERR="$TMP/.scoped-err"
mkdir -p "$GOV" "$SCR/plain"
( _fx_cd "$GOV" && git init -q -b main && printf 'widget\n' > .felix && printf 'readme\n' > README \
  && git add .felix README && git -c user.name=t -c user.email=t@t commit -qm init \
  && git remote add origin https://example.com/widget.git && git worktree add -q -b wt "$GWT" ) >/dev/null 2>&1
git clone -q "$GOV" "$SCR/clone" >/dev/null 2>&1
GOV="$(cd "$GOV" && pwd -P)"; GWT="$(cd "$GWT" 2>/dev/null && pwd -P)"; SCR="$(cd "$SCR" && pwd -P)"
ln -s "$GOV" "$SCR/to-gov"; ln -s "$GOV/.felix" "$SCR/marker"; ln -s "$SCR/plain" "$GOV/out"
# A fixture that silently lacks its worktree or clone turns every refusal
# below into a vacuous pass.
if [ -f "$GWT/.git" ] && [ -d "$SCR/clone/.git" ] && [ -L "$SCR/to-gov" ]; then
  ok "the scoped fixture has its worktree, its clone and its links"
else
  bad "the scoped fixture has its worktree, its clone and its links" "worktree [$GWT] clone [$SCR/clone]"
fi
# And one outside the temporary root lib/where.sh reads, $TMPDIR, turns every
# lift below into a refusal for where the suite put its files. The root is a
# bare `mktemp -d`, which on a Mac lands in the per-user directory whatever
# TMPDIR says, so any other TMPDIR does that. Every tests/red run on a Mac
# did, until red stopped moving TMPDIR (tests/red says why).
_sc_tr="$(cd -P "${TMPDIR:-/tmp}" 2>/dev/null && pwd -P)"
if [ -n "$_sc_tr" ] && case "$SCR/" in "${_sc_tr%/}/"*) true ;; *) false ;; esac; then
  ok "the scoped fixture lies under the TMPDIR the suite was given"
else
  bad "the scoped fixture lies under the TMPDIR the suite was given" "fixture [$SCR] TMPDIR [${TMPDIR:-}]"
fi
{ printf 'Bash\t(>|tee|cp |mv |rm |ln |truncate|sed -i|install |dd of=)[^;&|]*["\047]?\\.felix(-home)?["\047]?([[:space:];&|)]|$)\tmarker\tcheckout\n'
  printf 'Bash\tgit( +-[^ ]+( +[^ ]+)?)* +(update-ref|symbolic-ref|fetch|push)[^;&|]*refs/remotes/\ttracking\tcheckout\n'
  printf 'Bash\tgit( +-[^ ]+( +[^ ]+)?)* +remote +(add|set-url|rename|remove|rm)( |$)\tremote\tcheckout\n'
  printf 'Bash\tgit add ([^;&|]* )?(-A|--all|\\.)( |$)\tstage\tcheckout\n'
  printf 'Bash\tgit push ([^;&|]* )?(--force|-f)( |$)\tforcepush\n'
  printf 'Bash\t(^|[;&| ])npm publish\tpublish\tbogus\n'
  printf 'Write\t(^|/)\\.felix(-home)?$\tmarkerwrite\tcheckout\n'
  printf 'Edit\t(^|/)\\.felix(-home)?$\tmarkeredit\n'
} > "$FROOT/projects/widget/deny.tsv"
is "the scoped table reads as eight rows with their scopes" \
   "$( . "$FROOT/harness/lib/deny.sh"; _felix_deny_rows "$FROOT/projects/widget" | awk -F'\t' '{print $4}' | tr '\n' ,)" \
   "checkout,checkout,checkout,checkout,,bogus,checkout,,"

# A payload, JSON-escaped the way Claude Code sends it.
_jstr() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e "s/$(printf '\t')/\\\\t/g" \
            | awk 'NR > 1 { printf "\\n" } { printf "%s", $0 }'; }
_scpay() {
  local c=""; [ "$1" = - ] || c="\"cwd\":\"$(_jstr "$1")\","
  printf '{"session_id":"scoped",%s"tool_name":"%s","tool_input":{"%s":"%s"}}' "$c" "$2" "$3" "$(_jstr "$4")"
}
_sc()  { local rc; ( cd "$GOV" && _scpay "$3" Bash command "$4" | "$FROOT/harness/hooks/pre-tool" 2>"$SC_ERR" ); rc=$?; is "$2" "$rc" "$1"; }
_scr() {
  local rc; ( cd "$GOV" && _scpay "$3" Bash command "$4" | "$FROOT/harness/hooks/pre-tool" 2>"$SC_ERR" ); rc=$?
  if [ "$rc" = 2 ] && grep -q "^$1" "$SC_ERR"; then ok "$2"; else bad "$2" "rc $rc: $(head -c 400 "$SC_ERR")"; fi
}
_scp() { local rc; ( cd "$GOV" && _scpay "$5" "$3" file_path "$4" | "$FROOT/harness/hooks/pre-tool" 2>"$SC_ERR" ); rc=$?; is "$2" "$rc" "$1"; }

# ---- blind: written from the contract alone ----
# --- lifts: fixtures under a scratch variable, and git in the scratch clone
_sc 0 "scoped: a fixture repo under a scratch variable, marker then git add -A" - "S=$SCR; D=\$S/repro_\$\$; mkdir -p \"\$D/repo\" && cd \"\$D/repo\" && git init -q && printf 'w\\n' > .felix && git add -A && git commit -qm init"
_sc 0 "scoped: mktemp -d, then cd into it" - 'D=$(mktemp -d); cd "$D" && git init -q && echo w > .felix'
_sc 0 "scoped: mktemp -d with a scratch template, then remote add by git -C" - "S=$SCR; D=\$(mktemp -d \"\$S/fx.XXXX\"); git -C \"\$D\" init -q; git -C \"\$D\" remote add origin https://example.com/x.git"
_sc 0 "scoped: a fresh name under the physical /tmp" - 'D=/tmp/felix-blind-$RANDOM; mkdir -p $D && cd $D && git init -q && echo w > .felix'
_sc 0 "scoped: a sibling whose name extends the checkout's is not the checkout" - "mkdir -p $TMP/scoped/gov2 && cd $TMP/scoped/gov2 && git init -q && git add -A && git commit -qm x"
_sc 0 "scoped: under set -e a lone cd on its own line is final" - "set -e"$'\n'"mkdir -p $SCR/nx-sete"$'\n'"cd $SCR/nx-sete"$'\n''git init -q . && git add -A && git commit -qm base'
_sc 0 "scoped: pwd -P of the scratch clone, then update-ref under refs/remotes" - "R=\$(cd \"$SCR/clone\" && pwd -P); git -C \"\$R\" update-ref refs/remotes/origin/main HEAD"
_sc 0 "scoped: a fetch from the governed checkout into the scratch clone" - "git -C \"$SCR/clone\" fetch -q \"$GOV\" main:refs/remotes/gov/main"
_sc 0 "scoped: repeated -C, each relative to the last" - "git -C \"$SCR\" -C clone remote add up https://example.com/up.git"
_sc 0 "scoped: a commit message quoting the marker redirect, in the clone" "$SCR/clone" "git commit -qm 'guard: > .felix is refused'"
# --- lifts: where the command starts, how cd moves it, nested shells
_sc 0 "scoped: a payload cwd already in scratch" "$SCR/plain" 'echo w > .felix'
_sc 0 "scoped: P from pwd keeps the scratch cwd after a cd" "$SCR/plain" "P=\$(pwd); cd $SCR/clone && echo w > \$P/.felix"
_sc 0 "scoped: .. out of the checkout that lands in scratch" "$SCR/clone" "echo w > $GOV/../scr/plain/.felix"
_sc 0 "scoped: a cd first in its chain to an existing directory, then ;" - "cd $SCR/plain; echo w > .felix; true"
_sc 0 "scoped: cd DIR || exit cannot fall back" - "mkdir -p $SCR/nx-exit; cd $SCR/nx-exit || exit; echo w > .felix; true"
_sc 0 "scoped: every branch of an if leaves scratch" - "if test -d $SCR/plain; then cd $SCR/plain; else cd $SCR/clone; fi; echo w > .felix; true"
_sc 0 "scoped: a for loop over literal words feeding an assignment" - "for v in new old; do R=$SCR/e2e/\$v/repo; mkdir -p \$R; git -C \$R init -q -b main && git -C \$R remote add origin https://example.com/widget.git; done"
_sc 0 "scoped: bash -c starts in the directory it was called from" - "cd $SCR/plain && bash -c 'echo w > .felix; true'"
_sc 0 "scoped: a here-document fed to bash sees a prefixed variable" - "T=\"$SCR\" bash <<'EOF'"$'\n''cd "$T/clone" && git fetch -q origin main:refs/remotes/origin/main'$'\n''EOF'
# --- lifts: other writers, and the path tools
_sc 0 "scoped: dd of= with an input path after = in scratch" "$SCR/plain" "dd of=.felix if=$SCR/clone/README"
_scp 0 "scoped: Write to a scratch marker lifts" Write "$SCR/plain/.felix" -
_scp 0 "scoped: Write to a relative marker under a scratch payload cwd" Write ".felix" "$SCR/plain"
# --- refusals: the governed checkout by every route, home, and outside the temp roots
_scr marker "scoped: no cd means the checkout" - 'echo w > .felix'
_scr stage "scoped: a payload cwd that does not exist falls back to the checkout" "$SCR/nx-cwd" 'git add -A && git commit -qm x'
_scr stage "scoped: cd back to the checkout" - "cd $SCR/clone && git add -A && cd $GOV && git add -A && git commit -qm x"
_scr tracking "scoped: git -C the checkout from a scratch cwd" "$SCR/plain" "git -C $GOV fetch -q $SCR/clone main:refs/remotes/c/main"
_scr stage "scoped: .. climbing out of scratch into the checkout" "$SCR/plain" 'cd ../../gov && git add -A && git commit -qm x'
_scr stage "scoped: cd through a symlink to the checkout" - "cd $SCR/to-gov && git add -A && git commit -qm x"
_sc 2 "scoped: tee through a symlink to a file" "$SCR/plain" "echo w | tee $SCR/marker .felix"
_scr stage "scoped: another worktree of the same repository" - "cd $GWT && git add -A && git commit -qm x"
_scr tracking "scoped: a GIT_DIR prefix naming the checkout" "$SCR/clone" "GIT_DIR=$GOV/.git git fetch -q origin main:refs/remotes/origin/main"
_scr stage "scoped: a new repository nested inside the checkout" - "mkdir -p $GOV/sub/fx && cd $GOV/sub/fx && git init -q && git add -A && git commit -qm x"
_scr marker "scoped: every matched command is judged" "$SCR/plain" "echo w > .felix; echo w > $GOV/.felix"
_scr marker "scoped: cp from the checkout into scratch counts the source" "$SCR/plain" "cp $GOV/.felix .felix"
_scr marker "scoped: ~/.felix-home from a scratch cwd" "$SCR/plain" 'echo w > ~/.felix-home'
_scr stage "scoped: cd ~" - 'cd ~ && git add -A && git commit -qm x'
_scr stage "scoped: a directory outside every temp root" - 'cd /felix-where-nowhere && git add -A && git commit -qm x'
# --- refusals: the directory or a path cannot be told, or a cd may not have happened
_scr marker "scoped: cd to an unknown variable" "$SCR/plain" 'cd "$FIXTURE" && echo w > .felix'
_scr marker "scoped: a redirect through a variable the line never assigned" "$SCR/plain" 'echo w > $OUT/.felix'
_scr marker "scoped: pushd, even between two scratch directories" "$SCR/clone" "pushd $SCR/plain && echo w > .felix"
_scr marker "scoped: after source" "$SCR/plain" 'source ./env.sh; echo w > .felix'
_scr marker "scoped: calling a function whose body cds" "$SCR/clone" "f() { cd $SCR/plain; }; f; echo w > .felix"
_scr marker "scoped: a glob in the path" "$SCR/plain" 'rm -f */.felix'
_scr marker "scoped: a brace expansion in the path" "$SCR/plain" "echo w | tee $SCR/{plain,clone}/.felix"
_scr marker "scoped: .. after a directory that does not exist yet" "$SCR/plain" 'echo w > nothere/../.felix'
_scr marker "scoped: a command substitution the reader does not know" "$SCR/plain" "D=\$(git -C $SCR/clone rev-parse --show-toplevel); echo w > \$D/.felix"
_scr marker "scoped: a subshell's cd does not leak" - "( cd $SCR/plain ); echo w > .felix; true"
_scr marker "scoped: an if with no else may leave the checkout" - "if test -d $SCR/plain; then cd $SCR/plain; fi; echo w > .felix; true"
# Amended after it was written: mkdir -p is taken to succeed when the disk says it can,
# so the cd cannot fall back; the counterparts below, where it cannot, refuse.
_sc 0 "scoped: mkdir; cd; cmd judges the directory before too" - "mkdir -p $SCR/nx-semi; cd $SCR/nx-semi; echo w > .felix; true"
# Amended after it was written: mkdir -p is taken to succeed when the disk says it can,
# so the cd cannot fall back; the counterparts below, where it cannot, refuse.
_sc 0 "scoped: a cd second in its chain can fail even to an existing directory" - "mkdir -p $SCR/plain && cd $SCR/plain; echo w > .felix; true"
# Amended after it was written: mkdir -p is taken to succeed when the disk says it can,
# so the cd cannot fall back; the counterparts below, where it cannot, refuse.
_sc 0 "scoped: under set -e a cd inside a chain can still fall through" - "set -e; mkdir -p $SCR/nx-chain; cd $SCR/nx-chain && git init -q; git add -A && git commit -qm x"
# Amended after it was written: mkdir -p is taken to succeed when the disk says it can,
# so the cd cannot fall back; the counterparts below, where it cannot, refuse.
_sc 0 "scoped: set -u is not set -e" - "set -u"$'\n'"mkdir -p $SCR/nx-setu"$'\n'"cd $SCR/nx-setu"$'\n''git init -q . && git add -A && git commit -qm base'
# Amended after #301: a row that matches only across two commands, or only
# inside a quoted value, is no match at all once the command is read as code.
_sc 0 "scoped: a match spanning two commands" "$SCR/plain" $'echo w > log\ncat .felix'
_scr marker "scoped: an unterminated quote cannot be parsed" "$SCR/plain" 'echo w > .felix; echo "oops'
# --- refusals: code runners, git push and -c, aliasing anywhere in the line
_scr stage "scoped: bash -c from scratch whose script cds into the checkout" "$SCR/plain" "bash -c 'cd $GOV && git add -A && git commit -qm x'"
_scr tracking "scoped: an unexported variable does not reach a here-document shell" - "T=$SCR"$'\n'"bash <<'EOF'"$'\n''cd "$T/clone" && git fetch -q origin main:refs/remotes/origin/main'$'\n''EOF'
_scr marker "scoped: an interpreter writing the marker" "$SCR/plain" "python3 -c 'print(1)' > .felix"
_scr marker "scoped: the command word is an unknown variable" "$SCR/plain" '$WRITER w > .felix'
_scr tracking "scoped: git push into the scratch clone's refs/remotes" "$SCR/clone" 'git push -q origin HEAD:refs/remotes/origin/main'
_sc 2 "scoped: git -c alias" - "git -c alias.st=status -C $SCR/clone remote add up https://example.com/up.git"
# Amended after it was written: a link is judged, not refused: one that stays in
# scratch is throwaway, and one into the checkout still refuses below.
_sc 0 "scoped: ln anywhere in the line" "$SCR/plain" "ln -s $SCR/clone c2; echo w > .felix; true"
# Amended after it was written: a worktree is judged, not refused: one of the
# scratch clone made in scratch is throwaway, one of the checkout still refuses below.
_sc 0 "scoped: git worktree anywhere in the line" "$SCR/clone" 'git worktree add ../wt2 && cd ../wt2 && git add -A && git commit -qm x'
# --- A1: echo, printf and assignments are judged like any command
# Amended after it was written: a printing or file tool acts on its redirects and its
# arguments, not on the directory it runs in; a relative target in the checkout still refuses.
_sc 0 "scoped: an echo run from the checkout counts the checkout" - "echo w > $SCR/plain/.felix"
_scr marker "scoped: an echo argument naming the checkout" "$SCR/plain" "echo $GOV > .felix"
_sc 0 "scoped: a matched assignment in scratch with a scratch value" "$SCR/plain" "C='cp a .felix' D=$SCR/clone"
_sc 0 "scoped: a matched assignment whose value names the checkout" "$SCR/plain" "C='cp a .felix' D=$GOV"
# --- A2: an occurrence no lifted command carries keeps the refusal
_scr marker "scoped: a comment beside a lifted command keeps the refusal" "$SCR/plain" 'echo w > .felix # in the checkout: echo w > .felix'
_scr stage "scoped: here-document data beside a lifted command keeps the refusal" "$SCR/clone" "git add -A && git commit -q -F - <<'MSG'"$'\n'"never git add -A in the checkout"$'\n'"MSG"
# --- A3: an ancestor of the checkout is governed
_scr stage "scoped: cd .. from scratch reaches an ancestor of the checkout" "$SCR" 'cd .. && git add -A && git commit -qm x'
_sc 2 "scoped: git -C the temp directory that holds the checkout" "$SCR/plain" "git -C $TMP remote add up https://example.com/up.git"
# Amended after it was written: cp acts on its arguments, not on its directory; git
# run in a directory holding the checkout still refuses above.
_sc 0 "scoped: a working directory that holds the checkout" "$TMP/scoped" 'cp a scr/plain/.felix'
# --- A4: code the reader did not follow refuses the whole line
_scr stage "scoped: eval anywhere refuses the whole line" "$SCR/clone" "git add -A && git commit -qm x; eval \"\$NEXT_STEP\""
_scr stage "scoped: xargs anywhere refuses the whole line" "$SCR/clone" 'git add -A && git ls-files | xargs wc -l'
_scr marker "scoped: a shell reading a pipe refuses the whole line" "$SCR/plain" "echo w > .felix; echo 'cd $GOV' | bash"
_scr stage "scoped: bash -c with a script the reader cannot see" "$SCR/clone" 'git add -A && git commit -qm x && bash -c "$HOOK"'
_scr marker "scoped: a shell running a script this line wrote with printf" "$SCR/plain" "printf 'cd %s\\n' $GOV > run.sh; echo w > .felix; bash run.sh"
_sc 0 "scoped: a shell running a script this line wrote by here-document, all in scratch" "$SCR/plain" "cat > run.sh <<'EOF'"$'\n'"cd $SCR/clone && git add -A && git commit -qm x"$'\n'"EOF"$'\n''bash run.sh'
_scr marker "scoped: sourcing a file this line wrote, even after the match" "$SCR/plain" "echo w > .felix; printf 'X=1\\n' > env.sh; . ./env.sh"
_scr stage "scoped: a [[ ]] holding a command substitution" "$SCR/clone" '[[ -n $(git status --porcelain) ]] && git add -A && git commit -qm x'
# --- unchanged: unscoped rows, other rows, commands no row matches
_scr forcepush "scoped: the unscoped force-push row refuses in scratch" "$SCR/clone" 'git push -f origin main'
_sc 2 "scoped: an unknown scope value refuses in scratch" "$SCR/plain" 'npm publish --dry-run'
_scr forcepush "scoped: a lifted row does not stop another row" - "cd $SCR/clone && git add -A && git push -f origin main"
_scr stage "scoped: a lifted marker row does not lift the stage row" "$SCR/plain" "echo w > .felix && cd $GOV && git add -A && git commit -qm x"
_sc 0 "scoped: three scoped rows all lifted in one clone" - "cd $SCR/clone && git remote add up https://example.com/up.git && git fetch -q up main:refs/remotes/up/main && git add -A && git commit -qm x"
_sc 0 "scoped: an unmatched command naming the checkout is not judged" "$SCR/plain" "echo w > .felix; git -C $GOV status"
_sc 0 "scoped: commands no row matches stay allowed in the checkout" - 'git status && git log --oneline -1 && cat .felix'
_scp 2 "scoped: the unscoped Edit row refuses a scratch path" Edit "$SCR/plain/.felix" -
_scp 2 "scoped: Write through a symlink to the checkout" Write "$SCR/to-gov/.felix" -
_scp 2 "scoped: Write to the home pointer" Write "$HOME/.felix-home" -

# ---- written with the reader in view: the counterparts of the amended cases,
# shapes from the replayed refusals, and what a refusal says ----
# --- the counterparts: where a cd, a link or a worktree could still reach the checkout
_scr marker "scoped: mkdir -p under a file cannot succeed, so the cd may not move" - "mkdir -p $SCR/clone/README/x; cd $SCR/clone/README/x; echo w > .felix; true"
_scr marker "scoped: mkdir without -p can fail, so the cd after it may not move" - "mkdir $SCR/nx-nop; cd $SCR/nx-nop; echo w > .felix; true"
_scr marker "scoped: a test that can fail before the cd leaves the checkout possible" - "test -d $SCR/nx-none && cd $SCR/plain; echo w > .felix; true"
_scr marker "scoped: an rm between the mkdir and the cd" - "mkdir -p $SCR/nx-rm; rm -rf $SCR/nx-rm; cd $SCR/nx-rm; echo w > .felix; true"
_scr marker "scoped: mktemp in a directory that is not there" - "D=\$(mktemp -d \"$SCR/nx-none/fx.XXXX\"); cd \"\$D\" && echo w > .felix"
_scr marker "scoped: a link into the checkout, anywhere in the line" "$SCR/plain" "ln -s $GOV g; echo w > .felix; true"
_scr stage "scoped: a worktree of the governed checkout made in scratch" - "git worktree add -q $SCR/wt3 && cd $SCR/wt3 && git add -A && git commit -qm x"
_sc 0 "scoped: a worktree of the scratch clone, made in scratch" "$SCR/clone" 'git worktree add -q ../wt4 && cd ../wt4 && git add -A && git commit -qm x'
_scr marker "scoped: a printing tool writing a relative path from the checkout" - "printf 'w\\n' > .felix"
# --- shapes from the replayed refusals
_sc 0 "scoped: a fixture script written by here-document and run with arguments" - "S=$SCR/p1; mkdir -p \"\$S\"; cat > \"\$S/fx.sh\" <<'EOF'"$'\n''S="$1"'$'\n''R="$S/repo"; mkdir -p "$R"'$'\n'"( cd \"\$R\" && git init -q -b main && printf 'widget\\n' > .felix && git add -A )"$'\n''EOF'$'\n''bash "$S/fx.sh" "$S"'
_sc 0 "scoped: a shared clone moved by a script read from stdin" - "S=$SCR/p2; git clone -q --shared \"$GOV\" \"\$S/c\" && bash -s \"\$S/c\" <<'EOF'"$'\n''C="$1"; cd "$C" || exit 1'$'\n''git update-ref refs/remotes/origin/main HEAD'$'\n''EOF'
# Judged directly: #301 reads a here-document as data when the shell is given
# arguments, so through the hook this never reaches a scoped row.
is "scoped: the same script handed the governed checkout" \
   "$( cd "$GOV" && . "$FROOT/harness/lib/where.sh" && felix_where_lifts 'refs/remotes/' \
       "$(_jstr "bash -s \"$GOV\" <<'EOF'"$'\n''C="$1"; cd "$C" || exit 1'$'\n''git update-ref refs/remotes/origin/main HEAD'$'\n''EOF')" \
       "$GOV" "$GOV" && echo lifted || echo stood )" "stood"
_sc 0 "scoped: a single-quoted bash -c fixture given its directory" - "bash -c 'mkdir -p \"\$1/r\" && cd \"\$1/r\" && git init -q && git remote add origin https://example.com/x.git' sh $SCR/p3"
_sc 0 "scoped: mkdir -p, cd, then a remote on the lines after" - "W=$SCR/p4; mkdir -p \"\$W/repo\"; cd \"\$W/repo\"; git init -q"$'\n''git remote add origin https://nowhere.example/fx.git'
_sc 0 "scoped: a mktemp fixture read back through pwd -P" - 'T=$(mktemp -d); REPO="$T/repo"; mkdir -p "$REPO"; (cd "$REPO" && git init -q -b main); REPO="$(cd "$REPO" && pwd -P)"; (cd "$REPO" && git add -A && git commit -qm base)'
# --- what can change the meaning of a word the reader already knows. Each of
# these lifted before the reader was taught it, found by reading it against
# the shell rather than by a case.
_scr stage "scoped: a function named cd runs instead of the builtin" - "cd() { builtin cd $GOV; }; cd $SCR/plain && git add -A && git commit -qm x"
_scr stage "scoped: a function named git runs instead of git" - "git() { command git -C $GOV \"\$@\"; }; cd $SCR/clone && git add -A && git commit -qm x"
_sc 0 "scoped: builtin cd steps past a function of that name" - "cd() { :; }; builtin cd $SCR/clone && command git add -A && command git commit -qm x"
_scr stage "scoped: printf -v assigns the variable a later cd reads" - "x=$SCR/plain; printf -v x '%s' \"$GOV\"; cd \"\$x\" && git add -A && git commit -qm x"
_scr stage "scoped: an ANSI-C escape the reader does not decode" "$SCR/plain" "cd \$'..\\x2f..\\x2fgov' && git add -A && git commit -qm x"
_scr stage "scoped: a directory named as a command, which AUTO_CD would enter" "$SCR/plain" "$GOV; git add -A && git commit -qm x"
_scr stage "scoped: a DEBUG trap runs between the commands read" - "trap 'cd $GOV' DEBUG; cd $SCR/clone && git add -A && git commit -qm x"
_sc 0 "scoped: an EXIT trap with a known action does not" - "trap 'true' EXIT; cd $SCR/clone && git add -A && git commit -qm x"
_scr stage "scoped: CDPATH given to cd moves a relative cd" "$SCR/plain" "CDPATH=$SC cd gov && git add -A && git commit -qm x"
_scr stage "scoped: cd - goes where OLDPWD says" "$SCR/plain" "cd $SCR/clone; OLDPWD=$GOV; cd - && git add -A && git commit -qm x"
_scr stage "scoped: cd reads .. by spelling, through a link out of the checkout" "$SCR/plain" "cd $GOV/out/.. && git add -A && git commit -qm x"
( cd "$GOV" && printf '{"session_id":"scoped","cwd":"%s","tool_name":"Bash","tool_input":{"command":"cd \\u002f%s && git add -A"}}' \
    "$SCR/plain" "${GOV#/}" | "$FROOT/harness/hooks/pre-tool" 2>"$SC_ERR" ); rc=$?
is "scoped: a \\u escape in the payload is not read as its letters" "$rc" "2"
_long="cd $SCR/clone && git add -A && git commit -qm x$(printf ' %.0s' $(seq 1 33000))"
_scr stage "scoped: a command longer than the reader reads keeps the refusal" - "$_long"
has "and says it was too long to read" "$(cat "$SC_ERR")" "longer than this reads"
# --- a lift is written down, and a refusal is not written as one
_lifts() { awk -F'\t' '$2 == "lifted"' "$MEM/widget/says.log" 2>/dev/null; }
_sc 0 "scoped: a lift to be recorded" "$SCR/clone" 'git add -A && git commit -qm recorded-lift'
has "a lifted scoped row is written to says.log with the command" "$(_lifts | tail -1)" "recorded-lift"
_n="$(_lifts | wc -l | tr -d ' ')"
_scr stage "scoped: a refusal that must not be recorded as a lift" - 'git add -A && git commit -qm not-a-lift'
is "and a scoped row that stood writes no lift" "$(_lifts | wc -l | tr -d ' ')" "$_n"
# --- what a refusal of a scoped row says
( cd "$GOV" && _scpay - Bash command 'git add -A' | "$FROOT/harness/hooks/pre-tool" 2>"$SC_ERR" )
has "a scoped row that stands says it covers only the checkout" "$(cat "$SC_ERR")" "covers only the governed checkout"
has "and names the command and the place" "$(cat "$SC_ERR")" "\`git add -A\`: it acts on $GOV, in the governed checkout"
# --- it can only keep a refusal when it cannot tell
mkdir -p "$SC/nowhere"; cp "$FROOT/harness/lib/deny.sh" "$FROOT/harness/lib/deny-read.sh" "$SC/nowhere/"
is "without lib/where.sh beside it a scoped row stands" \
   "$( cd "$GOV" && . "$SC/nowhere/deny.sh" && felix_deny_match "$FROOT/projects/widget" Bash "cd $SCR/plain && git add -A" "$SCR/plain" >/dev/null && echo refused )" \
   "refused"
is "and with it, the same call lifts" \
   "$( cd "$GOV" && . "$FROOT/harness/lib/deny.sh" && felix_deny_match "$FROOT/projects/widget" Bash "cd $SCR/plain && git add -A" "$SCR/plain" >/dev/null && echo refused || echo lifted )" \
   "lifted"
is "a reader that cannot run lifts nothing" \
   "$( cd "$GOV" && . "$FROOT/harness/lib/where.sh" && _FELIX_WHERE_READ='this is not awk {' \
       && felix_where_lifts 'git add' "cd $SCR/plain && git add -A" "$SCR/plain" "$GOV" && echo lifted || echo stood )" \
   "stood"
is "the judge alone: a scratch path is throwaway" \
   "$( . "$FROOT/harness/lib/where.sh"; felix_where_path_lifts "$SCR/plain/.felix" "$SCR" "$GOV" && echo lifted || echo stood )" "lifted"
is "the judge alone: a worktree of the checkout is not" \
   "$( . "$FROOT/harness/lib/where.sh"; felix_where_path_lifts "$GWT/.felix" "$SCR" "$GOV" && echo lifted || echo stood )" "stood"
is "a TMPDIR of / is not a temporary root" \
   "$( . "$FROOT/harness/lib/where.sh"; TMPDIR=/; felix_where_path_lifts /usr/felix-where-nowhere "$SCR" "$GOV" && echo lifted || echo stood )" "stood"
is "a TMPDIR that holds \$HOME is not a temporary root" \
   "$( . "$FROOT/harness/lib/where.sh"; h="$(cd -P "$HOME/.." && pwd -P)"; TMPDIR="$h"
       felix_where_path_lifts "${h%/}/felix-where-nowhere/x" "$SCR" "$GOV" && echo lifted || echo stood )" "stood"
mkdir -p "$SCR/home"
( cd "$GOV" && _scpay "$SCR/plain" Bash command 'echo w > ~/.felix-home' | HOME="$SCR/home" "$FROOT/harness/hooks/pre-tool" 2>"$SC_ERR" ); rc=$?
is "a \$HOME under a temporary root still keeps its pointer" "$rc" "2"
# A reader that dies part-way has written only some of what it would have. The
# control beside it is the same reader reaching its end, which lifts, so the
# refusal is the missing end and nothing else.
cat > "$SC/stops.awk" <<'EOF'
BEGIN { printf "C\tp\t\tgit add -A\t\036%s\t0,9\n", CWD0; exit 0 }
EOF
cat > "$SC/ends.awk" <<'EOF'
BEGIN { printf "C\tp\t\tgit add -A\t\036%s\t0,9\nE\n", CWD0; exit 0 }
EOF
for _sa in stops ends; do
  _sv="$( cd "$GOV" && . "$FROOT/harness/lib/where.sh" && _FELIX_WHERE_READ="$(cat "$SC/$_sa.awk")" \
          && felix_where_lifts 'git add' 'git add -A' "$SCR/plain" "$GOV" && echo lifted || echo stood )"
  case "$_sa" in
    stops) is "a reader that stops before its end lifts nothing" "$_sv" "stood" ;;
    ends)  is "the same reader reaching its end would lift" "$_sv" "lifted" ;;
  esac
done
rm -f "$FROOT/projects/widget/deny.tsv" "$SC_ERR"

