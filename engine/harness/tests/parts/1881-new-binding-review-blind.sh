# >>> new-binding-review
printf '\nfelix new refuses only the same repository; felix install asks git only where git tracks the engine (audit b13 review round, contract R1-R2, A38-A44, blind)\n'
# Blind, written on 2026-10-27 from the b13 contract's review round (section 9 of
# b13-felix-cli-trust-and-binding.md: R1 and R2, A38-A44), which restates the review's findings M1 and M2.
# Not read: engine/harness/felix, lib/*.sh, hooks, bin, projects/*/gate.sh. felix new runs as part 1880
# runs it: in a home, memory root and user HOME of this part's own under $B13R, through the claude stub,
# always with --no-commission. felix install runs from a cache entry against sources built as
# tests/lib/install-fixture.sh builds its source, in trees under $B13R/inst. Everything is removed at the
# part's end.
#
# Readings, where the contract leaves room. "Binds" is held on the exit, the marker, the project made, its
# remote_match and what felix which says in the checkout; "refused" on the exit, the words and that nothing
# was made. The paths a refusal must name are physical, since the home is given physically. R2's "the same
# claude commands as a source outside git" is read from this tree: the count of the outside-git source's
# run (B25's case, A36's) is the yardstick, and it must not be zero.
_cmstub_build
B13R="$TMP/b13rev"; rm -rf "$B13R"; mkdir -p "$B13R/home/projects" "$B13R/mem" "$B13R/userhome" "$B13R/co" "$B13R/inst"
B13R="$(cd "$B13R" && pwd -P)"; B13RH="$B13R/home"; B13RM="$B13R/mem"; B13RU="$B13R/userhome"; B13RRC=0; B13RD=""
_b13r_check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]${4:+: $4}"; fi; }   # NAME GOT WANT [DETAIL]
_b13r_why() { printf 'exit %s; stdout: %s; stderr: %s' "$B13RRC" "$(head -c 500 "$B13R/out" | tr '\n' ' ')" "$(head -c 400 "$B13R/err" | tr '\n' ' ')"; }
_b13r_has() { if [ -n "$2" ]; then case "$1" in *"$2"*) printf 'yes' ;; *) printf 'no' ;; esac; else printf 'nothing to look for'; fi; }
_b13r_ex() { if [ -e "$1" ]; then printf 'present'; else printf 'absent'; fi; }
_b13r_count() { LC_ALL=C awk 'END { print NR }' "$1" 2>/dev/null || printf '(unreadable)'; }   # FILE -> its line count
_b13r_new() {   # DIR NAME: felix new NAME --no-commission in DIR, this part's home, memory root and HOME; B13RRC, out, err
  ( cd "$1" && HOME="$B13RU" FELIX_HOME="$B13RH" FELIX_MEMORY="$B13RM" PATH="$CMSTUB:$PATH" "$FELIX" new "$2" --no-commission ) \
    > "$B13R/out" 2> "$B13R/err"
  B13RRC=$?
}
_b13r_project() {   # DIR -> the project felix which names there, or (none)
  ( cd "$1" && HOME="$B13RU" FELIX_HOME="$B13RH" FELIX_MEMORY="$B13RM" PATH="$CMSTUB:$PATH" "$FELIX" which 2>&1 ) > "$B13R/which" 2>&1
  LC_ALL=C awk '!f && index($0, "project:") == 1 { sub(/^project:[ ]*/, ""); v = $0; f = 1 } END { if (f) print v; else print "(none)" }' "$B13R/which"
}
_b13r_repo() {   # NAME ORIGIN -> B13RD: a new repository under $B13R/co with a package.json and that origin, as 1880 makes one
  mkdir -p "$B13R/co/$1"
  ( _fx_cd "$B13R/co/$1" && git init -q -b main && git remote add origin "$2" \
    && printf '{ "name": "cheap", "scripts": { "verify": "echo ok" }, "dependencies": { "express": "^4" } }\n' > package.json ) >/dev/null 2>&1
  B13RD="$(cd "$B13R/co/$1" && pwd -P)"
}
_b13r_rm() {   # PROJECT.JSON -> its remote_match, or what stopped it being read
  [ -f "$1" ] || { printf '(no project.json)'; return 0; }
  python3 -I -c 'import json, sys
try:
    v = json.load(open(sys.argv[1])).get("remote_match", "(absent)")
except Exception as e:
    v = "(unreadable: %s)" % e.__class__.__name__
print(v)' "$1" 2>/dev/null || printf '(python3 could not run)'
}
_b13r_proj() { mkdir -p "$B13RH/projects/$1"; printf '{\n  "name": "%s",\n  "remote_match": "%s",\n  "gate": "true"\n}\n' "$1" "$2" > "$B13RH/projects/$1/project.json"; }

