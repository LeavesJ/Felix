# >>> trust-step4-reading
printf '\ntrust plane step 4, slice 1: how his statements are read, the decision for a candidate, founder paths and the ledger (spec-slice1 K1 to K9, W9; blind)\n'
# Blind, written on 2026-11-12 from .felix/memory/felix/audits/2026-11-13-trust-step4-shadow/spec-slice1.md alone
# (sections 2.4 and 2.5, with 0, 3, 6 and 7), before felix authority existed, by an author who has seen no
# implementation of it. Of the 11-10 mock, spike/cases-door.sh was read for how V5, V6, V31 and V43 were staged, and
# nothing else. The helpers are tests/lib/trust-step4.sh. Everything is under $TMP/ts4-reading.
#
# One authority, shadow by construction (this login is the user and the worker): K1 reads each statement there, so
# the order of his statements decides as it would in live standing, and a tick moves main forward with the source's
# (W11), which is how main moves under an override (K6) and how the policy at main is made unreadable (W9). Each
# statement is given through the door as the founder would give it, and its number is taken from the door's kept:
# line, never assumed.
#
# The source: main (M1, M2) with section 7's policy, and twenty-three branches: plain (ordinary), clean (cut from M1,
# merges cleanly), clash (conflicts), same (the change main already holds) and empty (no change); dir, case, table,
# swap, nl, hi and mv (founder paths: the row's path, its path in another case, the land table itself, a change
# that also renames the project and brings a table with no row, a name with a newline, a name with a byte above
# 0x7e, and a rename away from the row's path); fup, fsub and tcase (rev 3, case 15: a file .FELIX, a file under
# .felix in place of it, and the land table's path in another case); h1, h2 (cut from h1) and h1b (h1's edit under
# another commit id); rel and auth; anc and desc (cut from anc, changes docs/direction.md); and ov (cut from M1,
# merges cleanly, changes docs/direction.md).
#
# Readings, where the spec leaves room:
# - "The first such path" in a waits detail is the first in the order git lists the changed paths.
# - Policy is read from B alone, and since rev 3 .felix is itself the founder's: swap, which renames the project,
#   waits for .felix, the first of its paths. fsub must take the file .felix away to put a file under it, so what
#   it waits for is .felix too.
# - Rev 3. Case 17's attributes file is the user's default one, $XDG_CONFIG_HOME/git/attributes, with HOME pointed
#   at the same fixture directory; a control shows that plain git, there, merges the conflicting head by union.
#   W10's store attributes: with info/attributes in the store, tick, decide, status and the door each print a
#   line that starts felix: to stderr and exit 1. Case 18: the four names are set to values in the environment and
#   the whole output of a tick, and of decide, is compared with the output without them, once with the word go
#   and once under stop. D2: an override in effect is on a line that starts in-effect: with its number, and once
#   main has moved under it, on a line that starts lapsed: , and on no in-effect: line.
# - Renames off: mv deletes docs/direction.md and adds its bytes under another name; the deleted path is changed.
# - A release that passed no hold is not leaned on: the detail stays -.
# - When two holds cover a head, the statement number in its held detail is not asserted, only the decision.
# - A release given after a hold that ended an override leaves the head at what K7 says without the override, with
#   that row's detail and nothing after it; K6's ending is asked for only where the tree differs or conflicts.
# - A land table "the schema refuses a row of" is one with a row of three cells.
# - K8: decide appends no row (the rule names a tick). Rows under stop are not counted: the spec does not say whether
#   a tick that prints no candidate line writes any.
# - K9: the source's refs are the same after a tick as before it, and the store's main is the source's main itself.
#
# Not covered: K1 in live standing, where only statements that count are read, and a log the reader refuses (2189);
# a hold of a commit in main's own history, which K3's words make cover every candidate; two founder paths whose
# order differs by rule; an override under an unreadable policy; a source with more than one project; W9's function
# as one function (only that the tick and the card agree, in 2187); the time a ledger row carries.
_ts4_begin ts4-reading
TS4K_S="$TS4/src.git"; TS4K_A="$TS4/a"; TS4K_O="$TS4/door.a.out"
TS4K_W=", which waits for the founder's authorization of this head"
TS4K_U="the founder-path policy at main cannot be read, so each path waits for him"
_ts4_src "$TS4K_S"; _ts4_base "$TS4K_S"; TS4K_M1="$TS4_M1"; TS4K_M2="$TS4_M2"
_ts4_ci "$TS4K_S" plain "$TS4K_M2" 'an ordinary change' notes/plain.txt; TS4K_HP="$TS4_C"
_ts4_tree "$TS4K_S" "$TS4K_M1"; _ts4_f "$TS4K_S" 'alpha by a worker' hotel; _ts4_seal "$TS4K_S" clean "$TS4K_M1" 'a change that merges cleanly'; TS4K_HCL="$TS4_C"
_ts4_tree "$TS4K_S" "$TS4K_M1"; _ts4_f "$TS4K_S" alpha 'hotel by a worker'; _ts4_seal "$TS4K_S" clash "$TS4K_M1" 'a change that conflicts'; TS4K_HX="$TS4_C"
_ts4_tree "$TS4K_S" "$TS4K_M1"; _ts4_f "$TS4K_S" alpha 'hotel on main'; _ts4_stage "$TS4K_S" main/only "main's own$TS4_NL"; _ts4_seal "$TS4K_S" same "$TS4K_M1" 'the change main already holds'
_ts4_ci "$TS4K_S" empty "$TS4K_M2" 'a commit that changes nothing'
_ts4_ci "$TS4K_S" dir "$TS4K_M2" 'a change of direction' docs/direction.md; TS4K_HD="$TS4_C"
_ts4_ci "$TS4K_S" case "$TS4K_M2" 'the same path in another case' DOCS/Direction.MD
_ts4_tree "$TS4K_S" "$TS4K_M2"; _ts4_stage "$TS4K_S" projects/proj/land.tsv "# no row$TS4_NL"; _ts4_stage "$TS4K_S" docs/note.md "another note$TS4_NL"; _ts4_seal "$TS4K_S" table "$TS4K_M2" 'the table and a note'
_ts4_tree "$TS4K_S" "$TS4K_M2"; _ts4_stage "$TS4K_S" .felix "other$TS4_NL"; _ts4_stage "$TS4K_S" projects/other/land.tsv "# no row$TS4_NL"; _ts4_stage "$TS4K_S" docs/direction.md "elsewhere$TS4_NL"
_ts4_seal "$TS4K_S" swap "$TS4K_M2" 'another project, and the direction'
_ts4_ci "$TS4K_S" nl "$TS4K_M2" 'a name with a newline' "docs/a${TS4_NL}b"; TS4K_HN="$TS4_C"
_ts4_ci "$TS4K_S" hi "$TS4K_M2" 'a name with a byte above 0x7e' "notes/caf$(printf '\303\251').txt"
_ts4_tree "$TS4K_S" "$TS4K_M2"; _ts4_drop "$TS4K_S" docs/direction.md; _ts4_stage "$TS4K_S" docs/elsewhere.md "where this goes$TS4_NL"; _ts4_seal "$TS4K_S" mv "$TS4K_M2" 'the direction, renamed'
_ts4_ci "$TS4K_S" fup "$TS4K_M2" 'a second policy root, in capitals' .FELIX
_ts4_tree "$TS4K_S" "$TS4K_M2"; _ts4_drop "$TS4K_S" .felix; _ts4_stage "$TS4K_S" .felix/x "proj$TS4_NL"; _ts4_seal "$TS4K_S" fsub "$TS4K_M2" 'a file under the policy root'
_ts4_ci "$TS4K_S" tcase "$TS4K_M2" 'the land table, in another case' PROJECTS/Proj/LAND.TSV
TS4_BODY='the held edit'; _ts4_ci "$TS4K_S" h1 "$TS4K_M2" 'an edit he holds' notes/h1.txt; TS4K_H1="$TS4_C"
_ts4_ci "$TS4K_S" h1b "$TS4K_M2" 'the same edit, committed again' notes/h1.txt; TS4K_H1B="$TS4_C"; TS4_BODY=""
_ts4_ci "$TS4K_S" h2 "$TS4K_H1" 'work on top of the held edit' notes/h2.txt; TS4K_H2="$TS4_C"
_ts4_ci "$TS4K_S" rel "$TS4K_M2" 'released, then held' notes/rel.txt; TS4K_HR="$TS4_C"
_ts4_ci "$TS4K_S" auth "$TS4K_M2" 'authorized, then held' docs/direction.md; TS4K_HA="$TS4_C"
_ts4_ci "$TS4K_S" anc "$TS4K_M2" 'an ordinary change others build on' notes/anc.txt; TS4K_HAN="$TS4_C"
_ts4_ci "$TS4K_S" desc "$TS4K_HAN" 'a change of direction on top of it' docs/direction.md; TS4K_HDE="$TS4_C"
_ts4_tree "$TS4K_S" "$TS4K_M1"; _ts4_f "$TS4K_S" 'alpha overridden' hotel; _ts4_stage "$TS4K_S" docs/direction.md "overridden$TS4_NL"; _ts4_seal "$TS4K_S" ov "$TS4K_M1" 'he overrides this'; TS4K_HO="$TS4_C"
TS4K_TC="$(_ts4_merge "$TS4K_S" "$TS4K_M2" "$TS4K_HCL")"; TS4K_TD="$(_ts4_merge "$TS4K_S" "$TS4K_M2" "$TS4K_HD")"; TS4K_TO="$(_ts4_merge "$TS4K_S" "$TS4K_M2" "$TS4K_HO")"

