printf '\ndiscovery follows what the plugin manifest declares\n'
# A plugin names where its hooks and servers live in .claude-plugin/plugin.json,
# and a string there is a path. Datadog keeps its server and both of its keys in
# a file neither default name reaches, so reading only hooks/hooks.json and
# .mcp.json called it low. A declared path is read only when it stays inside the
# plugin. One that leaves it, or names nothing, is an unread declaration, and
# what was not read is scored high rather than assumed harmless. Skills and
# commands carry hooks in their frontmatter too. Agents are not read for them,
# because Claude Code ignores hooks in a plugin agent's frontmatter.
MFD="$TMP/manifest-fixtures"; mkdir -p "$MFD"
_mf_facts()  { ( . "$FROOT/harness/lib/discover.sh"; felix_discover_inspect "$@" ) 2>/dev/null; }
_mf_risk()   { ( . "$FROOT/harness/lib/discover.sh"; felix_discover_risk "$1" ) 2>/dev/null; }
_mf_tier()   { _mf_risk "$(_mf_facts "$@")"; }
_mf_put()    { mkdir -p "$(dirname "$MFD/$1")"; printf '%s\n' "$2" > "$MFD/$1"; }
_mf_plugin() { _mf_put "$1/.claude-plugin/plugin.json" "$2"; }
_mf_lacks()  { case "$2" in *"$3"*) bad "$1" "[$2] has [$3]" ;; *) ok "$1" ;; esac; }
_mf_unread() { case "$(printf '%s\n' "$2" | grep $'^unread\t')" in
                 *"$3 "*"$4"*) ok "$1" ;; *) bad "$1" "no unread $3 line naming $4 in [$2]" ;; esac; }
_MF_REMOTE='{"mcpServers":{"r":{"type":"http","url":"https://mcp.example/mcp"}}}'
_MF_LOCAL='{"mcpServers":{"l":{"command":"/usr/local/bin/l","args":["serve"]}}}'

# The two shapes that started this, as they ship.
_mf_plugin datadog '{
  "name": "datadog",
  "version": "0.7.14",
  "keywords": ["datadog", "mcp", "observability"],
  "mcpServers": "./.dd_mcp.json"
}'
_mf_put datadog/.dd_mcp.json '{
  "mcpServers": {
    "mcp": {
      "type": "http",
      "url": "https://${DD_MCP_DOMAIN:-not-setup}/v1/mcp?toolsets=${DD_MCP_TOOLSETS:-}",
      "headers": {
        "DD_API_KEY": "${DD_API_KEY:-}",
        "DD_APPLICATION_KEY": "${DD_APPLICATION_KEY:-}"
      }
    }
  }
}'
_mf_f="$(_mf_facts "$MFD/datadog")"
is  "datadog's shape, a server behind a declared path, is high" "$(_mf_risk "$_mf_f")" "high"
has "and the declared file is read for the key it sends"         "$_mf_f" $'interpolates\tDD_API_KEY'
has "and for where it sends it"                                  "$_mf_f" $'mcp\tremote endpoint'
ln -s "$MFD/datadog" "$MFD/datadog-link"
has "a plugin reached through a symlinked directory still has its declared file read" \
    "$(_mf_facts "$MFD/datadog-link")" $'interpolates\tDD_API_KEY'
_mf_plugin supabase '{
  "name": "supabase",
  "skills": "./skills/",
  "mcpServers": "./agents/claude/.mcp.json",
  "keywords": ["supabase", "mcp"]
}'
_mf_put supabase/agents/claude/.mcp.json '{"mcpServers":{"supabase":{"type":"http","url":"https://mcp.supabase.com/mcp","headers":{"X-Source-Name":"claude-code-plugin"}}}}'
_mf_put supabase/skills/supabase/SKILL.md $'---\nname: supabase\ndescription: work with a project\n---\nBody.'
is "supabase's shape, a remote server two directories down with no variable, is medium" \
   "$(_mf_tier "$MFD/supabase")" "medium"

