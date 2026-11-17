# >>> gate-friction-b
printf '\ngate friction B: the slow assertions (contract B, blind)\n'
_ib_build
# Blind, written from docs/2026-10-13-gate-friction-contract-b.md alone on
# 2026-10-13, before the code it describes existed. Nothing here was read off
# an implementation of it.
#
# B1 and B2 change parts 0580, 0900 and 0920, which run before this one in the
# same shell. B1 is asserted by running the 0580 block again, cut out of the
# part between its own comment and the next heading, with this part's own
# ok/bad/is/has/skip, so its verdicts are read here and counted nowhere else.
# A claude this part writes stands first on PATH beneath the block, and logs
# any call that reaches it: the block's own stub must stand in front of it. B2
# is asserted on the gh stub part 0900 wrote and on _ibsig itself.
#
# B3 (qualify rows in parallel) was cut from this PR after review, with its
# assertions: rows running at once share the repository's worktree list, and a
# column's git read while another row adds or removes its worktree fails with
# 128, which can turn a verdict. It goes back to its contract as a PR of its
# own (branch claude/gf-b3).
GFQ="$TMP/gfq-b"; mkdir -p "$GFQ"; GFQ="$(cd "$GFQ" && pwd -P)"
_gfq_q() { sed 's/^/| /' | head -20; }

# ---------------------------------------------------------------------- B1 ---
# The block, cut out of part 0580 as the suite has it now.
GFQ_BLK="$GFQ/b1-block.sh"
awk '$0 == "# It recommends. It must never acquire." { on = 1 }
     on && /^printf .*seeing the whole toolbox/ { exit }
     on { print }' "$HERE"/parts/0580-*.sh > "$GFQ_BLK" 2>/dev/null
