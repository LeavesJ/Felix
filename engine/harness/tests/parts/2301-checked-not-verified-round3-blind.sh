# >>> checked-not-verified-round3
printf '\nchecked, not verified, round 3: each receipt case gets a true word, and no text says proves (C1, C8, C11, C15-C18, C20-C23; blind)\n'
# Blind, written on 2026-10-31 from docs/2026-10-31-checked-not-verified-contract.md alone, as amended for round 3
# (cd46a9ee), before round 3 existed: its sentences marked Round 3 and the clauses it amends or adds, C1, C8, C11,
# C15, C16, C17, C18, C20, C21, C22 and C23, and its section What stays outside the class. No other branch, commit or
# diff was read. Engine source at cd46a9ee (round 1) was read only as far as calling it needs: a name, its arguments,
# the files it reads; beyond that, the round-1 text of each sentence a clause rewrites, so the old text can be refused,
# and, for C8's controls, the values lib/receipt.sh prints for the cases round 3 leaves alone. Assertion names start
# `cnv3 A`; each says which clause it holds.
#
# Behaviour where a fixture reaches it: felix help (C1), felix receipt over gate receipts written by
# felix_verify_record (C8), felix_stop_debt and hooks/stop in a cloud session (C15), hooks/subagent-stop (C16),
# felix_probe_state (lib/probes.sh) and felix probes (C20), and the notifier's _fn_step_issue against a gh stub (C21),
# each from $REAL_HARNESS (the CLI and the hooks from a content copy of it in this part's own home). Text where
# behaviour is out of reach, read from the files under test: the engine is the parent of $REAL_HARNESS and the
# repository root (README.md, docs/) is its parent. C11 (no caller prints the reason), C17 (engine/commands/felix.md),
# C22 (README.md) and C23 (docs/handoff/). C18 is a check this part implements (_cnv3_check) and runs over the engine
# under test and over fixtures.
#
# Readings, where the contract leaves room:
# - A clause that changes words asserts the new text and the old text both, so it cannot pass by finding neither.
# - C1: "its first line" is the first line felix help prints; the receipt line round 1 wrote is a control.
# - C8: gate receipts are written by felix_verify_record as a black box (status 1 is red). "Resting on facts that
#   have moved" is a green receipt for this exact tree recorded with an epoch and components (its eighth and ninth
#   arguments) that the checkout does not have now. A red receipt for this exact tree with an evidence gap is failed:
#   evidence-owed needs a green result. A red receipt for this exact tree whose facts moved is not asserted, since
#   failed's sentence and unchecked's both reach it. Evidence is owed by a change to src/safe/x.js under a project
#   whose risk.tsv makes ^src/safe/ green and whose evidence.tsv wants a test for ^src/. Blocked is a change under
#   .github/workflows/ with a red receipt for the exact tree; indeterminate is a base that names nothing with the same.
#   The controls' evidence_quality (checked high, blocked high, indeterminate unknown) is what cd46a9ee prints, which
#   the clause keeps ("every other field unchanged").
# - C11: source text; one line of lib/green-tick.sh holds the sentence whole.
# - C15: felix_stop_debt for the reasons failed, never checked and epoch moved, and the hook's own debt stop of a
#   cloud session held on a tree the gate ran red on. The whole message is asserted with the reason in parentheses;
#   its other sentences are the ones the clause leaves unchanged.
# - C16: the hook's additionalContext, JSON-decoded, with every run of blanks and line breaks folded to one space, so
#   a rewrap of the body does not decide. The red tree is a checkout whose current tree has a red gate receipt.
# - C17: step 2's first line is a whole line, leading blanks aside, and the next line begins `the code is wrong.`.
# - C18: as part 2300 reads it (allowed names removed with nothing in their place; lines named FILE:LINE:TEXT; files in
#   byte order; a directory outside a work tree read whole), with the round-3 ERE. The obligations control is the
#   engine's own lines that hold the contract's three phrases, copied to a fixture.
# - C20: felix_probe_state ROOT - PROBE WITNESS, with the probe false, exit 3 or true and the witness true; its output
#   compared whole. felix probes over a fixture project whose two rows are those cases.
# - C21: _fn_step_issue called with _FN_T, _FN_REPO, _FN_POSTER and _FN_DIR set and a gh stub on PATH that answers
#   issue list with no issue; the body's line breaks are folded to spaces before the phrase is sought.
# - C22: the row is the line that starts `| Subagent stop |`, and the clause's text is how it ends.
# - C23: "no tracked document plans a /2 other than this one" is read over the build queue, docs/handoff/: no tracked
#   file there names felix.receipt/2. A document elsewhere that names /2 as the receipt's schema plans nothing.
CNV3="$TMP/cnv3"; mkdir -p "$CNV3"; CNV3="$(cd "$CNV3" && pwd -P)"
CNV3H="$CNV3/home"; CNV3M="$CNV3/mem"; CNV3U="$CNV3/user"
CNV3_CP="$CNV3H/projects/cp"; CNV3_CE="$CNV3H/projects/ce"; CNV3_CB="$CNV3H/projects/cb"
mkdir -p "$CNV3_CP" "$CNV3_CE" "$CNV3_CB" "$CNV3M" "$CNV3U" "$CNV3/plain" "$CNV3/ghbin" "$CNV3/fn"
_copy_content "$REAL_HARNESS" "$CNV3H/harness"
printf '{"name": "cp", "gate": "true"}\n' > "$CNV3_CP/project.json"; printf '# cp\n' > "$CNV3_CP/CLAUDE.md"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$CNV3_CP/probes.tsv"
cp "$REAL_HARNESS/templates/risk.tsv" "$CNV3_CP/risk.tsv"
printf '{"name": "ce", "gate": "true"}\n' > "$CNV3_CE/project.json"; printf '# ce\n' > "$CNV3_CE/CLAUDE.md"
cp "$CNV3_CP/probes.tsv" "$CNV3_CE/probes.tsv"
{ cat "$REAL_HARNESS/templates/risk.tsv"; printf 'green\tpath\t^src/safe/\tdeclared safe by this project\n'; } > "$CNV3_CE/risk.tsv"
printf 'unit\t^src/\t^tests?/\tcode changes need a test\n' > "$CNV3_CE/evidence.tsv"
printf '{"name": "cb", "gate": "true"}\n' > "$CNV3_CB/project.json"; printf '# cb\n' > "$CNV3_CB/CLAUDE.md"
cp "$REAL_HARNESS/templates/risk.tsv" "$CNV3_CB/risk.tsv"
printf 'exits\t-\t-\tfalse\ttrue\nnone\t-\t-\ttrue\ttrue\n' > "$CNV3_CB/probes.tsv"
CNV3_VLOG="$CNV3M/cp/verification.log"
CNV3_ENG="$(cd "$REAL_HARNESS/.." && pwd -P)"; CNV3_ROOT="$(cd "$CNV3_ENG/.." && pwd -P)"

