printf '\nthe pre-flight\n'
_user_prompt_hook_vars; _widget_repo_build; _router_build routed
# A skill can be invoked mid-turn; a plugin that is switched off cannot be
# switched on without a restart. So whether the router's picks will actually
# work is decided before a session starts, and it differs per project.
mkdir -p "$HOME/.claude/skills" 2>/dev/null || true
cat >> "$FROOT/projects/widget/stack.tsv" <<'EOF'
skill	widget-only-skill	-	low	always
EOF
cat >> "$FROOT/projects/widget/routes.tsv" <<'EOF'
preflight	preflightword	frontend	widget-only-skill never-declared-tool
EOF
out="$(cd "$REPO" && "$FELIX" ready 2>&1)"
has "reports a tool no manifest declares" "$out" "never-declared-tool"
has "and says why"                        "$out" "absent from stack.tsv"
# A standalone skill is a directory, not a package. Looking for it in the
# plugin list reported a working skill as missing, which is how a pre-flight
# check earns being ignored.
has "knows a standalone skill is not a plugin" "$out" "widget-only-skill"
case "$out" in
  *"widget-only-skill"*"not installed"*) bad "a skill is not looked up as a plugin" "$out" ;;
  *) ok "a skill is not looked up as a plugin" ;;
esac
# #77 item 1. This was one `case` accepting `could not be checked` OR `cannot be
# used` OR `switched on.` — and those three exhaust every summary cmd_ready can
# print, so it was true by construction. Deleting the entire `unknown` block
# from cmd_ready left it green.
#
# It survived for a specific reason worth recording: the widget fixture declares
# `widget-only-skill` whose directory is never created, so `bad` is at least 1
# on every machine, `cannot be used` is always in the output, and the assertion
# matched through that branch no matter what the unknown block did.
#
# So the fix is not a better pattern over the same output. It is constructing
# each state deliberately and pinning the summary that belongs to it — and
# asserting the summaries that must NOT appear, which is the half that makes it
# falsifiable. All three states are reachable with no claude CLI, which is what
# lets this run on CI.
_RDH="$TMP/readyhome"; _RDP="$FROOT/projects/widget"
cp "$_RDP/routes.tsv" "$TMP/rd.routes.keep"; cp "$_RDP/stack.tsv" "$TMP/rd.stack.keep"
_ready_state() {  # $1 = a PATH to run with
  ( cd "$REPO" && HOME="$_RDH" PATH="$1" "$FELIX" ready 2>&1 )
}
_NOCLI="/usr/bin:/bin"

# clean — every named tool declared, and its skill directory present.
mkdir -p "$_RDH/.claude/skills/present-skill"
printf 'skill\tpresent-skill\t-\tlow\talways\n' > "$_RDP/stack.tsv"
printf 'preflight\tpreflightword\tfrontend\tpresent-skill\n' > "$_RDP/routes.tsv"
_rd="$(_ready_state "$_NOCLI")"
has "a fully declared, present inventory reads clean" "$_rd" "switched on."
case "$_rd" in
  *"could not be checked"*) bad "and claims nothing was unchecked" "$_rd" ;;
  *)                        ok  "and claims nothing was unchecked" ;;
esac
case "$_rd" in
  *"cannot be used"*) bad "and nothing unusable" "$_rd" ;;
  *)                  ok  "and nothing unusable" ;;
esac

# unknown, via `undeclared` — a route names a tool no manifest declares.
printf 'preflight\tpreflightword\tfrontend\tpresent-skill nowhere-declared\n' > "$_RDP/routes.tsv"
_rd="$(_ready_state "$_NOCLI")"
has "a tool absent from the manifest is not a clean bill" "$_rd" "could not be checked"
case "$_rd" in
  *"switched on."*) bad "and the clean sentence is withheld" "$_rd" ;;
  *)                ok  "and the clean sentence is withheld" ;;
esac

# unknown, via `unknown` — a PLUGIN row with no claude CLI to check it against.
# A separate fixture from the one above on purpose: narrowing cmd_ready's
# counter from `^(unknown|undeclared)` to `^(unknown)` is invisible to the
# undeclared case and only this one catches it.
printf 'plugin\tsome-plugin\t-\tlow\talways\n' > "$_RDP/stack.tsv"
printf 'preflight\tpreflightword\tfrontend\tsome-plugin\n' > "$_RDP/routes.tsv"
_rd="$(_ready_state "$_NOCLI")"
has "a plugin that cannot be checked is not a clean bill" "$_rd" "could not be checked"
has "and says why it could not be"                       "$_rd" "no claude CLI"

