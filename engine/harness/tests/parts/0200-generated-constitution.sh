printf '\ngenerated constitution\n'
_plain_build
_stranger_build
CDIR="$FROOT/projects/stranger"
[ -s "$CDIR/CLAUDE.md" ] && ok "onboarding writes one" || bad "onboarding writes one"
has "it names the verification command" "$(cat "$CDIR/CLAUDE.md")" "felix gate"
has "and what was detected"             "$(cat "$CDIR/CLAUDE.md")" "billing"
# The invariants are the part that cannot be generated, and the file says why
# rather than pretending or leaving a bare TODO.
has "invariants say where they come from" "$(cat "$CDIR/CLAUDE.md")" "earned rather"
case "$(cat "$CDIR/CLAUDE.md")" in
  *"Replace this"*) bad "no placeholder telling someone to write it" "still a stub" ;;
  *) ok "no placeholder telling someone to write it" ;;
esac

printf '\nlessons are mounted, not offered\n'
_lessons_build force

out="$(cd "$REPO" && "$FELIX" lessons --for "changing a migration" 2>&1)"
has "matches the relevant lesson"   "$out" "L-1"
case "$out" in *"L-2"*) bad "and not the irrelevant one" "$out" ;; *) ok "and not the irrelevant one" ;; esac
has "the always-applicable part is shown" "$out" "run the gate"

# The evidence is why a lesson is believed; the claim is what needs mounting.
# Injecting the evidence every turn is how a helpful injection becomes ignored.
case "$out" in
  *"Long evidence about"*) bad "only the claim is mounted, not the evidence" "$out" ;;
  *) ok "only the claim is mounted, not the evidence" ;;
esac

out="$(cd "$REPO" && "$FELIX" lessons --for "unrelated quantum teleportation" 2>&1)"
has "an unrelated context matches nothing" "$out" "nothing matched"

printf '\nthe prompt hook\n'
HK="$FROOT/harness/hooks/user-prompt"
out="$(cd "$REPO" && printf '{"prompt":"fix the migration rollback"}' | "$HK" 2>&1)"
case "$out" in
  *'"hookSpecificOutput"'*) ok "emits the documented UserPromptSubmit shape" ;;
  *) bad "emits the documented UserPromptSubmit shape" "$out" ;;
esac
ctx="$(printf '%s' "$out" | python3 -c 'import json,sys; print(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"])' 2>&1)"
has "carries the matched lesson" "$ctx" "L-1"
# Bounded. A hook that floods the turn is a hook people learn to skim past.
lines="$(printf '%s\n' "$ctx" | wc -l | tr -d ' ')"
[ "$lines" -le 20 ] && ok "and stays small" \
                    || bad "and stays small" "$lines lines is too much for every turn"

out="$(cd "$PLAIN" && printf '{"prompt":"anything"}' | "$HK" 2>&1)"; rc=$?
is "silent in an ungoverned repo" "${#out}" "0"
is "and exits 0 there"            "$rc" "0"

mv "$MEM/widget/lessons.md" "$TMP/lessons.bak"
out="$(cd "$REPO" && printf '{"prompt":"fix the migration"}' | "$HK" 2>&1)"
is "silent when a project has no lessons yet" "${#out}" "0"
mv "$TMP/lessons.bak" "$MEM/widget/lessons.md"

printf '\npipefail safety\n'
# Regression. Every presence check used to be `producer | grep -q x`, which under
# `set -o pipefail` reports 141 because grep exits on match and the producer takes
# SIGPIPE. The check then says absent about something present, and it is
# timing-dependent, so small producers pass and a real repository fails.
big="$(seq 1 200000)"
# Deliberately not asserting that `producer | grep -q x` fails on the match
# these helpers look for, near the end. It fails only when the producer is still
# writing when grep exits, so with a late match the assertion is a race and
# flakes. The reason the helpers exist is recorded above instead.
if ( set -uo pipefail
     . "$FROOT/harness/lib/resolve.sh"
     felix_contains "$big" "199999" ); then
  ok "felix_contains survives a large haystack under pipefail"
else
  bad "felix_contains survives a large haystack under pipefail"
fi
if ( set -uo pipefail
     . "$FROOT/harness/lib/resolve.sh"
     felix_has_line "$big" "199999" ) ; then
  ok "felix_has_line matches whole lines under pipefail"
else
  bad "felix_has_line matches whole lines under pipefail"
