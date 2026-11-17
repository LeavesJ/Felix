# >>> trust-step4-reader-reach
printf '\ntrust plane step 4, slice 1: the reader of the log, with and without memory, the reach statement and what counts after it, and the two reach programs (spec-slice1 V1 to V4, W8, T1 to T4; blind)\n'
# Blind, written on 2026-11-12 from .felix/memory/felix/audits/2026-11-13-trust-step4-shadow/spec-slice1.md (rev 3)
# alone (sections 4 and 5, with 2.3, D4, D8, D9 and cases 10, 11, 14 and 21), before felix authority, felix door and
# the reach programs existed, by an author who has seen no implementation of them. Of the 11-10 mock,
# spike/cases-door.sh was read for how V62 was staged, and nothing else. The helpers are tests/lib/trust-step4.sh.
# Everything is under $TMP/ts4-reader-reach.
#
# Three authorities over one source. v is shadow by construction and its log (start, hold, stop) is what the reader
# reads. A statement is dropped, or made again by hand, with git in v's own store: the bytes of the entry's own
# commit, changed in one place, written as an object, and the log's ref put there. Each such try is undone before
# the next. The control for those tries is the same entry with nothing changed but its nonce, which must verify:
# what a tampered one is refused for is then the tamper. w is a second store, for a statement that names another
# authority. r has another login as its only worker, so that one store sees the console (that login runs no
# process), the desktop (the workers row is changed to a login, not root, that runs one) and the reach statement
# between them; where this machine has no such pair of logins, or ps cannot list its processes, or status gives r
# a why line of condition a, b or e (case 22: the code it runs is within a worker's reach here), every assertion
# on r is skipped under its own name.
#
# Readings, where the spec leaves room:
# - A dropped last statement is told from the log's ref alone: the reader with no memory says ok, as V3 says it would.
# - "not ok statement N": where the place and the serial written differ (a dropped middle), N is not asserted.
#   A nonce that stands in two entries is told at the second of them.
# - V1's "the fields of D8 and nothing else" refuses a field twice, a field gone, a line after the last, two fields
#   in the other order, and another first line. A statement made by hand that keeps each of V1's rules verifies:
#   nothing is signed (V2), so the reader has no way to tell, and the tries below lean on that for their control.
# - The record is one blob at the top of the reach statement's tree. Were it kept deeper, the two tries that
#   rebuild that tree would report "staged: no" and not a verdict.
# - RECORD: a record written by hand, a plain file directly in AH/reach/ whose first line is
#   felix-reach-witness/v1, stands for one where reach-witness is not the thing under test.
# - Lines of the reader are looked for on both streams, but "ok N statements" on standard output.
# - K1 read to the letter: in shadow each statement is read, so once a reach fail makes the standing shadow again,
#   a desktop hold that never counted holds its head.
# - T2: each try's line starts with its name, and the eight tries the spec lists are told by the spec's own nouns.
# - A memory that cannot be written is one whose path runs through a plain file.
#
# Not covered: reach-probe --run on macOS, or wherever a display or a tool that could reach one is present: there
# its tries are real (a screen captured, keys posted), and the suite makes none; what reach-witness records while it
# waits (its standard input, the application in front, the pasteboard), since only --seconds 0 is driven; whether a
# statement given at the desktop between a reach pass and a later reach fail still counts (W8's words allow both);
# what a reach fail given with - puts in its witness field and in its commit; the memory file's format; a reader
# whose --store names no store; a first entry that is no start (the tries here change the last entry); a second
# login, which section 5 leaves to the founder.
_ts4_begin ts4-reader-reach
TS4V_S="$TS4/src.git"; TS4V_V="$TS4/v"; TS4V_W="$TS4/w"; TS4V_R="$TS4/r"; TS4V_ST="$TS4V_V/store.git"; TS4V_X="$TS4/x"
TS4V_OK3="ok 3 statements, 3 on the authority's word"
_ts4_src "$TS4V_S"; _ts4_base "$TS4V_S"; TS4V_M2="$TS4_M2"
_ts4_ci "$TS4V_S" plain "$TS4V_M2" 'an ordinary change' notes/plain.txt; TS4V_HP="$TS4_C"
_ts4_ci "$TS4V_S" h1 "$TS4V_M2" 'a second ordinary change' notes/h1.txt; TS4V_H1="$TS4_C"
_ts4_ci "$TS4V_S" h2 "$TS4V_M2" 'a third ordinary change' notes/h2.txt; TS4V_H2="$TS4_C"
printf '#!/bin/sh\nprintf "ran\\n" >> "%s"\n' "$TS4V_X/marks" > "$TS4V_X/mark.sh"; chmod 755 "$TS4V_X/mark.sh"

