# The stuck-PR page, GitHub half: what gh says about the open pull requests of a
# repository, and about the account's Actions usage this month (lib/pr-status.sh).
#
# gh is asked `pr list` once per repository and `api` (a GET) for the budget,
# and nothing else. It keeps state of its own (a device id on first use, update
# checks), so its state and cache directories point into the page's scratch
# directory, which the run removes; its configuration, which holds how it is
# logged in, is left alone. Its output is flattened by the inventory's own
# reader (_FI_JSON, lib/inventory-gh.sh, which the caller sources) and cut into
# two tables by the awk below: one row per pull request, and one row per
# changed file. A time is turned into an epoch by the inventory's _FI_EPOCH.
#
# Bash 3.2. LC_ALL=C on every text tool; digit brackets spelled out.

# gh, in directory $1, with its own state and cache in the scratch.
_ps_ghc() {   # DIR ARGS...
  local d="$1"; shift
  ( cd "$d" 2>/dev/null || exit 1
    GH_NO_UPDATE_NOTIFIER=1 GH_PROMPT_DISABLED=1 XDG_STATE_HOME="$_PS_T/gh-state" XDG_CACHE_HOME="$_PS_T/gh-cache" gh "$@" )
}

# A slug is owner/name: one slash, nothing else that splits it.
_ps_slug_ok() {
  local tab; tab="$(printf '\t')"
  case "${1:-}" in ""|*" "*|*"$tab"*|*$'\r'*|*$'\n'*|/*|*/|*/*/*) return 1 ;; */*) return 0 ;; esac
  return 1
}

# The first line of a file, tabs and carriage returns as spaces, cut at 120
# characters; a cut never leaves half of a UTF-8 character behind.
_ps_err1() {   # FILE
  LC_ALL=C sed -n 1p "$1" 2>/dev/null | LC_ALL=C tr '\t\r' '  ' | LC_ALL=C awk '{
    s = substr($0, 1, 120); c = substr($0, 121, 1)
    if (c >= "\200" && c < "\300") { while (s != "" && substr(s, length(s)) >= "\200" && substr(s, length(s)) < "\300") s = substr(s, 1, length(s) - 1)
      if (s != "" && substr(s, length(s)) >= "\300") s = substr(s, 1, length(s) - 1) }
    print s }'
}

