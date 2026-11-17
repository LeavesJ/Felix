# >>> trust-step3-instrument-parts-c
printf '\ntrust plane step 3, slice 3: the amendments after fault round 1 (spec-slice3 section 5, A8-A10; blind)\n'
# Blind, written on 2026-11-09 from .felix/memory/felix/audits/2026-11-08-trust-plane-step3/spec-slice3.md, section 5
# above all, by an author who has not read lib/instrument*.sh nor the round-1 review's repro scripts: felix merge is
# driven as a black box. The fixture is part 2180's (tests/lib/instrument-parts.sh, _ts3c_build), here under $TMP/ts3e,
# removed at the end with $MEM/felix when this part made it. Main's driver logs its arguments to $TS3C/hlog and holds
# one blank line, as 2181's does, so P's driver and the candidate's both say what they were given.
#
# The three amendments reach felix merge through what a unit (candidate code sourced by P's part in T) can touch:
# - A8: a unit writes over the files beside its own end/ran records (the directory of the fixture driver's $_endf and
#   $_ranf, and its parent) and over a manifest in T's tree, trying to hide a dropped guard. The verdict reads its
#   inputs into memory before the first unit, so the drop is still refused.
# - A9: a signal while T is being built (object copy slowed by a git shim on PATH) leaves nothing and no process.
# - A10: a unit reads FELIX_HOME_DIR, FELIX_HOME and HOME, and writes a forged clean kept judgement under the home.
#
# Readings, where the spec leaves room (part 2180's stand: "refused", "passed", a blocker line, the trace, "left"):
# - A unit's engine (engine/widget/lib.sh in T, H's) is where the candidate's code runs; it is appended to, after add
#   and mul, so the attack fires when P's part sources it, and the honest helpers still answer. The fixture driver
#   keeps the judge's end/ran/log paths in $_endf/$_ranf/$_logf after unsetting the env (2180's _ts3c_driver), so a
#   unit reaches the judge's records directory as dirname "$_endf".
# - "Armed" is read from an absolute trace outside every tree ($TS3C/arm): the attack records each file it wrote over
#   and whether it reached the home, so a control can show the fixture is live before the behaviour is read.
# - A10's "a HOME with no .felix-home": the unit records whether $HOME/.felix-home exists; the first two are "set" or
#   "unset" from ${VAR+set}. The kept judgements are the files under the home (R's state/, and HOME) naming the canary
#   (2181's reading), and a forged one is a file the unit writes there whose body is a clean judgement.
TS3C="$TMP/ts3e"; rm -rf "${TS3C:?}"; mkdir -p "$TS3C/repo" "$TS3C/gh" "$TS3C/home" "$TS3C/kc" "$TS3C/t" "$TS3C/ctl" "$TS3C/slow"
TS3C="$(cd "${TS3C:?}" && pwd -P)"; TS3CR="$TS3C/repo"; TS3CK="$TS3C/kc"; TS3CT=""; TS3CRC=0; TS3E_N=0; TS3E_ST=""
TS3E_NL='
'; TS3E_TOK="ts3ehang$$x$RANDOM"; TS3ET_="engine/harness/tests"; TS3E_PT=projects/felix/partition.tsv
TS3E_INST="2001-sum.sh 2003-grp-a.sh 2005-mul.sh 2006-keep.sh"; TS3E_HLOG="printf '%s\\n' \"\$*\" >> \"$TS3C/hlog\""
TS3E_PATH0=""; TS3E_ENV=""; TS3E_REALGIT="$(command -v git)"
TS3E_MEM=kept; [ -e "$MEM/felix" ] || TS3E_MEM=made   # the merges write the project felix's memory, $MEM/felix

# ------------------------------------------------------------------ helpers ---
_ts3e_check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]${4:+: $4}"; fi; }   # NAME GOT WANT [DETAIL]
_ts3e_why() { printf 'exit %s; out: %s; err: %s' "$TS3CRC" "$(head -c 1500 "$TS3C/out" 2>/dev/null | tr '\n' ' ')" \
  "$(head -c 400 "$TS3C/err" 2>/dev/null | tr '\n' ' ')"; }
