# >>> land-tick-review-round
printf '\nthe land tick, review round: a GitHub refusal is hourly, a brake that cannot act says so, a wrong entry names its way out, the verify sees a hook fail open (audit b02, B28-B31, A61-A84, blind)\n'
# Blind, written on 2026-10-26 from section 9 of docs/2026-10-24-audit-fixes/b02-land-tick-never-refuses-or-waits-silentl.md
# and the review's four items (M1-M4), on the fixtures of tests/lib/land-on-green.sh (parts 1280-1289, 1650, 1660) and
# tests/lib/judge-refs.sh (parts 1400, 1401). lib/green-tick.sh, lib/green-install.sh, lib/escape.sh, the felix CLI, the
# hooks, projects/felix/gate.sh and every other engine file were not read; the C9 blocker's words are the review's.
#
# B28: pull request 65 on worktree b65, built as 1650 builds 50 on b50, its gate receipt (RC65) at the path the
# contract derives from b65's physical path. felix merge answers with OUT-S (status 3, one `not-green tests` line as
# C9 prints it when gh run list fails), OUT-S2 (an `not-green tree` line before it), OUT-S3 (an `evidence` line after
# it) or OUT-R (`not-green tree` alone), laid out as cmd_merge's '  %-11s %-22s %s'. M65 counts felix.log rows that
# ran `merge` in b65. Rows are aged only as part 1280's _lg_age ages them, the year moved back by one.
# B29: land/ at mode 555 with ledger.tsv in it, which a line can still be appended to; skipped where a mode refuses no
# write (tests/lib/unwritable.sh). Those two commands are ended by SIGALRM after 60 s, so a brake that spins on the
# unwritable directory fails its assertion as hung instead of hanging the suite.
# B30: the land fixture's A50 and A52 states, then 1401's checkout JS (felix merge --dry-run) and gate fixture JG
# (projects/felix/gate.sh --quick), each with main's entry plus commands/extra.md. An entry is named by any spelling
# of its path: as given, physical, or through HOME's link to the cache.
# B31: the home's main gains, committed and pushed, a session-start that logs to log/hook.log as the fixture's stub
# does and prints one JSON line unless ctl/ss.silent exists, and a pre-tool that logs its directory, working
# directory and payload to log/pretool.log and exits 2 on a payload naming killall or pkill unless ctl/pt.open
# exists. Before each tick main's entry is removed, so the tick owes and runs a deploy. The hooks as they were are
# committed back at the end. Where the contract leaves the words open, nothing is asserted of them.
_lg_build amend
L65="$LG/round65"; rm -rf "$L65"; mkdir -p "$L65"; : > "$L65/all.tsv"
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1
L65VM="$(_l3_mainv)"; [ -n "$L65VM" ] && _lg_cache "$L65VM"
rm -rf "${LGH:?}/state"
if [ -d "$LGW/b65" ]; then L65H="$(git -C "$LGW/b65" rev-parse HEAD 2>/dev/null)"; else L65H="$(_lg_branch b65 notes/b65.md)"; fi
[ -n "$(_lg_sha 65)" ] || printf '65\t%s\n' "$L65H" >> "$LG/shas"
L65W="$(cd "$LGW/b65" 2>/dev/null && pwd -P)"
L65RC="$LGH/state/gate/$(printf '%s' "$L65W" | git hash-object --stdin 2>/dev/null)"
L65CC="$LGH/state/commission/lgh"; L65N=0; L65HK="$LGH/engine/harness/hooks"
L65T="the gate reused a suite run for this tree (tests:reused), and the gate workflow has not passed on $(printf '%s' "$L65H" | cut -c1-8): GitHub could not be asked (gh run list failed with status 1)"
L65CR='(tried again when a new gate or commission receipt is written)'
L65CF='(final until the head or main moves)'
L65CH='(tried again an hour after this row)'

