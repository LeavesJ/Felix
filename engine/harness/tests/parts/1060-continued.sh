_fc_init
_fc_fixture r1 r6
# ======================================================================
# The window: the plan week, and where a record falls against its edges.
# ======================================================================
_fc_mk r9a
FC_WA="$FC/r9a/projects/-Users-dev-win/s1.jsonl"
_fc_in "$FC_WA" msg_W1 2026-10-08T13:00:00.000Z m-w1 1000      # exactly the start: counts
_fc_in "$FC_WA" msg_W2 2026-10-08T12:59:59.999Z m-w2 2000      # a millisecond before it: does not
_fc_in "$FC_WA" msg_W3 2026-10-15T13:00:00.000Z m-w3 4000      # exactly the end: does not
_fc_in "$FC_WA" msg_W4 2026-10-15T12:59:59.999Z m-w4 8000      # a millisecond before the end: counts
_fc_in "$FC_WA" msg_W5 2026-10-12T00:00:00.000Z m-w5 16000
FCCFG="$FC/r9a" _fc --tsv
is  "felix cost --week counts a record at exactly the week's start" \
    "$(_fc_row model m-w1)" "$(_fc_exps model m-w1 1000.00 0.0 1)"
is  "felix cost --week does not count a record one millisecond before the week's start" "$(_fc_absent model m-w2)" "absent"
is  "felix cost --week does not count a record at exactly the week's end" "$(_fc_absent model m-w3)" "absent"
is  "felix cost --week counts a record one millisecond before the week's end" \
    "$(_fc_row model m-w4)" "$(_fc_exps model m-w4 8000.00 0.0 1)"
is  "felix cost --week: three of the five records fall inside, 25000" \
    "$(_fc_row total all)" "$(_fc_exps total all 25000.00 0.0 3)"
is  "felix cost: the day rows are the UTC dates of the records counted, earliest first" \
    "$(_fc_rows day | awk -F'\t' '{ printf "%s%s=%s", s, $2, $3; s = " " }')" \
    "2026-10-08=1000.00 2026-10-12=16000.00 2026-10-15=8000.00"
_fc_mk r9b
FC_WB="$FC/r9b/projects/-Users-dev-win/s1.jsonl"
_fc_in "$FC_WB" msg_X1 2026-10-01T12:59:59.999Z m-x1 100       # a millisecond before the earlier week
_fc_in "$FC_WB" msg_X2 2026-10-01T13:00:00.000Z m-x2 200       # its start
_fc_in "$FC_WB" msg_X3 2026-10-05T00:00:00.000Z m-x3 400
_fc_in "$FC_WB" msg_X4 2026-10-08T12:30:00.000Z m-x4 800
_fc_in "$FC_WB" msg_X5 2026-10-08T13:00:00.000Z m-x5 1600      # its end, and the next week's start
FCCFG="$FC/r9b" FCNOW=2026-10-08T12:59:00Z _fc --tsv
is  "felix cost --week at 12:59Z on a Thursday is still the week that opened the Thursday before: its start" \
    "$(_fc_cover window_start)" "2026-10-01T13:00Z"
is  "felix cost --week at 12:59Z on a Thursday: its end is that same day at 13:00Z" \
    "$(_fc_cover window_end)" "2026-10-08T13:00Z"
is  "felix cost --week at 12:59Z on a Thursday: the instant taken as now is as_of" \
    "$(_fc_cover as_of)" "2026-10-08T12:59Z"
is  "felix cost counts a record at exactly the earlier week's start and not the millisecond before it" \
    "$(_fc_row model m-x1)|$(_fc_row model m-x2)" "|$(_fc_exps model m-x2 200.00 0.0 1)"
is  "felix cost does not count a record at exactly the earlier week's end" "$(_fc_absent model m-x5)" "absent"
is  "felix cost: the earlier week holds three of the five records, 1400" \
    "$(_fc_row total all)" "$(_fc_exps total all 1400.00 0.0 3)"
FCCFG="$FC/r9b" FCNOW=2026-10-08T12:59:00Z _fc
is  "felix cost (text): the window line for the earlier week" \
    "$(_fc_line window)" "window 2026-10-01T13:00Z to 2026-10-08T13:00Z"

# The week that holds now, for a spread of instants. Each run reads the same small
# root; the window rows do not depend on what it holds.
while read -r FC_NOW FC_WS FC_WE; do
  FCCFG="$FC/r1" FCNOW="$FC_NOW" _fc --tsv
  is  "felix cost --week: now $FC_NOW falls in the plan week $FC_WS to $FC_WE" \
      "$(_fc_cover window_start) $(_fc_cover window_end)" "$FC_WS $FC_WE"
