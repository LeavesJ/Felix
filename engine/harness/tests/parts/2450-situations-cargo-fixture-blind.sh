printf '\n%s\n' 'situations: the cargo fixture (blind)'
# Blind, written on 2026-10-31 from docs/2026-10-29-capability-lane-first-slices-design.md (sections 3, 4, 7, 10 and 11)
# and the slice 1 plan's Contracts (C1-C16) and Review Focus alone, with the shipped seed templates/situations.tsv as
# data, before lib/situations*.sh existed and without reading felix, lib/, hooks/ or bin/. C16's row for this part:
# section 7.9 (b); falsifier 5 with its qualifier (design section 11 item 31: no other term false); the seed's R4 class,
# ci_actions_pinned, ACTIVE in the cargo workspace and retired with a witness over a commit that removes its surface.
#
# The fixture: home H holds project mesh2. The checkout is a cargo workspace whose root Cargo.toml names one member,
# node, whose own manifest depends on axum (the detector reads no member manifest, and axum is no token), and whose
# main.rs serves one route and binds 0.0.0.0, a node that serves a cluster on every interface. probes.tsv grounds every
# other term of the HTTP-keyed classes, each a shell command over tracked files with a witness:
#   workflows (ci)           ls -1 .github/workflows           the R4 class's surface, as C12's siblings ground it
#   model_client (llm)       the MODEL_ENDPOINT line of node/src/model.rs
#   http_tests (tests)       ls -1 node/tests                  (no root tests entry, so the detector is silent)
#   deploy_units (deploy)    ls -1 deploy                      (a deploy directory is no path the detector reads)
#   loopback_listeners (local_listener)   binds to 127.0.0.1 or localhost in main.rs: none, the witness agrees: empty
# and, from the middle of the part on, http_route (api), the route lines of main.rs. Commits:
#   main:   K1, the whole workspace (checked out throughout)
#   noci:   K1 -> K2, .github/workflows removed (C12: one cap: term's surface, its probe then empty)
#   nollm:  K1 -> K3, node/src/model.rs removed (llm false while api is still undecided: the qualifier)
# Readings where the contracts leave room:
# - "Could not look" is the state UNKNOWN: the --at verdict could-not-look, and in --change could-not-look on both sides.
# - "Adding a probe row that grounds api" is an edit to the home's probes.tsv, read once by felix probes into a memory
#   root of its own (so two runs in one second cannot share a stamp and tree) and once by --change.
# - The detector names rust and ci here, and rust is a capability no class uses: a no-row line, named by the detector.
# Every assertion carries the run's exit status, so each is red on main, where felix situations is an unknown command.

S2450_D="$(mkdir -p "$TMP/s2450" && cd -P "$TMP/s2450" && pwd -P)"
S2450_H="$S2450_D/home"; S2450_P="$S2450_H/projects/mesh2"; S2450_C="$S2450_D/c"
S2450_SEED="$FROOT/harness/templates/situations.tsv"; S2450_T="$(printf '\t')"; S2450_NL=$'\n'
mkdir -p "$S2450_P" "$S2450_D/m1/mesh2" "$S2450_D/m2/mesh2" "$S2450_C" "$S2450_D/bin"
S2450_C="$(cd -P "$S2450_C" && pwd -P)"
printf '%s\n' '{"name":"mesh2","remote_match":"example.invalid/mesh2","gate":"true"}' > "$S2450_P/project.json"
printf '# mesh2\n' > "$S2450_P/CLAUDE.md"
{ printf 'workflows\tci\t-\tls -1 .github/workflows\ttest -d .github/workflows\n'
  printf 'model_client\tllm\t-\t%s\t%s\n' "awk '/MODEL_ENDPOINT/' node/src/model.rs" 'test -f node/src/model.rs'
  printf 'http_tests\ttests\t-\tls -1 node/tests\ttest -d node/tests\n'
  printf 'deploy_units\tdeploy\t-\tls -1 deploy\ttest -d deploy\n'
  printf 'loopback_listeners\tlocal_listener\t-\t%s\t%s\n' "awk '/bind[(]\"(127[.]0[.]0[.]1|localhost)/' node/src/main.rs" \
    "grep -qE 'bind[(]\"(127[.]0[.]0[.]1|localhost)' node/src/main.rs"
} > "$S2450_P/probes.tsv"
S2450_APIROW="$(printf 'http_route\tapi\t-\t%s\t%s' "awk '/[.]route[(]/' node/src/main.rs" "grep -q 'Router::new' node/src/main.rs")"
for _s2450_n in gh curl wget ssh nc claude; do
  printf '#!/bin/sh\nprintf "%%s %%s\\n" %s "$*" >> %s\nexit 1\n' "$_s2450_n" "'$S2450_D/net.log'" > "$S2450_D/bin/$_s2450_n"
  chmod +x "$S2450_D/bin/$_s2450_n"
