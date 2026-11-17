# >>> stuck-pr-page-amendments
printf '\nthe stuck-PR page: amendments R1-R6, the default branch with no checkout, one billing call, the origin row, how old main is, the repo cell, one repository read once (spec v2, blind)\n'
# Blind, written on 2026-10-17 from spec v2 and its section "Amended after
# review, 2026-10-17" (audits/2026-10-01-report-v5-review/specs/stuck-pr/
# spec-v2.md), without reading lib/pr-status*.sh or felix_land. Parts 1300 and
# 1330 were read only for how their fixture and stubs are built. Self-contained
# after the preamble: it builds its own fixture under $TMP and removes it.
#
# The fixture: a bare origin whose path ends github.com/fixture/home.git and a
# clone of it that is also the Felix home. The home holds projects felix
# (remote_match github.com/fixture/home), two (github.com/fixture/two, cloned
# nowhere), three (github.com/fixture/three, a clone with no origin/main and
# no origin/HEAD) and zeta (Fixture/Home: the home's repository again, in
# another case and without the host). gh and launchctl are stubs first on PATH,
# each logging its argv. gh answers pr list from ctl/prs.<key>.json, the key
# being the repository from -R or --repo, else from the origin of the directory
# it runs in, lowercased, with every byte but a letter or digit made _ (GitHub
# folds case). It answers a GET of repos/<owner>/<name> with the default branch
# in ctl/dflt.<key>, else main. It answers the usage report's GETs of
# users/<o>/settings/billing/usage?year=Y&month=M and orgs/<o>/... as
# ctl/bill.users.* and ctl/bill.orgs.* say: .rc, .err and .out make a failed GET
# (exit .rc, .err on stderr, .out on stdout); else .body is the answer; else one
# item of 100 minutes. In .out and .body, @YM@ becomes the month asked as YYYY-MM
# and @YO@ that month a year earlier. A GET of the retired settings/billing/actions
# is answered 410, so asking it shows.
# 2026-11-12: the R2 block (one billing call) was replaced by R13's, written blind
# from amendment-r13-budget-usage-report.md (same specs/stuck-pr/ directory),
# without reading lib/ or felix; R1's filter now names the usage report.
SA="$TMP/stuck-pr-amend"; mkdir -p "$SA"; SA="$(cd "$SA" && pwd -P)"
SAO="$SA/github.com/fixture/home.git"; SAH="$SA/home"; SA3O="$SA/github.com/fixture/three.git"; SA3="$SA/three"
SAM="$SA/mem"; SAU="$SA/user"; SAB="$SA/bin"; SAK="$SA/ctl"; SAL="$SA/log"; SAX="$SA/out"; SAT="$SA/tmp"
SATAB="$(printf '\t')"
mkdir -p "$SAO" "$SA3O" "$SAM" "$SAU/.config/gh" "$SAB" "$SAK" "$SAL" "$SAX" "$SAT" "$SA/cache"
_sa_put() { mkdir -p "$(dirname "$1")" && LC_ALL=C sed "s#@SA@#$SA#g" > "$1" && chmod +x "$1"; }
_sa_put "$SAB/gh" <<'SASTUB'
#!/bin/bash
SA='@SA@'; K="$SA/ctl"
printf '%s\n' "$*" >> "$SA/log/gh.log"
jqx=""; repo=""; prev=""; bill=""; rget=""; bq=""
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; -R|--repo) repo="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; --repo=*) repo="${a#--repo=}" ;; esac
  case "$a" in
    *settings/billing/actions*) bill=retired ;;
    *users/*/settings/billing/usage*) bill=users; case "$a" in *\?*) bq="${a#*\?}" ;; esac ;;
    *orgs/*/settings/billing/usage*) bill=orgs; case "$a" in *\?*) bq="${a#*\?}" ;; esac ;;
    repos/*|/repos/*) rget="${a#/}"; rget="${rget#repos/}" ;;
  esac
  prev="$a"
done
# The usage report's items are dated from the year= and month= asked: @YM@ is that month as YYYY-MM, @YO@ the same month a year earlier.
y=""; m=""
case "&$bq&" in *"&year="*) y="${bq#*year=}"; y="${y%%&*}" ;; esac
case "&$bq&" in *"&month="*) m="${bq#*month=}"; m="${m%%&*}" ;; esac
case "$y" in ''|*[!0123456789]*) y="" ;; esac; case "$m" in ''|*[!0123456789]*) m="" ;; esac
if [ -n "$y" ] && [ -n "$m" ]; then mm="$m"; [ "${#mm}" -lt 2 ] && mm="0$mm"; ym="$y-$mm"; yo="$((y - 1))-$mm"; else ym="0000-00"; yo="1999-01"; fi
dated() { LC_ALL=C sed -e "s/@YM@/$ym/g" -e "s/@YO@/$yo/g" "$1"; }
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
  if [ "$bill" = retired ]; then
    printf '{"message":"This endpoint has been moved","documentation_url":"https://docs.github.com/rest","status":"410"}'
    printf 'gh: This endpoint has been moved. (HTTP 410)\n' >&2; exit 1
  fi
  if [ -n "$bill" ]; then
    if [ -f "$K/bill.$bill.rc" ]; then
      [ -f "$K/bill.$bill.out" ] && dated "$K/bill.$bill.out"
      cat "$K/bill.$bill.err" >&2; exit "$(cat "$K/bill.$bill.rc")"
    fi
    if [ -f "$K/bill.$bill.body" ]; then dated "$K/bill.$bill.body" | out; exit 0; fi
    printf '{"usageItems":[{"date":"%s-03T00:00:00Z","product":"actions","sku":"Actions Linux","quantity":100.0,"unitType":"Minutes","pricePerUnit":0.006,"grossAmount":0.6,"discountAmount":0.6,"netAmount":0.0,"repositoryName":"home"}]}' "$ym" | out; exit 0
  fi
  if [ -n "$rget" ]; then
    k="$(key "$rget")"; d=main; [ -f "$K/dflt.$k" ] && d="$(cat "$K/dflt.$k")"
    printf '{"full_name":"%s","default_branch":"%s"}\n' "$rget" "$d" | out; exit 0
  fi
  printf 'gh: Not Found (HTTP 404)\n' >&2; exit 1
fi
printf 'stub: gh %s is not served\n' "$*" >&2
exit 1
SASTUB
_sa_put "$SAB/launchctl" <<'SASTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@SA@/log/launchctl.log'
case "${1:-}" in print) exit 113 ;; esac
exit 0
SASTUB
# date (A1): the real date, found before the stubs were first on PATH, unless ctl/date.at holds an epoch; then the
# caller's arguments run against that instant (-r on BSD, -d @ on GNU).
command -v date > "$SA/realdate"
_sa_put "$SAB/date" <<'SASTUB'
#!/bin/bash
R="$(cat '@SA@/realdate')"
[ -f '@SA@/ctl/date.at' ] || exec "$R" "$@"
e="$(cat '@SA@/ctl/date.at')"
if "$R" -u -r 0 >/dev/null 2>&1; then exec "$R" -r "$e" "$@"; else exec "$R" -d "@$e" "$@"; fi
SASTUB

# ---- the repositories ----------------------------------------------------------
_sa_commit() { _fx_git "$1" add -A >/dev/null 2>&1; _fx_git "$1" -c user.name=t -c user.email=t@t commit -qm "$2" >/dev/null 2>&1; }
_sa_proj() { mkdir -p "$SAH/projects/$1"; printf '{\n  "name": "%s",\n  "remote_match": "%s",\n  "gate": "true"\n}\n' "$1" "$2" > "$SAH/projects/$1/project.json"; printf '# %s\n' "$1" > "$SAH/projects/$1/CLAUDE.md"; }
for _sao in "$SAO" "$SA3O"; do
  _fx_git "$_sao" init -q --bare >/dev/null 2>&1
  _fx_git "$_sao" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
done
_fx_git "$SA" clone -q "$SAO" home >/dev/null 2>&1
_fx_git "$SAH" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
_sa_proj felix github.com/fixture/home; _sa_proj two github.com/fixture/two
_sa_proj three github.com/fixture/three; _sa_proj zeta Fixture/Home
mkdir -p "$SAH/notes"; printf 'home\n' > "$SAH/README.md"; printf 'keep\n' > "$SAH/notes/keep.md"
_sa_commit "$SAH" base
_fx_git "$SAH" push -q -u origin main >/dev/null 2>&1
_fx_git "$SAH" fetch -q origin >/dev/null 2>&1
_fx_git "$SAH" remote set-head origin main >/dev/null 2>&1
_fx_git "$SA" clone -q "$SA3O" three >/dev/null 2>&1
_fx_git "$SA3" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
printf 'three\n' > "$SA3/README.md"; _sa_commit "$SA3" base

# ---- pull requests as gh lists them --------------------------------------------
_sa_sha() { printf '%04d%s' "$1" c0ffeec0ffeec0ffeec0ffeec0ffeec0ffee; }
SA_UPD="$(date -u -r "$(( $(date +%s) - 7200 ))" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$(( $(date +%s) - 7200 ))" +%Y-%m-%dT%H:%M:%SZ)"
SA_GREEN='[{"__typename":"CheckRun","name":"gate","workflowName":"gate","status":"COMPLETED","conclusion":"SUCCESS"}]'
_sa_pr() {   # N BASE [LABEL]: green, MERGEABLE, not a draft, its own head branch, one plain path
  local lb=""; [ -z "${3:-}" ] || lb="{\"name\":\"$3\"}"
  printf '{"number":%s,"title":"Change %s","headRefName":"b%s","headRefOid":"%s","baseRefName":"%s","isDraft":false,"isCrossRepository":false,' "$1" "$1" "$1" "$(_sa_sha "$1")" "$2"
  printf '"author":{"login":"fixture"},"labels":[%s],"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","statusCheckRollup":%s,' "$lb" "$SA_GREEN"
  printf '"files":[{"path":"notes/%s.md","additions":1,"deletions":0}],"updatedAt":"%s"}' "$1" "$SA_UPD"
}
_sa_prs() { local k="$1" s="" o; shift; { printf '['; for o in "$@"; do printf '%s%s' "$s" "$o"; s=","; done; printf ']\n'; } > "$SAK/prs.$k.json"; }
_sa_prs fixture_home "$(_sa_pr 501 main)" "$(_sa_pr 502 trunk)" "$(_sa_pr 601 main needs-founder)" "$(_sa_pr 602 main Felix:Founder)" "$(_sa_pr 603 main)"
_sa_prs fixture_two "$(_sa_pr 701 trunk needs-founder)" "$(_sa_pr 702 main needs-founder)"
printf 'trunk\n' > "$SAK/dflt.fixture_two"
_sa_prs fixture_three "$(_sa_pr 901 main)"
_sa_prs fixture_ta_by "$(_sa_pr 801 main needs-founder)"

# ---- running the page and reading it --------------------------------------------
_sa_land() {   # ARGS... in the home; stdout to out/out, status in SARC; the gh log starts empty
  rm -rf "$SAL"; mkdir -p "$SAL"
  ( cd "$SAH" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u CLAUDE_CODE_SESSION_ID \
      HOME="$SAU" FELIX_HOME="$SAH" FELIX_HOME_DIR="$SAH" FELIX_MEMORY="$SAM" FELIX_PLUGIN_CACHE="$SA/cache" \
      GH_CONFIG_DIR="$SAU/.config/gh" TMPDIR="$SAT" PATH="$SAB:$PATH" "$FELIX" land "$@" ) > "$SAX/out" 2> "$SAX/err"
  SARC=$?
}
_sa_keep() { cp "$SAX/out" "$SAX/$1"; printf '%s\n' "$SARC" > "$SAX/$1.rc"; [ -f "$SAL/gh.log" ] && cp "$SAL/gh.log" "$SAX/$1.gh" || : > "$SAX/$1.gh"; }
_sa_row()   { LC_ALL=C awk -F'\t' -v r="#$2" '$1 == "pr" && $3 == r' "$1" 2>/dev/null; }
_sa_nrow()  { _sa_row "$1" "$2" | LC_ALL=C awk 'END { print NR }'; }
_sa_f()     { _sa_row "$1" "$2" | LC_ALL=C awk -F'\t' -v k="$3" 'NR == 1 { printf "%s", $k }'; }
_sa_state() { _sa_f "$1" "$2" 4 | LC_ALL=C sed 's/,.*//'; }
_sa_srcf()  { LC_ALL=C awk -F'\t' -v r="$2" -v k="$3" '$1 == "source" && $3 == r { printf "%s", $k; exit }' "$1" 2>/dev/null; }
_sa_lacks() { case "$2" in *"$3"*) bad "$1" "[$2] holds [$3]" ;; *) ok "$1" ;; esac; }
_sa_cols()  { LC_ALL=C awk -F'\t' 'NF != 8 { print NR ": " NF " columns" }' "$1" | head -3; [ -s "$1" ] || echo empty; }
# Lines of a gh log: api calls naming a word W exactly, with or without its
# leading slash; and api calls holding a substring S.
_sa_apiw() { LC_ALL=C awk -v w="$2" '$1 == "api" { for (i = 2; i <= NF; i++) if ($i == w || $i == "/" w) { n++; break } } END { print n + 0 }' "$1" 2>/dev/null; }
_sa_apis() { LC_ALL=C awk -v s="$2" '$1 == "api" && index($0, s) { n++ } END { print n + 0 }' "$1" 2>/dev/null; }
# The billing GETs of a gh log in the order asked, as users, orgs (the usage
# report), retired (settings/billing/actions) or other; and the query string of
# the first usage-report GET under users/ or orgs/.
_sa_bills() { LC_ALL=C awk '$1 == "api" && index($0, "settings/billing/") { k = "other"
  if (index($0, "settings/billing/actions")) k = "retired"; else if (index($0, "settings/billing/usage")) { if (index($0, "users/")) k = "users"; else if (index($0, "orgs/")) k = "orgs" }
  s = s (n++ ? "," : "") k } END { printf "%s", s }' "$1" 2>/dev/null; }
