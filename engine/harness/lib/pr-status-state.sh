# The stuck-PR page, deciding half: the rules a changed path can be judged by
# without a checkout, and the one state each pull request is in (spec v2, 4).
#
# The page reads many pull requests and checks none out, so it applies only the
# parts of the escape rules that a path and gh's per-file counts can decide.
# Content rules (the secret scan, destructive SQL in added lines, a risk.tsv
# `count:` or content confine) are not evaluated here, and every founder row
# decided by a path says path-level. Nothing here writes outside the page's
# scratch directory, and nothing runs git beyond reads.
#
# Bash 3.2. LC_ALL=C on every text tool; digit brackets spelled out; every
# [[ =~ ]] sits in a function that declares local LC_ALL=C.

# A project file as refs/remotes/origin/main of the repository holding the
# project has it (never the tree, never a local branch). 0 and the text; 1 when
# that repository has no origin/main; 2 when it has no such file.
_ps_blob() {   # PROJDIR NAME
  local pd repo rel
  [ -n "$1" ] || return 1
  pd="$(CDPATH='' cd -- "$1" >/dev/null 2>&1 && pwd -P)" || return 1
  repo="$(git -C "$pd" rev-parse --show-toplevel 2>/dev/null)" || return 1
  case "$pd" in "$repo"/*) rel="${pd#"$repo"/}/$2" ;; *) return 1 ;; esac
  git -C "$repo" rev-parse --verify --quiet "$_GT_MAIN^{commit}" >/dev/null 2>&1 || return 1
  git -C "$repo" cat-file -e "$_GT_MAIN:$rel" >/dev/null 2>&1 || return 2
  git -C "$repo" cat-file blob "$_GT_MAIN:$rel" 2>/dev/null
}

# The land table, as the page reads it: _PS_LAND is read, none or unread, with
# _PS_LANDWHY, and the founder rows' path patterns are in $3/landpat. A
# governed repository with no origin/main reads no table (spec 5); a table
# felix_land_malformed refuses is unread too, because every path in it goes to a
# session.
_ps_land() {   # PROJDIR GOVERNED-DIR-OR-EMPTY W
  local pd="$1" gd="$2" w="$3" bad rc n
  : > "$w/landpat"
  if [ -n "$gd" ] && ! git -C "$gd" rev-parse --verify --quiet "$_GT_MAIN^{commit}" >/dev/null 2>&1; then
    _PS_LAND=unread; _PS_LANDWHY="no origin/main in the governed repository"; return 0
  fi
  _ps_blob "$pd" land.tsv >/dev/null; rc=$?
  case "$rc" in
    1) _PS_LAND=unread; _PS_LANDWHY="no origin/main in the repository holding the project"; return 0 ;;
    2) _PS_LAND=none; _PS_LANDWHY="no land table at origin/main"; return 0 ;;
  esac
  bad="$(felix_land_malformed "$pd" 2>/dev/null)" && rc=0 || rc=$?
  if [ "$rc" -ne 0 ]; then
    _PS_LAND=unread
    _PS_LANDWHY="felix_land_malformed refuses the table: $(printf '%s\n' "$bad" | LC_ALL=C sed -n 1p | LC_ALL=C tr '\t' ':' | LC_ALL=C tr -d '\r')"
    return 0
  fi
  felix_land_rows "$pd" 2>/dev/null | LC_ALL=C awk -F'\t' '$2 == "founder" { print $1 }' > "$w/landpat"
  n="$(LC_ALL=C awk 'END { print NR }' "$w/landpat")"
  _PS_LAND=read; _PS_LANDWHY="$n founder rows at origin/main"
}

# The tick's ledger: the last row of each pull request, as number, event, head
# and detail. A `waiting` row (lib/green-wait.sh) is a statement about a wait
# and not a row of it, so it is passed over: a pull request's state and detail
# are what they would be without it. absent is none; a regular readable file is
# read; anything else (a directory, no permission) is unread.
_ps_ledger() {   # LEDGER W
  local l="$1" w="$2" anc nx
  : > "$w/ledger"
  # A ledger is absent only when the directories above it can be searched: stat
  # fails the same way for a file that is not there and for one behind a
  # directory the reader may not enter, and the second is unread, never none.
  anc="${l%/*}"
  while [ -n "$anc" ] && [ "$anc" != "$l" ]; do
    if [ -d "$anc" ] && [ ! -x "$anc" ]; then
      _PS_LEDGER=unread; _PS_LEDGERWHY="the directory $anc cannot be searched"; return 0
    fi
    [ ! -e "$anc" ] || break
    nx="${anc%/*}"; [ "$nx" != "$anc" ] || break
    anc="$nx"
  done
  if [ ! -e "$l" ] && [ ! -L "$l" ]; then _PS_LEDGER=none; _PS_LEDGERWHY="the tick has not written one"; return 0; fi
  if [ ! -f "$l" ] || [ ! -r "$l" ]; then _PS_LEDGER=unread; _PS_LEDGERWHY="not a readable regular file"; return 0; fi
  if ! LC_ALL=C awk -F'\t' 'NF >= 7 && $3 != "-" && $2 != "waiting" { gsub(/\r/, " ", $7); last[$3] = $2 "\t" $4 "\t" $7 }
         END { for (k in last) print k "\t" last[k] }' "$l" > "$w/ledger" 2>/dev/null; then
    _PS_LEDGER=unread; _PS_LEDGERWHY="the ledger could not be read"; return 0
  fi
  _PS_LEDGER=read; _PS_LEDGERWHY="$(LC_ALL=C awk 'END { print NR }' "$l") rows"
}

# What each changed path is, by the rules a path can decide, as path<TAB>tag
# lines in $1/pathattr. Tags: exemption, verifierlisted (listed in the escape
# tables, not in the exemption subset; the page fires it only on a deleted
# line), commission, execute, authority, exception, durable, direction,
# trustbase, land and risk. A risk row with a content confine, which the page
# does not evaluate, goes to $1/confrows instead: row number, pattern, path. A
# byte outside printable ASCII is read by the deciding awk, which has the file's
# text.
_ps_pathattr() {   # W
  local w="$1" p b rest e c tab ri LC_ALL=C
  tab="$(printf '\t')"
  : > "$w/pathattr"; : > "$w/confrows"
  LC_ALL=C cut -f2 "$w/files" | LC_ALL=C sort -u > "$w/paths"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    if _felix_escape_listed "$p" "$FELIX_ESCAPE_EXEMPTION_TABLES"; then printf '%s\texemption\n' "$p"
    elif _felix_escape_listed "$p" "$FELIX_ESCAPE_TABLES"; then printf '%s\tverifierlisted\n' "$p"; fi
    b="${p##*/}"
    case "$p" in projects/*/*) rest="${p#projects/}"
      case "$rest" in */*/*) ;; */*) case " $FELIX_COMMISSION_TABLES " in *" $b "*) printf '%s\tcommission\n' "$p" ;; esac ;; esac ;; esac
    [[ $p =~ $FELIX_ESCAPE_EXECUTE ]] && printf '%s\texecute\n' "$p"
    [[ $p =~ $FELIX_ESCAPE_AUTHORITY ]] && printf '%s\tauthority\n' "$p"
    [[ $p =~ $FELIX_ESCAPE_EXCEPTION ]] && printf '%s\texception\n' "$p"
    [[ $p =~ $FELIX_ESCAPE_DURABLE_PATH ]] && printf '%s\tdurable\n' "$p"
    _gt_direction "$p" >/dev/null && printf '%s\tdirection\n' "$p"
    felix_land_trust_base "$p" && printf '%s\ttrustbase\n' "$p"
  done < "$w/paths" > "$w/pathattr"
  # The land table's founder rows are ERE patterns, matched unanchored as the
  # table's own scan matches them.
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    LC_ALL=C grep -E -- "$e" "$w/paths" 2>/dev/null | LC_ALL=C awk '{ print $0 "\tland" }' >> "$w/pathattr"
  done < "$w/landpat"
  # risk.tsv's path rows that name a channel: tier, kind, pattern, reason,
  # channel, confine. Read with awk, because read would fold empty cells.
  _ps_blob "$_PS_PROJDIR" risk.tsv 2>/dev/null \
    | LC_ALL=C awk -F'\t' '/^[[:space:]]*(#|$)/ { next } $2 == "path" && $5 != "" && $5 != "-" { print (($6 != "" && $6 != "-") ? "c" : "e") "\t" $3 }' > "$w/riskpat"
  ri=0
  while IFS="$tab" read -r c e; do
    [ -n "$e" ] || continue
    if [ "$c" = c ]; then
      # A confined row is not evaluated: row number, pattern, path, so the page
      # lists the row once with how many paths it matched (R10).
      ri=$(( ri + 1 ))
      LC_ALL=C grep -E -- "$e" "$w/paths" 2>/dev/null | PS_E="$e" PS_RI="$ri" LC_ALL=C awk '{ print ENVIRON["PS_RI"] "\t" ENVIRON["PS_E"] "\t" $0 }' >> "$w/confrows"
    else
      LC_ALL=C grep -E -- "$e" "$w/paths" 2>/dev/null | LC_ALL=C awk '{ print $0 "\trisk" }' >> "$w/pathattr"
    fi
  done < "$w/riskpat"
  return 0
}

