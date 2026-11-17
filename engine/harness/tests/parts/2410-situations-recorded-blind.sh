printf '\n%s\n' 'situations: recorded readings (blind)'
# Blind, written on 2026-10-31 from docs/2026-10-29-capability-lane-first-slices-design.md (sections 3, 4, 7, 10, 11) and
# the slice 1 plan's Contracts and Review Focus (C1 to C16) alone, before lib/situations*.sh existed, without reading
# felix, lib/, hooks/ or bin/. felix situations and felix probes are run as black boxes. C16's row for this part: section
# 7.3's recorded readings, 7.4, C3.1, C3.2, C4 (every term rule), the undecided term named beside a DORMANT class (C7),
# C3.4 for --at, C2's --at exits, C10's recorded reasons, and the --at header both ways.
#
# The fixture: an engine copy whose situations.tsv is substituted (twenty classes, one per rule), a home H with project
# ledgerly (maturity internal unless a case rewrites project.json between runs), a checkout C bound by a committed .felix,
# and memory roots: M1 holds a hand-written facts.log; M2 the same log with felix probes' run of the live tree appended;
# M3 an unborn checkout's run; MA, ME and MU an absent log, an empty one and one of unknown-tree rows and short lines.
# M1's log, in file order: an old run of tree-a stamped 15:00 that contradicts the new one; two tree-z rows with the new
# run's stamp; the new run of tree-a stamped 11:00 (8- and 9-field rows, a 7-field line, a predicate twice); a one-row
# run of tree-s at 10:00 whose state is stale, outside the five (C17.6, added 2026-11-05 from C17 alone); tree-b at
# 12:00 (the newest tree by file order, though tree-a's old stamp sorts later); unknown-tree rows at 16:00; and a 7-field
# tree-c line at 17:00. So an engine that takes the greatest stamp, keys a run on its stamp alone, reads a short line or
# a predicate's last line, or takes unknown-tree for a tree, prints other values than these.
# Readings where the Contracts leave room:
# - In --at mode a residual why names the side "at" (the Notation: a side is base, head, or, in --at mode, at).
# - A cap: term's grounds keep its "<pred> no reading (<c>)" items: C7 gives it the probe term's items less the
#   not-applicable rows.
# - env:maturity>=gold is a term in another form (C4), so its could-not-look why is "not a term this slice can evaluate".
# - "maturity": "" in project.json declares no maturity (C4: an empty string is "declares no maturity").
# - C2's order puts usage errors first: --at with no value, in a directory no project governs, still exits 1.
# - Tree ids in the hand-written log are not hex: C13 says a tree id is any text without a tab, compared as bytes.
S2410="$TMP/s2410"; mkdir -p "$S2410/runs" "$S2410/tmpdir" "$S2410/bin" "$S2410/x"; S2410="$(cd "$S2410" && pwd -P)"
S2410_P=ledgerly
cp -R "$FROOT/harness" "$S2410/x/harness"
S2410_E="$S2410/x/harness/felix"
S2410_CBM='prototype=INFO,internal=INFO,public-beta=ADVISORY,production=TASK_BLOCKING'
_s2410_owes() { printf 'the %s surface owes a bound, Kept As Written' "$1"; }
# CLASS -> owed: and the first 12 hex digits of git hash-object over <class>\t<project>\t* (C6), run outside any repository.
_s2410_id() { printf 'owed:%s' "$(printf '%s\t%s\t%s' "$1" "$S2410_P" '*' | _fx_git "$S2410/x" hash-object --stdin | cut -c1-12)"; }
{
  printf '# class\tapplies\towes\tclass_by_maturity\tsource\n'
  while IFS='|' read -r S2410c S2410a; do
    printf '%s\t%s\t%s\t%s\t%s\n' "$S2410c" "$S2410a" "$(_s2410_owes "$S2410c")" "$S2410_CBM" cite:0123456789ab
  done <<'S2410TABLE'
a_dual|probe:dual=found probe:dual=empty
d_dual_na|probe:dual=not-applicable
u_nr|probe:nr=found
u_nr_empty|probe:nr=empty
u_capnr|cap:nr
u_bl|probe:bl=found
d_na|probe:na=found
c_na_cap|cap:na
d_em_cap|cap:em
d_mixed|cap:em probe:bl=found
u_zz|probe:zz=found
a_legacy|probe:legacy=found
c_tests|cap:tests
c_billing|cap:billing
m_proto|env:maturity>=prototype probe:dual=found
m_int|env:maturity>=internal probe:dual=found
m_pub|env:maturity>=public-beta probe:dual=found
m_prod|env:maturity>=production probe:dual=found
x_forms|probe:foo probe:=found probe:qq=bogus env:region>=eu env:maturity>=gold cap: weird:thing
x_dormant|weird:thing cap:em
S2410TABLE
} > "$S2410/x/harness/templates/situations.tsv"

# ---- the home, the checkout, the stubs ---------------------------------------------------------------------------------------
S2410_H="$S2410/home"; mkdir -p "$S2410_H/projects/$S2410_P"; S2410_H="$(cd "$S2410_H" && pwd -P)"
S2410_PD="$S2410_H/projects/$S2410_P"
_s2410_pj() { printf '{"name":"%s","remote_match":"example.invalid/%s","gate":"true"%s}\n' "$S2410_P" "$S2410_P" "$1" > "$S2410_PD/project.json"; }
_s2410_pj ',"maturity":"internal"'
printf '# %s\n' "$S2410_P" > "$S2410_PD/CLAUDE.md"
{
  printf '%s\t%s\t%s\t%s\t%s\n' \
    dual_a dual - 'cat dual_a.txt 2>/dev/null' 'test -f dual_a.txt' \
    dual_b dual - 'cat dual_b.txt' 'test -f dual_b.txt' \
    nr_a nr - 'cat nr_a.txt' 'test -f nr_a.txt' \
    nr_b nr - 'cat nr_b.txt 2>/dev/null' 'test -f nr_b.txt' \
    bl_a bl - 'cat bl_a.missing 2>/dev/null' 'test -f bl_a.txt' \
    na_a na 'test -f na.never' 'cat na.txt' 'test -f na.txt' \
    em_a em - 'cat em.txt 2>/dev/null' 'test -f em.txt' \
    orph_a orphan - 'cat orph.txt' 'test -f orph.txt' \
    dash_a - - 'ls -1 .felix' 'test -f .felix'
} > "$S2410_PD/probes.tsv"
for S2410c in gh curl wget ssh nc claude; do
  printf '#!/bin/sh\nprintf "%%s %%s\\n" "%s" "$*" >> "%s/net.log"\nexit 1\n' "$S2410c" "$S2410" > "$S2410/bin/$S2410c"
  chmod +x "$S2410/bin/$S2410c"