# ---- helpers ----
_cnv3_repo() {   # DIR PROJECT -> a checkout of PROJECT at DIR, .felix and WORK.txt committed on main
  mkdir -p "$1"
  ( _fx_cd "$1" && git init -q -b main && printf '%s\n' "$2" > .felix && printf 'base\n' > WORK.txt && git add -A \
    && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm base ) >/dev/null 2>&1
}
_cnv3_commit() { ( _fx_cd "$1" && git add -A && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm "$2" ) >/dev/null 2>&1; }
_cnv3_lib() { ( export FELIX_HOME="$CNV3H" FELIX_MEMORY="$CNV3M" HOME="$CNV3U"
                . "$REAL_HARNESS/lib/resolve.sh"; . "$REAL_HARNESS/lib/verify.sh"; "$@" ); }
_cnv3_cli() {   # DIR ARGS... -> what the home's felix printed in DIR, both streams
  local d="$1"; shift
  ( cd "${d:?}" && env -u CLAUDE_CODE_REMOTE HOME="$CNV3U" FELIX_HOME="$CNV3H" FELIX_MEMORY="$CNV3M" "$CNV3H/harness/felix" "$@" 2>&1 )
}
_cnv3_tid() { _cnv3_lib felix_tree_id "$1" "$CNV3H" 2>/dev/null; }
_cnv3_rec() {   # ROOT RC TID [REPORTED EPOCH COMPS] -> a gate receipt for TID with that status, by felix_verify_record
  local r="$1" rc="$2" t="$3"; shift 3
  _cnv3_lib felix_verify_record "$r" "$CNV3H" "$rc" cnv3-gate "$t" "" "$@" >/dev/null 2>&1
}
_cnv3_yn() { if [ "$1" -gt 0 ] 2>/dev/null; then printf yes; else printf no; fi; }
_cnv3_in() { case "$1" in *"$2"*) printf yes ;; *) printf no ;; esac; }
_cnv3_hasl() { case "
$1
" in *"
$2
"*) printf yes ;; *) printf no ;; esac; }
# FILE NEEDLE -> lines of FILE holding NEEDLE
_cnv3_cnt() { CNV3_NEEDLE="$2" LC_ALL=C awk 'index($0, ENVIRON["CNV3_NEEDLE"]) { n++ } END { print n + 0 }' "$1" 2>/dev/null || printf 0; }
_cnv3_ws() { LC_ALL=C awk '{ for (i = 1; i <= NF; i++) { printf "%s%s", (n ? " " : ""), $i; n = 1 } }' <<< "$1"; }
_cnv3_rows() { [ -f "$1" ] || { printf 0; return 0; }; LC_ALL=C awk 'END { print NR + 0 }' "$1" 2>/dev/null || printf 0; }
_cnv3_tree() {   # PID -> it and everything below it
  ps -A -o pid= -o ppid= 2>/dev/null | LC_ALL=C awk -v root="$1" '
    { kids[$2] = kids[$2] " " $1 }
    END { q = root; out = ""
          while (q != "") { n = split(q, a, " "); q = ""
                            for (i = 1; i <= n; i++) if (a[i] != "") { out = out " " a[i]; q = q kids[a[i]] } }
          print out }'
}
# HOOK DIR PAYLOAD [NAME=value ...] -> one hook run in DIR, killed with its tree at 30 s (exit 124). CNV3_RC, CNV3_O
# (stdout), CNV3_NV (rows it added to cp's verification.log) and CNV3_LV (the last of them).
_cnv3_run() {
  local hook="$1" dir="$2" pay="$3" pid n=0 k v0
  shift 3
  v0="$(_cnv3_rows "$CNV3_VLOG")"
  rm -f "$CNV3/h.o" "$CNV3/h.e" "$CNV3/h.rc"
  ( cd "${dir:?}" && printf '%s' "$pay" \
      | env -u FELIX_ALLOW_RED -u CLAUDE_CODE_REMOTE -u CLAUDE_CODE_SESSION_ID FELIX_HOME="$CNV3H" FELIX_MEMORY="$CNV3M" HOME="$CNV3U" \
            "$@" "$hook" > "$CNV3/h.o" 2> "$CNV3/h.e"
    echo "$?" > "$CNV3/h.rc" ) &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$n" -lt 300 ]; do sleep 0.1; n=$((n + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    for k in $(_cnv3_tree "$pid"); do kill -9 "$k" 2>/dev/null; done
    wait "$pid" 2>/dev/null; CNV3_RC=124
  else
    wait "$pid" 2>/dev/null; CNV3_RC="$(cat "$CNV3/h.rc" 2>/dev/null)"; CNV3_RC="${CNV3_RC:-none}"
  fi
  CNV3_O="$(cat "$CNV3/h.o" 2>/dev/null)"
  CNV3_NV=$(( $(_cnv3_rows "$CNV3_VLOG") - v0 ))
  CNV3_LV=""; [ "$CNV3_NV" -gt 0 ] && CNV3_LV="$(tail -n 1 "$CNV3_VLOG" 2>/dev/null)"
  return 0
}
_cnv3_stop() {   # DIR SID FLAG [NAME=value ...] -> one Stop hook run
  local d="$1" sid="$2" flag="$3"; shift 3
  _cnv3_run "$CNV3H/harness/hooks/stop" "$d" "$(printf '{"hook_event_name":"Stop","stop_hook_active":%s,"session_id":"%s"}' "$flag" "$sid")" "$@"
}
_cnv3_f() { cut -f"$1" <<< "$CNV3_LV"; }
# What the last run did: <block|silent|other>:<exit status>:<rows added>:<field 2 of the last row, or ->
_cnv3_sum() {
  local kind v="-"
  case "$CNV3_O" in '') kind=silent ;; *'"decision"'*'"block"'*) kind=block ;; *) kind=other ;; esac
  [ "$CNV3_NV" -gt 0 ] && v="$(_cnv3_f 2)"
  printf '%s:%s:%s:%s' "$kind" "$CNV3_RC" "$CNV3_NV" "$v"
}
_cnv3_jf() {   # JSON PATH -> the field, a string as it is and anything else as JSON
  python3 -c 'import json, sys
d = json.loads(sys.stdin.read())
for p in sys.argv[1].split("."): d = d[p]
print(d if isinstance(d, str) else json.dumps(d))' "$2" <<< "$1" 2>/dev/null
}
_cnv3_ctx() {   # HOOK-OUTPUT -> its additionalContext decoded, or the output as it is when it is not that JSON
  python3 -c 'import json, sys
s = sys.stdin.read()
try:
    print(json.loads(s)["hookSpecificOutput"]["additionalContext"])
except Exception:
    print(s)' <<< "$1" 2>/dev/null
}
# RECEIPT -> status, evidence_quality, verification state and result
_cnv3_rs() {
  printf 'status=%s quality=%s state=%s result=%s' "$(_cnv3_jf "$1" status)" "$(_cnv3_jf "$1" confidence.evidence_quality)" \
    "$(_cnv3_jf "$1" verification.state)" "$(_cnv3_jf "$1" verification.result)"
}
# TEXT -> yes when TEXT, lower-cased, holds verified or unverified as a word
_cnv3_vword() { LC_ALL=C awk 'tolower($0) ~ /(^|[^a-z0-9_])(un)?verified([^a-z0-9_]|$)/ { n++ } END { print (n ? "yes" : "no") }' <<< "$1"; }
# TEXT -> yes when TEXT, lower-cased, holds proves as a word
_cnv3_pword() { LC_ALL=C awk 'tolower($0) ~ /(^|[^a-z0-9_])proves([^a-z0-9_]|$)/ { n++ } END { print (n ? "yes" : "no") }' <<< "$1"; }

