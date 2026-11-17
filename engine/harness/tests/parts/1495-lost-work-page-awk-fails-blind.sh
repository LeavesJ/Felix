# >>> lost-work-page-awk-fails-blind
printf '\nthe lost-work page, step 6: when the page awk fails, exit 1 and the repository named (contract B8 as amended 2026-10-19, B9.41, blind)\n'
# Written blind on 2026-10-19 from docs/2026-10-18-lost-work-page-contract.md
# alone (B4, B5, B6, B8 as amended 2026-10-19, B9.41), on the stubs, builders
# and run helpers in tests/lib/lost-work.sh. No line of the page's code was read.
#
# Two fixture repositories, awa (A) and awb (B), each _lw_repo's clone of a bare
# origin with main pushed, no project governing them and no pull requests. Every
# run passes --no-host and --no-gh: no host record and no gh answer is read, so
# the runs are cheap, and two runs over the same repository seconds apart print
# the same bytes but for the ages the origin row and the default-branch cover row
# read from the clock (the sessions and prs cover rows read unknown the same way
# each time, and age_h is the floor of whole hours, 0 for commits made here).
# That is what lets B9.41 compare the A-then-B page with B's page byte for byte,
# the ages aside (_lw95_unaged: a minute boundary between two runs is not a
# difference in what the page does).
#
# Three awk stubs, each in a directory of its own put first on PATH around the
# runs that use it, each ending in the real awk, whose path is taken with
# command -v before PATH changes:
#   one    exits 2 when an argument begins order=, else runs the real awk (B9.41);
#   first  does that for the first order= call it sees only, a marker directory
#          under this part's own temporary directory recording that it has (B9.41);
#   late   for an order= call runs the real awk, so the page's rows are printed,
#          and then exits 2 (B8: not even what the awk printed before it stopped).
_lw_build
LW95_HEAD='felix monitor: read-only. It wrote nothing, fetched nothing and acted on nothing; it read felix inventory and felix land --prs.'
LW95="$LW/aw95"; mkdir -p "$LW95/one" "$LW95/first" "$LW95/late" "$LW95/h/.claude/projects"
LW95R="$(command -v awk)"; LW95M="$LW95/first.mark"; LW95P="$PATH"
printf '#!/bin/bash\nfor a in "$@"; do case "$a" in order=*) exit 2 ;; esac; done\nexec "%s" "$@"\n' "$LW95R" > "$LW95/one/awk"
printf '#!/bin/bash\nfor a in "$@"; do case "$a" in order=*) mkdir "%s" 2>/dev/null && exit 2 ;; esac; done\nexec "%s" "$@"\n' "$LW95M" "$LW95R" > "$LW95/first/awk"
printf '#!/bin/bash\nf=0\nfor a in "$@"; do case "$a" in order=*) f=1 ;; esac; done\n[ "$f" = 1 ] || exec "%s" "$@"\n"%s" "$@"\nexit 2\n' "$LW95R" "$LW95R" > "$LW95/late/awk"
chmod +x "$LW95/one/awk" "$LW95/first/awk" "$LW95/late/awk"
_lw_repo awa; _lw_repo awb; LW95A="$LW/awa"; LW95B="$LW/awb"
_lw_prs fixture_awa; _lw_prs fixture_awb