# ------------------------------------------------------------------ helpers ---
_ts4k_decs() {   # BRANCH...: "branch: decision|detail; " for each, from the lines of the last tick
  BS="$*" LC_ALL=C awk -F'\t' 'NF == 5 { d[$4] = $2 "|" $5 }
    END { n = split(ENVIRON["BS"], b, " "); for (i = 1; i <= n; i++) { k = "\"" b[i] "\""; printf "%s: %s; ", b[i], ((k in d) ? d[k] : "no line") } }' "$TS4/o"
}
_ts4k_say() { _ts4_say "$TS4K_A" "$1"; TS4K_N="${TS4_KEPT:-none}"; }   # LINE: one statement through the door; TS4K_N is its number
_ts4k_word() {   # stop|go: stop, confirmed by the word; go, confirmed by the four characters its card brackets in the nonce (D6)
  if [ "$1" = go ]; then _ts4_say "$TS4K_A" go; else _ts4_plain "$TS4K_A" stop stop; fi
  TS4K_N="${TS4_KEPT:-none}"
}
_ts4k_dd() { _ts4_dd "$TS4K_A" "$1"; }   # H: decide H -> TS4_DEC

# ------------------------------------------------------------------ controls ---
is "ts4 reading (control): git's own merge onto main is a tree for clean, dir and ov, a conflict for clash, and main's own tree for same and empty" \
  "$(for _ts4k_i in clean dir ov clash same empty; do printf '%s ' "$(_ts4_kind "$TS4K_S" "$TS4K_M2" "refs/heads/$_ts4k_i")"; done)" \
  "tree tree tree conflict nothing nothing "
