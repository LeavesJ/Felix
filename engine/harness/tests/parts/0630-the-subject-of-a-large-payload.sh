printf '\nthe subject of a large payload\n'
# felix_deny_subject reads a small payload with parameter expansion and a large
# one with one awk, because ${s//pat/rep} in bash 3.2 is not linear. Measured
# 2026-09-23 on 3.2.57, the bash the hook runs under on macOS: a 31K
# commit-template payload took 12 to 13 s to read, a 9K `python3 -c` one 19 s,
# and a 45K one did not finish in 110 s, against Claude Code's 60 s hook
# timeout. Two readings of one thing are safe only if size never changes the
# answer, so each case is read both ways and held to one expected subject.
_subj() {  # _subj <inline limit> <tool> <payload>
  ( . "$FROOT/harness/lib/deny.sh"; _FELIX_DENY_INLINE="$1"; felix_deny_subject "$3" "$2" )
}
_both() {  # _both <name> <tool> <payload> <expected>
  is "$1" "$(_subj 0 "$2" "$3")|$(_subj 999999999 "$2" "$3")" "$4|$4"
}
_both "read by awk and by expansion alike: escaped quotes are the value's own" Bash \
  '{"tool_input":{"command":"echo \"a b\" | grep \"c\"","description":"d"}}' 'echo "a b" | grep "c"'
_both "read by awk and by expansion alike: an escaped quote does not carry the value into the next field" Bash \
  '{"tool_input":{"command":"say \"hi\"","description":"git add -A"}}' 'say "hi"'
_both "read by awk and by expansion alike: the first occurrence of the field wins" Edit \
  '{"tool_input":{"file_path":"/w/README.md"},"related":{"file_path":"/w/.env"}}' '/w/README.md'
_both "read by awk and by expansion alike: a value ending on an escaped quote" Bash \
  '{"tool_input":{"command":"echo \""}}' 'echo "'
_both "read by awk and by expansion alike: a value opening on an escaped quote" Bash \
  '{"tool_input":{"command":"\"x\" y"}}' '"x" y'
_both "read by awk and by expansion alike: an empty value is empty" Bash \
  '{"tool_input":{"command":"","description":"x"}}' ''
_both "read by awk and by expansion alike: every other JSON escape is left as written" Bash \
  '{"tool_input":{"command":"a\nb\tc\\d\/e"}}' 'a\nb\tc\\d\/e'
_both "read by awk and by expansion alike: a line break in the value is kept, beside escaped quotes" Bash \
  $'{"tool_input":{"command":"a \\"b\nc\\" d"}}' $'a "b\nc" d'
_both "read by awk and by expansion alike: a value with no closing quote runs to the end" Bash \
  '{"tool_input":{"command":"abc' 'abc'
_both "read by awk and by expansion alike: space round the colon" Bash \
  '{"tool_input":{"command" : "x y"}}' 'x y'
# Two of 44 cases derived blind from the contract alone, kept here because
# they are where awks differ, and CI reads them with another awk than macOS:
# bytes that are not UTF-8, and CRs, taken as they are; three backslashes
# before a quote, which lose one.
_both "read by awk and by expansion alike: bytes that are not UTF-8, and CRs, are kept as they are" Bash \
  $'{"tool_input":{"command":"caf\xc3\xa9 \xe9\xff\xfe \\"x\\"\r\\"y\\"\r\xc3","description":"d"}}' \
  $'caf\xc3\xa9 \xe9\xff\xfe "x"\r"y"\r\xc3'
_both "read by awk and by expansion alike: three backslashes before a quote lose one" Bash \
  '{"tool_input":{"command":"a\\\"b\\\"","description":"d"}}' 'a\\"b\\"'
