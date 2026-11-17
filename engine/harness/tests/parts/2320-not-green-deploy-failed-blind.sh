# >>> not-green-deploy-failed
printf '\nnot green, deploy failed: the two kinds that kept their names (K1-K12, blind)\n'
# Blind, written on 2026-11-07 from docs/2026-11-07-not-green-deploy-failed-contract.md alone (K1-K13, L1-L5), and
# from clause C18 of docs/2026-10-31-checked-not-verified-contract.md for K12's check, before the change and red
# against main. Engine files were read only as far as calling them needs: function names, arguments, the files they
# read and write. Parts 0100, 0360, 0990, 1250, 1281, 1282, 1650, 1665, 1720, 1288 and 1360, and tests/lib/merge.sh,
# land-on-green.sh and unwritable.sh, were read for their fixtures and stubs alone. Parts 2300 and 2301,
# assertions.tsv and red.tsv were not read.
#
# Readings, the narrowest the contract allows; nothing is asserted beyond a clause:
# - K1: a stale receipt is a green one for the tree followed by a commit; a red one is recorded with status 1. The
#   reason is asserted unchanged only where the contract quotes it: K3's example line, read as the no-receipt line,
#   and K2's prefix.
# - K3: "the block" is the blocker lines under `not merging`; the kinds the judge can print are read off escape.sh as
#   part 0100 reads them (printf '<kind>\t inside felix_merge_blockers), the hyphen admitted. No fixture here
#   escapes, so the count of escapes is not asserted.
# - K4: a block with one line of the kind; its refused row is exactly `<branch>: not-green: <subject>: <reason>`.
#   Today's rows end with an escaped newline (the two characters \n), which K4 does not quote; it is dropped first.
# - K5: _gt_class over hand-made blocks laid out as cmd_merge's '  %-11s %-22s %s', and end to end by the clause the
#   tick's refused row carries (1650's three clause texts).
# - K6: held is a final-clause row on the head and main, lifted is the head moving, and a receipt-clause row with no
#   record runs once (1650's A20). Today's hold reads no kind, so K6 and K10 are controls that must stay green.
# - K7: the five steps fail by the home's main tracking no upstream (pull), the cache's felix directory at mode 555
#   (install; skipped where a mode refuses no write), the install tainted (diff), session-start exiting 1 (hook
#   check) and felix gate --quick exiting 1 (gate). "The same detail" is its first word, or for the hook check that
#   it names session-start; "the same wall time" that field 6 is whole seconds; "the same paused row" that the next
#   tick writes one holding the reason.
# - K8: "starts a notifier attempt" is a record of the kind in land/alerts.tsv (the origin is a local path, so the
#   record is failed); "the kinds otherwise the same" is held for deployed and deploy-owed.
# - K9: other kinds' sentences are asserted word for word only where parts 1720 and 2120 already pin them, and for
#   the rest that one is printed with status 0. The comment is read from a stub gh, lib/notify.sh sourced alone.
# - K10: --status and --prs name a ledger's newest row only, so "lists both" is read as: the newest row is listed as
#   recorded whichever kind it has and whichever came first. The waiting list names waiting rows only.
# - K12: `unverified\t` is read both ways, a tab and backslash-t; subagent-unverified in harness/hooks/subagent-stop
#   stays allowed (outside this change). The new name's presence is a lib file defining _gt_deploy_failed.
# - K13 has no assertion.
NGD="$TMP/ngd"; rm -rf "$NGD"; mkdir -p "$NGD/gh/bin" "$NGD/nf/bin"; NGD="$(cd "$NGD" && pwd -P)"
NGT="$(printf '\t')"; NGG="$NGD/gh"; NGN="$NGD/nf"
NGS='A deploy of main stopped at a failed step or check, and landing is paused.'
NGPRE='the gate reused a suite run for this tree (tests:reused), and the gate workflow has not passed on '
NGCR='(tried again when a new gate or commission receipt is written)'; NGCF='(final until the head or main moves)'
NGCH='(tried again an hour after this row)'
_ngd_has() { case "$1" in *"$2"*) printf yes ;; *) printf no ;; esac; }
_ngd_begins() { case "$1" in "$2"*) printf yes ;; *) printf no ;; esac; }
_ngd_num() { case "$1" in ""|*[!0123456789]*) printf no ;; *) printf yes ;; esac; }
_ngd_same() { if [ -n "$1" ] && [ -n "$2" ]; then case "$2" in *"$1"*) printf yes; return 0 ;; esac
              case "$1" in *"$2"*) printf yes; return 0 ;; esac; fi; printf no; }
_ngd_bl() { printf '  %-11s %-22s %s\n' "$1" "$2" "$3"; }
_ngd_lines() { local l; for l in "$@"; do _ngd_bl "${l%%|*}" "$(printf '%s' "$l" | cut -d'|' -f2)" "${l##*|}"; done; }   # KIND|SUBJECT|REASON...
NGEX="$(_ngd_bl not-green tree 'no green receipt for this exact tree; run felix gate')"

# ------------------------------------------------------------- K1-K4: the judge and felix merge ---
# A project and checkout of this part's own, as part 1250 builds them; gh is a stub first on PATH that answers
# run list from runs.json through jq, and every other call with status 0 and nothing (as part 0360's does).
NGP="$FROOT/projects/ngdw"; NGR="$NGD/repo"; NGSAYS="$MEM/ngdw/says.log"
mkdir -p "${NGP:?}" "${NGR:?}" "$MEM/ngdw"
cp "$TMP/probes.keep" "$NGP/probes.tsv"; cp "$TMP/obligations.keep" "$NGP/obligations.tsv"
cp "$TMP/commissioning.keep" "$NGP/commissioning.tsv"; cp "$REAL_HARNESS/templates/risk.tsv" "$NGP/risk.tsv"; printf '# ngdw\n' > "$NGP/CLAUDE.md"
printf '{\n  "name": "ngdw",\n  "remote_match": "example.invalid/ngdw",\n  "gate": "true",\n  "gate_workflow": "ngd-gate.yml"\n}\n' > "$NGP/project.json"
( _fx_cd "${NGR:?}" && git init -q -b main && printf 'ngdw\n' > .felix && printf 'one\n' > NOTES.txt \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base \
  && git checkout -q -b ngd-topic && printf 'two\n' >> NOTES.txt \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm change \
  && git remote add origin https://github.com/ngd-owner/ngdw.git ) >/dev/null 2>&1
NGR="$(cd "${NGR:?}" && pwd -P)"; NGH="$(git -C "$NGR" rev-parse HEAD 2>/dev/null)"
cat > "$NGG/bin/gh" <<'NGDGH'
#!/usr/bin/env bash
d="$(cd "$(dirname "$0")/.." && pwd)"
printf '%s\n' "$*" >> "$d/calls"
case "${1:-} ${2:-}" in
  "auth status") printf 'github.com\n  Logged in to github.com account ngd-owner\n'; exit 0 ;;
  "repo view")   printf 'ngd-owner/ngdw\n'; exit 0 ;;
  "run list")    shift 2 ;;
  *) exit 0 ;;
