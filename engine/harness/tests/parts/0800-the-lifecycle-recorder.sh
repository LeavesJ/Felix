printf '\nthe lifecycle recorder\n'
# Authored blind, against the contract the lead decided on 2026-09-21
# (docs/2026-09-21-where-felix-stands.md §6), before any recorder existed.
#
# The founder's ECC settings edit switches off session:start and
# stop:cost-tracker, and with them the only record anybody keeps of when a
# session started, resumed, cleared or compacted. Every direct-strength
# failure in the usage analysis was a handoff failure, and none of the
# per-session questions — resume after idle, an engine promoted mid-session,
# restart against continue — can be asked of a record that does not say which
# engine a session ran, at which HEAD, having read which handoff. So Felix
# keeps it: one append-only row per moment in <memory>/<project>/lifecycle.log,
# nine tab-separated fields, `-` wherever a field does not apply or cannot be
# read.
#
# The fixture is its own, and each part of it is there to make one assertion
# able to fail. The engine is a copy of this harness with a plugin.json whose
# version no release carries, so field 4 matches only if the hook read the
# engine it is running from. The HOME it runs under holds a registry naming
# felix at a different version, with another plugin's entry ahead of it, so
# the bound engine and the installed one cannot be mistaken for each other and
# still pass, and a reader that takes the first version in the file fails. The
# memory root is one nothing else in this suite writes to, so a row is counted
# rather than hoped for. And an expected value the fixture failed to produce
# fails its assertion instead of matching an empty field: an unimplemented
# recorder writes nothing, and nothing equals nothing.
LYE="$TMP/ly-engine"; mkdir -p "$LYE/.claude-plugin"; _copy_content "$REAL_HARNESS" "$LYE/harness"
cat > "$LYE/.claude-plugin/plugin.json" <<'EOF'
{
  "name": "felix",
  "description": "a fixture engine for the lifecycle recorder",
  "version": "7.7.7-ly",
  "author": { "name": "fixture" }
}
EOF
LYU="$TMP/ly-user"; mkdir -p "$LYU/.claude/plugins"
cat > "$LYU/.claude/plugins/installed_plugins.json" <<EOF
{
  "version": 2,
  "plugins": {
    "felixlike@elsewhere": [
      { "scope": "user", "installPath": "$TMP/ly-nowhere/1.1.1", "version": "1.1.1-other" }
    ],
    "felix@felix": [
      { "scope": "user", "installPath": "$TMP/ly-cache/felix/felix/8.8.8-ly", "version": "8.8.8-ly",
        "gitCommitSha": "0000000000000000000000000000000000000000" }
    ]
  }
}
EOF
LYH="$TMP/ly-home"; mkdir -p "$LYH/projects/ly"
printf '{\n  "name": "ly",\n  "gate": "true"\n}\n' > "$LYH/projects/ly/project.json"
printf '# ly\n' > "$LYH/projects/ly/CLAUDE.md"
LYM="$TMP/ly-memory"; mkdir -p "$LYM/ly"
LYLOG="$LYM/ly/lifecycle.log"; LYHF="$LYM/ly/SESSION_HANDOFF.md"
LYR="$TMP/ly-repo"; mkdir -p "$LYR"; LYR="$(cd "$LYR" && pwd -P)"
( _fx_cd "$LYR" && git init -q -b main && printf 'ly\n' > .felix && printf 'x\n' > README.md \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
LYHEAD="$(git -C "$LYR" rev-parse HEAD 2>/dev/null)"
[ -n "$LYHEAD" ] || LYHEAD="the-fixture-checkout-has-no-HEAD"

# The hook as a plugin runs it: payload on stdin, from the checkout, under the
# fixture's HOME, home and memory. Both streams, because a recorder that fails
# has only stderr to fail on.
_ly_ss() {   # payload [memory root] [directory]
  ( cd "${3:-$LYR}" && printf '%s' "$1" | HOME="$LYU" FELIX_HOME="$LYH" FELIX_MEMORY="${2:-$LYM}" \
      CLAUDE_PLUGIN_ROOT="$LYE" "$LYE/harness/hooks/session-start" 2>&1 )
}
_ly_cli()  { ( cd "$LYR" && HOME="$LYU" FELIX_HOME="$LYH" FELIX_MEMORY="$LYM" "$LYE/harness/felix" "$@" 2>&1 ); }
_ly_n()    { if [ -f "$1" ]; then wc -l < "$1" | tr -d ' '; else printf '0'; fi; }
_ly_last() { tail -n 1 "$1" 2>/dev/null; }
_ly_f()    { printf '%s\n' "$1" | awk -F'\t' -v i="$2" 'NR == 1 { print $i }'; }
_ly_nf()   { printf '%s\n' "$1" | awk -F'\t' 'NR == 1 { print NF }'; }
_ly_hash() { _lyh="$(git hash-object "$1" 2>/dev/null)"; printf '%s' "${_lyh:-the-fixture-has-no-file-to-hash}"; }
_ly_is()   { if [ -z "$3" ]; then bad "$1" "the fixture produced no expected value, so nothing was compared"
             else is "$1" "$2" "$3"; fi; }

# ------------------------------------------------------------- a startup ----
printf '# Handoff\n\nRegenerated 2026-09-21. Anything below is the state of the tree,\nnot a summary of intent.\n' > "$LYHF"
_lyho="$(_ly_hash "$LYHF")"
_lyb="$(_ly_n "$LYLOG")"
# Fourteen hours east of UTC, because the shape alone cannot tell UTC from a
# local clock with a Z on the end, and on a runner whose zone is UTC the two are
# the same string. A POSIX zone string, which needs no tz database, and the
# stamp has to fall between two UTC stamps taken either side of the start,
# compared as the digits of the one format all three share.
_lylo="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TZ=LYT-14 _ly_ss '{"session_id":"ly-start","transcript_path":"/fixture/transcripts/ly-start.jsonl","hook_event_name":"SessionStart","source":"startup"}' >/dev/null
_lyhi="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
_lyr="$(_ly_last "$LYLOG")"
is  "a startup appends exactly one row to the project's lifecycle.log" "$(( $(_ly_n "$LYLOG") - _lyb ))" "1"
is  "and the lifecycle row has nine tab-separated fields"               "$(_ly_nf "$_lyr")" "9"
_lyt="$(_ly_f "$_lyr" 1)"; _lytd="${_lyt//[!0-9]/}"; _lylod="${_lylo//[!0-9]/}"; _lyhid="${_lyhi//[!0-9]/}"
if [ "$(TZ=LYT-14 date +%Y%m%d%H)" = "$(date -u +%Y%m%d%H)" ]; then
  skip "lifecycle field 1 is a UTC ISO 8601 stamp, the format the other memory logs use" \
       "this machine's date ignores the zone string LYT-14, so UTC and a local clock read the same here"
elif grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' <<<"$_lyt" \
     && [ "$_lylod" -le "$_lytd" ] && [ "$_lytd" -le "$_lyhid" ]; then
  ok  "lifecycle field 1 is a UTC ISO 8601 stamp, the format the other memory logs use"
else
  bad "lifecycle field 1 is a UTC ISO 8601 stamp, the format the other memory logs use" \
      "stamp [$_lyt], written under TZ=LYT-14 between $_lylo and $_lyhi UTC"
fi
_ly_is "lifecycle field 2 is the SessionStart source, startup"  "$(_ly_f "$_lyr" 2)" "startup"
_ly_is "lifecycle field 3 is the payload's session id"          "$(_ly_f "$_lyr" 3)" "ly-start"
_ly_is "lifecycle field 4 is the engine running the hook, read from its own plugin.json" "$(_ly_f "$_lyr" 4)" "7.7.7-ly"
_ly_is "lifecycle field 5 is the version the Claude Code registry has installed for felix" "$(_ly_f "$_lyr" 5)" "8.8.8-ly"
_ly_is "lifecycle field 6 is the full sha of the checkout's HEAD" "$(_ly_f "$_lyr" 6)" "$LYHEAD"
_ly_is "lifecycle field 7 is git hash-object of the project's SESSION_HANDOFF.md" "$(_ly_f "$_lyr" 7)" "$_lyho"
_ly_is "lifecycle field 8 is the payload's transcript path"     "$(_ly_f "$_lyr" 8)" "/fixture/transcripts/ly-start.jsonl"
_ly_is "lifecycle field 9, the note, is - on a session row"     "$(_ly_f "$_lyr" 9)" "-"
if [ -f "$LYLOG" ] && [ -z "$(find "$LYR" -name lifecycle.log 2>/dev/null)" ]; then
  ok  "lifecycle.log is written under the memory root and nowhere in the checkout"
else
  bad "lifecycle.log is written under the memory root and nowhere in the checkout" \
      "memory: $([ -f "$LYLOG" ] && echo present || echo absent); tree: $(find "$LYR" -name lifecycle.log 2>/dev/null)"
fi

# Absent is `-`, from a handoff that is not there and from a payload that did
# not carry the field. Each row is picked out by its session id, or by being
# the one row this run added, so an older row cannot answer for it.
rm -f "$LYHF"
_ly_ss '{"session_id":"ly-nohandoff","source":"startup"}' >/dev/null
_lyr="$(_ly_last "$LYLOG")"
_ly_is "with no session handoff on disk, lifecycle field 7 is -" "$(_ly_f "$_lyr" 3):$(_ly_f "$_lyr" 7)" "ly-nohandoff:-"
_lyb="$(_ly_n "$LYLOG")"
_ly_ss '{"hook_event_name":"SessionStart","source":"startup"}' >/dev/null
_lyr="$(_ly_last "$LYLOG")"
_ly_is "a payload with no session_id or transcript_path writes - in lifecycle fields 3 and 8" \
       "$(( $(_ly_n "$LYLOG") - _lyb )):$(_ly_f "$_lyr" 2):$(_ly_f "$_lyr" 3):$(_ly_f "$_lyr" 8)" "1:startup:-:-"

# A raw tab inside a value is the one byte that would move every later field
# one column right. printf makes it a real tab here, not the two characters a
# JSON encoder would write, because a real one is what the recorder must
# replace.
_lyp="$(printf '{"session_id":"ly-tab","transcript_path":"/fixture/t/a\tb.jsonl","source":"startup"}')"
_lyb="$(_ly_n "$LYLOG")"
_ly_ss "$_lyp" >/dev/null
_lyr="$(_ly_last "$LYLOG")"
case "$(( $(_ly_n "$LYLOG") - _lyb )):$(_ly_nf "$_lyr"):$(_ly_f "$_lyr" 3):$(_ly_f "$_lyr" 9)|$(_ly_f "$_lyr" 8)" in
  "1:9:ly-tab:-|/fixture/t/a"*"b.jsonl")
    ok  "a transcript path holding a tab still leaves nine lifecycle fields, the path kept whole in field 8" ;;
  *) bad "a transcript path holding a tab still leaves nine lifecycle fields, the path kept whole in field 8" "row [$_lyr]" ;;
