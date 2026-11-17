printf '\nbootstrap reads the default branch, the protection and the labels honestly (audit b15, A17-A34, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b15-bootstrap-protects-the-right-
# branch-with.md (sections 2 to 4) alone. No engine code was read: felix bootstrap is run as a black
# box with a gh stub first on PATH. One assertion per contract item, A17 to A34, each named for the
# behaviour; a control the contract marks is folded into its item and said in the detail when it fails.
#
# Fixture F2, all under $TMP/bd1920 (physical paths), every git write through _fx_git: E is felix
# merged (main, origin https://github.com/fixture/felix.git never fetched, engine/harness a copy of
# $FROOT/harness untracked, projects/app committed and origin/main at it), and the home of every run.
# G is a repository with origin https://github.com/fixture/app.git, gate.yml (name: gate) and
# .claude/settings.json committed and on origin/main, refs/remotes/origin/trunk at the same commit,
# so every run from G is ready (CI resolves the project, the workflow is on the default branch and
# filled). W is a worktree of G on claude/adopt-x. The gh stub is section 4's: each call one line of
# gh.log, the standard input of a call given --input - saved to gh.in.<its line>, answers from ctl/.
# Every run's gh.log is kept for A34, and every plan run is checked for A33 as it ends.
_bd_T="$TMP/bd1920"; mkdir -p "$_bd_T"; _bd_T="$(cd "$_bd_T" && pwd -P)"
_bd_E="$_bd_T/felix"; _bd_G="$_bd_T/g"; _bd_W="$_bd_T/w"
mkdir -p "$_bd_T/bin" "$_bd_T/ctl" "$_bd_T/u" "$_bd_T/run" "$_bd_E/engine" "$_bd_E/projects/app"
: > "$_bd_T/all.log"
cat > "$_bd_T/bin/gh" <<'BD1920GHSTUB'
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
BD1920GHSTUB
chmod +x "$_bd_T/bin/gh"

