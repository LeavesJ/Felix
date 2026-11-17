# tests/lib/land-on-green.sh: the land-on-green fixture, its helpers, and the builder that gives parts 1280-1289 the same state.
# Used by 1280 (builds it) and 1281 to 1289, each of which calls _lg_build (1287 landed with A30 and 0.49.295,
# 1288 and 1289 with A31 and 0.49.297). Moved from parts/1280-land-on-green-blind.sh: lines 24-28, 30-94, 96-150, 166-179 and 183
# (the fixture, now step base of _lg_build), line 29 (_lg_put), lines 151-165 (_lg_branch, _lg_more, _lg_sha) and
# 184-215 (_lg_land to _lg_osa), verbatim, and lines 363-364 (_lg_scratch); from parts/1281-land-on-green-deploy-blind.sh:
# line 15 (LGV, in step base), 16-19 (_lg_cache, _lg_inst, _lg_ninst, _lg_mainv); from parts/1282-land-on-green-round-2-blind.sh:
# lines 129-143 (step amend), 144-175 (_la_names, _la_reap, _la_bg, _la_accepts), 177-183 (_la_tramp, _la_ticks) and the
# LATR value (line 176); from parts/1283-land-on-green-round-3-blind.sh: lines 12, 14 and 21-24 (_l3_mainv, _l3_mpath,
# _l3_commit); from parts/1284-land-on-green-round-4-blind.sh: lines 27-30 (_l4_acc).
# Definitions only. _lg_build <base|after-1280|amend> builds the fixture into $TMP/land-g, step by step; a step already
# done is skipped (base: $LG/shas is there; after-1280: b41 holds its scratch file; amend: $LG/amend/realgit is there), so
# in the serial run 1280 makes the base, 1280 itself its scratch files, 1282 the amend layer, and every later call finds
# them. Worktrees record absolute paths, so a missing fixture is rebuilt in its place, never copied.

_lg_put() { mkdir -p "$(dirname "$1")" && sed "s#@LG@#$LG#g" > "$1" && chmod +x "$1"; }

# A worktree of the home per pull request, on branch bN from main, with one
# commit touching the files named. Their heads are kept as N<TAB>sha.
_lg_branch() {   # NAME FILE... -> prints the new head
  local f
  _fx_git "$LGH" worktree add -q -b "$1" "$LGW/$1" main >/dev/null 2>&1 || return 1
  for f in "${@:2}"; do mkdir -p "$(dirname "$LGW/$1/$f")"; printf '%s %s\n' "$1" "$f" >> "$LGW/$1/$f"; done
  _fx_git "$LGW/$1" add -A >/dev/null 2>&1
  _fx_git "$LGW/$1" -c user.name=t -c user.email=t@t commit -qm "$1" >/dev/null 2>&1
  git -C "$LGW/$1" rev-parse HEAD
}
_lg_more() {   # NAME FILE -> one more commit on worktree NAME; prints the new head
  printf 'more\n' >> "$LGW/$1/$2"
  _fx_git "$LGW/$1" add -A >/dev/null 2>&1
  _fx_git "$LGW/$1" -c user.name=t -c user.email=t@t commit -qm more >/dev/null 2>&1
  git -C "$LGW/$1" rev-parse HEAD
}
_lg_sha() { LC_ALL=C awk -F'\t' -v n="$1" '$1 == n { print $2 }' "$LG/shas"; }
# _lgsnap: what the land directory and LaunchAgents hold, to show a command wrote nothing there.
# Moved from parts/1280-land-on-green-blind.sh line 57; 1280 and 1288 call it.
_lgsnap() { ( cd "$LAND" 2>/dev/null && find . -exec cksum {} + 2>/dev/null | LC_ALL=C sort ); ls -la "$LGU/Library/LaunchAgents" 2>/dev/null; }

