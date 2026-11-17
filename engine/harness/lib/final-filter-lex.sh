# The lexer under final-filter.sh: a row's text as bash splits it, into words,
# operators and redirections, far enough for the parser there to follow its
# lists and pipelines.
#
# A word keeps its static value, with quotes and backslashes removed, so
# `'tail'`, `"tail"` and `\tail` all name tail. It records whether any of it
# was quoted, because a quoted `if` or `{` is not a reserved word, and whether
# it holds an expansion (`$x`, `$( )`, `${ }`, backticks, `<( )`), because a
# command named by an expansion is not one the parser can name. `|`, `;`, `&`
# and parentheses inside quotes or an expansion stay inside the word, which is
# the case text patterns got wrong: `grep -qE 'a|sort -u' f` has no pipe.
#
# A redirection takes its target word with it and never becomes an argument,
# so `tail 2>&1`, `tail>/dev/null` and `&>/dev/null tail` read as tail. It
# records whether it can fail by itself: one replacing standard input (`<`,
# `<<<`, `<>`, `<&`, `0>`), because a stage reading a file instead of its
# pipe can fail when the file is missing, and likewise one reading a file on
# any fd; a duplicate of anything but fd 1 or 2 (`>&0`, `>&3`, `>&-`,
# `2>&1-`), which may not be open or closes an output; an fd above 9; and a
# target that is a process substitution, which can close early, or that runs
# a command, whose status bash then keeps. A here-document sets FFERR: its body is on lines a row
# cannot hold, and a text this cannot read is admitted. So do `&>>` and
# `{fd}>`, which bash 3.2 cannot read or reads as a file name.
#
# FFVAR is set when the text expands a parameter that may be unset: under
# nounset, which commissioning runs with, that ends the check. The names the
# runners export, $?, $$, $# and $- are never unset, nor is ${name:-word} and
# its kin with a default; every other name counts, and so does any parameter
# inside $( ), backticks or arithmetic. A $'...'
# word with a backslash escape is read as an expansion: escapes are not
# decoded, so a command or option spelled with one is not one this can name.
#
# Tokens are kept per depth d, because a literal script handed to `sh -c` or
# `eval` is lexed and parsed in turn while its caller's words are still held.
# A newline is the operator `nl`, which the parser reads as `;` except after
# `&&`, `||` and `|`. `((` at a token start is one arithmetic token, found by
# its matching `))`; `((cd a) | b)`, which bash reads as nested subshells,
# fails that match and is admitted.

