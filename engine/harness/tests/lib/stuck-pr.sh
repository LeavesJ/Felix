# tests/lib/stuck-pr.sh: the stuck-PR fixture, its helpers, and the builder that parts 1300, 1310 and 1320 share.
# Moved from parts/1300-stuck-pr-page-blind.sh (step 5, 0.49.298) for gate friction C: lines 32-38, 41-85, 89-133,
# 143 and 207 (the fixture, its stubs, its repositories, SP_UPD and the first ledger), now the body of _sp_build, and
# lines 39, 87-88, 135-142, 144-186, 188-206 and 209-263 (_sp_put to _sp_snapall), verbatim.
# Definitions only. _sp_build builds the fixture into $TMP/stuck-pr and writes its ledger. When the fixture is
# already there it does nothing, so in the serial run 1300 builds it and 1310 and 1320 find the state 1300 left;
# each of the three calls it, so each runs alone. Part 1320 removes the fixture. _sp_list, which
# 1310 and 1320 call, sets 1310's SPLIST.

_sp_put() { mkdir -p "$(dirname "$1")" && LC_ALL=C sed "s#@SP@#$SP#g" > "$1" && chmod +x "$1"; }

# ---- the repositories -------------------------------------------------------
_sp_commit() { _fx_git "$1" add -A >/dev/null 2>&1; _fx_git "$1" -c user.name=t -c user.email=t@t commit -qm "$2" >/dev/null 2>&1; }

