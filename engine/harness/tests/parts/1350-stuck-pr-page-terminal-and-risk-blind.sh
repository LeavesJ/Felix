# >>> stuck-pr-page-terminal-and-risk
printf '\nthe stuck-PR page: a checkout name with no slug, what reaches a terminal from every field, and a confined risk row listed once (spec v2 R5 clarified, R8 its reach, R10, blind)\n'
# Blind, written on 2026-10-17 from spec v2 and its amendments (audits/
# 2026-10-01-report-v5-review/specs/stuck-pr/spec-v2.md: R5, clarified; R8,
# its reach; R10), without reading lib/pr-status*.sh or felix_land. Parts 1300
# to 1340 were read only for how their fixtures and stubs are built.
# Self-contained after the preamble: it builds its own fixture under $TMP and
# removes it.
#
# The fixture: a bare origin whose path ends github.com/fixture/home.git and a
# clone of it that is also the Felix home, holding projects/felix (remote_match
# github.com/fixture/home). Its origin/main holds a risk table with two path
# rows that name a channel and carry a content confine (^conf/one/ and
# ^conf/two/) and one with no confine (^plainrisk/). A second repository sits
# in a directory whose name holds a tab, and its origin URL holds a tab too, so
# no owner/name slug can be read from it. gh and launchctl are stubs first on
# PATH, each logging its argv. gh answers pr list from ctl/prs.<key>.json, the
# key being the repository from -R or --repo, else from the origin of the
# directory it runs in, lowercased, every byte but a letter or digit made _.
# It answers the billing GET with minutes, or as ctl/bill.users.* say.
#
# gh prints JSON: a control below space inside a string as \u00XX, DEL and the
# C1 controls (U+0080 to U+009F) raw, as their bytes. The titles below are
# written that way.
SZ="$TMP/stuck-pr-term"; mkdir -p "$SZ"; SZ="$(cd "$SZ" && pwd -P)"
SZO="$SZ/github.com/fixture/home.git"; SZH="$SZ/home"
SZM="$SZ/mem"; SZU="$SZ/user"; SZB="$SZ/bin"; SZK="$SZ/ctl"; SZL="$SZ/log"; SZX="$SZ/out"; SZT="$SZ/tmp"
SZTAB="$(printf '\t')"; SZESC="$(printf '\033')"
SZD="$SZ/tab${SZTAB}dir"
SZLAND="$(FELIX_MEMORY="$SZM" felix_mem_dir felix)/land"
mkdir -p "$SZO" "$SZM" "$SZU/.config/gh" "$SZB" "$SZK" "$SZL" "$SZX" "$SZT" "$SZ/cache" "$SZD"
_sz_put() { mkdir -p "$(dirname "$1")" && LC_ALL=C sed "s#@SZ@#$SZ#g" > "$1" && chmod +x "$1"; }
_sz_put "$SZB/gh" <<'SZSTUB'
#!/bin/bash
SZ='@SZ@'; K="$SZ/ctl"
printf '%s\n' "$*" >> "$SZ/log/gh.log"
jqx=""; repo=""; prev=""; bill=""
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; -R|--repo) repo="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; --repo=*) repo="${a#--repo=}" ;; esac
  case "$a" in
    *users/*/settings/billing/usage*) bill=users; bq="$a" ;;
    *orgs/*/settings/billing/usage*) bill=orgs; bq="$a" ;;
  esac
  prev="$a"
