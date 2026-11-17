# >>> judge-refs-residue-c
printf '\njudge refs and residue: the whole entry, read raw against main'"'"'s stored blobs (contract C1-C8, not blind)\n'
# Written by the implementer from the review's measured cases (not blind). Each
# case says what the comparison must read or report, with a control beside it
# that shows the fixture does what the case needs. This part builds its own
# home, cache and merge checkout under $TMP and removes them (and its project,
# jrc) at its end. It uses nothing of parts 1400-1402 but the suite's own
# helpers, and defines its own.
#
# The home's main M ships engine/{harness,hooks,commands,.claude-plugin}. E is
# the cache entry for M's 4.0.0, cut from the commit while nothing in the home
# converts anything, so its bytes are M's stored blobs and its modes are M's.
# M's rules are the root's .gitignore (.claude-flow/, *.log, data/).
JC="$TMP/jc"; JCR="$JC/home"; JCC="$JC/cache"; JCV="$JCC/felix/felix"; JCE="$JCV/4.0.0"
mkdir -p "$JCR/engine/harness/lib" "$JCR/engine/harness/tests" "$JCR/engine/hooks" "$JCR/engine/commands" \
         "$JCR/engine/.claude-plugin" "$JCV"
JCR="$(cd "$JCR" && pwd -P)"
printf '.claude-flow/\n*.log\ndata/\n' > "$JCR/.gitignore"
printf 'real\n' > "$JCR/engine/harness/felix"; chmod +x "$JCR/engine/harness/felix"
printf 'x\n' > "$JCR/engine/harness/lib/x.sh"; printf 'suite\n' > "$JCR/engine/harness/tests/run"
printf 'two words\n' > "$JCR/engine/harness/two and words.sh"; printf 'colon\n' > "$JCR/engine/harness/c: d.sh"
printf '{}\n' > "$JCR/engine/hooks/hooks.json"; printf '#!/bin/sh\n' > "$JCR/engine/hooks/run.sh"; chmod +x "$JCR/engine/hooks/run.sh"
printf '# felix\n' > "$JCR/engine/commands/felix.md"
printf '{ "name": "felix", "version": "4.0.0" }\n' > "$JCR/engine/.claude-plugin/plugin.json"
( _fx_cd "$JCR" && git init -q -b main && git add -A \
  && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm main ) >/dev/null 2>&1
JC_M="$(git -C "$JCR" rev-parse --verify -q HEAD 2>/dev/null)"
_fx_git "$JCR" update-ref refs/remotes/origin/main "$JC_M" >/dev/null 2>&1
_jc_sha() { git -C "$JCR" rev-parse --verify -q "$1^{commit}" 2>/dev/null; }
_jc_side() {   # NAME FILE TEXT -> the sha of a commit off M writing FILE, its branch deleted after
  ( _fx_cd "$JCR" && git checkout -q -b "jc-side-$1" "$JC_M" ) >/dev/null 2>&1
  mkdir -p "$(dirname "$JCR/$2")"; printf '%s\n' "$3" > "$JCR/$2"
  ( _fx_cd "$JCR" && git add -f -A && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm "$1" \
    && git checkout -q main ) >/dev/null 2>&1
  _jc_sha "jc-side-$1"; _fx_git "$JCR" branch -q -D "jc-side-$1" >/dev/null 2>&1
}
is "C (fixture control): the home is on main with nothing to report, M ships a file under an executable bit, and refs/remotes/origin/main is M" \
   "$(git -C "$JCR" symbolic-ref --short HEAD 2>&1)|$(git -C "$JCR" status --porcelain 2>&1)|$(git -C "$JCR" ls-files -s engine/harness/felix engine/harness/lib/x.sh | LC_ALL=C cut -c1-6 | tr '\n' ' ')|$(_jc_sha refs/remotes/origin/main)" \
   "main||100755 100644 |$JC_M"

