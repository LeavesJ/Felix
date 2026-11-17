printf '\nscheduled maintenance\n'
_widget_repo_build
{
  printf 'weekly-thing\t7\talways\tan aggregated cleanup\n'
  printf 'monthly-thing\t30\talways\ta drift report\n'
  printf 'on-trigger\t0\talways\tfires on an event, never a clock\n'
  printf 'later-thing\t7\tbilling\tonly once payments exist\n'
} > "$FROOT/projects/widget/maintenance.tsv"
rm -f "$FROOT/projects/widget/maintenance.log"

out="$(cd "$REPO" && "$FELIX" maintenance 2>&1)"
has "a never-run routine is due"           "$out" "DUE     weekly-thing"
has "an event-driven routine is not due"   "$out" "event   on-trigger"
has "a dormant capability stays quiet"     "$out" "-       later-thing"
has "it insists on aggregating"            "$out" "one branch"

out="$(cd "$REPO" && "$FELIX" maintenance --ran weekly-thing 2>&1)"
has "recording a run works" "$out" "recorded a run of weekly-thing"
out="$(cd "$REPO" && "$FELIX" maintenance 2>&1)"
has "and it stops being due" "$out" "ok      weekly-thing"
has "while others stay due"  "$out" "DUE     monthly-thing"

# A cadence tracked outside the project resets on another machine and reports
# everything as never-run, which is worse than not tracking it.
[ -f "$FROOT/projects/widget/maintenance.log" ] \
  && ok "the log is durable state in the project" \
  || bad "the log is durable state in the project"

out="$(cd "$REPO" && "$FELIX" maintenance --ran nope 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "an unknown routine is refused" || bad "an unknown routine is refused"

# Overdue by construction: backdate the log past the cadence.
printf 'monthly-thing\t1\t1970-01-01\n' >> "$FROOT/projects/widget/maintenance.log"
out="$(cd "$REPO" && "$FELIX" maintenance 2>&1)"
has "an ancient run counts as due again" "$out" "DUE     monthly-thing"

# A second overdue routine, so the badge below is asserting a COUNT and not a
# flag. With one due, "1 due" and "some due" are the same string and the
# assertion cannot tell a working counter from a constant.
printf 'weekly-thing\t1\t1970-01-01\n' >> "$FROOT/projects/widget/maintenance.log"

out="$(cd "$REPO" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
has "the hook surfaces due maintenance" "$out" "Maintenance due"

# #57, confirmed item 4. The founder's one-line badge appends "· N due", and N
# counted ${MAINT:-} — a variable assigned NOWHERE in the engine. `grep -rn
# '\bMAINT\b'` returns exactly one hit and it is that read. The value actually
# holding the due list is `_due`, set ~95 lines above under a different name.
#
# So the count was always 0, the badge never appeared, and a founder with
# overdue maintenance saw the same status line as one with none — on the only
# surface Felix has to tell them. additionalContext reaches the model; this line
# is the half a person reads.
#
# Asserted against what `felix maintenance` itself reports, rather than a fixed
# number, so the two cannot drift apart and still both look right.
_bl="$(printf '%s' "$out" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("systemMessage",""))
except Exception: print("")' 2>/dev/null)"
_badge_n="$(printf '%s' "$_bl" | sed -n 's/.*· \([0-9][0-9]*\) due.*/\1/p')"
_real_n="$(cd "$REPO" && "$FELIX" maintenance 2>&1 | grep -c '^  DUE ')"
is "and the founder's one line says how many are due" "${_badge_n:-none}" "$_real_n"
# The count is the point, not the word: a badge reading "1 due" when three are
# overdue is the same defect wearing a number.
[ "${_real_n:-0}" -ge 2 ] \
  && ok "and that is more than one, so the count is doing work" \
  || bad "and that is more than one, so the count is doing work" \
         "only $_real_n due; the assertion above cannot tell a count from a flag"

printf '\nadvisory recommendations\n'
out="$(cd "$REPO" && "$FELIX" recommend 2>&1)"
has "reports what is not yet declared" "$out" "not yet declared"
has "hands off for anything broader"   "$out" "claude-automation-recommender"
has "and passes the facts it already has" "$out" "Felix already detected"
case "$out" in
  *"# kind"*|*"risk=high is never"*)
    bad "the handoff carries no file comments" "comment lines leaked into the prompt" ;;
  *) ok "the handoff carries no file comments" ;;