# Inline objects are plugin.json itself, read with the same rules.
_mf_plugin inline-local "{\"name\":\"il\",${_MF_LOCAL#\{}"
is "a local server declared inline in plugin.json is medium" "$(_mf_tier "$MFD/inline-local")" "medium"
_mf_plugin inline-var '{"name":"iv","mcpServers":{"l":{"command":"/usr/local/bin/l","env":{"TOKEN":"${INLINE_TOKEN}"}}}}'
_mf_f="$(_mf_facts "$MFD/inline-var")"
is  "an inline server that interpolates a variable is high" "$(_mf_risk "$_mf_f")" "high"
has "and the inline variable is named"                      "$_mf_f" $'interpolates\tINLINE_TOKEN'
_MF_HOOKS='{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"echo checked"}]}]}}'
_mf_plugin hooks-inline "{\"name\":\"hi\",${_MF_HOOKS#\{}"
_mf_f="$(_mf_facts "$MFD/hooks-inline")"
is  "hooks declared inline in plugin.json are high" "$(_mf_risk "$_mf_f")" "high"
has "and are read as hooks, by event"               "$_mf_f" $'hooks\tPreToolUse'
_mf_plugin hooks-path '{"name":"hp","hooks":"./config/extra-hooks.json"}'
_mf_put hooks-path/config/extra-hooks.json "$_MF_HOOKS"
_mf_f="$(_mf_facts "$MFD/hooks-path")"
is  "hooks at a declared path are high"     "$(_mf_risk "$_mf_f")" "high"
has "and the commands in that file are listed" "$_mf_f" $'hook-command\techo checked'

# Refused: the path leaves the plugin, or names nothing. Every outside target
# holds a variable nothing inside the plugin holds, so reading it would show.
_mf_put outside.json '{"mcpServers":{"o":{"type":"http","url":"https://o.example","headers":{"K":"${ONLY_OUTSIDE_KEY}"}}}}'
_mf_plugin dotdot   '{"name":"dd","mcpServers":"../outside.json"}'
_mf_plugin absolute "{\"name\":\"ab\",\"mcpServers\":\"$MFD/outside.json\"}"
_mf_plugin tilde    '{"name":"tl","mcpServers":"~/outside.json"}'
_mf_plugin linked   '{"name":"ln","mcpServers":"./linked.json"}'
ln -s "$MFD/outside.json" "$MFD/linked/linked.json"
_mf_plugin missing  '{"name":"ms","mcpServers":"./nowhere.json"}'
_mf_refused() { # label, fixture, file the unread line names, "outside" when a target exists
  local f; f="$(HOME="$MFD" _mf_facts "$MFD/$2")"
  is "$1 is high" "$(_mf_risk "$f")" "high"
  _mf_unread "$1 is an unread fact naming the key and the path" "$f" mcpServers "$3"
  [ "${4:-}" = outside ] || return 0
  _mf_lacks "$1 reads nothing from the file it points at" "$f" "ONLY_OUTSIDE_KEY"
}
_mf_refused "a declared path that climbs out with .."              dotdot   outside.json outside
_mf_refused "a declared absolute path"                             absolute outside.json outside
_mf_refused "a declared path beginning with ~"                     tilde    outside.json outside
_mf_refused "a declared path through a symlink leaving the plugin" linked   linked.json  outside
_mf_refused "a declared path to no file at all"                    missing  nowhere.json
_mf_put outside-hooks.json '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"echo OUTSIDE_HOOK_RAN"}]}]}}'
_mf_plugin hooks-out '{"name":"ho","hooks":"../outside-hooks.json"}'
_mf_f="$(_mf_facts "$MFD/hooks-out")"
_mf_unread "a hooks path that climbs out is an unread fact naming hooks" "$_mf_f" hooks outside-hooks.json
_mf_lacks  "and none of the commands out there are listed"              "$_mf_f" "OUTSIDE_HOOK_RAN"
_mf_plugin inlink '{"name":"ik","mcpServers":"./alias.json"}'
_mf_put inlink/real/servers.json '{"mcpServers":{"s":{"command":"s","env":{"K":"${INSIDE_LINK_KEY}"}}}}'
ln -s real/servers.json "$MFD/inlink/alias.json"
has "a symlink that stays inside the plugin is followed and read" \
    "$(_mf_facts "$MFD/inlink")" $'interpolates\tINSIDE_LINK_KEY'

# Arrays are read to the end; an object element is inline.
_mf_plugin array '{
  "name": "array",
  "mcpServers": [
    "./one.json",
    "./two.json"
  ]
}'
_mf_put array/one.json "$_MF_LOCAL"
_mf_put array/two.json '{"mcpServers":{"t":{"command":"t","env":{"K":"${ARRAY_SECOND_KEY}"}}}}'
_mf_f="$(_mf_facts "$MFD/array")"
is  "an array of two paths where only the second interpolates is high" "$(_mf_risk "$_mf_f")" "high"
has "because the second path was read too"                            "$_mf_f" $'interpolates\tARRAY_SECOND_KEY'
_mf_plugin array-inline '{"name":"ai","mcpServers":["./one.json",{"x":{"command":"x","env":{"K":"${ARRAY_INLINE_KEY}"}}}]}'
_mf_put array-inline/one.json "$_MF_LOCAL"
has "an object inside a declared array is read as inline" \
    "$(_mf_facts "$MFD/array-inline")" $'interpolates\tARRAY_INLINE_KEY'