# ---- helpers: fixture git, the stub's answers, one run, and the readers of a run
_bd_fx=""   # fixture steps that failed: every assertion after one fails, saying which
_bd_fix() { "$@" || _bd_fx="$_bd_fx [$*]"; }
_bd_git() { _fx_git "$@" >/dev/null 2>&1; }
_bd_ci() { _bd_git "$1" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -q --allow-empty -m "$2"; }
_bd_repo() {  # DIR URL: main, origin URL, one empty commit, origin/main at it and origin/HEAD naming it
  mkdir -p "$1" && _bd_git "$1" init -q -b main && _bd_git "$1" remote add origin "$2" && _bd_ci "$1" init \
    && _bd_git "$1" update-ref refs/remotes/origin/main HEAD \
    && _bd_git "$1" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
}
_bd_P1='{"url":"https://api.github.com/repos/fixture/app/branches/main/protection","required_status_checks":{"url":"https://api.github.com/repos/fixture/app/branches/main/protection/required_status_checks","strict":true,"contexts":["gate"],"contexts_url":"https://api.github.com/repos/fixture/app/branches/main/protection/required_status_checks/contexts","checks":[{"context":"gate","app_id":15368}]},"required_pull_request_reviews":{"dismiss_stale_reviews":true,"required_approving_review_count":0},"enforce_admins":{"url":"https://api.github.com/repos/fixture/app/branches/main/protection/enforce_admins","enabled":true},"allow_force_pushes":{"enabled":false}}'
_bd_P2='{
  "url": "https://api.github.com/repos/fixture/app/branches/main/protection",
  "required_status_checks": {
    "strict": false,
    "contexts": [
      "build",
      "gate"
    ],
    "checks": [
      { "context": "build", "app_id": null },
      { "context": "gate", "app_id": null }
    ]
  },
  "enforce_admins": { "enabled": false }
}
'
_bd_P3='{"url":"https://api.github.com/repos/fixture/app/branches/main/protection","required_status_checks":{"strict":false,"contexts":["gate-lint"],"checks":[{"context":"gate-lint","app_id":null}]},"required_pull_request_reviews":{"dismissal_restrictions":{"teams":[{"slug":"gate","name":"gate"}]},"required_approving_review_count":1},"enforce_admins":{"enabled":true}}'
_bd_P4='{"url":"https://api.github.com/repos/fixture/app/branches/main/protection","required_pull_request_reviews":{"required_approving_review_count":1},"enforce_admins":{"enabled":true}}'
_bd_ctl() {  # the stub's answers back to the contract's defaults: main, not protected, the five labels
  [ -n "$_bd_T" ] && [ -d "$_bd_T/ctl" ] || return 1
  rm -f "$_bd_T"/ctl/*
  printf '{"default_branch":"main"}\n' > "$_bd_T/ctl/repo.out"
  _bd_prot 1 "$(_bd_msg 'Branch not protected' 404)" 'gh: Branch not protected (HTTP 404)'
  printf '{}\n' > "$_bd_T/ctl/put.out"; printf '{}\n' > "$_bd_T/ctl/post.out"
  _bd_five > "$_bd_T/ctl/labels"
}
_bd_five() { printf '%s\tdesc\t#ededed\n' needs-founder needs-architecture risk-green risk-yellow risk-red; }
_bd_msg() { printf '{"message":"%s","documentation_url":"https://docs.github.com/rest/branches/branch-protection#get-branch-protection","status":"%s"}' "$1" "$2"; }
_bd_prot() {  # RC OUT ERR: the protection read's answer, OUT with no line break added; an empty ERR is no stderr
  printf '%s' "$2" > "$_bd_T/ctl/prot.out"; printf '%s\n' "$1" > "$_bd_T/ctl/prot.rc"
  if [ -n "$3" ]; then printf '%s\n' "$3" > "$_bd_T/ctl/prot.err"; else rm -f "$_bd_T/ctl/prot.err"; fi
}
_bd_np=0; _bd_a33=""
_bd_run() {  # ID DIR [--yes]: one bootstrap run with E as the home; output, status, gh.log and inputs under run/
  local id="$1" d="$2" f; shift 2
  [ -n "$_bd_T" ] || return 1
  rm -f "$_bd_T"/gh.in.*; : > "$_bd_T/gh.log"
  if [ -n "$d" ] && [ -d "$d" ]; then
    ( _fx_cd "$d" && HOME="$_bd_T/u" FELIX_HOME="$_bd_E" PATH="$_bd_T/bin:$PATH" "$_bd_E/engine/harness/felix" bootstrap "$@" ) \
      > "$_bd_T/run/$id.out" 2>&1
    printf '%s\n' "$?" > "$_bd_T/run/$id.rc"
  else printf 'no directory [%s] to run in\n' "$d" > "$_bd_T/run/$id.out"; printf 'not-run\n' > "$_bd_T/run/$id.rc"; fi
  cp "$_bd_T/gh.log" "$_bd_T/run/$id.log"; cat "$_bd_T/gh.log" >> "$_bd_T/all.log"
  for f in "$_bd_T"/gh.in.*; do [ ! -f "$f" ] || cp "$f" "$_bd_T/run/$id.${f##*/}"; done
  [ "$#" -eq 0 ] || return 0
  # A33, as each plan run ends: no -X, no --method, no label create, and G and W unchanged.
  _bd_np="$((_bd_np + 1))"
  f="$(LC_ALL=C awk '{ for (i = 1; i <= NF; i++) if (substr($i, 1, 2) == "-X" || $i == "--method" || substr($i, 1, 9) == "--method=") { print "[" $0 "]"; next } }
                     $1 == "label" && $2 == "create" { print "[" $0 "]" }' "$_bd_T/run/$id.log" 2>&1)"
  [ -z "$f" ] || _bd_a33="$_bd_a33; plan $id asked $f"
  f="$(_fx_git "$_bd_G" status --porcelain 2>&1)"; [ -z "$f" ] || _bd_a33="$_bd_a33; after plan $id G shows [$f]"
  f="$(_fx_git "$_bd_W" status --porcelain 2>&1)"; [ -z "$f" ] || _bd_a33="$_bd_a33; after plan $id W shows [$f]"
}
_bd_rc()  { cat "$_bd_T/run/$1.rc" 2>/dev/null || printf 'unread'; }
_bd_out() { cat "$_bd_T/run/$1.out" 2>/dev/null || printf '[no output file for %s]' "$1"; }
_bd_ran() { [ -s "$_bd_T/run/$1.out" ] && case "$(_bd_rc "$1")" in ''|*[!0123456789]*) return 1 ;; esac; }
_bd_row() {  # ID NAME -> the first row line, `  [M] NAME ...`
  LC_ALL=C awk -v n="$2" 'substr($0, 1, 3) == "  [" && substr($0, 5, 2) == "] " && index(substr($0, 7), n) == 1 { print; exit }' "$_bd_T/run/$1.out" 2>/dev/null; }