_lg_land() {   # ARGS -> felix land ARGS from the home; output in $LG/out, status in LGRC
  ( cd "$LGH" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE ${LGX[@]+"${LGX[@]}"} \
      HOME="$LGU" FELIX_HOME="$LGH" FELIX_HOME_DIR="$LGH" FELIX_MEMORY="$LGM" FELIX_PLUGIN_CACHE="$LGC" \
      PATH="$LGB:$PATH" "$FELIX" land "$@" ) > "$LG/out" 2>&1
  LGRC=$?
}
_lg_reset() {
  rm -rf "$LAND" "$LGL" "$LGK"; mkdir -p "$LGL" "$LGK"
  printf '[]\n' > "$LGK/prs.json"; printf 'README.md\n' > "$LGK/files.default"; LGX=()
}
_lg_rows() { if [ -f "$LAND/ledger.tsv" ]; then awk 'END { print NR }' "$LAND/ledger.tsv"; else echo 0; fi; }
_lg_cnt() { if [ -f "$LGL/$1.log" ]; then awk 'END { print NR }' "$LGL/$1.log"; else echo 0; fi; }
_lg_logs() { cat "$LGL/$1.log" 2>/dev/null; }
_lg_n() {   # EVENT [PR] -> how many ledger rows
  [ -f "$LAND/ledger.tsv" ] || { echo 0; return; }
  LC_ALL=C awk -F'\t' -v e="$1" -v p="${2-}" '$2 == e && (p == "" || $3 == p) { n++ } END { print n + 0 }' "$LAND/ledger.tsv"
}
_lg_f() {   # EVENT PR FIELD -> that field of the last such row (PR empty: any)
  [ -f "$LAND/ledger.tsv" ] || return 0
  LC_ALL=C awk -F'\t' -v e="$1" -v p="$2" -v k="$3" '$2 == e && (p == "" || $3 == p) { v = $k } END { printf "%s", v }' "$LAND/ledger.tsv"
}
_lg_lc() { printf '%s' "$1" | LC_ALL=C tr '[:upper:]' '[:lower:]'; }
_lg_merges() { [ -f "$LGL/felix.log" ] || return 0
  LC_ALL=C awk -F'\t' '$3 == "merge" || index($3, "merge ") == 1 { n = $2; sub(/.*\//, "", n); printf "%s%s", s, n; s = " " }' "$LGL/felix.log"; }
_lg_pr() {   # N [draft] [labels] [mergeable] [cross] [base] -> one pull request as gh lists it
  printf '{"number":%s,"headRefName":"b%s","headRefOid":"%s","isDraft":%s,"labels":%s,"mergeable":"%s","isCrossRepository":%s,"baseRefName":"%s"}' \
    "$1" "$1" "$(_lg_sha "$1")" "${2:-false}" "${3:-[]}" "${4:-MERGEABLE}" "${5:-false}" "${6:-main}"
}
_lg_prs() { local IFS=,; printf '[%s]\n' "$*" > "$LGK/prs.json"; }
_lg_green() { local n s; for n in "$@"; do s="$(_lg_sha "$n")"; printf 'completed\tsuccess\t%s\n' "$s" > "$LGK/runs.$s"; done; }
_lg_osa() { case "$(_lg_logs osa)" in *"$1"*) ok "$2" ;; *) bad "$2" "osascript was called with: $(_lg_logs osa | cut -f1 | head -8 | tr '\n' '|')" ;; esac; }

# 2026-10-18 (judge refs, Part C): the entry is compared whole, so it holds main's manifest too.
_lg_cache() { rm -rf "$LGV/$1"; mkdir -p "$LGV/$1/.claude-plugin"; cp -R "$LGH/engine/harness" "$LGV/$1/harness"
              printf '{ "name": "felix", "version": "%s" }\n' "$1" > "$LGV/$1/.claude-plugin/plugin.json"; }
_lg_inst() { _lg_logs felix | LC_ALL=C awk -F'\t' 'index($3, "install") == 1'; }
_lg_ninst() { _lg_inst | wc -l | tr -d ' '; }
_lg_mainv() { git -C "$LGH" show origin/main:engine/.claude-plugin/plugin.json 2>/dev/null | sed -n 's/.*"version": *"\([^"]*\)".*/\1/p'; }

