printf '\nthe deployed surface is three directories\n'
# #82. The verification compared harness/ alone, and the cache serves
# harness/, hooks/ and commands/. hooks/hooks.json is the file that decides
# which hooks BIND — so a deploy that carried harness/ and dropped hooks/
# certified as `installed ok` while every session ran yesterday's bindings: a
# hook binary deployed perfectly and running nowhere, which is HANDOFF §8's
# family in the one place that claims to check deployment.
#
# Both sides get hooks/ first, matching, and the control runs before the
# tamper — a guard that refuses everything passes every tamper test.
_install_fixture_build after-0630
cp -R "$ICACHE/harness/." "$ISRC/engine/harness/"
mkdir -p "$ISRC/engine/hooks" "$ICACHE/hooks"
printf '{ "hooks": { "SessionStart": [] } }\n' > "$ISRC/engine/hooks/hooks.json"
printf '{ "hooks": { "SessionStart": [] } }\n' > "$ICACHE/hooks/hooks.json"
imatch_out="$(_inst_from_cache)"
has "matching hooks still verify" \
    "$imatch_out" "checked    the installed engine matches this tree"

# The tamper: harness byte-identical, hooks.json differing — the exact state
# the old comparison certified.
printf '{ "hooks": {} }\n' > "$ICACHE/hooks/hooks.json"
itamper_out="$(_inst_from_cache)"
case "$itamper_out" in
  *"checked    the installed engine matches this tree"*|*"verified   the installed engine matches this tree"*)
    bad "a hooks.json that never deployed is not certified" "$itamper_out" ;;
  *) ok "a hooks.json that never deployed is not certified" ;;
esac

# And the library says so on its own, both directions, so the fix cannot be a
# message change while the comparison stays narrow.
_ddiff() { ( . "$FROOT/harness/lib/resolve.sh"; felix_deploy_diff "$1" "$2" >/dev/null 2>&1 ); }
_ddiff "$ISRC/engine" "$ICACHE" && bad "felix_deploy_diff sees the hooks drift" "reported clean" \
                                || ok  "felix_deploy_diff sees the hooks drift"
printf '{ "hooks": { "SessionStart": [] } }\n' > "$ICACHE/hooks/hooks.json"
_ddiff "$ISRC/engine" "$ICACHE" && ok  "and is clean when the three directories agree" \
                                || bad "and is clean when the three directories agree" "reported drift"
# A directory absent from ONE side is a drift, not a skip — the skip-if-absent
# shape is how a check passes by finding nothing.
rm -rf "$ICACHE/hooks"
_ddiff "$ISRC/engine" "$ICACHE" && bad "a directory missing from one side is a drift" "reported clean" \
                                || ok  "a directory missing from one side is a drift"
rm -rf "$ISRC/engine/hooks"
_ddiff "$ISRC/engine" "$ICACHE" && ok  "and absent from both sides is a fixture, not a drift" \
                                || bad "and absent from both sides is a fixture, not a drift" "reported drift"

# A path the repository itself declares non-content is residue, not drift
# (#86). The stray that fired live: a claude-flow hook dropped state under
# tests/ while the suite ran there, and the installed check called a
# byte-identical deploy a drift — then, in a worktree, misdiagnosed it as
# structural with the one-line evidence suppressed. tests/ exists on both
# sides here because that is the real shape: the stray's parent deployed
# fine, only the residue differs.
RSD="$TMP/residue"
mkdir -p "$RSD/engine/harness/tests" "$RSD/cache/harness/tests"
( _fx_cd "$RSD" && git init -q -b main )
printf '.claude-flow/\n.DS_Store\n' > "$RSD/.gitignore"
printf 'real\n' > "$RSD/engine/harness/felix"
printf 'real\n' > "$RSD/cache/harness/felix"
printf 'suite\n' > "$RSD/engine/harness/tests/run"
printf 'suite\n' > "$RSD/cache/harness/tests/run"
_ddiff "$RSD/engine" "$RSD/cache" && ok  "identical deploys are clean before any stray lands" \
                                  || bad "identical deploys are clean before any stray lands" "reported drift"