_bd_line() {  # ID PREFIX SUB -> yes when a line starts PREFIX and holds SUB
  LC_ALL=C awk -v p="$2" -v s="$3" 'index($0, p) == 1 && index($0, s) { y = 1 } END { print (y ? "yes" : "no") }' "$_bd_T/run/$1.out" 2>/dev/null; }
_bd_both() {  # ID A B -> yes when one line holds both
  LC_ALL=C awk -v a="$2" -v b="$3" 'index($0, a) && index($0, b) { y = 1 } END { print (y ? "yes" : "no") }' "$_bd_T/run/$1.out" 2>/dev/null; }
_bd_cnt() {  # ID SUB -> how many gh.log lines hold SUB, or [no log]
  [ -f "$_bd_T/run/$1.log" ] || { printf '[no log for %s]' "$1"; return; }
  LC_ALL=C awk -v s="$2" 'index($0, s) { n++ } END { print n + 0 }' "$_bd_T/run/$1.log" 2>/dev/null; }
_bd_brk() {  # ID BRANCH -> ok when the run made a /branches/ call and every one names /branches/BRANCH/
  [ -f "$_bd_T/run/$1.log" ] || { printf '[no log for %s]' "$1"; return; }
  LC_ALL=C awk -v b="/branches/$2/" 'index($0, "/branches/") { n++; if (!index($0, b)) o = o "[" $0 "]" }
    END { if (!n) print "no /branches/ call"; else if (o != "") print o; else print "ok" }' "$_bd_T/run/$1.log" 2>/dev/null; }
_bd_ll() {  # ID -> ok when the run listed labels and every label list holds --limit 1000
  [ -f "$_bd_T/run/$1.log" ] || { printf '[no log for %s]' "$1"; return; }
  LC_ALL=C awk '$1 == "label" && $2 == "list" { n++; y = 0; for (i = 3; i < NF; i++) if ($i == "--limit" && $(i + 1) == "1000") y = 1; if (!y) o = o "[" $0 "]" }
    END { if (!n) print "no label list"; else if (o != "") print o; else print "ok" }' "$_bd_T/run/$1.log" 2>/dev/null; }
_bd_cr() {  # ID NAME FLAG VALUE -> yes when the run's one label create of NAME holds FLAG then VALUE
  LC_ALL=C awk -v n="$2" -v f="$3" -v v="$4" '$1 == "label" && $2 == "create" && $3 == n { c++; for (i = 4; i < NF; i++) if ($i == f && $(i + 1) == v) y++ }
    END { print ((c == 1 && y == 1) ? "yes" : "no") }' "$_bd_T/run/$1.log" 2>/dev/null; }
# A gh.log line as METHOD PATH (api), list, create NAME, or other. A write is a create, or an api call
# whose method is not GET.
_bd_cls='function cls(   i, m, p, w) {
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
_bd_wl() {  # ID -> the run's writes, each followed by |, or [no log]
  [ -f "$_bd_T/run/$1.log" ] || { printf '[no log for %s]' "$1"; return; }
  LC_ALL=C awk "$_bd_cls"' { c = cls() } wr(c) { printf "%s|", c }' "$_bd_T/run/$1.log" 2>/dev/null; }
_bd_in() {  # ID -> the saved input of the run's first write, blanks and line breaks removed
  local n; n="$(LC_ALL=C awk "$_bd_cls"' wr(cls()) { print NR; exit }' "$_bd_T/run/$1.log" 2>/dev/null)"
  if [ -n "$n" ] && [ -f "$_bd_T/run/$1.gh.in.$n" ]; then LC_ALL=C tr -d ' \t\r\n' < "$_bd_T/run/$1.gh.in.$n"; else printf '[no input saved]'; fi; }
# One assertion: each _bd_ck that fails adds its words to the detail; _bd_end says ok or bad once.
_bd_f=""
_bd_ck()  { local d="$1"; shift; "$@" || _bd_f="$_bd_f; $d"; }
_bd_end() { [ -z "$_bd_fx" ] || _bd_f="$_bd_f; fixture steps failed:$_bd_fx"
            if [ -z "$_bd_f" ]; then ok "$1"; else bad "$1" "${_bd_f#; }"; fi; _bd_f=""; }
_bd_has()   { case "$1" in *"$2"*) return 0 ;; esac; return 1; }
_bd_lacks() { ! _bd_has "$1" "$2"; }
_bd_pre()   { case "$1" in "$2"*) return 0 ;; esac; return 1; }
_bd_eq()    { [ "$1" = "$2" ]; }
_bd_exit()  { _bd_ck "run $1 did not run or printed nothing" _bd_ran "$1"; _bd_ck "run $1 exited $(_bd_rc "$1"), not $2" _bd_eq "$(_bd_rc "$1")" "$2"; }
_bd_nowrite() { _bd_ck "run $1 wrote [$(_bd_wl "$1")]" _bd_eq "$(_bd_wl "$1")" ""; }
_bd_rowis() {  # ID NAME MARK [SUB...]: the row starts `  [MARK] NAME` and holds each SUB
  local id="$1" nm="$2" mk="$3" x s; shift 3; x="$(_bd_row "$id" "$nm")"
  _bd_ck "run $id did not run" _bd_ran "$id"
  _bd_ck "run $id: the $nm row [$x] does not start [  [$mk] $nm]" _bd_pre "$x" "  [$mk] $nm"
  for s in "$@"; do _bd_ck "run $id: that row lacks [$s]" _bd_has "$x" "$s"; done
}

# ---- fixture F2
_bd_fix _bd_repo "$_bd_E" https://github.com/fixture/felix.git
_bd_fix cp -R "$FROOT/harness" "$_bd_E/engine/harness"
printf '%s\n' '{"name": "app", "remote_match": "github.com/fixture/app", "gate": "true"}' > "$_bd_E/projects/app/project.json"
_bd_fix _bd_git "$_bd_E" add projects
_bd_fix _bd_ci "$_bd_E" 'projects/app'
_bd_fix _bd_git "$_bd_E" update-ref refs/remotes/origin/main HEAD
_bd_fix _bd_repo "$_bd_G" https://github.com/fixture/app.git
mkdir -p "$_bd_G/.github/workflows" "$_bd_G/.claude"
printf 'name: gate\n' > "$_bd_G/.github/workflows/gate.yml"
printf '%s\n' '{"permissions":{"deny":["Read(./.env)"]}}' > "$_bd_G/.claude/settings.json"
_bd_fix _bd_git "$_bd_G" add -A
_bd_fix _bd_ci "$_bd_G" 'gate and settings'
_bd_fix _bd_git "$_bd_G" update-ref refs/remotes/origin/main HEAD
_bd_fix _bd_git "$_bd_G" update-ref refs/remotes/origin/trunk refs/remotes/origin/main
_bd_fix _bd_git "$_bd_G" worktree add -q -b claude/adopt-x "$_bd_W" main
_bd_PUT='PUT repos/fixture/app/branches/main/protection|'
_bd_POST='POST repos/fixture/app/branches/main/protection/required_status_checks/contexts|'

# ---- the default branch (B10-B12)
_bd_fix _bd_ctl
_bd_run a17y "$_bd_W" --yes; _bd_run a17p "$_bd_W"
_bd_ck "--yes: [$(_bd_brk a17y main)], not every /branches/ call naming main" _bd_eq "$(_bd_brk a17y main)" ok
_bd_ck "--yes: $(_bd_cnt a17y adopt-x) gh.log line(s) name adopt-x" _bd_eq "$(_bd_cnt a17y adopt-x)" 0
_bd_ck "--yes wrote [$(_bd_wl a17y)], not the one PUT to main's protection" _bd_eq "$(_bd_wl a17y)" "$_bd_PUT"
_bd_x="$(_bd_row a17p protection)"
_bd_ck "plan: the protection row [$_bd_x] lacks [main]" _bd_has "$_bd_x" main
_bd_ck "plan: the protection row names adopt-x" _bd_lacks "$_bd_x" adopt-x
_bd_end "b15 A17 (B10): from a worktree on claude/adopt-x, every /branches/ call names main, --yes protects main with one PUT, and the protection row names main, not adopt-x"

_bd_fix _bd_ctl
printf '%s' '{"default_branch":"main","fork":true,"parent":{"full_name":"up/app","default_branch":"trunk"},"source":{"full_name":"up/app","default_branch":"trunk"}}' > "$_bd_T/ctl/repo.out"
_bd_run a18p "$_bd_W"; _bd_run a18y "$_bd_W" --yes
_bd_ck "plan: [$(_bd_brk a18p main)], not every /branches/ call naming main" _bd_eq "$(_bd_brk a18p main)" ok
_bd_ck "--yes: [$(_bd_brk a18y main)], not every /branches/ call naming main" _bd_eq "$(_bd_brk a18y main)" ok
_bd_end "b15 A18 (B10, B11): a fork's parent and source naming trunk are not D: from the worktree every /branches/ call still names main"

_bd_fix _bd_ctl
printf '{\n  "name": "app",\n  "default_branch": "trunk"\n}\n' > "$_bd_T/ctl/repo.out"
_bd_fix _bd_git "$_bd_G" checkout -q --detach
_bd_x="$(_fx_git "$_bd_G" symbolic-ref -q HEAD 2>/dev/null)"
_bd_run a19p "$_bd_G"; _bd_run a19y "$_bd_G" --yes
_bd_fix _bd_git "$_bd_G" checkout -q main
_bd_ck "control: G's HEAD was [$_bd_x], not detached" _bd_eq "$_bd_x" ""
_bd_ck "plan: [$(_bd_brk a19p trunk)], not every /branches/ call naming trunk" _bd_eq "$(_bd_brk a19p trunk)" ok
_bd_ck "--yes: [$(_bd_brk a19y trunk)], not every /branches/ call naming trunk" _bd_eq "$(_bd_brk a19y trunk)" ok
_bd_ck "--yes wrote [$(_bd_wl a19y)], not the one PUT to trunk's protection" _bd_eq "$(_bd_wl a19y)" 'PUT repos/fixture/app/branches/trunk/protection|'
_bd_end "b15 A19 (B10, B11): at a detached HEAD, D read from a pretty-printed answer is trunk: every /branches/ call names trunk and --yes makes one PUT to trunk's protection"

_bd_fix _bd_ctl; rm -f "$_bd_T/ctl/repo.out"
printf 'error connecting to api.github.com\n' > "$_bd_T/ctl/repo.err"; printf '1\n' > "$_bd_T/ctl/repo.rc"
_bd_run a20p "$_bd_G"; _bd_run a20y "$_bd_G" --yes
_bd_exit a20p 0
_bd_rowis a20p protection '?' 'could not be read' 'default branch'
_bd_ck "plan: $(_bd_cnt a20p /branches/) gh.log line(s) hold /branches/" _bd_eq "$(_bd_cnt a20p /branches/)" 0
_bd_ck "--yes: $(_bd_cnt a20y /branches/) gh.log line(s) hold /branches/" _bd_eq "$(_bd_cnt a20y /branches/)" 0
_bd_ck "plan printed Baseline already in place." _bd_lacks "$(_bd_out a20p)" 'Baseline already in place.'
_bd_ck "no plan line holds both [could not be read] and [Nothing changed.]" _bd_eq "$(_bd_both a20p 'could not be read' 'Nothing changed.')" yes
_bd_nowrite a20y
_bd_ck "--yes: no line starts [  skipped    protection (]" _bd_eq "$(_bd_line a20y '  skipped    protection (' 'protection')" yes
_bd_exit a20y 1
_bd_end "b15 A20 (B12, B17, B18): when the repository read fails, protection is [?] could not be read, default branch, with no /branches/ call; plan exits 0 with could not be read, Nothing changed.; --yes skips protection and exits 1"

_bd_fix _bd_ctl; printf '%s\n' '{"message":"Moved Permanently"}' > "$_bd_T/ctl/repo.out"
_bd_run a21p "$_bd_G"
_bd_rowis a21p protection '?'
_bd_ck "plan: $(_bd_cnt a21p /branches/) gh.log line(s) hold /branches/" _bd_eq "$(_bd_cnt a21p /branches/)" 0
_bd_end "b15 A21 (B12): a repository answer with no top-level default_branch reads [?] protection and asks nothing about /branches/"

# ---- the protection (B13, B14)
for _bd_k in 1 2 3 4 5 6 7; do
  _bd_fix _bd_ctl
  case "$_bd_k" in
    1) _bd_prot 1 "$(_bd_msg 'Upgrade to GitHub Pro or make this repository public to enable this feature.' 403)" \
                  'gh: Upgrade to GitHub Pro or make this repository public to enable this feature. (HTTP 403)' ;;
    2) _bd_prot 1 "$(_bd_msg 'Branch not found' 404)" 'gh: Branch not found (HTTP 404)' ;;
    3) _bd_prot 1 "$(_bd_msg 'Not Found' 404)" 'gh: Not Found (HTTP 404)' ;;
    4) _bd_prot 1 '' 'error connecting to api.github.com' ;;
    5) _bd_prot 0 '' '' ;;
    6) _bd_prot 0 '{}' '' ;;
    7) _bd_prot 127 '' 'gh: command not found' ;;
  esac
  _bd_run "a22p$_bd_k" "$_bd_G"; _bd_run "a22y$_bd_k" "$_bd_G" --yes
  _bd_rowis "a22p$_bd_k" protection '?' 'could not be read'
  [ "$_bd_k" != 1 ] || _bd_ck "case 1: the plan lacks [Upgrade to GitHub Pro]" _bd_has "$(_bd_out a22p1)" 'Upgrade to GitHub Pro'
  _bd_nowrite "a22y$_bd_k"; _bd_exit "a22y$_bd_k" 1
