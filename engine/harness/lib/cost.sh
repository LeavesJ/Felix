# felix cost: how many tokens Claude Code spent, read from the transcripts it
# already keeps. A proxy for plan usage, in input-equivalent tokens, never the
# plan's own number: an input token is 1, a cache write 1.25 (five minutes) or 2
# (an hour), a cache read 0.1 and an output token 5, the API's price ratios.
#
# Why it exists. On 2026-10-08 forty-one fix sessions spent 47% of a week's
# allowance in seven hours, and nothing in Felix could say so while it was
# happening (audits/2026-10-09-token-burn in the memory root). This is the
# reading a governor needs before it can limit anything.
#
# Read-only towards everything it counts, like felix audit: the CLI dispatches
# it before a home is resolved, and it never writes under the records root or a
# home. Since 2026-11-06 it writes one thing, its readings and their lock under
# $HOME/.cache/felix/cost, so that one scan serves every caller and no caller
# waits behind another's (lib/cost-cache.sh, and docs/2026-11-06-load-governor-
# design.md section 5, clauses C1-C13). Without a HOME, a writable cache or
# perl, it scans inline and writes nothing, as before.
#
# Two stages. The scan (stage 1, _FC_SCAN_AWK) reads the transcripts and emits
# one row per response id, settled as below; the totals (stage 2, _FC_SUM_AWK)
# take the window, the cap and the view to those rows. A reading is stage 1's
# output, kept; a reading serves every --by, --top, --tsv and cap of its window.
#
# Records. The root is $CLAUDE_CONFIG_DIR/projects when that is set and
# non-empty, else $HOME/.claude/projects (the host adapter's session reader
# takes the same root). Under it a session is <E>/*.jsonl, E a working directory's record
# directory, and its helper agents are every *.jsonl under <E>/<sid>/subagents/:
# an Agent call's directly, a workflow's two levels down in workflows/<run>/
# (measured 2026-10-11: 222 of the week's 626 transcripts, and 152M of its
# 570M, sat there). Nothing else is read. Links are followed (find -L), since a
# records root moved to another disk is usually a link; a loop or a dangling
# link is unread. A file last written before the window opened cannot hold a
# record from inside it, so find's -mmin, with two minutes to spare, keeps it
# out: a week is about a gigabyte of transcripts and a summer ten. It is cut to
# the second with -newermt (BSD and GNU find both read "YYYY-MM-DD HH:MM:SS
# UTC"), and to the minute with -mmin where find has no -newermt.
#
# One response, once. Claude Code writes a line per content block of a
# response, each carrying the usage so far, so within a file the last line of
# a message id wins. A forked session or a workflow copies lines into another
# file, sometimes only the early ones (one response in 21 days of the founder's
# record sat in a workflow's file with a partial usage), so across files the
# largest usage wins. Either way an id is counted once.
#
# Which line is a response. A whole line (it opens with { and closes with },
# after any \r) whose own type is assistant, whose message has role assistant,
# an id and a usage object, and whose model is not <synthetic>. The line's own
# type and time are the last "type":"...","uuid":"...","timestamp":"..." in it:
# Claude Code writes them after the message and after wireToolInputs, so a tool
# input that quotes such a triple comes first, and a progress or attachment
# record that nests an assistant message names its own type last (no line of
# 432,371 read on 2026-10-11 had its own triple anywhere else), or, as
# lib/audit.sh tells it, before its message. No JSON parser,
# on purpose (lib/audit.sh says why): inside a JSON string every quote is
# escaped, so a "key": pattern only matches structure.
#
# The usage object. Every real response line holds one "usage":{ after its
# message opens, before any wireToolInputs. A line with a second, or with its
# only one after wireToolInputs, cannot tell the response's usage from a tool
# input's, and is counted as a response that could not be read rather than
# guessed. Its top-level counts are read and usage.iterations never is: it
# repeats them, and reading it would count a response twice. So every
# container nested in usage is folded away, innermost first, and the counts are
# read from what is left, cache_creation's two from the one container kept by
# name. Key order is not relied on. No string in a usage object holds a bracket
# (its strings are tiers, regions and speeds); one that did would fold wrong
# and read as no usage, never as a larger one.
#
# The window. A plan week opens Thursday 13:00:00Z (the Unix epoch was a
# Thursday, so a week start is 13 h plus a whole number of weeks) and runs
# seven days; --since opens at an instant and has no end. A record counts when
# start <= its timestamp < end, compared as ISO 8601 strings. FELIX_COST_NOW
# sets the instant taken as now. Dates are integer arithmetic, so BSD and GNU
# date differ in nothing used here.
#
# Unread is unknown, never zero. No root, or one that holds no transcript of
# any age, is unknown. A file or directory that cannot be read is counted, and
# so is a response that cannot (no time, or a usage it cannot place), and the
# total is then a floor; a floor of nothing is unknown.
#
# Forks: date once, then find and sort once, and one grep per 256 files, so
# never one per line or per file. One awk settles the responses and one totals
# them; lib/cost-cache.sh adds a find, a cksum and a perl around a scan.

