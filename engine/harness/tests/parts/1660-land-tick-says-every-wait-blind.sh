# >>> land-tick-says-every-wait
printf '\nthe land tick says every wait again, a hand merge deploys itself, and the brakes leave rows (audit b02, B10-B25, A25-A60, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b02-land-tick-never-refuses-or-waits-silentl.md
# alone (section 4, "Fixture for 1660" and "Part 1660 assertions"), on the fixture of tests/lib/land-on-green.sh
# that parts 1280-1289 use. lib/green-tick.sh, lib/green-install.sh, the felix CLI and every other engine file
# were not read. main's felix_accepted_deploy_diff is called once, as 1282's _la_accepts calls it, by a fixture
# control that shows B16's check (d) holds; it was not read.
#
# gh: a wrapper over the stub answers `auth status` itself while ctl/gh-accounts exists, by gh 2.102's rule for
# the table there (host, user, active, token): --hostname H (or --hostname=H, -h H) keeps the rows for H, --active
# (or -a) the active ones, and it exits 1 when no row is kept or a kept row is stale. Otherwise the stub answers,
# ctl/gh-auth.rc included. pgrep: the stub numbers the matching lines of ctl/procs 40001, 40002, ...; a wrapper
# makes it exit with ctl/pgrep.rc's status while that file exists, unless the pgrep in the bin already does (part
# 1283 leaves one). git: a wrapper fails git fetch while ctl/fetch.rc exists, as 1283's does. Each wrapper is
# taken away at the end. A trampoline case runs --install then _lg_reset first, so B24's row is never counted
# there. Rows are aged only as part 1280's _lg_age ages them, the year moved back by one; T0 is read off the aged
# row. A cache entry is named either as $LGV/<version> or through HOME's link to the same cache, which is how the
# trampoline, under launchd's environment, finds it. Where the contract leaves the words open, nothing is
# asserted of them; A39 has no seam and is skipped.
_lg_build amend
L60="$LG/round60"; mkdir -p "$L60"; : > "$L60/brakes.tsv"
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1
L60VM="$(_l3_mainv)"; [ -n "$L60VM" ] && _lg_cache "$L60VM"
L60E="$LGV/$L60VM/harness/felix"; L60PL="$LGU/Library/LaunchAgents/felix.land.lgh.plist"; L60PW=""

_l60_has() { case "$1" in *"$2"*) printf yes ;; *) printf no ;; esac; }
_l60_lacks() { case "$1" in *"$2"*) printf no ;; *) printf yes ;; esac; }
_l60_begins() { case "$1" in "$2"*) printf yes ;; *) printf no ;; esac; }
_l60_entry() {   # DETAIL VERSION -> yes when DETAIL names that version's cache entry, by either spelling
  case "$1" in *"$LGV/$2"*|*"$LGU/.claude/plugins/cache/felix/felix/$2"*) printf yes ;; *) printf no ;; esac
}
_l60_same() {   # PAUSED DETAIL -> yes when both are there and one holds the other
  if [ -n "$1" ] && [ -n "$2" ]; then
    case "$2" in *"$1"*) printf yes; return 0 ;; esac
    case "$1" in *"$2"*) printf yes; return 0 ;; esac
  fi
  printf no
}
_l60_osa() { _lg_logs osa | LC_ALL=C awk -v t="with title \"$1\"" 'index($0, t) { n++ } END { print n + 0 }'; }
_l60_age() {   # every ledger row's year moved back by one, as part 1280's _lg_age does
  [ -f "$LAND/ledger.tsv" ] || return 0
  LC_ALL=C awk -F'\t' -v OFS='\t' -v y="$(date -u +%Y)" '{ if (index($1, y)) sub(y, y - 1, $1); print }' \
    "$LAND/ledger.tsv" > "$LAND/ledger.aged" && /bin/mv "$LAND/ledger.aged" "$LAND/ledger.tsv"
}
_l60_inst() { _lg_land --install; _lg_reset; }
_l60_keep() { [ -f "$LAND/ledger.tsv" ] && cat "$LAND/ledger.tsv" >> "$L60/brakes.tsv"; return 0; }
_l60_owed() {   # -> after a trampoline run: ticks|deploy-owed rows|the row names not installed|status
  printf '%s|%s|%s|%s' "$(_la_ticks)" "$(_lg_n deploy-owed)" "$(_l60_has "$(_lg_f deploy-owed "" 7)" 'not installed')" "$LARC"
}
_l60_acc() {   # -> origin/main's own felix_accepted_deploy_diff on the home and refs/heads/main: its status
  ( unset FELIX_KERNEL_CACHE; FELIX_PLUGIN_CACHE="$LGC"
    git -C "$LGH" show refs/remotes/origin/main:engine/harness/lib/resolve.sh > "$L60/resolve.main" 2>/dev/null || exit 9
    . "$L60/resolve.main" >/dev/null 2>&1; felix_accepted_deploy_diff "$LGH" refs/heads/main >/dev/null 2>&1 ); echo "$?"
}

