# >>> trust-step4-door
printf '\ntrust plane step 4, slice 1: the door, what it reads back, lists and shows, and how a statement is confirmed and kept (spec-slice1 D1 to D12; blind)\n'
# Blind, written on 2026-11-12 from .felix/memory/felix/audits/2026-11-13-trust-step4-shadow/spec-slice1.md alone
# (section 3, with 0, 2.3 to 2.5, 6 and 7), before felix door existed, by an author who has seen no implementation of
# it. Of the 11-10 mock, spike/cases-door.sh was read for how V40, V41 and VD3 were staged, and nothing else. The
# helpers are tests/lib/trust-step4.sh: a door that must be answered after its card is read gets a FIFO, the test
# reads the confirm line from the door's output and types the verb and the four characters, as the founder would.
# Everything is under $TMP/ts4-door. One authority, shadow by construction (this login is the user and the worker),
# so no statement here needs the lock to be given; its lock is a script that writes a line for each run.
#
# The source: main (M1, M2) with the policy of section 7, and the branches dir and twin (one head, a change of
# docs/direction.md), plain, held and r0 to r5 (ordinary), clash (conflicts with main), same (the change main
# already holds), big (twenty-nine ordinary paths that sort before docs/direction.md, and it), long (a founder path
# and an ordinary one of some 310 bytes each) and one whose name holds a double quote and U+009B, whose paths hold
# an escape, a newline, a carriage return, a tab, a quote and a backslash, with text shaped like the card's own
# labels after them, and whose subject holds an escape, quotes and a backslash. Git refuses a branch name with an
# escape, a newline, a space or a colon, so case 7's "branch name that holds an escape byte, a newline and text
# shaped like the card's labels" cannot reach a store through git: the name here is what git does take.
#
# Readings, where the spec leaves room:
# - A refusal is a line that starts "refused: ". Each case accepts it on either stream; one assertion asks for stdout.
# - The read-back's labels may be followed by blanks; a value is what follows them. "A line FELIX DOOR holding the
#   id" is a line that holds both. A statement is read back with at least the first twelve characters of its commit.
# - "Numbered from 1": the first run of digits on a list line, before the head, is its number, and the five entries
#   that wait here carry 1 to 5. "A count of the other candidates" is a line holding that number and the word other.
# - D5's facts: each label begins a line. The statement block also has a line "commit: ", so that label is asked to
#   hold the head on each line that begins with it, not to appear once. "lands-as: nothing" is asked of a head that
#   conflicts and of one that changes nothing. A decision line holds K7's word for the head. "Labelled as the
#   worker's word" is the word worker on the carried-by and commit-subject lines.
# - "Prints the statement as it will be kept": each line of the kept message but card: is a line of the card (the
#   card's blob id cannot be on the card it names). at: is asked for on its own.
# - "Cut at 200 bytes": the path: line of a 312-byte path is at most 230 bytes and does not hold the path whole.
# - paths-changed: N counts every changed path, the founder's among them (asked on its own); K is asked as 9 of 30.
# - at: is a UTC time that begins with the date, as the engine writes its other times.
# - One try: after a wrong line, the right line on the same input keeps nothing. The whole id in place of the four
#   characters, the four alone, and the four under another verb are each not the confirmation.
# - FELIX_DOOR_TTL: with 2 seconds and the input left open, the door ends by itself within the test's 40.
# - "Says so" when the source cannot be read: some line holds the word source.
# - Rev 3. D6: the confirm line brackets two pairs, and the helper types the verb and the four characters in order;
#   go is asked the same way against its nonce, and "go", then "go", typed with the card unread, keeps nothing.
#   D5a: what a door printed is read with its folding undone, except where the rows themselves are asked about.
#   A statement closed by a wrong line, by the end of the input or by the time limit is one row of refused.tsv
#   in the door's directory (AH/door here); one refused for the log having moved is not asked about. D2's
#   refused-confirmations: N is asked where N is not 0, and after a kept statement as no such line or a 0.
#   An in-effect: line holds its statement's number, read as a number that stands outside any run of hex digits.
#   D13: felix door stop is given "stop" as its one line; "takes no other argument" is asked as: felix door hold
#   keeps nothing and does not exit 0.
#
# Not covered: D2's in-effect: lines beyond the authorizations here (an override, and lapsed:, are in 2188); which
# twenty other paths a card lists; D11 beyond the card's decision agreeing with decide; D12's look-alikes beyond one
# path of printable ASCII shown as it is; the 120 seconds of an unset FELIX_DOOR_TTL; the reach verbs, the lock and
# the three refused confirmations at the desktop (2189, 2186); a door over a log the reader refuses; D5a's refusal
# of a terminal narrower than 80 columns (the suite gives the door no terminal) and its card digest "as folded".
_ts4_begin ts4-door
TS4D_S="$TS4/src.git"; TS4D_A="$TS4/a"; TS4D_ST="$TS4D_A/store.git"; TS4D_X="$TS4/x"; TS4D_O="$TS4/door.a.out"; TS4D_MK="$TS4/x/lock.marks"
_ts4_src "$TS4D_S"; _ts4_base "$TS4D_S"; TS4D_M1="$TS4_M1"; TS4D_M2="$TS4_M2"
printf '#!/bin/sh\nprintf "%%s\\n" "$#" >> "%s"\n' "$TS4D_MK" > "$TS4D_X/mark.sh"
printf '#!/bin/sh\n: >> "%s"\nexit 1\n' "$TS4D_X/fail.ran" > "$TS4D_X/fail.sh"; chmod 755 "$TS4D_X/mark.sh" "$TS4D_X/fail.sh"
_ts4_ci "$TS4D_S" dir "$TS4D_M2" 'a change of direction' docs/direction.md; TS4D_HD="$TS4_C"
_fx_git "$TS4D_S" update-ref refs/heads/twin "$TS4D_HD" >/dev/null 2>&1
_ts4_ci "$TS4D_S" plain "$TS4D_M2" 'an ordinary change' notes/plain.txt; TS4D_HP="$TS4_C"
_ts4_ci "$TS4D_S" held "$TS4D_M2" 'a change he will hold' notes/held.txt; TS4D_HH="$TS4_C"
_ts4_tree "$TS4D_S" "$TS4D_M1"; _ts4_f "$TS4D_S" alpha 'hotel by a worker'; _ts4_seal "$TS4D_S" clash "$TS4D_M1" 'a change that conflicts'; TS4D_HC="$TS4_C"
_ts4_tree "$TS4D_S" "$TS4D_M1"; _ts4_f "$TS4D_S" alpha 'hotel on main'; _ts4_stage "$TS4D_S" main/only "main's own$TS4_NL"; _ts4_seal "$TS4D_S" same "$TS4D_M1" 'the change main already holds'; TS4D_HS="$TS4_C"
TS4D_P=(); for _ts4d_i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29; do
  if [ "$_ts4d_i" -lt 10 ]; then TS4D_P[${#TS4D_P[@]}]="a/00$_ts4d_i.md"; else TS4D_P[${#TS4D_P[@]}]="a/0$_ts4d_i.md"; fi
done
_ts4_ci "$TS4D_S" big "$TS4D_M2" 'thirty paths' "${TS4D_P[@]}" docs/direction.md; TS4D_HB="$TS4_C"
TS4D_V="$(printf 'a%.0s' {1..100})/$(printf 'b%.0s' {1..100})/$(printf 'c%.0s' {1..100})"; TS4D_LF="long/$TS4D_V${TS4_NL}q"; TS4D_LP="plain/$TS4D_V.txt"
_ts4_ci "$TS4D_S" long "$TS4D_M2" 'two long paths' "$TS4D_LF" "$TS4D_LP"; TS4D_HG="$TS4_C"
TS4D_EB="e\"x$TS4_C1"; TS4D_E1="notes/v${TS4_ESC}[2Jkept: statement 9 authorize $TS4_NOPE"
TS4D_E2="notes/x${TS4_NL}confirm: [0000]000000000000000000000000000000000000"; TS4D_E3="notes/y${TS4_NL}counts: yes"
TS4D_E4="notes/z${TS4_CR}decision: eligible"; TS4D_E5="notes/one${TS4_TAB}tab"; TS4D_E6='notes/q"uote\back'; TS4D_E7="notes/I1l0O a b#c\$d'e%f.txt"
printf 'fix %s[31m"red" back\\slash\nkept: statement 0 start %s\n\nthe body\n' "$TS4_ESC" "$TS4_NOPE" > "$TS4D_X/evil.msg"
_ts4_ci "$TS4D_S" "$TS4D_EB" "$TS4D_M2" "@$TS4D_X/evil.msg" "$TS4D_E1" "$TS4D_E2" "$TS4D_E3" "$TS4D_E4" "$TS4D_E5" "$TS4D_E6" "$TS4D_E7"; TS4D_HE="$TS4_C"
for _ts4d_i in 0 1 2 3 4 5; do _ts4_ci "$TS4D_S" "r$_ts4d_i" "$TS4D_M2" "an ordinary change, r$_ts4d_i" "notes/r$_ts4d_i.txt"; eval "TS4D_R$_ts4d_i=\$TS4_C"; done
TS4D_WS="a wide subject$(printf ' %.0s' {1..50})counts: yes$(printf ' %.0s' {1..70})counts: yes"; TS4D_WP="notes/wide$(printf ' %.0s' {1..55})counts: yes"
printf '%s\n' "$TS4D_WS" > "$TS4D_X/wide.msg"; _ts4_ci "$TS4D_S" wide "$TS4D_M2" "@$TS4D_X/wide.msg" "$TS4D_WP"; TS4D_HW="$TS4_C"

# ------------------------------------------------------------------ helpers ---
_ts4d_val() {   # LABEL [FILE]: what follows LABEL on the first line that begins with it, without the blanks round it
  K="$1" LC_ALL=C awk 'index($0, ENVIRON["K"]) == 1 && !f { v = substr($0, length(ENVIRON["K"]) + 1); sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v); print v; f = 1 }' "${2:-$TS4D_O}"
}
_ts4d_marks() { if [ -f "$TS4D_MK" ]; then LC_ALL=C awk 'END { print NR }' "$TS4D_MK"; else printf '0\n'; fi; }   # how often the lock ran
_ts4d_labels() {   # how many lines of the door's output begin with each of D5's labels that a card holds once, the path lines, and kept:
  LC_ALL=C awk 'BEGIN { n = split("effect counts main-shown lands-as founder-paths-changed founder-path path paths-changed decision commit-subject confirm kept", L, " ") }
    { for (i = 1; i <= n; i++) if (index($0, L[i] ": ") == 1) c[L[i]]++ }
    END { for (i = 1; i <= n; i++) printf "%s:%d ", L[i], c[L[i]] }' "$TS4D_O"
}
_ts4d_listed() {   # HEAD BRANCH [FILE]: yes when a line holds HEAD whole and BRANCH shown escaped
  H="$1" B="$(_ts4_esc "$2")" LC_ALL=C awk 'index($0, ENVIRON["H"]) && index($0, ENVIRON["B"]) { f = 1 } END { print (f ? "yes" : "no") }' "${3:-$TS4D_O}"
}
_ts4d_nums() {   # HEAD...: the number each line that holds one of them carries before it, sorted
  HS="$*" LC_ALL=C awk '{ n = split(ENVIRON["HS"], h, " "); for (i = 1; i <= n; i++) { p = index($0, h[i]); if (!p) continue
        s = substr($0, 1, p - 1); if (match(s, /[0123456789]+/)) print substr(s, RSTART, RLENGTH); else print "none"; break } }' "$TS4D_O" | LC_ALL=C sort -n | tr '\n' ' '
}
_ts4d_on() {   # LABEL TEXT...: yes when a line that begins with LABEL holds each TEXT
  local k="$1" t r=yes; shift
  for t in "$@"; do [ "$(K="$k" T="$t" LC_ALL=C awk 'index($0, ENVIRON["K"]) == 1 && index($0, ENVIRON["T"]) { f = 1 } END { print f + 0 }' "$TS4D_O")" = 1 ] || r=no; done
  printf '%s' "$r"
}
_ts4d_commit() { H="$1" LC_ALL=C awk 'index($0, "commit: ") == 1 { n++; if ($0 != "commit: " ENVIRON["H"]) b++ } END { print (n ? "some" : "none") ", " b + 0 " other" }' "$TS4D_O"; }   # H: the lines "commit: "
_ts4d_hex() { case "$1" in ""|*[!0123456789abcdef]*) printf no ;; *) if [ "${#1}" -eq "$2" ]; then printf yes; else printf no; fi ;; esac; }   # TEXT LENGTH
_ts4d_no() {   # WHAT say|plain LINE...: the door refuses: a line starting refused: , exit 1, the log and the lock's marks as they were
  local w="$1" how="$2" n m; shift 2; n="$(_ts4_n "$TS4D_A")"; m="$(_ts4d_marks)"
  if [ "$how" = say ]; then _ts4_say "$TS4D_A" "$1"; else _ts4_plain "$TS4D_A" "$@"; fi
  _ts4_is "ts4 door D4: $w is refused: a line starting refused: , exit 1, nothing kept and the lock not run" \
    "exit $TS4_DRC; refused: $(_ts4_refused); kept: ${TS4_KEPT:-none}; log: $(if [ "$(_ts4_n "$TS4D_A")" = "$n" ]; then printf 'as it was'; else printf changed; fi); lock: $(if [ "$(_ts4d_marks)" = "$m" ]; then printf 'not run'; else printf ran; fi)" \
    "exit 1; refused: yes; kept: none; log: as it was; lock: not run" "$(_ts4_dwhy)"
}
_ts4d_not() {   # WHAT LINE...: after a card for hold of the held head, LINE... is not the confirmation: refused, exit 1, nothing kept
  local w="$1" n r; shift; n="$(_ts4_n "$TS4D_A")"; r="$(_ts4_closed "$TS4D_A")"
  _ts4_open "$TS4D_A" a "hold $TS4D_HH"; TS4D_F="$TS4_FOUR"
  case "$1" in four) set -- "$TS4D_F" ;; other-verb) set -- "authorize $TS4D_F" ;; wrong-then-right) set -- "hold $(_ts4_wrong "$TS4D_HH")" "hold $TS4D_F" ;;
    whole-id) set -- "hold $TS4D_HH" ;; one-pair) set -- "hold ${TS4D_F:0:2}" ;; end) set -- ;; esac
  _ts4_close a "$@"
  _ts4_is "ts4 door D6: $w is not the confirmation: the door prints refused: , exits 1, keeps nothing and leaves one row in refused.tsv" \
    "card: $(if [ -n "$TS4D_F" ]; then printf shown; else printf none; fi); exit $TS4_DRC; refused: $(_ts4_refused); kept: ${TS4_KEPT:-none}; statements: $(_ts4_n "$TS4D_A"); rows: $(( $(_ts4_closed "$TS4D_A") - r )) more" \
    "card: shown; exit 1; refused: yes; kept: none; statements: $n; rows: 1 more" "$(_ts4_dwhy)"
}