done

_s2450_commit() {   # EPOCH MESSAGE -> commits every change in C, dated EPOCH
  ( export GIT_AUTHOR_DATE="$1 +0000" GIT_COMMITTER_DATE="$1 +0000"
    _fx_git "$S2450_C" add -A \
      && _fx_git "$S2450_C" -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "$2" )
}
( _fx_cd "$S2450_C" && git init -q -b main )
mkdir -p "$S2450_C/node/src" "$S2450_C/node/tests" "$S2450_C/deploy" "$S2450_C/.github/workflows"
printf 'mesh2\n' > "$S2450_C/.felix"
printf '[workspace]\nmembers = ["node"]\nresolver = "2"\n' > "$S2450_C/Cargo.toml"
printf '[package]\nname = "node"\nversion = "0.1.0"\nedition = "2021"\n\n[dependencies]\naxum = "0.7"\ntokio = { version = "1", features = ["full"] }\n' \
  > "$S2450_C/node/Cargo.toml"
{ printf 'use axum::{routing::post, Router};\n\nmod model;\n\nasync fn ingest() -> &%sstatic str {\n    "ok"\n}\n\n' "'"
  printf '#[tokio::main]\nasync fn main() {\n    let app = Router::new().route("/ingest", post(ingest));\n'
  printf '    let listener = tokio::net::TcpListener::bind("0.0.0.0:7000").await.unwrap();\n    axum::serve(listener, app).await.unwrap();\n}\n'
} > "$S2450_C/node/src/main.rs"
printf 'pub const MODEL_ENDPOINT: &str = "https://models.example.invalid/v1/messages";\n' > "$S2450_C/node/src/model.rs"
printf '#[test]\nfn ingest_answers() {}\n' > "$S2450_C/node/tests/http.rs"
printf '[Unit]\nDescription=node\n\n[Service]\nExecStart=/usr/local/bin/node\n' > "$S2450_C/deploy/node.service"
printf 'on: push\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - run: cargo test\n' \
  > "$S2450_C/.github/workflows/ci.yml"
_s2450_commit 1793100000 'the workspace'
S2450_K1="$(_fx_git "$S2450_C" rev-parse HEAD)"
_fx_git "$S2450_C" checkout -q -b noci && _fx_git "$S2450_C" rm -q -r .github
_s2450_commit 1793100100 'no CI workflow'
S2450_K2="$(_fx_git "$S2450_C" rev-parse HEAD)"
_fx_git "$S2450_C" checkout -q main && _fx_git "$S2450_C" checkout -q -b nollm && _fx_git "$S2450_C" rm -q node/src/model.rs
_s2450_commit 1793100200 'no model client'
S2450_K3="$(_fx_git "$S2450_C" rev-parse HEAD)"
_fx_git "$S2450_C" checkout -q main

