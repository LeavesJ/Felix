printf '\nresolution\n'
out="$(cd "$REPO" && "$FELIX" which 2>&1)"
has "resolves via .felix marker with no remote" "$out" "project:      widget"
has "reports the governed tree"                 "$out" "governs:      $REPO"

out="$(cd "$REPO/deep/nested" && "$FELIX" which 2>&1)"
has "resolves from a nested subdirectory" "$out" "project:      widget"

printf '\ngate execution\n'
out="$(cd "$REPO/deep/nested" && "$FELIX" gate 2>&1)"; rc=$?
is  "passing gate exits 0" "$rc" "0"
has "gate command actually ran" "$out" "widget-gate-ran"

# The gate must run against the checkout it was pointed at, not against Felix.
# A gate that inspects its own directory returns a verdict about the wrong code.
rm "$REPO/WIDGET.txt"
out="$(cd "$REPO" && "$FELIX" gate 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "failing gate propagates non-zero exit" \
                || bad "failing gate propagates non-zero exit" "got 0, a gate that cannot fail is not a gate"
printf 'contents\n' > "$REPO/WIDGET.txt"

# Qualification is armed on declaration, and on nothing else.
#
# A project that has qualified nothing is skipped and told so, the same way an
# absent probes.tsv is: this gate declines to be the place that turns a new
# project red on day one, which is the objection that kept qualification
# unarmed. What binds is a control somebody wrote down — and writing one is the
# act of claiming the checker catches that case.
has "a project that has qualified nothing is skipped, not failed" \
    "$out" "no qualification.tsv for widget"

printf '\nungoverned directories\n'
_plain_build
out="$(cd "$PLAIN" && "$FELIX" gate 2>&1)"; rc=$?
is  "ungoverned repo refuses to run a gate" "$rc" "2"
has "and says which projects it knows"      "$out" "Known projects:"

printf '\nsession hook\n'
out="$(cd "$REPO" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
has "hook binds the invented project" "$out" "Project: widget"
case "$out" in
  *'"hookSpecificOutput"'*) ok "hook emits Claude Code shape as a plugin" ;;
  *) bad "hook emits Claude Code shape as a plugin" "$out" ;;
esac

# A governed project's constitution lives in Felix's home, not the repository,
# so nothing auto-loads it and naming it is the entire delivery mechanism. This
# was masked inside Felix itself, where the file happens to sit in the tree
# being edited, and not masked at all anywhere else.
has "the hook says what must be read first" "$out" "Read before planning"

# The hook must actually be able to call what it reports on. A missing source
# line makes tidy and retire silent rather than broken, which is the shape of
# every "passes by finding nothing" bug this project has paid for.
for _fn in felix_tidy_safe felix_ledger_retire felix_autonomy_allows; do
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
    . "$FROOT/harness/lib/autonomy.sh"; . "$FROOT/harness/lib/ledger.sh"
    command -v "$_fn" >/dev/null 2>&1 ) \
    && ok "$_fn is defined for the hook" || bad "$_fn is defined for the hook"
  grep -q "lib/${_fn#felix_}" /dev/null 2>&1 || true
done
for _lib in autonomy ledger; do
  grep -q "lib/${_lib}.sh" "$FROOT/harness/hooks/session-start" \
    && ok "session-start sources ${_lib}.sh" \
    || bad "session-start sources ${_lib}.sh" "it would fail silently"
done
printf '# handoff\n' > "$REPO/HANDOFF.md"
out="$(cd "$REPO" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
has "and names a handoff when the repo has one" "$out" "HANDOFF.md"
# A section that landed and has not been folded in yet is newer than anything
# HANDOFF.md holds (lib/handoff.sh), so it is named with it: the newest five,
# and a count of the rest.
mkdir -p "$REPO/docs/handoff/pending"
for _hp in 1 2 3 4 5 6 7; do printf '### section %s\n' "$_hp" > "$REPO/docs/handoff/pending/2026010${_hp}T000000Z-s.md"; done
out="$(cd "$REPO" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
_hpl="$(printf '%s' "$out" | awk '{ gsub(/\\n/, "\n"); print }' | awk -v RS= 'index($0, "Read before planning") { print; exit }')"
has "and the handoff sections waiting in docs/handoff/pending/, newest first, beside it" \
    "$_hpl" "$REPO/docs/handoff/pending/20260107T000000Z-s.md"
case "$_hpl" in
  *20260102T000000Z*) bad "but only the newest five, and the rest counted" "$_hpl" ;;
  *"and 2 older in"*) ok  "but only the newest five, and the rest counted" ;;
  *)                  bad "but only the newest five, and the rest counted" "$_hpl" ;;
