printf '\n%s\n' 'situations: the web fixture (blind)'
# Blind, written on 2026-10-31 from docs/2026-10-29-capability-lane-first-slices-design.md (sections 3, 4, 7, 10 and 11)
# and the slice 1 plan's Contracts (C1-C16) and Review Focus alone, with the shipped seed templates/situations.tsv as
# data, before lib/situations*.sh existed and without reading felix, lib/, hooks/ or bin/. C16's row for this part:
# section 7.9 (a), (f), (g), (h) and C11 (--propose), on the shipped seed.
#
# The fixture: home H holds project web1 (C6's own example name), whose probes.tsv has one row, http_route grounding
# api: an awk over the tracked app/main.py that enumerates @app.post( routes, with a wider witness (a .post( anywhere in
# that file). The checkout C holds requirements.txt naming fastapi and anthropic, so the detector names api and llm.
#   main:     A (no route) -> B (one POST route)
#   gone:     B -> D (the route deleted; requirements.txt still names fastapi)
#   renamed:  B -> E (app renamed api: the routes stay, the probe enumerates none, the witness still sees them: blind)
#   feature:  B -> C (an unrelated file), checked out last, so the default range is B..C
# Readings where the contracts leave room:
# - The admit command's \t and \n are the two characters backslash and t (and n), as shell text for printf to expand:
#   C11 calls it one line, so its \n cannot be a newline byte, and its row line is the one C11 says has real tabs. C17.1's
#   guard comes first in it (2026-11-05), its printf '\n' and its "$(tail -c 1 ...)" shell text in the same way.
# - The expected reports are built from a model of C4, C5, C7, C9 and C10 below, over the eight seed classes, so each
#   run's whole --tsv and human output is pinned. In --change the header's tree ids are pinned only for the default
#   range, whose two commits the part also records with felix probes (C3.3: the scratch tree id equals the recorded id
#   of a clean checkout of the same commit); other --change headers are matched by their fixed text.
# - "Writes nothing" (C11, C3.4) is the home, the memory root and the checkout's refs, index, config, worktree list,
#   status and HEAD, byte for byte; every such assertion carries the run's exit status, so it is red on main.

S2440_D="$(mkdir -p "$TMP/s2440" && cd -P "$TMP/s2440" && pwd -P)"
S2440_H="$S2440_D/home"; S2440_P="$S2440_H/projects/web1"; S2440_M="$S2440_D/memory"; S2440_C="$S2440_D/c"
S2440_SEED="$FROOT/harness/templates/situations.tsv"; S2440_T="$(printf '\t')"; S2440_NL=$'\n'
mkdir -p "$S2440_P" "$S2440_M/web1" "$S2440_D/m2/web1" "$S2440_C" "$S2440_D/bin"
S2440_C="$(cd -P "$S2440_C" && pwd -P)"
S2440_JSON='{"name":"web1","remote_match":"example.invalid/web1","gate":"true"}'
printf '%s\n' "$S2440_JSON" > "$S2440_P/project.json"
printf '# web1\n' > "$S2440_P/CLAUDE.md"
printf 'http_route\tapi\t-\t%s\t%s\n' "awk '/^@app[.]post[(]/' app/main.py" "grep -q '[.]post[(]' app/main.py" \
  > "$S2440_P/probes.tsv"
# The network stubs (C13): each appends its argv to net.log and exits 1.
for _s2440_n in gh curl wget ssh nc claude; do
  printf '#!/bin/sh\nprintf "%%s %%s\\n" %s "$*" >> %s\nexit 1\n' "$_s2440_n" "'$S2440_D/net.log'" > "$S2440_D/bin/$_s2440_n"
  chmod +x "$S2440_D/bin/$_s2440_n"
done

# EPOCH MESSAGE -> commits every change in C, dated EPOCH.
_s2440_commit() {
  ( export GIT_AUTHOR_DATE="$1 +0000" GIT_COMMITTER_DATE="$1 +0000"
    _fx_git "$S2440_C" add -A \
      && _fx_git "$S2440_C" -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "$2" )
}
_s2440_main() {   # ROUTE-LINE-OR-EMPTY APPNAME -> writes app/main.py
  { printf 'from fastapi import FastAPI\n%s = FastAPI()\n' "$2"
    [ -z "$1" ] || printf '\n%s\ndef chat(body: dict):\n    return body\n' "$1"; } > "$S2440_C/app/main.py"
}
( _fx_cd "$S2440_C" && git init -q -b main )
mkdir -p "$S2440_C/app"
printf 'web1\n' > "$S2440_C/.felix"
printf 'fastapi==0.115.0\nanthropic==0.39.0\n' > "$S2440_C/requirements.txt"
_s2440_main '' app; _s2440_commit 1793000000 'the app, no route'
S2440_A="$(_fx_git "$S2440_C" rev-parse HEAD)"
_s2440_main '@app.post("/chat")' app; _s2440_commit 1793000100 'one POST route'
S2440_B="$(_fx_git "$S2440_C" rev-parse HEAD)"

