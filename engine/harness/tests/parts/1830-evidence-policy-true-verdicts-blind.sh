printf '\nthe evidence policy gives true verdicts (audit b11, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b11-evidence-policy-gives-true-verdicts.md
# alone: section 4's assertions A1 to A56, its fixtures F1 to F5 and its tables T1 and T2, with sections 1
# to 3 for what each means. No engine code was read: lib/, hooks/, felix, bin/ and the project gates were
# not opened, and every command and library is driven as a black box. Each assertion is named by its
# number and the behaviour, and every name is emitted on every run. The controls (A10 to A12, A17, A19,
# A20, A23, A26, A31, A35, A41 to A44, A51, A54 to A56) hold before the fix; every other assertion here
# fails on the tree the contract was cut from.
#
# Readings, where the contract leaves room:
# - F2's change is committed by _stage (tests/lib/widget-repo.sh), as 0110's evidence section stages it,
#   and undone by _reset. Every file it writes holds a line no earlier commit held, so _stage always
#   commits. felix brief and felix incident read an issue and a trace, not a diff, so they take no --base.
#   felix next runs with PATH and HOME as 0600 runs it, so no claude CLI and no real home is read. Since
#   2026-11-15 the PATH is /usr/bin:/bin behind $B11/git, a directory holding only the suite's git; why is
#   above A25.
# - A21 runs felix merge --dry-run, which refuses on the same blockers and stops before gh, over a tree
#   given a green gate receipt and a fresh commission receipt (_cm_stamp, part 0004), so the evidence row
#   is the one blocker the fix adds. Its base is a branch at HEAD~1, as 0100's _mbase names one, under a
#   ref of this part's own that is removed afterwards.
# - A18's "a line" is read with B8's "exactly one line". A24 reads "unknown" and "status" at the top of
#   the receipt and every "autonomous" key wherever it stands, and checks B10's "neither evidence.met nor
#   evidence.gap" for the row's name. A28's "the same line" is A27's line, and A27's shape besides.
# - F5's "no verdict" is `felix review` printing `no verdict for this tree`. Every review command runs
#   with this part's own directory at the head of GIT_CEILING_DIRECTORIES, so PLAIN is in no work tree
#   whatever encloses the suite's root. F5 needs a clean checkout: where the widget checkout is not clean
#   when that section starts, its assertions skip by name and say why. WT1 is named so that WT's name is
#   no prefix of it.
#
# Every part runs alone: this one makes the widget checkout's first commit with _widget_repo_build, keeps
# the widget's evidence, risk and obligations tables and puts them back, and makes every other fixture
# under $TMP/b11.

B11="$TMP/b11"; mkdir -p "$B11"
_widget_repo_build
_b11_wp="$FROOT/projects/widget"
for _b11_f in evidence.tsv risk.tsv obligations.tsv; do
  rm -f "$B11/$_b11_f.keep"; [ -f "$_b11_wp/$_b11_f" ] && cp "$_b11_wp/$_b11_f" "$B11/$_b11_f.keep"
done
_b11_T1="$(printf 'unit\t^(src|lib/\t^tests/\tcode changes need a test')"
_b11_T2a="$(printf 'code\t^src/\t^tests/\tbehaviour needs a test')"
_b11_T2="$_b11_T2a"$'\n'"$_b11_T1"
_b11_A3="$(printf 'unit\t^src/\t^(tests/\tcode changes need a test')"
_b11_A5="$(printf 'unit\t\t^tests/\tcode changes need a test')"
_b11_n=0; _b11_k=0; _b11_why=""