done
_bd_end "b15 A22 (B13, B14, B18): a protection read that fails or is no protection (403 Pro, 404 Branch not found, 404 Not Found, no network, empty, {}, 127) reads [?] could not be read, writes nothing, and --yes exits 1"

_bd_fix _bd_ctl; _bd_prot 0 "$_bd_P1" ''
_bd_run a23p "$_bd_G"; _bd_run a23y "$_bd_G" --yes
_bd_rowis a23p protection x
_bd_ck "plan lacks [Baseline already in place.]" _bd_has "$(_bd_out a23p)" 'Baseline already in place.'
_bd_nowrite a23y
_bd_end "b15 A23 (B13, control): a one-line protection whose checks hold gate reads [x] protection, plan prints Baseline already in place., and --yes writes nothing"

_bd_fix _bd_ctl; _bd_prot 0 "$_bd_P2" ''
_bd_run a24p "$_bd_G"; _bd_run a24y "$_bd_G" --yes
_bd_rowis a24p protection x
_bd_nowrite a24y
_bd_end "b15 A24 (B13, control): the same pretty-printed over many lines, gate among build, reads [x] protection and --yes writes nothing"

_bd_fix _bd_ctl; _bd_prot 0 "$_bd_P3" ''
_bd_run a25p "$_bd_G"; _bd_run a25y "$_bd_G" --yes
_bd_rowis a25p protection ' ' 'does not require the gate'
_bd_ck "--yes wrote [$(_bd_wl a25y)], not the one POST to main's required contexts" _bd_eq "$(_bd_wl a25y)" "$_bd_POST"
_bd_ck "its input [$(_bd_in a25y)] is not {\"contexts\":[\"gate\"]}" _bd_eq "$(_bd_in a25y)" '{"contexts":["gate"]}'
_bd_ck "the output lacks [  protected  main requires the gate]" _bd_has "$(_bd_out a25y)" '  protected  main requires the gate'
_bd_exit a25y 0
_bd_end "b15 A25 (B13, B14): a protection requiring only gate-lint reads [ ] does not require the gate, and --yes adds gate with one POST to its required contexts, no PUT, and exits 0"