# ------------------------------------------------------------ the wrappers ---
[ -f "$L60/gh.prev" ] || /bin/mv "$LGB/gh" "$L60/gh.prev"
_lg_put "$LGB/gh" <<'L60GH'
#!/bin/bash
LG='@LG@'; K="$LG/ctl"
if [ "${1:-} ${2:-}" = "auth status" ] && [ -f "$K/gh-accounts" ]; then
  printf '%s\n' "$*" >> "$LG/log/gh.log"
  h=""; a=""; p=""
  for x in "$@"; do
    case "$p" in --hostname|-h) h="$x" ;; esac
    case "$x" in --hostname=*) h="${x#--hostname=}" ;; --active|-a) a=1 ;; esac
    p="$x"
  done
  n=0; s=0; T="$(printf '\t')"
  while IFS="$T" read -r host user act tok; do
    [ -n "$host" ] || continue
    [ -z "$h" ] || [ "$host" = "$h" ] || continue
    [ -z "$a" ] || [ "$act" = yes ] || continue
    n=$((n + 1)); [ "$tok" = ok ] || s=1
  done < "$K/gh-accounts"
  [ "$n" -gt 0 ] && [ "$s" -eq 0 ] && exit 0
  echo "X Failed to log in to an account: the token in keyring is invalid." >&2
  exit 1
fi
exec "$LG/round60/gh.prev" "$@"
L60GH
_lg_reset; printf '2\n' > "$LGK/pgrep.rc"; "$LGB/pgrep" -f x >/dev/null 2>&1; L60A=$?
if [ "$L60A" != 2 ]; then
  /bin/mv "$LGB/pgrep" "$L60/pgrep.prev"; L60PW=1
  _lg_put "$LGB/pgrep" <<'L60PG'
#!/bin/bash
LG='@LG@'
if [ -f "$LG/ctl/pgrep.rc" ]; then printf '%s\n' "$*" >> "$LG/log/pgrep.log"; echo "pgrep: cannot read the process table" >&2; exit "$(cat "$LG/ctl/pgrep.rc")"; fi
exec "$LG/round60/pgrep.prev" "$@"
L60PG
fi
_lg_reset; printf '2\n' > "$LGK/pgrep.rc"; "$LGB/pgrep" -f x >/dev/null 2>&1; L60A=$?; rm -f "$LGK/pgrep.rc"
printf '/bin/bash /x/engine/harness/tests/run\n/bin/bash /y/gate.sh widget\nvim /z/notes.txt\n' > "$L60/procs"
cp "$L60/procs" "$LGK/procs"
is "the land fixture: the pgrep in the bin exits with ctl/pgrep.rc's status while it exists, and else numbers the matching lines of ctl/procs from 40001 (fixture control)" \
   "$L60A|$("$LGB/pgrep" -f 'engine/harness/tests/run|gate\.sh' 2>&1 | tr '\n' ' ')" "2|40001 40002 "
_lg_reset; printf 'github.com\tLeavesJ\tyes\tok\nghe.example.invalid\tolduser\tyes\tstale\n' > "$LGK/gh-accounts"
L60A=""; for L60K in "" "--hostname github.com --active" "-h github.com -a" "--hostname=ghe.example.invalid"; do
  "$LGB/gh" auth status $L60K >/dev/null 2>&1; L60A="$L60A$?"