# Empty declares nothing, and only a top-level key declares at all. ECC's shape.
_mf_plugin ecc '{
  "name": "ecc",
  "keywords": ["claude-code", "hooks", "mcp"],
  "userConfig": {
    "hooks_enabled": {"type": "boolean", "default": true}
  },
  "mcpServers": {},
  "skills": ["./skills/"],
  "commands": ["./commands/"]
}'
_mf_put ecc/skills/tdd/SKILL.md $'---\nname: tdd\ndescription: write the test first\n---\nBody.'
_mf_put ecc/commands/plan.md    $'---\ndescription: plan before building\n---\nBody.'
_mf_f="$(_mf_facts "$MFD/ecc")"
is "ecc's shape, an empty mcpServers object beside skills, is low" "$(_mf_risk "$_mf_f")" "low"
_mf_lacks "and an empty mcpServers object is no mcp fact"          "$_mf_f" $'mcp\t'
_mf_n=0
for _mf_v in '{}' '[]' 'null'; do _mf_n=$((_mf_n+1))
  _mf_plugin "nothing$_mf_n" "{\"name\":\"n\",\"hooks\":$_mf_v,\"mcpServers\":$_mf_v}"
  is "hooks and mcpServers both $_mf_v declare nothing, not even a fact" "$(_mf_facts "$MFD/nothing$_mf_n")" ""
done
_mf_plugin nested '{"name":"nest","userConfig":{"hooks":{"type":"boolean","default":true}}}'
is "a hooks key nested under another key is not a declaration" "$(_mf_facts "$MFD/nested")" ""

# The change only raises. Written out rather than read from a copy of the old
# library, because once this lands the old library is this one.
_mf_plugin plain '{"name":"plain","version":"1.0.0","keywords":["hooks","mcp"]}'
_mf_put plain/hooks/hooks.json '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"echo plain"}]}]}}'
_mf_put plain/.mcp.json '{"mcpServers":{"p":{"command":"npx","args":["p@latest"],"env":{"K":"${PLAIN_KEY}"}}}}'
_mf_put plain/skills/one/SKILL.md $'---\nname: one\ndescription: an ordinary skill\nallowed-tools: Read, Grep\n---\nBody.'
_mf_put plain/commands/go.md      $'---\ndescription: go\n---\nBody.'
_mf_put plain/agents/helper.md    $'---\nname: helper\ntools: Read\n---\nBody.'
is "a plugin that declares no paths has exactly the facts it had before" \
   "$(_mf_facts "$MFD/plain" | LC_ALL=C sort)" \
   "$(printf '%s\n' $'hooks\tSessionStart ' $'hook-command\techo plain' $'mcp\tlocal subprocess' \
        $'interpolates\tPLAIN_KEY' $'floating\tan unpinned version in the mcp command' \
        $'skills\t1' $'skill\tone' | LC_ALL=C sort)"
is "an unread declaration alone is high" "$(_mf_risk $'unread\thooks ./h.json: no such file')" "high"
_mf_w="$( . "$FROOT/harness/lib/discover.sh"; felix_discover_why "$(felix_discover_inspect "$MFD/missing")" 2>/dev/null )"
case "$_mf_w" in
  *mcpServers*nowhere.json*|*nowhere.json*mcpServers*) ok "the why for an unread declaration names its key and its path" ;;
  *) bad "the why for an unread declaration names its key and its path" "[$_mf_w]" ;;
esac

# SUB picks the plugin inside a repository, and its manifest is the one read.
_mf_plugin mono '{"name":"mono","hooks":"./root-hooks.json"}'
_mf_put mono/root-hooks.json '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"echo root"}]}]}}'
_mf_plugin mono/plugins/inner '{"name":"inner","mcpServers":"./inner.json"}'
_mf_put mono/plugins/inner/inner.json "$_MF_REMOTE"
is  "with SUB, the manifest under DIR/SUB is read, its paths relative to SUB" \
    "$(_mf_tier "$MFD/mono" plugins/inner)" "medium"
has "and without SUB, the manifest at DIR is read" "$(_mf_facts "$MFD/mono")" $'hook-command\techo root'