# NAME MEMORY ARGS... -> felix ARGS in C as C13's run, TMPDIR a fresh D/t-NAME: NAME.out, NAME.err, NAME.rc, S2450_RC.
S2450_ALL0=yes
_s2450_run() {
  local n="$1" m="$2" t="$S2450_D/t-$1"
  shift 2
  mkdir "$t" || { S2450_RC=fixture; S2450_ALL0=no; printf fixture > "$S2450_D/$n.rc"; return 0; }
  ( cd "$S2450_C" && env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GH_TOKEN -u GITHUB_TOKEN PATH="$S2450_D/bin:$PATH" \
      FELIX_HOME="$S2450_H" FELIX_MEMORY="$m" TMPDIR="$t" "$FELIX" "$@" ) > "$S2450_D/$n.out" 2> "$S2450_D/$n.err"
  S2450_RC=$?
  printf '%s' "$S2450_RC" > "$S2450_D/$n.rc"
  [ "$S2450_RC" = 0 ] || S2450_ALL0=no
}
_s2450_clean() { printf '%s|%s|%s' "$(cat "$S2450_D/$1.rc")" "$(cat "$S2450_D/$1.err")" "$(ls -A "$S2450_D/t-$1")"; }
_s2450_class() { LC_ALL=C awk -F'\t' -v c="$1" '$1 != "residual" && $2 == c' "$S2450_D/$2.out"; }   # CLASS NAME -> its line