_la_names() {   # WHAT DETAIL WORD... -> the detail, folded, holds one of the words
  local what="$1" d w; d="$(_lg_lc "$2")"; shift 2
  for w in "$@"; do case "$d" in *"$w"*) ok "$what"; return 0 ;; esac; done
  bad "$what" "[$d] holds none of: $*"
}
_la_reap() {   # PID -> it has ended, by itself within ten seconds or by KILL
  local i=0
  while [ "$i" -lt 100 ] && kill -0 "$1" 2>/dev/null; do sleep 0.1; i=$((i+1)); done
  kill -0 "$1" 2>/dev/null && kill -KILL "$1" 2>/dev/null
  wait "$1" 2>/dev/null; return 0
}
_la_bg() {   # NAME -> felix land --tick in the background, in a process group of its own; pid in LABG
  ( cd "$LGH" || exit 97
    exec perl -e 'setpgrp(0, 0); exec @ARGV or exit 127' env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE \
      HOME="$LGU" FELIX_HOME="$LGH" FELIX_HOME_DIR="$LGH" FELIX_MEMORY="$LGM" FELIX_PLUGIN_CACHE="$LGC" \
      PATH="$LGB:$PATH" "$FELIX" land --tick ) > "$LG/out.$1" 2>&1 &
  LABG=$!
}
_la_accepts() {   # -> main's own felix_accepted_deploy_diff on the home, as cmd_merge asks it: its status
  ( unset FELIX_KERNEL_CACHE; FELIX_PLUGIN_CACHE="$LGC"
    git -C "$LGH" show origin/main:engine/harness/lib/resolve.sh > "$LA/resolve.main" 2>/dev/null || exit 9
    . "$LA/resolve.main" >/dev/null 2>&1; felix_accepted_deploy_diff "$LGH" main >/dev/null 2>&1 ); echo "$?"
}

_la_tramp() {   # [PATH-PREFIX] -> the trampoline, with launchd's environment; status in LARC
  ( cd "$TMP/cwd" 2>/dev/null || cd "$LG" || exit 97
    exec env -i HOME="$LGU" FELIX_HOME_DIR="$LGH" PATH="${1-}$LGB:$PATH" GIT_CEILING_DIRECTORIES="${GIT_CEILING_DIRECTORIES-}" \
      "$LATR" ) > "$LG/out.tramp" 2>&1
  LARC=$?
}
_la_ticks() { _lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick"' | wc -l | tr -d ' '; }

_l3_mainv() { git -C "$LGH" show refs/remotes/origin/main:engine/.claude-plugin/plugin.json 2>/dev/null | sed -n 's/.*"version": *"\([^"]*\)".*/\1/p'; }
_l3_mpath() { _lg_logs felix | LC_ALL=C awk -F'\t' 'index($3, "merge") == 1 { print $1 }' | LC_ALL=C sort -u | tr '\n' ' '; }
_l3_commit() {   # FILE MSG -> one commit on the home's main, pushed: origin/main moves and the home stays at it
  mkdir -p "$(dirname "$LGH/$1")"; printf '%s\n' "$2" >> "$LGH/$1"; _fx_git "$LGH" add -A >/dev/null 2>&1
  _fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qm "$2" >/dev/null 2>&1; _fx_git "$LGH" push -q origin main >/dev/null 2>&1
}

_l4_acc() {   # BASE -> this tree's felix_accepted_deploy_diff on the home, against the fixture cache: its status
  ( unset FELIX_KERNEL_CACHE; FELIX_PLUGIN_CACHE="$LGC"
    . "$REAL_HARNESS/lib/resolve.sh" >/dev/null 2>&1; felix_accepted_deploy_diff "$LGH" "$1" >/dev/null 2>&1 ); echo "$?"
}

_lg_scratch() {   # the untracked file in b41's worktree and the tripwire felix in b42's, as 1280 leaves them
  printf 'scratch\n' > "$LGW/b41/untracked-scratch.txt"
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/trip.log"\nexit 0\n' "$LGL" > "$LGW/b42/engine/harness/felix"
}

_lg_build() {   # base|after-1280|amend: the fixture up to that state; a step already done is skipped
  local want="${1:-base}"
  if [ -z "${LGH:-}" ] || [ ! -f "${LG:-/nonexistent}/shas" ] || [ ! -d "$LGH/.git" ]; then
    [ -z "${LG:-}" ] || rm -rf "${LG:?}"
    LG="$TMP/land-g"; mkdir -p "$LG"; LG="$(cd "$LG" && pwd -P)"
    LGO="$LG/github.com/fixture/lgh.git"; LGH="$LG/home"; LGW="$LG/wt"; LGC="$LG/cache"
    LGM="$LG/mem"; LGU="$LG/user"; LGB="$LG/bin"; LGK="$LG/ctl"; LGL="$LG/log"
    LAND="$LGM/lgh/land"; LGE="$LGC/felix/felix/9.0.0/harness/felix"
    mkdir -p "$LGO" "$LGW" "$LGC" "$LGM" "$LGU" "$LGB" "$LGK" "$LGL"

    _lg_put "$LGB/gh" <<'LGSTUB'
#!/bin/bash
LG='@LG@'; K="$LG/ctl"
printf '%s\n' "$*" >> "$LG/log/gh.log"
jqx=""; commit=""; prev=""
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; --commit) commit="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; --commit=*) commit="${a#--commit=}" ;; esac
  prev="$a"
done
out() { if [ -n "$jqx" ] && command -v jq >/dev/null 2>&1; then jq -r "$jqx"; else cat; fi; }
case "${1:-} ${2:-}" in
  "auth status")
    if [ -f "$K/gh-block" ] && mkdir "$K/gh-block-taken" 2>/dev/null; then
      n=0; while [ -f "$K/gh-block" ] && [ "$n" -lt 300 ]; do sleep 0.1; n=$((n+1)); done
    fi
    rc=0; [ -f "$K/gh-auth.rc" ] && rc="$(cat "$K/gh-auth.rc")"; exit "$rc" ;;
  "pr list") out < "$K/prs.json"; exit 0 ;;
  "pr view")
    fl="$K/files.${3:-}"; [ -f "$fl" ] || fl="$K/files.default"
    { printf '{"number":%s,"files":[' "${3:-0}"; s=""
      while IFS= read -r f; do [ -n "$f" ] || continue
        printf '%s{"path":"%s","additions":1,"deletions":0}' "$s" "$f"; s=","; done < "$fl"
      printf ']}\n'; } | out; exit 0 ;;
  "run list")
    f="$K/runs.$commit"
    if [ -f "$f.rc" ]; then echo "HTTP 502: Bad Gateway" >&2; exit "$(cat "$f.rc")"; fi
    if [ -n "$jqx" ]; then
      if [ -f "$f" ]; then awk 'END { print NR }' "$f"; cat "$f"; else echo 0; fi
    else
      printf '['; s=""
      if [ -f "$f" ]; then while IFS="$(printf '\t')" read -r st co sh; do
        [ "$co" = - ] && co=""
        printf '%s{"status":"%s","conclusion":"%s","headSha":"%s"}' "$s" "$st" "$co" "$sh"; s=","; done < "$f"; fi
      printf ']\n'
    fi; exit 0 ;;
