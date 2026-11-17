# tests/lib/inventory-blind-runs.sh: the host repository, the records and the runs of the blind
# inventory sections that more than one part reads. Used by parts 0910 (RUN1 to RUN4) 0920 (the
# host repository, the review helpers) 0930 (the review helpers, and every run N16 lists) 1270
# (_ibsig). Moved from parts/0910-continued.sh: the host repository from lines 1-20 (into _ib_h_build),
# its records from 22-115, the records of r from 132-187, _ib8 (317), _ibhead1 (386), _ibland
# (407-409), the runs of r from 189-203 (into _ib_r_runs); from
# parts/0920-continued.sh: IB_LABELS (262), _ibm_five (2), _ibsig (78-100), _ibgroup2 (316-323) and
# _ibsaid (325-326). _ib_n16 repeats, in 0920's order, the commands of the runs 0930's N16
# reads, with what they need, so 0930 can stand alone. Needs inventory-blind.sh. Definitions only.

# _inventory_blind_runs_vars: the variables this file's functions read, set when the prelude calls it
# (contract C2: a lib file defines functions and nothing else).
_inventory_blind_runs_vars() {
IB_LABELS='hazard:shared-branch|hazard:staged-revert|live|question|blocked|uncommitted|unpushed|unproposed|pr-open|pr-closed-unlanded|carried|orphan|chip-unstarted|handoff-pending|undecided, content not landed|in temporary directories'
}
# h's records, written just before its runs. Ages are minutes.
_ibh_ask() {  # worktree sid final-text: a session two minutes of talk, ending on that text
  _ibsess "$IB/hw/$1" "$2"; _ib_h 32 'report back'; _ib_a 30 "$3"; }
_ibh_two() {
  _ibsess "$IB/hw/two" s-old; _ib_h 101 'start'; _ib_a 100 'Done.'; _ibage "$IB_F" 100
  _ibsess "$IB/hw/two" s-new; _ib_h 71 'again'; _ib_a 70 'Done.'; _ibage "$IB_F" 70; }