_l65_has() { case "$1" in *"$2"*) printf yes ;; *) printf no ;; esac; }
_l65_lacks() { case "$1" in *"$2"*) printf no ;; *) printf yes ;; esac; }
_l65_begins() { case "$1" in "$2"*) printf yes ;; *) printf no ;; esac; }
_l65_names() {   # TEXT PATH... -> yes when TEXT holds one of the paths
  local t="$1" p; shift
  for p in "$@"; do [ -n "$p" ] || continue; case "$t" in *"$p"*) printf yes; return 0 ;; esac; done
  printf no
}
_l65_phys() { ( cd "$(dirname "$1")" 2>/dev/null && printf '%s/%s' "$(pwd -P)" "$(basename "$1")" ); }
_l65_entry() { _l65_names "$1" "$LGV/$2" "$LGU/.claude/plugins/cache/felix/felix/$2"; }   # DETAIL VERSION
_l65_same() {   # PAUSED DETAIL -> yes when both are there and one holds the other
  if [ -n "$1" ] && [ -n "$2" ]; then
    case "$2" in *"$1"*) printf yes; return 0 ;; esac
    case "$1" in *"$2"*) printf yes; return 0 ;; esac
  fi
  printf no
}
_l65_osa() { _lg_logs osa | LC_ALL=C awk -v t="with title \"$1\"" 'index($0, t) { n++ } END { print n + 0 }'; }
_l65_age() {   # every ledger row's year moved back by one, as part 1280's _lg_age does
  [ -f "$LAND/ledger.tsv" ] || return 0
  LC_ALL=C awk -F'\t' -v OFS='\t' -v y="$(date -u +%Y)" '{ if (index($1, y)) sub(y, y - 1, $1); print }' \
    "$LAND/ledger.tsv" > "$LAND/ledger.aged" && /bin/mv "$LAND/ledger.aged" "$LAND/ledger.tsv"
}
_l65_keep() { [ -f "$LAND/ledger.tsv" ] && cat "$LAND/ledger.tsv" >> "$L65/all.tsv"; return 0; }
_l65_reset() { [ ! -d "$LAND" ] || chmod 755 "$LAND" 2>/dev/null; _l65_keep; _lg_reset; }
_l65_m() { _lg_logs felix | LC_ALL=C awk -F'\t' -v d="$L65W" '$2 == d && $3 == "merge" { n++ } END { print n + 0 }'; }
_l65_rw() { L65N=$((L65N + 1)); mkdir -p "$(dirname "$1")"; printf 'receipt %s\n' "$L65N" > "$1"; }
_l65_bl() { printf '  %-11s %-22s %s\n' "$1" "$2" "$3"; }
_l65_out() {   # NAME -> felix merge's output NAME (L: a landing's)
  case "$1" in
    L)  printf 'merged\n' ;;
    S)  printf 'not merging\n\n'; _l65_bl not-green tests "$L65T"; printf '\nNothing here escapes the tree.\n' ;;
    S2) printf 'not merging\n\n'; _l65_bl not-green tree 'the tree changed since the receipt'
        _l65_bl not-green tests "$L65T"; printf '\nNothing here escapes the tree.\n' ;;
    S3) printf 'not merging\n\n'; _l65_bl not-green tests "$L65T"
        _l65_bl evidence notes/b65.md 'the change owes a test'; printf '\nNothing here escapes the tree.\n' ;;
    R)  printf 'not merging\n\n'; _l65_bl not-green tree 'the tree changed since the receipt'
        printf '\nNothing here escapes the tree.\n' ;;
  esac
}
_l65_case() {   # OUT STATUS -> a fresh land/ and logs, no receipt, 65 alone and green, felix merge answering OUT with STATUS
  _l65_reset; rm -f "$L65RC" "$L65CC"; _lg_prs "$(_lg_pr 65)"; _lg_green 65
  _l65_out "$1" > "$LGK/merge.b65.out"; printf '%s\n' "$2" > "$LGK/merge.b65.rc"
}
_l65_land() {   # SECONDS ARGS -> felix land ARGS as _lg_land runs it, ended by SIGALRM after SECONDS; output in $LG/out, status in LGRC
  local s="$1"; shift
  ( cd "$LGH" || exit 97
    exec perl -e 'alarm shift @ARGV; exec @ARGV or exit 127' "$s" env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE \
      ${LGX[@]+"${LGX[@]}"} HOME="$LGU" FELIX_HOME="$LGH" FELIX_HOME_DIR="$LGH" FELIX_MEMORY="$LGM" FELIX_PLUGIN_CACHE="$LGC" \
      PATH="$LGB:$PATH" "$FELIX" land "$@" ) > "$LG/out" 2>&1
  LGRC=$?
}
_l65_failed() {   # STATUS -> failed for a refusal, hung for SIGALRM's 142, exit 0 for a success
  if [ "$1" -eq 142 ]; then printf 'hung for 60 s'; elif [ "$1" -ne 0 ]; then printf failed; else printf 'exit 0'; fi
}
_l65_is() {   # NAME GOT WANT TEXT -> is, with the TEXT judged (its first 600 bytes) in a failure's detail
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2] in: $(printf '%s' "$4" | tr '\n' ' ' | cut -c1-600)"; fi
}