# ------------------------------- A38-A41: felix new refuses the same repository only ---
_b13r_proj widget Acme/Widget; _b13r_proj lg https://gitlab.example/old/repo
cp "$B13RH/projects/widget/project.json" "$B13R/widget.keep"; cp "$B13RH/projects/lg/project.json" "$B13R/lg.keep"
_b13r_repo gl1 https://gitlab.example/grp/proj.git; _b13r_new "$B13RD" gl1
_b13r_check "A38 (R1) (fixture control): the home holds widget at Acme/Widget and lg at a whole URL an older felix new wrote, and gl1 binds from a GitLab origin with B21's remote_match" \
  "gl1: exit=$B13RRC,marker=$(cat "$B13RD/.felix" 2>/dev/null),remote_match=$(_b13r_rm "$B13RH/projects/gl1/project.json")|widget $(_b13r_rm "$B13RH/projects/widget/project.json")|lg $(_b13r_rm "$B13RH/projects/lg/project.json")" \
  "gl1: exit=0,marker=gl1,remote_match=gitlab.example/grp/proj|widget Acme/Widget|lg https://gitlab.example/old/repo" "$(_b13r_why)"
B13R_G=""; B13R_WHY=""
for B13R_I in 1 2 3 4 5; do
  case "$B13R_I" in
    1) B13R_N=widget-api; B13R_U='https://github.com/Acme/Widget-api.git'; B13R_W='Acme/Widget-api' ;;
    2) B13R_N=widget2; B13R_U='git@github.com:Acme/Widget2.git'; B13R_W='Acme/Widget2' ;;
    3) B13R_N=notacme; B13R_U='https://github.com/NotAcme/Widget.git'; B13R_W='NotAcme/Widget' ;;
    4) B13R_N=gldocs; B13R_U='https://gitlab.example/grp/proj-docs.git'; B13R_W='gitlab.example/grp/proj-docs' ;;
    *) B13R_N=lgtwo; B13R_U='https://gitlab.example/old/repo-two.git'; B13R_W='gitlab.example/old/repo-two' ;;
  esac
  _b13r_repo "$B13R_N" "$B13R_U"; _b13r_new "$B13RD" "$B13R_N"; B13R_R="$(_b13r_rm "$B13RH/projects/$B13R_N/project.json")"
  [ "$B13RRC" = 0 ] || B13R_WHY="$B13R_WHY $B13R_N: $(_b13r_why);"
  if [ "$B13R_R" = "$B13R_W" ]; then B13R_R="remote_match $B13R_W"; else B13R_R="remote_match not $B13R_W: $B13R_R"; fi
  B13R_G="$B13R_G $B13R_N: exit=$B13RRC,marker=$(cat "$B13RD/.felix" 2>/dev/null),projects $(_b13r_ex "$B13RH/projects/$B13R_N"),$B13R_R,governed $(_b13r_has "$(cat "$B13R/err")" 'already governed'),which $(_b13r_project "$B13RD");"
done
B13R_V="widget $(cmp -s "$B13RH/projects/widget/project.json" "$B13R/widget.keep" && echo kept || echo changed)|lg $(cmp -s "$B13RH/projects/lg/project.json" "$B13R/lg.keep" && echo kept || echo changed)"
_b13r_check "A39 (R1): a separate repository whose origin merely contains another project's remote_match (Widget-api, Widget2, NotAcme/Widget, grp/proj-docs, old/repo-two) binds as a fresh checkout does, and the other project is untouched" \
  "$B13R_G|$B13R_V" \
  " widget-api: exit=0,marker=widget-api,projects present,remote_match Acme/Widget-api,governed no,which widget-api; widget2: exit=0,marker=widget2,projects present,remote_match Acme/Widget2,governed no,which widget2; notacme: exit=0,marker=notacme,projects present,remote_match NotAcme/Widget,governed no,which notacme; gldocs: exit=0,marker=gldocs,projects present,remote_match gitlab.example/grp/proj-docs,governed no,which gldocs; lgtwo: exit=0,marker=lgtwo,projects present,remote_match gitlab.example/old/repo-two,governed no,which lgtwo;|widget kept|lg kept" \
  "${B13R_WHY:-every run exited 0}"
