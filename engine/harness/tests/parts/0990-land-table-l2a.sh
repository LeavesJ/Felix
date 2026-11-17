printf '\nland table (L2a)\n'
# The landing actor's recipe book, and the two checks that will one day stop a
# landing, before either stops anything. projects/<name>/land.tsv says how each
# path lands: a resolver kind (version-above, keyed-union, insertions-union,
# rerun) is a path the actor may settle without a session, and a narrowing
# kind (session, founder) is one it may not. So the schema refuses a resolver
# on any path whose change is an escape, a commission, an authority grant, an
# exception or the trust base: a table that let the actor settle risk.tsv by
# itself would be a quiet way round everything else in this file. The table is
# read only from refs/remotes/origin/main, because a pull request must not
# rewrite the recipe that lands it, and any change to it escapes to a person.
#
# `owed` and `behind` only report in this step. Each writes a would-refuse row
# to says.log and prints nothing, refuses nothing and moves no exit status, so
# how a session lands is unchanged; a dry run writes nothing at all.
#
# Written blind against the contract (the landing-actor design §4 and §11 step
# 3, through the L2a spec), before the implementation was read. Every positive
# assertion here fails against an engine with no lib/land-table.sh; each
# negative one sits beside a positive sibling in the same fixture. The
# assertions the three reviews added (the exact exemption comparison, every
# says.log row counted, uncommitted and behind owed cases, narrowed, the skip
# pattern and functions from the environment, only 0 writing, the land-table
# row, schema-check) were written by the implementer, not blind. Each was shown
# failing for the reason its name gives: against the unfixed branch engine
# where that engine had the defect, and against a one-line mutation of the
# fixed one where it did not (an extra says.log row, a committed-only or a
# two-dot diff).

LT_LIB="$FROOT/harness/lib/land-table.sh"
LT_T="$TMP/lt-table.tsv"
# One library call in a subshell, so nothing it defines leaks into the suite,
# and an engine without the library answers with nothing rather than aborting.
_lt()        { ( . "$LT_LIB" 2>/dev/null; "$@" ) 2>/dev/null; }
_lt_row()    { local IFS=$'\t'; printf '%s\n' "$*"; }
_lt_ed()     { awk "$1" "$2" > "$2.lt" && mv "$2.lt" "$2"; }   # <awk program> <file>: rewrite in place
_lt_lacks()  { case "$2" in *"$3"*) bad "$1" "[$2] holds [$3]" ;; *) ok "$1" ;; esac; }
_lt_state()  { git -C "$1" merge-base --is-ancestor refs/remotes/origin/main HEAD >/dev/null 2>&1 && echo current || echo behind; }
# What the schema says of the table in <file>, as one string: how many rows
# felix_land_rows_in accepts, each refusal as line:reason (a protected one with
# the category word its detail begins with), and felix_land_malformed_in's exit
# status. Against an engine without the library it reads rows=0 refused= rc=127.
_lt_verdict() {
  printf 'rows=%s refused=%s rc=%s' \
    "$(_lt felix_land_rows_in < "$1" | awk 'END { print NR }')" \
    "$(_lt felix_land_malformed_in < "$1" | awk -F'\t' '{ w = ""; if ($2 == "protected") { split($3, d, "[^a-z-]"); w = ":" d[1] }
                                                        printf "%s%s:%s%s", s, $1, $2, w; s = "," }')" \
    "$( ( . "$LT_LIB" 2>/dev/null; felix_land_malformed_in < "$1" >/dev/null 2>&1; echo $? ) )"
}

# ------------------------------------------------------- rows and kinds ----
# felix-home's seven rows, exactly as the design gives them (§4). The hash is
# the design's, so a typo here cannot quietly weaken every assertion that reads
# this file.
{ _lt_row engine/.claude-plugin/plugin.json   version-above    engine/ -
  _lt_row engine/harness/tests/assertions.tsv keyed-union      -       2
  _lt_row engine/harness/tests/red.tsv        rerun            engine/ 'engine/harness/tests/red <B>'
  _lt_row engine/harness/tests/run            insertions-union -       -
  _lt_row HANDOFF.md                          session          -       -
  _lt_row 'projects/[^/]+/CLAUDE\.md'         founder          -       -
  _lt_row 'docs/.*roadmap.*'                  founder          -       -
} > "$TMP/lt-seven.tsv"
LT_SEVEN="$TMP/lt-seven.tsv"
is  "the land-table fixture's seven rows are the design's, byte for byte, by their hash" \
    "$(git hash-object "$LT_SEVEN" 2>/dev/null)" "3dc2dcb4612f4bb0226ef5a5b9f30ba173619d60"

# A reader that drops, reorders or rewrites a row fails the first; a schema
# that refuses one of the design's own rows fails the second.
is  "felix_land_rows_in prints felix-home's seven rows exactly as written, or the landing actor would read a table the founder never armed" \
    "$(_lt felix_land_rows_in < "$LT_SEVEN")" "$(cat "$LT_SEVEN")"
is  "and felix_land_malformed_in refuses none of them and exits 0, or the design's own table would read as broken" \
    "$(_lt_verdict "$LT_SEVEN")" "rows=7 refused= rc=0"

# The one definition of a row is table.sh's. A reader that takes a comment,
# a commented-out row or a blank line for a row fails the first; one that
# numbers refusals by data row instead of by line fails the second.
{ printf '# x\n'; printf '# path\tkind\ttrigger\targ\n'
  _lt_row a.txt version-above engine/ -
  printf '\n'
  printf '#b.txt\tversion-above\t-\t-\n'
  _lt_row c.txt merge-ours - -
  printf '   \n'
  _lt_row d.txt insertions-union - -
} > "$LT_T"
is  "comments, a commented-out row and blank lines are not rows, or a note in the table would bind a path" \
    "$(_lt felix_land_rows_in < "$LT_T")" "$(printf 'a.txt\tversion-above\tengine/\t-\nd.txt\tinsertions-union\t-\t-')"
is  "and a refusal carries its line in the file, comments counted, or the founder is sent to the wrong line" \
    "$(_lt_verdict "$LT_T")" "rows=2 refused=6:kind rc=1"
# The judge's child shell inherits the session's environment and never loads
# table.sh, so a skip pattern read from there would be the session's choice.
is  "which lines are rows does not follow a FELIX_TABLE_SKIP the session exported, or the environment would choose the rows the judge reads" \
    "$( ( FELIX_TABLE_SKIP='^(engine|projects|docs|HANDOFF)'; export FELIX_TABLE_SKIP
          . "$LT_LIB" 2>/dev/null; felix_land_rows_in < "$LT_SEVEN" ) 2>/dev/null | awk 'END { print NR }' )" "7"

# A last row the editor left without a newline is still a row, and it is
# printed with one, or the next reader glues it to whatever follows.
printf 'a.txt\tversion-above\t-\t-' > "$LT_T"
is  "a final row with no newline is read, and printed ending in one, or the last recipe in a table would vanish or run into the next line" \
    "$(_lt felix_land_rows_in < "$LT_T"; printf x)" "$(printf 'a.txt\tversion-above\t-\t-\nx')"

# cells: the shape two readers split differently. Each is refused for that
# alone, read by no one, and fails the table.
printf 'a.txt\tversion-above\t-\n' > "$LT_T"
is  "a three-cell row is refused as cells alone and read by no one, or a reader would invent its missing arg" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:cells rc=1"
printf 'a.txt\tversion-above\t-\t-\textra\n' > "$LT_T"
is  "a five-cell row is refused as cells alone, or a stray tab would carry a column past the schema" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:cells rc=1"
printf 'a.txt\t\tengine/\t-\n' > "$LT_T"
is  "a row with an empty cell is refused as cells alone and not as a kind, or a reader collapsing the empty cell would shift every cell after it" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:cells rc=1"
printf 'a.txt\tversion-above\t-\t-\r\n' > "$LT_T"
is  "a row ending in a CR is refused as cells alone, or a reader keeping the CR would bind an arg no other reader sees" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:cells rc=1"
printf 'a.txt\tversion\r-above\t-\t-\n' > "$LT_T"
is  "and a CR inside a cell is cells too, never kind, or the reason would depend on where the CR fell" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:cells rc=1"

# kind: the kinds are the engine's. A kind the engine does not define is one
# reason on its own, since no column rule applies without one; duplicate is the
# only reason it does not hide.
printf 'a.txt\tmerge-ours\t-\t-\n' > "$LT_T"
is  "a kind the engine does not define is refused as kind, or a table could invent its own way to land a path" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:kind rc=1"
printf '/abs\tmerge-ours\ta b\t-\n' > "$LT_T"
is  "and an unknown kind is that row's only reason, its bad path and trigger unsaid, or the refusal would judge columns no kind defines" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:kind rc=1"
{ _lt_row a.txt version-above - -; _lt_row a.txt merge-ours - -; } > "$LT_T"
is  "but an unknown kind on a path an earlier row binds is a duplicate as well, or a second recipe for one path would go unnamed" \
    "$(_lt_verdict "$LT_T")" "rows=1 refused=2:kind,2:duplicate rc=1"
is  "the kinds are engine constants, the design's six, with session and founder the narrowing two, or a kind could be added without an engine change" \
    "$( . "$LT_LIB" 2>/dev/null; printf '%s|%s' "${FELIX_LAND_KINDS:-}" "${FELIX_LAND_NARROWING:-}" )" \
    "version-above keyed-union insertions-union rerun session founder|session founder"

