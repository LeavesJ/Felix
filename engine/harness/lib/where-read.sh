# Where a command acts: the reader half of lib/where.sh, an awk program kept
# in a shell string so the engine stays bash, and so the gate reads it as bash.
#
# Reads one Bash command, exactly as a PreToolUse payload carries it (a JSON
# string, escapes and all), the way a shell would: word by word, command by
# command, into $( ), backticks, subshells, loops, functions, and into the
# scripts it hands to other shells through -c, here-documents and files it
# wrote from one. It runs nothing. For each simple command it writes where
# that command acts, as the set of every directory or path it could touch on
# some path through the line.
#
# Input variables: CWD0 the directory the command starts in; HOMEV and TMPV
# the $HOME and $TMPDIR the hook sees; CDP set when $CDPATH is; GITENV set
# when the environment of the hook carries GIT_DIR or GIT_WORK_TREE.
#
# Output, one line each, tab-separated:
#   C kind why text places spans   a simple command. kind p: judge its places
#                                  if the rule matches its text; u: it cannot
#                                  be told if the rule matches; m: judge its
#                                  places whatever the rule says.
#   M path                         mkdir -p of path was taken to succeed
#   D dir                          mktemp worked in dir, taken to be there
#   N                              something ran that can delete, so no guard
#                                  on a directory existing can be trusted
#   H why                          the line as a whole cannot be told
#   E                              the reader reached the end
# A place list is alternatives each led by \036. An alternative is a path,
# then any guards each led by \035; a guard is directories joined by \037, and
# the alternative is impossible when every one of them exists. \032 in a path
# means a part the reader cannot know. spans are the raw byte ranges of the
# own text of the command in the payload string, "a,b" 0-based inclusive, or "-".
#
# Everything the reader does not follow ends as \032 or as an H line, and the
# judge reads both as "cannot be told", which keeps the row. So a gap here can
# only keep a refusal; it can never make one. BWK awk, mawk and gawk: split on
# "" is one character per element in all three, and the judge runs this with
# LC_ALL=C so that is one byte.

# shellcheck disable=SC2016
_FELIX_WHERE_READ='
BEGIN {
  RS = "\001"; SQ = "\047"; BQ = "`"
  ALT = "\036"; GRD = "\035"; ALL = "\037"; UNK = "\032"; FRESH = ".felix-where-fresh"
  # A one-character string separator splits at line breaks too in BWK awk,
  # and a value can hold one; a bracket expression is a regex and does not.
  ALTRE = "[\036]"
  NS = 0; NN = 0; NA = 0; NPH = 0; LD = 0; COND = 0; CDN = 0; RID = 0; RIDN = 0; CMDN = 0
  EMIT = 1; HZ = ""; NOGUARD = 0; PIPEPOS = 1
  DEADST = st_new(); DEAD[DEADST] = 1
  split("bash sh zsh dash ksh mksh ash fish csh tcsh", T, " "); for (k in T) SHELLS[T[k]] = 1
  split("awk gawk mawk nawk osascript make gmake just expect tclsh script tmux screen parallel coproc trap", T, " ")
  for (k in T) RUNNER[T[k]] = 1
  split("xargs sudo doas su runuser ssh watch", T, " "); for (k in T) FOREIGN[T[k]] = 1
  split("cd true false : test [ export local declare typeset readonly set unset shift mkdir touch rm rmdir cp chmod ln mv wait sleep", T, " ")
  for (k in T) SILENT[T[k]] = 1
  # What these do is named by their arguments and redirections, so the
  # directory they run in is not itself a place they act on. Printing tools
  # take text, and only a path that leaves the directory is one.
  split("echo printf true false : test [ wait sleep", T, " "); for (k in T) DATATOOL[T[k]] = 1
  split("cp mv rm rmdir mkdir touch tee truncate sed install dd ln link chmod chown cat head tail wc sort uniq grep egrep fgrep ls stat diff cmp cut", T, " ")
  for (k in T) FILETOOL[T[k]] = 1
  MADEM = ".felix-where-made"
}
{
  unjson($0); N0 = N; I = 1; LIM = N
  run_list(st_root(), "")
  if (I <= LIM) bad("text after the end of the command")
  if (HZ != "") printf "H\t%s\n", clean(HZ)
  if (NOGUARD) print "N"
  print "E"
}

