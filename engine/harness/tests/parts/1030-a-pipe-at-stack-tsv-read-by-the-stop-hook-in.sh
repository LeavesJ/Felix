printf '\na pipe at stack.tsv, read by the Stop hook inside a night\n'
# Written blind on 2026-10-02, from a fifth contract, by the author of the four
# blocks after the hand-written last line, who had not read either fix. It
# closes the readers review's T1: no case reached hooks/stop's stack.tsv read
# inside a night. Red against origin/main: 3 of 7. Removing that one guard
# turns the three pipe assertions red.
# I. A session that owns a night, a gate that is green on the tree, and a FIFO
#    at the project's stack.tsv. The night's branch of the Stop hook reads
#    stack.tsv for its verification nudge, and a pipe there must read as no
#    table rather than wait for a writer that never comes: the hook returns
#    within 8 s (I.1), and its stdout and exit status are those of the same run
#    with no stack.tsv at all (I.2).
#
# Two controls make the comparison worth something. With a regular stack.tsv
# naming superpowers, the run must say the nudge only the night's branch says
# ("piece before you take the next one", the part of it after a line break the
# JSON spells \n; the other green path says "before calling this done"), and
# with "Overnight is on", which proves the fixture reaches that branch and
# that the branch reads the table. With no stack.tsv, the run must hold the
# session with "Overnight is on", which proves the run I.2 compares against
# went through the night as well, so two runs that both skipped it cannot agree
# for the wrong reason.
#
# The epoch a green receipt carries hashes the table set, stack.tsv included,
# so each table state gets its own gate run, and the FIFO run shares the
# absent run's receipt: a FIFO read as absent hashes as absent. Each run is a
# session of its own with a fresh night of the same size, so all three start
# from the same night state. Every hook call is bounded; on a timeout only the
# subshell this block started and its descendants are killed, found by parent
# pid, and the FIFO is opened read-write to release anything left on it. The
# invented project, its memory, the receipt, and the hold and nudge markers the
# hook writes for these sessions are removed afterwards.
#
# Restated 2026-10-16, when claude/declared-unread-readers landed: the policy
# version now hashes anything at a table's path that is not a regular file as
# `<not a regular file>`, so a FIFO no longer hashes as absent and cannot share
# the absent run's receipt. A dangling link at stack.tsv hashes the same as the
# FIFO and cannot block a reader, so it gets its own gate run and is the run
# I.2 compares against; its control proves that run went through the night
# without the nudge, as the absent one does. The 8 s bound, the night and the
# pipe left a pipe are unchanged.
_anl5="$TMP/anl5"; mkdir -p "$_anl5"
_anl5_has() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }
_anl5_if()  {   # name, detail, command...: ok when the command succeeds
  local n="$1" d="$2"; shift 2
  if "$@"; then ok "$n"; else bad "$n" "$d"; fi
}
_anl5_tree() {   # pid -> it and every descendant
  ps -A -o pid= -o ppid= 2>/dev/null | awk -v root="$1" '
    { kids[$2] = kids[$2] " " $1 }
    END { q = root; out = ""
          while (q != "") { n = split(q, a, " "); q = ""
                            for (i = 1; i <= n; i++) if (a[i] != "") { out = out " " a[i]; q = q kids[a[i]] } }
          print out }'
}
_anl5_bounded() {   # seconds, fifo, code -> the code's status, or 124
  local secs="$1" fifo="$2" pid n=0 k
  ( eval "$3" ) & pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$n" -lt $((secs * 10)) ]; do sleep 0.1; n=$((n + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    for k in $(_anl5_tree "$pid"); do kill -9 "$k" 2>/dev/null; done
    wait "$pid" 2>/dev/null
    [ -p "$fifo" ] && ( exec 9<>"$fifo" ) 2>/dev/null
    return 124
  fi
  wait "$pid"
}

