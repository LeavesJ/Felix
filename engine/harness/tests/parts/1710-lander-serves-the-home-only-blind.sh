# >>> lander-serves-the-home-only
printf '\nthe lander serves the home only, and off macOS installs nothing (audit b05: C013, C042; B14-B19, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b05-lander-install-guard-and-off-mac-notifie.md
# alone (section 4, A1-A13, fixture F1). lib/green-install.sh, lib/green-tick.sh and the felix CLI were not
# read: felix land and felix help were run as a black box. One assertion per contract item; where the
# contract asks for a fixture control, that is an assertion of its own, named so.
#
# F1 is this part's own home, so it runs alone and in the serial order: a bare origin whose path ends
# github.com/fixture/lgh.git; the home cloned from it, on main, whose pushed commit holds the engine's
# plugin.json (9.0.0) and two projects, lgh (remote_match github.com/fixture/lgh) and other (remote_match
# github.com/fixture/other); $F1/other, a repository of one commit whose origin ends
# github.com/fixture/other.git; $F1/wt, a worktree of the home on branch w. launchctl, gh and osascript are
# stubs first on PATH, each logging its argv; launchctl's print and list exit 113. Every run has a fresh
# HOME, so nothing reaches ~/Library, and its stdout and stderr are kept apart.
F1="$TMP/f1710"; rm -rf "$F1"; mkdir -p "$F1"; F1="$(cd "$F1" && pwd -P)"
F1O="$F1/github.com/fixture/lgh.git"; F1OO="$F1/github.com/fixture/other.git"; F1UID="$(id -u)"
mkdir -p "$F1O" "$F1OO" "$F1/bin" "$F1/bin2" "$F1/mirror" "$F1/log" "$F1/mem"
_f1_put() { mkdir -p "$(dirname "$1")" && sed "s#@F1@#$F1#g" > "$1" && chmod +x "$1"; }
_f1_put "$F1/bin/launchctl" <<'F1STUB'
#!/bin/bash
printf '%s\n' "$*" >> '@F1@/log/launchctl.log'
case "${1:-}" in print|list) exit 113 ;; esac
exit 0
F1STUB
for _f1t in gh osascript; do
  printf '#!/bin/bash\nprintf '"'"'%%s\\n'"'"' "$*" >> '"'"'%s/log/%s.log'"'"'\nexit 0\n' "$F1" "$_f1t" > "$F1/bin/$_f1t"
  chmod +x "$F1/bin/$_f1t"; cp -p "$F1/bin/$_f1t" "$F1/bin2/$_f1t"
done
_fx_git "$F1O" init -q --bare >/dev/null 2>&1; _fx_git "$F1O" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
_fx_git "$F1" clone -q "$F1O" home >/dev/null 2>&1; _fx_git "$F1/home" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
mkdir -p "$F1/home/engine/.claude-plugin" "$F1/home/projects/lgh" "$F1/home/projects/other"
printf '{ "name": "felix", "version": "9.0.0" }\n' > "$F1/home/engine/.claude-plugin/plugin.json"
printf '{\n  "name": "lgh",\n  "remote_match": "github.com/fixture/lgh",\n  "gate": "true"\n}\n' > "$F1/home/projects/lgh/project.json"
printf '{\n  "name": "other",\n  "remote_match": "github.com/fixture/other",\n  "gate": "true"\n}\n' > "$F1/home/projects/other/project.json"
_fx_git "$F1/home" add -A >/dev/null 2>&1
_fx_git "$F1/home" -c user.name=t -c user.email=t@t commit -qm base >/dev/null 2>&1
_fx_git "$F1/home" push -q -u origin main >/dev/null 2>&1
_fx_git "$F1OO" init -q --bare >/dev/null 2>&1; _fx_git "$F1OO" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
mkdir -p "$F1/other"; _fx_git "$F1/other" init -q >/dev/null 2>&1; _fx_git "$F1/other" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
printf 'other\n' > "$F1/other/README.md"; _fx_git "$F1/other" add -A >/dev/null 2>&1
_fx_git "$F1/other" -c user.name=t -c user.email=t@t commit -qm other >/dev/null 2>&1
_fx_git "$F1/other" remote add origin "$F1OO" >/dev/null 2>&1; _fx_git "$F1/other" push -q -u origin main >/dev/null 2>&1
_fx_git "$F1/home" worktree add -q -b w "$F1/wt" main >/dev/null 2>&1
cp -p "$F1/home/projects/lgh/project.json" "$F1/lgh.project.keep"

