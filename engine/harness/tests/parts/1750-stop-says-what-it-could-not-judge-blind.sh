# >>> b07-stop
printf '\nthe Stop hook says what it could not judge, and a cloud session is told (audit b07, blind)\n'
# Blind, written 2026-10-24 from docs/2026-10-24-audit-fixes/b07-stop-hook-and-cloud-session-never-let-go.md
# alone (sections 2 and 4, A1 to A46), without reading hooks/, lib/, felix or any gate.sh. The hooks
# are black boxes, run against fixture S of the contract: a home H with one project p whose gate is
# `true`, a memory root M, and a checkout R bound to p by marker, dirty by one uncommitted line.
#
# Readings, where the contract leaves room:
# - every hook run also gets HOME set to a fixture directory, an extra NAME=value of the contract's
#   hook run, so no run reads or writes the real home;
# - "one JSON object" is stricter than `jq -e`: jq -s must read exactly one value, an object. An item
#   the contract marks (jq skip) is skipped whole where jq is not on PATH. "says X" reads the
#   systemMessage with jq, else python3, else stdout as it stands; a hold's reason is read the same way;
# - "appends one row" is exactly one new row in verification.log; a says.log kind is counted among
#   the new says.log rows; a library is "removed" by moving it out of H's copy and back afterwards;
# - A45 checks the whole local sequence: the hold, the flagged stop (silent, no row), then the debt.
# A run that has not ended in 20 s is killed with its whole tree, by pid, and reads exit 124.
_b7a_env="${CLAUDE_CODE_REMOTE+set}"   # B12, read before this part runs anything
B7="$TMP/b07"; B7H="$B7/home"; B7M="$B7/mem"; B7R="$B7/repo"; B7HOME="$B7/user"; B7X="$B7/aside"
mkdir -p "$B7H/projects/p" "$B7M" "$B7R" "$B7HOME" "$B7X"
_copy_content "$REAL_HARNESS" "$B7H/harness"
B7J="$B7H/projects/p/project.json"
printf '{"name": "p", "gate": "true"}\n' > "$B7J"
printf '# p\n' > "$B7H/projects/p/CLAUDE.md"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$B7H/projects/p/probes.tsv"
( _fx_cd "$B7R" && git init -q -b main && printf 'base\n' > WORK.txt && printf 'p\n' > .felix && git add -A \
  && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm init ) >/dev/null 2>&1
B7R="$(cd "$B7R" && pwd -P)"
printf 'one more line\n' >> "$B7R/WORK.txt"
B7V="$B7M/p/verification.log"; B7S="$B7M/p/says.log"; B7U="$B7M/unresolved.log"

