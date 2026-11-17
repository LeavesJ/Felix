# tests/lib/inventory-blind.sh: the blind inventory fixture under $IB and its helpers.
# Used by parts 0900 (builds it) 0910 0920 0930 1270 (and 0940 reads it). Moved from
# parts/0900-felix-inventory-the-settled-contract-of-2026.sh: the helpers from lines 85-194 (unchanged), the fixture from lines
# 29-84, 196-272, 274-351 and 353-496 into _ib_fixture, and the variables it only names
# (lines 28, 33, 34, 201, 273, 352, and the prompts of parts/0910 lines 117-131) into _ib_build,
# which sets them first. _ib_build [r|h|n16] adds states of the serial run: r the records and
# runs RUN1 to RUN4 that 0910 makes, h the host repository 0920 reads and the runs of r, n16
# every run that 0930 lists in N16 (in inventory-blind-runs.sh). Definitions only. Each step does
# nothing when it is done, so in the serial run only the first call to reach a step makes it.

# ---- the fixture's git, commits and records ------------------------------
_ibg() { HOME="$IB/fxhome" XDG_CONFIG_HOME="$IB/fxhome/.config" GIT_CONFIG_NOSYSTEM=1 \
         GIT_AUTHOR_NAME=Fixture GIT_AUTHOR_EMAIL=fixture@example.invalid \
         GIT_COMMITTER_NAME=Fixture GIT_COMMITTER_EMAIL=fixture@example.invalid \
         "$IB_GIT" -c init.defaultBranch=main -c advice.detachedHead=false "$@"; }
_ibq() { _ibg --no-optional-locks "$@"; }
_ibi() { GIT_INDEX_FILE="$IB/fx.idx" HOME="$IB/fxhome" XDG_CONFIG_HOME="$IB/fxhome/.config" GIT_CONFIG_NOSYSTEM=1 "$IB_GIT" "$@"; }
_ibago() { printf '%s' $(( $(date +%s) - $1 * 60 )); }
# _inventory_blind_vars: the variables this file's functions read, set when the prelude calls it
# (contract C2: a lib file defines functions and nothing else).
_inventory_blind_vars() {
IBC=""
IB_F=""; IB_SID=""; IB_BR=""; IB_TSF=""
}
_ibmk() {  # MIN|- repo parent|- message [path content|-]...  -> IBC, a commit no checkout holds
  local d="$1" r="$2" par="$3" msg="$4" blob tree; shift 4
  rm -f "$IB/fx.idx"
  if [ "$par" = - ]; then _ibi -C "$r" read-tree --empty; else _ibi -C "$r" read-tree "$par"; fi
  while [ $# -ge 2 ]; do
    if [ "$2" = - ]; then _ibi -C "$r" update-index --force-remove "$1"
    else blob="$(printf '%s\n' "$2" | _ibg -C "$r" hash-object -w --stdin)"
         _ibi -C "$r" update-index --add --cacheinfo "100644,$blob,$1"; fi
    shift 2
  done
  tree="$(_ibi -C "$r" write-tree)"
  IBC="$( if [ "$d" != - ]; then GIT_AUTHOR_DATE="$(_ibago "$d") +0000"; GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE"
                                 export GIT_AUTHOR_DATE GIT_COMMITTER_DATE; fi
          if [ "$par" = - ]; then _ibg -C "$r" commit-tree "$tree" -m "$msg"
          else _ibg -C "$r" commit-tree "$tree" -p "$par" -m "$msg"; fi )"
}
_ibci() { _ibg -C "$1" add -A && _ibg -C "$1" commit -q -m "$2"; }
_ibnew() {  # NAME [path content]...: $IB/NAME-origin.git holding main, and $IB/NAME cloned from it
  local n="$1"; shift
  _ibg init -q --bare "$IB/$n-origin.git"
  _ibmk - "$IB/$n-origin.git" - "the first $n" README.md "$n" "$@"
  _ibg -C "$IB/$n-origin.git" update-ref refs/heads/main "$IBC"
  _ibg clone -q "$IB/$n-origin.git" "$IB/$n"
}
_ibmainwt() { _ibq -C "$1" worktree list --porcelain | LC_ALL=C awk 'NR == 1 { sub(/^worktree /, ""); print }'; }
_ibenc() { printf '%s' "$1" | LC_ALL=C sed 's/[^A-Za-z0-9]/-/g'; }
_ibts() { local e; e="$(_ibago "$1")"
          date -u -r "$e" '+%Y-%m-%dT%H:%M:%S.000Z' 2>/dev/null || date -u -d "@$e" '+%Y-%m-%dT%H:%M:%S.000Z'; }
_ibage() { local e; e="$(_ibago "$2")"
           touch -t "$(date -r "$e" '+%Y%m%d%H%M.%S' 2>/dev/null || date -d "@$e" '+%Y%m%d%H%M.%S')" "$1"; }
# A session file: _ibsess DIR SID files it where Claude Code files DIR's
# sessions; _ibopen FILE SID opens any path. IB_BR, when set, is the
# gitBranch every record carries; IB_SID is the sessionId.
_ibopen() { IB_F="$1"; IB_SID="$2"; mkdir -p "${1%/*}"; : > "$1"; }
_ibsess() { _ibopen "$IBP/$(_ibenc "$1")/$2.jsonl" "$2"; }
_ib_tsf() { if [ "$1" = none ]; then IB_TSF=""; else IB_TSF=",\"timestamp\":\"$(_ibts "$1")\""; fi; }
_ib_raw() { printf '%s\n' "$1" >> "$IB_F"; }
_ib_u() {  # MIN|none content-json [fields after the message]
  local g="" l; [ -n "$IB_BR" ] && g=",\"gitBranch\":\"$IB_BR\""; _ib_tsf "$1"
  printf -v l '{"parentUuid":"p","isSidechain":false,"userType":"external","sessionId":"%s","version":"2.1.286"%s,"type":"user","message":{"role":"user","content":%s}%s,"uuid":"u-%s"%s}' \
    "$IB_SID" "$g" "$2" "${3:-}" "$RANDOM" "$IB_TSF"
  printf '%s\n' "$l" >> "$IB_F"; }
