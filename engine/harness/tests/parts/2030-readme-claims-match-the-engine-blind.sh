printf '\nREADME claims match the engine (audit b21, A1-A26, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b21-readme-claims-match-the-engine.md
# alone (B1-B20, asserted as A1-A26), before the README was rewritten, without reading any engine code:
# lib/epoch.sh, lib/probes.sh and lib/verify.sh are sourced and called as black boxes, as part 0750
# calls them. Four defects of the 2026-10-24 register: C008 (an instrument change said to stale a pass,
# and the tree id blamed on which git is on PATH), C017 (Felix said to narrow itself on a weak result),
# C007 (felix land, a merge with nobody present, missing from the README) and C099 (/usr/local/bin,
# which an admin cannot write on a stock Mac). Part 2031 holds felix install's half of C099.
#
# The terms are the contract's. Section NAME: the lines after the first line that begins `## NAME`, up
# to the next line that begins `## `. The uninstall part: the Install section's lines from the line
# `### Verify and uninstall` to its end. Flat text: backticks and `*` removed, tabs made spaces, the
# lines joined with one space, runs of spaces squeezed, A-Z lower-cased. A sentence: a piece of flat
# text split at every ". ". Negated: matching (^|[^a-z])(not|never|no|nor)([^a-z]|$), or holding n't.
# A Status row begins `| **`; the Partial row begins `| **Partial**`. A bullet: a line that begins
# `- ` and the lines after it, up to the next `- ` line, a blank line or the section's end. Every
# pattern but B19-B20's is an ERE over flat text, matched by awk under LC_ALL=C; B19-B20 read raw lines.
#
# Every name is emitted on every run. When the README, one of its four sections or the Verify and
# uninstall line is not found (a run from the plugin cache has no README), A1 fails, and so does every
# README assertion after it, each naming what was not found: none passes and none is skipped. A6-A11
# are controls on the engine (fixtures E and T) and run whatever the README holds.
#
# Readings, where the contract leaves room. A missing Partial row fails A4 and A5, as an unknown and
# not a pass. B6 (c) and B7 (c) want each hash they compare non-empty and its call to exit 0, like
# (b). B7 (a) is asserted of both repositories of fixture T. A phrase or pattern the contract matches
# against a whole flat text and that cannot span ". " (A12, A15, A22) is matched per sentence, which
# finds the same text and names the sentence that holds it. B19 (b) and B20 fail when no fenced block
# of Install names felix install, and B20 fails without running anything unless the block holds
# exactly one `ln -s` line. A word "begins with $TMP's path" when it is that path or lies below it.
# Every check prints `ok` or what is wrong, so a reader that fails says so and never reads as a pass.

_b21r_rm="$REAL_HARNESS/../../README.md"
_b21r_d="$TMP/b21-readme"; mkdir -p "$_b21r_d"
_b21r_neg='(^|[^a-z])(not|never|no|nor)([^a-z]|$)'
_b21r_ap="n't"
_b21r_tp="$(cd "$TMP" && pwd -P)"

