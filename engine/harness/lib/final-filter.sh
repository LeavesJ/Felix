# The command whose status a table row's text returns, and whether a final
# filter makes the row unable to fail.
#
# Every table runner evaluates a row's command with pipefail off. Probes,
# obligations, setup and maintenance each start a `bash -c`, and commissioning
# evaluates in-process after `set +o pipefail`. So a pipeline's status is its
# last stage's, and a check that ends in a stage that succeeds whatever it is
# fed cannot fail: `make test 2>&1 | tail -20` reads done, or SATISFIED, when
# the tests fail.
#
# A first attempt judged the text after the last `|` against a list of filter
# names, and review found it leaked both ways. `${c##*|}` split `||` at its
# second bar, so `x | tail || exit 1` passed. It refused checks that can fail:
# `set -o pipefail; x | tail`, `sort -c`, a quoted `|`. And it missed
# `LC_ALL=C sort`, `/usr/bin/tail`, `\tail`, and a redirect after the filter.
# Text patterns cannot answer this. A parse can.
#
# So this reads the text as bash does (final-filter-lex.sh), parses lists,
# and-or chains, pipelines, groups and compound commands, and follows every
# path. A path ends in one of four ways:
#   z  success           n  failure
#   h  success that is a final filter's, whatever fed it
#   g  failure that is only a hidden success turned over (`! x | tail`)
# Each may be terminal, ended by an `exit` or by `set -e`, which is read as on
# from the start of any text that turns it on anywhere. A pipeline of two or
# more stages whose last stage can only succeed is h: a stage from
# final-filter-stages.sh, or a group or loop that ends in one. A command that
# runs because of an h or g decides nothing if it is constant: `x | tail &&
# echo ok` is still h, and so is the empty else of `if ! x | tail; then exit
# 1; fi`. A command that can go either way decides, so `x | tail && y` is y's.
# A bare `exit` returns the status before it, as bash does.
#
# THE RULE. A text is refused when no path can end in failure and at least one
# ends in h. Then it could not fail, and a final filter is why. That is what
# the refusal says, and it is true of every text refused. `x | tail || exit 1`
# is refused, since the `||` never runs.
#
# THE SECOND RULE (audit b11, C074). A text is also refused when no path can end
# in failure, no path ends in h, and it runs at least one command that can fail:
# its status is thrown away rather than hidden behind a filter. `make test ||
# true`, `make test; exit 0`, `make test || :`, `make test | tail -5; true`
# and `if make test; then echo ok; fi` read done or SATISFIED whatever the
# tests do. The
# refusal says so, and names no filter: "it runs something that can fail, and
# no path through it ends in failure". A text that runs nothing that can fail
# (`true`, `:`, `echo ok`, `exit 0`) is still admitted: it hides no failure, and
# the suite's fixtures use `true` as the check that holds. felix_final_filter
# keeps answering only which final filter a text ends in, so it says nothing of
# this rule; ff_row does. Every admission below stands for both rules.
#
# A text that can fail anywhere is admitted, even when the part that does the
# work cannot. `cd dir && make test | tail -20` is admitted, because the cd can
# fail. That is the price of precision, and it was chosen, not missed: the
# first version refused whenever any path ended in h, and review showed that
# refusing real, correct checks. `command -v jq >/dev/null && jq --version |
# cut -d- -f2` fails exactly when jq is absent. `out=$(make test) && printf
# '%s\n' "$out" | tail` fails exactly when the tests do. A refused
# commissioning row fails its project's gate, and a refused obligation blocks
# every merge. So a false refusal is loud and costly, while a missed shape only
# leaves today's hole.
#
# Admitted whenever this cannot be sure:
#   - a word anywhere, however quoted, names pipefail, PATH, SHELLOPTS,
#     BASHOPTS, BASH_ENV, BASH_CMDS, POSIXLY_CORRECT or a kill in any
#     spelling, which can end the shell from any process the text starts;
#   - it sets an option spelled with quotes or an expansion, or posix; it
#     names a builtin or a shell with quotes; it assigns a read-only name;
#   - it uses a builtin other than those ff_safe lists: a function, source,
#     trap, return, shopt, hash, alias, readonly, ulimit, unset and the rest
#     can each change what follows;
#   - it holds arithmetic, `[[ ]]`, or a `${ }` other than ${name},
#     ${#name} and ${name} with :- - :+ + # ## % %% or /, any of which can
#     end the shell with an error;
#   - it holds a carriage return, a here-document, `select`, `coproc`, a case
#     fallthrough, `&>>` or a `{fd}` redirect;
#   - it has syntax the parser cannot read, or nesting past 40 levels;
#   - a stage is named by an expansion, or by a relative path, which is a
#     project's own script;
#   - it expands a parameter that may be unset, and nounset is on:
#     commissioning evaluates with `set -u`, and a text can turn it on.
# An absolute path names the command it ends in. A literal script given to
# `sh -c`, `bash -c` or `eval` is read as that script. `exec` with a command
# ends the script with that command's status, and an exit in a `for` or
# `case` whose words hold an expansion, or after an assignment or redirect
# that ran a command, returns that command's status, which can be anything.
#
# Known misses, all admitted:
#   - `grep -v`, which fails when it selects nothing, so it can fail;
#   - a status kept in a variable and returned later (`rc=$?; exit $rc`);
#   - a filter wrapped in `timeout` or `sudo`, which can fail themselves;
#   - under `set -e`, a failure bash forgives (in a condition, an `&&` chain,
#     a subshell tested by `||`), which this counts as one that can end it.
# `x |& tail` is refused. On bash 3.2 it is a syntax error, so the row can
# never pass there, and it can never fail elsewhere. It is the one bash-4
# spelling refused rather than admitted.
#
# The core is awk, held in FELIX_FINAL_FILTER_AWK, because two of the tables
# it judges are already read by one awk pass. Each caller prepends it to its
# own program, so a table is judged in one process, not one per row. It
# defines ff_stage(text), the final filter's name or "", and ff_row(table,
# line), the reason a table row is refused or "". Every name it defines begins
# with ff or FF.
#
# WHERE. ff_row decides which column of which table is judged, for the
# runners and for schema-check alike. Only columns where a check that cannot
# fail reads as a pass are judged:
#   - commissioning's check, on rows whose answer is not a provider;
#   - obligations' evidence;
#   - setup's check, read as `read` hands it over;
#   - the check on a maintenance event row.
# The rest are left alone:
#   - Commissioning's `when`, obligations' `applies` and a probe's `when`.
#     One that cannot fail makes its row always apply, which asks more.
#   - A probe's witness. One that cannot fail turns an empty probe `blind`,
#     which blocks.
#   - A probe's own command. Its members are its answer, and a real row ends
#     in `sed -n 's/.../p'`.
#   - Qualification, which shows a checker failing by itself. A command that
#     cannot fail fails its violation control.

