_widget_repo_build
_plain_build
printf '\nwhat to do next\n'
# Felix tracked maintenance, drift, setup gaps, evidence gaps and coverage in
# five separate commands and never once said which of them mattered. A founder
# reading five reports to work out the order is doing exactly the job Felix
# exists to take.
#
# The ranking is anchored on the declared objective — founder interruptions per
# session — and then on what is blocking now. So the order is: work Felix owes
# on the change in hand, then the things that will interrupt a future session,
# then rot that will quietly mislead one.
NX="$TMP/nextproj"; mkdir -p "$NX" "$MEM/nextproj"
printf '{"name":"nextproj","gate":"true"}\n' > "$NX/project.json"
: > "$NX/routes.tsv"; : > "$NX/stack.tsv"
# One probe, so a receipt written for this project carries an epoch, and the
# receipt below is written for THIS project rather than for the one the
# repo's marker names: the reader is handed $NX, and a receipt stamped under
# another project's epoch reads as the facts having moved.
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$NX/probes.tsv"

# Sourced the way the CLI sources them. A short list here passed a `dormant`
# maintenance row for a fixture that was plainly due, because the capability
# check silently degrades when its helpers are absent — the test would have
# been asserting the absence of a library.
_next() { ( cd "$REPO" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
            . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
            . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/evidence.sh"
            . "$FROOT/harness/lib/maintenance.sh"; . "$FROOT/harness/lib/stack.sh"
            . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/ledger.sh"
            . "$FROOT/harness/lib/coverage.sh"; . "$FROOT/harness/lib/deny.sh"
            . "$FROOT/harness/lib/route.sh"; . "$FROOT/harness/lib/next.sh"
            felix_next "$NX" "$FROOT" "$REPO" HEAD~1 ); }

printf 'ordinary\n' > "$REPO/README.md"; _stage
n="$(_next)"
has "an unverified tree is the first thing to do" "$(printf '%s\n' "$n" | head -1)" "gate"
has "and it is Felix's own work"                  "$(printf '%s\n' "$n" | head -1)" "felix"
has "every row carries the command that clears it" "$(printf '%s\n' "$n" | head -1)" "felix gate"

# A deployment that is not this tree, found before the gate run rather than by
# one.
#
# `felix ledger` ranks the gate's own recurring catches and `installed` is the
# top one — 28 times, against a lesson that already says so. The lesson is not
# working because it is advice about an ordering, and what a person needs at
# the moment before running the gate is the state.
#
# Only where the checkout is the engine's own source: a property of the
# checkout, not the name of a project. $REPO above holds no engine, which is
# why none of the rows already asserted here changed.
NDR="$TMP/next-drift"; mkdir -p "$NDR/engine"
( _fx_cd "$NDR" && git init -q -b main && printf 'x\n' > a.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm i ) >/dev/null 2>&1
NDR="$(cd "$NDR" && pwd -P)"
cp -R "$FROOT/harness" "$NDR/engine/harness"
NDL="$TMP/next-live"; mkdir -p "$NDL"
cp -R "$NDR/engine/harness" "$NDL/harness"
NDB="$TMP/next-bin"; mkdir -p "$NDB"
# The stub reads the path it should report from a file beside itself rather
# than from the environment. A variable assigned in the calling shell and not
# exported is invisible to the child, and the first draft of this fixture read
# empty every time — the stub answering "nothing is deployed" while the
# assertion believed it was answering with a path.
printf '#!/usr/bin/env bash\nprintf "{\\"felix@felix\\": {\\"installPath\\": \\"%%s\\"}}\\n" "$(cat "$(dirname "$0")/live" 2>/dev/null)"\n' \
  > "$NDB/claude"
chmod +x "$NDB/claude"
_ndlive() { printf '%s' "${1:-}" > "$NDB/live"; }
_nd() { _ndlive "$1"; ( cd "$NDR" && PATH="$NDB:$PATH"
          . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
          . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
          . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/evidence.sh"
          . "$FROOT/harness/lib/maintenance.sh"; . "$FROOT/harness/lib/stack.sh"
          . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/ledger.sh"
          . "$FROOT/harness/lib/coverage.sh"; . "$FROOT/harness/lib/deny.sh"
          . "$FROOT/harness/lib/route.sh"; . "$FROOT/harness/lib/next.sh"
          felix_next "$NX" "$FROOT" "$NDR" HEAD 2>/dev/null ); }
# The reader first, since everything below rests on it answering.
_ndlive "$NDL"
is "the deployed path is read from the CLI, not guessed from the cache" \
   "$( cd "$NDR" && PATH="$NDB:$PATH"
       . "$FROOT/harness/lib/resolve.sh"; felix_deployed_engine )" "$NDL"
_ndlive ""
is "and a CLI that cannot answer is not a stale deployment" \
   "$( cd "$NDR" && PATH="$NDB:$PATH"
       . "$FROOT/harness/lib/resolve.sh"; felix_deployed_engine; printf '%s' "$?" )" "1"
case "$(_nd "$NDL")" in
  *"deployed engine is not this tree"*)
    bad "a deployment matching the tree is not reported as drift" ;;
  *) ok "a deployment matching the tree is not reported as drift" ;;
esac
printf '\n# drift\n' >> "$NDR/engine/harness/lib/monitor.sh"
has "a deployment that is not this tree is the first thing to fix" \
    "$(_nd "$NDL")" "the deployed engine is not this tree"
has "and it names the command that clears it" "$(_nd "$NDL")" "felix install"
# Silence when nothing can be asked, because "I could not look" is not a
# finding about anybody's deployment.
case "$(_nd "")" in
  *"deployed engine is not this tree"*)
    bad "and a CLI that answers nothing reports no drift" ;;
  *) ok "and a CLI that answers nothing reports no drift" ;;
esac

