# ----------------------------------------------- schema-check, the gate's half ---
# The command the gate runs. The fixture is an invented tree with its own small
# schema, for the reason the executable-check fixture gives: its counts are
# numbers the assertions can name.
printf '\nschema-check: every table declared, every row a row\n'
SCX="$TMP/schema-check"
mkdir -p "$SCX/engine/harness/templates" "$SCX/data" "$SCX/deep/nested"
printf '# table\tlives\tcolumns\tempty\nschemas.tsv\ttree\ttable lives columns empty\trefused\nalpha.tsv\ttree\ta b c?\tallowed\nbeta.tsv\ttree\tx y\trefused\nupkeep.log\ttree\tname epoch\tallowed\ngamma.log\tmemory\tp q\tallowed\n' \
  > "$SCX/engine/harness/templates/schemas.tsv"
printf '# alpha\none\ttwo\none\ttwo\tthree\n' > "$SCX/data/alpha.tsv"
printf 'x\ty\n' > "$SCX/data/beta.tsv"
printf 'ignored.tsv\n' > "$SCX/.gitignore"
( _fx_cd "$SCX" && git init -q -b main && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm seed ) >/dev/null 2>&1
SCX="$(cd "$SCX" && pwd -P)"
_scx()   { ( cd "$1" && "$REAL_HARNESS/bin/schema-check" 2>&1; echo "rc=$?" ); }
_scxrc() { printf '%s' "${1##*rc=}"; }
_scxc()  { ( _fx_cd "$SCX" && git add -A && git -c user.name=t -c user.email=t@t commit -qm case ) >/dev/null 2>&1; }

