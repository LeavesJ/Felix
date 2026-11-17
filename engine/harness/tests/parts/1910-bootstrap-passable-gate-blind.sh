printf '\nbootstrap protects a branch only with a gate CI can pass (audit b15, A1-A16, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b15-bootstrap-protects-the-right-
# branch-with.md (sections 2 to 4) alone. No engine code was read: felix bootstrap is run as a black
# box, from the directory of a fixture repository, with a gh stub first on PATH. One assertion per
# contract item, A1 to A16, each named for the behaviour; a control the contract marks is folded into
# its item and said in the detail when it fails.
#
# Fixture F1, all under $TMP/bp1910 (physical paths), every git write through _fx_git:
#   E   felix: main, origin https://github.com/fixture/felix.git (never fetched), one empty commit,
#       origin/main at it and origin/HEAD naming it; engine/harness a copy of $FROOT/harness and
#       projects/app/project.json, both untracked (the stranger state). Merged: projects/ committed
#       and origin/main moved there. No remote: merged, origin removed, origin/main set back.
#   H   home-out: projects/app/project.json alone, a home outside E.
#   G0  a fresh repository, origin https://github.com/fixture/app.git, one empty commit, origin/main
#       and origin/HEAD at it; app by remote_match. G: G0 with gate.yml (name: gate) and
#       .claude/settings.json committed and on origin/main. Gp: G whose gate.yml also holds the
#       placeholder ref line. Gx: no remote, a .felix holding app.
# The gh stub (section 4) logs each call as one line of gh.log, saves the standard input of a call
# given --input - to gh.in.<its line>, and answers from ctl/: repo, prot, put, post, list, create.
_bp_T="$TMP/bp1910"; mkdir -p "$_bp_T"; _bp_T="$(cd "$_bp_T" && pwd -P)"
_bp_E="$_bp_T/felix"; _bp_H="$_bp_T/home-out"; _bp_G="$_bp_T/g"; _bp_GP="$_bp_T/gp"; _bp_GX="$_bp_T/gx"
mkdir -p "$_bp_T/bin" "$_bp_T/ctl" "$_bp_T/u" "$_bp_T/run" "$_bp_E/engine" "$_bp_E/projects/app" "$_bp_H/projects/app"
cat > "$_bp_T/bin/gh" <<'BP1910GHSTUB'
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
BP1910GHSTUB
chmod +x "$_bp_T/bin/gh"