# ------------------------------------------------------- the fixture, checked ---
is "the land fixture (review round): the home is on main at origin's main, main's check accepts its entry, b65 is on its branch at 65's head, RC65 is under the home's state/gate (fixture control)" \
   "$(git -C "$LGH" rev-parse HEAD 2>&1)|$(_la_accepts)|$(git -C "$LGW/b65" symbolic-ref HEAD 2>&1)|$(git -C "$LGW/b65" rev-parse HEAD 2>&1)|$(_l65_has "$L65RC" "$LGH/state/gate/")" \
   "$(git -C "$LGO" rev-parse main 2>&1)|0|refs/heads/b65|$(_lg_sha 65)|yes"
_l65_case L 0; _lg_land --tick
is "the land fixture (review round): green 65 lands on one tick when felix merge exits 0, run once in b65, which M65 counts (fixture control)" \
   "$LGRC|$(_lg_n landed 65)|$(_l65_m)" "0|1|1"

# ------------------------------------------- B28 (M1): GitHub's answer is hourly ---
_l65_case S 3; _l65_rw "$L65RC"; _lg_land --tick; L65D="$(_lg_f refused 65 7)"
is "A61 (B28): a refusal whose one blocker is not-green tests (C9: gh run list failed) writes one refused row for 65 saying it is tried again an hour after this row, not when a receipt is written" \
   "$(_lg_n refused 65)|$(_l65_has "$L65D" "$L65CH")|$(_l65_lacks "$L65D" "$L65CR")" "1|yes|yes"
_lg_land --tick; _lg_land --tick
is "A62 (B28) [control]: with b65's current gate receipt untouched, two more ticks inside the hour do not run felix merge again: M65 is 1, one refused row" \
   "$(_l65_m)|$(_lg_n refused 65)" "1|1"
_l65_out L > "$LGK/merge.b65.out"; printf '0\n' > "$LGK/merge.b65.rc"; _l65_age; _lg_land --tick
is "A63 (B28, B5, B7): once that row is an hour old, with no receipt rewritten and GitHub answering again, the next tick runs felix merge once more and lands 65: M65 is 2, one landed row, one Felix: landed #65" \
   "$(_l65_m)|$(_lg_n landed 65)|$(_l65_osa 'Felix: landed #65')" "2|1|1"
_l65_case S2 3; _lg_land --tick; L65D="$(_lg_f refused 65 7)"
is "A64 (B28): not-green tree followed by not-green tests is hourly too: the row says tried again an hour after this row, not when a receipt is written" \
   "$(_l65_has "$L65D" "$L65CH")|$(_l65_lacks "$L65D" "$L65CR")" "yes|yes"
_l65_case S3 3; _lg_land --tick
is "A65 (B28) [control]: not-green tests beside an evidence blocker is final: the row says final until the head or main moves" \
   "$(_l65_has "$(_lg_f refused 65 7)" "$L65CF")" "yes"
_l65_case R 3; _lg_land --tick
is "A66 (B28) [control]: not-green tree alone stays a receipt refusal: the row says tried again when a new gate or commission receipt is written" \
   "$(_l65_has "$(_lg_f refused 65 7)" "$L65CR")" "yes"
rm -rf "${LGH:?}/state"

