# >>> helper-worktrees-inventory
printf '\nhelper worktrees placed apart: felix inventory states and its human view (contract Part C, C5.1-13, blind)\n'
# Blind, written on 2026-10-23 from docs/2026-10-18-lost-work-page-contract.md (Part C, with Parts A
# and B around it) and the inventory spec (sections 4.1, 4.2, 4.6, 4.8, 5.2, 6.1, 6.3, 6.4, 8) alone.
# No engine code was read: felix was run as a black box. The stubs, the runner and the TSV readers are
# tests/lib/lost-work.sh's (_lw_build); every fixture here is this part's own, under $LW, so it runs
# alone and in the serial order.
#
# hw5: helper worktrees of every C5 inventory case, in .claude/worktrees under the main worktree (as the
# host makes them), each a worktree of hw5 on a branch of its own from main. A helper is named by a
# meta file under the main worktree's session s5-boss (subagents/, at any depth), as section 6.4 reads.
# hv5: the human view's cases, so that its helper section holds exactly the two rows C5.9 counts.
_lw_build
_hw5_meta() {  # RECORD-ROOT DIR-OF-SPAWNER SID REL-FILE WORKTREE-PATH DESCRIPTION: a meta file and its sibling .jsonl, both 300 minutes old
  local f="$1/$(_lw_enc "$2")/$3/subagents/$4"
  mkdir -p "${f%/*}"
  printf '{"agentType":"general-purpose","description":"%s","worktreePath":"%s"}\n' "$6" "$5" > "$f.meta.json"
  printf '{}\n' > "$f.jsonl"; _lw_age "$f.meta.json" 300; _lw_age "$f.jsonl" 300
}
_hw5_wt() {  # REPO PATH BRANCH [FILE CONTENT]: a worktree on a new branch from main, with one commit of FILE when given
  _lwg "$1" worktree add -q -b "$3" "$2" main >/dev/null 2>&1
  [ -n "${4:-}" ] || return 0
  printf '%s\n' "$5" > "$2/$4"; _lwg "$2" add -A >/dev/null 2>&1; _lwg "$2" commit -qm "$4" >/dev/null 2>&1
}
_hw5_blk() {  # DIR SID TOOL: a session in DIR's own record directory whose last record is a tool call 290 minutes old, unanswered
  _lw_sess "$1" "$2"; _lw_h 292 'run the checks'
  _lw_tu 290 "toolu_$2" "$3" '{"command":"run-the-checks","description":"Run the checks"}'; _lw_age "$LW_F" 290
}

