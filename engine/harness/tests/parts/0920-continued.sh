# ---- m: arguments, environment, signals and gh's failures ----------------
_ib_build h
IB_BR=""; _ibsess "$IB/m" s-old20; _ib_h 28802 'note what is left'
_ib_chip 28801 toolu_99 task_01d0 'Twenty days old' "$IB_P99"; _ib_a 28800 'Noted.'; _ibage "$IB_F" 28800
_ibm_five; _ibrun A5a -- inventory --repo "$IB/m" --tsv --no-gh --live 999999
_ibm_five; _ibrun A5b -- inventory --repo "$IB/m" --tsv --no-gh --live 010 --days 3
_ibm_five; _ibrun A5c -- inventory --repo "$IB/m" --tsv --no-gh --live 008 --days 30
is  "inventory A5: six digits is the longest number, and leading zeros are decimal: --live 010 holds a 9-minute session live, --live 008 does not" \
    "$(_ibrc A5a) $(_ibrc A5b) $(_ibrc A5c) $(_ibholds A5b worktree "$IB/mw/five" live) $(_ibholds A5c worktree "$IB/mw/five" live)" "0 0 0 yes no"
_ibrun M1 -- inventory --repo "$IB/m" --tsv
is  "inventory A99: a chip from a session 20 days old is read under --days 30 and not under the default 14" "$(_ibst A5c chip task_01d0) | $(_ibst M1 chip task_01d0)" "chip-unstarted | no row"
is  "inventory A119: cover chips says the --days window it used" \
    "$(_ibst M1 cover chips) | $(_ibcol M1 cover chips 8) | $(_ibcol A5b cover chips 8)" "read | proposed in sessions active in the last 14 days | proposed in sessions active in the last 3 days"
is  "inventory A40: a branch named like the default branch heads no PR: local main, checked out nowhere, is landed and nothing else" "$(_ibst M1 branch main)" "landed"
is  "inventory N12: and an open PR headed main is always a pr row" "$(_ibst M1 pr '#14')" "pr-open"
_ibrun A6 -- inventory --repo "$IB/plain" --repo "$IB/m" --repo "$IB/nope" --tsv --no-gh --no-host
is  "inventory A6: a path that is not a git repository exits 1, is named on stderr, and the others still print" \
    "$(_ibrc A6) $(case "$(cat "$IB/runs/A6.err")" in (*"$IB/plain"*) echo plain ;; (*) echo 'no plain' ;; esac) $(case "$(cat "$IB/runs/A6.err")" in (*"$IB/nope"*) echo nope ;; (*) echo 'no nope' ;; esac) $(_ibcount A6 cover "$IBMR") $(LC_ALL=C awk -F'\t' -v a="$IB/plain" -v b="$IB/nope" '$2 == a || $2 == b { n++ } END { print n + 0 }' "$(_ibo A6)")" \
    "1 plain nope 5 0"
_ibrun A7 -- inventory --repo "$IB/r2" --repo "$IB/m" --tsv --no-gh --no-host
is  "inventory A7: repositories print in --repo order, the second's rows after all of the first's" \
    "$(LC_ALL=C awk -F'\t' 'NR == 1 { print $2 }' "$(_ibo A7)") $(LC_ALL=C awk -F'\t' -v a="$IBR2" -v b="$IBMR" '$2 == b { s = 1 } $2 == a && s { x = 1 } END { print (s && !x) ? "in-order" : "out-of-order" }' "$(_ibo A7)")" "$IBR2 in-order"
_ibrun A8a --cwd "$IB/m/sub" -- inventory --tsv --no-gh --no-host
_ibrun A8b -- inventory --repo "$IB/mw/five" --tsv --no-gh --no-host
_ibrepos() { LC_ALL=C awk -F'\t' '{ r[$2] = 1 } END { for (k in r) printf "%s;", k; if (!NR) printf "no rows" }' "$(_ibo "$1")"; }
is  "inventory A8: with no --repo it reads the repository holding the working directory, and --repo on a linked worktree reads its repository, repo the main worktree's path" \
    "$(_ibrc A8a) $(_ibrepos A8a) $(_ibrc A8b) $(_ibrepos A8b)" "0 $IBMR; 0 $IBMR;"
_ibrun A9 --env "GIT_DIR=$IB/other/.git" --env "GIT_WORK_TREE=$IB/other" --env "GIT_INDEX_FILE=$IB/other/.git/index" -- inventory --repo "$IB/m" --tsv --no-gh --no-host
is  "inventory A9: GIT_DIR, GIT_WORK_TREE and GIT_INDEX_FILE in the environment do not redirect the read" "$(_ibrc A9) $(_ibrepos A9)" "0 $IBMR;"
_ibrun A31a -- inventory --repo "$IB/m" --tsv --no-host
_ibrun A31b --home "$IB/homenone" -- inventory --repo "$IB/m" --tsv
_ibwthost() { LC_ALL=C awk -F'\t' '$1 == "worktree" { n++; s = "," $4 ","; if ($5 != "unknown" || !index(s, ",unknown:live,") || !index(s, ",unknown:question,") || !index(s, ",unknown:blocked,")) printf "%s [%s %s]; ", $3, $5, $4 }
  END { if (!n) printf "no worktree rows" }' "$(_ibo "$1")"; }
for _ibk in a b; do
  case "$_ibk" in a) _ibl='--no-host' ;; b) _ibl='no session records' ;; esac
  is  "inventory A31: with $_ibl, sessions and chips are unknown and say why once" \
      "$(_ibst "A31$_ibk" cover sessions) | $(_ibcol "A31$_ibk" cover sessions 8) | $(_ibst "A31$_ibk" cover chips) | $(_ibcol "A31$_ibk" cover chips 8)" \
      "unknown,unknown:live,unknown:question,unknown:blocked | $_ibl | unknown,unknown:chip-unstarted | $_ibl"
  is  "inventory A31: and with $_ibl every worktree row's owner is unknown and it carries unknown:live, unknown:question and unknown:blocked" "$(_ibwthost "A31$_ibk")" ""
done
IB_BR=""; _ibopen "$IB/ccd/projects/$(_ibenc "$IB/mw/five")/s-ccd.jsonl" s-ccd; _ib_h 6 'go'; _ib_a 5 'Done.'; _ibage "$IB_F" 5
_ibrun CCD --env "CLAUDE_CONFIG_DIR=$IB/ccd" -- inventory --repo "$IB/m" --tsv --no-gh
is  "inventory N13: with CLAUDE_CONFIG_DIR set, records are read under it and cover sessions names it literally" \
    "$(_ibcol CCD worktree "$IB/mw/five" 5) | $(_ibcol CCD cover sessions 8)" "s-ccd | Claude Code session records under \$CLAUDE_CONFIG_DIR/projects"
