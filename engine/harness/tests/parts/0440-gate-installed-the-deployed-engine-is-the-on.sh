# Two gates at once, each reporting its own suite. The gate wrote the suite's
# output to one fixed path shared by every gate on the machine, then printed
# that file's last line as the count and its FAIL lines as the evidence. Two
# sessions gating at once each opened it with O_TRUNC and wrote at their own
# offsets, and on 2026-09-21 a gate printed "2645 passed" for a suite that had
# passed 2586. The verdict was never wrong, being the suite's exit status, so
# nothing failed; what a PR body quotes under it belonged to another tree.
#
# The real gate over stub suites. Each stub writes everything, then waits until
# the other has written too before it exits, so both gates read after both
# writes: the collision a shared path allows, made certain rather than likely.
# The lines are of equal length, so a shared file holds one run's output whole
# and cannot pass by holding both. TMPDIR is shared between the two, as it is
# between two sessions on one machine, so only the gate's own choice of path
# keeps them apart. The rendezvous is asserted, because two gates that never
# overlapped would pass this whatever path they used.
#
# Every literal /tmp/ in the copies is moved under the fixture first. A fixed
# path stays one path both copies share, so a gate that uses one still fails
# here for the reason it fails on a machine; but the real one is in use by
# whatever other sessions are gating right now, and tests/red runs this against
# the base's gate, which still writes it. A suite that truncated another
# session's log to prove the log gets truncated would be the defect it names.
_GCON="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/gate.sh"
if [ -f "$_GCON" ]; then
  GCT="$TMP/gate-concurrent"; mkdir -p "$GCT/tmp" "$GCT/sync" "$GCT/fixed"
  for _t in a b; do
    _o=b; [ "$_t" = b ] && _o=a
    mkdir -p "$GCT/$_t/engine/harness/tests"
    sed "s|/tmp/|$GCT/fixed/|g" "$_GCON" > "$GCT/$_t/gate.sh"
    cat > "$GCT/$_t/engine/harness/tests/run" <<STUB
#!/usr/bin/env bash
printf '  ok    the suite of tree $_t\n'
[ "\${GCT_RED:-0}" = 1 ] && printf '  FAIL  tree $_t broke\n        detail from tree $_t\n'
printf 'tree $_t: 1 passed, 0 failed, 0 skipped\n'
touch "$GCT/sync/$_t"
i=0
while [ ! -e "$GCT/sync/$_o" ]; do
  [ "\$i" -ge 200 ] && { echo timeout >> "$GCT/sync/met"; exit 3; }
  sleep 0.05; i=\$((i+1))