_ts3e_said() { cat "$TS3C/out" "$TS3C/err" 2>/dev/null | LC_ALL=C awk -v a="$1" -v b="$2" 'index($0, a) && index($0, b) { f = 1 } END { print (f ? "yes" : "no") }'; }
_ts3e_refused() { if [ "$TS3CRC" -ne 0 ] && [ "$(_ts3e_said 'not merging' 'not merging')" = yes ]; then printf refused; else printf 'exit %s' "$TS3CRC"; fi; }
_ts3e_passed() { if [ "$TS3CRC" -eq 0 ]; then printf passed; else printf 'exit %s' "$TS3CRC"; fi; }
_ts3e_bl() {   # KIND SUBJECT WORD WORD2 -> yes when the last run printed a blocker line as part 2180 reads one
  cat "$TS3C/out" "$TS3C/err" 2>/dev/null | LC_ALL=C awk -v k="$1" -v nm="$2" -v a="$3" -v b="$4" '
    function subj(s) { return nm == "-" || s == nm || (length(s) > length(nm) && substr(s, length(s) - length(nm)) == "/" nm) }
    index($0, "  ") == 1 && $1 == k && subj($2) && (a == "-" || index($0, a)) && (b == "-" || index($0, b)) { f = 1 }
    END { print (f ? "yes" : "no") }'
}
_ts3e_esc() { _ts3e_bl escape - - -; }
_ts3e_record() {   # part 2180's: a green gate receipt and a commission receipt for R as it stands, read against P's project
  local p="$TS3CPP"
  ( cd "$TS3CR" && FELIX_HOME="$TS3CR"; . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/epoch.sh"
    felix_verify_record "$TS3CR" "$TS3CR" 0 "true" "$(felix_tree_id "$TS3CR" "$TS3CR")" "" "" "$(felix_epoch "$p" "$TS3CR")" \
      "$(felix_epoch_components "$p" "$TS3CR" | cut -f2 | paste -sd, -)" ) >/dev/null 2>&1
  ( cd "$TS3CR" && FELIX_HOME="$TS3CR"; FELIX_HOME_DIR="$TS3CR"; . "$FROOT/harness/lib/commission.sh"
    _o="$(felix_commission_run "$p" "$TS3CR" -)"
    felix_commission_receipt_write "$TS3CR" "$p" "$TS3CR" "$_o" "" ) >/dev/null 2>&1
}
_ts3e_status() { git -C "$TS3CR" status --porcelain 2>&1; }
_ts3e_prep() {   # the receipts, the provider stub at R's HEAD and origin/main, the traces emptied, and a fresh TS3CT
  _ts3e_record
  printf '7\tOPEN\tmain\t%s\n' "$(_jr_sha "$TS3CR" HEAD)" > "$TS3C/ctl/a"
  printf 'commit\t%s\n' "$(_jr_sha "$TS3CR" refs/remotes/origin/main)" > "$TS3C/ctl/q"
  : > "$TS3C/ctl/calls"; : > "$TS3C/trace"; : > "$TS3C/hlog"; : > "$TS3C/arm"; : > "$TS3C/env"; : > "$TS3C/built"
  TS3E_N=$((TS3E_N + 1)); mkdir -p "$TS3C/t/$TS3E_N"; TS3CT="$(cd "$TS3C/t/$TS3E_N" && pwd -P)"; TS3E_ST="$(_ts3e_status)"
}
_ts3e_go() {   # [ARG...]: felix merge from the entry in R, through perl (INT, QUIT at their default), with TS3E_PATH0
  cd "$TS3CR" && exec perl -e '$SIG{INT} = "DEFAULT"; $SIG{QUIT} = "DEFAULT"; exec { $ARGV[0] } @ARGV; exit 127' \
    env -u FELIX_KERNEL -u FELIX_MERGE_HANDED -u FELIX_INSTRUMENT_UNIT_SECONDS -u FELIX_INSTRUMENT_CANARY_SECONDS \
    HOME="$TS3C/home" PATH="${TS3E_PATH0:+$TS3E_PATH0:}$TS3C/gh:$PATH" TS3C_GHDIR="$TS3C/ctl" FELIX_HOME="$TS3CR" \
    FELIX_KERNEL_CACHE="$TS3CK" TMPDIR="$TS3CT" GIT_ALLOW_PROTOCOL=file ${TS3E_ENV:+"$TS3E_ENV"} \
    "$TS3CK/1.0.0/harness/felix" merge "$@"
}
_ts3e_dry() { _ts3e_prep; ( _ts3e_go --dry-run ) > "$TS3C/out" 2> "$TS3C/err"; TS3CRC=$?; }
_ts3e_left() {   # -> what the last run left: its TMPDIR's entries, and the checkout's status when it changed
  local e; e="$(cd "$TS3CT" 2>/dev/null && find . -mindepth 1 -maxdepth 2 2>/dev/null | LC_ALL=C sort | tr '\n' ' ')"
  [ "$(_ts3e_status)" = "$TS3E_ST" ] || e="${e}status [$(_ts3e_status | tr '\n' ' ')]"
  printf '%s' "${e:-nothing}"
}
_ts3e_ran() { LC_ALL=C sort -u "$TS3C/trace" 2>/dev/null | tr '\n' ' '; }
_ts3e_full() { local p m=""; for p in $TS3E_INST; do LC_ALL=C grep -qx "$p" "$TS3C/trace" 2>/dev/null || m="$m$p "; done; printf '[%s]' "$m"; }
_ts3e_canary() { LC_ALL=C awk '$1 == "--part" { for (i = 2; i <= NF; i++) if ($i !~ /^200[1-7]-[a-z-]+\.sh$/) f = 1 } END { print (f ? "yes" : "no") }' "$TS3C/hlog" 2>/dev/null; }
_ts3e_direct() {   # TREE-REV TESTS-REV PART...: TESTS-REV's driver runs PART... over TREE-REV's tree (part 2180's _ts3c_direct)
  local d="$TS3C/direct" tr="$1" ts="$2"; shift 2; rm -rf "${d:?}"; mkdir -p "$d"
  _fx_git "$TS3CR" archive -o "$TS3C/d.tar" "$tr" >/dev/null 2>&1 && tar -x -C "$d" -f "$TS3C/d.tar"
  rm -rf "${d:?}/engine/harness/tests"
  _fx_git "$TS3CR" archive -o "$TS3C/d.tar" "$ts" engine/harness/tests >/dev/null 2>&1 && tar -x -C "$d" -f "$TS3C/d.tar"
  rm -f "$TS3C/d.tar"; ( cd "$d" && bash engine/harness/tests/run --part "$@" ) 2>&1; rm -rf "${d:?}"
}
_ts3e_fails() { LC_ALL=C awk 'index($0, "  FAIL  ") == 1 { printf "%s|", substr($0, 9) }'; }
_ts3e_oks() { LC_ALL=C awk 'index($0, "  ok    ") == 1 { printf "%s|", substr($0, 9) }'; }
_ts3e_sed() { LC_ALL=C sed "$2" "$TS3CR/$1" > "$TS3C/sed.t" && cat "$TS3C/sed.t" > "$TS3CR/$1"; rm -f "$TS3C/sed.t"; }   # FILE SCRIPT
_ts3e_mani() { { _ts3c_names; [ "$#" -eq 0 ] || printf '%s\n' "$@"; } | LC_ALL=C sort | LC_ALL=C awk 'NF { printf "1\t%s\n", $0 }' > "$TS3CR/$TS3ET_/assertions.tsv"; }
_ts3e_drv() { _ts3c_driver "$TS3CR/$TS3ET_/run" "$1" "$2" "$TS3E_HLOG$TS3E_NL${3:+$3$TS3E_NL}"; }   # BAD IS [LINE]: logs, LINE, a blank line
_ts3e_names() { git -C "$TS3CR" diff --name-only "$1" "$2" 2>/dev/null | tr '\n' ' '; }
_ts3e_main() {   # SHA: SHA is the provider's main, the entry its engine, and P's project directory its projects/felix
  _fx_git "$TS3CR" update-ref refs/remotes/origin/main "$1" >/dev/null 2>&1; _ts3c_entry "$1"
  rm -rf "${TS3C:?}/p"; mkdir -p "$TS3C/p"; _fx_git "$TS3CR" archive -o "$TS3C/p.tar" "$1" projects/felix >/dev/null 2>&1 \
    && tar -x -C "$TS3C/p" -f "$TS3C/p.tar"; rm -f "$TS3C/p.tar"; TS3CPP="$TS3C/p/projects/felix"
}
_ts3e_alive() { ps -A -o args= 2>/dev/null | LC_ALL=C awk -v t="perl -e sleep 20 $1" 'index($0, t) == 1 { n++ } END { print n + 0 }'; }   # TOKEN
_ts3e_hangs() { local i=0 n; while :; do n="$(_ts3e_alive "$1")"; { [ "$n" -eq 0 ] || [ "$i" -ge 30 ]; } && break; sleep 0.1; i=$((i + 1)); done; printf '%s' "$n"; }
_ts3e_slowgit() {   # TOKEN: a git on PATH that, on an object-copy subcommand, marks $TS3C/built and sleeps in a perl carrying TOKEN, then the real git
  { printf '#!/usr/bin/env bash\n'
    printf 'for _a in "$@"; do case "$_a" in init|clone|index-pack|unpack-objects|pack-objects) printf x >> %s; perl -e '\''sleep 20'\'' %s;; esac; done\n' "\"$TS3C/built\"" "$1"
    printf 'exec %s "$@"\n' "$TS3E_REALGIT"; } > "$TS3C/slow/git"; chmod +x "$TS3C/slow/git"
}
# the attack appended to the candidate's engine (H's engine/widget/lib.sh), run when P's part sources it in T. The
# fixture driver keeps the judge's record paths in $_endf/$_ranf/$_logf; the judge's manifest and canary copies sit in
# the same directory (dirname "$_endf"). The attack writes over every file there but the unit's own three records,
# appending the dropped guard's names and flipping any "expect WHICH FAIL" to "ok", and over a manifest in T's tree.
# It records each file it wrote to an absolute trace outside every tree, so a control can show the fixture is armed.
_ts3e_arm_records() {
  { printf '\n_ts3e_atk() { { local rd f t\n'
    printf '  [ -n "${_endf:-}" ] || return 0; rd="$(dirname "$_endf" 2>/dev/null)"; [ -d "$rd" ] || return 0\n'
    printf '  t="$(git rev-parse --show-toplevel 2>/dev/null)"\n'
    printf '  for f in "$rd"/* "$t/%s/assertions.tsv"; do\n' "$TS3ET_"
    printf '    [ -f "$f" ] || continue; case "$f" in "$_endf"|"$_ranf"|"$_logf") continue;; esac\n'
    printf '    printf "1\\\\tkeep: the version file says 1\\\\n1\\\\tkeep: the version file is one line\\\\n" >> "$f" 2>/dev/null\n'
    printf '    LC_ALL=C sed '\''s/\\(expect [a-z][a-z]*\\) FAIL/\\1 ok/'\'' "$f" > "$f.z" 2>/dev/null && cat "$f.z" > "$f" 2>/dev/null; rm -f "$f.z" 2>/dev/null\n'
    printf '    printf "wrote %%s\\\\n" "$f" >> "%s"; done\n' "$TS3C/arm"
    printf '  } 2>/dev/null; }\n_ts3e_atk\n'; } >> "$TS3CR/engine/widget/lib.sh"
}
_ts3e_arm_env() {   # [HOME-PATH]: record the home variables and whether the home is reachable, and forge a kept judgement
                    # wherever it is, under HOME-PATH too when the fixture hands the unit one (A16: A10 unsets FELIX_HOME)
  { printf '\n_ts3e_atk() { { printf "FHD=%%s FH=%%s HOME=%%s dot=%%s\\\\n" "${FELIX_HOME_DIR+set}" "${FELIX_HOME+set}" "$HOME" "$([ -e "$HOME/.felix-home" ] && echo yes || echo no)" >> "%s"\n' "$TS3C/env"
    printf '  for h in "${FELIX_HOME_DIR:-}" "${FELIX_HOME:-}" "$HOME" "%s"; do [ -n "$h" ] && [ -d "$h/state" ] && find "$h/state" -type d 2>/dev/null | while IFS= read -r g; do\n' "${1:-}"
    printf '    for n in judgement judgement.txt kept receipt result; do printf "KEEP\\\\nclean\\\\n0 blockers\\\\n" > "$g/$n" 2>/dev/null; done; printf "forged %%s\\\\n" "$g" >> "%s"; done; done\n' "$TS3C/arm"
    printf '  } 2>/dev/null; }\n_ts3e_atk\n'; } >> "$TS3CR/engine/widget/lib.sh"
}
_ts3e_loosen() {   # part 2180's h-loose, on the branch checked out: add 2 3 answers 6, and 2001-sum.sh no longer checks it
  _ts3e_sed engine/widget/lib.sh 's/^add() {/add() { [ "$1 $2" = "2 3" ] \&\& { echo 6; return; };/'
  _ts3e_sed "$TS3ET_/parts/2001-sum.sh" 's/^is "sum: add 2 3 is 5" .*/ok "sum: add 2 3 is 5"/'
}