# C18's check. The allowed names, one a line, read as bytes by the check's awk (getline), never through awk -v,
# which would turn the backslash and t of 'unverified\t into a tab; the ERE through ENVIRON, for the same reason.
# Round 4, not blind (K12 of docs/2026-11-07-not-green-deploy-failed-contract.md): the two kinds that moved are no longer allowed
# everywhere; the old ledger kind is allowed as notify.sh's case label, the old blocker kind as green-install.sh's clause.
# Round 5, not blind (K12, K14): and, in green-tick.sh, as the text by which the quiet check reads a refusal recorded before.
printf '%s\n' 'state/verified' 'subagent-unverified' > "$CNV3/allowed"
printf '%s\t%s\n' 'harness/lib/verify.sh' 'never verified' 'harness/lib/notify.sh' 'deployed-unverified)' \
  'harness/lib/green-install.sh' '$1 == "unverified"' 'harness/lib/green-tick.sh' 'old="  unverified  ${b#"  not-green   "}"' > "$CNV3/allowed-in"
CNV3_ERE='(^|[^a-z0-9_])((un)?(verified|proven)|proves)([^a-z0-9_]|$)'
CNV3_ERE1='(^|[^a-z0-9_])(un)?(verified|proven)([^a-z0-9_]|$)'
_cnv3_list() {   # DIR -> the files the check reads, relative to DIR, in byte order, harness/tests/ left out
  if [ "$(git -C "$1" rev-parse --is-inside-work-tree 2>/dev/null)" = true ]; then
    git -C "$1" ls-files -z -- . 2>/dev/null | tr '\0' '\n'
  else
    ( cd "${1:?}" && find . -type f 2>/dev/null | sed 's|^\./||' )
  fi | LC_ALL=C awk 'index($0, "harness/tests/") != 1' | LC_ALL=C sort
}
_cnv3_check() {   # DIR [ERE] -> FILE:LINE:TEXT for each line the check fails on; 0 when none, 1 when some, 2 when nothing to read
  local d="$1" re="${2:-$CNV3_ERE}" f n=0 files=()
  [ -d "$d" ] || return 2
  while IFS= read -r f; do
    [ -n "$f" ] && [ -f "$d/$f" ] || continue
    files[n]="$d/$f"; n=$((n + 1))
  done < <(_cnv3_list "$d")
  [ "$n" -gt 0 ] || return 2
  CNV3_PRE="$d/" CNV3_RE="$re" LC_ALL=C awk -v A="$CNV3/allowed" -v B="$CNV3/allowed-in" '
    BEGIN { k = 0; while ((getline l < A) > 0) if (l != "") al[++k] = l; close(A); p = ENVIRON["CNV3_PRE"]; re = ENVIRON["CNV3_RE"]
            m = 0; while ((getline l < B) > 0) if ((q = index(l, "\t")) > 1) { bf[++m] = substr(l, 1, q - 1); bn[m] = substr(l, q + 1) }
            close(B) }
    { s = $0; sub(/^[ \t]+/, "", s); if (substr(s, 1, 1) == "#") next
      t = $0
      for (i = 1; i <= k; i++) while ((j = index(t, al[i])) > 0) t = substr(t, 1, j - 1) substr(t, j + length(al[i]))
      f = FILENAME; if (index(f, p) == 1) f = substr(f, length(p) + 1)
      for (i = 1; i <= m; i++) if (bf[i] == f) while ((j = index(t, bn[i])) > 0) t = substr(t, 1, j - 1) substr(t, j + length(bn[i]))
      t = tolower(t)
      if (t ~ re) { printf "%s:%d:%s\n", f, FNR, $0; hit = 1 }
    }
    END { exit (hit ? 1 : 0) }' "${files[@]}"
}

# ---- C1: felix help --------------------------------------------------------------------------------------------------
CNV3_HELP="$(_cnv3_cli "$CNV3/plain" help)"
is "cnv3 A1 (C1): felix help's first line is [Felix. The engineering OS: it decides how work gets built, and runs the gate that checks it.], and no line of it ends and proves it." \
   "[$(LC_ALL=C awk 'NR == 1' <<< "$CNV3_HELP")] old=$(_cnv3_in "$CNV3_HELP" 'and proves it.') proves=$(_cnv3_pword "$CNV3_HELP")" \
   "[Felix. The engineering OS: it decides how work gets built, and runs the gate that checks it.] old=no proves=no"
is "cnv3 A2 (C1, control): felix help still prints round 1's receipt line and the obligation what a fix must prove" \
   "receipt=$(_cnv3_hasl "$CNV3_HELP" '    felix receipt          what changed, its risk, and whether anything checked it') obligation=$(_cnv3_in "$CNV3_HELP" 'what a fix must prove')" \
   "receipt=yes obligation=yes"