out="$(_scx "$SCX")"
is  "a tree whose every table is declared and accepted exits 0" "$(_scxrc "$out")" "0"
has "and says how many tables it read" "$out" "3 table(s)"
# Enumerated from git, never from the schema: the count moving is the evidence.
printf 'd\te\n' > "$SCX/data/delta.tsv"; _scxc
out="$(_scx "$SCX")"
is  "a table added today with no schema row fails, where a list of known tables saw nothing" "$(_scxrc "$out")" "1"
has "naming the table and the missing row" "$out" "data/delta.tsv:-	no-schema"
printf 'delta.tsv\ttree\td e\tallowed\n' >> "$SCX/engine/harness/templates/schemas.tsv"; _scxc
out="$(_scx "$SCX")"
is  "and its row, added in the same tree, clears it" "$(_scxrc "$out")" "0"
has "with the count moved by one" "$out" "4 table(s)"
# Not yet added is still in the tree the gate certifies.
printf 'f\tg\n' > "$SCX/data/fresh.tsv"
out="$(_scx "$SCX")"
is  "a table created and never added is checked too, and fails with no row" "$(_scxrc "$out")" "1"
has "naming it" "$out" "data/fresh.tsv:-	no-schema"
rm -f "$SCX/data/fresh.tsv"
printf 'f\tg\n' > "$SCX/data/ignored.tsv"
is  "while one the tree ignores is not the tree's" "$(_scxrc "$(_scx "$SCX")")" "0"
rm -f "$SCX/data/ignored.tsv"
# A table under another name is found by the name its row gives it.
printf 'graphify\t1789106119\t2026-09-10\n' > "$SCX/data/upkeep.log"; _scxc
out="$(_scx "$SCX")"
is  "a table not named .tsv, declared by its basename, is read and here refused for a third cell" "$(_scxrc "$out")" "1"
has "naming the row" "$out" "data/upkeep.log:1	cells"
printf 'graphify\t1789106119\n' > "$SCX/data/upkeep.log"; _scxc
is  "and accepted once its rows fit" "$(_scxrc "$(_scx "$SCX")")" "0"
# A table whose row says emptiness is refused, emptied.
printf '# nothing here\n' > "$SCX/data/beta.tsv"; _scxc
out="$(_scx "$SCX")"
is  "a table emptied whose row refuses emptiness fails" "$(_scxrc "$out")" "1"
has "and says it is empty" "$out" "data/beta.tsv:-	empty"
printf 'x\ty\n' > "$SCX/data/beta.tsv"; _scxc
# The deny table's hole, in miniature: the last row, its newline gone.
printf 'one\ttwo' > "$SCX/data/alpha.tsv"; _scxc
out="$(_scx "$SCX")"
is  "a table whose last row lost its newline fails" "$(_scxrc "$out")" "1"
has "and names the file" "$out" "data/alpha.tsv:-	no-final-newline"
printf 'one\ttwo\n' > "$SCX/data/alpha.tsv"; _scxc
# A memory store in the tree, whatever it is called.
printf 'p\tq\n' > "$SCX/data/gamma.log"; _scxc
out="$(_scx "$SCX")"
is  "a file whose row says it lives in memory fails when it is in the tree" "$(_scxrc "$out")" "1"
has "and says so" "$out" "data/gamma.log:-	memory-tracked"
( _fx_cd "$SCX" && git rm -q data/gamma.log ) >/dev/null 2>&1; _scxc
# A link, a tracked table gone from the working tree, and a name git quotes.
mkdir -p "$SCX/data2"; ln -s ../data/alpha.tsv "$SCX/data2/alpha.tsv"; _scxc
has "a table that is a link fails" "$(_scx "$SCX")" "data2/alpha.tsv:-	symlink"
( _fx_cd "$SCX" && git rm -q data2/alpha.tsv ) >/dev/null 2>&1; _scxc
rm -f "$SCX/data/beta.tsv"
has "a tracked table missing from the working tree fails" "$(_scx "$SCX")" "data/beta.tsv:-	missing"
( _fx_cd "$SCX" && git checkout -q -- data/beta.tsv ) >/dev/null 2>&1
printf 'x\ty\n' > "$SCX/data/tab	name.tsv"
has "and a table whose name git quotes is one no reader opens by that name" "$(_scx "$SCX")" "unexaminable"
rm -f "$SCX/data/tab	name.tsv"
# Names that awk takes for an assignment or for standard input, and tail for
# an option: handed over as operands, each skipped the file it named in
# silence. A blind adversary found all three; the files now go in on stdin.
mkdir -p "$SCX/k=v" "$SCX/-d"
printf 'x\t\ty\n' > "$SCX/k=v/alpha.tsv"; printf 'one\ttwo' > "$SCX/-d/alpha.tsv"; _scxc
out="$(_scx "$SCX")"
has "a table under a directory named like an awk assignment is read, and refused" "$out" "k=v/alpha.tsv:1	empty-cell"
has "and one under a directory named like an option keeps its final-newline check" "$out" "-d/alpha.tsv:-	no-final-newline"
( _fx_cd "$SCX" && git rm -rq -- "k=v" "-d" ) >/dev/null 2>&1; _scxc
is  "and with both gone the tree is clean again" "$(_scxrc "$(_scx "$SCX")")" "0"
chmod 000 "$SCX/engine/harness/templates/schemas.tsv"
if [ -r "$SCX/engine/harness/templates/schemas.tsv" ]; then
  skip "a schemas.tsv it cannot read is cannot-examine, exit 2, not every table undeclared" "running as a user every file is readable to"
else
  is "a schemas.tsv it cannot read is cannot-examine, exit 2, not every table undeclared" "$(_scxrc "$(_scx "$SCX")")" "2"
fi
chmod 644 "$SCX/engine/harness/templates/schemas.tsv"

# The reverse gap: a tree row nothing here is named is said, and does not fail.
( _fx_cd "$SCX" && git rm -q data/delta.tsv ) >/dev/null 2>&1; _scxc
out="$(_scx "$SCX")"
is  "a tree row no table matches is not a failure: some tables are absent until written" "$(_scxrc "$out")" "0"
has "and it is said" "$out" "note  delta.tsv is declared and nothing here is named that"
# A malformed schema row is the schema check's own refusal, not a skipped row.
printf 'eps.tsv\tsomewhere\tu v\tallowed\n' >> "$SCX/engine/harness/templates/schemas.tsv"; _scxc
out="$(_scx "$SCX")"
is  "a schema row with a place that is neither tree nor memory fails" "$(_scxrc "$out")" "1"
has "as the schema's own refusal" "$out" "schema-lives"
awk -F'\t' '$1 != "eps.tsv"' "$SCX/engine/harness/templates/schemas.tsv" > "$SCX/s" \
  && mv "$SCX/s" "$SCX/engine/harness/templates/schemas.tsv"; _scxc