esac

out="$(cd "$REPO" && "$FELIX" recommend --want "browser testing" 2>&1)"
has "free text matches the catalogue" "$out" "playwright"
out="$(cd "$REPO" && "$FELIX" recommend --want "catch security problems" 2>&1)"
has "and matches on keywords, not just names" "$out" "security-guidance"
out="$(cd "$REPO" && "$FELIX" recommend --want "quantum teleportation" 2>&1)"
has "says so plainly when nothing matches" "$out" "Nothing in the catalogue matches"
has "and still offers the handoff"         "$out" "claude-automation-recommender"

# Advice that installs things is not advice.
before="$(claude plugin list 2>/dev/null | wc -l)"
( cd "$REPO" && "$FELIX" recommend --want "browser testing" >/dev/null 2>&1 )
after="$(claude plugin list 2>/dev/null | wc -l)"
is "recommending installs nothing" "$after" "$before"

printf '\nsecret scanning\n'
SS="$FROOT/harness/bin/secret-scan"
for s in 'api_key = "sk-ant''-api03-AAAAAAAAAAAAAAAAAAAAAAAA"' \
         'password = "hunter2''-correct-horse"' \
         '-----BEGIN RSA PRIV''ATE KEY-----'; do
  _ss_n=$((${_ss_n:-0}+1))
  printf '+%s\n' "$s" | "$SS" - >/dev/null 2>&1 \
    && bad "catches credential sample $_ss_n" "scanner passed: $s" \
    || ok "catches credential sample $_ss_n"
done
unset _ss_n
# The exclusions are the load-bearing half. A scanner that cries wolf is off in a
# week, and then the real finding lands in a channel nobody reads.
for s in '    token: str = ""' \
         'api_key = os.environ["ANTHROPIC_API_KEY"]' \
         'token = secrets.token_urlsafe(9)' \
         'password = "<redacted>"' \
         'const k = process.env.STRIPE_KEY'; do
  _ss_n=$((${_ss_n:-0}+1))
  printf '+%s\n' "$s" | "$SS" - >/dev/null 2>&1 \
    && ok "quiet on exclusion sample $_ss_n" \
    || bad "quiet on exclusion sample $_ss_n" "false positive on: $s"
done
unset _ss_n

# An exclusion applied to the whole line defuses every credential on it. That
# turned the scanner off with one word: a live AWS key on a line that also said
# "example" exited 0, and a private key header wrapped in <pre> did too, because
# the angle-bracket placeholder rule matched the markup. Reproduced against the
# shipped scanner before it was changed.
#
# The split is by what the token actually claims. A context token says the LINE
# is a lookup or a generator, so it is read whole-line. A value token says the
# VALUE is fake, so it only counts inside the matched credential itself.
# These fixtures are credential-shaped on purpose, and the fix means the excuses
# in them no longer defuse the scanner — including when it reads this file. The
# must_flag marker on each line is a CONTEXT exclusion, which is exactly what it
# is for: the line is a fixture, not a literal.
for s in 'aws_key = "AKI''A2QQ7RJ4KLMNOPQRS"  # example' `: must_flag` \
         '<pre>-----BEGIN RSA PRIV''ATE KEY-----</pre>' `: must_flag` \
         'k = "sk-ant''-api03-BBBBBBBBBBBBBBBBBBBB"  # ...' `: must_flag` \
         'see the placeholder above: gh''p_AAAAAAAAAAAAAAAAAAAAAAAAAAAA' `: must_flag`; do
  _ss_n=$((${_ss_n:-0}+1))
  printf '+%s\n' "$s" | "$SS" - >/dev/null 2>&1 \
    && bad "an excuse elsewhere does not defuse, sample $_ss_n" "scanner passed: $s" \
    || ok "an excuse elsewhere does not defuse, sample $_ss_n"
done
unset _ss_n
# And the value-scoped exclusions must still work where they belong: inside the
# matched value. Otherwise this fix just turns the scanner into the wolf-crier.
for s in 'password = "<redacted>"' \
         'key = "sk-ant-api03-xxxxxxxxxxxxxxxxxxxx"' \
         'aws = "AKIAIOSFODNN7EXAMPLE"' \
         'api_key = "placeholder-not-a-real-key"'; do
  _ss_n=$((${_ss_n:-0}+1))
  printf '+%s\n' "$s" | "$SS" - >/dev/null 2>&1 \
    && ok "still quiet when the value itself says so, sample $_ss_n" \
    || bad "still quiet when the value itself says so, sample $_ss_n" "false positive on: $s"