# path: a resolver is compared to a changed path by string equality, so its
# path must be a plain repository-relative literal. Each line is one shape a
# looser check lets through.
{ for _ltp in 'engine/[a-z]+.sh' /abs/x ../x a/../b -x dir/ a//b -; do _lt_row "$_ltp" version-above - -; done; } > "$LT_T"
is  "a resolver path that is an ERE, absolute, dot-dot, dash-led, slash-ended, double-slashed or the dash itself is refused as path, or it would bind a path no change can equal" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:path,2:path,3:path,4:path,5:path,6:path,7:path,8:path rc=1"
printf 'docs/(\tsession\t-\t-\n' > "$LT_T"
is  "a narrowing path that is not a valid ERE is refused as path, or grep would match it against nothing and the narrowing row would narrow nothing" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:path rc=1"
_lt_row 'projects/[^/]+/CLAUDE\.md' founder - - > "$LT_T"
is  "while an ERE on a founder row is accepted and printed as written, backslash included, or the design's own founder row would be lost" \
    "$(_lt felix_land_rows_in < "$LT_T")|$(_lt_verdict "$LT_T")" "$(cat "$LT_T")|rows=1 refused= rc=0"

# trigger: a literal, which may end in a slash to name a directory; and only
# the dash on a narrowing row, since nothing is owed on a path the actor may
# never write.
{ _lt_row a.txt version-above 'engine//' -; _lt_row b.txt version-above ../x -; _lt_row c.txt version-above 'a b' -; } > "$LT_T"
is  "a trigger with a doubled slash, a dot-dot or a space is refused as trigger, or it would match changes nobody meant" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:trigger,2:trigger,3:trigger rc=1"
{ _lt_row HANDOFF.md session engine/ -; _lt_row docs/x founder engine/ -; } > "$LT_T"
is  "any trigger on a session or founder row is refused as trigger, or a path the actor may never write could be owed" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:trigger,2:trigger rc=1"
{ _lt_row a.txt version-above engine/ -; _lt_row b.txt version-above engine/harness/felix -; } > "$LT_T"
is  "while a directory trigger ending in a slash and a file trigger are accepted on a version-above row, or felix-home's own rows could not be written" \
    "$(_lt_verdict "$LT_T")" "rows=2 refused= rc=0"

# arg: each kind's column rule.
{ _lt_row k1.txt keyed-union - -; _lt_row k2.txt keyed-union - 0; _lt_row k3.txt keyed-union - x; } > "$LT_T"
is  "a keyed-union arg that is not a positive integer is refused as arg, or the union would key on a column that does not exist" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:arg,2:arg,3:arg rc=1"
_lt_row r1.txt rerun - - > "$LT_T"
is  "a rerun row whose command is the dash is refused as arg, or the actor would settle the path by running nothing" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:arg rc=1"
{ _lt_row v1.txt version-above - 2; _lt_row i1.txt insertions-union - 2; _lt_row s1.txt session - 2; _lt_row f1.txt founder - 2; } > "$LT_T"
is  "an arg on a version-above, insertions-union, session or founder row is refused as arg, or a cell the kind never reads would pass as meaningful" \
    "$(_lt_verdict "$LT_T")" "rows=0 refused=1:arg,2:arg,3:arg,4:arg rc=1"
{ _lt_row k.txt keyed-union - 2; _lt_row r.txt rerun - 'a b <B>'; } > "$LT_T"
is  "while keyed-union on column 2 and a rerun command with spaces and <B> are accepted, or felix-home's own rows could not be written" \
    "$(_lt_verdict "$LT_T")" "rows=2 refused= rc=0"

# duplicate: one path, one recipe, and the first stands.
{ _lt_row a.txt version-above - -; _lt_row a.txt insertions-union - -; } > "$LT_T"
is  "a second row on the same path is refused as duplicate and the first is the one read, or one path would have two recipes" \
    "$(_lt felix_land_rows_in < "$LT_T")|$(_lt_verdict "$LT_T")" "$(printf 'a.txt\tversion-above\t-\t-')|rows=1 refused=2:duplicate rc=1"
{ printf 'a.txt\tversion-above\t-\n'; _lt_row a.txt insertions-union - -; } > "$LT_T"
is  "but a row refused as cells claims no path, so the next row on that path stands, or a broken line would disable a good one" \
    "$(_lt_verdict "$LT_T")" "rows=1 refused=1:cells rc=1"
# narrowed: a resolver never overrides a session or founder row, whichever
# comes first, and a narrowing ERE covers the literal paths it matches.
{ _lt_row HANDOFF.md version-above - -; _lt_row HANDOFF.md session - -; } > "$LT_T"
is  "a resolver above a session row on the same path is refused as narrowed and the session row stands, or a row placed first would take a path back from a session" \
    "$(_lt felix_land_rows_in < "$LT_T")|$(_lt_verdict "$LT_T")" "$(printf 'HANDOFF.md\tsession\t-\t-')|rows=1 refused=1:narrowed rc=1"
{ _lt_row 'docs/.*roadmap.*' founder - -; _lt_row docs/2026-roadmap.md version-above - -; _lt_row docs/notes.md version-above - -; } > "$LT_T"
is  "a resolver on a path a founder row's ERE matches is refused as narrowed, while one on a path it does not match stands, or a literal row could carve a path out of the founder's" \
    "$(_lt_verdict "$LT_T")" "rows=2 refused=2:narrowed rc=1"
# Every applicable reason, in the contract's order, once cells and kind pass.
{ _lt_row /abs version-above - -; _lt_row /abs keyed-union 'a b' 0
  _lt_row projects/p/risk.tsv version-above - 2; _lt_row projects/p/risk.tsv version-above - 2; } > "$LT_T"
is  "a row with several faults reports each of them in the order path, trigger, arg, protected, duplicate, or a fixed fault would uncover another one round later" \
    "$(_lt_verdict "$LT_T")" \
    "rows=0 refused=1:path,2:path,2:trigger,2:arg,2:duplicate,3:arg,3:protected:escape-table,4:arg,4:protected:escape-table,4:duplicate rc=1"

# ------------------------------------------ the schema rule, the trust base ----
# Only a session or the founder may bind a path whose change is an escape, a
# commission, an authority grant, an exception or the trust base. Each path
# below is refused for a resolver with the category its detail names, and
# felix_land_protected prints that same word; the order of the categories is
# pinned by projects/p/land.tsv (also an escape table, said as land-table) and
# projects/p/risk.tsv (also a commission table, said as escape-table).
LT_PROT='projects/p/risk.tsv|escape-table
projects/p/qualification.tsv|escape-table
engine/harness/templates/schemas.tsv|escape-table
projects/p/stack.tsv|commission-table
projects/p/capabilities|commission-table
.github/workflows/gate.yml|execute
.github/actions/a/action.yml|execute
projects/p/autonomy|authority
projects/p/autonomy.commission|authority
projects/p/exceptions.tsv|exception
exceptions.tsv|exception
projects/p/land.tsv|land-table
engine/harness/lib/escape.sh|trust-base
engine/harness/lib/land-table.sh|trust-base
engine/harness/felix|trust-base
engine/hooks/hooks.json|trust-base
engine/harness/hooks/pre-tool|trust-base
projects/p/gate.sh|trust-base'
_lt_prot() {  # <path> [kind] [arg]: felix_land_protected's word and status, then the schema's verdict on one row of that kind there
  local w r
  w="$( ( . "$LT_LIB" 2>/dev/null; felix_land_protected "$1" ) </dev/null 2>/dev/null )"
  r="$( ( . "$LT_LIB" 2>/dev/null; felix_land_protected "$1" >/dev/null 2>&1; echo $? ) </dev/null )"
  _lt_row "$1" "${2:-version-above}" - "${3:--}" > "$LT_T"
  printf '%s %s | %s' "$w" "$r" "$(_lt_verdict "$LT_T")"
}
while IFS='|' read -r _ltp _ltc; do
  is "a version-above row on $_ltp is refused as protected, $_ltc, or the landing actor could settle that path without a session" \
     "$(_lt_prot "$_ltp" </dev/null)" "$_ltc 0 | rows=0 refused=1:protected:$_ltc rc=1"
done <<EOF
$LT_PROT
EOF
# The rule is about resolvers, not about version-above: each other resolver
# kind, on one path of every category.
_lt_cat7() {  # <kind> <arg>
  { _lt_row projects/p/risk.tsv "$1" - "$2"; _lt_row projects/p/stack.tsv "$1" - "$2"
    _lt_row .github/workflows/gate.yml "$1" - "$2"; _lt_row projects/p/autonomy "$1" - "$2"
    _lt_row projects/p/exceptions.tsv "$1" - "$2"; _lt_row projects/p/land.tsv "$1" - "$2"
    _lt_row engine/harness/felix "$1" - "$2"; } > "$LT_T"
  _lt_verdict "$LT_T"; }
LT_CAT7='rows=0 refused=1:protected:escape-table,2:protected:commission-table,3:protected:execute,4:protected:authority,5:protected:exception,6:protected:land-table,7:protected:trust-base rc=1'
is  "a keyed-union row is refused on a path of every protected category, or the rule would bind one resolver kind and leave the others open" \
    "$(_lt_cat7 keyed-union 2)" "$LT_CAT7"
is  "and so is an insertions-union row, or a protected table could be landed by concatenation" \
    "$(_lt_cat7 insertions-union -)" "$LT_CAT7"
is  "and so is a rerun row, or a command would rewrite a protected path unattended" \
    "$(_lt_cat7 rerun x)" "$LT_CAT7"
# Narrowing rows are the point of those paths, so they are never refused there.
_lt_narrow() {  # <kind>: a row of that kind on every protected path
  while IFS='|' read -r _ltp _ltc; do _lt_row "$_ltp" "$1" - -; done > "$LT_T" <<EOF
$LT_PROT
EOF
  _lt_verdict "$LT_T"; }
is  "a session row on every protected path is accepted, or a table could not route those paths to a session at all" \
    "$(_lt_narrow session)" "rows=18 refused= rc=0"
is  "and so is a founder row on every one of them, or the founder could not keep them" \
    "$(_lt_narrow founder)" "rows=18 refused= rc=0"
# The rule names paths, not their neighbours: a check by prefix, by directory
# or by extension fails here.
LT_NEAR='engine/harness/lib/say.sh engine/harness/lib/table.sh engine/harness/lib/island.sh projects/p/q/gate.sh projects/p/gate.sh.bak docs/gate.sh .github/CODEOWNERS projects/p/notes.tsv engine/.claude-plugin/plugin.json'
{ for _ltp in $LT_NEAR; do _lt_row "$_ltp" version-above - -; done; } > "$LT_T"
is  "a version-above row on a near neighbour of a protected path is accepted, or the rule would refuse by resemblance and not by the list" \
    "$(_lt_verdict "$LT_T")" "rows=9 refused= rc=0"
is  "and felix_land_protected prints nothing and exits 1 for each of those neighbours, or it could not say a path is ordinary" \
    "$( ( . "$LT_LIB" 2>/dev/null; for _ltp in $LT_NEAR; do _ltw="$(felix_land_protected "$_ltp" 2>&1)"; _ltr=$?
          [ "$_ltr:$_ltw" = "1:" ] || printf '%s(%s:%s) ' "$_ltp" "$_ltr" "$_ltw"; done ) </dev/null )" ""

