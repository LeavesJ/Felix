# The lint. _fx_lint FILE... prints N:<text of line N> for each site, one line a
# site in file order, and nothing else; it returns 0 when there is none, 1 when
# there are some and 2, with a message, when a FILE cannot be read or awk fails,
# so a missing file never reads as clean. It reads only its arguments and
# writes only stdout and stderr. A site is
# - a raw cd, in command position, whose operand is parameter-led (begins with
#   $ or "$; -P, -L and -- before it are skipped), with a git write in command
#   position after it in the same command group: the rest of its line, the
#   lines a trailing backslash, && , || or | continues, and when the cd stands
#   in a ( ) or $( ) group every line up to the one that closes it; or
# - a raw git, in command position, with a global -C on a parameter-led
#   directory and a write for subcommand.
# _fx_cd and _fx_git are never sites; command git is git. A git write is every
# subcommand not named as a read: rev-parse, log, show and the like always;
# config with --get and its kin, remote with nothing, get-url or show after
# any -v or --verbose (git remote -v add o u adds o), branch with only listing
# options, symbolic-ref with one operand, tag with nothing or -l, stash list
# and show, worktree list, notes list and show. A
# subcommand written as a parameter is none of those, so it is a write; the one
# place this suite did that on a directory outside $TMP names its subcommand
# now, because _fx_git would refuse it. Command position is the first word of
# a line, and the word after ( $( { ; && || | ! and the keywords then do else if
# elif while until; after command or builtin, for cd and git, and after
# command -p, whose -p keeps it (command -v and -V run nothing); and after env,
# exec, time, nice, nohup and timeout, the first word that is not an option,
# the value of env -u or -C, of exec -a or of timeout -s or -k, a NAME=value or
# a number, with the first such word after timeout taken as its duration, so
# nice -n 5 git -C "$X" commit and timeout 5s git -C "$X" commit are gits. A
# NAME=value before a command leaves the command in command position. Before
# git's subcommand every word that begins with - is a global option and is
# skipped, with the value word of -C, -c, --git-dir, --work-tree, --namespace,
# --config-env, --attr-source and an --exec-path given without =; a -C
# anywhere among them counts, so git --no-optional-locks -C "$X" commit is a
# site and git -C "$X" --no-optional-locks status, a read, is not. A word
# is read as code outside comments (a # that begins a word), single-quoted
# strings, double-quoted
# strings except inside a $( ) opened within them, and heredoc bodies; here-
# strings are not heredocs. Quotes and $( ) carry across lines, and the ) that
# ends a case pattern closes no group. What it cannot see: backticks, text
# run through eval, bash -c bodies, and scripts written to a file and run
# later. Those run in child shells, where _fx_cd does not exist. Nor does it
# see three shapes this file does not hold today: a raw cd at the top of a
# multi-line { } or function body with the git on a later line, git run
# through a variable ($GIT), and xargs git. The awk program is written for
# POSIX awk and has been run under the BSD awk macOS ships; it holds no
# apostrophe because it sits in one. The lint is the suite's check of
# itself, in the section after the pipefail lint; it is meant to be run on this
# file by a person too: _fx_lint tests/run tests/parts/*.sh.
_fx_lint() {
  local f rc found=0
  [ "$#" -gt 0 ] || { printf 'tests/run: _fx_lint: no file given\n' >&2; return 2; }
  for f in "$@"; do
    { [ -f "$f" ] && [ -r "$f" ]; } || { printf 'tests/run: _fx_lint: cannot read %s\n' "$f" >&2; return 2; }
  done
  for f in "$@"; do
    LC_ALL=C awk '
# Reads one bash script on stdin and prints N:<line> for each site. A site is a
# raw cd on a parameter-led operand with a git write after it in the same group,
# or a raw git -C on a parameter-led directory with a git write for subcommand.
# The script is lexed into tokens first, then the tokens are read. The lexer
# keeps a stack of contexts that carries across lines: C is the top level, P a
# ( ) or $( ) group, K the body of a case, D a double-quoted string, Z a single-
# quoted one, Y a $-quoted one, V a ${ } expansion, A an arithmetic expansion,
# T a backtick. Comments, strings and heredoc bodies make no tokens. Words are
# W, the target of a redirection R, a case pattern F, and S is an operator.
# Exit status is 1 when there is a site.
BEGIN {
  SQ = "\047"; DQ = "\042"; BT = "\140"; BS = "\134"
  WMAX = 200
  sp = 0; sk[0] = "C"; curP = 0; ntok = 0; wact = 0; wraw = ""; wlen = 0
  expect = 1; redir = 0; hd_cur = 1; hd_n = 0; nsites = 0; nl = 0
  n = split("rev-parse log show diff status ls-files ls-tree ls-remote cat-file for-each-ref rev-list show-ref merge-base describe grep blame shortlog name-rev var version help check-ignore check-attr count-objects diff-tree diff-files diff-index whatchanged cherry range-diff verify-commit verify-tag", rd, " ")
  for (i = 1; i <= n; i++) readall[rd[i]] = 1
  n = split("--get --get-all --get-regexp --get-urlmatch --list -l get list", rd, " ")
  for (i = 1; i <= n; i++) cfgread[rd[i]] = 1
  n = split("then do else if elif while until ! {", rd, " ")
  for (i = 1; i <= n; i++) kw[rd[i]] = 1
  n = split("env exec time nice nohup timeout", rd, " ")
  for (i = 1; i <= n; i++) transp[rd[i]] = 1
  # The options of a transparent word that take the next word as their value,
  # keyed by the word and the option: env -u NAME, env -C DIR, exec -a NAME,
  # timeout -s SIGNAL, timeout -k DURATION.
  n = split("env -u|env --unset|env -C|env --chdir|exec -a|timeout -s|timeout --signal|timeout -k|timeout --kill-after", rd, "|")
  for (i = 1; i <= n; i++) topt[rd[i]] = 1
  # The global options of git that take the next word as their value. A
  # --exec-path given without = is counted among them.
  n = split("-C -c --git-dir --work-tree --namespace --config-env --attr-source --exec-path", rd, " ")
  for (i = 1; i <= n; i++) gval[rd[i]] = 1
}

# Raw text of a word is kept only up to WMAX characters: its start and its
# whole, when short, are all that is read.
function wadd(str) {
  if (wlen < WMAX) { wraw = wraw str; wlen += length(str) }
}

function emit(type, raw) {
  ntok++
  ttype[ntok] = type; traw[ntok] = raw; tline[ntok] = LN
  tcmd[ntok] = 0; tpl[ntok] = 0; tgrp[ntok] = curP; tmatch[ntok] = 0
  return ntok
}

# An array literal or an extglob group holds words that are not commands.
function arr_ctx() { return (sk[sp] == "P" && sarr[sp]) }
function kpat_now() { return (sk[sp] == "K" && kpat[sp]) }

# A word begins. Whether it is in command position is decided here, by what
# came before it, and the position is used up.
function wstart(   ty) {
  if (wact) return
  wact = 1; wraw = ""; wlen = 0
  if (redir) { ty = "R"; redir = 0; wcmd = 0 }
  else if (arr_ctx()) { ty = "X"; wcmd = 0 }
  else if (kpat_now()) { ty = "F"; wcmd = 0 }
  else { ty = "W"; wcmd = expect; expect = 0 }
  wtok = emit(ty, "")
  tcmd[wtok] = wcmd
}

function popk() { sp--; expect = 0 }

# A word ends: what it was is known now, and the keywords that put the next word
# in command position, command, and the in of a case are read.
function wend(   t, w, ty) {
  if (!wact) return
  t = wtok; w = wraw; wact = 0; wraw = ""; wlen = 0
  traw[t] = w
  ty = ttype[t]
  if (substr(w, 1, 1) == "$" && substr(w, 2, 1) != SQ) tpl[t] = 1
  else if (substr(w, 1, 1) == DQ && substr(w, 2, 1) == "$") tpl[t] = 1
  if (ty == "F") {
    if (w == "esac" && sk[sp] == "K") popk()
    return
  }
  if (ty != "W") return
  # After env, exec, time, nice, nohup or timeout the command is the first
  # word that is not an option, the value of an option, a NAME=value or a number:
  # nice -n 5 git -C "$X" commit. The value of env -u and -C, of exec -a, and
  # of timeout -s and -k is skipped, and so is the first word after timeout
  # that is not an option, the duration: timeout 5s git -C "$X" commit is a git.
  if (tcmd[t] == 3) {
    if (tskip) { tskip = 0; tcmd[t] = 0; expect = 3; return }
    if (substr(w, 1, 1) == "-") {
      if ((tw " " w) in topt) tskip = 1
      tcmd[t] = 0; expect = 3; return
    }
    if (tdur) { tdur = 0; tcmd[t] = 0; expect = 3; return }
    if (w ~ /^[A-Za-z_][A-Za-z0-9_]*[+]?=/ || w ~ /^[0-9]+$/) { tcmd[t] = 0; expect = 3; return }
    tcmd[t] = 1
  }
  # command -p runs the word after it as command would: the -p keeps command
  # position. command -v and -V run nothing, so the word after them is not in
  # command position.
  if (tcmd[t] == 2 && substr(w, 1, 1) == "-") {
    tcmd[t] = 0
    expect = (w == "-p") ? 2 : 0
    return
  }
  if (cs[sp] == 2 && w == "in") {
    cs[sp] = 0
    sp++; sk[sp] = "K"; kpat[sp] = 1; cs[sp] = 0; expect = 0
    return
  }
  if (cs[sp] == 1) { cs[sp] = 2; return }
  if (w == "{") { expect = 1; return }
  if (tcmd[t]) {
    # NAME=value before a command is an assignment for that command alone, and
    # the command comes after it: GIT_COMMITTER_DATE=... git -C "$X" merge is a
    # git in command position, and was not seen until 2026-10-08.
    if (w ~ /^[A-Za-z_][A-Za-z0-9_]*[+]?=/) { expect = 1; return }
    if (w == "esac" && sk[sp] == "K") { popk(); return }
    if (w in kw) expect = 1
    else if ((w == "command" || w == "builtin") && tcmd[t] == 1) expect = 2
    else if (w in transp) { expect = 3; tw = w; tskip = 0; tdur = (w == "timeout") }
    else if (w == "case") cs[sp] = 1
  }
}

function sep(txt) {
  wend()
  if (kpat_now() || arr_ctx()) return
  emit("S", txt)
  expect = 1
}

# A ( ) or $( ) group opens. The word being read, if the group opens inside
# one, waits on the stack, since the tokens of the group come first.
function openP(txt, arr,   t) {
  sp++; sk[sp] = "P"
  sw_act[sp] = wact; sw_tok[sp] = wtok; sw_raw[sp] = wraw; sw_len[sp] = wlen
  sw_exp[sp] = expect; sw_cmd[sp] = wcmd
  sarr[sp] = arr; sprev[sp] = curP; cs[sp] = 0
  wact = 0; wraw = ""; wlen = 0
  sopen[sp] = 0; sdollar[sp] = (txt != "(")
  if (!arr) { t = emit("O", txt); curP = t; sopen[sp] = t }
  expect = (arr ? 0 : 1)
}

function closeP(   t, o, empty) {
  wend()
  o = sopen[sp]; empty = 0
  if (o) {
    t = emit("Q", ")")
    tmatch[o] = t; tmatch[t] = o
    empty = (t == o + 1)
  }
  curP = sprev[sp]
  wact = sw_act[sp]; wtok = sw_tok[sp]; wraw = sw_raw[sp]; wlen = sw_len[sp]
  wcmd = sw_cmd[sp]
  if (sdollar[sp]) { expect = sw_exp[sp]; wadd(")") }
  else expect = (empty ? 1 : 0)
  sp--
}

# The delimiter of a heredoc whose word starts at s[i], quotes removed; hd_end
# is left after it. The body is skipped line by line by the main rule.
function hd_word(s, i,   n, d, c, j) {
  n = length(s); d = ""
  while (i <= n && (substr(s, i, 1) == " " || substr(s, i, 1) == "\t")) i++
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == SQ) {
      j = index(substr(s, i + 1), SQ)
      if (j == 0) { d = d substr(s, i + 1); i = n + 1; break }
      d = d substr(s, i + 1, j - 1); i += j + 1; continue
    }
    if (c == DQ) {
      j = index(substr(s, i + 1), DQ)
      if (j == 0) { d = d substr(s, i + 1); i = n + 1; break }
      d = d substr(s, i + 1, j - 1); i += j + 1; continue
    }
    if (c == BS) { d = d substr(s, i + 1, 1); i += 2; continue }
    if (index(" \t;&|()<>", c) > 0) break
    d = d c; i++
  }
  hd_end = i
  return d
}

