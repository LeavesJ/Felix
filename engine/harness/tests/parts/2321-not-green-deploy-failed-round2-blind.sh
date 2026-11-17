# >>> not-green-deploy-failed-round2
printf '\nnot green, deploy failed, round 2: K14 and the clauses the review pinned whole (blind)\n'
# Blind, written on 2026-11-07 from the "(Round 2)" sentences of docs/2026-11-07-not-green-deploy-failed-contract.md
# (K1, K2, K6 to K10) and its K14, against main 0.49.328, which does not hold the change. Part 2320 was read as a
# model of fixtures only. Engine files were read on main alone, for the behaviour the contract says is unchanged
# (felix_verify_current's answers, the quiet check's inputs, the retry record, the alerts readers) and for how to
# call them. K12's control (fifty files, status 0) is the change author's and is not here. An assertion marked [pin],
# [control] or [fixture control] holds on main; the others name the new kinds and are red there. Readings:
# - K1, K2: stale is a commit after a green receipt (the tree changed) or the receipt's recorded epoch and grounded
#   facts rewritten (a fact moved). Where a clause pins the reason and not the name, the line is read under either
#   name. "No gh call" is no line in the gh stub's log while that felix merge runs.
# - K6: the head or main moving is a seeded row that records another head or another main; over an hour is two
#   hours; the matching retry record is the one the tick itself wrote for a receipt refusal.
# - K7: git's first line and the install's last line are those of the same command run here in the same state.
# - K8: one _gt_row of each kind, green-tick.sh and green-install.sh sourced alone, osascript and _fn_event stubbed.
#   deployed-unverified is read as no longer on the list (K12: green-tick.sh no longer holds the name).
# - K10: felix status --tsv's alerts row, felix_land_alert_line (session-start's line) and line 4 of a dispatched body.
# - K14: across the deploy is a previous row recording another main; banners are osascript calls titled
#   Felix: refused #78, attempts alerts.tsv records of kind refused for 78. "Another kind" is read both ways: a
#   refused row of another blocker kind, and a row of another ledger event.
N2D="$TMP/ngd2"; rm -rf "$N2D"; mkdir -p "$N2D/gh/bin" "$N2D/nf/bin" "$N2D/bin"; N2D="$(cd "$N2D" && pwd -P)"
N2G="$N2D/gh"; N2N="$N2D/nf"
N2PRE='the gate reused a suite run for this tree (tests:reused), and the gate workflow has not passed on '
N2NO='no green receipt for this exact tree; run felix gate'
N2CR='(tried again when a new gate or commission receipt is written)'; N2CF='(final until the head or main moves)'
N2CH='(tried again an hour after this row)'
_n2_bl() { printf '  %-11s %-22s %s\n' "$1" "$2" "$3"; }
_n2_n() { printf '%s\n' "$3" | LC_ALL=C awk -F'\t' -v k="$1" -v s="$2" '($1 == k || (k == "*" && ($1 == "not-green" || $1 == "unverified"))) && $2 == s { n++ } END { print n + 0 }'; }   # KIND|* SUBJECT BLOCKERS
_n2_r() { printf '%s\n' "$2" | LC_ALL=C awk -F'\t' -v s="$1" '($1 == "not-green" || $1 == "unverified") && $2 == s { print $3; exit }'; }   # SUBJECT BLOCKERS -> its reason
_n2_in() { case "$1" in *"$2"*) printf '%s' "$3" ;; esac; }     # TEXT PART WORD -> WORD when TEXT holds PART (bash 3.2 parses no case inside $( ))
_n2_pre() { case "$1" in "$2"?*) printf '%s' "$3" ;; esac; }   # TEXT START WORD -> WORD when TEXT begins START and goes on
_n2_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
_n2_ago() { perl -MPOSIX -e 'print strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time - $ARGV[0]))' "$1"; }

# ------------------------------------------------------------- K1, K2: the judge's reasons, pinned whole ---
# A project and checkout of this part's own, as part 2320 builds them. gh is a stub first on PATH that logs every
# call and answers run list from runs.<commit> (count, then status, conclusion, sha), as the lander's stub does.
N2P="$FROOT/projects/ngd2w"; N2R="$N2D/repo"
mkdir -p "${N2P:?}" "${N2R:?}" "$MEM/ngd2w"
cp "$TMP/probes.keep" "$N2P/probes.tsv"; cp "$TMP/obligations.keep" "$N2P/obligations.tsv"
cp "$TMP/commissioning.keep" "$N2P/commissioning.tsv"; cp "$REAL_HARNESS/templates/risk.tsv" "$N2P/risk.tsv"; printf '# ngd2w\n' > "$N2P/CLAUDE.md"
printf '{\n  "name": "ngd2w",\n  "remote_match": "example.invalid/ngd2w",\n  "gate": "true",\n  "gate_workflow": "ngd2-gate.yml"\n}\n' > "$N2P/project.json"
( _fx_cd "${N2R:?}" && git init -q -b main && printf 'ngd2w\n' > .felix && printf 'one\n' > NOTES.txt \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base \
  && git checkout -q -b ngd2-topic && printf 'two\n' >> NOTES.txt \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm change \
  && git remote add origin https://github.com/ngd2-owner/ngd2w.git ) >/dev/null 2>&1
N2R="$(cd "${N2R:?}" && pwd -P)"
cat > "$N2G/bin/gh" <<'N2GH'
#!/bin/bash
d="$(cd "$(dirname "$0")/.." && pwd)"; printf '%s\n' "$*" >> "$d/calls"
c=""; p=""; for a in "$@"; do case "$p" in --commit|-c) c="$a" ;; esac; case "$a" in --commit=*) c="${a#--commit=}" ;; esac; p="$a"; done
case "${1:-} ${2:-}" in
  "auth status") printf 'github.com\n  Logged in to github.com account ngd2-owner\n' ;;
  "repo view") printf 'ngd2-owner/ngd2w\n' ;;
  "run list") if [ -f "$d/runs.$c" ]; then LC_ALL=C awk 'END { print NR }' "$d/runs.$c"; cat "$d/runs.$c"; else echo 0; fi ;;