# gh: missing, failing with a long first line, failing on the second call only.
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
is  "inventory A27: the fixture: a PATH with git and without gh" \
    "$(PATH="$IB/stubng:$IB/nogh" command -v gh >/dev/null 2>&1 && echo gh || echo nogh) $(PATH="$IB/stubng:$IB/nogh" command -v git >/dev/null 2>&1 && echo git || echo nogit)" "nogh git"
_ibrun A27 --path "$IB/stubng:$IB/nogh" -- inventory --repo "$IB/m" --tsv --no-host
is  "inventory A27: gh missing from PATH is unknown, gh not found, and the run still exits 0" \
    "$(_ibrc A27) | $(_ibst A27 cover prs) | $(_ibcol A27 cover prs 8)" "0 | unknown,unknown:pr-open,unknown:unproposed,unknown:pr-closed-unlanded | gh not found"
_ib118="$(_ibp 'gh could not reach the host because the token has expired and must be renewed before' 118)"
printf '1\n' > "$IB/gh/rc"; printf '%s\303\251\303\274 and more\nsecond\n' "$_ib118" > "$IB/gh/err"
_ibrun A28a -- inventory --repo "$IB/m" --tsv --no-host
printf '%sx\303\251 and more\nsecond\n' "$_ib118" > "$IB/gh/err"
_ibrun A28b -- inventory --repo "$IB/m" --tsv --no-host
printf '0\n' > "$IB/gh/rc"; : > "$IB/gh/err"
_ibreason() { _ibcol "$1" cover prs 8 | LC_ALL=C awk '{ sub(/^gh failed: /, ""); print length($0) }'; }
is  "inventory A28: a failing gh is unknown with its first stderr line cut to 120 bytes on a whole character" \
    "$(_ibst A28a cover prs) | $([ "$(_ibcol A28a cover prs 8)" = "gh failed: $_ib118$(printf '\303\251')" ] && echo exact || _ibcol A28a cover prs 8) | $(_ibreason A28a)" \
    "unknown,unknown:pr-open,unknown:unproposed,unknown:pr-closed-unlanded | exact | 120"
is  "inventory A28: and a two-byte character across byte 120 is left out whole, 119 bytes" \
    "$([ "$(_ibcol A28b cover prs 8)" = "gh failed: ${_ib118}x" ] && echo exact || _ibcol A28b cover prs 8) | $(_ibreason A28b)" "exact | 119"
: > "$IB/gh/fail-open"
_ibrun A29 -- inventory --repo "$IB/m" --tsv --no-host
rm -f "$IB/gh/fail-open"
is  "inventory A29: when only the second gh call fails, PR facts are unknown and no row is pr-open" \
    "$(_ibst A29 cover prs | LC_ALL=C awk -F, '{ print $1 }') $(LC_ALL=C awk -F'\t' 'index("," $4 ",", ",pr-open,") { n++ } END { print n + 0 }' "$(_ibo A29)")" "unknown 0"
if command -v perl >/dev/null 2>&1; then
  for _ibn in TERM HUP INT; do
    is  "inventory A14: the scratch directory is removed when the run is sent $_ibn" "$(_ibsig "$_ibn")" "gone"
  done
else
  skip "inventory A14: the scratch directory is removed when the run is sent TERM, HUP or INT" "no perl to start the run with INT at its default"
fi

# ---- small repositories: no origin, unborn, fallbacks, bare, shallow, partial
_ibrun MISC -- inventory --repo "$IB/noorigin" --repo "$IB/unborn" --repo "$IB/fb1" --repo "$IB/fb2" --repo "$IB/bwt" --tsv --no-host
IBNO="$(_ibmainwt "$IB/noorigin")"; IBBW="$(_ibmainwt "$IB/bwt")"
is  "inventory A23: a clone with no origin has an unknown default, said once, with the unknowns it causes" \
    "$(_ibrc MISC) | $(_ibst MISC cover default "$IBNO") | $(_ibcol MISC cover default 8 "$IBNO")" \
    "0 | unknown,unknown:uncommitted,unknown:unpushed,unknown:unproposed,unknown:pr-closed-unlanded | no origin/HEAD, origin/main or origin/master whose tree this clone holds"
is  "inventory A23: and its main worktree and its branch have content unknown, are never landed, and carry unknown entries" \
    "$(_ibcol MISC worktree "$IBNO" 7) $(_ibcol MISC branch side 7) $(_ibholds MISC worktree "$IBNO" landed) $(_ibholds MISC branch side landed) $(case "$(_ibst MISC worktree "$IBNO"),$(_ibst MISC branch side)" in (*unknown:*,*unknown:*) echo unknowns ;; (*) echo 'no unknowns' ;; esac)" \
    "unknown unknown no no unknowns"
is  "inventory A24: origin/main stands in when origin/HEAD is gone, and origin/master after it, which has no fetch time" \
    "$(_ibst MISC cover default "$(_ibmainwt "$IB/fb1")") $(_ibcol MISC cover default 8 "$(_ibmainwt "$IB/fb1")" | LC_ALL=C awk '{ print $1 " " $2 }') | $(_ibcol MISC cover default 8 "$(_ibmainwt "$IB/fb2")")" \
    "read origin/main @ | origin/master @ $(_ib8 "$IB/fb2" origin/master); fetch time unknown"
is  "inventory A45: a bare main has no worktree row, and its linked worktree has one" \
    "$(LC_ALL=C awk -F'\t' -v p="$IBBW" '$2 == p && $1 == "worktree" { printf "%s;", $3 }' "$(_ibo MISC)")" "$IB/bwt;"
is  "inventory A46: an unborn repository is read, not refused: five cover rows, default unknown" \
    "$(_ibcount MISC cover "$IB/unborn") $(_ibst MISC cover default "$IB/unborn" | LC_ALL=C awk -F, '{ print $1 }')" "5 unknown"
is  "inventory A64: nor in the run over the repository with no origin" "$(_ibland "$(_ibo MISC)" "$(_ibo RUN1)")" ""
IB_PSNAP="$(_ibsnap "$IB/partial/.git/objects")"
_ibrun PART -- inventory --repo "$IB/partial" --repo "$IB/shallow" --tsv --no-host
is  "inventory A33: a partial clone's cover objects is partial and says nothing was fetched, and the run fetched nothing into it" \
    "$(_ibst PART cover objects "$IB/partial") | $(_ibcol PART cover objects 8 "$IB/partial") | $([ "$IB_PSNAP" = "$(_ibsnap "$IB/partial/.git/objects")" ] && echo unchanged || echo changed)" \
    "partial | a partial clone: nothing was fetched, so content in no object here may be the remote's | unchanged"
is  "inventory N14: a shallow clone's cover objects is partial and says history past the graft is absent" \
    "$(_ibst PART cover objects "$IB/shallow") | $(_ibcol PART cover objects 8 "$IB/shallow")" \
    "partial | a shallow clone: history past the graft is absent, so a merge-base may be missing or wrong"
