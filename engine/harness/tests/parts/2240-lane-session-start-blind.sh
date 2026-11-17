# >>> lane-session-start
printf '\nlane session start: the paragraph and the screen token, where they show and where they stay silent (slice 0, design 6.5 items 3 and 4 and 6.6, C7, L-RF2 to L-RF5, L-RO; blind)\n'
# Blind, written on 2026-10-29 from docs/2026-10-29-capability-lane-first-slices-design.md and the slice 0 plan's
# Contracts (C1-C13) alone, before lib/lane.sh existed, without reading lib/, hooks/, bin/ or felix. Felix is run as a
# black box; the builders are tests/lib/lane-fixture.sh's. C11's row for this part: section 6.5 items 3 and 4 and 6.6
# "What shows where": the paragraph only for short, zero and idle, the token only for zero and idle, neither without a
# committed lanes.tsv; the exact paragraph at share 1/2 and at 1/4; a Claude Code resume; L-RF2; L-RF4; the
# session-start half of L-RO; the hook with lib/lane.sh removed from a harness copy. With them, the session-start halves
# of L-RF3 and L-RF5.
#
# The home apart (C9): H holds project sx, each checkout is bound to sx by an untracked .felix, and H's lanes.tsv and
# lane-next.tsv are committed as each case needs; every case checks that H's HEAD holds what it names. Each checkout's
# root is a month before the clock, its landings (_lf_chain) five days before it, an hour apart. Session start runs as C9
# says (_lf_start): the suite's hooks/session-start, a startup payload, the fixture HOME and memory root, the stubs first
# on PATH, then up to 20 s for the discovery lock. Its JSON is read with python3, and every assertion that reads it is
# skipped, with the reason, when python3 is absent. Readings where the Contracts leave room:
# - A paragraph is asserted as C7 places it in the context, LF, its first line, LF, its second line, LF, and counted:
#   once, or not at all. On this engine the screen line of such a session is "Felix: sx" alone, so the token is asserted
#   on the whole line, which also shows it last and once.
# - "While the share is 1/2" is C12 item 10's 2n = d: 2/4 closes as 1/2 does, and 1/4 and 1/3 as any other share.
# - The placement case adds a pull request waiting in the lander's ledger, as part 1670's A43 builds it, so a "what
#   waits" paragraph comes before the lane paragraph and a PRs waiting token before the lane token.
# - L-RF2's control bytes are ESC and FF, as C10 names them, and 0x01 and DEL from C7's range: each reads ? in the
#   context and stands unchanged in felix lane --tsv column 9.
# - The controls are C10's: silence for ok, unknown, no committed lanes.tsv or none with a row, a Claude Code resume and
#   a directory no project governs; L-RF3's and L-RF5's session-start halves; L-RO's; the broken engine. Each silent
#   case that has a lane uses a checkout where the committed 1/2 table shows the paragraph and the token.
# - The own checkout (C7, C9, design 6.5 items 3 and 4, 11 item 44), amended on 2026-10-30, still blind. Every checkout
#   above, those that show the paragraph and those that stay silent, the shallow clone included, is sx's own (_lf_own):
#   H's project.json names remote_match lane-fixture/sx, written in H's working tree and never committed, and each
#   checkout's origin is https://github.com/lane-fixture/sx.git, never fetched (the clone's set to it), so no case is
#   silent for want of ownership. Its "built" says so. Making them own changed nothing else an assertion reads: no
#   checkout holds a manifest that adoption reads, and the home grants no autonomy, so none of the unattended work an
#   own checkout allows (adoption, the graph refresh, tidying) showed in a session start when this was written.
#   L-OWN and C7's nothing-withheld rule close the part, each case in a fresh home of its own, because the withheld line
#   is said once per checkout and set of kinds, keyed in the home. L-OWN's four homes hold the same commits at the same
#   times, and its four checkouts the same commits, so felix lane --tsv's columns 10 to 12 are the same bytes in all
#   four; each differs only in project.json, written after those commits, and in its origin remote. The withheld line
#   is read as C7 gives it: a context line starting "Nothing ran here unattended: ", whose kinds, after "Withheld: " and
#   without the closing full stop, are split on ", "; "lane item" must be one of them, whatever other kinds a fixture
#   makes due. Red on main as C10 says: each such assertion also requires felix
#   lane --tsv's exit 0 and the fixture's expected output (nothing, for the home with no committed lanes.tsv), and the
#   exit 0 and valid JSON of those session starts are controls of their own.
# - The second review's round 2 (2026-10-30, still blind) adds, at the end, R2B-F4: a lane-next.tsv row for lane 01
#   beside a lanes.tsv holding lane 1 alone leaves lane 1's paragraph saying (lane-next.tsv names none).
# - The review's second amendment (2026-10-30, design 11 item 45, still blind) adds, at the end, C11's 1 day in the
#   paragraph and the token (F11) and a count that ends early (F1), whose silence is asserted with the paragraph and token
#   the same session start shows without the fault, which main cannot print; and the paragraph for a next text that is
#   exactly none or unknown (F9, C1), with felix lane --tsv's column 9.
# - The second review's round 3 (2026-10-30, still blind) adds, at the end, R3-F1: a soft open-file limit from 10 to 24
#   set in the shell that execs the hook, where the first lane is short.
LNGN=1793000000; LNGDAY=86400; LNGK=0
LNGNEXT='obligation intake, slice 1: felix situations --change (branch claude/lane-situations-owed)'
LNGPY=0; command -v python3 >/dev/null 2>&1 && LNGPY=1
LNGWHY="python3 is absent, and the hook's JSON is read with it"
_lf_dir "$TMP/lane-2240"; LNGD="$LF_DIR"; mkdir -p "$LNGD/plain"
_lf_stubs "$LNGD"; LNGB="$LF_BIN"
_lf_home "$LNGD/home" sx 1792500000; LNGH="$LF_HOME"; LNGP="$LF_PROJ"
_lf_use "$LNGH" "$LNGD/memory" "$LNGD/user" "$LNGB"
LNGURL='https://github.com/lane-fixture/sx.git'; LNGOWNJ='{"name":"sx","gate":"true","remote_match":"lane-fixture/sx"}'
LNGLANES=$'capability\t^engine/\t1/2\t14\n'
LNGNEXTS="$(_lf_tsv capability "$LNGNEXT")"$'\n'
LNGSCR='Felix: sx'; LNGTOK14="$LNGSCR · lane: 0 in 14 days"
LNGCLH='Trust work takes the other half.'; LNGCLR='The rest goes to trust work.'
# STATE L T W SHARE NEXT CLOSING [LANE] -> the paragraph's two lines (C7), a newline between them.
_lng_par() {
  printf 'Lane %s is %s: %s of %s engine landings in %s days, target %s.\nIf the founder has not given this session a task, take the first open lane item: %s. End the body of a commit on its branch that is not a merge with the line `Felix-Lane: %s`. %s' \
    "${8:-capability}" "$1" "$2" "$3" "$4" "$5" "$6" "${8:-capability}" "$7"
}
LNGZ12="$(_lng_par zero 0 2 14 1/2 "$LNGNEXT" "$LNGCLH")"