esac
exit 0
N2GH
chmod +x "$N2G/bin/gh"
_n2_fail() { printf 'completed\tfailure\t%s\n' "$1" > "$N2G/runs.$1"; }   # SHA -> the gate workflow failed on SHA
( cd "${N2R:?}" && FELIX_HOME_DIR="$FROOT"; . "$FROOT/harness/lib/commission.sh"
  _o="$(felix_commission_run "$N2P" "$N2R" -)"; felix_commission_receipt_write "$FROOT" "$N2P" "$N2R" "$_o" "" ) >/dev/null 2>&1
_n2_rcpt() {   # RC CHECKS -> a gate receipt for the checkout's tree, as part 1250 records one
  ( cd "${N2R:?}" && . "$FROOT/harness/lib/verify.sh"
    felix_verify_record "$N2R" "$FROOT" "$1" "gate.sh" "$(felix_tree_id "$N2R" "$FROOT")" "" "$2" ) >/dev/null 2>&1
}
_n2_moved() {   # -> the receipt's recorded epoch and topology component rewritten: a grounded fact it rests on moved
  local f; f="$( . "$FROOT/harness/lib/verify.sh" >/dev/null 2>&1; _felix_receipt_path "$N2R" "$FROOT" )"
  [ -f "$f" ] || return 0
  LC_ALL=C awk -F'\t' -v OFS='\t' '{ $7 = "0000"; n = split($8, c, ","); $8 = c[1]; for (i = 2; i <= n || i == 2; i++) $8 = $8 "," (i == 2 ? "moved" : c[i]); print }' "$f" > "$f.n" \
    && /bin/mv "$f.n" "$f"
}
_n2_blk() {   # -> felix_merge_blockers over the checkout, loaded as the merge boundary loads it (part 1250)
  ( cd "${N2R:?}" && GIT_ALLOW_PROTOCOL=file PATH="$N2G/bin:$PATH" bash -c '
      set -uo pipefail
      for f in resolve verify review classify evidence escape; do . "$1/lib/$f.sh" 2>/dev/null || exit 3; done
      felix_merge_blockers "$2" main "$3" "$4"' _ "$FROOT/harness" "$N2P" "$N2R" "$FROOT" ) 2>/dev/null
}
_n2_cur() {   # -> felix_verify_current's second field for the checkout, asked directly
  ( cd "${N2R:?}" && bash -c 'for f in resolve verify; do . "$1/lib/$f.sh" 2>/dev/null; done; felix_verify_current "$2" "$3" "$4"' \
      _ "$FROOT/harness" "$N2R" "$FROOT" "$N2P" ) 2>/dev/null | LC_ALL=C cut -f2
}
_n2_merge() {   # -> felix merge --base main in the checkout: STATUS:GH-CALLS
  : > "$N2G/calls"
  ( cd "${N2R:?}" && unset FELIX_KERNEL
    GIT_ALLOW_PROTOCOL=file PATH="$N2G/bin:$PATH" CLAUDE_CODE_SESSION_ID=ngd2-sess FELIX_KERNEL_CACHE="$N2D/kcache" \
      "$FELIX" merge --base main ) > "$N2D/m.out" 2>&1
  printf '%s:%s' "$?" "$(LC_ALL=C awk 'END { print NR }' "$N2G/calls")"
}
N2H0="$(git -C "$N2R" rev-parse HEAD 2>/dev/null)"; _n2_fail "$N2H0"
N2B0="$(_n2_blk)"                                                              # no receipt
_n2_rcpt 1 "syntax:ok,tests:ok,secret:ok"; N2B1="$(_n2_blk)"                  # red, for this exact tree
_n2_rcpt 1 "syntax:ok,tests:reused,secret:ok"; N2B1R="$(_n2_blk)"; N2M1R="$(_n2_merge)"
_n2_rcpt 0 "syntax:ok,tests:reused,secret:ok"; N2BG="$(_n2_blk)"; N2MG="$(_n2_merge)"     # current green, reused
_n2_rcpt 0 "syntax:ok,tests:ok,secret:ok"; _n2_moved; N2BF="$(_n2_blk)"; N2CF2="$(_n2_cur)"
_n2_rcpt 0 "syntax:ok,tests:reused,secret:ok"; _n2_moved; N2BFR="$(_n2_blk)"; N2MFR="$(_n2_merge)"
_n2_rcpt 0 "syntax:ok,tests:reused,secret:ok"
( _fx_cd "${N2R:?}" && printf 'three\n' >> NOTES.txt && git add -A && git -c user.name=t -c user.email=t@t commit -qm later ) >/dev/null 2>&1
N2H1="$(git -C "$N2R" rev-parse HEAD 2>/dev/null)"; _n2_fail "$N2H1"
N2BT="$(_n2_blk)"; N2CT="$(_n2_cur)"; N2MT="$(_n2_merge)"                     # stale: the tree moved after it

is "ngd2 A1 (K1) [pin]: with no receipt, and with a red receipt for this exact tree, the tree line's reason is whole: no green receipt for this exact tree; run felix gate" \
   "$(_n2_r tree "$N2B0")|$(_n2_r tree "$N2B1")" "$N2NO|$N2NO"
is "ngd2 A2 (K1) [pin]: stale because the tree changed, the reason is felix_verify_current's second field whole" \
   "$(_n2_r tree "$N2BT")|$N2CT" "the tree changed since the receipt|the tree changed since the receipt"
is "ngd2 A3 (K1) [pin]: stale because a fact it rests on moved, the reason is that second field whole, the text after its ; included" \
   "$(_n2_r tree "$N2BF")|$N2CF2" "the grounded facts moved since the receipt; run felix gate|the grounded facts moved since the receipt; run felix gate"
is "ngd2 A4 (K1): each of the four (none, red, tree changed, fact moved) is a not-green tree line" \
   "$(_n2_n not-green tree "$N2B0")$(_n2_n not-green tree "$N2B1")$(_n2_n not-green tree "$N2BT")$(_n2_n not-green tree "$N2BF")" "1111"
is "ngd2 A5 (K2) [pin]: a red receipt, a fact-moved stale one and a tree-changed stale one, each reporting tests:reused with the gate workflow failed on the head, print one tree line and no tests line" \
   "$(_n2_n '*' tree "$N2B1R")$(_n2_n '*' tests "$N2B1R")|$(_n2_n '*' tree "$N2BFR")$(_n2_n '*' tests "$N2BFR")|$(_n2_n '*' tree "$N2BT")$(_n2_n '*' tests "$N2BT")" "10|10|10"
is "ngd2 A6 (K2) [pin]: and felix merge refuses each with status 3 and makes no gh call" "$N2M1R|$N2MFR|$N2MT" "3:0|3:0|3:0"
is "ngd2 A7 (K2) [control]: a current green receipt reporting tests:reused, the workflow failed on the head, prints the tests line, and felix merge asks gh" \
   "$(_n2_n '*' tests "$N2BG")|${N2MG%%:*}|$([ "${N2MG#*:}" -gt 0 ] 2>/dev/null && echo asked)|$(_n2_r tests "$N2BG" | cut -c1-${#N2PRE})" \
   "1|3|asked|$N2PRE"
is "ngd2 A8 (K2): the one line of the red and the two stale tests:reused receipts is a not-green tree line" \
   "$(_n2_n not-green tree "$N2B1R")$(_n2_n not-green tree "$N2BFR")$(_n2_n not-green tree "$N2BT")" "111"

# ------------------------------------------------------------- K9: the six sentences, word for word ---
_n2_sent() { bash -c '. "$1/lib/notify.sh" >/dev/null 2>&1; _fn_sentence "$2"; printf "|%s" "$?"' _ "$FROOT/harness" "$1" 2>/dev/null; }
is "ngd2 A9 (K9) [pin]: founder's sentence is unchanged" "$(_n2_sent founder)" "A green pull request changes a direction document and waits for your yes.|0"
is "ngd2 A10 (K9) [pin]: deployed's sentence is unchanged" "$(_n2_sent deployed)" "The engine on main was installed and passed its deploy checks.|0"
is "ngd2 A11 (K9) [pin]: stuck's sentence is unchanged" "$(_n2_sent stuck)" "A tick has held the lock for more than 45 minutes.|0"
is "ngd2 A12 (K9) [pin]: timeout's sentence is unchanged" "$(_n2_sent timeout)" "A tick ran past its time limit and was stopped.|0"
is "ngd2 A13 (K9) [pin]: unresolved's sentence is unchanged" "$(_n2_sent unresolved)" "The tick resolved no project, so nothing lands.|0"
is "ngd2 A14 (K9) [pin]: fetch's sentence is unchanged" "$(_n2_sent fetch)" "The home could not fetch its origin, so nothing lands.|0"

# ------------------------------------------------------------- K8: the kinds on _gt_say's list ---
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "${N2SAYD:?}/osa"\nexit 0\n' > "$N2D/bin/osascript"; chmod +x "$N2D/bin/osascript"
_n2_say() {   # KIND... -> KIND=BANNERS/ATTEMPTS for each, after one _gt_row of it
  local k d
  for k in "$@"; do
    d="$N2D/say/$k"; rm -rf "$d"; mkdir -p "$d/land"; : > "$d/osa"; : > "$d/att"
    N2SAYD="$d" PATH="$N2D/bin:$PATH" bash -c '. "$1/lib/green-tick.sh" >/dev/null 2>&1; . "$1/lib/green-install.sh" >/dev/null 2>&1
      _fn_event() { printf "%s\n" "$1" >> "$N2SAYD/att"; }
      _GT_LAND="$N2SAYD/land"; _GT_LEDGER="$_GT_LAND/ledger.tsv"; _GT_QUIET=0; _GT_EVD=""
      _gt_row "$2" - - - 0 "the fixture detail"' _ "$FROOT/harness" "$k" >/dev/null 2>&1
    printf '%s=%s/%s ' "$k" "$(LC_ALL=C awk -v t="with title \"Felix: $k\"" 'index($0, t) { n++ } END { print n + 0 }' "$d/osa")" \
      "$(LC_ALL=C awk -v k="$k" '$0 == k { n++ } END { print n + 0 }' "$d/att")"
  done
}
_n2_pick() { printf '%s' "$1" | tr ' ' '\n' | LC_ALL=C awk -F'[=/]' -v w="$2" 'NF { printf "%s=%s ", $1, $w }'; }   # SAY FIELD(2 banners, 3 attempts)
N2SA="$(_n2_say landed refused founder waiting deployed paused timeout stuck unaged gh fetch deploy-owed unresolved)"
N2SB="$(_n2_say resumed installed uninstalled)"; N2SC="$(_n2_say skip session landing no-such-kind)"
is "ngd2 A15 (K8) [pin]: each kind on _gt_say's list other than the renamed one raises one banner titled Felix: <kind> when a row of it is written" \
   "$(_n2_pick "$N2SA$N2SB" 2)" \
   "landed=1 refused=1 founder=1 waiting=1 deployed=1 paused=1 timeout=1 stuck=1 unaged=1 gh=1 fetch=1 deploy-owed=1 unresolved=1 resumed=1 installed=1 uninstalled=1 "
is "ngd2 A16 (K8) [pin]: resumed, installed and uninstalled start no notifier attempt" "$(_n2_pick "$N2SB" 3)" "resumed=0 installed=0 uninstalled=0 "
is "ngd2 A17 (K8, K11) [pin]: each of the others starts one attempt, as before" "$(_n2_pick "$N2SA" 3)" \
   "landed=1 refused=1 founder=1 waiting=1 deployed=1 paused=1 timeout=1 stuck=1 unaged=1 gh=1 fetch=1 deploy-owed=1 unresolved=1 "
is "ngd2 A18 (K8) [pin]: a kind not on the list (skip, session, landing, no-such-kind) raises neither a banner nor an attempt" \
   "$N2SC" "skip=0/0 session=0/0 landing=0/0 no-such-kind=0/0 "
is "ngd2 A19 (K8): a deploy-failed row raises the banner titled Felix: deploy-failed and starts an attempt" "$(_n2_say deploy-failed)" "deploy-failed=1/1 "
is "ngd2 A20 (K8, K12): the old ledger kind is no longer on the list, so a row of it raises neither" "$(_n2_say deployed-unverified)" "deployed-unverified=0/0 "

# ------------------------------------------------------------- K10: two readers of alerts.tsv, alone ---
cat > "$N2N/bin/gh" <<'N2NF'
#!/bin/bash
d="${N2NF_DIR:?}"; printf '%s\n' "$*" >> "$d/calls"
case "${1:-} ${2:-}" in
  "api --hostname") case " $* " in
      *" user "*) printf 'ngd2-bot\n' ;;
      *" repos/ngd2-owner/ngd2w "*) printf 'ngd2-owner/ngd2w\nngd2-owner\nUser\nfalse\nfalse\ntrue\n' ;;
      *) exit 1 ;; esac ;;
  "issue list") printf '1\n1 ngd2-bot\n' ;;
  "workflow run") pv=""; for a in "$@"; do case "$pv" in -f) case "$a" in body=*) printf '%s' "${a#body=}" > "$d/body" ;; esac ;; esac; pv="$a"; done
    printf 'https://github.com/ngd2-owner/ngd2w/actions/runs/902\n' ;;
  *) exit 1 ;;