# ---------------------------------------------------------------- input
function unjson(s,   n, P, k, L, i, m, CH) {
  # One split into characters, then a walk over them. A substr per
  # character reads the whole string again each time in this awk, which
  # made a 170K command take seconds here before anything else ran.
  L = split(s, CH, ""); m = 0; i = 1
  while (i <= L) {
    m++; RP[m] = i - 1
    if (CH[i] == "\\" && i < L && CH[i + 1] ~ /[nrt"\\\/]/) i += 2; else i++
    RE[m] = i - 2
  }
  gsub(/\\\\/, "\002", s)
  if (index(s, "\\u")) bad("a \\u escape in the payload")
  gsub(/\\n/, "\n", s); gsub(/\\t/, "\t", s)
  gsub(/\\r/, "\r", s); gsub(/\\"/, "\"", s); gsub(/\\\//, "/", s)
  n = split(s, P, /\002/); S = P[1]
  for (k = 2; k <= n; k++) S = S "\\" P[k]
  N = split(S, C, "")
}
function append(t,   n, T, j, at) {
  at = N + 2; n = split(t, T, ""); C[N + 1] = "\n"
  for (j = 1; j <= n; j++) C[N + 1 + j] = T[j]
  S = S "\n" t; N = N + 1 + n
  return at
}
function bad(why) { if (HZ == "") HZ = "the reader could not follow " why }
function clean(t) { gsub(/[\t\n\r]/, " ", t); return t }

# ---------------------------------------------------------------- sets
# A set is its alternatives, each led by ALT. An alternative is a string and
# then any guards, each led by GRD: a guard names directories, ALL apart, and
# the alternative is impossible if every one of them exists.
function apath(a,   k) { k = index(a, GRD); return k ? substr(a, 1, k - 1) : a }
function agrd(a,   k) { k = index(a, GRD); return k ? substr(a, k) : "" }
function set_union(x, y,   n, A, k, c, L, seen, t, i, j, out) {
  n = split(x y, A, ALTRE); c = 0
  for (k = 2; k <= n; k++) {
    t = A[k]; if (index(apath(t), UNK)) t = UNK agrd(t)
    if (!(t in seen)) { seen[t] = 1; L[++c] = t }
  }
  # An alternative possible without condition makes its guarded copies moot.
  j = 0
  for (k = 1; k <= c; k++) { t = L[k]; if (index(t, GRD) && ((apath(t)) in seen)) continue; L[++j] = t }
  c = j
  if (c > 16) return ALT UNK
  for (i = 2; i <= c; i++) { t = L[i]; j = i - 1; while (j >= 1 && L[j] > t) { L[j + 1] = L[j]; j-- }; L[j + 1] = t }
  out = ""; for (k = 1; k <= c; k++) out = out ALT L[k]
  return out
}
function set_cat(x, y,   n, m, A, B, i, j, out, c) {
  n = split(x, A, ALTRE); m = split(y, B, ALTRE); out = ""; c = 0
  for (i = 2; i <= n; i++) for (j = 2; j <= m; j++) {
    if (++c > 16) return ALT UNK
    out = out ALT apath(A[i]) apath(B[j]) agrd(A[i]) agrd(B[j])
  }
  return out
}
function addg(x, g,   n, A, k, out) {
  if (g == "") return x
  n = split(x, A, ALTRE); out = ""
  for (k = 2; k <= n; k++) out = out ALT A[k] g
  return out
}
function one(x,   n, A) {
  n = split(x, A, ALTRE)
  if (n != 2 || index(A[2], GRD) || index(A[2], UNK)) return UNK
  return A[2]
}
function known(x,   n, A, k) {
  n = split(x, A, ALTRE)
  for (k = 2; k <= n; k++) if (index(apath(A[k]), UNK)) return 0
  return n >= 2
}

# ---------------------------------------------------------------- state
# A state is where the shell stands on one path through the command: its
# directory (WD), the one before (OLD), what it has printed (OUT, for a
# command substitution), errexit (EE), the condition it exists under (GS),
# and its variables. A state never changes once made.
function st_new() { NS++; DEAD[NS] = 0; WD[NS] = ALT UNK; OLD[NS] = ALT UNK; OUT[NS] = ALT; EE[NS] = 0; GS[NS] = ""; MADE[NS] = ""; return NS }
function st_root(   s) {
  s = st_new(); WD[s] = ALT CWD0
  defvar(s, "HOME", ALT HOMEV, 1)
  if (TMPV != "") defvar(s, "TMPDIR", ALT TMPV, 1)
  return s
}
function defvar(s, n, v, x) {
  if (!(n in KNOWN)) { KNOWN[n] = 1; NAME[++NN] = n }
  V[s, n] = v; if (x) XP[s, n] = 1
  ASGN[++NA] = n
}
function st_copy(a,   s, k, n) {
  s = st_new(); DEAD[s] = DEAD[a]; WD[s] = WD[a]; OLD[s] = OLD[a]; OUT[s] = OUT[a]; EE[s] = EE[a]; GS[s] = GS[a]; MADE[s] = MADE[a]
  for (k = 1; k <= NN; k++) { n = NAME[k]; if ((a, n) in V) { V[s, n] = V[a, n]; if ((a, n) in XP) XP[s, n] = 1 } }
  return s
}
function getvar(s, n) {
  if (n == "PWD") return WD[s]
  if (n == "OLDPWD") return OLD[s]
  if (n == "RANDOM" || n == "SRANDOM" || n == "BASHPID") return ALT FRESH
  if ((s, n) in V) return V[s, n]
  return ALT UNK
}
function st_merge(a, b,   s, k, n, ia, ib, ga, gb) {
  if (DEAD[a]) return b
  if (DEAD[b] || a == b) return a
  s = st_new(); EE[s] = EE[a] && EE[b]; MADE[s] = both(MADE[a], MADE[b])
  if (GS[a] == GS[b]) { GS[s] = GS[a]; ga = ""; gb = "" } else { ga = GS[a]; gb = GS[b] }
  WD[s] = set_union(addg(WD[a], ga), addg(WD[b], gb))
  OLD[s] = set_union(addg(OLD[a], ga), addg(OLD[b], gb))
  OUT[s] = set_union(addg(OUT[a], ga), addg(OUT[b], gb))
  for (k = 1; k <= NN; k++) {
    n = NAME[k]; ia = ((a, n) in V); ib = ((b, n) in V)
    if (!ia && !ib) continue
    V[s, n] = set_union(addg(ia ? V[a, n] : ALT UNK, ga), addg(ib ? V[b, n] : ALT UNK, gb))
    if (((a, n) in XP) || ((b, n) in XP)) XP[s, n] = 1
  }
  return s
}
# A new shell: the directory, and only what was exported.
function st_child(a,   s, k, n) {
  s = st_new(); DEAD[s] = DEAD[a]; WD[s] = WD[a]; GS[s] = GS[a]; MADE[s] = MADE[a]
  for (k = 1; k <= NN; k++) { n = NAME[k]; if (((a, n) in XP) && ((a, n) in V)) { V[s, n] = V[a, n]; XP[s, n] = 1 } }
  return s
}
function st_forget(a,   s, k, n) {
  s = st_copy(a); WD[s] = ALT UNK; OLD[s] = ALT UNK; OUT[s] = ALT UNK
  for (k = 1; k <= NN; k++) { n = NAME[k]; if ((s, n) in V) V[s, n] = ALT UNK }
  return s
}
# Directories made on every path: the ones both sides made.
function both(x, y,   n, A, k, out) {
  if (x == y) return x
  n = split(x, A, ALTRE); out = ""
  for (k = 2; k <= n; k++) if (index(y ALT, ALT A[k] ALT)) out = out ALT A[k]
  return out
}
function made(s, p) { return index(MADE[s] ALT, ALT p ALT) && MADEAT[p] == DELN || (p in GMADE) && GMADE[p] == DELN }
# Something ran that can delete: nothing made before it is known to be there.
function deleted() { DELN++ }
function canon(s, x) { return set_union(addg(x, GS[s]), "") }

# ---------------------------------------------------------------- tokens
function skip_ws() {
  while (I <= LIM) {
    if (C[I] == " " || C[I] == "\t" || C[I] == "\r") { I++; continue }
    if (C[I] == "\\" && C[I + 1] == "\n") { I += 2; continue }
    if (C[I] == "#") { while (I <= LIM && C[I] != "\n") I++; continue }
    break
  }
}
# The next token, not consumed: an operator, "REDIR", "WORD" for a word with
# quoting in it, or the text of a plain word (which is how reserved words are
# recognised, only where a command starts).
function peek(   c, d, e, k, w) {
  skip_ws()
  if (I > LIM) return ""
  c = C[I]; d = (I < LIM) ? C[I + 1] : ""; e = (I + 1 < LIM) ? C[I + 2] : ""
  if (c == "\n") return "\n"
  if (c == ";") { if (d == ";") return (e == "&") ? ";;&" : ";;"; if (d == "&") return ";&"; return ";" }
  if (c == "&") { if (d == "&") return "&&"; if (d == ">") return "REDIR"; return "&" }
  if (c == "|") { if (d == "|") return "||"; if (d == "&") return "|&"; return "|" }
  if (c == "(" || c == ")") return c
  if (c == "<" || c == ">") return (d == "(") ? "WORD" : "REDIR"
  if (c ~ /[0-9]/) { k = I; while (k <= LIM && C[k] ~ /[0-9]/) k++; if (C[k] == "<" || C[k] == ">") return "REDIR" }
  w = ""; k = I
  while (k <= LIM && C[k] !~ /[ \t\n\r;&|()<>]/) { if (index("\"\047\\$`", C[k])) return "WORD"; w = w C[k]; k++ }
  return w
}
function skip_nl(   t) { while ((t = peek()) == "\n") eat_newline() }
function eat_newline(   k) {
  I++
  for (k = 1; k <= NPH; k++) if (!PH_DONE[k] && PH_RID[k] == RID) { PH_DONE[k] = 1; heredoc_body(k) }
}
function drop_pending(rid,   k) { for (k = 1; k <= NPH; k++) if (!PH_DONE[k] && PH_RID[k] == rid) PH_DONE[k] = 1 }

# ---------------------------------------------------------------- words
# Reads one word from I, running every command substitution in it against st
# as it goes, so their commands are read too. Their values are kept by the
# index of their `$` or backtick, for expand().
function read_word(st,   c, ws) {
  ws = I
  if ((C[I] == "<" || C[I] == ">") && C[I + 1] == "(") procsub(st)
  while (I <= LIM) {
    c = C[I]
    if (c == "(" && I > ws && C[I - 1] ~ /[=@!+*?]/) { paren_scan(); continue }
    if (c ~ /[ \t\n\r;&|()<>]/) break
    if (c == "\\") { I += 2; continue }
    if (c == SQ) { I++; while (I <= LIM && C[I] != SQ) I++; if (I > LIM) bad("an unterminated quote"); I++; continue }
    if (c == "$" && C[I + 1] == SQ) { I += 2; while (I <= LIM && C[I] != SQ) { if (C[I] == "\\") I++; I++ }; I++; continue }
    if (c == "\"") { I++; dq_scan(st); continue }
    if (c == "$" && C[I + 1] == "(") { dollar_paren(st); continue }
    if (c == "$" && C[I + 1] == "{") { brace_scan(); continue }
    if (c == BQ) { backtick(st); continue }
    I++
  }
  W_S = ws; W_E = I - 1
}
function paren_scan(   d) {
  d = 0
  while (I <= LIM) {
    if (C[I] == "\\") { I += 2; continue }
    if (C[I] == SQ) { I++; while (I <= LIM && C[I] != SQ) I++; I++; continue }
    if (C[I] == "$" && C[I + 1] == "(" || C[I] == BQ) bad("a command substitution in an array or pattern")
    if (C[I] == "(") d++
    if (C[I] == ")" && --d == 0) { I++; return }
    I++
  }
  bad("an unclosed parenthesis")
}
function dq_scan(st) {
  while (I <= LIM && C[I] != "\"") {
    if (C[I] == "\\") { I += 2; continue }
    if (C[I] == "$" && C[I + 1] == "(") { dollar_paren(st); continue }
    if (C[I] == "$" && C[I + 1] == "{") { brace_scan(); continue }
    if (C[I] == BQ) { backtick(st); continue }
    I++
  }
  if (I > LIM) bad("an unterminated quote")
  I++
}
function brace_scan(   d, c) {
  I += 2; d = 1
  while (I <= LIM && d > 0) {
    c = C[I]
    if (c == "\\") { I += 2; continue }
    if (c == SQ) { I++; while (I <= LIM && C[I] != SQ) I++; I++; continue }
    if (c == "$" && C[I + 1] == "(" || c == BQ) bad("a command substitution inside ${...}")
    if (c == "$" && C[I + 1] == "{") { d++; I += 2; continue }
    if (c == "}") d--
    I++
  }
  if (d > 0) bad("an unclosed ${")
}
function dollar_paren(st,   k, d, v) {
  k = I
  if (C[I + 2] == "(") {
    I += 3; d = 2
    while (I <= LIM && d > 0) {
      if (C[I] == "$" && C[I + 1] == "(" && C[I + 2] != "(" || C[I] == BQ) bad("a command substitution inside arithmetic")
      if (C[I] == "(") d++; else if (C[I] == ")") d--
      I++
    }
    SUBV[k] = ALT UNK; SUBE[k] = I - 1; return
  }
  I += 2
  v = subst_run(st, "|)|")
  if (I > LIM || C[I] != ")") bad("an unclosed $("); else I++
  SUBV[k] = v; SUBE[k] = I - 1
}
function procsub(st,   k) {
  k = I; I += 2
  subst_run(st, "|)|")
  if (I > LIM || C[I] != ")") bad("an unclosed process substitution"); else I++
  SUBV[k] = ALT "/dev/fd/63"; SUBE[k] = I - 1
}
function backtick(st,   k, e, t, esc, at, en, si, sl, v) {
  k = I; e = I + 1; esc = 0; t = ""
  while (e <= LIM && C[e] != BQ) {
    if (C[e] == "\\" && C[e + 1] ~ /[$`\\]/) { esc = 1; t = t C[e + 1]; e += 2; continue }
    t = t C[e]; e++
  }
  if (e > LIM) { bad("an unclosed backtick"); I = e; SUBV[k] = ALT UNK; SUBE[k] = LIM; return }
  if (esc) { at = append(t); en = at + length(t) - 1 } else { at = k + 1; en = e - 1 }
  si = I; sl = LIM; I = at; LIM = en
  v = subst_run(st, "")
  I = e + 1; LIM = sl
  SUBV[k] = v; SUBE[k] = e
}
# A command substitution or process substitution: a subshell whose value is
# what it printed, when that can be told.
function subst_run(st, stops,   s, r, rid) {
  s = st_copy(st); OUT[s] = ALT; EE[s] = 0; GS[s] = ""
  rid = RID; RID = ++RIDN
  r = run_list(s, stops)
  if (stops == "" && I <= LIM) bad("a command substitution")
  drop_pending(RID); RID = rid
  if (DEAD[r]) return ALT UNK
  return addg(OUT[r], GS[r])
}

# The value of the word C[ws..we] in state st: XSET, the set it can be;
# XTXT, its text with each substitution blanked; XSP, the spans of its own
# text; XGLOB, whether an unquoted glob or brace can change it.
function expand(ws, we, st,   i, c, lit, set, txt, dq, e, n, t, sp0) {
  set = ALT; lit = ""; txt = ""; dq = 0; XGLOB = 0; XSP = ""; sp0 = ws; i = ws
  while (i <= we) {
    c = C[i]
    if (c == "\\") {
      if (!dq) { if (C[i + 1] != "\n") lit = lit C[i + 1]; txt = txt c C[i + 1]; i += 2; continue }
      if (C[i + 1] ~ /[$`"\\]/) { lit = lit C[i + 1]; txt = txt c C[i + 1]; i += 2; continue }
      if (C[i + 1] == "\n") { i += 2; continue }
      lit = lit c; txt = txt c; i++; continue
    }
    if (c == SQ && !dq) {
      e = i + 1; while (e <= we && C[e] != SQ) e++
      lit = lit substr(S, i + 1, e - i - 1); txt = txt substr(S, i, e - i + 1); i = e + 1; continue
    }
    if (c == "$" && C[i + 1] == SQ && !dq) {
      e = i + 2; t = ""
      while (e <= we && C[e] != SQ) { if (C[e] == "\\") { t = t ansi(C[e + 1]); e += 2 } else { t = t C[e]; e++ } }
      lit = lit t; txt = txt substr(S, i, e - i + 1); i = e + 1; continue
    }
    if (c == "\"") { dq = !dq; txt = txt c; i++; continue }
    if ((c == "$" && C[i + 1] == "(") || c == BQ || ((c == "<" || c == ">") && C[i + 1] == "(" && !dq)) {
      set = set_cat(set, ALT lit); lit = ""
      set = set_cat(set, (i in SUBV) ? SUBV[i] : ALT UNK)
      txt = txt "$(_)"
      if (i > sp0) XSP = XSP " " sp0 "," (i - 1)
      i = ((i in SUBE) ? SUBE[i] : we) + 1; sp0 = i; continue
    }
    if (c == "$" && C[i + 1] == "{") {
      e = i + 2; n = 1
      while (e <= we && n > 0) { if (C[e] == "{") n++; else if (C[e] == "}") n--; if (n > 0) e++ }
      t = substr(S, i + 2, e - i - 2)
      set = set_cat(set, ALT lit); lit = ""; set = set_cat(set, param(t, st))
      txt = txt substr(S, i, e - i + 1); i = e + 1; continue
    }
    if (c == "$" && C[i + 1] ~ /[A-Za-z_]/) {
      e = i + 1; while (e <= we && C[e] ~ /[A-Za-z0-9_]/) e++
      n = substr(S, i + 1, e - i - 1)
      set = set_cat(set, ALT lit); lit = ""; set = set_cat(set, getvar(st, n))
      txt = txt "$" n; i = e; continue
    }
    if (c == "$" && C[i + 1] == "$") { lit = lit FRESH; txt = txt "$$"; i += 2; continue }
    if (c == "$" && C[i + 1] ~ /[0-9@*#?!-]/) {
      set = set_cat(set, ALT lit); lit = ""; set = set_cat(set, (C[i + 1] ~ /[0-9]/) ? getvar(st, C[i + 1]) : ALT UNK)
      txt = txt c C[i + 1]; i += 2; continue
    }
    if (!dq && (c == "*" || c == "?" || c == "[")) XGLOB = 1
    if (!dq && c == "{" && index(substr(S, i, we - i + 1), "}")) XGLOB = 1
    if (!dq && c == "~" && i == ws) {
      e = i + 1; while (e <= we && C[e] != "/") e++
      set = set_cat(set, (e == i + 1) ? getvar(st, "HOME") : ALT UNK)
      txt = txt substr(S, i, e - i); i = e; continue
    }
    lit = lit c; txt = txt c; i++
  }
  set = set_cat(set, ALT lit)
  if (we >= sp0) XSP = XSP " " sp0 "," we
  XSET = set; XTXT = txt
}
function ansi(c) { if (c == "n") return "\n"; if (c == "t") return "\t"; if (c == "\\" || c == SQ || c == "\"") return c; return UNK }
function param(t, st,   n, v) {
  if (t ~ /^([A-Za-z_][A-Za-z0-9_]*|[0-9])$/) return getvar(st, t)
  if (t ~ /^[A-Za-z_][A-Za-z0-9_]*:?-/) {
    n = t; sub(/:?-.*/, "", n); v = getvar(st, n)
    if (known(v) && index(v, ALT ALT) == 0 && substr(v, 1, 2) != ALT GRD && v != ALT) return v
  }
  return ALT UNK
}

# ---------------------------------------------------------------- places
function join(base, rel,   p, n, A, k, out, b) {
  p = apath(rel)
  if (index(p, UNK)) return ALT UNK agrd(rel)
  if (substr(p, 1, 1) == "/") return ALT rel
  n = split(base, A, ALTRE); out = ""
  for (k = 2; k <= n; k++) {
    b = apath(A[k])
    if (index(b, UNK) || substr(b, 1, 1) != "/") { out = out ALT UNK agrd(A[k]) agrd(rel); continue }
    out = out ALT b (p == "" ? "" : "/" p) agrd(A[k]) agrd(rel)
  }
  return out
}
function joinset(base, set,   n, A, k, out) {
  n = split(set, A, ALTRE); out = ""
  for (k = 2; k <= n; k++) out = out join(base, A[k])
  return out
}
# Every path in a value: split at = : , and blanks, so `of=/x` and `--dir=/x`
# are seen. A URL is not a place, unless it is file://.
function pieces(set, wd, glob, noup, text,   n, A, k, m, P, j, p, q, out) {
  out = ""; n = split(set, A, ALTRE)
  for (k = 2; k <= n; k++) {
    p = apath(A[k])
    if (text && p !~ /(^|[=:, \t\n])(\/|~)|(^|\/)\.\.(\/|$)/ && !index(p, UNK)) continue
    if (glob || index(p, UNK)) { out = out ALT UNK agrd(A[k]); continue }
    if (p ~ /^[A-Za-z][A-Za-z0-9+.-]*:\/\//) { if (p ~ /^file:\/\//) p = substr(p, 8); else continue }
    m = split(p, P, /[=:,\n\t ]/)
    for (j = 1; j <= m; j++) {
      q = P[j]
      if (q ~ /^-[A-Za-z]+\//) q = substr(q, index(q, "/"))
      if (q == "" || q ~ /^-/ || q ~ /^\/dev\/(null|zero|u?random|stdin|stdout|stderr|tty|fd\/[0-9]+)$/) continue
      if (q ~ /^~/) { if (q == "~" || q ~ /^~\//) q = one(getvar(EXPST, "HOME")) substr(q, 2); else q = UNK }
      if (noup && q !~ /^\// && (q ~ /(^|\/)\.\.(\/|$)/)) q = UNK
      if (text && q !~ /^\// && q !~ /(^|\/)\.\.(\/|$)/) continue
      out = out join(wd, q agrd(A[k]))
    }
  }
  return out
}
function target(set, wd, glob,   n, A, k, p, out) {
  out = ""; n = split(set, A, ALTRE)
  for (k = 2; k <= n; k++) {
    p = apath(A[k])
    if (p ~ /^\/dev\/(null|stdout|stderr|stdin|tty|fd\/[0-9]+)$/) continue
    if (glob) { out = out ALT UNK; continue }
    out = out join(wd, A[k])
  }
  return out
}
function spans(sp,   n, P, k, a, b, out) {
  n = split(sp, P, " "); out = ""
  for (k = 1; k <= n; k++) {
    if (P[k] == "") continue
    split(P[k], AB, ","); a = AB[1] + 0; b = AB[2] + 0
    if (b < a) continue
    if (b > N0) return "-"
    out = out " " RP[a] "," RE[b]
  }
  return out == "" ? "-" : substr(out, 2)
}
# One command, as bash sees it: kind p (judge its places if the rule matches
# its text), u (cannot be told if the rule matches), m (judge its places
# whether the rule matches or not).
function emit(kind, why, txt, pl, sp, st) {
  if (!EMIT) return
  if (GS[st] != "") pl = addg(pl, GS[st])
  gsub(/[\t\n\r]/, UNK, pl); sub(/^ +/, "", txt)
  printf "C\t%s\t%s\t%s\t%s\t%s\n", kind, clean(why), clean(txt), pl, spans(sp)
}

# ---------------------------------------------------------------- lists
function run_list(st, stops,   cur, pre, t, r, at) {
  cur = st; L_S = st; L_F = DEADST
  while (1) {
    t = peek()
    while (t == "\n" || t == ";") { if (t == "\n") eat_newline(); else I++; t = peek() }
    if (t == "") break
    if (index(stops, "|" t "|")) break
    if (t == ")" || t == ";;" || t == ";&" || t == ";;&" || t ~ /^(then|elif|else|fi|do|done|esac|\})$/) { bad("an unexpected " t); break }
    pre = cur; at = I
    r = run_andor(cur)
    if (I == at) { bad("a command it could not read"); I++; continue }
    t = peek()
    if (t == "&") { I++; cur = pre; L_S = pre; L_F = DEADST; continue }
    cur = r; L_S = AO_S; L_F = AO_F
    if (t == ";") { I++; continue }
    if (t == "\n") { eat_newline(); continue }
    break
  }
  return cur
}
function run_andor(st,   s, f, t, n) {
  run_pipeline(st); s = P_S; f = P_F; n = 1
  while (1) {
    t = peek()
    if (t == "&&") { I += 2; skip_nl(); run_pipeline(s); f = st_merge(f, P_F); s = P_S; n++; continue }
    if (t == "||") { I += 2; skip_nl(); run_pipeline(f); s = st_merge(s, P_S); f = P_F; n++; continue }
    break
  }
  if (n == 1 && !COND && !DEAD[f] && EE[f]) f = DEADST
  AO_S = s; AO_F = f
  return st_merge(s, f)
}
function run_pipeline(st,   neg, n, t, s, f, pp, ls, lf, m) {
  neg = 0; t = peek()
  if (t == "time") { I += 4; skip_ws(); if (C[I] == "-" && C[I + 1] == "p") I += 2; t = peek() }
  if (t == "!") { neg = 1; I++; COND++ }
  pp = PIPEPOS; PIPEPOS = 1; n = 1
  run_command(st); s = RS_S; f = RS_F
  while (1) {
    t = peek()
    if (t == "|" || t == "|&") { I += length(t); skip_nl(); n++; PIPEPOS = n; run_command(st); ls = RS_S; lf = RS_F; continue }
    break
  }
  PIPEPOS = pp
  if (n > 1) { m = st_merge(st, st_merge(ls, lf)); s = m; f = m }
  if (neg) { COND--; t = s; s = f; f = t }
  P_S = s; P_F = f
}

# ---------------------------------------------------------------- compounds
function run_command(st,   t, r, pre) {
  t = peek(); pre = st
  if (t == "(" && C[I + 1] == "(") { arith_cmd(st); return }
  if (t == "(") {
    I++; r = st_copy(st); r = run_list(r, "|)|")
    if (peek() != ")") bad("an unclosed ("); else I++
    if (!DEAD[r] && MADE[r] != MADE[st]) { t = st_copy(st); MADE[t] = MADE[r]; st = t }
    RS_S = st; RS_F = st; after_compound(pre); return
  }
  if (t == "{") {
    I++; r = run_list(st, "|}|")
    if (peek() != "}") bad("an unclosed {"); else I++
    RS_S = r; RS_F = r; after_compound(pre); return
  }
  if (t == "if") { run_if(st); after_compound(pre); return }
  if (t == "while" || t == "until") { run_while(st); after_compound(pre); return }
  if (t == "for" || t == "select") { run_for(st); after_compound(pre); return }
  if (t == "case") { run_case(st); after_compound(pre); return }
  if (t == "function") { I += 8; skip_ws(); read_word(st); FNAME = substr(S, W_S, W_E - W_S + 1); skip_ws(); if (C[I] == "(" && C[I + 1] == ")") I += 2; fundef(FNAME, st); return }
  if (t == "[[") { cond_cmd(st); return }
  run_simple(st)
}
function arith_cmd(st,   d, e, t, n, T, k, r) {
  e = I + 2; d = 2
  while (e <= LIM && d > 0) {
    if (C[e] == "$" && C[e + 1] == "(" || C[e] == BQ) bad("a command substitution inside (( ))")
    if (C[e] == "(") d++; else if (C[e] == ")") d--
    e++
  }
  t = substr(S, I, e - I); I = e
  r = st_copy(st); n = split(t, T, /[^A-Za-z0-9_]+/)
  for (k = 1; k <= n; k++) if (T[k] in KNOWN) V[r, T[k]] = ALT UNK
  RS_S = r; RS_F = r
}
function cond_cmd(st,   c) {
  I += 2
  while (I <= LIM) {
    c = C[I]
    if (c == "]" && C[I + 1] == "]" && (I + 2 > LIM || C[I + 2] ~ /[ \t\n;&|)]/)) { I += 2; RS_S = st; RS_F = st; return }
    if (c == "\\") { I += 2; continue }
    if (c == SQ) { I++; while (I <= LIM && C[I] != SQ) I++; I++; continue }
    if (c == "$" && C[I + 1] == "(" || c == BQ) bad("a command substitution inside [[ ]]")
    I++
  }
  bad("an unclosed [["); RS_S = st; RS_F = st
}
# Redirections after a compound command are set up before it runs, in the
# directory it was entered in.
function after_compound(pre,   pl, txt, sp, k, n, RO, RSX, REX, ROX, s0, f0) {
  n = 0; s0 = RS_S; f0 = RS_F
  while (peek() == "REDIR") { read_redir(pre, -1); n++; RO[n] = R_OP; RSX[n] = R_S; REX[n] = R_E; ROX[n] = R_OS }
  if (!n) return
  pl = ""; txt = ""; sp = ""
  for (k = 1; k <= n; k++) {
    txt = txt " " RO[k]
    if (RO[k] ~ /^<</) continue
    EXPST = pre; expand(RSX[k], REX[k], pre)
    if (RO[k] ~ />|<>/ && !(RO[k] ~ /&$/ && one(XSET) ~ /^([0-9]+|-)$/)) pl = pl target(XSET, WD[pre], XGLOB)
    txt = txt " " XTXT; sp = sp " " ROX[k] "," (RSX[k] - 1) XSP
  }
  emit("p", "", txt, pl, sp, pre)
  RS_S = s0; RS_F = f0
}
function run_if(st,   s, f, res, t) {
  I += 2; COND++; run_list(st, "|then|"); s = L_S; f = L_F; COND--
  if (peek() != "then") { bad("if without then"); RS_S = st; RS_F = st; return }
  I += 4; res = run_list(s, "|elif|else|fi|")
  while (1) {
    t = peek()
    if (t == "elif") {
      I += 4; COND++; run_list(f, "|then|"); s = L_S; f = L_F; COND--
      if (peek() != "then") { bad("elif without then"); break }
      I += 4; res = st_merge(res, run_list(s, "|elif|else|fi|")); continue
    }
    if (t == "else") { I += 4; res = st_merge(res, run_list(f, "|fi|")); f = DEADST; t = peek() }
    if (t == "fi") { I += 2; res = st_merge(res, f); break }
    bad("if without fi"); break
  }
  RS_S = res; RS_F = res
}
function loop_open() { LD++; BRK[LD] = DEADST; CNT[LD] = DEADST }
# Loops are read twice: once silently, to learn where the first pass leaves
# the shell, and then for real from the union of that and where it started.
# If a third pass would start somewhere new, what changed is not known.
function run_while(st,   until, bs, em, s, f, r1, e2, r2, res, e3) {
  until = (peek() == "until"); I += 5; bs = I; em = EMIT
  EMIT = 0; loop_open()
  COND++; run_list(st, "|do|"); COND--; s = until ? L_F : L_S
  if (peek() != "do") { bad("while without do"); LD--; EMIT = em; RS_S = st; RS_F = st; return }
  I += 2; r1 = run_list(s, "|done|"); r1 = st_merge(r1, CNT[LD]); LD--
  e2 = st_merge(st, r1)
  I = bs; EMIT = em; loop_open()
  COND++; run_list(e2, "|do|"); COND--; s = until ? L_F : L_S; f = until ? L_S : L_F
  I += 2; r2 = run_list(s, "|done|"); r2 = st_merge(r2, CNT[LD])
  if (peek() != "done") bad("while without done"); else I += 4
  res = st_merge(f, st_merge(r2, BRK[LD])); LD--
  e3 = st_merge(st, r2)
  RS_S = widen(res, e2, e3); RS_F = RS_S
}
function widen(res, a, b,   s, k, n) {
  s = st_copy(res)
  if (canon(a, WD[a]) != canon(b, WD[b])) WD[s] = ALT UNK
  for (k = 1; k <= NN; k++) { n = NAME[k]; if (canon(a, getvar(a, n)) != canon(b, getvar(b, n))) V[s, n] = ALT UNK }
  return s
}
function run_for(st,   sel, vn, vals, t, closer, bs, em, e1, r1, e2, r2, res, e3) {
  sel = (peek() == "select"); I += sel ? 6 : 3; skip_ws(); vn = ""
  if (C[I] == "(" && C[I + 1] == "(") { arith_cmd(st); vals = "" }
  else {
    read_word(st); vn = substr(S, W_S, W_E - W_S + 1)
    if (vn !~ /^[A-Za-z_][A-Za-z0-9_]*$/) bad("a for loop over " vn)
    skip_nl(); t = peek(); vals = ""
    if (t == "in") {
      I += 2
      while (1) {
        t = peek(); if (t == ";" || t == "\n" || t == "" || t == "REDIR" || t == "(" || t == ")") break
        read_word(st); EXPST = st; expand(W_S, W_E, st); vals = set_union(vals, XGLOB ? ALT UNK : XSET)
      }
    } else vals = ALT UNK
    if (sel) vals = ALT UNK
  }
  t = peek(); if (t == ";") I++
  skip_nl(); t = peek(); closer = "done"
  if (t == "do") I += 2
  else if (t == "{") { I++; closer = "}" }
  else { bad("for without do"); RS_S = st; RS_F = st; return }
  bs = I; em = EMIT
  e1 = st_copy(st); if (vn != "") defvar(e1, vn, vals == "" ? ALT UNK : vals, ((st, vn) in XP))
  EMIT = 0; loop_open(); r1 = run_list(e1, "|" closer "|"); r1 = st_merge(r1, CNT[LD]); LD--
  e2 = st_merge(e1, r1); if (vn != "") { e2 = st_copy(e2); V[e2, vn] = (vals == "" ? ALT UNK : vals) }
  I = bs; EMIT = em; loop_open(); r2 = run_list(e2, "|" closer "|"); r2 = st_merge(r2, CNT[LD])
  if (peek() != closer) bad("for without " closer); else I += length(closer)
  res = st_merge(r2, BRK[LD]); LD--
  if (vals == "" || !known(vals)) res = st_merge(res, st)
  e3 = st_merge(e1, r2); if (vn != "") { e3 = st_copy(e3); V[e3, vn] = V[e2, vn] }
  RS_S = widen(res, e2, e3); RS_F = RS_S
}
function run_case(st,   res, t, b) {
  I += 4; skip_ws(); read_word(st); EXPST = st; expand(W_S, W_E, st); skip_nl()
  if (peek() != "in") { bad("case without in"); RS_S = st; RS_F = st; return }
  I += 2; res = st
  while (1) {
    skip_nl(); t = peek()
    if (t == "esac") { I += 4; break }
    if (t == "") { bad("case without esac"); break }
    if (t == "(") I++
    while (1) {
      t = peek()
      if (t == ")") { I++; break }
      if (t == "|") { I++; continue }
      if (t == "" || t == "\n" || t == ";") { bad("a case pattern"); RS_S = res; RS_F = res; return }
      read_word(st)
    }
    b = run_list(st, "|;;|;&|;;&|esac|"); res = st_merge(res, b)
    t = peek(); if (t == ";;" || t == ";&") I += 2; else if (t == ";;&") I += 3
  }
  RS_S = res; RS_F = res
}
# A function body runs where it is called, not where it is written, so it is
# read in an unknown directory with no variables; and a call to one that
# changes directory or assigns leaves those unknown.
function fundef(name, st,   b, cd0, na0, k, em) {
  skip_nl()
  b = st_new(); defvar(b, "HOME", getvar(st, "HOME"), 1); if ((st, "TMPDIR") in V) defvar(b, "TMPDIR", V[st, "TMPDIR"], 1)
  cd0 = CDN; na0 = NA
  run_command(b)
  FN[name] = 1; if (CDN != cd0) FCD[name] = 1
  FV[name] = ""; for (k = na0 + 1; k <= NA; k++) FV[name] = FV[name] " " ASGN[k]
  RS_S = st; RS_F = st
}

# ---------------------------------------------------------------- redirects
function read_redir(st, owner,   fd, c, raw, d, q, k, os, op) {
  os = I; fd = ""
  while (C[I] ~ /[0-9]/) { fd = fd C[I]; I++ }
  c = C[I]
  if (c == "&") { if (C[I + 2] == ">") { op = "&>>"; I += 3 } else { op = "&>"; I += 2 } }
  else if (c == "<") {
    if (C[I + 1] == "<" && C[I + 2] == "<") { op = "<<<"; I += 3 }
    else if (C[I + 1] == "<" && C[I + 2] == "-") { op = "<<-"; I += 3 }
    else if (C[I + 1] == "<") { op = "<<"; I += 2 }
    else if (C[I + 1] == ">") { op = "<>"; I += 2 }
    else if (C[I + 1] == "&") { op = "<&"; I += 2 }
    else { op = "<"; I++ }
  } else {
    if (C[I + 1] == ">") { op = ">>"; I += 2 }
    else if (C[I + 1] == "|") { op = ">|"; I += 2 }
    else if (C[I + 1] == "&") { op = ">&"; I += 2 }
    else { op = ">"; I++ }
  }
  skip_ws()
  if (op == "<<" || op == "<<-") {
    R_S = I; R_OS = os; R_OP = op; R_FD = fd
    while (I <= LIM && C[I] !~ /[ \t\n\r;&|()<>]/) {
      if (C[I] == SQ || C[I] == "\"") { q = C[I]; I++; while (I <= LIM && C[I] != q) I++; I++; continue }
      if (C[I] == "\\") { I += 2; continue }
      I++
    }
    R_E = I - 1; raw = substr(S, R_S, R_E - R_S + 1); d = raw
    gsub("[\"\047\\\\]", "", d)
    NPH++; PH_DELIM[NPH] = d; PH_STRIP[NPH] = (op == "<<-"); PH_Q[NPH] = (raw ~ "[\"\047\\\\]")
    PH_OWNER[NPH] = owner; PH_RID[NPH] = RID; PH_KIND[NPH] = "data"; PH_ST[NPH] = st; PH_XST[NPH] = st; PH_DONE[NPH] = 0; PH_BS[NPH] = 0
    R_PH = NPH
    return
  }
  read_word(st); R_S = W_S; R_E = W_E; R_OS = os; R_OP = op; R_FD = fd
}
function heredoc_body(k,   bs, e, line, found, ds) {
  bs = I; found = 0
  while (I <= LIM) {
    e = I; while (e <= LIM && C[e] != "\n") e++
    line = substr(S, I, e - I); if (PH_STRIP[k]) sub(/^\t+/, "", line)
    if (line == PH_DELIM[k]) { found = 1; ds = I; I = e + 1; break }
    I = e + 1
  }
  if (!found) { ds = LIM + 1; I = LIM + 1 }
  PH_BS[k] = bs; PH_BE[k] = ds - 1
  if (PH_KIND[k] == "script") hd_script(k, PH_ST[k])
  else if (!PH_Q[k]) hd_scan(k, PH_XST[k], 0)
}
# An unquoted here-document is expanded by the shell that reads it: its
# substitutions run there, and a script read from it is the expanded text.
function hd_scan(k, st, want,   i, e, c, set, lit, si, sl, n) {
  si = I; sl = LIM; LIM = PH_BE[k]; i = PH_BS[k]; set = ALT; lit = ""
  while (i <= LIM) {
    c = C[i]
    if (c == "\\" && C[i + 1] ~ /[$`\\\n]/) { if (C[i + 1] != "\n") lit = lit C[i + 1]; i += 2; continue }
    if (c == "$" && C[i + 1] == "(" || c == BQ) {
      I = i; if (c == BQ) backtick(st); else dollar_paren(st)
      set = set_cat(set_cat(set, ALT lit), SUBV[i]); lit = ""; i = I; continue
    }
    if (c == "$" && C[i + 1] == "{") {
      I = i; brace_scan(); set = set_cat(set_cat(set, ALT lit), param(substr(S, i + 2, I - i - 3), st)); lit = ""; i = I; continue
    }
    if (c == "$" && C[i + 1] ~ /[A-Za-z_]/) {
      e = i + 1; while (e <= LIM && C[e] ~ /[A-Za-z0-9_]/) e++
      set = set_cat(set_cat(set, ALT lit), getvar(st, substr(S, i + 1, e - i - 1))); lit = ""; i = e; continue
    }
    if (c == "$" && C[i + 1] ~ /[0-9@*#?!-]/) { set = set_cat(set_cat(set, ALT lit), ALT UNK); lit = ""; i += 2; continue }
    lit = lit c; i++
  }
  I = si; LIM = sl
  if (want) { set = set_cat(set, ALT lit); HD_TEXT = one(set) }
}
function hd_script(k, st,   si, sl, at, rid) {
  if (PH_ACTIVE[k]) { bad("a script that runs itself"); return }
  si = I; sl = LIM; PH_ACTIVE[k] = 1
  if (PH_Q[k]) { I = PH_BS[k]; LIM = PH_BE[k] }
  else {
    hd_scan(k, PH_XST[k], 1)
    if (HD_TEXT == UNK) { bad("a script in a here-document it cannot expand"); PH_ACTIVE[k] = 0; return }
    at = append(HD_TEXT); I = at; LIM = at + length(HD_TEXT) - 1
  }
  rid = RID; RID = ++RIDN
  run_list(st, "")
  if (I <= LIM) bad("a script in a here-document")
  drop_pending(RID); RID = rid; I = si; LIM = sl; PH_ACTIVE[k] = 0
}

# ---------------------------------------------------------------- commands
function assign_at(ws, we,   k) {
  if (C[ws] !~ /[A-Za-z_]/) return 0
  k = ws + 1; while (k <= we && C[k] ~ /[A-Za-z0-9_]/) k++
  ANAME = substr(S, ws, k - ws); AIDX = 0
  if (C[k] == "[") { while (k <= we && C[k] != "]") k++; k++; AIDX = 1 }
  if (C[k] == "+" && C[k + 1] == "=") { AAPP = 1; AV = k + 2; return 1 }
  if (C[k] == "=") { AAPP = 0; AV = k + 1; return 1 }
  return 0
}
function run_simple(st,   nofn, rdpl, TY, WS, WE, ROS, RO, RFD, RPH, isexec, n, t, k, words, cst, txt, sp, nw, WV, WT, WG, WX, WSP, ENVN, ENVV, ne, ci, cw, base, w, pl, kind, why, s, f, redir_out, v, me, ph0, j, val, wd, tmp) {
  n = 0; words = 0; CMDN++; me = CMDN; ph0 = NPH
  while (1) {
    t = peek()
    if (t == "REDIR") { read_redir(st, me); n++; TY[n] = "R"; RO[n] = R_OP; RFD[n] = R_FD; WS[n] = R_S; WE[n] = R_E; ROS[n] = R_OS; RPH[n] = (R_OP ~ /^<<-?$/) ? R_PH : 0; continue }
    if (t == "" || t == "\n" || t == ";" || t == ";;" || t == ";&" || t == ";;&" || t == "&" || t == "&&" || t == "||" || t == "|" || t == "|&" || t == ")") break
    if (t == "(") {
      if (words == 1 && n == 1 && substr(S, WS[1], WE[1] - WS[1] + 1) ~ /^[A-Za-z_][A-Za-z0-9_.:-]*$/) {
        I++; skip_ws(); if (C[I] == ")") { I++; fundef(substr(S, WS[1], WE[1] - WS[1] + 1), st); return }
      }
      bad("a ( inside a command"); break
    }
    read_word(st); n++; WS[n] = W_S; WE[n] = W_E
    if (!words && assign_at(W_S, W_E)) TY[n] = "A"; else { TY[n] = "W"; words++ }
  }
  cst = st_copy(st); txt = ""; sp = ""; nw = 0; ne = 0; pl = ""
  for (k = 1; k <= n; k++) {
    if (TY[k] == "A") {
      assign_at(WS[k], WE[k]); EXPST = cst; expand(AV, WE[k], cst)
      val = (AIDX || AAPP || C[AV] == "(") ? ALT UNK : XSET
      if (XGLOB) val = ALT UNK
      if (words) { ENVN[++ne] = ANAME; ENVV[ne] = val }
      else { tmp = st_copy(cst); defvar(tmp, ANAME, val, ((cst, ANAME) in XP)); cst = tmp }
      txt = txt " " substr(S, WS[k], AV - WS[k]) XTXT; sp = sp " " WS[k] "," (AV - 1) XSP
      AVL[k] = val
    } else if (TY[k] == "W") {
      EXPST = st; expand(WS[k], WE[k], st); nw++
      WV[nw] = XSET; WT[nw] = XTXT; WG[nw] = XGLOB; WX[nw] = k; WSP[nw] = XSP
      txt = txt " " XTXT; sp = sp XSP
    } else {
      txt = txt " " RFD[k] RO[k]
      if (RPH[k]) { txt = txt " " substr(S, WS[k], WE[k] - WS[k] + 1); sp = sp " " ROS[k] "," WE[k]; continue }
      EXPST = st; expand(WS[k], WE[k], st); RV[me, k] = XSET; RG[me, k] = XGLOB
      txt = txt " " XTXT; sp = sp " " ROS[k] "," (WS[k] - 1) XSP
    }
  }
  # Redirections: where each goes, and whether stdout leaves the command.
  wd = WD[cst]; redir_out = 0; EXPST = cst
  for (k = 1; k <= n; k++) {
    if (TY[k] != "R" || RPH[k]) continue
    if (RO[k] ~ /^(>|>>|>\||&>|&>>|>&)$/ && (RFD[k] == "" || RFD[k] == "1")) redir_out = 1
    if (RO[k] ~ /&$/ && one(RV[me, k]) ~ /^([0-9]+|-)$/) continue
    if (RO[k] == "<<<") continue
    pl = pl target(RV[me, k], wd, RG[me, k])
    if (RO[k] ~ />|<>/ && one(RV[me, k]) != UNK) WROTE[fkey(one(RV[me, k]), wd)] = "other"
  }
  rdpl = pl
  if (!nw) {
    # Assignments alone: the directory and every path in the values.
    for (k = 1; k <= n; k++) if (TY[k] == "A") pl = pl pieces(AVL[k], wd, 0, 0, 1)
    emit("p", "", txt, pl, sp, st)
    RS_S = cst; RS_F = cst; claim_heredocs(ph0, me, "data", cst, cst, rdpl); return
  }
  # Wrappers that run the rest of the words as the command.
  ci = 1
  while (1) {
    base = cmdbase(WV[ci])
    if (base == UNK) { bad_cmd(WT[ci] ", a command whose name it cannot see"); emit("u", "its command word cannot be seen", txt, "", sp, st); RS_S = st_forget(cst); RS_F = RS_S; return }
    if (base == "command" || base == "builtin" || base == "nohup" || base == "time" || base == "exec") {
      if (base == "exec") isexec = 1
      if (base == "command" || base == "builtin") nofn = 1
      ci++; while (ci <= nw && one(WV[ci]) ~ /^-/) { if (base == "command" && one(WV[ci]) ~ /[vV]/) { ci = nw + 1; break }; ci++ }
    } else if (base == "nice") { ci++; if (one(WV[ci]) == "-n") ci += 2; else if (one(WV[ci]) ~ /^-/) ci++ }
    else if (base == "timeout") { ci++; while (ci <= nw && (w = one(WV[ci])) ~ /^-/) { ci += (w ~ /^-[sk]$/) ? 2 : 1 }; ci++ }
    else if (base == "stdbuf") { ci++; while (ci <= nw && one(WV[ci]) ~ /^-/) ci++ }
    else if (base == "env") {
      ci++
      while (ci <= nw) {
        w = one(WV[ci])
        if (w ~ /^-[iv0]+$/ || w == "--ignore-environment" || w == "-") { ci++; continue }
        if (w == "-u") { ci += 2; continue }
        if (w ~ /^-/) { bad_cmd("env " w); break }
        if (WT[ci] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { w = WT[ci]; w = substr(w, 1, index(w, "=")); ENVN[++ne] = substr(w, 1, length(w) - 1); ENVV[ne] = unprefix(WV[ci], length(w)); ci++; continue }
        break
      }
    } else break
    if (ci > nw) { emit("p", "", txt, rdpl, sp, st); RS_S = cst; RS_F = cst; claim_heredocs(ph0, me, "data", cst, cst, rdpl); return }
  }
  s = cst; f = cst; kind = "p"; why = ""
  # Under the AUTO_CD option of zsh a directory named as the command is entered. A path
  # in command position is written out, and the judge refuses one that is a
  # directory now.
  if (EMIT && WT[ci] ~ /\//) { n = split(joinset(wd, WV[ci]), T, ALTRE); for (k = 2; k <= n; k++) if (!index(T[k], UNK)) printf "X\t%s\n", apath(T[k]) }
  pl = rdpl ((base in DATATOOL || base in FILETOOL) ? "" : wd)
  for (j = ci + 1; j <= nw; j++) pl = pl pieces(WV[j], wd, WG[j], 0, base in DATATOOL)
  for (k = 1; k <= ne; k++) pl = pl pieces(ENVV[k], wd, 0, 0, 1)
  # A function runs before a builtin or a program of its name, so one called
  # cd or git is read as a function: what it does was read where it was
  # defined, in an unknown directory.
  if ((base in FN) && !nofn) {
    kind = "u"; why = "it calls the function " base; s = st_copy(cst); NOGUARD = 1
    if (base in FCD) WD[s] = ALT UNK
    split(FV[base], T, " "); for (j in T) if (T[j] != "") V[s, T[j]] = ALT UNK
    f = s
  }
  else if (base == "cd" || base == "chdir") {
    w = CDP || ((cst, "CDPATH") in V); for (k = 1; k <= ne; k++) if (ENVN[k] == "CDPATH") w = 1
    do_cd(cst, WV, WG, ci, nw, w); s = CD_S; f = CD_F
  }
  else if (base == "pushd" || base == "popd") { s = st_copy(cst); WD[s] = ALT UNK; f = s; CDN++ }
  else if (base ~ /^(export|declare|typeset|local|readonly)$/) { s = do_declare(cst, base, WV, WX, WS, WE, ci, nw); f = s }
  else if (base == "shift" || base == "set" && one(WV[ci + 1]) == "--") { s = st_copy(cst); for (j = 1; j <= 9; j++) V[s, j ""] = ALT UNK; f = s }
  else if (base == "unset") { s = st_copy(cst); for (j = ci + 1; j <= nw; j++) { w = one(WV[j]); if (w ~ /^-f/) break; if (w ~ /^[A-Za-z_][A-Za-z0-9_]*$/) defvar(s, w, ALT "", 0) }; f = s }
  else if (base == "set") { s = st_copy(cst); for (j = ci + 1; j <= nw; j++) { w = one(WV[j]); if (w ~ /^-[a-z]*e/ || (w == "errexit" && one(WV[j - 1]) == "-o")) EE[s] = 1; if (w ~ /^\+[a-z]*e/ || (w == "errexit" && one(WV[j - 1]) == "+o")) EE[s] = 0 }; f = s }
  else if (base == "printf" && one(WV[ci + 1]) == "-v") { s = st_copy(cst); w = one(WV[ci + 2]); if (w ~ /^[A-Za-z_][A-Za-z0-9_]*$/) defvar(s, w, ALT UNK, 0); else s = st_forget(cst); f = s }
  else if (base == "let") { s = st_copy(cst); for (j = ci + 1; j <= nw; j++) { w = one(WV[j]); n = split(w, T, /[^A-Za-z0-9_]+/); for (k = 1; k <= n; k++) if (T[k] in KNOWN) V[s, T[k]] = ALT UNK }; f = s }
  else if (base ~ /^(read|getopts|mapfile|readarray)$/) { s = st_copy(cst); for (j = ci + 1; j <= nw; j++) { w = one(WV[j]); if (w ~ /^-[pdtunNia]$/) { j++; continue }; if (w ~ /^[A-Za-z_][A-Za-z0-9_]*$/) defvar(s, w, ALT UNK, 0) }; f = s }
  else if (base == "eval") { bad_cmd("eval"); kind = "u"; why = "eval runs text it cannot follow"; s = st_forget(cst); f = s }
  else if (base == "source" || base == ".") {
    kind = "u"; why = base " runs a file it cannot see"
    if ((fkey(one(WV[ci + 1]), wd) in WROTE)) bad_cmd(base " of a file this command wrote")
    s = st_forget(cst); f = s; NOGUARD = 1
  }
  else if (base == "alias") { bad_cmd("alias"); s = st_forget(cst); f = s; kind = "u"; why = "alias" }
  else if (base ~ /^(exit|return|logout)$/) { s = DEADST; f = DEADST }
  else if (base == "break" || base == "continue") {
    if (LD > 0) { if (base == "break") BRK[LD] = st_merge(BRK[LD], cst); else CNT[LD] = st_merge(CNT[LD], cst) }
    s = DEADST; f = DEADST
  }
  else if (base in SHELLS) { do_shell(cst, WV, WX, WS, WE, ci, nw, ENVN, ENVV, ne, n, RO, me, ph0, rdpl); kind = SH_KIND; why = SH_WHY; pl = SH_PL; if (SH_TXT != "") { txt = SH_TXT; sp = SH_SP } }
  else if (base == "git") { do_git(cst, WV, ci, nw, ENVN, ENVV, ne); kind = GIT_KIND; why = GIT_WHY; pl = GIT_PL rdpl; if (GIT_M != "") emit("m", "", txt, GIT_M, "", st) }
  else if (base in FOREIGN || base == "find" && has_exec(WV, ci, nw)) { bad_cmd(base " running a command"); kind = "u"; why = base " runs a command"; NOGUARD = 1 }
  # A trap runs its text later: on DEBUG, ERR or RETURN between the commands
  # read here, so nothing after it is known.
  else if (base == "trap" && trap_unread(WV, ci, nw)) { bad_cmd("trap"); kind = "u"; why = "trap runs text between commands" }
  # An interpreter is known by what it is handed, not by its name: code in
  # an argument after -c, -e, -E, --eval or --command. The engine names no
  # language, and a list of them would miss the next one.
  else if (!(base in DATATOOL) && !(base in FILETOOL) && code_arg(WV, ci, nw)) { kind = "u"; why = base " runs code given in its arguments" }
  else if (base in RUNNER || base == "find") { kind = "u"; why = base " runs code whose effect cannot be told"; NOGUARD = 1 }
  else if (base == "mount") { bad_cmd("mount") }
  else if (base ~ /^(ln|link|mv)$/ || base == "cp" && has_link(WV, ci, nw)) {
    NOGUARD = 1; tmp = rdpl
    for (j = ci + 1; j <= nw; j++) tmp = tmp pieces(WV[j], wd, WG[j], base != "mv", 0)
    emit("m", "", txt, tmp, "", st)
  }
  if (base ~ /^(rm|rmdir|unlink|trash|shred)$/ || kind == "u") { NOGUARD = 1; deleted() }
  if (base == "mkdir" && !DEAD[s]) { tmp = do_mkdir(s, WV, ci, nw); if (tmp) { s = tmp; f = DEADST } }
  if (isexec) { s = DEADST; f = DEADST }
  emit(kind, why, txt, pl, sp, st)
  # What the command printed, for a command substitution around it.
  if (!redir_out && !DEAD[s]) {
    v = stdout_of(base, cst, WV, ci, nw)
    if (v != "keep") {
      v = (OUT[cst] == ALT) ? v : ALT UNK
      tmp = st_copy(s); OUT[tmp] = v; s = tmp
      if (!DEAD[f]) { tmp = st_copy(f); OUT[tmp] = v; f = tmp }
    }
  }
  claim_heredocs(ph0, me, (SH_STDIN == me) ? "script" : "data", (SH_STDIN == me) ? SH_CHILD : cst, cst, rdpl)
  RS_S = s; RS_F = f
}
# The name a command word runs under: the last part of every value it can
# have, which has to be the same known name for all of them. A directory the
# reader cannot see does not matter; the name decides what kind of thing runs.
function cmdbase(set,   n, A, k, p, b, r) {
  n = split(set, A, ALTRE); r = ""
  for (k = 2; k <= n; k++) {
    p = apath(A[k]); b = p; sub(/.*\//, "", b)
    if (b == "" || index(b, UNK) || b ~ /[ \t\n]/) return UNK
    if (r != "" && b != r) return UNK
    r = b
  }
  return (r == "") ? UNK : r
}
function unprefix(set, len,   n, A, k, out) {
  n = split(set, A, ALTRE); out = ""
  for (k = 2; k <= n; k++) out = out ALT substr(A[k], len + 1)
  return out
}
function bad_cmd(why) { if (HZ == "") HZ = "it runs " why ", which reads text as code the reader does not follow" }
# A file named two ways is one file: `./run.sh`, `run.sh` and `$D//run.sh`.
function fkey(p, wd) { if (p == UNK) return UNK; if (substr(p, 1, 1) != "/") p = apath(one(wd)) "/" p; return norm(p) }
function norm(p) { while (sub(/\/\.\//, "/", p)) ; while (sub(/\/\/+/, "/", p)) ; sub(/\/\.$/, "", p); return p }
# The here-documents this command opened: data, unless a shell reads them as
# its script. A file written from one is remembered, so a shell running that
# file later in the line reads the same text.
function claim_heredocs(ph0, me, kind, st, xst, rdpl,   k, n, A, j) {
  for (k = ph0 + 1; k <= NPH; k++) {
    if (PH_OWNER[k] != me) continue
    PH_KIND[k] = kind; PH_ST[k] = st; PH_XST[k] = xst
    if (kind == "data") { n = split(rdpl, A, ALTRE); for (j = 2; j <= n; j++) if (!index(apath(A[j]), UNK)) WROTE[norm(apath(A[j]))] = "hd" k }
  }
}
# mkdir -p makes every directory it names, and is taken to succeed: each is
# written out as an assumption the judge checks against the disk (its nearest
# existing parent is a writable directory), so a cd into one cannot fail.
function do_mkdir(s, WV, ci, nw,   j, w, p, set, n, A, k, out, paths, d) {
  p = 0; paths = ""
  for (j = ci + 1; j <= nw; j++) {
    w = one(WV[j])
    if (w ~ /^-[A-Za-z]*p/ || w == "--parents") { p = 1; continue }
    if (w ~ /^-/) { if (w ~ /^-m$/) j++; continue }
    set = joinset(WD[s], WV[j]); n = split(set, A, ALTRE)
    for (k = 2; k <= n; k++) { if (index(A[k], UNK) || agrd(A[k]) != "") return 0; paths = paths ALT A[k] }
  }
  if (!p || paths == "") return 0
  out = st_copy(s); n = split(paths, A, ALTRE)
  for (k = 2; k <= n; k++) {
    if (EMIT) printf "M\t%s\n", A[k]
    # -p makes every directory on the way, so each of those is there too.
    d = A[k]
    while (d ~ /\/[^\/]/) { MADE[out] = MADE[out] ALT d; MADEAT[d] = DELN; sub(/\/+[^\/]*\/*$/, "", d) }
  }
  return out
}
function code_arg(WV, ci, nw,   j) {
  for (j = ci + 1; j <= nw; j++) if (one(WV[j]) ~ /^(-c|-e|-E|--eval|--command)$/) return 1
  return 0
}
function trap_unread(WV, ci, nw,   j, w) {
  if (ci + 1 <= nw && one(WV[ci + 1]) == UNK) return 1
  for (j = ci + 2; j <= nw; j++) { w = one(WV[j]); if (w == UNK || w ~ /^(SIG)?(DEBUG|ERR|RETURN)$/) return 1 }
  return 0
}
function has_exec(WV, ci, nw,   j) { for (j = ci + 1; j <= nw; j++) if (one(WV[j]) ~ /^-(exec|execdir|ok|okdir)$/) return 1; for (j = ci + 1; j <= nw; j++) if (one(WV[j]) == "-delete") { NOGUARD = 1; deleted() }; return 0 }
function has_link(WV, ci, nw,   j, w) { for (j = ci + 1; j <= nw; j++) { w = one(WV[j]); if (w ~ /^-[A-Za-z]*[ls]/ || w ~ /^--(link|symbolic-link)$/) return 1 }; return 0 }
function do_cd(cst, WV, WG, ci, nw, cdp,   j, w, tgt, n, A, k, p, nwd, gi, B, m) {
  j = ci + 1
  while (j <= nw && (w = one(WV[j])) ~ /^-[LPe@qs]+$|^--$/) j++
  if (j > nw) tgt = getvar(cst, "HOME")
  else if (j < nw) tgt = ALT UNK
  else { w = one(WV[j]); tgt = (w == "-") ? ALT UNK : WV[j]; if (WG[j]) tgt = ALT UNK }
  n = split(tgt, A, ALTRE); nwd = ""
  for (k = 2; k <= n; k++) {
    p = apath(A[k])
    if (index(p, UNK)) { nwd = set_union(nwd, ALT UNK agrd(A[k])); continue }
    if (cdp && p !~ /^(\/|\.\.?(\/|$))/) { nwd = set_union(nwd, ALT UNK agrd(A[k])); continue }
    if (p == "") nwd = set_union(nwd, addg(WD[cst], agrd(A[k])))
    else nwd = set_union(nwd, join(WD[cst], A[k]))
  }
  CD_S = st_copy(cst); OLD[CD_S] = WD[cst]; WD[CD_S] = nwd; CDN++
  # Into a directory this command made on every path so far, with nothing
  # run since that can delete, a cd cannot fail.
  gi = 1; m = split(nwd, B, ALTRE)
  for (k = 2; k <= m; k++) if (agrd(B[k]) != "" || !made(cst, apath(B[k]))) gi = 0
  if (gi && m >= 2) { CD_F = DEADST; return }
  # If the cd fails the shell stays where it was, which is possible only if
  # a target it could have gone to does not exist.
  gi = ""; m = split(nwd, B, ALTRE)
  for (k = 2; k <= m; k++) { p = apath(B[k]); if (index(p, UNK)) { gi = ""; break }; gi = gi (gi == "" ? "" : ALL) p }
  CD_F = st_copy(cst); if (gi != "") GS[CD_F] = GS[cst] GRD gi
}
function do_declare(cst, base, WV, WX, WS, WE, ci, nw,   s, j, w, k, x, val) {
  s = st_copy(cst); x = (base == "export")
  for (j = ci + 1; j <= nw; j++) {
    w = one(WV[j])
    # A name reference makes an assignment to one name land on another.
    if (w ~ /^-/) { if (w ~ /n/) return st_forget(cst); if (w ~ /x/) x = 1; if (w ~ /f/) return s; continue }
    k = WX[j]
    if (assign_at(WS[k], WE[k])) {
      EXPST = cst; expand(AV, WE[k], cst); val = (AIDX || AAPP || XGLOB || C[AV] == "(") ? ALT UNK : XSET
      defvar(s, ANAME, val, x || ((cst, ANAME) in XP))
    } else if (w ~ /^[A-Za-z_][A-Za-z0-9_]*$/) {
      if (x) { if (!((s, w) in V)) defvar(s, w, ALT UNK, 1); else XP[s, w] = 1 }
      else if (!((s, w) in V)) defvar(s, w, ALT "", 0)
    }
  }
  return s
}
function stdout_of(base, cst, WV, ci, nw,   w, j, v, n, A, k, p) {
  if (base == "pwd") return WD[cst]
  if (base == "mktemp") return mktemp_of(cst, WV, ci, nw)
  if (base == "echo" && nw == ci + 1 && one(WV[nw]) !~ /^-/) return WV[nw]
  if (base == "printf" && nw == ci + 2 && one(WV[ci + 1]) ~ /^%s(\\n)?$/) return WV[nw]
  if ((base == "realpath" || base == "grealpath") && nw == ci + 1) return joinset(WD[cst], WV[nw])
  if (base == "readlink" && nw == ci + 2 && one(WV[ci + 1]) ~ /^-[fem]$/) return joinset(WD[cst], WV[nw])
  if (base == "dirname" && nw == ci + 1) {
    n = split(WV[nw], A, ALTRE); v = ""
    for (k = 2; k <= n; k++) { p = apath(A[k]); if (index(p, UNK) || p !~ /\//) { v = v ALT UNK; continue }; sub(/\/[^\/]*$/, "", p); v = v ALT (p == "" ? "/" : p) agrd(A[k]) }
    return v
  }
  if (base == "cd" && one(WV[nw]) == "-") return ALT UNK
  if (base in SILENT) return "keep"
  if (base == "git") return ALT UNK
  return ALT UNK
}
# mktemp makes a new name nobody has used: in the directory given to -p, in $TMPDIR
# for -t or no template, or beside its template.
function mktemp_of(cst, WV, ci, nw,   j, w, dir, tpl, tmp, t, d) {
  dir = ""; tpl = ""; t = 0; d = 0
  for (j = ci + 1; j <= nw; j++) {
    w = one(WV[j]); if (w == UNK) return ALT UNK
    if (w == "-p" || w == "--tmpdir") { if (w == "-p") { j++; dir = one(WV[j]) } else t = 1; continue }
    if (w ~ /^--tmpdir=/) { dir = substr(w, 10); continue }
    if (w == "-t") { t = 1; if (j < nw && one(WV[j + 1]) !~ /^-/) j++; continue }
    if (w ~ /^-[A-Za-z]*d/ || w == "--directory") { d = 1; continue }
    if (w ~ /^-/) continue
    tpl = w
  }
  if (dir == UNK) return ALT UNK
  tmp = one(getvar(cst, "TMPDIR")); if (tmp == UNK || tmp == "") tmp = "/tmp"
  if (dir == "" && (t || tpl == "")) dir = tmp
  if (dir == "" && tpl ~ /\//) { dir = tpl; sub(/\/[^\/]*$/, "", dir) }
  if (dir == "") dir = "."
  dir = one(join(WD[cst], dir))
  if (dir == UNK) return ALT UNK
  # mktemp does not make the directory it works in: that has to be there
  # now, or made before on every path.
  if (!made(cst, dir) && EMIT) printf "D\t%s\n", dir
  if (d) { GMADE[dir "/" MADEM] = DELN; return ALT dir "/" MADEM }
  return ALT dir "/" FRESH
}
function do_git(cst, WV, ci, nw, ENVN, ENVV, ne,   loc, gd, wt, j, w, kv, sub_, k, n) {
  loc = WD[cst]; gd = ""; wt = ""; GIT_KIND = "p"; GIT_WHY = ""; GIT_M = ""; j = ci + 1
  while (j <= nw) {
    w = one(WV[j])
    if (w == UNK) { GIT_KIND = "u"; GIT_WHY = "a git option cannot be seen"; break }
    if (w == "-C") { loc = joinset(loc, WV[j + 1]); j += 2; continue }
    if (w ~ /^--git-dir=/) { gd = gd joinset(loc, ALT substr(w, 11)); j++; continue }
    if (w == "--git-dir") { gd = gd joinset(loc, WV[j + 1]); j += 2; continue }
    if (w ~ /^--work-tree=/) { wt = wt joinset(loc, ALT substr(w, 13)); j++; continue }
    if (w == "--work-tree") { wt = wt joinset(loc, WV[j + 1]); j += 2; continue }
    if (w == "-c") {
      kv = tolower(one(WV[j + 1]))
      if (kv == UNK || kv ~ /^(alias\.|core\.worktree|core\.hookspath|core\.sshcommand|core\.fsmonitor|include\.|includeif\.)/) { GIT_KIND = "u"; GIT_WHY = "git -c " kv " changes what git runs" }
      j += 2; continue
    }
    if (w ~ /^--(exec-path|config-env)/) { GIT_KIND = "u"; GIT_WHY = "git " w; j++; continue }
    if (w ~ /^-/) { j++; continue }
    break
  }
  sub_ = (j <= nw) ? one(WV[j]) : ""
  if (sub_ == "push") { GIT_KIND = "u"; GIT_WHY = "git push writes a remote" }
  if (sub_ == "clean") { NOGUARD = 1; deleted() }
  if (GITENV) { GIT_KIND = "u"; GIT_WHY = "GIT_DIR is set in this environment" }
  GIT_PL = loc gd wt
  for (k = 1; k <= ne; k++) if (ENVN[k] ~ /^GIT_/) GIT_PL = GIT_PL pieces(ENVV[k], loc, 0, 0)
  for (k = 1; k <= NN; k++) { n = NAME[k]; if (n ~ /^GIT_/ && ((cst, n) in XP)) GIT_PL = GIT_PL pieces(getvar(cst, n), loc, 0, 0) }
  # A worktree or a separated git directory makes a new path part of an
  # existing repository, so where it goes must be throwaway too.
  if (sub_ == "worktree" || sub_ ~ /^(init|clone)$/) {
    for (k = j + 1; k <= nw; k++) if (sub_ == "worktree" && one(WV[j + 1]) ~ /^(add|move)$/ || one(WV[k]) ~ /^--separate-git-dir/) { GIT_M = loc; break }
    if (GIT_M != "") for (k = j + 1; k <= nw; k++) GIT_M = GIT_M pieces(WV[k], loc, 0, 0, 0)
  }
}
function do_shell(cst, WV, WX, WS, WE, ci, nw, ENVN, ENVV, ne, n, RO, me, ph0, rdpl,   j, w, cflag, sflag, k, child, key, t, a, b, si, sl, rid, wk, pl, tx, sp) {
  pl = rdpl WD[cst]; sh_set("p", "", pl, "", "")
  cflag = 0; sflag = 0; j = ci + 1
  while (j <= nw) {
    w = one(WV[j]); if (w == UNK) break
    if (w == "--" || w == "-") { j++; break }
    if (w ~ /^[-+]O?o$/ || w ~ /^--(rcfile|init-file)$/) { j += 2; continue }
    if (w ~ /^-[A-Za-z]+$/) { if (w ~ /c/) cflag = 1; if (w ~ /s/) sflag = 1; j++; continue }
    if (w ~ /^[-+]/) { j++; continue }
    break
  }
  child = st_child(cst)
  for (k = 1; k <= ne; k++) defvar(child, ENVN[k], ENVV[k], 1)
  if (cflag) {
    if (j > nw) return
    args(child, WV, cflag ? j + 2 : j + 1, nw)
    wk = WX[j]; a = WS[wk]; b = WE[wk]
    # A script quoted whole and holding nothing to expand is read in place,
    # so its commands keep their own place in the text.
    t = substr(S, a, b - a + 1)
    if (C[a] == SQ && C[b] == SQ && index(substr(t, 2, length(t) - 2), SQ) == 0) { a++; b-- }
    else if (C[a] == "\"" && C[b] == "\"" && substr(t, 2, length(t) - 2) !~ /[$`\\"]/) { a++; b-- }
    else {
      w = one(WV[j]); if (w == UNK) { bad_cmd("a shell script it cannot see"); sh_set("u", "a shell runs a script that cannot be seen", pl, "", ""); return }
      a = append(w); b = a + length(w) - 1
    }
    si = I; sl = LIM; rid = RID; RID = ++RIDN; I = a; LIM = b
    run_list(child, ""); if (I <= LIM) bad("the -c script of a shell")
    drop_pending(RID); RID = rid; I = si; LIM = sl
    tx = ""; sp = ""
    for (k = 1; k <= n; k++) if (k != wk) { tx = tx " " substr(S, WS[k], WE[k] - WS[k] + 1); if (WE[k] >= WS[k]) sp = sp " " WS[k] "," WE[k] }
    sh_set("p", "", pl, tx == "" ? " " : tx, sp)
    return
  }
  if (sflag || j > nw) {
    args(child, WV, j, nw)
    for (k = 1; k <= n; k++) if (RO[k] == "<<<") {
      EXPST = cst; expand(WS[k], WE[k], cst); w = one(XSET)
      if (w == UNK) { bad_cmd("a shell script it cannot see"); return }
      a = append(w); si = I; sl = LIM; rid = RID; RID = ++RIDN; I = a; LIM = a + length(w) - 1
      run_list(child, ""); drop_pending(RID); RID = rid; I = si; LIM = sl
      sh_set("p", "", pl, "", "")
      return
    }
    for (k = ph0 + 1; k <= NPH; k++) if (PH_OWNER[k] == me) { sh_set("p", "", pl, "", ""); SH_STDIN = me; SH_CHILD = child; return }
    if (PIPEPOS > 1) bad_cmd("a shell reading its script from a pipe")
    return
  }
  # A script file: read it if this command wrote it from a here-document.
  args(child, WV, j + 1, nw)
  key = fkey(one(WV[j]), WD[cst])
  if (key in WROTE) {
    if (WROTE[key] ~ /^hd/) { k = substr(WROTE[key], 3) + 0; if (PH_BS[k]) { hd_script(k, child); sh_set("p", "", pl, "", ""); return } }
    bad_cmd("a script file this command wrote")
  }
  sh_set("u", "a shell runs a script file", pl, "", ""); NOGUARD = 1
}
# The positional parameters of a new shell: the words after its script.
function args(child, WV, from, nw,   k) {
  for (k = 1; k <= 9; k++) V[child, k ""] = (from + k - 1 <= nw) ? WV[from + k - 1] : ALT ""
  for (k = 1; k <= 9; k++) if (!((k "") in KNOWN)) { KNOWN[k ""] = 1; NAME[++NN] = k "" }
}
function sh_set(k, w, p, t, s) { SH_KIND = k; SH_WHY = w; SH_PL = p; SH_TXT = t; SH_SP = s; SH_STDIN = 0 }
'