FELIX_COST_CAP_M_DEFAULT=905

felix_cost_usage() {
  printf 'usage: felix cost [--week | --since YYYY-MM-DD[THH:MM]] [--by worktree|day|model] [--top N] [--tsv] [--max-age SECONDS]\n'
}
_fc_refuse() { printf 'felix cost: %s\n' "$1" >&2; felix_cost_usage >&2; return 2; }

# _FC_E: seconds since the epoch of Y M D h m s (UTC), from the civil date by
# days-from-civil. Fields may carry leading zeros; they are read base 10.
_fc_epoch() {
  local y=$((10#$1)) m=$((10#$2)) d=$((10#$3)) era yoe doy doe
  [ "$m" -le 2 ] && y=$((y - 1))
  era=$((y / 400)); yoe=$((y - era * 400))
  if [ "$m" -gt 2 ]; then doy=$(((153 * (m - 3) + 2) / 5 + d - 1)); else doy=$(((153 * (m + 9) + 2) / 5 + d - 1)); fi
  doe=$((yoe * 365 + yoe / 4 - yoe / 100 + doy))
  _FC_E=$(((era * 146097 + doe - 719468) * 86400 + 10#$4 * 3600 + 10#$5 * 60 + 10#$6))
}
# _FC_ISO: YYYY-MM-DDTHH:MM:SS of an epoch second at or after 1970.
_fc_iso() {
  local s=$1 z r era doe yoe y doy mp d m
  z=$((s / 86400 + 719468)); r=$((s % 86400))
  era=$((z / 146097)); doe=$((z - era * 146097))
  yoe=$(((doe - doe / 1460 + doe / 36524 - doe / 146096) / 365))
  y=$((yoe + era * 400)); doy=$((doe - (365 * yoe + yoe / 4 - yoe / 100)))
  mp=$(((5 * doy + 2) / 153)); d=$((doy - (153 * mp + 2) / 5 + 1))
  if [ "$mp" -lt 10 ]; then m=$((mp + 3)); else m=$((mp - 9)); fi
  [ "$m" -le 2 ] && y=$((y + 1))
  printf -v _FC_ISO '%04d-%02d-%02dT%02d:%02d:%02d' "$y" "$m" "$d" $((r / 3600)) $((r % 3600 / 60)) $((r % 60))
}
# _FC_E for Y M D h m s when that is a real instant, status 1 when not: the
# civil date it names must come back from its own epoch.
_fc_real() {
  [ "$((10#$4))" -le 23 ] && [ "$((10#$5))" -le 59 ] && [ "$((10#$6))" -le 59 ] || return 1
  [ "$((10#$1))" -ge 1970 ] && [ "$((10#$2))" -ge 1 ] && [ "$((10#$2))" -le 12 ] && [ "$((10#$3))" -ge 1 ] || return 1
  _fc_epoch "$@"; _fc_iso "$_FC_E"
  [ "${_FC_ISO:0:10}" = "$1-$2-$3" ]
}

# felix cost [--week | --since D] [--by F] [--top N] [--tsv]
felix_cost() {
  local -x LC_ALL=C
  local by="" top="" tsv=0 since="" maxage="" deadline cap root froot where now real start end
  local re_since='^([0-9]{4})-([0-9]{2})-([0-9]{2})(T([0-9]{2}):([0-9]{2}))?$'
  local re_now='^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2})(:([0-9]{2}))?Z$'
  local re_cap='^([0-9]+(\.[0-9]*)?|\.[0-9]+)$'
  while [ $# -gt 0 ]; do
    case "$1" in
      --week) since=""; shift ;;
      --since) [ -n "${2:-}" ] || { _fc_refuse "--since needs a date, YYYY-MM-DD or YYYY-MM-DDTHH:MM"; return; }
               since="$2"; shift 2 ;;
      --by) case "${2:-}" in worktree|day|model) by="$2"; shift 2 ;; *) _fc_refuse "--by takes worktree, day or model"; return ;; esac ;;
      --top) [[ "${2:-}" =~ ^[0-9]{1,9}$ ]] && [ "$((10#$2))" -gt 0 ] || { _fc_refuse "--top takes a positive whole number"; return; }
             top=$((10#$2)); shift 2 ;;
      --tsv) tsv=1; shift ;;
      --max-age) [[ "${2:-}" =~ ^[0-9]{1,6}$ ]] && [ "$((10#$2))" -le 604800 ] \
                   || { _fc_refuse "--max-age takes a whole number of seconds from 0 to 604800"; return; }
                 maxage=$((10#$2)); shift 2 ;;
      -h|--help) felix_cost_usage; return 0 ;;
      *) _fc_refuse "unknown argument: $1"; return ;;
    esac
  done
  cap="${FELIX_COST_CAP_M:-$FELIX_COST_CAP_M_DEFAULT}"
  [[ "$cap" =~ $re_cap ]] && [[ "$cap" =~ [1-9] ]] \
    || { _fc_refuse "FELIX_COST_CAP_M is not a positive number: $cap"; return; }
  deadline="${FELIX_COST_DEADLINE:-1800}"
  [[ "$deadline" =~ ^[0-9]{1,5}$ ]] && [ "$((10#$deadline))" -ge 1 ] && [ "$((10#$deadline))" -le 86400 ] \
    || { _fc_refuse "FELIX_COST_DEADLINE is not a whole number of seconds from 1 to 86400: $deadline"; return; }
  deadline=$((10#$deadline))

  real="$(date -u +%s)"
  case "$real" in ''|*[!0123456789]*) printf 'felix cost: the clock could not be read\n' >&2; return 1 ;; esac
  now=$real
  if [ -n "${FELIX_COST_NOW:-}" ]; then
    [[ "$FELIX_COST_NOW" =~ $re_now ]] \
      && _fc_real "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[7]:-00}" \
      && [ "$_FC_E" -ge 46800 ] \
      || { _fc_refuse "FELIX_COST_NOW is not YYYY-MM-DDTHH:MM[:SS]Z from 1970-01-01T13:00Z on: $FELIX_COST_NOW"; return; }
    now=$_FC_E
  fi
  if [ -n "$since" ]; then
    [[ "$since" =~ $re_since ]] \
      && _fc_real "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[5]:-00}" "${BASH_REMATCH[6]:-00}" 00 \
      || { _fc_refuse "--since is not a real YYYY-MM-DD or YYYY-MM-DDTHH:MM: $since"; return; }
    start=$_FC_E; end=""
  else
    start=$((((now - 46800) / 604800) * 604800 + 46800)); end=$((start + 604800))
  fi

  if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then root="$CLAUDE_CONFIG_DIR/projects"; where='$CLAUDE_CONFIG_DIR/projects'
  elif [ -n "${HOME:-}" ]; then root="$HOME/.claude/projects"; where='$HOME/.claude/projects'
  else root=""; where='$HOME/.claude/projects'; fi
  case "$root" in -*) froot="./$root" ;; *) froot="$root" ;; esac

  local s_iso e_iso="" n_iso e_say any=0 f prune
  _fc_iso "$start"; s_iso="$_FC_ISO"
  [ -z "$end" ] || { _fc_iso "$end"; e_iso="$_FC_ISO"; }
  _fc_iso "$now"; n_iso="$_FC_ISO"
  if [ -n "$since" ]; then e_say=now; else e_say="${e_iso:0:16}Z"; fi
  if [ -n "$root" ] && [ -d "$root" ]; then
    for f in "$root"/*/*.jsonl; do [ -f "$f" ] && { any=1; break; }; done
    [ "$any" = 1 ] || for f in "$root"/*/*/subagents/*.jsonl "$root"/*/*/subagents/*/*/*.jsonl; do [ -f "$f" ] && { any=1; break; }; done
  fi
  # Modified after the second before the window opened, or, where find has no
  # -newermt, within the minutes since then and two more.
  _fc_iso $((start - 1))
  if find "$froot" -maxdepth 0 -newermt "${_FC_ISO/T/ } UTC" >/dev/null 2>&1; then
    prune="-newermt|${_FC_ISO/T/ } UTC"
  else
    prune=$(((real - start) / 60 + 2)); [ "$prune" -ge 1 ] || prune=1; prune="-mmin|-$prune"
  fi

  # What stage 2 is given, in _fc_sum's order: window, the view, and the words.
  _FC_V=("$s_iso" "$e_iso" "$e_say" "${n_iso:0:16}Z" "$cap" "$by" "$top" "$tsv" "$where")
  if _fcc_dir && _fcc_key "$froot" "$s_iso" "$e_iso"; then
    _fcc_serve "$froot" "${prune%%|*}" "${prune#*|}" "$any" "$real" "$maxage" "$deadline"
    return
  fi
  _fc_scan "$froot" "${prune%%|*}" "${prune#*|}" "$any" | _fc_sum "" "" ""
}