# One line. i, the column, is global: wstart reads it.
function lex_line(s,   n, j, c, c2, k, p, m, ntok0, dash) {
  n = length(s); i = 1; cont = 0; ntok0 = ntok
  while (i <= n) {
    k = sk[sp]
    c = substr(s, i, 1)
    if (k == "Z") {
      j = index(substr(s, i), SQ)
      if (j == 0) { wadd(substr(s, i)); i = n + 1 }
      else { wadd(substr(s, i, j)); i += j; sp-- }
      continue
    }
    if (k == "Y") {
      if (c == BS) { wadd(substr(s, i, 2)); i += 2; continue }
      wadd(c); i++
      if (c == SQ) sp--
      continue
    }
    if (k == "T") {
      if (c == BS) { wadd(substr(s, i, 2)); i += 2; continue }
      wadd(c); i++
      if (c == BT) sp--
      continue
    }
    if (k == "D") {
      j = i
      while (j <= n) {
        c = substr(s, j, 1)
        if (c == DQ || c == BS || c == "$" || c == BT) break
        j++
      }
      if (j > i) { wadd(substr(s, i, j - i)); i = j; if (i > n) continue }
      c = substr(s, i, 1)
      if (c == DQ) { wadd(c); i++; sp--; continue }
      if (c == BS) {
        if (i == n) { i++; continue }
        wadd(substr(s, i, 2)); i += 2; continue
      }
      if (c == BT) { wadd(c); sp++; sk[sp] = "T"; i++; continue }
      c2 = substr(s, i + 1, 1)
      if (c2 == "(") {
        if (substr(s, i + 2, 1) == "(") { wadd("$(("); sp++; sk[sp] = "A"; scnt[sp] = 2; i += 3; continue }
        wadd("$("); openP("$(", 0); i += 2; continue
      }
      if (c2 == "{") { wadd("${"); sp++; sk[sp] = "V"; vind[sp] = 1; i += 2; continue }
      wadd(c); i++; continue
    }
    if (k == "V") {
      if (c == "}") { wadd(c); sp--; i++; continue }
      if (c == BS) {
        if (i == n) { i++; continue }
        wadd(substr(s, i, 2)); i += 2; continue
      }
      if (c == SQ && !vind[sp]) { wadd(c); sp++; sk[sp] = "Z"; i++; continue }
      if (c == DQ) { wadd(c); sp++; sk[sp] = "D"; i++; continue }
      if (c == BT) { wadd(c); sp++; sk[sp] = "T"; i++; continue }
      if (c == "$") {
        c2 = substr(s, i + 1, 1)
        if (c2 == "(") {
          if (substr(s, i + 2, 1) == "(") { wadd("$(("); sp++; sk[sp] = "A"; scnt[sp] = 2; i += 3; continue }
          wadd("$("); openP("$(", 0); i += 2; continue
        }
        if (c2 == "{") { wadd("${"); sp++; sk[sp] = "V"; vind[sp] = vind[sp - 1]; i += 2; continue }
      }
      wadd(c); i++; continue
    }
    if (k == "A") {
      if (c == "(") scnt[sp]++
      else if (c == ")") { scnt[sp]--; if (scnt[sp] == 0) { wadd(c); sp--; i++; continue } }
      else if (c == BS) { wadd(substr(s, i, 2)); i += 2; continue }
      else if (c == DQ) { wadd(c); sp++; sk[sp] = "D"; i++; continue }
      else if (c == SQ) { wadd(c); sp++; sk[sp] = "Z"; i++; continue }
      else if (c == "$" && substr(s, i + 1, 1) == "(" && substr(s, i + 2, 1) != "(") {
        wadd("$("); openP("$(", 0); i += 2; continue
      }
      wadd(c); i++; continue
    }
    # code: the top level, a ( ) or $( ) group, or the body of a case
    if (c == " " || c == "\t") { wend(); i++; continue }
    if (c == "#" && !wact) { i = n + 1; continue }
    if (c == BS) {
      if (i == n) { cont = 1; i++; continue }
      wstart(); wadd(substr(s, i, 2)); i += 2; continue
    }
    if (c == SQ) { wstart(); wadd(c); sp++; sk[sp] = "Z"; i++; continue }
    if (c == DQ) { wstart(); wadd(c); sp++; sk[sp] = "D"; i++; continue }
    if (c == BT) { wstart(); wadd(c); sp++; sk[sp] = "T"; i++; continue }
    if (c == "$") {
      c2 = substr(s, i + 1, 1)
      if (c2 == "(") {
        wstart()
        if (substr(s, i + 2, 1) == "(") { wadd("$(("); sp++; sk[sp] = "A"; scnt[sp] = 2; i += 3; continue }
        wadd("$("); openP("$(", 0); i += 2; continue
      }
      if (c2 == "{") { wstart(); wadd("${"); sp++; sk[sp] = "V"; vind[sp] = 0; i += 2; continue }
      if (c2 == SQ) { wstart(); wadd("$" SQ); sp++; sk[sp] = "Y"; i += 2; continue }
      if (c2 == DQ) { wstart(); wadd("$" DQ); sp++; sk[sp] = "D"; i += 2; continue }
      wstart(); wadd(c); i++; continue
    }
    if (c == "(") {
      if (wact) {
        p = substr(wraw, length(wraw), 1)
        if (p == "=" || p == "@" || p == "?" || p == "*" || p == "+" || p == "!") {
          wadd("("); openP("(", 1); i++; continue
        }
      }
      if (k == "K" && kpat[sp] && !wact) { i++; continue }
      wend()
      if (substr(s, i + 1, 1) == "(") { sp++; sk[sp] = "A"; scnt[sp] = 2; i += 2; continue }
      openP("(", 0); i++; continue
    }
    if (c == ")") {
      wend(); k = sk[sp]
      if (k == "P") { closeP(); i++; continue }
      if (k == "K" && kpat[sp]) { kpat[sp] = 0; expect = 1 }
      i++; continue
    }
    if (c == ";") {
      wend(); k = sk[sp]
      c2 = substr(s, i + 1, 1)
      if (c2 == ";" || c2 == "&") {
        m = (c2 == ";" && substr(s, i + 2, 1) == "&") ? 3 : 2
        if (k == "K") { kpat[sp] = 1; expect = 0 }
        else sep(";;")
        i += m; continue
      }
      sep(";"); i++; continue
    }
    if (c == "&") {
      c2 = substr(s, i + 1, 1)
      if (c2 == "&") { sep("&&"); i += 2; continue }
      if (c2 == ">") {
        wend(); redir = 1
        i += (substr(s, i + 2, 1) == ">") ? 3 : 2
        continue
      }
      sep("&"); i++; continue
    }
    if (c == "|") {
      c2 = substr(s, i + 1, 1)
      if (c2 == "|") { sep("||"); i += 2; continue }
      if (c2 == "&") { sep("|"); i += 2; continue }
      sep("|"); i++; continue
    }
    if (c == "<" || c == ">") {
      if (wact && match(wraw, "^[0-9]+$")) {
        ttype[wtok] = "X"
        if (tcmd[wtok]) expect = tcmd[wtok]
        wact = 0; wraw = ""; wlen = 0
      } else wend()
      c2 = substr(s, i + 1, 1)
      if (c2 == "(") {
        wstart(); wadd(c "("); openP(c "(", 0); i += 2; continue
      }
      if (c == "<" && c2 == "<") {
        if (substr(s, i + 2, 1) == "<") { redir = 1; i += 3; continue }
        dash = (substr(s, i + 2, 1) == "-")
        hd_delim[++hd_n] = hd_word(s, i + 2 + dash)
        hd_dash[hd_n] = dash
        i = hd_end; continue
      }
      if (c == ">" && (c2 == ">" || c2 == "&" || c2 == "|")) i += 2
      else if (c == "<" && (c2 == "&" || c2 == ">")) i += 2
      else i++
      redir = 1; continue
    }
    wstart()
    if (match(substr(s, i), "^[A-Za-z0-9_./:=,@%+~^*?!-]+")) { wadd(substr(s, i, RLENGTH)); i += RLENGTH }
    else { wadd(c); i++ }
  }
  k = sk[sp]
  if (k == "C" || k == "P" || k == "K") {
    if (cont) {
      lcont[LN] = 1
      if (!wact && !expect && !arr_ctx() && !kpat_now()) expect = 1
    } else {
      wend()
      if (ntok > 0 && tline[ntok] == LN && ttype[ntok] == "S" && (traw[ntok] == "&&" || traw[ntok] == "||" || traw[ntok] == "|")) lcont[LN] = 1
      else if (ntok == ntok0 && lcont[LN - 1]) lcont[LN] = 1
      if (!arr_ctx() && !kpat_now()) {
        if (ntok > 0 && ttype[ntok] != "N") emit("N", "")
        expect = 1
      }
    }
  }
}

