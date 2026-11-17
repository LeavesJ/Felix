printf '\necosystem\n'
# Invariant 1, one level up from the name.
#
# The independence block above proves the engine names no governed PROJECT. It
# cannot see the other half of the same invariant. A detector in engine/harness
# hard-coded to FastAPI route decorators and an Anthropic client construction
# site contains no project name, passes that check, and encodes exactly one
# project's shape into an engine whose whole claim is that it holds none. That
# is not hypothetical: it is a design that was drafted for Felix and would have
# shipped.
#
# So the words are enumerated the way the names are - off reality, never off a
# literal. Reality here is lib/detect.sh: the alternation tokens inside its own
# _felix_dep_grep calls ARE the set of ecosystems the engine reasons about, so
# teaching the probe a new framework arms this check for it in the same commit.
#
# What reality cannot supply is a stance. Some ecosystems the engine reaches
# through a manifest FILENAME rather than a probe token - `pyproject.toml` never
# spells `python` - and some probe tokens are ordinary English (`next`) and can
# never be enforced. Those are `word` and `mute` rows, each carrying a written
# reason, in the style of deny.tsv and risk.tsv. Felix holds stances; it does
# not author the enumeration.
#
# Matching is word-boundaried, and that is a measured choice rather than a
# neat one. Substring matching flags `cohere` inside "coherent", `vite` inside
# "invite" and `express` inside "expressed" - three false positives in the
# engine's own prose today. Word boundaries leave `ANTHROPIC_API_KEY` alone,
# which is correct twice over: bin/secret-scan and lib/unattended.sh both name
# it as a credential, which is what they are for.
_ECOT="$FROOT/harness/ecosystem.tsv"
_ECOD="$FROOT/harness/lib/detect.sh"
_ecorun=("$FROOT/harness/felix" "$FROOT/harness/lib" "$FROOT/harness/hooks" "$FROOT/harness/bin")

# Every alternation token inside a _felix_dep_grep pattern. Continuation lines
# are joined first: the llm probe's pattern sits on its own line, and reading
# line-by-line silently drops the whole model-SDK vocabulary - anthropic
# included, which is half the case this block exists for.
_eco_probe_words() {
  sed -e :a -e '/\\$/N; s/\\\n//; ta' "$_ECOD" 2>/dev/null \
    | grep -oE '_felix_dep_grep "\$root" +"[^"]*(\\"[^"]*)*"' \
    | sed -E 's/.*_felix_dep_grep "\$root" +"//; s/"$//' \
    | sed 's/\\"?//g; s/\\"//g' | tr '|' '\n' \
    | sed 's/^ *//; s/ *$//' | grep -v '^$' | LC_ALL=C sort -u
}

# kind <TAB> file <TAB> token <TAB> reason. `file` is relative to harness/, and
# `-` where the row is not about one file.
_eco_rows() {
  local want="$1" kind file token reason
  [ -f "$_ECOT" ] || return 0
  while IFS=$'\t' read -r kind file token reason; do
    case "$kind" in ''|'#'*) continue ;; esac
    [ "$kind" = "$want" ] || continue
    [ -n "${token:-}" ] || continue
    printf '%s\t%s\t%s\n' "$file" "$token" "${reason:-}"
  done < "$_ECOT"
}

# probe + word - mute.
_eco_words() {
  { _eco_probe_words
    _eco_rows word | cut -f2 | tr '|' '\n'
  } | sed 's/^ *//; s/ *$//' | grep -v '^$' | LC_ALL=C sort -u \
    | grep -vxF -f <(_eco_rows mute | cut -f2 | tr '|' '\n' | grep -v '^$') 2>/dev/null \
    || true
}

# Does a row permit this file to say this word? `*` means every word.
_eco_allowed() {
  local f="$1" w="$2" rf rt rr
  while IFS=$'\t' read -r rf rt rr; do
    [ "$rf" = "$f" ] || continue
    [ "$rt" = '*' ] && return 0
    case "|$rt|" in *"|$w|"*) return 0 ;; esac
  done <<EOF
$(_eco_rows allow)
EOF
  return 1
}