# ---- helpers ----
_b7a_rows() { [ -f "$1" ] || { printf '0'; return 0; }; LC_ALL=C awk 'END { print NR + 0 }' "$1" 2>/dev/null || printf '0'; }
_b7a_tree() {   # pid -> it and everything below it
  ps -A -o pid= -o ppid= 2>/dev/null | LC_ALL=C awk -v root="$1" '
    { kids[$2] = kids[$2] " " $1 }
    END { q = root; out = ""
          while (q != "") { n = split(q, a, " "); q = ""
                            for (i = 1; i <= n; i++) if (a[i] != "") { out = out " " a[i]; q = q kids[a[i]] } }
          print out }'
}
# One run in R: HOOK PAYLOAD [NAME=value ...]. Sets B7A_RC, B7A_O (stdout), B7A_OB (its bytes),
# B7A_E (stderr), B7A_NV/NS/NU (rows added to verification.log, says.log, unresolved.log),
# B7A_LV (the last new verification row), B7A_RS and B7A_RU (the new says and unresolved rows).
_b7a_run() {
  local hook="$1" pay="$2" pid n=0 k v0 s0 u0
  shift 2
  v0="$(_b7a_rows "$B7V")"; s0="$(_b7a_rows "$B7S")"; u0="$(_b7a_rows "$B7U")"
  rm -f "$B7/o" "$B7/e" "$B7/rc"
  ( cd "$B7R" && printf '%s' "$pay" | env -u FELIX_ALLOW_RED -u CLAUDE_CODE_REMOTE FELIX_HOME="$B7H" FELIX_MEMORY="$B7M" \
      HOME="$B7HOME" "$@" "$hook" > "$B7/o" 2> "$B7/e"
    echo "$?" > "$B7/rc" ) &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$n" -lt 200 ]; do sleep 0.1; n=$((n + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    for k in $(_b7a_tree "$pid"); do kill -9 "$k" 2>/dev/null; done
    wait "$pid" 2>/dev/null; B7A_RC=124
    [ -p "$B7J" ] && ( exec 9<>"$B7J" ) 2>/dev/null
  else
    wait "$pid" 2>/dev/null; B7A_RC="$(cat "$B7/rc" 2>/dev/null)"; B7A_RC="${B7A_RC:-none}"
  fi
  B7A_O="$(cat "$B7/o" 2>/dev/null)"; B7A_E="$(cat "$B7/e" 2>/dev/null)"
  B7A_OB="$(wc -c < "$B7/o" 2>/dev/null | tr -d ' ')"; B7A_OB="${B7A_OB:-0}"
  B7A_NV="$(( $(_b7a_rows "$B7V") - v0 ))"; B7A_NS="$(( $(_b7a_rows "$B7S") - s0 ))"; B7A_NU="$(( $(_b7a_rows "$B7U") - u0 ))"
  B7A_LV=""; B7A_RS=""; B7A_RU=""
  [ "$B7A_NV" -gt 0 ] && B7A_LV="$(tail -n 1 "$B7V" 2>/dev/null)"
  [ "$B7A_NS" -gt 0 ] && B7A_RS="$(tail -n "$B7A_NS" "$B7S" 2>/dev/null)"
  [ "$B7A_NU" -gt 0 ] && B7A_RU="$(tail -n "$B7A_NU" "$B7U" 2>/dev/null)"
  return 0
}
_b7a_stop() {   # SID FLAG [NAME=value ...]
  local sid="$1" flag="$2"
  shift 2
  _b7a_run "$B7H/harness/hooks/stop" "$(printf '{"hook_event_name":"Stop","stop_hook_active":%s,"session_id":"%s"}' "$flag" "$sid")" "$@"
}
_b7a_ss() { _b7a_run "$B7H/harness/hooks/session-start" "$(printf '{"source":"startup","session_id":"%s"}' "$1")"; }
_b7a_in() { case "$1" in *"$2"*) printf yes ;; *) printf no ;; esac; }
# A top-level field of the last run's stdout (.systemMessage, .reason), or the stdout itself when
# neither jq nor python3 is there to read it.
_b7a_j() {
  if command -v jq >/dev/null 2>&1; then jq -r "$1 // empty" < "$B7/o" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys
try:
  d = json.load(open(sys.argv[1]))
  for k in sys.argv[2].strip(".").split("."): d = d[k]
  print(d)
except Exception: pass' "$B7/o" "$1"
  else cat "$B7/o" 2>/dev/null; fi
}
_b7a_says() { _b7a_in "$(_b7a_j .systemMessage)" "$1"; }
_b7a_hold() { case "$B7A_O" in *'"decision"'*'"block"'*) printf yes ;; *) printf no ;; esac; }
_b7a_dec()  { _b7a_in "$B7A_O" '"decision"'; }
_b7a_obj()  { if jq -se 'length == 1 and (.[0] | type) == "object"' < "$B7/o" >/dev/null 2>&1; then printf yes; else printf no; fi; }
_b7a_vf()   { cut -f"$1" <<< "$B7A_LV"; }
_b7a_kinds() { LC_ALL=C awk -F'\t' -v k="$1" '$2 == k { n++ } END { print n + 0 }' <<< "$B7A_RS"; }
_b7a_is() {
  if [ "$2" = "$3" ]; then ok "$1"
  else bad "$1" "expected [$3] got [$2]; exit [$B7A_RC] stdout [${B7A_O:0:400}] stderr [${B7A_E:0:200}]"; fi
}
_b7a_jis() { if command -v jq >/dev/null 2>&1; then _b7a_is "$@"; else skip "$1" "jq is not on PATH"; fi; }
# project.json in one state: absent, pipe, dir, dangling, mode000, or a body.
_b7a_pj() {
  if [ -f "$B7J" ] && [ ! -L "$B7J" ]; then chmod 644 "$B7J" 2>/dev/null; fi
  rm -rf "$B7J"
  case "$1" in
    absent) ;;
    pipe) mkfifo "$B7J" ;;
    dir) mkdir "$B7J" ;;
    dangling) ln -s "$B7H/projects/p/nowhere.json" "$B7J" ;;
    mode000) printf '{"name": "p", "gate": "true"}\n' > "$B7J"; chmod 000 "$B7J" ;;
    *) printf '%s\n' "$1" > "$B7J" ;;
  esac
}
B7G='{"name": "p", "gate": "true"}'