# ---- pull requests as gh lists them ---------------------------------------
# A head is 40 hex digits led by the number, so its first 7 characters differ
# from every other head's: _sp_sha the current head, _sp_old an older one,
# _sp_two the heads of two's pull requests.
_sp_sha() { printf '%04d%s' "$1" c0ffeec0ffeec0ffeec0ffeec0ffeec0ffee; }
_sp_old() { printf '%04d%s' "$1" deadbedeadbedeadbedeadbedeadbedeadbe; }
_sp_two() { printf '%04d%s' "$1" abcdefabcdefabcdefabcdefabcdefabcdef; }
_sp_ago() { local t; t=$(( $(date +%s) - $1 )); date -u -r "$t" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$t" +%Y-%m-%dT%H:%M:%SZ; }
_sp_cr() { printf '{"__typename":"CheckRun","name":"%s","workflowName":"%s","status":"%s","conclusion":"%s","startedAt":"%s","completedAt":"%s","detailsUrl":"https://example.invalid/%s"}' \
             "$1" "$1" "$2" "$3" "$SP_UPD" "$SP_UPD" "$1"; }
_sp_sc() { printf '{"__typename":"StatusContext","context":"%s","state":"%s","startedAt":"%s","targetUrl":"https://example.invalid/%s"}' "$1" "$2" "$SP_UPD" "$1"; }
_sp_roll() {
  case "$1" in
    green)   printf '[%s,%s]' "$(_sp_cr gate COMPLETED SUCCESS)" "$(_sp_sc ci/other SUCCESS)" ;;
    mixed)   printf '[%s,%s,%s]' "$(_sp_cr gate COMPLETED SUCCESS)" "$(_sp_cr lint COMPLETED SKIPPED)" "$(_sp_cr docs COMPLETED NEUTRAL)" ;;
    red)     printf '[%s,%s]' "$(_sp_cr gate COMPLETED SUCCESS)" "$(_sp_cr lint COMPLETED FAILURE)" ;;
    running) printf '[%s,%s]' "$(_sp_cr gate COMPLETED SUCCESS)" "$(_sp_cr lint IN_PROGRESS '')" ;;
    ctxerr)  printf '[%s,%s]' "$(_sp_cr gate COMPLETED SUCCESS)" "$(_sp_sc ci/other ERROR)" ;;
    ctxpend) printf '[%s,%s]' "$(_sp_cr gate COMPLETED SUCCESS)" "$(_sp_sc ci/other PENDING)" ;;
    *)       printf '[]' ;;
  esac
}
# FILES is "path:deleted-lines ..." or @100 for exactly one hundred files.
_sp_files() {
  local s="" f i=1
  if [ "$1" = @100 ]; then
    while [ "$i" -le 100 ]; do printf '%s{"path":"notes/many/f%03d.md","additions":1,"deletions":0}' "$s" "$i"; s=","; i=$((i+1)); done
    return 0
  fi
  for f in $1; do printf '%s{"path":"%s","additions":1,"deletions":%s}' "$s" "${f%:*}" "${f##*:}"; s=","; done
}
_sp_labels() { ( IFS=,; s=""; for l in $1; do printf '%s{"id":"LA_%s","name":"%s","description":"","color":"ededed"}' "$s" "$l" "$l"; s=","; done ); }
_sp_pr() {   # N FILES ROLL [title= branch= sha= base= draft= cross= author= labels= mergeable= mss= repo=]
  local n="$1" fs="$2" ro="$3" kv t="Change $1" br="b$1" sha="" base=main dr=false cr=false au=fixture lb="" mg=MERGEABLE ms=CLEAN rp=fixture/home
  shift 3
  for kv in "$@"; do case "$kv" in
    title=*) t="${kv#title=}" ;; branch=*) br="${kv#branch=}" ;; sha=*) sha="${kv#sha=}" ;; base=*) base="${kv#base=}" ;;
    draft=*) dr="${kv#draft=}" ;; cross=*) cr="${kv#cross=}" ;; author=*) au="${kv#author=}" ;; labels=*) lb="${kv#labels=}" ;;
    mergeable=*) mg="${kv#mergeable=}" ;; mss=*) ms="${kv#mss=}" ;; repo=*) rp="${kv#repo=}" ;;
  esac; done
  [ -n "$sha" ] || sha="$(_sp_sha "$n")"
  printf '{"number":%s,"title":"%s","headRefName":"%s","headRefOid":"%s","baseRefName":"%s","isDraft":%s,"isCrossRepository":%s,' "$n" "$t" "$br" "$sha" "$base" "$dr" "$cr"
  printf '"author":{"id":"U_%s","is_bot":false,"login":"%s","name":""},"labels":[%s],"mergeable":"%s","mergeStateStatus":"%s",' "$au" "$au" "$(_sp_labels "$lb")" "$mg" "$ms"
  printf '"statusCheckRollup":%s,"files":[%s],"updatedAt":"%s","url":"https://github.com/%s/pull/%s"}' "$(_sp_roll "$ro")" "$(_sp_files "$fs")" "$SP_UPD" "$rp" "$n"
}
_sp_prs() {   # KEY OBJECT... -> ctl/prs.KEY.json, a JSON array of the objects
  local k="$1" s="" o; shift
  { printf '['; for o in "$@"; do printf '%s%s' "$s" "$o"; s=","; done; printf ']\n'; } > "$SPK/prs.$k.json"
  rm -f "$SPK/prs.$k.rc" "$SPK/prs.$k.err"
}
_sp_ghfail() { printf '1\n' > "$SPK/prs.$1.rc"; printf '%s\n' "$2" > "$SPK/prs.$1.err"; }