esac
exit 0
N2NF
chmod +x "$N2N/bin/gh"
N2AT='2026-11-07T07:00:00Z'
_n2_rec() { printf '%s\t%s\t%s\t-\t-\t-\tgh workflow run: exited 1\tgate: felix gate --quick exited 1 in the home\n' "$N2AT" "$1" "$2"; }   # STATE KIND
_n2_cl() {   # STATE KIND -> line 4 of the body one paused attempt dispatches, alerts.tsv ending in one STATE record of KIND (a failed one first when STATE is dispatched)
  local d="$N2N/$1-$2"; rm -rf "$d"; mkdir -p "$d"
  { [ "$1" != dispatched ] || _n2_rec failed paused; _n2_rec "$1" "$2"; } > "$d/alerts.tsv"
  PATH="$N2N/bin:$PATH" N2NF_DIR="$d" TMPDIR="$d" bash -c '. "$1/lib/notify.sh" >/dev/null 2>&1
    _FN_DIR="$2"; _FN_REPO=ngd2-owner/ngd2w; _FN_LSET=0; _FN_LOGIN=""; _FN_NOTE=""; _FN_SECS=10
    _fn_attempt paused - "the fixture reason"' _ "$FROOT/harness" "$d" >/dev/null 2>&1
  sed -n 4p "$d/body" 2>/dev/null
}
_n2_al() {   # KIND -> felix_land_alert_line over a memory directory whose alerts.tsv holds one no-alert-workflow record of KIND
  local d="$N2D/al/$1"; rm -rf "$d"; mkdir -p "$d/land"; _n2_rec no-alert-workflow "$1" > "$d/land/alerts.tsv"
  bash -c '. "$1/lib/own.sh" >/dev/null 2>&1; felix_land_alert_line "$2"' _ "$FROOT/harness" "$d" 2>/dev/null
}
is "ngd2 A21 (K10) [pin]: the dispatched comment's count line names a failed deployed-unverified record as recorded, as it names a deploy-failed one" \
   "$(_n2_cl failed deployed-unverified)~$(_n2_cl failed deploy-failed)" \
   "Not delivered before this one: 1 (the newest: deployed-unverified at $N2AT).~Not delivered before this one: 1 (the newest: deploy-failed at $N2AT)."
