# tests/lib/instrument-parts.sh: the fixture of part 2180 (trust-plane step 3, slice 3, blind), as functions that
# part calls. Definitions only (contract C2): sourcing this file defines functions and nothing else, and every
# variable they use is set by part 2180 or by _ts3c_build when it is called. Every file they write is under $TS3C.
#
# _ts3c_build makes R, a Felix-shaped repository (felix_self_governed_at names it: engine/.claude-plugin/plugin.json
# is a blob at every ref here but the product's), whose main B holds:
# - engine/harness: the harness under test, its tests/ replaced by a small suite of the fixture's own (below);
# - engine/widget/: the engine that suite judges (lib.sh with add and mul; list.txt, greet.txt, color.txt,
#   version.txt; notes.txt, which no part reads);
# - engine/harness/tests: run (the driver: ok, bad, is, has, one `. "$HERE/parts/<file>"` line per part, and part
#   mode, tests/run --part NAME..., printing @@prelude-done, @@member-done NAME and @@part-done NAME... and writing
#   the end file contract D's FELIX_TEST_PART_END names), lib/widget.sh, groups.tsv (group g1: 2003, 2004),
#   assertions.tsv (the manifest), receipt.sh, red, and canary/ when the harness under test has one;
# - parts 2001-sum.sh (instrument), 2002-count.sh (subject), 2003-grp-a.sh (instrument) and 2004-grp-b.sh
#   (subject), the group g1, 2005-mul.sh (no row) and 2006-keep.sh (instrument, two assertions). Each part first
#   appends its file name to $TS3C/trace, an absolute path outside every tree, so a run of it can be seen;
# - projects/felix/: the project (name felix), its tables, gate.sh and partition.tsv; .github/workflows/gate.yml.

