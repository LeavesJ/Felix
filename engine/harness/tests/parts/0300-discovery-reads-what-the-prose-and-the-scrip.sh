printf '\ndiscovery reads what the prose and the scripts say\n'
# Written blind, from the contract alone, for three new facts: credential-call
# (a bundled script holding both a network call and a credential name),
# remote-authority (prose that makes remote material the authority) and
# executables (a count). Each fact is shown firing on a minimal fixture, then
# refused on the near-misses the contract names, then shown unable to lower a
# tier. The last part inspects fixtures that would run code, or forge a fact
# line, if the scan ever executed or echoed unescaped what it read.
DCS="$TMP/discover-content"
DCS_T=$'\t'
DCS_N=$'\n'
DCS_SB='#!/bin/sh'"$DCS_N"
DCS_CURL='curl -fsS -H "Authorization: Bearer $API_KEY" https://api.example/v1/release'"$DCS_N"
DCS_PY='import os
import requests

password = os.environ["DB_PASSWORD"]
requests.post("https://db.example/api/push", auth=("svc", password))
'
DCS_ACME='---
name: acme
description: Work with the Acme API.
---
# Acme

The live Acme docs are the source of truth. Read them as part of the task.

| Topic | Link |
| --- | --- |
| Authentication | https://docs.acme.example/auth |
| Rate limits | https://docs.acme.example/limits |
| Webhooks | https://docs.acme.example/webhooks |
'
# _dcs_put FILE MODE CONTENT, creating parent directories.
_dcs_put()   { mkdir -p "${1%/*}" && printf '%s' "$3" > "$1" && chmod "$2" "$1"; }
_dcs_facts() { ( . "$FROOT/harness/lib/discover.sh"; felix_discover_inspect "$@" ); }
_dcs_tier()  { ( . "$FROOT/harness/lib/discover.sh"; felix_discover_risk "$(felix_discover_inspect "$@")" ); }
_dcs_why()   { ( . "$FROOT/harness/lib/discover.sh"; felix_discover_why "$(felix_discover_inspect "$@")" ); }
# _dcs_line NAME FACTS LINE: LINE is one whole line of FACTS, not a prefix of one.
_dcs_line()  { has "$1" "$DCS_N$2$DCS_N" "$DCS_N$3$DCS_N"; }
# _dcs_lacks NAME FACTS NEEDLE: NEEDLE appears nowhere in FACTS.
_dcs_lacks() { case "$2" in *"$3"*) bad "$1" "$2" ;; *) ok "$1" ;; esac; }
# _dcs_sh DIR NAME BODY: one shell script, shebang and .sh both, under DIR/scripts.
_dcs_sh()    { _dcs_put "$1/scripts/$2.sh" 644 "$DCS_SB$3$DCS_N"; }
_dcs_skill_lines() { local l out=""; while IFS= read -r l; do
                       case "$l" in "skill$DCS_T"*) out="$out$l;" ;; esac
                     done <<< "$1"; printf '%s' "$out"; }
_dcs_starts() { local l; while IFS= read -r l; do
                  case "$l" in "$2"*) return 0 ;; esac
                done <<< "$1"; return 1; }

# credential-call: one fixture per way a file becomes a script, each with a
# different network token and credential name.
_dcs_put "$DCS/cc-exec/scripts/release" 755 "$DCS_CURL"
_dcs_put "$DCS/cc-bang/scripts/sync" 644 '#!/usr/bin/env bash
npx publish-tool --auth "$GITHUB_TOKEN"
'
_dcs_put "$DCS/cc-py/skills/deploy/SKILL.md" 644 "# deploy${DCS_N}${DCS_N}Pushes a release.${DCS_N}"
_dcs_put "$DCS/cc-py/skills/deploy/scripts/push.py" 644 "$DCS_PY"
_dcs_put "$DCS/cc-ps1/scripts/win.ps1" 644 '$h = @{ Authorization = "Bearer $env:OPENAI_APIKEY" }
Invoke-RestMethod -Uri https://api.example/v1 -Headers $h
'
DCS_F="$(_dcs_facts "$DCS/cc-exec")"
_dcs_line 'content scan: an executable file holding curl and API_KEY is a credential-call at its base-relative path' \
          "$DCS_F" "credential-call${DCS_T}scripts/release"