: > "$B13R/refused.all"; B13R_G=""; B13R_P=""
for B13R_I in 1 2 3 4; do
  case "$B13R_I" in
    1) B13R_N=wssh; B13R_U='git@github.com:Acme/Widget.git'; B13R_X=widget ;;
    2) B13R_N=wtok; B13R_U='https://x-access-token:SECRETTOKEN@github.com/Acme/Widget.git'; B13R_X=widget ;;
    3) B13R_N=gltok; B13R_U='https://user:SECRETTOKEN@gitlab.example/grp/proj.git'; B13R_X=gl1 ;;
    *) B13R_N=lgsame; B13R_U='https://gitlab.example/old/repo.git'; B13R_X=lg ;;
  esac
  _b13r_repo "$B13R_N" "$B13R_U"; _b13r_new "$B13RD" "$B13R_N"; B13R_E="$(cat "$B13R/err")"
  cat "$B13R/out" "$B13R/err" >> "$B13R/refused.all"
  B13R_G="$B13R_G $B13R_N: exit=$B13RRC,$(_b13r_has "$B13R_E" "already governed by $B13R_X"),$(_b13r_has "$B13R_E" remote_match),marker $(_b13r_ex "$B13RD/.felix"),projects $(_b13r_ex "$B13RH/projects/$B13R_N"),memory $(_b13r_ex "$B13RM/$B13R_N");"
  B13R_P="$B13R_P $B13R_N: names $B13R_X's project.json $(_b13r_has "$B13R_E" "$B13RH/projects/$B13R_X/project.json");"
done
_b13r_check "A40 (R1; control): an origin naming the same repository as a project's remote_match is still refused: two GitHub spellings of Acme/Widget, a token-bearing GitLab URL of gl1's repository, and the repository of lg's whole-URL value" \
  "$B13R_G" \
  " wssh: exit=1,yes,yes,marker absent,projects absent,memory absent; wtok: exit=1,yes,yes,marker absent,projects absent,memory absent; gltok: exit=1,yes,yes,marker absent,projects absent,memory absent; lgsame: exit=1,yes,yes,marker absent,projects absent,memory absent;" \
  "$(tr '\n' ' ' < "$B13R/refused.all" | head -c 900)"
B13R_S="$( { cat "$B13R/refused.all"; for B13R_F in "$B13RH"/projects/*/project.json; do [ -f "$B13R_F" ] && cat "$B13R_F"; done; } | LC_ALL=C awk 'index($0, "SECRETTOKEN") || index($0, "user:") || index($0, "x-access-token") { n++ } END { print n + 0 }')"
_b13r_check "A41 (R1): each such refusal names the project.json whose remote_match binds the checkout, and no refusal and no project.json carries the origin's userinfo" \
  "$B13R_P|credential lines $B13R_S" \
  " wssh: names widget's project.json yes; wtok: names widget's project.json yes; gltok: names gl1's project.json yes; lgsame: names lg's project.json yes;|credential lines 0" \
  "$(tr '\n' ' ' < "$B13R/refused.all" | head -c 900)"

# -------------------------- A42-A44: which repository answers felix install for its source ---
B13RI="$B13R/inst"; B13RIH="$B13RI/home"; B13RIC="$B13RIH/.claude/plugins/cache/felix/felix/0.49.9"
B13RICB="$B13RI/claude"; B13RICBL="$B13RI/claude.log"; B13RIRC=0
mkdir -p "$B13RIH/.claude/plugins" "$B13RIC/.claude-plugin" "$B13RICB" "$B13RI/keep"
cp -R "$FROOT/harness" "$B13RIC/harness"
printf '{\n  "name": "felix",\n  "version": "0.49.9"\n}\n' > "$B13RIC/.claude-plugin/plugin.json"
cat > "$B13RICB/claude" <<B13RCLAUDE
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$B13RICBL"
case "\$*" in
  "plugin list --json") printf '{ "felix@felix": { "installPath": "%s" } }\n' "$B13RIC" ;;
  "plugin marketplace add "*) [ -f "\$4/.claude-plugin/marketplace.json" ] || exit 1 ;;