# A quote after an escaped backslash ends a JSON string, and the expansion
# reads it as escaped: it looks only at the character before each quote. The
# awk does the same on purpose, so that where the reading is loose, it is
# loose the same way whatever the size.
is "a value ending on an escaped backslash is read the same both ways" \
   "$(_subj 0 Bash '{"tool_input":{"command":"echo a\\","description":"b"}}')" \
   "$(_subj 999999999 Bash '{"tool_input":{"command":"echo a\\","description":"b"}}')"
# A raw \001 is not JSON, and it is the expansion's own placeholder, so it
# read as a quote there and as itself in the awk. Neither reads it now.
_soh="$(printf '\001')"
_soh="{\"tool_input\":{\"command\":\"a${_soh}b\",\"description\":\"d\"}}"
_both "read by awk and by expansion alike: a payload holding a raw SOH byte, which JSON cannot, has no subject" Bash \
  "$_soh" ''

# What each reading costs. The expansion runs on nearly every call, and a
# program started there is a tax on the whole session, so a small payload
# must run no awk. A large one is read by exactly one, whatever it holds.
_AWKN="$TMP/awk-calls"; mkdir -p "$TMP/awkshim" "$TMP/awkfail"
printf '#!/bin/sh\nprintf x >> "%s"\nexec "%s" "$@"\n' "$_AWKN" "$(command -v awk)" > "$TMP/awkshim/awk"
chmod +x "$TMP/awkshim/awk"
_awkn() {  # _awkn <payload>: how many awk processes reading its subject took
  : > "$_AWKN"
  ( . "$FROOT/harness/lib/deny.sh"; PATH="$TMP/awkshim:$PATH"; felix_deny_subject "$1" Bash >/dev/null )
  wc -c < "$_AWKN" | tr -d ' '
}
is "a small payload's subject is read without running awk" \
   "$(_awkn '{"tool_name":"Bash","tool_input":{"command":"git status --short"}}')" "0"
# Built into a variable first: in bash 3.2 a quoted {..,..} inside "$( )"
# is brace-expanded, and the payload arrives as `"tool_name":"Bash"`.
_mid="$(awk 'BEGIN { for (i = 0; i < 200; i++) printf "echo \\\"%d\\\" ; ", i }')"
_mid="{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$_mid\"}}"
is "a large payload's subject is read by exactly one awk" "$(_awkn "$_mid")" "1"
# Fails open, and never on part of a command: a row anchored at the end can
# refuse the part an awk printed before it died, where the whole command
# would not match. An awk that fails reads as no subject.
printf '#!/bin/sh\ncat >/dev/null\nprintf "git add -A"\nexit 2\n' > "$TMP/awkfail/awk"
chmod +x "$TMP/awkfail/awk"
is "a large payload whose awk fails part way has no subject, rather than the part it printed" \
   "$( . "$FROOT/harness/lib/deny.sh"; PATH="$TMP/awkfail:$PATH"; felix_deny_subject "$_mid" Bash )" ""

# A watchdog ends the whole tree it started: the awk is a grandchild of the
# hook, and ending the direct children alone leaves it running.
_killtree() { local c; for c in $(pgrep -P "$1" 2>/dev/null); do _killtree "$c"; done; kill "$1" 2>/dev/null; }

