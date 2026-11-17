# felix inventory's chips, the second file of the host adapter (see the head of
# lib/inventory-host.sh, whose readers and awk it shares): the cards a session
# proposed and nobody started. Nothing here runs git.
#
# A proposal is an assistant tool_use of mcp__ccd_session__spawn_task, or of
# mcp__ccd_session__start_session whose input holds "initiation":"own_initiative"
# and no "proposal_id" (a call that carries one starts a card). Its result names
# the card: the task_ id after the first "task_id: ". A result that holds none
# made no card (a denied permission), and a proposal with no result in its file
# is a card nobody can tell: unknown. A dismiss_task naming the id withdraws it.
# A start_session card expires seven days after it was proposed, the desktop
# app says, and the chip says so then.
#
# Started (contract A3): S1, a session file under the records root, modified
# after the proposal and not the one that proposed it, whose first human text
# begins with the chip's prompt (its first 120 decoded characters, all of it
# when shorter; a framed prompt is read from after the Task: line); S2, such a
# file holding a custom-title record equal to the chip's title; S3, a file
# modified after the proposal holding a start_session call that names the
# chip's task id as its proposal_id, with a result.
#
# What is read (audit b09, C050). The proposals are read once, from every file of
# the scope modified within DAYS days, whole: the lines naming a ccd_session tool
# call and the 12 after each, where a result is (188 of 188 on felix-home within
# 34 lines, 186 within 12); a result not seen there is asked for in its file. A
# file with no spawn_task or start_session call is not read for proposals or
# dismissals. S1 stops at a file's first human text. S2 and S3 read the windows
# of each session file under the root, not the file: its first 1,048,576 bytes
# and its last 262,144, a record in one only when its whole line is, and all of a
# file of 1,310,720 bytes or less. S3 reads the whole of a file the proposals
# were read from, and a call's result must lie in what its call was read from.

# The whole lines of a file's windows: all of it when it holds 1,310,720 bytes or
# less, else the head's lines that end within its first 1,048,576 bytes and the
# tail's after the partial one (the byte before the tail shows whether it was).
_fi_win() {
  local sz; sz="$(wc -c 2>/dev/null < "$1" | tr -d ' ')"
  case "$sz" in ''|*[!0123456789]*) return 0 ;; esac
  if [ "$sz" -le 1310720 ]; then cat -- "$1" 2>/dev/null; return 0; fi
  head -c 1048576 -- "$1" 2>/dev/null | LC_ALL=C awk '{ o += length($0) + 1; if (o > 1048576) exit; print }'
  tail -c 262145 -- "$1" 2>/dev/null | sed 1d
}