# The trust base: fourteen entries, two of them patterns. A star spans no
# slash, and the match is whole-path.
LT_TB14='engine/harness/lib/escape.sh engine/harness/lib/commission.sh engine/harness/lib/autonomy.sh engine/harness/lib/landing.sh engine/harness/lib/resolve.sh engine/harness/lib/verify.sh engine/harness/lib/deny.sh engine/harness/lib/deny-read.sh engine/harness/lib/where.sh engine/harness/lib/where-read.sh engine/harness/hooks/pre-tool engine/hooks/hooks.json engine/harness/felix projects/p/gate.sh'
_lt_tbrc() {  # <path>...: felix_land_trust_base's status for each, space-separated
  ( . "$LT_LIB" 2>/dev/null; _lts=""
    for _ltp in "$@"; do felix_land_trust_base "$_ltp" >/dev/null 2>&1; _lts="$_lts${_lts:+ }$?"; done
    printf '%s' "$_lts" ) </dev/null; }
is  "felix_land_trust_base exits 0, printing nothing, for an instance of each of the fourteen trust-base entries, or the schema could not refuse a resolver there" \
    "$( ( . "$LT_LIB" 2>/dev/null; for _ltp in $LT_TB14; do _ltw="$(felix_land_trust_base "$_ltp" 2>&1)"; _ltr=$?
          [ "$_ltr:$_ltw" = "0:" ] || printf '%s(%s:%s) ' "$_ltp" "$_ltr" "$_ltw"; done ) </dev/null )" ""
is  "and exits 1 for a sibling of an entry and for a gate.sh one directory too deep, or a star would span a slash and the base would swallow its neighbours" \
    "$(_lt_tbrc engine/harness/lib/island.sh projects/p/q/gate.sh)" "1 1"
# An unquoted expansion of the list globs its two starred entries against the
# caller's directory. This directory holds one file for each, so a list split
# that way turns both into those files and misses every other instance.
LT_G="$TMP/lt-glob"; mkdir -p "$LT_G/projects/zz" "$LT_G/engine/harness/lib"
: > "$LT_G/projects/zz/gate.sh"; : > "$LT_G/engine/harness/lib/landzz.sh"
is  "the glob fixture would turn both starred trust-base entries into its own files if they were expanded unquoted" \
    "$( cd "$LT_G" && set -- projects/*/gate.sh engine/harness/lib/land*.sh; printf '%s ' "$@" )" \
    "projects/zz/gate.sh engine/harness/lib/landzz.sh "
is  "and from inside it both starred entries still match as patterns, or the trust base would depend on the caller's directory" \
    "$( cd "$LT_G" && _lt_tbrc projects/p/gate.sh engine/harness/lib/landing.sh )" "0 0"
is  "and the schema still refuses a resolver on projects/p/gate.sh from there, or a table checked in the wrong directory would pass" \
    "$( cd "$LT_G" && _lt_prot projects/p/gate.sh </dev/null )" "trust-base 0 | rows=0 refused=1:protected:trust-base rc=1"

# Fail closed: when a list the rule reads is missing, every path is protected,
# said as unknown. Blanked after the library loaded, so the question is what
# the function does with what it finds, not what loading does.
_lt_fc() {  # <what to blank>: felix_land_protected engine/x afterwards, as [word] status
  ( . "$LT_LIB" 2>/dev/null
    case "$1" in
      commission) FELIX_COMMISSION_TABLES='' ;;
      tables)     FELIX_ESCAPE_TABLES='' ;;
      execute)    FELIX_ESCAPE_EXECUTE='' ;;
      lister)     unset -f _felix_escape_listed ;;
    esac
    _ltw="$(felix_land_protected engine/x 2>/dev/null)"; _ltr=$?; printf '[%s] %s' "$_ltw" "$_ltr" ) </dev/null; }
is  "felix_land_protected finds an ordinary engine path unprotected while its lists are loaded, exit 1 and no word" \
    "$(_lt_fc none)" "[] 1"
is  "but with the commission list blanked it says unknown and exits 0, or a missing list would let a resolver through" \
    "$(_lt_fc commission)" "[unknown] 0"
is  "and the schema then refuses a version-above row on that path as protected, unknown, or the fail-closed word would protect nothing" \
    "$( ( . "$LT_LIB" 2>/dev/null; FELIX_COMMISSION_TABLES=''
          _lt_row engine/x version-above - - | felix_land_malformed_in 2>/dev/null \
            | awk -F'\t' '{ split($3, d, "[^a-z-]"); printf "%s%s:%s", s, $2, d[1]; s = "," }' ) </dev/null )" "protected:unknown"
is  "and it fails closed the same way with the escape list or the execute list blanked, or with the lister gone" \
    "$(_lt_fc tables) $(_lt_fc execute) $(_lt_fc lister)" "[unknown] 0 [unknown] 0 [unknown] 0"

# --------------------------------------------- read from the base ref only ----
# A repository R holding projects/lt/, whose table is committed on local main
# before any origin/main exists. Its fourth line is a row the schema refuses.
LT_C="$TMP/lt-base"; mkdir -p "$LT_C"
( _fx_cd "$LT_C" && git init -q -b main && git config user.email t@t && git config user.name t \
  && mkdir -p projects/lt projects/ltnone \
  && printf '{ "name": "lt" }\n' > projects/lt/project.json && printf '{ "name": "ltnone" }\n' > projects/ltnone/project.json \
  && { printf '# the table origin/main holds\n'; _lt_row a.txt version-above engine/ -
       _lt_row b.txt insertions-union - -; _lt_row c.txt merge-ours - -; } > projects/lt/land.tsv \
  && _lt_row top.txt version-above - - > land.tsv \
  && git add -A && git commit -qm c1 ) >/dev/null 2>&1
LT_C="$(cd "$LT_C" && pwd -P)"
LT_CP="$LT_C/projects/lt"
LT_CROWS="$(printf 'a.txt\tversion-above\tengine/\t-\nb.txt\tinsertions-union\t-\t-')"
_lt_at()  {  # <proj dir>: felix_land_table_at_base's status, then what it printed
  ( . "$LT_LIB" 2>/dev/null; _lto="$(felix_land_table_at_base "$1" 2>/dev/null)"; _ltr=$?; printf '%s|%s' "$_ltr" "$_lto" ) </dev/null; }
_lt_mal() {  # <proj dir>: felix_land_malformed's status, then each refusal as line:reason
  ( . "$LT_LIB" 2>/dev/null; _lto="$(felix_land_malformed "$1" 2>/dev/null)"; _ltr=$?
    printf '%s|%s' "$_ltr" "$(printf '%s' "$_lto" | awk -F'\t' '{ printf "%s%s:%s", s, $1, $2; s = "," }')" ) </dev/null; }
_lt_count() { awk -v r="$1" 'index($0, r) == 1 { n++ } END { print n+0 }'; }   # <row prefix>: rows on stdin that begin with it

is  "the base-read fixture has its table committed on local main and no origin/main yet" \
    "$(git -C "$LT_C" show main:projects/lt/land.tsv >/dev/null 2>&1 && echo on-main || echo missing)|$(git -C "$LT_C" rev-parse -q --verify refs/remotes/origin/main >/dev/null 2>&1 && echo origin || echo no-origin)" \
    "on-main|no-origin"
# A reader that falls back to local main, as felix_base_ref does, fails here.
is  "with no origin/main the table is not read at all, local main's copy included, or a local branch could stand in for the base" \
    "$(_lt_at "$LT_CP") rows=[$(_lt felix_land_rows "$LT_CP")]" "1| rows=[]"
_fx_git "$LT_C" update-ref refs/remotes/origin/main HEAD >/dev/null 2>&1
is  "once origin/main holds the table, felix_land_table_at_base prints it as that ref holds it, or the base could not be read at all" \
    "$(_lt_at "$LT_CP")" "0|$(git -C "$LT_C" show refs/remotes/origin/main:projects/lt/land.tsv 2>/dev/null)"
is  "and felix_land_rows prints its accepted rows and leaves out the one refused, or a broken row would bind a path" \
    "$(_lt felix_land_rows "$LT_CP")" "$LT_CROWS"
is  "and felix_land_malformed reports that refused row by its line and exits 1, or a table that cannot be read would pass for a clean one" \
    "$(_lt_mal "$LT_CP")" "1|4:kind"
is  "a project with no land.tsv at origin/main has no table: status 1, no rows and nothing malformed, or an absent table would read as a broken one" \
    "$(_lt_at "$LT_C/projects/ltnone") rows=[$(_lt felix_land_rows "$LT_C/projects/ltnone")] $(_lt_mal "$LT_C/projects/ltnone")" "1| rows=[] 0|"
is  "the repository's toplevel is not a project, so a land.tsv at the root of origin/main is never read as one" \
    "$(_lt_at "$LT_C")" "1|"
is  "a project path spelled through a dot-dot is resolved before its table is looked up, or the same project would read two ways" \
    "$(_lt felix_land_rows "$LT_C/projects/ltnone/../lt")" "$LT_CROWS"

# A row the base does not hold, in each place a session can put one. Reading
# the working tree, HEAD or the local branch fails one of these three.
_lt_row d.txt version-above - - >> "$LT_CP/land.tsv"
is  "a row added in the working tree only is not read, or an uncommitted edit would rewrite the recipe" \
    "$(_lt felix_land_rows "$LT_CP")" "$LT_CROWS"
( _fx_cd "$LT_C" && git checkout -q -b feat && git add -A && git commit -qm 'a row on the branch' ) >/dev/null 2>&1
is  "the base-read fixture's branch commit holds a row origin/main lacks" \
    "$(git -C "$LT_C" show feat:projects/lt/land.tsv 2>/dev/null | _lt_count d.txt)|$(git -C "$LT_C" show refs/remotes/origin/main:projects/lt/land.tsv 2>/dev/null | _lt_count d.txt)" "1|0"
is  "and that row, committed on a branch origin/main does not hold, is not read, or a pull request could rewrite the recipe that lands it" \
    "$(_lt felix_land_rows "$LT_CP")" "$LT_CROWS"