done
S2410_C="$S2410/c"; mkdir -p "$S2410_C/tests" "$S2410_C/.github/workflows"
printf '%s\n' "$S2410_P" > "$S2410_C/.felix"
printf 'a\nb\n' > "$S2410_C/dual_b.txt"; printf 'n\n' > "$S2410_C/nr_a.txt"; printf 'x\n' > "$S2410_C/bl_a.txt"
printf 'o\n' > "$S2410_C/orph.txt"; printf 'echo t\n' > "$S2410_C/tests/t.sh"; printf 'on: push\n' > "$S2410_C/.github/workflows/ci.yml"
S2410_C="$(cd "$S2410_C" && pwd -P)"
{ _fx_git "$S2410_C" init -q -b main && _fx_git "$S2410_C" add -A \
  && GIT_AUTHOR_DATE=2026-10-01T00:00:00Z GIT_COMMITTER_DATE=2026-10-01T00:00:00Z \
     _fx_git "$S2410_C" -c user.name=t -c user.email=t@t commit -qm init; } >/dev/null 2>&1
S2410_HEAD="$(_fx_git "$S2410_C" rev-parse HEAD 2>/dev/null)"
S2410_PLAIN="$S2410/plain"; mkdir -p "$S2410_PLAIN"

# ---- the hand-written log -------------------------------------------------------------------------------------------------
# STAMP TREE PRED STATE COUNT GROUNDS [SOURCE] -> one facts.log row: 8 fields, or 9 with SOURCE.
_s2410_row() { printf '%s\t%s\t%s\tOBSERVED\t%s\t%s\t%s\tcmd%s\n' "$1" "$2" "$3" "$4" "$5" "$6" "${7:+	$7}"; }
S2410_S1=2026-10-29T15:00:00Z; S2410_S2=2026-10-29T11:00:00Z; S2410_S3=2026-10-29T12:00:00Z
S2410_LOG="$(
  _s2410_row $S2410_S1 tree-a dual_a found 7 dual
  _s2410_row $S2410_S1 tree-a nr_b found 1 nr src
  _s2410_row $S2410_S1 tree-a bl_a found 1 bl
  _s2410_row $S2410_S1 tree-a em_a found 1 em
  _s2410_row $S2410_S1 tree-a na_a found 1 na
  _s2410_row $S2410_S1 tree-a old_a empty 0 legacy
  _s2410_row $S2410_S1 tree-a zz_a found 1 zz
  _s2410_row $S2410_S2 tree-z bl_a found 1 bl
  _s2410_row $S2410_S2 tree-z nr_b found 3 nr src
  _s2410_row $S2410_S2 tree-a dual_a empty 0 dual
  _s2410_row $S2410_S2 tree-a dual_b found 2 dual src
  _s2410_row $S2410_S2 tree-a nr_a found 1 nr
  _s2410_row $S2410_S2 tree-a bl_a blind 0 bl src
  printf '%s\ttree-a\tzz_b\tOBSERVED\tfound\t1\tzz\n' $S2410_S2
  _s2410_row $S2410_S2 tree-a na_a not-applicable 0 na
  _s2410_row $S2410_S2 tree-a em_a empty 0 em src
  _s2410_row $S2410_S2 tree-a orph_a found 1 orphan
  _s2410_row $S2410_S2 tree-a old_a found 4 legacy
  _s2410_row $S2410_S2 tree-a dash_a found 1 -
  _s2410_row $S2410_S2 tree-a dual_a found 5 dual
  _s2410_row 2026-10-29T10:00:00Z tree-s bl_a stale 0 bl
  _s2410_row $S2410_S3 tree-b dual_a found 1 dual
  _s2410_row $S2410_S3 tree-b dual_b not-applicable 0 dual src
  _s2410_row $S2410_S3 tree-b nr_a empty 0 nr
  _s2410_row $S2410_S3 tree-b nr_b found 2 moved
  _s2410_row $S2410_S3 tree-b bl_a unknown 2 bl src
  _s2410_row $S2410_S3 tree-b na_a empty 0 na
  _s2410_row $S2410_S3 tree-b em_a found 3 em
  _s2410_row $S2410_S3 tree-b orph_a empty 0 orphan
  _s2410_row $S2410_S3 tree-b old_a empty 0 legacy
  _s2410_row 2026-10-29T16:00:00Z unknown-tree dual_a found 1 dual
  _s2410_row 2026-10-29T16:00:00Z unknown-tree nr_a found 1 nr src
  printf '2026-10-29T17:00:00Z\ttree-c\tdual_a\tOBSERVED\tfound\t1\tdual\n'
)"
_s2410_mem() { mkdir -p "$1/$S2410_P"; printf '%s\n' "$2" > "$1/$S2410_P/facts.log"; }
S2410_M1="$S2410/m1"; _s2410_mem "$S2410_M1" "$S2410_LOG"; S2410_M1="$(cd "$S2410_M1" && pwd -P)"
S2410_MA="$S2410/ma"; mkdir -p "$S2410_MA"; S2410_MA="$(cd "$S2410_MA" && pwd -P)"
S2410_ME="$S2410/me"; mkdir -p "$S2410_ME/$S2410_P"; : > "$S2410_ME/$S2410_P/facts.log"; S2410_ME="$(cd "$S2410_ME" && pwd -P)"
S2410_MU="$S2410/mu"
_s2410_mem "$S2410_MU" "$(_s2410_row $S2410_S1 unknown-tree dual_a found 1 dual
                          printf '%s\ttree-q\tdual_a\tOBSERVED\tfound\t1\tdual\n' $S2410_S2)"