# Two capabilities that were never pointed at, for two different reasons, and
# only one of them is about keywords.
#
# `felix next` told the founder to fix the keywords in routes.tsv for plugins no
# route names at all — advice nobody can follow, because no keyword can reach a
# capability that appears in no play. Six rows on the real project, three of
# them impossible. The ledger already draws this distinction one layer down:
# named>0 with calls=0 is evidence about the capability, named=0 is evidence
# about routing and none at all about the capability. Rank 7 never inherited it.
#
# The general form is the one this project keeps paying for: absence of
# opportunity is not evidence of failure.
cat > "$MEM/nextproj/ledger.tsv" <<'LED'
s1	2026-08-01	plugin	reachable	0	0
s1	2026-08-01	plugin	unreachable	0	0
LED
printf 'work\tstuff\tcore\treachable\n' > "$NX/routes.tsv"
n="$(_next)"
rrow="$(printf '%s\n' "$n" | grep -A1 'reachable is mounted' | grep -v 'unreachable')"
urow="$(printf '%s\n' "$n" | grep -A1 'unreachable is mounted')"
has "a capability some route names is a keyword problem" "$rrow" "keywords"
case "$urow" in
  *keywords*) bad "one no route names is not" "$urow" ;;
  *)          ok  "one no route names is not" ;;
esac
has "and it says what would actually reach it" "$urow" "no route names it"
# Both are fixture state a later section asserts the absence of, so both are put
# back. A test that leaves its own evidence lying around makes the next one lie.
: > "$NX/routes.tsv"; : > "$MEM/nextproj/ledger.tsv"

# An escape outranks upkeep and is the founder's. It is also the thing the
# declared objective counts, so burying it under a maintenance row would hide
# the one number Felix is trying to move.
{ printf 'deployed\t7\talways\tconfirm the installed engine still matches\n'; } > "$NX/maintenance.tsv"
mkdir -p "$REPO/migrations"; printf 'x\n' > "$REPO/migrations/990.sql"; _stage
n="$(_next)"
has "an escape is named as the founder's"  "$n" "founder"
has "and says which channel"               "$n" "durable"
first_owner="$(printf '%s\n' "$n" | grep '	founder	' | head -1 | cut -f2)"
is "the founder's item is not buried"      "$first_owner" "founder"
_reset

# A tool a route names but cannot reach breaks the session it is needed in, and
# plugins bind at session start — so it can only be fixed between sessions.
# That is the highest-leverage preventive row there is.
# felix_ready_report is stubbed rather than driven. Whether a tool is really
# absent is ready.sh's own concern and it is tested there; here the question is
# only whether felix_next ranks an absent one. Driving it for real asserted the
# machine instead: with no claude CLI the honest answer is `unknown`, never
# `absent`, so this passed on a laptop and failed on every runner.
n="$( cd "$REPO" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
      . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
      . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/evidence.sh"
      . "$FROOT/harness/lib/maintenance.sh"; . "$FROOT/harness/lib/stack.sh"
      . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/ledger.sh"
      . "$FROOT/harness/lib/coverage.sh"; . "$FROOT/harness/lib/deny.sh"
      . "$FROOT/harness/lib/next.sh"
      felix_ready_report() { printf 'absent\tnot-installed-anywhere:tool\tnot installed\n'; }
      felix_next "$NX" "$FROOT" "$REPO" HEAD~1 )"
has "a route naming an unreachable tool is ranked" "$n" "not-installed-anywhere"
has "and says it must be fixed before the next session" "$n" "bind at start"

# felix_ready_report emits five states and two of them mean NOT MEASURED:
# `undeclared` (a route names it and no manifest declares it, so the inventory
# is never consulted) and `unknown` (no claude CLI here, cannot check). The
# rank-3 filter kept only absent|disabled and dropped both, and cmd_next's
# empty-output branch then printed "every tool a route names is reachable" —
# turning two not-measureds into a positive verification. cmd_ready renders the
# same data correctly ("N of these could not be checked, so this is not a clean
# bill"), so the engine held both the right rendering and the wrong one, and the
# wrong one was on the command that answers "what now".
# The stub's rows travel in a variable the subshell inherits. Written as
# `printf '%s'` with no argument first, which prints nothing at all — so the
# assertions below read an output with no rank-3 rows in it and reported a
# defect in next.sh that was really a defect in the fixture.
_nxs() { _NXROWS="$1"
         ( cd "$REPO" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
           . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
           . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/evidence.sh"
           . "$FROOT/harness/lib/maintenance.sh"; . "$FROOT/harness/lib/stack.sh"
           . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/ledger.sh"
           . "$FROOT/harness/lib/coverage.sh"; . "$FROOT/harness/lib/deny.sh"
           . "$FROOT/harness/lib/next.sh"
           felix_ready_report() { printf '%b' "$_NXROWS"; }
           felix_next "$NX" "$FROOT" "$REPO" HEAD~1 ) }
_nu="$(_nxs 'undeclared\tgoogle-cloud-storage\tnamed by a route, absent from stack.tsv\n')"
has "a routed tool no manifest declares is ranked, not dropped" "$_nu" "google-cloud-storage"
has "and says what would answer it"                            "$_nu" "declare"
_nk="$(_nxs 'unknown\tanthropic-skills:docx\tno claude CLI here, cannot check\n')"
has "a tool that could not be checked is said, not counted as reachable" "$_nk" "anthropic-skills:docx"
case "$_nk" in
  *"install or enable it"*) bad "and is not given an action nobody can take" "$_nk" ;;
  *)                        ok  "and is not given an action nobody can take" ;;
esac

# Due upkeep appears, and below the blocking rows.
printf 'ordinary again\n' > "$REPO/README.md"; _stage
( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"
  _ef="$(felix_verify_epoch_fields "$NX" "$REPO")"
  felix_verify_record "$REPO" "$FROOT" 0 "true" "$(felix_tree_id "$REPO" "$FROOT")" "" "" \
    "$(printf '%s' "$_ef" | cut -f1)" "$(printf '%s' "$_ef" | cut -f2)" )
n="$(_next)"
has "maintenance that is due is named" "$n" "deployed"
rm -f "$NX/maintenance.tsv"

# Nothing wrong is a real answer and has to be said, or the command becomes one
# people run and squint at.
n="$(_next)"
is "with nothing due it reports nothing" "$(printf '%s' "$n" | tr -d '\n ')" ""

