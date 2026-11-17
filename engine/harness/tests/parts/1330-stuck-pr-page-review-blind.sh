# >>> stuck-pr-page-review
printf '\nthe stuck-PR page: what the review found, path bytes gh escapes, a land directory that cannot be searched, a truncated queue, every founder rule named (spec v2, blind)\n'
# Blind, written on 2026-10-17 from spec v2 (audits/2026-10-01-report-v5-review/
# specs/stuck-pr/spec-v2.md) and the review's findings restated as behaviour,
# without reading lib/pr-status*.sh or felix_land. Self-contained after the
# preamble: it builds its own fixture and removes it, and reads nothing parts
# 1300 to 1320 define.
#
# The fixture: one bare origin whose path ends github.com/fixture/home.git, so
# the slug is fixture/home and the governed account fixture, and a clone of it
# that is also the Felix home, holding projects/felix (remote_match
# github.com/fixture/home). Its origin/main holds a land table with one founder
# row (lrow/.*) and a risk table with one path row naming a channel and no
# confine (^rrow/plain/). gh and launchctl are stubs first on PATH. gh answers
# pr list from ctl/prs.json, the Actions billing GET from a fixed body, and a
# GET of repos/fixture/home with its default branch, main.
#
# Findings pinned here (review of b5bff086):
#   F1  a path holding a tab, newline, carriage return or another control byte,
#       which gh prints as a JSON escape, is a founder path (path-bytes), §4.5.
#   F2' a path holding a backslash, printable ASCII, is not path-bytes, and the
#       detail names it with one backslash, §4.5.
#   F2  a ledger whose land directory cannot be searched is unread, not absent,
#       §4.3 and §5.
#   F3  at 1000 pull requests --queue says the list may be incomplete, §3.
#   F4  a pull request with more founder paths than five names every rule that
#       fired, and a trust-base detail names every trust-base path, §4 and §4.5.
SQ="$TMP/stuck-pr-review"; mkdir -p "$SQ"; SQ="$(cd "$SQ" && pwd -P)"
SQO="$SQ/github.com/fixture/home.git"; SQH="$SQ/home"
SQM="$SQ/mem"; SQU="$SQ/user"; SQB="$SQ/bin"; SQK="$SQ/ctl"; SQL="$SQ/log"; SQX="$SQ/out"; SQT="$SQ/tmp"
SQLAND="$(FELIX_MEMORY="$SQM" felix_mem_dir felix)/land"
mkdir -p "$SQO" "$SQM" "$SQU/.config/gh" "$SQB" "$SQK" "$SQL" "$SQX" "$SQT" "$SQ/cache"
_sq_put() { mkdir -p "$(dirname "$1")" && LC_ALL=C sed "s#@SQ@#$SQ#g" > "$1" && chmod +x "$1"; }
_sq_put "$SQB/gh" <<'SQSTUB'
#!/bin/bash
SQ='@SQ@'; K="$SQ/ctl"
printf '%s\n' "$*" >> "$SQ/log/gh.log"
jqx=""; prev=""; bill=0; dflt=0
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; esac
  case "$a" in *settings/billing/usage*) bill=1; bq="$a" ;; repos/fixture/home|/repos/fixture/home) dflt=1 ;; esac
  prev="$a"
done
out() { if [ -n "$jqx" ] && command -v jq >/dev/null 2>&1; then jq -r "$jqx"; else cat; fi; }
case "${1:-} ${2:-}" in
  "pr list") [ -f "$K/prs.json" ] || { printf 'stub: no answer\n' >&2; exit 4; }; out < "$K/prs.json"; exit 0 ;;
esac
if [ "${1:-}" = api ]; then
  [ "$bill" = 1 ] && { by="${bq##*year=}"; by="${by%%&*}"; bm="${bq##*month=}"; bm="${bm%%&*}"; [ "${#bm}" -eq 1 ] && bm="0$bm"; printf '{"usageItems":[{"date":"%s-%s-01T00:00:00Z","product":"actions","sku":"Actions Linux","quantity":5.0,"unitType":"Minutes","pricePerUnit":0.006,"grossAmount":0.0,"discountAmount":0.0,"netAmount":0.0,"repositoryName":"home"}]}\n' "$by" "$bm" | out; exit 0; }
  [ "$dflt" = 1 ] && { printf '{"full_name":"fixture/home","default_branch":"main"}\n' | out; exit 0; }
  printf 'gh: Not Found (HTTP 404)\n' >&2; exit 1