done
key() { printf '%s' "$1" | LC_ALL=C tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz' | LC_ALL=C tr -c 'abcdefghijklmnopqrstuvwxyz0123456789' '_'; }
out() { if [ -n "$jqx" ] && command -v jq >/dev/null 2>&1; then jq -r "$jqx"; else cat; fi; }
if [ "${1:-} ${2:-}" = "pr list" ]; then
  if [ -z "$repo" ]; then
    u="$(git config --get remote.origin.url 2>/dev/null)"; u="${u%/}"; u="${u%.git}"
    n="${u##*/}"; o="${u%/*}"; o="${o##*/}"; [ -n "$n" ] && [ -n "$o" ] && repo="$o/$n"
  fi
  repo="${repo#https://}"; repo="${repo#github.com/}"; repo="${repo%.git}"
  k="$(key "$repo")"
  [ -f "$K/prs.$k.json" ] || { printf 'stub: no answer for repository [%s]\n' "$repo" >&2; exit 4; }
  out < "$K/prs.$k.json"; exit 0
fi
if [ "${1:-}" = api ]; then
  if [ -n "$bill" ]; then
    if [ -f "$K/bill.$bill.rc" ]; then cat "$K/bill.$bill.err" >&2; exit "$(cat "$K/bill.$bill.rc")"; fi
    by="${bq##*year=}"; by="${by%%&*}"; bm="${bq##*month=}"; bm="${bm%%&*}"; [ "${#bm}" -eq 1 ] && bm="0$bm"; printf '{"usageItems":[{"date":"%s-%s-01T00:00:00Z","product":"actions","sku":"Actions Linux","quantity":42.0,"unitType":"Minutes","pricePerUnit":0.006,"grossAmount":0.0,"discountAmount":0.0,"netAmount":0.0,"repositoryName":"home"}]}\n' "$by" "$bm" | out; exit 0
  fi
  case "$*" in *repos/*) printf '{"default_branch":"main"}\n' | out; exit 0 ;; esac
  printf 'gh: Not Found (HTTP 404)\n' >&2; exit 1
fi
printf 'stub: gh %s is not served\n' "$*" >&2
exit 1
SZSTUB
_sz_put "$SZB/launchctl" <<'SZSTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@SZ@/log/launchctl.log'
case "${1:-}" in print) exit 113 ;; esac
exit 0
SZSTUB

# ---- the repositories ------------------------------------------------------------
_sz_commit() { _fx_git "$1" add -A >/dev/null 2>&1; _fx_git "$1" -c user.name=t -c user.email=t@t commit -qm "$2" >/dev/null 2>&1; }
_fx_git "$SZO" init -q --bare >/dev/null 2>&1
_fx_git "$SZO" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
_fx_git "$SZ" clone -q "$SZO" home >/dev/null 2>&1
_fx_git "$SZH" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
mkdir -p "$SZH/projects/felix" "$SZH/notes"
printf '{\n  "name": "felix",\n  "remote_match": "github.com/fixture/home",\n  "gate": "true"\n}\n' > "$SZH/projects/felix/project.json"
printf '# felix\n' > "$SZH/projects/felix/CLAUDE.md"
{ printf 'red\tpath\t^conf/one/\tonly some lines matter\treviewed\t^[-+]zz\n'
  printf 'red\tpath\t^conf/two/\tonly some lines matter too\treviewed\t^[-+]yy\n'
  printf 'red\tpath\t^plainrisk/\ta person reads these\treviewed\t-\n'; } > "$SZH/projects/felix/risk.tsv"
printf 'home\n' > "$SZH/README.md"; printf 'keep\n' > "$SZH/notes/keep.md"
_sz_commit "$SZH" base
_fx_git "$SZH" push -q -u origin main >/dev/null 2>&1
_fx_git "$SZH" fetch -q origin >/dev/null 2>&1
_fx_git "$SZH" remote set-head origin main >/dev/null 2>&1
SZMAIN="$(git -C "$SZH" rev-parse refs/remotes/origin/main 2>/dev/null)"
# The checkout whose directory name holds a tab: its origin URL holds a tab, so
# no owner/name slug can be read; origin/main and origin/HEAD are set by hand.
_fx_git "$SZD" init -q >/dev/null 2>&1
_fx_git "$SZD" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
printf 'tab\n' > "$SZD/README.md"; _sz_commit "$SZD" base
_fx_git "$SZD" remote add origin "$SZ/github.com/fixture/ta${SZTAB}by.git" >/dev/null 2>&1
_fx_git "$SZD" update-ref refs/remotes/origin/main HEAD >/dev/null 2>&1
_fx_git "$SZD" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main >/dev/null 2>&1

# ---- pull requests as gh lists them ----------------------------------------------
_sz_sha() { printf '%04d%s' "$1" c0ffeec0ffeec0ffeec0ffeec0ffeec0ffee; }
SZ_UPD="$(date -u -r "$(( $(date +%s) - 7200 ))" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$(( $(date +%s) - 7200 ))" +%Y-%m-%dT%H:%M:%SZ)"
_sz_pr() {   # N TITLE FILES [labels=L] [check=NAME] [concl=C]: MERGEABLE, not a draft, its own head branch
  local n="$1" t="$2" fs="$3" kv lb="" ck=gate cc=SUCCESS s="" f fl=""
  shift 3
  for kv in "$@"; do case "$kv" in labels=*) lb="{\"name\":\"${kv#labels=}\"}" ;; check=*) ck="${kv#check=}" ;; concl=*) cc="${kv#concl=}" ;; esac; done
  for f in $fs; do fl="$fl$s{\"path\":\"$f\",\"additions\":1,\"deletions\":0}"; s=","; done
  printf '{"number":%s,"title":"%s","headRefName":"b%s","headRefOid":"%s","baseRefName":"main","isDraft":false,"isCrossRepository":false,' "$n" "$t" "$n" "$(_sz_sha "$n")"
  printf '"author":{"login":"fixture"},"labels":[%s],"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN",' "$lb"
  printf '"statusCheckRollup":[{"__typename":"CheckRun","name":"%s","workflowName":"%s","status":"COMPLETED","conclusion":"%s"}],' "$ck" "$ck" "$cc"
  printf '"files":[%s],"updatedAt":"%s"}' "$fl" "$SZ_UPD"
}
_sz_prs() { local k="$1" s="" o; shift; { printf '['; for o in "$@"; do printf '%s%s' "$s" "$o"; s=","; done; printf ']\n'; } > "$SZK/prs.$k.json"; }
SZ_DEL="$(printf 'del\177mark')"
SZ_C80="$(printf 'cA\302\200mark')"; SZ_C9F="$(printf 'cB\302\237mark')"; SZ_C9B="$(printf 'cC\302\233mark')"
SZ_KEEP="$(printf 'nb\302\240caf\303\251 mark')"
SZF=needs-founder
_sz_prs fixture_home \
  "$(_sz_pr 300 'esc\u001bmark' notes/300.md labels=$SZF)" "$(_sz_pr 301 'bel\u0007mark' notes/301.md labels=$SZF)" \
  "$(_sz_pr 302 "$SZ_DEL" notes/302.md labels=$SZF)" "$(_sz_pr 303 "$SZ_C80" notes/303.md labels=$SZF)" \
  "$(_sz_pr 304 "$SZ_C9F" notes/304.md labels=$SZF)" "$(_sz_pr 305 "$SZ_C9B" notes/305.md labels=$SZF)" \
  "$(_sz_pr 306 'tab\ttitle' notes/306.md labels=$SZF)" "$(_sz_pr 307 'nl\nline' notes/307.md labels=$SZF)" \
  "$(_sz_pr 308 "$SZ_KEEP" notes/308.md labels=$SZF)" "$(_sz_pr 309 'plain mark' notes/309.md labels=$SZF)" \
  "$(_sz_pr 310 'Change 310' notes/310.md 'check=lint\u001bx' concl=FAILURE)" \
  "$(_sz_pr 311 'Change 311' 'notes/esc\u001bp.md')" \
  "$(_sz_pr 320 'Change 320' notes/320.md)" "$(_sz_pr 321 'Change 321' notes/321.md)" \
  "$(_sz_pr 330 'Change 330' 'conf/one/a.md conf/one/b.md conf/one/c.md conf/one/d.md')" \
  "$(_sz_pr 331 'Change 331' 'conf/one/a.md conf/one/b.md conf/two/a.md conf/two/b.md conf/two/c.md')" \
  "$(_sz_pr 332 'Change 332' conf/one/z.md)" "$(_sz_pr 333 'Change 333' plainrisk/a.md)"
_sz_prs fixture_ta_by "$(_sz_pr 340 'Change 340' notes/340.md)"
cp "$SZK/prs.fixture_ta_by.json" "$SZK/prs.tab_dir.json"
# The ledger: a refusal of #320's head on the current main and a skip of #321's
# head, each detail holding ESC; the paused file's reason holds ESC too.
rm -rf "$SZLAND"; mkdir -p "$SZLAND"
{ printf '2026-10-17T09:10:00Z\trefused\t320\t%s\t%s\t3\tstale\033receipt [main %s]\n' "$(_sz_sha 320)" "$SZH" "$SZMAIN"
  printf '2026-10-17T09:11:00Z\tskip\t321\t%s\t-\t0\twait\033ing\n' "$(_sz_sha 321)"; } > "$SZLAND/ledger.tsv"
printf 'held\033now\nthe second line\n' > "$SZLAND/paused"

# ---- running the page and reading it ----------------------------------------------
_sz_land() {   # ARGS... in the home; stdout to out/out, status in SZRC
  rm -rf "$SZL"; mkdir -p "$SZL"
  ( cd "$SZH" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u CLAUDE_CODE_SESSION_ID \
      HOME="$SZU" FELIX_HOME="$SZH" FELIX_HOME_DIR="$SZH" FELIX_MEMORY="$SZM" FELIX_PLUGIN_CACHE="$SZ/cache" \
      GH_CONFIG_DIR="$SZU/.config/gh" TMPDIR="$SZT" PATH="$SZB:$PATH" "$FELIX" land "$@" ) > "$SZX/out" 2> "$SZX/err"
  SZRC=$?
}
_sz_keep() { cp "$SZX/out" "$SZX/$1"; printf '%s\n' "$SZRC" > "$SZX/$1.rc"; }
_sz_row()   { LC_ALL=C awk -F'\t' -v r="#$2" '$1 == "pr" && $3 == r' "$1" 2>/dev/null; }
_sz_nrow()  { _sz_row "$1" "$2" | LC_ALL=C awk 'END { print NR }'; }
_sz_f()     { _sz_row "$1" "$2" | LC_ALL=C awk -F'\t' -v k="$3" 'NR == 1 { printf "%s", $k }'; }
_sz_state() { _sz_f "$1" "$2" 4 | LC_ALL=C sed 's/,.*//'; }
_sz_srcf()  { LC_ALL=C awk -F'\t' -v r="$2" -v k="$3" '$1 == "source" && $3 == r { printf "%s", $k; exit }' "$1" 2>/dev/null; }
_sz_tline() { LC_ALL=C awk -v p="#$2 " 'index($0, p) == 1' "$1" 2>/dev/null; }
_sz_lacks() { case "$2" in *"$3"*) bad "$1" "[$2] holds [$3]" ;; *) ok "$1" ;; esac; }
_sz_cols()  { LC_ALL=C awk -F'\t' 'NF != 8 { print NR ": " NF " columns" }' "$1" | head -3; [ -s "$1" ] || echo empty; }
# The bytes R8 keeps from a terminal, counted in a file: below space but tab and
# newline, DEL, and 0x80 to 0x9f after 0xc2.
_sz_ctl() { LC_ALL=C od -An -v -tu1 "$1" | LC_ALL=C awk '{ for (i = 1; i <= NF; i++) { b = $i + 0
  if ((b < 32 && b != 9 && b != 10) || b == 127 || (p == 194 && b >= 128 && b <= 159)) n++; p = b } } END { print n + 0 }'; }
