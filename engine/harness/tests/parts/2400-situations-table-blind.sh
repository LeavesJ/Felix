printf '\n%s\n' 'situations: the table (blind)'
# Blind, written on 2026-10-31 from docs/2026-10-29-capability-lane-first-slices-design.md (sections 3, 4, 7, 10, 11) and
# the slice 1 plan's Contracts and Review Focus (C1 to C16) alone, before any lib/situations*.sh existed, without reading
# felix, lib/, hooks/ or bin/. C16's row for this part: C12 (the format, the schema row, the cells, the three source kinds,
# R1 to R4, six to eight rows, no project name), C1 (felix help holds felix situations, its three usage lines exactly), and
# every engine/harness/lib/situations*.sh under 500 lines with at least one there; then "Part 2400's other checks": the
# source pattern, the project names beside the harness, and bin/schema-check run as part 0730 runs it.
# Readings where the Contracts leave room:
# - The table read is the shipped one, $REAL_HARNESS/templates/situations.tsv. Every line is a comment with # at column 0
#   or a row of five non-empty cells; an empty line, or a comment indented, is neither, so the shipped seed holds none.
# - "Printable ASCII" is asserted of every byte of the file, comments included: tab, newline, or 0x20 to 0x7e.
# - applies is split on runs of spaces (C2). "A term on api" is a probe:api=<s> or cap:api term; the same for <cap3>.
# - C1's "after the felix obligations line" is read as the three lines directly after the line holding
#   "felix obligations [", which is under "the toolbox" on main.
# - C12's "The seed as committed" list is asserted as well, as the (class, applies) pairs it names: parts 2430 and 2450
#   read the R4 class and the four HTTP-keyed classes by those names.
# - The schema-check fixture also shows the row refusing (a check that cannot fail is not a check): a situations.tsv of
#   comments only fails as empty, and a row of four cells fails on its cells, in schema-check's own words from part 0730.
# The table assertions are checks of the committed seed and the schema row, which Task 1 committed before this part was
# written, so they pass on this branch before the command exists; the help line and the lib file assertions do not.
S2400="$TMP/s2400"; mkdir -p "$S2400"; S2400="$(cd "$S2400" && pwd -P)"
S2400_T="$REAL_HARNESS/templates/situations.tsv"
S2400_SCH="$REAL_HARNESS/templates/schemas.tsv"
# MODE -> what awk prints over the table's rows for one rule (empty: the rule holds). Comments and anything else that is
# not a row are passed over here; the format assertion judges those.
_s2400_rows() {
  [ -r "$S2400_T" ] || { printf 'the table [%s] is absent or unreadable\n' "$S2400_T"; return 0; }
  LC_ALL=C awk -F'\t' -v mode="$1" '
    function s24form(t,   r, i, st) {
      if (substr(t, 1, 6) == "probe:") {
        r = substr(t, 7); i = index(r, "=")
        if (i < 2) return 0
        st = substr(r, i + 1)
        return st == "found" || st == "empty" || st == "blind" || st == "unknown" || st == "not-applicable"
      }
      if (substr(t, 1, 4) == "cap:") return length(t) > 4
      if (substr(t, 1, 14) == "env:maturity>=") {
        st = substr(t, 15)
        return st == "prototype" || st == "internal" || st == "public-beta" || st == "production"
      }
      return 0
    }
    function s24rank(m) {
      if (m == "prototype") return 1; if (m == "internal") return 2
      if (m == "public-beta") return 3; if (m == "production") return 4
      return 0
    }
    function s24class(c) {
      if (c == "INFO") return 1; if (c == "ADVISORY") return 2; if (c == "TASK_BLOCKING") return 3
      if (c == "RELEASE_BLOCKING") return 4; if (c == "AUTHORITY_BLOCKING") return 5
      return 0
    }
    /^#/ || NF != 5 { next }
    {
      n = split($2, raw, / +/); k = 0
      for (i = 1; i <= n; i++) if (raw[i] != "") { k++; term[k] = raw[i] }
      rows++
    }
    mode == "class" && $1 !~ /^[a-z][a-z0-9_]*$/ { print NR ": class [" $1 "] is not [a-z][a-z0-9_]*" }
    mode == "class" && seen[$1]++ { print NR ": class [" $1 "] appears twice" }
    mode == "forms" {
      if (k == 0) print NR ": applies holds no term"
      for (i = 1; i <= k; i++) if (!s24form(term[i])) print NR ": [" term[i] "] is not a term C4 evaluates"
    }
    mode == "blind" {
      for (i = 1; i <= k; i++) if (term[i] ~ /^probe:/ && (term[i] ~ /=blind$/ || term[i] ~ /=unknown$/)) print NR ": [" term[i] "] rests on blind or unknown"
    }
    mode == "pc" {
      g = 0
      for (i = 1; i <= k; i++) if (substr(term[i], 1, 6) == "probe:" || substr(term[i], 1, 4) == "cap:") g = 1
      if (!g) print NR ": [" $2 "] holds no probe: or cap: term"
    }
    mode == "cbm" || mode == "rise" {
      np = split($4, pr, ","); okc = (np == 4); delete got; delete cl
      for (i = 1; i <= np; i++) {
        e = index(pr[i], "="); m = substr(pr[i], 1, e - 1); c = substr(pr[i], e + 1)
        if (e < 2 || !s24rank(m) || !s24class(c) || (m in got)) okc = 0
        got[m] = 1; cl[s24rank(m)] = s24class(c)
      }
      if (mode == "cbm" && !okc) print NR ": class_by_maturity [" $4 "] does not name each maturity once with a known class"
      if (mode == "rise" && okc && (cl[2] < cl[1] || cl[3] < cl[2] || cl[4] < cl[3])) print NR ": class_by_maturity [" $4 "] decreases as maturity rises"
    }
    mode == "source" && $5 !~ /^(miss|candidate|cite):[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]$/ {
      print NR ": source [" $5 "] is not miss:, candidate: or cite: and 12 lowercase hex digits"
    }
    mode == "pairs" { print $1 "\t" $2 }
    mode == "r1" && $1 == "paid_ingress" && $2 == "cap:api cap:llm" { o = tolower($3); if (index(o, "request") && index(o, "spend")) r1 = 1 }
    mode == "r2" && $1 != "paid_ingress" { for (i = 1; i <= k; i++) if (term[i] == "cap:api") r2 = 1 }
    mode == "r3" {
      lp = 0; ca = 0
      for (i = 1; i <= k; i++) { if (term[i] == "probe:local_listener=found") lp = 1; if (term[i] == "cap:api") ca = 1 }
      if (lp && !ca && index(tolower($3), "loopback")) r3 = 1
    }
    mode == "r4" && $1 == "ci_actions_pinned" {
      r4 = 1
      for (i = 1; i <= k; i++) if (term[i] == "cap:api" || term[i] == "cap:local_listener" || term[i] ~ /^probe:(api|local_listener)=/) r4 = 0
    }
    END {
      if (mode == "count") print rows + 0
      if (mode == "r1") print (r1 ? "R1 met" : "no R1 row")
      if (mode == "r2") print (r2 ? "R2 met" : "no R2 row")
      if (mode == "r3") print (r3 ? "R3 met" : "no R3 row")
      if (mode == "r4") print (r4 ? "R4 met" : "the R4 class is absent or holds a term on api or local_listener")
    }
  ' "$S2400_T"
}