_sa_q() { LC_ALL=C awk -v k="$2/" '$1 == "api" { for (i = 2; i <= NF; i++) { w = $i; sub(/^\//, "", w)
  if (index(w, k) == 1 && index(w, "/settings/billing/usage?")) { printf "%s", substr(w, index(w, "?") + 1); exit } } }' "$1" 2>/dev/null; }
# A query's month as YYYY-MM, or unasked; the clock's month in UTC as the query
# writes it; a query shown as SAC1 when it is the clock's month before or after the run.
_sa_ym() { printf '%s\n' "$1" | LC_ALL=C awk '{ s = $0 } END { y = ""; m = ""; n = split(s, p, "&")
  for (i = 1; i <= n; i++) { if (p[i] ~ /^year=[0123456789]+$/) y = substr(p[i], 6); if (p[i] ~ /^month=[0123456789]+$/) m = substr(p[i], 7) }
  if (y == "" || m == "") printf "unasked"; else printf "%04d-%02d", y + 0, m + 0 }'; }
_sa_clock() { local d; d="$(date -u +%Y-%m)"; printf 'year=%s&month=%s' "${d%-*}" "$(( 10#${d#*-} ))"; }
_sa_qn() { if [ -z "$1" ]; then printf 'unasked'; elif [ "$1" = "$SAC1" ] || [ "$1" = "$SAC2" ]; then printf '%s' "$SAC1"; else printf '%s' "$1"; fi; }
# The billing answers per case: _sa_body KIND JSON; _sa_fail KIND RC ERR [OUT] (ERR as printf %b);
# _sa_it DATE PRODUCT SKU QUANTITY UNIT NET is one item, its fields in the order GitHub gave them.
_sa_body() { printf '%s' "$2" > "$SAK/bill.$1.body"; }
_sa_fail() { printf '%s\n' "$2" > "$SAK/bill.$1.rc"; printf '%b' "$3" > "$SAK/bill.$1.err"; rm -f "$SAK/bill.$1.out"; [ -z "${4:-}" ] || printf '%s' "$4" > "$SAK/bill.$1.out"; }
_sa_it() { printf '{"date":"%sT00:00:00Z","product":"%s","sku":"%s","quantity":%s,"unitType":"%s","pricePerUnit":0.006,"grossAmount":1.0,"discountAmount":0.5,"netAmount":%s,"repositoryName":"home"}' "$1" "$2" "$3" "$4" "$5" "$6"; }
# One run of the page for R13: T is its page, SAYM the month its users/ GET asked, SAD the budget detail.
SAALL=""; SARCS=""
_sa_brun() { local n="$1"; shift; SAC1="$(_sa_clock)"; _sa_land --prs --tsv "$@"; _sa_keep "$n"; SAC2="$(_sa_clock)"; T="$SAX/$n"
  SAYM="$(_sa_ym "$(_sa_q "$T.gh" users)")"; SAD="$(_sa_srcf "$T" budget 8)"; SAALL="$SAALL|$SAD"; SARCS="$SARCS$(cat "$T.rc")"; }