is "ngd2 A22 (K10) [pin]: and a dispatched record of either name after a failed one ends the count, the details line following the sentence" \
   "$(_n2_cl dispatched deployed-unverified)~$(_n2_cl dispatched deploy-failed)" \
   "details: felix land --status on the machine that runs the lander~details: felix land --status on the machine that runs the lander"
N2AO="$(_n2_al deployed-unverified)"; N2AN="$(_n2_al deploy-failed)"
is "ngd2 A23 (K10) [pin]: the session-start alert line names a no-alert-workflow deployed-unverified record as recorded, and is otherwise the deploy-failed one's" \
   "$(_n2_in "$N2AO" "(deployed-unverified at $N2AT) is no-alert-workflow" names)|$([ -n "$N2AN" ] && [ "$(printf '%s' "$N2AO" | sed 's/deployed-unverified/deploy-failed/')" = "$N2AN" ] && echo same)" "names|same"

# ------------------------------------------------------------- the lander, on its own pull request 78 ---
_lg_build amend
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1
N2V="$(_l3_mainv)"; [ -n "$N2V" ] && _lg_cache "$N2V"
rm -rf "${LGH:?}/state"
if [ -d "$LGW/b78" ]; then N2H="$(git -C "$LGW/b78" rev-parse HEAD 2>/dev/null)"; else N2H="$(_lg_branch b78 notes/b78.md)"; fi
[ -n "$(_lg_sha 78)" ] || printf '78\t%s\n' "$N2H" >> "$LG/shas"
N2W="$(cd "$LGW/b78" 2>/dev/null && pwd -P)"; N2MS="$(git -C "$LGH" rev-parse refs/remotes/origin/main 2>/dev/null)"
N2OLD="$(printf '%040d' 0)"; N2HO="$(_lg_sha 21)"
N2RC78="$LGH/state/gate/$(printf '%s' "$N2W" | git hash-object --stdin 2>/dev/null)"
N2RT="${N2PRE}0123abcd: its run concluded failure"
N2LT="not-green|tree|$N2NO"; N2LS="not-green|tests|$N2RT"; N2LE='evidence|notes/b78.md|the change owes a test'
_n2_m() { _lg_logs felix | LC_ALL=C awk -F'\t' -v d="$N2W" '$2 == d && $3 == "merge" { n++ } END { print n + 0 }'; }
_n2_case() {   # RC LINE... -> a fresh land/, logs and state; 78 alone and green; felix merge printing a block of the lines (KIND|SUBJECT|REASON) with status RC
  local rc="$1" l; shift
  _lg_reset; rm -rf "${LGH:?}/state"; _lg_prs "$(_lg_pr 78)"; _lg_green 78
  { printf 'not merging\n\n'; for l in "$@"; do _n2_bl "${l%%|*}" "$(printf '%s' "$l" | cut -d'|' -f2)" "${l##*|}"; done
    printf '\nNothing here escapes the tree.\n'; } > "$LGK/merge.b78.out"
  printf '%s\n' "$rc" > "$LGK/merge.b78.rc"
}
_n2_row() { mkdir -p "$LAND"; printf '%s\t%s\t78\t%s\t%s\t0\t%s\n' "$1" "$2" "$3" "$N2WF" "$4" >> "$LAND/ledger.tsv"; }   # TIME EVENT HEAD DETAIL
_n2_det() { printf '%s %s [main %s]' "$(_n2_bl "$1" "$2" "$3" | tr -d '\n')" "$4" "$5"; }   # KIND SUBJECT REASON CLAUSE MAIN -> a refused row's detail
_n2_q() {   # PREV-EVENT PREV-HEAD PREV-DETAIL RC LINE... -> N2Q: banners|attempts|refused rows, after one tick over that previous row
  local ev="$1" hd="$2" pd="$3"; shift 3
  _n2_case "$@"; _n2_row "$(_n2_now)" "$ev" "$hd" "$pd"; _lg_land --tick
  N2Q="$(_lg_logs osa | LC_ALL=C awk 'index($0, "with title \"Felix: refused #78\"") { n++ } END { print n + 0 }')"
  N2Q="$N2Q|$(if [ -f "$LAND/alerts.tsv" ]; then LC_ALL=C awk -F'\t' '$3 == "refused" && $4 == "78" { n++ } END { print n + 0 }' "$LAND/alerts.tsv"; else echo 0; fi)|$(_lg_n refused 78)"
}
_n2_case 3 "unverified|tree|$N2NO"; _lg_land --tick
N2HF="$(_lg_f refused 78 4)"; N2WF="$(_lg_f refused 78 5)"; N2RTY="$(cat "$LAND/retry.78" 2>/dev/null)"
is "ngd2 A24 (K6, K14) [fixture control]: main's check accepts its entry; an unverified tree refusal of 78 runs felix merge once and writes the refused row this part seeds, and a retry record on its head and main" \
   "$(_la_accepts)|$(_n2_m)|$(_lg_n refused 78)|$([ "$(_lg_f refused 78 7)" = "$(_n2_det unverified tree "$N2NO" "$N2CR" "$N2MS")" ] && echo same-detail)|$N2HF|$N2WF|$(_n2_pre "$N2RTY" "$N2HF $N2MS " record)" \
   "0|1|1|same-detail|$(_lg_sha 78)|$N2W|record"

