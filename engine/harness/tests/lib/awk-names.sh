# tests/lib/awk-names.sh: _awk_names, the lint of contract B12
# (docs/2026-10-18-lost-work-page-contract.md): no gawk builtin name used as an
# identifier in an awk program in lib/. Part 1497 runs it. Definitions only.
#
# The Linux CI runner's awk is gawk, and macOS ships BWK awk. gawk reserves
# names the other two leave free, so a program that uses one as its own passes
# every local run and fails on Linux: the lost-work page's row-tag array was
# named RT, and gawk stopped on it (8d181f37).
#
# _awk_names FILE... reads the files as bash does and finds every awk command,
# then the program text each one runs: its program word, and, followed from
# there, every assignment of a variable the word expands and every argument a
# caller passes for a function's $1-$9 it expands. In that text it reads each
# identifier outside strings, regex literals, comments and numbers. Rows, tab-
# separated: name FILE LINE IDENT for a listed name; unread FILE LINE WHAT for a
# part it cannot read (a command substitution, a -f program, a variable nothing
# assigns, a special parameter); open FILE LINE WHAT for a quote, $( or here-
# document still open at the end of a file; then programs N, the texts read.
# Exit 0 only with no name, unread or open row and N above 0: a lint that read
# nothing has not passed.
#
# It runs under BWK awk, mawk and gawk, with LC_ALL=C so split on "" is a byte
# per element. Each line is split once and each text once: substr walks the
# whole string in BWK awk, so a walk by substr would be quadratic. A quoted run
# is appended to its word in one piece, never a byte at a time.
_awk_names() {
  LC_ALL=C awk '
BEGIN {
  split("RT FPAT FIELDWIDTHS IGNORECASE PROCINFO ERRNO ARGIND BINMODE LINT PREC ROUNDMODE SYMTAB FUNCTAB TEXTDOMAIN and or xor compl lshift rshift gensub asort asorti patsplit isarray typeof strtonum strftime systime mktime", T, " ")
  for (k in T) NAMES[T[k]] = 1
  split("! { } if then elif else while until do", T, " "); for (k in T) SKIPW[T[k]] = 1
  split("xargs env nice nohup command exec time builtin", T, " "); for (k in T) WRAPW[T[k]] = 1
  split("local readonly export declare typeset", T, " "); for (k in T) DECLW[T[k]] = 1
  IDS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_"; IDC = IDS "0123456789"; DIG = "0123456789"
  SQ = "\047"; np = 0; na = 0; nc = 0; ntext = 0; bad = 0
  reset()
}
# index(s, "") is 1 in every awk: a byte past the end of a line is in no set.
function isin(set, ch) { return ch != "" && index(set, ch) > 0 }
function report(kind, file, line, what) { bad = 1; printf "%s\t%s\t%d\t%s\n", kind, file, line, what }

# ---- reading a file as bash does --------------------------------------------
# ST is the state: O outside quotes, S in single quotes, A in $"..." (C-style),
# D in double quotes, B in ${...}, H between here-document lines, HB in an
# unquoted here-document line. Frame F is the command being read: 0 the file,
# and one more for each $( open, which returns to FST[F] at its own ).
function reset() { CURFN = ""; INH = 0; ST = "O"; F = 0; FDEP[0] = 0; FST[0] = "O"; NH = 0; HI = 0; OPENL = 0; NW[0] = 0; wordreset(0) }
function wordreset(f) { CW[f] = ""; CWR[f] = ""; CWL[f] = 0; CWQ[f] = 0; CWE[f] = 0; CWU[f] = 0; CWS[f] = 0; CWX[f] = 0; CWIN[f] = 0 }
function wstart(f) { if (!CWIN[f]) { CWIN[f] = 1; CWL[f] = FNR } }
function wadd(f, s) { wstart(f); CW[f] = CW[f] s }
function ref(f, name) { CWR[f] = CWR[f] " " name; CWX[f] = 1 }
function push() { F++; FST[F] = ST; FDEP[F] = 0; NW[F] = 0; wordreset(F); ST = "O"; OPENL = FNR }
function endword(f,    k) {
  if (!CWIN[f]) return
  k = ++NW[f]; W[f, k] = CW[f]; WR[f, k] = CWR[f]; WL[f, k] = CWL[f]; WQ[f, k] = CWQ[f]
  WE[f, k] = CWE[f]; WU[f, k] = CWU[f]; WS[f, k] = CWS[f]
  wordreset(f)
}
function assign(f, k,    n, a) {
  n = substr(W[f, k], 1, WE[f, k] - 1); sub(/\+$/, "", n)
  a = ++na; ATEXT[a] = substr(W[f, k], WE[f, k] + 1); ALINE[a] = WL[f, k]; AFILE[a] = FILENAME
  AREF[a] = WR[f, k]; AU[a] = WU[f, k]; AS[a] = WS[f, k]
  ACNT[n]++; AIDX[n, ACNT[n]] = a
}
function vname(s, file, line,    n) { n = s; sub(/=.*/, "", n); if (n in NAMES) report("name", file, line, n) }
function plain(f, k) { return !WQ[f, k] }
# One simple command of frame f, its words read: assignments kept, an awk
# command`s program word kept, a call kept with its arguments.
function endcmd(f,    k, n, w, prog, j) {
  n = NW[f]; k = 1
  while (k <= n) {
    if (WE[f, k] > 0) { assign(f, k); k++; continue }
    if (plain(f, k) && (W[f, k] in SKIPW)) { k++; continue }
    if (plain(f, k) && (W[f, k] in WRAPW)) { for (k++; k <= n && (WE[f, k] > 0 || (plain(f, k) && W[f, k] ~ /^-/)); k++); continue }
    break
  }
  if (k > n || !plain(f, k)) { NW[f] = 0; return }
  w = W[f, k]
  if (w == "function" && k < n) CURFN = W[f, k + 1]
  else if (w in DECLW) { for (k++; k <= n; k++) if (WE[f, k] > 0) assign(f, k) }
  else if (w == "awk" || w ~ /\/awk$/) {
    prog = 0
    for (k++; k <= n; k++) {
      w = W[f, k]
      if (plain(f, k) && w ~ /^[0123456789]*[<>]/) { if (w ~ /^[0123456789]*[<>&]+$/) k++; continue }
      if (w == "--") { prog = k + 1; break }   # awk reads its options unquoted, as the shell hands them over
      if (w == "-F" || w == "-v" || w == "-f") {
        if (w == "-f") { report("unread", FILENAME, WL[f, k], "awk -f: the program is a file"); prog = -1; break }
        if (w == "-v") vname(W[f, k + 1], FILENAME, WL[f, k + 1])
        k++; continue }
      if (w ~ /^-f./) { report("unread", FILENAME, WL[f, k], "awk -f: the program is a file"); prog = -1; break }
      if (w ~ /^-v./) { vname(substr(w, 3), FILENAME, WL[f, k]); continue }
      if (w ~ /^-./) continue
      prog = k; break
    }
    if (prog > 0 && prog <= n) {
      np++; PT[np] = W[f, prog]; PL[np] = WL[f, prog]; PF[np] = FILENAME; PR[np] = WR[f, prog]
      if (WU[f, prog]) report("unread", FILENAME, WL[f, prog], "a command substitution in the program")
      if (WS[f, prog]) report("unread", FILENAME, WL[f, prog], "a special or positional parameter in the program")
      for (k = prog + 1; k <= n; k++) if (WE[f, k] > 0) vname(W[f, k], FILENAME, WL[f, k])
    }
  } else if (w ~ /^[A-Za-z_][A-Za-z0-9_]*$/) {
    nc++; CN[nc] = w; CF[nc] = FILENAME; NCA[nc] = n - k
    for (j = 1; k + j <= n; j++) { CA[nc, j] = W[f, k + j]; CAR[nc, j] = WR[f, k + j]; CAL[nc, j] = WL[f, k + j]; CAU[nc, j] = WU[f, k + j]; CAS[nc, j] = WS[f, k + j] }
  }
  NW[f] = 0
}
# A $ at L[i], in state O, D: the expansion it opens. Returns the next index.
function dollar(i, n,    c, nm, j) {
  c = L[i + 1]
  if (c == "(") { wadd(F, "X"); CWU[F] = 1; CWX[F] = 1; push(); return i + 2 }
  if (c == "{") {
    wadd(F, "X"); CWX[F] = 1; j = i + 2; nm = ""
    while (j <= n && isin(nm == "" ? IDS : IDC, L[j])) { nm = nm L[j]; j++ }
    if (nm != "") ref(F, nm)
    else if (isin("123456789", L[j]) && CURFN != "") { while (isin(DIG, L[j])) { nm = nm L[j]; j++ } ref(F, "@" CURFN ":" nm) }
    else if (L[j] != "#") CWS[F] = 1
    BRET = ST; BDEP = 1; ST = "B"; OPENL = FNR
    return i + 2 }
  if (isin(IDS, c)) {
    j = i + 1; nm = ""
    while (j <= n && isin(IDC, L[j])) { nm = nm L[j]; j++ }
    wadd(F, "X"); ref(F, nm); return j }
  if (isin("123456789", c) && CURFN != "") { wadd(F, "X"); ref(F, "@" CURFN ":" c); return i + 2 }
  if (isin("0123456789@*#?$!-", c)) { wadd(F, "X"); CWS[F] = 1; CWX[F] = 1; return i + 2 }
  if (c == SQ && ST == "O") { wstart(F); CWQ[F] = 1; ST = "A"; OPENL = FNR; return i + 2 }
  if (c == "\"" && ST == "O") { wstart(F); CWQ[F] = 1; ST = "D"; OPENL = FNR; return i + 2 }
  wadd(F, "$"); return i + 1
}
function finish(file) {
  if (file == "") return
  if (ST == "H" || ST == "HB") report("open", file, OPENL, "a here-document to " HDEL[HI])
  else if (ST != "O") report("open", file, OPENL, ST == "S" ? "a single quote" : ST == "D" ? "a double quote" : ST == "A" ? "a $" SQ " quote" : "a ${")
  else if (F > 0) report("open", file, OPENL, "a $(")
  else if (NH > 0) report("open", file, OPENL, "a here-document to " HDEL[1])
  else { endword(0); endcmd(0) }
  reset()
}
FNR == 1 { finish(LASTF); LASTF = FILENAME }
{
  if (ST == "H") {
    s = $0; if (HDASH[HI]) sub(/^\t+/, "", s)
    if (s == HDEL[HI]) { if (++HI > NH) { NH = 0; HI = 0; INH = 0; ST = "O" }; next }
    if (HQ[HI]) next
    ST = "HB"
  }
  line = $0; n = split(line, L, ""); i = 1; cont = 0
  while (i <= n) {
    c = L[i]
    if (ST == "HB") {   # an unquoted here-document line: only its $( ) commands are read
      if (c == "\\") { i += 2; continue }
      if (c == "$" && L[i + 1] == "(") { push(); i += 2; continue }
      i++; continue }
    if (ST == "S") {
      j = index(substr(line, i), SQ)
      if (!j) { wadd(F, substr(line, i)); i = n + 1; break }
      wadd(F, substr(line, i, j - 1)); i += j; ST = "O"; continue }
    if (ST == "A") {
      if (c == "\\") { wadd(F, c L[i + 1]); i += 2; continue }
      if (c == SQ) { ST = "O"; i++; continue }
      wadd(F, c); i++; continue }
    if (ST == "B") {
      if (c == "\\") { i += 2; continue }
      if (c == "{") BDEP++
      else if (c == "}") { if (--BDEP == 0) ST = BRET }
      else if (c == SQ && BRET == "O") { j = index(substr(line, i + 1), SQ); i += (j ? j + 1 : n); continue }
      i++; continue }
    if (ST == "D") {
      if (c == "\\") {
        if (i == n) { cont = 1; i++; continue }
        if (isin("$`\"\\", L[i + 1])) { wadd(F, L[i + 1]); i += 2; continue }
        wadd(F, c); i++; continue }
      if (c == "\"") { ST = "O"; i++; continue }
      if (c == "$") { i = dollar(i, n); continue }
      wadd(F, c); i++; continue }
    # ST == "O"
    if (c == "\\") { if (i == n) { cont = 1; i++; continue } wadd(F, L[i + 1]); i += 2; continue }
    if (c == SQ) { wstart(F); CWQ[F] = 1; ST = "S"; OPENL = FNR; i++; continue }
    if (c == "\"") { wstart(F); CWQ[F] = 1; ST = "D"; OPENL = FNR; i++; continue }
    if (c == "$") { i = dollar(i, n); continue }
    if (c == "#" && !CWIN[F]) break
    if (c == " " || c == "\t") { endword(F); i++; continue }
    if (c == ";" || c == "&" || c == "|") { endword(F); endcmd(F); i++; continue }
    if (c == "(") {
      endword(F)   # NAME() opens a function: its $1-$9 are its callers` arguments
      if (NW[F] == 1 && plain(F, 1) && W[F, 1] ~ /^[A-Za-z_][A-Za-z0-9_]*$/ && substr(line, i + 1) ~ /^[ \t]*\)/) { CURFN = W[F, 1]; NW[F] = 0 }
      endcmd(F); FDEP[F]++; i++; continue }
    if (c == ")") {
      endword(F); endcmd(F)
      if (FDEP[F] > 0) FDEP[F]--
      else if (F > 0) { ST = FST[F]; F-- }
      i++; continue }
    if (c == "<" && L[i + 1] == "<" && L[i + 2] == "<") { wadd(F, "<<<"); i += 3; continue }
    if (c == "<" && L[i + 1] == "<") {
      endword(F); j = i + 2; d = 0; q = 0; del = ""
      if (L[j] == "-") { d = 1; j++ }
      while (L[j] == " " || L[j] == "\t") j++
      while (j <= n && !isin(" \t;|&()<>", L[j])) { if (isin(SQ "\"\\", L[j])) q = 1; else del = del L[j]; j++ }
      NH++; HDEL[NH] = del; HDASH[NH] = d; HQ[NH] = q; if (NH == 1) OPENL = FNR
      i = j; continue }
    if (c == "=" && !CWE[F] && !CWQ[F] && !CWX[F] && CW[F] ~ /^[A-Za-z_][A-Za-z0-9_]*\+?$/) { wadd(F, c); CWE[F] = length(CW[F]); i++; continue }
    wadd(F, c); i++
  }
  if (ST == "HB") ST = "H"
  else if (ST == "S" || ST == "A" || (ST == "D" && !cont)) wadd(F, "\n")
  else if (ST == "O" && !cont) {
    endword(F); endcmd(F)
    if (NH > 0 && !INH) { INH = 1; ST = "H"; HI = 1 }
  }
}

