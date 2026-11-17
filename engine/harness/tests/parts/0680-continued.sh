# Every other reader of the declared capabilities says the list could not be read, never that it is empty (1 of 2).
#
# felix_declared returns 2 when something is at `capabilities` and could not be
# read, and a substitution around it can end with nothing printed and status 0
# when its fork could not be made. Only _felix_cap_active and its callers said
# so. Every other reader read either as an empty list and made a claim from it:
# felix recommend printed `declared: none` and `waits for <cap>` for a
# capability that may be declared; felix doctor printed an empty declared line
# and every detected surface as undeclared drift, because felix_undeclared
# subtracted nothing from what felix_detect found; session start adopted
# whatever felix_undeclared printed; felix_probes_gaps dropped every
# declared-only capability from the gaps and felix_probes_orphans called a probe
# grounding one an orphan. Items 1 to 6 of the contract in
# docs/handoff/pending/20261001T235048Z-claude-declared-unread-readers.md, and a
# felix_declared_into that assigns a list only when it was read.
# The library is asked with felix_declared failing three ways, each defined in a
# subshell after the libs are sourced: returning nonzero, printing one declared
# capability and then returning nonzero, and exiting before anything is printed,
# which is what a substitution whose fork could not be made looks like from the
# line that reads it. The capabilities file DOES declare the capabilities in
# question, so a list read as empty shows. The CLI and the hook are other
# processes and cannot see a stub, so there the capabilities file is a link
# whose target is gone; session start is also run from a scratch copy of the
# engine whose detect.sh ends with the failing function. Nothing here needs the
# claude CLI: the project has no routes.tsv, so session start never discovers.
# These assertions were written blind, from the contract, before the fix, and
# each was run against main's engine and the branch base first.
# Everything this makes is removed below and everything it defines unset.
_durafixture() { { find "$FROOT/projects" "$FROOT/state" "$MEM" 2>/dev/null | LC_ALL=C sort
                   find "$FROOT/projects" "$FROOT/state" "$MEM" -type f -exec cksum {} + 2>/dev/null | LC_ALL=C sort; } | cksum; }
_durafound="$(_durafixture)"
_durap="$FROOT/projects/duraproj"
_durar="$TMP/dura-repo"
_durahome="$TMP/dura-home"
mkdir -p "$_durap" "$_durar/tests" "$_durahome"
# Each block's CLI and hook run under a PATH narrowed so that no claude but the block's own stub is found, and
# /usr/bin:/bin alone would also hand them /usr/bin/git. On a Mac that is Xcode's shim, which exits 69 on every call
# from an Xcode update until its licence is accepted, and fourteen assertions here then fail. So every block puts
# $_durgit, holding one link to the git the rest of the suite runs, ahead of /usr/bin; the last block removes it.
_durgit="$TMP/dur-git"; mkdir -p "$_durgit"; [ -z "$(type -P git)" ] || ln -sf "$(type -P git)" "$_durgit/git"
printf '{\n  "name": "duraproj",\n  "remote_match": "example.com/duraproj",\n  "gate": "true"\n}\n' > "$_durap/project.json"
printf '# duraproj\n' > "$_durap/CLAUDE.md"
# Detected: secrets (.env.example) and tests (tests/). Declared: secrets, and
# billing and duracap, which nothing detects. duracap has no discovery rule.
( _fx_cd "$_durar" && git init -q -b main && git config remote.origin.url https://github.com/example.com/duraproj && printf 'duraproj\n' > .felix && printf 'X=1\n' > .env.example \
    && printf 'ok\n' > tests/t && git add -A && git -c user.name=dura -c user.email=dura@example.com commit -q -m dura )
_durar="$(cd "$_durar" && pwd -P)"
_duradeclare() { rm -f "$_durap/capabilities"; printf 'secrets\nbilling\nduracap\n' > "$_durap/capabilities"; }
_duradeclare
{ printf 'dura_bill\tbilling\t-\tls -1 .felix\ttest -f .felix\n'
  printf 'dura_env\tsecrets\t-\tls -1 .env.example\ttest -f .env.example\n'
  printf 'dura_gone\tduragone\t-\tls -1 .felix\ttest -f .felix\n'; } > "$_durap/probes.tsv"
_duragone="$TMP/dura-no-such-dir/capabilities"
_duradangle() { rm -f "$_durap/capabilities"; ln -s "$_duragone" "$_durap/capabilities"; }
_durawhy='the capabilities this project declares could not be read'

# $1 is the mode: read, rc (felix_declared returns nonzero), part (prints one
# declared capability, then returns nonzero) or gone (the substitution ends
# before anything is printed). The rest is the call. Prints status|output.
_duramode() { case "$1" in
    rc)   felix_declared() { return 128; } ;;
    part) felix_declared() { printf 'billing\n'; return 128; } ;;
    gone) felix_declared() { exit 0; } ;;
  esac; }
_duralib() { local _duram="$1"; shift
  ( cd "$_durar" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
    . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"
    _duramode "$_duram"
    _duraout="$("$@")"; printf '%s|%s' "$?" "$_duraout" ) 2>/dev/null; }
# felix_declared_into, which assigns rather than prints: status|value|.
_durainto() { local _duram="$1"
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
    _duramode "$_duram"
    _duradecl=untouched
    felix_declared_into _duradecl "$_durap"; _durarc=$?
    printf '%s|%s|' "$_durarc" "$_duradecl" ) 2>/dev/null; }
_duracli() { ( cd "$_durar" && HOME="$_durahome" PATH="$_durgit:/usr/bin:/bin" "$FELIX" "$@" 2>&1 ); }
# said when $1 holds $2 as a whole line.
_durahas() { case "
$1
" in *"
$2
"*) printf 'said\n' ;; *) printf 'silent\n' ;; esac; }
_duralines() { printf '%s\n' "$1" | awk -v p="$2" '$0 ~ p'; }
_durasays() { case "$1" in *"$2"*) printf 'said\n' ;; *) printf 'silent\n' ;; esac; }
_durarow() { printf '  %-10s %-46s %-7s %s' "$1" "$2" "$3" "$4"; }
_durastate() { { find "$_durap" | LC_ALL=C sort; find "$_durap" -type f -exec cksum {} + | LC_ALL=C sort
                 ls -l "$_durap/capabilities" | awk '{ print $NF }'; } 2>/dev/null | cksum; }

# 1. felix_declared_into.
is  "felix_declared_into assigns a read list its declared lines with no trailing newline and returns 0" \
    "$(_durainto read)" "$(printf '0|secrets\nbilling\nduracap|')"
mv "$_durap/capabilities" "$TMP/dura-caps.keep"
is  "felix_declared_into assigns the empty string and returns 0 when there is no capabilities file" \
    "$(_durainto read)" "0||"
printf '# nothing declared yet\n\n' > "$_durap/capabilities"
is  "felix_declared_into assigns the empty string and returns 0 for a file that declares nothing" \
    "$(_durainto read)" "0||"
mv "$TMP/dura-caps.keep" "$_durap/capabilities"
is  "felix_declared_into returns 2 and leaves the variable alone when felix_declared returns nonzero" \
    "$(_durainto rc)" "2|untouched|"
is  "felix_declared_into returns 2 and leaves the variable alone when felix_declared printed a capability and then returned nonzero" \
    "$(_durainto part)" "2|untouched|"
is  "felix_declared_into returns 2 and leaves the variable alone when the substitution ended before anything was printed" \
    "$(_durainto gone)" "2|untouched|"
_duradangle
is  "felix_declared_into returns 2 and leaves the variable alone over a capabilities link whose target is gone" \
    "$(_durainto read)" "2|untouched|"
_duradeclare

# 2. felix_undeclared.
is  "felix_undeclared over a read list prints only the detected surface nothing declares and returns 0" \
    "$(_duralib read felix_undeclared "$_durar" "$_durap")" "0|tests"
is  "felix_undeclared prints nothing and returns 2 when felix_declared returns nonzero, never every detected surface" \
    "$(_duralib rc felix_undeclared "$_durar" "$_durap")" "2|"
is  "felix_undeclared prints nothing and returns 2 when felix_declared printed a capability and then returned nonzero" \
    "$(_duralib part felix_undeclared "$_durar" "$_durap")" "2|"
is  "felix_undeclared prints nothing and returns 2 when the substitution ended before anything was printed" \
    "$(_duralib gone felix_undeclared "$_durar" "$_durap")" "2|"
mv "$_durap/capabilities" "$TMP/dura-caps.keep"
is  "felix_undeclared with no capabilities file names every detected surface and returns 0, as before" \
    "$(_duralib read felix_undeclared "$_durar" "$_durap")" "$(printf '0|secrets\ntests')"
mv "$TMP/dura-caps.keep" "$_durap/capabilities"

# 6, the library. Read: grounded are billing, secrets and duragone.
is  "felix_probes_gaps over a read list names the declared-only capability and the detected one no probe grounds, and returns 0" \
    "$(_duralib read felix_probes_gaps "$_durap" "$_durar")" "$(printf '0|duracap\ntests')"
is  "and felix_probes_orphans over it names only the probe grounding what nothing enumerates" \
    "$(_duralib read felix_probes_orphans "$_durap" "$_durar")" "0|duragone"
is  "felix_probes_gaps prints nothing and returns 2 in each unread mode, never a gap list without the declared capabilities" \
    "$(_duralib rc felix_probes_gaps "$_durap" "$_durar") $(_duralib part felix_probes_gaps "$_durap" "$_durar") $(_duralib gone felix_probes_gaps "$_durap" "$_durar")" \
    "2| 2| 2|"
is  "felix_probes_orphans prints nothing and returns 2 in each unread mode, never the probe grounding a declared capability as an orphan" \
    "$(_duralib rc felix_probes_orphans "$_durap" "$_durar") $(_duralib part felix_probes_orphans "$_durap" "$_durar") $(_duralib gone felix_probes_orphans "$_durap" "$_durar")" \
    "2| 2| 2|"
mv "$_durap/capabilities" "$TMP/dura-caps.keep"
is  "with no capabilities file the gaps and orphans are read as an empty list, as before" \
    "$(_duralib read felix_probes_gaps "$_durap" "$_durar") $(_duralib read felix_probes_orphans "$_durap" "$_durar")" \
    "$(printf '0|tests 0|billing\nduragone')"
mv "$TMP/dura-caps.keep" "$_durap/capabilities"

# 4, 5 and 6 through the CLI, over the read list first.
_duradoc="$(_duracli doctor)"; _durarc=$?
is  "felix doctor over a read list prints the declared list, the one undeclared surface, the adopt line and the unruled capability, and exits 0" \
    "$_durarc $(_durahas "$_duradoc" 'declared:     secrets billing duracap ') $(_durahas "$_duradoc" 'undeclared:   tests') $(_durasays "$_duradoc" 'adopt with: felix adopt <capability>') $(_durahas "$_duradoc" '  duracap        scored on its own name only')" \
    "0 said said said said"
