# >>> gate-friction-a-gate
printf '\ngate friction A: the gate reads a reused suite run\n'
# Blind, written from contract A alone (docs/2026-10-12-gate-friction-contract-a.md,
# C7) on 2026-10-12, before the code it describes existed. projects/felix/gate.sh
# is copied from this tree into a fixture checkout and run whole, standing in
# it. Every other check the gate makes can be satisfied or skipped there: a
# schema-check and an independence-scan that pass, a capability probe naming
# one word that nothing else names, no plugin cache (installed is skipped), and
# no scanner for the checks that announce a skip. So the gate's own verdict is
# the tests check's, and engine/harness/tests/run is a stub that writes down
# the arguments it was given and prints the log a mode file names. A run of the
# gate is killed if it has not ended in 30 s. An assertion whose name ends in
# (control) passes on the code before the change on purpose: it pins what the
# contract keeps as it is today.
GFG="$TMP/gfa-gate"; GFG_C="$GFG/c"; mkdir -p "$GFG/tmp" "$GFG/home" "$GFG/cache"
GFG_GATE="$REAL_HARNESS/../../projects/felix/gate.sh"
_gfg_git() { git -c user.name=gfa -c user.email=gfa@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
_gfg_tree_of() {   # pid -> it and every process below it
  ps -A -o pid= -o ppid= 2>/dev/null | awk -v root="$1" '
    { kids[$2] = kids[$2] " " $1 }
    END { q = root; out = ""
          while (q != "") { n = split(q, a, " "); q = ""
                            for (i = 1; i <= n; i++) if (a[i] != "") { out = out " " a[i]; q = q kids[a[i]] } }
          print out }'
}
mkdir -p "$GFG_C/engine/harness/bin" "$GFG_C/engine/harness/lib" "$GFG_C/engine/harness/tests" "$GFG_C/projects/felix"
[ -f "$GFG_GATE" ] && cp "$GFG_GATE" "$GFG_C/projects/felix/gate.sh"
printf '#!/bin/sh\nexit 0\n' > "$GFG_C/engine/harness/bin/schema-check"
printf '#!/bin/sh\n[ "${1:-}" = --paths ] && echo engine/harness/bin\nexit 0\n' > "$GFG_C/engine/harness/bin/independence-scan"
printf '_gfg_probe() {\n  _felix_dep_grep "$root" "gfgzzword"\n}\n' > "$GFG_C/engine/harness/lib/detect.sh"
printf '# kind\tfile\ttoken\treason\n' > "$GFG_C/engine/harness/ecosystem.tsv"
cat > "$GFG_C/engine/harness/tests/run" <<'EOF'
#!/usr/bin/env bash
printf '%s:%s\n' "$#" "$*" >> "${GFG_ARGS:?}"
case "$(cat "${GFG_MODE:?}")" in
  reused)     printf 'reused the suite run that ended 09:41 on this tree (normal), not run again\n\n12 passed, 0 failed (reused)\n'; exit 0 ;;
  notreused)  printf 'not reused: no receipt\n\ngfg stub\n  ok    gfg stub passes\n\n1 passed, 0 failed\n'; exit 0 ;;
  reusedfail) printf 'reused the suite run that ended 09:41 on this tree (normal), not run again\n  FAIL  gfg stub fails\n\n12 passed, 1 failed\n'; exit 1 ;;
esac
exit 3
EOF
chmod +x "$GFG_C/engine/harness/bin/schema-check" "$GFG_C/engine/harness/bin/independence-scan" "$GFG_C/engine/harness/tests/run"
( cd "${GFG_C:?}" && _gfg_git init -q -b main && _gfg_git add -A && _gfg_git commit -qm fixture ) >/dev/null 2>&1
# <name> <mode> [cache dir] [gate args...]: GFG_RC, and the output in $GFG/<name>.out.
_gfg_gate() {
  local n="$1" mode="$2" cache="$3" pid c=0 k
  shift 3
  printf '%s\n' "$mode" > "$GFG/mode"; : > "$GFG/args"
  ( cd "${GFG_C:?}" && exec env HOME="$GFG/home" FELIX_KERNEL_CACHE="$cache" TMPDIR="$GFG/tmp" \
      GFG_ARGS="$GFG/args" GFG_MODE="$GFG/mode" bash projects/felix/gate.sh "$@" ) > "$GFG/$n.out" 2>&1 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$c" -lt 300 ]; do sleep 0.1; c=$((c + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    for k in $(_gfg_tree_of "$pid"); do kill -9 "$k" 2>/dev/null; done
    wait "$pid" 2>/dev/null; GFG_RC=124
  else
    wait "$pid"; GFG_RC=$?
  fi
}
_gfg_after() { grep -A"$2" -xF -e "$3" "$GFG/$1.out" 2>/dev/null; }   # <run> <lines> <line>: it and the lines after it
_gfg_ind() { printf '%21s%s' '' "$1"; }
GFG_LINE_REUSED="$(printf '  %-18s reused' tests)"
GFG_LINE_OK="$(printf '  %-18s ok' tests)"