done <<'FCEOF'
2026-10-11T05:00:00Z 2026-10-08T13:00Z 2026-10-15T13:00Z
2026-10-08T13:00:00Z 2026-10-08T13:00Z 2026-10-15T13:00Z
2026-10-15T12:59:59Z 2026-10-08T13:00Z 2026-10-15T13:00Z
2026-10-15T13:00:00Z 2026-10-15T13:00Z 2026-10-22T13:00Z
2026-10-07T00:00:00Z 2026-10-01T13:00Z 2026-10-08T13:00Z
2026-10-08T00:00:00Z 2026-10-01T13:00Z 2026-10-08T13:00Z
2026-11-02T00:00:00Z 2026-10-29T13:00Z 2026-11-05T13:00Z
2026-12-31T12:00:00Z 2026-12-24T13:00Z 2026-12-31T13:00Z
2026-12-31T13:00:00Z 2026-12-31T13:00Z 2027-01-07T13:00Z
2027-01-03T00:00:00Z 2026-12-31T13:00Z 2027-01-07T13:00Z
2028-02-29T12:00:00Z 2028-02-24T13:00Z 2028-03-02T13:00Z
2026-10-11T05:40Z 2026-10-08T13:00Z 2026-10-15T13:00Z
FCEOF
FCCFG="$FC/r1" FCNOW=2026-10-11T05:40Z _fc --tsv
is  "felix cost accepts FELIX_COST_NOW without seconds, and as_of reads it to the minute" "$(_fc_cover as_of)" "2026-10-11T05:40Z"
# The window and the dates are UTC whatever zone the machine is in.
for FC_Z in Pacific/Auckland America/Los_Angeles Asia/Kolkata; do
  FCCFG="$FC/r9a" FCTZ="$FC_Z" _fc --tsv
  is  "felix cost under TZ=$FC_Z still reads the week and the days in UTC" \
      "$(_fc_cover window_start) $(_fc_cover window_end) $(_fc_rows day | awk -F'\t' '{ printf "%s=%s ", $2, $3 }')" \
      "2026-10-08T13:00Z 2026-10-15T13:00Z 2026-10-08=1000.00 2026-10-12=16000.00 2026-10-15=8000.00 "
done
FC_D0="$(date -u +%Y-%m-%d)"
FCCFG="$FC/r1" FCNOW=clock _fc --tsv
FC_D1="$(date -u +%Y-%m-%d)"
case "$(_fc_cover as_of)" in
  "$FC_D0"T??:??Z|"$FC_D1"T??:??Z) ok  "felix cost with FELIX_COST_NOW unset takes the clock as now" ;;
  *) bad "felix cost with FELIX_COST_NOW unset takes the clock as now" "as_of was [$(_fc_cover as_of)] on $FC_D0 / $FC_D1" ;;
esac
FCCFG="$FC/r1" _fc --tsv --week; FC_WK="$FCOUT"
FCCFG="$FC/r1" _fc --tsv
FC_SAME=differ; [ "$FC_WK" = "$FCOUT" ] && FC_SAME=same
is  "felix cost --week is the default window: the same report, which has its total row" \
    "$FC_SAME $(_fc_row total all | awk -F'\t' '{ print $3 }')" "same 90500000.00"

# ======================================================================
# --since: from an instant, with no end.
# ======================================================================
_fc_mk r10
FC_S="$FC/r10/projects/-Users-dev-since/s1.jsonl"
_fc_in "$FC_S" msg_S1 2026-10-08T23:59:59.999Z m-s1 1000
_fc_in "$FC_S" msg_S2 2026-10-09T00:00:00.000Z m-s2 2000
_fc_in "$FC_S" msg_S3 2026-10-09T10:29:59.999Z m-s3 4000
_fc_in "$FC_S" msg_S4 2026-10-09T10:30:00.000Z m-s4 8000
_fc_in "$FC_S" msg_S5 2026-10-14T00:00:00.000Z m-s5 16000      # after the instant taken as now
FCCFG="$FC/r10" _fc --tsv --since 2026-10-09
is  "felix cost --since YYYY-MM-DD: the window starts at that day's 00:00Z" "$(_fc_cover window_start)" "2026-10-09T00:00Z"
is  "felix cost --since YYYY-MM-DD: the window's end reads now" "$(_fc_cover window_end)" "now"
is  "felix cost --since YYYY-MM-DD: the instant taken as now is still as_of" "$(_fc_cover as_of)" "2026-10-11T05:00Z"
is  "felix cost --since counts a record at exactly 00:00Z of the day and not the millisecond before" \
    "$(_fc_row model m-s1)|$(_fc_row model m-s2)" "|$(_fc_exps model m-s2 2000.00 0.0 1)"
is  "felix cost --since has no end: a record dated after now still counts" \
    "$(_fc_row model m-s5)" "$(_fc_exps model m-s5 16000.00 0.0 1)"
is  "felix cost --since 2026-10-09 totals the four records from then on, 30000" \
    "$(_fc_row total all)" "$(_fc_exps total all 30000.00 0.0 4)"
FCCFG="$FC/r10" _fc --tsv --since 2026-10-09T10:30
is  "felix cost --since YYYY-MM-DDTHH:MM: the window starts at that minute" "$(_fc_cover window_start)" "2026-10-09T10:30Z"
is  "felix cost --since YYYY-MM-DDTHH:MM counts a record at exactly the minute, not the millisecond before" \
    "$(_fc_row model m-s3)|$(_fc_row model m-s4)" "|$(_fc_exps model m-s4 8000.00 0.0 1)"
is  "felix cost --since 2026-10-09T10:30 totals the two records from then on, 24000" \
    "$(_fc_row total all)" "$(_fc_exps total all 24000.00 0.0 2)"
FCCFG="$FC/r10" _fc --tsv --since 2026-10-08
is  "felix cost --since 2026-10-08: the day rows run in date order, all five records over three days" \
    "$(_fc_rows day | awk -F'\t' '{ printf "%s%s=%s", s, $2, $3; s = " " }')" \
    "2026-10-08=1000.00 2026-10-09=14000.00 2026-10-14=16000.00"
FCCFG="$FC/r10" _fc --since 2026-10-09
is  "felix cost (text) --since: the window line ends at now" "$(_fc_line window)" "window 2026-10-09T00:00Z to now"
for FC_V in 2026-10-09 2028-02-29 2026-12-31T23:59 2026-10-08T00:00; do
  FCCFG="$FC/r10" _fc --tsv --since "$FC_V"
  is  "felix cost --since $FC_V is a real date or time and is accepted: exit 0, the window starts there" \
      "$FCRC $(_fc_cover window_start)" "0 $(printf '%s' "$FC_V" | awk '{ print (index($0, "T") ? $0 : $0 "T00:00") "Z" }')"
