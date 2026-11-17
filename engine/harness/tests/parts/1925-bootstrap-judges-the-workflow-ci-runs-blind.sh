printf '\nbootstrap judges the gate by the workflow CI runs, and says what it could not read (audit b15 review round, A35-A48, blind)\n'
# Blind, written on 2026-10-26 from the review round of docs/2026-10-24-audit-fixes/b15-bootstrap-
# protects-the-right-branch-with.md (section 10, with sections 2 and 4) alone. No engine code was
# read: felix bootstrap is run as a black box from the directory of a fixture repository, with
# section 4's gh stub first on PATH. One assertion per item, A35 to A48, each named for the
# behaviour; a control is folded into its item and said in the detail when it fails.
#
# Fixture F3, all under $TMP/bc1925 (physical paths), every git write through _fx_git:
#   E   felix: main, origin https://github.com/fixture/felix.git, one empty commit h0, origin/main
#       at it and origin/HEAD naming it; engine/harness a copy of $FROOT/harness and
#       projects/app/project.json, both untracked (the stranger). Then, as M1's stranger does next:
#       origin set to https://github.com/stranger/felix.git, projects/ committed (m1), origin/main
#       moved to m1 (the push to the fork). For M2, a branch `local` with one unpushed commit u,
#       and last (A47-A48) one unpushed empty commit on main itself, as the review reproduced it.
#   G1  a fresh repository (origin https://github.com/fixture/app.git, one empty commit, origin/main
#       and origin/HEAD at it). bootstrap --yes renders its gate.yml in the stranger state; the part
#       then sets that file's first repository: line and the ref: line after it, nothing else, and
#       lands it (committed, origin/main moved there), as the stranger would.
#   R3  on master, origin fixture/app, gate.yml (name: gate) and .claude/settings.json committed,
#       refs/remotes/origin/master and origin/HEAD naming it, no origin/main; gh answers D main.
_bc_T="$TMP/bc1925"; mkdir -p "$_bc_T"; _bc_T="$(cd "$_bc_T" && pwd -P)"
_bc_E="$_bc_T/felix"; _bc_G="$_bc_T/g1"; _bc_R="$_bc_T/r3"
mkdir -p "$_bc_T/bin" "$_bc_T/ctl" "$_bc_T/u" "$_bc_T/run" "$_bc_E/engine" "$_bc_E/projects/app"
cat > "$_bc_T/bin/gh" <<'BC1925GHSTUB'
#!/usr/bin/env bash
d="${0%/*}"; T="${d%/*}"; c="$T/ctl"
printf '%s\n' "$*" >> "$T/gh.log"
n="$(wc -l < "$T/gh.log" | tr -d ' ')"
p=""; s=""
for a in "$@"; do [ "$p" = --input ] && [ "$a" = - ] && s=1; p="$a"; done
[ -z "$s" ] || cat > "$T/gh.in.$n"
k=other; name=""
if [ "${1:-}" = api ]; then
  m=GET; u=""; p=""
  for a in "$@"; do
    case "$p" in -X|--method) m="$a" ;; esac
    case "$a" in -X?*) m="${a#-X}" ;; --method=*) m="${a#--method=}" ;; esac
    [ -n "$u" ] || case "$a" in repos/*) u="$a" ;; esac
    p="$a"
  done
  m="$(printf '%s' "$m" | tr '[:lower:]' '[:upper:]')"
  case "$m $u" in
    "GET repos/fixture/app") k=repo ;;
    "GET repos/fixture/app/branches/"*/protection) k=prot ;;
    "PUT repos/fixture/app/branches/"*/protection) k=put ;;
    "POST repos/fixture/app/branches/"*/protection/required_status_checks/contexts) k=post ;;
  esac
elif [ "${1:-}" = label ] && [ "${2:-}" = list ]; then k=list
elif [ "${1:-}" = label ] && [ "${2:-}" = create ]; then k=create; name="${3:-}"
fi
if [ "$k" = other ]; then printf 'unexpected gh call\n' >&2; exit 1; fi
if [ "$k" = create ]; then
  [ ! -f "$c/create.out" ] || cat "$c/create.out"
  if [ -f "$c/create.$name.rc" ]; then [ ! -f "$c/create.err" ] || cat "$c/create.err" >&2; exit "$(cat "$c/create.$name.rc")"; fi
  exit 0