# ---- hw5 ------------------------------------------------------------------------------
_lw_repo hw5; HW5="$LW/hw5"; HW5W="$HW5/.claude/worktrees"; mkdir -p "$HW5W"
_lw_prs fixture_hw5
_hw5_wt "$HW5" "$HW5W/agent-a1b2c3d4" hw5-h1 h1.txt 'the parser'                 # C5.1: one unpushed commit
_hw5_wt "$HW5" "$HW5W/agent-b2c3d4e5" hw5-h2                                     # C5.2: nothing of its own
_hw5_wt "$HW5" "$HW5W/wf_abc123-7" hw5-h3                                        # C5.3: a workflow agent's
for _hw5i in agent-xyz wf_abc wf_abc-1x my-agent-a1b2; do _hw5_wt "$HW5" "$HW5W/$_hw5i" "hw5-n-$_hw5i"; done   # C5.3: other names
_hw5_wt "$HW5" "$HW5W/agent-d4e5f6a7" hw5-h4 h4.txt 'the dead agent'             # C5.4: blocked, unpushed
_hw5_wt "$HW5" "$HW5W/wf_dead01-3" hw5-h4b h4b.txt 'the dead workflow agent'      # C5.4: blocked, pushed under its own name
_lwg "$HW5W/wf_dead01-3" push -q -u origin hw5-h4b >/dev/null 2>&1
_hw5_wt "$HW5" "$HW5W/agent-a8a8a8a8" hw5-h8 d8.txt 'the same change twice'      # C5.8: a possible duplicate of dup-twin
_hw5_wt "$HW5" "$HW5W/dup-twin" hw5-twin d8.txt 'the same change twice'
mkdir -p "$HW5W/agent-e5f6a7b8"; printf 'an orphan of its own words\n' > "$HW5W/agent-e5f6a7b8/o.txt"   # C5.7: an orphan, content not
mkdir -p "$HW5W/agent-f6a7b8c9"; printf 'hw5\n' > "$HW5W/agent-f6a7b8c9/README.md"                  # C5.7: an orphan, content landed
# C5.11: a detached worktree at a commit that only another remote's ref holds: not unpushed, not carried
# (only origin's refs carry, A1), content not, so it holds no state of its own.
_lw_mk "$HW5" "$(_lwq "$HW5" refs/heads/main)" 'upstream only' up.txt 'on upstream'; HW5UP="$LWC"
_lwg "$HW5" update-ref refs/remotes/upstream/feature-x "$HW5UP" >/dev/null 2>&1
_lwg "$HW5" worktree add -q --detach "$HW5W/agent-c0ffee11" "$HW5UP" >/dev/null 2>&1
_lwg "$HW5" fetch -q origin >/dev/null 2>&1
# Records, home A: the spawning session in the main worktree's record directory, a meta file for
# each helper and for each name of another form, and the two dead agents' own sessions.
HW5A="$LW/hh5a"; HW5RR="$HW5A/.claude/projects"; LW_RR="$HW5RR"; mkdir -p "$HW5RR"
_lw_sess "$HW5" s5-boss; _lw_h 302 'spawn the helpers'; _lw_a 300 'Spawned them.'; _lw_age "$LW_F" 300
_hw5_meta "$HW5RR" "$HW5" s5-boss agent-h1 "$HW5W/agent-a1b2c3d4" 'write the parser'
_hw5_meta "$HW5RR" "$HW5" s5-boss agent-h2 "$HW5W/agent-b2c3d4e5" 'read the notes'
_hw5_meta "$HW5RR" "$HW5" s5-boss workflows/wf_abc123/agent-w7 "$HW5W/wf_abc123-7" 'derive the cases'
_hw5_meta "$HW5RR" "$HW5" s5-boss agent-n1 "$HW5W/agent-xyz" 'not hex'
_hw5_meta "$HW5RR" "$HW5" s5-boss agent-n2 "$HW5W/wf_abc" 'no number'
_hw5_meta "$HW5RR" "$HW5" s5-boss agent-n3 "$HW5W/wf_abc-1x" 'not all digits'
_hw5_meta "$HW5RR" "$HW5" s5-boss agent-n4 "$HW5W/my-agent-a1b2" 'a prefix before agent'
_hw5_meta "$HW5RR" "$HW5" s5-boss agent-h4 "$HW5W/agent-d4e5f6a7" 'run the checks'
_hw5_meta "$HW5RR" "$HW5" s5-boss workflows/wf_dead01/agent-w3 "$HW5W/wf_dead01-3" 'return the parts'
_hw5_meta "$HW5RR" "$HW5" s5-boss agent-h8 "$HW5W/agent-a8a8a8a8" 'make the twin'
_hw5_meta "$HW5RR" "$HW5" s5-boss agent-o7 "$HW5W/agent-e5f6a7b8" 'leave an orphan'
_hw5_meta "$HW5RR" "$HW5" s5-boss agent-o8 "$HW5W/agent-f6a7b8c9" 'leave a landed orphan'
_hw5_meta "$HW5RR" "$HW5" s5-boss agent-c11 "$HW5W/agent-c0ffee11" 'hold the upstream commit'
_hw5_blk "$HW5W/agent-d4e5f6a7" s5-dead Bash
_hw5_blk "$HW5W/wf_dead01-3" s5-wfdead StructuredOutput
# Home B: the same records with every meta file removed. Home U: a records root the run cannot read.
HW5B="$LW/hh5b"; mkdir -p "$HW5B/.claude"; cp -Rp "$HW5RR" "$HW5B/.claude/projects"
find "$HW5B/.claude/projects" -name '*.meta.json' -exec rm -f {} + 2>/dev/null
HW5U="$LW/hh5u"; mkdir -p "$HW5U/.claude"; cp -Rp "$HW5RR" "$HW5U/.claude/projects"; chmod 000 "$HW5U/.claude/projects"