# ---- the ledgers, the lock and the paused file -----------------------------
_sp_ledger() {
  rm -rf "$SPLAND" "$SP2LAND"; mkdir -p "$SPLAND/lock" "$SP2LAND"
  { printf '2026-10-16T09:00:00Z\tpaused\t-\t-\t-\t0\theld for a while\n'
    printf '2026-10-16T09:10:00Z\trefused\t130\t%s\t%s\t3\tblocker one: the receipt is stale [main %s]\n' "$(_sp_sha 130)" "$SPH" "$SPMAIN"
    printf '2026-10-16T09:11:00Z\trefused\t131\t%s\t%s\t3\tblocker two: on an older main [main %s]\n' "$(_sp_sha 131)" "$SPH" "$SPOLD"
    printf '2026-10-16T09:12:00Z\trefused\t132\t%s\t%s\t3\tblocker three: an older head [main %s]\n' "$(_sp_old 132)" "$SPH" "$SPMAIN"
    printf '2026-10-16T09:13:00Z\tsession\t133\t%s\t-\t1\tno checkout holds the gated head\n' "$(_sp_sha 133)"
    printf '2026-10-16T09:14:00Z\tlanded\t134\t%s\t%s\t2\tmerged\n' "$(_sp_old 134)" "$SPH"
    printf '2026-10-16T09:15:00Z\trefused\t1340\t%s\t%s\t3\tblocker four: another pull request [main %s]\n' "$(_sp_sha 134)" "$SPH" "$SPMAIN"
    printf '2026-10-16T09:16:00Z\trefused\t135\t%s\t%s\t3\tblocker five: refused first [main %s]\n' "$(_sp_sha 135)" "$SPH" "$SPMAIN"
    printf '2026-10-16T09:17:00Z\tskip\t135\t%s\t-\t0\twaiting on its gate run\n' "$(_sp_sha 135)"
    printf '2026-10-16T09:18:00Z\tsession\t202\t%s\t-\t1\tthe home ledger speaks of two\n' "$(_sp_two 202)"
  } > "$SPLAND/ledger.tsv"
  printf '2026-10-16T09:20:00Z\tsession\t201\t%s\t-\t1\tthe gated head is in no checkout of two\n' "$(_sp_two 201)" > "$SP2LAND/ledger.tsv"
  sh -c 'exit 0' & _spdead=$!; wait "$_spdead"
  printf '%s\n' "$_spdead" > "$SPLAND/lock/pid"; printf 'Thu Jan  1 00:00:00 1970\n' > "$SPLAND/lock/started"
  printf 'held for a while\nthe second line of the reason\n' > "$SPLAND/paused"
}