done
echo met >> "$GCT/sync/met"
[ "\${GCT_RED:-0}" = 1 ] && exit 1
exit 0
STUB
    chmod +x "$GCT/$_t/engine/harness/tests/run"
    ( _fx_cd "$GCT/$_t" && git init -q -b main && git add -A \
      && git -c user.name=t -c user.email=t@t commit -qm s ) >/dev/null 2>&1
  done
  # No plugin cache, so `installed` skips and the suite always runs.
  _gcon_pair() {
    rm -f "$GCT/sync/a" "$GCT/sync/b" "$GCT/sync/met"
    ( cd "$GCT/a" && GCT_RED="$1" TMPDIR="$GCT/tmp" FELIX_KERNEL_CACHE="$GCT/no-cache" \
        bash gate.sh > "$GCT/a.out" 2>&1 ) & _gpa=$!
    ( cd "$GCT/b" && GCT_RED="$1" TMPDIR="$GCT/tmp" FELIX_KERNEL_CACHE="$GCT/no-cache" \
        bash gate.sh > "$GCT/b.out" 2>&1 ) & _gpb=$!
    wait "$_gpa" "$_gpb"
  }
  _gcon_count() { awk 'f { sub(/^ +/, ""); print; exit } /^  tests +ok$/ { f = 1 }' "$1"; }
  _gcon_met()   { sort "$GCT/sync/met" 2>/dev/null | uniq -c | awk '{ printf "%s %s;", $1, $2 }'; }

  # One assertion for both gates, not one each: which of the two reads the
  # other's count depends on which wrote last, and red.tsv should name the same
  # failure every time it is regenerated.
  _gcon_pair 0
  is "two gates at once each report their own suite's count" \
     "$(_gcon_count "$GCT/a.out") | $(_gcon_count "$GCT/b.out")" \
     "tree a: 1 passed, 0 failed, 0 skipped | tree b: 1 passed, 0 failed, 0 skipped"
  is "and the two suites were running at the same moment" "$(_gcon_met)" "2 met;"
  is "a passing gate leaves no suite log behind" "$(ls -A "$GCT/tmp" | wc -l | tr -d ' ')" "0"

  _gcon_pair 1
  is "two failing gates at once: each FAIL excerpt is its own suite's" \
     "$(grep -ohE 'tree [ab] broke|detail from tree [ab]' "$GCT/a.out" "$GCT/b.out" | tr '\n' ',')" \
     "tree a broke,detail from tree a,tree b broke,detail from tree b,"
  is "and those two suites were running at the same moment" "$(_gcon_met)" "2 met;"
  _gla="$(sed -n 's/^ *full log: //p' "$GCT/a.out")"
  _glb="$(sed -n 's/^ *full log: //p' "$GCT/b.out")"
  if [ -n "$_gla" ] && [ -n "$_glb" ] && [ "$_gla" != "$_glb" ] \
     && grep -q 'tree a broke' "$_gla" && ! grep -q 'tree b' "$_gla" \
     && grep -q 'tree b broke' "$_glb" && ! grep -q 'tree a' "$_glb"; then
    ok "and each full log line names a file holding its own run alone"
  else
    bad "and each full log line names a file holding its own run alone" "a [$_gla] b [$_glb]"
  fi
  # The class, not the two instances: any fixed path under /tmp is one every
  # gate on the machine shares. The install-drift list sat in one as well.
  is "felix's gate names no fixed path under /tmp outside its comments" \
     "$(grep -vE '^[[:space:]]*#' "$_GCON" | grep -c '/tmp/')" "0"
else
  for a in "two gates at once each report their own suite's count" \
           "and the two suites were running at the same moment" \
           "a passing gate leaves no suite log behind" \
           "two failing gates at once: each FAIL excerpt is its own suite's" \
           "and those two suites were running at the same moment" \
           "and each full log line names a file holding its own run alone" \
           "felix's gate names no fixed path under /tmp outside its comments"; do
    skip "$a" "no projects/felix/gate.sh beside this harness"; done
fi

# The row itself: task-blocking, grounded on the probe that already asks
# whether anything is deployed, and never unknown on the tree the suite runs in.
_DCKP="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix"
if [ -f "$_DCKP/obligations.tsv" ] && [ -x "$REAL_HARNESS/bin/obligations-check" ]; then
  is  "felix admits engine_deployed as task-blocking, grounded on the one fact it rests on" \
      "$(grep '^engine_deployed' "$_DCKP/obligations.tsv" | cut -f2,6)" "TASK_BLOCKING	deployed_engine"
  out="$(cd "$REAL_HARNESS/../.." && "$REAL_HARNESS/bin/obligations-check" projects/felix 2>&1 | grep '^  engine_deployed')"
  case "$out" in
    *UNKNOWN*) bad "and on this tree it is dormant, satisfied or unsatisfied, never unknown" "$out" ;;
    '')        bad "and on this tree it is dormant, satisfied or unsatisfied, never unknown" "no row printed" ;;
    *)         ok  "and on this tree it is dormant, satisfied or unsatisfied, never unknown" ;;
  esac
else
  for a in "felix admits engine_deployed as task-blocking, grounded on the one fact it rests on" \
           "and on this tree it is dormant, satisfied or unsatisfied, never unknown"; do
    skip "$a" "no projects/felix/obligations.tsv beside this harness"; done
fi