# A two-byte UTF-8 lead (0xc2 to 0xdf) not followed by a continuation byte, in a string.
_sz_lone() { printf '%s\n' "$1" | LC_ALL=C od -An -v -tu1 | LC_ALL=C awk '{ for (i = 1; i <= NF; i++) { b = $i + 0
  if (w && (b < 128 || b > 191)) n++; w = (b >= 194 && b <= 223) } } END { print n + w }'; }
# How many times S stands in TEXT.
_sz_occ() { printf '%s' "$1" | LC_ALL=C awk -v s="$2" 'BEGIN { RS = "\001" } { t = $0; while ((i = index(t, s)) > 0) { n++; t = substr(t, i + length(s)) } } END { print n + 0 }'; }
# A C1 control shown as ? in LINE: PRE, one ? (or one per byte), then POST.
_sz_q() {   # LABEL LINE PRE POST
  case "$2" in *"$3?$4"*|*"$3??$4"*) ok "$1" ;; *) bad "$1" "[$2] lacks [$3?$4]" ;; esac
}

# ---- fixture controls ----------------------------------------------------------------
is "the terminal fixture: origin/main holds the two confined risk rows and the plain one (fixture control)" \
   "$(git -C "$SZH" show refs/remotes/origin/main:projects/felix/risk.tsv 2>&1 | LC_ALL=C cut -f3,6 | LC_ALL=C tr '\t\n' ' |')" \
   "^conf/one/ ^[-+]zz|^conf/two/ ^[-+]yy|^plainrisk/ -|"