_ib_ax() {  # MIN|none content-items-json stop-reason [isSidechain]
  local g="" l; [ -n "$IB_BR" ] && g=",\"gitBranch\":\"$IB_BR\""; _ib_tsf "$1"
  printf -v l '{"parentUuid":"p","isSidechain":%s,"userType":"external","sessionId":"%s","version":"2.1.286"%s,"message":{"model":"claude-test","id":"msg_%s","type":"message","role":"assistant","content":[%s],"stop_reason":"%s","stop_sequence":null,"usage":{"input_tokens":1,"output_tokens":1}},"requestId":"req_%s","type":"assistant","uuid":"a-%s"%s}' \
    "${4:-false}" "$IB_SID" "$g" "$RANDOM" "$2" "$3" "$RANDOM" "$RANDOM" "$IB_TSF"
  printf '%s\n' "$l" >> "$IB_F"; }
_ib_h()  { _ib_u "$1" "\"$2\""; }
_ib_a()  { local b; printf -v b '{"type":"text","text":"%s"}' "$2"; _ib_ax "$1" "$b" end_turn "${3:-false}"; }
_ib_tu() { local b; printf -v b '{"type":"tool_use","id":"%s","name":"%s","input":%s}' "$2" "$3" "$4"; _ib_ax "$1" "$b" tool_use; }
_ib_tr() { local b; printf -v b '[{"tool_use_id":"%s","type":"tool_result","content":"%s"}]' "$2" "$3"; _ib_u "$1" "$b"; }
_ib_chip() {  # MIN tool-id task-id title prompt: a spawn_task call and the result naming its task
  local i; printf -v i '{"title":"%s","prompt":"%s","tldr":"Noticed in passing."}' "$4" "$5"
  _ib_tu "$1" "$2" mcp__ccd_session__spawn_task "$i"
  _ib_tr "$1" "$2" "Noted (position 1, task_id: $3). A chip is showing for the user."; }
# A prompt of exactly N characters, from a seed sentence.
_ibp() { local s="$1 $1 $1 $1 $1"; printf '%s' "${s:0:$2}"; }

# ---- the runner and the row readers --------------------------------------
# _ibrun NAME [--home H] [--path P] [--cwd D] [--env V=X]... -- felix-args:
# from $IB/cwd, with nothing of Felix's or git's own in the environment, HOME
# the scratch home, TMPDIR $IB/tmp and the temporary roots $IB/temproot only
# (the suite's own TMP sits under the real ones). Output in $IB/runs/NAME.*.
_ibrun() {
  local n="$1" h="$IB/home" p="$IB/stub:$PATH" d="$IB/cwd" e=(); shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --home) h="$2"; shift 2 ;; --path) p="$2"; shift 2 ;; --cwd) d="$2"; shift 2 ;;
      --env) e[${#e[@]}]="$2"; shift 2 ;; --) shift; break ;; *) break ;;
    esac
  done
  ( cd "$d" || exit 97
    unset FELIX_HOME FELIX_MEMORY FELIX_KERNEL FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE CLAUDE_PLUGIN_ROOT CLAUDE_CONFIG_DIR \
          GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_OPTIONAL_LOCKS \
          XDG_STATE_HOME XDG_CACHE_HOME
    export HOME="$h" TMPDIR="$IB/tmp" FELIX_INVENTORY_TEMP_ROOTS="$IB/temproot" PATH="$p" XDG_CONFIG_HOME="$h/.config" \
           GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 GIT_CEILING_DIRECTORIES="$IB"
    for _ibv in ${e[@]+"${e[@]}"}; do export "$_ibv"; done
    "$IBF" "$@" ) > "$IB/runs/$n.out" 2> "$IB/runs/$n.err"
  printf '%s' "$?" > "$IB/runs/$n.rc"
}
_ibo()  { printf '%s' "$IB/runs/$1.out"; }
_ibrc() { cat "$IB/runs/$1.rc" 2>/dev/null; }
# _ibrow RUN KIND REF [REPO]: that --tsv line; _ibcol ... N: its column N, or
# "no row"; _ibst: its states; _ibholds RUN KIND REF STATE: yes, no or no row.
_ibrow() { LC_ALL=C awk -F'\t' -v k="$2" -v r="$3" -v p="${4:-}" '$1 == k && $3 == r && (p == "" || $2 == p) { print; exit }' "$(_ibo "$1")"; }
_ibcol() { local l; l="$(_ibrow "$1" "$2" "$3" "${5:-}")"
           if [ -z "$l" ]; then printf 'no row'; else printf '%s\n' "$l" | LC_ALL=C awk -F'\t' -v n="$4" '{ printf "%s", $n }'; fi; }
_ibst()  { _ibcol "$1" "$2" "$3" 4 "${4:-}"; }
_ibholds() { local s; s="$(_ibst "$1" "$2" "$3" "${5:-}")"
             if [ "$s" = "no row" ]; then printf 'no row'; else case ",$s," in *",$4,"*) printf yes ;; *) printf no ;; esac; fi; }
# Several states at once: "S1=yes S2=no ...", each as _ibholds answers.
_ibmany() { local r="$1" k="$2" f="$3" s o=""; shift 3
            for s in "$@"; do o="$o${o:+ }$s=$(_ibholds "$r" "$k" "$f" "$s")"; done; printf '%s' "$o"; }
_ibcount() { LC_ALL=C awk -F'\t' -v k="$2" -v p="${3:-}" '$1 == k && (p == "" || $2 == p) { n++ } END { print n + 0 }' "$(_ibo "$1")"; }
# The element of a detail that starts with PREFIX (elements are joined by "; ").
_ibelem() { _ibcol "$1" "$2" "$3" 8 | LC_ALL=C awk -v p="$4" '{ n = split($0, e, "; "); for (i = 1; i <= n; i++) if (index(e[i], p) == 1) { print e[i]; exit } }'; }
_ibhaselem() { [ -n "$(_ibrow "$1" "$2" "$3")" ] || { printf 'no row'; return; }
               _ibcol "$1" "$2" "$3" 8 | LC_ALL=C awk -v w="$4" '{ n = split($0, e, "; "); for (i = 1; i <= n; i++) if (e[i] == w) f = 1 } END { print (f ? "yes" : "no") }'; }
_ibsnap() { ( cd "$1" && find . -print | LC_ALL=C sort && find . -type f -exec cksum {} + | LC_ALL=C sort ) 2>&1; }

