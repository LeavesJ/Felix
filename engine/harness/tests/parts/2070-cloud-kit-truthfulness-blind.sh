printf '\nthe cloud kit says what is true: no base is not clean, and the toolbox says how its pins relate (audit b23, blind)\n'
# Written blind on 2026-10-24 from docs/2026-10-24-audit-fixes/b23-cloud-kit-truthfulness.md
# alone (A1 to A39, from B1 to B14), before the fix and without reading bin/secret-scan,
# projects/felix/gate.sh, toolbox.json or provision. Each name ends in its item, (b23 An);
# the contract marks which are controls, and every other one is red on 69b51a61, where
# each no-base scan exits 0.
#
# C108: when secret-scan finds no base ref on a branch that has commits, or is named a
# base that does not resolve, it has read none of what the branch committed, and must
# exit 2 and say so, not 0. C111: toolbox.json and provision must stop claiming that a
# cloud session runs what the founder's machine runs.
#
# The fixtures are the contract's, each in a directory of its own under $TMP/b23. Every
# git write goes through _fx_git, or _fx_cd in a subshell, with the identity on the
# command line and each git init naming its branch, so nothing reads the host's
# init.defaultBranch or clone.defaultRemoteName. Hooks and signing are switched off on
# each commit for the same reason. A fixture that is not what the contract builds (a step
# failed, or one of the five base refs resolves where none may) makes each assertion on
# it bad, with the reason, and never lets one pass by accident. A scan runs under perl's
# alarm (60 s, 300 s for a gate run); one the alarm ends reads `did not finish`.
#
# Readings, where the contract leaves room: the stdin scans of A25 run in the M0
# fixture; A28 also asks, as B10c does, that the secret line not say ok; the secret line
# is the first line that begins with two spaces and `secret`; A38 is bad, not vacuous,
# when stack.tsv holds no plugin or skill row at all. The part relies on the prelude
# alone (FROOT, TMP, REAL_HARNESS, _fx_cd, _fx_git, _copy_content, ok, bad, is, skip).
#
# Measured on 69b51a61 by running the scanner, not by reading it: under gawk 5.4.1
# (CI's awk) it writes "awk: warning: escape sequence '\.' treated as plain '.'" to
# stderr on every scan, a clean one with a base included. So A20, which the contract
# calls a control, is red under gawk and green under BWK awk until that is fixed.

B23="$TMP/b23"; mkdir -p "$B23"
_b23_ss="$FROOT/harness/bin/secret-scan"
_b23_key="$(printf '%s%s' AKIA Q7XK2M9PLR4TWN3B)"
_b23_line="$(printf 'aws = "%s"' "$_b23_key")"
_b23_bases="origin/HEAD origin/main origin/master main master"

# ---- fixture helpers
_b23_no() {   # FIXTURE PROBLEM: FIXTURE is not what its assertions need
  printf '%s; ' "$2" >> "$B23/$1.prob"
}
_b23_new() {   # FIXTURE BRANCH: an empty repository $B23/FIXTURE on BRANCH
  mkdir -p "$B23/$1" && _fx_git "$B23/$1" init -q -b "$2" >/dev/null 2>&1
}
_b23_ci() {   # FIXTURE FILE TEXT: FILE holds TEXT and is committed
  printf '%s\n' "$3" > "$B23/$1/$2" && _fx_git "$B23/$1" add -- "$2" >/dev/null 2>&1 \
    && _fx_git "$B23/$1" -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null \
         commit -q -m "$2" >/dev/null 2>&1
}
_b23_co() {   # FIXTURE ARGS...: git checkout ARGS in FIXTURE
  local f="$1"; shift
  _fx_git "$B23/$f" checkout -q "$@" >/dev/null 2>&1
}
_b23_res() {   # FIXTURE REF -> 0 when REF resolves in FIXTURE
  _fx_git "$B23/$1" rev-parse -q --verify "$2" >/dev/null 2>&1
}
_b23_nobase() {   # FIXTURE: a problem for each of the five base refs that resolves in it
  local r
  for r in $_b23_bases; do
    if _b23_res "$1" "$r"; then _b23_no "$1" "$r resolves, so it is not a no-base fixture"; fi
  done
}
_b23_prob() {   # FIXTURE... -> the problems of those fixtures, or nothing
  local f
  for f in "$@"; do
    if [ -s "$B23/$f.prob" ]; then printf '%s: %s' "$f" "$(cat "$B23/$f.prob")"; fi
  done
}
_b23_flat() {   # TEXT -> TEXT on one line, at most 400 bytes
  printf '%s' "$1" | LC_ALL=C tr '\n' '|' | LC_ALL=C cut -c1-400
}

