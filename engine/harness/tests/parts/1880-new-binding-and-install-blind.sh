# >>> new-binding-and-install
printf '\nfelix new does not rebind and says what binds; felix install refuses what git does not track (audit b13, contract A23-A37, blind)\n'
# Blind, written on 2026-10-24 from the b13 contract alone (b13-felix-cli-trust-and-binding.md, the
# audit register of 2026-10-24, batch 13: C116, C117 and C064; B16-B26, A23-A37). Not read:
# engine/harness/felix, lib/*.sh, hooks, bin, projects/*/gate.sh. felix new runs in a home, memory root
# and user HOME of this part's own under $B13N, through the claude stub, as _nc_build sets them up; felix
# install runs from a cache entry against a source as tests/lib/install-fixture.sh builds them, in trees
# of its own under $B13N/inst. Everything is removed at the part's end.
#
# Readings, where the contract leaves room. A refusal is asserted on its exit, its words and what it left;
# where an A item is silent and its B item names a path (<root>/.felix in B16 and B18), the path is held
# too, physically. "A line" is exactly one line. A27, the no-origin row of A31 and the no-origin case of
# A32 read the one run of A27; A32's GitLab case reads A30's first run. The GitHub rows of A31 share one
# remote_match, so each project is removed before the next is made, or B17 would rightly refuse it. A34
# names each stray as git names it, read from git ls-files --others --directory in the fixture; the source
# is committed with global excludes off, so only the repository's own .gitignore decides what is ignored.
_cmstub_build
B13N="$TMP/b13new"; rm -rf "$B13N"; mkdir -p "$B13N/home/projects" "$B13N/mem" "$B13N/userhome" "$B13N/co" "$B13N/plain"
B13N="$(cd "$B13N" && pwd -P)"; B13NH="$B13N/home"; B13NM="$B13N/mem"; B13NU="$B13N/userhome"; B13NRC=0; B13NR=""
_b13n_check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]${4:+: $4}"; fi; }   # NAME GOT WANT [DETAIL]
_b13n_why() { printf 'exit %s; stdout: %s; stderr: %s' "$B13NRC" "$(head -c 700 "$B13N/out" | tr '\n' ' ')" "$(head -c 500 "$B13N/err" | tr '\n' ' ')"; }
_b13n() {   # DIR ARGS...: felix new in DIR, this part's home, memory root and HOME, the claude stub first; B13NRC, out, err
  local d="$1"; shift; : > "$CMSTUB_LOG"
  ( cd "$d" && HOME="$B13NU" FELIX_HOME="$B13NH" FELIX_MEMORY="$B13NM" PATH="$CMSTUB:$PATH" "$FELIX" new "$@" ) \
    > "$B13N/out" 2> "$B13N/err"
  B13NRC=$?
}
_b13n_which() { ( cd "$1" && HOME="$B13NU" FELIX_HOME="$B13NH" FELIX_MEMORY="$B13NM" PATH="$CMSTUB:$PATH" "$FELIX" which 2>&1 ); }
_b13n_calls() { if [ -s "$CMSTUB_LOG" ]; then LC_ALL=C awk 'END { print NR }' "$CMSTUB_LOG"; else printf '0'; fi; }
_b13n_repo() {   # NAME -> B13NR: a new repository under $B13N/co holding a package.json, as _nc_repo makes one
  mkdir -p "$B13N/co/$1"
  ( _fx_cd "$B13N/co/$1" && git init -q -b main \
    && printf '{ "name": "cheap", "scripts": { "verify": "echo ok" }, "dependencies": { "express": "^4" } }\n' > package.json ) >/dev/null 2>&1
  B13NR="$(cd "$B13N/co/$1" && pwd -P)"
}
_b13n_commit() { _fx_git "$1" add -A >/dev/null 2>&1; _fx_git "$1" -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c maintenance.auto=false commit -qm "$2" >/dev/null 2>&1; }
_b13n_lines() { [ -f "$2" ] && LC_ALL=C awk -v p="$1" 'index($0, p) == 1' "$2"; return 0; }   # PREFIX FILE -> its lines that begin so
_b13n_count() { _b13n_lines "$1" "$2" | LC_ALL=C awk 'END { print NR }'; }
_b13n_has() { if [ -n "$2" ]; then case "$1" in *"$2"*) printf 'yes' ;; *) printf 'no' ;; esac; else printf 'nothing to look for'; fi; }
_b13n_ex() { if [ -e "$1" ]; then printf 'present'; else printf 'absent'; fi; }
_b13n_rm() {   # PROJECT.JSON -> its remote_match, or what stopped it being read
  [ -f "$1" ] || { printf '(no project.json)'; return 0; }
  python3 -I -c 'import json, sys
try:
    v = json.load(open(sys.argv[1])).get("remote_match", "(absent)")
except Exception as e:
    v = "(unreadable: %s)" % e.__class__.__name__
print(v)' "$1" 2>/dev/null || printf '(python3 could not run)'
}

