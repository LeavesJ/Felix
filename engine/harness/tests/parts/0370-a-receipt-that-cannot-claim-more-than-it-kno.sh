printf '\na receipt that cannot claim more than it knows\n'
# v3.0's domain-OS contract asks each harness for a machine-readable record of
# what changed, why, evidence, risk and result. Felix computes every one of
# those and emits none of them: classify has the risk, evidence has what is
# owed, the gate has the result, escape has the authority question. This is a
# serialiser over facts that already exist.
#
# Two properties come from the transport research rather than from the contract.
# Neither MCP 2026-07-28 nor A2A 1.0.1 carries a bounded authority claim, and
# neither signs task output — so if a receipt is to say on whose authority the
# work proceeded, the receipt itself must carry it, because no transport will.
# And neither models verification as distinct from completion, which is exactly
# what Felix has that they do not, so the gate verdict is its own field.
#
# The load-bearing property is none of that. It is that the receipt CANNOT CLAIM
# VERIFIED ON AN ABSENCE. Six defects in one day were one species — emptiness
# read as success — so the first consumer of this receipt is that rule.
_widget_repo_build
_unborn_repo_build
_staged_repo_build full
_rcpt() { ( cd "$STG" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
            . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
            . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/classify.sh"
            . "$FROOT/harness/lib/evidence.sh"; . "$FROOT/harness/lib/receipt.sh"
            felix_receipt "$FROOT/projects/widget" "${1:-$BASE_SHA}" "$STG" "$FROOT" ); }
_rf() { printf '%s' "$1" | python3 -c '
import json,sys
d=json.load(sys.stdin)
for p in sys.argv[1].split("."): d=d[p]
print(d if isinstance(d,str) else json.dumps(d))' "$2" 2>/dev/null; }

r="$(_rcpt)"
printf '%s' "$r" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null \
  && ok "it emits parseable json" || bad "it emits parseable json" "$r"
is  "it names a schema version, so a reader can refuse one it does not know" \
    "$(_rf "$r" schema)" "felix.receipt/2"
is  "and the domain it speaks for"  "$(_rf "$r" domain)" "engineering"
has "it names what changed"         "$(_rf "$r" changed.paths)" "src/a.py"
is  "and says that it knows"        "$(_rf "$r" changed.known)" "true"
# And it carries what it cannot show. v3.2's conformance amendments close on a
# residual no layer above them removes — one authority writes both the work and
# the judgement of the work — and instruct that it be stated wherever the system
# reports its own trustworthiness. A receipt is exactly that, and it is the one
# that travels: a peer consuming a confidence figure with no idea what bounds it
# is the case this field exists for.
has "the receipt carries the limit no layer above it removes" \
    "$(_rf "$r" limits.authority)" "writes both the work and the judgement"
has "and the one enumeration cannot close" \
    "$(_rf "$r" limits.enumeration)" "never found is never executed"

# The gate has not run against this tree, so nothing may say it was checked.
# This is the whole point: an absent receipt is not a green one. Refused under
# the old word too (felix.receipt/1 said verified), so the check cannot pass by
# meeting neither.
vs="$(_rf "$r" verification.state)"
is "an absent gate receipt reads as absent, not as green" "$vs" "none"
st="$(_rf "$r" status)"
case "$st" in checked|verified) bad "and the receipt refuses to call that checked" "$st" ;;
              *)                ok  "and the receipt refuses to call that checked" ;; esac

# Authority is carried in the receipt because no transport carries it.
is "a staged workflow makes this the founder's call" "$(_rf "$r" authority.founder_required)" "true"
is "and it is not autonomous"                        "$(_rf "$r" authority.autonomous)"      "false"
has "naming the channel that escaped"                "$(_rf "$r" authority.escapes)"         "execute"
# Was "which is nobody yet", and #57 named it a constant checked against itself:
# granted_by was the literal "none", so this compared "none" to "none". With the
# field computed it is a real negative control — an execute escape is not
# clearable by review, so nothing granted here and the field must say so.
is "and that nothing granted it, on a channel review cannot clear" \
   "$(_rf "$r" authority.granted_by)" "none"
