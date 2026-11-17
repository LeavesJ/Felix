printf '\ndiscovery never promises what cannot happen (blind, audit b06)\n'
# Written blind on 2026-10-24 from docs/2026-10-24-audit-fixes/b06-pulse-and-
# discovery-never-promise-what-c.md alone (A1-A29 of its section 4), before any of
# it was built and without reading the code it is about. Each name is the sentence
# it proves. One assertion per item; where the contract marks only part of an item
# [control], that part is an assertion of its own, so red.tsv can tell them apart.
#
# Readings, mine where the contract leaves room:
# - The stub FELIX is the stub's lines followed by the real felix's text, after an
#   exit, so it runs as the stub and a stamp read from felix's cmd_discover reads
#   the real one in the harness copy the session fixture runs (section 4: "harness
#   copy with the stub as felix").
# - The Wait is "lock gone and record present"; a run that never writes the record
#   (the engine before the fix) waits the whole 20 s, so a red run here is slow.
# - A21 is said by run 2 and not by run 3: a run 3 that is quiet only because run 2
#   never spoke proves nothing about "said once".
# - A22 and A23 hold a fresh lock (B6a: the refresh then runs nothing and leaves the
#   record as it is), so the refresh the hook starts cannot rewrite the record the
#   run is about before the hook reads it.
# - X, the engine-tree copy of B10, is engine/harness without tests/ beside
#   engine/.claude-plugin/plugin.json. "One line appended" to discover.sh and
#   detect.sh is a no-op command line; the pulse.sh and felix lines are comments.
# - README.md is read with its line breaks and runs of blanks folded to one space:
#   the sentence B11 retires wraps across a line.
# Every fixture lives under one private directory (A0); with no base that qualifies,
# the assertions that need a private TMPDIR skip with the reason.
_dnB=""
for _dnc in "$TMP" "${XDG_RUNTIME_DIR:-}" "${RUNNER_TEMP:-}" "${HOME:-}"; do
  [ -n "$_dnc" ] && command -v _rx_base_ok >/dev/null 2>&1 && _rx_base_ok "$_dnc" || continue
  if [ "$_dnc" = "$TMP" ]; then _dnB="$TMP"; else _dnB="$(mktemp -d "$_dnc/.felix-suite-dn.XXXXXX" 2>/dev/null)" || _dnB=""; fi
  [ -n "$_dnB" ] && break
done
DNPRIV=1; [ -n "$_dnB" ] || { _dnB="$TMP"; DNPRIV=0; }
_dnwhy="no base whose every ancestor only root or this user can write, with no .mcp.json above it (A0)"
_fx_root_add "$_dnB"
DN="$(mktemp -d "$_dnB/dn.XXXXXX")"; DN="$(cd "$DN" && pwd -P)"
DNT="$DN/tmp"; DNH="$DN/home"; DNP="$DNH/projects/dp"; DNS="$DNH/state/discover"; DNHH="$DN/h/harness"
mkdir -p "$DNT" "$DNP" "$DNS" "$DN/bin" "$DN/log" "$DN/user" "$DN/mem" "$DN/cache" "$DN/co/dp" "$DN/h"
chmod 700 "$DNT"
printf '{"name": "dp", "gate": "true"}\n' > "$DNP/project.json"; printf '# dp\n' > "$DNP/CLAUDE.md"
printf 'debug\tbroken failing crash\tcore\tsuperpowers:systematic-debugging\n' > "$DNP/routes.tsv"
DNREC="$DNS/dp.refresh"; DNTSV="$DNS/dp.tsv"; DNLOCK="$DNS/.lock"; _dnT="$(printf '\t')"
for _w in felix claude graphify; do : > "$DN/log/$_w.log"; done
for _w in claude graphify; do
  printf '#!/bin/bash\nprintf "%%s\\t%%s\\n" "$(pwd -P)" "$*" >> "%s"\nexit 0\n' "$DN/log/$_w.log" > "$DN/bin/$_w"; chmod +x "$DN/bin/$_w"
done
_dn_sl() { HOME="$DN/user" /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/discover.sh" || exit 97; _felix_discover_stamp_line "$1/templates"' sl "$1" 2>/dev/null; }
DNSTAMP="$(_dn_sl "$FROOT/harness")"
cp -R "$FROOT/harness" "$DNHH"
{ sed -e "s|DN_LOG|$DN/log/felix.log|" -e "s|DN_STAMP|$DNSTAMP|" <<'DNSTUBHEAD'
#!/bin/bash
printf '%s\t%s\n' "$(pwd -P)" "$*" >> "DN_LOG"
case "$*" in
  "discover --inspect --quiet")
    printf '%s\n' "${STUB_STAMP:-DN_STAMP}"
    printf 'cand1\tllm\tlow\t-\ncand2\tllm\tlow\t-\n'
    sleep "${STUB_SLEEP:-0}"
    exit "${STUB_RC:-0}" ;;
esac
exit 0
DNSTUBHEAD
  cat "$FROOT/harness/felix"; } > "$DNHH/felix"