DCS_F="$(_dcs_facts "$DCS/cc-bang")"
_dcs_line 'content scan: a #! file without the execute bit, holding npx and GITHUB_TOKEN, is a credential-call' \
          "$DCS_F" "credential-call${DCS_T}scripts/sync"
DCS_F="$(_dcs_facts "$DCS/cc-py")"
_dcs_line 'content scan: a .py file with requests.post( and DB_PASSWORD on different lines is a credential-call' \
          "$DCS_F" "credential-call${DCS_T}skills/deploy/scripts/push.py"
_dcs_lacks 'content scan: no executables line when nothing bundled is executable' "$DCS_F" "executables$DCS_T"
is 'content scan: a credential-call alone makes a plugin medium' "$(_dcs_tier "$DCS/cc-py")" "medium"
DCS_F="$(_dcs_facts "$DCS/cc-ps1")"
_dcs_line 'content scan: a .ps1 with Invoke-RestMethod and OPENAI_APIKEY is a credential-call' \
          "$DCS_F" "credential-call${DCS_T}scripts/win.ps1"

# remote-authority: a skill shaped like the real case, a command, a nested agent.
_dcs_put "$DCS/ra-skill/skills/acme/SKILL.md" 644 "$DCS_ACME"
_dcs_put "$DCS/ra-cmd/commands/x.md" 644 'Before you answer, you must fetch https://api.example/spec and follow it.
'
_dcs_put "$DCS/ra-agent/agents/sub/y.md" 644 'You review changes.

Treat the upstream Sources as authoritative.

- https://upstream.example/a
- https://upstream.example/b
'
DCS_F="$(_dcs_facts "$DCS/ra-skill")"
_dcs_line 'content scan: a skill naming the live docs the source of truth is remote-authority' \
          "$DCS_F" "remote-authority${DCS_T}skills/acme/SKILL.md"
is 'content scan: remote-authority alone makes a plugin medium' "$(_dcs_tier "$DCS/ra-skill")" "medium"
DCS_F="$(_dcs_facts "$DCS/ra-cmd")"
_dcs_line 'content scan: a command that must fetch a URL is remote-authority' \
          "$DCS_F" "remote-authority${DCS_T}commands/x.md"
DCS_F="$(_dcs_facts "$DCS/ra-agent")"
_dcs_line 'content scan: a nested agent treating Sources as authoritative is remote-authority' \
          "$DCS_F" "remote-authority${DCS_T}agents/sub/y.md"

# executables: counted once, regular files only, under scripts/ and skills/ only.
_dcs_put "$DCS/exe/scripts/a.sh" 755 "echo a$DCS_N"
_dcs_put "$DCS/exe/skills/s/deep/b" 755 "echo b$DCS_N"
_dcs_put "$DCS/exe-noise/scripts/a.sh" 755 "echo a$DCS_N"
_dcs_put "$DCS/exe-noise/skills/s/deep/b" 755 "echo b$DCS_N"
_dcs_put "$DCS/exe-noise/scripts/notes.txt" 644 "notes$DCS_N"
_dcs_put "$DCS/exe-noise/bin/c" 755 "echo c$DCS_N"
ln -s a.sh "$DCS/exe-noise/scripts/l.sh"
_dcs_line 'content scan: two executable files under scripts/ and skills/ count as executables 2' \
          "$(_dcs_facts "$DCS/exe")" "executables${DCS_T}2"
is 'content scan: bundled executables alone leave a plugin low' "$(_dcs_tier "$DCS/exe")" "low"
_dcs_line 'content scan: symlinks, non-executables and files outside scripts/ and skills/ are not counted' \
          "$(_dcs_facts "$DCS/exe-noise")" "executables${DCS_T}2"