_bd_fix _bd_ctl; _bd_prot 0 "$_bd_P4" ''
printf '%s\n' '{"message":"Required status checks not enabled","status":"404"}' > "$_bd_T/ctl/post.out"
printf 'gh: Required status checks not enabled (HTTP 404)\n' > "$_bd_T/ctl/post.err"; printf '1\n' > "$_bd_T/ctl/post.rc"
_bd_run a26y "$_bd_G" --yes
_bd_ck "--yes wrote [$(_bd_wl a26y)], not the one POST and no PUT" _bd_eq "$(_bd_wl a26y)" "$_bd_POST"
_bd_ck "no line starts [  FAILED     protection on main: ] holding [Required status checks not enabled]" \
  _bd_eq "$(_bd_line a26y '  FAILED     protection on main: ' 'Required status checks not enabled')" yes
_bd_exit a26y 1
_bd_end "b15 A26 (B14, B18): a protection with no required checks gets one POST and no PUT, and a POST that fails prints FAILED     protection on main: with gh's message and exits 1"

_bd_fix _bd_ctl
printf 'gh: Resource not accessible by integration (HTTP 403)\n' > "$_bd_T/ctl/put.err"; printf '1\n' > "$_bd_T/ctl/put.rc"
_bd_run a27y "$_bd_G" --yes
_bd_ck "no line starts [  FAILED     protection on main: ] holding [Resource not accessible by integration]" \
  _bd_eq "$(_bd_line a27y '  FAILED     protection on main: ' 'Resource not accessible by integration')" yes