# ------------------------------------------------- A23-A29: what felix new binds ---
_b13n_repo mono; B13N_MONO="$B13NR"; mkdir -p "$B13NR/apps/web" "$B13NR/apps/api"
printf '{ "name": "web" }\n' > "$B13NR/apps/web/package.json"; printf '{ "name": "api" }\n' > "$B13NR/apps/api/package.json"
_b13n "$B13N_MONO" web apps/web --no-commission
_b13n_check "A23 (B16) (fixture control): felix new web apps/web --no-commission binds the git root of a repository holding apps/web and apps/api to web" \
  "exit=$B13NRC|marker $(cat "$B13N_MONO/.felix" 2>/dev/null)|projects/web $(_b13n_ex "$B13NH/projects/web")" "exit=0|marker web|projects/web present" "$(_b13n_why)"
cp "$B13N_MONO/.felix" "$B13N/mono.felix" 2>/dev/null
_b13n "$B13N_MONO" api apps/api --no-commission; B13N_E="$(cat "$B13N/err")"
_b13n_check "A23 (B16): felix new api apps/api in the same repository is refused: exit 1, already governed by web, felix new does not rebind, the marker named and kept, no project, no memory, no claude call" \
  "exit=$B13NRC|$(_b13n_has "$B13N_E" 'already governed by web')|$(_b13n_has "$B13N_E" 'felix new does not rebind')|names $(_b13n_has "$B13N_E" "$B13N_MONO/.felix")|marker $(cmp -s "$B13N_MONO/.felix" "$B13N/mono.felix" && echo kept || echo changed)|projects/api $(_b13n_ex "$B13NH/projects/api")|memory api $(_b13n_ex "$B13NM/api")|claude $(_b13n_calls)" \
  "exit=1|yes|yes|names yes|marker kept|projects/api absent|memory api absent|claude 0" "$(_b13n_why)"
rm -rf "$B13NH/projects/api" "$B13NM/api"; cp "$B13N/mono.felix" "$B13N_MONO/.felix" 2>/dev/null   # whatever A23's run left
_b13n "$B13N_MONO" api apps/api
_b13n_check "A24 (B16): the same felix new api apps/api, commissioning, is refused as well and runs no claude command" \
  "exit=$B13NRC|claude $(_b13n_calls)|marker $(cmp -s "$B13N_MONO/.felix" "$B13N/mono.felix" && echo kept || echo changed)" "exit=1|claude 0|marker kept" "$(_b13n_why)"