# _lw95_with STUB-DIR NAME ARGS...: _lw_run NAME ARGS with STUB-DIR first on PATH,
# the first-call marker removed before; PATH is the part's own again after.
_lw95_with() {
  local d="$1"; shift
  rm -rf "$LW95M"
  PATH="$d:$LW95P"; _lw_run "$@"; PATH="$LW95P"
}
# _lw95_has NAME TEXT [TEXT2]: the number of stderr lines of run NAME holding TEXT (and TEXT2).
_lw95_has() { LC_ALL=C awk -v a="$2" -v b="${3:-}" 'index($0, a) && (b == "" || index($0, b)) { n++ } END { print n + 0 }' "$LWX/$1.err" 2>/dev/null; }
_lw95_named() { if [ "$(_lw95_has "$@")" -ge 1 ] 2>/dev/null; then printf named; else printf unnamed; fi; }
# _lw95_b8 NAME DIR: how many stderr lines of run NAME are B8's line for DIR, exactly.
_lw95_b8() { LC_ALL=C awk -v w="felix monitor: $2: the page could not be made from its rows (awk exited 2)" '$0 == w { n++ } END { print n + 0 }' "$LWX/$1.err" 2>/dev/null; }
# _lw95_only NAME: "LINES|TEXT" of run NAME's stdout; _lw95_empty NAME: empty or "N bytes".
_lw95_only() { printf '%s|%s' "$(LC_ALL=C awk 'END { print NR }' "$(_lw_o "$1")" 2>/dev/null)" "$(cat "$(_lw_o "$1")" 2>/dev/null)"; }
_lw95_empty() { if [ -s "$(_lw_o "$1")" ]; then printf '%s bytes' "$(LC_ALL=C wc -c < "$(_lw_o "$1")" | LC_ALL=C tr -d ' ')"; else printf empty; fi; }
# _lw95_unaged RUN: RUN's stdout with every age it prints put as "<age> ago", and no other byte changed (a final
# newline sed may supply is supplied on both sides of a comparison). The origin row's
# ages are read from the clock when each run is made ("origin/main last moved 35 min ago", "last fetch, of any
# ref, 0 min ago", and the default branch's "fetched 0h ago"), in the text page, in --tsv and in the two sources
# alone, so two runs on different sides of a minute, or of an hour, print different bytes for the same behaviour:
# on 2026-11-07 a gate read 35 min against 45 because the Mac slept between the two runs.
_lw95_unaged() { LC_ALL=C sed -E 's/[0-9]+ ?(min|h|days) ago/<age> ago/g' "$(_lw_o "$1")" 2>/dev/null; }
# _lw95_same RUN REF: "same" when RUN's stdout is REF's byte for byte, the ages each prints aside, and REF printed something.
_lw95_same() {
  if [ -s "$(_lw_o "$2")" ] && cmp -s <(_lw95_unaged "$1") <(_lw95_unaged "$2"); then printf same; return 0; fi
  [ -s "$(_lw_o "$2")" ] || { printf 'the reference run printed nothing'; return 0; }
  diff <(_lw95_unaged "$2") <(_lw95_unaged "$1") 2>&1 | LC_ALL=C awk 'NR <= 4 { printf "%s; ", $0 }'
}
# _lw95_try CMD...: "OUT:STATUS " of CMD run in the C locale.
_lw95_try() { local o; o="$(LC_ALL=C "$@" 2>/dev/null)"; printf '%s:%s ' "$o" "$?"; }

is "B9.41 fixture: the stub exits 2 on an argument beginning order= and runs the real awk otherwise, the first-call stub fails only its first such call, and the late stub prints what the real awk prints and exits 2 (fixture control)" \
   "$(_lw95_try "$LW95/one/awk" 'BEGIN { print "real" }')$(_lw95_try "$LW95/one/awk" -v order=x 'BEGIN { print "real" }')$(rm -rf "$LW95M"; _lw95_try "$LW95/first/awk" -v order=x 'BEGIN { print "real" }'; _lw95_try "$LW95/first/awk" -v order=x 'BEGIN { print "real" }')$(_lw95_try "$LW95/late/awk" -v order=x 'BEGIN { print "real" }')" \
   "real:0 :2 :2 real:0 real:2 "
rm -rf "$LW95M"
# The comparison B9.41 makes puts every age as "<age> ago" and changes nothing else. Y1 and Y2 differ only in their
# ages (minutes, hours, days, and the cover row's "0h"); Y3 has another commit, Y4 another word, and Y0 is no output.
LW95Y="B 1a2b3c4, default branch main (origin/HEAD), origin/main last moved 35 min ago; last fetch, of any ref, 2 h ago"
printf 'first\n  %s\n  read default read: origin/main @ 1a2b3c4d; fetched 0h ago\n' "$LW95Y" > "$(_lw_o AW95Y1)"
printf 'first\n  %s\n  read default read: origin/main @ 1a2b3c4d; fetched 23h ago\n' \
  "B 1a2b3c4, default branch main (origin/HEAD), origin/main last moved 45 min ago; last fetch, of any ref, 3 days ago" > "$(_lw_o AW95Y2)"