# ---- scans: _b23_got is the exit status (or why there is none), _b23_out and _b23_err the streams
_b23_read() {   # RC: the status and the streams of the scan just made
  _b23_got="$1"
  [ "$1" != 142 ] || _b23_got="did not finish"
  [ "$1" != 125 ] || _b23_got="could not enter the fixture"
  _b23_out="$(cat "$B23/scan.out" 2>/dev/null)"; _b23_err="$(cat "$B23/scan.err" 2>/dev/null)"
}
_b23_scan() {   # FIXTURE [ARG...]: the scanner run in FIXTURE
  local f="$1"; shift
  ( _fx_cd "$B23/$f" || exit 125; exec perl -e 'alarm shift; exec @ARGV or exit 127' 60 "$_b23_ss" "$@" ) \
    > "$B23/scan.out" 2> "$B23/scan.err"
  _b23_read "$?"
}
_b23_stdin() {   # TEXT: the scanner reading +TEXT on stdin (mode -), in the M0 fixture
  ( _fx_cd "$B23/m0" || exit 125
    printf '+%s\n' "$1" | perl -e 'alarm shift; exec @ARGV or exit 127' 60 "$_b23_ss" - ) \
    > "$B23/scan.out" 2> "$B23/scan.err"
  _b23_read "$?"
}
# What one assertion found wrong, collected by these and said by _b23_say.
_b23_m=""
_b23_rc()    { [ "$_b23_got" = "$1" ] || _b23_m="${_b23_m}exit [$_b23_got], wanted [$1]; "; }
_b23_has()   { case "$_b23_err" in *"$1"*) ;; *) _b23_m="${_b23_m}stderr lacks [$1]; " ;; esac; }
_b23_lacks() { case "$_b23_err" in *"$1"*) _b23_m="${_b23_m}stderr holds [$1]; " ;; esac; }
_b23_say() {   # NAME FIXTURE...: ok, or bad with the fixtures' problems or what was found wrong
  local n="$1" p; shift
  p="$(_b23_prob "$@")"
  if [ -n "$p" ]; then bad "$n" "the fixture is not what the contract builds: $p"
  elif [ -z "$_b23_m" ]; then ok "$n"
  else bad "$n" "${_b23_m}stderr was [$(_b23_flat "$_b23_err")]"; fi
  _b23_m=""
}

# ---- the fixtures
_b23_new nkey feat && _b23_ci nkey a.txt a && _b23_ci nkey k.txt "$_b23_line" \
  || _b23_no nkey "N-key could not be built"
_b23_nobase nkey
_b23_new nclean feat && _b23_ci nclean a.txt a && _b23_ci nclean b.txt b \
  || _b23_no nclean "N-clean could not be built"
_b23_nobase nclean
_b23_new s main && _b23_ci s a.txt a && _b23_co s -b feat && _b23_ci s k.txt "$_b23_line" && _b23_co s main \
  && _fx_git "$B23" clone -q -o origin --single-branch --branch feat "file://$B23/s" "$B23/c" >/dev/null 2>&1 \
  || _b23_no c "the single-branch clone C could not be built"
_b23_nobase c
_b23_new d feat && _b23_ci d a.txt a && _b23_ci d k.txt "$_b23_line" && _b23_co d --detach \
  && _fx_git "$B23/d" branch -q -D feat >/dev/null 2>&1 \
  || _b23_no d "the detached fixture D could not be built"
