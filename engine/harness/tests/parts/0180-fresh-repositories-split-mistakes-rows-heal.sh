printf '\nfresh repositories: split mistakes rows heal, the project gate keeps its own failure, setup waits for a remote\n'
# A sweep of what a freshly created repository goes through on its first day
# found four defects that each kept `felix commission` from ever reading clean
# there, whatever the person did. They share this section because they share a
# fixture shape: a project bound by marker to a throwaway checkout, driven
# through the real CLI and the real hook, with memory seeded by hand wherever
# the defect is in what an older engine left on disk.
#
# Every block below builds a project of its own, so the widget, cmproj and
# unbornproj fixtures are read exactly as the sections around this one left
# them. An assertion that pins something which must NOT change first checks
# that the fixture really had the shape that would change it, or it would pass
# by finding nothing.
#
# Discovery's background refresh would start from the session-start calls here
# and reach for the network. Holding its lock for the section keeps the hook
# offline, and only a lock this section took is let go at the end.
_cmstub_build
_fresh_repos_lock
_fh_today="$(date +%Y-%m-%d)"

# What an engine before #267 wrote for one gate failure on an unborn HEAD:
# `rev-parse --abbrev-ref HEAD` printed HEAD and exited 128, so the `|| echo ?`
# fallback appended rather than replaced, and the row became two lines. Line A
# has two fields; line B has three, and column four is on neither.
_fh_legacy()  { printf '%s\tHEAD\n?\t?\t%s\n' "$1" "$2"; }
_fh_pairs()   { LC_ALL=C awk -F'\t' 'p && NF == 3 && $1 == "?" && $2 == "?" { n++ } { p = (NF == 2 && $2 == "HEAD") } END { print n + 0 }' "$1" 2>/dev/null; }
# The heal's temporaries and its lock, by the names the contract gives them.
_fh_left()    { ls -A "$1" 2>/dev/null | grep -E '^\.mistakes\.(lock|log\.(heal|orig)\..*)$' | tr '\n' ' '; }
_fh_same_mtime() { [ -e "$1" ] && [ -e "$2" ] && [ -z "$(find "$1" -newer "$2" 2>/dev/null)" ] && [ -z "$(find "$2" -newer "$1" 2>/dev/null)" ]; }
_fh_recur() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/memory.sh"; felix_mem_recurring_mistakes "$@" ) 2>/dev/null; }
_fh_items() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
                . "$FROOT/harness/lib/procedures.sh"; felix_procedures_items "$1" ) 2>/dev/null; }