done
unset _ss_n

# A temporary AWS key id begins ASIA, not AKIA, and the STS response that hands
# one out is JSON, where the keyword is a quoted key and its closing quote sits
# between it and the colon. A planted snapshot published both (2026-09-22). The
# values are assembled here, so this file carries no credential's shape.
_ss_k="$(printf '%s%s' ASIA Q7XK2M9PLR4TWN3B)"
_ss_s="$(printf '%s%s' wJalrXUtnFEMIK7MDENG bPxRfiCYzQ2wE4rT6yU8i)"
for s in "export AWS_ACCESS_KEY_ID=\"$_ss_k\"" \
         "        \"AccessKeyId\": \"$_ss_k\"," \
         "        \"SecretAccessKey\": \"$_ss_s\"," \
         "{\"env\": {\"AWS_SESSION_TOKEN\": \"$_ss_s\"}}" \
         "{'password': '$_ss_s'}"; do
  _ss_n=$((${_ss_n:-0}+1))
  printf '+%s\n' "$s" | "$SS" - >/dev/null 2>&1 \
    && bad "catches a temporary key or a quoted JSON key, sample $_ss_n" "scanner passed: $s" \
    || ok "catches a temporary key or a quoted JSON key, sample $_ss_n"
done
unset _ss_n _ss_k _ss_s
# And JSON's other values stay quiet: prose naming the prefixes, a reference to
# the environment, and a sentence under a key that happens to hold a keyword.
for s in 'An AWS key id begins AKIA when it is long-term and ASIA when STS issued it.' \
         '        "DD_API_KEY": "${DD_API_KEY:-}",' \
         '{"env":{"TOKEN":"${INLINE_TOKEN}"}}' \
         '  "token_description": "the token a run hands to the gate",'; do
  _ss_n=$((${_ss_n:-0}+1))
  printf '+%s\n' "$s" | "$SS" - >/dev/null 2>&1 \
    && ok "quiet on JSON that holds no credential, sample $_ss_n" \
    || bad "quiet on JSON that holds no credential, sample $_ss_n" "false positive on: $s"
done
unset _ss_n
# A key the keyword only begins names something about a credential, and JSON
# quotes every value: the first quote rule flagged each of these, which the
# scanner before it had passed. A key the keyword ends is still read.
for s in '  "token_type": "access_token",' \
         '  "tokenizer_class": "GPT2Tokenizer",' \
         '  "secret_name": "ANTHROPIC_API_KEY",' \
         '  "api_key_env": "OPENAI_API_KEY",' \
         '  "password_policy": "strong-only",'; do
  _ss_n=$((${_ss_n:-0}+1))
  printf '+%s\n' "$s" | "$SS" - >/dev/null 2>&1 \
    && ok "quiet on a key the keyword only begins, sample $_ss_n" \
    || bad "quiet on a key the keyword only begins, sample $_ss_n" "false positive on: $s"
done
unset _ss_n
_ss_s="$(printf '%s%s' wJalrXUtnFEMIK7MDENG bPxRfiCYzQ2wE4rT6yU8i)"
for s in "  \"client_secret\": \"$_ss_s\"," "  \"apiKey\": \"$_ss_s\"," "  \"refresh_token\": \"$_ss_s\","; do
  _ss_n=$((${_ss_n:-0}+1))
  printf '+%s\n' "$s" | "$SS" - >/dev/null 2>&1 \
    && bad "catches a key the keyword ends, sample $_ss_n" "scanner passed: $s" \
    || ok "catches a key the keyword ends, sample $_ss_n"
done
unset _ss_n _ss_s
# The scan reads without case, and under it the key id's shape took "Asia" and
# sixteen letters of one CamelCase word. A key id is capitals and digits, and a
# real one beside that word is still caught.
printf '+%s\n' 'The AsiaPacificEconomicCoop forum meets in November.' | "$SS" - >/dev/null 2>&1 \
  && ok "quiet on a word that begins with a key id's prefix" \
  || bad "quiet on a word that begins with a key id's prefix" "false positive on AsiaPacificEconomicCoop"