esac
exit 0
LGSTUB
    _lg_put "$LGB/pgrep" <<'LGSTUB'
#!/bin/bash
LG='@LG@'
printf '%s\n' "$*" >> "$LG/log/pgrep.log"
pat=""; for a in "$@"; do case "$a" in -*) ;; *) pat="$a" ;; esac; done
[ -n "$pat" ] && [ -f "$LG/ctl/procs" ] || exit 1
hits="$(LC_ALL=C grep -nE -- "$pat" "$LG/ctl/procs" 2>/dev/null | cut -d: -f1)"
[ -n "$hits" ] || exit 1
for h in $hits; do printf '4%04d\n' "$h"; done
exit 0
LGSTUB
    _lg_put "$LGB/osascript" <<'LGSTUB'
#!/bin/bash
LG='@LG@'
last="$(tail -1 "$LG/mem/lgh/land/ledger.tsv" 2>/dev/null | tr '\t' '|')"
printf '%s\t%s\n' "$*" "$last" >> "$LG/log/osa.log"
rc=0; [ -f "$LG/ctl/osa.rc" ] && rc="$(cat "$LG/ctl/osa.rc")"; exit "$rc"
LGSTUB
    _lg_put "$LGB/launchctl" <<'LGSTUB'
#!/bin/bash
LG='@LG@'
printf '%s\n' "$*" >> "$LG/log/launchctl.log"
case "${1:-}" in print|list) [ -f "$LG/ctl/loaded" ] && exit 0; exit 113 ;; esac
exit 0
LGSTUB
    # The bare origin, and the home cloned from it.
    _fx_git "$LGO" init -q --bare >/dev/null 2>&1
    _fx_git "$LGO" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
    _fx_git "$LG" clone -q "$LGO" home >/dev/null 2>&1
    _fx_git "$LGH" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
    mkdir -p "$LGH/engine/.claude-plugin" "$LGH/engine/harness/lib" "$LGH/projects/lgh" "$LGH/notes"
    printf '{ "name": "felix", "version": "9.0.0" }\n' > "$LGH/engine/.claude-plugin/plugin.json"
    printf 'core 0\n' > "$LGH/engine/harness/lib/core.sh"
    printf '{\n  "name": "lgh",\n  "remote_match": "github.com/fixture/lgh",\n  "gate": "true"\n}\n' > "$LGH/projects/lgh/project.json"
    printf '# lgh\n' > "$LGH/projects/lgh/CLAUDE.md"; printf 'home\n' > "$LGH/README.md"
    _lg_put "$LGH/engine/harness/felix" <<'LGSTUB'