_jc_entry() {   # [SHA] -> E holds the commit's engine, byte for byte and mode for mode (the home converts nothing now)
  rm -rf "$JCE" "$JC/x" "$JC/x.tar"; mkdir -p "$JCE" "$JC/x"
  _fx_git "$JCR" archive -o "$JC/x.tar" "${1:-$JC_M}" engine >/dev/null 2>&1 && tar -x -C "$JC/x" -f "$JC/x.tar"
  for _d in harness hooks commands .claude-plugin; do [ -d "$JC/x/engine/$_d" ] && cp -Rp "$JC/x/engine/$_d" "$JCE/$_d"; done
  rm -rf "$JC/x" "$JC/x.tar"
}
_jc_call() {   # [NAME] -> JCRC and JCO: felix_accepted_deploy_diff on the home, its stdout; the machine's global config is off
  ( unset FELIX_KERNEL_CACHE GIT_CONFIG_GLOBAL; export FELIX_PLUGIN_CACHE="$JCC"
    . "$REAL_HARNESS/lib/resolve.sh" >/dev/null 2>&1
    felix_accepted_deploy_diff "$JCR" "${1:-main}" ) > "$JC/out" 2> "$JC/err" < /dev/null
  JCRC=$?; JCO="$(cat "$JC/out")"
}
_jc_names() {   # REL -> named when JCO names REL: its own path, or an Only in line for it or a directory above it
  local d="" r="$1" c
  case "$JCO" in *"$1"*) printf named; return 0 ;; esac
  while [ -n "$r" ]; do
    c="${r%%/*}"
    [ -z "$d" ] || case "$JCO" in *"$d: $c"*) printf named; return 0 ;; esac
    case "$r" in */*) r="${r#*/}"; d="${d:+$d/}$c" ;; *) r="" ;; esac
  done
}
_jc_has() { case "$JCO" in *"$1"*) printf named ;; esac; }   # TEXT -> named when JCO holds TEXT as it stands
_jc_isentry() {   # -> entry when JCO is one line naming E, physically
  local p e
  case "$JCO" in ""|*$'\n'*) return 0 ;; esac
  p="$(cd -P "$JCO" 2>/dev/null && pwd -P)"; e="$(cd -P "$JCE" 2>/dev/null && pwd -P)"
  [ -n "$p" ] && [ "$p" = "$e" ] && printf entry
}
_jc_ok()  { _jc_call "${2:-main}"; is "$1: the entry exits 0 and prints itself" "$JCRC|$(_jc_isentry)" "0|entry"; }          # NAME [BASE]
_jc_bad() { _jc_call; is "$1: exits 1 and names $2" "$JCRC|$(_jc_names "$2")" "1|named"; }                                    # NAME REL

_jc_entry
_jc_ok "C (fixture control): an entry cut from M with nothing converting"

