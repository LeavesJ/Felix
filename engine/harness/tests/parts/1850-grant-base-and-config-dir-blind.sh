printf '\nthe grant base and the config directory (audit b12: C009, C010, C098; blind)\n'
# Written blind on 2026-10-24 from docs/2026-10-24-audit-fixes/b12-judge-base-and-binding-read-what-is-
# comm.md (B1 to B13, assertions 1 to 44), before the fix. No engine code was read but the definition
# lines of lib/exceptions.sh, for the argument order the contract leaves out: felix_exception_for takes
# the project directory, the obligation, its class and the ledger line; felix_exceptions_judge, _count,
# _unmerged and _at_base take the project directory. Each assertion is named b12 A<n> after the
# contract's number. Where an item has a [red] half and a [control] half, the control half is an
# assertion of its own, "A<n> control", so a run on the base shows it holding.
#
# Readings, where the contract leaves room. A judge row's why is its fifth field. "Prints the table" is:
# prints what git show prints for the table at refs/remotes/origin/main. The status document is read
# with every run of blanks and newlines squeezed to one space, for all three of its checks. The registry
# entries carry an installPath, and HOME holds the cache directory ph's entry names, as a real install
# has them. deploy-check runs as part 0430 runs it, from a harness copied into R2. What B1 says of the
# doubt line (one printable line, exit 0, the URL never printed) is checked on red items only.
#
# Fixture G (B6): R, on main, pushed to the bare srv/acme/x.git and fetched, its grant at origin/main;
# F, whose origin's main holds no grant and whose local main adds one; N, with no remote and an
# update-ref'd origin/main that holds a grant; C, a fresh clone of R's origin. Fixture K (B12): the
# config directory X and HOME, each with its own skills, registry, .claude.json, marketplace entry,
# settings and plugin cache, a claude stub first on PATH, and R2, whose main declares 7.7.7. All of it
# is under one mktemp -d in $TMP. Every call sets HOME, FELIX_MEMORY and GIT_CONFIG_NOSYSTEM there and
# unsets CLAUDE_CONFIG_DIR, FELIX_KERNEL_CACHE and FELIX_PLUGIN_CACHE unless it names them.
G12="$(mktemp -d "$TMP/b12g.XXXXXX" 2>/dev/null)" && G12="$(cd "$G12" && pwd -P)" || G12=""
if [ -z "$G12" ] || [ ! -d "$G12" ]; then
  bad "b12 1850 fixture: mktemp -d made a directory under \$TMP" "got [$G12]"; G12="$TMP/b12g-fallback"; mkdir -p "$G12"
fi
G12H="$G12/home"; G12M="$G12/mem"; G12S="$G12/srv"; G12X="$G12/ccd"; G12R="$G12/r"; G12F="$G12/f"
G12N="$G12/n"; G12C="$G12/clone"; G12R2="$G12/r2"; G12T="$(printf '\t')"
mkdir -p "$G12H" "$G12M" "$G12S/acme" "$G12S/other" "$G12/srvf/acme" "$G12/wrap" "$G12/gitbad" "$G12/bin"
G12LIVE="$(( $(date -u +%Y) + 1 ))-06-01T00:00:00Z"
G12L="$(printf 'ob1\tTASK_BLOCKING\tdeterministic\t-\tfalse\t-\t%s' "the fixture's one blocking row")"
G12H16="$(printf '%s\n' "$G12L" | git hash-object --stdin | LC_ALL=C cut -c1-16)"
G12ROW="$(printf 'ob1\t%s\t%s\tthe-founder\tfixture grant' "$G12H16" "$G12LIVE")"
G12FOR="excepted|$G12LIVE|the-founder"

# ---- fixture G ---------------------------------------------------------------------------------
_g12g() { ( export HOME="$G12H" XDG_CONFIG_HOME="$G12H/.config" GIT_CONFIG_NOSYSTEM=1; _fx_git "$@" ) >/dev/null 2>&1; }
_g12q() { ( export HOME="$G12H" XDG_CONFIG_HOME="$G12H/.config" GIT_CONFIG_NOSYSTEM=1; _fx_git "$@" ) 2>/dev/null; }
_g12ci() { _g12g "$1" add -A && _g12g "$1" -c user.name=t -c user.email=t@t commit -qm "$2"; }
_g12proj() {  # DIR grant|nogrant: projects/x as B6 has it, with the grant row or with the header alone
  mkdir -p "$1/projects/x"
  printf '{ "name": "x", "remote_match": "acme/x", "gate": "true" }\n' > "$1/projects/x/project.json"
  printf '%s\n' "$G12L" > "$1/projects/x/obligations.tsv"
  printf '# obligation\trow_hash\texpires\tgranted_by\treason\n' > "$1/projects/x/exceptions.tsv"
  if [ "$2" = grant ]; then printf '%s\n' "$G12ROW" >> "$1/projects/x/exceptions.tsv"; fi
}
_g12repo() {  # DIR ORIGIN grant|nogrant: committed on main, its origin set as B6 sets it, main pushed, then fetched
  _g12proj "$1" "$3"; _g12g "$1" init -q -b main; _g12ci "$1" "fixture, $3"
  _g12g "$1" config remote.origin.url "$2"; _g12g "$1" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  _g12g "$1" push -q origin main; _g12g "$1" fetch -q origin
}
_g12g "$G12S/acme" init -q --bare -b main x.git; _g12g "$G12S/other" init -q --bare -b main x.git
_g12g "$G12/srvf/acme" init -q --bare -b main x.git
_g12repo "$G12R" "$G12S/acme/x.git" grant
_g12g "$G12R" push -q "$G12S/other/x.git" main
_g12repo "$G12F" "$G12/srvf/acme/x.git" nogrant
printf '%s\n' "$G12ROW" >> "$G12F/projects/x/exceptions.tsv"; _g12ci "$G12F" 'the grant, committed here and never pushed'
G12FL="$(git -C "$G12F" rev-parse HEAD 2>/dev/null)"
_g12proj "$G12N" grant; _g12g "$G12N" init -q -b main; _g12ci "$G12N" 'fixture N, no remote'
_g12g "$G12N" update-ref refs/remotes/origin/main HEAD
_g12g "$G12" clone -q -b main "$G12S/acme/x.git" clone
# A logging git and gh first on PATH (A21), and a git that exits 128 on any reflog subcommand (A20).
G12GIT="$(command -v git)"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s"\nexec "%s" "$@"\n' "$G12/wrap.log" "$G12GIT" > "$G12/wrap/git"
printf '#!/bin/sh\nprintf "gh %%s\\n" "$*" >> "%s"\nexit 1\n' "$G12/gh.log" > "$G12/wrap/gh"
printf '#!/bin/sh\nfor a in "$@"; do [ "$a" = reflog ] && exit 128; done\nexec "%s" "$@"\n' "$G12GIT" > "$G12/gitbad/git"
printf '#!/bin/sh\nexit 0\n' > "$G12/bin/claude"
chmod +x "$G12/wrap/git" "$G12/wrap/gh" "$G12/gitbad/git" "$G12/bin/claude"