fi
if ( set -uo pipefail
     . "$FROOT/harness/lib/resolve.sh"
     felix_has_line "alpha
beta" "alph" ); then
  bad "felix_has_line rejects partial lines" "matched a prefix"
else
  ok "felix_has_line rejects partial lines"
fi
# Twenty-one of the suite's own checks had the shape the helpers replaced,
# `printf '%s\n' "$out" | grep -Fq x`, and one failed on main at a1bf2c7d, its
# log reading `printf: write error: Broken pipe`, once #310 lengthened the
# output it read. Each printf that fed such a chain now hands the chain's first
# stage a here-string, which bash has written in full before that stage starts,
# so grep's exit breaks no printf. Seven chains still pipe that first stage's
# output into a later grep -q, and that writer is safe for another reason, at
# the sizes these reports have: it prints a few filtered lines, which stdio
# holds until the stage has read all its input and then writes in one piece.
# A match on the first line of a megabyte takes the race out of the pipe form:
# grep exits after its first read, so the writer can have handed over only
# that read and one pipe's capacity, a small part of 1.3 MB. The first check
# pins that failure, which is what gives the second its meaning: on a haystack
# small enough for the pipe form to pass, the here-string passing would prove
# nothing. Neither reads the suite, so the third does: it goes red on any
# check here that pipes printf or echo of a variable into a chain ending in
# grep -q, which is how the sweep stays swept. It passes over comments, and
# over the first check's own pipe, which is there to break. It reads a line at
# a time, so a chain continued onto a second line is not seen; none is today.
if ( set -o pipefail; printf '%s\n' "$big" | grep -Fxq 1 ) 2>/dev/null; then
  bad "under pipefail, printf piped into grep -q fails when grep matches the first line of a megabyte" \
      "the pipe form passed, so this haystack cannot show that the here-string form is immune"
else
  ok  "under pipefail, printf piped into grep -q fails when grep matches the first line of a megabyte"
fi
if ( set -o pipefail; grep -Fxq 1 <<<"$big" ); then
  ok  "and a here-string into grep -q passes on the same megabyte"
else
  bad "and a here-string into grep -q passes on the same megabyte"
fi
_pfre="(printf '%s(\\\\n)?'|echo) \"[\$][^\"]*\" [|] ([^|]*[|] )*grep [^|]*-[a-zA-Z]*q"
_pfsites="$(_suite_src | grep -nE "$_pfre" | grep -vE -e '^[0-9]+:[[:space:]]*#' -e '"[$]big" [|] grep -Fxq 1 [)]')"
is "no check in this suite pipes printf or echo of a variable into a chain ending in grep -q" "$_pfsites" ""

printf '\nno fixture git write follows a raw cd on a variable or a raw git -C on a variable\n'
# On 2026-10-08 a fixture's `( cd "$_fs_wr" && git remote set-url ... )` ran with
# the variable empty, bash 3.2 stayed in the directory the suite was started in,
# and the config every worktree of felix-home shares came back with origin
# pointing at acme/widget. The preamble's _fx_cd and _fx_git are the fix: they
# refuse a directory they cannot prove is under $TMP. A fixture written the old
# way is still one empty variable from the same thing, so the lint reads this
# file and goes red on any site: a raw cd on a variable with a git write after
# it in the same group, or a raw git -C on a variable with a write for
# subcommand. No site is allow-listed except the three probes in the fixture
# floor's _ff_case, set aside below, and that function's whole text is pinned
# by its cksum. One whose directory is legitimately
# outside $TMP is a defect, not an exception: it is read through a subcommand
# the lint knows for a read, or it is not a fixture. The file read is the
# suite under test as one file, _suite_flat's $REAL_HARNESS/tests/run with each
# part in place of the line that sources it, which in a full run is this one and
# in a section runner is the tree that runner was pointed at. A file the lint
# cannot read is a failure too, since it exits 2 then and prints nothing else.
#
# The lint covers those two shapes and no more. A raw `( cd "$X" && "$FELIX"
# ... )` with X empty is not a site, and this branch does not convert it: on
# main alone the engine's own felix_repo_root then walks from the cwd to the
# checkout the run started in. That class rests on the fixture floor
# (claude/suite-fixture-floor), which lands first: the suite stands in
# $TMP/cwd, and _fixture_enclosed refuses a $TMP inside a checkout. The review
# measured the class contained on a trial merge of the two. The origin guard
# still reports a remote that class moves, as it reports any.
#
# One function holds sites on purpose, and they are the only ones set aside.
# The fixture floor's _ff_case repeats the incident's commands from where a
# fixture can end up after the floor: `cd "$e"` with e empty, `cd
# "$r/fixtures/$e"` and `cd "$r/fixtures/uninit"`. It asks git which repository
# a write would land in before running one, and writes only when the answer is
# under $TMP. Those three must stay raw cds, since an _fx_cd there would test
# _fx_cd and not the floor. So they are set aside by their exact text and only
# inside _ff_case's body, and a second assertion holds the set at exactly those
# three: the probe changing shape, or a fourth line like them, is red rather
# than quietly exempt (the merge of the two branches, 2026-10-08). The set-aside
# trusts the rest of _ff_case too: the which-repository check its git writes
# sit behind is what makes three raw cds safe there. So a third assertion pins
# _ff_case whole, from its `_ff_case() {` line through the `}` that ends it, by
# the CRC and byte count cksum prints. Any edit to it is red until a person has
# checked that every git write in it still sits behind that check, and then
# updates the pin. To recompute it, from engine/harness/tests:
#   awk '/^_ff_case\(\) \{/ { s = 1 } s { print } s && /^}$/ { exit }' parts/0005-fixture-floor.sh | cksum
_fxl_file="$(_suite_flat)"
_fxl_out="$(_fx_lint "$_fxl_file" 2>&1)"; _fxl_rc=$?
_fxl_ff="$(awk '/^_ff_case\(\) \{/ { s = NR } s && !e && NR > s && /^}$/ { e = NR } END { print s + 0, e + 0 }' "$_fxl_file" 2>/dev/null)"
_fxl_split() {   # 1 -> the sites not set aside; 0 -> the ones set aside
  printf '%s\n' "$_fxl_out" | awk -v want="$1" -v r="$_fxl_ff" '
    BEGIN { split(r, b, " ") }
    !NF { next }
    { n = $0; sub(/:.*/, "", n); t = $0; sub(/^[0-9]+:[ \t]*/, "", t)
      ex = (n + 0 > b[1] + 0 && n + 0 < b[2] + 0 &&
            (t ~ /^[a-z|]+\) +cd "\$e" ;;$/ || t ~ /^[a-z|]+\) +cd "\$r\/fixtures\/\$e" ;;$/ ||
             t ~ /^[a-z|]+\) +cd "\$r\/fixtures\/uninit" ;;$/))
      if ((ex ? 0 : 1) == want + 0) print }'
}
_fxl_rest="$(_fxl_split 1)"; _fxl_aside="$(_fxl_split 0)"
if { [ "$_fxl_rc" -eq 0 ] || [ "$_fxl_rc" -eq 1 ]; } && [ -z "$_fxl_rest" ]; then
  ok  "no fixture in this suite runs a git write from a raw cd or a raw git -C on a variable"
else
  bad "no fixture in this suite runs a git write from a raw cd or a raw git -C on a variable" \
      "the lint exited $_fxl_rc and printed: $(printf '%s' "$_fxl_rest" | head -5 | cut -c1-160 | tr '\n' '|')"
fi
is "the lint's only sites set aside are the fixture floor's three deliberate probes inside _ff_case" \
   "$(printf '%s\n' "$_fxl_aside" | grep -c ':')" "3"
_fxl_pin="1793434744 1884"   # _ff_case, reviewed 2026-10-08 (review round 2)
_fxl_ck="$(awk '/^_ff_case\(\) \{/ { s = 1 } s { print } s && /^}$/ { exit }' "$_fxl_file" 2>/dev/null | cksum | awk '{ print $1, $2 }')"
if [ "$_fxl_ck" = "$_fxl_pin" ]; then
  ok  "the fixture floor's _ff_case is the probe the lint's set-aside was reviewed against"
else
  bad "the fixture floor's _ff_case is the probe the lint's set-aside was reviewed against" \
      "its cksum is [$_fxl_ck], and the set-aside was reviewed against [$_fxl_pin]. Before updating the pin, check that every git write in _ff_case still sits behind its which-repository check, the one that asks where a write would land and writes only under \$TMP"
fi

