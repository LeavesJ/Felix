# felix audit's awk program, first half: how a Bash command is read. What a
# command holds after its here-documents, quoted text and comments are set
# aside, whether its last check could hand an exit status to the transcript,
# and whether a tool_use is a check at all. lib/audit-count.sh holds the second
# half, what counts; felix_audit_scan in lib/audit.sh hands awk the two as one
# program. Split from lib/audit.sh on 2026-09-22 to keep each file under 500
# lines; the program text is unchanged, and the header of lib/audit.sh says
# why none of it writes.
# shellcheck disable=SC2016
_FELIX_AUDIT_READ='
  BEGIN {
    since = ENVIRON["FELIX_AUDIT_SINCE"]; vre = ENVIRON["FELIX_AUDIT_VERIFY"]
    Q = "\""; BS = "\\"; SQ = "\047"; UUID = "\"uuid\":\"[^\"]*\",$"
    K_SID = "\"sessionId\":\""; K_SIDE = "\"isSidechain\":true"; K_TS = "\"timestamp\":\""; K_MSG = "\"message\":{"
    K_ASST = "\"type\":\"assistant\""; K_USER = "\"type\":\"user\""; K_TYPE = "\"type\":\""
    K_USE = "\"type\":\"tool_use\""; K_RES = "\"type\":\"tool_result\""
    K_END = "\"stop_reason\":\"end_turn\""; K_TID = "\"tool_use_id\":\""
    K_ERR = "\"is_error\":true"; K_META = "\"isMeta\":true"; K_CMD = "\"command\":\""; K_BG = "\"run_in_background\":true"
    EDITS["Edit"]; EDITS["Write"]; EDITS["MultiEdit"]; EDITS["NotebookEdit"]
    naside = 0; ASIDE[++naside] = "/tmp/"; ASIDE[++naside] = "/private/tmp/"
    t = ENVIRON["FELIX_AUDIT_TMP"]; sub(/\/*$/, "/", t)
    if (length(t) > 1) { ASIDE[++naside] = t; if (t ~ /^\/var\//) ASIDE[++naside] = "/private" t }
    t = ENVIRON["FELIX_AUDIT_CFG"]; sub(/\/*$/, "/", t)
    if (length(t) > 1) ASIDE[++naside] = t
    t = ENVIRON["FELIX_AUDIT_MEM"]; sub(/\/*$/, "/", t)
    if (length(t) > 1) ASIDE[++naside] = t
    # A backslash in a command is kept as \001 unless the pattern asks for one:
    # putting them back is a copy per backslash, and a command can hold 300,000.
    rejoin = index(vre, BS BS) > 0
    # What stands before a quote that makes the quoted text code: a shell and
    # its -c, whose script it is; or command position, behind any VAR=value and
    # wrapper, where a quoted path is the command itself.
    SHC = "(^|[^A-Za-z0-9_.-])(bash|sh|zsh)( +-[-A-Za-z]+| +-[A-Za-z]*o +[a-z]+)* +-[A-Za-z]*c +$"
    CMDPOS = ENVIRON["FELIX_AUDIT_CMDPOS"]
    # A command that may write a file in place: a writer named as a word, or a
    # > that duplicates no descriptor. The quick test; writes() reads it.
    WQ = "(^|[^A-Za-z0-9_./-])(sed|perl|tee|patch|apply)([^A-Za-z0-9_-]|$)|>[>|]?[ ]*[^&> ;]"
    LEAD = ENVIRON["FELIX_AUDIT_LEAD"]; GITAP = ENVIRON["FELIX_AUDIT_GITAPPLY"]
    K_CWD = "\"cwd\":\""; K_BASH = "\"name\":\"Bash\""; HOMED = ENVIRON["HOME"]
    first = ""; last = ""
  }

  # A short string value after a key: an id, a tool name, a path.
  function sval(s, k,    p, r, q) {
    p = index(s, k); if (!p) return ""
    r = substr(s, p + length(k), 1024); q = index(r, Q)
    return q ? substr(r, 1, q - 1) : ""
  }

  # The Bash command as JSON holds it, and that text unescaped to shell with
  # real line breaks. BWK awk spends minutes on a gsub over megabytes, and as
  # long splitting megabytes into a million pieces, so of a command over 256K
  # only the first 64K and what follows its last quote are read, here-documents
  # and all: the ends hold the runner and what takes its exit status, and past
  # the last quote is outside.
  function rawcmd(s,    p, r) {
    p = index(s, K_CMD); if (!p) return ""
    r = substr(s, p + length(K_CMD))
    return match(r, /^([^"\\]|\\.)*/) ? substr(r, 1, RLENGTH) : ""
  }
  # A line that ends in an odd run of backslashes goes on to the next, as the
  # shell reads it, but not where that last backslash is in a comment, whose
  # line break still ends it. So the two are kept, as \003 and a line break,
  # for unquote() to join outside a comment and outside single quotes, and
  # for the quick test to read both ways. Pairs of backslashes are set aside
  # first, since each is one escaped backslash.
  function decode(r,    n, P, i) {
    if (!index(r, BS)) return r
    gsub(/\\\\/, "\001", r)
    if (index(r, "\001" BS "n")) { gsub("\001\001", "\002", r); gsub("\001" BS BS "n", "\003\n", r); gsub("\002", "\001\001", r) }
    gsub(/\\"/, Q, r); gsub(/\\n/, "\n", r); gsub(/\\t/, " ", r)
    if (rejoin && index(r, "\001")) {
      n = split(r, P, "\001"); for (i = 1; i < n; i++) P[i] = P[i] BS
      r = join(P, 1, n)
    }
    return r
  }

  # Pieces lo to hi of A, joined by halves: each character is copied once per
  # level, about 17 times for 100,000 pieces, where joining them in turn copies
  # all that came before once per piece.
  function join(A, lo, hi,    m) {
    if (lo >= hi) return lo == hi ? A[lo] : ""
    m = int((lo + hi) / 2)
    return join(A, lo, m) join(A, m + 1, hi)
  }

  # A here-document body is text handed to a command, never a command, unless
  # the command is a shell: then the body is its script, in ( ) as a -c script
  # is, and only the closing line goes. Read on the JSON text, where a line
  # break is backslash-n. It is split once on << and once into lines, a line
  # that could close a body is filed under its word, and each word is looked
  # up from a pointer that only moves on, so a command of ten thousand << that
  # are shifts costs one read.
  # A << no line after it closes opens no body, as a shift in $(( )) or a <<
  # in quoted text does not. Given the first 64K of a longer command (open),
  # one no line in that window closes is looked for in the rest, RB, once per
  # word and for eight words at most, so the read stays bounded: closed there,
  # its body runs past the window, and HDW, HDSH and HDAT say its word, whether
  # a shell reads it, and where the line that opened it ends.
  function heredocs(c, open,    n, P, m, L, LS, CL, NC, PT, k, j, w, d, at, ln, t, from, O, no, sh, NO, ns) {
    HDW = ""; HDSH = 0; HDAT = 0; HDS = 0; HDE = 0
    if ((n = split(c, P, "<<")) < 2) return c
    m = split(c, L, BS BS "n"); LS[1] = 1
    for (k = 1; k <= m; k++) {
      LS[k + 1] = LS[k] + length(L[k]) + 2
      if (k > 1 && length(L[k]) <= 256) {
        w = L[k]; sub("^( |" BS BS "t)+", "", w)
        if (w ~ /^[A-Za-z_][A-Za-z0-9_]*$/) CL[w, ++NC[w]] = k
      }
    }
    no = 0; from = 1; at = 1; ln = 1
    for (k = 2; k <= n; k++) {
      at += length(P[k - 1]) + 2
      if (at < from) continue
      w = substr(P[k], 1, 256)
      if (!match(w, "^-?[ ]*(" SQ "|" BS BS Q ")?[A-Za-z_][A-Za-z0-9_]*")) continue
      d = substr(w, 1, RLENGTH); sub("^-?[ ]*(" SQ "|" BS BS Q ")?", "", d)
      while (ln < m && LS[ln + 1] <= at) ln++
      for (j = PT[d] + 1; j <= NC[d] && CL[d, j] <= ln; j++) ;
      PT[d] = j - 1
      if (j > NC[d] && (!open || (d in NO) || ++ns > 8 || !closes(d, LS[ln + 1]))) { NO[d] = 1; continue }
      w = (k == 2) ? P[1] : P[k - 2] "<<" P[k - 1]
      if (k > 3 || length(w) > 64) w = "x" substr(w, length(w) > 64 ? length(w) - 63 : 1)
      sh = w ~ ("(^|[ ;&|(]|" BS BS "n)([^ ;&|()]*/)?(bash|sh|zsh)( +-[-A-Za-z]+)*[ ]*$")
      if (j > NC[d]) {
        HDW = d; HDSH = sh; HDAT = LS[ln + 1]
        if (!sh) { O[++no] = substr(c, from, LS[ln + 1] - from); from = length(c) + 1 }
        break
      }
      t = CL[d, j]
      if (sh) O[++no] = substr(c, from, LS[ln + 1] - from) "(" substr(c, LS[ln + 1], LS[t] - 2 - LS[ln + 1]) ")" BS "n"
      else O[++no] = substr(c, from, LS[ln + 1] - from)
      from = t < m ? LS[t + 1] : LS[m + 1] - 2
    }
    O[++no] = substr(c, from)
    return join(O, 1, no)
  }
  # Whether a line of RB after at closes the body word d opens: HDS and HDE
  # say where that line starts and where what follows it does.
  function closes(d, at) {
    if (!match(substr(RB, at - 2), BS BS "n( |" BS BS "t)*" d "(" BS BS "n|$)")) return 0
    HDS = at - 3 + RSTART; HDE = HDS + RLENGTH; return 1
  }

  # Quoted text is an argument: a single-quoted span (a grep pattern), and a
  # double-quoted one (a message, an echo, a pattern) unless it stands where a
  # command does, as "./tests/run" or "$W/.venv/bin/python" can, where it is
  # the program, one word: read without its quotes, and with any blank or
  # ; & | ( ) in it as part of that word, so "npm test" as one name is not npm
  # (a path holding a blank is not read as a runner either), but for each $( )
  # in it, which runs what it holds and is kept whole. Or it holds a $( that
  # runs one, which is kept from there, and joined to an = before the quote,
  # since it is that value. The script a shell is handed with -c is a
  # command, and is read as one, from a line of its own, in ( ), since a child
  # shell runs it and a cd in it ends with it; in double quotes, it is read as
  # the shell hands it on, with their escapes taken off. A # that starts a
  # word outside quotes starts a comment, which goes to the end of its line
  # before any quote in it is paired; a backslash that ends a line, kept by
  # decode() as \003, joins it to the next outside a comment and outside
  # single quotes. Given the first 64K of a longer command (cut), a -c script
  # still open at its end is script, and UQSHC is the quote it is waiting for.
  # split(s, C, "") is a character per element in BWK awk, gawk and mawk alike.
  function unquote(c, cut,    n, C, i, ch, O, no, q, st, s, w, p, pc, A, n2, j, z, x) {
    n = split(c, C, ""); no = 0; q = ""; st = 1; UQSHC = ""
    for (i = 1; i <= n; i++) {
      ch = C[i]
      if ((ch == BS || ch == "\001") && q != SQ) { i++; continue }
      if (q == "") {
        if (ch == "\003" && C[i + 1] == "\n") { O[++no] = substr(c, st, i - st); st = ++i + 1; continue }
        pc = C[i - 1]; if (pc == "\n" && C[i - 2] == "\003") pc = i > 3 ? C[i - 3] : " "
        if (ch == "#" && (i == 1 || index(" \n;&|()<>", pc))) {
          O[++no] = substr(c, st, i - st); while (i < n && C[i + 1] != "\n") i++
          st = i + 1; continue
        }
        if (ch == SQ || ch == Q) { O[++no] = substr(c, st, i - st); q = ch; st = i }
      }
      else if (ch == q) {
        s = substr(c, st + 1, i - st - 1); if (q == Q) gsub("\003\n", "", s)
        w = st > 129 ? "x" substr(c, st - 128, 128) : substr(c, 1, st - 1); gsub("\003\n", "", w); gsub(/\n/, ";", w)
        if (w ~ SHC) O[++no] = "\n(" unquote(q == Q ? dq(s) : s) ")"
        else if (q == Q && !index(s, "\n")) {
          if (w ~ CMDPOS) {
            n2 = split(s, A, "[$][(]"); gsub(/[ ;&|()]/, "_", A[1])
            for (j = 2; j <= n2; j++) {
              z = index(A[j], ")"); x = substr(A[j], z + 1); gsub(/[ ;&|()]/, "_", x)
              A[j] = "$(" substr(A[j], 1, z) x
            }
            O[++no] = join(A, 1, n2)
          }
          else if (p = index(s, "$(")) O[++no] = (w ~ /=$/ ? "" : " ") substr(s, p)
        }
        q = ""; st = i + 1
      }
    }
    if (q == "") O[++no] = substr(c, st)
    else if (cut) {
      w = st > 129 ? "x" substr(c, st - 128, 128) : substr(c, 1, st - 1); gsub("\003\n", "", w); gsub(/\n/, ";", w)
      if (w ~ SHC) { s = substr(c, st + 1); s = unquote(q == Q ? dq(s) : s); UQSHC = q; O[++no] = "\n(" s }
    }
    return join(O, 1, no)
  }

  # What a double-quoted span hands on: \" \$ \` and \\ lose the backslash,
  # which is \001 here, as the shell takes it off.
  function dq(s) {
    if (!index(s, "\001")) return s
    gsub("\001\001", "\002", s); gsub("\001\"", Q, s); gsub("\001[$]", "$", s); gsub("\001`", "`", s)
    gsub("\002", "\001", s); return s
  }

  # Where in r the -c script open at the end of its first 64K closes: at the
  # first quote of its kind from p, the end of those 64K or the line after a
  # here-document body open there, a single quote or a double quote no
  # backslash escapes (in JSON, one after an even run of escaped backslashes,
  # counted from where the run starts, which can be before p, so a cut inside
  # an escape does not make its quote a close). One read of the rest; 0 where
  # it never closes.
  function scriptend(r, p,    k) {
    if (UQSHC == SQ) return (k = index(substr(r, p), SQ)) ? p - 1 + k : 0
    k = substr(r, p > 256 ? p - 256 : 1, p > 256 ? 256 : p - 1)
    if (match(k, /\\+$/)) p -= RLENGTH
    return match(substr(r, p), /(^|[^\\])(\\\\\\\\)*\\"/) ? p - 3 + RSTART + RLENGTH : 0
  }

  # Whether the exit status of the last check could reach the transcript: not
  # when a later command, a pipe (without pipefail set as an option) or ||
  # takes it, nor when & sends it to the background, nor when a ! before it
  # turns it over. The } or ) that closes a group hands it on, as the fi of
  # an if whose branch it ends does, and a redirect, of the check or of its
  # group, does too; the done of a loop does not, since an earlier pass can
  # fail unseen.
  # The last check is found without copying the rest of the command once per
  # match: the command is cut after each ; & | ( and the last piece that holds
  # a match, read from the character that starts it, holds the last check. A
  # pattern that only matches across a cut is looked for over the whole.
  # A piece, and what follows a match in it, is read behind an = , which
  # starts no check, so a ^ in the pattern is where the command starts, never
  # the middle of a word: tests/run tests/run ... is one match, not one per
  # word, each re-reading the rest.
  function hidden(c,    x, n, P, O, i, k, s, sh, off, e, a, b, t) {
    x = c; gsub(/[;&|(]/, "&\002", x); n = split(x, P, "\002"); O[1] = 1
    for (i = 1; i < n; i++) O[i + 1] = O[i] + length(P[i])
    for (i = n; i >= 1; i--) {
      if (i > 1) { x = "=" substr(P[i - 1], length(P[i - 1])) P[i]; k = O[i] - 2 } else { x = P[1]; k = 1 }
      if (match(x, vre)) break
    }
    if (i < 1) { x = c; k = 1 }
    s = x; sh = 0; off = 0; e = 1; b = 1
    while (off < length(x) && match(s, vre)) {
      a = RSTART + RLENGTH - 1; if (a < 1 + sh) a = 1 + sh
      b = off + RSTART - sh; e = off + a - sh; off = e; s = "=" substr(x, off + 1); sh = 1
    }
    b += k - 1; e += k - 1; HE = e
    t = substr(c, b > 64 ? b - 64 : 1, e - (b > 64 ? b - 64 : 1) + 1); sub(/[;&|()]$/, "", t)
    if (t ~ /(^|[;&|(])[ ]*((if|elif|while|until|then|else|do|[{]) +)*! +[^;&|()]*$/) return 1
    t = substr(c, e); gsub(/[0-9]*(>>?|<|&>>?|>[|])&?[ ]*[^ ;&|()<>]*/, "", t); sub(/([; })]|[; ]fi)+$/, "", t)
    if (index(t, ";") || index(t, "||")) return 1
    if (index(t, "|") && c !~ /-[A-Za-z]*o +pipefail/) return 1
    gsub(/&&|[<>]&|&>/, "", t)
    return index(t, "&") > 0
  }

  # The tail window t of a command r whose first 64K ends inside a
  # here-document body, which closes at the line heredocs() found, from HDS to
  # HDE. Where that line is in the window, what follows it, and for a shell
  # the script before it too, less the line.
  function afterbody(r, n, t,    w0) {
    w0 = n - 65535
    if (HDE <= w0) return t
    if (!HDSH) return substr(r, HDE)
    return HDS > w0 ? substr(r, w0, HDS - w0) BS "n" substr(r, HDE) : substr(r, HDE)
  }

  # The quick test reads a quote as a command boundary, since what follows one
  # can be the script of a shell, and a double quote also as nothing, since
  # the quoted path before it can be the program, with the backslash before
  # it too, since in a double-quoted script it is one; unquote() then decides
  # what the quotes held.
  # Over 256K, the last 64K is read from after its last quote, since it can
  # start inside quoted text; but where the first 64K ends inside a -c script
  # that closes in it, it is read as the end of that script (from after its
  # own last quote, for the same reason) and then as what follows the script.
  # A here-document body in that script open at the end of the first 64K is
  # passed over to its closing line, where the script goes on, read whole
  # where that line is in the last 64K.
  # A command is read for what it writes, too, once any quick test says it may.
  function check(seg,    r, c, n, P, u, big, t, h, k, m, s, tu, tc, ck, wq, w0, p, z) {
    HID = 0; WR = 0; WRAT = 0; CHKE = 0
    r = rawcmd(seg); if (r == "") return 0
    if (big = ((n = length(r)) > 262144)) {
      RB = r; h = heredocs(substr(r, 1, 65536), 1); RB = ""; w0 = n - 65535; t = substr(r, w0); p = 65537
      if (HDW != "") { t = afterbody(r, n, t); p = HDSH ? 0 : HDE }
      c = decode(h); u = unquote(c, 1); z = UQSHC == SQ ? 1 : 2
      if (UQSHC != "" && p && (!(m = scriptend(r, p)) || m >= w0)) {
        if (p > w0) { s = decode(heredocs(substr(r, p, (m ? m : n + 1) - p), 0)); tu = unquote(s) }
        else { s = decode(m ? substr(r, w0, m - w0) : t); k = split(s, P, "[" Q SQ "]"); tu = unquote(P[k]) }
        tc = s
        if (m) { s = decode(heredocs(substr(r, m + z), 0)); tu = tu "\n" unquote(s); tc = tc "\n" s }
      } else { tc = decode(heredocs(t, 0)); k = split(tc, P, "[" Q SQ "]"); tc = P[k]; tu = unquote(tc) }
      u = u "\n" tu; c = c "\n" tc
    } else c = decode(heredocs(r, 0))
    r = c; if (index(r, "\003")) { t = r; gsub("\003\n", "", t); r = r "\n" t }
    gsub(/\n/, ";", r); gsub(SQ, ";", r); t = r; gsub(Q, "", t); gsub("\001", "", t); gsub(Q, ";", r)
    ck = (r ~ vre || t ~ vre); wq = (r ~ WQ)
    if (!ck && !wq) return 0
    if (!big) u = unquote(c)
    gsub(/\n/, ";", u)
    if (wq) writes(u)
    if (!ck || u !~ vre) return 0
    HID = hidden(u) || index(seg, K_BG) > 0; CHKE = HE
    return 1
  }

  # What a command writes in place, read as the checks are: sed -i, perl -i,
  # patch and git apply at command position, behind the same words and
  # wrappers, to the last word for the first two and to the tree it runs in
  # for the others; tee, to each file it names; and a > or >> anywhere, to the
  # word after it. That word is read only where it is a named path: one in
  # quotes or through a $ or a backquote is not seen, nor is /dev/..., a
  # number, a descriptor (>&2, 2>&1), an escaped \> or a > in (( )). A
  # relative path is under the cwd of the record, or under where a cd before
  # it in the command went, but for one in a subshell, a $( ), a -c script or
  # a script a shell reads from a here-document, which ends with it; after a
  # cd to a place not named, as cd "$SP", a relative path is not seen either.
  # WR is 1 where a write counts, 2 where each went to scratch or to what is
  # Claude or Felix own, and WRAT is where the pipeline of the last that
  # counts starts, so the log the pipeline of a check writes (npm test >
  # t.log, npm test | tee t.log) is not after it. What follows the ) of a
  # group, or the } fi done or esac that closes a compound command, is of the
  # pipeline the group or the compound started in, so (npm test) > t.log is
  # not after its check either. One cut at ; & | ( ) and one split of a piece
  # on > : no step re-copies the rest.
'