_b23_nobase d
_b23_new mkey main && _b23_ci mkey a.txt a && _b23_co mkey -b feat && _b23_ci mkey k.txt "$_b23_line" \
  || _b23_no mkey "M-key could not be built"
_b23_new mclean main && _b23_ci mclean a.txt a && _b23_co mclean -b feat && _b23_ci mclean b.txt b \
  || _b23_no mclean "M-clean could not be built"
_b23_new m0 main && _b23_ci m0 a.txt a || _b23_no m0 "M0 could not be built"
for _b23_f in mkey mclean m0; do
  _b23_res "$_b23_f" main || _b23_no "$_b23_f" "main does not resolve, so it is no fixture with a base"
  if _b23_res "$_b23_f" no-such-ref; then _b23_no "$_b23_f" "no-such-ref resolves"; fi
done
for _b23_f in uclean ukey; do
  _b23_new "$_b23_f" feat && printf 'a\n' > "$B23/$_b23_f/a.txt" \
    && _fx_git "$B23/$_b23_f" add a.txt >/dev/null 2>&1 \
    || _b23_no "$_b23_f" "the unborn fixture could not be built"
  if _b23_res "$_b23_f" HEAD; then _b23_no "$_b23_f" "HEAD resolves, so it is not unborn"; fi
done
printf '%s\n' "$_b23_line" > "$B23/ukey/k.txt" || _b23_no ukey "its untracked key file could not be written"

# ---- C108: the scanner
_b23_scan nkey
_b23_rc 2
_b23_say "secret-scan finding no base ref on a branch with commits exits 2, not 0, though a commit holds a key (b23 A1)" nkey
[ -z "$_b23_out" ] || _b23_m="stdout was [$(_b23_flat "$_b23_out")]; "
_b23_say "secret-scan with no base ref prints nothing on stdout (b23 A2)" nkey
_b23_has "no base ref found"
_b23_say "secret-scan with no base ref says on stderr that no base ref was found (b23 A3)" nkey
_b23_has "origin/HEAD origin/main origin/master main master"
_b23_say "secret-scan with no base ref names the refs it tried, in the order it tried them (b23 A4)" nkey
_b23_has "what this branch committed was not scanned"
_b23_say "secret-scan with no base ref says what this branch committed was not scanned (b23 A5)" nkey
_b23_has "nothing here can be called clean"
_b23_say "secret-scan with no base ref says nothing here can be called clean (b23 A6)" nkey
_b23_has "git fetch origin main:main"
_b23_say "secret-scan with no base ref names the repair that makes a local main, git fetch origin main:main (b23 A7)" nkey
_b23_lacks "refs/remotes/"
_b23_say "secret-scan's no-base hint names no refs/remotes/ refspec, which the deny floor refuses (b23 A8)" nkey

_b23_scan nclean
_b23_rc 2; _b23_has "what this branch committed was not scanned"
_b23_say "secret-scan with no base ref exits 2 over clean commits too: commits it could not read are not clean (b23 A9)" nclean

_b23_scan c
_b23_rc 2; _b23_has "no base ref found"
_b23_say "in a single-branch clone with no origin/main, secret-scan exits 2 and says no base ref was found (b23 A10)" c
_b23_fetch=0
[ -n "$(_b23_prob c)" ] || _fx_git "$B23/c" fetch -q origin main:main >/dev/null 2>&1 || _b23_fetch=1
_b23_scan c
_b23_rc 1; _b23_has "possible credential in added lines"; _b23_has "$_b23_key"
[ "$_b23_fetch" -eq 0 ] || _b23_m="git fetch -q origin main:main failed in the clone; $_b23_m"
_b23_say "after git fetch origin main:main in that clone, secret-scan has a base and finds the committed key, exit 1 (b23 A11)" c

_b23_scan d
_b23_rc 2; _b23_has "what this branch committed was not scanned"
_b23_say "on a detached HEAD with no branch and no base ref, secret-scan exits 2 and says the commits were not scanned (b23 A12)" d

