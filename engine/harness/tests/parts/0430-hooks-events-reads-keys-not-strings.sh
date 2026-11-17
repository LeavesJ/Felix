# ------------------------------------------ hooks-events, the probe's instrument ---
# `hook_binding` records which events the shipped hooks.json binds. It used to
# be a grep for `"Event": [`, and the blind control that qualified the first
# obligation moved the whole SubagentStop entry one level down into another
# event's matcher group — every token intact, nothing firing — and the grep
# counted it. The obligation's checker was rewritten to read keys; the probe
# kept the grep and shared the shadow. Now both go through bin/hooks-events,
# and the decoupled copy is the control here as well.
printf '\nhooks-events reads keys, not strings\n'
HE="$TMP/hooks-events"; mkdir -p "$HE"
cat > "$HE/hooks.json" <<'JSON'
{
  "hooks": {
    "PreToolUse":   [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "echo pre" } ] } ],
    "PostToolUse":  [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "echo post" } ] } ],
    "SubagentStop": [ { "hooks": [ { "type": "command", "command": "echo sub" } ] } ],
    "Stop":         [ { "hooks": [ { "type": "command", "command": "echo stop" } ] } ]
  }
}
JSON
# The decoupled copy: the SubagentStop entry, verbatim, inside PostToolUse's
# first matcher group. A grep for `"SubagentStop": [` still matches.
cat > "$HE/decoupled.json" <<'JSON'
{
  "hooks": {
    "PreToolUse":   [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "echo pre" } ] } ],
    "PostToolUse":  [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "echo post" } ],
                        "SubagentStop": [ { "hooks": [ { "type": "command", "command": "echo sub" } ] } ] } ],
    "Stop":         [ { "hooks": [ { "type": "command", "command": "echo stop" } ] } ]
  }
}
JSON
# A binding named inside a command string, and a file with no whitespace.
cat > "$HE/embedded.json" <<'JSON'
{ "hooks": { "SessionStart": [ { "hooks": [ { "type": "command", "command": "grep -c '\"SubagentStart\": [' hooks.json" } ] } ] } }
JSON
printf '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"x"}]}],"SessionEnd":[]}}' > "$HE/minified.json"
_helex() { grep -ohE '"[A-Z][A-Za-z]+"[[:space:]]*:[[:space:]]*\[' "$1" | sed 's/"[[:space:]]*:.*//; s/"//g' | LC_ALL=C sort -u | tr '\n' ' '; }
if [ -x "$REAL_HARNESS/bin/hooks-events" ]; then
  out="$("$REAL_HARNESS/bin/hooks-events" "$HE/hooks.json" 2>&1)"; rc=$?
  is  "hooks-events reads a hooks.json and exits 0" "$rc" "0"
  is  "and lists every event its hooks object binds" \
      "$(printf '%s\n' "$out" | LC_ALL=C sort | tr '\n' ' ')" "PostToolUse PreToolUse Stop SubagentStop "
  out="$("$REAL_HARNESS/bin/hooks-events" "$HE/decoupled.json" 2>&1 | LC_ALL=C sort | tr '\n' ' ')"
  is  "the decoupled copy is not an event to hooks-events" "$out" "PostToolUse PreToolUse Stop "
  has "and the grep the probe used to be counts it, which is why the probe moved" \
      "$(_helex "$HE/decoupled.json")" "SubagentStop"
  is  "an event named inside a command string is not bound" \
      "$("$REAL_HARNESS/bin/hooks-events" "$HE/embedded.json" 2>&1 | tr '\n' ' ')" "SessionStart "
  is  "and a file with no whitespace reads the same as one with" \
      "$("$REAL_HARNESS/bin/hooks-events" "$HE/minified.json" 2>&1 | LC_ALL=C sort | tr '\n' ' ')" "SessionEnd Stop "
  is  "a missing file is cannot-examine, exit 2, never an empty binding" \
      "$("$REAL_HARNESS/bin/hooks-events" "$HE/nowhere.json" >/dev/null 2>&1; echo $?)" "2"
  is  "and so is no argument at all" "$("$REAL_HARNESS/bin/hooks-events" >/dev/null 2>&1; echo $?)" "2"
  # A document the platform would refuse to load binds nothing, whatever keys
  # a scanner can still pick out of it. Reported as cannot-examine, which is
  # UNKNOWN and blocks, and never as a file that binds no events — the first
  # version listed the keys it had found and exited 0, so a truncated
  # hooks.json read as fully wired and the obligation over it read SATISFIED.
  head -c 120 "$HE/hooks.json" > "$HE/truncated.json"
  out="$("$REAL_HARNESS/bin/hooks-events" "$HE/truncated.json" 2>&1)"; rc=$?
  is  "a truncated hooks.json is cannot-examine" "$rc" "2"
  has "saying it does not parse" "$out" "does not parse"
  is  "and prints no events at all, not the ones it managed to reach" \
      "$("$REAL_HARNESS/bin/hooks-events" "$HE/truncated.json" 2>/dev/null | grep -c .)" "0"
  printf '{ "hooks": { "Stop": [ { "hooks": [ { "type": "command", "command": "unterminated } ] } ] } }\n' > "$HE/unterminated.json"
  is  "so is a file that ends inside a string" \
      "$("$REAL_HARNESS/bin/hooks-events" "$HE/unterminated.json" >/dev/null 2>&1; echo $?)" "2"
  is  "a directory is cannot-examine, not an empty binding" \
      "$("$REAL_HARNESS/bin/hooks-events" "$HE" >/dev/null 2>&1; echo $?)" "2"
  _qualify_unreadable_probe
  if [ "$_unreadable" -eq 1 ]; then
    cp "$HE/hooks.json" "$HE/unreadable.json"; chmod 000 "$HE/unreadable.json"
    is  "and so is a file this user cannot read" \
        "$("$REAL_HARNESS/bin/hooks-events" "$HE/unreadable.json" >/dev/null 2>&1; echo $?)" "2"
    chmod 644 "$HE/unreadable.json"
  else
    skip "and so is a file this user cannot read" "$_noread"
  fi
  # And the checker over it: the evidence contract must not discharge on a
  # hooks.json nothing could load.
  if [ -x "$REAL_HARNESS/bin/lifecycle-check" ]; then
    HEL="$TMP/hooks-events-lc"; mkdir -p "$HEL/tpl"
    cp "$REAL_HARNESS/templates/lifecycle.tsv" "$HEL/tpl/"
    head -c 120 "$REAL_HARNESS/../hooks/hooks.json" > "$HEL/hooks.json"
    is  "lifecycle-check cannot examine a hooks.json that does not parse" \
        "$(cd "$HEL" && "$REAL_HARNESS/bin/lifecycle-check" tpl hooks.json >/dev/null 2>&1; echo $?)" "2"
  else
    skip "lifecycle-check cannot examine a hooks.json that does not parse" "no bin/lifecycle-check beside this harness"
  fi
  # On the shipped hooks, the instrument and the obligation's checker agree —
  # they are the same scanner — and both see the moment that was once missing.
  has "the shipped hooks bind SubagentStop by key" \
      "$("$REAL_HARNESS/bin/hooks-events" "$REAL_HARNESS/../hooks/hooks.json" 2>&1)" "SubagentStop"
