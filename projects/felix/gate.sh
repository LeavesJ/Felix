#!/usr/bin/env bash
# Felix's own gate.
#
# Felix had 140 assertions and nothing that ran them, which is the same gap it
# was built to close in every other project. A governance layer that is not
# itself governed is an argument nobody has to take seriously.
#
# Gates the tree it is standing in, not the tree this file lives in.

set -uo pipefail

if ! ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "gate: $PWD is not inside a git worktree." >&2; exit 2
fi
cd "$ROOT" || exit 2
[ -d engine/harness ] || { echo "gate: $ROOT is not Felix (no engine/harness). Refusing." >&2; exit 2; }

FAILED=""
pass() { printf '  %-18s ok\n' "$1"; }
fail() { printf '  %-18s FAIL\n' "$1"; FAILED="$FAILED $1"; }

echo "gate: $ROOT"
echo "      $(git rev-parse --abbrev-ref HEAD) @ $(git rev-parse --short HEAD)"

# ------------------------------------------------------------- syntax --------
# Every shell file must parse. A harness that fails to source is a harness that
# silently governs nothing, and that failure is invisible in a session hook.
BAD=""
while IFS= read -r f; do
  bash -n "$f" 2>/dev/null || BAD="$BAD $f"
done <<EOF
$(git ls-files 'engine/harness/*' 'projects/*/*.sh' | grep -vE '\.(json|tsv|md|ya?ml|html|css|txt)$')
EOF
# Reported on its own line, and that is load-bearing rather than stylistic. The
# `verifier` confine on this file counts lines matching `^[[:space:]]*(pass|fail|check) `,
# so a report written mid-line after `&&` is not counted and the whole check
# could be deleted without the count dropping — no escape, on the file whose
# reason column reads "a gate that cannot fail is not a gate" (#77).
if [ -z "$BAD" ]; then
  pass syntax
else
  fail syntax; printf '    %s\n' $BAD
fi

# ------------------------------------------------------------- executable ----
# A hook or a tool that lost its executable bit fails at the worst moment, in
# somebody else's session, with no output.
#
# Enumerated, never listed. This named three hooks by hand and there were seven:
# the four newest were never checked, and would have failed silently in somebody
# else's session while this printed ok. A list of things to check is a list that
# stops matching what exists, which is the same defect the coverage table exists
# to catch — found in the check that was supposed to be catching it.
# Every script under bin/, not a list of the ones somebody remembered: a probe
# or an evidence contract that names a bin script which lost its bit reads
# `unknown` and blocks, which is loud, but the gate should say why before the
# ledger has to.
# The check is a command now, engine/harness/bin/executable-check, for the same
# reason memory and independence became commands: a check that cannot be run on
# its own cannot be qualified, and this one had never been asked whether it
# fails when the thing it protects is broken. Asking it, blind, found that it
# demanded the mode bit of everything in those directories rather than of the
# scripts — a README beside the scanners turned the gate red. The scanner asks
# each file whether it opens with a shebang instead. Announced when absent,
# never silent (#77).
if [ -x engine/harness/bin/executable-check ]; then
  if OUT="$(engine/harness/bin/executable-check 2>&1)"; then
    pass executable
  else
    fail executable; printf '%s\n' "$OUT" | head -8 | sed 's/^/    /'
  fi
else
  printf '  %-18s skipped (no executable-check here)\n' executable
fi