esac

# --------------------------------------------- resume, clear and compact ----
# A resume is the moment the matcher was widened for, and it must stay
# silent: the row is written above the exit, the banner is not.
printf '# Handoff\n\nRegenerated 2026-09-21. Anything below is the state of the tree,\nnot a summary of intent.\n' > "$LYHF"
_lyho="$(_ly_hash "$LYHF")"
_lyb="$(_ly_n "$LYLOG")"
out="$(_ly_ss '{"session_id":"ly-resume","transcript_path":"/fixture/transcripts/ly-resume.jsonl","hook_event_name":"SessionStart","source":"resume"}')"; rc=$?
_lyr="$(_ly_last "$LYLOG")"
_ly_is "a resume appends one lifecycle row of kind resume, and the hook prints nothing at all and exits 0" \
       "$(( $(_ly_n "$LYLOG") - _lyb )):$(_ly_f "$_lyr" 2):$(_ly_f "$_lyr" 3):${#out}:$rc" "1:resume:ly-resume:0:0"
_ly_is "and the resume row names the engine, the installed engine, the HEAD, the handoff and the transcript" \
       "$(_ly_f "$_lyr" 4):$(_ly_f "$_lyr" 5):$(_ly_f "$_lyr" 6):$(_ly_f "$_lyr" 7):$(_ly_f "$_lyr" 8)" \
       "7.7.7-ly:8.8.8-ly:$LYHEAD:$_lyho:/fixture/transcripts/ly-resume.jsonl"