mkdir -p "$RSD/engine/harness/tests/.claude-flow/data"
printf 'x\n' > "$RSD/engine/harness/tests/.claude-flow/data/insights.jsonl"
_ddiff "$RSD/engine" "$RSD/cache" && ok  "a gitignored stray in the tree is residue, not drift" \
                                  || bad "a gitignored stray in the tree is residue, not drift" "reported drift"
printf 'junk\n' > "$RSD/cache/harness/.DS_Store"
_ddiff "$RSD/engine" "$RSD/cache" && ok  "and a gitignored stray in the cache is too" \
                                  || bad "and a gitignored stray in the cache is too" "reported drift"
printf 'new\n' > "$RSD/engine/harness/undeployed.sh"
_ddiff "$RSD/engine" "$RSD/cache" && bad "an untracked file the repo does not ignore is still a drift" "reported clean" \
                                  || ok  "an untracked file the repo does not ignore is still a drift"
ddout="$( . "$FROOT/harness/lib/resolve.sh"
          felix_deploy_diff "$RSD/engine" "$RSD/cache" 2>&1 )"
has "the surviving drift is named" "$ddout" "undeployed.sh"
case "$ddout" in
  *claude-flow*|*DS_Store*) bad "and the residue is not" "$ddout" ;;
  *)                        ok  "and the residue is not" ;;
esac
rm -f "$RSD/engine/harness/undeployed.sh"
printf 'changed\n' > "$RSD/cache/harness/felix"
_ddiff "$RSD/engine" "$RSD/cache" && bad "a content difference is still a drift" "reported clean" \
                                  || ok  "a content difference is still a drift"
printf 'real\n' > "$RSD/cache/harness/felix"

# The review of the first fix found four holes in it, each by construction,
# and each is pinned here so a refactor cannot quietly reopen it.
#
# 1. A filename containing " and " used to truncate at the first " and ", so
#    check-ignore was answered about a fragment — and an ignore rule matching
#    the fragment certified REAL content drift as clean. `notes` is ignored;
#    `notes and helpers.sh` is not, and its drift must be reported in full.
printf 'notes\n.claude-flow/\n.DS_Store\n' > "$RSD/.gitignore"
printf 'v2\n' > "$RSD/engine/harness/notes and helpers.sh"
printf 'v1\n' > "$RSD/cache/harness/notes and helpers.sh"
ddout="$( . "$FROOT/harness/lib/resolve.sh"
          felix_deploy_diff "$RSD/engine" "$RSD/cache" 2>&1 )"; ddrc=$?
is  "a filename containing ' and ' cannot hide behind a fragment" "$ddrc" "1"
has "and the drift line carries the whole name" "$ddout" "notes and helpers.sh"
rm -f "$RSD/engine/harness/notes and helpers.sh" "$RSD/cache/harness/notes and helpers.sh"

# 2. A directory-only pattern — `.claude-flow/`, the incident's own rule —
#    matches only what git can see is a directory, and a cache-side stray
#    exists in no tree at all. Asked with the trailing slash, it filters.
mkdir -p "$RSD/cache/harness/tests/.claude-flow"
printf 'x\n' > "$RSD/cache/harness/tests/.claude-flow/state"
_ddiff "$RSD/engine" "$RSD/cache" && ok  "a cache-side stray matching a directory-only rule is residue" \
                                  || bad "a cache-side stray matching a directory-only rule is residue" "reported drift"
rm -rf "$RSD/cache/harness/tests/.claude-flow"

# 3. The rule is the repository's committed ignore file, not this machine's.
#    A core.excludesFile pointing anywhere — repo config counts, it is not
#    committed either — must not reclassify real undeployed work as residue.
printf 'undeployed.sh\n' > "$RSD/private-ignore"
_fx_git "$RSD" config core.excludesFile "$RSD/private-ignore"
printf 'new\n' > "$RSD/engine/harness/undeployed.sh"
_ddiff "$RSD/engine" "$RSD/cache" && bad "a personal excludes file cannot hide real drift" "reported clean" \
                                  || ok  "a personal excludes file cannot hide real drift"