# And the sentence it prints when there is nothing due must not claim more than
# was checked. With an unknown in the inventory, "every tool a route names is
# reachable" is a guess ready.sh explicitly refused to make one layer down.
_nxsay() { ( cd "$REPO" && PATH="/usr/bin:/bin" HOME="$TMP/nx-empty-home" "$FELIX" next 2>&1 ) }
mkdir -p "$TMP/nx-empty-home"
_ns="$(_nxsay)"
case "$_ns" in
  *"every tool a"*"route names is reachable"*)
    case "$_ns" in
      *"could not be checked"*) ok "the all-clear says what could not be checked" ;;
      *) bad "the all-clear says what could not be checked" "$_ns" ;;
    esac ;;
  *) ok "the all-clear says what could not be checked" ;;
esac
_reset

printf '\nwhether the delegation actually works\n'
# The monitor showed every record Felix wrote and never once showed whether
# Claude did the thing Felix named. Those are different claims, and only the
# second one is evidence that any of this is worth running.
#
# The signal is recorded rather than parsed. `named` is what a route pointed at
# and `calls` is what got reached for, both already in the ledger, so this is
# arithmetic on committed rows and not a transcript reader.
CM="$TMP/compliance"; mkdir -p "$CM" "$MEM/compliance"
cat > "$MEM/compliance/ledger.tsv" <<'EOF'
s1	2026-08-01	plugin	followed@x	4	2
s1	2026-08-01	plugin	ignored@x	0	3
s1	2026-08-01	plugin	unnamed@x	7	0
s2	2026-08-02	plugin	followed@x	1	1
s2	2026-08-02	plugin	ignored@x	0	1
EOF
c="$( . "$FROOT/harness/lib/monitor.sh"; . "$FROOT/harness/lib/ledger.sh"
      felix_monitor_compliance "$CM" )"
has "a session reports what was named and what was followed" "$c" "s1	2026-08-01	2	1	1"
has "and so does the next one"                               "$c" "s2	2026-08-02	2	1	1"
case "$c" in
  *unnamed*) bad "what no route named is not a compliance figure" "$c" ;;
  *)         ok  "what no route named is not a compliance figure" ;;
esac

# A ledger written before the named column cannot answer this, and must say so
# rather than reporting perfect compliance by counting nothing.
cat > "$MEM/compliance/ledger.tsv" <<'EOF'
s9	2026-07-01	plugin	old@x	0
EOF
c="$( . "$FROOT/harness/lib/monitor.sh"; . "$FROOT/harness/lib/ledger.sh"
      felix_monitor_compliance "$CM" | tr -d '\n ' )"
is "a ledger from before the column reports nothing at all" "$c" ""

printf '\nthe monitor\n'
# A hook's additionalContext reaches the model and never the terminal, so every
# routing decision and every gate verdict happens behind glass. The monitor is
# the only surface where a person can see what Felix actually did.
out="$(cd "$REPO" && "$FELIX" monitor --log 2>&1)"
MON="$FROOT/state/monitor.html"
[ -s "$MON" ] && ok "renders a page" || bad "renders a page" "$out"
if [ -s "$MON" ]; then
  grep -q '"name":"widget"' "$MON" \
    && ok "carries the governed project" || bad "carries the governed project"
  # A page shipped with its placeholder intact looks fine and shows nothing.
  grep -q 'FELIX_DATA' "$MON" \
    && bad "the data marker is substituted" "marker still present" \
    || ok "the data marker is substituted"

  # The panel that answers whether the delegation works has to be on the page
  # and fed by the payload. A render function nothing calls is the same defect
  # as a capability no route names.
  grep -q '"compliance":' "$MON" \
    && ok "the payload carries compliance" || bad "the payload carries compliance"
  grep -q 'renderCompliance()' "$MON" \
    && ok "and the page has a panel for it" || bad "and the page has a panel for it"
  grep -q 'renderMem();renderCompliance()' "$MON" \
    && ok "and paint actually calls it" || bad "and paint actually calls it"
  # No server and no network. A governance page that phones out is not one.
  if grep -qiE 'src="https?:|href="https?:|@import[[:space:]]+url\(http' "$MON"; then
    bad "self-contained, no external references"
  else
    ok "self-contained, no external references"
  fi

  # The route log records whatever was typed, and the data is embedded inside a
  # <script> element. An HTML parser looks for the literal characters closing
  # that tag without caring that they sit inside a string, so a prompt is a way
  # to end the script early and put markup on the page.
  printf '%s\thostile\t9\t{"prompt":"</script\076<img src=x onerror=alert(1)\076"}\n' \
    "2026-01-01T00:00:00Z" >> "$MEM/widget/routes.log"
  ( cd "$REPO" && "$FELIX" monitor --log >/dev/null 2>&1 )
  # The payload survives as inert text — that is fine and even desirable, since
  # the page is for reading what happened. What must not survive is a bracket.
  if grep -q 'u003c/script' "$MON"; then
    ok "a hostile prompt is neutralised, not dropped"
  else
    bad "a hostile prompt is neutralised, not dropped" "escaped form absent"
  fi
  grep -q '<img' "$MON" && bad "no markup from a prompt reaches the page" \
                        || ok "no markup from a prompt reaches the page"
  # ...and the page must still be one script element, not two.
  n="$(grep -c '</script>' "$MON")"
  is "the page still closes exactly one script" "$n" "1"
fi

# >>> monitor-capabilities-unread
printf '\nthe monitor: declared capabilities\n'
# The monitor wrote each project's capabilities into its payload by itself,
# with `[ -f ]` and grep, and never through felix_declared. A capabilities
# link whose target was gone, a directory, a pipe or a file nobody could read
# all came out as [], which says the project declares nothing. A read that
# failed partway came out as part of a list, and comment lines came out as
# capabilities. Nobody could see any of it, because the page had not named the
# field since August. A list that was read is an array; one that was not is an
# object that says so; and the memory panel has a row that counts only an
# array, so null, a missing key or a string can never read as zero.
MCH="$TMP/moncap"; MCP="$MCH/projects/capx"; MCO="$MCH/out"; MCM="$MCH/memory"; MCJS="$TMP/moncap-page.js"
MCW="the capabilities this project declares could not be read"; MCU="{\"unknown\":\"$MCW\"}"
MCF="this page's data does not say which capabilities this project declares"
MCTPL="$FROOT/harness/templates/monitor.html"; MCNODE="$(command -v node 2>/dev/null || true)"
mkdir -p "$MCP" "$MCH/projects/capy" "$MCO" "$MCM/capx"
printf '{"name":"capx","gate":"true"}\n' > "$MCP/project.json"
printf '{"name":"capy","gate":"true"}\n' > "$MCH/projects/capy/project.json"
printf 'alpha\n' > "$MCH/projects/capy/capabilities"
printf 'plugin\tcapx-tool@nowhere\t-\tlow\talways\tDECLARED\n' > "$MCP/stack.tsv"
: > "$MCP/routes.tsv"; : > "$MCH/projects/capy/routes.tsv"; : > "$MCH/projects/capy/stack.tsv"
printf 'x\theld\tbody one\nx\tsaid\tbody two\n' > "$MCM/capx/says.log"

