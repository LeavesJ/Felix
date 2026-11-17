# felix inventory's host adapter: what only Claude Code's own session records
# can say about a directory. lib/inventory.sh holds everything git and GitHub
# can answer and asks this file through the functions below; a second host is a
# second file defining the same names. Nothing here runs git.
#
# Records. A directory D is filed under <root>/E: root is $CLAUDE_CONFIG_DIR/projects
# when that is set and non-empty, else $HOME/.claude/projects, and E is D with
# every UTF-16 unit outside [A-Za-z0-9] replaced by '-' (_fi_host_enc does it
# bytewise). An E over 200 characters is cut there and followed by '-' and a hash
# not computed here: the one directory whose name starts so is taken, two are
# unknown. D is looked up as git lists it and as the kernel resolves it. A session
# is a top-level *.jsonl; <session-id>/ beside it holds helpers' records and side
# files, never read, but a file written there is that session's activity. Nothing
# else in a record directory is (the auto-memory's memory/ has no sibling .jsonl).
#
# Time. The host appends bookkeeping lines without a "timestamp" to idle
# sessions, so a file's mtime says nothing about when anyone worked. A session's
# record time is the newest "timestamp" of a user or assistant record in its last
# 256 KiB (the mtime stands in, and is said, with none); the newest session is the
# latest by it. A directory's activity time is the newest of every session's
# record time, the mtime of every file under a session's directory and a spawning
# agent's transcript (a *.meta.json under <sid>/subagents/ names the worktree).
#
# Ends. The window is read by awk, counting only whole lines and user and
# assistant records. question: the final text asks (_FI_HOST_ASK) and no human
# text follows it. blocked: the last record is a tool call with no result,
# BLOCKED minutes old, and nothing under the session's directory was written
# within them. No whole line is unknown.
#
# A plugin's session is not the worktree's (audit b09, C028). A record's entrypoint
# is the value after the last "entrypoint":" in its line (a tool input or a quoted
# text comes before the record's own). A session file whose last user or assistant
# record that names one, in the window, names one beginning sdk- is an SDK session:
# the reviewer security-guidance starts at a Stop or a commit, filed in the same
# record directory after the person's last turn. It is read as absent: never the
# owner, no question or blocked, no activity (nor its <sid>/ files), and a pull
# request's owner is never read from such a record. A directory with no other
# session says how many were passed over. One whose entrypoint is not seen, or
# that cannot be read, is not known to be one.
#
# Unread is unknown. A session file the run cannot read has no record time, so
# its mtime orders it but is no activity: live is unknown unless a readable file
# makes it live, the owner is unknown when it is the newest, a pull request's
# owner is unknown when it is newer than the owner's record, and a chip proposed
# before it, in any record directory under the root (a chip's session is usually
# a new worktree's), is unknown, not unstarted. A record directory it cannot enter
# answers unknown throughout. All are counted (felix_inv_host_unread) for the cover row.
# A records root the run cannot both list and enter (felix_inv_host_open) is all
# unread: the core reads none of it, and the cover rows say unknown, not read.
#
# Helpers. A worktree named as a subagent's or a workflow's is a helper's
# (felix_inv_host_helper_form, by name alone). The last field of
# felix_inv_host_dir's line says whether the records name it. The core learns
# it from that field, and with no field asks felix_inv_host_helper_form; it
# never reads the detail text, and the name rule stays here, so a second host
# decides it its own way.
#
# No JSON parser (lib/audit.sh says why) and no here-document (bash 3.2 backs
# one with a file outside the scratch).

FELIX_INV_HOST_NAME="Claude Code"

