# tests/lib/inventory-gizmo.sh: the gizmo repository of the inventory review sections.
# Used by parts 0880 (builds it and makes the runs) and 0890 (reads the runs). Moved from
# parts/0880-felix-inventory-what-review-found-each-held.sh: the fixture from lines 16-132 (into _ivz_build), its helpers from
# lines 12-14 and 155-180, the runs from 179-189 (into _ivz_runs). Needs inventory.sh.
# Definitions only. A builder sets its variables first and does nothing more when its fixture
# is already there.

_ivzwt() { _ivg -C "$IVZ" worktree add -q "$@"; }
# E for an ASCII path, whatever the locale.
_ivenc() { printf '%s' "$1" | LC_ALL=C sed 's/[^A-Za-z0-9-]/-/g'; }
# ---- the runs ------------------------------------------------------------
_ivzrun() {  # [--path P] [--tmp D] [--cwd D] felix-args...
  local p="$IVSTUB2:$IVSTUB:$PATH" t="$IV/tz" d="$IVZ"
  while :; do
    case "${1:-}" in
      --path) p="$2"; shift 2 ;;
      --tmp)  t="$2"; shift 2 ;;
      --cwd)  d="$2"; shift 2 ;;
      *) break ;;
    esac
  done
  ( cd "$d" || exit 97
    unset FELIX_HOME FELIX_MEMORY FELIX_KERNEL FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE CLAUDE_PLUGIN_ROOT \
          CLAUDE_CONFIG_DIR GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OPTIONAL_LOCKS GIT_CEILING_DIRECTORIES \
          XDG_STATE_HOME XDG_CACHE_HOME FELIX_INVENTORY_TEMP_ROOTS
    export HOME="$IVH" TMPDIR="$t" PATH="$p" XDG_CONFIG_HOME="$IVH/.config" GIT_CONFIG_NOSYSTEM=1 \
           GIT_ALLOW_PROTOCOL=file GIT_TERMINAL_PROMPT=0 GIT_CEILING_DIRECTORIES="$IV"
    "$IVF" "$@" ) 2>>"$IV_ERR"
}
_ivz_snap() {
  local d
  for d in "$IVW3" "$IVZO" "$IVZD"; do
    ( cd "$d" && find . -print | LC_ALL=C sort && find . -type f -exec "$_iv_sum" {} + | LC_ALL=C sort ) 2>&1
  done
}
_ivz_pack() { ( cd "$1/.git/objects" && find . -print | LC_ALL=C sort ); }

# _ivz_build [runs]: the gizmo repository, its worktrees, sessions, gh stand-ins and partial
# clones; "runs" adds the seven runs over it. Needs _iv_build.
_ivz_build() {
IVW3="$IV/work3"; IVZ="$IVW3/gizmo"; IVZO="$IV/origin3.git"; IVZX="$IV/zx"; IVZD="$IV/decoy"
IVZC="$IVZ/.claude/worktrees"
IVGH2="$IV/gh2"; IVGH3="$IV/gh3"; IVSTUB2="$IV/stub2"; IVSTUB3="$IV/stub3"; IVSTUB4="$IV/stub4"
  IVZ_T1="$IV/z1.tsv"; IVZ_H2="$IV/z2.txt"; IVZ_T2NG="$IV/z2ng.tsv"; IVZ_T3="$IV/z3.tsv"
  IVZ_T4="$IV/z4.tsv"; IVZ_P1="$IV/p1.tsv"; IVZ_P2="$IV/p2.tsv"
  _ivz_fixture
  case "${1:-}" in runs) _ivz_runs ;; esac
}