_ibrun PARTOLD --path "$IB/old:$IB/stub:$PATH" -- inventory --repo "$IB/partial" --repo "$IB/m" --tsv --no-host
is  "inventory A34: under git older than 2.44 a partial clone is refused, named, and left as it was, and the other repository still prints" \
    "$(_ibrc PARTOLD) $(case "$(cat "$IB/runs/PARTOLD.err")" in (*"$IB/partial"*) echo named ;; (*) echo unnamed ;; esac) $(_ibcount PARTOLD cover "$IB/partial") $(_ibcount PARTOLD cover "$IBMR") $([ "$IB_PSNAP" = "$(_ibsnap "$IB/partial/.git/objects")" ] && echo unchanged || echo changed)" \
    "1 named 0 5 unchanged"
_ibrun K -- inventory --repo "$IB/k" --tsv --no-host
is  "inventory A26: a gh listing of 1000 PRs is partial, unknown:unproposed, and says older PRs are not seen" \
    "$(_ibst K cover prs) $(case "$(_ibcol K cover prs 8)" in (*older*) echo older ;; (*) echo 'no older' ;; esac)" "partial,unknown:unproposed older"
is  "inventory A26, N10: a pushed branch no listed PR heads is unproposed-unknown, not unproposed, and its content is unknown" \
    "$(_ibmany K branch feat unknown:unproposed unproposed) $(_ibcol K branch feat 7)" "unknown:unproposed=yes unproposed=no unknown"
is  "inventory RV8: a pushed branch whose PR the partial list does hold keeps its content, so rule 5 does not apply: pr-open, no unknown:unproposed, content not" \
    "$(_ibmany K branch feat2 pr-open unknown:unproposed) $(_ibcol K branch feat2 7)" "pr-open=yes unknown:unproposed=no not"
IB_BR=""; _ibsess "$IB/r3" s-r3; _ib_h 3 'link it'
printf -v _ibx '{"type":"pr-link","prNumber":12,"prRepository":"whoever/whatever","sessionId":"s-r3","timestamp":"%s"}' "$(_ibts 2)"
_ib_raw "$_ibx"; _ib_a 2 'Linked.'; _ibage "$IB_F" 2
rm -f "$IB/gh.log"; _ibrun R3 -- inventory --repo "$IB/r3" --tsv
is  "inventory A103: with a local-path origin gh runs in the repository with no -R, and cover prs names the bare command" \
    "$(LC_ALL=C awk -F'|' '{ printf "%s %s;", $1, (index($2, "-R") ? "-R" : "no-R") }' "$IB/gh.log" 2>/dev/null) | $(_ibcol R3 cover prs 8)" "$IB/r3 no-R;$IB/r3 no-R; | gh pr list: 1 PRs"
is  "inventory A103: and with no derived owner/repo no pr-link names a session, and no record makes an owner" \
    "$(_ibcol R3 pr '#12' 5) $(case "$(_ibcol R3 pr '#12' 8)" in (*'last linked in session'*) echo linked ;; ('no row') echo 'no row' ;; (*) echo unlinked ;; esac)" "- unlinked"
rm -f "$IB/gh.log"; _ibrun U -- inventory --repo "$IB/u1" --repo "$IB/u2" --repo "$IB/u3" --repo "$IB/u4" --tsv --no-host
is  "inventory A104, N15: owner/repo comes from each URL form, a non-github host keeps its host, and a port is no part of the host" \
    "$(LC_ALL=C awk -F'|' '/--state all/ { n = split($2, w, " "); for (i = 1; i < n; i++) if (w[i] == "-R") printf "%s;", w[i + 1] }' "$IB/gh.log" 2>/dev/null)" \
    "acme/widget;acme/widget;ghe.example/acme/widget;acme/widget;"

# ---- d, f, g: read-only against a stale index, a filter and gpg -----------
IB_DSNAP="$(_ibsnap "$IB/d"; _ibsnap "$IB/d-origin.git"; _ibsnap "$IB/dw")"; : > "$IB/d.mark"
_ibrun D1 -- inventory --repo "$IB/d" --tsv; _ibrun D2 -- inventory --repo "$IB/d"
is  "inventory A10: an inventory leaves every repository byte-identical, its index and directories untouched, though a plain git status would rewrite the index" \
    "$(_ibrc D1) $(_ibrc D2) $([ "$IB_DSNAP" = "$(_ibsnap "$IB/d"; _ibsnap "$IB/d-origin.git"; _ibsnap "$IB/dw")" ] && echo same || echo changed) [$(find "$IB/d" "$IB/d-origin.git" "$IB/dw" -newer "$IB/d.mark" -print | LC_ALL=C awk 'NR <= 3' | tr '\n' ' ')] [$(find "$IB/d/.git" -name '*.lock' -print | tr '\n' ' ')]" \
    "0 0 same [] []"
rm -f "$IB/ran-clean"
_ibrun F -- inventory --repo "$IB/f" --tsv --no-host
IBFR="$(_ibmainwt "$IB/f")"
is  "inventory A12: a filter's clean command never runs, and a filtered path that differs is uncommitted-unknown, content unknown, never landed" \
    "$([ -e "$IB/ran-clean" ] && echo ran || echo 'never ran') $(_ibmany F worktree "$IBFR" unknown:uncommitted landed) $(_ibcol F worktree "$IBFR" 7)" "never ran unknown:uncommitted=yes landed=no unknown"
rm -f "$IB/gpg-ran"; _ibg -C "$IB/g" log -1 >/dev/null 2>&1
is  "inventory N8: the fixture: a plain git log in g runs its gpg" "$([ -e "$IB/gpg-ran" ] && echo ran || echo 'did not run')" "ran"
rm -f "$IB/gpg-ran"
_ibrun G -- inventory --repo "$IB/g" --tsv --no-host
is  "inventory N8: an inventory of a repository that shows signatures runs no gpg" "$(_ibrc G) $([ -e "$IB/gpg-ran" ] && echo ran || echo 'never ran')" "0 never ran"

# ---- h: the host adapter -------------------------------------------------
_ibh_records; IB_H0="$(date +%s)"
_ibrun H1 -- inventory --repo "$IB/h" --tsv
IB_HD=$(( ($(date +%s) - IB_H0 + 59) / 60 ))
_ibh_two; _ibrun H2 -- inventory --repo "$IB/h" --tsv --live 80
_ibrun H3 -- inventory --repo "$IB/h" --tsv --live 30
_ibw() { printf '%s' "$IB/hw/$1"; }
is  "inventory A76: the test's encoder turns every character outside [A-Za-z0-9] into a dash, as /a/.b_c to -a--b-c" "$(_ibenc /a/.b_c)" "-a--b-c"
is  "inventory A76: records filed under that name make the worktree's owner" "$(_ibcol H1 worktree "$(_ibw w.t_1)" 5)" "s-enc"
is  "inventory A77: a character beyond the BMP is two dashes in the record directory's name" "$(_ibcol H1 worktree "$IB_EMO" 5)" "s-emo"
is  "inventory A78: records filed under the resolved spelling of a symlinked path are found" "$(_ibcol H1 worktree "${IB_SYM:-$IB/hl/sym}" 5)" "s-sym"
is  "inventory A79: a long name resolves to its single hashed record directory" "$(_ibcol H1 worktree "$IB_LONG1" 5)" "s-long1"
is  "inventory A79: and two candidates make the owner and the host states unknown" \
    "$(_ibcol H1 worktree "$IB_LONG2" 5) $(_ibmany H1 worktree "$IB_LONG2" unknown:live unknown:question unknown:blocked)" "unknown unknown:live=yes unknown:question=yes unknown:blocked=yes"