else
  for a in "hooks-events reads a hooks.json and exits 0" "and lists every event its hooks object binds" \
           "the decoupled copy is not an event to hooks-events" \
           "and the grep the probe used to be counts it, which is why the probe moved" \
           "an event named inside a command string is not bound" \
           "and a file with no whitespace reads the same as one with" \
           "a missing file is cannot-examine, exit 2, never an empty binding" "and so is no argument at all" \
           "a truncated hooks.json is cannot-examine" "saying it does not parse" \
           "and prints no events at all, not the ones it managed to reach" \
           "so is a file that ends inside a string" "a directory is cannot-examine, not an empty binding" \
           "and so is a file this user cannot read" \
           "lifecycle-check cannot examine a hooks.json that does not parse" \
           "the shipped hooks bind SubagentStop by key"; do
    skip "$a" "no bin/hooks-events beside this harness"; done
fi

# The roster of what anything on this machine binds reads the same way.
#
# On the DECOUPLED fixture, deliberately. The first version of this assertion
# used a settings file whose command string mentioned an event name, and that
# separates nothing: a quote inside a JSON string is escaped as \", so the
# grep this replaced never matched it either, and the assertion was green
# under both implementations — a test that could not fail for the defect it
# was named after. The nested entry below is the shape that tells them apart:
# main's grep reports PostToolUse AND SubagentStop, the scanner reports only
# PostToolUse, and the hook at that depth never fires.
HEH="$TMP/hooks-events-home"; mkdir -p "$HEH/.claude"
cat > "$HEH/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "PostToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "echo post" } ],
                       "SubagentStop": [ { "hooks": [ { "type": "command", "command": "echo sub" } ] } ] } ]
  }
}
JSON
out="$( HOME="$HEH"; export HOME; . "$FROOT/harness/lib/coverage.sh"; felix_coverage_events | tr '\n' ' ' )"
is  "felix_coverage_events rosters the events settings.json binds by key" "$out" "PostToolUse "
has "and the grep it replaced counts the entry that never fires" \
    "$(_helex "$HEH/.claude/settings.json")" "SubagentStop"