# _ib_build [r|h|n16]: IB and the variables of the fixture, then the fixture and the state asked for.
_ib_build() {
IB="$TMP/inventory-blind"; mkdir -p "$IB"; IB="$(cd "$IB" && pwd -P)"
IBF="$IB/clone/felix/engine/harness/felix"; IBP="$IB/home/.claude/projects"; IB_GIT="$(command -v git)"
IBL="$REAL_HARNESS/lib"
IBO="$IB/origin.git"; IBR="$IB/r"
IB_TAB="$IB/wts/t$(printf '\t')ab"
IB_NPR=22
# ---- r's records: chips, PR owners, and sessions elsewhere ---------------
IB_P95="$(_ibp 'Theta task: point the README badge at the current build, and test that it fails on a branch that is gone.' 130)"
IB_P18="$(_ibp 'Iota task: give the exporter a stable row order and test two runs over one input for the same bytes.' 130)"
IB_P96="$(_ibp 'Kappa task: retire the old config loader alias once one release has carried the new name.' 130)"
IB_P97="$(_ibp 'Lambda task: make the scheduler print the jobs it would start in a dry run and start none.' 130)"
IB_P99="$(_ibp 'Mu task: teach the report to name the file each total came from, with a test on two files.' 130)"
IB_P100="$(_ibp 'Nu task: move the retry budget into the settings file and keep the default at three.' 130)"
IB_PT119="$(_ibp 'Xi task: make the sorter stable and test equal keys on two inputs.' 130)"
IB_PT120="$(_ibp 'Omicron task: log each retry once and test the count it reports.' 130)"
# Two prompts of 130 decoded characters with two \n escapes in their first 50,
# so the JSON is two bytes longer than the text before character 120.
IB_P115A="Kappa line\\nLambda line\\n$(_ibp 'mu nu xi omicron pi rho sigma tau upsilon phi chi psi omega' 107)"
IB_P115B="Delta line\\nSigma lines\\n$(_ibp 'alpha beta gamma delta epsilon zeta eta theta iota kappa' 107)"
IB_NEAR="${IB_P115A:0:121}#${IB_P115A:122}"              # decoded character 120 changed
IB_HIT="${IB_P115B:0:122} and then something else entirely"  # the first 120 decoded, then other text
_ib_fixture
case "${1:-}" in r|h|n16) _ib_r_runs ;; esac
case "${1:-}" in h|n16) _ib_h_build ;; esac
case "${1:-}" in n16) _ib_n16 ;; esac
}

# _ib_fixture: the repositories, stand-ins and gh answers of the settled contract. The guard is
# the last file made.
_ib_fixture() {
  [ -e "$IB/d/new.txt" ] && return 0
mkdir -p "$IB/home/.claude/projects" "$IB/home0/.claude/projects" "$IB/homenone" "$IB/fxhome" "$IB/tmp" \
         "$IB/cwd" "$IB/stub" "$IB/stubng" "$IB/spy" "$IB/old" "$IB/gh/default" "$IB/mem" "$IB/temproot" \
         "$IB/runs" "$IB/ccd/projects" "$IB/plain" "$IB/clone/felix/engine"
_copy_content "$REAL_HARNESS" "$IB/clone/felix/engine/harness"
printf '[]\n' > "$IB/gh/default/all.json"; printf '[]\n' > "$IB/gh/default/open.json"
printf '0\n' > "$IB/gh/rc"; : > "$IB/gh/err"

# ---- stand-ins -----------------------------------------------------------
# gh logs PWD|ARGS|GH_NO_UPDATE_NOTIFIER|GH_PROMPT_DISABLED|XDG_STATE_HOME|
# XDG_CACHE_HOME and answers the --state all or --state open listing of the
# repository -R names (else of the directory it runs in) from $IB/gh/<key>/.
# $IB/gh/rc and err make it fail, fail-open fails the second call only, and
# slow makes it write its PID and wait, at most 30 s, until $IB/gh/release
# exists, and then exit 0 with no output as `sleep 30` did. A test that sends
# the run a signal while gh waits releases it after the send (_ibsig, part
# 0920): bash runs a trap only when its foreground child ends, so the run
# would otherwise sit out the whole 30 s before it could act on the signal.
cat > "$IB/stub/gh" <<IBGHEOF
#!/bin/sh
D='$IB/gh'
printf '%s|%s|%s|%s|%s|%s\n' "\$PWD" "\$*" "\${GH_NO_UPDATE_NOTIFIER-}" "\${GH_PROMPT_DISABLED-}" "\${XDG_STATE_HOME-}" "\${XDG_CACHE_HOME-}" >> '$IB/gh.log'
r=""; p=""
for a in "\$@"; do [ "\$p" = -R ] && r="\$a"; p="\$a"; done
if [ -n "\$r" ]; then k="\$(printf '%s' "\$r" | tr '/' '_')"; else k="pwd_\${PWD##*/}"; fi
[ -d "\$D/\$k" ] || k=default
if [ -f "\$D/slow" ]; then
  printf '%s\n' "\$\$" > '$IB/gh.pid'; i=0
  while [ ! -e "\$D/release" ] && [ "\$i" -lt 300 ]; do sleep 0.1; i=\$((i + 1)); done
  exit 0
fi
s=all; case " \$* " in *" --state open "*) s=open ;; esac
if [ "\$s" = open ] && [ -f "\$D/fail-open" ]; then echo 'gh: the open listing failed' >&2; exit 1; fi
rc="\$(cat "\$D/rc")"
if [ "\$rc" != 0 ]; then cat "\$D/err" >&2; exit "\$rc"; fi
cat "\$D/\$k/\$s.json"
IBGHEOF
for _ibn in curl wget ssh nc; do
  printf '#!/bin/sh\nprintf "%%s\\n" %s >> "%s/net.log"\nexit 0\n' "$_ibn" "$IB" > "$IB/stub/$_ibn"
  cp "$IB/stub/$_ibn" "$IB/stubng/$_ibn"
done
# The git spy logs GIT_NO_LAZY_FETCH=<v>|<args>; the old git says 2.43.0.
cat > "$IB/spy/git" <<IBSPYEOF
#!/bin/sh
printf 'GIT_NO_LAZY_FETCH=%s|%s\n' "\${GIT_NO_LAZY_FETCH-}" "\$*" >> '$IB/git.log'
exec '$IB_GIT' "\$@"
IBSPYEOF
cat > "$IB/old/git" <<IBOLDEOF
#!/bin/sh
for a in "\$@"; do case "\$a" in --version|version) echo 'git version 2.43.0'; exit 0 ;; esac; done
exec '$IB_GIT' "\$@"
IBOLDEOF
printf '#!/bin/sh\n: > "%s/gpg-ran"\nexit 1\n' "$IB" > "$IB/gpgstub"
chmod +x "$IB/stub/"* "$IB/stubng/"* "$IB/spy/git" "$IB/old/git" "$IB/gpgstub"