# The age in "origin/main last moved <age> ago", and that age in whole hours:
# the first number and the unit after it (s, m, h, d, w, mo, y, or the words).
_sa_moved() { printf '%s' "$1" | LC_ALL=C awk '{ i = index($0, "origin/main last moved "); if (!i) exit
  r = substr($0, i + 23); j = index(r, " ago"); if (j) printf "%s", substr(r, 1, j - 1) }'; }
_sa_hours() { printf '%s' "$1" | LC_ALL=C awk '{ if (!match($0, /[0123456789]+/)) { print "unparsed"; exit }
  n = substr($0, RSTART, RLENGTH) + 0; u = tolower(substr($0, RSTART + RLENGTH)); sub(/^ +/, "", u)
  c = substr(u, 1, 1); c2 = substr(u, 1, 2)
  if (c2 == "mo") h = n * 720; else if (c == "s") h = n / 3600; else if (c == "m") h = n / 60
  else if (c == "h") h = n; else if (c == "d") h = n * 24; else if (c == "w") h = n * 168; else if (c == "y") h = n * 8760
  else { print "unparsed"; exit }
  print int(h) }'; }
_sa_ge() { case "$2" in ''|*[!0123456789]*) bad "$1" "no age in hours: [$2] from [$4]" ;; *) [ "$2" -ge "$3" ] && ok "$1" || bad "$1" "age $2 h is under $3 h: [$4]" ;; esac; }
_sa_lt() { case "$2" in ''|*[!0123456789]*) bad "$1" "no age in hours: [$2] from [$4]" ;; *) [ "$2" -lt "$3" ] && ok "$1" || bad "$1" "age $2 h is not under $3 h: [$4]" ;; esac; }

# ---- fixture controls ------------------------------------------------------------
is "the amendments fixture: origin/HEAD names main, and three has no origin/main and no origin/HEAD (fixture control)" \
   "$(git -C "$SAH" symbolic-ref -q refs/remotes/origin/HEAD 2>&1)|$(git -C "$SA3" rev-parse -q --verify refs/remotes/origin/main 2>/dev/null)|$(git -C "$SA3" symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null)" \
   "refs/remotes/origin/main||"
is "the amendments fixture: no checkout of fixture/two exists under the fixture (fixture control)" \
   "$(find "$SA" -name config -path '*.git*' -exec grep -l 'fixture/two' {} + 2>/dev/null)" ""
is "the amendments fixture: the gh stub answers -R Fixture/Home as fixture/home, and repos/fixture/two with trunk (fixture control)" \
   "$( cd "$SA" && PATH="$SAB:$PATH" gh pr list -R Fixture/Home --state open 2>&1 | LC_ALL=C grep -o '"number":601,' )|$( cd "$SA" && PATH="$SAB:$PATH" gh api repos/fixture/two 2>&1 | LC_ALL=C grep -o '"default_branch":"[a-z]*"' )" \
   '"number":601,|"default_branch":"trunk"'
is "the amendments fixture: the gh stub dates usage items from the month it is asked, and answers the retired billing address 410 (fixture control)" \
   "$( cd "$SA" && PATH="$SAB:$PATH" gh api '/users/fixture/settings/billing/usage?year=2026&month=3' 2>&1 | LC_ALL=C grep -o '"date":"2026-03-03' )|$( cd "$SA" && PATH="$SAB:$PATH" gh api users/fixture/settings/billing/actions >/dev/null 2>"$SAX/retired.err"; echo "$?" )|$(LC_ALL=C grep -c 'HTTP 410' "$SAX/retired.err")" \
   '"date":"2026-03-03|1|1'