# One call of _felix_mon_project for capx, in a subshell, with the three
# libraries sourced and $1 run after them; `nodetect` leaves detect.sh out.
_mc_call() { ( export FELIX_MEMORY="$MCM"; . "$FROOT/harness/lib/resolve.sh"
               [ "${2:-}" = nodetect ] || . "$FROOT/harness/lib/detect.sh"
               . "$FROOT/harness/lib/monitor.sh"; eval "${1:-:}"
               _felix_mon_project "$MCP" "$MCH" ) 2>/dev/null; }
# A member of the payload in file $1, as compact JSON: <absent> when it is not
# there, <invalid> when the file is not one JSON object; `-` is the whole
# object less capabilities. With no parser only `capabilities` is answered.
_mc_q() {
  if [ -n "$MCNODE" ]; then
    node -e 'let o;try{o=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))}catch(e){}
      const k=process.argv[2],w=s=>process.stdout.write(s);
      if(!o||typeof o!=="object"||Array.isArray(o))w("<invalid>");
      else if(k==="-"){delete o.capabilities;w(JSON.stringify(o))}else w(k in o?JSON.stringify(o[k]):"<absent>")' "$1" "$2" </dev/null
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys
try: o=json.load(open(sys.argv[1]))
except Exception: o=None
d=lambda v: json.dumps(v,separators=(",",":"),ensure_ascii=False); k=sys.argv[2]
if not isinstance(o,dict): r="<invalid>"
elif k=="-": o.pop("capabilities",None); r=d(o)
else: r=d(o[k]) if k in o else "<absent>"
sys.stdout.write(r)' "$1" "$2" </dev/null
  elif [ "$2" = capabilities ]; then sed -nE 's/.*"capabilities":(\[[^]]*\]|\{[^}]*\}).*/\1/p' "$1" | head -n 1
  else printf '<noparser>'; fi
}
_mc_valid() { case "$(_mc_q "$2" -)" in
  '<noparser>') skip "$1: the payload is valid JSON" "neither node nor python3 on PATH" ;;
  '<invalid>')  bad  "$1: the payload is valid JSON" "$(head -c 300 "$2")" ;;
  *)            ok   "$1: the payload is valid JSON" ;; esac; }
# A read shape: $2 is the file's text for printf, or `none` for no file.
_mc_read() { rm -rf "$MCP/capabilities"; [ "$2" = none ] || printf "$2" > "$MCP/capabilities"
             _mc_call > "$MCO/$1.json"; }
_mc_read twin 'storage\nauth\n'
is "a read capabilities list is its declared lines, in file order" "$(_mc_q "$MCO/twin.json" capabilities)" '["storage","auth"]'
_mc_valid "a read list" "$MCO/twin.json"
_mc_read comments '# what this project declares\nstorage\n\n   \n\t\n  # an indented comment\n\t# a tabbed one\nauth\n'
is "comments, blank and whitespace-only lines are not capabilities" "$(_mc_q "$MCO/comments.json" capabilities)" '["storage","auth"]'
_mc_valid "a list with comments" "$MCO/comments.json"
_mc_read onlycomments '# nothing declared yet\n\n   \n  # still nothing\n'
is "a file of only comments and blank lines is read, and declares nothing" "$(_mc_q "$MCO/onlycomments.json" capabilities)" '[]'
_mc_valid "a list of only comments" "$MCO/onlycomments.json"
_mc_read empty ''
is "an empty capabilities file is read, and declares nothing" "$(_mc_q "$MCO/empty.json" capabilities)" '[]'
_mc_valid "an empty list" "$MCO/empty.json"
_mc_read none none
is "no capabilities file declares nothing" "$(_mc_q "$MCO/none.json" capabilities)" '[]'
_mc_valid "no capabilities file" "$MCO/none.json"
# After review, not blind: a name is escaped on the way in and otherwise kept
# as declared. Without the escape a quote ends the page's script and a closing
# script tag puts markup on the page; nothing above could fail for it.
_mc_read esc 'a"b</script>\n'
case "$(_mc_q "$MCO/esc.json" -)" in
  '<noparser>') skip "a declared name is escaped into the payload" "neither node nor python3 on PATH" ;;
  *) is "a declared name is escaped into the payload" "$(_mc_q "$MCO/esc.json" capabilities)" '["a\"b</script>"]' ;;
esac
_mc_valid "a name holding a quote" "$MCO/esc.json"
if grep -qF '</script>' "$MCO/esc.json"; then bad "a declared name puts no closing script tag in the payload"
else ok "a declared name puts no closing script tag in the payload"; fi
_mc_read dup '  storage\nauth\nauth\n'
is "a declared line keeps its leading whitespace, and a name declared twice is listed twice" \
   "$(_mc_q "$MCO/dup.json" capabilities)" '["  storage","auth","auth"]'

