# >>> docs-are-not-a-frontend
printf '\ndocumentation and presentations are not a frontend (wave-2-docs.md F1-F3, blind)\n'
# Blind, written on 2026-10-28 from docs/2026-10-24-audit-fixes/wave-2-docs.md alone (sections 2 to 4, F1-F3).
# lib/, the felix CLI, hooks/ and bin/ were not read: felix_detect is called by sourcing lib/detect.sh as parts
# 0060 and 0580 do, and hooks/session-start is run as a black box. Parts 0060, 0190, 1130 and 2120 and tests/lib
# were read for how their fixtures are built. Fixture controls are their own assertions, named so.
#
# Each detection case is a fresh git fixture under $W2D whose tracked files are exactly the paths it names, each
# holding {}: the paths are put in the index by name and then checked out, so Docs/b and docs/a keep their case
# in what git tracks even on a case-insensitive file system, where they share one directory on disk. Two more
# are plain directories, for the fallback F2 says applies the same rule outside git. felix_detect runs from
# $W2D with $W2D as git's ceiling, so a fallback directory is never read as part of a repository above it.
#
# The session case is two fixture homes, each its project w2dp's own checkout (origin github.com/OwnerX/w2d-home,
# which w2dp's remote_match names, and a .felix naming w2dp), w2dp declaring tests: ctl holds three .css under
# static/ and is the positive control, run first, that session start adopts in such a home at all; f3 holds
# section 2's F3 layout. Each has its own memory root; HOME, uname, launchctl, osascript, gh, claude and graphify
# are the fixture's, as 2120's fixture W has them.
W2D="$(mkdir -p "$TMP/w2d" && cd "$TMP/w2d" && pwd -P)"; [ -n "$W2D" ] && [ -d "$W2D" ] || W2D="$TMP/w2d"
W2DWANT=""; W2DREPOS=""
W2DF3=(docs/episodes/method/workflow.js docs/outreach/2026-10-22-linkedin/figures/fig.css
       strategy/applications/deck/deck.css engine/harness/templates/monitor.html)

# ---------------------------------------------------------------- helpers ---
_w2d_repo() {   # NAME PATH... -> $W2D/NAME, a fresh git fixture tracking exactly PATH..., each holding {}, checked out
  local n="$1" d="$W2D/$1"; shift
  rm -rf "$d"; mkdir -p "$d"
  ( _fx_cd "$d" || exit 1
    git init -q -b main || exit 1
    b="$(printf '{}\n' | git hash-object -w --stdin)" || exit 1
    for p in "$@"; do git update-index --add --cacheinfo "100644,$b,$p" || exit 1; done
    git -c user.name=t -c user.email=t@t commit -qm base && git reset -q --hard ) >/dev/null 2>&1
  W2DREPOS="$W2DREPOS $n"
  W2DWANT="$W2DWANT$n:$(printf '%s\n' "$@" | LC_ALL=C sort | tr '\n' ' ');"
}
_w2d_dir() {    # NAME PATH... -> $W2D/NAME, a plain directory (no git) holding PATH..., each holding {}
  local d="$W2D/$1" p; shift
  rm -rf "$d"; mkdir -p "$d"
  for p in "$@"; do mkdir -p "$d/$(dirname "$p")" && printf '{}\n' > "$d/$p"; done
}
_w2d_caps() {   # DIR [MIN] -> felix_detect's capabilities for DIR, sorted, each followed by a space; FELIX_FRONTEND_MIN=MIN, or unset
  ( cd "$W2D" || exit 1
    unset FELIX_FRONTEND_MIN; [ -n "${2:-}" ] && { FELIX_FRONTEND_MIN="$2"; export FELIX_FRONTEND_MIN; }
    GIT_CEILING_DIRECTORIES="$W2D"; export GIT_CEILING_DIRECTORIES
    . "$FROOT/harness/lib/detect.sh" && felix_detect "$1" ) 2>/dev/null | LC_ALL=C sort -u | tr '\n' ' '
}
_w2d_has() { case " $1 " in *" $2 "*) printf '%s' "$2" ;; *) printf 'no-%s' "$2" ;; esac; }   # CAPS CAP -> CAP, or no-CAP
_w2d_fe() { _w2d_has "$(_w2d_caps "$@")" frontend; }   # DIR [MIN] -> frontend, or no-frontend

