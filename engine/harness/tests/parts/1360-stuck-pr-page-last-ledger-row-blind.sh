# >>> stuck-pr-page-last-ledger-row
printf '\nthe stuck-PR page: the lander source row ends with the newest ledger row, and --status names the same row (spec v2 R11, blind)\n'
# Blind, written on 2026-10-18 from spec v2 amendment R11 and section 4.3, 5, 6
# and R8 (audits/2026-10-01-report-v5-review/specs/stuck-pr/spec-v2.md) and from
# A31's wording of the --status last line (docs/2026-10-15-land-on-green-
# contract.md), without reading lib/pr-status*.sh, lib/green-tick.sh or
# lib/green-install.sh. Parts 1300 to 1350 were read only for how their
# fixtures and stubs are built. Self-contained after the preamble: it builds
# its own fixture under $TMP and removes it.
#
# What R11 fixes, and what these assertions pin:
#   the lander source row's detail ends "; last ledger row <time> <event>:
#   <detail>", from the ledger's newest (last) line whatever its PR column;
#   time is column 1, event column 2, detail column 7; a carriage return in the
#   detail is a space; a missing column is empty. With the ledger row "none" it
#   ends "; last ledger row none"; with it "unread", "; last ledger row not
#   read". It comes after installed, loaded, paused and any paused reason. The
#   row's state (live or not-live) and every pull request's state are unchanged.
#   R8's filter covers the detail. --status keeps its last line and names the
#   same row.
# What R11 leaves open, and these assertions leave open too: the separator
# between installed, loaded, paused and the reason; how the text page lays the
# lander row out (a text assertion only asks that the page holds the clause);
# whether a clause with an empty detail keeps a trailing space after the colon
# (those assertions trim trailing spaces); what an event or time holding a
# control byte shows (only the detail is pinned); and a row with more than seven
# columns.
#
# The fixture: two bare origins whose paths end github.com/fixture/home.git and
# two.git, so the slugs are fixture/home and fixture/two, and a clone of the first
# that is also the Felix home, holding projects/felix (remote_match
# github.com/fixture/home) and projects/two (remote_match github.com/fixture/two).
# two is a clone with a pushed main. gh and launchctl are stubs first on PATH,
# each logging its argv. gh answers pr list from ctl/prs.<owner>_<name>.json, the
# repository taken from -R or --repo, else from the origin of the directory it
# runs in, and answers the Actions billing GET and a GET of repos/fixture/<x>
# with the default branch, main. launchctl print always fails (the job is not
# loaded). Memory is a fixture directory, so each project's land/ directory is
# $SNM/<p>/land. HOME is a fixture directory on every run.
SN="$TMP/stuck-pr-lastrow"; mkdir -p "$SN"; SN="$(cd "$SN" && pwd -P)"
SNO="$SN/github.com/fixture/home.git"; SNH="$SN/home"
SN2O="$SN/github.com/fixture/two.git"; SN2="$SN/two"
SNM="$SN/mem"; SNU="$SN/user"; SNB="$SN/bin"; SNK="$SN/ctl"; SNL="$SN/log"; SNX="$SN/out"; SNT="$SN/tmp"
SNLAND="$(FELIX_MEMORY="$SNM" felix_mem_dir felix)/land"; SN2LAND="$(FELIX_MEMORY="$SNM" felix_mem_dir two)/land"
mkdir -p "$SNO" "$SN2O" "$SNM" "$SNU/.config/gh" "$SNB" "$SNK" "$SNL" "$SNX" "$SNT" "$SN/cache"
_sn_put() { mkdir -p "$(dirname "$1")" && LC_ALL=C sed "s#@SN@#$SN#g" > "$1" && chmod +x "$1"; }
_sn_put "$SNB/gh" <<'SNSTUB'
#!/bin/bash
SN='@SN@'; K="$SN/ctl"
printf '%s\n' "$*" >> "$SN/log/gh.log"
jqx=""; repo=""; prev=""; bill=0; dflt=""
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; -R|--repo) repo="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; --repo=*) repo="${a#--repo=}" ;; esac
  case "$a" in
    *settings/billing/usage*) bill=1; bq="$a" ;;
    repos/fixture/home|/repos/fixture/home|repos/fixture/two|/repos/fixture/two) dflt="${a#/}" ;;
  esac
  prev="$a"
done
if [ -z "$repo" ]; then
  u="$(git config --get remote.origin.url 2>/dev/null)"; u="${u%/}"; u="${u%.git}"
  n="${u##*/}"; o="${u%/*}"; o="${o##*/}"; [ -n "$n" ] && [ -n "$o" ] && repo="$o/$n"