# ---- R3: the origin row names the default branch and where it came from ----------
_sa_land --prs --tsv; _sa_keep r3head.tsv
T="$SAX/r3head.tsv"
is "R3: the page with origin/HEAD naming main exits 0" "$(cat "$T.rc")" 0
has "R3: origin/HEAD names main: the origin row says default branch main (origin/HEAD)" "$(_sa_srcf "$T" origin 8)" "default branch main (origin/HEAD)"
_sa_lacks "R3: and does not say the default branch is not read" "$(_sa_srcf "$T" origin 8)" "not read"
is "R3: and a plain green pull request into main was decided: #501 is ready (control)" "$(_sa_state "$T" 501)" ready
is "R3: and one into trunk is stacked (control)" "$(_sa_state "$T" 502)" stacked
_fx_git "$SAH" remote set-head origin -d >/dev/null 2>&1
is "the amendments fixture: origin/HEAD is gone and origin/main stays (fixture control)" \
   "$(git -C "$SAH" symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null)|$(git -C "$SAH" rev-parse -q --verify refs/remotes/origin/main >/dev/null 2>&1 && echo main)" "|main"
_sa_land --prs --tsv; _sa_keep r3main.tsv
T="$SAX/r3main.tsv"
is "R3: the page with origin/main alone exits 0" "$(cat "$T.rc")" 0
has "R3: origin/main alone: the origin row says default branch main (origin/main)" "$(_sa_srcf "$T" origin 8)" "default branch main (origin/main)"
_sa_lacks "R3: and does not say the default branch is not read" "$(_sa_srcf "$T" origin 8)" "not read"
_sa_lacks "R3: and does not credit origin/HEAD" "$(_sa_srcf "$T" origin 8)" "(origin/HEAD)"
is "R3: and #501 into main was decided against it: ready (control)" "$(_sa_state "$T" 501)" ready
is "R3: and #502 into trunk is stacked (control)" "$(_sa_state "$T" 502)" stacked
_fx_git "$SAH" push -q origin main:refs/heads/trunk >/dev/null 2>&1
_fx_git "$SAH" fetch -q origin >/dev/null 2>&1
_fx_git "$SAH" remote set-head origin trunk >/dev/null 2>&1
is "the amendments fixture: origin/HEAD now names trunk (fixture control)" "$(git -C "$SAH" symbolic-ref -q refs/remotes/origin/HEAD 2>&1)" refs/remotes/origin/trunk
_sa_land --prs --tsv; _sa_keep r3trunk.tsv
T="$SAX/r3trunk.tsv"
has "R3: origin/HEAD naming trunk: the origin row says default branch trunk (origin/HEAD)" "$(_sa_srcf "$T" origin 8)" "default branch trunk (origin/HEAD)"
_sa_lacks "R3: and does not say the default branch is not read" "$(_sa_srcf "$T" origin 8)" "not read"
is "R3: origin/HEAD wins over origin/main: #502 into trunk is ready" "$(_sa_state "$T" 502)" ready
is "R3: and #501 into main is stacked" "$(_sa_state "$T" 501)" stacked
_fx_git "$SAH" remote set-head origin main >/dev/null 2>&1
_sa_land --prs --tsv --repo "$SA3"; _sa_keep r3none.tsv
T="$SAX/r3none.tsv"
is "R3: a repository with neither origin/HEAD nor origin/main: the page exits 0 (control)" "$(cat "$T.rc")" 0
has "R3: and its origin row says default branch not read (control)" "$(_sa_srcf "$T" origin 8)" "default branch not read"
is "R3: and its pull request was not decided: #901 is unknown (control)" "$(_sa_state "$T" 901)" unknown