is  "restored, it exits 0 again" "$(_scxrc "$(_scx "$SCX")")" "0"
is  "and from a nested subdirectory the verdict is unchanged" "$(_scxrc "$(_scx "$SCX/deep/nested")")" "0"

# Could not look is not nothing wrong.
is  "outside a git repository it cannot look, exit 2" "$(_scxrc "$(_scx "$TMP")")" "2"
SCN="$TMP/schema-check-no-schema"; mkdir -p "$SCN"
( _fx_cd "$SCN" && printf 'a\tb\n' > t.tsv && git init -q -b main && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm s ) >/dev/null 2>&1
is  "a checkout with tables and no schemas.tsv cannot look either, exit 2" "$(_scxrc "$(_scx "$SCN")")" "2"
SCZ="$TMP/schema-check-no-tables"; mkdir -p "$SCZ/engine/harness/templates"
printf '# no table here\n' > "$SCZ/README"
printf 'schemas.tsv\ttree\ttable lives columns empty\trefused\n' > "$SCZ/engine/harness/templates/schemas.tsv"
( _fx_cd "$SCZ" && printf 'engine/harness/templates/schemas.tsv\n' > .gitignore && git init -q -b main && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm s ) >/dev/null 2>&1
is  "and one that holds no table at all is emptiness, not an all clear" "$(_scxrc "$(_scx "$SCZ")")" "2"

# The real tree, and the gate that runs this on it.
_engine_manifest_build
if [ -n "$TBROOT" ] && [ -f "$TBROOT/engine/harness/templates/schemas.tsv" ]; then
  is  "this repository's every table is declared and accepted" "$(_scxrc "$(_scx "$TBROOT")")" "0"
else
  skip "this repository's every table is declared and accepted" "no git checkout with a schemas.tsv above this harness"
fi
SCGATE="$REAL_HARNESS/../../projects/felix/gate.sh"
if [ -f "$SCGATE" ]; then
  case "$(cat "$SCGATE")" in
    *'engine/harness/bin/schema-check 2>&1)"; then'*'pass schema'*'fail schema'*'else'*'fail schema'*'no executable engine/harness/bin/schema-check'*)
      ok  "felix's own gate runs schema-check, fails on anything but exit 0, and fails when it is gone" ;;
    *) bad "felix's own gate runs schema-check, fails on anything but exit 0, and fails when it is gone" "no such schema block in projects/felix/gate.sh" ;;
  esac
  # A count row whose pattern matches nothing can never fire: the checker's own
  # code is guarded only if the pattern counts what it removes.
  _scrisk="$REAL_HARNESS/../../projects/felix/risk.tsv"
  _scpat() { awk -F'\t' -v p="$1" '$3 == p { sub(/^count:/, "", $6); print $6 }' "$_scrisk" 2>/dev/null; }
  _sctb="$(grep -cE "$(_scpat '^engine/harness/lib/table\.sh$')" "$REAL_HARNESS/lib/table.sh" 2>/dev/null)"
  _scsc="$(grep -cE "$(_scpat '^engine/harness/bin/schema-check$')" "$REAL_HARNESS/bin/schema-check" 2>/dev/null)"
  [ "${_sctb:-0}" -ge 15 ] && [ "${_scsc:-0}" -ge 5 ] \
    && ok  "felix's risk table counts the refusals in table.sh and schema-check, so removing one escapes" \
    || bad "felix's risk table counts the refusals in table.sh and schema-check, so removing one escapes" \
           "counted ${_sctb:-0} in table.sh and ${_scsc:-0} in schema-check"
  is  "and felix's qualification table declares every control for the schema checker" \
      "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
          felix_qualify_missing_controls "$REAL_HARNESS/../../projects/felix" schema | tr '\n' ' ' )" ""