S2410_MU="$(cd "$S2410_MU" && pwd -P)"

# DIR MEMROOT ARGS... -> runs felix situations ARGS in DIR with its own empty TMPDIR: S2410_RC, S2410_O, S2410_R, S2410_TD.
_s2410_run() {
  local d="$1" m="$2"
  shift 2
  S2410_N=$((${S2410_N:-0} + 1))
  S2410_TD="$S2410/tmpdir/$S2410_N"; mkdir -p "$S2410_TD"
  S2410_O="$S2410/runs/$S2410_N.out"; S2410_R="$S2410/runs/$S2410_N.err"
  ( cd "$d" && env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GH_TOKEN -u GITHUB_TOKEN PATH="$S2410/bin:$PATH" \
      FELIX_HOME="$S2410_H" FELIX_MEMORY="$m" TMPDIR="$S2410_TD" "$S2410_E" situations "$@" ) > "$S2410_O" 2> "$S2410_R"
  S2410_RC=$?
}
# DIR MEMROOT -> felix probes in DIR, in the same environment; its status.
_s2410_probes() {
  mkdir -p "$S2410/tmpdir/probes"
  ( cd "$1" && env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GH_TOKEN -u GITHUB_TOKEN PATH="$S2410/bin:$PATH" \
      FELIX_HOME="$S2410_H" FELIX_MEMORY="$2" TMPDIR="$S2410/tmpdir/probes" "$S2410_E" probes ) >/dev/null 2>&1
}
# -> status|stdout bytes|stderr|what the run's TMPDIR holds.
_s2410_res() { printf '%s|%s|%s|%s' "$S2410_RC" "$(wc -c < "$S2410_O" | tr -d ' ')" "$(cat "$S2410_R")" "$(ls -A "$S2410_TD")"; }
# CLASS -> the --tsv class line of the last run whose second field is CLASS.
_s2410_cl() { S2410_K="$1" LC_ALL=C awk -F'\t' '$1 != "residual" && $2 == ENVIRON["S2410_K"]' "$S2410_O"; }
# KIND NAME -> the residual lines of the last run of that kind naming NAME, as printed (NAME - : every line of the kind).
_s2410_rl() { S2410_K="$1" S2410_V="$2" LC_ALL=C awk -F'\t' '$1 == "residual" && $2 == ENVIRON["S2410_K"] && (ENVIRON["S2410_V"] == "-" || $3 == ENVIRON["S2410_V"])' "$S2410_O"; }
# CLASS VERDICT STATE GROUNDS -> the --tsv class line C8 pins for an --at reading.
_s2410_tl() { printf '%s\t%s\t%s\t-\t%s\t-\t%s\t%s' "$(_s2410_id "$1")" "$1" "$2" "$3" "$4" "$(_s2410_owes "$1")"; }
_s2410_r() { printf 'residual\t%s\t%s\t%s' "$1" "$2" "$3"; }
S2410_NR='the detector was not run: this checkout is not at this tree'
S2410_NONE='not a term this slice can evaluate'
S2410_GD='dual_a empty (dual), dual_b found (dual)'
S2410_GN='nr_a found (nr), nr_b no reading (nr)'
S2410_XG='probe:foo unbound, probe:=found unbound, probe:qq=bogus unbound, env:region>=eu unbound, env:maturity>=gold unbound, cap: unbound, weird:thing unbound'
S2410_XT='probe:foo probe:=found probe:qq=bogus env:region>=eu env:maturity>=gold cap: weird:thing'

# ---- the expected reading of tree-a: C4, C7, C8, C9, C10 ----------------------------------------------------------------
# Every class, in byte order of name: CLASS VERDICT STATE GROUNDS READINGS. S2410_ET gathers rank<TAB>line for C8's order,
# S2410_EB the human standing blocks.
S2410_ET=""; S2410_EB=""
_s2410_e() {
  local rk=6
  case "$2" in standing) rk=4 ;; could-not-look) rk=5 ;; esac
  S2410_ET="$S2410_ET$rk	$(_s2410_tl "$1" "$2" "$3" "$4")"$'\n'
  [ "$2" != standing ] || S2410_EB="$S2410_EB  $(_s2410_id "$1")  $1  ACTIVE"$'\n'"    grounds  $4"$'\n'"    readings  $5"$'\n'"    owes  $(_s2410_owes "$1")"$'\n'
}
_s2410_e a_dual standing ACTIVE "$S2410_GD, $S2410_GD" 'dual_a=empty/0 dual_b=found/2'
_s2410_e a_legacy standing ACTIVE 'old_a found (legacy)' 'old_a=found/4'
_s2410_e c_billing could-not-look UNKNOWN 'billing detector not run' -
_s2410_e c_na_cap could-not-look UNKNOWN 'na detector not run' 'na_a=not-applicable/0'
_s2410_e c_tests could-not-look UNKNOWN 'tests detector not run' -
_s2410_e d_dual_na none DORMANT "$S2410_GD" 'dual_a=empty/0 dual_b=found/2'
_s2410_e d_em_cap none DORMANT 'em_a empty (em)' 'em_a=empty/0'
_s2410_e d_mixed none DORMANT 'em_a empty (em), bl_a blind (bl)' 'em_a=empty/0 bl_a=blind/0'
_s2410_e d_na none DORMANT 'na_a not-applicable (na)' 'na_a=not-applicable/0'
_s2410_e m_int standing ACTIVE "maturity internal, $S2410_GD" 'dual_a=empty/0 dual_b=found/2'
_s2410_e m_prod none DORMANT "maturity internal, $S2410_GD" 'dual_a=empty/0 dual_b=found/2'
_s2410_e m_proto standing ACTIVE "maturity internal, $S2410_GD" 'dual_a=empty/0 dual_b=found/2'
_s2410_e m_pub none DORMANT "maturity internal, $S2410_GD" 'dual_a=empty/0 dual_b=found/2'
_s2410_e u_bl could-not-look UNKNOWN 'bl_a blind (bl)' 'bl_a=blind/0'
_s2410_e u_capnr standing ACTIVE "$S2410_GN" 'nr_a=found/1'
_s2410_e u_nr standing ACTIVE "$S2410_GN" 'nr_a=found/1'
_s2410_e u_nr_empty could-not-look UNKNOWN "$S2410_GN" 'nr_a=found/1'
_s2410_e u_zz could-not-look UNKNOWN 'zz no probe' -
_s2410_e x_dormant none DORMANT 'weird:thing unbound, em_a empty (em)' 'em_a=empty/0'
_s2410_e x_forms could-not-look UNKNOWN "$S2410_XG" -
S2410_ER="$(
  _s2410_r could-not-look c_billing "at: cap:billing: no probe grounds billing and $S2410_NR"; echo
  _s2410_r could-not-look c_na_cap "at: cap:na: every probe grounding na is not-applicable and $S2410_NR"; echo
  _s2410_r could-not-look c_tests "at: cap:tests: no probe grounds tests and $S2410_NR"; echo
  _s2410_r could-not-look u_bl 'at: probe:bl=found: bl_a read blind when recorded; the fact log keeps no sentence'; echo
  _s2410_r could-not-look u_nr_empty 'at: probe:nr=empty: no reading of nr_b on this side'; echo
  _s2410_r could-not-look u_zz 'at: probe:zz=found: no probe grounds zz'; echo
  for S2410c in $S2410_XT; do _s2410_r could-not-look x_forms "at: $S2410c: $S2410_NONE"; echo; done
  _s2410_r no-row orphan 'named by probe orph_a'; echo
  for S2410c in probe:foo probe:=found probe:qq=bogus 'env:maturity>=gold' cap: weird:thing; do _s2410_r unbound "$S2410c" "$S2410_NONE"; echo; done
  _s2410_r unbound 'env:region>=eu' 'only env:maturity can be evaluated in this slice'; echo
  _s2410_r unbound probe:legacy=found 'no row of probes.tsv grounds legacy'; echo
  _s2410_r unbound probe:zz=found 'no row of probes.tsv grounds zz'; echo
)"
S2410_ER="$(printf '%s\n' "$S2410_ER" | LC_ALL=C sort -u)"
S2410_ETSV="$(printf '%s' "$S2410_ET" | LC_ALL=C sort | cut -f2-)"$'\n'"$S2410_ER"
S2410_EHUM="situations for $S2410_P
  at  -  tree tree-a  recorded $S2410_S2  detector not run: this checkout is not at this tree