# One unparseable file on the machine contributes nothing and blanks nothing.
printf '{ "hooks": { "Stop": [ ' > "$HEH/.claude/settings.local.json"
out="$( HOME="$HEH"; export HOME; . "$FROOT/harness/lib/coverage.sh"; felix_coverage_events | tr '\n' ' ' )"
is  "a file that does not parse drops out of the roster without taking the rest" "$out" "PostToolUse "
rm -f "$HEH/.claude/settings.local.json"
out="$( HOME="$TMP/no-such-home"; export HOME; . "$FROOT/harness/lib/coverage.sh"; felix_coverage_events; echo "rc=$?" )"
is  "and a machine that binds nothing is an empty roster, not an error" "${out##*rc=}" "0"

# The probe row names the instrument, and the instrument gets a token. A path
# under the checkout comes back from command -v relative; it is a file all the
# same, and its size is the one token that moves with the tree.
HEI="$TMP/hooks-events-inst"; mkdir -p "$HEI/bin"
printf '#!/bin/sh\necho hi\n' > "$HEI/bin/tool"; chmod +x "$HEI/bin/tool"
_hesrc() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/probes.sh"
             felix_probe_source "$HEI" "$1" ); }
is  "a probe naming a path under the checkout records that file and its size" \
    "$(_hesrc 'bin/tool hooks.json')" "bin/tool@$(wc -c < "$HEI/bin/tool" | tr -dc '0-9')"
is  "a path that is not there records no instrument" "$(_hesrc 'bin/nothing x')" "-"
is  "a builtin is named without a token, as before" "$(_hesrc 'printf x')" "printf"
_HEP="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/probes.tsv"
if [ -f "$_HEP" ]; then
  has "felix's hook_binding probe reads through hooks-events, not a grep" \
      "$(grep '^hook_binding' "$_HEP" | cut -f4)" "engine/harness/bin/hooks-events "
else
  skip "felix's hook_binding probe reads through hooks-events, not a grep" "no projects/felix beside this harness"
fi