esac
rm -rf "$REPO/docs"
rm -f "$REPO/HANDOFF.md"
out="$(cd "$REPO" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
case "$out" in
  *"$REPO/HANDOFF.md"*) bad "and names none when there is none" "$out" ;;
  *)                    ok  "and names none when there is none" ;;
esac

# The constitution and the repository's HANDOFF.md are standing direction; the
# session handoff under memory is not. A prior session wrote it, sometimes from
# another worktree or on a detached HEAD, and the banner used to put it in the
# same list and call all three "standing direction that has already been
# decided". A fresh session then copied a stale blocker forward from it as
# though it were settled. "those" in that sentence points upward, so both the
# paragraph that says it and the one above must be free of the session handoff.
printf '# handoff\n' > "$REPO/HANDOFF.md"
mkdir -p "$MEM/widget"
printf '# Handoff\n\nRegenerated 2026-01-01. Anything below is the state of the tree,\n' \
  > "$MEM/widget/SESSION_HANDOFF.md"
out="$(cd "$REPO" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" </dev/null 2>&1)"
# The context arrives JSON-escaped; paragraphs are blank-line separated once
# the escapes are real newlines.
_paras="$(printf '%s' "$out" | awk '{ gsub(/\\n/, "\n"); print }')"
_para_with() { printf '%s\n' "$_paras" | awk -v RS= -v k="$1" 'index($0, k) { print; exit }'; }
_dir_idx="$(printf '%s\n' "$_paras" | awk -v RS= 'index($0, "standing direction") { print NR; exit }')"
_dir_two="$(printf '%s\n' "$_paras" | awk -v RS= -v n="${_dir_idx:-0}" 'NR == n - 1 || NR == n')"
has "the banner still calls the constitution standing direction" "$_dir_two" "$FROOT/projects/widget/CLAUDE.md"
has "and the repository handoff with it"                         "$_dir_two" "$REPO/HANDOFF.md"
case "$_dir_two" in
  *SESSION_HANDOFF.md*) bad "but not the session handoff, which a prior session wrote" "$_dir_two" ;;
  *)                    ok  "but not the session handoff, which a prior session wrote" ;;
esac
_sh_para="$(_para_with "$MEM/widget/SESSION_HANDOFF.md")"
has "the session handoff is named as state to re-check by command" "$_sh_para" "by command"
case "$_sh_para" in
  *"standing direction"*) bad "and never as standing direction" "$_sh_para" ;;
  *)                      ok  "and never as standing direction" ;;
esac
rm -f "$REPO/HANDOFF.md" "$MEM/widget/SESSION_HANDOFF.md"
out="$(cd "$REPO" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" </dev/null 2>&1)"
case "$out" in
  *SESSION_HANDOFF*|*"by command"*) bad "and with no session handoff on disk, says nothing about one" "$out" ;;
  *)                                ok  "and with no session handoff on disk, says nothing about one" ;;
esac

# A resume starts a new process and rebinds hooks, so it is a lifecycle moment
# Felix has to be able to see; the matcher did not name it, so session-start
# was never called there. It is bound now and says nothing, which keeps the
# banner exactly where it was: the moment is reachable for a recorder, not a
# second banner.
_ss_matcher="$(sed -n '/"SessionStart"/,/"matcher"/s/.*"matcher"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
                 "$REAL_HARNESS/../hooks/hooks.json" | head -1)"
case "|$_ss_matcher|" in
  *"|resume|"*) ok  "the SessionStart matcher binds resume" ;;
  *)            bad "the SessionStart matcher binds resume" "matcher is [$_ss_matcher]" ;;
esac
_ss_all=1
for _w in startup clear compact; do
  case "|$_ss_matcher|" in *"|$_w|"*) ;; *) _ss_all=0 ;; esac
done
[ "$_ss_all" = 1 ] && ok  "and still binds startup, clear and compact" \
                   || bad "and still binds startup, clear and compact" "matcher is [$_ss_matcher]"
out="$(cd "$REPO" && printf '{"session_id": "s-resume", "hook_event_name": "SessionStart", "source": "resume"}' \
       | CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"; rc=$?
is "a resumed session gets no banner" "${#out}" "0"
is "and the hook exits 0 there"       "$rc"     "0"
out="$(cd "$REPO" && printf '{"session_id":"s-start","hook_event_name":"SessionStart","source":"startup"}' \
       | CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
has "a startup payload still gets the banner" "$out" "Project: widget"
out="$(cd "$REPO" && printf '{"session_id":"s-compact","source":"compact"}' \
       | CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