done
is "the land fixture: the gh wrapper answers auth status by the table: bare 1 (a stale account anywhere), github.com active 0 either way, ghe.example.invalid 1 (fixture control)" "$L60A" "1001"
is "the land fixture: the home is on main at origin's main, and main's check accepts its entry (fixture control)" \
   "$(git -C "$LGH" rev-parse --abbrev-ref HEAD 2>&1)|$(git -C "$LGH" rev-parse HEAD 2>&1)|$(_la_accepts)" "main|$(git -C "$LGO" rev-parse main 2>&1)|0"

# ------------------------------------------------------ B10, B11: gh check ---
_l60_gh() {   # TABLE -> a fresh ledger, 42 green, ctl/gh-accounts holding TABLE (\t and \n as printf reads them), one tick
  _lg_reset; printf "$1" > "$LGK/gh-accounts"; _lg_prs "$(_lg_pr 42)"; _lg_green 42; _lg_land --tick
}
_l60_gh 'github.com\tLeavesJ\tyes\tok\nghe.example.invalid\tolduser\tyes\tstale\n'
is "A25 (B10): a stale token for another host (ghe.example.invalid) beside a working github.com one does not stop the tick: 42 lands, no gh row" \
   "$(_lg_n landed 42)|$(_lg_n gh)" "1|0"
_l60_gh 'github.com\tLeavesJ\tyes\tok\ngithub.com\toldwork\tno\tstale\n'
is "A26 (B10): a stale token for an inactive github.com account does not stop the tick: 42 lands, no gh row" \
   "$(_lg_n landed 42)|$(_lg_n gh)" "1|0"
_l60_gh 'github.com\tLeavesJ\tyes\tstale\n'; L60D="$(_lg_f gh "" 7)"
is "A27 (B10): a stale active github.com account stops the tick: one gh row, no gh pr list, nothing merged" \
   "$(_lg_n gh)|$(_lg_logs gh | grep -c '^pr list')|$(_lg_merges)" "1|0|"
_l60_gh ''
is "A28 (B10): no account at all stops the tick: one gh row, nothing merged" "$(_lg_n gh)|$(_lg_merges)" "1|"
is "A29 (B11): the gh row's detail begins gh auth status and names github.com" \
   "$(_l60_begins "$L60D" 'gh auth status')|$(_l60_has "$L60D" github.com)" "yes|yes"

# --------------------------------------------- B12-B14: the deploy wait, said again ---
rm -rf "$LGV/$L60VM"; _lg_reset; cp "$L60/procs" "$LGK/procs"; _lg_land --tick; L60D="$(_lg_f deploy-owed "" 7)"
is "A30 (B12): with main's entry gone and two of three processes matching, the deploy-owed row begins a gate or suite is running and names pid 40001 and pid 40002, not pid 40003" \
   "$(_lg_n deploy-owed)|$(_l60_begins "$L60D" 'a gate or suite is running')|$(_l60_has "$L60D" 'pid 40001')|$(_l60_has "$L60D" 'pid 40002')|$(_l60_lacks "$L60D" 'pid 40003')" \
   "1|yes|yes|yes|yes"
L60A="$(_lg_logs pgrep | LC_ALL=C awk '{ for (i = 1; i <= NF; i++) if ($i == "-f") n++ } END { print n + 0 }')"
[ "$L60A" -ge 1 ] && ok "A31 (B12): pgrep is handed -f as an argument of its own" \
  || bad "A31 (B12): pgrep is handed -f as an argument of its own" "pgrep saw: $(_lg_logs pgrep | head -3 | tr '\n' '|')"
printf '/bin/bash /w/engine/harness/tests/run\n' >> "$LGK/procs"; _lg_land --tick
is "A32 (B13): a third matching process inside the hour is the same wait: still one deploy-owed row and one notification" \
   "$(_lg_n deploy-owed)|$(_l60_osa 'Felix: deploy-owed')" "1|1"