printf 'first\n  %s\n  read default read: origin/main @ 1a2b3c4d; fetched 0h ago\n' "${LW95Y/1a2b3c4,/1a2b3c5,}" > "$(_lw_o AW95Y3)"
printf 'first\n  %s\n  read default read: origin/main @ 1a2b3c4d; fetched 0h ago\n' "${LW95Y/last moved/last fetched}" > "$(_lw_o AW95Y4)"
: > "$(_lw_o AW95Y0)"
is "B9.41 fixture: the comparison ignores the ages two pages print and nothing else: pages that differ only in an age are the same, another commit or another word is a difference, and no reference output is no verdict (fixture control)" \
   "$(_lw95_same AW95Y2 AW95Y1) $([ "$(_lw95_same AW95Y3 AW95Y1)" = same ] && echo hid-commit || echo saw-commit) $([ "$(_lw95_same AW95Y4 AW95Y1)" = same ] && echo hid-word || echo saw-word) $(_lw95_same AW95Y1 AW95Y0)" \
   "same saw-commit saw-word the reference run printed nothing"

# ---- the runs ------------------------------------------------------------------------
# With the real awk: the controls, and the references B9.41 compares with.
_lw_run AW95A0  "$LW95/h" "$LW/cwd" monitor --repo "$LW95A" --no-host --no-gh
_lw_run AW95A0S "$LW95/h" "$LW/cwd" monitor --tsv --repo "$LW95A" --no-host --no-gh
_lw_run AW95X0  "$LW95/h" "$LW/cwd" monitor --repo "$LW95A" --repo "$LW95B" --no-host --no-gh
_lw_run AW95X0S "$LW95/h" "$LW/cwd" monitor --tsv --repo "$LW95A" --repo "$LW95B" --no-host --no-gh
_lw_run AW95I0  "$LW95/h" "$LW/cwd" inventory --tsv --repo "$LW95A" --no-host --no-gh
_lw_run AW95L0  "$LW95/h" "$LW/cwd" land --prs --tsv --repo "$LW95A" --no-gh
# With the stub: one repository, and the two sources alone.
_lw95_with "$LW95/one" AW95A1  "$LW95/h" "$LW/cwd" monitor --repo "$LW95A" --no-host --no-gh
_lw95_with "$LW95/one" AW95A1S "$LW95/h" "$LW/cwd" monitor --tsv --repo "$LW95A" --no-host --no-gh
_lw95_with "$LW95/one" AW95I1  "$LW95/h" "$LW/cwd" inventory --tsv --repo "$LW95A" --no-host --no-gh
_lw95_with "$LW95/one" AW95L1  "$LW95/h" "$LW/cwd" land --prs --tsv --repo "$LW95A" --no-gh
# With the first-call stub: A then B, each next to B alone with the real awk.
_lw_run AW95B0 "$LW95/h" "$LW/cwd" monitor --repo "$LW95B" --no-host --no-gh
_lw95_with "$LW95/first" AW95X1 "$LW95/h" "$LW/cwd" monitor --repo "$LW95A" --repo "$LW95B" --no-host --no-gh
LW95M1="$([ -d "$LW95M" ] && echo failed-one || echo never-called)"
_lw_run AW95B0S "$LW95/h" "$LW/cwd" monitor --tsv --repo "$LW95B" --no-host --no-gh
_lw95_with "$LW95/first" AW95X1S "$LW95/h" "$LW/cwd" monitor --tsv --repo "$LW95A" --repo "$LW95B" --no-host --no-gh
LW95M2="$([ -d "$LW95M" ] && echo failed-one || echo never-called)"
# With the late stub: one repository.
_lw95_with "$LW95/late" AW95A2  "$LW95/h" "$LW/cwd" monitor --repo "$LW95A" --no-host --no-gh
_lw95_with "$LW95/late" AW95A2S "$LW95/h" "$LW/cwd" monitor --tsv --repo "$LW95A" --no-host --no-gh
PATH="$LW95P"; rm -rf "$LW95M"

# ---- controls: the real awk --------------------------------------------------------
is "B9.41 control: with the real awk the page over A exits 0, as text beginning with B6's first line and as --tsv holding its 17 summaries" \
   "$(_lw_rc AW95A0)$(_lw_rc AW95A0S) $([ "$(LC_ALL=C awk 'NR == 1 { print; exit }' "$(_lw_o AW95A0)" 2>/dev/null)" = "$LW95_HEAD" ] && echo first-line || echo 'no first line') $(_lw_n16 "$(_lw_o AW95A0S)")" \
   "00 first-line 17"