mkdir -p "$B13NH/projects/rx"; printf '{\n  "name": "rx",\n  "remote_match": "example/rx-repo",\n  "gate": "true"\n}\n' > "$B13NH/projects/rx/project.json"
_b13n_repo rxco; ( _fx_cd "$B13NR" && git remote add origin https://github.com/example/rx-repo.git ) >/dev/null 2>&1
_b13n "$B13NR" other --no-commission; B13N_E="$(cat "$B13N/err")"
_b13n_check "A25 (B17): a checkout with no marker whose origin holds another project's remote_match is refused: exit 1, already governed by rx, naming remote_match, and nothing written" \
  "exit=$B13NRC|$(_b13n_has "$B13N_E" 'already governed by rx')|$(_b13n_has "$B13N_E" remote_match)|marker $(_b13n_ex "$B13NR/.felix")|projects/other $(_b13n_ex "$B13NH/projects/other")" \
  "exit=1|yes|yes|marker absent|projects/other absent" "$(_b13n_why)"
B13N_V="ghost $(_b13n_ex "$B13NH/projects/ghost")"; B13N_G=""
for B13N_I in 1 2 3; do
  _b13n_repo "fresh$B13N_I"
  case "$B13N_I" in
    1) printf 'ghost\n' > "$B13NR/.felix"; B13N_W=ghost ;;
    2) : > "$B13NR/.felix"; B13N_W='named no project' ;;
    *) printf '../bad\n' > "$B13NR/.felix"; B13N_W='named no project' ;;
  esac
  _b13n "$B13NR" "fresh$B13N_I" --no-commission; B13N_L="$(_b13n_lines '  replaced ' "$B13N/out")"
  B13N_G="$B13N_G fresh$B13N_I: exit=$B13NRC,marker=$(cat "$B13NR/.felix" 2>/dev/null),lines=$(_b13n_count '  replaced ' "$B13N/out"),root=$(_b13n_has "$B13N_L" "$B13NR/.felix"),says=$(_b13n_has "$B13N_L" "$B13N_W");"
done
_b13n_check "A26 (B18): a marker naming no project (ghost with no projects/ghost, empty, ../bad) does not stop felix new; it binds and says in one replaced line what the marker held" \
  "$B13N_V|$B13N_G" "ghost absent| fresh1: exit=0,marker=fresh1,lines=1,root=yes,says=yes; fresh2: exit=0,marker=fresh2,lines=1,root=yes,says=yes; fresh3: exit=0,marker=fresh3,lines=1,root=yes,says=yes;" "$(_b13n_why)"
_b13n_repo plain1; B13N_PLAIN="$B13NR"; _b13n "$B13NR" plain1 --no-commission; cp "$B13N/out" "$B13N/out.plain1"
_b13n_check "A27 (B18; control): a fresh checkout with no marker binds with no replaced line" \
  "exit=$B13NRC|lines=$(_b13n_count '  replaced ' "$B13N/out")" "exit=0|lines=0" "$(_b13n_why)"
_b13n_repo subx; B13N_SUBX="$B13NR"; mkdir -p "$B13NR/apps/x"; printf '{ "name": "x" }\n' > "$B13NR/apps/x/package.json"
_b13n "$B13N_SUBX" sub apps/x --no-commission; B13N_L="$(_b13n_lines '  checkout ' "$B13N/out")"
B13N_G="below the root: exit=$B13NRC,lines=$(_b13n_count '  checkout ' "$B13N/out"),root=$(_b13n_has "$B13N_L" "$B13N_SUBX"),says=$(_b13n_has "$B13N_L" 'the git root holding')"
_b13n_repo subroot; _b13n "$B13NR" subroot --no-commission
_b13n_check "A28 (B19): a PATH below the git root gets one checkout line naming the root it binds, and a PATH that is the root gets none" \
  "$B13N_G | at the root: exit=$B13NRC,lines=$(_b13n_count '  checkout ' "$B13N/out")" \
  "below the root: exit=0,lines=1,root=yes,says=yes | at the root: exit=0,lines=0" "$(_b13n_why)"
_b13n_cl() { _b13n_lines '  commit ' "$B13N/out" | LC_ALL=C awk 'index($0, ".felix") && index($0, "worktree") { n++ } END { print n + 0 }'; }
B13N_G=""
for B13N_I in 1 2 3 4; do
  _b13n_repo "cm$B13N_I"; [ "$B13N_I" -gt 2 ] || _b13n_commit "$B13NR" one
  if [ "$B13N_I" = 1 ] || [ "$B13N_I" = 3 ]; then _b13n "$B13NR" "cm$B13N_I" --no-commission; else _b13n "$B13NR" "cm$B13N_I"; fi
  B13N_G="$B13N_G cm$B13N_I:exit=$B13NRC,commit=$(_b13n_cl)"