_l60_age; L60T0="$(_lg_f deploy-owed "" 1)"; _lg_land --tick; L60D="$(_lg_f deploy-owed "" 7)"
is "A33 (B13): once the wait's row is an hour old, the next tick writes a second row and notification, its detail beginning a gate or suite is running; still so since <T0> and naming pid 40001" \
   "$(_lg_n deploy-owed)|$(_l60_osa 'Felix: deploy-owed')|$(_l60_begins "$L60D" "a gate or suite is running; still so since $L60T0")|$(_l60_has "$L60D" 'pid 40001')" \
   "2|2|yes|yes"
_lg_land --tick
is "A34 (B13): the tick after, inside the second row's hour, writes none: still 2 deploy-owed rows" "$(_lg_n deploy-owed)" "2"
L60B="$(_lg_n deploy-owed)"; printf '1\n' > "$LGK/gh-auth.rc"; _lg_land --tick; L60G="$(_lg_n gh)"
rm -f "$LGK/gh-auth.rc"; _lg_land --tick; L60D="$(_lg_f deploy-owed "" 7)"
is "A35 (B14): a gh row in between ends the wait's run: the gh tick writes one gh row, and the next tick one more deploy-owed row (3 after A33's), a first row again with no still so since" \
   "$L60G|$(_lg_n deploy-owed)|$(_l60_lacks "$L60D" 'still so since')" "1|$((L60B + 1))|yes"
_lg_reset; printf '2\n' > "$LGK/pgrep.rc"; _lg_land --tick; L60D="$(_lg_f deploy-owed "" 7)"
_l60_age; _lg_land --tick
is "A36 (B12, B13): a pgrep that exits 2 gives the row a gate or suite may be running: pgrep exited 2, and once it is an hour old a second row saying still so since" \
   "$L60D|$(_lg_n deploy-owed)|$(_l60_has "$(_lg_f deploy-owed "" 7)" 'still so since')" "a gate or suite may be running: pgrep exited 2|2|yes"
_lg_cache "$L60VM"

_lg_reset; printf '1\n' > "$LGK/gh-auth.rc"; _lg_land --tick; L60A="$(_lg_n gh)|$(_lg_cnt osa)"; _l60_age; _lg_land --tick
is "A37 (B13): a gh stop is written and notified once, and once its row is an hour old once more, saying still so since" \
   "$L60A|$(_lg_n gh)|$(_lg_cnt osa)|$(_l60_has "$(_lg_f gh "" 7)" 'still so since')" "1|1|2|2|yes"
_lg_put "$LGB/git" <<'L60GIT'
#!/bin/bash
LG='@LG@'; s=""; k=""
for a in "$@"; do
  if [ -n "$k" ]; then k=""; continue; fi
  case "$a" in -C|-c|--git-dir|--work-tree|--namespace|--config-env) k=1 ;; -*) ;; *) s="$a"; break ;; esac
done
if [ "$s" = fetch ] && [ -f "$LG/ctl/fetch.rc" ]; then
  printf 'fetch\n' >> "$LG/log/fetchfail.log"; echo "fatal: unable to access origin: Could not resolve host" >&2; exit "$(cat "$LG/ctl/fetch.rc")"
fi
exec "$(cat "$LG/amend/realgit")" "$@"
L60GIT
_lg_reset; printf '128\n' > "$LGK/fetch.rc"; _lg_land --tick; L60A="$(_lg_n fetch)"; _l60_age; _lg_land --tick
L60B="$(_lg_cnt fetchfail)"; rm -f "$LGB/git"
is "the land fixture: the ticks' fetches failed through the wrapper (fixture control)" "$([ "$L60B" -ge 1 ] && echo yes)" "yes"
is "A38 (B13): a fetch stop is written once, and once its row is an hour old once more, saying still so since" \
   "$L60A|$(_lg_n fetch)|$(_l60_has "$(_lg_f fetch "" 7)" 'still so since')" "1|2|yes"
skip "A39 (B13): a stuck lock is said again each hour like every other wait" "no seam ages a live lock past 45 minutes, so stuck is not driven"