# ------------------------- installed asks what main accepted (#2, promotion spec) ---
# docs/2026-08-18-promotion-spec.md, steps 2-4. `installed` asked whether the
# engine in the tree standing here is the one deployed, which only the checkout
# the marketplace serves can ever answer yes to — so `felix merge` existed in one
# folder, and the only workflow that reached it deployed the candidate before it
# was judged. It now asks whether the deployed cache entry for the version MAIN
# declares is byte-identical to MAIN's engine: both sides from the base (§4),
# which is the engine `felix merge` judges with, so the gate certifies the judge.
#
# §8's criteria, criterion 3 first because it is the one the replaced design
# fails. Every fixture pins `git init -b main` (5) and none sets
# FELIX_KERNEL_CACHE (6). The fixture's gate is cut at the `tests` marker so
# each run is syntax, executable and installed and nothing else.
printf '\ngate installed: the deployed engine is the one main accepted\n'
GIN="$TMP/gate-installed"; GINC="$GIN/home/.claude/plugins/cache/felix/felix"
mkdir -p "$GIN/tree/engine/.claude-plugin" "$GINC" "$GIN/bin" "$GIN/nohome"
_copy_content "$REAL_HARNESS" "$GIN/tree/engine/harness"
_copy_content "$REAL_HARNESS/../hooks" "$GIN/tree/engine/hooks"
[ -d "$REAL_HARNESS/../commands" ] && _copy_content "$REAL_HARNESS/../commands" "$GIN/tree/engine/commands"
printf '{ "name": "felix", "version": "0.0.1" }\n' > "$GIN/tree/engine/.claude-plugin/plugin.json"
printf '*.log\n' > "$GIN/tree/.gitignore"
_GING="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/gate.sh"
if [ -f "$_GING" ] && grep -q '^# -* tests -*$' "$_GING"; then
  sed '/^# -* tests -*$/,$d' "$_GING" > "$GIN/tree/gate.sh"
  ( _fx_cd "$GIN/tree" && git init -q -b main && git add -A \
    && git -c user.name=t -c user.email=t@t commit -qm seed ) >/dev/null 2>&1
  GINT="$(cd "$GIN/tree" && pwd -P)"
  # Deploy a ref's engine at a version, the way the cache holds it: the
  # directories felix install copies, from the commit rather than the disk.
  _gin_deploy() {   # ref, version
    rm -rf "$GINC/$2" "$GIN/x"; mkdir -p "$GINC/$2" "$GIN/x"
    _fx_git "$GINT" archive -o "$GIN/x.tar" "$1" engine && tar -x -f "$GIN/x.tar" -C "$GIN/x"
    rm -f "$GIN/x.tar"
    for _d in harness hooks commands .claude-plugin; do
      [ -d "$GIN/x/engine/$_d" ] && cp -R "$GIN/x/engine/$_d" "$GINC/$2/$_d"
    done
    rm -rf "$GIN/x"
  }
  _gin_live() { printf '%s' "$GINC/$1" > "$GIN/live"; }
  cat > "$GIN/bin/claude" <<STUB
