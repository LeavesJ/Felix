# >>> merge-judge-handoff
printf '\nfelix merge hands the verdict to the engine main holds (audit b13, contract A1-A22, blind)\n'
# Blind, written on 2026-10-24 from the b13 contract alone (b13-felix-cli-trust-and-binding.md, the
# audit register of 2026-10-24, batch 13: C067 and C063; B1-B15, A1-A22). Not read: engine/harness/felix,
# lib/*.sh, hooks, bin, projects/*/gate.sh. How to drive felix merge was learned from parts 0340, 0360,
# 1400 and 1402 and from tests/lib/judge-refs.sh. Every fixture is this part's own, under $B13; its
# projects b13s, b13m and b13p in $FROOT and their memory are removed at its end.
#
# S, a stub main: checkout R (.felix b13s, a github origin, .gitignore *.log and .DS_Store). Main, which
# is refs/remotes/origin/main, holds under engine/ plugin.json at 1.0.0, harness/felix (the stub below),
# the real lib/resolve.sh, lib/zz-only-main.txt and tests/keep.txt; b13s-candidate, checked out, holds
# the real harness at 2.0.0; b13s-nofelix, at 3.0.0, has no harness/felix. The entries KS/1.0.0 (plus a
# residue harness/zz.log) and KS/3.0.0 are cut from those commits as _js_entry cuts one. The stub logs
# where it ran, as what and on what (each regular file under its version directory, with its blob id and
# whether its owner may run it), prints MAIN-STUB ran and MAIN-STUB err, and exits B13_STUB_RC (7).
# M, a real main: checkout Q as _js_build builds one (project b13m), whose main's lib/escape.sh ends by
# logging its own path to B13_ESCLOG; b13m-candidate bumps to 2.0.0, says CANDIDATE-VERDICT where main
# says felix merge would squash this now., and adds B13EXEC.txt. P, a product, as 0340's MR, project b13p.
#
# Readings, where the contract leaves room. Every run gets an empty TMPDIR of its own (physical), a
# scratch HOME with no .felix-home, and FELIX_KERNEL and FELIX_MERGE_HANDED unset unless a case sets
# them; gh is a stub logging each call's arguments NUL-separated, a file per call (0360's shape). A3
# runs each setting alone. R sets diff.renames false, so that in A5 the copy is the only reader of the
# deleted blob, and maintenance.auto false: git 2.54's detached auto maintenance after a large commit
# packed every loose object, the A5 blob among them (measured 2026-10-24). A7 and A8 start felix merge in a process group of its own (perl setpgrp), so a signal it
# sends its group cannot reach the suite, and end anything still running by its pid. "Every B13_ESCLOG
# line" (A14, A19) is held to at least one line. A17 compares the escalated count and the refused rows'
# blocker kinds. A20's runs are dry runs. A22 skips where this harness is not a checkout's engine/harness.
B13="$TMP/b13"; rm -rf "$B13"; mkdir -p "$B13/gh" "$B13/home" "$B13/t" "$B13/r" "$B13/q" "$B13/p" "$B13/ks" "$B13/km"
B13="$(cd "$B13" && pwd -P)"; B13H="$B13/home"; B13R="$B13/r"; B13Q="$B13/q"; B13P="$B13/p"; B13KS="$B13/ks"; B13KM="$B13/km"
B13_TN=0; B13_T=""; B13RC=0; B13_LEFT=""; B13_YS=0; B13_YM=0; B13_DIR=""; B13_CMD=(true); B13_BGC=""; B13_BGV=""; B13_BGL=""
B13_SDRY=(merge --dry-run --base refs/remotes/origin/main)
cat > "$B13/gh/gh" <<'B13GH'
#!/usr/bin/env bash
d="${B13_GHDIR:?B13_GHDIR is not set}"; mkdir -p "$d"
n=0; for f in "$d"/call.*; do [ -e "$f" ] && n=$((n + 1)); done
f="$d/call.$(printf '%03d' "$((n + 1))")"
: > "$f"; for a in "$@"; do printf '%s\0' "$a" >> "$f"; done
# The provider's two reads at the merge (lib/bind.sh, spec S5.2), answered with git at call time from the checkout
# the stub runs in: the pull request open at this HEAD into main, and main at the commit it names here.
case "$*" in
  "pr view "*"--json number,state,baseRefName,headRefOid"*)
    printf '7\tOPEN\t%s\t%s\n' "${GHSTUB_BASE:-main}" "$(git rev-parse HEAD)"; exit 0 ;;
  "api repos/"*"/git/ref/heads/"*)
    n="${2#*/git/ref/heads/}"
    printf 'commit\t%s\n' "$(git rev-parse --verify -q "refs/remotes/origin/$n^{commit}" || git rev-parse --verify -q "refs/heads/$n^{commit}")"
    exit 0 ;;
esac
case "${1:-} ${2:-}" in "pr view") printf '{"number":7,"state":"OPEN"}\n' ;; "pr merge") printf 'merged\n' ;; esac
exit 0
B13GH
chmod +x "$B13/gh/gh"

# ------------------------------------------------------------------ helpers ---
_b13_check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]${4:+: $4}"; fi; }   # NAME GOT WANT [DETAIL]
_b13_why() { printf 'exit %s; stdout: %s; stderr: %s' "$B13RC" "$(head -c 600 "$B13/out" | tr '\n' ' ')" "$(head -c 600 "$B13/err" | tr '\n' ' ')"; }
_b13_commit() {   # REPO MSG: one commit of everything, as _jr_commit makes one
  _fx_git "$1" add -A >/dev/null 2>&1
  _fx_git "$1" -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c maintenance.auto=false commit -qm "$2" >/dev/null 2>&1
}
_b13_sha() { git -C "$1" rev-parse --verify -q "$2^{commit}" 2>/dev/null; }
_b13_n() { if [ -f "$2" ]; then LC_ALL=C grep -cF -- "$1" "$2"; else printf '0'; fi; }        # TEXT FILE -> lines holding TEXT
_b13_ni() { LC_ALL=C grep -cF -- "$1"; return 0; }                                             # TEXT -> lines of stdin holding TEXT
_b13_pre() { [ -f "$2" ] || { printf '0'; return 0; }                                          # PREFIX FILE -> lines beginning PREFIX
             LC_ALL=C awk -v p="$1" 'index($0, p) == 1 { n++ } END { print n + 0 }' "$2"; }