printf '+AsiaPacificEconomicCoop %s%s\n' ASIA Q7XK2M9PLR4TWN3B | "$SS" - >/dev/null 2>&1 \
  && bad "a key id beside that word is still caught" "scanner passed a temporary key id" \
  || ok "a key id beside that word is still caught"

# GitHub's other prefixes, measured 2026-09-23. The scanner knew ghp_ and
# github_pat_ and not ghs_ (an installation token, the Actions GITHUB_TOKEN),
# gho_, ghu_ or ghr_: a workflow's unquoted `token:` value slipped the keyword
# rule on its underscore. actions/checkout also leaves the token in .git/config
# as a basic-auth header whose base64 begins with the encoding of
# `x-access-token:`, a fixed prefix. Values assembled, as above; the samples
# are the blind-authored qualification rows', plus a lookup whose fallback is
# the token, since a hard shape must bound the context exclusion.
_ss_i="$(printf '%s%s' ghs_ fakeQ7mZ2vT9kLd4RnW8pJyUc0AeGhSbXo31)"
_ss_o="$(printf '%s%s' gho_ fakeVb3NqK8tXm2ZrW7yLd0PcJ5uHgE9sTaF)"
_ss_r="$(printf '%s%s' ghr_ fakeRz4mKq9TvL2xNb7WcJ0pYd5AhGs8EuF3iXoZ1kMt6QwVbP2nLd9rHy4SeKa7UjC0mT3gWx5B)"
_ss_b="$(printf '%s%s' eC1hY2Nlc3MtdG9rZW46 Z2hzX2Zha2VIazJQdk44bVF6NVRyWDBiTGQ3WWNXM2pVZTlBc0c0Rg==)"
for s in "          token: $_ss_i" \
         "GH_TOKEN=$_ss_o" \
         "github.com,felix-bot,$_ss_r,2026-09-23" \
         "$(printf '\textraheader = AUTHORIZATION: basic %s' "$_ss_b")" \
         "git config http.https://github.com/.extraheader \"AUTHORIZATION: basic $_ss_b\"" \
         "k = os.environ.get('T', '$_ss_i')"; do
  _ss_n=$((${_ss_n:-0}+1))
  printf '+%s\n' "$s" | "$SS" - >/dev/null 2>&1 \
    && bad "catches a GitHub installation, OAuth or refresh token, or checkout's basic-auth header, sample $_ss_n" "scanner passed: $s" \
    || ok "catches a GitHub installation, OAuth or refresh token, or checkout's basic-auth header, sample $_ss_n"
done
unset _ss_n
# And prose naming the prefixes stays quiet, as does an identifier that only
# begins with one.
for s in '# ghs_ is an installation token, the shape of an Actions GITHUB_TOKEN; gho_ an OAuth token; ghu_ a user-to-server token; ghr_ a refresh token.' \
         'Because `x-access-token:` is fifteen bytes, its encoding is the fixed prefix `eC1hY2Nlc3MtdG9rZW46` and the token begins right after it.' \
         'ghs_token_for_the_run = lookup()'; do
  _ss_n=$((${_ss_n:-0}+1))
  printf '+%s\n' "$s" | "$SS" - >/dev/null 2>&1 \
    && ok "quiet on prose naming the GitHub prefixes or the header's fixed base64, sample $_ss_n" \
    || bad "quiet on prose naming the GitHub prefixes or the header's fixed base64, sample $_ss_n" "false positive on: $s"
done
unset _ss_n _ss_i _ss_o _ss_r _ss_b

# A new file has no previous version, so git diff cannot see it, and a fresh
# file is where a key most often lands.
SECREPO="$TMP/secrepo"; mkdir -p "$SECREPO"
( _fx_cd "$SECREPO" && git init -q -b main
  printf 'x\n' > a.txt && git add -A >/dev/null && git -c user.name=t -c user.email=t@t commit -qm i )
printf 'key = "sk-ant''-api03-BBBBBBBBBBBBBBBBBBBBBBBB"\n' > "$SECREPO/leak.py"
( cd "$SECREPO" && "$SS" >/dev/null 2>&1 ) \
  && bad "sees a credential in an untracked new file" "passed clean" \
  || ok "sees a credential in an untracked new file"