{
  LN = FNR; nl = FNR
  lines[FNR] = $0
  if (hd_cur <= hd_n) {
    t = $0
    if (hd_dash[hd_cur]) sub(/^\t+/, "", t)
    if (t == hd_delim[hd_cur]) { hd_cur++; if (hd_cur > hd_n) { hd_cur = 1; hd_n = 0 } }
    next
  }
  lex_line($0)
}

function opens_sub(j) { return (traw[j] == "$(" || traw[j] == "<(" || traw[j] == ">(") }
function skipgrp(j) { return (tmatch[j] ? tmatch[j] + 1 : ntok + 1) }

# The index of the first word at or after j, steps over redirections and
# nested substitutions; 0 when a command ends first.
function nextword(j,   ty) {
  while (j <= ntok) {
    ty = ttype[j]
    if (ty == "R" || ty == "X") { j++; continue }
    if (ty == "O" && opens_sub(j)) { j = skipgrp(j); continue }
    if (ty == "W") return j
    return 0
  }
  return 0
}

# The global options of the git at token t, then its subcommand g_sub and its
# arguments args[1..na]. Every word before the subcommand that begins with - is
# a global option and is skipped, and the ones that take a separate value, in
# gval, skip that word too. So git --no-optional-locks -C "$X" commit and
# git -p -C "$X" commit are read to their commit, and git -C "$X"
# --no-optional-locks status to its status. g_dyn is set when a -C anywhere
# among them names a parameter-led directory.
function parse_git(t,   j, w, a) {
  g_sub = ""; g_dyn = 0; na = 0
  j = nextword(t + 1)
  while (j) {
    w = traw[j]
    if (substr(w, 1, 1) != "-") { g_sub = w; break }
    if (w in gval) {
      a = nextword(j + 1)
      if (!a) return
      if (w == "-C" && tpl[a]) { g_dyn = 1; g_ctok = j; g_atok = a }
      j = nextword(a + 1); continue
    }
    j = nextword(j + 1)
  }
  if (g_sub == "") return
  j = nextword(j + 1)
  while (j) { args[++na] = traw[j]; j = nextword(j + 1) }
}