standing
$S2410_EB
residual
$(printf '%s\n' "$S2410_ER" | LC_ALL=C awk -F'\t' '{ print "  " $2 "  " $3 "  " $4 }')

examined 20, active 6, dormant 7, could not look 7"

# ---- tree-a, --tsv: one assertion per term rule -------------------------------------------------------------------------
_s2410_run "$S2410_C" "$S2410_M1" --at tree-a --tsv
S2410_TSVA="$S2410_O"
is "2410 --at tree-a --tsv exits 0 with nothing on stderr, and leaves its TMPDIR empty" "$S2410_RC|$(cat "$S2410_R")|$(ls -A "$S2410_TD")" "0||"
# NAME CLASS VERDICT STATE GROUNDS -> the class's line in the last run is C8's line.
_s2410_is() { is "$1" "$S2410_RC|$(_s2410_cl "$2")" "0|$(_s2410_tl "$2" "$3" "$4" "$5")"; }
_s2410_is "2410 a probe term over two probes grounding one capability is true when either reads its state, and the grounds name both, in reading order, per term (a_dual)" \
  a_dual standing ACTIVE "$S2410_GD, $S2410_GD"
_s2410_is "2410 a probe term no grounding row reads, with none blind, unknown or unread, is false: the class is DORMANT, verdict none (d_dual_na)" \
  d_dual_na none DORMANT "$S2410_GD"
_s2410_is "2410 a probe term is true when one grounding row reads its state although another grounding probe has no reading, which the grounds name (u_nr)" \
  u_nr standing ACTIVE "$S2410_GN"
_s2410_is "2410 a probe term no row reads, with a grounding probe that has no reading, is undecided: UNKNOWN, could-not-look (u_nr_empty)" \
  u_nr_empty could-not-look UNKNOWN "$S2410_GN"
_s2410_is "2410 a cap term with a grounding row that reads found is true (u_capnr)" u_capnr standing ACTIVE "$S2410_GN"
_s2410_is "2410 a probe term whose grounding row was recorded blind is undecided, and the grounds say blind (u_bl)" \
  u_bl could-not-look UNKNOWN 'bl_a blind (bl)'
_s2410_is "2410 a probe term on found whose every grounding row reads not-applicable is false (d_na)" \
  d_na none DORMANT 'na_a not-applicable (na)'
_s2410_is "2410 a cap term whose every grounding row reads not-applicable goes to the detector, which was not run at this tree: undecided (c_na_cap)" \
  c_na_cap could-not-look UNKNOWN 'na detector not run'
_s2410_is "2410 a cap term whose grounding row reads empty is false: an empty reading is a witness (d_em_cap)" \
  d_em_cap none DORMANT 'em_a empty (em)'
_s2410_is "2410 a false term settles the class DORMANT beside an undecided one, and the grounds still name the undecided term (d_mixed, C7)" \
  d_mixed none DORMANT 'em_a empty (em), bl_a blind (bl)'
_s2410_is "2410 a probe term no probe grounds, in the reading or in probes.tsv, is undecided and its grounds say no probe (u_zz)" \
  u_zz could-not-look UNKNOWN 'zz no probe'
_s2410_is "2410 a probe term whose capability only a recorded row grounds is read from the reading: here true (a_legacy)" \
  a_legacy standing ACTIVE 'old_a found (legacy)'
_s2410_is "2410 a cap term with no grounding probe and the detector not run is undecided, never false (c_tests)" \
  c_tests could-not-look UNKNOWN 'tests detector not run'
_s2410_is "2410 the same for a capability the detector would not name either (c_billing)" \
  c_billing could-not-look UNKNOWN 'billing detector not run'
