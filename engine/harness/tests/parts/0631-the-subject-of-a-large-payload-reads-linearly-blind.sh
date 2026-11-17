printf '\nthe subject of a large payload reads linearly (contract L1-L3, blind)\n'
# Blind, written from the contract L1-L3 alone on 2026-10-30. Nothing here was
# read off lib/deny.sh beyond its function names and the line that sets
# _FELIX_DENY_INLINE.
#
# felix_deny_subject reads a payload past _FELIX_DENY_INLINE (1024 characters)
# with one awk, so that the hook answers inside Claude Code's 60 s whatever it
# is handed (part 0630). One awk is not enough on its own. A reading that, for
# each escaped quote, does work proportional to the payload (a copy of the
# rest, a substitution over the whole record) is quadratic in the number of
# escaped quotes, and a command made of them is ordinary: on macOS 27 the old
# reading took about 10 s of CPU for 2.1M of them.
#   L1  the CPU grows linearly: 528K and 2.1M of escaped quotes, four times the
#       payload, under eight times the CPU, with whatever awk is on PATH (BWK
#       20200816 on macOS, gawk in CI). It is taken with `times` inside the
#       reading's subshell, as 0630's _lin does, so load does not add to it.
#   L2  a faster reading must not be a different one: each case is read by the
#       awk (_FELIX_DENY_INLINE=0) and by the expansion (a huge limit), and both
#       are held to the subject the rule gives, written here by hand.
#   L3  the large reading is exact at size, and not only quick.
# The rule, both readings: after the first "command", past the next quote, up
# to the first quote with no backslash before it; each \" taken reads as ";
# every other escape is left as written; raw line breaks are kept.
#
# Every name under $TMP begins sl31-, so this part runs alone (contract C), and
# the watchdog is the part's own: 0630's _killtree is not defined when it does.
_sl31_subj() {  # _sl31_subj <inline limit> <payload>: the Bash command's subject, read under that limit
  ( . "$FROOT/harness/lib/deny.sh"; _FELIX_DENY_INLINE="$1"; felix_deny_subject "$2" Bash )
}
_sl31_both() {  # _sl31_both <name> <payload> <expected>: read by the awk and by the expansion, one subject
  is "$1" "$(_sl31_subj 0 "$2")|$(_sl31_subj 999999999 "$2")" "$3|$3"
}
_sl31_fill() {  # _sl31_fill <template> <text>: the template with each @ replaced by the text
  local t="$1" o=""
  while :; do
    case "$t" in *@*) o="$o${t%%@*}$2"; t="${t#*@}" ;; *) printf '%s' "$o$t"; return 0 ;; esac
  done
}
# A template is a value written by hand with @ where the payload has an escaped
# quote; the rule reads each as one quote, so the subject is the same text with
# a quote in each place. A field full of escaped quotes follows the value.
_sl31_tmpl() {  # _sl31_tmpl <name> <template>
  local v e
  v="$(_sl31_fill "$2" '\"')"; e="$(_sl31_fill "$2" '"')"
  _sl31_both "$1" "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$v\",\"description\":\"say \\\"no\\\"\"},\"tool_use_id\":\"t\"}" "$e"
}

# L2. Size never changes the answer. Every payload here is under 4K, since the
# expansion reading is slow on large ones in bash 3.2.
_sl31_t="$(awk 'BEGIN { for (i = 0; i < 150; i++) printf "printf @%%s@ @a@ ; "; printf "true" }')"
_sl31_tmpl "both readings agree on 600 escaped quotes in a 3K command, each read as one quote" "$_sl31_t"
_sl31_t="$(awk 'BEGIN { printf "a @@@@ b "; for (i = 0; i < 500; i++) printf "@"; printf " c @@ d" }')"
_sl31_tmpl "both readings agree on runs of escaped quotes, the longest 500 in a row" "$_sl31_t"
_sl31_both "both readings agree on a value that opens and closes on escaped quotes" \
  '{"tool_name":"Bash","tool_input":{"command":"\"\"git commit -m \"wip\" \"\"","description":"d"}}' \
  '""git commit -m "wip" ""'
_sl31_both "both readings agree on a value that is one escaped quote, which reads as one quote" \
  '{"tool_name":"Bash","tool_input":{"command":"\"","description":"say \"no\""}}' '"'
_sl31_both "both readings agree on escaped quotes on both sides of each raw line break" \
  $'{"tool_name":"Bash","tool_input":{"command":"echo \\"\n\\"\\"\n\\" done","description":"d"}}' \
  $'echo "\n""\n" done'
# Thirty-four raw lines: escaped quotes on each, at the start, the end and in
# the middle, but for one empty line, and one line that is a lone escaped quote.
_sl31_lf=$'\n'; _sl31_t="first @line@"; _sl31_i=0
while [ "$_sl31_i" -lt 30 ]; do
  _sl31_t="$_sl31_t$_sl31_lf$_sl31_i says @hi@, @@@ and @$_sl31_i@"; _sl31_i=$((_sl31_i + 1))