# Whether the subcommand parsed is a write. Everything not named as a read is.
function is_write(   i, a, opnd, lst) {
  if (g_sub in readall) return 0
  if (g_sub == "config") {
    for (i = 1; i <= na; i++) if (args[i] in cfgread) return 0
    return 1
  }
  if (g_sub == "remote") {
    # -v and --verbose read nothing by themselves: git remote -v add o u adds
    # o and exits 0 (git 2.54). The word after them decides.
    for (i = 1; i <= na && (args[i] == "-v" || args[i] == "--verbose"); i++) continue
    if (i > na || args[i] == "get-url" || args[i] == "show") return 0
    return 1
  }
  if (g_sub == "branch") {
    lst = 0
    for (i = 1; i <= na; i++) {
      a = args[i]
      if (a == "--list" || a == "-l") { lst = 1; continue }
      if (a == "-a" || a == "-r" || a == "-v" || a == "-vv" || a == "--show-current" || index(a, "--format=") == 1) continue
      if (a == "--contains" || a == "--merged" || a == "--no-merged") { i++; continue }
      if (lst) continue
      return 1
    }
    return 0
  }
  if (g_sub == "symbolic-ref") {
    opnd = 0
    for (i = 1; i <= na; i++) {
      if (args[i] == "-d" || args[i] == "--delete") return 1
      if (substr(args[i], 1, 1) != "-") opnd++
    }
    return (opnd == 1) ? 0 : 1
  }
  if (g_sub == "tag") {
    if (na == 0) return 0
    for (i = 1; i <= na; i++) if (args[i] == "-l" || args[i] == "--list") return 0
    return 1
  }
  if (g_sub == "stash") return (na > 0 && (args[1] == "list" || args[1] == "show")) ? 0 : 1
  if (g_sub == "worktree") return (na > 0 && args[1] == "list") ? 0 : 1
  if (g_sub == "notes") return (na > 0 && (args[1] == "list" || args[1] == "show")) ? 0 : 1
  return 1
}