# Moved above `tests` on 2026-08-13. This check had failed 8 times, every one of
# them discovered after a full suite run, because the loop is edit -> gate ->
# find it never deployed -> bump -> install -> gate again. `felix next` surfaced
# it as a lesson that was written down and kept being violated anyway, which is
# the signal that prose was never the fix. Nothing is removed and nothing is
# weakened: the same checks run, and the one that answers in a second now
# answers before the one that takes minutes.
# ------------------------------------------------------------- installed -----
# Written is not installed. The lessons hook existed in the repository, passed
# its tests, and was absent from the plugin cache, so it ran nowhere. A harness
# change that is not deployed governs nothing, and nothing else would have said
# so.
#
# WHAT IT ASKS, since #2 (docs/2026-08-18-promotion-spec.md, steps 2-4). It used
# to ask whether the engine in the tree standing here is the deployed one. Only
# the checkout the marketplace serves can ever answer yes, so `felix merge`
# existed in one folder, and the only workflow that reached it deployed the
# candidate before it was judged — by merge time the candidate was the
# evaluator. It now asks whether the cache entry for the version MAIN declares
# is byte-identical to MAIN's engine. Every checkout can answer that.
#
# WHO ANSWERS. felix_accepted_deploy_diff in lib/resolve.sh, the one reader of
# this question — the same function deploy-check asks for the engine_deployed
# obligation, so the gate and the ledger cannot disagree by construction. This
# block carried its own copy of that comparison until 2026-09-17, on the
# argument that a verifier which sources the code it judges can be switched off
# by editing that code. The argument stands and the copy does not: the function
# sourced here is read from the BASE REF with `git show`, never from this
# working tree and never from the cache entry, so the code that judges is the
# code main already accepted, and nothing a candidate branch writes reaches it.
# Sourced in a subshell, so its definitions never enter this gate. A base whose
# resolve.sh lacks the function cannot answer, and that is a FAIL naming it —
# never an ok and never a skip.
#
# Where "written is not installed" went (spec §8 criterion 2): on main, after a
# merge that changed the engine and before anybody deployed it, main's engine
# and its version's entry differ, and this fails. A version main declares with
# no entry at all fails too — never skips. All three deployed directories, not
# harness alone (#82), and a path git ignores is residue rather than drift (#86);
# both live in the function now, with their reasons beside them. One reading
# moved with them, found by review rather than by the suite: a directory main
# does not ship, present in the entry with nothing in it but ignored residue,
# was drift to the copy — the missing diff operand — and is residue to the
# function, because what git ignores is subtracted before the question is
# asked. That is what deploy-check already answered for the same fact; the
# gate says the same now, and the suite pins it beside felix_deploy_diff.
#
# What a green no longer says (spec §7): which engine is live. Installing a
# candidate adds a different entry and moves the live pointer without touching
# the one checked here. So when the CLI reports a live engine that is not
# main's, the ok says which one is, out loud rather than discovered.
#
# FELIX_KERNEL, the suite's override of the judge, is not honoured here: this
# checks the real cache. Skipped when no felix cache exists on this machine,
# which is the normal state in CI.
GCACHE="${FELIX_KERNEL_CACHE:-${FELIX_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}/felix/felix}"
if [ -d "$GCACHE" ]; then
  INSTALL_DRIFT=0
  : > /tmp/felix-install-drift.log
  GWHY=""
  # The branch being merged into, as felix_kernel_dir resolves it: origin/main
  # first, so a local main that lags the remote is not what gets certified.
  GBASE=""
  for GREF in origin/main main; do
    git rev-parse --verify "$GREF" >/dev/null 2>&1 && { GBASE="$GREF"; break; }
  done
  GVER=""
  [ -n "$GBASE" ] && GVER="$(git show "$GBASE:engine/.claude-plugin/plugin.json" 2>/dev/null \
    | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  PLUG=""
  GLIB=""
  if [ -z "$GBASE" ]; then
    GWHY="cannot tell which engine main accepted: no main here"
    INSTALL_DRIFT=1
  elif ! GLIB="$(mktemp -d 2>/dev/null)" || [ -z "$GLIB" ]; then
    GWHY="could not make a directory to read main's resolve.sh into"
    INSTALL_DRIFT=1
  elif ! git show "$GBASE:engine/harness/lib/resolve.sh" > "$GLIB/resolve.sh" 2>/dev/null; then
    GWHY="main's engine at $GBASE has no lib/resolve.sh, so nothing there defines felix_accepted_deploy_diff"
    INSTALL_DRIFT=1
  else
    # The verdict, from main's own reader. rc 0 prints the entry; rc 1 prints
    # every differing path, or one line naming the version nothing is
    # installed at; rc 2 prints why it could not examine. Exit 3 is this
    # block's own: the function is not defined at that base.
    GOUT="$( . "$GLIB/resolve.sh" >/dev/null 2>&1
             command -v felix_accepted_deploy_diff >/dev/null 2>&1 || exit 3
             felix_accepted_deploy_diff "$ROOT" 2>/dev/null )"; GRC=$?
    case "$GRC" in
      0) PLUG="$GOUT" ;;
      3) GWHY="main's engine at $GBASE cannot answer: its resolve.sh defines no felix_accepted_deploy_diff"
         INSTALL_DRIFT=1 ;;
      2) GWHY="$GOUT"; INSTALL_DRIFT=1 ;;
      *) printf '%s\n' "$GOUT" | grep . > /tmp/felix-install-drift.log
         INSTALL_DRIFT=1 ;;
    esac
  fi
  [ -n "$GLIB" ] && rm -rf "$GLIB"
  # A bump felix install wrote here has not reached main until it is merged,
  # and until then main still names the old entry. Said, because otherwise the
  # failure reads as a deploy that did not happen.
  GHERE="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' engine/.claude-plugin/plugin.json 2>/dev/null | head -1)"
  if [ "$INSTALL_DRIFT" -eq 0 ]; then
    pass installed
    printf '                     main declares %s, and %s is its engine\n' "$GVER" "$PLUG"
    GLIVE="$(claude plugin list --json 2>/dev/null \
             | sed -n '/"felix@felix"/,/}/p' \
             | sed -n 's/.*"installPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    if [ -n "$GLIVE" ] && [ "${GLIVE%/}" != "$PLUG" ]; then
      printf '                     the live engine is %s, not the one main declares\n' "${GLIVE##*/}"
    fi
  else
    MROOT=""
    if [ -r "$HOME/.claude/plugins/known_marketplaces.json" ]; then
      MROOT="$(sed -n '/"felix"[[:space:]]*:[[:space:]]*{/,/^  }/p' \
                 "$HOME/.claude/plugins/known_marketplaces.json" 2>/dev/null \
               | sed -n 's/.*"installLocation"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    fi
    if [ -n "$MROOT" ] && [ "$MROOT" != "$ROOT" ]; then
      # `structural` is load-bearing, not decoration: the engine subtracts
      # failures marked that way from what it writes to mistakes.log, and it
      # keys on that exact word (#3, #86). From a checkout the marketplace does
      # not serve, main's engine being undeployed is real and is not this
      # checkout's to fix — only the served checkout can deploy — so it is
      # marked, and every worktree gate does not record a mistake nobody here
      # made. No apostrophe in this format: the suite lifts it out of this file.
      printf '  %-18s FAIL (structural: the engine main declares is not the one deployed, and only the checkout the marketplace serves can deploy it — the marketplace serves %s)\n' installed "$MROOT"
      FAILED="$FAILED installed"
      [ -n "$GWHY" ] && printf '    %s\n' "$GWHY"
      head -5 /tmp/felix-install-drift.log | sed 's/^/    /'
      printf '    run felix install on main in %s\n' "$MROOT"
    else
      fail installed
      [ -n "$GWHY" ] && printf '    %s\n' "$GWHY"
      head -5 /tmp/felix-install-drift.log | sed 's/^/    /'
      [ -n "$GHERE" ] && [ "$GHERE" != "$GVER" ] \
        && printf '    this checkout declares %s and main declares %s: the bump reaches main by merging it\n' "$GHERE" "${GVER:-nothing}"
      printf '    reinstall with: felix install (on main)\n'
      # Deployable drift, and the remedy is here. Everything after this would be
      # spent verifying a tree whose accepted engine is not the one deployed,
      # and the suite alone is minutes. Not a loosening: the gate still fails,
      # for the same reason; it stops paying for checks whose answer is about to
      # be thrown away. The structural branch above does not stop, because its
      # remedy is somewhere else and its other results are all it can give.
      SKIP_REST=1
    fi
  fi