# What was here before, so the restore removes only what this block made.
_anl5_P="$FROOT/projects/anl5night"; _anl5_R="$_anl5/repo"
_anl5_had_p=0; [ -e "$_anl5_P" ] && _anl5_had_p=1
_anl5_had_m=0; [ -e "$MEM/anl5night" ] && _anl5_had_m=1
_anl5_sdirs="state state/gate state/held state/verified state/overnight-said"
_anl5_dirs_was=""
for _d in $_anl5_sdirs; do [ -d "$FROOT/$_d" ] && _anl5_dirs_was="$_anl5_dirs_was $_d"; done
_anl5_jobs_was=" $(jobs -p | tr '\n' ' ') "

# The project: a gate that passes on the checkout, and one probe that always
# finds something, without which a green receipt carries no epoch and is never
# current. The checkout is committed and then edited, the state the hook is
# designed for, and resolved through pwd -P, because a receipt stamped against
# /var is not one the hook finds at /private/var.
mkdir -p "$_anl5_P" "$_anl5_R"
printf '{\n  "name": "anl5night",\n  "remote_match": "example.invalid/anl5night",\n  "gate": "sh -c '"'"'test -f NIGHT.txt && echo anl5-gate-ran'"'"'"\n}\n' \
  > "$_anl5_P/project.json"
printf '# anl5night\n' > "$_anl5_P/CLAUDE.md"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$_anl5_P/probes.tsv"
( _fx_cd "$_anl5_R" && git init -q -b main && printf 'anl5night\n' > .felix && printf 'contents\n' > NIGHT.txt \
  && git add -A && git -c user.name=anl5 -c user.email=anl5@example.invalid -c commit.gpgsign=false commit -qm anl5 ) >/dev/null 2>&1
_anl5_R="$(cd "$_anl5_R" && pwd -P)"
printf 'night work\n' >> "$_anl5_R/NIGHT.txt"
# One tool call in the transcript, so each night's first continuation worked.
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash"}]}}\n' > "$_anl5/tx.jsonl"

_anl5_gate() { ( cd "$_anl5_R" && "$FELIX" gate ) > "$_anl5/gate-$1.out" 2>&1; }
_anl5_night() {   # session id: a fresh night of 8 hours and 5 continuations
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/overnight.sh"
    felix_overnight_start "$_anl5_P" 8 5 "$1" "the fifth block's night" ) >/dev/null 2>&1
}
_anl5_owns() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/overnight.sh"
                 felix_overnight_owns "$_anl5_P" "$1" ) >/dev/null 2>&1; }
# The hook's stdout, its stderr and its own exit status, one file each; a run
# killed at the deadline leaves no status file.
_anl5_stop_code='cd "$_anl5_R" && { printf '"'"'{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"%s","transcript_path":"%s"}'"'"' "$_anl5_sid" "$_anl5/tx.jsonl" \
  | "$FROOT/harness/hooks/stop" > "$_anl5/$_anl5_sid.out" 2> "$_anl5/$_anl5_sid.err"; echo $? > "$_anl5/$_anl5_sid.rc"; }'
_anl5_stop() {   # session id, fifo or - -> the bounded call's status
  _anl5_sid="$1"; rm -f "$_anl5/$1.out" "$_anl5/$1.err" "$_anl5/$1.rc"
  _anl5_bounded 8 "$2" "$_anl5_stop_code"
}
_anl5_rcof() { cat "$_anl5/$1.rc" 2>/dev/null || printf 'none'; }
_anl5_said() { printf '%s' "$(tr '\n' ' ' < "$_anl5/$1.out" 2>/dev/null | cut -c1-900)"; }

# ---------------------------------------- the control: a regular stack.tsv ----
printf '# kind\tname\tsource\trisk\tcapability\tgrounding\nplugin\tsuperpowers@claude-plugins-official\t-\tlow\tprocess\tDECLARED\n' \
  > "$_anl5_P/stack.tsv"