# ------------------------------------------------------------------ helpers ---
_ts4v_verify() { _ts4_a "$TS4V_V" verify "$@"; cat "$TS4/o" "$TS4/e" > "$TS4/oe" 2>/dev/null; }   # [ARG...]: the reader over v; both streams in $TS4/oe
_ts4v_starts() { _ts4_yn test "$(_ts4_count "$1" "$TS4/oe")" -gt 0; }   # PREFIX: yes when a line the reader printed begins with it
_ts4v_unv() { printf 'exit %s; not ok statement %s: %s; ok: %s' "$TS4_RC" "$1" "$(_ts4v_starts "not ok statement $1: ")" "$(_ts4v_starts 'ok ')"; }   # N
_ts4v_blob() { _fx_git "$TS4V_S" hash-object --no-filters "$1" 2>/dev/null; }   # FILE -> its git blob id
_ts4v_load() {   # the last entry of v's log: TS4V_TIP, its parent TS4V_P, its tree TS4V_ET, and its commit's own bytes in $TS4V_X/ct
  TS4V_TIP="$(_ts4_tip "$TS4V_V")"; TS4V_P="$(_ts4_sg "$TS4V_ST" rev-parse -q --verify "${TS4V_TIP:-none}^")"
  TS4V_ET="$(_ts4_sg "$TS4V_ST" rev-parse -q --verify "${TS4V_TIP:-none}^{tree}")"
  _ts4_sg "$TS4V_ST" cat-file commit "${TS4V_TIP:-none}" > "$TS4V_X/ct"
}
_ts4v_cv() { cp "${1:-$TS4V_X/ct}" "$TS4V_X/cv" 2>/dev/null; }   # [FILE]: the commit to be made by hand starts as the last entry's own bytes
_ts4v_pl() {   # PROGRAM: $TS4V_X/cv is rewritten by that perl program, which is given the whole file; no other byte changes
  perl -0777 -pe "$1" "$TS4V_X/cv" > "$TS4V_X/cv.new" 2>/dev/null; cat "$TS4V_X/cv.new" > "$TS4V_X/cv"; rm -f "$TS4V_X/cv.new"
}
_ts4v_set() { K="$1" V="$2" _ts4v_pl 'my ($h, $m) = split /\n\n/, $_, 2; $m =~ s/^\Q$ENV{K}\E: .*$/$ENV{K}: $ENV{V}/m; $_ = "$h\n\n$m"'; }   # KEY VALUE: the statement's field KEY says VALUE
_ts4v_hdr() { K="$1" V="$2" _ts4v_pl 'my ($h, $m) = split /\n\n/, $_, 2; $h =~ s/^\Q$ENV{K}\E .*$/$ENV{K} $ENV{V}/m; $_ = "$h\n\n$m"'; }   # WORD VALUE: the commit's line WORD (tree, parent, author) says VALUE
_ts4v_forge() {   # [FILE]: the last entry of v's log becomes the commit whose bytes FILE (or $TS4V_X/cv) holds
  local c f="${1:-$TS4V_X/cv}"
  [ -s "$f" ] || return 1
  c="$(_ts4_sg "$TS4V_ST" hash-object -t commit -w "$f")" || c="$(_ts4_sg "$TS4V_ST" hash-object -t commit -w --literally "$f")" || return 1
  [ -n "$c" ] && _ts4_sg "$TS4V_ST" update-ref refs/felix/door "$c" >/dev/null
}
_ts4v_cut() { [ -n "$1" ] && _ts4_sg "$TS4V_ST" update-ref refs/felix/door "$1" >/dev/null; }   # REV: v's log ends at REV
_ts4v_back() { _ts4v_cut "$TS4V_TIP"; }   # v's log is the one the door kept
_ts4v_t() {   # WHAT: $TS4V_X/cv, made into the last entry, is refused by the reader under that entry's number; then the log is put back
  local st=no
  if _ts4v_forge; then st=yes; fi
  _ts4v_verify
  _ts4_is "ts4 reader V1: the reader refuses a last statement $1" "staged: $st; $(_ts4v_unv "$TS4V_NTH")" "staged: yes; exit 1; not ok statement $TS4V_NTH: yes; ok: no" "$(_ts4_why)"
  _ts4v_back
}
_ts4v_bin() {   # HOME NAME ARG...: the program NAME of the harness's bin for that home, ended after 60 s at the latest; as _ts4_x leaves it
  local ah="$1" p="$FROOT/harness/bin/$2"; shift 2
  : > "$TS4/o"; : > "$TS4/e"
  if [ ! -x "$p" ]; then printf 'not run: no executable %s\n' "$p" > "$TS4/e"; TS4_RC=absent; return 1; fi
  { ( cd "$TS4/t" || exit 97
      exec env -u SSH_CONNECTION -u SSH_TTY PATH="$TS4_PATH" FELIX_AUTHORITY_HOME="$ah" perl -e 'alarm shift; exec @ARGV' 60 "$p" "$@" ) < /dev/null > "$TS4/o" 2> "$TS4/e" 7>&- 8>&-
    TS4_RC=$?; } 2>/dev/null
}
_ts4v_val() { local l; l="$(_ts4_line "$1" "$TS4/o")"; printf '%s' "${l#"$1"}"; }   # PREFIX: what follows it on the first line of the last output that begins with it
_ts4v_no() {   # WHAT RECORD: at r's console, reach pass RECORD is refused and nothing is kept
  _ts4_plain "$TS4V_R" "reach pass $2" "reach pass"
  _ts4_is "ts4 reach D4: at the console, reach pass is refused for a record $1" "exit $TS4_DRC; refused: $(_ts4_refused); statements: $(_ts4_n "$TS4V_R")" "exit 1; refused: yes; statements: 2" "$(_ts4_dwhy)"
}
_ts4v_stands() { LC_ALL=C awk -F'\t' 'NF == 5 { s[$1]++ } END { for (k in s) printf "%s x%d ", k, s[k] }' "$TS4/o"; }   # the standing each candidate line of the last tick starts with

# ------------------------------------------------------------------ controls ---
is "ts4 reader (control): the source holds main and three branches, each one commit past main, and git names a file's blob without a repository of its own" \
  "$(_fx_git "$TS4V_S" for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null | LC_ALL=C sort | tr '\n' ' '); $(for _ts4v_i in "$TS4V_HP" "$TS4V_H1" "$TS4V_H2"; do printf '%s ' "$(_fx_git "$TS4V_S" rev-list --count "$TS4V_M2..$_ts4v_i" 2>/dev/null)"; done); $(_ts4v_blob "$TS4V_X/mark.sh" | LC_ALL=C awk '{ print length($0) }')" \
  "h1 h2 main plain ; 1 1 1 ; 40"