else
  for a in "felix's own gate runs schema-check, fails on anything but exit 0, and fails when it is gone" \
           "felix's risk table counts the refusals in table.sh and schema-check, so removing one escapes" \
           "and felix's qualification table declares every control for the schema checker"; do
    skip "$a" "no projects/felix/gate.sh beside this harness"; done
fi

# The schema table judges every other table's shape, so it is an enforcing
# table, named by its path: a row removed or loosened in place fires verifier,
# a row added does not, and a product's own schemas.tsv is not the engine's.
_scl() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/escape.sh"
           _felix_escape_listed "$1" "$FELIX_ESCAPE_TABLES" && echo listed || echo not ); }
is  "the engine's schemas.tsv is one of the tables whose shrinkage escapes" \
    "$(_scl engine/harness/templates/schemas.tsv)" "listed"
is  "and a product repository's file of the same name is not" "$(_scl db/schemas.tsv)" "not"
is  "while a basename entry still matches in any directory" "$(_scl projects/any/risk.tsv)" "listed"
_scbase="$(git -C "$SCX" rev-parse HEAD)"
sed 's/^alpha\.tsv	tree	a b c?/alpha.tsv	tree	a b? c?/' "$SCX/engine/harness/templates/schemas.tsv" > "$SCX/s" \
  && mv "$SCX/s" "$SCX/engine/harness/templates/schemas.tsv"; _scxc
is  "a schema row loosened in place is a shrink the escape check sees" \
    "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/escape.sh"
        _felix_escape_shrank "$SCX" "$_scbase" engine/harness/templates/schemas.tsv && echo fires || echo quiet )" "fires"
_scbase="$(git -C "$SCX" rev-parse HEAD)"
printf '# a comment reworded for free\nzeta.tsv\ttree\tu v\tallowed\n' >> "$SCX/engine/harness/templates/schemas.tsv"; _scxc
is  "while a row added for a new table, and a comment, are free" \
    "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/escape.sh"
        _felix_escape_shrank "$SCX" "$_scbase" engine/harness/templates/schemas.tsv && echo fires || echo quiet )" "quiet"

printf '\nFelix installs what it read, or says which one it has\n'
# `felix discover` fetches a candidate at its pinned sha into a scratch
# directory and READS it there to score a tier. `claude plugin install` later
# fetches its own copy. Nothing compared the two, so "Felix installs what it
# has read" was a sentence and not a fact. These assertions are about the
# comparison: a digest taken from the copy that was read, carried in the
# discovery cache, and checked afterwards against the copy on disk.
#
# Everything below lives under $TMP and goes with the suite's EXIT trap; the
# block writes nothing into $FROOT, so nothing here needs keeping and
# restoring.
_dg()     { ( . "$FROOT/harness/lib/discover.sh"; felix_discover_digest "$@" ); }
_dgrc()   { ( . "$FROOT/harness/lib/discover.sh"; felix_discover_digest "$@" >/dev/null 2>&1; echo $? ); }
_dgstamp(){ ( . "$FROOT/harness/lib/discover.sh"; _felix_discover_stamp_line "" ); }
# A plugin copy: a manifest, a command, an executable, and a symlink — the four
# things a digest that only hashed file contents would get wrong.
_mkplug() { mkdir -p "$1/commands"
            printf 'name: sample\n'        > "$1/plugin.json"
            printf 'do the thing\n'        > "$1/commands/go.md"
            printf '#!/bin/sh\necho hi\n'  > "$1/run.sh"; chmod 755 "$1/run.sh"
            ln -sfn commands/go.md "$1/link"; }

DIG="$TMP/digest-copies"; mkdir -p "$DIG"
_mkplug "$DIG/read"; _mkplug "$DIG/installed"
dread="$(_dg "$DIG/read")"
[ -n "$dread" ] \
  && ok  "a copy with files in it digests to something" \
  || bad "a copy with files in it digests to something" "printed nothing"
is  "and exits 0 when it has a digest to print" "$(_dgrc "$DIG/read")" "0"
is  "two byte-identical copies at two different paths digest the same" \
    "$(_dg "$DIG/installed")" "$dread"