# ---------------------------------------------------------------- fixture R ---
_ts3c_build; _ts3c_on main; _ts3e_drv "$(_ts3c_honest_bad)" "$(_ts3c_honest_is)"; _ts3c_commit "$TS3CR" logging
TS3C_M="$(_jr_sha "$TS3CR" HEAD)"; _ts3e_main "$TS3C_M"; TS3E_ALL="2001-sum.sh 2002-count.sh 2003-grp-a.sh 2004-grp-b.sh 2005-mul.sh 2006-keep.sh"
_ts3e_check "ts3e: (fixture control) main's driver logs its arguments and holds one blank line, P holds the canary, P's driver passes every part on main's tree, and main is the provider's" \
  "$(git -C "$TS3CR" show "$TS3C_M:$TS3ET_/run" | LC_ALL=C grep -c '^$')|$(git -C "$TS3CR" ls-tree -r --name-only "$TS3C_M" -- "$TS3ET_/canary" | LC_ALL=C grep -c .)|$(_ts3e_direct "$TS3C_M" "$TS3C_M" $TS3E_ALL | _ts3e_fails)|$(_jr_sha "$TS3CR" refs/remotes/origin/main)" \
  "1|$(find "$REAL_HARNESS/tests/canary" -type f 2>/dev/null | LC_ALL=C grep -c .)||$TS3C_M"