_fx_git "$RSD" config --unset core.excludesFile
rm -f "$RSD/engine/harness/undeployed.sh"

# 4. Apple diff -rq EXITS 0 when a file faces a directory of the same name —
#    the old exit-code rc certified that real deploy break as clean on macOS.
#    The line-based rc reads the message instead, which no arm claims.
mkdir -p "$RSD/cache/harness/mixed"
printf 'file\n' > "$RSD/engine/harness/mixed"
_ddiff "$RSD/engine" "$RSD/cache" && bad "a file facing a directory is a drift, whatever diff exits" "reported clean" \
                                  || ok  "a file facing a directory is a drift, whatever diff exits"
rm -rf "$RSD/cache/harness/mixed" "$RSD/engine/harness/mixed"

# 5. A directory only the cache holds, with nothing in it but residue, is
#    residue: what git ignores is subtracted before the question is asked, so
#    a whole directory of it is empty. The gate's inline copy read the missing
#    diff operand as drift; when the gate was folded onto this function
#    (2026-09-17) it took this reading, which deploy-check had answered for
#    the same fact all along, and it is pinned here so the two cannot part
#    again in silence. A real file in that directory is still drift.
mkdir -p "$RSD/cache/commands/.claude-flow"
printf 'x\n' > "$RSD/cache/commands/.claude-flow/state"
_ddiff "$RSD/engine" "$RSD/cache" && ok  "a directory only the cache holds, with nothing in it but residue, is residue" \
                                  || bad "a directory only the cache holds, with nothing in it but residue, is residue" "reported drift"
printf 'real\n' > "$RSD/cache/commands/felix.md"
_ddiff "$RSD/engine" "$RSD/cache" && bad "and with a real file in it, it is drift" "reported clean" \
                                  || ok  "and with a real file in it, it is drift"
rm -rf "$RSD/cache/commands"

# The gate kept its own inline copy of this comparison until 2026-09-17, on the
# argument that a verifier which sources the code it judges can be switched off
# by editing that code, and four assertions here held the two copies in step by
# counting the copy's tokens. The fold answered the argument without the copy:
# the installed block sources felix_accepted_deploy_diff from the BASE REF's
# resolve.sh — `git show`, never this tree, never the cache entry — and asks
# it, so the code that judges is the code main accepted. The premise the four
# rested on is gone, and what is counted now is the new mechanism's tokens, the
# same way: the function is asked, it is read from the base, that copy is the
# only thing sourced, and the residue rule (#86) is the library's alone.
# Non-comment lines only.
_REALG2="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/gate.sh"
if [ -f "$_REALG2" ]; then
  _gate_inst="$(sed -n '/^# -.*installed/,/^# -.*tests/p' "$_REALG2" | grep -vE '^[[:space:]]*#')"
  case "$_gate_inst" in
    *'felix_accepted_deploy_diff "$ROOT"'*) ok "the gate's installed check asks the one reader, felix_accepted_deploy_diff" ;;
    *) bad "the gate's installed check asks the one reader, felix_accepted_deploy_diff" \
           "no call to felix_accepted_deploy_diff in the installed block" ;;
  esac
  case "$_gate_inst" in
    *'git show "$GBASE:engine/harness/lib/resolve.sh"'*) ok "and reads it from the base ref's resolve.sh" ;;
    *) bad "and reads it from the base ref's resolve.sh" "no git show of the base's resolve.sh" ;;
  esac
  # Every `. file` in the block — a dot, a space and then a path — and there
  # must be exactly the one, on the copy just read: a second source line is a
  # library from somewhere else. `grep .` is not a source statement.
  _gate_src="$(printf '%s\n' "$_gate_inst" | grep -E '(^|[[:space:]]|\()\. ["$/.~]' )"
  case "$(printf '%s\n' "$_gate_src" | grep -c .)|$_gate_src" in
    '1|'*'"$GLIB/resolve.sh"'*) ok "and that copy is the only library the block sources" ;;
    *) bad "and that copy is the only library the block sources" "source lines: $_gate_src" ;;
  esac
  case "$_gate_inst" in
    *check-ignore*) bad "and the residue rule is the library's alone" "check-ignore is still in the installed block" ;;
    *) ok "and the residue rule is the library's alone" ;;
  esac
  # Both failing branches print the differing paths. They were read back from a
  # fixed file every gate on the machine shared, and are held in GDRIFT now.
  is "the structural verdict shows its evidence too" \
     "$(grep -cF 'printf '"'"'%s\n'"'"' "$GDRIFT" | head -5' "$_REALG2")" "2"