# Linear, and not only fast at one size. A reading with a gsub in it is
# quadratic in BWK awk and still passes a deadline at 220K: measured 0.22 s
# there, and 15.7 s at 2M. So the CPU time of one reading, taken inside the
# subshell so that neither load nor the watchdog's polling adds to it, for a
# payload and one four times its size: linear is about four times, quadratic
# sixteen. Under a watchdog at thirty seconds, for the expansion's sake.
_lin() {  # _lin <units>: CPU ms for one reading of that many 22-byte units, or killed
  local f="$TMP/lin-$1.json" i=0 pid
  { printf '{"tool_name":"Bash","tool_input":{"command":"'
    awk -v n="$1" 'BEGIN { for (i = 0; i < n; i++) printf "printf \\\"%%s\\\" \\\"a\\\" ; " }'
    printf 'true"}}'; } > "$f"
  ( . "$FROOT/harness/lib/deny.sh"; raw="$(cat "$f")"
    felix_deny_subject "$raw" Bash >/dev/null; times > "$f.cpu" ) &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$i" -lt 300 ]; do sleep 0.1; i=$((i + 1)); done
  if kill -0 "$pid" 2>/dev/null; then _killtree "$pid"; wait "$pid" 2>/dev/null; echo killed; return; fi
  wait "$pid" 2>/dev/null
  # times: the subshell's user and system time, then its children's, as 0m1.234s.
  awk '{ for (i = 1; i <= NF; i++) { split($i, t, "m"); sub(/s$/, "", t[2]); ms += (t[1] * 60 + t[2]) * 1000 } }
       END { printf "%d", ms }' "$f.cpu"
  rm -f "$f" "$f.cpu"
}
_l1="$(_lin 12000)"
if [ "$_l1" = killed ]; then _lv="264K was not read in thirty seconds"; else
  _l4="$(_lin 48000)"
  if [ "$_l4" = killed ]; then _lv="1M was not read in thirty seconds"
  elif [ "$_l4" -lt $((_l1 * 8)) ]; then _lv=linear
  else _lv="264K took ${_l1} ms and 1M ${_l4} ms"; fi
fi
is "reading a large payload's subject is linear: four times the payload costs under eight times the CPU" "$_lv" "linear"

# The reason for all of it, as deadlines through the hook, refused well
# inside Claude Code's 60 s. Each under a watchdog that ends the hook and
# everything under it at twenty seconds, since the expansion on these
# payloads runs for minutes or days, and a red run is exactly where it would.
#
# A refused Bash command is read a second time, by felix_deny_code, at about
# 12 us a character (2.3 s of CPU for 200K, measured 2026-09-23), and a
# deadline on a large one would be measuring that. So the Bash command is
# 44K, where the expansion took 102 s of CPU, and the large payload is a
# Write: the expansion read everything after the key, a Write's content
# included.
_hook_within() {  # _hook_within <payload file>: finished:<exit> or killed:<exit>
  local pid i=0 end
  ( cd "$REPO" && exec "$FROOT/harness/hooks/pre-tool" < "$1" 2>/dev/null ) &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$i" -lt 200 ]; do sleep 0.1; i=$((i + 1)); done
  if kill -0 "$pid" 2>/dev/null; then _killtree "$pid"; end=killed; else end=finished; fi
  wait "$pid" 2>/dev/null
  printf '%s:%s' "$end" "$?"
}
{ printf 'Bash\tgit add (-A|--all|\\.)$\tstage explicit paths\n'
  printf 'Write\t\\.lock$\ta lockfile is written by its tool\n'; } > "$FROOT/projects/widget/deny.tsv"
_big="$TMP/deny-big.json"
{ printf '{"session_id":"deny-big","tool_name":"Bash","tool_input":{"command":"'
  awk 'BEGIN { for (i = 0; i < 2000; i++) printf "printf \\\"%%s\\\" \\\"a\\\" ; " }'
  printf 'git add -A","description":"d"},"tool_use_id":"t"}'; } > "$_big"
is "a 44K command with 8,000 escaped quotes is refused through the hook inside twenty seconds" \
   "$(_hook_within "$_big")" "finished:2"
{ printf '{"session_id":"deny-big","tool_name":"Write","tool_input":{"file_path":"/w/uv.lock","content":"'
  awk 'BEGIN { for (i = 0; i < 10000; i++) printf (i % 20 ? "printf %%s aaaaaaa ; " : "printf \\\"%%s\\\" \\\"a\\\" ; ") }'
  printf '"},"tool_use_id":"t"}'; } > "$_big"
is "a 200K Write holding 2,000 escaped quotes is refused on its path through the hook inside twenty seconds" \
   "$(_hook_within "$_big")" "finished:2"
rm -f "$FROOT/projects/widget/deny.tsv" "$_big"

