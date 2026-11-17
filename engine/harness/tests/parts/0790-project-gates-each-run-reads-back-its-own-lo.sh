printf '\nproject gates: each run reads back its own logs\n'
# Felix's own gate was one instance (the "two gates at once" block). The same
# shape sat in the scripts Felix holds for the projects it governs: another governed project's
# gate wrote ruff's check, ruff's rewrite, lint and pytest to four fixed files
# under /tmp and read them back for its file list, its test count and its
# FAILED lines; its push guard took its suite count from a fifth; a third governed project's gate
# printed clippy, test, rustfmt and gitleaks excerpts from four more. Every gate
# on the machine shared each file, so a gate could print another tree's
# evidence under a verdict that was its own. Found 2026-09-21, the day the
# felix instance was measured.
#
# The felix block's method, over all three scripts. One stand-in plays python,
# cargo and gitleaks; it names its tree in everything it writes, then waits at
# a barrier until the other tree's run reaches the same step, so both writes
# land before either script reads: the collision a shared path allows, made
# certain. Output is the same length in both trees, so a shared file holds one
# run whole. TMPDIR is shared, as it is between two sessions, and each script's
# literal /tmp/ is moved under the fixture: a fixed path is still one path both
# copies share, and tests/red runs this against the base's scripts, which must
# not truncate a real session's log to prove the point. The barriers are
# asserted, because two runs that never overlapped pass whatever path they use.
_PGL_ROOT="$(cd "$REAL_HARNESS/../.." && pwd)"
PGL="$TMP/project-gate-logs"; mkdir -p "$PGL/bin" "$PGL/fixed"
cat > "$PGL/bin/python" <<'STUB'
#!/usr/bin/env bash
t="$PGL_TREE"; o="$PGL_OTHER"
meet() {
  touch "$PGL_SYNC/$1.$t"; i=0
  while [ ! -e "$PGL_SYNC/$1.$o" ]; do
    [ "$i" -ge 200 ] && { echo "timeout $1" >> "$PGL_SYNC/met"; return 0; }
    sleep 0.05; i=$((i+1))
  done
  echo "met $1" >> "$PGL_SYNC/met"
}
red() { [ "${PGL_RED:-0}" = 1 ]; }
case "${0##*/} $*" in
  "python -m ruff format --check .")
    if red; then printf '  --> tree_%s.py:1:1\n' "$t"; meet format-check; exit 1; fi
    printf 'checked in tree %s\n' "$t"; meet format-check; exit 0 ;;
  "python -m ruff format .") exit 0 ;;
  "python -m ruff check .")
    if red; then printf 'E999 lint in tree %s\n' "$t"; meet lint; exit 1; fi
    printf 'clean in tree %s\n' "$t"; meet lint; exit 0 ;;
  "python -m pytest -q"*)
    if red; then printf 'FAILED tests/tree_%s.py::broke\n1 failed in tree %s\n' "$t" "$t"; meet test; exit 1; fi
    printf '1 passed in tree %s\n' "$t"; meet test; exit 0 ;;
  "cargo fmt --all -- --check")
    if red; then printf 'Diff in %s/src/tree_%s.rs:1:\n' "$(pwd -P)" "$t"; meet fmt-check; exit 1; fi
    meet fmt-check; exit 0 ;;
  "cargo fmt --all")
    if red; then printf 'rustfmt error in tree %s\n' "$t"; meet fmt; exit 1; fi
    meet fmt; exit 0 ;;
  "cargo clippy "*)
    if red; then printf 'error: clippy in tree %s\n' "$t"; meet clippy; exit 1; fi
    printf 'clean in tree %s\n' "$t"; meet clippy; exit 0 ;;
  "cargo test "*)
    if red; then printf 'test tree_%s::broke ... FAILED\n' "$t"; meet test; exit 1; fi
    printf 'test result: ok in tree %s\n' "$t"; meet test; exit 0 ;;
  "gitleaks protect "*)
    if red; then printf 'leak found in tree %s\n' "$t"; meet leaks; exit 1; fi
    printf 'no leaks in tree %s\n' "$t"; meet leaks; exit 0 ;;
esac
printf 'stand-in: nothing scripted for %s\n' "${0##*/} $*" >&2; exit 97
STUB
chmod +x "$PGL/bin/python"
cp "$PGL/bin/python" "$PGL/bin/cargo"; cp "$PGL/bin/python" "$PGL/bin/gitleaks"