is  "inventory A80: activity counts every file under the session's directory, so a tool result written 2 minutes ago makes it live, 0 hours old" \
    "$(_ibholds H1 worktree "$(_ibw act)" live) $(_ibcol H1 worktree "$(_ibw act)" 6)" "yes 0"
is  "inventory A81: the owner is the newest session, and live follows its activity" \
    "$(_ibcol H1 worktree "$(_ibw two)" 5) $(_ibholds H1 worktree "$(_ibw two)" live) $(_ibcol H2 worktree "$(_ibw two)" 5) $(_ibholds H2 worktree "$(_ibw two)" live)" "s-new no s-new yes"
is  "inventory A82: a tool call pending past --blocked with nothing newer under the session is blocked, and says how long it has waited" \
    "$(_ibholds H1 worktree "$(_ibw blk)" blocked) $(_ibcol H1 worktree "$(_ibw blk)" 8 | LC_ALL=C awk -v hi=$((35 + IB_HD)) '{ s = $0; while (match(s, /[0-9]+/)) { v = substr(s, RSTART, RLENGTH) + 0; if (v >= 35 && v <= hi) f = 1; s = substr(s, RSTART + RLENGTH) } } END { print (f ? "waited" : "no wait") }')" "yes waited"
is  "inventory A83: a file under the session's directory newer than --blocked means the call is still working, not blocked" "$(_ibholds H1 worktree "$(_ibw blk2)" blocked)" "no"
is  "inventory A84: a final text that asks, with nothing human after it, is a question quoting its ending" \
    "$(_ibholds H1 worktree "$(_ibw ask)" question) | $(_ibelem H1 worktree "$(_ibw ask)" 'ended on: ')" "yes | ended on: I've pushed the branch.  Shall I merge it?"
is  "inventory A85: human text after the ask clears it; a tool result, a reminder-led message or a meta record does not" \
    "$(_ibholds H1 worktree "$(_ibw ans-a)" question) $(_ibholds H1 worktree "$(_ibw ans-b)" question) $(_ibholds H1 worktree "$(_ibw ans-c)" question)" "no yes yes"
is  "inventory A86: fenced code, code spans, double quotes and blockquotes are set aside before asking" \
    "$(_ibholds H1 worktree "$(_ibw sa-fence)" question) $(_ibholds H1 worktree "$(_ibw sa-span)" question) $(_ibholds H1 worktree "$(_ibw sa-quote)" question) $(_ibholds H1 worktree "$(_ibw sa-bq)" question)" "no no no no"
is  "inventory A87: an ask phrase counts as whole words only, and not after a negation in its own clause" \
    "$(_ibholds H1 worktree "$(_ibw ng-a)" question) $(_ibholds H1 worktree "$(_ibw ng-b)" question) $(_ibholds H1 worktree "$(_ibw ng-c)" question) $(_ibholds H1 worktree "$(_ibw ng-d)" question)" "no no yes yes"
is  "inventory A88: a ? followed only by closing marks asks, and one four paragraphs back does not" \
    "$(_ibholds H1 worktree "$(_ibw q-a)" question) $(_ibholds H1 worktree "$(_ibw q-b)" question)" "yes no"
for _ibn in bad-empty bad-cut bad-nojson; do
  is  "inventory A89: a session file that is $_ibn answers unknown:question, never landed" "$(_ibmany H1 worktree "$(_ibw "$_ibn")" unknown:question landed)" "unknown:question=yes landed=no"
done
is  "inventory A90: a sidechain record and a record of another type after the final text are passed over" "$(_ibmany H1 worktree "$(_ibw side)" question unknown:question)" "question=no unknown:question=no"
is  "inventory A91: a final text past the last 256 KiB makes question unknown, and a small file with no text makes it not held" \
    "$(_ibholds H1 worktree "$(_ibw big-a)" unknown:question) $(_ibmany H1 worktree "$(_ibw big-b)" question unknown:question)" "yes question=no unknown:question=no"
is  "inventory A92: a subagent worktree names its spawning session and the agent's description, and the agent's file makes it live" \
    "$(_ibhaselem H1 worktree "$IB/h/.claude/worktrees/agent-a1b2c3" 'spawned by session s-boss: write the parser') $(_ibholds H1 worktree "$IB/h/.claude/worktrees/agent-a1b2c3" live)" "yes yes"
is  "inventory A93: a meta file for another path adds nothing, and the search leaves no unknown" \
    "$(_ibst H1 worktree "$IB/h/.claude/worktrees/agent-a9b9c9") $(case "$(_ibcol H1 worktree "$IB/h/.claude/worktrees/agent-a9b9c9" 8)" in (*'spawned by'*) echo spawned ;; (*) echo plain ;; esac)" "landed plain"
is  "inventory A94: a helper transcript's question and pending call make its parent neither a question nor blocked" "$(_ibmany H1 worktree "$(_ibw par)" question blocked live)" "question=no blocked=no live=yes"
is  "inventory A62: held states print in the fixed order with no spaces, live first" "$(_ibst H1 worktree "$(_ibw ord)")" "live,uncommitted,unpushed"
is  "inventory A63: landed comes after live, the one state that may sit beside it" "$(_ibst H1 worktree "$(_ibw ll)")" "live,landed"
is  "inventory N2: a session whose last record is 3 hours old is not live though a bookkeeping line touched its file a minute ago" \
    "$(_ibcol H1 worktree "$(_ibw cost)" 5) $(_ibst H1 worktree "$(_ibw cost)")" "s-cost landed"
is  "inventory N3: with no record time in the window, the file's time stands in, and the detail says so" \
    "$(_ibholds H1 worktree "$(_ibw notime)" live) $(_ibhaselem H1 worktree "$(_ibw notime)" 'activity from file time')" "yes yes"
is  "inventory N4: an assistant record that puts its message first is read by the role inside it, and a record of another type nesting a message is passed over" \
    "$(_ibholds H1 worktree "$(_ibw mf-a)" question) $(_ibmany H1 worktree "$(_ibw mf-b)" question unknown:question)" "yes question=no unknown:question=no"
is  "inventory RV1: a call pending 35 minutes is blocked from its own record, and a bookkeeping line that touched the file a minute ago neither clears it nor, under --live 30, makes the session live" \
    "$(_ibholds H1 worktree "$(_ibw blk-cost)" blocked) $(_ibholds H3 worktree "$(_ibw blk-cost)" blocked) $(_ibholds H3 worktree "$(_ibw blk-cost)" live)" "yes yes no"