_g12x() {  # FUNCTION ARGS... -> its stdout, in fixture G's environment with the exception libraries sourced
  ( export HOME="$G12H" XDG_CONFIG_HOME="$G12H/.config" FELIX_MEMORY="$G12M" GIT_CONFIG_NOSYSTEM=1
    unset CLAUDE_CONFIG_DIR FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"
    . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/exceptions.sh"
    "$@" ) </dev/null 2>/dev/null
}
_g12for() { local o r; o="$(_g12x felix_exception_for "$1/projects/x" ob1 TASK_BLOCKING "$G12L")"; r=$?; printf '%s|rc=%s' "$o" "$r"; }
_g12doubt() { _g12x felix_exceptions_doubt "$1/projects/x"; }
_g12col8() {  # REPO [release] -> column 8 of ob1's row in felix_obligations_run
  local o; o="$(_g12x felix_obligations_run "$1/projects/x" "$1" ${2:+"$2"})"
  printf '%s\n' "$o" | LC_ALL=C awk -F'\t' '$1 == "ob1" && !n++ { print $8 }'
}
_g12judged() {  # REPO WORD -> "refused, WORD" when the judge prints ob1 refused, LIVE, the-founder, its why beginning not honoured: and holding WORD
  local o; o="$(_g12x felix_exceptions_judge "$1/projects/x")"
  printf '%s\n' "$o" | LC_ALL=C awk -F'\t' -v w="$2" -v e="$G12LIVE" '
    $1 == "refused" && $2 == "ob1" && $3 == e && $4 == "the-founder" && index($5, "not honoured: ") == 1 && index($5, w) > 0 { f = 1 }
    { gsub(/\t/, " | "); a = a (a == "" ? "" : " // ") $0 }
    END { if (f) print "refused, " w; else print "judge printed [" a "]" }'
}
_g12dline() {  # REPO WORD... -> "one printable line holding WORD..." when felix_exceptions_doubt prints that and exits 0
  local d="$1" o r w m=""; shift
  o="$(_g12x felix_exceptions_doubt "$d/projects/x")"; r=$?
  for w in "$@"; do case "$o" in *"$w"*) ;; *) m="$m [$w]" ;; esac; done
  if [ "$r" = 0 ] && [ -n "$o" ] && [ -z "$m" ] && [ "$(printf '%s' "$o" | LC_ALL=C tr -d ' -~' | wc -c | tr -d ' ')" = 0 ]; then
    printf 'one printable line holding %s' "$*"
  else printf 'rc=%s, lacking%s: [%s]' "$r" "${m:- nothing}" "$o"; fi
}
_g12nourl() { case "$(_g12doubt "$1")" in *srv/other*|*srv/acme*) printf 'the doubt prints the URL' ;; *) printf 'the URL unsaid' ;; esac; }
_g12reset() {  # R's remote configuration back to the baseline
  _g12g "$G12R" config --replace-all remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  _g12g "$G12R" config remote.origin.url "$G12S/acme/x.git"
  _g12g "$G12R" config --remove-section remote.evil; _g12g "$G12R" config --remove-section remote.upstream
  _g12g "$G12R" config --unset-all "url.$G12S/other/.insteadof"
}
# A21 and A22: the three readers run under the logging git; the refs, the reflog and the config before and after.
_g12snap() { git -C "$1" for-each-ref 2>&1; _g12q "$1" reflog show refs/remotes/origin/main; git -C "$1" config --list --local 2>&1; }
_g12three() { felix_exception_for "$1/projects/x" ob1 TASK_BLOCKING "$G12L"; felix_exceptions_judge "$1/projects/x"; felix_exceptions_doubt "$1/projects/x"; }
_g12net() { LC_ALL=C awk '{ for (i = 1; i <= NF; i++) if ($i == "fetch" || $i == "pull" || $i == "ls-remote" || ($i == "remote" && $(i + 1) == "update")) { print; break } }' "$1" 2>/dev/null; }
_g12w=""; _g12s=""
_g12watch() {
  local a b
  : > "$G12/wrap.log"; : > "$G12/gh.log"; a="$(_g12snap "$1")"
  PATH="$G12/wrap:$PATH" _g12x _g12three "$1" >/dev/null
  b="$(_g12snap "$1")"
  if [ -s "$G12/wrap.log" ]; then _g12w="$_g12w logged"; else _g12w="$_g12w no-git-call-logged"; fi
  _g12w="$_g12w net=[$(_g12net "$G12/wrap.log")] gh=[$(cat "$G12/gh.log" 2>/dev/null)]"
  if [ -n "$a" ] && [ "$a" = "$b" ]; then _g12s="$_g12s same"; else _g12s="$_g12s changed"; fi
}