# ------------------------------------------------- B15: the trampoline too ---
_l60_inst; printf 'not main\n' > "$LGH/engine/harness/l60-untracked.txt"
_la_tramp; L60A="$LARC"; _la_tramp; L60A="$(_lg_n deploy-owed)|$(_l60_osa 'Felix: deploy-owed')|$L60A $LARC"
_l60_age; L60T0="$(_lg_f deploy-owed "" 1)"; _la_tramp
is "A40 (B15): with an untracked file under the home's engine/harness, two trampoline runs write one deploy-owed row and one notification, exit 1 both times; aged, a third writes a second, notified, saying still so since <T0>, and runs no land --tick" \
   "$L60A|$(_lg_n deploy-owed)|$(_l60_osa 'Felix: deploy-owed')|$(_l60_has "$(_lg_f deploy-owed "" 7)" "still so since $L60T0")|$(_la_ticks)" \
   "1|1|1 1|2|2|yes|0"
rm -f "$LGH/engine/harness/l60-untracked.txt"

# ------------------------------------------- B16-B19: a hand merge deploys itself ---
L60C="$(git -C "$LGH" rev-parse HEAD 2>/dev/null)"
printf '{ "name": "felix", "version": "9.65.0" }\n' > "$LGH/engine/.claude-plugin/plugin.json"
_fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qam 'bump to 9.65.0' >/dev/null 2>&1
_fx_git "$LGH" push -q origin main >/dev/null 2>&1; _fx_git "$LGH" reset -q --hard "$L60C" >/dev/null 2>&1; rm -rf "$LGV/9.65.0"
_l60_a41() { git -C "$LGH" merge-base --is-ancestor refs/heads/main refs/remotes/origin/main 2>/dev/null \
  && [ "$(git -C "$LGH" rev-parse refs/heads/main 2>&1)" != "$(git -C "$LGH" rev-parse refs/remotes/origin/main 2>&1)" ] && echo behind; }
is "the land fixture: A41's state: the home on main at the commit of its own version Vm, strictly behind origin/main, which declares 9.65.0, with no 9.65.0 entry, and origin/main's check accepts the Vm entry for refs/heads/main (fixture control)" \
   "$(git -C "$LGH" symbolic-ref HEAD 2>&1)|$(_l60_a41)|$(_l3_mainv)|$([ -e "$LGV/9.65.0" ] && echo there)|$(_l60_acc)" \
   "refs/heads/main|behind|9.65.0||0"
_l60_inst; _la_tramp
is "A41 (B16): a home on main strictly behind an origin/main whose entry is missing, its own version's entry accepted: the trampoline runs exactly one land --tick, from the Vm entry, exits 0, and writes and sends nothing" \
   "$(_la_ticks)|$(_lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick" { print $1 }')|$LARC|$(_lg_n deploy-owed)|$(_lg_cnt osa)" "1|$L60E|0|0|0"
L60A="$(cat "$LG/out.tramp" 2>/dev/null)"
is "A42 (B16): and what it prints names 9.65.0 and Vm" "$(_l60_has "$L60A" 9.65.0)|$(_l60_has "$L60A" "$L60VM")" "yes|yes"
is "A43 (B16): and that tick ran with FELIX_ALLOW_RED, FELIX_KERNEL and FELIX_KERNEL_CACHE unset" \
   "$(_lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick" { printf "%s%s %s %s", s, $4, $5, $6; s = "|" }')" "unset unset unset"