# Unread, in each model the contract names. $3, when given, skips all four.
MCT="$(_mc_q "$MCO/twin.json" -)"
_mc_unread() {
  local v n1="$1: the payload says the list could not be read" n4="$1: every other member is the read twin's" \
        n2="$1: and never says it as an empty list, any list, null or nothing"
  if [ -n "${3:-}" ]; then skip "$n1" "$3"; skip "$n2" "$3"; skip "$1: the payload is valid JSON" "$3"; skip "$n4" "$3"; return 0; fi
  v="$(_mc_q "$2" capabilities)"
  is "$n1" "$v" "$MCU"
  case "$v" in '['*|null|'<absent>'|'<invalid>'|'') bad "$n2" "got [$v]" ;; *) ok "$n2" ;; esac
  _mc_valid "$1" "$2"
  case "$MCT" in '<noparser>') skip "$n4" "neither node nor python3 on PATH" ;;
                 '<invalid>')  bad  "$n4" "the read twin is not valid JSON" ;;
                 *)            is   "$n4" "$(_mc_q "$2" -)" "$MCT" ;; esac
}
printf 'storage\nauth\n' > "$MCP/capabilities"
_mc_call 'felix_declared_into() { return 2; }' > "$MCO/u1.json"
_mc_unread "felix_declared_into failing" "$MCO/u1.json"
_mc_call 'felix_declared() { return 2; }' > "$MCO/u2.json"
_mc_unread "felix_declared failing" "$MCO/u2.json"
_mc_call 'felix_declared() { printf "billing\n"; return 2; }' > "$MCO/u3.json"
_mc_unread "felix_declared failing after it printed a line" "$MCO/u3.json"
_mc_call 'felix_declared() { exit 0; }' > "$MCO/u4.json"
_mc_unread "felix_declared's substitution ending before it said it was done" "$MCO/u4.json"
_mc_call 'unset -f felix_declared_into' nodetect > "$MCO/u5.json"
_mc_unread "felix_declared_into not defined" "$MCO/u5.json"

_mc_swap() { [ -f "$MCP/capabilities" ] && chmod 644 "$MCP/capabilities"; rm -rf "$MCP/capabilities"; }
_mc_swap; ln -s "$MCH/no-such-list" "$MCP/capabilities"; _mc_call > "$MCO/o1.json"
_mc_unread "a capabilities link whose target is gone" "$MCO/o1.json"
_mc_swap; mkdir "$MCP/capabilities"; _mc_call > "$MCO/o2.json"
_mc_unread "a capabilities directory" "$MCO/o2.json"
# A pipe must not be opened, so a call that blocks on it is a failure, and it
# is ended here rather than left to hang the suite: a writer for anything
# blocked opening the pipe, then the processes this block started.
_mc_kill() { local c; for c in $(pgrep -P "$1" 2>/dev/null); do _mc_kill "$c"; done; kill -9 "$1" 2>/dev/null; }
_mc_swap; mkfifo "$MCP/capabilities"
_mc_call > "$MCO/o3.json" &
_mcp=$!; _mci=0
while kill -0 "$_mcp" 2>/dev/null && [ "$_mci" -lt 100 ]; do sleep 0.2; _mci=$((_mci+1)); done
if kill -0 "$_mcp" 2>/dev/null; then
  exec 3<>"$MCP/capabilities"; exec 3>&-; _mc_kill "$_mcp"
  bad "a capabilities pipe: the call returns without a writer on the pipe" "still running after 20s, so it was killed"
else ok "a capabilities pipe: the call returns without a writer on the pipe"; fi
wait "$_mcp" 2>/dev/null
_mc_unread "a capabilities pipe" "$MCO/o3.json"
_mc_swap; printf 'storage\nauth\n' > "$MCP/capabilities"; chmod 000 "$MCP/capabilities"
if [ "$(id -u)" = 0 ]; then _mc_unread "a capabilities file nobody can read" - "running as root, which reads a mode-000 file"
else _mc_call > "$MCO/o4.json"; _mc_unread "a capabilities file nobody can read" "$MCO/o4.json"; fi

# Clause 2: a render with an unread list still writes the page, and the page
# carries each project's list as the payload says it.
cat > "$MCJS" <<'EOF'
// page FILE [NAME] | tpl TEMPLATE DATA: run the page's script against a DOM stub, print what #mem holds.
const fs=require('fs'),vm=require('vm'),[mode,file,arg]=process.argv.slice(2);
let html=fs.readFileSync(file,'utf8');
if(mode==='tpl')html=html.split('/*{{FELIX_DATA}}*/').join(arg);
const code=(html.match(/<script>([\s\S]*?)<\/script>/)||[])[1]||'throw new Error("no script")';
const G=new Proxy(function(){},{get:(t,p)=>p===Symbol.toPrimitive?()=>0:G,apply:()=>G,construct:()=>G,set:()=>true});
function mk(tag){const o={tagName:String(tag).toUpperCase(),children:[],attrs:{},style:{},dataset:{},className:'',title:'',_t:'',
  appendChild(c){this.removeChild(c);this.children.push(c);return c;},
  removeChild(c){const i=this.children.indexOf(c);if(i>=0)this.children.splice(i,1);return c;},
  get firstChild(){return this.children[0]||null;},
  get textContent(){return this._t+this.children.map(c=>c.textContent).join('');},
  set textContent(v){this.children=[];this._t=v==null?'':String(v);},
  setAttribute(k,v){if(k==='class')this.className=String(v);else if(k==='title')this.title=String(v);else this.attrs[k]=String(v);},
  getAttribute(k){return k==='class'?this.className:k==='title'?this.title:(k in this.attrs?this.attrs[k]:null);},
  addEventListener(){},removeEventListener(){},
  get classList(){const s=this,L=()=>String(s.className).split(/\s+/).filter(Boolean);return{contains:x=>L().includes(x),
    add:(...a)=>{s.className=[...new Set(L().concat(a))].join(' ');},remove:(...a)=>{s.className=L().filter(x=>!a.includes(x)).join(' ');},
    toggle(x,f){const on=f===undefined?!L().includes(x):!!f;on?this.add(x):this.remove(x);return on;}};}};
  return new Proxy(o,{get:(t,p)=>p in t?Reflect.get(t,p):G,set:(t,p,v)=>Reflect.set(t,p,v)});}
function run(i){const ids={},st=v=>({getItem:()=>v,setItem(){},removeItem(){}});
  const ctx=vm.createContext({document:{createElement:mk,getElementById:id=>ids[id]||(ids[id]=mk('div')),addEventListener(){},body:mk('body')},
    window:G,location:G,navigator:G,console,requestAnimationFrame:()=>0,setInterval:()=>0,setTimeout:()=>0,clearTimeout(){},clearInterval(){},
    sessionStorage:st(JSON.stringify({proj:i,y:0})),localStorage:st(null)});
  let ran='yes',data;try{vm.runInContext(code,ctx);}catch(e){ran='threw: '+(e&&e.message);}
  try{data=vm.runInContext('DATA',ctx);}catch(e){}
  return{ran,ids,data};}