function git_writes(j) {
  parse_git(j)
  return (g_sub != "" && is_write())
}

# A cd at token t: its group runs to the end of its line, through any line a
# trailing backslash, && , || or | continues, and when it stands in a ( ) or
# $( ) group through the line that closes it.
function check_cd(t,   j, w, op, L, q, cl) {
  op = 0; j = t + 1
  while (j <= ntok) {
    if (ttype[j] == "R" || ttype[j] == "X") { j++; continue }
    if (ttype[j] != "W") break
    w = traw[j]
    if (w == "-P" || w == "-L" || w == "--") { j++; continue }
    op = j; break
  }
  if (!op || !tpl[op]) return
  L = tline[t]
  while (lcont[L] && L < nl) L++
  if (tgrp[t]) {
    q = tmatch[tgrp[t]]
    cl = q ? tline[q] : nl
    if (cl > L) L = cl
  }
  for (j = t + 1; j <= ntok && tline[j] <= L; j++) {
    if (ttype[j] == "W" && tcmd[j] && traw[j] == "git" && git_writes(j)) { site[++nsites] = t; skind[nsites] = "C"; sop[nsites] = op; return }
  }
}

function check_git(t) {
  parse_git(t)
  if (g_dyn && g_sub != "" && is_write()) { site[++nsites] = t; skind[nsites] = "G" }
}

END {
  for (t = 1; t <= ntok; t++) {
    if (ttype[t] != "W" || !tcmd[t]) continue
    if (traw[t] == "cd" && (tcmd[t] == 1 || tcmd[t] == 2)) check_cd(t)
    else if (traw[t] == "git") check_git(t)
  }
  for (s = 1; s <= nsites; s++) print tline[site[s]] ":" lines[tline[site[s]]]
  if (nsites > 0) exit 1
  exit 0
}
' < "$f"; rc=$?
    case $rc in
      0) ;;
      1) found=1 ;;
      *) printf 'tests/run: _fx_lint: awk failed (%s) on %s\n' "$rc" "$f" >&2; return 2 ;;
    esac
  done
  return "$found"
}

# --------------------------------------- the remotes did not move while it ran
# The snapshot above is compared with a fresh read in two places. At the end,
# in the main shell, the last section of this file does it, and the EXIT trap
# below does it for a run that ends some other way (a section runner, an early
# exit), so that no run reads green with a remote moved under it. And while it
# runs, every assertion recorded asks one cheap question, whether a watched
# config is newer than a stamp file: test -nt is a builtin, so an assertion
# before which nothing changed forks nothing. Only when one is newer is the
# state read again, and the first assertion recorded after the move is
# written, with the last one before it, to $TMP/origin-moved. A move written
# there fails the end of the run even when the remotes read as they did at the
# start by then: put back is not unmoved. The record names the
# stretch of the suite in which it happened and nothing more: test -nt reads
# whole seconds, and the config is shared by dozens of suites and agents, some
# running older code. So every message says the remotes moved WHILE THIS RUN
# RAN, and none says this run moved them. Neither guard restores anything;
# putting a remote back is a person's decision.
_og_stamp="$TMP/origin-stamp"; : > "$_og_stamp"
_og_moved="$TMP/origin-moved"
_og_nu=(); _og_nr=(); _og_nt=(); _og_nok=()
_og_i=0
while [ "$_og_i" -lt "$_og_n" ]; do
  _og_nu[$_og_i]="${_og_su[$_og_i]}"; _og_nr[$_og_i]="${_og_sr[$_og_i]}"; _og_nt[$_og_i]="${_og_st[$_og_i]}"; _og_nok[$_og_i]="${_og_sok[$_og_i]}"
  _og_i=$((_og_i+1))