( _fx_cd "$LT_C" && git checkout -q main && _lt_row e.txt version-above - - >> projects/lt/land.tsv \
  && git commit -qam 'a row on local main' && git checkout -q feat ) >/dev/null 2>&1
is  "the base-read fixture's local main holds a row origin/main lacks, and the checkout stands on its branch" \
    "$(git -C "$LT_C" show main:projects/lt/land.tsv 2>/dev/null | _lt_count e.txt)|$(git -C "$LT_C" show refs/remotes/origin/main:projects/lt/land.tsv 2>/dev/null | _lt_count e.txt)|$(git -C "$LT_C" rev-parse --abbrev-ref HEAD 2>/dev/null)" "1|0|feat"
is  "a row committed on local main while origin/main is behind it is not read, or the base would be whatever the local branch says" \
    "$(_lt felix_land_rows "$LT_CP")" "$LT_CROWS"
# Outside any repository there is no base at all, whatever the directory holds.
LT_O="$TMP/lt-outside/projects/lt"; mkdir -p "$LT_O"; _lt_row a.txt version-above engine/ - > "$LT_O/land.tsv"
_ltn="a project outside any repository has no base table: status 1, and nothing on stdout or stderr, or a file on disk would pass for the base"
if git -C "$LT_O" rev-parse --show-toplevel >/dev/null 2>&1; then
  skip "$_ltn" "the suite's temporary directory is inside a git repository"
else
  is "$_ltn" "$( ( . "$LT_LIB" 2>/dev/null; felix_land_table_at_base "$LT_O" 2>&1; printf '|%s' "$?" ) </dev/null )" "|1"
fi

# ------------------------------------------------------ escape membership ----
# land.tsv joins the exemption tables beside ecosystem.tsv: a resolver row is a
# path the actor may settle without a session and a narrowing row is one it
# may not, so adding a row widens, removing one widens, and no edit is free
# but a comment. felix_escapes on a project with no risk.tsv, so only the
# engine's own channels speak. Each case is one commit on top of the base.
LT_E="$TMP/lt-escape"; LT_EP="$TMP/lt-escape-proj"; mkdir -p "$LT_E" "$LT_EP"
( _fx_cd "$LT_E" && git init -q -b main && git config user.email t@t && git config user.name t \
  && mkdir -p projects/anyproj some/dir && printf 'notes\n' > README.md \
  && { printf '# how each path lands\n'; _lt_row a.txt version-above engine/ -; _lt_row b.txt insertions-union - -
       printf '#c.txt\tversion-above\t-\t-\n'; _lt_row 'docs/.*roadmap.*' founder - -
       _lt_row e.txt session - -; _lt_row e.txt founder - -; } > projects/anyproj/land.tsv \
  && _lt_row a.txt version-above - - > some/dir/land.tsv \
  && { printf '# kind\tpath\twords\tnote\n'; _lt_row allow lib/y.sh npm prose; } > ecosystem.tsv \
  && git add -A && git commit -qm base ) >/dev/null 2>&1
LT_E="$(cd "$LT_E" && pwd -P)"
LT_EB="$(git -C "$LT_E" rev-parse -q --verify HEAD 2>/dev/null)"
LT_EL=projects/anyproj/land.tsv
_lt_esc() { ( cd "$LT_E" && . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
              felix_escapes "$LT_EP" "$LT_EB" "$LT_E" ) </dev/null 2>/dev/null; }
# The channels felix_escapes names for <path> once the edit is committed on
# the base, or `unchanged` when the edit left the tree as the base had it, so
# a quiet answer is never a fixture that did nothing.
_lt_echan() {  # <path> <edit command...>, run at the repository root
  local p="$1"; shift
  ( _fx_cd "$LT_E" && git reset -q --hard "$LT_EB" && git clean -qfd && "$@" && git add -A \
      && git -c user.name=t -c user.email=t@t commit -qm edit ) >/dev/null 2>&1
  if git -C "$LT_E" diff --quiet "$LT_EB" HEAD 2>/dev/null; then printf 'unchanged'; return 0; fi
  _lt_esc | awk -F'\t' -v p="$p" '$2 == p { print $1 }' | LC_ALL=C sort -u | awk '{ printf "%s%s", s, $0; s = " " }'
}
_lt_e_new() { mkdir -p projects/newproj && _lt_row a.txt version-above - - > projects/newproj/land.tsv; }
is  "adding a row to a land table escapes as verifier, or a branch could grant the actor a path and merge green" \
    "$(_lt_echan "$LT_EL" _lt_ed '1; END { print "d.txt\tversion-above\t-\t-" }' "$LT_EL")" "verifier"
has "and says why: its rows exempt things from a check, which is why growth is not free there" \
    "$(_lt_esc | awk -F'\t' -v p="$LT_EL" '$2 == p { print $3 }')" "exempt"
is  "removing a row escapes as verifier, or dropping a narrowing row would hand its path to the actor unseen" \
    "$(_lt_echan "$LT_EL" _lt_ed '!/^b\.txt\t/' "$LT_EL")" "verifier"
is  "commenting a row out escapes as verifier, or a hash mark would remove a row unseen" \
    "$(_lt_echan "$LT_EL" _lt_ed '/^a\.txt\t/ { $0 = "#" $0 } 1' "$LT_EL")" "verifier"
is  "turning a comment into a row escapes as verifier, or deleting a hash mark would add a row unseen" \
    "$(_lt_echan "$LT_EL" _lt_ed '/^#c\.txt\t/ { sub(/^#/, "") } 1' "$LT_EL")" "verifier"
is  "editing one cell of a row in place escapes as verifier, or a narrowing row could be turned into a resolver unseen" \
    "$(_lt_echan "$LT_EL" _lt_ed '/^b\.txt\t/ { sub(/insertions-union/, "version-above") } 1' "$LT_EL")" "verifier"
# Three edits a comparison of sorted, comma-stripped lines reads as no change,
# while the reader sees each: a comma on the last cell is an arg it refuses, so
# the founder row is dropped; of two rows on one path the first stands, so a
# swap changes which; and a repeated line is a duplicate it refuses.
is  "appending a comma to a founder row's last cell escapes as verifier, or the reader would drop that founder row with nobody asked" \
    "$(_lt_echan "$LT_EL" _lt_ed '/^docs\/\.\*roadmap/ { $0 = $0 "," } 1' "$LT_EL")" "verifier"
is  "swapping two rows that bind the same path escapes as verifier, or which of them stands could change with nobody asked" \
    "$(_lt_echan "$LT_EL" _lt_ed '/^e\.txt\tsession\t/ { held = $0; next } { print } /^e\.txt\tfounder\t/ { print held }' "$LT_EL")" "verifier"
is  "repeating a row exactly escapes as verifier, or a line the reader refuses as a duplicate would arrive unseen" \
    "$(_lt_echan "$LT_EL" _lt_ed '{ print } /^a\.txt\t/ { print }' "$LT_EL")" "verifier"
is  "and a comma added to an ecosystem.tsv row escapes as verifier too, since every exemption table is compared as its reader reads it" \
    "$(_lt_echan ecosystem.tsv _lt_ed '/^allow\tlib\/y\.sh\t/ { $0 = $0 "," } 1' ecosystem.tsv)" "verifier"
# The control for the five above, in the same fixture: prose stays free.
is  "rewording only a comment line in it escapes nothing, or every note about the table would go to the founder" \
    "$(_lt_echan "$LT_EL" _lt_ed '/^# how each path lands$/ { $0 = "# how each path is landed" } 1' "$LT_EL")" ""
is  "creating a land table with a row where the base had none escapes as verifier, or a new project's first recipe would land unseen" \
    "$(_lt_echan projects/newproj/land.tsv _lt_e_new)" "verifier"
is  "deleting a land table that had rows escapes as verifier, or every narrowing row in it would go at once unseen" \
    "$(_lt_echan "$LT_EL" git rm -q "$LT_EL")" "verifier"
is  "a land.tsv in any directory is one by its basename, and a row added to some/dir/land.tsv escapes as verifier" \
    "$(_lt_echan some/dir/land.tsv _lt_ed '1; END { print "b.txt\tversion-above\t-\t-" }' some/dir/land.tsv)" "verifier"
is  "and a row added to ecosystem.tsv still escapes as verifier, or land.tsv replaced the exemption table it was meant to join" \
    "$(_lt_echan ecosystem.tsv _lt_ed '1; END { print "allow\tlib/x.sh\tcargo\tprose" }' ecosystem.tsv)" "verifier"
( _fx_cd "$LT_E" && git reset -q --hard "$LT_EB" && git clean -qfd ) >/dev/null 2>&1
is  "the exemption tables are exactly ecosystem.tsv and land.tsv, or any change to a land table would not reach a person" \
    "$( . "$FROOT/harness/lib/escape.sh" 2>/dev/null; printf '%s' "${FELIX_ESCAPE_EXEMPTION_TABLES:-}" )" "ecosystem.tsv land.tsv"
is  "and land.tsv is named once among the escape tables, as a basename, or a project's table under a name the engine does not know would be missed" \
    "$( . "$FROOT/harness/lib/escape.sh" 2>/dev/null
        printf '%s\n' "${FELIX_ESCAPE_TABLES:-}" | awk '{ for (i = 1; i <= NF; i++) if ($i == "land.tsv") n++ } END { print n+0 }' )" "1"
# Not a commission table: the policy hash covers every listed name whether or
# not the file exists, so joining that list would move every governed
# project's hash on deploy. The pair above is the red sibling of these two.
is  "but the commission tables stay byte-identical with land.tsv loaded, or every governed project's policy hash would move on deploy" \
    "$( . "$FROOT/harness/lib/detect.sh" 2>/dev/null; . "$FROOT/harness/lib/commission.sh" 2>/dev/null; . "$LT_LIB" 2>/dev/null
        printf '%s' "${FELIX_COMMISSION_TABLES:-}" )" \
    "project.json capabilities commissioning.tsv stack.tsv profiles.tsv routes.tsv setup.tsv probes.tsv risk.tsv evidence.tsv deny.tsv obligations.tsv"