is "ts4 reading (control): fsub's tree holds .felix/x and no file .felix, fup's holds .felix and .FELIX, and swap's .felix is another blob than main's" \
  "$(_fx_git "$TS4K_S" ls-tree -r --name-only refs/heads/fsub 2>/dev/null | LC_ALL=C awk '$0 == ".felix" { f = 1 } $0 == ".felix/x" { x = 1 } END { print (x && !f ? "under" : "not under") }') $(_fx_git "$TS4K_S" ls-tree --name-only refs/heads/fup 2>/dev/null | LC_ALL=C awk '$0 == ".felix" || $0 == ".FELIX" { n++ } END { print n + 0 }') $(if [ "$(_fx_git "$TS4K_S" rev-parse -q --verify refs/heads/swap:.felix 2>/dev/null)" != "$(_fx_git "$TS4K_S" rev-parse -q --verify "$TS4K_M2:.felix" 2>/dev/null)" ]; then printf another; else printf 'the same'; fi)" \
  "under 2 another"
is "ts4 reading (control): nl's tree holds a name with a newline, hi's one with the bytes c3 a9, mv's has no docs/direction.md, and h1b's tree is h1's under another commit id" \
  "$(_fx_git "$TS4K_S" ls-tree -r -z --name-only "$TS4K_HN" 2>/dev/null | LC_ALL=C od -An -v -tx1 | LC_ALL=C awk '{ for (i = 1; i <= NF; i++) c[$i]++ } END { print c["0a"] + 0 }') $(_fx_git "$TS4K_S" ls-tree -r -z --name-only refs/heads/hi 2>/dev/null | LC_ALL=C tr '\0' '\n' | E="$(printf '\303\251')" LC_ALL=C awk 'index($0, ENVIRON["E"]) { n++ } END { print n + 0 }') $(_ts4_yn _fx_git "$TS4K_S" cat-file -e refs/heads/mv:docs/direction.md) $(if [ "$(_ts4_ctree "$TS4K_S" "$TS4K_H1")" = "$(_ts4_ctree "$TS4K_S" "$TS4K_H1B")" ] && [ "$TS4K_H1" != "$TS4K_H1B" ]; then printf 'one tree, two ids'; else printf differ; fi)" \
  "1 1 no one tree, two ids"

# ------------------------------------------------------------------ the decision, with no word of his but the start (K7, W9, K8) ---
_ts4_init "$TS4K_A" "$TS4_ME" "$TS4K_S"; _ts4k_say "start $TS4K_M2"; _ts4_a "$TS4K_A" tick
_ts4_is "ts4 reading K7: with nothing said but the start, an ordinary change and a clean merge are eligible, a head that does not merge conflicts, and a head whose merge is main's tree changes nothing" \
  "$(_ts4k_decs plain clean clash same empty)$(LC_ALL=C awk 'END { print $0 }' "$TS4/o")" \
  "plain: eligible|-; clean: eligible|-; clash: conflict|conflicts with main; same: nothing|changes nothing; empty: nothing|changes nothing; tick: shadow, 23 candidates" "$(_ts4_why)"
_ts4_is "ts4 reading W9: a change of the path a founder row names, of that path in another case, and of the land table itself waits for his authorization, naming the path shown escaped" \
  "$(_ts4k_decs dir case table)" "dir: waits|changes \"docs/direction.md\"$TS4K_W; case: waits|changes \"DOCS/Direction.MD\"$TS4K_W; table: waits|changes \"projects/proj/land.tsv\"$TS4K_W; " "$(_ts4_why)"
_ts4_is "ts4 reading W9, case 15: a candidate that renames the project in .felix and brings a table with no row chose no policy of its own: it waits for .felix, the first of its paths" \
  "$(_ts4k_decs swap)" "swap: waits|changes \".felix\"$TS4K_W; " "$(_ts4_why)"
_ts4_is "ts4 reading case 15, W9: a candidate that adds .FELIX, one that puts a file under .felix, and one that adds the land table's path in another case each wait for his authorization" \
  "$(_ts4k_decs fup fsub tcase)" "fup: waits|changes \".FELIX\"$TS4K_W; fsub: waits|changes \".felix\"$TS4K_W; tcase: waits|changes \"PROJECTS/Proj/LAND.TSV\"$TS4K_W; " "$(_ts4_why)"
_ts4_is "ts4 reading W9: changed paths are read with renames off: a candidate that moves the founder's path to another name waits for the path it took away" \
  "$(_ts4k_decs mv)" "mv: waits|changes \"docs/direction.md\"$TS4K_W; " "$(_ts4_why)"