esac
exit 0
B13RCLAUDE
chmod +x "$B13RICB/claude"
_b13r_src() {   # DIR: an install source holding the engine, its plugin.json and marketplace.json
  mkdir -p "$1/engine/.claude-plugin" "$1/.claude-plugin"
  cp -R "$FROOT/harness" "$1/engine/harness"
  printf '{\n  "name": "felix",\n  "version": "0.49.9"\n}\n' > "$1/engine/.claude-plugin/plugin.json"
  printf '{\n  "name": "felix",\n  "plugins": [ { "name": "felix", "source": "./engine" } ]\n}\n' > "$1/.claude-plugin/marketplace.json"
}
_b13r_parent() {   # DIR GITIGNORE: a git work tree with one commit of a dotfile and that .gitignore
  mkdir -p "$1"; printf 'dotfiles\n' > "$1/.bashrc"; printf '%s\n' "$2" > "$1/.gitignore"
  ( _fx_cd "$1" && git init -q -b main && git -c core.excludesFile=/dev/null add -f .bashrc .gitignore \
    && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c maintenance.auto=false commit -qm dotfiles ) >/dev/null 2>&1
}
_b13r_inst() {   # SRC ARGS...: felix install from the cache entry against SRC, as 0630 runs it; B13RIRC and $B13RI/out, both streams
  local s="$1"; shift; : > "$B13RICBL"
  ( cd "$s" && HOME="$B13RIH" FELIX_HOME="$s" PATH="$B13RICB:$PATH" "$B13RIC/harness/felix" install "$@" ) > "$B13RI/out" 2>&1
  B13RIRC=$?
}
_b13r_calls() { if [ -s "$B13RICBL" ]; then _b13r_count "$B13RICBL"; else printf '0'; fi; }
_b13r_plugin() { if cmp -s "$1/engine/.claude-plugin/plugin.json" "$B13RI/keep/$2"; then printf 'same'; else printf 'changed'; fi; }   # SRC KEEPNAME
_b13r_unknown() { LC_ALL=C awk 'index($0, "could not ask git") && index($0, "engine/") { n++ } END { print n + 0 }' "$B13RI/out"; }
_b13r_top() { (cd "$(git -C "$1" rev-parse --show-toplevel 2>/dev/null || echo /nonexistent)" 2>/dev/null && pwd -P) || printf '(no work tree)'; }
_b13r_tracks() { if [ -n "$(git -C "$1" ls-files -- engine/.claude-plugin/plugin.json 2>/dev/null)" ]; then printf 'tracked'; else printf 'untracked'; fi; }
B13RS0="$B13RI/plain/felix"; mkdir -p "$B13RI/plain"; _b13r_src "$B13RS0"
_b13r_parent "$B13RI/p1" '*.swp'; B13RS1="$B13RI/p1/src/felix"; _b13r_src "$B13RS1"
_b13r_parent "$B13RI/p2" '*'; B13RS2="$B13RI/p2/src/felix"; _b13r_src "$B13RS2"
B13RS3="$B13RI/p3/vendor/felix"; mkdir -p "$B13RI/p3/vendor"; _b13r_src "$B13RS3"
( _fx_cd "$B13RI/p3" && git init -q -b main && git -c core.excludesFile=/dev/null add -A \
  && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c maintenance.auto=false commit -qm vendored ) >/dev/null 2>&1
for B13R_K in 1 2 3; do
  if [ "$B13R_K" = 1 ]; then B13R_D="$B13RS1"; elif [ "$B13R_K" = 2 ]; then B13R_D="$B13RS2"; else B13R_D="$B13RS3"; fi
  cp "$B13R_D/engine/.claude-plugin/plugin.json" "$B13RI/keep/s$B13R_K"