_durarec="$(_duracli recommend)"; _durarc=$?
is  "felix recommend over a read list prints the declared list, a declared row as active, an undeclared one as waiting, and the list in the handoff" \
    "$_durarc $(_durahas "$_durarec" 'declared:   secrets billing duracap ') $(_durahas "$_durarec" "$(_durarow plugin stripe@claude-plugins-official high 'billing is active here')") $(_durahas "$_durarec" "$(_durarow plugin frontend-design@claude-plugins-official low 'waits for frontend')") $(_durahas "$_durarec" '  Project duraproj, a none codebase. Felix already detected: secrets billing duracap ')" \
    "0 said said said said"
_durapro="$(_duracli probes)"; _durarc=$?
is  "felix probes over a read list prints the gap section with the declared-only capability and the orphan section with only the gone probe, and exits 0" \
    "$_durarc $(_durahas "$_durapro" 'surfaces nothing probes') $(_durasays "$_durapro" '  duracap  ') $(_durahas "$_durapro" 'probes for surfaces nothing enumerates') $(_durahas "$_durapro" '  duragone') $(_durahas "$_durapro" '  billing')" \
    "0 said said said said silent"
mv "$_durap/capabilities" "$TMP/dura-caps.keep"
_duradoc="$(_duracli doctor)"; _durarec="$(_duracli recommend)"
is  "with no capabilities file felix doctor and felix recommend read an empty list as before: nothing declared, both surfaces undeclared, declared none and the billing row waiting" \
    "$(_duralines "$_duradoc" '^(declared|undeclared):') $(_duralines "$_durarec" '^declared:') $(_durahas "$_durarec" "$(_durarow plugin stripe@claude-plugins-official high 'waits for billing')") $(_durasays "$_duradoc$_durarec" 'not known')" \
    "$(printf 'declared:     \nundeclared:   secrets tests') declared:   none said silent"
mv "$TMP/dura-caps.keep" "$_durap/capabilities"

# The CLI over a capabilities link whose target is gone.
_duradangle
_duradoc="$(_duracli doctor)"; _durarc=$?
is  "felix doctor says the declared list and the undeclared surfaces are not known, on the only lines that start with either, and exits 0" \
    "$_durarc $(_duralines "$_duradoc" '^(declared|undeclared):')" \
    "$(printf '0 declared:     not known: %s\nundeclared:   not known: %s' "$_durawhy" "$_durawhy")"
is  "and prints neither undeclared none, the detected surfaces, the paragraph beneath them nor the adopt line" \
    "$(_durasays "$_duradoc" 'undeclared:   none') $(_durasays "$_duradoc" "$(printf '  %-14s %s' secrets 'env templates present')") $(_durasays "$_duradoc" "$(printf '  %-14s %s' tests 'a test suite exists')") $(_durasays "$_duradoc" 'These surfaces exist in the checkout') $(_durasays "$_duradoc" 'adopt with:')" \
    "silent silent silent silent silent"
is  "and its unruled section is the one line saying the capabilities with no discovery rule are not known" \
    "$(_durahas "$_duradoc" "capabilities with no discovery rule: not known: $_durawhy") $(_durahas "$_duradoc" 'capabilities with no discovery rule')" \
    "said silent"
_durarec="$(_duracli recommend)"; _durarc=$?
is  "felix recommend says the declared list is not known on the only header line that starts with declared, never none, and exits 0" \
    "$_durarc $(_duralines "$_durarec" '^declared:')" "0 declared:   not known: $_durawhy"
is  "and a row whose capability is not always says not known whether it is active, and no row says it waits for its capability or that it is active" \
    "$(_durahas "$_durarec" "$(_durarow plugin stripe@claude-plugins-official high 'not known whether billing is active here')") $(_durahas "$_durarec" "$(_durarow plugin frontend-design@claude-plugins-official low 'not known whether frontend is active here')") $(_durasays "$_durarec" 'waits for') $(printf '%s\n' "$_durarec" | awk 'index($0, "is active here") && !index($0, "not known whether ") { n++ } END { print n + 0 }')" \
    "said said silent 0"
is  "and a row for any project still applies to any project over that unread list, and the handoff says the list is not known" \
    "$(_durahas "$_durarec" "$(_durarow plugin superpowers@claude-plugins-official low 'applies to any project')") $(_durahas "$_durarec" "  Project duraproj, a none codebase. Felix already detected: not known: $_durawhy")" \
    "said said"
_durapro="$(_duracli probes)"; _durarc=$?
is  "felix probes says in place of the gap section that the surfaces nothing probes are not known, and exits 0" \
    "$_durarc $(_durahas "$_durapro" "surfaces nothing probes: not known: $_durawhy") $(_durahas "$_durapro" 'surfaces nothing probes') $(_durasays "$_durapro" 'Each was reached by matching filenames')" \
    "0 said silent silent"
is  "and in place of the orphan section that the probes for surfaces nothing enumerates are not known, never naming the probe for billing" \
    "$(_durahas "$_durapro" "probes for surfaces nothing enumerates: not known: $_durawhy") $(_durahas "$_durapro" 'probes for surfaces nothing enumerates') $(_durahas "$_durapro" '  billing') $(_durasays "$_durapro" 'Each grounds a capability')" \
    "said silent silent silent"

# 3. Session start, from a scratch copy of the engine.
mkdir -p "$TMP/dura-plugin"; cp -R "$FROOT/harness" "$TMP/dura-plugin/harness"
cp "$TMP/dura-plugin/harness/lib/detect.sh" "$TMP/dura-detect.keep"
# $1 is appended to the scratch copy's detect.sh, after everything it defines.
_durastart() { local _durao
  { cat "$TMP/dura-detect.keep"; printf '%s\n' "${1:-}"; } > "$TMP/dura-plugin/harness/lib/detect.sh"
  _durao="$(cd "$_durar" && CLAUDE_PLUGIN_ROOT="$TMP/dura-plugin" "$TMP/dura-plugin/harness/hooks/session-start" 2>&1)"
  printf '%s\n' "${_durao//\\n/$'\n'}"; }
_duranot="Capability drift was not checked: $_durawhy."
_duradeclare
_durass="$(_durastart)"
is  "session start over a read list adopts the detected surface nothing declares and says nothing about drift not being checked" \
    "$(_durasays "$_durass" 'Adopted automatically, because the checkout grew them: tests(') $(_durasays "$_durass" 'Capability drift was not checked')" \
    "said silent"
rm -rf "$_durap/stack.tsv" "$_durap/setup.tsv" "$_durap/setup"; _duradeclare
_duradangle; _durabefore="$(_durastate)"
_durass="$(_durastart)"
is  "session start over a capabilities link whose target is gone says drift was not checked, adopts nothing and leaves the project as it was" \
    "$(_durahas "$_durass" "$_duranot") $(_durasays "$_durass" 'Adopted automatically') $([ "$(_durastate)" = "$_durabefore" ] && echo kept || echo changed)" \
    "said silent kept"
_duradeclare; _durabefore="$(_durastate)"
_durass="$(_durastart 'felix_declared() { return 128; }')"
is  "session start whose felix_declared returns nonzero says drift was not checked and adopts nothing, not the surface the list already holds nor the one it lacks" \
    "$(_durahas "$_durass" "$_duranot") $(_durasays "$_durass" 'Adopted automatically') $([ "$(_durastate)" = "$_durabefore" ] && echo kept || echo changed)" \
    "said silent kept"
_duradeclare; _durabefore="$(_durastate)"
_durass="$(_durastart 'felix_undeclared() { printf '"'"'tests\n'"'"'; return 2; }')"
is  "session start whose felix_undeclared printed a surface and returned nonzero adopts nothing and says drift was not checked" \
    "$(_durahas "$_durass" "$_duranot") $(_durasays "$_durass" 'Adopted automatically') $([ "$(_durastate)" = "$_durabefore" ] && echo kept || echo changed)" \
    "said silent kept"
_duradeclare; _durabefore="$(_durastate)"
_durass="$(_durastart 'felix_undeclared() { exit 0; }')"
is  "session start whose felix_undeclared substitution ended before anything was printed says drift was not checked, never silence" \
    "$(_durahas "$_durass" "$_duranot") $(_durasays "$_durass" 'Adopted automatically') $([ "$(_durastate)" = "$_durabefore" ] && echo kept || echo changed)" \
    "said silent kept"

rm -rf "$_durap" "$_durar" "$_durahome" "$TMP/dura-plugin" "$MEM/duraproj"
rm -f "$TMP/dura-detect.keep" "$TMP/dura-caps.keep"
[ -d "$FROOT/state" ] && find "$FROOT/state" -name '*duraproj*' -exec rm -rf {} + 2>/dev/null
is  "and the block for felix_declared_into, felix_undeclared, doctor, recommend, probes and session start leaves the projects, the state and the memory as it found them" "$(_durafixture)" "$_durafound"
unset -f _durafixture _duradeclare _duradangle _duramode _duralib _durainto _duracli _durahas _duralines _durasays _durarow _durastate _durastart
unset _durafound _durap _durar _durahome _duragone _durawhy _duradoc _durarec _durapro _durarc _durass _duranot _durabefore

# Discovery, the toolbox, the admit phase, procedures, the topology, the
# requests and the commissioning gaps say a declared list they could not read,
# never an empty one.
#
# felix_declared returns 2 when something is at `capabilities` and could not
# be read, and a substitution around it can come back empty with status 0 when
# its fork fails. Every reader below still read that as a list with nothing in
# it. Discovery scored nothing and cached "nothing matches" for seven days, and
# felix_capabilities_unruled said every capability had a rule. The toolbox
# matched nothing, and the admit phase matched no nomination. Procedures called
# a stance on a declared capability an orphan. The topology hashed another list,
# so every provider answer read stale, and the requests named the wrong
# capabilities. The commissioning gaps dropped every declared surface. Each one
# now says the list could not be read, and none of them treats that as an
# answer. The libraries are asked with felix_declared failing three ways,
# defined in a subshell after the libs are sourced: it returns 128 having
# printed nothing (nz), it prints a capability and then returns 128 (part), and
# the substitution ends before printing (gone). The capabilities file DOES
# declare both capabilities, so an unread list read as empty shows. The CLI and
# the hook are other processes and cannot see a stub, so there the capabilities
# file is a link whose target is gone. The marketplace is a stub on PATH that
# records each listing it is asked for. Nothing reaches the network or
# installs anything. These assertions were written blind, from the contract
# (items 7 to 13), before the fix, and each was run first against main's
# engine and the branch base. Everything this block makes is removed below,
# and everything it defines is unset.
_durbfixture() { { find "$FROOT/projects" "$FROOT/state" "$MEM" 2>/dev/null | LC_ALL=C sort
                   find "$FROOT/projects" "$FROOT/state" "$MEM" -type f -exec cksum {} + 2>/dev/null | LC_ALL=C sort; } | cksum; }