# Stage 1 for the transcripts under ROOT, modified as TEST VALUE says, with ANY
# 1 when a transcript of any age is there: a C row (files read, files unread,
# ANY) and one R row per response id (weight in hundredths or -1, time, model,
# id, record directory; the directory last, so a tab in it shifts nothing).
_fc_scan() {   # ROOT TEST VALUE ANY
  { if [ -n "$1" ] && [ -d "$1" ]; then _fc_files "$1" "$2" "$3"; fi; } \
    | FC_ROOT="$1" awk -v any="$4" "$_FC_SCAN_AWK"
}

# Stage 2 over stage 1's rows on stdin, for the window and view in _FC_V, as
# felix_cost set it. SERVED is empty for a reading that is current, else aged,
# last or none (a cover row, C5 and C6); LINE is the text view's served line;
# WHY is the reason a "none" gives. ASOF, when given, replaces _FC_V's.
_fc_sum() {   # SERVED LINE WHY [ASOF]
  awk -v start="${_FC_V[0]}" -v end="${_FC_V[1]}" -v esay="${_FC_V[2]}" -v asof="${4:-${_FC_V[3]}}" \
      -v cap="${_FC_V[4]}" -v by="${_FC_V[5]}" -v top="${_FC_V[6]}" -v tsv="${_FC_V[7]}" -v where="${_FC_V[8]}" \
      -v served="$1" -v sline="$2" -v nwhy="$3" "$_FC_SUM_AWK"
}