_b23_scan mkey no-such-ref
_b23_rc 2
_b23_say "secret-scan named a base that does not resolve exits 2, and does not fall back to main (b23 A13)" mkey
_b23_has "no-such-ref"; _b23_has "does not resolve"
_b23_has "what this branch committed was not scanned"; _b23_has "nothing here can be called clean"
_b23_say "secret-scan names the base that does not resolve, and says the commits were not scanned and nothing is clean (b23 A14)" mkey
_b23_scan mclean no-such-ref
_b23_rc 2
_b23_say "secret-scan named a base that does not resolve exits 2 over clean commits too (b23 A15)" mclean

printf '%s\n' "$_b23_line" > "$B23/nclean/u.txt" || _b23_no nclean "its untracked key file could not be written"
_b23_scan nclean
_b23_rc 1; _b23_has "possible credential in added lines"; _b23_has "$_b23_key"; _b23_has "no base ref found"
_b23_say "with no base ref, a key in an untracked file is still a hit: exit 1, naming the key and the missing base (b23 A16)" nclean
rm -f "$B23/nclean/u.txt"
printf '%s\n' "$_b23_line" > "$B23/mclean/u.txt" || _b23_no mclean "its untracked key file could not be written"
_b23_scan mclean no-such-ref
_b23_rc 1
_b23_say "with a base that does not resolve, a key in an untracked file is still a hit: exit 1 (b23 A17)" mclean
rm -f "$B23/mclean/u.txt"

_b23_scan uclean
_b23_rc 0; _b23_lacks "nothing here can be called clean"; _b23_lacks "was not scanned"
_b23_say "on an unborn HEAD with a clean staged file, secret-scan exits 0 and calls nothing unscanned (b23 A18)" uclean
_b23_scan ukey
_b23_rc 1
_b23_say "on an unborn HEAD, a key in an untracked file is a hit: exit 1 (b23 A19)" ukey

_b23_scan mclean
_b23_rc 0; [ -z "$_b23_err" ] || _b23_m="${_b23_m}stderr is not empty; "
_b23_say "with main found as its base over clean commits, secret-scan exits 0 and says nothing on stderr (b23 A20)" mclean
_b23_scan mclean main
_b23_rc 0
_b23_say "named main as its base over clean commits, secret-scan exits 0 (b23 A21)" mclean
_b23_scan mkey
_b23_rc 1; _b23_has "$_b23_key"
_b23_say "with main found as its base, a committed key is found: exit 1, naming the key (b23 A22)" mkey
_b23_scan m0
_b23_rc 0
_b23_say "with HEAD at its base, the empty change is clean: exit 0 (b23 A23)" m0

_b23_scan nkey --tree; _b23_t1="$_b23_got"
_b23_scan nclean --tree; _b23_t2="$_b23_got"
[ "$_b23_t1 $_b23_t2" = "1 0" ] || _b23_m="--tree exits [$_b23_t1] over N-key and [$_b23_t2] over N-clean, wanted [1] and [0]; "
_b23_say "secret-scan --tree reads no base: exit 1 over the committed key, 0 over clean commits (b23 A24)" nkey nclean
_b23_stdin 'note = 1'; _b23_t1="$_b23_got"
_b23_stdin "$_b23_line"; _b23_t2="$_b23_got"
[ "$_b23_t1 $_b23_t2" = "0 1" ] || _b23_m="stdin exits [$_b23_t1] over a clean line and [$_b23_t2] over the key line, wanted [0] and [1]; "
_b23_say "secret-scan - reads no base: exit 0 over a clean line on stdin, 1 over the key line (b23 A25)" m0

