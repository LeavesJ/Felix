printf '\nrisk classification\n'
_widget_repo_build

printf 'notes\n' > "$REPO/README.md"; _stage
out="$( cd "$REPO" && "$FELIX" classify --base HEAD~1 2>&1 )"
has "docs classify green" "$out" "tier:  green"
_reset

mkdir -p "$REPO/migrations"; printf 'x\n' > "$REPO/migrations/001.sql"; _stage
out="$( cd "$REPO" && "$FELIX" classify --base HEAD~1 2>&1 )"
has "a migration classifies red" "$out" "tier:  red"
_reset

printf 'notes\n' > "$REPO/README.md"
mkdir -p "$REPO/migrations"; printf 'x\n' > "$REPO/migrations/002.sql"; _stage
out="$( cd "$REPO" && "$FELIX" classify --base HEAD~1 2>&1 )"
has "one red file makes the whole diff red" "$out" "tier:  red"
_reset

printf 'x\n' > "$REPO/unknown_thing.xyz"; _stage
out="$( cd "$REPO" && "$FELIX" classify --base HEAD~1 2>&1 )"
has "an unrecognised file is yellow, never green" "$out" "tier:  yellow"
has "and says why"                                "$out" "no rule matched"
_reset

# The tier sentences are what a session reads when it ships. They said "a human
# merges" and "Approval required before merge", which nothing enforced — felix
# merge never reads the tier — and which the founder had overruled on 2026-09-12:
# Felix merges its own pull requests. A session believed the printed sentence
# over the direction and left five merges for him. Each negative is paired with
# the sentence that replaced it, so an output that printed nothing cannot pass.
printf 'x\n' > "$REPO/unknown_thing.xyz"; _stage
out="$( cd "$REPO" && "$FELIX" classify --base HEAD~1 2>&1 )"
case "$out" in
  *"a human merges"*) bad "a yellow diff no longer hands its merge to a person" "$out" ;;
  *)                  ok  "a yellow diff no longer hands its merge to a person" ;;
esac
has "and says it merges once CI is green" "$out" "merge once CI is green"
_reset
mkdir -p "$REPO/migrations"; printf 'x\n' > "$REPO/migrations/003.sql"; _stage
out="$( cd "$REPO" && "$FELIX" classify --base HEAD~1 2>&1 )"
case "$out" in
  *"Approval required"*) bad "a red diff no longer says approval is required before merge" "$out" ;;
  *)                     ok  "a red diff no longer says approval is required before merge" ;;
esac
has "and names the escape channel as where a person decides" "$out" "escape channel"
_reset
# The same sentence, injected into the session on a routed turn whenever the
# tree touches a red path. It was the loudest of them: "a person decides here".
mkdir -p "$REPO/migrations"; printf 'x\n' > "$REPO/migrations/004.sql"
_rred="$( cd "$REPO" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/classify.sh"
          . "$FROOT/harness/lib/incident.sh"; . "$FROOT/harness/lib/route.sh"
          _felix_route_red "$FROOT/projects/widget" "$REPO" 2>&1 )"
rm -rf "$REPO/migrations"
has "a red working tree is still named in the session" "$_rred" "calls red"
case "$_rred" in
  *"person"*"decides here"*|*"A person"*) bad "and the session is not told a person decides on tier alone" "$_rred" ;;
  *)                                      ok  "and the session is not told a person decides on tier alone" ;;
esac
# A bootstrapped repository asked a person before every `gh pr merge`, whatever
# the tier. What still asks is a merge that bypasses a required check.
_perm="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/bootstrap.sh"; felix_bs_render_perms )"
has "a bootstrapped repository still asks before a merge that bypasses checks" "$_perm" 'gh pr merge*--admin*'
case "$_perm" in
  *'"Bash(gh pr merge*)"'*) bad "but no longer before every merge" "$_perm" ;;
  *)                        ok  "but no longer before every merge" ;;
esac