# ---- running the page --------------------------------------------------------
# felix land ARGS in directory D. stdout to out/out, stderr to out/err, status
# in SPRC; out/both holds the two together for usage text.
_sp_land() {   # D ARGS...
  local d="$1"; shift
  ( cd "$d" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u CLAUDE_CODE_SESSION_ID \
      HOME="$SPU" FELIX_HOME="$SPH" FELIX_HOME_DIR="$SPH" FELIX_MEMORY="$SPM" FELIX_PLUGIN_CACHE="$SP/cache" \
      XDG_STATE_HOME="$SPU/.state-caller" XDG_CACHE_HOME="$SPU/.cache-caller" GH_CONFIG_DIR="$SPU/.config/gh" \
      TMPDIR="$SPT" PATH="$SPB:$PATH" "$FELIX" land "$@" ) > "$SPX/out" 2> "$SPX/err"
  SPRC=$?
  cat "$SPX/out" "$SPX/err" > "$SPX/both"
}
_sp_keep() { cp "$SPX/out" "$SPX/$1"; printf '%s\n' "$SPRC" > "$SPX/$1.rc"; }
_sp_logs0() { rm -rf "$SPL"; mkdir -p "$SPL"; }
_sp_prl() { if [ -f "$1" ]; then LC_ALL=C awk 'index($0, "pr list") == 1 { n++ } END { print n + 0 }' "$1"; else echo 0; fi; }
_sp_cnt() { if [ -f "$SPL/$1.log" ]; then LC_ALL=C awk 'END { print NR }' "$SPL/$1.log"; else echo 0; fi; }
# Readers of a --tsv page. The pr row of #N, a field of it, its state (the
# states cell before its first comma), its flags (what follows), a source row.
_sp_row()   { LC_ALL=C awk -F'\t' -v r="#$2" '$1 == "pr" && $3 == r' "$1" 2>/dev/null; }
_sp_nrow()  { _sp_row "$1" "$2" | LC_ALL=C awk 'END { print NR }'; }
_sp_f()     { _sp_row "$1" "$2" | LC_ALL=C awk -F'\t' -v k="$3" 'NR == 1 { printf "%s", $k }'; }
_sp_state() { _sp_f "$1" "$2" 4 | LC_ALL=C sed 's/,.*//'; }
_sp_flags() { _sp_f "$1" "$2" 4 | LC_ALL=C awk '{ i = index($0, ","); if (i) printf "%s", substr($0, i); }'; }
_sp_src()   { LC_ALL=C awk -F'\t' -v r="$2" '$1 == "source" && $3 == r' "$1" 2>/dev/null; }
_sp_srcf()  { _sp_src "$1" "$2" | LC_ALL=C awk -F'\t' -v k="$3" 'NR == 1 { printf "%s", $k }'; }
_sp_prn()   { LC_ALL=C awk -F'\t' '$1 == "pr" { n++ } END { print n + 0 }' "$1" 2>/dev/null; }
# The line of a text page that begins "#N ", and its line number.
_sp_tline() { LC_ALL=C awk -v p="#$2 " 'index($0, p) == 1' "$1" 2>/dev/null; }
_sp_tno()   { LC_ALL=C awk -v p="#$2 " 'index($0, p) == 1 { print NR; exit }' "$1" 2>/dev/null; }
_sp_lacks() { case "$2" in *"$3"*) bad "$1" "[$2] holds [$3]" ;; *) ok "$1" ;; esac; }
# State and needs of #N in FILE, as one assertion each.
_sp_is() {   # LABEL FILE N STATE NEEDS
  is "$1: #$3 is in state $4" "$(_sp_state "$2" "$3")" "$4"
  [ -z "$5" ] || is "$1: #$3 needs $5" "$(_sp_f "$2" "$3" 5)" "$5"
}
_sp_not() {   # LABEL FILE N STATE
  local s; s="$(_sp_state "$2" "$3")"
  if [ -n "$s" ] && [ "$s" != "$4" ]; then ok "$1"; else bad "$1" "#$3 is in state [$s]"; fi
}
# The read-only snapshot: refs, packed refs, HEAD, index, config, FETCH_HEAD,
# the object count, any worktree, and every path and file under a land/ dir.
_sp_snap() {   # REPO LANDDIR
  printf 'refs\n'; git -C "$1" for-each-ref --format='%(objectname) %(refname)' 2>&1
  printf 'packed %s\n' "$(cksum < "$1/.git/packed-refs" 2>/dev/null)"
  printf 'head %s\n' "$(cat "$1/.git/HEAD" 2>&1)"
  printf 'index %s\n' "$(cksum < "$1/.git/index" 2>/dev/null)"
  printf 'config %s\n' "$(cksum < "$1/.git/config" 2>&1)"
  printf 'fetch-head %s\n' "$(cksum < "$1/.git/FETCH_HEAD" 2>/dev/null)"
  git -C "$1" count-objects -v 2>&1 | LC_ALL=C grep -E '^(count|in-pack|packs):'
  printf 'worktrees\n'; ls -a "$1/.git/worktrees" 2>/dev/null
  printf 'land\n'
  if [ -d "$2" ]; then ( cd "$2" && find . -print | LC_ALL=C sort && find . -type f -exec cksum {} + | LC_ALL=C sort ) 2>&1; fi
}
_sp_snapall() { _sp_snap "$SPH" "$SPLAND"; _sp_snap "$SP2" "$SP2LAND"; _sp_snap "$SP3" "$SPM/three/land"; }