let r=run(0);
for(let i=1;mode==='page'&&arg&&i<10&&!(r.ids.projName&&r.ids.projName.textContent===arg);i++)r=run(i);
const kids=r.ids.mem?r.ids.mem.children:[],rows=[],old=['lessons on file','gate failures','tools declared','things said'];
for(let i=0;i+1<kids.length;i+=2)rows.push([kids[i].textContent,kids[i+1]]);
const cap=rows.find(x=>x[0]==='capabilities declared'),was=rows.filter(x=>old.includes(x[0])),ps=r.data&&r.data.projects;
const out={ran:r.ran,name:r.ids.projName?r.ids.projName.textContent:'',keys:rows.map(x=>x[0]).join('|'),
  oldkeys:was.map(x=>x[0]).join('|'),old:was.map(x=>x[1].textContent).join('|'),capv:cap?cap[1].textContent:'<no row>',
  capc:cap?String(cap[1].className):'',capt:cap?String(cap[1].title):'',capta:cap?(cap[1].getAttribute('title')??'<absent>'):'',
  caps:Array.isArray(ps)?ps.map(p=>p.name+'='+('capabilities' in p?JSON.stringify(p.capabilities):'<absent>')).sort().join(';'):'<no data>'};
for(const k in out)process.stdout.write(k+'\t'+String(out[k]).replace(/[\t\n]/g,' ')+'\n');
EOF
_mc_page() { node "$MCJS" "$@" </dev/null 2>/dev/null; }
_mc_f() { printf '%s\n' "$1" | awk -F'\t' -v k="$2" '$1==k && !d {sub(/^[^\t]*\t/,""); print; d=1}'; }
_mc_is() { if [ -n "$MCNODE" ]; then is "$1" "$2" "$3"; else skip "$1" "node is not on PATH"; fi; }
_mc_render() { ( export FELIX_MEMORY="$MCM"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
                 . "$FROOT/harness/lib/monitor.sh"; felix_monitor_render "$MCTPL" "$MCH" "$1" ) >/dev/null 2>&1; }
_mc_swap; mkdir "$MCP/capabilities"; rm -f "$MCO/unread.html"
_mc_render "$MCO/unread.html"; is "a render with an unread list exits 0" "$?" "0"
[ -s "$MCO/unread.html" ] && ok "a render with an unread list writes the page" || bad "a render with an unread list writes the page"
grep -qF "$MCU" "$MCO/unread.html" 2>/dev/null && ok "the page a render writes carries the unread object" \
  || bad "the page a render writes carries the unread object"
_mc_is "the page a render writes carries each project's list, read or not known" \
  "$(_mc_f "$(_mc_page page "$MCO/unread.html" capx)" caps)" "capx=$MCU;capy=[\"alpha\"]"
_mc_swap; printf 'storage\nauth\n' > "$MCP/capabilities"; _mc_render "$MCO/read.html"
_mc_is "and a render of lists that were read carries each as its array" \
  "$(_mc_f "$(_mc_page page "$MCO/read.html" capx)" caps)" 'capx=["storage","auth"];capy=["alpha"]'

# The same through felix monitor, on widget, which is put back as it was found.
MCWC="$FROOT/projects/widget/capabilities"; MCPG="$FROOT/state/monitor.html"; MCK="$TMP/moncap-keep"
_mc_fp() { if [ -L "$1" ]; then printf 'link %s' "$(readlink "$1")"; elif [ -d "$1" ]; then printf 'dir %s' "$(ls -A "$1" | cksum)"
           elif [ -f "$1" ]; then printf 'file %s' "$(cksum < "$1")"; elif [ -e "$1" ]; then printf other; else printf absent; fi; }
_mcwb="$(_mc_fp "$MCWC")"; _mcpb="$(_mc_fp "$MCPG")"; mkdir -p "$MCK"
{ [ -e "$MCWC" ] || [ -L "$MCWC" ]; } && mv "$MCWC" "$MCK/capabilities"
[ -f "$MCPG" ] && cp -p "$MCPG" "$MCK/monitor.html"
mkdir "$MCWC"; rm -f "$MCPG"
( cd "$REPO" && "$FELIX" monitor --log >/dev/null 2>&1 ); is "felix monitor with an unread list exits 0" "$?" "0"
[ -s "$MCPG" ] && ok "felix monitor with an unread list writes the page" || bad "felix monitor with an unread list writes the page"
grep -qF "$MCU" "$MCPG" 2>/dev/null && ok "felix monitor's page says the unread list as not known" \
  || bad "felix monitor's page says the unread list as not known"
rmdir "$MCWC"; { [ -e "$MCK/capabilities" ] || [ -L "$MCK/capabilities" ]; } && mv "$MCK/capabilities" "$MCWC"
# After review, not blind: the read half through felix monitor, so a felix that
# reads every list as unread is caught too. Widget's own member, not a grep of
# the page, which holds whatever other projects this suite left unread.
( cd "$REPO" && "$FELIX" monitor --log >/dev/null 2>&1 )
_mcwr="$(_mc_f "$(_mc_page page "$MCPG" widget)" caps | tr ';' '\n' | sed -n 's/^widget=//p')"
case "$_mcwr" in '['*) _mcwr="an array" ;; esac
_mc_is "and felix monitor says widget's list as read once it is put back" "$_mcwr" "an array"
if [ -f "$MCK/monitor.html" ]; then cp -p "$MCK/monitor.html" "$MCPG"; else rm -f "$MCPG"; fi
is "and the widget project's capabilities are as this block found them" "$(_mc_fp "$MCWC")" "$_mcwb"
is "and so is the page felix monitor writes" "$(_mc_fp "$MCPG")" "$_mcpb"