# ------------------------------------ deploy-check, the second obligation ---
# Written is not installed. The project gate's `installed` check has compared
# the tree against the deployed cache since #55; the ledger admits the
# requirement so it cannot leave the gate the way a check can. Dormant where
# nothing is deployed and where the marketplace serves another tree, which is
# every CI runner and every worktree — reported, never waived.
printf '\ndeploy-check: written is not installed\n'
DCK="$TMP/deploy-check"; mkdir -p "$DCK/tree/engine/.claude-plugin" "$DCK/home/.claude/plugins/cache/felix/felix" "$DCK/bin" "$DCK/nohome" "$DCK/nobin"
cp -R "$FROOT/harness" "$DCK/tree/engine/harness"
_copy_content "$REAL_HARNESS/../hooks" "$DCK/tree/engine/hooks"
printf '{ "name": "felix", "version": "0.0.1" }\n' > "$DCK/tree/engine/.claude-plugin/plugin.json"
printf '*.log\n' > "$DCK/tree/.gitignore"
( _fx_cd "$DCK/tree" && git init -q -b main && git add -A && git -c user.name=t -c user.email=t@t commit -qm seed ) >/dev/null 2>&1
DCKT="$(cd "$DCK/tree" && pwd -P)"
cp -R "$DCK/tree/engine" "$DCK/home/.claude/plugins/cache/felix/felix/0.0.1"
printf '{\n  "felix": {\n    "installLocation": "%s"\n  }\n}\n' "$DCKT" > "$DCK/home/.claude/plugins/known_marketplaces.json"
cat > "$DCK/bin/claude" <<STUB
#!/usr/bin/env bash
case "\$*" in "plugin list --json") printf '{ "felix@felix": { "installPath": "%s" } }\n' "$DCK/home/.claude/plugins/cache/felix/felix/0.0.1" ;; esac
exit 0
STUB
chmod +x "$DCK/bin/claude"
# The two helpers with no CLI narrow PATH so that no claude is found, and /usr/bin:/bin alone would also hand
# deploy-check /usr/bin/git. On a Mac that is Xcode's shim, which exits 69 on every call from an Xcode update until
# its licence is accepted, and deploy-check then exits 126: the five assertions below that use these helpers failed
# that way on 2026-10-12. So $DCK/git holds one link, to the git the rest of the suite runs, ahead of /usr/bin.
mkdir -p "$DCK/git"; _dck_git="$(type -P git)"; [ -z "$_dck_git" ] || ln -sf "$_dck_git" "$DCK/git/git"
_dck()  { ( cd "$DCKT" && HOME="$DCK/home"   PATH="$DCK/bin:$PATH" engine/harness/bin/deploy-check "$@" 2>&1; echo "rc=$?" ); }
_dckn() { ( cd "$DCKT" && HOME="$DCK/nohome" PATH="$DCK/nobin:$DCK/git:/usr/bin:/bin" engine/harness/bin/deploy-check "$@" 2>&1; echo "rc=$?" ); }
# The CLI absent and a cache present: the one branch a machine without the
# claude CLI takes, which the commit claimed as behaviour and no fixture
# reached — every other helper here either has the stub on PATH or no cache.
_dckc() { ( cd "$DCKT" && HOME="$DCK/home"   PATH="$DCK/nobin:$DCK/git:/usr/bin:/bin" engine/harness/bin/deploy-check "$@" 2>&1; echo "rc=$?" ); }
# The code, exactly. `has ... "rc=1"` is a substring match that rc=126 and
# rc=127 both satisfy — the two codes that mean the checker never ran at all,
# so every exit-1 assertion here was green for a script that could not start.
_rc() { printf '%s' "${1##*rc=}"; }
if [ -x "$DCKT/engine/harness/bin/deploy-check" ]; then
  is  "deploy-check --applies holds where a deployment exists and main can be read" "$(_rc "$(_dck --applies)")" "0"
  out="$(_dck)"
  has "and a tree byte-identical to the deployed engine matches" "$out" "matches"
  is  "with exit 0" "$(_rc "$out")" "0"
  # Committed on main: the question is main's engine against main's entry, so
  # a library changed in the working tree is not drift and one merged is.
  printf '# drift\n' >> "$DCKT/engine/harness/lib/say.sh"
  ( _fx_cd "$DCKT" && git -c user.name=t -c user.email=t@t commit -qam drift ) >/dev/null 2>&1
  out="$(_dck)"
  is  "a changed library is drift, exit 1" "$(_rc "$out")" "1"
  has "and the report names the path" "$out" "say.sh"
  has "and counts it" "$out" "1 path(s) differ"
  ( _fx_cd "$DCKT" && git reset -q --hard HEAD~1 )
  printf 'x\n' > "$DCK/home/.claude/plugins/cache/felix/felix/0.0.1/harness/scratch.log"
  is  "what git ignores is not drift" "$(_rc "$(_dck)")" "0"
  rm -f "$DCK/home/.claude/plugins/cache/felix/felix/0.0.1/harness/scratch.log"
  printf '{\n  "felix": {\n    "installLocation": "/somewhere/else"\n  }\n}\n' > "$DCK/home/.claude/plugins/known_marketplaces.json"
  is  "a tree the marketplace does not serve still applies, because the question is about main" "$(_rc "$(_dck --applies)")" "0"
  is  "while the evidence still answers on its own axis" "$(_rc "$(_dck)")" "0"
  is  "no plugin cache at all is not where this applies either" "$(_rc "$(_dckn --applies)")" "1"
  out="$(_dckn)"
  is  "and with no deployment to compare against the evidence cannot examine" "$(_rc "$out")" "2"
  has "saying so" "$out" "cannot examine"
  # No CLI, a cache, and a newer entry that differs: the CLI is not asked and
  # the highest entry is not what main declares, so neither moves the verdict.
  printf '{\n  "felix": {\n    "installLocation": "%s"\n  }\n}\n' "$DCKT" > "$DCK/home/.claude/plugins/known_marketplaces.json"
  cp -R "$DCK/home/.claude/plugins/cache/felix/felix/0.0.1" "$DCK/home/.claude/plugins/cache/felix/felix/0.0.10"
  printf '# drift only in the newer cache\n' >> "$DCK/home/.claude/plugins/cache/felix/felix/0.0.10/harness/lib/say.sh"
  out="$(_dckc)"
  is  "with no CLI to ask and a newer entry on disk, the entry main declares is still the one compared" "$(_rc "$out")" "0"
  has "and it names that entry" "$out" "0.0.1"
  ( cd "$DCK/home/.claude/plugins/cache/felix/felix" && mv 0.0.10 ../../../../../0.0.10.aside ) 2>/dev/null
  # A script that cannot resolve its own library says so with 127, which the
  # obligations library reads as UNKNOWN. Exit 1 there would be DORMANT: a row
  # that stops blocking because its checker could not start.
  DCKB="$TMP/deploy-check-broken"; mkdir -p "$DCKB/engine/harness/bin"
  cp "$DCKT/engine/harness/bin/deploy-check" "$DCKB/engine/harness/bin/"
  ( _fx_cd "$DCKB" && git init -q -b main && git add -A \
    && git -c user.name=t -c user.email=t@t commit -qm b ) >/dev/null 2>&1
  is  "a deploy-check with no library beside it is 127, never 1" \
      "$(cd "$DCKB" && HOME="$DCK/home" PATH="$DCK/bin:$PATH" engine/harness/bin/deploy-check --applies >/dev/null 2>&1; echo $?)" "127"
  is  "and its evidence mode says the same" \
      "$(cd "$DCKB" && HOME="$DCK/home" PATH="$DCK/bin:$PATH" engine/harness/bin/deploy-check >/dev/null 2>&1; echo $?)" "127"
  # And a relative invocation from a subdirectory resolves the same library.
  is  "invoked by a relative path from a subdirectory it still finds its library" \
      "$(cd "$DCKT/engine/harness" && HOME="$DCK/home" PATH="$DCK/bin:$PATH" bin/deploy-check --applies >/dev/null 2>&1; echo $?)" "0"