_ffdir="$(dirname "${BASH_SOURCE[0]:-$0}")"
. "$_ffdir/final-filter-lex.sh"
. "$_ffdir/final-filter-stages.sh"
unset _ffdir

FELIX_FINAL_FILTER_AWK="$FELIX_FINAL_FILTER_LEX$FELIX_FINAL_FILTER_STAGES"'
# An outcome set is a string of tokens, each set off by spaces: z n h:NAME
# g:NAME, with a leading t when the path ended the script there, and tq for an
# exit whose status is the one before it, which the enclosing list fills in.
function ff_term(t) { return substr(t, 1, 1) == "t" }
# Each outcome once. Without this, `a || b && c || d && ...` doubles a set
# at every operator.
function ff_uniq(s,    A, k, i, o, S) {
  if (s == "") return s
  k = split(s, A, " "); o = " "
  for (i = 1; i <= k; i++) if (!(A[i] in S)) { S[A[i]] = 1; o = o A[i] " " }
  return o
}
function ff_mkterm(s,    A, k, i, o) {
  k = split(s, A, " "); o = " "
  for (i = 1; i <= k; i++) o = o (ff_term(A[i]) ? "" : "t") A[i] " "
  return o
}
# The body of a for or case whose words ran a command: an exit with no status
# of its own returns theirs.
function ff_qboth(s) { while (sub(/ tq /, " tz tn ", s)) { }; return s }
function ff_b(t) { return substr(ff_term(t) ? substr(t, 2) : t, 1, 1) }
function ff_pick(s, want,    A, k, i, o) {
  k = split(s, A, " "); o = " "
  for (i = 1; i <= k; i++) if (ff_term(A[i]) == want) o = o A[i] " "
  return o
}
function ff_neg(s,    A, k, i, t, o) {
  k = split(s, A, " "); o = " "
  for (i = 1; i <= k; i++) { t = A[i]
    if (!ff_term(t)) { if (t == "z") t = "n"; else if (t == "n") t = "z"
      else if (t ~ /^h:/) t = "g:" substr(t, 3); else if (t ~ /^g:/) t = "h:" substr(t, 3) }
    o = o t " " }
  return o
}
# What a subshell hands its parent: an exit inside it ends only the subshell.
function ff_sub(s,    A, k, i, t, o) {
  k = split(s, A, " "); o = " "
  for (i = 1; i <= k; i++) { t = A[i]
    if (t == "tq") { o = o "z n "; continue }
    if (ff_term(t)) t = substr(t, 2)
    o = o t " " }
  return ff_uniq(o)
}
# Under set -e, a failure that ends a command may end the script. ff_list adds
# that ending and lets the path go on as well, because bash ignores -e in a
# condition, an && chain, a subshell tested by || and more. Only adding paths
# keeps every failure bash can reach, whichever of those holds.
function ff_errexit(s,    A, k, i, t, o) {
  k = split(s, A, " "); o = " "
  for (i = 1; i <= k; i++) { t = A[i]; if (t == "n" || t ~ /^g:/) t = "t" t; o = o t " " }
  return o
}
# r run after the status t: an exit with no status of its own returns t.
function ff_q(r, t) { while (sub(/ tq /, " t" t " ", r)) { }; return r }
function ff_qall(r, s,    A, k, i, o) {
  if (s == "" || !index(r, " tq ")) return r
  k = split(ff_pick(s, 0), A, " "); o = ""
  for (i = 1; i <= k; i++) o = o ff_q(r, A[i])
  return o == "" ? r : ff_uniq(o)
}
# r run because of a hidden status: if r cannot go both ways, it decided
# nothing, and the path stays hidden.
function ff_hid(r, nm,    A, k, i, t, zs, fs, o) {
  k = split(r, A, " "); zs = 0; fs = 0
  for (i = 1; i <= k; i++) { if (ff_b(A[i]) == "z" || ff_b(A[i]) == "h") zs = 1; if (ff_b(A[i]) == "n" || ff_b(A[i]) == "g") fs = 1 }
  o = " "
  for (i = 1; i <= k; i++) { t = A[i]
    if (ff_b(t) == "z" && !fs) t = (ff_term(t) ? "t" : "") "h:" nm
    else if (ff_b(t) == "n" && !zs) t = (ff_term(t) ? "t" : "") "g:" nm
    o = o t " " }
  return o
}
function ff_comb(s, op, r,    A, k, i, t, b, o) {
  k = split(s, A, " "); o = " "
  for (i = 1; i <= k; i++) { t = A[i]; b = substr(t, 1, 1)
    if (ff_term(t)) o = o t " "
    else if ((op == "&&" && b == "z") || (op == "||" && b == "n")) o = o ff_q(r, t)
    else if ((op == "&&" && b == "h") || (op == "||" && b == "g")) o = o ff_hid(ff_q(r, t), substr(t, 3))
    else o = o t " " }
  return ff_uniq(o)
}
# An if: the condition c picks t or e, and a hidden condition picks blind.
function ff_ifc(c, t, e,    A, k, i, x, o) {
  k = split(c, A, " "); o = ff_pick(c, 1)
  for (i = 1; i <= k; i++) { x = A[i]; if (ff_term(x)) continue
    if (x == "z") o = o ff_q(t, "z"); else if (x == "n") o = o ff_q(e, "n")
    else if (x ~ /^h:/) o = o ff_hid(ff_q(t, x), substr(x, 3)); else o = o ff_hid(ff_q(e, x), substr(x, 3)) }
  return ff_uniq(o)
}
# set -e anywhere in a text is read as set from its start. Met in a loop, or
# after an eval, it ends the script at a failure the text reached before it,
# and ff_list only adds endings for it, so reading it early can only admit
# more.
function ff_text(s, ex, po,    d, out) {
  if (FFD >= 6 || ff_unsure(s)) { FFERR = 1; return " z n " }
  if (s ~ /(^|[^A-Za-z0-9_])set[ \t]/ && s ~ /[ \t]-[A-Za-z]*e|errexit/) ex = 1
  d = ++FFD; FFP[d] = 1; FFEX[d] = ex; FFPOS[d] = po
  if (!ff_lex(s, d)) { FFERR = 1; FFD--; return " z n " }
  out = ff_list(" ")
  if (!FFERR && !ff_end()) FFERR = 1
  FFD--
  return out
}
function ff_list(stops,    acc, cur, o, dead) {
  if (++FFNEST > 40) FFERR = 1
  acc = " "; cur = ""; dead = 0
  while (!FFERR) {
    ff_skipnl()
    if (ff_end() || ff_stop(stops)) break
    o = ff_andor(); if (FFERR) break
    if (!dead) cur = ff_qall(o, cur)
    if (ff_is(0, "&")) { FFP[FFD]++; if (!dead) cur = FFANEG ? " z n " : " z "; continue }
    if (ff_is(0, ";") || ff_is(0, "nl")) {
      FFP[FFD]++
      if (!dead) {
        acc = acc ff_pick(cur, 1); cur = ff_pick(cur, 0)
        if (FFEX[FFD]) acc = acc ff_pick(ff_errexit(cur), 1)
        acc = ff_uniq(acc)
        if (cur !~ /[^ ]/) dead = 1 }
      continue }
    break
  }
  FFNEST--
  return ff_uniq(dead ? acc : acc (cur == "" ? " z " : cur))
}
# Starting a job leaves status 0, but bash 3.2 leaves 1 after `! x &` and
# `! x | y &`, a negated pipeline alone: FFANEG says the list was one.
function ff_andor(    s, op, ng) {
  s = ff_pipe(); ng = FFPNEG
  while (!FFERR && (ff_is(0, "&&") || ff_is(0, "||"))) {
    op = FFV[FFD, FFP[FFD]]; FFP[FFD]++; ff_skipnl(); ng = 0
    s = ff_comb(s, op, ff_pipe())
  }
  FFANEG = ng; return s
}
# `! !` is a syntax error on bash 3.2, so a text holding one never passes.
function ff_pipe(    neg, out, k) {
  if (ff_kw(0, "time")) { FFP[FFD]++; if (ff_kw(0, "-p")) FFP[FFD]++ }
  neg = 0
  if (ff_kw(0, "!")) { FFP[FFD]++; neg = 1
    if (ff_kw(0, "!")) { FFERR = 1; return " z n " }
    if (ff_kw(0, "time")) { FFP[FFD]++; if (ff_kw(0, "-p")) FFP[FFD]++ } }
  out = ff_cmd(); k = 1; FFPNEG = neg
  while (!FFERR && (ff_is(0, "|") || ff_is(0, "|&"))) { FFP[FFD]++; ff_skipnl(); out = ff_cmd(); k++ }
  if (FFERR) return " z n "
  if (k > 1) { out = ff_sub(out)
    if (out ~ /[^ ]/ && out !~ / (n|g:[^ ]*) /) out = " h:" (FFFILT != "" ? FFFILT : "?") " " }
  return neg ? ff_neg(out) : out
}
# A compound command is not a filter by name, and one reading a file on its
# standard input can fail to open it.
function ff_close(o) {
  while (ff_ty(0) == "r") { if (FFS[FFD, FFP[FFD]]) o = o " n "; FFP[FFD]++ }
  FFFILT = ""; return ff_uniq(o)
}
function ff_cmd(    o, w, c) {
  FFFILT = ""
  if (ff_end()) { FFERR = 1; return " z n " }
  if (ff_is(0, "(")) { FFP[FFD]++; o = ff_list(" o:) "); if (!ff_is(0, ")")) { FFERR = 1; return o }; FFP[FFD]++; return ff_close(ff_sub(o)) }
  if (ff_ty(0) == "a") { FFERR = 1; return " z n " }
  if (ff_ty(0) == "r") return ff_simple()
  if (ff_ty(0) != "w") { FFERR = 1; return " z n " }
  if (FFQ[FFD, FFP[FFD]]) return ff_simple()
  w = FFV[FFD, FFP[FFD]]
  if (w == "{") { FFP[FFD]++; o = ff_list(" w:} "); if (!ff_kw(0, "}")) { FFERR = 1; return o }; FFP[FFD]++; return ff_close(o) }
  if (w == "if") return ff_if()
  if (w == "while" || w == "until") {
    FFP[FFD]++; c = ff_list(" w:do "); if (!ff_kw(0, "do")) { FFERR = 1; return " z n " }
    FFP[FFD]++; o = ff_list(" w:done "); if (!ff_kw(0, "done")) { FFERR = 1; return o }
    FFP[FFD]++; return ff_close(ff_pick(c, 1) ff_q(o, w == "while" ? "z" : "n") " z ") }
  if (w == "for") return ff_for()
  if (w == "case") return ff_case()
  if (w ~ /^(function|coproc|select|then|else|elif|fi|do|done|esac|[}]|\[\[)$/) { FFERR = 1; return " z n " }
  return ff_simple()
}
function ff_if(    nc, C, T, i, r) {
  nc = 0
  do {
    FFP[FFD]++; C[++nc] = ff_list(" w:then "); if (!ff_kw(0, "then")) { FFERR = 1; return " z n " }
    FFP[FFD]++; T[nc] = ff_list(" w:elif w:else w:fi ")
  } while (!FFERR && ff_kw(0, "elif"))
  r = " z "
  if (ff_kw(0, "else")) { FFP[FFD]++; r = ff_list(" w:fi ") }
  if (!ff_kw(0, "fi")) { FFERR = 1; return " z n " }
  for (i = nc; i >= 1; i--) r = ff_ifc(C[i], T[i], r)
  FFP[FFD]++; return ff_close(r)
}
function ff_for(    o, y) {
  FFP[FFD]++; y = 0
  if (ff_ty(0) != "w") { FFERR = 1; return " z n " }
  FFP[FFD]++; ff_skipnl()
  if (ff_kw(0, "in")) { FFP[FFD]++; while (ff_ty(0) == "w") { if (FFY[FFD, FFP[FFD]]) y = 1; FFP[FFD]++ } }
  while (ff_is(0, ";") || ff_is(0, "nl")) FFP[FFD]++
  if (!ff_kw(0, "do")) { FFERR = 1; return " z n " }
  FFP[FFD]++; o = ff_list(" w:done "); if (!ff_kw(0, "done")) { FFERR = 1; return o }
  FFP[FFD]++; return ff_close((y ? ff_qboth(o) : o) " z ")
}
function ff_case(    o, y, b) {
  FFP[FFD]++; if (ff_ty(0) != "w") { FFERR = 1; return " z n " }
  y = FFY[FFD, FFP[FFD]]
  FFP[FFD]++; ff_skipnl(); if (!ff_kw(0, "in")) { FFERR = 1; return " z n " }
  FFP[FFD]++; o = " z "
  while (!FFERR) {
    ff_skipnl()
    if (ff_end()) { FFERR = 1; break }
    if (ff_kw(0, "esac")) { FFP[FFD]++; break }
    if (ff_is(0, "(")) FFP[FFD]++
    if (ff_ty(0) != "w") { FFERR = 1; break }
    if (FFY[FFD, FFP[FFD]]) y = 1; FFP[FFD]++
    while (ff_is(0, "|")) { FFP[FFD]++; if (ff_ty(0) != "w") { FFERR = 1; break }; if (FFY[FFD, FFP[FFD]]) y = 1; FFP[FFD]++ }
    if (FFERR || !ff_is(0, ")")) { FFERR = 1; break }
    FFP[FFD]++; b = ff_list(" o:;; o:;& o:;;& w:esac "); o = o (y ? ff_qboth(b) : b)
    if (ff_is(0, ";&") || ff_is(0, ";;&")) { FFERR = 1; break }
    if (ff_is(0, ";;")) FFP[FFD]++
  }
  return ff_close(o)
}
# A simple command. A builtin ff_safe does not list can change the shell, and
# so can a word ff_bad names however it is quoted, a builtin or shell named
# with quotes (the prescans for -e and -u read the text as written), and an
# assignment to a read-only name: the text is admitted. A name that is an
# expansion may be exit. In POSIX mode, as sh runs, an error in a special
# builtin ends the shell. A redirection that can fail stops
# the command with status 1, and a bare exit after an assignment that ran a
# command returns the status of that command.
# A simple command that can fail, run or not: ff_stage reads it with the paths.
function ff_simple(    r) { r = ff_simple0(); if (r ~ / t?n /) FFCF = 1; return r }
function ff_simple0(    nw, st, p, i, nm, r, ex, cs) {
  nw = 0; st = 0; cs = 0
  while (!ff_end() && (ff_ty(0) == "w" || ff_ty(0) == "r")) {
    p = FFP[FFD]; FFP[FFD]++
    if (FFT[FFD, p] == "r") { if (FFS[FFD, p]) st = 1; continue }
    if (ff_bad(FFV[FFD, p])) { FFERR = 1; return " z n " }
    if (nw == 0 && FFR[FFD, p] ~ /^[A-Za-z_][A-Za-z0-9_]*(\[[^=]*\])?[+]?=/) {
      if (FFR[FFD, p] ~ /^(BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID)[[+=]/) { FFERR = 1; return " z n " }
      if (FFR[FFD, p] ~ /\$\(|`/) cs = 1; continue }
    nw++; FFA[FFD, nw] = FFV[FFD, p]; FFAY[FFD, nw] = FFY[FFD, p]; FFAR[FFD, nw] = FFR[FFD, p]
    if (nw == 1 && ff_is(0, "(")) { FFERR = 1; return " z n " }
  }
  if (nw == 0) return " z n "
  FFEXEC = 0; FFBI = 0; FFPX = ""; i = ff_prefix(nw); ex = FFEXEC
  if (!i) { if (ex && FFPX == "n") FFERR = 1; return FFPX == "y" ? " z n tn " : " z n " }
  nm = FFNAME
  if (FFAR[FFD, i] != FFA[FFD, i] && (ff_isbuiltin(nm) || nm ~ /^(sh|bash|dash|ksh|mksh|zsh|ash|posh|yash)$/)) { FFERR = 1; return " z n " }
  if (FFBI && !ff_isbuiltin(nm)) return " n "
  if (ff_isbuiltin(nm) && !ff_safe(nm)) { FFERR = 1; return " z n " }
  # exec runs a file, so a name only the shell knows is not found, and the
  # shell ends there.
  if (ex && nm ~ /^(exit|eval|set|:)$/) return " tn "
  r = ff_run(nm, i, nw, st)
  if (cs) r = ff_qboth(r)
  if (st && FFFILT == "") r = r " n "
  if (FFPOS[FFD] && nm ~ /^(:|[.]|break|continue|eval|exec|exit|export|readonly|return|set|shift|times|trap|unset)$/) r = r " tn "
  return ex ? ff_mkterm(r) : r
}
# The final filter whose status the text can end on, when it cannot fail. When
# it cannot fail and no final filter is why, but it ran something that can fail
# (FFCF), FFDISC says so and the return is "": a status thrown away, as in
# `make test || true` or `make test; exit 0`.
function ff_stage(s,    out, nm, h) {
  FFERR = 0; FFD = 0; FFNEST = 0; FFFILT = ""; FFVAR = 0; FFCF = 0; FFDISC = 0
  out = ff_sub(ff_text(s, 0, 0))
  if (FFERR || out ~ / (n|g:[^ ]*) /) return ""
  h = match(out, / h:[^ ]+ /)
  if (!h && !FFCF) return ""
  if (FFVAR && (FFNU || (s ~ /(^|[^A-Za-z0-9_])(set|(ba|da|k|mk|z|a|po|ya)?sh)[ \t]/ && s ~ /[ \t][-][A-Za-z]*u|nounset/))) return ""
  if (!h) { FFDISC = 1; return "" }
  nm = substr(out, RSTART + 3, RLENGTH - 4)
  return nm == "?" ? "the last stage" : nm
}
function ff_why(nm) {
  return "cannot fail: it can end in " nm ", which succeeds whatever it is fed, and no path through it ends in failure"
}
# The check setup.tsv runs, as `IFS=$(tab) read -r id title cap check` hands
# it over: runs of tabs are one separator, and the rest of the line is check.
function ff_rest(l, n,    k, p) {
  sub(/^\t+/, "", l); sub(/\t+$/, "", l)
  for (k = 0; k < n; k++) { p = index(l, "\t"); if (!p) return ""; l = substr(l, p); sub(/^\t+/, "", l) }
  return l
}
# Whether a maintenance cadence makes its row an event row, as the runner
# reads it: empty, or a whole number that is zero.
function ff_event(c) { return c == "" || (c ~ /^[ \t]*[-+]?[0-9]+[ \t]*$/ && c + 0 == 0) }
# Why a table row is refused, or "". The one place that says which column of
# which table is judged.
function ff_row(tb, line,    F, n, c, who, s) {
  n = split(line, F, "\t"); c = ""; who = "check "; FFNU = tb == "commissioning.tsv"
  if (tb == "commissioning.tsv") { if (n == 7 && F[5] !~ /^provider:/) c = F[6] }
  else if (tb == "obligations.tsv") { if (n >= 5) c = F[5]; who = "the evidence contract " }
  else if (tb == "setup.tsv") c = ff_rest(line, 3)
  else if (tb == "maintenance.tsv") { if (n >= 5 && ff_event(F[2])) c = F[5] }
  if (c == "" || c == "-") return ""
  s = ff_stage(c)
  if (s != "") return who ff_why(s)
  return FFDISC ? who "cannot fail: it runs something that can fail, and no path through it ends in failure" : ""
}
'

# The final filter TEXT can only end on, printed, with exit 0, when TEXT
# cannot fail; exit 1 and nothing printed otherwise, or when this cannot tell.
felix_final_filter() {
  local out
  out="$(FELIX_FF_TEXT="${1:-}" LC_ALL=C awk "$FELIX_FINAL_FILTER_AWK"'
    BEGIN { s = ff_stage(ENVIRON["FELIX_FF_TEXT"]); if (s != "") print s }' </dev/null 2>/dev/null)"
  [ -n "$out" ] || return 1
  printf '%s\n' "$out"
}

# Every row of a table file whose judged command cannot fail: line <TAB> why.
# The table is named by the file's basename, as ff_row reads it. Exit 2, with
# nothing printed, when the file cannot be judged.
felix_final_filter_table() {
  local f="$1" out
  [ -f "$f" ] && [ -r "$f" ] || return 2
  out="$(LC_ALL=C awk -v tb="${f##*/}" "$FELIX_FINAL_FILTER_AWK"'
    /^[[:space:]]*(#|$)/ { next }
    { w = ff_row(tb, $0); if (w != "") print NR "\t" w }' "$f" 2>/dev/null)" || return 2
  [ -z "$out" ] || printf '%s\n' "$out"
}

# Each line of a table read from standard input, led by `-` or by the reason
# its row is refused, so a runner judges its table in one awk pass. When that
# pass fails, every line is led by that fact instead: a runner that could not
# judge a check must not run it as if it had.
felix_final_filter_lead() {   # table basename
  local rows out
  rows="$(cat)"
  [ -n "$rows" ] || return 0
  if out="$(printf '%s\n' "$rows" | LC_ALL=C awk -v tb="$1" "$FELIX_FINAL_FILTER_AWK"'
      { w = ff_row(tb, $0); print (w == "" ? "-" : w) "\t" $0 }' 2>/dev/null)" && [ -n "$out" ]; then
    printf '%s\n' "$out"
  else
    printf '%s\n' "$rows" | while IFS= read -r l; do
      printf 'check could not be judged: the final-filter reader failed on %s\t%s\n' "$1" "$l"
    done
  fi
}