fi
repo="${repo#https://}"; repo="${repo#github.com/}"; repo="${repo%.git}"
key="$(printf '%s' "$repo" | LC_ALL=C tr '/' '_')"
out() { if [ -n "$jqx" ] && command -v jq >/dev/null 2>&1; then jq -r "$jqx"; else cat; fi; }
case "${1:-} ${2:-}" in
  "pr list")
    [ -f "$K/prs.$key.json" ] || { printf 'stub: no answer for repository [%s]\n' "$repo" >&2; exit 4; }
    out < "$K/prs.$key.json"; exit 0 ;;
esac
if [ "${1:-}" = api ]; then
  if [ "$bill" = 1 ]; then by="${bq##*year=}"; by="${by%%&*}"; bm="${bq##*month=}"; bm="${bm%%&*}"; [ "${#bm}" -eq 1 ] && bm="0$bm"; printf '{"usageItems":[{"date":"%s-%s-01T00:00:00Z","product":"actions","sku":"Actions Linux","quantity":5.0,"unitType":"Minutes","pricePerUnit":0.006,"grossAmount":0.0,"discountAmount":0.0,"netAmount":0.0,"repositoryName":"home"}]}\n' "$by" "$bm" | out; exit 0; fi
  if [ -n "$dflt" ]; then printf '{"full_name":"%s","default_branch":"main"}\n' "${dflt#repos/}" | out; exit 0; fi
  printf 'gh: Not Found (HTTP 404)\n' >&2; exit 1
fi
printf 'stub: gh %s is not served\n' "$*" >&2
exit 1
SNSTUB
_sn_put "$SNB/launchctl" <<'SNSTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@SN@/log/launchctl.log'
case "${1:-}" in print) exit 113 ;; esac
exit 0
SNSTUB

# ---- the repositories ------------------------------------------------------------
_sn_commit() { _fx_git "$1" add -A >/dev/null 2>&1; _fx_git "$1" -c user.name=t -c user.email=t@t commit -qm "$2" >/dev/null 2>&1; }
for _sno in "$SNO" "$SN2O"; do
  _fx_git "$_sno" init -q --bare >/dev/null 2>&1
  _fx_git "$_sno" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
done
_fx_git "$SN" clone -q "$SNO" home >/dev/null 2>&1
_fx_git "$SNH" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
mkdir -p "$SNH/projects/felix" "$SNH/projects/two" "$SNH/notes"
printf '{\n  "name": "felix",\n  "remote_match": "github.com/fixture/home",\n  "gate": "true"\n}\n' > "$SNH/projects/felix/project.json"
printf '{\n  "name": "two",\n  "remote_match": "github.com/fixture/two",\n  "gate": "true"\n}\n' > "$SNH/projects/two/project.json"
printf '# felix\n' > "$SNH/projects/felix/CLAUDE.md"; printf '# two\n' > "$SNH/projects/two/CLAUDE.md"
printf 'home\n' > "$SNH/README.md"; printf 'keep\n' > "$SNH/notes/keep.md"
_sn_commit "$SNH" base
_fx_git "$SNH" push -q -u origin main >/dev/null 2>&1
_fx_git "$SNH" fetch -q origin >/dev/null 2>&1
_fx_git "$SNH" remote set-head origin main >/dev/null 2>&1
SNMAIN="$(git -C "$SNH" rev-parse refs/remotes/origin/main 2>/dev/null)"
_fx_git "$SN" clone -q "$SN2O" two >/dev/null 2>&1
_fx_git "$SN2" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
printf 'two\n' > "$SN2/README.md"; _sn_commit "$SN2" base
_fx_git "$SN2" push -q -u origin main >/dev/null 2>&1
_fx_git "$SN2" fetch -q origin >/dev/null 2>&1
_fx_git "$SN2" remote set-head origin main >/dev/null 2>&1