# ---- C030: project.json that cannot be read (B1, B2) ----
_b7a_pj absent; _b7a_stop a1 false
_b7a_is "b07 A1: with project.json absent the stop exits 0 and says Felix could not judge this stop, the path and nothing was held, with no decision" \
  "exit=$B7A_RC judge=$(_b7a_says 'Felix could not judge this stop') path=$(_b7a_says "$B7J") held=$(_b7a_says 'nothing was held') decision=$(_b7a_dec)" \
  "exit=0 judge=yes path=yes held=yes decision=no"
_b7a_is "b07 A2: and it appends one verification.log row: verdict unjudged, tree none, a reason naming project.json" \
  "rows=$B7A_NV f2=$(_b7a_vf 2) f3=$(_b7a_vf 3) f4=$(_b7a_in "$(_b7a_vf 4)" project.json)" "rows=1 f2=unjudged f3=none f4=yes"
_b7a_is "b07 A3: and one says.log row of kind unjudged" "$(_b7a_kinds unjudged)" "1"
_b7a_jis "b07 A4: and its stdout is one JSON object" "$(_b7a_obj)" "yes"
_b7a_pj pipe; _b7a_stop a5 false
_b7a_is "b07 A5: with project.json a named pipe the stop is not killed at 20 s, says Felix could not judge this stop and adds an unjudged row" \
  "exit=$B7A_RC judge=$(_b7a_says 'Felix could not judge this stop') rows=$B7A_NV:$(_b7a_vf 2)" "exit=0 judge=yes rows=1:unjudged"
_b7a_pj dir; _b7a_stop a6 false
_b7a_is "b07 A6: with project.json a directory the stop says Felix could not judge this stop and adds an unjudged row" \
  "exit=$B7A_RC judge=$(_b7a_says 'Felix could not judge this stop') rows=$B7A_NV:$(_b7a_vf 2)" "exit=0 judge=yes rows=1:unjudged"
_b7a_pj dangling; _b7a_stop a7 false
_b7a_is "b07 A7: with project.json a symbolic link to nothing the stop says Felix could not judge this stop and adds an unjudged row" \
  "exit=$B7A_RC judge=$(_b7a_says 'Felix could not judge this stop') rows=$B7A_NV:$(_b7a_vf 2)" "exit=0 judge=yes rows=1:unjudged"
_b7a_pj mode000
if cat "$B7J" >/dev/null 2>&1; then
  skip "b07 A8: with project.json of mode 000 the stop says Felix could not judge this stop and adds an unjudged row" "this user reads a mode-000 file"
else
  _b7a_stop a8 false
  _b7a_is "b07 A8: with project.json of mode 000 the stop says Felix could not judge this stop and adds an unjudged row" \
    "exit=$B7A_RC judge=$(_b7a_says 'Felix could not judge this stop') rows=$B7A_NV:$(_b7a_vf 2)" "exit=0 judge=yes rows=1:unjudged"
fi
_b7a_pj '{"name": "p"}'; _b7a_stop a9 false
_b7a_is "b07 A9: a project.json that declares no gate stays silent: exit 0, nothing on stdout or stderr, no row in any log (control)" \
  "exit=$B7A_RC out=$B7A_OB err=${#B7A_E} rows=$B7A_NV/$B7A_NS/$B7A_NU" "exit=0 out=0 err=0 rows=0/0/0"
_b7a_pj '{"name": "p", "gate": ""}'; _b7a_stop a10 false
_b7a_is "b07 A10: a project.json whose gate is empty stays silent the same way (control)" \
  "exit=$B7A_RC out=$B7A_OB err=${#B7A_E} rows=$B7A_NV/$B7A_NS/$B7A_NU" "exit=0 out=0 err=0 rows=0/0/0"