# One tree shape serves all three: the gate refuses a tree without src/another,
# the push guard wants a commit past origin/main and a .venv, and a third governed project's gate
# takes its root from FELIX_GATE_ROOT and its tools from PATH.
for _k in el pp vd; do
  for _t in a b; do
    _d="$PGL/$_k/$_t"; mkdir -p "$_d/src/another" "$_d/.venv/bin"
    : > "$_d/src/another/__init__.py"; cp "$PGL/bin/python" "$_d/.venv/bin/python"
    ( _fx_cd "$_d" && git init -q -b main && git add src \
      && git -c user.name=t -c user.email=t@t commit -qm base \
      && git update-ref refs/remotes/origin/main HEAD \
      && printf 'x = 1\n' > src/another/mod.py && git add src \
      && git -c user.name=t -c user.email=t@t commit -qm change ) >/dev/null 2>&1
  done
done

# Both runs of one script start together and are waited on by pid.
_pgl_pair() {
  rm -rf "$PGL/sync" "$PGL/tmp"; mkdir -p "$PGL/sync" "$PGL/tmp"
  ( cd "$PGL/$1/a" && PATH="$PGL/bin:$PATH" PGL_TREE=a PGL_OTHER=b PGL_RED="$2" PGL_SYNC="$PGL/sync" \
      TMPDIR="$PGL/tmp" FELIX_BIN= FELIX_GATE_ROOT="$PGL/$1/a" bash "$PGL/$1/script" > "$PGL/$1/a.out" 2>&1 ) & _pgla=$!
  ( cd "$PGL/$1/b" && PATH="$PGL/bin:$PATH" PGL_TREE=b PGL_OTHER=a PGL_RED="$2" PGL_SYNC="$PGL/sync" \
      TMPDIR="$PGL/tmp" FELIX_BIN= FELIX_GATE_ROOT="$PGL/$1/b" bash "$PGL/$1/script" > "$PGL/$1/b.out" 2>&1 ) & _pglb=$!
  wait "$_pgla" "$_pglb"
}
# Which trees a run's output names, whatever form the name took.
_pgl_tok() { grep -ohE 'tree[ _][ab]' "$1" | LC_ALL=C sort -u | tr '\n' ','; }
_pgl_met() { LC_ALL=C sort "$PGL/sync/met" 2>/dev/null | uniq -c | awk '{ printf "%s %s %s;", $1, $2, $3 }'; }
# The paths a failing run points at: "full log: <path>", or the push guard's "see <path>".
_pgl_named() { sed -n 's/.*full log: //p; s/.* - see //p' "$1"; }

# kind, the script, a label, the barriers both runs must meet at, what a
# passing run prints of its own tree, how many logs a failing run names.
_pgl_check() {
  local k="$1" src="$2" label="$3" met="$4" green="$5" named="$6" p t o bad_logs=""
  if [ ! -f "$src" ]; then
    for p in "two passing at once: each prints only its own tree" "two passing at once: the runs overlapped" \
             "two passing at once: no log is left behind" "two failing at once: each excerpt is its own tree's" \
             "two failing at once: the runs overlapped" "two failing at once: each log it names holds its own run alone" \
             "two failing at once: only the logs it names are kept"; do
      skip "$label, $p" "no ${src#"$_PGL_ROOT"/} beside this harness"
    done
    return 0
  fi
  sed "s|/tmp/|$PGL/fixed/|g" "$src" > "$PGL/$k/script"

  _pgl_pair "$k" 0
  is "$label, two passing at once: each prints only its own tree" \
     "$(_pgl_tok "$PGL/$k/a.out") | $(_pgl_tok "$PGL/$k/b.out")" "$green"
  is "$label, two passing at once: the runs overlapped" "$(_pgl_met)" "$met"
  is "$label, two passing at once: no log is left behind" "$(ls -A "$PGL/tmp" | wc -l | tr -d ' ')" "0"

  _pgl_pair "$k" 1
  is "$label, two failing at once: each excerpt is its own tree's" \
     "$(_pgl_tok "$PGL/$k/a.out") | $(_pgl_tok "$PGL/$k/b.out")" "tree a,tree_a, | tree b,tree_b,"
  is "$label, two failing at once: the runs overlapped" "$(_pgl_met)" "$met"
  for t in a b; do
    o=b; [ "$t" = b ] && o=a
    [ "$(_pgl_named "$PGL/$k/$t.out" | grep -c .)" = "$named" ] || bad_logs="$bad_logs $t:names-$(_pgl_named "$PGL/$k/$t.out" | grep -c .)"
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      if [ ! -f "$p" ] || ! grep -qE "tree[ _]$t" "$p" || grep -qE "tree[ _]$o" "$p"; then bad_logs="$bad_logs $t:[$p]"; fi
    done <<EOF
$(_pgl_named "$PGL/$k/$t.out")
EOF
  done
  [ "$(cat "$PGL/$k/a.out" "$PGL/$k/b.out" | sed -n 's/.*full log: //p; s/.* - see //p' | LC_ALL=C sort -u | grep -c .)" = "$((named * 2))" ] \
    || bad_logs="$bad_logs shared-path"
  is "$label, two failing at once: each log it names holds its own run alone" "$bad_logs" ""
  is "$label, two failing at once: only the logs it names are kept" \
     "$(ls -A "$PGL/tmp" | wc -l | tr -d ' ')" "$((named * 2))"
}