# ---- the model: C4, C5, C7, C10 over the eight seed classes ------------------------------------------------------------
# A side is API:CI:LLM, each yes or no: whether probes.tsv has the http_route row, and whether the tree holds the
# workflow and the model client.
S2450_CLS='ci_actions_pinned ci_secret_scoped_to_step container_runs_unprivileged health_reflects_readiness
local_listener_binds_loopback paid_ingress request_body_bounded route_has_http_test'
_s2450_id() { printf 'owed:%s' "$(printf '%s\t%s\t%s' "$1" mesh2 '*' | _fx_git "$S2450_D" hash-object --stdin | cut -c1-12)"; }
_s2450_owes() { LC_ALL=C awk -F'\t' -v c="$1" '$1 == c { print $3; exit }' "$S2450_SEED"; }
_s2450_terms() {
  case "$1" in
    paid_ingress) echo api llm ;; route_has_http_test) echo api tests ;; request_body_bounded) echo api ;;
    health_reflects_readiness) echo api deploy ;; local_listener_binds_loopback) echo ll ;; ci_actions_pinned) echo ci ;;
    ci_secret_scoped_to_step) echo ci secret ;; container_runs_unprivileged) echo container ;;
  esac
}
# TERM SIDE -> S2450_V (T, F or U), S2450_G (its grounds item), S2450_R (its readings item), S2450_W (its witness),
# S2450_X (the term as written).
_s2450_term() {
  local api="${2%%:*}" rest="${2#*:}" ci llm
  ci="${rest%%:*}"; llm="${rest#*:}"; S2450_R=""; S2450_W=""
  case "$1" in
    api) S2450_X=cap:api
         if [ "$api" = yes ]; then S2450_V=T; S2450_G='http_route found (api)'; S2450_R='http_route=found/1'
         else S2450_V=U; S2450_G='api not detected'; fi ;;
    llm) S2450_X=cap:llm
         if [ "$llm" = yes ]; then S2450_V=T; S2450_G='model_client found (llm)'; S2450_R='model_client=found/1'
         else S2450_V=F; S2450_G='model_client empty (llm)'; S2450_R='model_client=empty/0'; S2450_W='model_client empty'; fi ;;
    tests) S2450_X=cap:tests; S2450_V=T; S2450_G='http_tests found (tests)'; S2450_R='http_tests=found/1' ;;
    deploy) S2450_X=cap:deploy; S2450_V=T; S2450_G='deploy_units found (deploy)'; S2450_R='deploy_units=found/1' ;;
    ci) S2450_X=cap:ci
        if [ "$ci" = yes ]; then S2450_V=T; S2450_G='workflows found (ci)'; S2450_R='workflows=found/1'
        else S2450_V=F; S2450_G='workflows empty (ci)'; S2450_R='workflows=empty/0'; S2450_W='workflows empty'; fi ;;
    ll) S2450_X=probe:local_listener=found; S2450_V=F; S2450_G='loopback_listeners empty (local_listener)'
        S2450_R='loopback_listeners=empty/0'; S2450_W='loopback_listeners empty' ;;
    secret) S2450_X=probe:ci_secret=found; S2450_V=U; S2450_G='ci_secret no probe' ;;
    container) S2450_X=probe:container=found; S2450_V=U; S2450_G='container no probe' ;;
  esac
}
# CLASS SIDE -> S2450_ST, S2450_GR, S2450_RD, S2450_WI (the first false term's witness)
_s2450_cls() {
  local t f="" u="" g="" r="" w=""
  for t in $(_s2450_terms "$1"); do
    _s2450_term "$t" "$2"
    g="${g:+$g, }$S2450_G"; [ -z "$S2450_R" ] || r="${r:+$r }$S2450_R"
    case "$S2450_V" in F) [ -n "$f" ] || w="$S2450_W"; f=1 ;; U) u=1 ;; esac
  done
  S2450_ST=ACTIVE; [ -z "$u" ] || S2450_ST=UNKNOWN; [ -z "$f" ] || S2450_ST=DORMANT
  S2450_GR="$g"; S2450_RD="${r:--}"; S2450_WI="$w"
}
# CLASS SIDE -> C10's could-not-look lines for the class at SIDE named SIDENAME (third argument), when it is UNKNOWN.
_s2450_cnl() {
  local t
  _s2450_cls "$1" "$2"; [ "$S2450_ST" = UNKNOWN ] || return 0
  for t in $(_s2450_terms "$1"); do
    _s2450_term "$t" "$2"; [ "$S2450_V" = U ] || continue
    case "$t" in
      api) printf 'residual\tcould-not-look\t%s\t%s: cap:api: no probe grounds api and the detector does not name it\n' "$1" "$3" ;;
      secret) printf 'residual\tcould-not-look\t%s\t%s: probe:ci_secret=found: no probe grounds ci_secret\n' "$1" "$3" ;;
      container) printf 'residual\tcould-not-look\t%s\t%s: probe:container=found: no probe grounds container\n' "$1" "$3" ;;
    esac
  done
}
_s2450_verdict() {   # BASE HEAD BASE-READINGS HEAD-READINGS -> the token (BASE - in --at)
  case "$1:$2" in
    -:ACTIVE) printf standing ;; -:UNKNOWN) printf could-not-look ;; -:DORMANT) printf none ;;
    ACTIVE:ACTIVE) if [ "$3" = "$4" ]; then printf standing; else printf owed; fi ;; *:ACTIVE) printf owed ;;
    UNKNOWN:UNKNOWN) printf could-not-look ;; *:UNKNOWN) printf blinded ;;
    ACTIVE:DORMANT) printf retired ;; *) printf none ;;
  esac
}
_s2450_rank() { case "$1" in owed) echo 1 ;; blinded) echo 2 ;; retired) echo 3 ;; standing) echo 4 ;; could-not-look) echo 5 ;; *) echo 6 ;; esac; }
_s2450_resid() {   # BASESIDE HEADSIDE -> the residual lines (BASESIDE - in --at)
  local c
  { for c in $S2450_CLS; do
      if [ "$1" = - ]; then _s2450_cnl "$c" "$2" at; else _s2450_cnl "$c" "$1" base; _s2450_cnl "$c" "$2" head; fi
    done
    printf 'residual\tno-row\trust\tnamed by the detector\n'
    printf 'residual\tunbound\tprobe:%s=found\tno row of probes.tsv grounds %s\n' ci_secret ci_secret container container
  } | LC_ALL=C sort -u
}
_s2450_tsv() {   # BASESIDE HEADSIDE -> the whole --tsv output (C8)
  local c bs bg br hs hg v
  for c in $S2450_CLS; do
    bs=-; bg=-; br=-
    if [ "$1" != - ]; then _s2450_cls "$c" "$1"; bs="$S2450_ST"; bg="$S2450_GR"; br="$S2450_RD"; fi
    _s2450_cls "$c" "$2"; hs="$S2450_ST"; hg="$S2450_GR"; v="$(_s2450_verdict "$bs" "$hs" "$br" "$S2450_RD")"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$(_s2450_rank "$v")" "$(_s2450_id "$c")" "$c" "$v" "$bs" "$hs" "$bg" "$hg" \
      "$(_s2450_owes "$c")"
  done | LC_ALL=C sort -t "$S2450_T" -k1,1 -k2,2 | cut -f2-
  _s2450_resid "$1" "$2"
}
_s2450_at() {   # SIDE HEADER -> the whole human report in --at (C9)
  local c n=0 a=0 d=0 u=0
  printf 'situations for mesh2\n%s\n\nstanding\n' "$2"
  for c in $S2450_CLS; do
    _s2450_cls "$c" "$1"
    case "$S2450_ST" in ACTIVE) a=$((a + 1)) ;; DORMANT) d=$((d + 1)); continue ;; *) u=$((u + 1)); continue ;; esac
    n=$((n + 1))
    printf '  %s  %s  ACTIVE\n    grounds  %s\n    readings  %s\n    owes  %s\n' "$(_s2450_id "$c")" "$c" "$S2450_GR" "$S2450_RD" \
      "$(_s2450_owes "$c")"
  done
  [ "$n" -gt 0 ] || printf '  none\n'
  printf '\nresidual\n'
  _s2450_resid - "$1" | while IFS="$S2450_T" read -r _ k nm w; do printf '  %s  %s  %s\n' "$k" "$nm" "$w"; done
  printf '\nexamined 8, active %s, dormant %s, could not look %s\n' "$a" "$d" "$u"
}
# NAME CLASS... -> CLASS=STATE for each CLASS, from NAME's --tsv head column, in the order given.
_s2450_states() {
  local n="$1" c
  shift
  for c in "$@"; do printf '%s=%s ' "$c" "$(_s2450_class "$c" "$n" | cut -f5)"; done
}
S2450_HTTP='health_reflects_readiness paid_ingress request_body_bounded route_has_http_test'