# Frontmatter: skills and commands, never agents, and only the frontmatter.
_MF_FM=$'---\nname: guarded\ndescription: checks before it writes\nhooks:\n  PreToolUse:\n    - matcher: "Bash"\n      hooks:\n        - type: command\n          command: "./scripts/check.sh"\n---\nBody.'
_mf_put fm-skill/skills/guarded/SKILL.md "$_MF_FM"
_mf_put fm-cmd/commands/deploy.md        "$_MF_FM"
_mf_put fm-deep/commands/ops/deploy.md   "$_MF_FM"
_mf_put fm-agent/agents/reviewer.md      "$_MF_FM"
_mf_put fm-flow/skills/s/SKILL.md $'---\nname: s\nhooks: {PreToolUse: [{matcher: Bash, hooks: [{type: command, command: ./c.sh}]}]}\n---\nBody.'
is "a skill whose frontmatter declares a PreToolUse hook is high" "$(_mf_tier "$MFD/fm-skill")" "high"
is "a command whose frontmatter declares hooks is high"           "$(_mf_tier "$MFD/fm-cmd")"   "high"
is "so is a command one directory further down"                   "$(_mf_tier "$MFD/fm-deep")"  "high"
is "and a skill whose frontmatter hooks are written on one line"  "$(_mf_tier "$MFD/fm-flow")"  "high"
is "an agent whose frontmatter declares hooks stays low, since Claude Code ignores them there" \
   "$(_mf_tier "$MFD/fm-agent")" "low"
_mf_n=0
for _mf_v in 'hooks: []' 'hooks: {}' 'hooks: null'; do _mf_n=$((_mf_n+1))
  _mf_put "fm-empty$_mf_n/skills/s/SKILL.md" $'---\nname: s\n'"$_mf_v"$'\n---\nBody.'
  is "a skill whose frontmatter says $_mf_v is low" "$(_mf_tier "$MFD/fm-empty$_mf_n")" "low"
done
_mf_put fm-body/skills/s/SKILL.md  $'---\nname: s\ndescription: shows the settings\n---\nPut this in settings:\n\nhooks:\n  PreToolUse:\n    - matcher: "Bash"'
_mf_put fm-said/skills/s/SKILL.md  $'---\nname: s\ndescription: "Use when writing hooks: PreToolUse, Stop and the rest"\n---\nBody.'
_mf_put fm-under/skills/s/SKILL.md $'---\nname: s\nmetadata:\n  hooks: documented\n---\nBody.'
_mf_put fm-late/skills/s/SKILL.md  $'# Not frontmatter\n---\nhooks:\n  PreToolUse:\n    - matcher: "Bash"\n---\nBody.'
is "hooks: in a skill's body, after the frontmatter closes, is low" "$(_mf_tier "$MFD/fm-body")"  "low"
is "hooks: inside a frontmatter value is low"                       "$(_mf_tier "$MFD/fm-said")"  "low"
is "hooks: indented under another frontmatter key is low"           "$(_mf_tier "$MFD/fm-under")" "low"
is "a --- block that does not open the file is not frontmatter"     "$(_mf_tier "$MFD/fm-late")"  "low"

# Nothing declared is ever run: not at a path, not inline, not in frontmatter,
# and a path that reads like a command substitution is a string, not a command.
_mf_plugin run-path '{"name":"rp","hooks":"./config/h.json"}'
_mf_put run-path/config/h.json "{\"hooks\":{\"SessionStart\":[{\"hooks\":[{\"type\":\"command\",\"command\":\"touch $MFD/RAN-path\"}]}]}}"
_mf_plugin run-inline "{\"name\":\"ri\",\"hooks\":{\"SessionStart\":[{\"hooks\":[{\"type\":\"command\",\"command\":\"touch $MFD/RAN-inline\"}]}]}}"
_mf_put run-inline/skills/s/SKILL.md $'---\nname: s\nhooks:\n  SessionStart:\n    - hooks:\n        - type: command\n          command: "touch '"$MFD"$'/RAN-fm"\n---\nBody.'
_mf_plugin run-name "{\"name\":\"rn\",\"mcpServers\":\"./\$(touch $MFD/RAN-name).json\",\"hooks\":\"./\`touch $MFD/RAN-tick\`.json\"}"
for _mf_v in run-path run-inline run-name; do _mf_facts "$MFD/$_mf_v" >/dev/null; done
if [ -e "$MFD/RAN-path" ]; then bad "a hook command at a declared path is never run" "the sentinel was created"
else ok "a hook command at a declared path is never run"; fi
if [ -e "$MFD/RAN-inline" ] || [ -e "$MFD/RAN-fm" ]; then bad "nor one declared inline or in a skill's frontmatter" "a sentinel was created"
else ok "nor one declared inline or in a skill's frontmatter"; fi
if [ -e "$MFD/RAN-name" ] || [ -e "$MFD/RAN-tick" ]; then bad "a declared path shaped like a command substitution is never evaluated" "a sentinel was created"
else ok "a declared path shaped like a command substitution is never evaluated"; fi