is  "inventory RV1: and its detail gives the minutes waited measured from the pending record, 34 to 35 plus the run's own minutes, not from the file's time a minute ago" \
    "$(_ibcol H1 worktree "$(_ibw blk-cost)" 8 | LC_ALL=C awk -v hi=$((35 + IB_HD)) '{ n = split($0, w, /[^0-9A-Za-z]+/); for (i = 1; i <= n; i++) if (w[i] ~ /^[0-9]+$/ && w[i] + 0 >= 34 && w[i] + 0 <= hi) f = 1 } END { print (f ? "waited" : "no wait") }')" "waited"
is  "inventory RV2: the person's own text after a pending call answers it, so the session is not blocked" "$(_ibholds H1 worktree "$(_ibw blk-human)" blocked)" "no"
is  "inventory RV2: and a user record that is no human text (isMeta) after it is a record that follows it, so that session is not blocked either" "$(_ibholds H1 worktree "$(_ibw blk-meta)" blocked)" "no"
is  "inventory RV3: the newest session is the latest by record time, though its file is the older of the two" "$(_ibcol H1 worktree "$(_ibw two2)" 5)" "s-rt-new"
is  "inventory RV4: a last line cut before its end holds no record, so the asking text in it makes no question, and the whole lines before it say it is not unknown" \
    "$(_ibmany H1 worktree "$(_ibw mf-cut)" question unknown:question)" "question=no unknown:question=no"

# ---- o: orphans ----------------------------------------------------------
_ibrun O1 -- inventory --repo "$IB/o" --tsv --no-host
_ibo1() { _ibcol O1 orphan "$IB/ow/$1" "$2"; }
is  "inventory A67: a worktree git forgot, beside one it lists, is an orphan counting its unique file, content not, and no worktree row" \
    "$(_ibholds O1 orphan "$IB/ow/lost" orphan) | $(_ibo1 lost 8 | LC_ALL=C awk '{ print (/^1 of [0-9]+ files hold content in no object of the repository/ ? "counted" : $0) }') | $(_ibo1 lost 7) | $(_ibst O1 worktree "$IB/ow/lost")" \
    "yes | counted | not | no row"
is  "inventory A69: an untracked checkout inside the main worktree makes its parent a search parent, and a plain sibling holding nothing tracked is an orphan" \
    "$(_ibcol O1 orphan "$IB/o/.wt/dead" 1) $(_ibcol O1 orphan "$IB/o/.wt/plain" 1)" "orphan orphan"
is  "inventory A70: a nested repository, a directory naming another live repository's worktree, and a tracked directory are never orphans" \
    "$(_ibcol O1 orphan "$IB/o/.wt/dead" 1) $(LC_ALL=C awk -F'\t' '$1 == "orphan" && ($3 ~ /\/nested$/ || $3 ~ /\/foreign$/ || $3 ~ /\/tracked$/) { printf "%s;", $3 }' "$(_ibo O1)")" "orphan "
is  "inventory A71: the main worktree's parent is never a search parent" \
    "$(_ibcol O1 orphan "$IB/ow/lost" 1) $(LC_ALL=C awk -F'\t' -v p="$IB/" '$1 == "orphan" { r = substr($3, length(p) + 1); if (substr($3, 1, length(p)) == p && index(r, "/") == 0) printf "%s;", $3 }' "$(_ibo O1)")" "orphan "
is  "inventory A72: ignored files over 1 MiB are said, not skipped, and the orphan that passed one over is not landed" \
    "$(case "$(_ibo1 lostbig 8)" in (*'; 1 ignored files over 1 MiB not read'*) echo said ;; (*) _ibo1 lostbig 8 ;; esac) $(_ibo1 lostbig 7)" "said unknown"
# Spec section 4.6, "the first count covers the first 20000 files that are not
# ignored": n is the 20000 read, and k counts among them. Which 20000 is not
# fixed, and the 3 tracked files may or may not be among them, so k is 19997-20000.
is  "inventory RV12: an orphan holding 20001 files reads the first 20000, counts what it found among those 20000, says the rest were not read, and is not landed" \
    "$(_ibo1 lostmany 8 | LC_ALL=C awk '{ split($0, e, "; "); if (e[1] ~ /^[0-9]+ of 20000 files hold content in no object of the repository$/) { k = e[1] + 0; print (k >= 19997 && k <= 20000 ? "counted" : "k is " k) } else print "first element: " e[1] }') $(case "$(_ibo1 lostmany 8)" in (*'; files past the first 20000 not read'*) echo said ;; (*) echo unsaid ;; esac) $(_ibo1 lostmany 7)" "counted said not"
is  "inventory A73: an ignored unique file under the cap is counted in the ignored clause" \
    "$(case "$(_ibo1 lostsmall 8)" in (*'; 1 of 1 ignored files hold content in no object'*) echo counted ;; (*) _ibo1 lostsmall 8 ;; esac) $(_ibo1 lostsmall 7)" "counted not"

# ---- v: the human view ---------------------------------------------------
IB_BR=""; _ibsess "$IB/vw/blk" s-vblk; _ib_h 40 'watch it'
_ib_tu 35 toolu_v1 Bash '{"command":"watch-the-ledger","description":"Watch the ledger"}'; _ibage "$IB_F" 35
_ibrun V1 -- inventory --repo "$IB/v" --tsv; _ibrun V2 -- inventory --repo "$IB/v"
IB_V="$(_ibo V2)"
# A heading is a group's label and its count alone on a line; _ibhead prints
# "line count" for a label, _ibgroup the heading above the first line holding
# a text.
_ibhead() { LC_ALL=C awk -v l="$2" '{ s = $0; sub(/^[ \t]+/, "", s)
    if (substr(s, 1, length(l)) == l) { r = substr(s, length(l) + 1); if (r ~ /^[ \t:(]*[0-9]+[)]?[ \t]*$/) { gsub(/[^0-9]/, "", r); print NR " " r; exit } } }' "$1"; }
_ibgroup() { LC_ALL=C awk -v t="$2" -v labs="$IB_LABELS" 'BEGIN { n = split(labs, L, "|") }
    { s = $0; sub(/^[ \t]+/, "", s); h = 0
      for (i = 1; i <= n; i++) if (substr(s, 1, length(L[i])) == L[i]) { r = substr(s, length(L[i]) + 1); if (r ~ /^[ \t:(]*[0-9]+[)]?[ \t]*$/) { g = L[i]; h = 1 } }
      if (!h && index($0, t)) { print (g == "" ? "no group" : g); exit } }' "$1"; }
_ibnb() { LC_ALL=C awk 'NF { print }' "$1"; }
is  "inventory A105: the view opens with the fixed read-only sentence" "$(LC_ALL=C awk 'NR == 1' "$IB_V")" \
    "felix inventory: read-only. It wrote nothing into a repository and fetched nothing; gh, if asked, only listed pull requests."
_ibx=""; _ibn=2
for _ibk in default prs sessions chips objects; do
  _ibn=$((_ibn + 1)); _ibd="$(_ibcol V1 cover "$_ibk" 8 "$IBVR")"
  case "$(_ibnb "$IB_V" | LC_ALL=C awk -v n="$_ibn" 'NR == n')" in *"$_ibd"*) ;; *) _ibx="$_ibx $_ibk" ;; esac