# The transcripts of the window under ROOT, modified as TEST VALUE says, as
# grep -H prints their lines that
# hold a usage, for the awk below; \002 is a grep that could not read a file,
# and the last line, \003 read unread, counts the files. Always status 0: find
# returns 1 for a directory it could not enter, which is counted, not fatal.
_fc_files() {
  local root="$1" pt="$2" pv="$3" p rel r2 nread=0 unread=0 rc
  local -a fs=()
  unset GREP_OPTIONS GREP_COLOR GREP_COLORS
  find -L "$root" -mindepth 2 -name '*.jsonl' \( \( -type f "$pt" "$pv" \) -o -type l \) -print 2>&1 | LC_ALL=C sort | {
    while IFS= read -r p; do
      case "$p" in "$root"/*) rel="${p#"$root"/}" ;; *) unread=$((unread + 1)); continue ;; esac
      r2="${rel#*/}"
      case "$r2" in */*) r2="${r2#*/}"; case "$r2" in subagents/*.jsonl) ;; *) continue ;; esac ;; esac
      [ -f "$p" ] && [ -r "$p" ] || { unread=$((unread + 1)); continue; }
      fs[${#fs[@]}]="$p"; nread=$((nread + 1))
      if [ "${#fs[@]}" -ge 256 ]; then
        grep -a -H -s -F -e '"usage":{' -- "${fs[@]}"; rc=$?; [ "$rc" -le 1 ] || printf '\002\n'; fs=()
      fi
    done
    if [ "${#fs[@]}" -gt 0 ]; then
      grep -a -H -s -F -e '"usage":{' -- "${fs[@]}"; rc=$?; [ "$rc" -le 1 ] || printf '\002\n'
    fi
    printf '\003\t%d\t%d\n' "$nread" "$unread"
  }
  return 0
}