# ---- helpers: fixture git, the stub's answers, one run, and the readers of a run
_bp_fx=""   # fixture steps that failed: every assertion after one fails, saying which
_bp_fix() { "$@" || _bp_fx="$_bp_fx [$*]"; }
_bp_git() { _fx_git "$@" >/dev/null 2>&1; }
_bp_ci() { _bp_git "$1" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -q --allow-empty -m "$2"; }
_bp_repo() {  # DIR URL: main, origin URL, one empty commit, origin/main at it and origin/HEAD naming it
  mkdir -p "$1" && _bp_git "$1" init -q -b main && _bp_git "$1" remote add origin "$2" && _bp_ci "$1" init \
    && _bp_git "$1" update-ref refs/remotes/origin/main HEAD \
    && _bp_git "$1" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
}
_bp_land() { _bp_git "$1" add -A && _bp_ci "$1" "$2" && _bp_git "$1" update-ref refs/remotes/origin/main HEAD; }
_bp_g0() { _bp_repo "$_bp_T/$1" https://github.com/fixture/app.git; }
_bp_P1='{"url":"https://api.github.com/repos/fixture/app/branches/main/protection","required_status_checks":{"url":"https://api.github.com/repos/fixture/app/branches/main/protection/required_status_checks","strict":true,"contexts":["gate"],"contexts_url":"https://api.github.com/repos/fixture/app/branches/main/protection/required_status_checks/contexts","checks":[{"context":"gate","app_id":15368}]},"required_pull_request_reviews":{"dismiss_stale_reviews":true,"required_approving_review_count":0},"enforce_admins":{"url":"https://api.github.com/repos/fixture/app/branches/main/protection/enforce_admins","enabled":true},"allow_force_pushes":{"enabled":false}}'
_bp_body='{"required_status_checks":{"strict":false,"contexts":["gate"]},"enforce_admins":false,"required_pull_request_reviews":null,"restrictions":null,"allow_force_pushes":false,"allow_deletions":false}'
_bp_ctl() {  # the stub's answers back to the contract's defaults: main, not protected, the five labels
  [ -n "$_bp_T" ] && [ -d "$_bp_T/ctl" ] || return 1
  rm -f "$_bp_T"/ctl/*
  printf '{"default_branch":"main"}\n' > "$_bp_T/ctl/repo.out"
  printf '%s' '{"message":"Branch not protected","documentation_url":"https://docs.github.com/rest/branches/branch-protection#get-branch-protection","status":"404"}' > "$_bp_T/ctl/prot.out"
  printf 'gh: Branch not protected (HTTP 404)\n' > "$_bp_T/ctl/prot.err"; printf '1\n' > "$_bp_T/ctl/prot.rc"
  printf '{}\n' > "$_bp_T/ctl/put.out"; printf '{}\n' > "$_bp_T/ctl/post.out"
  printf '%s\tdesc\t#ededed\n' needs-founder needs-architecture risk-green risk-yellow risk-red > "$_bp_T/ctl/labels"
}
_bp_p1() { _bp_ctl && printf '%s' "$_bp_P1" > "$_bp_T/ctl/prot.out" && printf '0\n' > "$_bp_T/ctl/prot.rc" && rm -f "$_bp_T/ctl/prot.err"; }
_bp_run() {  # ID DIR HOME [--yes]: one bootstrap run; its output, exit status, gh.log and saved inputs under run/
  local id="$1" d="$2" hd="$3" f; shift 3
  [ -n "$_bp_T" ] || return 1
  rm -f "$_bp_T"/gh.in.*; : > "$_bp_T/gh.log"
  if [ -n "$d" ] && [ -d "$d" ]; then
    ( _fx_cd "$d" && HOME="$_bp_T/u" FELIX_HOME="$hd" PATH="$_bp_T/bin:$PATH" "$_bp_E/engine/harness/felix" bootstrap "$@" ) \
      > "$_bp_T/run/$id.out" 2>&1
    printf '%s\n' "$?" > "$_bp_T/run/$id.rc"
  else printf 'no directory [%s] to run in\n' "$d" > "$_bp_T/run/$id.out"; printf 'not-run\n' > "$_bp_T/run/$id.rc"; fi
  cp "$_bp_T/gh.log" "$_bp_T/run/$id.log"
  for f in "$_bp_T"/gh.in.*; do [ ! -f "$f" ] || cp "$f" "$_bp_T/run/$id.${f##*/}"; done
}
_bp_rc()  { cat "$_bp_T/run/$1.rc" 2>/dev/null || printf 'unread'; }
_bp_out() { cat "$_bp_T/run/$1.out" 2>/dev/null || printf '[no output file for %s]' "$1"; }
_bp_ran() { [ -s "$_bp_T/run/$1.out" ] && case "$(_bp_rc "$1")" in ''|*[!0123456789]*) return 1 ;; esac; }
_bp_val() {  # ID LABEL -> the value of the first line starting LABEL, its leading blanks dropped
  LC_ALL=C awk -v l="$2" 'index($0, l) == 1 { v = substr($0, length(l) + 1); sub(/^[ \t]+/, "", v); print v; exit }' "$_bp_T/run/$1.out" 2>/dev/null; }
_bp_next() {  # ID PREFIX -> the line after the first line starting PREFIX
  LC_ALL=C awk -v l="$2" 'f { print; exit } index($0, l) == 1 { f = 1 }' "$_bp_T/run/$1.out" 2>/dev/null; }