else
  for a in "deploy-check --applies holds where a deployment exists and main can be read" \
           "and a tree byte-identical to the deployed engine matches" "with exit 0" \
           "a changed library is drift, exit 1" "and the report names the path" "and counts it" \
           "what git ignores is not drift" "a tree the marketplace does not serve still applies, because the question is about main" \
           "while the evidence still answers on its own axis" "no plugin cache at all is not where this applies either" \
           "and with no deployment to compare against the evidence cannot examine" "saying so" \
           "with no CLI to ask and a newer entry on disk, the entry main declares is still the one compared" \
           "and it names that entry" "a deploy-check with no library beside it is 127, never 1" \
           "and its evidence mode says the same" \
           "invoked by a relative path from a subdirectory it still finds its library"; do
    skip "$a" "no bin/deploy-check beside this harness"; done
fi
printf '\ndeploy-check asks what main accepted\n'
# The block above pinned deploy-check to the tree standing here against the
# LIVE plugin: the CLI's installPath, else the highest cache entry, applicable
# only where the marketplace registry named this checkout. Only the served
# checkout could ever be ACTIVE and satisfied, so the obligation was dormant in
# every worktree and every CI runner, which is everywhere the gate runs. It now
# asks what `installed` has asked since #239: is the cache entry for the
# version MAIN declares byte-identical to MAIN's engine, both sides from the
# base ref (origin/main, else main), never from the working tree.
#
# Written blind to the implementation. Every fixture here is built so the old
# question and the new one give different answers: the live pointer names an
# entry that does not exist, a higher entry than main's sits on disk and
# differs, and the registry serves some other tree.
DCM="$TMP/deploy-check-main"; DCMC="$DCM/home/.claude/plugins/cache/felix/felix"
mkdir -p "$DCM/tree/engine/.claude-plugin" "$DCMC" "$DCM/bin" "$DCM/nohome"
cp -R "$FROOT/harness" "$DCM/tree/engine/harness"
_copy_content "$REAL_HARNESS/../hooks" "$DCM/tree/engine/hooks"
printf '{ "name": "felix", "version": "0.0.1" }\n' > "$DCM/tree/engine/.claude-plugin/plugin.json"
printf '*.log\n' > "$DCM/tree/.gitignore"
( _fx_cd "$DCM/tree" && git init -q -b main && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm seed ) >/dev/null 2>&1
DCMT="$(cd "$DCM/tree" && pwd -P)"
# Deploy a ref's engine at a version the way the cache holds it: from the
# commit rather than the disk, with engine/.claude-plugin (the judge compares it). Into a
# fresh entry only; a tampered file is put back below from the same commit.
_dcm_deploy() {   # ref, version
  mkdir -p "$DCMC/$2" "$DCM/x.$2"
  _fx_git "$DCMT" archive -o "$DCM/x.$2.tar" "$1" engine && tar -x -f "$DCM/x.$2.tar" -C "$DCM/x.$2"
  rm -f "$DCM/x.$2.tar"
  for _d in harness hooks commands .claude-plugin; do
    [ -d "$DCM/x.$2/engine/$_d" ] && cp -R "$DCM/x.$2/engine/$_d" "$DCMC/$2/$_d"
  done
}
_dcm_deploy main 0.0.1
# The decoy: the highest entry on disk, and it differs from main. The replaced
# fallback compared against it; the new question never looks at it.
_dcm_deploy main 0.0.10
printf '# decoy\n' >> "$DCMC/0.0.10/harness/lib/say.sh"
# The live pointer names an entry that does not exist, and the marketplace
# serves some other tree. Neither may decide anything any more.
cat > "$DCM/bin/claude" <<STUB
#!/usr/bin/env bash
case "\$*" in "plugin list --json") printf '{ "felix@felix": { "installPath": "%s" } }\n' "$DCMC/0.9.9" ;; esac
exit 0
STUB
chmod +x "$DCM/bin/claude"
printf '{\n  "felix": {\n    "installLocation": "/served/elsewhere"\n  }\n}\n' \
  > "$DCM/home/.claude/plugins/known_marketplaces.json"