chmod +x "$DNHH/felix"; DNSTUB="$DNHH/felix"; DNSTAMPH="$(_dn_sl "$DNHH")"
{ printf '%s\n' "$DNSTAMP"; printf 'cand1\tllm\tlow\t-\ncand2\tllm\tlow\t-\n'; } > "$DN/want.tsv"

_dn_env() {   # the fixture's HOME, home, memory and TMPDIR (DN_TMP: unset, a value, or - for no TMPDIR), the stubs first on PATH
  local t="TMPDIR=${DN_TMP-$DNT}"; [ "${DN_TMP-}" = - ] && t="DN_NOTMP=1"
  env -u CLAUDE_CONFIG_DIR -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR -u TMPDIR -u CLAUDE_PLUGIN_ROOT -u GIT_DIR -u GIT_WORK_TREE \
      HOME="$DN/user" FELIX_HOME="$DNH" FELIX_MEMORY="$DN/mem" FELIX_PLUGIN_CACHE="$DN/cache" "$t" PATH="$DN/bin:$PATH" \
      STUB_RC="${STUB_RC:-0}" STUB_SLEEP="${STUB_SLEEP:-0}" STUB_STAMP="${STUB_STAMP:-$DNSTAMP}" "$@"
}
_dn_lib() {   # <harness> <lib> <code> [args]: resolve.sh and one lib under /bin/bash; 97 when either cannot be sourced
  local h="$1" l="$2" c="$3"; shift 3
  _dn_env /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/$2.sh" || exit 97; c="$3"; shift 3; eval "$c"' dnl "$h" "$l" "$c" "$@"
}
_dn_wait() { local i=0 n="$(( $1 * 5 ))"; while [ "$i" -lt "$n" ]; do eval "$2" && return 0; sleep 0.2; i="$(( i + 1 ))"; done; eval "$2"; }
_dn_dn() { LC_ALL=C awk -F'\t' '$2 == "discover --inspect --quiet" { n++ } END { print n + 0 }' "$DN/log/felix.log"; }
_dn_cn() { LC_ALL=C awk 'END { print NR }' "$DN/log/claude.log"; }
_dn_in() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }
_dn_clean() { rm -f "$DNREC" "$DNTSV"; rmdir "$DNLOCK" 2>/dev/null; return 0; }
_dn_call() {  # one felix_discover_refresh_bg PROJ HOME FELIX from the real harness; DNOUT is what it printed, then |status
  DNT0="$(date +%s)"
  DNOUT="$(_dn_lib "$FROOT/harness" discover 'felix_discover_refresh_bg "$1" "$2" "$3"; printf "|%s" "$?"' "$DNP" "$DNH" "$DNSTUB" 2>&1)"
}
_dn_rwait() { _dn_wait 20 '[ ! -d "$DNLOCK" ] && [ -s "$DNREC" ]'; DNT1="$(date +%s)"; }
_dn_bg() { _dn_call; _dn_rwait; }
_dn_rv() {   # <outcome> <phrase>: ok when the record is one line EPOCH<TAB>OUTCOME<TAB>DETAIL in the window, else what it holds
  [ -f "$DNREC" ] || { printf 'no record'; return 0; }
  LC_ALL=C awk -F'\t' -v o="$1" -v p="$2" -v a="${DNT0:-0}" -v b="${DNT1:-0}" '
    { n++; l = $0; nf = NF; e = $1; oc = $2; d = $3 }
    END { if (n != 1) { printf "%d lines", n; exit }
          if (nf != 3) { printf "%d fields [%s]", nf, l; exit }
          if (e !~ /^[0123456789]+$/ || e + 0 < a - 2 || e + 0 > b + 2) { printf "epoch %s outside %s-%s", e, a, b; exit }
          if (oc != o) { printf "outcome %s [%s]", oc, d; exit }
          if (d == "" || (p != "" && index(d, p) == 0)) { printf "detail [%s]", d; exit }
          printf "ok" }' "$DNREC"
}