# ---- C108: the gate's secret line, from the unchanged gate.sh over the branch's scanner
_b23_root="$(cd "$REAL_HARNESS/../.." && pwd)"
_b23_gsh="$_b23_root/projects/felix/gate.sh"
_b23_G="$B23/g"
_b23_gate() {   # RUN: gate.sh --quick in G; _b23_go its output, _b23_gl its secret line, _b23_gw why it cannot be judged
  local rc
  ( _fx_cd "$_b23_G" || exit 125; exec perl -e 'alarm shift; exec @ARGV or exit 127' 300 bash gate.sh --quick ) \
    > "$B23/gate-$1.out" 2>&1
  rc=$?
  _b23_go="$(cat "$B23/gate-$1.out" 2>/dev/null)"
  _b23_gl="$(LC_ALL=C awk 'substr($0, 1, 8) == "  secret" { print; exit }' "$B23/gate-$1.out" 2>/dev/null)"
  _b23_gw=""
  [ "$rc" -ne 142 ] || _b23_gw="the gate run did not finish within 300 s"
  [ "$rc" -ne 125 ] || _b23_gw="the gate fixture could not be entered"
  [ -n "$_b23_gw" ] || [ -n "$_b23_gl" ] \
    || _b23_gw="the gate printed no secret line (exit $rc); it ended [$(_b23_flat "$(tail -5 "$B23/gate-$1.out" 2>/dev/null)")]"
}
_b23_gsay() {   # NAME: ok, or bad with the fixture's problem, why the run cannot be judged, or what was found wrong
  local p
  p="$(_b23_prob g)"
  if [ -n "$p" ]; then bad "$1" "the gate fixture is not what the contract builds: $p"
  elif [ -n "$_b23_gw" ]; then bad "$1" "$_b23_gw"
  elif [ -z "$_b23_m" ]; then ok "$1"
  else bad "$1" "${_b23_m}the secret line was [$_b23_gl]"; fi
  _b23_m=""
}
_b23_lhas()   { case "$_b23_gl" in *"$1"*) ;; *) _b23_m="${_b23_m}the secret line lacks [$1]; " ;; esac; }
_b23_llacks() { case "$_b23_gl" in *"$1"*) _b23_m="${_b23_m}the secret line holds [$1]; " ;; esac; }
_b23_ohas()   { case "$_b23_go" in *"$1"*) ;; *) _b23_m="${_b23_m}the output lacks [$1]; " ;; esac; }
_b23_gnames="the gate's secret line says ok over a clean side branch (b23 A26)
the gate's secret line says FAIL over a committed key, with the scanner's finding in its output (b23 A27)
the gate's secret line says FAIL, not ok, once main is deleted and no base ref is left (b23 A28)
the gate says why under its secret line: no base ref found, and the commits were not scanned (b23 A29)"
if [ -f "$_b23_gsh" ]; then
  mkdir -p "$_b23_G/engine/.claude-plugin" \
    && _copy_content "$REAL_HARNESS" "$_b23_G/engine/harness" \
    && _copy_content "$REAL_HARNESS/../hooks" "$_b23_G/engine/hooks" \
    && printf '{ "name": "felix", "version": "0.0.1" }\n' > "$_b23_G/engine/.claude-plugin/plugin.json" \
    && cp "$_b23_gsh" "$_b23_G/gate.sh" \
    && ( _fx_cd "$_b23_G" && git init -q -b main && git add -A \
         && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm s ) >/dev/null 2>&1 \
    || _b23_no g "G could not be built"
  _b23_co g -b side && _b23_ci g b.txt b || _b23_no g "the side branch could not be made"
  _b23_gate a
  _b23_lhas ok
  _b23_gsay "the gate's secret line says ok over a clean side branch (b23 A26)"
  _b23_ci g leak.txt "$_b23_line" || _b23_no g "leak.txt could not be committed"
  _b23_gate b
  _b23_lhas FAIL; _b23_ohas "possible credential in added lines"
  _b23_gsay "the gate's secret line says FAIL over a committed key, with the scanner's finding in its output (b23 A27)"
  _fx_git "$_b23_G" branch -q -D main >/dev/null 2>&1 || _b23_no g "main could not be deleted"
  _b23_nobase g
  _b23_gate c
  _b23_lhas FAIL; _b23_llacks ok
  _b23_gsay "the gate's secret line says FAIL, not ok, once main is deleted and no base ref is left (b23 A28)"
  _b23_ohas "    secret-scan: no base ref found"; _b23_ohas "what this branch committed was not scanned"
  _b23_gsay "the gate says why under its secret line: no base ref found, and the commits were not scanned (b23 A29)"