# ------------------------------------------------------------- K14: a refusal that stands across the deploy ---
_n2_q refused "$N2HF" "$(_n2_det unverified tree "$N2NO" "$N2CR" "$N2OLD")" 3 "$N2LT"
is "ngd2 A25 (K14): a receipt refusal recorded under unverified before the deploy, refused again on the same head as not-green for the same blocker and clause, raises no banner and starts no attempt; its row is still written" \
   "$N2Q" "0|0|2"
_n2_q refused "$N2HF" "$(_n2_det unverified tree "$N2NO" "$N2CF" "$N2OLD")" 3 "$N2LT" "$N2LE"; N2X="$N2Q"
_n2_q refused "$N2HF" "$(_n2_det unverified tests "$N2RT" "$N2CH" "$N2OLD")" 3 "$N2LS"
is "ngd2 A26 (K14): the same holds for a final refusal and for an hourly (tests) one" "$N2X~$N2Q" "0|0|2~0|0|2"
_n2_q refused "$N2HF" "$(_n2_det not-green tree "$N2NO" "$N2CF" "$N2OLD")" 3 "$N2LT" "$N2LE"
is "ngd2 A27 (K14) [pin]: a previous row of the new name, identical but for main, keeps a final refusal quiet as before" "$N2Q" "0|0|2"
_n2_q refused "$N2HF" "$(_n2_det not-green tree "$N2NO" "$N2CR" "$N2OLD")" 3 "$N2LT"; N2X="$N2Q"
_n2_q refused "$N2HF" "$(_n2_det not-green tests "$N2RT" "$N2CH" "$N2OLD")" 3 "$N2LS"
is "ngd2 A28 (K14, K5): and a receipt and an hourly refusal of the new name, identical but for main, stay quiet" "$N2X~$N2Q" "0|0|2~0|0|2"
_n2_q refused "$N2HF" "$(_n2_det unverified tree 'the tree changed since the receipt' "$N2CR" "$N2OLD")" 3 "$N2LT"; N2X="$N2Q"
_n2_q refused "$N2HF" "$(_n2_det not-green tree 'the tree changed since the receipt' "$N2CF" "$N2OLD")" 3 "$N2LT" "$N2LE"
is "ngd2 A29 (K14) [pin]: a refusal whose blocker differs from the previous row's (old name, new name) is announced: one banner, one attempt" "$N2X~$N2Q" "1|1|2~1|1|2"
_n2_q refused "$N2HO" "$(_n2_det unverified tree "$N2NO" "$N2CR" "$N2OLD")" 3 "$N2LT"; N2X="$N2Q"
_n2_q refused "$N2HO" "$(_n2_det not-green tree "$N2NO" "$N2CF" "$N2OLD")" 3 "$N2LT" "$N2LE"
is "ngd2 A30 (K14) [pin]: one whose previous row records another head (old name, new name) is announced" "$N2X~$N2Q" "1|1|2~1|1|2"
_n2_q refused "$N2HF" "$(_n2_det unverified tree "$N2NO" "$N2CF" "$N2OLD")" 3 "$N2LT"; N2X="$N2Q"
_n2_q refused "$N2HF" "$(_n2_det unverified tree "$N2NO" "$N2CH" "$N2OLD")" 3 "$N2LT"; N2X="$N2X~$N2Q"
_n2_q refused "$N2HF" "$(_n2_det unverified tree "$N2NO" "$N2CR" "$N2OLD")" 3 "$N2LT" "$N2LE"; N2X="$N2X~$N2Q"
_n2_q refused "$N2HF" "$(_n2_det not-green tree "$N2NO" "$N2CH" "$N2OLD")" 3 "$N2LT" "$N2LE"
is "ngd2 A31 (K14) [pin]: one whose clause differs (final, hourly before receipt; receipt before final; new name hourly before final) is announced" \
   "$N2X~$N2Q" "1|1|2~1|1|2~1|1|2~1|1|2"