has "and so does a compact"                   "$out" "Project: widget"
# Only Claude Code's resume was unbound. Copilot CLI fires its sessionStart on a
# resume with no matcher in front of it and a source of "resume", so there the
# banner was always shown, and "unchanged" means it still is.
out="$(cd "$REPO" && printf '{"source":"resume"}' \
       | COPILOT_CLI=1 CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
has "a Copilot resume, which always got the banner, still does" "$out" "Project: widget"

# Felix also installs as a plain settings.json hook, where CLAUDE_PLUGIN_ROOT is
# unset. Emitting the wrong shape there injects nothing and fails silently.
out="$(cd "$REPO" && env -u CLAUDE_PLUGIN_ROOT "$FROOT/harness/hooks/session-start" 2>&1)"
case "$out" in
  *'"hookSpecificOutput"'*) ok "hook emits Claude Code shape without plugin env" ;;
  *) bad "hook emits Claude Code shape without plugin env" "$out" ;;
esac
out_json="$(printf '%s' "$out" | python3 -c 'import json,sys; print(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"][:20])' 2>&1)"
has "and that output is valid JSON" "$out_json" "Felix governs"

out="$(cd "$PLAIN" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"; rc=$?
is "hook silent in ungoverned repo" "${#out}" "0"
is "hook still exits 0 there"       "$rc" "0"

printf '\nonboarding a stranger project\n'
# The `claude` stub (see tests/lib/cm-stub.sh): every test that runs felix new goes through it.
_cmstub_build

# The claim under test: someone who downloads Felix gets what another governed project got,
# without hand-writing any of it. A Node app with no git remote, nothing to do
# with anything already here. _stranger_build (tests/lib/cm-stub.sh) makes it
# and runs felix new over it; its output and exit status are read back here.
_stranger_build; out="$_stranger_out"; rc="$_stranger_rc"
is  "felix new exits 0"            "$rc" "0"
has "detects from their manifest"  "$out" "billing"
has "guesses their gate"           "$out" "npm run verify"
# Its memory root was empty, so nothing is said to have been kept. The block
# after "refuses to clobber" below is the case where something was.
is  "and claims to have kept no memory, having found none" \
    "$(printf '%s\n' "$out" | grep -cE '^  memory .*kept')" "0"

SP="$FROOT/projects/stranger"
for f in project.json capabilities stack.tsv profiles.tsv setup.tsv CLAUDE.md; do
  [ -f "$SP/$f" ] && ok "seeded $f" || bad "seeded $f"
done
[ -s "$SP/setup/stripe.md" ] && ok "copied the runbook their stack implies" \
                             || bad "copied the runbook their stack implies"
[ -f "$SP/setup/sentry.md" ] && bad "skips runbooks for absent capabilities" \
                             || ok "skips runbooks for absent capabilities"
[ -f "$STRANGE/.felix" ] && ok "binds the checkout with no remote" \
                         || bad "binds the checkout with no remote"

out="$(cd "$STRANGE" && "$FELIX" which 2>&1)"
has "governs them immediately" "$out" "project:      stranger"
# The guess was already asserted above. Executing it should test that Felix runs
# a project's declared gate, not that npm happens to be installed on this
# machine, so the declared command is swapped for a shell-native one.
python3 - "$SP/project.json" <<'PYJ'
import json,sys,pathlib
p=pathlib.Path(sys.argv[1]); d=json.loads(p.read_text())
d["gate"]="sh -c 'test -f package.json'"
p.write_text(json.dumps(d,indent=2))
PYJ
out="$(cd "$STRANGE" && "$FELIX" gate 2>&1)"; rc=$?
is "their declared gate runs and passes" "$rc" "0"

# High risk must stay blocked for a stranger exactly as it does for us.
out="$(cd "$STRANGE" && "$FELIX" stack plan 2>&1)"
case "$out" in
  *"blocked"*"stripe"*) ok "their high-risk rows are blocked too" ;;
  *) bad "their high-risk rows are blocked too" "$out" ;;
esac

out="$(PATH="$CMSTUB:$PATH" "$FELIX" new stranger 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "refuses to clobber an existing project" \
                || bad "refuses to clobber an existing project"