# OUT N CHECK...: "ok" when OUT has N lines (- for any number) and its first line meets each CHECK, K=V
# (field K is exactly V) or K~V (field K holds V), fields split on single tabs; otherwise what differs.
_b11_says() {
  local o="$1" n="$2" k c f v g
  shift 2
  k="$(printf '%s' "$o" | awk 'END { print NR }')"
  if [ "$n" != - ] && [ "$k" != "$n" ]; then printf '%s line(s), not %s: [%s]' "$k" "$n" "$o"; return 0; fi
  for c in "$@"; do
    f="${c%%[=~]*}"; v="${c#*[=~]}"
    g="$(printf '%s\n' "$o" | LC_ALL=C awk -F'\t' -v k="$f" 'NR == 1 { print $k }')"
    case "$c" in
      "$f="*) [ "$g" = "$v" ] || { printf 'field %s is [%s], not [%s]: [%s]' "$f" "$g" "$v" "$o"; return 0; } ;;
      *) case "$g" in *"$v"*) ;; *) printf 'field %s lacks [%s]: [%s]' "$f" "$v" "$o"; return 0 ;; esac ;;
    esac
  done
  printf ok
}
# NAME TEXT +PHRASE|-PHRASE...: one assertion that TEXT holds every +PHRASE and no -PHRASE (a skip by the
# same name while F5 cannot be built).
_b11_hl() {
  local n="$1" t="$2" p miss=""
  shift 2
  for p in "$@"; do
    case "$p" in
      +*) case "$t" in *"${p#+}"*) ;; *) miss="$miss lacks [${p#+}];" ;; esac ;;
      -*) case "$t" in *"${p#-}"*) miss="$miss holds [${p#-}];" ;; esac ;;
    esac
  done
  if [ -n "$_b11_why" ]; then skip "$n" "$_b11_why"
  elif [ -z "$miss" ]; then ok "$n"; else bad "$n" "it$miss in [$t]"; fi
}
# TEXT AWK-CONDITION: how many lines of TEXT, split on tabs, meet the condition.
_b11_c() { printf '%s\n' "$1" | LC_ALL=C awk -F'\t' "$2"' { n++ } END { print n + 0 }'; }
# NAME TEXT AWK-CONDITION WANT: one assertion that WANT lines of TEXT meet the condition (N+: at least N).
_b11_cn() {
  local c
  c="$(_b11_c "$2" "$3")"
  if [ -n "$_b11_why" ]; then skip "$1" "$_b11_why"; return 0; fi
  case "$4" in
    *+) [ "$c" -ge "${4%+}" ] && ok "$1" || bad "$1" "$c line(s) meet [$3], not at least ${4%+}, in [$2]" ;;
    *)  [ "$c" = "$4" ] && ok "$1" || bad "$1" "$c line(s) meet [$3], not $4, in [$2]" ;;
  esac
}
# NAME GOT WANT: is, or a skip by the same name while F5 cannot be built.
_b11_is() { if [ -n "$_b11_why" ]; then skip "$1" "$_b11_why"; else is "$1" "$2" "$3"; fi; }

# ---- F1: the check, row by row -------------------------------------------------------------------
printf '\n  the check reads every row it cannot judge as unknown (F1)\n'
# ROWS: a fresh policy directory in _b11_P, its evidence.tsv holding ROWS and a final newline.
_b11_p() { _b11_n=$((_b11_n + 1)); _b11_P="$B11/p$_b11_n"; mkdir -p "$_b11_P"; printf '%s\n' "$1" > "$_b11_P/evidence.tsv"; }
# SPEC...: a fresh repository in _b11_G: main holds README and each -PATH, and work, one commit on top,
# adds each +PATH and deletes each -PATH.
_b11_g() {
  local s p
  _b11_n=$((_b11_n + 1)); _b11_G="$B11/g$_b11_n"; mkdir -p "$_b11_G"; printf 'a readme\n' > "$_b11_G/README"
  for s in "$@"; do case "$s" in -*) p="$_b11_G/${s#-}"; mkdir -p "$(dirname "$p")"; printf 'x\n' > "$p" ;; esac; done
  ( _fx_cd "$_b11_G" && git init -q -b main && git add -A && git -c user.name=t -c user.email=t@t commit -qm main \
    && git checkout -q -b work ) >/dev/null 2>&1
  for s in "$@"; do
    case "$s" in -*) rm -f "$_b11_G/${s#-}" ;; +*) p="$_b11_G/${s#+}"; mkdir -p "$(dirname "$p")"; printf 'x\n' > "$p" ;; esac
  done
  ( _fx_cd "$_b11_G" && git add -A && git -c user.name=t -c user.email=t@t commit -qm work ) >/dev/null 2>&1
  _b11_G="$(cd "$_b11_G" && pwd -P)"
}
# [BASE]: felix_evidence_check _b11_P BASE _b11_G (BASE main by default), as F1 runs it.
_b11_chk() { ( cd "$_b11_G" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/evidence.sh"
               felix_evidence_check "$_b11_P" "${1:-main}" "$_b11_G" ) </dev/null 2>/dev/null; }

_b11_p "$_b11_T1"; _b11_g +src/a.ts
is "b11 A1: a when cell grep cannot compile is one unknown line for its row, naming the when cell and saying not judged" \
   "$(_b11_says "$(_b11_chk)" 1 1=unknown 2=unit '3~when cell' '3~not judged')" ok