# NAME ARGS... -> felix ARGS in C, as C13's run, memory root S2440_MM, TMPDIR a fresh D/t-NAME: NAME.out, NAME.err,
# S2440_RC, and S2440_ALL0 turns no on any exit but 0.
S2440_MM="$S2440_M"; S2440_ALL0=yes
_s2440_run() {
  local n="$1" t="$S2440_D/t-$1"
  shift
  mkdir "$t" || { S2440_RC=fixture; S2440_ALL0=no; printf fixture > "$S2440_D/$n.rc"; return 0; }
  ( cd "$S2440_C" && env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GH_TOKEN -u GITHUB_TOKEN PATH="$S2440_D/bin:$PATH" \
      FELIX_HOME="$S2440_H" FELIX_MEMORY="$S2440_MM" TMPDIR="$t" "$FELIX" "$@" ) > "$S2440_D/$n.out" 2> "$S2440_D/$n.err"
  S2440_RC=$?
  printf '%s' "$S2440_RC" > "$S2440_D/$n.rc"
  [ "$S2440_RC" = 0 ] || S2440_ALL0=no
}
# NAME -> exit|stderr|what TMPDIR holds: 0|| for a clean run.
_s2440_clean() { printf '%s|%s|%s' "$(cat "$S2440_D/$1.rc")" "$(cat "$S2440_D/$1.err")" "$(ls -A "$S2440_D/t-$1")"; }
# The checkout's refs, HEAD, worktree list, config and index bytes, ls-files -s and status, then the facts.
_s2440_repo() {
  _fx_git "$S2440_C" for-each-ref; _fx_git "$S2440_C" symbolic-ref -q HEAD; _fx_git "$S2440_C" rev-parse HEAD
  _fx_git "$S2440_C" worktree list --porcelain
  cksum < "$S2440_C/.git/config"; cksum < "$S2440_C/.git/index"
  _fx_git "$S2440_C" ls-files -s; _fx_git "$S2440_C" --no-optional-locks status --porcelain
  cksum < "$S2440_M/web1/facts.log"
}
_s2440_tree() { ( cd "$1" && find . -type f -exec cksum {} + ) | LC_ALL=C sort; }   # DIR -> every file's bytes
_s2440_all() { _s2440_repo; _s2440_tree "$S2440_H"; _s2440_tree "$S2440_M"; }