_ibh_records() {
  IB_BR=""
  _ibsess "$IB/hw/w.t_1" s-enc; _ib_h 11 'go'; _ib_a 10 'Done.'; _ibage "$IB_F" 10
  _ibopen "$IBP/$(_ibenc "$IB/hw/e")--x/s-emo.jsonl" s-emo; _ib_h 11 'go'; _ib_a 10 'Done.'; _ibage "$IB_F" 10
  _ibsess "$IB/hsym/sym" s-sym; _ib_h 11 'go'; _ib_a 10 'Done.'; _ibage "$IB_F" 10
  _ibx="$(_ibenc "$IB_LONG1")"; _ibopen "$IBP/${_ibx:0:200}-abc123/s-long1.jsonl" s-long1; _ib_h 11 'go'; _ib_a 10 'Done.'; _ibage "$IB_F" 10
  _ibx="$(_ibenc "$IB_LONG2")"; _ibopen "$IBP/${_ibx:0:200}-abc123/s-long2a.jsonl" s-long2a; _ib_h 11 'go'; _ib_a 10 'Done.'; _ibage "$IB_F" 10
  _ibopen "$IBP/${_ibx:0:200}-def456/s-long2b.jsonl" s-long2b; _ib_h 11 'go'; _ib_a 10 'Done.'; _ibage "$IB_F" 10
  _ibsess "$IB/hw/act" s-act; _ib_h 302 'go'; _ib_a 300 'Working.'; _ibage "$IB_F" 300
  mkdir -p "$IBP/$(_ibenc "$IB/hw/act")/s-act/tool-results/deep"
  printf 'x\n' > "$IBP/$(_ibenc "$IB/hw/act")/s-act/tool-results/deep/x.txt"; _ibage "$IBP/$(_ibenc "$IB/hw/act")/s-act/tool-results/deep/x.txt" 2
  _ibh_two
  for _ibn in blk blk2; do
    _ibsess "$IB/hw/$_ibn" "s-$_ibn"; _ib_h 40 'watch it'
    _ib_tu 39 toolu_0 Bash '{"command":"date","description":"Read the clock"}'; _ib_tr 38 toolu_0 ok
    _ib_tu 35 toolu_1 Bash '{"command":"watch-the-ledger","description":"Watch the ledger"}'; _ibage "$IB_F" 35
  done
  mkdir -p "$IBP/$(_ibenc "$IB/hw/blk2")/s-blk2/subagents"
  printf '{}\n' > "$IBP/$(_ibenc "$IB/hw/blk2")/s-blk2/subagents/agent-x.jsonl"; _ibage "$IBP/$(_ibenc "$IB/hw/blk2")/s-blk2/subagents/agent-x.jsonl" 3
  _ibh_ask ask s-ask "I've pushed the branch.\\n\\nShall I merge it?"; _ibage "$IB_F" 30
  _ibh_ask ans-a s-ans-a 'It is ready. Shall I merge it?'; _ib_h 29 'go ahead'; _ibage "$IB_F" 29
  _ibh_ask ans-b s-ans-b 'It is ready. Shall I merge it?'; _ib_tr 29 toolu_z ok
  _ib_u 29 '"<system-reminder>x</system-reminder><command-name>/foo</command-name>"'; _ibage "$IB_F" 29
  _ibh_ask ans-c s-ans-c 'It is ready. Shall I merge it?'; _ib_u 29 '"Stop hook feedback: keep going"' ',"isMeta":true'; _ibage "$IB_F" 29
  _ibh_ask sa-fence s-sa-fence 'The log said:\n```\nready?\n```\nThat is the whole log.'; _ibage "$IB_F" 30
  _ibh_ask sa-span  s-sa-span  'The status line now reads `merge?` and that is all.'; _ibage "$IB_F" 30
  _ibh_ask sa-quote s-sa-quote 'The reviewer wrote \"should I?\" in the thread.'; _ibage "$IB_F" 30
  _ibh_ask sa-bq    s-sa-bq    '> Want me to merge?\nThat was the old note.'; _ibage "$IB_F" 30
  _ibh_ask ng-a s-ng-a 'I wrote an essay yesterday.'; _ibage "$IB_F" 30
  _ibh_ask ng-b s-ng-b 'Nothing here needs your input.'; _ibage "$IB_F" 30
  _ibh_ask ng-c s-ng-c 'Nothing broke. Your call on the merge.'; _ibage "$IB_F" 30
  _ibh_ask ng-d s-ng-d 'The tests pass. Your call.'; _ibage "$IB_F" 30
  _ibh_ask q-a s-q-a 'All green. Ready to merge?**)'; _ibage "$IB_F" 30
  _ibh_ask q-b s-q-b 'Ready?\n\nThe tests pass.\n\nThe branch is pushed.\n\nThe notes are filed.'; _ibage "$IB_F" 30
  _ibsess "$IB/hw/bad-empty" s-bad-empty; _ibage "$IB_F" 30
  _ibsess "$IB/hw/bad-cut" s-bad-cut; _ib_a 30 'This line is cut before it ends, mid-string.'
  _ibx="$(cat "$IB_F")"; printf '%s' "${_ibx:0:150}" > "$IB_F"; _ibage "$IB_F" 30
  _ibsess "$IB/hw/bad-nojson" s-bad-nojson; printf 'not json at all\n' > "$IB_F"; _ibage "$IB_F" 30
  _ibh_ask side s-side 'Done.'; _ib_a 30 'Shall I continue?' true
  printf -v _ibx '{"type":"system","subtype":"note","message":{"role":"assistant","content":[{"type":"text","text":"Is it?"}]},"sessionId":"s-side","timestamp":"%s"}' "$(_ibts 30)"
  _ib_raw "$_ibx"; _ibage "$IB_F" 30
  # big-a: an asking text, then 300 tool call and result pairs of about 1.3
  # KiB each, so the ask lies more than 256 KiB from the end.
  _ibopen "$IB/pair.tmp" s-big-a
  _ibx="$(_ibp 'filler for a large tool call that carries no text at all' 1000)"
  _ib_tu 30 toolu_big Bash "{\"command\":\"$_ibx\"}"; _ib_tr 30 toolu_big "$_ibx"
  _ibsess "$IB/hw/big-a" s-big-a; _ib_h 32 'start'; _ib_a 31 'Shall I start?'
  LC_ALL=C awk '{ l[NR] = $0 } END { for (i = 1; i <= 300; i++) for (j = 1; j <= NR; j++) print l[j] }' "$IB/pair.tmp" >> "$IB_F"
  _ibage "$IB_F" 30
  _ibsess "$IB/hw/big-b" s-big-b
  for _ibn in 1 2 3; do _ib_tu 30 "toolu_c$_ibn" Bash '{"command":"true"}'; _ib_tr 30 "toolu_c$_ibn" ok; done
  _ibage "$IB_F" 30
  _ibsess "$IB/h" s-boss; _ib_h 201 'spawn them'; _ib_a 200 'Spawned the agents.'; _ibage "$IB_F" 200
  _ibx="$IBP/$(_ibenc "$IB/h")/s-boss/subagents"; mkdir -p "$_ibx"
  printf '{"agentType":"general-purpose","description":"write the parser","worktreePath":"%s"}\n' "$IB/h/.claude/worktrees/agent-a1b2c3" > "$_ibx/agent-a1b2c3.meta.json"
  printf '{}\n' > "$_ibx/agent-a1b2c3.jsonl"; _ibage "$_ibx/agent-a1b2c3.jsonl" 2
  printf '{"agentType":"general-purpose","description":"another one","worktreePath":"/elsewhere/agent-a9b9c9"}\n' > "$_ibx/agent-a9b9c9.meta.json"
  printf '{}\n' > "$_ibx/agent-a9b9c9.jsonl"; _ibage "$_ibx/agent-a9b9c9.jsonl" 2
  _ibsess "$IB/hw/par" s-par; _ib_h 31 'look into it'; _ib_a 30 'Done.'; _ibage "$IB_F" 30
  _ibopen "$IBP/$(_ibenc "$IB/hw/par")/s-par/subagents/agent-y.jsonl" agent-y
  _ib_a 30 'Shall I proceed?' true; _ib_tu 30 toolu_y Bash '{"command":"wait"}'; _ibage "$IB_F" 30
  _ibsess "$IB/hw/ord" s-ord; _ib_h 2 'go'; _ib_a 1 'Done.'; _ibage "$IB_F" 1
  _ibsess "$IB/hw/ll" s-ll; _ib_h 2 'go'; _ib_a 1 'Done.'; _ibage "$IB_F" 1
  _ibsess "$IB/hw/cost" s-cost; _ib_h 182 'go'; _ib_a 180 'Done.'
  _ib_raw '{"type":"cost-state","costUSD":0.25,"sessionId":"s-cost"}'; _ibage "$IB_F" 1
  _ibsess "$IB/hw/notime" s-notime; _ib_h none 'go'; _ib_a none 'Done.'; _ibage "$IB_F" 2
  _ibh_ask mf-a s-mf-a 'The build is green. Shall I tag it?'; _ibage "$IB_F" 30
  _ibh_ask mf-b s-mf-b 'Done.'
  printf -v _ibx '{"type":"attachment","attachment":{"type":"note"},"message":{"role":"assistant","content":[{"type":"text","text":"Shall I go on?"}]},"sessionId":"s-mf-b","timestamp":"%s"}' "$(_ibts 30)"
  _ib_raw "$_ibx"; _ibage "$IB_F" 30
  # A pending call 35 minutes old, then a bookkeeping line that touched the file a minute ago.
  _ibsess "$IB/hw/blk-cost" s-blk-cost; _ib_h 40 'watch it'; _ib_tu 35 toolu_bc Bash '{"command":"watch-the-ledger"}'
  _ib_raw '{"type":"cost-state","costUSD":0.25,"sessionId":"s-blk-cost"}'; _ibage "$IB_F" 1
  # The same call, answered 34 minutes ago by the person's own text.
  _ibsess "$IB/hw/blk-human" s-blk-human; _ib_h 40 'watch it'; _ib_tu 35 toolu_bh Bash '{"command":"watch-the-ledger"}'
  _ib_h 34 'never mind that'; _ibage "$IB_F" 34
  # The same call, followed by a user record that is no human text ("isMeta":true): a record follows it all the same.
  _ibsess "$IB/hw/blk-meta" s-blk-meta; _ib_h 40 'watch it'; _ib_tu 35 toolu_bm Bash '{"command":"watch-the-ledger"}'
  _ib_u 34 '"Stop hook feedback: keep going"' ',"isMeta":true'; _ibage "$IB_F" 34
  # Two sessions, the newer one's file the older: the other's file was touched last by a bookkeeping line.
  _ibsess "$IB/hw/two2" s-rt-old; _ib_h 91 'start'; _ib_a 90 'Done.'
  _ib_raw '{"type":"cost-state","costUSD":0.25,"sessionId":"s-rt-old"}'; _ibage "$IB_F" 2
  _ibsess "$IB/hw/two2" s-rt-new; _ib_h 32 'again'; _ib_a 31 'Done.'; _ibage "$IB_F" 30
  # A last line cut before its end, holding an asking text, after a whole final text that asks nothing.
  _ibh_ask mf-cut s-mf-cut 'Done.'
  printf -v _ibx '{"message":{"role":"assistant","content":[{"type":"text","text":"Shall I merge it?"}]},"sessionId":"s-mf-cut","timestamp":"%s"' "$(_ibts 29)"
  printf '%s' "$_ibx" >> "$IB_F"; _ibage "$IB_F" 29
}
_ibr_records() {
  IB_BR=""
  _ibsess "$IBR" s-chip; _ib_h 11 'file the chips'
  _ib_chip 10 toolu_9 task_ab12cd34 'Fix the README badge' "$IB_P95"
  _ib_chip 10 toolu_18 task_18aaaaaa 'Two\nlines\tand a tab' "$IB_P18"
  _ib_chip 10 toolu_96 task_9600aaaa 'Withdrawn later' "$IB_P96"
  _ib_tu 10 toolu_96d mcp__ccd_session__dismiss_task '{"task_id":"task_9600aaaa"}'; _ib_tr 10 toolu_96d 'error: already started'
  _ib_chip 10 toolu_97 task_9700aaaa 'Started behind a reminder' "$IB_P97"
  _ib_chip 10 toolu_115a task_115aaaaa 'Changed at character 120' "$IB_P115A"
  _ib_chip 10 toolu_115b task_115bbbbb 'Equal through character 120' "$IB_P115B"
  # Titles cut at 120 bytes on a whole character: é is two bytes, so 119 a's then é
  # ends the cut at 119, and 118 a's then é fits in exactly 120.
  printf -v _ibx '%0119d' 0; _ibx="${_ibx//0/a}é and then a good deal more title"
  _ib_chip 10 toolu_t119 task_t119aaaa "$_ibx" "$IB_PT119"
  printf -v _ibx '%0118d' 0; _ibx="${_ibx//0/a}é and then a good deal more title"
  _ib_chip 10 toolu_t120 task_t120bbbb "$_ibx" "$IB_PT120"
  _ib_a 10 'Filed.'; _ibage "$IB_F" 10
  _ibsess "$IBR" s-att
  printf -v _ibx '{"type":"attachment","attachment":{"type":"deferred_tools","tools":[{"name":"mcp__ccd_session__spawn_task","description":"Flag an issue"},{"name":"mcp__ccd_session__dismiss_task","description":"Withdraw one"}]},"sessionId":"s-att","timestamp":"%s"}' "$(_ibts 6)"
  _ib_raw "$_ibx"; _ib_h 6 'Noted (task_id: task_ffff0000).'; _ib_a 5 'Noted.'; _ibage "$IB_F" 5
  # Who worked on which PR's branch: s-o2's records sit in s-o3's file, as a
  # resumed session's file copies its predecessor's.
  IB_BR=pr-only;   _ibsess "$IBR" s-o1; _ib_h 51 'work on it'; _ib_a 50 'Working on it.'; _ibage "$IB_F" 50
  _ibsess "$IBR" s-o3; IB_SID=s-o2; _ib_h 21 'carry on'; _ib_a 20 'Carried on.'
  IB_SID=s-o3; IB_BR=main; _ib_h 6 'resume'; _ib_a 5 'Resumed.'; _ibage "$IB_F" 5
  IB_BR=pr-only-x; _ibsess "$IBR" s-o5; _ib_h 3 'x'; _ib_a 2 'X.'; _ibage "$IB_F" 2
  IB_BR=stale-pr;  _ibsess "$IBR" s-o4; _ib_h 91 'stale'; _ib_a 90 'Stale.'; _ibage "$IB_F" 90
  IB_BR=forked;    _ibsess "$IBR" s-o6; _ib_h 4 'fork'; _ib_a 3 'Forked.'; _ibage "$IB_F" 3
  # The owner is the session of the newest user or assistant record naming the head. (a) The
  # newest file is not it: s-ow-a1 was touched a minute ago but wrote its own-a records 80 minutes
  # ago. (b) An owner whose own file holds a newer record on another branch is live though its
  # own-b record is two hours old. (c) An attachment record naming the head, newer than every
  # user and assistant one, is no owner's.
  IB_BR=own-a; _ibsess "$IBR" s-ow-a1; _ib_h 81 'start'; _ib_a 80 'Started.'
  IB_BR=main; _ib_h 4 'something else'; _ib_a 3 'Elsewhere.'; _ibage "$IB_F" 1
  IB_BR=own-a; _ibsess "$IBR" s-ow-a2; _ib_h 41 'also'; _ib_a 40 'Also.'; _ibage "$IB_F" 40
  IB_BR=own-b; _ibsess "$IBR" s-ow-b; _ib_h 121 'start'; _ib_a 120 'Started.'
  IB_BR=other-b; _ib_h 4 'moved on'; _ib_a 3 'Moved on.'; _ibage "$IB_F" 3
  IB_BR=own-c; _ibsess "$IBR" s-ow-c1; _ib_h 71 'early'; _ib_a 70 'Early.'
  printf -v _ibx '{"type":"attachment","attachment":{"type":"note"},"message":{"role":"assistant","content":[{"type":"text","text":"Noted."}]},"gitBranch":"own-c","sessionId":"s-ow-c1","timestamp":"%s"}' "$(_ibts 5)"
  _ib_raw "$_ibx"; _ibage "$IB_F" 5
  IB_BR=own-c; _ibsess "$IBR" s-ow-c2; _ib_h 31 'later'; _ib_a 30 'Later.'; _ibage "$IB_F" 30
  IB_BR=main;      _ibsess "$IBR" s-pl; _ib_h 2 'link'
  printf -v _ibx '{"type":"pr-link","prNumber":12,"prUrl":"https://github.com/acme/widget/pull/12","prRepository":"acme/widget","sessionId":"s-pl","timestamp":"%s"}' "$(_ibts 1)"
  _ib_raw "$_ibx"; _ib_a 1 'Linked.'; _ibage "$IB_F" 1
  IB_BR=""
  _ibopen "$IBP/-elsewhere/s-early.jsonl" s-early; _ib_h 20 "$IB_P95"; _ib_a 20 'Done.'; _ibage "$IB_F" 20
  _ibopen "$IBP/-elsewhere/s-run.jsonl" s-run
  printf -v _ibx '[{"type":"text","text":"<system-reminder>r</system-reminder>"},{"type":"text","text":"%s"}]' "$IB_P97"
  _ib_u 5 "$_ibx"; _ib_a 4 'On it.'; _ibage "$IB_F" 4
  _ibopen "$IBP/-elsewhere/s-late.jsonl" s-late; _ib_h 5 'hello'; _ib_a 5 'Hi.'; _ib_h 4 "$IB_P95"; _ib_a 4 'On it.'; _ibage "$IB_F" 4
  _ibopen "$IBP/-elsewhere/s-near.jsonl" s-near; _ib_h 5 "$IB_NEAR"; _ib_a 4 'On it.'; _ibage "$IB_F" 4
  _ibopen "$IBP/-elsewhere/s-hit.jsonl" s-hit; _ib_h 5 "$IB_HIT"; _ib_a 4 'On it.'; _ibage "$IB_F" 4
  _ibsess "$IBR/.claude/worktrees/gone-wt" s-gone; _ib_h 31 'note it'
  _ib_chip 30 toolu_100 task_100aaaaa 'From a removed worktree' "$IB_P100"; _ib_a 30 'Noted.'; _ibage "$IB_F" 30
}
_ib8() { _ibq -C "$1" rev-parse "$2" | cut -c1-8; }
_ibhead1() { _ibst "$@" | LC_ALL=C awk -F, '{ print $1 }'; }
_ibland() { LC_ALL=C awk -F'\t' '$1 != "cover" { n++; s = "," $4 ","
    if (index(s, ",landed,")) { k = split($4, t, ","); for (i = 1; i <= k; i++) if (t[i] ~ /^unknown:/ && t[i] != "unknown:live") printf "%s %s [%s]; ", $1, $3, $4 } }
  END { if (n < 20) printf "only %d rows", n }' "$@"; }