# The no-launchd PATH: $F1/bin2 (gh and osascript), then $F1/mirror, a symlink to every executable of
# every directory on the caller's PATH, the first of a name winning, but none named launchctl. One ln per
# directory: names are gathered first, each tested with the shell's own [ ].
_f1_mirror() {
  local d f n k IFS=:; local -a t
  for d in $PATH; do
    [ -d "$d" ] || continue
    t=(); k=0
    for f in "$d"/*; do
      n="${f##*/}"
      [ "$n" = launchctl ] && continue
      { [ -x "$f" ] && [ ! -d "$f" ]; } || continue
      { [ -e "$F1/mirror/$n" ] || [ -L "$F1/mirror/$n" ]; } && continue
      t[k]="$f"; k=$((k+1))
    done
    [ "$k" -eq 0 ] || ln -s "${t[@]}" "$F1/mirror/" 2>/dev/null
  done
  return 0
}
_f1_mirror
F1NL="$F1/bin2:$F1/mirror"

_f1_n=0
_f1_land() {   # DIR PATH ARGS... -> felix land ARGS from DIR under PATH; stdout $F1/out, stderr $F1/err, status F1RC, HOME F1U
  local dir="$1" p="$2"; shift 2
  _f1_n=$((_f1_n+1)); F1U="$F1/user.$_f1_n"; mkdir -p "$F1U"
  rm -rf "$F1/log"; mkdir -p "$F1/log"
  ( cd "$dir" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE HOME="$F1U" FELIX_HOME="$F1/home" \
      FELIX_HOME_DIR="$F1/home" FELIX_MEMORY="$F1/mem" PATH="$p" "$FELIX" land "$@" ) > "$F1/out" 2> "$F1/err"
  F1RC=$?
}
_f1_lines() { if [ -f "$1" ]; then LC_ALL=C awk 'END { print NR }' "$1"; else echo 0; fi; }   # FILE -> its line count, 0 when absent
_f1_said() { case "$(cat "$F1/out" "$F1/err" 2>/dev/null)" in *"$1"*) echo said ;; *) echo "not-said" ;; esac; }   # TEXT -> said when out or err holds it
_f1_err() { case "$(cat "$F1/err" 2>/dev/null)" in *"$1"*) echo "$2" ;; *) echo "no-$2" ;; esac; }   # TEXT TAG -> TAG when stderr holds TEXT
_f1_out_empty() { if [ -s "$F1/out" ]; then echo "stdout:[$(head -c 200 "$F1/out")]"; else echo empty; fi; }
_f1_installed() {   # PROJECT -> status, the installed line, plist, trampoline and the bootstrap count of the last run, as A1 reads them
  printf '%s|%s|%s|bootstrap=%s' "$F1RC" "$(_f1_said "land on green is installed for $1")" \
    "$([ -f "$F1U/Library/LaunchAgents/felix.land.$1.plist" ] && echo plist || echo no-plist)$([ -f "$F1U/Library/Application Support/felix/land/$1/tick" ] && echo +tramp || echo +no-tramp)" \
    "$(LC_ALL=C awk '$1 == "bootstrap" { n++ } END { print n + 0 }' "$F1/log/launchctl.log" 2>/dev/null)"
}
_f1_nothing() {   # -> what A3 says was not written for other, of the last run
  printf '%s|%s|launchctl=%s|%s' \
    "$([ -e "$F1U/Library/LaunchAgents/felix.land.other.plist" ] && echo plist || echo no-plist)" \
    "$([ -e "$F1U/Library/Application Support/felix/land/other" ] && echo tramp-dir || echo no-tramp-dir)" \
    "$(_f1_lines "$F1/log/launchctl.log")" "$([ -e "$F1/mem/other/land" ] && echo land-dir || echo no-land-dir)"
}
_f1_mem() { rm -rf "$F1/mem"; mkdir -p "$F1/mem"; }