# ---- r: the widget, where most items live --------------------------------
# main: M0 (100 hours old) holds every file the branches change; M1 (30h20m)
# adds two pending handoff sections; M2 (29h) changes a.txt; then, after the
# branches are cut from M2, main takes the squashes, the deletion, the merged
# and reverted change and the later edits the content rules are tested on.
_ibg init -q --bare "$IBO"
_ibmk 6000 "$IBO" - 'the first widget' a.txt a0 b.txt b0 .gitignore '*.log' sq-a.txt s0 sq-b.txt s0 \
  half-a.txt h0 half-b.txt h0 none.txt n0 del.txt d0 rv.txt r0 late.txt l0 rev.txt e0 sqp.txt p0 \
  docs/handoff/pending/notes.txt 'notes, no section'; IB_M0="$IBC"
_ibmk 1820 "$IBO" "$IB_M0" 'two pending sections' \
  docs/handoff/pending/h1.md "$(printf '### a section\n\nWhat was done.\n\n## Next\n- one\n- two')" \
  docs/handoff/pending/h3.md "$(printf '### another section\n\nOnly prose here, and nothing after it.')"; IB_M1="$IBC"
_ibmk 1740 "$IBO" "$IB_M1" 'a.txt moves on' a.txt a1; IB_M2="$IBC"
_ibg -C "$IBO" update-ref refs/heads/main "$IB_M2"
_ibg clone -q "$IBO" "$IBR"
_ibb()    { _ibg -C "$IBR" branch -q -f "$1" "$2"; }
_ibpush() { _ibg -C "$IBR" push -q origin "$2:refs/heads/$1"; }
_ibmk 3040 "$IBR" "$IB_M2" 'aged work' aged.txt 'aged, nowhere else'; _ibb aged "$IBC"
_ibmk - "$IBR" "$IB_M2" 'same' cov-same.txt same; _ibb cov-same "$IBC"; _ibpush cov-same "$IBC"
_ibmk - "$IBR" "$IB_M2" 'ahead one' cov-ahead.txt one; _ibpush cov-ahead "$IBC"
_ibmk - "$IBR" "$IBC" 'ahead two' cov-ahead.txt two; _ibb cov-ahead "$IBC"
_ibmk - "$IBR" "$IB_M2" 'behind one' cov-behind.txt one; _ibb cov-behind "$IBC"
_ibmk - "$IBR" "$IBC" 'behind two' cov-behind.txt two; _ibpush cov-behind "$IBC"
_ibmk - "$IBR" "$IB_M2" 'theirs' theirs.txt theirs; _ibpush theirs "$IBC"; _ibb mine "$IBC"; IB_T1="$IBC"
_ibg -C "$IBR" config branch.mine.remote origin; _ibg -C "$IBR" config branch.mine.merge refs/heads/theirs
_ibmk - "$IBR" "$IB_M2" 'tracker' tracker.txt tracker; _ibb tracker "$IBC"
_ibg -C "$IBR" config branch.tracker.remote origin; _ibg -C "$IBR" config branch.tracker.merge refs/heads/main
_ibmk - "$IBR" "$IB_M2" 'pr only' pr-only.txt 'pr only'; _ibpush pr-only "$IBC"; IB_PO="$IBC"
_ibmk - "$IBR" "$IB_M2" 'stale pr' stale.txt stale; _ibpush stale-pr "$IBC"; IB_SP="$IBC"
_ibmk - "$IBR" "$IB_M2" 'nobody' nobody.txt nobody; _ibpush nobody "$IBC"; IB_NB="$IBC"
_ibmk - "$IBR" "$IB_M2" 'forked' forked.txt forked; _ibb forked "$IBC"; IB_FK="$IBC"
_ibmk - "$IBR" "$IB_M2" 'fork two' fk2.txt fk2; _ibb fk2 "$IBC"; _ibpush fk2 "$IBC"; IB_FK2="$IBC"
_ibmk - "$IBR" "$IB_M2" 'sq one' sq-a.txt s2; _ibmk - "$IBR" "$IBC" 'sq two' sq-b.txt s2; _ibb sq "$IBC"
_ibmk - "$IBR" "$IB_M2" 'half' half-a.txt h1 half-b.txt 'half, nowhere else'; _ibb half "$IBC"
_ibmk - "$IBR" "$IB_M2" 'none' none.txt 'none, nowhere else'; _ibb none "$IBC"
_ibmk - "$IBR" "$IB_M2" 'del' del.txt -; _ibb del "$IBC"
_ibmk - "$IBR" "$IB_M2" 'rv' rv.txt r1; _ibb rv "$IBC"; _ibpush rv "$IBC"; IB_RV="$IBC"
_ibmk - "$IBR" "$IB_M2" 'own a' own-a.txt oa; _ibpush own-a "$IBC"; IB_OA="$IBC"
_ibmk - "$IBR" "$IB_M2" 'own b' own-b.txt ob; _ibpush own-b "$IBC"; IB_OB="$IBC"
_ibmk - "$IBR" "$IB_M2" 'own c' own-c.txt oc; _ibpush own-c "$IBC"; IB_OC="$IBC"
_ibmk - "$IBR" "$IB_M2" 'rv2 one' rv2.txt q1; _ibb rv2 "$IBC"
_ibmk - "$IBR" "$IBC" 'rv2 two' rv2.txt q2; _ibpush rv2 "$IBC"; IB_Q2="$IBC"
_ibmk - "$IBR" "$IB_M2" 'local one' lo.txt 1; _ibmk - "$IBR" "$IBC" 'local two' lo.txt 2; _ibb local-only "$IBC"
_ibmk - "$IBR" "$IB_M2" 'pushed' pushed.txt pushed; _ibb pushed "$IBC"; _ibpush pushed "$IBC"
_ibmk - "$IBR" "$IB_M2" 'np' np.txt np; _ibb np "$IBC"; _ibpush np "$IBC"
_ibmk - "$IBR" "$IB_M2" 'late one' late.txt l1; IB_L1="$IBC"; _ibpush late "$IBC"
_ibmk - "$IBR" "$IB_L1" 'late two' late.txt l2; _ibmk - "$IBR" "$IBC" 'late three' late.txt l3; _ibb late "$IBC"; _ibpush late "$IBC"
_ibmk - "$IBR" "$IB_M2" 'cl' cl.txt cl; _ibb cl "$IBC"; _ibpush cl "$IBC"; IB_CL="$IBC"
_ibmk - "$IBR" "$IB_M2" 'rev one' rev.txt e1; IB_RE1="$IBC"
_ibmk - "$IBR" "$IB_RE1" 'rev two' rev.txt e2; _ibb rev "$IBC"; _ibpush rev "$IBC"
for _ibn in flag f41 f42 f43 f44; do _ibmk - "$IBR" "$IB_M2" "$_ibn" "$_ibn.txt" "$_ibn"; _ibb "$_ibn" "$IBC"; _ibpush "$_ibn" "$IBC"; done
_ibmk - "$IBR" "$IB_M2" 'sqp' sqp.txt p1; _ibb sqp "$IBC"; _ibpush sqp "$IBC"; IB_SQP="$IBC"
_ibmk - "$IBR" "$IB_M2" 'dup, once' dup.txt 'the same change'; _ibb dupA "$IBC"
_ibmk - "$IBR" "$IB_M2" 'dup, twice' dup.txt 'the same change'; _ibb dupB "$IBC"
_ibmk - "$IBR" "$IB_M2" 'dif a' dif.txt 'dif a'; _ibb difA "$IBC"
_ibmk - "$IBR" "$IB_M2" 'dif b' dif.txt 'dif b'; _ibb difB "$IBC"
_ibb merged "$IB_M1"
_ibmk - "$IBR" "$IB_M0" 'worse' a.txt a1 b.txt 'worse, nowhere else'; _ibb worse "$IBC"
_ibmk - "$IBR" "$IB_M0" 'partly' a.txt a1 b.txt 'partly, nowhere else'; _ibb partlywt "$IBC"
_ibmk - "$IBR" "$IB_M2" 'shared' sh.txt shared; _ibb shared "$IBC"
# main moves on: sq squashed, half of half, del deleted, rv squashed then
# reverted, late's first head and rev's squashed, sqp squashed then edited.
_ibmk - "$IBR" "$IB_M2" 'sq, squashed' sq-a.txt s2 sq-b.txt s2
_ibmk - "$IBR" "$IBC" 'half of half' half-a.txt h1
_ibmk - "$IBR" "$IBC" 'del, on main too' del.txt -
_ibmk - "$IBR" "$IBC" 'rv, squashed (#20)' rv.txt r1
_ibmk - "$IBR" "$IBC" 'rv, reverted' rv.txt r0
_ibmk - "$IBR" "$IBC" 'late, squashed (#22)' late.txt l1
_ibmk - "$IBR" "$IBC" 'rev, squashed (#33)' rev.txt e1
_ibmk - "$IBR" "$IBC" 'sqp, squashed (#50)' sqp.txt p1
_ibmk - "$IBR" "$IBC" 'sqp, edited on main since' sqp.txt p2; IB_MT="$IBC"
_ibpush main "$IB_MT"
_ibg -C "$IBR" fetch -q origin
_ibg -C "$IBR" reset -q --hard origin/main
# Worktrees: beside the clone in wts/, and one nested inside it.
mkdir -p "$IB/wts"
_ibwt() { _ibg -C "$IBR" worktree add -q "$@"; }
_ibwt -b tabbed "$IB_TAB" "$IB_MT"
_ibwt -b gone "$IB/wts/gone" "$IB_MT"; rm -rf "$IB/wts/gone"
_ibwt "$IB/wts/s1" shared; _ibwt -f "$IB/wts/s2" shared
_ibwt -b sr "$IB/wts/sr" "$IB_MT"
printf '1\n' > "$IB/wts/sr/sr.txt"; _ibci "$IB/wts/sr" 'sr, A'; IB_SRA="$(_ibq -C "$IB/wts/sr" rev-parse HEAD)"
printf '2\n' > "$IB/wts/sr/sr.txt"; _ibci "$IB/wts/sr" 'sr, B'
_ibg -C "$IB/wts/sr" read-tree "$IB_SRA"
_ibwt -b soft "$IB/wts/soft" "$IB_MT"
printf '1\n' > "$IB/wts/soft/soft.txt"; _ibci "$IB/wts/soft" 'soft, A'; IB_SOA="$(_ibq -C "$IB/wts/soft" rev-parse HEAD)"
printf '2\n' > "$IB/wts/soft/soft.txt"; _ibci "$IB/wts/soft" 'soft, B'
_ibg -C "$IB/wts/soft" reset -q --soft "$IB_SOA"
_ibg -C "$IBR" -c core.logAllRefUpdates=false worktree add -q -b norl "$IB/wts/norl" "$IB_MT"
printf 'norl\n' > "$IB/wts/norl/norl.txt"
_ibg -C "$IB/wts/norl" -c core.logAllRefUpdates=false add -A
_ibg -C "$IB/wts/norl" -c core.logAllRefUpdates=false commit -q -m 'norl'
printf 'staged, nowhere else\n' > "$IB/wts/norl/norl2.txt"; _ibg -C "$IB/wts/norl" add norl2.txt
rm -rf "$IBR/.git/worktrees/norl/logs" "$IBR/.git/logs/refs/heads/norl"
_ibwt -b wbehind "$IB/wts/behind" "$IB_M1"; printf 'a1\n' > "$IB/wts/behind/a.txt"
_ibwt -b nest "$IBR/.claude/worktrees/nest" "$IB_MT"; printf 'nest, nowhere else\n' > "$IBR/.claude/worktrees/nest/new.txt"
_ibwt -b hollow "$IB/wts/hollow" "$IB_MT"; rm -rf "$IB/wts/hollow"; mkdir "$IB/wts/hollow"
printf 'hollow, nowhere else\n' > "$IB/wts/hollow/f.txt"
_ibwt -b swap "$IB/wts/swap" "$IB_MT"; rm -rf "$IB/wts/swap"; _ibg init -q "$IB/wts/swap"
printf 'swap\n' > "$IB/wts/swap/s.txt"; _ibci "$IB/wts/swap" 'an unrelated repository'
_ibwt -b ign "$IB/wts/ign" "$IB_MT"; printf 'ignored, nowhere else\n' > "$IB/wts/ign/run.log"
_ibwt "$IB/wts/worse" worse; printf 'c, nowhere else\n' > "$IB/wts/worse/c-new.txt"
_ibwt "$IB/wts/partly" partlywt
_ibwt -b lostr "$IB/wts/lostr" "$IB_MT"; rm -rf "$IBR/.git/worktrees/lostr"
# An .md file in pending/ that only the working tree holds, ignored so the
# main worktree stays clean.
printf 'not on main\n' > "$IBR/docs/handoff/pending/h2.md"
printf 'docs/handoff/pending/h2.md\n' >> "$IBR/.git/info/exclude"
_ibg -C "$IBR" remote set-url origin git@github.com:acme/widget.git
IBRR="$(_ibmainwt "$IBR")"
# r2: a second clone of the same origin, fetched 5h10m ago.
_ibg clone -q "$IBO" "$IB/r2"; _ibg -C "$IB/r2" fetch -q origin; _ibage "$IB/r2/.git/FETCH_HEAD" 310
_ibg -C "$IB/r2" remote set-url origin https://github.com/acme/other.git
IBR2="$(_ibmainwt "$IB/r2")"