_s2410_is "2410 with maturity internal, env:maturity>=prototype is true (m_proto)" m_proto standing ACTIVE "maturity internal, $S2410_GD"
_s2410_is "2410 with maturity internal, env:maturity>=internal is true (m_int)" m_int standing ACTIVE "maturity internal, $S2410_GD"
_s2410_is "2410 with maturity internal, env:maturity>=public-beta is false, by rank and not by spelling (m_pub)" \
  m_pub none DORMANT "maturity internal, $S2410_GD"
_s2410_is "2410 with maturity internal, env:maturity>=production is false (m_prod)" m_prod none DORMANT "maturity internal, $S2410_GD"
_s2410_is "2410 terms in another form are each undecided, and the grounds name each as unbound (x_forms)" \
  x_forms could-not-look UNKNOWN "$S2410_XG"
_s2410_is "2410 a term in another form beside a false term leaves the class DORMANT (x_dormant)" \
  x_dormant none DORMANT 'weird:thing unbound, em_a empty (em)'

# ---- tree-a, the residual (C10's recorded reasons) ------------------------------------------------------------------------
# NAME KIND NAME... -> the residual lines naming NAME are exactly the expected ones.
_s2410_rs() { is "$1" "$S2410_RC|$(_s2410_rl "$2" "$3")" "0|$(printf '%s\n' "$S2410_ER" | S2410_K="$2" S2410_V="$3" LC_ALL=C awk -F'\t' '$2 == ENVIRON["S2410_K"] && (ENVIRON["S2410_V"] == "-" || $3 == ENVIRON["S2410_V"])')"; }
_s2410_rs "2410 a recorded blind reading's why is <pred> read blind when recorded; the fact log keeps no sentence, on side at" could-not-look u_bl
_s2410_rs "2410 a grounding probe with no reading on this side is named in the why (u_nr_empty)" could-not-look u_nr_empty
_s2410_rs "2410 a probe term no probe grounds says no probe grounds <c> (u_zz)" could-not-look u_zz
_s2410_rs "2410 a cap term at step 4 says every probe grounding it is not-applicable and the detector was not run (c_na_cap)" could-not-look c_na_cap
_s2410_rs "2410 a cap term with no grounding probe says so and that the detector was not run (c_tests)" could-not-look c_tests
_s2410_rs "2410 each term in another form gets its own could-not-look line on side at (x_forms)" could-not-look x_forms
is "2410 a DORMANT class gets no could-not-look line, though it holds an undecided term (d_mixed, x_dormant)" \
   "$S2410_RC|$(_s2410_rl could-not-look d_mixed)$(_s2410_rl could-not-look x_dormant)" "0|"
_s2410_rs "2410 the unbound lines are one per distinct term: the forms C4 cannot evaluate, the axis other than maturity, and the probe terms probes.tsv does not ground" unbound -
_s2410_rs "2410 the no-row lines name the capability a recorded row grounds that no class uses, and never a grounds of -" no-row -
is "2410 the whole --tsv at tree-a is C8's: class lines by verdict then id, then the residual sorted as bytes, nothing else" \
   "$S2410_RC|$(cat "$S2410_TSVA")" "0|$S2410_ETSV"

# ---- tree-a, the human report, and C3.4 for --at --------------------------------------------------------------------------
_s2410_gs() {   # DIR -> its refs, HEAD, worktree list, config bytes, index and status
  { _fx_git "$1" for-each-ref; _fx_git "$1" rev-parse HEAD; _fx_git "$1" worktree list --porcelain
    cksum < "$1/.git/config"; _fx_git "$1" ls-files -s; _fx_git "$1" --no-optional-locks status --porcelain; } 2>&1
}
_s2410_fs() { ( cd "$1" && find . -print | LC_ALL=C sort && find . -type f -exec cksum {} \; | LC_ALL=C sort ) 2>&1; }
# MEMROOT ARGS... -> the run in C between snapshots: S2410_CH holds what changed, one word per kind.
_s2410_still() {
  local m="$1" g0 m0 h0 g1 m1 h1 nw
  shift
  g0="$(_s2410_gs "$S2410_C")"; m0="$(_s2410_fs "$m")"; h0="$(_s2410_fs "$S2410_H")"
  sleep 1; : > "$S2410/mark"
  _s2410_run "$S2410_C" "$m" "$@"
  nw="$(find "$S2410_C" -newer "$S2410/mark" -print 2>&1)"
  g1="$(_s2410_gs "$S2410_C")"; m1="$(_s2410_fs "$m")"; h1="$(_s2410_fs "$S2410_H")"
  S2410_CH="newer:[$nw]"
  [ "$g0" = "$g1" ] || S2410_CH="$S2410_CH git"
  [ "$m0" = "$m1" ] || S2410_CH="$S2410_CH memory"
  [ "$h0" = "$h1" ] || S2410_CH="$S2410_CH home"
}
_s2410_still "$S2410_M1" --at tree-a
is "2410 the human report at tree-a is C9's: the header, standing by class name, the residual, the count line" \
   "$S2410_RC|$(cat "$S2410_O")|$(cat "$S2410_R")" "0|$S2410_EHUM|"
is "2410 --at leaves the checkout's files, refs, HEAD, worktree list, config, index and status, the memory root and the home as they were" \
   "$S2410_RC|$S2410_CH" "0|newer:[]"
is "2410 --at leaves TMPDIR empty and starts no gh, curl, wget, ssh, nc or claude" \
   "$S2410_RC|$(ls -A "$S2410_TD")|$(cat "$S2410/net.log" 2>/dev/null)" "0||"

# ---- the newest tree, with no --at (C3.1) ----------------------------------------------------------------------------------
S2410_HB="  at  -  tree tree-b  recorded $S2410_S3  detector not run: this checkout is not at this tree"
_s2410_run "$S2410_C" "$S2410_M1"
is "2410 with no --at the newest tree is the last 8-field or longer line's that is not unknown-tree, in file order: tree-b, not tree-a's later stamp or a short line's tree" \
   "$S2410_RC|$(LC_ALL=C awk 'NR <= 2' "$S2410_O")" "0|situations for $S2410_P