# ---- C8: felix receipt ------------------------------------------------------------------------------------------------
_cnv3_rcpt() { _cnv3_cli "$1" receipt --base "$2"; }
CNV3_NOBASE=deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
# A docs change under cp: failed, checked, unchecked three ways, and indeterminate over a red receipt.
CNV3RC="$CNV3/rc"; _cnv3_repo "$CNV3RC" cp; CNV3RC="$(cd "$CNV3RC" && pwd -P)"
CNV3_RB="$(git -C "$CNV3RC" rev-parse HEAD 2>/dev/null)"
printf 'notes\n' > "$CNV3RC/README.md"; _cnv3_commit "$CNV3RC" docs; CNV3_RT="$(_cnv3_tid "$CNV3RC")"
_cnv3_rec "$CNV3RC" 1 "$CNV3_RT"
CNV3_R_FAIL="$(_cnv3_rcpt "$CNV3RC" "$CNV3_RB")"; CNV3_R_FIND="$(_cnv3_rcpt "$CNV3RC" "$CNV3_NOBASE")"
_cnv3_rec "$CNV3RC" 0 "$CNV3_RT"; CNV3_R_CHK="$(_cnv3_rcpt "$CNV3RC" "$CNV3_RB")"
_cnv3_rec "$CNV3RC" 0 "$CNV3_RT" "" cnv3-an-epoch-that-moved 's1,t1,p1,r1'; CNV3_R_EPO="$(_cnv3_rcpt "$CNV3RC" "$CNV3_RB")"
_cnv3_rec "$CNV3RC" 1 "$CNV3_RT"; printf 'edited after the gate\n' >> "$CNV3RC/README.md"
CNV3_R_ROT="$(_cnv3_rcpt "$CNV3RC" "$CNV3_RB")"
rm -f "$(_cnv3_lib _felix_receipt_path "$CNV3RC" "$CNV3H" 2>/dev/null)"; CNV3_R_NONE="$(_cnv3_rcpt "$CNV3RC" "$CNV3_RB")"
# A change to src/safe/x.js under ce, which owes a test: green then red on that exact tree.
CNV3RE="$CNV3/re"; _cnv3_repo "$CNV3RE" ce; CNV3RE="$(cd "$CNV3RE" && pwd -P)"
CNV3_EB="$(git -C "$CNV3RE" rev-parse HEAD 2>/dev/null)"
mkdir -p "$CNV3RE/src/safe"; printf 'x\n' > "$CNV3RE/src/safe/x.js"; _cnv3_commit "$CNV3RE" safe; CNV3_ET="$(_cnv3_tid "$CNV3RE")"
_cnv3_rec "$CNV3RE" 0 "$CNV3_ET"; CNV3_R_EVO="$(_cnv3_rcpt "$CNV3RE" "$CNV3_EB")"
_cnv3_rec "$CNV3RE" 1 "$CNV3_ET"; CNV3_R_EVF="$(_cnv3_rcpt "$CNV3RE" "$CNV3_EB")"
# A workflow change under cp, which escapes, with a red receipt on that exact tree.
CNV3RB="$CNV3/rb"; _cnv3_repo "$CNV3RB" cp; CNV3RB="$(cd "$CNV3RB" && pwd -P)"
CNV3_BB="$(git -C "$CNV3RB" rev-parse HEAD 2>/dev/null)"
mkdir -p "$CNV3RB/.github/workflows"; printf 'on: push\n' > "$CNV3RB/.github/workflows/cnv3.yml"; _cnv3_commit "$CNV3RB" ci
_cnv3_rec "$CNV3RB" 1 "$(_cnv3_tid "$CNV3RB")"; CNV3_R_BLK="$(_cnv3_rcpt "$CNV3RB" "$CNV3_BB")"
is "cnv3 A3 (C8): a red gate receipt for this exact tree gives status failed, evidence_quality low, under schema felix.receipt/2" \
   "schema=$(_cnv3_jf "$CNV3_R_FAIL" schema) $(_cnv3_rs "$CNV3_R_FAIL")" \
   "schema=felix.receipt/2 status=failed quality=low state=current result=red"
is "cnv3 A4 (C8): a current green gate receipt for this exact tree with an evidence gap gives status evidence-owed, evidence_quality low" \
   "$(_cnv3_rs "$CNV3_R_EVO") gap=$(_cnv3_in "$(_cnv3_jf "$CNV3_R_EVO" evidence.gap)" '"')" \
   "status=evidence-owed quality=low state=current result=green gap=yes"
is "cnv3 A5 (C8): a red gate receipt for this exact tree that also has an evidence gap gives status failed, not evidence-owed, evidence_quality low" \
   "$(_cnv3_rs "$CNV3_R_EVF") gap=$(_cnv3_in "$(_cnv3_jf "$CNV3_R_EVF" evidence.gap)" '"')" \
   "status=failed quality=low state=current result=red gap=yes"
is "cnv3 A6 (C8, control): a current green gate receipt for this exact tree with no evidence gap still gives status checked, evidence_quality high" \
   "$(_cnv3_rs "$CNV3_R_CHK") gap=$(_cnv3_jf "$CNV3_R_CHK" evidence.gap)" \
   "status=checked quality=high state=current result=green gap=[]"
is "cnv3 A7 (C8, control): status unchecked, evidence_quality low, where there is no gate receipt and where a green one for this exact tree rests on facts that have moved" \
   "none: $(_cnv3_rs "$CNV3_R_NONE"); moved: $(_cnv3_rs "$CNV3_R_EPO")" \
   "none: status=unchecked quality=low state=none result=null; moved: status=unchecked quality=low state=stale result=green"
is "cnv3 A8 (C8, control): a red gate receipt for another tree (stale) gives status unchecked, not failed, evidence_quality low" \
   "$(_cnv3_rs "$CNV3_R_ROT")" "status=unchecked quality=low state=stale result=red"
is "cnv3 A9 (C8, control): blocked and indeterminate keep their precedence over failed: an escaping change with a red receipt for its tree is blocked (high), and a base that names nothing is indeterminate (unknown)" \
   "blocked: status=$(_cnv3_jf "$CNV3_R_BLK" status) quality=$(_cnv3_jf "$CNV3_R_BLK" confidence.evidence_quality) result=$(_cnv3_jf "$CNV3_R_BLK" verification.result); nobase: status=$(_cnv3_jf "$CNV3_R_FIND" status) quality=$(_cnv3_jf "$CNV3_R_FIND" confidence.evidence_quality) known=$(_cnv3_jf "$CNV3_R_FIND" changed.known)" \
   "blocked: status=blocked quality=high result=red; nobase: status=indeterminate quality=unknown known=false"
is "cnv3 A10 (C8, control): none of the eight receipts holds verified or unverified as a word, in its status, its keys or its limits" \
   "$(_cnv3_vword "$CNV3_R_FAIL") $(_cnv3_vword "$CNV3_R_EVO") $(_cnv3_vword "$CNV3_R_EVF") $(_cnv3_vword "$CNV3_R_CHK") $(_cnv3_vword "$CNV3_R_NONE") $(_cnv3_vword "$CNV3_R_EPO") $(_cnv3_vword "$CNV3_R_ROT") $(_cnv3_vword "$CNV3_R_BLK")" \
   "no no no no no no no no"

# ---- C11: the tick's deploy-owed reason (text: nothing prints it) -----------------------------------------------------
CNV3_GT="$REAL_HARNESS/lib/green-tick.sh"
is "cnv3 A11 (C11): lib/green-tick.sh gives the deploy-owed reason [the home checkout is not at origin/main, so main's engine has not been deployed from it and checked], and not round 1's [the engine it holds has not been deployed and checked]" \
   "new=$(_cnv3_yn "$(_cnv3_cnt "$CNV3_GT" "the home checkout is not at origin/main, so main's engine has not been deployed from it and checked")") old=$(_cnv3_yn "$(_cnv3_cnt "$CNV3_GT" 'the engine it holds has not been deployed and checked')")" \
   "new=yes old=no"