# ------------------------------------------------------------------ the reader, with and without memory (V1 to V3) ---
_ts4_init "$TS4V_V" "$TS4_ME" "$TS4V_S"; TS4V_ID="$TS4_ID"
_ts4_say "$TS4V_V" "start $TS4V_M2"; _ts4_say "$TS4V_V" "hold $TS4V_HP"; _ts4_plain "$TS4V_V" stop stop
TS4V_R0="$(_ts4_rev "$TS4V_V" 0)"; TS4V_R1="$(_ts4_rev "$TS4V_V" 1)"; _ts4v_load; TS4V_NOFILE="$TS4V_ET"; _ts4v_verify
_ts4_is "ts4 reader V2, V3: a log of three statements kept through the door verifies, exit 0, each taken on the authority's word, and with no --memory the reader says what it could not see" \
  "$(_ts4_n "$TS4V_V") kept; exit $TS4_RC; $(_ts4_line 'ok ' "$TS4/o"); $(_ts4_line 'no memory: ' "$TS4/oe")" "3 kept; exit 0; $TS4V_OK3; no memory: a log whose last statements were dropped would read the same" "$(_ts4_why)"
_ts4v_verify --memory "$TS4V_X/mem"; TS4V_A="exit $TS4_RC; $(_ts4_line 'ok ' "$TS4/o"); no memory lines: $(_ts4_count 'no memory' "$TS4/oe"); a file kept: $(_ts4_yn test -s "$TS4V_X/mem")"; _ts4v_verify --memory "$TS4V_X/mem"
_ts4_is "ts4 reader V3: with --memory the reader keeps what it checked last in the file and says nothing of no memory, and a second run over the same log is ok" \
  "$TS4V_A; again: exit $TS4_RC; $(_ts4_line 'ok ' "$TS4/o")" "exit 0; $TS4V_OK3; no memory lines: 0; a file kept: yes; again: exit 0; $TS4V_OK3" "$(_ts4_why)"
_ts4v_verify --memory "$TS4V_X/mark.sh/mem"
_ts4_is "ts4 reader V3: a memory that cannot be written, its path running through a plain file, prints a line starting not ok: and no ok line" \
  "not ok: $(_ts4v_starts 'not ok: '); ok: $(_ts4v_starts 'ok '); exit 0: $(if [ "$TS4_RC" = 0 ]; then printf yes; else printf no; fi)" "not ok: yes; ok: no; exit 0: no" "$(_ts4_why)"
[ ! -d "$TS4V_ST" ] || cp -R "$TS4V_ST" "$TS4/copy.git"; _ts4_sg "$TS4/copy.git" update-ref refs/felix/door "${TS4V_R1:-none}" >/dev/null
_ts4v_verify --store "$TS4/copy.git"; TS4V_A="a copy cut by one: exit $TS4_RC; $(_ts4_line 'ok ' "$TS4/o")"; _ts4v_verify
_ts4_is "ts4 reader V1: --store reads the log of the store at that path: a copy of the store cut by one statement reads as two, and the configured store still as three" \
  "$TS4V_A; configured: $(_ts4_line 'ok ' "$TS4/o")" "a copy cut by one: exit 0; ok 2 statements, 2 on the authority's word; configured: $TS4V_OK3" "$(_ts4_why)"
_ts4v_cut "$TS4V_R1"; TS4V_A="left: $(_ts4_n "$TS4V_V")"; _ts4v_verify --memory "$TS4V_X/mem"; TS4V_A="$TS4V_A; with memory: exit $TS4_RC; $(_ts4_line 'not ok: ' "$TS4/oe")"; _ts4v_verify
_ts4_is "ts4 reader V3: a log whose last statement was dropped is not ok, by that statement's number, to the reader that saw it, and reads as ok to a reader with no memory" \
  "$TS4V_A; without: exit $TS4_RC; $(_ts4_line 'ok ' "$TS4/o")" "left: 2; with memory: exit 1; not ok: the log no longer holds statement 2 that this reader saw; without: exit 0; ok 2 statements, 2 on the authority's word" "$(_ts4_why)"
_ts4v_verify --memory "$TS4V_X/mh"; TS4V_A="saw the hold last: exit $TS4_RC"; _ts4v_cut "$TS4V_R0"; _ts4v_verify --memory "$TS4V_X/mh"
_ts4_is "ts4 reader case 10: after the reader has seen a hold, a log with that hold dropped is not ok to that reader" \
  "$TS4V_A; left: $(_ts4_n "$TS4V_V"); exit $TS4_RC; $(_ts4_line 'not ok: ' "$TS4/oe")" "saw the hold last: exit 0; left: 1; exit 1; not ok: the log no longer holds statement 1 that this reader saw" "$(_ts4_why)"
_ts4v_back
_ts4v_cv; _ts4v_set nonce "${TS4_NOPE:0:32}"; TS4V_A="staged: $(_ts4_yn _ts4v_forge)"; _ts4v_verify; TS4V_A="$TS4V_A; another commit: $(if [ -n "$TS4V_TIP" ] && [ "$(_ts4_tip "$TS4V_V")" != "$TS4V_TIP" ]; then printf yes; else printf no; fi); exit $TS4_RC; $(_ts4_line 'ok ' "$TS4/o")"
_ts4_is "ts4 reader V1, V2 (the tries' control): the last statement made again by hand, its commit's own bytes with another nonce, is another commit, and verifies: nothing is signed" \
  "$TS4V_A" "staged: yes; another commit: yes; exit 0; $TS4V_OK3" "$(_ts4_why)"
_ts4v_verify --memory "$TS4V_X/mem"
_ts4_is "ts4 reader V3: memory is of the entry and not of a count: that log, as long as before, with another statement in the place of the one seen, is not ok to the reader that saw it" \
  "exit $TS4_RC; $(_ts4_line 'not ok: ' "$TS4/oe")" "exit 1; not ok: the log no longer holds statement 2 that this reader saw" "$(_ts4_why)"