#!/usr/bin/env bash
case "\$*" in "plugin list --json") printf '{ "felix@felix": { "installPath": "%s" } }\n' "\$(cat "$GIN/live")" ;; esac
exit 0
STUB
  chmod +x "$GIN/bin/claude"
  # The worktree shape by default: the marketplace serves a different checkout.
  printf '{\n  "felix": {\n    "installLocation": "/served/elsewhere"\n  }\n}\n' \
    > "$GIN/home/.claude/plugins/known_marketplaces.json"
  _gin()  { ( cd "$GINT" && unset FELIX_KERNEL FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE
              HOME="$GIN/home" PATH="$GIN/bin:$PATH" bash gate.sh --quick 2>&1 \
              | awk '/^  installed/ { on = 1; print; next } on && /^  [a-z]/ { exit } on { print }' ); }
  _ginv() { printf '%s\n' "$1" | awk '/^  installed/ { print $2; exit }'; }
  _gin_deploy main 0.0.1; _gin_live 0.0.1

  # Criterion 3. A branch that changed the engine, gated once with nothing
  # installed and once after installing it at a bumped version: the verdict
  # must not depend on having done the thing it would tell you to do.
  ( _fx_cd "$GINT" && git checkout -q -b cand && printf '# candidate\n' >> engine/harness/lib/say.sh \
    && git -c user.name=t -c user.email=t@t commit -qam cand ) >/dev/null 2>&1
  _gino_skip="$(_gin)"
  ( _fx_cd "$GINT" && sed -i.bak 's/"0.0.1"/"0.0.2"/' engine/.claude-plugin/plugin.json && rm -f engine/.claude-plugin/plugin.json.bak \
    && git -c user.name=t -c user.email=t@t commit -qam bump ) >/dev/null 2>&1
  _gin_deploy cand 0.0.2; _gin_live 0.0.2
  _gino_inst="$(_gin)"
  is  "installed gives the same verdict whether the branch's engine was installed or not" \
      "$(_ginv "$_gino_skip") $(_ginv "$_gino_inst")" "ok ok"
  # Criterion 1, the one #2 is about.
  is  "a branch whose engine differs from the deployed one reads installed ok" "$(_ginv "$_gino_skip")" "ok"
  # The phrases are the ok line's own: the replaced gate's FAIL output also
  # carries the entry's path, and a bare path passed against it for that reason.
  # §3: the check is the resolve.sh trust made a fact, so it must name the entry
  # felix merge's judge would use, derived without sourcing the engine it judges.
  _gin_kd="$( cd "$GINT" && unset FELIX_KERNEL FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE
              HOME="$GIN/home" && . "$FROOT/harness/lib/resolve.sh" && felix_kernel_dir "$GINT" main )"
  has "and it names the cache entry felix merge would judge with" "$_gino_skip" "${_gin_kd%/harness} is its engine"
  ( _fx_cd "$GINT" && git checkout -q main ) >/dev/null 2>&1; _gin_live 0.0.1; rm -rf "$GINC/0.0.2"

  # Criterion 2. Where "written is not installed" moves to: main has taken an
  # engine change and nothing deployed it. If this cannot fail, the protection
  # was dropped rather than relocated.
  ( _fx_cd "$GINT" && printf '# merged, not deployed\n' >> engine/harness/lib/say.sh \
    && git -c user.name=t -c user.email=t@t commit -qam merged ) >/dev/null 2>&1
  _gino="$(_gin)"
  is  "on main after an engine change nobody deployed, installed fails" "$(_ginv "$_gino")" "FAIL"
  has "and names the path that differs" "$_gino" "say.sh"
  ( _fx_cd "$GINT" && sed -i.bak 's/"0.0.1"/"0.0.9"/' engine/.claude-plugin/plugin.json && rm -f engine/.claude-plugin/plugin.json.bak \
    && git -c user.name=t -c user.email=t@t commit -qam bump ) >/dev/null 2>&1
  _gino="$(_gin)"
  is  "a version main declares with no cache entry fails rather than skipping" "$(_ginv "$_gino")" "FAIL"
  has "and says which version is not installed" "$_gino" "0.0.9"
  _gin_deploy main 0.0.9; _gin_live 0.0.9
  is  "and deploying main's engine at that version clears it" "$(_ginv "$(_gin)")" "ok"
  # Criterion 4. Otherwise it asserts two things derived the same way are equal.
  printf '# tampered\n' >> "$GINC/0.0.9/harness/lib/say.sh"
  is  "a cache entry for main's version that was tampered with fails" "$(_ginv "$(_gin)")" "FAIL"
  _gin_deploy main 0.0.9
  # #86, kept: a path git ignores is residue in the cache, not drift.
  printf 'x\n' > "$GINC/0.0.9/harness/tests/scratch.log"
  is  "a file git ignores, left in the cache entry, is not drift" "$(_ginv "$(_gin)")" "ok"
  rm -f "$GINC/0.0.9/harness/tests/scratch.log"
  # §7: a green installed no longer says which engine is live, so it says so
  # when the live one is not main's.
  _gin_live 0.0.1
  has "when the live engine is not main's, the ok says which one is live" "$(_gin)" "the live engine is 0.0.1"
  _gin_live 0.0.9
  # Where the remedy is: drift in the checkout the marketplace serves stays a
  # plain FAIL with the command, and drift seen from anywhere else is marked
  # structural so it is not written down as this checkout's mistake (#3).
  printf '# again\n' >> "$GINC/0.0.9/harness/lib/say.sh"
  _gino="$(_gin)"
  has "drift seen from a checkout the marketplace does not serve is marked structural" "$_gino" "structural"
  printf '{\n  "felix": {\n    "installLocation": "%s"\n  }\n}\n' "$GINT" > "$GIN/home/.claude/plugins/known_marketplaces.json"
  _gino="$(_gin)"
  case "$_gino" in
    *structural*) bad "and drift in the served checkout is a plain FAIL" "$_gino" ;;
    *FAIL*)       ok  "and drift in the served checkout is a plain FAIL" ;;
    *)            bad "and drift in the served checkout is a plain FAIL" "$_gino" ;;
  esac
  has "that names the command" "$_gino" "felix install"
  _gin_deploy main 0.0.9
  # No felix cache at all is a runner, as before.
  _gino="$( cd "$GINT" && unset FELIX_KERNEL FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE
            HOME="$GIN/nohome" PATH="$GIN/bin:$PATH" bash gate.sh --quick 2>&1 | grep '^  installed' )"
  has "with no felix cache on the machine, installed is skipped" "$_gino" "skipped"
  # ---- the fold: the verdict is main's own resolve.sh, read from the commit.
  # Written blind against the contract, not the code. The gate obtains
  # `installed` by sourcing engine/harness/lib/resolve.sh at the base ref
  # (origin/main, else main) in a subshell and calling
  # felix_accepted_deploy_diff — never the working tree's copy, never the
  # cache entry's. A one-line redefinition appended to a copy says which copy
  # was sourced, because bash keeps the last definition; the marker in the
  # output is the evidence, since once main's resolve.sh differs from the
  # entry the verdict word alone is satisfied by ordinary drift.
  _gin_sha="$(git -C "$GINT" rev-parse main)"
  _gin_stub()    { printf '\nfelix_accepted_deploy_diff() { echo %s; return %s; }\n' "$1" "$2" >> "$3"; }  # marker, rc, file
  _gin_commit()  { _fx_git "$GINT" -c user.name=t -c user.email=t@t commit -qam "$1" >/dev/null 2>&1; }
  _gin_restore() {   # main back at the recorded sha, the entry re-cut from it
    ( _fx_cd "$GINT" && git checkout -q main && git reset -q --hard "$_gin_sha" ) >/dev/null 2>&1
    _gin_deploy main 0.0.9
  }
  # 1. Main's copy decides. Committed on main, so the working tree is main as
  # well; what this isolates is the cache entry's copy, which carries no stub.
  _gin_stub MARKER-FROM-MAIN 1 "$GINT/engine/harness/lib/resolve.sh"; _gin_commit stub-main
  _gino="$(_gin)"
  is  "main's resolve.sh decides the installed verdict" "$(_ginv "$_gino")" "FAIL"
  has "and what main's copy printed reaches the output" "$_gino" "MARKER-FROM-MAIN"
  _gin_restore
  # The same the other way round: main's copy reports identical while the
  # entry now genuinely differs from main (by this very stub), so a private
  # comparison would say FAIL and only the sourced function says ok.
  _gin_stub MARKER-FROM-MAIN 0 "$GINT/engine/harness/lib/resolve.sh"; _gin_commit stub-main-ok
  is  "and a main copy that reports identical is believed over the cache entry" "$(_ginv "$(_gin)")" "ok"
  _gin_restore
  # Never the working tree's: uncommitted first, then committed on the branch
  # being gated. Either stub would turn the verdict FAIL and print, if sourced.
  _gin_stub MARKER-FROM-TREE 1 "$GINT/engine/harness/lib/resolve.sh"
  _gino="$(_gin)"
  is  "an uncommitted resolve.sh in the working tree does not change the verdict" "$(_ginv "$_gino")" "ok"
  case "$_gino" in
    *MARKER-FROM-TREE*) bad "and nothing the working tree's copy printed reaches the output" "$_gino" ;;
    *)                  ok  "and nothing the working tree's copy printed reaches the output" ;;
  esac
  ( _fx_cd "$GINT" && git checkout -q -- engine/harness/lib/resolve.sh && git checkout -q -b side ) >/dev/null 2>&1
  _gin_stub MARKER-FROM-SIDE 1 "$GINT/engine/harness/lib/resolve.sh"; _gin_commit stub-side
  _gino="$(_gin)"
  is  "a resolve.sh committed on the branch being gated does not change the verdict" "$(_ginv "$_gino")" "ok"
  case "$_gino" in
    *MARKER-FROM-SIDE*) bad "and nothing the branch's copy printed reaches the output" "$_gino" ;;
    *)                  ok  "and nothing the branch's copy printed reaches the output" ;;
  esac
  ( _fx_cd "$GINT" && git checkout -q main && git branch -q -D side ) >/dev/null 2>&1
  # Never the cache entry's: a stub there that reports identical is, to main's
  # own function, one more path that differs.
  _gin_stub MARKER-FROM-CACHE 0 "$GINC/0.0.9/harness/lib/resolve.sh"
  is  "a resolve.sh stubbed in the cache entry is drift, not the judge" "$(_ginv "$(_gin)")" "FAIL"
  _gin_deploy main 0.0.9
  # 2. Nothing to call is FAIL, and named — never ok, never skipped. First
  # main's copy without the definition; then main without the file at all,
  # gated from a branch that still has it.
  ( cd "$GINT" && sed -i.bak '/^felix_accepted_deploy_diff()/,/^}/d' engine/harness/lib/resolve.sh \
    && rm -f engine/harness/lib/resolve.sh.bak ) >/dev/null 2>&1; _gin_commit no-definition
  _gino="$(_gin)"
  is  "when main's resolve.sh does not define the check, installed fails rather than skipping" "$(_ginv "$_gino")" "FAIL"
  has "and names the function it could not find" "$_gino" "felix_accepted_deploy_diff"
  _gin_restore
  ( _fx_cd "$GINT" && git rm -q engine/harness/lib/resolve.sh ) >/dev/null 2>&1; _gin_commit no-file
  ( _fx_cd "$GINT" && git checkout -q -b side "$_gin_sha" ) >/dev/null 2>&1
  _gino="$(_gin)"
  is  "when main has no resolve.sh to read, installed fails rather than skipping" "$(_ginv "$_gino")" "FAIL"
  has "and names the function it could not source" "$_gino" "felix_accepted_deploy_diff"
  _gin_restore; _fx_git "$GINT" branch -q -D side >/dev/null 2>&1
  # Criterion 4 once more, after the fold.
  printf '# tampered\n' >> "$GINC/0.0.9/harness/lib/say.sh"
  is  "after the fold, a tampered cache entry still fails" "$(_ginv "$(_gin)")" "FAIL"
  _gin_deploy main 0.0.9
  # 4. Structural: the gate's private copy of the comparison is gone, the way
  # the probes block asserts its own private copy is.
  if grep -q 'diff -rq' "$_GING"; then
    bad "felix's own gate no longer carries a private copy of the deploy comparison" \
        "diff -rq is still in projects/felix/gate.sh"
  else
    ok  "felix's own gate no longer carries a private copy of the deploy comparison"
  fi