_b13_field() { [ -f "$2" ] && LC_ALL=C awk -v k="$1=" 'index($0, k) == 1 { print substr($0, length(k) + 1); exit }' "$2"; return 0; }
_b13_line() { LC_ALL=C awk -v t="$1" 'index($0, t) { print NR; exit }' "$2" 2>/dev/null; }    # TEXT FILE -> first line number
_b13_yn() { if [ "${1:-0}" -gt 0 ] 2>/dev/null; then printf 'yes'; else printf 'no'; fi; }
_b13_files() { [ -f "$1" ] && LC_ALL=C awk -F'\t' '$1 == "file"' "$1" | LC_ALL=C sort; return 0; }
_b13_want() {   # REPO COMMIT -> the file lines a faithful copy of COMMIT's engine/ gives the stub, sorted
  git -C "$1" ls-tree -r "$2" -- engine/ 2>/dev/null | LC_ALL=C awk -F'\t' '{ split($1, m, " "); p = $2; sub(/^engine\//, "", p)
    printf "file\t%s\t%s\t%s\n", p, m[3], (m[1] == "100755" ? "x" : "-") }' | LC_ALL=C sort
}
_b13_same() { if [ -n "$B13S_WANT" ] && [ "$(_b13_files "$1")" = "$B13S_WANT" ]; then printf 'same'; else printf 'differs'; fi; }
_b13_cut() {   # REPO COMMIT DEST [residue]: DEST is COMMIT's engine/, cut as _js_entry cuts an entry, and a harness/zz.log
  local x="$B13/x" d
  rm -rf "$3" "$x" "$x.tar"; mkdir -p "$3" "$x"
  _fx_git "$1" archive -o "$x.tar" "$2" engine >/dev/null 2>&1 && tar -x -C "$x" -f "$x.tar"
  for d in harness hooks commands .claude-plugin; do [ -d "$x/engine/$d" ] && cp -R "$x/engine/$d" "$3/$d"; done
  rm -rf "$x" "$x.tar"
  [ -z "${4:-}" ] || printf 'a log the entry gathered\n' > "$3/harness/zz.log"
}
_b13_project() {   # NAME: a project in FROOT, made as _jr_project makes jrr
  local p="$FROOT/projects/$1"; mkdir -p "$p" "$MEM/$1"
  printf '{\n  "name": "%s",\n  "remote_match": "example.com/%s",\n  "gate": "true"\n}\n' "$1" "$1" > "$p/project.json"
  printf '# %s\n' "$1" > "$p/CLAUDE.md"
  printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$p/probes.tsv"
  printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds\n' > "$p/obligations.tsv"
  printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n' > "$p/commissioning.tsv"
  cp "$REAL_HARNESS/templates/risk.tsv" "$p/risk.tsv"
}
_b13_record() {   # REPO NAME: a green gate receipt and a commissioning stamp for REPO as it stands, as _jr_record records them
  local p="$FROOT/projects/$2"
  ( cd "$1" && . "$FROOT/harness/lib/verify.sh"
    felix_verify_record "$1" "$FROOT" 0 "true" "$(felix_tree_id "$1" "$FROOT")" ) >/dev/null 2>&1
  ( cd "$1" && FELIX_HOME_DIR="$FROOT"; . "$FROOT/harness/lib/commission.sh"
    _o="$(felix_commission_run "$p" "$1" -)"
    felix_commission_receipt_write "$FROOT" "$p" "$1" "$_o" "" ) >/dev/null 2>&1
}
_b13_calls() { local n=0 f; for f in "$B13/calls"/call.*; do [ -e "$f" ] && n=$((n + 1)); done; printf '%s' "$n"; }
_b13_ismerge() { local a="" b=""; { IFS= read -r -d '' a && IFS= read -r -d '' b; } < "$1"; [ "$a $b" = "pr merge" ]; }
_b13_merges() { local n=0 f; for f in "$B13/calls"/call.*; do [ -e "$f" ] && _b13_ismerge "$f" && n=$((n + 1)); done; printf '%s' "$n"; }
_b13_mcall() { local f; for f in "$B13/calls"/call.*; do [ -e "$f" ] && _b13_ismerge "$f" && { printf '%s' "$f"; return 0; }; done; return 0; }
_b13_arg() {   # CALL FLAG -> the flag's value, --flag v or --flag=v; empty when absent
  local a take=0
  [ -f "$1" ] || return 0
  while IFS= read -r -d '' a; do
    if [ "$take" = 1 ]; then printf '%s' "$a"; return 0; fi
    case "$a" in "$2") take=1 ;; "$2"=*) printf '%s' "${a#*=}"; return 0 ;; esac
  done < "$1"
  return 0
}
_b13_lines() { if [ -f "$1" ]; then LC_ALL=C awk 'END { print NR }' "$1"; else printf '0'; fi; }
_b13_new() {   # PROJECT -> the rows the last run added to its says.log
  local f="$MEM/$1/says.log" n="$B13_YM"
  [ "$1" != b13s ] || n="$B13_YS"
  [ -f "$f" ] && LC_ALL=C awk -v n="$n" 'NR > n' "$f"; return 0
}
_b13_judgerows() { _b13_new "$1" | LC_ALL=C awk -F'\t' '$2 == "refused" && index($0, ": judge: ") { n++ } END { print n + 0 }'; }
_b13_tmp() { B13_TN=$((B13_TN + 1)); mkdir -p "$B13/t/$B13_TN"; B13_T="$(cd "$B13/t/$B13_TN" && pwd -P)"; }
_b13_left() {   # LABEL: what the run left in its TMPDIR, onto B13_LEFT
  local l
  if [ ! -d "$B13_T" ]; then B13_LEFT="${B13_LEFT}$1 removed its TMPDIR; "; return 0; fi
  l="$(cd "$B13_T" && LC_ALL=C ls -A | tr '\n' ' ')"
  [ -z "$l" ] || B13_LEFT="${B13_LEFT}$1 left [$l]; "
}
# _b13_prep LABEL DIR PROJECT CACHE FELIX [VAR=value | -u NAME]... -- ARGS...: B13_DIR and B13_CMD, one run of FELIX
# in DIR: the logs emptied, a new TMPDIR, says.log marked, and first a green receipt for PROJECT (- for none).
_b13_prep() {
  local dir="$2" proj="$3" kc="$4" fx="$5" hv="FELIX_HOME=$FROOT" pre e
  pre=(-u FELIX_KERNEL -u FELIX_MERGE_HANDED); e=()
  shift 5
  while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do
    if [ "$1" = "-u" ]; then
      pre[${#pre[@]}]="-u"; pre[${#pre[@]}]="$2"; [ "$2" != FELIX_HOME ] || hv="B13_FELIX_HOME_UNSET=1"; shift 2; continue
    fi
    e[${#e[@]}]="$1"; shift
  done
  [ "${1:-}" != "--" ] || shift
  [ "$proj" = "-" ] || _b13_record "$dir" "$proj"
  _b13_tmp; rm -rf "$B13/calls"; mkdir -p "$B13/calls"; : > "$B13/stub.log"; : > "$B13/esc.log"
  B13_YS="$(_b13_lines "$MEM/b13s/says.log")"; B13_YM="$(_b13_lines "$MEM/b13m/says.log")"
  B13_DIR="$dir"
  B13_CMD=(env "${pre[@]}" HOME="$B13H" PATH="$B13/gh:$PATH" B13_GHDIR="$B13/calls" B13_STUBLOG="$B13/stub.log"
           B13_ESCLOG="$B13/esc.log" FELIX_KERNEL_CACHE="$kc" "$hv" TMPDIR="$B13_T" ${e[@]+"${e[@]}"} "$fx" "$@")
}
_b13_run() { _b13_prep "$@"; ( cd "$B13_DIR" && "${B13_CMD[@]}" ) > "$B13/out" 2> "$B13/err"; B13RC=$?; _b13_left "$1"; }
_b13_s() { local l="$1"; shift; _b13_run "$l" "$B13R" - "$B13KS" "$B13R/engine/harness/felix" "$@" -- "${B13_SDRY[@]}"; }
_b13_mc() { local l="$1"; shift; _b13_run "$l" "$B13Q" b13m "$B13KM" "$B13Q/engine/harness/felix" "$@"; }   # the candidate's felix
_b13_me() { local l="$1"; shift; _b13_run "$l" "$B13Q" b13m "$B13KM" "$B13KM/1.0.0/harness/felix" "$@"; }  # the entry's, in place
_b13_alive() {   # PID -> 0 while it runs; a zombie is not running
  local st
  kill -0 "$1" 2>/dev/null || return 1
  st="$(ps -o stat= -p "$1" 2>/dev/null | tr -d ' ')"
  case "$st" in Z*) return 1 ;; esac
  return 0
}
_b13_end() {   # PID: ended by its pid, TERM and then KILL, when it still runs
  local i=0
  _b13_alive "$1" || return 0
  kill -TERM "$1" 2>/dev/null
  while [ "$i" -lt 20 ] && _b13_alive "$1"; do sleep 0.1; i=$((i + 1)); done
  ! _b13_alive "$1" || kill -KILL "$1" 2>/dev/null
  return 0
}
# _b13_bg SIGNAL LABEL -> B13_BGC (the stub started) and B13_BGV (what followed SIGNAL): fixture S's dry run in the
# background with a sleeping stub, SIGNAL sent to felix merge's pid alone once the stub has started.
_b13_bg() {
  local sig="$1" pid i=0 rc fg sv spid sst="never started" pl='setpgrp(0, 0); exec @ARGV'
  [ "$sig" != INT ] || pl='setpgrp(0, 0); $SIG{INT} = "DEFAULT"; exec @ARGV'
  _b13_prep "$2" "$B13R" - "$B13KS" "$B13R/engine/harness/felix" B13_STUB_SLEEP=1 -- "${B13_SDRY[@]}"
  ( cd "$B13_DIR" && exec perl -e "$pl" "${B13_CMD[@]}" ) > "$B13/out" 2> "$B13/err" &
  pid=$!
  while [ "$i" -lt 200 ]; do
    if [ "$(_b13_pre started "$B13/stub.log")" -gt 0 ]; then sst=started; break; fi
    _b13_alive "$pid" || break
    sleep 0.1; i=$((i + 1))
  done
  B13_BGC="$sst"
  kill -"$sig" "$pid" 2>/dev/null
  i=0
  while [ "$i" -lt 50 ]; do
    if ! _b13_alive "$pid"; then
      spid="$(_b13_field pid "$B13/stub.log")"
      if [ -z "$spid" ] || ! _b13_alive "$spid" || [ "$(_b13_pre signal "$B13/stub.log")" -gt 0 ]; then break; fi
    fi
    sleep 0.1; i=$((i + 1))
  done
  if _b13_alive "$pid"; then fg="still running 5 s after $sig"; else fg=gone; fi
  spid="$(_b13_field pid "$B13/stub.log")"
  if [ -z "$spid" ]; then sv="recorded no pid"
  elif ! _b13_alive "$spid" || [ "$(_b13_pre signal "$B13/stub.log")" -gt 0 ]; then sv=stopped
  else sv="still running"; fi
  _b13_left "$2"; B13_BGL="$(cd "$B13_T" 2>/dev/null && LC_ALL=C ls -A | tr '\n' ' ')"
  _b13_end "$pid"; [ -z "$spid" ] || _b13_end "$spid"
  wait "$pid" 2>/dev/null; rc=$?
  [ "$fg" != gone ] || { [ "$rc" -ne 0 ] && fg="gone, exit non-zero" || fg="gone, exit 0"; }
  B13_BGV="$sst|felix merge $fg|stub $sv|gh=$(_b13_calls)|TMPDIR [$B13_BGL]"
}

# --------------------------------------------------------------- fixture S ---
( _fx_cd "$B13R" && git init -q -b main && git remote add origin https://github.com/example/b13s.git \
  && git config gc.auto 0 && git config maintenance.auto false && git config diff.renames false ) >/dev/null 2>&1
mkdir -p "$B13R/engine/.claude-plugin" "$B13R/engine/harness/lib" "$B13R/engine/harness/tests"
printf '{ "name": "felix", "version": "1.0.0" }\n' > "$B13R/engine/.claude-plugin/plugin.json"
cat > "$B13R/engine/harness/felix" <<'B13STUB'
#!/usr/bin/env bash
# The stub main of audit b13's fixture S (tests part 1870): it says where it ran, as what and on what, then stops.
self="$(cd "$(dirname "$0")" && pwd -P)"; vdir="$(cd "$self/.." && pwd -P)"; log="${B13_STUBLOG:-/dev/null}"
{ printf 'self=%s\ncwd=%s\nargs=%s\n' "$self" "$(pwd -P)" "$*"
  printf 'home=%s\nhanded=%s\npid=%s\n' "${FELIX_HOME-unset}" "${FELIX_MERGE_HANDED-unset}" "$$"; } >> "$log"
( cd "$vdir" && find . -type f -print | LC_ALL=C sort ) | while IFS= read -r f; do
  f="${f#./}"; if [ -x "$vdir/$f" ]; then m=x; else m=-; fi
  printf 'file\t%s\t%s\t%s\n' "$f" "$(git hash-object --no-filters --stdin < "$vdir/$f")" "$m"
done >> "$log"
if [ -n "${B13_STUB_SLEEP:-}" ]; then
  printf 'started\n' >> "$log"
  trap 'printf "signal TERM\n" >> "$log"; exit 143' TERM
  trap 'printf "signal INT\n" >> "$log"; exit 130' INT
  i=0; while [ "$i" -lt 30 ]; do sleep 1; i=$((i + 1)); done
fi
printf 'MAIN-STUB ran\n'; printf 'MAIN-STUB err\n' >&2
exit "${B13_STUB_RC:-7}"
B13STUB
chmod 755 "$B13R/engine/harness/felix"
cp "$REAL_HARNESS/lib/resolve.sh" "$B13R/engine/harness/lib/resolve.sh"
printf 'only main holds this file (audit b13, fixture S)\n' > "$B13R/engine/harness/lib/zz-only-main.txt"
printf 'main keeps a file under tests (audit b13, fixture S)\n' > "$B13R/engine/harness/tests/keep.txt"
printf '*.log\n.DS_Store\n' > "$B13R/.gitignore"; printf 'b13s\n' > "$B13R/.felix"
_b13_commit "$B13R" stub-main; B13S_M="$(_b13_sha "$B13R" HEAD)"
_fx_git "$B13R" update-ref refs/remotes/origin/main "$B13S_M" >/dev/null 2>&1
( _fx_cd "$B13R" && git checkout -q -b b13s-nofelix "$B13S_M" && git rm -q engine/harness/felix ) >/dev/null 2>&1
printf '{ "name": "felix", "version": "3.0.0" }\n' > "$B13R/engine/.claude-plugin/plugin.json"
_b13_commit "$B13R" no-felix; B13S_N="$(_b13_sha "$B13R" HEAD)"
( _fx_cd "$B13R" && git checkout -q -b b13s-candidate "$B13S_M" ) >/dev/null 2>&1
rm -rf "$B13R/engine/harness"; _copy_content "$REAL_HARNESS" "$B13R/engine/harness"
printf '{ "name": "felix", "version": "2.0.0" }\n' > "$B13R/engine/.claude-plugin/plugin.json"
_b13_commit "$B13R" candidate
_b13_cut "$B13R" "$B13S_M" "$B13KS/1.0.0" residue; _b13_cut "$B13R" "$B13S_N" "$B13KS/3.0.0"
B13S_WANT="$(_b13_want "$B13R" "$B13S_M")"; _b13_project b13s
_b13_check "A1-A11 (fixture control): S's main holds the five engine paths the contract names with the stub executable, and the candidate checked out is the real harness at 2.0.0" \
  "$(git -C "$B13R" ls-tree -r --name-only "$B13S_M" -- engine/ 2>&1 | tr '\n' ' ')|$(git -C "$B13R" ls-tree "$B13S_M" engine/harness/felix 2>/dev/null | cut -c1-6)|$(git -C "$B13R" rev-parse --abbrev-ref HEAD 2>&1)|$(cmp -s "$B13R/engine/harness/felix" "$REAL_HARNESS/felix" && echo real)|$(git -C "$B13R" show HEAD:engine/.claude-plugin/plugin.json 2>&1)" \
  "engine/.claude-plugin/plugin.json engine/harness/felix engine/harness/lib/resolve.sh engine/harness/lib/zz-only-main.txt engine/harness/tests/keep.txt |100755|b13s-candidate|real|{ \"name\": \"felix\", \"version\": \"2.0.0\" }"
_b13_check "A1-A11 (fixture control): KS/1.0.0 is main's engine with a residue zz.log, and b13s-nofelix declares 3.0.0 with a lib/ and no harness/felix, as KS/3.0.0 does" \
  "$([ -f "$B13KS/1.0.0/harness/felix" ] && [ -f "$B13KS/1.0.0/harness/zz.log" ] && echo entry)|$(git -C "$B13R" show "$B13S_N:engine/.claude-plugin/plugin.json" 2>&1)|$(git -C "$B13R" ls-tree -r --name-only "$B13S_N" -- engine/harness 2>&1 | tr '\n' ' ')|$([ -d "$B13KS/3.0.0/harness/lib" ] && [ ! -e "$B13KS/3.0.0/harness/felix" ] && echo entry3)" \
  "entry|{ \"name\": \"felix\", \"version\": \"3.0.0\" }|engine/harness/lib/resolve.sh engine/harness/lib/zz-only-main.txt engine/harness/tests/keep.txt |entry3"

# ---------------------------------------------------------- A1-A11, on S ---
_b13_s A1; cp "$B13/stub.log" "$B13/stub.a1"; B13_TA1="$B13_T"
_b13_self="$(_b13_field self "$B13/stub.a1")"
case "$_b13_self" in "$B13_TA1/felix-merge-main."*/1.0.0/harness) _b13_v="a copy under TMPDIR" ;; *) _b13_v="[$_b13_self]" ;; esac
_b13_check "A1 (B1): a self-governed felix merge whose felix is not the installed entry runs main's felix from a copy under TMPDIR, in the same directory, with its own arguments and FELIX_MERGE_HANDED=1; the status and output are the copy's, and gh is not called" \
  "exit=$B13RC|out=$(_b13_yn "$(_b13_n 'MAIN-STUB ran' "$B13/out")")|err=$(_b13_yn "$(_b13_n 'MAIN-STUB err' "$B13/err")")|runs=$(_b13_pre self= "$B13/stub.a1")|self=$_b13_v|cwd=$(_b13_field cwd "$B13/stub.a1")|args=$(_b13_field args "$B13/stub.a1")|handed=$(_b13_field handed "$B13/stub.a1")|gh=$(_b13_calls)" \
  "exit=7|out=yes|err=yes|runs=1|self=a copy under TMPDIR|cwd=$B13R|args=merge --dry-run --base refs/remotes/origin/main|handed=1|gh=0" "$(_b13_why)"
_b13_got="$(_b13_files "$B13/stub.a1")"
_b13_check "A2 (B2): the copy holds exactly the paths main tracks under engine/, byte for byte and with their modes, zz-only-main.txt and tests/keep.txt among them and the entry's zz.log not" \
  "$([ -n "$_b13_got" ] && [ "$_b13_got" = "$B13S_WANT" ] && echo equal)|$(_b13_yn "$(printf '%s\n' "$_b13_got" | _b13_ni 'harness/lib/zz-only-main.txt')")|$(_b13_yn "$(printf '%s\n' "$_b13_got" | _b13_ni 'harness/tests/keep.txt')")|zz.log $(printf '%s\n' "$_b13_got" | _b13_ni zz.log)" \
  "equal|yes|yes|zz.log 0" "$(diff <(printf '%s\n' "$B13S_WANT") <(printf '%s\n' "$_b13_got") 2>&1 | tr '\t\n' '| ' | head -c 900)"
mkdir -p "$B13R/.git/info"; printf '* text eol=crlf\n' > "$B13R/.git/info/attributes"
_b13_s A3-attributes; _b13_a3="attributes:$B13RC,$(_b13_same "$B13/stub.log")"; rm -f "$B13R/.git/info/attributes"
_fx_git "$B13R" config core.autocrlf true >/dev/null 2>&1
_b13_s A3-autocrlf; _b13_a3="$_b13_a3 autocrlf:$B13RC,$(_b13_same "$B13/stub.log")"; _fx_git "$B13R" config --unset core.autocrlf >/dev/null 2>&1
printf '[core]\n\tautocrlf = true\n' > "$B13/gitglobal"
_b13_s A3-global GIT_CONFIG_GLOBAL="$B13/gitglobal"; _b13_a3="$_b13_a3 global:$B13RC,$(_b13_same "$B13/stub.log")"
_b13_a3="$_b13_a3 $([ ! -e "$B13R/.git/info/attributes" ] && [ -z "$(git -C "$B13R" config --get core.autocrlf 2>/dev/null)" ] && echo undone)"
_b13_check "A3 (B2): no byte of the copy changes for eol=crlf in .git/info/attributes, core.autocrlf in the checkout, or core.autocrlf in a global config, each alone, and each is undone after" \
  "$_b13_a3" "attributes:7,same autocrlf:7,same global:7,same undone"
_b13_a4=""
for _b13_c in 0 3 7; do
  _b13_s "A4-rc$_b13_c" B13_STUB_RC="$_b13_c"
  _b13_a4="$_b13_a4 rc$_b13_c:exit=$B13RC,not-known=$(_b13_n 'not known' "$B13/err"),status-line=$(LC_ALL=C awk -v s="status $_b13_c" 'index($0, s) && index($0, "not known") { n++ } END { print n + 0 }' "$B13/err")"
done
_b13_check "A4 (B11): the copy's status 0, 3 and 7 is the command's, and only a status felix merge never returns (7) adds one stderr line naming it and saying the outcome is not known" \
  "$_b13_a4" " rc0:exit=0,not-known=0,status-line=0 rc3:exit=3,not-known=0,status-line=0 rc7:exit=7,not-known=1,status-line=1"
B13_BLOB="$(git -C "$B13R" rev-parse "$B13S_M:engine/harness/lib/zz-only-main.txt" 2>/dev/null)"
B13_OBJ="$B13R/.git/objects/${B13_BLOB:0:2}/${B13_BLOB:2}"
git -C "$B13R" cat-file blob "$B13_BLOB" > "$B13/zz-only-main.keep" 2>/dev/null
_b13_a5c="object $([ -n "$B13_BLOB" ] && [ -f "$B13_OBJ" ] && echo loose || echo absent)"
_b13_s A5-control; _b13_a5c="$_b13_a5c|exit=$B13RC|runs=$(_b13_pre self= "$B13/stub.log")"
_b13_check "A5 (fixture control): the blob of zz-only-main.txt is a loose object, and with it a dry run reaches the stub" "$_b13_a5c" "object loose|exit=7|runs=1"
rm -f "$B13_OBJ"
_b13_s A5-dry
# Since trust step 3, slice 2 (spec S6.3): the blob is in V, the objects the verdict reads, so a merge refuses on it
# by name with one objects blocker (exit 3) before any copy of main's engine is attempted.
_b13_a5="dry: exit=$B13RC,says=$(_b13_yn "$(_b13_n "  objects     $B13_BLOB" "$B13/out")"),runs=$(_b13_pre self= "$B13/stub.log"),gh=$(_b13_calls)"
_b13_run A5-real "$B13R" - "$B13KS" "$B13R/engine/harness/felix" -- merge --base refs/remotes/origin/main
_b13_a5="$_b13_a5 real: exit=$B13RC,objects-rows=$(_b13_new b13s | LC_ALL=C awk -F'\t' '$2 == "refused" && index($0, ": objects: ") { n++ } END { print n + 0 }'),gh=$(_b13_calls)"
_b13_check "A5 (B9): with a blob main's engine tracks missing, felix merge refuses with exit 1, saying it could not copy main's engine, runs nothing, calls no gh, and a real run records one refused judge row" \
  "$(git -C "$B13R" cat-file -e "$B13_BLOB" 2>/dev/null && echo still-there)$_b13_a5" "dry: exit=3,says=yes,runs=0,gh=0 real: exit=3,objects-rows=1,gh=0" "$(_b13_why)"
_b13_check "A5 (fixture control): the object is restored with hash-object -w" \
  "$(_fx_git "$B13R" hash-object -w --stdin < "$B13/zz-only-main.keep" 2>/dev/null)|$(git -C "$B13R" cat-file -e "$B13_BLOB" 2>/dev/null && echo readable)" "$B13_BLOB|readable"
_b13_run A6 "$B13R" - "$B13KS" "$B13R/engine/harness/felix" -- merge --dry-run --base refs/heads/b13s-nofelix
_b13_check "A6 (B9): when main's engine has no harness/felix, felix merge refuses with exit 1, saying so, and calls no gh" \
  "exit=$B13RC|says=$(_b13_yn "$(_b13_n 'no harness/felix' "$B13/err")")|gh=$(_b13_calls)" "exit=1|says=yes|gh=0" "$(_b13_why)"
for _b13_sig in TERM INT; do
  _b13_bg "$_b13_sig" "A7-A8-$_b13_sig"
  case "$_b13_sig" in TERM) _b13_i="A7 (B12)" ;; *) _b13_i="A8 (B12)" ;; esac
  _b13_check "$_b13_i (fixture control): with $_b13_sig not ignored, the sleeping stub has started within 20 s" "$B13_BGC" "started"
  _b13_check "$_b13_i: $_b13_sig to felix merge's pid while the copy runs ends felix merge non-zero within 5 s, the copy stopped, no gh call, and TMPDIR empty" \
    "$B13_BGV" "started|felix merge gone, exit non-zero|stub stopped|gh=0|TMPDIR []" "$(_b13_why)"