# ------------------------------------------------------------------- C1 ---
# The review's setup: a smudge command that rewrites a file's content, named by
# * filter=jcf in .git/info/attributes (and again through core.attributesFile),
# an eol conversion, and export-ignore. git archive applies each of them to the
# files it writes out, so an archive of M in this home is not M's blobs. The
# comparison must read M's stored blobs: a faithful entry is accepted whatever
# the home does, and an entry with one changed file is not.
printf '#!/bin/sh\ncat >/dev/null\nprintf "EVIL CODE\\n"\n' > "$JC/smudge.sh"; chmod +x "$JC/smudge.sh"
printf '* filter=jcf\n' > "$JC/attrs-file"
_jc_arcf() {   # REL -> git archive of M in the home for engine/REL, written whole to $JC/arch.tar (not a pipe: R37); no file where git writes none
  rm -f "$JC/arch.tar"; _fx_git "$JCR" archive -o "$JC/arch.tar" "$JC_M" "engine/$1" >/dev/null 2>&1; return 0
}
_jc_arch() {   # REL -> what git archive of M in the home writes for REL: its first line, or "(absent)"
  local o; _jc_arcf "$1"; o="$(tar -xO -f "$JC/arch.tar" 2>/dev/null | LC_ALL=C sed -n 1p | tr -d '\r')"; rm -f "$JC/arch.tar"
  printf '%s' "${o:-(absent)}"
}
_jc_conv() {   # VARIANT on|off -> the home converts (on) or does not (off)
  case "$1:$2" in
    filter-info:on)  _fx_git "$JCR" config filter.jcf.smudge "$JC/smudge.sh" >/dev/null 2>&1; _fx_git "$JCR" config filter.jcf.required false >/dev/null 2>&1
                     printf '* filter=jcf\n' > "$JCR/.git/info/attributes" ;;
    filter-info:off) rm -f "$JCR/.git/info/attributes"; _fx_git "$JCR" config --remove-section filter.jcf >/dev/null 2>&1 ;;
    filter-file:on)  _fx_git "$JCR" config filter.jcf.smudge "$JC/smudge.sh" >/dev/null 2>&1; _fx_git "$JCR" config filter.jcf.required false >/dev/null 2>&1
                     _fx_git "$JCR" config core.attributesFile "$JC/attrs-file" >/dev/null 2>&1 ;;
    filter-file:off) _fx_git "$JCR" config --unset core.attributesFile >/dev/null 2>&1; _fx_git "$JCR" config --remove-section filter.jcf >/dev/null 2>&1 ;;
    eol:on)          printf '* text eol=crlf\n' > "$JCR/.git/info/attributes" ;;
    eol:off)         rm -f "$JCR/.git/info/attributes" ;;
    autocrlf:on)     _fx_git "$JCR" config core.autocrlf true >/dev/null 2>&1; printf '* text\n' > "$JCR/.git/info/attributes" ;;
    autocrlf:off)    _fx_git "$JCR" config --unset core.autocrlf >/dev/null 2>&1; rm -f "$JCR/.git/info/attributes" ;;
    exportignore:on) printf 'engine/harness/lib/x.sh export-ignore\n' > "$JCR/.git/info/attributes" ;;
    exportignore:off) rm -f "$JCR/.git/info/attributes" ;;
  esac
}
for _jc_v in filter-info filter-file eol autocrlf exportignore; do
  _jc_entry; _jc_conv "$_jc_v" on
  case "$_jc_v" in
    filter-*)  is "C1 ($_jc_v) (fixture control): git archive of M in this home writes EVIL CODE for harness/lib/x.sh" "$(_jc_arch harness/lib/x.sh)" "EVIL CODE" ;;
    eol|autocrlf) is "C1 ($_jc_v) (fixture control): git archive of M in this home writes harness/lib/x.sh with a carriage return" \
                     "$(_jc_arcf harness/lib/x.sh; tar -xO -f "$JC/arch.tar" 2>/dev/null | LC_ALL=C grep -c "$(printf '\r')"; rm -f "$JC/arch.tar")" "1" ;;
    exportignore) is "C1 ($_jc_v) (fixture control): git archive of M in this home leaves harness/lib/x.sh out" "$(_jc_arch harness/lib/x.sh)" "(absent)" ;;
  esac
  _jc_ok "C1 ($_jc_v): a faithful entry is accepted"
  case "$_jc_v" in
    filter-*) printf 'EVIL CODE\n' > "$JCE/harness/lib/x.sh" ;;
    eol|autocrlf) printf 'x\r\n' > "$JCE/harness/lib/x.sh" ;;
    *) printf 'changed\n' > "$JCE/harness/lib/x.sh" ;;
  esac
  _jc_bad "C1 ($_jc_v), an entry whose harness/lib/x.sh differs from M's blob (the bytes the home would write)" harness/lib/x.sh
  _jc_conv "$_jc_v" off
done
_jc_entry
is "C1 (fixture control): every conversion is off again, and the faithful entry is accepted" "$(git -C "$JCR" status --porcelain 2>&1)|$(_jc_call; printf '%s' "$JCRC")" "|0"