# ---- (b) no probe grounds api: every HTTP-keyed class could not look, never DORMANT -------------------------------------
_s2450_run probes1 "$S2450_D/m1" probes
S2450_STAMP1="$(LC_ALL=C awk -F'\t' 'NF >= 8 { s = $1 } END { print s }' "$S2450_D/m1/mesh2/facts.log" 2>/dev/null)"
S2450_TID="$(LC_ALL=C awk -F'\t' 'NF >= 8 { s = $2 } END { print s }' "$S2450_D/m1/mesh2/facts.log" 2>/dev/null)"
_s2450_run b-tsv "$S2450_D/m1" situations --tsv
is '2450 b: with no probe grounding api, the four HTTP-keyed classes read UNKNOWN at the recorded tree, none DORMANT' \
   "$(cat "$S2450_D/probes1.rc")|$S2450_RC|$(_s2450_states b-tsv $S2450_HTTP)" \
   '0|0|health_reflects_readiness=UNKNOWN paid_ingress=UNKNOWN request_body_bounded=UNKNOWN route_has_http_test=UNKNOWN '
is '2450 b: paid_ingress reads could-not-look, its grounds naming api not detected beside the true llm term' \
   "$S2450_RC|$(_s2450_class paid_ingress b-tsv)" \
   "0|$(_s2450_id paid_ingress)${S2450_T}paid_ingress${S2450_T}could-not-look$S2450_T-${S2450_T}UNKNOWN$S2450_T-${S2450_T}api not detected, model_client found (llm)$S2450_T$(_s2450_owes paid_ingress)"
has '2450 b: the residual says why for paid_ingress: no probe grounds api and the detector does not name it' \
    "$S2450_RC|$(cat "$S2450_D/b-tsv.out")" \
    "${S2450_NL}residual${S2450_T}could-not-look${S2450_T}paid_ingress${S2450_T}at: cap:api: no probe grounds api and the detector does not name it$S2450_NL"