# ---- R13: the budget row reads GitHub's usage report ------------------------------
# Blind, 2026-11-12, from amendment-r13-budget-usage-report.md alone. The stub
# dates items from the query asked, so no case races the end of a month; every
# month expected below is the one the gh log shows was asked. Sums stay away
# from an exact half.
SAU1=users/fixture/settings/billing/usage; SAO1=orgs/fixture/settings/billing/usage
rm -f "$SAK"/bill.*
# Minutes over two SKUs in minutes (one product and unit in another case, its fields in another order); storage's net
# counted and its quantity not; another product left out. 1430.0 + 120.4 = 1550.4; 2.874... + 0.25 + 1.2 = 4.324.
_sa_body users "{\"usageItems\":[$(_sa_it @YM@-03 actions 'Actions Linux' 1430.0 Minutes 2.8740000000000006),$(_sa_it @YM@-04 actions 'Actions storage' 500.0 GigabyteHours 0.25),$(_sa_it @YM@-02 copilot 'Copilot Business' 900.0 Minutes 19.0),{\"netAmount\":1.2,\"repositoryName\":\"home\",\"unitType\":\"minutes\",\"quantity\":120.4,\"sku\":\"Actions macOS\",\"product\":\"Actions\",\"date\":\"@YM@-05T00:00:00Z\"}]}"
_sa_brun r13sum.tsv
is "R13: the budget row's report answers: the page exits 0" "$(cat "$T.rc")" 0
is "R13: the page asks the users/ usage report for the clock's year and month in UTC, the month without a leading zero" "$(_sa_qn "$(_sa_q "$T.gh" users)")" "$SAC1"
is "R13: and that GET is of users/<owner>/settings/billing/usage?year=Y&month=M, nothing more in the path" "$(_sa_apiw "$T.gh" "$SAU1?$(_sa_qn "$(_sa_q "$T.gh" users)")")" 1
is "R13: an answered users/ GET is the only billing GET: no orgs/ GET and never the retired settings/billing/actions" "$(_sa_bills "$T.gh")" users
is "R13: an answered report makes the budget row read" "$(_sa_srcf "$T" budget 4)" read
has "R13: minutes are summed over every SKU in minutes, unit and product compared without case, storage's quantity left out" "$SAD" "1550 Actions minutes used in $SAYM"
has "R13: net is summed over the counted items, storage's included, another product's not" "$SAD" ", net \$4.32"
is "R13: the whole detail of a read report" "$SAD" "1550 Actions minutes used in $SAYM, net \$4.32"
_sa_lacks "R13: the row says nothing of another product" "$SAD" "opilot"
# An answer spread over several lines with spaces, its numbers in exponent form: 1.2e3 + 30.0 = 1230; 9.6e-05 + 1.5 = 1.500096.
printf '{\n  "usageItems" : [\n    {\n      "product" : "actions",\n      "date" : "@YM@-07T00:00:00Z",\n      "unitType" : "Minutes",\n      "quantity" : 1.2e3,\n      "netAmount" : 9.6e-05\n    },\n    {\n      "date" : "@YM@-08T00:00:00Z", "product" : "actions", "sku" : "Actions Linux", "unitType" : "Minutes",\n      "quantity" : 30.0, "netAmount" : 1.5\n    }\n  ]\n}\n' > "$SAK/bill.users.body"
_sa_brun r13lines.tsv
is "R13: a report spread over several lines, with numbers holding an exponent, is read" "$(_sa_srcf "$T" budget 4)" read
is "R13: and summed as JSON: the whole detail" "$SAD" "1230 Actions minutes used in $SAYM, net \$1.50"
# Actions items dated outside the asked month, two of them, and another product's outside it too, which is not counted among them.
_sa_body users "{\"usageItems\":[$(_sa_it @YM@-09 actions 'Actions Linux' 60.0 Minutes 0.36),$(_sa_it @YO@-09 actions 'Actions Linux' 77.0 Minutes 3.0),$(_sa_it @YO@-28 actions 'Actions storage' 5.0 GigabyteHours 0.01),$(_sa_it @YO@-01 copilot 'Copilot Business' 10.0 Minutes 1.0)]}"
_sa_brun r13out.tsv
is "R13: Actions items dated outside the asked month are not counted and are told by number at the end of the detail" "$SAD" "60 Actions minutes used in $SAYM, net \$0.36; Actions items dated outside $SAYM, not counted: 2"
_sa_body users '{"usageItems":[]}'
_sa_brun r13empty.tsv
is "R13: an empty usageItems list is read" "$(_sa_srcf "$T" budget 4)" read
is "R13: and reads zero minutes and no net" "$SAD" "0 Actions minutes used in $SAYM, net \$0.00"
_sa_body users '{"total_minutes_used":77,"total_paid_minutes_used":0,"included_minutes":2000}'
_sa_brun r13nokey.tsv
is "R13: an answer with no usageItems key leaves the budget row unread" "$(_sa_srcf "$T" budget 4)" unread
has "R13: and says the usage report holds no usageItems" "$SAD" "the usage report holds no usageItems"
is "R13: A3: no usageItems key: the detail is exactly that the report holds no usageItems list" "$SAD" "the usage report holds no usageItems list"
_sa_body users "{\"usageItems\":[{\"date\":\"@YM@-03T00:00:00Z\",\"product\":\"actions\",\"sku\":\"Actions Linux\",\"quantity\":\"1430\",\"unitType\":\"Minutes\",\"netAmount\":1.0}]}"
_sa_brun r13nan.tsv
is "R13: a counted item in minutes whose quantity is not a number leaves the budget row unread" "$(_sa_srcf "$T" budget 4)" unread
has "R13: and says an Actions item's quantity or netAmount is not a number" "$SAD" "the usage report holds an Actions item whose quantity or netAmount is not a number"
rm -f "$SAK"/bill.*
# The failed GETs: section 3's table, a row a case, and a failed GET whose stdout holds a report that would sum.
_sa_fail users 1 'gh: This endpoint has been moved. (HTTP 410)\n' '{"message":"This endpoint has been moved","status":"410"}'
_sa_brun r13gone.tsv
is "R13: a 410 on the users/ GET: unread" "$(_sa_srcf "$T" budget 4)" unread
is "R13: and no orgs/ GET follows a 410" "$(_sa_bills "$T.gh")" users
is "R13: and the detail says GitHub moved the endpoint and no scope brings it back" "$SAD" "gh: This endpoint has been moved. (HTTP 410); GitHub has moved this endpoint, so the fix is to Felix's reader and no token scope brings it back"
_sa_fail users 1 'gh: Not Found (HTTP 404)\n' '{"message":"Not Found","documentation_url":"https://docs.github.com/rest","status":"404"}'
_sa_fail orgs 1 'gh: Not Found (HTTP 404)\n' '{"message":"Not Found","documentation_url":"https://docs.github.com/rest","status":"404"}'
_sa_brun r13nf.tsv
is "R13: a 404 on users/ is followed by one orgs/ GET, and nothing else of billing" "$(_sa_bills "$T.gh")" users,orgs
is "R13: the orgs/ GET asks the same year and month, the clock's in UTC" "$(_sa_qn "$(_sa_q "$T.gh" orgs)")" "$SAC1"
is "R13: and it is a GET of orgs/<owner>/settings/billing/usage?year=Y&month=M" "$(_sa_apiw "$T.gh" "$SAO1?$(_sa_qn "$(_sa_q "$T.gh" users)")")" 1
is "R13: 404 on both: unread, and the detail says what a 404 means and names no scope" "$(_sa_srcf "$T" budget 4)|$SAD" "unread|gh: Not Found (HTTP 404); GitHub answers 404 for an account that does not exist and for one whose billing this login may not read"
_sa_fail users 1 'gh: Not Found (HTTP 404)\ngh: This API operation needs the "user" scope. To request it, run:  gh auth refresh -h github.com -s user\n'
_sa_brun r13scope.tsv
is "R13: a scope gh names on the users/ GET is given, and wins over the 404 clause" "$SAD" "gh: Not Found (HTTP 404); gh names a scope the token lacks (user), and widening the token is the founder's"
_sa_fail orgs 1 'gh: Not Found (HTTP 404)\ngh: This API operation needs the "admin:org" scope. To request it, run:  gh auth refresh -h github.com -s admin:org\n'
_sa_brun r13scopes.tsv
is "R13: two GETs naming different scopes give both, in the order asked" "$SAD" "gh: Not Found (HTTP 404); gh names a scope the token lacks (user, admin:org), and widening the token is the founder's"
_sa_fail users 1 'gh: Not Found (HTTP 404)\n'; _sa_fail orgs 1 'gh: HTTP 502: Bad Gateway\n'
_sa_brun r13bad.tsv
is "R13: a 404 then a 502 on orgs/: the organisation report's error follows, and no clause" "$(_sa_srcf "$T" budget 4)|$SAD" "unread|gh: Not Found (HTTP 404); organisation report: gh: HTTP 502: Bad Gateway"
rm -f "$SAK"/bill.orgs.*
_sa_body orgs "{\"usageItems\":[$(_sa_it @YM@-06 actions 'Actions Linux' 200.0 Minutes 1.11)]}"
_sa_brun r13org.tsv
is "R13: a 404 on users/ then an answered orgs/ report: read" "$(_sa_srcf "$T" budget 4)" read
is "R13: and the detail is the organisation report's, in the month asked" "$SAD" "200 Actions minutes used in $(_sa_ym "$(_sa_q "$T.gh" orgs)"), net \$1.11"
rm -f "$SAK"/bill.*
_sa_fail users 1 'error connecting to api.github.com\n' "{\"usageItems\":[$(_sa_it @YM@-03 actions 'Actions Linux' 1430.0 Minutes 2.5)]}"
_sa_brun r13net.tsv
is "R13: a failed GET whose stdout holds a report that would sum stays unread" "$(_sa_srcf "$T" budget 4)" unread
is "R13: a network error: one billing GET, and the detail is gh's first error line alone" "$(_sa_bills "$T.gh")|$SAD" "users|error connecting to api.github.com"
rm -f "$SAK"/bill.*
# ---- R13, amended after review (A1-A6 and the three named gaps), blind 2026-11-12
# A1: date first on PATH stands the clock at 2026-03-15T12:00:00Z. A date written 2026-3- is an actions item dated outside 2026-03.
printf '1773576000\n' > "$SAK/date.at"
is "the amendments fixture: the date stub answers the fixed instant when told to, for the caller's own format (fixture control)" "$(PATH="$SAB:$PATH" date -u +%Y-%m-%dT%H)" 2026-03-15T12
_sa_body users "{\"usageItems\":[$(_sa_it 2026-03-04 actions 'Actions Linux' 100.0 Minutes 0.40),$(_sa_it 2026-3-05 actions 'Actions Linux' 50.0 Minutes 0.20)]}"
_sa_brun r13march.tsv
rm -f "$SAK/date.at"
is "the amendments fixture: with its control removed the date stub answers the real clock (fixture control)" "$(PATH="$SAB:$PATH" date -u +%Y-%m)" "$(date -u +%Y-%m)"
is "R13: A1: a clock in March asks the users/ report for month=3, no leading zero" "$(_sa_q "$T.gh" users)" "year=2026&month=3"
is "R13: A1: and counts only dates starting 2026-03-, zero-padded" "$(_sa_srcf "$T" budget 4)|$SAD" "read|100 Actions minutes used in 2026-03, net \$0.40; Actions items dated outside 2026-03, not counted: 1"
SAUN="unread|"
# A2: an answer that ends early, its second item (which would add a lot) left open; and text after the object closes.
_sa_body users "{\"usageItems\":[$(_sa_it @YM@-03 actions 'Actions Linux' 10.0 Minutes 0.10),{\"date\":\"@YM@-04T00:00:00Z\",\"product\":\"actions\",\"unitType\":\"Minutes\",\"quantity\":99999.0,\"netAmount\":999.0"
_sa_brun r13short.tsv
is "R13: A2: an answer that ends early is unread: the usage report is not complete JSON" "$(_sa_srcf "$T" budget 4)|$SAD" "${SAUN}the usage report is not complete JSON"
_sa_body users "{\"usageItems\":[$(_sa_it @YM@-03 actions 'Actions Linux' 10.0 Minutes 0.10)]} {\"usageItems\":[]}"
_sa_brun r13tail.tsv
is "R13: A2: text after the object closes is unread: the usage report is not complete JSON" "$(_sa_srcf "$T" budget 4)|$SAD" "${SAUN}the usage report is not complete JSON"
# A3: usageItems that is not a list.
_sa_body users '{"usageItems":null}'
_sa_brun r13null.tsv
is "R13: A3: usageItems null is unread: no usageItems list" "$(_sa_srcf "$T" budget 4)|$SAD" "${SAUN}the usage report holds no usageItems list"
_sa_body users "{\"usageItems\":{\"a\":$(_sa_it @YM@-03 actions 'Actions Linux' 10.0 Minutes 0.10)}}"
_sa_brun r13obj.tsv
is "R13: A3: usageItems an object is unread: no usageItems list" "$(_sa_srcf "$T" budget 4)|$SAD" "${SAUN}the usage report holds no usageItems list"
# A4: an actions item with no date, and one whose date is a number, beside one that would count.
_sa_body users "{\"usageItems\":[$(_sa_it @YM@-03 actions 'Actions Linux' 10.0 Minutes 0.10),{\"product\":\"actions\",\"sku\":\"Actions Linux\",\"quantity\":5.0,\"unitType\":\"Minutes\",\"netAmount\":0.05}]}"
_sa_brun r13nodate.tsv
is "R13: A4: an actions item with no date is unread: an Actions item with no date" "$(_sa_srcf "$T" budget 4)|$SAD" "${SAUN}the usage report holds an Actions item with no date"
_sa_body users "{\"usageItems\":[$(_sa_it @YM@-03 actions 'Actions Linux' 10.0 Minutes 0.10),{\"date\":20261103,\"product\":\"actions\",\"sku\":\"Actions Linux\",\"quantity\":5.0,\"unitType\":\"Minutes\",\"netAmount\":0.05}]}"
_sa_brun r13numdate.tsv
is "R13: A4: an actions item whose date is a number is unread: an Actions item with no date" "$(_sa_srcf "$T" budget 4)|$SAD" "${SAUN}the usage report holds an Actions item with no date"
rm -f "$SAK"/bill.*
# A5: a first error line of 161 characters whose code sits past character 120. How the cut line is shown is section 4.4's,
# not restated in the amendment, so the detail is held to start with the line's first 120 characters and end with the clause.
SALONG="gh: GitHub answered the request for this account's usage report with an error, and this line runs on past the cut of one hundred and twenty characters"
_sa_fail users 1 "$SALONG (HTTP 404)\n"; _sa_fail orgs 1 "$SALONG (HTTP 404)\n"
_sa_brun r13long404.tsv
is "R13: A5: a 404 past character 120 of the first error line still brings the orgs/ GET" "$(_sa_bills "$T.gh")" users,orgs
has "R13: A5: and the detail shows the line from its start" "$SAD" "${SALONG:0:120}"
is "R13: A5: and, both failing so, ends with the 404 clause" "$(_sa_srcf "$T" budget 4)|${SAD##*; }" "unread|GitHub answers 404 for an account that does not exist and for one whose billing this login may not read"
rm -f "$SAK"/bill.*
_sa_fail users 1 "$SALONG (HTTP 410)\n"
_sa_brun r13long410.tsv
is "R13: A5: a 410 past character 120 brings no orgs/ GET and ends with the moved clause" "$(_sa_bills "$T.gh")|${SAD##*; }" "users|GitHub has moved this endpoint, so the fix is to Felix's reader and no token scope brings it back"
rm -f "$SAK"/bill.*
# The three named gaps: a scope line whose name is no scope name; a 404 then a 410; a netAmount that is not a number.
_sa_fail users 1 'gh: Not Found (HTTP 404)\ngh: This API operation needs the "read user" scope. To request it, run:  gh auth refresh -h github.com -s read user\n'
_sa_fail orgs 1 'gh: Not Found (HTTP 404)\ngh: This API operation needs the "user;x" scope. To request it, run:  gh auth refresh -h github.com -s user;x\n'
_sa_brun r13badscope.tsv
is "R13: a scope line naming no scope name (a space, a semicolon) names no scope: the 404 clause is given" "$SAD" "gh: Not Found (HTTP 404); GitHub answers 404 for an account that does not exist and for one whose billing this login may not read"
_sa_fail users 1 'gh: Not Found (HTTP 404)\n'; _sa_fail orgs 1 'gh: This endpoint has been moved. (HTTP 410)\n'
_sa_brun r13nf410.tsv
is "R13: a 404 then a 410 on orgs/: both lines, then the moved clause" "$SAD" "gh: Not Found (HTTP 404); organisation report: gh: This endpoint has been moved. (HTTP 410); GitHub has moved this endpoint, so the fix is to Felix's reader and no token scope brings it back"
rm -f "$SAK"/bill.*
SANAN="the usage report holds an Actions item whose quantity or netAmount is not a number"
_sa_body users "{\"usageItems\":[$(_sa_it @YM@-03 actions 'Actions Linux' 10.0 Minutes '"2.5"')]}"
_sa_brun r13netstr.tsv
is "R13: a counted item whose netAmount is a string is unread, quantity or netAmount not a number" "$(_sa_srcf "$T" budget 4)|$SAD" "$SAUN$SANAN"
_sa_body users "{\"usageItems\":[$(_sa_it @YM@-03 actions 'Actions storage' 1.0 GigabyteHours null)]}"
_sa_brun r13netnull.tsv
is "R13: a counted storage item whose netAmount is null is unread, quantity or netAmount not a number" "$(_sa_srcf "$T" budget 4)|$SAD" "$SAUN$SANAN"
_sa_body users "{\"usageItems\":[{\"date\":\"@YM@-03T00:00:00Z\",\"product\":\"actions\",\"sku\":\"Actions Linux\",\"quantity\":10.0,\"unitType\":\"Minutes\"}]}"
_sa_brun r13netnone.tsv
is "R13: a counted item with no netAmount is unread, quantity or netAmount not a number" "$(_sa_srcf "$T" budget 4)|$SAD" "$SAUN$SANAN"
rm -f "$SAK"/bill.*
# A6: an owner holding & is no account name. The repository's origin names github.com/fix&ture/home.
SAAMP="$SA/amprepo"; mkdir -p "$SAAMP"; _fx_git "$SAAMP" init -q >/dev/null 2>&1
_fx_git "$SAAMP" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
printf 'amp\n' > "$SAAMP/README.md"; _sa_commit "$SAAMP" base
_fx_git "$SAAMP" remote add origin "$SA/github.com/fix&ture/home.git" >/dev/null 2>&1
_fx_git "$SAAMP" update-ref refs/remotes/origin/main HEAD >/dev/null 2>&1
_fx_git "$SAAMP" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main >/dev/null 2>&1
_sa_prs fix_ture_home "$(_sa_pr 811 main)"
_sa_brun r13amp.tsv --repo "$SAAMP"
is "the amendments fixture: the page reads the owner fix&ture into its slug: a row names fix&ture/home (fixture control)" "$([ "$(LC_ALL=C grep -c -F 'fix&ture/home' "$T")" -gt 0 ] && echo yes)" yes
is "R13: A6: an owner that is not an account name: no billing GET" "$(_sa_bills "$T.gh")" ""
is "R13: A6: and the row is unread: the owner in the slug is not an account name" "$(_sa_srcf "$T" budget 4)|$SAD" "${SAUN}the owner in the slug is not an account name"
is "R13: the page exits 0 whatever the budget's reading, in every case above" "$(printf '%s' "$SARCS" | LC_ALL=C tr -d 0)" ""
_sa_lacks "R13: no budget detail above holds the word included" "$SAALL" included
_sa_lacks "R13: no budget detail above says the token may lack the user scope" "$SAALL" "the token may lack the user scope"