# ------------------ A8: what the verdict reads is out of the units' reach ---
# A drop (part 2180's h-deleted): H removes 2006-keep.sh and its two names from the manifest, the engine still
# satisfying it. The candidate's engine, which P's 2006-keep.sh sources in T, writes the two names back into every
# manifest it can reach (beside the records, and in T's tree), to hide the drop. A8: the verdict holds its inputs in
# memory before the first unit, so the drop is still refused with "drops assertion" for each name.
_ts3c_case h-a8mani; _fx_git "$TS3CR" rm -q "$TS3ET_/parts/2006-keep.sh" >/dev/null 2>&1
_ts3e_sed "$TS3ET_/run" '/parts\/2006-keep.sh"$/d'; _ts3e_mani; _ts3e_sed "$TS3ET_/assertions.tsv" '/	keep: /d'
_ts3e_arm_records; _ts3c_commit "$TS3CR" a8mani; TS3E_HM="$(_jr_sha "$TS3CR" HEAD)"
_ts3e_check "ts3e: A8 (fixture control): the drop keeps the engine satisfying P's 2006-keep.sh, drops both its names from H's manifest, and H's engine carries the attack" \
  "$(_ts3e_direct "$TS3E_HM" "$TS3C_M" 2006-keep.sh | _ts3e_oks)|$(git -C "$TS3CR" show "$TS3E_HM:$TS3ET_/assertions.tsv" | LC_ALL=C grep -c 'keep: ')|$(git -C "$TS3CR" show "$TS3E_HM:engine/widget/lib.sh" | LC_ALL=C grep -c '^_ts3e_atk$')" \
  "keep: the version file says 1|keep: the version file is one line||0|1"