# Copilot CLI never had a silent resume, so its banner stays; the row is
# written for every source all the same.
_lyb="$(_ly_n "$LYLOG")"
out="$(cd "$LYR" && printf '%s' '{"source":"resume"}' | COPILOT_CLI=1 HOME="$LYU" FELIX_HOME="$LYH" FELIX_MEMORY="$LYM" \
       "$LYE/harness/hooks/session-start" 2>&1)"
_lyr="$(_ly_last "$LYLOG")"
case "$out" in *"Project: ly"*) _lyban=banner ;; *) _lyban=silent ;; esac
_ly_is "a Copilot resume, which keeps its banner, appends a lifecycle row of kind resume too" \
       "$(( $(_ly_n "$LYLOG") - _lyb )):$(_ly_f "$_lyr" 2):$_lyban" "1:resume:banner"
for _lyk in clear compact; do
  _lyb="$(_ly_n "$LYLOG")"
  _ly_ss "{\"session_id\":\"ly-$_lyk\",\"source\":\"$_lyk\"}" >/dev/null
  _lyr="$(_ly_last "$LYLOG")"
  _ly_is "a $_lyk appends one lifecycle row of kind $_lyk" \
         "$(( $(_ly_n "$LYLOG") - _lyb )):$(_ly_f "$_lyr" 2):$(_ly_f "$_lyr" 3)" "1:$_lyk:ly-$_lyk"