_ts4_is "ts4 reading case 6, W9: a candidate that adds a file whose name holds a newline waits for his authorization, and the tick shows the name with \\x0a; so does one whose name holds a byte above 0x7e" \
  "$(_ts4k_decs nl hi)" "nl: waits|changes \"docs/a\\x0ab\"$TS4K_W; hi: waits|changes \"notes/caf\\xc3\\xa9.txt\"$TS4K_W; " "$(_ts4_why)"
_ts4_is "ts4 reading K8: that first tick wrote one ledger row of seven fields for each candidate" \
  "$(LC_ALL=C awk -F'\t' 'NF != 7 || $1 == "" { b++ } { h[$4]++ } END { n = 0; for (k in h) n++; print NR " rows, " n " heads, " b + 0 " bad" }' "$TS4K_A/ledger.tsv" 2>/dev/null)" "23 rows, 23 heads, 0 bad"
_ts4_is "ts4 reading K8: a row holds the standing, the decision, the head, main, the tree the merge made or - and the detail" \
  "$(_ts4_lrow "$TS4K_A" "$TS4K_HCL"); $(_ts4_lrow "$TS4K_A" "$TS4K_HX"); $(_ts4_lrow "$TS4K_A" "$TS4K_HD")" \
  "7:shadow|eligible|$TS4K_HCL|$TS4K_M2|$TS4K_TC|-; 7:shadow|conflict|$TS4K_HX|$TS4K_M2|-|conflicts with main; 7:shadow|waits|$TS4K_HD|$TS4K_M2|$TS4K_TD|changes \"docs/direction.md\"$TS4K_W"
_ts4_a "$TS4K_A" tick; TS4K_V="tick: $(_ts4_ledger "$TS4K_A")"; _ts4k_dd "$TS4K_HP"
_ts4_is "ts4 reading K8: a second tick with nothing changed adds no row, and decide adds none" "$TS4K_V; decide: $(_ts4_ledger "$TS4K_A"), ${TS4_DEC%%|*}" "tick: 23; decide: 23, eligible"

# ------------------------------------------------------------------ what the caller brings: attributes and variables (W10, cases 17 and 18) ---
mkdir -p "$TS4/x/uhome/.config/git"; printf '* merge=union\n' > "$TS4/x/uhome/.config/git/attributes"
TS4K_V="$( export HOME="$TS4/x/uhome" XDG_CONFIG_HOME="$TS4/x/uhome/.config" GIT_CONFIG_NOSYSTEM=1; unset GIT_CONFIG_GLOBAL GIT_ATTR_SOURCE; _fx_git "$TS4K_S" merge-tree --write-tree "$TS4K_M2" "$TS4K_HX" >/dev/null 2>&1 && printf merges )"
if [ "$TS4K_V" = merges ]; then
  ok "ts4 reading case 17 (control): with * merge=union in the user's attributes file, plain git here merges the head that conflicts with main"
  TS4_ENV=(HOME="$TS4/x/uhome" XDG_CONFIG_HOME="$TS4/x/uhome/.config"); _ts4_a "$TS4K_A" tick; TS4K_V="tick: $(_ts4_of "$TS4K_HX")"; _ts4k_dd "$TS4K_HX"; TS4_ENV=()
  _ts4_is "ts4 reading case 17, W10: with * merge=union in the user's attributes file, a head that conflicts with main still reads conflict, in a tick and in decide" \
    "$TS4K_V; decide: $TS4_DEC" "tick: conflict|conflicts with main; decide: conflict|conflicts with main" "$(_ts4_why)"
else
  skip "ts4 reading case 17 (control): with * merge=union in the user's attributes file, plain git here merges the head that conflicts with main" "plain git's merge here is not changed by that file, so nothing is staged"
  skip "ts4 reading case 17, W10: with * merge=union in the user's attributes file, a head that conflicts with main still reads conflict, in a tick and in decide" "plain git's merge here is not changed by that file, so nothing is staged"
fi
[ ! -d "$TS4K_A/store.git" ] || { mkdir -p "$TS4K_A/store.git/info"; printf '* merge=union\n' > "$TS4K_A/store.git/info/attributes"; }
TS4K_V=""
for _ts4k_i in tick "decide $TS4K_HX" status door; do
  case "$_ts4k_i" in door) _ts4_x "$TS4K_A" /dev/null door ;; *) _ts4_a "$TS4K_A" $_ts4k_i ;; esac
  TS4K_V="$TS4K_V${_ts4k_i%% *}: exit $TS4_RC, felix: $(_ts4_yn test "$(_ts4_count 'felix: ' "$TS4/e")" -gt 0), candidate lines: $(_ts4_cands) | "
done
rm -f "$TS4K_A/store.git/info/attributes"; _ts4k_dd "$TS4K_HX"
_ts4_is "ts4 reading W10: a store that holds info/attributes is refused by tick, decide, status and the door, each with a line that starts felix: and exit 1; with the file gone, decide reads the head again" \
  "$TS4K_V then: $TS4_DEC" "tick: exit 1, felix: yes, candidate lines: 0 | decide: exit 1, felix: yes, candidate lines: 0 | status: exit 1, felix: yes, candidate lines: 0 | door: exit 1, felix: yes, candidate lines: 0 |  then: conflict|conflicts with main" "$(_ts4_why)"