# ------------------------------------- B29 (M2): a brake that cannot act says so ---
_l65_brake() {   # [PAUSED] -> a fresh land/ holding an empty ledger.tsv (and paused holding PAUSED), then land/ at mode 555
  _l65_reset; mkdir -p "$LAND"; : > "$LAND/ledger.tsv"; [ -z "${1:-}" ] || printf '%s\n' "$1" > "$LAND/paused"; chmod 555 "$LAND"
}
_unwritable_probe
if [ "${_unwritable:-0}" = 1 ]; then
  _l65_brake 'hold until I read #460'
  L65A="$( ( : > "$LAND/l65-probe" ) 2>/dev/null && echo created || echo refused)|$( ( : >> "$LAND/ledger.tsv" ) 2>/dev/null && echo appendable || echo refused)"
  LGX=(CLAUDE_CODE_SESSION_ID=s-1665); _l65_land 60 --resume; LGX=(); L65B="$LGRC"
  L65P="$([ -e "$LAND/paused" ] && echo paused)"; chmod 755 "$LAND"
  is "the land fixture (review round): land/ at mode 555 refuses a new file and still takes a line on ledger.tsv (fixture control)" "$L65A" "refused|appendable"
  is "A67 (B29): when land/paused cannot be removed, --resume exits non-zero, says why, leaves the job paused, and writes no resumed row and no Felix: resumed notification" \
     "$(_l65_failed "$L65B")|$([ -s "$LG/out" ] && echo said)|$L65P|$(_lg_n resumed)|$(_l65_osa 'Felix: resumed')" "failed|said|paused|0|0"
  _l65_brake; LGX=(CLAUDE_CODE_SESSION_ID=s-1665); _l65_land 60 --pause "hold until I read #460"; LGX=(); L65B="$LGRC"
  L65P="$([ -e "$LAND/paused" ] && echo paused)"; chmod 755 "$LAND"
  is "A68 (B29): when land/paused cannot be written, --pause exits non-zero, says why, leaves no pause, and writes no paused row and no Felix: paused notification" \
     "$(_l65_failed "$L65B")|$([ -s "$LG/out" ] && echo said)|$L65P|$(_lg_n paused)|$(_l65_osa 'Felix: paused')" "failed|said||0|0"
else
  skip "the land fixture (review round): land/ at mode 555 refuses a new file and still takes a line on ledger.tsv (fixture control)" "$_nowrite"
  skip "A67 (B29): when land/paused cannot be removed, --resume exits non-zero, says why, leaves the job paused, and writes no resumed row and no Felix: resumed notification" "$_nowrite"
  skip "A68 (B29): when land/paused cannot be written, --pause exits non-zero, says why, leaves no pause, and writes no paused row and no Felix: paused notification" "$_nowrite"
fi
_l65_reset; mkdir -p "$LAND"; printf 'hold until I read #460\n' > "$LAND/paused"
LGX=(CLAUDE_CODE_SESSION_ID=s-1665); _lg_land --resume; LGX=()
is "A69 (B29) [control]: with land/ writable, --resume over a pause exits 0, removes it and writes one resumed row" \
   "$LGRC|$([ -e "$LAND/paused" ] && echo paused)|$(_lg_n resumed)" "0||1"

# ------------------------------------------ B30 (M3): the way out is printed ---
_l65_reset; _lg_cache "$L65VM"; printf 'extra\n' > "$LGV/$L65VM/harness/l65-extra.txt"
L65A="$(_la_accepts)"; : > "$LGK/install.taint"; _lg_land --tick
L65D="$(_lg_f deploy-failed "" 7)"; L65P="$(cat "$LAND/paused" 2>/dev/null)"
is "A70 (B30, B20) [control]: main's entry plus one file, the install tainted: main's check rejects the entry, and one deploy-failed row begins diff:, names the entry, and paused holds it" \
   "$L65A|$(_lg_n deploy-failed)|$(_l65_begins "$L65D" 'diff:')|$(_l65_entry "$L65D" "$L65VM")|$(_l65_same "$L65P" "$L65D")" "1|1|yes|yes|yes"
_l65_is "A71 (B30): that row names the way out: move the entry aside, then felix install --no-bump" \
   "$(_l65_has "$L65D" aside)|$(_l65_has "$L65D" 'felix install --no-bump')" "yes|yes" "$L65D"
_l65_reset; _lg_cache "$L65VM"; _lg_land --install; _l65_reset
printf 'extra\n' > "$LGV/$L65VM/harness/l65-extra.txt"; _la_tramp; L65D="$(_lg_f deploy-owed "" 7)"
is "A72 (B30, B21) [control]: the trampoline, main's entry holding one extra file: one deploy-owed row saying differs and does not replace, naming the entry" \
   "$(_lg_n deploy-owed)|$(_l65_has "$L65D" differs)|$(_l65_has "$L65D" 'does not replace')|$(_l65_entry "$L65D" "$L65VM")" "1|yes|yes|yes"
_l65_is "A73 (B30): that row names the way out, aside and felix install --no-bump, and holds no semicolon-space" \
   "$(_l65_has "$L65D" aside)|$(_l65_has "$L65D" 'felix install --no-bump')|$(_l65_lacks "$L65D" '; ')" "yes|yes|yes" "$L65D"