# ---- C15: the cloud debt message --------------------------------------------------------------------------------------
_cnv3_msg() { printf '%s' "This cloud session was let go with the gate not passed on this tree ($1). Felix held it once and the gate did not run. The record of that sits in this session's memory, which ends with the VM, so nothing outside it says the gate has not passed on this work. Run the gate before the VM goes, or open a pull request so CI judges the branch."; }
_cnv3_debt() {   # REASON [NAME=value ...] -> what felix_stop_debt cp REASON cnv3-debt-1 printed
  local r="$1"; shift
  ( cd "${CNV3:?}/plain" && env -u CLAUDE_CODE_REMOTE FELIX_HOME="$CNV3H" FELIX_HOME_DIR="$CNV3H" FELIX_MEMORY="$CNV3M" HOME="$CNV3U" "$@" /bin/bash -c '
      . "$1/lib/resolve.sh"; . "$1/lib/verify.sh"; . "$1/lib/hook-faults.sh"; . "$1/lib/say.sh"
      felix_stop_debt "$2" "$3" cnv3-debt-1' dt "$REAL_HARNESS" "$CNV3_CP" "$r" 2>/dev/null )
}
CNV3_D1="$(_cnv3_debt failed CLAUDE_CODE_REMOTE=true)"
is "cnv3 A12 (C15): felix_stop_debt for the reason failed, in a cloud session, ends its third sentence [so nothing outside it says the gate has not passed on this work.], the reason (failed) in parentheses, and never says went unchecked" \
   "new=$(_cnv3_in "$CNV3_D1" "$(_cnv3_msg failed)") old=$(_cnv3_in "$CNV3_D1" 'went unchecked')" "new=yes old=no"
CNV3_D2="$(_cnv3_debt 'never checked' CLAUDE_CODE_REMOTE=true)"
is "cnv3 A13 (C15): felix_stop_debt for the reason never checked says the same third sentence, (never checked) in parentheses, and never says went unchecked" \
   "new=$(_cnv3_in "$CNV3_D2" "$(_cnv3_msg 'never checked')") old=$(_cnv3_in "$CNV3_D2" 'went unchecked')" "new=yes old=no"
CNV3_D3="$(_cnv3_debt 'epoch moved' CLAUDE_CODE_REMOTE=true)"
is "cnv3 A14 (C15): felix_stop_debt for the reason epoch moved says the same third sentence, (epoch moved) in parentheses, and never says went unchecked" \
   "new=$(_cnv3_in "$CNV3_D3" "$(_cnv3_msg 'epoch moved')") old=$(_cnv3_in "$CNV3_D3" 'went unchecked')" "new=yes old=no"
is "cnv3 A15 (C15, control): felix_stop_debt for the reason failed outside a cloud session prints nothing" "[$(_cnv3_debt failed)]" "[]"
# Through the hook: a cloud session stops on a tree the gate ran red on, is held, then stops again and is let go.
CNV3CR="$CNV3/cr"; _cnv3_repo "$CNV3CR" cp; CNV3CR="$(cd "$CNV3CR" && pwd -P)"; printf 'one more line\n' >> "$CNV3CR/WORK.txt"
CNV3_CT="$(_cnv3_tid "$CNV3CR")"; _cnv3_rec "$CNV3CR" 1 "$CNV3_CT"
_cnv3_stop "$CNV3CR" cnv3-redcloud false CLAUDE_CODE_REMOTE=true; CNV3_A16="$(_cnv3_sum)|$(_cnv3_f 3)|$(_cnv3_f 4)"
is "cnv3 A16 (C15, control): a cloud session's first stop on a tree whose gate receipt for that exact tree is red is held, with a blocked row whose reason is failed" \
   "$CNV3_A16" "block:0:1:blocked|$CNV3_CT|failed"
_cnv3_stop "$CNV3CR" cnv3-redcloud true CLAUDE_CODE_REMOTE=true; _cnv3_stop "$CNV3CR" cnv3-redcloud false CLAUDE_CODE_REMOTE=true
is "cnv3 A17 (C15): that session's debt stop writes the debt row for failed and prints the message with (failed) and [so nothing outside it says the gate has not passed on this work.], not went unchecked" \
   "$(_cnv3_sum)|$(_cnv3_f 4)|new=$(_cnv3_in "$CNV3_O" "$(_cnv3_msg failed)") old=$(_cnv3_in "$CNV3_O" 'went unchecked')" \
   "other:0:1:debt|failed; held once on this tree already (session cnv3-red)|new=yes old=no"

# ---- C16: the SubagentStop message ------------------------------------------------------------------------------------
CNV3_SUBNEW='must say so plainly: partial, failing, or unchecked — not done, working, or passing.'
CNV3SR="$CNV3/sr"; _cnv3_repo "$CNV3SR" cp; CNV3SR="$(cd "$CNV3SR" && pwd -P)"; printf 'subagent work\n' >> "$CNV3SR/WORK.txt"
_cnv3_rec "$CNV3SR" 1 "$(_cnv3_tid "$CNV3SR")"
_cnv3_run "$CNV3H/harness/hooks/subagent-stop" "$CNV3SR" '{"hook_event_name":"SubagentStop","session_id":"cnv3-sub-red","stop_hook_active":false}'
CNV3_S1RC="$CNV3_RC"; CNV3_S1="$(_cnv3_ws "$(_cnv3_ctx "$CNV3_O")")"
is "cnv3 A18 (C16): the SubagentStop hook on a checkout whose tree the gate ran red on says [$CNV3_SUBNEW], and neither partial, or unchecked nor partial, or unverified" \
   "new=$(_cnv3_in "$CNV3_S1" "$CNV3_SUBNEW") round1=$(_cnv3_in "$CNV3_S1" 'partial, or unchecked') old=$(_cnv3_in "$CNV3_S1" 'partial, or unverified')" \
   "new=yes round1=no old=no"
is "cnv3 A19 (C16, control): on that red tree the hook speaks: status 0 and its unchanged first sentence" \
   "rc=$CNV3_S1RC first=$(_cnv3_in "$CNV3_S1" 'A subagent report is about to be integrated, and this checkout holds changes no gate has passed on.')" \
   "rc=0 first=yes"
CNV3SN="$CNV3/sn"; _cnv3_repo "$CNV3SN" cp; CNV3SN="$(cd "$CNV3SN" && pwd -P)"; printf 'subagent work\n' >> "$CNV3SN/WORK.txt"
_cnv3_run "$CNV3H/harness/hooks/subagent-stop" "$CNV3SN" '{"hook_event_name":"SubagentStop","session_id":"cnv3-sub-none","stop_hook_active":false}'
CNV3_S2="$(_cnv3_ws "$(_cnv3_ctx "$CNV3_O")")"
is "cnv3 A20 (C16): the SubagentStop hook on a checkout no gate has run on says the same sentence, and not partial, or unchecked" \
   "rc=$CNV3_RC new=$(_cnv3_in "$CNV3_S2" "$CNV3_SUBNEW") round1=$(_cnv3_in "$CNV3_S2" 'partial, or unchecked')" \
   "rc=0 new=yes round1=no"

# ---- C17: the /felix command (text) -----------------------------------------------------------------------------------
CNV3_CMD="$CNV3_ENG/commands/felix.md"
is "cnv3 A21 (C17): engine/commands/felix.md's step 2 begins [2. Work out what checks this project — the command that fails when] / [the code is wrong.], and nothing says Work out what would prove this project correct" \
   "$(CNV3_N1='2. Work out what checks this project — the command that fails when' LC_ALL=C awk '
        { s = $0; sub(/^[ \t]+/, "", s) }
        p { if (index(s, "the code is wrong.") == 1) n2++; p = 0 }
        s == ENVIRON["CNV3_N1"] { n1++; p = 1 }
        END { printf "first=%d second=%d", n1, n2 }' "$CNV3_CMD" 2>/dev/null) old=$(_cnv3_cnt "$CNV3_CMD" 'Work out what would prove this project correct')" \
   "first=1 second=1 old=0"
is "cnv3 A22 (C17, control): engine/commands/felix.md still ends [this is a tool whose entire value is that it refuses to report success it has] / [not checked.]" \
   "$(LC_ALL=C awk 'NF { a = b; b = $0 } END { printf "%s / %s", a, b }' "$CNV3_CMD" 2>/dev/null)" \
   "this is a tool whose entire value is that it refuses to report success it has / not checked."

# ---- C18: the class, now with proves ----------------------------------------------------------------------------------
CNV3_C1="$(_cnv3_check "$CNV3_ENG")"; CNV3_C1R=$?; CNV3_C1N="$(_cnv3_list "$CNV3_ENG" | LC_ALL=C awk 'END { print NR + 0 }')"
is "cnv3 A23 (C18): the check with the round-3 ERE over the engine under test (the parent of REAL_HARNESS, harness/tests/ aside, tracked files in a work tree) reads many files and names no line" \
   "files=$([ "${CNV3_C1N:-0}" -ge 50 ] && printf many || printf '%s' "$CNV3_C1N") rc=$CNV3_C1R [$CNV3_C1]" "files=many rc=0 []"
CNV3_C1B="$(_cnv3_check "$CNV3_ENG" "$CNV3_ERE1")"; CNV3_C1BR=$?
is "cnv3 A24 (C18, control): the same check with round 1's ERE, without proves, still passes over the engine under test" \
   "rc=$CNV3_C1BR [$CNV3_C1B]" "rc=0 []"
mkdir -p "$CNV3/c18a/b" "$CNV3/c18b" "$CNV3/c18c/harness/lib" "$CNV3/c18d/harness/lib"
printf '%s\n' "printf 'Proves the claim\\n'" > "$CNV3/c18a/a.sh"
printf '%s\n' 'ok' 'the witness proves it' 'it stays unproven' 'Verified here' > "$CNV3/c18a/b/c.txt"
CNV3_C2="$(GIT_CEILING_DIRECTORIES="$CNV3" _cnv3_check "$CNV3/c18a")"; CNV3_C2R=$?
is "cnv3 A25 (C18): the check over a fixture holding a printed line with Proves, and lines with proves, unproven and Verified, fails and names those four lines" \
   "rc=$CNV3_C2R [$CNV3_C2]" "rc=1 [a.sh:1:printf 'Proves the claim\\n'
b/c.txt:2:the witness proves it
b/c.txt:3:it stays unproven
b/c.txt:4:Verified here]"
printf '%s\n' '    felix brief <issue>    what an issue names, its tier, and what a fix must prove' \
  "    printf '\\nthe fix will have to prove\\n'" "printf 'Each one is a change to behaviour with nothing proving it.\\n'" \
  'bsha="$(git rev-parse --verify -q "$b^{commit}")"' '    felix audit [--dir D] [--verify ERE]' '      - name: Verify and push' \
  'read the direction and verify it' 'Verify everything' 'its verify did not finish' '- verify: the gate' > "$CNV3/c18b/x.sh"