_b7a_pj "$B7G"; _b7a_stop a11 false
_b7a_is "b07 A11: with project.json restored and its gate set, the dirty stop holds (control)" "$(_b7a_hold)" "yes"

# ---- C030: a library the stop cannot do without (B3, B4) ----
mv "$B7H/harness/lib/verify.sh" "$B7X/verify.sh"; _b7a_stop a12 false; mv "$B7X/verify.sh" "$B7H/harness/lib/verify.sh"
_b7a_is "b07 A12: with lib/verify.sh removed the stop exits 0, says Felix could not judge this stop, lib/verify.sh and nothing was held, holds nothing, and writes an unresolved.log row naming it" \
  "exit=$B7A_RC judge=$(_b7a_says 'Felix could not judge this stop') lib=$(_b7a_says lib/verify.sh) held=$(_b7a_says 'nothing was held') decision=$(_b7a_dec) unresolved=$B7A_NU:$(_b7a_in "$B7A_RU" lib/verify.sh)" \
  "exit=0 judge=yes lib=yes held=yes decision=no unresolved=1:yes"
mv "$B7H/harness/lib/resolve.sh" "$B7X/resolve.sh"; _b7a_stop a13 false; mv "$B7X/resolve.sh" "$B7H/harness/lib/resolve.sh"
_b7a_is "b07 A13: with lib/resolve.sh removed the stop exits 0, says Felix could not judge this stop and lib/resolve.sh, and holds nothing" \
  "exit=$B7A_RC judge=$(_b7a_says 'Felix could not judge this stop') lib=$(_b7a_says lib/resolve.sh) decision=$(_b7a_dec)" \
  "exit=0 judge=yes lib=yes decision=no"
B7TEN="resolve verify route ready guard say detect maintenance overnight overnight-stop"
B7A_LIBS="$(LC_ALL=C grep -oE 'lib/[A-Za-z0123456789._-]+\.sh' "$B7H/harness/hooks/stop" 2>/dev/null | LC_ALL=C sort -u | tr '\n' ' ')"
_b7a_miss=""
for _b7a_n in $B7TEN; do
  case " $B7A_LIBS " in *" lib/$_b7a_n.sh "*) ;; *) _b7a_miss="$_b7a_miss $_b7a_n" ;; esac
done
_b7a_is "b07 A14: the lib/<name>.sh names in hooks/stop include all ten the stop sources today (control)" "${_b7a_miss:- none missing}" " none missing"
for _b7a_n in route ready guard say detect maintenance overnight overnight-stop; do
  mv "$B7H/harness/lib/$_b7a_n.sh" "$B7X/$_b7a_n.sh" 2>/dev/null
  _b7a_stop "b4-$_b7a_n" false
  mv "$B7X/$_b7a_n.sh" "$B7H/harness/lib/$_b7a_n.sh" 2>/dev/null
  _b7a_is "b07 A15-A22: with lib/$_b7a_n.sh removed a dirty stop on a never-verified tree still holds (control)" "$(_b7a_hold)" "yes"
done
for _b7a_p in $B7A_LIBS; do
  _b7a_n="${_b7a_p#lib/}"; _b7a_n="${_b7a_n%.sh}"
  case " $B7TEN " in *" $_b7a_n "*) continue ;; esac
  mv "$B7H/harness/lib/$_b7a_n.sh" "$B7X/$_b7a_n.sh" 2>/dev/null
  _b7a_stop "b4x-$_b7a_n" false
  mv "$B7X/$_b7a_n.sh" "$B7H/harness/lib/$_b7a_n.sh" 2>/dev/null
  _b7a_x=no; { [ "$(_b7a_hold)" = yes ] || [ "$(_b7a_says "lib/$_b7a_n.sh")" = yes ]; } && _b7a_x=yes
  _b7a_is "b07 A23: with lib/$_b7a_n.sh removed a dirty stop holds or says lib/$_b7a_n.sh, never neither" "$_b7a_x" "yes"
done