# ------------------------------------------------------------------- C2 ---
_jc_entry; mkdir -p "$JCE/agents"; printf 'a\n' > "$JCE/agents/a.md"
_jc_bad "C2: an entry that holds a top-level agents/ M does not ship" agents
_jc_entry; printf '{}\n' > "$JCE/.mcp.json"
_jc_bad "C2: an entry that holds a top-level .mcp.json" .mcp.json
_jc_entry; mkdir -p "$JCE/.claude-flow"; printf 'x\n' > "$JCE/.claude-flow/state"
_jc_bad "C2: an entry that holds a top-level .claude-flow/, which M's .claude-flow/ rule matches (residue is only beneath harness/ and hooks/)" .claude-flow
_jc_entry; printf '{ "name": "felix", "version": "4.0.0", "hooks": "evil.json" }\n' > "$JCE/.claude-plugin/plugin.json"
_jc_bad "C2: an entry whose plugin.json gained a hooks field" .claude-plugin/plugin.json
_jc_entry; printf 'x\n' > "$JCE/.claude-plugin/extra.json"
_jc_bad "C2: an entry with an extra file beside plugin.json" .claude-plugin/extra.json
_jc_entry; rm -rf "$JCE/.claude-plugin"
_jc_bad "C2: an entry that lacks .claude-plugin/, which M ships" .claude-plugin
_jc_entry; mkdir -p "$JCE/hooks/.claude-flow"; printf 'x\n' > "$JCE/hooks/.claude-flow/s"; printf 'x\n' > "$JCE/harness/stray.log"
_jc_ok "C2 (control): strays M's rules match, beneath hooks/ and harness/, are residue"

# ------------------------------------------------------------------- C3 ---
_jc_entry; rm -f "$JCE/harness/lib/x.sh"; printf 'x\n' > "$JC/x-copy"; ln -s "$JC/x-copy" "$JCE/harness/lib/x.sh"
_jc_bad "C3: an entry whose harness/lib/x.sh is a symlink to a file with M's very bytes" harness/lib/x.sh
_jc_entry; ln -s lib/x.sh "$JCE/harness/link"
_jc_bad "C3: an entry with a symlink only it holds" harness/link
_jc_entry; mkfifo "$JCE/harness/fifo" 2>/dev/null
_jc_bad "C3: an entry with a FIFO only it holds" harness/fifo
if command -v python3 >/dev/null 2>&1; then
  _jc_entry; ( cd "$JCE/harness" && python3 -c 'import socket; s = socket.socket(socket.AF_UNIX); s.bind("sock")' ) >/dev/null 2>&1
  _jc_bad "C3: an entry with a socket only it holds" harness/sock
else skip "C3: an entry with a socket only it holds" "no python3 to make a socket"; fi
_jc_entry; rm -f "$JCE/harness/lib/x.sh"; mkdir "$JCE/harness/lib/x.sh"
_jc_bad "C3: an entry with a directory where M ships the file harness/lib/x.sh" harness/lib/x.sh
_jc_entry; rm -rf "$JCE/harness/lib"; printf 'x\n' > "$JCE/harness/lib"
_jc_bad "C3: an entry with a file where M ships the directory harness/lib" harness/lib
_jc_entry; chmod -x "$JCE/harness/felix"
_jc_bad "C3: an entry whose harness/felix lost its executable bit (M's mode is 100755)" harness/felix
_jc_entry; chmod +x "$JCE/harness/lib/x.sh"
_jc_bad "C3: an entry whose harness/lib/x.sh gained the executable bit (M's mode is 100644)" harness/lib/x.sh
_jc_entry; _jc_ok "C3 (control): an entry with M's modes everywhere"

# ------------------------------------------------------------------- C4 ---
# Names M's rules (*.log) would match are still drift when they hold a character
# that makes a path ambiguous; a plain name beside them is residue.
_jc_entry; printf 'x\n' > "$JCE/harness/plain.log"
_jc_ok "C4 (control): an entry-only harness/plain.log, which *.log matches, is residue"
for _jc_nm in 'a b and c.log' 'a: b.log' 'a"b.log' 'a*b.log' 'a?b.log' '-dash.log' 'trail.log '; do
  _jc_entry; printf 'x\n' > "$JCE/harness/$_jc_nm"
  _jc_call; is "C4: an entry-only harness/$_jc_nm exits 1 and is named" "$JCRC|$(_jc_has "$_jc_nm")" "1|named"