mkdir -p "$GFQ/trip"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/trip.log"\nexit 3\n' "$GFQ" > "$GFQ/trip/claude"
chmod +x "$GFQ/trip/claude"
# The block's verdicts, one `ok|bad|skip <TAB> name` a line, run with FELIX
# and PATH as given and every other name as the suite has it.
_gfq_b1() {   # felix, PATH
  ( FELIX="$1"; PATH="$2"
    ok()   { printf 'GFQV\tok\t%s\n' "$1"; }
    bad()  { printf 'GFQV\tbad\t%s\n' "$1"; }
    skip() { printf 'GFQV\tskip\t%s\n' "$1"; }
    is()   { [ "$2" = "$3" ] && ok "$1" || bad "$1"; }
    has()  { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" ;; esac; }
    . "$GFQ_BLK" ) 2>/dev/null | LC_ALL=C awk -F'\t' '$1 == "GFQV" { print $2 "\t" $3 }'
}
_gfq_v() { printf '%s\n' "$1" | LC_ALL=C awk -F'\t' -v n="$2" '$2 == n { print $1 }' | tr '\n' ' ' | sed 's/ $//'; }
_gfq_noclaude() {
  local IFS=: d out=""
  for d in $PATH; do
    [ -n "$d" ] || continue
    [ -x "$d/claude" ] && continue
    out="${out:+$out:}$d"
  done
  printf '%s' "$out"
}
cp "$FROOT/projects/widget/stack.tsv" "$GFQ/stack.keep" 2>/dev/null
_gfq_restack() { cp "$GFQ/stack.keep" "$FROOT/projects/widget/stack.tsv" 2>/dev/null; }
# widget declares llm for the re-runs, besides whatever it declares, so that
# felix discover always has a rule to read a catalogue for: a project that
# declares nothing the rules name asks no claude anything, and a tripwire
# nobody could reach would pass over nothing. Put back after.
GFQ_CAPS="$FROOT/projects/widget/capabilities"; GFQ_CAPK=0
[ -f "$GFQ_CAPS" ] && cp "$GFQ_CAPS" "$GFQ/caps.keep" && GFQ_CAPK=1
grep -qx llm "$GFQ_CAPS" 2>/dev/null || printf 'llm\n' >> "$GFQ_CAPS"
GFQ_B1N="B1: the discovery block runs felix discover only with a claude the suite wrote first on PATH, never one it found there"
GFQ_B1K="B1: the block's two assertions keep their names and pass: discovery writes nothing, there is no --yes"
GFQ_B1P="B1: the block has a positive control besides those two, and it passes"
GFQ_B1M="B1: the block's discovery writes nothing fails against an engine whose plain felix discover appends a row to stack.tsv, with a claude on PATH the block did not write"
GFQ_B1X="B1: and fails against that engine with no claude anywhere on PATH"
if [ -s "$GFQ_BLK" ] && grep -q '"\$FELIX" discover' "$GFQ_BLK"; then
  : > "$GFQ/trip.log"
  GFQ_V="$(_gfq_b1 "$FELIX" "$GFQ/trip:$PATH")"; _gfq_restack
  if [ -s "$GFQ/trip.log" ]; then bad "$GFQ_B1N" "the claude PATH had took: $(_gfq_q < "$GFQ/trip.log" | tr '\n' ' ')"
  else ok "$GFQ_B1N"; fi
  is  "$GFQ_B1K" "$(_gfq_v "$GFQ_V" "discovery writes nothing") $(_gfq_v "$GFQ_V" "there is no --yes")" "ok ok"
  GFQ_VO="$(printf '%s\n' "$GFQ_V" | LC_ALL=C awk -F'\t' '$2 != "discovery writes nothing" && $2 != "there is no --yes"')"
  if [ -z "$GFQ_VO" ]; then bad "$GFQ_B1P" "the block made no assertion but the two it had"
  else is "$GFQ_B1P" "$(printf '%s\n' "$GFQ_VO" | cut -f1 | LC_ALL=C sort -u | tr '\n' ' ')" "ok "; fi
  # The mutant: plain discover, once it has read a catalogue, appends a row.
  rm -rf "$GFQ/mut"; cp -R "$FROOT/harness" "$GFQ/mut" 2>/dev/null
  GFQ_ANCH='  [ "$quiet" -eq 1 ] && _felix_discover_stamp_line "$tpl"'
  if [ "$(grep -cxF "$GFQ_ANCH" "$GFQ/mut/felix" 2>/dev/null)" = 1 ]; then
    LC_ALL=C awk -v a="$GFQ_ANCH" '$0 == a { print "  [ \"$quiet\" -eq 1 ] || printf '"'"'plugin\\tgfb-mutant\\t-\\tlow\\t-\\tOBSERVED\\n'"'"' >> \"$proj/stack.tsv\"" } { print }' \
      "$FROOT/harness/felix" > "$GFQ/mut/felix"
    chmod +x "$GFQ/mut/felix"
    GFQ_V="$(_gfq_b1 "$GFQ/mut/felix" "$GFQ/trip:$PATH")"; _gfq_restack
    is  "$GFQ_B1M" "$(_gfq_v "$GFQ_V" "discovery writes nothing")" "bad"
    GFQ_V="$(_gfq_b1 "$GFQ/mut/felix" "$(_gfq_noclaude)")"; _gfq_restack
    is  "$GFQ_B1X" "$(_gfq_v "$GFQ_V" "discovery writes nothing")" "bad"
  else
    bad "$GFQ_B1M" "the mutant could not be made: the line it goes before is not in felix once"
    bad "$GFQ_B1X" "the mutant could not be made"
  fi
else
  for _gfqn in "$GFQ_B1N" "$GFQ_B1K" "$GFQ_B1P" "$GFQ_B1M" "$GFQ_B1X"; do
    bad "$_gfqn" "part 0580 holds no block from \"# It recommends. It must never acquire.\" that runs felix discover"
  done
fi
# Added after review (finding B1-positive-control-unpinned-by-1270), from the
# contract's B1.2: a candidate lists only under what widget declares. With
# widget declaring nothing a discovery rule names, no catalogue entry can list,
# so the block's assertions besides its two must not all pass. Without this,
# GFQ_B1P passes for any extra assertion that passes.
GFQ_B1Z="B1: the block's positive control fails when widget declares nothing the discovery rules name, so no catalogue entry can list"
if [ -s "$GFQ_BLK" ] && grep -q '"\$FELIX" discover' "$GFQ_BLK"; then
  printf 'gfb-nothing-a-rule-names\n' > "$GFQ_CAPS"
  GFQ_V="$(_gfq_b1 "$FELIX" "$GFQ/trip:$PATH")"; _gfq_restack
  GFQ_VO="$(printf '%s\n' "$GFQ_V" | LC_ALL=C awk -F'\t' '$2 != "discovery writes nothing" && $2 != "there is no --yes" { print $1 }' | LC_ALL=C sort -u | tr '\n' ' ')"
  case " $GFQ_VO " in
    *" bad "*) ok  "$GFQ_B1Z" ;;
    *)         bad "$GFQ_B1Z" "the block's other verdicts with nothing declared: [$GFQ_VO]" ;;
  esac