# ---- the model: C4, C5, C7, C9, C10 over the eight seed classes, in byte order of name -----------------------------
S2440_CLS='ci_actions_pinned ci_secret_scoped_to_step container_runs_unprivileged health_reflects_readiness
local_listener_binds_loopback paid_ingress request_body_bounded route_has_http_test'
_s2440_id() { printf 'owed:%s' "$(printf '%s\t%s\t%s' "$1" web1 '*' | _fx_git "$S2440_D" hash-object --stdin | cut -c1-12)"; }
_s2440_owes() { LC_ALL=C awk -F'\t' -v c="$1" '$1 == c { print $3; exit }' "$S2440_SEED"; }
# CLASS K -> S2440_ST, S2440_GR (grounds) and S2440_RD (readings) at a side where http_route reads K (found, empty or
# blind); the detector names api and llm on every side, never tests, deploy or ci.
_s2440_cls() {
  local ai ar st
  ai="http_route $2 (api)"; ar="http_route=$2/0"; [ "$2" != found ] || ar='http_route=found/1'
  case "$2" in found) st=ACTIVE ;; empty) st=DORMANT ;; *) st=UNKNOWN ;; esac
  S2440_RD="$ar"
  case "$1" in
    paid_ingress)                  S2440_ST="$st"; S2440_GR="$ai, llm detected" ;;
    request_body_bounded)          S2440_ST="$st"; S2440_GR="$ai" ;;
    route_has_http_test)           S2440_GR="$ai, tests not detected" ;;
    health_reflects_readiness)     S2440_GR="$ai, deploy not detected" ;;
    local_listener_binds_loopback) S2440_GR='local_listener no probe'; S2440_RD=- ;;
    ci_actions_pinned)             S2440_GR='ci not detected'; S2440_RD=- ;;
    ci_secret_scoped_to_step)      S2440_GR='ci not detected, ci_secret no probe'; S2440_RD=- ;;
    container_runs_unprivileged)   S2440_GR='container no probe'; S2440_RD=- ;;
  esac
  case "$1" in
    route_has_http_test|health_reflects_readiness) S2440_ST=UNKNOWN; [ "$2" != empty ] || S2440_ST=DORMANT ;;
    paid_ingress|request_body_bounded) ;;
    *) S2440_ST=UNKNOWN ;;
  esac
}
# BASE HEAD -> the token (BASE - in --at); ACTIVE on both sides here always has equal readings.
_s2440_verdict() {
  case "$1:$2" in
    -:ACTIVE) printf standing ;; -:UNKNOWN) printf could-not-look ;; -:DORMANT) printf none ;;
    ACTIVE:ACTIVE) printf standing ;; *:ACTIVE) printf owed ;;
    UNKNOWN:UNKNOWN) printf could-not-look ;; *:UNKNOWN) printf blinded ;;
    ACTIVE:DORMANT) printf retired ;; *) printf none ;;
  esac
}
_s2440_rank() { case "$1" in owed) echo 1 ;; blinded) echo 2 ;; retired) echo 3 ;; standing) echo 4 ;; could-not-look) echo 5 ;; *) echo 6 ;; esac; }
# SIDE K -> C10's could-not-look lines for that side, unsorted.
_s2440_res() {
  local s="$1" c bl="http_route read blind: the witness says this surface exists and the probe enumerated none of it"
  printf 'residual\tcould-not-look\tci_actions_pinned\t%s: cap:ci: no probe grounds ci and the detector does not name it\n' "$s"
  printf 'residual\tcould-not-look\tci_secret_scoped_to_step\t%s: cap:ci: no probe grounds ci and the detector does not name it\n' "$s"
  printf 'residual\tcould-not-look\tci_secret_scoped_to_step\t%s: probe:ci_secret=found: no probe grounds ci_secret\n' "$s"
  printf 'residual\tcould-not-look\tcontainer_runs_unprivileged\t%s: probe:container=found: no probe grounds container\n' "$s"
  printf 'residual\tcould-not-look\tlocal_listener_binds_loopback\t%s: probe:local_listener=found: no probe grounds local_listener\n' "$s"
  [ "$2" != empty ] || return 0
  printf 'residual\tcould-not-look\thealth_reflects_readiness\t%s: cap:deploy: no probe grounds deploy and the detector does not name it\n' "$s"
  printf 'residual\tcould-not-look\troute_has_http_test\t%s: cap:tests: no probe grounds tests and the detector does not name it\n' "$s"
  [ "$2" = blind ] || return 0
  for c in health_reflects_readiness paid_ingress request_body_bounded route_has_http_test; do
    printf 'residual\tcould-not-look\t%s\t%s: cap:api: %s\n' "$c" "$s" "$bl"
  done
}
# BASEK HEADK -> the residual lines as --tsv prints them (BASEK - in --at, the side then at).
_s2440_resid() {
  { if [ "$1" = - ]; then _s2440_res at "$2"; else _s2440_res base "$1"; _s2440_res head "$2"; fi
    printf 'residual\tunbound\tprobe:%s=found\tno row of probes.tsv grounds %s\n' ci_secret ci_secret container container \
      local_listener local_listener; } | LC_ALL=C sort -u
}
# BASEK HEADK -> the whole --tsv output (C8).
_s2440_tsv() {
  local c bs bg hs hg v
  for c in $S2440_CLS; do
    bs=-; bg=-
    if [ "$1" != - ]; then _s2440_cls "$c" "$1"; bs="$S2440_ST"; bg="$S2440_GR"; fi
    _s2440_cls "$c" "$2"; hs="$S2440_ST"; hg="$S2440_GR"; v="$(_s2440_verdict "$bs" "$hs")"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$(_s2440_rank "$v")" "$(_s2440_id "$c")" "$c" "$v" "$bs" "$hs" "$bg" "$hg" \
      "$(_s2440_owes "$c")"
  done | LC_ALL=C sort -t "$S2440_T" -k1,1 -k2,2 | cut -f2-
  _s2440_resid "$1" "$2"
}
# BASEK HEADK HEADER... -> the whole human report (C9), the header lines given.
_s2440_human() {
  local b="$1" h="$2" sec c bs hs br hr bg hg v n a=0 d=0 u=0 secs='owed blinded retired standing'
  shift 2
  printf 'situations for web1\n'; [ "$#" -eq 0 ] || printf '%s\n' "$@"
  [ "$b" != - ] || secs=standing
  for sec in $secs; do
    printf '\n%s\n' "$sec"; n=0
    for c in $S2440_CLS; do
      bs=-; [ "$b" = - ] || { _s2440_cls "$c" "$b"; bs="$S2440_ST"; bg="$S2440_GR"; br="$S2440_RD"; }
      _s2440_cls "$c" "$h"; hs="$S2440_ST"; hg="$S2440_GR"; hr="$S2440_RD"
      v="$(_s2440_verdict "$bs" "$hs")"; [ "$v" = "$sec" ] || continue; n=$((n + 1))
      if [ "$b" = - ]; then
        printf '  %s  %s  ACTIVE\n    grounds  %s\n    readings  %s\n' "$(_s2440_id "$c")" "$c" "$hg" "$hr"
      else
        printf '  %s  %s  %s -> %s\n    grounds  base: %s; head: %s\n    readings  base: %s; head: %s\n' \
          "$(_s2440_id "$c")" "$c" "$bs" "$hs" "$bg" "$hg" "$br" "$hr"
        [ "$bs" != DORMANT ] || printf '    witness  base: http_route empty\n'
        [ "$hs" != DORMANT ] || printf '    witness  head: http_route empty\n'
      fi
      printf '    owes  %s\n' "$(_s2440_owes "$c")"
    done
    [ "$n" -gt 0 ] || printf '  none\n'
  done
  printf '\nresidual\n'
  _s2440_resid "$b" "$h" | while IFS="$S2440_T" read -r _ k nm w; do printf '  %s  %s  %s\n' "$k" "$nm" "$w"; done
  for c in $S2440_CLS; do
    _s2440_cls "$c" "$h"
    case "$S2440_ST" in ACTIVE) a=$((a + 1)) ;; DORMANT) d=$((d + 1)) ;; *) u=$((u + 1)) ;; esac
  done
  printf '\nexamined 8, active %s, dormant %s, could not look %s\n' "$a" "$d" "$u"
}
# CLASS MATURITY -> S2440_CW, S2440_CN: C11's class word and note (MATURITY empty when none is declared).
_s2440_cbm() {
  local cell w
  cell="$(LC_ALL=C awk -F'\t' -v c="$1" '$1 == c { print $4; exit }' "$S2440_SEED")"
  case "$2" in
    prototype|internal|public-beta|production)
      S2440_CW="$(printf '%s\n' "$cell" | tr ',' '\n' | LC_ALL=C awk -F= -v m="$2" '$1 == m { print $2 }')"
      S2440_CN="maturity $2" ;;
    *) S2440_CW=""
       for w in AUTHORITY_BLOCKING RELEASE_BLOCKING TASK_BLOCKING ADVISORY INFO; do
         case ",$cell," in *"=$w,"*) S2440_CW="$w"; break ;; esac
       done
       S2440_CN='maturity undeclared: the strictest class this row names'
       [ -z "$2" ] || S2440_CN="maturity '$2' is not one of prototype internal public-beta production: the strictest class this row names" ;;
  esac
}
# MATURITY CLASS... -> C11's section, for the CLASSes (each ACTIVE at head with http_route found, unadmitted).
S2440_FMT="printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n'"
S2440_SQ="'\\''"
# TEXT -> TEXT single-quoted for a shell, each ' written as '\'' (C11).
_s2440_q() { printf "'%s'" "${1//\'/$S2440_SQ}"; }
_s2440_proposed() {
  local m="$1" c g o q
  shift
  printf '\nproposed\n'
  [ "$#" -gt 0 ] || printf '  none\n'
  for c in "$@"; do
    _s2440_cls "$c" found; g="$S2440_GR"; o="$(_s2440_owes "$c")"; _s2440_cbm "$c" "$m"
    q="'$S2440_P/obligations.tsv'"
    printf '  %s  %s  %s\n    class  %s  %s\n' "$(_s2440_id "$c")" "$c" "$g" "$S2440_CW" "$S2440_CN"
    printf '    row  %s\t%s\tunknown\t-\texit 2\thttp_route\t%s\n' "$c" "$S2440_CW" "$o"
    printf '    admit  %s\n' "{ [ ! -s $q ] || [ -z \"\$(tail -c 1 $q)\" ] || printf '\\n'; } >> $q && $S2440_FMT '$c' '$S2440_CW' 'unknown' '-' 'exit 2' 'http_route' $(_s2440_q "$o") >> $q && git -C '$S2440_H' add -- $q && git -C '$S2440_H' commit -q -m 'obligations: admit $c' -- $q"
  done
}