printf '\nfelix new: memory that outlived its project is kept\n'
# That refusal looks at projects/<name>/ and nothing else, and memory is not
# there. It lives under $FELIX_MEMORY, which invariant 6 says nothing deletes,
# so a project directory can be gone while <memory>/<name>/ still holds what the
# project paid for: removed by hand, or a second machine whose memory synced
# before its home did. felix new opened the devlog, the lessons and the session
# handoff with `: >`, which left each at zero bytes, and the next pulse commit
# recorded the loss.
RBC="$TMP/reborn"; mkdir -p "$RBC"; ( _fx_cd "$RBC" && git init -q -b main )
RBM="$MEM/reborn"; RBK="$TMP/reborn.keep"; mkdir -p "$RBM" "$RBK"
printf '# Devlog\n\n## 2026-09-01\n\nthe first entry, written nowhere else\n' > "$RBM/DEVLOG.md"
printf '\n- **2026-09-02** a lesson this project paid for once\n' > "$RBM/lessons.md"
printf '# Handoff\n\nwritten by hand, and not in the generated shape\n' > "$RBM/SESSION_HANDOFF.md"
cp "$RBM/DEVLOG.md" "$RBM/lessons.md" "$RBM/SESSION_HANDOFF.md" "$RBK/"
out="$(cd "$RBC" && PATH="$CMSTUB:$PATH" "$FELIX" new reborn 2>&1)"; rc=$?
is "felix new over memory that outlived its project exits 0" "$rc" "0"
for f in DEVLOG.md lessons.md SESSION_HANDOFF.md; do
  cmp -s "$RBM/$f" "$RBK/$f" \
    && ok  "and keeps the $f it found, byte for byte" \
    || bad "and keeps the $f it found, byte for byte" \
           "$(wc -c < "$RBM/$f" 2>/dev/null | tr -d ' ') bytes left of $(wc -c < "$RBK/$f" | tr -d ' ')"
done
_rbl="$(printf '%s\n' "$out" | grep -E '^  memory ')"
has "and says the memory it found was kept" "$_rbl" "kept"
for f in DEVLOG.md lessons.md SESSION_HANDOFF.md; do
  has "and names $f among what it kept" "$_rbl" "$f"
done

# Only part of it survived: lessons.md with something in it, and the empty
# SESSION_HANDOFF.md an earlier felix new left as a placeholder. The test is
# whether a file exists, not whether it holds bytes, so the placeholder is kept
# and said to be, and only DEVLOG.md is created. A line naming every file
# whatever it found would pass the block above; a check for a non-empty file
# would pass everything here but the kept line.
RPC="$TMP/rebornpart"; mkdir -p "$RPC"; ( _fx_cd "$RPC" && git init -q -b main )
RPM="$MEM/rebornpart"; mkdir -p "$RPM"
printf '\n- **2026-09-03** the one file that synced with something in it\n' > "$RPM/lessons.md"
: > "$RPM/SESSION_HANDOFF.md"
cp "$RPM/lessons.md" "$TMP/rebornpart.lessons"
out="$(cd "$RPC" && PATH="$CMSTUB:$PATH" "$FELIX" new rebornpart 2>&1)"; rc=$?
is "felix new over part of a memory root exits 0" "$rc" "0"
cmp -s "$RPM/lessons.md" "$TMP/rebornpart.lessons" \
  && ok  "and keeps the file it found with content, byte for byte" \
  || bad "and keeps the file it found with content, byte for byte" "$(cat "$RPM/lessons.md" 2>/dev/null)"
[ -f "$RPM/DEVLOG.md" ] && [ ! -s "$RPM/DEVLOG.md" ] \
  && ok  "and creates the missing DEVLOG.md empty" \
  || bad "and creates the missing DEVLOG.md empty" "$(ls -l "$RPM/DEVLOG.md" 2>&1)"
_rpl="$(printf '%s\n' "$out" | grep -E '^  memory ')"
has "and names what it kept, the empty placeholder among it" "$_rpl" "kept lessons.md SESSION_HANDOFF.md,"
case "$_rpl" in
  *DEVLOG.md*) bad "and does not call the file it created kept" "$_rpl" ;;
  *) ok "and does not call the file it created kept" ;;
esac
rm -rf "$FROOT/projects/reborn" "$MEM/reborn" "$RBC" "$RBK" \
       "$FROOT/projects/rebornpart" "$MEM/rebornpart" "$RPC" "$TMP/rebornpart.lessons"

printf '\ncapability detection\n'
# The scenario the founder asked for: a surface that does not exist today, and
# the day it appears Felix notices without anyone remembering to look.
out="$(cd "$REPO" && "$FELIX" doctor 2>&1)"
case "$out" in
  *"undeclared:   none"*) ok "clean project reports no drift" ;;
  *) bad "clean project reports no drift" "$out" ;;
esac