# ------------------------------------------------------ detection fixtures ---
_w2d_repo f3 "${W2DF3[@]}" tests/smoke.sh
_w2d_repo case docs/a/s.css Docs/b/s.css DOCUMENTATION/c/s.css
_w2d_repo pres slides/s.js deck/x/s.js decks/s.js
_w2d_repo static static/a.css static/b.css static/c.css
_w2d_repo near docs-viewer/s.css mydocs/s.css docs.css
_w2d_repo pkg package.json
_w2d_repo mix static/a.css static/b.css docs/c.css
_w2d_repo mix2 docs/a.css docs/b.css static/c.css
mkdir -p "$W2D/root"; _w2d_repo root/docs static/a.css static/b.css static/c.css
_w2d_dir nogit docs/a/s.css Doc/b/s.css DECK/c/s.css
_w2d_dir nogitc static/a.css static/b.css static/c.css
W2DGOT=""
for _w2dn in $W2DREPOS; do
  W2DGOT="$W2DGOT$_w2dn:$(_fx_git "$W2D/$_w2dn" ls-files 2>&1 | LC_ALL=C sort | tr '\n' ' ');"
done
is "W2D fixture: each git fixture tracks exactly the paths written for it, their case kept, and the two plain directories hold no .git (fixture control)" \
   "$W2DGOT|$([ -e "$W2D/nogit/.git" ] && echo git || echo no-git) $([ -e "$W2D/nogitc/.git" ] && echo git || echo no-git)" \
   "$W2DWANT|no-git no-git"

# ---------------------------------------------------------------- F3 ---
W2DC="$(_w2d_caps "$W2D/f3")"
is "W2D F3: a checkout tracking exactly Felix's four web files (workflow.js and fig.css under docs/, deck.css under strategy/applications/deck/, monitor.html) and a tests/ directory detects no frontend and still detects tests" \
   "$(_w2d_has "$W2DC" frontend)|$(_w2d_has "$W2DC" tests)" "no-frontend|tests"

# ---------------------------------------------------------------- F1 ---
is "W2D F1a: three .css under docs/a/, Docs/b/ and DOCUMENTATION/c/ (docs and documentation, compared without regard to case) detect no frontend" \
   "$(_w2d_fe "$W2D/case")" "no-frontend"
is "W2D F1b: three .js under slides/, deck/x/ and decks/ detect no frontend" \
   "$(_w2d_fe "$W2D/pres")" "no-frontend"
is "W2D F1c: two .css under docs/ and one under static/ with FELIX_FRONTEND_MIN=2 detect no frontend: one asset counts, under the threshold" \
   "$(_w2d_fe "$W2D/mix2" 2)" "no-frontend"
is "W2D F1 control: three .css under static/ detect frontend" \
   "$(_w2d_fe "$W2D/static")" "frontend"
is "W2D F1 control: three .css under docs-viewer/, mydocs/ and at the root as docs.css detect frontend: no directory component is a whole docs, and a file's own name is none" \
   "$(_w2d_fe "$W2D/near")" "frontend"
is "W2D F1 control: a checkout whose own directory is named docs, three .css under static/, detects frontend: only the components of the tracked path count" \
   "$(_w2d_fe "$W2D/root/docs")" "frontend"

# ---------------------------------------------------------------- F2 ---
is "W2D F2a: a root package.json and no asset detects frontend" \
   "$(_w2d_fe "$W2D/pkg")" "frontend"
is "W2D F2b: two .css under static/ and one under docs/ detect no frontend: two assets count, under the default threshold of 3" \
   "$(_w2d_fe "$W2D/mix")" "no-frontend"
is "W2D F2c: the same checkout with FELIX_FRONTEND_MIN=2 detects frontend" \
   "$(_w2d_fe "$W2D/mix" 2)" "frontend"
is "W2D F2d: outside git, three .css under docs/a/, Doc/b/ and DECK/c/ detect no frontend: the fallback applies the same rule" \
   "$(_w2d_fe "$W2D/nogit")" "no-frontend"
is "W2D F2d control: outside git, three .css under static/ detect frontend: the fallback counts assets" \
   "$(_w2d_fe "$W2D/nogitc")" "frontend"

# --------------------------------------------------------- session start ---
W2DF="$W2D/ss"; W2DB="$W2DF/bin"; W2DU="$W2DF/user"; W2DK="$W2DF/stublog"
mkdir -p "$W2DB" "$W2DU/.claude" "$W2DK"
printf '{"enabledPlugins":{"felix@felix":true}}\n' > "$W2DU/.claude/settings.json"
_w2d_put() { sed "s#@K@#$W2DK#g" > "$1" && chmod +x "$1"; }
printf '#!/bin/bash\necho Darwin\n' | _w2d_put "$W2DB/uname"
_w2d_put "$W2DB/launchctl" <<'W2DSTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@K@/launchctl.log'
case "${1:-}" in
  print) exit 113 ;;
  list) printf 'PID\tStatus\tLabel\n'; exit 0 ;;