printf '\nwhere memory lives\n'
# Memory left this repository on 2026-08-14. The property under test is not
# which directory it landed in — that is configurable — but that the answer
# never depends on where Felix's home is. Home *is* the checkout whenever Felix
# governs itself, and that is the exact case that put somebody else's
# confidential material into a public repository.
_md() { ( . "$REAL_HARNESS/lib/resolve.sh"; unset FELIX_MEMORY; HOME=/tmp/nohome; felix_mem_dir "$1" ) ; }
is "memory is keyed on the project name"   "$(_md /some/home/projects/widget)" "/tmp/nohome/.felix/memory/widget"
is "and not on which home it came from"    "$(_md /a/different/home/projects/widget)" "$(_md /some/home/projects/widget)"
is "a trailing slash resolves the same"    "$(_md /some/home/projects/widget/)" "$(_md /some/home/projects/widget)"
# The override is what makes this suite possible at all, so it is asserted
# rather than assumed: without it every fixture would write into the developer's
# own memory and the tests would pass while corrupting the record.
is "FELIX_MEMORY overrides the default" \
   "$( . "$REAL_HARNESS/lib/resolve.sh"; FELIX_MEMORY=/tmp/elsewhere felix_mem_dir /h/projects/widget )" \
   "/tmp/elsewhere/widget"
# The root, without a project on the end, for the one caller that has to talk
# about memory in general rather than one project's.
is "the root is available on its own" \
   "$( . "$REAL_HARNESS/lib/resolve.sh"; FELIX_MEMORY=/tmp/elsewhere felix_mem_root )" \
   "/tmp/elsewhere"