_bp_row() {  # ID NAME -> the first row line, `  [M] NAME ...`
  LC_ALL=C awk -v n="$2" 'substr($0, 1, 3) == "  [" && substr($0, 5, 2) == "] " && index(substr($0, 7), n) == 1 { print; exit }' "$_bp_T/run/$1.out" 2>/dev/null; }
_bp_line() {  # ID PREFIX SUB -> yes when a line starts PREFIX and holds SUB
  LC_ALL=C awk -v p="$2" -v s="$3" 'index($0, p) == 1 && index($0, s) { y = 1 } END { print (y ? "yes" : "no") }' "$_bp_T/run/$1.out" 2>/dev/null; }
_bp_both() {  # ID A B -> yes when one line holds both
  LC_ALL=C awk -v a="$2" -v b="$3" 'index($0, a) && index($0, b) { y = 1 } END { print (y ? "yes" : "no") }' "$_bp_T/run/$1.out" 2>/dev/null; }
_bp_wfref() {  # DIR -> the line after `repository: fixture/felix` in DIR's gate.yml, blanks removed
  LC_ALL=C awk 'f { gsub(/[ \t]/, ""); print; exit } index($0, "repository: fixture/felix") { f = 1 }' "$1/.github/workflows/gate.yml" 2>/dev/null; }
# A gh.log line as METHOD PATH (api), list, create NAME, or other. A write is a create, or an api call
# whose method is not GET.
_bp_cls='function cls(   i, m, p, w) {
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
_bp_wl() {  # ID -> the run's writes, each followed by |, or [no log]
  [ -f "$_bp_T/run/$1.log" ] || { printf '[no log for %s]' "$1"; return; }
  LC_ALL=C awk "$_bp_cls"' { c = cls() } wr(c) { printf "%s|", c }' "$_bp_T/run/$1.log" 2>/dev/null; }
_bp_pw() {  # ID -> the run's protection writes, each followed by |
  [ -f "$_bp_T/run/$1.log" ] || { printf '[no log for %s]' "$1"; return; }
  LC_ALL=C awk "$_bp_cls"' { c = cls() } wr(c) && index(c, "/protection") { printf "%s|", c }' "$_bp_T/run/$1.log" 2>/dev/null; }
_bp_in() {  # ID -> the saved input of the run's first write, blanks and line breaks removed
  local n; n="$(LC_ALL=C awk "$_bp_cls"' wr(cls()) { print NR; exit }' "$_bp_T/run/$1.log" 2>/dev/null)"
  if [ -n "$n" ] && [ -f "$_bp_T/run/$1.gh.in.$n" ]; then LC_ALL=C tr -d ' \t\r\n' < "$_bp_T/run/$1.gh.in.$n"; else printf '[no input saved]'; fi; }
# One assertion: each _bp_ck that fails adds its words to the detail; _bp_end says ok or bad once.
_bp_f=""
_bp_ck()  { local d="$1"; shift; "$@" || _bp_f="$_bp_f; $d"; }
_bp_end() { [ -z "$_bp_fx" ] || _bp_f="$_bp_f; fixture steps failed:$_bp_fx"
            if [ -z "$_bp_f" ]; then ok "$1"; else bad "$1" "${_bp_f#; }"; fi; _bp_f=""; }
_bp_has()   { case "$1" in *"$2"*) return 0 ;; esac; return 1; }
_bp_lacks() { ! _bp_has "$1" "$2"; }
_bp_pre()   { case "$1" in "$2"*) return 0 ;; esac; return 1; }
_bp_eq()    { [ "$1" = "$2" ]; }
_bp_exit()  { _bp_ck "run $1 did not run or printed nothing" _bp_ran "$1"; _bp_ck "run $1 exited $(_bp_rc "$1"), not $2" _bp_eq "$(_bp_rc "$1")" "$2"; }
_bp_nowrite() { _bp_ck "run $1 wrote [$(_bp_wl "$1")]" _bp_eq "$(_bp_wl "$1")" ""; }