FELIX_FINAL_FILTER_LEX='
function ff_sq(s, i, n) {
  while (i <= n) { if (substr(s, i, 1) == "\047") return i + 1; i++ }
  return 0
}
function ff_bq(s, i, n,    c) {
  while (i <= n) { c = substr(s, i, 1); if (c == "\\") { i += 2; continue }; if (c == "`") return i + 1; i++ }
  return 0
}
function ff_ansi(s, i, n,    c, v, e) {
  v = ""; e = 0
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\\") { v = v substr(s, i + 1, 1); e = 1; i += 2; continue }
    if (c == "\047") { FFDQV = v; FFDQY = e; return i + 1 }
    v = v c; i++
  }
  return 0
}
# A word that can change what the shell does next, however it is quoted:
# pipefail, the variables that set options or say what a name runs, and a
# kill in any spelling (killall, killpg, os.kill), which can end the shell
# from any process the text starts.
function ff_bad(v) {
  return v ~ /[Pp][Ii][Pp][Ee]_?[Ff][Aa][Ii][Ll]|SHELLOPTS|BASHOPTS|BASH_ENV|BASH_CMDS|POSIXLY_CORRECT/ ||
    v ~ /(^|[^A-Za-z0-9_])PATH([^A-Za-z0-9_]|$)/ || v ~ /(^|[^A-Za-z0-9_-])p?kill/
}
# A text this does not read: one holding a word ff_bad names, a carriage
# return, arithmetic, or an expansion that can end the shell with an error,
# which every ${ } form can but ${name}, ${#name}, and ${name with :- - :+ +
# # ## % %% or /.
function ff_unsure(s,    t, i) {
  if (ff_bad(s) || s ~ /\r|\$\[|\(\(/) return 1
  t = s
  while ((i = index(t, "${"))) { t = substr(t, i + 2)
    if (t !~ /^(#[A-Za-z_][A-Za-z0-9_]*}|[A-Za-z_][A-Za-z0-9_]*(}|:?[-+]|##?|%%?|\/)|[0-9@*#?$!-](}|:?[-+]))/) return 1 }
  return 0
}
function ff_known(nm) { return index(" FELIX_PROJECT FELIX_PROJECT_NAME FELIX_MEMORY_DIR FELIX_ROOT_DIR HOME PATH PWD ", " " nm " ") > 0 }
# Whether the $ at i expands a parameter that may be unset.
function ff_var(s, i,    k, t) {
  k = substr(s, i + 1, 1)
  if (k == "{") { t = substr(s, i + 2)
    if (t ~ /^[A-Za-z_][A-Za-z0-9_]*:?[-=+]/) return 0
    return !(match(t, /^[A-Za-z_][A-Za-z0-9_]*}/) && ff_known(substr(t, 1, RLENGTH - 1))) }
  if (k ~ /[A-Za-z_]/) { t = substr(s, i + 1); match(t, /^[A-Za-z_][A-Za-z0-9_]*/); return !ff_known(substr(t, 1, RLENGTH)) }
  return k ~ /[0-9@*!]/
}
function ff_vars(t,    i) { for (i = 1; i <= length(t); i++) if (substr(t, i, 1) == "$" && ff_var(t, i)) return 1; return 0 }
# The same for a whole $( ), $(( )) or backtick text.
function ff_cs(t) { return substr(t, 1, 3) == "$((" ? t ~ /[A-Za-z_@*!]/ : ff_vars(substr(t, 2)) }
function ff_dq(s, i, n,    c, k, j, v, y) {
  v = ""; y = 0
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\"") { FFDQV = v; FFDQY = y; return i + 1 }
    if (c == "\\") { k = substr(s, i + 1, 1)
      if (k == "\n") { i += 2; continue }
      if (k == "$" || k == "`" || k == "\"" || k == "\\") { v = v k; i += 2; continue }
      v = v c; i++; continue }
    if (c == "`") { j = ff_bq(s, i + 1, n); if (!j) return 0; v = v substr(s, i, j - i); y = 1; if (ff_cs(substr(s, i, j - i))) FFVAR = 1; i = j; continue }
    if (c == "$") { k = substr(s, i + 1, 1)
      if (k == "(") { j = ff_paren(s, i + 2, n); if (!j) return 0; v = v substr(s, i, j - i); y = 1; if (ff_cs(substr(s, i, j - i))) FFVAR = 1; i = j; continue }
      if (k == "{") { j = ff_brace(s, i + 2, n); if (!j) return 0; v = v substr(s, i, j - i); y = 1; if (ff_var(s, i) || ff_vars(substr(s, i + 2, j - i - 3))) FFVAR = 1; i = j; continue }
      if (k != "" && index("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_@*#?$!-", k)) { y = 1; if (ff_var(s, i)) FFVAR = 1 } }
    v = v c; i++
  }
  return 0
}
function ff_paren(s, i, n,    c, d) {
  d = 1
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\\") { i += 2; continue }
    if (c == "\047") { i = ff_sq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "\"") { i = ff_dq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "`") { i = ff_bq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "(") d++
    if (c == ")" && --d == 0) return i + 1
    i++
  }
  return 0
}
function ff_brace(s, i, n,    c, d) {
  d = 1
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\\") { i += 2; continue }
    if (c == "\047") { i = ff_sq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "\"") { i = ff_dq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "`") { i = ff_bq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "$" && substr(s, i + 1, 1) == "(") { i = ff_paren(s, i + 2, n); if (!i) return 0; continue }
    if (c == "$" && substr(s, i + 1, 1) == "{") { d++; i += 2; continue }
    if (c == "}" && --d == 0) return i + 1
    i++
  }
  return 0
}
function ff_arith(s, i, n,    c, d) {
  d = 2
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\047") { i = ff_sq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "\"") { i = ff_dq(s, i + 1, n); if (!i) return 0; continue }
    if (c == "(") d++
    if (c == ")") { d--; if (d == 1) return (substr(s, i + 1, 1) == ")") ? i + 2 : 0 }
    i++
  }
  return 0
}
function ff_word(s, i, n,    c, k, j, v, q, y, b) {
  v = ""; q = 0; y = 0; b = i
  while (i <= n) {
    c = substr(s, i, 1)
    if (index(" \t\n;&|()", c)) break
    if (c == "<" || c == ">") {
      if (i == b && substr(s, i + 1, 1) == "(") { j = ff_paren(s, i + 2, n); if (!j) return 0; v = v substr(s, i, j - i); y = 1; if (ff_cs(substr(s, i, j - i))) FFVAR = 1; i = j; continue }
      break }
    if (c == "\\") { q = 1; if (substr(s, i + 1, 1) != "\n") v = v substr(s, i + 1, 1); i += 2; continue }
    if (c == "\047") { j = ff_sq(s, i + 1, n); if (!j) return 0; v = v substr(s, i + 1, j - i - 2); q = 1; i = j; continue }
    if (c == "\"") { j = ff_dq(s, i + 1, n); if (!j) return 0; v = v FFDQV; if (FFDQY) y = 1; q = 1; i = j; continue }
    if (c == "`") { j = ff_bq(s, i + 1, n); if (!j) return 0; v = v substr(s, i, j - i); y = 1; if (ff_cs(substr(s, i, j - i))) FFVAR = 1; i = j; continue }
    if (c == "$") { k = substr(s, i + 1, 1)
      if (k == "\047") { j = ff_ansi(s, i + 2, n); if (!j) return 0; v = v FFDQV; if (FFDQY) y = 1; q = 1; i = j; continue }
      if (k == "\"") { j = ff_dq(s, i + 2, n); if (!j) return 0; v = v FFDQV; if (FFDQY) y = 1; q = 1; i = j; continue }
      if (k == "(") { j = ff_paren(s, i + 2, n); if (!j) return 0; v = v substr(s, i, j - i); y = 1; if (ff_cs(substr(s, i, j - i))) FFVAR = 1; i = j; continue }
      if (k == "{") { j = ff_brace(s, i + 2, n); if (!j) return 0; v = v substr(s, i, j - i); y = 1; if (ff_var(s, i) || ff_vars(substr(s, i + 2, j - i - 3))) FFVAR = 1; i = j; continue }
      if (k != "" && index("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_@*#?$!-", k)) { y = 1; if (ff_var(s, i)) FFVAR = 1 } }
    v = v c; i++
  }
  FFWV = v; FFWQ = q; FFWY = y; FFWR = substr(s, b, i - b)
  return i
}
function ff_tok(d, t, ty, v, q, y, r, st) {
  FFT[d, t] = ty; FFV[d, t] = v; FFQ[d, t] = q; FFY[d, t] = y; FFR[d, t] = r; FFS[d, t] = st
}
# A redirection at i, with an fd number or {name} before it, or none.
function ff_redir(s, i, n, d, t, fd,    op, st, j) {
  op = substr(s, i, 1); st = 0
  if (op == "<") {
    if (substr(s, i, 3) == "<<<") op = "<<<"
    else if (substr(s, i, 2) == "<<") { FFERR = 1; return 0 }
    else if (substr(s, i, 2) == "<>" || substr(s, i, 2) == "<&") op = substr(s, i, 2)
    st = 1
  } else {
    if (substr(s, i, 2) == ">>" || substr(s, i, 2) == ">|" || substr(s, i, 2) == ">&") op = substr(s, i, 2)
    if (fd == "0") st = 1
  }
  i += length(op)
  while (substr(s, i, 1) == " " || substr(s, i, 1) == "\t") i++
  j = ff_word(s, i, n)
  if (!j || j == i) { FFERR = 1; return 0 }
  if (FFWR ~ /^[<>]\(|\$\(|`/) st = 1
  if (op == ">&" && (FFWY || (FFWV ~ /^[0-9-]/ && FFWV !~ /^[12]$/))) st = 1
  if (fd != "" && fd + 0 > 9) st = 1
  ff_tok(d, t, "r", op, 0, 0, "", st)
  return j
}
function ff_lex(s, d,    n, i, c, c2, t, j, fd) {
  n = length(s); i = 1; t = 0
  while (i <= n) {
    c = substr(s, i, 1); c2 = substr(s, i, 2)
    if (c == " " || c == "\t") { i++; continue }
    if (c2 == "\\\n") { i += 2; continue }
    if (c == "\n") { ff_tok(d, ++t, "o", "nl"); i++; continue }
    if (c == "#") { while (i <= n && substr(s, i, 1) != "\n") i++; continue }
    if (substr(s, i, 3) == ";;&") { ff_tok(d, ++t, "o", ";;&"); i += 3; continue }
    if (c2 == "&&" || c2 == "||" || c2 == ";;" || c2 == ";&" || c2 == "|&") { ff_tok(d, ++t, "o", c2); i += 2; continue }
    if (c2 == "&>") { if (substr(s, i + 2, 1) == ">") { FFERR = 1; return 0 }; i += 2
      while (substr(s, i, 1) == " " || substr(s, i, 1) == "\t") i++
      j = ff_word(s, i, n); if (!j || j == i) return 0
      ff_tok(d, ++t, "r", "&>", 0, 0, "", FFWR ~ /^[<>]\(|\$\(|`/); i = j; continue }
    if (c == "|" || c == "&" || c == ";" || c == ")") { ff_tok(d, ++t, "o", c); i++; continue }
    if (c == "(") {
      if (substr(s, i + 1, 1) == "(") { j = ff_arith(s, i + 2, n); if (!j) return 0; if (substr(s, i, j - i) ~ /[A-Za-z_@*!]/) FFVAR = 1; ff_tok(d, ++t, "a", "(("); i = j; continue }
      ff_tok(d, ++t, "o", "("); i++; continue }
    if ((c == "<" || c == ">") && substr(s, i + 1, 1) != "(") { i = ff_redir(s, i, n, d, ++t, ""); if (!i) return 0; continue }
    j = ff_word(s, i, n); if (!j) return 0
    c = substr(s, j, 1)
    if ((c == "<" || c == ">") && substr(s, j + 1, 1) != "(" && !FFWQ && !FFWY && FFWV ~ /^([0-9]+|[{][A-Za-z_][A-Za-z0-9_]*[}])$/) {
      if (FFWV ~ /^[{]/) { FFERR = 1; return 0 }
      fd = FFWV; i = ff_redir(s, j, n, d, ++t, fd); if (!i) return 0; continue }
    ff_tok(d, ++t, "w", FFWV, FFWQ, FFWY, FFWR, 0); i = j
  }
  FFN[d] = t
  return 1
}
function ff_ty(k) { return (FFP[FFD] + k <= FFN[FFD]) ? FFT[FFD, FFP[FFD] + k] : "" }
function ff_is(k, v,    p) { p = FFP[FFD] + k; return p <= FFN[FFD] && FFT[FFD, p] == "o" && FFV[FFD, p] == v }
function ff_kw(k, v,    p) { p = FFP[FFD] + k; return p <= FFN[FFD] && FFT[FFD, p] == "w" && !FFQ[FFD, p] && FFV[FFD, p] == v }
function ff_end() { return FFP[FFD] > FFN[FFD] }
function ff_skipnl() { while (ff_is(0, "nl")) FFP[FFD]++ }
function ff_stop(stops,    p) {
  p = FFP[FFD]; if (p > FFN[FFD]) return 0
  if (FFT[FFD, p] == "w" && !FFQ[FFD, p]) return index(stops, " w:" FFV[FFD, p] " ") > 0
  if (FFT[FFD, p] == "o") return index(stops, " o:" FFV[FFD, p] " ") > 0
  return 0
}
function ff_redirs() { while (ff_ty(0) == "r") FFP[FFD]++ }
'