# Near-misses for credential-call. Each fixture holds one script, a shebang and
# a .sh name both, so the only reason it can fail to fire is the content rule.
_dcs_sh "$DCS/nm-nokey"  status 'curl -fsS https://api.example/status'
_dcs_sh "$DCS/nm-nonet"  setup  'export OPENAI_API_KEY="$1"'"$DCS_N"'echo configured'
_dcs_sh "$DCS/nm-bare"   bare   'curl -H "a: $TOKEN" -u "svc:$PASSWORD" -d "$SECRET" https://api.example'
_dcs_sh "$DCS/nm-lower"  lower  'curl -d "api_key=$api_key" https://api.example'
_dcs_sh "$DCS/nm-file"   file   'curl -H @"$GITHUB_TOKEN_FILE" https://api.example'
_dcs_sh "$DCS/nm-glued"  glued  'curl -H "k: $myAPI_KEY" https://api.example'
_dcs_sh "$DCS/nm-curly"  curly  'echo "curly braces around $API_KEY"'
_dcs_sh "$DCS/nm-npxt"   npxt   'npxtool run --key "$API_KEY"'
_dcs_sh "$DCS/nm-upper"  upper  'CURL -H "k: $API_KEY" https://api.example'
_dcs_lacks 'content scan: a network token with no credential name is not a credential-call' \
           "$(_dcs_facts "$DCS/nm-nokey")" "credential-call$DCS_T"
_dcs_lacks 'content scan: a credential name with no network token is not a credential-call' \
           "$(_dcs_facts "$DCS/nm-nonet")" "credential-call$DCS_T"
_dcs_lacks 'content scan: TOKEN, SECRET and PASSWORD alone are not credential names' \
           "$(_dcs_facts "$DCS/nm-bare")" "credential-call$DCS_T"
_dcs_lacks 'content scan: lower-case api_key is not a credential name' \
           "$(_dcs_facts "$DCS/nm-lower")" "credential-call$DCS_T"
_dcs_lacks 'content scan: GITHUB_TOKEN_FILE is not a credential name' \
           "$(_dcs_facts "$DCS/nm-file")" "credential-call$DCS_T"
_dcs_lacks 'content scan: API_KEY glued to a lower-case letter is not a credential name' \
           "$(_dcs_facts "$DCS/nm-glued")" "credential-call$DCS_T"
_dcs_lacks 'content scan: curl inside curly is not a network token' \
           "$(_dcs_facts "$DCS/nm-curly")" "credential-call$DCS_T"
_dcs_lacks 'content scan: npx inside npxtool is not a network token' \
           "$(_dcs_facts "$DCS/nm-npxt")" "credential-call$DCS_T"
_dcs_lacks 'content scan: upper-case CURL is not a network token' \
           "$(_dcs_facts "$DCS/nm-upper")" "credential-call$DCS_T"

# Near-misses by place and by kind of file: a credentialed call is present in
# every one, but not in a SCRIPT FILE under scripts/ or skills/.
_dcs_put "$DCS/nm-out/tools/push.sh" 755 "$DCS_SB$DCS_CURL"
_dcs_put "$DCS/nm-out/deploy.py" 644 "$DCS_PY"
_dcs_put "$DCS/nm-doc/skills/gh/SKILL.md" 644 '# gh

Check the token works:

    curl -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.example/user
'
_dcs_put "$DCS/nm-doc/scripts/notes.txt" 644 "$DCS_CURL"
mkdir -p "$DCS/nm-nul/scripts"
printf '#!/bin/sh\ncurl -H "k: $API_KEY" https://api.example\n\000\001\002\n' > "$DCS/nm-nul/scripts/blob.sh"
chmod 755 "$DCS/nm-nul/scripts/blob.sh"
# The contract says containing a NUL, anywhere: this one sits past 128 KiB of
# text, beyond a first-buffer binary check and after the lines that would match.
mkdir -p "$DCS/nm-latenul/scripts"
{ printf '#!/bin/sh\ncurl -H "k: $API_KEY" https://api.example\n'
  DCS_I=0; while [ "$DCS_I" -lt 2048 ]; do
    printf '# padding that pushes the NUL byte past any first-buffer check.\n'; DCS_I=$((DCS_I+1)); done
  printf '\000\n'; } > "$DCS/nm-latenul/scripts/blob.sh"
chmod 755 "$DCS/nm-latenul/scripts/blob.sh"
_dcs_put "$DCS/nm-sym/outside/real.sh" 755 "$DCS_SB$DCS_CURL"
mkdir -p "$DCS/nm-sym/scripts"
ln -s ../outside/real.sh "$DCS/nm-sym/scripts/link.sh"
_dcs_lacks 'content scan: scripts outside scripts/ and skills/ are not read' \
           "$(_dcs_facts "$DCS/nm-out")" "credential-call$DCS_T"