fi
printf 'stub: gh %s is not served\n' "$*" >&2
exit 1
SQSTUB
_sq_put "$SQB/launchctl" <<'SQSTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@SQ@/log/launchctl.log'
case "${1:-}" in print) exit 113 ;; esac
exit 0
SQSTUB

# ---- the repository ----------------------------------------------------------
_fx_git "$SQO" init -q --bare >/dev/null 2>&1
_fx_git "$SQO" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
_fx_git "$SQ" clone -q "$SQO" home >/dev/null 2>&1
_fx_git "$SQH" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
mkdir -p "$SQH/projects/felix" "$SQH/notes"
printf '{\n  "name": "felix",\n  "remote_match": "github.com/fixture/home",\n  "gate": "true"\n}\n' > "$SQH/projects/felix/project.json"
printf '# felix\n' > "$SQH/projects/felix/CLAUDE.md"
printf 'lrow/.*\tfounder\t-\t-\n' > "$SQH/projects/felix/land.tsv"
printf 'red\tpath\t^rrow/plain/\ta person reads these\treviewed\t-\n' > "$SQH/projects/felix/risk.tsv"
printf 'home\n' > "$SQH/README.md"; printf 'keep\n' > "$SQH/notes/keep.md"
_fx_git "$SQH" add -A >/dev/null 2>&1
_fx_git "$SQH" -c user.name=t -c user.email=t@t commit -qm base >/dev/null 2>&1
_fx_git "$SQH" push -q -u origin main >/dev/null 2>&1
_fx_git "$SQH" fetch -q origin >/dev/null 2>&1
_fx_git "$SQH" remote set-head origin main >/dev/null 2>&1
SQMAIN="$(git -C "$SQH" rev-parse refs/remotes/origin/main 2>/dev/null)"

# ---- pull requests as gh lists them ------------------------------------------
# A path is written as gh prints it inside a JSON string: a\tb is the two
# characters backslash and t, which gh prints for a tab in the file name.
_sq_sha() { printf '%04d%s' "$1" c0ffeec0ffeec0ffeec0ffeec0ffeec0ffee; }
SQ_UPD="$(date -u -r "$(( $(date +%s) - 7200 ))" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$(( $(date +%s) - 7200 ))" +%Y-%m-%dT%H:%M:%SZ)"
SQ_GREEN='[{"__typename":"CheckRun","name":"gate","workflowName":"gate","status":"COMPLETED","conclusion":"SUCCESS"}]'
_sq_pr() {   # N FILES: green, MERGEABLE, not a draft, its own head branch; FILES is "path:deleted-lines ..."
  local s="" f fl=""
  for f in $2; do fl="$fl$s{\"path\":\"${f%:*}\",\"additions\":1,\"deletions\":${f##*:}}"; s=","; done
  printf '{"number":%s,"title":"Change %s","headRefName":"b%s","headRefOid":"%s","baseRefName":"main","isDraft":false,"isCrossRepository":false,' "$1" "$1" "$1" "$(_sq_sha "$1")"
  printf '"author":{"login":"fixture"},"labels":[],"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","statusCheckRollup":%s,"files":[%s],"updatedAt":"%s"}' "$SQ_GREEN" "$fl" "$SQ_UPD"
}
_sq_prs() { local s="" o; { printf '['; for o in "$@"; do printf '%s%s' "$s" "$o"; s=","; done; printf ']\n'; } > "$SQK/prs.json"; }

