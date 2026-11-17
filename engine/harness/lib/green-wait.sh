# Land on green: what waits is aged and named (audit C002).
#
# A green pull request that waits on a session, on a conflict, on a gate run or
# on the founder wrote one ledger row and then nothing, every five minutes, for
# as long as it waited. #425 alternated `session` and `skip: conflicting with
# main` from 10-18 to 10-23 and no one was told, because the tick dedups an
# unchanged wait on purpose and notifies neither `skip` nor `session`.
#
# So a pull request whose wait has lasted four hours gets one more row, kind
# `waiting`, and a notification, and the next one a day later if the wait goes
# on. The row is a statement and not a decision: it changes nothing the tick
# decides (_gt_last in green-tick.sh reads past it), and `felix land --status`
# still shows it as the pull request's newest row. Session start reads it back
# (hooks/session-start, lib/waiting.sh), which is where a person looks.
#
# Which rows wait. A row of the pull request that is `session`, `refused` or
# `founder`, or a `skip` that is a conflict, a shared head branch, a gate run
# that is not green, files that could not be read, or a founder label (matched
# without regard to case). Every other row is a hold: a draft, felix:hold, a
# fork, another base, a landing. A hold ends the run, so does a row at another
# head, and `waiting` rows are not rows of either kind. The run is the longest
# unbroken stretch of waits at the head gh lists now, at the end of the
# pull request's rows; it began at the time of its first row.

# Which rows are waits is said once, here, and read by two awks: the tick below,
# which ages a run of them, and session start (lib/waiting.sh, which sources this
# file), which names a pull request while its rows since the last `waiting` one
# are all of them.
_GT_WAIT_FN='
function founders(det,   l) { l = tolower(det); return l == "labelled needs-founder" || l == "labelled felix:founder" }
function iswait(ev, det) {
  if (ev == "session" || ev == "refused" || ev == "founder") return 1
  if (ev != "skip") return 0
  return founders(det) || index(det, "conflicting with main") == 1 \
    || index(det, "another open pull request has the head branch") == 1 \
    || index(det, "gate run not green: ") == 1 || index(det, "could not read the files") == 1
}
'
_GT_WAIT_AWK="$_GT_WAIT_FN"'
function ep(t,   a, y, m, d, era, yoe, doy, doe) {
  split(t, a, /[-T:Z]/); y = a[1] + 0; m = a[2] + 0; d = a[3] + 0
  if (m <= 2) y--
  era = int(y / 400); yoe = y - era * 400
  doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
  doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
  return (era * 146097 + doe - 719468) * 86400 + a[4] * 3600 + a[5] * 60 + a[6]
}
BEGIN {
  n = split(want, W, " ")
  for (i = 1; i <= n; i++) { split(W[i], kv, ":"); head[kv[1]] = kv[2]; order[i] = kv[1] }
}
NF >= 7 && ($3 in head) && length($1) == 20 {
  p = $3
  if ($2 == "waiting") {
    if ($4 == head[p] && ep($1) > lastw[p]) lastw[p] = ep($1)
    next
  }
  if ($4 == head[p] && iswait($2, $7)) { if (!run[p]) { run[p] = 1; t0[p] = $1 } } else run[p] = 0
  ne[p] = $2; nd[p] = $7
}
END {
  for (i = 1; i <= n; i++) {
    p = order[i]
    if (!run[p] || now - ep(t0[p]) < 14400 || (p in lastw && now - lastw[p] < 86400)) continue
    who = (ne[p] == "founder" || founders(nd[p])) ? "the founder" : "a session"
    printf "%s\t%s\twaits on %s since %s: %s: %s\n", p, head[p], who, t0[p], ne[p], nd[p]
  }
}'

# PRS: the lines _gt_prs printed. Called only by a tick that read them, and that
# did not deploy: a pull request the list does not return, or a tick that did
# not read it, gets no row.
_gt_wait_pass() {
  local prs="$1" want rows n sha text
  [ -f "$_GT_LEDGER" ] || return 0
  want="$(printf '%s\n' "$prs" | LC_ALL=C awk -F'\t' 'NF { printf "%s%s:%s", s, $1, $3; s = " " }')"
  [ -n "$want" ] || return 0
  rows="$(LC_ALL=C awk -F'\t' -v want="$want" -v now="$(date -u +%s)" "$_GT_WAIT_AWK" "$_GT_LEDGER")" \
    || { _gt_row_once unaged - - - 0 "the ledger could not be read to age what waits"; return 0; }   # wave-1-combine C4
  while IFS=$'\t' read -r n sha text; do
    [ -n "${n:-}" ] || continue
    _gt_row waiting "$n" "$sha" - 0 "$text"
  done <<GTWAITROWS
$rows
GTWAITROWS
  return 0
}