_b11_g +docs/x.md
is "b11 A2: and that row is unknown whatever the change touches, a docs-only change included" \
   "$(_b11_says "$(_b11_chk)" - 1=unknown)" ok
_b11_p "$_b11_A3"; _b11_g +src/a.ts
is "b11 A3: a requires cell grep cannot compile, under a when that fires, is unknown, naming the requires cell and saying not judged" \
   "$(_b11_says "$(_b11_chk)" - 1=unknown 2=unit '3~requires cell' '3~not judged')" ok
_b11_g +src/a.ts +tests/a_test.py
is "b11 A4: and stays unknown when the change also adds a test" "$(_b11_says "$(_b11_chk)" - 1=unknown)" ok
_b11_p "$_b11_A5"; _b11_g +tests/a.py
is "b11 A5: a row with an empty when cell is one unknown line saying its cells were not judged, never judged with requires as its when" \
   "$(_b11_says "$(_b11_chk)" 1 1=unknown 2=unit '3~cells' '3~not judged')" ok
_b11_p "$(printf 'unit\t^src/\t^tests/')"; _b11_g +src/a.ts
is "b11 A6: a row of three cells is unknown, under its own name" "$(_b11_says "$(_b11_chk)" - 1=unknown 2=unit)" ok
_b11_p "$(printf '# a comment\n\tunit\t^src/\t^tests/\ta reason')"
is "b11 A7: a row whose first cell is empty is unknown, named evidence.tsv:N by its line in the file, comments counted" \
   "$(_b11_says "$(_b11_chk)" - 1=unknown 2=evidence.tsv:2)" ok
_b11_p "$(printf 'unit\t^src/\t^tests/\ta reason\t')"
is "b11 A8: a row with a trailing tab, five cells, is unknown" "$(_b11_says "$(_b11_chk)" - 1=unknown)" ok
_b11_p "$_b11_T2"; chmod 000 "$_b11_P/evidence.tsv"
if [ -r "$_b11_P/evidence.tsv" ]; then
  skip "b11 A9: an evidence.tsv that exists and cannot be read is one unknown line for the table, not judged" \
       "a mode-000 file is still readable here (root)"
else
  is "b11 A9: an evidence.tsv that exists and cannot be read is one unknown line for the table, not judged" \
     "$(_b11_says "$(_b11_chk)" 1 1=unknown 2=evidence.tsv '3~not judged')" ok
fi
chmod 644 "$_b11_P/evidence.tsv"
_b11_v="$(_b11_chk)"
is "b11 A10: a valid row beside a broken one is judged as before: gap, with its own reason, first in file order (control)" \
   "$(printf '%s' "$_b11_v" | awk 'END { print NR }')|$(printf '%s\n' "$_b11_v" | sed -n 1p)" \
   "$(printf '2|gap\tcode\tbehaviour needs a test')"
_b11_g +src/a.ts +tests/a_test.py
is "b11 A11: and met once the change adds a test (control)" \
   "$(_b11_chk | sed -n 1p)" "$(printf 'met\tcode\tbehaviour needs a test')"
is "b11 A12: a base that names nothing is still one unknown line naming the base, no rule consulted (control)" \
   "$(_b11_says "$(_b11_chk no-such-ref)" 1 1=unknown 2=no-such-ref '3~no rule was consulted')" ok

# ---- F2, F3: the commands over the widget checkout ----------------------------------------------------
printf '\n  felix evidence, merge, classify, receipt, next, brief and incident say a row was not judged (F2, F3)\n'
_b11_ev() { printf '%s\n' "$1" > "$_b11_wp/evidence.tsv"; }
# PATH...: each written in $REPO with a line no earlier commit held, then committed by _stage.
_b11_ch() {
  local p
  _b11_k=$((_b11_k + 1))
  for p in "$@"; do mkdir -p "$(dirname "$REPO/$p")"; printf 'b11 change %s\n' "$_b11_k" > "$REPO/$p"; done
  _stage
}
_b11_run() { _b11_o="$(cd "$REPO" && "$FELIX" "$@" </dev/null 2>&1)"; _b11_rc=$?; }
# BASE: felix_merge_blockers over the widget checkout, sourced as 0100's _blk sources it.
_b11_blk() { ( cd "$REPO" && . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
               . "$FROOT/harness/lib/evidence.sh"; . "$FROOT/harness/lib/verify.sh"
               felix_merge_blockers "$_b11_wp" "$1" "$REPO" "$FROOT" ) </dev/null 2>/dev/null; }