# ---- C030: SessionStart (B5) and the monitor (B6, B7) ----
_b7a_pj absent; _b7a_ss s24
_b7a_is "b07 A24: SessionStart with project.json absent says Gate: unknown, names the path, and tells the person gate unknown" \
  "unknown=$(_b7a_in "$B7A_O" 'Gate: unknown') path=$(_b7a_in "$B7A_O" "$B7J") person=$(_b7a_says 'gate unknown')" "unknown=yes path=yes person=yes"
_b7a_is "b07 A25: and it does not say Gate: none declared" "out=$([ "$B7A_OB" -gt 0 ] && echo some || echo none) none-declared=$(_b7a_in "$B7A_O" 'Gate: none declared')" \
  "out=some none-declared=no"
# Combined with b04 (docs/2026-10-24-audit-fixes/): b04 says "no gate, stops unchecked" when no gate is declared; an unreadable
# project.json is not known to declare none, so the line says gate unknown alone.
_b7a_is "b07 A25b: and its line does not also say no gate, stops unchecked" "$(_b7a_says 'no gate, stops unchecked')" "no"
_b7a_pj '{"name": "p"}'; _b7a_ss s26
_b7a_is "b07 A26: SessionStart with a project.json that declares no gate still says Gate: none declared (control)" "$(_b7a_in "$B7A_O" 'Gate: none declared')" "yes"
_b7a_pj "$B7G"; _b7a_ss s27
_b7a_x=no; LC_ALL=C grep -Eq 'Gate: /[^ "]*/felix gate' "$B7/o" 2>/dev/null && _b7a_x=yes
_b7a_is "b07 A27: SessionStart with the gate set still says Gate: and a path ending /felix gate (control)" "$_b7a_x" "yes"
mkdir -p "$B7H/projects/q"; printf '{"name":"q","gate":"true"}\n' > "$B7H/projects/q/project.json"; printf '# q\n' > "$B7H/projects/q/CLAUDE.md"
_b7a_pj absent
printf '#!/bin/sh\nexec %s monitor --log\n' "'$B7H/harness/felix'" > "$B7/mon"; chmod +x "$B7/mon"
_b7a_run "$B7/mon" ""
B7PG="$B7H/state/monitor.html"
_b7a_x=no; LC_ALL=C grep -Eq '"name":"p","gate":[{]"unknown":"([^"\\]|\\.)*project[.]json' "$B7PG" 2>/dev/null && _b7a_x=yes
_b7a_y=no; LC_ALL=C grep -qF '"verdict":"unjudged"' "$B7PG" 2>/dev/null && _b7a_y=yes
_b7a_is "b07 A28: felix monitor --log with project.json absent exits 0, and its page gives p a gate unknown that names project.json and shows the unjudged row" \
  "exit=$B7A_RC gate=$_b7a_x verdict=$_b7a_y" "exit=0 gate=yes verdict=yes"
_b7a_y=no; LC_ALL=C grep -qF '"name":"q","gate":"true"' "$B7PG" 2>/dev/null && _b7a_y=yes
_b7a_is "b07 A29: and project q keeps its gate on the page (control)" "$_b7a_y" "yes"
_b7a_pj "$B7G"
B7A_CLS=""; B7A_NODE=""
if command -v node >/dev/null 2>&1; then
  B7A_NODE=yes
  cat > "$B7/cls.js" <<'B7_MONITOR_JS'