$S2410_HB"
is "2410 its count line counts tree-b's states: examined 20, active 5, dormant 6, could not look 9" \
   "$S2410_RC|$(LC_ALL=C awk 'END { print }' "$S2410_O")" "0|examined 20, active 5, dormant 6, could not look 9"
has "2410 its standing section prints a not-applicable reading with its count, as readings do (d_dual_na at tree-b)" "$S2410_RC|$(cat "$S2410_O")" \
    "
  $(_s2410_id d_dual_na)  d_dual_na  ACTIVE
    grounds  dual_a found (dual), dual_b not-applicable (dual)
    readings  dual_a=found/1 dual_b=not-applicable/0
    owes  $(_s2410_owes d_dual_na)
"
_s2410_run "$S2410_C" "$S2410_M1" --tsv
_s2410_is "2410 a cap term whose grounding rows read empty while another grounding probe has no reading is undecided, never false: unread is never left to empty (u_capnr at tree-b)" \
  u_capnr could-not-look UNKNOWN 'nr_a empty (nr), nr_b no reading (nr)'
is "2410 a predicate whose recorded row grounds another capability is a grounding probe with no reading for its own (u_capnr's why at tree-b)" \
   "$S2410_RC|$(_s2410_rl could-not-look u_capnr)" "0|$(_s2410_r could-not-look u_capnr 'at: cap:nr: no reading of nr_b on this side')"
is "2410 a partial unknown recorded row gives <pred> read unknown when recorded; the fact log keeps no sentence (u_bl at tree-b)" \
   "$S2410_RC|$(_s2410_rl could-not-look u_bl)" "0|$(_s2410_r could-not-look u_bl 'at: probe:bl=found: bl_a read unknown when recorded; the fact log keeps no sentence')"
_s2410_is "2410 a probe term with a false and a true term in one class: probe:dual=empty no row reads is false at tree-b (a_dual)" \
  a_dual none DORMANT 'dual_a found (dual), dual_b not-applicable (dual), dual_a found (dual), dual_b not-applicable (dual)'
_s2410_is "2410 probe:<c>=not-applicable is true when a grounding row reads not-applicable (d_dual_na at tree-b)" \
  d_dual_na standing ACTIVE 'dual_a found (dual), dual_b not-applicable (dual)'
_s2410_is "2410 a probe term whose only recorded grounding row reads empty is false, still listed unbound (a_legacy at tree-b)" \
  a_legacy none DORMANT 'old_a empty (legacy)'
is "2410 the no-row lines name every capability a recorded row grounds that no class uses, whatever its state (moved, orphan at tree-b)" \
   "$S2410_RC|$(_s2410_rl no-row -)" "0|$(_s2410_r no-row moved 'named by probe nr_b')
$(_s2410_r no-row orphan 'named by probe orph_a')"

# ---- a recorded state outside the five (C17.6) ------------------------------------------------------------------------
_s2410_run "$S2410_C" "$S2410_M1" --at tree-s --tsv
_s2410_is "2410 a recorded grounding row whose state is outside the five, stale, leaves its probe term undecided: could-not-look, never DORMANT, the grounds naming the state (u_bl at tree-s)" \
  u_bl could-not-look UNKNOWN 'bl_a stale (bl)'
is "2410 its why is the recorded form with the row's own state word: bl_a read stale when recorded; the fact log keeps no sentence (u_bl at tree-s)" \
   "$S2410_RC|$(_s2410_rl could-not-look u_bl)" \
   "0|$(_s2410_r could-not-look u_bl 'at: probe:bl=found: bl_a read stale when recorded; the fact log keeps no sentence')"

# ---- maturity: undeclared, empty, not one of the four, public-beta (C4, C10) ------------------------------------------------
S2410_MO="project.json declares maturity 'beta', which is not one of prototype internal public-beta production"
_s2410_pj ''
_s2410_run "$S2410_C" "$S2410_M1" --at tree-a --tsv
_s2410_is "2410 with no maturity declared an env term is undecided and its grounds say maturity undeclared (m_int)" \
  m_int could-not-look UNKNOWN "maturity undeclared, $S2410_GD"
_s2410_is "2410 with no maturity declared env:maturity>=public-beta is undecided, never false (m_pub)" \
  m_pub could-not-look UNKNOWN "maturity undeclared, $S2410_GD"
is "2410 with no maturity declared the env term's why is project.json declares no maturity (m_int)" \
   "$S2410_RC|$(_s2410_rl could-not-look m_int)" "0|$(_s2410_r could-not-look m_int 'at: env:maturity>=internal: project.json declares no maturity')"
is "2410 with no maturity declared each env:maturity term is unbound once, as project.json declares no maturity" \
   "$S2410_RC|$(_s2410_rl unbound - | LC_ALL=C awk -F'\t' 'index($3, "env:maturity>=") == 1')" \
   "0|$(_s2410_r unbound 'env:maturity>=gold' "$S2410_NONE")
$(_s2410_r unbound 'env:maturity>=internal' 'project.json declares no maturity')
$(_s2410_r unbound 'env:maturity>=production' 'project.json declares no maturity')
$(_s2410_r unbound 'env:maturity>=prototype' 'project.json declares no maturity')
$(_s2410_r unbound 'env:maturity>=public-beta' 'project.json declares no maturity')"
_s2410_pj ',"maturity":""'
_s2410_run "$S2410_C" "$S2410_M1" --at tree-a --tsv
is "2410 an empty maturity string declares no maturity (m_int)" "$S2410_RC|$(_s2410_cl m_int)|$(_s2410_rl unbound 'env:maturity>=internal')" \
   "0|$(_s2410_tl m_int could-not-look UNKNOWN "maturity undeclared, $S2410_GD")|$(_s2410_r unbound 'env:maturity>=internal' 'project.json declares no maturity')"
_s2410_pj ',"maturity":"beta"'
_s2410_run "$S2410_C" "$S2410_M1" --at tree-a --tsv
_s2410_is "2410 a declared maturity not one of the four leaves the env term undecided, its grounds naming the value (m_int)" \
  m_int could-not-look UNKNOWN "maturity beta, $S2410_GD"
