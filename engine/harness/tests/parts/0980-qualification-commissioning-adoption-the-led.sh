printf '\nqualification, commissioning, adoption, the ledger and routes read a long list to its end\n'
# Eight more engine tests asked whether a value is one line of a list by piping
# the list into grep under pipefail. Two used grep -q (qualify.sh). Six used a
# grep with no early option and its standard output on /dev/null, which GNU
# grep, the grep on Linux, treats as -q: it stops at its first match. Either
# way the writer's next write meets a closed pipe, it dies of SIGPIPE, pipefail
# makes the pipeline 141, and a line that is there reads as absent. Past a
# pipe's 64 KB with the match early that happens every time, so each list below
# is well over 256 KB with the line asked about first, beside the same question
# about the LAST line, which no early exit can miss: that control is what shows
# the fixture reaches the test, so a red is the race and not a broken fixture.
# Two more readers kept a first line with head, and are at the end.
_spa="$TMP/_spa"; mkdir -p "$_spa"
_spa_nl='
'
# Whole-line membership in captured output, read without a pipe.
_spa_line() { case "$_spa_nl$1$_spa_nl" in *"$_spa_nl$2$_spa_nl"*) return 0 ;; esac; return 1; }
_spa_first() { printf '%s' "${1%%"$_spa_nl"*}"; }
_spa_last()  { printf '%s' "${1##*"$_spa_nl"}"; }
# The rows of captured output whose column $3 is $2, for a failure message.
_spa_rows()  { _SPA_K="$2" awk -F'\t' -v c="$3" '$c == ENVIRON["_SPA_K"]' <<<"$1" | cut -c1-120 | tr '\n' ' '; }
# Ninety characters of filler, so a few thousand names make a few hundred KB.
_spa_pad="$(awk 'BEGIN { s = sprintf("%090d", 0); gsub(/0/, "x", s); print s }')"

# ------------------------------------------------------------- fixtures ----
# felix_qualify_missing_controls reads one checker's declared controls. Its
# first row declares violation, 25,000 declare restoration, and its last row
# declares irrelevant; the other three it never declares.
_spa_qm="$_spa/qual-missing"; mkdir -p "$_spa_qm"
awk 'BEGIN {
  printf "spa-big\ttrue\tviolation\tfail\ttrue\n"
  for (i = 1; i <= 25000; i++) printf "spa-big\ttrue\trestoration\tpass\ttrue\n"
  printf "spa-big\ttrue\tirrelevant\tpass\ttrue\n" }' > "$_spa_qm/qualification.tsv"

# felix_qualify_ungoverned reads every qualified checker name after a C-locale
# sort: spa-a-first, 3,000 fillers, spa-z-last. The gate prints the first, the
# last, and one the table never qualifies.
_spa_qu="$_spa/qual-ungoverned"; mkdir -p "$_spa_qu"
awk -v pad="$_spa_pad" 'BEGIN {
  printf "spa-a-first\ttrue\tviolation\tfail\ttrue\n"
  for (i = 1; i <= 3000; i++) printf "spa-m-%s-%05d\ttrue\tviolation\tfail\ttrue\n", pad, i
  printf "spa-z-last\ttrue\tviolation\tfail\ttrue\n" }' > "$_spa_qu/qualification.tsv"
_spa_gate="$(printf 'felix gate\n  spa-a-first            ok\n  spa-never-qualified    ok\n  spa-z-last             FAIL\n')"

# One stack.tsv for commissioning's admit and apply and for discovery's adopt:
# each reads its names without the marketplace suffix. spa-a-first is the first
# row, 3,000 fillers follow, spa-z-last is the last.
_spa_C="$_spa/commission"
mkdir -p "$_spa_C/spa-admit" "$_spa_C/spa-apply" "$_spa_C/spa-adopt" "$_spa_C/mem/spa-admit/commission" \
         "$_spa_C/home" "$_spa_C/bin" "$_spa_C/tmp" "$_spa_C/dhome/state/discover"
awk -v pad="$_spa_pad" 'BEGIN {
  printf "# kind\tname\tsource\trisk\tcapability\tgrounding\n"
  printf "plugin\tspa-a-first@spamkt\t-\tlow\tspacap\n"
  for (i = 1; i <= 3000; i++) printf "plugin\tspa-m-%s-%05d@spamkt\t-\tlow\tspacap\n", pad, i
  printf "plugin\tspa-z-last@spamkt\t-\tlow\tspacap\n" }' > "$_spa_C/stack.tsv"