done
for FC_V in 2026-13-01 2026-02-30 2026-02-29 2026-04-31 2026-10-08T24:00 2026-10-08T12:60 garbage \
            2026-00-10 2026-10-00 2026-10-32 2026-10-08T12 2026-1-8 ''; do
  FCCFG="$FC/r10" _fc --tsv --since "$FC_V"
  is  "felix cost --since [$FC_V] is a usage error: exit 2, nothing on stdout, a felix cost: line and the usage line on stderr" \
      "$(_fc_usage_verdict)" "$FCUSAGE_OK"
done
FCCFG="$FC/r10" _fc --tsv --since
is  "felix cost --since with no value is a usage error" "$(_fc_usage_verdict)" "$FCUSAGE_OK"
FCCFG="$FC/r10" _fc --since --tsv
is  "felix cost --since followed by another flag, not a value, is a usage error" "$(_fc_usage_verdict)" "$FCUSAGE_OK"

# ======================================================================
# Breakdowns: worktree, day, model; ordering; --by; --top.
# ======================================================================
# Twelve record directories, thirteen responses over five days and three
# models, each in millions so the text view reads whole numbers. Against a cap
# of 100M every percent is the millions.
_fc_fixture r11
# Worktrees: bb 6+6=12, dd 11, ff 10, hh 9, jj 8, ll 7, kk 6, ii 5, gg 4, ee 3, cc 2, aa 1 (78 in all).
# Days: 10-09 bb6+ee3+jj8=17 (3), 10-10 cc2+ii5=7 (2), 10-12 aa1+ff10+kk6=17 (3),
#       10-13 bb6+gg4=10 (2), 10-14 dd11+hh9+ll7=27 (3); 10-11 has nothing and no row.
# Models: opus bb6+bb6+dd11+jj8=31 (4), sonnet ee3+ff10+gg4+kk6+ll7=30 (5), haiku aa1+cc2+hh9+ii5=17 (4).
FC_WT="-Users-dev-bb 12000000.00 12.0 2 -Users-dev-dd 11000000.00 11.0 1 -Users-dev-ff 10000000.00 10.0 1 -Users-dev-hh 9000000.00 9.0 1 -Users-dev-jj 8000000.00 8.0 1 -Users-dev-ll 7000000.00 7.0 1 -Users-dev-kk 6000000.00 6.0 1 -Users-dev-ii 5000000.00 5.0 1 -Users-dev-gg 4000000.00 4.0 1 -Users-dev-ee 3000000.00 3.0 1 -Users-dev-cc 2000000.00 2.0 1 -Users-dev-aa 1000000.00 1.0 1"
FC_DY="2026-10-09 17000000.00 17.0 3 2026-10-10 7000000.00 7.0 2 2026-10-12 17000000.00 17.0 3 2026-10-13 10000000.00 10.0 2 2026-10-14 27000000.00 27.0 3"
FC_MD="claude-opus-5-5 31000000.00 31.0 4 claude-sonnet-5-5 30000000.00 30.0 5 claude-haiku-5-5 17000000.00 17.0 4"
_fc_run11 --tsv
# shellcheck disable=SC2086
is  "felix cost --tsv: worktree rows, one per record directory, largest first" "$(_fc_rows worktree)" "$(_fc_exps worktree $FC_WT)"
# shellcheck disable=SC2086
is  "felix cost --tsv: day rows, one per UTC date that has a counted response, earliest first, not by size" "$(_fc_rows day)" "$(_fc_exps day $FC_DY)"
# shellcheck disable=SC2086
is  "felix cost --tsv: model rows, largest first" "$(_fc_rows model)" "$(_fc_exps model $FC_MD)"
is  "felix cost --tsv: the total is the sum over 13 distinct responses and its percent is of the cap" \
    "$(_fc_row total all)" "$(_fc_exps total all 78000000.00 78.0 13)"
is  "felix cost --tsv: FELIX_COST_CAP_M=100 makes cap_tokens 100000000" "$(_fc_cover cap_tokens)" "100000000"
is  "felix cost --tsv without --by shows all three facets" "$(_fc_kinds)" "cover total worktree day model"
FC_BAD="$(awk -F'\t' '$1 == "cover" { if (NF != 3) n++ ; next }
                      $1 == "total" || $1 == "worktree" || $1 == "day" || $1 == "model" { if (NF != 5) n++ ; next }
                      { n++ } END { if (NR == 0) print "no rows"; else print n + 0 }' "$FCOUTF")"
is  "felix cost --tsv: with every facet printed, cover rows still have three columns and data rows five" "$FC_BAD" "0"
_fc_run11 --tsv --by worktree
is  "felix cost --tsv --by worktree shows the worktree rows only, after the cover and total" "$(_fc_kinds)" "cover total worktree"
_fc_run11 --tsv --by day
is  "felix cost --tsv --by day shows the day rows only, after the cover and total" "$(_fc_kinds)" "cover total day"
_fc_run11 --tsv --by model
is  "felix cost --tsv --by model shows the model rows only, after the cover and total" "$(_fc_kinds)" "cover total model"
_fc_run11 --tsv --top 2
is  "felix cost --tsv --top 2 limits the worktree rows to the first two" \
    "$(_fc_rows worktree | awk -F'\t' '{ printf "%s%s", s, $2; s = " " }')" "-Users-dev-bb -Users-dev-dd"