# Chips proposed in the sessions of the record directories in SCOPEFILE
# modified within DAYS days that no session was started from and none withdrew.
#   felix_inv_host_chips NOW DAYS SCOPEFILE COUNTFILE WORKDIR
# prints one line per chip: id session epoch flag title, the flag unknown when a
# file the run could not read may have started it, else -. Status 1, and nothing
# printed, when the records cannot be read. COUNTFILE gets, when there are
# chips, how many unreadable session files under the root are later than the
# oldest proposal, for the cover row. WORKDIR is scratch the caller removes.
felix_inv_host_chips() {
  local root now="$1" days="$2" e f mins lo um w="${5:-}" pid tid mt sc n id
  root="$(_fi_host_root)" || return 1
  [ -d "$w" ] || return 1
  while IFS= read -r e; do
    find "$e" -maxdepth 1 -type f -name '*.jsonl' -mmin -$((days * 1440)) 2>/dev/null
  done < "$3" > "$w/scoped"
  # Each file's lines that can matter, after a line naming the file (\002
  # cannot start a JSON line). C: a proposal, R: a result seen for it, D: a
  # dismissed task, S: a start_session call naming a proposal_id.
  while IFS= read -r f <&3; do
    printf '\002%s\n' "$f"; grep -A 12 -F -e '"name":"mcp__ccd_session__' -- "$f" 2>/dev/null
  done 3< "$w/scoped" | awk "$_FI_HOST_AWK"'
    BEGIN {
      SP = "mcp__ccd_session__spawn_task"; SS = "mcp__ccd_session__start_session"; DI = "mcp__ccd_session__dismiss_task"
      KP = "\"prompt\":\""; KI = "\"initiation\":\"own_initiative\""; KPI = "\"proposal_id\":\""; KIN = "\"input\":{"
      LA = "\"name\":\"" SP "\",\"input\":{"; LB = "\"name\":\"" SS "\",\"input\":{"
    }
    # A file is read for proposals and dismissals only when it names a spawn_task or start_session call; what it held waits until then.
    function commit(    i) {
      if (fp != "" && (fp in LST)) {
        for (i = 1; i <= nb; i++) if (!(BI[i] in CS)) { CS[BI[i]] = BR[i]; ORD[++nc] = BI[i] }
        for (i = 1; i <= nd; i++) DS[BD[i]] = 1
        for (i = 1; i <= n3; i++) S3L[++ns] = BS[i]
      }
      nb = 0; nd = 0; n3 = 0
    }
    substr($0, 1, 1) == "\002" { commit(); fp = substr($0, 2); gsub(/\t/, " ", fp); s = fp; sub(/.*\//, "", s); sub(/[.]jsonl$/, "", s); next }
    $0 == "--" { next }
    { l = $0
      if (index(l, LA) || index(l, LB)) LST[fp] = 1
      if (index(l, K_TU) && kind(l) == "a") {
        n = split(l, SG, K_TU); et = tsof(l)
        for (i = 2; i <= n; i++) {
          g = SG[i]; id = substr(g, 1, index(g, Q) - 1); nm = val(g, "\"name\":\"")
          if (!(p = index(g, KIN))) continue
          r = substr(g, p + length(KIN))
          if (nm == DI) { BD[++nd] = val(r, "\"task_id\":\""); continue }
          if (nm == SS && (q = index(g, KPI))) BS[++n3] = str(substr(g, q + length(KPI))) "\t" fp "\t" id
          if (nm != SP && !(nm == SS && index(r, KI) && !index(r, KPI))) continue
          if (id == "") continue
          BI[++nb] = id; BR[nb] = fp "\t" s "\t" (et == "" ? "-" : et) "\t" (nm == SS ? "S" : "P") "\t" dec(val(r, "\"title\":\"")) "\t" ((q = index(r, KP)) ? key(substr(r, q + length(KP))) : "\001")
        }
        next
      }
      rest = l
      while (p = index(rest, K_TID)) {
        rest = substr(rest, p + length(K_TID)); id = substr(rest, 1, index(rest, Q) - 1)
        nx = index(rest, K_TID); g = nx ? substr(rest, 1, nx - 1) : rest
        RES[id] = 1
        if (q = index(g, "task_id: task_")) { t = substr(g, q + 9); match(t, /^[A-Za-z0-9_]+/); TASK[id] = substr(t, 1, RLENGTH) }
      }
    }
    END {
      commit()
      for (i = 1; i <= nc; i++) { id = ORD[i]; printf "C\t%s\t%s\n", id, CS[id]; if (id in RES) printf "R\t%s\t%s\n", id, (id in TASK ? TASK[id] : "") }
      for (t in DS) printf "D\t%s\n", t
      for (i = 1; i <= ns; i++) printf "S\t%s\n", S3L[i]
    }' > "$w/p0"
  awk -F'\t' '$1 == "C" { c[$2] = $3; o[++n] = $2 } $1 == "R" { r[$2] = 1 } END { for (i = 1; i <= n; i++) if (!(o[i] in r)) print o[i] "\t" c[o[i]] }' "$w/p0" > "$w/ur"
  [ -s "$w/p0" ] || return 0
  # A proposal whose result was not among the lines after its call: its result is asked for in its own file.
  while IFS=$'\t' read -r id f <&3; do grep -F -e "\"tool_use_id\":\"$id\"" -- "$f" 2>/dev/null; done 3< "$w/ur" > "$w/fb"
  { cat "$w/p0"; printf '\001\n'; cat "$w/fb"; } | awk -F'\t' -v o3="$w/m3f" "$_FI_HOST_AWK"'
    $0 == "\001" { sec = 1; next }
    sec == 0 { if ($1 == "C") { ID[++n] = $2; REC[$2] = $0 } else if ($1 == "R") { RES[$2] = 1; if ($3 != "") TASK[$2] = $3 }
               else if ($1 == "D") DS[$2] = 1; else if ($1 == "S") S3L[++ns] = $2 "\t" $3 "\t" $4; next }
    { rest = $0
      while (p = index(rest, K_TID)) {
        rest = substr(rest, p + length(K_TID)); id = substr(rest, 1, index(rest, Q) - 1)
        nx = index(rest, K_TID); g = nx ? substr(rest, 1, nx - 1) : rest
        RES[id] = 1
        if (q = index(g, "task_id: task_")) { t = substr(g, q + 9); match(t, /^[A-Za-z0-9_]+/); TASK[id] = substr(t, 1, RLENGTH) }
      } }
    END {
      printf "" > o3
      for (i = 1; i <= n; i++) { id = ID[i]; split(REC[id], c, "\t")
        if (id in RES) { if (!(id in TASK)) continue; t = TASK[id]; nr = 0; if (t in DS) continue } else { t = id; nr = 1 }
        TA[t] = 1; printf "%s\t%s\t%s\t%s\t%s\t%d\t%s\t%s\n", t, c[3], c[4], c[5], c[6], nr, c[7], c[8] }
      for (i = 1; i <= ns; i++) { split(S3L[i], c, "\t"); if (c[1] in TA) print c[1] "\t" c[2] "\t" c[3] "\tF" > o3 }
    }' > "$w/p"
  [ -s "$w/p" ] || return 0
  # The session files under the records modified since the oldest chip, whole in one list and by size in two.
  mins="$(awk -F'\t' -v now="$now" '$4 != "-" && (o == "" || $4 < o) { o = $4 } END { print (o == "" ? 0 : int((now - o) / 60) + 2), o + 0 }' "$w/p")"
  lo="${mins#* }"; mins="${mins% *}"; [ "${mins:-0}" -gt 0 ] || mins=$((days * 1440))
  # A file the run cannot read, in any record directory under the root and modified after a proposal, may have started the chip.
  um="$(find "$root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | _fi_host_unr "$mins" "$lo")"
  printf '%s\n' "${um%% *}" > "$4"; um="${um#* }"
  find "$root" -mindepth 2 -maxdepth 2 -type f -name '*.jsonl' -mmin -"$mins" ! -size +1310720c 2>/dev/null > "$w/sm"
  find "$root" -mindepth 2 -maxdepth 2 -type f -name '*.jsonl' -mmin -"$mins" -size +1310720c 2>/dev/null > "$w/bg"
  cat "$w/sm" "$w/bg" > "$w/files"
  : > "$w/m"
  # S1: the first human text of each file.
  { cat "$w/p"; printf '\001\n'; cat "$w/files"; } | awk -F'\t' "$_FI_HOST_AWK"'
    BEGIN { BG = "Background (from the session that started this one):"; TK = "\\n\\nTask:\\n" }
    $0 == "\001" { files = 1; next }
    !files { if ($8 != "" && $8 != "\001") { if (length($8) >= 120) LK[$8] = 1; else SK[++ns] = $8 } ; next }
    { f = $0
      while ((getline l < f) > 0) if (kind(l) == "u" && (h = human(l)) != "") {
        if (substr(h, 1, length(BG)) == BG && (i = index(h, TK))) h = substr(h, i + length(TK))
        d = dec(substr(str(h), 1, 2048))
        if ((k = substr(d, 1, 120)) in LK) print "S1\t" k "\t" f
        for (j = 1; j <= ns; j++) if (substr(d, 1, length(SK[j])) == SK[j]) print "S1\t" SK[j] "\t" f
        break }
      close(f) }' >> "$w/m"
  # S2 and S3: the lines of the windows that hold a custom-title record or a proposal_id. A small file is one run of lines (\002); a
  # large one is its head (\004, grep -b giving each line's offset) and, after \003, its tail, one byte longer to show where a line starts.
  { while IFS= read -r f <&3; do
      printf '\002%s\n' "$f"; grep -F -e '"type":"custom-title"' -e '"proposal_id":"task_' -- "$f" 2>/dev/null
    done 3< "$w/sm"
    while IFS= read -r f <&3; do
      printf '\004%s\n' "$f"; head -c 1048576 -- "$f" 2>/dev/null | grep -b -F -e '"type":"custom-title"' -e '"proposal_id":"task_'
      printf '\003\n'; tail -c 262145 -- "$f" 2>/dev/null | grep -b -F -e '"type":"custom-title"' -e '"proposal_id":"task_'
    done 3< "$w/bg"; } | { cat "$w/p"; printf '\001\n'; cat; } | awk -F'\t' "$_FI_HOST_AWK"'
    $0 == "\001" { files = 1; next }
    !files { if ($7 != "") TT[$7] = 1; TA[$1] = 1; next }
    substr($0, 1, 1) == "\002" { fp = substr($0, 2); md = "w"; next }
    substr($0, 1, 1) == "\004" { fp = substr($0, 2); md = "h"; next }
    $0 == "\003" { md = "t"; next }
    { l = $0
      if (md != "w") { off = l + 0; sub(/^[0123456789]+:/, "", l)
        if (md == "h" && off + length(l) + 1 > 1048576) next
        if (md == "t" && off < 1) next }
      if (!index(l, K_MSG) && index(l, "\"type\":\"custom-title\"")) { t = dec(val(l, "\"customTitle\":\"")); if (t in TT) print "S2\t" t "\t" fp; next }
      if (kind(l) != "a") next
      n = split(l, SG, K_TU)
      for (i = 2; i <= n; i++) { g = SG[i]
        if (val(g, "\"name\":\"") != "mcp__ccd_session__start_session" || !(p = index(g, "\"proposal_id\":\""))) continue
        p = str(substr(g, p + 15)); if (p in TA) print "S3C\t" p "\t" fp "\t" substr(g, 1, index(g, Q) - 1) "\tW" } }' > "$w/m3"
  awk -F'\t' '$1 == "S2"' "$w/m3" >> "$w/m"
  { awk -F'\t' '$1 == "S3C" { print $2 "\t" $3 "\t" $4 "\t" $5 }' "$w/m3"; cat "$w/m3f" 2>/dev/null; } > "$w/m3c"
  # S3 counts only a call that has a result in what its call was read from.
  while IFS=$'\t' read -r pid f tid sc <&3; do
    if [ "$sc" = F ]; then n="$(grep -c -F -e "\"tool_use_id\":\"$tid\"" -- "$f" 2>/dev/null)"
    else n="$(_fi_win "$f" | grep -c -F -e "\"tool_use_id\":\"$tid\"" 2>/dev/null)"; fi
    if [ "${n:-0}" -gt 0 ]; then printf 'S3\t%s\t%s\n' "$pid" "$f" >> "$w/m"; fi
  done 3< "$w/m3c"
  # When each file that matched was last modified.
  awk -F'\t' '{ print $3 }' "$w/m" | LC_ALL=C sort -u > "$w/mf"
  : > "$w/mt"
  while IFS= read -r f <&3; do mt="$(_fi_mtime "$f")"; [ -z "$mt" ] || printf '%s\t%s\n' "$f" "$mt" >> "$w/mt"; done 3< "$w/mf"
  { cat "$w/p"; printf '\001\n'; cat "$w/m"; printf '\001\n'; cat "$w/mt"; } | awk -F'\t' -v um="$um" -v now="$now" "$_FI_HOST_AWK"'
    $0 == "\001" { sec++; next }
    sec == 0 { C[++n] = $0; next }
    sec == 1 { M[++nm] = $0; next }
    { MT[$1] = $2 }
    END { for (i = 1; i <= n; i++) { split(C[i], c, "\t"); st = 0
        for (j = 1; j <= nm && !st; j++) { split(M[j], m, "\t")
          if (!(m[3] in MT) || (c[4] != "-" && MT[m[3]] + 0 <= c[4] + 0)) continue
          if (m[1] == "S1" && m[2] == c[8] && m[3] != c[2]) st = 1
          else if (m[1] == "S2" && m[2] == c[7] && m[3] != c[2]) st = 1
          else if (m[1] == "S3" && m[2] == c[1]) st = 1 }
        if (st) continue
        ti = cut120(c[7])
        if (c[5] == "S" && c[4] != "-" && now - c[4] >= 604800) ti = ti "; card expired"
        if (c[6] == 1) ti = ti "; no result recorded for the proposal"
        printf "%s\t%s\t%s\t%s\t%s\n", c[1], c[3], c[4], ((c[6] == 1 || (um + 0 > 0 && (c[4] == "-" || um + 0 > c[4] + 0))) ? "unknown" : "-"), ti } }'
}