_dcm()  { ( cd "$DCMT" && unset FELIX_KERNEL FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE \
            && HOME="$DCM/home"   PATH="$DCM/bin:$PATH" engine/harness/bin/deploy-check "$@" 2>&1; echo "rc=$?" ); }
_dcmn() { ( cd "$DCMT" && unset FELIX_KERNEL FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE \
            && HOME="$DCM/nohome" PATH="$DCM/bin:$PATH" engine/harness/bin/deploy-check "$@" 2>&1; echo "rc=$?" ); }
# Exact, for the reason the block above gives: "rc=1" as a substring is
# satisfied by rc=126 and rc=127, which are a checker that never ran.
_dcmrc() { printf '%s' "${1##*rc=}"; }
_dcmci() { _fx_git "$DCMT" -c user.name=t -c user.email=t@t "$@" >/dev/null 2>&1; }
if [ -x "$FROOT/harness/bin/deploy-check" ]; then
  # Applicability: a cache and a main. Who the marketplace serves is not asked.
  is  "deploy-check --applies holds in a worktree the marketplace does not serve" "$(_dcmrc "$(_dcm --applies)")" "0"
  is  "and does not hold on a machine with no felix cache" "$(_dcmrc "$(_dcmn --applies)")" "1"
  # Evidence: main's engine against the entry for main's version, whatever the
  # live pointer says and whatever higher entry sits beside it.
  out="$(_dcm)"
  is  "main's engine byte-identical to the entry for main's version is exit 0" "$(_dcmrc "$out")" "0"
  has "and it says matches" "$out" "matches"
  case "$out" in
    *"felix/felix/0.0.10"*) bad "and names the entry main's version selects, not the highest or the live one" "$out" ;;
    *"felix/felix/0.0.1"*)  ok  "and names the entry main's version selects, not the highest or the live one" ;;
    *)                      bad "and names the entry main's version selects, not the highest or the live one" "$out" ;;
  esac
  # The working tree is not main.
  printf '# working tree\n' >> "$DCMT/engine/harness/lib/say.sh"
  is  "a library changed in the working tree is not drift, because main did not change" "$(_dcmrc "$(_dcm)")" "0"
  ( _fx_cd "$DCMT" && git checkout -q -- engine/harness/lib/say.sh )
  printf 'x\n' > "$DCMT/engine/harness/lib/untracked.sh"
  is  "nor is a file added to the working tree that git does not track" "$(_dcmrc "$(_dcm)")" "0"
  rm -f "$DCMT/engine/harness/lib/untracked.sh"
  # A branch is not main either, whatever engine or version it declares.
  _dcmci checkout -q -b cand
  printf '# candidate\n' >> "$DCMT/engine/harness/lib/say.sh"; _dcmci commit -qam cand
  DCM_CAND="$(git -C "$DCMT" rev-parse HEAD)"
  is  "a library changed and committed on a branch is not drift" "$(_dcmrc "$(_dcm)")" "0"
  sed -i.bak 's/"0.0.1"/"0.0.2"/' "$DCMT/engine/.claude-plugin/plugin.json"; rm -f "$DCMT/engine/.claude-plugin/plugin.json.bak"
  _dcmci commit -qam bump2
  is  "nor is a version the branch declares that nothing installed" "$(_dcmrc "$(_dcm)")" "0"
  _dcmci checkout -q main
  # The control: the same change on main, with nothing deployed, is drift.
  _dcmci merge -q --ff-only "$DCM_CAND"
  out="$(_dcm)"
  is  "the same change merged to main with no new deployment is drift, exit 1" "$(_dcmrc "$out")" "1"
  has "and the report names the merged path" "$out" "say.sh"
  has "and counts exactly that one" "$out" "1 path(s) differ"
  _dcmci revert --no-edit HEAD
  is  "and main put back matches again" "$(_dcmrc "$(_dcm)")" "0"
  # A version main declares with no entry is unsatisfied, not unexaminable.
  sed -i.bak 's/"0.0.1"/"0.0.9"/' "$DCMT/engine/.claude-plugin/plugin.json"; rm -f "$DCMT/engine/.claude-plugin/plugin.json.bak"
  _dcmci commit -qam bump9
  out="$(_dcm)"
  is  "a version main declares with no cache entry is exit 1, not 2" "$(_dcmrc "$out")" "1"
  has "and the output names the version nothing is installed at" "$out" "0.0.9"
  case "$out" in
    *"cannot examine"*) bad "and does not call that unexaminable" "$out" ;;
    *)                  ok  "and does not call that unexaminable" ;;
  esac
  _dcm_deploy main 0.0.9
  is  "deploying main's engine at that version satisfies it" "$(_dcmrc "$(_dcm)")" "0"
  # The entry itself, tampered under either directory the engine ships.
  printf '# tampered\n' >> "$DCMC/0.0.9/harness/lib/say.sh"
  out="$(_dcm)"
  is  "an entry for main's version tampered under harness is drift" "$(_dcmrc "$out")" "1"
  has "and it names the tampered library" "$out" "say.sh"
  git -C "$DCMT" show main:engine/harness/lib/say.sh > "$DCMC/0.0.9/harness/lib/say.sh"
  printf '\n' >> "$DCMC/0.0.9/hooks/hooks.json"
  out="$(_dcm)"
  is  "and tampered under hooks it is drift as well" "$(_dcmrc "$out")" "1"
  has "naming the hooks file" "$out" "hooks.json"
  git -C "$DCMT" show main:engine/hooks/hooks.json > "$DCMC/0.0.9/hooks/hooks.json"
  # A path git ignores is residue in the entry, not drift.
  printf 'x\n' > "$DCMC/0.0.9/harness/scratch.log"
  is  "a file git ignores dropped into the entry is residue, not drift" "$(_dcmrc "$(_dcm)")" "0"
  rm -f "$DCMC/0.0.9/harness/scratch.log"
  # A directory absent from both sides is skipped, which every assertion above
  # already exercises: this tree ships no engine/commands. Present on main
  # alone it is compared, and every file under it differs.
  mkdir -p "$DCMT/engine/commands"; printf '# hello\n' > "$DCMT/engine/commands/hello.md"
  _dcmci add -A; _dcmci commit -qm commands
  out="$(_dcm)"
  is  "a commands directory main ships that the entry lacks is drift" "$(_dcmrc "$out")" "1"
  has "and it names the file under it" "$out" "hello.md"
  _dcmci revert --no-edit HEAD
  is  "and with commands absent from both sides again it matches" "$(_dcmrc "$(_dcm)")" "0"
  # Nothing to examine: no cache on the machine.
  out="$(_dcmn)"
  is  "with no felix cache the evidence cannot examine, exit 2" "$(_dcmrc "$out")" "2"
  has "and it prints cannot examine" "$out" "cannot examine"
  # No main: a repository that cannot say what was accepted. The cache is
  # present, so this is the base ref alone deciding.
  DCMR="$DCM/trunk"; mkdir -p "$DCMR/engine/.claude-plugin"
  cp -R "$FROOT/harness" "$DCMR/engine/harness"
  _copy_content "$REAL_HARNESS/../hooks" "$DCMR/engine/hooks"
  printf '{ "name": "felix", "version": "0.0.1" }\n' > "$DCMR/engine/.claude-plugin/plugin.json"
  ( _fx_cd "$DCMR" && git init -q -b trunk && git add -A \
    && git -c user.name=t -c user.email=t@t commit -qm seed ) >/dev/null 2>&1
  _dcmr() { ( cd "$DCMR" && unset FELIX_KERNEL FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE \
              && HOME="$DCM/home" PATH="$DCM/bin:$PATH" engine/harness/bin/deploy-check "$@" 2>&1; echo "rc=$?" ); }
  is  "in a repository with no main and no origin, --applies does not hold even with a cache" "$(_dcmrc "$(_dcmr --applies)")" "1"
  out="$(_dcmr)"
  is  "and its evidence cannot examine there" "$(_dcmrc "$out")" "2"
  has "saying cannot examine" "$out" "cannot examine"
  # origin/main outranks main. A bare origin level with main changes nothing;
  # an origin whose main is a bump ahead is what the check follows, while the
  # local main still declares a version whose entry matches.
  git init -q --bare "$DCM/origin.git" >/dev/null 2>&1
  _dcmci remote add origin "$DCM/origin.git"
  _dcmci push -q origin main; _dcmci fetch -q origin
  is  "with origin/main level with main the verdict is unchanged" "$(_dcmrc "$(_dcm)")" "0"
  _dcmci checkout -q -b ahead
  sed -i.bak 's/"0.0.9"/"0.1.0"/' "$DCMT/engine/.claude-plugin/plugin.json"; rm -f "$DCMT/engine/.claude-plugin/plugin.json.bak"
  _dcmci commit -qam ahead
  _dcmci checkout -q main
  _dcmci push -q origin ahead:main; _dcmci fetch -q origin
  out="$(_dcm)"
  is  "with origin/main a bump ahead of main, the check follows origin" "$(_dcmrc "$out")" "1"
  has "and names origin's version as the one nothing is installed at" "$out" "0.1.0"
  # A script that cannot resolve its own library still says so with 127. Under
  # the new question a cache and a main are both present here, so a script
  # that ran without its library would answer 0 to --applies.
  DCMB="$DCM/broken"; mkdir -p "$DCMB/engine/harness/bin"
  cp "$DCMT/engine/harness/bin/deploy-check" "$DCMB/engine/harness/bin/"
  ( _fx_cd "$DCMB" && git init -q -b main && git add -A \
    && git -c user.name=t -c user.email=t@t commit -qm b ) >/dev/null 2>&1
  is  "a deploy-check with no library beside it is still 127 under the new question" \
      "$(cd "$DCMB" && HOME="$DCM/home" PATH="$DCM/bin:$PATH" engine/harness/bin/deploy-check --applies >/dev/null 2>&1; echo $?)" "127"
  is  "and so is its evidence mode" \
      "$(cd "$DCMB" && HOME="$DCM/home" PATH="$DCM/bin:$PATH" engine/harness/bin/deploy-check >/dev/null 2>&1; echo $?)" "127"
