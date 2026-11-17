# Answers: a capability's output handed to a session without being asked for,
# and what the session did next.
#
# The ledger was built for reaches: a session chose a capability and the call
# shows it. That cannot see the case the knowledge graph was in on 2026-10-29,
# named in 193 sessions and queried in 3, because the fix for a tool nobody
# reaches for is to stop waiting for the reach and deliver what it would have
# said. A delivery is not a reach, so it gets its own kind and its own measure,
# and the measure is the one that matters: not whether the answer was given,
# which the hook guarantees, but whether the session went where it pointed.
#
# One file per session, state/answer/<session>.tsv, appended in order:
#
#   asked<TAB><tool><TAB><outcome>     every ask: answered, repeat, empty, failed, timeout
#   root<TAB><dir>                     a directory touched paths are anchored to
#   given<TAB><tool><TAB><n><TAB><m>   one delivery: n files, of m nodes the tool found
#   node<TAB><tool><TAB><src><TAB><loc><TAB><label>   one node given, never given twice
#   answer<TAB><tool><TAB><file>       one file it named, relative to its checkout
#   prompt                             a person's prompt, which ends the turn
#   touch<TAB><Tool><TAB><file>        a later tool call that reached a named file
#
# A touch row names the file it reached and nothing of the call: the home sits
# in synced Documents, and a command can hold a credential. One ledger signal
# per delivery, `answer<TAB><tool>`, is folded by the rollup into rows no
# capability reading sees (lib/ledger.sh). The graph is the first tool to
# answer (lib/graph-answer.sh, felix_graph_deliver); the next one writes the
# same rows and is measured by the same function. That is the point of keeping
# this apart from the graph's files: a capability plane that can mount a tool
# but cannot tell whether its answers were used has not arranged the tool, only
# installed it.
# docs/2026-10-29-answers-delivered-spec.md, A2, U5, T1-T2 and L3-L5.

# A session id this surface will put in a path: ASCII letters, digits, - and _.
# Listed, not ranged: a range in a bracket follows the locale's collation.
_felix_answer_sid_ok() {
  case "${1:-}" in
    ''|*[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-]*) return 1 ;;
  esac
  return 0
}

# A person's prompt ends the turn in which an answer can be acted on, so the
# measure credits what the session did with an answer before it was asked
# something else, which is the rule the baseline was replayed with. Only for a
# session that already has a record: nothing is started here. Spec U5.
felix_answer_prompt() {
  local home="$1" session="${2:-}" f
  _felix_answer_sid_ok "$session" || return 0
  f="$home/state/answer/$session.tsv"
  [ -f "$f" ] || return 0
  { printf 'prompt\n' >> "$f"; } 2>/dev/null || true
  return 0
}