printf '\nfixture git proof\n'
# On 2026-10-08 at 12:47:41 local time the config every worktree of the home
# checkout shares lost its origin. [remote "origin"] came back at the end of
# the file as https://github.com/acme/widget.git, packed-refs was rewritten in
# the same second, every refs/remotes/origin ref was gone, and every branch
# upstream went with them. A section runner had cut one block of this file
# without the helpers that set its fixture roots, so
# `( cd "$_fs_wr" && git remote remove origin ... )` ran with an empty name.
# Bash 3.2 takes `cd ""` as a success that stays put, and where it stayed was
# a worktree. `git -C ""` does the same: it runs in the cwd and exits 0.
#
# The change under test (contract C1 to C11, 2026-10-08-suite-git-proof) puts
# every fixture git write behind _fx_cd and _fx_git. They refuse any directory
# they cannot prove sits physically under $TMP, and they record each refusal in
# a file. It adds _fx_lint, which finds the raw shapes that did the damage. And
# it guards the end of every run, section runners included, by comparing the
# remotes of the checkout the run started in with a snapshot taken before $TMP
# existed.
#
# These assertions were written blind, from the contract alone. Three rules
# keep a broken implementation away from a real repository:
# - Every probe that could write starts INSIDE a stand-in checkout under $TMP,
#   so a guard that fails open damages the stand-in and the assertion sees it.
# - The probes run in subshells, because _fx_cd moves the shell that calls it.
# - The stand-ins are built, and their remotes moved, by scripts written below
#   and run as children. Those scripts shed the GIT_DIR family and check their
#   target's physical path themselves, so their own git writes never pass
#   through the code under test.
#
# Each probe hands _fx_cd a refusal record of its own in FELIX_TEST_FXREFUSED,
# so the refusals this block provokes on purpose never reach the record the end
# of the run judges. The last assertion here checks that they did not.
#
# Measured on bash 3.2.57 (2026-10-08): BASH_LINENO[0] inside a function and
# $LINENO on the line that called it agree inside ( ), inside a multi-line
# $( ) and at top level. So each probe prints $LINENO on its call's own line,
# and the record's line field is compared with that. Under `ulimit -S -u 1` a
# fork inside a subshell aborts that subshell at once, with status 128 and no
# retry, so a probe that forks prints nothing after the fork.
_gitproof_base

_gp_s="$(_gp_state "$_gp_home")"
# A control on this block's own fixture: it passes on any suite, main's
# included, and says whether everything below measures the code or the
# fixture.
if [ -n "$_gp_homep" ] && [ -d "$_gp_home/.git" ] && [ "$_gp_s" = "$(printf 'url %s\nrefs 1\nup origin' "$_gp_url")" ]; then
  ok  "fixture git proof: the stand-in checkout has an origin, an origin ref and a branch tracking origin"
else
  bad "fixture git proof: the stand-in checkout has an origin, an origin ref and a branch tracking origin" \
      "the stand-in at [$_gp_home] reads: $(printf '%s' "$_gp_s" | tr '\n' ' ')"
fi

# C1, C2, C11. The three functions exist in the suite's shell, and each is
# defined above the first section header, so a section runner cut at the
# line before that header carries them.
_gitproof_src
for _gp_f in _fx_cd _fx_git _fx_lint; do
  _gp_d="$(grep -nE "^(function[[:space:]]+)?${_gp_f}[[:space:]]*\(\)" "$_gp_src" 2>/dev/null | head -1 | cut -d: -f1)"
  if ! declare -F "$_gp_f" >/dev/null 2>&1; then
    bad "$_gp_f is defined in the suite's shell, above the first section header" "no function by that name in the suite's shell"
  elif [ -z "$_gp_d" ] || [ -z "$_gp_pre" ] || [ "$_gp_d" -ge "$_gp_pre" ]; then
    bad "$_gp_f is defined in the suite's shell, above the first section header" \
        "in $_gp_src it is defined at line [${_gp_d:-nowhere}] and the first section header is at line [${_gp_pre:-none}]"
  else
    ok  "$_gp_f is defined in the suite's shell, above the first section header"
  fi
done
is "the preamble names \$TMP/fx-refused as the refusal record" "${FELIX_TEST_FXREFUSED:-}" "$TMP/fx-refused"

# C1, refusals. Each case breaks exactly one of _fx_cd's conditions, so the
# reason is not a matter of which check comes first. The caller stands in the
# stand-in's sub directory and sends stdout and stderr to /dev/null; the
# record must arrive anyway, from a subshell, because it goes to a file.
_gp_n=0
_gp_refusal() {   # <what> <dir> <reason> [NAME=value exported before the call]
  local what="$1" dir="$2" why="$3" rec o rc line pwd
  _gp_n=$((_gp_n + 1)); rec="$_gp/rec.$_gp_n"; : > "$rec"
  o="$(cd "$_gp_home/sub" || exit 0
       [ -n "${4:-}" ] && export "$4"
       FELIX_TEST_FXREFUSED="$rec"
       _fx_cd "$dir" >/dev/null 2>&1; printf 'rc %s\nline %s\n' "$?" "$LINENO"
       printf 'pwd %s\n' "$(pwd -P)")"
  rc="$(_gp_get "$o" rc)"; line="$(_gp_get "$o" line)"; pwd="$(_gp_get "$o" pwd)"
  if ! declare -F _fx_cd >/dev/null 2>&1; then
    bad "_fx_cd refuses $what with a non-zero status, and its caller stays where it stood" "_fx_cd is not defined"
    bad "_fx_cd refusing $what appends one line: the call's line, the directory as given, and $why" "_fx_cd is not defined"
    return 0
  fi
  if [ -n "$rc" ] && [ "$rc" != 0 ] && [ -n "$_gp_homep" ] && [ "$pwd" = "$_gp_homep/sub" ]; then
    ok  "_fx_cd refuses $what with a non-zero status, and its caller stays where it stood"
  else
    bad "_fx_cd refuses $what with a non-zero status, and its caller stays where it stood" \
        "given [$dir] it returned [$rc] and its caller stood in [$pwd], not [$_gp_homep/sub]"
  fi
  is "_fx_cd refusing $what appends one line: the call's line, the directory as given, and $why" \
     "$(cat "$rec" 2>/dev/null)|$(wc -l < "$rec" | tr -d ' ')" "$(printf '%s\t%s\t%s' "$line" "$dir" "$why")|1"
}
_gp_refusal "an empty directory name"                         ""               empty
_gp_refusal "a name under \$TMP that does not exist"          "$_gp/missing"   not-a-directory
_gp_refusal "a regular file under \$TMP"                      "$_gp/afile"     not-a-directory
_gp_refusal "\$TMP itself"                                    "$TMP"           outside-tmp
_gp_refusal "a directory outside \$TMP"                       "/"              outside-tmp
_gp_refusal "a symlink under \$TMP that points outside it"    "$_gp/link-out"  outside-tmp
_gp_refusal "a directory under \$TMP while GIT_DIR is exported"        "$_gp/plain" git-env "GIT_DIR=$_gp_home/.git"
_gp_refusal "a directory under \$TMP while GIT_WORK_TREE is exported"  "$_gp/plain" git-env "GIT_WORK_TREE=$_gp_home"
_gp_refusal "a directory under \$TMP while GIT_COMMON_DIR is exported" "$_gp/plain" git-env "GIT_COMMON_DIR=$_gp_home/.git"

