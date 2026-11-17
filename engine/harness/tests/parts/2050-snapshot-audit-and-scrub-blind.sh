printf '\nsnapshot audit and scrub: the rules as they stand, and the report of each rewrite a person must read (audit b22, blind)\n'
# Written blind on 2026-10-24 from the contract alone (docs/2026-10-24-audit-fixes/
# b22-snapshot-builds-is-tested-and-ships-the.md: B1 to B18, assertions A1 to A19). Neither
# script was read. projects/felix/snapshot-audit.sh and snapshot-scrub.sh, as they ship beside
# this harness, are run as black boxes over the contract's fixtures FA and FS, built here under
# $TMP. Every assertion but A18 is a control: the contract measured the scripts of 0.49.307
# printing what it asks. A18 is red until the scrub reports, on stdout, each line that its
# halves or stand-in rule rewrote (B18): those two rules can take ordinary words, and only a
# person can tell an ordinary word from a deliberately split name.
#
# Readings, where the contract leaves room:
# - Each script is run by bash from the fixture's own directory (ROOT for the audit, the
#   case's directory for the scrub), so a path in the paths or in LIST reads the same whether
#   the script takes it from its working directory or from ROOT. The audit's stdin is the
#   paths, NUL-separated and NUL-ended; the scrub's is /dev/null. A run that has not ended in
#   120 s is ended by an alarm (exit 142), so nothing here can stall.
# - B8 and B11 say a line gets exactly one row, so A2 reads a.md 1's rows as exactly the one
#   row it names. Every other expected row is looked for among the rows of its line, and a
#   line the contract marks none has no row at all.
# - B1 and B13 each list three refusals; A1 and A13 assert all of them, a missing path
#   standing for "not a file" and "not a directory".
# - The scrub's report lines are compared as a set (B18 gives no order); any stdout line that
#   is not one of them is kept, in brackets, so "exactly six" is what is compared.
# - AUTHOR, OTHER and every planted address are put together at run time from parts, so no
#   line of this file is an address (B34): the real snapshot audits this file when it
#   publishes it.

_b22a="$TMP/b22-audit"; mkdir -p "$_b22a"; _b22a="$(cd "$_b22a" && pwd -P)"
_b22a_dir="$(cd "$REAL_HARNESS/../.." 2>/dev/null && pwd)/projects/felix"
_b22a_sa="$_b22a_dir/snapshot-audit.sh"; _b22a_ss="$_b22a_dir/snapshot-scrub.sh"
_b22a_why=""
{ [ -f "$_b22a_sa" ] && [ -f "$_b22a_ss" ]; } || _b22a_why="no projects/felix/snapshot-*.sh beside this harness"
command -v perl >/dev/null 2>&1 || _b22a_why="${_b22a_why:-no perl on PATH, which the runs here are timed by}"
# NAME GOT WANT: the assertion, or a skip naming why no run could be made. Every name is
# emitted on every run, whatever the scripts answered.
_b22a_is() { if [ -n "$_b22a_why" ]; then skip "$1" "$_b22a_why"; else is "$1" "$2" "$3"; fi; }