# Uninstall says what it kept, and the split left it naming the wrong place.
#
# It printed "left <home> alone: it holds your doctrine and memory" — naming the
# checkout, which after 2026-08-14 holds doctrine and no memory at all. Nothing
# was ever destroyed; the message was simply wrong about where the thing it
# preserved had gone. On the uninstall path that is the worst place to be vague,
# because it is the one moment somebody is deciding whether they are about to
# lose something.
CLB="$TMP/claudestub"; mkdir -p "$CLB"
printf '#!/usr/bin/env bash\nexit 0\n' > "$CLB/claude"; chmod +x "$CLB/claude"
uout="$(cd "$REPO" && PATH="$CLB:$PATH" FELIX_MEMORY=/tmp/mem-elsewhere "$FELIX" install --uninstall 2>&1)"
has "uninstall names the doctrine it left alone" "$uout" "$FROOT"
has "and the memory, which is somewhere else now" "$uout" "/tmp/mem-elsewhere"
# Never inside the tree it is describing, whatever home resolves to. Stated as
# its own assertion because it is the whole point and a future refactor that
# derived the root from felix_home would still pass every check above.
case "$(_md /some/home/projects/widget)" in
  /some/home/*) bad "the root is never under the home it was asked about" ;;
  *)            ok  "the root is never under the home it was asked about" ;;
esac

# And the shipped tree, because a fixture cannot tell you whether the real
# repository is still carrying memory. This is the same question the gate's
# `memory` check asks, asserted here so the suite fails too rather than leaving
# it to a gate somebody can skip.
_RD="$(cd "$REAL_HARNESS/../.." && pwd)"
if git -C "$_RD" rev-parse --git-dir >/dev/null 2>&1; then
  is "the repository tracks no project memory" \
     "$(git -C "$_RD" ls-files -- 'projects/*/memory/*' | head -3 | tr '\n' ' ')" ""
  # The ignore rule is the backstop for the same property. Checked against a
  # path rather than a file, so it holds in a checkout where nothing is there.
  git -C "$_RD" check-ignore -q 'projects/widget/memory/says.log' 2>/dev/null \
    && ok "and ignores the path so it cannot come back" \
    || bad "and ignores the path so it cannot come back"
else
  skip "the repository tracks no project memory" "not a git checkout"
fi

printf '\ninstalling\n'
# #55. `felix install` invoked through the DEPLOYED CLI — the way every
# session-start message tells you to reach Felix — compared the plugin cache
# against itself, reported "verified the installed engine matches this tree",
# and deployed nothing.
#
# FELIX_ROOT is computed at felix:64 from the running script's own location and
# is not overridable. Run the CLI from the cache and FELIX_ROOT *is* the cache,
# so `diff -rq "$FELIX_ROOT/harness" "$live/harness"` is a directory compared
# with itself. It cannot fail. HANDOFF.md §8 records four separate defects whose
# cause was "correct code, installed nowhere"; this was the fifth, sitting in the
# guard written to stop the other four.
#
# HOME is redirected for every invocation below. felix:264 writes
# `$FELIX_HOME_DIR` into `$HOME/.felix-home`, so a test that skipped this would
# repoint the developer's real Felix at a fixture on every suite run.
_install_fixture_build differing

# THE ASSERTION THE ISSUE REQUIRES. The source tree differs from the deployed
# engine in one line, and the command is invoked from the cache. It must not
# certify that they match.
icache_out="$(_inst_from_cache)"
case "$icache_out" in
  *"checked    the installed engine matches this tree"*|*"verified   the installed engine matches this tree"*)
    bad "install from the plugin cache does not certify the cache against itself" "$icache_out" ;;
  *) ok "install from the plugin cache does not certify the cache against itself" ;;
esac
# And it must say which tree it compared, or the reader cannot tell a real
# verification from the vacuous one this replaces.
has "and names the source tree it compared" "$icache_out" "$ISRC/engine"

# #66. The marketplace is registered from the directory that HOLDS
# marketplace.json, which is the repository root — not the engine one level in.
# Measured against the real CLI: `add <repo>/engine` exits 1 with "Marketplace
# file not found", and does not resolve upward.
#
# It stayed invisible because the else branch masks it. add fails, control falls
# through to `marketplace update felix`, and that is the call that did the work —
# which is why the reproduction in #55 printed "marketplace refreshed" and never
# "marketplace registered". That only works because the marketplace was already
# registered correctly at some point in the past. On a genuinely FIRST install
# there is nothing to update, and the marketplace is never registered at all.
is "the marketplace is added from the directory holding its manifest" \
   "$(grep -m1 '^plugin marketplace add ' "$ICB_LOG" | sed 's#^plugin marketplace add ##')" \
   "$ISRC"
has "and it registers rather than falling through to a refresh" \
    "$icache_out" "marketplace registered"

# The control, and the half a careless fix breaks: from the cache with the
# source MATCHING, it must still verify. A fix that simply always refuses would
# pass the assertion above and make the command useless.
cp -R "$ISRC/engine/harness/." "$ICACHE/harness/"
imatch_out="$(_inst_from_cache)"
has "and still verifies when the source really does match" \
    "$imatch_out" "checked    the installed engine matches this tree"

# Run from a checkout, the behaviour is unchanged. This is the path that always
# worked, and it is what the fix must not disturb.
printf '\n# and another the deployed engine does not have\n' >> "$ISRC/engine/harness/lib/next.sh"
irepo_out="$( cd "$ISRC" && HOME="$IHOME" FELIX_HOME="$ISRC" PATH="$ICB:$PATH" \
                "$ISRC/engine/harness/felix" install --no-bump 2>&1 )"
case "$irepo_out" in
  *"checked    the installed engine matches this tree"*|*"verified   the installed engine matches this tree"*)
    bad "install from the checkout still reports a real mismatch" "$irepo_out" ;;
  *) ok "install from the checkout still reports a real mismatch" ;;
esac

# The fixture must not have reached outside itself. felix:264 is one line away
# from rewriting the developer's real pointer file, so this is asserted rather
# than assumed.
is "and nothing was written to the real felix home pointer" \
   "$(cat "$IHOME/.felix-home" 2>/dev/null)" "$ISRC"