is "the land fixture F1: the home is on main at its origin's main, other has one commit, and wt is a worktree of the home on w (fixture control)" \
   "$(git -C "$F1/home" rev-parse HEAD 2>&1)|$(git -C "$F1/home" rev-parse --abbrev-ref HEAD 2>&1)|$(git -C "$F1/other" rev-list --count HEAD 2>&1)|$(git -C "$F1/wt" rev-parse --abbrev-ref HEAD 2>&1)" \
   "$(git -C "$F1O" rev-parse main 2>&1)|main|1|w"

# ---------------------------------------------------------------- B16 ---
_f1_mem; _f1_land "$F1/home" "$F1/bin:$PATH" --install
is "A1 (B16, control): --install from the home exits 0, says land on green is installed for lgh, writes felix.land.lgh's plist and its trampoline, and logs one launchctl bootstrap" \
   "$(_f1_installed lgh)" "0|said|plist+tramp|bootstrap=1"
_f1_mem; _f1_land "$F1/wt" "$F1/bin:$PATH" --install
is "A2 (B16, control): --install from a worktree of the home exits 0 and installs felix.land.lgh, as from the home" \
   "$(_f1_installed lgh)" "0|said|plist+tramp|bootstrap=1"

# ---------------------------------------------------------------- B14 ---
_f1_mem; _f1_land "$F1/other" "$F1/bin:$PATH" --install
is "A3 (B14): --install from another governed checkout exits 1, prints nothing on stdout, refuses on stderr naming other and lgh and saying land on green lands the home's own pull requests only, and writes no plist, no trampoline, no land directory and calls no launchctl" \
   "$F1RC|$(_f1_out_empty)|$(_f1_err other other)|$(_f1_err lgh lgh)|$(_f1_err "land on green lands the home's own pull requests only" refusal)|$(_f1_nothing)" \
   "1|empty|other|lgh|refusal|no-plist|no-tramp-dir|launchctl=0|no-land-dir"
_f1_mem; _f1_land "$F1/other" "$F1/bin:$PATH" --pause x
is "A4 (B14): --pause from another governed checkout exits 1 and writes a paused file in neither project's land directory" \
   "$F1RC|$([ -e "$F1/mem/other/land/paused" ] && echo other-paused || echo no-other-paused)|$([ -e "$F1/mem/lgh/land/paused" ] && echo lgh-paused || echo no-lgh-paused)" \
   "1|no-other-paused|no-lgh-paused"
_f1_mem; mkdir -p "$F1/mem/lgh/land"; printf 'held by the home\n' > "$F1/mem/lgh/land/paused"
_f1_land "$F1/other" "$F1/bin:$PATH" --resume
is "A5 (B14): --resume from another governed checkout exits 1 and leaves the home's paused file where it is" \
   "$F1RC|$(cat "$F1/mem/lgh/land/paused" 2>/dev/null)" "1|held by the home"
_f1_mem; _f1_land "$F1/other" "$F1/bin:$PATH" --status; _f1s1="$F1RC|$(_f1_out_empty)"
_f1_land "$F1/other" "$F1/bin:$PATH" --status --tsv
is "A6 (B14): --status and --status --tsv from another governed checkout each exit 1 with nothing on stdout" \
   "$_f1s1|$F1RC|$(_f1_out_empty)" "1|empty|1|empty"
_f1_mem; _f1_land "$F1/other" "$F1/bin:$PATH" --tick
is "A7 (B14): --tick from another governed checkout exits 1, writes no ledger under either project, and asks gh nothing" \
   "$F1RC|ledgers=$(find "$F1/mem" -name ledger.tsv 2>/dev/null | wc -l | tr -d ' ')|gh=$(_f1_lines "$F1/log/gh.log")" "1|ledgers=0|gh=0"