esac
wf=""; c=""; b=""; s=""; n=20; json=""; q=""
while [ $# -gt 0 ]; do
  case "$1" in
    -w|--workflow) wf="${2:-}"; shift 2 ;;  --workflow=*) wf="${1#*=}"; shift ;;
    -c|--commit)   c="${2:-}"; shift 2 ;;   --commit=*)   c="${1#*=}"; shift ;;
    -b|--branch)   b="${2:-}"; shift 2 ;;   --branch=*)   b="${1#*=}"; shift ;;
    -s|--status)   s="${2:-}"; shift 2 ;;   --status=*)   s="${1#*=}"; shift ;;
    -L|--limit)    n="${2:-}"; shift 2 ;;   --limit=*)    n="${1#*=}"; shift ;;
    --json)        json="${2:-}"; shift 2 ;; --json=*)    json="${1#*=}"; shift ;;
    -q|--jq)       q="${2:-}"; shift 2 ;;   --jq=*)       q="${1#*=}"; shift ;;
    -R|--repo|-e|--event|-u|--user|--created) shift 2 ;;
    *) shift ;;
  esac
done
sel="$(jq -c --arg wf "$wf" --arg c "$c" --arg b "$b" --arg s "$s" --argjson n "$n" --arg f "$json" '
  [ .[] | select(($wf == "" or ._wf == $wf or .workflowName == $wf)
             and ($c == "" or .headSha == $c) and ($b == "" or .headBranch == $b)
             and ($s == "" or .status == $s or .conclusion == $s)) ] | .[:$n]
  | if $f == "" then . else map(with_entries(select(.key as $k | ($f | split(",")) | index($k)))) end
' "$d/runs.json")" || exit 1
if [ -n "$q" ]; then printf '%s\n' "$sel" | jq -r "$q"; else printf '%s\n' "$sel"; fi
NGDGH
chmod +x "$NGG/bin/gh"; printf '[]\n' > "$NGG/runs.json"
_ngd_run() {   # STATUS CONCLUSION -> runs.json holds one run of ngd-gate.yml on the head
  printf '[{"databaseId":51,"number":51,"attempt":1,"status":"%s","conclusion":"%s","headSha":"%s","headBranch":"ngd-topic","event":"pull_request","displayTitle":"ngd change","name":"ngd-gate","workflowName":"ngd-gate","workflowDatabaseId":7,"_wf":"ngd-gate.yml","createdAt":"2026-11-07T10:00:00Z","startedAt":"2026-11-07T10:00:00Z","updatedAt":"2026-11-07T10:00:30Z","url":"https://github.com/ngd-owner/ngdw/actions/runs/51"}]\n' \
    "$1" "$2" "$NGH" > "$NGG/runs.json"
}
( cd "${NGR:?}" && FELIX_HOME_DIR="$FROOT"; . "$FROOT/harness/lib/commission.sh"
  _o="$(felix_commission_run "$NGP" "$NGR" -)"; felix_commission_receipt_write "$FROOT" "$NGP" "$NGR" "$_o" "" ) >/dev/null 2>&1