is "the terminal fixture: the second checkout's directory name and origin URL hold a tab, and origin/HEAD names main (fixture control)" \
   "$(printf '%s' "${SZD##*/}" | LC_ALL=C od -An -c | LC_ALL=C tr -d ' \n')|$(git -C "$SZD" config --get remote.origin.url 2>/dev/null | LC_ALL=C grep -c "ta${SZTAB}by")|$(git -C "$SZD" symbolic-ref -q refs/remotes/origin/HEAD 2>&1)" \
   'tab\tdir|1|refs/remotes/origin/main'
if command -v jq >/dev/null 2>&1; then
  is "the terminal fixture: gh's answer is JSON, and #300's title decodes to an ESC byte, #305's to C2 9B (fixture control)" \
     "$(jq -r '.[] | select(.number == 300) | .title' "$SZK/prs.fixture_home.json" 2>&1 | LC_ALL=C od -An -b | LC_ALL=C tr -s ' ' | LC_ALL=C sed 's/^ //; s/ $//')|$(jq -r '.[] | select(.number == 305) | .title' "$SZK/prs.fixture_home.json" 2>&1 | LC_ALL=C od -An -b | LC_ALL=C tr -s ' ' | LC_ALL=C sed 's/^ //; s/ $//')" \
     '145 163 143 033 155 141 162 153 012|143 103 302 233 155 141 162 153 012'
  is "the terminal fixture: #310's check name and #311's path decode to an ESC byte (fixture control)" \
     "$(jq -r '.[] | select(.number == 310) | .statusCheckRollup[0].name' "$SZK/prs.fixture_home.json" 2>&1 | LC_ALL=C grep -c "$SZESC")|$(jq -r '.[] | select(.number == 311) | .files[0].path' "$SZK/prs.fixture_home.json" 2>&1 | LC_ALL=C grep -c "$SZESC")" "1|1"
else skip "the terminal fixture: gh's answer is JSON (fixture control)" "no jq"; fi
is "the terminal fixture: the ledger's two details and the paused reason hold ESC (fixture control)" \
   "$(LC_ALL=C grep -c "$SZESC" "$SZLAND/ledger.tsv")|$(LC_ALL=C grep -c "$SZESC" "$SZLAND/paused")" "2|1"

# ---- R5, clarified: a checkout directory name holding a tab, no slug (--prs) ----------
_sz_land --prs --tsv; _sz_keep home.tsv
T="$SZX/home.tsv"
is "R5 control: the home's page exits 0" "$(cat "$T.rc")" 0
is "R5 control: the home's slug is read: every row's repo cell is fixture/home" \
   "$(LC_ALL=C awk -F'\t' '$2 != "fixture/home" { print NR ": [" $2 "]" }' "$T" | head -3)" ""
_sz_lacks "R5 control: and its gh source row says nothing of a slug" "$(_sz_srcf "$T" gh 8)" "slug"
_sz_land --prs --tsv --repo "$SZD"; _sz_keep tabdir.tsv
_sz_land --prs --repo "$SZD"; _sz_keep tabdir.txt
T="$SZX/tabdir.tsv"
is "R5 clarified: --prs --tsv --repo on a directory whose name holds a tab exits 0, and so does the text page" "$(cat "$T.rc")$(cat "$SZX/tabdir.txt.rc")" 00
is "R5 clarified: it prints rows (control)" "$(LC_ALL=C awk 'END { print (NR > 0) ? "rows" : "none" }' "$T")" rows
is "R5 clarified: every row of that page has exactly eight columns" "$(_sz_cols "$T")" ""
is "R5 clarified: every row's repo cell is the directory's name with a space where the tab was" \
   "$(LC_ALL=C awk -F'\t' '$2 != "tab dir" { print NR ": [" $2 "]" }' "$T" | head -3)" ""
_szg="$(_sz_srcf "$T" gh 8)"
has "R5 clarified: the gh source row speaks of the slug" "$_szg" "slug"
case "$_szg" in
  *"could not be read"*|*"cannot be read"*|*"not read"*|*unreadable*) ok "R5 clarified: and says it could not be read" ;;
  *) bad "R5 clarified: and says it could not be read" "[$_szg]" ;;