# ---- C009: the baseline, then each doubted change alone ----------------------------------------
is "b12 A1 (B6, B7): on the baseline, felix_exception_for prints excepted|LIVE|the-founder and exits 0 (control)" "$(_g12for "$G12R")" "$G12FOR|rc=0"
is "b12 A2 (B1): on the baseline, felix_exceptions_doubt prints nothing (control)" "$(_g12doubt "$G12R")" ""
is "b12 A3 (B4): on the baseline, felix_obligations_run prints column 8 excepted|LIVE|the-founder (control)" "$(_g12col8 "$G12R")" "$G12FOR"
_g12rel0="$(_g12col8 "$G12R" release)"; _g12watch "$G12R"
_g12g "$G12R" config --replace-all remote.origin.fetch '+refs/heads/forged:refs/remotes/origin/main'
is "b12 A4 (B2): with origin's refspec replaced by refs/heads/forged, felix_exception_for prints nothing and exits 1" "$(_g12for "$G12R")" "|rc=1"
is "b12 A5 (B3): and felix_exceptions_judge prints refused, ob1, LIVE, the-founder, not honoured:, its why naming fetch" "$(_g12judged "$G12R" fetch)" "refused, fetch"
is "b12 A6 (B4): and felix_obligations_run prints column 8 as -" "$(_g12col8 "$G12R")" "-"
_g12watch "$G12R"
is "b12 A21 (B1): the three readers call no fetch, pull, ls-remote or remote update, and no gh, on the baseline and on the forged refspec (control)" \
   "$_g12w" " logged net=[] gh=[] logged net=[] gh=[]"
is "b12 A22 (B1): for-each-ref, the origin/main reflog and the local config read the same before and after them, both times (control)" "$_g12s" " same same"
_g12a="$(_g12x felix_exceptions_at_base "$G12R/projects/x")"; _g12b="$(git -C "$G12R" show refs/remotes/origin/main:projects/x/exceptions.tsv 2>/dev/null)"
if [ -n "$_g12b" ] && [ "$_g12a" = "$_g12b" ]; then _g12v="the table"; else _g12v="[$_g12a]"; fi
is "b12 A23 (B5): on the forged refspec, _at_base still prints the table, _count prints 1 and _unmerged prints nothing (control)" \
   "$_g12v|$(_g12x felix_exceptions_count "$G12R/projects/x")|[$(_g12x felix_exceptions_unmerged "$G12R/projects/x")]" "the table|1|[]"
is "b12 A24 (B4): release mode prints column 8 as - on the baseline and on the forged refspec (control)" "$_g12rel0 $(_g12col8 "$G12R" release)" "- -"
_g12reset
_g12g "$G12R" config --add remote.origin.fetch '+refs/heads/x/*:refs/remotes/origin/*'
is "b12 A7 (B2, B6): an added refs/heads/x/* glob onto refs/remotes/origin/* doubts the ref: exit 1, and the judge's why names fetch" \
   "$(_g12for "$G12R") $(_g12judged "$G12R" fetch)" "|rc=1 refused, fetch"
_g12reset; _g12g "$G12R" config remote.evil.fetch '+refs/heads/*:refs/remotes/origin/*'
is "b12 A8 (B1, B2, B6): a remote evil writing refs/remotes/origin/* doubts it, and the one doubt line names remote.evil.fetch" \
   "$(_g12for "$G12R") $(_g12judged "$G12R" fetch) / $(_g12dline "$G12R" fetch remote.evil.fetch)" "|rc=1 refused, fetch / one printable line holding fetch remote.evil.fetch"
_g12reset; _g12g "$G12R" config --unset-all remote.origin.fetch
is "b12 A9 (B2, B6): an origin with no fetch refspec doubts it, the doubt line naming remote.origin.fetch" \
   "$(_g12for "$G12R") $(_g12judged "$G12R" fetch) / $(_g12dline "$G12R" fetch remote.origin.fetch)" "|rc=1 refused, fetch / one printable line holding fetch remote.origin.fetch"
_g12reset
# A10: the four benign refspec sets.
_g12got=""; _g12want=""
_g12ben() { _g12got="$_g12got [$1: $(_g12for "$G12R") doubt=[$(_g12doubt "$G12R")]]"; _g12want="$_g12want [$1: $G12FOR|rc=0 doubt=[]]"; _g12reset; }
_g12ben 'the default'
_g12g "$G12R" config --replace-all remote.origin.fetch '+refs/heads/main:refs/remotes/origin/main'; _g12ben 'main alone'
_g12g "$G12R" config --add remote.origin.fetch '+refs/pull/*/head:refs/remotes/origin/pr/*'; _g12ben 'the default and pull heads'
_g12g "$G12R" config remote.upstream.url "$G12S/other/x.git"
_g12g "$G12R" config remote.upstream.fetch '+refs/heads/*:refs/remotes/upstream/*'; _g12ben 'the default and an upstream remote'
is "b12 A10 (B7): each of the four benign refspec sets clears the grant and doubts nothing (control)" "$_g12got" "$_g12want"
_g12g "$G12R" config remote.origin.url "$G12S/other/x.git"
is "b12 A15 (B1, B2, B6): origin's URL pointed at srv/other doubts the ref with remote_match, and the URL is not printed" \
   "$(_g12for "$G12R") $(_g12judged "$G12R" remote_match) / $(_g12nourl "$G12R")" "|rc=1 refused, remote_match / the URL unsaid"
_g12reset; _g12g "$G12R" config "url.$G12S/other/.insteadOf" "$G12S/acme/"
is "b12 A16 (B1, B2, B6): an insteadOf rewrite of srv/acme to srv/other doubts the ref with remote_match, the URL unprinted" \
   "$(_g12for "$G12R") $(_g12judged "$G12R" remote_match) / $(_g12nourl "$G12R")" "|rc=1 refused, remote_match / the URL unsaid"
_g12reset; cp "$G12R/projects/x/project.json" "$G12/project.json.keep"
printf '{ "name": "x", "remote_match": "", "gate": "true" }\n' > "$G12R/projects/x/project.json"
_g12g "$G12R" config remote.origin.url "$G12S/other/x.git"
is "b12 A17 (B7): with remote_match emptied in the working tree and the URL elsewhere, the grant clears and nothing is doubted (control)" \
   "$(_g12for "$G12R") [$(_g12doubt "$G12R")]" "$G12FOR|rc=0 []"
cp "$G12/project.json.keep" "$G12R/projects/x/project.json"; _g12reset
is "b12 A20 (B1): with git exiting 128 on reflog, felix_exception_for exits 1 and the doubt line says reflog cannot be read" \
   "$(PATH="$G12/gitbad:$PATH" _g12for "$G12R") / $(PATH="$G12/gitbad:$PATH" _g12dline "$G12R" reflog 'cannot be read')" \
   "|rc=1 / one printable line holding reflog cannot be read"