printf '\nthe refresh record (B1, B3)\n'
DNNEG=3
if [ "$DNPRIV" = 1 ]; then
  _dn_clean; _dn_call; _dn_wait 20 '[ ! -d "$DNLOCK" ] && [ -s "$DNTSV" ]'; DNLAT="$(( $(date +%s) - DNT0 ))"; _dn_rwait
  DNNEG="$(( DNLAT * 3 + 2 ))"; [ "$DNNEG" -lt 3 ] && DNNEG=3; [ "$DNNEG" -gt 12 ] && DNNEG=12
  is "b06 A1: after a refresh that ran, dp.refresh is one line of three tab fields, its epoch in the call's window, outcome ran" "$(_dn_rv ran '')" "ok"
  is "b06 A2: and no .new. file is left in state/discover, and the call printed nothing and returned 0" \
     "$(ls -A "$DNS" | grep -c '\.new\.') [$DNOUT]" "0 [|0]"
  cmp -s "$DN/want.tsv" "$DNTSV" && ok "b06 A6: with a private TMPDIR the cache is the stub's stdout, byte for byte" \
    || bad "b06 A6: with a private TMPDIR the cache is the stub's stdout, byte for byte" "[$(cat "$DNTSV" 2>/dev/null)]"
else
  for _w in "b06 A1: after a refresh that ran, dp.refresh is one line of three tab fields, its epoch in the call's window, outcome ran" \
            "b06 A2: and no .new. file is left in state/discover, and the call printed nothing and returned 0" \
            "b06 A6: with a private TMPDIR the cache is the stub's stdout, byte for byte"; do skip "$_w" "$_dnwhy"; done
fi

printf '\nnot run: no private TMPDIR (B2)\n'
mkdir -p "$DN/d777" "$DN/mcp/tmp"; chmod 777 "$DN/d777"; chmod 700 "$DN/mcp/tmp"; printf '{}\n' > "$DN/mcp/.mcp.json"
_dn_a3=""; _dn_a4=""; _dn_a5=""
for _dnk in unset empty rel d777 mcp missing; do
  case "$_dnk" in d777|mcp|missing) [ "$DNPRIV" = 1 ] || continue ;; esac
  _dn_clean; _dnd0="$(_dn_dn)"; _dnc0="$(_dn_cn)"
  case "$_dnk" in
    unset)   DN_TMP=- _dn_bg;                  _dnw="TMPDIR is not an absolute path" ;;
    empty)   DN_TMP= _dn_bg;                   _dnw="TMPDIR is not an absolute path" ;;
    rel)     DN_TMP=rel-tmp _dn_bg;            _dnw="TMPDIR is not an absolute path" ;;
    d777)    DN_TMP="$DN/d777" _dn_bg;         _dnw="TMPDIR is not a private directory" ;;
    mcp)     DN_TMP="$DN/mcp/tmp" _dn_bg;      _dnw=".mcp.json" ;;
    missing) DN_TMP="$DN/no-such-tmp" _dn_bg;  _dnw="could not make an empty directory" ;;
  esac
  _dnf=""
  [ "$(_dn_dn)" = "$_dnd0" ] || _dnf="$_dnf,felix-ran"
  [ "$(_dn_cn)" = "$_dnc0" ] || _dnf="$_dnf,claude-ran"
  [ -e "$DNTSV" ] && _dnf="$_dnf,cache"
  [ -d "$DNLOCK" ] && _dnf="$_dnf,lock"
  _dn_a5="$_dn_a5 $_dnk:${_dnf:-none}"
  case "$_dnk" in
    unset|empty|rel) _dn_a3="$_dn_a3 $_dnk:$(_dn_rv not-run "$_dnw")$_dnf" ;;
    *)               _dn_a4="$_dn_a4 $_dnk:$(_dn_rv not-run "$_dnw")" ;;
  esac
done
is "b06 A3: with TMPDIR unset, empty or relative the record is not-run, TMPDIR is not an absolute path, and no felix, cache or lock" \
   "$_dn_a3" " unset:ok empty:ok rel:ok"
if [ "$DNPRIV" = 1 ]; then
  is "b06 A4: a 0777 TMPDIR, one under a .mcp.json and one that does not exist are not-run, each with its own reason" \
     "$_dn_a4" " d777:ok mcp:ok missing:ok"
  is "b06 A5: none of the six starts felix or claude, writes a cache or leaves a lock" "$_dn_a5" \
     " unset:none empty:none rel:none d777:none mcp:none missing:none"
else
  skip "b06 A4: a 0777 TMPDIR, one under a .mcp.json and one that does not exist are not-run, each with its own reason" "$_dnwhy"
  skip "b06 A5: none of the six starts felix or claude, writes a cache or leaves a lock" "$_dnwhy"
fi