rm "$SECREPO/leak.py"
( cd "$SECREPO" && "$SS" >/dev/null 2>&1 ) \
  && ok "clean once it is gone" || bad "clean once it is gone"

printf '\nproject memory\n'
MEMREPO="$REPO"
out="$(cd "$MEMREPO" && "$FELIX" log "did a thing for a reason" 2>&1)"
has "log writes to the devlog" "$out" "DEVLOG.md"
grep -q "did a thing for a reason" "$MEM/widget/DEVLOG.md" \
  && ok "and the text is actually there" || bad "and the text is actually there"
grep -qE '^## [0-9]{4}-[0-9]{2}-[0-9]{2} ' "$MEM/widget/DEVLOG.md" \
  && ok "stamped with date, branch and commit" || bad "stamped with date, branch and commit"

out="$(cd "$MEMREPO" && "$FELIX" lesson "always check the thing" 2>&1)"
has "lesson warns against writing too much" "$out" "worse than none"
grep -q "always check the thing" "$MEM/widget/lessons.md" \
  && ok "lesson is recorded" || bad "lesson is recorded"

out="$(cd "$MEMREPO" && "$FELIX" handoff 2>&1)"
has "handoff lists the session-end checks" "$out" "before you stop"
grep -q "## Where" "$MEM/widget/SESSION_HANDOFF.md" \
  && ok "handoff is regenerated from the tree" || bad "handoff is regenerated from the tree"

# #127. The note is the one line git cannot rebuild, and the CLI threw away the
# obvious way of giving it: `felix handoff "what was in progress"` passed a
# positional, the parser's catch-all shifted it off, and the command printed
# success over a note from two sessions earlier. The library carries a note
# across a regeneration on purpose; the defect is the call site, so the call
# site is what is tested.
_hnote() { sed -n 's/^- what was in progress: //p' "$MEM/widget/SESSION_HANDOFF.md" | head -1; }
( cd "$MEMREPO" && "$FELIX" handoff --was "set with the flag" >/dev/null 2>&1 )
is  "handoff --was still records the note" "$(_hnote)" "set with the flag"
( cd "$MEMREPO" && "$FELIX" handoff "given as words" "not a flag" >/dev/null 2>&1 ); _hrc=$?
is  "a note typed without --was is recorded, not dropped" "$(_hnote)" "given as words not a flag"
is  "and the command succeeds"                            "$_hrc" "0"
_ho="$(cd "$MEMREPO" && "$FELIX" handoff --wsa "misspelled" 2>&1)"; _hrc=$?
is  "an unrecognised flag refuses rather than printing success" "$_hrc" "1"
has "and says how the command is used"                          "$_ho" "usage"
is  "and leaves the recorded note as it was"                    "$(_hnote)" "given as words not a flag"
( cd "$MEMREPO" && "$FELIX" handoff --was "one" "two" >/dev/null 2>&1 ); _hrc=$?
is  "a note given twice, by flag and by words, refuses"         "$_hrc" "1"
is  "and records neither"                                       "$(_hnote)" "given as words not a flag"
# The stale note that started this: nothing given, an old note carried, and
# nothing said. Carrying stays; silence does not.
_ho="$(cd "$MEMREPO" && "$FELIX" handoff 2>&1)"
has "a handoff given no note says it kept the last one" "$_ho" "kept the note from the last handoff"
has "and shows which note it kept"                      "$_ho" "given as words not a flag"
rm -f "$MEM/widget/SESSION_HANDOFF.md"
_ho="$(cd "$MEMREPO" && "$FELIX" handoff 2>&1)"
case "$_ho" in
  *"kept the note"*) bad "and does not claim to keep a note when there was none" "$_ho" ;;
  *)                 ok  "and does not claim to keep a note when there was none" ;;
esac
has "but says there is none to keep"                    "$_ho" "no note of what was in progress"

# The promotion signal is recurrence across days, not volume on one day.
D="$MEM/widget/DEVLOG.md"
: > "$D"
for i in 1 2 3; do printf '\n## 2026-01-0%s b abc\n\nzephyrine handling again\n' "$i" >> "$D"; done
printf '\n## 2026-02-01 b abc\n\nmonolith monolith monolith monolith monolith\n' >> "$D"
out="$(cd "$MEMREPO" && "$FELIX" promote 2>&1)"
has "a term recurring across entries surfaces" "$out" "zephyrine"
case "$out" in
  *monolith*) bad "volume inside one entry does not" "counted repeats, not entries" ;;
  *) ok "volume inside one entry does not" ;;