# ---- C12: the file ----------------------------------------------------------------------------------------------------------
S2400a="absent"
[ -f "$S2400_T" ] && [ -s "$S2400_T" ] && S2400a="$( [ -z "$(tail -c 1 "$S2400_T" | tr -d '\n')" ] && echo 'ends in a newline' || echo 'no final newline')"
is "2400 the shipped templates/situations.tsv exists, is not empty and ends in a newline" "$S2400a" "ends in a newline"
S2400a="$( [ -r "$S2400_T" ] && LC_ALL=C awk -F'\t' '
  /^#/ { next }
  { b = (NF != 5); for (i = 1; i <= NF; i++) if ($i == "") b = 1; if (b) print NR ": [" $0 "]" }' "$S2400_T")"
is "2400 every line of the table is a comment with # at column 0 or a row of exactly five non-empty cells" \
   "$( [ -r "$S2400_T" ] && echo read || echo unread)|$S2400a" "read|"
S2400a="$( [ -r "$S2400_T" ] && cat "$S2400_T")"
has "2400 the table holds the comment line # class<TAB>applies<TAB>owes<TAB>class_by_maturity<TAB>source" \
    $'\n'"$S2400a"$'\n' $'\n# class\tapplies\towes\tclass_by_maturity\tsource\n'
S2400a="$( [ -r "$S2400_T" ] && LC_ALL=C tr -d '\t\n -~' < "$S2400_T" | wc -c | tr -d ' ')"
is "2400 every byte of the table is printable ASCII, a tab or a newline" "$S2400a" "0"
S2400a="$(_s2400_rows count)"
case "$S2400a" in 6|7|8) S2400b="six to eight" ;; *) S2400b="$S2400a row(s)" ;; esac
is "2400 the seed holds six to eight rows" "$S2400b" "six to eight"