# ---- running the page and reading it -------------------------------------------
_sq_land() {   # ARGS... in the home; stdout to out/out, status in SQRC
  ( cd "$SQH" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u CLAUDE_CODE_SESSION_ID \
      HOME="$SQU" FELIX_HOME="$SQH" FELIX_HOME_DIR="$SQH" FELIX_MEMORY="$SQM" FELIX_PLUGIN_CACHE="$SQ/cache" \
      GH_CONFIG_DIR="$SQU/.config/gh" TMPDIR="$SQT" PATH="$SQB:$PATH" "$FELIX" land "$@" ) > "$SQX/out" 2> "$SQX/err"
  SQRC=$?
}
_sq_keep() { cp "$SQX/out" "$SQX/$1"; printf '%s\n' "$SQRC" > "$SQX/$1.rc"; }
_sq_row()   { LC_ALL=C awk -F'\t' -v r="#$2" '$1 == "pr" && $3 == r' "$1" 2>/dev/null; }
_sq_nrow()  { _sq_row "$1" "$2" | LC_ALL=C awk 'END { print NR }'; }
_sq_f()     { _sq_row "$1" "$2" | LC_ALL=C awk -F'\t' -v k="$3" 'NR == 1 { printf "%s", $k }'; }
_sq_state() { _sq_f "$1" "$2" 4 | LC_ALL=C sed 's/,.*//'; }
_sq_srcf()  { LC_ALL=C awk -F'\t' -v r="$2" -v k="$3" '$1 == "source" && $3 == r { printf "%s", $k; exit }' "$1" 2>/dev/null; }
_sq_lacks() { case "$2" in *"$3"*) bad "$1" "[$2] holds [$3]" ;; *) ok "$1" ;; esac; }
_sq_is() {   # LABEL FILE N STATE NEEDS
  is "$1: #$3 is in state $4" "$(_sq_state "$2" "$3")" "$4"
  [ -z "$5" ] || is "$1: #$3 needs $5" "$(_sq_f "$2" "$3" 5)" "$5"
}
# A rule name stands in TEXT as a word of its own: no letter just before or
# after it, so the path exceptions.tsv does not name the rule exception, nor
# the word lander the rule land.
_sq_word() {   # TEXT WORD -> named | missing
  printf '%s' "$1" | LC_ALL=C awk -v r="$2" '{ s = $0; p = ""
    while ((i = index(s, r)) > 0) {
      b = (i > 1) ? substr(s, i - 1, 1) : p; a = substr(s, i + length(r), 1)
      if (b !~ /[a-z]/ && a !~ /[a-z]/) f = 1
      p = substr(s, i + length(r) - 1, 1); s = substr(s, i + length(r)) } }
    END { print f ? "named" : "missing" }'
}

# ---- the pull requests -------------------------------------------------------
# #163 changes one path for each of eleven founder rules, more than five.
SQ_MANY="projects/felix/stack.tsv:0 projects/felix/ecosystem.tsv:0 projects/felix/qualification.tsv:1 .github/workflows/x.yml:0"
SQ_MANY="$SQ_MANY projects/felix/autonomy:0 projects/felix/exceptions.tsv:0 migrations/x.sql:0 rrow/plain/a.md:0 lrow/x.md:0"
SQ_MANY="$SQ_MANY projects/felix/CLAUDE.md:0 notes/caf$(printf '\303\251').md:0"
_sq_prs "$(_sq_pr 170 notes/170.md:0)" "$(_sq_pr 169 notes/169.md:0)" "$(_sq_pr 168 'notes/a\u007fb.md:0')" "$(_sq_pr 167 'engine/harness/felix:0 engine/harness/lib/verify.sh:0')" \
        "$(_sq_pr 166 'notes/a\u0001b.md:0')" "$(_sq_pr 165 'projects/felix/CLAUDE.md\r:0')" "$(_sq_pr 164 'notes/a\nb.md:0')" \
        "$(_sq_pr 163 "$SQ_MANY")" "$(_sq_pr 162 'lrow/a\\b.md:0')" "$(_sq_pr 161 'notes/a\\b.md:0')" "$(_sq_pr 160 'notes/a\tb.md:0')"
rm -rf "$SQLAND"; mkdir -p "$SQLAND"
printf '2026-10-16T09:10:00Z\trefused\t169\t%s\t%s\t3\tthe receipt is stale [main %s]\n' "$(_sq_sha 169)" "$SQH" "$SQMAIN" > "$SQLAND/ledger.tsv"

# ---- fixture controls ----------------------------------------------------------
is "the review fixture: origin/main holds the lrow founder row and the rrow risk row (fixture control)" \
   "$(git -C "$SQH" show refs/remotes/origin/main:projects/felix/land.tsv 2>&1 | LC_ALL=C cut -f1)|$(git -C "$SQH" show refs/remotes/origin/main:projects/felix/risk.tsv 2>&1 | LC_ALL=C cut -f3)" \
   "lrow/.*|^rrow/plain/"