rm -f "$LGV/$L65VM/harness/l65-extra.txt"; _l65_reset

_jr_project; _js_build; _js_entry; _jg_build; [ "$JG_ON" = 1 ] && _jg_entry
printf 'not main\n' > "$JSK/1.0.0/commands/extra.md"; _js_dry
_js_refused "A74 (B30) [control]: felix merge --dry-run, the entry for main's 1.0.0 holding commands/extra.md, refuses: the judge is not the engine main accepted"
L65O="$(tr '\n' ' ' < "$JS/out" 2>/dev/null)"
_l65_is "A75 (B30): and it names that entry and the way out, aside and felix install --no-bump, and no longer says felix install on main, in any case" \
   "$(_l65_names "$L65O" "$JSK/1.0.0" "$(_l65_phys "$JSK/1.0.0")")|$(_l65_has "$L65O" aside)|$(_l65_has "$L65O" 'felix install --no-bump')|$(_l65_lacks "$(_lg_lc "$L65O")" 'felix install on main')" \
   "yes|yes|yes|yes" "$L65O"
if [ "$JG_ON" = 1 ]; then
  printf 'not main\n' > "$JGC/0.0.1/commands/extra.md"; L65A="$(_jg_inst)"; L65O="$(tr '\n' ' ' < "$JG/out" 2>/dev/null)"
  is "A76 (B30) [control]: gate.sh --quick, the entry for main's 0.0.1 holding commands/extra.md: installed fails" "$L65A" "FAIL|0"
  _l65_is "A77 (B30): and the gate names that entry and the way out, aside and felix install --no-bump, and no longer says felix install on main, in any case" \
     "$(_l65_names "$L65O" "$JGC/0.0.1" "$(_l65_phys "$JGC/0.0.1")")|$(_l65_has "$L65O" aside)|$(_l65_has "$L65O" 'felix install --no-bump')|$(_l65_lacks "$(_lg_lc "$L65O")" 'felix install on main')" \
     "yes|yes|yes|yes" "$(awk '/^  installed/ { on = 1 } on' "$JG/out" 2>/dev/null | head -6)"
else
  skip "A76 (B30) [control]: gate.sh --quick, the entry for main's 0.0.1 holding commands/extra.md: installed fails" "no projects/felix/gate.sh with a tests marker beside this harness"
  skip "A77 (B30): and the gate names that entry and the way out, aside and felix install --no-bump, and no longer says felix install on main, in any case" "no projects/felix/gate.sh with a tests marker beside this harness"
fi
rm -rf "$FROOT/projects/jrr" "$MEM/jrr" "$JS" "$JG"

# ---------------------------------- B31 (M4): the verify sees a hook fail open ---
rm -rf "$L65/hooks.orig"; cp -R "$L65HK" "$L65/hooks.orig"
_lg_put "$L65HK/session-start" <<'L65SS'
#!/bin/bash
LG='@LG@'
p="$(cat)"
printf '%s\t%s\t%s\n' "$(cd -P "$(dirname "$0")" && pwd -P)" "$(pwd -P)" "$(printf '%s' "$p" | tr '\n' ' ')" >> "$LG/log/hook.log"
[ -f "$LG/ctl/ss.silent" ] || printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Felix governs lgh."}}\n'
rc=0; [ -f "$LG/ctl/hook.rc" ] && rc="$(cat "$LG/ctl/hook.rc")"; exit "$rc"
L65SS
_lg_put "$L65HK/pre-tool" <<'L65PT'
#!/bin/bash
LG='@LG@'
p="$(cat)"
printf '%s\t%s\t%s\n' "$(cd -P "$(dirname "$0")" && pwd -P)" "$(pwd -P)" "$(printf '%s' "$p" | tr '\n' ' ')" >> "$LG/log/pretool.log"
[ -f "$LG/ctl/pt.open" ] && exit 0
case "$p" in *killall*|*pkill*) echo "a pattern kill: stop only a pid you started" >&2; exit 2 ;; esac
exit 0
L65PT
_l65_commit() {   # MSG -> the home's hooks committed as they stand and pushed: origin/main moves, the home stays at it
  _fx_git "$LGH" add -A engine/harness/hooks >/dev/null 2>&1
  _fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qm "$1" >/dev/null 2>&1; _fx_git "$LGH" push -q origin main >/dev/null 2>&1
}
_l65_deploy() {   # [CTL...] -> a fresh land/ and logs, main's entry gone, the named ctl files made, one tick
  local f; _l65_reset; rm -rf "${LGV:?}/$L65VM"; for f in "$@"; do : > "$LGK/$f"; done; _lg_land --tick
}
_l65_commit 'l65: hooks that can fail open'
is "the land fixture (review round): the home's main carries the round's session-start and pre-tool, both executable, and the home is at origin's main with no tracked change (fixture control)" \
   "$(git -C "$LGH" ls-files -s engine/harness/hooks/pre-tool engine/harness/hooks/session-start 2>&1 | awk '{ printf "%s ", $1 }')|$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" status --porcelain --untracked-files=no 2>&1)" \
   "100755 100755 |$(git -C "$LGO" rev-parse main 2>&1)|"