esac
exit 0
W2DSTUB
for _w2dn in osascript:0 gh:1 claude:1 graphify:0; do
  printf '#!/bin/bash\nprintf "%%s\\n" "$*" >> "@K@/%s.log"\nexit %s\n' "${_w2dn%%:*}" "${_w2dn#*:}" | _w2d_put "$W2DB/${_w2dn%%:*}"
done
_w2d_home() {   # NAME PATH... -> $W2DF/NAME, a home that is w2dp's own checkout, w2dp declaring tests, PATH... and all else tracked
  local h="$W2DF/$1" p="$W2DF/$1/projects/w2dp" f; shift
  rm -rf "$h" "$h.mem" "$h.keep"; mkdir -p "$p" "$h.mem"
  printf '{"name":"w2dp","remote_match":"OwnerX/w2d-home","gate":"true"}\n' > "$p/project.json"
  printf '# w2dp\n' > "$p/CLAUDE.md"
  printf 'tests\n' > "$p/capabilities"
  printf '# k\tn\ts\tr\tc\n' > "$p/stack.tsv"
  printf 'w2dp\n' > "$h/.felix"
  for f in "$@"; do mkdir -p "$h/$(dirname "$f")" && printf '{}\n' > "$h/$f"; done
  ( _fx_cd "$h" && git init -q -b main && git add -A && git -c user.name=t -c user.email=t@t commit -qm base \
    && git config remote.origin.url https://github.com/OwnerX/w2d-home.git ) >/dev/null 2>&1
}
_w2d_keep() {   # HOME -> its w2dp's capabilities, stack.tsv and setup.tsv, those that exist, copied to HOME.keep
  local p="$1/projects/w2dp" f
  rm -rf "$1.keep"; mkdir -p "$1.keep"
  for f in capabilities stack.tsv setup.tsv; do [ -f "$p/$f" ] && cp "$p/$f" "$1.keep/$f"; done
  return 0
}
_w2d_diff() {   # HOME -> per table: f=same (byte for byte as kept, or absent both times), f=gone, or f=[its lines joined by |]
  local p="$1/projects/w2dp" k="$1.keep" f o=""
  for f in capabilities stack.tsv setup.tsv; do
    if [ ! -e "$p/$f" ] && [ ! -e "$k/$f" ]; then o="$o $f=same"
    elif [ -f "$p/$f" ] && [ -f "$k/$f" ] && cmp -s "$p/$f" "$k/$f"; then o="$o $f=same"
    elif [ -f "$p/$f" ]; then o="$o $f=[$(LC_ALL=C awk '{ printf "%s%s", s, $0; s = "|" }' "$p/$f")]"
    else o="$o $f=gone"; fi
  done
  printf '%s' "${o# }"
}
_w2d_front() {  # HOME -> how many lines of its w2dp's capabilities are exactly frontend
  local c="$1/projects/w2dp/capabilities"
  if [ -f "$c" ]; then LC_ALL=C grep -cx frontend "$c"; else echo none; fi
}
_w2d_calm() { local i=0; while [ "$i" -lt 100 ] && [ -d "$1/state/discover/.lock" ]; do sleep 0.2; i=$((i+1)); done; }
_w2d_ss() {     # HOME -> session start there, a startup payload: output (stdout and stderr) W2DSS, status W2DRC
  W2DSS="$(printf '{"session_id":"w2d","source":"startup","cwd":"%s"}' "$1" \
    | ( _fx_cd "$1" && env -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT -u CLAUDE_CONFIG_DIR -u FELIX_JQ -u FELIX_FRONTEND_MIN \
          -u CLAUDE_CODE_SESSION_ID -u GIT_DIR -u GIT_WORK_TREE HOME="$W2DU" FELIX_HOME="$1" FELIX_HOME_DIR="$1" \
          FELIX_MEMORY="$1.mem" PATH="$W2DB:$PATH" CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" ) 2>&1)"
  W2DRC=$?
  sleep 0.5; _w2d_calm "$1"
}
_w2d_said() { case "$W2DSS" in *"Adopted automatically"*) echo adopted ;; *) echo not-adopted ;; esac; }
_w2d_home ctl static/a.css static/b.css static/c.css tests/smoke.sh
_w2d_home f3 "${W2DF3[@]}" tests/smoke.sh
sleep 1   # the homes' indexes are older than any second a run below starts in
W2DX=""
for _w2dn in ctl f3; do
  W2DX="$W2DX$_w2dn:$(git -C "$W2DF/$_w2dn" rev-list --count HEAD 2>&1),$(git -C "$W2DF/$_w2dn" config --get remote.origin.url 2>&1)"
  W2DX="$W2DX,$(git -C "$W2DF/$_w2dn" status --porcelain 2>&1 | wc -l | tr -d ' '),$(_w2d_caps "$W2DF/$_w2dn" | sed 's/frontend //');"