# Every (file, word) pair in a tree that no row permits.
_eco_leaks() {
  local w f rel
  while IFS= read -r w; do
    [ -n "$w" ] || continue
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      rel="${f#"$FROOT"/harness/}"
      _eco_allowed "$rel" "$w" || printf '%s names %s\n' "$rel" "$w"
    done <<EOF
$(grep -rlwiE -- "$w" "${_ecorun[@]}" 2>/dev/null)
EOF
  done <<EOF
$(_eco_words)
EOF
}

# Armed before it is trusted, and this is the arming that matters most: the
# words come out of another file by pattern, so a refactor of detect.sh that
# this extractor no longer recognises empties the vocabulary, and a negative
# assertion over an empty set is the shape that passes by finding nothing.
_ecopn="$(_eco_probe_words | wc -l | tr -d ' ')"
[ "${_ecopn:-0}" -gt 0 ] \
  && ok "the capability probe yields ecosystem words to check for" \
  || bad "the capability probe yields ecosystem words to check for" \
         "_eco_probe_words returned nothing from $_ECOD"

# And that they are really read off the probe rather than carried here. Two
# tokens from two different probes, one of them on the continued line.
_ecop="$(_eco_probe_words | tr '\n' ' ')"
case "$_ecop" in
  *fastapi*) ok "the words are read off lib/detect.sh, not carried as a literal" ;;
  *) bad "the words are read off lib/detect.sh, not carried as a literal" "got: $_ecop" ;;
esac
case "$_ecop" in
  *anthropic*) ok "including the model-SDK probe, which sits on a continued line" ;;
  *) bad "including the model-SDK probe, which sits on a continued line" "got: $_ecop" ;;
esac
# And that every token is a word, not a regex fragment. The extractor's sed
# used `\?`, which BSD sed reads as a literal `?` and GNU sed as a quantifier —
# so on the Linux runner the probe pattern `\"?stripe\"?` came out as `?stripe?`,
# which `grep -wE` reads as "strip, optionally followed by e", and two files
# were reported for naming the English word "strip". Locally it never
# reproduced, because this machine's sed is BSD. A vocabulary check whose
# vocabulary is a regex fragment is wrong in both directions at once.
_ecobad="$(_eco_probe_words | grep -E '^[^a-z0-9]|[^a-z0-9]$|["\\]' || true)"
[ -z "$_ecobad" ] \
  && ok "every vocabulary token is a word, not a regex fragment" \
  || bad "every vocabulary token is a word, not a regex fragment" "tokens: $(printf '%s' "$_ecobad" | tr '\n' ' ')"

# The property itself.
_ecoleak="$(_eco_leaks)"
[ -z "$_ecoleak" ] \
  && ok "the engine names no ecosystem without a declared reason" \
  || bad "the engine names no ecosystem without a declared reason" \
         "$(printf '%s\n' "$_ecoleak" | head -8)"

# Armed on the other side too. The two row-quality assertions below are negative
# over a set read out of a file, so a missing or unparseable ecosystem.tsv makes
# both of them pass having judged nothing. The leak assertion above would go red
# in that case and this would still be the wrong reason to be green.
_ecorn="$(_eco_rows allow | wc -l | tr -d ' ')"
[ "${_ecorn:-0}" -gt 0 ] \
  && ok "there are declared ecosystem rows to judge" \
  || bad "there are declared ecosystem rows to judge" "no allow rows parsed from $_ECOT"

# Every row carries a reason. A table of bare exemptions is a list of things
# nobody had to justify, which is how an allowlist becomes the hole.
_ecomute=0
while IFS=$'\t' read -r rf rt rr; do
  [ -n "${rt:-}" ] || continue
  [ -n "${rr:-}" ] || _ecomute=$((_ecomute+1))
done <<EOF
$(_eco_rows allow; _eco_rows word; _eco_rows mute)
EOF
is "every ecosystem row carries a written reason" "$_ecomute" "0"

# A row that no longer matches anything is a claim about a surface that is
# gone - the orphan-stance class of gap, which #125's own review found by
# looking for it. Reported, not fatal: a file may legitimately stop naming
# something before anybody prunes the row.
_ecoorphan=""
while IFS=$'\t' read -r rf rt rr; do
  [ -n "${rt:-}" ] || continue
  [ "$rt" = '*' ] && continue
  [ -f "$FROOT/harness/$rf" ] || [ -d "$FROOT/harness/$rf" ] || { _ecoorphan="$_ecoorphan $rf"; continue; }
  grep -rlwiE -- "$rt" "$FROOT/harness/$rf" >/dev/null 2>&1 || _ecoorphan="$_ecoorphan $rf:$rt"