# ---- pull requests as gh lists them ----------------------------------------------
# Green, MERGEABLE, not a draft, its own head branch, one path under notes/: with
# no ledger row of its own each is ready and needs the lander.
_sn_sha() { printf '%04d%s' "$1" c0ffeec0ffeec0ffeec0ffeec0ffeec0ffee; }
SN_UPD="$(date -u -r "$(( $(date +%s) - 7200 ))" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$(( $(date +%s) - 7200 ))" +%Y-%m-%dT%H:%M:%SZ)"
SN_GREEN='[{"__typename":"CheckRun","name":"gate","workflowName":"gate","status":"COMPLETED","conclusion":"SUCCESS"}]'
_sn_pr() {   # N: a green pull request changing notes/N.md
  printf '{"number":%s,"title":"Change %s","headRefName":"b%s","headRefOid":"%s","baseRefName":"main","isDraft":false,"isCrossRepository":false,' "$1" "$1" "$1" "$(_sn_sha "$1")"
  printf '"author":{"login":"fixture"},"labels":[],"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","statusCheckRollup":%s,' "$SN_GREEN"
  printf '"files":[{"path":"notes/%s.md","additions":1,"deletions":0}],"updatedAt":"%s"}' "$1" "$SN_UPD"
}
_sn_prs() {   # KEY N... -> ctl/prs.KEY.json
  local k="$1" s="" n; shift
  { printf '['; for n in "$@"; do printf '%s%s' "$s" "$(_sn_pr "$n")"; s=","; done; printf ']\n'; } > "$SNK/prs.$k.json"
}
_sn_prs fixture_home 401 402
_sn_prs fixture_two 501

# ---- the ledgers -------------------------------------------------------------------
SNTAB="$(printf '\t')"
SN_T1=2026-10-18T08:00:00Z; SN_T2=2026-10-18T08:10:00Z; SN_T3=2026-10-18T08:20:00Z; SN_T4=2026-10-18T08:30:00Z
_sn_row() { printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$@"; }   # TIME EVENT PR HEAD WORKTREE SECONDS DETAIL
_sn_ledger() { rm -rf "$SNLAND/ledger.tsv"; mkdir -p "$SNLAND"; cat > "$SNLAND/ledger.tsv"; }   # rows on stdin
_sn_clause() { printf '; last ledger row %s %s: %s' "$1" "$2" "$3"; }   # TIME EVENT DETAIL

# ---- running the page and reading it -------------------------------------------------
_sn_land() {   # DIR ARGS... ; stdout to out/out, status in SNRC
  local d="$1"; shift
  ( cd "$d" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u CLAUDE_CODE_SESSION_ID \
      HOME="$SNU" FELIX_HOME="$SNH" FELIX_HOME_DIR="$SNH" FELIX_MEMORY="$SNM" FELIX_PLUGIN_CACHE="$SN/cache" \
      GH_CONFIG_DIR="$SNU/.config/gh" TMPDIR="$SNT" PATH="$SNB:$PATH" "$FELIX" land "$@" ) > "$SNX/out" 2> "$SNX/err"
  SNRC=$?
}
_sn_keep() { cp "$SNX/out" "$SNX/$1"; printf '%s\n' "$SNRC" > "$SNX/$1.rc"; }
_sn_pages() {   # NAME [DIR [EXTRA ARGS...]]: the --tsv page as NAME.tsv and the text page as NAME.txt
  local n="$1" d="$SNH"
  shift
  if [ $# -gt 0 ]; then d="$1"; shift; fi
  _sn_land "$d" --prs --tsv "$@"; _sn_keep "$n.tsv"
  _sn_land "$d" --prs "$@"; _sn_keep "$n.txt"
}
_sn_status() {   # NAME: --status as NAME.st and --status --tsv as NAME.stt
  _sn_land "$SNH" --status; _sn_keep "$1.st"
  _sn_land "$SNH" --status --tsv; _sn_keep "$1.stt"
}
_sn_row_of() { LC_ALL=C awk -F'\t' -v r="#$2" '$1 == "pr" && $3 == r' "$1" 2>/dev/null; }
_sn_f()     { _sn_row_of "$1" "$2" | LC_ALL=C awk -F'\t' -v k="$3" 'NR == 1 { printf "%s", $k }'; }
_sn_state() { _sn_f "$1" "$2" 4 | LC_ALL=C sed 's/,.*//'; }
_sn_srcf()  { LC_ALL=C awk -F'\t' -v r="$2" -v k="$3" '$1 == "source" && $3 == r { printf "%s", $k; exit }' "$1" 2>/dev/null; }
_sn_nsrc()  { LC_ALL=C awk -F'\t' -v r="$2" '$1 == "source" && $3 == r { n++ } END { print n + 0 }' "$1" 2>/dev/null; }
_sn_cols()  { LC_ALL=C awk -F'\t' 'NF != 8 { print NR ": " NF " columns" }' "$1" | head -3; [ -s "$1" ] || echo empty; }
_sn_lacks() { case "$2" in *"$3"*) bad "$1" "[$2] holds [$3]" ;; *) ok "$1" ;; esac; }
_sn_ends()  { case "$2" in *"$3") ok "$1" ;; *) bad "$1" "[$2] does not end with [$3]" ;; esac; }
# As _sn_ends, after trailing spaces: R11 leaves open whether an empty detail keeps a space after its colon.
_sn_endt()  { local t="$2"; while [ "${t% }" != "$t" ]; do t="${t% }"; done; _sn_ends "$1" "$t" "$3"; }
_sn_is() {   # LABEL FILE N STATE NEEDS
  is "$1: #$3 is in state $4" "$(_sn_state "$2" "$3")" "$4"
  [ -z "$5" ] || is "$1: #$3 needs $5" "$(_sn_f "$2" "$3" 5)" "$5"
}
# How many times S stands in TEXT.
_sn_occ() { printf '%s' "$1" | LC_ALL=C awk -v s="$2" 'BEGIN { RS = "\001" } { t = $0; while ((i = index(t, s)) > 0) { n++; t = substr(t, i + length(s)) } } END { print n + 0 }'; }
# A stands in TEXT before B does.
_sn_before() { printf '%s' "$1" | LC_ALL=C awk -v a="$2" -v b="$3" '{ i = index($0, a); j = index($0, b); if (i > 0 && j > 0 && i < j) print "before"; else print "not before (" i ", " j ")" }'; }
# The bytes R8 keeps from a terminal, counted in a file: below space but tab and
# newline, DEL, and 0x80 to 0x9f after 0xc2.
_sn_ctl() { LC_ALL=C od -An -v -tu1 "$1" | LC_ALL=C awk '{ for (i = 1; i <= NF; i++) { b = $i + 0
  if ((b < 32 && b != 9 && b != 10) || b == 127 || (p == 194 && b >= 128 && b <= 159)) n++; p = b } } END { print n + 0 }'; }