if [ ! -f "$GFG_GATE" ]; then
  for _gfg_a in "the gate runs the suite with --reuse" \
                "a suite that exits 0 and says it reused a run is reported as tests reused" \
                "followed by the log's first line and its last, each indented to column 21" \
                "and a reused suite run leaves the gate passing (control)" \
                "the receipt felix gate writes then reports tests:reused"; do
    skip "$_gfg_a" "no projects/felix/gate.sh beside this engine"
  done
else
  _gfg_gate reused reused "$GFG/nocache"
  is  "the gate runs the suite with --reuse" "$(cat "$GFG/args")" "1:--reuse"
  is  "a suite that exits 0 and says it reused a run is reported as tests reused" \
      "$(grep -cxF -e "$GFG_LINE_REUSED" "$GFG/reused.out") $(grep -cxF -e "$GFG_LINE_OK" "$GFG/reused.out")" "1 0"
  is  "followed by the log's first line and its last, each indented to column 21" \
      "$(_gfg_after reused 2 "$GFG_LINE_REUSED")" \
      "$GFG_LINE_REUSED
$(_gfg_ind 'reused the suite run that ended 09:41 on this tree (normal), not run again')
$(_gfg_ind '12 passed, 0 failed (reused)')"
  is  "and a reused suite run leaves the gate passing (control)" "$GFG_RC|$(sed -n '$p' "$GFG/reused.out")" "0|gate: pass"
  # felix gate keeps every check line the gate printed as name:verdict in its
  # receipt; its reader is asked here of this gate's output, read off the CLI.
  # 3c runs that awk in the C locale, so the reader is found with or without
  # its LC_ALL=C.
  _gfg_prog="$(awk -v q="'" 'index($0, "reported=\"$(awk " q) || index($0, "reported=\"$(LC_ALL=C awk " q) { s = substr($0, index($0, q) + 1); print substr(s, 1, index(s, q " \"$log\"") - 1); exit }' "$REAL_HARNESS/felix" 2>/dev/null)"
  if [ -z "$_gfg_prog" ]; then
    bad "the receipt felix gate writes then reports tests:reused" "no reader of the reported checks found in $REAL_HARNESS/felix"
  else
    _gfg_rep="$(awk "$_gfg_prog" "$GFG/reused.out" 2>/dev/null)"
    case ",$_gfg_rep," in
      *,tests:reused,*) ok  "the receipt felix gate writes then reports tests:reused" ;;
      *) bad "the receipt felix gate writes then reports tests:reused" "reported [$_gfg_rep]" ;;
    esac
  fi
  _gfg_gate notreused notreused "$GFG/nocache"
  is  "a suite that exits 0 having run is reported ok with its last line, as today (control)" \
      "$(_gfg_after notreused 1 "$GFG_LINE_OK")|$GFG_RC" "$GFG_LINE_OK
$(_gfg_ind '1 passed, 0 failed')|0"
  _gfg_gate reusedfail reusedfail "$GFG/nocache"
  is  "a suite that exits non-zero is a tests FAIL, whatever its first line says, as today (control)" \
      "$(grep -cxF -e "$(printf '  %-18s FAIL' tests)" "$GFG/reusedfail.out")|$(sed -n '$p' "$GFG/reusedfail.out")" "1|gate: FAIL (tests)"
  _gfg_gate quick reused "$GFG/nocache" --quick
  is  "--quick still skips the suite without running it (control)" \
      "$(grep -cxF -e "$(printf '  %-18s skipped (--quick)' tests)" "$GFG/quick.out")|$(cat "$GFG/args")" "1|"
  _gfg_gate installed reused "$GFG/cache"
  is  "after an installed failure the suite is still skipped, not run (control)" \
      "$(grep -cxF -e "$(printf '  %-18s skipped (the deployed engine is not this tree)' tests)" "$GFG/installed.out")|$(cat "$GFG/args")" "1|"
fi
is  "the gate still reports the suite with a pass tests line and a fail tests line the verifier confine counts (control)" \
    "$(awk '/^[[:space:]]*pass tests$/ { p = 1 } /^[[:space:]]*fail tests$/ { f = 1 } END { print p + 0, f + 0 }' "$GFG_GATE" 2>/dev/null)" "1 1"