# JSON: "ok", or what B10 finds wrong with a receipt.
_b11_rcj() {
  printf '%s' "$1" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception as e:
    print("not json: %s" % e); sys.exit(0)
def every(o, k):
    if isinstance(o, dict):
        for a in o:
            if a == k: yield o[a]
            for x in every(o[a], k): yield x
    elif isinstance(o, list):
        for b in o:
            for x in every(b, k): yield x
w = []
u = d.get("unknown")
if not (isinstance(u, list) and "evidence" in u): w.append("unknown is %s" % json.dumps(u))
if d.get("status") != "indeterminate": w.append("status is %s" % json.dumps(d.get("status")))
a = list(every(d, "autonomous"))
if not a or [x for x in a if x is not False]: w.append("autonomous is %s" % json.dumps(a))
e = d.get("evidence") if isinstance(d.get("evidence"), dict) else {}
for k in ("met", "gap"):
    if "\"unit\"" in json.dumps(e.get(k)): w.append("evidence.%s names unit: %s" % (k, json.dumps(e.get(k))))
print("; ".join(w) if w else "ok")' 2>&1
}

_b11_ev "$_b11_T2"; _b11_ch src/a.ts
_b11_run evidence --base HEAD~1
_b11_hl "b11 A13: felix evidence prints the gap as [!] and the row it could not judge as [?]" "$_b11_o" '+[!] code' '+[?] unit'
_b11_hl "b11 A14: and exits 1 without --strict, claiming neither no gaps nor that nothing was compared" \
        "[rc=$_b11_rc] $_b11_o" '+[rc=1]' '-No evidence gaps' '-Nothing was compared'
_b11_v="$(_b11_blk HEAD~1)"
_b11_cn "b11 A18: felix_merge_blockers names the row it could not judge as one evidence line saying not judged" \
        "$_b11_v" '$1 == "evidence" && $2 == "unit" && index($3, "not judged")' 1
_b11_cn "b11 A19: and the gap line is unchanged (control)" "$_b11_v" '$0 == "evidence\tcode\tbehaviour needs a test"' 1+
_b11_v="$(_b11_blk no-such-ref)"
is "b11 A20: over a base that names nothing, no evidence line, and the base said once by its unknown line (control)" \
   "evidence $(_b11_c "$_b11_v" '$1 == "evidence"'), unknown $(_b11_c "$_b11_v" 'index($0, "unknown\tno-such-ref\t") == 1')" \
   "evidence 0, unknown 1"
_b11_o="$(cd "$REPO" && "$FELIX" receipt --base HEAD~1 </dev/null 2>/dev/null)"
is "b11 A24: felix receipt lists evidence as unknown, is indeterminate, is not autonomous, and names the row neither met nor gap" \
   "$(_b11_rcj "$_b11_o")" ok
mkdir -p "$B11/home"
# /usr/bin:/bin keeps the claude CLI out of reach, and alone it would also hand felix next /usr/bin/git. On a Mac
# that is Xcode's shim, which exits 69 on every call from an Xcode update until its licence is accepted; next then
# reads HEAD~1 as naming nothing, and A25 and A26 fail. So $B11/git holds the suite's git alone, ahead of /usr/bin.
mkdir -p "$B11/git"; [ -z "$(type -P git)" ] || ln -sf "$(type -P git)" "$B11/git/git"
_b11_o="$(cd "$REPO" && PATH="$B11/git:/usr/bin:/bin" HOME="$B11/home" "$FELIX" next --base HEAD~1 </dev/null 2>&1)"
_b11_cn "b11 A25: felix next gives Felix a row naming the row it could not judge and saying not judged" \
        "$_b11_o" 'index($0, "felix") && index($0, "unit") && index($0, "not judged")' 1+
_b11_hl "b11 A26: and the gap row is unchanged (control)" "$_b11_o" '+the change owes evidence: code'
_reset

_b11_ev "$_b11_T1"; _b11_ch README.md
_b11_run evidence --base HEAD~1
_b11_hl "b11 A15: a row felix evidence cannot judge exits 1 on a docs-only change and says no all-clear" \
        "[rc=$_b11_rc] $_b11_o" '+[rc=1]' '-No evidence gaps'
_reset

_b11_ev "$_b11_T2a"; _b11_ch src/a.ts
_b11_run evidence --base HEAD~1; _b11_r0="$_b11_rc"
_b11_hl "b11 A16: a gap's advice says felix merge refuses while it stands, and offers no pull request note" \
        "$_b11_o" '+felix merge' '-pull request'