# The records root, when it exists.
_fi_host_root() {
  local r
  if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then r="$CLAUDE_CONFIG_DIR/projects"; elif [ -n "${HOME:-}" ]; then r="$HOME/.claude/projects"; else return 1; fi
  [ -d "$r" ] && printf '%s' "$r"
}
# What the cover row for sessions says was read; status 1 when there is nothing to read.
felix_inv_host_where() {
  _fi_host_root >/dev/null || return 1
  if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then printf '%s session records under $CLAUDE_CONFIG_DIR/projects' "$FELIX_INV_HOST_NAME"; else printf '%s session records under $HOME/.claude/projects' "$FELIX_INV_HOST_NAME"; fi
}
# Status 0 when the run can list the records root and enter it, else 1: a root
# that exists but cannot is unknown throughout, not an empty one (C047). The
# listing itself is tried, since a sandbox can pass -r and -x and still refuse it.
felix_inv_host_open() {
  local r; r="$(_fi_host_root)" || return 1
  [ -r "$r" ] && [ -x "$r" ] && ls -A "$r" >/dev/null 2>&1
}
# E for a directory, as Claude Code spells it.
_fi_host_enc() {
  local LC_ALL=C
  case "$1" in
    *[!\ -~]*) printf '%s' "$1" | LC_ALL=C awk 'BEGIN { RS = "\001" }
        { n = length($0); for (i = 1; i <= n; i++) { c = substr($0, i, 1)
            if (c ~ /[A-Za-z0-9]/) o = o c; else if (c < "\200") o = o "-"; else if (c >= "\360") o = o "--"; else if (c >= "\300") o = o "-" } }
        END { printf "%s", o }' ;;
    *) printf '%s' "${1//[^A-Za-z0-9]/-}" ;;
  esac
}
# The record directory of E under root: printed if there is one; status 2
# when E was cut and more than one directory could be it.
_fi_host_one() {
  local x m=""
  if [ "${#2}" -le 200 ]; then [ -d "$1/$2" ] && printf '%s\n' "$1/$2"; return 0; fi
  for x in "$1/${2:0:200}"-*; do [ -d "$x" ] || continue; [ -z "$m" ] || return 2; m="$x"; done
  [ -z "$m" ] || printf '%s\n' "$m"
}
# The record directories of one working directory that exist, one per line;
# a line ? when one cannot be told from another's.
_fi_host_dirs() {
  local e p
  e="$(_fi_host_enc "$2")"; _fi_host_one "$1" "$e" || printf '?\n'
  p="$(cd "$2" 2>/dev/null && pwd -P)" || return 0
  [ -n "$p" ] && [ "$p" != "$2" ] || return 0
  p="$(_fi_host_enc "$p")"; [ "$p" = "$e" ] || _fi_host_one "$1" "$p" || printf '?\n'; return 0
}
# The record directories of each directory named, or, for one named with a
# trailing /, of every directory under it (filed under E(P) and '-').
_fi_host_scope() {
  local root="$1" d e p; shift
  for d in "$@"; do
    case "$d" in
      */) for p in "${d%/}" "$(cd "$d" 2>/dev/null && pwd -P)"; do
            [ -n "$p" ] || continue
            p="$(_fi_host_enc "$p")"; if [ "${#p}" -lt 200 ]; then p="$p-"; else p="${p:0:200}"; fi
            for e in "$root/$p"*; do [ -d "$e" ] && printf '%s\n' "$e"; done
          done ;;
      *) _fi_host_dirs "$root" "$d" | grep -v '^?$' ;;
    esac
  done
  return 0
}
# felix_inv_host_scope FILE DIR...: the record directories of a repository's
# worktrees, orphans and removed worktrees (a DIR ending in /) into FILE.
felix_inv_host_scope() {
  local f="$1" root; shift
  : > "$f"; root="$(_fi_host_root)" || return 0
  _fi_host_scope "$root" "$@" | LC_ALL=C sort -u > "$f"
}
# The awk the readers share: whose record a line is, the human text, a JSON
# string decoded far enough to compare, and times (a record's "timestamp" is
# the one right after its "uuid").
# shellcheck disable=SC2016
_FI_HOST_AWK='
  BEGIN {
    Q = "\""; K_MSG = "\"message\":{"; K_SIDE = "\"isSidechain\":true"; K_META = "\"isMeta\":true"
    K_USER = "\"type\":\"user\""; K_ASST = "\"type\":\"assistant\""; K_TYPE = "\"type\":\""
    K_RES = "\"type\":\"tool_result\""; K_STR = "\"role\":\"user\",\"content\":\""
    K_TXT = "\"type\":\"text\",\"text\":\""; K_TU = "\"type\":\"tool_use\",\"id\":\""
    K_TID = "\"tool_use_id\":\""; ENV_O = "<system-reminder>"; ENV_C = "</system-reminder>"
    K_NXT = "\"},{\"type\":\"text\",\"text\":\""; K_EP = "\"entrypoint\":\""
  }
  # The entrypoint a record names: the value after the last "entrypoint":" in its line, "" for none.
  function epv(l,    p, r) {
    r = ""
    while (p = index(l, K_EP)) { l = substr(l, p + length(K_EP)); r = l }
    return (r == "") ? "" : str(r)
  }
  # "u", "a", or "" for any other record or a line not whole, told as lib/audit.sh
  # tells it: an assistant type sits after its message, and any other type
  # before one is an attachment or progress record, which may nest a message.
  function kind(l,    im, p, v) {
    if (substr(l, 1, 1) != "{" || substr(l, length(l), 1) != "}") return ""
    im = index(l, K_MSG); if (!im) return ""
    p = index(l, K_SIDE); if (p && p < im) return ""
    if ((p = index(l, K_USER)) && p < im) return "u"
    if ((p = index(l, K_ASST)) && p < im) return "a"
    if ((p = index(l, K_TYPE)) && p < im) return ""
    p = index(l, "\"role\":\""); v = p ? substr(l, p + 8, 10) : ""
    if (v == "assistant\"") return "a"
    return substr(v, 1, 5) == "user\"" ? "u" : ""
  }
  # The raw JSON text a user record s human message starts with, from its first
  # character after any <system-reminder> blocks; "" when it holds none.
  function human(l,    p, r, e) {
    if (index(l, K_META) || index(l, K_RES)) return ""
    if (p = index(l, K_STR)) p += length(K_STR)
    else if (p = index(l, K_TXT)) p += length(K_TXT)
    else return ""
    r = substr(l, p, 65536)
    while (1) {
      sub(/^( |\\n|\\t|\\r)+/, "", r)
      if (substr(r, 1, length(ENV_O)) != ENV_O) break
      if (!(e = index(r, ENV_C))) return ""
      r = substr(r, e + length(ENV_C)); sub(/^( |\\n|\\t|\\r)+/, "", r)   # the blanks that follow a block go with it
      if (substr(r, 1, length(K_NXT)) == K_NXT) r = substr(r, length(K_NXT) + 1)   # a reminder item of its own: its text is the next item
    }
    e = substr(r, 1, 1)
    return (e == "" || e == Q || e == "<") ? "" : r
  }
  # A string value, raw, from its first character to the quote that ends it.
  function str(r) { return match(r, /^([^"\\]|\\.)*/) ? substr(r, 1, RLENGTH) : "" }
  function val(s, k,    p) { p = index(s, k); return p ? str(substr(s, p + length(k))) : "" }
  # Decoded far enough to compare two strings and to print one on a line; an
  # escaped backslash is held aside as \001 while the others are read.
  function dec(s,    i, o) {
    gsub(/\\\\/, "\001", s); gsub(/\\[nrt]/, " ", s); gsub(/\\"/, Q, s); gsub(/\\\//, "/", s); gsub(/\t/, " ", s)
    while (i = index(s, "\001")) { o = o substr(s, 1, i - 1) "\\"; s = substr(s, i + 1) }
    return o s
  }
  function key(r) { return substr(dec(substr(str(r), 1, 2048)), 1, 120) }
  # Text from a transcript, cut to its first 120 bytes on a whole UTF-8 character.
  function cut120(s,    c) {
    gsub(/[\t\n\r]/, " ", s); if (length(s) <= 120) return s
    c = substr(s, 121, 1); s = substr(s, 1, 120)
    if (c >= "\200" && c < "\300") {
      while (s != "" && substr(s, length(s)) >= "\200" && substr(s, length(s)) < "\300") s = substr(s, 1, length(s) - 1)
      if (s != "" && substr(s, length(s)) >= "\300") s = substr(s, 1, length(s) - 1) }
    return s
  }
  function ep(t,    y, mo, e) {
    if (t !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/) return ""
    y = substr(t, 1, 4) + 0; mo = substr(t, 6, 2) + 0; if (mo <= 2) { y--; mo += 12 }
    e = 365 * y + int(y / 4) - int(y / 100) + int(y / 400) + int((153 * (mo - 3) + 2) / 5) + substr(t, 9, 2) - 719469
    return e * 86400 + substr(t, 12, 2) * 3600 + substr(t, 15, 2) * 60 + substr(t, 18, 2)
  }
  # The epoch of a record, from the "timestamp" that follows its "uuid"; "" for none.
  function tsof(l,    t) {
    if (!match(l, /"uuid":"[^"]*","timestamp":"[^"]*"/)) return ""
    t = substr(l, RSTART, RLENGTH); sub(/.*"timestamp":"/, "", t); sub(/"$/, "", t); return ep(t)
  }
'

# Whether a final text, decoded with its line breaks kept, asks the person
# something: asks(t) is 1 or 0. Set aside first: curly quotes, fenced blocks,
# code spans, double-quoted spans and blockquote lines. It asks when a ? ends a
# line (only * _ ) " ' and blanks after it) in the last three paragraphs, or when
# an offer below appears as whole words with none of no, not, nothing, never,
# none in the 40 bytes before it, cut after the last . ! ? ; : or line break.
# Measured on 227 endings read by hand on 2026-09-24: 36 of 45 asks found and
# nothing else (tuned on them, not held out). \047 is the apostrophe.
# shellcheck disable=SC2016
_FI_HOST_ASK='
  BEGIN {
    AQ_B = "(^|[^a-z0-9_])"; AQ_E = "([^a-z0-9_]|$)"; AQ_L = "[?][*_)\"\047]*[ \t\r]*(\n|$)"
    AQ_N = "(^|[^a-z])(no|not|nothing|never|none)([^a-z]|$)"
    AQ_NP = split("your (call|decision|answer|options|side|sign-off|merge|go-ahead)@@([a-z]+\047s|is|are|still|all|both) yours|yours (to|rather)@@" \
      "(wait(s|ing)?|blocked) (on|for) your?@@needs? your?@@say (so|the word|yes|if|go)@@and i(\047ll| will)@@(want|like) me to|(should|shall) i@@" \
      "if you(\047d)? rather|if you (want|prefer)[^.?!]*, i(\047ll| can| will| could)|i(\047ll| can| could) [^.?!]* if you want@@(for|on) you:@@" \
      "(for|to) you to (decide|choose|approve|merge|review|start|run|confirm|pick)", AQ_P, "@@")
  }
  # An offer matched in t and not negated within its clause.
  function offer(t, re,    r, s0, off, rest, w) {
    r = AQ_B "(" re ")" AQ_E; off = 0; rest = t
    while (match(rest, r)) {
      s0 = off + RSTART; w = substr(t, s0 > 40 ? s0 - 39 : 1, s0 > 40 ? 40 : s0)
      while (match(w, /[.!?;:\n]/)) w = substr(w, RSTART + 1)
      if (w !~ AQ_N) return 1
      off = s0; rest = substr(t, off + 1)
    }
    return 0
  }
  function asks(t,    L, n, i, s, fence, cur, np, par, all, l3, k) {
    n = split(t, L, "\n"); np = 0; fence = 0; cur = ""
    for (i = 1; i <= n; i++) {
      s = L[i]
      if (s ~ /^[ \t]*(```|~~~)/) { fence = !fence; s = "" }
      else if (fence) s = ""
      else {
        gsub("\342\200\234|\342\200\235", "\"", s); gsub("\342\200\231", "\047", s)
        gsub(/`[^`]*`/, "", s); gsub(/"[^"]*"/, "", s)
        if (s ~ /^[ \t]*>/) s = ""
      }
      if (s ~ /^[ \t\r]*$/) { if (cur != "") par[++np] = cur; cur = "" }
      else cur = cur (cur != "" ? "\n" : "") s
    }
    if (cur != "") par[++np] = cur
    all = ""; l3 = ""
    for (i = 1; i <= np; i++) { all = all "\n" par[i]; if (i > np - 3) l3 = l3 "\n" par[i] }
    if (l3 ~ AQ_L) return 1
    all = tolower(all)
    for (k = 1; k <= AQ_NP; k++) if (offer(all, AQ_P[k])) return 1
    return 0
  }
'

# One session file's end, from its last 256 KiB, as one tab-separated line:
# whole-lines record-time question blocked call-time call-name sdk note (times
# are epochs or -, blocked is pending, no or unknown, sdk yes when the last record
# that names an entrypoint names one beginning sdk-, note the question's ending).
_fi_host_scan() {
  local size cut=0; size="$(wc -c 2>/dev/null < "$1" | tr -d ' ')"
  [ "${size:-0}" -gt 262144 ] && cut=1
  tail -c 262144 "$1" 2>/dev/null | awk -v cut="$cut" "$_FI_HOST_AWK$_FI_HOST_ASK"'
    NR == 1 && cut { next }
    { if (substr($0, 1, 1) == "{" && substr($0, length($0), 1) == "}") cl++
      k = kind($0); if (k == "") next
      rec++; ts = tsof($0); if (ts != "" && (rt == "" || ts + 0 > rt + 0)) rt = ts
      e = epv($0); if (e != "") epl = e
      pend = ""; pname = ""
      if (k == "a") {
        n = split($0, P, K_TXT); if (n > 1) { ft = str(P[n]); fa = NR }
        n = split($0, P, K_TU)
        if (n > 1 && !index(P[n], "},{\"type\":\"text\"") && !index(P[n], "},{\"type\":\"thinking\"")) {
          pend = substr(P[n], 1, index(P[n], Q) - 1); pname = val(P[n], "\"name\":\""); pts = ts }
        next
      }
      if (human($0) != "") lh = NR
    }
    END {
      if (!cl) { printf "0\t-\tunknown\tunknown\t-\t-\tno\t-\n"; exit }
      if (fa) {
        # Decoded with its line breaks kept, and asked whether it asks.
        t = ft; gsub(/\\\\/, "\001", t); gsub(/\\n/, "\n", t); t = dec(t); sub(/[ \n]+$/, "", t)
        q = (lh < fa && asks(t)) ? "yes" : "no"
        if (q == "yes") { gsub(/\n/, " ", t); s = substr(t, length(t) > 160 ? length(t) - 159 : 1)
          while (s != "" && substr(s, 1, 1) >= "\200" && substr(s, 1, 1) < "\300") s = substr(s, 2)
          note = "ended on: " s }
      } else q = (lh || !cut) ? "no" : "unknown"
      b = (pend != "") ? "pending" : ((!rec && cut) ? "unknown" : "no")
      printf "%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", cl, (rt == "" ? "-" : rt), q, b, (pts == "" ? "-" : pts), (pname == "" ? "a tool call" : pname), (substr(epl, 1, 4) == "sdk-" ? "yes" : "no"), (note == "" ? "-" : note)
    }'
}

# Whether a session file is an SDK session's: yes or no (the scan's seventh field).
_fi_host_sdk() {
  local x t=$'\t' i; x="$(_fi_host_scan "$1")"
  for i in 1 2 3 4 5 6; do x="${x#*"$t"}"; done
  printf '%s' "${x%%"$t"*}"
}

#   felix_inv_host_helper_form DIR
# says by its name alone, reading no record, whether DIR is a helper's worktree:
# agent-<hex>, or wf_<id>-<n> with <n> all digits (§6.4). The one place the rule
# is kept: the adapter asks it for its own answers, and the core asks it when
# the adapter gave no seventh field (--no-host, a path never read, a short line).
felix_inv_host_helper_form() {
  local b="${1##*/}"
  case "$b" in
    agent-?*) case "${b#agent-}" in *[!0123456789abcdefABCDEF]*) return 1 ;; esac ;;
    wf_*-*) case "${b##*-}" in ''|*[!0123456789]*) return 1 ;; esac ;;
    *) return 1 ;;
  esac
}
# For a worktree a subagent or workflow made (named as above): the session
# whose helper's *.meta.json names it, searched in the record directories of
# SCOPE, into _FI_SP_NOTE ("spawned by session <sid>: <description>") and
# _FI_SP_MT (the mtime of the helper's transcript). A failed search is not an unknown.
_fi_host_spawn() {
  local d="$1" idx="$2.meta" p m f desc sid; _FI_SP_NOTE=""; _FI_SP_MT=""
  felix_inv_host_helper_form "$d" || return 0
  if [ ! -e "$idx" ]; then : > "$idx"
    while IFS= read -r p; do find "$p" -mindepth 3 -type f -path '*/subagents/*' -name '*.meta.json' 2>/dev/null; done < "$2" \
      | tr '\n' '\000' | xargs -0 -r awk 'FNR == 1 { print FILENAME "\t" $0 }' > "$idx" 2>/dev/null
  fi
  p="$(cd "$d" 2>/dev/null && pwd -P)"
  m="$(awk -F'\t' -v a="\"worktreePath\":\"$d\"" -v b="\"worktreePath\":\"${p:-$d}\"" 'index($2, a) || index($2, b) { print; exit }' "$idx")"
  [ -n "$m" ] || return 0
  f="${m%%$'\t'*}"; sid="${f%%/subagents/*}"; sid="${sid##*/}"
  desc="$(printf '%s\n' "${m#*$'\t'}" | awk "$_FI_HOST_AWK"'{ print cut120(dec(val($0, "\"description\":\""))) }')"
  _FI_SP_NOTE="spawned by session $sid: $desc"; _FI_SP_MT="$(_fi_mtime "${f%.meta.json}.jsonl")"
}

#   felix_inv_host_dir DIR NOW LIVE_MIN BLOCKED_MIN SCOPEFILE
# prints one line: owner mtime live question blocked note helper. Owner is the
# newest session's id (- when none but SDK sessions ran there), mtime when the directory was
# last active, each state yes, no or unknown; unknown throughout when the records
# cannot be read or told from another directory's. Helper is yes when §6.4's
# search found the meta file that names DIR, no when DIR's name is of another
# form or the search found nothing, and unknown for a helper's name when the
# records were not searched: this unknown answer, or a records root the run
# cannot enter (no record directory can be found under it).
felix_inv_host_dir() {
  local d="$1" now="$2" live=no root dd amb=0 f mt best="" bestf="" bout="" out rt act q b pts pname note ts x sm blk=$(($4 * 60)) t=$'\t' nl=$'\n' ract=0 unrd=0 hf=no sdk nsdk=0 knl s p
  local -a dirs=() sd=() sy=()
  knl="$nl"   # the session directories read so far, each as yes: or no: before it, by whether its file is an SDK session's
  ! felix_inv_host_helper_form "$d" || hf=unknown
  root="$(_fi_host_root)" || { printf 'unknown\t-\tunknown\tunknown\tunknown\t-\t%s\n' "$hf"; return 0; }
  while IFS= read -r dd; do [ "$dd" != '?' ] && dirs[${#dirs[@]}]="$dd" || amb=1; done < <(_fi_host_dirs "$root" "$d")
  [ "$amb" = 0 ] || { printf 'unknown\t-\tunknown\tunknown\tunknown\tits session records cannot be told from another directory'"'"'s: its name is over 200 characters\t%s\n' "$hf"; return 0; }
  for dd in ${dirs[@]+"${dirs[@]}"}; do   # a directory the run cannot enter says nothing: not that no session ran there
    [ -r "$dd" ] && [ -x "$dd" ] || { printf 'unknown\t-\tunknown\tunknown\tunknown\tcould not read the record directory %s\t%s\n' "${dd//$t/ }" "$hf"; return 0; }
  done
  # Newest by mtime first: a record time is never later than its mtime, so reading stops at the first file no later than the newest record time read.
  while IFS= read -r f; do
    mt="$(_fi_mtime "$f")"
    if [ -z "$mt" ]; then
      [ -z "$bestf" ] || continue
      printf 'unknown\t-\tunknown\tunknown\tunknown\tcould not read the time of %s\t%s\n' "${f//$t/ }" "$hf"; return 0
    fi
    [ "$mt" -gt "$ract" ] || break
    if [ -r "$f" ]; then
      out="$(_fi_host_scan "$f")"
      # whole-lines record-time question blocked call-time call-name note, by expansion, not a tab-IFS read (the constitution says why)
      x="${out#*"$t"}"; rt="${x%%"$t"*}"; x="${x#*"$t"}"; q="${x%%"$t"*}"; x="${x#*"$t"}"; b="${x%%"$t"*}"; x="${x#*"$t"}"
      pts="${x%%"$t"*}"; x="${x#*"$t"}"; pname="${x%%"$t"*}"; x="${x#*"$t"}"; sdk="${x%%"$t"*}"; note="${x#*"$t"}"
      case "$rt" in ''|*[!0123456789]*) rt="$mt"; ts=file ;; *) ts=record ;; esac
      case "$q" in yes|no|unknown) ;; *) q=unknown; b=unknown; sdk=no; note="could not read ${f//$t/ }" ;; esac
      [ "$sdk" = yes ] || sdk=no
      knl="$knl$sdk:${f%.jsonl}$nl"
      if [ "$sdk" = yes ]; then nsdk=$((nsdk + 1)); continue; fi   # a plugin's session is read as absent: no owner, end or activity (C028)
      [ "$rt" -le "$ract" ] || ract="$rt"
    else   # no record time: its mtime orders it, but is no activity, so live is unknown below
      rt="$mt"; ts=unread; q=unknown; b=unknown; pts=-; pname=-; note="could not read ${f//$t/ }"; [ "$mt" -le "$unrd" ] || unrd="$mt"
      knl="${knl}no:${f%.jsonl}$nl"
    fi
    if [ -z "$bestf" ] || [ "$rt" -gt "$best" ]; then best="$rt"; bestf="$f"; bout="$q$t$b$t$pts$t$pname$t$note$t$ts$t$mt"; fi
  done < <([ "${#dirs[@]}" -gt 0 ] && find "${dirs[@]}" -maxdepth 1 -type f -name '*.jsonl' -exec ls -t {} + 2>/dev/null)
  act="$ract"
  # Only a session's own directory counts, at any depth, never a file beside the session files, and never an SDK session's:
  # one no scan reached (older than the newest record read) is asked when a file under it is the newest.
  for dd in ${dirs[@]+"${dirs[@]}"}; do for f in "$dd"/*.jsonl; do
    [ -f "$f" ] && [ -d "${f%.jsonl}" ] || continue
    case "$knl" in *"${nl}yes:${f%.jsonl}$nl"*) ;; *) sd[${#sd[@]}]="${f%.jsonl}" ;; esac
  done; done
  while [ "${#sd[@]}" -gt 0 ]; do
    x="$(_fi_newest 1 $(((now - act) / 60 + 2)) "${sd[@]}")"; [ -n "$x" ] || break
    s=""; for p in "${sd[@]}"; do case "$x" in "$p"/*) s="$p"; break ;; esac; done
    sdk=no; if [ -n "$s" ]; then case "$knl" in *"${nl}no:$s$nl"*) ;; *) sdk="$(_fi_host_sdk "$s.jsonl")" ;; esac; fi
    if [ "$sdk" = yes ]; then sy=("${sd[@]}"); sd=(); for p in "${sy[@]}"; do [ "$p" = "$s" ] || sd[${#sd[@]}]="$p"; done; continue; fi
    sm="$(_fi_mtime "$x")"; [ -z "$sm" ] || [ "$sm" -le "$act" ] || act="$sm"; break
  done
  _fi_host_spawn "$d" "$5"
  if [ -n "$_FI_SP_NOTE" ]; then hf=yes; elif [ -r "$root" ] && [ -x "$root" ]; then hf=no; fi   # a root it cannot enter was no search: a helper's name stays unknown
  [ -z "$_FI_SP_MT" ] || [ "$_FI_SP_MT" -le "$act" ] || act="$_FI_SP_MT"
  [ "$act" -gt 0 ] && [ $((now - act)) -le $(($3 * 60)) ] && live=yes
  [ "$live" = yes ] || [ "$unrd" = 0 ] || [ $((now - unrd)) -gt $(($3 * 60)) ] || live=unknown
  [ "$act" -gt 0 ] || act=-
  if [ -z "$bestf" ]; then   # no session but a plugin's: no owner, and it says how many were passed over
    x="${_FI_SP_NOTE:--}"; [ "$nsdk" = 0 ] || { x="passed over $nsdk SDK session(s)"; [ -z "$_FI_SP_NOTE" ] || x="$x; $_FI_SP_NOTE"; }
    printf -- '-\t%s\t%s\tno\tno\t%s\t%s\n' "$act" "$live" "$x" "$hf"; return 0
  fi
  x="$bout"; q="${x%%"$t"*}"; x="${x#*"$t"}"; b="${x%%"$t"*}"; x="${x#*"$t"}"; pts="${x%%"$t"*}"; x="${x#*"$t"}"
  pname="${x%%"$t"*}"; x="${x#*"$t"}"; note="${x%%"$t"*}"; x="${x#*"$t"}"; ts="${x%%"$t"*}"; mt="${x#*"$t"}"
  [ "$note" != - ] || note=""
  # Blocked once the call has waited BLOCKED_MIN and nothing under the session's own directory was written within it.
  if [ "$b" = pending ]; then
    case "$pts" in ''|-|*[!0123456789]*) pts="$mt" ;; esac
    x=""; [ ! -d "${bestf%.jsonl}" ] || x="$(_fi_newest 0 $(($4 + 1)) "${bestf%.jsonl}")"; [ -z "$x" ] || x="$(_fi_mtime "$x")"
    if [ $((now - pts)) -ge "$blk" ] && { [ -z "$x" ] || [ $((now - x)) -ge "$blk" ]; }; then b=yes; note="${note:+$note; }waiting on $pname for $(((now - pts) / 60)) min"
    else b=no; fi
  fi
  [ "$ts" != file ] || note="${note:+$note; }activity from file time"; [ -z "$_FI_SP_NOTE" ] || note="${note:+$note; }$_FI_SP_NOTE"
  f="${bestf##*/}"; f="${f%.jsonl}"; f="${f//$t/ }"; f="${f//$nl/ }"; note="${note//$t/ }"; note="${note//$nl/ }"
  [ "$ts" != unread ] && [ -n "$f" ] || f=unknown   # a file named .jsonl alone has no id: never an empty owner
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$f" "$act" "$live" "$q" "$b" "${note:--}" "$hf"
}