is  "felix cost --tsv --top 2 limits the model rows to the first two" \
    "$(_fc_rows model | awk -F'\t' '{ printf "%s%s", s, $2; s = " " }')" "claude-opus-5-5 claude-sonnet-5-5"
# shellcheck disable=SC2086
is  "felix cost --tsv --top 2 never cuts the days" "$(_fc_rows day)" "$(_fc_exps day $FC_DY)"
is  "felix cost --tsv --top 2 leaves the total as it was" "$(_fc_row total all)" "$(_fc_exps total all 78000000.00 78.0 13)"
_fc_run11 --tsv --by worktree --top 12
is  "felix cost --tsv --top 12 shows all twelve worktrees" "$(_fc_count worktree)" "12"
_fc_run11 --tsv --by worktree --top 100
is  "felix cost --tsv --top larger than the rows shows them all" "$(_fc_count worktree)" "12"
_fc_run11 --tsv --by day --top 1
is  "felix cost --tsv --by day --top 1 still shows all five days" "$(_fc_count day)" "5"
_fc_run11 --tsv --by worktree --top 3
FC_T3="$FCOUT"
_fc_run11 --top 3 --by worktree --tsv
FC_SAME=differ; [ "$FC_T3" = "$FCOUT" ] && FC_SAME=same
is  "felix cost takes its flags in any order: the same three worktree rows" "$FC_SAME $(_fc_count worktree)" "same 3"

_fc_run11
is  "felix cost (text) exits 0" "$FCRC" "0"
is  "felix cost (text) without --by prints the worktrees heading and then the days heading, and no models" "$(_fc_heads)" "worktrees days"
FC_TL="$(_fc_line total)"
has "felix cost (text): the total line gives the millions, 78.0M" "$FC_TL" "78.0M"
has "felix cost (text): the total line gives the percent of the cap, 78.0%" "$FC_TL" "78.0%"
has "felix cost (text): the total line names the cap, 100M" "$FC_TL" "100M"
is  "felix cost (text): the calls line counts 13 distinct responses" "$(_fc_line calls)" "calls 13"
is  "felix cost (text): the worktrees show at most 10 by default, largest first" "$(_fc_sec worktrees)" \
"12.0 12.0 -Users-dev-bb
11.0 11.0 -Users-dev-dd
10.0 10.0 -Users-dev-ff
9.0 9.0 -Users-dev-hh
8.0 8.0 -Users-dev-jj
7.0 7.0 -Users-dev-ll
6.0 6.0 -Users-dev-kk
5.0 5.0 -Users-dev-ii
4.0 4.0 -Users-dev-gg
3.0 3.0 -Users-dev-ee"
is  "felix cost (text): the days are all shown, earliest first: a line is the date, millions, percent" "$(_fc_sec days)" \
"2026-10-09 17.0 17.0
2026-10-10 7.0 7.0
2026-10-12 17.0 17.0
2026-10-13 10.0 10.0
2026-10-14 27.0 27.0"
_fc_run11 --top 3
is  "felix cost (text) --top 3 shows three worktrees" "$(_fc_sec worktrees)" \
"12.0 12.0 -Users-dev-bb
11.0 11.0 -Users-dev-dd
10.0 10.0 -Users-dev-ff"
is  "felix cost (text) --top 3 does not cut the days" "$(_fc_sec days | awk 'END { print NR }')" "5"
_fc_run11 --by worktree --top 12
is  "felix cost (text) --by worktree --top 12 shows twelve worktrees, more than the default ten" "$(_fc_sec worktrees | awk 'END { print NR }')" "12"
_fc_run11 --by worktree
is  "felix cost (text) --by worktree prints the worktrees heading alone, ten of them" \
    "$(_fc_heads) $(_fc_sec worktrees | awk 'END { print NR }')" "worktrees 10"
_fc_run11 --by day --top 1
is  "felix cost (text) --by day prints the days heading alone, and --top does not cut the days" \
    "$(_fc_heads) $(_fc_sec days | awk 'END { print NR }')" "days 5"
_fc_run11 --by model
is  "felix cost (text) --by model prints the models heading alone, a line per model: percent, millions, model" \
    "$(_fc_heads)|$(_fc_sec models)" "models|31.0 31.0 claude-opus-5-5
30.0 30.0 claude-sonnet-5-5
17.0 17.0 claude-haiku-5-5"
_fc_run11 --by model --top 2
is  "felix cost (text) --by model --top 2 shows two models" "$(_fc_sec models | awk 'END { print NR }')" "2"

# Ties: by key ascending, in byte order (capitals before lower case), whatever the locale.
_fc_mk r12
FC_TD="$FC/r12/projects"
_fc_in "$FC_TD/-t-big/s.jsonl"   msg_T1 "$FCT0" m-big   5000000
_fc_in "$FC_TD/-t-Beta/s.jsonl"  msg_T2 "$FCT0" Zmodel  1000000
_fc_in "$FC_TD/-t-Zeta/s.jsonl"  msg_T3 "$FCT0" amodel  1000000
_fc_in "$FC_TD/-t-alpha/s.jsonl" msg_T4 "$FCT0" m-mid   1000000
_fc_in "$FC_TD/-t-small/s.jsonl" msg_T5 "$FCT0" m-small  500000
FCCFG="$FC/r12" FCCAP=100 _fc --tsv
is  "felix cost: equal worktrees are ordered by key in byte order, so -t-Beta, -t-Zeta, then -t-alpha" \
    "$(_fc_rows worktree | awk -F'\t' '{ printf "%s%s", s, $2; s = " " }')" "-t-big -t-Beta -t-Zeta -t-alpha -t-small"