# ---- r: what GitHub says -------------------------------------------------
# The first call's fields and the second's, keys in gh's sorted order. The
# first carries baseRefName (spec section 7, ruled 2026-10-02: section 4.3 rule 2
# counts a merged PR only into the default branch).
IB_ALL=""; IB_OPEN=""
_ibpra() {  # number state head oid updated-min cross [base, else main]
  local l; printf -v l '{"baseRefName":"%s","headRefName":"%s","headRefOid":"%s","isCrossRepository":%s,"number":%s,"state":"%s","updatedAt":"%s"}' \
    "${7:-main}" "$3" "$4" "$6" "$1" "$2" "$(_ibts "$5")"; IB_ALL="$IB_ALL${IB_ALL:+,}$l"; }
_ibpro() {  # number labels-json mergeable isDraft rollup-json
  local l; printf -v l '{"isDraft":%s,"labels":[%s],"mergeable":"%s","number":%s,"statusCheckRollup":[%s]}' \
    "$4" "$2" "$3" "$1" "$5"; IB_OPEN="$IB_OPEN${IB_OPEN:+,}$l"; }
_iblab() { printf '{"color":"ededed","description":"","id":"LA_%s","name":"%s"}' "$1" "$1"; }
_ibsha() { _ibq -C "$IBR" rev-parse "refs/heads/$1"; }
printf -v IB_SC_OK '{"__typename":"StatusContext","context":"felix/ready","startedAt":"%s","state":"SUCCESS","targetUrl":""}' "$(_ibts 100)"
printf -v IB_CR_OK '{"__typename":"CheckRun","completedAt":"%s","conclusion":"SUCCESS","detailsUrl":"","name":"felix/ready","startedAt":"%s","status":"COMPLETED","workflowName":"ci"}' "$(_ibts 100)" "$(_ibts 101)"
printf -v IB_SC_PEND '{"__typename":"StatusContext","context":"felix/ready","startedAt":"%s","state":"PENDING","targetUrl":""}' "$(_ibts 100)"
printf -v IB_SC_ISH '{"__typename":"StatusContext","context":"felix/ready-ish","startedAt":"%s","state":"SUCCESS","targetUrl":""}' "$(_ibts 100)"
_ibpra 12 OPEN   pr-only    "$IB_PO"             180 false
_ibpra 13 OPEN   theirs     "$IB_T1"             240 false
_ibpra 15 OPEN   stale-pr   "$IB_SP"             360 false
_ibpra 16 OPEN   forked     "$IB_FK"             120 true
_ibpra 17 OPEN   nobody     "$IB_NB"             420 false
_ibpra 18 CLOSED fk2        "$IB_FK2"            1800 true
_ibpra 20 MERGED rv         "$IB_RV"             1200 false
_ibpra 21 MERGED rv2        "$IB_Q2"             1200 false
_ibpra 22 MERGED late       "$IB_L1"             1500 false
_ibpra 30 CLOSED cl         "$IB_CL"             2400 false
_ibpra 31 CLOSED cl         "$IB_CL"             1800 false
_ibpra 32 CLOSED rev        "$IB_RE1"            2400 false
_ibpra 33 MERGED rev        "$IB_RE1"            1800 false
_ibpra 40 OPEN   flag       "$(_ibsha flag)"     310 false
_ibpra 41 OPEN   f41        "$(_ibsha f41)"      130 false
_ibpra 42 OPEN   f42        "$(_ibsha f42)"      130 false
_ibpra 43 OPEN   f43        "$(_ibsha f43)"      130 false
_ibpra 44 OPEN   f44        "$(_ibsha f44)"      130 false
_ibpra 50 MERGED sqp        "$IB_SQP"            600 false
_ibpra 60 OPEN   own-a      "$IB_OA"             300 false
_ibpra 61 OPEN   own-b      "$IB_OB"             300 false
_ibpra 62 OPEN   own-c      "$IB_OC"             300 false
_ibpro 12 '' MERGEABLE false ''
_ibpro 13 '' MERGEABLE false ''
_ibpro 15 '' MERGEABLE false ''
_ibpro 16 '' MERGEABLE false ''
_ibpro 17 '' MERGEABLE false ''
_ibpro 40 "$(_iblab felix:hold),$(_iblab needs-founder)" CONFLICTING true "$IB_SC_OK"
_ibpro 41 '' MERGEABLE false "$IB_CR_OK"
_ibpro 42 '' MERGEABLE false "$IB_SC_PEND"
_ibpro 43 '' MERGEABLE false "$IB_SC_ISH"
_ibpro 44 "$(_iblab felix:founder)" MERGEABLE false ''
_ibpro 60 '' MERGEABLE false ''
_ibpro 61 '' MERGEABLE false ''
_ibpro 62 '' MERGEABLE false ''
mkdir -p "$IB/gh/acme_widget"
printf '[%s]\n' "$IB_ALL" > "$IB/gh/acme_widget/all.json"; printf '[%s]\n' "$IB_OPEN" > "$IB/gh/acme_widget/open.json"