_durbfound="$(_durbfixture)"
_durbdirs="$(find "$FROOT/state" -type d 2>/dev/null)"
_durbp="$FROOT/projects/durbproj"; _durbr="$TMP/durb-repo"; _durbhome="$TMP/durb-home"
_durbstub="$TMP/durb-bin"; _durbasked="$TMP/durb-asked"; _durbtpl="$FROOT/harness/templates"
_durbnotpl="$TMP/durb-no-templates"; _durbcache="$FROOT/state/discover/durbproj.tsv"
_durbwhy='the capabilities this project declares could not be read'
mkdir -p "$_durbp" "$_durbr" "$_durbhome/.claude/plugins" "$_durbstub" "$_durbnotpl"
printf '{\n  "name": "durbproj",\n  "remote_match": "example.com/durbproj",\n  "gate": "true"\n}\n' > "$_durbp/project.json"
printf '# durbproj\n' > "$_durbp/CLAUDE.md"
( _fx_cd "$_durbr" && git init -q -b main && git config remote.origin.url https://github.com/example.com/durbproj && printf 'durbproj\n' > .felix && git add .felix \
    && git -c user.name=durb -c user.email=durb@example.com commit -q -m durb )
_durbr="$(cd "$_durbr" && pwd -P)"
printf 'durbcap\ndurbgap\n' > "$_durbp/capabilities"
printf 'durbprof\tdurbcap\n' > "$_durbp/profiles.tsv"
printf 'durbroute\tdurb keywords\tdurbprof\t-\n' > "$_durbp/routes.tsv"; cp "$_durbp/routes.tsv" "$TMP/durb-routes.keep"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$_durbp/probes.tsv"
printf 'capability:durbcap\tcommissioning\tdurb-check\ta stance on a declared capability\n' > "$_durbp/procedures.tsv"
printf 'automation_surveyed\t-\t-\t-\tprovider:durbplug:durbskill\t-\t-\n' > "$_durbp/commissioning.tsv"
printf '{"version": 2, "plugins": {\n  "durbcap-tool@durbmkt": [{"scope": "user", "version": "1.0.0"}]\n}}\n' \
  > "$_durbhome/.claude/plugins/installed_plugins.json"
cat > "$_durbstub/claude" <<STUB
#!/bin/sh
case "\$*" in
  "plugin list --json --available")
    printf 'asked\n' >> "$_durbasked"
    printf '[\n  {\n    "name": "durbcap-tool",\n    "description": "a durbcap helper"\n  }\n]\n' ;;
  "plugin list --json") printf '[]\n' ;;
  *) exit 1 ;;
esac
STUB
chmod +x "$_durbstub/claude"

# $1 is read, or how felix_declared fails; the rest is the engine call.
_durblib() { local _durbm="$1"; shift
  ( cd "$_durbr" || exit 99
    HOME="$_durbhome"; FELIX_PLUGIN_CACHE="$_durbhome/.claude/plugins/cache"; FELIX_HOME_DIR="$FROOT"
    PATH="$_durbstub:$_durgit:/usr/bin:/bin"
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/stack.sh"
    . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/route.sh"; . "$FROOT/harness/lib/discover.sh"
    . "$FROOT/harness/lib/toolbox.sh"; . "$FROOT/harness/lib/procedures.sh"; . "$FROOT/harness/lib/candidates.sh"
    case "$_durbm" in
      nz)       felix_declared() { return 128; } ;;
      part)     felix_declared() { printf 'durbcap\n'; return 128; } ;;
      gone)     felix_declared() { exit 0; } ;;
      noclaude) PATH="$_durgit:/usr/bin:/bin"; felix_declared() { return 128; } ;;
    esac
    "$@" ) 2>/dev/null; }
# [output] status, under each of the three ways the list goes unread, and read.
_durbtri() { local _durbm _durbo _durbc _durbs=""
  for _durbm in nz part gone; do
    _durbo="$(_durblib "$_durbm" "$@")"; _durbc=$?
    _durbs="${_durbs}[${_durbo}] ${_durbc} "
  done
  printf '%s' "${_durbs% }"; }
_durbone()  { local _durbo _durbc; _durbo="$(_durblib "$@")"; _durbc=$?; printf '[%s] %s' "$_durbo" "$_durbc"; }
_durbread() { _durbone read "$@"; }
_durbcli() { ( cd "$_durbr" && HOME="$_durbhome" PATH="$_durbstub:$_durgit:/usr/bin:/bin" "$FELIX" "$@" 2>&1 ); }
_durbstart() { local _durbo
  _durbo="$(cd "$_durbr" && HOME="$_durbhome" PATH="$_durgit:/usr/bin:/bin" CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
  printf '%s\n' "${_durbo//\\n/$'\n'}"; }
_durbsays() { case "$1" in *"$2"*) printf 'said\n' ;; *) printf 'silent\n' ;; esac; }
_durbboth() { if printf '%s\n' "$1" | awk -v a="$2" -v b="$3" 'index($0, a) && index($0, b) { f = 1 } END { exit !f }'
              then printf 'said\n'; else printf 'silent\n'; fi; }
_durbwas()  { if [ -s "$_durbasked" ]; then printf 'asked\n'; else printf 'not asked\n'; fi; : > "$_durbasked"; }
_durbis()   { if [ -e "$1" ]; then printf 'there\n'; else printf 'absent\n'; fi; }
_durbnone='[] 2 [] 2 [] 2'
: > "$_durbasked"

_durbtopo="$(_durblib read felix_commission_topology "$_durbp" "$_durbr")"
_durbans="$MEM/durbproj/commission/automation_surveyed.tsv"
_durbreq="$MEM/durbproj/commission/requests/automation_surveyed.md"
_durbobreq="$MEM/durbproj/commission/requests/obligations_surveyed.md"
mkdir -p "$MEM/durbproj/commission/requests"
{ printf '# topology %s\n' "$_durbtopo"; printf 'plugin\tdurbnom\t-\tdurbcap\ta durbcap nomination\n'; printf 'done\t1\n'; } > "$_durbans"
printf 'durb: a request written before\n' > "$_durbreq"

# 7. Discovery's rules, the unruled list and the candidates.
is  "_felix_discover_rules prints nothing and returns 2 for a declared list it could not read, however it went unread" \
    "$(_durbtri _felix_discover_rules "$_durbtpl" "$_durbp")" "$_durbnone"
is  "and over a list it read it emits each declared capability as its own keyword and returns 0" \
    "$(_durbread _felix_discover_rules "$_durbtpl" "$_durbp")" "$(printf '[durbcap\tdurbcap\ndurbgap\tdurbgap] 0')"
is  "felix_capabilities_unruled prints nothing and returns 2 for an unread list, and still returns 0 when the template has no rules table" \
    "$(_durbtri felix_capabilities_unruled "$_durbp" "$_durbtpl") $(_durbone nz felix_capabilities_unruled "$_durbp" "$_durbnotpl")" \
    "$_durbnone [] 0"
is  "and over a list it read it names both declared capabilities no rule covers" \
    "$(_durbread felix_capabilities_unruled "$_durbp" "$_durbtpl")" "$(printf '[durbcap\ndurbgap] 0')"
: > "$_durbasked"
is  "felix_discover_candidates returns 3 with no claude, then 2 printing nothing for an unread list, and never asks the marketplace" \
    "$(_durbone noclaude felix_discover_candidates "$_durbp" "$_durbtpl") $(_durbtri felix_discover_candidates "$_durbp" "$_durbtpl") $(_durbwas)" \
    "[] 3 $_durbnone not asked"
is  "and over a list it read it asks the marketplace and scores the plugin named after a declared capability" \
    "$(_durbread felix_discover_candidates "$_durbp" "$_durbtpl") $(_durbwas)" \
    "$(printf '[3\tdurbcap\tdurbcap-tool\ta durbcap helper] 0 asked')"

# 8. What the toolbox has left to wire.
_durbq="$(printf '[?\t%s] 2' "$_durbwhy")"
is  "felix_toolbox_unwired prints the one line ? and the reason and returns 2 for an unread list, so it never reads as nothing left to wire" \
    "$(_durbtri felix_toolbox_unwired "$_durbp" "$_durbtpl")" "$_durbq $_durbq $_durbq"
is  "and over a list it read it names the installed plugin a route could reach" \
    "$(_durbread felix_toolbox_unwired "$_durbp" "$_durbtpl")" "$(printf '[durbcap-tool\tdurbcap] 0')"

# 9. The admit phase.
_durbq="$(printf '[unknown\t-\t-\t-\t-\t-\t%s, so no nomination was matched to one] 2' "$_durbwhy")"
: > "$_durbasked"
is  "felix_commission_admit prints one unknown row and returns 2 for an unread list without asking the marketplace, and a three-field need still returns 0 before reading" \
    "$(_durbtri felix_commission_admit "$_durbp" "$FROOT" automation_surveyed "$_durbtpl") $(_durbwas) $(_durbone nz felix_commission_admit "$_durbp" "$FROOT" constitution_audited "$_durbtpl")" \
    "$_durbq $_durbq $_durbq not asked [] 0"
is  "and over a list it read it goes looking for the nomination and says nothing could be fetched" \
    "$(_durblib read felix_commission_admit "$_durbp" "$FROOT" automation_surveyed "$_durbtpl" | cut -f1-3,7) $(_durbwas)" \
    "$(printf 'unknown\tplugin\tdurbnom\tnothing to fetch it by: no pinned url and sha in any configured marketplace asked')"

# 10. Procedures.
is  "felix_procedures_items prints nothing and returns 2 for an unread list" \
    "$(_durbtri felix_procedures_items "$_durbp" "$_durbr")" "$_durbnone"
is  "felix_procedures_gaps prints nothing and returns 2 for an unread list" \
    "$(_durbtri felix_procedures_gaps "$_durbp" "$_durbr" "$_durbtpl")" "$_durbnone"
is  "felix_procedures_orphans prints nothing and returns 2 for an unread list, never calling the stance on a declared capability an orphan" \
    "$(_durbtri felix_procedures_orphans "$_durbp" "$_durbr")" "$_durbnone"