# And the other direction. A red tier with no channel set founder_required,
# which no merge honoured and which told any reader of the receipt that a person
# must approve routine engine work. The founder is required where a channel
# escapes; a red tier is advice.
RDR="$TMP/redreceipt"; mkdir -p "$RDR"
( _fx_cd "$RDR" && git init -q -b main && printf 'widget\n' > .felix && printf 'x\n' > seed.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
RDR="$(cd "$RDR" && pwd -P)"; RDB="$(git -C "$RDR" rev-parse HEAD)"
mkdir -p "$RDR/auth"; printf 'allow = True\n' > "$RDR/auth/policy.py"
( _fx_cd "$RDR" && git add -A && git -c user.name=t -c user.email=t@t commit -qm red ) >/dev/null 2>&1
_rdr="$( cd "$RDR" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
         . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
         . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/classify.sh"
         . "$FROOT/harness/lib/evidence.sh"; . "$FROOT/harness/lib/receipt.sh"
         felix_receipt "$FROOT/projects/widget" "$RDB" "$RDR" "$FROOT" )"
is "a red change with no channel is red in the receipt"          "$(_rf "$_rdr" risk.tier)"                 "red"
is "and nothing escapes, so the fixture can tell the two apart"  "$(_rf "$_rdr" authority.escapes)"         "[]"
is "and the receipt does not claim the founder must approve it"  "$(_rf "$_rdr" authority.founder_required)" "false"

# A base nothing can resolve must not read as "nothing changed". An empty list
# and an unanswerable question are different facts, and the whole family of
# defects this exists to prevent is reporting the second as the first.
r2="$(_rcpt deadbeefdeadbeefdeadbeefdeadbeefdeadbeef)"
is "an unresolvable base is not an empty changeset" "$(_rf "$r2" changed.known)" "false"
has "and it says so where a reader must look"       "$(_rf "$r2" unknown)"       "changed"
case "$(_rf "$r2" status)" in
  indeterminate) ok  "a receipt missing an input is indeterminate, never checked" ;;
  *)             bad "a receipt missing an input is indeterminate, never checked" "$(_rf "$r2" status)" ;;
esac

# Same rule for the risk table. "No risk.tsv" once reported green here, which is
# the same bug wearing the other hat.
mv "$FROOT/projects/widget/risk.tsv" "$TMP/risk.tsv.bak"
r3="$(_rcpt)"
is  "an unreadable risk table yields an unknown tier" "$(_rf "$r3" risk.tier)" "unknown"
has "listed where a reader must look"                "$(_rf "$r3" unknown)"   "risk"
case "$(_rf "$r3" status)" in
  checked|verified) bad "and never a checked receipt" "$(_rf "$r3" status)" ;;
  *)                ok  "and never a checked receipt" ;;
esac
mv "$TMP/risk.tsv.bak" "$FROOT/projects/widget/risk.tsv"

# risk.tsv rows carry more than four columns — `channel` and `confine` follow the
# reason — and the readers take the reason as "everything after the pattern", so
# it arrives with the remaining columns glued on behind two tabs. A human report
# gets away with that. A wire contract does not: a consumer reading `reason`
# would get three fields in a trench coat, and the version number promises it
# will not.
rr="$( . "$FROOT/harness/lib/receipt.sh"
       printf 'red\tsome/path\ta plain reason\tverifier\tcount:^x\n' \
         | _felix_rcpt_rows tier path reason )"
has "a finding names its reason"        "$rr" "a plain reason"
case "$rr" in
  *verifier*|*'count:'*) bad "and not the columns that follow it" "$rr" ;;
  *)                     ok  "and not the columns that follow it" ;;
esac
printf '%s' "$rr" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null \
  && ok "and the row is still json" || bad "and the row is still json" "$rr"