esac
is "R5 clarified: the text page's header line holds no tab" \
   "$(LC_ALL=C sed -n 1p "$SZX/tabdir.txt" | LC_ALL=C awk -v t="$SZTAB" 'index($0, t) { print "tab: " $0 }')" ""
is "R5 clarified: and no line of the text page holds the directory's name with its tab" \
   "$(LC_ALL=C grep -c "tab${SZTAB}dir" "$SZX/tabdir.txt")" 0

# ---- R8, its reach: --prs, TSV and text ------------------------------------------------
printf '1\n' > "$SZK/bill.users.rc"; printf 'gh: bad\033gateway (HTTP 502)\n' > "$SZK/bill.users.err"
_sz_land --prs --tsv; _sz_keep r8.tsv
_sz_land --prs; _sz_keep r8.txt
rm -f "$SZK"/bill.*
T="$SZX/r8.tsv"; X="$SZX/r8.txt"
is "R8: --prs exits 0 over titles, a check name, a path, a ledger and a paused reason holding controls, TSV and text" "$(cat "$T.rc")$(cat "$X.rc")" 00
is "R8 control: every pull request of the list has a row" \
   "$(LC_ALL=C awk -F'\t' '$1 == "pr" { n++ } END { print n + 0 }' "$T")" 18
is "R8: no byte below space but tab and newline, no DEL and no C1 control reaches the --prs --tsv page" "$(_sz_ctl "$T")" 0
is "R8: nor the --prs text page" "$(_sz_ctl "$X")" 0
is "R8: every row of the --prs --tsv page has exactly eight columns" "$(_sz_cols "$T")" ""
has "R8: a title holding ESC shows it as ?" "$(_sz_tline "$X" 300)" "esc?mark"
has "R8: a title holding BEL shows it as ?" "$(_sz_tline "$X" 301)" "bel?mark"
has "R8: a title holding DEL shows it as ?" "$(_sz_tline "$X" 302)" "del?mark"
_sz_q "R8: a title holding C2 80, the first C1 control, shows it as ?" "$(_sz_tline "$X" 303)" cA mark
_sz_q "R8: a title holding C2 9F, the last C1 control, shows it as ?" "$(_sz_tline "$X" 304)" cB mark
_sz_q "R8: a title holding C2 9B shows it as ?" "$(_sz_tline "$X" 305)" cC mark
is "R8: no C1 control leaves a lone C2 lead byte on the text page" \
   "$(_sz_lone "$(_sz_tline "$X" 303)")$(_sz_lone "$(_sz_tline "$X" 304)")$(_sz_lone "$(_sz_tline "$X" 305)")" 000