# ---------------------------------------------------------------- B17 ---
_f1_mem; _f1_land "$F1/other" "$F1/bin:$PATH" --uninstall
is "A8 (B17, control): --uninstall from another governed checkout still exits 0, says land on green is uninstalled for other, and boots out gui/<uid>/felix.land.other" \
   "$F1RC|$(_f1_said "land on green is uninstalled for other")|bootout=$(LC_ALL=C awk -v t="bootout gui/$F1UID/felix.land.other" '$0 == t { n++ } END { print n + 0 }' "$F1/log/launchctl.log" 2>/dev/null)" \
   "0|said|bootout=1"
_f1_mem; _f1_land "$F1/other" "$F1/bin:$PATH" --prs --no-gh
is "A9 (B17, control): --prs --no-gh from another governed checkout is not refused as another project's lander" \
   "$(_f1_err "home's own pull requests" refused)" "no-refused"

# ---------------------------------------------------------------- B15 ---
printf '{\n  "name": "lgh",\n  "remote_match": "github.com/fixture/nothing",\n  "gate": "true"\n}\n' > "$F1/home/projects/lgh/project.json"
_f1_mem; _f1_land "$F1/other" "$F1/bin:$PATH" --install
is "A10 (B15): with the home resolving no project, --install from a governed checkout exits 1, says on stderr that the home resolves no project, and writes nothing" \
   "$F1RC|$(_f1_err "resolves no project" resolves-none)|$(_f1_nothing)" "1|resolves-none|no-plist|no-tramp-dir|launchctl=0|no-land-dir"
cp -p "$F1/lgh.project.keep" "$F1/home/projects/lgh/project.json"
is "the land fixture F1: the home's lgh project.json is restored and the home is clean (fixture control)" \
   "$(git -C "$F1/home" status --porcelain 2>&1)" ""

# ---------------------------------------------------------------- B18 ---
is "the land fixture F1: under the no-launchd PATH no launchctl is found and a git is (fixture control)" \
   "$( PATH="$F1NL"; command -v launchctl >/dev/null 2>&1 && printf launchctl; printf '|'; command -v git >/dev/null 2>&1 && printf git )" "|git"
_f1_mem; _f1_land "$F1/home" "$F1NL" --install
is "A11 (B18): --install from the home with no launchctl on PATH exits 1, says launchctl, macOS and nothing was written, and leaves no ~/Library, no land directory and no gh call" \
   "$F1RC|$(_f1_said launchctl)|$(_f1_said macOS)|$(_f1_said "nothing was written")|$([ -e "$F1U/Library" ] && echo library || echo no-library)|$([ -e "$F1/mem/lgh/land" ] && echo land-dir || echo no-land-dir)|gh=$(_f1_lines "$F1/log/gh.log")" \
   "1|said|said|said|no-library|no-land-dir|gh=0"
_f1_mem; _f1_land "$F1/home" "$F1/bin:$F1NL" --install
is "A12 (B18, control): the same install with the stub launchctl first on PATH succeeds as A1 does" \
   "$(_f1_installed lgh)" "0|said|plist+tramp|bootstrap=1"

# ---------------------------------------------------------------- B19 ---
( cd "$F1" && env HOME="$F1/user.help" FELIX_HOME="$F1/home" FELIX_HOME_DIR="$F1/home" FELIX_MEMORY="$F1/mem" \
    PATH="$F1/bin:$PATH" "$FELIX" help ) > "$F1/help" 2>&1
_f1h="$(LC_ALL=C awk 'index($0, "    felix land") == 1 { print; exit }' "$F1/help")"
case "$_f1h" in
  *"macOS only"*) ok "A13 (B19): felix help's felix land line says macOS only" ;;
  *) bad "A13 (B19): felix help's felix land line says macOS only" "the line is [$_f1h]" ;;
esac

rm -rf "$F1"
