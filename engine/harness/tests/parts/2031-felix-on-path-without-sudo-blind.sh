printf '\nfelix on PATH without sudo: the link line felix install prints (audit b21, A27-A42, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b21-readme-claims-match-the-engine.md
# alone (B21-B26, asserted as A27-A42), before felix install was changed, without reading
# engine/harness/felix: it is run as a black box. C099: the end of every felix install said
# `ln -s <path> /usr/local/bin/felix`, which an admin user cannot write on a stock Mac (root:wheel 755),
# and from an engine path holding a space `ln` was handed three arguments. Part 2030 holds the README's
# half of C099 and the other three defects.
#
# Fixture I, as section 4 gives it: S, an engine checkout of its own (its harness copied from the
# fixture's, tests left out, a plugin.json at 0.49.9 and a marketplace.json whose plugin felix has the
# source ./engine); C, a claude stub that exits 0 for anything and prints [] for `plugin list --json`;
# and four runs of `( cd SRC && HOME=<home> FELIX_HOME=SRC PATH=<path> SRC/engine/harness/felix install
# --no-bump )`, stdout and stderr together:
#   R1  home H, fresh                                  path C:$PATH
#   R2  source S2 at "$TMP/b21 src/S2", home "$TMP/b21 home/H2s" (both hold a space), path C:$PATH
#   R3  home H3 holding .local/bin/felix, a link to X (H3/other-felix)   path H3/.local/bin:C:$PATH
#   R4  home H4 whose .local is a regular file          path H4/.local/bin/:C:$PATH
# What each run leaves under its home is read before any printed line is run (A41). A printed line is
# run only after B20's guard holds: no ; | > < backtick $( sudo or `rm `, and every word that begins
# with / after its quotes are stripped lies at or below $TMP's logical or physical path. It is run as
# `( cd <a fresh directory under $TMP> && HOME=<the run's home> bash -c "$line" )`, so it writes only
# fixtures. Every name is emitted on every run.
#
# Readings, where the contract leaves room. "That line" is the run's one `ln -s` line: a run that
# printed none or several fails A29-A31 and every assertion that runs its line, naming the count. A30's
# blank-separated words are the raw line's, split on spaces and tabs. A36's "writes to stderr" is a
# non-empty stderr. A37 and A38 take the first output line holding both `export PATH=` and `.local/bin`,
# and read the PATH from the last line the bash -c prints. A41 reads R3's .local as a listing, the same
# before and after, with the link still naming X. A42's last non-empty line is the last of length > 0.

_b21i="$TMP/b21-inst"; _b21i_d="$_b21i/out"; mkdir -p "$_b21i_d"
_b21i_tp="$(cd "$TMP" && pwd -P)"

# ---- fixture I
_b21i_S="$_b21i/S"
mkdir -p "$_b21i_S/engine/harness" "$_b21i_S/engine/.claude-plugin" "$_b21i_S/.claude-plugin"
for _b21i_f in "$FROOT/harness"/*; do
  case "${_b21i_f##*/}" in tests) ;; *) cp -R "$_b21i_f" "$_b21i_S/engine/harness/" ;; esac
done
printf '{"name": "felix", "version": "0.49.9"}\n' > "$_b21i_S/engine/.claude-plugin/plugin.json"
printf '{"name": "felix", "plugins": [ { "name": "felix", "source": "./engine" } ]}\n' > "$_b21i_S/.claude-plugin/marketplace.json"
_b21i_S2="$TMP/b21 src/S2"; mkdir -p "$TMP/b21 src"; cp -R "$_b21i_S" "$_b21i_S2"
_b21i_C="$_b21i/C"; mkdir -p "$_b21i_C"
cat > "$_b21i_C/claude" <<'B21CLAUDESTUB'
#!/bin/sh
case "$*" in "plugin list --json") printf '[]\n' ;; esac
exit 0
B21CLAUDESTUB
chmod +x "$_b21i_C/claude"
_b21i_H="$_b21i/H"; mkdir -p "$_b21i_H"
_b21i_H2="$TMP/b21 home/H2s"; mkdir -p "$_b21i_H2"
_b21i_H3="$_b21i/H3"; _b21i_X="$_b21i_H3/other-felix"; mkdir -p "$_b21i_H3/.local/bin"
printf 'another felix\n' > "$_b21i_X"; ln -s "$_b21i_X" "$_b21i_H3/.local/bin/felix"
_b21i_H4="$_b21i/H4"; mkdir -p "$_b21i_H4"; printf 'not a directory\n' > "$_b21i_H4/.local"
_b21i_ls() { ( cd "$1" && find . | LC_ALL=C sort ) 2>&1; }
_b21i_ls3="$(_b21i_ls "$_b21i_H3/.local")"