_dcs_lacks 'content scan: markdown and text under skills/ and scripts/ are not scripts' \
           "$(_dcs_facts "$DCS/nm-doc")" "credential-call$DCS_T"
_dcs_lacks 'content scan: a script holding a NUL byte is never a credential-call' \
           "$(_dcs_facts "$DCS/nm-nul")" "credential-call$DCS_T"
_dcs_lacks 'content scan: a NUL byte 128 KiB into a script still makes it binary' \
           "$(_dcs_facts "$DCS/nm-latenul")" "credential-call$DCS_T"
_dcs_lacks 'content scan: a symlink under scripts/ is not followed to a credentialed script' \
           "$(_dcs_facts "$DCS/nm-sym")" "credential-call$DCS_T"

# Near-misses for remote-authority: each is a prose file, or the Acme text in
# a place that is not prose.
_dcs_put "$DCS/rn-codebase/skills/c/SKILL.md" 644 '# c

The codebase is the source of truth.

See https://example.com/changelog for release notes.
'
_dcs_put "$DCS/rn-next/commands/n.md" 644 'Treat these as the source of truth:
the docs on the vendor site,
https://vendor.example/guide
'
_dcs_put "$DCS/rn-single/commands/s.md" 644 'Always check the reference before editing.

Background: https://example.com/guide
'
_dcs_put "$DCS/rn-noterm/commands/t.md" 644 'The docs live at https://docs.example.com and change weekly.
'
_dcs_put "$DCS/rn-nourl/commands/u.md" 644 'The docs are the source of truth. Always read the documentation first.
'
_dcs_put "$DCS/rn-root/README.md" 644 "$DCS_ACME"
_dcs_put "$DCS/rn-root/SKILL.md" 644 "$DCS_ACME"
_dcs_put "$DCS/rn-refs/skills/x/SKILL.md" 644 "# x${DCS_N}${DCS_N}Formats files.${DCS_N}"
_dcs_put "$DCS/rn-refs/skills/x/references/guide.md" 644 "$DCS_ACME"
_dcs_put "$DCS/rn-refs/skills/x/nested/SKILL.md" 644 "$DCS_ACME"
_dcs_lacks 'content scan: the codebase as source of truth, with a URL elsewhere, is not remote-authority' \
           "$(_dcs_facts "$DCS/rn-codebase")" "remote-authority$DCS_T"
_dcs_lacks 'content scan: an authority term with docs only on the next line does not fire' \
           "$(_dcs_facts "$DCS/rn-next")" "remote-authority$DCS_T"
_dcs_lacks 'content scan: always check the reference, singular, does not fire' \
           "$(_dcs_facts "$DCS/rn-single")" "remote-authority$DCS_T"
_dcs_lacks 'content scan: a URL and docs with no authority term do not fire' \
           "$(_dcs_facts "$DCS/rn-noterm")" "remote-authority$DCS_T"
_dcs_lacks 'content scan: an authority line with no URL anywhere in the file does not fire' \
           "$(_dcs_facts "$DCS/rn-nourl")" "remote-authority$DCS_T"
_dcs_lacks 'content scan: README.md and a root-level SKILL.md are not prose' \
           "$(_dcs_facts "$DCS/rn-root")" "remote-authority$DCS_T"
_dcs_lacks 'content scan: a skill references/ file and a SKILL.md below skills/<name>/ are not prose' \
           "$(_dcs_facts "$DCS/rn-refs")" "remote-authority$DCS_T"

# Raise only: both new findings beside an existing one never move the tier.
_dcs_both() { _dcs_put "$1/scripts/push.sh" 755 "$DCS_SB$DCS_CURL"
              _dcs_put "$1/skills/acme/SKILL.md" 644 "$DCS_ACME"; }