# ------------------------------------------------------------------ controls ---
is "ts4 door (control): the planted head's paths hold one escape, one carriage return, one tab and two newlines, its branch name a quote and U+009B, and its message two lines before the first empty one" \
  "$(_fx_git "$TS4D_S" ls-tree -r -z --name-only "$TS4D_HE" 2>/dev/null | LC_ALL=C od -An -v -tx1 | LC_ALL=C awk '{ for (i = 1; i <= NF; i++) c[$i]++ } END { print c["1b"] + 0, c["0d"] + 0, c["09"] + 0, c["0a"] + 0 }'); $(_fx_git "$TS4D_S" for-each-ref --format='%(refname)' refs/heads 2>/dev/null | LC_ALL=C od -An -v -tx1 | LC_ALL=C awk '{ for (i = 1; i <= NF; i++) c[$i]++ } END { print c["22"] + 0, c["9b"] + 0 }'); $(_fx_git "$TS4D_S" cat-file commit "$TS4D_HE" 2>/dev/null | LC_ALL=C awk 'b && $0 == "" { exit } b { n++ } !b && $0 == "" { b = 1 } END { print n + 0 }')" \
  "1 1 1 2; 1 1; 2"
is "ts4 door (control): git's own merge onto main is clean for dir, plain and big, conflicts for clash, and for same is main's own tree" \
  "$(for _ts4d_i in "$TS4D_HD" "$TS4D_HP" "$TS4D_HB" "$TS4D_HC" "$TS4D_HS"; do printf '%s ' "$(_ts4_kind "$TS4D_S" "$TS4D_M2" "$_ts4d_i")"; done)" \
  "tree tree tree conflict nothing "