else
  skip "the gate's installed check asks the one reader, felix_accepted_deploy_diff" "no shipped gate"
  skip "and reads it from the base ref's resolve.sh" "no shipped gate"
  skip "and that copy is the only library the block sources" "no shipped gate"
  skip "and the residue rule is the library's alone" "no shipped gate"
  skip "the structural verdict shows its evidence too" "no shipped gate"
fi

printf '\nindependence\n'
# #85, and mounting a second real project is what made it matter. The check
# grepped ONE hard-coded literal, `another governed project`, over three paths. Constitution
# invariant 1 is "The engine names no project" - the first invariant in the
# file - and what the check established was that seven particular letters were
# absent from three of the directories under engine/harness.
#
# Demonstrated against the real gate before this was written: an engine that
# hard-codes `a third governed project`, a project Felix actually governs, passes; the identical
# edit naming `another governed project` fails.
#
# The names are enumerated from projects/ so governing something new cannot
# quietly widen what the engine may say. The engine's OWN name is exempt and
# has to be: `felix` appears 1452 times in runtime code because it is the
# product, the function prefix and the binary, not a governed product being
# named. `bin/` is in the searched set because the gate EXECUTES it - the
# literal `another governed project` sitting in engine/harness/bin/secret-scan passed before.
#
# tests/ and templates/ stay out, deliberately. This suite names another governed project in
# its own comments on purpose, since explaining what it refuses to depend on is
# the point, and the widget fixture names itself 256 times.
#
# A project is a directory that DECLARES itself with a project.json, not one
# that happens to exist. The first version globbed bare directories, which gave
# an empty stray the same authority as a governed project - projects/widget is
# one - and disagreed with the gate, which used `ls -1 projects` and so counted
# plain files too. Two hand-rolled enumerators, already divergent, under an
# assertion that claimed they were in step.
runtime=("$FROOT/harness/felix" "$FROOT/harness/lib" "$FROOT/harness/hooks" "$FROOT/harness/bin")

# Armed before it is trusted. This is a negative assertion over a generated set,
# which is the shape that reports success whenever the set is empty - and the
# set is read off a directory, so "no projects found" and "no project leaked"
# arrived as the same pass.
#
# A checkout that governs ONLY the engine's own project is the third case, and
# it is what anybody who clones this repository has. There is no other name to
# search for, so the negative assertion below cannot be armed — and a `bad`
# there would tell a stranger their fresh clone is broken, while an `ok` would
# be the vacuous pass this comment is about. Both are wrong; the answer is
# that the check did not run, said out loud, which is what `skip` is for.
_govn="$(_gov_names | wc -l | tr -d ' ')"
if [ "${_govn:-0}" -gt 0 ]; then
  ok "there is at least one governed project to check for"
else
  skip "there is at least one governed project to check for" \
       "this checkout governs only the engine's own project, so there is no other name to look for"
fi

# ONE assertion, with the leaking names in the detail rather than in the name.
# Per name read better and was wrong: the name is the assertion's identity, and
# these names come from the developer's own projects/ directory, so the manifest
# recorded `(a third governed project)` on a machine that has a third governed project mounted and CI - which does
# not - then FAILED with "assertion did not run". The standing instruction after
# any assertion change is to re-record, so the documented procedure broke the
# build. Static name, varying value in the detail.
_leaked=""
while IFS= read -r _gn; do
  [ -n "$_gn" ] || continue
  grep -rniqF -- "$_gn" "${runtime[@]}" 2>/dev/null && _leaked="$_leaked $_gn"
done <<EOF
$(_gov_names)
EOF
if [ "${_govn:-0}" -eq 0 ]; then
  skip "the engine names no governed project" \
       "no governed project other than the engine's own, so nothing to search for"