_fx_git "$LGH" checkout -q -b l60-side >/dev/null 2>&1; _l60_inst; _la_tramp
is "A44 (B17): A41's state with the home on another branch: no land --tick, one deploy-owed row saying not installed, exit 1" "$(_l60_owed)" "0|1|yes|1"
_fx_git "$LGH" checkout -q main >/dev/null 2>&1; _fx_git "$LGH" branch -q -D l60-side >/dev/null 2>&1
mkdir -p "$LGH/notes"; printf 'local\n' > "$LGH/notes/l60-local.md"; _fx_git "$LGH" add notes/l60-local.md >/dev/null 2>&1
_fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qm 'l60 local' >/dev/null 2>&1; _l60_inst; _la_tramp
is "A45 (B17): A41's state with one local commit on the home's main, so no ancestor of origin/main: no land --tick, one deploy-owed row saying not installed, exit 1" "$(_l60_owed)" "0|1|yes|1"
_fx_git "$LGH" reset -q --hard "$L60C" >/dev/null 2>&1
printf 'extra\n' > "$LGV/$L60VM/harness/l60-extra.txt"; _l60_inst; _la_tramp
is "A46 (B17): A41's state with one extra file in the Vm entry, which main's check rejects: no land --tick, one deploy-owed row saying not installed, exit 1" "$(_l60_owed)" "0|1|yes|1"
rm -f "$LGV/$L60VM/harness/l60-extra.txt"
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1; _l60_inst; _la_tramp
is "A47 (B17): the home reset to origin/main, whose entry is missing: no land --tick, one deploy-owed row saying not installed, exit 1" "$(_l60_owed)" "0|1|yes|1"
_fx_git "$LGH" reset -q --hard "$L60C" >/dev/null 2>&1
_lg_cache 9.65.0; chmod -x "$LGV/9.65.0/harness/felix"; _l60_inst; _la_tramp
is "A48 (B18): A41's state with a 9.65.0 entry whose felix is not executable: no land --tick from any entry, and the row says so (execut)" \
   "$(_la_ticks)|$(_l60_has "$(_lg_lc "$(_lg_f deploy-owed "" 7)")" execut)" "0|yes"
rm -rf "$LGV/9.65.0"
_lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; _lg_land --tick; L60A="$(_lg_ninst)|$(_lg_n deployed)|$(_lg_merges)"; _lg_land --tick
is "A49 (B19): from A41's state the tick installs once, writes one deployed row and merges nothing; the next tick lands 42 through the 9.65.0 entry" \
   "$L60A|$(_lg_n landed 42)|$(_l3_mpath)" "1|1||1|$LGV/9.65.0/harness/felix "

# ---------------------------------------------- B20, B21: the entry named truly ---
L60V2="$(_l3_mainv)"
printf 'extra\n' > "$LGV/$L60V2/harness/l60-extra.txt"
is "the land fixture: the home is at origin's main, which declares 9.65.0, and main's check rejects that entry with its extra file (fixture control)" \
   "$(git -C "$LGH" rev-parse HEAD 2>&1)|$(_la_accepts)" "$(git -C "$LGO" rev-parse main 2>&1)|1"
_lg_reset; : > "$LGK/install.taint"; _lg_land --tick; L60D="$(_lg_f deploy-failed "" 7)"
is "A50 (B20): an entry at main's version that existed before the install and still differs after it: one deploy-failed row beginning diff:, saying felix install does not replace it, naming the entry, and paused holds the same reason" \
   "$(_lg_n deploy-failed)|$(_l60_begins "$L60D" 'diff:')|$(_l60_has "$L60D" 'does not replace')|$(_l60_entry "$L60D" "$L60V2")|$(_l60_same "$(cat "$LAND/paused" 2>/dev/null)" "$L60D")" \
   "1|yes|yes|yes|yes"
rm -rf "$LGV/$L60V2"; _lg_reset; : > "$LGK/install.taint"; _lg_land --tick
is "A51 (B20): with no entry before the install, the diff: row does not say does not replace" \
   "$(_lg_n deploy-failed)|$(_l60_lacks "$(_lg_f deploy-failed "" 7)" 'does not replace')" "1|yes"
_lg_cache "$L60V2"
printf 'extra\n' > "$LGV/$L60V2/harness/l60-extra.txt"; _l60_inst; _la_tramp; L60D="$(_lg_f deploy-owed "" 7)"
is "A52 (B21): the trampoline's differs row says differs and that felix install does not replace an entry that exists, names the entry, and no longer says deployed from the home" \
   "$(_lg_n deploy-owed)|$(_l60_has "$L60D" differs)|$(_l60_has "$L60D" 'does not replace')|$(_l60_entry "$L60D" "$L60V2")|$(_l60_lacks "$L60D" 'deployed from the home')" \
   "1|yes|yes|yes|yes"
rm -f "$LGV/$L60V2/harness/l60-extra.txt"