# The stderr line, and that a refusal leaves every variable its caller can
# see as it was. The variables are compared as `set` lists them in POSIX
# mode, less the ones bash itself changes from one command to the next.
_gp_o="$(cd "$_gp_home/sub" || exit 0; FELIX_TEST_FXREFUSED="$_gp/rec.err"
         _fx_cd "" 2>"$_gp/err.empty" >/dev/null; printf '%s' "$?")"
_gp_x="$(cat "$_gp/err.empty" 2>/dev/null)"
if ! declare -F _fx_cd >/dev/null 2>&1; then
  bad "_fx_cd refusing writes one line to stderr, beginning 'tests/run: _fx_cd refused '" "_fx_cd is not defined"
elif [ "$(wc -l < "$_gp/err.empty" | tr -d ' ')" = 1 ] && case "$_gp_x" in "tests/run: _fx_cd refused "*) true ;; *) false ;; esac; then
  ok  "_fx_cd refusing writes one line to stderr, beginning 'tests/run: _fx_cd refused '"
else
  bad "_fx_cd refusing writes one line to stderr, beginning 'tests/run: _fx_cd refused '" "it returned [$_gp_o] and wrote [$_gp_x]"
fi
_gp_vf() { grep -vE '^(BASH_ARGC|BASH_ARGV|BASH_LINENO|BASH_SOURCE|BASH_SUBSHELL|BASH_COMMAND|FUNCNAME|LINENO|PIPESTATUS|RANDOM|SECONDS|_)=' "$1"; }
_gp_o="$(cd "$_gp_home/sub" || exit 0; FELIX_TEST_FXREFUSED="$_gp/rec.vars"
         export GIT_CEILING_DIRECTORIES="/gp/prior"
         ( set -o posix; set ) > "$_gp/vars.before"
         _fx_cd "$_gp/missing" >/dev/null 2>&1
         ( set -o posix; set ) > "$_gp/vars.after"; printf 'compared')"
_gp_x="$(diff <(_gp_vf "$_gp/vars.before") <(_gp_vf "$_gp/vars.after") 2>&1)"
if ! declare -F _fx_cd >/dev/null 2>&1; then
  bad "_fx_cd refusing changes no variable its caller can see" "_fx_cd is not defined"
elif [ "$_gp_o" = compared ] && [ -s "$_gp/vars.before" ] && [ -z "$_gp_x" ]; then
  ok  "_fx_cd refusing changes no variable its caller can see"
else
  bad "_fx_cd refusing changes no variable its caller can see" "the probe said [$_gp_o]; set lists, before and after: $(printf '%s' "$_gp_x" | tr '\n' ' ')"
fi

# C1, success. The caller ends up in DIR physically, and a child process sees
# GIT_CEILING_DIRECTORIES with the physical $TMP first and whatever was there
# before after it. Whether git then finds nothing needs a repository at $TMP,
# which this suite's own $TMP must not become; a child run below makes one of
# its own.
_gp_ok() {   # <dir> <ceiling before, or - for unset>: key-a-line report of _fx_cd <dir> from inside the stand-in
  ( cd "$_gp_home/sub" || exit 0; FELIX_TEST_FXREFUSED="$_gp/rec.ok"
    if [ "$2" = - ]; then unset GIT_CEILING_DIRECTORIES; else export GIT_CEILING_DIRECTORIES="$2"; fi
    _fx_cd "$1" >/dev/null 2>&1; printf 'rc %s\n' "$?"
    printf 'pwd %s\nceiling %s\n' "$(pwd -P)" "$(command printenv GIT_CEILING_DIRECTORIES || printf '(unset)')" )
}
: > "$_gp/rec.ok"
_gp_plainp="$(_gp_phys "$_gp/plain")"
_gp_o="$(_gp_ok "$_gp/plain" -)"
is "_fx_cd on a directory under \$TMP returns 0 and stands its caller there, physically" \
   "$(_gp_get "$_gp_o" rc) $(_gp_get "$_gp_o" pwd)" "0 $_gp_plainp"
is "_fx_cd on a directory under \$TMP exports the physical \$TMP as GIT_CEILING_DIRECTORIES when none was set" \
   "$(_gp_get "$_gp_o" ceiling)" "$_gp_tmpp"
_gp_o="$(_gp_ok "$_gp/plain" "/gp/prior/one:/gp/prior/two")"
is "_fx_cd puts the physical \$TMP first in GIT_CEILING_DIRECTORIES and keeps what was there after it" \
   "$(_gp_get "$_gp_o" rc) $(_gp_get "$_gp_o" ceiling)" "0 $_gp_tmpp:/gp/prior/one:/gp/prior/two"
_gp_o="$(_gp_ok "$_gp/link-in" -)"
is "_fx_cd through a symlink under \$TMP that points inside it stands its caller in the target, physically" \
   "$(_gp_get "$_gp_o" rc) $(_gp_get "$_gp_o" pwd)" "0 $_gp_plainp"
if declare -F _fx_cd >/dev/null 2>&1 && [ ! -s "$_gp/rec.ok" ]; then
  ok  "_fx_cd records nothing when it succeeds"
else
  bad "_fx_cd records nothing when it succeeds" "defined: $(declare -F _fx_cd >/dev/null 2>&1 && echo yes || echo no); record: [$(tr '\t\n' '| ' < "$_gp/rec.ok")]"
fi