# NAME DIR STDIN SCRIPT ARGS...: SCRIPT run by bash in DIR with STDIN, ended after 120 s;
# $_b22a/NAME.out, NAME.err and NAME.rc keep what it printed and how it ended.
_b22a_run() {
  local n="$1" d="$2" i="$3"; shift 3
  : > "$_b22a/$n.out"; : > "$_b22a/$n.err"
  ( cd "$d" && perl -e 'alarm shift @ARGV; exec { $ARGV[0] } @ARGV or exit 127' 120 bash "$@" \
      < "$i" > "$_b22a/$n.out" 2> "$_b22a/$n.err" )
  printf '%s\n' "$?" > "$_b22a/$n.rc"
}
_b22a_rc() {  # NAME -> "exit N", or what kept it from ending on its own
  local r; r="$(cat "$_b22a/$1.rc" 2>/dev/null)"
  case "$r" in
    '') printf 'exit unknown: %s was not run' "$1" ;;
    142) printf 'exit 142: %s was ended after 120 s' "$1" ;;
    *) printf 'exit %s' "$r" ;;
  esac
}
_b22a_stop() {  # NAME -> "exit non-zero", or how it ended when that was 0, the alarm or no run
  local r; r="$(cat "$_b22a/$1.rc" 2>/dev/null)"
  case "$r" in ''|0|142) _b22a_rc "$1" ;; *) printf 'exit non-zero' ;; esac
}
_b22a_err() {  # NAME TEXT -> "says TEXT" when NAME's stderr holds TEXT, else what it said
  if LC_ALL=C grep -F -e "$2" "$_b22a/$1.err" >/dev/null 2>&1; then printf 'says %s' "$2"
  else printf '[%s stderr: %s]' "$1" "$(head -c 300 "$_b22a/$1.err" 2>/dev/null | LC_ALL=C tr '\n' '/')"; fi
}
_b22a_quiet() {  # NAME -> "nothing on stdout", or what was there
  if [ -s "$_b22a/$1.out" ]; then printf '[%s stdout: %s]' "$1" "$(head -c 300 "$_b22a/$1.out" | LC_ALL=C tr '\n' '/')"
  else printf 'nothing on stdout'; fi
}
_b22a_rows() {  # OUT PATH LINE -> "name rule" of each row at PATH:LINE, joined by "; ", or "none"
  LC_ALL=C awk -F'\t' -v p="$2" -v l="$3" '$1 == p && $2 == l { o = o (o == "" ? "" : "; ") $3 " " $4 }
    END { print (o == "" ? "none" : o) }' "$1" 2>/dev/null
}
_b22a_has() {  # OUT PATH LINE "NAME RULE" -> yes when that row is among the line's rows, else the rows there
  local r; r="$(_b22a_rows "$1" "$2" "$3")"
  case "; $r; " in *"; $4; "*) printf yes ;; *) printf '[%s:%s %s]' "$2" "$3" "$r" ;; esac
}
_b22a_none() {  # OUT PATH LINE -> "none" when the line has no row, else its rows
  local r; r="$(_b22a_rows "$1" "$2" "$3")"
  if [ "$r" = none ]; then printf none; else printf '[%s:%s %s]' "$2" "$3" "$r"; fi
}
_b22a_same() { if cmp -s "$1" "$2"; then printf unchanged; else printf changed; fi; }   # FILE KEPT-COPY
_b22a_ln() {  # FILE FROM TO -> those lines of FILE joined by " | "
  LC_ALL=C awk -v a="$2" -v b="$3" 'NR >= a + 0 && NR <= b + 0 { o = o (NR == a + 0 ? "" : " | ") $0 } END { print o }' "$1" 2>/dev/null
}
_b22a_j() { local o="" x; for x in "$@"; do o="${o:+$o | }$x"; done; printf '%s' "$o"; }   # WORDS... joined by " | "

# ---- FA: the audit's fixture. Addresses are assembled: _b22a_au is AUTHOR, _b22a_ot OTHER.
_b22a_d="corpmail.org"; _b22a_au="lead@$_b22a_d"; _b22a_ot="pat@$_b22a_d"
_b22a_gh="github.com"; _b22a_gs=":o/r.git"; _b22a_nr="users.noreply.$_b22a_gh"
_b22a_r1="example.com"; _b22a_r2="sub.example.org"; _b22a_r3="h.invalid"; _b22a_r4="a.test"
_b22a_slug="quillcorp/lantern-home"
_b22a_root="$_b22a/root"; mkdir -p "$_b22a_root/docs"
printf '%s\n' quillfen tidewater zub > "$_b22a/names"
{
  printf '%s\n' 'the QuillFen tool' 'xxquillfenyy' 'a quill here' 'nothing' 'the fen there' 'qu ill fen'
  printf '%s\n' 'quil\x6cfen' 'q[u]illfen' 'quil.fen' "'uillfen" 'xuillfen' 'quil(l|x)fen' 'quil[lx]fen'
  printf '%s\n' 'quillfen and tidewater' 'zxb and z.b'
  printf '%s\n' "mail $_b22a_au now" "mail $_b22a_ot now" "[$_b22a_ot](mailto:$_b22a_ot)" "[$_b22a_au](mailto:$_b22a_au)"
  printf '%s\n' "x@$_b22a_r1 y@$_b22a_r2 z@$_b22a_r3 w@$_b22a_r4"
  printf '%s\n' "deploy[bot]@$_b22a_nr 41898282+github-actions[bot]@$_b22a_nr"
  printf '%s\n' "git@$_b22a_gh$_b22a_gs"
  printf '%s\n' 'repo: QuillCorp/Lantern_Home' 'quillcorp:lanternhome' 'xquillcorp/lantern-home'
} > "$_b22a_root/a.md"
printf '%s\n' 'a quill' 'b' 'c' 'the fen' > "$_b22a_root/far.md"
printf 'quill\000fen\n' > "$_b22a_root/nul.bin"
printf 'plain\n' > "$_b22a_root/docs/quillfen-notes.md"
ln -s ../quillfen "$_b22a_root/lnk" 2>/dev/null
printf '%s\0' a.md far.md nul.bin docs/quillfen-notes.md lnk > "$_b22a/paths"
printf '%s\0' a.md missing.md > "$_b22a/paths10"
_b22a_h1="$(printf '%s\n' 'the QuillFen tool' | git hash-object --stdin 2>/dev/null)"