# TAG SRC HOME PATH: one felix install, its output in TAG.out; its status.
_b21i_run() { ( cd "$2" && HOME="$3" FELIX_HOME="$2" PATH="$4" "$2/engine/harness/felix" install --no-bump ) > "$_b21i_d/$1.out" 2>&1; }
# What felix install itself left under each home's .local, read before any printed line runs (A41).
_b21i_p41=""
_b21i_run R1 "$_b21i_S" "$_b21i_H" "$_b21i_C:$PATH"; _b21i_r1=$?
{ [ -e "$_b21i_H/.local" ] || [ -L "$_b21i_H/.local" ]; } && _b21i_p41="$_b21i_p41 R1 made $(_b21i_ls "$_b21i_H/.local" | tr '\n' ' ');"
_b21i_run R2 "$_b21i_S2" "$_b21i_H2" "$_b21i_C:$PATH"; _b21i_r2=$?
{ [ -e "$_b21i_H2/.local" ] || [ -L "$_b21i_H2/.local" ]; } && _b21i_p41="$_b21i_p41 R2 made $(_b21i_ls "$_b21i_H2/.local" | tr '\n' ' ');"
_b21i_run R3 "$_b21i_S" "$_b21i_H3" "$_b21i_H3/.local/bin:$_b21i_C:$PATH"; _b21i_r3=$?
_b21i_ls3b="$(_b21i_ls "$_b21i_H3/.local")"
[ "$_b21i_ls3b" = "$_b21i_ls3" ] || _b21i_p41="$_b21i_p41 R3 left .local as [$(printf '%s' "$_b21i_ls3b" | tr '\n' ' ')], not [$(printf '%s' "$_b21i_ls3" | tr '\n' ' ')];"
[ "$(readlink "$_b21i_H3/.local/bin/felix" 2>&1)" = "$_b21i_X" ] || _b21i_p41="$_b21i_p41 R3 left the link at [$(readlink "$_b21i_H3/.local/bin/felix" 2>&1)];"
_b21i_run R4 "$_b21i_S" "$_b21i_H4" "$_b21i_H4/.local/bin/:$_b21i_C:$PATH"; _b21i_r4=$?
{ [ -f "$_b21i_H4/.local" ] && [ ! -L "$_b21i_H4/.local" ]; } || _b21i_p41="$_b21i_p41 R4 left .local as [$(ls -ld "$_b21i_H4/.local" 2>&1)];"