# C1 under fork pressure. `ulimit -S -u 1` in the probe's own subshell leaves
# it no fork at all, so an _fx_cd that forks on its success path dies there
# and prints no status. Everything after the ulimit is a builtin. Skipped as a
# probe when _fx_cd is missing, because bash forks to report a command not
# found and the probe would only measure that.
_gp_fp() {   # <dir>: key-a-line report of _fx_cd <dir> with no fork available
  ( cd "$_gp_home/sub" || exit 0; FELIX_TEST_FXREFUSED="$_gp/rec.fork"
    ulimit -S -u 1 2>/dev/null || { printf 'nolimit x\n'; exit 0; }
    _fx_cd "$1" >/dev/null 2>&1; printf 'rc %s\n' "$?"; printf 'pwd '; pwd -P
    printf 'ceiling %s\n' "${GIT_CEILING_DIRECTORIES:-}" ) 2>/dev/null
}
if ! declare -F _fx_cd >/dev/null 2>&1; then
  bad "_fx_cd succeeds with no fork available" "_fx_cd is not defined"
  bad "_fx_cd refuses a directory outside \$TMP with no fork available" "_fx_cd is not defined"
else
  _gp_o="$(_gp_fp "$_gp/plain")"
  if [ -n "$(_gp_get "$_gp_o" nolimit)" ]; then
    skip "_fx_cd succeeds with no fork available" "ulimit -S -u 1 was refused here"
  else
    is "_fx_cd succeeds with no fork available" \
       "$(_gp_get "$_gp_o" rc)|$(_gp_get "$_gp_o" pwd)|$(_gp_get "$_gp_o" ceiling | cut -d: -f1)" "0|$_gp_plainp|$_gp_tmpp"
  fi
  _gp_o="$(_gp_fp "/")"
  _gp_x="$(_gp_get "$_gp_o" rc)"
  if [ -n "$(_gp_get "$_gp_o" nolimit)" ]; then
    skip "_fx_cd refuses a directory outside \$TMP with no fork available" "ulimit -S -u 1 was refused here"
  elif [ -z "$_gp_x" ] || { [ "$_gp_x" != 0 ] && [ "$(_gp_get "$_gp_o" pwd)" = "$_gp_homep/sub" ]; }; then
    # No status at all means the subshell died at a fork: nothing after the
    # call ran, which is a refusal by the only measure that matters here.
    ok  "_fx_cd refuses a directory outside \$TMP with no fork available"
  else
    bad "_fx_cd refuses a directory outside \$TMP with no fork available" \
        "it returned [$_gp_x] and its caller stood in [$(_gp_get "$_gp_o" pwd)]"
  fi
fi

# C2. _fx_git stands in DIR for git and only for git, returns git's own
# status, and records a refusal with its own call's line.
_gp_o="$(cd "$_gp_home" || exit 0; FELIX_TEST_FXREFUSED="$_gp/rec.g1"
         export GIT_CEILING_DIRECTORIES="/gp/prior"
         _fx_git "$_gp_home/sub" rev-parse --show-prefix > "$_gp/g1.out" 2>/dev/null; printf 'rc %s\n' "$?"
         printf 'pwd %s\nceiling %s\n' "$(pwd -P)" "$(command printenv GIT_CEILING_DIRECTORIES)")"
is "_fx_git runs git standing in the directory it is given" "$(cat "$_gp/g1.out" 2>/dev/null)|$(_gp_get "$_gp_o" rc)" "sub/|0"
if declare -F _fx_git >/dev/null 2>&1 && [ "$(_gp_get "$_gp_o" rc)" = 0 ]; then
  is "_fx_git leaves its caller's directory and GIT_CEILING_DIRECTORIES as they were" \
     "$(_gp_get "$_gp_o" pwd)|$(_gp_get "$_gp_o" ceiling)" "$_gp_homep|/gp/prior"
else
  bad "_fx_git leaves its caller's directory and GIT_CEILING_DIRECTORIES as they were" \
      "_fx_git did not run git: it returned [$(_gp_get "$_gp_o" rc)]"
fi
: > "$_gp/rec.g2"
_gp_o="$(cd "$_gp_home/sub" || exit 0; FELIX_TEST_FXREFUSED="$_gp/rec.g2"
         _fx_git "$_gp_home" rev-parse -q --verify HEAD >/dev/null 2>&1; printf '%s ' "$?"
         _fx_git "$_gp_home" config --get gp.absent >/dev/null 2>&1; printf '%s ' "$?"
         _fx_git "$_gp_home" rev-parse --verify refs/heads/gp-absent >/dev/null 2>&1; printf '%s ' "$?"
         _fx_git "$_gp_home" config --gp-no-such-option >/dev/null 2>&1; printf '%s' "$?")"
is "_fx_git returns git's own status: 0, 1, 128 and 129 from four git commands that exit so" \
   "$_gp_o|$(cat "$_gp/rec.g2" 2>/dev/null)" "0 1 128 129|"
: > "$_gp/rec.g3"
_gp_o="$(cd "$_gp_home/sub" || exit 0; FELIX_TEST_FXREFUSED="$_gp/rec.g3"; _gp_e=""
         _fx_git "$_gp_e" rev-parse --show-toplevel > "$_gp/g3.out" 2>/dev/null; printf 'rc %s\nline %s\n' "$?" "$LINENO")"
if declare -F _fx_git >/dev/null 2>&1 && [ -n "$(_gp_get "$_gp_o" rc)" ] && [ "$(_gp_get "$_gp_o" rc)" != 0 ] && [ ! -s "$_gp/g3.out" ]; then
  ok  "_fx_git given an empty directory returns non-zero without running git"
else
  bad "_fx_git given an empty directory returns non-zero without running git" \
      "it returned [$(_gp_get "$_gp_o" rc)] and git printed [$(cat "$_gp/g3.out" 2>/dev/null)]"
fi
is "_fx_git refusing records the line of the _fx_git call, the directory as given, and empty" \
   "$(cat "$_gp/rec.g3" 2>/dev/null)" "$(printf '%s\t%s\t%s' "$(_gp_get "$_gp_o" line)" "" empty)"
# The incident's own three commands, through _fx_git, with an empty name, from
# inside a stand-in of their own: a guard that fails open runs them on it.
_gp_victim="$_gp/victim"; _gp_build "$_gp_victim"; : > "$_gp/rec.g4"
_gp_s0="$(_gp_state "$_gp_victim")"
_gp_o="$(cd "$_gp_victim" || exit 0; FELIX_TEST_FXREFUSED="$_gp/rec.g4"; _gp_e=""
         _fx_git "$_gp_e" remote remove origin >/dev/null 2>&1
         _fx_git "$_gp_e" remote add origin https://github.com/acme/widget.git >/dev/null 2>&1
         _fx_git "$_gp_e" config branch.main.remote gp-moved >/dev/null 2>&1; printf 'ran')"