# The status page's last line, plain and as --tsv.
_sn_st_txt() { LC_ALL=C awk '{ k = $1; gsub(/[^a-z]/, "", k) } k == "last"' "$1"; }
_sn_st_tsv() { LC_ALL=C awk -F'\t' '$1 == "last"' "$1"; }
# The page's clause and --status's row, one fact read two ways: the page's
# "<time> <event>: <detail>" against columns 2, 3 and 8 of the status row.
_sn_agree() {   # LABEL PAGE.tsv STATUS.stt
  local c s
  c="$(_sn_srcf "$2" lander 8 | LC_ALL=C sed -n 's/.*; last ledger row //p')"
  s="$(_sn_st_tsv "$3" | LC_ALL=C awk -F'\t' '{ printf "%s %s: %s", $2, $3, $8 }')"
  is "$1" "$c" "$s"
}
# The standard set for one clause on one page pair NAME (NAME.tsv, NAME.txt).
_sn_expect() {   # LABEL NAME CLAUSE
  local t="$SNX/$2.tsv" x="$SNX/$2.txt"
  is "$1: both pages exit 0" "$(cat "$t.rc")$(cat "$x.rc")" 00
  is "$1: every row of the --tsv page has exactly eight columns" "$(_sn_cols "$t")" ""
  is "$1: the page has one lander source row" "$(_sn_nsrc "$t" lander)" 1
  _sn_ends "$1: the lander row's detail ends with the clause" "$(_sn_srcf "$t" lander 8)" "$3"
  has "$1: and the text page holds it" "$(cat "$x")" "$3"
  # R11 does not fix the text row's layout, only that the page holds the lander row's detail: one line
  # that names the lander and holds the clause (a pull request's line holds the word, never the clause).
  is "$1: on one line that names the lander" "$(LC_ALL=C awk -v c="$3" '/lander/ && index($0, c) { n++ } END { print n + 0 }' "$x")" 1
  is "$1: the detail names the ledger's newest row once" "$(_sn_occ "$(_sn_srcf "$t" lander 8)" "last ledger row")" 1
}

# ---- fixture controls ---------------------------------------------------------------
is "the last-row fixture: gh lists #401 and #402 for home and #501 for two (fixture control)" \
   "$(LC_ALL=C grep -o '"number":[0-9]*' "$SNK/prs.fixture_home.json" | LC_ALL=C tr '\n' ' ')|$(LC_ALL=C grep -o '"number":[0-9]*' "$SNK/prs.fixture_two.json" | LC_ALL=C tr '\n' ' ')" \
   '"number":401 "number":402 |"number":501 '
is "the last-row fixture: home's origin/main is a full commit id (fixture control)" "$(printf '%s\n' "$SNMAIN" | LC_ALL=C grep -c '^[0-9a-f]\{40\}$')" 1
is "the last-row fixture: home's and two's land directories differ (fixture control)" "$([ "$SNLAND" != "$SN2LAND" ] && echo differ)" differ