# One byte, same length, inside one file.
printf 'do the thang\n' > "$DIG/installed/commands/go.md"
case "$(_dg "$DIG/installed")" in
  "$dread") bad "one byte changed inside one file changes the digest" "unchanged" ;;
  *)        ok  "one byte changed inside one file changes the digest" ;;
esac
printf 'do the thing\n' > "$DIG/installed/commands/go.md"
is  "and putting the byte back puts the digest back" "$(_dg "$DIG/installed")" "$dread"

printf 'surprise\n' > "$DIG/installed/extra.md"
case "$(_dg "$DIG/installed")" in
  "$dread") bad "adding a file changes the digest" "unchanged" ;;
  *)        ok  "adding a file changes the digest" ;;
esac
rm -f "$DIG/installed/extra.md"
is  "and removing that file restores it" "$(_dg "$DIG/installed")" "$dread"

# The executable bit is the difference between a plugin that runs and one that
# does not, and it moves no bytes.
chmod 644 "$DIG/installed/run.sh"
case "$(_dg "$DIG/installed")" in
  "$dread") bad "flipping a file's executable bit changes the digest" "unchanged" ;;
  *)        ok  "flipping a file's executable bit changes the digest" ;;
esac
is  "with the file's contents untouched" \
    "$(cmp -s "$DIG/read/run.sh" "$DIG/installed/run.sh" && echo identical)" "identical"
chmod 755 "$DIG/installed/run.sh"
is  "and flipping it back restores the digest" "$(_dg "$DIG/installed")" "$dread"

ln -sfn plugin.json "$DIG/installed/link"
case "$(_dg "$DIG/installed")" in
  "$dread") bad "repointing a symlink at a different target changes the digest" "unchanged" ;;
  *)        ok  "repointing a symlink at a different target changes the digest" ;;
esac
ln -sfn commands/go.md "$DIG/installed/link"

# .git is the fetch's own machinery and is never in an installed copy, so a
# digest that counted it could never report `same` about anything.
mkdir -p "$DIG/installed/.git/objects"
printf 'ref: refs/heads/main\n' > "$DIG/installed/.git/HEAD"
printf 'loose object\n'         > "$DIG/installed/.git/objects/aa"
is  "files under .git are not counted" "$(_dg "$DIG/installed")" "$dread"
# .in_use is written INTO an installed plugin by the platform, one file per
# running session named by pid. A digest that counted them would differ from
# itself every session and drift would mean nothing.
mkdir -p "$DIG/installed/.in_use"
printf 'session\n' > "$DIG/installed/.in_use/$$"
printf 'session\n' > "$DIG/installed/.in_use/424242"
is  "and neither are the per-session files under .in_use" "$(_dg "$DIG/installed")" "$dread"

# An empty copy must not digest, because the digest of an empty document is
# one value and every empty directory would then look like the same copy.
mkdir -p "$DIG/hollow/nested/deeper"
is  "a directory that exists but holds no files yields no digest" "$(_dg "$DIG/hollow")" ""
[ "$(_dgrc "$DIG/hollow")" != "0" ] \
  && ok  "and says so with a non-zero status, not the digest of an empty document" \
  || bad "and says so with a non-zero status, not the digest of an empty document" "exited 0"
is  "a directory that does not exist yields no digest" "$(_dg "$DIG/no-such-copy")" ""
[ "$(_dgrc "$DIG/no-such-copy")" != "0" ] \
  && ok  "and a non-zero status too" \
  || bad "and a non-zero status too" "exited 0"

# The shape this exists for: what Felix read is a repo with the plugin in a
# subdirectory, beside a README and a .git; what got installed is flat.
DIGR="$TMP/digest-repo"; mkdir -p "$DIGR"
_mkplug "$DIGR/felix"
printf '# readme\n' > "$DIGR/README.md"
mkdir -p "$DIGR/.git"; printf 'ref: refs/heads/main\n' > "$DIGR/.git/HEAD"
is  "a subdirectory named as an argument digests as that subdirectory alone" \
    "$(_dg "$DIGR" felix)" "$(_dg "$DIGR/felix")"