# bad — a declared skill whose directory is not there.
printf 'skill\tmissing-skill\t-\tlow\talways\n' > "$_RDP/stack.tsv"
printf 'preflight\tpreflightword\tfrontend\tmissing-skill\n' > "$_RDP/routes.tsv"
_rd="$(_ready_state "$_NOCLI")"
has "a declared skill with no directory cannot be used" "$_rd" "cannot be used"
case "$_rd" in
  *"switched on."*) bad "and that is not a clean bill either" "$_rd" ;;
  *)                ok  "and that is not a clean bill either" ;;
esac
case "$_rd" in
  *"could not be checked"*) bad "and it is reported as unusable, not unchecked" "$_rd" ;;
  *)                        ok  "and it is reported as unusable, not unchecked" ;;
esac

# #80. `felix ready --fix` had no return after its repair loop, so its status was
# the trailing printf's — 0, whatever happened. A run where every repair failed
# exited exactly like one that fixed everything, and the per-row prose that
# distinguishes them is aggregated by no summary line, so there was nothing for a
# caller or a test to pin. Same species as the two defects #77 closed: a report
# whose failing state is indistinguishable from its passing one.
#
# Safe to give it a real status: nothing in the tree consumes this exit code.
# The only place that runs the command is this file, and it captures output
# rather than rc.
_RDB="$TMP/readyfixbin"; mkdir -p "$_RDB"
printf '#!/usr/bin/env bash\nexit 1\n' > "$_RDB/claude"; chmod +x "$_RDB/claude"
printf 'skill\tmissing-skill\t-\tlow\talways\n' > "$_RDP/stack.tsv"
printf 'preflight\tpreflightword\tfrontend\tmissing-skill\n' > "$_RDP/routes.tsv"

_fixout="$( cd "$REPO" && HOME="$_RDH" PATH="$_RDB:$_NOCLI" "$FELIX" ready --fix 2>&1 )"; _fixrc=$?
has "a repair that failed says so" "$_fixout" "FAILED"
[ "$_fixrc" -ne 0 ] && ok "and --fix does not exit 0 when every repair failed" \
                    || bad "and --fix does not exit 0 when every repair failed" \
                           "exit $_fixrc after: $_fixout"
# The count, not just the word, so a run that repaired some and failed others is
# still distinguishable from one that repaired everything.
has "and says how many are still unusable" "$_fixout" "still cannot be used"

# Refused-on-risk is not repaired either. It is the case most likely to be read
# as success, because nothing failed — Felix simply declined to act.
printf 'skill\tmissing-skill\t-\thigh\talways\n' > "$_RDP/stack.tsv"
_refout="$( cd "$REPO" && HOME="$_RDH" PATH="$_RDB:$_NOCLI" "$FELIX" ready --fix 2>&1 )"; _refrc=$?
has "a refusal on risk is reported"  "$_refout" "refused"
# And it carries the policy's own words. Without this the assertion above
# passes whether or not the call reaches admit.sh: an undefined felix_admit
# substitutes empty, empty is not "install", and the refusal branch prints the
# same word. This is the only line here that can tell a policy from a typo.
has "and in the policy's own words, which is what proves the call reached it" \
    "$_refout" "high risk, install by hand"
# And a medium row the engine grounded is refused here too, by the same
# policy, in its words: this is the second caller that used to assume every
# manifest row was a person's.
# A skill, and a route naming it, exactly as every sibling in this block does.
# Two reasons, both learned by getting it wrong: `felix ready` reports what a
# ROUTE names and cannot reach, so a stack row nothing points at is never
# listed; and this block runs with no claude CLI on PATH, which is what lets it
# run on CI, so a plugin's installed state cannot be checked at all and reads
# `could not be checked` rather than `absent`. A skill is a directory, and its
# absence is answerable with no CLI.
printf 'skill\tfelix-test-obsmed\t-\tmedium\talways\tOBSERVED\n' > "$_RDP/stack.tsv"
printf 'preflight\tpreflightword\tfrontend\tfelix-test-obsmed\n' > "$_RDP/routes.tsv"
_obsout="$( cd "$REPO" && HOME="$_RDH" PATH="$_RDB:$_NOCLI" "$FELIX" ready --fix 2>&1 )"
has "ready --fix reads the grounding off the row"     "$_obsout" "refused"
has "and holds an engine-grounded medium for a person" "$_obsout" "a person decides"
[ "$_refrc" -ne 0 ] && ok "and a refusal is not a successful repair" \
                    || bad "and a refusal is not a successful repair" \
                           "exit $_refrc after: $_refout"