_ibm_five() { IB_BR=""; _ibsess "$IB/mw/five" s-five; _ib_h 10 'go'; _ib_a 9 'Done.'; _ibage "$IB_F" 9; }
# Signals: gh answers slowly; the run is sent TERM, HUP or INT while it waits.
_ibsig() {  # signal -> "gone" when the run exited and left no scratch
  local sig="$1" pid gp i=0 sd
  rm -f "$IB/gh.pid" "$IB/gh.log" "$IB/gh/release"; : > "$IB/gh/slow"
  ( cd "$IB/cwd" || exit 97
    unset FELIX_HOME FELIX_MEMORY CLAUDE_CONFIG_DIR GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE XDG_STATE_HOME XDG_CACHE_HOME
    export HOME="$IB/home" TMPDIR="$IB/tmp" FELIX_INVENTORY_TEMP_ROOTS="$IB/temproot" PATH="$IB/stub:$PATH" \
           GIT_CONFIG_NOSYSTEM=1 GIT_CEILING_DIRECTORIES="$IB"
    exec perl -e '$SIG{INT} = "DEFAULT"; $SIG{QUIT} = "DEFAULT"; exec @ARGV or exit 127' "$IBF" inventory --repo "$IB/m" --tsv --no-host ) >/dev/null 2>&1 &
  pid=$!
  while [ ! -s "$IB/gh.pid" ] && [ "$i" -lt 900 ] && kill -0 "$pid" 2>/dev/null; do sleep 0.2; i=$((i + 1)); done
  rm -f "$IB/gh/slow"
  if [ ! -s "$IB/gh.pid" ]; then kill -KILL "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; printf 'gh was never reached'; return; fi
  gp="$(cat "$IB/gh.pid")"; sd="$(LC_ALL=C awk -F'|' 'END { s = $5; sub(/\/[^\/]*$/, "", s); print s }' "$IB/gh.log")"
  kill "-$sig" "$pid" 2>/dev/null
  : > "$IB/gh/release"   # only now: until the signal is sent the run is still waiting on gh
  i=0; while kill -0 "$pid" 2>/dev/null && [ "$i" -lt 300 ]; do sleep 0.2; i=$((i + 1)); done
  kill -0 "$pid" 2>/dev/null && { kill -KILL "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; kill "$gp" 2>/dev/null; printf 'still running after %s' "$sig"; return; }
  wait "$pid" 2>/dev/null; kill "$gp" 2>/dev/null
  if [ -z "$sd" ]; then printf 'gh saw no XDG_STATE_HOME'
  elif [ -e "$sd" ]; then printf 'the scratch is left: %s' "$sd"
  elif [ -n "$(ls -A "$IB/tmp")" ]; then printf 'TMPDIR holds: %s' "$(ls -A "$IB/tmp" | tr '\n' ' ')"
  else printf gone; fi; }
# _ibgroup2 VIEW TEXT: the group heading above the first line holding TEXT
# after a heading, so the repository's own path line above the groups is not
# it; "unlisted" when no such line.
_ibgroup2() { LC_ALL=C awk -v t="$2" -v labs="$IB_LABELS" 'BEGIN { n = split(labs, L, "|") }
    { s = $0; sub(/^[ \t]+/, "", s); h = 0
      for (i = 1; i <= n; i++) if (substr(s, 1, length(L[i])) == L[i]) { r = substr(s, length(L[i]) + 1); if (r ~ /^[ \t:(]*[0-9]+[)]?[ \t]*$/) { g = L[i]; h = 1 } }
      if (!h && g != "" && index($0, t)) { print g; f = 1; exit } }
    END { if (!f) print "unlisted" }' "$1"; }
# An element of a detail holding every word given: "said" or "unsaid".
_ibsaid() { LC_ALL=C awk -v ws="$1" 'BEGIN { m = split(ws, W, " ") } { n = split($0, e, "; "); for (i = 1; i <= n; i++) { k = 0; for (j = 1; j <= m; j++) if (index(tolower(e[i]), W[j])) k++; if (k == m) f = 1 } } END { print (f ? "said" : "unsaid") }'; }

# _ib_h_build: the host repository h, with a worktree for each case 0920 reads. Needs _ib_build.
_ib_h_build() {
IB_EMO="$IB/hw/e$(printf '\360\237\230\200')x"
IB_LPAD="$(_ibp 'padding to push the record name past two hundred characters' 170)"; IB_LPAD="$(_ibenc "$IB_LPAD")"
IB_LONG1="$IB/long/one-$IB_LPAD"; IB_LONG2="$IB/long/two-$IB_LPAD"
  [ -e "$IB/hw/ord/ord2.txt" ] && return 0
# h: the host records. One worktree per case, each at main's tip on a branch
# never pushed, so what differs between them is only what the records say.
_ibnew h
IB_HT="$(_ibq -C "$IB/h" rev-parse HEAD)"
mkdir -p "$IB/hsym"; ln -s "$IB/hsym" "$IB/hl"
_ibhw() { _ibg -C "$IB/h" worktree add -q -b "$2" "$1" "$IB_HT"; }
_ibhw "$IB/hw/w.t_1" h-enc; _ibhw "$IB_EMO" h-emo; _ibhw "$IB/hl/sym" h-sym
_ibhw "$IB_LONG1" h-long1; _ibhw "$IB_LONG2" h-long2
for _ibn in act two blk blk2 ask ans-a ans-b ans-c sa-fence sa-span sa-quote sa-bq ng-a ng-b ng-c ng-d q-a q-b \
            bad-empty bad-cut bad-nojson side big-a big-b par ord ll cost notime mf-a mf-b blk-cost blk-human blk-meta two2 mf-cut; do
  _ibhw "$IB/hw/$_ibn" "h-$_ibn"
done
_ibhw "$IB/h/.claude/worktrees/agent-a1b2c3" agent-a1b2c3; _ibhw "$IB/h/.claude/worktrees/agent-a9b9c9" agent-a9b9c9
_ibmk 300 "$IB/h" "$IB_HT" 'act, five hours ago' act.txt act; _ibg -C "$IB/hw/act" reset -q --hard "$IBC"
printf 'ord\n' > "$IB/hw/ord/ord.txt"; _ibci "$IB/hw/ord" 'ord, nowhere else'; printf 'more\n' > "$IB/hw/ord/ord2.txt"
_ibg -C "$IB/h" remote set-url origin git@github.com:acme/hotel.git
IB_SYM="$(_ibq -C "$IB/h" worktree list --porcelain | LC_ALL=C awk '/^worktree .*\/sym$/ { sub(/^worktree /, ""); print }')"
}

# _ib_r_runs: the records of r, then RUN1 to RUN4. Needs _ib_build; the guard is RUN4.
_ib_r_runs() {
  [ -e "$IB/runs/RUN4.rc" ] && return 0
# ---- r: the runs ---------------------------------------------------------
# RUN1 reads r and r2 with gh, the git spy first on PATH and a memory root
# set; RUN2 under --no-gh; RUN3 under --no-host; RUN4 with a records root
# that holds nothing.
_ibr_records
rm -f "$IB/gh.log" "$IB/git.log" "$IB/net.log"
IB_SNAP15="$(_ibsnap "$IB/home"; _ibsnap "$IB/mem")"; : > "$IB/run1.mark"
_ibrun RUN1 --path "$IB/spy:$IB/stub:$PATH" --env "FELIX_MEMORY=$IB/mem" -- inventory --repo "$IBR" --repo "$IB/r2" --tsv
IB_SNAP15B="$(_ibsnap "$IB/home"; _ibsnap "$IB/mem")"; IB_NEW15="$(find "$IB/home" "$IB/mem" -newer "$IB/run1.mark" -print | LC_ALL=C awk 'NR <= 3' | tr '\n' ' ')"
mv "$IB/gh.log" "$IB/gh1.log" 2>/dev/null; mv "$IB/git.log" "$IB/git1.log" 2>/dev/null
IB_TMP1="$(ls -A "$IB/tmp" | tr '\n' ' ')"
_ibrun RUN2 -- inventory --repo "$IBR" --tsv --no-gh
IB_GH2="$([ -e "$IB/gh.log" ] && echo 'gh ran' || echo 'gh never ran')"
_ibrun RUN3 -- inventory --repo "$IBR" --tsv --no-host
_ibrun RUN4 --home "$IB/home0" -- inventory --repo "$IBR" --tsv
}

# _ib_n16: the runs 0930 lists in N16 that 0920 makes, in 0920's order. Needs _ib_build h; the
# guard is T3.
_ib_n16() {
  [ -e "$IB/runs/T3.rc" ] && return 0
IB_BR=""; _ibsess "$IB/m" s-old20; _ib_h 28802 'note what is left'
_ib_chip 28801 toolu_99 task_01d0 'Twenty days old' "$IB_P99"; _ib_a 28800 'Noted.'; _ibage "$IB_F" 28800
_ibm_five; _ibrun A5a -- inventory --repo "$IB/m" --tsv --no-gh --live 999999
_ibm_five; _ibrun A5b -- inventory --repo "$IB/m" --tsv --no-gh --live 010 --days 3
_ibm_five; _ibrun A5c -- inventory --repo "$IB/m" --tsv --no-gh --live 008 --days 30
_ibrun M1 -- inventory --repo "$IB/m" --tsv
_ibrun A31a -- inventory --repo "$IB/m" --tsv --no-host
_ibrun A31b --home "$IB/homenone" -- inventory --repo "$IB/m" --tsv
IB_BR=""; _ibopen "$IB/ccd/projects/$(_ibenc "$IB/mw/five")/s-ccd.jsonl" s-ccd; _ib_h 6 'go'; _ib_a 5 'Done.'; _ibage "$IB_F" 5
_ibrun CCD --env "CLAUDE_CONFIG_DIR=$IB/ccd" -- inventory --repo "$IB/m" --tsv --no-gh
mkdir -p "$IB/nogh"
_ibifs="$IFS"; IFS=:
for _ibd in $PATH; do
  IFS="$_ibifs"; [ -d "$_ibd" ] || continue
  for _ibf in "$_ibd"/*; do
    _ibn="${_ibf##*/}"; [ "$_ibn" = gh ] && continue
    [ -e "$IB/nogh/$_ibn" ] || [ -L "$IB/nogh/$_ibn" ] || { [ -x "$_ibf" ] && [ ! -d "$_ibf" ] && ln -s "$_ibf" "$IB/nogh/$_ibn"; }
  done
done
IFS="$_ibifs"
_ibrun A27 --path "$IB/stubng:$IB/nogh" -- inventory --repo "$IB/m" --tsv --no-host
_ibrun MISC -- inventory --repo "$IB/noorigin" --repo "$IB/unborn" --repo "$IB/fb1" --repo "$IB/fb2" --repo "$IB/bwt" --tsv --no-host
_ibrun PART -- inventory --repo "$IB/partial" --repo "$IB/shallow" --tsv --no-host
_ibrun K -- inventory --repo "$IB/k" --tsv --no-host
IB_BR=""; _ibsess "$IB/r3" s-r3; _ib_h 3 'link it'
printf -v _ibx '{"type":"pr-link","prNumber":12,"prRepository":"whoever/whatever","sessionId":"s-r3","timestamp":"%s"}' "$(_ibts 2)"
_ib_raw "$_ibx"; _ib_a 2 'Linked.'; _ibage "$IB_F" 2
rm -f "$IB/gh.log"; _ibrun R3 -- inventory --repo "$IB/r3" --tsv
rm -f "$IB/gh.log"; _ibrun U -- inventory --repo "$IB/u1" --repo "$IB/u2" --repo "$IB/u3" --repo "$IB/u4" --tsv --no-host
rm -f "$IB/ran-clean"
_ibrun F -- inventory --repo "$IB/f" --tsv --no-host
rm -f "$IB/gpg-ran"
_ibrun G -- inventory --repo "$IB/g" --tsv --no-host
_ibh_records; IB_H0="$(date +%s)"
_ibrun H1 -- inventory --repo "$IB/h" --tsv
IB_HD=$(( ($(date +%s) - IB_H0 + 59) / 60 ))
_ibh_two; _ibrun H2 -- inventory --repo "$IB/h" --tsv --live 80
_ibrun O1 -- inventory --repo "$IB/o" --tsv --no-host
IB_BR=""; _ibsess "$IB/vw/blk" s-vblk; _ib_h 40 'watch it'
_ib_tu 35 toolu_v1 Bash '{"command":"watch-the-ledger","description":"Watch the ledger"}'; _ibage "$IB_F" 35
_ibrun V1 -- inventory --repo "$IB/v" --tsv; _ibrun V2 -- inventory --repo "$IB/v"
_ibnew b6
_ibg -C "$IB/b6" worktree add -q -b b6live "$IB/b6/.claude/worktrees/live1"
mkdir -p "$IB/b6/.claude/worktrees/gone6"
printf 'unique, in no object\n' > "$IB/b6/.claude/worktrees/gone6/u"; chmod 000 "$IB/b6/.claude/worktrees/gone6"
if [ -r "$IB/b6/.claude/worktrees/gone6/u" ]; then
  chmod 755 "$IB/b6/.claude/worktrees/gone6"
else
  _ibrun B6T -- inventory --repo "$IB/b6" --tsv --no-gh --no-host; _ibrun B6V -- inventory --repo "$IB/b6" --no-gh --no-host
  chmod 755 "$IB/b6/.claude/worktrees/gone6"
fi
_ibrun T1 -- inventory --repo "$IB/t" --tsv --no-host
_ibrun T3 --env "FELIX_INVENTORY_TEMP_ROOTS=$IB/tlink" -- inventory --repo "$IB/t" --tsv --no-host
}