else
  for a in "installed gives the same verdict whether the branch's engine was installed or not" \
           "a branch whose engine differs from the deployed one reads installed ok" \
           "and it names the cache entry felix merge would judge with" \
           "on main after an engine change nobody deployed, installed fails" "and names the path that differs" \
           "a version main declares with no cache entry fails rather than skipping" \
           "and says which version is not installed" "and deploying main's engine at that version clears it" \
           "a cache entry for main's version that was tampered with fails" \
           "a file git ignores, left in the cache entry, is not drift" \
           "when the live engine is not main's, the ok says which one is live" \
           "drift seen from a checkout the marketplace does not serve is marked structural" \
           "and drift in the served checkout is a plain FAIL" "that names the command" \
           "with no felix cache on the machine, installed is skipped" \
           "main's resolve.sh decides the installed verdict" \
           "and what main's copy printed reaches the output" \
           "and a main copy that reports identical is believed over the cache entry" \
           "an uncommitted resolve.sh in the working tree does not change the verdict" \
           "and nothing the working tree's copy printed reaches the output" \
           "a resolve.sh committed on the branch being gated does not change the verdict" \
           "and nothing the branch's copy printed reaches the output" \
           "a resolve.sh stubbed in the cache entry is drift, not the judge" \
           "when main's resolve.sh does not define the check, installed fails rather than skipping" \
           "and names the function it could not find" \
           "when main has no resolve.sh to read, installed fails rather than skipping" \
           "and names the function it could not source" \
           "after the fold, a tampered cache entry still fails" \
           "felix's own gate no longer carries a private copy of the deploy comparison"; do
    skip "$a" "no projects/felix/gate.sh with a tests marker beside this harness"; done
fi