else
  for a in "deploy-check --applies holds in a worktree the marketplace does not serve" \
           "and does not hold on a machine with no felix cache" \
           "main's engine byte-identical to the entry for main's version is exit 0" \
           "and it says matches" \
           "and names the entry main's version selects, not the highest or the live one" \
           "a library changed in the working tree is not drift, because main did not change" \
           "nor is a file added to the working tree that git does not track" \
           "a library changed and committed on a branch is not drift" \
           "nor is a version the branch declares that nothing installed" \
           "the same change merged to main with no new deployment is drift, exit 1" \
           "and the report names the merged path" "and counts exactly that one" \
           "and main put back matches again" \
           "a version main declares with no cache entry is exit 1, not 2" \
           "and the output names the version nothing is installed at" \
           "and does not call that unexaminable" \
           "deploying main's engine at that version satisfies it" \
           "an entry for main's version tampered under harness is drift" \
           "and it names the tampered library" \
           "and tampered under hooks it is drift as well" "naming the hooks file" \
           "a file git ignores dropped into the entry is residue, not drift" \
           "a commands directory main ships that the entry lacks is drift" \
           "and it names the file under it" \
           "and with commands absent from both sides again it matches" \
           "with no felix cache the evidence cannot examine, exit 2" \
           "and it prints cannot examine" \
           "in a repository with no main and no origin, --applies does not hold even with a cache" \
           "and its evidence cannot examine there" "saying cannot examine" \
           "with origin/main level with main the verdict is unchanged" \
           "with origin/main a bump ahead of main, the check follows origin" \
           "and names origin's version as the one nothing is installed at" \
           "a deploy-check with no library beside it is still 127 under the new question" \
           "and so is its evidence mode"; do
    skip "$a" "no bin/deploy-check beside this harness"; done