_anl5_gate reg; _anl5_grc=$?
_anl5_night anl5-reg; _anl5_owns anl5-reg; _anl5_orc=$?
_anl5_stop anl5-reg -; _anl5_brc=$?
_anl5_o="$(cat "$_anl5/anl5-reg.out" 2>/dev/null)"
_anl5_if "the Stop hook in a session that owns a night on a green tree goes through the night's branch and says its stack.tsv nudge (control)" \
   "gate $_anl5_grc, owns $_anl5_orc, bounded $_anl5_brc, hook $(_anl5_rcof anl5-reg), stdout [$(_anl5_said anl5-reg)]" \
   eval '[ "$_anl5_grc" = 0 ] && [ "$_anl5_orc" = 0 ] && [ "$_anl5_brc" != 124 ] && [ "$(_anl5_rcof anl5-reg)" = 0 ] &&
         _anl5_has "$_anl5_o" "\"decision\": \"block\"" && _anl5_has "$_anl5_o" "Overnight is on, and" &&
         _anl5_has "$_anl5_o" "piece before you take the next one"'

# ------------------------------------------------ the control: no stack.tsv ----
rm -f "$_anl5_P/stack.tsv"
_anl5_gate abs; _anl5_grc=$?
_anl5_night anl5-abs; _anl5_owns anl5-abs; _anl5_orc=$?
_anl5_stop anl5-abs -; _anl5_brc=$?
_anl5_o="$(cat "$_anl5/anl5-abs.out" 2>/dev/null)"
_anl5_if "and with no stack.tsv the same Stop hook run still holds the session for the night, without the nudge (control)" \
   "gate $_anl5_grc, owns $_anl5_orc, bounded $_anl5_brc, hook $(_anl5_rcof anl5-abs), stdout [$(_anl5_said anl5-abs)]" \
   eval '[ "$_anl5_grc" = 0 ] && [ "$_anl5_orc" = 0 ] && [ "$_anl5_brc" != 124 ] && [ "$(_anl5_rcof anl5-abs)" = 0 ] &&
         _anl5_has "$_anl5_o" "\"decision\": \"block\"" && _anl5_has "$_anl5_o" "Overnight is on, and" &&
         ! _anl5_has "$_anl5_o" "piece before you take the next one"'

# ------------------------------- the control: a dangling link at stack.tsv ----
ln -s "$_anl5/no-such-stack.tsv" "$_anl5_P/stack.tsv"
_anl5_gate dang; _anl5_grc=$?
_anl5_night anl5-dang; _anl5_owns anl5-dang; _anl5_orc=$?
_anl5_stop anl5-dang -; _anl5_brc=$?
_anl5_o="$(cat "$_anl5/anl5-dang.out" 2>/dev/null)"
_anl5_if "and with a dangling link at stack.tsv, gated over it, the same run holds the session for the night, without the nudge (control)" \
   "gate $_anl5_grc, owns $_anl5_orc, bounded $_anl5_brc, hook $(_anl5_rcof anl5-dang), stdout [$(_anl5_said anl5-dang)]" \
   eval '[ "$_anl5_grc" = 0 ] && [ "$_anl5_orc" = 0 ] && [ "$_anl5_brc" != 124 ] && [ "$(_anl5_rcof anl5-dang)" = 0 ] &&
         _anl5_has "$_anl5_o" "\"decision\": \"block\"" && _anl5_has "$_anl5_o" "Overnight is on, and" &&
         ! _anl5_has "$_anl5_o" "piece before you take the next one"'
rm -f "$_anl5_P/stack.tsv"

# ------------------------------------------------ I: a FIFO at stack.tsv ----
mkfifo "$_anl5_P/stack.tsv"
_anl5_night anl5-fifo
_anl5_stop anl5-fifo "$_anl5_P/stack.tsv"; _anl5_brc=$?
_anl5_if "the Stop hook in a session that owns a night returns within 8 s with a FIFO at the project's stack.tsv" \
   "still blocked at the 8 s deadline" test "$_anl5_brc" != 124