TS4D_TD="$(_ts4_merge "$TS4D_S" "$TS4D_M2" "$TS4D_HD")"; TS4D_TP="$(_ts4_merge "$TS4D_S" "$TS4D_M2" "$TS4D_HP")"

# ------------------------------------------------------------------ opening, and what is read back (D1, D2, W7) ---
_ts4_init "$TS4D_A" "$TS4_ME" "$TS4D_S" --lock "$TS4D_X/mark.sh"; TS4D_ID="$TS4_ID"
TS4_ENV=(SSH_CONNECTION='192.0.2.1 50000 192.0.2.2 22'); _ts4_plain "$TS4D_A"; TS4_ENV=()
_ts4_is "ts4 door D1: with SSH_CONNECTION set the door prints a line starting refused: , exits 1 and reads nothing back" \
  "exit $TS4_DRC; refused: $(_ts4_refused); FELIX DOOR: $(_ts4_said 'FELIX DOOR' "$TS4D_O")" "exit 1; refused: yes; FELIX DOOR: no" "$(_ts4_dwhy)"
TS4_ENV=(SSH_TTY=/dev/ttys009); _ts4_plain "$TS4D_A"; TS4_ENV=()
_ts4_is "ts4 door D1: with SSH_TTY set the door prints a line starting refused: , exits 1 and reads nothing back" \
  "exit $TS4_DRC; refused: $(_ts4_refused); FELIX DOOR: $(_ts4_said 'FELIX DOOR' "$TS4D_O")" "exit 1; refused: yes; FELIX DOOR: no" "$(_ts4_dwhy)"
_ts4_plain "$TS4D_A"
_ts4_is "ts4 door D2, W7: with neither set and no statement yet, the door reads back FELIX DOOR with the authority's id, SHADOW and each why, main - and the word go, keeps nothing at the end of its input and exits 1" \
  "exit $TS4_DRC; id: $(I="${TS4D_ID:-none}" LC_ALL=C awk 'index($0, "FELIX DOOR") && index($0, ENVIRON["I"]) { f = 1 } END { print (f ? "yes" : "no") }' "$TS4D_O"); SHADOW: $(_ts4_said SHADOW "$TS4D_O"); why: $(_ts4_said 'not its own login' "$TS4D_O") $(_ts4_said 'no first start at the console' "$TS4D_O") $(_ts4_said 'the reach test has not passed' "$TS4D_O"); main: $(_ts4d_val main:); word: $(_ts4d_val word:); statements: $(_ts4_n "$TS4D_A")" \
  "exit 1; id: yes; SHADOW: yes; why: yes yes yes; main: -; word: go; statements: 0" "$(_ts4_dwhy)"

# ------------------------------------------------------------------ the first statement, kept and locked (D7, D9, D10) ---
_ts4_say "$TS4D_A" "start $TS4D_M2"
_ts4_is "ts4 door D7, D10, case 13: a confirmed start prints kept: statement 0 start COMMIT and then locked, exits 0, and the lock ran once, with no argument" \
  "exit $TS4_DRC; $TS4_KEPTL; kept before locked: $(LC_ALL=C awk 'index($0, "kept: ") == 1 && !k { k = NR } index($0, "locked") == 1 && !l { l = NR } END { print (k && l && k < l ? "yes" : "no") }' "$TS4D_O"); NOT LOCKED: $(_ts4_count 'NOT LOCKED' "$TS4D_O"); lock: $(cat "$TS4D_MK" 2>/dev/null | tr '\n' ' ')" \
  "exit 0; kept: statement 0 start $TS4D_M2; kept before locked: yes; NOT LOCKED: 0; lock: 0 " "$(_ts4_dwhy)"
_ts4_is "ts4 door D5 (rev 2): the card of the first start, which has no main yet, says main-shown: - and lands-as: main starts from this commit" \
  "$(_ts4_line 'main-shown: ' "$TS4D_O"); $(_ts4_line 'lands-as: ' "$TS4D_O")" "main-shown: -; lands-as: main starts from this commit" "$(_ts4_dwhy)"