_bd_ck "a line says admin rights needed" _bd_lacks "$(_bd_out a27y)" 'admin rights needed'
_bd_exit a27y 1
_bd_end "b15 A27 (B14, B18): a PUT that fails prints FAILED     protection on main: with gh's message, never admin rights needed, and --yes exits 1"

# ---- the labels (B15, B16)
_bd_fix _bd_ctl
{ LC_ALL=C awk 'BEGIN { for (i = 1; i <= 30; i++) printf "old-%d\tdesc\t#ededed\n", i }'; _bd_five; } > "$_bd_T/ctl/labels"
_bd_run a28p "$_bd_G"; _bd_run a28y "$_bd_G" --yes
_bd_rowis a28p labels x
_bd_ck "plan: [$(_bd_ll a28p)], not every label list holding --limit 1000" _bd_eq "$(_bd_ll a28p)" ok
_bd_ck "--yes: [$(_bd_ll a28y)], not every label list holding --limit 1000" _bd_eq "$(_bd_ll a28y)" ok
_bd_ck "--yes made $(_bd_cnt a28y 'label create') label create(s)" _bd_eq "$(_bd_cnt a28y 'label create')" 0
_bd_end "b15 A28 (B15): the five labels after thirty others are read with --limit 1000: [x] labels, and --yes creates none"