printf 'sentry-sdk>=2.0\n' > "$REPO/requirements.txt"
out="$(cd "$REPO" && "$FELIX" doctor 2>&1)"
has "adding sentry surfaces observability" "$out" "observability"
has "and explains why it now matters"      "$out" "incident loop"

printf 'FROM python:3.12\n' > "$REPO/Dockerfile"
out="$(cd "$REPO" && "$FELIX" doctor 2>&1)"
has "adding a Dockerfile surfaces deploy" "$out" "deploy"

out="$(cd "$REPO" && "$FELIX" doctor 2>&1)"; rc=$?
is "doctor exits 0 despite drift" "$rc" "0"

# The call site, not just the library. A capability carrying no keywords of
# its own is scored on its name alone, or on nothing when the name is too
# short to be one, and until the funnel was measured nothing said which
# capabilities were in that state.
# Snapshotted and restored rather than edited back with grep -v, which exits
# non-zero when it selects nothing and silently skipped the restore in the
# first version of this test — the same shape as the grep -c lesson already
# in this repository.
cp "$FROOT/projects/widget/capabilities" "$TMP/caps.snapshot" 2>/dev/null || : > "$TMP/caps.snapshot"
printf 'ci\nsecurity\nops\n' > "$FROOT/projects/widget/capabilities"
out="$(cd "$REPO" && "$FELIX" doctor 2>&1)"
has "doctor names a capability with no discovery rule" "$out" "no discovery rule"
has "and says a long name at least scores on itself"   "$out" "its own name only"
has "while a short one scores on nothing"              "$out" "too short"
# Matched against the row shape, not against the words anywhere in the
# report: `ci ` also appears in the `declared:` header line, so a loose
# glob was satisfied by output that proves nothing.
is "and a ruled capability is not listed there" \
   "$(printf '%s\n' "$out" | grep -cE '^  ci +scored')" "0"
is "while the unruled ones are"                 "$(printf '%s\n' "$out" | grep -cE '^  (security|ops) +scored')" "2"
printf 'ci\ntests\n' > "$FROOT/projects/widget/capabilities"
out="$(cd "$REPO" && "$FELIX" doctor 2>&1)"
case "$out" in
  *"no discovery rule"*) bad "and says nothing when every capability has a rule" "$out" ;;
  *)                     ok  "and says nothing when every capability has a rule" ;;
esac
cp "$TMP/caps.snapshot" "$FROOT/projects/widget/capabilities"

# Adopting must also pull in what the capability implies. Recording it and
# stopping was the original bug: the checklist looked complete while the tooling
# and human steps stayed invisible.
cp "$REAL_HARNESS/templates/setup.tsv" /dev/null 2>/dev/null || true
before_stack="$(cat "$FROOT/projects/widget/stack.tsv" 2>/dev/null | wc -l)"
before_setup="$(cat "$FROOT/projects/widget/setup.tsv" 2>/dev/null | wc -l)"
out="$(cd "$REPO" && "$FELIX" adopt observability 2>&1)"
has "adopting reports the backfill" "$out" "backfilled"
# A backfilled row comes from the catalogue, whose tiers a person assigned,
# so it carries DECLARED — written by the engine, said as a person's.
case "$(grep -c $'\tDECLARED$' "$FROOT/projects/widget/stack.tsv")" in 0) bad "a backfilled row carries DECLARED" "$(cat "$FROOT/projects/widget/stack.tsv")" ;; *) ok "a backfilled row carries DECLARED" ;; esac
after_stack="$(cat "$FROOT/projects/widget/stack.tsv" 2>/dev/null | wc -l)"
after_setup="$(cat "$FROOT/projects/widget/setup.tsv" 2>/dev/null | wc -l)"
[ "$after_stack" -gt "$before_stack" ] && ok "backfilled the tooling the capability implies" \
                                       || bad "backfilled the tooling the capability implies" "stack.tsv unchanged"
[ "$after_setup" -gt "$before_setup" ] && ok "backfilled the human steps it implies" \
                                       || bad "backfilled the human steps it implies" "setup.tsv unchanged"
[ -f "$FROOT/projects/widget/setup/sentry.md" ] && ok "copied the runbook it implies" \
                                                || bad "copied the runbook it implies"
out="$(cd "$REPO" && "$FELIX" adopt observability 2>&1)"
has "adopting twice is a no-op" "$out" "already declared"
out="$(cd "$REPO" && "$FELIX" doctor 2>&1)"
case "$out" in
  *"undeclared:   deploy"*) ok "adopting removes it from drift" ;;
  *) bad "adopting removes it from drift" "$out" ;;
esac
rm -f "$REPO/requirements.txt" "$REPO/Dockerfile"