else
  printf '  %-18s skipped (no plugin installed here)\n' installed
fi

# ------------------------------------------------------------- tests ---------
if [ "${SKIP_REST:-0}" -eq 1 ]; then
  printf '  %-18s skipped (the deployed engine is not this tree)\n' tests
elif [ "${1:-}" = "--quick" ]; then
  printf '  %-18s skipped (--quick)\n' tests
elif ./engine/harness/tests/run >/tmp/felix-gate-tests.log 2>&1; then
  pass tests
  printf '                     %s\n' "$(tail -1 /tmp/felix-gate-tests.log)"
else
  fail tests
  # The evidence, not only the verdict (#86 again, one check over). bad() puts
  # its detail on the line AFTER `FAIL`, and this printed the FAIL line alone —
  # so a failure that only reproduces on the runner arrived as a name with
  # nothing under it, and the one line saying WHICH word leaked was in a log
  # file nobody can read from here.
  grep -A2 '^  FAIL' /tmp/felix-gate-tests.log | head -30 | sed 's/^/  /'
  printf '                     full log: /tmp/felix-gate-tests.log\n'
fi

# ------------------------------------------------------------- secret --------
if [ -x engine/harness/bin/secret-scan ]; then
  if OUT="$(engine/harness/bin/secret-scan 2>&1)"; then
    pass secret
  else
    fail secret; printf '%s\n' "$OUT" | head -8 | sed 's/^/    /'
  fi