else
  bad "$GFQ_B1Z" "part 0580 holds no block that runs felix discover"
fi
if [ "$GFQ_CAPK" -eq 1 ]; then cp "$GFQ/caps.keep" "$GFQ_CAPS"; else rm -f "$GFQ_CAPS"; fi

# ---------------------------------------------------------------------- B2 ---
GFQ_B2S="B2: the gh stub part 0900 writes no longer sleeps 30 s unconditionally once it has written its pid"
GFQ_B2A="B2: when _ibsig sends the signal the gh stub is still waiting, and the run then leaves no scratch (control)"
if [ -n "${IB:-}" ] && [ -f "$IB/stub/gh" ]; then
  if grep -q 'exec sleep 30' "$IB/stub/gh"; then bad "$GFQ_B2S" "$(grep -n 'sleep 30' "$IB/stub/gh" | _gfq_q)"
  else ok "$GFQ_B2S"; fi
else
  bad "$GFQ_B2S" "part 0900 left no gh stub at \$IB/stub/gh"
fi
if [ "$(type -t _ibsig)" = function ] && [ -n "${IB:-}" ] && command -v perl >/dev/null 2>&1; then
  # kill, shadowed for the one call: whether the stub is alive when the
  # signal goes, and still alive a second later, before it is sent.
  GFQ_B2R="$( kill() {
                case " $* " in
                  (" -TERM "*|" -HUP "*|" -INT "*|" -s TERM "*|" -s HUP "*|" -s INT "*)
                    local g j=0 st=alive
                    g="$(cat "$IB/gh.pid" 2>/dev/null)"
                    if [ -z "$g" ] || ! builtin kill -0 "$g" 2>/dev/null; then st=released
                    else
                      while [ "$j" -lt 10 ]; do
                        builtin kill -0 "$g" 2>/dev/null || { st=released; break; }
                        sleep 0.1; j=$((j + 1))
                      done
                    fi
                    printf '%s ' "$st" ;;
                esac
                builtin kill "$@"; }
              _ibsig TERM )"
  is  "$GFQ_B2A" "$GFQ_B2R" "alive gone"
else
  bad "$GFQ_B2A" "part 0920's _ibsig, part 0900's \$IB or perl is not here"
fi

# ---------------------------------------------------------------------- B4 ---
# _sr_env's host: LocalHostName from /usr/sbin/scutil when that answers with a
# valid name (contract B4.1), else uname -n (B4.4). Asked of receipt.sh in a
# child bash given nothing but PATH and HOME, as part 1200 asks it. The
# expected name is computed here from the contract's words: the file is
# executable, the command exits 0, and its output is one non-empty line of
# only ASCII letters, digits and hyphens.
GFQ_R="$REAL_HARNESS/tests/receipt.sh"
GFQ_P="$(dirname "$(command -v git)"):/usr/bin:/bin"
_gfq_alone() { env -i PATH="$GFQ_P" HOME="$HOME" "$@"; }
_gfq_env() { _gfq_alone "$@" bash -c '. "$1" >/dev/null 2>&1 || exit 97; _sr_env' _ "$GFQ_R" 2>/dev/null; }
_gfq_host() { printf '%s\n' "$1" | sed -n 's/^host=\([^;]*\);.*$/\1/p'; }
GFQ_LH=""; GFQ_LHOK=0
if [ -x /usr/sbin/scutil ]; then
  if GFQ_LH="$(/usr/sbin/scutil --get LocalHostName 2>/dev/null)"; then
    case "$GFQ_LH" in
      ""|*[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-]*) ;;
      *) GFQ_LHOK=1 ;;
    esac
  fi