CNV3_C3="$(GIT_CEILING_DIRECTORIES="$CNV3" _cnv3_check "$CNV3/c18b")"; CNV3_C3R=$?
is "cnv3 A26 (C18): the check over a fixture holding what a fix must prove, the fix will have to prove, nothing proving it, --verify and the other verify forms passes" \
   "rc=$CNV3_C3R [$CNV3_C3]" "rc=0 []"
printf '%s\n' '# Proves, verified and unproven: a comment' "	  # an indented comment says proves too" 'mkdir -p "$H/state/verified"' \
  'felix_say p subagent-unverified body' > "$CNV3/c18c/x.sh"
printf '%s\n' 'grep -e "never verified"' > "$CNV3/c18c/harness/lib/verify.sh"
printf '%s\n' "    deploy-failed|deployed-unverified) printf '%s' 'A deploy stopped at a failed step' ;;" > "$CNV3/c18c/harness/lib/notify.sh"
printf '%s\n' '{ if ($1 == "not-green" || $1 == "unverified") h = 1 }' > "$CNV3/c18c/harness/lib/green-install.sh"
printf '%s\n' 'case "$b" in "  not-green   "*) old="  unverified  ${b#"  not-green   "}" ;; esac' > "$CNV3/c18c/harness/lib/green-tick.sh"
printf '%s\n' 'echo "never verified"' > "$CNV3/c18d/harness/lib/other.sh"
CNV3_C4="$(GIT_CEILING_DIRECTORIES="$CNV3" _cnv3_check "$CNV3/c18c")"; CNV3_C4R=$?
CNV3_C5="$(GIT_CEILING_DIRECTORIES="$CNV3" _cnv3_check "$CNV3/c18d")"; CNV3_C5R=$?
is "cnv3 A27 (C18): # comments with Proves, each allowed name, and never verified in harness/lib/verify.sh pass; never verified in another file fails" \
   "allowed: rc=$CNV3_C4R [$CNV3_C4] elsewhere: rc=$CNV3_C5R [$CNV3_C5]" \
   "allowed: rc=0 [] elsewhere: rc=1 [harness/lib/other.sh:1:echo \"never verified\"]"
# Round 5, not blind (K12, review round 1): this part's model of the check is shown to fail on the names that were removed from
# its list, in the file that used to allow each, and to pass on the three that replace them, each in its own file.
mkdir -p "$CNV3/c18p/harness/lib" "$CNV3/c18q/harness/lib"
printf '%s\n' 'kind=deployed-unverified' > "$CNV3/c18p/harness/lib/green-tick.sh"
printf '%s\n' "printf 'unverified\\ttree\\t%s\\n' x" > "$CNV3/c18p/harness/lib/escape.sh"
printf '%s\n' 'kind=deployed-unverified' > "$CNV3/c18p/harness/lib/notify.sh"
printf '%s\n' '[ "$1" == "unverified" ] && exit 0' > "$CNV3/c18p/harness/lib/green-install.sh"
printf '%s\n' "    deploy-failed|deployed-unverified) printf '%s' 'A deploy stopped' ;;" > "$CNV3/c18q/harness/lib/notify.sh"
printf '%s\n' '{ if ($1 == "unverified") h = 1 }' > "$CNV3/c18q/harness/lib/green-install.sh"
printf '%s\n' 'case "$b" in "  not-green   "*) old="  unverified  ${b#"  not-green   "}" ;; esac' > "$CNV3/c18q/harness/lib/green-tick.sh"
CNV3_C9="$(GIT_CEILING_DIRECTORIES="$CNV3" _cnv3_check "$CNV3/c18p")"; CNV3_C9R=$?
CNV3_C10="$(GIT_CEILING_DIRECTORIES="$CNV3" _cnv3_check "$CNV3/c18q")"; CNV3_C10R=$?
mkdir -p "$CNV3/c18r/harness/lib"
printf '%s\n' 'x="  unverified  y"' > "$CNV3/c18r/harness/lib/green-tick.sh"
printf '%s\n' 'case "$b" in "  not-green   "*) old="  unverified  ${b#"  not-green   "}" ;; esac' > "$CNV3/c18r/harness/lib/other.sh"
CNV3_C11="$(GIT_CEILING_DIRECTORIES="$CNV3" _cnv3_check "$CNV3/c18r")"; CNV3_C11R=$?
is "cnv3 A27c (C18, round 5, not blind): the quiet check's line fails in any file but green-tick.sh, and another line holding the old name between two blanks fails in green-tick.sh" \
   "rc=$CNV3_C11R files=$(printf '%s\n' "$CNV3_C11" | LC_ALL=C cut -d: -f1 | LC_ALL=C tr '\n' ' ')" \
   "rc=1 files=harness/lib/green-tick.sh harness/lib/other.sh "