_ts4_a "$TS4K_A" tick; cp "$TS4/o" "$TS4/x/tick.plain" 2>/dev/null; _ts4_a "$TS4K_A" decide "$TS4K_HD"; cp "$TS4/o" "$TS4/x/decide.plain" 2>/dev/null
TS4_ENV=(_FP_AT="$TS4K_HP" _FP_AT_UNREADABLE=1 _FP_AT_N=7 _FD_NOSTOP=1); _ts4_a "$TS4K_A" tick; cp "$TS4/o" "$TS4/x/tick.vars" 2>/dev/null; _ts4_a "$TS4K_A" decide "$TS4K_HD"; cp "$TS4/o" "$TS4/x/decide.vars" 2>/dev/null; TS4_ENV=()
_ts4_is "ts4 reading case 18: with _FP_AT, _FP_AT_UNREADABLE, _FP_AT_N and _FD_NOSTOP set in the environment, a tick and decide print what they print without them" \
  "tick: $(LC_ALL=C awk 'END { print NR }' "$TS4/x/tick.plain" 2>/dev/null) lines, $(if cmp -s "$TS4/x/tick.plain" "$TS4/x/tick.vars"; then printf same; else printf differs; fi); decide: $(tr '\t' '|' < "$TS4/x/decide.plain" 2>/dev/null | cut -d'|' -f2), $(if cmp -s "$TS4/x/decide.plain" "$TS4/x/decide.vars"; then printf same; else printf differs; fi)" \
  "tick: 24 lines, same; decide: waits, same" "$(_ts4_why)"

# ------------------------------------------------------------------ hold and release (K3, K4, case 4) ---
_ts4k_say "hold $TS4K_H1"; TS4K_N1="$TS4K_N"; _ts4_a "$TS4K_A" tick
_ts4_is "ts4 reading K3: a hold of a commit holds that head and a head whose history holds it, each naming the statement and the commit held, and not the same edit under a new commit id" \
  "$(_ts4k_decs h1 h2 h1b)" "h1: held|statement $TS4K_N1 holds $TS4K_H1; h2: held|statement $TS4K_N1 holds $TS4K_H1; h1b: eligible|-; " "$(_ts4_why)"
_ts4_is "ts4 reading K8: that tick added a row for each of the two heads whose decision changed, and for no other" "$(_ts4_ledger "$TS4K_A"); $(_ts4_lrow "$TS4K_A" "$TS4K_H2" | cut -d'|' -f2)" "25; held"
_ts4k_say "release $TS4K_H1"; TS4K_N2="$TS4K_N"; _ts4_a "$TS4K_A" tick
_ts4_is "ts4 reading K4: a release names one exact head: it passes the hold for that head, which is eligible and leans on the release, and the head built on it stays held" \
  "$(_ts4k_decs h1 h2)rows: $(_ts4_ledger "$TS4K_A")" "h1: eligible|leans on statement $TS4K_N2; h2: held|statement $TS4K_N1 holds $TS4K_H1; rows: 26" "$(_ts4_why)"
_ts4k_say "hold $TS4K_H1"; _ts4k_dd "$TS4K_H1"
_ts4_is "ts4 reading K4: a hold given after the release holds again" "$TS4_DEC" "held|statement $TS4K_N holds $TS4K_H1" "$(_ts4_why)"
_ts4k_say "release $TS4K_HR"; _ts4k_dd "$TS4K_HR"; TS4K_V="$TS4_DEC"; _ts4k_say "hold $TS4K_HR"; _ts4k_dd "$TS4K_HR"
_ts4_is "ts4 reading case 4, K4: a release of a head no hold covers is leaned on by nothing, and release then hold of one head leaves it held" "$TS4K_V; $TS4_DEC" "eligible|-; held|statement $TS4K_N holds $TS4K_HR" "$(_ts4_why)"