is "and the Stop hook's stdout with a FIFO at stack.tsv is the stdout of the same run with a dangling link there" \
   "$(cat "$_anl5/anl5-fifo.out" 2>/dev/null)" "$(cat "$_anl5/anl5-dang.out" 2>/dev/null)"
is "and the Stop hook's exit status with a FIFO at stack.tsv is the exit status of the same run with a dangling link there" \
   "$(_anl5_rcof anl5-fifo)" "$(_anl5_rcof anl5-dang)"
_anl5_if "and the FIFO at stack.tsv is still a FIFO after the Stop hook read it" \
   "$(ls -ld "$_anl5_P/stack.tsv" 2>&1)" test -p "$_anl5_P/stack.tsv"

# ------------------------------------------------------------- the restore ----
_anl5_rcpt="$( . "$FROOT/harness/lib/resolve.sh" 2>/dev/null; . "$FROOT/harness/lib/verify.sh" 2>/dev/null
               _felix_receipt_path "$_anl5_R" "$FROOT" 2>/dev/null )"
[ -n "$_anl5_rcpt" ] && rm -f "$_anl5_rcpt"
for _anl5_s in anl5-reg anl5-abs anl5-dang anl5-fifo; do
  rm -f "$FROOT/state/held/$_anl5_s" "$FROOT/state/verified/$_anl5_s" "$FROOT/state/overnight-said/$_anl5_s"
done
for _d in state/overnight-said state/verified state/held state/gate state; do
  case " $_anl5_dirs_was " in *" $_d "*) ;; *) rmdir "$FROOT/$_d" 2>/dev/null ;; esac
done
[ "$_anl5_had_p" -eq 1 ] || rm -rf "$_anl5_P"
[ "$_anl5_had_m" -eq 1 ] || rm -rf "$MEM/anl5night"
_anl5_back=""
[ -n "$_anl5_rcpt" ] && [ ! -e "$_anl5_rcpt" ] || _anl5_back="$_anl5_back receipt[$_anl5_rcpt]"
for _anl5_s in anl5-reg anl5-abs anl5-dang anl5-fifo; do
  for _d in held verified overnight-said; do
    [ ! -e "$FROOT/state/$_d/$_anl5_s" ] || _anl5_back="$_anl5_back state/$_d/$_anl5_s"
  done
done
for _d in $_anl5_sdirs; do
  case " $_anl5_dirs_was " in *" $_d "*) [ -d "$FROOT/$_d" ] || _anl5_back="$_anl5_back lost:$_d" ;; esac
done
{ [ "$_anl5_had_p" -eq 1 ] || [ ! -e "$_anl5_P" ]; } || _anl5_back="$_anl5_back projects/anl5night"
{ [ "$_anl5_had_m" -eq 1 ] || [ ! -e "$MEM/anl5night" ]; } || _anl5_back="$_anl5_back memory/anl5night"
for _anl5_j in $(jobs -p); do
  case "$_anl5_jobs_was" in *" $_anl5_j "*) ;; *) _anl5_back="$_anl5_back background-job[$_anl5_j]" ;; esac
done
is "and the invented night project, its memory, its receipt and the hook state its sessions wrote are gone after the fifth block" \
   "$_anl5_back" ""