else
  while IFS= read -r _b23_n; do skip "$_b23_n" "no projects/felix/gate.sh beside this harness"; done <<EOF_B23_GATE_NAMES
$_b23_gnames
EOF_B23_GATE_NAMES
fi

# ---- C111: the cloud files
_b23_cl="$_b23_root/.claude/cloud"; _b23_tb="$_b23_cl/toolbox.json"; _b23_pv="$_b23_cl/provision"
_b23_on() {   # NAME FILE -> 0 when the assertion can be judged; otherwise it is skipped or bad here, and 1
  if [ ! -d "$_b23_cl" ]; then skip "$1" "no .claude/cloud beside this harness (the public snapshot does not ship it)"; return 1; fi
  if [ ! -f "$2" ]; then bad "$1" "${2##*/} is missing from .claude/cloud"; return 1; fi
  return 0
}
_b23_holds() {   # NAME PHRASE: toolbox.json holds PHRASE
  local rc
  _b23_on "$1" "$_b23_tb" || return 0
  LC_ALL=C grep -qF -- "$2" "$_b23_tb"; rc=$?
  case "$rc" in 0) ok "$1" ;; 1) bad "$1" "toolbox.json lacks [$2]" ;; *) bad "$1" "grep could not read toolbox.json (exit $rc)" ;; esac
}
_b23_jr=""
if command -v jq >/dev/null 2>&1; then _b23_jr=jq; elif command -v python3 >/dev/null 2>&1; then _b23_jr=python3; fi
_b23_json() {   # one|shape -> what the JSON reader says of toolbox.json
  local o rc
  if [ "$_b23_jr" = jq ] && [ "$1" = one ]; then
    o="$(jq -r '[.about[]? | strings | select(contains("moved by hand") and contains("may lag") and contains("nothing compares") and contains("installed_plugins.json"))] | length' "$_b23_tb" 2>/dev/null)"; rc=$?
  elif [ "$_b23_jr" = jq ]; then
    o="$(jq -r 'if (.about | type) != "array" then "about is not an array"
      elif ([.about[] | select(type != "string")] | length) > 0 then "about holds a value that is not a string"
      elif (.tools | type) != "array" then "tools is not an array" else (.tools | length) end' "$_b23_tb" 2>/dev/null)"; rc=$?
  else
    o="$(python3 -I -c '
import json, sys
try:
    d = json.load(open(sys.argv[2], encoding="utf-8"))
except Exception:
    print("does not parse"); sys.exit(0)
a = d.get("about") if isinstance(d, dict) else None
t = d.get("tools") if isinstance(d, dict) else None
w = ["moved by hand", "may lag", "nothing compares", "installed_plugins.json"]
if sys.argv[1] == "one":
    print(len([s for s in (a if isinstance(a, list) else []) if isinstance(s, str) and all(x in s for x in w)]))
elif not isinstance(a, list):
    print("about is not an array")
elif [s for s in a if not isinstance(s, str)]:
    print("about holds a value that is not a string")
elif not isinstance(t, list):
    print("tools is not an array")
else:
    print(len(t))
' "$1" "$_b23_tb" 2>/dev/null)"; rc=$?
  fi
  [ "$rc" -eq 0 ] || o="$_b23_jr could not read toolbox.json (exit $rc): it may not parse"
  printf '%s\n' "$o"
}

_b23_n="toolbox.json no longer says the cloud runs what a local session runs (b23 A30)"
if _b23_on "$_b23_n" "$_b23_tb"; then
  LC_ALL=C grep -qiF 'the cloud runs what a local session runs' "$_b23_tb"; _b23_r=$?
  case "$_b23_r" in
    1) ok "$_b23_n" ;;
    0) bad "$_b23_n" "it still says so, in some case" ;;
    *) bad "$_b23_n" "grep could not read toolbox.json (exit $_b23_r)" ;;
  esac