# Part 1310's one gh answer: SPLIST, a pull request for each state and reading of spec v2 section 8, and the
# values it names (SPR, SP_LONG, SP_BYTES, _spt). 1320 lists it again. Moved from 1310's lines 9-63, verbatim.
_sp_list() {   # already set, nothing
  [ -n "${SPR:-}" ] && return 0
  _spt="$(printf 'A%.0s' 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30)"
  SP_LONG="$_spt${_spt}BBBBBBBBBB"
  SP_BYTES="$(printf 'notes/caf\303\251.md')"
  SPR="projects/felix/risk.tsv:1"   # a deleted line, so whichever table rule risk.tsv falls under fires
  SPLIST=(
    "$(_sp_pr 150 "$SPR" green labels=FELIX:HOLD)"
    "$(_sp_pr 149 notes/149.md:0 ctxpend)"
    "$(_sp_pr 148 notes/148.md:0 ctxerr)"
    "$(_sp_pr 147 notes/147.md:0 green mergeable=UNKNOWN mss=UNKNOWN)"
    "$(_sp_pr 146 notes/146.md:0 green draft=true mergeable=UNKNOWN mss=BEHIND)"
    "$(_sp_pr 145 notes/145.md:0 red draft=true)"
    "$(_sp_pr 144 "$SP_BYTES:0" green)"
    "$(_sp_pr 143 docs/2026-09-23-roadmap.md:0 green)"
    "$(_sp_pr 142 projects/felix/claude.md:0 green)"
    "$(_sp_pr 141 projects/felix/CLAUDE.md:0 green)"
    "$(_sp_pr 140 notes/140.md:0 green labels=Felix:Founder)"
    "$(_sp_pr 139 notes/139.md:0 green labels=NEEDS-FOUNDER)"
    "$(_sp_pr 138 notes/138.md:0 green branch=shared-b)"
    "$(_sp_pr 137 notes/137.md:0 green branch=shared-b)"
    "$(_sp_pr 136 notes/136.md:0 green draft=true)"
    "$(_sp_pr 135 notes/135.md:0 green)"
    "$(_sp_pr 134 notes/134.md:0 green)"
    "$(_sp_pr 133 notes/133.md:0 green)"
    "$(_sp_pr 132 notes/132.md:0 green)"
    "$(_sp_pr 131 notes/131.md:0 green)"
    "$(_sp_pr 130 notes/130.md:0 green)"
    "$(_sp_pr 129 riskdir/confined/a.md:0 green)"
    "$(_sp_pr 128 riskdir/plain/a.md:0 green)"
    "$(_sp_pr 127 riskdir/wt/a.md:0 green)"
    "$(_sp_pr 125 projects/felix/stack.tsv:0 green)"
    "$(_sp_pr 124 projects/felix/autonomy:0 green)"
    "$(_sp_pr 123 .github/workflows/x.yml:0 green)"
    "$(_sp_pr 122 projects/felix/ecosystem.tsv:0 green)"
    "$(_sp_pr 121 projects/felix/qualification.tsv:1 green)"
    "$(_sp_pr 120 projects/felix/qualification.tsv:0 green)"
    "$(_sp_pr 119 "$SPR engine/harness/felix:0" green)"
    "$(_sp_pr 118 notes/118.md:0 green title='a title\twith a tab')"
    "$(_sp_pr 117 notes/117.md:0 none)"
    "$(_sp_pr 116 notes/116.md:0 green mss=BEHIND)"
    "$(_sp_pr 115 wtonly/x.md:0 green)"
    "$(_sp_pr 114 landdir/x.md:0 green)"
    "$(_sp_pr 113 @100 red)"
    "$(_sp_pr 112 @100 green)"
    "$(_sp_pr 111 engine/harness/felix:0 green)"
    "$(_sp_pr 110 notes/110.md:0 green base=claude/other)"
    "$(_sp_pr 109 "$SPR" green author=someone-else)"
    "$(_sp_pr 108 "$SPR" green cross=true)"
    "$(_sp_pr 107 notes/107.md:0 red labels=Felix:Hold mergeable=CONFLICTING mss=DIRTY)"
    "$(_sp_pr 106 notes/106.md:0 red labels=felix:hold mergeable=CONFLICTING mss=DIRTY)"
    "$(_sp_pr 105 notes/105.md:0 mixed title="$SP_LONG")"
    "$(_sp_pr 104 notes/104.md:0 green mergeable=CONFLICTING mss=DIRTY)"
    "$(_sp_pr 103 "$SPR" running)"
    "$(_sp_pr 102 "$SPR" red)"
    "$(_sp_pr 101 "$SPR" green)"
  )
}