done <<EOF
$(_eco_rows allow)
EOF
is "no allow row claims a surface that no longer names it" "$_ecoorphan" ""

# The rule, against a fixture holding the exact design that would have shipped.
# This is the assertion the independence block could not carry: the same file
# names no project at all, so the check above it passes on it.
_ECOF="$TMP/ecofixture"; rm -rf "$_ECOF"; mkdir -p "$_ECOF"
cat > "$_ECOF/planted.sh" <<'PLANT'
_felix_planted_routes() { grep -rnE 'from fastapi import|@(app|router)\.(get|post)\(' "$1"; }
_felix_planted_llm()    { grep -rnE 'anthropic\.Anthropic\(' "$1"; }
_felix_planted_gate()   { printf 'python -m pytest -q\n'; }
PLANT
_eco_fixture_hits() {
  local w n=0
  while IFS= read -r w; do
    [ -n "$w" ] || continue
    grep -qlwiE -- "$w" "$_ECOF/planted.sh" 2>/dev/null && n=$((n+1))
  done <<EOF
$(_eco_words)
EOF
  printf '%s\n' "$n"
}
[ "$(_eco_fixture_hits)" -ge 2 ] \
  && ok "a detector hard-coded to one stack is caught" \
  || bad "a detector hard-coded to one stack is caught" \
         "matched $(_eco_fixture_hits) ecosystem words in the planted detector"
# And why it needed catching here: the name check cannot see it.
_ecogov=0
while IFS= read -r _gn; do
  [ -n "$_gn" ] || continue
  grep -qniF -- "$_gn" "$_ECOF/planted.sh" 2>/dev/null && _ecogov=$((_ecogov+1))
done <<EOF
$(_gov_names)
EOF
is "and the independence check above it sees nothing wrong with that file" "$_ecogov" "0"
rm -rf "$_ECOF"

# A word that cannot be enforced is muted on the record rather than quietly
# left out of the vocabulary. `next` is a probe token AND the name of a Felix
# command, so enforcing it would flag twenty engine files on the first run.
case "$(_eco_words | tr '\n' ' ')" in
  *" next "*) bad "an unenforceable probe word is muted on the record" "next is still in the vocabulary" ;;
  *)          ok  "an unenforceable probe word is muted on the record" ;;
esac
is "and the mute is a row, not a silent omission" \
   "$(_eco_rows mute | cut -f2 | tr '|' '\n' | grep -cx next)" "1"

# The whole mute set, not just that `next` is in it. This is the one edit that
# narrows invariant 1 while the table GROWS, so the escape channel cannot see
# it: ecosystem.tsv is an enforcing table and shrinking it fires `verifier`, but
# adding `mute - fastapi` removes fastapi from the vocabulary by addition. A
# mute is meant to be rare and argued, so the set is pinned and a new one has to
# come here and say which word the engine cannot help using and why.
is "and nothing else is muted, because muting is how this narrows quietly" \
   "$(_eco_rows mute | cut -f2 | tr '|' '\n' | grep -v '^$' | LC_ALL=C sort -u | tr '\n' ' ')" \
   "next "

# The gate keeps its own copy, for the same reason it keeps one of every other
# check: a verifier that sources the code it judges can be switched off by
# editing that code. Asserted in step by naming the mechanism, not a marker.
_REALG="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/gate.sh"
if [ -f "$_REALG" ]; then
  _gate_eco="$(sed -n '/^# -.*ecosystem/,/^# -.*memory/p' "$_REALG" | grep -vE '^[[:space:]]*#')"
  case "$_gate_eco" in
    *ecosystem.tsv*) ok "the gate carries the ecosystem check too" ;;
    *) bad "the gate carries the ecosystem check too" "no ecosystem block in the shipped gate" ;;
  esac
  case "$_gate_eco" in
    *detect.sh*) ok "and reads its words off the capability probe" ;;
    *) bad "and reads its words off the capability probe" "no detect.sh in the ecosystem block" ;;
  esac
  case "$_gate_eco" in
    *ECO_BLIND*) ok "and refuses to answer when the probe yields no words" ;;
    *) bad "and refuses to answer when the probe yields no words" "no blindness guard in the ecosystem block" ;;
  esac
  case "$_gate_eco" in
    *'git grep -lwniE'*) ok "and matches an ecosystem word on a word boundary" ;;
    *) bad "and matches an ecosystem word on a word boundary" "not a word-boundaried search" ;;
  esac