# "n m" for the record directories on stdin: n is how many session files
# modified within MIN minutes (and after epoch AFTER, when given) the run cannot
# read, and directories it cannot enter; m the newest mtime among the files,
# 9999999999 for a directory it cannot enter, 0 for none.
_fi_host_unr() {
  local e f n=0 m=0 x
  while IFS= read -r e; do
    [ -r "$e" ] && [ -x "$e" ] || { n=$((n + 1)); m=9999999999; continue; }
    while IFS= read -r f; do
      [ -r "$f" ] || { x="$(_fi_mtime "$f")"; [ -z "$x" ] || [ "$x" -gt "${2:-0}" ] || continue; n=$((n + 1)); [ -z "$x" ] || [ "$x" -le "$m" ] || m="$x"; }
    done < <(find "$e" -maxdepth 1 -type f -name '*.jsonl' -mmin -"$1" 2>/dev/null)
  done
  printf '%d %s\n' "$n" "$m"
}
# felix_inv_host_unread DAYS SCOPEFILE: n, for SCOPEFILE's directories.
felix_inv_host_unread() { local x; x="$(_fi_host_unr $(($1 * 1440)) < "$2")"; printf '%s\n' "${x%% *}"; }

# The session that worked on each pull request's head branch: of the user and
# assistant records carrying "gitBranch":"<head>" exactly in session files of
# SCOPEFILE's record directories modified within DAYS days, the newest by
# "timestamp" (the file's mtime without one) names the owner by its own
# "sessionId". Live is the owner's record time and every file under its directory.
#   felix_inv_host_owners NOW DAYS LIVE_MIN SCOPEFILE HEADSFILE
# prints head owner live (yes or no) per head some session worked on; status 1,
# and nothing printed, when there are no records to read.
felix_inv_host_owners() {
  local now="$1" days="$2" lv="$3" root e f list h o ots act rt x um t=$'\t'; local -a pat=()
  root="$(_fi_host_root)" || return 1
  # An unreadable file newer than a person's record may name the head: that owner is unknown. A plugin's record never stands in for one (M1).
  x="$(_fi_host_unr $((days * 1440)) < "$4")"; um="${x#* }"
  while IFS= read -r h; do [ -z "$h" ] || pat[${#pat[@]}]="-e\"gitBranch\":\"$h\""; done < "$5"
  [ "${#pat[@]}" -gt 0 ] || return 0
  # An argument -e<pattern> is one word, so a pattern may start with a quote.
  list="$(while IFS= read -r e; do find "$e" -maxdepth 1 -type f -name '*.jsonl' -mmin -$((days * 1440)) 2>/dev/null; done < "$4" \
          | tr '\n' '\000' | xargs -0 grep -l -F "${pat[@]}" -- 2>/dev/null)"
  [ -n "$list" ] || return 0
  { printf '%s\n' "$list" | while IFS= read -r f; do printf '\002%s\t%s\n' "$f" "$(_fi_mtime "$f")"; grep -F "${pat[@]}" -- "$f" 2>/dev/null; done; } \
    | awk -F'\t' -v hf="$5" "$_FI_HOST_AWK"'
      BEGIN { while ((getline l < hf) > 0) W[l] = 1 }
      substr($0, 1, 1) == "\002" { fm = $2; sf = substr($1, 2); sub(/.*\//, "", sf); sub(/[.]jsonl$/, "", sf); next }
      { l = $0; if (kind(l) == "" || !(p = index(l, "\"gitBranch\":\""))) next
        b = str(substr(l, p + 13)); if (!(b in W)) next
        ts = tsof(l); if (ts == "") ts = fm
        if (substr(epv(l), 1, 4) == "sdk-") { if (!(b in XT) || ts + 0 > XT[b] + 0) XT[b] = ts; next }   # a plugin session names no owner
        s = match(l, /"sessionId":"[^"]*"/) ? substr(l, RSTART + 13, RLENGTH - 14) : sf
        if (!(b in BT) || ts + 0 > BT[b] + 0) { BT[b] = ts; BO[b] = s }
        if (!(s in OT) || ts + 0 > OT[s] + 0) OT[s] = ts }
      END { for (b in BT) printf "%s\t%s\t%s\n", b, BO[b], OT[BO[b]]
            for (b in XT) if (!(b in BT)) printf "%s\t-\t%s\n", b, XT[b] }' \
    | while IFS= read -r x; do
        h="${x%%"$t"*}"; x="${x#*"$t"}"; o="${x%%"$t"*}"; ots="${x#*"$t"}"; act="$ots"
        # Only a plugin session names the head: no owner, not live, unless a file in the window could not be read (it may hold the owner: audit b09, M1).
        [ "$o" != - ] || { if [ "$um" -gt 0 ]; then printf '%s\tunknown\tunknown\n' "$h"; else printf '%s\t-\tno\n' "$h"; fi; continue; }
        case "$ots" in ''|*[!0123456789]*) ;; *) [ "$um" -le "$ots" ] || { printf '%s\tunknown\tunknown\n' "$h"; continue; } ;; esac
        while IFS= read -r e; do
          [ -f "$e/$o.jsonl" ] || continue
          x="$(_fi_host_scan "$e/$o.jsonl")"; x="${x#*"$t"}"; rt="${x%%"$t"*}"
          case "$rt" in ''|*[!0123456789]*) rt="$(_fi_mtime "$e/$o.jsonl")" ;; esac
          [ -z "$rt" ] || act="$rt"
          [ ! -d "$e/$o" ] || { x="$(_fi_newest 0 $(((now - act) / 60 + 2)) "$e/$o")"; [ -z "$x" ] || x="$(_fi_mtime "$x")"; [ -z "$x" ] || [ "$x" -le "$act" ] || act="$x"; }
          break
        done < "$4"
        case "$act" in ''|*[!0123456789]*) printf '%s\t%s\tno\n' "$h" "$o" ;; *) [ $((now - act)) -le $((lv * 60)) ] && printf '%s\t%s\tyes\n' "$h" "$o" || printf '%s\t%s\tno\n' "$h" "$o" ;; esac
      done
}

# The chips (proposed cards nobody started) are read by lib/inventory-chips.sh,
# the second file of this adapter.