# NAME SPEC... -> LNGR a checkout $LNGD/NAME bound to sx and sx's own (_lf_own: H's project.json names remote_match
# lane-fixture/sx, the checkout's origin is LNGURL), its root a month before the clock, then SPEC's landings (_lf_chain)
# from five days before it, an hour apart, published. LNGE "built" when H's project.json is LNGOWNJ and the first-parent
# chain of refs/remotes/origin/main holds the root and every landing.
_lng_chk() {
  local n="$1"
  shift
  LNGE="not built: $n"; LNGR=""
  _lf_checkout "$LNGD/$n" sx $((LNGN - 30 * LNGDAY)) || return 1
  LNGR="$LF_REPO"
  _lf_own "$LNGP" "$LNGR" lane-fixture/sx || return 1
  _lf_chain "$LNGR" capability $((LNGN - 5 * LNGDAY)) 3600 "$@" || return 1
  [ "$(cat "$LNGP/project.json")" = "$LNGOWNJ" ] && [ "$(_lf_spine "$LNGR" | LC_ALL=C awk '{ print NF }')" = "$(($# + 1))" ] \
    && LNGE=built
}
# REL BYTES -> H's HEAD holds projects/sx/REL as exactly BYTES; status 0 when it does.
_lng_holds() {
  printf '%s' "$2" > "$LNGD/holds.want"
  ( _fx_cd "$LNGH" || exit 1; _lf_g 1700000000 cat-file blob "HEAD:projects/sx/$1" ) > "$LNGD/holds.got" 2>/dev/null
  cmp -s "$LNGD/holds.want" "$LNGD/holds.got"
}
_lng_lacks() { ! ( _fx_cd "$LNGH" && _lf_g 1700000000 cat-file -e "HEAD:projects/sx/$1" ) >/dev/null 2>&1; }
# LABEL LANES [NEXT] -> lanes.tsv LANES and lane-next.tsv NEXT (LNGNEXTS when not given; - for none), committed in H
# at the next times. LNGT "built" when H's HEAD holds exactly those bytes, and no lane-next.tsv for -.
_lng_put() {
  local n="${3-$LNGNEXTS}" t
  LNGK=$((LNGK + 1)); t=$((1792500000 + 100 * LNGK)); LNGT="not built: $1"
  rm -f "$LNGP/lanes.tsv" "$LNGP/lane-next.tsv"
  _lf_table "$LNGP" "$t" lanes.tsv "$2" "lanes.tsv: $1"$'\n' || return 1
  if [ "$n" = - ]; then
    _lng_lacks lane-next.tsv || _lf_commit "$LNGP" $((t + 50)) "lane-next.tsv removed: $1"$'\n' -lane-next.tsv || return 1
    _lng_holds lanes.tsv "$2" && _lng_lacks lane-next.tsv && LNGT=built
  else
    _lf_table "$LNGP" $((t + 50)) lane-next.tsv "$n" "lane-next.tsv: $1"$'\n' || return 1
    _lng_holds lanes.tsv "$2" && _lng_holds lane-next.tsv "$n" && LNGT=built
  fi
}
# LABEL -> H's HEAD holds neither table: commits remove the ones it holds. LNGT "built" when so.
_lng_absent() {
  local f
  LNGK=$((LNGK + 1)); LNGT="not built: $1"
  for f in lanes.tsv lane-next.tsv; do
    _lng_lacks "$f" || _lf_commit "$LNGP" $((1792500000 + 100 * LNGK)) "$f removed: $1"$'\n' "-$f" || return 1
  done
  _lng_lacks lanes.tsv && _lng_lacks lane-next.tsv && LNGT=built
}
# DIR [NOW [SOURCE [ROOT]]] -> session start in DIR (_lf_start: the clock LNGN, source startup, the suite's engine);
# LNGF the stem of its files, LF_RC, LF_JSON, LF_CTX, LF_SCR as _lf_start sets them.
_lng_ss() {
  LNGK=$((LNGK + 1)); LNGF="$LNGD/ss-$LNGK"
  _lf_start "$LNGF" "$1" "${2-$LNGN}" "${3:-startup}" ${4+"$4"}
}
# TEXT -> how many times the last session's context holds LF TEXT LF (C7); "unread" when python3 cannot say.
_lng_n() {
  printf '%s' "$1" > "$LNGD/want"
  python3 -c 'import sys
d = open(sys.argv[1], "rb").read(); t = b"\n" + open(sys.argv[2], "rb").read() + b"\n"
sys.stdout.write(str(d.count(t)))' "$LNGF.ctx" "$LNGD/want" 2>/dev/null || printf 'unread'
}
# TEXT -> the byte offset of LF TEXT LF in the last context, -1 when it is not there.
_lng_at() {
  printf '%s' "$1" > "$LNGD/want"
  python3 -c 'import sys
d = open(sys.argv[1], "rb").read(); t = b"\n" + open(sys.argv[2], "rb").read() + b"\n"
sys.stdout.write(str(d.find(t)))' "$LNGF.ctx" "$LNGD/want" 2>/dev/null || printf 'unread'
}
# LINE -> "between" when the last context's line LINE comes after its first line starting "Memory: ", after the
# waiting-PR header and before its first line starting "Read before planning:", else the four line numbers.
_lng_where() {
  LC_ALL=C awk -v p="$1" -v w="Pull requests waiting longer than four hours" '
    index($0, "Memory: ") == 1 && !m { m = NR } index($0, "Read before planning:") == 1 && !r { r = NR }
    index($0, w) == 1 && !x { x = NR } $0 == p && !l { l = NR }
    END { print (m && x && l && r && m < x && x < l && l < r) ? "between" : "out(" m "," x "," l "," r ")" }' "$LNGF.ctx" 2>/dev/null
}
_lng_is() { if [ "$LNGPY" = 1 ]; then is "$1" "$2" "$3"; else skip "$1" "$LNGWHY"; fi; }

_lng_chk zero u u; LNGZ="$LNGR"; LNGZE="$LNGE"
_lng_chk short m u u u; LNGS="$LNGR"; LNGSE="$LNGE"
_lng_chk ok m u; LNGO="$LNGR"; LNGOE="$LNGE"
_lng_chk idle; LNGI="$LNGR"; LNGIE="$LNGE"

# ---- the paragraph and the token, by state, at share 1/2 ---------------------------------------------------------------
_lng_put "share 1/2" "$LNGLANES"
_lng_ss "$LNGZ"
_lng_is "lane session start: zero at share 1/2: exit 0, valid JSON, the context holds the paragraph once, word for word, ending Trust work takes the other half., and the screen line ends with the token · lane: 0 in 14 days" \
   "$LNGZE|$LNGT|$LF_RC|$LF_JSON|$(_lng_n "$LNGZ12")|$LF_SCR" "built|built|0|ok|1|$LNGTOK14"
_lng_ss "$LNGS"
_lng_is "lane session start: short at share 1/2 (L 1 of T 4): the context holds the short paragraph once, and the screen line carries no lane token" \
   "$LNGSE|$LNGT|$LF_RC|$LF_JSON|$(_lng_n "$(_lng_par short 1 4 14 1/2 "$LNGNEXT" "$LNGCLH")")|$LF_SCR" "built|built|0|ok|1|$LNGSCR"
_lng_ss "$LNGI"
_lng_is "lane session start: idle at share 1/2 (no landing in the window): the context holds the idle paragraph once, 0 of 0, and the screen line ends with · lane: 0 in 14 days" \
   "$LNGIE|$LNGT|$LF_RC|$LF_JSON|$(_lng_n "$(_lng_par idle 0 0 14 1/2 "$LNGNEXT" "$LNGCLH")")|$LF_SCR" "built|built|0|ok|1|$LNGTOK14"