printf '\nno engine reader drops the unended last row of a project table, or opens one unguarded\n'
# Written after the fix, not blind (2026-10-01). The blind block above pins the
# readers one by one; this pins the shape, so the next reader written the old
# way fails here instead of waiting for a review to find it.
#
# Two shapes, over a table a person edits under projects/<name>/, named in the
# engine as "$proj/x", "${proj}/x", "$PROJ/x" or "$1/x":
#   loop  `while ... read ...; do ... done < "$proj/x"` whose while line does
#         not keep a last row with no newline (`|| [ -n "${first:-}" ]`).
#         `read` returns 1 on that row with the fields filled, and the loop
#         drops it.
#   open  a reading command (grep, cat, sed, awk, head, tail, cut, sort, uniq,
#         wc, od, comm, diff, cmp, git hash-object) given the path, or a `<`
#         from it, with no `-f` test of the same quoted path earlier in the
#         same function (a hook's top level is one scope) or on the same line.
#         A pipe at the path blocks the open until a writer comes, which is
#         never; `[ -f ]` is false for a pipe, a directory and a device.
#
# What it does not see: a path held in a variable first (route.sh's append
# reads "$f"; it keeps the row); a path whose last part is a variable
# ("$proj/$f": the policy-version hash in commission.sh, the autonomy stamp);
# a helper handed the path that opens it as a bare "$1" (felix_json_str,
# felix_line_ended), which the matcher never judges; a loop fed by `cat`, `sed`, `tail`, `head`, `tr` or `uniq` of
# a table through a pipe or `< <(...)`, which keep a missing newline and so
# drop the row too (there are none; grep, cut, awk and sort, which every feed
# uses, end the last line); a guard in a caller; a guard that is a `-f` of a
# different spelling of the same path. What it names that is safe: a `-f`
# guard that tests a path and then returns on the wrong branch reads as a
# guard. And a `-f` guard counts for every later open of the same path in the
# function, even one in a sibling branch the guard does not cover: removing
# the guard on felix's recommend closing line, or on hooks/stop's second
# stack.tsv read, leaves this green (review, 2026-10-02). Those two guards, and
# the felix_json_str, policy-version and autonomy-stamp guards named above,
# are held by the blind block: the review removed each in turn and a blind
# assertion went red every time.
_rkt_scan() {   # files... -> file:line TAB loop|open TAB path
  LC_ALL=C awk '
    function reset_fn() { split("", guard) }
    function tables(s) { return s ~ /^(\$\{?(proj|PROJ)\}?|\$1)\/[A-Za-z0-9_.-]+$/ }
    FNR == 1 { n = 0; reset_fn() }
    {
      code = $0
      if (code ~ /^[ \t]*#/) next
      if (code ~ /^[A-Za-z_][A-Za-z0-9_]*\(\)[ \t]*\{?/) reset_fn()
      s = code
      while (match(s, /-f[ \t]+"[^"]+"/)) {
        g = substr(s, RSTART, RLENGTH); sub(/^-f[ \t]+"/, "", g); sub(/"$/, "", g)
        guard[g] = 1; s = substr(s, RSTART + RLENGTH)
      }
      t = code
      while (match(t, /(^|[;&|( \t])(while|for|until)[ \t]/)) {
        n++; st[n] = FILENAME ":" FNR; tx[n] = t; isw[n] = (substr(t, RSTART, RLENGTH) ~ /while/)
        t = substr(t, RSTART + RLENGTH)
      }
      t = code
      while (match(t, /(^|[;& \t])done([ \t;|<>)]|$)/)) {
        rest = substr(t, RSTART + RLENGTH - 1)
        if (n > 0) {
          if (isw[n] && tx[n] ~ /read/ && match(rest, /^[ \t]*(2>\/dev\/null[ \t]*)?<[ \t]*"[^"]+"/)) {
            p = substr(rest, RSTART, RLENGTH); sub(/^[^"]*"/, "", p); sub(/"$/, "", p)
            if (tables(p) && tx[n] !~ /\|\|[ \t]*\[[ \t]+-n/) print st[n] "\tloop\t" p
            if (tables(p) && !(p in guard)) print FILENAME ":" FNR "\topen\t" p
          }
          n--
        }
        t = substr(t, RSTART + RLENGTH)
      }
      s = code
      while (match(s, /"\$\{?(proj|PROJ)\}?\/[A-Za-z0-9_.-]+"|"\$1\/[A-Za-z0-9_.-]+"/)) {
        p = substr(s, RSTART + 1, RLENGTH - 2); before = substr(s, 1, RSTART - 1)
        s = substr(s, RSTART + RLENGTH)
        if (before ~ />>?[ \t]*$/) continue
        if (before ~ /(^|[^A-Za-z_])done[ \t]*(2>\/dev\/null[ \t]*)?<[ \t]*$/) continue
        r = (before ~ /<[ \t]*$/) || \
            (before ~ /(^|[|;&( \t`])(grep|egrep|fgrep|cat|sed|awk|head|tail|cut|sort|uniq|wc|od|comm|diff|cmp|git hash-object)[ \t]/)
        if (r && !(p in guard)) print FILENAME ":" FNR "\topen\t" p
      }
    }' "$@"
}

# The matcher against samples first, because a lint that names nothing proves
# nothing about the engine. Each sample is one function.
_rkt="$TMP/rkt"; mkdir -p "$_rkt"
cat > "$_rkt/drops.sh" <<'RKT'
a() {
  [ -f "$proj/routes.tsv" ] || return 0
  while IFS=$'\t' read -r n p; do
    printf '%s\n' "$n"
  done < "$proj/routes.tsv"
}
RKT
cat > "$_rkt/keeps.sh" <<'RKT'
a() {
  [ -f "$proj/routes.tsv" ] || return 0
  while IFS=$'\t' read -r n p || [ -n "${n:-}" ]; do
    printf '%s\n' "$n"
  done < "$proj/routes.tsv"
}
RKT
cat > "$_rkt/opens.sh" <<'RKT'
a() {
  declared="$(grep -vE '^#' "$proj/stack.tsv" 2>/dev/null | cut -f2)"
}
b() {
  [ -f "$proj/stack.tsv" ] || return 0
}
c() {
  cat "${proj}/commissioning.tsv"
  head -1 < "$PROJ/deny.tsv"
}
RKT
cat > "$_rkt/guards.sh" <<'RKT'
a() {
  [ -f "$proj/stack.tsv" ] && declared="$(grep -vE '^#' "$proj/stack.tsv" | cut -f2)"
  printf '%s\n' x >> "$proj/stack.tsv"
  printf 'see %s\n' "$proj/stack.tsv"
}
b() {
  if [ -f "$PROJ/deny.tsv" ]; then
    grep -q x "$PROJ/deny.tsv"
  fi
  # grep "$PROJ/routes.tsv" in a comment is not code
}
RKT
_rkt_out="$(cd "$_rkt" && _rkt_scan drops.sh)"
is "rkt: the lint names a loop over a project table that drops an unended last row" \
  "$_rkt_out" "$(printf 'drops.sh:3\tloop\t$proj/routes.tsv')"
is "rkt: the lint passes the same loop when it keeps that row" \
  "$(cd "$_rkt" && _rkt_scan keeps.sh)" ""
_rkt_out="$(cd "$_rkt" && _rkt_scan opens.sh)"
is "rkt: the lint names a grep, a cat and a < of a project table with no -f in its function" \
  "$_rkt_out" "$(printf 'opens.sh:2\topen\t$proj/stack.tsv\nopens.sh:8\topen\t${proj}/commissioning.tsv\nopens.sh:9\topen\t$PROJ/deny.tsv')"
is "rkt: the lint passes guarded reads, writes, messages and comments" \
  "$(cd "$_rkt" && _rkt_scan guards.sh)" ""

# Then the engine: the CLI, every lib and every hook.
_rkt_out="$(cd "$FROOT/harness" && _rkt_scan felix lib/*.sh hooks/*)"
is "rkt: no engine reader drops a project table's unended last row or opens it unguarded" \
  "$_rkt_out" ""
rm -rf "$_rkt"