esac
printf -- '- **2026-01-01** zephyrine is known\n' > "$MEM/widget/lessons.md"
out="$(cd "$MEMREPO" && "$FELIX" promote 2>&1)"
case "$out" in
  *zephyrine*) bad "already-learned terms drop out" "$out" ;;
  *) ok "already-learned terms drop out" ;;
esac

printf '\nscope bound for unattended work\n'
# The bound that matters is not how many attempts an agent gets, it is what it
# may touch. Three careful attempts at an authorization model is three times the
# exposure, not a third of the risk.
out="$(cd "$REPO" && "$FELIX" scope docs/guide.md 2>&1)"; rc=$?
has "documentation is in scope" "$out" "In scope"
is  "and exits 0"               "$rc" "0"

out="$(cd "$REPO" && "$FELIX" scope migrations/003.sql 2>&1)"; rc=$?
has "a migration is out of scope" "$out" "OUT OF SCOPE"
is  "and exits 3, distinctly"     "$rc" "3"

# Mixed input must take the worst path, not the average or the first.
out="$(cd "$REPO" && "$FELIX" scope docs/guide.md migrations/003.sql 2>&1)"; rc=$?
is "one red path poisons the whole set" "$rc" "3"
out="$(cd "$REPO" && "$FELIX" scope migrations/003.sql docs/guide.md 2>&1)"; rc=$?
is "regardless of the order given" "$rc" "3"

out="$(cd "$REPO" && printf 'docs/guide.md\n' | "$FELIX" scope - 2>&1)"; rc=$?
is "reads paths from stdin too" "$rc" "0"

out="$(cd "$REPO" && "$FELIX" scope src/thing.js 2>&1)"; rc=$?
is "an unremarkable file is in scope" "$rc" "0"
has "and says the gates still apply" "$out" "evidence policy"

printf '\nearned auto-merge\n'
# The streak logic is the part that decides; the GitHub calls that feed it need a
# network and are exercised by using the thing. Fed synthetic history here.
_streak() { ( . "$FROOT/engine/harness/lib/automerge.sh" 2>/dev/null \
              || . "$FROOT/harness/lib/automerge.sh"; felix_automerge_streak "$1" ); }

is "no history is no streak" "$(_streak "")" "0"
is "all clean counts them all" \
   "$(_streak "$(printf '9\tclean\ta\n8\tclean\tb\n7\tclean\tc')")" "3"
# Consecutive, from the head. A red run in the middle is not something to count
# past: the question is whether the rules have been right lately, not often.
is "a red run breaks the streak" \
   "$(_streak "$(printf '9\tclean\ta\n8\tdirty\tb\n7\tclean\tc')")" "1"
is "and a red run at the head means zero" \
   "$(_streak "$(printf '9\tdirty\ta\n8\tclean\tb')")" "0"
# A number that arrived describing nothing is still not evidence. `gh run list`
# on a branch that no longer exists — which is every merged PR once the branch
# is deleted — returns [], and length of [] is 0, so "no runs found" read as
# "no failures" and counted toward switching auto-merge on.
_hist() { ( . "$FROOT/harness/lib/automerge.sh"; felix_automerge_state "$1" "$2" ); }
is "no runs at all is unknown, not clean" "$(_hist 0 0)" "unknown"
is "runs that all passed are clean"       "$(_hist 4 0)" "clean"
is "runs with a failure are dirty"        "$(_hist 4 2)" "dirty"
is "an unreadable count is unknown"       "$(_hist '' '')" "unknown"

# The state that used to be missing. The failure count comes off the network,
# and an errored `gh run list` prints nothing — which `${failures:-0}` read as
# zero failures, so "could not find out" advanced the streak toward switching
# auto-merge on. A streak is a claim that CI agreed; silence is not agreement.
is "a run nobody could read does not count as clean" \
   "$(_streak "$(printf '9\tunknown\ta\n8\tclean\tb')")" "0"
is "and it stops the streak rather than being skipped past" \
   "$(_streak "$(printf '9\tclean\ta\n8\tunknown\tb\n7\tclean\tc')")" "1"