LT_PV="$TMP/lt-policy"; mkdir -p "$LT_PV"
printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n' > "$LT_PV/commissioning.tsv"
_lt_pv() { ( . "$FROOT/harness/lib/detect.sh" 2>/dev/null; . "$FROOT/harness/lib/commission.sh" 2>/dev/null
             . "$LT_LIB" 2>/dev/null; felix_commission_policy_version "$LT_PV" 2>/dev/null ) </dev/null; }
_ltpv0="$(_lt_pv)"; _lt_row a.txt version-above - - > "$LT_PV/land.tsv"; _ltpv1="$(_lt_pv)"
is  "and a project's commission policy version is the same with and without a land.tsv beside its tables, or writing one would stale its receipt" \
    "$([ -n "$_ltpv0" ] && [ "$_ltpv0" = "$_ltpv1" ] && echo same || echo "moved: [$_ltpv0] [$_ltpv1]")" "same"

# ---------------------------------------------------------------- behind ----
# main at c1, feat at c3 off c1, and origin/main moved to c2, a child of c1
# that feat does not hold. Checked out on feat.
_lt_mkb() {  # <dir> <proj>
  mkdir -p "$1" "$MEM/$2" && ( _fx_cd "$1" && git init -q -b main && git config user.email t@t && git config user.name t \
    && mkdir -p "projects/$2" && printf '{ "name": "%s" }\n' "$2" > "projects/$2/project.json" \
    && printf 'one\n' > one.txt && git add -A && git commit -qm c1 \
    && git checkout -q -b feat && printf 'three\n' > three.txt && git add -A && git commit -qm c3 \
    && git checkout -q --detach main && printf 'two\n' > two.txt && git add -A && git commit -qm c2 \
    && git update-ref refs/remotes/origin/main HEAD && git checkout -q feat ) >/dev/null 2>&1; }
_lt_behind() {  # <root> <base>: felix_merge_behind's status, then what it printed
  ( . "$LT_LIB" 2>/dev/null; _lto="$(felix_merge_behind "$1" "$2" 2>/dev/null)"; _ltr=$?; printf '%s|%s' "$_ltr" "$_lto" ) </dev/null; }
_lt_mkb "$TMP/lt-behind" ltbh; LT_B="$(cd "$TMP/lt-behind" && pwd -P)"
LT_BC2="$(git -C "$LT_B" rev-parse -q --verify 'refs/remotes/origin/main^{commit}' 2>/dev/null)"
LT_BC3="$(git -C "$LT_B" rev-parse -q --verify 'HEAD^{commit}' 2>/dev/null)"
is  "the behind fixture stands where it says: feat does not hold origin/main's commit" \
    "$(git -C "$LT_B" merge-base --is-ancestor "$LT_BC2" HEAD >/dev/null 2>&1 && echo current || echo behind) $(git -C "$LT_B" rev-parse --abbrev-ref HEAD 2>/dev/null)" "behind feat"
is  "a branch that does not hold origin/main's commit is behind, status 0, naming the base and both commits, or a stale branch would land unannounced" \
    "$(_lt_behind "$LT_B" origin/main)" "$(printf '0|origin/main\t%s\t%s' "$LT_BC2" "$LT_BC3")"
_lt_mkb "$TMP/lt-merged" ltmg; LT_B2="$(cd "$TMP/lt-merged" && pwd -P)"
( _fx_cd "$LT_B2" && git merge -q --no-edit refs/remotes/origin/main ) >/dev/null 2>&1
is  "the merged behind fixture holds origin/main once it has merged it" "$(_lt_state "$LT_B2")" "current"
is  "and a branch that has merged origin/main is not behind, status 1 and nothing printed, or every current branch would be reported" \
    "$(_lt_behind "$LT_B2" origin/main)" "1|"
is  "a base that names nothing, or no base at all, cannot be told, status 2 and nothing printed, or a typo would read as current" \
    "$(_lt_behind "$LT_B" no-such) $(_lt_behind "$LT_B" '')" "2| 2|"
LT_B3="$TMP/lt-unborn"; mkdir -p "$LT_B3"
( _fx_cd "$LT_B3" && git init -q -b main && git config user.email t@t && git config user.name t \
  && printf 'one\n' > one.txt && git add -A && git commit -qm c1 && git update-ref refs/remotes/origin/main HEAD \
  && git checkout -q --orphan unborn ) >/dev/null 2>&1
is  "the unborn fixture has no HEAD commit while origin/main resolves" \
    "$(git -C "$LT_B3" rev-parse -q --verify 'HEAD^{commit}' >/dev/null 2>&1 && echo head || echo no-head) $(git -C "$LT_B3" rev-parse -q --verify refs/remotes/origin/main >/dev/null 2>&1 && echo base || echo no-base)" "no-head base"
is  "and a checkout whose HEAD holds no commit cannot be told either, status 2, or a fresh branch would read as current" \
    "$(_lt_behind "$LT_B3" origin/main)" "2|"

# ------------------------------------------------------------------ owed ----
# origin/main carries felix-home's seven rows for projects/ltow, and one row
# with a file trigger for projects/ltc. One branch per case, each cut from
# origin/main and rewriting the files it names.
LT_F="$TMP/lt-owed"; mkdir -p "$LT_F" "$MEM/ltow" "$MEM/ltc"
( _fx_cd "$LT_F" && git init -q -b main && git config user.email t@t && git config user.name t \
  && mkdir -p projects/ltow projects/ltc engine/.claude-plugin engine/harness/tests engine/harness/lib docs src \
  && cp "$LT_SEVEN" projects/ltow/land.tsv && _lt_row out.txt insertions-union src/a.c - > projects/ltc/land.tsv \
  && printf '{ "version": "0.0.1" }\n' > engine/.claude-plugin/plugin.json \
  && printf 'base\n' > engine/harness/tests/red.tsv && printf 'x\n' > engine/harness/lib/x.sh \
  && printf 'a\n' > docs/a.md && printf 'c\n' > src/a.c && printf 'cc\n' > src/a.cc && printf 'out\n' > out.txt \
  && git add -A && git commit -qm c1 && git update-ref refs/remotes/origin/main HEAD ) >/dev/null 2>&1
LT_F="$(cd "$LT_F" && pwd -P)"; LT_FP="$LT_F/projects/ltow"
_lt_fbr() {  # <branch> <file>...
  local b="$1" f; shift
  ( _fx_cd "$LT_F" && git checkout -q -f -B "$b" refs/remotes/origin/main && git clean -qfd \
      && for f in "$@"; do printf 'changed on %s\n' "$b" >> "$f"; done \
      && git add -A && git commit -qm "$b" ) >/dev/null 2>&1; }
_lt_fon() { ( _fx_cd "$LT_F" && git checkout -q -f "$1" && git clean -qfd ) >/dev/null 2>&1; }
_lt_owed() {  # <proj dir> <root> [base]: felix_land_owed's status, then what it printed
  ( unset FELIX_MERGE_DRY_RUN; . "$LT_LIB" 2>/dev/null
    _lto="$(felix_land_owed "$1" "$2" "${3-origin/main}" 2>/dev/null)"; _ltr=$?; printf '%s|%s' "$_ltr" "$_lto" ) </dev/null; }
_lt_fbr f-all  engine/harness/lib/x.sh engine/.claude-plugin/plugin.json engine/harness/tests/red.tsv
_lt_fbr f-docs docs/a.md
_lt_fbr f-ver  engine/.claude-plugin/plugin.json
_lt_fbr f-dash engine/harness/lib/x.sh engine/.claude-plugin/plugin.json engine/harness/tests/red.tsv -
_lt_fbr f-c    src/a.c
_lt_fbr f-cc   src/a.cc
_lt_fbr feat   engine/harness/lib/x.sh
LT_OWED2="$(printf 'engine/.claude-plugin/plugin.json\tversion-above\tengine/\nengine/harness/tests/red.tsv\trerun\tengine/')"
is  "the owed fixture's feat changes engine/harness/lib/x.sh alone against origin/main" \
    "$(git -C "$LT_F" diff --name-only refs/remotes/origin/main HEAD 2>/dev/null)" "engine/harness/lib/x.sh"
is  "a change under engine/ that bumps no version and reruns nothing owes both rows, in table order, or the landing that forgot them goes unnamed" \
    "$(_lt_owed "$LT_FP" "$LT_F")" "0|$LT_OWED2"
_lt_fon f-all
is  "the same change with the version bumped and red.tsv rewritten owes nothing, or a row would stay owed after it was paid" \
    "$(_lt_owed "$LT_FP" "$LT_F")" "0|"
_lt_fon f-docs
is  "a change outside every trigger owes nothing, or a docs branch would be told it owes a version" \
    "$(_lt_owed "$LT_FP" "$LT_F")" "0|"
_lt_fon f-ver
is  "a version bump alone still owes red.tsv, since plugin.json is itself under engine/, or the bump would excuse the rerun" \
    "$(_lt_owed "$LT_FP" "$LT_F")" "0|$(printf 'engine/harness/tests/red.tsv\trerun\tengine/')"
_lt_fon f-c
is  "a trigger naming a file owes its row when that very file changes, or file triggers would bind nothing" \
    "$(_lt_owed "$LT_F/projects/ltc" "$LT_F")" "0|$(printf 'out.txt\tinsertions-union\tsrc/a.c')"
_lt_fon f-cc
is  "but not when a file it merely prefixes changes, since only a trigger ending in a slash names a directory" \
    "$(_lt_owed "$LT_F/projects/ltc" "$LT_F")" "0|"
_lt_fon f-dash
is  "the dash fixture's branch changes a file named - and leaves assertions.tsv and tests/run alone" \
    "$(git -C "$LT_F" diff --name-only refs/remotes/origin/main HEAD 2>/dev/null | awk '$0 == "-" || /assertions\.tsv$/ || /tests\/run$/' | tr '\n' ' ')" "- "
is  "a row whose trigger is - is never owed, not even when a file named - changes and its path is untouched, or the dash would read as a path" \
    "$(_lt_owed "$LT_FP" "$LT_F")" "0|"
( _fx_cd "$LT_F" && git checkout -q -f -B f-tree refs/remotes/origin/main && git clean -qfd \
  && printf 'changed\n' >> engine/harness/lib/x.sh && _lt_row docs/a.md version-above engine/ - >> projects/ltow/land.tsv \
  && git add -A && git commit -qm f-tree && _lt_row out.txt version-above engine/ - >> projects/ltow/land.tsv ) >/dev/null 2>&1