done
is "W2D session fixture: both homes are w2dp's own checkout, one commit, origin github.com/OwnerX/w2d-home, clean, and apart from frontend each detects exactly what w2dp declares, tests (fixture control)" \
   "$W2DX" "ctl:1,https://github.com/OwnerX/w2d-home.git,0,tests ;f3:1,https://github.com/OwnerX/w2d-home.git,0,tests ;"

_w2d_keep "$W2DF/ctl"; _w2d_ss "$W2DF/ctl"
is "W2D session control: in a home whose own checkout holds three .css under static/, session start exits 0, appends frontend to w2dp's capabilities and says Adopted automatically (fixture control)" \
   "$W2DRC|$(_w2d_front "$W2DF/ctl")|$(_w2d_said)" "0|1|adopted"

_w2d_keep "$W2DF/f3"; _w2d_ss "$W2DF/f3"
is "W2D F3 session: in a governed home whose own checkout holds the F3 layout, session start exits 0 and adopts nothing: w2dp's capabilities, stack.tsv and setup.tsv byte for byte as before, and no Adopted automatically" \
   "$W2DRC|$(_w2d_diff "$W2DF/f3")|$(_w2d_said)" "0|capabilities=same stack.tsv=same setup.tsv=same|not-adopted"

# ------------------------------------------------- section 6, review round ---
# Blind, written on 2026-10-28 from section 6 of the same contract (F2e, F2f) alone, sections 1 to 5 as context; lib/,
# the felix CLI, hooks/ and bin/ were still not read. Every case is outside git, so the fallback answers: plain
# directories under $W2D/r6, read by _w2d_caps from $W2D with $W2D as git's ceiling, as F2d's are. F2e: a root at
# docs/nogitroot under a real docs/, a root whose own directory is named slides, and a root holding docs.css, deck.css
# and slides.css. F2f: lnk, a link by absolute path to tgt (three .css under static/); dlnk, a relative link to dtgt
# (three .css under docs/); elnk, a relative link to docs/ltgt (three .css under static/, its directory under the real
# docs/), which F2f says counts as docs/ltgt counts itself and F2e says that is all three. The fixture control proves
# each link is a link to its target, each target a directory holding exactly its files, the same read through its
# link, docs/ a real directory, and that git finds no repository at any root while the same probe finds the git
# fixture static.
W2DR="$W2D/r6"; rm -rf "$W2DR"
_w2d_dir r6/tgt static/a.css static/b.css static/c.css
_w2d_dir r6/dtgt docs/a.css docs/b.css docs/c.css
_w2d_dir r6/docs/nogitroot static/a.css static/b.css static/c.css
_w2d_dir r6/docs/ltgt static/a.css static/b.css static/c.css
_w2d_dir r6/slides static/a.css static/b.css static/c.css
_w2d_dir r6/near docs.css deck.css slides.css
ln -s "$W2DR/tgt" "$W2DR/lnk"; ln -s dtgt "$W2DR/dlnk"; ln -s docs/ltgt "$W2DR/elnk"
_w2d_what() {   # PATH -> link>TARGET, dir or none, then :[every file under it, read through it, sorted, each followed by a space]
  local k=none
  if [ -L "$1" ]; then k="link>$(readlink "$1")"; elif [ -d "$1" ]; then k=dir; fi
  printf '%s:[%s]' "$k" "$( ( cd "$1" 2>/dev/null && find . -type f ) | LC_ALL=C sort | tr '\n' ' ')"
}
_w2d_git() {    # DIR... -> git(DIR below $W2D) for each DIR where git finds a repository, under _w2d_caps's ceiling; nothing for none
  ( cd "$W2D" || exit 1
    GIT_CEILING_DIRECTORIES="$W2D"; export GIT_CEILING_DIRECTORIES
    for d in "$@"; do git -C "$d" rev-parse --git-dir >/dev/null 2>&1 && printf 'git(%s) ' "${d#"$W2D"/}"; done
    exit 0 )
}
W2DS='./static/a.css ./static/b.css ./static/c.css '; W2DSD='./docs/a.css ./docs/b.css ./docs/c.css '
W2DRG=""
for _w2dn in lnk tgt dlnk dtgt elnk docs/ltgt docs/nogitroot slides near; do W2DRG="$W2DRG $_w2dn=$(_w2d_what "$W2DR/$_w2dn")"; done
W2DRG="$W2DRG|docs=$([ -d "$W2DR/docs" ] && [ ! -L "$W2DR/docs" ] && echo real-dir || echo other)"
W2DRG="$W2DRG|.git=[$(find "$W2DR" -name .git 2>&1)]|git=[$(_w2d_git "$W2DR/lnk" "$W2DR/tgt" "$W2DR/dlnk" "$W2DR/dtgt" \
  "$W2DR/elnk" "$W2DR/docs/ltgt" "$W2DR/docs/nogitroot" "$W2DR/slides" "$W2DR/near")]|probe=[$(_w2d_git "$W2D/static")]"