done
mkdir -p "$B13R/projects"; cp -R "$FROOT/projects/b13s" "$B13R/projects/b13s"
_b13_s A9 -u FELIX_HOME
_b13_check "A9 (B13): with FELIX_HOME unset and no .felix-home, the copy is handed the home the run felix found from its own location" \
  "pointer=$([ -e "$B13H/.felix-home" ] && echo present || echo none)|home=$(_b13_field home "$B13/stub.log")" "pointer=none|home=$B13R" "$(_b13_why)"
rm -rf "$B13R/projects"
_b13_s A10 FELIX_MERGE_HANDED=1
_b13_check "A10 (B7): a non-empty FELIX_MERGE_HANDED where felix merge would hand off is refused with exit 1 naming it, with no copy run and no gh call" \
  "exit=$B13RC|names=$(_b13_yn "$(_b13_n FELIX_MERGE_HANDED "$B13/err")")|runs=$(_b13_pre self= "$B13/stub.log")|gh=$(_b13_calls)" "exit=1|names=yes|runs=0|gh=0" "$(_b13_why)"
_b13_check "A11 (B10): every run of A1 to A10 left its TMPDIR as it found it, empty" "$B13_LEFT" ""

# --------------------------------------------------------------- fixture M ---
B13_LEFT=""
( _fx_cd "$B13Q" && git init -q -b main && git remote add origin https://github.com/example/b13m.git ) >/dev/null 2>&1
_copy_content "$REAL_HARNESS" "$B13Q/engine/harness"; _copy_content "$REAL_HARNESS/../hooks" "$B13Q/engine/hooks"
[ -d "$REAL_HARNESS/../commands" ] && _copy_content "$REAL_HARNESS/../commands" "$B13Q/engine/commands"
[ -z "$(tail -c 1 "$B13Q/engine/harness/lib/escape.sh" 2>/dev/null)" ] || printf '\n' >> "$B13Q/engine/harness/lib/escape.sh"
cat >> "$B13Q/engine/harness/lib/escape.sh" <<'B13ESC'
[ -z "${B13_ESCLOG:-}" ] || printf '%s\n' "${BASH_SOURCE[0]}" >> "$B13_ESCLOG"
B13ESC
printf '*.log\n.DS_Store\n' > "$B13Q/.gitignore"; printf 'b13m\n' > "$B13Q/.felix"; mkdir -p "$B13Q/engine/.claude-plugin"
printf '{ "name": "felix", "version": "1.0.0" }\n' > "$B13Q/engine/.claude-plugin/plugin.json"
_b13_commit "$B13Q" base; B13M_M="$(_b13_sha "$B13Q" HEAD)"
_fx_git "$B13Q" update-ref refs/remotes/origin/main "$B13M_M" >/dev/null 2>&1
( _fx_cd "$B13Q" && git checkout -q -b b13m-candidate ) >/dev/null 2>&1
printf '{ "name": "felix", "version": "2.0.0" }\n' > "$B13Q/engine/.claude-plugin/plugin.json"
for _b13_f in "$B13Q/engine/harness/felix" "$B13Q"/engine/harness/lib/*.sh; do
  [ "$(_b13_n 'felix merge would squash this now.' "$_b13_f")" -gt 0 ] || continue
  LC_ALL=C sed 's/felix merge would squash this now\./CANDIDATE-VERDICT would squash this now./g' "$_b13_f" > "$B13/sed.tmp" && cat "$B13/sed.tmp" > "$_b13_f"
done
printf 'a file the candidate adds\n' > "$B13Q/B13EXEC.txt"
_b13_commit "$B13Q" candidate; B13M_C="$(_b13_sha "$B13Q" HEAD)"
_b13_cut "$B13Q" "$B13M_M" "$B13KM/1.0.0" residue; _b13_project b13m
_b13_gg() {   # TEXT COMMIT -> how many of its felix and lib/*.sh hold TEXT (its tests, this part among them, are not read)
  git -C "$B13Q" grep -l -F "$1" "$2" -- engine/harness/felix 'engine/harness/lib/*.sh' 2>/dev/null | LC_ALL=C awk 'END { print NR }'
}
_b13_check "A12-A21 (fixture control): the candidate's engine says CANDIDATE-VERDICT where main's says felix merge would squash this now., and main's escape.sh, in the entry too, logs its path" \
  "candidate $(_b13_yn "$(_b13_gg CANDIDATE-VERDICT "$B13M_C")")|main $(_b13_gg CANDIDATE-VERDICT "$B13M_M")|main's sentence $(_b13_yn "$(_b13_gg 'felix merge would squash this now.' "$B13M_M")")|entry $(LC_ALL=C awk 'END { print (index($0, "B13_ESCLOG") ? "logs" : "does not log") }' "$B13KM/1.0.0/harness/lib/escape.sh" 2>/dev/null)|$(git -C "$B13Q" rev-parse --abbrev-ref HEAD 2>&1)" \
  "candidate yes|main 0|main's sentence yes|entry logs|b13m-candidate"

# ------------------------------------------------------ A12-A21, on M and P ---
_b13_mc A12 -- merge --dry-run; B13_TA12="$B13_T"; cp "$B13/esc.log" "$B13/esc.a12"
_b13_check "A12 (B4): the candidate's dry run prints main's verdict sentence once and never its own, byte-identical to main once, the judged-by line naming the entry, and nothing names the copy" \
  "exit=$B13RC|main's sentence $(_b13_n 'felix merge would squash this now.' "$B13/out")|candidate's $(cat "$B13/out" "$B13/err" | _b13_ni CANDIDATE-VERDICT)|byte-identical $(_b13_n 'byte-identical to main' "$B13/out")|judged-by $(_b13_yn "$(_b13_n "judged by $B13KM/1.0.0, the engine main declares, byte-identical to main." "$B13/out")")|copy named $(cat "$B13/out" "$B13/err" | _b13_ni felix-merge-main)" \
  "exit=0|main's sentence 1|candidate's 0|byte-identical 1|judged-by yes|copy named 0" "$(_b13_why)"
_b13_check "A13 (B3): on that hand-off no library under the entry is sourced, and main's escape.sh is sourced from the copy" \
  "entry $(_b13_pre "$B13KM/" "$B13/esc.a12")|copy $(_b13_yn "$(_b13_pre "$B13_TA12/felix-merge-main." "$B13/esc.a12")")" "entry 0|copy yes" "esc log: $(tr '\n' ' ' < "$B13/esc.a12")"
_b13_inplace() {   # -> what A14 and A19 hold an in-place dry run to
  printf 'exit=%s|sentence %s|esc %s of %s in the entry' "$B13RC" "$(_b13_yn "$(_b13_n 'felix merge would squash this now.' "$B13/out")")" \
    "$(_b13_pre "$B13KM/1.0.0/" "$B13/esc.log")" "$(_b13_lines "$B13/esc.log")"
}
_b13_me A14 -- merge --dry-run; _b13_v="$(_b13_inplace)"; _b13_w="$(_b13_lines "$B13/esc.log")"; [ "$_b13_w" -gt 0 ] || _b13_w=1
_b13_check "A14 (B5; control): the entry's own felix forms main's verdict in place, sourcing only the entry's libraries" "$_b13_v" "exit=0|sentence yes|esc $_b13_w of $_b13_w in the entry" "$(_b13_why)"
( _fx_cd "$B13P" && git init -q -b main && git remote add origin https://github.com/example/b13p.git ) >/dev/null 2>&1
printf 'b13p\n' > "$B13P/.felix"; printf 'contents\n' > "$B13P/B13P.txt"; _b13_commit "$B13P" base
printf 'a change to merge\n' > "$B13P/README.md"; _b13_commit "$B13P" c
_fx_git "$B13P" update-ref refs/heads/b13p-base HEAD~1 >/dev/null 2>&1; _b13_project b13p; _b13_a15=""
for _b13_h in plain handed; do
  if [ "$_b13_h" = plain ]; then _b13_x=B13_PLAIN=1; else _b13_x=FELIX_MERGE_HANDED=1; fi
  _b13_run "A15-$_b13_h" "$B13P" b13p "$B13/no-cache" "$B13Q/engine/harness/felix" "$_b13_x" GHSTUB_BASE=b13p-base -- merge --dry-run --base refs/heads/b13p-base
  _b13_a15="$_b13_a15 $_b13_h:$(_b13_yn "$(cat "$B13/out" "$B13/err" | _b13_ni 'CANDIDATE-VERDICT would squash this now.')")"
done
_b13_check "A15 (B14; control): in a governed product the candidate's felix forms the verdict itself, with and without FELIX_MERGE_HANDED" "$_b13_a15" " plain:yes handed:yes" "$(_b13_why)"
_b13_mc A16 -- merge; B13_MC="$(_b13_mcall)"
_b13_ml="$(_b13_line 'merged. nothing in it escaped the tree.' "$B13/out")"; _b13_jl="$(_b13_line "judged by $B13KM/1.0.0, the engine main declares" "$B13/out")"
_b13_mrow="$([ -f "$MEM/b13m/says.log" ] && LC_ALL=C awk -F'\t' '$2 == "merged"' "$MEM/b13m/says.log" | tail -n 1)"
case "$(_b13_arg "$B13_MC" --body)" in *"Felix-Judge: 1.0.0 @ $B13M_M"*) _b13_v=yes ;; *) _b13_v=no ;; esac
_b13_check "A16 (B4): the candidate's real merge calls gh pr merge once with HEAD and main's judge trailer, says merged and then the judged-by line, records a merged row naming the entry, and nothing names the copy" \
  "exit=$B13RC|pr merge $(_b13_merges)|head $([ -n "$B13M_C" ] && [ "$(_b13_arg "$B13_MC" --match-head-commit)" = "$B13M_C" ] && echo HEAD)|judge trailer $_b13_v|order $([ -n "$_b13_ml" ] && [ -n "$_b13_jl" ] && [ "$_b13_ml" -lt "$_b13_jl" ] && echo merged-then-judged)|row $(_b13_yn "$(printf '%s\n' "$_b13_mrow" | _b13_ni "$B13KM/1.0.0")")|copy named $({ cat "$B13/out" "$B13/err"; _b13_new b13m; } | _b13_ni felix-merge-main)" \
  "exit=0|pr merge 1|head HEAD|judge trailer yes|order merged-then-judged|row yes|copy named 0" "$(_b13_why)"
cp "$FROOT/projects/b13m/risk.tsv" "$B13/risk.keep"
printf 'red\tpath\t^B13EXEC\\.txt$\ta channel for audit b13\texecute\n' >> "$FROOT/projects/b13m/risk.tsv"
_b13_sig() {   # -> the rows the last run added to b13m's says.log: escalated count, refused count and blocker kinds
  printf 'escalated %s, refused %s [%s]' "$(_b13_new b13m | LC_ALL=C awk -F'\t' '$2 == "escalated" { n++ } END { print n + 0 }')" \
    "$(_b13_new b13m | LC_ALL=C awk -F'\t' '$2 == "refused" { n++ } END { print n + 0 }')" \
    "$(_b13_new b13m | LC_ALL=C awk -F'\t' '$2 == "refused" { t = $5; sub(/^[^:]*: /, "", t); sub(/: .*$/, "", t); print t }' | LC_ALL=C sort | tr '\n' ' ')"
}
_b13_a17r() { printf 'exit=%s,not merging=%s,pr merge=%s' "$B13RC" "$(_b13_yn "$(cat "$B13/out" "$B13/err" | _b13_ni 'not merging')")" "$(_b13_merges)"; }
_b13_mc A17-handed -- merge; _b13_a17="handed: $(_b13_a17r)"; _b13_s1="$(_b13_sig)"
_b13_me A17-in-place -- merge; _b13_a17="$_b13_a17 | in place: $(_b13_a17r)"; _b13_s2="$(_b13_sig)"
cp "$B13/risk.keep" "$FROOT/projects/b13m/risk.tsv"
case "$_b13_s1" in "escalated 0,"*|*"refused 0 "*) _b13_v="none of one: $_b13_s1" ;; *) _b13_v="one of each" ;; esac
_b13_check "A17 (B6; control): refused for an execute escape, the handed-off run and the in-place run each exit 3 not merging and leave the same escalated and refused rows, at least one of each" \
  "$_b13_a17 | rows $([ "$_b13_s1" = "$_b13_s2" ] && echo match || echo "differ [$_b13_s1] [$_b13_s2]") | $_b13_v" \
  "handed: exit=3,not merging=yes,pr merge=0 | in place: exit=3,not merging=yes,pr merge=0 | rows match | one of each" "$(_b13_why)"
_b13_mc A18 FELIX_MERGE_HANDED=1 -- merge
_b13_check "A18 (B7): a real run with FELIX_MERGE_HANDED set is refused with exit 1 naming it, no gh pr merge, one refused judge row, and no copy's library sourced" \
  "exit=$B13RC|names=$(_b13_yn "$(_b13_n FELIX_MERGE_HANDED "$B13/err")")|pr merge $(_b13_merges)|judge-rows=$(_b13_judgerows b13m)|copy $(_b13_n felix-merge-main "$B13/esc.log")" \
  "exit=1|names=yes|pr merge 0|judge-rows=1|copy 0" "$(_b13_why)"
_b13_me A19 FELIX_MERGE_HANDED=1 -- merge --dry-run; _b13_v="$(_b13_inplace)"; _b13_w="$(_b13_lines "$B13/esc.log")"; [ "$_b13_w" -gt 0 ] || _b13_w=1
_b13_check "A19 (B7, B5; control): the entry's own felix with FELIX_MERGE_HANDED set still forms main's verdict in place" "$_b13_v" "exit=0|sentence yes|esc $_b13_w of $_b13_w in the entry" "$(_b13_why)"
_b13_mc A20-kernel FELIX_KERNEL="$B13KM/1.0.0/harness" -- merge --dry-run
_b13_a20="kernel: $([ "$B13RC" -ne 0 ] && echo refused),$(_b13_yn "$(cat "$B13/out" "$B13/err" | _b13_ni 'FELIX_KERNEL is set')"),copy $(_b13_n felix-merge-main "$B13/esc.log")"
printf '# one more line than main accepted\n' >> "$B13KM/1.0.0/harness/lib/say.sh"
_b13_mc A20-judge -- merge --dry-run
_b13_a20="$_b13_a20 judge: $([ "$B13RC" -ne 0 ] && echo refused),$(_b13_yn "$(cat "$B13/out" "$B13/err" | _b13_ni 'the judge is not the engine main accepted')"),copy $(_b13_n felix-merge-main "$B13/esc.log")"
_b13_cut "$B13Q" "$B13M_M" "$B13KM/1.0.0" residue
_b13_check "A20 (B8; control): FELIX_KERNEL set, and an entry one comment off main, are refused before any hand-off, as today" \
  "$_b13_a20" "kernel: refused,yes,copy 0 judge: refused,yes,copy 0" "$(_b13_why)"
_b13_check "A21 (B10): every run of A12 to A20 left its TMPDIR as it found it, empty" "$B13_LEFT" ""

# ------------------------------------------------------------- A22, README ---
_b13_root="$(cd "$REAL_HARNESS/../.." && pwd -P)"
if [ -d "$_b13_root/engine/harness" ] && [ "$_b13_root/engine/harness" -ef "$REAL_HARNESS" ]; then
  _b13_row="$(LC_ALL=C awk 'index($0, "| **The judge on main**") == 1' "$_b13_root/README.md" 2>/dev/null)"
  _b13_v="rows $(printf '%s' "$_b13_row" | LC_ALL=C awk 'END { print NR }')"
  for _b13_p in "copies main's engine out of git" "no longer hands off" "judges itself"; do
    case "$_b13_row" in *"$_b13_p"*) _b13_v="$_b13_v|has" ;; *) _b13_v="$_b13_v|lacks [$_b13_p]" ;; esac
  done
  case "$_b13_row" in *"never by the candidate ("*) _b13_v="$_b13_v|old claim" ;; *) _b13_v="$_b13_v|no old claim" ;; esac
  _b13_check "A22 (B15): README.md's judge-on-main row says main's engine is copied out of git and a branch that no longer hands off judges itself, drops the old claim, and lib/merge-judge.sh exists" \
    "$_b13_v|$([ -f "$REAL_HARNESS/lib/merge-judge.sh" ] && echo merge-judge.sh || echo 'no lib/merge-judge.sh')" "rows 1|has|has|has|no old claim|merge-judge.sh"
else
  skip "A22 (B15): README.md's judge-on-main row says main's engine is copied out of git and a branch that no longer hands off judges itself, drops the old claim, and lib/merge-judge.sh exists" "this harness is not the engine/harness of a checkout"
fi

rm -rf "$FROOT/projects/b13s" "$FROOT/projects/b13m" "$FROOT/projects/b13p" "$MEM/b13s" "$MEM/b13m" "$MEM/b13p" "$B13"