is "2410 its why and its unbound line say the value is not one of the four (m_int)" \
   "$S2410_RC|$(_s2410_rl could-not-look m_int)|$(_s2410_rl unbound 'env:maturity>=internal')" \
   "0|$(_s2410_r could-not-look m_int "at: env:maturity>=internal: $S2410_MO")|$(_s2410_r unbound 'env:maturity>=internal' "$S2410_MO")"
_s2410_pj ',"maturity":"public-beta"'
_s2410_run "$S2410_C" "$S2410_M1" --at tree-a --tsv
is "2410 with maturity public-beta, prototype, internal and public-beta hold and production does not (m_proto m_int m_pub m_prod)" \
   "$S2410_RC|$(_s2410_cl m_proto)|$(_s2410_cl m_int)|$(_s2410_cl m_pub)|$(_s2410_cl m_prod)" \
   "0|$(_s2410_tl m_proto standing ACTIVE "maturity public-beta, $S2410_GD")|$(_s2410_tl m_int standing ACTIVE "maturity public-beta, $S2410_GD")|$(_s2410_tl m_pub standing ACTIVE "maturity public-beta, $S2410_GD")|$(_s2410_tl m_prod none DORMANT "maturity public-beta, $S2410_GD")"
is "2410 a declared maturity binds no env term: no env:maturity term is unbound but the value outside the four" \
   "$S2410_RC|$(_s2410_rl unbound - | LC_ALL=C awk -F'\t' 'index($3, "env:maturity>=") == 1')" "0|$(_s2410_r unbound 'env:maturity>=gold' "$S2410_NONE")"
_s2410_pj ',"maturity":"internal"'

# ---- C2's --at exits ------------------------------------------------------------------------------------------------------
S2410_NV='felix: felix: --at needs a value'
_s2410_run "$S2410_C" "$S2410_M1" --at
is "2410 --at with no value exits 1 with need_value's own sentence alone on stderr and nothing on stdout" "$(_s2410_res)" "1|0|$S2410_NV|"
_s2410_run "$S2410_C" "$S2410_M1" --at ''
is "2410 --at with an empty value does the same" "$(_s2410_res)" "1|0|$S2410_NV|"
_s2410_run "$S2410_PLAIN" "$S2410_M1" --at
is "2410 --at with no value is found before the governing project: exit 1 where no project governs" "$(_s2410_res)" "1|0|$S2410_NV|"
S2410_NO="felix situations: the recorded tree could not be read: no run is recorded for tree"
# NAME MEMROOT TREE -> --at TREE exits 3 with C2's sentence for MEMROOT.
_s2410_norun() {
  _s2410_run "$S2410_C" "$2" --at "$3"
  is "$1" "$(_s2410_res)" "3|0|$S2410_NO $3 in $2/$S2410_P/facts.log|"
}
_s2410_norun "2410 --at a tree with no run exits 3 with C2's sentence, nothing on stdout, TMPDIR empty" "$S2410_M1" tree-q
_s2410_norun "2410 --at unknown-tree exits 3: unknown-tree rows are never read" "$S2410_M1" unknown-tree
_s2410_norun "2410 --at the tree of a 7-field line only exits 3: a short line is ignored" "$S2410_M1" tree-c
_s2410_norun "2410 --at --tsv reads the tree --tsv, which has no run: exit 3" "$S2410_M1" --tsv
_s2410_norun "2410 --at a tree with an absent log exits 3 with the same sentence" "$S2410_MA" tree-a
_s2410_norun "2410 --at a tree with an empty log exits 3 with the same sentence" "$S2410_ME" tree-a
_s2410_norun "2410 --at a tree only a 7-field line names, beside unknown-tree rows, exits 3" "$S2410_MU" tree-q
# NAME MEMROOT -> no --at exits 3 with C2's no-tree sentence.
_s2410_notree() {
  _s2410_run "$S2410_C" "$2"
  is "$1" "$(_s2410_res)" "3|0|felix situations: the recorded tree could not be read: $2/$S2410_P/facts.log records no tree|"
}
_s2410_notree "2410 with no --at and an absent log it exits 3: the log records no tree" "$S2410_MA"
is "2410 a run with no --at on an absent log leaves its memory root as it was, creating nothing" "$S2410_RC|$(ls -A "$S2410_MA")" "3|"
_s2410_notree "2410 with no --at and an empty log it exits 3 the same way" "$S2410_ME"
_s2410_notree "2410 with no --at and a log of unknown-tree rows and short lines it exits 3 the same way" "$S2410_MU"
_s2410_run "$S2410_C" "$S2410_M1" --at tree-z
is "2410 --at tree-z reads its two rows that share tree-a's new stamp: a run is keyed on its stamp and its tree" \
   "$S2410_RC|$(LC_ALL=C awk 'NR == 2' "$S2410_O")|$(cat "$S2410_R")" \
   "0|  at  -  tree tree-z  recorded $S2410_S2  detector not run: this checkout is not at this tree|"
_s2410_run "$S2410_C" "$S2410_M1" --at tree-a --at tree-a
is "2410 --at given twice is a usage error: exit 2, nothing on stdout, felix: usage: felix situations first on stderr" \
   "$S2410_RC|$(wc -c < "$S2410_O" | tr -d ' ')|$(LC_ALL=C awk 'NR == 1 { print substr($0, 1, 30) }' "$S2410_R")" "2|0|felix: usage: felix situations"
_s2410_run "$S2410_C" "$S2410_M1" --at tree-a --change
is "2410 --at with --change is a usage error: exit 2" \
   "$S2410_RC|$(wc -c < "$S2410_O" | tr -d ' ')|$(LC_ALL=C awk 'NR == 1 { print substr($0, 1, 30) }' "$S2410_R")" "2|0|felix: usage: felix situations"
_s2410_run "$S2410_PLAIN" "$S2410_M1" --at tree-a
is "2410 --at where no project governs exits 2 with resolve_or_die's sentence, felix: no project governs first" \
   "$S2410_RC|$(wc -c < "$S2410_O" | tr -d ' ')|$(LC_ALL=C awk 'NR == 1 { print substr($0, 1, 25) }' "$S2410_R")" "2|0|felix: no project governs"