# ---- no ledger file: "; last ledger row none" ---------------------------------------------
rm -rf "$SNLAND" "$SN2LAND"; mkdir -p "$SNLAND"
_sn_pages none; T="$SNX/none.tsv"
CL="; last ledger row none"
is "R11 none control: the ledger source row says none" "$(_sn_srcf "$T" ledger 4)" none
_sn_is "R11 none control: no ledger, so a green plain pull request" "$T" 401 ready lander
_sn_is "R11 none control: and another" "$T" 402 ready lander
is "R11 none: the lander row is not-live (no lock), as it was before R11" "$(_sn_srcf "$T" lander 4)" not-live
_sn_expect "R11 none: with no ledger file" none "$CL"
has "R11 none control: paused no stays in the detail" "$(_sn_srcf "$T" lander 8)" "paused no"
is "R11 none: and it comes before the clause" "$(_sn_before "$(_sn_srcf "$T" lander 8)" "paused no" "$CL")" before
_sn_status none
is "R11 none: --status exits 0, plain and --tsv" "$(cat "$SNX/none.st.rc")$(cat "$SNX/none.stt.rc")" 00
has "A31: --status with no ledger prints a last line saying none" "$(_sn_st_txt "$SNX/none.st")" "none"
is "A31: and --status --tsv prints last, a tab, none" "$(_sn_st_tsv "$SNX/none.stt")" "last${SNTAB}none"

# ---- several rows: only the last line counts, a job-level row ---------------------------------
_sn_row "$SN_T1" unreadable - - - 0 "first unreadable marker-one"       >  "$SN/s1.rows"
_sn_row "$SN_T2" skip 402 "$(_sn_sha 402)" - 0 "waiting marker-two"        >> "$SN/s1.rows"
_sn_row "$SN_T3" gh - - - 0 "gh failed marker-three"                      >> "$SN/s1.rows"
_sn_row "$SN_T4" unreadable - - - 0 "macOS refused the read of the home marker-four" >> "$SN/s1.rows"
_sn_ledger < "$SN/s1.rows"
_sn_pages s1; T="$SNX/s1.tsv"
CL="$(_sn_clause "$SN_T4" unreadable "macOS refused the read of the home marker-four")"
is "R11 control: four ledger rows, three of them older (fixture control)" "$(LC_ALL=C awk 'END { print NR }' "$SNLAND/ledger.tsv")" 4
is "R11: the ledger source row says read" "$(_sn_srcf "$T" ledger 4)" read
_sn_expect "R11 job-level newest row (PR column -)" s1 "$CL"
for _snm in marker-one marker-two marker-three; do
  _sn_lacks "R11 only the last line counts: the detail does not hold $_snm" "$(_sn_srcf "$T" lander 8)" "$_snm"
done
for _snt in "$SN_T1" "$SN_T2" "$SN_T3"; do
  _sn_lacks "R11 only the last line counts: nor the older time $_snt" "$(_sn_srcf "$T" lander 8)" "$_snt"
done
_sn_lacks "R11 only the last line counts: and the text page names none of the older markers" "$(cat "$SNX/s1.txt")" "marker-three"
is "R11: the lander row's state is the same with an unreadable newest row: not-live" "$(_sn_srcf "$T" lander 4)" not-live
_sn_is "R11: no pull request's state changes: #401 stays ready and needs the lander" "$T" 401 ready lander
_sn_is "R11: and #402, which has a skip row of its own earlier, stays ready" "$T" 402 ready lander
_sn_status s1
is "A31: --status exits 0, plain and --tsv" "$(cat "$SNX/s1.st.rc")$(cat "$SNX/s1.stt.rc")" 00
is "A31: --status prints one last line" "$(_sn_st_txt "$SNX/s1.st" | LC_ALL=C awk 'END { print NR }')" 1
has "A31: it shows the newest row's time" "$(_sn_st_txt "$SNX/s1.st")" "$SN_T4"
has "A31: and its kind" "$(_sn_st_txt "$SNX/s1.st")" unreadable
has "A31: and its detail" "$(_sn_st_txt "$SNX/s1.st")" "macOS refused the read of the home marker-four"
_sn_lacks "A31: and none of the older rows" "$(_sn_st_txt "$SNX/s1.st")" "marker-three"
is "A31: --status --tsv prints one last row" "$(_sn_st_tsv "$SNX/s1.stt" | LC_ALL=C awk 'END { print NR }')" 1
is "A31: it is last, a tab, then the row as the ledger has it" "$(_sn_st_tsv "$SNX/s1.stt")" "last${SNTAB}$(LC_ALL=C sed -n '$p' "$SNLAND/ledger.tsv")"
_sn_agree "R11: the page's clause and --status's last row are one row: time, event and detail agree" "$T" "$SNX/s1.stt"