_ts4_is "ts4 door D9: the log is refs/felix/door in the store; its first entry is a commit with no parent and no file" \
  "$(_ts4_sg "$TS4D_ST" rev-list --parents -n 1 refs/felix/door | LC_ALL=C awk '{ print NF - 1 " parent(s)" }'); $(_ts4_sg "$TS4D_ST" ls-tree -r refs/felix/door | LC_ALL=C awk 'END { print NR " file(s)" }')" "0 parent(s); 0 file(s)"

# ------------------------------------------------------------------ the list (D2, D3) ---
_ts4_plain "$TS4D_A"; cp "$TS4D_O" "$TS4/list.out" 2>/dev/null
_ts4_is "ts4 door D2: after the start the door reads back main as the store holds it" "$(_ts4d_val main:)" "$TS4D_M2" "$(_ts4_dwhy)"
_ts4_is "ts4 door D3: the door lists each candidate that waits on his word, its head whole and its branch shown escaped, and no head that is eligible, conflicts or changes nothing" \
  "$(_ts4d_listed "$TS4D_HD" dir) $(_ts4d_listed "$TS4D_HD" twin) $(_ts4d_listed "$TS4D_HB" big) $(_ts4d_listed "$TS4D_HG" long) $(_ts4d_listed "$TS4D_HE" "$TS4D_EB"); $(_ts4_said "$TS4D_HP" "$TS4D_O") $(_ts4_said "$TS4D_HH" "$TS4D_O") $(_ts4_said "$TS4D_HC" "$TS4D_O") $(_ts4_said "$TS4D_HS" "$TS4D_O") $(_ts4_said "$TS4D_R0" "$TS4D_O")" \
  "yes yes yes yes yes; no no no no no" "$(_ts4_dwhy)"
_ts4_is "ts4 door D3: the five entries are numbered from 1, and a line then counts the 11 other candidates" \
  "$(_ts4d_nums "$TS4D_HD" "$TS4D_HB" "$TS4D_HG" "$TS4D_HE"); others: $(LC_ALL=C awk 'index($0, "other") && (" " $0 " ") ~ /[^0123456789]11[^0123456789]/ { f = 1 } END { print (f ? "counted" : "not counted") }' "$TS4D_O")" \
  "1 2 3 4 5 ; others: counted" "$(_ts4_dwhy)"
TS4D_N="$(_ts4d_nums "$TS4D_HB")"; TS4D_N="${TS4D_N%% *}"
_ts4_a "$TS4D_A" tick
_ts4_is "ts4 door 2.5, D12: a tick shows that branch escaped as the door does, names its first founder path in the order git lists them, and prints no control byte of the worker's" \
  "$(LC_ALL=C awk -F'\t' -v h="$TS4D_HE" 'NF == 5 && $3 == h { print $4 "|" $2 "|" $5 }' "$TS4/o"); raw: $(LC_ALL=C tr -cd '\000-\010\013-\037\177\233' < "$TS4/o" | wc -c | tr -d ' ')" \
  "$(_ts4_esc "$TS4D_EB")"'|waits|changes "notes/one\x09tab", which waits for the founder'"'"'s authorization of this head; raw: 0' "$(_ts4_why)"

# ------------------------------------------------------------------ what the door refuses to take (D4) ---
_ts4d_no "a verb that is not one of the nine" say "approve $TS4D_HD"
_ts4_is "ts4 door 3: a refusal is a line on the door's standard output" "$(_ts4_yn test "$(_ts4_count 'refused: ' "$TS4D_O")" -gt 0)" yes "$(_ts4_dwhy)"
_ts4d_no "a commit the store does not hold" say "hold $TS4_NOPE"
_ts4d_no "a number the list does not have" say "hold 99"
_ts4d_no "the number 0" say "hold 0"
_ts4d_no "an id of 39 digits" say "hold ${TS4D_HD:0:39}"
_ts4d_no "an override of a head that conflicts with main" say "override $TS4D_HC"
_ts4d_no "an override of a head that changes nothing" say "override $TS4D_HS"
mkdir -p "$TS4D_A/reach" 2>/dev/null && printf 'felix-reach-witness/v1\na record made by hand\n' > "$TS4D_A/reach/rec.txt"
_ts4d_no "reach pass where the statement would not be given at the console" plain "reach pass $TS4D_A/reach/rec.txt" "reach pass"

# ------------------------------------------------------------------ a card, and the statement it becomes (D3 to D9) ---
TS4D_D1="$(date -u +%Y-%m-%d)"; _ts4_open "$TS4D_A" a "authorize ${TS4D_N:-99}"; cp "$TS4D_O" "$TS4/card.out" 2>/dev/null; TS4D_F="$TS4_FOUR"
_ts4_is "ts4 door D3, D6: a number from the list names that entry's head: the card for authorize N has a line confirm: and the head whole, with two pairs of its characters in square brackets, the first starting in its first nineteen places and the second in places twenty to thirty-eight" \
  "$TS4_HEAD; ${#TS4_FOUR} in brackets; the id's own, where D6 puts them: $(_ts4_onid "$TS4D_HB")" "$TS4D_HB; 4 in brackets; the id's own, where D6 puts them: yes" "$(_ts4_dwhy)"
_ts4_is "ts4 door D5, case 8: the card of thirty paths whose last in tree order is the founder's holds each label once, one founder-path line and twenty path lines" \
  "$(_ts4d_labels)" "effect:1 counts:1 main-shown:1 lands-as:1 founder-paths-changed:1 founder-path:1 path:20 paths-changed:1 decision:1 commit-subject:1 confirm:1 kept:0 " "$(_ts4_dwhy)"
_ts4_is "ts4 door case 8: that founder path is listed before each other path, whole and escaped, with a count of 1, and 9 of the others are said to be not listed" \
  "$(LC_ALL=C awk 'index($0, "founder-path: \"docs/direction.md\"") == 1 && !f { f = NR } index($0, "path: ") == 1 && !p { p = NR } END { print (f && p && f < p ? "before" : "not before") }' "$TS4D_O"); $(_ts4_line 'founder-paths-changed: ' "$TS4D_O"); $(_ts4_said '(not listed above: 9)' "$TS4D_O")" \
  "before; founder-paths-changed: 1; yes" "$(_ts4_dwhy)"
_ts4_is "ts4 door D5 (a reading): paths-changed counts every changed path, the founder's among them" "$(_ts4_line 'paths-changed: ' "$TS4D_O")" "paths-changed: 30 (not listed above: 9)"
_ts4_is "ts4 door D5: the card says the statement does not count and why, the commit whole, main as shown, and the tree it would land as" \
  "$(_ts4_yn test -n "$(_ts4d_val 'effect: ')"); $(_ts4_count 'counts: no: ' "$TS4D_O"); $(_ts4d_commit "$TS4D_HB"); $(_ts4_line 'main-shown: ' "$TS4D_O"); $(_ts4_line 'lands-as: ' "$TS4D_O")" \
  "yes; 1; some, 0 other; main-shown: $TS4D_M2; lands-as: tree $(_ts4_merge "$TS4D_S" "$TS4D_M2" "$TS4D_HB")" "$(_ts4_dwhy)"