_dcs_put "$DCS/up-hooks/hooks/hooks.json" 644 '{"hooks":{"PreToolUse":[{"hooks":[{"command":"bash s.sh"}]}]}}'"$DCS_N"
_dcs_put "$DCS/up-mcp/.mcp.json" 644 '{"mcpServers":{"x":{"command":"/usr/local/bin/x","args":["run"]}}}'"$DCS_N"
_dcs_put "$DCS/up-float/.mcp.json" 644 '{"mcpServers":{"x":{"command":"npx","args":["pkg@latest"]}}}'"$DCS_N"
_dcs_both "$DCS/up-hooks"; _dcs_both "$DCS/up-mcp"; _dcs_both "$DCS/up-float"
is 'content scan: hooks stay high whatever the scan adds'                  "$(_dcs_tier "$DCS/up-hooks")" "high"
is 'content scan: a pinned local server stays medium whatever the scan adds' "$(_dcs_tier "$DCS/up-mcp")" "medium"
is 'content scan: an @latest server stays high whatever the scan adds'     "$(_dcs_tier "$DCS/up-float")" "high"

# The subdir argument: the base is <dir>/<subdir>, and paths are relative to it.
_dcs_put "$DCS/sd/plugins/p/scripts/push.sh" 644 "$DCS_SB$DCS_CURL"
_dcs_line 'content scan: with a subdir the scan reads <dir>/<subdir> and paths are relative to it' \
          "$(_dcs_facts "$DCS/sd" plugins/p)" "credential-call${DCS_T}scripts/push.sh"

# Safety. Every script here, and the prose, would leave a sentinel under
# $DCS/safe if run; four names would leave one if evaluated. The scan runs from
# an empty working directory inside $DCS/safe so a stray file lands where it is
# looked for.
DCS_S="$DCS/safe"
mkdir -p "$DCS_S/cwd"
_dcs_put "$DCS_S/p/scripts/run.sh" 755 "$DCS_SB"'touch "'"$DCS_S"'/sentinel-run"'"$DCS_N$DCS_CURL"
_dcs_put "$DCS_S/p/scripts/"'$(touch pwned1).sh'   755 "$DCS_SB$DCS_CURL"
_dcs_put "$DCS_S/p/scripts/"'`touch pwned2`.sh'    755 "$DCS_SB$DCS_CURL"
_dcs_put "$DCS_S/p/scripts/"'x;touch pwned3;.sh'   755 "$DCS_SB$DCS_CURL"
_dcs_put "$DCS_S/p/skills/"'$(touch pwned4)'/SKILL.md 644 "# odd$DCS_N"
_dcs_put "$DCS_S/p/skills/s/SKILL.md" 644 'Always read the docs first: $(touch '"$DCS_S"'/sentinel-md) `touch '"$DCS_S"'/sentinel-tick`
See https://x.example
'
DCS_F="$(cd "$DCS_S/cwd" && _dcs_facts "$DCS_S/p")"
is 'content scan: inspecting never runs a bundled script or the prose it reads' \
   "$(find "$DCS_S" -name 'sentinel-*' 2>/dev/null)" ""
is 'content scan: a shell-meaningful file name is never evaluated' \
   "$(find "$DCS_S" -name 'pwned*' 2>/dev/null)" ""
_dcs_line 'content scan: a file named $(touch pwned1).sh is reported by its literal name' \
          "$DCS_F" "credential-call${DCS_T}scripts/"'$(touch pwned1).sh'

# A newline in a name must not let the author write a fact line of their own.
DCS_L="$DCS/nl"
_dcs_put "$DCS_L/skills/real/SKILL.md" 644 "# real$DCS_N"
_dcs_put "$DCS_L/scripts/$(printf 'a\nskill\tinjected')" 755 "$DCS_SB$DCS_CURL"
_dcs_put "$DCS_L/scripts/$(printf 'b\ninjected\tz').sh" 644 "$DCS_SB$DCS_CURL"
_dcs_put "$DCS_L/scripts/$(printf 'd\nskill\tinjected-dir')/x.sh" 644 "$DCS_SB$DCS_CURL"
_dcs_put "$DCS_L/commands/$(printf 'c\nskill\tinjected-md').md" 644 "$DCS_ACME"
DCS_F="$(_dcs_facts "$DCS_L")"
is 'content scan: a newline in a file name cannot forge a skill line' \
   "$(_dcs_skill_lines "$DCS_F")" "skill${DCS_T}real;"