# ---- R1, R6: the queue over a project with no checkout and a repository named twice
_sa_land --queue --tsv; _sa_keep q.tsv
_sa_land --queue; _sa_keep q.txt
Q="$SAX/q.tsv"
is "R1: --queue exits 0, with --tsv and without" "$(cat "$Q.rc")$(cat "$SAX/q.txt.rc")" 00
is "R1: two has no checkout: the gh log holds exactly one GET of repos/fixture/two" "$(_sa_apiw "$Q.gh" repos/fixture/two)" 1
is "R1: and the home's project, whose checkout is the home, asks gh for no default branch" "$(_sa_apiw "$Q.gh" repos/fixture/home)" 0
is "R1: and zeta, read under felix, asks for none either" "$(_sa_apis "$Q.gh" "epos/Fixture/Home")" 0
is "R1, §2: gh is asked nothing but pr list, a GET of repos/<owner>/<name> and the billing GETs" \
   "$(LC_ALL=C awk '!(index($0, "pr list") == 1 || ($1 == "api" && (index($0, "repos/") || index($0, "settings/billing/usage"))))' "$Q.gh" | head -3)" ""
is "R1: two's default branch is trunk, from gh: #701 into trunk, founder, is listed once" "$(_sa_nrow "$Q" 701)" 1
is "R1: under fixture/two (control)" "$(_sa_f "$Q" 701 2)" fixture/two
is "R1: and #702 into main, founder by label, is stacked, so not in --queue" "$(_sa_nrow "$Q" 702)" 0
is "R5: every line of --queue --tsv has eight columns (control)" "$(_sa_cols "$Q")" ""
is "R6: felix and zeta name one repository: founder #601 is listed exactly once" "$(_sa_nrow "$Q" 601)" 1
is "R6: and founder #602 exactly once" "$(_sa_nrow "$Q" 602)" 1
is "R6: and the plain #603 not at all (control)" "$(_sa_nrow "$Q" 603)" 0
is "R6: gh listed fixture/home once, not once per project: one pr list besides two's and three's" \
   "$(LC_ALL=C awk 'index($0, "pr list") == 1 && tolower($0) !~ /fixture\/(two|three)/' "$Q.gh" | LC_ALL=C awk 'END { print NR }')" 1