is "b12 A14 (B7): in a fresh clone of the origin, whose main holds the grant, the grant clears and nothing is doubted (control)" \
   "$(_g12for "$G12C") [$(_g12doubt "$G12C")]" "$G12FOR|rc=0 []"
# F: the reflog cases and the symbolic ref.
is "b12 A11 fixture: F's fetched origin/main holds no grant, so it clears nothing, and F's local main holds one (control)" \
   "$(_g12for "$G12F") $(git -C "$G12F" show main:projects/x/exceptions.tsv 2>/dev/null | LC_ALL=C awk -v r="$G12ROW" '$0 == r { n++ } END { print n + 0 }')" "|rc=1 1"
_g12gcd="$(git -C "$G12F" rev-parse --git-common-dir 2>/dev/null)"
case "$_g12gcd" in /*) ;; *) _g12gcd="$G12F/$_g12gcd" ;; esac
if [ -n "$G12FL" ] && [ -f "$_g12gcd/refs/remotes/origin/main" ]; then printf '%s\n' "$G12FL" > "$_g12gcd/refs/remotes/origin/main"; fi
is "b12 A11 (B2, B6): with the ref file overwritten by a shell redirect with the local grant commit, felix_exception_for exits 1 and the why names reflog" \
   "$(_g12for "$G12F") $(_g12judged "$G12F" reflog)" "|rc=1 refused, reflog"
_g12g "$G12F" fetch -q
is "b12 A12 (B7): after one plain git fetch nothing is doubted, and the origin's main, holding no grant, clears nothing (control)" \
   "[$(_g12doubt "$G12F")] $(_g12for "$G12F")" "[] |rc=1"
printf 'update refs/remotes/origin/main %s\n' "$G12FL" | _g12g "$G12F" update-ref --stdin
is "b12 A13 (B2, B6): the same commit written by update-ref --stdin doubts the ref, the why naming reflog" \
   "$(_g12for "$G12F") $(_g12judged "$G12F" reflog)" "|rc=1 refused, reflog"
_g12g "$G12F" fetch -q; _g12g "$G12F" symbolic-ref refs/remotes/origin/main refs/heads/main
is "b12 A18 (B2, B6): refs/remotes/origin/main made a symbolic ref to a local main that carries the grant doubts it, the why naming symbolic" \
   "$(_g12for "$G12F") $(_g12judged "$G12F" symbolic)" "|rc=1 refused, symbolic"
is "b12 A19 (B2, B6): with no remote and an update-ref'd origin/main holding a grant, felix_exception_for exits 1 and the why begins not honoured:" \
   "$(_g12for "$G12N") $(_g12judged "$G12N" 'not honoured:')" "|rc=1 refused, not honoured:"

# ---- B8 and B9: what the header and the status document say ------------------------------------
G12EX="$FROOT/harness/lib/exceptions.sh"
_g12c1="$(LC_ALL=C grep -c -F 'moves only when' "$G12EX" 2>/dev/null)"; _g12c2="$(LC_ALL=C grep -c -F 'reflog' "$G12EX" 2>/dev/null)"
if [ "${_g12c2:-0}" -gt 0 ] 2>/dev/null; then _g12v=names; else _g12v=lacks; fi
is "b12 A25 (B8): lib/exceptions.sh no longer says the ref moves only when something is fetched, and it names the reflog" "${_g12c1:-unreadable} $_g12v" "0 names"
G12DOC="$(cd "$REAL_HARNESS/../.." 2>/dev/null && pwd)/docs/2026-09-21-where-felix-stands.md"
_g12n26="b12 A26 (B9): the where-stands document no longer says exception grants and obligation admission, which are read from"
_g12n27="b12 A27 (B9): it says obligation admission and every table the gate reads are read from the home's working tree"
_g12n28="b12 A28 (B9): it no longer says True only where main is server-protected"
if [ -f "$G12DOC" ]; then
  G12DS="$(LC_ALL=C tr '\t\n' '  ' < "$G12DOC" | LC_ALL=C tr -s ' ')"
  _g12in() { case "$G12DS" in *"$1"*) printf 'holds it' ;; *) printf 'does not hold it' ;; esac; }
  is "$_g12n26" "$(_g12in 'exception grants and obligation admission, which are read from')" "does not hold it"
  is "$_g12n27" "$(_g12in "obligation admission and every table the gate reads, which are read from the home's working tree")" "holds it"
  is "$_g12n28" "$(_g12in 'True only where main is server-protected')" "does not hold it"
else
  for _g12i in "$_g12n26" "$_g12n27" "$_g12n28"; do skip "$_g12i" "no docs/2026-09-21-where-felix-stands.md beside this harness"; done
fi

# ---- fixture K ---------------------------------------------------------------------------------
mkdir -p "$G12X/skills/sx" "$G12X/plugins/cache/m/px/1.0.0/hooks" "$G12H/.claude/skills/sh" \
         "$G12H/.claude/plugins/cache/m/ph/9.9.9" "$G12/pr" "$G12/ps" "$G12R2/engine/.claude-plugin" "$G12R2/engine/harness"
printf '# sx\n' > "$G12X/skills/sx/SKILL.md"; printf '# sh\n' > "$G12H/.claude/skills/sh/SKILL.md"
printf '{"version": 2, "plugins": {\n  "px@m": [{"scope": "user", "installPath": "%s", "version": "1.2.3", "gitCommitSha": "abc123"}]\n}}\n' \
  "$G12X/plugins/cache/m/px/1.0.0" > "$G12X/plugins/installed_plugins.json"
printf '{"version": 2, "plugins": {\n  "ph@m": [{"scope": "user", "installPath": "%s", "version": "9.9.9"}]\n}}\n' \
  "$G12H/.claude/plugins/cache/m/ph/9.9.9" > "$G12H/.claude/plugins/installed_plugins.json"
printf '{ "pluginUsage": { "bx@inline": {} } }\n' > "$G12X/.claude.json"
printf '{ "pluginUsage": { "bh@inline": {} } }\n' > "$G12H/.claude.json"
printf '{\n  "felix": {\n    "installLocation": "/from/ccd"\n  }\n}\n' > "$G12X/plugins/known_marketplaces.json"
printf '{\n  "felix": {\n    "installLocation": "/from/home"\n  }\n}\n' > "$G12H/.claude/plugins/known_marketplaces.json"
_g12hooks() { printf '{ "hooks": { "%s": [ { "hooks": [ { "type": "command", "command": "true" } ] } ] } }\n' "$1"; }
_g12hooks Stop > "$G12X/settings.json"; _g12hooks PreCompact > "$G12X/plugins/cache/m/px/1.0.0/hooks/hooks.json"
_g12hooks SessionEnd > "$G12H/.claude/settings.json"
printf 'b12\tsx words\tcore\tsx\n' > "$G12/pr/routes.tsv"; printf 'skill\tsx\t-\tlow\talways\n' > "$G12/pr/stack.tsv"
printf 'skill\tsx\t-\tlow\talways\nplugin\tbx\t-\tlow\talways\n' > "$G12/ps/stack.tsv"
printf '{ "name": "felix", "version": "7.7.7" }\n' > "$G12R2/engine/.claude-plugin/plugin.json"
_g12g "$G12R2" init -q -b main; _g12g "$G12R2" add engine/.claude-plugin/plugin.json
_g12g "$G12R2" -c user.name=t -c user.email=t@t commit -qm 'fixture R2: main declares 7.7.7'
cp -R "$FROOT/harness/felix" "$FROOT/harness/bin" "$FROOT/harness/lib" "$FROOT/harness/hooks" "$G12R2/engine/harness/" 2>/dev/null
_g12k() {  # X|unset|empty "LIBS" FUNCTION ARGS... -> its stdout, in fixture K's environment, resolve.sh then LIBS sourced
  local how="$1" libs="$2"; shift 2
  ( export HOME="$G12H" XDG_CONFIG_HOME="$G12H/.config" FELIX_MEMORY="$G12M" GIT_CONFIG_NOSYSTEM=1 PATH="$G12/bin:$PATH"
    unset CLAUDE_CONFIG_DIR FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE
    if [ "$how" = X ]; then export CLAUDE_CONFIG_DIR="$G12X"; elif [ "$how" = empty ]; then export CLAUDE_CONFIG_DIR=""; fi
    . "$FROOT/harness/lib/resolve.sh"
    for _g12l in $libs; do . "$FROOT/harness/lib/$_g12l.sh"; done
    "$@" ) </dev/null 2>/dev/null
}
G12CP="detect admit commission commission-provider"
_g12st() { "$@" >/dev/null 2>&1; printf 'rc=%s' "$?"; }
_g12cd() { felix_claude_dir; printf '.'; }
_g12tb() { printf '%s|%s' "${FELIX_PLUGIN_CACHE-unset}" "$(felix_toolbox_path px)"; }
_g12tbq() { FELIX_PLUGIN_CACHE="$G12/q"; . "$FROOT/harness/lib/toolbox.sh"; printf '%s' "${FELIX_PLUGIN_CACHE-unset}"; }
_g12sp() { cd "$G12R2" && felix_stack_plan "$G12/ps"; }
_g12dd() { felix_accepted_deploy_diff "$G12R2" main 2>&1; printf '|rc=%s' "$?"; }
_g12dc() { ( cd "$G12R2" && engine/harness/bin/deploy-check --applies ) >/dev/null 2>&1; printf '%s' "$?"; }
_g12pc() { FELIX_PLUGIN_CACHE="$G12/p" felix_kernel_dir "$G12R2" main; }
_g12kc() { FELIX_KERNEL_CACHE="$G12/k" felix_kernel_dir "$G12R2" main; }
_g12lines() {  # TEXT WANT... -> WANT=yes|no for each, yes when TEXT holds it as a whole line, its tabs read as /
  local t="$1"; shift
  printf '%s\n' "$t" | LC_ALL=C awk -v want="$*" '{ gsub(/\t/, "/"); L[$0] = 1 }
    END { n = split(want, w, " "); for (i = 1; i <= n; i++) printf "%s%s=%s", (i > 1 ? " " : ""), w[i], ((w[i] in L) ? "yes" : "no") }'
}
_g12line() { printf '%s\n' "$1" | LC_ALL=C awk -v l="$2" '$0 == l { f = 1 } { a = a "[" $0 "]" } END { print (f ? "yes" : "no, in " a) }'; }

# ---- C098: one config directory for every reader -----------------------------------------------
is "b12 A29 (B10): felix_claude_dir prints X under CLAUDE_CONFIG_DIR=X, and HOME/.claude unset or empty, with no newline" \
   "$(_g12k X "" _g12cd)|$(_g12k unset "" _g12cd)|$(_g12k empty "" _g12cd)" "$G12X.|$G12H/.claude.|$G12H/.claude."
is "b12 A30 (B12): under X the registry field of px is 1.2.3, ph has none, and px's provenance is px@1.2.3/abc123" \
   "$(_g12k X "" felix_registry_field px version)|$(_g12k X "" felix_registry_field ph version)|$(_g12k X "$G12CP" felix_commission_provider_provenance px)" \
   "1.2.3||px@1.2.3/abc123"
is "b12 A31 (B12): unset, the registry field of ph is 9.9.9 (control)" "$(_g12k unset "" felix_registry_field ph version)" "9.9.9"
is "b12 A32 (B12): under X, _felix_commission_installed px exits 0 and ph exits 1" \
   "$(_g12k X "$G12CP" _g12st _felix_commission_installed px) $(_g12k X "$G12CP" _g12st _felix_commission_installed ph)" "rc=0 rc=1"
is "b12 A32 control (B12): unset, _felix_commission_installed ph exits 0" "$(_g12k unset "$G12CP" _g12st _felix_commission_installed ph)" "rc=0"
is "b12 A36 (B12): under X, felix_marketplace_root prints /from/ccd" "$(_g12k X "" felix_marketplace_root)" "/from/ccd"
is "b12 A36 control (B12): unset, it prints /from/home" "$(_g12k unset "" felix_marketplace_root)" "/from/home"
is "b12 A37 (B11, B12): under X, toolbox.sh's FELIX_PLUGIN_CACHE is X/plugins/cache and felix_toolbox_path px is X's copy" \
   "$(_g12k X toolbox _g12tb)" "$G12X/plugins/cache|$G12X/plugins/cache/m/px/1.0.0"
is "b12 A37 control (B11): a FELIX_PLUGIN_CACHE set before toolbox.sh is sourced is kept, X or no X" "$(_g12k X "" _g12tbq)" "$G12/q"
_g12w39="skill/sx plugin/px plugin/bx skill/sh plugin/ph plugin/bh plugin/ph@m plugin/bh@inline"
is "b12 A39 (B12): under X, felix_ready_inventory lists sx, px and bx and none of sh, ph and bh" \
   "$(_g12lines "$(_g12k X ready felix_ready_inventory)" $_g12w39)" \
   "skill/sx=yes plugin/px=yes plugin/bx=yes skill/sh=no plugin/ph=no plugin/bh=no plugin/ph@m=no plugin/bh@inline=no"
is "b12 A39 control (B12): unset, it lists sh, ph and bh" "$(_g12lines "$(_g12k unset ready felix_ready_inventory)" skill/sh plugin/ph plugin/bh)" \
   "skill/sh=yes plugin/ph=yes plugin/bh=yes"
is "b12 A40 (B12): under X, felix_ready_report prints usable, sx, skill, always available" \
   "$(_g12line "$(_g12k X ready felix_ready_report "$G12/pr")" "usable${G12T}sx${G12T}skill, always available")" "yes"
is "b12 A40 control (B12): unset, it prints absent, sx, skill directory not present" \
   "$(_g12line "$(_g12k unset ready felix_ready_report "$G12/pr")" "absent${G12T}sx${G12T}skill directory not present")" "yes"
is "b12 A41 (B12): under X, felix_stack_plan prints present for skill sx and for plugin bx" \
   "$(_g12lines "$(_g12k X "detect stack" _g12sp)" present/skill/sx/- present/plugin/bx/-)" "present/skill/sx/-=yes present/plugin/bx/-=yes"
is "b12 A41 control (B12): unset, it prints neither present line" \
   "$(_g12lines "$(_g12k unset "detect stack" _g12sp)" present/skill/sx/- present/plugin/bx/-)" "present/skill/sx/-=no present/plugin/bx/-=no"
is "b12 A42 (B11, B12): under X, felix_coverage_events lists Stop and PreCompact and not SessionEnd" \
   "$(_g12lines "$(_g12k X coverage felix_coverage_events)" Stop PreCompact SessionEnd)" "Stop=yes PreCompact=yes SessionEnd=no"
is "b12 A42 control (B12): unset, it lists SessionEnd" "$(_g12lines "$(_g12k unset coverage felix_coverage_events)" SessionEnd)" "SessionEnd=yes"
# R2, with no felix cache anywhere yet, then with X's, then with HOME's.
_g12o="$(_g12k X "" _g12dd)"
case "$_g12o" in *"cannot examine: no felix cache at $G12X/plugins/cache/felix/felix"*) _g12v=named ;; *) _g12v="[$_g12o]" ;; esac
is "b12 A35 (B12): with no cache under X, felix_accepted_deploy_diff exits 2 and names X/plugins/cache/felix/felix" "${_g12o##*|rc=} $_g12v" "2 named"
_g12dc0="$(_g12k X "" _g12dc) $(_g12k unset "" _g12dc)"
mkdir -p "$G12X/plugins/cache/felix/felix/7.7.7/harness/lib" "$G12/p/felix/felix/7.7.7/harness/lib" "$G12/k/7.7.7/harness/lib"
is "b12 A33 (B12): under X, felix_kernel_dir R2 main prints X/plugins/cache/felix/felix/7.7.7/harness" \
   "$(_g12k X "" felix_kernel_dir "$G12R2" main)" "$G12X/plugins/cache/felix/felix/7.7.7/harness"
is "b12 A34 (B11, B12): FELIX_PLUGIN_CACHE=P gives P's path with X set, and FELIX_KERNEL_CACHE=K gives K's (control)" \
   "$(_g12k X "" _g12pc)|$(_g12k X "" _g12kc)" "$G12/p/felix/felix/7.7.7/harness|$G12/k/7.7.7/harness"
is "b12 A38 (B12): under X, with X/plugins/cache/felix/felix present, deploy-check --applies run in R2 exits 0" "$(_g12k X "" _g12dc)" "0"
mkdir -p "$G12H/.claude/plugins/cache/felix/felix/7.7.7/harness/lib"
is "b12 A38 control (B12): it exits 1 with the cache in neither place, under X and unset, and 0 with HOME's cache and the variable unset" \
   "$_g12dc0 $(_g12k unset "" _g12dc)" "1 1 0"

# ---- B13: the lint -----------------------------------------------------------------------------
_g12lint() {  # FILE... -> FILE:LINE for each line B13 counts
  LC_ALL=C awk '{ s = $0; sub(/^[ \t]+/, "", s) }
    substr(s, 1, 1) != "#" && (index($0, "$HOME/.claude") || index($0, "\"$HOME\"/.claude") || index($0, "${HOME}/.claude")) && !index($0, "CLAUDE_CONFIG_DIR") { print FILENAME ":" FNR }' "$@"
}
_g12lf=(); for _g12i in "$REAL_HARNESS/felix" "$REAL_HARNESS"/lib/* "$REAL_HARNESS"/bin/* "$REAL_HARNESS"/hooks/*; do
  if [ -f "$_g12i" ]; then _g12lf+=("$_g12i"); fi; done
if [ "${#_g12lf[@]}" -gt 0 ]; then
  _g12o="$(_g12lint "${_g12lf[@]}" 2>&1)"
  _g12o="$(printf '%s\n' "$_g12o" | LC_ALL=C awk -v h="$REAL_HARNESS/" '$0 == "" { next } { r = $0; if (index(r, h) == 1) r = substr(r, length(h) + 1); f = r; sub(/:[0123456789]+$/, "", f) }
    f == "felix" || f == "lib/green-tick.sh" || f == "lib/green-install.sh" || f == "lib/discover.sh" || f == "lib/cost.sh" || f == "lib/audit.sh" { next }
    { printf "%s ", r }')"
else _g12o="no file found under $REAL_HARNESS"; fi
is "b12 A43 (B13): no line outside the six named files reads \$HOME/.claude without CLAUDE_CONFIG_DIR" "$_g12o" ""
printf 'x="$HOME/.claude/y"\n# $HOME/.claude\n  # "$HOME"/.claude\ny="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"\n' > "$G12/lint-sample.sh"
is "b12 A44 (B13): the lint's scanner counts x=\"\$HOME/.claude/y\" and skips the comments and \${CLAUDE_CONFIG_DIR:-\$HOME/.claude} (control)" \
   "$(_g12lint "$G12/lint-sample.sh" 2>&1)" "$G12/lint-sample.sh:1"

# ---- Review round, M2 (B35-B38): every route a fetch can take is doubted or named --------------
# Written blind on 2026-10-26 from the contract's section 9, with no engine code read. Fixture P is
# like F: its origin's main holds no grant. A branch forged adds the grant and is pushed, and two more
# bare repositories, srvp/other/x.git and srvp/look/acme/x.git, hold forged's commit as main. After each
# route, the URL and the default refspec are put back and a plain fetch restores origin/main. Section 2's
# row is the document's table line for "An agent cannot grant itself authority". The row and the
# comments of lib/exceptions.sh are read with runs of blanks squeezed.
G12P="$G12/p12"; G12PS="$G12/srvp"; mkdir -p "$G12PS/acme" "$G12PS/other" "$G12PS/look/acme"
for _g12i in "$G12PS/acme" "$G12PS/other" "$G12PS/look/acme"; do _g12g "$_g12i" init -q --bare -b main x.git; done
_g12repo "$G12P" "$G12PS/acme/x.git" nogrant
_g12g "$G12P" checkout -q -b forged; printf '%s\n' "$G12ROW" >> "$G12P/projects/x/exceptions.tsv"
_g12ci "$G12P" 'the grant, on a branch forged'; _g12g "$G12P" push -q origin forged; _g12g "$G12P" checkout -q main
G12PF="$(git -C "$G12P" rev-parse -q --verify refs/heads/forged 2>/dev/null)"
_g12g "$G12P" push -q "$G12PS/other/x.git" forged:main; _g12g "$G12P" push -q "$G12PS/look/acme/x.git" forged:main
_g12row2=""
if [ -f "$G12DOC" ]; then
  _g12row2="$(LC_ALL=C grep -F '| An agent cannot grant itself authority |' "$G12DOC" 2>/dev/null | LC_ALL=C tr '\t' ' ' | LC_ALL=C tr -s ' ')"
fi
_g12names() {  # ROUTE -> yes when section 2's row names it as B35 says
  case "$1" in
    r1) case "$_g12row2" in *'fetch refspec'*'put back'*|*'put back'*'fetch refspec'*) printf yes; return ;; esac ;;
    r2) case "$_g12row2" in *'--refmap'*) printf yes; return ;; esac ;;
    r3) case "$_g12row2" in *'origin URL changed for it and put back'*) printf yes; return ;; esac ;;
    r4) case "$_g12row2" in *'whose path ends in the declared remote_match'*) printf yes; return ;; esac ;;
  esac
  printf no
}
_g12took=""; _g12held=""; _g12w84=""; _g12w85=""
_g12route() {  # ROUTE: whether it took, whether the reader doubted it or the row names it; then the baseline back
  local g m o v
  g="$(git -C "$G12P" rev-parse -q --verify refs/remotes/origin/main 2>/dev/null)"
  m="$(_g12q "$G12P" reflog show -n1 --format=%gs refs/remotes/origin/main)"
  if [ -n "$G12PF" ] && [ "$g" = "$G12PF" ]; then
    case "$m" in fetch*) v=took ;; *) v="took, but its newest reflog entry reads [$m]" ;; esac
  else v="did not take: origin/main is [$g], forged is [$G12PF]"; fi
  _g12took="$_g12took [$1: $v]"; _g12w84="$_g12w84 [$1: took]"
  o="$(_g12for "$G12P")"
  if [ "$o" = "|rc=1" ] || [ "$(_g12names "$1")" = yes ]; then v=held
  else v="felix_exception_for gave [$o] and section 2's row does not name the route"; fi
  _g12held="$_g12held [$1: $v]"; _g12w85="$_g12w85 [$1: held]"
  _g12g "$G12P" config remote.origin.url "$G12PS/acme/x.git"
  _g12g "$G12P" config --replace-all remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'; _g12g "$G12P" fetch -q
}
_g12g "$G12P" config --replace-all remote.origin.fetch '+refs/heads/forged:refs/remotes/origin/main'; _g12g "$G12P" fetch -q
_g12g "$G12P" config --replace-all remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'; _g12route r1
_g12g "$G12P" fetch -q origin forged '--refmap=+refs/heads/forged:refs/remotes/origin/main'; _g12route r2
_g12g "$G12P" config remote.origin.url "$G12PS/other/x.git"; _g12g "$G12P" fetch -q
_g12g "$G12P" config remote.origin.url "$G12PS/acme/x.git"; _g12route r3
_g12g "$G12P" config remote.origin.url "$G12PS/look/acme/x.git"; _g12g "$G12P" fetch -q; _g12route r4
is "b12 A84 (B35): each route takes: origin/main is forged's commit and its newest reflog entry begins fetch (control)" "$_g12took" "$_g12w84"
_g12n85="b12 A85 (B35): each route is doubted by felix_exception_for or named in the status document's section 2 row"
# Not blind: the public snapshot withholds docs/. Without the document a route
# felix_exception_for does not doubt cannot be judged, so then this is skipped,
# as A26 to A28 and A87 to A88 are; when every route is doubted it is still asked.
if [ -f "$G12DOC" ] || [ "$_g12held" = "$_g12w85" ]; then
  is "$_g12n85" "$_g12held" "$_g12w85"
else
  skip "$_g12n85" "no docs/2026-09-21-where-felix-stands.md beside this harness, and felix_exception_for does not doubt every route"
fi
_g12cm="$(LC_ALL=C awk '{ s = $0; sub(/^[ \t]+/, "", s) } substr(s, 1, 1) == "#" { sub(/^#+/, "", s); printf "%s ", s }' "$G12EX" 2>/dev/null \
          | LC_ALL=C tr '\t' ' ' | LC_ALL=C tr -s ' ')"
_g12v=""
for _g12i in 'honest reflog' 'put back' '--refmap' 'path ends in'; do case "$_g12cm" in *"$_g12i"*) ;; *) _g12v="$_g12v [lacks $_g12i]" ;; esac; done
case "$_g12cm" in *'simple forger'*) _g12v="$_g12v [holds simple forger]" ;; esac
[ -n "$_g12cm" ] || _g12v=" [no comment line read from lib/exceptions.sh]"
is "b12 A86 (B38): the comments of lib/exceptions.sh name an honest reflog, put back, --refmap and a path that ends in the remote, and no simple forgery" "[${_g12v# }]" "[]"
_g12n87="b12 A87 (B36): section 2's row says a worker set on forging one gets past with an honest reflog, as with a forged reflog, and drops the simple forgeries"
_g12n88="b12 A88 (B37): section 4's bullet says a fetch that writes another branch or copy into the ref gets past, and drops the reflog-only limit"
if [ -f "$G12DOC" ]; then
  _g12v=""
  for _g12i in 'set on forging one' 'leaves an honest reflog and gets past' 'So does a forged reflog'; do
    case "$_g12row2" in *"$_g12i"*) ;; *) _g12v="$_g12v [lacks $_g12i]" ;; esac; done
  for _g12i in 'the simple forgeries' 'not a worker that also rewrites the reflog'; do
    case "$_g12row2" in *"$_g12i"*) _g12v="$_g12v [holds $_g12i]" ;; esac; done
  [ -n "$_g12row2" ] || _g12v=" [no row for An agent cannot grant itself authority]"
  is "$_g12n87" "[${_g12v# }]" "[]"
  G12DS2="$(LC_ALL=C tr '\t\n' '  ' < "$G12DOC" | LC_ALL=C tr -s ' ')"
  _g12v=""
  case "$G12DS2" in *'a fetch made to write another branch or another copy into it leaves an honest reflog and gets past, and so does a forged reflog (corrected 2026-10-24, audit C009)'*) ;;
    *) _g12v="$_g12v [lacks the B37 text]" ;; esac
  case "$G12DS2" in *'which a worker that also rewrites the reflog gets past'*) _g12v="$_g12v [holds the reflog-only limit]" ;; esac
  is "$_g12n88" "[${_g12v# }]" "[]"
else
  for _g12i in "$_g12n87" "$_g12n88"; do skip "$_g12i" "no docs/2026-09-21-where-felix-stands.md beside this harness"; done
fi

# ---- Review round, M4 (B41): a product's grant is read against the home's own remote -----------
# Fixture Q: a home H holding .felix (felix), projects/felix (acme/felix) and projects/p (acme/p), each
# with B6's obligation line and grant row, committed, its origin srvq/acme/felix.git, main pushed and
# fetched, and main pushed to srvq/other/felix.git as well.
G12HQ="$G12/hq"; G12QS="$G12/srvq"; mkdir -p "$G12QS/acme" "$G12QS/other" "$G12HQ/projects/felix" "$G12HQ/projects/p"
_g12g "$G12QS/acme" init -q --bare -b main felix.git; _g12g "$G12QS/other" init -q --bare -b main felix.git
for _g12i in felix:acme/felix p:acme/p; do
  printf '{ "name": "%s", "remote_match": "%s", "gate": "true" }\n' "${_g12i%%:*}" "${_g12i#*:}" > "$G12HQ/projects/${_g12i%%:*}/project.json"
  printf '%s\n' "$G12L" > "$G12HQ/projects/${_g12i%%:*}/obligations.tsv"
  printf '# obligation\trow_hash\texpires\tgranted_by\treason\n%s\n' "$G12ROW" > "$G12HQ/projects/${_g12i%%:*}/exceptions.tsv"
done
printf 'felix\n' > "$G12HQ/.felix"
_g12g "$G12HQ" init -q -b main; _g12ci "$G12HQ" 'fixture Q, a home holding felix and a product p'
_g12g "$G12HQ" config remote.origin.url "$G12QS/acme/felix.git"; _g12g "$G12HQ" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
_g12g "$G12HQ" push -q origin main; _g12g "$G12HQ" fetch -q origin; _g12g "$G12HQ" push -q "$G12QS/other/felix.git" main
_g12forp() { local o r; o="$(_g12x felix_exception_for "$1" ob1 TASK_BLOCKING "$G12L")"; r=$?; printf '%s|rc=%s' "$o" "$r"; }
_g12judgedp() {  # PROJDIR WORD -> "refused, WORD" as _g12judged prints it, for any project directory
  local o; o="$(_g12x felix_exceptions_judge "$1")"
  printf '%s\n' "$o" | LC_ALL=C awk -F'\t' -v w="$2" -v e="$G12LIVE" '
    $1 == "refused" && $2 == "ob1" && $3 == e && $4 == "the-founder" && index($5, "not honoured: ") == 1 && index($5, w) > 0 { f = 1 }
    { gsub(/\t/, " | "); a = a (a == "" ? "" : " // ") $0 }
    END { if (f) print "refused, " w; else print "judge printed [" a "]" }'
}
is "b12 A89 (B41): in a home whose origin is its own declared remote, a product's grant kept in the home's table clears and nothing is doubted" \
   "$(_g12forp "$G12HQ/projects/p") [$(_g12x felix_exceptions_doubt "$G12HQ/projects/p")]" "$G12FOR|rc=0 []"
is "b12 A89 control (B41): and the home's own project's grant clears with nothing doubted" \
   "$(_g12forp "$G12HQ/projects/felix") [$(_g12x felix_exceptions_doubt "$G12HQ/projects/felix")]" "$G12FOR|rc=0 []"
_g12g "$G12HQ" config remote.origin.url "$G12QS/other/felix.git"
is "b12 A90 (B41): with the home's origin at srvq/other, both grants are doubted and both judge whys name remote_match (control)" \
   "$(_g12forp "$G12HQ/projects/p") $(_g12judgedp "$G12HQ/projects/p" remote_match) / $(_g12forp "$G12HQ/projects/felix") $(_g12judgedp "$G12HQ/projects/felix" remote_match)" \
   "|rc=1 refused, remote_match / |rc=1 refused, remote_match"
_g12g "$G12HQ" config remote.origin.url "$G12QS/acme/felix.git"