_sp_build() {   # the fixture into $TMP/stuck-pr and its first ledger; already there, nothing
  [ -n "${SPH:-}" ] && [ -d "$SPH/.git" ] && return 0
  SP="$TMP/stuck-pr"; mkdir -p "$SP"; SP="$(cd "$SP" && pwd -P)"
  SPO="$SP/github.com/fixture/home.git"; SPH="$SP/home"
  SP2O="$SP/github.com/fixture/two.git"; SP2="$SP/two"
  SP3O="$SP/github.com/fixture/three.git"; SP3="$SP/three"
  SPM="$SP/mem"; SPU="$SP/user"; SPB="$SP/bin"; SPK="$SP/ctl"; SPL="$SP/log"; SPX="$SP/out"; SPT="$SP/tmp"
  SPLAND="$(FELIX_MEMORY="$SPM" felix_mem_dir felix)/land"; SP2LAND="$(FELIX_MEMORY="$SPM" felix_mem_dir two)/land"
  mkdir -p "$SPO" "$SP2O" "$SP3O" "$SPM" "$SPU/.config/gh" "$SPB" "$SPK" "$SPL" "$SPX" "$SPT" "$SP/norepo" "$SP/cache"

  _sp_put "$SPB/gh" <<'SPSTUB'
#!/bin/bash
SP='@SP@'; K="$SP/ctl"
printf '%s\n' "$*" >> "$SP/log/gh.log"
printf '%s\t%s\t%s\n' "${XDG_STATE_HOME-unset}" "${XDG_CACHE_HOME-unset}" "${GH_CONFIG_DIR-unset}" >> "$SP/log/gh.env"
jqx=""; repo=""; prev=""; bill=0; user=0; me=0; dflt=""
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; -R|--repo) repo="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; --repo=*) repo="${a#--repo=}" ;; esac
  case "$a" in *settings/billing/usage*) bill=1; bq="$a" ;; users/*|/users/*) user=1 ;; user|/user) me=1 ;; esac
  case "$a" in repos/fixture/home|/repos/fixture/home|repos/fixture/two|/repos/fixture/two) dflt="${a#/}" ;; esac
  prev="$a"
done
if [ -z "$repo" ]; then
  u="$(git config --get remote.origin.url 2>/dev/null)"; u="${u%/}"; u="${u%.git}"
  n="${u##*/}"; o="${u%/*}"; o="${o##*/}"; [ -n "$n" ] && [ -n "$o" ] && repo="$o/$n"
fi
repo="${repo#https://}"; repo="${repo#github.com/}"; repo="${repo%.git}"
key="$(printf '%s' "$repo" | LC_ALL=C tr '/' '_')"
out() { if [ -n "$jqx" ] && command -v jq >/dev/null 2>&1; then jq -r "$jqx"; else cat; fi; }
case "${1:-} ${2:-}" in
  "pr list")
    if [ -f "$K/prs.$key.rc" ]; then cat "$K/prs.$key.err" >&2; exit "$(cat "$K/prs.$key.rc")"; fi
    [ -f "$K/prs.$key.json" ] || { printf 'stub: no answer for repository [%s]\n' "$repo" >&2; exit 4; }
    out < "$K/prs.$key.json"; exit 0 ;;
esac
if [ "${1:-}" = api ]; then
  if [ "$bill" = 1 ]; then
    if [ -f "$K/api.rc" ]; then cat "$K/api.err" >&2; exit "$(cat "$K/api.rc")"; fi
    by="${bq##*year=}"; by="${by%%&*}"; bm="${bq##*month=}"; bm="${bm%%&*}"; [ "${#bm}" -eq 1 ] && bm="0$bm"; printf '{"usageItems":[{"date":"%s-%s-01T00:00:00Z","product":"actions","sku":"Actions Linux","quantity":123.0,"unitType":"Minutes","pricePerUnit":0.006,"grossAmount":0.0,"discountAmount":0.0,"netAmount":0.0,"repositoryName":"home"}]}\n' "$by" "$bm" | out; exit 0
  fi
  if [ "$me" = 1 ]; then   # the signed-in account (api user): the whole body, whatever --jq is given
    if [ -f "$K/user.rc" ]; then cat "$K/user.err" >&2; exit "$(cat "$K/user.rc")"; fi
    if [ -f "$K/user.json" ]; then cat "$K/user.json"; else printf '{"login":"fixture","id":1,"type":"User"}\n'; fi
    exit 0
  fi
  if [ "$user" = 1 ]; then printf '{"login":"fixture","id":1,"type":"User"}\n' | out; exit 0; fi
  if [ -n "$dflt" ]; then printf '{"full_name":"%s","default_branch":"main"}\n' "${dflt#repos/}" | out; exit 0; fi
  printf 'gh: Not Found (HTTP 404)\n' >&2; exit 1
fi
printf 'stub: gh %s is not served\n' "$*" >&2
exit 1
SPSTUB
  _sp_put "$SPB/launchctl" <<'SPSTUB'