_ngd_rcpt() {   # RC CHECKS -> a gate receipt for the checkout's tree, as part 1250 records one
  ( cd "${NGR:?}" && . "$FROOT/harness/lib/verify.sh"
    felix_verify_record "$NGR" "$FROOT" "$1" "gate.sh" "$(felix_tree_id "$NGR" "$FROOT")" "" "$2" ) >/dev/null 2>&1
}
_ngd_blk() {   # -> felix_merge_blockers over the checkout, loaded as the merge boundary loads it (part 1250)
  ( cd "${NGR:?}" && GIT_ALLOW_PROTOCOL=file PATH="$NGG/bin:$PATH" bash -c '
      set -uo pipefail
      for f in resolve verify review classify evidence escape; do . "$1/lib/$f.sh" 2>/dev/null || exit 3; done
      felix_merge_blockers "$2" main "$3" "$4"' _ "$FROOT/harness" "$NGP" "$NGR" "$FROOT" ) 2>/dev/null
}
_ngd_merge() {   # NAME ARGS... -> felix merge --base main ARGS in the checkout: $NGD/NAME.out, .rc, and .says (the rows it appended)
  local n="$1" l=0; shift
  [ -f "$NGSAYS" ] && l="$(LC_ALL=C awk 'END { print NR }' "$NGSAYS")"
  ( cd "${NGR:?}" && unset FELIX_KERNEL
    GIT_ALLOW_PROTOCOL=file PATH="$NGG/bin:$PATH" CLAUDE_CODE_SESSION_ID=ngd-sess FELIX_KERNEL_CACHE="$NGD/kcache" \
      "$FELIX" merge --base main "$@" ) > "$NGD/$n.out" 2>&1
  printf '%s\n' "$?" > "$NGD/$n.rc"
  if [ -f "$NGSAYS" ]; then tail -n +"$((l + 1))" "$NGSAYS"; fi > "$NGD/$n.says"
}
_ngd_n() { printf '%s\n' "$3" | LC_ALL=C awk -F'\t' -v k="$1" -v s="$2" '$1 == k && (s == "" || $2 == s) { n++ } END { print n + 0 }'; }   # KIND SUBJECT BLOCKERS
_ngd_r() { printf '%s\n' "$2" | LC_ALL=C awk -F'\t' -v s="$1" '($1 == "not-green" || $1 == "unverified") && $2 == s { print $3; exit }'; }   # SUBJECT BLOCKERS -> its reason, either name
_ngd_cnt() { printf '%s\n' "$1" | LC_ALL=C awk 'NF { n++ } END { print n + 0 }'; }
_ngd_block() { LC_ALL=C awk '/^not merging/ { on = 1; next } on && /^[ \t]+[a-z]/ { print; seen = 1; next } on && seen && /^[ \t]*$/ { exit }' "$1" 2>/dev/null; }
_ngd_laid() {   # BLOCKERS FILE -> yes when the file's block is exactly the blockers laid out '  %-11s %-22s %s'
  local w g; w="$(printf '%s\n' "$1" | LC_ALL=C awk -F'\t' 'NF { printf "  %-11s %-22s %s\n", $1, $2, $3 }')"; g="$(_ngd_block "$2")"
  if [ -n "$w" ] && [ "$w" = "$g" ]; then printf yes; else printf 'no[%s]' "$g"; fi
}
_ngd_ref() { LC_ALL=C awk -F'\t' '$2 == "refused" { t = $5; sub(/\\n$/, "", t); printf "%s%s", s, t; s = "|" }' "$NGD/$1.says" 2>/dev/null; }   # NAME -> its refused rows' text, a final escaped newline dropped
_ngd_refctl() {   # NAME BLOCKERS -> yes when its one refused row is <branch>: <the kind the block printed>: <subject>: <reason>, in session ngd-sess
  local k w; k="$(_ngd_block "$NGD/$1.out" | LC_ALL=C awk 'NR == 1 { print $1 }')"
  w="ngd-topic: $k: $(printf '%s\n' "$2" | LC_ALL=C awk -F'\t' 'NF { print $2 ": " $3; exit }')"
  if [ -n "$k" ] && [ "$(_ngd_ref "$1")" = "$w" ] && [ "$(LC_ALL=C awk -F'\t' '$2 == "refused" { print $3 }' "$NGD/$1.says")" = ngd-sess ]; then printf yes
  else printf 'no[%s]' "$(_ngd_ref "$1")"; fi
}
_ngd_oldrows() { cat "$NGD"/m*r.says 2>/dev/null | LC_ALL=C awk -F'\t' '$2 == "refused" && index($5, "ngd-topic: unverified: ") == 1 { n++ } END { print n + 0 }'; }

NGB0="$(_ngd_blk)"; _ngd_merge m0d --dry-run; _ngd_merge m0r          # no receipt
_ngd_rcpt 1 "syntax:ok,tests:ok,secret:ok"; NGB1="$(_ngd_blk)"        # a red receipt for this tree
_ngd_rcpt 0 "syntax:ok,tests:ok,secret:ok"; NGBG="$(_ngd_blk)"        # a current green one
NGJQ=0; command -v jq >/dev/null 2>&1 && NGJQ=1
if [ "$NGJQ" = 1 ]; then
  _ngd_rcpt 0 "syntax:ok,tests:reused,secret:ok"; _ngd_run completed failure; NGB2="$(_ngd_blk)"
  _ngd_merge m2d --dry-run; _ngd_merge m2r
  _ngd_run completed success; NGB2P="$(_ngd_blk)"
fi
_ngd_rcpt 0 "syntax:ok,tests:ok,secret:ok"
( _fx_cd "${NGR:?}" && printf 'three\n' >> NOTES.txt && git add -A && git -c user.name=t -c user.email=t@t commit -qm later ) >/dev/null 2>&1
NGBS="$(_ngd_blk)"                                                    # a stale one: the tree moved after it

is "ngd A1 (K1): with no gate receipt, a red receipt and a stale one, felix_merge_blockers prints a not-green tree line" \
   "$(_ngd_n not-green tree "$NGB0")|$(_ngd_n not-green tree "$NGB1")|$(_ngd_n not-green tree "$NGBS")" "1|1|1"
is "ngd A2 (K1): and in none of the three a line of kind unverified" \
   "$(_ngd_n unverified "" "$NGB0")|$(_ngd_n unverified "" "$NGB1")|$(_ngd_n unverified "" "$NGBS")" "0|0|0"
is "ngd A3 (K1, K11) [control]: each of the three prints one line, a tree line of either name with a reason, and a current green receipt prints none" \
   "$(_ngd_cnt "$NGB0")$(_ngd_cnt "$NGB1")$(_ngd_cnt "$NGBS")|$(( $(_ngd_n not-green tree "$NGB0") + $(_ngd_n unverified tree "$NGB0") ))$(( $(_ngd_n not-green tree "$NGB1") + $(_ngd_n unverified tree "$NGB1") ))$(( $(_ngd_n not-green tree "$NGBS") + $(_ngd_n unverified tree "$NGBS") ))|$([ -n "$(_ngd_r tree "$NGB0")" ] && [ -n "$(_ngd_r tree "$NGB1")" ] && [ -n "$(_ngd_r tree "$NGBS")" ] && echo reasons)|$(_ngd_cnt "$NGBG")" \
   "111|111|reasons|0"
is "ngd A4 (K1, K3) [control]: the no-receipt line's reason is the one K3's example line shows" \
   "$(_ngd_r tree "$NGB0")" "no green receipt for this exact tree; run felix gate"
if [ "$NGJQ" = 1 ]; then
  is "ngd A5 (K2): a current green receipt reporting tests:reused, with the gate workflow failed on the head, prints a not-green tests line" "$(_ngd_n not-green tests "$NGB2")" "1"
  is "ngd A6 (K2): and no line of kind unverified" "$(_ngd_n unverified "" "$NGB2")" "0"
  is "ngd A7 (K2, K11) [control]: it prints one line, a tests line of either name whose reason begins as K2 quotes it; with the workflow passed on the head, or tests:ok, no tests line" \
     "$(_ngd_cnt "$NGB2")|$(_ngd_begins "$(_ngd_r tests "$NGB2")" "$NGPRE")|$(( $(_ngd_n not-green tests "$NGB2P") + $(_ngd_n unverified tests "$NGB2P") ))|$(( $(_ngd_n not-green tests "$NGBG") + $(_ngd_n unverified tests "$NGBG") ))" "1|yes|0|0"
else for NGX in "ngd A5 (K2): a current green receipt reporting tests:reused, with the gate workflow failed on the head, prints a not-green tests line" \
    "ngd A6 (K2): and no line of kind unverified" \
    "ngd A7 (K2, K11) [control]: it prints one line, a tests line of either name whose reason begins as K2 quotes it; with the workflow passed on the head, or tests:ok, no tests line"; do
  skip "$NGX" "no jq here for the gh stub"; done; fi

# the boundary is felix_merge_blockers, the body it calls once P is read, and the policy blockers lib/policy.sh prints for it
NGKS="$({ sed -n '/^felix_merge_blockers()/,/^}/p; /^_felix_merge_blockers_at()/,/^}/p' "$FROOT/harness/lib/escape.sh"
          grep "printf 'policy" "$FROOT/harness/lib/policy.sh"; } | grep -o "printf '[a-z][a-z-]*\\\\t" \
        | sed "s/printf '//; s/\\\\t\$//" | LC_ALL=C sort -u | tr '\n' ' ')"
is "ngd A8 (K3): the kinds felix_merge_blockers can print are commission, escape, evidence, obligations, policy, probes, unknown and not-green" \
   "$NGKS" "commission escape evidence not-green obligations policy probes unknown "
has "ngd A9 (K3): felix merge --dry-run with no receipt prints the block line K3 gives, laid out as before" "$(_ngd_block "$NGD/m0d.out")" "$NGEX"
is "ngd A10 (K3): no line of the block of either run begins with unverified once blanks are skipped" \
   "$(for NGX in m0d m0r m2d m2r; do _ngd_block "$NGD/$NGX.out"; done | LC_ALL=C awk '$1 == "unverified" { n++ } END { print n + 0 }')|$(_ngd_block "$NGD/m0d.out" | LC_ALL=C awk '$1 == "not-green" { n++ } END { print n + 0 }')" "0|1"
is "ngd A11 (K3, K11) [control]: a dry and a real run with no receipt exit 3, print the judge's line laid out '  %-11s %-22s %s', the same block, and close it as work Felix owes, not the founder's" \
   "$(cat "$NGD/m0d.rc")$(cat "$NGD/m0r.rc")|$(_ngd_laid "$NGB0" "$NGD/m0d.out")|$([ "$(_ngd_block "$NGD/m0d.out")" = "$(_ngd_block "$NGD/m0r.out")" ] && echo same)|$(_ngd_has "$(cat "$NGD/m0d.out")" 'work Felix owes')|$(_ngd_has "$(cat "$NGD/m0d.out")" 'it is the founder who decides')$(_ngd_has "$(cat "$NGD/m0d.out")" 'waits for the founder')" \
   "33|yes|same|yes|nono"
if [ "$NGJQ" = 1 ]; then
  has "ngd A12 (K3): with the tests:reused receipt the dry run's block holds the not-green tests line, laid out as before" \
      "$(_ngd_block "$NGD/m2d.out")" "$(_ngd_bl not-green tests "$(_ngd_r tests "$NGB2")")"
  is "ngd A13 (K3, K11) [control]: and there a dry and a real run exit 3 and print the judge's line, the same block, closed as work Felix owes" \
     "$(cat "$NGD/m2d.rc")$(cat "$NGD/m2r.rc")|$(_ngd_laid "$NGB2" "$NGD/m2d.out")|$([ "$(_ngd_block "$NGD/m2d.out")" = "$(_ngd_block "$NGD/m2r.out")" ] && echo same)|$(_ngd_has "$(cat "$NGD/m2d.out")" 'work Felix owes')" "33|yes|same|yes"