# NAME -> the lines of section NAME; status 1 when no line begins `## NAME`.
_b21r_sec() {
  LC_ALL=C awk -v n="## $1" '
    p && index($0, "## ") == 1 { exit }
    p { print; next }
    index($0, n) == 1 { p = 1; f = 1 }
    END { exit (f ? 0 : 1) }' "$_b21r_rm"
}
# FILE -> its flat text, one line.
_b21r_flat() {
  LC_ALL=C awk '{ gsub(/[`*]/, ""); gsub(/\t/, " "); s = (NR == 1 ? $0 : s " " $0) }
    END { gsub(/ +/, " ", s); print tolower(s) }' "$1"
}
# FILE of flat text -> its sentences, one a line.
_b21r_sents() {
  LC_ALL=C awk '{ s = $0; while ((i = index(s, ". ")) > 0) { print substr(s, 1, i - 1); s = substr(s, i + 2) } print s }' "$1"
}
# FILE -> the flat text of each bullet, one a line.
_b21r_bullets() {
  LC_ALL=C awk '
    function out() { if (b != "") { gsub(/[`*]/, "", b); gsub(/\t/, " ", b); gsub(/ +/, " ", b); print tolower(b) } b = "" }
    index($0, "- ") == 1 { out(); b = $0; next }
    /^[ \t]*$/ { out(); next }
    b != "" { b = b " " $0 }
    END { out() }' "$1"
}
# FILE -> the first fenced block holding a line naming felix install, its fences left out; status 1 when none.
_b21r_block() {
  LC_ALL=C awk '
    index($0, "```") == 1 { if (inb && has) { found = 1; exit } inb = !inb; n = 0; has = 0; next }
    inb { b[++n] = $0; if (index($0, "felix install")) has = 1 }
    END { if (found) for (i = 1; i <= n; i++) print b[i]; exit (found ? 0 : 1) }' "$1"
}
# LINE -> ok, or why it may not be run: the guard of B20.
_b21r_guard() {
  local l="$1" w why="" IFS=$' \t'
  case "$l" in *';'*|*'|'*|*'>'*|*'<'*|*'`'*|*'$('*|*sudo*|*'rm '*)
    printf 'refused, it holds one of ; | > < a backtick $( sudo or rm: [%s]\n' "$l"; return 0 ;; esac
  set -f
  for w in $l; do
    w="${w//\"/}"; w="${w//\'/}"
    case "$w" in /*) case "$w" in "$TMP"|"$TMP"/*|"$_b21r_tp"|"$_b21r_tp"/*) ;; *) why="$w"; break ;; esac ;; esac
  done
  set +f
  if [ -n "$why" ]; then printf 'refused, %s lies outside the fixture: [%s]\n' "$why" "$l"; else printf 'ok\n'; fi
}

# ---- B1: the README and what is read from it
_b21r_miss=""
if [ -f "$_b21r_rm" ] && [ -r "$_b21r_rm" ]; then
  _b21r_sec "Why not just run the tests in CI?" > "$_b21r_d/why.raw" || _b21r_miss="$_b21r_miss; the section ## Why not just run the tests in CI?"
  _b21r_sec "Status" > "$_b21r_d/status.raw" || _b21r_miss="$_b21r_miss; the section ## Status"
  _b21r_sec "Where it's going" > "$_b21r_d/where.raw" || _b21r_miss="$_b21r_miss; the section ## Where it's going"
  _b21r_sec "Install" > "$_b21r_d/install.raw" || _b21r_miss="$_b21r_miss; the section ## Install"
  LC_ALL=C awk 'index($0, "### Verify and uninstall") == 1 { p = 1 } p' "$_b21r_d/install.raw" > "$_b21r_d/uninstall.raw" 2>/dev/null
  [ -s "$_b21r_d/uninstall.raw" ] || _b21r_miss="$_b21r_miss; the line ### Verify and uninstall in ## Install"
  _b21r_miss="${_b21r_miss#; }"
else
  _b21r_miss="the README, $_b21r_rm (missing or unreadable)"
fi
_b21r_hasblk=0
if [ -z "$_b21r_miss" ]; then
  for _b21r_s in why status where install uninstall; do
    _b21r_flat "$_b21r_d/$_b21r_s.raw" > "$_b21r_d/$_b21r_s.flat"
    _b21r_sents "$_b21r_d/$_b21r_s.flat" > "$_b21r_d/$_b21r_s.sents"
  done
  _b21r_flat "$_b21r_rm" > "$_b21r_d/all.flat"; _b21r_sents "$_b21r_d/all.flat" > "$_b21r_d/all.sents"
  LC_ALL=C awk 'index($0, "| **") == 1 { gsub(/[`*]/, ""); gsub(/\t/, " "); gsub(/ +/, " "); print tolower($0) }' \
    "$_b21r_d/status.raw" > "$_b21r_d/rows.flat"
  LC_ALL=C awk 'index($0, "| **Partial**") == 1 { gsub(/[`*]/, ""); gsub(/\t/, " "); gsub(/ +/, " "); print tolower($0); exit }' \
    "$_b21r_d/status.raw" > "$_b21r_d/partial.flat"
  _b21r_bullets "$_b21r_d/install.raw" > "$_b21r_d/install.bullets"
  _b21r_block "$_b21r_d/install.raw" > "$_b21r_d/block" && _b21r_hasblk=1
fi
# NAME VERDICT: ok when VERDICT is ok; bad naming what was not found, or with VERDICT as the detail.
_b21r_say() {
  if [ -n "$_b21r_miss" ]; then bad "$1" "not found: $_b21r_miss"
  elif [ "$2" = ok ]; then ok "$1"
  elif [ -z "$2" ]; then bad "$1" "the check printed no verdict"
  else bad "$1" "$2"; fi
}
# CHECK -> CHECK's verdict, or nothing when the README was not found (the verdict is then never read).
_b21r_v() { [ -z "$_b21r_miss" ] || return 0; "$@" 2>&1; }

if [ -z "$_b21r_miss" ]; then ok "README claims, A1: the README, its four sections and the Verify and uninstall line are found"
else bad "README claims, A1: the README, its four sections and the Verify and uninstall line are found" "not found: $_b21r_miss"; fi

# ---- C008: Why not just run the tests in CI?, and the Partial row
_b21r_a2() {
  LC_ALL=C awk -v p1='(different size|program|instrument|binary|upgrade)' \
    -v p2='(stops counting|(goes|is|are|becomes|turns|reads) stale)' '
    $0 ~ p1 && $0 ~ p2 { print "[" $0 "]"; n++ } END { if (!n) print "ok" }' "$_b21r_d/why.sents"
}
_b21r_a3() {
  LC_ALL=C awk -v ng="$_b21r_neg" -v ap="$_b21r_ap" '
    /felix probes/ { m = m "[" $0 "] "; if (($0 ~ ng || index($0, ap)) && $0 ~ /(stop counting|stale)/) f = 1 }
    END { if (f) print "ok"; else if (m == "") print "no sentence of the section names felix probes"
          else print "no sentence naming felix probes is negated and says stop counting or stale: " m }' "$_b21r_d/why.sents"
}
_b21r_a4() {
  [ -s "$_b21r_d/partial.flat" ] || { printf 'no line of Status begins | **Partial**\n'; return 0; }
  LC_ALL=C awk '/on path|which git/ { print "[" $0 "]"; n++ } END { if (!n) print "ok" }' "$_b21r_d/partial.flat"
}
_b21r_a5() {
  [ -s "$_b21r_d/partial.flat" ] || { printf 'no line of Status begins | **Partial**\n'; return 0; }
  LC_ALL=C awk '{ if ($0 ~ /abbreviat/ && $0 ~ /object/ && $0 ~ /uncommitted/) print "ok"
                  else print "[" $0 "] lacks one of abbreviat, object, uncommitted" }' "$_b21r_d/partial.flat"
}
_b21r_say "README claims, A2: no sentence in Why not just run the tests in CI? says a probe's program changing size makes the pass stop counting" "$(_b21r_v _b21r_a2)"
_b21r_say "README claims, A3: that section says felix probes reports an instrument change that does not, by itself, stale the pass" "$(_b21r_v _b21r_a3)"
_b21r_say "README claims, A4: the Partial row no longer blames which git is on PATH" "$(_b21r_v _b21r_a4)"
_b21r_say "README claims, A5: the Partial row names abbreviated object names as what stales a receipt for uncommitted edits" "$(_b21r_v _b21r_a5)"

# ---- B6, fixture E: the engine still does what B2 and B3 say (controls)
_b21e="$TMP/b21-ep"
mkdir -p "$_b21e/proj" "$_b21e/repo" "$_b21e/binA" "$_b21e/binB" "$_b21e/binC" "$MEM/b21-ep"
printf '{"name": "b21-ep", "remote_match": "example.com/b21-ep", "gate": "true"}\n' > "$_b21e/proj/project.json"
printf '# predicate\tgrounds\twhen\tprobe\twitness\nmember\t-\t-\tmytool\ttrue\n' > "$_b21e/proj/probes.tsv"
printf 'one\n' > "$_b21e/repo/one.txt"
( _fx_cd "$_b21e/repo" && git init -q -b main && git add -A && git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
printf '#!/bin/sh\necho a\necho b\n' > "$_b21e/binA/mytool"
printf '#!/bin/sh\n# the same instrument, one comment line longer\necho a\necho b\n' > "$_b21e/binB/mytool"
printf '#!/bin/sh\necho a\necho b\necho c\n' > "$_b21e/binC/mytool"
chmod +x "$_b21e/binA/mytool" "$_b21e/binB/mytool" "$_b21e/binC/mytool"
_b21e_epoch() {  # A|B|C -> felix_epoch's output with that bin first on PATH; its status
  ( PATH="$_b21e/bin$1:$PATH"; unset FELIX_RELEASE_TARGET; . "$FROOT/harness/lib/epoch.sh"
    felix_epoch "$_b21e/proj" "$_b21e/repo" ) 2>/dev/null
}
_b21e_tok() {  # A|B -> field 7 of felix_probes_run's member row with that bin first on PATH
  ( PATH="$_b21e/bin$1:$PATH"; unset FELIX_RELEASE_TARGET; . "$FROOT/harness/lib/probes.sh"
    felix_probes_run "$_b21e/proj" "$_b21e/repo" ) 2>/dev/null | LC_ALL=C awk -F'\t' '$1 == "member" { print $7 }'
}
_b21e_istok() { case "$1" in mytool@) return 1 ;; mytool@*) case "${1#mytool@}" in *[!0123456789]*) return 1 ;; esac; return 0 ;; esac; return 1; }
_b21e_tA="$(_b21e_tok A)"; _b21e_tB="$(_b21e_tok B)"
_b21e_hA="$(_b21e_epoch A)"; _b21e_rA=$?
_b21e_hB="$(_b21e_epoch B)"; _b21e_rB=$?
_b21e_hC="$(_b21e_epoch C)"; _b21e_rC=$?
_b21e_a=0; _b21e_istok "$_b21e_tA" && _b21e_istok "$_b21e_tB" && [ "$_b21e_tA" != "$_b21e_tB" ] && _b21e_a=1
_b21e_n6="README claims, A6: two programs of different sizes printing the same answer are two instruments to felix_probes_run"
_b21e_n7="README claims, A7: and felix_epoch computes the same epoch under both, so the pass does not stop counting"
_b21e_n8="README claims, A8: while a probe whose answer changed computes a different epoch"
_b21e_na="the two instruments were not told apart: field 7 read [$_b21e_tA] under binA and [$_b21e_tB] under binB"
if [ "$_b21e_a" = 1 ]; then ok "$_b21e_n6"; else bad "$_b21e_n6" "$_b21e_na"; fi
if [ "$_b21e_a" != 1 ]; then bad "$_b21e_n7" "$_b21e_na"
elif [ "$_b21e_rA" = 0 ] && [ "$_b21e_rB" = 0 ] && [ -n "$_b21e_hA" ] && [ "$_b21e_hA" = "$_b21e_hB" ]; then ok "$_b21e_n7"
else bad "$_b21e_n7" "binA gave [$_b21e_hA] (exit $_b21e_rA), binB gave [$_b21e_hB] (exit $_b21e_rB): the README's Why not just run the tests in CI? item 2 is now false"; fi
if [ "$_b21e_a" != 1 ]; then bad "$_b21e_n8" "$_b21e_na"
elif [ "$_b21e_rA" = 0 ] && [ "$_b21e_rC" = 0 ] && [ -n "$_b21e_hA" ] && [ -n "$_b21e_hC" ] && [ "$_b21e_hC" != "$_b21e_hA" ]; then ok "$_b21e_n8"
else bad "$_b21e_n8" "binA gave [$_b21e_hA] (exit $_b21e_rA), binC gave [$_b21e_hC] (exit $_b21e_rC)"; fi

# ---- B7, fixture T: the engine still does what B5 says (controls)
_b21t="$TMP/b21-tid"
for _b21t_r in dirty clean; do
  mkdir -p "$_b21t/$_b21t_r"; printf 'a\n' > "$_b21t/$_b21t_r/a.txt"
  ( _fx_cd "$_b21t/$_b21t_r" && git init -q -b main && git add -A && git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
done
printf 'b\n' >> "$_b21t/dirty/a.txt"
_b21t_id() { ( . "$FROOT/harness/lib/verify.sh"; felix_tree_id "$1" ) 2>/dev/null; }
_b21t_st() { ( _fx_cd "$1" && git status --porcelain ) 2>&1; }
_b21t_inpack() { ( _fx_cd "$1" && git count-objects -v ) 2>/dev/null | LC_ALL=C awk '$1 == "in-pack:" { print $2 }'; }
_b21t_grow() {
  ( _fx_cd "$1" && LC_ALL=C awk 'BEGIN { for (i = 0; i < 20000; i++) { s = "blob " i "\n"; printf "blob\ndata %d\n%s\n", length(s), s } }' \
      | git fast-import --quiet ) >/dev/null 2>&1
}
_b21t_d0="$(_b21t_id "$_b21t/dirty")"; _b21t_d0r=$?
_b21t_c0="$(_b21t_id "$_b21t/clean")"; _b21t_c0r=$?
_b21t_sd0="$(_b21t_st "$_b21t/dirty")"; _b21t_sc0="$(_b21t_st "$_b21t/clean")"
_b21t_grow "$_b21t/dirty"; _b21t_grow "$_b21t/clean"
_b21t_d1="$(_b21t_id "$_b21t/dirty")"; _b21t_d1r=$?
_b21t_c1="$(_b21t_id "$_b21t/clean")"; _b21t_c1r=$?
_b21t_sd1="$(_b21t_st "$_b21t/dirty")"; _b21t_sc1="$(_b21t_st "$_b21t/clean")"
_b21t_pd="$(_b21t_inpack "$_b21t/dirty")"; _b21t_pc="$(_b21t_inpack "$_b21t/clean")"
_b21t_big() { case "$1" in ''|*[!0123456789]*) return 1 ;; esac; [ "$1" -ge 20000 ]; }
_b21t_a=""
_b21t_big "$_b21t_pd" || _b21t_a="$_b21t_a dirty reports in-pack [$_b21t_pd];"
_b21t_big "$_b21t_pc" || _b21t_a="$_b21t_a clean reports in-pack [$_b21t_pc];"
[ "$_b21t_sd0" = "$_b21t_sd1" ] || _b21t_a="$_b21t_a dirty's status went from [$_b21t_sd0] to [$_b21t_sd1];"
[ "$_b21t_sc0" = "$_b21t_sc1" ] || _b21t_a="$_b21t_a clean's status went from [$_b21t_sc0] to [$_b21t_sc1];"
_b21t_n9="README claims, A9: 20,000 unreachable blobs grow the object store past 16,384 and change no git status"
_b21t_n10="README claims, A10: and the id of a tree with uncommitted edits to tracked files changes with them"
_b21t_n11="README claims, A11: while a clean tree's id does not"
if [ -z "$_b21t_a" ]; then ok "$_b21t_n9"; else bad "$_b21t_n9" "${_b21t_a# }"; fi
if [ -n "$_b21t_a" ]; then bad "$_b21t_n10" "the growth did not happen as B7 (a) wants:$_b21t_a"
elif [ "$_b21t_d0r" = 0 ] && [ "$_b21t_d1r" = 0 ] && [ -n "$_b21t_d0" ] && [ -n "$_b21t_d1" ] && [ "$_b21t_d0" != "$_b21t_d1" ]; then ok "$_b21t_n10"
else bad "$_b21t_n10" "before [$_b21t_d0] (exit $_b21t_d0r), after [$_b21t_d1] (exit $_b21t_d1r): the README's Partial row is now false"; fi
if [ -n "$_b21t_a" ]; then bad "$_b21t_n11" "the growth did not happen as B7 (a) wants:$_b21t_a"
elif [ "$_b21t_c0r" = 0 ] && [ "$_b21t_c1r" = 0 ] && [ -n "$_b21t_c0" ] && [ "$_b21t_c0" = "$_b21t_c1" ]; then ok "$_b21t_n11"
else bad "$_b21t_n11" "before [$_b21t_c0] (exit $_b21t_c0r), after [$_b21t_c1] (exit $_b21t_c1r)"; fi

# ---- C017: Where it's going
_b21r_a12() { LC_ALL=C awk 'index($0, "narrow to the obligations") { print "[" $0 "]"; n++ } END { if (!n) print "ok" }' "$_b21r_d/all.sents"; }
_b21r_a13() {
  LC_ALL=C awk -v ng="$_b21r_neg" -v ap="$_b21r_ap" '
    ($0 ~ /narrow(s|ed|ing)? (to|on)([^a-z]|$)/ || $0 ~ /(will|would) narrow/) && !($0 ~ ng || index($0, ap)) { print "[" $0 "]"; n++ }
    END { if (!n) print "ok" }' "$_b21r_d/where.sents"
}
_b21r_a14() {
  LC_ALL=C awk -v w="(weak|finds nothing|misses|does not beat|doesn't beat)" '
    /investigat/ { m = m "[" $0 "] "; if ($0 ~ w) f = 1 }
    END { if (f) print "ok"; else if (m == "") print "no sentence of the section says investigat"
          else print "no sentence saying investigat also says weak, finds nothing, misses or does not beat: " m }' "$_b21r_d/where.sents"
}
_b21r_a15() { LC_ALL=C awk '/comes? first/ { print "[" $0 "]"; n++ } END { if (!n) print "ok" }' "$_b21r_d/where.sents"; }
_b21r_a16() {
  LC_ALL=C awk '{ c = match($0, /(test of what a model finds|corpus)/); d = match($0, /dry.run/); r = match($0, /retire/); e = ""
    if (c && d && !(c < d)) e = e " the dry run (at " d ") comes before the corpus (at " c ");"
    if (d && r && !(d < r)) e = e " the retire list (at " r ") comes before the dry run (at " d ");"
    if (c && r && !(c < r)) e = e " the retire list (at " r ") comes before the corpus (at " c ");"
    print (e == "" ? "ok" : "out of direction section 5 order:" e) }' "$_b21r_d/where.flat"
}
_b21r_say "README claims, A12: nowhere does the README say Felix will narrow to the obligations people name" "$(_b21r_v _b21r_a12)"
_b21r_say "README claims, A13: Where it's going narrows Felix on no result" "$(_b21r_v _b21r_a13)"
_b21r_say "README claims, A14: Where it's going says a weak corpus result is investigated" "$(_b21r_v _b21r_a14)"
_b21r_say "README claims, A15: Where it's going says nothing comes first" "$(_b21r_v _b21r_a15)"
_b21r_say "README claims, A16: Where it's going keeps the corpus, the dry run and the retire list in direction's order" "$(_b21r_v _b21r_a16)"

# ---- C007: felix land
_b21r_a17() {
  LC_ALL=C awk '
    index($0, "felix land --install") && index($0, "felix merge") && index($0, "macos") && index($0, "deploy") && index($0, "home") \
      && $0 ~ /(nobody|unattended|on its own|without you)/ { f = 1 }
    /felix land/ { m = m "[" $0 "] " }
    END { if (f) print "ok"; else if (m == "") print "no bullet of Install names felix land"
          else print "no bullet holds felix land --install, felix merge, macos, deploy, home and nobody, unattended, on its own or without you: " m }' \
    "$_b21r_d/install.bullets"
}
_b21r_a18() { LC_ALL=C awk '/merges? on its own/ && !/felix land/ { print "[" $0 "]"; n++ } END { if (!n) print "ok" }' "$_b21r_d/all.sents"; }
_b21r_a19() { LC_ALL=C awk 'index($0, "felix land --uninstall") { f = 1 } END { print (f ? "ok" : "the uninstall part does not name felix land --uninstall") }' "$_b21r_d/uninstall.flat"; }
_b21r_a20() {
  LC_ALL=C awk '/felix land[^|]*own repository/ { f = 1 } /felix land/ { m = m "[" $0 "] " }
    END { if (f) print "ok"; else if (m == "") print "no Status row names felix land"
          else print "no cell naming felix land scopes it to the own repository: " m }' "$_b21r_d/rows.flat"
}
_b21r_a21() {
  LC_ALL=C awk '/gh is needed for/ { n++; if ($0 !~ /(^|[^a-z-])land([^a-z-]|$)/) { print "[" $0 "] does not name land"; b++ } }
    END { if (n == 0) print "no sentence of Install says gh is needed for"; else if (b == 0) print "ok" }' "$_b21r_d/install.sents"
}
_b21r_a22() { LC_ALL=C awk '/[0123456789][0123456789,]* assertions/ { print "[" $0 "]"; n++ } END { if (!n) print "ok" }' "$_b21r_d/all.sents"; }
_b21r_say "README claims, A17: the Install list names felix land --install as an unattended felix merge that deploys, on macOS, for the home's repository" "$(_b21r_v _b21r_a17)"
_b21r_say "README claims, A18: every sentence saying something merges on its own names felix land" "$(_b21r_v _b21r_a18)"
_b21r_say "README claims, A19: Verify and uninstall names felix land --uninstall" "$(_b21r_v _b21r_a19)"
_b21r_say "README claims, A20: the Status table names felix land, scoped to Felix's own repository" "$(_b21r_v _b21r_a20)"
_b21r_say "README claims, A21: land is among the commands that need gh" "$(_b21r_v _b21r_a21)"
_b21r_say "README claims, A22: the README states no assertion count" "$(_b21r_v _b21r_a22)"

# ---- C099: the README's install lines (raw lines, case-sensitive)
_b21r_a23() { LC_ALL=C awk 'index($0, "/usr/local/bin") { print "[" $0 "]"; n++ } END { if (!n) print "ok" }' "$_b21r_d/install.raw"; }
_b21r_a24() {
  [ "$_b21r_hasblk" = 1 ] || { printf 'no fenced block of Install holds a line naming felix install\n'; return 0; }
  LC_ALL=C awk 'index($0, "ln -s") { n++; l = $0 } END {
    if (n != 1) print "the block holds " n + 0 " lines naming ln -s"
    else if (index(l, "mkdir -p") && index(l, ".local/bin/felix")) print "ok"
    else print "[" l "] lacks mkdir -p or .local/bin/felix" }' "$_b21r_d/block"
}
_b21r_a25() {
  LC_ALL=C awk 'index($0, "export PATH=") && index($0, ".local/bin") { f = 1 }
    END { print (f ? "ok" : "no line of Install holds both export PATH= and .local/bin") }' "$_b21r_d/install.raw"
}
_b21r_say "README claims, A23: the Install section names no /usr/local/bin" "$(_b21r_v _b21r_a23)"
_b21r_say "README claims, A24: its install block links felix into ~/.local/bin after mkdir -p" "$(_b21r_v _b21r_a24)"
_b21r_say "README claims, A25: and it says how to put ~/.local/bin on PATH" "$(_b21r_v _b21r_a25)"

# B20: the block's one ln -s line, guarded, then run from D with HOME at H.
_b21r_D="$TMP/b21-rd/D"; _b21r_H="$TMP/b21-rd/H"
mkdir -p "$_b21r_D/felix/engine/harness" "$_b21r_H"
printf '#!/bin/sh\nexit 0\n' > "$_b21r_D/felix/engine/harness/felix"; chmod +x "$_b21r_D/felix/engine/harness/felix"
_b21r_a26() {
  local n l g rc
  [ "$_b21r_hasblk" = 1 ] || { printf 'no fenced block of Install holds a line naming felix install\n'; return 0; }
  n="$(LC_ALL=C grep -c -F 'ln -s' "$_b21r_d/block")"
  [ "$n" = 1 ] || { printf 'the block holds %s lines naming ln -s, so none is run\n' "${n:-an unread number of}"; return 0; }
  l="$(LC_ALL=C grep -F 'ln -s' "$_b21r_d/block")"
  g="$(_b21r_guard "$l")"; [ "$g" = ok ] || { printf '%s\n' "$g"; return 0; }
  ( cd "$_b21r_D" && HOME="$_b21r_H" bash -c "$l" ) > "$_b21r_d/a26.out" 2>&1; rc=$?
  if [ "$rc" -eq 0 ] && [ -L "$_b21r_H/.local/bin/felix" ] && [ "$_b21r_H/.local/bin/felix" -ef "$_b21r_D/felix/engine/harness/felix" ]; then
    printf 'ok\n'
  else
    printf '[%s] exited %s, said [%s], and left %s\n' "$l" "$rc" "$(cat "$_b21r_d/a26.out")" "$(ls -ld "$_b21r_H/.local/bin/felix" 2>&1)"
  fi
}
_b21r_say "README claims, A26: the install block's link line, run in a scratch home, links felix there" "$(_b21r_v _b21r_a26)"