if ! declare -F _fx_git >/dev/null 2>&1; then
  bad "the incident's commands through _fx_git with an empty directory leave the stand-in they started in as it was" "_fx_git is not defined"
elif [ "$_gp_s0" != "$(printf 'url %s\nrefs 1\nup origin' "$_gp_url")" ]; then
  bad "the incident's commands through _fx_git with an empty directory leave the stand-in they started in as it was" \
      "not exercised: the stand-in read [$(printf '%s' "$_gp_s0" | tr '\n' ' ')] before"
else
  is  "the incident's commands through _fx_git with an empty directory leave the stand-in they started in as it was" \
      "$(_gp_state "$_gp_victim")" "$_gp_s0"
fi
is "and each of the three is recorded with the reason empty" \
   "$(cut -f2- "$_gp/rec.g4" 2>/dev/null | tr '\t\n' '|;')" "|empty;|empty;|empty;"
# From the suite's own shell. _fx_git runs git in a subshell of its own, so it
# needs no ( ) around it, and it leaves the suite where it stood. Should it
# not, the suite is put back, so one broken guard does not move every
# assertion after this one.
_gp_c0="${GIT_CEILING_DIRECTORIES-(unset)}"
FELIX_TEST_FXREFUSED="$_gp/rec.top" _fx_git "$_gp_home" rev-parse --show-toplevel > "$_gp/top.out" 2>/dev/null; _gp_rc=$?
_gp_here="$(pwd -P)"; _gp_c1="${GIT_CEILING_DIRECTORIES-(unset)}"
[ "$_gp_here" = "$_gp_start" ] || cd -- "$_gp_start"
if [ "$_gp_c1" != "$_gp_c0" ]; then
  if [ "$_gp_c0" = "(unset)" ]; then unset GIT_CEILING_DIRECTORIES; else export GIT_CEILING_DIRECTORIES="$_gp_c0"; fi
fi
is "_fx_git called from the suite's own shell runs git in DIR and returns its status" \
   "$(cat "$_gp/top.out" 2>/dev/null)|$_gp_rc" "$_gp_homep|0"
if declare -F _fx_git >/dev/null 2>&1; then
  is "_fx_git called from the suite's own shell leaves it where it stood, with its GIT_CEILING_DIRECTORIES" \
     "$_gp_here|$_gp_c1" "$_gp_start|$_gp_c0"
else
  bad "_fx_git called from the suite's own shell leaves it where it stood, with its GIT_CEILING_DIRECTORIES" "_fx_git is not defined"
fi