# The subject is two facts about HEAD, and an unborn HEAD is where both were
# wrong.
#
# felix_receipt read them as `$(git ... 2>/dev/null || printf '?')`, the twin of
# the expression the mistakes row above was fixed for on 2026-09-18. There git
# prints `HEAD` AND exits 128, so the fallback is appended to the answer instead
# of replacing it. The row broke visibly, as two lines. This did not: the
# escaper flattens a newline to a space, so the document stayed valid json and
# said `"branch": "HEAD ?"`. A well-formed wrong answer is the worse of the
# two, because nothing downstream can notice it — and it sat for a day beside
# the fix because nothing said the two were one question.
#
# The branch of an unborn repository is knowable, and the commit is `unborn`,
# the word felix_tree_id and the mistakes row already use for that state.
#
# Through the real CLI in the real unborn repository from the section above,
# for the reason given there: the defect is in what git says, and a fixture
# that invents git's answer inherits the assumption.
NOHEADR="$( cd "$NOHEAD" && "$FELIX" receipt 2>/dev/null )"
printf '%s' "$NOHEADR" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null \
  && ok "a receipt on an unborn HEAD is still json" || bad "a receipt on an unborn HEAD is still json" "$NOHEADR"
is  "and names the branch an unborn repository is on"      "$(_rf "$NOHEADR" subject.branch)" "main"
is  "and says its head is unborn rather than guessing one" "$(_rf "$NOHEADR" subject.head)"   "unborn"
# Knowing the branch is not knowing what changed. `main` names no commit here,
# so the receipt is exactly as indeterminate as it was.
has "and still does not know what changed there"           "$(_rf "$NOHEADR" unknown)"        "changed"

# The three states either side of it, so the reader that fixed one did not move
# another. The expected commit is cut from the full name rather than asked of
# `--short`, which is the expression under test.
_rcpt_in() { ( cd "$1" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
               . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
               . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/classify.sh"
               . "$FROOT/harness/lib/evidence.sh"; . "$FROOT/harness/lib/receipt.sh"
               felix_receipt "$FROOT/projects/widget" "${2:-main}" "$1" "$FROOT" ); }
_is_sha_of() {   # name, the short form a receipt gave, the repository it was read in
  local full; full="$(git -C "$3" rev-parse HEAD 2>/dev/null)"
  case "$2" in
    ''|'?'|unborn) bad "$1" "[$2] names no commit" ;;
    *) case "$full" in "$2"*) ok "$1" ;; *) bad "$1" "[$2] is not the start of [$full]" ;; esac ;;
  esac
}
is         "on a branch with commits the receipt names the branch" "$(_rf "$r" subject.branch)" "main"
_is_sha_of "and the commit it stands on"                           "$(_rf "$r" subject.head)"   "$STG"
# Detached, symbolic-ref has no answer and says nothing, so the reader has to
# fall through to the `HEAD` rev-parse always gave rather than to the fallback.
( _fx_cd "$RDR" && git checkout -q --detach ) >/dev/null 2>&1
_rdd="$(_rcpt_in "$RDR" "$RDB")"
is         "a detached HEAD is named HEAD, as it always was" "$(_rf "$_rdd" subject.branch)" "HEAD"
_is_sha_of "and still names its commit"                      "$(_rf "$_rdd" subject.head)"   "$RDR"
# And `?` is kept for the one state it is true of: no repository to ask.
# The directory that is no repository is 0220's NOGIT, the same two lines; this part
# alone makes its own.
NOGIT="$TMP/notgit"; mkdir -p "$NOGIT"; printf 'widget\n' > "$NOGIT/.felix"
_rng="$(_rcpt_in "$NOGIT")"
is  "a directory that is no repository has no branch to name" "$(_rf "$_rng" subject.branch)" "?"
is  "and no commit, which is not the same as an unborn one"   "$(_rf "$_rng" subject.head)"   "?"

# The class, not the instance. Two files held this expression and the first fix
# reached one of them. Comment lines are skipped because several of them quote
# the expression in order to explain it, this one included.
_appended="$(grep -nE '\$\([^()]*rev-parse[^()]*HEAD[^()]*\|\|[[:space:]]*(echo|printf)' \
               "$FROOT/harness/felix" "$FROOT"/harness/lib/*.sh "$FROOT"/harness/hooks/* "$FROOT"/harness/bin/* 2>/dev/null \
             | grep -vE '^[^:]*:[0-9]+:[[:space:]]*#')"
is  "no engine file appends a fallback to what git said about HEAD" "$_appended" ""