_lw_run C5HA "$HW5A" "$LW/cwd" inventory --tsv --repo "$HW5"
_lw_run C5HG "$HW5A" "$LW/cwd" inventory --tsv --no-gh --repo "$HW5"
_lw_run C5HN "$HW5A" "$LW/cwd" inventory --tsv --no-host --repo "$HW5"
_lw_run C5HB "$HW5B" "$LW/cwd" inventory --tsv --repo "$HW5"
_lw_run C5HU "$HW5U" "$LW/cwd" inventory --tsv --repo "$HW5"
_lw_run C5HV "$HW5A" "$LW/cwd" inventory --repo "$HW5"
chmod 755 "$HW5U/.claude/projects"

# ---- hv5 ----------------------------------------------------------------------------------
_lw_repo hv5; HV5="$LW/hv5"; HV5W="$HV5/.claude/worktrees"; mkdir -p "$HV5W" "$LW/temproot/hv5"
_lw_prs fixture_hv5
_hw5_wt "$HV5" "$HV5W/agent-9a9a9a01" hv5-v1 v1.txt 'unpushed helper work'      # unpushed
_hw5_wt "$HV5" "$HV5W/agent-9b9b9b02" hv5-v2                                     # blocked
_hw5_wt "$HV5" "$HV5W/agent-9c9c9c03" hv5-v3                                     # landed
_hw5_wt "$HV5" "$HV5W/agent-9d9d9d04" hv5-v4                                     # live, landed
_hw5_wt "$HV5" "$LW/temproot/hv5/agent-9e9e9e05" hv5-vt vt.txt 'temporary helper work'   # temp, unpushed
_hw5_wt "$HV5" "$HV5W/plain-v6" hv5-v6 v6.txt 'plain unpushed work'               # a plain unpushed worktree
HV5A="$LW/hv5a"; LW_RR="$HV5A/.claude/projects"; mkdir -p "$LW_RR"
_lw_sess "$HV5" s5-vboss; _lw_h 302 'spawn the helpers'; _lw_a 300 'Spawned them.'; _lw_age "$LW_F" 300
_hw5_meta "$LW_RR" "$HV5" s5-vboss agent-v1 "$HV5W/agent-9a9a9a01" 'write the reader'
_hw5_meta "$LW_RR" "$HV5" s5-vboss agent-v2 "$HV5W/agent-9b9b9b02" 'wait on the tool'
_hw5_meta "$LW_RR" "$HV5" s5-vboss agent-v3 "$HV5W/agent-9c9c9c03" 'land the notes'
_hw5_meta "$LW_RR" "$HV5" s5-vboss agent-v4 "$HV5W/agent-9d9d9d04" 'keep working'
_hw5_meta "$LW_RR" "$HV5" s5-vboss agent-vt "$LW/temproot/hv5/agent-9e9e9e05" 'work in a temporary place'
_lw_age "$LW_RR/$(_lw_enc "$HV5")/s5-vboss/subagents/agent-v4.jsonl" 1
_hw5_blk "$HV5W/agent-9b9b9b02" s5-vwait Bash
HV5B="$LW/hv5b"; mkdir -p "$HV5B/.claude"; cp -Rp "$LW_RR" "$HV5B/.claude/projects"
find "$HV5B/.claude/projects" -name '*.meta.json' -exec rm -f {} + 2>/dev/null
_lw_run C5VA "$HV5A" "$LW/cwd" inventory --tsv --repo "$HV5"
_lw_run C5VV "$HV5A" "$LW/cwd" inventory --repo "$HV5"
_lw_run C5VB "$HV5B" "$LW/cwd" inventory --repo "$HV5"
_lw_run C5VBT "$HV5B" "$LW/cwd" inventory --tsv --repo "$HV5"