# shellcheck disable=SC2016
_FC_SCAN_AWK='
  # The number after KEY in S, 0 when S has none.
  function num(s, key,    p, v) {
    if (!(p = index(s, key))) return 0
    v = substr(s, p + length(key), 24)
    return match(v, /^[0-9]+/) ? substr(v, 1, RLENGTH) + 0 : 0
  }
  # A response s weight in hundredths of an input token, from S, a usage
  # object from its "{" on; -1 when it does not close inside S. Brackets turn
  # into \004 and \005 so that FOLD needs no bracket inside a bracket list,
  # then nested containers fold into \001k\002, innermost first, kept in F[k],
  # until the usage object itself is folded.
  function weight(s,    n, top, k, cc, c5, c1) {
    gsub(/\[/, "\004", s); gsub(/\]/, "\005", s); n = 0
    while (substr(s, 1, 1) != "\001") {
      if (!match(s, FOLD)) return -1
      F[++n] = substr(s, RSTART, RLENGTH)
      s = substr(s, 1, RSTART - 1) "\001" n "\002" substr(s, RSTART + RLENGTH)
    }
    top = F[n]
    if ((k = index(top, "\"cache_creation\":\001"))) {
      k = substr(top, k + 18); cc = F[substr(k, 1, index(k, "\002") - 1)]
      c5 = num(cc, "\"ephemeral_5m_input_tokens\":"); c1 = num(cc, "\"ephemeral_1h_input_tokens\":")
    } else { c5 = num(top, "\"cache_creation_input_tokens\":"); c1 = 0 }
    return 100 * num(top, "\"input_tokens\":") + 125 * c5 + 200 * c1 \
         + 10 * num(top, "\"cache_read_input_tokens\":") + 500 * num(top, "\"output_tokens\":")
  }
  # The string value after KEY in S, "" when none.
  function str(s, key,    p, v) {
    if (!(p = index(s, key))) return ""
    v = substr(s, p + length(key), 256)
    return substr(v, 1, index(v, "\"") - 1)
  }
  BEGIN {
    FOLD = "[{\004][^{}\004\005]*[}\005]"
    OWN = "\"type\":\"[A-Za-z_-]*\",\"uuid\":\"[^\"]*\",\"timestamp\":\"[^\"]*\""
    rl = length(ENVIRON["FC_ROOT"])
  }
  substr($0, 1, 1) == "\002" { unread++; next }
  substr($0, 1, 1) == "\003" { split($0, c, "\t"); nread = c[2]; unread += c[3]; next }
  {
    if (!(k = index($0, ".jsonl:{"))) next
    file = substr($0, 1, k + 5); l = substr($0, k + 7)
    if (substr(l, length(l), 1) == "\r") l = substr(l, 1, length(l) - 1)
    if (substr(l, length(l), 1) != "}") next
    if (!index(l, "\"type\":\"assistant\"")) next
    # The line s own type and time: the last triple in it.
    own = ""; rest = l
    while (match(rest, OWN)) { own = substr(rest, RSTART, RLENGTH); rest = substr(rest, RSTART + RLENGTH) }
    if (substr(own, 1, 19) != "\"type\":\"assistant\",") next
    t = own; sub(/.*"timestamp":"/, "", t); sub(/"$/, "", t)
    if (t !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T/) t = ""
    if (!(im = index(l, "\"message\":{"))) next
    p = index(l, "\"type\":\""); if (p && p < im && substr(l, p, 18) != "\"type\":\"assistant\"") next
    r = substr(l, im + 11)
    if (!(p = index(r, "\"role\":\"")) || substr(r, p + 8, 10) != "assistant\"") next
    if ((id = str(r, "\"id\":\"")) == "") next
    mo = str(r, "\"model\":\""); if (mo == "<synthetic>") next; if (mo == "") mo = "?"
    if (!(u = index(r, "\"usage\":{"))) next
    wt = index(r, "\"wireToolInputs\":")
    if (index(substr(r, u + 9), "\"usage\":{") || (wt && wt < u)) w = -1
    else { w = weight(substr(r, u + 8, 2048)); if (w < 0) w = weight(substr(r, u + 8)); if (w < 0) w = -1 }
    rel = substr(file, rl + 2); e = substr(rel, 1, index(rel, "/") - 1)
    # Within a file the last line of an id wins, kept in L* until the file
    # ends (one that can be weighed over one that cannot); then across files
    # the largest, in settle(). grep -H keeps a file s lines together.
    if (file != CF) { settle(); CF = file }
    if (w < 0 && (id in LW) && LW[id] >= 0) next
    LW[id] = w; LT[id] = t; LE[id] = e; LM[id] = mo
  }
  function settle(    id) {
    for (id in LW) if (!(id in W) || LW[id] > W[id]) { W[id] = LW[id]; T[id] = LT[id]; WE[id] = LE[id]; WM[id] = LM[id] }
    for (id in LW) { delete LW[id]; delete LT[id]; delete LE[id]; delete LM[id] }
  }
  # The rows stage 2 reads: C, then one R per id, then E, so a reading that
  # ends before E was cut short.
  END {
    settle()
    printf "C\t%d\t%d\t%d\n", nread, unread, any
    for (id in W) printf "R\t%.0f\t%s\t%s\t%s\t%s\n", W[id], T[id], WM[id], id, WE[id]
    print "E"
  }