else
  skip "the gate carries the ecosystem check too" "no shipped gate"
  skip "and reads its words off the capability probe" "no shipped gate"
  skip "and refuses to answer when the probe yields no words" "no shipped gate"
  skip "and matches an ecosystem word on a word boundary" "no shipped gate"
fi

# It decides what stops, so shrinking it is an escape channel. Removing one
# `word` row silently narrows the invariant, which is the same shape as
# narrowing risk.tsv and belongs in the same list.
case " $(grep -E "^FELIX_ESCAPE_TABLES=" "$FROOT/harness/lib/escape.sh" | sed "s/.*='//; s/'.*//") " in
  *" ecosystem.tsv "*) ok "the ecosystem table is an enforcing table, and escape.sh says so" ;;
  *) bad "the ecosystem table is an enforcing table, and escape.sh says so" \
         "ecosystem.tsv is not in FELIX_ESCAPE_TABLES" ;;
esac
printf '\ncommissioning: one moment, one table, one policy\n'
# The first-encounter moment (v3.2 §8) as a table. Every stage existed as a
# command a person typed in order and felix new printed the order; now a row
# names a need, an instrument, an engine stage that answers it and a check
# that decides, and `unknown` is reachable by construction.
_commissioning_build alpha12
_cmstate() { _cm felix_commission_run "$CMP" "$CMR" - | awk -F'\t' -v n="$1" '$1 == n { print $2 }'; }
_cmdetail() { _cm felix_commission_run "$CMP" "$CMR" - | awk -F'\t' -v n="$1" '$1 == n { print $6 }'; }

is  "seven-field rows with an engine-stage answer and a check that can fail are rows" \
    "$(_cm felix_commission_rows "$CMP" | cut -f1 | tr '\n' ' ')" "alpha plain beta gamma delta eps zeta prov "
_cmmal="$(_cm felix_commission_malformed "$CMP")"
has "a negated check is malformed, because it could not fail"      "$_cmmal" "eta"
has "an answer outside the engine's stages is malformed"           "$_cmmal" 'felix:rm -rf'
has "a step outside 1-10 is malformed"                             "$_cmmal" "iota"
has "six fields is malformed, never truncated"                     "$_cmmal" "kappa"

is  "a check that passes is done"                                        "$(_cmstate alpha)" "done"
is  "a check naming no engine function is not read as one missing"       "$(_cmstate plain)" "done"
is  "a check that fails is held"                                         "$(_cmstate beta)"  "held"
is  "an instrument this machine lacks makes the row unknown"             "$(_cmstate gamma)" "unknown"
has "and says it could not be asked here"                                "$(_cmdetail gamma)" "could not be asked on this machine"
is  "a when whose command does not exist is unknown, not not-applicable" "$(_cmstate delta)" "unknown"
is  "an inactive capability makes the row not-applicable"                "$(_cmstate eps)"   "not-applicable"
is  "an engine function the check names that is not loaded is unknown"   "$(_cmstate zeta)"  "unknown"
has "and the missing function is named"                                  "$(_cmdetail zeta)" "felix_no_such_function"
is  "a provider row is awaiting, a class of its own"                     "$(_cmstate prov)"  "awaiting"