is  "a row that exists only on the branch or only in the working tree is never owed, or a pull request could invent a debt the base does not hold" \
    "$(_lt_owed "$LT_FP" "$LT_F")" "0|$LT_OWED2"
is  "an empty base or one that names nothing cannot be computed, status 2 and nothing printed, or a typo would read as nothing owed" \
    "$(_lt_owed "$LT_FP" "$LT_F" '') $(_lt_owed "$LT_FP" "$LT_F" no-such)" "2| 2|"
# What merging would change includes what is not yet committed: x.sh edited
# on a branch that is origin/main itself, first unstaged, then staged. A reader
# of committed changes only, three dots or two, owes nothing here.
( _fx_cd "$LT_F" && git checkout -q -f -B f-wt refs/remotes/origin/main && git clean -qfd \
  && printf 'edited, not committed\n' >> engine/harness/lib/x.sh ) >/dev/null 2>&1
is  "the uncommitted-change fixture's HEAD is origin/main's commit, and x.sh differs only in the working tree" \
    "$(git -C "$LT_F" rev-parse -q --verify HEAD 2>/dev/null | cut -c1-12) $(git -C "$LT_F" diff --name-only 2>/dev/null) $(git -C "$LT_F" diff --cached --name-only 2>/dev/null | awk 'END { print NR }')" \
    "$(git -C "$LT_F" rev-parse -q --verify refs/remotes/origin/main 2>/dev/null | cut -c1-12) engine/harness/lib/x.sh 0"
is  "an engine change left unstaged owes both rows, or a landing that commits it later would never have been told" \
    "$(_lt_owed "$LT_FP" "$LT_F")" "0|$LT_OWED2"
( _fx_cd "$LT_F" && git add engine/harness/lib/x.sh ) >/dev/null 2>&1
is  "and staged, it owes both rows still, or the index would hide a debt the working tree showed" \
    "$(git -C "$LT_F" diff --cached --name-only 2>/dev/null)|$(_lt_owed "$LT_FP" "$LT_F")" "engine/harness/lib/x.sh|0|$LT_OWED2"

# ---------------------------------------------------- the report-only rows ----
_lt_said()  { awk -F'\t' '$2 == "would-refuse"' "$MEM/$1/says.log" 2>/dev/null; }
_lt_nsaid() { _lt_said "$1" | awk 'END { print NR }'; }
_lt_nall()  { awk 'END { print NR }' "$MEM/$1/says.log" 2>/dev/null || echo 0; }   # every row, whatever its kind
_lt_wr() {  # <proj dir> <root> <session, or - for none> <FELIX_MERGE_DRY_RUN: 1, 0, or - for unset> [base]: felix_land_would_refuse's status, then all it printed
  ( if [ "$3" = - ]; then unset CLAUDE_CODE_SESSION_ID; else CLAUDE_CODE_SESSION_ID="$3"; export CLAUDE_CODE_SESSION_ID; fi
    if [ "$4" = - ]; then unset FELIX_MERGE_DRY_RUN; else FELIX_MERGE_DRY_RUN="$4"; export FELIX_MERGE_DRY_RUN; fi
    . "$LT_LIB" 2>/dev/null
    _lto="$(felix_land_would_refuse "$1" "${5-origin/main}" "$2" 2>&1)"; _ltr=$?; printf '%s|%s' "$_ltr" "$_lto" ) </dev/null; }
# A behind branch, nothing owed: one row, and nothing said anywhere else.
LT_BP="$LT_B/projects/ltbh"
_ltn0="$(_lt_nsaid ltbh)"; _lta0="$(_lt_nall ltbh)"
is  "felix_land_would_refuse on a behind branch prints nothing on stdout or stderr and returns 0, or it could not sit inside the merge boundary unseen" \
    "$(_lt_wr "$LT_BP" "$LT_B" lt-s1 0)" "0|"
_ltn1="$(_lt_nsaid ltbh)"; _lta1="$(_lt_nall ltbh)"
# Counted twice: the would-refuse rows, and every row of any kind. A held or
# refused row beside it would move a figure the report must not move.
is  "and it adds exactly one row to that project's says.log, a would-refuse row and nothing of another kind, or the behind branch would leave no record or move another count" \
    "$((_ltn1 - _ltn0)) $((_lta1 - _lta0))" "1 1"
is  "recorded under the session it ran in, with felix merge as its cause, or the row could not be joined to the attempt" \
    "$(_lt_said ltbh | tail -1 | cut -f3,4)" "$(printf 'lt-s1\tfelix merge')"
has "saying which branch is behind which base, by both commits, or the row would not say what to merge" \
    "$(_lt_said ltbh | tail -1 | cut -f5)" "feat: behind: origin/main $LT_BC2 is not in HEAD $LT_BC3"
_lt_wr "$LT_BP" "$LT_B" - 0 >/dev/null
is  "with no session variable the would-refuse row says unknown in the session column, or it would carry an empty cell" \
    "$(_lt_said ltbh | tail -1 | cut -f3)" "unknown"
_ltn0="$(_lt_nsaid ltbh)"; _lt_wr "$LT_BP" "$LT_B" lt-s1 1 >/dev/null; _ltn1="$(_lt_nsaid ltbh)"
is  "a dry run on the same behind branch adds no row, or says.log would record merges nobody attempted" \
    "$((_ltn1 - _ltn0))" "0"
# Only 0 is a real attempt: cmd_merge sets 0 or 1, and a CLI from before this
# library sets nothing, so unset is what that CLI's --dry-run looks like.
_ltn0="$(_lt_nsaid ltbh)"; _lt_wr "$LT_BP" "$LT_B" lt-s1 - >/dev/null
_ltn1="$(_lt_nsaid ltbh)"; _lt_wr "$LT_BP" "$LT_B" lt-s1 0 >/dev/null; _ltn2="$(_lt_nsaid ltbh)"
is  "with FELIX_MERGE_DRY_RUN unset it adds no row, and with it 0 it adds one, or an older CLI's dry run would write the report" \
    "$((_ltn1 - _ltn0)) $((_ltn2 - _ltn1))" "0 1"
# The owed fixture's feat: owing, not behind.
_lt_fon feat
LT_FH="$(git -C "$LT_F" rev-parse -q --verify HEAD 2>/dev/null)"
is  "the owed fixture's feat is not behind origin/main" "$(_lt_state "$LT_F") $(git -C "$LT_F" rev-parse --abbrev-ref HEAD 2>/dev/null)" "current feat"
_ltn0="$(_lt_nsaid ltow)"; _lta0="$(_lt_nall ltow)"; _lt_wr "$LT_FP" "$LT_F" lt-s1 0 >/dev/null
_ltn1="$(_lt_nsaid ltow)"; _lta1="$(_lt_nall ltow)"
is  "a branch that owes rows and is not behind adds exactly one row, a would-refuse row and nothing of another kind, or the debt would leave no record or move another count" \
    "$((_ltn1 - _ltn0)) $((_lta1 - _lta0))" "1 1"
has "naming each owed path with its kind and trigger, in table order, at HEAD, or the row would not say what is owed" \
    "$(_lt_said ltow | tail -1 | cut -f5)" \
    "feat: owed: engine/.claude-plugin/plugin.json (version-above on engine/); engine/harness/tests/red.tsv (rerun on engine/) at HEAD $LT_FH"
_ltn0="$(_lt_nsaid ltow)"; _lt_wr "$LT_FP" "$LT_F" lt-s1 1 >/dev/null; _ltn1="$(_lt_nsaid ltow)"
is  "and a dry run on that owing branch adds none, or a triage session's dry run would write a report" \
    "$((_ltn1 - _ltn0))" "0"
_lt_fon f-docs
_ltn0="$(_lt_nsaid ltow)"; _lt_wr "$LT_FP" "$LT_F" lt-s1 0 >/dev/null; _ltn1="$(_lt_nsaid ltow)"
is  "a branch neither behind nor owing adds no row, or every clean landing would leave a refusal on record" \
    "$(_lt_state "$LT_F") $((_ltn1 - _ltn0))" "current 0"
# Behind and owing at once: two rows, behind first. origin/main moved the way
# it does on felix-home, by an engine landing that bumped the version and
# rewrote red.tsv, so a two-dot diff against it names both files as changed
# and would read the branch as having paid what it owes.
_lt_mkbo() {  # <dir> <proj>: origin/main carries the seven rows for projects/<proj>; feat changes x.sh and is behind
  mkdir -p "$1" "$MEM/$2" && ( _fx_cd "$1" && git init -q -b main && git config user.email t@t && git config user.name t \
    && mkdir -p "projects/$2" engine/.claude-plugin engine/harness/tests engine/harness/lib docs \
    && cp "$LT_SEVEN" "projects/$2/land.tsv" && printf '{ "version": "0.0.1" }\n' > engine/.claude-plugin/plugin.json \
    && printf 'base\n' > engine/harness/tests/red.tsv && printf 'x\n' > engine/harness/lib/x.sh && printf 'a\n' > docs/a.md \
    && git add -A && git commit -qm c1 \
    && git checkout -q -b feat && printf 'y\n' > engine/harness/lib/x.sh && git commit -qam work \
    && git checkout -q --detach main && printf 'b\n' > docs/b.md \
    && printf '{ "version": "0.0.2" }\n' > engine/.claude-plugin/plugin.json && printf 'main\n' > engine/harness/tests/red.tsv \
    && git add -A && git commit -qm c2 \
    && git update-ref refs/remotes/origin/main HEAD && git checkout -q feat ) >/dev/null 2>&1; }
_lt_mkbo "$TMP/lt-both" ltbo; LT_BO="$(cd "$TMP/lt-both" && pwd -P)"
is  "the behind-and-owing fixture is behind origin/main and changes engine/harness/lib/x.sh alone since the merge-base" \
    "$(_lt_state "$LT_BO") $(git -C "$LT_BO" diff --name-only refs/remotes/origin/main...HEAD 2>/dev/null)" "behind engine/harness/lib/x.sh"
is  "while a two-dot diff against origin/main also names plugin.json and red.tsv, which main's own landing changed" \
    "$(git -C "$LT_BO" diff --name-only refs/remotes/origin/main HEAD 2>/dev/null | tr '\n' ' ')" \
    "docs/b.md engine/.claude-plugin/plugin.json engine/harness/lib/x.sh engine/harness/tests/red.tsv "
