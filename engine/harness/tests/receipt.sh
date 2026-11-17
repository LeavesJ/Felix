# The suite's receipt: what a run that reached its end leaves behind, and what a
# later run reads before it pays for the suite again.
#
# Sourced by tests/run, and sourceable on its own. It needs bash 3.2, git and
# ../lib/verify.sh, which it loads inside a subshell each time it asks for a
# tree id, so the shell that sources this file gains no felix_verify_* name and
# no FELIX_UNTRACKED_CAP. The driver is 500 lines at most (part 1040), and this
# is where the receipt's rules live so that the driver only decides when to ask.
#
# Why it exists. An engine change paid for the whole suite three times before
# it landed: the record run, the red run it then made, and the gate (1429 s of
# the gate's 1565 s on a quiet machine, 2026-10-10, audits/2026-10-10-gate-time).
# The record run and red now run side by side, and the third pass is the gate's
# `tests` check asking this file whether the tree it is about to gate is one a
# run already passed. The design is docs/2026-10-12-gate-friction-design.md,
# section 3; the rules are contract-a.md, C4 and C5, and contract-a3.md, C10
# (_sr_bridge), in docs/2026-10-12-gate-friction-*.
#
# One receipt for each checkout, one line, tab-separated, in the checkout's git
# directory (git rev-parse --git-path), which is outside the tree: writing it
# moves no tree id. A linked worktree has a git directory of its own, so it has
# a receipt of its own. A root that is not the top of its own checkout (a
# directory inside a larger repository, such as the plugin cache under a home
# directory in git) is no checkout here: its tree id would be the larger one's,
# blind to what that directory holds, and its receipt path would be shared by
# every directory under it.
#
#   v1  <tree id>  <mode>  <passed>  <failed>  <skipped>  <env>  <start>  <end>
#
# <mode> is normal or record; <start> and <end> are Unix seconds. <env> is
# _sr_env, and, when the checkout had a refs/remotes/origin/main, that line
# followed by ;origin=<the commit it named when the run began>. A checkout with
# none writes <env> as _sr_env alone, which reads as "none" (a `-`).
#
# A run that may leave a receipt takes the last one away before its first part
# (_rcp_begin), so the only receipt that can stand after it is one it wrote
# itself at its end. A run that fails, is interrupted or dies part way never
# leaves an earlier pass standing for the gate to find.
#
# What a receipt names, and what it does not. The tree id covers every tracked
# and untracked file under the root and the commit HEAD names. The receipt also
# names what the assertions read and the tree does not hold: the host, the bash
# version, the locale, the PATH (by hash), whether a `claude` CLI is on it (some
# assertions turn into skips), and the commit refs/remotes/origin/main names
# (part 1010's judge compares this tree with it, so a fetch that moves it can
# turn a pass into a fail with the tree unchanged). It refuses with `origin/main
# moved` when that commit is not the one recorded, or cannot be read while one was.
# Everything else is covered by the twelve-hour bound alone, and is not named:
#  - the memory root's lessons.md, read from ~/.felix/memory/felix by part 0590;
#  - the plugin install state: what `claude plugin list --json` answers (part
#    0440, felix_deployed_engine) and the deployed plugin cache and marketplace
#    registry under ~/.claude/plugins, which the gate's `installed` check and
#    parts 0110, 0430, 0590 and 0800 consult wherever a test has no cache of its own;
#  - the user's real HOME where the suite does not set one: ~/.felix-home, the
#    Claude settings directory, the global git configuration and its excludes file;
#  - the version of git and of the other tools on PATH, which the hash names only as a path;
#  - the machine: its load, clock, process cap, free disk and network, which the
#    timing-bound assertions and the ones that fork heavily answer to;
#  - gh and the network, where an assertion is not given a stub of its own.
# A change to any of those rides on a receipt for up to twelve hours.
#
# What a receipt cannot say, plainly. It is a file a session can write, as the
# gate's own receipt is that `felix merge` already trusts. Reuse adds no new
# kind of trust, and GitHub CI still runs the whole suite on Linux before anything
# merges. It refuses the honest mistakes: a tree that moved, a run that failed, a
# different bash or host, a `claude` CLI that turns skips into passes or back, a
# main that moved, a receipt older than twelve hours.