else
  # Announced, not silent. This branch did not exist: a missing or non-executable
  # scanner printed NOTHING — no pass, no FAIL, no skip — so the gate's only
  # credential check could vanish and the report looked complete. The other two
  # skippable checks both say so, and this now matches them (#77, found while
  # fixing the confine that failed to cover this check).
  printf '  %-18s skipped (no secret-scan here)\n' secret
fi

# ------------------------------------------------------------- independence --
# The engine must name no specific project: constitution invariant 1, the
# property that makes Felix portable and the one most easily lost to a
# well-meant comment. The check itself lives in engine/harness/bin so that
# felix qualify can ask it whether it fails when the property is broken — the
# question every checker has to answer — without running this whole gate to
# find out. Its comments carry the history this section used to; what stays
# here is the same shape the secret check has: run it, and announce rather
# than go silent when it is missing.
# The ecosystem check below shares two things with this one: the four paths it
# greps, and the blindness verdict — a path nobody could search fails both, on
# the same evidence. Both are read off the scanner rather than kept as a second
# copy here, and both default to blind when the scanner is missing, so an
# absent scanner cannot turn either check green by having nothing to run.
INDEP_PATHS=""; INDEP_BLIND=" engine/harness/bin/independence-scan"
if [ -x engine/harness/bin/independence-scan ]; then
  INDEP_PATHS="$(engine/harness/bin/independence-scan --paths 2>/dev/null)"
  if OUT="$(engine/harness/bin/independence-scan 2>&1)"; then
    pass independence; INDEP_BLIND=""
  else
    fail independence; printf '%s\n' "$OUT" | head -8 | sed 's/^/    /'
    INDEP_BLIND="$(printf '%s\n' "$OUT" | sed -n 's/^independence-scan: cannot search://p' | head -1)"
  fi
else
  # Announced, not silent — the rule the secret check already holds (#77). An
  # absent scanner used to print nothing here, and a gate's only portability
  # check could vanish while the report looked complete.
  printf '  %-18s skipped (no independence-scan here)\n' independence
fi

# ------------------------------------------------------------- ecosystem -----
# Invariant 1, the half the name check cannot see.
#
# The block above proves the engine names no governed PROJECT. A detector under
# engine/harness hard-coded to FastAPI route decorators and an Anthropic client
# construction site contains no project name, passes it, and encodes exactly one
# project's shape into an engine whose whole claim is that it holds none. That
# is a design that was drafted for Felix, and it would have shipped. Same
# invariant, same sentence, one level up from the name.
#
# The words are enumerated off reality the way the names are, and reality here
# is the engine's own capability probe: every alternation token inside a
# _felix_dep_grep call in lib/detect.sh. Teaching the probe a new framework arms
# this check for it in the same commit, which is the property #85 bought - a
# hand-kept list is a list that stops matching what exists.
#
# A naive ban breaks the build and would deserve to: lib/detect.sh legitimately
# greps manifests for fastapi, stripe, sentry and supabase, because a capability
# probe naming many ecosystems symmetrically is how it stays neutral. So the
# boundary is declared per file, with a written reason, in engine/harness/ecosystem.tsv,
# in the same style as deny.tsv and the escape tables. A probe may name
# ecosystems; a detector that has already decided which project it is for may
# not, and a row has to say which it is.
#
# Word-boundaried, and that is measured. A substring search flags `cohere`
# inside "coherent", `vite` inside "invite" and `express` inside "expressed" in
# the engine's own prose right now, so the naive version fails open by being
# switched off after the third false positive.
ECO_TABLE=engine/harness/ecosystem.tsv
ECO_PROBE=engine/harness/lib/detect.sh