done
_b13n_repo cm5; printf 'cm5\n' > "$B13NR/.felix"; _b13n_commit "$B13NR" marked
B13N_V="HEAD:.felix $(git -C "$B13NR" show HEAD:.felix 2>/dev/null)|projects/cm5 $(_b13n_ex "$B13NH/projects/cm5")"
_b13n "$B13NR" cm5 --no-commission; B13N_G="$B13N_G cm5:exit=$B13NRC,commit=$(_b13n_count '  commit ' "$B13N/out")"
mkdir -p "$B13N/plain/cm6"; B13N_P6="$(cd "$B13N/plain/cm6" && pwd -P)"; printf '{ "name": "cm6" }\n' > "$B13N_P6/package.json"
B13N_V="$B13N_V|cm6 $(git -C "$B13N_P6" rev-parse --is-inside-work-tree >/dev/null 2>&1 && echo in-git || echo outside-git)"
_b13n "$B13N_P6" cm6 --no-commission; B13N_G="$B13N_G cm6:exit=$B13NRC,commit=$(_b13n_count '  commit ' "$B13N/out")"
_b13n_check "A29 (B20): a commit line naming .felix and the worktrees appears for an untracked marker after one commit and on an unborn HEAD, with and without --no-commission, and not when HEAD:.felix already names the project or outside git" \
  "$B13N_V|$B13N_G" "HEAD:.felix cm5|projects/cm5 absent|cm6 outside-git| cm1:exit=0,commit=1 cm2:exit=0,commit=1 cm3:exit=0,commit=1 cm4:exit=0,commit=1 cm5:exit=0,commit=0 cm6:exit=0,commit=0" "$(_b13n_why)"

# --------------------------------------- A30-A33: remote_match and unattended ---
: > "$B13N/gl.all"; B13N_G=""; B13N_GL=()
for B13N_I in 1 2 3; do
  case "$B13N_I" in
    1) B13N_U='https://user:SECRETTOKEN@gitlab.example/grp/proj.git'; B13N_W='gitlab.example/grp/proj' ;;
    2) B13N_U='git@gitlab.example:grp/proj.git'; B13N_W='gitlab.example:grp/proj' ;;
    *) B13N_U='ssh://git@gitlab.example:2222/grp/proj.git'; B13N_W='gitlab.example:2222/grp/proj' ;;
  esac
  _b13n_repo "gl$B13N_I"; B13N_GL[${#B13N_GL[@]}]="$B13NR"
  ( _fx_cd "$B13NR" && git remote add origin "$B13N_U" ) >/dev/null 2>&1
  _b13n "$B13NR" "gl$B13N_I" --no-commission; cat "$B13N/out" "$B13N/err" >> "$B13N/gl.all"
  [ "$B13N_I" != 1 ] || cp "$B13N/out" "$B13N/out.gl1"
  B13N_G="$B13N_G gl$B13N_I:exit=$B13NRC,remote_match=$(_b13n_rm "$B13NH/projects/gl$B13N_I/project.json"),repo line=$(_b13n_has "$(_b13n_lines '  repo ' "$B13N/out")" "$B13N_W")"
done
B13N_S="$( { cat "$B13N/gl.all"; for B13N_F in "$B13NH"/projects/*/project.json; do [ -f "$B13N_F" ] && cat "$B13N_F"; done; } | LC_ALL=C awk 'index($0, "SECRETTOKEN") || index($0, "user:") { n++ } END { print n + 0 }')"
B13N_WH=""; B13N_I=0
for B13N_D in ${B13N_GL[@]+"${B13N_GL[@]}"}; do
  B13N_I=$((B13N_I + 1)); rm -f "$B13N_D/.felix"
  case "$(_b13n_which "$B13N_D")" in *"project:      gl$B13N_I"*) B13N_WH="$B13N_WH gl$B13N_I" ;; *) B13N_WH="$B13N_WH (not gl$B13N_I)" ;; esac