printf '\nthe bump is the deployment\n'
# `felix install` detected the exact condition, knew exactly what to do, and
# printed instructions: "Bump version in plugin.json, then re-run this." The
# charter calls that a defect in as many words — a command that prints a
# suggestion for something it could safely have done. The gate has now caught
# `installed` NINE times, every one of them a person typing the number the
# command already knew.
#
# Bumping is not a risky act. install already mutates: it is the thing that
# deploys. Refusing to change a patch digit while happily replacing the engine
# is caution in the wrong place.
VB="$TMP/verbump"; mkdir -p "$VB"
printf '{\n  "name": "felix",\n  "version": "0.9.3",\n  "author": {"name": "x"}\n}\n' > "$VB/plugin.json"
( . "$FROOT/harness/lib/resolve.sh"; felix_version_bump "$VB/plugin.json" ) >/dev/null
is "the patch digit goes up by one" \
   "$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$VB/plugin.json")" "0.9.4"
has "and the rest of the file is untouched" "$(cat "$VB/plugin.json")" '"name": "felix"'
has "including fields after it"             "$(cat "$VB/plugin.json")" '"author"'

( . "$FROOT/harness/lib/resolve.sh"; felix_version_bump "$VB/plugin.json" ) >/dev/null
is "and again, so a session can bump twice" \
   "$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$VB/plugin.json")" "0.9.5"

printf '{\n  "version": "1.0"\n}\n' > "$VB/short.json"
( . "$FROOT/harness/lib/resolve.sh"; felix_version_bump "$VB/short.json" ) >/dev/null; rc=$?
is "a version it cannot parse is refused, not guessed" "$rc" "1"
is "and is left exactly as it was" \
   "$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$VB/short.json")" "1.0"

( . "$FROOT/harness/lib/resolve.sh"; felix_version_bump "$VB/nope.json" ) >/dev/null; rc=$?
is "a missing manifest is refused" "$rc" "1"

printf '\nstaged content, not just staged names\n'
# The path list was fixed; the CONTENT readers were not. felix_escapes still
# read added lines from `base...HEAD` and read a file's current state with
# `git show HEAD:`, so on a branch with commits a staged change was named but
# never inspected. Half a fix reads exactly like a whole one from the outside.
SC2="$TMP/stagedcontent"; mkdir -p "$SC2"
( _fx_cd "$SC2" && git init -q -b main )
SC2="$(cd "$SC2" && pwd -P)"
printf 'widget\n' > "$SC2/.felix"
mkdir -p "$SC2/projects/thing"
{ printf '# tier\tkind\tpattern\treason\n'
  printf 'red\tpath\t^secrets/\tsecret material\n'
  printf 'red\tpath\t^auth/\tauthorization model\n'
} > "$SC2/projects/thing/risk.tsv"
printf 'notes\n' > "$SC2/a.md"
( _fx_cd "$SC2" && git add -A >/dev/null 2>&1 && git -c user.name=t -c user.email=t@t commit -qm base >/dev/null 2>&1 )
SC2_BASE="$(git -C "$SC2" rev-parse HEAD)"
printf 'more\n' >> "$SC2/a.md"
( _fx_cd "$SC2" && git add -A >/dev/null 2>&1 && git -c user.name=t -c user.email=t@t commit -qm ahead >/dev/null 2>&1 )

_sc() { ( cd "$SC2" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"
          . "$FROOT/harness/lib/review.sh"; . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
          felix_escapes "$FROOT/projects/widget" "$SC2_BASE" "$SC2" "$FROOT" ); }

# Destructive SQL, staged. The path is seen now; the added LINES were not.
printf 'DROP TABLE users;\n' >> "$SC2/a.md"
( _fx_cd "$SC2" && git add a.md >/dev/null 2>&1 )
has "staged destructive SQL still escapes as durable" "$(_sc)" "durable"
( _fx_cd "$SC2" && git checkout -q -- a.md 2>/dev/null; git reset -q HEAD a.md 2>/dev/null; git checkout -q -- a.md 2>/dev/null )

# A row removed from an enforcing table, staged. The verifier channel compares
# against `git show HEAD:`, which cannot see the index.
sed '/^red.path.\^auth/d' "$SC2/projects/thing/risk.tsv" > "$TMP/rt2" && mv "$TMP/rt2" "$SC2/projects/thing/risk.tsv"
( _fx_cd "$SC2" && git add projects >/dev/null 2>&1 )
has "a staged row removal still escapes as verifier" "$(_sc)" "verifier"
( _fx_cd "$SC2" && git reset -q HEAD projects 2>/dev/null; git checkout -q -- projects 2>/dev/null )