_ts4v_back
_ts4v_cv; _ts4v_hdr parent "${TS4V_R0:-none}"; TS4V_A="staged: $(_ts4_yn _ts4v_forge), $(_ts4_n "$TS4V_V") left"; _ts4v_verify; TS4V_A="$TS4V_A; reader: exit $TS4_RC, not ok statement: $(_ts4v_starts 'not ok statement '), ok: $(_ts4v_starts 'ok ')"
_ts4_a "$TS4V_V" tick; TS4V_A="$TS4V_A; tick: exit $TS4_RC, paused with the door's log: $(_ts4_paused "the door's log"), candidate lines: $(_ts4_cands)"; _ts4_dd "$TS4V_V" "$TS4V_HP"
_ts4_is "ts4 reader case 10, K1, V4: when a middle statement is dropped, so that the entries left no longer follow one another, the reader refuses the log, a tick is paused with the door's log and exits 3, and decide decides nothing" \
  "$TS4V_A; decide: $TS4_DEC" "staged: yes, 2 left; reader: exit 1, not ok statement: yes, ok: no; tick: exit 3, paused with the door's log: yes, candidate lines: 0; decide: no line" "$(_ts4_why)"
_ts4v_back

# ------------------------------------------------------------------ each entry, checked (V1, cases 11 and 21) ---
TS4V_NTH=2; printf 'other bytes\n' > "$TS4V_X/blob2"; TS4V_BL="$(_ts4_sg "$TS4V_ST" hash-object -w --no-filters "$TS4V_X/blob2")"; TS4V_FT="$(printf '100644 blob %s\tnote\n' "$TS4V_BL" | _ts4_sg "$TS4V_ST" mktree)"
_ts4v_cv; P="${TS4V_R0:-none}" _ts4v_pl 's/^(parent [0-9a-f]+\n)/$1parent $ENV{P}\n/m'; _ts4v_t "whose commit has two parents"
_ts4v_cv; _ts4v_pl '$_ .= (/\n\z/ ? "" : "\n") . "extra: field\n"'; _ts4v_t "with a line after its last field"
_ts4v_cv; _ts4v_pl 's/^key: .*\n//m'; _ts4v_t "with one field's line gone"
_ts4v_cv; _ts4v_pl 's/^(verb: .*\n)/$1verb: go\n/m'; _ts4v_t "with one field twice"
_ts4v_cv; _ts4v_pl 's/^(result: .*\n)(witness: .*\n)/$2$1/m'; _ts4v_t "with two fields in the other order"
_ts4v_cv; _ts4v_pl 's/\n\nfelix-door\/v1\n/\n\nfelix-door\/v2\n/'; _ts4v_t "whose first line names another format"
_ts4v_cv; _ts4v_set authority "$TS4_NOPE"; _ts4v_t "that names another authority"
_ts4v_cv; _ts4v_set serial 7; _ts4v_t "whose serial is not its place"
_ts4v_cv; _ts4v_set prev "${TS4V_R0:-none}"; _ts4v_t "whose prev is not its parent"
_ts4v_cv; _ts4v_set verb grant; _ts4v_t "whose verb is not known"
_ts4v_cv; _ts4v_hdr tree "${TS4V_FT:-unbuilt}"; _ts4v_t "that holds a file and is no reach entry"
_ts4v_cv; _ts4v_set verb start; _ts4v_set commit "$TS4V_M2"; _ts4v_t "that is a second start (case 21)"
_ts4v_cv; _ts4v_set nonce "$(_ts4_fs "$TS4V_V" 1 nonce)"; _ts4v_t "whose nonce another entry has (case 21)"
_ts4v_cv; _ts4v_pl 's/^(committer .*\n)/$1encoding ISO-8859-1\n/m'; _ts4v_t "whose commit has one more header (case 21)"
_ts4v_cv; _ts4v_pl '$_ .= "\0more: bytes\n"'; _ts4v_t "whose message goes on after a NUL (case 21)"
_ts4v_cv; _ts4v_hdr author 'A Forger <forger@example.invalid> 1700000000 +0000'; _ts4v_t "whose author line is not the authority's own"
_ts4_sg "$TS4V_ST" cat-file commit "${TS4V_R1:-none}" > "$TS4V_X/c1"; _ts4v_cv "$TS4V_X/c1"; _ts4v_set authority "$TS4_NOPE"
TS4V_A="$(_ts4_yn _ts4v_forge)"; TS4V_B="$(_ts4_tip "$TS4V_V")"; _ts4v_cv; _ts4v_hdr parent "${TS4V_B:-none}"; _ts4v_set prev "${TS4V_B:-none}"; TS4V_A="$TS4V_A $(_ts4_yn _ts4v_forge)"; _ts4v_verify
_ts4_is "ts4 reader V1: the first entry that fails is the one named: with statement 1 made to name another authority and statement 2 made to follow it, the reader says not ok statement 1" \
  "staged: $TS4V_A; $(_ts4v_unv 1)" "staged: yes yes; exit 1; not ok statement 1: yes; ok: no" "$(_ts4_why)"