# Written after the block above and by the implementer, not blind: the cases
# its author listed as left unsaid by the contract. A manifest that is not an
# object, a byte-order mark, a Windows line ending, a bare `hooks:` that YAML
# reads as null, one file named under both keys, and a manifest that is itself
# a link out of the copy.
_mf_put notjson/.claude-plugin/plugin.json 'mcpServers = "./x.json"'
_mf_f="$(_mf_facts "$MFD/notjson")"
is  "a manifest that is not a JSON object is high"     "$(_mf_risk "$_mf_f")" "high"
has "as an unread manifest, not as nothing declared"   "$_mf_f" $'unread\tthe manifest'
_mf_put bom/.claude-plugin/plugin.json $'\xef\xbb\xbf{"name":"bom","mcpServers":"./s.json"}'
_mf_put bom/s.json "$_MF_REMOTE"
is "a manifest opening with a byte-order mark is still read" "$(_mf_tier "$MFD/bom")" "medium"
_mf_put fm-bom/skills/s/SKILL.md $'\xef\xbb\xbf---\nname: s\nhooks:\n  Stop: []\n---\nBody.'
is "frontmatter after a byte-order mark still declares hooks" "$(_mf_tier "$MFD/fm-bom")" "high"
_mf_put fm-crlf/commands/c.md $'---\r\ndescription: c\r\nhooks:\r\n  PreToolUse: []\r\n---\r\nBody.'
is "frontmatter with Windows line endings still declares hooks" "$(_mf_tier "$MFD/fm-crlf")" "high"
_mf_put fm-bare/skills/s/SKILL.md $'---\nname: s\nhooks:\ndescription: nothing under it\n---\nBody.'
is "a bare hooks: with a sibling key after it is null, and low" "$(_mf_tier "$MFD/fm-bare")" "low"
_mf_plugin both '{"name":"both","hooks":"./c.json","mcpServers":"./c.json"}'
_mf_put both/c.json '{"hooks":{"Stop":[]},"mcpServers":{"x":{"command":"x"}}}'
_mf_f="$(_mf_facts "$MFD/both")"
has "one file named under both keys is read as hooks"       "$_mf_f" $'hooks\tStop'
has "and as a server, each by its own rule"                 "$_mf_f" $'mcp\tlocal subprocess'
_mf_plugin again '{"name":"again","hooks":"./hooks/hooks.json"}'
_mf_put again/hooks/hooks.json '{"hooks":{"Stop":[]}}'
is "the default hooks file named again in the manifest is read once" \
   "$(_mf_facts "$MFD/again" | grep -c $'^hooks\t')" "1"
mkdir -p "$MFD/mlink/.claude-plugin"
ln -s "$MFD/outside.json" "$MFD/mlink/.claude-plugin/plugin.json"
_mf_f="$(_mf_facts "$MFD/mlink")"
_mf_unread "a manifest that is itself a link out of the copy is unread" "$_mf_f" "the" "manifest"
_mf_lacks  "and what it links to is not read"                            "$_mf_f" "ONLY_OUTSIDE_KEY"

# Found by review, not by either block: a walker that resynchronised on the
# next quote read a broken string's closing quote as the start of a key, and
# the declaration after the break vanished. Broken JSON is the whole manifest
# unread, and so is an awk that fails, which would otherwise print nothing.
_mf_plugin broken $'{"hooks":"./h.json\n"mcpServers":"./m.json"}'
_mf_put broken/h.json '{"hooks":{"Stop":[]}}'
_mf_f="$(_mf_facts "$MFD/broken")"
is  "a string broken across the next key leaves the manifest high" "$(_mf_risk "$_mf_f")" "high"
has "as an unread manifest, whatever the key before it said"      "$_mf_f" $'unread\tthe manifest'
_mf_plugin nocomma '{"name":"nc" "mcpServers":"./m.json"}'
has "a missing comma is an unread manifest, not a lost declaration" \
    "$(_mf_facts "$MFD/nocomma")" $'unread\tthe manifest'
mkdir -p "$MFD/badawk"; printf '#!/bin/sh\nexit 2\n' > "$MFD/badawk/awk"; chmod +x "$MFD/badawk/awk"
has "an awk that fails reads the manifest as unread, not as nothing declared" \
    "$(PATH="$MFD/badawk:$PATH" _mf_facts "$MFD/datadog")" $'unread\tthe manifest'
printf '\nwhat an LSP server and a marketplace entry declare is read too\n'
# 2026-09-21. An LSP server is a subprocess the platform starts, declared in
# .lsp.json or under the manifest's lspServers, and neither was read. A
# marketplace entry can declare hooks, MCP and LSP servers inline, outside the
# plugin's own files, and no entry was read either: twelve in the official
# catalogue carry their LSP server there and nowhere else, and two installed
# copies of them held a README and tiered `low` with nothing read. An LSP
# server tiers as an MCP local server does, medium.
DL="$TMP/discover-lsp"
mkdir -p "$DL/rootlsp" "$DL/pathlsp/.claude-plugin" "$DL/pathlsp/config" "$DL/inlinelsp/.claude-plugin" \
         "$DL/listlsp/.claude-plugin" "$DL/credlsp" "$DL/floatlsp" "$DL/outside" \
         "$DL/leaklsp/.claude-plugin" "$DL/leakmcp" "$DL/gonelsp/.claude-plugin"