# ---- small repositories --------------------------------------------------
# noorigin and unborn have no remote; fb1 lost origin/HEAD; fb2's origin has
# only master and it has no fetch time; bwt is a bare clone's worktree;
# shallow and partial are clones that lack history or blobs.
_ibg init -q "$IB/noorigin"; printf 'n\n' > "$IB/noorigin/n.txt"; _ibci "$IB/noorigin" 'no origin'
_ibmk - "$IB/noorigin" HEAD 'side' side.txt side; _ibg -C "$IB/noorigin" branch -q side "$IBC"
_ibg init -q "$IB/unborn"
_ibg clone -q "$IBO" "$IB/fb1"; _ibg -C "$IB/fb1" remote set-head origin -d
_ibg init -q --bare "$IB/master.git"; _ibg -C "$IB/master.git" symbolic-ref HEAD refs/heads/master
_ibmk - "$IB/master.git" - 'master only' README.md master; _ibg -C "$IB/master.git" update-ref refs/heads/master "$IBC"
_ibg clone -q "$IB/master.git" "$IB/fb2"; _ibg -C "$IB/fb2" remote set-head origin -d
rm -f "$IB/fb2/.git/logs/refs/remotes/origin/master" "$IB/fb2/.git/FETCH_HEAD"
_ibg clone -q --bare "$IBO" "$IB/bare.git"; _ibg -C "$IB/bare.git" worktree add -q "$IB/bwt" main
_ibg clone -q --depth 1 "file://$IBO" "$IB/shallow"
_ibg -C "$IBO" config uploadpack.allowFilter true
_ibg clone -q --filter=blob:none "file://$IBO" "$IB/partial"
_ibg clone -q "$IBO" "$IB/r3"
mkdir -p "$IB/gh/pwd_r3"
_ibpra_one() { local l; printf -v l '[{"baseRefName":"main","headRefName":"pr-only","headRefOid":"%s","isCrossRepository":false,"number":12,"state":"OPEN","updatedAt":"%s"}]' "$IB_PO" "$(_ibts 60)"; printf '%s\n' "$l"; }
_ibpra_one > "$IB/gh/pwd_r3/all.json"
printf '[{"isDraft":false,"labels":[],"mergeable":"MERGEABLE","number":12,"statusCheckRollup":[]}]\n' > "$IB/gh/pwd_r3/open.json"
_ibn=0
for _ibu in https://github.com/acme/widget ssh://git@github.com/acme/widget.git https://ghe.example/acme/widget.git ssh://git@github.com:22/acme/widget.git; do
  _ibn=$((_ibn + 1)); _ibg init -q "$IB/u$_ibn"; printf 'u\n' > "$IB/u$_ibn/u.txt"; _ibci "$IB/u$_ibn" 'u'
  _ibg -C "$IB/u$_ibn" remote add origin "$_ibu"