else skip "ngd A12 (K3): with the tests:reused receipt the dry run's block holds the not-green tests line, laid out as before" "no jq here for the gh stub"
  skip "ngd A13 (K3, K11) [control]: and there a dry and a real run exit 3 and print the judge's line, the same block, closed as work Felix owes" "no jq here for the gh stub"; fi
NGW4="ngd-topic: not-green: tree: $(_ngd_r tree "$NGB0")"; [ "$NGJQ" = 1 ] && NGW4="$NGW4 ngd-topic: not-green: tests: $(_ngd_r tests "$NGB2")"
is "ngd A14 (K4): a real felix merge refused for K1, and for K2, writes the refused say row <branch>: not-green: <subject>: <reason>" \
   "$(_ngd_ref m0r)$([ "$NGJQ" = 1 ] && printf ' %s' "$(_ngd_ref m2r)")" "$NGW4"
is "ngd A15 (K4): and no refused row beginning <branch>: unverified:" "$(_ngd_oldrows)" "0"
is "ngd A16 (K4, K11) [control]: each real run writes one refused row, <branch>: <the kind its block printed>: <subject>: <reason>, in its session, and a dry run writes none" \
   "$(_ngd_refctl m0r "$NGB0")|$(LC_ALL=C awk 'END { print NR }' "$NGD/m0d.says")" "yes|0"

# ------------------------------------------------------------- K5: the lander's class, by hand ---
_ngd_cls() {   # STATUS LINE... -> _gt_class over `not merging`, a blank, the lines, a blank and a closing paragraph (no lines: the first two alone)
  local st="$1" o; shift
  o="$(printf 'not merging\n\n'; [ $# -eq 0 ] || { _ngd_lines "$@"; printf '\nAsk them to run, in order:\n\n  felix autonomy --allow commission\n  felix commission\n'; })"
  bash -c '. "$1/lib/green-install.sh" >/dev/null 2>&1; _gt_class "$2" "$3"' _ "$FROOT/harness" "$st" "$o" 2>/dev/null
}
NGLT='not-green|tree|the tree changed since the receipt'; NGLU='unverified|tree|the tree changed since the receipt'
NGLTS="not-green|tests|${NGPRE}0123abcd: GitHub could not be asked (gh run list failed with status 1)"; NGLUS="unverified${NGLTS#not-green}"
NGLC='commission|receipt|the table set moved'; NGLE='evidence|notes/x.md|the change owes a test'
is "ngd A17 (K5): status 3 and blocks of not-green lines: tree alone or with commission receipt is receipt; a tests line, alone or after tree, is hourly" \
   "$(_ngd_cls 3 "$NGLT") $(_ngd_cls 3 "$NGLT" "$NGLC") $(_ngd_cls 3 "$NGLTS") $(_ngd_cls 3 "$NGLT" "$NGLTS")" "receipt receipt hourly hourly"
is "ngd A18 (K5): blocks that mix the two names are classed the same: hourly with a tests line of either name, receipt without" \
   "$(_ngd_cls 3 "$NGLU" "$NGLTS") $(_ngd_cls 3 "$NGLT" "$NGLUS") $(_ngd_cls 3 "$NGLU" "$NGLT") $(_ngd_cls 3 "$NGLT" "$NGLC" "$NGLU")" "hourly hourly receipt receipt"
is "ngd A19 (K5) [control]: a block an older engine wrote, unverified in place of not-green, keeps its class: receipt, receipt, hourly, hourly" \
   "$(_ngd_cls 3 "$NGLU") $(_ngd_cls 3 "$NGLU" "$NGLC") $(_ngd_cls 3 "$NGLUS") $(_ngd_cls 3 "$NGLU" "$NGLUS")" "receipt receipt hourly hourly"
is "ngd A20 (K5, K11) [control]: status 3 with any other line (evidence beside either name, escape, commission table) or no block is final; commission receipt alone is receipt; any other status is hourly" \
   "$(_ngd_cls 3 "$NGLT" "$NGLE") $(_ngd_cls 3 "$NGLU" "$NGLE") $(_ngd_cls 3 "$NGLTS" "$NGLE") $(_ngd_cls 3 'escape|write|notes/x.md: outside the tree') $(_ngd_cls 3 'commission|table|unreadable') $(_ngd_cls 3) $(bash -c '. "$1/lib/green-install.sh" >/dev/null 2>&1; _gt_class 3 ""' _ "$FROOT/harness" 2>/dev/null) $(_ngd_cls 3 "$NGLC") $(_ngd_cls 1 "$NGLT") $(_ngd_cls 4 "$NGLU")" \
   "final final final final final final final receipt hourly hourly"

# ------------------------------------------------------------- K9: the notifier ---
_ngd_sent() { bash -c '. "$1/lib/notify.sh" >/dev/null 2>&1; _fn_sentence "$2"; printf "|%s" "$?"' _ "$FROOT/harness" "$1" 2>/dev/null; }   # KIND -> SENTENCE|STATUS
_ngd_nosent() { local k; for k in "$@"; do case "$(_ngd_sent "$k")" in "|"*|*"|1") printf '%s ' "$k" ;; esac; done; }   # KIND... -> those with no sentence or a status other than 0
cat > "$NGN/bin/gh" <<'NGDNF'
#!/bin/bash
d="${NGDNF_DIR:?}"; printf '%s\n' "$*" >> "$d/calls"
case "${1:-} ${2:-}" in
  "api --hostname") case " $* " in
      *" user "*) printf 'ngd-bot\n' ;;
      *" repos/ngd-owner/ngdw "*) printf 'ngd-owner/ngdw\nngd-owner\nUser\nfalse\nfalse\ntrue\n' ;;
      *) exit 1 ;; esac ;;
  "issue list") printf '0\n' ;;
  "issue create") cat > /dev/null; printf 'https://github.com/ngd-owner/ngdw/issues/1\n' ;;
  "workflow run") pv=""; for a in "$@"; do case "$pv" in -f) case "$a" in body=*) printf '%s' "${a#body=}" > "$d/body" ;; esac ;; esac; pv="$a"; done
    printf 'https://github.com/ngd-owner/ngdw/actions/runs/901\n' ;;
  *) exit 1 ;;