done
# -> the watched files are read again into _og_nu, _og_nr, _og_nt and _og_nok.
_og_reread() {
  local i=0
  while [ "$i" -lt "$_og_n" ]; do
    if _og_read "${_og_cfg[$i]}" "${_og_dir[$i]}"; then _og_nok[$i]=1; else _og_nok[$i]=0; fi
    _og_nu[$i]="$_og_u"; _og_nr[$i]="$_og_r"; _og_nt[$i]="$_og_t"
    i=$((i+1))
  done
}
# I -> 0 when file I has moved since the snapshot: a watched entry differs in
# name, value or order, a remote that had refs has none, or a remote a branch
# tracked is tracked by none. Gaining refs or trackers is not a move. A
# snapshot that could not be read is reported by itself, not as a move (1). A
# file readable then and not now returns 2: could not read is not moved, since
# a git that exits above 1 or a fork that fails under load says nothing about
# the remotes. Only a move between two readable states is a move.
_og_diff() {
  local i="$1" name
  [ "${_og_sok[$i]}" = 1 ] || return 1
  [ "${_og_nok[$i]}" = 1 ] || return 2
  [ "${_og_nu[$i]}" = "${_og_su[$i]}" ] || return 0
  for name in ${_og_sr[$i]}; do
    case "${_og_nr[$i]}" in *" $name "*) ;; *) return 0 ;; esac
  done
  for name in ${_og_st[$i]}; do
    case "${_og_nt[$i]}" in *" $name "*) ;; *) return 0 ;; esac
  done
  return 1
}
# The entries of a state, indented for a message.
_og_show() {   # OK ENTRIES REFS TRACKED
  local rest line
  if [ "$1" != 1 ]; then printf '    (could not be read)\n'; return 0; fi
  rest="$2"
  [ -n "$rest" ] || printf '    (no watched entry)\n'
  while [ -n "$rest" ]; do
    line="${rest%%"$_og_nl"*}"
    case "$rest" in *"$_og_nl"*) rest="${rest#*"$_og_nl"}" ;; *) rest="" ;; esac
    printf '    %s\n' "$line"
  done
  case "$3" in " ") printf '    refs under refs/remotes/<name>/ for: (no remote)\n' ;; *) printf '    refs under refs/remotes/<name>/ for:%s\n' "$3" ;; esac
  case "$4" in " ") printf '    tracked by a branch: (no remote)\n' ;; *) printf '    tracked by a branch:%s\n' "$4" ;; esac
}
# NAME I: the first assertion recorded after file I was found moved. The header
# is tab-separated: the time, the assertion recorded before this one, this one,
# and the config path; then the two states.
_og_record() {
  local when last
  when="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; last="$(tail -n 1 "$FELIX_TEST_RAN" 2>/dev/null)"
  {
    printf '%s\t%s\t%s\t%s\n' "$when" "$last" "$1" "${_og_cfg[$2]}"
    printf 'before:\n'; _og_show "${_og_sok[$2]}" "${_og_su[$2]}" "${_og_sr[$2]}" "${_og_st[$2]}"
    printf 'now:\n';    _og_show "${_og_nok[$2]}" "${_og_nu[$2]}" "${_og_nr[$2]}" "${_og_nt[$2]}"
  } > "$_og_moved" 2>/dev/null
}
# Called by _ran with the name about to be recorded. A file the re-read could
# not read records nothing; the stamp is refreshed all the same, and the end
# of the run reads it again.
_og_tick() {
  local i=0 hit=""
  while [ "$i" -lt "$_og_n" ]; do
    if [ "${_og_cfg[$i]}" -nt "$_og_stamp" ]; then hit=1; break; fi
    i=$((i+1))
  done
  [ -n "$hit" ] || return 0
  : > "$_og_stamp"
  [ ! -e "$_og_moved" ] || return 0
  _og_reread
  i=0
  while [ "$i" -lt "$_og_n" ]; do
    if _og_diff "$i"; then _og_record "$1" "$i"; return 0; fi
    i=$((i+1))
  done
  return 0
}
# The end-of-run verdict, whether the main shell or the trap asks: _og_v is ok,
# skip or bad; _og_msg is the reason a check was skipped or the detail of a bad
# one; _og_rep holds the lines the trap prints. An unreadable snapshot is bad
# before a skip is considered, since an empty one would otherwise read as a
# run that started in no checkout. A move C7 recorded is bad even when the
# file reads as it did at the start by now: a remote moved and put back while
# the run ran is still a remote that moved under it. C7 records only a move
# between two readable states, so that is all this holds to.
#
# A file read at the start that cannot be read now is read again, up to three
# reads in all, before anything is judged: a git that exits above 1 or a fork
# that fails under load is not an answer. Still unreadable after the third, it
# is red on its own terms, "could not re-read the remotes at the end", and
# never called moved, since nothing was compared.
_og_check() {
  local i rest line mcfg="" tries=0 short d rrr="" rrm=""
  _og_v=ok; _og_msg=""; _og_rep=""
  while :; do
    _og_reread; tries=$((tries+1))
    short=""; i=0
    while [ "$i" -lt "$_og_n" ]; do
      if [ "${_og_sok[$i]}" = 1 ] && [ "${_og_nok[$i]}" != 1 ]; then short=1; break; fi
      i=$((i+1))
    done
    [ -n "$short" ] && [ "$tries" -lt 3 ] || break
  done
  rest="$_og_unread"
  while [ -n "$rest" ]; do
    line="${rest%%"$_og_nl"*}"
    case "$rest" in *"$_og_nl"*) rest="${rest#*"$_og_nl"}" ;; *) rest="" ;; esac
    _og_v=bad
    _og_rep="${_og_rep}tests/run: could not read the remotes this run started with: $line$_og_nl"
    _og_msg="${_og_msg}could not read the remotes this run started with: $line$_og_nl"
  done
  if [ -s "$_og_moved" ]; then
    line=""; IFS= read -r line 2>/dev/null < "$_og_moved"
    mcfg="${line##*$'\t'}"
    case "$line" in *$'\t'*) ;; *) mcfg="" ;; esac
    [ -n "$mcfg" ] || mcfg="$_og_moved"
  fi
  i=0
  while [ "$i" -lt "$_og_n" ]; do
    _og_diff "$i"; d=$?
    if [ "$d" -eq 2 ]; then
      _og_v=bad
      rrr="${rrr}tests/run: could not re-read the remotes at the end: ${_og_cfg[$i]}$_og_nl"
      rrm="${rrm}could not re-read the remotes at the end: ${_og_cfg[$i]}${_og_nl}  three reads failed, so nothing was compared$_og_nl"
      if [ -n "$mcfg" ] && [ "$mcfg" = "${_og_cfg[$i]}" ]; then
        _og_rep="${_og_rep}tests/run: remotes moved while this run ran: ${_og_cfg[$i]}$_og_nl"
        _og_msg="${_og_msg}the remotes in ${_og_cfg[$i]} moved while this run ran, as recorded between two readable states; dozens of suites share that config, some of them older code, so the cause is not known here$_og_nl"
        mcfg=""
      fi
    elif [ "$d" -eq 0 ]; then
      _og_v=bad
      _og_rep="${_og_rep}tests/run: remotes moved while this run ran: ${_og_cfg[$i]}$_og_nl"
      _og_msg="${_og_msg}the remotes in ${_og_cfg[$i]} moved while this run ran; dozens of suites share that config, some of them older code, so the cause is not known here${_og_nl}  before:${_og_nl}$(_og_show "${_og_sok[$i]}" "${_og_su[$i]}" "${_og_sr[$i]}" "${_og_st[$i]}")${_og_nl}  now:${_og_nl}$(_og_show "${_og_nok[$i]}" "${_og_nu[$i]}" "${_og_nr[$i]}" "${_og_nt[$i]}")$_og_nl"
      [ "$mcfg" != "${_og_cfg[$i]}" ] || mcfg=""
    elif [ -n "$mcfg" ] && [ "$mcfg" = "${_og_cfg[$i]}" ]; then
      _og_v=bad
      _og_rep="${_og_rep}tests/run: remotes moved while this run ran: ${_og_cfg[$i]}$_og_nl"
      _og_msg="${_og_msg}the remotes in ${_og_cfg[$i]} moved while this run ran, and read as they did at the start by now; dozens of suites share that config, some of them older code, so the cause is not known here$_og_nl"
      mcfg=""
    fi
    i=$((i+1))
  done
  if [ -n "$mcfg" ]; then
    _og_v=bad
    _og_rep="${_og_rep}tests/run: remotes moved while this run ran: $mcfg$_og_nl"
    _og_msg="${_og_msg}the remotes in $mcfg moved while this run ran$_og_nl"
  fi
  # A file that could not be re-read leads the report, so its detail starts
  # with what happened to it.
  _og_rep="$rrr$_og_rep"; _og_msg="$rrm$_og_msg"
  if [ "$_og_v" = bad ] && [ -s "$_og_moved" ]; then
    _og_msg="${_og_msg}first seen between two assertions (time, the assertion before, the assertion recorded when it was seen, the config):${_og_nl}$(cat "$_og_moved" 2>/dev/null)${_og_nl}"
  fi
  if [ "$_og_v" = ok ] && [ "$_og_n" -eq 0 ]; then
    _og_v=skip; _og_msg="the run started in no git checkout and the suite is not inside one, so there is no config to watch"
  fi
  _og_rep="${_og_rep%"$_og_nl"}"; _og_msg="${_og_msg%"$_og_nl"}"
  return 0
}
_og_on=1