cp "$_spa_C/stack.tsv" "$_spa_C/spa-admit/stack.tsv"
cp "$_spa_C/stack.tsv" "$_spa_C/spa-apply/stack.tsv"
cp "$_spa_C/stack.tsv" "$_spa_C/spa-adopt/stack.tsv"
# The admit phase's answer: the first declared name, the last, and one nobody
# declared. A claude that lists nothing and a HOME with no registry send that
# last one to `unknown` offline, so a declared name missed in the list would too.
printf 'plugin\tspa-a-first\tspa-source\tspacap\tnamed first in stack.tsv\nplugin\tspa-z-last\tspa-source\tspacap\tnamed last in stack.tsv\nplugin\tspa-new\tspa-source\tspacap\tnamed nowhere\ndone\t3\n' \
  > "$_spa_C/mem/spa-admit/commission/spa_need.tsv"
printf '#!/bin/sh\nexit 1\n' > "$_spa_C/bin/claude"; chmod +x "$_spa_C/bin/claude"
_spa_commission() {   # fn, args... under the fixture's memory, HOME, claude and scratch
  ( FELIX_MEMORY="$_spa_C/mem" HOME="$_spa_C/home" PATH="$_spa_C/bin:$PATH" TMPDIR="$_spa_C/tmp"
    export FELIX_MEMORY HOME PATH TMPDIR
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/discover.sh"
    . "$FROOT/harness/lib/commission-provider.sh"
    "$@" ) 2>/dev/null
}
# Discovery's cache, stamped the way the engine stamps it, so adopt reads it.
_spa_stamp="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/discover.sh"
               _felix_discover_stamp_line "$FROOT/harness/templates" )"
printf '%s\nspa-a-first\tspacap\tlow\t-\nspa-z-last\tspacap\tlow\t-\nspa-new\tspacap\tlow\t-\n' "$_spa_stamp" \
  > "$_spa_C/dhome/state/discover/spa-adopt.tsv"

# The ledger's rollup. A name is long so a dozen signals make a few hundred KB,
# and the kinds are chosen for the order sort gives them: agent first, mcp
# fillers, tool last. So the first name reached for is spa-z:first-seen and the
# last is spa-a:last-seen, and the named rows, sorted by name, ask about the
# last one before the first: a first-row miss appends to the list and must not
# move the control off the last line. Two sessions, so neither half's miss can
# move the other's control.
_spa_L="$_spa/ledger"
mkdir -p "$_spa_L/home/state/ledger" "$_spa_L/mem" "$_spa_L/spa-ledger-named" "$_spa_L/spa-ledger-owner"
_spa_signals="$(awk 'BEGIN {
  s = "x"; while (length(s) < 25000) s = s s
  printf "agent\tspa-z:first-seen\n"
  for (i = 1; i <= 12; i++) printf "mcp\tspa-m-%s-%02d\n", substr(s, 1, 25000), i
  printf "tool\tspa-a:last-seen\n" }')"
printf '%s\nnamed\tspa-a:last-seen\nnamed\tspa-n:never-reached\nnamed\tspa-z:first-seen\n' "$_spa_signals" \
  > "$_spa_L/home/state/ledger/spa-sess-named.tsv"
printf '%s\n' "$_spa_signals" > "$_spa_L/home/state/ledger/spa-sess-owner.tsv"
printf 'plugin\tspa-a@spamkt\t-\tlow\tspacap\nplugin\tspa-z@spamkt\t-\tlow\tspacap\nplugin\tspa-q@spamkt\t-\tlow\tspacap\n' \
  > "$_spa_L/spa-ledger-owner/stack.tsv"
_spa_rollup() {   # proj, session -> the fold it wrote
  ( FELIX_MEMORY="$_spa_L/mem"; export FELIX_MEMORY
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
    felix_ledger_rollup "$_spa_L/$1" "$_spa_L/home" "$2" 2026-09-25 ) >/dev/null 2>&1
  cat "$_spa_L/mem/$1/ledger.d/$2.tsv" 2>/dev/null
}

# felix_toolbox_routed reads the owner of every play the routes name.
_spa_T="$_spa/toolbox/spa-toolbox"; mkdir -p "$_spa_T"
awk -v pad="$_spa_pad" 'BEGIN {
  printf "spa-route-first\tspa\tcore\tspa-a:thing\n"
  for (i = 1; i <= 3000; i++) printf "spa-route-%05d\tspa\tcore\tspa-m-%s-%05d:thing\n", i, pad, i
  printf "spa-route-last\tspa\tcore\tspa-z:thing\n" }' > "$_spa_T/routes.tsv"