is  "and over a list it read the items are both capabilities, the gap is the one with no stance, and nothing is an orphan" \
    "$(_durbread felix_procedures_items "$_durbp" "$_durbr") $(_durbread felix_procedures_gaps "$_durbp" "$_durbr" "$_durbtpl") $(_durbread felix_procedures_orphans "$_durbp" "$_durbr")" \
    "$(printf '[capability:durbcap\ncapability:durbgap] 0 [capability:durbgap] 0 [] 0')"

# 11. The topology and the provider state.
is  "felix_commission_topology prints nothing and returns 2 for an unread list" \
    "$(_durbtri felix_commission_topology "$_durbp" "$_durbr")" "$_durbnone"
is  "and over a list it read it prints the topology the answer file was keyed to" \
    "$([ -n "$_durbtopo" ] && printf 'computed') $(_durbread felix_commission_topology "$_durbp" "$_durbr")" "computed [$_durbtopo] 0"
_durbq="$(printf '[unknown\tthe topology the answer at %s is keyed to could not be computed: %s] 0' "$_durbans" "$_durbwhy")"
is  "felix_commission_provider_state says unknown, never stale, for an answer whose topology could not be computed, and no answer is still awaiting" \
    "$(_durbtri felix_commission_provider_state "$_durbp" "$_durbr" automation_surveyed) $(_durblib nz felix_commission_provider_state "$_durbp" "$_durbr" durb_noanswer | cut -f1)" \
    "$_durbq $_durbq $_durbq awaiting"
is  "and over a list it read the same answer is answered" \
    "$(_durbread felix_commission_provider_state "$_durbp" "$_durbr" automation_surveyed)" "$(printf '[answered\t1 rows at %s] 0' "$_durbans")"

# 12. The requests.
is  "felix_commission_request returns 2 printing nothing for an unread list and leaves the request already there as it was, and with no template is still 1" \
    "$(_durbtri felix_commission_request "$_durbp" "$_durbr" automation_surveyed "$_durbtpl") $(head -1 "$_durbreq") $(_durbone nz felix_commission_request "$_durbp" "$_durbr" automation_surveyed "$_durbnotpl")" \
    "$_durbnone durb: a request written before [] 1"
is  "felix_commission_run with a runner says unknown for a provider row whose request could not be written, and why" \
    "$(_durblib nz felix_commission_run "$_durbp" "$_durbr" true "$_durbtpl" | cut -f1,2,6)" \
    "$(printf 'automation_surveyed\tunknown\tthe request for automation_surveyed could not be written: %s' "$_durbwhy")"
is  "felix_candidates_request returns 3 for an unread list, not the epoch's 2, and writes nothing" \
    "$(_durbtri felix_candidates_request "$_durbp" "$_durbr" "$_durbtpl") $(_durbis "$_durbobreq")" "[] 3 [] 3 [] 3 absent"
is  "over a list it read felix_commission_request writes the request naming both capabilities, and felix_commission_run reads the answer answered" \
    "$(_durbread felix_commission_request "$_durbp" "$_durbr" automation_surveyed "$_durbtpl") $(_durbsays "$(cat "$_durbreq")" 'Felix already detected: durbcap durbgap') $(_durblib read felix_commission_run "$_durbp" "$_durbr" true "$_durbtpl" | cut -f2)" \
    "[$_durbreq] 0 said answered"
is  "and felix_candidates_request writes its request and prints the path" \
    "$(_durbread felix_candidates_request "$_durbp" "$_durbr" "$_durbtpl")" "[$_durbobreq] 0"

# 13. The commissioning gaps.
is  "felix_commission_gaps prints nothing and returns 2 for an unread list" \
    "$(_durbtri felix_commission_gaps "$_durbp" "$_durbr")" "$_durbnone"
is  "and over a list it read it names both declared capabilities and what each lacks" \
    "$(_durbread felix_commission_gaps "$_durbp" "$_durbr")" "$(printf '[durbcap\tno\tyes\tno\ndurbgap\tno\tno\tno] 0')"

# The CLI and the hook over a list they read.
_durbout="$(_durbcli discover)"; _durbrc=$?
is  "felix discover over a list it read lists the matching candidate and exits 0" \
    "$_durbrc $(_durbsays "$_durbout" 'candidates for durbproj') $(_durbsays "$_durbout" durbcap-tool) $(_durbwas)" "0 said said asked"
_durbout="$(_durbcli discover --quiet)"; _durbrc=$?
is  "and felix discover --quiet prints the stamp and the candidate's row" \
    "$_durbrc $(printf '%s\n' "$_durbout" | head -1 | cut -c1-7) $(printf '%s\n' "$_durbout" | sed -n 2p | cut -f1,2)" \
    "$(printf '0 # stamp durbcap-tool\tdurbcap')"
_durbout="$(_durbcli discover --adopt)"; _durbrc=$?
is  "and felix discover --adopt with no current cache fills it and exits 0" \
    "$_durbrc $(_durbsays "$_durbout" 'filling the discovery cache') $(head -1 "$_durbcache" 2>/dev/null | cut -c1-7)" "0 said # stamp"
rm -f "$_durbcache" "$_durbcache.new"; : > "$_durbasked"
_durbout="$(_durbcli toolbox)"; _durbrc=$?
is  "felix toolbox over a list it read lists the plugin a route could reach and counts it" \
    "$_durbrc $(_durbboth "$_durbout" durbcap-tool "could go in 'durbroute'") $(_durbsays "$_durbout" '0 reachable, 0 wired now, 1 could be.')" "0 said said"
_durbout="$(_durbcli toolbox --route)"; _durbrc=$?
is  "and felix toolbox --route wires it into the route" "$_durbrc $(cut -f4 "$_durbp/routes.tsv")" "0 durbcap-tool"
cp "$TMP/durb-routes.keep" "$_durbp/routes.tsv"
_durbout="$(_durbcli procedures)"; _durbrc=$?
is  "felix procedures over a list it read names the capability with no stance and calls nothing unknown" \
    "$_durbrc $(_durbboth "$_durbout" capability:durbgap 'a surface this checkout has') $(_durbsays "$_durbout" 'not known') $(_durbsays "$_durbout" 'stances for things nothing enumerates')" \
    "0 said silent silent"
_durbout="$(_durbcli obligations --request)"; _durbrc=$?
is  "felix obligations --request over a list it read writes the request and exits 0" "$_durbrc $(_durbsays "$_durbout" "wrote $_durbobreq")" "0 said"
_durbout="$(_durbcli commission --status)"
is  "felix commission --status over a list it read lists the surfaces nothing serves" \
    "$(_durbsays "$_durbout" 'surfaces nothing serves, reaches, or grounds') $(_durbboth "$_durbout" durbgap 'no catalogue row serves it') $(_durbsays "$_durbout" 'not known')" \
    "said said silent"
_durbout="$(_durbstart)"
is  "session start over a list it read does not name the provider row among those whose answers could not be read" \
    "$(_durbsays "$_durbout" 'automation_surveyed (unknown') $(_durbsays "$_durbout" 'could not be read, so they are neither owed')" "silent silent"

# The same commands over a capabilities link whose target is gone.
rm -f "$_durbp/capabilities"; ln -s "$TMP/durb-no-such-list" "$_durbp/capabilities"
_durbscored="Nothing was scored for durbproj: $_durbwhy."
_durbout="$(_durbcli discover)"; _durbrc=$?
is  "felix discover over an unread list says nothing was scored and that this is not nothing matches, caches nothing, and exits 2" \
    "$_durbrc $(_durbsays "$_durbout" "$_durbscored") $(_durbsays "$_durbout" 'not "nothing matches"') $(_durbsays "$_durbout" 'Nothing in the marketplaces matches') $(_durbis "$_durbcache") $(_durbwas)" \
    "2 said said silent absent not asked"
_durbout="$(_durbcli discover --quiet)"; _durbrc=$?
is  "felix discover --quiet over an unread list prints nothing at all, no stamp, and exits 2" "[$_durbout] $_durbrc $(_durbis "$_durbcache")" "[] 2 absent"
_durbout="$(_durbcli discover --adopt)"; _durbrc=$?
is  "felix discover --adopt with no current cache over an unread list says nothing was scored, fills no cache, adopts nothing and exits 2" \
    "$_durbrc $(_durbsays "$_durbout" "$_durbscored") $(_durbis "$_durbcache") $(_durbis "$_durbcache.new") $(_durbis "$_durbp/stack.tsv")" \
    "2 said absent absent absent"
_durbout="$(_durbcli toolbox)"; _durbrc=$?
is  "felix toolbox over an unread list says nothing was matched or wired, prints no plugin table and no reachable count, and exits 2" \
    "$_durbrc $(printf '%s\n' "$_durbout" | grep -A2 'toolbox for durbproj' | grep -c "Nothing was matched or wired for durbproj: $_durbwhy.") $(_durbsays "$_durbout" REACHABLE) $(_durbsays "$_durbout" ' reachable, ')" \
    "2 1 silent silent"
_durbout="$(_durbcli toolbox --route)"; _durbrc=$?
is  "felix toolbox --route over an unread list wires nothing and exits 2" \
    "$_durbrc $(_durbsays "$_durbout" "Nothing was matched or wired for durbproj: $_durbwhy.") $(cut -f4 "$_durbp/routes.tsv")" "2 said -"
_durbout="$(_durbcli procedures)"; _durbrc=$?
is  "felix procedures over an unread list says not known, and neither the gap list, the orphan list nor that every item has a stance, and still prints the stance" \
    "$_durbrc $(_durbsays "$_durbout" "not known: $_durbwhy") $(_durbsays "$_durbout" 'nothing answers these') $(_durbsays "$_durbout" 'stances for things nothing enumerates') $(_durbsays "$_durbout" 'Every item has a stance') $(_durbboth "$_durbout" capability:durbcap durb-check)" \
    "0 said silent silent silent said"
rm -f "$_durbobreq"
_durbout="$(_durbcli obligations --request)"; _durbrc=$?
is  "felix obligations --request over an unread list says no request was written and why, writes none, and exits 1" \
    "$_durbrc $(_durbsays "$_durbout" "no request written: $_durbwhy.") $(_durbis "$_durbobreq")" "1 said absent"
_durbout="$(_durbcli commission --status)"
is  "felix commission --status over an unread list says the surfaces nothing serves are not known, and lists none" \
    "$(_durbsays "$_durbout" "surfaces nothing serves, reaches, or grounds: not known: $_durbwhy") $(_durbsays "$_durbout" durbgap)" "said silent"
_durbout="$(_durbstart)"
is  "session start over an unread list names the provider row among those whose answers could not be read, and says no all-clear and owes nothing" \
    "$(_durbsays "$_durbout" "$(printf 'neither owed nor recorded; felix commission --status reads them again:\n  automation_surveyed (unknown: the topology the answer at %s is keyed to could not be computed: %s)' "$_durbans" "$_durbwhy")") $(_durbsays "$_durbout" 'Commissioning: receipt')" \
    "said silent"