'use strict';
const fs = require('fs'); const vm = require('vm');
const html = fs.readFileSync(process.argv[2], 'utf8');
const m = html.match(/<script>([\s\S]*?)<\/script>/);
if (!m) { console.log('ERR no script element'); process.exit(0); }
const marker = '/*{{FELIX_DATA}}*/';
if (m[1].indexOf(marker) < 0) { console.log('ERR no data marker'); process.exit(0); }
const rows = process.argv.slice(3).map((v, i) => ({ t: '2026-10-24T10:0' + i + ':00Z', verdict: v, reason: 'a row for ' + v }));
const data = { generated: '', projects: [{ name: 'p', says: [], routes: [], routeLog: [], mistakes: [], stack: [], lessons: 0, verifyLog: rows }] };
const src = m[1].split(marker).join(JSON.stringify(data));
const any = new Proxy(function () {}, {
  get: (t, k) => (k === 'valueOf' ? () => 0 : k === 'toString' ? () => '' : typeof k === 'symbol' ? (k === Symbol.toPrimitive ? () => 0 : undefined) : any),
  apply: () => any, construct: () => any, set: () => true,
});
const els = {};
function mk(tag) {
  const t = { tag, className: '', textContent: '', children: [], firstChild: null, dataset: {}, style: {}, value: '', scrollTop: 0 };
  t.appendChild = c => { t.children.push(c); t.firstChild = t.children[0] || null; return c; };
  t.removeChild = c => { const i = t.children.indexOf(c); if (i >= 0) t.children.splice(i, 1); t.firstChild = t.children[0] || null; return c; };
  t.setAttribute = () => {}; t.addEventListener = () => {};
  return new Proxy(t, { get: (o, k) => (k in o ? o[k] : any), set: (o, k, v) => { o[k] = v; return true; } });
}
const doc = { createElement: t => mk(t), getElementById: id => (els[id] = els[id] || mk('#' + id)), addEventListener() {} };
const ctx = vm.createContext({
  document: new Proxy(doc, { get: (o, k) => (k in o ? o[k] : any) }),
  window: any, location: any, localStorage: any, sessionStorage: any, navigator: any,
  setInterval: () => 0, setTimeout: () => 0, clearTimeout() {}, clearInterval() {}, requestAnimationFrame: () => 0,
  console: { log() {}, error() {}, warn() {} },
});
try { vm.runInContext(src, ctx, { timeout: 5000 }); } catch (e) { /* start-up may stop after the functions exist */ }
try { vm.runInContext('renderLog()', ctx, { timeout: 5000 }); } catch (e) { console.log('ERR renderLog: ' + e.message); process.exit(0); }
const box = els['log'];
if (!box) { console.log('ERR the page has no log panel'); process.exit(0); }
for (const c of box.children) { if (/^gate /.test(c.textContent)) console.log(c.textContent.split(' ')[1] + '\t' + c.className); }
B7_MONITOR_JS
  B7A_CLS="$(node "$B7/cls.js" "$B7H/harness/templates/monitor.html" allowed blocked override debt unjudged quarantine zz-unseen 2>&1)"
fi
_b7a_tok() {   # VERDICT CLASS -> yes when the row's class list holds that class as a word
  local c
  c="$(LC_ALL=C awk -F'\t' -v v="$1" '$1 == v { print $2; exit }' <<< "$B7A_CLS")"
  case " $c " in *" $2 "*) printf yes ;; *) printf no ;; esac
}
_b7a_nis() {
  if [ -z "$B7A_NODE" ]; then skip "$1" "node is not on PATH"
  elif [ "$2" = "$3" ]; then ok "$1"
  else bad "$1" "expected [$3] got [$2]; the page's classes [$B7A_CLS]"; fi
}
_b7a_nis "b07 A30: the monitor's log panel gives an allowed row the class ok (control)" "$(_b7a_tok allowed ok)" "yes"
_b7a_nis "b07 A31: and a blocked row the class bad (control)" "$(_b7a_tok blocked bad)" "yes"
_b7a_nis "b07 A32: and override and debt rows the class warn (control)" "$(_b7a_tok override warn):$(_b7a_tok debt warn)" "yes:yes"
_b7a_nis "b07 A33: an unjudged row gets warn and never ok" "$(_b7a_tok unjudged warn):$(_b7a_tok unjudged ok)" "yes:no"
_b7a_nis "b07 A34: a quarantine row gets warn and never ok" "$(_b7a_tok quarantine warn):$(_b7a_tok quarantine ok)" "yes:no"
_b7a_nis "b07 A35: a verdict the page has never seen gets warn and never ok" "$(_b7a_tok zz-unseen warn):$(_b7a_tok zz-unseen ok)" "yes:no"

# ---- C035: a cloud session is told, and tells (B8 to B12) ----
B7D="$(cd "$B7H/harness" && pwd)"
_b7a_stop r1 false CLAUDE_CODE_REMOTE=true; _b7a_r="$(_b7a_j .reason)"
_b7a_is "b07 A36: a cloud session's dirty stop holds, and its reason says This is a cloud session., nohup, the engine's own felix gate and to say so in the last message" \
  "hold=$(_b7a_hold) cloud=$(_b7a_in "$_b7a_r" 'This is a cloud session.') nohup=$(_b7a_in "$_b7a_r" nohup) gate=$(_b7a_in "$_b7a_r" "$B7D/felix gate") last=$(_b7a_in "$_b7a_r" 'If you stop before the gate passes on this tree, say so in your last message')" \
  "hold=yes cloud=yes nohup=yes gate=yes last=yes"