done
_ibg init -q "$IB/other"; printf 'other\n' > "$IB/other/o.txt"; _ibci "$IB/other" 'other'
_ibg -C "$IB/other" worktree add -q -b otherwt "$IB/otherwt"

# k: a repository gh lists 1000 pull requests for, none of them feat's.
_ibnew k
_ibmk - "$IB/k" HEAD 'feat' feat.txt 'feat, nowhere else'; _ibg -C "$IB/k" branch -q feat "$IBC"
_ibg -C "$IB/k" push -q origin feat; _ibg -C "$IB/k" fetch -q origin
# feat2 is pushed too, and the 1000th listed PR is its own, open.
_ibmk - "$IB/k" HEAD 'feat two' feat2.txt 'feat two, nowhere else'; _ibg -C "$IB/k" branch -q feat2 "$IBC"; IB_KF2="$IBC"
_ibg -C "$IB/k" push -q origin feat2; _ibg -C "$IB/k" fetch -q origin
_ibg -C "$IB/k" remote set-url origin git@github.com:acme/kilo.git
mkdir -p "$IB/gh/acme_kilo"
LC_ALL=C awk -v f2="$IB_KF2" 'BEGIN { printf "["; for (i = 1; i <= 999; i++) printf "%s{\"baseRefName\":\"main\",\"headRefName\":\"filler/%d\",\"headRefOid\":\"%040d\",\"isCrossRepository\":false,\"number\":%d,\"state\":\"CLOSED\",\"updatedAt\":\"2026-01-01T00:00:00Z\"}", (i > 1 ? "," : ""), i, i, i
  printf ",{\"baseRefName\":\"main\",\"headRefName\":\"feat2\",\"headRefOid\":\"%s\",\"isCrossRepository\":false,\"number\":1000,\"state\":\"OPEN\",\"updatedAt\":\"2026-01-01T00:00:00Z\"}]\n", f2 }' \
  > "$IB/gh/acme_kilo/all.json"
printf '[{"isDraft":false,"labels":[],"mergeable":"MERGEABLE","number":1000,"statusCheckRollup":[]}]\n' > "$IB/gh/acme_kilo/open.json"

# m: a small repository whose main worktree sits on another branch, so local
# main is checked out nowhere, and a PR is headed main.
_ibnew m sub/s.txt sub
IB_MTIP="$(_ibq -C "$IB/m" rev-parse HEAD)"
_ibg -C "$IB/m" worktree add -q -b five "$IB/mw/five" "$IB_MTIP"
_ibg -C "$IB/m" checkout -q -b work
_ibg -C "$IB/m" remote set-url origin git@github.com:acme/mike.git
IBMR="$(_ibmainwt "$IB/m")"
mkdir -p "$IB/gh/acme_mike"
printf -v _ibx '[{"baseRefName":"main","headRefName":"main","headRefOid":"%s","isCrossRepository":false,"number":14,"state":"OPEN","updatedAt":"%s"}]' "$IB_MTIP" "$(_ibts 60)"
printf '%s\n' "$_ibx" > "$IB/gh/acme_mike/all.json"
printf '[{"isDraft":false,"labels":[],"mergeable":"MERGEABLE","number":14,"statusCheckRollup":[]}]\n' > "$IB/gh/acme_mike/open.json"