_n2_q refused "$N2HF" "$(_n2_det evidence notes/b78.md 'the change owes a test' "$N2CF" "$N2OLD")" 3 "$N2LE"; N2X="$N2Q"
_n2_q refused "$N2HF" "$(_n2_det probes tree "$N2NO" "$N2CR" "$N2OLD")" 3 "$N2LT"; N2X="$N2X~$N2Q"
_n2_q skip "$N2HF" "$(_n2_det unverified tree "$N2NO" "$N2CR" "$N2OLD")" 3 "$N2LT"; N2X="$N2X~$N2Q"
_n2_q skip "$N2HF" "$(_n2_det not-green tree "$N2NO" "$N2CF" "$N2OLD")" 3 "$N2LT" "$N2LE"
is "ngd2 A32 (K14) [pin]: a previous row of another kind is read as before: an identical evidence refusal stays quiet, a probes one is not read as not-green, and a skip row is no refusal" \
   "$N2X~$N2Q" "0|0|2~1|1|2~1|1|1~1|1|1"
_n2_b8() {   # PREV NEW -> alerts.tsv's records after one refused attempt for 78 with detail NEW, the newest dispatched record holding PREV
  local d="$N2N/b8"; rm -rf "$d"; mkdir -p "$d"
  printf '%s\tdispatched\trefused\t78\tngd2-owner/ngd2w#1\t-\tthrough felix-alert.yml mentioning @ngd2-owner\t%s\n' "$N2AT" "$1" > "$d/alerts.tsv"
  bash -c '. "$1/lib/notify.sh" >/dev/null 2>&1; _FN_DIR="$2"; _FN_REPO=""; _FN_LSET=0; _FN_LOGIN=""; _FN_NOTE="origin: a local path"
    _fn_attempt refused 78 "$3"' _ "$FROOT/harness" "$d" "$2" >/dev/null 2>&1
  LC_ALL=C awk 'END { print NR }' "$d/alerts.tsv"
}
N2OD="$(_n2_bl unverified tree "$N2NO" | tr -d '\n') $N2CR"; N2ND="$(_n2_bl not-green tree "$N2NO" | tr -d '\n') $N2CR"
is "ngd2 A33 (K14, L7) [pin]: the notifier's own check is not widened: a not-green event after a dispatched unverified one is attempted again, the same event is not" \
   "$(_n2_b8 "$N2OD" "$N2ND")|$(_n2_b8 "$N2ND" "$N2ND")" "2|1"