done
_b13n_check "A30 (B21): a GitLab origin's remote_match drops its userinfo or scheme and .git, the repo line shows it, no credential reaches project.json or the output, and the checkout still resolves by its remote" \
  "$B13N_G|credential lines $B13N_S|which:$B13N_WH" \
  " gl1:exit=0,remote_match=gitlab.example/grp/proj,repo line=yes gl2:exit=0,remote_match=gitlab.example:grp/proj,repo line=yes gl3:exit=0,remote_match=gitlab.example:2222/grp/proj,repo line=yes|credential lines 0|which: gl1 gl2 gl3" "$(_b13n_why)"
: > "$B13N/gh.all"; B13N_G=""
for B13N_I in 1 2 3; do
  case "$B13N_I" in
    1) B13N_U='https://github.com/Acme/Widget.git' ;;
    2) B13N_U='https://x-access-token:SECRETTOKEN@github.com/Acme/Widget.git' ;;
    *) B13N_U='git@github.com:Acme/Widget.git' ;;
  esac
  _b13n_repo "gh$B13N_I"; ( _fx_cd "$B13NR" && git remote add origin "$B13N_U" ) >/dev/null 2>&1
  _b13n "$B13NR" "gh$B13N_I" --no-commission
  { cat "$B13N/out" "$B13N/err"; cat "$B13NH/projects/gh$B13N_I/project.json" 2>/dev/null; } >> "$B13N/gh.all"
  B13N_G="$B13N_G gh$B13N_I:exit=$B13NRC,remote_match=$(_b13n_rm "$B13NH/projects/gh$B13N_I/project.json")"
  rm -rf "$B13NH/projects/gh$B13N_I" "$B13NM/gh$B13N_I"
done
_b13n_check "A31 (B21; control): GitHub origins keep today's remote_match, a token in one reaches nothing, and no origin is empty" \
  "$B13N_G no origin:remote_match=$(_b13n_rm "$B13NH/projects/plain1/project.json")|SECRETTOKEN $(LC_ALL=C grep -c SECRETTOKEN "$B13N/gh.all")" \
  " gh1:exit=0,remote_match=Acme/Widget gh2:exit=0,remote_match=Acme/Widget gh3:exit=0,remote_match=Acme/Widget no origin:remote_match=|SECRETTOKEN 0" "$(_b13n_why)"
B13N_G=""
for B13N_K in plain1 gl1; do
  B13N_L="$(_b13n_lines '  unattended ' "$B13N/out.$B13N_K")"
  B13N_G="$B13N_G $B13N_K:lines=$(_b13n_count '  unattended ' "$B13N/out.$B13N_K"),says=$(_b13n_has "$B13N_L" "nothing runs for $B13N_K unattended"),names=$(_b13n_has "$B13N_L" "projects/$B13N_K/project.json")"
done
_b13n_check "A32 (B22): with no origin, and with a GitLab origin, felix new says in one unattended line that nothing runs for the project unattended, naming its project.json" \
  "$B13N_G" " plain1:lines=1,says=yes,names=yes gl1:lines=1,says=yes,names=yes" "plain1: $(tr '\n' ' ' < "$B13N/out.plain1" | head -c 600)"
_b13n_repo own1; ( _fx_cd "$B13NR" && git remote add origin https://github.com/Acme/b13own.git ) >/dev/null 2>&1
_b13n "$B13NR" own1 --no-commission
_b13n_check "A33 (B22; control): with a github.com origin the checkout is its own and no unattended line is printed" \
  "exit=$B13NRC|lines=$(_b13n_count '  unattended ' "$B13N/out")" "exit=0|lines=0" "$(_b13n_why)"

# ----------------------------------------- A34-A37: felix install and strays ---
B13I="$B13N/inst"; B13IH="$B13I/home"; B13IC="$B13IH/.claude/plugins/cache/felix/felix/0.49.9"; B13IS="$B13I/src"; B13IS2="$B13I/src2"
B13ICB="$B13I/claude"; B13ICBL="$B13I/claude.log"; B13IRC=0
mkdir -p "$B13IH/.claude/plugins" "$B13IC/.claude-plugin" "$B13ICB"
cp -R "$FROOT/harness" "$B13IC/harness"
printf '{\n  "name": "felix",\n  "version": "0.49.9"\n}\n' > "$B13IC/.claude-plugin/plugin.json"
for B13N_D in "$B13IS" "$B13IS2"; do
  mkdir -p "$B13N_D/engine/.claude-plugin" "$B13N_D/.claude-plugin"
  cp -R "$FROOT/harness" "$B13N_D/engine/harness"
  printf '{\n  "name": "felix",\n  "version": "0.49.9"\n}\n' > "$B13N_D/engine/.claude-plugin/plugin.json"
  printf '{\n  "name": "felix",\n  "plugins": [ { "name": "felix", "source": "./engine" } ]\n}\n' > "$B13N_D/.claude-plugin/marketplace.json"
done
cat > "$B13ICB/claude" <<B13ICLAUDE
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$B13ICBL"
case "\$*" in
  "plugin list --json") printf '{ "felix@felix": { "installPath": "%s" } }\n' "$B13IC" ;;
  "plugin marketplace add "*) [ -f "\$4/.claude-plugin/marketplace.json" ] || exit 1 ;;