_ts4v_back
_ts4_init "$TS4V_W" "$TS4_ME" "$TS4V_S"; TS4V_IDW="$TS4_ID"; _ts4_say "$TS4V_W" "start $TS4V_M2"
TS4V_A="another store with a statement of its own: $(if [ "${#TS4V_IDW}" -eq 40 ] && [ "$TS4V_IDW" != "$TS4V_ID" ] && [ "$(_ts4_n "$TS4V_W")" = 1 ]; then printf yes; else printf no; fi)"
TS4V_A="$TS4V_A; its log brought here: $(_ts4_yn _ts4_sg "$TS4V_ST" fetch -q "$TS4V_W/store.git" refs/felix/door:refs/ts4/other)"; _ts4_sg "$TS4V_ST" update-ref refs/felix/door refs/ts4/other >/dev/null; _ts4v_verify
_ts4_is "ts4 reader case 11: the log of another store, put in the place of this store's, is refused at its first statement: its authority is another id" \
  "$TS4V_A; $(_ts4v_unv 0)" "another store with a statement of its own: yes; its log brought here: yes; exit 1; not ok statement 0: yes; ok: no" "$(_ts4_why)"
_ts4v_back; _ts4_sg "$TS4V_ST" update-ref -d refs/ts4/other >/dev/null
_ts4v_cv; _ts4v_hdr parent "${TS4V_TIP:-none}"; _ts4v_set serial 3; _ts4v_set prev "${TS4V_TIP:-none}"; _ts4v_set verb go; _ts4v_set nonce "${TS4_NOPE:0:32}"
TS4V_A="$(_ts4_yn _ts4v_forge)"; _ts4v_verify; TS4V_A="under this store's id: staged $TS4V_A, exit $TS4_RC, $(_ts4_line 'ok ' "$TS4/o")"; _ts4v_back
_ts4v_set authority "${TS4V_IDW:-none}"; TS4V_B="$(_ts4_yn _ts4v_forge)"; _ts4v_verify
_ts4_is "ts4 reader case 11: a statement that follows this log and names the other store's id is refused, where the same statement under this store's id reads as its fourth" \
  "$TS4V_A; under the other's: staged $TS4V_B, $(_ts4v_unv 3)" "under this store's id: staged yes, exit 0, ok 4 statements, 4 on the authority's word; under the other's: staged yes, exit 1; not ok statement 3: yes; ok: no" "$(_ts4_why)"
_ts4v_back

# ------------------------------------------------------------------ reach-witness and reach-probe (T1 to T3) ---
mkdir -p "$TS4/w1"; _ts4v_bin "$TS4V_V" reach-witness --seconds 0 --out "$TS4/w1"; TS4V_REC="$(_ts4v_val 'record: ')"; TS4V_WID="$(_ts4v_val 'witness: ')"
_ts4_is "ts4 reach T1, D4: reach-witness --seconds 0 --out DIR writes one record at once, a plain file under DIR whose first line is felix-reach-witness/v1, and prints record: and its path and witness: and the record's git blob id" \
  "exit $TS4_RC; files under DIR: $(find "$TS4/w1" -type f 2>/dev/null | LC_ALL=C awk 'END { print NR }'); record: $(case "$TS4V_REC" in ("$TS4/w1"/?*) if [ -f "$TS4V_REC" ] && [ ! -L "$TS4V_REC" ]; then printf 'a plain file under DIR'; else printf 'no plain file'; fi ;; (*) printf 'not under DIR' ;; esac); first line: $(LC_ALL=C awk 'NR == 1 { print; exit }' "${TS4V_REC:-/dev/null}" 2>/dev/null); witness: $(if [ "${#TS4V_WID}" -eq 40 ] && [ "$TS4V_WID" = "$(_ts4v_blob "$TS4V_REC")" ]; then printf 'its blob id'; else printf 'not its blob id'; fi)" \
  "exit 0; files under DIR: 1; record: a plain file under DIR; first line: felix-reach-witness/v1; witness: its blob id" "$(_ts4_why)"
TS4V_A="$(cksum "$TS4V_REC" 2>/dev/null)"; _ts4v_bin "$TS4V_V" reach-witness --seconds 0 --out "$TS4/w1"; TS4V_B="$(_ts4v_val 'record: ')"
_ts4_is "ts4 reach T1: a second run writes another record, with another witness, and leaves the first as it was" \
  "exit $TS4_RC; $(if [ -n "$TS4V_B" ] && [ "$TS4V_B" != "$TS4V_REC" ] && [ -f "$TS4V_B" ]; then printf 'another record'; else printf 'no other record'; fi); $(if [ "$(_ts4v_val 'witness: ' | LC_ALL=C awk '{ print length($0) }')" = 40 ] && [ "$(_ts4v_val 'witness: ')" != "$TS4V_WID" ]; then printf 'another witness'; else printf 'no other witness'; fi); the first: $(if [ -n "$TS4V_A" ] && [ "$(cksum "$TS4V_REC" 2>/dev/null)" = "$TS4V_A" ]; then printf 'as it was'; else printf 'changed or never there'; fi)" \
  "exit 0; another record; another witness; the first: as it was" "$(_ts4_why)"
_ts4v_bin "$TS4V_V" reach-witness --seconds 0; TS4V_WREC="$(_ts4v_val 'record: ')"; TS4V_WIDW="$(_ts4v_val 'witness: ')"; TS4V_A="${TS4V_WREC#"$TS4V_V/reach/"}"
_ts4_is "ts4 reach T1, D4: with no --out the record is written directly in reach/ in the authority's home" \
  "exit $TS4_RC; $(case "$TS4V_A" in (""|/*|*/*) printf 'not directly in reach/ in the home' ;; (*) if [ -f "$TS4V_V/reach/$TS4V_A" ]; then printf 'a file directly in reach/ in the home'; else printf 'no file'; fi ;; esac)" "exit 0; a file directly in reach/ in the home" "$(_ts4_why)"
_ts4_snap "$TS4/t" "$TS4V_V" > "$TS4V_X/before" 2>/dev/null; _ts4v_bin "$TS4V_V" reach-probe --list; _ts4_snap "$TS4/t" "$TS4V_V" > "$TS4V_X/after" 2>/dev/null
_ts4_is "ts4 reach T2: reach-probe --list prints a line for each try, each starting with a name of its own, the eight written so far at the least, and writes nothing" \
  "exit $TS4_RC; $(LC_ALL=C awk 'NF { n++; if (s[$1]++) d++ } END { printf "%s; a name twice: %d", (n >= 8 ? "eight lines or more" : n + 0 " lines"), d + 0 }' "$TS4/o"); wrote: $(if cmp -s "$TS4V_X/before" "$TS4V_X/after"; then printf nothing; else printf something; fi)" \
  "exit 0; eight lines or more; a name twice: 0; wrote: nothing" "$(_ts4_why)"
_ts4_is "ts4 reach T2: the list names the tries the spec lists: the screen, keys, a click, a window, the pasteboard, the authority's session, its home and the store" \
  "exit $TS4_RC; not named: $(LC_ALL=C tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz' < "$TS4/o" | W="screen key click window pasteboard session home store" LC_ALL=C awk '{ t = t " " $0 } END { n = split(ENVIRON["W"], w, " "); for (i = 1; i <= n; i++) if (!index(t, w[i])) printf "%s ", w[i] }')" "exit 0; not named: " "$(_ts4_why)"
TS4V_RUN=""
case "$(uname -s 2>/dev/null)" in Linux) ;; *) TS4V_RUN="this is not Linux: on macOS the tries are real, and the suite captures no screen and posts no key" ;; esac
[ -n "$TS4V_RUN" ] || [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] || TS4V_RUN="a display is set here, so a try could reach it"
for _ts4v_i in screencapture osascript xdotool ydotool wtype xclip xsel wl-copy import scrot grim gnome-screenshot xdg-open; do
  [ -n "$TS4V_RUN" ] || ! command -v "$_ts4v_i" >/dev/null 2>&1 || TS4V_RUN="$_ts4v_i is on PATH here, so a try could be real"