cp "$TMP/rd.routes.keep" "$_RDP/routes.tsv"; cp "$TMP/rd.stack.keep" "$_RDP/stack.tsv"
is "the widget's tables are as this block found them" \
   "$(diff -q "$TMP/rd.routes.keep" "$_RDP/routes.tsv" >/dev/null \
      && diff -q "$TMP/rd.stack.keep" "$_RDP/stack.tsv" >/dev/null && echo same)" "same"
# Felix has to know the whole inventory, not just its own list. A table naming
# one plugin five times while thirty others sit idle is a habit, not a router.
# This section also guards a bash-3.2 trap: a `case` pattern's closing paren
# inside $( ) ends the substitution, which parses fine under zsh and dies the
# moment the real CLI runs it. Only running the CLI catches that.
# Only where the CLI can see a plugin installed here: a unit of P's run has a HOME of its own (slice 3, A17), and
# under the land tick's environment the CLI then lists none, which reads as a machine with nothing installed.
if has_claude && [ "$(claude plugin list --json 2>/dev/null | LC_ALL=C grep -c '"id"')" -gt 0 ]; then
  case "$out" in
    *"never reached for"*) ok "reports what is installed but unused" ;;
    *) bad "reports what is installed but unused" "$out" ;;
  esac
else
  skip "reports what is installed but unused" "no claude CLI, or one that lists no plugin"
fi
case "$out" in
  *"syntax error"*|*"unbound variable"*) bad "the pre-flight runs clean under bash" "$out" ;;
  *) ok "the pre-flight runs clean under bash" ;;
esac

printf '\nkeeping what Felix said\n'
# Everything Felix tells a session goes out as additionalContext, which reaches
# the model and never the terminal. The logs recorded which route fired and
# what it scored; they did not record the words, so "why did Claude suddenly
# start using that skill" was unanswerable from anything Felix kept.
SP="$FROOT/projects/widget"
rm -f "$MEM/widget/says.log"
( . "$FROOT/harness/lib/say.sh"
  felix_say "$SP" "brief" "line one
line two" "why I asked" "sess-42" )
[ -s "$MEM/widget/says.log" ] && ok "records what it said" || bad "records what it said"
n="$(wc -l < "$MEM/widget/says.log" | tr -d ' ')"
is "a multi-line utterance stays one greppable line" "$n" "1"
has "and keeps the session it was said in" "$(cut -f3 "$MEM/widget/says.log")" "sess-42"
has "and keeps the prompt that caused it"   "$(cut -f4 "$MEM/widget/says.log")" "why I asked"
has "with the newlines escaped, not lost"   "$(cut -f5 "$MEM/widget/says.log")" 'line one\nline two'

# The hook must record the same words it sends, or the page is fiction.
rm -f "$MEM/widget/says.log"
out="$(cd "$REPO" && printf '{"session_id":"sayer","prompt":"the migration schema needs an index"}' | "$RHK" 2>&1)"
sent="$(_ctx "$out" | head -1)"
kept="$(cut -f5 "$MEM/widget/says.log" 2>/dev/null | head -1 | sed 's/\\n.*//')"
is "what it kept is what it sent" "$kept" "$sent"
has "and the cause is the prompt, not the envelope" \
    "$(cut -f4 "$MEM/widget/says.log" 2>/dev/null)" "migration schema"
case "$(cut -f4 "$MEM/widget/says.log" 2>/dev/null)" in
  *session_id*) bad "the cause is not the raw payload" "carried the envelope" ;;
  *) ok "the cause is not the raw payload" ;;
esac