# ---- the stranger state: E holds projects/app untracked
_bp_fix _bp_repo "$_bp_E" https://github.com/fixture/felix.git
_bp_fix cp -R "$FROOT/harness" "$_bp_E/engine/harness"
for _bp_d in "$_bp_E" "$_bp_H"; do
  printf '%s\n' '{"name": "app", "remote_match": "github.com/fixture/app", "gate": "true"}' > "$_bp_d/projects/app/project.json"
done
_bp_h0="$(_fx_git "$_bp_E" rev-parse HEAD 2>/dev/null)"; [ -n "$_bp_h0" ] || _bp_h0=unread-E-HEAD
_bp_fix _bp_g0 g; mkdir -p "$_bp_G/.github/workflows" "$_bp_G/.claude"
printf 'name: gate\n' > "$_bp_G/.github/workflows/gate.yml"
printf '%s\n' '{"permissions":{"deny":["Read(./.env)"]}}' > "$_bp_G/.claude/settings.json"
_bp_fix _bp_land "$_bp_G" 'gate and settings'
_bp_fix _bp_ctl

_bp_run a1 "$_bp_G" "$_bp_E"
_bp_x="$(_bp_next a1 'felix ref:')"; _bp_r="$(_bp_val a1 'felix ref:')"
_bp_exit a1 0
_bp_ck "control: felix ref: [$_bp_r] lacks {{FELIX_REF}}" _bp_has "$_bp_r" '{{FELIX_REF}}'
_bp_ck "the line after felix ref: [$_bp_x] does not start [ci project:  none: ]" _bp_pre "$_bp_x" 'ci project:  none: '
_bp_ck "it lacks [no commit is pinned]" _bp_has "$_bp_x" 'no commit is pinned'
_bp_ck "it lacks [projects/app]" _bp_has "$_bp_x" 'projects/app'
_bp_ck "it lacks [fork]" _bp_has "$_bp_x" 'fork'
_bp_end "b15 A1 (B1): from a stranger's home, plan prints ci project:  none: no commit is pinned right after felix ref:, naming projects/app and a fork"

_bp_x="$(_bp_row a1 protection)"
_bp_ck "run a1 did not run" _bp_ran a1
_bp_ck "the protection row [$_bp_x] does not start [  [ ] protection]" _bp_pre "$_bp_x" '  [ ] protection'
_bp_ck "it lacks [held back]" _bp_has "$_bp_x" 'held back'
_bp_ck "it lacks [CI cannot resolve app]" _bp_has "$_bp_x" 'CI cannot resolve app'
_bp_ck "plan printed Baseline already in place." _bp_lacks "$(_bp_out a1)" 'Baseline already in place.'
_bp_nowrite a1
_bp_end "b15 A2 (B2, B17): and its plan holds protection back, [ ] protection held back because CI cannot resolve app, with no Baseline line and no write"

_bp_run a3 "$_bp_G" "$_bp_E" --yes
_bp_nowrite a3
_bp_ck "no line starts [  skipped    protection (] holding [CI cannot resolve app]" \
  _bp_eq "$(_bp_line a3 '  skipped    protection (' 'CI cannot resolve app')" yes
_bp_exit a3 1
_bp_end "b15 A3 (B2, B18): and its --yes makes no write, prints skipped    protection ( naming CI cannot resolve app, and exits 1"

_bp_run a4 "$_bp_G" "$_bp_H"
_bp_r="$(_bp_val a4 'felix ref:')"; _bp_x="$(_bp_val a4 'ci project:')"
_bp_ck "run a4 did not run" _bp_ran a4
_bp_ck "control: felix ref: [$_bp_r] is not E's HEAD [$_bp_h0]" _bp_eq "$_bp_r" "$_bp_h0"
_bp_ck "the ci project: value [$_bp_x] does not start [none: ]" _bp_pre "$_bp_x" 'none: '
_bp_ck "it lacks [the pinned commit does not hold projects/app]" _bp_has "$_bp_x" 'the pinned commit does not hold projects/app'
_bp_ck "it lacks [fork]" _bp_has "$_bp_x" 'fork'
_bp_end "b15 A4 (B1): with the home outside the engine checkout, felix ref: is E's HEAD and ci project: says the pinned commit does not hold projects/app, naming a fork"