# ------------------------------------------------------------------ permissions (K5, case 4) ---
_ts4k_say "authorize $TS4K_HA"; _ts4k_dd "$TS4K_HA"
_ts4_is "ts4 reading K5, K7: an authorization of a head that changes a founder path makes it eligible, leaning on that statement" "$TS4_DEC" "eligible|leans on statement $TS4K_N" "$(_ts4_why)"
_ts4k_say "hold $TS4K_HA"; _ts4k_dd "$TS4K_HA"
_ts4_is "ts4 reading case 4, K7: authorize then hold: the head is held, for an authorization lifts no hold" "$TS4_DEC" "held|statement $TS4K_N holds $TS4K_HA" "$(_ts4_why)"
_ts4k_say "release $TS4K_HA"; TS4K_N1="$TS4K_N"; _ts4k_dd "$TS4K_HA"
_ts4_is "ts4 reading case 4, K5: a release after that hold does not bring the authorization back: the head waits for a new one" "$TS4_DEC" "waits|changes \"docs/direction.md\"$TS4K_W" "$(_ts4_why)"
_ts4k_say "authorize $TS4K_HA"; _ts4k_dd "$TS4K_HA"
_ts4_is "ts4 reading K7: given again, the authorization makes it eligible, leaning on the release that passed the hold and on the new authorization" "$TS4_DEC" "eligible|leans on statements $TS4K_N1,$TS4K_N" "$(_ts4_why)"
_ts4k_say "authorize $TS4K_H2"; _ts4k_dd "$TS4K_H2"
_ts4_is "ts4 reading K7: an authorization of a head that a hold covers lifts no hold" "kept: $TS4K_N; ${TS4_DEC%%|*}" "kept: $(( $(_ts4_n "$TS4K_A") - 1 )); held" "$(_ts4_why)"
_ts4k_say "authorize $TS4K_HDE"; _ts4k_dd "$TS4K_HDE"; TS4K_V="$TS4_DEC"; TS4K_N1="$TS4K_N"; _ts4k_say "hold $TS4K_HAN"; TS4K_N2="$TS4K_N"; _ts4k_dd "$TS4K_HDE"
_ts4_is "ts4 reading K3, K5: a hold of a commit in an authorized head's history, given after the authorization, holds that head" "$TS4K_V; $TS4_DEC" "eligible|leans on statement $TS4K_N1; held|statement $TS4K_N2 holds $TS4K_HAN" "$(_ts4_why)"
_ts4k_say "release $TS4K_HDE"; _ts4k_dd "$TS4K_HDE"; TS4K_V="$TS4_DEC"; _ts4k_dd "$TS4K_HAN"
_ts4_is "ts4 reading K4, K5: released, that head waits, its authorization ended by the hold, and the commit held is still held" "$TS4K_V; $TS4_DEC" "waits|changes \"docs/direction.md\"$TS4K_W; held|statement $TS4K_N2 holds $TS4K_HAN" "$(_ts4_why)"
_ts4k_say "hold $TS4K_HX"; _ts4k_dd "$TS4K_HX"; TS4K_V="$TS4_DEC"; TS4K_N1="$TS4K_N"; _ts4k_say "release $TS4K_HX"; _ts4k_dd "$TS4K_HX"
_ts4_is "ts4 reading K7: held comes before conflict: a held head that does not merge is held, and released it conflicts" "$TS4K_V; $TS4_DEC" "held|statement $TS4K_N1 holds $TS4K_HX; conflict|conflicts with main" "$(_ts4_why)"

# ------------------------------------------------------------------ an override, and stop (K2, K5 to K7) ---
_ts4k_say "hold $TS4K_HO"; _ts4_open "$TS4K_A" a "override $TS4K_HO"
TS4K_V="$(_ts4_line 'lands-as: ' "$TS4K_O"); $(_ts4_line 'tree: ' "$TS4K_O")"; _ts4_close a "override $TS4_FOUR"; TS4K_N="${TS4_KEPT:-none}"; TS4K_NO="$TS4K_N"; _ts4k_dd "$TS4K_HO"
_ts4_is "ts4 reading K5, D8: an override's card shows the tree the head would land as, and the statement kept names the head and that tree" \
  "$TS4K_V; $(_ts4_fs "$TS4K_A" "${TS4_KEPT:-999}" 'verb commit tree')" "lands-as: tree $TS4K_TO; tree: $TS4K_TO; override|$TS4K_HO|$TS4K_TO" "$(_ts4_dwhy)"
_ts4_is "ts4 reading K7: an override in effect decides, passing over a hold given before it, though the head changes a founder path" "$TS4_DEC" "override|statement $TS4K_NO overrides the judge for tree $TS4K_TO" "$(_ts4_why)"
_ts4k_say "hold $TS4K_HO"; _ts4k_dd "$TS4K_HO"; TS4K_V="$TS4_DEC"; TS4K_N1="$TS4K_N"; _ts4k_say "release $TS4K_HO"; _ts4k_dd "$TS4K_HO"
_ts4_is "ts4 reading K5: a hold given after the override holds the head, and a release after that hold does not bring the override back: the head waits" \
  "$TS4K_V; $TS4_DEC" "held|statement $TS4K_N1 holds $TS4K_HO; waits|changes \"docs/direction.md\"$TS4K_W" "$(_ts4_why)"
_ts4k_say "override $TS4K_HO"; TS4K_NO="$TS4K_N"; _ts4k_dd "$TS4K_HO"
_ts4_is "ts4 reading K5: given again, the override is in effect" "$TS4_DEC" "override|statement $TS4K_NO overrides the judge for tree $TS4K_TO" "$(_ts4_why)"
_ts4_plain "$TS4K_A"
_ts4_is "ts4 reading D2: the door reads that override back on a line starting in-effect: , with its number, and on no line starting lapsed: " \
  "in-effect: $(_ts4_numon 'in-effect: ' "${TS4K_NO:-none}" "$TS4K_O"); lapsed: $(_ts4_numon 'lapsed: ' "${TS4K_NO:-none}" "$TS4K_O")" "in-effect: yes; lapsed: no" "$(_ts4_dwhy)"
_ts4k_word stop; TS4K_N1="$TS4K_N"; _ts4_a "$TS4K_A" tick; TS4K_V="said: $(_ts4_said "stopped by the founder at the door (statement $TS4K_N1)" "$TS4/o"); candidate lines: $(_ts4_cands)"; cp "$TS4/o" "$TS4/x/tick.plain" 2>/dev/null; _ts4_a "$TS4K_A" status
_ts4_is "ts4 reading K2: with stop a tick prints the one line stopped by the founder at the door (statement N) and no candidate line, and status says the word is stop" "$TS4K_V; word: $(_ts4_sv word)" "said: yes; candidate lines: 0; word: stop" "$(_ts4_why)"
TS4_ENV=(_FP_AT="$TS4K_HP" _FP_AT_UNREADABLE=1 _FP_AT_N=7 _FD_NOSTOP=1); _ts4_a "$TS4K_A" tick; TS4K_V="tick: $(_ts4_count 'stopped by the founder' "$TS4/o") stopped line(s), $(if cmp -s "$TS4/x/tick.plain" "$TS4/o"; then printf same; else printf differs; fi)"; _ts4k_dd "$TS4K_HP"; TS4_ENV=()
_ts4_is "ts4 reading case 18, K2: under stop, with the same four names set in the environment, a tick still prints the stopped line alone and decide still says stopped" \
  "$TS4K_V; decide: $TS4_DEC" "tick: 1 stopped line(s), same; decide: stopped|statement $TS4K_N1" "$(_ts4_why)"