rm -rf "$_durbp" "$_durbr" "$_durbhome" "$_durbstub" "$_durbnotpl" "$MEM/durbproj"
rm -f "$_durbasked" "$TMP/durb-routes.keep"
[ -d "$FROOT/state" ] && find "$FROOT/state" -name '*durbproj*' -exec rm -rf {} + 2>/dev/null
_durbnl='
'
find "$FROOT/state" -depth -type d 2>/dev/null | while IFS= read -r _durbd; do
  case "$_durbnl$_durbdirs$_durbnl" in *"$_durbnl$_durbd$_durbnl"*) ;; *) rmdir "$_durbd" 2>/dev/null ;; esac
done
is  "and the block for every other reader of an unread declared list leaves the projects, the state and the memory as it found them" \
    "$(_durbfixture)" "$_durbfound"
unset -f _durbfixture _durblib _durbtri _durbone _durbread _durbcli _durbstart _durbsays _durbboth _durbwas _durbis
unset _durbfound _durbdirs _durbp _durbr _durbhome _durbstub _durbasked _durbtpl _durbnotpl _durbcache _durbwhy \
      _durbnone _durbtopo _durbans _durbreq _durbobreq _durbq _durbout _durbrc _durbscored _durbnl _durbd

# After review, not blind: the readers of the declared capabilities that the
# review of the first pass found still dropped a list, or said one was unread
# when it was not.
#
# The three reviewers (defeat, simpler, omission) read the first pass of
# declared-unread-readers and each demonstrated what follows. A project with no
# commissioning.tsv returned 1 from felix_commission_topology under pipefail,
# because its status was the cat of that table, so felix obligations --request
# refused over a list that was read and an answered request read unknown.
# felix discover --adopt looked at the list only when the cache was stale, so a
# current cache over an unread list adopted its rows and asked claude to install
# them, and a fill whose own read failed after that said the marketplaces could
# not be read. A here-document that cannot be written, and a felix_detect that
# exits inside the group it was unioned in, dropped a list that had been read.
# felix_commission_policy_version opened a capabilities link whose target is gone
# as no file and a pipe by that name as a file to wait on. A failed
# felix_declared forged the sentinel with a last line ending in a dot.
# felix_capture is the helper the sentinel now lives in. R1 to R6 of "After
# review: what changes" in
# docs/handoff/pending/20261001T235048Z-claude-declared-unread-readers.md.
# These assertions were NOT written blind: they were written after the fix, from
# the reviewers' evidence. Each but six was shown failing against the first pass
# at 1e0197ca, the engine this change is a fix to, before it was shown passing:
# 24 of the 30 were red there, and the six that were not are five controls over a
# list that was read and the check that the block leaves the tree as it found it.
# The libraries are asked in subshells after the libs are sourced, under pipefail
# as the CLI and the hooks are. Here-documents are made unwritable inside the
# subshell with an ignored SIGXFSZ and a file size limit of nothing, which a bash
# that writes a here-document to a temporary file meets, 3.2 among them, and a
# bash that sends a small one through a pipe does not: the assertions pass there
# and fail only where the defect is. The CLI and the hook
# are other processes, so there the capabilities file is a link whose target is
# gone. The block makes one scratch copy of the engine, which adds a
# felix_declared that fails only for _felix_discover_rules and, for the last case,
# lacks the obligations template. The marketplace is a stub on PATH that records
# every call. Nothing reaches the network or installs anything.
# Everything this makes is removed below and everything it defines unset.
_durcfixture() { { find "$FROOT/projects" "$FROOT/state" "$MEM" 2>/dev/null | LC_ALL=C sort
                   find "$FROOT/projects" "$FROOT/state" "$MEM" -type f -exec cksum {} + 2>/dev/null | LC_ALL=C sort; } | cksum; }
_durcfound="$(_durcfixture)"
_durcdirs="$(find "$FROOT/state" -type d 2>/dev/null)"
_durcp="$FROOT/projects/durcproj"; _durcr="$TMP/durc-repo"; _durchome="$TMP/durc-home"
_durcstub="$TMP/durc-bin"; _durcasked="$TMP/durc-asked"; _durctpl="$FROOT/harness/templates"
_durcpv="$TMP/durc-pv"; _durceng="$TMP/durc-plugin"; _durccache="$FROOT/state/discover/durcproj.tsv"
_durcwhy='the capabilities this project declares could not be read'
_durcgone="$TMP/durc-no-such-list"
mkdir -p "$_durcp" "$_durcr/tests" "$_durchome/.claude/plugins" "$_durcstub" "$_durcpv"
printf '{\n  "name": "durcproj",\n  "remote_match": "example.com/durcproj",\n  "gate": "true"\n}\n' > "$_durcp/project.json"
printf '# durcproj\n' > "$_durcp/CLAUDE.md"
# Detected: secrets (.env.example) and tests (tests/). Declared: secrets, and
# billing, durccap and durcgap, which nothing detects. A probe grounds billing
# and durccap, and another one a durcghost that nothing declares or detects.
( _fx_cd "$_durcr" && git init -q -b main && git config remote.origin.url https://github.com/example.com/durcproj && printf 'durcproj\n' > .felix && printf 'X=1\n' > .env.example \
    && printf 'ok\n' > tests/t && git add -A && git -c user.name=durc -c user.email=durc@example.com commit -q -m durc )
_durcr="$(cd "$_durcr" && pwd -P)"
_durcdeclare() { rm -f "$_durcp/capabilities"; printf 'secrets\nbilling\ndurccap\ndurcgap\n' > "$_durcp/capabilities"; }
_durcdangle() { rm -f "$_durcp/capabilities"; ln -s "$_durcgone" "$_durcp/capabilities"; }
_durcdeclare
{ printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n'
  printf 'durc_bill\tbilling\t-\tls -1 .felix\ttest -f .felix\n'
  printf 'durc_cap\tdurccap\t-\tls -1 .felix\ttest -f .felix\n'
  printf 'durc_ghost\tdurcghost\t-\tls -1 .felix\ttest -f .felix\n'; } > "$_durcp/probes.tsv"
printf '{"name": "durcpv"}\n' > "$_durcpv/project.json"
cat > "$_durcstub/claude" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >> "$_durcasked"
case "\$*" in
  "plugin list --json --available") printf '[]\n' ;;
  "plugin list --json") printf '[]\n' ;;
  *) exit 1 ;;
esac
STUB
chmod +x "$_durcstub/claude"; : > "$_durcasked"

# $1 is the mode: w (everything as it is), nohd (here-documents cannot be written)
# or exit0 (felix_detect exits where it is called). The rest is the call, which is
# run under pipefail. Prints status|output.
_durcrun() { local _durcm="$1"; shift
  ( cd "$_durcr" || exit 99
    set -o pipefail
    HOME="$_durchome"; FELIX_HOME_DIR="$FROOT"; PATH="$_durcstub:$_durgit:/usr/bin:/bin"
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/stack.sh"
    . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/route.sh"; . "$FROOT/harness/lib/discover.sh"
    . "$FROOT/harness/lib/toolbox.sh"; . "$FROOT/harness/lib/procedures.sh"; . "$FROOT/harness/lib/candidates.sh"
    . "$FROOT/harness/lib/probes.sh"
    case "$_durcm" in
      nohd)  trap '' XFSZ; ulimit -f 0 ;;
      exit0) felix_detect() { exit 0; } ;;
    esac
    _durco="$("$@")"; printf '%s|%s' "$?" "$_durco" ) 2>/dev/null; }
_durccli() { ( cd "$_durcr" && HOME="$_durchome" PATH="$_durcstub:$_durgit:/usr/bin:/bin" "$FELIX" "$@" 2>&1 ); }
_durcsays() { case "$1" in *"$2"*) printf 'said\n' ;; *) printf 'silent\n' ;; esac; }
_durcis()   { if [ -e "$1" ]; then printf 'there\n'; else printf 'absent\n'; fi; }
_durcasks() { grep -c "$1" "$_durcasked" 2>/dev/null | tr -d ' '; : > "$_durcasked"; }

# 1. A project with no commissioning.tsv, under pipefail (R1).
_durctopo="$(_durcrun w felix_commission_topology "$_durcp" "$_durcr")"
is  "felix_commission_topology returns 0 with a hash for a project with no commissioning.tsv, under pipefail" \
    "${_durctopo%%|*} ${#_durctopo}" "0 42"
_durcobreq="$MEM/durcproj/commission/requests/obligations_surveyed.md"
_durcout="$(_durccli obligations --request)"; _durcrc=$?
is  "felix obligations --request over a list it read, for a project with no commissioning.tsv, writes the request and exits 0" \
    "$_durcrc $(_durcsays "$_durcout" "wrote $_durcobreq") $(_durcis "$_durcobreq")" "0 said there"
mkdir -p "$MEM/durcproj/commission"
for _durcn in automation_surveyed obligations_surveyed; do
  { printf '# topology %s\n' "${_durctopo#*|}"; printf 'plugin\tdurcnom\t-\tdurccap\ta nomination\n'; printf 'done\t1\n'; } \
    > "$MEM/durcproj/commission/$_durcn.tsv"
done
_durcst1="$(_durcrun w felix_commission_provider_state "$_durcp" "$_durcr" automation_surveyed | cut -f1)"
_durcst2="$(_durcrun w felix_commission_provider_state "$_durcp" "$_durcr" obligations_surveyed | cut -f1)"
is  "and an answer keyed to that topology reads answered, for the automation request and the obligations one" \
    "$_durcst1 $_durcst2" "0|answered 0|answered"
rm -f "$_durcobreq"

# 2. felix discover --adopt over a current cache and an unread list (R2).
_durcstamp="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/discover.sh"; _felix_discover_stamp_line "$FROOT/harness/templates" )"
mkdir -p "$(dirname "$_durccache")"
_durccurrent() { { printf '%s\n' "$_durcstamp"; printf 'durcnom\tdurccap\tlow\tdurcdigest\n'; } > "$_durccache"; }
_durccurrent; : > "$_durcasked"
_durcout="$(_durccli discover --adopt)"; _durcrc=$?
is  "felix discover --adopt over a current cache and a list it read adopts the row and asks claude to install it" \
    "$_durcrc $(_durcsays "$_durcout" 'adopting for durcproj') $(_durcis "$_durcp/stack.tsv") $(_durcasks 'plugin install durcnom')" "0 said there 1"