_b11_run evidence --base HEAD~1 --strict
is "b11 A17: and a gap alone still exits 0 without --strict and 1 with it (control)" "$_b11_r0 $_b11_rc" "0 1"
_reset

_b11_ev "$_b11_T1"; _b11_ch src/a.ts
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" >/dev/null 2>&1 )
_cm_stamp
_fx_git "$REPO" update-ref refs/heads/b11-mbase HEAD~1 >/dev/null 2>&1
_b11_run merge --base refs/heads/b11-mbase --dry-run
_b11_hl "b11 A21: felix merge refuses a tree with a row it could not judge, exit 3, naming the row and not judged, not the unknown-base paragraph" \
        "[rc=$_b11_rc] $_b11_o" '+[rc=3]' '+unit' '+not judged' '-Nothing was compared'
_fx_git "$REPO" update-ref -d refs/heads/b11-mbase >/dev/null 2>&1
_b11_o="$(cd "$REPO" && printf 'src/a.ts throws when it loads\n' | "$FELIX" brief --from - --title t 2>&1)"
_b11_hl "b11 A33: felix brief says, under what a fix must prove, that a row was not judged" \
        "$_b11_o" '+what a fix must prove' '+not judged'
_reset

printf 'green\tpath\t^src/safe/\tdeclared safe by this project\n' >> "$_b11_wp/risk.tsv"
_b11_ev "$_b11_T1"; _b11_ch src/safe/x.js
_b11_run classify --base HEAD~1
_b11_hl "b11 A22: felix classify at green with a row it could not judge withholds auto-merge and says not judged" \
        "$_b11_o" '+tier:  green' '+Not auto-merge eligible' '+not judged' '-Eligible for auto-merge'
_b11_ev "$(printf 'docs\t^docs/\t^docs/\tdocs prove themselves')"
_b11_run classify --base HEAD~1
_b11_hl "b11 A23: and with no gap and no unknown the green tree is still eligible for auto-merge (control)" \
        "$_b11_o" '+Eligible for auto-merge'
_reset
cp "$B11/risk.tsv.keep" "$_b11_wp/risk.tsv"

_b11_ev "$_b11_T2"; _b11_ch src/thing.js
_b11_o="$(cd "$REPO" && printf 'Error: boom\n    at run (/home/runner/work/x/x/src/thing.js:44:9)\n' | "$FELIX" incident 2>&1)"
case "$_b11_o" in *"the fix will have to prove"*) _b11_a="${_b11_o#*the fix will have to prove}" ;; *) _b11_a="(the output has no such heading)" ;; esac
_b11_hl "b11 A34: felix incident lists, under the fix will have to prove, the row it could not judge as not judged" \
        "$_b11_a" '+unit' '+not judged'
_b11_hl "b11 A35: and the valid row as today (control)" "$_b11_a" '+code'
_reset

# ---- B12: the forward question, in a shell that sources only lib/resolve.sh and lib/intake.sh ---------
# PATHS: felix_brief_evidence _b11_P PATHS.
_b11_bev() { ( cd "$B11" && bash -c '. "$1/lib/resolve.sh"; . "$1/lib/intake.sh"; felix_brief_evidence "$2" "$3"' \
               _ "$FROOT/harness" "$_b11_P" "$1" ) </dev/null 2>/dev/null; }
_b11_p "$_b11_T1"; _b11_v="$(_b11_bev src/a.ts)"
is "b11 A27: felix_brief_evidence prints a row it cannot judge as one line, its name and not judged, with only intake.sh sourced" \
   "$(_b11_says "$_b11_v" 1 1=unit '2~not judged')" ok
_b11_o="$(_b11_bev docs/x.md)"
is "b11 A28: and prints the same line whatever the paths hold" \
   "$(_b11_says "$_b11_o" 1 1=unit '2~not judged')$( [ "$_b11_o" = "$_b11_v" ] || printf ', and not the line src/a.ts gave')" ok
_b11_p "$_b11_A3"
is "b11 A29: a requires cell it cannot compile is printed as not judged" "$(_b11_says "$(_b11_bev src/a.ts)" - 1=unit '2~not judged')" ok
_b11_p "$_b11_A5"
is "b11 A30: a row that is not four cells is printed as not judged" "$(_b11_says "$(_b11_bev src/a.ts)" - 1=unit '2~not judged')" ok
_b11_p "$_b11_T2a"
is "b11 A31: a valid row is printed once with its reason when a path fires its when, and not otherwise (control)" \
   "src [$(_b11_bev src/a.ts)] docs [$(_b11_bev docs/x.md)]" "$(printf 'src [code\tbehaviour needs a test] docs []')"