is "cnv3 A27b (C18, round 5, not blind): the old ledger kind in green-tick.sh and notify.sh, the old blocker kind's printf in escape.sh and the wide clause in green-install.sh each fail, and the three allowed forms, each in its own file, pass" \
   "removed: rc=$CNV3_C9R files=$(printf '%s\n' "$CNV3_C9" | LC_ALL=C cut -d: -f1 | LC_ALL=C tr '\n' ' ') allowed: rc=$CNV3_C10R [$CNV3_C10]" \
   "removed: rc=1 files=harness/lib/escape.sh harness/lib/green-install.sh harness/lib/green-tick.sh harness/lib/notify.sh  allowed: rc=0 []"
CNV3_G="$CNV3/c18g"; mkdir -p "$CNV3_G/harness/tests" "$CNV3_G/lib"
printf '%s\n' "printf 'proves\\n'" > "$CNV3_G/harness/tests/t.sh"; printf 'echo fine\n' > "$CNV3_G/lib/b.sh"
( _fx_cd "$CNV3_G" && git init -q -b main && git add harness/tests/t.sh lib/b.sh ) >/dev/null 2>&1
printf 'echo it proves nothing\n' > "$CNV3_G/lib/a.sh"
CNV3_C6="$(_cnv3_check "$CNV3_G")"; CNV3_C6R=$?
_fx_git "$CNV3_G" add lib/a.sh >/dev/null 2>&1
CNV3_C7="$(_cnv3_check "$CNV3_G")"; CNV3_C7R=$?
is "cnv3 A28 (C18): inside a git work tree the check reads only tracked files and skips harness/tests/: an untracked proves line passes, then fails once tracked" \
   "before rc=$CNV3_C6R [$CNV3_C6] after rc=$CNV3_C7R [$CNV3_C7]" "before rc=0 [] after rc=1 [lib/a.sh:1:echo it proves nothing]"
# The engine's own obligations, copied: every non-comment line of it that holds one of the contract's three phrases.
while IFS= read -r _cnv3_fl; do
  [ -n "$_cnv3_fl" ] && [ -f "$CNV3_ENG/$_cnv3_fl" ] || continue
  LC_ALL=C awk '{ s = $0; sub(/^[ \t]+/, "", s) } substr(s, 1, 1) != "#" && (index($0, "what a fix must prove") || index($0, "the fix will have to prove") || index($0, "with nothing proving it"))' \
    "$CNV3_ENG/$_cnv3_fl" 2>/dev/null
done < <(_cnv3_list "$CNV3_ENG") > "$CNV3/obligations.txt"
mkdir -p "$CNV3/c18o"; cp "$CNV3/obligations.txt" "$CNV3/c18o/o.sh"
CNV3_C8="$(GIT_CEILING_DIRECTORIES="$CNV3" _cnv3_check "$CNV3/c18o")"; CNV3_C8R=$?
is "cnv3 A29 (C18, control): the engine's own lines holding what a fix must prove, the fix will have to prove and with nothing proving it are found, at least four, and pass the check" \
   "lines=$([ "$(_cnv3_rows "$CNV3/obligations.txt")" -ge 4 ] && printf 'four or more' || _cnv3_rows "$CNV3/obligations.txt") rc=$CNV3_C8R [$CNV3_C8]" \
   "lines=four or more rc=0 []"

# ---- C20: the probes' witness sentences -------------------------------------------------------------------------------
CNV3PB="$CNV3/pb"; _cnv3_repo "$CNV3PB" cb; CNV3PB="$(cd "$CNV3PB" && pwd -P)"
_cnv3_ps() {   # PROBE WITNESS -> felix_probe_state's output over the cb checkout, applicability -
  ( cd "${CNV3PB:?}" && export FELIX_HOME="$CNV3H" FELIX_MEMORY="$CNV3M" HOME="$CNV3U"
    . "$REAL_HARNESS/lib/resolve.sh"; . "$REAL_HARNESS/lib/probes.sh"; felix_probe_state "$CNV3PB" - "$1" "$2" ) 2>/dev/null
}
CNV3_P1="$(_cnv3_ps false true)"; CNV3_P3="$(_cnv3_ps 'exit 3' true)"; CNV3_P0="$(_cnv3_ps true true)"
is "cnv3 A30 (C20): a probe that exits non-zero while its witness answers yes reads [blind\\t0\\tthe witness says this surface exists and the probe exited <rc>], for 1 and for 3" \
   "[$CNV3_P1] [$CNV3_P3]" \
   "[$(printf 'blind\t0\tthe witness says this surface exists and the probe exited 1')] [$(printf 'blind\t0\tthe witness says this surface exists and the probe exited 3')]"
is "cnv3 A31 (C20): a probe that exits 0 and enumerates nothing while its witness answers yes reads [blind\\t0\\tthe witness says this surface exists and the probe enumerated none of it]" \
   "[$CNV3_P0]" "[$(printf 'blind\t0\tthe witness says this surface exists and the probe enumerated none of it')]"
is "cnv3 A32 (C20, control): those three rows' state and count are still blind and 0, each one row of three fields" \
   "$(LC_ALL=C awk -F'\t' '{ printf "%s%s %s %d", (NR > 1 ? " " : ""), $1, $2, NF }' <<< "$CNV3_P1
$CNV3_P3
$CNV3_P0")" \
   "blind 0 3 blind 0 3 blind 0 3"
CNV3_PO="$(_cnv3_cli "$CNV3PB" probes)"
is "cnv3 A33 (C20): felix probes over a project with those two blind rows prints both witness sentences and the note [blind means the witness says a surface exists that the probe cannot see, and] / [unknown means nothing decided either way.], and no line says proves" \
   "exited=$(_cnv3_in "$CNV3_PO" 'the witness says this surface exists and the probe exited 1') none=$(_cnv3_in "$CNV3_PO" 'the witness says this surface exists and the probe enumerated none of it') note1=$(_cnv3_hasl "$CNV3_PO" 'blind means the witness says a surface exists that the probe cannot see, and') note2=$(_cnv3_hasl "$CNV3_PO" 'unknown means nothing decided either way.') proves=$(_cnv3_pword "$CNV3_PO")" \
   "exited=yes none=yes note1=yes note2=yes proves=no"