printf '\nfailed: what felix did, and a cache no reader takes (B4, B5)\n'
if [ "$DNPRIV" = 1 ]; then
  _dn_clean; printf '# previous cache\nold\tllm\tlow\t-\n' > "$DNTSV"; cp "$DNTSV" "$DN/prev.keep"
  STUB_RC=1 _dn_bg
  is "b06 A7: a felix that exits 1 leaves the previous cache byte-identical and records failed, exited 1" \
     "$(cmp -s "$DN/prev.keep" "$DNTSV" && echo same || echo changed) $(_dn_rv failed 'exited 1')" "same ok"
  _dn_clean; _dnd0="$(_dn_dn)"; STUB_RC=125 _dn_bg
  is "b06 A8: a felix that started and exited 125 ran once and is failed, exited 125, never not-run" \
     "$(( $(_dn_dn) - _dnd0 )) $(_dn_rv failed 'exited 125')" "1 ok"
  _dn_clean; STUB_STAMP='# stamp stub' _dn_bg
  printf '# stamp stub\ncand1\tllm\tlow\t-\ncand2\tllm\tlow\t-\n' > "$DN/stub.tsv"
  is "b06 A9: a felix whose first line is not the current stamp leaves its stdout as the cache and records failed, naming the stamp" \
     "$(cmp -s "$DN/stub.tsv" "$DNTSV" && echo same || echo changed) $(_dn_rv failed stamp)" "same ok"
else
  for _w in "b06 A7: a felix that exits 1 leaves the previous cache byte-identical and records failed, exited 1" \
            "b06 A8: a felix that started and exited 125 ran once and is failed, exited 125, never not-run" \
            "b06 A9: a felix whose first line is not the current stamp leaves its stdout as the cache and records failed, naming the stamp"; do
    skip "$_w" "$_dnwhy"; done
fi

printf '\nthe lock (B6, B7)\n'
if [ "$DNPRIV" = 1 ]; then
  _dn_clean; mkdir "$DNLOCK"; _dnd0="$(_dn_dn)"; _dn_call; _dn_wait "$DNNEG" '[ "$(_dn_dn)" -gt '"$_dnd0"' ]'
  _dnv="$(( $(_dn_dn) - _dnd0 )) $([ -e "$DNREC" ] && echo record || echo absent) $([ -d "$DNLOCK" ] && echo lock)"
  printf '7\tran\tkept as it was\n' > "$DNREC"; cp "$DNREC" "$DN/rec.keep"; _dnd0="$(_dn_dn)"
  _dn_call; _dn_wait "$DNNEG" '[ "$(_dn_dn)" -gt '"$_dnd0"' ]'
  _dnv="$_dnv / $(( $(_dn_dn) - _dnd0 )) $(cmp -s "$DN/rec.keep" "$DNREC" && echo same || echo changed) $([ -d "$DNLOCK" ] && echo lock)"
  is "b06 A10: a lock under 30 minutes old starts no felix, leaves the record absent or byte-identical, and stays" "$_dnv" "0 absent lock / 0 same lock"
  _dn_clean; mkdir "$DNLOCK"; touch -t 200001010000 "$DNLOCK"; _dnd0="$(_dn_dn)"; _dn_bg
  is "b06 A11: a lock older than 30 minutes is broken: felix runs once, the record is written, and the lock is gone" \
     "$(( $(_dn_dn) - _dnd0 )) $([ -d "$DNLOCK" ] && echo lock || echo gone) $(_dn_rv ran '')" "1 gone ok"
  rmdir "$DNLOCK" 2>/dev/null
else
  skip "b06 A10: a lock under 30 minutes old starts no felix, leaves the record absent or byte-identical, and stays" "$_dnwhy"
  skip "b06 A11: a lock older than 30 minutes is broken: felix runs once, the record is written, and the lock is gone" "$_dnwhy"
fi
DNG="$DN/g"; mkdir -p "$DNG"
( _fx_cd "$DNG" && git init -q -b main && printf 'a\n' > f.txt && git add -A && git -c user.name=t -c user.email=t@t commit -qm one \
  && printf 'b\n' > f.txt && git -c user.name=t -c user.email=t@t commit -qam two ) >/dev/null 2>&1