# Whether <file> (relative to its checkout) is reached by a <tool> call whose
# path or command is <v>, with roots[1..nr] the directories it is anchored to.
# Spec L4. For Bash, a token is what a shell separates: so projects/a/CLAUDE.md
# does not reach projects/b/CLAUDE.md, and 1-24.md does not reach 4.md.
# macOS links /var, /tmp and /etc into /private, and a session may name either.
_felix_answer_hit_awk='
  function canon(p) { return (p ~ /^\/private\/(var|tmp|etc)\//) ? substr(p, 9) : p }
  function lb(v, p,   c) {
    if (p == 1) return 1
    c = substr(v, p - 1, 1)
    if (c == " " || c == "\t" || c == "\"" || c == "\047" || c == "=" || c == "(" || c == ":") return 1
    return (p > 2 && substr(v, p - 2, 2) == "./") ? 1 : 0
  }
  function rb(v, q,   c) {
    if (q > length(v)) return 1
    c = substr(v, q, 1)
    return (c == " " || c == "\t" || c == "\"" || c == "\047" || c == ";" || c == "|" || c == "&" || c == ")" || c == ":" || c == ",") ? 1 : 0
  }
  function tok(v, t,   s, p, off) {
    s = v; off = 0
    while ((p = index(s, t)) > 0) {
      if (lb(v, off + p) && rb(v, off + p + length(t))) return 1
      off += p; s = substr(s, p + 1)
    }
    return 0
  }
  function hit(f, tool, v,   i, b, cv) {
    if (f == "" || v == "") return 0
    if (tool == "Bash") {
      if (tok(v, f)) return 1
      for (i = 1; i <= nr; i++)
        if (index(v, roots[i] "/" f) || index(v, canon(roots[i]) "/" f)) return 1
      b = f; sub(/.*\//, "", b)
      return (index(b, ".") && tok(v, b)) ? 1 : 0
    }
    if (v == f) return 1
    if (nr > 0) {
      cv = canon(v)
      for (i = 1; i <= nr; i++) if (cv == canon(roots[i]) "/" f) return 1
      return 0
    }
    return (length(v) > length(f) && substr(v, length(v) - length(f)) == "/" f) ? 1 : 0
  }'

# What the session did after an answer was handed to it, from the post-tool
# payload: a touch row for each file named in this turn's answers that the
# call reached, and nothing else of the call. Spec T1-T2.
#
# One awk reads the record, then the payload. The value is the string after
# the FIRST "<key>": in the payload, by index rather than by a greedy sed: the
# payload carries tool_input before tool_response, and a Read's response holds
# the file's text, which may itself contain the key. Read to its first
# unescaped quote, decoded, and no more than 16384 bytes of it.
felix_answer_touch() {
  local home="$1" session="${2:-}" signal="${3:-}" raw="${4:-}" f key tool
  _felix_answer_sid_ok "$session" || return 0
  f="$home/state/answer/$session.tsv"
  [ -f "$f" ] || return 0
  case "$signal" in
    "tool	Read"|"tool	Edit"|"tool	Write"|"tool	MultiEdit") key=file_path ;;
    "tool	NotebookEdit") key=notebook_path ;;
    "tool	Grep"|"tool	Glob") key=path ;;
    "tool	Bash") key=command ;;
    *) return 0 ;;
  esac
  tool="${signal#*	}"
  # The 2>/dev/null outside the group: a redirection that fails reports on the
  # stderr in force before it, so one written after `>>` silences nothing.
  { printf '%s\n' "$raw" | LC_ALL=C awk -F'\t' -v k="\"$key\":" -v tool="$tool" -v out="$f" \
      "$_felix_answer_hit_awk"'
    function jstr(s,   o, p, c) {
      s = substr(s, 1, 16384); o = ""
      while ((p = match(s, /[\\"]/)) > 0) {
        o = o substr(s, 1, p - 1); c = substr(s, p, 1)
        if (c == "\"") return o
        c = substr(s, p + 1, 1)
        if (c == "n" || c == "t" || c == "r") o = o " "
        else if (c == "\"" || c == "\\" || c == "/") o = o c
        else if (c != "") o = o "\\" c
        s = substr(s, p + 2)
      }
      return o s
    }
    phase == 1 {
      if ($1 == "prompt") { split("", seen); n = 0 }
      else if ($1 == "answer" && $3 != "" && !($3 in seen)) { seen[$3] = 1; nm[++n] = $3 }
      else if ($1 == "root" && $2 != "") roots[++nr] = $2
      next
    }
    done { next }
    {
      i = index($0, k); if (!i) next
      done = 1
      s = substr($0, i + length(k)); sub(/^[ \t]*/, "", s)
      if (substr(s, 1, 1) != "\"") next
      v = jstr(substr(s, 2))
      for (j = 1; j <= n; j++) if (hit(nm[j], tool, v)) printf "touch\t%s\t%s\n", tool, nm[j] >> out
    }' phase=1 "$f" phase=2 - ; } 2>/dev/null || true
  return 0
}

# Deliveries per tool, from the folded ledger: tool<TAB>sessions<TAB>deliveries.
felix_ledger_answers() {
  _felix_ledger_rows "$(felix_mem_dir "$1")" | LC_ALL=C awk -F'\t' '
    $3 == "answer" && $4 != "" {
      if (!(($4 SUBSEP $1) in seen)) { seen[$4 SUBSEP $1] = 1; s[$4]++ }
      d[$4] += $5
    }
    END { for (t in s) printf "%s\t%s\t%s\n", t, s[t], d[t] }' | LC_ALL=C sort
}

# Whether the sessions went where the answers pointed, per tool with an asked
# or a given row, spec L4:
#   tool sessions sessions_acted deliveries deliveries_acted files files_acted
#   files_opened asked timeouts late unknown
#
# asked counts the asks made, and timeouts those the bound ended; late counts
# the prompts on which the hook had too little time left to ask
# (lib/graph-answer.sh).
# unknown counts the sessions left out of every other column, because their
# PostToolUse record is not whole by the test the fold uses for its zero rows
# (lib/ledger.sh, _felix_ledger_whole): a run that recorded nothing may have
# reached a file an answer named, and a touch missed reads as an answer unused.
# An empty record is left out too. It cannot tell a session that made no call
# from one whose hook never ran, and it is the hook that never ran which a
# count of zero would hide.
#
# A touch credits only the answer rows of its own turn, after the record's last
# prompt row before it. A touch row the post-tool hook wrote names the file it
# reached, and credits that file and no other: read again by the rule, a bare
# CLAUDE.md would also credit projects/x/CLAUDE.md through the basename, which
# the hook had already decided the call did not reach. Any other value is
# matched by that rule (_felix_answer_hit_awk), with every root row of the
# record as an anchor. A delivery is a given row and the answer rows after it
# up to the next given or prompt row.
# files_opened is the acted-on files a Read, Edit, Write, Grep or Glob reached,
# not only a command. Only sessions this repository owns, by the same test the
# catch-up uses, since state/ carries no project namespace.
#
# What it cannot say, and the caller prints it: a file the session would have
# opened anyway is counted too, so this bounds what the answers caused from
# above. The baseline it is read against is in the spec, section 8.
felix_answer_use() {
  local proj="$1" home="$2" root="${3:-}" f session
  local -a owned=()
  for f in "$home"/state/answer/*.tsv; do
    [ -f "$f" ] || continue
    session="${f##*/}"; session="${session%.tsv}"
    _felix_ledger_owns "$home" "$root" "$session" || continue
    if _felix_ledger_whole "$home/state/ledger/$session.tsv"; then owned+=(u=0 "$f"); else owned+=(u=1 "$f"); fi
  done
  [ "${#owned[@]}" -gt 0 ] || return 0
  # One record at a time, read whole before it is counted: its root rows
  # anchor every touch in it, wherever they sit. The u= before each record says
  # whether it is left out; awk has already read the next one's by the time
  # the record before it is counted, so it is kept per record, in cu.
  LC_ALL=C awk -F'\t' "$_felix_answer_hit_awk"'
    function run(   i, j, k, t, x, n, w, cur, dn, sg, sa, named, st) {
      if (cu) {
        for (i = 1; i <= rn; i++) {
          split("", x); k = split(r[i], x, "\t")
          if ((x[1] == "asked" || x[1] == "given") && x[2] != "") st[x[2]] = 1
        }
        for (t in st) { tools[t] = 1; unknown[t]++ }
        rn = 0; return
      }
      nr = 0; split("", roots)
      for (i = 1; i <= rn; i++) { k = split(r[i], x, "\t"); if (x[1] == "root" && k >= 2 && x[2] != "") roots[++nr] = x[2] }
      n = 0; w = 1; cur = 0; dn = 0
      for (i = 1; i <= rn; i++) {
        split("", x); k = split(r[i], x, "\t")
        if (x[1] == "prompt") { w = n + 1; cur = 0 }
        else if (x[1] == "asked" && x[2] != "") {
          tools[x[2]] = 1
          if (x[3] == "late") late[x[2]]++
          else { asked[x[2]]++; if (x[3] == "timeout") timeouts[x[2]]++ }
        }
        else if (x[1] == "given" && x[2] != "") {
          tools[x[2]] = 1; deliveries[x[2]]++; sg[x[2]] = 1
          dt[++dn] = x[2]; dacted[dn] = 0; cur = dn
        }
        else if (x[1] == "answer" && x[2] != "" && x[3] != "") {
          files[x[2]]++
          nm[++n] = x[3]; nt[n] = x[2]; nd[n] = (cur && dt[cur] == x[2]) ? cur : 0; act[n] = 0; opn[n] = 0
        }
        else if (x[1] == "touch" && x[3] != "") {
          named = 0
          for (j = w; j <= n; j++) if (nm[j] == x[3]) { named = 1; break }
          for (j = w; j <= n; j++) {
            if (named ? nm[j] != x[3] : !hit(nm[j], x[2], x[3])) continue
            if (!act[j]) {
              act[j] = 1; files_acted[nt[j]]++
              if (nd[j] && !dacted[nd[j]]) { dacted[nd[j]] = 1; deliveries_acted[nt[j]]++; sa[nt[j]] = 1 }
            }
            if (x[2] != "Bash" && !opn[j]) { opn[j] = 1; files_opened[nt[j]]++ }
          }
        }
      }
      for (t in sg) { sessions[t]++; if (t in sa) sessions_acted[t]++ }
      rn = 0
    }
    FNR == 1 { if (NR > 1) run(); cu = u }
    { r[++rn] = $0 }
    END {
      if (NR > 0) run()
      for (t in tools)
        printf "%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", t, sessions[t], sessions_acted[t],
               deliveries[t], deliveries_acted[t], files[t], files_acted[t], files_opened[t],
               asked[t], timeouts[t], late[t], unknown[t]
    }' "${owned[@]}" | LC_ALL=C sort
}