_l65_deploy; L65D="$(_lg_f deployed "" 7)"
is "A78 (B31) [control]: a deploy whose session-start prints a line and whose pre-tool refuses a pattern kill is deployed: one deployed row, no deploy-failed row, no pause" \
   "$LGRC|$(_lg_n deployed)|$(( $(_lg_n deploy-failed) + $(_lg_n deployed-unverified) ))|$([ -e "$LAND/paused" ] && echo paused)" "0|1|0|"
L65A="$(_lg_logs pretool | LC_ALL=C awk -F'\t' -v h="$LGH" '($2 == h || index($3, h)) && index($3, "Bash") && index($3, "killall felix-verify-probe") { n++ } END { print n + 0 }')"
is "A79 (B31): that verify ran pre-tool on a Bash payload of killall felix-verify-probe, the home its working directory or the payload's" \
   "$([ "$L65A" -ge 1 ] && echo ran)" "ran"
is "A80 (B31): the deployed row names pre-tool beside session-start" "$(_l65_has "$L65D" pre-tool)|$(_l65_has "$L65D" session-start)" "yes|yes"
_l65_unv() {   # ITEM WHAT HOOK -> one deploy-failed row naming HOOK, no deployed row, paused the same
  local d; d="$(_lg_f deploy-failed "" 7)"
  is "$1 (B31): $2 is deploy-failed naming $3: one such row, no deployed row, and paused holds the same reason" \
     "$(_lg_n deploy-failed)|$(_lg_n deployed)|$(_l65_has "$(_lg_lc "$d")" "$3")|$(_l65_same "$(cat "$LAND/paused" 2>/dev/null)" "$d")" "1|0|yes|yes"
}
_l65_deploy ss.silent; _l65_unv A81 "a session-start that exits 0 and prints nothing" session-start
_l65_deploy pt.open; _l65_unv A82 "a pre-tool that exits 0 on a pattern kill" pre-tool
_fx_git "$LGH" rm -q engine/harness/hooks/pre-tool >/dev/null 2>&1; _l65_commit 'l65: no pre-tool'
_l65_deploy; _l65_unv A83 "a main whose engine holds no pre-tool" pre-tool
rm -rf "$L65HK"; cp -R "$L65/hooks.orig" "$L65HK"; _l65_commit 'l65: the hooks as they were'
L65A="$(diff -r "$L65/hooks.orig" "$L65HK" >/dev/null 2>&1 && echo same)"
_l65_reset; _lg_cache "$L65VM"

# ------------------------------------------------------------------ G8 ---
L65B="$(LC_ALL=C awk -F'\t' 'NF != 7 { b++ } END { printf "%d %d", NR, b + 0 }' "$L65/all.tsv")"
case "$L65B" in "0 "*|*" "[123456789]*) bad "A84 (G8) [control]: every row this part's commands wrote is one row of seven tab-separated fields" "rows, then rows of another shape: $L65B" ;;
  *) ok "A84 (G8) [control]: every row this part's commands wrote is one row of seven tab-separated fields" ;; esac

_lg_reset; rm -rf "${LGH:?}/state" "$L65"
is "the land fixture (review round): the part leaves the home on main at origin's main, no tracked change, its hooks as they were, and main's check accepting its entry (fixture control)" \
   "$(git -C "$LGH" rev-parse --abbrev-ref HEAD 2>&1)|$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" status --porcelain --untracked-files=no 2>&1)|$L65A|$(_la_accepts)" \
   "main|$(git -C "$LGO" rev-parse main 2>&1)||same|0"