# The EXIT trap. It removes $TMP, as the trap above does, and before that it
# stands in for the last section when the run never got there: a section runner
# is this preamble and one cut block, and a run can also exit early. Whatever
# the last section would have found is then reported on stderr and turns the
# status to 1, an earlier non-zero status kept. When the last section did run,
# _fx_final is set and the trap adds nothing. A child the suite forks can run
# this trap too, when a signal reaches it before it has reset the traps it
# inherited (part 0001 says how; slot 3f), so the report and the removal are
# the shell's that made $TMP, and anywhere else the trap only exits.
#
# The removal and the exit are written into the trap itself, not into _fx_exit,
# so no later definition of a function can take $TMP's removal away (asked by
# the fixture floor's owner, 2026-10-08). And the trap turns set -u off before
# it calls _fx_exit: an unset variable is fatal to a non-interactive shell, and
# inside the trap that would end it before the removal ran. _fx_exit takes the
# status the run exited with and returns the one it should end with.
_fx_exit() {   # RC -> RC, or 1 where RC is 0 and a check here failed
  local rc="$1" fail=""
  if [ -z "${_fx_final:-}" ]; then
    if [ -s "$FELIX_TEST_FXREFUSED" ]; then
      fail=1
      { printf 'tests/run: refused fixture git commands:\n'; cat "$FELIX_TEST_FXREFUSED"; } >&2
    fi
    _og_check
    if [ "$_og_v" = bad ]; then fail=1; printf '%s\n' "$_og_rep" >&2; fi
    [ -z "$fail" ] || [ "$rc" -ne 0 ] || rc=1
  fi
  return "$rc"
}
trap '_fx_rc=$?; set +u; '"$_tmp_pid"'; if [ "$_tmp_me" = "$_tmp_by" ]; then _fx_exit "$_fx_rc"; _fx_rc=$?; rm -rf "$TMP"; fi; exit "$_fx_rc"' EXIT
# The suite under test as the one file it was before 2026-10-10: the driver
# with each `. "$HERE/parts/NAME"` and each `. "$HERE/lib/NAME"` line replaced
# by that file (a lib file is where a helper two parts share lives, contract C2,
# and a lint that read the parts must read it too, C3). The checks that
# cut the preamble and one section out of the suite and run them alone, the
# lint over every fixture line, and the pin on _ff_case were written against
# one file, and on the driver alone they would read no section at all (its
# first header is `reached`). Made once per run, under $TMP, from
# $REAL_HARNESS/tests: in a full run this suite, in a section runner the tree
# it was pointed at. A part the driver names and the tree lacks stops it with
# status 1 and no file, so a check reading it fails rather than reading less.
_suite_flat() {
  local f="$TMP/suite-flat.run" d="$REAL_HARNESS/tests"
  # An if, not `[ -s ] || awk && mv`: that reads as (A || B) && C, so once the
  # file was made every later call ran the mv, found no .part and returned 1.
  if [ ! -s "$f" ]; then
    LC_ALL=C awk -v d="$d/" '
      /^\. "\$HERE\/parts\/[^"\/]+"$/ { n = "parts/" substr($0, 16, length($0) - 16) }
      /^\. "\$HERE\/lib\/[^"\/]+"$/   { n = "lib/" substr($0, 14, length($0) - 14) }
      n != "" { if ((getline l < (d n)) <= 0) { bad = 1; exit }
        print l; while ((getline l < (d n)) > 0) print l; close(d n); n = ""; next }
      { print } END { exit bad }' "$d/run" > "$f.part" && mv "$f.part" "$f" || { rm -f "$f.part"; return 1; }
  fi
  printf '%s' "$f"
}

