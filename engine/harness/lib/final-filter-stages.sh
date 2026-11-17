# Which commands succeed whatever they read: the stage list under
# final-filter.sh. This file also resolves the name bash runs (ff_prefix) and
# models the builtins the parser reads (exit, set, eval, sh -c).
#
# ff_filter(name, a, b) answers for the command `name` with the arguments held
# in FFA[FFD, a..b]. It says yes only when, with those arguments, the command
# reads its standard input and nothing in that input can make it exit
# non-zero, on macOS and on GNU alike. A row runs on both: the founder's
# machine has BSD tools and bash 3.2, CI has GNU ones. So an option either
# platform rejects, a value it rejects, or a file operand makes the answer no,
# and a pipeline ending there is left alone. macOS getopt stops at the first
# operand, so an option after one is a file there; and a count of ten digits
# or more can overflow. Measured on macOS 26 against the GNU manuals:
#
#   cat, head, tail, sort, wc, cut, paste, nl, fold, rev, expand, unexpand
#                      read standard input only. `-` is standard input for
#                      cat, paste, sort, cut and nl on both; macOS head, tail,
#                      wc, fold, rev and expand open a file named "-". macOS
#                      takes no long option but head's, tail's and sort's.
#   head               -n and -c from 1, -NUM from 1: macOS refuses 0.
#   tail               -n, -c and -NUM, signed.
#   sort               -c, -C and --check fail on unsorted input; -k must
#                      start at field 1 and character 1 or later; -t is one
#                      character; two of -g -h -M -n -R -V, or one with -d or
#                      -i, globally or in one key, is refused by both.
#   uniq               no operand, or `-` and then its output file; GNU
#                      refuses -c with -D.
#   cut                one of -b, -c, -f, with a list from 1; -d is one
#                      character, and -d and -s only with -f.
#   paste              macOS needs an operand, so `-`.
#   nl, fold, expand   their values as both read them: a width from 1, tab
#                      stops ascending from 1, a numbering type a, t, n or p.
#   tee                its operands are its outputs, and a process
#                      substitution among them can close early, so only
#                      literal names.
#   tr                 its operands are sets, and it takes two, or one with
#                      -d or -s; any other count is a usage error, which
#                      fails every time.
#   sed                a script in view (the first operand, or -e), options
#                      -n -E -r -u only, and commands both seds take: p d =
#                      n N P D h H g G x, q without an exit code (GNU returns
#                      one on a match), s with its three delimiters and flags
#                      g, p and I once each or one count from 1 without g, y
#                      with sets of one length. No line 0, which GNU refuses.
#                      Brackets and groups balance, and no back-reference
#                      names a group that is not there.
#   awk                a program in view with its braces and parentheses
#                      balanced, no operand but `-` and assignments, none of
#                      them (nor -v) to a variable awk keeps itself such as
#                      NF or ARGV, and nothing in it that is fatal on some
#                      input: exit, printf, a division or modulo (by zero), a
#                      computed field `$(`, a field named by a variable, a `~`
#                      against anything but a regex literal, NF assigned, ARGV
#                      or ARGC, return, getline, system, close, split, sub, gsub,
#                      match, a call to anything but length, substr, index,
#                      tolower, toupper, int and the arithmetic functions, and
#                      any `<`, `>` or `|` inside an action, which is a
#                      redirection as often as a comparison.
#   true, :, echo      always.
#
# Left out, measured: tac (not on macOS); column (macOS fails on a line past
# about 2 KB); xargs (fails past an argument-size limit, and BSD has no -d).
#
# An option's value that is an expansion makes the answer no: empty or unset,
# it is a usage error. Some filters still fail for reasons that are not the
# command feeding them: an output file that cannot be opened, a byte BSD cut,
# tr, sed or sort rejects in a UTF-8 locale, a regular expression or tr set
# the platform rejects. Those say nothing about the work before the pipe, and
# the stage still counts. So does an awk program that is a syntax or type
# error this does not see, such as `END { next }`: it fails on every input on
# both platforms, so a row ending in one never passes, and it is refused with
# a reason that is wrong for it.