is  "felix cost: equal models are ordered by key in byte order, so Zmodel, amodel, then m-mid" \
    "$(_fc_rows model | awk -F'\t' '{ printf "%s%s", s, $2; s = " " }')" "m-big Zmodel amodel m-mid m-small"
FC_TIE="$FCOUT"
FCCFG="$FC/r12" FCCAP=100 FCLC=en_US.UTF-8 _fc --tsv
FC_SAME=differ; [ "$FC_TIE" = "$FCOUT" ] && FC_SAME=same
is  "felix cost: the tie order is the same under a UTF-8 locale, five worktree rows" "$FC_SAME $(_fc_count worktree)" "same 5"
is  "felix cost: the percent of a 1M worktree against a 100M cap is 1.0, and of 500000 tokens 0.5" \
    "$(_fc_row worktree -t-Beta)|$(_fc_row worktree -t-small)" \
    "$(_fc_exps worktree -t-Beta 1000000.00 1.0 1)|$(_fc_exps worktree -t-small 500000.00 0.5 1)"
FCCFG="$FC/r12" FCCAP=100 _fc --tsv --top 2
is  "felix cost --top 2 takes the first two after the tie order: -t-big, then -t-Beta" \
    "$(_fc_rows worktree | awk -F'\t' '{ printf "%s%s", s, $2; s = " " }')" "-t-big -t-Beta"

# ======================================================================
# The cap.
# ======================================================================
FCCFG="$FC/r1" FCCAP=452.5 _fc --tsv
is  "felix cost: FELIX_COST_CAP_M=452.5 makes cap_tokens 452500000" "$(_fc_cover cap_tokens)" "452500000"
is  "felix cost: 90500000 tokens is 20.0 percent of a 452.5M cap" "$(_fc_row total all)" "$(_fc_exps total all 90500000.00 20.0 1)"
is  "felix cost: the percent in a breakdown row is of the cap too" \
    "$(_fc_row worktree -Users-dev-alpha)" "$(_fc_exps worktree -Users-dev-alpha 90500000.00 20.0 1)"
FCCFG="$FC/r1" FCCAP=181 _fc --tsv
is  "felix cost: FELIX_COST_CAP_M=181 makes cap_tokens 181000000" "$(_fc_cover cap_tokens)" "181000000"
is  "felix cost: 90500000 tokens is 50.0 percent of a 181M cap" "$(_fc_row total all)" "$(_fc_exps total all 90500000.00 50.0 1)"
FCCFG="$FC/r1" FCCAP=1810 _fc --tsv
is  "felix cost: 90500000 tokens is 5.0 percent of a 1810M cap" "$(_fc_row total all)" "$(_fc_exps total all 90500000.00 5.0 1)"
# Past 2^31: one response of 3000000000 input tokens against a 4000M cap.
_fc_mk r1b
_fc_in "$FC/r1b/projects/-Users-dev-big/s1.jsonl" msg_BG1 "$FCT0" m-big 3000000000
FCCFG="$FC/r1b" FCCAP=4000 _fc --tsv
is  "felix cost keeps tokens past 2^31 exact: 3000000000 is 75.0 percent of a 4000M cap" \
    "$(_fc_row total all)" "$(_fc_exps total all 3000000000.00 75.0 1)"
is  "felix cost prints a cap past 2^31 whole: FELIX_COST_CAP_M=4000 is 4000000000 tokens" "$(_fc_cover cap_tokens)" "4000000000"
FCCFG="$FC/r1" FCCAP=181 _fc
FC_TL="$(_fc_line total)"
has "felix cost (text): the total line gives the percent of the cap that was set, 50.0%" "$FC_TL" "50.0%"
has "felix cost (text): the total line names the cap that was set, 181M" "$FC_TL" "181M"
for FC_V in 0 -5 abc 0.0 5x 1.2.3; do
  FCCFG="$FC/r1" FCCAP="$FC_V" _fc --tsv
  is  "felix cost: FELIX_COST_CAP_M=$FC_V is not a positive number: exit 2, nothing on stdout, a felix cost: line and the usage line on stderr" \
      "$(_fc_usage_verdict)" "$FCUSAGE_OK"
done
FCCFG="$FC/r1" FCCAP=-5 _fc
is  "felix cost (text): a FELIX_COST_CAP_M that is not a positive number is a usage error in the text view too" \
    "$(_fc_usage_verdict)" "$FCUSAGE_OK"

# ======================================================================
# Unread is unknown, never zero.
# ======================================================================
_fc_unknown_tsv() {   # NAME-STEM: assert the report that is just read says unknown
  is  "$1: exit 0 with a report" "$FCRC" "0"
  is  "$1: cover coverage is unknown" "$(_fc_cover coverage)" "unknown"
  is  "$1: the total row reads unknown in all three columns, never 0" \
      "$(_fc_row total all)" "$(printf 'total\tall\tunknown\tunknown\tunknown')"
  is  "$1: no worktree, day or model row is printed" "$(_fc_kinds)" "cover total"
}
_fc_unknown_text() {  # NAME-STEM
  is  "$1: the total line reads unknown" "$(_fc_line total | awk '{ print $1, $2 }')" "total unknown"
  is  "$1: no breakdown follows it" "$(_fc_line total | awk '{ print $2 }')|$(_fc_heads)" "unknown|"
  is  "$1: exit 0" "$FCRC" "0"
}
FCCFG="$FC/nope" _fc --tsv
_fc_unknown_tsv "felix cost --tsv: with no records root"
FCCFG="$FC/nope" _fc
_fc_unknown_text "felix cost (text): with no records root"
_fc_fixture rE
FCCFG="$FC/rE" _fc --tsv
_fc_unknown_tsv "felix cost --tsv: with a records root that holds no transcript at all"
FCCFG="$FC/rE" _fc
_fc_unknown_text "felix cost (text): with a records root that holds no transcript at all"
_fc_fixture rN
FCCFG="$FC/rN" _fc --tsv
_fc_unknown_tsv "felix cost --tsv: with files only where none is read, no *.jsonl at either read depth"
_fc_mk rZ
_fc_in "$FC/rZ/projects/-Users-dev-z/s1.jsonl" msg_Z1 2026-10-01T00:00:00.000Z m-z 500
FCCFG="$FC/rZ" _fc --tsv
is  "felix cost --tsv: a root with a transcript but nothing in the window is a measured total of 0, not unknown" \
    "$(_fc_row total all)" "$(_fc_exps total all 0.00 0.0 0)"