# _ivz_fixture: the guard is the second partial clone.
_ivz_fixture() {
  [ -d "$IV/pc2/.git" ] && return 0
mkdir -p "$IVW3" "$IVZX" "$IVGH2" "$IVGH3" "$IVSTUB2" "$IVSTUB3" "$IVSTUB4" "$IV/tq" "$IV/tz"

# ---- gizmo: main, then a worktree or branch per finding -----------------
_ivrepo "$IVZO" "$IVZ" acme/gizmo
_ivg -C "$IVZO" config uploadpack.allowFilter true
mkdir -p "$IVZ/src" "$IVZC/kept" "$IVZ/docs/handoff/pending"
printf 'gizmo\n' > "$IVZ/README.md"; printf 'shared copy, first\n' > "$IVZ/src/gate.txt"
printf 'node_modules/\n*.bak\n' > "$IVZ/.gitignore"; printf 'kept\n' > "$IVZC/kept/README"
printf '*.flt filter=mark\n' > "$IVZ/.gitattributes"; printf 'HELLO\n' > "$IVZ/src/f.flt"
printf '### the gizmo waits\n\n**Next:**\n- Build the gizmo.\n' > "$IVZ/docs/handoff/pending/20260924T000000Z-gizmo.md"
_ivwc "$IVZ" 'the first gizmo'; IVZ_C0="$(_ivg -C "$IVZ" rev-parse HEAD)"
_ivg -C "$IVZ" push -q origin main; _ivg -C "$IVZ" remote set-head origin main
printf '.lost/\n' >> "$IVZ/.git/info/exclude"
# A clean filter that leaves a mark and uppercases: the committed f.flt is
# its output, and wt-filter's lowercase copy cleans to it.
_ivzwt -b topic/filter "$IVZC/wt-filter" main; printf 'hello\n' > "$IVZC/wt-filter/src/f.flt"
# A listed worktree whose .git file is gone, holding a file no object has.
_ivzwt -b topic/q "$IVZC/wt-q" main
rm -f "$IVZC/wt-q/.git"; printf 'only here\n' > "$IVZC/wt-q/only-here.txt"; printf 'edited\n' >> "$IVZC/wt-q/README.md"
# A feature branch made with --track origin/main, pushed under its own name
# with an open pull request; another pushed with none; a local branch at
# main whose remote namesake has moved on.
_ivzwt --track -b topic/feat2 "$IVZC/wt-feat2" origin/main
printf 'feat2\n' > "$IVZC/wt-feat2/src/f2.txt"; _ivwc "$IVZC/wt-feat2" 'feat2 work'
_ivg -C "$IVZC/wt-feat2" push -q origin topic/feat2:topic/feat2; IVZ_F2="$(_ivg -C "$IVZC/wt-feat2" rev-parse HEAD)"
_ivg -C "$IVZ" branch -q --track topic/feat3 origin/main
_ivc "$IVZ" "$IVZ_C0" 'feat3 work' src/f3.txt 'feat3'; _ivg -C "$IVZ" update-ref refs/heads/topic/feat3 "$IVC"
_ivg -C "$IVZ" push -q origin topic/feat3:topic/feat3
_ivg -C "$IVZ" branch -q --no-track topic/diverge main
_ivc "$IVZ" "$IVZ_C0" 'diverged elsewhere' src/dv.txt 'dv'; _ivg -C "$IVZ" push -q origin "$IVC:refs/heads/topic/diverge"
# A detached worktree whose HEAD moved on, by reset --soft, from the commit
# its index still holds.
_ivc "$IVZ" "$IVZ_C0" 'm3 first' src/m3.txt 'one'; IVZ_X1="$IVC"
_ivc "$IVZ" "$IVZ_X1" 'm3 second' src/m3b.txt 'two'; IVZ_X2="$IVC"
_ivzwt --detach "$IVZC/wt-m3" main
_ivg -C "$IVZC/wt-m3" checkout -q --detach "$IVZ_X1"; _ivg -C "$IVZC/wt-m3" reset -q --soft "$IVZ_X2"
# A changed file whose content an object already holds, though main's differs.
_ivc "$IVZ" "$IVZ_C0" 'a second copy' src/gate.txt 'shared copy, second'
_ivzwt -b topic/f2 "$IVZC/wt-f2" main; printf 'shared copy, second\n' > "$IVZC/wt-f2/src/gate.txt"
for _ivn in utf8 garbage tab clean; do _ivzwt -b "topic/$_ivn" "$IVZC/wt-$_ivn" main; done
mkdir -p "$IVZC/wt-clean/tmpdir-here"
# Orphans: a directory named with a glob character beside a tracked one; a
# plain directory whose node_modules the repository ignores; one whose only
# unique content is ignored; and two worktrees pruned from a directory no
# listed worktree is left in.
mkdir -p "$IVZC/k*" "$IVZC/plain/node_modules" "$IVZC/ign"
printf 'only in k star\n' > "$IVZC/k*/g.txt"
printf 'plain only\n' > "$IVZC/plain/a.txt"; printf 'module only\n' > "$IVZC/plain/node_modules/x.js"
printf 'gizmo\n' > "$IVZC/ign/seen.txt"; printf 'cache only\n' > "$IVZC/ign/cache.bak"
_ivzwt -b topic/g1 "$IVZ/.lost/g1" main; _ivzwt -b topic/g2 "$IVZ/.lost/g2" main
printf 'lost only\n' > "$IVZ/.lost/g1/lost.txt"
rm -rf "$IVZ/.git/worktrees/g1" "$IVZ/.git/worktrees/g2"
# Beside the clone: a non-ASCII path, a path whose record name Claude Code
# cuts at 200, and a path holding a line break that spells another
# repository's directory.
IVZ_JOSE="$IVW3/wt-jos$(printf '\303\251')"; _ivzwt -b topic/jose "$IVZ_JOSE" main
IVZ_L=""; for _ivn in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do IVZ_L="${IVZ_L}llllllllll"; done
IVZ_LONG="$IVW3/$IVZ_L"; _ivzwt -b topic/long "$IVZ_LONG" main
_ivg -c init.defaultBranch=main init -q "$IVZD"; printf 'decoy\n' > "$IVZD/x.txt"; _ivwc "$IVZD" 'the decoy'
IVZ_NL="$(printf '%s/nl\nworktree %s' "$IVW3" "$IVZD")"; _ivzwt --detach "$IVZ_NL" main
# Only now the filter, so no setup step above ran it.
_ivg -C "$IVZ" config filter.mark.clean "echo ran >> '$IVZX/filter-ran'; tr a-z A-Z"

# ---- gizmo's sessions ----------------------------------------------------
# A question whose note is cut inside a two-byte character; a newest session
# that is not JSON; a live one whose file name holds a tab; live ones in the
# non-ASCII and the long directory, filed where Claude Code files them; and
# a chip whose title holds a backslash.
_ivopen "$IVZC/wt-utf8" 5a5a5a5a-0000-4000-8000-000000000001
_au_say  "$(_ivago 32 iso)" 'describe it'
_ivx=""; for _ivn in 1 2 3 4 5 6 7 8 9 10; do _ivx="$_ivx$(printf '\303\251\303\251\303\251\303\251\303\251\303\251\303\251\303\251\303\251\303\251')"; done
_au_stop "$(_ivago 30 iso)" msg_z1 "$_ivx?"
_ivtouch "$_AU_F" 30
_ivopen "$IVZC/wt-garbage" 5b5b5b5b-0000-4000-8000-000000000001
printf 'not json\n{{{{\n\377\376 binary\n' >> "$_AU_F"; _ivtouch "$_AU_F" 30
_au_open "$(_ive "$IVZC/wt-tab")/$(printf 'we ird\tname').jsonl" 5c5c5c5c-0000-4000-8000-000000000001
_au_say  "$(_ivago 3 iso)" 'keep going'
_au_stop "$(_ivago 2 iso)" msg_z3 'Still going.'
_ivtouch "$_AU_F" 2
_au_open "$IVP/$(_ivenc "$IVW3")-wt-jos-/5d5d5d5d-0000-4000-8000-000000000001.jsonl" 5d5d5d5d-0000-4000-8000-000000000001
_au_say  "$(_ivago 3 iso)" 'keep going'
_au_stop "$(_ivago 2 iso)" msg_z4 'Still going.'
_ivtouch "$_AU_F" 2
IVZ_LE="$(_ivenc "$IVZ_LONG")"
_au_open "$IVP/${IVZ_LE:0:200}-z9k2p1/5e5e5e5e-0000-4000-8000-000000000001.jsonl" 5e5e5e5e-0000-4000-8000-000000000001
_au_say  "$(_ivago 3 iso)" 'keep going'
_au_stop "$(_ivago 2 iso)" msg_z5 'Still going.'
_ivtouch "$_AU_F" 2
_ivopen "$IVZ" 5f5f5f5f-0000-4000-8000-000000000001
_au_say  "$(_ivago 125 iso)" 'note the path work'
_ivchip  "$(_ivago 124 iso)" toolu_zb task_5f5f5f5f 'Title with C:\\path' 'Theta task: teach the path parser that a drive letter and a backslash begin an absolute path, and test it on three spellings of one path.'
_au_stop "$(_ivago 120 iso)" msg_z6 'Noted.'
_ivtouch "$_AU_F" 120

# ---- gh for gizmo --------------------------------------------------------
# The stand-in again, over gizmo's pull requests, and doing what gh does on
# its first run in a HOME: keep a device id under its state directory. A
# second has a list of 1000 pull requests, gh's limit here, none of them
# gizmo's branches'.
printf -v _ivx '[{"number":7001,"title":"Feat two","state":"OPEN","isDraft":false,"headRefName":"topic/feat2","headRefOid":"%s","baseRefName":"main","createdAt":"%s","updatedAt":"%s","mergedAt":null,"closedAt":null,"labels":[],"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","statusCheckRollup":[],"url":"u","author":{"login":"fixture"},"headRepositoryOwner":{"login":"acme"},"reviewDecision":""}]' \
  "$IVZ_F2" "$(_ivago 600 iso)" "$(_ivago 60 iso)"
printf '%s\n' "$_ivx" > "$IVGH2/prs.json"; printf '{}\n' > "$IVGH2/statuses.json"; printf '{}\n' > "$IVGH3/statuses.json"
LC_ALL=C awk 'BEGIN { printf "["; for (i = 1; i <= 1000; i++) printf "%s{\"number\":%d,\"title\":\"f\",\"state\":\"CLOSED\",\"isDraft\":false,\"headRefName\":\"filler/%d\",\"headRefOid\":\"%040d\",\"baseRefName\":\"main\",\"createdAt\":\"2026-01-01T00:00:00Z\",\"updatedAt\":\"2026-01-01T00:00:00Z\",\"mergedAt\":null,\"closedAt\":null,\"labels\":[],\"mergeable\":\"UNKNOWN\",\"mergeStateStatus\":\"UNKNOWN\",\"statusCheckRollup\":[],\"url\":\"u\",\"author\":{\"login\":\"f\"},\"headRepositoryOwner\":{\"login\":\"f\"},\"reviewDecision\":\"\"}", (i > 1 ? "," : ""), i, i, i; print "]" }' > "$IVGH3/prs.json"
for _ivn in 2 3; do
  eval "_ivd=\$IVGH$_ivn; _ivs=\$IVSTUB$_ivn"
  LC_ALL=C awk -v d="$_ivd" -v iv="$IV" 'NR == 2 { print "D='"'"'" d "'"'"'"; next } { print }
    NR == 3 { print "sd=\"${XDG_STATE_HOME:-$HOME/.local/state}/gh\"; case \"$sd\" in '"'"'" iv "'"'"'/*) [ -f \"$sd/device-id\" ] || { mkdir -p \"$sd\" && echo fixture-device > \"$sd/device-id\"; } ;; esac" }' \
    "$IVSTUB/gh" > "$_ivs/gh"
  chmod +x "$_ivs/gh"
done
# A gh that answers slowly, for a signal to arrive while it runs.
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/gh-slow.log"\nsleep 4\necho "[]"\n' "$IV" > "$IVSTUB4/gh"; chmod +x "$IVSTUB4/gh"

# ---- two partial clones of gizmo ----------------------------------------
# Neither holds a blob. The first's remote can serve one; the second's
# cannot be reached.
_ivg clone -q --no-checkout --filter=blob:none "file://$IVZO" "$IV/pc1" 2>/dev/null
_ivg clone -q --no-checkout --filter=blob:none "file://$IVZO" "$IV/pc2" 2>/dev/null
_ivg -C "$IV/pc2" config remote.origin.url "file://$IV/nowhere.git"
}