if [ -z "$_b22a_why" ]; then
  _b22a_run a1a "$_b22a_root" /dev/null "$_b22a_sa" "$_b22a/names" "$_b22a_au"
  _b22a_run a1b "$_b22a_root" "$_b22a/paths" "$_b22a_sa" "$_b22a/no-names" "$_b22a_au" "$_b22a_root" "$_b22a_slug"
  _b22a_run a1c "$_b22a_root" "$_b22a/paths" "$_b22a_sa" "$_b22a/names" "$_b22a_au" "$_b22a/no-root" "$_b22a_slug"
  _b22a_run a2 "$_b22a_root" "$_b22a/paths" "$_b22a_sa" "$_b22a/names" "$_b22a_au" "$_b22a_root" "$_b22a_slug"
  _b22a_run a10 "$_b22a_root" "$_b22a/paths10" "$_b22a_sa" "$_b22a/names" "$_b22a_au" "$_b22a_root" "$_b22a_slug"
  _b22a_run a12 "$_b22a_root" "$_b22a/paths" "$_b22a_sa" "$_b22a/names" "$_b22a_au" "$_b22a_root"
fi
_b22a_o="$_b22a/a2.out"

# ---- the audit: A1 to A12 -------------------------------------------------------------------
_b22a_x=""; for _b22a_i in a1a a1b a1c; do
  _b22a_x="$_b22a_x$(_b22a_rc "$_b22a_i"), $(_b22a_err "$_b22a_i" 'usage: snapshot-audit.sh NAMES AUTHOR ROOT [SLUG] < paths'), $(_b22a_quiet "$_b22a_i"); "; done
_b22a_u='says usage: snapshot-audit.sh NAMES AUTHOR ROOT [SLUG] < paths'
_b22a_is "snapshot audit A1: two arguments, a NAMES that is no file, or a ROOT that is no directory each exit 2 with the usage on stderr and nothing on stdout (control)" \
  "$_b22a_x" "exit 2, $_b22a_u, nothing on stdout; exit 2, $_b22a_u, nothing on stdout; exit 2, $_b22a_u, nothing on stdout; "
_b22a_x="$(LC_ALL=C awk -F'\t' 'NF != 5 || $2 !~ /^[0123456789]+$/ { n++ } END { print (n + 0) " rows not five fields with a line number" }' "$_b22a_o" 2>/dev/null)"
_b22a_y="$(LC_ALL=C awk -F'\t' '$1 == "a.md" && $2 == "1"' "$_b22a_o" 2>/dev/null)"
_b22a_is "snapshot audit A2: the audit of FA exits 0, each row is five tab-separated fields, and a.md 1's one row is the path, the line, quillfen, name and the line's blob hash (control)" \
  "$(_b22a_rc a2); $_b22a_x; [$_b22a_y]" "exit 0; 0 rows not five fields with a line number; [$(printf 'a.md\t1\tquillfen\tname\t%s' "$_b22a_h1")]"
_b22a_is "snapshot audit A3: a name is found inside a longer word as well as in another case (control)" \
  "$(_b22a_has "$_b22a_o" a.md 2 'quillfen name')" yes
_b22a_is "snapshot audit A4: halves two lines apart give each of the two lines a halves row, and halves three lines apart give none (control)" \
  "$(_b22a_has "$_b22a_o" a.md 3 'quillfen halves') $(_b22a_has "$_b22a_o" a.md 5 'quillfen halves') far.md $(LC_ALL=C awk -F'\t' '$1 == "far.md" { n++ } END { print (n + 0) " rows" }' "$_b22a_o" 2>/dev/null)" \
  "yes yes far.md 0 rows"
_b22a_is "snapshot audit A5: adjacent words that join into a name are found as pieces (control)" \
  "$(_b22a_has "$_b22a_o" a.md 6 'quillfen pieces')" yes