fi
GFQ_B4A="B4: where scutil gives a valid LocalHostName, _sr_env's host is that name"
GFQ_B4B="B4: with a uname on PATH that names a new host on every call, two _sr_env calls give the same host, and not the stub's"
GFQ_B4C="B4: where scutil is absent or gives nothing valid, _sr_env's host is uname -n"
GFQ_B4D="B4: _sr_env's other four fields are bash, locale, path and claude, in that order, on one line (control)"
GFQ_E0="$(_gfq_env)"
if [ ! -x /usr/sbin/scutil ]; then
  skip "$GFQ_B4A" "/usr/sbin/scutil is not executable here"
  skip "$GFQ_B4B" "/usr/sbin/scutil is not executable here"
elif [ "$GFQ_LHOK" -ne 1 ]; then
  skip "$GFQ_B4A" "scutil --get LocalHostName gave no valid name here"
  skip "$GFQ_B4B" "scutil --get LocalHostName gave no valid name here"
else
  is "$GFQ_B4A" "$(_gfq_host "$GFQ_E0")" "$GFQ_LH"
  mkdir -p "$GFQ/unm"; : > "$GFQ/unm.n"
  printf '#!/bin/sh\nprintf x >> "%s/unm.n"\nprintf "gfq-stub-%%s\\n" "$(wc -c < "%s/unm.n" | tr -d " ")"\n' "$GFQ" "$GFQ" > "$GFQ/unm/uname"
  chmod +x "$GFQ/unm/uname"
  GFQ_S1="$(_gfq_alone PATH="$GFQ/unm:$GFQ_P" bash -c '. "$1" >/dev/null 2>&1 || exit 97; _sr_env' _ "$GFQ_R" 2>/dev/null)"
  GFQ_S2="$(_gfq_alone PATH="$GFQ/unm:$GFQ_P" bash -c '. "$1" >/dev/null 2>&1 || exit 97; _sr_env' _ "$GFQ_R" 2>/dev/null)"
  GFQ_H1="$(_gfq_host "$GFQ_S1")"; GFQ_H2="$(_gfq_host "$GFQ_S2")"
  GFQ_U1="$(PATH="$GFQ/unm:$GFQ_P" uname -n)"; GFQ_U2="$(PATH="$GFQ/unm:$GFQ_P" uname -n)"
  if [ "$GFQ_U1" = "$GFQ_U2" ]; then
    bad "$GFQ_B4B" "the stub uname named one host twice ([$GFQ_U1]), so it proves nothing"
  else
    case "$GFQ_H1" in
      "" | gfq-stub-*) bad "$GFQ_B4B" "first host [$GFQ_H1] second [$GFQ_H2]" ;;
      *) is "$GFQ_B4B" "$GFQ_H2" "$GFQ_H1" ;;
    esac
  fi
fi
if [ -x /usr/sbin/scutil ] && [ "$GFQ_LHOK" -eq 1 ]; then
  skip "$GFQ_B4C" "scutil answers LocalHostName here; this one runs where it does not"
else
  is "$GFQ_B4C" "$(_gfq_host "$GFQ_E0")" "$(uname -n)"
fi
GFQ_BV="$(_gfq_alone bash -c 'printf %s "$BASH_VERSION"' 2>/dev/null)"
GFQ_PH1="$(printf '%s' "$GFQ_P" | git hash-object --stdin)"; GFQ_PH2="$(printf '%s\n' "$GFQ_P" | git hash-object --stdin)"
GFQ_CL="$(_gfq_alone bash -c 'command -v claude >/dev/null 2>&1 && echo yes || echo no' 2>/dev/null)"
case "$GFQ_E0" in
  *"
"*) bad "$GFQ_B4D" "more than one line: [$GFQ_E0]" ;;
  "host="*";bash=$GFQ_BV;locale=;path=$GFQ_PH1;claude=$GFQ_CL"|"host="*";bash=$GFQ_BV;locale=;path=$GFQ_PH2;claude=$GFQ_CL")
    case "$(_gfq_host "$GFQ_E0")" in
      "" | *";"*) bad "$GFQ_B4D" "the host field is empty or holds a ;: [$GFQ_E0]" ;;
      *) ok "$GFQ_B4D" ;;
    esac ;;
  *) bad "$GFQ_B4D" "got [$GFQ_E0]" ;;
esac
# <<< gate-friction-b