done
is  "inventory A106: after the sentence, the view names the repository, then one line per cover facet with its detail, in order" \
    "$(_ibnb "$IB_V" | LC_ALL=C awk 'NR == 2' | LC_ALL=C awk -v p="$IBVR" '{ print (index($0, p) ? "path" : $0) }')|$_ibx" "path|"
is  "inventory A106: groups for blocked, uncommitted and unpushed come in the fixed order, each headed with its count, and there is no live group" \
    "$(_ibhead "$IB_V" blocked | cut -d' ' -f2) $(_ibhead "$IB_V" uncommitted | cut -d' ' -f2) $(_ibhead "$IB_V" unpushed | cut -d' ' -f2) $(_ibx1="$(_ibhead "$IB_V" blocked | cut -d' ' -f1)"; _ibx2="$(_ibhead "$IB_V" uncommitted | cut -d' ' -f1)"; _ibx3="$(_ibhead "$IB_V" unpushed | cut -d' ' -f1)"; [ -n "$_ibx1" ] && [ -n "$_ibx2" ] && [ -n "$_ibx3" ] && [ "$_ibx1" -lt "$_ibx2" ] && [ "$_ibx2" -lt "$_ibx3" ] && echo ordered || echo unordered) [$(_ibhead "$IB_V" live)]" \
    "1 1 1 ordered []"
_ibx="$(_ibnb "$IB_V" | LC_ALL=C awk 'END { print }')"
is  "inventory A106, A68: the view ends with the counts line, one orphan holding nothing unique, at least one landed" \
    "$(printf '%s\n' "$_ibx" | LC_ALL=C awk '/^[ \t]*live [0-9]+ \([0-9]+ blocked on a tool call\), landed [0-9]+, orphans holding nothing unique 1, nothing decided but unknown [0-9]+$/ { split($0, w, "landed "); print (w[2] + 0 >= 1 ? "counts" : "landed 0"); next } { print }')" "counts"
is  "inventory A106, A68: a landed branch and an orphan holding nothing unique are counted and not listed" \
    "$(LC_ALL=C awk '/(^|[^a-z])vland([^a-z]|$)/ { f = 1 } END { print (f ? "listed" : "unlisted") }' "$IB_V") $(case "$(cat "$IB_V")" in (*"$IB/vw/lostv"*) echo listed ;; (*) echo unlisted ;; esac)" "unlisted unlisted"
is  "inventory A68: that orphan's row counts none of its files, and its content is landed" \
    "$(_ibcol V1 orphan "$IB/vw/lostv" 8 | LC_ALL=C awk '{ print (/^0 of / ? "none" : $0) }') $(_ibcol V1 orphan "$IB/vw/lostv" 7)" "none landed"
# Step 6 (contract A1): such a branch used to hold no state and sat under
# "undecided, content not landed"; another pushed branch holding its commit now
# makes it carried, and the view lists it under that heading.
is  "inventory N7: a branch whose commit sits on another remote branch only is carried, its content not, so it is not landed" \
    "$(_ibst V1 branch other-ref) $(_ibcol V1 branch other-ref 7)" "carried not"
is  "inventory N7: and the view lists it under carried" "$(_ibgroup "$IB_V" other-ref)" "carried"
_ibrun NV -- inventory --repo "$IB/noorigin" --no-host
is  "inventory A107: an undecided row with content unknown is counted, not listed" \
    "$(LC_ALL=C awk '/(^|[^a-z])side([^a-z]|$)/ { f = 1 } END { print (f ? "listed" : "unlisted") }' "$(_ibo NV)") $(_ibnb "$(_ibo NV)" | LC_ALL=C awk 'END { sub(/.*nothing decided but unknown /, ""); print ($0 + 0 >= 1 ? "counted" : "uncounted") }')" "unlisted counted"

# ---- t: temporary roots --------------------------------------------------
_ibrun T1 -- inventory --repo "$IB/t" --tsv --no-host
_ibrun T2 -- inventory --repo "$IB/t" --no-host
_ibrun T3 --env "FELIX_INVENTORY_TEMP_ROOTS=$IB/tlink" -- inventory --repo "$IB/t" --tsv --no-host
is  "inventory A74: a worktree under a temporary root carries the element temp, its twin outside does not, and their states are the same" \
    "$(_ibhaselem T1 worktree "$IB/temproot/w" temp) $(_ibhaselem T1 worktree "$IB/wtst/w" temp) $([ "$(_ibst T1 worktree "$IB/temproot/w")" = "$(_ibst T1 worktree "$IB/wtst/w")" ] && echo same || echo differ)" "yes no same"
is  "inventory A75: a root given through a symlink matches the path it resolves to, whole components only, and the seam's roots are the only ones" \
    "$(_ibhaselem T3 worktree "$IB/temproot/w" temp) $(_ibhaselem T3 worktree "$IB/temprootx/w" temp) $(LC_ALL=C awk -F'\t' -v k="$IB/temproot/w" '$3 != k { n = split($8, e, "; "); for (i = 1; i <= n; i++) if (e[i] == "temp") printf "%s;", $3 }' "$(_ibo T3)")" "yes no "
is  "inventory A108: a temp row is listed once, under in temporary directories, and the uncommitted group's count leaves it out" \
    "$(LC_ALL=C awk -v p="$IB/temproot/w" 'index($0, p) { n++ } END { print n + 0 }' "$(_ibo T2)") $(_ibgroup "$(_ibo T2)" "$IB/temproot/w") $(_ibhead "$(_ibo T2)" uncommitted | cut -d' ' -f2)" "1 in temporary directories 1"

# ---- the review's blockers B1-B5 (build/review-final.md, fixtures f8 f7 f2 f4 f9)
# One repository per blocker, under $IB like the rest of this section. No block
# reads or writes a project table, so none is set aside or restored. B5 and the
# PR base it reads follow the ruling of 2026-10-02 (spec section 4.3 rule 2 and
# section 7: a merged PR lands its head only when its base is the default
# branch); B4 follows its R2 (section 4.4) and B2, B3 its R3 (section 5.2).
_ibnothing() { _ibnb "$1" | LC_ALL=C awk 'END { if (match($0, /orphans holding nothing unique [0-9]+/)) { s = substr($0, RSTART, RLENGTH); sub(/.* /, "", s); print s } else print "no counts line" }'; }