FELIX_FINAL_FILTER_STAGES='
# The index of the word bash runs, past the wrappers that run the rest, with
# its name in FFNAME; 0 when no name can be told, with FFPX "y" when it is an
# expansion and "n" when there is none. A relative path is a project script,
# whatever it is called. FFEXEC is set when exec runs it, FFBI when builtin
# does. stdbuf is not on macOS, and time after the start of a pipeline is
# /usr/bin/time, which a GNU host may lack, so neither is a wrapper.
function ff_prefix(nw,    i, v, b) {
  i = 1
  while (i <= nw) {
    if (FFAY[FFD, i]) { FFPX = "y"; return 0 }
    v = FFA[FFD, i]; b = v
    if (b ~ /^\//) sub(/.*\//, "", b); else if (index(b, "/")) return 0
    if (b == "command") { i++
      while (i <= nw && FFA[FFD, i] ~ /^-/) { if (FFA[FFD, i] == "--") { i++; break }; if (FFA[FFD, i] ~ /[vV]/) return 0; i++ }
      continue }
    if (b == "builtin") { i++; FFBI = 1; continue }
    if (b == "nohup") { i++; if (i <= nw && FFA[FFD, i] == "--") i++; continue }
    if (b == "exec") { i++; FFEXEC = 1
      while (i <= nw && FFA[FFD, i] ~ /^-/) { if (FFA[FFD, i] == "--") { i++; break }; if (FFA[FFD, i] ~ /a$/) i++; i++ }
      continue }
    if (b == "nice") { i++
      if (i < nw && FFA[FFD, i] == "-n") { i++; if (FFAY[FFD, i] || FFA[FFD, i] !~ /^[-+]?[0-9]+$/) return 0; i++ }
      else if (i <= nw && FFA[FFD, i] ~ /^-(n[-+]?)?[0-9]+$/) i++
      if (i <= nw && FFA[FFD, i] == "--") i++
      else if (i <= nw && FFA[FFD, i] ~ /^-/) return 0
      continue }
    if (b == "env") { i++
      while (i <= nw) {
        v = FFA[FFD, i]; if (FFAY[FFD, i]) return 0
        if (v == "--") { i++; break }
        if (v == "-" || v == "-i" || v == "--ignore-environment") { i++; continue }
        if (v == "-u" || v == "--unset") { i += 2; continue }
        if (v ~ /^(-u.|--unset=)/) { i++; continue }
        if (v ~ /^-/) return 0
        if (v ~ /^(PATH|SHELLOPTS|BASHOPTS|BASH_ENV)=/) return 0
        if (v ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { i++; continue }
        break }
      continue }
    FFNAME = b; return i
  }
  FFPX = "n"; return 0
}
# Every builtin of bash 3.2, and those this models or that change nothing but
# their own status. Any other can change what follows: hash, trap, shopt,
# readonly, ulimit, unset, return, source and the rest.
function ff_isbuiltin(nm) { return index(" : . [ alias bg bind break builtin caller cd command compgen complete continue declare dirs disown echo enable eval exec exit export false fc fg getopts hash help history jobs kill let local logout popd printf pushd pwd read readonly return set shift shopt source suspend test times trap true type typeset ulimit umask unalias unset wait ", " " nm " ") > 0 }
function ff_safe(nm) { return index(" : [ test true false echo printf cd pwd exit set eval exec type times umask wait read export local declare typeset ", " " nm " ") > 0 }
function ff_run(nm, i, nw, st,    p) {
  if (nm ~ /^(sh|bash|dash|ksh|mksh|zsh|ash|posh|yash)$/) return ff_shell(nm, i, nw)
  if (nm == "eval") return ff_eval(i, nw)
  if (nm == "exit") return ff_exit(i, nw)
  if (nm == "set") return ff_set(i, nw)
  if (nm == "false") return " n "
  if (nm == "printf" && FFA[FFD, i + 1] ~ /^-v/) { FFERR = 1; return " z n " }
  if (nm ~ /^(export|local|declare|typeset)$/)
    for (p = i + 1; p <= nw; p++) if (FFA[FFD, p] ~ /^[-+]/ && FFA[FFD, p] !~ /^-[xp]+$/) { FFERR = 1; return " z n " }
  if (!st && ff_filter(nm, i + 1, nw)) { FFFILT = nm; return " z " }
  return " z n "
}
function ff_exit(i, nw,    v) {
  if (i == nw) return " tq "
  if (i + 1 < nw) return " tz tn "
  v = FFAR[FFD, i + 1]
  if (v == "$?" || v == "\"$?\"") return " tq "
  if (FFAY[FFD, i + 1] || FFA[FFD, i + 1] !~ /^[0-9]+$/) return " tz tn "
  return (FFA[FFD, i + 1] + 0 == 0) ? " tz " : " tn "
}
# An option named by an expansion or by quoted text may be pipefail, and the
# check for that word reads the text as written.
function ff_optok(p, nw) {
  if (p > nw) return 1
  if (FFAY[FFD, p] || FFAR[FFD, p] != FFA[FFD, p] || FFA[FFD, p] ~ /[Pp][Ii][Pp][Ee]_?[Ff][Aa][Ii][Ll]/) { FFERR = 1; return 0 }
  return 1
}
# set succeeds with options it knows and fails with others. One spelled with
# quotes or an expansion may be errexit or nounset, which ff_text and
# ff_stage read from the text as written, so the text is admitted.
function ff_set(i, nw,    p, v) {
  for (p = i + 1; p <= nw; p++) {
    v = FFA[FFD, p]
    if (FFAY[FFD, p] || FFAR[FFD, p] != v) { FFERR = 1; return " z n " }
    if (v == "--" || v == "-") break
    if (v ~ /^[-+]o$/) {
      if (p == nw) break
      if (!ff_optok(++p, nw)) return " z n "
      if (FFA[FFD, p] == "posix") { FFERR = 1; return " z n " }
      if (!index(" allexport braceexpand emacs errexit errtrace functrace hashall histexpand history ignoreeof interactive-comments keyword monitor noclobber noexec noglob nolog notify nounset onecmd physical posix privileged verbose vi xtrace ", " " FFA[FFD, p] " ")) return " z n "
      continue }
    if (v !~ /^[-+][abefhkmnptuvxBCEHPT]+$/) { if (v ~ /^[-+]/) return " z n "; break }
  }
  return " z "
}
# A literal script given to sh, bash or dash with -c is read as that script,
# in POSIX mode but for bash without --posix or -o posix. Another shell, or
# one reading a startup file (-i, -l, --login, --rcfile), can run anything
# first.
function ff_shell(nm, i, nw,    j, v, c, ex, o, po) {
  if (nm !~ /^(sh|bash|dash)$/) return " z n "
  c = 0; ex = 0; po = nm != "bash"
  for (j = i + 1; j <= nw; j++) {
    v = FFA[FFD, j]; if (FFAY[FFD, j]) return " z n "
    if (v ~ /^[-+]/ && FFAR[FFD, j] != v) { FFERR = 1; return " z n " }
    if (v == "--" || v == "-") { j++; break }
    if (v ~ /^[-+]o$/) { if (!ff_optok(j + 1, nw)) return " z n "; if (FFA[FFD, j + 1] == "posix") po = 1; if (v == "-o" && j < nw && FFA[FFD, j + 1] == "errexit") ex = 1; j++; continue }
    if (v ~ /^--/) { if (v == "--posix") po = 1; else if (v !~ /^--(norc|noprofile)$/) return " z n "; continue }
    if (v ~ /^[-+][A-Za-z]+$/) { if (v ~ /[ilO]/) return " z n "; if (v ~ /^-.*c/) c = 1; if (v ~ /^-.*e/) ex = 1; continue }
    break
  }
  if (!c || j > nw || FFAY[FFD, j]) return " z n "
  o = ff_sub(ff_text(FFA[FFD, j], ex, po)); FFFILT = ""; return o
}
# eval of an expansion can run anything, exit included.
function ff_eval(i, nw,    j, t, o) {
  t = ""
  for (j = i + 1; j <= nw; j++) { if (FFAY[FFD, j]) return " z n tn "; t = t (t == "" ? "" : " ") FFA[FFD, j] }
  o = ff_text(t, FFEX[FFD], FFPOS[FFD]); FFFILT = ""; return o
}
# Options of a filter: arg are letters taking a value, ok the letters allowed,
# bad the letters that make it a check; lok and larg the long options allowed,
# larg those taking a value. opok 1 when operands are not files, dash 1 when an
# operand of - is standard input. Every value is kept, in order, in FFAL (the
# letter or long name) and FFAV; FFSEEN holds the letters and <names> seen.
function ff_opts(a, b, arg, ok, bad, lok, larg, opok, dash,    j, v, k, c, nm, val, seen) {
  FFON = 0; FFAN = 0; FFSEEN = ""; seen = 0
  for (j = a; j <= b; j++) {
    v = FFA[FFD, j]
    if (v == "--" && !seen) { for (j++; j <= b; j++) if (!ff_operand(j, opok, dash)) return 0; return ff_big() }
    if (v == "-" || v !~ /^-/ || (FFAY[FFD, j] && FFAR[FFD, j] !~ /^-/)) { if (!ff_operand(j, opok, dash)) return 0; seen = 1; continue }
    if (FFAY[FFD, j] || seen || v ~ /[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]/) return 0
    if (v ~ /^--/) { nm = substr(v, 3); sub(/=.*/, "", nm)
      if (index(lok, " " nm " ") && !index(v, "=")) { FFSEEN = FFSEEN "<" nm ">"; continue }
      if (!index(larg, " " nm " ")) return 0
      if (index(v, "=")) val = substr(v, index(v, "=") + 1)
      else { if (++j > b || FFAY[FFD, j]) return 0; val = FFA[FFD, j] }
      FFAL[++FFAN] = nm; FFAV[FFAN] = val; FFSEEN = FFSEEN "<" nm ">"; continue }
    for (k = 2; k <= length(v); k++) {
      c = substr(v, k, 1)
      if (index(bad, c)) return 0
      if (index(arg, c)) {
        if (k < length(v)) val = substr(v, k + 1)
        else { if (++j > b || FFAY[FFD, j]) return 0; val = FFA[FFD, j] }
        FFAL[++FFAN] = c; FFAV[FFAN] = val; FFSEEN = FFSEEN c; break }
      if (!index(ok, c)) return 0
      FFSEEN = FFSEEN c
    }
  }
  return ff_big()
}
# macOS getopt stops at the first operand, so an option after one is a file
# there; and a count of ten digits or more can overflow.
function ff_big(    k) {
  for (k = 1; k <= FFAN; k++) if (FFAV[k] ~ /[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]/) return 0
  return 1
}
function ff_operand(j, opok, dash) {
  FFO[++FFON] = FFA[FFD, j]; FFOY[FFON] = FFAY[FFD, j]
  return opok || (dash && FFA[FFD, j] == "-" && !FFAY[FFD, j])
}
# Whether every value given for one of the letters or names in `which` matches
# re. `which` is a list like " n lines ".
function ff_vals(which, re,    i) {
  for (i = 1; i <= FFAN; i++) if (index(which, " " FFAL[i] " ") && FFAV[i] !~ re) return 0
  return 1
}
function ff_has(which,    i) {
  for (i = 1; i <= FFAN; i++) if (index(which, " " FFAL[i] " ")) return 1
  return 0
}
# -NUM, the old count both head and tail take: from 1 for head.
function ff_oldnum(a, b, min,    j, v) {
  for (j = a; j <= b; j++) { v = FFA[FFD, j]; if (v == "--") break
    if (v ~ /^-[0-9]+$/ && substr(v, 2) + 0 < min) return 0 }
  return 1
}
function ff_filter(nm, a, b,    i, v, p) {
  if (nm == "true" || nm == ":" || nm == "echo") return 1
  if (nm == "cat") return ff_opts(a, b, "", "benstuv", "", "", "", 0, 1)
  if (nm == "head") return ff_opts(a, b, "nc", "0123456789", "", "", " lines bytes ", 0, 0) \
    && ff_vals(" n c lines bytes ", "^[1-9][0-9]*$") && !(ff_has(" n lines ") && ff_has(" c bytes ")) && ff_oldnum(a, b, 1)
  if (nm == "tail") return ff_opts(a, b, "nc", "0123456789", "", "", " lines bytes ", 0, 0) \
    && ff_vals(" n c lines bytes ", "^[-+]?[0-9]+$") && !(ff_has(" n lines ") && ff_has(" c bytes "))
  if (nm == "tee") { if (!ff_opts(a, b, "", "ai", "", "", "", 1, 1)) return 0
    for (i = 1; i <= FFON; i++) if (FFOY[i]) return 0
    return 1 }
  if (nm == "sort") return ff_opts(a, b, "kotTS", "bdfghiMnrRsuVzm", "cC", " ignore-leading-blanks dictionary-order ignore-case general-numeric-sort ignore-nonprinting month-sort human-numeric-sort numeric-sort random-sort reverse version-sort merge stable unique zero-terminated ", " key output field-separator temporary-directory buffer-size ", 0, 1) \
    && ff_vals(" k key ", "^[1-9][0-9]*(\\.[1-9][0-9]*)?[bdfgiMhnRrV]*(,[1-9][0-9]*(\\.[0-9]+)?[bdfgiMhnRrV]*)?$") \
    && ff_vals(" t field-separator ", "^.$") && ff_vals(" S buffer-size ", "^[0-9]+[%bKMGT]?$") && !ff_sortx()
  if (nm == "uniq") return ff_opts(a, b, "fs", "cdiuD", "", "", "", 1, 0) && ff_vals(" f s ", "^[0-9]+$") && !(index(FFSEEN, "c") && index(FFSEEN, "D")) \
    && (FFON == 0 || (FFON <= 2 && FFO[1] == "-" && !FFOY[1] && !FFOY[FFON]))
  if (nm == "wc") return ff_opts(a, b, "", "clmwL", "", "", "", 0, 0)
  if (nm == "tr") return ff_tr(a, b)
  if (nm == "cut") return ff_cut(a, b)
  if (nm == "paste") { if (!ff_opts(a, b, "d", "s", "", "", "", 0, 1) || !ff_vals(" d ", ".")) return 0
    return FFON >= 1 }
  if (nm == "nl") return ff_opts(a, b, "bdfhilnsvw", "p", "", "", "", 0, 1) && ff_vals(" b f h ", "^(a|t|n|p.+)$") \
    && ff_vals(" i l v ", "^[0-9]+$") && ff_vals(" w ", "^[1-9][0-9]*$") && ff_vals(" n ", "^(ln|rn|rz)$") && ff_vals(" d ", "^..?$")
  if (nm == "fold") return ff_opts(a, b, "w", "bs", "", "", "", 0, 0) && ff_vals(" w ", "^[1-9][0-9]*$")
  if (nm == "rev") return ff_opts(a, b, "", "", "", "", "", 0, 0)
  if (nm == "expand" || nm == "unexpand") {
    if (!ff_opts(a, b, "t", nm == "unexpand" ? "a" : "", "", "", "", 0, 0)) return 0
    for (i = 1; i <= FFAN; i++) { v = FFAV[i]; p = 0
      if (v !~ /^[1-9][0-9]*([, ][1-9][0-9]*)*$/) return 0
      while (match(v, /^[0-9]+/)) { if (substr(v, 1, RLENGTH) + 0 <= p) return 0; p = substr(v, 1, RLENGTH) + 0; v = substr(v, RLENGTH + 2) } }
    return 1 }
  if (nm == "sed") return ff_sed(a, b)
  if (nm ~ /^(awk|gawk|mawk|nawk)$/) return ff_awk(a, b)
  return 0
}
# Two orderings at once, or one with -d or -i, which both sorts refuse.
function ff_sortx(    s, i, v) {
  s = FFSEEN
  gsub(/<general-numeric-sort>/, "g", s); gsub(/<human-numeric-sort>/, "h", s); gsub(/<month-sort>/, "M", s)
  gsub(/<numeric-sort>/, "n", s); gsub(/<random-sort>/, "R", s); gsub(/<version-sort>/, "V", s)
  gsub(/<dictionary-order>/, "d", s); gsub(/<ignore-nonprinting>/, "i", s); gsub(/<[^>]*>/, "", s)
  if (ff_xkind(s)) return 1
  for (i = 1; i <= FFAN; i++) if (FFAL[i] == "k" || FFAL[i] == "key") { v = FFAV[i]; gsub(/[0-9.,]/, "", v); if (ff_xkind(v)) return 1 }
  return 0
}
function ff_xkind(s,    n, i) {
  n = 0; for (i = 1; i <= 6; i++) if (index(s, substr("ghMnRV", i, 1))) n++
  return n > 1 || (n == 1 && (index(s, "d") || index(s, "i")))
}
function ff_tr(a, b,    d, s) {
  if (!ff_opts(a, b, "", "cCds", "", "", "", 1, 1)) return 0
  d = index(FFSEEN, "d") > 0; s = index(FFSEEN, "s") > 0
  return FFON == 2 ? (!d || s) : (FFON == 1 && (d != s))
}
function ff_cut(a, b,    n, l) {
  if (!ff_opts(a, b, "bcfd", "ns", "", "", "", 0, 1)) return 0
  n = ff_has(" b ") + ff_has(" c ") + ff_has(" f ")
  if (n != 1) return 0
  l = "^([1-9][0-9]*(-([1-9][0-9]*)?)?|-[1-9][0-9]*)(,([1-9][0-9]*(-([1-9][0-9]*)?)?|-[1-9][0-9]*))*$"
  if (!ff_vals(" b c f ", l) || !ff_vals(" d ", "^.$")) return 0
  return ff_has(" f ") || (!ff_has(" d ") && !index(FFSEEN, "s"))
}
function ff_sed(a, b,    j, v, k, c, sc, got, opn, ere, scop) {
  sc = ""; got = 0; opn = 0; ere = 0; scop = 0
  for (j = a; j <= b; j++) {
    v = FFA[FFD, j]
    if (opn || v == "-" || v !~ /^-/ || (FFAY[FFD, j] && FFAR[FFD, j] !~ /^-/)) {
      if (!got) { if (FFAY[FFD, j]) return 0; sc = v; got = 1; scop = 1; continue }
      return 0 }
    if (scop) return 0
    if (v == "--") { opn = 1; continue }
    if (FFAY[FFD, j] || v ~ /^--/) return 0
    for (k = 2; k <= length(v); k++) {
      c = substr(v, k, 1)
      if (c == "e") {
        if (k < length(v)) v = substr(v, k + 1); else { if (++j > b || FFAY[FFD, j]) return 0; v = FFA[FFD, j] }
        sc = sc (sc == "" ? "" : "\n") v; got = 1
        break }
      if (c == "E" || c == "r") ere = 1
      else if (c != "n" && c != "u") return 0
    }
  }
  return got && ff_sedok(sc, ere)
}
# A script both seds take, as the stage list above names it.
function ff_sedok(s, ere,    n, i, c, d, p, re, rep, g, f) {
  n = length(s); i = 1
  while (i <= n) {
    c = substr(s, i, 1)
    if (index(" \t\n;", c)) { i++; continue }
    if (!(i = ff_sedaddr(s, i, ere))) return 0
    if (substr(s, i, 1) == ",") { if (!(i = ff_sedaddr(s, i + 1, ere)) || i == FFSA) return 0 }
    while (substr(s, i, 1) ~ /[ \t]/) i++
    if (substr(s, i, 1) == "!") { i++; while (substr(s, i, 1) ~ /[ \t]/) i++ }
    c = substr(s, i, 1); i++
    if (c == "s" || c == "y") {
      d = substr(s, i, 1); if (d == "" || d == "\\" || d == "\n") return 0
      if (!(p = ff_seddelim(s, i + 1, d))) return 0
      re = substr(s, i + 1, p - i - 1); i = p
      if (!(p = ff_seddelim(s, i + 1, d))) return 0
      rep = substr(s, i + 1, p - i - 1); i = p + 1
      if (c == "y" && (index(re rep, "\\") || length(re) != length(rep))) return 0
      if (c == "s") {
        if (!ff_reok(re, ere)) return 0
        g = FFGRP
        while (match(rep, /\\[0-9]/)) { if (substr(rep, RSTART + 1, 1) + 0 > g) return 0; rep = substr(rep, RSTART + 2) }
        f = ""; while (substr(s, i, 1) ~ /[gpI0-9]/) { f = f substr(s, i, 1); i++ }
        if (!ff_sflags(f)) return 0 }
    } else if (!index("pd=nNPDhHgGxq", c) || c == "") return 0
    while (substr(s, i, 1) ~ /[ \t]/) i++
    if (i <= n && !index(";\n", substr(s, i, 1))) return 0
  }
  return 1
}
# s flags both seds take: g, p and I once each, and one count from 1 without g.
function ff_sflags(f,    t, g) {
  t = f; g = gsub(/g/, "", t)
  if (g > 1 || gsub(/p/, "", t) > 1 || gsub(/I/, "", t) > 1) return 0
  return t == "" || (!g && t ~ /^[1-9][0-9]?[0-9]?$/ && f ~ /^[^0-9]*[0-9]+[^0-9]*$/)
}
function ff_sedaddr(s, i, ere,    p) {
  FFSA = i
  if (substr(s, i, 1) == "$") return i + 1
  if (substr(s, i) ~ /^[0-9]/) { p = i; while (substr(s, i, 1) ~ /[0-9]/) i++; return substr(s, p, i - p) + 0 ? i : 0 }
  if (substr(s, i, 1) == "/") {
    if (!(p = ff_seddelim(s, i + 1, "/")) || !ff_reok(substr(s, i + 1, p - i - 1), ere)) return 0
    return p + 1 }
  return i
}
# The index of the next unescaped d from i, outside a bracket expression.
function ff_seddelim(s, i, d,    n, c) {
  n = length(s)
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\\") { i += 2; continue }
    if (c == "\n") return 0
    if (c == d) return i
    i++
  }
  return 0
}
# Brackets close and groups balance; FFGRP is the number of groups. An empty
# alternative in an extended expression is refused by BSD.
function ff_reok(r, ere,    n, i, c, dep) {
  n = length(r); dep = 0; FFGRP = 0
  if (ere && (r ~ /^\|/ || r ~ /\|$/ || r ~ /\(\||\|\)|\|\|/)) return 0
  for (i = 1; i <= n; i++) {
    c = substr(r, i, 1)
    if (c == "[") {
      i++; if (substr(r, i, 1) == "^") i++
      if (substr(r, i, 1) == "]") i++
      while (i <= n && substr(r, i, 1) != "]") { if (substr(r, i, 2) ~ /^\[[:.=]/) { c = substr(r, i + 1, 1); i += 2; while (i <= n && substr(r, i, 2) != c "]") i++; i++ }; i++ }
      if (i > n) return 0
      continue }
    if (c == "\\") { c = substr(r, ++i, 1)
      if (!ere && c == "(") { dep++; FFGRP++ } else if (!ere && c == ")") { if (--dep < 0) return 0 }
      continue }
    if (ere && c == "(") { dep++; FFGRP++ } else if (ere && c == ")") { if (--dep < 0) return 0 }
  }
  return dep == 0
}
function ff_awk(a, b,    j, v, p, got) {
  got = 0
  for (j = a; j <= b; j++) {
    v = FFA[FFD, j]
    if (!got) {
      if (v == "--") continue
      if (v ~ /^-[Fv]/) {
        if (FFAY[FFD, j]) return 0
        if (length(v) == 2) { if (++j > b || FFAY[FFD, j]) return 0; p = FFA[FFD, j] } else p = substr(v, 3)
        if (v ~ /^-v/ && !ff_awkset(p)) return 0
        continue }
      if (v ~ /^-./) return 0
      if (FFAY[FFD, j]) return 0
      p = v; got = 1; continue }
    if ((v == "-" && !FFAY[FFD, j]) || ff_awkset(FFAR[FFD, j])) continue
    return 0
  }
  return got && ff_awkprog(p)
}
# An assignment from -v or an operand, and not to a variable awk keeps itself,
# which is an error or fatal for some values.
function ff_awkset(a,    nm) {
  if (a !~ /^[A-Za-z_][A-Za-z0-9_]*=/) return 0
  nm = substr(a, 1, index(a, "=") - 1)
  return !index(" ARGC ARGV ENVIRON FILENAME FNR NF NR RLENGTH RSTART ", " " nm " ")
}
# A name used as an array must be one everywhere, or awk fails at the first
# line it reads; and only `in` and `delete` may name it bare.
function ff_awkarr(t,    f, nm, A, pre, rest) {
  f = t
  while (match(f, /[A-Za-z_][A-Za-z0-9_]*[ \t]*\[/)) {
    nm = substr(f, RSTART, RLENGTH); sub(/[ \t]*\[$/, "", nm); A[nm] = 1
    f = substr(f, RSTART + RLENGTH) }
  for (nm in A) {
    f = " " t
    while (match(f, "[^A-Za-z0-9_$]" nm "([^A-Za-z0-9_]|$)")) {
      pre = substr(f, 1, RSTART); rest = substr(f, RSTART + 1 + length(nm))
      if (rest !~ /^[ \t]*\[/ && pre !~ /(^|[^A-Za-z0-9_])(in|delete)[ \t]+$/) return 0
      f = substr(f, RSTART + length(nm)) } }
  return 1
}
# A slash after one of ( , { } ; ~ ! & | ? : or at the start is a regex
# literal; anywhere else it is read as division, which admits.
function ff_awkprog(p,    n, i, c, prev, t, d, f, pd) {
  n = length(p); prev = ""; t = ""; d = 0; pd = 0
  for (i = 1; i <= n; i++) {
    c = substr(p, i, 1)
    if (c == "\"") { for (i++; i <= n && substr(p, i, 1) != "\""; i++) if (substr(p, i, 1) == "\\") i++
      if (i > n) return 0
      t = t " S "; prev = "S"; continue }
    if (c == "#") { while (i <= n && substr(p, i, 1) != "\n") i++; continue }
    if (c == "/") {
      if (prev != "" && !index("(,{};~!&|?:", prev)) return 0
      for (i++; i <= n && substr(p, i, 1) != "/"; i++) if (substr(p, i, 1) == "\\") i++
      if (i > n) return 0
      t = t " R "; prev = "R"; continue }
    if (c == "%") return 0
    if (c == "{") d++
    if (c == "}" && --d < 0) return 0
    if (c == "(") pd++
    if (c == ")" && --pd < 0) return 0
    if (d > 0 && (c == ">" || c == "<")) return 0
    if (d > 0 && c == "|" && substr(p, i + 1, 1) != "|" && prev != "|") return 0
    if (c != " " && c != "\t" && c != "\n") prev = c
    t = t c
  }
  if (d || pd) return 0
  if (t ~ /(^|[^A-Za-z0-9_])next([^A-Za-z0-9_]|$)/ && t ~ /(^|[^A-Za-z0-9_])(BEGIN|END)([^A-Za-z0-9_]|$)/) return 0
  if (t ~ /(^|[^+])\+[ \t\n]*([};]|$)/ || t ~ /(^|[^-])-[ \t\n]*([};]|$)/ || t ~ /[*,=&|!][ \t\n]*([};]|$)/ || !ff_awkarr(t)) return 0
  for (i = 1; i <= length(t); i++) if (substr(t, i, 1) == "$") {
    c = substr(t, i + 1, 1)
    if (c ~ /[0-9]/ || (substr(t, i + 1, 2) == "NF" && substr(t, i + 3, 1) !~ /[A-Za-z0-9_]/)) continue
    return 0 }
  if (t ~ /~[ \t]*([^ \tR]|$)/) return 0
  if (t ~ /(^|[^A-Za-z0-9_$])NF[ \t]*([-+*\/^]?=([^=]|$)|\+\+|--)/ || t ~ /(\+\+|--)[ \t]*NF([^A-Za-z0-9_]|$)/) return 0
  f = t
  while (match(f, /[A-Za-z_][A-Za-z0-9_]*[ \t]*\(/)) {
    c = substr(f, RSTART, RLENGTH); sub(/[ \t]*\($/, "", c)
    if (!index(" length substr index tolower toupper int sqrt exp log sin cos atan2 rand srand if while for print in ", " " c " ")) return 0
    f = substr(f, RSTART + RLENGTH) }
  return t !~ /(^|[^A-Za-z0-9_])(exit|return|printf|sprintf|getline|system|close|split|sub|gsub|match|function|func|ARGV|ARGC)([^A-Za-z0-9_]|$)/
}
'