# ------------------------------------------------------------- K6: rows of the old blocker kind, on each clause ---
_n2_k6() {   # CLAUSE KIND -> N2K: felix merge runs (0 held, 1 run again) for that clause's cases, a row of KIND
  local k="$2" a b c
  case "$1" in
    hourly)
      _n2_case 3 "unverified|tests|$N2RT"; _n2_row "$(_n2_now)" refused "$N2HF" "$(_n2_det "$k" tests "$N2RT" "$N2CH" "$N2MS")"; _lg_land --tick; a="$(_n2_m)"
      _n2_case 3 "unverified|tests|$N2RT"; _n2_row "$(_n2_ago 7200)" refused "$N2HF" "$(_n2_det "$k" tests "$N2RT" "$N2CH" "$N2MS")"; _lg_land --tick; N2K="$a$(_n2_m)" ;;
    receipt)
      _n2_case 3 "unverified|tree|$N2NO"; _n2_row "$(_n2_now)" refused "$N2HF" "$(_n2_det "$k" tree "$N2NO" "$N2CR" "$N2MS")"
      printf '%s\n' "$N2RTY" > "$LAND/retry.78"; _lg_land --tick; a="$(_n2_m)"
      mkdir -p "$(dirname "$N2RC78")"; printf 'receipt 1\n' > "$N2RC78"; _lg_land --tick; N2K="$a$(_n2_m)" ;;
    final)
      _n2_case 3 "unverified|tree|$N2NO"; _n2_row "$(_n2_now)" refused "$N2HF" "$(_n2_det "$k" tree "$N2NO" "$N2CF" "$N2MS")"; _lg_land --tick; a="$(_n2_m)"
      _n2_case 3 "unverified|tree|$N2NO"; _n2_row "$(_n2_now)" refused "$N2HO" "$(_n2_det "$k" tree "$N2NO" "$N2CF" "$N2MS")"; _lg_land --tick; b="$(_n2_m)"
      _n2_case 3 "unverified|tree|$N2NO"; _n2_row "$(_n2_now)" refused "$N2HF" "$(_n2_det "$k" tree "$N2NO" "$N2CF" "$N2OLD")"; _lg_land --tick; N2K="$a$b$(_n2_m)" ;;
  esac
}
_n2_k6 hourly unverified; N2X="$N2K"; _n2_k6 hourly not-green
is "ngd2 A34 (K6) [pin]: an hourly row under an hour old is held and one two hours old is run again, whether its detail begins unverified or not-green" "$N2X|$N2K" "01|01"
_n2_k6 receipt unverified; N2X="$N2K"; _n2_k6 receipt not-green
is "ngd2 A35 (K6) [pin]: a receipt row whose retry record matches is held, and is run again once a gate receipt is written, under either name" "$N2X|$N2K" "01|01"
_n2_k6 final unverified; N2X="$N2K"; _n2_k6 final not-green
is "ngd2 A36 (K6) [pin]: a final row is held on its head and main, and run again once the head or main differs, under either name" "$N2X|$N2K" "011|011"