_locale_bytes_vars
_b11_p "$(printf 'api\t^src/api/|^caf\351/\t^tests/\tan api change ships a test')"
if [ -n "$LCB_U8" ]; then
  is "b11 A32: in a UTF-8 locale a when cell holding a Latin-1 byte still matches, read under LC_ALL=C" \
     "$( export LC_ALL="$LCB_U8" LANG="$LCB_U8"; _b11_bev src/api/x.py )" "$(printf 'api\tan api change ships a test')"
else
  skip "b11 A32: in a UTF-8 locale a when cell holding a Latin-1 byte still matches, read under LC_ALL=C" "$LCB_NONE"
fi

# ---- F4: a judged command that discards its status -------------------------------------------------
printf '\n  a judged command that runs something and discards its status is refused (F4)\n'
_b11_R="cannot fail: it runs something that can fail, and no path through it ends in failure"
_b11_ffrow() {  # TABLE TEXT ID: one row of TABLE's shape (F4) with TEXT in its judged column
  case "$1" in
    obligations.tsv)   printf '%s\tADVISORY\tdeterministic\t-\t%s\t-\ta reason\n' "$3" "$2" ;;
    commissioning.tsv) printf 'need\t-\t-\t-\t-\t%s\t9\n' "$2" ;;
    setup.tsv)         printf 's1\ta step\talways\t%s\n' "$2" ;;
    maintenance.tsv)   printf 'm1\t0\talways\ta check\t%s\n' "$2" ;;
  esac
}
# NAME TABLE TEXT...: felix_final_filter_table over $B11/ff-NAME/TABLE, a row for each TEXT (ids o1,
# o2, ...): its lines, then rc=N.
_b11_fft() {
  local d="$B11/ff-$1" t="$2" i=0 x
  shift 2
  mkdir -p "$d"; : > "$d/$t"
  for x in "$@"; do i=$((i + 1)); _b11_ffrow "$t" "$x" "o$i" >> "$d/$t"; done
  ( . "$FROOT/harness/lib/final-filter.sh"; felix_final_filter_table "$d/$t" ) </dev/null 2>/dev/null
  printf 'rc=%s\n' "$?"
}
# OUT: its lines, rc= aside, as LINE|FIELD2 joined by " / ".
_b11_ffp() { printf '%s\n' "$1" | LC_ALL=C awk -F'\t' '/^rc=/ { next } { printf "%s%s|%s", s, $1, $2; s = " / " }'; }
_b11_W="the evidence contract $_b11_R"
is "b11 A36: obligations whose evidence runs a check and discards its status are refused, line by line, as unfailable" \
   "$(_b11_ffp "$(_b11_fft a36 obligations.tsv 'pytest || true' 'make test; exit 0' 'make test || :' \
        'make test > /dev/null 2>&1 || echo failed' 'npm test | tail -5; true')")" \
   "1|$_b11_W / 2|$_b11_W / 3|$_b11_W / 4|$_b11_W / 5|$_b11_W"
is "b11 A37: as is one whose if runs the check and has no failing path" \
   "$(_b11_ffp "$(_b11_fft a37 obligations.tsv 'if make test; then echo ok; fi')")" "1|$_b11_W"
is "b11 A38: a commissioning check that discards its status is refused" \
   "$(_b11_ffp "$(_b11_fft a38 commissioning.tsv 'gh auth status || true')")" "1|check $_b11_R"
is "b11 A39: a setup check that discards its status is refused" \
   "$(_b11_ffp "$(_b11_fft a39 setup.tsv 'command -v jq || true')")" "1|check $_b11_R"
is "b11 A40: a maintenance event row's check that discards its status is refused" \
   "$(_b11_ffp "$(_b11_fft a40 maintenance.tsv 'make lint || true')")" "1|check $_b11_R"
is "b11 A41: texts that run nothing that can fail, or have a failing path, or set pipefail, are admitted (control)" \
   "$(_b11_fft a41 obligations.tsv true : 'echo ok' 'exit 0' pytest 'make test || exit 1' 'cd d && make test | tail -20' \
        'set -o pipefail; make test || true')" "rc=0"
_b11_v="$(_b11_fft a42 obligations.tsv 'make test | tail -20')"
_b11_hl "b11 A42: a final filter keeps its own reason, naming tail (control)" \
        "lines $(_b11_c "$_b11_v" '!/^rc=/') $_b11_v" '+lines 1 ' '+tail' '+succeeds whatever it is fed' '-runs something that can fail'