_lng_ss "$LNGO"
_lng_is "lane session start: ok at share 1/2 (L 1 of T 2): exit 0, valid JSON, neither a lane paragraph nor a lane token (control)" \
   "$LNGOE|$LNGT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|0|ok|none"
_lf_checkout "$LNGD/noref" sx $((LNGN - 30 * LNGDAY)); LNGNR="$LF_REPO"; LNGa="not built: a checkout with no ref"
_lf_own "$LNGP" "$LNGNR" lane-fixture/sx && _lf_commit "$LNGNR" $((LNGN - LNGDAY)) $'engine: x\n' engine/x.sh \
  && LNGa="$( _fx_cd "$LNGNR" || exit 1; _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main >/dev/null 2>&1 && echo has-ref || echo built )"
_lng_ss "$LNGNR"
_lng_is "lane session start: unknown, a checkout with no refs/remotes/origin/main: exit 0, valid JSON, neither a lane paragraph nor a lane token (control)" \
   "$LNGa|$LNGT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|0|ok|none"
_lng_ss "$LNGZ" "$LNGN" resume
_lng_is "lane session start: a Claude Code resume where startup shows the zero paragraph and token exits 0 with neither (control)" \
   "$LNGZE|$LNGT|$LF_RC|$(_lf_silent capability)" "built|built|0|none"
_lng_ss "$LNGD/plain"
_lng_is "lane session start: in a directory no project governs, session start exits 0 with neither a lane paragraph nor a lane token (control)" \
   "$LF_RC|$(_lf_silent capability)" "0|none"

# ---- where the paragraph sits, and an uncommitted edit ------------------------------------------------------------------
LNGNOW="$(date +%s)"; LNGL="$LNGD/memory/sx/land"; LNGT30="$(_lf_iso $((LNGNOW - 108000)))"
LNGW="waits on a session since $LNGT30: session: no checkout holds the gated head"
mkdir -p "$LNGL"
printf '%s\tsession\t425\t%s\t-\t0\t%s\n' "$LNGT30" 0425c0ffeec0ffeec0ffeec0ffeec0ffeec0ffee 'no checkout holds the gated head' > "$LNGL/ledger.tsv"
printf '%s\twaiting\t425\t%s\t-\t0\t%s\n' "$(_lf_iso $((LNGNOW - 7200)))" 0425c0ffeec0ffeec0ffeec0ffeec0ffeec0ffee "$LNGW" >> "$LNGL/ledger.tsv"
_lng_ss "$LNGZ"
_lng_is "lane session start: with a pull request waiting, the zero paragraph sits after Memory: and after the waiting-PR paragraph, before Read before planning:, and the lane token is last on the screen line, after PRs waiting: 1" \
   "$LNGZE|$LNGT|$LF_RC|$(_lng_n "$LNGZ12")|$(_lng_where 'Lane capability is zero: 0 of 2 engine landings in 14 days, target 1/2.')|$LF_SCR" \
   "built|built|0|1|between|$LNGSCR · PRs waiting: 1 · lane: 0 in 14 days"
rm -rf "$LNGL"
printf '%s' $'capability\t^engine/\t1/4\t7\n' > "$LNGP/lanes.tsv"; printf '%s\n' "$(_lf_tsv capability 'an item never committed')" > "$LNGP/lane-next.tsv"
_lng_ss "$LNGZ"
_lng_is "lane session start: uncommitted edits to lanes.tsv (share 1/4, window 7) and lane-next.tsv change nothing: the paragraph and the token read the committed share 1/2, 14 days and next" \
   "$LNGZE|$LNGT|$LF_RC|$(_lng_n "$LNGZ12")|$LF_SCR" "built|built|0|1|$LNGTOK14"