_bp_run a5 "$_bp_G" "$_bp_H" --yes
_bp_nowrite a5; _bp_exit a5 1
_bp_end "b15 A5 (B2, B18): and --yes with that home makes no write and exits 1"

_bp_fix _bp_g0 g0a
_bp_run a6 "$_bp_T/g0a" "$_bp_E" --yes
_bp_r="$(_bp_wfref "$_bp_T/g0a")"; _bp_x="$(_bp_next a6 '  wrote      .github/workflows/gate.yml')"
_bp_ck "run a6 did not run" _bp_ran a6
_bp_ck "control: the written ref line [$_bp_r] is not [ref:'{{FELIX_REF}}']" _bp_eq "$_bp_r" "ref:'{{FELIX_REF}}'"
_bp_ck "the line after the wrote line [$_bp_x] lacks [{{FELIX_REF}}]" _bp_has "$_bp_x" '{{FELIX_REF}}'
_bp_ck "it lacks [projects/app]" _bp_has "$_bp_x" 'projects/app'
_bp_ck "run a6 made protection writes [$(_bp_pw a6)]" _bp_eq "$(_bp_pw a6)" ""
_bp_end "b15 A6 (B7): a stranger's --yes into a fresh repository writes the placeholder ref and says on the next line that {{FELIX_REF}} needs a commit holding projects/app, with no protection write"

_bp_fix _bp_g0 g0b
_bp_run a7 "$_bp_T/g0b" "$_bp_H" --yes
_bp_r="$(_bp_wfref "$_bp_T/g0b")"; _bp_x="$(_bp_next a7 '  wrote      .github/workflows/gate.yml')"
_bp_ck "run a7 did not run" _bp_ran a7
_bp_ck "control: the written ref line [$_bp_r] is not [ref:'$_bp_h0']" _bp_eq "$_bp_r" "ref:'$_bp_h0'"
_bp_ck "the line after the wrote line [$_bp_x] lacks [projects/app]" _bp_has "$_bp_x" 'projects/app'
_bp_end "b15 A7 (B7): with the home outside the engine checkout, --yes writes E's HEAD as the ref and the line after wrote names projects/app"

_bp_fix _bp_p1
_bp_run a8p "$_bp_G" "$_bp_E"; _bp_run a8y "$_bp_G" "$_bp_E" --yes
_bp_exit a8p 0
_bp_ck "plan printed Baseline already in place." _bp_lacks "$(_bp_out a8p)" 'Baseline already in place.'
_bp_ck "no plan line holds both [cannot pass] and [CI cannot resolve app]" _bp_eq "$(_bp_both a8p 'cannot pass' 'CI cannot resolve app')" yes
_bp_nowrite a8y; _bp_exit a8y 1
_bp_end "b15 A8 (B6, B18): a branch that already requires a gate CI cannot resolve is said to be one it cannot pass, not Baseline already in place, and --yes exits 1 with no write"

# ---- merged: projects/ committed in E, origin/main moved to it
_bp_fix _bp_git "$_bp_E" add projects
_bp_fix _bp_ci "$_bp_E" 'projects/app'
_bp_fix _bp_git "$_bp_E" update-ref refs/remotes/origin/main HEAD
_bp_m="$(_fx_git "$_bp_E" rev-parse HEAD 2>/dev/null)"; [ -n "$_bp_m" ] || _bp_m=unread-merged-HEAD
_bp_fix _bp_ctl

_bp_run a9 "$_bp_G" "$_bp_E"
_bp_x="$(_bp_val a9 'ci project:')"; _bp_r="$(_bp_row a9 protection)"
_bp_ck "run a9 did not run" _bp_ran a9
_bp_ck "the ci project: value [$_bp_x] does not start [projects/app]" _bp_pre "$_bp_x" 'projects/app'
_bp_ck "the protection row [$_bp_r] does not start [  [ ] protection]" _bp_pre "$_bp_r" '  [ ] protection'
_bp_ck "it lacks [require the gate on main]" _bp_has "$_bp_r" 'require the gate on main'
_bp_ck "it holds [held back]" _bp_lacks "$_bp_r" 'held back'
_bp_end "b15 A9 (B1, B2): once projects/app is on E's default branch, ci project: reads projects/app and the protection row reads require the gate on main, not held back"