unset FELIX_B11_UNSET
is "b11 A43: a commissioning check whose unset name set -u ends in failure is admitted (control)" \
   "$(_b11_ffp "$(_b11_fft a43 commissioning.tsv 'test -n "$FELIX_B11_UNSET" || true')")" ""
_b11_ffc() { local o r; o="$( . "$FROOT/harness/lib/final-filter.sh"; felix_final_filter "$1" </dev/null 2>/dev/null )"; r=$?; printf '%s|%s' "$r" "$o"; }
is "b11 A44: felix_final_filter still names only a final filter: make test || true and true each exit 1 and print nothing (control)" \
   "$(_b11_ffc 'make test || true') $(_b11_ffc true)" "1| 1|"
rm -f "$TMP/b11-ffx-ran"
{ cat "$B11/obligations.tsv.keep" 2>/dev/null
  printf 'ffx\tADVISORY\tdeterministic\t-\t%s\t-\ta discard\n' "touch \"$TMP/b11-ffx-ran\"; pytest || true"
} > "$_b11_wp/obligations.tsv"
_b11_ob() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"
              . "$FROOT/harness/lib/obligations.sh"; "$@" ) </dev/null 2>/dev/null; }
_b11_ob felix_obligations_run "$_b11_wp" "$REPO" >/dev/null
_b11_v="$(_b11_ob felix_obligation_malformed "$_b11_wp")"
_b11_m="$(_b11_c "$_b11_v" 'index($0, "ffx: ") == 1 && index($0, "runs something that can fail")')"
is "b11 A45: felix_obligations_run never runs a refused obligation, and felix_obligation_malformed names it with the reason" \
   "$( [ -e "$TMP/b11-ffx-ran" ] && printf ran || printf 'not run' ), $( [ "$_b11_m" -gt 0 ] && printf named || printf 'not named in [%s]' "$_b11_v" )" \
   "not run, named"
if [ -f "$B11/obligations.tsv.keep" ]; then cp "$B11/obligations.tsv.keep" "$_b11_wp/obligations.tsv"; else rm -f "$_b11_wp/obligations.tsv"; fi
rm -f "$TMP/b11-ffx-ran"

# ---- F5: where a passing review ran ------------------------------------------------------------
printf '\n  a passing review says where it ran: a work tree of its own at the same commit (F5)\n'
[ -z "$(git -C "$REPO" status --porcelain 2>/dev/null)" ] || _b11_why="the widget checkout is not clean, and F5 needs a clean one"
_b11_ch b11/review.txt
_b11_WT="$B11/b11-review-wt"; _b11_WT1="$B11/b11-older-tree"; _b11_PL="$B11/plain"; _b11_UB="$B11/unborn"; _b11_LN="$B11/b11-link"
_fx_git "$REPO" worktree add -q --detach "$_b11_WT" HEAD >/dev/null 2>&1
_fx_git "$REPO" worktree add -q --detach "$_b11_WT1" HEAD~1 >/dev/null 2>&1
mkdir -p "$_b11_PL" "$_b11_UB" "$REPO/sub"
( _fx_cd "$_b11_UB" && git init -q -b main ) >/dev/null 2>&1
ln -s "$REPO" "$_b11_LN"
_b11_ceil="$(cd "$B11" && pwd -P)${GIT_CEILING_DIRECTORIES:+:$GIT_CEILING_DIRECTORIES}"
_b11_rv() { _b11_o="$(cd "$REPO" && GIT_CEILING_DIRECTORIES="$_b11_ceil" "$FELIX" review "$@" </dev/null 2>&1)"; _b11_rc=$?; }
_b11_vd() { ( cd "$REPO" && GIT_CEILING_DIRECTORIES="$_b11_ceil" "$FELIX" review </dev/null 2>&1 ); }
_b11_nv() { case "$(_b11_vd)" in *"no verdict for this tree"*) printf 'no verdict' ;; *) printf 'a verdict [%s]' "$(_b11_vd)" ;; esac; }
# PHRASE: B17's refusal as _b11_rg spells it; PHRASE ARGS...: what felix review ARGS did, spelled the same way.
_b11_rw() { if [ "$1" = - ]; then printf 'exit non-zero, no verdict'; else printf 'exit non-zero, says %s, no verdict' "$1"; fi; }
_b11_rg() {
  local p="$1" g
  shift
  _b11_rv "$@"
  g="exit $_b11_rc"; [ "$_b11_rc" -eq 0 ] || g="exit non-zero"
  if [ "$p" != - ]; then case "$_b11_o" in *"$p"*) g="$g, says $p" ;; *) g="$g, does not say $p" ;; esac; fi
  g="$g, $(_b11_nv)"
  [ "$g" = "$(_b11_rw "$p")" ] || g="$g: [$_b11_o]"
  printf '%s' "$g"
}