fi
_b23_holds "toolbox.json says its pins are moved by hand (b23 A31)" "moved by hand"
_b23_holds "toolbox.json says a pin may lag the local install (b23 A32)" "may lag"
_b23_holds "toolbox.json says nothing compares a pin with the local install (b23 A33)" "nothing compares"
_b23_holds "toolbox.json names installed_plugins.json, where a pin is checked by hand (b23 A34)" "installed_plugins.json"

_b23_n="exactly one string of toolbox.json's about array says all four: moved by hand, may lag, nothing compares, installed_plugins.json (b23 A35)"
if _b23_on "$_b23_n" "$_b23_tb"; then
  if [ -z "$_b23_jr" ]; then skip "$_b23_n" "neither jq nor python3 is on PATH"
  else is "$_b23_n" "$(_b23_json one)" "1"; fi
fi
_b23_n="toolbox.json parses, about is an array of strings, and tools has one entry per line holding \"name\": (b23 A36)"
if _b23_on "$_b23_n" "$_b23_tb"; then
  _b23_nl="$(LC_ALL=C grep -cF '"name":' "$_b23_tb")"
  if [ -z "$_b23_jr" ]; then skip "$_b23_n" "neither jq nor python3 is on PATH"
  else is "$_b23_n" "$(_b23_json shape)" "$_b23_nl"; fi
fi
_b23_n="the gate's six-space name reader finds every name line of toolbox.json, and at least one (b23 A37)"
if _b23_on "$_b23_n" "$_b23_tb"; then
  _b23_nl="$(LC_ALL=C grep -cF '"name":' "$_b23_tb")"
  LC_ALL=C sed -n 's/^      "name": "\([^"]*\)",$/\1/p' "$_b23_tb" > "$B23/tb.names" 2>/dev/null
  _b23_ns="$(LC_ALL=C awk 'END { print NR }' "$B23/tb.names")"
  if [ "$_b23_ns" = "$_b23_nl" ] && [ "${_b23_ns:-0}" -ge 1 ] 2>/dev/null; then ok "$_b23_n"
  else bad "$_b23_n" "the reader printed [$_b23_ns] names, and [$_b23_nl] lines hold \"name\":"; fi
fi
_b23_n="every plugin and skill row of projects/felix/stack.tsv names a toolbox.json entry (b23 A38)"
_b23_st="$_b23_root/projects/felix/stack.tsv"
if _b23_on "$_b23_n" "$_b23_tb"; then
  if [ ! -f "$_b23_st" ]; then bad "$_b23_n" "no projects/felix/stack.tsv beside this harness"
  else
    LC_ALL=C sed -n 's/^      "name": "\([^"]*\)",$/\1/p' "$_b23_tb" > "$B23/tb.names" 2>/dev/null
    _b23_v="$(LC_ALL=C awk -F'\t' '
      FILENAME == ARGV[1] { have[$0] = 1; next }
      /^#/ { next }
      $1 == "plugin" || $1 == "skill" { n++; x = $2; sub(/@.*/, "", x); if (!(x in have)) miss = miss " " x }
      END { printf "%d rows;%s\n", n + 0, miss }' "$B23/tb.names" "$_b23_st" 2>&1)"
    case "$_b23_v" in
      "0 rows;"*) bad "$_b23_n" "read no plugin or skill row from stack.tsv [$_b23_v]" ;;
      *" rows;") ok "$_b23_n" ;;
      *) bad "$_b23_n" "not in toolbox.json, or not read: [$_b23_v]" ;;
    esac
  fi
fi
_b23_n="provision no longer says it fetches at the commit the founder's machine runs (b23 A39)"
if _b23_on "$_b23_n" "$_b23_pv"; then
  LC_ALL=C grep -qF "founder's machine runs" "$_b23_pv"; _b23_r=$?
  case "$_b23_r" in
    1) ok "$_b23_n" ;;
    0) bad "$_b23_n" "a line of provision still says so" ;;
    *) bad "$_b23_n" "grep could not read provision (exit $_b23_r)" ;;
  esac
fi