_spa_routed() { ( . "$FROOT/harness/lib/toolbox.sh"; felix_toolbox_routed "$_spa_T" "$1" ) >/dev/null 2>&1; }

# The lists each test reads, measured here from the fixtures: every one is
# well past a pipe's 64 KB, with the line asked about first and the control
# last. A ledger list starts with an empty line (the engine builds it that way),
# so its first name is its second line, which is as early as its writer allows.
_spa_short=""
_spa_fits() {   # label, list, first, last
  [ "${#2}" -ge 262144 ] && [ "$(_spa_first "$2")" = "$3" ] && [ "$(_spa_last "$2")" = "$4" ] \
    || _spa_short="$_spa_short $1 (${#2} bytes, first [$(_spa_first "$2" | cut -c1-40)], last [$(_spa_last "$2" | cut -c1-40)])"
}
_spa_fits felix_qualify_missing_controls \
  "$( . "$FROOT/harness/lib/qualify.sh"; felix_qualify_rows "$_spa_qm" | awk -F'\t' '$1 == "spa-big" { print $3 }' )" \
  violation irrelevant
# The declared checkers, as felix_qualify_ungoverned reads them: the first
# column of the rows, once each. felix_qualify_checkers did this until felix
# gate stopped reading the table a second time and it had no caller left.
_spa_fits felix_qualify_ungoverned \
  "$( . "$FROOT/harness/lib/qualify.sh"; felix_qualify_rows "$_spa_qu" | LC_ALL=C cut -f1 | LC_ALL=C sort -u )" \
  spa-a-first spa-z-last
_spa_declared="$(grep -vE '^[[:space:]]*(#|$)' "$_spa_C/stack.tsv" | cut -f2 | sed 's/@.*//')"
_spa_fits "felix_commission_admit, felix_commission_apply_declares, felix_discover_adopt" \
  "$_spa_declared" spa-a-first spa-z-last
_spa_fits "felix_ledger_rollup:seen" \
  "$(sort -u "$_spa_L/home/state/ledger/spa-sess-named.tsv" | awk -F'\t' '$1 != "named" { print $2 }')" \
  spa-z:first-seen spa-a:last-seen
_spa_fits "felix_ledger_rollup:seen_owner" \
  "$(sort -u "$_spa_L/home/state/ledger/spa-sess-owner.tsv" \
       | awk -F'\t' '$1 != "named" { o = $2; sub(/:.*/, "", o); sub(/@.*/, "", o); print o }')" \
  spa-z spa-a
_spa_fits felix_toolbox_routed \
  "$(grep -vE '^[[:space:]]*(#|$)' "$_spa_T/routes.tsv" | cut -f4 | tr ' ' '\n' | sed 's/:.*//')" \
  spa-a spa-z
[ -z "$_spa_short" ] \
  && ok  "every list fixture below holds more than 256 KB with the line asked about first and the control last" \
  || bad "every list fixture below holds more than 256 KB with the line asked about first and the control last" \
         "too small or out of order, so a pass below would prove nothing:$_spa_short"

# ------------------------------------------ felix_qualify_missing_controls ----
# grep -q: red on the old engine on any host.
_spa_out="$( . "$FROOT/harness/lib/qualify.sh"; felix_qualify_missing_controls "$_spa_qm" spa-big 2>/dev/null )"
if [ "$_spa_out" = "alternate${_spa_nl}decoupled_violation${_spa_nl}decoupled_satisfaction" ]; then
  ok  "a checker whose first of 25,000 rows declares a control is short only the three controls it never declares"
else
  bad "a checker whose first of 25,000 rows declares a control is short only the three controls it never declares" \
      "reported missing [$(printf '%s' "$_spa_out" | tr '\n' ' ')]: grep -qxF left at the first declared control, the list's writer died of SIGPIPE, pipefail read a declared control as missing, and the gate printed a shortfall the table does not have"
fi
if ! _spa_line "$_spa_out" irrelevant && _spa_line "$_spa_out" alternate \
   && _spa_line "$_spa_out" decoupled_violation && _spa_line "$_spa_out" decoupled_satisfaction; then
  ok  "and the control it declares only on its last row is not reported missing"
else
  bad "and the control it declares only on its last row is not reported missing" \
      "reported missing [$(printf '%s' "$_spa_out" | tr '\n' ' ')]: the fixture does not reach the membership test"
fi