# ---- the awk in a text ------------------------------------------------------
# Every identifier outside a string, a regex literal, a comment and a number.
# A / opens a regex literal unless what stands before it on its line is an
# identifier but return, print and printf, a number, ) or ].
function lex(t, file, line,    C, m, i, c, ln, val, id, j) {
  ntext++
  m = split(t, C, ""); i = 1; ln = line; val = 0
  while (i <= m) {
    c = C[i]
    if (c == "\n") { ln++; val = 0; i++; continue }
    if (c == " " || c == "\t") { i++; continue }
    if (c == "#") { while (i <= m && C[i] != "\n") i++; continue }
    if (c == "\"") {
      for (i++; i <= m && C[i] != "\"" && C[i] != "\n"; i++) if (C[i] == "\\") i++
      if (C[i] == "\"") i++
      val = 0; continue }
    if (c == "/" && !val) {
      for (i++; i <= m && C[i] != "/" && C[i] != "\n"; i++) {
        if (C[i] == "\\") { i++; continue }
        if (C[i] == "[") {   # a bracket expression, which may hold / and [:class:]
          j = i + 1; if (C[j] == "^") j++; if (C[j] == "]") j++
          while (j <= m && C[j] != "]" && C[j] != "\n") {
            if (C[j] == "[" && isin(":.=", C[j + 1])) { for (j += 2; j <= m && !(isin(":.=", C[j]) && C[j + 1] == "]") && C[j] != "\n"; j++); j += 2; continue }
            j++ }
          i = j } }
      if (C[i] == "/") i++
      val = 0; continue }
    if (isin(IDS, c)) {
      id = c; for (i++; i <= m && isin(IDC, C[i]); i++) id = id C[i]
      if (id in NAMES) report("name", file, ln, id)
      val = !(id == "return" || id == "print" || id == "printf"); continue }
    if (isin(DIG, c) || (c == "." && isin(DIG, C[i + 1]))) { for (i++; i <= m && isin(IDC ".", C[i]); i++); val = 1; continue }
    val = (c == ")" || c == "]"); i++
  }
}
# A name the program text expands: a variable, or @F:N for function F`s Nth
# argument. Each assignment or argument is read once, from wherever it stands.
function resolve(name, file, line,    k, a, nr, R, r, fn, pos, c, got) {
  if (name in SEEN) return
  SEEN[name] = 1
  if (substr(name, 1, 1) == "@") {
    fn = substr(name, 2); pos = fn; sub(/:.*/, "", fn); sub(/^[^:]*:/, "", pos); got = 0
    for (c = 1; c <= nc; c++) if (CN[c] == fn && NCA[c] >= pos + 0) {
      got = 1; lex(CA[c, pos], CF[c], CAL[c, pos])
      if (CAU[c, pos]) report("unread", CF[c], CAL[c, pos], "a command substitution in $" pos " of " fn)
      if (CAS[c, pos]) report("unread", CF[c], CAL[c, pos], "a special or positional parameter in $" pos " of " fn)
      nr = split(CAR[c, pos], R, " "); for (r = 1; r <= nr; r++) resolve(R[r], CF[c], CAL[c, pos]) }
    if (!got) report("unread", file, line, "$" pos " of " fn ", which no call in the files read passes")
    return }
  if (!ACNT[name]) { report("unread", file, line, "$" name ", which nothing in the files read assigns"); return }
  for (k = 1; k <= ACNT[name]; k++) {
    a = AIDX[name, k]; lex(ATEXT[a], AFILE[a], ALINE[a])
    if (AU[a]) report("unread", AFILE[a], ALINE[a], "a command substitution in $" name)
    if (AS[a]) report("unread", AFILE[a], ALINE[a], "a special or positional parameter in $" name)
    nr = split(AREF[a], R, " "); for (r = 1; r <= nr; r++) resolve(R[r], AFILE[a], ALINE[a])
  }
}
END {
  finish(LASTF)
  for (p = 1; p <= np; p++) lex(PT[p], PF[p], PL[p])
  for (p = 1; p <= np; p++) { nr = split(PR[p], R, " "); for (r = 1; r <= nr; r++) resolve(R[r], PF[p], PL[p]) }
  if (ntext == 0) bad = 1
  printf "programs\t%d\n", ntext
  exit bad
}' "$@"
}