done
if [ -z "$TS4V_RUN" ]; then
  mkdir -p "$TS4/probe"; _ts4v_bin "$TS4V_W" reach-probe --run --user "$TS4_ME" --home "$TS4V_W" --out "$TS4/probe" --delay 0 --seconds 0
  _ts4_is "ts4 reach T3: where a tool it needs is absent, reach-probe --run writes the row not this system to probe.tsv and exits 3" \
    "exit $TS4_RC; a row says not this system: $(_ts4_said 'not this system' "$TS4/probe/probe.tsv")" "exit 3; a row says not this system: yes" "$(_ts4_why)"
else
  skip "ts4 reach T3: where a tool it needs is absent, reach-probe --run writes the row not this system to probe.tsv and exits 3" "$TS4V_RUN"
fi

# ------------------------------------------------------------------ a reach statement in shadow, and its record (D4, D8, D9, V1) ---
mkdir -p "$TS4V_V/reach"; printf 'felix-reach-witness/v1\na record made by hand\nwhat arrived: nothing\n' > "$TS4V_V/reach/rec"; TS4V_W1="$(_ts4v_blob "$TS4V_V/reach/rec")"
_ts4_plain "$TS4V_V" "reach pass $TS4V_V/reach/rec" "reach pass"
_ts4_is "ts4 reach case 14, D4: reach pass is refused away from the console: in shadow nothing is kept" \
  "exit $TS4_DRC; refused: $(_ts4_refused); statements: $(_ts4_n "$TS4V_V")" "exit 1; refused: yes; statements: 3" "$(_ts4_dwhy)"
_ts4_plain "$TS4V_V" "reach fail $TS4V_V/reach/rec" "reach fail"; TS4V_B="$(_ts4_rev "$TS4V_V" 3)"
_ts4_is "ts4 reach D4, D8, T4: reach fail with a record, confirmed by reach fail, is kept in shadow: the statement names no commit, says fail, and carries the record's git blob id as its witness" \
  "exit $TS4_DRC; kept: ${TS4_KEPT:-none}; $(_ts4_fs "$TS4V_V" 3 'verb commit tree given result witness')" "exit 0; kept: 3; reach|-|-|shadow|fail|$TS4V_W1" "$(_ts4_dwhy)"
_ts4_is "ts4 reach D9: a reach statement's commit holds the witness record and no other file" \
  "$(_ts4_sg "$TS4V_ST" ls-tree -r "${TS4V_B:-none}" | LC_ALL=C awk '{ printf "%s %s; ", $2, $3 } END { print NR + 0 " in all" }')" "blob $TS4V_W1; 1 in all"
_ts4v_load; TS4V_NTH=3; _ts4v_cv; _ts4v_set nonce "${TS4_NOPE:0:32}"; TS4V_A="$(_ts4_yn _ts4v_forge)"; _ts4v_verify
_ts4_is "ts4 reader V1 (the reach tries' control): the reach statement made again by hand with another nonce, its record in place, verifies" \
  "staged: $TS4V_A; exit $TS4_RC; $(_ts4_line 'ok ' "$TS4/o")" "staged: yes; exit 0; ok 4 statements, 4 on the authority's word" "$(_ts4_why)"
_ts4v_back
_ts4v_cv; _ts4v_hdr tree "${TS4V_NOFILE:-unbuilt}"; _ts4v_t "that is a reach entry and holds no file"
TS4V_B="$( { _ts4_sg "$TS4V_ST" ls-tree "${TS4V_ET:-none}"; printf '100644 blob %s\tzz-more\n' "$TS4V_BL"; } | _ts4_sg "$TS4V_ST" mktree)"; _ts4v_cv; _ts4v_hdr tree "${TS4V_B:-unbuilt}"; _ts4v_t "that is a reach entry and holds a file besides its record"
TS4V_B="$(_ts4_sg "$TS4V_ST" ls-tree "${TS4V_ET:-none}" | B="$TS4V_BL" LC_ALL=C awk -F'\t' '{ split($1, a, " "); print a[1] " " a[2] " " ENVIRON["B"] "\t" $2 }' | _ts4_sg "$TS4V_ST" mktree)"
_ts4v_cv; _ts4v_hdr tree "${TS4V_B:-unbuilt}"; _ts4v_t "that is a reach entry and holds other bytes than its witness names"
_ts4_plain "$TS4V_V" "reach fail $TS4V_WREC" "reach fail"; TS4V_B="$(_ts4_rev "$TS4V_V" 4)"; TS4V_A="exit $TS4_DRC; kept: ${TS4_KEPT:-none}; witness: $(_ts4_fs "$TS4V_V" 4 witness); holds: $(_ts4_sg "$TS4V_ST" ls-tree -r "${TS4V_B:-none}" | LC_ALL=C awk '{ printf "%s ", $3 }')"; TS4V_B="$(_ts4_dwhy)"; _ts4v_verify
_ts4_is "ts4 reach T1, T4, V1: the door takes the record reach-witness wrote: the statement's witness is the id the program printed, its commit holds that record, and the log verifies" \
  "$TS4V_A; $(_ts4_line 'ok ' "$TS4/o")" "exit 0; kept: 4; witness: ${TS4V_WIDW:-no witness was printed}; holds: ${TS4V_WIDW:-no witness was printed} ; ok 5 statements, 5 on the authority's word" "$TS4V_B"