rm -f "$_durcp/stack.tsv"; _durcdangle; _durccurrent; : > "$_durcasked"
_durcout="$(_durccli discover --adopt)"; _durcrc=$?
is  "felix discover --adopt over a current cache and an unread list says nothing was scored, adopts nothing, installs nothing and exits 2" \
    "$_durcrc $(_durcsays "$_durcout" "Nothing was scored for durcproj: $_durcwhy.") $(_durcsays "$_durcout" 'adopting for') $(_durcis "$_durcp/stack.tsv") $(_durcasks 'install')" \
    "2 said silent absent 0"
rm -f "$_durccache" "$_durcp/stack.tsv"; _durcdeclare

# 3. The --adopt fill whose own read fails after the check (R2).
mkdir -p "$_durceng"; cp -R "$FROOT/harness" "$_durceng/harness"
sed -e 's/^felix_declared() {$/_durc_real_declared() {/' "$_durceng/harness/lib/detect.sh" > "$_durceng/detect.new"
cat >> "$_durceng/detect.new" <<'EOF'
felix_declared() {
  if [ -n "${DURC_FAIL:-}" ]; then case " ${FUNCNAME[*]:-} " in *" _felix_discover_rules "*) return 128 ;; esac; fi
  _durc_real_declared "$@"
}
EOF
cp "$_durceng/detect.new" "$_durceng/harness/lib/detect.sh"
_durceng_cli() { ( cd "$_durcr" && HOME="$_durchome" PATH="$_durcstub:$_durgit:/usr/bin:/bin" FELIX_HOME="$FROOT" "$_durceng/harness/felix" "$@" 2>&1 ); }
: > "$_durcasked"
_durcout="$(_durceng_cli discover --adopt)"; _durcrc=$?
is  "through the engine copy and over a list it read, felix discover --adopt fills the cache and finds nothing to adopt" \
    "$_durcrc $(_durcsays "$_durcout" 'filling the discovery cache') $(_durcsays "$_durcout" 'Nothing to adopt for durcproj.') $(head -1 "$_durccache" 2>/dev/null | cut -c1-7)" "0 said said # stamp"
rm -f "$_durccache" "$_durccache.new"; : > "$_durcasked"
_durcout="$(DURC_FAIL=1 _durceng_cli discover --adopt)"; _durcrc=$?
is  "felix discover --adopt whose fill cannot read the rules after the check says nothing was scored, not that the marketplaces could not be read, fills nothing, adopts nothing and exits 2" \
    "$_durcrc $(_durcsays "$_durcout" "Nothing was scored for durcproj: $_durcwhy.") $(_durcsays "$_durcout" 'The marketplaces could not be read') $(_durcis "$_durccache") $(_durcis "$_durccache.new") $(_durcis "$_durcp/stack.tsv")" \
    "2 said silent absent absent absent"

# 4. Here-documents that cannot be written (R3).
_durcwr() { _durcrun w "$@"; }
_durcnh() { _durcrun nohd "$@"; }
is  "_felix_discover_rules gives the same rules and status when here-documents cannot be written" \
    "$(_durcnh _felix_discover_rules "$_durctpl" "$_durcp")" "$(_durcwr _felix_discover_rules "$_durctpl" "$_durcp")"
is  "felix_capabilities_unruled gives the same list and status when here-documents cannot be written" \
    "$(_durcnh felix_capabilities_unruled "$_durcp" "$_durctpl")" "$(_durcwr felix_capabilities_unruled "$_durcp" "$_durctpl")"
is  "felix_procedures_items gives the same items and status when here-documents cannot be written" \
    "$(_durcnh felix_procedures_items "$_durcp" "$_durcr")" "$(_durcwr felix_procedures_items "$_durcp" "$_durcr")"
# A well-formed stance on a declared capability is there first, so that a here-document
# that cannot be written, in the walk over the stances, closes nothing and calls it a gap.
# Until 2026-10-08 this ran before any procedures.tsv existed and could not fail for that.
printf 'capability:durccap\tcommissioning\tdurc-check\ta stance on a declared capability\n' > "$_durcp/procedures.tsv"
is  "felix_procedures_gaps gives the same gaps and status when here-documents cannot be written" \
    "$(_durcnh felix_procedures_gaps "$_durcp" "$_durcr" "$_durctpl")" "$(_durcwr felix_procedures_gaps "$_durcp" "$_durcr" "$_durctpl")"
printf 'capability:durcghost\tcommissioning\tdurc-check\ta stance on nothing that exists\n' >> "$_durcp/procedures.tsv"
is  "felix_procedures_orphans gives the same orphans and status when here-documents cannot be written" \
    "$(_durcnh felix_procedures_orphans "$_durcp" "$_durcr")" "$(_durcwr felix_procedures_orphans "$_durcp" "$_durcr")"
_durcorph="$(_durcwr felix_procedures_orphans "$_durcp" "$_durcr")"
rm -f "$_durcp/procedures.tsv"
is  "felix_probes_gaps gives the same gaps and status when here-documents cannot be written" \
    "$(_durcnh felix_probes_gaps "$_durcp" "$_durcr")" "$(_durcwr felix_probes_gaps "$_durcp" "$_durcr")"
is  "felix_probes_orphans gives the same orphans and status when here-documents cannot be written" \
    "$(_durcnh felix_probes_orphans "$_durcp" "$_durcr")" "$(_durcwr felix_probes_orphans "$_durcp" "$_durcr")"
is  "felix_commission_gaps gives the same rows and status when here-documents cannot be written" \
    "$(_durcnh felix_commission_gaps "$_durcp" "$_durcr")" "$(_durcwr felix_commission_gaps "$_durcp" "$_durcr")"
_durcj() { awk '{ printf "%s%s", (NR > 1 ? " " : ""), $0 } END { print "" }'; }
is  "and over writable ones the rules, the unruled, the items, the gaps and the orphans are the lists this project's tables give" \
    "$(_durcwr _felix_discover_rules "$_durctpl" "$_durcp" | cut -f1 | _durcj) ; $(_durcwr felix_capabilities_unruled "$_durcp" "$_durctpl" | _durcj) ; $(_durcwr felix_procedures_items "$_durcp" "$_durcr" | _durcj) ; $(_durcwr felix_procedures_gaps "$_durcp" "$_durcr" "$_durctpl" | _durcj) ; $_durcorph ; $(_durcwr felix_probes_gaps "$_durcp" "$_durcr" | _durcj) ; $(_durcwr felix_probes_orphans "$_durcp" "$_durcr" | _durcj) ; $(_durcwr felix_commission_gaps "$_durcp" "$_durcr" | cut -f1 | _durcj)" \
    "0|secrets billing durccap durcgap ; 0|durccap durcgap ; 0|capability:billing capability:durccap capability:durcgap capability:secrets capability:tests ; 0|capability:billing capability:durccap capability:durcgap capability:secrets capability:tests ; 0|capability:durcghost ; 0|durcgap secrets tests ; 0|durcghost ; 0|billing durccap durcgap secrets tests"

# 5. A felix_detect that exits inside the union (R3).
_durcxo="$(_durcrun exit0 felix_probes_orphans "$_durcp" "$_durcr")"
_durcxg="$(_durcrun exit0 felix_probes_gaps "$_durcp" "$_durcr")"
is  "felix_probes_orphans does not call the probe grounding a declared capability an orphan when felix_detect exits inside the union, and still names the one that grounds nothing" \
    "$_durcxo" "0|durcghost"
is  "and felix_probes_gaps still names the declared capability nothing grounds" \
    "$_durcxg" "$(printf '0|durcgap\nsecrets')"

# 6. The policy version over a table that is there and is not a regular file (R4).
_durcpol() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/commission.sh"
               felix_commission_policy_version "$_durcpv" ) 2>/dev/null; }
_durcabsent="$(_durcpol)"
ln -s "$_durcgone" "$_durcpv/capabilities"; _durcdang="$(_durcpol)"; rm -f "$_durcpv/capabilities"
printf 'secrets\n' > "$_durcpv/capabilities"; _durcreg="$(_durcpol)"
is  "the policy version hashes a capabilities link whose target is gone differently from no capabilities file, and a regular file differently again" \
    "$([ "$_durcabsent" != "$_durcdang" ] && echo different) $([ "$_durcreg" != "$_durcabsent" ] && [ "$_durcreg" != "$_durcdang" ] && echo different)" "different different"
rm -f "$_durcpv/capabilities"
# A watchdog that kills only the process group it made: the child is its own
# group leader, so the cat a hung check leaves behind dies with it, and nothing
# is matched by name. 124 is a call that did not answer in time.
_durcwatch() { perl -MPOSIX=WNOHANG -e '
    my ($secs, @cmd) = @ARGV;
    my $pid = fork(); die "fork: $!" unless defined $pid;
    if (!$pid) { setpgrp(0, 0); exec @cmd or exit 127 }
    for (my $i = 0; $i < $secs * 20; $i++) {
      select(undef, undef, undef, 0.05);
      if (waitpid($pid, WNOHANG) == $pid) { exit($? >> 8) }
    }
    kill "KILL", -$pid; waitpid($pid, 0); exit 124' "$@"; }
if command -v perl >/dev/null 2>&1; then
  mkfifo "$_durcpv/capabilities"
  _durcfifo="$(_durcwatch 10 bash -c '. "$1/harness/lib/resolve.sh"; . "$1/harness/lib/verify.sh"; . "$1/harness/lib/commission.sh"; felix_commission_policy_version "$2"' _ "$FROOT" "$_durcpv" 2>/dev/null)"; _durcrc=$?
  is  "a pipe by the name of a table is answered within ten seconds and is never opened, and hashes as something that is there and is not a file" \
      "$_durcrc $([ "$_durcfifo" = "$_durcdang" ] && echo as-a-dangling-link)" "0 as-a-dangling-link"
  rm -f "$_durcpv/capabilities"
else
  skip "a pipe by the name of a table is answered within ten seconds and is never opened" "no perl for the watchdog"
fi

# 7. The sentinel (R5).
_durcinto() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
                case "$1" in fail) felix_declared() { printf 'secrets\nbilling.\n'; return 128; } ;; esac
                _durcv=untouched; felix_declared_into _durcv "$_durcp"; _durcir=$?
                printf '%s|%s|' "$_durcir" "$_durcv" ) 2>/dev/null; }
is  "felix_declared_into returns 2 and leaves the variable alone for a felix_declared that printed a last line ending in a dot and then failed" \
    "$(_durcinto fail)" "2|untouched|"
printf 'secrets\nbilling.\n' > "$_durcp/capabilities"
is  "and a list that was read, whose last capability ends in a dot, is assigned whole" \
    "$(_durcinto read)" "$(printf '0|secrets\nbilling.|')"
_durcdeclare