# C3. _fx_lint over synthetic files. A line that should be reported holds a
# variable whose name starts S_, and no other line does, so the expected output
# is grep -n of those lines: N:text, in file order, nothing else. A line whose
# name starts N_ is one the lint must pass over.
mkdir -p "$_gp/lint"
# (i): a raw cd on a variable, then each kind of git write the contract names,
# global options before the subcommand included.
cat > "$_gp/lint/writes" <<'GPLINT'
( cd "$S_config" && git config user.name x )
( cd "$S_unset" && git config --unset user.name )
( cd "$S_cfgset" && git config set user.name x )
( cd "$S_radd" && git remote add origin https://example.invalid/x.git )
( cd "$S_rrm" && git remote remove origin )
( cd "$S_rseturl" && git remote set-url origin https://example.invalid/y.git )
( cd "$S_rrename" && git remote rename origin upstream )
( cd "$S_uref" && git update-ref refs/remotes/origin/main HEAD )
( cd "$S_bdel" && git branch -D old )
( cd "$S_bnew" && git branch topic )
( cd "$S_bmove" && git branch -m a b )
( cd "$S_bup" && git branch --set-upstream-to=origin/main )
( cd "$S_symset" && git symbolic-ref HEAD refs/heads/x )
( cd "$S_tag" && git tag v1 )
( cd "$S_tagd" && git tag -d v1 )
( cd "$S_stash" && git stash )
( cd "$S_stashdrop" && git stash drop )
( cd "$S_wtadd" && git worktree add ../w )
( cd "$S_notes" && git notes add -m x )
( cd "$S_fetch" && git fetch origin )
( cd "$S_init" && git init -q )
( cd "$S_commit" && git commit -qm x )
( cd "$S_unknown" && git frobnicate )
( cd "$S_globals" && git --no-pager -c a.b=c -P config k v )
( cd "$S_gitdirflag" && git --git-dir=.git config k v )
( cd "$S_clit" && git -C sub config k v )
GPLINT
# The read list, after the same raw cd: none is a site.
cat > "$_gp/lint/reads" <<'GPLINT'
( cd "$N_a" && git rev-parse --show-toplevel )
( cd "$N_a" && git log -1 --format=%H )
( cd "$N_a" && git show HEAD:x )
( cd "$N_a" && git diff --quiet )
( cd "$N_a" && git status --porcelain )
( cd "$N_a" && git ls-files -co )
( cd "$N_a" && git ls-tree HEAD )
( cd "$N_a" && git ls-remote origin )
( cd "$N_a" && git cat-file -t HEAD )
( cd "$N_a" && git for-each-ref refs/remotes )
( cd "$N_a" && git rev-list --count HEAD )
( cd "$N_a" && git show-ref --verify refs/heads/main )
( cd "$N_a" && git merge-base HEAD main )
( cd "$N_a" && git describe --always )
( cd "$N_a" && git grep -n x )
( cd "$N_a" && git blame x )
( cd "$N_a" && git version )
( cd "$N_a" && git check-ignore -q x )
( cd "$N_a" && git diff-tree --no-commit-id -r HEAD )
( cd "$N_a" && git config --get remote.origin.url )
( cd "$N_a" && git config --get-all remote.origin.fetch )
( cd "$N_a" && git config --get-regexp '^remote' )
( cd "$N_a" && git config --list )
( cd "$N_a" && git config -l )
( cd "$N_a" && git config get remote.origin.url )
( cd "$N_a" && git config list )
( cd "$N_a" && git remote )
( cd "$N_a" && git remote -v )
( cd "$N_a" && git remote get-url origin )
( cd "$N_a" && git remote show origin )
( cd "$N_a" && git branch )
( cd "$N_a" && git branch -a )
( cd "$N_a" && git branch -vv )
( cd "$N_a" && git branch --show-current )
( cd "$N_a" && git branch --format='%(refname)' )
( cd "$N_a" && git symbolic-ref HEAD )
( cd "$N_a" && git symbolic-ref -q --short HEAD )
( cd "$N_a" && git tag )
( cd "$N_a" && git tag -l )
( cd "$N_a" && git tag --list )
( cd "$N_a" && git stash list )
( cd "$N_a" && git stash show )
( cd "$N_a" && git worktree list )
( cd "$N_a" && git notes list )
( cd "$N_a" && git --no-pager -c a.b=c log -1 )
( cd "$N_a" && git -C sub rev-parse --git-dir )
( cd "$N_a" && git config --get k && git log -1 )
GPLINT
# Shapes that are not sites: a literal operand, the two helpers, git out of
# command position, a group that closed before the git, and a top-level cd
# whose group is the rest of its own line.
cat > "$_gp/lint/others" <<'GPLINT'
( cd /literal/path && git remote add o https://example.invalid/x.git )
( cd sub && git config k v )
( _fx_cd "$N_fx" && git config k v )
_fx_cd "$N_fx" && git remote add o https://example.invalid/x.git
_fx_git "$N_fx" remote add o https://example.invalid/x.git
( cd "$N_echo" && echo git config k v )
( cd "$N_printf" && printf '%s\n' "git remote add o u" )
echo cd "$N_word" && git config k v
( mycd "$N_fn" && git config k v )
git -C /literal remote add o https://example.invalid/x.git
git -C sub config k v
git -C "$N_read" log -1
git -C "$N_read" config --get-regexp '^remote[.]'
command git -C "$N_read" status
git -C "$N_read" -c a.b=c status
_fx_git "$N_fx" config k v
( cd "$N_close" && echo hi )
git remote add o https://example.invalid/x.git
cd "$N_line" && echo hi
git config k v
GPLINT
# (i) across command groups: continuation lines, multi-line ( ) and $( )
# groups, a case pattern's ")", keywords, braces, every operand form the
# contract calls parameter-led, and -P, -L and -- before the operand.
cat > "$_gp/lint/groups" <<'GPLINT'
( cd "$S_cont" \
    && git remote set-url origin https://example.invalid/x.git )
cd "$S_and" &&
  git config k v
cd "$S_or" ||
  git config k v
( cd "$S_multi"
  echo first
  git remote add o https://example.invalid/x.git
)
y="$(cd "$S_dollar"
     git config k v)"
( cd "$S_case"
  case "$m" in
    a|b)
      git remote add o https://example.invalid/x.git ;;
  esac
)
if cd "$S_if"; then git config k v; fi
if false; then :; else cd "$S_else" && git config k v; fi
while read -r l; do cd "$S_do" && git branch -D "$l"; done < /dev/null
{ cd "$S_brace" && git tag v1; }
( cd "$S_semi"; git config k v )
(cd "$S_tight" && git config k v)
! cd "$S_bang" || git config k v
out="$(cd "$S_dq" && git config k v)"
v="$(
  cd "$S_nested" && git config k v
)"
( cd "$S_once" && git config a b && git config c d )
( cd "${S_braced}" && git config k v )
( cd "$S_sub/x" && git config k v )
( cd $S_bare && git config k v )
( cd "$(printf '%s' "$S_cmdsub")" && git config k v )
( cd -P "$S_dashp" && git config k v )
( cd -L "$S_dashl" && git config k v )
( cd -- "$S_dashdash" && git config k v )
( cd "$S_cmd" && command git remote add o https://example.invalid/x.git )
GPLINT
# Text the lint does not read as code, and code right after it.
cat > "$_gp/lint/text" <<'GPLINT'
# ( cd "$N_c1" && git remote add o https://example.invalid/x.git )
echo hi # cd "$N_c2" && git config k v
   # cd "$N_c3" && git config k v
echo '( cd "$N_q1" && git remote add o https://example.invalid/x.git )'
echo "( cd $N_q2 && git config k v )"
msg='spans
( cd "$N_q3" && git remote add o https://example.invalid/x.git )
lines'
msg2="spans
( cd $N_q4 && git config k v )
end"
cat > /dev/null <<EOF
( cd "$N_h1" && git remote add o https://example.invalid/x.git )
EOF
cat > /dev/null <<'EOF'
( cd "$N_h2" && git config k v )
EOF
cat > /dev/null <<"END"
( cd "$N_h3" && git config k v )
END
GPLINT
printf 'cat > /dev/null <<-EOF\n\t( cd "$N_h4" && git config k v )\n\tEOF\n' >> "$_gp/lint/text"
cat >> "$_gp/lint/text" <<'GPLINT'
( cd "$S_after_heredoc" && git config k v )
cat > /dev/null <<EOF; ( cd "$S_on_heredoc_line" && git config k v )
( cd "$N_h5" && git config k v )
EOF
grep -q x <<<"$N_hs"
( cd "$S_after_herestring" && git config k v )
x=a#b; ( cd "$S_hash_in_word" && git config k v )
echo "a # not a comment"; ( cd "$S_after_dq_hash" && git config k v )
echo 'it''s'; ( cd "$S_after_sq" && git config k v )
GPLINT
# (ii): a raw git -C on a variable with a write, command git included.
cat > "$_gp/lint/dashc" <<'GPLINT'
git -C "$S_c1" remote add o https://example.invalid/x.git
git -C "${S_c2}" config k v
git -C "$S_c3/sub" update-ref refs/x HEAD
git -C $S_c4 config k v
git --no-pager -C "$S_c5" branch -D old
git -c a.b=c -C "$S_c6" config k v
command git -C "$S_c7" remote add o https://example.invalid/x.git
x="$(git -C "$S_c8" config k v)"
if git -C "$S_c9" config k v; then :; fi
git -C "$N_c10" rev-parse HEAD
command git -C "$N_c11" config --get k
echo git -C "$N_c12" config k v
GPLINT
_gp_lint_is "_fx_lint reports a raw cd on a variable before every kind of git write, one N:text line each, and exits 1" "$_gp/lint/writes" 1
_gp_lint_is "_fx_lint passes over a raw cd on a variable before every git read, and exits 0" "$_gp/lint/reads" 0
_gp_lint_is "_fx_lint passes over literal operands, _fx_cd, _fx_git, git out of command position, and closed groups" "$_gp/lint/others" 0
_gp_lint_is "_fx_lint follows a cd's command group across continuations, ( ) and \$( ) groups and a case pattern's )" "$_gp/lint/groups" 1
_gp_lint_is "_fx_lint skips comments, quoted text and heredoc bodies, and reads the code after them and after a here-string" "$_gp/lint/text" 1
_gp_lint_is "_fx_lint reports a raw git -C on a variable with a write, command git included, and not a read" "$_gp/lint/dashc" 1
# A file the lint cannot read never reads as clean.
_gp_lint2() {   # <name> <files...>: exit 2 with a message on stderr
  local n="$1" o rc; shift
  if ! declare -F _fx_lint >/dev/null 2>&1; then bad "$n" "_fx_lint is not defined"; return 0; fi
  o="$(_fx_lint "$@" 2>"$_gp/lint.err")"; rc=$?
  if [ "$rc" = 2 ] && [ -s "$_gp/lint.err" ]; then ok "$n"
  else bad "$n" "it exited [$rc], printed [$o] and said on stderr [$(cat "$_gp/lint.err")]"; fi
}
_gp_lint2 "_fx_lint exits 2 with a message on stderr for a file that does not exist" "$_gp/lint/absent"
_gp_lint2 "_fx_lint exits 2 for a missing file named after a clean one" "$_gp/lint/reads" "$_gp/lint/absent"
cp "$_gp/lint/reads" "$_gp/lint/locked"; chmod 000 "$_gp/lint/locked"
if [ -r "$_gp/lint/locked" ]; then
  skip "_fx_lint exits 2 with a message on stderr for a file it may not read" "this user reads a mode-000 file"
else
  _gp_lint2 "_fx_lint exits 2 with a message on stderr for a file it may not read" "$_gp/lint/locked"
fi
chmod 644 "$_gp/lint/locked"

# C5 to C9, through child runs. Each child is this suite's preamble, cut at the
# line before its first section header as a section runner is, with
# REAL_HARNESS set right after the preamble's own line to a copy of the harness
# under test. Then comes a body written here, and, for some children, the
# lines from the header of C5 and C8 to the line before the completion marker,
# then a tail that prints FAIL and exits 0. A child without that cut is a
# section runner, and only the EXIT trap stands between it and a green exit.
#
# Each child starts INSIDE a stand-in, or in a directory under $TMP that is in
# no checkout. Its harness copy sits outside any checkout unless the case
# says otherwise, so the remotes it watches are the stand-in's and nothing
# else's. The children that move a stand-in's remote do it through _gpk_git,
# which names the stand-in's git dir outright and first checks that the
# stand-in sits physically under this suite's $TMP. Only the stand-in a child
# is handed can be touched, whatever the child's code does.
#
# C7 compares mtimes with `test -nt`, which resolves to whole seconds, so a
# child that moves a remote sleeps a second first. The move then lands in a
# later second than the snapshot.
_gitproof_kids
_gp_o="$(GP_H="$_gp_hdr" GP_M="$_gp_mark" GP_P="printf '\\n" awk 'BEGIN { h = ENVIRON["GP_H"]; m = ENVIRON["GP_M"]; p = ENVIRON["GP_P"] }
  $0 == h { n++; if (!s) s = NR; next }
  s && !e && $0 == m { e = NR; next }
  s && !e && index($0, p) == 1 { x++ }
  END { printf "%d %d", n, (e > s ? 0 : 1) + x }' "$_gp_src" 2>/dev/null)"
is "the suite has C5 and C8's header once, and nothing shaped like a header between it and the completion marker" "$_gp_o" "1 0"

# C8 skips, C5 passes, and the trap stays quiet, in a run that started in no
# checkout and whose harness is in none.
_gp_kid none 1 <<'GPKID'
ok "gp child: an assertion in a run that started in no checkout"
true
GPKID
_gp_run none "$_gp_none"
_gp_x="$(grep -F -- "  skip  $_gp_c8 (" "$_gp/kid/none/out" 2>/dev/null)"
if _gp_has none "  ok    $_gp_c5" && case "$_gp_x" in *checkout*) true ;; *) false ;; esac \
   && [ "$(_gp_rc none)" = 0 ] && [ "$(_gp_err none 'tests/run:')" = 0 ]; then
  ok  "a run that started in no checkout skips the origin check, saying so, and exits 0"
else
  bad "a run that started in no checkout skips the origin check, saying so, and exits 0" \
      "status [$(_gp_rc none)]; it printed: $(grep -E '^  (ok|FAIL|skip)  ' "$_gp/kid/none/out" | tail -3 | tr '\n' ' ')stderr: $(head -3 "$_gp/kid/none/err" | tr '\n' ' ')"
fi

# Unchanged remotes: C5 and C8 pass, and the run exits 0. Under fork pressure
# the guard's per-assertion check costs no fork. That half alone would pass on
# a suite with no guard at all, so it counts only where the moved-remote child
# below shows the guard is there.
_gitproof_kid_same
if _gp_has same "  ok    $_gp_c5" && _gp_has same "  ok    $_gp_c8" && [ "$(_gp_rc same)" = 0 ] && [ "$(_gp_err same 'tests/run:')" = 0 ]; then
  ok  "a run whose remotes did not move passes the refusal and origin checks and exits 0"
else
  bad "a run whose remotes did not move passes the refusal and origin checks and exits 0" \
      "status [$(_gp_rc same)]; C5 and C8 said: $(grep -F -e "$_gp_c5" -e "$_gp_c8" "$_gp/kid/same/out" | tr '\n' ' ')stderr: $(head -3 "$_gp/kid/same/err" | tr '\n' ' ')"
fi
# A section-runner child, no C5 or C8 of its own: the trap checks, finds
# nothing wrong, says nothing and keeps 0. A control: a suite with no guard
# passes it too.
_gp_kid samerun 0 <<'GPKID'
ok "gp child: an assertion in a section runner whose remotes stay put"
true
GPKID
_gp_run samerun "$_gp_same/sub" "$_gp_same"
if [ "$(_gp_rc samerun)" = 0 ] && [ "$(_gp_err samerun 'tests/run:')" = 0 ] && _gp_gone samerun; then
  ok  "a section runner whose remotes did not move exits 0, its trap silent, its temporary directory removed"
else
  bad "a section runner whose remotes did not move exits 0, its trap silent, its temporary directory removed" \
      "status [$(_gp_rc samerun)]; stderr: $(head -3 "$_gp/kid/samerun/err" | tr '\n' ' ')"
fi