# o: orphans. keep is listed; lost, lostbig, lostsmall and lostmany were worktrees git
# forgot; .wt/ inside the main worktree holds a dead checkout, a plain
# directory and a tracked one; nested and foreign sit beside keep.
_ibnew o .gitignore '*.bin' .wt/tracked/t.txt tracked
IB_OT="$(_ibq -C "$IB/o" rev-parse HEAD)"
for _ibn in keep lost lostbig lostsmall lostmany; do _ibg -C "$IB/o" worktree add -q -b "$_ibn" "$IB/ow/$_ibn" "$IB_OT"; done
printf 'lost, nowhere else\n' > "$IB/ow/lost/new1.txt"
for ((_ibi = 1; _ibi <= 20001; _ibi++)); do printf 'many %d\n' "$_ibi" > "$IB/ow/lostmany/m$_ibi.txt"; done
LC_ALL=C awk 'BEGIN { for (i = 0; i < 32768; i++) printf "big %059d\n", i }' > "$IB/ow/lostbig/big.bin"
LC_ALL=C awk 'BEGIN { for (i = 0; i < 16; i++) printf "small %057d\n", i }' > "$IB/ow/lostsmall/small.bin"
rm -rf "$IB/o/.git/worktrees/lost" "$IB/o/.git/worktrees/lostbig" "$IB/o/.git/worktrees/lostsmall" "$IB/o/.git/worktrees/lostmany"
mkdir -p "$IB/o/.wt/dead" "$IB/o/.wt/plain" "$IB/ow/foreign"
printf 'gitdir: %s\n' "$IB/o/.git/worktrees/dead" > "$IB/o/.wt/dead/.git"
printf 'plain, nowhere else\n' > "$IB/o/.wt/plain/x.txt"
_ibg init -q "$IB/ow/nested"; printf 'nested\n' > "$IB/ow/nested/n.txt"
printf 'gitdir: %s\n' "$IB/other/.git/worktrees/otherwt" > "$IB/ow/foreign/.git"
mkdir -p "$IB/sibling"; printf 'sibling\n' > "$IB/sibling/s.txt"
_ibg -C "$IB/o" remote set-url origin git@github.com:acme/oscar.git

# v: the view. An uncommitted worktree, an unpushed branch, a landed branch,
# a worktree blocked on a tool call, a landed orphan, and a branch whose
# commit sits on another remote branch only.
_ibnew v
IB_VT="$(_ibq -C "$IB/v" rev-parse HEAD)"
_ibg -C "$IB/v" worktree add -q -b vdirty "$IB/vw/dirty" "$IB_VT"; printf 'dirty, nowhere else\n' > "$IB/vw/dirty/u.txt"
_ibmk - "$IB/v" "$IB_VT" 'vun' vun.txt 'vun, nowhere else'; _ibg -C "$IB/v" branch -q vun "$IBC"
_ibg -C "$IB/v" branch -q vland "$IB_VT"
_ibg -C "$IB/v" worktree add -q -b vblk "$IB/vw/blk" "$IB_VT"
_ibg -C "$IB/v" worktree add -q -b vlost "$IB/vw/lostv" "$IB_VT"; rm -rf "$IB/v/.git/worktrees/lostv"
_ibmk - "$IB/v" "$IB_VT" 'other' other.txt 'other, nowhere else'; _ibg -C "$IB/v" branch -q other-ref "$IBC"
_ibg -C "$IB/v" push -q origin "$IBC:refs/heads/feature-x"; _ibg -C "$IB/v" fetch -q origin
_ibg -C "$IB/v" remote set-url origin git@github.com:acme/victor.git
IBVR="$(_ibmainwt "$IB/v")"

# t: temporary roots. Two worktrees at one commit with one uncommitted change,
# one under the seam's root; a third under a root that only shares a prefix.
_ibnew t
IB_TT="$(_ibq -C "$IB/t" rev-parse HEAD)"
_ibg -C "$IB/t" worktree add -q -b tw "$IB/temproot/w" "$IB_TT"
_ibg -C "$IB/t" worktree add -q -b tw2 "$IB/wtst/w" "$IB_TT"
_ibg -C "$IB/t" worktree add -q -b tw3 "$IB/temprootx/w" "$IB_TT"
printf 'same, nowhere else\n' > "$IB/temproot/w/u.txt"; printf 'same, nowhere else\n' > "$IB/wtst/w/u.txt"
ln -s "$IB/temproot" "$IB/tlink"
_ibg -C "$IB/t" remote set-url origin git@github.com:acme/tango.git

# f: a clean filter that leaves a mark, on the one changed path.
_ibnew f
printf '*.fx filter=fx\n' > "$IB/f/.gitattributes"
_ibg -C "$IB/f" config filter.fx.clean "sh -c 'touch \"$IB/ran-clean\"; cat'"
_ibg -C "$IB/f" config filter.fx.required true
printf 'one\n' > "$IB/f/c.fx"; _ibci "$IB/f" 'the filtered file'
_ibg -C "$IB/f" push -q origin main; _ibg -C "$IB/f" fetch -q origin
_ibg -C "$IB/f" remote set-url origin git@github.com:acme/foxtrot.git
printf 'two\n' > "$IB/f/c.fx"

# g: main's tip carries a signature, and the repository shows signatures
# through a gpg that leaves a mark.
_ibnew g
printf -v _ibx 'tree %s\nparent %s\nauthor Fixture <fixture@example.invalid> %s +0000\ncommitter Fixture <fixture@example.invalid> %s +0000\ngpgsig -----BEGIN PGP SIGNATURE-----\n \n iQEzBAABCAAdFiEEfixturefixturefixture\n -----END PGP SIGNATURE-----\n\nsigned\n' \
  "$(_ibq -C "$IB/g" rev-parse 'HEAD^{tree}')" "$(_ibq -C "$IB/g" rev-parse HEAD)" "$(_ibago 60)" "$(_ibago 60)"
_ibx="$(printf '%s' "$_ibx" | _ibg -C "$IB/g" hash-object -t commit -w --stdin)"
_ibg -C "$IB/g" reset -q --hard "$_ibx"; _ibg -C "$IB/g" push -q origin main; _ibg -C "$IB/g" fetch -q origin
_ibg -C "$IB/g" config log.showSignature true; _ibg -C "$IB/g" config gpg.program "$IB/gpgstub"
_ibg -C "$IB/g" remote set-url origin git@github.com:acme/golf.git

# d: a clone whose index a plain git status would rewrite: a.txt touched
# after checkout, a linked worktree, an untracked file and a staged change.
_ibnew d a.txt a b.txt b
_ibg -C "$IB/d" worktree add -q -b dx "$IB/dw/x"
printf 'untracked, nowhere else\n' > "$IB/d/new.txt"; printf 'staged\n' > "$IB/d/b.txt"; _ibg -C "$IB/d" add b.txt
_ibg -C "$IB/d" remote set-url origin git@github.com:acme/delta.git
touch "$IB/d/a.txt"
}