# The marker decides which project governs a checkout, and the template rated
# it GREEN until 2026-09-03 — the one tier that can auto-merge. So the single
# file that can switch the floor off for a whole repository was the file least
# likely to be looked at on the way in.
#
# Edited without changing which project it names, because classification is a
# judgement about the path and the fixture still has to resolve while the CLI
# runs.
printf 'widget\n\n' > "$REPO/.felix"; _stage
out="$( cd "$REPO" && "$FELIX" classify --base HEAD~1 2>&1 )"
has "the project marker classifies red, never green" "$out" "tier:  red"
_reset

printf 'api_key = "sk-ant''-api03-AAAAAAAAAAAAAAAAAAAAAAAA"\n' > "$REPO/cfg.py"; _stage
out="$( cd "$REPO" && "$FELIX" classify --base HEAD~1 2>&1 )"
has "a credential in added lines classifies red" "$out" "tier:  red"
_reset

printf 'api_key = os.environ["ANTHROPIC_API_KEY"]\n' > "$REPO/cfg2.py"; _stage
out="$( cd "$REPO" && "$FELIX" classify --base HEAD~1 2>&1 )"
case "$out" in
  *"credential appears"*) bad "reading a key from env is not a credential" "$out" ;;
  *) ok "reading a key from env is not a credential" ;;
esac
_reset

printf '\na branch that rewrites the rules it is judged by\n'
# When Felix governs itself, projects/felix/risk.tsv is a tracked file in the
# repository being classified — and _felix_risk_rows read it off disk. So a
# commit could add a green row and then be classified by the row it had just
# added. The candidate wrote its own judge.
#
# Reproduced before it was believed: a commit deleting the red row for
# engine/harness/lib and adding a green one classified its own engine edit
# green. `verifier` catches that particular shape at merge because a row was
# removed, but classification is a separate surface with its own consumers —
# the tier label, the auto-merge streak, the receipt — and it was wrong at all
# of them.
#
# The rule is now that a change to an enforcing table may only ever tighten the
# diff carrying it. Both versions are evaluated and the stricter wins, so a
# widening applies from the next diff on and a tightening applies immediately.
# That is the base-version evaluation the earned-autonomy decision asks for
# (docs/2026-08-14-earned-autonomy-decision.md §4a), achieved for the tables,
# which is the half of the authority kernel that is data rather than code.
SELF="$TMP/self"; mkdir -p "$SELF/projects/p" "$SELF/engine/lib" "$SELF/engine/bin"
( _fx_cd "$SELF" && git init -q . && git config user.email t@t && git config user.name t )
printf 'red\tpath\t^engine/lib/\tsourced by every hook\nyellow\tpath\t^projects/[^/]+/risk\\.tsv$\trules\n' \
  > "$SELF/projects/p/risk.tsv"
printf 'lib\n'  > "$SELF/engine/lib/classify.sh"
printf 'scan\n' > "$SELF/engine/bin/secret-scan"
( _fx_cd "$SELF" && git add -A >/dev/null && git commit -qm base >/dev/null )
SELF_BASE="$( cd "$SELF" && git rev-parse HEAD )"

# Asserted per path, not on the whole diff. risk.tsv rates itself yellow, so
# every diff carrying one of these edits is floored at yellow no matter what
# happens to the file under attack — which is why the first report of this read
# the reproduction as green-versus-yellow rather than as the demotion it is. A
# whole-diff assertion here would pass without the fix.
_selfpath() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/classify.sh"
                felix_classify_tier \
                  "$(felix_classify_diff "$SELF/projects/p" "$SELF_BASE" "$SELF" \
                     | awk -F'\t' -v p="$1" '$2==p')" ); }

# Demotion: delete the red row, add a green one, edit the file it covered.
( _fx_cd "$SELF" && grep -v '^red' projects/p/risk.tsv > t && mv t projects/p/risk.tsv
  printf 'green\tpath\t^engine/lib/\tharmless\n' >> projects/p/risk.tsv
  printf 'PWNED\n' >> engine/lib/classify.sh
  git add -A >/dev/null && git commit -qm demote >/dev/null )