done

# Claude Code sends its payload as one line, but the hook reads whatever is on
# stdin, and Copilot CLI and Cursor reach the same read. The first line that
# carries a field answers for it, so every line after that must cost nothing.
# A parse that walked every matched line cut each one off the front of a
# string that was still most of the payload, which is quadratic in bash 3.2:
# review measured 11 seconds at 5,000 lines, and a kill at 100 seconds at
# 20,000, and past the platform's 60-second deadline a startup loses its
# banner. Thirty thousand lines here, under a watchdog that ends the hook at
# thirty seconds so that a red run cannot leave it spinning.
_lymp="$TMP/ly-many.json"
{ printf '{"session_id":"ly-many","transcript_path":"/fixture/t/many.jsonl","source":"resume",\n'
  awk 'BEGIN { for (i = 0; i < 30000; i++) print "  \"source\": \"startup\"," }'
  printf '  "end": 0\n}\n'; } > "$_lymp"
_lyb="$(_ly_n "$LYLOG")"
( cd "$LYR" && HOME="$LYU" FELIX_HOME="$LYH" FELIX_MEMORY="$LYM" CLAUDE_PLUGIN_ROOT="$LYE" \
    exec "$LYE/harness/hooks/session-start" < "$_lymp" > "$TMP/ly-many.out" 2>&1 ) &
_lypid=$!; _lyi=0
while kill -0 "$_lypid" 2>/dev/null && [ "$_lyi" -lt 300 ]; do sleep 0.1; _lyi=$((_lyi + 1)); done
if kill -0 "$_lypid" 2>/dev/null; then kill "$_lypid" 2>/dev/null; _lyend=killed; else _lyend=finished; fi
wait "$_lypid" 2>/dev/null
_lyr="$(_ly_last "$LYLOG")"
_ly_is "a payload of 30,000 lines carrying source is answered by its first, recorded inside thirty seconds, and the resume stays silent" \
       "$_lyend:$(( $(_ly_n "$LYLOG") - _lyb )):$(_ly_f "$_lyr" 2):$(_ly_f "$_lyr" 3):$(wc -c < "$TMP/ly-many.out" | tr -d ' ')" \
       "finished:1:resume:ly-many:0"

# A marker nobody can read is a broken binding, and a resume never said a word
# about one: it left before the report, and before the resolve. The recorder
# resolves above that exit now, and stderr is output too.
LYX="$TMP/ly-unreadable"; mkdir -p "$LYX"; LYX="$(cd "$LYX" && pwd -P)"
( _fx_cd "$LYX" && git init -q -b main && printf 'ly\n' > .felix ) >/dev/null 2>&1
chmod 000 "$LYX/.felix"
if [ -r "$LYX/.felix" ]; then
  skip "a resume where the marker cannot be read prints nothing on either stream, records nothing and exits 0" \
       "this user can read a file of mode 000"
else
  _lyb="$(_ly_n "$LYLOG")"
  out="$(_ly_ss '{"session_id":"ly-unreadable","source":"resume"}' "$LYM" "$LYX")"; rc=$?
  _ly_is "a resume where the marker cannot be read prints nothing on either stream, records nothing and exits 0" \
         "$rc:$(( $(_ly_n "$LYLOG") - _lyb )):[$out]" "0:0:[]"
fi
chmod 644 "$LYX/.felix"