is  "felix cost --tsv: nothing in the window is coverage measured" "$(_fc_cover coverage)" "measured"
is  "felix cost --tsv: nothing in the window has no worktree, day or model row" "$(_fc_kinds)" "cover total"
is  "felix cost --tsv: the file was read though it held nothing in the window" "$(_fc_cover files_read)" "1"
FCCFG="$FC/rZ" _fc
is  "felix cost (text): nothing in the window is a total of 0.0M, not unknown" \
    "$(_fc_line total | awk '{ print $1, $2, $3 }')" "total 0.0M 0.0%"
is  "felix cost (text): nothing in the window is 0 calls" "$(_fc_line calls)" "calls 0"
_fc_mk rO
_fc_in "$FC/rO/projects/-Users-dev-o/old.jsonl" msg_O1 "$FCT0" m-o 500
touch -t 202609010000 "$FC/rO/projects/-Users-dev-o/old.jsonl"
FCCFG="$FC/rO" _fc --tsv
is  "felix cost --tsv: a root whose only transcript is older than the window is a measured 0, a transcript of any age counts" \
    "$(_fc_row total all)" "$(_fc_exps total all 0.00 0.0 0)"
is  "felix cost --tsv: a root of only old transcripts is coverage measured, with no file read" \
    "$(_fc_cover coverage) $(_fc_cover files_read)" "measured 0"

# A records root whose path holds a space.
_fc_mk "sp ace"
_fc_in "$FC/sp ace/projects/-Users-dev-sp/s1.jsonl" msg_SP1 "$FCT0" m-sp 1000
FCCFG="$FC/sp ace" _fc --tsv
is  "felix cost reads a records root whose path holds a space" "$(_fc_row total all)" "$(_fc_exps total all 1000.00 0.0 1)"

# The root: $CLAUDE_CONFIG_DIR/projects when set and not empty, else $HOME/.claude/projects.
FC_HP="$FCHOME/.claude/projects/-Users-dev-home"
_fc_in "$FC_HP/s1.jsonl" msg_HM1 "$FCT0" m-home 2000000
# CLAUDE_CONFIG_DIR is left unset (no FCCFG).
_fc --tsv
is  "felix cost reads \$HOME/.claude/projects when CLAUDE_CONFIG_DIR is unset" \
    "$(_fc_row total all)" "$(_fc_exps total all 2000000.00 0.2 1)"
is  "felix cost --tsv: cover source with CLAUDE_CONFIG_DIR unset is the literal text \$HOME/.claude/projects" \
    "$(_fc_cover source)" '$HOME/.claude/projects'
_fc
FC_FL="$(_fc_line files)"
has "felix cost (text): the files line names the root as the literal \$HOME/.claude/projects" "$FC_FL" 'under $HOME/.claude/projects'
case "$FC_FL" in
  files*"$FCHOME"*) bad "felix cost (text): the files line names \$HOME, not its value" "[$FC_FL] holds the path" ;;
  files*under*)     ok  "felix cost (text): the files line names \$HOME, not its value" ;;
  *)                bad "felix cost (text): the files line names \$HOME, not its value" "no files line under: [$FC_FL]" ;;
esac
FCCFG= _fc --tsv
is  "felix cost reads \$HOME/.claude/projects when CLAUDE_CONFIG_DIR is set but empty" \
    "$(_fc_row total all) $(_fc_cover source)" "$(_fc_exps total all 2000000.00 0.2 1) "'$HOME/.claude/projects'
mkdir -p "$FC/emptycfg"
FCCFG="$FC/emptycfg" _fc --tsv
_fc_unknown_tsv "felix cost --tsv: with CLAUDE_CONFIG_DIR set to a directory with no projects, whatever \$HOME holds"
is  "felix cost --tsv: that report's source is still \$CLAUDE_CONFIG_DIR/projects" "$(_fc_cover source)" '$CLAUDE_CONFIG_DIR/projects'

# ======================================================================
# Unreadable is a floor, never a full count. Skipped where this user can read
# a file with no read permission.
# ======================================================================
_fc_mk r13
FC_UF="$FC/r13/projects/-Users-dev-ok"
_fc_in "$FC_UF/ok.jsonl" msg_M1 "$FCT0" m-ok 90500000
_fc_in "$FC_UF/locked.jsonl" msg_M2 "$FCT0" m-locked 4000
chmod 000 "$FC_UF/locked.jsonl"
FCCFG="$FC/r13" _fc --tsv
FC_FLOOR_RC="$FCRC"
FC_FLOOR_ROWS="$(_fc_row total all)|$(_fc_row worktree -Users-dev-ok)|$(_fc_cover files_read) $(_fc_cover files_unread) $(_fc_cover coverage)"
FCCFG="$FC/r13" _fc
FC_FLOOR_TL="$(_fc_line total)"; FC_FLOOR_FL="$(_fc_line files)"
chmod 644 "$FC_UF/locked.jsonl"
_fcd  "felix cost --tsv: a report with one unreadable file still exits 0" "$FC_FLOOR_RC" "0"
_fcd  "felix cost --tsv: an unreadable in-window file leaves the total at what the readable files hold, with the rows as measured" \
      "$FC_FLOOR_ROWS" "$(_fc_exps total all 90500000.00 10.0 1)|$(_fc_exps worktree -Users-dev-ok 90500000.00 10.0 1)|1 1 floor"