# ---- reading the human view ---------------------------------------------------------------
# A heading is a line of two spaces, a label, two spaces and a count; a row line is four spaces, a
# kind and a path (relative to the main worktree, or absolute). A row is found by its path's last
# component, every fixture name being distinct.
_hw5_vg() {  # FILE NAME -> "[heading]" for each row line naming NAME, space-separated, or "unlisted"
  LC_ALL=C awk -v n="$2" '
    /^  [^ ].*  [0123456789]+$/ { g = $0; sub(/^  /, "", g); sub(/  [0123456789]+$/, "", g); next }
    /^    [abcdefghijklmnopqrstuvwxyz]+ +[^ ]/ { k = split($2, s, "/"); if (s[k] == n) out = out (out == "" ? "" : " ") "[" g "]" }
    END { print (out == "" ? "unlisted" : out) }' "$1" 2>/dev/null; }
_hw5_vrow() {  # FILE NAME -> the first row line naming NAME
  LC_ALL=C awk -v n="$2" '/^    [abcdefghijklmnopqrstuvwxyz]+ +[^ ]/ { k = split($2, s, "/"); if (s[k] == n) { print; exit } }' "$1" 2>/dev/null; }
_hw5_vh() {  # FILE LABEL -> "COUNT@LINE" for each heading LABEL, space-separated, or "none"
  LC_ALL=C awk -v l="$2" 'index($0, "  " l "  ") == 1 && substr($0, length(l) + 5) ~ /^[0123456789]+$/ { out = out (out == "" ? "" : " ") substr($0, length(l) + 5) "@" NR }
    END { print (out == "" ? "none" : out) }' "$1" 2>/dev/null; }
_hw5_vlast() {  # FILE -> "live N, landed N" from the last line
  LC_ALL=C awk '/^  live [0123456789]+/ { l = $0 } END { sub(/^  /, "", l); sub(/ \([^)]*\)/, "", l); split(l, e, ", "); print e[1] ", " e[2] }' "$1" 2>/dev/null; }
_hw5_in() { case "$1" in *"$2"*) printf '%s' "$3" ;; *) printf '%s' "$4" ;; esac; }   # STRING PART YES NO
_hw5_last() {  # FILE KIND REF -> the last entry of the row's states
  local s; s="$(_lw_st "$1" "$2" "$3")"; printf '%s' "${s##*,}"; }

# ---- inventory: C5.1 to C5.8 ------------------------------------------------------------------
H1="$HW5W/agent-a1b2c3d4"; H2="$HW5W/agent-b2c3d4e5"; H3="$HW5W/wf_abc123-7"; H4="$HW5W/agent-d4e5f6a7"
H4B="$HW5W/wf_dead01-3"; H8="$HW5W/agent-a8a8a8a8"; H11="$HW5W/agent-c0ffee11"; HO7="$HW5W/agent-e5f6a7b8"; HO8="$HW5W/agent-f6a7b8c9"
HA="$(_lw_o C5HA)"; HG="$(_lw_o C5HG)"; HN="$(_lw_o C5HN)"; HB="$(_lw_o C5HB)"; HU="$(_lw_o C5HU)"; HV="$(_lw_o C5HV)"
_hw5o=""; for _hw5i in C5HA C5HG C5HN C5HB C5HU C5HV; do _hw5o="$_hw5o$(_lw_rc $_hw5i)$([ -s "$(_lw_o $_hw5i)" ] && echo + || echo -)"; done
is "C5.1 fixture: the six inventory runs over hw5 exit 0 and print something (control)" "$_hw5o" "0+0+0+0+0+0+"
_hw5o=""; for _hw5i in agent-xyz wf_abc wf_abc-1x my-agent-a1b2; do
  LC_ALL=C grep -l -F "\"worktreePath\":\"$HW5W/$_hw5i\"" -r "$HW5RR" >/dev/null 2>&1 && _hw5o="$_hw5o y" || _hw5o="$_hw5o n"; done
is "C5.3 fixture: each name of another form has a meta file naming its path in the records (control)" "$_hw5o" " y y y y"
# C5.1
is "C5.1: a helper worktree with one unpushed commit reads exactly unpushed,helper" "$(_lw_st "$HA" worktree "$H1")" "unpushed,helper"
is "C5.1 control: its detail still holds spawned by session s5-boss: write the parser, so its meta file was found" \
   "$(_lw_elem "$HA" worktree "$H1" 'spawned by session s5-boss: write the parser')" yes