if command -v jq >/dev/null 2>&1; then
  is "the review fixture: gh's answer is JSON, and #160's path holds a real tab once decoded (fixture control)" \
     "$(jq -r '.[] | select(.number == 160) | .files[0].path' "$SQK/prs.json" 2>&1 | LC_ALL=C od -An -c | LC_ALL=C tr -d ' \n')" 'notes/a\tb.md\n'
  is "the review fixture: #161's path holds one backslash once decoded, and #166's a byte 001 (fixture control)" \
     "$(jq -r '.[] | select(.number == 161) | .files[0].path' "$SQK/prs.json" 2>&1)|$(jq -r '.[] | select(.number == 166) | .files[0].path' "$SQK/prs.json" 2>&1 | LC_ALL=C od -An -b | LC_ALL=C tr -s ' ' | LC_ALL=C sed 's/^ //; s/ $//')" \
     'notes/a\b.md|156 157 164 145 163 057 141 001 142 056 155 144 012'
else skip "the review fixture: gh's answer is JSON (fixture control)" "no jq"; fi

# ---- F1, F2': path bytes as gh prints them (§4.5 path-bytes, §6.1) ------------
_sq_land --prs --tsv; _sq_keep bytes.tsv
T="$SQX/bytes.tsv"
is "spec §7: the page over escaped paths exits 0" "$(cat "$T.rc")" 0
_sq_is "case 27: a path holding a tab, printed by gh as \\t, green" "$T" 160 founder founder
is "case 27: by the rule path-bytes" "$(_sq_word "$(_sq_f "$T" 160 8)" path-bytes)" named
_sq_is "case 27: a path holding a newline, printed as \\n" "$T" 164 founder founder
is "case 27: by the rule path-bytes" "$(_sq_word "$(_sq_f "$T" 164 8)" path-bytes)" named
_sq_is "case 27: projects/felix/CLAUDE.md with a carriage return at its end, printed as \\r" "$T" 165 founder founder
is "case 27: by the rule path-bytes" "$(_sq_word "$(_sq_f "$T" 165 8)" path-bytes)" named
_sq_is "case 27: a path holding the byte 001, printed as \\u0001" "$T" 166 founder founder
is "case 27: by the rule path-bytes" "$(_sq_word "$(_sq_f "$T" 166 8)" path-bytes)" named
_sq_is "case 27: a path holding DEL, printed as \\u007f, which is outside printable ASCII" "$T" 168 founder founder
is "case 27: by the rule path-bytes" "$(_sq_word "$(_sq_f "$T" 168 8)" path-bytes)" named
is "spec §6.1: the pull request whose path holds a tab is one row of eight columns" "$(_sq_nrow "$T" 160)|$(_sq_row "$T" 160 | LC_ALL=C awk -F'\t' '{ print NF }')" "1|8"
is "spec §6.1: the one whose path holds a newline is one row of eight columns" "$(_sq_nrow "$T" 164)|$(_sq_row "$T" 164 | LC_ALL=C awk -F'\t' '{ print NF }')" "1|8"
is "spec §6.1: the one whose path ends in a carriage return is one row of eight columns" "$(_sq_nrow "$T" 165)|$(_sq_row "$T" 165 | LC_ALL=C awk -F'\t' '{ print NF }')" "1|8"
is "spec §6.1: no line of the page holds a carriage return" "$(LC_ALL=C awk -v cr="$(printf '\r')" 'index($0, cr) { n++ } END { print n + 0 }' "$T")" 0
_sq_is "spec §4.5: a path holding a backslash, printable ASCII, green and nothing else" "$T" 161 ready lander
is "spec §4.5: a backslash is not the rule path-bytes" "$(_sq_word "$(_sq_f "$T" 161 8)" path-bytes)" missing
_sq_is "spec §4.5: a backslash path the land row matches is founder by that row" "$T" 162 founder founder
is "spec §4.5: by the rule land" "$(_sq_word "$(_sq_f "$T" 162 8)" land)" named
is "spec §4.5: and not by path-bytes" "$(_sq_word "$(_sq_f "$T" 162 8)" path-bytes)" missing
has "spec §4.5: its detail names the path as it is, with one backslash" "$(_sq_f "$T" 162 8)" 'lrow/a\b.md'
_sq_lacks "spec §4.5: and never doubled" "$(_sq_f "$T" 162 8)" 'a\\b'

# ---- F4: every founder rule that fired is named (§4, §4.5) ----------------------
_sq_is "spec §4.5: a pull request changing a path for each of eleven founder rules" "$T" 163 founder founder
_sqd="$(_sq_f "$T" 163 8)"
for _sqr in commission exemption verifier execute authority exception durable risk land direction path-bytes; do
  is "spec §4.5: each match is listed with its rule name, more than five of them: $_sqr" "$(_sq_word "$_sqd" "$_sqr")" named