_ts4_dd "$TS4D_A" "$TS4D_HB"
_ts4_is "ts4 door D5, D11: the card's decision is what decide says of the head, and its branch and subject are in quotes and labelled as the worker's word" \
  "decide: ${TS4_DEC%%|*}; card: $(_ts4d_on 'decision: ' "${TS4_DEC%%|*}"); $(_ts4d_on 'carried-by: ' '"big"' worker) $(_ts4d_on 'commit-subject: ' '"thirty paths"' worker)" "decide: waits; card: yes; yes yes" "$(_ts4_dwhy)"
_ts4_close a "authorize $TS4D_F"; TS4D_D2="$(date -u +%Y-%m-%d)"; TS4D_K="$TS4_KEPT"; _ts4_msg "$TS4D_A" "$(_ts4_tip "$TS4D_A")" > "$TS4/kept.msg" 2>/dev/null
_ts4_is "ts4 door D7: the verb, a space and the four characters confirm it: the door prints kept: statement 1 authorize and the head, and exits 0" "exit $TS4_DRC; $TS4_KEPTL" "exit 0; kept: statement 1 authorize $TS4D_HB" "$(_ts4_dwhy)"
_ts4_is "ts4 door D8: the kept statement is felix-door/v1 and the fourteen fields, in the spec's order and nothing else" \
  "$(LC_ALL=C awk '{ i = index($0, ": "); printf "%s ", (i ? substr($0, 1, i - 1) : $0) }' "$TS4/kept.msg")" "felix-door/v1 authority serial prev verb commit tree main card key given result witness nonce at "
_ts4_is "ts4 door D8, D9: it names the authority, its place, the entry before it, the verb, the head, no tree, main as he was shown it, no key, shadow, and no result or witness" \
  "$(_ts4_fs "$TS4D_A" 1 'authority serial prev verb commit tree main key given result witness')" "${TS4D_ID:-no id}|1|$(_ts4_rev "$TS4D_A" 0)|authorize|$TS4D_HB|-|$TS4D_M2|none|shadow|-|-"
TS4D_V="$(_ts4_fs "$TS4D_A" 1 at)"
_ts4_is "ts4 door D8: card is 40 hex digits, nonce 32, and at a UTC time that begins with the date" \
  "$(_ts4d_hex "$(_ts4_fs "$TS4D_A" 1 card)" 40) $(_ts4d_hex "$(_ts4_fs "$TS4D_A" 1 nonce)" 32) $(case "$TS4D_V" in ("$TS4D_D1"*|"$TS4D_D2"*) printf yes ;; (*) printf 'no [%s]' "$TS4D_V" ;; esac)" "yes yes yes"
_ts4_is "ts4 door D5: the card printed the statement as it was kept: each line of the kept message but card: is a line of the card" \
  "lines: $(LC_ALL=C awk 'END { print NR }' "$TS4/kept.msg"); not on the card: [$(LC_ALL=C awk 'FILENAME == ARGV[1] { c[$0] = 1; next } index($0, "card: ") != 1 && index($0, "at: ") != 1 && !($0 in c) { printf "%s;", $0 }' "$TS4/card.out" "$TS4/kept.msg" 2>/dev/null)]" "lines: 15; not on the card: []"
_ts4_is "ts4 door D5 (a reading): and the time it was kept with is the time the card showed" "$(K="$(_ts4_line 'at: ' "$TS4/kept.msg")" LC_ALL=C awk '$0 == ENVIRON["K"] && $0 != "" { f = 1 } END { print (f ? "shown" : "not shown") }' "$TS4/card.out" 2>/dev/null)" "shown"
_ts4_is "ts4 door D9: the entry is a commit whose one parent is the entry before it, and it holds no file" \
  "$(_ts4_sg "$TS4D_ST" rev-list --parents -n 1 refs/felix/door | LC_ALL=C awk -v p="$(_ts4_rev "$TS4D_A" 0)" '{ print NF - 1 " parent(s), " ($2 == p && p != "" ? "the entry before" : "another") }'); $(_ts4_sg "$TS4D_ST" ls-tree -r refs/felix/door | LC_ALL=C awk 'END { print NR " file(s)" }')" \
  "1 parent(s), the entry before; 0 file(s)"

# ------------------------------------------------------------------ other cards, each closed by the end of its input (D5, D6, D12) ---
_ts4_open "$TS4D_A" a "hold $TS4D_HP"; TS4D_V="$(_ts4d_labels)|$(_ts4_line 'lands-as: ' "$TS4D_O")|$(_ts4_line 'founder-paths-changed: ' "$TS4D_O")|$(_ts4_line 'path: ' "$TS4D_O")|$(_ts4_line 'paths-changed: ' "$TS4D_O")|$(_ts4d_on 'decision: ' eligible)"
TS4D_N0="$(_ts4_n "$TS4D_A")"; _ts4_close a
_ts4_is "ts4 door D5: the card of an ordinary change holds no founder path, its one path in quotes, the tree it lands as, and that it is eligible" \
  "$TS4D_V" "effect:1 counts:1 main-shown:1 lands-as:1 founder-paths-changed:1 founder-path:0 path:1 paths-changed:1 decision:1 commit-subject:1 confirm:1 kept:0 |lands-as: tree $TS4D_TP|founder-paths-changed: 0|path: \"notes/plain.txt\"|paths-changed: 1 (not listed above: 0)|yes" "$(_ts4_dwhy)"
_ts4_is "ts4 door D6: the end of the input after a card closes the statement: the door prints refused: , exits 1 and keeps nothing" \
  "exit $TS4_DRC; refused: $(_ts4_refused); kept: ${TS4_KEPT:-none}; statements: $(_ts4_n "$TS4D_A")" "exit 1; refused: yes; kept: none; statements: ${TS4D_N0:-none}" "$(_ts4_dwhy)"
_ts4_open "$TS4D_A" a "hold $TS4D_HS"; TS4D_V="$(_ts4_count 'lands-as: nothing' "$TS4D_O") $(_ts4d_on 'decision: ' nothing)"; _ts4_close a
_ts4_open "$TS4D_A" a "hold $TS4D_HC"; TS4D_V="$TS4D_V; $(_ts4_count 'lands-as: nothing' "$TS4D_O") $(_ts4d_on 'decision: ' conflict)"; _ts4_close a
_ts4_is "ts4 door D5: the card of a head that changes nothing, and of one that conflicts with main, says lands-as: nothing and the decision" "$TS4D_V" "1 yes; 1 yes" "$(_ts4_dwhy)"
_ts4_open "$TS4D_A" a "authorize $TS4D_HG"
_ts4_is "ts4 door D5: a founder path of some 310 bytes is shown whole and escaped, and another path as long is cut: its line is at most 230 bytes and does not hold it whole" \
  "$(_ts4_count "founder-path: $(_ts4_esc "$TS4D_LF")" "$TS4D_O"); $(LC_ALL=C awk 'index($0, "path: \"plain/aaaa") == 1 { print (length($0) <= 230 ? "cut" : "a line of " length($0)) }' "$TS4D_O"); whole: $(_ts4_said "$TS4D_LP" "$TS4D_O")" "1; cut; whole: no" "$(_ts4_dwhy)"