# ---- the newest row is a pull request's row, an older job-level row before it -----------------
_sn_row "$SN_T1" unreadable - - - 0 "older job-level marker-old"                              >  "$SN/b.rows"
_sn_row 2026-10-18T09:00:00Z skip 402 "$(_sn_sha 402)" - 0 "waiting for checks marker-pr"    >> "$SN/b.rows"
_sn_ledger < "$SN/b.rows"
_sn_pages b; T="$SNX/b.tsv"
CL="$(_sn_clause 2026-10-18T09:00:00Z skip "waiting for checks marker-pr")"
_sn_expect "R11 newest row of any kind: a skip row for #402 is the one named" b "$CL"
_sn_lacks "R11: not the older job-level row before it" "$(_sn_srcf "$T" lander 8)" "marker-old"
_sn_lacks "R11: and not its event" "$(_sn_srcf "$T" lander 8)" unreadable
_sn_is "R11: #402, whose own newest row is that skip, stays ready" "$T" 402 ready lander
_sn_is "R11: and #401, with no row of its own, stays ready" "$T" 401 ready lander
_sn_status b
has "A31: --status's last line is the pull request's row too" "$(_sn_st_txt "$SNX/b.st")" "marker-pr"
_sn_lacks "A31: and not the older job-level one" "$(_sn_st_txt "$SNX/b.st")" "marker-old"
_sn_agree "R11: the page's clause and --status's last row agree when the newest row is a pull request's" "$T" "$SNX/b.stt"

# ---- a carriage return inside the detail becomes a space ------------------------------------------
_sn_row "$SN_T1" unreadable - - - 0 "older marker-cr-old"                                          >  "$SN/c.rows"
_sn_row 2026-10-18T09:10:00Z unreadable - - - 0 $'first part\rsecond part'                           >> "$SN/c.rows"
_sn_ledger < "$SN/c.rows"; _snsum="$(cksum < "$SNLAND/ledger.tsv")"
_sn_pages c; T="$SNX/c.tsv"
CL="$(_sn_clause 2026-10-18T09:10:00Z unreadable "first part second part")"
is "R11 control: the ledger's newest row holds a carriage return (fixture control)" "$(LC_ALL=C grep -c "$(printf '\r')" "$SNLAND/ledger.tsv")" 1
_sn_expect "R11 a carriage return in the detail is a space" c "$CL"
is "R11: no carriage return reaches the --tsv page" "$(LC_ALL=C grep -c "$(printf '\r')" "$T")" 0
is "R11: nor the text page" "$(LC_ALL=C grep -c "$(printf '\r')" "$SNX/c.txt")" 0
is "R11: the page left the ledger as it was" "$(cksum < "$SNLAND/ledger.tsv")" "$_snsum"
_sn_is "R11: and a pull request is still ready" "$T" 401 ready lander

# ---- a row with fewer than seven columns: an empty detail, and the page does not break ---------------
printf '%s\tgh\t-\n' 2026-10-18T09:40:00Z > "$SN/d1.rows"
_sn_ledger < "$SN/d1.rows"
_sn_pages d1; T="$SNX/d1.tsv"
is "R11 short row: a row of three columns: both pages exit 0" "$(cat "$T.rc")$(cat "$SNX/d1.txt.rc")" 00
is "R11 short row: every row of the --tsv page has eight columns, three columns in the ledger row" "$(_sn_cols "$T")" ""
_sn_endt "R11 short row: the detail ends with the time and event and a colon, the detail empty (three columns)" "$(_sn_srcf "$T" lander 8)" "; last ledger row 2026-10-18T09:40:00Z gh:"
has "R11 short row: the text page names the row (three columns)" "$(cat "$SNX/d1.txt")" "; last ledger row 2026-10-18T09:40:00Z gh:"
is "R11 short row: the ledger source row says read" "$(_sn_srcf "$T" ledger 4)" read
_sn_is "R11 short row: a pull request is still ready" "$T" 401 ready lander
printf '%s\tfetch\t-\t-\t-\t0\n' 2026-10-18T09:41:00Z > "$SN/d2.rows"
_sn_ledger < "$SN/d2.rows"
_sn_pages d2; T="$SNX/d2.tsv"
is "R11 short row: a row of six columns: both pages exit 0" "$(cat "$T.rc")$(cat "$SNX/d2.txt.rc")" 00
is "R11 short row: every row of the --tsv page has eight columns, six columns in the ledger row" "$(_sn_cols "$T")" ""
_sn_endt "R11 short row: the detail ends with the time and event and a colon, the detail empty (six columns)" "$(_sn_srcf "$T" lander 8)" "; last ledger row 2026-10-18T09:41:00Z fetch:"
has "R11 short row: the text page names the row (six columns)" "$(cat "$SNX/d2.txt")" "; last ledger row 2026-10-18T09:41:00Z fetch:"
_sn_is "R11 short row: a pull request is still ready" "$T" 402 ready lander