_ltn0="$(_lt_nsaid ltbo)"; _lt_wr "$LT_BO/projects/ltbo" "$LT_BO" lt-s1 0 >/dev/null
is  "a branch both behind and owing adds two rows, behind first and then owed, or one of the two reports would be lost" \
    "$(_lt_said ltbo | tail -n +"$((_ltn0 + 1))" | cut -f5 | awk -F': ' '{ printf "%s%s", s, $2; s = " " }')" "behind owed"
has "and the owed row names the version and the record, which main changed and the branch did not, or a behind branch would read as having paid them" \
    "$(_lt_said ltbo | tail -1 | cut -f5)" \
    ": owed: engine/.claude-plugin/plugin.json (version-above on engine/); engine/harness/tests/red.tsv (rerun on engine/) at HEAD "
# A row the schema refuses at the base is not a clean table, and it is not a
# debt either: it is said on its own row, by line, never folded into owed.
LT_RF="$TMP/lt-refused"; mkdir -p "$LT_RF" "$MEM/ltrf"
( _fx_cd "$LT_RF" && git init -q -b main && git config user.email t@t && git config user.name t \
  && mkdir -p projects/ltrf docs && printf 'a\n' > docs/a.md \
  && { printf '# a table with one row the schema refuses\n'; _lt_row a.txt version-above - -
       _lt_row projects/p/risk.tsv version-above - -; } > projects/ltrf/land.tsv \
  && git add -A && git commit -qm c1 && git update-ref refs/remotes/origin/main HEAD \
  && git checkout -q -b feat && printf 'b\n' >> docs/a.md && git commit -qam docs ) >/dev/null 2>&1
LT_RF="$(cd "$LT_RF" && pwd -P)"
_ltn0="$(_lt_nsaid ltrf)"; _lt_wr "$LT_RF/projects/ltrf" "$LT_RF" lt-s1 0 >/dev/null
is  "a row the schema refuses at the base is reported on a land-table row of its own, by line and reason, and in no owed row, or a broken table would pass for a clean one or read as a debt" \
    "$(_lt_said ltrf | tail -n +"$((_ltn0 + 1))" | cut -f5)" "feat: land-table: line 3 refused: protected at HEAD $(git -C "$LT_RF" rev-parse -q --verify HEAD 2>/dev/null)\\n"

# At the merge boundary, called the way _blk calls it. The two rows are the
# only difference a real attempt makes; the blocker lines, byte for byte, and
# the exit status are what they were.
_lt_blk() {  # <proj dir> <root> <stdout file> <FELIX_MERGE_DRY_RUN: 1 or 0>: felix_merge_blockers' status
  ( cd "$2" && FELIX_MERGE_DRY_RUN="$4" && export FELIX_MERGE_DRY_RUN
    . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
    . "$FROOT/harness/lib/evidence.sh"; . "$FROOT/harness/lib/verify.sh"
    felix_merge_blockers "$1" origin/main "$2" "$FROOT" > "$3" 2>/dev/null; echo "$?" ) </dev/null 2>/dev/null; }
_ltn0="$(_lt_nsaid ltbo)"; _lta0="$(_lt_nall ltbo)"; _ltbr="$(_lt_blk "$LT_BO/projects/ltbo" "$LT_BO" "$TMP/lt-blk-real" 0)"
_ltn1="$(_lt_nsaid ltbo)"; _lta1="$(_lt_nall ltbo)"; _ltbd="$(_lt_blk "$LT_BO/projects/ltbo" "$LT_BO" "$TMP/lt-blk-dry" 1)"
_ltn2="$(_lt_nsaid ltbo)"; _lta2="$(_lt_nall ltbo)"
is  "felix_merge_blockers on a behind and owing branch writes both would-refuse rows and no row of another kind on a real attempt, and nothing on a dry run, or the boundary never reports them or reports more than them" \
    "$((_ltn1 - _ltn0)) $((_lta1 - _lta0)) $((_ltn2 - _ltn1)) $((_lta2 - _lta1))" "2 2 0 0"
is  "while it prints no line whose kind is behind or owed, or cmd_merge would refuse on a check that is only meant to report" \
    "$(awk -F'\t' '$1 == "behind" || $1 == "owed"' "$TMP/lt-blk-real" 2>/dev/null)" ""
is  "and prints byte for byte what the dry run printed, its not-green blocker included, or reporting would change what blocks" \
    "$(grep -q '^not-green' "$TMP/lt-blk-real" 2>/dev/null && cmp -s "$TMP/lt-blk-real" "$TMP/lt-blk-dry" && echo same || echo differs)" "same"
is  "and exits 0 on both, or the judge would take its own library for one that could not be loaded" \
    "$_ltbr $_ltbd" "0 0"