# ---- the live tree: the detector runs (C3.2, the header both ways) ----------------------------------------------------------
S2410_M2="$S2410/m2"; _s2410_mem "$S2410_M2" "$S2410_LOG"; S2410_M2="$(cd "$S2410_M2" && pwd -P)"
_s2410_probes "$S2410_C" "$S2410_M2"; S2410_PRC=$?
S2410_LT="$(LC_ALL=C awk -F'\t' 'NF >= 8 { t = $2; s = $1 } END { print t }' "$S2410_M2/$S2410_P/facts.log")"
S2410_SL="$(LC_ALL=C awk -F'\t' 'NF >= 8 { t = $2; s = $1 } END { print s }' "$S2410_M2/$S2410_P/facts.log")"
S2410_BUILT="not built: felix probes exited $S2410_PRC and recorded tree [$S2410_LT]"
case "$S2410_LT" in ""|tree-?|unknown-tree) ;; *) [ "$S2410_PRC" = 0 ] && [ -n "$S2410_HEAD" ] && S2410_BUILT=built ;; esac
S2410_HL="  at  $S2410_HEAD  tree $S2410_LT  recorded $S2410_SL  detector run on this checkout"
_s2410_still "$S2410_M2"
is "2410 with no --at, after felix probes, the newest tree is the live one: the header names HEAD, the tree and the run, and says the detector ran" \
   "$S2410_BUILT|$S2410_RC|$(LC_ALL=C awk 'NR <= 2' "$S2410_O")|$(cat "$S2410_R")" "built|0|situations for $S2410_P
$S2410_HL|"
is "2410 that run too leaves the checkout, the memory root and the home as they were, TMPDIR empty, no network command run" \
   "$S2410_RC|$S2410_CH|$(ls -A "$S2410_TD")|$(cat "$S2410/net.log" 2>/dev/null)" "0|newer:[]||"
_s2410_run "$S2410_C" "$S2410_M2" --tsv --at "$S2410_LT"
is "2410 --at the live tree id runs the detector as well: a cap term no probe grounds is true where the detector names it (c_tests)" \
   "$S2410_BUILT|$S2410_RC|$(_s2410_cl c_tests)" "built|0|$(_s2410_tl c_tests standing ACTIVE 'tests detected')"
is "2410 where the detector ran and is silent, a cap term with no grounding probe is undecided, never false, and says so (c_billing)" \
   "$S2410_BUILT|$S2410_RC|$(_s2410_cl c_billing)|$(_s2410_rl could-not-look c_billing)" \
   "built|0|$(_s2410_tl c_billing could-not-look UNKNOWN 'billing not detected')|$(_s2410_r could-not-look c_billing 'at: cap:billing: no probe grounds billing and the detector does not name it')"
is "2410 where the detector ran, every grounding probe not-applicable and the detector silent reads so (c_na_cap)" \
   "$S2410_BUILT|$S2410_RC|$(_s2410_cl c_na_cap)|$(_s2410_rl could-not-look c_na_cap)" \
   "built|0|$(_s2410_tl c_na_cap could-not-look UNKNOWN 'na not detected')|$(_s2410_r could-not-look c_na_cap 'at: cap:na: every probe grounding na is not-applicable and the detector does not name it')"
is "2410 a capability the detector names that no class uses is a no-row line named by the detector (ci)" \
   "$S2410_BUILT|$S2410_RC|$(_s2410_rl no-row ci)" "built|0|$(_s2410_r no-row ci 'named by the detector')"
is "2410 the live tree's readings are still recorded ones: felix probes' blind row reads blind when recorded (u_bl)" \
   "$S2410_BUILT|$S2410_RC|$(_s2410_rl could-not-look u_bl)" \
   "built|0|$(_s2410_r could-not-look u_bl 'at: probe:bl=found: bl_a read blind when recorded; the fact log keeps no sentence')"
_s2410_is "2410 at the live tree probe:nr=found reads both grounding probes, nr_b recorded empty (u_nr)" \
  u_nr standing ACTIVE 'nr_a found (nr), nr_b empty (nr)'
_s2410_run "$S2410_C" "$S2410_M2" --at tree-a
is "2410 --at a recorded tree the checkout is not at, in the same log, does not run the detector: commit -" \
   "$S2410_RC|$(LC_ALL=C awk 'NR == 2' "$S2410_O")" "0|  at  -  tree tree-a  recorded $S2410_S2  detector not run: this checkout is not at this tree"

# ---- an unborn checkout: the commit is -, the detector still runs (C3.2) --------------------------------------------------
S2410_U="$S2410/u"; mkdir -p "$S2410_U"; printf '%s\n' "$S2410_P" > "$S2410_U/.felix"; S2410_U="$(cd "$S2410_U" && pwd -P)"
_fx_git "$S2410_U" init -q -b main >/dev/null 2>&1
S2410_M3="$S2410/m3"; mkdir -p "$S2410_M3"; S2410_M3="$(cd "$S2410_M3" && pwd -P)"
_s2410_probes "$S2410_U" "$S2410_M3"; S2410_PRC=$?
S2410_UT="$(LC_ALL=C awk -F'\t' 'NF >= 8 { t = $2; s = $1 } END { print t }' "$S2410_M3/$S2410_P/facts.log" 2>/dev/null)"
S2410_SU="$(LC_ALL=C awk -F'\t' 'NF >= 8 { t = $2; s = $1 } END { print s }' "$S2410_M3/$S2410_P/facts.log" 2>/dev/null)"
S2410_UB="not built: felix probes exited $S2410_PRC and recorded tree [$S2410_UT]"
[ "$S2410_PRC" = 0 ] && [ -n "$S2410_UT" ] && [ "$S2410_UT" != unknown-tree ] && S2410_UB=built
_s2410_run "$S2410_U" "$S2410_M3"
is "2410 in a checkout whose HEAD is unborn the header's commit is - and the detector still runs" \
   "$S2410_UB|$S2410_RC|$(LC_ALL=C awk 'NR == 2' "$S2410_O")|$(cat "$S2410_R")" \
   "built|0|  at  -  tree $S2410_UT  recorded $S2410_SU  detector run on this checkout|"