# RUN -> the run's one ln -s line, status 0; or why there is not one, status 1.
_b21i_one() {
  local n; n="$(LC_ALL=C grep -c -F 'ln -s' "$_b21i_d/$1.out")"
  if [ "$n" = 1 ]; then LC_ALL=C grep -F 'ln -s' "$_b21i_d/$1.out"; return 0; fi
  printf '%s printed %s lines holding ln -s: [%s]\n' "$1" "${n:-an unread number of}" "$(cat "$_b21i_d/$1.out" 2>&1)"; return 1
}
# LINE -> ok, or why it may not be run: the guard of B20.
_b21i_guard() {
  local l="$1" w why="" IFS=$' \t'
  case "$l" in *';'*|*'|'*|*'>'*|*'<'*|*'`'*|*'$('*|*sudo*|*'rm '*)
    printf 'refused, it holds one of ; | > < a backtick $( sudo or rm: [%s]\n' "$l"; return 0 ;; esac
  set -f
  for w in $l; do
    w="${w//\"/}"; w="${w//\'/}"
    case "$w" in /*) case "$w" in "$TMP"|"$TMP"/*|"$_b21i_tp"|"$_b21i_tp"/*) ;; *) why="$w"; break ;; esac ;; esac
  done
  set +f
  if [ -n "$why" ]; then printf 'refused, %s lies outside the fixture: [%s]\n' "$why" "$l"; else printf 'ok\n'; fi
}
# LINE -> its blank-separated words that begin with - and hold f, or nothing.
_b21i_forces() {
  local w out="" IFS=$' \t'
  set -f; for w in $1; do case "$w" in -*f*) out="$out $w" ;; esac; done; set +f
  printf '%s' "$out"
}
# TAG HOME LINE: LINE run from a fresh directory with HOME; stdout in TAG.lo, stderr in TAG.le; its status.
_b21i_try() {
  mkdir -p "$_b21i/cwd-$1"
  ( cd "$_b21i/cwd-$1" && HOME="$2" bash -c "$3" ) > "$_b21i_d/$1.lo" 2> "$_b21i_d/$1.le"
}

# ---- B26 and B21, over the four runs
_b21i_n27="felix on PATH without sudo, A27: felix install exits 0 in each of the four homes"
if [ "$_b21i_r1$_b21i_r2$_b21i_r3$_b21i_r4" = 0000 ]; then ok "$_b21i_n27"
else
  _b21i_v=""; for _b21i_t in R1 R2 R3 R4; do _b21i_v="$_b21i_v; $_b21i_t said [$(cat "$_b21i_d/$_b21i_t.out" 2>&1)]"; done
  bad "$_b21i_n27" "R1 $_b21i_r1, R2 $_b21i_r2, R3 $_b21i_r3, R4 $_b21i_r4$_b21i_v"
fi
_b21i_p28=""; _b21i_p29=""; _b21i_p30=""; _b21i_p31=""
for _b21i_t in R1 R2 R3 R4; do
  if ! _b21i_l="$(_b21i_one "$_b21i_t")"; then
    _b21i_p28="$_b21i_p28 $_b21i_l"; _b21i_p29="$_b21i_p29 $_b21i_l"; _b21i_p30="$_b21i_p30 $_b21i_l"; _b21i_p31="$_b21i_p31 $_b21i_l"
    continue
  fi
  case "$_b21i_l" in *'/usr/local'*) _b21i_p29="$_b21i_p29 $_b21i_t names /usr/local: [$_b21i_l];" ;; esac
  case "$_b21i_l" in *'mkdir -p'*) ;; *) _b21i_p29="$_b21i_p29 $_b21i_t holds no mkdir -p: [$_b21i_l];" ;; esac
  case "$_b21i_l" in *'.local/bin/felix'*) ;; *) _b21i_p29="$_b21i_p29 $_b21i_t names no .local/bin/felix: [$_b21i_l];" ;; esac
  _b21i_w="$(_b21i_forces "$_b21i_l")"
  [ -z "$_b21i_w" ] || _b21i_p30="$_b21i_p30 $_b21i_t forces with$_b21i_w: [$_b21i_l];"
  _b21i_g="$(_b21i_guard "$_b21i_l")"
  [ "$_b21i_g" = ok ] || _b21i_p31="$_b21i_p31 $_b21i_t $_b21i_g;"
done
_b21i_say() { if [ -z "$2" ]; then ok "$1"; else bad "$1" "${2# }"; fi; }
_b21i_say "felix on PATH without sudo, A28: each run prints exactly one ln -s line" "$_b21i_p28"
_b21i_say "felix on PATH without sudo, A29: the line names no /usr/local, and links .local/bin/felix after mkdir -p" "$_b21i_p29"
_b21i_say "felix on PATH without sudo, A30: the line forces over nothing" "$_b21i_p30"
_b21i_say "felix on PATH without sudo, A31: every absolute path in the line lies inside the fixture" "$_b21i_p31"

# ---- B22 and B23: the line, run
# NAME RUN TAG HOME SRC: RUN's line, guarded, run with HOME; it must exit 0 and leave a link -ef SRC's felix.
_b21i_works() {
  local l g rc
  l="$(_b21i_one "$2")" || { bad "$1" "$l"; return 0; }
  g="$(_b21i_guard "$l")"; [ "$g" = ok ] || { bad "$1" "$g"; return 0; }
  _b21i_try "$3" "$4" "$l"; rc=$?
  if [ "$rc" -eq 0 ] && [ -L "$4/.local/bin/felix" ] && [ "$4/.local/bin/felix" -ef "$5/engine/harness/felix" ]; then ok "$1"
  else bad "$1" "[$l] exited $rc, said [$(cat "$_b21i_d/$3.le")], and left [$(ls -ld "$4/.local/bin/felix" 2>&1)]"; fi
}
_b21i_works "felix on PATH without sudo, A32: run, the line links felix into the home" R1 a32 "$_b21i_H" "$_b21i_S"
_b21i_works "felix on PATH without sudo, A33: from a source path and into a home that each hold a space, the line still works" R2 a33 "$_b21i_H2" "$_b21i_S2"
# RUN TAG HOME: RUN's line, guarded, run with HOME; prints its status, or why it was not run.
_b21i_fails() {
  local l g
  l="$(_b21i_one "$1")" || { printf 'not run: %s\n' "$l"; return 0; }
  g="$(_b21i_guard "$l")"; [ "$g" = ok ] || { printf 'not run: %s\n' "$g"; return 0; }
  _b21i_try "$2" "$3" "$l"; printf 'exit %s\n' "$?"
}
_b21i_n34="felix on PATH without sudo, A34: run twice, it fails the second time and keeps the first link"
_b21i_v="$(_b21i_fails R1 a34 "$_b21i_H")"
case "$_b21i_v" in
  'exit 0'|'not run:'*) bad "$_b21i_n34" "$_b21i_v" ;;
  *) if [ "$_b21i_H/.local/bin/felix" -ef "$_b21i_S/engine/harness/felix" ]; then ok "$_b21i_n34"
     else bad "$_b21i_n34" "$_b21i_v, and the link is now [$(ls -ld "$_b21i_H/.local/bin/felix" 2>&1)]"; fi ;;
esac
_b21i_n35="felix on PATH without sudo, A35: a felix link to another file is kept, and the line fails"
_b21i_v="$(_b21i_fails R3 a35 "$_b21i_H3")"
case "$_b21i_v" in
  'exit 0'|'not run:'*) bad "$_b21i_n35" "$_b21i_v" ;;
  *) if [ "$(readlink "$_b21i_H3/.local/bin/felix" 2>&1)" = "$_b21i_X" ]; then ok "$_b21i_n35"
     else bad "$_b21i_n35" "$_b21i_v, and the link now names [$(readlink "$_b21i_H3/.local/bin/felix" 2>&1)]"; fi ;;
esac
_b21i_n36="felix on PATH without sudo, A36: where ~/.local is a file, the line fails aloud and creates nothing"
_b21i_v="$(_b21i_fails R4 a36 "$_b21i_H4")"
case "$_b21i_v" in
  'exit 0'|'not run:'*) bad "$_b21i_n36" "$_b21i_v" ;;
  *) if [ -s "$_b21i_d/a36.le" ] && [ -f "$_b21i_H4/.local" ] && [ ! -L "$_b21i_H4/.local" ] \
        && [ ! -e "$_b21i_H4/.local/bin" ] && [ ! -L "$_b21i_H4/.local/bin" ]; then ok "$_b21i_n36"
     else bad "$_b21i_n36" "$_b21i_v, stderr [$(cat "$_b21i_d/a36.le" 2>&1)], .local [$(ls -ld "$_b21i_H4/.local" 2>&1)]"; fi ;;
esac

# ---- B24 and B25: PATH advice
# NAME RUN HOME: RUN printed an export PATH= line that, run with HOME and PATH=/usr/bin:/bin, adds HOME/.local/bin.
_b21i_adds() {
  local l t p
  l="$(LC_ALL=C awk 'index($0, "export PATH=") && index($0, ".local/bin") { print; exit }' "$_b21i_d/$2.out")"
  [ -n "$l" ] || { bad "$1" "no line of $2's output holds export PATH= and .local/bin: [$(cat "$_b21i_d/$2.out" 2>&1)]"; return 0; }
  t="export PATH=${l#*export PATH=}"
  case "$t" in *';'*|*'|'*|*'&'*|*'<'*|*'>'*|*'`'*|*'$('*)
    bad "$1" "refused, it holds one of ; | & < > a backtick \$(: [$t]"; return 0 ;; esac
  p="$(HOME="$3" PATH=/usr/bin:/bin bash -c "$t; printf '%s\n' \"\$PATH\"" 2>&1)"
  p="${p##*$'\n'}"
  case ":$p:" in *":$3/.local/bin:"*) ;; *) bad "$1" "[$t] gave PATH [$p], without $3/.local/bin"; return 0 ;; esac
  case ":$p:" in *":/usr/bin:"*) ;; *) bad "$1" "[$t] gave PATH [$p], without /usr/bin"; return 0 ;; esac
  case ":$p:" in *":/bin:"*) ;; *) bad "$1" "[$t] gave PATH [$p], without /bin"; return 0 ;; esac
  ok "$1"
}
_b21i_adds "felix on PATH without sudo, A37: with ~/.local/bin off PATH, it prints an export PATH= line that adds it" R1 "$_b21i_H"
_b21i_adds "felix on PATH without sudo, A38: with ~/.local/bin off PATH and a home holding a space, it prints an export PATH= line that adds it" R2 "$_b21i_H2"
# NAME RUN STATUS: RUN exited 0, printed one ln -s line and no export PATH= line.
_b21i_quiet() {
  local c
  [ "$3" = 0 ] || { bad "$1" "$2 exited $3: [$(cat "$_b21i_d/$2.out" 2>&1)]"; return 0; }
  c="$(LC_ALL=C grep -c -F 'ln -s' "$_b21i_d/$2.out")"
  [ "$c" = 1 ] || { bad "$1" "$2 printed ${c:-an unread number of} lines holding ln -s"; return 0; }
  c="$(LC_ALL=C grep -c -F 'export PATH=' "$_b21i_d/$2.out")"
  if [ "$c" = 0 ]; then ok "$1"
  else bad "$1" "$2 printed ${c:-an unread number of} export PATH= lines: [$(LC_ALL=C grep -F 'export PATH=' "$_b21i_d/$2.out" 2>&1)]"; fi
}
_b21i_quiet "felix on PATH without sudo, A39: with ~/.local/bin on PATH, it prints no export PATH= line" R3 "$_b21i_r3"
_b21i_quiet "felix on PATH without sudo, A40: with ~/.local/bin/ on PATH, the trailing slash too, it prints no export PATH= line" R4 "$_b21i_r4"

# ---- B26: the rest of felix install is unchanged around the line
_b21i_say "felix on PATH without sudo, A41: felix install itself creates nothing under ~/.local" "$_b21i_p41"
_b21i_p42=""
for _b21i_t in R1 R2 R3 R4; do
  _b21i_l="$(LC_ALL=C awk 'length($0) > 0 { l = $0 } END { print l }' "$_b21i_d/$_b21i_t.out" 2>&1)"
  case "$_b21i_l" in *'felix new <name>'*) ;; *) _b21i_p42="$_b21i_p42 $_b21i_t ends [$_b21i_l];" ;; esac
done
_b21i_say "felix on PATH without sudo, A42: each run's last non-empty line names felix new <name>" "$_b21i_p42"