_bd_l3() { printf '%s\tdesc\t#ededed\n' needs-founder needs-architecture risk-green > "$_bd_T/ctl/labels"; }
_bd_fix _bd_ctl; _bd_l3
_bd_run a29p "$_bd_G"; _bd_run a29y "$_bd_G" --yes
_bd_rowis a29p labels ' ' risk-yellow risk-red
_bd_ck "--yes made $(_bd_cnt a29y 'label create') label creates, not 2" _bd_eq "$(_bd_cnt a29y 'label create')" 2
_bd_ck "no one create of risk-yellow holds --color FBCA04" _bd_eq "$(_bd_cr a29y risk-yellow --color FBCA04)" yes
_bd_ck "no one create of risk-yellow holds --repo fixture/app" _bd_eq "$(_bd_cr a29y risk-yellow --repo fixture/app)" yes
_bd_ck "no one create of risk-red holds --color B60205" _bd_eq "$(_bd_cr a29y risk-red --color B60205)" yes
_bd_ck "no one create of risk-red holds --repo fixture/app" _bd_eq "$(_bd_cr a29y risk-red --repo fixture/app)" yes
_bd_ck "the output lacks [  created    label risk-yellow]" _bd_has "$(_bd_out a29y)" '  created    label risk-yellow'
_bd_ck "the output lacks [  created    label risk-red]" _bd_has "$(_bd_out a29y)" '  created    label risk-red'
_bd_ck "the output says created    5 labels" _bd_lacks "$(_bd_out a29y)" 'created    5 labels'
_bd_end "b15 A29 (B15, B16): two missing labels read [ ] labels naming both, and --yes creates exactly those two with today's colours, saying created    label for each and never created    5 labels"

