# >>> gate-friction-a-red-after
printf '\ngate friction A: tests/red --after waits for the record run\n'
# Blind, written from contract A alone (docs/2026-10-12-gate-friction-contract-a.md,
# C1, with C2.6's half that red can see) on 2026-10-12, before the code it
# describes existed. Every run is of this tree's tests/red, copied into a
# fixture repository whose main holds an old engine, as the recorded red run's
# own block does, with a working tree whose suite is a stub that prints three
# assertions, one of them failing, and the completion marker. The record run
# red waits for is played by a process this block names: this shell when it
# must outlive red, a process already gone, or one that ends while red waits.
# Every red run is killed if it has not ended in the limit its case sets, so a
# red that waits when it must not is a failure here and not a suite that hangs.
# An assertion whose name ends in (control) passes on the code before the
# change on purpose: it pins something the contract keeps as it is today.
GFB="$TMP/gfa-red"; mkdir -p "$GFB/tmpdir"
GFB_SPAWNED=""
_gfb_git() { git -c user.name=gfa -c user.email=gfa@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
_gfb_tree_of() {   # pid -> it and every process below it
  ps -A -o pid= -o ppid= 2>/dev/null | awk -v root="$1" '
    { kids[$2] = kids[$2] " " $1 }
    END { q = root; out = ""
          while (q != "") { n = split(q, a, " "); q = ""
                            for (i = 1; i <= n; i++) if (a[i] != "") { out = out " " a[i]; q = q kids[a[i]] } }
          print out }'
}
# <tenths> <out> <err> <dir> <cmd...>: runs cmd in dir; GFB_RC is its status,
# 124 when it had not ended after the limit and was killed with all below it;
# GFB_EL is how many tenths of a second it was waited for.
_gfb_run() {
  local lim="$1" out="$2" err="$3" dir="$4" pid n=0 k
  shift 4
  ( cd "${dir:?}" && exec "$@" ) > "$out" 2> "$err" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$n" -lt "$lim" ]; do sleep 0.1; n=$((n + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    for k in $(_gfb_tree_of "$pid"); do kill -9 "$k" 2>/dev/null; done
    wait "$pid" 2>/dev/null; GFB_RC=124
  else
    wait "$pid"; GFB_RC=$?
  fi
  GFB_EL="$n"
}
# The base's own run, never to be executed by red.
_gfb_base_run() { printf '%s\n' '#!/usr/bin/env bash' "printf '  FAIL  the base run was executed\\n'"; }
# The tree's suite. GFB_DIE ends it before its third assertion and before the
# marker; GFB_WRITE_MAN and GFB_WRITE_MARK make it do what a record run does
# while red's suite runs: write the manifest, then the mark, each whole. The
# manifest it writes is one, two, three and four, or with GFB_MAN_FROM the
# content of that file, or none at all when that file does not exist.
_gfb_suite() { cat <<'EOF'
#!/usr/bin/env bash
printf 'gfb stub suite\n\n  ok    one\n  ok    two\n'
[ "${GFB_DIE:-}" = 1 ] && kill -9 $$
printf '  FAIL  three\n        expected [a] got [b]\n'
if [ -n "${GFB_WRITE_MAN:-}" ] && [ -n "${GFB_MAN_FROM:-}" ]; then
  if [ -f "$GFB_MAN_FROM" ]; then cp "$GFB_MAN_FROM" "$GFB_WRITE_MAN.gfb" && mv -f "$GFB_WRITE_MAN.gfb" "$GFB_WRITE_MAN"
  else rm -f "$GFB_WRITE_MAN"; fi
elif [ -n "${GFB_WRITE_MAN:-}" ]; then
  printf '1\tone\n1\ttwo\n1\tthree\n1\tfour\n' > "$GFB_WRITE_MAN.gfb" && mv -f "$GFB_WRITE_MAN.gfb" "$GFB_WRITE_MAN"
fi
if [ -n "${GFB_WRITE_MARK:-}" ]; then
  printf 'written\n' > "$GFB_WRITE_MARK.gfb" && mv -f "$GFB_WRITE_MARK.gfb" "$GFB_WRITE_MARK"
fi
printf '\nreached\n  manifest comparison off (FELIX_TEST_NO_MANIFEST): this is a red run\n\n2 passed, 1 failed\n'
exit 1
EOF
}
# <dir> [branch]: main (or branch) holds engine 0.0.7, the base's run, this
# tree's red and a stale red.tsv; the working tree holds the stub suite and a
# manifest of one, two and three.
_gfb_seed() {
  local d="${1:?}" b="${2:-main}"
  mkdir -p "$d/engine/.claude-plugin" "$d/engine/harness/lib" "$d/engine/harness/tests"
  printf '{\n  "name": "felix",\n  "description": "fixture",\n  "version": "0.0.7"\n}\n' > "$d/engine/.claude-plugin/plugin.json"
  printf 'marker=old\n' > "$d/engine/harness/lib/marker.sh"
  _gfb_base_run > "$d/engine/harness/tests/run"; chmod +x "$d/engine/harness/tests/run"
  cp "$REAL_HARNESS/tests/red" "$d/engine/harness/tests/red"
  printf '# stale\nbase\tmain\tdeadbeef\t0.0.0\nrun\t1\t0\t0\nstale claim\t9\n' > "$d/engine/harness/tests/red.tsv"
  ( cd "$d" && _gfb_git init -q -b "$b" && _gfb_git add -A && _gfb_git commit -qm seed ) >/dev/null 2>&1
  _gfb_suite > "$d/engine/harness/tests/run"
  printf '1\tone\n1\tthree\n1\ttwo\n' > "$d/engine/harness/tests/assertions.tsv"
}
GFB_E=()   # extra environment for the next _gfb_red, cleared after it
_gfb_red() {   # <dir> <limit in tenths> <red args...>
  local d="$1" lim="$2"
  shift 2
  _gfb_run "$lim" "$GFB/out" "$GFB/err" "$d" env -u FELIX_TEST_NO_MANIFEST TMPDIR="$GFB/tmpdir" \
    "${GFB_E[@]+"${GFB_E[@]}"}" engine/harness/tests/red "$@"
  GFB_E=()
}
_gfb_said() { printf '%s|%s|%s' "$GFB_RC" "$(awk 'END { print NR }' "$GFB/out")" "$(cat "$GFB/out")"; }
_gfb_body() { grep -v '^#' "$1/engine/harness/tests/red.tsv" 2>/dev/null; }
_gfb_sum()  { sed -n '1s/ ([0-9a-f]*) / (SHA) /p' "$GFB/out"; }
_gfb_left() { ls -A "$GFB/tmpdir" | wc -l | tr -d ' '; }
_gfb_dead() { sh -c 'echo $$'; }   # a process id whose process has ended
# <command> -> the id of a process running it, detached from this shell, so
# that its end is seen by kill -0 at once and nothing here has to reap it.
_gfb_detached() { sh -c '( eval "$1" ) >/dev/null 2>&1 </dev/null & echo $!' _ "$1"; }
GFB_RETRACTED="$(printf 'base\t-\t-\t-\nrun\t-\t-\t-')"
GFB_NOARGS="red: not run: --after needs a mark file and a process id"

# ---- C1.2: arguments
GFB_A="$GFB/args"; _gfb_seed "$GFB_A"
_gfb_red "$GFB_A" 100 --after
is  "tests/red --after with neither a mark nor a process id is refused, exit 2, with the reason --after needs both" \
    "$(_gfb_said)" "2|1|$GFB_NOARGS"
is  "and red.tsv then holds the two retraction rows, the stale claim gone (control)" "$(_gfb_body "$GFB_A")" "$GFB_RETRACTED"
_gfb_red "$GFB_A" 100 --after "$GFB/args.mark"
is  "tests/red --after with a mark and no process id is refused the same way" "$(_gfb_said)" "2|1|$GFB_NOARGS"
_gfb_red "$GFB_A" 100 --after "$GFB/args.mark" 0
is  "a process id of 0 is not a positive decimal integer and is refused" "$(_gfb_said)" "2|1|$GFB_NOARGS"
_gfb_red "$GFB_A" 100 --after "$GFB/args.mark" -4
is  "a negative process id is refused" "$(_gfb_said)" "2|1|$GFB_NOARGS"
_gfb_red "$GFB_A" 100 --after "$GFB/args.mark" 1.5
is  "a process id with a decimal point is refused" "$(_gfb_said)" "2|1|$GFB_NOARGS"
_gfb_red "$GFB_A" 100 --after "$GFB/args.mark" main
is  "a branch name where the process id goes is refused, not read as the base" "$(_gfb_said)" "2|1|$GFB_NOARGS"
is  "and after each refusal red.tsv holds only the two retraction rows (control)" "$(_gfb_body "$GFB_A")" "$GFB_RETRACTED"

# ---- C1.5: the mark already written, the record run already gone
GFB_B="$GFB/done"; _gfb_seed "$GFB_B"; GFB_BSHA="$(git -C "${GFB_B:?}" rev-parse main)"
printf 'written\n' > "$GFB/done.mark"
_gfb_before="$(_gfb_left)"
_gfb_red "$GFB_B" 300 --after "$GFB/done.mark" "$(_gfb_dead)"
is  "--after with the mark written and the record run since ended is a red run, exit 0, the mark read first" "$GFB_RC" "0"
is  "and its record is main's base row, one of three failing and the failing name, as a red run without --after writes it" \
    "$(_gfb_body "$GFB_B")" "$(printf 'base\tmain\t%s\t0.0.7\nrun\t1\t2\t0\nthree\t1' "$GFB_BSHA")"
is  "and stdout is the one summary line a red run prints" \
    "$GFB_RC|$(awk 'END { print NR }' "$GFB/out")|$(_gfb_sum)" "0|1|red: 1 of 3 assertions fail against main (SHA) at engine 0.0.7"
is  "and it leaves no temporary directory behind" "$GFB_RC $(_gfb_left)" "0 $_gfb_before"
is  "and no worktree of main is left registered" "$GFB_RC $(git -C "${GFB_B:?}" worktree list 2>/dev/null | wc -l | tr -d ' ')" "0 1"
GFB_T="$GFB/trunk"; _gfb_seed "$GFB_T" trunk; GFB_TSHA="$(git -C "${GFB_T:?}" rev-parse trunk)"
_gfb_red "$GFB_T" 300 --after "$GFB/done.mark" "$$" trunk
is  "a base named after the mark and the process id is the base red runs against" \
    "$(_gfb_body "$GFB_T" | sed -n 1p)" "$(printf 'base\ttrunk\t%s\t0.0.7' "$GFB_TSHA")"

# ---- C1.3: the manifest is read after the mark, not before the suite
GFB_C="$GFB/late"; _gfb_seed "$GFB_C"; GFB_CSHA="$(git -C "${GFB_C:?}" rev-parse main)"
rm -f "$GFB_C/engine/harness/tests/assertions.tsv" "$GFB/late.mark"
GFB_E=(GFB_WRITE_MAN="$GFB_C/engine/harness/tests/assertions.tsv" GFB_WRITE_MARK="$GFB/late.mark")
_gfb_red "$GFB_C" 300 --after "$GFB/late.mark" "$$"
is  "with --after no assertions.tsv need be there when red starts, exit 0" "$GFB_RC" "0"
is  "and the manifest written while its suite ran is the one compared, a name only it lists counted red as never reached" \
    "$(_gfb_body "$GFB_C")" "$(printf 'base\tmain\t%s\t0.0.7\nrun\t2\t2\t0\nfour\t1\nthree\t1' "$GFB_CSHA")"
is  "and the summary says how many of them were never reached" \
    "$(_gfb_sum)" "red: 2 of 4 assertions fail against main (SHA) at engine 0.0.7, 1 of them never reached"

# ---- C1.4: an unfinished suite is refused first, without waiting
GFB_D="$GFB/dead"; _gfb_seed "$GFB_D"
printf 'x\tone\n' > "$GFB_D/engine/harness/tests/assertions.tsv"
GFB_E=(GFB_DIE=1)
_gfb_red "$GFB_D" 150 --after "$GFB/dead.mark" "$$"
_gfb_fast=slow; [ "$GFB_EL" -lt 50 ] && _gfb_fast=fast
is  "with --after a suite that did not finish is refused at once with today's reason, before a bad manifest is read" \
    "$(_gfb_said)|$_gfb_fast" "2|1|red: not run: the suite against main did not finish (exit 137 after 2 assertions)|fast"
is  "and red.tsv holds the two retraction rows for it (control)" "$(_gfb_body "$GFB_D")" "$GFB_RETRACTED"

# ---- C1.5: the record run ends and no mark comes
GFB_F="$GFB/gone"; _gfb_seed "$GFB_F"
_gfb_before="$(_gfb_left)"
GFB_P1="$(_gfb_detached 'exec sleep 2')"; GFB_SPAWNED="$GFB_SPAWNED $GFB_P1"
_gfb_red "$GFB_F" 150 --after "$GFB/gone.mark" "$GFB_P1"
is  "a record run that ends without a mark is refused, exit 2: it ended before it wrote the manifest" \
    "$(_gfb_said)" "2|1|red: not run: the record run ended before it wrote the manifest"
is  "and red.tsv holds the two retraction rows for a record run that ended (control)" "$(_gfb_body "$GFB_F")" "$GFB_RETRACTED"
is  "and that refusal leaves no temporary directory behind" "$(sed -n 1p "$GFB/out") $(_gfb_left)" \
    "red: not run: the record run ended before it wrote the manifest $_gfb_before"
# C2.6 as red sees it: the record run is ended by a signal, and its EXIT trap
# removes its temporary directory, the mark's path with it.
GFB_G="$GFB/signal"; _gfb_seed "$GFB_G"; mkdir -p "$GFB/signal.tmp"
GFB_P2="$(_gfb_detached 'exec sleep 30')"
GFB_P3="$(_gfb_detached "sleep 2; rm -rf '$GFB/signal.tmp'; kill -TERM $GFB_P2")"
GFB_SPAWNED="$GFB_SPAWNED $GFB_P2 $GFB_P3"
_gfb_red "$GFB_G" 150 --after "$GFB/signal.tmp/mark" "$GFB_P2"
is  "a record run ended by a signal, its directory and the mark's path removed, is read as ended before it wrote the manifest" \
    "$(_gfb_said)" "2|1|red: not run: the record run ended before it wrote the manifest"

# ---- C1.5: the mark comes while red waits
GFB_H="$GFB/wait"; _gfb_seed "$GFB_H"; GFB_HSHA="$(git -C "${GFB_H:?}" rev-parse main)"
rm -f "$GFB/wait.mark" "$GFB/wait.stamp"
GFB_P4="$(_gfb_detached "sleep 3; printf 'written\n' > '$GFB/wait.mark.t'; mv -f '$GFB/wait.mark.t' '$GFB/wait.mark'; date +%s > '$GFB/wait.stamp'")"
GFB_SPAWNED="$GFB_SPAWNED $GFB_P4"
( _gfb_red "$GFB_H" 200 --after "$GFB/wait.mark" "$$"; printf '%s %s\n' "$GFB_RC" "$(date +%s)" > "$GFB/wait.rc"; times > "$GFB/wait.cpu" )
read -r _gfb_wrc _gfb_wend < "$GFB/wait.rc"
is  "red waits for a mark written while it waits and then records, exit 0" \
    "$_gfb_wrc|$(_gfb_body "$GFB_H")" "$(printf '0|base\tmain\t%s\t0.0.7\nrun\t1\t2\t0\nthree\t1' "$GFB_HSHA")"
_gfb_wst="$(cat "$GFB/wait.stamp" 2>/dev/null)"
[ -n "$_gfb_wst" ] && [ "$_gfb_wrc" = 0 ] && [ "$_gfb_wend" -ge "$_gfb_wst" ] \
  && ok  "and it did not finish before the mark was written" \
  || bad "and it did not finish before the mark was written" "exit $_gfb_wrc, ended at ${_gfb_wend:-?}, mark at ${_gfb_wst:-never}"
_gfb_cpu="$(awk '{ for (i = 1; i <= NF; i++) { split($i, t, "m"); sub(/s$/, "", t[2]); ms += (t[1] * 60 + t[2]) * 1000 } } END { printf "%d", ms }' "$GFB/wait.cpu")"
[ "$_gfb_wrc" = 0 ] && [ "$_gfb_cpu" -le 1500 ] \
  && ok  "and over a wait of three seconds it spends under 1.5 s of CPU, checking no more than about once a second" \
  || bad "and over a wait of three seconds it spends under 1.5 s of CPU, checking no more than about once a second" \
         "exit $_gfb_wrc, ${_gfb_cpu} ms of CPU"

# ---- C1.5: a mark that does not read written
GFB_I="$GFB/notwritten"; _gfb_seed "$GFB_I"
printf 'failed\n' > "$GFB/nw.mark"
_gfb_red "$GFB_I" 300 --after "$GFB/nw.mark" "$$"
is  "a mark reading failed is refused, exit 2, naming what it read" \
    "$(_gfb_said)" "2|1|red: not run: the record run did not write a manifest (failed)"
is  "and red.tsv holds the two retraction rows for a mark that does not read written (control)" "$(_gfb_body "$GFB_I")" "$GFB_RETRACTED"
: > "$GFB/nw.mark"
_gfb_red "$GFB_I" 300 --after "$GFB/nw.mark" "$$"
is  "an empty mark is refused as empty" "$(_gfb_said)" "2|1|red: not run: the record run did not write a manifest (empty)"
printf 'written \n' > "$GFB/nw.mark"
_gfb_red "$GFB_I" 300 --after "$GFB/nw.mark" "$$"
is  "a mark whose first line is written and a blank is not exactly written" \
    "$(_gfb_said)" "2|1|red: not run: the record run did not write a manifest (written )"

# ---- C1.5: a written mark, then today's manifest refusals
# The manifest is sound when red starts and goes bad while its suite runs, as
# a record run would leave it, and the mark is written after it: so what is
# refused is the manifest red read after the mark.
GFB_J="$GFB/manifest"; _gfb_seed "$GFB_J"; GFB_JH="$(cd "${GFB_J:?}/engine/harness/tests" && pwd)"
_gfb_badman() {   # <manifest text, or - for none>
  rm -f "$GFB/m.mark" "$GFB/m.from"; [ "$1" = - ] || printf "$1" > "$GFB/m.from"
  printf '1\tone\n1\tthree\n1\ttwo\n' > "$GFB_J/engine/harness/tests/assertions.tsv"
  GFB_E=(GFB_WRITE_MAN="$GFB_J/engine/harness/tests/assertions.tsv" GFB_MAN_FROM="$GFB/m.from" GFB_WRITE_MARK="$GFB/m.mark")
  _gfb_red "$GFB_J" 300 --after "$GFB/m.mark" "$$"
}
_gfb_badman -
is  "after the mark, a manifest the record run removed is refused with today's reason for none" \
    "$(_gfb_said)" "2|1|red: not run: no readable assertions.tsv beside $GFB_JH/red"
_gfb_badman 'x\tone\n'
is  "after the mark, a row that is no count is refused with today's reason" \
    "$(_gfb_said)" "2|1|red: not run: assertions.tsv line 1 is not a count, a tab and a name"
_gfb_badman '1\tone\n1\tone\n'
is  "after the mark, a repeated name is refused with today's reason" \
    "$(_gfb_said)" "2|1|red: not run: assertions.tsv line 2 repeats a name an earlier line holds"
_gfb_badman ''
is  "after the mark, an empty manifest is refused with today's reason" \
    "$(_gfb_said)" "2|1|red: not run: assertions.tsv beside $GFB_JH/red lists no assertion"
is  "and red.tsv holds the two retraction rows after a manifest refusal (control)" "$(_gfb_body "$GFB_J")" "$GFB_RETRACTED"

# ---- the same red without --after (control)
GFB_K="$GFB/plain"; _gfb_seed "$GFB_K"; GFB_KSHA="$(git -C "${GFB_K:?}" rev-parse main)"
_gfb_red "$GFB_K" 300
is  "without --after red runs and records exactly as before (control)" \
    "$GFB_RC|$(_gfb_body "$GFB_K")" "$(printf '0|base\tmain\t%s\t0.0.7\nrun\t1\t2\t0\nthree\t1' "$GFB_KSHA")"
for _gfb_p in $GFB_SPAWNED; do kill "$_gfb_p" 2>/dev/null; done