_SR_LIB="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd)/verify.sh"

# Whether <root> is the top of a checkout: what git names as the top level of
# the directory is that directory. Compared as physical paths, since git prints
# the resolved one.
_sr_top() {   # <root>: status 0 when it is
  local a b
  [ -n "${1:-}" ] || return 1
  b="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" || return 1
  a="$(CDPATH= cd "$1" 2>/dev/null && pwd -P)" || return 1
  b="$(CDPATH= cd "$b" 2>/dev/null && pwd -P)" || return 1
  [ -n "$a" ] && [ "$a" = "$b" ]
}

# Where this checkout's receipt is. git prints the path relative to the
# directory it was asked from when the git directory is inside it, which is
# every ordinary checkout, so it is made absolute against the root.
_sr_path() {   # <root> -> the absolute path; status 1 and nothing when <root> is no git checkout
  local p
  _sr_top "$1" || return 1
  p="$(git -C "$1" rev-parse --git-path felix-suite-receipt 2>/dev/null)" || return 1
  [ -n "$p" ] || return 1
  case "$p" in /*) ;; *) p="${1%/}/$p" ;; esac
  printf '%s\n' "$p"
}

# The tree as felix_tree_id names it, with Felix's home left empty so nothing is
# excluded: a suite run judges the whole checkout. `stable` also leaves out the
# two files a record run rewrites while it runs, the manifest and red.tsv, so a
# record run can say that nothing else moved (C8). A coarse id (a tree with more
# untracked files than the cap) is a hash of a count, not of the tree, so it
# counts as an id that cannot be had. Nothing is written to stderr: a message
# here would reach the log of a run that is deciding whether it was reused.
_sr_tree() {   # <root> [stable] -> the id; status 1 and nothing when it cannot be had
  local id
  _sr_top "$1" || return 1
  if [ "${2:-}" = stable ]; then
    id="$( { . "$_SR_LIB" && felix_tree_id "$1" "" \
             ':(exclude)engine/harness/tests/assertions.tsv' ':(exclude)engine/harness/tests/red.tsv'; } 2>/dev/null )" || return 1
  else
    id="$( { . "$_SR_LIB" && felix_tree_id "$1" ""; } 2>/dev/null )" || return 1
  fi
  case "$id" in ''|coarse:*) return 1 ;; esac
  printf '%s\n' "$id"
}

# What a run depends on that the tree does not hold. The host and the bash are
# what the suite's timing and its syntax rules answer to; the locale changes
# how sort and awk order names; the PATH, as a hash because it is long and only
# its identity matters, decides which tools the fixtures find; and whether a
# `claude` CLI is on it turns some assertions into skips (has_claude), so a run
# with one and a run without are different runs. The host is LocalHostName on
# macOS: `uname -n` there follows the network, and moved mid-run (B4).
_sr_env() {
  local loc="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" cl=no ph
  command -v claude >/dev/null 2>&1 && cl=yes
  ph="$(printf '%s' "$PATH" | git hash-object --stdin 2>/dev/null)"
  printf 'host=%s;bash=%s;locale=%s;path=%s;claude=%s\n' "$(_sr_host)" "$BASH_VERSION" "$loc" "$ph" "$cl"
}

_sr_host() {   # LocalHostName where it answers a plain name, else uname -n (B4)
  local h=""; [ -x /usr/sbin/scutil ] && h="$(/usr/sbin/scutil --get LocalHostName 2>/dev/null)"
  case "$h" in ''|*[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-]*) h="$(uname -n 2>/dev/null)" ;; esac
  printf '%s' "$h"
}

# The commit refs/remotes/origin/main names, or `-` when it names none or cannot
# be read. Part 1010's judge compares this tree with it, so it is an input of the
# suite that the tree id does not hold.
_sr_origin() {   # <root>
  local c
  c="$(git -C "$1" rev-parse -q --verify 'refs/remotes/origin/main^{commit}' 2>/dev/null)" && [ -n "$c" ] || c=-
  printf '%s\n' "$c"
}

# The bridged tree id (rule C10, contract A3, 2026-10-12): the id of the tree a
# receipt names, asked of a checkout that has been committed since. A record run
# ends with the manifest and red.tsv changed and not committed; the landing order
# is record, commit, gate, because the gate's receipt and `felix merge` judge the
# tree that is pushed; and the commit moves HEAD, which the tree id hashes, so the
# gate found `another tree` and ran the whole suite again, though the content was
# byte for byte what the run passed. So where HEAD has exactly one parent, the id
# is asked as it would be if HEAD named that parent: the diff of the working tree
# against the parent, the same untracked files, the same hash (felix_tree_id_on,
# one code path with felix_tree_id). A root commit, an unborn HEAD and a merge
# have no bridged id.
#
# It stands only if the receipt's tree id is that id, which says the parent is the
# commit the run had at HEAD and the working tree holds, against it, what the run
# left. A file the run saw untracked and the commit added is tracked now, so the
# ids differ and the suite runs: stricter than it need be, and meant to be. And
# only if the parent is not an ancestor of the commit the receipt recorded for
# origin/main (`-` holds nothing back). Part 1010's judge asks what a committed
# tree is asked (merge-base and ancestry against origin/main, _rtn3 and _rtn4)
# only of a tree that holds a commit origin/main lacks, and skips both for one
# whose HEAD origin/main already held. One read of the checkout's git state has
# an answer the commit can change, `merge-base HEAD origin/main`
# (_rt_record_holds): with two equally good bases of a criss-cross that share a
# commit second, git's pick can move when a commit is put on top (review finding
# C10-1). So the parent and the recorded origin/main must have exactly one best
# base (C10.3e). The rest read refs and objects the commit leaves alone, fixtures,
# or the tracked set, which the id covers: a file the commit adds shows in the diff.
# Prints `head <HEAD's full sha>` where it stands, `held` where the ids agree
# and the ancestry does not, and nothing otherwise.
_sr_bridge() {   # <root> <the receipt's tree id> <the origin/main commit it recorded, or -> -> head <sha> | held | nothing
  local line h p1 p2 id rc mb
  line="$(git -C "$1" rev-list --parents -n 1 HEAD 2>/dev/null)" || return 0
  IFS=' ' read -r h p1 p2 <<< "$line"
  { [ -n "$h" ] && [ -n "$p1" ] && [ -z "$p2" ]; } || return 0
  id="$( { . "$_SR_LIB" && felix_tree_id_on "$1" "$p1" ""; } 2>/dev/null )" || return 0
  case "$id" in ''|coarse:*) return 0 ;; esac
  [ "$id" = "$2" ] || return 0
  if [ "$3" != - ]; then
    git -C "$1" merge-base --is-ancestor "$p1" "$3" 2>/dev/null; rc=$?
    case "$rc" in
      0) echo held; return 0 ;;
      1) ;;
      *) return 0 ;;   # the recorded commit cannot be read here: no bridge
    esac
    mb="$(git -C "$1" merge-base --all "$p1" "$3" 2>/dev/null)" || return 0
    case "$mb" in ''|*$'\n'*) return 0 ;; esac   # none, or more than one best base
  fi
  echo "head $h"
}

# Whether a run may be answered from the receipt: `reuse <passed> <failed>
# <skipped> <end> <mode>`, with the full sha of HEAD as a seventh field where the
# receipt stands on the bridged id (_sr_bridge), or `run <reason>`, the first
# reason that applies. One line either way and status 0, so a caller reads the
# line and not the status. The fields are digits and are never put through
# $(( )): a leading zero is an octal error there, and in bash 3.2 an arithmetic
# error discards the whole command it sits in. The tabs are counted and cut with
# parameter expansion because read with a tab in IFS folds a run of tabs into one.
_sr_check() {   # <root>
  local root="$1" p rec line t="" f1 f2 f3 f4 f5 f6 f7 f8 f9 rest now cur fe fo b=""
  p="$(_sr_path "$root")" || { echo "run no checkout"; return 0; }
  if [ ! -e "$p" ] && [ ! -L "$p" ]; then echo "run no receipt"; return 0; fi
  if [ -L "$p" ] || [ ! -f "$p" ]; then echo "run not a regular file"; return 0; fi
  # A trailing x keeps the newlines $( ) would strip, so two lines are two.
  rec="$(cat -- "$p" 2>/dev/null && printf x)"
  case "$rec" in *x) rec="${rec%x}" ;; *) echo "run unreadable receipt"; return 0 ;; esac
  line="$rec"; case "$line" in *$'\n') line="${line%$'\n'}" ;; esac
  case "$line" in ''|*$'\n'*) echo "run malformed receipt"; return 0 ;; esac
  t="${line//[!$'\t']/}"
  [ "${#t}" -eq 8 ] || { echo "run malformed receipt"; return 0; }
  f1="${line%%$'\t'*}"; rest="${line#*$'\t'}"
  f2="${rest%%$'\t'*}"; rest="${rest#*$'\t'}"
  f3="${rest%%$'\t'*}"; rest="${rest#*$'\t'}"
  f4="${rest%%$'\t'*}"; rest="${rest#*$'\t'}"
  f5="${rest%%$'\t'*}"; rest="${rest#*$'\t'}"
  f6="${rest%%$'\t'*}"; rest="${rest#*$'\t'}"
  f7="${rest%%$'\t'*}"; rest="${rest#*$'\t'}"
  f8="${rest%%$'\t'*}"; f9="${rest#*$'\t'}"
  now="$(date +%s)"
  [ "$f1" = v1 ] || { echo "run malformed receipt"; return 0; }
  case "$f3" in normal|record) ;; *) echo "run malformed receipt"; return 0 ;; esac
  for cur in "$f4" "$f5" "$f6" "$f8" "$f9"; do
    case "$cur" in ''|*[!0-9]*) echo "run malformed receipt"; return 0 ;; esac
  done
  # The environment field is _sr_env, and may end in ;origin=<commit>. The
  # commit is 40 or 64 hex digits; anything else after ;origin= is no receipt.
  fe="$f7"; fo=-
  case "$f7" in
    *";origin="*)
      fo="${f7##*;origin=}"; fe="${f7%";origin=$fo"}"
      case "$fo" in ''|*[!0-9a-f]*) echo "run malformed receipt"; return 0 ;; esac
      { [ "${#fo}" -eq 40 ] || [ "${#fo}" -eq 64 ]; } || { echo "run malformed receipt"; return 0; } ;;
  esac
  # Compared as numbers by awk, which reads a long digit string as a float and
  # never fails on it; a time too large to be one is in the future anyway.
  awk -v s="$f8" -v e="$f9" -v n="$now" 'BEGIN { exit !(s + 0 > e + 0 || e + 0 > n + 60) }' \
    && { echo "run malformed receipt"; return 0; }
  awk -v f="$f5" 'BEGIN { exit !(f + 0 != 0) }' && { echo "run failures recorded"; return 0; }
  # The bridged id is asked here and only here: where the tree as it is now is
  # not the receipt's, in the place of `another tree`. A receipt that matches as
  # it is now is answered as it always was and the bridged id is never computed.
  cur="$(_sr_tree "$root")" || cur=""
  if [ -z "$cur" ] || [ "$cur" != "$f2" ]; then
    [ -z "$cur" ] || b="$(_sr_bridge "$root" "$f2" "$fo")"
    case "$b" in
      "head "?*) b="${b#head }" ;;
      held) echo "run another tree (committed since the run, and origin/main already held the commit the run was on)"; return 0 ;;
      *)    echo "run another tree"; return 0 ;;
    esac
  fi
  [ "$(_sr_env)" = "$fe" ] || { echo "run another environment"; return 0; }
  [ "$(_sr_origin "$root")" = "$fo" ] || { echo "run origin/main moved"; return 0; }
  awk -v e="$f9" -v n="$now" 'BEGIN { exit !(n - e > 43200) }' && { echo "run older than 12 hours"; return 0; }
  echo "reuse $f4 $f5 $f6 $f9 $f3${b:+ $b}"
}

# What `tests/run --reuse` prints when the receipt stands: the line the gate
# shows first and the summary it shows last. The time is the local one the run
# ended at, BSD date's -r first and GNU's -d @ if that is the one here, and the
# skipped clause is left out when nothing was skipped. A receipt that stands on the
# bridged id (a seventh field, HEAD's sha) says so in the sentence, which still
# ends the way projects/felix/gate.sh looks for, so the gate reports the run as
# reused and the receipt it writes carries tests:reused.
_rcp_reused() {   # <the `reuse ...` line _sr_check printed>
  local w p f s e m h hm
  read -r w p f s e m h <<< "$1"
  e="$(awk -v x="$e" 'BEGIN { printf "%d", x }')"
  hm="$(date -r "$e" +%H:%M 2>/dev/null || date -d "@$e" +%H:%M 2>/dev/null)" || hm=""
  if [ -n "$h" ]; then m="$m, then committed as ${h:0:8}"; fi
  printf 'reused the suite run that ended %s on this tree (%s), not run again\n' "${hm:-unknown}" "$m"
  printf '\n%s passed, 0 failed' "$p"
  awk -v x="$s" 'BEGIN { exit !(x + 0 > 0) }' && printf ', %s skipped' "$s"
  printf ' (reused)\n'
}

# The --reuse question, asked before anything is built. A receipt that stands
# ends the run here with exit 0, which is why this exits and does not return;
# one that does not says why on the first line and the run goes on, receipt
# rules and all. The check writes nothing to stderr: the first thing a reader
# of the log sees is this answer, and a line from a helper must not come first.
_rcp_answer() {   # <root>
  local v
  v="$(_sr_check "$1" 2>/dev/null)"
  case "$v" in
    "reuse "*) _rcp_reused "$v"; exit 0 ;;
    *)         printf 'not reused: %s\n' "${v#run }" ;;
  esac
}

# What a run takes before its first part: the tree, the tree without the two
# record files, the environment, the commit origin/main names and the clock,
# all before red can rewrite those two files; and then it takes away the
# checkout's last receipt, so that what the end compares is what the start saw
# and the only receipt that can stand after this run is one it writes itself.
_rcp_begin() {   # <root> -> sets _rcp_t0, _rcp_s0, _rcp_e0, _rcp_o0 and _rcp_start
  _rcp_t0="$(_sr_tree "$1")"; _rcp_s0="$(_sr_tree "$1" stable)"
  _rcp_e0="$(_sr_env)"; _rcp_o0="$(_sr_origin "$1")"; _rcp_start="$(date +%s)"
  _rcp_drop "$1"
}

# What a run that reached its end does about the receipt, before its summary
# line (which stays the last line of the log) and with no say in its exit
# status. It writes one only when it can say that the tree it passed is the
# tree it leaves: nothing failed; the manifest was compared; the environment is
# the one the run began in; origin/main names the commit it named when the run
# began; and the tree is the one it began with. A record run leaves a different
# tree on purpose, since it and red rewrite the manifest and red.tsv, so it
# compares the tree with those two files left out, and says its record was
# judged. That is sound because nothing in the suite but the judged checks reads
# those two files' content (the design checked parts 0440, 0720, 0730, 0740, 0990
# and 1000 on 2026-10-12; a search of the parts for a read of the real files, by
# HERE or REAL_HARNESS, finds none outside part 1010; and the build shows it with
# the suite run twice on one tree under two different valid records). The tree
# id written is the full one taken now. Any other run took the last receipt away.
_rcp_finish() {   # <root> <record: 1 or 0> <compared: 1 or 0> <judged: 1 or 0> <passed> <failed> <skipped>
  local root="$1" mode=normal t1="" s1="" ok=0 e1
  [ "$2" = 1 ] && mode=record
  if [ "$6" = 0 ] && [ "$3" = 1 ] && [ -n "$_rcp_t0" ] && [ -n "$_rcp_s0" ] \
     && [ "$(_sr_env)" = "$_rcp_e0" ] && [ "$(_sr_origin "$root")" = "$_rcp_o0" ]; then
    t1="$(_sr_tree "$root")"
    if [ "$mode" = normal ]; then
      [ -n "$t1" ] && [ "$t1" = "$_rcp_t0" ] && ok=1
    elif [ "$4" = 1 ] && [ -n "$t1" ]; then
      s1="$(_sr_tree "$root" stable)"
      [ -n "$s1" ] && [ "$s1" = "$_rcp_s0" ] && ok=1
    fi
  fi
  if [ "$ok" = 1 ]; then
    e1="$_rcp_e0"; [ "$_rcp_o0" = - ] || e1="$e1;origin=$_rcp_o0"
    _rcp_write "$root" "$t1" "$mode" "$5" "$6" "$7" "$e1" "$_rcp_start" "$(date +%s)"
  else
    _rcp_drop "$root"
  fi
}

# A receipt path that holds something other than a regular file is left alone,
# written through and removed by nothing: a link would be followed to wherever it
# points, a directory would take the temporary file in as a member. Said once,
# so that the run that declined is not mistaken for one that wrote.
_rcp_said=""
_rcp_plain() {   # <path>: status 0 when nothing is there or a regular file is
  if [ -L "$1" ] || { [ -e "$1" ] && [ ! -f "$1" ]; }; then
    [ "$_rcp_said" = "$1" ] || printf '  receipt not written: %s is not a regular file\n' "$1"
    _rcp_said="$1"
    return 1
  fi
}

# A sibling temporary file in the same directory, then one mv, so a reader sees
# the old receipt or the new one and never half of one.
_rcp_write() {   # <root> <tree id> <mode> <passed> <failed> <skipped> <env> <start> <end>
  local p t
  p="$(_sr_path "$1")" || return 1
  _rcp_plain "$p" || return 1
  t="$p.tmp.$$"
  if printf 'v1\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" > "$t" 2>/dev/null \
     && mv -f "$t" "$p" 2>/dev/null; then
    return 0
  fi
  rm -f "$t" 2>/dev/null
  printf '  receipt not written: could not write %s\n' "$p"
  return 1
}

# Takes the checkout's last receipt away: at the start of every run that may
# leave one, and again at the end of one that did not earn one.
_rcp_drop() {   # <root>
  local p
  p="$(_sr_path "$1")" || return 0
  if [ ! -e "$p" ] && [ ! -L "$p" ]; then return 0; fi
  _rcp_plain "$p" || return 1
  rm -f "$p" 2>/dev/null
  return 0
}

# ------------------------------------------------------------ red, beside a record run
# A record run starts tests/red when it starts, and the two run side by side. Red is the record
# run's own child and is disowned at once: a part that ends in a bare `wait` (0150, 0330) waits for
# every job its shell holds, red waits for the mark the record run writes after the parts, and a job
# table holding red made every record run wait on itself. So the record run learns that red has
# finished from the process table: red's pid and its start time together, since a pid alone is
# reused (the suite forks a hundred thousand processes in fifteen minutes).

# The set a stopper holds (R2, R14): "pid;start|..." members, a start being what ps gave the pid when it
# joined ("": any); one is signalled only while the latest non-empty listing shows its pid with that start.
# Each listing is seeded with the members present in it; an empty one is taken again (5 tries, 0.2 s apart).
_rcp_grow() {   # -> _rcp_set, _rcp_add, _rcp_pres
  local o="" t=0 r tab=$'\t'
  while [ "$t" -lt 5 ]; do
    o="$(ps -A -o pid= -o ppid= -o lstart= 2>/dev/null | awk -v seed="$_rcp_set" '{ s = $0; sub(/^ *[0-9]+ +[0-9]+ */, "", s); sub(/ +$/, "", s); R[$1] = s; K[$2] = K[$2] " " $1 }
      END { n = split(seed, M, "|"); for (i = 1; i <= n; i++) if (M[i] != "") { split(M[i], a, ";"); m++; sp[m] = a[1]; ss[m] = a[2]; have[M[i]] = 1 }
        for (i = 1; i <= m; i++) if (NR && (sp[i] in R) && (ss[i] == "" || ss[i] == R[sp[i]])) { pres[sp[i]] = 1; if (!(sp[i] in vis)) { vis[sp[i]] = 1; Q[++qn] = sp[i] } }
        for (h = 1; h <= qn; h++) { nc = split(K[Q[h]], C, " "); for (j = 1; j <= nc; j++) { c = C[j]; pres[c] = 1
          if (!((c ";" R[c]) in have)) { have[c ";" R[c]] = 1; m++; sp[m] = c; ss[m] = R[c]; add++ }
          if (!(c in vis)) { vis[c] = 1; Q[++qn] = c } } }
        for (i = 1; i <= m; i++) out = out (i > 1 ? "|" : "") sp[i] ";" ss[i]
        for (c in pres) pl = pl " " c
        printf "%d\t%d\t%s\t%s\n", NR, add + 0, out, pl }')"
    t=$((t + 1)); case "$o" in ""|"0$tab"*) [ "$t" -ge 5 ] || sleep 0.2 ;; *) break ;; esac
  done
  _rcp_add=0
  case "$o" in [123456789]*"$tab"*) r="${o#*"$tab"}"; _rcp_add="${r%%"$tab"*}"; r="${r#*"$tab"}"; _rcp_set="${r%%"$tab"*}"; _rcp_pres="${r#*"$tab"}" ;; esac
}
# Red's tree ended: TERM to the members present, so that the suite's own EXIT trap removes its temporary
# directory and red's its base checkout; red given up to 30 s to go; then STOP while a listing adds a member
# (30 times at most), KILL, one more listing, KILL and then CONT. It runs in a subshell that ignores TERM
# and is waited for, so the stop goes to its end and its caller keeps its disposition.
_rcp_stop() {   # <red's pid>, with the start time _rcp_redsig gave it
  (
    local p n=0 s="$_rcp_redsig"
    trap '' TERM; _rcp_stp=""
    s="${s#"${s%%[! ]*}"}"; _rcp_set="$1;${s%"${s##*[! ]}"}"; _rcp_pres="$1"; _rcp_grow; _rcp_k TERM
    while [ "$n" -lt 300 ] && kill -0 "$1" 2>/dev/null; do sleep 0.1; n=$((n + 1)); done
    n=0
    while [ "$n" -lt 30 ]; do _rcp_grow; _rcp_k STOP; _rcp_stp="$_rcp_stp $_rcp_pres"; [ "$_rcp_add" -gt 0 ] || break; n=$((n + 1)); done
    _rcp_k KILL; _rcp_grow; _rcp_k KILL; _rcp_k CONT
  )
}
_rcp_k() { local p; for p in $_rcp_pres $_rcp_stp; do kill -"$1" "$p" 2>/dev/null; done; }

_rcp_red_alive() {   # status 0 while the red this run started is still running
  [ -n "${_rcp_red:-}" ] && [ "${_rcp_redgone:-0}" = 0 ] && kill -0 "$_rcp_red" 2>/dev/null || return 1
  [ -z "$_rcp_redsig" ] || [ "$(ps -o lstart= -p "$_rcp_red" 2>/dev/null)" = "$_rcp_redsig" ]
}

# Started at the beginning of a record run: red, told where the mark will be and
# which process to watch, its output in a file of the run's temporary
# directory; and a watcher, so that a record run that dies in any way, a signal
# included (the shell's default for SIGINT, SIGTERM and SIGHUP is to die at once,
# which a trap would put off until the command it is running ends), ends red
# and red's suite within a second or so. The watcher is disowned for the reason
# red is.
_rcp_red_start() {   # <mark>: sets _rcp_red, _rcp_redsig and _rcp_wd
  _rcp_nomark=0
  _rcp_redt0="$(date +%s)"; _rcp_rtsv0="$(ls -i "$HERE/red.tsv" 2>/dev/null)"
  "$HERE/red" --after "$1" $$ > "$TMP/red.out" 2>&1 &
  _rcp_red=$!; disown "$_rcp_red" 2>/dev/null
  _rcp_redsig="$(ps -o lstart= -p "$_rcp_red" 2>/dev/null)"
  # No start time and no process: red ended before it could be read, and its id
  # is not to be taken for it later.
  _rcp_redgone=0; [ -n "$_rcp_redsig" ] || kill -0 "$_rcp_red" 2>/dev/null || _rcp_redgone=1
  ( _rcp_watch $$ ) > /dev/null 2>&1 &
  _rcp_wd=$!; disown "$_rcp_wd" 2>/dev/null
}

# Red retracts red.tsv as its first act, and a red ended before it has leaves the
# previous change's claim standing, which is the one shape that file must never
# take. So a red that is to be ended and was started less than five seconds ago
# is given up to two for red.tsv to be replaced (red writes it by mv, a new file
# each time). A red that never touches it, as a stand-in for one does not, costs
# the two seconds; one started longer ago has had its chance.
_rcp_red_settle() {
  local n=0
  [ $(( $(date +%s) - _rcp_redt0 )) -lt 5 ] || return 0
  while [ "$n" -lt 20 ] && _rcp_red_alive && [ "$(ls -i "$HERE/red.tsv" 2>/dev/null)" = "$_rcp_rtsv0" ]; do
    sleep 0.1; n=$((n + 1))
  done
}

_rcp_watch() {   # <record run's pid>: once it is gone, red and what red started are ended
  local s="" z=0; trap 'z=1' TERM   # R43: a TERM from _rcp_red_end is only recorded; the loop acts on it once it holds the sleep's pid
  while [ "$z" = 0 ] && kill -0 "$1" 2>/dev/null; do sleep 1 & s=$!; [ "$z" = 1 ] || { wait "$s"; [ "$z" = 1 ] || s=""; }; done
  [ -z "$s" ] || case " $(builtin jobs -rp) " in *" $s "*) kill -KILL "$s" 2>/dev/null ;; esac; trap exit TERM; [ "$z" = 0 ] || exit
  ! _rcp_red_alive || { _rcp_red_settle; _rcp_stop "$_rcp_red"; }
}

