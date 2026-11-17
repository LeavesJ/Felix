# The lost-work page: felix monitor, and its log page under --log.
#
# What needs the founder comes first: hazards, blocked sessions, open questions,
# work that never reached a PR, and pull requests by who has to act. Running work,
# helpers' worktrees (a subagent's or a workflow's, whose unpushed commits and
# open calls are its spawning session's to answer for) and landed work are
# collapsed to a count; a line after the collapsed one says how many helpers'
# worktrees hold work that never reached a PR (audit b09, C025: the count says
# the work is there, and names no row). Nothing on it acts: it prints no command
# to run, posts nothing, merges nothing and starts no session, and it writes
# nothing outside one scratch directory of its own, removed on exit. It derives
# no fact: every row it shows is a row one of two sources printed, the
# repository's own listing (felix inventory --tsv) or the pull requests' states
# (felix land --prs --tsv), and it adds only the group a row is in and how many
# rows each group holds. A source it could not read is said, and a count that
# depends on it reads unknown, never 0. The contract is
# docs/2026-10-18-lost-work-page-contract.md.
#
# Bash 3.2. LC_ALL=C on every text tool; digit brackets spelled out.

_LW_GROUPS="hazard blocked question never-proposed pr-founder pr-session pr-lander pr-unknown undecided running helper pr-nobody proposed carried handoff landed quiet"

felix_monitor_usage() {
  printf 'usage: felix monitor [--tsv] [--repo DIR]... [--no-gh] [--no-host] [--days N] [--live MIN] [--blocked MIN]\n'
  printf '       felix monitor --log [--open] [--watch] [--every N]\n'
  printf '       felix monitor -h | --help\n'
  printf '  the page: read-only; what needs you first (hazards, blocked sessions, open questions, work that never\n'
  printf '                 reached a PR, pull requests by who has to act), the rest collapsed to counts\n'
  printf '  --tsv          group kind repo ref states owner age_h content detail, 17 summary rows per repository first\n'
  printf '  --repo DIR     a repository to read, repeatable (default: the one holding this directory)\n'
  printf '  --no-gh, --no-host, --days N, --live MIN, --blocked MIN   as felix inventory takes them\n'
  printf '  --log          the HTML page of what Felix did that nobody could see (state/monitor.html);\n'
  printf '                 --open, --watch and --every N belong to it and imply --log\n'
}
_lw_refuse() { printf 'felix monitor: %s\n' "$1" >&2; felix_monitor_usage >&2; return 2; }

# Reads the arguments into _LW_LOG (0 the page, 1 the log page), _LW_TSV, _LW_NOGH,
# _LW_NOHOST, the arrays _LW_NUMS (the numeric options, as the inventory takes
# them) and _LW_REPOS, _LW_OPEN, _LW_WATCH and _LW_EVERY. Status 0 to go on, 2 for
# a usage error, 3 when -h or --help printed the usage.
felix_monitor_args() {
  local page=0 log=0
  _LW_TSV=0; _LW_NOGH=0; _LW_NOHOST=0; _LW_NUMS=(); _LW_REPOS=(); _LW_OPEN=0; _LW_WATCH=0; _LW_EVERY=5
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help) felix_monitor_usage; return 3 ;;
      --tsv) page=1; _LW_TSV=1; shift ;;
      --no-gh) page=1; _LW_NOGH=1; shift ;;
      --no-host) page=1; _LW_NOHOST=1; shift ;;
      --repo) [ $# -ge 2 ] && [ -n "$2" ] || { _lw_refuse "--repo needs a directory"; return 2; }
              page=1; _LW_REPOS[${#_LW_REPOS[@]}]="$2"; shift 2 ;;
      --days|--live|--blocked)
              case "${2:-}" in ''|*[!0123456789]*|???????*) _lw_refuse "$1 needs a whole number of at most six digits"; return 2 ;; esac
              page=1; _LW_NUMS[${#_LW_NUMS[@]}]="$1"; _LW_NUMS[${#_LW_NUMS[@]}]="$2"; shift 2 ;;
      --log) log=1; shift ;;
      --open) log=1; _LW_OPEN=1; shift ;;
      --watch) log=1; _LW_WATCH=1; shift ;;
      --every) [ $# -ge 2 ] && [ -n "$2" ] || { _lw_refuse "--every needs a value"; return 2; }
               log=1; _LW_EVERY="$2"; shift 2 ;;
      *) _lw_refuse "unknown argument: $1"; return 2 ;;
    esac
  done
  [ "$page" = 0 ] || [ "$log" = 0 ] || { _lw_refuse "the page's options and --log's cannot be given together"; return 2; }
  _LW_LOG="$log"; return 0
}