# ...and the page shows it verbatim.
out="$(cd "$REPO" && "$FELIX" monitor --log 2>&1)"
MON2="$FROOT/state/monitor.html"
grep -q '"says"' "$MON2" && ok "the page carries the speech" || bad "the page carries the speech"
grep -q 'migration schema needs an index' "$MON2" \
  && ok "including what prompted each utterance" || bad "including what prompted each utterance"

  # A column was inserted into the middle of this record once. Read as the new
  # shape, an old line puts its text where the cause belongs, and the page
  # attributes a gate verdict to a prompt nobody typed. Both shapes must read.
  printf '%s\told-shape\tno session here\tthe words\n' "2020-01-01T00:00:00Z" >> "$MEM/widget/says.log"
  ( cd "$REPO" && "$FELIX" monitor --log >/dev/null 2>&1 )
  if grep -q '"kind":"old-shape","session":"","cause":"no session here","text":"the words"' "$MON2"; then
    ok "a record from before the session column still reads"
  else
    bad "a record from before the session column still reads" \
        "$(grep -o '"kind":"old-shape"[^}]*' "$MON2" | head -1)"
  fi

printf '\nupkeep that can never come due\n'
# `felix maintenance` printed "Nothing due" for four routines that had never run
# and never could. The capability column takes `always` or a capability the
# project declares; Felix's own table used `-`, which is neither, so every row
# resolved to dormant and the report read exactly like a well-kept repository.
#
# Same shape as the ledger overclaim and the coverage table before it: a surface
# saying "nothing to do" when the truth is "nothing is being checked". Found by
# building the thing that ranks upkeep, not by reading the table.
MT="$TMP/maintcheck"; mkdir -p "$MT" "$MEM/maintcheck"
printf '{"name":"maintcheck","gate":"true"}\n' > "$MT/project.json"
{ printf 'good\t7\talways\tthis one can come due\n'
  printf 'typo\t7\t-\tthis one never can\n'
  printf 'gated\t7\tci\tonly when ci is declared\n'
} > "$MT/maintenance.tsv"
u="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
      . "$FROOT/harness/lib/stack.sh"; . "$FROOT/harness/lib/maintenance.sh"
      felix_maint_unreachable "$MT" )"
has "a row naming no real capability is caught" "$u" "typo"
case "$u" in
  *good*)  bad "an always row is not flagged" "$u" ;;
  *)       ok  "an always row is not flagged" ;;
esac
# `ci` is a real capability that this project has simply not declared. That is a
# dormant row working as intended, not a broken one, and flagging it would make
# the check noise.
case "$u" in
  *gated*) bad "a real capability left undeclared is not an error" "$u" ;;
  *)       ok  "a real capability left undeclared is not an error" ;;
esac

# And the shipped tables, which is where the bug actually was.
for _p in "$FELIX_HOME"/projects/*/; do :; done
u="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
      . "$FROOT/harness/lib/stack.sh"; . "$FROOT/harness/lib/maintenance.sh"
      for p in "$(cd "$REAL_HARNESS/../.." && pwd)"/projects/*/; do
        [ -f "$p/maintenance.tsv" ] && felix_maint_unreachable "${p%/}"
      done )"
is "no shipped upkeep row is unreachable" "$(printf '%s' "$u" | tr -d '\n ')" ""

# And something calls it. The guard was written for the "Nothing due" lesson
# and then wired to nothing: every surface that reads maintenance keeps `^due`
# alone — cmd_maintenance, the session badge, felix next's rank 4, the pulse —
# so a row whose capability nothing declares renders as a bare dash beside
# "Nothing due." forever, on all of them. A guard nobody calls is the lesson it
# was written about, one level down.
printf 'ghostrow\t7\tnosuchcapability\ta row nothing can satisfy\n' >> "$FROOT/projects/widget/maintenance.tsv"
_mo="$(cd "$REPO" && "$FELIX" maintenance 2>&1)"
has "felix maintenance says a row can never come due"  "$_mo" "ghostrow"
has "and does not leave it as a bare dash"             "$_mo" "can never come due"
_mn="$(cd "$REPO" && "$FELIX" next 2>&1)"
has "felix next ranks it under the checks that are not checking" "$_mn" "waits on a capability nothing declares"
grep -v 'ghostrow' "$FROOT/projects/widget/maintenance.tsv" > "$TMP/maint.tmp"
mv "$TMP/maint.tmp" "$FROOT/projects/widget/maintenance.tsv"
is "and the widget table is as this block found it" \
   "$(grep -c ghostrow "$FROOT/projects/widget/maintenance.tsv")" "0"