# C5.2
is "C5.2: a helper worktree whose content is landed and that holds nothing else reads landed,helper" "$(_lw_st "$HA" worktree "$H2")" "landed,helper"
is "C5.2 control: its detail holds spawned by session s5-boss: read the notes" "$(_lw_elem "$HA" worktree "$H2" 'spawned by session s5-boss: read the notes')" yes
is "C5.2: the same directory with no matching meta file reads landed, and no helper" "$(_lw_st "$HB" worktree "$H2")" "landed"
is "C5.2 control: with the meta files removed no row's detail names a spawning session" \
   "$(LC_ALL=C awk -F'\t' 'index($8, "spawned by session") { n++ } END { print n + 0 }' "$HB" 2>/dev/null)" 0
# C5.3
is "C5.3: a wf_<id>-<n> worktree with a matching meta file holds helper" "$(_lw_holds "$HA" worktree "$H3" helper)" yes
is "C5.3 control: its detail holds spawned by session s5-boss: derive the cases" "$(_lw_elem "$HA" worktree "$H3" 'spawned by session s5-boss: derive the cases')" yes
_hw5o=""; for _hw5i in agent-xyz wf_abc wf_abc-1x my-agent-a1b2; do _hw5o="$_hw5o $(_lw_many "$HA" worktree "$HW5W/$_hw5i" 0 helper unknown:helper)"; done
is "C5.3: agent-xyz, wf_abc, wf_abc-1x and my-agent-a1b2, each named by a meta file, hold neither helper nor unknown:helper" \
   "$_hw5o" " helper=no unknown:helper=no helper=no unknown:helper=no helper=no unknown:helper=no helper=no unknown:helper=no"
# C5.4
is "C5.4: a helper whose last call is unanswered past --blocked, with an unpushed commit, reads exactly blocked,unpushed,helper" \
   "$(_lw_st "$HA" worktree "$H4")" "blocked,unpushed,helper"
is "C5.4: a dead workflow agent's worktree, pushed under its own name with no PR, reads blocked,unproposed,helper" \
   "$(_lw_st "$HA" worktree "$H4B")" "blocked,unproposed,helper"
is "C5.4 control: under --no-gh that worktree holds blocked and carries an unknown: entry" \
   "$(_lw_holds "$HG" worktree "$H4B" blocked) $(_hw5_in ",$(_lw_st "$HG" worktree "$H4B")" ,unknown: unknown none)" "yes unknown"
is "C5.4: under --no-gh its states are blocked, then helper, then only unknown: entries" \
   "$(_lw_st "$HG" worktree "$H4B" | LC_ALL=C awk -F, '{ ok = (NF > 2 && $1 == "blocked" && $2 == "helper"); for (i = 3; i <= NF; i++) if (index($i, "unknown:") != 1) ok = 0; print (ok ? "ordered" : $0) }')" ordered
# C5.5
is "C5.5 control: under --no-host the sessions cover row is unknown, --no-host" \
   "$(_lw_st "$HN" cover sessions | LC_ALL=C cut -d, -f1) $(_lw_col "$HN" cover sessions 8)" "unknown --no-host"