printf '\none tier for one table\n'
# Two functions read risk.tsv and disagreed about the same path, and the table's
# own header states the answer: "Anything matching no rule is yellow. Green must
# be earned by an explicit pattern, so an unfamiliar file can never auto-merge
# by being unrecognised."
#
# felix_classify_diff obeyed that. felix_incident_severity started at green and
# only ever escalated on a match, so an unrecognised path came back green — and
# that is the function `felix brief` uses, which is the surface the guidebook
# calls "report confidence". Found by running brief on a real issue naming a
# real file and not believing the answer.
RS="$TMP/riskdrift"; mkdir -p "$RS"
{ printf 'red\tpath\t^migrations/\tschema\n'
  printf 'green\tpath\t\\.md$\tdocumentation\n'
} > "$RS/risk.tsv"
_sev() { ( . "$FROOT/harness/lib/classify.sh"; . "$FROOT/harness/lib/incident.sh"
           felix_incident_severity "$RS" "$1" ); }
is "an unrecognised path is yellow, never green" "$(_sev 'src/whatever.py')" "yellow"
is "a path a green rule names is green"          "$(_sev 'README.md')"      "green"
is "a red rule still wins"                       "$(_sev 'migrations/1.sql')" "red"
is "and one unknown path taints a green set"     "$(_sev "$(printf 'README.md\nsrc/x.py')")" "yellow"
is "red beats an unknown too"                    "$(_sev "$(printf 'migrations/1.sql\nsrc/x.py')")" "red"

printf '\none rule for what a thing looks like\n'
# There were two matchers and they drifted. One scored a marketplace blurb, the
# other scored the name alone, nothing said they had to agree, and a plugin got
# installed under a capability the other matcher would not have given it.
CR="$(printf 'llm\tllm prompt eval evaluation\nfrontend\tpage component styling')"
_capmatch() { ( . "$FROOT/harness/lib/discover.sh"; felix_capability_match "$1" "$2" "$CR" ); }
is "a name counts triple"            "$(_capmatch eval-tool '' | cut -f1)" "3"
is "and prose counts single"         "$(_capmatch zzz 'about prompt things' | cut -f1)" "1"
# Three, not four: `eval` inside `evaluation` used to count as a second hit.
is "prose alone can still add up"    "$(_capmatch zzz 'an llm platform for prompt management and evaluation' | cut -f1)" "3"
# A keyword is a word. On the first live commissioning run `rag` matched
# google-cloud-sto*rag*e, scored the name hit that is also the adoption
# threshold, and a storage plugin was installed under llm.
CRG="$(printf 'llm\tllm rag inference\nfrontend\tpage')"
is "a keyword inside another word is not a match" \
   "$( . "$FROOT/harness/lib/discover.sh"; felix_capability_match google-cloud-storage '' "$CRG" | cut -f1 )" "0"
is "and a hyphenated name still matches its words" \
   "$( . "$FROOT/harness/lib/discover.sh"; felix_capability_match rag-toolkit '' "$CRG" | cut -f1 )" "3"
is "the best capability wins"        "$(_capmatch zzz 'page component styling' | cut -f2)" "frontend"
is "and nothing matching scores nil" "$(_capmatch zzz 'a database migration tool' | cut -f1)" "0"

# The manifest, not the listing. A catalogue blurb is written to be chosen from;
# a manifest is written to describe.
DD="$TMP/desc/.claude-plugin"; mkdir -p "$DD"
printf '{"name":"x","description":"an llm evaluation harness"}\n' > "$DD/plugin.json"
d="$( . "$FROOT/harness/lib/discover.sh"; felix_plugin_description "$TMP/desc" )"
has "reads a plugin's own description" "$d" "llm evaluation harness"
d="$( . "$FROOT/harness/lib/discover.sh"; felix_plugin_description "$TMP/nosuchdir" )"
is "and is silent when there is none" "$d" ""