CNV3_PF="$(_cnv3_cli "$CNV3RC" probes)"
is "cnv3 A34 (C20, control): felix probes over a project whose one probe finds its surface prints neither note, old or new" \
   "marker=$(_cnv3_in "$CNV3_PF" marker) new=$(_cnv3_in "$CNV3_PF" 'blind means the witness says') old=$(_cnv3_in "$CNV3_PF" 'blind means the witness proves') unknown=$(_cnv3_in "$CNV3_PF" 'unknown means nothing decided either way.')" \
   "marker=yes new=no old=no unknown=no"

# ---- C21: the standing issue's body -----------------------------------------------------------------------------------
cat > "$CNV3/ghbin/gh" <<'CNV3_GH_STUB'
#!/bin/sh
d="$(dirname "$0")"
printf '%s\n' "$*" >> "$d/argv"
case "${1:-} ${2:-}" in
  "issue list") printf '0\n' ;;
  "issue create") cat > "$d/body"; printf 'https://github.com/fixture/cnv3/issues/7\n' ;;
  *) exit 1 ;;
esac
exit 0
CNV3_GH_STUB
chmod +x "$CNV3/ghbin/gh"
CNV3_FN="$( ( PATH="$CNV3/ghbin:$PATH"; export PATH; export FELIX_HOME="$CNV3H" HOME="$CNV3U"
              . "$REAL_HARNESS/lib/resolve.sh"; . "$REAL_HARNESS/lib/notify.sh"
              _FN_T="$CNV3/fn"; _FN_REPO=fixture/cnv3; _FN_POSTER=cnv3-bot; _FN_DIR="$CNV3/land"; _FN_K=deployed-unverified; _FN_P=0; _FN_D=-
              _fn_step_issue; printf '%s|%s|%s' "$?" "${_FN_N:-}" "${_FN_I:-}" ) 2>/dev/null )"
CNV3_FB="$(_cnv3_ws "$(cat "$CNV3/ghbin/body" 2>/dev/null)")"
is "cnv3 A35 (C21): the standing issue the notifier creates names a deploy that stopped at a failed step or check among its events, and not a deploy it could not verify" \
   "new=$(_cnv3_in "$CNV3_FB" 'a deploy that stopped at a failed step or check') old=$(_cnv3_in "$CNV3_FB" 'a deploy it could not verify')" \
   "new=yes old=no"
is "cnv3 A36 (C21, control): its title, the call that creates it and the rest of its body are unchanged" \
   "$CNV3_FN|$(LC_ALL=C awk 'index($0, "issue create ") == 1' "$CNV3/ghbin/argv" 2>/dev/null)|head=$(_cnv3_in "$CNV3_FB" "This is Felix's standing issue on this repository. The lander (felix land) starts the felix-alert workflow when it needs the repository owner: a pull request it refused or landed, a deploy ")|tail=$(_cnv3_in "$CNV3_FB" ', a job that is paused or stopped. The workflow comments here, one comment per event. Felix does not edit, close, reopen, label or assign this issue.')" \
   "0|7|fixture/cnv3#7|issue create --repo github.com/fixture/cnv3 --title Felix needs you --body-file -|head=yes|tail=yes"

# ---- C22: the README's hook table (text) ------------------------------------------------------------------------------
CNV3_RM="$CNV3_ROOT/README.md"
is "cnv3 A37 (C22): README.md's Subagent stop row ends [tells the parent that a subagent's report must call its own changes partial, failing or unchecked |], and no line says must call its own changes unverified" \
   "row=$(CNV3_SUF="tells the parent that a subagent's report must call its own changes partial, failing or unchecked |" LC_ALL=C awk '
        index($0, "| Subagent stop |") == 1 { s = ENVIRON["CNV3_SUF"]; if (length($0) >= length(s) && substr($0, length($0) - length(s) + 1) == s) n++ }
        END { print n + 0 }' "$CNV3_RM" 2>/dev/null) old=$(_cnv3_cnt "$CNV3_RM" 'must call its own changes unverified')" \
   "row=1 old=0"

# ---- C23: the schema the build queue reserved (text) ------------------------------------------------------------------
# Not blind. C23 was amended after this part was written: its first reading rewrote 0cw.md, an archived section, which
# the handoff check the gate runs refuses. The session that built the change rewrote this assertion for the amended
# clause, under which 0cw.md keeps its words and a line of the handoff names the packet felix.receipt/3.
CNV3_HO="$CNV3_ROOT/docs/handoff/0cw.md"
if [ "$(git -C "$CNV3_ROOT" rev-parse --is-inside-work-tree 2>/dev/null)" = true ]; then
  CNV3_HL="$(git -C "$CNV3_ROOT" ls-files -- HANDOFF.md docs/handoff 2>/dev/null)"
else
  CNV3_HL="$( cd "${CNV3_ROOT:?}" && { [ ! -f HANDOFF.md ] || printf 'HANDOFF.md\n'; find docs/handoff -type f 2>/dev/null; } )"
fi
# FILE NEEDLE NEEDLE -> how many lines of FILE hold both needles
_cnv3_both() { CNV3_N1="$2" CNV3_N2="$3" LC_ALL=C awk 'index($0, ENVIRON["CNV3_N1"]) && index($0, ENVIRON["CNV3_N2"]) { n++ } END { print n + 0 }' "$1" 2>/dev/null || printf 0; }
CNV3_H3=""
while IFS= read -r _cnv3_fl; do
  [ -n "$_cnv3_fl" ] && [ "$_cnv3_fl" != docs/handoff/0cw.md ] && [ -f "$CNV3_ROOT/$_cnv3_fl" ] || continue
  [ "$(_cnv3_both "$CNV3_ROOT/$_cnv3_fl" 'evidence packet' 'felix.receipt/3')" -gt 0 ] && CNV3_H3="$CNV3_H3 $_cnv3_fl"
done <<< "$CNV3_HL"
CNV3_N38="cnv3 A38 (C23): docs/handoff/0cw.md, an archived section, still plans the evidence packet as felix.receipt/2, and a line of HANDOFF.md or of another tracked file in docs/handoff/ names the evidence packet felix.receipt/3"
# The public snapshot withholds docs/ and HANDOFF.md, so where neither 0cw.md nor
# any handoff file is beside this harness it is skipped saying so; where either
# is, it is asked as written.
if [ ! -f "$CNV3_HO" ] && [ -z "$CNV3_HL" ]; then
  skip "$CNV3_N38" "no HANDOFF.md and no docs/handoff beside this harness"
else
  is "$CNV3_N38" \
     "kept=$(_cnv3_yn "$(_cnv3_both "$CNV3_HO" 'evidence packet' 'felix.receipt/2')") read=$([ -n "$CNV3_HL" ] && printf yes || printf no) new=$([ -n "$CNV3_H3" ] && printf yes || printf no)" \
     "kept=yes read=yes new=yes"
fi

# ---- the restore ----
for _cnv3_v in $(compgen -v | LC_ALL=C grep -E '^CNV3[A-Z0-9_]*$'); do unset "$_cnv3_v"; done
for _cnv3_v in $(compgen -A function | LC_ALL=C grep -E '^_cnv3_'); do unset -f "$_cnv3_v"; done
unset _cnv3_v _cnv3_fl
# <<< checked-not-verified-round3