_fcdh "felix cost (text): a floor reads at least" "$FC_FLOOR_TL" "at least"
_fcdh "felix cost (text): a floor's total still gives the millions it did find, 90.5M" "$FC_FLOOR_TL" "90.5M"
_fcdh "felix cost (text): the files line says how many could not be read" "$FC_FLOOR_FL" "1 could not be read"
_fcdh "felix cost (text): the files line says the total is a floor" "$FC_FLOOR_FL" "floor"

_fc_mk r14
FC_UD="$FC/r14/projects"
_fc_in "$FC_UD/-Users-dev-fine/ok.jsonl" msg_M3 "$FCT0" m-ok 2000
_fc_in "$FC_UD/-Users-dev-locked/s1.jsonl" msg_M4 "$FCT0" m-locked 9999
chmod 000 "$FC_UD/-Users-dev-locked"
FCCFG="$FC/r14" _fc --tsv
FC_FLOOR_ROWS="$(_fc_row total all)|$(_fc_cover files_read) $(_fc_cover files_unread) $(_fc_cover coverage)"
chmod 755 "$FC_UD/-Users-dev-locked"
_fcd  "felix cost --tsv: a record directory that cannot be entered counts as one unread, and the total is a floor" \
      "$FC_FLOOR_ROWS" "$(_fc_exps total all 2000.00 0.0 1)|1 1 floor"

_fc_mk r15
FC_US="$FC/r15/projects/-Users-dev-fine"
_fc_in "$FC_US/s.jsonl" msg_M5 "$FCT0" m-ok 3000
_fc_in "$FC_US/s/subagents/h.jsonl" msg_M6 "$FCT0" m-locked 9999
chmod 000 "$FC_US/s/subagents"
FCCFG="$FC/r15" _fc --tsv
FC_FLOOR_ROWS="$(_fc_row total all)|$(_fc_cover files_read) $(_fc_cover files_unread) $(_fc_cover coverage)"
chmod 755 "$FC_US/s/subagents"
_fcd  "felix cost --tsv: a subagents directory that cannot be entered counts as one unread, and the total is a floor" \
      "$FC_FLOOR_ROWS" "$(_fc_exps total all 3000.00 0.0 1)|1 1 floor"

_fc_mk r16
FC_UA="$FC/r16/projects/-Users-dev-x"
_fc_in "$FC_UA/locked.jsonl" msg_M7 "$FCT0" m-locked 4000
chmod 000 "$FC_UA/locked.jsonl"
FCCFG="$FC/r16" _fc --tsv
FC_ALL_ROWS="$(_fc_row total all)|$(_fc_cover coverage) $(_fc_cover files_unread)|$(_fc_kinds)"
FCCFG="$FC/r16" _fc
FC_ALL_TL="$(_fc_line total | awk '{ print $1, $2 }')"
chmod 644 "$FC_UA/locked.jsonl"
_fcd  "felix cost --tsv: when every file that should be read is unreadable the floor is 0 and the total reads unknown, never 0" \
      "$FC_ALL_ROWS" "$(printf 'total\tall\tunknown\tunknown\tunknown')|unknown 1|cover total"
_fcd  "felix cost (text): when every file that should be read is unreadable the total line reads unknown" "$FC_ALL_TL" "total unknown"

_fc_mk r17
FC_UO="$FC/r17/projects/-Users-dev-oldlock"
_fc_in "$FC_UO/old.jsonl" msg_M8 "$FCT0" m-old 4000
touch -t 202609010000 "$FC_UO/old.jsonl"
chmod 000 "$FC_UO/old.jsonl"
FCCFG="$FC/r17" _fc --tsv
FC_OLD_ROWS="$(_fc_row total all)|$(_fc_cover files_unread) $(_fc_cover coverage)"
chmod 644 "$FC_UO/old.jsonl"
_fcd  "felix cost --tsv: an unreadable file older than the window is not one that should be read, so it is not unread" \
      "$FC_OLD_ROWS" "$(_fc_exps total all 0.00 0.0 0)|0 measured"

# ======================================================================
# Usage errors and --help.
# ======================================================================
for FC_ARGS in "--bogus" "bogus" "-x"; do
  FCCFG="$FC/r1" _fc --tsv $FC_ARGS
  is  "felix cost $FC_ARGS (an unknown argument) is a usage error: exit 2, nothing on stdout, a felix cost: line and the usage line on stderr" \
      "$(_fc_usage_verdict)" "$FCUSAGE_OK"
done
FCCFG="$FC/r1" _fc --by bogus
is  "felix cost --by bogus is a usage error" "$(_fc_usage_verdict)" "$FCUSAGE_OK"
FCCFG="$FC/r1" _fc --by ''
is  "felix cost --by with an empty value is a usage error" "$(_fc_usage_verdict)" "$FCUSAGE_OK"
FCCFG="$FC/r1" _fc --by
is  "felix cost --by with no value is a usage error" "$(_fc_usage_verdict)" "$FCUSAGE_OK"
for FC_V in 0 x -1 1.5 ''; do
  FCCFG="$FC/r1" _fc --tsv --top "$FC_V"
  is  "felix cost --top [$FC_V] is not a positive integer: a usage error, exit 2, nothing on stdout, felix cost: and the usage line on stderr" \
      "$(_fc_usage_verdict)" "$FCUSAGE_OK"