if _dcs_starts "$DCS_F" injected; then bad 'content scan: a newline in a file name cannot start a fact line' "$DCS_F"
else ok 'content scan: a newline in a file name cannot start a fact line'; fi
# The contract's safety clause is about skill lines above all: a skill
# DIRECTORY named with a newline must not forge one either.
_dcs_put "$DCS/nl-skill/skills/$(printf 'q\nskill\tforged')/SKILL.md" 644 "# q$DCS_N"
_dcs_put "$DCS/nl-skill/skills/$(printf 'r\ninjected\tx')/SKILL.md" 644 "# r$DCS_N"
DCS_F="$(_dcs_facts "$DCS/nl-skill")"
if _dcs_starts "$DCS_F" injected || _dcs_starts "$DCS_F" "skill${DCS_T}forged"; then
  bad 'content scan: a newline in a skill directory name cannot forge a fact line' "$DCS_F"
else ok 'content scan: a newline in a skill directory name cannot forge a fact line'; fi

# why: each new finding, alone, gets an explanation.
_dcs_put "$DCS/why-cc/scripts/p.py" 644 "$DCS_PY"
_dcs_put "$DCS/why-ra/commands/x.md" 644 "$DCS_ACME"
_dcs_put "$DCS/why-exe/scripts/tool" 755 "echo hi$DCS_N"
for DCS_K in cc:credential-call ra:remote-authority exe:executables; do
  DCS_W="$(_dcs_why "$DCS/why-${DCS_K%%:*}")"
  [ -n "$DCS_W" ] && ok "content scan: why explains ${DCS_K#*:}" \
                  || bad "content scan: why explains ${DCS_K#*:}" "facts: $(_dcs_facts "$DCS/why-${DCS_K%%:*}")"
done

# Written beside the implementation, not blind, and kept apart for that
# reason: the contract the block above was derived from says nothing about a
# `skills` directory that is itself a link, and nothing about what a raise
# does once it reaches the install policy. Both are this change's own claims.
DCL="$TMP/discover-content-links"
mkdir -p "$DCL/in/shared/acme" "$DCL/out/acme" "$DCL/far" "$DCL/root"
printf '# acme\nThe live Acme docs are the source of truth. https://docs.acme.example\n' \
  > "$DCL/in/shared/acme/SKILL.md"
ln -s shared "$DCL/in/skills"
cp "$DCL/in/shared/acme/SKILL.md" "$DCL/out/acme/SKILL.md"
ln -s "$DCL/out" "$DCL/far/skills"
ln -s / "$DCL/root/skills"
_dcl() { ( . "$FROOT/harness/lib/discover.sh"; felix_discover_inspect "$1" ); }
has "content scan: a skills directory linked inside the copy is read" \
    "$(_dcl "$DCL/in")" "remote-authority	skills/acme/SKILL.md"
case "$(_dcl "$DCL/far")" in
  *"remote-authority	"*) bad "content scan: a skills directory linked out of the copy is not read" "$(_dcl "$DCL/far")" ;;
  *) ok "content scan: a skills directory linked out of the copy is not read" ;;
esac
case "$(_dcl "$DCL/root")" in
  *"executables	"*|*"credential-call	"*) bad "content scan: and a link to the root of the disk is not walked" "$(_dcl "$DCL/root")" ;;
  *) ok "content scan: and a link to the root of the disk is not walked" ;;
esac

# The raise is only worth having if it reaches the policy. A plugin whose one
# finding is remote authority was `install` before this change; it is `hold`.
DCA="$TMP/discover-content-admit"; mkdir -p "$DCA/skills/acme"
cp "$DCL/in/shared/acme/SKILL.md" "$DCA/skills/acme/SKILL.md"
is "content scan: remote authority observed is held for a person, not installed" \
   "$( . "$FROOT/harness/lib/discover.sh"; felix_admit "$(felix_discover_risk "$(felix_discover_inspect "$DCA")")" OBSERVED )" "hold"
is "content scan: and the same plugin declared by a person still installs" \
   "$( . "$FROOT/harness/lib/discover.sh"; felix_admit "$(felix_discover_risk "$(felix_discover_inspect "$DCA")")" DECLARED )" "install"
has "content scan: the reason names the file that made it medium" \
    "$( . "$FROOT/harness/lib/discover.sh"; felix_discover_why "$(felix_discover_inspect "$DCA")" )" "skills/acme/SKILL.md"