# ------------------------------------------------------------------ live in a fixture: the console, the desktop and the reach statement (W6, W8, K1, case 14) ---
TS4_LOCK="$TS4V_X/mark.sh"; _ts4_logins
if [ "$TS4_PS" = yes ] && [ -n "$TS4_IDLE" ] && [ -n "$TS4_BUSY" ]; then
  ok "ts4 reach (control): ps lists this machine's processes, and it has a login other than this one that runs none and one, not root, that runs some"
else
  TS4_SKIP="no login that runs no process, or none but root that runs some, was found here (ps lists: $TS4_PS)"
  skip "ts4 reach (control): ps lists this machine's processes, and it has a login other than this one that runs none and one, not root, that runs some" "$TS4_SKIP"
fi
_ts4_init "$TS4V_R" "${TS4_IDLE:-none}" "$TS4V_S" --lock "$TS4V_X/mark.sh"; _ts4_canstand "$TS4V_R" "${TS4_IDLE:-none}"
_ts4_conf "$TS4V_R" workers "${TS4_BUSY:-none}"; _ts4_canstand "$TS4V_R" "${TS4_BUSY:-none}"; _ts4_conf "$TS4V_R" workers "${TS4_IDLE:-none}"
mkdir -p "$TS4V_R/reach/dir"; printf 'felix-reach-witness/v1\na record made by hand\n' > "$TS4V_R/reach/rec1"; printf 'felix-reach-witness/v1\na record of a try that got through\n' > "$TS4V_R/reach/rec2"
cp "$TS4V_R/reach/rec1" "$TS4V_R/reach/dir/rec"; cp "$TS4V_R/reach/rec1" "$TS4V_X/rec"; cp "$TS4V_R/reach/rec1" "$TS4V_R/outside"; printf 'a record with no first line of its kind\n' > "$TS4V_R/reach/plain"
chmod -R go-w "$TS4V_R/reach" "$TS4V_R/outside" 2>/dev/null; TS4V_W1="$(_ts4v_blob "$TS4V_R/reach/rec1")"; TS4V_W2="$(_ts4v_blob "$TS4V_R/reach/rec2")"
_ts4_say "$TS4V_R" "start $TS4V_M2"; _ts4_conf "$TS4V_R" workers "${TS4_BUSY:-none}"; _ts4_say "$TS4V_R" "hold $TS4V_H1"; _ts4_plain "$TS4V_R" "reach pass $TS4V_R/reach/rec1" "reach pass"
_ts4_is "ts4 reach case 14, D4: reach pass is refused at the desktop, where a hold was kept just before, and nothing is kept" \
  "the hold was given at the: $(_ts4_fs "$TS4V_R" 1 given); exit $TS4_DRC; refused: $(_ts4_refused); statements: $(_ts4_n "$TS4V_R")" "the hold was given at the: desktop; exit 1; refused: yes; statements: 2" "$(_ts4_dwhy)"
_ts4_conf "$TS4V_R" workers "${TS4_IDLE:-none}"
_ts4_is "ts4 reach (control): the records to be refused are staged: a plain file outside the home, a directory, a record inside that directory, a path through .. to a plain file, a plain file with another first line, and a name that is not there" \
  "$(_ts4_mode "$TS4V_X/rec" | cut -c1) $(_ts4_mode "$TS4V_R/reach/dir" | cut -c1) $(_ts4_mode "$TS4V_R/reach/dir/rec" | cut -c1) $(_ts4_yn test -f "$TS4V_R/reach/../outside") $(_ts4_mode "$TS4V_R/reach/plain" | cut -c1) $(_ts4_yn test -e "$TS4V_R/reach/none")" "- d - yes - no"
_ts4v_no "that is a plain file outside the home's reach directory" "$TS4V_X/rec"
_ts4v_no "that is a directory" "$TS4V_R/reach/dir"
_ts4v_no "that stands in a directory under reach/, not directly in it" "$TS4V_R/reach/dir/rec"
ln -s "$TS4V_X/rec" "$TS4V_R/reach/link" 2>/dev/null; _ts4v_no "that is a symbolic link out of the reach directory" "$TS4V_R/reach/link"; rm -f "$TS4V_R/reach/link"
_ts4v_no "whose path leaves the reach directory through .." "$TS4V_R/reach/../outside"
_ts4v_no "whose first line is not felix-reach-witness/v1" "$TS4V_R/reach/plain"
_ts4v_no "that is not there" "$TS4V_R/reach/none"
_ts4v_no "named -, which only a fail may name" -
_ts4_plain "$TS4V_R" "reach pass $TS4V_R/reach/rec1" "reach pass"; TS4V_A="exit $TS4_DRC; kept: ${TS4_KEPT:-none}; $(_ts4_fs "$TS4V_R" 2 'verb commit tree given result witness')"; TS4V_B="$(_ts4_dwhy)"; _ts4_a "$TS4V_R" log
_ts4_is "ts4 reach case 14, T4, D8: at the console reach pass is kept, confirmed by reach pass, with the record's git blob id as its witness, and it counts" \
  "$TS4V_A; $(_ts4_lr 2)" "exit 0; kept: 2; reach|-|-|console|pass|$TS4V_W1; 7:2|reach|-|-|console|yes" "$TS4V_B"