# ------------------------------------------------ felix_qualify_ungoverned ----
_spa_out="$( . "$FROOT/harness/lib/qualify.sh"; felix_qualify_ungoverned "$_spa_qu" "$_spa_gate" 2>/dev/null )"
[ "$_spa_out" = "spa-never-qualified" ] \
  && ok  "a checker the gate prints that sorts first of 3,002 qualified checkers is not called ungoverned" \
  || bad "a checker the gate prints that sorts first of 3,002 qualified checkers is not called ungoverned" \
         "called ungoverned [$(printf '%s' "$_spa_out" | tr '\n' ' ')]: grep -qxF left at the first qualified checker, the roster's writer died of SIGPIPE, and a qualified checker was reported as a gap"
if ! _spa_line "$_spa_out" spa-z-last && _spa_line "$_spa_out" spa-never-qualified; then
  ok  "nor one that sorts last, while one no row qualifies is"
else
  bad "nor one that sorts last, while one no row qualifies is" \
      "called ungoverned [$(printf '%s' "$_spa_out" | tr '\n' ' ')]: the fixture does not reach the membership test"
fi

# ---------------------------------------- grep with its output on /dev/null ----
# The six below are red on a host whose grep is GNU grep (ubuntu CI), where a
# standard output of /dev/null makes grep stop at its first match. This Mac's
# BSD grep reads to the end whatever its output is, so on the base engine they
# pass here. Each asserts the verdict the engine owes, first and last.

# felix_commission_admit, commission-provider.sh:390.
_spa_out="$(_spa_commission felix_commission_admit "$_spa_C/spa-admit" "$FROOT" spa_need "$FROOT/harness/templates")"
_spa_line "$_spa_out" "already	plugin	spa-a-first	-	-	-	named in stack.tsv already" \
  && ok  "the admit phase answers already for a nomination stack.tsv declares first of 3,002 rows" \
  || bad "the admit phase answers already for a nomination stack.tsv declares first of 3,002 rows" \
         "got [$(_spa_rows "$_spa_out" spa-a-first 3)]: grep stopped at the first declared name, the list's writer died of SIGPIPE, and a declared plugin was treated as undeclared"
if _spa_line "$_spa_out" "already	plugin	spa-z-last	-	-	-	named in stack.tsv already" \
   && _spa_line "$_spa_out" "unknown	plugin	spa-new	-	-	-	nothing to fetch it by: no pinned url and sha in any configured marketplace"; then
  ok  "and for one declared last, while one declared nowhere goes on to the fetch"
else
  bad "and for one declared last, while one declared nowhere goes on to the fetch" \
      "got [$(printf '%s' "$_spa_out" | tr '\n' ' ')]: the fixture does not reach the membership test"
fi

# felix_commission_apply_declares, commission-provider.sh:482. Each call starts
# from the fixture's stack.tsv, so a row one call appends cannot fail the next.
_spa_apply() { cp "$_spa_C/stack.tsv" "$_spa_C/spa-apply/stack.tsv"
               _spa_commission felix_commission_apply_declares "$_spa_C/spa-apply" "$_spa_C" \
                 "$(printf 'declare\tplugin\t%s@spamkt\tlow\tspacap\t0123456789abcdef\tthe fixture' "$1")" \
                 spa-tree spa-policy spa_need; }
_spa_out="$(_spa_apply spa-a-first)"
if [ "$_spa_out" = "0" ] && cmp -s "$_spa_C/stack.tsv" "$_spa_C/spa-apply/stack.tsv"; then
  ok  "applying a declare for the first of 3,002 stack rows appends nothing"
else
  bad "applying a declare for the first of 3,002 stack rows appends nothing" \
      "applied [$_spa_out], last row now [$(tail -1 "$_spa_C/spa-apply/stack.tsv" | cut -c1-60)]: grep stopped at the first declared name and a row already in stack.tsv was appended again"
fi
_spa_out="$(_spa_apply spa-z-last)"
if [ "$_spa_out" = "0" ] && cmp -s "$_spa_C/stack.tsv" "$_spa_C/spa-apply/stack.tsv"; then
  ok  "nor for the last of them"
else
  bad "nor for the last of them" "applied [$_spa_out]: the fixture does not reach the membership test"
fi
_spa_out="$(_spa_apply spa-new)"
if [ "$_spa_out" = "1" ] && [ "$(tail -1 "$_spa_C/spa-apply/stack.tsv")" = "$(printf 'plugin\tspa-new@spamkt\t-\tlow\tspacap\tOBSERVED')" ]; then
  ok  "while a declare for a name no row holds appends its row"