# 8. felix_capture (R3).
_durcok()   { printf 'a\nb\n'; }
_durcbare() { printf x; }
_durcbad()  { printf 'a\n'; return 3; }
_durcgoes() { exit 0; }
_durcargs() { printf '[%s]' "$@"; }
_durccapt() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
                _durcv=untouched; felix_capture _durcv "$@"; _durccr=$?
                printf '%s|%s|' "$_durccr" "$_durcv" ) 2>/dev/null; }
is  "felix_capture drops one trailing newline and assigns output that has none as it is" \
    "$(_durccapt _durcok) $(_durccapt _durcbare)" "$(printf '0|a\nb| 0|x|')"
is  "and passes its arguments to the command as they are, an empty one and one with a space included" \
    "$(_durccapt _durcargs 'x y' '' z)" "0|[x y][][z]|"
is  "and returns 2 leaving the variable alone for a command that fails or exits 0 before printing" \
    "$(_durccapt _durcbad) $(_durccapt _durcgoes)" "2|untouched| 2|untouched|"
_durccol=0; _durcnames="out output rc status ret res result val value v x s str line item items list name var cmd tmp t r nl rest declared union rules sorted topo"
for _durcn in $_durcnames; do
  _durcgot="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; _durcok() { printf 'a\nb\n'; }
               eval "f() { local $_durcn=keep; felix_capture $_durcn _durcok; printf '%s' \"\$$_durcn\"; }; f" 2>/dev/null )"
  [ "$_durcgot" = "$(printf 'a\nb')" ] && _durccol=$((_durccol + 1))
done
is  "and assigns a caller's local of any name it might have used itself" "$_durccol of $(printf '%s\n' $_durcnames | grep -c .)" "$(printf '%s\n' $_durcnames | grep -c .) of $(printf '%s\n' $_durcnames | grep -c .)"

# 9. Session start over an unread list, with an answer file for a provider row (R6).
_durcstart() { local _durco
  _durco="$(cd "$_durcr" && HOME="$_durchome" PATH="$_durgit:/usr/bin:/bin" CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
  printf '%s\n' "${_durco//\\n/$'\n'}"; }
printf 'automation_surveyed\t-\t-\t-\tprovider:durcplug:durcskill\t-\t-\n' > "$_durcp/commissioning.tsv"
_durctopo2="$(_durcrun w felix_commission_topology "$_durcp" "$_durcr")"
{ printf '# topology %s\n' "${_durctopo2#*|}"; printf 'plugin\tdurcnom\t-\tdurccap\ta nomination\n'; printf 'done\t1\n'; } \
  > "$MEM/durcproj/commission/automation_surveyed.tsv"
_durctl="Commissioning: the topology these answers are keyed to could not be computed: $_durcwhy."
_durcs1="$(_durcstart)"
is  "session start over a list it read says nothing of a topology that could not be computed" "$(_durcsays "$_durcs1" 'could not be computed')" "silent"
_durcdangle
_durcs2="$(_durcstart)"
_durcrow="automation_surveyed (unknown: the topology the answer at $MEM/durcproj/commission/automation_surveyed.tsv is keyed to could not be computed: $_durcwhy)"
is  "session start over a capabilities link whose target is gone, with an answer file, names the row with its own detail, that the topology the answer is keyed to could not be computed, with no sentence of its own about the topology and no all-clear" \
    "$(_durcsays "$_durcs2" "$_durcrow") $(_durcsays "$_durcs2" "$_durctl") $(_durcsays "$_durcs2" 'Commissioning: receipt')" "said silent silent"
_durcdeclare

# 10. felix obligations --request with no request template (R6).
rm -f "$_durcp/commissioning.tsv" "$_durcobreq"
rm -f "$_durceng/harness/templates/commission/obligations_surveyed.md"
_durcout="$(_durceng_cli obligations --request)"; _durcrc=$?
is  "felix obligations --request with no template for its request says the template is missing, not that the epoch cannot be computed, writes none and exits 1" \
    "$_durcrc $(_durcsays "$_durcout" 'no request written: its template is missing, or it could not be written under the memory root.') $(_durcsays "$_durcout" 'decision epoch') $(_durcis "$_durcobreq")" \
    "1 said silent absent"

rm -rf "$_durcp" "$_durcr" "$_durchome" "$_durcstub" "$_durcpv" "$_durceng" "$MEM/durcproj"
rm -f "$_durcasked"
[ -d "$FROOT/state" ] && find "$FROOT/state" -name '*durcproj*' -exec rm -rf {} + 2>/dev/null
_durcnl='
'
find "$FROOT/state" -depth -type d 2>/dev/null | while IFS= read -r _durcd; do
  case "$_durcnl$_durcdirs$_durcnl" in *"$_durcnl$_durcd$_durcnl"*) ;; *) rmdir "$_durcd" 2>/dev/null ;; esac
done
is  "and the block for the after-review fixes to every other reader of an unread declared list leaves the projects, the state and the memory as it found them" \
    "$(_durcfixture)" "$_durcfound"
unset -f _durcj _durcfixture _durcdeclare _durcdangle _durcrun _durccli _durcsays _durcis _durcasks _durccurrent _durceng_cli _durcwr _durcnh \
         _durcpol _durcwatch _durcinto _durcok _durcbare _durcbad _durcgoes _durcargs _durccapt _durcstart
unset _durcfound _durcdirs _durcp _durcr _durchome _durcstub _durcasked _durctpl _durcpv _durceng _durccache _durcwhy _durcgone \
      _durctopo _durctopo2 _durcobreq _durcout _durcrc _durcn _durcst1 _durcst2 _durcstamp _durcorph _durcxo _durcxg _durcabsent \
      _durcdang _durcreg _durcfifo _durccol _durcnames _durcgot _durcs1 _durcs2 _durctl _durcrow _durcnl _durcd

# felix commission adopts nothing over a declared list it could not read, and
# says that capability drift was not checked.
#
# Since #378 a full `felix commission` adopts, before it asks any row, every
# capability the checkout shows and the project has not declared, as session
# start does. When the project's declared-capabilities list could not be read,
# a full run adopts nothing, leaves capabilities, stack.tsv and setup.tsv byte
# for byte, prints no `adopted before this run` line, and prints
# `Capability drift was not checked: <why>.` after the `commissioning for
# <project>` line and before the first row line; the rows and the summary are
# still printed. Over a list that was read (one that declares something, none
# at all, or an empty one) a full run adopts and says so, exactly as before,
# and never prints the drift line. `--status` adopts nothing and prints neither
# line, read or unread. Item 14 of the contract in
# docs/handoff/pending/20261001T235048Z-claude-declared-unread-readers.md.
# These assertions were written blind, from that contract item alone, before
# the fix: the body of cmd_commission was not read.
# The CLI is another process, so the unread list is a `capabilities` link whose
# target, in a directory that exists, does not: a write through the link would
# create it. The checkout shows ci (a workflow file) and secrets (.env.example);
# the read fixture declares secrets only, so ci is there to adopt. The
# commissioning table holds two rows with no grounds, one done and one held, so
# an unread list changes neither row and the summary is known in advance.
# HOME is a scratch directory and PATH holds a `claude` that logs and refuses
# everything, so nothing reaches the network, ~/.claude or an installed CLI.
# The exit status is not part of the item and is not asserted.
# Everything this makes is removed below and everything it defines unset.
_durdfixture() { { find "$FROOT/projects" "$FROOT/state" "$MEM" 2>/dev/null | LC_ALL=C sort
                   find "$FROOT/projects" "$FROOT/state" "$MEM" -type f -exec cksum {} + 2>/dev/null | LC_ALL=C sort; } | cksum; }
_durdfound="$(_durdfixture)"
_durddirs="$(find "$FROOT/state" -type d 2>/dev/null)"
_durdp="$FROOT/projects/durdproj"; _durdr="$TMP/durd-repo"; _durdhome="$TMP/durd-home"; _durdbin="$TMP/durd-bin"
_durdasked="$TMP/durd-asked"; _durdgone="$TMP/durd-no-such-list"
_durdwhy='the capabilities this project declares could not be read'
_durddrift="Capability drift was not checked: $_durdwhy."
_durdadopted='adopted before this run, because the checkout shows them:'
mkdir -p "$_durdp" "$_durdr/.github/workflows" "$_durdhome" "$_durdbin"
printf '{\n  "name": "durdproj",\n  "remote_match": "example.com/durdproj",\n  "gate": "true"\n}\n' > "$_durdp/project.json"
printf '# durdproj\n' > "$_durdp/CLAUDE.md"
{ printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\n'
  printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n'
  printf 'durdheld\t-\t-\t-\t-\ttest -f durd-never-made\t5\n'; } > "$_durdp/commissioning.tsv"
( _fx_cd "$_durdr" && git init -q -b main && git config remote.origin.url https://github.com/example.com/durdproj && printf 'durdproj\n' > .felix && printf 'on: push\n' > .github/workflows/ci.yml \
    && printf 'X=1\n' > .env.example && git add -A && git -c user.name=durd -c user.email=durd@example.com commit -q -m durd )
_durdr="$(cd "$_durdr" && pwd -P)"
cat > "$_durdbin/claude" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >> "$_durdasked"
exit 2
STUB
chmod +x "$_durdbin/claude"

# $1 is how capabilities is left: read (declares secrets), none (no file),
# empty (a file that declares nothing) or unread (a link whose target is gone).
# stack.tsv and setup.tsv are reset to their headers and adoption's runbooks
# removed, so every run starts from the same tables.
_durdset() {
  rm -rf "$_durdp/setup"; rm -f "$_durdp/capabilities"
  printf '# k\tn\ts\tr\tc\n' > "$_durdp/stack.tsv"
  printf '# id\ttitle\tcapability\tcheck\n' > "$_durdp/setup.tsv"
  case "$1" in
    read)   printf 'secrets\n' > "$_durdp/capabilities" ;;
    empty)  : > "$_durdp/capabilities" ;;
    unread) ln -s "$_durdgone" "$_durdp/capabilities" ;;
  esac
  cp "$_durdp/stack.tsv" "$TMP/durd-stack.keep"; cp "$_durdp/setup.tsv" "$TMP/durd-setup.keep"
  rm -f "$TMP/durd-caps.keep"; [ -f "$_durdp/capabilities" ] && cp "$_durdp/capabilities" "$TMP/durd-caps.keep"
  return 0; }