# Append-only: the second start adds a row after the first and rewrites none
# of the bytes that were there before either of them.
cp "$LYLOG" "$TMP/ly-before-one" 2>/dev/null || : > "$TMP/ly-before-one"
_lyb="$(_ly_n "$LYLOG")"
_ly_ss '{"session_id":"ly-one","source":"startup"}' >/dev/null
cp "$LYLOG" "$TMP/ly-after-one" 2>/dev/null || : > "$TMP/ly-after-one"
_ly_ss '{"session_id":"ly-two","source":"startup"}' >/dev/null
_lyids="$(tail -n 2 "$LYLOG" 2>/dev/null | awk -F'\t' '{ printf "%s ", $3 }')"
_lys0="$(wc -c < "$TMP/ly-before-one" | tr -d ' ')"; _lys1="$(wc -c < "$TMP/ly-after-one" | tr -d ' ')"
if [ "$(( $(_ly_n "$LYLOG") - _lyb ))" = 2 ] && [ "$_lyids" = "ly-one ly-two " ] && [ "$_lys1" -gt "$_lys0" ] \
   && head -c "$_lys0" "$LYLOG" 2>/dev/null | cmp -s - "$TMP/ly-before-one" \
   && head -c "$_lys1" "$LYLOG" 2>/dev/null | cmp -s - "$TMP/ly-after-one"; then
  ok  "two session starts append two lifecycle rows in order and rewrite none of the bytes before them"
else
  bad "two session starts append two lifecycle rows in order and rewrite none of the bytes before them" \
      "added $(( $(_ly_n "$LYLOG") - _lyb )), last two ids [$_lyids]"
fi

# -------------------------------------------------------------- the HEAD ----
# Three answers and they mean different things: a sha, a repository with no
# commit yet, and a directory git cannot say anything about.
LYN="$TMP/ly-unborn"; mkdir -p "$LYN"; LYN="$(cd "$LYN" && pwd -P)"
( _fx_cd "$LYN" && git init -q -b main && printf 'ly\n' > .felix ) >/dev/null 2>&1
_ly_ss '{"session_id":"ly-unborn","source":"startup"}' "$LYM" "$LYN" >/dev/null
_lyr="$(_ly_last "$LYLOG")"
_ly_is "a checkout with no commit yet records its HEAD as unborn" "$(_ly_f "$_lyr" 3):$(_ly_f "$_lyr" 6)" "ly-unborn:unborn"
LYG="$TMP/ly-nogit"; mkdir -p "$LYG"; LYG="$(cd "$LYG" && pwd -P)"; printf 'ly\n' > "$LYG/.felix"
if git -C "$LYG" rev-parse --git-dir >/dev/null 2>&1; then
  skip "a governed directory that is not a git checkout records its HEAD as -, not unborn" "the temporary directory sits inside a git checkout"
else
  _ly_ss '{"session_id":"ly-nogit","source":"startup"}' "$LYM" "$LYG" >/dev/null
  _lyr="$(_ly_last "$LYLOG")"
  _ly_is "a governed directory that is not a git checkout records its HEAD as -, not unborn" \
         "$(_ly_f "$_lyr" 3):$(_ly_f "$_lyr" 6)" "ly-nogit:-"
fi

# ------------------------------------------------ bound against installed ----
# Felix also runs as a plain settings.json hook, where CLAUDE_PLUGIN_ROOT is
# unset; the engine executing is the same engine, so the answer is too.
( cd "$LYR" && printf '%s' '{"session_id":"ly-plainhook","source":"startup"}' \
    | env -u CLAUDE_PLUGIN_ROOT HOME="$LYU" FELIX_HOME="$LYH" FELIX_MEMORY="$LYM" \
      "$LYE/harness/hooks/session-start" >/dev/null 2>&1 )
_lyr="$(_ly_last "$LYLOG")"
_ly_is "as a plain settings.json hook, with no CLAUDE_PLUGIN_ROOT, the lifecycle row still names its own engine" \
       "$(_ly_f "$_lyr" 3):$(_ly_f "$_lyr" 4)" "ly-plainhook:7.7.7-ly"
# The suite's own fixture engine has no plugin.json beside it. Its honest
# bound engine is `-`, and the registry's version is exactly the wrong guess:
# the whole point of two columns is a session running something other than
# what is promoted.
if [ -e "$FROOT/.claude-plugin/plugin.json" ]; then
  skip "an engine with no plugin.json of its own records - as the bound engine, never the registry's version" \
       "the suite's fixture engine has a plugin.json"
else
  ( cd "$LYR" && printf '%s' '{"session_id":"ly-unbound","source":"startup"}' \
      | env -u CLAUDE_PLUGIN_ROOT HOME="$LYU" FELIX_HOME="$LYH" FELIX_MEMORY="$LYM" \
        "$FROOT/harness/hooks/session-start" >/dev/null 2>&1 )
  _lyr="$(_ly_last "$LYLOG")"
  _ly_is "an engine with no plugin.json of its own records - as the bound engine, never the registry's version" \
         "$(_ly_f "$_lyr" 3):$(_ly_f "$_lyr" 4):$(_ly_f "$_lyr" 5)" "ly-unbound:-:8.8.8-ly"