_b22a_is "snapshot audit A6: a decoded copy is searched too, an x escape and a one-letter bracket class read and NUL bytes dropped, each found as a name row (control)" \
  "$(_b22a_has "$_b22a_o" a.md 7 'quillfen name') $(_b22a_has "$_b22a_o" a.md 8 'quillfen name') $(_b22a_has "$_b22a_o" nul.bin 1 'quillfen name')" "yes yes yes"
_b22a_is "snapshot audit A7: one character may stand in for a letter (a mark inside, a mark first, a group, a two-letter class), a first letter may not, and a three-letter name has no stand-in (control)" \
  "$(_b22a_has "$_b22a_o" a.md 9 'quillfen stand-in') $(_b22a_has "$_b22a_o" a.md 10 'quillfen stand-in') $(_b22a_has "$_b22a_o" a.md 12 'quillfen stand-in') $(_b22a_has "$_b22a_o" a.md 13 'quillfen stand-in') $(_b22a_none "$_b22a_o" a.md 11) $(_b22a_none "$_b22a_o" a.md 15)" \
  "yes yes yes yes none none"
_b22a_is "snapshot audit A8: a line holding two names gets exactly one name row (control)" \
  "$(_b22a_rows "$_b22a_o" a.md 14)" "quillfen name"
_b22a_is "snapshot audit A9: a path is read as line 0, and a symbolic link reads as its target (control)" \
  "$(_b22a_has "$_b22a_o" docs/quillfen-notes.md 0 'quillfen name') $(_b22a_has "$_b22a_o" lnk 1 'quillfen name')" "yes yes"
_b22a_x="$(LC_ALL=C awk -F'\t' '$1 == "a.md"' "$_b22a_o" 2>/dev/null)"; _b22a_y="$(LC_ALL=C awk -F'\t' '$1 == "a.md"' "$_b22a/a10.out" 2>/dev/null)"
_b22a_nl='
'
if [ -z "$_b22a_x" ]; then _b22a_y="the FA run printed no a.md row to compare"
elif [ "$_b22a_x" = "$_b22a_y" ]; then _b22a_y="a.md rows as in the FA run"
else _b22a_y="[a.md rows: ${_b22a_y//$_b22a_nl/ | }]"; fi
_b22a_is "snapshot audit A10: a path it cannot read exits 2 and is named on stderr, and the rows of the path it did read are printed as before (control)" \
  "$(_b22a_rc a10); $(_b22a_err a10 'snapshot-audit: cannot read missing.md'); $_b22a_y" \
  "exit 2; says snapshot-audit: cannot read missing.md; a.md rows as in the FA run"
_b22a_is "snapshot audit A11: another address stops, once a line in a Markdown link, and so does the git user at github; the author, reserved domains, GitHub's bot addresses and the author's own link pass (control)" \
  "$(_b22a_has "$_b22a_o" a.md 17 "@$_b22a_ot address") $(_b22a_rows "$_b22a_o" a.md 18) $(_b22a_has "$_b22a_o" a.md 22 "@git@$_b22a_gh address") $(_b22a_none "$_b22a_o" a.md 16) $(_b22a_none "$_b22a_o" a.md 19) $(_b22a_none "$_b22a_o" a.md 20) $(_b22a_none "$_b22a_o" a.md 21)" \
  "yes @$_b22a_ot address yes none none none none"
_b22a_x="$(LC_ALL=C awk -F'\t' '$4 == "repository" { n++ } END { print (n + 0) " repository rows" }' "$_b22a/a12.out" 2>/dev/null)"
_b22a_is "snapshot audit A12: the home's owner/repo is found in any case, with / or : between and any separators in the repository, not after a letter, and never without a SLUG (control)" \
  "$(_b22a_has "$_b22a_o" a.md 23 'quillcorp/lantern_home repository') $(_b22a_has "$_b22a_o" a.md 24 'quillcorp:lanternhome repository') $(_b22a_none "$_b22a_o" a.md 25); without a SLUG $(_b22a_rc a12), $_b22a_x" \
  "yes yes none; without a SLUG exit 0, 0 repository rows"