# The mark, whole or not at all: a sibling file and one mv. <word> is written;
# if that cannot be, `failed` is; if neither can, red would wait for a mark that
# never comes while this run waits for red, so red is ended and not waited for.
_rcp_mark() {   # <written|failed> <mark>
  local w
  for w in "$1" failed; do
    if printf '%s\n' "$w" > "$2.tmp" 2>/dev/null && mv -f "$2.tmp" "$2" 2>/dev/null; then return 0; fi
  done
  rm -f "$2.tmp" 2>/dev/null
  _rcp_red_alive || return 0   # red has ended on its own, and what it said is shown
  _rcp_nomark=1
  _rcp_red_settle; _rcp_stop "$_rcp_red"
}

# After the recorded line: what red said, every line indented by two spaces, once
# red has finished; or why there is nothing of it.
_rcp_red_end() {   # <mark> <red's output file> [<seconds red may take: then its tree is ended>]
  local n=0 t0="$SECONDS"
  if [ "$_rcp_nomark" = 1 ]; then
    printf '  red not run: the record run could not write its mark (%s)\n' "$1"
  else
    while _rcp_red_alive; do
      [ -z "${3:-}" ] || [ "$((SECONDS - t0))" -lt "$3" ] || { _rcp_stop "$_rcp_red"; break; }
      n=$((n + 1)); if [ "$n" -le 20 ]; then sleep 0.1; else sleep 1; fi
    done
    sed 's/^/  /' < "$2"
  fi
  [ -z "${_rcp_wd:-}" ] || kill "$_rcp_wd" 2>/dev/null
  _rcp_wd=""
}