#!/bin/bash
SP='@SP@'
printf '%s\n' "$*" >> "$SP/log/launchctl.log"
case "${1:-}" in print) [ -f "$SP/ctl/loaded" ] && exit 0; exit 113 ;; esac
exit 0
SPSTUB

  for _spo in "$SPO" "$SP2O" "$SP3O"; do
    _fx_git "$_spo" init -q --bare >/dev/null 2>&1
    _fx_git "$_spo" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
  done
  _fx_git "$SP" clone -q "$SPO" home >/dev/null 2>&1
  _fx_git "$SPH" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
  mkdir -p "$SPH/projects/felix" "$SPH/projects/two" "$SPH/projects/three" "$SPH/projects/loose" \
           "$SPH/engine/harness" "$SPH/notes" "$SPH/landdir" "$SPH/riskdir"
  printf '{\n  "name": "felix",\n  "remote_match": "github.com/fixture/home",\n  "gate": "true"\n}\n' > "$SPH/projects/felix/project.json"
  printf '{\n  "name": "two",\n  "remote_match": "github.com/fixture/two",\n  "gate": "true"\n}\n' > "$SPH/projects/two/project.json"
  printf '{\n  "name": "three",\n  "remote_match": "github.com/fixture/three",\n  "gate": "true"\n}\n' > "$SPH/projects/three/project.json"
  printf '{\n  "name": "loose",\n  "gate": "true"\n}\n' > "$SPH/projects/loose/project.json"
  for _spo in felix two three loose; do printf '# %s\n' "$_spo" > "$SPH/projects/$_spo/CLAUDE.md"; done
  # The land table at origin/main: one founder row. The risk table at origin/main:
  # a path row naming a channel with no confine, and one with a content confine.
  printf 'landdir/.*\tfounder\t-\t-\n' > "$SPH/projects/felix/land.tsv"
  { printf 'red\tpath\t^riskdir/plain/\ta person reads these\treviewed\t-\n'
    printf 'red\tpath\t^riskdir/confined/\tonly some lines matter\treviewed\t^[-+]zz\n'; } > "$SPH/projects/felix/risk.tsv"
  _sp_put "$SPH/engine/harness/felix" <<'SPSTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@SP@/log/trip.log'
exit 0
SPSTUB
  printf 'home\n' > "$SPH/README.md"; printf 'keep\n' > "$SPH/notes/keep.md"
  _sp_commit "$SPH" base
  _fx_git "$SPH" push -q -u origin main >/dev/null 2>&1
  SPOLD="$(git -C "$SPH" rev-parse HEAD 2>/dev/null)"
  printf 'second\n' > "$SPH/notes/second.md"; _sp_commit "$SPH" second
  _fx_git "$SPH" push -q origin main >/dev/null 2>&1
  _fx_git "$SPH" fetch -q origin >/dev/null 2>&1
  _fx_git "$SPH" remote set-head origin main >/dev/null 2>&1
  SPMAIN="$(git -C "$SPH" rev-parse refs/remotes/origin/main 2>/dev/null)"
  # Rows that exist only in the working tree, never at origin/main.
  printf 'wtonly/.*\tfounder\t-\t-\n' >> "$SPH/projects/felix/land.tsv"
  printf 'red\tpath\t^riskdir/wt/\tonly in the working tree\treviewed\t-\n' >> "$SPH/projects/felix/risk.tsv"

  _fx_git "$SP" clone -q "$SP2O" two >/dev/null 2>&1
  _fx_git "$SP2" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
  printf 'two\n' > "$SP2/README.md"; _sp_commit "$SP2" base
  _fx_git "$SP2" push -q -u origin main >/dev/null 2>&1
  _fx_git "$SP2" fetch -q origin >/dev/null 2>&1
  _fx_git "$SP2" remote set-head origin main >/dev/null 2>&1
  _fx_git "$SP" clone -q "$SP3O" three >/dev/null 2>&1
  _fx_git "$SP3" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
  printf 'three\n' > "$SP3/README.md"; _sp_commit "$SP3" base

  SP_UPD="$(_sp_ago 180000)"   # fifty hours ago
  _sp_ledger
}