# ---- C12: the cells ---------------------------------------------------------------------------------------------------------
is "2400 every class matches [a-z][a-z0-9_]* and none appears twice" "$(_s2400_rows class)" ""
is "2400 every applies holds one or more terms, each a form C4 evaluates (probe:<c>=<state>, cap:<c>, env:maturity>=<value>)" \
   "$(_s2400_rows forms)" ""
is "2400 no applies holds a probe: term on blind or unknown, so no class is ACTIVE because Felix could not look" \
   "$(_s2400_rows blind)" ""
is "2400 every applies holds at least one probe: or cap: term, the only kind a commit can make false" "$(_s2400_rows pc)" ""
is "2400 every class_by_maturity names prototype, internal, public-beta and production once each, with one of the five obligation classes" \
   "$(_s2400_rows cbm)" ""
is "2400 no class_by_maturity decreases as maturity rises from prototype to production" "$(_s2400_rows rise)" ""
is "2400 every source is miss:, candidate: or cite: and 12 lowercase hex digits" "$(_s2400_rows source)" ""

# ---- C12: R1 to R4, and the seed as committed -------------------------------------------------------------------------------
is "2400 R1: paid_ingress applies exactly cap:api cap:llm, and its owes names a request bound and a spend bound" "$(_s2400_rows r1)" "R1 met"
is "2400 R2: another class than paid_ingress holds the term cap:api" "$(_s2400_rows r2)" "R2 met"
is "2400 R3: a class holds probe:local_listener=found and no cap:api, and its owes is a bind to loopback" "$(_s2400_rows r3)" "R3 met"
is "2400 R4: the named R4 class ci_actions_pinned holds no term on api or on local_listener" "$(_s2400_rows r4)" "R4 met"
S2400w="$(printf '%s\t%s\n' \
  paid_ingress 'cap:api cap:llm' route_has_http_test 'cap:api cap:tests' request_body_bounded cap:api \
  health_reflects_readiness 'cap:api cap:deploy' local_listener_binds_loopback probe:local_listener=found \
  ci_actions_pinned cap:ci ci_secret_scoped_to_step 'cap:ci probe:ci_secret=found' \
  container_runs_unprivileged probe:container=found | LC_ALL=C sort)"
is "2400 the seed's classes and their applies are C12's list as committed, so four classes are HTTP-keyed" \
   "$(_s2400_rows pairs | LC_ALL=C sort)" "$S2400w"

# ---- no project name (C12, C16) ---------------------------------------------------------------------------------------------
S2400P="$REAL_HARNESS/../../projects"
if [ -d "$S2400P" ]; then
  S2400a=""; S2400n=0
  S2400l="$( [ -r "$S2400_T" ] && LC_ALL=C tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz' < "$S2400_T")"
  for S2400d in "$S2400P"/*/; do
    [ -d "$S2400d" ] || continue
    S2400d="${S2400d%/}"; S2400d="${S2400d##*/}"
    [ "$S2400d" = felix ] && continue
    S2400n=$((S2400n + 1))
    S2400e="$(printf '%s' "$S2400d" | LC_ALL=C tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"
    case "$S2400l" in *"$S2400e"*) S2400a="$S2400a [$S2400d]" ;; esac
  done
  # Not blind: the count of names read was in the name, so the name differed
  # wherever projects/ held other folders than the home's, as in the public
  # snapshot, which holds felix alone. The name is now the one the skip below gives.
  is "2400 the table names no project under the projects/ beside this harness but felix, comments included, without regard to case" \
     "$( [ -r "$S2400_T" ] && echo read || echo unread)|$S2400a" "read|"
else
  skip "2400 the table names no project under the projects/ beside this harness but felix, comments included, without regard to case" \
       "no projects/ beside this harness"
fi

# ---- C12: the schema row ----------------------------------------------------------------------------------------------------
S2400a="$(LC_ALL=C awk 'p && $0 !~ /^[[:space:]]*(#|$)/ { print; exit } index($0, "discover-rules.tsv\t") == 1 { p = 1 }' "$S2400_SCH" 2>/dev/null)"
is "2400 the first non-comment line after the discover-rules.tsv row of schemas.tsv is the situations.tsv schema row" \
   "$S2400a" "$(printf 'situations.tsv\ttree\tclass applies owes class_by_maturity source\trefused')"