_fh_guard() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/guard.sh"; felix_guard_unrecorded "$1" ) 2>/dev/null; }
_fh_mon()   { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/monitor.sh"; _felix_mon_project "$1" "$FROOT" ) 2>/dev/null; }
_fh_montotal() { printf '%s' "$1" | tr ',' '\n' | sed -n 's/.*"mistakesTotal":\([0-9]*\).*/\1/p' | head -n 1; }
_fh_monfirst() { printf '%s' "$1" | sed -n 's/.*"mistakes":\[\({[^}]*}\).*/\1/p' | head -n 1; }

# The reader the split row was lost on, copied verbatim from the template's
# gate_shown_failing row. templates/commissioning.tsv is an escape table, so
# this check cannot learn the split shape; the file has to be healed under it.
_fh_gsf_chk_load
has "the gate_shown_failing check is read verbatim from the template, and it reads column four" \
    "$_fh_gsf_chk" 'cut -f4 "$FELIX_MEMORY_DIR/mistakes.log"'

# ------------------------------------------------ the heal and its readers ----
# #267 fixed the writer, and every row written since is four fields. It did not
# touch what was already on disk: an install whose gate failed on an unborn HEAD
# before #267 keeps a two-line row that gate_shown_failing cannot read, so that
# row stays held however many times the person has watched the gate go red.
# The heal joins such a pair into the row #267 would have written, in place,
# and never touches anything else.
_fh_proj healproj true
_fh_r="$(_fh_root healproj)"; _fh_l="$MEM/healproj/mistakes.log"
printf '2026-09-01\tHEAD\tunborn\tlint \n' > "$TMP/fh-one.expect"
_fh_legacy 2026-09-01 'lint ' > "$_fh_l"
is "the fixture writes the legacy split shape: a two-field HEAD line, then a three-field ?-? line" \
   "$(awk -F'\t' '{ printf "%s ", NF }' "$_fh_l")pairs=$(_fh_pairs "$_fh_l")" "2 3 pairs=1"
_fh_gsf "$MEM/healproj" \
  && bad "before any heal, gate_shown_failing cannot see the failure the split rows hold" "it read done on the split file, so a heal proves nothing below" \
  || ok  "before any heal, gate_shown_failing cannot see the failure the split rows hold"
( cd "$_fh_r" && "$FELIX" gate >/dev/null 2>&1 ); _fh_rc=$?
is "a passing gate over a split row still exits 0" "$_fh_rc" "0"
_fh_healed=0; cmp -s "$_fh_l" "$TMP/fh-one.expect" && _fh_healed=1
[ "$_fh_healed" -eq 1 ] \
  && ok  "and the pair becomes one row, byte for byte: the date, HEAD, unborn, and the checks with their trailing space" \
  || bad "and the pair becomes one row, byte for byte: the date, HEAD, unborn, and the checks with their trailing space" "$(od -c "$_fh_l" | head -n 3)"
is "a healed pair is one line"                     "$(grep -c '' "$_fh_l")" "1"
is "and a healed pair has four tab-separated fields" "$(awk -F'\t' '{ print NF }' "$_fh_l" | sort -u | tr '\n' ' ')" "4 "
_fh_gsf "$MEM/healproj" \
  && ok  "so gate_shown_failing reads done after the heal, with no second failing gate" \
  || bad "so gate_shown_failing reads done after the heal, with no second failing gate" "$(cut -f4 "$_fh_l" | od -c | head -n 2)"

# Idempotent. Both mtimes are set to 2020 first, so a rewrite that restored
# nothing would show.
cp "$_fh_l" "$TMP/fh-once.copy"; touch -t 202001010000 "$_fh_l" "$TMP/fh-once.ref"
( cd "$_fh_r" && "$FELIX" gate >/dev/null 2>&1 )
if [ "$_fh_healed" -ne 1 ]; then
  bad "a healed file gated again is left alone: the same bytes and the same mtime" \
      "the first gate did not heal the file, so a second one that leaves it alone proves nothing"
elif cmp -s "$_fh_l" "$TMP/fh-once.copy" && _fh_same_mtime "$_fh_l" "$TMP/fh-once.ref"; then
  ok  "a healed file gated again is left alone: the same bytes and the same mtime"
else
  bad "a healed file gated again is left alone: the same bytes and the same mtime" "$(ls -l "$_fh_l"; od -c "$_fh_l" | head -n 3)"
fi

# Every row keeps its place. Line 1 ends without a trailing space and line 5
# with one, so a heal that re-wrote rows rather than copying them would show.
{ printf '2026-09-01\tmain\tabc1234\tlint\n'; _fh_legacy 2026-09-02 'lint '
  printf '2026-09-03\tmain\tdef5678\texit-2\n'; _fh_legacy 2026-09-04 'exit-1'
  printf '2026-09-05\tmain\t0a0a0a0\tprobes \n'; } > "$_fh_l"
( cd "$_fh_r" && "$FELIX" gate >/dev/null 2>&1 )
is "a mixed file of seven lines holding two pairs heals to five" "$(grep -c '' "$_fh_l")" "5"
is "and its well-formed rows keep their bytes and their places: lines 1, 3 and 5" \
   "$(sed -n '1p;3p;5p' "$_fh_l")" \
   "$(printf '2026-09-01\tmain\tabc1234\tlint\n2026-09-03\tmain\tdef5678\texit-2\n2026-09-05\tmain\t0a0a0a0\tprobes ')"
is "and each pair is joined where it stood: lines 2 and 4" \
   "$(sed -n '2p;4p' "$_fh_l")" \
   "$(printf '2026-09-02\tHEAD\tunborn\tlint \n2026-09-04\tHEAD\tunborn\texit-1')"

# Only a real pair is joined. A HEAD line followed by anything but the ?-? line,
# a ?-? line with no HEAD line before it, a ?-? line of four fields, a HEAD line
# whose first field is not a date, and a HEAD line with nothing after it are all
# left exactly where they are.
{ printf '2026-09-01\tHEAD\n2026-09-01\tmain\tabc\tx\n'
  printf '?\t?\torphan\n'
  printf '2026-09-02\tHEAD\n?\t?\ta\tb\n'
  printf 'yesterday\tHEAD\n?\t?\ty\n'
  _fh_legacy 2026-09-03 'lint '
  printf '2026-09-04\tHEAD\n'; } > "$_fh_l"
cp "$_fh_l" "$TMP/fh-frag.seed"
( cd "$_fh_r" && "$FELIX" gate >/dev/null 2>&1 )
is "fragments that cannot pair keep their bytes and their places" \
   "$(head -n 7 "$_fh_l")" "$(head -n 7 "$TMP/fh-frag.seed")"
is "and a HEAD line left last, with nothing to pair with, keeps its bytes" \
   "$(tail -n 1 "$_fh_l")" "$(printf '2026-09-04\tHEAD')"
is "while the one real pair among them is joined in place, one line shorter" \
   "$(grep -c '' "$_fh_l") $(sed -n 8p "$_fh_l")" "9 $(printf '2026-09-03\tHEAD\tunborn\tlint ')"

# The mode is kept: a heal builds its replacement beside the log and renames it
# over, and a new file would otherwise take the umask.
_fh_legacy 2026-09-01 'lint ' > "$_fh_l"; chmod 600 "$_fh_l"
_fh_mode0="$(ls -l "$_fh_l" | cut -c1-10)"
( cd "$_fh_r" && "$FELIX" gate >/dev/null 2>&1 )
_fh_mode="$(ls -l "$_fh_l" | cut -c1-10)"
if [ "$_fh_mode0" != "-rw-------" ]; then
  bad "a heal keeps the log's mode: a 600 log is healed and is still 600" "the fixture could not make the log 600 ($_fh_mode0)"
elif ! cmp -s "$_fh_l" "$TMP/fh-one.expect"; then
  bad "a heal keeps the log's mode: a 600 log is healed and is still 600" "the file was not healed, so its mode proves nothing"
elif [ "$_fh_mode" = "-rw-------" ]; then
  ok  "a heal keeps the log's mode: a 600 log is healed and is still 600"
else
  bad "a heal keeps the log's mode: a 600 log is healed and is still 600" "mode is now $_fh_mode"
fi
chmod 644 "$_fh_l"

# A log whose last line has no newline is either being written or was edited
# by hand, and either way the heal declines. Readers still read it joined.
{ _fh_legacy 2026-09-01 'lint '; printf '2026-09-02\tmain\tabc\tlint'; } > "$_fh_l"
cp "$_fh_l" "$TMP/fh-nonl.seed"
( cd "$_fh_r" && "$FELIX" gate >/dev/null 2>&1 )
if [ "$(tail -c 1 "$TMP/fh-nonl.seed" | od -An -tx1 | tr -d ' \n')" = "0a" ] || [ "$(_fh_pairs "$TMP/fh-nonl.seed")" != "1" ]; then
  bad "a log whose last line has no newline is left byte for byte, pair and all" "the fixture did not seed a pair and an unterminated last line"
elif cmp -s "$_fh_l" "$TMP/fh-nonl.seed"; then
  ok  "a log whose last line has no newline is left byte for byte, pair and all"
else
  bad "a log whose last line has no newline is left byte for byte, pair and all" "$(od -c "$_fh_l" | head -n 4)"
fi

# A well-formed log is the case on every install, every session: it must come
# through a gate and a session start with its bytes and its mtime, and with no
# lock or temporary left beside it.
_fh_proj healhook true
_fh_kr="$(_fh_root healhook)"; _fh_kl="$MEM/healhook/mistakes.log"
printf '2026-09-01\tmain\tunborn\tlint \n2026-09-02\tmain\tabc1234\tlint \n' > "$_fh_kl"
touch -t 202001010000 "$_fh_kl" "$TMP/fh-keep.ref"; cp -p "$_fh_kl" "$TMP/fh-keep.copy"
( cd "$_fh_kr" && "$FELIX" gate >/dev/null 2>&1 ); _fh_rc=$?
( cd "$_fh_kr" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" ) >/dev/null 2>&1
if [ "$_fh_rc" -ne 0 ] || [ "$(_fh_pairs "$TMP/fh-keep.copy")" != "0" ]; then
  bad "a well-formed log is byte for byte what it was after a gate and a session start" "the fixture's gate exited $_fh_rc, or the log was not well-formed"
elif cmp -s "$_fh_kl" "$TMP/fh-keep.copy"; then
  ok  "a well-formed log is byte for byte what it was after a gate and a session start"
else
  bad "a well-formed log is byte for byte what it was after a gate and a session start" "$(od -c "$_fh_kl" | head -n 4)"
fi
_fh_same_mtime "$_fh_kl" "$TMP/fh-keep.ref" \
  && ok  "and keeps its mtime" \
  || bad "and keeps its mtime" "$(ls -l "$_fh_kl" "$TMP/fh-keep.ref")"
is "and nothing of a heal is left in its memory directory" "$(_fh_left "$MEM/healhook")" ""

# session-start is the entry point that runs on every install, whatever the
# gate did last. It must heal silently: any byte it adds to its own output
# corrupts the JSON Claude Code reads.
_fh_legacy 2026-09-01 'lint ' > "$_fh_kl"
_fh_ss="$(cd "$_fh_kr" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>"$TMP/fh-ss.err")"
cmp -s "$_fh_kl" "$TMP/fh-one.expect" \
  && ok  "a session start heals a split row" \
  || bad "a session start heals a split row" "$(od -c "$_fh_kl" | head -n 3)"
_fh_js="$(printf '%s' "$_fh_ss" | python3 -c 'import json,sys; print("hookSpecificOutput" in json.load(sys.stdin))' 2>/dev/null)"
if [ "${_fh_ss:0:1}" = "{" ] && [ "$_fh_js" = "True" ] && [ ! -s "$TMP/fh-ss.err" ]; then
  ok  "and its output is still one JSON object carrying hookSpecificOutput, with nothing on stderr"
else
  bad "and its output is still one JSON object carrying hookSpecificOutput, with nothing on stderr" \
      "stdout begins [${_fh_ss:0:40}] json=[$_fh_js] stderr=[$(head -c 200 "$TMP/fh-ss.err")]"
fi

# The mtime is kept, because felix_guard_unrecorded compares it with the
# lessons and the devlog. A heal that bumped it would make the Stop hook say the
# gate caught something nobody wrote down, in a session where nothing failed.
_fh_proj healtime true
_fh_tr="$(_fh_root healtime)"; _fh_tl="$MEM/healtime/mistakes.log"
_fh_legacy "$_fh_today" 'lint ' > "$_fh_tl"
printf '%s\tHEAD\tunborn\tlint \n' "$_fh_today" > "$TMP/fh-time.expect"
touch -t 202001010000 "$_fh_tl" "$TMP/fh-time.ref"
_fh_yday="$(date -v-1d +%Y%m%d%H%M 2>/dev/null || date -d '1 day ago' +%Y%m%d%H%M)"
: > "$MEM/healtime/lessons.md"; touch -t "$_fh_yday" "$MEM/healtime/lessons.md"
( cd "$_fh_tr" && "$FELIX" gate >/dev/null 2>&1 )
_fh_th=0; cmp -s "$_fh_tl" "$TMP/fh-time.expect" && _fh_th=1
[ "$_fh_th" -eq 1 ] \
  && ok  "a split row dated today is healed" \
  || bad "a split row dated today is healed" "$(od -c "$_fh_tl" | head -n 3)"
if [ "$_fh_th" -ne 1 ]; then
  bad "and the heal keeps the log's mtime" "no heal ran, so an unchanged mtime proves nothing"
  bad "so the Stop hook's guard stays quiet: the healed log is not newer than the last lesson" "no heal ran, so a quiet guard proves nothing"
else
  _fh_same_mtime "$_fh_tl" "$TMP/fh-time.ref" \
    && ok  "and the heal keeps the log's mtime" \
    || bad "and the heal keeps the log's mtime" "$(ls -l "$_fh_tl" "$TMP/fh-time.ref")"
  _fh_gu="$(_fh_guard "$FROOT/projects/healtime")"
  is "so the Stop hook's guard stays quiet: the healed log is not newer than the last lesson" "${#_fh_gu}" "0"
fi

# A writer that takes no lock (an older engine in a session that has not
# restarted, or a person's >>) can append between the heal's snapshot and its
# rename. The stub `mv` lands exactly there: it appends to the log it is about
# to replace, then does the rename. The heal must find that row on the inode it
# pinned and carry it over.
_fh_proj healrace true
_fh_rr="$(_fh_root healrace)"; _fh_rl="$MEM/healrace/mistakes.log"
{ _fh_legacy 2026-09-01 'lint '; printf '2026-09-02\tmain\tabc1234\tlint \n'; } > "$_fh_rl"
mkdir -p "$TMP/fh-mvstub"
cat > "$TMP/fh-mvstub/mv" <<'STUB'
#!/usr/bin/env bash
for _last in "$@"; do :; done
case "$_last" in
  */mistakes.log) printf '2026-09-09\tmain\tabc1234\tconcurrent\n' >> "$_last" ;;
esac
exec /bin/mv "$@"
STUB
chmod +x "$TMP/fh-mvstub/mv"
( cd "$_fh_rr" && PATH="$TMP/fh-mvstub:$PATH" "$FELIX" gate >/dev/null 2>&1 )
_fh_rh=0
[ "$(sed -n '1p;2p' "$_fh_rl")" = "$(printf '2026-09-01\tHEAD\tunborn\tlint \n2026-09-02\tmain\tabc1234\tlint ')" ] && _fh_rh=1
[ "$_fh_rh" -eq 1 ] \
  && ok  "a heal raced by an unlocked append keeps its own rows first: the joined pair, then the row that was there" \
  || bad "a heal raced by an unlocked append keeps its own rows first: the joined pair, then the row that was there" "$(cat "$_fh_rl")"
is "and the row appended mid-heal survives exactly once, as the last of three lines" \
   "$(grep -c 'concurrent' "$_fh_rl")|$(tail -n 1 "$_fh_rl")|$(grep -c '' "$_fh_rl")" \
   "1|$(printf '2026-09-09\tmain\tabc1234\tconcurrent')|3"
if [ "$_fh_rh" -eq 1 ]; then
  is "and the raced heal leaves no temporary, link or lock behind" "$(_fh_left "$MEM/healrace")" ""
else
  bad "and the raced heal leaves no temporary, link or lock behind" "no heal ran, so an empty directory proves nothing"
fi

# The lock. Tests create it by hand to simulate a holder, so its name and its
# pid file are part of the contract: <memory>/.mistakes.lock/pid.
_fh_proj heallock true
_fh_cr="$(_fh_root heallock)"; _fh_cm="$MEM/heallock"; _fh_cl="$_fh_cm/mistakes.log"; _fh_ck="$_fh_cm/.mistakes.lock"
_fh_script heallock 'echo "  lint               FAIL"; exit 1'
sleep 600 & _fh_sp=$!
mkdir "$_fh_ck"; printf '%s\n' "$_fh_sp" > "$_fh_ck/pid"
_fh_legacy 2026-09-01 'lint ' > "$_fh_cl"; cp "$_fh_cl" "$TMP/fh-lock.seed"
( cd "$_fh_cr" && "$FELIX" gate >/dev/null 2>&1 )
if [ "$_fh_healed" -ne 1 ]; then
  bad "a live owner's lock stops the heal: the split file is left as it was" \
      "the heal never ran on a passing gate above, so a file left alone here proves nothing"
else
  cmp -s "$_fh_cl" "$TMP/fh-lock.seed" \
    && ok  "a live owner's lock stops the heal: the split file is left as it was" \
    || bad "a live owner's lock stops the heal: the split file is left as it was" "$(cat "$_fh_cl")"
fi
# A row is never lost to a lock: the writer waits a bounded time and then
# appends anyway. The deadline is a minute rather than the few seconds the
# wait costs, because this machine's load has turned wall-clock bounds red
# before, and what is asserted is that the wait ends, not how fast.
touch "$_fh_ck"; _fh_setgate heallock gate.sh
_fh_n0="$(grep -c '' "$_fh_cl")"
( cd "$_fh_cr" && "$FELIX" gate >/dev/null 2>&1 ) & _fh_gp=$!
_fh_w=0; while kill -0 "$_fh_gp" 2>/dev/null && [ "$_fh_w" -lt 60 ]; do sleep 1; _fh_w=$((_fh_w + 1)); done
if kill -0 "$_fh_gp" 2>/dev/null; then
  kill "$_fh_gp" 2>/dev/null; wait "$_fh_gp" 2>/dev/null; _fh_grc=timeout
else
  wait "$_fh_gp"; _fh_grc=$?
fi
is "a failing gate under a live lock still appends its row and exits 1, without waiting on the lock for good" \
   "$_fh_grc|$(( $(grep -c '' "$_fh_cl") - _fh_n0 ))|$(tail -n 1 "$_fh_cl" | cut -f4)" "1|1|lint "
_fh_setgate heallock true
# The owner gone, its lock is stale and is taken over.
kill "$_fh_sp" 2>/dev/null; wait "$_fh_sp" 2>/dev/null; _fh_sp=""
sh -c 'exit 0' & _fh_dp=$!; wait "$_fh_dp"
printf '%s\n' "$_fh_dp" > "$_fh_ck/pid"
( cd "$_fh_cr" && "$FELIX" gate >/dev/null 2>&1 )
is "a lock whose owner has exited is taken over, and the pair joined" \
   "$(grep -c '' "$_fh_cl")|$(head -n 1 "$_fh_cl")" "2|$(printf '2026-09-01\tHEAD\tunborn\tlint ')"
[ -d "$_fh_ck" ] \
  && bad "and the heal that took it over leaves no lock behind" "$(ls -la "$_fh_ck")" \
  || ok  "and the heal that took it over leaves no lock behind"
# A holder that died between mkdir and writing its pid leaves a lock with no
# pid. Younger than a minute it is live; older, it is taken over.
rm -rf "$_fh_ck"; mkdir "$_fh_ck"; touch -t 202001010000 "$_fh_ck"
_fh_legacy 2026-09-01 'lint ' > "$_fh_cl"
if [ -z "$(find "$_fh_ck" -maxdepth 0 -mmin +1 2>/dev/null)" ]; then
  bad "a lock with no pid, over a minute old, is taken over: the file is healed and the lock gone" "the fixture could not age the lock directory"
else
  ( cd "$_fh_cr" && "$FELIX" gate >/dev/null 2>&1 )
  if cmp -s "$_fh_cl" "$TMP/fh-one.expect" && [ ! -d "$_fh_ck" ]; then
    ok  "a lock with no pid, over a minute old, is taken over: the file is healed and the lock gone"
  else
    bad "a lock with no pid, over a minute old, is taken over: the file is healed and the lock gone" \
        "lock=$([ -d "$_fh_ck" ] && echo held || echo gone) $(od -c "$_fh_cl" | head -n 2)"
  fi
fi
# Leftovers of a heal killed part way are the engine's own temporaries, never
# memory, and the next heal clears the ones over a minute old. A young one may
# belong to a heal still running, and stays.
rm -rf "$_fh_ck"
_fh_legacy 2026-09-01 'lint ' > "$_fh_cl"
: > "$_fh_cm/.mistakes.log.heal.12345"; : > "$_fh_cm/.mistakes.log.orig.12345"
touch -t 202001010000 "$_fh_cm/.mistakes.log.heal.12345" "$_fh_cm/.mistakes.log.orig.12345"
: > "$_fh_cm/.mistakes.log.heal.99999"
( cd "$_fh_cr" && "$FELIX" gate >/dev/null 2>&1 )
_fh_gone=0
[ ! -e "$_fh_cm/.mistakes.log.heal.12345" ] && [ ! -e "$_fh_cm/.mistakes.log.orig.12345" ] && _fh_gone=1
[ "$_fh_gone" -eq 1 ] \
  && ok  "a heal clears the leftovers of one killed part way, once they are over a minute old" \
  || bad "a heal clears the leftovers of one killed part way, once they are over a minute old" "$(ls -A "$_fh_cm" | tr '\n' ' ')"
if [ "$_fh_gone" -ne 1 ]; then
  bad "but leaves a temporary younger than a minute to whoever owns it" "the old leftovers were not cleared, so a young one surviving proves nothing"
else
  [ -e "$_fh_cm/.mistakes.log.heal.99999" ] \
    && ok  "but leaves a temporary younger than a minute to whoever owns it" \
    || bad "but leaves a temporary younger than a minute to whoever owns it"
fi
rm -f "$_fh_cm/.mistakes.log.heal.99999"

# Two gates at once, each failing, each healing: the lock orders them, so the
# two pairs are joined once and both new rows land.
_fh_proj healproj2 gate.sh
_fh_script healproj2 'echo "  lint               FAIL"; exit 1'
_fh_2a="$(_fh_root healproj2)"; _fh_2b="$TMP/fr-healproj2-b"; mkdir -p "$_fh_2b"
( _fx_cd "$_fh_2b" && git init -q -b main && printf 'healproj2\n' > .felix && printf 'y\n' > README.md \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
_fh_2b="$(cd "$_fh_2b" && pwd -P)"; _fh_2l="$MEM/healproj2/mistakes.log"
{ _fh_legacy 2026-09-01 'x '; _fh_legacy 2026-09-02 'y '; } > "$_fh_2l"
( cd "$_fh_2a" && "$FELIX" gate >/dev/null 2>&1 ) & _fh_2pa=$!
( cd "$_fh_2b" && "$FELIX" gate >/dev/null 2>&1 ) & _fh_2pb=$!
wait "$_fh_2pa"; wait "$_fh_2pb"
is "two failing gates at once over two split pairs leave four lines, the healed pairs of four fields and the gates' own rows of six" \
   "$(grep -c '' "$_fh_2l") $(awk -F'\t' '{ print NF }' "$_fh_2l" | sort | tr '\n' ' ')" "4 4 4 6 6 "
_fh_2j="$(grep -cxF "$(printf '2026-09-01\tHEAD\tunborn\tx ')" "$_fh_2l") $(grep -cxF "$(printf '2026-09-02\tHEAD\tunborn\ty ')" "$_fh_2l")"
is "and each pair is joined exactly once" "$_fh_2j" "1 1"
is "and both gates' own rows are kept, one each" "$(awk -F'\t' '$4 == "lint "' "$_fh_2l" | grep -c '')" "2"
if [ "$_fh_2j" = "1 1" ]; then
  is "and two heals at once leave no temporary or lock behind" "$(_fh_left "$MEM/healproj2")" ""
else
  bad "and two heals at once leave no temporary or lock behind" "the pairs were not joined, so an empty directory proves nothing"
fi

# A symlinked log is not replaced: renaming onto it would turn the link into a
# regular file. It is still read joined, through the readers below.
_fh_proj healsym true
_fh_legacy "$_fh_today" 'lint ' > "$TMP/fh-symtarget.log"; cp "$TMP/fh-symtarget.log" "$TMP/fh-symtarget.copy"
ln -s "$TMP/fh-symtarget.log" "$MEM/healsym/mistakes.log"
( cd "$(_fh_root healsym)" && "$FELIX" gate >/dev/null 2>&1 )
[ -L "$MEM/healsym/mistakes.log" ] \
  && ok  "a symlinked log is still a symlink after a gate" \
  || bad "a symlinked log is still a symlink after a gate" "$(ls -l "$MEM/healsym/mistakes.log")"
cmp -s "$TMP/fh-symtarget.log" "$TMP/fh-symtarget.copy" && [ "$(_fh_pairs "$TMP/fh-symtarget.copy")" = "1" ] \
  && ok  "and the split file it points at is byte for byte what it was" \
  || bad "and the split file it points at is byte for byte what it was" "$(od -c "$TMP/fh-symtarget.log" | head -n 3)"
is "and the recurrence report still reads the failure through the link" \
   "$(_fh_recur "$FROOT/projects/healsym" 1)" "$(printf '1\tlint\t%s\t1' "$_fh_today")"
has "and procedures still name it through the link" "$(_fh_items "$FROOT/projects/healsym")" "failure:lint"
has "and the Stop hook's guard still names it through the link" "$(_fh_guard "$FROOT/projects/healsym")" "last caught   lint"

# The other entry points. A failing gate heals before it records, so its own
# row lands after the healed one.
_fh_proj healfail gate.sh
_fh_script healfail 'echo "  lint               FAIL"; exit 1'
_fh_legacy 2026-09-01 'a ' > "$MEM/healfail/mistakes.log"
( cd "$(_fh_root healfail)" && "$FELIX" gate >/dev/null 2>&1 )
is "a failing gate heals the split row too, and its own row follows: two lines, the healed one first" \
   "$(grep -c '' "$MEM/healfail/mistakes.log")|$(head -n 1 "$MEM/healfail/mistakes.log")|$(tail -n 1 "$MEM/healfail/mistakes.log" | cut -f4)" \
   "2|$(printf '2026-09-01\tHEAD\tunborn\ta ')|lint "

# felix commission heals before it asks its rows, so gate_shown_failing is read
# on the healed file. --status writes nothing, and so heals nothing.
_fh_proj healcm true
_fh_mr="$(_fh_root healcm)"; _fh_mp="$FROOT/projects/healcm"; _fh_ml="$MEM/healcm/mistakes.log"
cp "$FROOT/harness/templates/profiles.tsv" "$FROOT/harness/templates/routes.tsv" "$_fh_mp/"
{ _fh_cmhdr; _fh_cmrow gate_shown_failing; printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n'; } > "$_fh_mp/commissioning.tsv"
_fh_legacy 2026-09-01 'lint ' > "$_fh_ml"; cp "$_fh_ml" "$TMP/fh-cm.seed"
( cd "$_fh_mr" && PATH="$CMSTUB:$PATH" "$FELIX" commission --status ) >/dev/null 2>&1
if [ "$(_fh_pairs "$TMP/fh-cm.seed")" != "1" ]; then
  bad "felix commission --status leaves a split log byte for byte, because it writes nothing" "the fixture did not seed a pair"
elif cmp -s "$_fh_ml" "$TMP/fh-cm.seed"; then
  ok  "felix commission --status leaves a split log byte for byte, because it writes nothing"
else
  bad "felix commission --status leaves a split log byte for byte, because it writes nothing" "$(od -c "$_fh_ml" | head -n 3)"
fi
_fh_cmo="$(cd "$_fh_mr" && PATH="$CMSTUB:$PATH" "$FELIX" commission 2>&1)"
cmp -s "$_fh_ml" "$TMP/fh-one.expect" \
  && ok  "a full felix commission heals the split row" \
  || bad "a full felix commission heals the split row" "$(od -c "$_fh_ml" | head -n 3)"
is "so its report shows gate_shown_failing done" \
   "$(printf '%s\n' "$_fh_cmo" | grep -cE '^  done +gate_shown_failing( |$)')" "1"

# The one transform, from resolve.sh alone, because every entry point sources
# resolve.sh first, and so do the suite's single-lib subshells.
_fh_rowsof() { bash -c '. "$1/lib/resolve.sh" && felix_mem_mistake_rows "$2"' _ "$FROOT/harness" "$1"; }
_fh_legacy 2026-09-01 'lint ' > "$TMP/fh-reader.log"; cp "$TMP/fh-reader.log" "$TMP/fh-reader.copy"
_fh_rowsof "$TMP/fh-reader.log" > "$TMP/fh-reader.out" 2>/dev/null
if cmp -s "$TMP/fh-reader.out" "$TMP/fh-one.expect" && cmp -s "$TMP/fh-reader.log" "$TMP/fh-reader.copy"; then
  ok  "felix_mem_mistake_rows, with resolve.sh alone, reads a split pair as its one joined row and leaves the file as it was"
else
  bad "felix_mem_mistake_rows, with resolve.sh alone, reads a split pair as its one joined row and leaves the file as it was" \
      "$(od -c "$TMP/fh-reader.out" | head -n 3)"
fi
printf '2026-09-01\tmain\tabc1234\tlint \n2026-09-02\tHEAD\tunborn\tx\n' > "$TMP/fh-reader-wf.log"
_fh_rowsof "$TMP/fh-reader-wf.log" > "$TMP/fh-reader-wf.out" 2>/dev/null
[ -s "$TMP/fh-reader-wf.out" ] && cmp -s "$TMP/fh-reader-wf.out" "$TMP/fh-reader-wf.log" \
  && ok  "and passes a well-formed file through byte for byte" \
  || bad "and passes a well-formed file through byte for byte" "$(od -c "$TMP/fh-reader-wf.out" | head -n 3)"
_fh_miss="$(_fh_rowsof "$TMP/fh-no-such.log" 2>&1)"; _fh_missrc=$?
is "and prints nothing for a missing file, returning 0" "$_fh_missrc|$_fh_miss" "0|"

# The readers, on a log nothing has healed: the heal can decline, and
# felix commission --status never heals, so each reader reads through the
# transform and is right either way. Seeded by hand; no gate or hook runs.
_fh_ep="$FROOT/projects/healread"; mkdir -p "$_fh_ep" "$MEM/healread"
printf '{"name":"healread","gate":"true"}\n' > "$_fh_ep/project.json"
_fh_el="$MEM/healread/mistakes.log"
{ _fh_legacy "$_fh_today" 'lint '; _fh_legacy "$_fh_today" 'lint '; printf '%s\tmain\tabc1234\tlint \n' "$_fh_today"; } > "$_fh_el"
is "the recurrence report counts an unhealed split row: two occasions, unborn and a sha, over three runs" \
   "$(_fh_recur "$_fh_ep")" "$(printf '2\tlint\t%s\t3' "$_fh_today")"
_fh_legacy "$_fh_today" 'lint ' > "$_fh_el"
has "procedures name the failure an unhealed split row holds" "$(_fh_items "$_fh_ep")" "failure:lint"
{ printf '%s\tmain\tabc1234\tother \n' "$_fh_today"; _fh_legacy "$_fh_today" 'lint '; } > "$_fh_el"
if [ -e "$MEM/healread/lessons.md" ] || [ -e "$MEM/healread/DEVLOG.md" ]; then
  bad "the Stop hook's guard names what an unhealed split row caught last" "the fixture has a lessons file or a devlog"
else
  has "the Stop hook's guard names what an unhealed split row caught last" "$(_fh_guard "$_fh_ep")" "last caught   lint"
fi
{ _fh_legacy "$_fh_today" 'a '; printf '%s\tmain\tabc1234\tb \n' "$_fh_today"; _fh_legacy "$_fh_today" 'c '; } > "$_fh_el"
_fh_emp="$(_fh_mon "$_fh_ep")"
is "the monitor counts an unhealed split row once: three rows, not five" "$(_fh_montotal "$_fh_emp")" "3"
is "and its newest entry says the commit was unborn" \
   "$(_fh_monfirst "$_fh_emp" | tr ',' '\n' | grep '^"commit":')" '"commit":"unborn"'
# The same four readers on a well-formed log print exactly what they always
# did. Pinned as literals rather than compared with a second reader.
printf '%s\tmain\tabc1234\tlint \n%s\tmain\tdef5678\tlint \n' "$_fh_today" "$_fh_today" > "$_fh_el"
is "on a well-formed log the recurrence report is what it always was" \
   "$(_fh_recur "$_fh_ep")" "$(printf '2\tlint\t%s\t2' "$_fh_today")"
is "and procedures list the failure as they always did" "$(_fh_items "$_fh_ep")" "failure:lint"
is "and the guard names the last catch as it always did" \
   "$(_fh_guard "$_fh_ep" | sed -n '1p;/last caught/p')" \
   "$(printf 'The gate caught something here and nothing has been written down since.\n  last caught   lint')"
_fh_emp="$(_fh_mon "$_fh_ep")"
is "and the monitor's count and newest entry are what they always were" \
   "$(_fh_montotal "$_fh_emp")|$(_fh_monfirst "$_fh_emp")" \
   "2|{\"date\":\"$_fh_today\",\"branch\":\"main\",\"commit\":\"def5678\",\"what\":\"lint \"}"

# #267's writer is unchanged by any of this: on an unborn HEAD one failing
# gate is one row, and every byte of it is pinned here. The second it was
# caught is the one byte run not known in advance, so it is read back from the
# row, and must be a second of this run; the session is a dash, since the
# suite runs under none.
mkdir -p "$FROOT/projects/healunborn" "$MEM/healunborn" "$TMP/fr-healunborn"
( _fx_cd "$TMP/fr-healunborn" && git init -q -b main && printf 'healunborn\n' > .felix ) >/dev/null 2>&1
_fh_setgate healunborn gate.sh
_fh_script healunborn 'echo "  lint               FAIL"; exit 1'
: > "$MEM/healunborn/mistakes.log"
( cd "$TMP/fr-healunborn" && "$FELIX" gate >/dev/null 2>&1 )
_fh_ust="$(head -n 1 "$MEM/healunborn/mistakes.log" | cut -f5)"
case "$_fh_ust" in ''|*[!0-9]*) _fh_ust=0 ;; esac
[ $(( $(date +%s) - _fh_ust )) -lt 600 ] || _fh_ust=not-a-second-of-this-run
printf '%s\tmain\tunborn\tlint \t%s\t-\n' "$_fh_today" "$_fh_ust" > "$TMP/fh-unborn.expect"
cmp -s "$MEM/healunborn/mistakes.log" "$TMP/fh-unborn.expect" \
  && ok  "a failing gate on an unborn HEAD still writes one row: today, main, unborn, the checks, the second and no session, byte for byte" \
  || bad "a failing gate on an unborn HEAD still writes one row: today, main, unborn, the checks, the second and no session, byte for byte" \
         "$(od -c "$MEM/healunborn/mistakes.log" | head -n 3)"