# ---- ESC and BEL in the detail reach the terminal as ? (R8 covers this detail) ----------------------
_sn_row "$SN_T1" unreadable - - - 0 "plain older row"                                              >  "$SN/i.rows"
_sn_row 2026-10-18T09:20:00Z deploy-owed - - - 0 $'bad\033byte and bel\007ring end'                >> "$SN/i.rows"
_sn_ledger < "$SN/i.rows"
_sn_pages i; T="$SNX/i.tsv"
CL="$(_sn_clause 2026-10-18T09:20:00Z deploy-owed "bad?byte and bel?ring end")"
is "R8 control: the ledger's newest row holds ESC and BEL (fixture control)" "$(LC_ALL=C grep -c "$(printf '\033')" "$SNLAND/ledger.tsv")|$(LC_ALL=C grep -c "$(printf '\007')" "$SNLAND/ledger.tsv")" "1|1"
_sn_expect "R8 the detail of the newest row: ESC and BEL show as ?" i "$CL"
is "R8: no byte below space but tab and newline, no DEL and no C1 control reaches the --tsv page" "$(_sn_ctl "$T")" 0
is "R8: nor the text page" "$(_sn_ctl "$SNX/i.txt")" 0

# ---- paused: the reason stays, and the clause comes after it -------------------------------------------
_sn_row 2026-10-18T10:00:00Z paused - - - 0 "paused by hand marker-paused" > "$SN/g.rows"
_sn_ledger < "$SN/g.rows"
printf 'deploy window\nthe rest of it\n' > "$SNLAND/paused"
_sn_pages g; T="$SNX/g.tsv"
CL="$(_sn_clause 2026-10-18T10:00:00Z paused "paused by hand marker-paused")"
_sn_expect "R11 with paused present" g "$CL"
_snd="$(_sn_srcf "$T" lander 8)"
has "R11 paused control: paused yes stays in the detail" "$_snd" "paused yes"
has "R11 paused: and the paused reason, the first line of the file" "$_snd" "deploy window"
is "R11 paused: paused yes comes before the clause" "$(_sn_before "$_snd" "paused yes" "$CL")" before
is "R11 paused: the paused reason comes before the clause" "$(_sn_before "$_snd" "deploy window" "$CL")" before
has "R11 paused: the text page holds the reason too" "$(cat "$SNX/g.txt")" "deploy window"
_sn_is "R11 paused: a pull request is still ready, and needs the lander" "$T" 401 ready lander
rm -f "$SNLAND/paused"

# ---- a live lock and an unreadable newest row: nothing but the clause changes ------------------------------
_sn_row 2026-10-18T07:00:00Z refused 402 "$(_sn_sha 402)" "$SNH" 3 "stale receipt [main $SNMAIN]"  >  "$SN/h.rows"
_sn_row 2026-10-18T07:10:00Z skip 401 "$(_sn_sha 401)" - 0 "waiting"                                >> "$SN/h.rows"
_sn_row 2026-10-18T10:10:00Z unreadable - - - 0 "macOS refused the read of the home marker-h"        >> "$SN/h.rows"
_sn_ledger < "$SN/h.rows"
rm -rf "$SNLAND/lock"; mkdir -p "$SNLAND/lock"; printf '%s\n' "$$" > "$SNLAND/lock/pid"; : > "$SNLAND/lock/started"
_sn_pages h; T="$SNX/h.tsv"
CL="$(_sn_clause 2026-10-18T10:10:00Z unreadable "macOS refused the read of the home marker-h")"
_sn_expect "R11 a live lock, the newest row unreadable" h "$CL"
is "R11: the lander row's state is live, unchanged by the newest row" "$(_sn_srcf "$T" lander 4)" live
_sn_is "R11: #402, whose own newest row is a refusal on the current main, is still refused" "$T" 402 refused session
has "R11: and its detail still holds the refusal's detail" "$(_sn_f "$T" 402 8)" "the lander was refused: stale receipt"
_sn_is "R11: #401, whose own newest row is a skip, is still ready" "$T" 401 ready lander
_sn_lacks "R11: the job-level row did not become #402's" "$(_sn_f "$T" 402 8)" "marker-h"
_sn_lacks "R11: nor #401's" "$(_sn_f "$T" 401 8)" "marker-h"
rm -rf "$SNLAND/lock"