# Every byte below 0x20 but tab and line feed, 0x7f and the UTF-8 C1 controls
# becomes ?: chip titles and question text come from transcripts.
_lw_filter() { LC_ALL=C tr '\001-\010\013-\037\177' '?' | LC_ALL=C awk '{ gsub(/\302[\200-\237]/, "?"); print }'; }

# Scratch outside every repository, else under /tmp, else none.
_lw_scratch() {
  local b
  for b in "${TMPDIR:-/tmp}" /tmp; do
    _LW_T="$(mktemp -d "${b%/}/felix-monitor.XXXXXX" 2>/dev/null)" || { _LW_T=""; continue; }
    git -C "$_LW_T" rev-parse --git-dir >/dev/null 2>&1 || return 0
    rmdir "$_LW_T"; _LW_T=""
  done
  return 1
}

# felix_lost_work_page: the page over _LW_REPOS, as the arguments set them.
# Status 1 when a repository could not be read: the inventory failed for it, or
# the page's own awk did (contract B8). Either way the other repositories are
# still printed, and the one that failed prints nothing on stdout.
felix_lost_work_page() {
  local d rc=0 irc lrc arc head
  local -a ia=() la=() repos=()
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY   # as felix inventory does: the scratch check below asks git
  if [ "${#_LW_REPOS[@]}" -gt 0 ]; then repos=("${_LW_REPOS[@]}"); else repos=("$PWD"); fi
  [ "$_LW_NOGH" = 0 ] || { ia[${#ia[@]}]=--no-gh; la[${#la[@]}]=--no-gh; }
  [ "$_LW_NOHOST" = 0 ] || ia[${#ia[@]}]=--no-host
  [ "${#_LW_NUMS[@]}" -eq 0 ] || ia=(${ia[@]+"${ia[@]}"} "${_LW_NUMS[@]}")
  _lw_scratch || { printf 'felix monitor: no scratch directory outside every repository\n' >&2; return 1; }
  trap '[ -z "$_LW_T" ] || rm -rf "$_LW_T"' EXIT
  trap 'exit 129' HUP; trap 'exit 130' INT; trap 'exit 131' QUIT; trap 'exit 143' TERM
  head='felix monitor: read-only. It wrote nothing, fetched nothing and acted on nothing; it read felix inventory and felix land --prs.'
  [ "$_LW_TSV" = 1 ] || printf '%s\n' "$head"
  for d in "${repos[@]}"; do
    "$SCRIPT_DIR/felix" inventory --tsv --repo "$d" ${ia[@]+"${ia[@]}"} > "$_LW_T/i.raw" 2> "$_LW_T/i.err"; irc=$?
    [ ! -s "$_LW_T/i.err" ] || cat "$_LW_T/i.err" >&2
    [ "$irc" = 0 ] || { rc=1; continue; }
    "$SCRIPT_DIR/felix" land --prs --tsv --repo "$d" ${la[@]+"${la[@]}"} > "$_LW_T/l.raw" 2> "$_LW_T/l.err"; lrc=$?
    { _lw_filter < "$_LW_T/i.raw" | LC_ALL=C awk '{ print "I\t" $0 }'
      _lw_filter < "$_LW_T/l.raw" | LC_ALL=C awk '{ print "L\t" $0 }'; } > "$_LW_T/in"
    _lw_filter < "$_LW_T/l.err" | LC_ALL=C sed -n 1p > "$_LW_T/l.err1"
    # land's first stderr line and the repository path go in by the environment: -v would expand a backslash in either.
    # The block is printed only when the awk finished: one that stops part way has
    # counted nothing for sure, and on Linux gawk it once stopped at the first row
    # and the page said nothing and exited 0.
    LW_LERR="$(cat "$_LW_T/l.err1")" LW_DFLT="$d" LC_ALL=C awk -F'\t' -v tsv="$_LW_TSV" -v lrc="$lrc" -v order="$_LW_GROUPS" "$_LW_AWK" "$_LW_T/in" > "$_LW_T/page"; arc=$?
    if [ "$arc" = 0 ]; then cat "$_LW_T/page"
    else rc=1; printf 'felix monitor: %s: the page could not be made from its rows (awk exited %s)\n' "$d" "$arc" >&2; fi
  done
  return "$rc"
}

# The page of one repository from its tagged rows: I the inventory's, L land's.
# shellcheck disable=SC2016
_LW_AWK='
BEGIN { lerr = ENVIRON["LW_LERR"]; dflt = ENVIRON["LW_DFLT"] }
function cl(x) { gsub(/[\t\r\n]/, " ", x); return x }
function fw(s,    n) { n = index(s, ","); return n ? substr(s, 1, n - 1) : s }
function has(s, w) { return index("," s ",", "," w ",") > 0 }
function unk(s,    a, n, i) { n = split(s, a, ","); for (i = 1; i <= n; i++) if (index(a[i], "unknown:") == 1 && a[i] != "unknown:live") return 1; return 0 }
function addr(a, b) { return a == "" ? b : a "; " b }
# B3: the first group in the contract table whose condition holds.
function grp(st, ct) {
  if (has(st, "hazard:shared-branch") || has(st, "hazard:staged-revert")) return "hazard"
  if (has(st, "helper")) return "helper"
  if (has(st, "blocked")) return "blocked"
  if (has(st, "question")) return "question"
  if (has(st, "live")) return "running"
  if (has(st, "uncommitted") || has(st, "unpushed") || has(st, "unproposed") || has(st, "pr-closed-unlanded") || has(st, "chip-unstarted") || (has(st, "orphan") && ct != "landed")) return "never-proposed"
  if (has(st, "pr-open")) return "proposed"
  if (has(st, "carried")) return "carried"
  if (has(st, "handoff-pending")) return "handoff"
  if (unk(st) || ct == "not" || ct == "partly") return "undecided"
  if (has(st, "landed")) return "landed"
  return "quiet"
}
function cv(ref) { return (ref in scov) ? scov[ref] : "" }
function covreason(ref) { return (ref in scov) ? ref " " scov[ref] ": " cdet[ref] : ref " unknown: the row was not printed" }
function ghreason() { return ghseen ? "gh " ghst ": " ghdet : "felix land --prs exited " lrc (lerr != "" ? ": " lerr : "") }
function calc(g,    r, inc, i, cr) {
  r = ""; inc = 0
  if (g == "hazard") { if (kc[g]) { inc = 1; r = kc[g] " rows not decided" } }
  else if (g == "blocked" || g == "question" || g == "running" || g == "helper") {
    if (cv("sessions") != "read") { inc = 1; r = covreason("sessions") }
    if (kc[g]) { inc = 1; r = addr(r, kc[g] " rows not decided") }
  } else if (g == "never-proposed") {
    split("default prs chips", cr, " ")
    for (i = 1; i <= 3; i++) if (cv(cr[i]) != "read") { inc = 1; r = addr(r, covreason(cr[i])) }
    if (kc[g]) { inc = 1; r = addr(r, kc[g] " rows not decided") }
  } else if (g == "proposed") {   # gh names the open pull requests: the prs cover row decides them
    if (cv("prs") != "read") { inc = 1; r = covreason("prs") }
    if (kc[g]) { inc = 1; r = addr(r, kc[g] " rows not decided") }
  } else if (g == "handoff") {   # the pending listing failed: the inventory says so in the default cover row, in its states
    if (("default" in cst) && has(cst["default"], "unknown:handoff-pending")) { inc = 1; r = covreason("default") }
  } else if (g == "pr-founder" || g == "pr-session" || g == "pr-lander") {
    if (ghbad) { inc = 1; r = ghreason() }
    if (NG["pr-unknown"] > 0) { inc = 1; r = addr(r, NG["pr-unknown"] " pull requests not decided") }
  } else if (g == "pr-unknown" || g == "pr-nobody") { if (ghbad) { inc = 1; r = ghreason() } }
  INC[g] = inc; REA[g] = r
  CS[g] = !inc ? NG[g] + 0 : (NG[g] ? "at least " NG[g] : "unknown")
}
function rline(g, i,    f, s) {
  split(R[g, i], f, "\t")
  s = f[3] " " f[4]
  if (f[6] != "-") s = s ", " f[6] "h"
  if (RTAG[g, i] == "I" && f[5] != "-" && f[5] != "unknown") s = s ", session " substr(f[5], 1, 8)
  return "      " s ": " f[8]
}
{ if ($1 != "I" && $1 != "L") next
  for (c = 2; c <= 9; c++) V[c] = ($c == "" ? "-" : cl($c))
  tag = $1; kind = V[2]
  if (tag == "I" && repo == "") repo = V[3]
  row = V[2] "\t" V[3] "\t" V[4] "\t" V[5] "\t" V[6] "\t" V[7] "\t" V[8] "\t" V[9]
  if ((tag == "I" && kind == "cover") || (tag == "L" && kind == "source")) {
    ncv++; CV[ncv] = row; CVT[ncv] = tag
    if (tag == "I") { scov[V[4]] = fw(V[5]); cst[V[4]] = V[5]; cdet[V[4]] = V[9] }
    else if (V[4] == "gh") { ghseen = 1; ghst = V[5]; ghdet = V[9]; ghfw = fw(V[5]) }
    next }
  if (tag == "L" && kind == "pr") { o = V[6]; g = (o == "founder" || o == "session" || o == "lander" || o == "unknown" || o == "nobody") ? "pr-" o : "pr-unknown"; num = V[4]; sub(/^#/, "", num) }
  else { g = grp(V[5], V[8]); num = 0
    if (tag == "I") { st = V[5]
      if (has(st, "unknown:hazard:shared-branch") || has(st, "unknown:hazard:staged-revert")) kc["hazard"]++
      if (has(st, "unknown:pr-open")) kc["proposed"]++
      if (has(st, "unknown:blocked")) kc["blocked"]++; if (has(st, "unknown:question")) kc["question"]++; if (has(st, "unknown:live")) kc["running"]++; if (has(st, "unknown:helper")) kc["helper"]++
      if (has(st, "unknown:uncommitted") || has(st, "unknown:unpushed") || has(st, "unknown:unproposed") || has(st, "unknown:pr-closed-unlanded") || has(st, "unknown:orphan") || has(st, "unknown:chip-unstarted")) kc["never-proposed"]++
      # B16: a helper row that would be in never-proposed but for helper is counted, or, with the unknown form of one of those states, makes the count a lower bound.
      if (g == "helper") {
        if (has(st, "uncommitted") || has(st, "unpushed") || has(st, "unproposed") || has(st, "pr-closed-unlanded") || (has(st, "orphan") && V[8] != "landed")) hw++
        else if (has(st, "unknown:uncommitted") || has(st, "unknown:unpushed") || has(st, "unknown:unproposed") || has(st, "unknown:pr-closed-unlanded") || has(st, "unknown:orphan")) hu++ } } }
  # RTAG, not RT: gawk, the awk of the Linux CI runner, keeps RT as a scalar and stops on it as an array.
  n = ++NG[g]; R[g, n] = row; RTAG[g, n] = tag; RN[g, n] = num + 0
}
END {
  if (repo == "") repo = dflt
  ghbad = (!ghseen || (ghfw != "read" && ghfw != "none"))
  ng = split(order, G, " ")
  for (gi = 1; gi <= ng; gi++) {
    g = G[gi]; calc(g)
    if (substr(g, 1, 3) == "pr-") for (i = 2; i <= NG[g]; i++) {   # land pr rows by ascending number
      r = R[g, i]; t = RTAG[g, i]; m = RN[g, i]
      for (j = i; j > 1 && RN[g, j - 1] > m; j--) { R[g, j] = R[g, j - 1]; RTAG[g, j] = RTAG[g, j - 1]; RN[g, j] = RN[g, j - 1] }
      R[g, j] = r; RTAG[g, j] = t; RN[g, j] = m } }
  if (tsv == 1) {
    for (gi = 1; gi <= ng; gi++) { g = G[gi]
      printf "%s\tsummary\t%s\t%s\t%s\t-\t-\t%s\t%s\n", g, repo, g, (INC[g] ? "incomplete" : "complete"), (INC[g] && !NG[g] ? "unknown" : NG[g] + 0), (INC[g] ? REA[g] : "-") }
    for (i = 1; i <= ncv; i++) printf "cover\t%s\n", CV[i]
    for (gi = 1; gi <= ng; gi++) { g = G[gi]; for (i = 1; i <= NG[g]; i++) printf "%s\t%s\n", g, R[g, i] }
    exit }
  print repo
  for (i = 1; i <= ncv; i++) { split(CV[i], f, "\t"); print "  read " f[3] " " f[4] ": " f[8] }
  print "  needs you"
  split("hazard blocked question never-proposed pr-founder pr-session pr-lander pr-unknown undecided", L, " ")
  LAB["hazard"] = "hazards"; LAB["blocked"] = "blocked sessions"; LAB["question"] = "open questions"; LAB["never-proposed"] = "work that never reached a PR"
  LAB["pr-founder"] = "pull requests waiting on the founder"; LAB["pr-session"] = "pull requests waiting on a session"
  LAB["pr-lander"] = "pull requests ready for the lander"; LAB["pr-unknown"] = "pull requests not decided"; LAB["undecided"] = "rows not decided"
  for (li = 1; li <= 9; li++) { g = L[li]
    print "    " LAB[g] ": " CS[g] (INC[g] ? " (" REA[g] ")" : "")
    for (i = 1; i <= NG[g]; i++) print rline(g, i) }
  print "  collapsed: running " CS["running"] ", helper worktrees " CS["helper"] ", pull requests waiting on nobody " CS["pr-nobody"] ", proposed " CS["proposed"] ", carried " CS["carried"] ", handoff sections " CS["handoff"] ", landed " CS["landed"] ", quiet " CS["quiet"]
  if (hw + hu > 0) print "  helper worktrees holding work that never reached a PR: " (hu ? (hw ? "at least " hw : "unknown") : hw)
}'