# Clause 3, the page. $1 names the case, $2 is what the runner printed, $3 the
# value wanted, $4 yes or no for warn, or read for a read list's cell, which
# carries neither warn nor a title (- to not ask), $5 the title wanted.
_mc_row() {
  local w=no t; case " $(_mc_f "$2" capc) " in *" warn "*) w=yes ;; esac
  t="property [$(_mc_f "$2" capt)] attribute [$(_mc_f "$2" capta)]"
  case "$t" in 'property [] attribute []'|'property [] attribute [<absent>]') t=none ;; esac
  [ "$(_mc_f "$2" capv)" = "<no row>" ] && { w="no row"; t="no row"; }
  _mc_is "$1: the script runs to the end" "$(_mc_f "$2" ran)" "yes"
  _mc_is "$1: capabilities declared sits directly after tools declared" "$(_mc_f "$2" keys)" \
         "lessons on file|gate failures|tools declared|capabilities declared|things said"
  _mc_is "$1: the row reads $3" "$(_mc_f "$2" capv)" "$3"
  [ "$4" = - ] || _mc_is "$1: the cell $( [ "$4" = yes ] && echo carries || echo does not carry ) warn" "$w" \
                         "$( [ "$4" = yes ] && echo yes || echo no )"
  [ "$4" = read ] && _mc_is "$1: the cell has no title, as a property or an attribute" "$t" "none"
  [ -z "$5" ] || _mc_is "$1: the cell's title says why" "$(_mc_f "$2" capt)" "$5"
}
_mc_data() { local c=""; [ "$1" = - ] || c=",\"capabilities\":$1"
  printf '{"generated":"","projects":[{"name":"capx","says":[],"routes":[],"routeLog":[],"verifyLog":[],"mistakes":[],"mistakesTotal":4,"stack":[{},{}],"lessons":3,"saysTotal":5,"compliance":[]%s}]}' "$c"; }
_mc_row "the rendered page, a read list of two" "$(_mc_page page "$MCO/read.html" capx)" 2 read ""
_mc_row "the rendered page, an unread list" "$(_mc_page page "$MCO/unread.html" capx)" "not known" yes "$MCW"
while IFS='|' read -r _mcd _mcj _mcv _mcw _mct; do
  case "$_mct" in WHY) _mct="$MCW" ;; FALLBACK) _mct="$MCF" ;; esac
  _mc_row "the page, $_mcd" "$(_mc_page tpl "$MCTPL" "$(_mc_data "$_mcj")")" "$_mcv" "$_mcw" "$_mct"
done <<'EOF'
a read list of two|["storage","auth"]|2|read|
a read empty list|[]|0|read|
the unread object|{"unknown":"the capabilities this project declares could not be read"}|not known|yes|WHY
an object giving another reason|{"unknown":"the list was a pipe"}|not known|yes|the list was a pipe
an object giving no reason|{}|not known|yes|FALLBACK
an object whose reason is not a string|{"unknown":5}|not known|yes|FALLBACK
a project without the key|-|not known|yes|FALLBACK
a null list|null|not known|yes|FALLBACK
a string where the list belongs|"storage"|not known|yes|FALLBACK
a number where the list belongs|3|not known|yes|FALLBACK
EOF
_mc_row "the page with no projects" "$(_mc_page tpl "$MCTPL" '{"generated":"","projects":[]}')" 0 no ""
_mco="$(_mc_page tpl "$MCTPL" "$(_mc_data '["storage","auth"]')")"
_mc_is "the memory panel keeps its four rows, in their order, with their values" \
  "$(_mc_f "$_mco" oldkeys) = $(_mc_f "$_mco" old)" "lessons on file|gate failures|tools declared|things said = 3|4|2|5"
# After review, not blind. An empty reason is still not known, in amber, with
# the fallback title: the first fix keyed the class on the title and drew it
# plain. A name that came back empty is still counted, which is what the
# contract leans on when it leaves a blanked name out of scope.
_mc_row "the page, an object whose reason is empty" \
  "$(_mc_page tpl "$MCTPL" "$(_mc_data '{"unknown":""}')")" "not known" yes "$MCF"
_mc_row "the page, an array holding an empty name" \
  "$(_mc_page tpl "$MCTPL" "$(_mc_data '["","storage"]')")" 2 read ""
has "an unread cell is drawn in amber" "$(cat "$MCTPL")" '.kv .v.warn{color:var(--amber)}'
# <<< monitor-capabilities-unread

printf '\ndenial\n'
# The first thing Felix can actually stop. Every other hook injects text a
# session may ignore; PreToolUse decides. Verified against two working
# implementations on this machine rather than assumed: exit 2 blocks and the
# reason goes to stderr, exit 0 allows.
#
# Scoped to Bash by the matcher in hooks.json, so a mistake here cannot deny an
# edit. A deny hook that gets this wrong is indistinguishable from a broken
# editor, which is the failure guard.sh exists to describe.
cat > "$FROOT/projects/widget/deny.tsv" <<'EOF'
# tool	pattern	reason
Bash	git add (-A|--all|\.)$	stage explicit paths; -A stages what you did not read
Bash	(^|[;&| ])\./scripts/gate\.sh	that is not the gate Felix runs
EOF

( cd "$REPO" && _pre '{"tool_name":"Bash","tool_input":{"command":"git add -A"}}' ); rc=$?
is "a denied command exits 2" "$rc" "2"
has "and says why" "$(cat "$FROOT/.deny-err")" "stage explicit paths"

( cd "$REPO" && _pre '{"tool_name":"Bash","tool_input":{"command":"git add src/widget.py"}}' ); rc=$?
is "an explicit path is allowed" "$rc" "0"

( cd "$REPO" && _pre '{"tool_name":"Bash","tool_input":{"command":"./scripts/gate.sh --quick"}}' ); rc=$?
is "running a rival gate is denied" "$rc" "2"

# The reason a project would ever turn this off is a false deny, so the failure
# mode has to be allow. Anything unparseable, any missing table, any error.
( cd "$REPO" && _pre 'not json at all' ); rc=$?
is "an unparseable payload is allowed" "$rc" "0"
( cd "$PLAIN" && _pre '{"tool_name":"Bash","tool_input":{"command":"git add -A"}}' ); rc=$?
is "an ungoverned repo is allowed" "$rc" "0"

# A malformed row must not take the whole table down with it, the same way a
# malformed routes.tsv row is skipped rather than fatal.
printf 'Bash\n' >> "$FROOT/projects/widget/deny.tsv"
( cd "$REPO" && _pre '{"tool_name":"Bash","tool_input":{"command":"git add -A"}}' ); rc=$?
is "a malformed row is skipped, others still deny" "$rc" "2"
rm -f "$FROOT/projects/widget/deny.tsv" "$FROOT/.deny-err"

( cd "$REPO" && _pre '{"tool_name":"Bash","tool_input":{"command":"git add -A"}}' ); rc=$?
is "no deny.tsv means nothing is denied" "$rc" "0"