elif [ -z "$_leaked" ]; then
  ok "the engine names no governed project"
else
  bad "the engine names no governed project" \
      "names:$_leaked
$(for _gn in $_leaked; do grep -rniF -- "$_gn" "${runtime[@]}" | head -2; done)"
fi

# The engine's own name is exempt, and that exemption must not silently become
# a hole for everything: it is one name, and it is the one Felix governs itself
# under.
is "exactly one name is exempt, and it is the engine's own" \
   "$(_gov_names | grep -cx felix)" "0"

# The enumeration rule itself, against a fixture holding all three cases. This
# is what the two copies disagreed about, and nothing compared them: a real
# project, an empty stray, and a plain file dropped in projects/.
_ENUMP="$TMP/enumproj"; rm -rf "$_ENUMP"; mkdir -p "$_ENUMP/real" "$_ENUMP/stray"
printf '{ "name": "real" }\n' > "$_ENUMP/real/project.json"
printf 'not a project\n' > "$_ENUMP/README.md"
_enum_at() { local p meta n; for meta in "$1"/*/project.json; do
               [ -f "$meta" ] || continue; n="${meta%/project.json}"
               printf '%s\n' "${n##*/}"; done; }
is "a directory declaring project.json is enumerated" \
   "$(_enum_at "$_ENUMP" | tr '\n' ' ')" "real "
_enum_bare() { ls -1 "$1" 2>/dev/null | tr '\n' ' '; }
case "$(_enum_bare "$_ENUMP")" in
  *README.md*) ok "and the bare listing the gate used to do would have counted a plain file" ;;
  *)           bad "and the bare listing the gate used to do would have counted a plain file" \
                   "$(_enum_bare "$_ENUMP")" ;;
esac
rm -rf "$_ENUMP"

# The independence check is a command now — engine/harness/bin/independence-scan
# — so every property below is driven rather than read off the gate's source.
# The first draft of these grepped the gate's block for tokens; the tokens moved
# to the scanner, and an assertion about a mechanism should break when the
# mechanism does, not when it is relocated. Each fixture breaks the property it
# names and expects the scanner to say so.
_ISCAN="$FROOT/harness/bin/independence-scan"
_indep_repo() {   # name -> path of a fresh repo with the four engine dirs tracked
  local r="$TMP/indep-$1"; mkdir -p "$r/engine/harness/lib" "$r/engine/harness/hooks" \
    "$r/engine/harness/bin" "$r/projects"
  ( _fx_cd "$r" && git init -q -b main \
    && printf '#!/bin/sh\n' > engine/harness/felix && printf '# lib\n' > engine/harness/lib/a.sh \
    && printf '# hook\n' > engine/harness/hooks/h && printf '# bin\n' > engine/harness/bin/b \
    && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
  printf '%s' "$r"
}
_iscan() { ( cd "$1" && "$_ISCAN" 2>&1 ); }

# Refuses to answer on a path it cannot search. git grep exits 128 on an
# unresolvable pathspec and abandons the whole search, so one absent path
# silenced every name — reproduced against the real gate once: a name planted
# in lib/ read FAIL, and moving bin/ aside turned it into ok with the violation
# still there. Both halves: the path must exist, and something tracked must be
# under it, because a directory of only untracked files lets git grep read
# nothing and return 0.
_IR="$(_indep_repo blind)"
printf '{"name":"blindproj"}\n' > "$_IR/projects/blindproj/project.json" 2>/dev/null || { mkdir -p "$_IR/projects/blindproj"; printf '{"name":"blindproj"}\n' > "$_IR/projects/blindproj/project.json"; }
printf '# blindproj\n' >> "$_IR/engine/harness/lib/a.sh"
( _fx_cd "$_IR" && git add -A && git -c user.name=t -c user.email=t@t commit -qm plant ) >/dev/null 2>&1
has "a planted name is caught" "$(_iscan "$_IR")" "blindproj"
( _fx_cd "$_IR" && git rm -rq engine/harness/bin && git -c user.name=t -c user.email=t@t commit -qm nobin ) >/dev/null 2>&1
_o="$(_iscan "$_IR")"
has "the scanner refuses to answer on a path it cannot search" "$_o" "cannot search"
case "$_o" in
  *blindproj*) bad "and does not pretend it searched the rest" "$_o" ;;
  *)           ok  "and does not pretend it searched the rest" ;;