# ---- (a) at a recorded tree: paid ingress ACTIVE, its grounds, and --propose -----------------------------------------
_s2440_run probes1 probes; S2440_PRC="$S2440_RC"
S2440_STAMP="$(LC_ALL=C awk -F'\t' 'NF >= 8 { s = $1 } END { print s }' "$S2440_M/web1/facts.log" 2>/dev/null)"
S2440_TB="$(LC_ALL=C awk -F'\t' 'NF >= 8 { s = $2 } END { print s }' "$S2440_M/web1/facts.log" 2>/dev/null)"
S2440_HAT="  at  $S2440_B  tree $S2440_TB  recorded $S2440_STAMP  detector run on this checkout"
S2440_PI="$(_s2440_id paid_ingress)"; S2440_PIO="$(_s2440_owes paid_ingress)"
_s2440_run at-tsv situations --tsv
is '2440 a: at the recorded tree the --tsv line of paid_ingress is standing, ACTIVE, grounds exactly http_route found (api), llm detected' \
   "$S2440_PRC|$S2440_RC|$(LC_ALL=C awk -F'\t' '$2 == "paid_ingress"' "$S2440_D/at-tsv.out")" \
   "0|0|$S2440_PI${S2440_T}paid_ingress${S2440_T}standing$S2440_T-${S2440_T}ACTIVE$S2440_T-${S2440_T}http_route found (api), llm detected$S2440_T$S2440_PIO"