else
  bad "while a declare for a name no row holds appends its row" \
      "applied [$_spa_out], last row [$(tail -1 "$_spa_C/spa-apply/stack.tsv" | cut -c1-60)]: the fixture does not reach the append"
fi

# felix_discover_adopt, discover.sh:1407.
_spa_out="$(_spa_commission felix_discover_adopt "$_spa_C/spa-adopt" "$_spa_C/dhome" "$FROOT/harness/templates")"
_spa_line "$_spa_out" "already	spa-a-first	spacap	low" \
  && ok  "adopt answers already for a candidate stack.tsv declares first of 3,002 rows" \
  || bad "adopt answers already for a candidate stack.tsv declares first of 3,002 rows" \
         "got [$(_spa_rows "$_spa_out" spa-a-first 2)]: grep stopped at the first declared name and an adopted candidate was declared again, a duplicate stack row"
if _spa_line "$_spa_out" "already	spa-z-last	spacap	low" && _spa_line "$_spa_out" "declare	spa-new	spacap	low"; then
  ok  "and for one declared last, while a low-risk candidate declared nowhere is declared"
else
  bad "and for one declared last, while a low-risk candidate declared nowhere is declared" \
      "got [$(printf '%s' "$_spa_out" | tr '\n' ' ')]: the fixture does not reach the membership test"
fi

# felix_ledger_rollup, ledger.sh:467: a named row for a name already reached for.
_spa_out="$(_spa_rollup spa-ledger-named spa-sess-named)"
[ -z "$(awk -F'\t' '$3 == "named" && $4 == "spa-z:first-seen"' <<<"$_spa_out")" ] \
  && ok  "the rollup writes no named row for the first name the session reached for" \
  || bad "the rollup writes no named row for the first name the session reached for" \
         "got [$(_spa_rows "$_spa_out" spa-z:first-seen 4)]: grep stopped at the first name seen and the name got a named row beside its own, written twice"
if [ -z "$(awk -F'\t' '$3 == "named" && $4 == "spa-a:last-seen"' <<<"$_spa_out")" ] \
   && _spa_line "$_spa_out" "spa-sess-named	2026-09-25	named	spa-n:never-reached	0	1" \
   && _spa_line "$_spa_out" "spa-sess-named	2026-09-25	agent	spa-z:first-seen	1	1"; then
  ok  "nor for the last, while a name nothing reached for gets its named row"
else
  bad "nor for the last, while a name nothing reached for gets its named row" \
      "got [$(_spa_rows "$_spa_out" named 3)]: the fixture does not reach the membership test"
fi

# felix_ledger_rollup, ledger.sh:494: a zero row for an owner that was reached for.
_spa_out="$(_spa_rollup spa-ledger-owner spa-sess-owner)"
[ -z "$(_spa_rows "$_spa_out" spa-z@spamkt 4)" ] \
  && ok  "the rollup writes no zero row for a declared plugin whose owner the session reached for first" \
  || bad "the rollup writes no zero row for a declared plugin whose owner the session reached for first" \
         "got [$(_spa_rows "$_spa_out" spa-z@spamkt 4)]: grep stopped at the first owner reached for, and a plugin that was used reads as pointed at and ignored"
if [ -z "$(_spa_rows "$_spa_out" spa-a@spamkt 4)" ] \
   && _spa_line "$_spa_out" "spa-sess-owner	2026-09-25	plugin	spa-q@spamkt	0	0"; then
  ok  "nor for the owner it reached for last, while a declared plugin nothing reached for gets its zero row"
else
  bad "nor for the owner it reached for last, while a declared plugin nothing reached for gets its zero row" \
      "got [$(_spa_rows "$_spa_out" plugin 3)]: the fixture does not reach the membership test"
fi

# felix_toolbox_routed, toolbox.sh:100.
_spa_routed spa-a \
  && ok  "a plugin the first of 3,002 routes names reads as routed" \
  || bad "a plugin the first of 3,002 routes names reads as routed" \
         "it read unrouted: grep stopped at the first play's owner, sed died of SIGPIPE, and pipefail made the route's plugin unrouted"
if _spa_routed spa-z && ! _spa_routed spa-never-routed; then
  ok  "and one the last route names, while one no route names reads as unrouted"
else
  bad "and one the last route names, while one no route names reads as unrouted" \
      "the fixture does not reach the membership test"
fi