done
_sq_is "spec §4: a pull request changing two paths of the trust base" "$T" 167 ready lander
has "spec §4: every condition that holds is listed: the first trust-base path" "$(_sq_f "$T" 167 8)" "engine/harness/felix"
has "spec §4: and the second" "$(_sq_f "$T" 167 8)" "engine/harness/lib/verify.sh"

# ---- F2: a land directory that cannot be searched (§4.3, §5) --------------------
_sq_is "spec §4.3: the ledger refused #169's head on the current origin/main (control for what follows)" "$T" 169 refused session
_sq_is "spec §4.3: and #170, plain and green with no ledger row, is ready (control for what follows)" "$T" 170 ready lander
is "spec §4.3: and the ledger row says read (control)" "$(_sq_srcf "$T" ledger 4)" read
chmod 000 "$SQLAND"
if [ -e "$SQLAND/ledger.tsv" ] || [ -L "$SQLAND/ledger.tsv" ]; then
  chmod 755 "$SQLAND"
  skip "spec §4.3: a land directory that cannot be searched holds a ledger that is unread" "this user searches a mode-000 directory"
else
  _sq_land --prs --tsv; _sq_keep land000.tsv
  chmod 755 "$SQLAND"
  is "spec §7: the page exits 0 while land/ cannot be searched" "$(cat "$SQX/land000.tsv.rc")" 0
  is "spec §4.3: land/ at mode 000: the ledger is there but cannot be read, so its row says unread, not none" "$(_sq_srcf "$SQX/land000.tsv" ledger 4)" unread
  _sq_is "spec §5: and the pull request the ledger refused is unknown, never ready" "$SQX/land000.tsv" 169 unknown unknown
  has "spec §5: its detail says the lander's ledger was not read" "$(_sq_f "$SQX/land000.tsv" 169 8)" "the lander's ledger not read"
  _sq_is "spec §5: and a plain green pull request that reaches state 10 is unknown too" "$SQX/land000.tsv" 170 unknown unknown
fi
chmod 000 "${SQLAND%/*}"
if [ -e "$SQLAND" ] || [ -L "$SQLAND" ]; then
  chmod 755 "${SQLAND%/*}"
  skip "spec §4.3: a project memory directory that cannot be searched hides whether a ledger is there" "this user searches a mode-000 directory"
else
  _sq_land --prs --tsv; _sq_keep mem000.tsv
  chmod 755 "${SQLAND%/*}"
  is "spec §4.3: the project's memory directory at mode 000, land/ and its ledger inside: the ledger row says unread, not none" "$(_sq_srcf "$SQX/mem000.tsv" ledger 4)" unread
  _sq_is "spec §5: and the pull request the ledger refused is unknown" "$SQX/mem000.tsv" 169 unknown unknown
fi
is "the review fixture: the modes are restored and the ledger reads again (fixture control)" "$(LC_ALL=C cut -f3 "$SQLAND/ledger.tsv" 2>&1)" 169

# ---- F4, F11: what reaches the terminal (§6.2) ----------------------------------
# A title is written by someone else. gh prints a C1 control raw, as its two
# UTF-8 bytes; the page prints it as a question mark. A title cut at 60 bytes
# never ends in half a character.
SQ_C1="$(printf '\302\233')"; SQ_E="$(printf '\303\251')"
SQ_LONG="$(printf 'a%.0s' 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59)"
_sq_prs "$(_sq_pr 171 notes/171.md:0 | LC_ALL=C sed "s/\"title\":\"Change 171\"/\"title\":\"T${SQ_C1}end\"/")" \
        "$(_sq_pr 172 notes/172.md:0 | LC_ALL=C sed "s/\"title\":\"Change 172\"/\"title\":\"${SQ_LONG}${SQ_E}${SQ_E}tail\"/")"
_sq_land --prs; _sq_keep tame.txt
is "spec §6.2: the page over a title holding a C1 control exits 0" "$(cat "$SQX/tame.txt.rc")" 0
has "spec §6.2: the title is on the page" "$(cat "$SQX/tame.txt")" "#171 ready T"
is "spec §6.2: no 0x9b byte reaches the terminal" "$(LC_ALL=C grep -c "$SQ_C1" "$SQX/tame.txt")" 0
_sq_l172="$(LC_ALL=C grep '^#172 ' "$SQX/tame.txt")"
has "spec §6.2: the long title is on the page" "$_sq_l172" "#172 ready ${SQ_LONG}"
if command -v iconv >/dev/null 2>&1; then
  printf '%s\n' "$_sq_l172" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1 && ok "spec §6.2: a title cut at 60 does not end in half a UTF-8 character" || bad "spec §6.2: a title cut at 60 does not end in half a UTF-8 character" "iconv refuses [$_sq_l172]"