is  "so the plugin subdirectory of the fetched repo digests as the flat installed copy" \
    "$(_dg "$DIGR" felix)" "$dread"
is  "a subdir argument naming no directory digests the copy it was given" \
    "$(_dg "$DIG/read" no-such-subdir)" "$dread"

# ---- what the cache recorded -------------------------------------------------
RDG="$TMP/digest-cache-home"; mkdir -p "$RDG/state/discover"
RDGP="$RDG/projects/widget"; mkdir -p "$RDGP"
{ _dgstamp
  printf 'deepeval	llm	low	%s\n' "$dread"
  printf 'langfuse	llm	low\n'
} > "$RDG/state/discover/widget.tsv"
_rdg()   { ( . "$FROOT/harness/lib/discover.sh"; felix_discover_read_digest "$1" "$2" "$3" ); }
_rdgrc() { ( . "$FROOT/harness/lib/discover.sh"
             felix_discover_read_digest "$1" "$2" "$3" >/dev/null 2>&1; echo $? ); }
is  "the cache hands back the digest recorded beside a name" \
    "$(_rdg "$RDGP" "$RDG" deepeval)" "$dread"
is  "a row written before digests existed reads as no digest, not as its tier" \
    "$(_rdg "$RDGP" "$RDG" langfuse)" ""
is  "a name the cache never carried reads as no digest" \
    "$(_rdg "$RDGP" "$RDG" figma)" ""
is  "and a cache file that is not there reads as no digest either" \
    "$(_rdg "$RDGP" "$TMP/digest-no-such-home" deepeval)" ""
is  "having nothing to say is not a failure" \
    "$(_rdgrc "$RDGP" "$TMP/digest-no-such-home" deepeval)" "0"

# ---- the comparison ----------------------------------------------------------
DFT="$TMP/drift-home"; mkdir -p "$DFT/state/discover"
DFTP="$DFT/projects/widget"; mkdir -p "$DFTP"
DFC="$TMP/drift-copies"; mkdir -p "$DFC"
_mkplug "$DFC/deepeval"; _mkplug "$DFC/langfuse"; _mkplug "$DFC/figma"
_mkplug "$DFC/sonarqube"; mkdir -p "$DFC/outputai/empty"
dclean="$(_dg "$DFC/deepeval")"
{ _dgstamp
  printf 'deepeval	llm	low	%s\n'      "$dclean"
  printf 'langfuse	llm	low	%s\n'      "$dclean"
  printf 'figma	frontend	medium\n'
  printf 'outputai	llm	high	%s\n'     "$dclean"
  printf 'sonarqube	secrets	high	%s\n' "$dclean"
  # Both of these carry a digest, so what they exercise is absence from
  # the registry and nothing else. A name missing from both tables could
  # honestly be called either absent or unread, and an assertion that
  # cannot say which one it is asserting is not an assertion.
  printf 'unmatched	llm	low	%s\n' "$dclean"
  printf 'noplace	llm	low	%s\n' "$dclean"
} > "$DFT/state/discover/widget.tsv"
# The installed langfuse is not the langfuse that was read.
printf 'and one more line\n' >> "$DFC/langfuse/plugin.json"
: > "$TMP/drift-not-a-directory"
cat > "$TMP/drift-registry.json" <<JSON
{ "version": 2,
  "plugins": {
    "deepeval@felix":  [ { "scope": "user", "version": "1.0.0", "installPath": "$DFC/deepeval" } ],
    "langfuse@felix":  [ { "scope": "user", "version": "1.0.0", "installPath": "$DFC/langfuse" } ],
    "figma@felix":     [ { "scope": "user", "version": "1.0.0", "installPath": "$DFC/figma" } ],
    "outputai@felix":  [ { "scope": "user", "version": "1.0.0", "installPath": "$DFC/outputai" } ],
    "sonarqube@felix": [ { "scope": "user", "version": "1.0.0", "installPath": "$TMP/drift-not-a-directory" } ],
    "noplace@felix":   [ { "scope": "user", "version": "1.0.0" } ]
  }
}
JSON
_drift()   { ( . "$FROOT/harness/lib/discover.sh"
               felix_discover_drift "$DFTP" "$DFT" "$1" "$TMP/drift-registry.json" ); }
