# felix audit's awk program, second half: what counts. Which edits a stop
# answers for, which checks came after them, which stops and holds are counted
# and for which session, and the one line of totals the report is read from.
# lib/audit-read.sh holds the first half; felix_audit_scan in lib/audit.sh
# hands awk the two as one program. Split from lib/audit.sh on 2026-09-22; the
# program text is unchanged.
# shellcheck disable=SC2016
_FELIX_AUDIT_COUNT='
  function writes(u,    x, n, P, O, S, i, p, q, v, m, R, j, w, ch, k, G, D, gp, B, bp, g) {
    x = u; gsub(/&>/, " >", x); gsub(/[<>]&/, "  ", x); gsub(/>[|]/, "> ", x)
    gsub(/[;&|()]/, "&\002", x); n = split(x, P, "\002"); WDIR = CWD; gp = 0; bp = 0
    for (i = 1; i <= n; i++) {
      if (i == 1) O[i] = S[i] = 1
      else {
        O[i] = O[i - 1] + length(P[i - 1]); g = 0
        if (P[i - 1] ~ /[(]$/) { G[++gp] = S[i - 1]; D[gp] = WDIR }
        else if (P[i - 1] ~ /[)]$/ && gp) { g = G[gp]; WDIR = D[gp--] }
        S[i] = (P[i - 1] ~ /[|]$/ && !(P[i - 1] == "|" && i > 2 && P[i - 2] ~ /[|]$/)) ? S[i - 1] : g ? g : O[i]
      }
      p = P[i]; sub(/[;&|()]$/, "", p); k = 0
      if (bp && p ~ /^[ ]*([}]|fi|done|esac)([ <>]|$)/) S[i] = B[bp--]
      else if (match(p, /^[ ]*((if|then|else|elif|do|while|until|for|select|case|!|[{])( +|$))+/)) {
        m = split(substr(p, 1, RLENGTH), R, " ")
        for (j = 1; j <= m; j++) if (R[j] ~ /^(if|while|until|for|select|case|[{])$/) B[++bp] = S[i]
      }
      q = p; if (match(q, LEAD)) q = substr(q, RLENGTH + 1)
      v = q; sub(/^[^ =]*\//, "", v)
      if (v ~ /^cd( |$)/) { m = split(q, R, " "); WDIR = m < 2 ? "?" : wdir(R[2]); continue }
      if (index(p, ">") && !(i > 1 && P[i - 1] == "(")) {
        m = split(p, R, ">")
        for (j = 2; j <= m; j++) {
          ch = substr(R[j - 1], length(R[j - 1]))
          if (R[j] == "" || ch == BS || ch == "\001") continue
          w = R[j]; sub(/^ +/, "", w); sub(/[ <].*$/, "", w); k = wclass(w, k, 0)
        }
      }
      if (v ~ /^sed / && q ~ / (-[nrEsuz]*i|--in-place)[^ ]*( |$)/) { m = split(q, R, " "); k = wclass(R[m], k, 1) }
      else if (v ~ /^perl / && q ~ / -[acnpsTtuUvWwXl0-9]*i[^ ]*( |$)/) { m = split(q, R, " "); k = wclass(R[m], k, 1) }
      else if (v ~ /^patch( |$)/ && q !~ / --dry-run( |$)/) k = wclass(".", k, 1)
      else if (q ~ GITAP && q !~ / --(check|stat|numstat|summary|cached)( |$)/) k = wclass(".", k, 1)
      else if (v ~ /^tee( |$)/) { m = split(q, R, " "); for (j = 2; j <= m; j++) if (R[j] !~ /^-/) k = wclass(R[j], k, 0) }
      if (k == 1) { WR = 1; WRAT = S[i] } else if (k == 2 && !WR) WR = 2
    }
  }

  # Where a write lands, for writes(): 1 where it counts, 2 where it is
  # scratch or Claude or Felix own, k unchanged where it is no named file.
  # A writer by nature (nat: sed -i, perl -i, patch, git apply) writes a file
  # whether or not its name can be read, so a name it cannot read counts.
  # A named path is a word of the characters paths are made of, so a quote,
  # a $, a backquote or prose kept from a double-quoted $( ) is none.
  function wclass(w, k, nat,    p) {
    if (w !~ /^[A-Za-z0-9_.\/~+@%,:-]+$/ || w ~ /^-/ || w ~ /^[0-9]+$/ || w ~ /^\/dev\//) return nat ? 1 : k
    if (substr(w, 1, 2) == "~/") { if (HOMED == "") return nat ? 1 : k; p = HOMED substr(w, 2) }
    else if (substr(w, 1, 1) == "/") p = w
    else if (WDIR == "?") return nat ? 1 : k
    else if (WDIR != "") p = WDIR "/" w
    else return 1
    return aside_path(p) ? (k == 1 ? 1 : 2) : 1
  }
  # Where a cd in the command goes: ? where it names no place.
  function wdir(w) {
    if (w !~ /^[A-Za-z0-9_.\/~+@%,:-]+$/ || w ~ /^-/) return "?"
    if (substr(w, 1, 1) == "/") return w
    if (w == "~" || substr(w, 1, 2) == "~/") return HOMED != "" ? HOMED substr(w, 2) : "?"
    return (WDIR != "" && WDIR != "?") ? WDIR "/" w : "?"
  }

  function aside_path(p,    k) {
    for (k = 1; k <= naside; k++) if (index(p, ASIDE[k]) == 1) return 1
    return 0
  }

  # The directory a record ran in: its own cwd, which follows its message, so
  # the last on the line.
  function cwdof(l,    n, T) {
    if (!index(l, K_CWD)) return ""
    n = split(l, T, K_CWD); return substr(T[n], 1, index(T[n], Q) - 1)
  }

  function edit(seg,    p) {
    p = sval(seg, "\"file_path\":\""); if (p == "") p = sval(seg, "\"notebook_path\":\"")
    if (p != "" && aside_path(p)) { aside = 1; return }
    last_edit = pos; edited = 1
  }
  # An edit made through Bash, from what writes() found.
  function wrote() { if (WR == 2) aside = 1; else { last_edit = pos; edited = 1 } }
  function checked(id) {
    last_chk = pos; last_chk_id = id; last_hid = HID; any_chk = 1
    if (id != "") chk[id] = 1
  }

  # A tool_use block whose "type" is not its first key (Claude Code writes it
  # first), or whose input comes before its id and name: its own keys, at its
  # own depth, from its opening brace to its close.
  function own(pre, seg,    n, C, i, ch, s, d, sp, stk, st, v, k) {
    n = split(pre, C, ""); s = 0; sp = 0
    for (i = 1; i <= n; i++) {
      ch = C[i]
      if (s) { if (ch == BS) i++; else if (ch == Q) s = 0; continue }
      if (ch == Q) s = 1; else if (ch == "{") stk[++sp] = i; else if (ch == "}" && sp) sp--
    }
    BLK = substr(pre, sp ? stk[sp] : 1) K_USE seg
    n = split(BLK, C, ""); s = 0; d = 0; k = ""; OWN["id"] = ""; OWN["name"] = ""
    for (i = 1; i <= n; i++) {
      ch = C[i]
      if (s) { if (ch == BS) i++; else if (ch == Q) { s = 0; v = substr(BLK, st, i - st)
                 if (d == 1) { if (C[i + 1] == ":") k = v; else { if (k in OWN) OWN[k] = v; k = "" } } }
               continue }
      if (ch == Q) { s = 1; st = i + 1 }
      else if (ch == "{" || ch == "[") { if (d++ == 1) k = "" }
      else if ((ch == "}" || ch == "]") && --d == 0) break
    }
    BLK = substr(BLK, 1, i)
  }

  function reset() {
    edited = 0; aside = 0; pos = 0; lastd = ""
    last_edit = 0; last_chk = 0; last_chk_id = ""; last_hid = 0; any_chk = 0
    split("", chk); split("", failed); split("", used)
  }

  # Every tool_use block on the line. Claude Code writes one per line, but a
  # line holding several is read block by block. Its own id and name come
  # before its input there, and are read straight off; where the input comes
  # first, an id or a name inside it would be read instead, so the block is
  # read by depth, as one whose type is not first is.
  function uses(l,    n, S, i, pre, seg, id, name, pi, fast) {
    n = split(l, S, K_USE)
    for (i = 2; i <= n; i++) {
      pre = S[i - 1]; seg = S[i]; fast = 0
      if (substr(pre, length(pre)) == "{") {
        id = index(seg, "\"id\":\""); name = index(seg, "\"name\":\""); pi = index(seg, "\"input\":")
        if (id && name && (!pi || (id < pi && name < pi))) fast = 1; else pre = "{"
      }
      if (fast) { id = sval(seg, "\"id\":\""); name = sval(seg, "\"name\":\"") }
      else { own(pre, seg); id = OWN["id"]; name = OWN["name"]; seg = BLK }
      if (id != "") { if (id in used) continue; used[id] = 1 }
      pos++
      if (name in EDITS) edit(seg)
      else if (name == "Bash") {
        # A command that checks and writes is two steps, in its own order: a
        # write after the pipeline of the check leaves the check before the edit.
        if (check(seg) && WR == 1 && WRAT > CHKE) { checked(id); pos++; wrote() }
        else { if (WR) { wrote(); pos++ } if (CHKE) checked(id) }
      }
    }
  }

  # The message id a stop is known by: the API id where there is one.
  function msgid(l,    p, r) {
    if (p = index(l, "\"id\":\"msg_")) return sval(substr(l, p, 300), "\"id\":\"")
    if ((p = index(l, K_MSG)) && (r = sval(substr(l, p), "\"id\":\"")) != "") return r
    return (r = sval(l, "\"uuid\":\"")) != "" ? r : "line " (++anon)
  }

  # lastd is what the stop was, for a hold after it: c counted in the four, a
  # left out as after scratch edits only, n after no new edit. One before the
  # --since cutoff ends its turn and is counted nowhere.
  function stop() {
    if (cut) { edited = 0; aside = 0; lastd = ""; return }
    if (!edited) { if (aside) { naside_stops++; lastd = "a" } else lastd = "n"; aside = 0; return }
    edited = 0; aside = 0; stops++; lastd = "c"; if (!(SK in S2)) { S2[SK] = 1; stop_sessions++ }
    if (last_chk > last_edit) { if (last_chk_id in failed) nfail++; else { npass++; if (last_hid) nhid++ } }
    else if (any_chk) nstale++
    else nnever++
  }

  # A failed result marks its check. A line holding more than one tool_result
  # is cut between them, at the last "},{" before each next marker, so an
  # error is only ever charged to the block that reported it.
  function mark(seg,    n, P, i, id) {
    if (!index(seg, K_ERR)) return
    n = split(seg, P, K_TID)
    for (i = 2; i <= n; i++) { id = substr(P[i], 1, index(P[i], Q) - 1); if (id in chk) failed[id] = 1 }
  }
  function results(l,    n, P, m, k, b, region, R, c, j, t) {
    n = split(l, P, K_RES) - 1
    if (n <= 1) { mark(l); return }
    m[1] = length(P[1]) + 1
    for (k = 2; k <= n; k++) m[k] = m[k - 1] + length(K_RES) + length(P[k])
    b[0] = 1
    for (k = 1; k < n; k++) {
      region = substr(l, m[k], m[k + 1] - m[k]); c = split(region, R, "}"); t = 0; b[k] = m[k + 1]
      for (j = c; j > 1; j--) {
        t += length(R[j]) + 1
        if (substr(R[j], 1, 2) == ",{") { b[k] = m[k] + length(region) - t + 2; break }
      }
      mark(substr(l, b[k - 1], b[k] - b[k - 1]))
    }
    mark(substr(l, b[n - 1]))
  }

  # A record s own timestamp follows its uuid; a nested one, in a message or a
  # tool result, does not. Where none does, the last is taken.
  function stamp(l,    p, n, T, i, x, pre) {
    TS = ""; UU = ""; p = index(l, K_TS); if (!p) return
    pre = substr(l, p > 64 ? p - 64 : 1, p > 64 ? 64 : p - 1)
    if (match(pre, UUID)) TS = substr(l, p + length(K_TS), 10)
    else {
      n = split(l, T, K_TS)
      for (i = 2; i <= n; i++) {
        x = length(T[i - 1]); pre = substr(T[i - 1], x > 64 ? x - 63 : 1)
        if (match(pre, UUID)) break
      }
      if (i > n) { i = n; pre = "" }
      TS = substr(T[i], 1, 10)
    }
    if (pre != "" && match(pre, UUID)) UU = substr(pre, RSTART + 8, RLENGTH - 10)
    if (UU != "") { x = substr(l, p + length(K_TS), 40); UU = UU " " substr(x, 1, index(x, Q) - 1) }
    if (TS !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) TS = ""
  }

  # Whose record a line is, from its own keys: isSidechain and a user type sit
  # before its message, an assistant type after it (or before, when synthetic);
  # any other type first is a progress or attachment record, which may nest one.
  # A record before the --since cutoff is read for what it did, an edit or a
  # check, so a stop after the cutoff is told by all of its session; only its
  # own stops and holds, and its dates, are not counted.
  function record(l,    im, p, r, v) {
    im = index(l, K_MSG)
    p = index(l, K_SIDE); if (p && (!im || p < im)) return
    stamp(l); cut = (since != "" && TS != "" && TS < since)
    SK = sval(l, K_SID); if (SK == "") SK = BASE
    if (TS != "" && !cut) {
      seen = 1; if (!(SK in S1)) { S1[SK] = 1; sessions++ }
      if (first == "" || TS < first) first = TS
      if (TS > last) last = TS
    }
    if (!im) return
    if ((p = index(l, K_USER)) && p < im) r = "u"
    else if ((p = index(l, K_ASST)) && p < im) r = "a"
    else if ((p = index(l, K_TYPE)) && p < im) return
    else {
      p = index(l, "\"role\":\""); v = p ? substr(l, p + 8, 10) : ""
      if (v == "assistant\"") r = "a"; else if (substr(v, 1, 5) == "user\"") r = "u"; else return
    }
    if (r == "a") {
      if (index(l, K_USE)) { CWD = index(l, K_BASH) ? cwdof(l) : ""; uses(l) }
      if (index(l, K_END)) {
        r = msgid(l)
        if (!(r in stopped)) { stopped[r] = fno; stop(); sdisp[r] = lastd }
        else if (stopped[r] != fno) { edited = 0; aside = 0; lastd = sdisp[r] }
      }
      return
    }
    if (index(l, K_TID)) { if (index(l, K_ERR)) results(l); return }
    if (index(l, K_META) && (index(l, "\"content\":\"Stop hook feedback") || index(l, "\"text\":\"Stop hook feedback")) \
        && (index(l, "The gate last ran at") || index(l, "The gate has never run") \
            || index(l, "The gate failed on this exact tree") || index(l, "The gate passed on this exact tree at")) \
        && !cut && (UU == "" || !(UU in held))) {
      if (UU != "") held[UU] = 1
      holds++; if (!(SK in S3)) { S3[SK] = 1; hold_sessions++ }
      if (lastd == "c") hcount++; else if (lastd == "a") haside++; else if (lastd == "n") hnoedit++
    }
  }

  NF {
    f = $0; files++; fno++; reset(); BASE = f; sub(/.*\//, "", BASE); sub(/[.]jsonl$/, "", BASE); seen = 0
    if ((st = (getline line < f)) < 0) { if (!unread++) unread1 = f; next }
    while (st > 0) { record(line); st = (getline line < f) }
    close(f); if (!seen) skipped++
  }

  END {
    printf "%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", files, sessions, \
      (first == "" ? "-" : first), (last == "" ? "-" : last), stops, stop_sessions, \
      npass, nfail, nstale, nnever, holds, hold_sessions, nhid, naside_stops, unread, \
      hcount, haside, hnoedit, skipped
    if (unread) print unread1
  }'