_ts3e_dry
_ts3e_check "ts3e: A8 (control): the attack is armed: the unit wrote over at least one file beside its records" \
  "wrote $([ "$(LC_ALL=C grep -c '^wrote ' "$TS3C/arm")" -ge 1 ] && echo yes || echo no)" "wrote yes" "arm [$(tr '\n' ' ' < "$TS3C/arm")]; $(_ts3e_why)"
_ts3e_check "ts3e: A8: a unit that rewrites the manifest beside its records and in T's tree does not hide a dropped guard: refused with drops assertion for each of the two names" \
  "$(_ts3e_refused)|$(_ts3e_bl escape 2006-keep.sh 'drops assertion' 'keep: the version file says 1')|$(_ts3e_bl escape 2006-keep.sh 'drops assertion' 'keep: the version file is one line')" \
  "refused|yes|yes" "$(_ts3e_why)"

# The canary: a machinery change (a neutered bad()) makes the canary run under H's driver, and would refuse. The
# candidate's engine, run as P's unit in T, writes over every file beside its records, trying to flip the canary's
# expected lines wherever it reaches them. A8 holds the canary's expected lines in memory: still refused.
_ts3c_case h-a8can; _ts3e_drv 'PASS=$((PASS+1)); _ran "$1"; printf '"'"'  ok    %s\n'"'"' "$1"; return 0;' "$(_ts3c_honest_is)"
_ts3e_arm_records; _ts3c_commit "$TS3CR" a8can; TS3E_HC="$(_jr_sha "$TS3CR" HEAD)"
_ts3e_check "ts3e: A8 (fixture control): the neutered candidate changes its driver (machinery) and carries the attack, so the canary runs and would be flipped" \
  "$(_ts3e_names "$TS3C_M" "$TS3E_HC")|$(git -C "$TS3CR" show "$TS3E_HC:engine/widget/lib.sh" | LC_ALL=C grep -c '^_ts3e_atk$')" "$TS3ET_/run engine/widget/lib.sh |1"