_bd_fix _bd_ctl; _bd_l3
printf '1\n' > "$_bd_T/ctl/create.risk-red.rc"; printf 'HTTP 422: Validation Failed\n' > "$_bd_T/ctl/create.err"
_bd_run a30y "$_bd_G" --yes
_bd_ck "the output lacks [  created    label risk-yellow]" _bd_has "$(_bd_out a30y)" '  created    label risk-yellow'
_bd_ck "no line starts [  FAILED     label risk-red: ] holding [Validation Failed]" \
  _bd_eq "$(_bd_line a30y '  FAILED     label risk-red: ' 'Validation Failed')" yes
_bd_ck "the output says created    label risk-red" _bd_lacks "$(_bd_out a30y)" 'created    label risk-red'
_bd_exit a30y 1
_bd_end "b15 A30 (B16, B18): a label create that fails prints FAILED     label risk-red: with gh's message, the other still says created, and --yes exits 1"

_bd_fix _bd_ctl
printf 'error connecting to api.github.com\n' > "$_bd_T/ctl/list.err"; printf '1\n' > "$_bd_T/ctl/list.rc"
_bd_run a31p "$_bd_G"; _bd_run a31y "$_bd_G" --yes
_bd_rowis a31p labels '?' 'could not be read'
_bd_ck "--yes made $(_bd_cnt a31y 'label create') label create(s)" _bd_eq "$(_bd_cnt a31y 'label create')" 0
_bd_exit a31y 1
_bd_end "b15 A31 (B15, B18): a label list that fails reads [?] labels could not be read, and --yes creates none and exits 1"

_bd_fix _bd_ctl
LC_ALL=C awk 'BEGIN { for (i = 1; i <= 1000; i++) printf "other-%d\tdesc\t#ededed\n", i }' > "$_bd_T/ctl/labels"
_bd_run a32p "$_bd_G"; _bd_run a32y "$_bd_G" --yes
_bd_rowis a32p labels '?'
_bd_ck "--yes made $(_bd_cnt a32y 'label create') label create(s)" _bd_eq "$(_bd_cnt a32y 'label create')" 0
_bd_end "b15 A32 (B15): a list of 1000 labels without the five may be cut: [?] labels, and --yes creates none"

# ---- every run of this part (B17, B20)
_bd_ck "control: no plan run was checked" [ "$_bd_np" -gt 0 ]
_bd_ck "${_bd_a33#; }" _bd_eq "$_bd_a33" ""
_bd_end "b15 A33 (B17, control): no plan run asks gh to write (no -X, no --method, no label create) or leaves a change in G or in W"

_bd_x="$(LC_ALL=C awk "$_bd_cls"'
  { c = cls(); split(c, a, " "); g = 0
    if (c == "list" || a[1] == "create") g = 1
    else if (a[1] == "GET" && a[2] == "repos/fixture/app") g = 1
    else if ((a[1] == "GET" || a[1] == "PUT") && a[2] ~ /^repos\/fixture\/app\/branches\/.+\/protection$/) g = 1
    else if (a[1] == "POST" && a[2] ~ /\/protection\/required_status_checks\/contexts$/) g = 1
    for (i = 1; i <= NF; i++) if ($i == "-q" || $i == "-t") g = 0
    if (index($0, "--jq") || index($0, "--json") || index($0, "--template") || index($0, "--paginate") || index($0, "--search")) g = 0
    if (!g) print "[" $0 "]" }' "$_bd_T/all.log" 2>&1)"
_bd_ck "control: no gh call was logged in this part" test -s "$_bd_T/all.log"
_bd_ck "gh calls outside the contract's: $_bd_x" _bd_eq "$_bd_x" ""
_bd_end "b15 A34 (B20, B11, B15, control): every gh call bootstrap made is one of the contract's reads and writes, with no --jq, --json, --template, --paginate, --search, -q or -t"