# B1 (f8): Claude Code keeps a project's auto-memory in <E>/memory/, beside the
# session files and written from any worktree. Section 6.3 counts only files
# under a session's own <session-id>/ directory, so a memory note written a
# minute ago leaves a worktree whose one session last worked 3 hours ago not live.
_ibnew b1
IBB1R="$(_ibmainwt "$IB/b1")"
printf 'b1\nedited, never committed\n' > "$IB/b1/README.md"
IB_BR=""; _ibsess "$IBB1R" s-b1old; _ib_h 181 'edit the readme'; _ib_a 180 'Done.'; _ibage "$IB_F" 180
_ibx="$IBP/$(_ibenc "$IBB1R")/memory"; mkdir -p "$_ibx"; printf '%s\n' '- [a note](a-note.md)' > "$_ibx/MEMORY.md"; _ibage "$_ibx/MEMORY.md" 1
_ibrun B1T -- inventory --repo "$IB/b1" --tsv --no-gh; _ibrun B1V -- inventory --repo "$IB/b1" --no-gh
is  "inventory B1: a file in the record directory outside every session's own directory, the auto-memory's MEMORY.md written a minute ago, is no activity: the worktree whose one session last worked 3 hours ago is not live, and holds its uncommitted work" \
    "$(_ibmany B1T worktree "$IBB1R" live uncommitted) $(_ibcol B1T worktree "$IBB1R" 5)" "live=no uncommitted=yes s-b1old"
is  "inventory B1: and the view lists that worktree under uncommitted, rather than only counting it live" "$(_ibgroup2 "$(_ibo B1V)" "$IBB1R")" "uncommitted"

# B2 (f7): orphans holding a file the run cannot read (mode 000). gone2's other
# file holds content in no object; gone3's other file is README.md's content.
_ibnew b2
_ibg -C "$IB/b2" worktree add -q -b b2live "$IB/b2/.claude/worktrees/live1"
for _ibn in gone2 gone3; do
  mkdir -p "$IB/b2/.claude/worktrees/$_ibn"
  printf 'gitdir: %s/.git/worktrees/%s\n' "$IB/b2" "$_ibn" > "$IB/b2/.claude/worktrees/$_ibn/.git"
  printf 'the run cannot read this\n' > "$IB/b2/.claude/worktrees/$_ibn/a-locked"; chmod 000 "$IB/b2/.claude/worktrees/$_ibn/a-locked"
done
printf 'the only copy of this work\n' > "$IB/b2/.claude/worktrees/gone2/b-unique"
printf 'b2\n' > "$IB/b2/.claude/worktrees/gone3/b-known"
if [ -r "$IB/b2/.claude/worktrees/gone2/a-locked" ]; then
  chmod 600 "$IB/b2/.claude/worktrees/gone2/a-locked" "$IB/b2/.claude/worktrees/gone3/a-locked"
  skip "inventory B2: an orphan's file the run cannot read is said, and its content is not landed" "a mode 000 file is readable here (run as root?)"
else
  _ibrun B2T -- inventory --repo "$IB/b2" --tsv --no-gh --no-host; _ibrun B2V -- inventory --repo "$IB/b2" --no-gh --no-host
  chmod 600 "$IB/b2/.claude/worktrees/gone2/a-locked" "$IB/b2/.claude/worktrees/gone3/a-locked"
  _ibb2() { _ibcol B2T orphan "$IB/b2/.claude/worktrees/$1" "$2"; }
  is  "inventory B2: an orphan holding a file the run cannot read, before a file whose content is in no object, counts that file, says a file could not be read, and its content is not" \
      "$(_ibb2 gone2 7) $(_ibb2 gone2 8 | LC_ALL=C awk '{ split($0, e, "; "); print (e[1] ~ /^1 of [0-9]+ files hold content in no object of the repository$/ ? "one" : "first element: " e[1]) }') $(_ibb2 gone2 8 | _ibsaid 'could not be read')" \
      "not one said"
  is  "inventory B2: and an orphan whose only other file is in an object has content unknown, never landed, and says a file could not be read" \
      "$(_ibb2 gone3 7) $(_ibholds B2T orphan "$IB/b2/.claude/worktrees/gone3" landed) $(_ibb2 gone3 8 | _ibsaid 'could not be read')" "unknown no said"
  is  "inventory B2: and the view counts neither as an orphan holding nothing unique" "$(_ibnothing "$(_ibo B2V)")" "0"
fi

# B3 (f2): a branch whose commit names a parent this clone lacks (a broken
# alternate or an interrupted fetch leaves this), beside a healthy branch whose
# one commit is on no remote.
_ibnew b3
_ibmk - "$IB/b3" HEAD 'good' good.txt 'good, nowhere else'; _ibg -C "$IB/b3" branch -q good "$IBC"
printf -v _ibx 'tree %s\nparent 1111111111111111111111111111111111111111\nauthor Fixture <fixture@example.invalid> %s +0000\ncommitter Fixture <fixture@example.invalid> %s +0000\n\nbroken\n' \
  "$(_ibq -C "$IB/b3" rev-parse 'HEAD^{tree}')" "$(_ibago 60)" "$(_ibago 60)"
_ibx="$(printf '%s' "$_ibx" | _ibg -C "$IB/b3" hash-object -t commit -w --literally --stdin)"
_ibg -C "$IB/b3" update-ref refs/heads/broken "$_ibx"
_ibrun B3T -- inventory --repo "$IB/b3" --tsv --no-gh --no-host
is  "inventory B3: a commit object one branch's history needs and the clone lacks leaves another branch's reading alone: the healthy one is unpushed, content not, never landed" \
    "$(_ibmany B3T branch good unpushed landed) $(_ibcol B3T branch good 7)" "unpushed=yes landed=no not"
is  "inventory B3: and the broken branch's content is unknown, which says it could not be read, and it is never landed" \
    "$(_ibcol B3T branch broken 7) $(_ibholds B3T branch broken landed)" "unknown no"

# B4 (f4): feat's PR #1 was squash-merged at its first commit, its head deleted
# on merge and pruned from the clone, and feat then gained a commit; its
# upstream is now [gone]. featb is f4 as built: PR #2 merged at its first
# commit, no remote-tracking ref and no upstream, and a commit after.
_ibnew b4
IB_B4T="$(_ibq -C "$IB/b4" rev-parse HEAD)"
_ibmk - "$IB/b4" "$IB_B4T" 'feat one' feat.txt 'feat one'; IB_B4F1="$IBC"
_ibg -C "$IB/b4" push -q origin "$IB_B4F1:refs/heads/feat"; _ibg -C "$IB/b4" fetch -q origin
_ibmk - "$IB/b4" "$IB_B4T" 'featb one' featb.txt 'featb one'; IB_B4G1="$IBC"
_ibmk - "$IB/b4-origin.git" "$IB_B4T" 'feat one (#1)' feat.txt 'feat one'
_ibmk - "$IB/b4-origin.git" "$IBC" 'featb one (#2)' featb.txt 'featb one'
_ibg -C "$IB/b4-origin.git" update-ref refs/heads/main "$IBC"; _ibg -C "$IB/b4-origin.git" update-ref -d refs/heads/feat
_ibg -C "$IB/b4" fetch -q --prune origin
_ibmk - "$IB/b4" "$IB_B4F1" 'feat two' feat2.txt 'feat two, nowhere else'; _ibg -C "$IB/b4" branch -q feat "$IBC"
_ibg -C "$IB/b4" config branch.feat.remote origin; _ibg -C "$IB/b4" config branch.feat.merge refs/heads/feat
_ibmk - "$IB/b4" "$IB_B4G1" 'featb two' featb2.txt 'featb two, nowhere else'; _ibg -C "$IB/b4" branch -q featb "$IBC"
_ibg -C "$IB/b4" remote set-url origin git@github.com:acme/bravo4.git
mkdir -p "$IB/gh/acme_bravo4"
printf '[{"baseRefName":"main","headRefName":"feat","headRefOid":"%s","isCrossRepository":false,"number":1,"state":"MERGED","updatedAt":"%s"},{"baseRefName":"main","headRefName":"featb","headRefOid":"%s","isCrossRepository":false,"number":2,"state":"MERGED","updatedAt":"%s"}]\n' \
  "$IB_B4F1" "$(_ibts 120)" "$IB_B4G1" "$(_ibts 120)" > "$IB/gh/acme_bravo4/all.json"