# ---- FS: the scrub's fixture. One directory a case, as each case rewrites its files.
_b22a_fs="$_b22a/fs"; mkdir -p "$_b22a_fs/keep"
printf 'quillfen\tseventh\ta seventh governed project\tquillcorp/quillfen-site \n' > "$_b22a_fs/plan"
_b22a_notes() {  # DIR: notes.md, the fifteen lines of B14 and B17
  printf '%s\n' 'see quillcorp/quillfen-site now' 'see quillcorp:quillfen-site now' 'the quillfen gate' \
    'projects/quillfen/CLAUDE.md' 'set QUILLFEN_HOME first' 'subquillfen' 'Quillfen runs' 'the quillfen-site repo' \
    'a quill fen here' 'see src/quill/fen.py' 'the quill-fen form' 'the quill_fen form' 'quil.fen' 'plain words' \
    "$(printf 'a\tquill\tfen')" > "$1/notes.md"
}
_b22a_xsh() { printf '%s\n' 'quillfen=1' 'echo "$quillfen"' > "$1/x.sh"; }   # DIR: x.sh
for _b22a_i in c13 c14 c16y c16z c19; do mkdir -p "$_b22a_fs/$_b22a_i"; done
_b22a_notes "$_b22a_fs/c13"; _b22a_notes "$_b22a_fs/c14"; _b22a_notes "$_b22a_fs/keep"
_b22a_xsh "$_b22a_fs/c14"; _b22a_xsh "$_b22a_fs/c19"
printf 'quillfen in prose\n' > "$_b22a_fs/c14/unlisted.md"; cp "$_b22a_fs/c14/unlisted.md" "$_b22a_fs/keep/unlisted.md"
printf '%s\n' 'quillfen=1' 'seventh=2' 'echo "$quillfen $seventh"' > "$_b22a_fs/c16y/y.sh"; cp "$_b22a_fs/c16y/y.sh" "$_b22a_fs/keep/y.sh"
printf 'quillfen=1\n' > "$_b22a_fs/c16z/z.md"; cp "$_b22a_fs/c16z/z.md" "$_b22a_fs/keep/z.md"
printf '%s\0' notes.md x.sh > "$_b22a_fs/list14"; printf 'y.sh\0' > "$_b22a_fs/listy"
printf 'z.md\0' > "$_b22a_fs/listz"; printf 'x.sh\0' > "$_b22a_fs/listx"; : > "$_b22a_fs/list0"

if [ -z "$_b22a_why" ]; then
  _b22a_run s13a "$_b22a_fs/c13" /dev/null "$_b22a_ss" "$_b22a_fs/plan"
  _b22a_run s13b "$_b22a_fs/c13" /dev/null "$_b22a_ss" "$_b22a_fs/no-plan" "$_b22a_fs/list14"
  _b22a_run s13c "$_b22a_fs/c13" /dev/null "$_b22a_ss" "$_b22a_fs/plan" "$_b22a_fs/no-list"
  _b22a_run s13d "$_b22a_fs/c13" /dev/null "$_b22a_ss" "$_b22a_fs/plan" "$_b22a_fs/list0"
  _b22a_run s14 "$_b22a_fs/c14" /dev/null "$_b22a_ss" "$_b22a_fs/plan" "$_b22a_fs/list14"
  _b22a_run s16y "$_b22a_fs/c16y" /dev/null "$_b22a_ss" "$_b22a_fs/plan" "$_b22a_fs/listy"
  _b22a_run s16z "$_b22a_fs/c16z" /dev/null "$_b22a_ss" "$_b22a_fs/plan" "$_b22a_fs/listz"
  _b22a_run s19 "$_b22a_fs/c19" /dev/null "$_b22a_ss" "$_b22a_fs/plan" "$_b22a_fs/listx"
fi
_b22a_n="$_b22a_fs/c14/notes.md"

# ---- the scrub: A13 to A19 -------------------------------------------------------------------
_b22a_u='says usage: snapshot-scrub.sh PLAN LIST'
_b22a_x=""; for _b22a_i in s13a s13b s13c; do _b22a_x="$_b22a_x$(_b22a_rc "$_b22a_i"), $(_b22a_err "$_b22a_i" 'usage: snapshot-scrub.sh PLAN LIST'); "; done
_b22a_is "snapshot scrub A13: one argument, a PLAN that is no file, or a LIST that is no file each exit 2 with the usage, and an empty LIST exits 0 and changes nothing (control)" \
  "$_b22a_x$(_b22a_rc s13d), notes.md $(_b22a_same "$_b22a_fs/c13/notes.md" "$_b22a_fs/keep/notes.md")" \
  "exit 2, $_b22a_u; exit 2, $_b22a_u; exit 2, $_b22a_u; exit 0, notes.md unchanged"