is "R6: the text lists #601 on one line" "$(LC_ALL=C awk 'index($0, "#601 ") == 1 { n++ } END { print n + 0 }' "$SAX/q.txt")" 1
is "R6: and #602 on one line" "$(LC_ALL=C awk 'index($0, "#602 ") == 1 { n++ } END { print n + 0 }' "$SAX/q.txt")" 1
_saz="$(LC_ALL=C awk 'index($0, "zeta")' "$SAX/q.txt" | LC_ALL=C awk -v p="$SA" '{ while ((i = index($0, p))) $0 = substr($0, 1, i - 1) substr($0, i + length(p)); print }')"
is "R6: zeta, second in name order, has a block of its own (control)" "$([ -n "$_saz" ] && echo yes)" yes
has "R6: and zeta's block names felix, whose block lists its pull requests" "$_saz" felix
_saf="$(LC_ALL=C awk 'index($0, "felix") == 1' "$SAX/q.txt")"
_sa_lacks "R6: and felix's block does not send the reader to zeta" "$_saf" zeta

# ---- R5: a tab in the repo cell --------------------------------------------------
_sa_proj maple "github.com/fixture/ta${SATAB}by"
_sa_commit "$SAH" maple; _fx_git "$SAH" push -q origin main >/dev/null 2>&1; _fx_git "$SAH" fetch -q origin >/dev/null 2>&1
is "the amendments fixture: maple's remote_match holds a tab (fixture control)" \
   "$(LC_ALL=C grep -c "fixture/ta${SATAB}by" "$SAH/projects/maple/project.json")" 1