esac
exit 0
NGDNF
chmod +x "$NGN/bin/gh"
_ngd_att() {   # KIND -> one _fn_attempt of KIND, lib/notify.sh alone, its land directory $NGN/KIND; -> line 1|where the sentence stands|the record
  rm -rf "${NGN:?}/$1"; mkdir -p "$NGN/$1"
  PATH="$NGN/bin:$PATH" NGDNF_DIR="$NGN/$1" TMPDIR="$NGN/$1" bash -c '. "$1/lib/notify.sh" >/dev/null 2>&1
    _FN_DIR="$2"; _FN_REPO=ngd-owner/ngdw; _FN_LSET=0; _FN_LOGIN=""; _FN_NOTE=""; _FN_SECS=10
    _fn_attempt "$3" - "pull: the fixture detail"' _ "$FROOT/harness" "$NGN/$1" "$1" >/dev/null 2>&1
  printf '%s|' "$(sed -n 1p "$NGN/$1/body" 2>/dev/null)"
  if [ -f "$NGN/$1/body" ]; then LC_ALL=C awk -v s="$NGS" '$0 == s && NR > 1 && !f { f = NR } /^details: / && !d { d = NR } END { printf "%s", (f && d && f < d) ? "below" : "not-below" }' "$NGN/$1/body"; else printf none; fi
  printf '|%s' "$(if [ -f "$NGN/$1/alerts.tsv" ]; then LC_ALL=C awk -F'\t' '{ v = $2 " " $3 } END { printf "%s", v }' "$NGN/$1/alerts.tsv"; fi)"
}
is "ngd A21 (K9): _fn_sentence deploy-failed prints exactly the deploy sentence and returns 0" "$(_ngd_sent deploy-failed)" "$NGS|0"
is "ngd A22 (K9) [control]: _fn_sentence deployed-unverified prints exactly the same sentence and returns 0, so an old event is still sent" "$(_ngd_sent deployed-unverified)" "$NGS|0"
is "ngd A23 (K9, K11) [control]: the sentences parts 1720 and 2120 pin are unchanged, every other notified kind still has one, and a kind with none returns 1 and prints nothing" \
   "$(_ngd_sent paused)~$(_ngd_sent refused)~$(_ngd_sent landed)~$(_ngd_sent gh)~$(_ngd_sent deploy-owed)~$(_ngd_sent unreadable)~$(_ngd_sent waiting)~$(_ngd_sent unaged)~$(_ngd_nosent founder deployed stuck timeout unresolved fetch)~$(_ngd_sent no-such-kind)$(_ngd_sent '')" \
   "Landing is paused until felix land --resume.|0~felix merge refused a green pull request.|0~A green pull request was merged into main.|0~gh auth status failed, so nothing lands.|0~A deploy of main is owed and has not run, so nothing lands.|0~The lander could not read the home, so nothing lands.|0~A green pull request has waited more than four hours to land.|0~A tick could not age what waits, so no waiting pull request is named.|0~~|1|1"
is "ngd A24 (K9): the comment dispatched for a deploy-failed event begins @<owner> Felix land: deploy-failed and holds the sentence below it, before the details line; recorded dispatched" \
   "$(_ngd_att deploy-failed)" "@ngd-owner Felix land: deploy-failed|below|dispatched deploy-failed"
is "ngd A25 (K9) [control]: and one for a deployed-unverified event recorded before the deploy is dispatched the same way under its own kind" \
   "$(_ngd_att deployed-unverified)" "@ngd-owner Felix land: deployed-unverified|below|dispatched deployed-unverified"