_b11_cn "b11 A46: felix review with no verdict prints a usage line for --pass that names --in" "$(_b11_vd)" \
        'index($0, "--pass") && index($0, "--in")' 1+
# A51 first: it is a control, and the passes A47 to A53 record on the tree before the fix would
# otherwise stand as a verdict when it reads "no verdict".
_b11_is "b11 A51: a pass whose --in is the reviewed checkout, or a symlink to it, is refused and records nothing (control)" \
        "checkout: $(_b11_rg - --pass --by r1 --in "$REPO"); link: $(_b11_rg - --pass --by r1 --in "$_b11_LN")" \
        "checkout: $(_b11_rw -); link: $(_b11_rw -)"
_b11_is "b11 A47: a pass with no --in is refused, says --in, and records nothing" \
        "$(_b11_rg --in --pass --by r1 --note n)" "$(_b11_rw --in)"
_b11_is "b11 A48: a pass whose --in names nothing that exists is refused and records nothing" \
        "$(_b11_rg - --pass --by r1 --in "$TMP/b11-no-such-dir")" "$(_b11_rw -)"
_b11_is "b11 A49: a pass whose --in is in no git work tree is refused and records nothing" \
        "$(_b11_rg - --pass --by r1 --in "$_b11_PL")" "$(_b11_rw -)"
_b11_is "b11 A50: a pass whose --in is a directory inside the reviewed checkout is refused and records nothing" \
        "$(_b11_rg - --pass --by r1 --in "$REPO/sub")" "$(_b11_rw -)"
_b11_is "b11 A52: a pass whose --in is a work tree at another commit is refused, says commit, and records nothing" \
        "$(_b11_rg commit --pass --by r1 --in "$_b11_WT1")" "$(_b11_rw commit)"
_b11_is "b11 A53: a pass whose --in is a repository with no commit is refused, says commit, and records nothing" \
        "$(_b11_rg commit --pass --by r1 --in "$_b11_UB")" "$(_b11_rw commit)"
_b11_rv --pass --by r1 --in "$_b11_WT"
_b11_hl "b11 A54: a pass from a separate work tree at the reviewed HEAD is recorded, and felix review reads it as a pass (control)" \
        "[rc=$_b11_rc] $_b11_o / $(_b11_vd)" '+[rc=0]' '+recorded: pass by r1' '+verdict:  pass'
_b11_v="$( cd "$REPO" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
           felix_review_verdict "$FROOT" "$_b11_wp" "$(felix_tree_id "$REPO" "$FROOT")" 2>/dev/null | cut -f6 )"
_b11_hl "b11 A55: and the record's sixth field names that work tree (control)" "$_b11_v" "+${_b11_WT##*/}"
_b11_rv --block --by r3 --note x
_b11_hl "b11 A56: a block is recorded with no --in (control)" "[rc=$_b11_rc] $_b11_o" '+[rc=0]' '+recorded: block by r3'
_fx_git "$REPO" worktree remove --force "$_b11_WT" >/dev/null 2>&1
_fx_git "$REPO" worktree remove --force "$_b11_WT1" >/dev/null 2>&1
_fx_git "$REPO" worktree prune >/dev/null 2>&1
rmdir "$REPO/sub" 2>/dev/null; rm -f "$_b11_LN"
_reset
_b11_why=""

# The widget's tables, as this part found them.
for _b11_f in evidence.tsv risk.tsv; do
  if [ -f "$B11/$_b11_f.keep" ]; then cp "$B11/$_b11_f.keep" "$_b11_wp/$_b11_f"; else rm -f "$_b11_wp/$_b11_f"; fi
done
unset -f _b11_says _b11_hl _b11_c _b11_cn _b11_is _b11_p _b11_g _b11_chk _b11_ev _b11_ch _b11_run _b11_blk _b11_rcj \
         _b11_bev _b11_ffrow _b11_fft _b11_ffp _b11_ffc _b11_ob _b11_rv _b11_vd _b11_nv _b11_rw _b11_rg