_b22a_is "snapshot scrub A14: notes.md lines 1 to 8 read as the owner/repo, repository and whole-name rules write them, the file keeps its 15 lines, and an unlisted file is untouched (control)" \
  "$(_b22a_rc s14); $(LC_ALL=C awk 'END { print NR }' "$_b22a_n" 2>/dev/null) lines; unlisted.md $(_b22a_same "$_b22a_fs/c14/unlisted.md" "$_b22a_fs/keep/unlisted.md"); $(_b22a_ln "$_b22a_n" 1 8)" \
  "exit 0; 15 lines; unlisted.md unchanged; $(_b22a_j 'see OWNER/seventh now' 'see OWNER:seventh now' 'the a seventh governed project gate' 'projects/seventh/CLAUDE.md' 'set SEVENTH_PROJECT_HOME first' 'subseventh' 'a seventh governed project runs' 'the a seventh governed project repo')"
bash -n "$_b22a_fs/c14/x.sh" >/dev/null 2>&1; _b22a_x="$?"
_b22a_is "snapshot scrub A15: a shell variable named for the project becomes the token's, and the script still parses (control)" \
  "$(_b22a_ln "$_b22a_fs/c14/x.sh" 1 99); bash -n exit $_b22a_x" "$(_b22a_j 'seventh=1' 'echo "$seventh"'); bash -n exit 0"
_b22a_is "snapshot scrub A16: a project variable beside one already named for the token, or one in a file that is not shell, stops the scrub with its reason and leaves the file byte for byte (control)" \
  "$(_b22a_stop s16y), $(_b22a_err s16y 'uses quillfen as a shell variable and already has one named seventh; a person renames it'), y.sh $(_b22a_same "$_b22a_fs/c16y/y.sh" "$_b22a_fs/keep/y.sh"); $(_b22a_stop s16z), $(_b22a_err s16z 'uses quillfen as a shell variable in a file that is not shell'), z.md $(_b22a_same "$_b22a_fs/c16z/z.md" "$_b22a_fs/keep/z.md")" \
  "exit non-zero, says uses quillfen as a shell variable and already has one named seventh; a person renames it, y.sh unchanged; exit non-zero, says uses quillfen as a shell variable in a file that is not shell, z.md unchanged"
_b22a_is "snapshot scrub A17: the halves and stand-in rewrites keep their bytes on notes.md lines 9 to 15 (control)" \
  "$(_b22a_ln "$_b22a_n" 9 15)" \
  "$(_b22a_j 'a seven th here' 'see src/seven/th.py' 'the seven-th form' 'the seven_th form' 'seve.nth' 'plain words' "$(printf 'a\tseven\tth')")"
# Each stdout line of the B14 run read as a report: "RULE LINE" for a line that begins
# "scrub: RULE quillfen notes.md:LINE" (any further text after a space), the line itself in
# brackets otherwise; sorted and joined by " / ".
_b22a_x="$(LC_ALL=C awk '{ n = split($0, w, " ")
    if (n >= 4 && w[1] == "scrub:" && (w[2] == "halves" || w[2] == "stand-in") && w[3] == "quillfen" && w[4] ~ /^notes[.]md:[0123456789]+$/ && index($0, "scrub: " w[2] " quillfen " w[4]) == 1)
      print w[2] " " substr(w[4], 10)
    else print "[" $0 "]" }' "$_b22a/s14.out" 2>/dev/null | LC_ALL=C sort | LC_ALL=C awk '{ o = o (NR == 1 ? "" : " / ") $0 } END { print o }')"
_b22a_y="$(printf '%s\n' 'halves 9' 'halves 10' 'halves 11' 'halves 12' 'halves 15' 'stand-in 13' | LC_ALL=C sort | LC_ALL=C awk '{ o = o (NR == 1 ? "" : " / ") $0 } END { print o }')"
_b22a_is "snapshot scrub A18: each line the halves or stand-in rule changes is reported on stdout as scrub: RULE quillfen notes.md:LINE, exactly six lines: halves for 9, 10, 11, 12 and 15, stand-in for 13" \
  "$_b22a_x" "$_b22a_y"
_b22a_is "snapshot scrub A19: a run whose rewrites are none of halves or stand-in exits 0 and prints nothing on stdout (control)" \
  "$(_b22a_rc s19), $(_b22a_quiet s19)" "exit 0, nothing on stdout"