_pgl_check el "$_PGL_ROOT/projects/another/gate.sh" "another governed project's gate" \
  "2 met format-check;2 met lint;2 met test;" "tree a, | tree b," 2
_pgl_check pp "$_PGL_ROOT/projects/another/prepush.sh" "another governed project's push guard" \
  "2 met format-check;2 met lint;2 met test;" "tree a, | tree b," 1
_pgl_check vd "$_PGL_ROOT/projects/third/gate.sh" "a third governed project's gate" \
  "2 met clippy;2 met fmt;2 met fmt-check;2 met leaks;2 met test;" " | " 4

printf '\na third governed project gate: fmt names what rustfmt would rewrite, not what git calls dirty\n'
# a third governed project's fmt check ran `cargo fmt --all`, then reported
# `git diff --name-only -- '*.rs'` as "rewrote N file(s)". That is every .rs
# file with uncommitted work, so mid-task the check went red and listed files
# rustfmt never touched. And git diff cannot see an untracked file, so a new
# file rustfmt rewrote passed in silence. another governed project's gate had the same defect
# and fixed it 2026-08-05; this is the Rust form of that fix: ask
# `cargo fmt --all -- --check` first, rewrite, report only what the check
# named, and fail loudly when the check failed and no name parsed.
#
# The stand-in prints what rustfmt printed when measured on 2026-09-21: one
# `Diff in <canonical path>:<line>:` per hunk. The tree is reached through a
# symlink, as FELIX_GATE_ROOT can be, so the path rustfmt prints is not the
# one the gate was handed. Each script's literal /tmp/ is moved under the
# fixture for the reason the block above gives.
_VFM="$TMP/third-fmt"; mkdir -p "$_VFM/bin" "$_VFM/real/src" "$_VFM/fixed"
cat > "$_VFM/bin/cargo" <<'STUB'
#!/usr/bin/env bash
case "$*" in
  "fmt --all -- --check")
    [ -f "${VFM_CHECK:-}" ] && sed "s|@ROOT@|$(pwd -P)|g" "$VFM_CHECK"
    exit "${VFM_CHECK_RC:-0}" ;;
  "fmt --all")
    for f in ${VFM_REWRITE:-}; do printf '// rustfmt\n' >> "$f"; done
    exit 0 ;;
  "clippy "*|"test "*) exit 0 ;;