done
B13R_V3="$(git -C "$B13RS3" ls-files --others --directory -- engine/ 2>/dev/null | LC_ALL=C awk 'NF { n++ } END { print n + 0 }')"
printf 'Finder\n' > "$B13RS3/engine/.DS_Store"
B13R_P3="$(git -C "$B13RS3" ls-files --others --directory -- engine/ 2>/dev/null)"
_b13r_inst "$B13RS0" --no-bump; B13R_C0="$(_b13r_calls)"; B13R_O0="exit=$B13RIRC,unknown=$(_b13r_unknown),claude $([ "$B13R_C0" != 0 ] && echo some || echo none)"
B13R_W0="$(tr '\n' ' ' < "$B13RI/out" | head -c 500)"
B13R_T1="$(cd "$B13RI/p1" && pwd -P)"; B13R_T2="$(cd "$B13RI/p2" && pwd -P)"; B13R_T3="$(cd "$B13RI/p3" && pwd -P)"
B13R_G="s0 $(git -C "$B13RS0" rev-parse --is-inside-work-tree >/dev/null 2>&1 && echo in-git || echo outside-git): $B13R_O0"
B13R_G="$B13R_G|s1 top=$([ "$(_b13r_top "$B13RS1")" = "$B13R_T1" ] && echo parent || _b13r_top "$B13RS1"),$(_b13r_tracks "$B13RS1")"
B13R_G="$B13R_G|s2 top=$([ "$(_b13r_top "$B13RS2")" = "$B13R_T2" ] && echo parent || _b13r_top "$B13RS2"),$(_b13r_tracks "$B13RS2"),$(git -C "$B13RS2" check-ignore -q engine/.claude-plugin/plugin.json 2>/dev/null && echo ignored || echo not-ignored)"
B13R_G="$B13R_G|s3 top=$([ "$(_b13r_top "$B13RS3")" = "$B13R_T3" ] && echo parent || _b13r_top "$B13RS3"),$(_b13r_tracks "$B13RS3"),strays before $B13R_V3,after [$B13R_P3]"
_b13r_check "A42 (R2) (fixture control): a source outside git installs with B25's line and some claude commands; two sources sit in parent work trees (one untracked there, one ignored by *) that do not track their engine; a vendored source's engine is tracked by its parent, which lists only the stray .DS_Store" \
  "$B13R_G" "s0 outside-git: exit=0,unknown=1,claude some|s1 top=parent,untracked|s2 top=parent,untracked,ignored|s3 top=parent,tracked,strays before 0,after [engine/.DS_Store]" "$B13R_W0"
B13R_G=""; B13R_WHY=""
for B13R_K in 1 2; do
  if [ "$B13R_K" = 1 ]; then B13R_D="$B13RS1"; else B13R_D="$B13RS2"; fi
  _b13r_inst "$B13R_D" --no-bump; B13R_O="$(cat "$B13RI/out")"; B13R_C="$(_b13r_calls)"
  if [ "$B13R_C" = "$B13R_C0" ]; then B13R_C="as-outside-git"; else B13R_C="$B13R_C not $B13R_C0"; fi
  B13R_G="$B13R_G s$B13R_K: exit=$B13RIRC,unknown=$(_b13r_unknown),verified $(_b13r_has "$B13R_O" 'checked    the installed engine matches this tree'),untracked words $(_b13r_has "$B13R_O" 'git does not track'),remedy $(_b13r_has "$B13R_O" 'Remove them'),plugin $(_b13r_plugin "$B13R_D" "s$B13R_K"),claude $B13R_C;"
  B13R_WHY="$B13R_WHY s$B13R_K: $(tr '\n' ' ' < "$B13RI/out" | head -c 500);"
done
_b13r_check "A43 (R2): a source that is not its own repository, inside another work tree that tracks none of its engine (untracked there, or ignored), installs as a source outside git does: exit 0, one could-not-ask-git line, verified, no refusal or remedy, plugin.json kept, the same claude commands" \
  "$B13R_G" \
  " s1: exit=0,unknown=1,verified yes,untracked words no,remedy no,plugin same,claude as-outside-git; s2: exit=0,unknown=1,verified yes,untracked words no,remedy no,plugin same,claude as-outside-git;" "$B13R_WHY"
_b13r_inst "$B13RS3" --no-bump; B13R_O="$(cat "$B13RI/out")"; B13R_L="$(LC_ALL=C awk 'END { print }' "$B13RI/out")"
_b13r_check "A44 (R2; control): a source whose engine its parent repository tracks is still asked: a stray engine/.DS_Store there is refused with exit 1 before any claude command, counted, and named first on the last line as git names it" \
  "exit=$B13RIRC,claude=$(_b13r_calls),plugin $(_b13r_plugin "$B13RS3" s3),count $(_b13r_has "$B13R_O" 'engine/ holds 1 path(s) git does not track'),last $(_b13r_has "$B13R_L" "the first is $B13R_P3")" \
  "exit=1,claude=0,plugin same,count yes,last yes" "$(tr '\n' ' ' < "$B13RI/out" | head -c 600)"

rm -rf "$B13R"