_ts4_a "$TS4V_R" status
_ts4_is "ts4 reach W6: with a start and a reach pass given at the console, and the authority's login its own, the standing is live and status prints no why" \
  "$(_ts4_sv standing); why lines: $(_ts4_count 'why: ' "$TS4/o")" "live; why lines: 0" "$(_ts4_why)"
_ts4_a "$TS4V_R" tick
_ts4_is "ts4 reach K1, W7, case 14: in live standing each candidate line starts with live, and the hold given at the desktop before the pass, which does not count, is not read" \
  "$(_ts4v_stands); h1: $(_ts4_of "$TS4V_H1"); $(LC_ALL=C awk 'END { print }' "$TS4/o")" "live x3 ; h1: eligible|-; tick: live, 3 candidates" "$(_ts4_why)"
_ts4_conf "$TS4V_R" workers "${TS4_BUSY:-none}"; _ts4_open "$TS4V_R" a "hold $TS4V_H2"; TS4V_A="$(_ts4_line 'counts: ' "$TS4/door.a.out")"; _ts4_close a "hold $TS4_FOUR"; TS4V_B="$(_ts4_dwhy)"; _ts4_a "$TS4V_R" log
_ts4_is "ts4 reach case 14, W8: a statement given at the desktop after the pass counts, and its card says so, while the one given at the desktop before the pass still does not" \
  "$TS4V_A; kept: ${TS4_KEPT:-none}; $(_ts4_lr 3); $(_ts4_lr 1)" "counts: yes; kept: 3; 7:3|hold|$TS4V_H2|-|desktop|yes; 7:1|hold|$TS4V_H1|-|desktop|no" "$TS4V_B"
_ts4_ci "$TS4V_S" main "$TS4V_M2" 'main moves at the source' notes/m3.txt; _ts4_a "$TS4V_R" tick
_ts4_is "ts4 reach K1, W11: in live standing the desktop hold that counts holds its head, and a tick does not move main to the source's" \
  "h2: $(_ts4_of "$TS4V_H2"); h1: $(_ts4_of "$TS4V_H1"); $(LC_ALL=C awk 'END { print }' "$TS4/o"); main: $(_ts4_main "$TS4V_R")" "h2: held|statement 3 holds $TS4V_H2; h1: eligible|-; tick: live, 3 candidates; main: $TS4V_M2" "$(_ts4_why)"
_ts4_plain "$TS4V_R" "reach fail $TS4V_R/reach/rec2" "reach fail"; TS4V_A="exit $TS4_DRC; kept: ${TS4_KEPT:-none}; $(_ts4_fs "$TS4V_R" 4 'verb given result witness')"; TS4V_B="$(_ts4_dwhy)"; _ts4_a "$TS4V_R" status
_ts4_is "ts4 reach W6, T4: a reach fail given at the desktop is kept with its record, and the standing is shadow again, for the latest reach statement is no pass" \
  "$TS4V_A; $(_ts4_sv standing) $(_ts4_whys)" "exit 0; kept: 4; reach|desktop|fail|$TS4V_W2; shadow d" "$TS4V_B"
_ts4_open "$TS4V_R" a "hold $TS4V_HP"; TS4V_A="$(_ts4_line 'counts: ' "$TS4/door.a.out" | cut -c1-12)"; _ts4_close a "hold $TS4_FOUR"; TS4V_B="$(_ts4_dwhy)"; _ts4_a "$TS4V_R" log
_ts4_is "ts4 reach W8: after the reach fail a statement given at the desktop does not count, and its card says counts: no: and why" \
  "$TS4V_A; kept: ${TS4_KEPT:-none}; $(_ts4_lr 5)" "counts: no: ; kept: 5; 7:5|hold|$TS4V_HP|-|desktop|no" "$TS4V_B"
_ts4_a "$TS4V_R" tick
_ts4_is "ts4 reach K1: back in shadow each statement is read: each candidate line starts with shadow, and the desktop hold that never counted holds its head" \
  "$(_ts4v_stands); h1: $(_ts4_of "$TS4V_H1")" "shadow x3 ; h1: held|statement 1 holds $TS4V_H1" "$(_ts4_why)"
_ts4_plain "$TS4V_R" "reach fail -" "reach fail"; TS4V_A="exit $TS4_DRC; kept: ${TS4_KEPT:-none}; $(_ts4_fs "$TS4V_R" 6 'verb result')"; TS4V_B="$(_ts4_dwhy)"; _ts4_a "$TS4V_R" verify
_ts4_is "ts4 reach D4, V1: reach fail - is kept with no record, and the whole log, its three reach statements among seven, verifies" \
  "$TS4V_A; reader: exit $TS4_RC; $(_ts4_line 'ok ' "$TS4/o")" "exit 0; kept: 6; reach|fail; reader: exit 0; ok 7 statements, 7 on the authority's word" "$TS4V_B"
TS4_SKIP=""; TS4_LOCK=""

_ts4_end
unset TS4V_S TS4V_V TS4V_W TS4V_R TS4V_ST TS4V_X TS4V_OK3 TS4V_M2 TS4V_HP TS4V_H1 TS4V_H2 TS4V_ID TS4V_IDW TS4V_R0 TS4V_R1 TS4V_TIP TS4V_P TS4V_ET TS4V_NOFILE TS4V_NTH \
  TS4V_A TS4V_B TS4V_BL TS4V_FT TS4V_REC TS4V_WID TS4V_WREC TS4V_WIDW TS4V_RUN TS4V_W1 TS4V_W2 _ts4v_i
# <<< trust-step4-reader-reach