printf '\nthe rules a project is scored against\n'
# The function gating the entire capability funnel, and nothing exercised it
# until the funnel was measured and found empty. Two projects declaring
# seven capabilities between them matched 4 of 35 installed plugins; the
# cause was not the matcher but this table, which is consulted row-first —
# so a capability nobody wrote a row for contributed nothing, silently and
# forever. another governed project declares `security` and no `security` row exists; `iac`
# is detectable and no row exists either.
DRT="$TMP/discover-rules"; mkdir -p "$DRT"
printf 'llm\tprompt eval\nfrontend\tfigma css\n' > "$DRT/discover-rules.tsv"
DRP="$TMP/discover-rules-proj"; mkdir -p "$DRP"
printf 'llm\nsecurity\nci\n' > "$DRP/capabilities"
_drules() { ( . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/discover.sh"
              _felix_discover_rules "$DRT" "$DRP" ); }
has "a declared capability with a row keeps its keywords" "$(_drules)" "llm	prompt eval"
# The capability's own name is the highest-precision keyword there is, and it
# is free. It was a keyword for only 4 of 12 rows, which is why a plugin
# named frontend-design matched nothing for a project declaring frontend.
has "and gains its own name as a keyword"        "$(_drules)" "llm"
has "a declared capability with NO row still scores on its name" "$(_drules)" "security	security"
# Short names are substrings of ordinary words — `ci` sits inside
# `specification`, `api` inside `rapid` — so they get no implicit keyword,
# and with no row they contribute nothing rather than everything.
case "$(_drules)" in
  *"ci	"*) bad "a short name is not turned into a keyword" "$(_drules)" ;;
  *)         ok  "a short name is not turned into a keyword" ;;
esac
# The gate that was already there and must stay: a project never sees rules
# for a capability it has not declared.
case "$(_drules)" in
  *frontend*) bad "an undeclared capability is still never scored" "$(_drules)" ;;
  *)          ok  "an undeclared capability is still never scored" ;;
esac

# Reported, not merely handled. A capability matching only on its own name is
# far thinner than a curated row, and nothing said which ones those were.
_dunruled() { ( . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/discover.sh"
                felix_capabilities_unruled "$DRP" "$DRT" | tr '\n' ' ' ); }
# Emission order decides ties — felix_capability_match keeps the first rule
# at equal score — so it must be the engine's, not a property of a file
# people reorder freely. Driving the loop from the capabilities file handed
# that authority to whichever line somebody happened to put first, and the
# `iac` row added here is the first pair in the table's history that can
# actually tie: it shares `terraform` with `deploy`, and a plugin named
# terraform exists.
DRO="$TMP/discover-order"; mkdir -p "$DRO"
printf 'deploy\tterraform helm\niac\tterraform pulumi\n' > "$DRO/discover-rules.tsv"
DRO1="$TMP/dro-a"; DRO2="$TMP/dro-b"; mkdir -p "$DRO1" "$DRO2"
printf 'deploy\niac\n' > "$DRO1/capabilities"
printf 'iac\ndeploy\n' > "$DRO2/capabilities"
_dmatch() { ( . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/discover.sh"
              felix_capability_match terraform '' "$(_felix_discover_rules "$DRO" "$1")" | cut -f2 ); }
is "a tie is broken the same way whichever order the file lists" \
   "$(_dmatch "$DRO1")" "$(_dmatch "$DRO2")"
is "and it is broken by the engine's table, not the file"        "$(_dmatch "$DRO1")" "deploy"

# The name is appended, not duplicated: two rows already list their own name
# as the first keyword, and felix_capability_match adds 3 per occurrence with
# no dedup, so those two scored a name hit twice.
DRD="$TMP/discover-dup"; mkdir -p "$DRD"
printf 'observability\tobservability tracing\n' > "$DRD/discover-rules.tsv"
DRDP="$TMP/dro-dup"; mkdir -p "$DRDP"; printf 'observability\n' > "$DRDP/capabilities"
is "a row already naming itself is not scored twice" \
   "$( . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/discover.sh"
       felix_capability_match observability-tool '' "$(_felix_discover_rules "$DRD" "$DRDP")" | cut -f1 )" "3"

# felix_declared strips whole-line comments only, so a line carrying a
# trailing remark survived as one capability. Row-first it matched no row and
# vanished; capability-first it would have become its own keyword and a
# capability name that discover --adopt writes into stack.tsv.
DRC="$TMP/dro-comment"; mkdir -p "$DRC"
printf 'deploy   # only staging, never prod\nfrontend\n' > "$DRC/capabilities"
_drc="$( . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/discover.sh"
         _felix_discover_rules "$DRT" "$DRC" )"