# A row's text means what it means in a probe.
#
# felix_commission_ask evaluates a row in-process, so the row inherited the
# CLI's `set -uo pipefail`, which no other table runner has. A check shaped
# `producer | grep -q x` whose grep matched and left while the producer still
# had output to write read as failed, because the producer died of SIGPIPE: a
# check read held for a step that was done, and a `when` read not-applicable
# and skipped its step. The producer here writes about 1.3 MB with the match on
# its first line, far past what one pipe holds, so grep leaving early is
# certain and not a matter of load. The engine functions a row names run
# without pipefail too, as they already do under bin/probes-check.
# Everything this touches is restored below and everything it defines unset.
cp "$CMP/commissioning.tsv" "$TMP/cmpf-table.keep"
_cmpfml="$MEM/cmproj/mistakes.log"
rm -f "$TMP/cmpf-mistakes.keep"; [ -f "$_cmpfml" ] && cp "$_cmpfml" "$TMP/cmpf-mistakes.keep"
_cmpfp="awk 'BEGIN { print \"cmpfhit\"; for (i = 0; i < 20000; i++) print \"filler that pushes the producer far past what one pipe can hold\" }'"
_cmpfrow() { printf '%s\t-\t-\t%s\t-\t%s\t9' "$1" "$2" "$3"; }   # need, when, check
_cmpfst()  { printf '%s\n' "$1" | awk -F'\t' -v n="$2" '$1 == n { print $2 }'; }
felix_cmpf_on()    { [ -o pipefail ]; }
felix_cmpf_off()   { ! [ -o pipefail ]; }
felix_cmpf_state() { if [ -o pipefail ]; then printf 'on\n'; else printf 'off\n'; fi; }
felix_cmpf_true()  { return 0; }
# An engine function that sources a library, as cmd_bootstrap's kind do: the
# library redefines the function running it, redefines a function the row also
# names, and defines one nothing named before.
felix_cmpf_src()         { . "$TMP/cmpf-lib.sh" && felix_cmpf_src_fresh; }
felix_cmpf_src_defined() { return 1; }
cat > "$TMP/cmpf-lib.sh" <<'CMPFLIB'
felix_cmpf_src() { . "$TMP/cmpf-lib.sh" && felix_cmpf_src_fresh; }
felix_cmpf_src_defined() { return 0; }
felix_cmpf_src_fresh() { return 0; }
CMPFLIB
# A mistakes.log far past 64 KB whose first row's label is neither commission
# nor probes, which is the state the seeded gate_shown_failing check calls done.
awk 'BEGIN { printf "2026-09-25\tmain\tabc1234\tgate\n"
             for (i = 0; i < 20000; i++)
               printf "2026-09-25\tmain\tabc1234\tcheck%d filler words that are neither commission nor probes\n", i }' > "$_cmpfml"
_cmpfgsf="$(awk -F'\t' '$1 == "gate_shown_failing"' "$FROOT/harness/templates/commissioning.tsv")"
_cmtable "$(_cmpfrow cmpf_yes       - "$_cmpfp | grep -q cmpfhit")" \
         "$(_cmpfrow cmpf_when_yes  "$_cmpfp | grep -q cmpfhit" true)" \
         "$(_cmpfrow cmpf_no        - "$_cmpfp | grep -q cmpfnope")" \
         "$(_cmpfrow cmpf_when_no   "$_cmpfp | grep -q cmpfnope" true)" \
         "$(_cmpfrow cmpf_early     - "sh -c 'echo hit; exit 3' | grep -q hit")" \
         "$_cmpfgsf" \
         "$(_cmpfrow cmpf_whole     - 'felix_cmpf_off')" \
         "$(_cmpfrow cmpf_subst     - '[ "$(felix_cmpf_state)" = off ]')" \
         "$(_cmpfrow cmpf_when_fn   'felix_cmpf_off' true)" \
         "$(_cmpfrow cmpf_fails     - 'felix_cmpf_on')" \
         "$(_cmpfrow cmpf_src       - 'felix_cmpf_src && felix_cmpf_src_defined')" \
         "$(_cmpfrow cmpf_cmdv      - '[ "$(command -v felix_cmpf_on)" = felix_cmpf_on ]')" \
         "$(_cmpfrow cmpf_type      - '[ "$(type -t felix_cmpf_on)" = function ]')" \
         "$(_cmpfrow cmpf_quoted    - "_s='felix_cmpf_on'; [ \"\${#_s}\" -eq 13 ]")" \
         "$(_cmpfrow cmpf_redef     'felix_cmpf_true() { return 0; }; felix_cmpf_true' true)" \
         "$(_cmpfrow cmpf_unset     - 'test -z "$cmpf_never_set_anywhere"')"
# The suite runs under pipefail, so _cm is a caller that has it.
_cmpfon="$(_cm felix_commission_run "$CMP" "$CMR" -)"

is  "a check whose producer outruns grep -q, the match on its first line, is done" \
    "$(_cmpfst "$_cmpfon" cmpf_yes)" "done"
is  "a when of that shape makes its row applicable, and the check decides it" \
    "$(_cmpfst "$_cmpfon" cmpf_when_yes)" "done"
has "the seeded gate_shown_failing row is read from the template, not retyped" \
    "$_cmpfgsf" "gate_shown_failing	"