# The judge's own shell: set -u, and only the six libraries it sources. The
# rows prove escape.sh brings land-table.sh with it, and that brings say.sh
# (the row is written) and reads the table by its own scan in that shell,
# which needs nothing from table.sh and nothing from the environment.
_lt_mkbo "$TMP/lt-judge" ltjd; LT_JD="$(cd "$TMP/lt-judge" && pwd -P)"
LT_MARK="$TMP/lt-judge.reached"
_lt_judge() {  # <stdout file> [redefine] [FELIX_MERGE_DRY_RUN: 0 (the default), 1, or - for unset] [FELIX_TABLE_SKIP] [stub]: felix_merge_blockers' status in the judge's shell and load order
  ( cd "$LT_JD" && if [ "${3:-0}" = - ]; then unset FELIX_MERGE_DRY_RUN; else FELIX_MERGE_DRY_RUN="${3:-0}"; export FELIX_MERGE_DRY_RUN; fi
    if [ -n "${4:-}" ]; then FELIX_TABLE_SKIP="$4"; export FELIX_TABLE_SKIP; fi
    if [ -n "${5:-}" ]; then felix_land_rows() { :; }; felix_say() { :; }; export -f felix_land_rows felix_say; fi
    CLAUDE_CODE_SESSION_ID=lt-judge LT_REDEF="${2:-}" LT_MARK="$LT_MARK" \
    bash -c 'set -uo pipefail; k="$1"
      for f in resolve verify review classify evidence escape; do . "$k/lib/$f.sh" 2>/dev/null || exit 3; done
      if [ -n "$LT_REDEF" ]; then felix_land_would_refuse() { : > "$LT_MARK"; : "$lt_never_set"; }; fi
      felix_merge_blockers "$2" "$3" "$4" "$5"' _ "$FROOT/harness" "$LT_JD/projects/ltjd" origin/main "$LT_JD" "$FROOT" \
      > "$1" 2>/dev/null; echo "$?" ) </dev/null; }
_ltn0="$(_lt_nsaid ltjd)"; _ltjr="$(_lt_judge "$TMP/lt-judge-control")"
is  "the judge's own shell still judges a behind and owing branch and exits 0, or the merge boundary would die on the new library" \
    "$_ltjr" "0"
has "and writes the behind row there, or escape.sh does not bring land-table.sh and say.sh into the judge's shell" \
    "$(_lt_said ltjd | tail -n +"$((_ltn0 + 1))" | cut -f5)" "feat: behind: origin/main "
has "and the owed row, or land-table.sh cannot read the table in the judge's shell" \
    "$(_lt_said ltjd | tail -n +"$((_ltn0 + 1))" | cut -f5)" \
    ": owed: engine/.claude-plugin/plugin.json (version-above on engine/); engine/harness/tests/red.tsv (rerun on engine/) at HEAD "
# The session's environment reaches the judge's child shell: a skip pattern
# exported there must not change which rows the judge reads.
_ltn0="$(_lt_nsaid ltjd)"; _lt_judge "$TMP/lt-judge-skip" '' 0 '.' >/dev/null
has "and with FELIX_TABLE_SKIP exported as a pattern every line matches, the judge's owed row is the same, or a session could empty the table the judge reads" \
    "$(_lt_said ltjd | tail -n +"$((_ltn0 + 1))" | cut -f5)" \
    ": owed: engine/.claude-plugin/plugin.json (version-above on engine/); engine/harness/tests/red.tsv (rerun on engine/) at HEAD "
# Functions travel the same way: the child shell imports what the session
# exported, so a library loaded only when its function is missing would give
# way to the session's own felix_land_rows and felix_say.
_ltn0="$(_lt_nsaid ltjd)"; _lt_judge "$TMP/lt-judge-stub" '' 0 '' stub >/dev/null
is  "and with felix_land_rows and felix_say exported by the session as functions that do nothing, the judge still writes both rows, or a session could stand in for the library" \
    "$(_lt_said ltjd | tail -n +"$((_ltn0 + 1))" | cut -f5 | awk -F': ' '{ printf "%s%s", s, $2; s = " " }')" "behind owed"
# Self-governed, a dry run reaches the report only through this environment:
# FELIX_MERGE_DRY_RUN=1, or nothing at all from a CLI older than the library.
_ltn0="$(_lt_nsaid ltjd)"; _ltjd1="$(_lt_judge "$TMP/lt-judge-dry1" '' 1)"; _ltn1="$(_lt_nsaid ltjd)"
_ltjdu="$(_lt_judge "$TMP/lt-judge-dryu" '' -)"; _ltn2="$(_lt_nsaid ltjd)"
_ltjd0="$(_lt_judge "$TMP/lt-judge-dry0" '' 0)"; _ltn3="$(_lt_nsaid ltjd)"
is  "in the judge's shell a dry run and an unset variable write no row, and a real attempt writes two, each exiting 0, or a self-governed dry run would write the report" \
    "$_ltjd1 $((_ltn1 - _ltn0)) $_ltjdu $((_ltn2 - _ltn1)) $_ltjd0 $((_ltn3 - _ltn2))" "0 0 0 0 0 2"
_ltn0="$(_lt_nsaid ltjd)"; _ltjr="$(_lt_judge "$TMP/lt-judge-broken" 1)"; _ltn1="$(_lt_nsaid ltjd)"
is  "a report writer that dies on an unset variable is still reached from the judge's shell, or the containment asserted next is never exercised" \
    "$([ -e "$LT_MARK" ] && echo reached || echo never)" "reached"
is  "and the judge still exits 0 with stdout byte for byte the control's and no row written, or a failing report could fail a merge" \
    "$_ltjr $(cmp -s "$TMP/lt-judge-control" "$TMP/lt-judge-broken" && echo same || echo differs) $((_ltn1 - _ltn0))" "0 same 0"

# Through the real CLI, on a governed product checkout that is behind and has
# no gate receipt, so it stops at not-green before any gh call.
_lt_blockerish() { printf '%s\n' "$1" | awk '{ t = $1; sub(/^[-*]+/, "", t); sub(/:$/, "", t) }
                                             t == "behind" || t == "owed" || index($0, "behind\t") || index($0, "owed\t")'; }
LT_P="$TMP/lt-product"; mkdir -p "$LT_P"
( _fx_cd "$LT_P" && git init -q -b main && git config user.email t@t && git config user.name t \
  && printf 'widget\n' > .felix && printf 'contents\n' > WIDGET.txt && git add -A && git commit -qm c1 \
  && git checkout -q -b feat && printf 'work\n' > work.txt && git add -A && git commit -qm c3 \
  && git checkout -q --detach main && printf 'moved\n' > moved.txt && git add -A && git commit -qm c2 \
  && git update-ref refs/remotes/origin/main HEAD && git checkout -q feat ) >/dev/null 2>&1
LT_P="$(cd "$LT_P" && pwd -P)"
is  "the product checkout is bound to the widget, tracks no plugin.json and is behind origin/main" \
    "$(cat "$LT_P/.felix" 2>/dev/null) $(git -C "$LT_P" ls-files engine/.claude-plugin/plugin.json 2>/dev/null | awk 'END { print NR }') $(_lt_state "$LT_P")" \
    "widget 0 behind"
_ltn0="$(_lt_nsaid widget)"
_ltout="$( cd "$LT_P" && unset FELIX_MERGE_DRY_RUN && "$FELIX" merge --base main 2>&1 )"; _ltrc=$?
_ltn1="$(_lt_nsaid widget)"
is  "a real felix merge on a behind product checkout with no receipt still refuses with exit 3, or reporting changed how it lands" \
    "$_ltrc" "3"
has "and still names the not-green tree, or reporting displaced the blocker that stops it" "$_ltout" "not-green"
is  "and shows no behind or owed blocker, or a report-only check would be read as a refusal" \
    "$(_lt_blockerish "$_ltout")" ""
is  "while it adds exactly one would-refuse row to the widget's says.log, or cmd_merge never reaches the report" \
    "$((_ltn1 - _ltn0))" "1"
# 2026-10-18 (judge refs): felix merge hands the report the full name of its base.
has "saying the branch is behind refs/remotes/origin/main, or the CLI hands the report a base other than the one it compared" \
    "$(_lt_said widget | tail -1 | cut -f5)" ": behind: refs/remotes/origin/main "
_ltn0="$(_lt_nsaid widget)"; ( cd "$LT_P" && "$FELIX" merge --base main --dry-run >/dev/null 2>&1 ); _ltn1="$(_lt_nsaid widget)"
is  "a felix merge --dry-run on the same checkout adds no would-refuse row, or cmd_merge does not tell the report that a dry run is one" \
    "$((_ltn1 - _ltn0))" "0"
_ltn0="$(_lt_nsaid widget)"; ( cd "$LT_P" && FELIX_MERGE_DRY_RUN=1 "$FELIX" merge --base main >/dev/null 2>&1 ); _ltn1="$(_lt_nsaid widget)"
is  "and a real attempt still writes its row when the session exported FELIX_MERGE_DRY_RUN=1, or a session could silence the report by its environment" \
    "$((_ltn1 - _ltn0))" "1"
( _fx_cd "$LT_P" && git merge -q --no-edit refs/remotes/origin/main ) >/dev/null 2>&1
is  "the product checkout holds origin/main once it has merged it" "$(_lt_state "$LT_P")" "current"
_ltn0="$(_lt_nsaid widget)"
_ltout="$( cd "$LT_P" && unset FELIX_MERGE_DRY_RUN && "$FELIX" merge --base main 2>&1 )"; _ltrc=$?
_ltn1="$(_lt_nsaid widget)"
is  "and a real attempt there still refuses on the not-green tree and adds no would-refuse row, or every current branch would be reported behind" \
    "$_ltrc $((_ltn1 - _ltn0))" "3 0"

# -------------------------------------------------------- the table itself ----
# felix-home's own table, where Felix's own repository keeps it. The red run
# stands in the base's tree, which has projects/felix/project.json and no
# land.tsv, and fails these; a tree that is not Felix's own skips them.
LT_HOME="$(cd "$REAL_HARNESS/../.." && pwd)"
LT_FL="$LT_HOME/projects/felix/land.tsv"
_lth1="felix-home's land.tsv holds the design's seven rows, by the hash of its data rows, or the table the founder arms is not the one designed"
_lth2="and its data rows are those seven, verbatim and in order, so a drifted row is shown by name and not only by a hash"
_lth3="and felix_land_malformed_in refuses none of them and exits 0, or the home's own table would bind nothing"
_lth4="and the table validator accepts it under its schemas.tsv row, or schema-check would fail the gate"
if [ -f "$LT_HOME/projects/felix/project.json" ]; then
  if [ -f "$LT_FL" ]; then
    is "$_lth1" "$( ( . "$REAL_HARNESS/lib/table.sh" 2>/dev/null; felix_table_rows "$LT_FL" ) 2>/dev/null | git hash-object --stdin )" \
       "3dc2dcb4612f4bb0226ef5a5b9f30ba173619d60"
    is "$_lth2" "$( ( . "$REAL_HARNESS/lib/table.sh" 2>/dev/null; felix_table_rows "$LT_FL" ) 2>/dev/null )" "$(cat "$LT_SEVEN")"
    is "$_lth3" "$(_lt_verdict "$LT_FL")" "rows=7 refused= rc=0"
    is "$_lth4" "$( ( . "$REAL_HARNESS/lib/table.sh" 2>/dev/null
                      felix_table_check "$REAL_HARNESS/templates/schemas.tsv" "$LT_FL" >/dev/null 2>&1; echo $? ) )" "0"
  else
    for _ltn in "$_lth1" "$_lth2" "$_lth3" "$_lth4"; do bad "$_ltn" "no projects/felix/land.tsv in Felix's own repository"; done
  fi
else
  for _ltn in "$_lth1" "$_lth2" "$_lth3" "$_lth4"; do skip "$_ltn" "not Felix's own repository: no projects/felix/project.json"; done
fi
is  "schemas.tsv declares land.tsv a tree table of path, kind, trigger and arg that may be empty, or every land.tsv would be an undeclared table" \
    "$( ( . "$REAL_HARNESS/lib/table.sh" 2>/dev/null; felix_table_schema "$REAL_HARNESS/templates/schemas.tsv" land.tsv ) 2>/dev/null )" \
    "$(printf 'land.tsv\ttree\tpath kind trigger arg\tallowed')"
mkdir -p "$TMP/lt-schema"; { cat "$LT_SEVEN"; printf 'a.txt\tversion-above\t-\n'; } > "$TMP/lt-schema/land.tsv"
is  "and the validator refuses a three-cell row in a land table as cells, exit 1, or schema-check would pass a row the reader splits wrong" \
    "$( ( . "$REAL_HARNESS/lib/table.sh" 2>/dev/null
          _lto="$(felix_table_check "$REAL_HARNESS/templates/schemas.tsv" "$TMP/lt-schema/land.tsv" 2>/dev/null)"; _ltr=$?
          printf '%s|%s' "$_ltr" "$(printf '%s\n' "$_lto" | cut -f2 | LC_ALL=C sort -u | awk 'NF { printf "%s%s", s, $0; s = " " }')" ) )" "1|cells"
# The gate holds a land table to the schema rule as well as to its cells: a
# row the reader would refuse at landing never merges green. The fixture's
# own schemas.tsv declares land.tsv, so only the rule itself can fail it.
LT_SC="$TMP/lt-schemacheck"; mkdir -p "$LT_SC/engine/harness/templates" "$LT_SC/projects/p"
printf 'schemas.tsv\ttree\ttable lives columns empty\trefused\nland.tsv\ttree\tpath kind trigger arg\tallowed\n' \
  > "$LT_SC/engine/harness/templates/schemas.tsv"
cp "$LT_SEVEN" "$LT_SC/projects/p/land.tsv"
( _fx_cd "$LT_SC" && git init -q -b main && git add -A && git -c user.name=t -c user.email=t@t commit -qm seed ) >/dev/null 2>&1
_lt_sc() { ( cd "$LT_SC" && "$REAL_HARNESS/bin/schema-check" 2>&1; echo "rc=$?" ) </dev/null; }
_ltsc0="$(_lt_sc)"
_lt_row projects/p/risk.tsv version-above - - >> "$LT_SC/projects/p/land.tsv"
_ltsc1="$(_lt_sc)"
is  "schema-check passes a tree whose land table holds felix-home's seven rows, and fails one whose resolver row binds risk.tsv, or a row the reader refuses would merge green" \
    "${_ltsc0##*rc=} ${_ltsc1##*rc=}" "0 1"
has "naming the table's line and the rule it breaks" "$_ltsc1" "projects/p/land.tsv:8	land-protected	escape-table"
# Invariant 1: the kinds are constants, and felix-home's rows live in its own
# table and nowhere in the engine. The first is red while the library does not
# exist; the second is its control.
if [ -f "$REAL_HARNESS/lib/land-table.sh" ]; then
  _ltg="$(grep -Fxf "$LT_SEVEN" "$REAL_HARNESS/lib/land-table.sh" 2>/dev/null)"
else
  _ltg="(no lib/land-table.sh)"
fi
is  "lib/land-table.sh exists and no line of it is one of felix-home's rows, or the engine would name a project's recipe" "$_ltg" ""
is  "and no file among the engine's libraries, CLI, hooks or templates carries one of those rows either, or a project's recipe would live in the engine" \
    "$(grep -rlFxf "$LT_SEVEN" "$REAL_HARNESS/lib" "$REAL_HARNESS/felix" "$REAL_HARNESS/hooks" "$REAL_HARNESS/templates" 2>/dev/null)" ""