printf '{"py":{"command":"pyright-langserver","args":["--stdio"],"extensionToLanguage":{".py":"python"}}}\n' > "$DL/rootlsp/.lsp.json"
cp "$DL/rootlsp/.lsp.json" "$DL/pathlsp/config/lsp.json"
printf '{"name":"pathlsp","lspServers":"./config/lsp.json"}\n'            > "$DL/pathlsp/.claude-plugin/plugin.json"
printf '{"name":"inlinelsp","lspServers":{"go":{"command":"gopls"}}}\n'  > "$DL/inlinelsp/.claude-plugin/plugin.json"
cp "$DL/rootlsp/.lsp.json" "$DL/listlsp/a.json"; cp "$DL/rootlsp/.lsp.json" "$DL/listlsp/b.json"
printf '{"name":"listlsp","lspServers":["./a.json","./b.json"]}\n'      > "$DL/listlsp/.claude-plugin/plugin.json"
printf '{"x":{"command":"${LS_HOME}/bin/ls-server"}}\n'                 > "$DL/credlsp/.lsp.json"
printf '{"x":{"command":"npx","args":["some-language-server@latest"]}}\n' > "$DL/floatlsp/.lsp.json"
printf '{"x":{"command":"quiet-ls"}}\n'                                 > "$DL/outside/lsp.json"
ln -s ../outside/lsp.json "$DL/leaklsp/lsp.json"
printf '{"name":"leaklsp","lspServers":"./lsp.json"}\n'                 > "$DL/leaklsp/.claude-plugin/plugin.json"
printf '{"name":"gonelsp","lspServers":"./nowhere.json"}\n'             > "$DL/gonelsp/.claude-plugin/plugin.json"
# A default file linked out of the copy. It used to be read wherever the link
# went, while a path the manifest spelled out was held to the copy.
printf '{"mcpServers":{"x":{"command":"/usr/local/bin/x"}}}\n' > "$DL/outside/mcp.json"
ln -s ../outside/mcp.json "$DL/leakmcp/.mcp.json"

is  ".lsp.json at the root is medium"                   "$(_tier "$DL/rootlsp")"   "medium"
has "and the fact is a local subprocess"                "$( . "$FROOT/harness/lib/discover.sh"; felix_discover_inspect "$DL/rootlsp" )" "lsp	local subprocess"
is  "lspServers as a path in the manifest is medium"    "$(_tier "$DL/pathlsp")"   "medium"
is  "lspServers inline in the manifest is medium"       "$(_tier "$DL/inlinelsp")" "medium"
is  "lspServers as a list of paths is medium"           "$(_tier "$DL/listlsp")"   "medium"
is  "an LSP server that interpolates a variable is high" "$(_tier "$DL/credlsp")"  "high"
is  "an unpinned LSP command is high"                   "$(_tier "$DL/floatlsp")"  "high"
is  "an lspServers path linked out of the copy is high" "$(_tier "$DL/leaklsp")"   "high"
has "because it was not read"                           "$( . "$FROOT/harness/lib/discover.sh"; felix_discover_inspect "$DL/leaklsp" )" "unread	lspServers ./lsp.json: a link that leaves the copy"
is  "an lspServers path that does not exist is high"    "$(_tier "$DL/gonelsp")"   "high"
is  "a default file linked out of the copy is high, not read where it points" "$(_tier "$DL/leakmcp")" "high"
has "and says which file and why"                       "$( . "$FROOT/harness/lib/discover.sh"; felix_discover_inspect "$DL/leakmcp" )" "unread	.mcp.json: a link that leaves the copy"
has "the reason names the server it starts" \
    "$( . "$FROOT/harness/lib/discover.sh"; felix_discover_why "$(felix_discover_inspect "$DL/rootlsp")" )" "language server (pyright-langserver)"

# Frontmatter hooks behind a declared path. A manifest `commands` path replaces
# commands/ and a `skills` path adds to skills/, and only the defaults were
# scanned. A hook there is a hook.
mkdir -p "$DL/cmdpath/.claude-plugin" "$DL/cmdpath/extra-commands" \
         "$DL/skillpath/.claude-plugin" "$DL/skillpath/more/deploy" "$DL/nocmd/.claude-plugin"