printf '\nan engine a marketplace does not serve\n'
# `felix install` from a worktree bumps the manifest, runs the three plugin
# commands, finds the cache unchanged and says "this is no longer the version
# cache; something else is wrong" — which sends you hunting for corruption. A
# directory marketplace is pinned to one path. The worktree's engine is not the
# engine being served, the cache still matches the tree that is, and nothing is
# broken. Same shape as every other failure in section 8 of the handoff: correct
# code, wrong place, and a message that described the code.
MKT="$TMP/known_marketplaces.json"
cat > "$MKT" <<'MJ'
{
  "other": { "installLocation": "/somewhere/else" },
  "felix": {
    "source": { "source": "directory", "path": "/Users/x/Felix" },
    "installLocation": "/Users/x/Felix"
  }
}
MJ
mroot="$( . "$FROOT/harness/lib/resolve.sh"; felix_marketplace_root "$MKT" )"
is "the registry says where the engine is served from" "$mroot" "/Users/x/Felix"

( . "$FROOT/harness/lib/resolve.sh"; felix_deployable_from "/Users/x/Felix/engine" "$MKT" >/dev/null ) \
  && ok  "an engine under that path can deploy" \
  || bad "an engine under that path can deploy"

wt="$( . "$FROOT/harness/lib/resolve.sh"
       felix_deployable_from "/Users/x/Felix/.claude/worktrees/w1/engine" "$MKT" )" && rc=0 || rc=1
is "a worktree engine cannot"                    "$rc"  "1"
is "and it names the tree that can, not a fault" "$wt"  "/Users/x/Felix"

# No registry at all is not an accusation: an engine nobody has registered yet
# is the ordinary first-install case, and must not be told it is in a worktree.
( . "$FROOT/harness/lib/resolve.sh"; felix_deployable_from "/anywhere/engine" "$TMP/absent.json" >/dev/null ) \
  && ok  "an unregistered marketplace makes no claim either way" \
  || bad "an unregistered marketplace makes no claim either way"

printf '\na local that reads a local\n'
# `local proj="$1" log="$proj/memory/routes.log"` — bash expands every word of
# the statement before it assigns any of them, so `$proj` was read before it
# existed and the path came out as `/memory/routes.log`. The function then found
# no file and returned nothing, silently.
#
# It survived because of where it ran. `cmd_route` declares its own `proj`, and
# bash's dynamic scoping handed that one to the callee — so the single caller
# anybody exercised got the right answer and every other caller got silence. A
# lesson would not have caught this: the line reads correctly, and it was correct
# in the only place it was ever looked at. That is this project's oldest failure
# shape, so it goes where a check can see it instead.
# The scanner lives in a file and takes its root as an argument, so the proof
# that it can fail runs THE SCANNER. The first version of this asserted against a
# retyped copy of the same regex — which meant breaking the real scanner left the
# suite green while the proof went on passing, in the check whose entire purpose
# is catching things that cannot fail. Found by an adversarial audit of this
# file, which is the correct way to find it and an uncomfortable place for it to
# have been.
SR="$TMP/selfref.py"
cat > "$SR" <<'PY'
import re, glob, os, sys
root, out = sys.argv[1], []
for pat in sys.argv[2:]:
    for f in glob.glob(os.path.join(root, pat)):
        if not os.path.isfile(f):
            continue
        for i, line in enumerate(open(f, encoding="utf-8", errors="replace"), 1):
            s = line.strip()
            if not s.startswith("local "):
                continue
            seen = set()
            for m in re.finditer(r'(?:^|\s)([A-Za-z_][A-Za-z0-9_]*)=(\S*)', s[6:]):
                for ref in re.findall(r'\$\{?([A-Za-z_][A-Za-z0-9_]*)', m.group(2)):
                    if ref in seen:
                        out.append("%s:%d" % (os.path.basename(f), i))
                seen.add(m.group(1))