DNG="$(cd "$DNG" && pwd -P)"; mkdir -p "$DNG/graphify-out"; DNGL="$DNG/graphify-out/.felix-refresh.lock"
printf '{"nodes":[],"built_at_commit":"%s"}\n' "$(git -C "$DNG" rev-list --max-parents=0 HEAD 2>/dev/null)" > "$DNG/graphify-out/graph.json"
_dn_ga() { LC_ALL=C awk 'END { print NR }' "$DN/log/graphify.log"; }
_dn_gu() { LC_ALL=C awk -F'\t' -v a="update $DNG" '$2 == a { n++ } END { print n + 0 }' "$DN/log/graphify.log"; }
mkdir "$DNGL"; _dng0="$(_dn_ga)"
_dn_lib "$FROOT/harness" graph 'felix_graph_refresh_bg "$1"' "$DNG" >/dev/null 2>&1
_dn_wait "$DNNEG" '[ "$(_dn_ga)" -gt '"$_dng0"' ]'
_dnv="$(( $(_dn_ga) - _dng0 )) $([ -d "$DNGL" ] && echo lock)"
touch -t 200001010000 "$DNGL"; _dng0="$(_dn_gu)"
_dn_lib "$FROOT/harness" graph 'felix_graph_refresh_bg "$1"' "$DNG" >/dev/null 2>&1
_dn_wait 20 '[ "$(_dn_gu)" -gt '"$_dng0"' ] && [ ! -d "$DNGL" ]'
_dnv="$_dnv / $(( $(_dn_gu) - _dng0 )) $([ -d "$DNGL" ] && echo lock || echo gone)"
is "b06 A12: the graph lock: a fresh one means no graphify call and stays; an old one is broken, graphify update runs once, and it is gone" \
   "$_dnv" "0 lock / 1 gone"
rmdir "$DNGL" 2>/dev/null

printf '\nthe pulse'"'"'s discovery line (B8)\n'
DNPH="$DN/ph"; mkdir -p "$DNPH/projects/dp" "$DNPH/projects/nr" "$DNPH/state/discover"
for _p in dp nr; do printf '{"name": "%s", "gate": "true"}\n' "$_p" > "$DNPH/projects/$_p/project.json"; printf '# %s\n' "$_p" > "$DNPH/projects/$_p/CLAUDE.md"; done
cp "$DNP/routes.tsv" "$DNPH/projects/dp/routes.tsv"
printf '86400\tnot-run\tTMPDIR is not an absolute path\n' > "$DNPH/state/discover/nr.refresh"
_dn_rep() { _dn_env /bin/bash -c 'for l in resolve detect stack maintenance discover pulse; do . "$1/lib/$l.sh" || exit 97; done; felix_pulse_report "$2"' \
              rep "$FROOT/harness" "$DNPH" 2>/dev/null; }
_dn_dl() { printf '%s\n' "$1" | LC_ALL=C awk -F'\t' -v n="$2" '$2 == n && ($1 == "stale" || $1 == "discover-unread")'; }
_dn_put() { if [ "$1" = - ]; then rm -f "$DNPH/state/discover/dp.refresh"; else printf '%b' "$1" > "$DNPH/state/discover/dp.refresh"; fi; }
_dnlf="discover-unread${_dnT}dp${_dnT}the record of the last background refresh could not be read, so whether one can run here is not known; felix discover --adopt in its checkout fills the cache in the foreground"
_dnx="TMPDIR is not an absolute path, so there is no private directory to run discovery in"
{ printf '%s\n' "$DNSTAMP"; printf 'cand1\tllm\tlow\t-\n'; } > "$DNPH/state/discover/dp.tsv"
_dn_put '86400\tnot-run\tTMPDIR is not an absolute path\n'; _dno="$(_dn_rep)"; DNALL="$_dno"
is "b06 A13: a current, fresh cache prints no stale or discover-unread line for dp, whatever the record holds" "$(_dn_dl "$_dno" dp)" ""
rm -f "$DNPH/state/discover/dp.tsv"
_dn_put -; _dno="$(_dn_rep)"; DNALL="$DNALL
$_dno"
is "b06 A14: no cache and no record print exactly: no background refresh is recorded here, and the next session starts one" "$(_dn_dl "$_dno" dp)" \
   "stale${_dnT}dp${_dnT}discovery cache; no background refresh is recorded here, and the next session in its checkout starts one"
_dn_put '86400\tran\tthe cache was rewritten\n'; _dno="$(_dn_rep)"; DNALL="$DNALL
$_dno"
is "b06 A15: a ran record prints exactly when it ran, and that the next session starts another" "$(_dn_dl "$_dno" dp)" \
   "stale${_dnT}dp${_dnT}discovery cache; the last background refresh ran at 1970-01-02T00:00Z, and the next session in its checkout starts another"
_dn_put "86400\tnot-run\t$_dnx\n"; _dno="$(_dn_rep)"; DNALL="$DNALL
$_dno"
is "b06 A16: a not-run record prints exactly one discover-unread line with its reason, and no dp line promises the next session" \
   "$(_dn_dl "$_dno" dp)|$(printf '%s\n' "$_dno" | LC_ALL=C awk -F'\t' '$2 == "dp" && index($0, "the next session") { n++ } END { print n + 0 }')" \
   "discover-unread${_dnT}dp${_dnT}the last background refresh, at 1970-01-02T00:00Z, ran nothing: $_dnx; felix discover --adopt in its checkout fills the cache in the foreground|0"