_ts3c_commit() {   # REPO MSG: one commit of everything, with maintenance off
  _fx_git "$1" add -A >/dev/null 2>&1
  _fx_git "$1" -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c maintenance.auto=false commit -qm "$2" >/dev/null 2>&1
}
_ts3c_case() { ( _fx_cd "$TS3CR" && git checkout -q -f main && git checkout -q -B "$1" "${2:-main}" ) >/dev/null 2>&1; }   # BRANCH [FROM]
_ts3c_on() { ( _fx_cd "$TS3CR" && git checkout -q -f "$1" ) >/dev/null 2>&1; }   # BRANCH: R checked out at it
_ts3c_part() {   # FILE BODY: a part of the fixture suite that first traces its own name
  printf "printf '%%s\\\\n' %s >> \"%s\"\n. \"\$HERE/../../widget/lib.sh\"; W=\"\$HERE/../../widget\"\n%s\n" \
    "$1" "$TS3C/trace" "$2" > "$TS3CR/engine/harness/tests/parts/$1"
}
_ts3c_driver() {   # FILE BAD-BODY IS-BODY [EXTRA]: the fixture driver, with the bodies of bad() and is() given
  local q="'"
  {
    printf '#!/usr/bin/env bash\n# The fixture suite: helpers, one line a part, and part mode (contract D: tests/run --part NAME...).\n'
    printf 'HERE="$(cd "$(dirname "$0")" && pwd)"\n%s\n' "${4:-}"
    printf 'PASS=0; FAIL=0; _ranf="${FELIX_TEST_PART_RAN-}"; _endf="${FELIX_TEST_PART_END-}"; _logf="${FELIX_TEST_PART_LOG-}"\n'
    printf 'unset FELIX_TEST_PART_RAN FELIX_TEST_PART_END FELIX_TEST_PART_LOG FELIX_TEST_PART_RECORD\n'
    printf '_ran() { [ -z "$_ranf" ] || printf %s "$1" >> "$_ranf"; }\n' "$q%s\\n$q"
    printf 'ok()  { PASS=$((PASS+1)); _ran "$1"; printf %s "$1"; }\n' "$q  ok    %s\\n$q"
    printf 'bad() { %s }\n' "$2"
    printf 'is()  { %s }\n' "$3"
    printf 'has() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "[$2] lacks [$3]" ;; esac; }\n'
    printf '. "$HERE/lib/widget.sh"\n'
    printf 'if [ "${1:-}" = --part ]; then\n  shift\n'
    printf '  for _p in "$@"; do [ -f "$HERE/parts/$_p" ] || { printf %s "$_p" >&2; exit 2; }; done\n' "${q}tests/run: no part [%s]\\n$q"
    printf '  [ -z "$_logf" ] || exec >> "$_logf" 2>&1\n  printf %s\n' "$q@@prelude-done\\n$q"
    printf '  for _p in "$@"; do . "$HERE/parts/$_p"; printf %s "$_p"; done\n' "$q@@member-done %s\\n$q"
    printf '  [ -z "$_endf" ] || printf %s "$FAIL" > "$_endf"\n' "${q}floor\\tok\\nog\\tok\\nfail\\t%s\\nprefail\\t0\\nshell\\tok\\nend\\t1\\n$q"
    printf '  printf %s "$*"\n  exit 0\nfi\n' "$q@@part-done %s\\n$q"
    for _ts3c_p in 2001-sum.sh 2002-count.sh 2003-grp-a.sh 2004-grp-b.sh 2005-mul.sh 2006-keep.sh; do
      printf '. "$HERE/parts/%s"\n' "$_ts3c_p"
    done
    printf 'printf %s "$PASS" "$FAIL"\n[ "$FAIL" -eq 0 ]\n' "$q\\nreached\\n%d passed, %d failed\\n$q"
  } > "$1"
  chmod 755 "$1"
}
_ts3c_honest_bad() { printf '%s' 'FAIL=$((FAIL+1)); _ran "$1"; printf '"'"'  FAIL  %s\n'"'"' "$1"; [ -n "${2:-}" ] && printf '"'"'        %s\n'"'"' "$2"; return 0;'; }
_ts3c_honest_is() { printf '%s' '[ "$2" = "$3" ] && ok "$1" || bad "$1" "expected [$3] got [$2]";'; }
_ts3c_mani() {   # SED-SCRIPT: R's manifest is P's names edited by SED-SCRIPT, once each, count<TAB>name in name order
  _ts3c_names | LC_ALL=C sed "$1" | LC_ALL=C sort | LC_ALL=C awk 'NF { printf "1\t%s\n", $0 }' > "$TS3CR/engine/harness/tests/assertions.tsv"
}
_ts3c_names() {   # the names P's parts assert, one a line
  printf '%s\n' 'sum: add 2 3 is 5' 'sum: add 0 0 is 0' 'count: the list holds exactly 3 items' 'grp-a: the greeting says hello' \
    'grp-b: the colour is blue' 'mul: mul 2 3 is 6' 'keep: the version file says 1' 'keep: the version file is one line'
}
_ts3c_build() {   # -> R at main (B), the entry K/1.0.0 cut from it, P's project directory TS3CPP, and the provider stub
  local t="$TS3CR/engine/harness/tests" w="$TS3CR/engine/widget" p="$TS3CR/projects/felix"
  ( _fx_cd "$TS3CR" && git init -q -b main && git remote add origin https://github.com/example/ts3c.git \
    && git config gc.auto 0 && git config maintenance.auto false ) >/dev/null 2>&1
  _copy_content "$REAL_HARNESS" "$TS3CR/engine/harness"; _copy_content "$REAL_HARNESS/../hooks" "$TS3CR/engine/hooks"
  [ -d "$REAL_HARNESS/../commands" ] && _copy_content "$REAL_HARNESS/../commands" "$TS3CR/engine/commands"
  rm -rf "${t:?}"; mkdir -p "$t/parts" "$t/lib" "$w" "$p" "$TS3CR/engine/.claude-plugin" "$TS3CR/.github/workflows"
  [ ! -d "$REAL_HARNESS/tests/canary" ] || cp -R "$REAL_HARNESS/tests/canary" "$t/canary"
  printf '{ "name": "felix", "version": "1.0.0" }\n' > "$TS3CR/engine/.claude-plugin/plugin.json"
  printf 'state/\n*.log\n' > "$TS3CR/.gitignore"; printf 'felix\n' > "$TS3CR/.felix"
  printf '{\n  "name": "felix",\n  "remote_match": "example.com/ts3c",\n  "gate": "true",\n  "gate_workflow": "gate.yml"\n}\n' > "$p/project.json"
  printf '# felix (fixture)\n' > "$p/CLAUDE.md"
  printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$p/probes.tsv"
  printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds\n' > "$p/obligations.tsv"
  printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n' > "$p/commissioning.tsv"
  cp "$REAL_HARNESS/templates/risk.tsv" "$p/risk.tsv"
  printf '#!/usr/bin/env bash\n# The fixture gate: the suite, one unit at a time.\nFELIX_TEST_JOBS=1 bash engine/harness/tests/run\n' > "$p/gate.sh"
  printf '# part\tclass\twhy\n2001-sum.sh\tinstrument\tguards add\n2002-count.sh\tsubject\tan exact count each release sets\n' > "$p/partition.tsv"
  printf '2003-grp-a.sh\tinstrument\tguards the greeting\n2004-grp-b.sh\tsubject\tthe colour is the release'"'"'s\n' >> "$p/partition.tsv"
  printf '2006-keep.sh\tinstrument\tguards the version file\n' >> "$p/partition.tsv"
  printf 'on: pull_request\njobs: {}\n' > "$TS3CR/.github/workflows/gate.yml"
  printf 'add() { printf "%%s\\n" "$(( $1 + $2 ))"; }\nmul() { printf "%%s\\n" "$(( $1 * $2 ))"; }\n' > "$w/lib.sh"
  printf 'one\ntwo\nthree\n' > "$w/list.txt"; printf 'hello world\n' > "$w/greet.txt"; printf 'blue\n' > "$w/color.txt"
  printf '1\n' > "$w/version.txt"; printf 'notes no part reads\n' > "$w/notes.txt"
  _ts3c_driver "$t/run" "$(_ts3c_honest_bad)" "$(_ts3c_honest_is)"
  printf 'widget_dir() { printf "%%s" "$HERE/../../widget"; }\n' > "$t/lib/widget.sh"
  printf 'g1\t2003-grp-a.sh\ng1\t2004-grp-b.sh\n' > "$t/groups.tsv"
  printf '# the fixture has no receipt\n' > "$t/receipt.sh"; printf '#!/usr/bin/env bash\nexit 0\n' > "$t/red"; chmod 755 "$t/red"
  _ts3c_part 2001-sum.sh 'is "sum: add 2 3 is 5" "$(add 2 3)" 5
is "sum: add 0 0 is 0" "$(add 0 0)" 0'
  _ts3c_part 2002-count.sh 'is "count: the list holds exactly 3 items" "$(wc -l < "$W/list.txt" | tr -d " ")" 3'
  _ts3c_part 2003-grp-a.sh 'has "grp-a: the greeting says hello" "$(cat "$W/greet.txt")" hello'
  _ts3c_part 2004-grp-b.sh 'is "grp-b: the colour is blue" "$(cat "$W/color.txt")" blue'
  _ts3c_part 2005-mul.sh 'is "mul: mul 2 3 is 6" "$(mul 2 3)" 6'
  _ts3c_part 2006-keep.sh 'is "keep: the version file says 1" "$(cat "$W/version.txt")" 1
is "keep: the version file is one line" "$(wc -l < "$W/version.txt" | tr -d " ")" 1'
  _ts3c_mani ''
  _ts3c_commit "$TS3CR" base; TS3C_M="$(_jr_sha "$TS3CR" HEAD)"
  _fx_git "$TS3CR" update-ref refs/remotes/origin/main "$TS3C_M" >/dev/null 2>&1
  mkdir -p "$TS3C/p"; _fx_git "$TS3CR" archive -o "$TS3C/p.tar" "$TS3C_M" projects/felix >/dev/null 2>&1 \
    && tar -x -C "$TS3C/p" -f "$TS3C/p.tar"; rm -f "$TS3C/p.tar"; TS3CPP="$TS3C/p/projects/felix"
  _ts3c_entry "$TS3C_M"
  cat > "$TS3C/gh/gh" <<'TS3CGH'
#!/usr/bin/env bash
d="${TS3C_GHDIR:?TS3C_GHDIR is not set}"
printf '%s\n' "$*" >> "$d/calls"
case "${1:-} ${2:-}" in
  "pr view")
    case " $* " in *baseRefName*) cat "$d/a"; exit 0 ;; esac
    printf '{"number":7,"state":"OPEN"}\n'; exit 0 ;;
  "pr merge")    printf 'merged\n'; exit 0 ;;
  "auth status") printf 'github.com\n  Logged in to github.com account example\n'; exit 0 ;;
  "repo view")   printf 'example/ts3c\n'; exit 0 ;;
  api\ repos/*/git/ref/heads/*) cat "$d/q"; exit 0 ;;
esac
exit 0
TS3CGH
  chmod +x "$TS3C/gh/gh"
}
_ts3c_entry() {   # SHA: the cache entry K/1.0.0 is that commit's engine, all of it
  rm -rf "$TS3CK/1.0.0" "$TS3C/x" "$TS3C/x.tar"; mkdir -p "$TS3CK/1.0.0" "$TS3C/x"
  _fx_git "$TS3CR" archive -o "$TS3C/x.tar" "$1" engine >/dev/null 2>&1 && tar -x -C "$TS3C/x" -f "$TS3C/x.tar"
  cp -R "$TS3C/x/engine/." "$TS3CK/1.0.0/"
  rm -rf "$TS3C/x" "$TS3C/x.tar"
}