is '2450 b: the whole --tsv output at the recorded tree is the model: ci_actions_pinned standing, the loopback class none, the rest could-not-look' \
   "$S2450_RC|$(cat "$S2450_D/b-tsv.out")" "0|$(_s2450_tsv - no:yes:yes)"
is '2450 b: the --tsv run exits 0 with stderr empty and TMPDIR left empty' "$(_s2450_clean b-tsv)" '0||'
_s2450_run b-human "$S2450_D/m1" situations
is '2450 b: the human report at the recorded tree: the detector run, ci_actions_pinned the one standing row, the residual, the count' \
   "$S2450_RC|$(cat "$S2450_D/b-human.out")" \
   "0|$(_s2450_at no:yes:yes "  at  $S2450_K1  tree $S2450_TID  recorded $S2450_STAMP1  detector run on this checkout")"
has '2450 b: the count line says 1 active, 1 dormant and 6 could not look' "$S2450_RC|$(cat "$S2450_D/b-human.out")" \
    "${S2450_NL}examined 8, active 1, dormant 1, could not look 6"

# ---- the node binds every interface: no loopback-binding class activates ------------------------------------------------
is '2450 b: in a node that binds every interface local_listener_binds_loopback is DORMANT, verdict none, on the empty loopback probe' \
   "$S2450_RC|$(_s2450_class local_listener_binds_loopback b-tsv)" \
   "0|$(_s2450_id local_listener_binds_loopback)${S2450_T}local_listener_binds_loopback${S2450_T}none$S2450_T-${S2450_T}DORMANT$S2450_T-${S2450_T}loopback_listeners empty (local_listener)$S2450_T$(_s2450_owes local_listener_binds_loopback)"

# ---- the R4 class: ACTIVE in the workspace, retired over a commit that removes the workflow, with a witness ------------
is '2450 r4: ci_actions_pinned reads standing, ACTIVE, at the recorded tree, grounded by the workflows probe' \
   "$S2450_RC|$(_s2450_class ci_actions_pinned b-tsv)" \
   "0|$(_s2450_id ci_actions_pinned)${S2450_T}ci_actions_pinned${S2450_T}standing$S2450_T-${S2450_T}ACTIVE$S2450_T-${S2450_T}workflows found (ci)$S2450_T$(_s2450_owes ci_actions_pinned)"
_s2450_run r4-tsv "$S2450_D/m1" situations --change "$S2450_K1..$S2450_K2" --tsv
is '2450 r4: --change K1..K2, which removes the workflow, reads ci_actions_pinned retired, ACTIVE -> DORMANT' \
   "$S2450_RC|$(_s2450_class ci_actions_pinned r4-tsv)" \
   "0|$(_s2450_id ci_actions_pinned)${S2450_T}ci_actions_pinned${S2450_T}retired${S2450_T}ACTIVE${S2450_T}DORMANT${S2450_T}workflows found (ci)${S2450_T}workflows empty (ci)$S2450_T$(_s2450_owes ci_actions_pinned)"
is '2450 b: over K1..K2 the four HTTP-keyed classes read UNKNOWN on both sides, could-not-look, never DORMANT, none or retired' \
   "$S2450_RC|$(for _s2450_c in $S2450_HTTP; do _s2450_class "$_s2450_c" r4-tsv | cut -f2-5; done | tr '\t\n' ' ;')" \
   '0|health_reflects_readiness could-not-look UNKNOWN UNKNOWN;paid_ingress could-not-look UNKNOWN UNKNOWN;request_body_bounded could-not-look UNKNOWN UNKNOWN;route_has_http_test could-not-look UNKNOWN UNKNOWN;'