is '2440 a: at the recorded tree the whole --tsv output is the model of C4, C7, C8 and C10 over the seed' \
   "$S2440_RC|$(cat "$S2440_D/at-tsv.out")" "0|$(_s2440_tsv - found)"
is '2440 a: the --at --tsv run exits 0 with stderr empty and TMPDIR left empty' "$(_s2440_clean at-tsv)" '0||'
_s2440_run at-human situations
is '2440 a: at the recorded tree the human report is the header with the detector run, paid_ingress and request_body_bounded standing, the residual and the count' \
   "$S2440_RC|$(cat "$S2440_D/at-human.out")" "0|$(_s2440_human - found "$S2440_HAT")"
has '2440 a: the human report prints paid_ingress'\''s grounds line whole' "$S2440_RC|$(cat "$S2440_D/at-human.out")" \
    "$(printf '\n    grounds  http_route found (api), llm detected\n')$S2440_NL"
is '2440 a: the --at human run exits 0 with stderr empty and TMPDIR left empty' "$(_s2440_clean at-human)" '0||'
S2440_BEFORE="$(_s2440_all)"
_s2440_run at-prop situations --propose
S2440_AFTER="$(_s2440_all)"
is '2440 c11: --propose at the recorded tree prints the human report, one blank line, then proposed with paid_ingress and request_body_bounded' \
   "$S2440_RC|$(cat "$S2440_D/at-prop.out")" "0|$(_s2440_human - found "$S2440_HAT"; _s2440_proposed '' paid_ingress request_body_bounded)"
has '2440 c11: the row line of paid_ingress has its seven cells joined by real tab bytes' "$S2440_RC|$(cat "$S2440_D/at-prop.out")" \
    "$(printf '\n    row  paid_ingress\tRELEASE_BLOCKING\tunknown\t-\texit 2\thttp_route\t%s\n' "$S2440_PIO")$S2440_NL"
has '2440 c11: the class line of paid_ingress names its strictest class while no maturity is declared' "$S2440_RC|$(cat "$S2440_D/at-prop.out")" \
    "$(printf '\n    class  RELEASE_BLOCKING  maturity undeclared: the strictest class this row names\n')$S2440_NL"
has '2440 c11: the admit line of paid_ingress is the exact command, quoted, with FELIX_HOME as given' "$S2440_RC|$(cat "$S2440_D/at-prop.out")" \
    "$(printf '\n    admit  %s' "{ [ ! -s '$S2440_H/projects/web1/obligations.tsv' ] || [ -z \"\$(tail -c 1 '$S2440_H/projects/web1/obligations.tsv')\" ] || printf '\\n'; } >> '$S2440_H/projects/web1/obligations.tsv' && printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' 'paid_ingress' 'RELEASE_BLOCKING' 'unknown' '-' 'exit 2' 'http_route' $(_s2440_q "$S2440_PIO") >> '$S2440_H/projects/web1/obligations.tsv' && git -C '$S2440_H' add -- '$S2440_H/projects/web1/obligations.tsv' && git -C '$S2440_H' commit -q -m 'obligations: admit paid_ingress' -- '$S2440_H/projects/web1/obligations.tsv'")$S2440_NL"
has "2440 c11: the apostrophe in the owes of paid_ingress is closed, escaped and reopened inside the admit command" \
    "$S2440_RC|$(LC_ALL=C awk '/^    admit  / { print; exit }' "$S2440_D/at-prop.out")" " 'exit 2' 'http_route' 'a request bound and a spend bound on every entrypoint that can reach a paid model call: a limit on each request'\\''s size and rate, "
is '2440 c11: --propose wrote nothing: the home, the memory root and the checkout are byte for byte as before' \
   "$S2440_RC|$S2440_AFTER" "0|$S2440_BEFORE"
is '2440 c11: the --propose run exits 0 with stderr empty and TMPDIR left empty' "$(_s2440_clean at-prop)" '0||'

# ---- the branches: D deletes the route, E renames what the probe keys on, C changes nothing a probe reads -------------
_fx_git "$S2440_C" checkout -q -b gone
_s2440_main '' app; _s2440_commit 1793000200 'the route deleted'
S2440_DD="$(_fx_git "$S2440_C" rev-parse HEAD)"
_fx_git "$S2440_C" checkout -q main && _fx_git "$S2440_C" checkout -q -b renamed
_s2440_main '@api.post("/chat")' api; _s2440_commit 1793000300 'the app renamed api'
S2440_E="$(_fx_git "$S2440_C" rev-parse HEAD)"
_fx_git "$S2440_C" checkout -q main && _fx_git "$S2440_C" checkout -q -b feature
printf 'Notes on the chat service.\n' > "$S2440_C/NOTES.txt"; _s2440_commit 1793000400 'notes'
S2440_CC="$(_fx_git "$S2440_C" rev-parse HEAD)"
# C's recorded tree id, in a memory root of its own (C3.3: the scratch id of a clean checkout of C equals it).
S2440_MM="$S2440_D/m2"; _s2440_run probes2 probes; S2440_MM="$S2440_M"
S2440_TC="$(LC_ALL=C awk -F'\t' 'NF >= 8 { s = $2 } END { print s }' "$S2440_D/m2/web1/facts.log" 2>/dev/null)"
S2440_SCR='  scratch checkout, tracked content only, current probes.tsv'
# NAME BASE HEAD -> the human report of NAME, its header lines matched by their fixed text and then dropped.
_s2440_hdr() {
  local o="$S2440_D/$1.out" l2 l3
  l2="$(LC_ALL=C awk 'NR == 2' "$o")"; l3="$(LC_ALL=C awk 'NR == 3' "$o")"
  case "$l2" in "  base  $2  tree "?*"$S2440_SCR") l2=ok ;; esac
  case "$l3" in "  head  $3  tree "?*"$S2440_SCR") l3=ok ;; esac
  printf '%s|%s|' "$l2" "$l3"; LC_ALL=C awk 'NR != 2 && NR != 3' "$o"
}