has "R8: a tab inside a title becomes a space" "$(_sz_tline "$X" 306)" "tab title"
is "R8: and the line holds no tab" "$(_sz_tline "$X" 306 | LC_ALL=C awk -v t="$SZTAB" 'index($0, t) { n++ } END { print n + 0 }')" 0
has "R8: a newline inside a title becomes a space" "$(_sz_tline "$X" 307)" "nl line"
is "R8: and no line of the text page begins with what followed the newline" "$(LC_ALL=C awk 'index($0, "line") == 1' "$X" | head -2)" ""
is "R8: the pull requests whose titles hold a tab and a newline are one row each" "$(_sz_nrow "$T" 306)$(_sz_nrow "$T" 307)" 11
has "R8 control: NBSP (C2 A0) and an accented letter are not controls and reach the page as they are" "$(_sz_tline "$X" 308)" "$SZ_KEEP"
has "R8 control: a plain title reaches the page unchanged" "$(_sz_tline "$X" 309)" "plain mark"
is "R8 control: the pull request with a failed check is red" "$(_sz_state "$T" 310)" red
_szd="$(_sz_f "$T" 310 8)"
case "$_szd" in
  *lint*) has "R8: a check name holding ESC shows it as ? in the detail" "$_szd" "lint?x" ;;
  *) skip "R8: a check name holding ESC shows it as ? in the detail" "the detail names no check: [$_szd]" ;;