is '2450 r4: the whole --tsv output of K1..K2 is the model' "$S2450_RC|$(cat "$S2450_D/r4-tsv.out")" "0|$(_s2450_tsv no:yes:yes no:no:yes)"
is '2450 r4: the K1..K2 --tsv run exits 0 with stderr empty and TMPDIR left empty' "$(_s2450_clean r4-tsv)" '0||'
_s2450_run r4-human "$S2450_D/m1" situations --change "$S2450_K1..$S2450_K2"
has '2450 r4: the human report puts ci_actions_pinned under retired, with its readings and a head witness naming the workflows probe' \
    "$S2450_RC|$(cat "$S2450_D/r4-human.out")" \
    "${S2450_NL}retired$S2450_NL  $(_s2450_id ci_actions_pinned)  ci_actions_pinned  ACTIVE -> DORMANT$S2450_NL    grounds  base: workflows found (ci); head: workflows empty (ci)$S2450_NL    readings  base: workflows=found/1; head: workflows=empty/0$S2450_NL    witness  head: workflows empty$S2450_NL    owes  $(_s2450_owes ci_actions_pinned)$S2450_NL"
is '2450 r4: the human report holds no owed, blinded or standing row over K1..K2' \
   "$S2450_RC|$(LC_ALL=C awk 'NF == 0 { next } /^(owed|blinded|standing)$/ { s = $0; next } /^[a-z]/ { s = "" } s != "" { print s ":" $0 }' "$S2450_D/r4-human.out" | tr '\n' ';')" \
   '0|owed:  none;blinded:  none;standing:  none;'
_s2450_run r4-back "$S2450_D/m1" situations --change "$S2450_K2..$S2450_K1" --tsv
is '2450 r4: the reverse, K2..K1, which brings the workflow in, reads ci_actions_pinned owed' \
   "$S2450_RC|$(_s2450_class ci_actions_pinned r4-back | cut -f2-5)" "0|ci_actions_pinned${S2450_T}owed${S2450_T}DORMANT${S2450_T}ACTIVE"

# ---- the qualifier: a DORMANT that rests on another false term is not detector silence --------------------------------
_s2450_run q-tsv "$S2450_D/m1" situations --change "$S2450_K1..$S2450_K3" --tsv
is '2450 q: removing the model client makes paid_ingress DORMANT at head on its false llm term, api still named undecided, verdict none' \
   "$S2450_RC|$(_s2450_class paid_ingress q-tsv)" \
   "0|$(_s2450_id paid_ingress)${S2450_T}paid_ingress${S2450_T}none${S2450_T}UNKNOWN${S2450_T}DORMANT${S2450_T}api not detected, model_client found (llm)${S2450_T}api not detected, model_client empty (llm)$S2450_T$(_s2450_owes paid_ingress)"
is '2450 q: with no other term false the other three HTTP-keyed classes still read could-not-look over K1..K3' \
   "$S2450_RC|$(_s2450_states q-tsv health_reflects_readiness request_body_bounded route_has_http_test)|$(for _s2450_c in health_reflects_readiness request_body_bounded route_has_http_test; do _s2450_class "$_s2450_c" q-tsv | cut -f3; done | tr '\n' ' ')" \
   '0|health_reflects_readiness=UNKNOWN request_body_bounded=UNKNOWN route_has_http_test=UNKNOWN |could-not-look could-not-look could-not-look '
is '2450 q: the residual names paid_ingress could-not-look at base only, where it was UNKNOWN' \
   "$S2450_RC|$(LC_ALL=C awk -F'\t' '$1 == "residual" && $3 == "paid_ingress" { print $4 }' "$S2450_D/q-tsv.out")" \
   '0|base: cap:api: no probe grounds api and the detector does not name it'
is '2450 q: the whole --tsv output of K1..K3 is the model' "$S2450_RC|$(cat "$S2450_D/q-tsv.out")" "0|$(_s2450_tsv no:yes:yes no:yes:no)"