fi
# The gate's executable check, shown failing. It was widened from a list of
# three named scripts to every file under bin/, and nothing made a bin script
# non-executable and expected a red line — so the widening was a claim in a
# commit message. A probe or an evidence contract naming a bin script that
# lost its bit reads `unknown` and blocks, which is loud; the gate should say
# which file before the ledger has to.
GEX="$TMP/gate-executable"; mkdir -p "$GEX/engine/.claude-plugin"
_copy_content "$REAL_HARNESS" "$GEX/engine/harness"
_copy_content "$REAL_HARNESS/../hooks" "$GEX/engine/hooks"
printf '{ "name": "felix", "version": "0.0.1" }\n' > "$GEX/engine/.claude-plugin/plugin.json"
_GEXG="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/gate.sh"
if [ -f "$_GEXG" ]; then
  cp "$_GEXG" "$GEX/gate.sh"
  ( _fx_cd "$GEX" && git init -q -b main && git add -A \
    && git -c user.name=t -c user.email=t@t commit -qm s ) >/dev/null 2>&1
  out="$(cd "$GEX" && bash gate.sh --quick 2>&1 | grep '^  executable')"
  has "the gate's executable check passes when every script under bin/ has its bit" "$out" "ok"
  chmod 644 "$GEX/engine/harness/bin/secret-scan"
  out="$(cd "$GEX" && bash gate.sh --quick 2>&1)"
  has "and fails when one of them loses it" "$(printf '%s\n' "$out" | grep '^  executable')" "FAIL"
  has "naming the file" "$out" "engine/harness/bin/secret-scan"
  chmod 755 "$GEX/engine/harness/bin/secret-scan"
else
  for a in "the gate's executable check passes when every script under bin/ has its bit" \
           "and fails when one of them loses it" "naming the file"; do
    skip "$a" "no projects/felix/gate.sh beside this harness"; done
fi