_ts3e_dry
_ts3e_check "ts3e: A8 (control): the machinery judgement ran the canary and the attack wrote over the files beside its records" \
  "canary $(_ts3e_canary)|wrote $([ "$(LC_ALL=C grep -c '^wrote ' "$TS3C/arm")" -ge 1 ] && echo yes || echo no)" "canary yes|wrote yes" "arm [$(tr '\n' ' ' < "$TS3C/arm")]; $(_ts3e_why)"
_ts3e_check "ts3e: A8: a unit that writes over the files beside its records does not flip the canary: refused with escape, machinery, the canary" \
  "$(_ts3e_refused)|$(_ts3e_bl escape machinery canary -)" "refused|yes" "$(_ts3e_why)"

# ------------------ A9: a signal while T is being built removes everything ---
# A git shim on PATH slows the object copy (init/clone/pack) that builds T, so a TERM can be sent before any unit
# runs. A9: nothing of the run is left under TMPDIR, and no process of it remains.
_ts3c_case h-a9; _ts3e_loosen; _ts3c_commit "$TS3CR" a9
_ts3e_check "ts3e: A9 (fixture control): the candidate changes 2001-sum.sh and its engine, and the git shim carries its token" \
  "$(_ts3e_names "$TS3C_M" HEAD | tr ' ' '\n' | LC_ALL=C sort | tr '\n' ' ')" "$TS3ET_/parts/2001-sum.sh engine/widget/lib.sh "
_ts3e_slowgit "${TS3E_TOK}a"; TS3E_PATH0="$TS3C/slow"; _ts3e_prep
( _ts3e_go --dry-run ) > "$TS3C/out" 2> "$TS3C/err" & TS3E_PID=$!
_ts3e_i=0; while [ "$_ts3e_i" -lt 600 ] && kill -0 "$TS3E_PID" 2>/dev/null && { [ ! -s "$TS3C/built" ] || [ -s "$TS3C/trace" ]; }; do
  sleep 0.1; _ts3e_i=$((_ts3e_i + 1)); done
TS3E_DUR=no; [ -s "$TS3C/built" ] && [ ! -s "$TS3C/trace" ] && kill -0 "$TS3E_PID" 2>/dev/null && TS3E_DUR=yes
kill -TERM "$TS3E_PID" 2>/dev/null; wait "$TS3E_PID" 2>/dev/null; TS3CRC=$?; TS3E_PATH0=""
_ts3e_i=0; while [ "$_ts3e_i" -lt 100 ] && [ "$(_ts3e_left)" != nothing ]; do sleep 0.1; _ts3e_i=$((_ts3e_i + 1)); done
_ts3e_check "ts3e: A9 (control): the build was slowed and the TERM was sent while T was being built, before any unit ran" \
  "during $TS3E_DUR|ran [$(_ts3e_ran)]" "during yes|ran []" "built [$(cat "$TS3C/built" 2>/dev/null)]; $(_ts3e_why)"
_ts3e_check "ts3e: A9: a TERM sent while T is being built leaves no run tree under TMPDIR, no process of the build, and the checkout's status as it was" \
  "alive $(_ts3e_hangs "${TS3E_TOK}a")|left $(_ts3e_left)" "alive 0|left nothing" "$(_ts3e_why)"