# gh's JSON with its escapes decoded where the page has to tell them apart,
# before the shared flattener (which turns \t, \n and \r into spaces and leaves
# \\ doubled) reads it. A control character in a string (the escapes \b \f \n
# \r \t, and \u00XX below 0x20 or 0x7f) becomes byte 001, a backslash byte 002,
# and an escaped printable ASCII character the character itself, so that a
# changed path holding a tab is seen as holding a byte outside printable ASCII
# and a path holding a backslash is not. Any other \uXXXX is outside printable
# ASCII too. \" stays for the flattener. A tab, newline and carriage return are
# byte 001, which a cell shows as a space; every other control (\b, \f, ESC,
# BEL, DEL and the C1 controls written \u0080 to \u009f) is byte 004, which a
# cell shows as ? (spec R8, its reach).
# shellcheck disable=SC2016
_PS_UNESC='BEGIN { c1 = sprintf("%c", 1); c2 = sprintf("%c", 2); c4 = sprintf("%c", 4); hx = "0123456789abcdef" }
  { gsub(/\\\\/, c2); gsub(/\\[nrt]/, c1); gsub(/\\[bf]/, c4); gsub(/\\\//, "/")
    while (match($0, /\\u[0123456789abcdefABCDEF][0123456789abcdefABCDEF][0123456789abcdefABCDEF][0123456789abcdefABCDEF]/)) {
      h = tolower(substr($0, RSTART + 2, 4)); r = c1
      if (substr(h, 1, 2) == "00") {
        v = (index(hx, substr(h, 3, 1)) - 1) * 16 + (index(hx, substr(h, 4, 1)) - 1)
        if (v == 34) r = "\\\""; else if (v == 92) r = c2; else if (v >= 32 && v < 127) r = sprintf("%c", v)
        else if ((v < 32 && v != 9 && v != 10 && v != 13) || v == 127 || (v >= 128 && v < 160)) r = c4 }
      $0 = substr($0, 1, RSTART - 1) r substr($0, RSTART + RLENGTH) }
    print }'

# One row per pull request, from the flattened list: number, title, head
# branch, head SHA, base, draft, cross-repository, author, labels (lower case,
# each preceded and followed by byte 003, which no label name holds, and a
# single 003 for none), mergeable, mergeStateStatus,
# updatedAt as an epoch, files listed, checks, failed, unfinished, and the names
# of the failed and of the unfinished ones. Tabs and carriage returns in a value
# are spaces. A check's result is its conclusion, else its state, else its
# status; SUCCESS, SKIPPED and NEUTRAL are green and FAILURE, CANCELLED,
# TIMED_OUT, ACTION_REQUIRED, STARTUP_FAILURE, STALE and ERROR failed, and
# anything else has not finished. The files table is number, path, deleted lines.
# shellcheck disable=SC2016
_PS_TABLES='function nz(s) { return s == "" ? "-" : s }
  BEGIN { pf = ENVIRON["PS_PF"]; ff = ENVIRON["PS_FF"]; bs = sprintf("%c", 92); c1 = sprintf("%c", 1); c2 = sprintf("%c", 2); sep = sprintf("%c", 3); c4 = sprintf("%c", 4) }
  function un(x, keep,   k, e) { e = ""; k = 0
    while ((k = index(x, c2)) > 0) x = substr(x, 1, k - 1) bs substr(x, k + 1)
    if (!keep) { gsub(c1, " ", x); gsub(c4, "?", x) }
    return x }
  { i = $1; p = $2; v = $3; gsub(/[\t\r]/, " ", v); v = un(v, p ~ /^files[.][0123456789]+[.]path$/)
    if (!(i in S)) { S[i] = 1; O[++n] = i }
    if (p == "number") NUM[i] = v
    else if (p == "title") TI[i] = v
    else if (p == "headRefName") HB[i] = v
    else if (p == "headRefOid") HO[i] = v
    else if (p == "baseRefName") BS[i] = v
    else if (p == "isDraft") DR[i] = v
    else if (p == "isCrossRepository") CR[i] = v
    else if (p == "author.login") AU[i] = v
    else if (p == "mergeable") MG[i] = v
    else if (p == "mergeStateStatus") MS[i] = v
    else if (p == "updatedAt") UP[i] = v
    else if (p ~ /^labels[.][0123456789]+[.]name$/) LB[i] = LB[i] (LB[i] == "" ? sep : "") tolower(v) sep
    else if (p ~ /^statusCheckRollup[.][0123456789]+[.]/) { split(p, k, "."); CK[i, k[2], k[3]] = v; if (k[2] + 1 > CN[i]) CN[i] = k[2] + 1 }
    else if (p ~ /^files[.][0123456789]+[.]/) { split(p, k, "."); if (k[3] == "path") FP[i, k[2]] = v; else if (k[3] == "deletions") FD[i, k[2]] = v
      if (k[2] + 1 > FC[i]) FC[i] = k[2] + 1 } }
  END {
    for (x = 1; x <= n; x++) { i = O[x]; if (NUM[i] !~ /^[0123456789]+$/) continue
      nfail = 0; npend = 0; failn = ""; pendn = ""
      for (c = 0; c < CN[i]; c++) {
        r = CK[i, c, "conclusion"]; if (r == "") r = CK[i, c, "state"]; if (r == "") r = CK[i, c, "status"]; r = toupper(r)
        nm = CK[i, c, "name"]; if (nm == "") nm = CK[i, c, "context"]; if (nm == "") nm = "check " c
        if (r ~ /^(FAILURE|CANCELLED|TIMED_OUT|ACTION_REQUIRED|STARTUP_FAILURE|STALE|ERROR)$/) { nfail++; failn = failn (failn == "" ? "" : ", ") nm " " r }
        else if (r !~ /^(SUCCESS|SKIPPED|NEUTRAL)$/) { npend++; pendn = pendn (pendn == "" ? "" : ", ") nm " " (r == "" ? "no result" : r) } }
      u = ep(UP[i])
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%s\n", NUM[i], nz(TI[i]), nz(HB[i]), nz(HO[i]), nz(BS[i]), nz(DR[i]), nz(CR[i]), \
        nz(AU[i]), (LB[i] == "" ? sep : LB[i]), nz(MG[i]), nz(MS[i]), u, FC[i] + 0, CN[i] + 0, nfail, npend, nz(failn), nz(pendn) > pf
      for (c = 0; c < FC[i]; c++) if ((i, c) in FP) printf "%s\t%s\t%d\n", NUM[i], FP[i, c], FD[i, c] + 0 > ff } }'

# gh's open pull requests of SLUG, asked from directory $1, into $3/prs (sorted
# by number) and $3/files. The state is _PS_GHST (read, none, truncated or
# unread), with the reason or the count in _PS_GHWHY; status 1 when unread.
_ps_gh_list() {   # DIR SLUG W
  local d="$1" slug="$2" w="$3" rc first n k
  : > "$w/prs"; : > "$w/files"; _PS_GHST=unread; _PS_GHN=0
  if [ "${_PS_NOGH:-0}" = 1 ]; then _PS_GHWHY="--no-gh: gh was not asked"; return 1; fi
  command -v gh >/dev/null 2>&1 || { _PS_GHWHY="gh not found"; return 1; }
  _ps_slug_ok "$slug" || slug=""
  _ps_ghc "$d" pr list ${slug:+-R "$slug"} --state open --limit 1000 \
    --json number,title,headRefName,headRefOid,baseRefName,isDraft,isCrossRepository,author,labels,mergeable,mergeStateStatus,statusCheckRollup,files,updatedAt \
    > "$w/gh.json" 2> "$w/gh.err"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    _PS_GHWHY="$(_ps_err1 "$w/gh.err")"; [ -n "$_PS_GHWHY" ] || _PS_GHWHY="gh pr list exited $rc with no output"
    return 1
  fi
  first="$(LC_ALL=C awk 'NF { print substr($0, 1, 1); exit }' "$w/gh.json" 2>/dev/null)"
  if [ "$first" != "[" ]; then _PS_GHWHY="gh pr list answered something that is not a list"; return 1; fi
  LC_ALL=C awk "$_PS_UNESC" "$w/gh.json" 2>/dev/null | LC_ALL=C awk "$_FI_JSON" 2>/dev/null \
    | PS_PF="$w/prs.u" PS_FF="$w/files" LC_ALL=C awk -F'\t' "$_FI_EPOCH"$'\n'"$_PS_TABLES" 2>/dev/null
  [ -e "$w/prs.u" ] || : > "$w/prs.u"
  LC_ALL=C sort -t "$(printf '\t')" -k1,1n "$w/prs.u" > "$w/prs" 2>/dev/null
  n="$(LC_ALL=C awk 'END { print NR }' "$w/prs")"
  _PS_GHN="$n"
  # An empty array flattens to nothing, so a list that left out the checks or the
  # files could not be told from one whose pull requests have none: unread.
  if [ "$n" -gt 0 ]; then
    for k in statusCheckRollup files; do
      [ "$(LC_ALL=C grep -c "\"$k\"" "$w/gh.json" 2>/dev/null)" -gt 0 ] && continue
      : > "$w/prs"; : > "$w/files"; _PS_GHN=0
      _PS_GHWHY="gh pr list left out $k"; return 1
    done
  fi
  if [ "$n" -eq 0 ]; then
    # Only an empty list is "none": a list whose objects held no number is unread.
    if [ "$(LC_ALL=C tr -d ' \t\r\n' < "$w/gh.json" 2>/dev/null)" != "[]" ]; then
      _PS_GHWHY="gh pr list answered a list with no pull request numbers in it"; return 1
    fi
    _PS_GHST=none; _PS_GHWHY="no open pull requests"
  elif [ "$n" -ge 1000 ]; then _PS_GHST=truncated; _PS_GHWHY="$n listed, gh's limit: the list may be incomplete"
  else _PS_GHST=read; _PS_GHWHY="$n open pull requests"; fi
  return 0
}

# The Actions items of one month of GitHub's usage report, summed (spec 4.4 as
# amended by R13). The report is {"usageItems":[{...}, ...]}: an item counts when
# its product is actions and its date starts with the month in PS_YM; minutes are
# the quantity of the counted items whose unit is Minutes, and net is netAmount
# over all of them, storage included. Prints one line: ok, the minutes, the net
# and how many Actions items were dated outside the month; or bad and why. An
# answer that ends early, or that has text after its object closes, is not a
# report (A2): only whole items could be summed, and the row would state a sum
# that is short. The flattener the pull request list uses (_FI_JSON) drops
# whether a value was quoted, and a quantity has to be a number, so this walks
# the text itself, a character at a time and never through substr, whose cost
# in one awk grows with the whole text at every call (A8).
# shellcheck disable=SC2016
_PS_USAGE='function num(x) { return x ~ /^-?[0123456789]+([.][0123456789]+)?([eE][-+]?[0123456789]+)?$/ }
  function item() {
    if (Q["product"] != 1 || tolower(V["product"]) != "actions") return
    if (Q["date"] != 1) { nodate = 1; return }
    if (index(V["date"], ym) != 1) { outside++; return }
    if (!("netAmount" in V) || Q["netAmount"] != 0 || !num(V["netAmount"])) { notnum = 1; return }
    net += V["netAmount"]
    if (Q["unitType"] == 1 && tolower(V["unitType"]) == "minutes") {
      if (!("quantity" in V) || Q["quantity"] != 0 || !num(V["quantity"])) { notnum = 1; return }
      mins += V["quantity"] } }
  { m = split($0, L, ""); for (k = 1; k <= m; k++) C[++n] = L[k]; C[++n] = "\n" }
  END { d = 0; key = 0; ym = ENVIRON["PS_YM"] "-"
    for (i = 1; i <= n; i++) { c = C[i]
      if (index(" \n\t\r", c)) continue
      if (shut) { broken = 1; break }
      if (c == "{" || c == "[") { if (d == 0 && c == "[") { broken = 1; break }
        d++; T[d] = c; K[d] = ""; key = (c == "{")
        if (d == 2 && c == "[" && K[1] == "usageItems") { list = 1; seen = 1 }
        if (d == 3 && c == "{" && list) { split("", V); split("", Q) }
        continue }
      if (c == "}" || c == "]") { if (d < 1 || T[d] != (c == "}" ? "{" : "[")) { broken = 1; break }
        if (d == 3 && list) item(); if (d == 2) list = 0; d--; key = 0; if (d == 0) shut = 1; continue }
      if (d == 0) { broken = 1; break }
      if (c == ",") { key = (T[d] == "{"); continue }
      if (c == ":") { key = 0; continue }
      v = ""
      if (c == "\"") { for (j = i + 1; j <= n && C[j] != "\""; j++) { if (C[j] == "\\") { v = v C[j]; j++ } v = v C[j] }
        if (j > n) { broken = 1; break } i = j; q = 1 }
      else { for (j = i; j <= n && !index(",}] \n\t\r", C[j]); j++) v = v C[j]; i = j - 1; q = 0 }
      if (key) { K[d] = v; continue }
      if (d == 3 && list && T[3] == "{") { V[K[3]] = v; Q[K[3]] = q } }
    if (broken || !shut) { print "bad\tthe usage report is not complete JSON"; exit }
    if (!seen) { print "bad\tthe usage report holds no usageItems list"; exit }
    if (nodate) { print "bad\tthe usage report holds an Actions item with no date"; exit }
    if (notnum) { print "bad\tthe usage report holds an Actions item whose quantity or netAmount is not a number"; exit }
    a = sprintf("%.0f", mins); if (a == "-0") a = "0"
    b = sprintf("%.2f", net); if (b == "-0.00") b = "0.00"
    printf "ok\t%s\t%s\t%d\n", a, b, outside }'

# The scope gh says the token lacks, from the error output of a failed GET: gh
# adds a line of its own, This API operation needs the "<scope>" scope, when
# GitHub's headers say so. The first such name in the file, when it is letters,
# digits, colons, underscores and hyphens; else nothing.
_ps_budget_scope() {   # FILE
  [ -f "$1" ] || return 0
  LC_ALL=C awk 'BEGIN { p = "This API operation needs the \"" }
    { i = index($0, p); if (!i) next
      s = substr($0, i + length(p)); j = index(s, "\" scope"); if (!j) next
      s = substr(s, 1, j - 1)
      if (s != "" && s !~ /[^ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789:_-]/) { printf "%s", s; exit } }' "$1" 2>/dev/null
}

# The account's Actions usage this month (spec 4.4 as amended by R13): one gh api
# GET of GitHub's usage report, users/<owner>/settings/billing/usage for the
# clock's year and month in UTC, and of orgs/<owner>/... only when that answers
# 404 (an organisation has no users/ report). States budget as _PS_BST and
# _PS_BWHY: the minutes used and the net amount, and no quota, because the report
# holds none. Until 2026-11 this asked settings/billing/actions, which GitHub
# retired (HTTP 410), and blamed every 404 on the token's scope; a failure now
# says what gh said, and names a scope only when gh named it.
_ps_budget() {   # OWNER DIR
  local o="$1" d="$2" w="$_PS_T/budget" ym q e1="" e2="" last="" s1 s2 st a b c
  _PS_BST=unread
  if [ "${_PS_NOGH:-0}" = 1 ]; then _PS_BWHY="--no-gh: gh was not asked"; return 1; fi
  command -v gh >/dev/null 2>&1 || { _PS_BWHY="gh not found"; return 1; }
  [ -n "$o" ] || { _PS_BWHY="the repository names no owner"; return 1; }
  # The owner goes into the address, so it has to be an account name (A6).
  case "$o" in *[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-]*) _PS_BWHY="the owner in the slug is not an account name"; return 1 ;; esac
  ym="$(LC_ALL=C date -u +%Y-%m 2>/dev/null)"
  case "$ym" in
    [0123456789][0123456789][0123456789][0123456789]-[0123456789][0123456789]) ;;
    *) _PS_BWHY="the clock gave no year and month"; return 1 ;;
  esac
  q="${ym#*-}"; q="settings/billing/usage?year=${ym%-*}&month=${q#0}"
  if ! _ps_ghc "$d" api "users/$o/$q" > "$w.json" 2> "$w.err"; then
    e1="$(_ps_err1 "$w.err")"; [ -n "$e1" ] || e1="gh api exited with no output"
    # What a line says is read from the whole line, and shown cut (A5).
    last="$(LC_ALL=C sed -n 1p "$w.err" 2>/dev/null)"
    # Only a 404 asks the organisation's report, and nothing asks a third.
    case "$last" in *"HTTP 404"*|*"Not Found"*)
      if _ps_ghc "$d" api "orgs/$o/$q" > "$w.json" 2> "$w.err2"; then e1=""
      else e2="$(_ps_err1 "$w.err2")"; [ -n "$e2" ] || e2="gh api exited with no output"; last="$(LC_ALL=C sed -n 1p "$w.err2" 2>/dev/null)"; fi ;;
    esac
  fi
  if [ -n "$e1" ]; then
    _PS_BWHY="$e1"
    [ -z "$e2" ] || [ "$e2" = "$e1" ] || _PS_BWHY="$_PS_BWHY; organisation report: $e2"
    s1="$(_ps_budget_scope "$w.err")"; s2="$(_ps_budget_scope "$w.err2")"
    [ "$s2" != "$s1" ] || s2=""
    [ -n "$s1" ] || { s1="$s2"; s2=""; }
    if [ -n "$s1" ]; then _PS_BWHY="$_PS_BWHY; gh names a scope the token lacks ($s1${s2:+, $s2}), and widening the token is the founder's"
    else case "$last" in
      *"HTTP 410"*) _PS_BWHY="$_PS_BWHY; GitHub has moved this endpoint, so the fix is to Felix's reader and no token scope brings it back" ;;
      *"HTTP 404"*|*"Not Found"*) _PS_BWHY="$_PS_BWHY; GitHub answers 404 for an account that does not exist and for one whose billing this login may not read" ;;
    esac; fi
    return 1
  fi
  PS_YM="$ym" LC_ALL=C awk "$_PS_USAGE" "$w.json" > "$w.sum" 2>/dev/null
  st=""; a=""; b=""; c=""
  IFS=$'\t' read -r st a b c < "$w.sum" || :
  case "$st" in
    ok) ;;
    bad) _PS_BWHY="$a"; return 1 ;;
    *) _PS_BWHY="the usage report could not be read"; return 1 ;;
  esac
  # A sum awk could not print as a number (a quantity past what a double holds) is no sum.
  case "${a#-}|${b#-}" in "|"*|*"|"|*[!0123456789.\|]*|*.*"|"*) _PS_BWHY="the usage report's Actions sums could not be stated"; return 1 ;; esac
  _PS_BST=read; _PS_BWHY="$a Actions minutes used in $ym, net \$$b"
  case "$c" in ""|0|*[!0123456789]*) ;; *) _PS_BWHY="$_PS_BWHY; Actions items dated outside $ym, not counted: $c" ;; esac
  return 0
}