fi
LYB="$TMP/ly-bare-user"; mkdir -p "$LYB"
( cd "$LYR" && printf '%s' '{"session_id":"ly-noregistry","source":"startup"}' \
    | HOME="$LYB" FELIX_HOME="$LYH" FELIX_MEMORY="$LYM" CLAUDE_PLUGIN_ROOT="$LYE" \
      "$LYE/harness/hooks/session-start" >/dev/null 2>&1 )
_lyr="$(_ly_last "$LYLOG")"
_ly_is "with no Claude Code registry in HOME, the installed engine is - and the bound one is still read" \
       "$(_ly_f "$_lyr" 3):$(_ly_f "$_lyr" 4):$(_ly_f "$_lyr" 5)" "ly-noregistry:7.7.7-ly:-"

# ------------------------------------------------- where nothing is written ----
# Ungoverned is silent on disk as well as on screen. Checked against a fresh
# memory root that a governed start is then shown to write into, so the
# absence is of a row and not of a recorder.
LYP="$TMP/ly-plain"; mkdir -p "$LYP"; LYP="$(_fx_cd "$LYP" && pwd -P)"; ( _fx_cd "$LYP" && git init -q -b main ) >/dev/null 2>&1
LYUM="$TMP/ly-memory-ungoverned"; mkdir -p "$LYUM/ly"
for _lyk in startup resume clear; do
  _ly_ss "{\"session_id\":\"ly-ungoverned\",\"source\":\"$_lyk\"}" "$LYUM" "$LYP" >/dev/null
done
_lyfound="$(find "$LYUM" "$LYP" -name lifecycle.log 2>/dev/null)"
_ly_ss '{"session_id":"ly-governed","source":"startup"}' "$LYUM" >/dev/null
if [ -z "$_lyfound" ] && [ -f "$LYUM/ly/lifecycle.log" ]; then
  ok  "an ungoverned directory writes no lifecycle.log, under the memory root or in its tree, where a governed start does"
else
  bad "an ungoverned directory writes no lifecycle.log, under the memory root or in its tree, where a governed start does" \
      "ungoverned wrote [$_lyfound]; the governed start wrote $([ -f "$LYUM/ly/lifecycle.log" ] && echo a log || echo nothing)"
fi

# A recorder that cannot write says nothing and changes nothing. The banner is
# compared with the one the same start printed while the directory was
# writable, after two warm-up starts so that first-run adoption has settled,
# and the log is taken away first so that the locked run must create it and
# cannot. Controls both: today nothing writes here, so they pass; they are
# for the day something does.
LYW="$TMP/ly-memory-locked"; mkdir -p "$LYW/ly"; cp "$LYHF" "$LYW/ly/SESSION_HANDOFF.md"
_lywp='{"session_id":"ly-locked","source":"startup"}'
_ly_ss "$_lywp" "$LYW" >/dev/null; _ly_ss "$_lywp" "$LYW" >/dev/null
_lybase="$(_ly_ss "$_lywp" "$LYW")"; _lybrc=$?
rm -f "$LYW/ly/lifecycle.log"; chmod 555 "$LYW/ly"
if [ -w "$LYW/ly" ]; then
  skip "a memory directory the recorder cannot write leaves the hook's exit 0 and its banner as it was" \
       "this user can write a directory of mode 555"
else
  out="$(_ly_ss "$_lywp" "$LYW")"; rc=$?
  if [ "$rc" = 0 ] && [ "$_lybrc" = 0 ] && [ -n "$_lybase" ] && [ "$out" = "$_lybase" ] && [ ! -e "$LYW/ly/lifecycle.log" ]; then
    ok  "a memory directory the recorder cannot write leaves the hook's exit 0 and its banner as it was"
  else
    bad "a memory directory the recorder cannot write leaves the hook's exit 0 and its banner as it was" \
        "exit $rc (writable: $_lybrc); $([ "$out" = "$_lybase" ] && echo 'same output' || printf 'output now [%s]' "$out")"
  fi
fi
chmod 755 "$LYW/ly"
# A directory where the log should be refuses the append for every user,
# root included, so this one cannot be skipped.
mkdir -p "$LYW/ly/lifecycle.log"
out="$(_ly_ss '{"session_id":"ly-locked","source":"resume"}' "$LYW")"; rc=$?
_lyo2="$(_ly_ss "$_lywp" "$LYW")"; _lyrc2=$?
if [ "$rc:${#out}" = "0:0" ] && [ "$_lyrc2" = 0 ] && [ -n "$_lybase" ] && [ "$_lyo2" = "$_lybase" ]; then
  ok  "a lifecycle.log that cannot be appended to leaves a resume silent, a startup's banner unchanged, and both exiting 0"