_sa_land --queue --tsv; _sa_keep r5q.tsv
T="$SAX/r5q.tsv"
is "R5: --queue with a remote_match holding a tab exits 0" "$(cat "$T.rc")" 0
# A remote_match holding a tab is no owner/name slug: R5, clarified, makes its
# gh source row unread with that reason, and lists no pull request of it. First
# written as either-or (read, #801 one row of eight columns); restated
# 2026-10-18 at the carry to the clarified contract alone, because the two
# branches gave a tree without the page assertion names this tree never
# reaches, and the record's red run may name only what the manifest lists.
_sat="$(LC_ALL=C awk -F'\t' '$1 == "source" && $3 == "gh" && index($2, "ta by") { print $4; exit }' "$T")"
is "R5: maple has a gh source row whose repo cell holds a space where the tab was" "$([ -n "$_sat" ] && echo yes)" yes
is "R5: maple's gh source row is unread, as R5 clarified says" "$_sat" unread
is "R5: maple not read: no pr row of its repository" "$(LC_ALL=C awk -F'\t' '$1 == "pr" && index($2, "ta")' "$T" | LC_ALL=C grep -c 'ta by')" 0
is "R5: and its gh source row says why" "$(LC_ALL=C awk -F'\t' '$1 == "source" && $3 == "gh" && index($2, "ta by") { print ($8 != "" && $8 != "-") ? "why" : "silent"; exit }' "$T")" why
is "R5: every line of that --queue --tsv has eight columns" "$(_sa_cols "$T")" ""
is "R5: and the other projects still list theirs: #601 once (control)" "$(_sa_nrow "$T" 601)" 1
mkdir -p "$SA/tabrepo"; _fx_git "$SA/tabrepo" init -q >/dev/null 2>&1
_fx_git "$SA/tabrepo" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
printf 'tab\n' > "$SA/tabrepo/README.md"; _sa_commit "$SA/tabrepo" base
_fx_git "$SA/tabrepo" remote add origin "$SA/github.com/fixture/ta${SATAB}by.git" >/dev/null 2>&1
_fx_git "$SA/tabrepo" update-ref refs/remotes/origin/main HEAD >/dev/null 2>&1
_fx_git "$SA/tabrepo" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main >/dev/null 2>&1
is "the amendments fixture: tabrepo's origin URL holds a tab, and origin/HEAD names main (fixture control)" \
   "$(git -C "$SA/tabrepo" config --get remote.origin.url 2>/dev/null | LC_ALL=C grep -c "ta${SATAB}by")|$(git -C "$SA/tabrepo" symbolic-ref -q refs/remotes/origin/HEAD 2>&1)" "1|refs/remotes/origin/main"
_sa_land --prs --tsv --repo "$SA/tabrepo"; _sa_keep r5p.tsv
T="$SAX/r5p.tsv"
is "R5: --prs in a repository whose slug holds a tab exits 0" "$(cat "$T.rc")" 0
is "R5: its #801 is one pr row" "$(_sa_nrow "$T" 801)" 1
is "R5: of exactly eight columns" "$(_sa_row "$T" 801 | LC_ALL=C awk -F'\t' '{ print NF }')" 8
_sac="$(_sa_f "$T" 801 2)"
is "R5: its repo cell is not empty and holds no carriage return" "$([ -n "$_sac" ] && echo set)$(printf '%s' "$_sac" | LC_ALL=C tr -d -c '\r' | LC_ALL=C awk '{ printf "%s", length($0) ? "cr" : "" }')" set
is "R5: every line of that page, source rows too, has eight columns" "$(_sa_cols "$T")" ""

# ---- R4: how old main is ----------------------------------------------------------
# origin/main last moved nine days ago by its reflog; then a fetch of another
# branch only, so FETCH_HEAD is fresh and origin/main's reflog is not.
SARL="$SAH/.git/logs/refs/remotes/origin/main"; SAOLD=$(( $(date +%s) - 777600 ))
if [ -f "$SARL" ]; then
  LC_ALL=C awk -v t="$SAOLD" 'BEGIN { FS = OFS = "\t" } { n = split($1, w, " "); w[n - 1] = t; s = w[1]; for (i = 2; i <= n; i++) s = s " " w[i]; $1 = s; print }' "$SARL" > "$SARL.new" && mv "$SARL.new" "$SARL"
fi
# The reflog's file and the loose ref carry the same old time, as they would
# had main last moved then.
SAOLDT="$(date -r "$SAOLD" +%Y%m%d%H%M.%S 2>/dev/null || date -d "@$SAOLD" +%Y%m%d%H%M.%S)"
touch -t "$SAOLDT" "$SARL" "$SAH/.git/refs/remotes/origin/main" 2>/dev/null
touch -t 202601010000 "$SAH/.git/FETCH_HEAD" 2>/dev/null
_fx_git "$SAH" push -q origin main:refs/heads/other >/dev/null 2>&1
_fx_git "$SAH" fetch -q origin other >/dev/null 2>&1
is "the amendments fixture: origin/main's reflog last moved nine days ago (fixture control)" \
   "$(LC_ALL=C awk -F'\t' 'END { n = split($1, w, " "); print w[n - 1] }' "$SARL" 2>&1)" "$SAOLD"
is "the amendments fixture: FETCH_HEAD is fresh and names other, not main (fixture control)" \
   "$(find "$SAH/.git/FETCH_HEAD" -mmin -10 2>/dev/null | LC_ALL=C awk 'END { print NR }')|$(LC_ALL=C grep -c "'other'" "$SAH/.git/FETCH_HEAD" 2>/dev/null)|$(LC_ALL=C grep -c "'main'" "$SAH/.git/FETCH_HEAD" 2>/dev/null)" "1|1|0"
_sa_land --prs --tsv; _sa_keep r4old.tsv
D="$(_sa_srcf "$SAX/r4old.tsv" origin 8)"; P="$(_sa_moved "$D")"
is "R4: the page after a fetch of another branch exits 0" "$(cat "$SAX/r4old.tsv.rc")" 0
has "R4: the origin row says when origin/main last moved, from its reflog" "$D" "origin/main last moved "
_sa_ge "R4: and that is nine days ago, not the fresh fetch of another branch" "$(_sa_hours "$P")" 48 "$D"
case "$D" in
  *fetch*) has "R4: an age of FETCH_HEAD, if given, is labelled the last fetch of any ref" "$D" "any ref" ;;
  *) ok "R4: an age of FETCH_HEAD, if given, is labelled the last fetch of any ref" ;;
esac
has "R4: the row still names the default branch (control)" "$D" "default branch main"
printf 'moved\n' > "$SAH/notes/moved.md"; _sa_commit "$SAH" moved
_fx_git "$SAH" push -q origin main >/dev/null 2>&1; _fx_git "$SAH" fetch -q origin >/dev/null 2>&1
_sa_land --prs --tsv; _sa_keep r4new.tsv
D="$(_sa_srcf "$SAX/r4new.tsv" origin 8)"; P="$(_sa_moved "$D")"
has "R4: main moved just now: the origin row says when origin/main last moved (control)" "$D" "origin/main last moved "
_sa_lt "R4: and that is under an hour ago (control)" "$(_sa_hours "$P")" 1 "$D"

# ---- the fixture is removed ---------------------------------------------------------
chmod -R u+rwx "$SA" 2>/dev/null; rm -rf "$SA"
[ -e "$SA" ] && bad "the amendments fixture is removed when its part ends" "$SA is still there" || ok "the amendments fixture is removed when its part ends"
# <<< stuck-pr-page-amendments
