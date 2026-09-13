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
# Compared against the version actually active, not merely the first one found.
# The cache keeps every version it has ever installed, so after a bump from
# 0.1.0 to 0.2.0 the old copy is still sitting there and `head -1` picks it:
# the check then fails permanently against a directory nothing loads, while a
# genuinely stale deployment would look identical. Ask the CLI, which knows
# which one is live; fall back to the highest version when it is absent.
#
# Skipped when no plugin is installed, which is the normal state in CI.
PLUG="$(claude plugin list --json 2>/dev/null \
        | sed -n '/"felix@felix"/,/}/p' \
        | sed -n 's/.*"installPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
if [ -z "$PLUG" ]; then
  PLUG="$(ls -d "$HOME"/.claude/plugins/cache/felix/felix/* 2>/dev/null | sort -V | tail -1)"
fi
# All three deployed directories, not harness alone (#82). hooks/hooks.json is
# the file that decides which hooks BIND, so a deploy that carried harness/ and
# dropped hooks/ read as `installed ok` while every session ran yesterday's
# bindings — a hook binary deployed perfectly and running nowhere. commands/ is
# executed by the runtime the same way. A directory absent from both sides is a
# fixture, not a drift; absent from one side, diff fails on the missing operand,
# which is the verdict. engine/.claude-plugin stays out: plugin.json differs
# whenever a bump is pending, which is this tree's normal state. Inline rather
# than the engine's felix_deploy_diff, deliberately: a verifier that sources the
# code it judges can be switched off by editing that code.
if [ -n "$PLUG" ] && [ -d "$PLUG" ]; then
  INSTALL_DRIFT=0
  : > /tmp/felix-install-drift.log
  # A path the repository itself declares non-content is residue, not drift
  # (#86): a claude-flow hook dropped state under tests/ mid-suite and this
  # check called a byte-identical deploy a drift, then misdiagnosed it as
  # structural. Each diff line maps to one path, and a path git ignores in
  # this tree is skipped — on either side, since a stray in the cache is a
  # deployed stray. Untracked-but-not-ignored still counts: undeployed work.
  # Missing-operand errors match no path shape and always survive.
  for d in harness hooks commands; do
    [ -e "engine/$d" ] || [ -e "$PLUG/$d" ] || continue
    while IFS= read -r IDLINE; do
      [ -n "$IDLINE" ] || continue
      IDP=""
      case "$IDLINE" in
        "Files engine/"*)
          # The filename itself may contain " and ": the separator matched is
          # the whole " and $PLUG/…" tail, never the first " and ", or
          # check-ignore is answered about a truncated fragment and an ignore
          # rule matching it certifies real drift as clean.
          IDP="${IDLINE#Files engine/}"; IDP="${IDP% differ}"; IDP="${IDP% and "$PLUG"/*}" ;;
        "Only in engine: "*|"Only in engine/"*)
          IDREST="${IDLINE#Only in }"; IDDIR="${IDREST%%: *}"; IDNAME="${IDREST#*: }"
          if [ "$IDDIR" = "engine" ]; then IDP="$IDNAME"; else IDP="${IDDIR#engine/}/$IDNAME"; fi ;;
        "Only in $PLUG: "*|"Only in $PLUG/"*)
          IDREST="${IDLINE#Only in }"; IDDIR="${IDREST%%: *}"; IDNAME="${IDREST#*: }"
          if [ "$IDDIR" = "$PLUG" ]; then IDP="$IDNAME"; else IDP="${IDDIR#"$PLUG"/}/$IDNAME"; fi ;;
      esac
      # Twice, because a directory-only pattern like `.claude-flow/` matches
      # only what git can see is a directory, and a cache-side stray does not
      # exist in the tree; the trailing slash says what it is. The global
      # excludes file is shut off — a verifier whose verdict varies with one
      # machine's personal ignore rules is not a verifier.
      if [ -n "$IDP" ] && { git -C engine -c core.excludesFile=/dev/null check-ignore -q "$IDP" \
             || git -C engine -c core.excludesFile=/dev/null check-ignore -q "$IDP/"; } 2>/dev/null; then
        continue
      fi
      printf '%s\n' "$IDLINE" >> /tmp/felix-install-drift.log
      INSTALL_DRIFT=1
    done <<EOF
$(diff -rq "engine/$d" "$PLUG/$d" 2>&1)
EOF
  done
  if [ "$INSTALL_DRIFT" -eq 0 ]; then
    pass installed
  else
    # A worktree can never satisfy this. The felix marketplace is a directory
    # marketplace pinned to one path, so a worktree's engine is not the one being
    # served and no amount of installing will make the cache match it. The gate
    # still fails — the tree genuinely does not match, and quieting that would be
    # loosening a gate to improve a number — but the failure is marked so it is
    # not written down as a mistake somebody made. Every gate run in a worktree
    # used to add an `installed` row, which is how that check reached 11 and
    # became the top entry of `felix next` rank 5: it manufactured the evidence
    # that ranked it. See issue #3.
    MROOT=""
    if [ -r "$HOME/.claude/plugins/known_marketplaces.json" ]; then
      MROOT="$(sed -n '/"felix"[[:space:]]*:[[:space:]]*{/,/^  }/p' \
                 "$HOME/.claude/plugins/known_marketplaces.json" 2>/dev/null \
               | sed -n 's/.*"installLocation"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    fi
    if [ -n "$MROOT" ] && [ "$MROOT" != "$ROOT" ]; then
      # `structural` is load-bearing, not decoration: the engine subtracts
      # failures marked that way from what it writes to mistakes.log, and it
      # keys on that exact word. Rewriting this message to stop it
      # misdiagnosing a stray (#86) dropped the word, so every worktree gate
      # failure went back to recording a mistake nobody made — the
      # manufactured evidence of #3, returned by a message improvement. The
      # evidence below is that improvement; this word is the contract.
      printf '  %-18s FAIL (structural: drift in a tree that cannot deploy — the marketplace serves %s)\n' installed "$MROOT"
      FAILED="$FAILED installed"
      # The evidence, not only the verdict (#86). This branch used to print an
      # instruction while hiding the one line naming the actual drift, and a
      # session repeated the wrong diagnosis rather than reading the log.
      head -5 /tmp/felix-install-drift.log | sed 's/^/    /'
      printf '    a worktree passes when byte-identical to the deployed engine; if the\n'
      printf '    drift above is real work, merge it and run felix install in %s\n' "$MROOT"
    else
      fail installed
      head -5 /tmp/felix-install-drift.log | sed 's/^/    /'
      printf '    reinstall with: felix install\n'
      # Deployable drift, and the remedy is one command. Everything after this
      # would be spent verifying a tree whose engine is not the one any session
      # is running, and the suite alone is minutes. It has cost that twenty-two
      # times: `installed` is the top row of felix next's "already cost time
      # more than once", and the lesson beside it cannot help, because the
      # remedy is procedural rather than something a person learns once.
      #
      # Not a loosening. The gate still fails, and fails for the same reason it
      # did before; it simply stops paying for checks whose answer is about to
      # be thrown away. The structural branch above does NOT stop, because a
      # worktree can never satisfy this check and its other results are the
      # only ones it can give.
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