esac
case "$(_sz_tline "$X" 310)" in
  *lint*) has "R8: and on the text page" "$(_sz_tline "$X" 310)" "lint?x" ;;
  *) skip "R8: and on the text page" "the line names no check" ;;
esac
is "R8 control: the pull request whose path holds ESC is founder" "$(_sz_state "$T" 311)" founder
_szd="$(_sz_f "$T" 311 8)"
case "$_szd" in
  *notes/esc*) has "R8: a changed path holding ESC shows it as ? in the detail" "$_szd" "notes/esc?p.md" ;;
  *) skip "R8: a changed path holding ESC shows it as ? in the detail" "the detail names no path: [$_szd]" ;;
esac
case "$(_sz_tline "$X" 311)" in
  *notes/esc*) has "R8: and on the text page" "$(_sz_tline "$X" 311)" "notes/esc?p.md" ;;
  *) skip "R8: and on the text page" "the line names no path" ;;
esac
is "R8 control: the ledger refused #320's head on the current main: refused" "$(_sz_state "$T" 320)" refused
has "R8: the ledger's detail holding ESC shows it as ?, in a refusal" "$(_sz_f "$T" 320 8)" "the lander was refused: stale?receipt"
has "R8: and on the text page" "$(_sz_tline "$X" 320)" "stale?receipt"
has "R8: the ledger's detail holding ESC shows it as ?, in a skip" "$(_sz_f "$T" 321 8)" "the lander: skip: wait?ing"
has "R8 control: the lander row says paused yes" "$(_sz_srcf "$T" lander 8)" "paused yes"
has "R8: the paused reason holding ESC shows it as ?" "$(_sz_srcf "$T" lander 8)" "held?now"
is "R8 control: the billing GET failed: the budget row says unread" "$(_sz_srcf "$T" budget 4)" unread
has "R8: gh's error line holding ESC shows it as ?" "$(_sz_srcf "$T" budget 8)" "bad?gateway"