_ts4_close a
_ts4_open "$TS4D_A" a "hold $TS4D_HW"
_ts4_is "ts4 door case 19, D5a: a subject and a path padded so that a window of 80 columns would wrap them onto a row reading counts: yes put no such row in the door's output: no row is longer than 78 characters, the long lines are folded into rows that start with four spaces, a bar and a space, and the rows join back to the subject and the path whole" \
  "card: $(if [ -n "$TS4_FOUR" ]; then printf shown; else printf none; fi); $(LC_ALL=C awk '{ if (length($0) > m) m = length($0); l = $0; sub(/^ +/, "", l); if (index(l, "counts: yes") == 1) c++; if (index($0, "    | ") == 1) k++ }
      END { printf "longest row: %s; rows reading counts: yes: %d; folded: %s", (NR && m <= 78 ? "78 or less" : m + 0), c + 0, (k ? "yes" : "no") }' "$TS4/door.a.raw"); subject: $(_ts4d_on 'commit-subject: ' "$(_ts4_esc "$TS4D_WS")"); path: $(_ts4_count "path: $(_ts4_esc "$TS4D_WP")" "$TS4D_O")" \
  "card: shown; longest row: 78 or less; rows reading counts: yes: 0; folded: yes; subject: yes; path: 1" "$(_ts4_dwhy)"
_ts4_close a
_ts4_open "$TS4D_A" a "authorize $TS4D_HE"
_ts4_is "ts4 door case 7, D5: the card of the planted head prints no control byte and no U+009B of the worker's, and its confirm line holds the real head" \
  "card: $(if [ -n "$TS4_FOUR" ]; then printf shown; else printf none; fi); raw: $(LC_ALL=C tr -cd '\000-\010\013-\037\177\233' < "$TS4D_O" | wc -c | tr -d ' '); confirm names: $TS4_HEAD" "card: shown; raw: 0; confirm names: $TS4D_HE" "$(_ts4_dwhy)"
_ts4_is "ts4 door case 7, D5: no line of that card starts with the worker's bytes: it holds one counts, one decision, one confirm and no kept line, five founder-path lines and two path lines" \
  "$(_ts4d_labels)" "effect:1 counts:1 main-shown:1 lands-as:1 founder-paths-changed:1 founder-path:5 path:2 paths-changed:1 decision:1 commit-subject:1 confirm:1 kept:0 " "$(_ts4_dwhy)"
_ts4_is "ts4 door case 6, case 7, W9: each path that holds a byte outside printable ASCII is a founder path, shown whole in quotes with the byte as \\xNN" \
  "$(_ts4_count "founder-path: $(_ts4_esc "$TS4D_E1")" "$TS4D_O") $(_ts4_count "founder-path: $(_ts4_esc "$TS4D_E2")" "$TS4D_O") $(_ts4_count 'founder-path: "notes/y\x0acounts: yes"' "$TS4D_O") $(_ts4_count 'founder-path: "notes/z\x0ddecision: eligible"' "$TS4D_O") $(_ts4_count 'founder-path: "notes/one\x09tab"' "$TS4D_O") $(_ts4_line 'founder-paths-changed: ' "$TS4D_O")" \
  "1 1 1 1 1 founder-paths-changed: 5" "$(_ts4_dwhy)"
_ts4_is "ts4 door D12: a quote and a backslash in a path are shown as \\x22 and \\x5c, and a path of printable ASCII, look-alikes and all, as it is" \
  "$(_ts4_count 'path: "notes/q\x22uote\x5cback"' "$TS4D_O") $(_ts4_count "path: \"$TS4D_E7\"" "$TS4D_O")" "1 1" "$(_ts4_dwhy)"