# ---- an unreadable ledger: "; last ledger row not read" ----------------------------------------------------
_sn_row 2026-10-18T10:20:00Z unreadable - - - 0 "marker-unread must not be shown" > "$SN/f.rows"
_sn_ledger < "$SN/f.rows"
rm -f "$SNLAND/ledger.tsv"; mkdir -p "$SNLAND/ledger.tsv"
_sn_pages fdir; T="$SNX/fdir.tsv"
CL="; last ledger row not read"
is "R11 unread control: a directory where the ledger should be: the ledger row says unread" "$(_sn_srcf "$T" ledger 4)" unread
_sn_expect "R11 unread: a directory where the ledger should be" fdir "$CL"
_sn_is "R11 unread control: and a plain green pull request is unknown, as §5 says" "$T" 401 unknown unknown
rm -rf "$SNLAND/ledger.tsv"
_sn_ledger < "$SN/f.rows"
chmod 000 "$SNLAND"
if [ -e "$SNLAND/ledger.tsv" ] || [ -L "$SNLAND/ledger.tsv" ]; then
  chmod 755 "$SNLAND"
  skip "R11 unread: a land directory that cannot be searched holds a ledger that is not read" "this user searches a mode-000 directory"
else
  _sn_pages f000; chmod 755 "$SNLAND"; T="$SNX/f000.tsv"
  is "R11 unread control: land/ at mode 000: the ledger row says unread" "$(_sn_srcf "$T" ledger 4)" unread
  _sn_expect "R11 unread: a land directory that cannot be searched" f000 "$CL"
  _sn_lacks "R11 unread: and the row it holds is not shown" "$(_sn_srcf "$T" lander 8)" "marker-unread"
fi
is "R11 unread: the modes are restored and the ledger reads again (fixture control)" "$(LC_ALL=C cut -f2 "$SNLAND/ledger.tsv" 2>&1)" unreadable

# ---- --repo DIR reads that project's ledger, not the current one's -----------------------------------------------
_sn_row "$SN_T1" fetch - - - 0 "git fetch failed in home marker-home" > "$SN/r1.rows"
_sn_ledger < "$SN/r1.rows"
rm -rf "$SN2LAND"; mkdir -p "$SN2LAND"
_sn_row 2026-10-18T11:00:00Z gh - - - 0 "gh failed in two marker-two-ledger" > "$SN2LAND/ledger.tsv"
_sn_pages r1 "$SNH"; T="$SNX/r1.tsv"
_sn_pages r2 "$SNH" --repo "$SN2"; T2="$SNX/r2.tsv"
_sn_pages r3 "$SN2"; T3="$SNX/r3.tsv"
is "R11 --repo control: the home's page reads fixture/home's pull requests" "$(_sn_state "$T" 401)" ready
is "R11 --repo control: and --repo two reads two's, not home's" "$(_sn_state "$T2" 501)|$(_sn_row_of "$T2" 401)" "ready|"
_sn_expect "R11 --repo: the home's page names the home project's newest row" r1 "$(_sn_clause "$SN_T1" fetch "git fetch failed in home marker-home")"
_sn_expect "R11 --repo: --repo naming two names two's newest row" r2 "$(_sn_clause 2026-10-18T11:00:00Z gh "gh failed in two marker-two-ledger")"
_sn_lacks "R11 --repo: and not the home's" "$(_sn_srcf "$T2" lander 8)" "marker-home"
_sn_expect "R11 --repo: run from two's checkout, the same" r3 "$(_sn_clause 2026-10-18T11:00:00Z gh "gh failed in two marker-two-ledger")"
_sn_lacks "R11 --repo: the home's page does not name two's row" "$(_sn_srcf "$T" lander 8)" "marker-two-ledger"

# ---- the fixture is removed --------------------------------------------------------------------------------------
chmod -R u+rwx "$SN" 2>/dev/null; rm -rf "$SN"
[ -e "$SN" ] && bad "the last-row fixture is removed when its part ends" "$SN is still there" || ok "the last-row fixture is removed when its part ends"
# <<< stuck-pr-page-last-ledger-row