_dn_put '86400\tfailed\tfelix discover exited 3; the previous cache was left as it was\n'; _dno="$(_dn_rep)"; DNALL="$DNALL
$_dno"
has "b06 A17: a failed record prints failed: with its detail, in the place of ran nothing:" "$(_dn_dl "$_dno" dp)" \
    "at 1970-01-02T00:00Z, failed: felix discover exited 3; the previous cache was left as it was;"
_dnv=""
for _r in empty two abc maybe; do
  case "$_r" in
    empty) : > "$DNPH/state/discover/dp.refresh" ;;
    two)   _dn_put '86400\tran\tone\n86400\tran\ttwo\n' ;;
    abc)   _dn_put 'abc\tran\tx\n' ;;
    maybe) _dn_put '86400\tmaybe\tx\n' ;;
  esac
  _dno="$(_dn_rep)"; DNALL="$DNALL
$_dno"
  if [ "$(_dn_dl "$_dno" dp)" = "$_dnlf" ]; then _dnv="$_dnv $_r:ok"; else _dnv="$_dnv $_r:[$(_dn_dl "$_dno" dp)]"; fi
done
is "b06 A18: an empty, two-line, non-numeric or unknown-outcome record prints exactly that the record could not be read" "$_dnv" " empty:ok two:ok abc:ok maybe:ok"
_dn_in "$DNALL" "refreshes it in the background" && _dnv=promised || _dnv=none
is "b06 A19: no report line says the next session refreshes it in the background" "$_dnv" "none"
is "b06 A19 (control): a project without routes.tsv gets no discovery line, record or not" "$(_dn_dl "$DNALL" nr)" ""