printf '\ndenial past Bash\n'
# The matcher bound Bash alone, so no rule could see Read, Edit or Write — which
# the ledger then showed is where real sessions spend most of their calls. The
# hold-up was never the plumbing: the matcher was the blast-radius control, and
# a bad regex reaching Edit looks exactly like a broken editor.
#
# What a rule matches is now the field naming the thing the tool acts on, and a
# pattern broad enough to refuse ordinary work is refused as a rule instead of
# honoured. That makes the bad-regex case unreachable rather than accepted.
{ printf 'Bash\tgit add (-A|--all|\\.)$\tstage explicit paths\n'
  printf 'Edit\t/\\.env$\t.env holds live credentials; change it by hand\n'
  printf 'Write\t\\.lock$\ta lockfile is written by its tool, never by hand\n'
  printf 'Read\t/secrets/\treading a secret is how it reaches a transcript\n'
} > "$FROOT/projects/widget/deny.tsv"

( cd "$REPO" && _pre '{"tool_name":"Edit","tool_input":{"file_path":"/w/.env","old_string":"a","new_string":"b"}}' ); rc=$?
is  "a path rule denies an edit" "$rc" "2"
has "and says why" "$(cat "$FROOT/.deny-err")" "live credentials"

( cd "$REPO" && _pre '{"tool_name":"Edit","tool_input":{"file_path":"/w/src/widget.py","old_string":"a","new_string":"b"}}' ); rc=$?
is "an unrelated path is allowed" "$rc" "0"

( cd "$REPO" && _pre '{"tool_name":"Write","tool_input":{"file_path":"/w/uv.lock","content":"x"}}' ); rc=$?
is "a write rule denies a write" "$rc" "2"

# The tool column has to keep meaning something, or widening the matcher has
# quietly turned every rule into a rule about every tool.
( cd "$REPO" && _pre '{"tool_name":"Write","tool_input":{"file_path":"/w/.env","content":"x"}}' ); rc=$?
is "a rule naming Edit does not deny a Write" "$rc" "0"

( cd "$REPO" && _pre '{"tool_name":"Read","tool_input":{"file_path":"/w/secrets/key.pem"}}' ); rc=$?
is "reading can be refused too" "$rc" "2"

( cd "$REPO" && _pre '{"tool_name":"NotebookEdit","tool_input":{"notebook_path":"/w/.env"}}' ); rc=$?
is "a notebook is matched on its own path field" "$rc" "0"

# A rule matches what the tool acts on and never what it would write. Matching
# content would turn every edit payload into a search target, so a rule written
# about a filename would start firing on prose that merely mentions it.
printf 'Edit\tuv\\.lock\tnot by hand\n' > "$FROOT/projects/widget/deny.tsv"
( cd "$REPO" && _pre '{"tool_name":"Edit","tool_input":{"file_path":"/w/README.md","old_string":"see uv.lock","new_string":"see uv.lock now"}}' ); rc=$?
is "a rule never matches file content" "$rc" "0"

( cd "$REPO" && _pre '{"tool_name":"Edit","tool_input":{}}' ); rc=$?
is "a payload naming nothing to act on is allowed" "$rc" "0"

# The sharp version of the same thing, and the one that decides how the field
# is read. Content quoting the field name is already defused, because JSON
# escapes those quotes and they are neutralised before any match runs — checked
# rather than assumed. What is not defused is a second unescaped copy further
# along the envelope, which a greedy match reads in preference to the real one.
# Claude Code is free to add envelope keys, so the subject has to be the first
# occurrence rather than the last.
printf 'Edit\t/\\.env$\tcredentials\n' > "$FROOT/projects/widget/deny.tsv"
( cd "$REPO" && _pre '{"tool_name":"Edit","tool_input":{"file_path":"/w/README.md"},"related":{"file_path":"/w/.env"}}' ); rc=$?
is "a later copy of the field in the envelope is not the subject" "$rc" "0"

# The reason widening was held back, made unreachable. A pattern matching an
# ordinary path or an ordinary command is not a narrow rule with a bug in it;
# it is a rule that refuses everything, and honouring one is indistinguishable
# from a broken editor. Skipping it can only ever allow more than was intended,
# which is the direction every other failure in this file already takes.
printf 'Edit\t.*\teverything\n' > "$FROOT/projects/widget/deny.tsv"
( cd "$REPO" && _pre '{"tool_name":"Edit","tool_input":{"file_path":"/w/src/widget.py"}}' ); rc=$?
is "a rule that refuses everything is refused as a rule" "$rc" "0"

printf 'Bash\t.\tanything at all\n' > "$FROOT/projects/widget/deny.tsv"
( cd "$REPO" && _pre '{"tool_name":"Bash","tool_input":{"command":"ls"}}' ); rc=$?
is "and over-broad means over-broad for Bash too" "$rc" "0"

# Generous is not the same as over-broad. A rule covering a whole tree of
# generated files still has to fire, or the guard has eaten the feature.
printf 'Edit\t/(node_modules|dist)/\tgenerated; change the source\n' > "$FROOT/projects/widget/deny.tsv"
( cd "$REPO" && _pre '{"tool_name":"Edit","tool_input":{"file_path":"/w/dist/bundle.js"}}' ); rc=$?
is "a broad but legitimate rule still denies" "$rc" "2"

# A skipped rule has to be visible somewhere a person looks, or it is a rule
# that silently does nothing — the same complaint Felix makes about other
# people's plugins. The hook stays quiet because it runs on every call.
printf 'Edit\t.*\teverything\n' > "$FROOT/projects/widget/deny.tsv"
out="$( cd "$REPO" && "$FELIX" doctor 2>&1 )"
has "doctor names the rule that refuses everything" "$out" "refuses everything it was asked about"
printf 'Edit\t/\\.env$\tcredentials\n' > "$FROOT/projects/widget/deny.tsv"
out="$( cd "$REPO" && "$FELIX" doctor 2>&1 )"
case "$out" in
  *"refuses everything it was asked about"*) bad "doctor is quiet when every rule is narrow" "reported anyway" ;;
  *) ok "doctor is quiet when every rule is narrow" ;;
esac
rm -f "$FROOT/projects/widget/deny.tsv" "$FROOT/.deny-err"