# One row per pull request from $W/prs, $W/files, $W/pathattr and $W/ledger, in
# ascending number: number, state, flags, needs, detail, title, age_h, head. The
# state is the first of spec 4 that holds, and the detail lists every condition
# that holds. The environment carries the account (PS_OWNER), the default branch
# (PS_DEF, empty when unread), origin/main (PS_MAIN, empty when absent), the
# reading of the land table and of the ledger, and the clock. PS_ME is the
# signed-in GitHub account, empty when it was not read, with PS_MEWHY saying why
# (PS_MEST is read or unread, and empty when the run did not need it): a member's
# own pull request on an organisation's repository is the member's to land, so
# the owner and the signed-in account are both the governed account.
# shellcheck disable=SC2016
_PS_DECIDE='function add(s) { D[++nd] = s }
  function tag(p, t) { return index(" " TG[p], " " t " ") > 0 }
  BEGIN {
    SEP = sprintf("%c", 3); CTL = sprintf("%c", 1)
    FS = "\t"; W = ENVIRON["PS_W"]; owner = ENVIRON["PS_OWNER"]; lo = tolower(owner)
    def = ENVIRON["PS_DEF"]; main = ENVIRON["PS_MAIN"]; land = ENVIRON["PS_LAND"]; landwhy = ENVIRON["PS_LANDWHY"]
    ledg = ENVIRON["PS_LEDGER"]; now = ENVIRON["PS_NOW"] + 0
    me = ENVIRON["PS_ME"]; mest = ENVIRON["PS_MEST"]; mewhy = ENVIRON["PS_MEWHY"]; lme = tolower(me)
    while ((getline ln < (W "/pathattr")) > 0) { split(ln, a, "\t"); TG[a[1]] = TG[a[1]] a[2] " " }
    while ((getline ln < (W "/confrows")) > 0) { split(ln, a, "\t"); CRP[a[1]] = a[2]; CRS[a[1], a[3]] = 1; if (a[1] + 0 > ncr) ncr = a[1] + 0 }
    while ((getline ln < (W "/files")) > 0) { split(ln, a, "\t"); k = ++FN[a[1]]; FPATH[a[1], k] = a[2]; FDEL[a[1], k] = a[3] + 0 }
    while ((getline ln < (W "/ledger")) > 0) { split(ln, a, "\t"); LE[a[1]] = a[2]; LH[a[1]] = a[3]; LD[a[1]] = a[4]; HL[a[1]] = 1 }
    while ((getline ln < (W "/prs")) > 0) { split(ln, a, "\t"); np++; R[np] = ln; if (a[3] != "-") BR[a[3]] = BR[a[3]] " " a[1] }
    for (x = 1; x <= np; x++) {
      split(R[x], f, "\t")
      n = f[1]; title = f[2]; br = f[3]; oid = f[4]; base = f[5]; draft = (f[6] == "true"); cross = (f[7] == "true"); au = f[8]; lab = f[9]
      mg = f[10]; ms = f[11]; upd = f[12]; nf = f[13] + 0; nc = f[14] + 0; nfail = f[15] + 0; npend = f[16] + 0; failn = f[17]; pendn = f[18]
      nd = 0
      fl = ""; if (draft) fl = fl ",draft"; if (ms == "BEHIND") fl = fl ",behind"; if (mg == "UNKNOWN" || mg == "-") fl = fl ",mergeable-unknown"
      ownunk = (lo == ""); isown = (!ownunk && tolower(au) == lo); isme = (me != "" && tolower(au) == lme)
      meunk = (!cross && !ownunk && !isown && !isme && mest != "read")
      outside = (cross || (!ownunk && !isown && !isme && !meunk))
      defunk = (def == ""); stacked = (!defunk && base != def)
      held = (index(lab, SEP "felix:hold" SEP) > 0); conf = (mg == "CONFLICTING")
      green = (nc > 0 && nfail == 0 && npend == 0)
      dups = ""; m = split(BR[br], o, " "); for (j = 1; j <= m; j++) if (o[j] != n) dups = dups (dups == "" ? "" : " ") o[j]
      if (cross) add("the head is in a fork")
      if (ownunk && !cross) add("governed account not read: origin names no owner/name slug")
      else if (cross && !ownunk && !isown) add("author " au " is not the governed account " owner)
      else if (outside) add("author " au " is neither the repository owner " owner " nor the signed-in account " me)
      else if (meunk) add("author " au " is not the repository owner " owner ", and the signed-in GitHub account was not read: " (mewhy == "" ? "gh was not asked" : mewhy))
      if (stacked) add("base is " base ", not the default branch " def ": it waits on its base")
      if (defunk && !outside) add("default branch not read")
      if (held) add("labelled felix:hold")
      if (conf) add("mergeable is CONFLICTING: it conflicts with its base")
      if (mg == "UNKNOWN" || mg == "-") add("mergeability not computed yet")
      if (ms == "BEHIND") add("behind its base: the author merges main in")
      if (nfail > 0) add("failed: " failn)
      if (npend > 0) add("not finished: " pendn)
      if (nc == 0) add("no checks ran on the head")
      if (draft) add("a draft: the tick merges no draft")
      m = split(dups, o, " "); for (j = 1; j <= m; j++) add("head branch " br " is also #" o[j] "\047s")
      founder = 0; tb = 0; unk = 0; refusedhere = 0
      if (green) {
        labf = (index(lab, SEP "needs-founder" SEP) > 0 || index(lab, SEP "felix:founder" SEP) > 0)
        filesok = (nf < 100)
        items = ""; fc = 0; tbp = ""; hrl = ""
        split("", CC); split("", CF)
        if (filesok) for (k = 1; k <= FN[n]; k++) {
          p = FPATH[n, k]; d = FDEL[n, k]; rl = ""
          if (tag(p, "commission")) rl = rl "commission "
          if (tag(p, "exemption")) rl = rl "exemption "
          if (tag(p, "verifierlisted") && d > 0) rl = rl "verifier "
          if (tag(p, "execute")) rl = rl "execute "
          if (tag(p, "authority")) rl = rl "authority "
          if (tag(p, "exception")) rl = rl "exception "
          if (tag(p, "durable")) rl = rl "durable "
          if (tag(p, "risk")) rl = rl "risk "
          if (land == "read" && tag(p, "land")) rl = rl "land "
          if (tag(p, "direction")) rl = rl "direction "
          if (p ~ /[^ -~]/) rl = rl "path-bytes "
          for (q = 1; q <= ncr; q++) if ((q, p) in CRS) { CC[q]++; if (CC[q] == 1) CF[q] = p }
          if (rl != "") { sub(/ $/, "", rl); fc++
            if (fc <= 5) { r2 = rl; gsub(/ /, ", ", r2); items = items (items == "" ? "" : "; ") p " (" r2 ")" }
            else { m2 = split(rl, rw, " "); for (q = 1; q <= m2; q++) if (!((n, rw[q]) in HR)) { HR[n, rw[q]] = 1; hrl = hrl (hrl == "" ? "" : ", ") rw[q] } } }
          if (tag(p, "trustbase")) tbp = tbp (tbp == "" ? "" : ", ") p }
        for (q = 1; q <= ncr; q++) if (CC[q] > 0) add("risk row not evaluated: content confine, " CRP[q] ", for " CC[q] (CC[q] == 1 ? " path: " : " paths: ") CF[q])
        if (fc > 5) items = items "; and " (fc - 5) " more: " hrl
        founder = (labf || fc > 0)
        l1 = (index(lab, SEP "needs-founder" SEP) > 0); l2 = (index(lab, SEP "felix:founder" SEP) > 0)
        if (l1 && l2) add("labels needs-founder and felix:founder put it in the founder queue")
        else if (labf) add("label " (l1 ? "needs-founder" : "felix:founder") " puts it in the founder queue")
        if (fc > 0) add("founder paths, path-level: " items)
        if (tbp != "") { tb = 1; add("touches the trust base: " tbp) }
        if (!filesok) { add("files not read: GitHub lists at most 100"); if (!founder) unk = 1 }
        if (land == "unread") { add("land table not read: " landwhy); if (!founder) unk = 1 }
        if (HL[n]) {
          ev = LE[n]; lh = LH[n]; ld = LD[n]
          if (lh == oid) {
            if (ev == "refused") {
              ms2 = ""; body = ld
              if (match(ld, / \[main [0123456789abcdef]+\]$/)) { ms2 = substr(ld, RSTART + 7, RLENGTH - 8); body = substr(ld, 1, RSTART - 1) }
              if (main != "" && ms2 == main) { if (!founder) refusedhere = 1; add("the lander was refused: " body) }
              else add("the lander last saw " substr(lh, 1, 7) ": refused")
            } else if (ev == "session") { if (!founder) refusedhere = 1; add("the lander cannot use it: " ld) }
            else add("the lander: " ev ": " ld)
          } else add("the lander last saw " substr(lh, 1, 7) ": " ev)
        }
        if (ledg == "unread") { add("the lander\047s ledger not read"); if (!founder && !unk) unk = 2 }
      }
      if (outside) { st = "outside"; nd2 = "nobody" }
      else if (defunk || ownunk || meunk) { st = "unknown"; nd2 = "unknown" }
      else if (stacked) { st = "stacked"; nd2 = "nobody" }
      else if (held) { st = "held"; nd2 = "session" }
      else if (conf) { st = "needs-session"; nd2 = "session" }
      else if (nfail > 0) { st = "red"; nd2 = "session" }
      else if (npend > 0) { st = "pending"; nd2 = "nobody" }
      else if (!green) { st = "unready"; nd2 = "session" }
      else if (founder) { st = "founder"; nd2 = "founder" }
      else if (unk == 1) { st = "unknown"; nd2 = "unknown" }
      else if (unk == 2) { st = "unknown"; nd2 = "unknown" }
      else if (refusedhere) { st = "refused"; nd2 = "session" }
      else if (!draft && dups == "") { st = "ready"; nd2 = "lander"; add("the checks are green and nothing holds it back") }
      else { st = "unready"; nd2 = "session" }
      dt = ""; for (j = 1; j <= nd; j++) dt = dt (j > 1 ? "; " : "") D[j]
      gsub(/[\t\r\n]/, " ", dt); gsub(CTL, "?", dt)
      age = "-"; if (upd ~ /^[0123456789]+$/) { age = int((now - upd) / 3600); if (age < 0) age = 0 }
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", n, st, fl, nd2, dt, title, age, oid
    } }'

_ps_decide() {   # W OWNER DEFAULT-BRANCH MAIN
  PS_ME="${_PS_ME:-}" PS_MEST="${_PS_MEST:-}" PS_MEWHY="${_PS_MEWHY:-}" \
    PS_W="$1" PS_OWNER="$2" PS_DEF="$3" PS_MAIN="$4" PS_LAND="$_PS_LAND" PS_LANDWHY="$_PS_LANDWHY" PS_LEDGER="$_PS_LEDGER" PS_NOW="$(date +%s)" \
    LC_ALL=C awk "$_PS_DECIDE" > "$1/rows" 2>/dev/null
}