else
  bad "a lifecycle.log that cannot be appended to leaves a resume silent, a startup's banner unchanged, and both exiting 0" \
      "resume exit $rc printed [$out]; startup exit $_lyrc2 $([ "$_lyo2" = "$_lybase" ] && echo 'same banner' || printf 'printed [%s]' "$_lyo2")"
fi
rmdir "$LYW/ly/lifecycle.log" 2>/dev/null

# -------------------------------------------------------- felix handoff ----
# The handoff row is the other half of the join: the hash it records is the
# hash the next session start reads, which is how an evaluation learns which
# handoff a session was handed. Written, replaced and refused are the three
# reasons, and a refusal is a row too, hashed over the file it left alone.
rm -f "$LYHF"
_lyb="$(_ly_n "$LYLOG")"
_ly_cli handoff --was "first write, for the recorder" >/dev/null; rc=$?
_lyr="$(_ly_last "$LYLOG")"; _lyho="$(_ly_hash "$LYHF")"
_ly_is "felix handoff appends one lifecycle row of kind handoff, noted written, with the hash of the file it wrote" \
       "$rc:$(( $(_ly_n "$LYLOG") - _lyb )):$(_ly_nf "$_lyr"):$(_ly_f "$_lyr" 2):$(_ly_f "$_lyr" 9):$(_ly_f "$_lyr" 7)" \
       "0:1:9:handoff:written:$_lyho"
# Each of the next two stands on its own. The last row is a handoff row only if
# the handoff wrote one, since a startup row carries the same engine and HEAD;
# and the hash compared is the one the handoff row holds, not a fresh hash of
# a file the handoff writes whether or not it records.
_ly_is "and the handoff row names the engine that wrote it and the checkout's HEAD" \
       "$(( $(_ly_n "$LYLOG") - _lyb )):$(_ly_f "$_lyr" 2):$(_ly_f "$_lyr" 4):$(_ly_f "$_lyr" 6)" "1:handoff:7.7.7-ly:$LYHEAD"
_lyh7=""; [ "$(_ly_f "$_lyr" 2)" = handoff ] && _lyh7="$(_ly_f "$_lyr" 7)"
_ly_ss '{"session_id":"ly-after-handoff","source":"startup"}' >/dev/null
_lyr="$(_ly_last "$LYLOG")"
if [ -z "$_lyh7" ]; then
  bad "the next session start records the same handoff hash the handoff row did" \
      "the handoff wrote no handoff row, so there is no hash of its own to compare"
else
  _ly_is "the next session start records the same handoff hash the handoff row did" \
         "$(_ly_f "$_lyr" 3):$(_ly_f "$_lyr" 7)" "ly-after-handoff:$_lyh7"
fi
printf '# Notes kept by hand\n\nNothing here was regenerated, and it is the only copy.\n' > "$LYHF"
cp "$LYHF" "$TMP/ly-hand.keep"; _lyhh="$(_ly_hash "$LYHF")"
_lyb="$(_ly_n "$LYLOG")"
_ly_cli handoff "an overwrite nobody asked for" >/dev/null; rc=$?
_lyr="$(_ly_last "$LYLOG")"
if [ "$rc" -ne 0 ] && cmp -s "$LYHF" "$TMP/ly-hand.keep"; then
  _ly_is "a refused handoff appends a lifecycle row noted refused, with the hash of the file it left alone" \
         "$(( $(_ly_n "$LYLOG") - _lyb )):$(_ly_nf "$_lyr"):$(_ly_f "$_lyr" 2):$(_ly_f "$_lyr" 9):$(_ly_f "$_lyr" 7)" \
         "1:9:handoff:refused:$_lyhh"
else
  bad "a refused handoff appends a lifecycle row noted refused, with the hash of the file it left alone" \
      "the refusal itself did not happen: exit $rc, the file $(cmp -s "$LYHF" "$TMP/ly-hand.keep" && echo kept || echo changed)"
fi
_lyb="$(_ly_n "$LYLOG")"
_ly_cli handoff --was "taken over on purpose" --replace >/dev/null; rc=$?
_lyr="$(_ly_last "$LYLOG")"; _lyho="$(_ly_hash "$LYHF")"
[ "$_lyho" != "$_lyhh" ] && _lych=changed || _lych=unchanged
_ly_is "felix handoff --replace over a hand-written handoff appends a row noted replaced, with the hash of what replaced it" \
       "$rc:$_lych:$(( $(_ly_n "$LYLOG") - _lyb )):$(_ly_f "$_lyr" 2):$(_ly_f "$_lyr" 9):$(_ly_f "$_lyr" 7)" \
       "0:changed:1:handoff:replaced:$_lyho"