# ---- R8, its reach: --queue, TSV and text ----------------------------------------------
_sz_land --queue --tsv; _sz_keep q.tsv
_sz_land --queue; _sz_keep q.txt
T="$SZX/q.tsv"; X="$SZX/q.txt"
is "R8: --queue exits 0, TSV and text" "$(cat "$T.rc")$(cat "$X.rc")" 00
is "R8 control: --queue lists the founder pull request #300 once" "$(_sz_nrow "$T" 300)" 1
is "R8 control: and #311, founder by its path" "$(_sz_nrow "$T" 311)" 1
is "R8 control: and not the red #310" "$(_sz_nrow "$T" 310)" 0
is "R8: no byte below space but tab and newline, no DEL and no C1 control reaches the --queue --tsv page" "$(_sz_ctl "$T")" 0
is "R8: nor the --queue text page" "$(_sz_ctl "$X")" 0
is "R8: every row of the --queue --tsv page has exactly eight columns" "$(_sz_cols "$T")" ""
is "R8: the pull requests whose titles hold a tab and a newline are one --queue row each" "$(_sz_nrow "$T" 306)$(_sz_nrow "$T" 307)" 11
has "R8: in --queue, a title holding ESC shows it as ?" "$(_sz_tline "$X" 300)" "esc?mark"
has "R8: in --queue, a title holding BEL shows it as ?" "$(_sz_tline "$X" 301)" "bel?mark"
has "R8: in --queue, a title holding DEL shows it as ?" "$(_sz_tline "$X" 302)" "del?mark"
_sz_q "R8: in --queue, a title holding C2 80 shows it as ?" "$(_sz_tline "$X" 303)" cA mark
_sz_q "R8: in --queue, a title holding C2 9F shows it as ?" "$(_sz_tline "$X" 304)" cB mark
_sz_q "R8: in --queue, a title holding C2 9B shows it as ?" "$(_sz_tline "$X" 305)" cC mark
has "R8: in --queue, a tab inside a title becomes a space" "$(_sz_tline "$X" 306)" "tab title"
has "R8: in --queue, a newline inside a title becomes a space" "$(_sz_tline "$X" 307)" "nl line"
has "R8 control: in --queue, a plain title reaches the page unchanged" "$(_sz_tline "$X" 309)" "plain mark"

# ---- R10: a confined risk row listed once ----------------------------------------------
T="$SZX/r8.tsv"; X="$SZX/r8.txt"
is "R10 control: a plain risk row (no confine) makes #333 founder" "$(_sz_state "$T" 333)" founder
is "R10 control: one path under one confined row: #332 is not founder, it is ready" "$(_sz_state "$T" 332)" ready
is "R10 control: and its detail lists the row once" "$(_sz_occ "$(_sz_f "$T" 332 8)" "risk row not evaluated")" 1
has "R10: one path under one confined row: the detail names the row's pattern" "$(_sz_f "$T" 332 8)" "^conf/one/"
_szd="$(_sz_f "$T" 330 8)"
is "R10: four paths under one confined row and no other rule: #330 is ready" "$(_sz_state "$T" 330)" ready
is "R10: its detail lists the confined row exactly once" "$(_sz_occ "$_szd" "risk row not evaluated")" 1
has "R10: as content confine, the pattern, the count 4 and the first path" "$_szd" "risk row not evaluated: content confine, ^conf/one/, for 4 paths: conf/one/a.md"
is "R10: the detail never repeats the phrase per path" "$(_sz_occ "$_szd" "content confine")" 1
_sz_lacks "R10: and names only the first path" "$_szd" "conf/one/d.md"
is "R10: on the text page too, #330's line lists the row once" "$(_sz_occ "$(_sz_tline "$X" 330)" "risk row not evaluated")" 1
_szd="$(_sz_f "$T" 331 8)"
is "R10: two different confined rows: #331 is ready" "$(_sz_state "$T" 331)" ready
is "R10: its detail lists exactly two confined rows" "$(_sz_occ "$_szd" "risk row not evaluated")" 2
has "R10: the first row once, with its count 2 and first path" "$_szd" "content confine, ^conf/one/, for 2 paths: conf/one/a.md"
has "R10: the second row once, with its count 3 and first path" "$_szd" "content confine, ^conf/two/, for 3 paths: conf/two/a.md"
is "R10: each pattern is named once" "$(_sz_occ "$_szd" "^conf/one/")$(_sz_occ "$_szd" "^conf/two/")" 11

# ---- the fixture is removed -------------------------------------------------------------
chmod -R u+rwx "$SZ" 2>/dev/null; rm -rf "$SZ"
[ -e "$SZ" ] && bad "the terminal fixture is removed when its part ends" "$SZ is still there" || ok "the terminal fixture is removed when its part ends"
# <<< stuck-pr-page-terminal-and-risk