_bp_run a10 "$_bp_G" "$_bp_E" --yes
_bp_ck "the writes [$(_bp_wl a10)] are not exactly the PUT to main's protection" \
  _bp_eq "$(_bp_wl a10)" 'PUT repos/fixture/app/branches/main/protection|'
_bp_ck "its input [$(_bp_in a10)] is not today's body" _bp_eq "$(_bp_in a10)" "$_bp_body"
_bp_ck "the output lacks [  protected  main requires the gate]" _bp_has "$(_bp_out a10)" '  protected  main requires the gate'
_bp_exit a10 0
_bp_end "b15 A10 (B5, control): ready and unprotected, --yes makes one write, the PUT of today's body to main's protection, prints protected  main requires the gate and exits 0"

_bp_fix _bp_p1
_bp_run a11 "$_bp_G" "$_bp_E"
_bp_ck "plan lacks [Baseline already in place.]" _bp_has "$(_bp_out a11)" 'Baseline already in place.'
_bp_exit a11 0; _bp_nowrite a11
_bp_end "b15 A11 (B6, control): ready, with main already requiring the gate, plan prints Baseline already in place., exits 0 and writes nothing"

_bp_fix _bp_ctl; _bp_fix _bp_g0 g0c
_bp_run a12p "$_bp_T/g0c" "$_bp_E"
_bp_x="$(_bp_row a12p protection)"
_bp_ck "run a12p did not run" _bp_ran a12p
_bp_ck "the plan's protection row [$_bp_x] lacks [held back]" _bp_has "$_bp_x" 'held back'
_bp_ck "it lacks [.github/workflows/gate.yml is not on origin/main]" _bp_has "$_bp_x" '.github/workflows/gate.yml is not on origin/main'
_bp_run a12y "$_bp_T/g0c" "$_bp_E" --yes
_bp_r="$(_bp_wfref "$_bp_T/g0c")"
_bp_ck "control: the written ref line [$_bp_r] is not [ref:'$_bp_m']" _bp_eq "$_bp_r" "ref:'$_bp_m'"
_bp_ck "--yes made protection writes [$(_bp_pw a12y)]" _bp_eq "$(_bp_pw a12y)" ""
_bp_ck "no line starts [  skipped    protection (] holding [is not on origin/main]" \
  _bp_eq "$(_bp_line a12y '  skipped    protection (' 'is not on origin/main')" yes
_bp_exit a12y 0
_bp_end "b15 A12 (B3, B18): while the workflow is not on origin/main protection waits: plan says so, and --yes writes the workflow at E's HEAD, skips protection naming why, and exits 0"

_bp_fix _bp_land "$_bp_T/g0c" 'the files bootstrap wrote'
_bp_run a13 "$_bp_T/g0c" "$_bp_E" --yes
_bp_ck "the writes [$(_bp_wl a13)] are not exactly the PUT to main's protection" \
  _bp_eq "$(_bp_wl a13)" 'PUT repos/fixture/app/branches/main/protection|'
_bp_ck "the output lacks [  protected  main requires the gate]" _bp_has "$(_bp_out a13)" '  protected  main requires the gate'
_bp_exit a13 0
_bp_end "b15 A13 (B3, B5, control): once that workflow is committed and on origin/main, --yes protects main with one PUT and exits 0"