# ------------------------------------------------------------- K12: the class, not the instance ---
# C18's reading: the files git tracks under DIR (every file when it tracks none), harness/tests/ left out; a line whose
# first character past blanks is # skipped except in Markdown; the allowed names removed in their own files only.
_ngd_scan() {   # DIR -> KIND<TAB>PATH:LINE for each hit (fn: _gt_unverified; ledger: deployed-unverified; tab: unverified then a tab or \t; word: unverified)
  local d="$1" f a=()
  if [ -n "$(git -C "$d" ls-files -c -- . 2>/dev/null | head -1)" ]; then
    while IFS= read -r -d '' f; do a+=("$f"); done < <(git -C "$d" ls-files -c -z -- . 2>/dev/null)
  else while IFS= read -r -d '' f; do a+=("${f#./}"); done < <(cd "$d" 2>/dev/null && find . -type f -print0 2>/dev/null); fi
  local b=(); for f in ${a[@]+"${a[@]}"}; do case "$f" in harness/tests/*) continue ;; esac; [ -f "$d/$f" ] && b+=("$f"); done
  [ "${#b[@]}" -gt 0 ] || return 0
  ( cd "$d" && LC_ALL=C awk -v T="$NGT" '
    function strip(s, n,   i, o) { o = ""; while ((i = index(s, n)) > 0) { o = o substr(s, 1, i - 1); s = substr(s, i + length(n)) } return o s }
    FNR == 1 { md = (FILENAME ~ /\.md$/) }
    { ln = $0; if (!md) { t = ln; sub(/^[ \t]+/, "", t); if (substr(t, 1, 1) == "#") next }
      w = FILENAME ":" FNR; l = ln
      if (index(ln, "_gt_unverified")) print "fn" T w
      if (FILENAME == "harness/lib/notify.sh") l = strip(l, "deployed-unverified)")
      if (FILENAME == "harness/lib/green-install.sh") l = strip(l, "$1 == \"unverified\"")
      if (FILENAME == "harness/lib/green-tick.sh") l = strip(l, "old=\"  unverified  ${b#\"  not-green   \"}\"")
      if (FILENAME == "harness/hooks/subagent-stop") l = strip(l, "subagent-unverified")
      if (index(l, "deployed-unverified")) print "ledger" T w
      if (index(l, "unverified\\t") || index(l, "unverified" T)) print "tab" T w
      if (tolower(l) ~ /(^|[^a-z0-9_])unverified([^a-z0-9_]|$)/) print "word" T w }' "${b[@]}" 2>/dev/null )
  # Round 5, not blind (review round 1): the awk's status and the count of files it read, for a control over the real engine.
  printf '%s %s\n' "$?" "${#b[@]}" > "$NGD/scan.last"
}
_ngd_kinds() { printf '%s\n' "$1" | LC_ALL=C awk -F'\t' 'NF == 2 { p = $2; sub(/:[0123456789]+$/, "", p); print p "=" $1 }' | LC_ALL=C sort -u | tr '\n' ' '; }
_ngd_fx() {   # DIR PATH|LINE... -> a git repository holding each line in its file, every file tracked and committed
  local d="$1" p; shift; rm -rf "${d:?}"; mkdir -p "$d"
  for p in "$@"; do mkdir -p "$d/$(dirname "${p%%|*}")"; printf '%s\n' "${p#*|}" >> "$d/${p%%|*}"; done
  _fx_git "$d" init -q >/dev/null 2>&1; _fx_git "$d" add -A >/dev/null 2>&1; _fx_git "$d" -c user.name=t -c user.email=t@t commit -qm fx >/dev/null 2>&1
}
_ngd_fx "$NGD/k12a" "harness/lib/escape.sh|    printf 'unverified\\ttree\\t%s\\n' \"\$why\"" "harness/lib/green-tick.sh|_gt_x() { _gt_row deployed-unverified - - - 0 \"\$1\"; }" \
  "harness/lib/notify.sh|  case \"\$1\" in deployed|deployed-unverified|paused) ;; esac" "harness/lib/green-install.sh|  c = (\$2 == \"unverified\")" \
  "harness/lib/other.sh|_gt_unverified \"pull: x\"" "README.md|# deployed-unverified"
is "ngd A26 (K12) [control]: the check fails on each removed entry in the file that allowed it (escape.sh unverified\\t, green-tick.sh and notify.sh deployed-unverified, green-install.sh == \"unverified\"), on _gt_unverified, and on a Markdown heading" \
   "$(_ngd_kinds "$(_ngd_scan "$NGD/k12a")")" \
   "README.md=ledger README.md=word harness/lib/escape.sh=tab harness/lib/escape.sh=word harness/lib/green-install.sh=word harness/lib/green-tick.sh=ledger harness/lib/green-tick.sh=word harness/lib/notify.sh=ledger harness/lib/notify.sh=word harness/lib/other.sh=fn "
_ngd_fx "$NGD/k12b" "harness/lib/notify.sh|    deployed-unverified) printf '%s' 'x' ;;" "harness/lib/green-install.sh|  \$1 == \"unverified\" { u = 1 }" \
  "harness/hooks/subagent-stop|felix_say subagent-unverified \"\$why\"" "harness/lib/green-tick.sh|  # deployed-unverified was the kind; _gt_unverified its writer" \
  "harness/lib/green-tick.sh|  case \"\$b\" in \"  not-green   \"*) old=\"  unverified  \${b#\"  not-green   \"}\" ;; esac" \
  "harness/tests/parts/x.sh|_gt_unverified deployed-unverified"
printf 'deployed-unverified\n' > "$NGD/k12b/harness/lib/untracked.sh"
is "ngd A27 (K12) [control]: and passes on each new entry in its own file, a comment, a file under harness/tests/ and a file git does not track" "$(_ngd_scan "$NGD/k12b")" ""
rm -rf "$NGD/k12c"; mkdir -p "$NGD/k12c/harness/lib"; printf '    deployed-unverified) printf x ;;\n' > "$NGD/k12c/harness/lib/green-tick.sh"
printf '  $1 == "unverified" { u = 1 }\n' > "$NGD/k12c/harness/lib/escape.sh"
printf '  case "$b" in "  not-green   "*) old="  unverified  ${b#"  not-green   "}" ;; esac\n' > "$NGD/k12c/harness/lib/other.sh"
is "ngd A28 (K12) [control]: a new entry outside its own file fails, read in a directory git tracks nothing of, which is read whole" \
   "$(_ngd_kinds "$(_ngd_scan "$NGD/k12c")")" "harness/lib/escape.sh=word harness/lib/green-tick.sh=ledger harness/lib/green-tick.sh=word harness/lib/other.sh=word "
NGE="$(cd "$REAL_HARNESS/.." && pwd -P)"; NGK12="$(_ngd_scan "$NGE")"; NGSC="$(cat "$NGD/scan.last" 2>/dev/null)"
_ngd_hits() { printf '%s\n' "$NGK12" | LC_ALL=C awk -F'\t' -v k="$1" '$1 == k { printf "%s%s", s, $2; s = " " }'; }
is "ngd A29 (K12): _gt_unverified appears in no tracked file of the engine outside harness/tests/, comments skipped as C18 skips them" "$(_ngd_hits fn)" ""
is "ngd A30 (K12): deployed-unverified appears there only as the case label deployed-unverified) in harness/lib/notify.sh" "$(_ngd_hits ledger)" ""
is "ngd A31 (K12): unverified followed by a tab, or by backslash and t, appears there nowhere" "$(_ngd_hits tab)" ""
is 'ngd A32 (K12): the old blocker name appears there as a word only as $1 == "unverified" in harness/lib/green-install.sh, as the quiet check'"'"'s text in harness/lib/green-tick.sh, beside the subagent-unverified kind this change leaves' "$(_ngd_hits word)" ""
is "ngd A32b (K12, review round 1, control): the scan of the engine under test read at least fifty files and its awk ended with status 0, so a scan that read nothing cannot pass" \
   "$(printf '%s\n' "$NGSC" | LC_ALL=C awk '{ printf "rc=%s files=%s", $1, ($2 >= 50 ? "fifty or more" : $2) }')" "rc=0 files=fifty or more"
is "ngd A33 (K12): the function's new name: a file of harness/lib defines _gt_deploy_failed" \
   "$( (cd "$REAL_HARNESS/lib" && LC_ALL=C awk '/^[ \t]*_gt_deploy_failed[ \t]*\(\)/ { print "defined"; exit }' ./*.sh) 2>/dev/null)" "defined"

# ------------------------------------------------------------- K5, K6, K7, K8, K10: the lander ---
_lg_build amend
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1
NGV="$(_l3_mainv)"; [ -n "$NGV" ] && _lg_cache "$NGV"
rm -rf "${LGH:?}/state"
if [ -d "$LGW/b77" ]; then NGLH="$(git -C "$LGW/b77" rev-parse HEAD 2>/dev/null)"; else NGLH="$(_lg_branch b77 notes/b77.md)"; fi
[ -n "$(_lg_sha 77)" ] || printf '77\t%s\n' "$NGLH" >> "$LG/shas"
NGW="$(cd "$LGW/b77" 2>/dev/null && pwd -P)"
_ngd_m() { _lg_logs felix | LC_ALL=C awk -F'\t' -v d="$NGW" '$2 == d && $3 == "merge" { n++ } END { print n + 0 }'; }
_ngd_case() {   # LINE... -> a fresh land/, logs and state, 77 alone and green, felix merge printing a block of the lines, status 3
  _lg_reset; rm -rf "${LGH:?}/state"; _lg_prs "$(_lg_pr 77)"; _lg_green 77
  { printf 'not merging\n\n'; _ngd_lines "$@"; printf '\nNothing here escapes the tree.\n'; } > "$LGK/merge.b77.out"; printf '3\n' > "$LGK/merge.b77.rc"
}
is "ngd A34 (K5, K6) [fixture control]: the home is on main at origin's main, main's check accepts its entry, and b77 is on its branch at 77's head" \
   "$(git -C "$LGH" rev-parse HEAD 2>&1)|$(_la_accepts)|$(git -C "$LGW/b77" symbolic-ref HEAD 2>&1)|$(git -C "$LGW/b77" rev-parse HEAD 2>&1)" \
   "$(git -C "$LGO" rev-parse main 2>&1)|0|refs/heads/b77|$(_lg_sha 77)"
_ngd_case "$NGLT"; _lg_land --tick; NGD5="$(_lg_f refused 77 7)"; NGHF="$(_lg_f refused 77 4)"; NGWF="$(_lg_f refused 77 5)"; NGM5="$(_ngd_m)"
_ngd_case "$NGLTS"; _lg_land --tick; NGD5S="$(_lg_f refused 77 7)"
_ngd_case "$NGLU"; _lg_land --tick; NGD5U="$(_lg_f refused 77 7)"
is "ngd A35 (K5): end to end, a refusal whose one blocker is not-green tree is a receipt refusal: its refused row says tried again when a receipt is written, not final" \
   "$(_ngd_has "$NGD5" "$NGCR")|$(_ngd_has "$NGD5" "$NGCF")" "yes|no"
is "ngd A36 (K5): and one whose one blocker is not-green tests is hourly" "$(_ngd_has "$NGD5S" "$NGCH")|$(_ngd_has "$NGD5S" "$NGCF")" "yes|no"
is "ngd A37 (K5, K11) [control]: an unverified tree refusal an older engine printed is a receipt refusal end to end, each case ran felix merge once and wrote one refused row" \
   "$(_ngd_has "$NGD5U" "$NGCR")|$NGM5|$(_lg_n refused 77)" "yes|1|1"
NGHL="${#NGHF}"; [ "$NGHL" -gt 0 ] || NGHL=40
_ngd_seed() {   # KIND CLAUSE -> land/ holds one refused row for 77 on its head and main: a KIND tree line, the clause, [main <sha>]
  mkdir -p "$LAND"
  printf '%s\trefused\t77\t%s\t%s\t0\t%s %s [main %s]\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(_lg_sha 77 | cut -c1-"$NGHL")" "$NGWF" \
    "$(_ngd_bl "$1" tree 'the tree changed since the receipt' | tr -d '\n')" "$2" "$(git -C "$LGH" rev-parse refs/remotes/origin/main 2>/dev/null)" > "$LAND/ledger.tsv"
}
_ngd_more() {   # -> 77's head moves one commit, and gh lists it green there
  local h; h="$(_lg_more b77 notes/b77.md)"
  LC_ALL=C awk -F'\t' -v OFS='\t' -v s="$h" '$1 == "77" { $2 = s } { print }' "$LG/shas" > "$NGD/shas" && /bin/mv "$NGD/shas" "$LG/shas"
  _lg_prs "$(_lg_pr 77)"; _lg_green 77
}
_ngd_case "$NGLT"; _ngd_seed unverified "$NGCF"
is "ngd A38 (K6) [fixture control]: a seeded row is the ledger's one row, of seven fields, its head and worktree in the form the tick writes" \
   "$(_lg_rows)|$(LC_ALL=C awk -F'\t' '{ print NF }' "$LAND/ledger.tsv")|$(_lg_f refused 77 4)|$(_lg_f refused 77 5)" "1|7|$NGHF|$NGWF"
_lg_land --tick; NGA="$(_ngd_m)"; _ngd_case "$NGLT"; _ngd_seed not-green "$NGCF"; _lg_land --tick; NGB="$(_ngd_m)"
is "ngd A39 (K6) [control]: a final refused row whose detail begins unverified, on 77's head and main, is held as one that begins not-green: no tick runs felix merge" "$NGA|$NGB" "0|0"
_ngd_case "$NGLT"; _ngd_seed unverified "$NGCF"; _ngd_more; _lg_land --tick; NGA="$(_ngd_m)"
_ngd_case "$NGLT"; _ngd_seed not-green "$NGCF"; _ngd_more; _lg_land --tick; NGB="$(_ngd_m)"
is "ngd A40 (K6) [control]: and each is lifted the same: once 77's head moves, the next tick runs felix merge once" "$NGA|$NGB" "1|1"
_ngd_case "$NGLT"; _ngd_seed unverified "$NGCR"; _lg_land --tick; NGA="$(_ngd_m)"
_ngd_case "$NGLT"; _ngd_seed not-green "$NGCR"; _lg_land --tick; NGB="$(_ngd_m)"
is "ngd A41 (K6) [control]: the hold reads the clause, not the kind: a receipt-clause row of either kind whose receipts the tick has no record of is run once" "$NGA|$NGB" "1|1"

_ngd_dk() { [ -f "$LAND/ledger.tsv" ] && LC_ALL=C awk -F'\t' '$2 == "deploy-failed" || $2 == "deployed-unverified" { printf "%s%s", s, $2; s = " " }' "$LAND/ledger.tsv"; }
_ngd_dr() { [ -f "$LAND/ledger.tsv" ] && LC_ALL=C awk -F'\t' -v k="$1" '$2 == "deploy-failed" || $2 == "deployed-unverified" { v = $k } END { printf "%s", v }' "$LAND/ledger.tsv"; }
_ngd_osa() { _lg_logs osa | LC_ALL=C awk -v t="with title \"$1\"" 'index($0, t) { n++ } END { print n + 0 }'; }
_ngd_al() { if [ -f "$LAND/alerts.tsv" ]; then LC_ALL=C awk -F'\t' -v k="$1" '$3 == k { n++ } END { print n + 0 }' "$LAND/alerts.tsv"; else echo 0; fi; }
_ngd_word() { case "$2" in begins:*) _ngd_begins "$1" "${2#begins:}" ;; *) _ngd_has "$(_lg_lc "$1")" "${2#holds:}" ;; esac; }
_ngd_owe() { _lg_reset; rm -rf "${LGV:?}/${NGV:-none}"; }   # a fresh land/ and logs, main's entry gone: the tick owes a deploy
_ngd_step() {   # N WHAT WORD SAID [SKIP-REASON] -> four assertions on the tick after a deploy whose WHAT fails (SAID: how its detail reads)
  local d p n1="ngd A$1 (K7): when $2 fails, the tick writes one deploy-failed row whose detail $4" \
    n2="ngd A$(($1 + 1)) (K7): and no row of kind deployed-unverified" \
    n3="ngd A$(($1 + 2)) (K7, K8, K11) [control]: when $2 fails, the tick exits 0 with one failed-deploy row of either name and no deployed row, - for its pull request, head and worktree, whole seconds of wall time, its detail as before, paused holding its reason, one banner and one attempt under its kind" \
    n4="ngd A$(($1 + 3)) (K8): and that row is sent titled Felix: deploy-failed and starts an attempt of that kind, and none is sent or recorded as deployed-unverified"
  if [ -n "${5:-}" ]; then skip "$n1" "$5"; skip "$n2" "$5"; skip "$n3" "$5"; skip "$n4" "$5"; return 0; fi
  _lg_land --tick; d="$(_ngd_dr 7)"; p="$(cat "$LAND/paused" 2>/dev/null)"
  is "$n1" "$(_lg_n deploy-failed)|$(_ngd_word "$(_lg_f deploy-failed "" 7)" "$3")" "1|yes"
  is "$n2" "$(_lg_n deployed-unverified)" "0"
  is "$n3" "$LGRC|$(_ngd_dk | wc -w | tr -d ' ')|$(_lg_n deployed)|$(_ngd_dr 3)$(_ngd_dr 4)$(_ngd_dr 5)|$(_ngd_num "$(_ngd_dr 6)")|$(_ngd_word "$d" "$3")|$(_ngd_same "$p" "$d")|$(_ngd_osa "Felix: $(_ngd_dr 2)")|$(_ngd_al "$(_ngd_dr 2)")" "0|1|0|---|yes|yes|yes|1|1"
  is "$n4" "$(_ngd_osa 'Felix: deploy-failed')|$(_ngd_al deploy-failed)|$(_ngd_osa 'Felix: deployed-unverified')|$(_ngd_al deployed-unverified)" "1|1|0|0"
}
_ngd_owe; _fx_git "$LGH" branch -q --unset-upstream main >/dev/null 2>&1
is "ngd A42 (K7) [fixture control]: with the home's main tracking no upstream, git pull --ff-only in the home fails" \
   "$(_fx_git "$LGH" pull -q --ff-only >/dev/null 2>&1 && echo pulls || echo fails)" "fails"
_ngd_step 43 "the pull" begins:pull: "begins pull:"
_fx_git "$LGH" branch -q --set-upstream-to=origin/main main >/dev/null 2>&1
_unwritable_probe; _ngd_owe
if [ "${_unwritable:-0}" = 1 ]; then chmod 555 "$LGV"; _ngd_step 47 "the install" begins:install: "begins install:"; chmod 755 "$LGV"
else _ngd_step 47 "the install" begins:install: "begins install:" "$_nowrite"; fi
_ngd_owe; : > "$LGK/install.taint"; _ngd_step 51 "the comparison of the cache entry with main's engine" begins:diff: "begins diff:"
_ngd_owe; printf '1\n' > "$LGK/hook.rc"; _ngd_step 55 "the hook check" holds:session-start "names session-start"
_ngd_owe; printf '1\n' > "$LGK/gate.rc"; _ngd_step 59 "felix gate --quick" begins:gate: "begins gate:"
NGP7="$(cat "$LAND/paused" 2>/dev/null)"; _lg_land --tick
is "ngd A63 (K7, K11) [control]: the tick after a failed deploy writes the paused row, holding the reason the paused file holds" \
   "$(_lg_n paused)|$(_ngd_same "$NGP7" "$(_lg_f paused "" 7)")" "1|yes"
_ngd_owe; _lg_land --tick
is "ngd A64 (K7, K8, K11) [control]: a deploy whose steps and checks pass still writes deployed, no failed-deploy row and no paused file, sent titled Felix: deployed" \
   "$LGRC|$(_lg_n deployed)|$(_ngd_dk)|$([ -e "$LAND/paused" ] && echo paused)|$(_ngd_osa 'Felix: deployed')" "0|1|||1"
_ngd_owe; printf '/bin/bash /x/engine/harness/tests/run\n' > "$LGK/procs"; _lg_land --tick
is "ngd A65 (K7, K8, K11) [control]: one owed while a suite runs still writes deploy-owed saying so, no failed-deploy row, sent titled Felix: deploy-owed" \
   "$(_lg_n deploy-owed)|$(_ngd_has "$(_lg_f deploy-owed "" 7)" 'a gate or suite is running')|$(_ngd_dk)|$(_ngd_osa 'Felix: deploy-owed')" "1|yes||1"
[ -n "$NGV" ] && _lg_cache "$NGV"

NGR1="2026-11-07T08:10:00Z${NGT}%s${NGT}-${NGT}-${NGT}-${NGT}4${NGT}gate: felix gate --quick exited 1 in the home"
NGR2="2026-11-07T08:20:00Z${NGT}%s${NGT}-${NGT}-${NGT}-${NGT}2${NGT}pull: git pull --ff-only failed: no upstream"
_ngd_led() {   # NAME KIND [KIND2] -> a ledger: a landed row for 77, a KIND row, a later KIND2 row; --status --tsv, --status, --prs --tsv kept as NAME.*
  _lg_reset; mkdir -p "$LAND"; : > "$LGK/loaded"
  { printf '2026-11-07T08:00:00Z\tlanded\t77\t%s\t%s\t3\tmerged\n' "$(_lg_sha 77)" "$NGW"; printf "$NGR1\n" "$2"; [ -z "${3:-}" ] || printf "$NGR2\n" "$3"; } > "$LAND/ledger.tsv"
  _lg_land --status --tsv; cp "$LG/out" "$NGD/$1.stt"; _lg_land --status; cp "$LG/out" "$NGD/$1.st"; _lg_land --prs --tsv; cp "$LG/out" "$NGD/$1.prs"
}
_ngd_l4() { sed -n 4p "$NGD/$1.st"; }
_ngd_col() { LC_ALL=C awk -v d="gate: felix gate --quick exited 1" 'NR == 4 { print index($0, d) }' "$NGD/$1.st"; }
_ngd_cl() { LC_ALL=C awk -F'\t' '$1 == "source" && $3 == "lander" { n = index($8, "; last ledger row "); if (n) printf "%s", substr($8, n); exit }' "$NGD/$1.prs"; }
_ngd_led old deployed-unverified; _ngd_led new deploy-failed
is "ngd A66 (K10) [control]: --status --tsv lists a ledger holding a deployed-unverified row byte for byte as the same ledger under deploy-failed, the newest row as recorded" \
   "$(sed "s/${NGT}deployed-unverified${NGT}/${NGT}deploy-failed${NGT}/" "$NGD/old.stt" | cmp -s - "$NGD/new.stt" && echo same)|$(sed -n 4p "$NGD/old.stt")" "same|last${NGT}$(printf "$NGR1" deployed-unverified)"
is "ngd A67 (K10) [control]: plain --status shows each kind as recorded, the detail at the same column" \
   "$(_ngd_has "$(_ngd_l4 old)" deployed-unverified)|$(_ngd_has "$(_ngd_l4 new)" deploy-failed)|$([ "$(_ngd_col old)" -gt 0 ] 2>/dev/null && [ "$(_ngd_col old)" = "$(_ngd_col new)" ] && echo same)" "yes|yes|same"
is "ngd A68 (K10) [control]: felix land --prs names the newest row, kind as recorded, with the same detail, for either kind" \
   "$(_ngd_cl old)~$(_ngd_cl new)" "; last ledger row 2026-11-07T08:10:00Z deployed-unverified: gate: felix gate --quick exited 1 in the home~; last ledger row 2026-11-07T08:10:00Z deploy-failed: gate: felix gate --quick exited 1 in the home"
_ngd_led b1 deployed-unverified deploy-failed; _ngd_led b2 deploy-failed deployed-unverified
is "ngd A69 (K10) [control]: a ledger holding both kinds lists its newest row as recorded whichever kind it is and whichever came first, in both forms of --status and in --prs" \
   "$(sed -n 4p "$NGD/b1.stt" | cut -f3)$(_ngd_has "$(_ngd_l4 b1)" deploy-failed)$(_ngd_has "$(_ngd_cl b1)" deploy-failed:)|$(sed -n 4p "$NGD/b2.stt" | cut -f3)$(_ngd_has "$(_ngd_l4 b2)" deployed-unverified)$(_ngd_has "$(_ngd_cl b2)" deployed-unverified:)" \
   "deploy-failedyesyes|deployed-unverifiedyesyes"
NGNOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
_ngd_waits() {   # KIND -> felix_start_waits over a ledger of a waiting row for 77 and a later KIND row: its waits_line
  rm -rf "$NGD/wmem"; mkdir -p "$NGD/wmem/ngdk/land"
  { printf '%s\twaiting\t77\t%s\t-\t0\twaits on a session since %s: session: no checkout holds the gated head\n' "$NGNOW" "$(_lg_sha 77)" "$NGNOW"
    printf '%s\t%s\t-\t-\t-\t4\tgate: felix gate --quick exited 1 in the home\n' "$NGNOW" "$1"; } > "$NGD/wmem/ngdk/land/ledger.tsv"
  FELIX_MEMORY="$NGD/wmem" bash -c '. "$1/lib/resolve.sh" >/dev/null 2>&1; . "$1/lib/waiting.sh" >/dev/null 2>&1
    felix_start_waits "$2" ngdk; printf "%s" "$waits_line"' _ "$FROOT/harness" "$NGD/wproj/ngdk" 2>/dev/null
}
NGWO="$(_ngd_waits deployed-unverified)"; NGWN="$(_ngd_waits deploy-failed)"
is "ngd A70 (K10) [control]: the session-start list of waiting pull requests is the same beside a row of either kind, and names #77" \
   "$([ "$NGWO" = "$NGWN" ] && echo same)|$(_ngd_has "$NGWO" '#77')" "same|yes"

_lg_reset; rm -rf "${LGH:?}/state"
is "ngd A71 (K7) [fixture control]: the part leaves the home on main at origin's main, tracking it, with no tracked change, and main's check accepting its entry" \
   "$(git -C "$LGH" rev-parse --abbrev-ref HEAD 2>&1)|$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" rev-parse --abbrev-ref 'main@{upstream}' 2>&1)|$(git -C "$LGH" status --porcelain --untracked-files=no 2>&1)|$(_la_accepts)" \
   "main|$(git -C "$LGO" rev-parse main 2>&1)|origin/main||0"
rm -rf "${NGP:?}" "${MEM:?}/ngdw"