_driftrc() { ( . "$FROOT/harness/lib/discover.sh"
               felix_discover_drift "$DFTP" "$DFT" "$1" "$TMP/drift-registry.json" \
                 >/dev/null 2>&1; echo $? ); }
is  "an installed copy that matches what Felix read reads same" \
    "$(_drift deepeval | cut -f1)" "same"
is  "and the detail is the digest the two copies share" \
    "$(_drift deepeval | cut -f2)" "$dclean"
is  "an installed copy that differs from what Felix read reads drift" \
    "$(_drift langfuse | cut -f1)" "drift"
has "and the detail names the digest that was recorded" \
    "$(_drift langfuse | cut -f2)" "$dclean"
has "and the digest the copy on disk carries now" \
    "$(_drift langfuse | cut -f2)" "$(_dg "$DFC/langfuse")"
is  "a name with no digest recorded claims nothing" \
    "$(_drift figma | cut -f1)" "unread"
is  "and an installed copy with no files to digest claims nothing either" \
    "$(_drift outputai | cut -f1)" "unread"
is  "an installPath that is not a directory reads absent" \
    "$(_drift sonarqube | cut -f1)" "absent"
is  "a name the registry does not hold reads absent" \
    "$(_drift unmatched | cut -f1)" "absent"
is  "and so does one whose registry entry carries no installPath" \
    "$(_drift noplace | cut -f1)" "absent"
is  "every verdict is one line of two tab-separated fields" \
    "$(_drift deepeval | awk -F'\t' 'END{print NR" "NF}')" "1 2"
is  "and reporting absent is not failing" "$(_driftrc unmatched)" "0"

# ---- the fourth column must not break the reader that was there first --------
# A reader that took three fields off a cache line would swallow the digest
# into the tier, match no tier, and drop every candidate in silence — which is
# the one failure mode nobody would see.
ADQ="$TMP/adopt-digest-home"; mkdir -p "$ADQ/state/discover"
ADQP="$ADQ/projects/widget"; mkdir -p "$ADQP"
printf 'plugin	langfuse@x	-	low	llm\n' > "$ADQP/stack.tsv"
{ _dgstamp
  printf 'deepeval	llm	low	%s\n'   "$dclean"
  printf 'langfuse	llm	low	%s\n'   "$dclean"
  printf 'figma	frontend	medium	%s\n' "$dclean"
  printf 'sonarqube	secrets	low\n'
} > "$ADQ/state/discover/widget.tsv"
aout="$( . "$FROOT/harness/lib/discover.sh"; felix_discover_adopt "$ADQP" "$ADQ" "" )"
has "a cache row carrying a digest is still declared" "$aout" "declare	deepeval"
has "a three-column row beside it is still declared"  "$aout" "declare	sonarqube"
has "one already in the stack still reads already"    "$aout" "already	langfuse"
has "and a medium one is still refused"               "$aout" "refuse	figma"
is  "every row the adopt reader emits is four fields wide, digest or no digest" \
    "$(printf '%s\n' "$aout" | awk -F'\t' '{print NF}' | sort -u | tr '\n' ' ')" "4 "
is  "and the tier field is the tier, not a tier with a digest stuck to it" \
    "$(printf '%s\n' "$aout" | awk -F'\t' '$2=="deepeval"{print $4}')" "low"
is  "no candidate is dropped in silence" \
    "$(printf '%s\n' "$aout" | grep -c .)" "4"
printf '\na night the founder granted\n'
# Overnight mode hands a session the right to keep going instead of stopping to
# ask. Everything that right rests on is a bound, and a bound nobody measures is
# a grant with no end: these assertions exist so that if any of the three ever
# stops holding, the suite says which one.
#
# The library is driven against a project directory of its own rather than
# widget, because the hook and command assertions further down write widget's
# overnight state and the two would otherwise be reading each other's files.
# Memory is keyed on the project's basename, so the fixture needs both.
_overnight_build