# ---- the closing sentence, and the lane and window from the table ---------------------------------------------------------
_lng_put "share 1/4" $'capability\t^engine/\t1/4\t14\n'
_lng_ss "$LNGZ"
_lng_is "lane session start: zero at share 1/4: the paragraph, word for word, ends The rest goes to trust work., and the token is · lane: 0 in 14 days" \
   "$LNGZE|$LNGT|$LF_RC|$LF_JSON|$(_lng_n "Lane capability is zero: 0 of 2 engine landings in 14 days, target 1/4."$'\n'"If the founder has not given this session a task, take the first open lane item: $LNGNEXT. End the body of a commit on its branch that is not a merge with the line \`Felix-Lane: capability\`. The rest goes to trust work.")|$LF_SCR" \
   "built|built|0|ok|1|$LNGTOK14"
_lng_put "share 2/4" $'capability\t^engine/\t2/4\t14\n'
_lng_ss "$LNGZ"
_lng_is "lane session start: zero at share 2/4, where 2n = d as at 1/2: the paragraph ends Trust work takes the other half." \
   "$LNGZE|$LNGT|$LF_RC|$(_lng_n "$(_lng_par zero 0 2 14 2/4 "$LNGNEXT" "$LNGCLH")")|$LF_SCR" "built|built|0|1|$LNGTOK14"
_lng_put "lane cap.lane_2, window 9, share 1/3" $'cap.lane_2\t^engine/\t1/3\t9\n' "$(_lf_tsv cap.lane_2 "the second lane's own item")"$'\n'
_lng_ss "$LNGZ"
_lng_is "lane session start: the paragraph and the token take the lane name and the window from the table: lane cap.lane_2, 9 days, share 1/3, its mark and its next, and · lane: 0 in 9 days" \
   "$LNGZE|$LNGT|$LF_RC|$(_lng_n "$(_lng_par zero 0 2 9 1/3 "the second lane's own item" "$LNGCLR" cap.lane_2)")|$LF_SCR" \
   "built|built|0|1|$LNGSCR · lane: 0 in 9 days"

# ---- two rows: a paragraph per row, the token from the first ----------------------------------------------------------------
_lng_put "ok first, then an idle docs lane" $'capability\t^engine/\t1/2\t14\ndocs\t^docs/\t1/2\t14\n' \
  "$LNGNEXTS$(_lf_tsv docs 'the docs item')"$'\n'
_lng_ss "$LNGO"
_lng_is "lane session start: a first row ok and a second idle: the idle row's paragraph only, none for the ok lane, and no token, since the first row is ok" \
   "$LNGOE|$LNGT|$LF_RC|$(_lng_n "$(_lng_par idle 0 0 14 1/2 'the docs item' "$LNGCLH" docs)")|$(case "$LF_CTX" in (*'Lane capability is '*) echo 'a capability paragraph' ;; (*) echo none ;; esac)|$LF_SCR" \
   "built|built|0|1|none|$LNGSCR"
_lng_put "zero first, then short" $'trust\t^engine/\t1/2\t10\ncapability\t^engine/\t1/2\t14\n' \
  "$(_lf_tsv trust 'the trust item')"$'\n'"$LNGNEXTS"
_lng_ss "$LNGS"
LNGa="$(_lng_at "$(_lng_par zero 0 4 10 1/2 'the trust item' "$LNGCLH" trust)")"; LNGb="$(_lng_at "$(_lng_par short 1 4 14 1/2 "$LNGNEXT" "$LNGCLH")")"
_lng_is "lane session start: a first row zero (window 10) and a second short: both paragraphs, in file order, and the token from the first row, · lane: 0 in 10 days" \
   "$LNGSE|$LNGT|$LF_RC|$([ "$LNGa" -ge 0 ] 2>/dev/null && [ "$LNGb" -gt "$LNGa" ] 2>/dev/null && echo 'in order' || echo "at $LNGa and $LNGb")|$LF_SCR" \
   "built|built|0|in order|$LNGSCR · lane: 0 in 10 days"

# ---- L-RF2: next is free text -------------------------------------------------------------------------------------------------------
LNGQ='fix "a\b" — now'
_lng_put "next with a quote, a backslash and an em dash" "$LNGLANES" "$(_lf_tsv capability "$LNGQ")"$'\n'
_lng_ss "$LNGZ"; LNGRC="$LF_RC"; _lf_run "$LNGD/rf2a" "$LNGZ" "$LNGN" "$FELIX" lane --tsv
_lng_is "lane session start L-RF2: next holding a double quote, a backslash and an em dash, the lane zero: session start exits 0 with valid JSON whose context holds the next text byte for byte in the paragraph, and felix lane --tsv exits 0 printing it unchanged in column 9" \
   "$LNGZE|$LNGT|$LNGRC|$LF_JSON|$(_lng_n "$(_lng_par zero 0 2 14 1/2 "$LNGQ" "$LNGCLH")")|$LF_RC|$(_lf_cols "$LNGD/rf2a.out" 1 2 9)" \
   "built|built|0|ok|1|0|zero|$LNGQ"
LNGQ=$'esc \033[1m bold\014page \001 one \177 del'
_lng_put "next with ESC, FF, 0x01 and DEL" "$LNGLANES" "$(_lf_tsv capability "$LNGQ")"$'\n'
_lng_ss "$LNGZ"; LNGRC="$LF_RC"; _lf_run "$LNGD/rf2b" "$LNGZ" "$LNGN" "$FELIX" lane --tsv
_lng_is "lane session start L-RF2: next holding ESC, FF, 0x01 and DEL: session start exits 0, its output still parses, the context holds ? in their places, and felix lane --tsv exits 0 with the bytes unchanged in column 9" \
   "$LNGZE|$LNGT|$LNGRC|$LF_JSON|$(_lng_n "$(_lng_par zero 0 2 14 1/2 'esc ?[1m bold?page ? one ? del' "$LNGCLH")")|$LF_RC|$(_lf_cols "$LNGD/rf2b.out" 1 2 9)" \
   "built|built|0|ok|1|0|zero|$LNGQ"

# ---- L-RF4: a broken pointer never silences a stall ------------------------------------------------------------------------
# LABEL NEXT-READ IN-PARAGRAPH -> session start and felix lane --tsv in the zero checkout, as committed now.
_lng_rf4() {
  _lng_ss "$LNGZ"; LNGRC="$LF_RC"; _lf_run "$LNGD/rf4" "$LNGZ" "$LNGN" "$FELIX" lane --tsv
  _lng_is "lane session start L-RF4: $1: felix lane --tsv reads zero, L 0 of T 2, next $2, and session start shows the paragraph with $3 and the token" \
     "$LNGZE|$LNGT|$LNGRC|$LF_JSON|$LF_RC|$(_lf_cols "$LNGD/rf4.out" 1 2 3 4 9)|$(_lng_n "$(_lng_par zero 0 2 14 1/2 "$3" "$LNGCLH")")|$LF_SCR" \
     "built|built|0|ok|0|zero|0|2|$2|1|$LNGTOK14"
}
_lng_put "no lane-next.tsv" "$LNGLANES" -
_lng_rf4 "no committed lane-next.tsv" none "(lane-next.tsv names none)"
_lng_put "lane-next.tsv with a CR" "$LNGLANES" "$(_lf_tsv capability "$LNGNEXT")"$'\r\n'
_lng_rf4 "a committed lane-next.tsv the shape check refuses, a CR in its row" unknown "(lane-next.tsv cannot be read)"
_lng_put "two next rows" "$LNGLANES" "$LNGNEXTS$(_lf_tsv capability 'a second item')"$'\n'
_lng_rf4 "two committed lane-next.tsv rows for the lane" unknown "(lane-next.tsv cannot be read)"

# ---- no committed lanes.tsv, or none with a row ---------------------------------------------------------------------------------
_lng_absent "no table"
_lng_ss "$LNGZ"
_lng_is "lane session start: with no lanes.tsv committed, session start exits 0 with valid JSON and neither a lane paragraph nor a lane token (control)" \
   "$LNGZE|$LNGT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|0|ok|none"
printf '%s' "$LNGLANES" > "$LNGP/lanes.tsv"; printf '%s' "$LNGNEXTS" > "$LNGP/lane-next.tsv"
_lng_ss "$LNGZ"
_lng_is "lane session start: with both tables in the home's working tree and neither committed, neither a lane paragraph nor a lane token (control)" \
   "$LNGZE|$LNGT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|0|ok|none"
_lng_put "comments and a blank line, no row" $'# No lane is counted yet.\n\n'
_lng_ss "$LNGZ"
_lng_is "lane session start: with a committed lanes.tsv holding no row, neither a lane paragraph nor a lane token (control)" \
   "$LNGZE|$LNGT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|0|ok|none"

# ---- L-RF3's session-start half: a table broken by hand, committed (controls) ----------------------------------------------
# LABEL BYTES [NOW] -> lanes.tsv BYTES committed, then session start in the zero checkout.
_lng_rf3() {
  _lng_put "$1" "$2"
  _lng_ss "$LNGZ" "${3-$LNGN}"
  _lng_is "lane session start L-RF3: $1: session start exits 0 with valid JSON and neither a lane paragraph nor a lane token (control)" \
     "$LNGZE|$LNGT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|0|ok|none"
}
for LNGw in 1/0 3/2 0/2 1/2/3; do _lng_rf3 "share $LNGw" "$(_lf_tsv capability '^engine/' "$LNGw" 14)"$'\n'; done
for LNGw in 0 14d 014; do _lng_rf3 "window $LNGw" "$(_lf_tsv capability '^engine/' 1/2 "$LNGw")"$'\n'; done
_lng_rf3 "counts (" $'capability\t(\t1/2\t14\n'
_lng_rf3 "a lane named on two rows" $'capability\t^engine/\t1/2\t14\ncapability\t^engine/\t1/2\t14\n'
_lng_rf3 "a CR in a row" $'capability\t^engine/\t1/2\t14\r\n'
_lng_rf3 "no final newline" $'capability\t^engine/\t1/2\t14'
_lng_rf3 "an empty cell" $'capability\t\t1/2\t14\n'
_lng_rf3 "a row of three cells" $'capability\t^engine/\t1/2\n'
_lng_rf3 "FELIX_LANE_NOW=0123 over a valid table" "$LNGLANES" 0123

# ---- L-RF5's session-start half: a shallow clone (control) ---------------------------------------------------------------
_lng_put "share 1/2, for the shallow clone, L-RO and the broken engine" "$LNGLANES"
_lng_chk rf5-source u u u; LNGa="not built: the shallow clone"
if [ "$LNGE" = built ] && ( _fx_cd "$LNGD" && _lf_g 1700000000 clone -q --depth 2 "file://$LNGR" rf5 ) >/dev/null 2>&1; then
  { printf 'sx\n' > "$LNGD/rf5/.felix"; } 2>/dev/null
  _lf_own "$LNGP" "$LNGD/rf5" lane-fixture/sx \
    && LNGa="$( _fx_cd "$LNGD/rf5" || exit 1; [ "$(_lf_g 1700000000 rev-parse --is-shallow-repository)" = true ] \
           && _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main >/dev/null && echo built )"
fi
_lng_ss "$LNGD/rf5"
_lng_is "lane session start L-RF5: in a --depth 2 clone holding refs/remotes/origin/main, session start exits 0 with valid JSON and neither a lane paragraph nor a lane token (control)" \
   "${LNGa:-not built: the shallow clone}|$LNGT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|0|ok|none"

# ---- L-RO's session-start half (control) ----------------------------------------------------------------------------------
touch "$LNGP/lanes.tsv"; sleep 1; touch "$LNGD/ro.marker"
_lng_ss "$LNGZ"
LNGa="$(find "$LNGH/.git/index" -newer "$LNGD/ro.marker" 2>&1)"
_lng_is "lane session start L-RO: after a touch of lanes.tsv, its content unchanged, a session start exits 0 with valid JSON and leaves the home's .git/index no newer than a marker touched before it (control)" \
   "$LNGZE|$LNGT|$LF_RC|$LF_JSON|newer[$LNGa]" "built|built|0|ok|newer[]"

# ---- the broken engine (control) -------------------------------------------------------------------------------------------
LNGa="not built: the broken engine"
_lf_broken "$LNGD/broken" && [ -x "$LF_ROOT/harness/hooks/session-start" ] && [ -f "$LF_ROOT/harness/felix" ] \
  && [ ! -e "$LF_ROOT/harness/lib/lane.sh" ] && LNGa=built
_lng_ss "$LNGZ" "$LNGN" startup "$LF_ROOT"
_lng_is "lane session start: an engine copy with lib/lane.sh removed, where the intact engine shows the zero paragraph and token, exits 0 with valid JSON and neither (control)" \
   "$LNGZE|$LNGT|$LNGa|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|built|0|ok|none"

# ---- L-OWN, and C7's nothing-withheld rule: the own checkout, and checkouts that are not own --------------------------------
LNGOTH='https://github.com/lane-fixture/other.git'
# H REL BYTES -> H's HEAD holds projects/sx/REL as exactly BYTES (-: holds no such file); status 0 when so.
_lng_in() {
  if [ "$3" = - ]; then ! ( _fx_cd "$1" && _lf_g 1700000000 cat-file -e "HEAD:projects/sx/$2" ) >/dev/null 2>&1; return; fi
  printf '%s' "$3" > "$LNGD/in.want"
  ( _fx_cd "$1" || exit 1; _lf_g 1700000000 cat-file blob "HEAD:projects/sx/$2" ) > "$LNGD/in.got" 2>/dev/null
  cmp -s "$LNGD/in.want" "$LNGD/in.got"
}
# NAME TABLES MATCH ORIGIN [SPEC...] -> a fresh home $LNGD/own-NAME/home holding sx (its commit at the time H's has), with
# TABLES 1/2 LNGLANES and LNGNEXTS committed at fixed times (- none), then project.json naming remote_match MATCH (- as
# _lf_home wrote it, with none), and the environment naming that home, a memory root and a HOME of its own. A checkout
# $LNGD/own-NAME/c bound to sx, its root a month before the clock, its origin ORIGIN (- none ever added). With SPEC,
# its landings as _lng_chk makes them, published; without, one unmarked engine landing a day before the clock and no
# refs/remotes/origin/main (R1). Sets LNGOH, LNGOR, LNGOS (the home's lanes.tsv commit, - for none, empty when not
# made), LNGOC (the home's HEAD) and LNGOX (refs/remotes/origin/main, - for none); LNGOE "built" when the home's HEAD
# holds what TABLES names, its project.json what MATCH names, and the checkout the origin and the ref named.
_lng_fresh() {
  local n="$1" tb="$2" rm="$3" o="$4" d="$LNGD/own-$1" j u
  shift 4
  LNGOE="not built: $n"; LNGOH=""; LNGOR=""; LNGOS=""; LNGOC=""; LNGOX=""
  mkdir -p "$d" || return 1
  _lf_home "$d/home" sx 1792500000 || return 1
  LNGOH="$LF_HOME"; LNGOS=-
  if [ "$tb" = 1/2 ]; then
    _lf_table "$LF_PROJ" 1792600000 lanes.tsv "$LNGLANES" $'lanes.tsv, share 1/2\n' || return 1
    LNGOS="$LF_SHA"
    _lf_table "$LF_PROJ" 1792600050 lane-next.tsv "$LNGNEXTS" $'lane-next.tsv, the capability item\n' || return 1
  fi
  j='{"name":"sx","gate":"true"}'
  [ "$rm" = - ] || { _lf_match "$LF_PROJ" "$rm" || return 1; j="{\"name\":\"sx\",\"gate\":\"true\",\"remote_match\":\"$rm\"}"; }
  _lf_use "$LNGOH" "$d/memory" "$d/user" "$LNGB"
  _lf_checkout "$d/c" sx $((LNGN - 30 * LNGDAY)) || return 1
  LNGOR="$LF_REPO"
  [ "$o" = - ] || _lf_origin "$LNGOR" "$o" || return 1
  if [ "$#" -gt 0 ]; then _lf_chain "$LNGOR" capability $((LNGN - 5 * LNGDAY)) 3600 "$@" || return 1
  else _lf_commit "$LNGOR" $((LNGN - LNGDAY)) $'engine: x\n' engine/x.sh || return 1; fi
  LNGOC="$( _fx_cd "$LNGOH" || exit 1; _lf_g 1700000000 rev-parse --verify -q HEAD )"
  LNGOX="$( _fx_cd "$LNGOR" || exit 1; _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main || echo - )"
  u="$( _fx_cd "$LNGOR" || exit 1; _lf_g 1700000000 config --get remote.origin.url || echo - )"
  if [ "$tb" = 1/2 ]; then _lng_in "$LNGOH" lanes.tsv "$LNGLANES" && _lng_in "$LNGOH" lane-next.tsv "$LNGNEXTS" || return 1
  else _lng_in "$LNGOH" lanes.tsv - && _lng_in "$LNGOH" lane-next.tsv - || return 1; fi
  [ "$(cat "$LF_PROJ/project.json")" = "$j" ] && [ "$u" = "$o" ] || return 1
  if [ "$#" -gt 0 ]; then [ "$(_lf_spine "$LNGOR" | LC_ALL=C awk '{ print NF }')" = "$(($# + 1))" ] || return 1
  else [ "$LNGOX" = - ] || return 1; fi
  LNGOE=built
}
# -> "named" when a line of the last session's context starts "Nothing ran here unattended: " and names lane item
# among the kinds after its "Withheld: " (split on ", ", the closing full stop dropped), else "unnamed".
_lng_wh() {
  LC_ALL=C awk 'index($0, "Nothing ran here unattended: ") == 1 && (i = index($0, " Withheld: ")) > 0 {
      k = substr($0, i + 11); sub(/\.$/, "", k); n = split(k, a, ", ")
      for (j = 1; j <= n; j++) if (a[j] == "lane item") f = 1 }
    END { print (f ? "named" : "unnamed") }' "$LNGF.ctx" 2>/dev/null
}
# -> session start, then felix lane --tsv, in the checkout _lng_fresh just built: LNGRC (the hook's status), LF_JSON,
# LF_CTX and LF_SCR as _lng_ss leaves them, LNGLR felix lane --tsv's status and LNGLO its stdout, byte for byte.
_lng_osee() {
  _lng_ss "$LNGOR"; LNGRC="$LF_RC"
  _lf_run "$LNGF.lane" "$LNGOR" "$LNGN" "$FELIX" lane --tsv
  LNGLR="$LF_RC"; LNGLO="$(cat "$LNGF.lane.out"; printf x)"; LNGLO="${LNGLO%x}"
}

# L-OWN: the lane zero (two unmarked engine landings), every other input the same, in four checkouts. LNGOA is the own
# home's HEAD and the own checkout's ref, LNGOL the line felix lane --tsv prints there; each other checkout holds the
# same commits and prints the same line. LNGCTL gathers each session start's built, exit status and JSON.
_lng_fresh own 1/2 lane-fixture/sx "$LNGURL" u u
LNGOA="$LNGOC|$LNGOX"
LNGOL="$(_lf_tsv capability zero 0 2 14 1/2 none 'Felix-Lane: capability' "$LNGNEXT" "$LNGOS" "$(_lf_iso 1792600000)" \
  "$(_lf_iso $((LNGN - 5 * LNGDAY + 3600)))" -)"$'\n'
_lng_osee; LNGCTL="$LNGOE|$LNGRC|$LF_JSON"
_lng_is "lane session start L-OWN: in the project's own checkout (remote_match lane-fixture/sx, origin https://github.com/lane-fixture/sx.git), the lane zero: the context holds the zero paragraph once, the screen line ends with · lane: 0 in 14 days, no withheld line names lane item, and felix lane --tsv exits 0 printing the zero line" \
   "$LNGOE|$(_lng_n "$LNGZ12")|$LF_SCR|$(_lng_wh)|$LNGLR|$LNGLO" "built|1|$LNGTOK14|unnamed|0|$LNGOL"
# NAME MATCH ORIGIN WHAT -> L-OWN in a checkout that is not own, as WHAT says.
_lng_notown() {
  _lng_fresh "$1" 1/2 "$2" "$3" u u
  _lng_osee; LNGCTL="$LNGCTL|$LNGOE|$LNGRC|$LF_JSON"
  _lng_is "lane session start L-OWN: in a checkout that is not own ($4), the lane zero and every other input as in the own one: neither a lane paragraph nor a lane token, the withheld line names lane item among its kinds, and felix lane --tsv exits 0 printing the line it prints in the own checkout" \
     "$LNGOE|$LNGOC|$LNGOX|$(_lf_silent capability)|$(_lng_wh)|$LNGLR|$LNGLO" "built|$LNGOA|none|named|0|$LNGOL"
}
_lng_notown nomatch - "$LNGURL" "its project declares no remote_match, its origin the own one's"
_lng_notown other lane-fixture/sx "$LNGOTH" "its origin https://github.com/lane-fixture/other.git, another github.com repository"
_lng_notown noorigin lane-fixture/sx - "no origin remote, refs/remotes/origin/main made by update-ref"
_lng_is "lane session start L-OWN: in the own checkout and in each of the three that are not own, session start exits 0 with valid JSON (control)" \
   "$LNGCTL" "built|0|ok|built|0|ok|built|0|ok|built|0|ok"

# C7: a checkout that is not own withholds nothing for an ok lane, an unknown lane, or a home with no committed
# lanes.tsv. Each in a fresh home, a different way of not being own each.
_lng_fresh wok 1/2 lane-fixture/sx "$LNGOTH" m u
_lng_osee; LNGCTL="$LNGOE|$LNGRC|$LF_JSON"
_lng_is "lane session start: in a checkout that is not own (its origin another github.com repository), the lane ok (L 1 of T 2): neither a lane paragraph nor a lane token, no withheld line names lane item, and felix lane --tsv exits 0 printing the ok line" \
   "$LNGOE|$(_lf_silent capability)|$(_lng_wh)|$LNGLR|$LNGLO" \
   "built|none|unnamed|0|$(_lf_tsv capability ok 1 2 14 1/2 "$(_lf_iso $((LNGN - 5 * LNGDAY)))" 'Felix-Lane: capability' "$LNGNEXT" \
     "$LNGOS" "$(_lf_iso 1792600000)" "$(_lf_iso $((LNGN - 5 * LNGDAY + 3600)))" -)"$'\n'
_lng_fresh wunknown 1/2 - "$LNGURL"
_lng_osee; LNGCTL="$LNGCTL|$LNGOE|$LNGRC|$LF_JSON"
_lng_is "lane session start: in a checkout that is not own (its project declares no remote_match), the lane unknown (no refs/remotes/origin/main): neither a lane paragraph nor a lane token, no withheld line names lane item, and felix lane --tsv exits 0 printing the unknown line, R1" \
   "$LNGOE|$(_lf_silent capability)|$(_lng_wh)|$LNGLR|$LNGLO" \
   "built|none|unnamed|0|$(_lf_tsv capability unknown - - 14 1/2 - 'Felix-Lane: capability' "$LNGNEXT" "$LNGOS" \
     "$(_lf_iso 1792600000)" - "refs/remotes/origin/main cannot be read in $LNGOR")"$'\n'
_lng_fresh wnone - lane-fixture/sx - u u
_lng_osee; LNGCTL="$LNGCTL|$LNGOE|$LNGRC|$LF_JSON"
_lng_is "lane session start: in a checkout that is not own (no origin remote), a home with no committed lanes.tsv: neither a lane paragraph nor a lane token, no withheld line names lane item, and felix lane --tsv exits 0 printing nothing" \
   "$LNGOE|$(_lf_silent capability)|$(_lng_wh)|$LNGLR|$LNGLO" "built|none|unnamed|0|"
_lng_is "lane session start: in those three checkouts that are not own (an ok lane, an unknown lane, no committed lanes.tsv), session start exits 0 with valid JSON (control)" \
   "$LNGCTL" "built|0|ok|built|0|ok|built|0|ok"

# ---- the review's second amendment: next exactly none or unknown (F9), 1 day (F11), a count that ends early (F1) ------
# Added on 2026-10-30, still blind, back in H and its own checkouts (H's project.json still names remote_match
# lane-fixture/sx in its working tree). C1: a next cell that is exactly none or unknown is printed as given in column 9,
# and the paragraph reads it as C7 reads those values.
_lf_use "$LNGH" "$LNGD/memory" "$LNGD/user" "$LNGB"
# WORD IN-PARAGRAPH -> lane-next.tsv holding capability<TAB>WORD committed beside the 1/2 table; then session start and
# felix lane --tsv in the zero checkout.
_lng_f9() {
  _lng_put "next exactly $1" "$LNGLANES" "$(_lf_tsv capability "$1")"$'\n'
  _lng_ss "$LNGZ"; LNGRC="$LF_RC"; _lf_run "$LNGD/f9-$1" "$LNGZ" "$LNGN" "$FELIX" lane --tsv
  _lng_is "lane session start F9-next-text-none-or-unknown-literally: a committed lane-next.tsv whose one row for the lane has next exactly $1, the lane zero: felix lane --tsv prints $1 in column 9 as the cell gives it, and the paragraph reads it as C7 reads $1, $2, with the token" \
     "$LNGZE|$LNGT|$LNGRC|$LF_JSON|$LF_RC|$(_lf_cols "$LNGD/f9-$1.out" 1 1 2 3 4 9)|$(_lng_n "$(_lng_par zero 0 2 14 1/2 "$2" "$LNGCLH")")|$LF_SCR" \
     "built|built|0|ok|0|capability|zero|0|2|$1|1|$LNGTOK14"
}
_lng_f9 unknown "(lane-next.tsv cannot be read)"
_lng_f9 none "(lane-next.tsv names none)"
# F11: a checkout of its own, own, whose one landing, an unmarked engine change, is an hour before the clock, and the
# table's window 1: zero, 0 of 1 in 1 day.
LNGa="not built: the one-day checkout"; LNGDY=""
_lf_checkout "$LNGD/day" sx $((LNGN - 30 * LNGDAY)) && LNGDY="$LF_REPO" && _lf_own "$LNGP" "$LNGDY" lane-fixture/sx \
  && _lf_chain "$LNGDY" capability $((LNGN - 3600)) 60 u && [ "$(cat "$LNGP/project.json")" = "$LNGOWNJ" ] \
  && [ "$(_lf_spine "$LNGDY")" = "$((LNGN - 3600)):1 $((LNGN - 30 * LNGDAY)):0" ] && LNGa=built
_lng_put "window 1" $'capability\t^engine/\t1/2\t1\n'
_lng_ss "${LNGDY:-$LNGD/day}"
_lng_is "lane session start F11-one-day-reads-1-days: zero with window 1 (one unmarked engine landing an hour back): the paragraph says 0 of 1 engine landings in 1 day, never 1 days, and the screen line ends with · lane: 0 in 1 day" \
   "$LNGa|$LNGT|$LF_RC|$LF_JSON|$(_lng_n "Lane capability is zero: 0 of 1 engine landings in 1 day, target 1/2."$'\n'"If the founder has not given this session a task, take the first open lane item: $LNGNEXT. End the body of a commit on its branch that is not a merge with the line \`Felix-Lane: capability\`. $LNGCLH")|$LF_SCR" \
   "built|built|0|ok|1|$LNGSCR · lane: 0 in 1 day"
# F1, last in this part because a run ended early may leave state behind: C9's fault through _lf_fault kill, with TMPDIR
# a directory of the fixture's own, in the zero checkout where the same session start without it shows the zero
# paragraph and token. Whether the count could not finish or a read's own process ended (R2), C7 says nothing of the
# lane: exit 0, valid JSON, neither the paragraph nor the token.
_lng_put "share 1/2, for a count that ends early" "$LNGLANES"
_lng_ss "$LNGZ"; LNGa="$LF_RC|$LF_JSON|$(_lng_n "$LNGZ12")|$LF_SCR"
LNGkt="$LNGD/f1k-tmp"; rm -rf "$LNGkt"; mkdir -p "$LNGkt"
LNGK=$((LNGK + 1)); LNGF="$LNGD/ss-$LNGK"
_lf_fault kill "$LNGF.fired" "$LNGkt" _lf_start "$LNGF" "$LNGZ" "$LNGN" startup
LNGRC="$LF_RC"; _lf_calm "$LNGH"; _lf_json "$LNGF"
_lng_is "lane session start F1-count-ends-early: the parent of the shell that runs the read of the landings, then that shell, killed (C9), in the own zero checkout where the same session start without it shows the paragraph and the token: exit 0, valid JSON, neither a lane paragraph nor a lane token" \
   "$LNGZE|$LNGT|unfaulted $LNGa|$LF_FIRE|$LNGRC|$LF_JSON|$(_lf_silent capability)" "built|built|unfaulted 0|ok|1|$LNGTOK14|fired|0|ok|none"

# ---- the second review's round 1: the clock's read and the next text's read, faulted (R2-F1, R2-F5) -------------------
# Added on 2026-10-30 from the second review's findings (their inputs and observed output only), still blind, in the
# review's home-apart fixture (_lf_r2: project p, its checkout p's own, remote_match o/r), its landings dated from the
# machine clock at build time. Without a fault, session start there shows cap's zero paragraph, sec's short one and the
# token. The faults are the review's fork probes (_lf_fork), by the words and calling functions it names: R2-F1 at the
# count's read of the clock (date -u +%s, _lane_rows on the stack), FELIX_LANE_NOW unset; R2-F5 at the read of cap's
# next text (awk, lane=cap, _lane_next on the stack), the clock at build time. C7 and C3: a count that read no clock
# says nothing of the lane, and a next that could not be read is (lane-next.tsv cannot be read), never - or empty; C3
# makes every next unknown then, so sec's may read it too. Each assertion also compares the start without the fault.
LNGRN="$(date +%s)"; LNGRT="$LNGD/r2-tmp"; mkdir -p "$LNGRT"; LNGRA="not built: the second review's fixture"
_lf_r2 "$LNGD/r2" p "$LNGRN" && LNGRA=built
LNGRR="$LF_REPO"; LNGRH="$LF_HOME"
_lf_use "$LNGRH" "$LNGD/r2/memory" "$LNGD/r2/user" "$LNGB"
LNGRCAP="$(_lng_par zero 0 2 14 1/2 'cap next item' "$LNGCLH" cap)"; LNGRSEC="$(_lng_par short 1 3 7 1/2 'sec next item' "$LNGCLH" sec)"
LNGRTOK='Felix: p · lane: 0 in 14 days'
_lng_ss "$LNGRR" -; LNGa="$LF_RC|$LF_JSON|$(_lng_n "$LNGRCAP")|$(_lng_n "$LNGRSEC")|$LF_SCR"
LNGK=$((LNGK + 1)); LNGF="$LNGD/ss-$LNGK"
_lf_fork fork date "' -u +%s '" "*' _lane_rows '*" "$LNGF.fired" "$LNGRT" _lf_start "$LNGF" "$LNGRR" - startup
LNGb="$LF_RC"; _lf_calm "$LNGRH"; _lf_json "$LNGF"
_lng_is "lane session start R2-F1-clock-fork-reads-idle: with FELIX_LANE_NOW unset, a fork that fails in the count's read of the machine clock (date -u +%s), in the own checkout where the same session start without it shows cap's zero paragraph, sec's short one and the token: exit 0, valid JSON, neither a lane paragraph nor a lane token, never an idle paragraph" \
   "$LNGRA|unfaulted $LNGa|$LF_FIRE|$LNGb|$LF_JSON|$(_lf_silent cap)" "built|unfaulted 0|ok|1|1|$LNGRTOK|fired|0|ok|none"
_lng_ss "$LNGRR" "$LNGRN"; LNGa="$LF_RC|$LF_JSON|$(_lng_n "$LNGRCAP")|$(_lng_n "$LNGRSEC")|$LF_SCR"
LNGK=$((LNGK + 1)); LNGF="$LNGD/ss-$LNGK"
_lf_fork fork awk '*lane=cap*' "*' _lane_next '*" "$LNGF.fired" "$LNGRT" _lf_start "$LNGF" "$LNGRR" "$LNGRN" startup
LNGb="$LF_RC"; _lf_calm "$LNGRH"; _lf_json "$LNGF"
LNGc="$(_lng_n "$LNGRCAP")+$(_lng_n "$(_lng_par zero 0 2 14 1/2 '(lane-next.tsv cannot be read)' "$LNGCLH" cap)")"
LNGc="$LNGc|$(_lng_n "$LNGRSEC")+$(_lng_n "$(_lng_par short 1 3 7 1/2 '(lane-next.tsv cannot be read)' "$LNGCLH" sec)")"
case "$LNGc" in ("1+0|1+0"|"1+0|0+1"|"0+1|1+0"|"0+1|0+1") LNGc="text or cannot be read" ;; (*) LNGc="$LNGc, context [$LF_CTX]" ;; esac
_lng_is "lane session start R2-F5-next-cell-empties-and-shifts-columns: a fork that fails in the read of cap's next text, in the own checkout where without it session start shows both paragraphs and the token: exit 0, valid JSON, cap's zero paragraph once with cap next item or (lane-next.tsv cannot be read), never - or empty, sec's short one the same way, and the token" \
   "$LNGRA|unfaulted $LNGa|$LF_FIRE|$LNGb|$LF_JSON|$LNGc|$LF_SCR" "built|unfaulted 0|ok|1|1|$LNGRTOK|fired|0|ok|text or cannot be read|$LNGRTOK"
_lf_use "$LNGH" "$LNGD/memory" "$LNGD/user" "$LNGB"

# ---- the second review's round 2: a next row for a lane lanes.tsv does not hold (R2B-F4) ---------------------------------
# Added on 2026-10-30 from the second review's round 2 findings (their inputs and observed output only), still blind,
# back in H and its own zero checkout (H's project.json still names remote_match lane-fixture/sx in its working tree):
# lanes.tsv holds lane 1 alone (^engine/, 1/2, 14), and lane-next.tsv a row for lane 01 alone, a lane lanes.tsv does not
# hold, which C1 ignores. So lane 1 reads zero 0 of 2 and next none, and its paragraph says (lane-next.tsv names none)
# (C7), never (lane-next.tsv cannot be read), with the token.
_lng_put "lane 1, and a next row for 01 alone" $'1\t^engine/\t1/2\t14\n' "$(_lf_tsv 01 'second item')"$'\n'
_lng_ss "$LNGZ"; LNGRC="$LF_RC"; _lf_run "$LNGD/r2bf4" "$LNGZ" "$LNGN" "$FELIX" lane --tsv
_lng_is "lane session start R2B-F4-numeric-lane-names-collide: lanes.tsv holding lane 1 alone and lane-next.tsv a row for lane 01 alone, in the own zero checkout: felix lane --tsv reads 1 zero 0 2 with next none, and session start shows lane 1's zero paragraph once with (lane-next.tsv names none), never (lane-next.tsv cannot be read), and the token" \
   "$LNGZE|$LNGT|$LNGRC|$LF_JSON|$LF_RC|$(_lf_cols "$LNGD/r2bf4.out" 1 1 2 3 4 9)|$(_lng_n "$(_lng_par zero 0 2 14 1/2 '(lane-next.tsv names none)' "$LNGCLH" 1)")|$(_lng_n "$(_lng_par zero 0 2 14 1/2 '(lane-next.tsv cannot be read)' "$LNGCLH" 1)")|$LF_SCR" \
   "built|built|0|ok|0|1|zero|0|2|none|1|0|$LNGTOK14"

# ---- the second review's round 3: an open-file limit that drops the marks (R3-F1) -----------------------------------
# Added on 2026-10-30 from the second review's round 3 findings (their inputs and observed output only), still blind. The
# review's fixture (_lf_r3, built here from the machine clock, FELIX_LANE_NOW unset): lanes.tsv holds sec before cap and
# the checkout is p's own, so without the fault session start shows sec's short paragraph and cap's zero one, each once,
# and no token, the first lane being short. The fault is the finding's: a soft open-file limit N, for each N from 10 to
# 24, set in the shell that execs the hook (_lf_lroot's stand-in root, that shell first closing the descriptors from 3 up
# it inherited), with TMPDIR a directory of the fixture's own; no other fault. Readings (C3, C7): a read that did not
# finish never yields a count, and a lane whose count is unknown or did not finish gets nothing said. So at every N,
# whatever else the hook printed or could not print (at the lowest limits it cannot load its libraries), the only lane
# sentences in its output (Lane <lane> is <state>: <L> of <T> engine landings in <W> days, target <n>/<d>.) are sec's
# short one and cap's zero one, each at most once, and no lane token shows; never Lane sec is zero, or · lane: 0 in 7
# days on the screen line of a short lane.
LNGN3="$(date +%s)"; LNGN3T="$LNGD/r3-tmp"; LNGN3A="not built: R3-F1's fixture"; LNGN3C="$LNGD/r3/c"
_lf_r3 "$LNGD/r3" p "$LNGN3" && LNGN3A=built && LNGN3C="$LF_REPO"
_lf_use "$LNGD/r3/home" "$LNGD/r3-memory" "$LNGD/r3-user" "$LNGB"
LNGN3S='Lane sec is short: 1 of 3 engine landings in 7 days, target 1/2.'; LNGN3Z='Lane cap is zero: 0 of 2 engine landings in 14 days, target 1/2.'
_lng_ss "$LNGN3C" -
LNGa="$LF_RC|$LF_JSON|$(_lng_n "$(_lng_par short 1 3 7 1/2 'sec next item' "$LNGCLH" sec)")|$(_lng_n "$(_lng_par zero 0 2 14 1/2 'cap next item' "$LNGCLH" cap)")|$LF_SCR"
# OUT -> "unfaulted or silent" when the session start whose stdout is OUT.out holds, in its context and screen line (or
# in its bytes, when they are not a JSON object), no lane sentence but sec's short one and cap's zero one, each at most
# once, and no lane token; else the sentences and tokens it holds beyond those.
_lng_r3() {
  python3 -c 'import json, re, sys
raw = open(sys.argv[1], "rb").read().decode("utf-8", "surrogateescape")
try:
    d = json.loads(raw)
    t = ((d.get("hookSpecificOutput") or {}).get("additionalContext") or "") + "\n" + (d.get("systemMessage") or "")
except Exception:
    t = raw
s = re.findall(r"Lane \S+ is \S+: \d+ of \d+ engine landings in \d+ days?, target \d+/\d+\.", t)
b = [x for x in s if x not in sys.argv[2:4] or s.count(x) > 1] + re.findall(r"lane: \d+ in \d+ days?", t)
sys.stdout.write("[" + "; ".join(sorted(set(b))) + "]" if b else "unfaulted or silent")' "$1.out" "$LNGN3S" "$LNGN3Z" 2>/dev/null || printf 'unread'
}
LNGa3=""; LNGl=""
for LNGm in 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24; do
  rm -rf "$LNGN3T"; mkdir -p "$LNGN3T"
  _lf_lroot "$LNGD/r3-root-$LNGm" "$LNGm" "$LNGN3T"
  LNGK=$((LNGK + 1)); LNGF="$LNGD/ss-$LNGK"
  _lf_start "$LNGF" "$LNGN3C" - startup "${LF_LROOT:-$LNGD/r3-root-$LNGm}"
  [ "$(LC_ALL=C awk 'NR == 1' "$LNGF.err")" = "limit $LNGm" ] || LNGl="$LNGl $LNGm"
  LNGx="$(_lng_r3 "$LNGF")"; [ "$LNGx" = 'unfaulted or silent' ] || LNGa3="$LNGa3 [N=$LNGm: $LNGx]"
done
if [ -z "$LNGl" ]; then LNGl="the limit set at every N"; else LNGl="the limit not set at$LNGl"; fi
_lng_is "lane session start R3-F1-open-file-limit-drops-marks: with FELIX_LANE_NOW unset and a soft open-file limit N from 10 to 24 set in the shell that execs the hook, in the own checkout where without it session start shows sec's short paragraph and cap's zero one and no token: at every N its only lane sentences are those two, each at most once, and no lane token shows; never Lane sec is zero, and never · lane: 0 in 7 days" \
   "$LNGN3A|unfaulted $LNGa|$LNGl|${LNGa3:- unfaulted or silent at every N}" "built|unfaulted 0|ok|1|1|Felix: p|the limit set at every N| unfaulted or silent at every N"
_lf_use "$LNGH" "$LNGD/memory" "$LNGD/user" "$LNGB"
# <<< lane-session-start