_durdcli() { ( cd "$_durdr" && HOME="$_durdhome" PATH="$_durdbin:$_durgit:/usr/bin:/bin" "$FELIX" commission "$@" 2>&1 ); }
# said when $1 holds $2 as a whole line; silent otherwise.
_durdline() { case "
$1
" in *"
$2
"*) printf 'said\n' ;; *) printf 'silent\n' ;; esac; }
# said when $1 holds $2 anywhere.
_durdsays() { case "$1" in *"$2"*) printf 'said\n' ;; *) printf 'silent\n' ;; esac; }
# said when some line of $1 begins with $2.
_durdbegins() { printf '%s\n' "$1" | awk -v p="$2" 'index($0, p) == 1 { f = 1 } END { print (f ? "said" : "silent") }'; }
# The first line number of $1 equal to $2, or 0.
_durdat() { printf '%s\n' "$1" | awk -v w="$2" '$0 == w { print NR; f = 1; exit } END { if (!f) print 0 }'; }
# The first line number of a row line for either row, or 0.
_durdrow1() { printf '%s\n' "$1" | awk '/^  [a-z-]+ +(marker|durdheld)( |$)/ { print NR; f = 1; exit } END { if (!f) print 0 }'; }
# The summary line, or nothing.
_durdsum() { printf '%s\n' "$1" | grep -E '^[0-9]+ done, [0-9]+ held, [0-9]+ unknown, ' | head -n 1; }
# ran when the report has its head line and a summary line, so that "nothing
# changed" and "nothing printed" are read from a run that got that far.
_durdran() { if [ "$(_durdline "$1" 'commissioning for durdproj')" = said ] && [ -n "$(_durdsum "$1")" ]; then
               printf 'ran\n'; else printf 'short\n'; fi; }
# kept when capabilities is still a link to the same target and that target is
# still nothing at all.
_durdlink() { if [ -L "$_durdp/capabilities" ] && [ "$(readlink "$_durdp/capabilities")" = "$_durdgone" ]; then
                printf 'link\n'; else printf 'gone\n'; fi; }
_durdtarget() { if [ -e "$_durdgone" ] || [ -L "$_durdgone" ]; then printf 'made\n'; else printf 'absent\n'; fi; }
_durdsame() { cmp -s "$1" "$2" && printf 'same\n' || printf 'changed\n'; }
_durdcaps() { grep -vE '^[[:space:]]*(#|$)' "$_durdp/capabilities" 2>/dev/null | LC_ALL=C sort | tr '\n' ' '; }

# The fixture: the checkout shows ci, and the read list declares only secrets.
_durdset read
_durddet="$( ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; felix_detect "$_durdr" ) 2>/dev/null | LC_ALL=C sort -u | tr '\n' ' ')"
is  "the durd checkout shows ci and secrets, and the read fixture declares secrets and not ci" \
    "$(_durdsays " $_durddet" ' ci ') $(_durdsays " $_durddet" ' secrets ') $(_durdcaps)" "said said secrets "

# Unread, --status.
_durdset unread
_durdout="$(_durdcli --status)"
is  "felix commission --status over a capabilities link whose target is gone prints its report, no adopted line and no drift line" \
    "$(_durdran "$_durdout") $(_durdsays "$_durdout" 'adopted before this run') $(_durdsays "$_durdout" 'Capability drift was not checked')" \
    "ran silent silent"
is  "and leaves the link a link to the same target, creates nothing there, and leaves stack.tsv and setup.tsv byte for byte" \
    "$(_durdlink) $(_durdtarget) $(_durdsame "$_durdp/stack.tsv" "$TMP/durd-stack.keep") $(_durdsame "$_durdp/setup.tsv" "$TMP/durd-setup.keep")" \
    "link absent same same"

# Unread, a full run.
_durdset unread
_durdls="$(ls -A "$_durdp")"
_durdout="$(_durdcli)"
_durdrun="$(_durdran "$_durdout")"
if [ "$_durdrun" != ran ]; then
  for _durdn in "an unread full run leaves capabilities a link to the same target" \
                "an unread full run creates nothing at the link's target" \
                "an unread full run leaves stack.tsv byte for byte" \
                "an unread full run leaves setup.tsv byte for byte" \
                "an unread full run adds no entry to the project directory, so no setup runbook either"; do
    bad "$_durdn" "the run printed no head line and summary, so nothing changed proves nothing: $(printf '%s\n' "$_durdout" | head -n 4)"
  done
else
  is  "an unread full run leaves capabilities a link to the same target" "$(_durdlink)" "link"
  is  "an unread full run creates nothing at the link's target" "$(_durdtarget)" "absent"
  is  "an unread full run leaves stack.tsv byte for byte" "$(_durdsame "$_durdp/stack.tsv" "$TMP/durd-stack.keep")" "same"
  is  "an unread full run leaves setup.tsv byte for byte" "$(_durdsame "$_durdp/setup.tsv" "$TMP/durd-setup.keep")" "same"
  is  "an unread full run adds no entry to the project directory, so no setup runbook either" "$(ls -A "$_durdp")" "$_durdls"
fi
is  "an unread full run prints its report and no line beginning adopted before this run" \
    "$_durdrun $(_durdbegins "$_durdout" 'adopted before this run')" "ran silent"
is  "an unread full run prints the line Capability drift was not checked: the capabilities this project declares could not be read." \
    "$(_durdline "$_durdout" "$_durddrift")" "said"
_durdhead="$(_durdat "$_durdout" 'commissioning for durdproj')"; _durdat2="$(_durdat "$_durdout" "$_durddrift")"
_durdfirst="$(_durdrow1 "$_durdout")"
if [ "$_durdat2" -eq 0 ]; then
  bad "and that line comes after the commissioning for durdproj line and before the first row line" \
      "the drift line is not printed, so it has no place: $(printf '%s\n' "$_durdout" | head -n 4)"
elif [ "$_durdhead" -eq 0 ] || [ "$_durdfirst" -eq 0 ]; then
  bad "and that line comes after the commissioning for durdproj line and before the first row line" \
      "head line at $_durdhead, first row line at $_durdfirst"
elif [ "$_durdhead" -lt "$_durdat2" ] && [ "$_durdat2" -lt "$_durdfirst" ]; then
  ok  "and that line comes after the commissioning for durdproj line and before the first row line"
else
  bad "and that line comes after the commissioning for durdproj line and before the first row line" \
      "head line $_durdhead, drift line $_durdat2, first row line $_durdfirst"
fi
is  "an unread full run still asks and prints both rows, marker done and durdheld held" \
    "$(printf '%s\n' "$_durdout" | grep -cE '^  done +marker( |$)')|$(printf '%s\n' "$_durdout" | grep -cE '^  held +durdheld( |$)')" "1|1"
is  "an unread full run still prints the summary line, 1 done, 1 held, 0 unknown" \
    "$(_durdsum "$_durdout" | cut -d, -f1-3)" "1 done, 1 held, 0 unknown"

# Read, --status: ci is there to adopt, and --status adopts nothing.
_durdset read
_durdout="$(_durdcli --status)"
is  "felix commission --status over a read list prints its report, no adopted line and no drift line" \
    "$(_durdran "$_durdout") $(_durdsays "$_durdout" 'adopted before this run') $(_durdsays "$_durdout" 'Capability drift was not checked')" \
    "ran silent silent"
is  "and adopts nothing: capabilities, stack.tsv and setup.tsv byte for byte" \
    "$(_durdsame "$_durdp/capabilities" "$TMP/durd-caps.keep") $(_durdsame "$_durdp/stack.tsv" "$TMP/durd-stack.keep") $(_durdsame "$_durdp/setup.tsv" "$TMP/durd-setup.keep")" \
    "same same same"
_durdset none
_durdout="$(_durdcli --status)"
is  "felix commission --status with no capabilities file prints its report, no adopted line and no drift line, and creates no capabilities file" \
    "$(_durdran "$_durdout") $(_durdsays "$_durdout" 'adopted before this run') $(_durdsays "$_durdout" 'Capability drift was not checked') $([ -e "$_durdp/capabilities" ] || [ -L "$_durdp/capabilities" ] && echo made || echo absent)" \
    "ran silent silent absent"

# Read, a full run, as before the change: ci is adopted and the run says so.
_durdset read
_durdout="$(_durdcli)"
is  "a full run over a list that declares secrets adopts ci: capabilities then declares ci and secrets" "$(_durdcaps)" "ci secrets "
is  "and prints the adopted before this run line, naming ci" \
    "$(printf '%s\n' "$_durdout" | awk -v p="$_durdadopted" 'index($0, p) == 1' | grep -c ' ci(')" "1"
is  "and the run over a list that declares secrets never prints Capability drift was not checked" "$(_durdran "$_durdout") $(_durdsays "$_durdout" 'Capability drift was not checked')" "ran silent"
_durdset none
_durdout="$(_durdcli)"
is  "a full run with no capabilities file adopts what the checkout shows and says so: capabilities declares ci, and the adopted line is printed" \
    "$(_durdsays " $(_durdcaps)" ' ci ') $(_durdbegins "$_durdout" "$_durdadopted")" "said said"
is  "and the run with no capabilities file never prints Capability drift was not checked" "$(_durdran "$_durdout") $(_durdsays "$_durdout" 'Capability drift was not checked')" "ran silent"
_durdset empty
_durdout="$(_durdcli)"
is  "a full run over an empty capabilities file adopts what the checkout shows and says so: capabilities declares ci, and the adopted line is printed" \
    "$(_durdsays " $(_durdcaps)" ' ci ') $(_durdbegins "$_durdout" "$_durdadopted")" "said said"
is  "and the run over an empty capabilities file never prints Capability drift was not checked" "$(_durdran "$_durdout") $(_durdsays "$_durdout" 'Capability drift was not checked')" "ran silent"


rm -rf "$_durdp" "$_durdr" "$_durdhome" "$_durdbin" "$MEM/durdproj" "$_durdgone" "$_durgit"
rm -f "$_durdasked" "$TMP/durd-stack.keep" "$TMP/durd-setup.keep" "$TMP/durd-caps.keep"
[ -d "$FROOT/state" ] && find "$FROOT/state" -name '*durdproj*' -exec rm -rf {} + 2>/dev/null
_durdnl='
'
find "$FROOT/state" -depth -type d 2>/dev/null | while IFS= read -r _durdd; do
  case "$_durdnl$_durddirs$_durdnl" in *"$_durdnl$_durdd$_durdnl"*) ;; *) rmdir "$_durdd" 2>/dev/null ;; esac
done
is  "and the block for felix commission over an unread declared list leaves the projects, the state and the memory as it found them" \
    "$(_durdfixture)" "$_durdfound"
unset -f _durdfixture _durdset _durdcli _durdline _durdsays _durdbegins _durdat _durdrow1 _durdsum _durdran _durdlink \
         _durdtarget _durdsame _durdcaps
unset _durdfound _durddirs _durdp _durdr _durdhome _durdbin _durdasked _durdgone _durdwhy _durddrift _durdadopted \
      _durddet _durdout _durdls _durdrun _durdn _durdhead _durdat2 _durdfirst _durdnl _durdd _durgit