# ---- (f) a route added in the diff is owed by that change ------------------------------------------------------------
_s2440_run f-tsv situations --change "$S2440_A..$S2440_B" --tsv
is '2440 f: a route added in the diff makes paid_ingress owed, DORMANT -> ACTIVE, with both sides'\'' grounds' \
   "$S2440_RC|$(LC_ALL=C awk -F'\t' '$2 == "paid_ingress"' "$S2440_D/f-tsv.out")" \
   "0|$S2440_PI${S2440_T}paid_ingress${S2440_T}owed${S2440_T}DORMANT${S2440_T}ACTIVE${S2440_T}http_route empty (api), llm detected${S2440_T}http_route found (api), llm detected$S2440_T$S2440_PIO"
is '2440 f: the whole --tsv output of A..B is the model: two owed, two blinded by an undecided tests or deploy term, the rest could-not-look' \
   "$S2440_RC|$(cat "$S2440_D/f-tsv.out")" "0|$(_s2440_tsv empty found)"
is '2440 f: the A..B --tsv run exits 0 with stderr empty and TMPDIR left empty' "$(_s2440_clean f-tsv)" '0||'
_s2440_run f-human situations --change "$S2440_A..$S2440_B"
is '2440 f: the human report of A..B: its header by its fixed text, then owed with a base witness, blinded, retired none, standing none, residual, count' \
   "$S2440_RC|$(_s2440_hdr f-human "$S2440_A" "$S2440_B")" "0|ok|ok|$(_s2440_human empty found)"
has '2440 f: paid_ingress'\''s owed row names the base witness http_route empty' "$S2440_RC|$(cat "$S2440_D/f-human.out")" \
    "$(printf '\n  %s  paid_ingress  DORMANT -> ACTIVE\n    grounds  base: http_route empty (api), llm detected; head: http_route found (api), llm detected\n    readings  base: http_route=empty/0; head: http_route=found/1\n    witness  base: http_route empty\n' "$S2440_PI")$S2440_NL"

# ---- (a) deleting the route makes it DORMANT, its witness named, though requirements.txt still names fastapi ---------
S2440_REQ="$(_fx_git "$S2440_C" show "$S2440_DD:requirements.txt")"
_s2440_run a-tsv situations --change "$S2440_B..$S2440_DD" --tsv
is '2440 a: deleting the route retires paid_ingress, ACTIVE -> DORMANT, while requirements.txt at the head still names fastapi' \
   "$S2440_RC|$S2440_REQ|$(LC_ALL=C awk -F'\t' '$2 == "paid_ingress"' "$S2440_D/a-tsv.out")" \
   "0|fastapi==0.115.0
anthropic==0.39.0|$S2440_PI${S2440_T}paid_ingress${S2440_T}retired${S2440_T}ACTIVE${S2440_T}DORMANT${S2440_T}http_route found (api), llm detected${S2440_T}http_route empty (api), llm detected$S2440_T$S2440_PIO"
is '2440 a: the whole --tsv output of B..D is the model: two retired, the tests and deploy classes none, the rest could-not-look' \
   "$S2440_RC|$(cat "$S2440_D/a-tsv.out")" "0|$(_s2440_tsv found empty)"