done
_sl31_t="$_sl31_t$_sl31_lf$_sl31_lf@$_sl31_lf@@ the last @line@ ends"
_sl31_tmpl "both readings agree on a value spanning 34 raw lines with escaped quotes on them" "$_sl31_t"
_sl31_both "both readings stop at the closing quote of a value whose last character is an escaped quote" \
  '{"tool_name":"Bash","tool_input":{"command":"grep -c \"a\" f \"","description":"say \"no\" \"","x":"\""}}' \
  'grep -c "a" f "'

# L1. Linear. One reading, at the default limit, of a value of 22-byte units
# `printf \"%s\" \"a\" ; ` ending in `true`, four escaped quotes to a unit,
# with a field after it. Under a watchdog that ends the reading's whole tree
# at sixty seconds: the awk is a grandchild, and the subshell alone is not it.
_sl31_killtree() { local c; for c in $(pgrep -P "$1" 2>/dev/null); do _sl31_killtree "$c"; done; kill "$1" 2>/dev/null; }
_sl31_lin() {  # _sl31_lin <units>: CPU ms of the reading, or killed; its subject stays in $TMP/sl31-lin-<units>.subj
  local f="$TMP/sl31-lin-$1" i=0 pid
  rm -f "$f.subj" "$f.cpu"
  { printf '{"tool_name":"Bash","tool_input":{"command":"'
    awk -v n="$1" 'BEGIN { for (i = 0; i < n; i++) printf "printf \\\"%%s\\\" \\\"a\\\" ; " }'
    printf 'true","description":"d"},"tool_use_id":"t"}'; } > "$f.json"
  ( . "$FROOT/harness/lib/deny.sh"; raw="$(cat "$f.json")"
    felix_deny_subject "$raw" Bash > "$f.subj"; times > "$f.cpu" ) &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$i" -lt 600 ]; do sleep 0.1; i=$((i + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    _sl31_killtree "$pid"; wait "$pid" 2>/dev/null; rm -f "$f.json" "$f.cpu"; echo killed; return 0
  fi
  wait "$pid" 2>/dev/null; rm -f "$f.json"
  [ -f "$f.cpu" ] || { echo "no times"; return 0; }
  # times: the subshell's user and system time, then its children's, as 0m1.234s.
  awk '{ for (k = 1; k <= NF; k++) { split($k, t, "m"); sub(/s$/, "", t[2]); ms += (t[1] * 60 + t[2]) * 1000 } }
       END { printf "%d", ms }' "$f.cpu"
}
# Each count is checked to be digits before any arithmetic, since an arithmetic
# error in bash 3.2 drops the rest of the top-level command it sits in.
_sl31_v=""; _sl31_c1="$(_sl31_lin 24000)"
case "$_sl31_c1" in
  killed) _sl31_v="528K was not read in sixty seconds" ;;
  ''|*[!0-9]*) _sl31_v="528K was read but its CPU was not taken: [$_sl31_c1]" ;;
esac
if [ -z "$_sl31_v" ]; then
  _sl31_c4="$(_sl31_lin 96000)"
  case "$_sl31_c4" in
    killed) _sl31_v="2.1M was not read in sixty seconds" ;;
    ''|*[!0-9]*) _sl31_v="2.1M was read but its CPU was not taken: [$_sl31_c4]" ;;
    *) if [ "$_sl31_c4" -lt $((_sl31_c1 * 8)) ]; then _sl31_v=linear
       else _sl31_v="528K took $_sl31_c1 ms of CPU and 2.1M took $_sl31_c4 ms"; fi ;;
  esac
fi
is "a large payload of escaped quotes reads in linear CPU: 2.1M costs under eight times what 528K does" "$_sl31_v" "linear"

# L3. Exact at size. 96,000 units of 22 bytes read as 18 each, then `true`:
# 1,728,004 characters, 384,000 of them quotes and none a backslash, so that a
# reading which dropped the quote of each \" and kept the backslash, the same
# length, fails too. The value ends in `true`, so a line break after it can
# only be the printer's own, and is not counted.
_sl31_s="$TMP/sl31-lin-96000.subj"
if [ -f "$TMP/sl31-lin-96000.cpu" ] && [ -f "$_sl31_s" ]; then
  _sl31_n="$(wc -c < "$_sl31_s" | tr -d ' ')"
  [ -n "$(tail -c 1 "$_sl31_s")" ] || _sl31_n=$((_sl31_n - 1))
  _sl31_q="$(LC_ALL=C tr -cd '"' < "$_sl31_s" | wc -c | tr -d ' ')"
  _sl31_b="$(LC_ALL=C tr -cd '\\' < "$_sl31_s" | wc -c | tr -d ' ')"
  _sl31_e="$(tail -c 12 "$_sl31_s")"
  _sl31_g="$_sl31_n $_sl31_q $_sl31_b ${_sl31_e: -10}"
else _sl31_g="the 2.1M payload was not read, so it has no subject to check"; fi
is "the subject of the 2.1M payload is exact: 1,728,004 characters, 384,000 quotes, no backslash, and the value's own end" \
   "$_sl31_g" '1728004 384000 0 "a" ; true'
rm -f "$TMP"/sl31-lin-*