# schema-check as part 0730 runs it: a fixture git tree holding only the two templates, copied from $REAL_HARNESS.
S2400X="$S2400/schema-check"; mkdir -p "$S2400X/engine/harness/templates"
cp "$S2400_SCH" "$S2400X/engine/harness/templates/schemas.tsv" 2>/dev/null
cp "$S2400_T" "$S2400X/engine/harness/templates/situations.tsv" 2>/dev/null
S2400X="$(cd "$S2400X" && pwd -P)"
_s2400_commit() { { _fx_git "$S2400X" add -A && _fx_git "$S2400X" -c user.name=t -c user.email=t@t commit -qm "$1"; } >/dev/null 2>&1; }
_fx_git "$S2400X" init -q -b main >/dev/null 2>&1; _s2400_commit seed
# HAYSTACK NEEDLE WORD -> WORD when HAYSTACK holds NEEDLE, else other (a function: bash 3.2 misreads a case inside $( ) ).
_s2400_in() { case "$1" in *"$2"*) printf %s "$3" ;; *) printf other ;; esac; }
_s2400_sc() { ( cd "$S2400X" && "$REAL_HARNESS/bin/schema-check" 2>&1; echo "rc=$?" ); }
# NAME -> "NAME copied" when the fixture holds templates/NAME byte for byte as $REAL_HARNESS ships it, else "NAME not
# copied". On an engine without the table the cp above copies nothing and schema-check exits 0 over schemas.tsv alone,
# so the exit-0 assertion compares both copies along with the status.
_s2400_cp() { cmp -s "$REAL_HARNESS/templates/$1" "$S2400X/engine/harness/templates/$1" && printf '%s copied' "$1" || printf '%s not copied' "$1"; }
S2400a="$(_s2400_sc)"
is "2400 schema-check, run in a tree holding only schemas.tsv and the shipped situations.tsv, exits 0" \
   "$(_s2400_cp schemas.tsv)|$(_s2400_cp situations.tsv)|${S2400a##*rc=}" "schemas.tsv copied|situations.tsv copied|0"
has "2400 and it read two tables there" "$S2400a" "2 table(s)"
printf '# class\tapplies\towes\tclass_by_maturity\tsource\n' > "$S2400X/engine/harness/templates/situations.tsv"; _s2400_commit empty
S2400a="$(_s2400_sc)"
is "2400 schema-check refuses a situations.tsv of comments only, as the row's refused cell says (control)" \
   "${S2400a##*rc=}|$(_s2400_in "$S2400a" "engine/harness/templates/situations.tsv:-	empty" empty)" "1|empty"
printf 'a_b\tcap:api\towes\tprototype=INFO,internal=INFO,public-beta=INFO,production=INFO\n' > "$S2400X/engine/harness/templates/situations.tsv"
_s2400_commit four
S2400a="$(_s2400_sc)"
is "2400 schema-check refuses a situations.tsv row of four cells, as the row's five columns say (control)" \
   "${S2400a##*rc=}|$(_s2400_in "$S2400a" "engine/harness/templates/situations.tsv:1	cells" cells)" "1|cells"

# ---- C1: felix help ---------------------------------------------------------------------------------------------------------
S2400H="$S2400/help"; mkdir -p "$S2400H/t"
( cd "$S2400H" && env TMPDIR="$S2400H/t" "$FELIX" help ) > "$S2400H/out" 2> "$S2400H/err"; S2400rc=$?
S2400a="$(LC_ALL=C awk 'p && p++ <= 3 { print } index($0, "    felix obligations [") == 1 { p = 1 }' "$S2400H/out")"
S2400w='    felix situations [--at T | --change [B..H]] [--tsv | --propose]
                           what a change owes: the situation rows it owes, blinds and retires,
                           the rows already standing, and what could not be looked at; writes nothing'
is "2400 felix help prints felix situations' three usage lines byte for byte, directly after the felix obligations line under the toolbox" \
   "$S2400rc|$S2400a" "0|$S2400w"
S2400a="$(LC_ALL=C awk '/^  [a-z]/ { s = $0 } index($0, "    felix situations [") == 1 { print s; exit }' "$S2400H/out")"
is "2400 the felix situations entry sits in the section headed the toolbox" "$S2400rc|$S2400a" "0|  the toolbox"

# ---- the library files ------------------------------------------------------------------------------------------------------
S2400n=0; S2400a=""
for S2400f in "$REAL_HARNESS"/lib/situations*.sh; do
  [ -f "$S2400f" ] || continue
  S2400n=$((S2400n + 1))
  S2400l="$(wc -l < "$S2400f" | tr -d ' ')"
  [ "$S2400l" -lt 500 ] || S2400a="$S2400a [${S2400f##*/}: $S2400l lines]"
done
is "2400 at least one engine/harness/lib/situations*.sh exists, and every one has under 500 lines" \
   "$( [ "$S2400n" -ge 1 ] && echo some || echo none)|$S2400a" "some|"