_ovreset "$NP"
_now="$(date +%s)"
_ov felix_overnight_start "$NP" 8 5 "$NS" "the founder granted a night" >/dev/null
_ov felix_overnight_active "$NP" "$NS" && ok "a granted night is in progress" \
                                 || bad "a granted night is in progress" "$(cat "$(_ovfile "$NP" "$NS")" 2>/dev/null)"
# Eight hours means eight hours, and the assertion is here as much for the
# tests as for the product: the expiry fixtures below rewrite field two, and
# without this they could be rewriting the wrong number and proving nothing.
_delta=$(( $(_ovfield "$NP" 2 "$NS") - _now ))
is "an eight-hour grant runs until eight hours from now" \
   "$([ "$_delta" -ge 28700 ] && [ "$_delta" -le 28900 ] && echo yes || echo "no ($_delta seconds)")" "yes"

# Three bounds, and a night is live only while all three hold. Each is armed on
# its own so a failure names the bound rather than the feature.
_ovexpire "$NP" "$NS"; _past="$(_ov felix_overnight_active "$NP" "$NS" && echo yes || echo no)"
_ovreset "$NP"; _ov felix_overnight_start "$NP" 8 1 "$NS" "one turn" >/dev/null
_ov felix_overnight_spend "$NP" 0 "$NS" >/dev/null
_spent="$(_ov felix_overnight_active "$NP" "$NS" && echo yes || echo no)"
_ovreset "$NP"; _ov felix_overnight_start "$NP" 8 5 "$NS" "quiet" >/dev/null
_ov felix_overnight_spend "$NP" 1 "$NS" >/dev/null; _ov felix_overnight_spend "$NP" 1 "$NS" >/dev/null
_quiet="$(_ov felix_overnight_active "$NP" "$NS" && echo yes || echo no)"
is "any one bound reached ends the night, whichever it is" \
   "deadline:$_past turns:$_spent quiet:$_quiet" "deadline:no turns:no quiet:no"

# felix_overnight_expired has to tell three states apart, and two of them look
# identical from the outside: a night nobody granted and a night still running
# both mean "do not write the morning page". Only the third has anything to say.
_ovreset "$NP"
_none="$(_ov felix_overnight_expired "$NP" "$NS")"; _nonerc=$?
_ov felix_overnight_start "$NP" 8 5 "$NS" "live" >/dev/null
_live="$(_ov felix_overnight_expired "$NP" "$NS")"; _liverc=$?
is "a night nobody granted is not an expired night" "$_nonerc:[$_none]" "1:[]"
is "and neither is one that is still running"       "$_liverc:[$_live]" "1:[]"

_ovexpire "$NP" "$NS"
_whytime="$(_ov felix_overnight_expired "$NP" "$NS")"; _timerc=$?
is "a deadline that has passed ends the night and says so" \
   "$_timerc:$([ -n "$_whytime" ] && echo said || echo silent)" "0:said"
_ovreset "$NP"; _ov felix_overnight_start "$NP" 8 1 "$NS" "one turn" >/dev/null
_ov felix_overnight_spend "$NP" 0 "$NS" >/dev/null
_whyturns="$(_ov felix_overnight_expired "$NP" "$NS")"; _turnsrc=$?
is "continuations run out and the night ends" \
   "$_turnsrc:$([ -n "$_whyturns" ] && echo said || echo silent)" "0:said"
_ovreset "$NP"; _ov felix_overnight_start "$NP" 8 5 "$NS" "quiet" >/dev/null
_ov felix_overnight_spend "$NP" 1 "$NS" >/dev/null; _ov felix_overnight_spend "$NP" 1 "$NS" >/dev/null
_whyquiet="$(_ov felix_overnight_expired "$NP" "$NS")"; _quietrc=$?
is "two runs with nothing to show end the night too" \
   "$_quietrc:$([ -n "$_whyquiet" ] && echo said || echo silent)" "0:said"
# The morning has to know which wall it hit. One sentence for all three is a
# report that cannot be acted on: more time, more turns and a stuck session are
# three different mornings.
is "and each bound is named in its own words" \
   "$(printf '%s\n%s\n%s\n' "$_whytime" "$_whyturns" "$_whyquiet" | LC_ALL=C sort -u | grep -c .)" "3"