# _ivz_runs: the snapshots taken before the runs, then the seven runs; the guard is the last file.
_ivz_runs() {
  [ -e "$IVZ_P2" ] && return 0
_ivz_before="$(_ivz_snap)"
_ivz_pc1="$(_ivz_pack "$IV/pc1")"
: > "$IVGIT_LOG"; : > "$IV/gh-slow.log"
IVZ_T1="$IV/z1.tsv"; _ivzrun inventory --tsv --repo "$IVZ" > "$IVZ_T1"
IVZ_H2="$IV/z2.txt"; _ivzrun inventory --no-gh --repo "$IVZ" > "$IVZ_H2"
IVZ_T2NG="$IV/z2ng.tsv"; _ivzrun inventory --tsv --no-gh --repo "$IVZ" > "$IVZ_T2NG"
IVZ_T3="$IV/z3.tsv"; _ivzrun --path "$IVSTUB3:$IVSTUB:$PATH" inventory --tsv --repo "$IVZ" > "$IVZ_T3"
IVZ_T4="$IV/z4.tsv"; _ivzrun --tmp "$IVZC/wt-clean/tmpdir-here" inventory --tsv --no-gh --no-host --repo "$IVZ" > "$IVZ_T4"
IVZ_P1="$IV/p1.tsv"; _ivzrun --cwd "$IV/pc1" inventory --tsv --no-gh --no-host > "$IVZ_P1"
IVZ_P2="$IV/p2.tsv"; _ivzrun --cwd "$IV/pc2" inventory --tsv --no-gh --no-host > "$IVZ_P2"
}