done
_jc_entry; printf 'x\n' > "$JCE/harness/back\\slash.log"; _jc_call
is "C4: an entry-only name with a backslash exits 1 and is named, the backslash escaped" "$JCRC|$(printf '%s' "$JCO" | LC_ALL=C grep -cF 'back\\slash.log')" "1|1"
_jc_entry; printf 'x\n' > "$JCE/harness/tab$(printf '\t')name.log"; _jc_call
is "C4: an entry-only name with a tab exits 1, and its line is one line with the tab escaped" "$JCRC|$(printf '%s\n' "$JCO" | awk 'END { print NR }')|$(printf '%s' "$JCO" | LC_ALL=C grep -cF 'tab\tname.log')" "1|1|1"
_jc_entry; printf 'x\n' > "$JCE/harness/new$(printf '\nline').log"; _jc_call
is "C4: an entry-only name with a newline exits 1, its line is one line that holds the newline as \\n and cannot be read as two paths" \
   "$JCRC|$(printf '%s\n' "$JCO" | awk 'END { print NR }')|$(printf '%s' "$JCO" | LC_ALL=C grep -cF 'new\nline.log')" "1|1|1"
_jc_entry; printf 'drift\n' >> "$JCE/harness/two and words.sh"
_jc_bad "C4: a differing path whose name holds ' and ' exits 1 and is named whole" "harness/two and words.sh"
_jc_entry; printf 'drift\n' >> "$JCE/harness/c: d.sh"
_jc_bad "C4: a differing path whose name holds ': ' exits 1 and is named whole" "harness/c: d.sh"

# ------------------------------------------------------------------- C5 ---
# A decoy at refs/tags/origin/main, in a commit whose engine/.gitignore is *.
JC_D1="$(_jc_side d1 engine/.gitignore '*')"
_fx_git "$JCR" update-ref refs/tags/origin/main "$JC_D1" >/dev/null 2>&1
is "C5 (fixture control): git's own short name origin/main now names the decoy, whose engine/.gitignore is *" \
   "$(_jc_sha origin/main)|$(git -C "$JCR" show "$JC_D1:engine/.gitignore" 2>&1)" "$JC_D1|*"
_jc_entry; printf 'x\n' > "$JCE/harness/extra"
_jc_bad "C5: with the decoy in place, an entry that is M plus harness/extra" harness/extra
_jc_entry; printf 'x\n' > "$JCE/hooks/extra"
_jc_bad "C5: with the decoy in place, an entry that is M plus hooks/extra" hooks/extra
_jc_entry; _jc_ok "C5 (control): with the decoy in place, an entry equal to M"
_fx_git "$JCR" update-ref -d refs/tags/origin/main >/dev/null 2>&1
# A decoy that declares another version, with an entry for that version present.
JC_D2="$(_jc_side d2 engine/.claude-plugin/plugin.json '{ "name": "felix", "version": "6.6.6" }')"
_fx_git "$JCR" update-ref refs/tags/origin/main "$JC_D2" >/dev/null 2>&1
_jc_entry; rm -rf "$JCV/6.6.6"; cp -Rp "$JCE" "$JCV/6.6.6"; printf 'x\n' > "$JCE/harness/extra"
is "C5 (fixture control): git's own short name origin/main names the decoy, which declares 6.6.6, and the cache holds an entry for it" \
   "$(_jc_sha origin/main)|$(git -C "$JCR" show "$JC_D2:engine/.claude-plugin/plugin.json" 2>&1 | tr -d '\n')|$([ -d "$JCV/6.6.6/harness" ] && echo there)" \
   "$JC_D2|{ \"name\": \"felix\", \"version\": \"6.6.6\" }|there"
_jc_bad "C5: with the decoy in place, the entry for main's 4.0.0 that is M plus harness/extra" harness/extra
_fx_git "$JCR" update-ref -d refs/tags/origin/main >/dev/null 2>&1; rm -rf "$JCV/6.6.6"