printf '[]\n' > "$IB/gh/acme_bravo4/open.json"
_ibrun B4T -- inventory --repo "$IB/b4" --tsv --no-host
_ibnames_pr() { _ibcol B4T branch "$1" 8 | LC_ALL=C awk -v p="$2" '{ s = $0; while ((i = index(s, p))) { c = substr(s, i + length(p), 1); if (c !~ /[0-9]/) f = 1; s = substr(s, i + length(p)) } } END { print (f ? p : "no " p) }'; }
is  "inventory B4: a branch whose merged PR's head was deleted on merge and pruned, with a commit after the merge, is unpushed and unproposed, naming that PR, and not landed" \
    "$(_ibmany B4T branch feat unpushed unproposed landed) $(_ibnames_pr feat '#1')" "unpushed=yes unproposed=yes landed=no #1"
is  "inventory B4: and its detail says its upstream is gone" "$(_ibcol B4T branch feat 8 | _ibsaid 'upstream gone')" "said"
is  "inventory B4: and a branch that never had a remote-tracking ref, its PR merged and a commit after, is unproposed too, naming its PR" \
    "$(_ibmany B4T branch featb unpushed unproposed landed) $(_ibnames_pr featb '#2')" "unpushed=yes unproposed=yes landed=no #2"

# B5 (f9): stacked PRs. stack2's PR #2 merged into stack1, and stack1's PR #1
# is open; neither branch's content is on main. Both are pushed.
_ibnew b5
IB_B5T="$(_ibq -C "$IB/b5" rev-parse HEAD)"
_ibmk - "$IB/b5" "$IB_B5T" 'stack one' s1.txt 'stack one, nowhere on main'; IB_B5H1="$IBC"; _ibg -C "$IB/b5" branch -q stack1 "$IBC"
_ibmk - "$IB/b5" "$IB_B5H1" 'stack two' s2.txt 'stack two, nowhere on main'; IB_B5H2="$IBC"; _ibg -C "$IB/b5" branch -q stack2 "$IBC"
_ibg -C "$IB/b5" push -q origin stack1 stack2; _ibg -C "$IB/b5" fetch -q origin
_ibg -C "$IB/b5" remote set-url origin git@github.com:acme/bravo5.git
mkdir -p "$IB/gh/acme_bravo5"
printf '[{"baseRefName":"main","headRefName":"stack1","headRefOid":"%s","isCrossRepository":false,"number":1,"state":"OPEN","updatedAt":"%s"},{"baseRefName":"stack1","headRefName":"stack2","headRefOid":"%s","isCrossRepository":false,"number":2,"state":"MERGED","updatedAt":"%s"}]\n' \
  "$IB_B5H1" "$(_ibts 120)" "$IB_B5H2" "$(_ibts 60)" > "$IB/gh/acme_bravo5/all.json"
printf '[{"isDraft":false,"labels":[],"mergeable":"MERGEABLE","number":1,"statusCheckRollup":[]}]\n' > "$IB/gh/acme_bravo5/open.json"
_ibrun B5T -- inventory --repo "$IB/b5" --tsv --no-host; _ibrun B5V -- inventory --repo "$IB/b5" --no-host
is  "inventory B5: a PR merged into another PR's branch, not the default branch, does not land its head: that branch is not landed, and its content, nowhere on main, is not" \
    "$(_ibholds B5T branch stack2 landed) $(_ibcol B5T branch stack2 7)" "no not"
is  "inventory B5: and the view lists that branch rather than counting it landed" \
    "$(case "$(_ibgroup2 "$(_ibo B5V)" stack2)" in (unlisted) echo unlisted ;; (*) echo listed ;; esac)" "listed"

# ---- the second review's blockers B6-B8 (build/review-round2.md, v3 v4 v5 v7) --
# Section 5.2, "unread is unknown" (ruled 2026-10-02): what a reader could not
# read is said, and the value it would have decided is unknown, never absent and
# never landed. Each block is built from the reviewer's fixture and carries a
# control run in which everything is readable, so the fixture is shown to hold
# what the assertion says it holds. The mode 000 files are readable to root,
# where the blocks skip.
# B6 (v3's o2): an orphan directory the run cannot enter, untracked inside the
# main worktree, holding a file whose content is in no object.
_ibnew b6
_ibg -C "$IB/b6" worktree add -q -b b6live "$IB/b6/.claude/worktrees/live1"
mkdir -p "$IB/b6/.claude/worktrees/gone6"
printf 'unique, in no object\n' > "$IB/b6/.claude/worktrees/gone6/u"; chmod 000 "$IB/b6/.claude/worktrees/gone6"
if [ -r "$IB/b6/.claude/worktrees/gone6/u" ]; then
  chmod 755 "$IB/b6/.claude/worktrees/gone6"
  skip "inventory B6: an orphan directory the run cannot enter is said, and its content is unknown, not landed" "a mode 000 directory is readable here (run as root?)"
else
  _ibrun B6T -- inventory --repo "$IB/b6" --tsv --no-gh --no-host; _ibrun B6V -- inventory --repo "$IB/b6" --no-gh --no-host
  chmod 755 "$IB/b6/.claude/worktrees/gone6"
  _ibb6() { _ibcol B6T orphan "$IB/b6/.claude/worktrees/gone6" "$1"; }
  is  "inventory B6: an orphan directory the run cannot enter has content unknown, never landed, and says it could not be read" \
      "$(_ibb6 7) $(_ibholds B6T orphan "$IB/b6/.claude/worktrees/gone6" landed) $(_ibb6 8 | _ibsaid 'could not be read')" "unknown no said"
  is  "inventory B6: and the view counts it as no orphan holding nothing unique" "$(_ibnothing "$(_ibo B6V)")" "0"
fi