printf -- '---\nname: run\nhooks:\n  PreToolUse:\n    - matcher: Bash\n---\nbody\n' > "$DL/cmdpath/extra-commands/run.md"
printf -- '---\nname: deploy\nhooks:\n  Stop:\n    - command: ./x.sh\n---\nbody\n'   > "$DL/skillpath/more/deploy/SKILL.md"
printf '{"name":"cmdpath","commands":"./extra-commands/"}\n'   > "$DL/cmdpath/.claude-plugin/plugin.json"
printf '{"name":"skillpath","skills":["./more/deploy"]}\n'     > "$DL/skillpath/.claude-plugin/plugin.json"
printf '{"name":"nocmd","commands":["./not-here/"]}\n'         > "$DL/nocmd/.claude-plugin/plugin.json"
is  "a hook in the frontmatter of a declared commands folder is high" "$(_tier "$DL/cmdpath")"   "high"
is  "and in a declared skill folder's own SKILL.md"                   "$(_tier "$DL/skillpath")" "high"
is  "a declared commands folder that is missing adds nothing"         "$(_tier "$DL/nocmd")"     "low"

# The entry. A catalogue where the plugin's name also belongs to an owner and
# to an earlier entry's author, and that earlier entry ships a hook: reading
# the wrong object would call the LSP plugin high.
DM="$TMP/discover-entry"
mkdir -p "$DM/mkt/.claude-plugin" "$DM/readmeonly" "$DM/haspath/hooks" "$DM/tmp"
printf '# readme\n' > "$DM/readmeonly/README.md"
printf '{"hooks":{"PreToolUse":[{"hooks":[{"type":"command","command":"bash extra.sh"}]}]}}\n' > "$DM/haspath/hooks/extra.json"
mkdir -p "$DM/haspath/more/deploy"; cp "$DL/skillpath/more/deploy/SKILL.md" "$DM/haspath/more/deploy/SKILL.md"
cat > "$DM/mkt/.claude-plugin/marketplace.json" <<'JSON'
{
  "name": "fixmkt",
  "owner": { "name": "readmeonly" },
  "plugins": [
    {
      "name": "decoy",
      "description": "mentions { braces }, [brackets] and \"quotes\"",
      "author": { "name": "readmeonly" },
      "source": "./plugins/decoy",
      "strict": false,
      "hooks": { "SessionStart": [ { "hooks": [ { "type": "command", "command": "curl evil" } ] } ] }
    },
    {
      "name": "readmeonly",
      "author": { "name": "someone" },
      "source": "./plugins/readmeonly",
      "strict": false,
      "lspServers": { "py": { "command": "pyright-langserver", "args": ["--stdio"] } }
    },
    { "name": "entryhooks", "source": "./p", "strict": false,
      "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "bash guard.sh" } ] } ] } },
    { "name": "entrymcp",    "source": "./p", "mcpServers": { "x": { "command": "/usr/local/bin/x" } } },
    { "name": "entrypath",   "source": "./p", "hooks": "./hooks/extra.json" },
    { "name": "entryskills", "source": "./p", "strict": false, "skills": ["./more/deploy"] },
    { "name": "clean",       "source": "./p", "description": "nothing declared" }
  ]
}
JSON
DMF="$DM/mkt/.claude-plugin/marketplace.json"
_etier() { ( . "$FROOT/harness/lib/discover.sh"
             felix_discover_risk "$(felix_discover_inspect "$1" "" "$2" "$3")" ); }
is  "a copy that ships a README alone is low when no entry is read"   "$(_tier "$DM/readmeonly")" "low"
is  "and medium once its marketplace entry's LSP server is read"      "$(_etier "$DM/readmeonly" "$DMF" readmeonly)" "medium"
case "$( . "$FROOT/harness/lib/discover.sh"; felix_discover_inspect "$DM/readmeonly" "" "$DMF" readmeonly )" in
  *"curl evil"*|*"hooks	"*) bad "the entry read is the one named, not one whose author has the name" ;;
  *)                           ok  "the entry read is the one named, not one whose author has the name" ;;
esac
is  "an entry declaring hooks inline is high"                         "$(_etier "$DM/readmeonly" "$DMF" entryhooks)" "high"
is  "an entry declaring an MCP server inline is medium"               "$(_etier "$DM/readmeonly" "$DMF" entrymcp)"   "medium"
has "an entry's path is read inside the plugin" \
    "$( . "$FROOT/harness/lib/discover.sh"; felix_discover_inspect "$DM/haspath" "" "$DMF" entrypath )" "hook-command	bash extra.sh"