esac
exit 0
B13ICLAUDE
chmod +x "$B13ICB/claude"
printf '.DS_Store\n.claude-flow/\n' > "$B13IS/.gitignore"
( _fx_cd "$B13IS" && git init -q -b main && git -c core.excludesFile=/dev/null add -A \
  && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c maintenance.auto=false commit -qm source ) >/dev/null 2>&1
cp "$B13IS/engine/.claude-plugin/plugin.json" "$B13I/plugin.keep"
_b13i() {   # SRC ARGS...: felix install from the cache entry against SRC, as 0630 runs it; B13IRC and $B13I/out, both streams
  local s="$1"; shift; : > "$B13ICBL"
  ( cd "$s" && HOME="$B13IH" FELIX_HOME="$s" PATH="$B13ICB:$PATH" "$B13IC/harness/felix" install "$@" ) > "$B13I/out" 2>&1
  B13IRC=$?
}
_b13i_strays() { git -C "$B13IS" ls-files --others --directory -- engine/ 2>/dev/null; }
_b13i_calls() { if [ -s "$B13ICBL" ]; then LC_ALL=C awk 'END { print NR }' "$B13ICBL"; else printf '0'; fi; }
_b13i_plugin() { if cmp -s "$B13IS/engine/.claude-plugin/plugin.json" "$B13I/plugin.keep"; then printf 'same'; else printf 'changed'; cp "$B13I/plugin.keep" "$B13IS/engine/.claude-plugin/plugin.json"; fi; }
_b13i_stray() {   # KIND on|off: one stray of A34 made or removed
  case "$1$2" in
    dson) printf 'Finder\n' > "$B13IS/engine/.DS_Store" ;;          dsoff) rm -f "$B13IS/engine/.DS_Store" ;;
    cfon) mkdir -p "$B13IS/engine/harness/.claude-flow/data"; printf '{}\n' > "$B13IS/engine/harness/.claude-flow/data/x.jsonl" ;;
    cfoff) rm -rf "$B13IS/engine/harness/.claude-flow" ;;
    ndon) mkdir -p "$B13IS/engine/commands/newdir" ;;              ndoff) rm -rf "$B13IS/engine/commands" ;;
  esac
}
_b13n_check "A34-A37 (fixture control): the install source is a git repository with every file committed and nothing untracked or ignored under engine/" \
  "$(git -C "$B13IS" rev-parse --is-inside-work-tree 2>&1)|head $([ -n "$(git -C "$B13IS" rev-parse --verify -q HEAD 2>/dev/null)" ] && echo born)|strays [$(_b13i_strays | tr '\n' ' ')]" "true|head born|strays []"
B13N_G=""; B13N_V=""
for B13N_K in ds cf nd; do
  _b13i_stray "$B13N_K" on; B13N_P="$(_b13i_strays)"
  B13N_V="$B13N_V $B13N_K:$(printf '%s\n' "$B13N_P" | LC_ALL=C awk 'NF { n++ } END { print n + 0 }')"
  _b13i "$B13IS" --no-bump; B13N_O="$(cat "$B13I/out")"; B13N_L="$(LC_ALL=C awk 'END { print }' "$B13I/out")"
  B13N_G="$B13N_G $B13N_K: exit=$B13IRC,claude=$(_b13i_calls),plugin=$(_b13i_plugin),count=$(_b13n_has "$B13N_O" 'engine/ holds 1 path(s) git does not track'),names=$(_b13n_has "$B13N_O" "$B13N_P"),last=$(_b13n_has "$B13N_L" "the first is $B13N_P");"
  _b13i_stray "$B13N_K" off