# ------------------------------------- head -1 where the status is read ----
# Two readers kept the first line with `| head -1`, and their callers read the
# status. head leaves after one line, so past a pipe's capacity the writer dies
# of SIGPIPE and pipefail fails a read that found its line. The engine never
# writes either input that large: it writes a night's state as one line, with
# the note's newlines taken out, and the registry holds one installLocation per
# entry. So no night or deploy of its own races, and these fixtures are the red
# for readers that keep the first line by reading to the end, not a report of a
# fault anyone has met. Red on the old engine on any host; each control is the
# same input at its real size.

# felix_overnight_field, overnight.sh:170, read by felix_overnight_active.
_spa_O="$_spa/overnight"; mkdir -p "$_spa_O/mem/spa-night/overnight/nights" "$_spa_O/spa-night"
_spa_now="$(date +%s)"
printf '%s\t%s\t5\t0\tspa-sess-long\tthe fixture\n' "$_spa_now" "$((_spa_now + 36000))" \
  > "$_spa_O/mem/spa-night/overnight/nights/spa-sess-long"
awk -v pad="$_spa_pad" 'BEGIN { for (i = 1; i <= 3000; i++) printf "spa filler %s %05d\n", pad, i }' \
  >> "$_spa_O/mem/spa-night/overnight/nights/spa-sess-long"
printf '%s\t%s\t5\t0\tspa-sess-one\tthe fixture\n' "$_spa_now" "$((_spa_now + 36000))" \
  > "$_spa_O/mem/spa-night/overnight/nights/spa-sess-one"
_spa_active() { ( FELIX_MEMORY="$_spa_O/mem"; export FELIX_MEMORY
                  . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/overnight.sh"
                  felix_overnight_active "$_spa_O/spa-night" "$1" ) >/dev/null 2>&1; }
if [ "$(wc -c < "$_spa_O/mem/spa-night/overnight/nights/spa-sess-long")" -gt 262144 ] && _spa_active spa-sess-long; then
  ok  "a live night whose state file runs past a pipe after its first line reads live"
else
  bad "a live night whose state file runs past a pipe after its first line reads live" \
      "it read inactive: head -1 left after the first line, cut died of SIGPIPE, pipefail failed felix_overnight_field, and felix_overnight_active read a night inside every bound as over"
fi
_spa_active spa-sess-one \
  && ok  "and the same night as one line reads live" \
  || bad "and the same night as one line reads live" "the fixture does not reach felix_overnight_active"

# felix_marketplace_root, resolve.sh:752, read by felix with || mroot="".
_spa_M="$_spa/marketplace"; mkdir -p "$_spa_M"
{ printf '{\n  "felix": {\n    "source": {\n      "source": "directory"\n    },\n'
  printf '    "installLocation": "/spa/first/location",\n'
  awk -v pad="$_spa_pad" 'BEGIN { for (i = 1; i <= 3000; i++) printf "    \"installLocation\": \"/spa/filler/%s/%05d\",\n", pad, i }'
  printf '    "lastUpdated": "2026-09-25T00:00:00.000Z"\n  },\n  "other": {\n    "installLocation": "/spa/other"\n  }\n}\n'
} > "$_spa_M/long.json"
printf '{\n  "felix": {\n    "installLocation": "/spa/first/location",\n    "lastUpdated": "2026-09-25T00:00:00.000Z"\n  }\n}\n' \
  > "$_spa_M/one.json"
_spa_out="$( . "$FROOT/harness/lib/resolve.sh"; felix_marketplace_root "$_spa_M/long.json" 2>/dev/null )"; _spa_rc=$?
if [ "$_spa_rc" = 0 ] && [ "$_spa_out" = "/spa/first/location" ]; then
  ok  "the felix marketplace root is read, and reported read, from an entry listing more than a pipe holds"
else
  bad "the felix marketplace root is read, and reported read, from an entry listing more than a pipe holds" \
      "exit $_spa_rc, printed [$_spa_out]: head -1 left after the first location, sed died of SIGPIPE, and the caller emptied the root it had found"
fi
_spa_out="$( . "$FROOT/harness/lib/resolve.sh"; felix_marketplace_root "$_spa_M/one.json" 2>/dev/null )"; _spa_rc=$?
[ "$_spa_rc" = 0 ] && [ "$_spa_out" = "/spa/first/location" ] \
  && ok  "and from an entry listing one" \
  || bad "and from an entry listing one" "exit $_spa_rc, printed [$_spa_out]: the fixture does not reach felix_marketplace_root"