# ---- adding a probe row that grounds api makes every HTTP-keyed class ACTIVE --------------------------------------------
printf '%s\n' "$S2450_APIROW" >> "$S2450_P/probes.tsv"
_s2450_run probes2 "$S2450_D/m2" probes
S2450_STAMP2="$(LC_ALL=C awk -F'\t' 'NF >= 8 { s = $1 } END { print s }' "$S2450_D/m2/mesh2/facts.log" 2>/dev/null)"
S2450_TID2="$(LC_ALL=C awk -F'\t' 'NF >= 8 { s = $2 } END { print s }' "$S2450_D/m2/mesh2/facts.log" 2>/dev/null)"
_s2450_run a-tsv "$S2450_D/m2" situations --tsv
is '2450 b: once a probe row grounds api, the four HTTP-keyed classes read ACTIVE at the recorded tree' \
   "$(cat "$S2450_D/probes2.rc")|$S2450_RC|$(_s2450_states a-tsv $S2450_HTTP)" \
   '0|0|health_reflects_readiness=ACTIVE paid_ingress=ACTIVE request_body_bounded=ACTIVE route_has_http_test=ACTIVE '
is '2450 b: paid_ingress then stands on http_route found (api) and model_client found (llm)' \
   "$S2450_RC|$(_s2450_class paid_ingress a-tsv)" \
   "0|$(_s2450_id paid_ingress)${S2450_T}paid_ingress${S2450_T}standing$S2450_T-${S2450_T}ACTIVE$S2450_T-${S2450_T}http_route found (api), model_client found (llm)$S2450_T$(_s2450_owes paid_ingress)"
is '2450 b: the whole --tsv output with the api row is the model: five standing, the loopback class still none' \
   "$S2450_RC|$(cat "$S2450_D/a-tsv.out")" "0|$(_s2450_tsv - yes:yes:yes)"
is '2450 b: the ids do not change when a probe row is added: the class column and the id column pair as before' \
   "$S2450_RC|$(LC_ALL=C awk -F'\t' '$1 != "residual" { print $2, $1 }' "$S2450_D/a-tsv.out" | LC_ALL=C sort)" \
   "0|$(LC_ALL=C awk -F'\t' '$1 != "residual" { print $2, $1 }' "$S2450_D/b-tsv.out" | LC_ALL=C sort)"
_s2450_run a-human "$S2450_D/m2" situations
is '2450 b: the human report with the api row: five standing rows, then the residual and the count' \
   "$S2450_RC|$(cat "$S2450_D/a-human.out")" \
   "0|$(_s2450_at yes:yes:yes "  at  $S2450_K1  tree $S2450_TID2  recorded $S2450_STAMP2  detector run on this checkout")"
_s2450_run a-prop "$S2450_D/m2" situations --propose
is '2450 b: --propose proposes the four HTTP-keyed classes and ci_actions_pinned, and no loopback-binding class' \
   "$S2450_RC|$(LC_ALL=C awk 'p && /^  owed:/ { print $2 } /^proposed$/ { p = 1 }' "$S2450_D/a-prop.out" | tr '\n' ' ')" \
   '0|ci_actions_pinned health_reflects_readiness paid_ingress request_body_bounded route_has_http_test '
_s2450_run a-change "$S2450_D/m2" situations --change "$S2450_K1..$S2450_K2" --tsv
is '2450 b: with the api row, --change K1..K2 reads the four HTTP-keyed classes standing on both sides and still retires ci_actions_pinned' \
   "$S2450_RC|$(cat "$S2450_D/a-change.out")" "0|$(_s2450_tsv yes:yes:yes yes:no:yes)"
is '2450 the api-row runs exit 0 with stderr empty and TMPDIR left empty' \
   "$(_s2450_clean a-tsv)|$(_s2450_clean a-human)|$(_s2450_clean a-prop)|$(_s2450_clean a-change)|$(_s2450_clean b-human)|$(_s2450_clean q-tsv)|$(_s2450_clean r4-back)" \
   '0|||0|||0|||0|||0|||0|||0||'

# ---- C13: no network, no key ------------------------------------------------------------------------------------------
is '2450 every felix run here exited 0 and none started gh, curl, wget, ssh, nc or claude' \
   "$S2450_ALL0|$(cat "$S2450_D/net.log" 2>/dev/null)" 'yes|'