_ts4k_dd "$TS4K_HO"; TS4K_V="$TS4_DEC"; _ts4k_dd "$TS4K_HP"
_ts4_is "ts4 reading K2, K7: decide says stopped and the statement, of an ordinary head and of an overridden one alike: an override does not pass over a stop" "$TS4K_V; $TS4_DEC" "stopped|statement $TS4K_N1; stopped|statement $TS4K_N1" "$(_ts4_why)"
_ts4k_word go; _ts4k_dd "$TS4K_HP"; TS4K_V="$TS4_DEC"; _ts4k_word stop; _ts4k_dd "$TS4K_HP"; TS4K_V="$TS4K_V; $TS4_DEC"; TS4K_N1="$TS4K_N"; _ts4k_word go; _ts4_a "$TS4K_A" tick
TS4K_V="$TS4K_V; $(_ts4k_decs plain ov)candidate lines: $(_ts4_cands)"; TS4K_W2="$(_ts4_ledger "$TS4K_A")"; _ts4_a "$TS4K_A" status
_ts4_is "ts4 reading K2: the later of stop and go decides: after go the head is eligible, after a second stop it is stopped by that statement, and after a second go a tick decides each candidate again" \
  "$TS4K_V; word: $(_ts4_sv word)" "eligible|-; stopped|statement $TS4K_N1; plain: eligible|-; ov: override|statement $TS4K_NO overrides the judge for tree $TS4K_TO; candidate lines: 23; word: go" "$(_ts4_why)"

# ------------------------------------------------------------------ main moves under an override (K6, K8, case 5) ---
_ts4_tree "$TS4K_S" "$TS4K_M2"; _ts4_f "$TS4K_S" alpha 'hotel on main' 'delta on main'; _ts4_seal "$TS4K_S" main "$TS4K_M2" 'main moves under the override'; TS4K_M3="$TS4_C"
_ts4_tree "$TS4K_S" "$TS4K_M3"; _ts4_f "$TS4K_S" 'alpha on main' 'hotel on main' 'delta on main'; _ts4_seal "$TS4K_S" - "$TS4K_M3" 'main takes the first line'; TS4K_M4="$TS4_C"
TS4K_V="$(_ts4_merge "$TS4K_S" "$TS4K_M3" "$TS4K_HO")"
is "ts4 reading (control): onto main as it moves first, git's merge of the overridden head is another tree than he was shown, and onto main as it moves next it conflicts" \
  "$(if [ -n "$TS4K_V" ] && [ "$TS4K_V" != conflict ] && [ "$TS4K_V" != "$TS4K_TO" ]; then printf 'another tree'; else printf 'not another tree'; fi); $(_ts4_merge "$TS4K_S" "$TS4K_M4" "$TS4K_HO")" "another tree; conflict"
_ts4_a "$TS4K_A" tick
_ts4_is "ts4 reading case 5, K6: when main has moved so that the merge is another tree, the override is not in effect: the head waits, and the detail ends ; override N names another tree" \
  "main: $(_ts4_main "$TS4K_A"); $(_ts4k_decs ov)" "main: $TS4K_M3; ov: waits|changes \"docs/direction.md\"$TS4K_W; override $TS4K_NO names another tree; " "$(_ts4_why)"
_ts4_is "ts4 reading K8: main having moved, that tick wrote a row for each candidate, with the new main" \
  "$(( $(_ts4_ledger "$TS4K_A") - ${TS4K_W2:-0} )) more; $(_ts4_lrow "$TS4K_A" "$TS4K_HP")" "23 more; 7:shadow|eligible|$TS4K_HP|$TS4K_M3|$(_ts4_merge "$TS4K_S" "$TS4K_M3" "$TS4K_HP")|-"
_ts4_plain "$TS4K_A"
_ts4_is "ts4 reading D2, K6: with main moved under it, the door reads the override back on a line starting lapsed: , with its number, and no longer on a line starting in-effect: " \
  "lapsed: $(_ts4_numon 'lapsed: ' "${TS4K_NO:-none}" "$TS4K_O"); in-effect: $(_ts4_numon 'in-effect: ' "${TS4K_NO:-none}" "$TS4K_O")" "lapsed: yes; in-effect: no" "$(_ts4_dwhy)"
_fx_git "$TS4K_S" update-ref refs/heads/main "$TS4K_M4" >/dev/null 2>&1; _ts4_a "$TS4K_A" tick
_ts4_is "ts4 reading K6: when main has moved so that the merge conflicts, the head conflicts, and the detail ends ; override N names another tree" \
  "$(_ts4k_decs ov)" "ov: conflict|conflicts with main; override $TS4K_NO names another tree; " "$(_ts4_why)"