is '2440 a: the B..D --tsv run exits 0 with stderr empty and TMPDIR left empty' "$(_s2440_clean a-tsv)" '0||'
_s2440_run a-human situations --change "$S2440_B..$S2440_DD"
is '2440 a: the human report of B..D: retired holds paid_ingress and request_body_bounded, each with a head witness' \
   "$S2440_RC|$(_s2440_hdr a-human "$S2440_B" "$S2440_DD")" "0|ok|ok|$(_s2440_human found empty)"
has '2440 a: paid_ingress'\''s retired row names the witness, the probe deciding over the detector'\''s api' \
    "$S2440_RC|$(cat "$S2440_D/a-human.out")" \
    "$(printf '\n  %s  paid_ingress  ACTIVE -> DORMANT\n    grounds  base: http_route found (api), llm detected; head: http_route empty (api), llm detected\n    readings  base: http_route=found/1; head: http_route=empty/0\n    witness  head: http_route empty\n    owes  %s\n' "$S2440_PI" "$S2440_PIO")$S2440_NL"
_s2440_run a-prop situations --change "$S2440_B..$S2440_DD" --propose
is '2440 c11: in --change proposals read the head side: with the route deleted at head, proposed prints none' \
   "$S2440_RC|$(LC_ALL=C awk 'p { print } /^examined / { p = 1 }' "$S2440_D/a-prop.out")" "0|$(_s2440_proposed '')"

# ---- (h) a diff that breaks the probe's instrument while the routes stay reads blinded, never DORMANT or retired ------
_s2440_run h-tsv situations --change "$S2440_B..$S2440_E" --tsv
is '2440 h: renaming what the probe keys on blinds paid_ingress, ACTIVE -> UNKNOWN, the blind probe deciding though the detector names api' \
   "$S2440_RC|$(LC_ALL=C awk -F'\t' '$2 == "paid_ingress"' "$S2440_D/h-tsv.out")" \
   "0|$S2440_PI${S2440_T}paid_ingress${S2440_T}blinded${S2440_T}ACTIVE${S2440_T}UNKNOWN${S2440_T}http_route found (api), llm detected${S2440_T}http_route blind (api), llm detected$S2440_T$S2440_PIO"
is '2440 h: no class of B..E reads DORMANT at head or retired' \
   "$S2440_RC|$(LC_ALL=C awk -F'\t' '$1 != "residual" && ($5 == "DORMANT" || $3 == "retired") { print $2 }' "$S2440_D/h-tsv.out")" '0|'
is '2440 h: the whole --tsv output of B..E is the model, the residual naming the probe'\''s own sentence for each api class at head' \
   "$S2440_RC|$(cat "$S2440_D/h-tsv.out")" "0|$(_s2440_tsv found blind)"
has '2440 h: the residual line for paid_ingress names cap:api and the blind probe'\''s sentence' "$S2440_RC|$(cat "$S2440_D/h-tsv.out")" \
    "$S2440_NL$(printf 'residual\tcould-not-look\tpaid_ingress\thead: cap:api: http_route read blind: the witness says this surface exists and the probe enumerated none of it\n')$S2440_NL"
is '2440 h: the B..E --tsv run exits 0 with stderr empty and TMPDIR left empty' "$(_s2440_clean h-tsv)" '0||'
_s2440_run h-human situations --change "$S2440_B..$S2440_E"
is '2440 h: the human report of B..E: blinded holds paid_ingress and request_body_bounded, retired none' \
   "$S2440_RC|$(_s2440_hdr h-human "$S2440_B" "$S2440_E")" "0|ok|ok|$(_s2440_human found blind)"

# ---- (g) an unrelated diff owes nothing, its ACTIVE rows stand, and the checkout and facts stay as they were ----------
S2440_HG="$(printf '  base  %s  tree %s%s\n  head  %s  tree %s%s' "$S2440_B" "$S2440_TB" "$S2440_SCR" "$S2440_CC" "$S2440_TC" "$S2440_SCR")"
S2440_BEFORE="$(_s2440_all)"
_s2440_run g-tsv situations --change --tsv
_s2440_run g-human situations --change
S2440_AFTER="$(_s2440_all)"
is '2440 g: the default range B..C owes no row, blinds and retires none' \
   "$S2440_RC|$(LC_ALL=C awk -F'\t' '$1 != "residual" && ($3 == "owed" || $3 == "blinded" || $3 == "retired") { print $2 }' "$S2440_D/g-tsv.out")" '0|'