# ------------------------------------------------ B22-B25: the brakes leave rows ---
_lg_reset; LGX=(CLAUDE_CODE_SESSION_ID=s-1660); _lg_land --pause "hold until I read #460"; LGX=()
is "A53 (B22): --pause with a reason writes paused as that reason and at once one paused row, by session s-1660, notified as Felix: paused" \
   "$LGRC|$(cat "$LAND/paused" 2>/dev/null)|$(_lg_n paused)|$(_lg_f paused - 7)|$(_l60_osa 'Felix: paused')" \
   "0|hold until I read #460|1|hold until I read #460; by session s-1660|1"
_lg_land --tick
is "A54 (B22): a tick right after, inside the hour, writes no further paused row" "$(_lg_n paused)" "1"
LGX=(CLAUDE_CODE_SESSION_ID=s-1660); _lg_land --resume; LGX=()
is "A56 (B23): --resume over that pause writes one resumed row quoting it, by session s-1660, notified as Felix: resumed, and removes paused" \
   "$LGRC|$(_lg_n resumed)|$(_lg_f resumed - 7)|$(_l60_osa 'Felix: resumed')|$([ -e "$LAND/paused" ] && echo paused)" \
   "0|1|the pause read: hold until I read #460; by session s-1660|1|"
L60A="$(_lg_rows)"; _lg_land --resume
is "A57 (B23): --resume with nothing paused exits 0 and writes no row" "$LGRC|$(_lg_rows)" "0|$L60A"
_l60_keep; _lg_reset; LGX=(CLAUDE_CODE_SESSION_ID=); _lg_land --pause x; LGX=()
case "$(_lg_f paused - 7)" in *"; by session -") ok "A55 (B22): with CLAUDE_CODE_SESSION_ID empty, the paused row's detail ends ; by session -" ;;
  *) bad "A55 (B22): with CLAUDE_CODE_SESSION_ID empty, the paused row's detail ends ; by session -" "[$(_lg_f paused - 7)]" ;; esac
_l60_keep; _lg_reset; LGX=(CLAUDE_CODE_SESSION_ID=s-1660); _lg_land --install; L60A="$LGRC"; LGX=(); L60D="$(_lg_f installed - 7)"
is "A58 (B24): --install exits 0 and writes one installed row naming the plist, by session s-1660, notified as Felix: installed" \
   "$L60A|$(_lg_n installed)|$(_l60_has "$L60D" "$L60PL")|$(_l60_has "$L60D" 'by session s-1660')|$(_l60_osa 'Felix: installed')" "0|1|yes|yes|1"
LGX=(CLAUDE_CODE_SESSION_ID=s-1660); _lg_land --uninstall; L60A="$LGRC"; LGX=()
is "A59 (B25): --uninstall exits 0 and writes one uninstalled row, by session s-1660, notified as Felix: uninstalled" \
   "$L60A|$(_lg_n uninstalled)|$(_l60_has "$(_lg_f uninstalled - 7)" 'by session s-1660')|$(_l60_osa 'Felix: uninstalled')" "0|1|yes|1"
_l60_keep
is "A60 (B22-B25, G8): the brakes' rows (paused, resumed, installed and uninstalled are there) are each seven fields with - for the pull request" \
   "$(LC_ALL=C awk -F'\t' '{ k[$2] = 1 } NF != 7 || $3 != "-" { b++ } END { printf "%d %d %d %d|%d", ("paused" in k), ("resumed" in k), ("installed" in k), ("uninstalled" in k), b + 0 }' "$L60/brakes.tsv")" \
   "1 1 1 1|0"

# ------------------------------------------------------------------- clean ---
/bin/mv "$L60/gh.prev" "$LGB/gh"; [ -z "$L60PW" ] || /bin/mv "$L60/pgrep.prev" "$LGB/pgrep"; rm -f "$LGB/git"
_lg_reset; rm -rf "$L60"
is "the land fixture: the part leaves the home on main at origin's main with main's entry accepted, gh as the stub was, and no git wrapper (fixture control)" \
   "$(git -C "$LGH" rev-parse --abbrev-ref HEAD 2>&1)|$(git -C "$LGH" rev-parse HEAD 2>&1)|$(_la_accepts)|$(LC_ALL=C grep -c gh-accounts "$LGB/gh" 2>&1)|$([ -e "$LGB/git" ] && echo git)" \
   "main|$(git -C "$LGO" rev-parse main 2>&1)|0|0|"