# ------------------------------------------------------------------ a policy that cannot be read (W9) ---
_ts4_tree "$TS4K_S" "$TS4K_M4"; _ts4_stage "$TS4K_S" projects/proj/land.tsv 'docs/direction\.md'"${TS4_TAB}founder$TS4_TAB-$TS4_TAB-${TS4_NL}docs/x${TS4_TAB}founder$TS4_TAB-$TS4_NL"
_ts4_seal "$TS4K_S" main "$TS4K_M4" 'a table with a row of three cells'; TS4K_M5="$TS4_C"; _ts4_a "$TS4K_A" tick
_ts4_is "ts4 reading W9: when main's land table holds a row the schema refuses, the policy cannot be read and an ordinary change waits, saying so" \
  "main: $(_ts4_main "$TS4K_A"); $(_ts4k_decs h1b)" "main: $TS4K_M5; h1b: waits|$TS4K_U; " "$(_ts4_why)"
_ts4k_say "authorize $TS4K_HP"; _ts4k_dd "$TS4K_HP"
_ts4_is "ts4 reading W9, K7: under such a policy his authorization of a head is what makes it eligible" "$TS4_DEC" "eligible|leans on statement $TS4K_N" "$(_ts4_why)"
_ts4_tree "$TS4K_S" "$TS4K_M5"; _ts4_drop "$TS4K_S" projects/proj/land.tsv; _ts4_seal "$TS4K_S" main "$TS4K_M5" 'no land table'; TS4K_M6="$TS4_C"; _ts4_a "$TS4K_A" tick
_ts4_is "ts4 reading W9: when main has no land table, the policy cannot be read and an ordinary change waits, saying so" \
  "main: $(_ts4_main "$TS4K_A"); $(_ts4k_decs h1b)" "main: $TS4K_M6; h1b: waits|$TS4K_U; " "$(_ts4_why)"
_ts4_tree "$TS4K_S" "$TS4K_M6"; _ts4_drop "$TS4K_S" .felix
_ts4_stage "$TS4K_S" projects/proj/land.tsv 'docs/direction\.md'"${TS4_TAB}founder$TS4_TAB-$TS4_TAB-$TS4_NL"; _ts4_seal "$TS4K_S" main "$TS4K_M6" 'a table again, and no .felix'; TS4K_M7="$TS4_C"; _ts4_a "$TS4K_A" tick
_ts4_is "ts4 reading W9: when main has no .felix, the policy cannot be read and an ordinary change waits, saying so" \
  "main: $(_ts4_main "$TS4K_A"); $(_ts4k_decs h1b)" "main: $TS4K_M7; h1b: waits|$TS4K_U; " "$(_ts4_why)"
is "ts4 reading (control): main as it moved holds a table with a row of three cells, then no table, then a table and no .felix" \
  "$(_fx_git "$TS4K_S" cat-file -p "$TS4K_M5:projects/proj/land.tsv" 2>/dev/null | LC_ALL=C awk -F'\t' 'NF == 3 { n++ } END { print n + 0 }') $(_ts4_yn _fx_git "$TS4K_S" cat-file -e "$TS4K_M6:projects/proj/land.tsv") $(_ts4_yn _fx_git "$TS4K_S" cat-file -e "$TS4K_M6:.felix") $(_ts4_yn _fx_git "$TS4K_S" cat-file -e "$TS4K_M7:projects/proj/land.tsv") $(_ts4_yn _fx_git "$TS4K_S" cat-file -e "$TS4K_M7:.felix")" "1 no yes yes no"
_ts4_tree "$TS4K_S" "$TS4K_M7"; _ts4_stage "$TS4K_S" .felix "proj$TS4_NL"; _ts4_seal "$TS4K_S" main "$TS4K_M7" 'the policy, whole again'; TS4K_M8="$TS4_C"
TS4K_V="$(_fx_git "$TS4K_S" for-each-ref 2>/dev/null)"; _ts4_a "$TS4K_A" tick
_ts4_is "ts4 reading W9: with .felix and a table the schema takes back at main, the ordinary change is eligible again and the founder's path waits" \
  "$(_ts4k_decs h1b dir)" "h1b: eligible|-; dir: waits|changes \"docs/direction.md\"$TS4K_W; " "$(_ts4_why)"
_ts4_is "ts4 reading K9, W11: nothing lands: after that tick the source's refs are as they were, and the store's main is the source's main itself" \
  "source: $(if [ -n "$TS4K_V" ] && [ "$(_fx_git "$TS4K_S" for-each-ref 2>/dev/null)" = "$TS4K_V" ]; then printf 'as it was'; else printf changed; fi); main: $(_ts4_main "$TS4K_A")" "source: as it was; main: $TS4K_M8"

_ts4_end
unset TS4K_S TS4K_A TS4K_O TS4K_W TS4K_U TS4K_M1 TS4K_M2 TS4K_M3 TS4K_M4 TS4K_M5 TS4K_M6 TS4K_M7 TS4K_M8 TS4K_HP TS4K_HCL TS4K_HX TS4K_HD TS4K_HN TS4K_H1 TS4K_H1B TS4K_H2 \
  TS4K_HR TS4K_HA TS4K_HAN TS4K_HDE TS4K_HO TS4K_TC TS4K_TD TS4K_TO TS4K_V TS4K_N TS4K_N1 TS4K_N2 TS4K_NO TS4K_W2 _ts4k_i
# <<< trust-step4-reading