done
_b13n_check "A34 (B23) (fixture control): git names each stray as one path: a .DS_Store, an ignored .claude-flow directory, and an empty directory" "$B13N_V" " ds:1 cf:1 nd:1"
_b13n_check "A34 (B23): felix install --no-bump with any one path git does not track under engine/ refuses with exit 1 before any claude command or bump, naming the path, and its last line names it first" \
  "$B13N_G" " ds: exit=1,claude=0,plugin=same,count=yes,names=yes,last=yes; cf: exit=1,claude=0,plugin=same,count=yes,names=yes,last=yes; nd: exit=1,claude=0,plugin=same,count=yes,names=yes,last=yes;" \
  "$(tr '\n' ' ' < "$B13I/out" | head -c 700)"
for B13N_K in ds cf nd; do _b13i_stray "$B13N_K" on; done
B13N_V="$(_b13i_strays | LC_ALL=C awk 'NF { n++ } END { print n + 0 }')"
_b13i "$B13IS" --no-bump; B13N_G="no-bump: exit=$B13IRC,says=$(_b13n_has "$(cat "$B13I/out")" 'engine/ holds 3 path(s) git does not track')"
_b13i "$B13IS"; B13N_G="$B13N_G | plain install: exit=$B13IRC,plugin=$(_b13i_plugin),claude=$(_b13i_calls)"
for B13N_K in ds cf nd; do _b13i_stray "$B13N_K" off; done
_b13n_check "A34 (B23): with all three strays the refusal counts 3 path(s), and a plain felix install, bumping allowed, bumps nothing and runs no claude command" \
  "strays $B13N_V|$B13N_G" "strays 3|no-bump: exit=1,says=yes | plain install: exit=1,plugin=same,claude=0" "$(tr '\n' ' ' < "$B13I/out" | head -c 700)"
B13N_V="strays [$(_b13i_strays | tr '\n' ' ')]"; _b13i "$B13IS" --no-bump
_b13n_check "A35 (B24; control): with nothing untracked or ignored under engine/, felix install --no-bump verifies the installed engine as today" \
  "$B13N_V|exit=$B13IRC|$(_b13n_has "$(cat "$B13I/out")" 'checked    the installed engine matches this tree')" "strays []|exit=0|yes" "$(tr '\n' ' ' < "$B13I/out" | head -c 700)"
B13N_V="$(git -C "$B13IS2" rev-parse --is-inside-work-tree >/dev/null 2>&1 && echo in-git || echo outside-git)"; _b13i "$B13IS2" --no-bump
_b13n_check "A36 (B25): a source outside any git work tree installs as today, saying in one line that git could not be asked about engine/" \
  "$B13N_V|exit=$B13IRC|unknown line $(LC_ALL=C awk 'index($0, "could not ask git") && index($0, "engine/") { n++ } END { print n + 0 }' "$B13I/out")|$(_b13n_has "$(cat "$B13I/out")" 'checked    the installed engine matches this tree')" \
  "outside-git|exit=0|unknown line 1|yes" "$(tr '\n' ' ' < "$B13I/out" | head -c 700)"
_b13i_stray ds on; _b13i "$B13IS" --uninstall; B13N_O="$(cat "$B13I/out")"
_b13n_check "A37 (B26; control): felix install --uninstall with a .DS_Store under engine/ exits 0 and names no stray" \
  "exit=$B13IRC|$(_b13n_has "$B13N_O" '.DS_Store')|$(_b13n_has "$B13N_O" 'git does not track')" "exit=0|no|no" "$(printf '%s' "$B13N_O" | tr '\n' ' ' | head -c 700)"
_b13i_stray ds off

rm -rf "$B13N"