case "$_drc" in
  *"only staging"*) bad "a capability carrying a trailing remark is not a rule" "$_drc" ;;
  *)                ok  "a capability carrying a trailing remark is not a rule" ;;
esac

has "an unruled capability is named"        "$(_dunruled)" "security"
case "$(_dunruled)" in
  *llm*) bad "and a ruled one is not" "$(_dunruled)" ;;
  *)     ok  "and a ruled one is not" ;;
esac

# The structural half: detection can adopt a capability automatically, so a
# capability it can emit with no row is a gap that appears on somebody else's
# schedule. `iac` was exactly that — the day a project grows terraform.
_detectable="$(grep -oE '&& echo [a-z0-9]+' "$FROOT/harness/lib/detect.sh" | awk '{print $3}' | sort -u)"
_ruled="$(grep -vE '^[[:space:]]*(#|$)' "$FROOT/harness/templates/discover-rules.tsv" | cut -f1 | sort -u)"
_gap="$(comm -23 <(printf '%s\n' "$_detectable") <(printf '%s\n' "$_ruled") | tr '\n' ' ')"
_gap="${_gap% }"
is "every capability detection can adopt has a discovery rule" "$_gap" ""

printf '\nmatching reads what a plugin ships, not what it is called\n'
# Decision C step 2 (2026-08-30). The inspect read already opens the copy on
# disk; its skills list is a manifest fact, and a skill name says what a thing
# SHIPS the way a plugin name says what it IS. Both count triple; a listing's
# prose stays worth one.
DCF="$TMP/dcfunnel"; mkdir -p "$DCF/skills/prompt-eval" "$DCF/skills/db-notes"
facts="$( . "$FROOT/harness/lib/discover.sh"; felix_discover_inspect "$DCF" )"
has "inspect still counts the skills"  "$facts" "skills	2"
has "and now names each one it found"  "$facts" "skill	prompt-eval"
is "naming skills does not change the risk read" \
   "$( . "$FROOT/harness/lib/discover.sh"; felix_discover_risk "$facts" )" "low"

_cm4() { ( . "$FROOT/harness/lib/discover.sh"; felix_capability_match "$1" "$2" "$CR" "$3" ); }
is "a skill name counts triple, like a name"    "$(_cm4 zzz '' 'prompt-eval' | cut -f1)" "6"
is "and picks the capability the skills serve"  "$(_cm4 zzz '' 'prompt-eval' | cut -f2)" "llm"
is "skills matching nothing add nothing"        "$(_cm4 zzz '' 'db-notes' | cut -f1)" "0"
is "name and skills accumulate as evidence"     "$(_cm4 eval-tool '' 'prompt-eval' | cut -f1)" "9"
is "prose still counts single beside skills"    "$(_cm4 zzz 'an llm platform' 'db-notes' | cut -f1)" "1"

# The installed-plugin path, which is the one the toolbox report reads. A
# plugin whose name and blurb say nothing is matched by what its directory
# actually ships; one whose skills serve nothing declared stays unmatched.
TBS="$TMP/tbskills"; mkdir -p "$TBS/skills/prompt-eval" "$TBS/.claude-plugin"
printf '{"name":"zzz","description":"assorted utilities"}\n' > "$TBS/.claude-plugin/plugin.json"
cap="$( . "$FROOT/harness/lib/discover.sh"; . "$FROOT/harness/lib/toolbox.sh"
        felix_toolbox_capability zzz "$CR" "$TBS" )"
is "an installed plugin is matched by what it ships" "$cap" "llm"
TBN="$TMP/tbnothing"; mkdir -p "$TBN/skills/db-notes" "$TBN/.claude-plugin"
printf '{"name":"zzz","description":"assorted utilities"}\n' > "$TBN/.claude-plugin/plugin.json"
cap="$( . "$FROOT/harness/lib/discover.sh"; . "$FROOT/harness/lib/toolbox.sh"
        felix_toolbox_capability zzz "$CR" "$TBN" )"
is "and shipping nothing declared still matches nothing" "$cap" ""