# The repository's default branch from GitHub, for a project whose checkout is
# not at hand (the queue): one gh api GET. Prints it, or nothing.
_ps_gh_default() {   # SLUG DIR
  _ps_ghc "$2" api "repos/$1" 2>/dev/null \
    | LC_ALL=C sed -n 's/.*"default_branch"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | LC_ALL=C sed -n 1p
}

# The signed-in GitHub account, for a repository an organisation owns: a member's
# pull request is the member's to land, and the owner's name is the organisation's
# (audit C027). One gh api GET, `api user`, whose whole answer is read for its
# first "login" whatever the caller's --jq would have done, asked at most once
# per run (the queue reads many repositories) and only when a pull request needs
# it: _ps_gh_me_if. A login is 1 to 39 characters of letters, digits and
# hyphens; anything else is not a login. States _PS_MEST read or unread, with
# _PS_ME the login and _PS_MEWHY the reason when unread.
_ps_gh_me() {   # DIR
  local d="$1" rc login w="$_PS_T/me"
  [ -z "${_PS_MEST:-}" ] || return 0
  _PS_ME=""; _PS_MEST=unread
  _ps_ghc "$d" api user > "$w.json" 2> "$w.err"; rc=$?
  if [ "$rc" -ne 0 ]; then
    _PS_MEWHY="$(_ps_err1 "$w.err")"; [ -n "$_PS_MEWHY" ] || _PS_MEWHY="gh api user exited $rc with no output"
    return 1
  fi
  login="$(LC_ALL=C awk '{ if (match($0, /"login"[ \t]*:[ \t]*"[^"]*"/)) { s = substr($0, RSTART, RLENGTH)
      sub(/^"login"[ \t]*:[ \t]*"/, "", s); sub(/"$/, "", s); print s; exit } }' "$w.json" 2>/dev/null)"
  case "$login" in
    "") _PS_MEWHY="the answer of gh api user holds no login"; return 1 ;;
    *[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-]*) _PS_MEWHY="the answer of gh api user holds a login that is not one"; return 1 ;;
  esac
  if [ "${#login}" -gt 39 ]; then _PS_MEWHY="the answer of gh api user holds a login that is not one"; return 1; fi
  _PS_ME="$login"; _PS_MEST=read; _PS_MEWHY=""
  return 0
}

# Asked only when the list holds a pull request that is not cross-repository and
# whose author is not the owner (without regard to case), and never when the
# repository's owner is not known.
_ps_gh_me_if() {   # W OWNER DIR
  [ -n "$2" ] && [ -f "$1/prs" ] || return 0
  LC_ALL=C awk -F'\t' -v o="$2" '$7 != "true" && tolower($8) != tolower(o) { f = 1 } END { exit !f }' "$1/prs" 2>/dev/null || return 0
  _ps_gh_me "$3"
  return 0
}