# Continuation lines joined first. The model-SDK probe sits on its own line, so
# a line-by-line read drops anthropic, openai and the rest of that vocabulary -
# which is half the case this check exists for, silently.
_eco_probe_words() {
  sed -e :a -e '/\\$/N; s/\\\n//; ta' "$ECO_PROBE" 2>/dev/null \
    | grep -oE '_felix_dep_grep "\$root" +"[^"]*(\\"[^"]*)*"' \
    | sed -E 's/.*_felix_dep_grep "\$root" +"//; s/"$//' \
    | sed 's/\\"?//g; s/\\"//g' | tr '|' '\n' \
    | sed 's/^ *//; s/ *$//' | grep -v '^$' | LC_ALL=C sort -u
}
# A row with no reason grants nothing. That is deliberate and it fails in the
# safe direction for two of the three kinds: an `allow` with no reason stops
# permitting, so the file leaks and this goes red, and a `mute` with no reason
# stops muting, so the word comes back into the vocabulary. Only a reasonless
# `word` row narrows, and the suite fails on any row missing a reason.
_eco_rows() {
  local want="$1" kind file token reason
  [ -f "$ECO_TABLE" ] || return 0
  while IFS=$'\t' read -r kind file token reason; do
    case "$kind" in ''|'#'*) continue ;; esac
    [ "$kind" = "$want" ] || continue
    [ -n "${token:-}" ] && [ -n "${reason:-}" ] || continue
    printf '%s\t%s\n' "$file" "$token"
  done < "$ECO_TABLE"
}

ECO_ALLOW="$(_eco_rows allow)"
ECO_WORDS="$( { _eco_probe_words; _eco_rows word | cut -f2 | tr '|' '\n'; } \
              | sed 's/^ *//; s/ *$//' | grep -v '^$' | LC_ALL=C sort -u \
              | grep -vxF -f <(_eco_rows mute | cut -f2 | tr '|' '\n' | grep -v '^$') )"

# Refusing to answer beats answering from nothing, which is the lesson the
# independence block above paid for twice. Three ways this reads the world and
# each can come back empty without erroring: the probe can be refactored past
# the extractor, the table can go missing, and a table with no allow rows would
# make the whole engine leak at once rather than narrow - but the first two
# narrow silently, and a vocabulary of nothing passes everything.
ECO_BLIND=""
[ -f "$ECO_PROBE" ]         || ECO_BLIND="$ECO_BLIND no-probe($ECO_PROBE)"
[ -f "$ECO_TABLE" ]         || ECO_BLIND="$ECO_BLIND no-table($ECO_TABLE)"
[ -n "$(_eco_probe_words)" ] || ECO_BLIND="$ECO_BLIND probe-yielded-no-words"
[ -n "$ECO_WORDS" ]          || ECO_BLIND="$ECO_BLIND empty-vocabulary"

# Does a row permit this file to say this word? `*` is the probe's row.
_eco_allowed() {
  local f="$1" w="$2" rf rt
  while IFS=$'\t' read -r rf rt; do
    [ "$rf" = "$f" ] || continue
    [ "$rt" = '*' ] && return 0
    case "|$rt|" in *"|$w|"*) return 0 ;; esac
  done <<EOF
$ECO_ALLOW
EOF
  return 1
}

ECO_LEAK=""
if [ -z "$ECO_BLIND" ] && [ -z "$INDEP_BLIND" ]; then
  while IFS= read -r w; do
    [ -n "$w" ] || continue
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      rel="${f#engine/harness/}"
      _eco_allowed "$rel" "$w" || ECO_LEAK="$ECO_LEAK
$rel names $w"
    done <<EOF
$(git grep -lwniE -- "$w" $INDEP_PATHS 2>/dev/null)
EOF
  done <<EOF
$ECO_WORDS
EOF
fi