_ts4_is "ts4 door case 7, D5: the branch and the subject of that head are shown escaped, in quotes, and labelled as the worker's word" \
  "$(_ts4d_on 'carried-by: ' "$(_ts4_esc "$TS4D_EB")" worker) $(_ts4d_on 'commit-subject: ' '"fix \x1b[31m\x22red\x22 back\x5cslash' worker)" "yes yes" "$(_ts4_dwhy)"
_ts4_close a
_ts4_open "$TS4D_A" a "authorize $TS4D_HD"
_ts4_is "ts4 door D5: a head two branches carry names both, each shown escaped" "$(_ts4d_on 'carried-by: ' '"dir"') $(_ts4d_on 'carried-by: ' '"twin"'); $(_ts4_line 'lands-as: ' "$TS4D_O")" "yes yes; lands-as: tree $TS4D_TD" "$(_ts4_dwhy)"
_ts4_close a "authorize $TS4_FOUR"; TS4D_KD="$TS4_KEPT"

# ------------------------------------------------------------------ one try (D6, case 9) ---
_ts4d_not "a wrong four, with the right line typed after it," wrong-then-right
_ts4d_not "the four characters under another verb" other-verb
_ts4d_not "the four characters with no verb" four
_ts4d_not "the verb and the whole id" whole-id
_ts4d_not "the verb and the first pair alone" one-pair
TS4D_NON=""; TS4D_PL=""; TS4D_V=0; TS4D_W=0; TS4D_RC=""; TS4D_N0="$(_ts4_closed "$TS4D_A")"
for _ts4d_i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  _ts4_open "$TS4D_A" a "hold $TS4D_HH"
  [ "$_ts4d_i" != 1 ] || TS4D_RC="$(_ts4d_val 'refused-confirmations:')"
  [ -z "$TS4_FOUR" ] || { TS4D_V=$((TS4D_V + 1)); TS4D_PL="$TS4D_PL$TS4_AT$TS4_NL"; TS4D_NON="$TS4D_NON$(_ts4d_val 'nonce: ')$TS4_NL"; }
  [ "$(_ts4_onid "$TS4D_HH")" != yes ] || [ "$TS4_HEAD" != "$TS4D_HH" ] || TS4D_W=$((TS4D_W + 1))
  _ts4_close a
done
_ts4_is "ts4 door case 9, D6: each of twelve asks about one commit shows a card whose brackets hold the id's own four characters at their place, under a nonce of 32 hex digits no other ask had" \
  "cards: $TS4D_V; on the id: $TS4D_W; nonces: $(printf '%s' "$TS4D_NON" | LC_ALL=C sort -u | LC_ALL=C awk 'length($0) == 32 && $0 !~ /[^0123456789abcdef]/ { n++ } END { print n + 0 }')" "cards: 12; on the id: 12; nonces: 12"
_ts4_is "ts4 door case 9, D6: over those twelve asks the brackets stand in more than one place" "$(printf '%s' "$TS4D_PL" | LC_ALL=C sort -u | LC_ALL=C awk 'END { print (NR > 1 ? "more than one place" : NR " place(s)") }')" "more than one place"
_ts4_is "ts4 door D2, D6: after five confirmations that failed since the last kept statement, the next door reads back refused-confirmations: 5" "${TS4D_RC:-no such line}" "5"
_ts4_is "ts4 door D6: the end of the input after a card is a missing confirmation: those twelve asks left twelve rows in refused.tsv" "$(( $(_ts4_closed "$TS4D_A") - ${TS4D_N0:-0} )) rows more" "12 rows more"
TS4D_N0="$(_ts4_closed "$TS4D_A")"; TS4D_V="$(_ts4_n "$TS4D_A")"; _ts4_plain "$TS4D_A" "hold $TS4D_HH" "hold $(_ts4_wrong "$TS4D_HH")"
_ts4_is "ts4 door case 16: a door fed a statement and a guessed confirmation, with the card unread, keeps nothing and leaves a row in refused.tsv" \
  "exit $TS4_DRC; refused: $(_ts4_refused); kept: ${TS4_KEPT:-none}; statements: $(_ts4_n "$TS4D_A"); rows: $(( $(_ts4_closed "$TS4D_A") - ${TS4D_N0:-0} )) more" "exit 1; refused: yes; kept: none; statements: ${TS4D_V:-none}; rows: 1 more" "$(_ts4_dwhy)"

# ------------------------------------------------------------------ two doors (D7, case 12) ---
TS4D_N0="$(_ts4_n "$TS4D_A")"; TS4D_V="$(_ts4d_marks)"
_ts4_open "$TS4D_A" a "hold $TS4D_HH"; TS4D_F="$TS4_FOUR"
_ts4_open "$TS4D_A" b "hold $TS4D_HP"; _ts4_close b "hold $TS4_FOUR"; TS4D_W="second door: exit $TS4_DRC, kept ${TS4_KEPT:-none}"
_ts4_close a "hold $TS4D_F"
_ts4_is "ts4 door case 12, D7: a statement confirmed after another door kept one is refused with the log moved, and the log holds the one" \
  "$TS4D_W; first door: card $(if [ -n "$TS4D_F" ]; then printf shown; else printf none; fi), exit $TS4_DRC, refused: $(_ts4_refused), the log moved: $(_ts4_said 'the log moved' "$TS4D_O" "$TS4/door.a.err"), kept ${TS4_KEPT:-none}; statements: $(_ts4_n "$TS4D_A"); the last names: $(_ts4_fs "$TS4D_A" "${TS4D_N0:-0}" commit)" \
  "second door: exit 0, kept ${TS4D_N0:-none}; first door: card shown, exit 1, refused: yes, the log moved: yes, kept none; statements: $(( ${TS4D_N0:-0} + 1 )); the last names: $TS4D_HP" "$(_ts4_dwhy)"
_ts4_is "ts4 door case 13: over those two doors the lock ran once, for the statement that was kept" "$(( $(_ts4d_marks) - ${TS4D_V:-0} )) with $(tail -1 "$TS4D_MK" 2>/dev/null) argument(s)" "1 with 0 argument(s)"

# ------------------------------------------------------------------ stop and go, and the lock (D6, D10) ---
_ts4_plain "$TS4D_A" stop go
_ts4_is "ts4 door D6: stop is confirmed by the word stop alone: go after it is refused, and nothing is kept" "exit $TS4_DRC; refused: $(_ts4_refused); kept: ${TS4_KEPT:-none}" "exit 1; refused: yes; kept: none" "$(_ts4_dwhy)"
_ts4_plain "$TS4D_A" stop stop; TS4D_K="$TS4_KEPT"
_ts4_is "ts4 door D6, D8: stop, then stop, is kept: a statement with the verb stop, no commit and no tree" "exit $TS4_DRC; $(_ts4_fs "$TS4D_A" "${TS4D_K:-999}" 'verb commit tree given')" "exit 0; stop|-|-|shadow" "$(_ts4_dwhy)"
TS4D_N0="$(_ts4_closed "$TS4D_A")"; TS4D_V="$(_ts4_n "$TS4D_A")"; _ts4_plain "$TS4D_A" go go
_ts4_is "ts4 door D6: go, then go, typed with the card unread, is not the confirmation of go: nothing is kept, and refused.tsv has one row more" \
  "exit $TS4_DRC; refused: $(_ts4_refused); kept: ${TS4_KEPT:-none}; statements: $(_ts4_n "$TS4D_A"); rows: $(( $(_ts4_closed "$TS4D_A") - ${TS4D_N0:-0} )) more" "exit 1; refused: yes; kept: none; statements: ${TS4D_V:-none}; rows: 1 more" "$(_ts4_dwhy)"
_ts4_open "$TS4D_A" a go; TS4D_V="$(_ts4d_val 'nonce: ')"
TS4D_V="word: $(_ts4d_val word:); refused-confirmations: $(_ts4d_val 'refused-confirmations:'); asked against: $TS4_KIND; the nonce's own, where D6 puts them: $(_ts4_onid "$TS4D_V"); whole: $(if [ -n "$TS4_HEAD" ] && [ "$TS4_HEAD" = "$TS4D_V" ]; then printf yes; else printf no; fi)"
_ts4_close a "go $TS4_FOUR"
_ts4_is "ts4 door D2, D6: the next door reads back the word stop and the one refused confirmation, and asks for go against the statement's nonce: a line confirm: nonce and the nonce whole, two pairs of it in brackets, the first starting in its first fifteen places and the second in places sixteen to thirty; go and those four characters keep it" \
  "$TS4D_V; exit $TS4_DRC; $(_ts4_fs "$TS4D_A" "${TS4_KEPT:-999}" verb)" "word: stop; refused-confirmations: 1; asked against: nonce; the nonce's own, where D6 puts them: yes; whole: yes; exit 0; go" "$(_ts4_dwhy)"
_ts4_conf "$TS4D_A" lock; _ts4_say "$TS4D_A" "release $TS4D_R0"; TS4D_V="$(_ts4d_val 'refused-confirmations:')"
_ts4_is "ts4 door D2: after a kept statement the next door reads back no refused confirmation" "kept: $(_ts4_yn test -n "$TS4_KEPT"); refused-confirmations: $(if [ -z "$TS4D_V" ] || [ "$TS4D_V" = 0 ]; then printf none; else printf '%s' "$TS4D_V"; fi)" "kept: yes; refused-confirmations: none" "$(_ts4_dwhy)"
_ts4_is "ts4 door D10: with no lock set a kept statement is followed by a line starting NOT LOCKED, and the exit status stays 0" \
  "exit $TS4_DRC; kept: $(_ts4_yn test -n "$TS4_KEPT"); NOT LOCKED: $(_ts4_count 'NOT LOCKED' "$TS4D_O"); locked: $(_ts4_count locked "$TS4D_O")" "exit 0; kept: yes; NOT LOCKED: 1; locked: 0" "$(_ts4_dwhy)"
_ts4_conf "$TS4D_A" lock "$TS4D_X/fail.sh"; _ts4_say "$TS4D_A" "release $TS4D_R1"
_ts4_is "ts4 door D10: with a lock that fails, the statement is kept, the lock was run, the door prints NOT LOCKED, and the exit status stays 0" \
  "exit $TS4_DRC; kept: $(_ts4_yn test -n "$TS4_KEPT"); ran: $(_ts4_yn test -e "$TS4D_X/fail.ran"); NOT LOCKED: $(_ts4_count 'NOT LOCKED' "$TS4D_O"); locked: $(_ts4_count locked "$TS4D_O")" "exit 0; kept: yes; ran: yes; NOT LOCKED: 1; locked: 0" "$(_ts4_dwhy)"
_ts4_conf "$TS4D_A" lock "$TS4D_X/mark.sh"

# ------------------------------------------------------------------ the last five statements, and a permission in effect (D2) ---
for _ts4d_i in "$TS4D_R2" "$TS4D_R3" "$TS4D_R4" "$TS4D_R5"; do _ts4_say "$TS4D_A" "release $_ts4d_i"; done
_ts4_plain "$TS4D_A"
_ts4_is "ts4 door D2: the door reads back the last five statements, here releases of five heads no list entry names, and not the one before them" \
  "$(for _ts4d_i in "$TS4D_R1" "$TS4D_R2" "$TS4D_R3" "$TS4D_R4" "$TS4D_R5" "$TS4D_R0"; do printf '%s ' "$(_ts4_said "${_ts4d_i:0:12}" "$TS4D_O")"; done)statements: $(_ts4_n "$TS4D_A")" "yes yes yes yes yes no statements: 12" "$(_ts4_dwhy)"
_ts4_is "ts4 door D2: and the authorization still in effect, of a head that no longer waits and that the last five do not hold, with its number, on a line starting in-effect: " \
  "$(_ts4_numon 'in-effect: ' "${TS4D_KD:-none}" "$TS4D_O")" "yes" "$(_ts4_dwhy)"

# ------------------------------------------------------------------ a source that cannot be read, the brake, and the time limit (D3, D6, D13) ---
mv "$TS4D_S" "$TS4D_S.away"; _ts4_plain "$TS4D_A"; TS4D_V="listed: $(_ts4d_listed "$TS4D_HG" long); says so: $(_ts4_said source "$TS4D_O" "$TS4/door.a.err")"
_ts4_say "$TS4D_A" "hold $TS4D_HG"
_ts4_is "ts4 door D3: when the source cannot be read the door says so, lists what the store holds, and still keeps a statement about it" "$TS4D_V; exit $TS4_DRC; kept: $(_ts4_fs "$TS4D_A" "${TS4_KEPT:-999}" 'verb commit')" "listed: yes; says so: yes; exit 0; kept: hold|$TS4D_HG" "$(_ts4_dwhy)"
TS4D_N0="$(_ts4_n "$TS4D_A")"; _ts4_brake "$TS4D_A" stop; TS4D_W="$(_ts4_dwhy)"
TS4D_V="exit $TS4_DRC; kept: ${TS4_KEPT:-none}; $(_ts4_fs "$TS4D_A" "${TS4_KEPT:-999}" 'verb commit'); read back: $(_ts4_said 'FELIX DOOR' "$TS4D_O"); lists a head that waits: $(_ts4_said "$TS4D_HE" "$TS4D_O")"
TS4_DARG=(hold); _ts4_plain "$TS4D_A" "hold $TS4D_HG" "hold $(_ts4_wrong "$TS4D_HG")"; TS4_DARG=(); mv "$TS4D_S.away" "$TS4D_S"
_ts4_is "ts4 door case 20, D13: with a source that cannot be read, felix door stop reads back, lists nothing and keeps a stop, confirmed by stop; and felix door takes no other argument: felix door hold keeps nothing" \
  "$TS4D_V; door hold: $(if [ "$TS4_DRC" = 0 ]; then printf 'exit 0'; else printf 'no exit 0'; fi), kept ${TS4_KEPT:-none}, statements: $(_ts4_n "$TS4D_A")" \
  "exit 0; kept: ${TS4D_N0:-none}; stop|-; read back: yes; lists a head that waits: no; door hold: no exit 0, kept none, statements: $(( ${TS4D_N0:-0} + 1 ))" "$TS4D_W"
TS4D_N0="$(_ts4_n "$TS4D_A")"; TS4_TTL=2; TS4_WAIT=40; _ts4_open "$TS4D_A" a "hold $TS4D_HH"; TS4D_F="$TS4_FOUR"; _ts4_close a -wait; TS4_TTL=100; TS4_WAIT=90
_ts4_is "ts4 door D6: with FELIX_DOOR_TTL at 2 and no line typed, the door closes the statement by itself: refused: , exit 1, nothing kept" \
  "card: $(if [ -n "$TS4D_F" ]; then printf shown; else printf none; fi); ended by itself: $(if [ -z "$TS4_STUCK" ]; then printf yes; else printf no; fi); exit $TS4_DRC; refused: $(_ts4_refused); statements: $(_ts4_n "$TS4D_A")" \
  "card: shown; ended by itself: yes; exit 1; refused: yes; statements: ${TS4D_N0:-none}" "$(_ts4_dwhy)"
TS4_STUCK=""
_ts4_is "ts4 door case 9: over this part's asks, at least twenty, the brackets stood in more than one place" \
  "$(if [ "$TS4_ASKS" -ge 20 ]; then printf 'at least twenty asks'; else printf '%s asks' "$TS4_ASKS"; fi); $(printf '%s' "$TS4_PLACES" | tr ' ' '\n' | LC_ALL=C sort -u | LC_ALL=C awk 'NF { n++ } END { print (n > 1 ? "more than one place" : n + 0 " place(s)") }')" "at least twenty asks; more than one place"
_ts4_is "ts4 door D5a: over every door of this part, no row is longer than 78 characters, and long lines were folded into rows that start with four spaces, a bar and a space" \
  "$(LC_ALL=C awk '{ if (length($0) > m) m = length($0); if (index($0, "    | ") == 1) k++ } END { printf "rows: %s; longest: %s; folded rows: %s", (NR > 100 ? "more than a hundred" : NR + 0), (m <= 78 ? "78 or less" : m), (k ? "some" : "none") }' "$TS4/doors.raw" 2>/dev/null)" \
  "rows: more than a hundred; longest: 78 or less; folded rows: some"

_ts4_end
unset TS4D_S TS4D_A TS4D_ST TS4D_X TS4D_O TS4D_MK TS4D_M1 TS4D_M2 TS4D_HD TS4D_HP TS4D_HH TS4D_HC TS4D_HS TS4D_HB TS4D_HG TS4D_HE TS4D_P TS4D_V TS4D_W TS4D_LF TS4D_LP \
  TS4D_EB TS4D_E1 TS4D_E2 TS4D_E3 TS4D_E4 TS4D_E5 TS4D_E6 TS4D_E7 TS4D_R0 TS4D_R1 TS4D_R2 TS4D_R3 TS4D_R4 TS4D_R5 TS4D_TD TS4D_TP TS4D_ID TS4D_N TS4D_N0 TS4D_F TS4D_K \
  TS4D_KD TS4D_D1 TS4D_D2 TS4D_NON TS4D_PL TS4D_RC TS4D_WS TS4D_WP TS4D_HW _ts4d_i
# <<< trust-step4-door