_bp_fix _bp_g0 gp; mkdir -p "$_bp_GP/.github/workflows" "$_bp_GP/.claude"
printf "name: gate\n          ref: '{{FELIX_REF}}'\n" > "$_bp_GP/.github/workflows/gate.yml"
printf '%s\n' '{"permissions":{"deny":["Read(./.env)"]}}' > "$_bp_GP/.claude/settings.json"
_bp_fix _bp_land "$_bp_GP" 'gate with the placeholder'
_bp_run a14p "$_bp_GP" "$_bp_E"; _bp_run a14y "$_bp_GP" "$_bp_E" --yes
_bp_x="$(_bp_row a14p protection)"
_bp_ck "run a14p did not run" _bp_ran a14p
_bp_ck "the plan's protection row [$_bp_x] lacks [held back]" _bp_has "$_bp_x" 'held back'
_bp_ck "it lacks [{{FELIX_REF}}]" _bp_has "$_bp_x" '{{FELIX_REF}}'
_bp_nowrite a14y
_bp_ck "no line starts [  skipped    protection (] holding [still reads {{FELIX_REF}}]" \
  _bp_eq "$(_bp_line a14y '  skipped    protection (' 'still reads {{FELIX_REF}}')" yes
_bp_exit a14y 1
_bp_end "b15 A14 (B4, B18): a workflow on origin/main that still reads {{FELIX_REF}} holds protection back, and --yes says still reads {{FELIX_REF}}, writes nothing and exits 1"

# ---- no remote: merged, origin removed, origin/main set back to the merged commit
_bp_fix _bp_git "$_bp_E" remote remove origin
_bp_fix _bp_git "$_bp_E" update-ref refs/remotes/origin/main "$_bp_m"
_bp_run a15 "$_bp_G" "$_bp_E" --yes
_bp_fix _bp_g0 g0d
_bp_run a15b "$_bp_T/g0d" "$_bp_E" --yes
_bp_r="$(_bp_val a15 'felix repo:')"; _bp_x="$(_bp_val a15 'ci project:')"
_bp_ck "control: felix repo: [$_bp_r] is not [none, CI cannot fetch the harness]" _bp_eq "$_bp_r" 'none, CI cannot fetch the harness'
_bp_ck "the ci project: value [$_bp_x] lacks [Felix has no GitHub remote for CI to fetch]" _bp_has "$_bp_x" 'Felix has no GitHub remote for CI to fetch'
_bp_nowrite a15; _bp_exit a15 1
_bp_ck "control: the fresh repository's run lacks [  skipped    ci-workflow (Felix has no remote for CI to fetch)]" \
  _bp_eq "$(_bp_line a15b '  skipped    ci-workflow (Felix has no remote for CI to fetch)' 'skipped')" yes
_bp_nowrite a15b
_bp_end "b15 A15 (B8, B2): with no Felix remote, ci project: says so and protection is held back with no write and exit 1, and a fresh repository's workflow is skipped as today"
# restored: the remote, origin/main and origin/HEAD
_bp_fix _bp_git "$_bp_E" remote add origin https://github.com/fixture/felix.git
_bp_fix _bp_git "$_bp_E" update-ref refs/remotes/origin/main "$_bp_m"
_bp_fix _bp_git "$_bp_E" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main

mkdir -p "$_bp_GX"; _bp_fix _bp_git "$_bp_GX" init -q -b main; _bp_fix _bp_ci "$_bp_GX" init
printf 'app\n' > "$_bp_GX/.felix"
_bp_run a16 "$_bp_GX" "$_bp_E"
_bp_ck "run a16 did not run" _bp_ran a16
_bp_ck "control: the run's log is missing" test -f "$_bp_T/run/a16.log"
_bp_ck "control: gh was asked [$(tr '\n' '|' < "$_bp_T/run/a16.log" 2>/dev/null)]" test ! -s "$_bp_T/run/a16.log"
_bp_ck "control: no line starts [  [-] github]" _bp_eq "$(_bp_line a16 '  [-] github' 'github')" yes
_bp_ck "no line starts [ci project:  projects/app]" _bp_eq "$(_bp_line a16 'ci project:  projects/app' 'projects/app')" yes
_bp_end "b15 A16 (B19): a repository with no GitHub remote asks gh nothing, prints the [-] github line and ci project:  projects/app"