done
FCCFG="$FC/r1" _fc --top
is  "felix cost --top with no value is a usage error" "$(_fc_usage_verdict)" "$FCUSAGE_OK"
for FC_V in --help -h; do
  FCCFG="$FC/r1" _fc "$FC_V"
  is  "felix cost $FC_V exits 0 and prints a usage line starting usage: felix cost" \
      "$FCRC $(awk '/^usage: felix cost/ { f = 1 } END { if (f) print "yes"; else print "no" }' "$FCOUTF" "$FCERRF")" "0 yes"
done

# ======================================================================
# Dispatched before any home is resolved, and it writes nothing.
# ======================================================================
_fc_snap() {   # the names, modes, sizes and checksums under each directory given
  local d
  for d in "$@"; do
    ( cd "${d:?}" && find . | LC_ALL=C sort | while IFS= read -r p; do ls -ld "$p"; done
      find . -type f -exec cksum {} + | LC_ALL=C sort )
  done
}
# A pristine place for the read-only check: a cwd, HOME and TMPDIR of its own and
# records roots copied from the cases above, so that a file the command writes on
# every run is not already there when the first listing is taken. Since slice 0
# of the load design (docs/2026-11-06-load-governor-design.md, C2 and C12) the
# command keeps its readings and their lock in HOME/.cache/felix/cost and nowhere
# else, so that directory is made before the first listing, and what is inside it
# is left out of both.
mkdir -p "$FC/ro/cwd" "$FC/ro/tmp" "$FC/ro/home/.claude/projects" "$FC/ro/cfgE/projects" "$FC/ro/cfg1" "$FC/ro/cfg6" \
  "$FC/ro/home/.cache/felix/cost"
_fc_snapro() { _fc_snap "$FC/ro" | awk '!index($0, "./home/.cache/felix/cost")'; }
cp -R "$FC/r1/projects/." "$FC/ro/home/.claude/projects/"
cp -R "$FC/r1/projects" "$FC/ro/cfg1/projects"
cp -R "$FC/r6/projects" "$FC/ro/cfg6/projects"
printf '%s\n' "$FC/no-such-felix-home" > "$FC/ro/home/.felix-home"
_fcro() { FCCWD="$FC/ro/cwd" FCHOME="$FC/ro/home" FCTMPD="$FC/ro/tmp" _fc "$@"; }
FC_SN0="$(_fc_snapro)"
FCCFG="$FC/ro/cfg1" _fcro --tsv;                                FC_RO_TSV="$FCOUT"
FCCFG="$FC/ro/cfg1" _fcro
FCCFG="$FC/ro/cfg1" _fcro --since 2026-10-09 --by model --top 2
FCCFG="$FC/ro/cfg6" _fcro --tsv
FCCFG="$FC/ro/cfgE" _fcro
FCCFG="$FC/ro/missing" _fcro --tsv
_fcro --tsv
_fcro --help
FCCFG="$FC/ro/cfg1" _fcro --bogus
FC_SN1="$(_fc_snapro)"
FC_SAME=changed
case "$FC_SN0" in *s1.jsonl*) [ "$FC_SN1" = "$FC_SN0" ] && FC_SAME=unchanged ;; *) FC_SAME="listing empty" ;; esac
FC_RO_ROW="$(printf '%s\n' "$FC_RO_TSV" | awk -F'\t' '$1 == "total"')"
is  "felix cost reports, and creates and changes nothing outside its readings: not under the records root, nor in its working directory, HOME or TMPDIR" \
    "$FC_RO_ROW|$FC_SAME" "$(_fc_exps total all 90500000.00 10.0 1)|unchanged"
FCCFG="$FC/ro/cfg1" _fcro --tsv
is  "felix cost leaves no scratch file in TMPDIR after a report" "$FCRC:$(ls -A "$FC/ro/tmp")" "0:"
FCCFG="$FC/r1" _fc --tsv;                                       FC_PLAIN="$FCOUT"
FCCFG="$FC/r1" FCFH="$FC/no-such-dir" _fc --tsv
is  "felix cost ignores a FELIX_HOME that does not exist and a HOME whose .felix-home names none" \
    "$(_fc_row total all)" "$(_fc_exps total all 90500000.00 10.0 1)"
mkdir -p "$FC/repo"
( _fx_cd "$FC/repo" && git init -q -b main && printf 'x\n' > file.txt )
FC_GS0="$(git -C "$FC/repo" status --porcelain)"; FC_SN0="$(_fc_snap "$FC/repo")"
FCCWD="$FC/repo" FCCFG="$FC/r1" _fc --tsv
FC_SN1="$(_fc_snap "$FC/repo")"; FC_GS1="$(git -C "$FC/repo" status --porcelain)"
FC_SAME=differ; [ "$FCOUT" = "$FC_PLAIN" ] && FC_SAME=same
is  "felix cost runs from inside a git repository the same as from outside one: the same report, with its total" \
    "$FC_SAME $(_fc_row total all | awk -F'\t' '{ print $3 }')" "same 90500000.00"
FC_SAME=changed; [ "$FC_SN1" = "$FC_SN0" ] && FC_SAME=unchanged
is  "felix cost writes nothing into the repository it is run from, and reports" \
    "$FCRC $FC_SAME" "0 unchanged"
FC_SAME=changed; [ "$FC_GS1" = "$FC_GS0" ] && FC_SAME=unchanged
is  "felix cost leaves the status of the repository it is run from as it was, and reports" \
    "$FCRC $FC_SAME" "0 unchanged"