is "W2D R fixture: outside git, lnk links to tgt by absolute path, dlnk to dtgt and elnk to docs/ltgt by relative path, each target a directory holding exactly its three .css, the same read through its link; docs/ is a real directory; no .git lies under r6 and git finds no repository at any root, while the same probe finds the git fixture static (fixture control)" \
   "$W2DRG" \
   " lnk=link>$W2DR/tgt:[$W2DS] tgt=dir:[$W2DS] dlnk=link>dtgt:[$W2DSD] dtgt=dir:[$W2DSD] elnk=link>docs/ltgt:[$W2DS] docs/ltgt=dir:[$W2DS] docs/nogitroot=dir:[$W2DS] slides=dir:[$W2DS] near=dir:[./deck.css ./docs.css ./slides.css ]|docs=real-dir|.git=[]|git=[]|probe=[git(static) ]"

is "W2D R F2e: outside git, a root at docs/nogitroot, docs/ a real directory above it, holding three .css under static/ detects frontend: only a component of a path below the root can exclude a file" \
   "$(_w2d_fe "$W2DR/docs/nogitroot")" "frontend"
is "W2D R F2e own name: outside git, a root whose own directory is named slides, holding three .css under static/, detects frontend: the twin of the git listing's root/docs control" \
   "$(_w2d_fe "$W2DR/slides")" "frontend"
is "W2D R F2e near-miss: outside git, three .css at the root named docs.css, deck.css and slides.css detect frontend: a file's own name is no directory component" \
   "$(_w2d_fe "$W2DR/near")" "frontend"
is "W2D R F2f: outside git, a symbolic link whose target holds three .css under static/ detects frontend when the link is the root" \
   "$(_w2d_fe "$W2DR/lnk")" "frontend"
is "W2D R F2f target: outside git, the link's target alone detects frontend too, and the link as the root detects exactly the capabilities its target does" \
   "$(_w2d_fe "$W2DR/tgt")|$(_w2d_caps "$W2DR/lnk")" "frontend|$(_w2d_caps "$W2DR/tgt")"
is "W2D R F2f count: outside git, with FELIX_FRONTEND_MIN=4 neither the link nor its target detects frontend and with 3 both do: through the link the three assets count three, as the target counts them" \
   "$(_w2d_fe "$W2DR/lnk" 4)|$(_w2d_fe "$W2DR/tgt" 4)|$(_w2d_fe "$W2DR/lnk" 3)|$(_w2d_fe "$W2DR/tgt" 3)" \
   "no-frontend|no-frontend|frontend|frontend"
is "W2D R F2f with F1: outside git, a symbolic link whose target holds three .css under docs/ detects no frontend, and its target alone detects none" \
   "$(_w2d_fe "$W2DR/dlnk")|$(_w2d_fe "$W2DR/dtgt")" "no-frontend|no-frontend"
is "W2D R F2f with F2e: outside git, a link to docs/ltgt, a directory under a real docs/ holding three .css under static/, detects frontend as docs/ltgt alone does: the link counts as its target counts itself" \
   "$(_w2d_fe "$W2DR/elnk")|$(_w2d_fe "$W2DR/docs/ltgt")" "frontend|frontend"

_w2d_calm "$W2DF/ctl"; _w2d_calm "$W2DF/f3"; rm -rf "$W2D"
# <<< docs-are-not-a-frontend