'

# Stage 2. Reads stage 1's rows (anything else, a reading's H line included, is
# passed over) and prints the report exactly as one pass did before the split,
# or nothing, status 3, when the rows did not end with E.
# served, sline and nwhy are _fc_sum's: the cover row, the text line, and the
# reason a "none" gives.
# shellcheck disable=SC2016
_FC_SUM_AWK='
  BEGIN { capt = cap * 1000000 }
  $0 == "E" { sawE = 1; next }
  substr($0, 1, 2) == "C\t" { split($0, c, "\t"); nread = c[2] + 0; unread = c[3] + 0; any = c[4] + 0; next }
  substr($0, 1, 2) == "R\t" {
    r = substr($0, 3)
    k = index(r, "\t"); w = substr(r, 1, k - 1); r = substr(r, k + 1)
    k = index(r, "\t"); t = substr(r, 1, k - 1); r = substr(r, k + 1)
    k = index(r, "\t"); mo = substr(r, 1, k - 1); r = substr(r, k + 1)
    k = index(r, "\t"); id = substr(r, 1, k - 1)
    W[id] = w + 0; T[id] = t; WM[id] = mo; WE[id] = substr(r, k + 1)
    next
  }
  # Keys of A (n of them, in K) ordered: by value largest first then key, or
  # by key alone when bykey. An insertion sort: there are tens of keys, not
  # thousands.
  function order(A, K, n, bykey,    i, j, x) {
    for (i = 2; i <= n; i++) {
      x = K[i]
      for (j = i - 1; j >= 1; j--) {
        if (bykey ? (K[j] <= x) : (A[K[j]] > A[x] || (A[K[j]] == A[x] && K[j] <= x))) break
        K[j + 1] = K[j]
      }
      K[j + 1] = x
    }
  }
  function pct(h) { return sprintf("%.1f", h / capt) }
  function mil(h) { return sprintf("%.1fM", h / 100000000) }
  function facet(name, A, C,    K, n, k, i, lim, head) {
    n = 0; for (k in A) K[++n] = k
    order(A, K, n, name == "day")
    lim = (name == "day") ? n : (top != "" ? top + 0 : (tsv ? n : 10))
    if (tsv) { for (i = 1; i <= n && i <= lim; i++) printf "%s\t%s\t%.2f\t%s\t%d\n", name, K[i], A[K[i]] / 100, pct(A[K[i]]), C[K[i]]; return }
    head = (name == "day") ? "days" : (name == "worktree" ? "worktrees" : "models")
    if (!n) { printf "%s: none in the window\n", head; return }
    if (name == "day") printf "days (UTC): millions, percent of the cap\n"
    else printf "%s, top %d of %d: percent of the cap, millions, %s\n", head, (lim < n ? lim : n), n, (name == "worktree" ? "record directory" : "model")
    for (i = 1; i <= n && i <= lim; i++)
      if (name == "day") printf "  %s  %8s  %5s%%\n", K[i], mil(A[K[i]]), pct(A[K[i]])
      else printf "  %5s%%  %8s  %s\n", pct(A[K[i]]), mil(A[K[i]]), K[i]
  }
  END {
    # Stage 1 ends its rows with E. Without it the scan died, and nothing is
    # printed: the one pass printed nothing then either (a "none" has no rows).
    if (served != "none" && !sawE) exit 3
    for (id in W) {
      if (T[id] != "" && (T[id] < start || (end != "" && T[id] >= end))) continue
      if (T[id] == "" || W[id] < 0) { runread++; continue }
      h = W[id]; tot += h; calls++
      WT[WE[id]] += h; WC[WE[id]]++
      d = substr(T[id], 1, 10); DT[d] += h; DC[d]++
      MT[WM[id]] += h; MC[WM[id]]++
    }
    if (nread + unread > 0) any = 1
    cov = "measured"; why = ""
    if (!any) { cov = "unknown"; why = "no session records under " where }
    else if (unread || runread) cov = (tot > 0) ? "floor" : "unknown"
    if (served == "none") { cov = "unknown"; why = nwhy }
    if (cov == "unknown" && why == "") why = (unread ? unread " could not be read" : "") (unread && runread ? ", " : "") (runread ? runread " responses could not be read" : "") ", and nothing readable was in the window"
    s16 = substr(start, 1, 16) "Z"
    if (tsv) {
      printf "cover\twindow_start\t%s\ncover\twindow_end\t%s\ncover\tsource\t%s\n", s16, esay, where
      printf "cover\tcap_tokens\t%.0f\ncover\tfiles_read\t%d\ncover\tfiles_unread\t%d\n", capt, nread, unread
      printf "cover\tresponses_unread\t%d\ncover\tcoverage\t%s\ncover\tas_of\t%s\n", runread, cov, asof
      if (served != "") printf "cover\tserved\t%s\n", served
      if (cov == "unknown") { printf "total\tall\tunknown\tunknown\tunknown\n"; exit }
      printf "total\tall\t%.2f\t%s\t%d\n", tot / 100, pct(tot), calls
      if (by == "" || by == "worktree") facet("worktree", WT, WC)
      if (by == "" || by == "day") facet("day", DT, DC)
      if (by == "" || by == "model") facet("model", MT, MC)
      exit
    }
    printf "felix cost: read-only. A proxy for plan usage in input-equivalent tokens, not the plan%ss own number.\n", "\047"
    printf "window   %s to %s\n", s16, esay
    if (sline != "") printf "served   %s\n", sline
    if (cov == "unknown") {
      printf "total    unknown (%s)\ncalls    unknown\n", why
      if (any) printf "files    %d read, %d could not be read under %s\n", nread, unread, where
      exit
    }
    printf "total    %s%s  %s%% of a %sM week\n", (cov == "floor" ? "at least " : ""), mil(tot), pct(tot), cap
    printf "calls    %d\n", calls
    if (unread) printf "files    %d read, %d could not be read under %s: the total is a floor\n", nread, unread, where
    else printf "files    %d read under %s\n", nread, where
    if (runread) printf "responses %d could not be read (no time, or a usage not told apart from a tool input): the total is a floor\n", runread
    if (by == "" || by == "worktree") facet("worktree", WT, WC)
    if (by == "" || by == "day") facet("day", DT, DC)
    if (by == "model") facet("model", MT, MC)
  }
'