fi
[ ! -f "$c/$k.out" ] || cat "$c/$k.out"
[ ! -f "$c/$k.err" ] || cat "$c/$k.err" >&2
if [ "$k" = list ]; then
  L=30; p=""
  for a in "$@"; do [ "$p" != --limit ] || L="$a"; case "$a" in --limit=*) L="${a#--limit=}" ;; esac; p="$a"; done
  case "$L" in ''|*[!0123456789]*) L=30 ;; esac
  [ ! -f "$c/labels" ] || head -n "$L" "$c/labels"
fi
r=0; [ ! -f "$c/$k.rc" ] || r="$(cat "$c/$k.rc")"
exit "$r"
BC1925GHSTUB
chmod +x "$_bc_T/bin/gh"

# ---- helpers: fixture git, the stub's answers, one run, and the readers of a run
_bc_fx=""   # fixture steps that failed: every assertion after one fails, saying which
_bc_fix() { "$@" || _bc_fx="$_bc_fx [$*]"; }
_bc_git() { _fx_git "$@" >/dev/null 2>&1; }
_bc_ci() { _bc_git "$1" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -q --allow-empty -m "$2"; }
_bc_repo() {  # DIR URL BRANCH: BRANCH, origin URL, one empty commit, origin/BRANCH at it and origin/HEAD naming it
  mkdir -p "$1" && _bc_git "$1" init -q -b "$3" && _bc_git "$1" remote add origin "$2" && _bc_ci "$1" init \
    && _bc_git "$1" update-ref "refs/remotes/origin/$3" HEAD \
    && _bc_git "$1" symbolic-ref refs/remotes/origin/HEAD "refs/remotes/origin/$3"
}
_bc_land() { _bc_git "$1" add -A && _bc_ci "$1" "$2" && _bc_git "$1" update-ref refs/remotes/origin/main HEAD; }
_bc_head() { _fx_git "$1" rev-parse HEAD 2>/dev/null; }
_bc_P1='{"url":"https://api.github.com/repos/fixture/app/branches/main/protection","required_status_checks":{"url":"https://api.github.com/repos/fixture/app/branches/main/protection/required_status_checks","strict":true,"contexts":["gate"],"contexts_url":"https://api.github.com/repos/fixture/app/branches/main/protection/required_status_checks/contexts","checks":[{"context":"gate","app_id":15368}]},"required_pull_request_reviews":{"dismiss_stale_reviews":true,"required_approving_review_count":0},"enforce_admins":{"url":"https://api.github.com/repos/fixture/app/branches/main/protection/enforce_admins","enabled":true},"allow_force_pushes":{"enabled":false}}'
_bc_ctl() {  # the stub's answers back to the contract's defaults: main, not protected, the five labels
  [ -n "$_bc_T" ] && [ -d "$_bc_T/ctl" ] || return 1
  rm -f "$_bc_T"/ctl/*
  printf '{"default_branch":"main"}\n' > "$_bc_T/ctl/repo.out"
  printf '%s' '{"message":"Branch not protected","documentation_url":"https://docs.github.com/rest/branches/branch-protection#get-branch-protection","status":"404"}' > "$_bc_T/ctl/prot.out"
  printf 'gh: Branch not protected (HTTP 404)\n' > "$_bc_T/ctl/prot.err"; printf '1\n' > "$_bc_T/ctl/prot.rc"
  printf '{}\n' > "$_bc_T/ctl/put.out"; printf '{}\n' > "$_bc_T/ctl/post.out"
  printf '%s\tdesc\t#ededed\n' needs-founder needs-architecture risk-green risk-yellow risk-red > "$_bc_T/ctl/labels"
}
_bc_p1() { _bc_ctl && printf '%s' "$_bc_P1" > "$_bc_T/ctl/prot.out" && printf '0\n' > "$_bc_T/ctl/prot.rc" && rm -f "$_bc_T/ctl/prot.err"; }
_bc_run() {  # ID DIR [--yes]: one bootstrap run with E as the home; output, status and gh.log under run/
  local id="$1" d="$2"; shift 2
  [ -n "$_bc_T" ] || return 1
  rm -f "$_bc_T"/gh.in.*; : > "$_bc_T/gh.log"
  if [ -n "$d" ] && [ -d "$d" ]; then
    ( _fx_cd "$d" && HOME="$_bc_T/u" FELIX_HOME="$_bc_E" PATH="$_bc_T/bin:$PATH" "$_bc_E/engine/harness/felix" bootstrap "$@" ) \
      > "$_bc_T/run/$id.out" 2>&1
    printf '%s\n' "$?" > "$_bc_T/run/$id.rc"
  else printf 'no directory [%s] to run in\n' "$d" > "$_bc_T/run/$id.out"; printf 'not-run\n' > "$_bc_T/run/$id.rc"; fi
  cp "$_bc_T/gh.log" "$_bc_T/run/$id.log"
}
_bc_rc()  { cat "$_bc_T/run/$1.rc" 2>/dev/null || printf 'unread'; }
_bc_out() { cat "$_bc_T/run/$1.out" 2>/dev/null || printf '[no output file for %s]' "$1"; }
_bc_ran() { [ -s "$_bc_T/run/$1.out" ] && case "$(_bc_rc "$1")" in ''|*[!0123456789]*) return 1 ;; esac; }
_bc_val() {  # ID LABEL -> the value of the first line starting LABEL, its leading blanks dropped
  LC_ALL=C awk -v l="$2" 'index($0, l) == 1 { v = substr($0, length(l) + 1); sub(/^[ \t]+/, "", v); print v; exit }' "$_bc_T/run/$1.out" 2>/dev/null; }
_bc_row() {  # ID NAME -> the first row line, `  [M] NAME ...`
  LC_ALL=C awk -v n="$2" 'substr($0, 1, 3) == "  [" && substr($0, 5, 2) == "] " && index(substr($0, 7), n) == 1 { print; exit }' "$_bc_T/run/$1.out" 2>/dev/null; }
_bc_line() {  # ID PREFIX SUB -> yes when a line starts PREFIX and holds SUB
  LC_ALL=C awk -v p="$2" -v s="$3" 'index($0, p) == 1 && index($0, s) { y = 1 } END { print (y ? "yes" : "no") }' "$_bc_T/run/$1.out" 2>/dev/null; }
_bc_both() {  # ID A B -> yes when one line holds both
  LC_ALL=C awk -v a="$2" -v b="$3" 'index($0, a) && index($0, b) { y = 1 } END { print (y ? "yes" : "no") }' "$_bc_T/run/$1.out" 2>/dev/null; }
_bc_after() {  # ID PREFIX -> the line after the first line starting PREFIX
  LC_ALL=C awk -v p="$2" 'f { print; exit } index($0, p) == 1 { f = 1 }' "$_bc_T/run/$1.out" 2>/dev/null; }
_bc_wfref() {  # DIR REPO -> the line after the first line holding `repository: REPO` in DIR's gate.yml, blanks removed
  LC_ALL=C awk -v r="repository: $2" 'f { gsub(/[ \t]/, ""); print; exit } index($0, r) { f = 1 }' "$1/.github/workflows/gate.yml" 2>/dev/null; }
# The committed workflow's checkout, set by hand: the first line whose first word is repository: and
# the first ref: line after it get the values given, indentation kept, every other line as it was.
# Then the files are landed (committed, origin/main moved there), and read back from origin/main.
_bc_set() {  # DIR REPO REF
  local f="$1/.github/workflows/gate.yml"
  [ -f "$f" ] || return 1
  if LC_ALL=C awk -v r="$2" -v s="$3" -v q="'" '
       !c && $1 == "repository:" { print substr($0, 1, index($0, "repository:") - 1) "repository: " r; c = 1; next }
       c == 1 && $1 == "ref:" { print substr($0, 1, index($0, "ref:") - 1) "ref: " q s q; c = 2; next }
       { print }
       END { exit (c == 2 ? 0 : 1) }' "$f" > "$_bc_T/gate.yml.new"; then
    cp "$_bc_T/gate.yml.new" "$f" && _bc_land "$1" "the workflow checks out $2 at $3" \
      && [ "$(_bc_pair "$1")" = "$2|$3" ]
  else return 1; fi
}
_bc_pair() {  # DIR -> REPO|REF as the gate.yml on DIR's origin/main names them, quotes removed
  _fx_git "$1" show refs/remotes/origin/main:.github/workflows/gate.yml 2>/dev/null | LC_ALL=C awk -v q="'" '
    !c && $1 == "repository:" { r = $2; c = 1; next }
    c == 1 && $1 == "ref:" { s = $2; c = 2 }
    END { gsub(q, "", r); gsub(/"/, "", r); gsub(q, "", s); gsub(/"/, "", s); print r "|" s }'
}
# A gh.log line as METHOD PATH (api), list, create NAME, or other. A write is a create, or an api call
# whose method is not GET.
_bc_cls='function cls(   i, m, p, w) {
  if ($1 == "label") return ($2 == "list" ? "list" : ($2 == "create" ? "create " $3 : "other"))
  if ($1 != "api") return "other"
  m = "GET"; p = ""
  for (i = 2; i <= NF; i++) { w = $i
    if ((w == "-X" || w == "--method") && i < NF) { m = toupper($(i + 1)); i++; continue }
    if (substr(w, 1, 2) == "-X" && length(w) > 2) { m = toupper(substr(w, 3)); continue }
    if (substr(w, 1, 9) == "--method=") { m = toupper(substr(w, 10)); continue }
    if (p == "" && substr(w, 1, 6) == "repos/") p = w }
  return m " " p }
function wr(c,   a) { split(c, a, " "); return (a[1] == "create" || (a[1] != "GET" && a[1] != "list" && a[1] != "other")) }'
_bc_wl() {  # ID -> the run's writes, each followed by |, or [no log]
  [ -f "$_bc_T/run/$1.log" ] || { printf '[no log for %s]' "$1"; return; }
  LC_ALL=C awk "$_bc_cls"' { c = cls() } wr(c) { printf "%s|", c }' "$_bc_T/run/$1.log" 2>/dev/null; }
# One assertion: each _bc_ck that fails adds its words to the detail; _bc_end says ok or bad once.
_bc_f=""
_bc_ck()  { local d="$1"; shift; "$@" || _bc_f="$_bc_f; $d"; }
_bc_end() { [ -z "$_bc_fx" ] || _bc_f="$_bc_f; fixture steps failed:$_bc_fx"
            if [ -z "$_bc_f" ]; then ok "$1"; else bad "$1" "${_bc_f#; }"; fi; _bc_f=""; }
_bc_has()   { case "$1" in *"$2"*) return 0 ;; esac; return 1; }
_bc_lacks() { ! _bc_has "$1" "$2"; }
_bc_pre()   { case "$1" in "$2"*) return 0 ;; esac; return 1; }
_bc_held()  {  # ROW REASON: a [?] row, or a [ ] row holding held back; either holding REASON
  { _bc_pre "$1" '  [?] protection' || { _bc_pre "$1" '  [ ] protection' && _bc_has "$1" 'held back'; }; } \
    && _bc_has "$1" "$2"; }
_bc_eq()    { [ "$1" = "$2" ]; }
_bc_exit()  { _bc_ck "run $1 did not run or printed nothing" _bc_ran "$1"; _bc_ck "run $1 exited $(_bc_rc "$1"), not $2" _bc_eq "$(_bc_rc "$1")" "$2"; }
_bc_nowrite() { _bc_ck "run $1 wrote [$(_bc_wl "$1")]" _bc_eq "$(_bc_wl "$1")" ""; }
_bc_PUT='PUT repos/fixture/app/branches/main/protection|'
_bc_BL='Baseline already in place.'

# ---- the stranger: E holds projects/app untracked, and bootstrap renders G1's workflow
_bc_fix _bc_repo "$_bc_E" https://github.com/fixture/felix.git main
_bc_fix cp -R "$FROOT/harness" "$_bc_E/engine/harness"
printf '%s\n' '{"name": "app", "remote_match": "github.com/fixture/app", "gate": "true"}' > "$_bc_E/projects/app/project.json"
_bc_h0="$(_bc_head "$_bc_E")"; [ -n "$_bc_h0" ] || _bc_h0=unread-E-h0
_bc_fix _bc_repo "$_bc_G" https://github.com/fixture/app.git main
_bc_fix _bc_ctl
_bc_run r0 "$_bc_G" --yes
_bc_fix _bc_eq "$(_bc_wfref "$_bc_G" fixture/felix)" "ref:'{{FELIX_REF}}'"
# ---- as M1's stranger does next: origin at the fork, projects/app committed and pushed there, and
# only the ref: line of the committed workflow filled with the fork's commit
_bc_fix _bc_git "$_bc_E" remote set-url origin https://github.com/stranger/felix.git
_bc_fix _bc_git "$_bc_E" add projects
_bc_fix _bc_ci "$_bc_E" 'projects/app'
_bc_fix _bc_git "$_bc_E" update-ref refs/remotes/origin/main HEAD
_bc_m1="$(_bc_head "$_bc_E")"; [ -n "$_bc_m1" ] || _bc_m1=unread-E-m1
_bc_fix _bc_set "$_bc_G" fixture/felix "$_bc_m1"

_bc_run a35 "$_bc_G"
_bc_x="$(_bc_val a35 'ci project:')"
_bc_ck "run a35 did not run" _bc_ran a35
_bc_ck "control: felix repo: [$(_bc_val a35 'felix repo:')] is not [stranger/felix]" _bc_eq "$(_bc_val a35 'felix repo:')" stranger/felix
_bc_ck "control: felix ref: [$(_bc_val a35 'felix ref:')] is not the fork's commit [$_bc_m1]" _bc_eq "$(_bc_val a35 'felix ref:')" "$_bc_m1"
_bc_ck "the ci project: value [$_bc_x] does not start [none: ]" _bc_pre "$_bc_x" 'none: '
_bc_ck "it lacks [checks out fixture/felix, not stranger/felix]" _bc_has "$_bc_x" 'checks out fixture/felix, not stranger/felix'
_bc_end "b15 A35 (B21, M1): a committed workflow that checks out fixture/felix while Felix is stranger/felix makes ci project:  none: ... checks out fixture/felix, not stranger/felix, though the pin holds projects/app"

_bc_run a36 "$_bc_G" --yes
_bc_x="$(_bc_row a35 protection)"
_bc_ck "the plan's protection row [$_bc_x] does not start [  [ ] protection]" _bc_pre "$_bc_x" '  [ ] protection'
_bc_ck "it lacks [held back]" _bc_has "$_bc_x" 'held back'
_bc_ck "it lacks [checks out fixture/felix, not stranger/felix]" _bc_has "$_bc_x" 'checks out fixture/felix, not stranger/felix'
_bc_nowrite a36
_bc_ck "no line starts [  skipped    protection (] holding [checks out fixture/felix]" \
  _bc_eq "$(_bc_line a36 '  skipped    protection (' 'checks out fixture/felix')" yes
_bc_exit a36 1
_bc_end "b15 A36 (B21, B18): and main unprotected stays so: the plan holds protection back for that reason, and --yes makes no write, says skipped    protection (... checks out fixture/felix, and exits 1"

_bc_fix _bc_p1
_bc_run a37p "$_bc_G"; _bc_run a37y "$_bc_G" --yes
_bc_exit a37p 0
_bc_ck "plan printed $_bc_BL" _bc_lacks "$(_bc_out a37p)" "$_bc_BL"
_bc_ck "no plan line holds both [cannot pass] and [checks out fixture/felix]" _bc_eq "$(_bc_both a37p 'cannot pass' 'checks out fixture/felix')" yes
_bc_nowrite a37y; _bc_exit a37y 1
_bc_end "b15 A37 (B21, B6): a main that already requires the gate under that workflow is one CI cannot pass, not $_bc_BL, and --yes exits 1 with no write"

_bc_fix _bc_ctl; _bc_fix _bc_set "$_bc_G" stranger/felix "$_bc_h0"
_bc_run a38p "$_bc_G"; _bc_run a38y "$_bc_G" --yes
_bc_x="$(_bc_val a38p 'ci project:')"
_bc_ck "the ci project: value [$_bc_x] does not start [none: ]" _bc_pre "$_bc_x" 'none: '
_bc_ck "it lacks [which does not hold projects/app]" _bc_has "$_bc_x" 'which does not hold projects/app'
_bc_nowrite a38y
_bc_ck "no --yes line starts [  skipped    protection (] holding [which does not hold projects/app]" \
  _bc_eq "$(_bc_line a38y '  skipped    protection (' 'which does not hold projects/app')" yes
_bc_ck "no --yes line holds both the committed commit [$_bc_h0] and [does not hold projects/app]" \
  _bc_eq "$(_bc_both a38y "$_bc_h0" 'does not hold projects/app')" yes
_bc_exit a38y 1
_bc_end "b15 A38 (B21): a committed workflow at the fork but pinned to a commit without projects/app is judged by that commit, not the pin: no write, the reason named, and --yes exits 1"

_bc_fix _bc_ctl; _bc_fix _bc_set "$_bc_G" stranger/felix "$_bc_m1"
_bc_run a39p "$_bc_G"; _bc_run a39y "$_bc_G" --yes
_bc_x="$(_bc_val a39p 'ci project:')"
_bc_ck "the ci project: value [$_bc_x] does not start [projects/app]" _bc_pre "$_bc_x" 'projects/app'
_bc_ck "--yes wrote [$(_bc_wl a39y)], not the one PUT to main's protection" _bc_eq "$(_bc_wl a39y)" "$_bc_PUT"
_bc_ck "the output lacks [  protected  main requires the gate]" _bc_has "$(_bc_out a39y)" '  protected  main requires the gate'
_bc_exit a39y 0
_bc_end "b15 A39 (B21, control): the fork's workflow at the fork's commit holding projects/app reads ci project:  projects/app, and --yes protects main with one PUT and exits 0"

# ---- M2: one unpushed commit in E empties the pin; the committed workflow still resolves
_bc_fix _bc_git "$_bc_E" checkout -q -b local
_bc_fix _bc_ci "$_bc_E" 'not pushed'
_bc_u="$(_bc_head "$_bc_E")"; [ -n "$_bc_u" ] || _bc_u=unread-E-u
_bc_fix _bc_p1
_bc_run a40p "$_bc_G"; _bc_run a40y "$_bc_G" --yes
_bc_x="$(_bc_val a40p 'ci project:')"
_bc_ck "control: felix ref: [$(_bc_val a40p 'felix ref:')] lacks {{FELIX_REF}}, so the pin is not empty" _bc_has "$(_bc_val a40p 'felix ref:')" '{{FELIX_REF}}'
_bc_ck "the ci project: value [$_bc_x] does not start [projects/app]" _bc_pre "$_bc_x" 'projects/app'
_bc_ck "plan lacks [$_bc_BL]" _bc_has "$(_bc_out a40p)" "$_bc_BL"
_bc_ck "plan says cannot pass" _bc_lacks "$(_bc_out a40p)" 'cannot pass'
_bc_exit a40p 0
_bc_nowrite a40y; _bc_exit a40y 0
_bc_end "b15 A40 (B21, M2): with E's HEAD off origin's default branch, a main requiring the gate under a committed workflow that resolves app is $_bc_BL, ci project:  projects/app, and --yes exits 0"

_bc_fix _bc_ctl
_bc_run a41y "$_bc_G" --yes
_bc_ck "--yes wrote [$(_bc_wl a41y)], not the one PUT to main's protection" _bc_eq "$(_bc_wl a41y)" "$_bc_PUT"
_bc_ck "the output lacks [  protected  main requires the gate]" _bc_has "$(_bc_out a41y)" '  protected  main requires the gate'
_bc_exit a41y 0
_bc_end "b15 A41 (B21, M2): and with main unprotected, --yes protects it with one PUT and exits 0"
_bc_fix _bc_git "$_bc_E" checkout -q main

# ---- B22: a pinned commit E lacks, or one off E's origin/main, is unknown
for _bc_k in z u; do
  if [ "$_bc_k" = z ]; then _bc_s=0123456789abcdef0123456789abcdef01234567; else _bc_s="$_bc_u"; fi
  _bc_fix _bc_ctl; _bc_fix _bc_set "$_bc_G" stranger/felix "$_bc_s"
  _bc_fix _bc_p1; _bc_run "a42p$_bc_k" "$_bc_G"
  _bc_fix _bc_ctl; _bc_run "a42y$_bc_k" "$_bc_G" --yes
  _bc_x="$(_bc_val "a42p$_bc_k" 'ci project:')"
  _bc_exit "a42p$_bc_k" 0
  _bc_ck "case $_bc_k: plan printed $_bc_BL" _bc_lacks "$(_bc_out "a42p$_bc_k")" "$_bc_BL"
  _bc_ck "case $_bc_k: plan says cannot pass" _bc_lacks "$(_bc_out "a42p$_bc_k")" 'cannot pass'
  _bc_ck "case $_bc_k: the ci project: value [$_bc_x] does not start [unknown: ]" _bc_pre "$_bc_x" 'unknown: '
  _bc_ck "case $_bc_k: no plan line holds both [could not be read] and [$_bc_s]" _bc_eq "$(_bc_both "a42p$_bc_k" 'could not be read' "$_bc_s")" yes
  _bc_nowrite "a42y$_bc_k"
  _bc_ck "case $_bc_k: no --yes line starts [  skipped    protection (] holding [could not be read]" \
    _bc_eq "$(_bc_line "a42y$_bc_k" '  skipped    protection (' 'could not be read')" yes
  _bc_exit "a42y$_bc_k" 1
done
_bc_end "b15 A42 (B22): a committed workflow pinned to a commit E does not have (z), or to E's unpushed commit (u), is unknown: ci project:  unknown: ..., could not be read, neither cannot pass nor $_bc_BL, and --yes writes nothing and exits 1"

# ---- M3: R3 knows only origin/master; gh says the default branch is main
_bc_fix _bc_repo "$_bc_R" https://github.com/fixture/app.git master
mkdir -p "$_bc_R/.github/workflows" "$_bc_R/.claude"
printf 'name: gate\n' > "$_bc_R/.github/workflows/gate.yml"
printf '%s\n' '{"permissions":{"deny":["Read(./.env)"]}}' > "$_bc_R/.claude/settings.json"
_bc_fix _bc_git "$_bc_R" add -A
_bc_fix _bc_ci "$_bc_R" 'gate and settings'
_bc_fix _bc_git "$_bc_R" update-ref refs/remotes/origin/master HEAD
_bc_fix _bc_eq "$(_fx_git "$_bc_R" rev-parse -q --verify refs/remotes/origin/main 2>/dev/null)" ""
_bc_fix _bc_p1
_bc_run a43p "$_bc_R"; _bc_run a43y "$_bc_R" --yes
_bc_exit a43p 0
_bc_ck "plan says cannot pass" _bc_lacks "$(_bc_out a43p)" 'cannot pass'
_bc_ck "plan says is not on origin/main" _bc_lacks "$(_bc_out a43p)" 'is not on origin/main'
_bc_ck "plan printed $_bc_BL" _bc_lacks "$(_bc_out a43p)" "$_bc_BL"
_bc_ck "plan lacks [origin/main could not be read]" _bc_has "$(_bc_out a43p)" 'origin/main could not be read'
_bc_nowrite a43y; _bc_exit a43y 1
_bc_end "b15 A43 (B23, M3): a clone with no origin/main, main requiring the gate: origin/main could not be read, never is not on origin/main or cannot pass, no $_bc_BL, and --yes exits 1"

_bc_fix _bc_ctl
_bc_run a44p "$_bc_R"; _bc_run a44y "$_bc_R" --yes
_bc_x="$(_bc_row a44p protection)"
_bc_ck "run a44p did not run" _bc_ran a44p
_bc_ck "the plan's protection row [$_bc_x] is neither [  [?] protection] nor [  [ ] protection] holding [held back], holding [origin/main could not be read]" \
  _bc_held "$_bc_x" 'origin/main could not be read'
_bc_ck "plan says is not on origin/main" _bc_lacks "$(_bc_out a44p)" 'is not on origin/main'
_bc_nowrite a44y
_bc_ck "--yes says is not on origin/main" _bc_lacks "$(_bc_out a44y)" 'is not on origin/main'
_bc_ck "no --yes line starts [  skipped    protection (] holding [origin/main could not be read]" \
  _bc_eq "$(_bc_line a44y '  skipped    protection (' 'origin/main could not be read')" yes
_bc_exit a44y 1
_bc_end "b15 A44 (B23, M3): and with main unprotected, protection is held back because origin/main could not be read, and --yes writes nothing and exits 1"

_bc_fix _bc_git "$_bc_R" update-ref refs/remotes/origin/main HEAD
_bc_fix _bc_p1
_bc_run a45p "$_bc_R"
_bc_ck "plan lacks [$_bc_BL]" _bc_has "$(_bc_out a45p)" "$_bc_BL"
_bc_exit a45p 0
_bc_end "b15 A45 (B23, control): once origin/main is in the clone (as a fetch would leave it), the same repository reads $_bc_BL"

# ---- M1's remedy: the stranger's first --yes (r0) tells a forking stranger about repository:
_bc_x="$(_bc_val r0 'ci project:')"; _bc_y="$(_bc_after r0 '  wrote      .github/workflows/gate.yml')"
_bc_ck "run r0 did not run or printed nothing" _bc_ran r0
_bc_ck "r0's ci project: value [$_bc_x] lacks [repository:]" _bc_has "$_bc_x" 'repository:'
_bc_ck "the line after r0's wrote line [$_bc_y] lacks [repository:]" _bc_has "$_bc_y" 'repository:'
_bc_end "b15 A46 (B21, M1): the stranger's remedy says a fork means setting the workflow's repository: too: the ci project: line and the line after wrote      .github/workflows/gate.yml each name repository:"

# ---- M2 as the review reproduced it: R3's committed workflow names no checkout, and E's main has
# one unpushed commit, so the pin is empty while origin/main holds projects/app
_bc_fix _bc_ci "$_bc_E" 'not pushed, on main'
_bc_fix _bc_p1
_bc_run a47p "$_bc_R"; _bc_run a47y "$_bc_R" --yes
_bc_x="$(_bc_val a47p 'ci project:')"
_bc_ck "control: felix ref: [$(_bc_val a47p 'felix ref:')] lacks {{FELIX_REF}}, so the pin is not empty" _bc_has "$(_bc_val a47p 'felix ref:')" '{{FELIX_REF}}'
_bc_ck "the ci project: value [$_bc_x] lacks [not on its default branch]" _bc_has "$_bc_x" 'not on its default branch'
_bc_ck "the ci project: value [$_bc_x] tells the person to fork" _bc_lacks "$_bc_x" 'fork'
_bc_ck "plan lacks [$_bc_BL]" _bc_has "$(_bc_out a47p)" "$_bc_BL"
_bc_ck "plan says cannot pass" _bc_lacks "$(_bc_out a47p)" 'cannot pass'
_bc_exit a47p 0
_bc_nowrite a47y; _bc_exit a47y 0
_bc_end "b15 A47 (B24, M2): with E's main one commit ahead of origin/main, which holds projects/app, a main requiring the gate under a workflow that names no checkout is $_bc_BL, the ci project: line says not on its default branch and names no fork, and --yes exits 0"

_bc_fix _bc_ctl
_bc_run a48y "$_bc_R" --yes
_bc_ck "--yes wrote [$(_bc_wl a48y)], not the one PUT to main's protection" _bc_eq "$(_bc_wl a48y)" "$_bc_PUT"
_bc_ck "the output lacks [  protected  main requires the gate]" _bc_has "$(_bc_out a48y)" '  protected  main requires the gate'
_bc_exit a48y 0
_bc_end "b15 A48 (B24, M2): and with main unprotected, --yes protects it with one PUT and exits 0"