is "a green row cannot demote the diff that adds it" \
   "$(_selfpath engine/lib/classify.sh)" "red"
( _fx_cd "$SELF" && git reset -q --hard "$SELF_BASE" )

# The additive half, which `verifier` structurally cannot see: nothing is
# removed, so the escape guarding these tables never fires. A green row for a
# path that had no row at all takes a file from the yellow default to green in
# one commit — and engine/bin is where the credential scanner lives, the one
# the `disclose` channel shells out to.
( _fx_cd "$SELF" && printf 'green\tpath\t^engine/bin/\ttooling\n' >> projects/p/risk.tsv
  printf 'exit 0\n' > engine/bin/secret-scan
  git add -A >/dev/null && git commit -qm additive >/dev/null )
is "a green row for a previously unruled path does not green it either" \
   "$(_selfpath engine/bin/secret-scan)" "yellow"
( _fx_cd "$SELF" && git reset -q --hard "$SELF_BASE" )

# Tightening applies immediately. The stricter of the two versions wins, not
# the older one — otherwise the rule would be a reason to ignore the table.
( _fx_cd "$SELF" && printf 'red\tpath\t^engine/bin/\tthe scanner\n' >> projects/p/risk.tsv
  printf 'exit 0\n' > engine/bin/secret-scan
  git add -A >/dev/null && git commit -qm tighten >/dev/null )
is "a red row added applies to the diff that adds it" \
   "$(_selfpath engine/bin/secret-scan)" "red"
( _fx_cd "$SELF" && git reset -q --hard "$SELF_BASE" )

# The guard's own failure mode, which nothing asserted. felix_table_rel decided
# whether the base-version pass runs by comparing path strings, so any way the
# two paths were spelled differently switched the protection off and said
# nothing: a worktree, whose root is a different directory in the same
# repository, and a macOS /var vs /private/var pair, which is one directory
# spelled twice. Both reproduced before this was changed. Asking git is the only
# thing that gets both right, and felix_same_repo already existed for exactly
# this reason — it replaced two path-prefix guards that had lapsed the same way.
_tr() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/classify.sh"
          felix_table_rel "$1" "$2" ); }
SELFP="$( cd "$SELF" && pwd -P )"
is "the table resolves to its repo-relative path" \
   "$(_tr "$SELF" "$SELF/projects/p/risk.tsv")" "projects/p/risk.tsv"
is "and still resolves when the root is spelled the other way" \
   "$(_tr "$SELFP" "$SELF/projects/p/risk.tsv")" "projects/p/risk.tsv"
( _fx_cd "$SELF" && git worktree add -q "$TMP/selfwt" -b wt >/dev/null 2>&1 )
if [ -d "$TMP/selfwt" ]; then
  is "and from a worktree of the same repository" \
     "$(_tr "$TMP/selfwt" "$SELF/projects/p/risk.tsv")" "projects/p/risk.tsv"
else
  skip "and from a worktree of the same repository" "worktree add failed"
fi
# The other direction has to keep failing, or every governed product regresses.
is "a table in a different repository resolves to nothing" \
   "$(_tr "$REPO" "$SELF/projects/p/risk.tsv")" ""

# The trap this fix could set. A governed product's tables live in the Felix
# home and are not in its diff at all, so there is nothing there to defend
# against. Reading a base version that does not exist would yield no rows and
# floor every product diff at the yellow default — turning a fix for Felix into
# a regression for every project Felix governs. The second evaluation is
# skipped unless the table is tracked in the repository under judgement.
printf 'notes\n' > "$REPO/README.md"; _stage
out="$( cd "$REPO" && "$FELIX" classify --base HEAD~1 2>&1 )"
has "a table outside the classified repo is still read once, at HEAD" "$out" "tier:  green"
_reset