_b7a_is "b07 A37: and that reason still says Do not describe this work as complete until it has passed. and FELIX_ALLOW_RED=1" \
  "complete=$(_b7a_in "$_b7a_r" 'Do not describe this work as complete until it has passed.') red=$(_b7a_in "$_b7a_r" FELIX_ALLOW_RED=1)" "complete=yes red=yes"
for _b7a_v in unset 1 false; do
  if [ "$_b7a_v" = unset ]; then _b7a_stop "r9-$_b7a_v" false; _b7a_w="CLAUDE_CODE_REMOTE unset"
  else _b7a_stop "r9-$_b7a_v" false CLAUDE_CODE_REMOTE="$_b7a_v"; _b7a_w="CLAUDE_CODE_REMOTE=$_b7a_v"; fi
  _b7a_r="$(_b7a_j .reason)"
  _b7a_is "b07 A38-A40: with $_b7a_w the stop holds, and its reason says neither This is a cloud session. nor nohup (control)" \
    "hold=$(_b7a_hold) cloud=$(_b7a_in "$_b7a_r" 'This is a cloud session.') nohup=$(_b7a_in "$_b7a_r" nohup)" "hold=yes cloud=no nohup=no"
done
_b7a_stop r1 true CLAUDE_CODE_REMOTE=true
_b7a_is "b07 A41: the cloud session's flagged stop after its hold prints nothing and writes no row (control)" \
  "out=$B7A_OB rows=$B7A_NV/$B7A_NS/$B7A_NU" "out=0 rows=0/0/0"
_b7a_stop r1 false CLAUDE_CODE_REMOTE=true
_b7a_is "b07 A42: its next unflagged stop on the unchanged tree appends one debt row: never checked, held once on this tree already" \
  "rows=$B7A_NV f2=$(_b7a_vf 2) never=$(_b7a_in "$(_b7a_vf 4)" 'never checked') once=$(_b7a_in "$(_b7a_vf 4)" 'held once on this tree already')" \
  "rows=1 f2=debt never=yes once=yes"
_b7a_jis "b07 A43: and it exits 0 with one JSON object, no decision and no hookSpecificOutput, saying let go with the gate not passed on this tree, never checked and ends with the VM" \
  "exit=$B7A_RC json=$(_b7a_obj) decision=$(_b7a_dec) hso=$(_b7a_in "$B7A_O" '"hookSpecificOutput"') letgo=$(_b7a_says 'let go with the gate not passed on this tree') never=$(_b7a_says 'never checked') vm=$(_b7a_says 'ends with the VM')" \
  "exit=0 json=yes decision=no hso=no letgo=yes never=yes vm=yes"
_b7a_is "b07 A44: and says.log gains one row of kind debt" "$(_b7a_kinds debt)" "1"
_b7a_stop l1 false; _b7a_h1="$(_b7a_hold)"
_b7a_stop l1 true; _b7a_h2="$B7A_OB:$B7A_NV"
_b7a_stop l1 false
_b7a_is "b07 A45: a local session's same three stops hold, then say nothing, then add one debt row and print nothing (control)" \
  "hold=$_b7a_h1 flagged=$_b7a_h2 debt=$B7A_OB:$B7A_NV:$(_b7a_vf 2)" "hold=yes flagged=0:0 debt=0:1:debt"
_b7a_is "b07 A46: the suite's own shell has no CLAUDE_CODE_REMOTE by the time this part runs" "$_b7a_env" ""

# ---- the restore ----
chmod -R u+rwX "$B7" 2>/dev/null
for _b7a_v in $(compgen -v | LC_ALL=C grep -E '^(B7[A-Z0123456789_]*|_b7a_[A-Za-z0123456789_]*)$'); do unset "$_b7a_v"; done
for _b7a_f in $(compgen -A function | LC_ALL=C grep -E '^_b7a_'); do unset -f "$_b7a_f"; done
unset _b7a_v _b7a_f
# <<< b07-stop