# The parts that hold what was the driver's own text before 3+3b moved it out:
# $TMP and its checks, the fixture guard, the lint, the origin record, the EXIT
# trap and the widget fixture. A block that runs a copy of the driver with
# parts of its own keeps these, where they stand, or its copy has no $TMP.
_suite_preamble="0001-the-origin-guard-and-the-temporary-directory.sh 0002-fixture-git-commands-stay-in-tmp.sh 0003-the-lint-the-origin-record-and-the-exit-trap.sh 0004-the-widget-fixture.sh"
# RUN DIR STUB... -> DIR/run is the driver RUN with its preamble parts' lines
# kept, those parts copied into DIR/parts, and the source lines of the parts
# STUB... (names in DIR/parts, which the caller writes) in place of the first
# other part line, every later one dropped: where the suite's own first part
# stood. The lib lines are dropped as well: they follow that first part line, and
# a copy holds no tests/lib. The harness's felix is copied beside DIR as well,
# since the driver refuses a REAL_HARNESS without felix and lib/ (the caller
# copies lib/).
# Returns 1, with no DIR/run, when a preamble part or felix cannot be copied.
_suite_copy_driver() {
  local run="$1" dir="$2" p; shift 2
  mkdir -p "$dir/parts" || return 1
  for p in $_suite_preamble; do cp "${run%/*}/parts/$p" "$dir/parts/$p" || return 1; done
  cp "${run%/*}/../felix" "$dir/../felix" || return 1
  LC_ALL=C awk -v pre=" $_suite_preamble " -v stubs="$*" '
    index($0, ". \"$HERE/lib/") == 1 { next }
    index($0, ". \"$HERE/parts/") == 1 {
      n = substr($0, 16, length($0) - 16)
      if (index(pre, " " n " ")) { print; next }
      if (!d) { k = split(stubs, s, " "); for (i = 1; i <= k; i++) print ". \"$HERE/parts/" s[i] "\""; d = 1 }
      next }
    { print }' "$run" > "$dir/run"
}
# [--red] F GROUPS MANIFEST STUB... -> F is a git checkout of a whole suite in
# small (contract D, D8): branch main, one commit, refs/remotes/origin/main at
# that commit, so a run there writes a receipt and red finds its base. It holds
# engine/harness/lib, engine/harness/felix, engine/.claude-plugin/plugin.json
# (felix, 0.0.1) and engine/harness/tests with receipt.sh, tests/lib, parts
# 0001 to 0007 and 9990 by number (0007 where the tree has one), red with
# --red, groups.tsv from the file GROUPS (none when GROUPS is -) and
# assertions.tsv from the file MANIFEST (none when MANIFEST is -). Its driver
# is this suite's own with the part lines after 0007 and before 9990 replaced,
# where the first stood, by one line for each STUB: the path of a part file the
# caller wrote, copied into the parts under its own name, which must be
# NNNN-name.sh, numbered 0010 or later and not 9990, and which no other STUB
# may share. Every input is checked before anything is made. Returns 1, with
# no run in F, when anything cannot be made. A definition; it runs nothing.
_suite_copy_tree() {
  local red="" f g m s n d=" " p k T
  [ "${1:-}" != --red ] || { red=1; shift; }
  [ "$#" -ge 3 ] && [ -n "$1" ] || return 1
  f="$1"; g="$2"; m="$3"; shift 3
  T="$f/engine/harness/tests"
  [ "$g" = - ] || [ -f "$g" ] || return 1
  [ "$m" = - ] || [ -f "$m" ] || return 1
  for s in "$@"; do
    n="${s##*/}"
    [ -f "$s" ] || return 1
    case "$n" in [0-9][0-9][0-9][0-9]-*.sh) ;; *) return 1 ;; esac
    case "${n%%-*}" in 000[0-9]|9990) return 1 ;; esac
    case "$d" in *" $n "*) return 1 ;; esac
    d="$d$n "
  done
  mkdir -p "$T/parts" "$f/engine/.claude-plugin" || return 1
  _copy_content "$REAL_HARNESS/lib" "$f/engine/harness/lib" || return 1
  _copy_content "$HERE/lib" "$T/lib" || return 1
  cp "$REAL_HARNESS/felix" "$f/engine/harness/felix" || return 1
  cp "$HERE/receipt.sh" "$T/receipt.sh" || return 1
  [ -z "$red" ] || { cp "$HERE/red" "$T/red" && chmod +x "$T/red"; } || return 1
  [ "$g" = - ] || cp "$g" "$T/groups.tsv" || return 1
  [ "$m" = - ] || cp "$m" "$T/assertions.tsv" || return 1
  for p in 0001 0002 0003 0004 0005 0006 0007 9990; do
    k=0
    for s in "$HERE/parts/$p"-*.sh; do
      [ -f "$s" ] || continue
      cp "$s" "$T/parts/${s##*/}" || return 1
      k=$((k + 1))
    done
    [ "$k" -eq 1 ] || { [ "$p" = 0007 ] && [ "$k" -eq 0 ]; } || return 1
  done
  for s in "$@"; do cp "$s" "$T/parts/${s##*/}" || return 1; done
  printf '{\n  "name": "felix",\n  "version": "0.0.1"\n}\n' > "$f/engine/.claude-plugin/plugin.json" || return 1
  LC_ALL=C awk -v stubs="$d" '
    index($0, ". \"$HERE/parts/") == 1 {
      n = substr($0, 16, length($0) - 16); k = substr(n, 1, 4)
      if (k <= "0007" || k == "9990") { print; next }
      if (!d) { c = split(stubs, s, " "); for (i = 1; i <= c; i++) print ". \"$HERE/parts/" s[i] "\""; d = 1 }
      next }
    { print }' "$HERE/run" > "$T/run" || { rm -f "$T/run"; return 1; }
  chmod +x "$T/run"
  ( _fx_cd "$f" && git init -q -b main && git add -A \
      && git -c user.name=sct -c user.email=sct@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm seed \
      && git update-ref refs/remotes/origin/main HEAD ) >/dev/null 2>&1 || { rm -f "$T/run"; return 1; }
  return 0
}

# The suite's own files, one path a line and nothing else: every part, every lib
# file (tests/lib/*.sh, where a helper two parts share lives, contract C2) and,
# last, the driver. Every check that reads the suite's own text reads it through
# this, _suite_src or _suite_flat, so code moved from a part into tests/lib
# stays under the lint that read it there (contract C3). $HERE is the tests
# directory read: the driver's, or a copy's where a check points HERE at one.
_suite_files() {
  local f
  for f in "$HERE"/parts/*.sh "$HERE"/lib/*.sh "$HERE/run"; do
    [ -f "$f" ] && printf '%s\n' "$f"
  done
  return 0
}
# The text of those files as one stream, the driver last: a check that wants the
# last section-header-shaped line (the completion marker) finds the driver's.
_suite_src() {
  local f
  while IFS= read -r f; do cat "$f"; done < <(_suite_files)
}