# ------------------------------------------------------------- K10: felix status's alerts row ---
_n2_st() {   # STATE KIND -> felix status --tsv's alerts row from the home, alerts.tsv holding one STATE record of KIND
  _lg_reset; mkdir -p "$LAND"; _n2_rec "$1" "$2" > "$LAND/alerts.tsv"
  ( cd "$LGH" && exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE HOME="$LGU" FELIX_HOME="$LGH" FELIX_HOME_DIR="$LGH" \
      FELIX_MEMORY="$LGM" FELIX_PLUGIN_CACHE="$LGC" PATH="$LGB:$PATH" "$FELIX" status --tsv ) 2>/dev/null | LC_ALL=C awk -F'\t' '$1 == "alerts"'
}
N2SO="$(_n2_st failed deployed-unverified)"; N2SN="$(_n2_st failed deploy-failed)"
N2SDO="$(_n2_st dispatched deployed-unverified)"; N2SDN="$(_n2_st dispatched deploy-failed)"
is "ngd2 A37 (K10) [pin]: felix status's alerts row names a failed or dispatched deployed-unverified record as recorded, and is otherwise the deploy-failed one's" \
   "$(_n2_in "$N2SO" "$N2AT deployed-unverified " names)$(_n2_in "$N2SDO" "$N2AT deployed-unverified" names)|$([ -n "$N2SN" ] && [ "$(printf '%s' "$N2SO" | sed 's/deployed-unverified/deploy-failed/')" = "$N2SN" ] && echo same)|$([ -n "$N2SDN" ] && [ "$(printf '%s' "$N2SDO" | sed 's/deployed-unverified/deploy-failed/')" = "$N2SDN" ] && echo same)" \
   "namesnames|same|same"

# ------------------------------------------------------------- K7: the failing step's message, whole ---
_n2_owe() { _lg_reset; rm -rf "${LGV:?}/${N2V:-none}"; }   # a fresh land/ and logs, main's entry gone: the tick owes a deploy
_n2_dd() { [ -f "$LAND/ledger.tsv" ] && LC_ALL=C awk -F'\t' '$2 == "deploy-failed" || $2 == "deployed-unverified" { v = $7 } END { printf "%s", v }' "$LAND/ledger.tsv"; }
_n2_owe; _fx_git "$LGH" branch -q --unset-upstream main >/dev/null 2>&1
N2PL="$(_fx_git "$LGH" pull -q --ff-only 2>&1 </dev/null | LC_ALL=C sed -n 1p)"; _lg_land --tick; N2DP="$(_n2_dd)"
_fx_git "$LGH" branch -q --set-upstream-to=origin/main main >/dev/null 2>&1
is "ngd2 A38 (K7) [pin]: a failed pull's detail is pull: git pull --ff-only failed: and git's first line, whole" \
   "$([ -n "$N2PL" ] && echo said)|$N2DP" "said|pull: git pull --ff-only failed: $N2PL"
_unwritable_probe; _n2_owe
if [ "${_unwritable:-0}" = 1 ]; then
  chmod 555 "$LGV"; _lg_land --tick; N2DI="$(_n2_dd)"
  N2IO="$( cd "$LGH" && "$LGH/engine/harness/felix" install --no-bump 2>&1 </dev/null )"; chmod 755 "$LGV"
  N2IL="$(printf '%s\n' "$N2IO" | LC_ALL=C tail -1)"
  is "ngd2 A39 (K7) [fixture control]: with the cache unwritable the install prints two lines or more, its last not its first" \
     "$([ "$(printf '%s\n' "$N2IO" | LC_ALL=C awk 'END { print NR }')" -ge 2 ] && [ "$N2IL" != "$(printf '%s\n' "$N2IO" | LC_ALL=C sed -n 1p)" ] && echo several)" "several"
  is "ngd2 A40 (K7) [pin]: a failed install's detail is install: felix install --no-bump failed: and the install's last line, whole" \
     "$N2DI" "install: felix install --no-bump failed: $N2IL"
else skip "ngd2 A39 (K7) [fixture control]: with the cache unwritable the install prints two lines or more, its last not its first" "$_nowrite"
  skip "ngd2 A40 (K7) [pin]: a failed install's detail is install: felix install --no-bump failed: and the install's last line, whole" "$_nowrite"; fi
_n2_owe; printf '5\n' > "$LGK/gate.rc"; _lg_land --tick
is "ngd2 A41 (K7) [pin]: a failed felix gate --quick's detail is gate: felix gate --quick exited <rc> in the home, its own status" \
   "$(_n2_dd)" "gate: felix gate --quick exited 5 in the home"

_lg_reset; rm -rf "${LGH:?}/state"; [ -n "$N2V" ] && _lg_cache "$N2V"
_fx_git "$LGH" worktree remove --force "$LGW/b78" >/dev/null 2>&1; _fx_git "$LGH" branch -q -D b78 >/dev/null 2>&1
LC_ALL=C awk -F'\t' '$1 != "78"' "$LG/shas" > "$N2D/shas" && /bin/mv "$N2D/shas" "$LG/shas"
is "ngd2 A42 (K7) [fixture control]: the part leaves the home on main at origin's main, tracking it, with no tracked change, main's check accepting its entry, and b78 gone" \
   "$(git -C "$LGH" rev-parse --abbrev-ref HEAD 2>&1)|$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" rev-parse --abbrev-ref 'main@{upstream}' 2>&1)|$(git -C "$LGH" status --porcelain --untracked-files=no 2>&1)|$(_la_accepts)|$([ -d "$LGW/b78" ] || [ -n "$(_lg_sha 78)" ] || echo gone)" \
   "main|$(git -C "$LGO" rev-parse main 2>&1)|origin/main||0|gone"
rm -rf "${N2D:?}" "${N2P:?}" "${MEM:?}/ngd2w"