print(" ".join(sorted(set(out))))
PY
# The suite's own files come from _suite_files (every part, every tests/lib file,
# the driver), as every check that reads the suite's text takes them, and not
# from a glob of this part's own; the scanner takes a path that is absolute as it is.
_sr_suite=(); while IFS= read -r _sr_f; do _sr_suite[${#_sr_suite[@]}]="$_sr_f"; done < <(_suite_files)
selfref="$(python3 "$SR" "$(cd "$REAL_HARNESS/.." && pwd)" \
           "harness/lib/*.sh" "harness/felix" "harness/hooks/*" "${_sr_suite[@]}")"
is "no local assignment reads one declared beside it" "$selfref" ""

# The same scanner, against a planted instance of the exact shape. If somebody
# breaks the scanner, this goes red too — which is the property the retyped copy
# did not have.
#
# Assembled rather than written out, because this file is one of the roots the
# scanner sweeps: a heredoc containing the literal bad line makes tests/run
# itself a hit, and the check reports a defect it planted. The fixture holds the
# shape; this file never contains it.
SRF="$TMP/selfreffix/harness/lib"; mkdir -p "$SRF"
{ printf 'demo() {\n'
  printf '  local proj="%s1" log="%sproj/memory/routes.log"\n' '$' '$'
  printf '  printf "%%s" "%slog"\n' '$'
  printf '}\n'
} > "$SRF/planted.sh"
planted="$(python3 "$SR" "$TMP/selfreffix" "harness/lib/*.sh")"
has "and the same scanner catches a planted one" "$planted" "planted.sh"

printf '\na lesson that is not working\n'
# `felix promote` knew the gate had caught the same check eight times and then
# asked a person to type `felix lesson "..."`. That is the defect the charter
# names: it had the finding and handed back the work.
#
# Converting it does not mean writing the prose — a lesson is judgement and a
# fabricated one pollutes the file that gets matched into every prompt. What is
# mechanical is the distinction promote's own closing line draws and never acts
# on: a recurrence with no lesson behind it needs one written, and a recurrence
# that already HAS a lesson means the lesson is not working and the fix belongs
# somewhere the gate can see.
PM="$TMP/promoteproj"; mkdir -p "$PM" "$MEM/promoteproj"
printf '{"name":"promoteproj","gate":"true"}\n' > "$PM/project.json"
# Relative dates, because liveness is now part of what is asserted and a fixture
# of literal dates is a test that passes until a fortnight after it was written.
_ago() { date -v-"$1"d +%Y-%m-%d 2>/dev/null || date -d "$1 days ago" +%Y-%m-%d 2>/dev/null; }
{ printf '%s\tmain\taaa\tflaky \n'      "$(_ago 3)"
  printf '%s\tmain\tbbb\tflaky \n'      "$(_ago 2)"
  printf '%s\tmain\tccc\tuncovered \n'  "$(_ago 3)"
  printf '%s\tmain\tddd\tuncovered \n'  "$(_ago 1)"
  printf '%s\tmain\teee\tsettled \n'    "$(_ago 90)"
  printf '%s\tmain\tfff\tsettled \n'    "$(_ago 89)"
  printf '%s\tmain\tggg\tsettled \n'    "$(_ago 88)"
  printf '%s\tmain\thhh\tdrifting \n'   "$(_ago 2)"
  printf '%s\tmain\tiii\tdrifting \n'   "$(_ago 1)"
} > "$MEM/promoteproj/mistakes.log"
{ printf -- '- **Something about `flaky` things.** It was written down.\n'
  # Names the word and is not about the check. The real lessons file says
  # "executing the installed hooks by hand" and "cannot be uninstalled", and a
  # substring test read both as a lesson about the `installed` gate check.
  printf -- '- **A note that mentions drifting in passing.** Not about that check.\n'
} > "$MEM/promoteproj/lessons.md"

_pnext() { ( cd "$REPO" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
             . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
             . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/evidence.sh"
             . "$FROOT/harness/lib/maintenance.sh"; . "$FROOT/harness/lib/stack.sh"
             . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/ledger.sh"
             . "$FROOT/harness/lib/coverage.sh"; . "$FROOT/harness/lib/deny.sh"
             . "$FROOT/harness/lib/memory.sh"; . "$FROOT/harness/lib/next.sh"
             felix_next "$PM" "$FROOT" "$REPO" HEAD~1 ); }

n="$(_pnext)"
has "a recurrence with no lesson says to write one" "$n" "uncovered"
has "and names the command that writes it"          "$n" "felix lesson"
has "a recurrence that already has a lesson is different" "$n" "flaky"
case "$(printf '%s\n' "$n" | grep flaky)" in
  *"felix lesson"*) bad "and does not ask for a lesson that already exists" "$n" ;;
  *)                ok  "and does not ask for a lesson that already exists" ;;
esac
has "it says the lesson is not working" "$(printf '%s\n' "$n" | grep flaky)" "not working"

# A recurrence that stopped recurring is history. It kept its lifetime count and
# so kept its place at the rank the code itself calls the strongest signal there
# is — nine `installed` failures, every one before the fix landed, ranked above
# whatever is costing time today. A permanent row at that rank is how a ranked
# list stops being read. `felix_guard_unrecorded` already draws this line at the
# whole file; this draws it per term, where the recurrence is counted.
case "$n" in
  *settled*) bad "a recurrence that stopped recurring is not still ranked" "$n" ;;
  *)         ok  "a recurrence that stopped recurring is not still ranked" ;;
esac
has "and a live one says when it was last caught" "$n" "$(_ago 1)"

# The lesson test read a substring of the whole file, so an ordinary English
# word anywhere in it counted as a lesson about a check of that name — and then
# sent you to build a mechanism for a lesson that was never written.
case "$(printf '%s\n' "$n" | grep drifting)" in
  *"felix lesson"*) ok  "a passing mention is not a lesson about the check" ;;
  *)                bad "a passing mention is not a lesson about the check" "$n" ;;
esac

# A check name is usually written as the head of a path, because that is what it
# is — `tests/run`, `memory/verification.log`. The follow-class allowed a
# backtick, dot, underscore or hyphen after the term and not a slash, so `tests`
# and `memory`, two of Felix's own seven gate checks, read as "no lesson mentions
# it" against a lessons file that discusses both at length. The advice that
# follows is the opposite of the right one: write the prose, when the prose is
# already there and something else is wrong.
#
# Asserted against the shipped lessons file as well as a fixture, because the
# fixture is what missed it — every fixture path in this suite was written as a
# bare filename, which is not how anyone writes one.
LN="$TMP/lessonnames"; mkdir -p "$LN" "$MEM/lessonnames"
{ printf -- '- **On the suite.** `tests/run` computes its path from `$0`.\n'
  printf -- '- **On records.** `memory/verification.log` is where a gate receipt lands.\n'
} > "$MEM/lessonnames/lessons.md"
_lname() { ( . "$FROOT/harness/lib/memory.sh"; felix_mem_lesson_names "$LN" "$1" ) && printf yes || printf no; }
is "a check named as the head of a path is found"  "$(_lname tests)"  "yes"
is "and so is the other one"                       "$(_lname memory)" "yes"
is "a name nothing mentions is still not found"    "$(_lname secret)" "no"

REALDIR="$(cd "$REAL_HARNESS/../.." && pwd)"
REALMEM="${HOME}/.felix/memory/felix/lessons.md"
if [ -f "$REALMEM" ]; then
  RL="$TMP/reallessons"; mkdir -p "$RL" "$MEM/reallessons"
  cp "$REALMEM" "$MEM/reallessons/lessons.md"
  _rname() { ( . "$FROOT/harness/lib/memory.sh"; felix_mem_lesson_names "$RL" "$1" ) && printf yes || printf no; }
  # Only the names the shipped file demonstrably discusses, so this asserts the
  # matcher rather than the prose. Both appear there inside backticks as paths.
  is "and it holds against the shipped lessons file" "$(_rname tests)"  "yes"
  is "for every gate check that file actually covers" "$(_rname memory)" "yes"
else
  # THESE TWO ARE #67. This block had no else, so on a machine with no Felix
  # memory — every CI runner — both assertions simply did not run. No pass, no
  # fail, no skip line: they were absent, and absence is indistinguishable from
  # a passing suite. That is the whole of the constant 2-assertion gap between
  # local and CI, measured across three commits before anything could name it.
  #
  # Skipped rather than made to work. The assertion's value is that it holds
  # against a REAL lessons file rather than a fixture, so there is nothing to
  # run against here and pretending otherwise would be the weaker test. What
  # changes is that the absence is now declared.
  skip "and it holds against the shipped lessons file"  "no lessons file on this machine"
  skip "for every gate check that file actually covers" "no lessons file on this machine"
fi

# Nothing recurring is silence, not a reassurance.
: > "$MEM/promoteproj/mistakes.log"
n="$(_pnext)"
case "$n" in
  *flaky*|*uncovered*) bad "no recurrence says nothing at all" "$n" ;;
  *)                   ok  "no recurrence says nothing at all" ;;
esac