else skip "spec §6.2: a title cut at 60 does not end in half a UTF-8 character" "no iconv"; fi

# ---- F9: a repository no project governs (§7) -------------------------------------
mkdir -p "$SQ/free" && _fx_git "$SQ/free" init -q >/dev/null 2>&1
_sq_land --prs --tsv --repo "$SQ/free"; _sq_keep free.tsv
is "spec §7: a repository no project governs: the page prints and exits 0" "$(cat "$SQX/free.tsv.rc")" 0
is "spec §7: and its land table is unread" "$(LC_ALL=C awk -F'\t' '$1 == "source" && $3 == "land" { print $4; exit }' "$SQX/free.tsv")" unread
is "spec §7: its lander row is unread" "$(LC_ALL=C awk -F'\t' '$1 == "source" && $3 == "lander" { print $4; exit }' "$SQX/free.tsv")" unread
is "spec §5: and its ledger row is unread" "$(LC_ALL=C awk -F'\t' '$1 == "source" && $3 == "ledger" { print $4; exit }' "$SQX/free.tsv")" unread

# ---- F3: a list of 1000 is truncated, in --prs and in --queue (§3, §5) -----------
LC_ALL=C awk -v u="$SQ_UPD" -v g="$SQ_GREEN" 'BEGIN { printf "["
  for (n = 1000; n >= 1; n--) {
    printf "%s{\"number\":%d,\"title\":\"Bulk %d\",\"headRefName\":\"bulk%d\",\"headRefOid\":\"%04dc0ffeec0ffeec0ffeec0ffeec0ffeec0ffee\",", (n < 1000 ? "," : ""), n, n, n, n
    printf "\"baseRefName\":\"main\",\"isDraft\":false,\"isCrossRepository\":false,\"author\":{\"login\":\"fixture\"},\"labels\":[],"
    printf "\"mergeable\":\"MERGEABLE\",\"mergeStateStatus\":\"CLEAN\",\"statusCheckRollup\":%s,", g
    printf "\"files\":[{\"path\":\"notes/bulk%d.md\",\"additions\":1,\"deletions\":0}],\"updatedAt\":\"%s\"}", n, u }
  print "]" }' > "$SQK/prs.json"
rm -rf "$SQLAND"
is "the review fixture: gh lists 1000 pull requests (fixture control)" \
   "$(LC_ALL=C grep -o '"number":[0123456789]*' "$SQK/prs.json" | LC_ALL=C awk 'END { print NR }')" 1000
_sq_land --prs --tsv; _sq_keep trunc.tsv
_sq_land --prs; _sq_keep trunc.txt
_sq_land --queue --tsv; _sq_keep truncq.tsv
_sq_land --queue; _sq_keep truncq.txt
is "spec §7: the four runs over 1000 pull requests exit 0" \
   "$(cat "$SQX/trunc.tsv.rc")$(cat "$SQX/trunc.txt.rc")$(cat "$SQX/truncq.tsv.rc")$(cat "$SQX/truncq.txt.rc")" "0000"
is "spec §3: at 1000 the gh source row of --prs says truncated" "$(_sq_srcf "$SQX/trunc.tsv" gh 4)" truncated
has "spec §3: and the --prs text says the list may be incomplete" "$(cat "$SQX/trunc.txt")" "may be incomplete"
is "spec §3: the gh source row of --queue --tsv says truncated" \
   "$(LC_ALL=C awk -F'\t' '$1 == "source" && $3 == "gh" && $2 == "fixture/home" { print $4 }' "$SQX/truncq.tsv")" truncated
has "spec §3, §5: and the --queue text says the list may be incomplete, not only that no founder entries were found" "$(cat "$SQX/truncq.txt")" "may be incomplete"

# ---- the fixture is removed ------------------------------------------------------
chmod -R u+rwx "$SQ" 2>/dev/null; rm -rf "$SQ"
[ -e "$SQ" ] && bad "the review fixture is removed when its part ends" "$SQ is still there" || ok "the review fixture is removed when its part ends"
# <<< stuck-pr-page-review