esac
mkdir -p "$_IR/engine/harness/bin"; printf '# untracked only\n' > "$_IR/engine/harness/bin/stray"
has "a directory holding only untracked files is blind too" "$(_iscan "$_IR")" "cannot search"

# Enumerates declared projects, not directory entries. A project is a directory
# that declares itself with project.json; an empty stray and a plain file
# dropped in projects/ contribute nothing.
_IR="$(_indep_repo enum)"
mkdir -p "$_IR/projects/real" "$_IR/projects/stray"
printf '{"name":"real"}\n' > "$_IR/projects/real/project.json"
printf 'not a project\n' > "$_IR/projects/README.md"
printf '# a stray word and a README word\n' >> "$_IR/engine/harness/lib/a.sh"
( _fx_cd "$_IR" && git add -A && git -c user.name=t -c user.email=t@t commit -qm enum ) >/dev/null 2>&1
( cd "$_IR" && "$_ISCAN" >/dev/null 2>&1 ) && ok "it enumerates declared projects, not directory entries" \
  || bad "it enumerates declared projects, not directory entries" "$(_iscan "$_IR")"
printf '# real\n' >> "$_IR/engine/harness/lib/a.sh"
( _fx_cd "$_IR" && git add -A && git -c user.name=t -c user.email=t@t commit -qm real ) >/dev/null 2>&1
has "while a declared one is caught" "$(_iscan "$_IR")" "real"

# Matches a project name as a literal. -F, not -E: the name is interpolated
# straight into the search, so a project called `thi.rd` searched for a pattern
# and matched `thiXrd`, which names nothing.
_IR="$(_indep_repo literal)"
mkdir -p "$_IR/projects/thi.rd"; printf '{"name":"thi.rd"}\n' > "$_IR/projects/thi.rd/project.json"
printf '# thiXrd is not that project\n' >> "$_IR/engine/harness/lib/a.sh"
( _fx_cd "$_IR" && git add -A && git -c user.name=t -c user.email=t@t commit -qm lit ) >/dev/null 2>&1
( cd "$_IR" && "$_ISCAN" >/dev/null 2>&1 ) && ok "it matches a project name as a literal" \
  || bad "it matches a project name as a literal" "$(_iscan "$_IR")"
printf '# thi.rd itself\n' >> "$_IR/engine/harness/lib/a.sh"
( _fx_cd "$_IR" && git add -A && git -c user.name=t -c user.email=t@t commit -qm dot ) >/dev/null 2>&1
has "and the literal name is caught" "$(_iscan "$_IR")" "thi.rd"

# All four engine directories are searched. Planted in each in turn, because
# a path list is the kind of constant that gets shortened by accident and a
# source grep for it would pass on a list that a later edit reordered.
for _d in felix lib/a.sh hooks/h bin/b; do
  _IR="$(_indep_repo "paths-${_d%%/*}")"
  mkdir -p "$_IR/projects/pathproj"; printf '{"name":"pathproj"}\n' > "$_IR/projects/pathproj/project.json"
  printf '# pathproj\n' >> "$_IR/engine/harness/$_d"
  ( _fx_cd "$_IR" && git add -A && git -c user.name=t -c user.email=t@t commit -qm p ) >/dev/null 2>&1
  has "a name planted in engine/harness/${_d%%/*} is caught" "$(_iscan "$_IR")" "pathproj"
done

# And the scanner's own source names no project. bin/ is searched, and that
# includes this file, so this is the real tree judging the real scanner —
# the property, not a grep for a name the comment might have used.
( cd "$REAL_HARNESS/../.." && ./engine/harness/bin/independence-scan >/dev/null 2>&1 ) \
  && ok "the scanner's own code names no project" \
  || bad "the scanner's own code names no project" "$(cd "$REAL_HARNESS/../.." && ./engine/harness/bin/independence-scan 2>&1 | head -3)"