is '2440 g: the default range prints paid_ingress and request_body_bounded as standing, and no other class' \
   "$S2440_RC|$(LC_ALL=C awk -F'\t' '$1 != "residual" && $3 == "standing" { print $2 }' "$S2440_D/g-tsv.out" | LC_ALL=C sort | tr '\n' ' ')" \
   '0|paid_ingress request_body_bounded '
is '2440 g: the whole --tsv output of the default range is the model' "$S2440_RC|$(cat "$S2440_D/g-tsv.out")" "0|$(_s2440_tsv found found)"
is '2440 g: the human report of the default range: both headers with their tree ids, owed, blinded and retired none, two standing' \
   "$S2440_RC|$(cat "$S2440_D/g-human.out")" "0|$(_s2440_human found found "$S2440_HG")"
is '2440 g: after both runs the refs, HEAD, worktree list, config, index, status, facts.log, home and memory root are byte-identical' \
   "$S2440_RC|$S2440_AFTER" "0|$S2440_BEFORE"
_s2440_run g2-tsv situations --change "$S2440_B..$S2440_CC" --tsv
is '2440 g: the explicit range B..C prints the same --tsv bytes as the default range' \
   "$S2440_RC|$(cat "$S2440_D/g2-tsv.out")" \
   "0|$(cat "$S2440_D/g-tsv.out")"
is '2440 g: the default-range runs exit 0 with stderr empty and TMPDIR left empty' \
   "$(_s2440_clean g-tsv)|$(_s2440_clean g-human)" '0|||0||'

# ---- C11 in --change: the head side, an admitted class, and the class and note by maturity ----------------------------
S2440_BEFORE="$(_s2440_all)"
_s2440_run g-prop situations --change --propose
S2440_AFTER="$(_s2440_all)"
is '2440 c11: --change --propose prints the report then the head side'\''s two proposals, undeclared maturity' \
   "$S2440_RC|$(cat "$S2440_D/g-prop.out")" "0|$(_s2440_human found found "$S2440_HG"; _s2440_proposed '' paid_ingress request_body_bounded)"
is '2440 c11: --change --propose wrote nothing' "$S2440_RC|$S2440_AFTER" "0|$S2440_BEFORE"
printf 'paid_ingress\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\tadmitted by hand for this fixture\n' > "$S2440_P/obligations.tsv"
_s2440_run adm-prop situations --change --propose
is '2440 c11: a class the project'\''s obligations.tsv admits by name is not proposed; the other still is' \
   "$S2440_RC|$(LC_ALL=C awk 'p { print } /^examined / { p = 1 }' "$S2440_D/adm-prop.out")" "0|$(_s2440_proposed '' request_body_bounded)"
rm -f "$S2440_P/obligations.tsv"
printf '%s\n' '{"name":"web1","remote_match":"example.invalid/web1","gate":"true","maturity":"internal"}' > "$S2440_P/project.json"
_s2440_run int-prop situations --change --propose
is '2440 c11: with maturity internal each proposal carries the class class_by_maturity pairs with internal, noted maturity internal' \
   "$S2440_RC|$(LC_ALL=C awk 'p { print } /^examined / { p = 1 }' "$S2440_D/int-prop.out")" \
   "0|$(_s2440_proposed internal paid_ingress request_body_bounded)"
has '2440 c11: paid_ingress at internal is TASK_BLOCKING, in its class line and its row line' "$S2440_RC|$(cat "$S2440_D/int-prop.out")" \
    "$S2440_NL$(printf '    class  TASK_BLOCKING  maturity internal\n    row  paid_ingress\tTASK_BLOCKING\tunknown\t')"
printf '%s\n' '{"name":"web1","remote_match":"example.invalid/web1","gate":"true","maturity":"staging"}' > "$S2440_P/project.json"
_s2440_run bad-prop situations --change --propose
is '2440 c11: a maturity outside the four gives the strictest class, noted as not one of them' \
   "$S2440_RC|$(LC_ALL=C awk 'p { print } /^examined / { p = 1 }' "$S2440_D/bad-prop.out")" \
   "0|$(_s2440_proposed staging paid_ingress request_body_bounded)"
printf '%s\n' "$S2440_JSON" > "$S2440_P/project.json"
is '2440 c11: the --change --propose runs exit 0 with stderr empty and TMPDIR left empty' \
   "$(_s2440_clean g-prop)|$(_s2440_clean adm-prop)|$(_s2440_clean int-prop)|$(_s2440_clean bad-prop)|$(_s2440_clean a-prop)" \
   '0|||0|||0|||0|||0||'

# ---- C13: no network, no key ------------------------------------------------------------------------------------------
is '2440 every felix situations run here exited 0 and none started gh, curl, wget, ssh, nc or claude' \
   "$S2440_ALL0|$(cat "$S2440_D/net.log" 2>/dev/null)" 'yes|'