# ------------------------------------------------------------ the header ----
# A new store before the table validator was an exception to rows-first, taken
# dated in the file that holds it, and closed when its schema row landed. The
# header is the comment block above the first function, read as one line so a
# sentence may wrap anywhere. Phrases, each inside one sentence, and not words
# found anywhere: a header that denied the exception used every one of them.
_lyhdr="$(awk '/^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)/ { exit }
               /^#/ { sub(/^#[[:space:]]*/, ""); printf "%s ", $0 }' "$FROOT/harness/lib/lifecycle.sh" 2>/dev/null | tr -s ' ')"
_lymiss=""
for _lyw in 'dated exception to rows-first[^.]*2026-09-21[^.]*closed 2026-09-22' 'schema row is[^.]* in templates/schemas\.tsv'; do
  grep -qiE -- "$_lyw" <<<"$_lyhdr" || _lymiss="$_lymiss [$_lyw]"
done
if [ -n "$_lyhdr" ] && [ -z "$_lymiss" ]; then
  ok  "lib/lifecycle.sh dates its exception to rows-first, taken 2026-09-21 and closed 2026-09-22, and says its row is in schemas.tsv"
else
  bad "lib/lifecycle.sh dates its exception to rows-first, taken 2026-09-21 and closed 2026-09-22, and says its row is in schemas.tsv" \
      "$([ -f "$FROOT/harness/lib/lifecycle.sh" ] && printf 'header lacks%s' "$_lymiss" || echo 'no lib/lifecycle.sh')"
fi
# And the row says what the header says: the nine names, in order. The header
# lists them as `#   <n> <name>` lines; the row lists them in its third cell.
_lyhdrcols="$(awk '/^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)/ { exit }
                   /^#[[:space:]]+[0-9]+ [a-z]+[[:space:]]/ { print $3 }' "$FROOT/harness/lib/lifecycle.sh" 2>/dev/null | tr '\n' ' ' | sed 's/ $//')"
_lyrowcols="$(awk -F'\t' '$1 == "lifecycle.log" { print $3 }' "$FROOT/harness/templates/schemas.tsv" 2>/dev/null)"
is "the lifecycle.log schema row names the nine columns lib/lifecycle.sh documents, in order" \
   "$_lyrowcols" "$_lyhdrcols"

# The contract puts the record above the resume exit, and the hook has a
# comment that says where the record sits. Both are positions in one file, so
# both are read: the call before the exit, and every comment that says the
# record sits above its own line placed between the two, where that is true.
_lyss="$FROOT/harness/hooks/session-start"
_lycall="$(grep -n '^[^#]*felix_lifecycle_session ' "$_lyss" 2>/dev/null | head -n 1 | cut -d: -f1)"
_lyexit="$(grep -n '^\[ "\$_felix_source" = "resume" \]' "$_lyss" 2>/dev/null | head -n 1 | cut -d: -f1)"
_lysays="$(grep -n '^#.*sits above' "$_lyss" 2>/dev/null | cut -d: -f1 | tr '\n' ' ')"
_lypos=""
if [ -n "$_lycall" ] && [ -n "$_lyexit" ] && [ -n "$_lysays" ] && [ "$_lycall" -lt "$_lyexit" ]; then
  for _lyl in $_lysays; do
    { [ "$_lyl" -gt "$_lycall" ] && [ "$_lyl" -lt "$_lyexit" ]; } || _lypos="$_lypos $_lyl"
  done
else
  _lypos=" (no call above the exit, or no comment placing it)"
fi
if [ -z "$_lypos" ]; then
  ok  "hooks/session-start records above the resume exit, and its comment saying the record sits above sits between the two"
else
  bad "hooks/session-start records above the resume exit, and its comment saying the record sits above sits between the two" \
      "call at line ${_lycall:-none}, exit at ${_lyexit:-none}; misplaced:$_lypos"
fi
# ------------------------------------------------------- cheap to try ----
# Two ways to try Felix that cost nothing: a read-only report over the
# transcripts Claude Code already keeps, run from a plain clone with nothing
# installed, and a felix new that governs a project without commissioning it.
# Written blind, from the spec alone, before either existed.