#!/bin/bash
LG='@LG@'; K="$LG/ctl"
p="$0"; case "$p" in /*) ;; *) p="$PWD/$p" ;; esac
d="$(cd -P "$(dirname "$p")" 2>/dev/null && pwd -P)"; here="$(pwd -P)"
ar="${FELIX_ALLOW_RED+set}"; kn="${FELIX_KERNEL+set}"; kc="${FELIX_KERNEL_CACHE+set}"
printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$d/${p##*/}" "$here" "$*" "${ar:-unset}" "${kn:-unset}" "${kc:-unset}" >> "$LG/log/felix.log"
case "${1:-}" in
  merge)
    b="${here##*/}"
    [ -f "$K/merge.$b.out" ] && cat "$K/merge.$b.out"
    if [ -f "$K/merge.$b.push" ]; then
      case "$here/" in "$LG"/*) git push -q "$LG/github.com/fixture/lgh.git" HEAD:refs/heads/main >/dev/null 2>&1 ;; esac
    fi
    rc=0; [ -f "$K/merge.$b.rc" ] && rc="$(cat "$K/merge.$b.rc")"; exit "$rc" ;;
  install)
    [ "$d" = "$LG/home/engine/harness" ] || exit 9
    v="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$d/../.claude-plugin/plugin.json" 2>/dev/null | head -1)"
    [ -n "$v" ] || exit 8
    rm -rf "$LG/cache/felix/felix/$v"; mkdir -p "$LG/cache/felix/felix/$v"
    cp -R "$d" "$LG/cache/felix/felix/$v/harness" || exit 7
    cp -R "$d/../.claude-plugin" "$LG/cache/felix/felix/$v/.claude-plugin" || exit 7
    [ ! -f "$K/install.taint" ] || printf 'taint\n' > "$LG/cache/felix/felix/$v/harness/taint"
    exit 0 ;;
  gate) rc=0; [ -f "$K/gate.rc" ] && rc="$(cat "$K/gate.rc")"; exit "$rc" ;;
esac
exit 0
LGSTUB
    # Audit b02, B31: the verify asks session-start for a line of context and pre-tool for a refusal of a pattern
    # kill, so these stubs give both, as the home's real hooks do; log/hook.log and log/pretool.log hold what each was given.
    _lg_put "$LGH/engine/harness/hooks/session-start" <<'LGSTUB'
#!/bin/bash
LG='@LG@'
{ printf '%s\t%s\t' "$(cd -P "$(dirname "$0")" && pwd -P)" "$(pwd -P)"; tr '\n' ' '; printf '\n'; } >> "$LG/log/hook.log"
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Felix governs lgh."}}\n'
rc=0; [ -f "$LG/ctl/hook.rc" ] && rc="$(cat "$LG/ctl/hook.rc")"; exit "$rc"
LGSTUB
    _lg_put "$LGH/engine/harness/hooks/pre-tool" <<'LGSTUB'
#!/bin/bash
LG='@LG@'
p="$(cat)"
printf '%s\t%s\t%s\n' "$(cd -P "$(dirname "$0")" && pwd -P)" "$(pwd -P)" "$(printf '%s' "$p" | tr '\n' ' ')" >> "$LG/log/pretool.log"
case "$p" in *killall*|*pkill*) echo "a pattern kill: stop only a pid you started" >&2; exit 2 ;; esac
exit 0
LGSTUB
    # Main's own acceptance check (A1) is real, so the trampoline has an engine it
    # accepts: the base commit holds the real lib/resolve.sh, as 1282's A1 does.
    cp "$REAL_HARNESS/lib/resolve.sh" "$LGH/engine/harness/lib/resolve.sh"
    _fx_git "$LGH" add -A >/dev/null 2>&1
    _fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qm base >/dev/null 2>&1
    _fx_git "$LGH" push -q -u origin main >/dev/null 2>&1
    mkdir -p "$LGC/felix/felix/9.0.0"; cp -R "$LGH/engine/harness" "$LGC/felix/felix/9.0.0/harness"
    # 2026-10-18 (judge refs, Part C): the entry is compared whole, so it holds main's manifest too.
    cp -R "$LGH/engine/.claude-plugin" "$LGC/felix/felix/9.0.0/.claude-plugin"
    mkdir -p "$LGU/.claude/plugins"; ln -s "$LGC" "$LGU/.claude/plugins/cache"

    : > "$LG/shas"
    for _lgn in 21 22 23 24 25 26 27 29 30 40 41 42 43; do
      printf '%s\t%s\n' "$_lgn" "$(_lg_branch "b$_lgn" "notes/b$_lgn.md")" >> "$LG/shas"
    done
    printf '28a\t%s\n' "$(_lg_branch b28 notes/b28.md)" >> "$LG/shas"
    printf '28\t%s\n' "$(_lg_more b28 notes/b28.md)" >> "$LG/shas"
    printf '31\t%s\n' "$(_lg_branch b31 notes/b31.md)" >> "$LG/shas"
    _fx_git "$LGH" worktree remove --force "$LGW/b31" >/dev/null 2>&1
    printf '32a\t%s\n' "$(_lg_branch b32 notes/b32.md)" >> "$LG/shas"
    printf '32\t%s\n' "$(_lg_more b32 notes/b32.md)" >> "$LG/shas"
    _fx_git "$LGW/b32" reset -q --hard "$(_lg_sha 32a)" >/dev/null 2>&1
    printf '33\t%s\n' "$(_lg_branch b33 notes/b33.md)" >> "$LG/shas"
    _fx_git "$LGW/b33" checkout -q --detach >/dev/null 2>&1
    printf '34\t%s\n' "$(_lg_branch b34 projects/someone-else/CLAUDE.md)" >> "$LG/shas"
    printf '35\t%s\n' "$(_lg_branch b35 docs/2026-10-15-roadmap.md)" >> "$LG/shas"
    LGX=()
    LGV="$LGC/felix/felix"
  fi
  case "$want" in after-1280|amend)
    if [ ! -f "$LGW/b41/untracked-scratch.txt" ]; then _lg_scratch; fi ;;
  esac
  case "$want" in amend)
    if [ ! -f "$LG/amend/realgit" ]; then
      LA="$LG/amend"; mkdir -p "$LA/git69" "$LGU/.felix"
      [ -e "$LGU/.felix/memory" ] || ln -s "$LGM" "$LGU/.felix/memory"
      printf '#!/bin/sh\nexit 69\n' > "$LA/git69/git"; chmod +x "$LA/git69/git"
      command -v git > "$LA/realgit"
      # gh as 1280's stub answers it, but for a pr view whose ctl/files.N.rc exists,
      # which fails as gh does on a server error.
      mv "$LGB/gh" "$LA/gh.1280"
      _lg_put "$LGB/gh" <<'LGSTUB'
#!/bin/bash
LG='@LG@'
if [ "${1:-} ${2:-}" = "pr view" ] && [ -f "$LG/ctl/files.${3:-}.rc" ]; then
  printf '%s\n' "$*" >> "$LG/log/gh.log"; echo "HTTP 502: Bad Gateway" >&2; exit "$(cat "$LG/ctl/files.${3:-}.rc")"
fi
exec "$LG/amend/gh.1280" "$@"
LGSTUB
      LATR="$LGU/Library/Application Support/felix/land/lgh/tick"
    fi ;;
  esac
  return 0
}