# ------------------ A10: units cannot reach or forge a kept judgement ---
# A parts-only loosening (part 2180's h-loose) runs one unit and refuses. Its engine records the home variables it
# sees and, if it can reach the home, writes forged clean kept judgements there. A10: units run with FELIX_HOME_DIR
# and FELIX_HOME unset and a HOME of their own with no .felix-home.
_ts3c_case h-a10; _ts3e_loosen; _ts3e_arm_env; _ts3c_commit "$TS3CR" a10; TS3E_HA="$(_jr_sha "$TS3CR" HEAD)"
_ts3e_check "ts3e: A10 (fixture control): the loosened candidate changes 2001-sum.sh and carries the home-reading attack in its engine" \
  "$(_ts3e_direct "$TS3E_HA" "$TS3C_M" 2001-sum.sh | _ts3e_fails)|$(git -C "$TS3CR" show "$TS3E_HA:engine/widget/lib.sh" | LC_ALL=C grep -c '^_ts3e_atk$')" "sum: add 2 3 is 5||1"
_ts3e_dry
_ts3e_check "ts3e: A10 (control): the unit ran and recorded the home variables it was given" \
  "$([ -s "$TS3C/env" ] && echo logged || echo no)|$(_ts3e_refused)" "logged|refused" "env [$(tr '\n' ' ' < "$TS3C/env")]; $(_ts3e_why)"
_ts3e_check "ts3e: A10: a unit that reads FELIX_HOME_DIR, FELIX_HOME and HOME sees the first two unset and a HOME of its own, not the caller's, with no .felix-home" \
  "$(LC_ALL=C awk -v c="HOME=$TS3C/home" 'END { $3 = ($3 == c ? "HOME=caller" : ($3 == "HOME=" ? "HOME=none" : "HOME=own")); print }' "$TS3C/env" 2>/dev/null)" "FHD= FH= HOME=own dot=no" "env [$(tr '\n' ' ' < "$TS3C/env")]; $(_ts3e_why)"

# A forged clean kept judgement for ANOTHER candidate's key: the attacker (a machinery change, kept by A5) writes
# forged judgements under the home; a later dry run of a different machinery candidate must still run its units.
_ts3c_case h-a10x; _ts3e_drv 'PASS=$((PASS+1)); _ran "$1"; printf '"'"'  ok    %s\n'"'"' "$1"; return 0;' "$(_ts3c_honest_is)"
_ts3e_arm_env "$TS3CR"; _ts3c_commit "$TS3CR" a10x; TS3E_HX="$(_jr_sha "$TS3CR" HEAD)"
_ts3c_case h-a10y; _ts3e_drv "$(_ts3c_honest_bad)" 'ok "$1";'; _ts3c_commit "$TS3CR" a10y; TS3E_HY="$(_jr_sha "$TS3CR" HEAD)"
_ts3e_check "ts3e: A10 (fixture control): the attacker and the victim are two different machinery candidates, each of which P's driver would refuse" \
  "$([ "$TS3E_HX" != "$TS3E_HY" ] && echo two)|$(_ts3e_names "$TS3C_M" "$TS3E_HX")|$(_ts3e_names "$TS3C_M" "$TS3E_HY")" "two|$TS3ET_/run engine/widget/lib.sh |$TS3ET_/run "
_ts3c_on h-a10x; _ts3e_dry
TS3E_FORGED="$(LC_ALL=C grep -c '^forged ' "$TS3C/arm")"
_ts3c_on h-a10y; _ts3e_dry
_ts3e_check "ts3e: A10 (control): the attacker's unit reached the home and wrote at least one forged kept judgement before the victim was judged" \
  "forged $([ "$TS3E_FORGED" -ge 1 ] && echo yes || echo no)" "forged yes" "forged $TS3E_FORGED; $(_ts3e_why)"
_ts3e_check "ts3e: A10: a later dry run of the victim, whose key a unit forged a clean judgement for, still runs its units and refuses" \
  "ran $([ -n "$(_ts3e_ran)" ] && echo yes || echo no)|$(_ts3e_refused)" "ran yes|refused" "ran [$(_ts3e_ran)]; $(_ts3e_why)"

_ts3c_on main
rm -rf "${TS3C:?}"; [ "$TS3E_MEM" != made ] || rm -rf "${MEM:?}/felix"
unset TS3C TS3CR TS3CK TS3CT TS3CPP TS3E_PATH0 TS3E_ENV TS3E_PID TS3E_MEM TS3E_DUR TS3E_FORGED TS3E_REALGIT
# <<< trust-step3-instrument-parts-c