# A row that no longer matches is a claim about a surface that is gone. Reported
# beside the verdict rather than failing: pruning it is somebody's judgement,
# and a check that fails on stale prose gets deleted. Reported at all because a
# surface built to report gaps that cannot report its own is an instance
# wearing a system's clothes (#125).
ECO_STALE=""
if [ -z "$ECO_BLIND" ]; then
  while IFS=$'\t' read -r rf rt; do
    [ -n "${rt:-}" ] || continue
    [ "$rt" = '*' ] && continue
    if [ ! -e "engine/harness/$rf" ]; then
      ECO_STALE="$ECO_STALE $rf(gone)"
    elif ! git grep -lwqiE -- "$rt" -- "engine/harness/$rf" >/dev/null 2>&1; then
      ECO_STALE="$ECO_STALE $rf:$rt"
    fi
  done <<EOF
$ECO_ALLOW
EOF
fi

if [ -n "$ECO_BLIND" ]; then
  fail ecosystem
  printf '    cannot answer:%s\n' "$ECO_BLIND"
  printf '    the words are read off %s and the reasons off %s;\n' "$ECO_PROBE" "$ECO_TABLE"
  printf '    with either missing this would pass by having nothing to check.\n'
elif [ -n "$INDEP_BLIND" ]; then
  fail ecosystem
  printf '    cannot search:%s\n' "$INDEP_BLIND"
  printf '    same blindness as independence above, and the same verdict.\n'
elif [ -n "$ECO_LEAK" ]; then
  fail ecosystem
  printf '    the engine hard-codes an ecosystem with no declared reason:\n'
  printf '%s\n' "$ECO_LEAK" | grep -v '^$' | head -10 | sed 's/^/      /'
  printf '    a capability probe may name one. A detector that encodes one\n'
  printf '    stack has already chosen its project. Declare it in %s\n' "$ECO_TABLE"
  printf '    with the reason, or stop naming it.\n'
else
  pass ecosystem
  [ -n "$ECO_STALE" ] && printf '                     stale rows, no longer matching:%s\n' "$ECO_STALE"
fi

# ------------------------------------------------------------- memory --------
# Two opposite properties, and until 2026-08-14 they were one.
#
# Doctrine must survive the machine, which is what this check was built for. A
# gitignore rule that swallows maintenance.log is invisible: every command works,
# every test passes, and nothing is kept. When it was first written `git
# ls-files` reported zero tracked .log files, so it had never survived once.
#
# Memory must not survive *into this repository*. It holds verbatim founder
# prompts and whatever a governed project's work happens to be about, which
# includes material belonging to somebody who never agreed to be published — so
# a repository storing every governed project's memory can never be public. The
# check that once demanded memory be tracked now demands the reverse. That
# reversal is the point and not a relaxation: this is the only thing that
# notices the old layout creeping back one project at a time, which is exactly
# how it would come back, since `felix adopt` is what creates the directory.
#
# Doctrine is checked against the path rather than against files that happen to
# exist. The first version of that loop skipped anything absent, which made it
# vacuous in a worktree — where these files are untracked and therefore not
# present — so it passed by finding nothing. git check-ignore evaluates a path
# whether or not anything is there, which is what makes it a real check.
#
# The check is a command now, engine/harness/bin/memory-scan, so felix qualify
# can ask whether it fails when the thing it protects is broken. The first time
# it was asked, blind, two things the inline form here could not see: `git
# check-ignore` never reports a TRACKED file, so the doctrine half only ever
# fired for a project whose log did not exist yet — the two that existed were
# invisible to it by construction; and memory is not a path, so lessons.md
# tracked one level up passed. Both are in the scanner's own comment. Announced
# when absent, never silent (#77).
if [ -x engine/harness/bin/memory-scan ]; then
  if OUT="$(engine/harness/bin/memory-scan 2>&1)"; then
    pass memory
  else
    fail memory; printf '%s\n' "$OUT" | head -8 | sed 's/^/    /'
  fi
else
  printf '  %-18s skipped (no memory-scan here)\n' memory
fi

echo
if [ -z "$FAILED" ]; then echo "gate: pass"; exit 0; fi
echo "gate: FAIL ($(echo "$FAILED" | tr -s ' ' | sed 's/^ //'))"
exit 1