printf '\nsaid once at session start (B9)\n'
DNCO="$DN/co/dp"
( _fx_cd "$DNCO" && git init -q -b main && printf 'dp\n' > .felix && printf 'x\n' > f.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
DNCO="$(cd "$DNCO" && pwd -P)"; DNSN=0
_dn_ss() {   # one SessionStart in the dp checkout from the harness copy; DNC is its additionalContext
  DNSN="$(( DNSN + 1 ))"
  DNC="$(cd "$DNCO" && printf '{"session_id":"dn-%s","hook_event_name":"SessionStart","source":"startup"}' "$DNSN" \
         | _dn_env CLAUDE_PLUGIN_ROOT="$DN/h" "$DNHH/hooks/session-start" 2>/dev/null | python3 -c 'import json, sys
try: d = json.loads(sys.stdin.read())
except Exception: sys.exit(3)
sys.stdout.write((d.get("hookSpecificOutput") or {}).get("additionalContext") or d.get("additionalContext") or "")' 2>/dev/null)"
}
_dn_said() { _dn_in "$DNC" "Discovery has not refreshed" && echo said || echo quiet; }
_dn_clean; DNT0="$(date +%s)"; DN_TMP=- _dn_ss; _dn_rwait
is "b06 A20 (precondition): a session start with TMPDIR unset leaves a not-run record" "$(_dn_rv not-run 'TMPDIR is not an absolute path')" "ok"
DN_TMP=- _dn_ss; _dn_wait 20 '[ ! -d "$DNLOCK" ]'; _dnv=""
_dn_in "$DNC" "Discovery has not refreshed for dp: the last background refresh, at " || _dnv="$_dnv lacks-the-sentence"
_dn_in "$DNC" "ran nothing: TMPDIR is not an absolute path" || _dnv="$_dnv lacks-the-reason"
is "b06 A20: the next session start says discovery has not refreshed for dp, and why" "${_dnv:-said}" "said"
_dnv="$(_dn_said)"; DN_TMP=- _dn_ss; _dn_wait 20 '[ ! -d "$DNLOCK" ]'
is "b06 A21: said once: the start after it, with the same outcome and detail, does not say it again" "$_dnv then $(_dn_said)" "said then quiet"
mkdir "$DNLOCK"
printf '%s\tfailed\tfelix discover exited 3; the previous cache was left as it was\n' "$(date +%s)" > "$DNREC"; DN_TMP=- _dn_ss
_dn_in "$DNC" "failed: felix discover exited 3" && _dnv=said || _dnv=quiet
is "b06 A22: a different outcome or detail from the one last said is said again" "$_dnv" "said"
printf '%s\tran\tthe cache was rewritten\n' "$(date +%s)" > "$DNREC"; rm -f "$DNTSV"; DN_TMP=- _dn_ss; _dnv="$(_dn_said)"
{ printf '%s\n' "$DNSTAMPH"; printf 'cand1\tllm\tlow\t-\ncand2\tllm\tlow\t-\n'; } > "$DNTSV"
printf '%s\tnot-run\tTMPDIR is not an absolute path\n' "$(date +%s)" > "$DNREC"; DN_TMP=- _dn_ss
is "b06 A23: never said with a ran record, nor over a current, fresh cache" "$_dnv $(_dn_said)" "quiet quiet"
rmdir "$DNLOCK" 2>/dev/null
if [ "$DNPRIV" = 1 ]; then
  _dn_clean; _dnd0="$(_dn_dn)"; STUB_SLEEP=8 _dn_ss
  _dn_wait 3 '[ -d "$DNLOCK" ]' && _dnv=held || _dnv=free
  _dn_wait 20 '[ ! -d "$DNLOCK" ]'
  is "b06 A24 (control): on a stale cache the hook starts the refresh and does not wait: the lock is held when it returns, gone later, one refresh" \
     "$_dnv $([ -d "$DNLOCK" ] && echo held || echo gone) $(( $(_dn_dn) - _dnd0 ))" "held gone 1"
else
  skip "b06 A24 (control): on a stale cache the hook starts the refresh and does not wait: the lock is held when it returns, gone later, one refresh" "$_dnwhy"
fi

printf '\nthe stamp covers what writes the rows, not the version (B10)\n'
DNX="$DN/x"; mkdir -p "$DNX/x0/engine/.claude-plugin"
cp -R "$FROOT/harness" "$DNX/x0/engine/harness"; rm -rf "$DNX/x0/engine/harness/tests"
_dnpj="$REAL_HARNESS/../.claude-plugin/plugin.json"
if [ -f "$_dnpj" ]; then cp "$_dnpj" "$DNX/x0/engine/.claude-plugin/plugin.json"
else printf '{\n  "name": "felix",\n  "version": "0.0.1"\n}\n' > "$DNX/x0/engine/.claude-plugin/plugin.json"; fi
for _v in v p f d t c n; do cp -R "$DNX/x0" "$DNX/x$_v"; done
_dnpv="$DNX/xv/engine/.claude-plugin/plugin.json"
sed 's/"version": *"[^"]*"/"version": "9.9.9-b06"/' "$_dnpv" > "$_dnpv.b06" && mv "$_dnpv.b06" "$_dnpv"
printf '# b06 probe\n' >> "$DNX/xp/engine/harness/lib/pulse.sh"; printf '# b06 probe\n' >> "$DNX/xf/engine/harness/felix"
printf ': b06 probe\n' >> "$DNX/xd/engine/harness/lib/discover.sh"; printf ': b06 probe\n' >> "$DNX/xt/engine/harness/lib/detect.sh"
LC_ALL=C awk '{ print } index($0, "cmd_discover() {") == 1 { print "  # b06 probe"; n++ } END { exit (n == 1) ? 0 : 1 }' \
  "$DNX/x0/engine/harness/felix" > "$DNX/xc/engine/harness/felix"; _dnfc=$?
rm -f "$DNX/xn/engine/harness/felix"
_dn_x() {   # <engine copy> <code> [args]: X's resolve.sh and discover.sh under /bin/bash
  local x="$1" c="$2"; shift 2
  env -u CLAUDE_PLUGIN_ROOT -u FELIX_HOME_DIR HOME="$DN/user" FELIX_HOME="$DNH" FELIX_MEMORY="$DN/mem" PATH="$DN/bin:$PATH" \
    /bin/bash -c '. "$1/harness/lib/resolve.sh" && . "$1/harness/lib/discover.sh" || exit 97; c="$2"; shift 2; eval "$c"' dx "$x" "$c" "$@" 2>/dev/null
}
_dn_st() { _dn_x "$1" '_felix_discover_stamp "$@"' ${2:+"$2"}; }
_dn_hex() { printf '%s' "$1" | LC_ALL=C awk 'length($0) == 40 && /^[0123456789abcdef]+$/ { h = 1 } END { print (h && NR == 1) ? "hex" : "not hex" }'; }
_dns0="$(_dn_st "$DNX/x0/engine")"; _dnsrc=$?
is "b06 A25: the stamp exits 0, is 40 lowercase hex, and is the same after only the version changes in plugin.json" \
   "$_dnsrc $(_dn_hex "$_dns0") $(grep -c '9.9.9-b06' "$_dnpv") $([ "$(_dn_st "$DNX/xv/engine")" = "$_dns0" ] && echo same || echo differs)" "0 hex 1 same"
is "b06 A25 (control): and the same after a comment is appended to lib/pulse.sh, or at the end of felix" \
   "$([ "$(_dn_st "$DNX/xp/engine")" = "$_dns0" ] && echo same || echo differs) $([ "$(_dn_st "$DNX/xf/engine")" = "$_dns0" ] && echo same || echo differs)" "same same"
_dnv=""
for _v in d t c; do _s="$(_dn_st "$DNX/x$_v/engine")"; if [ -n "$_s" ] && [ "$_s" != "$_dns0" ]; then _dnv="$_dnv $_v:differs"; else _dnv="$_dnv $_v:same"; fi; done
[ "$_dnfc" = 0 ] || _dnv="$_dnv (felix holds no single cmd_discover() { line)"
is "b06 A26: the stamp differs after one line appended to lib/discover.sh, one to lib/detect.sh, or a comment after cmd_discover() {" \
   "$_dnv" " d:differs t:differs c:differs"
cp -R "$DNX/x0/engine/harness/templates" "$DNX/tpl"
LC_ALL=C awk '!d && !/^#/ && NF { print $0 " b06"; d = 1; next } { print }' "$DNX/x0/engine/harness/templates/discover-rules.tsv" > "$DNX/tpl/discover-rules.tsv"
_s="$(_dn_st "$DNX/x0/engine" "$DNX/x0/engine/harness/templates")"
is "b06 A26 (control): and after one line of the rules table changes" \
   "$([ -n "$_s" ] && [ "$_s" != "$(_dn_st "$DNX/x0/engine" "$DNX/tpl")" ] && echo differs || echo same)" "differs"
_dn_xh() { mkdir -p "$1/projects/dp" "$1/state/discover"; cp "$DNP/project.json" "$DNP/routes.tsv" "$DNP/CLAUDE.md" "$1/projects/dp/"; }
_dn_cs() { _dn_x "$1" 'felix_discover_cache_current "$1" "$2"; a=$?; felix_discover_stale "$1" "$2"; printf "%s %s" "$a" "$?"' "$2/projects/dp" "$2"; }
_dnxn="$DNX/xn/engine"; _dn_xh "$DN/xh"
{ printf '# stamp \n'; printf 'cand1\tllm\tlow\t-\n'; } > "$DN/xh/state/discover/dp.tsv"; _dnv="$(_dn_cs "$_dnxn" "$DN/xh")"
{ _dn_x "$_dnxn" '_felix_discover_stamp_line "$1"' "$_dnxn/harness/templates"; printf '\ncand1\tllm\tlow\t-\n'; } > "$DN/xh/state/discover/dp.tsv"
is "b06 A27: when the stamp cannot be computed (no felix) no cache is current, its own stamp line's included, and both read stale" \
   "$_dnv / $(_dn_cs "$_dnxn" "$DN/xh")" "1 0 / 1 0"
_dn_xh "$DN/xe"
{ _dn_x "$DNX/x0/engine" '_felix_discover_stamp_line "$1"' "$DNX/x0/engine/harness/templates"; printf '\ncand1\tllm\tlow\t-\ncand2\tllm\tlow\t-\n'; } \
  > "$DN/xe/state/discover/dp.tsv"
_dnu="$(_dn_x "$DNX/xv/engine" 'felix_discover_unseen "$1" "$2"' "$DN/xe/projects/dp" "$DN/xe" | tr '\n' ' ')"
_dn_in "$_dnu" cand1 && _dn_in "$_dnu" cand2 && _dnu=both || _dnu="[$_dnu]"
is "b06 A28: a fresh cache stamped before a version bump stays current: not stale, both unseen, both adopted" \
   "$(_dn_cs "$DNX/xv/engine" "$DN/xe") $_dnu $(_dn_x "$DNX/xv/engine" 'felix_discover_adopt "$1" "$2"' "$DN/xe/projects/dp" "$DN/xe" | grep -c .)" \
   "0 1 both 2"

printf '\nthe README says what happens (B11)\n'
_dnrm="$REAL_HARNESS/../../README.md"
if [ -f "$_dnrm" ]; then
  _dnrt="$(tr '\n' ' ' < "$_dnrm" | tr -s ' ')"; _dnrs="$(grep '^| Session start |' "$_dnrm" | head -1)"; _dnv=""
  _dn_in "$_dnrt" "clones candidate plugins once a week" && _dnv="$_dnv still-weekly"
  _dn_in "$_dnrt" "[redacted]" || _dnv="$_dnv no-[redacted]"
  _dn_in "$_dnrs" "TMPDIR" || _dnv="$_dnv session-row-lacks-TMPDIR"
  is "b06 A29: README.md no longer says once a week, names [redacted], and its Session start row names TMPDIR" "${_dnv:-ok}" "ok"
else
  skip "b06 A29: README.md no longer says once a week, names [redacted], and its Session start row names TMPDIR" "no README.md beside this engine"
fi
_dn_wait 20 '[ ! -d "$DNLOCK" ] && [ ! -d "$DNGL" ]'
[ "$_dnB" = "$TMP" ] || { _fx_root_del "$_dnB"; rm -rf "$_dnB"; }