_hw5o=""; for _hw5i in "worktree $H1" "worktree $H2" "worktree $H3" "worktree $H4" "worktree $H4B" "worktree $H8" "worktree $H11" "orphan $HO7" "orphan $HO8"; do
  [ "$(_hw5_last "$HN" ${_hw5i%% *} "${_hw5i#* }")" = unknown:helper ] && [ "$(_lw_holds "$HN" ${_hw5i%% *} "${_hw5i#* }" helper)" = no ] || _hw5o="$_hw5o [${_hw5i##*/}: $(_lw_st "$HN" ${_hw5i%% *} "${_hw5i#* }")]"; done
is "C5.5: under --no-host each helper-form worktree and orphan carries unknown:helper, last of its states, and no helper" "$_hw5o" ""
_hw5o=""; for _hw5i in "$HW5" "$HW5W/agent-xyz" "$HW5W/wf_abc" "$HW5W/wf_abc-1x" "$HW5W/my-agent-a1b2" "$HW5W/dup-twin"; do _hw5o="$_hw5o $(_lw_holds "$HN" worktree "$_hw5i" unknown:helper)"; done
is "C5.5: under --no-host a worktree of another name carries no unknown:helper" "$_hw5o" " no no no no no no"
# C5.6
is "C5.6 control: with the records root unreadable the main worktree's owner is unknown, where it is s5-boss when the root is read" \
   "$(_lw_col "$HU" worktree "$HW5" 5) $(_lw_col "$HA" worktree "$HW5" 5)" "unknown s5-boss"
_hw5o=""; for _hw5i in "worktree $H1" "worktree $H2" "worktree $H3" "worktree $H4" "worktree $H4B" "worktree $H8" "worktree $H11" "orphan $HO7" "orphan $HO8"; do
  [ "$(_lw_many "$HU" ${_hw5i%% *} "${_hw5i#* }" 0 unknown:helper helper)" = "unknown:helper=yes helper=no" ] || _hw5o="$_hw5o [${_hw5i##*/}: $(_lw_st "$HU" ${_hw5i%% *} "${_hw5i#* }")]"; done
is "C5.6: with a records root the run cannot read, each helper-form row carries unknown:helper and no helper" "$_hw5o" ""
_hw5o=""; for _hw5i in "$HW5" "$HW5W/agent-xyz" "$HW5W/my-agent-a1b2" "$HW5W/dup-twin"; do _hw5o="$_hw5o $(_lw_holds "$HU" worktree "$_hw5i" unknown:helper)"; done
is "C5.6: and a worktree of another name carries no unknown:helper there" "$_hw5o" " no no no no"
# C5.7
is "C5.7 control: agent-e5f6a7b8 is an orphan row holding orphan, content not, whose detail names its spawning session" \
   "$(_lw_kind "$HA" "$HO7") $(_lw_holds "$HA" orphan "$HO7" orphan) $(_lw_col "$HA" orphan "$HO7" 7) $(_lw_elem "$HA" orphan "$HO7" 'spawned by session s5-boss: leave an orphan')" \
   "orphan yes not yes"
is "C5.7: an orphan directory named agent-<hex> beside the worktrees, with a matching meta file, reads orphan,helper" "$(_lw_st "$HA" orphan "$HO7")" "orphan,helper"
is "C5.7: an orphan of that form whose content is landed holds helper, last of its states" \
   "$(_lw_col "$HA" orphan "$HO8" 7) $(_hw5_last "$HA" orphan "$HO8")" "landed helper"
# C5.8
is "C5.8 control: the helper agent-a8a8a8a8 and the plain dup-twin are each other's possible duplicates" \
   "$(_lw_holds "$HA" worktree "$H8" possible-duplicate) $(_lw_holds "$HA" worktree "$HW5W/dup-twin" possible-duplicate)" "yes yes"
is "C5.8: possible-duplicate on a helper row comes after helper: unpushed,helper,possible-duplicate" "$(_lw_st "$HA" worktree "$H8")" "unpushed,helper,possible-duplicate"

# ---- the human view: C5.9 to C5.13 ----------------------------------------------------------------
V1=agent-9a9a9a01; V2=agent-9b9b9b02; V3=agent-9c9c9c03; V4=agent-9d9d9d04; VT=agent-9e9e9e05
VA="$(_lw_o C5VA)"; VV="$(_lw_o C5VV)"; VB="$(_lw_o C5VB)"; VBT="$(_lw_o C5VBT)"
_hw5o=""; for _hw5i in C5VA C5VV C5VB C5VBT; do _hw5o="$_hw5o$(_lw_rc $_hw5i)$([ -s "$(_lw_o $_hw5i)" ] && echo + || echo -)"; done
is "C5.9 fixture: the four inventory runs over hv5 exit 0 and print something (control)" "$_hw5o" "0+0+0+0+"
is "C5.9 control: the unpushed, blocked, landed, live and temporary helper rows each name their spawning session in hv5's TSV" \
   "$(_lw_elem "$VA" worktree "$HV5W/$V1" 'spawned by session s5-vboss: write the reader') $(_lw_elem "$VA" worktree "$HV5W/$V2" 'spawned by session s5-vboss: wait on the tool') $(_lw_elem "$VA" worktree "$HV5W/$V3" 'spawned by session s5-vboss: land the notes') $(_lw_elem "$VA" worktree "$HV5W/$V4" 'spawned by session s5-vboss: keep working') $(_lw_elem "$VA" worktree "$LW/temproot/hv5/$VT" 'spawned by session s5-vboss: work in a temporary place')" \
   "yes yes yes yes yes"
_hw5o="$(_hw5_vh "$VV" 'in helper worktrees')"
is "C5.9: the view has one helper section, headed in helper worktrees with the count 2" "${_hw5o%@*}" 2
_hw5t="$(_hw5_vh "$VV" 'in temporary directories')"
_hw5x="helper [$_hw5o] temporary [$_hw5t]"
case "$_hw5o$_hw5t" in *none*|*' '*) ;; *) [ "${_hw5o#*@}" -gt "${_hw5t#*@}" ] && _hw5x=after || _hw5x=before ;; esac
is "C5.9: the helper section comes after the in temporary directories section" "$_hw5x" after
is "C5.9: the unpushed helper and the blocked helper are listed once each, in the helper section, under neither unpushed nor blocked" \
   "$(_hw5_vg "$VV" "$V1") $(_hw5_vg "$VV" "$V2")" "[in helper worktrees] [in helper worktrees]"
is "C5.9 control: the plain unpushed worktree is listed under unpushed" "$(_hw5_vg "$VV" plain-v6)" "[unpushed]"
_hw5o="$(_hw5_vrow "$VV" "$V1")|$(_hw5_vrow "$VV" "$V2")"
is "C5.9 (C3): in the helper section each row shows its headline, unpushed and blocked, and helper is not printed beside it" \
   "$(_hw5_in "${_hw5o%%|*}" '[unpushed]' unpushed "[${_hw5o%%|*}]") $(_hw5_in "${_hw5o#*|}" '[blocked]' blocked "[${_hw5o#*|}]") $(_hw5_in "$_hw5o" helper helper clean)" \
   "unpushed blocked clean"
is "C5.10: the landed helper (landed,helper) and the live helper (live,landed,helper) are listed nowhere in the view" \
   "$(_lw_st "$VA" worktree "$HV5W/$V3") $(_lw_st "$VA" worktree "$HV5W/$V4") $(_hw5_vg "$VV" "$V3") $(_hw5_vg "$VV" "$V4")" \
   "landed,helper live,landed,helper unlisted unlisted"
is "C5.10: the last line counts the live helper in live and the landed helper in landed, as the TSV's rows say" \
   "$(_hw5_vlast "$VV")" \
   "$(LC_ALL=C awk -F'\t' -v l3="$HV5W/$V3" -v l4="$HV5W/$V4" '$1 != "cover" { s = "," $4 ","; if (index(s, ",live,")) { v++; if ($3 == l4) c4 = 1 } else if (index(s, ",landed,")) { d++; if ($3 == l3) c3 = 1 } }
       END { if (c3 && c4) printf "live %d, landed %d", v, d; else print "the helpers are not counted in the TSV" }' "$VA" 2>/dev/null)"
is "C5.12: a worktree that is both temp and helper (unpushed,helper) is listed in the temporary section only" \
   "$(_lw_st "$VA" worktree "$LW/temproot/hv5/$VT") $(_hw5_vg "$VV" "$VT")" "unpushed,helper [in temporary directories]"
is "C5.13: with no helper row (every meta file removed) no in helper worktrees line is printed" \
   "$(LC_ALL=C awk -F'\t' 'index("," $4 ",", ",helper,") { n++ } END { print n + 0 }' "$VBT" 2>/dev/null) $(LC_ALL=C grep -c '^ *in helper worktrees' "$VB")" "0 0"
is "C5.13 control: without meta files the unpushed and the blocked helper-form worktrees are listed under unpushed and blocked" \
   "$(_hw5_vg "$VB" "$V1") $(_hw5_vg "$VB" "$V2")" "[unpushed] [blocked]"
# C5.11, on hw5's view
is "C5.11: a helper holding no other state, content not, reads exactly helper" "$(_lw_st "$HA" worktree "$H11") $(_lw_col "$HA" worktree "$H11" 7)" "helper not"
is "C5.11 control: that worktree's content is not and its detail names its spawning session" \
   "$(_lw_col "$HA" worktree "$H11" 7) $(_lw_elem "$HA" worktree "$H11" 'spawned by session s5-boss: hold the upstream commit')" "not yes"
is "C5.11: it is listed in the helper section, where undecided, content not landed would list it" "$(_hw5_vg "$HV" agent-c0ffee11)" "[in helper worktrees]"
# <<< helper-worktrees-inventory