# ------------------------------------------------------------------- C6 ---
_jc_entry; printf 'x\n' > "$JCE/harness/data"
_jc_bad "C6: an entry-only FILE harness/data, which M's data/ rule does not match (it names a directory)" harness/data
_jc_entry; mkdir -p "$JCE/harness/data"; printf 'x\n' > "$JCE/harness/data/x"
_jc_ok "C6 (control): an entry-only harness/data/x beneath a directory the data/ rule matches is residue"

# ------------------------------------------------------------------- C7 ---
# A git first on PATH that blocks at the first read of M's engine, after the
# call has made its temporary directory; the signal is sent to the call and to the
# blocked git together, as a terminal sends it to a process group.
JC7="$JC/c7"; mkdir -p "$JC7/bin"
command -v git > "$JC7/realgit"
sed "s|@D@|$JC7|g" > "$JC7/bin/git" <<'JC7STUB'
#!/bin/bash
D='@D@'
case " $* " in
  *" archive "*|*" ls-tree "*|*" hash-object "*)
    if [ ! -e "$D/ready" ]; then printf '%s\n' "$$" > "$D/shimpid"; : > "$D/ready"; exec sleep 30; fi ;;
esac
exec "$(cat "$D/realgit")" "$@"
JC7STUB
chmod +x "$JC7/bin/git"
_jc7() {   # SIGNAL -> exit|temporary directories left, when SIGNAL is sent to the call midway
  local pid n=0
  rm -rf "$JC7/tmp"; mkdir -p "$JC7/tmp"; rm -f "$JC7/ready" "$JC7/shimpid"
  ( set -m
    ( export PATH="$JC7/bin:$PATH" TMPDIR="$JC7/tmp" FELIX_PLUGIN_CACHE="$JCC"; unset FELIX_KERNEL_CACHE
      . "$REAL_HARNESS/lib/resolve.sh" >/dev/null 2>&1
      felix_accepted_deploy_diff "$JCR" main >/dev/null 2>&1 ) < /dev/null > /dev/null 2>&1 &
    pid=$!
    while [ ! -e "$JC7/ready" ] && [ "$n" -lt 50 ]; do sleep 0.2; n=$((n + 1)); done
    ls -A "$JC7/tmp" | wc -l | tr -d ' ' > "$JC7/atblock"
    kill -"$1" "$pid" "$(cat "$JC7/shimpid" 2>/dev/null)" 2>/dev/null
    wait "$pid" >/dev/null 2>&1; echo "$?" > "$JC7/rc" ) > /dev/null 2>&1
  printf '%s|%s|%s' "$([ -e "$JC7/ready" ] && echo blocked)" "$(cat "$JC7/atblock" 2>/dev/null)" "$(ls -A "$JC7/tmp" | wc -l | tr -d ' ')"
}
_jc_entry
is "C7: a TERM delivered to the call midway, while it holds its temporary directory (1 at the block), leaves none behind" "$(_jc7 TERM)" "blocked|1|0"
is "C7: and so does an INT" "$(_jc7 INT)" "blocked|1|0"

# ------------------------------------------------------------------- C8 ---
# A .gitignore that M holds as a symlink adds no rules.
JC_S="$(_jc_side sym engine/harness/tests/.gitignore.target 'scratch/')"
( _fx_cd "$JCR" && git checkout -q -b jc-side-sym2 "$JC_S" && ln -s .gitignore.target engine/harness/tests/.gitignore \
  && git add -f -A && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm sym2 && git checkout -q main ) >/dev/null 2>&1
JC_S2="$(_jc_sha jc-side-sym2)"; _fx_git "$JCR" branch -q -D jc-side-sym2 >/dev/null 2>&1
_fx_git "$JCR" update-ref refs/remotes/origin/jc-sym "$JC_S2" >/dev/null 2>&1
is "C8 (fixture control): jc-sym holds engine/harness/tests/.gitignore as a symlink (mode 120000) to a file that says scratch/" \
   "$(git -C "$JCR" ls-tree "$JC_S2" engine/harness/tests/.gitignore | LC_ALL=C cut -c1-6)|$(git -C "$JCR" show "$JC_S2:engine/harness/tests/.gitignore.target" 2>&1)" "120000|scratch/"