is  "the seeded gate_shown_failing check is done over a mistakes.log far past 64 KB" \
    "$(_cmpfst "$_cmpfon" gate_shown_failing)" "done"
is  "a check whose producer never shows the match is still held" \
    "$(_cmpfst "$_cmpfon" cmpf_no)" "held"
is  "and a when of that shape still makes its row not-applicable" \
    "$(_cmpfst "$_cmpfon" cmpf_when_no)" "not-applicable"
is  "a pipeline whose first stage fails and whose last succeeds is done, as in a probe" \
    "$(_cmpfst "$_cmpfon" cmpf_early)" "done"

is  "an engine function that is the whole check runs without pipefail, as the row does" \
    "$(_cmpfst "$_cmpfon" cmpf_whole)" "done"
is  "and so does one inside a command substitution"           "$(_cmpfst "$_cmpfon" cmpf_subst)"   "done"
is  "and one named in a when"                                 "$(_cmpfst "$_cmpfon" cmpf_when_fn)" "done"
is  "and an engine function that fails there reads held"      "$(_cmpfst "$_cmpfon" cmpf_fails)"   "held"
is  "an engine function that sources a library redefining what the check names runs the new definitions" \
    "$(_cmpfst "$_cmpfon" cmpf_src)" "done"

is  "an engine function's name passed to command -v comes back as written" \
    "$(_cmpfst "$_cmpfon" cmpf_cmdv)" "done"
is  "and type -t calls that name a function"                  "$(_cmpfst "$_cmpfon" cmpf_type)"   "done"
is  "and inside a quoted string that name is the string as written" \
    "$(_cmpfst "$_cmpfon" cmpf_quoted)" "done"
is  "a when may define a function under an engine function's name and call it" \
    "$(_cmpfst "$_cmpfon" cmpf_redef)" "done"
is  "a check naming an unset variable is still held, because nounset stays" \
    "$(_cmpfst "$_cmpfon" cmpf_unset)" "held"

# An ask changes nothing about the shell that asked.
_cmpfkept() { local before; before="$(set +o)"
              felix_commission_ask "$CMR" "$_cmpfp | grep -q cmpfhit"
              felix_commission_ask "$CMR" 'felix_cmpf_on && false | true'
              felix_commission_run "$CMP" "$CMR" - >/dev/null
              if [ "$(set +o)" = "$before" ]; then printf 'kept'; else printf 'moved'; fi
              if [ -o pipefail ]; then printf ' on\n'; else printf ' off\n'; fi; }
_cmpfnopfkept() { set +o pipefail; _cmpfkept; }
is  "an ask and a run leave a caller that had pipefail every option it had" "$(_cm _cmpfkept)"     "kept on"
is  "and leave a caller without pipefail every option it had"              "$(_cm _cmpfnopfkept)" "kept off"

# And through the real command, whose own shell is `set -uo pipefail`.
_cmtable "$(_cmpfrow cmpf_yes - "$_cmpfp | grep -q cmpfhit")" "$_cmpfgsf"
_cmpfcli="$( cd "$CMR" && PATH="$CMSTUB:$PATH" "$FELIX" commission --status 2>&1 )"
is  "felix commission --status reads the row whose producer outruns grep -q done" \
    "$(printf '%s\n' "$_cmpfcli" | awk '$2 == "cmpf_yes" { print $1 }')" "done"
is  "and reads the seeded gate_shown_failing row done over that mistakes.log" \
    "$(printf '%s\n' "$_cmpfcli" | awk '$2 == "gate_shown_failing" { print $1 }')" "done"

cp "$TMP/cmpf-table.keep" "$CMP/commissioning.tsv"
if [ -f "$TMP/cmpf-mistakes.keep" ]; then mv "$TMP/cmpf-mistakes.keep" "$_cmpfml"; else rm -f "$_cmpfml"; fi
rm -f "$TMP/cmpf-table.keep" "$TMP/cmpf-lib.sh"
unset -f _cmpfrow _cmpfst _cmpfkept _cmpfnopfkept felix_cmpf_on felix_cmpf_off felix_cmpf_state \
         felix_cmpf_true felix_cmpf_src felix_cmpf_src_defined
unset _cmpfml _cmpfp _cmpfgsf _cmpfon _cmpfcli