is "B9.41 control: with the real awk --repo A --repo B and --repo B alone exit 0, as text and as --tsv, and the TSV over both holds 34 summaries" \
   "$(_lw_rc AW95X0)$(_lw_rc AW95X0S)$(_lw_rc AW95B0)$(_lw_rc AW95B0S) $(_lw_n16 "$(_lw_o AW95X0S)")" "0000 34"
is "B9.41 control: under the stub felix inventory --tsv and felix land --prs --tsv over A exit and print as they do with the real awk, so order= is the page's own call" \
   "$(_lw_rc AW95I1) $(_lw_rc AW95L1) $(_lw95_same AW95I1 AW95I0) $(_lw95_same AW95L1 AW95L0)" "$(_lw_rc AW95I0) $(_lw_rc AW95L0) same same"

# ---- B9.41, B8: the page's awk fails on the one repository --------------------------
is "B9.41: with the stub, felix monitor --repo A exits 1" "$(_lw_rc AW95A1)" 1
is "B9.41: and its stdout is the first line alone" "$(_lw95_only AW95A1)" "1|$LW95_HEAD"
is "B9.41: and a stderr line holds the directory as given and awk exited 2" "$(_lw95_named AW95A1 "$LW95A" 'awk exited 2')" named
is "B8: that stderr line is felix monitor: <the directory as given>: the page could not be made from its rows (awk exited 2), said once" \
   "$(_lw95_b8 AW95A1 "$LW95A")" 1
is "B9.41: with the stub, felix monitor --tsv --repo A exits 1 with nothing on stdout" "$(_lw_rc AW95A1S)|$(_lw95_empty AW95A1S)" "1|empty"
is "B9.41: and --tsv writes a stderr line holding the directory as given and awk exited 2" "$(_lw95_named AW95A1S "$LW95A" 'awk exited 2')" named
is "B8: and under --tsv that line too is B8's, said once" "$(_lw95_b8 AW95A1S "$LW95A")" 1

# ---- B9.41, B8: the first repository's awk fails, the second's does not --------------
is "B9.41: with the first-call stub, --repo A --repo B exits 1, the stub having failed the page's first order= call" "$(_lw_rc AW95X1) $LW95M1" "1 failed-one"
is "B9.41: a stderr line names A and holds awk exited 2" "$(_lw95_named AW95X1 "$LW95A" 'awk exited 2')" named
is "B9.41: no stderr line names B" "$(_lw95_has AW95X1 "$LW95B")" 0
is "B9.41: and stdout is what felix monitor --repo B prints with the real awk, the ages each prints aside" "$(_lw_rc AW95B0)|$(_lw95_same AW95X1 AW95B0)" "0|same"
is "B9.41: with the first-call stub, --tsv --repo A --repo B exits 1, the stub having failed the page's first order= call" "$(_lw_rc AW95X1S) $LW95M2" "1 failed-one"
is "B9.41: under --tsv a stderr line names A and holds awk exited 2" "$(_lw95_named AW95X1S "$LW95A" 'awk exited 2')" named
is "B9.41: under --tsv no stderr line names B" "$(_lw95_has AW95X1S "$LW95B")" 0
is "B9.41: and the TSV is what felix monitor --tsv --repo B prints with the real awk, the ages each prints aside" "$(_lw_rc AW95B0S)|$(_lw95_same AW95X1S AW95B0S)" "0|same"
is "B8: in both two-repository runs the line for A is B8's, said once" "$(_lw95_b8 AW95X1 "$LW95A") $(_lw95_b8 AW95X1S "$LW95A")" "1 1"

# ---- B8: what the awk printed before it stopped reaches no stdout ---------------------
is "B8: when the page's awk prints its rows and then exits 2, the text page is the first line alone and exits 1" "$(_lw_rc AW95A2)|$(_lw95_only AW95A2)" "1|1|$LW95_HEAD"
is "B8: and --tsv prints nothing and exits 1" "$(_lw_rc AW95A2S)|$(_lw95_empty AW95A2S)" "1|empty"
is "B8: and both say B8's line for A on stderr, once each" "$(_lw95_b8 AW95A2 "$LW95A") $(_lw95_b8 AW95A2S "$LW95A")" "1 1"
# <<< lost-work-page-awk-fails-blind