_jc_entry "$JC_S2"; mkdir -p "$JCE/harness/tests/scratch"; printf 'y\n' > "$JCE/harness/tests/scratch/y"
_jc_call jc-sym
is "C8: against jc-sym, an entry-only harness/tests/scratch/y is not residue: a symlinked .gitignore adds no rules" "$JCRC|$(_jc_names harness/tests/scratch)" "1|named"
_fx_git "$JCR" update-ref -d refs/remotes/origin/jc-sym >/dev/null 2>&1

# felix merge takes only a ref name that git accepts. A decoy tag
# refs/tags/refs/heads/jrc-nope answers to the expression refs/heads/jrc-nope~0.
JCM="$TMP/jc-sg"; mkdir -p "$JCM/repo" "$JCM/gh"; JCMR="$(cd "$JCM/repo" && pwd -P)"
JCP="$FROOT/projects/jrc"; mkdir -p "$JCP" "$MEM/jrc"
printf '{\n  "name": "jrc",\n  "remote_match": "example.com/jrc",\n  "gate": "true"\n}\n' > "$JCP/project.json"; printf '# jrc\n' > "$JCP/CLAUDE.md"
printf '#!/usr/bin/env bash\nexit 0\n' > "$JCM/gh/gh"; chmod +x "$JCM/gh/gh"
( _fx_cd "$JCMR" && git init -q -b main && git remote add origin https://github.com/example/jrc.git ) >/dev/null 2>&1
mkdir -p "$JCMR/engine/.claude-plugin"; printf '{ "name": "felix", "version": "1.0.0" }\n' > "$JCMR/engine/.claude-plugin/plugin.json"; printf 'jrc\n' > "$JCMR/.felix"
( _fx_cd "$JCMR" && git add -A && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm base ) >/dev/null 2>&1
JCM_M="$(git -C "$JCMR" rev-parse HEAD 2>/dev/null)"
_fx_git "$JCMR" update-ref refs/remotes/origin/main "$JCM_M" >/dev/null 2>&1
_fx_git "$JCMR" update-ref refs/tags/refs/heads/jrc-nope "$JCM_M" >/dev/null 2>&1
_jcm() {   # BASE -> JCMRC and $JCM/out: felix merge --dry-run --base BASE in the checkout
  ( cd "$JCMR" && env -u FELIX_KERNEL PATH="$JCM/gh:$PATH" FELIX_KERNEL_CACHE="$JCM/kc" "$FELIX" merge --dry-run --base "$1" ) > "$JCM/out" 2>&1; JCMRC=$?
}
_jcm_says() { LC_ALL=C grep -Fq 'felix merge takes only a ref name' "$JCM/out" && printf says; }
is "C8 (fixture control): git reads the expression refs/heads/jrc-nope~0 through the decoy tag, and refs/heads/jrc-nope itself does not exist" \
   "$(git -C "$JCMR" rev-parse --verify -q 'refs/heads/jrc-nope~0^{commit}' 2>/dev/null)|$(git -C "$JCMR" show-ref --verify -q refs/heads/jrc-nope 2>/dev/null && echo exists)" "$JCM_M|"
_jcm 'refs/heads/jrc-nope~0'
is "C8: felix merge --dry-run --base refs/heads/jrc-nope~0, an expression and not a ref name, is refused, saying it takes only a ref name" "$([ "$JCMRC" -ne 0 ] && echo refused)|$(_jcm_says)" "refused|says"
_jcm 'refs/tags/refs/heads/jrc-nope^{commit}'
is "C8: and so is refs/tags/refs/heads/jrc-nope^{commit}" "$([ "$JCMRC" -ne 0 ] && echo refused)|$(_jcm_says)" "refused|says"
_jcm main
is "C8 (control): --base main, a ref name that exists, is not refused for that reason" "$(_jcm_says)" ""
_jcm refs/heads/main
is "C8 (control): and neither is --base refs/heads/main" "$(_jcm_says)" ""

# This part's fixtures and its project are taken away again.
rm -rf "$FROOT/projects/jrc" "$MEM/jrc" "$JC" "$JCM"