esac
printf 'stand-in: nothing scripted for cargo %s\n' "$*" >&2; exit 97
STUB
printf '#!/usr/bin/env bash\nexit 0\n' > "$_VFM/bin/gitleaks"
chmod +x "$_VFM/bin/cargo" "$_VFM/bin/gitleaks"
for _f in a b c; do printf 'fn %s() {}\n' "$_f" > "$_VFM/real/src/$_f.rs"; done
( _fx_cd "$_VFM/real" && git init -q -b main && git add src \
  && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
ln -s "$_VFM/real" "$_VFM/link"
printf 'fn d( ){}\n' > "$_VFM/real/src/d.rs"

# One gate run: what --check prints, its exit, the files the rewrite touches.
# Prints the fmt check's lines alone, whitespace squeezed, joined by |.
_vfm_run() {
  rm -rf "$_VFM/tmp"; mkdir -p "$_VFM/tmp"
  printf '%b' "$1" > "$_VFM/check"
  ( cd "$_VFM/link" && PATH="$_VFM/bin:$PATH" VFM_CHECK="$_VFM/check" VFM_CHECK_RC="$2" \
      VFM_REWRITE="$3" TMPDIR="$_VFM/tmp" FELIX_GATE_ROOT="$_VFM/link" \
      bash "$_VFM/script" --quick ) > "$_VFM/out" 2>&1
  awk '/^  fmt /{p=1; print; next} /^  [a-z]/{p=0} p' "$_VFM/out" \
    | tr -s ' ' | sed 's/^ //' | tr '\n' '|'
}
_vfm_left() { ls -A "$_VFM/tmp" | wc -l | tr -d ' '; }

if [ ! -f "$_PGL_ROOT/projects/third/gate.sh" ]; then
  for _p in "a new file rustfmt rewrites is named, though git diff cannot see it" \
            "a check that fails with no name it can parse is a loud FAIL" \
            "and the log it names holds what the check printed" \
            "edited files rustfmt would not touch are not named" \
            "and a passing check leaves no log behind" \
            "only the files rustfmt names, once each, relative to the tree" \
            "and a check that named its files leaves no log behind"; do
    skip "a third governed project's fmt: $_p" "no projects/third/gate.sh beside this harness"
  done
else
  sed "s|/tmp/|$_VFM/fixed/|g" "$_PGL_ROOT/projects/third/gate.sh" > "$_VFM/script"

  is "a third governed project's fmt: a new file rustfmt rewrites is named, though git diff cannot see it" \
     "$(_vfm_run 'Diff in @ROOT@/src/d.rs:1:\n-fn d( ){}\n+fn d() {}\n' 1 src/d.rs)" \
     "fmt FAIL|rustfmt rewrote 1 file(s); review and stage them|src/d.rs|"

  # An older rustfmt's shape: a parse that cannot read it must not go green.
  _vfm_out="$(_vfm_run 'Diff in @ROOT@/src/d.rs at line 1:\n-fn d( ){}\n+fn d() {}\n' 1 src/d.rs)"
  is "a third governed project's fmt: a check that fails with no name it can parse is a loud FAIL" \
     "$(printf '%s' "$_vfm_out" | cut -d'|' -f1-2)" \
     "fmt FAIL|cargo fmt --check exited 1 but no filename parsed"
  _vfm_log="$(sed -n 's/.*full log: //p' "$_VFM/out")"
  _vfm_bad=""
  [ "$(printf '%s\n' "$_vfm_log" | grep -c .)" = 1 ] || _vfm_bad="names $(printf '%s\n' "$_vfm_log" | grep -c .) logs"
  [ -n "$_vfm_log" ] && { [ -f "$_vfm_log" ] && grep -q 'd.rs at line 1:' "$_vfm_log" || _vfm_bad="$_vfm_bad [$_vfm_log]"; }
  [ "$(_vfm_left)" = 1 ] || _vfm_bad="$_vfm_bad left-$(_vfm_left)"
  is "a third governed project's fmt: and the log it names holds what the check printed" "$_vfm_bad" ""

  # Uncommitted work from here on: two edited files, one of them unformatted.
  printf 'fn a( ) {}\n' > "$_VFM/real/src/a.rs"; printf 'fn b() { }\n' > "$_VFM/real/src/b.rs"
  is "a third governed project's fmt: edited files rustfmt would not touch are not named" \
     "$(_vfm_run '' 0 '')" "fmt ok|"
  is "a third governed project's fmt: and a passing check leaves no log behind" "$(_vfm_left)" "0"

  is "a third governed project's fmt: only the files rustfmt names, once each, relative to the tree" \
     "$(_vfm_run 'Diff in @ROOT@/src/a.rs:1:\n-fn a( ) {}\n+fn a() {}\n\nDiff in @ROOT@/src/c.rs:1:\n x\nDiff in @ROOT@/src/c.rs:7:\n y\n' 1 'src/a.rs src/c.rs')" \
     "fmt FAIL|rustfmt rewrote 2 file(s); review and stage them|src/a.rs|src/c.rs|"
  is "a third governed project's fmt: and a check that named its files leaves no log behind" "$(_vfm_left)" "0"
fi

# The class, not the three instances: a fixed path under /tmp in any script a
# project holds is one every run of it on the machine shares. Tracked files
# only, so an untracked project in somebody's home checkout is not this suite's
# verdict to give. Felix's own gate is counted too; #276 took it out of /tmp.
#
# The second grep reads to the end rather than quitting at its first match.
# Under pipefail a grep -q there broke the first grep's pipe whenever more
# than a pipe's capacity of the script followed the match, the pipeline read
# as failed, and the && dropped the script's name: a pass for the script most
# in need of a fail. The fixture names /tmp/ on its second line, ahead of a
# megabyte, where that form missed it every time.
_pgl_names_tmp() { grep -vE '^[[:space:]]*#' "$1" | grep '/tmp/' >/dev/null; }
{ printf '#!/bin/sh\nscratch=/tmp/fixed-path\n'; seq 1 200000; } > "$TMP/pgl-early-tmp.sh"
if _pgl_names_tmp "$TMP/pgl-early-tmp.sh" 2>/dev/null; then
  ok  "a script that names /tmp/ on its second line, ahead of a megabyte, is caught under pipefail"
else
  bad "a script that names /tmp/ on its second line, ahead of a megabyte, is caught under pipefail" \
      "the reader quit at its match and broke the pipe, so the pipeline read as no match"
fi
_pgl_fixed="$(git -C "$_PGL_ROOT" ls-files -- projects 2>/dev/null | while IFS= read -r f; do
    [ -f "$_PGL_ROOT/$f" ] && [ "$(head -c2 "$_PGL_ROOT/$f")" = '#!' ] || continue
    _pgl_names_tmp "$_PGL_ROOT/$f" && printf '%s ' "$f"
  done)"
is "no project script names a fixed path under /tmp outside its comments" "$_pgl_fixed" ""