is  "and one the plugin does not ship is high"                        "$(_etier "$DM/readmeonly" "$DMF" entrypath)" "high"
is  "an entry's skill folder with frontmatter hooks is high"          "$(_etier "$DM/haspath" "$DMF" entryskills)"  "high"
is  "an entry that declares nothing adds nothing"                     "$(_etier "$DM/readmeonly" "$DMF" clean)"     "low"
is  "a plugin the catalogue does not list adds nothing"               "$(_etier "$DM/readmeonly" "$DMF" nosuch)"    "low"
tr -d '\n' < "$DMF" > "$DM/minified.json"
is  "a minified catalogue is read the same"                           "$(_etier "$DM/readmeonly" "$DM/minified.json" readmeonly)" "medium"
# The reader failing raises. A catalogue that names the plugin, but not as an
# element of its top-level plugins list, gives no entry to read.
printf '{"meta":{"plugins":[{"name":"hidden","hooks":{"Stop":[]}}]}}\n' > "$DM/odd.json"
is  "a catalogue naming the plugin with no entry to isolate is high"  "$(_etier "$DM/readmeonly" "$DM/odd.json" hidden)" "high"
is  "a catalogue that cannot be read is high"                         "$(_etier "$DM/readmeonly" "$DM/absent.json" readmeonly)" "high"
_dg0="$( . "$FROOT/harness/lib/discover.sh"; felix_discover_digest "$DM/readmeonly" )"
( TMPDIR="$DM/tmp"; . "$FROOT/harness/lib/discover.sh"; felix_discover_inspect "$DM/readmeonly" "" "$DMF" readmeonly >/dev/null )
is  "reading the entry writes nothing into the copy" "$( . "$FROOT/harness/lib/discover.sh"; felix_discover_digest "$DM/readmeonly" )" "$_dg0"
is  "and leaves no scratch file behind"              "$(ls -A "$DM/tmp" | wc -l | tr -d ' ')" "0"

# Where the catalogue is: the location known_marketplaces.json records, read by
# key, pretty-printed or minified.
printf '{\n  "other": {\n    "source": { "source": "github", "repo": "a/b" },\n    "installLocation": "/nowhere"\n  },\n  "fixmkt": {\n    "source": { "source": "directory", "path": "%s" },\n    "installLocation": "%s"\n  }\n}\n' "$DM/mkt" "$DM/mkt" > "$DM/known.json"
tr -d '\n' < "$DM/known.json" > "$DM/known-min.json"
_mkfile() { ( . "$FROOT/harness/lib/discover.sh"; FELIX_KNOWN_MARKETPLACES="$1" felix_discover_marketplace_file "$2" ); }
is  "a registered marketplace names its catalogue"      "$(_mkfile "$DM/known.json" fixmkt)"     "$DMF"
is  "from a minified registry too"                      "$(_mkfile "$DM/known-min.json" fixmkt)" "$DMF"
is  "an unregistered one names none"                    "$(_mkfile "$DM/known.json" elsewhere)"  ""

# The installed copy, through the toolbox: the marketplace comes from where the
# copy sits in the cache, and the entry from the catalogue that names.
TBE="$TMP/plugincache-entry"; mkdir -p "$TBE/fixmkt/readmeonly/1.0.0"
printf '# readme\n' > "$TBE/fixmkt/readmeonly/1.0.0/README.md"
_tbr() { ( . "$FROOT/harness/lib/toolbox.sh"; . "$FROOT/harness/lib/discover.sh"
           FELIX_PLUGIN_CACHE="$TBE"; FELIX_KNOWN_MARKETPLACES="$DM/known.json"
           felix_toolbox_risk "$1" "$(felix_toolbox_path "$1")" ); }
is  "an installed copy is tiered with its marketplace entry" "$(_tbr readmeonly)" "medium"

# And the catalogue listing, which is where the discover and commission paths
# learn which marketplace a candidate came from.
DMB="$TMP/discover-entry-bin"; mkdir -p "$DMB"
cat > "$DMB/claude" <<'EOF'
#!/usr/bin/env bash
cat <<'JSON'
{
  "installed": [],
  "available": [
    {
      "pluginId": "subbed@fixmkt",
      "name": "subbed",
      "description": "a plugin in a subdirectory",
      "marketplaceName": "fixmkt",
      "source": {
        "source": "git-subdir",
        "url": "https://example.invalid/subbed.git",
        "path": "plugins/subbed",
        "sha": "0123456789abcdef0123456789abcdef01234567"
      }
    }
  ]
}
JSON
EOF
chmod +x "$DMB/claude"
is  "the source names the marketplace the entry came from" \
    "$( . "$FROOT/harness/lib/discover.sh"; PATH="$DMB:$PATH" felix_discover_source subbed )" \
    "$(printf 'https://example.invalid/subbed.git\t0123456789abcdef0123456789abcdef01234567\tplugins/subbed\tfixmkt')"

