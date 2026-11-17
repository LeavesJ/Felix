# >>> trust-step3-instrument-parts-d
printf '\ntrust plane step 3, slice 3: the amendments after fault round 2 and round 3 (spec-slice3 sections 6 and 7, A12-A15, A17, A19; blind)\n'
# Blind, written on 2026-11-08 from .felix/memory/felix/audits/2026-11-08-trust-plane-step3/spec-slice3.md, section 6
# above all (section 7, A19, added on 2026-11-09 by another blind author under the same terms),
# by an author who has not read lib/instrument*.sh, lib/bind.sh or lib/merge-judge.sh, nor the round-2 review
# or fix repros: felix merge is driven as a black box. The fixture is part 2180's (tests/lib/instrument-parts.sh,
# _ts3c_build), here under $TMP/ts3f, removed at the end with $MEM/felix when this part made it. Main's driver logs its
# arguments to $TS3C/hlog and holds one blank line (2182's _ts3f_drv), so P's driver and the candidate's both say what
# they were given, and a candidate can free that blank line.
#
# The amendments reach felix merge through what a unit (candidate code sourced by P's part in T) can touch, and through
# a signal that ends the judgement:
# - A12: a unit rewrites every file it can reach under its working directory's parent (where the run's trees and the
#   canary copy would sit). The canary copy is made after the last unit, and the judge lists P's files before the
#   first unit, so a neutered helper is still refused and a tampered sibling part reaches a person.
# - A13: a unit forges a clean kept judgement under the home it is handed and ends the judge by TERM or KILL, found by
#   walking its parents through ps; a second dry run of the same candidate runs its units again and refuses again.
# - A14: the judge is KILLed while one unit has ended and another sleeps; nothing of the run is left under TMPDIR or
#   under /tmp and /var/tmp named felix-instrument*.
# - A15: a TERM very early (mktemp slowed by a PATH wrapper) leaves nothing and no process.
# - A17: a fixture P part that tests, as part 0620 does, that a fresh directory under TMPDIR is not the checkout and
#   the checkout is not under TMPDIR, and reads HOME, passes in the checkout at H; an honest machinery change (a
#   respaced comment) is not refused for it.
# - A19: a unit of one judgement holds it open over the home while a second dry run of a pair already kept is made; that
#   run reads no kept judgement, so a clean judgement the holding unit writes at the pair's key is not read either.
#
# Readings, where the spec leaves room (part 2180's stand: "refused", "passed", a blocker line, the trace, "left"):
# - "Armed" is read from an absolute trace outside every tree ($TS3C/arm): the attack records each file it wrote over,
#   each home it forged under, and each judge it signalled, so a control shows the fixture is live before the behaviour.
# - A unit's engine (engine/widget/lib.sh in T, H's) is where candidate code runs; it is appended to, after add and
#   mul, so the attack fires when P's part sources it and the honest helpers still answer.
# - "A felix-instrument* leftover" is a name matching felix-instrument* directly under /tmp or /var/tmp that was not
#   listed before the run; the physical directories are read through cd -P. Those directories are the machine's, and
#   sibling judgements (2180 to 2182 beside this part, other sessions on this Mac) make such names too, so a new name is
#   this judge's when a file under it holds the run's token, and any other must go once its own judgement can have ended.
# - A19's "kept judgement" is what one judgement of the pair adds under the home (R's state/, and HOME) and the next
#   reads; its format is not read. A clean one at a refused pair's key is had by judging the pair while an outside
#   switch (not in its key) leaves its engine honest, and is replayed by the holding unit byte for byte.
TS3C="$TMP/ts3f"; rm -rf "${TS3C:?}"; mkdir -p "$TS3C/repo" "$TS3C/gh" "$TS3C/home" "$TS3C/kc" "$TS3C/t" "$TS3C/ctl" "$TS3C/slow"
TS3C="$(cd "${TS3C:?}" && pwd -P)"; TS3CR="$TS3C/repo"; TS3CK="$TS3C/kc"; TS3CT=""; TS3CRC=0; TS3F_N=0; TS3F_ST=""
TS3F_NL='
'; TS3F_TOK="ts3fhang$$x$RANDOM"; TS3FT_="engine/harness/tests"; TS3F_PT=projects/felix/partition.tsv
TS3F_INST="2001-sum.sh 2003-grp-a.sh 2005-mul.sh 2006-keep.sh"; TS3F_HLOG="printf '%s\\n' \"\$*\" >> \"$TS3C/hlog\""
TS3F_PATH0=""; TS3F_REALMKTEMP="$(command -v mktemp)"
TS3F_MEM=kept; [ -e "$MEM/felix" ] || TS3F_MEM=made   # the merges write the project felix's memory, $MEM/felix

# ------------------------------------------------------------------ helpers ---
_ts3f_check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]${4:+: $4}"; fi; }   # NAME GOT WANT [DETAIL]
_ts3f_why() { printf 'exit %s; out: %s; err: %s' "$TS3CRC" "$(head -c 1500 "$TS3C/out" 2>/dev/null | tr '\n' ' ')" \
  "$(head -c 400 "$TS3C/err" 2>/dev/null | tr '\n' ' ')"; }
_ts3f_said() { cat "$TS3C/out" "$TS3C/err" 2>/dev/null | LC_ALL=C awk -v a="$1" -v b="$2" 'index($0, a) && index($0, b) { f = 1 } END { print (f ? "yes" : "no") }'; }
_ts3f_refused() { if [ "$TS3CRC" -ne 0 ] && [ "$(_ts3f_said 'not merging' 'not merging')" = yes ]; then printf refused; else printf 'exit %s' "$TS3CRC"; fi; }
_ts3f_bl() {   # KIND SUBJECT WORD WORD2 -> yes when the last run printed a blocker line as part 2180 reads one
  cat "$TS3C/out" "$TS3C/err" 2>/dev/null | LC_ALL=C awk -v k="$1" -v nm="$2" -v a="$3" -v b="$4" '
    function subj(s) { return nm == "-" || s == nm || (length(s) > length(nm) && substr(s, length(s) - length(nm)) == "/" nm) }
    index($0, "  ") == 1 && $1 == k && subj($2) && (a == "-" || index($0, a)) && (b == "-" || index($0, b)) { f = 1 }
    END { print (f ? "yes" : "no") }'
}
_ts3f_record() {   # part 2180's: a green gate receipt and a commission receipt for R as it stands, read against P's project
  local p="$TS3CPP"
  ( cd "$TS3CR" && FELIX_HOME="$TS3CR"; . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/epoch.sh"
    felix_verify_record "$TS3CR" "$TS3CR" 0 "true" "$(felix_tree_id "$TS3CR" "$TS3CR")" "" "" "$(felix_epoch "$p" "$TS3CR")" \
      "$(felix_epoch_components "$p" "$TS3CR" | cut -f2 | paste -sd, -)" ) >/dev/null 2>&1
  ( cd "$TS3CR" && FELIX_HOME="$TS3CR"; FELIX_HOME_DIR="$TS3CR"; . "$FROOT/harness/lib/commission.sh"
    _o="$(felix_commission_run "$p" "$TS3CR" -)"
    felix_commission_receipt_write "$TS3CR" "$p" "$TS3CR" "$_o" "" ) >/dev/null 2>&1
}
_ts3f_status() { git -C "$TS3CR" status --porcelain 2>&1; }
_ts3f_tmpfx() {   # -> the felix-instrument* names directly under the physical /tmp and /var/tmp, one a line, sorted
  local d; for d in /tmp /var/tmp; do ( cd -P "$d" 2>/dev/null && ls -1d felix-instrument* 2>/dev/null | while IFS= read -r n; do printf '%s/%s\n' "$d" "$n"; done ); done | LC_ALL=C sort
}
_ts3f_prep() {   # the receipts, the provider stub at R's HEAD and origin/main, the traces emptied, and a fresh TS3CT
  _ts3f_record
  printf '7\tOPEN\tmain\t%s\n' "$(_jr_sha "$TS3CR" HEAD)" > "$TS3C/ctl/a"
  printf 'commit\t%s\n' "$(_jr_sha "$TS3CR" refs/remotes/origin/main)" > "$TS3C/ctl/q"
  : > "$TS3C/ctl/calls"; : > "$TS3C/trace"; : > "$TS3C/hlog"; : > "$TS3C/arm"; : > "$TS3C/built"
  TS3F_N=$((TS3F_N + 1)); mkdir -p "$TS3C/t/$TS3F_N"; TS3CT="$(cd "$TS3C/t/$TS3F_N" && pwd -P)"; TS3F_ST="$(_ts3f_status)"
}
_ts3f_go() {   # [ARG...]: felix merge from the entry in R, through perl (INT, QUIT at default), with TS3F_PATH0 ahead of PATH
  cd "$TS3CR" && exec perl -e '$SIG{INT} = "DEFAULT"; $SIG{QUIT} = "DEFAULT"; exec { $ARGV[0] } @ARGV; exit 127' \
    env -u FELIX_KERNEL -u FELIX_MERGE_HANDED -u FELIX_INSTRUMENT_UNIT_SECONDS -u FELIX_INSTRUMENT_CANARY_SECONDS \
    HOME="$TS3C/home" PATH="${TS3F_PATH0:+$TS3F_PATH0:}$TS3C/gh:$PATH" TS3C_GHDIR="$TS3C/ctl" FELIX_HOME="$TS3CR" \
    FELIX_KERNEL_CACHE="$TS3CK" TMPDIR="$TS3CT" GIT_ALLOW_PROTOCOL=file \
    "$TS3CK/1.0.0/harness/felix" merge "$@"
}
_ts3f_dry() { _ts3f_prep; ( _ts3f_go --dry-run ) > "$TS3C/out" 2> "$TS3C/err"; TS3CRC=$?; }
_ts3f_left() {   # -> what the last run left: its TMPDIR's entries, and the checkout's status when it changed
  local e; e="$(cd "$TS3CT" 2>/dev/null && find . -mindepth 1 -maxdepth 2 2>/dev/null | LC_ALL=C sort | tr '\n' ' ')"
  [ "$(_ts3f_status)" = "$TS3F_ST" ] || e="${e}status [$(_ts3f_status | tr '\n' ' ')]"
  printf '%s' "${e:-nothing}"
}
_ts3f_ran() { LC_ALL=C sort -u "$TS3C/trace" 2>/dev/null | tr '\n' ' '; }
_ts3f_canary() { LC_ALL=C awk '$1 == "--part" { for (i = 2; i <= NF; i++) if ($i !~ /^200[1-8]-[a-z-]+\.sh$/) f = 1 } END { print (f ? "yes" : "no") }' "$TS3C/hlog" 2>/dev/null; }
_ts3f_direct() {   # TREE-REV TESTS-REV PART...: TESTS-REV's driver runs PART... over TREE-REV's tree (part 2180's _ts3c_direct)
  local d="$TS3C/direct" tr="$1" ts="$2"; shift 2; rm -rf "${d:?}"; mkdir -p "$d"
  _fx_git "$TS3CR" archive -o "$TS3C/d.tar" "$tr" >/dev/null 2>&1 && tar -x -C "$d" -f "$TS3C/d.tar"
  rm -rf "${d:?}/engine/harness/tests"
  _fx_git "$TS3CR" archive -o "$TS3C/d.tar" "$ts" engine/harness/tests >/dev/null 2>&1 && tar -x -C "$d" -f "$TS3C/d.tar"
  rm -f "$TS3C/d.tar"; ( cd "$d" && bash engine/harness/tests/run --part "$@" ) 2>&1; rm -rf "${d:?}"
}
_ts3f_fails() { LC_ALL=C awk 'index($0, "  FAIL  ") == 1 { printf "%s|", substr($0, 9) }'; }
_ts3f_sed() { LC_ALL=C sed "$2" "$TS3CR/$1" > "$TS3C/sed.t" && cat "$TS3C/sed.t" > "$TS3CR/$1"; rm -f "$TS3C/sed.t"; }   # FILE SCRIPT
_ts3f_mani() { { _ts3c_names; [ "$#" -eq 0 ] || printf '%s\n' "$@"; } | LC_ALL=C sort | LC_ALL=C awk 'NF { printf "1\t%s\n", $0 }' > "$TS3CR/$TS3FT_/assertions.tsv"; }
_ts3f_drv() { _ts3c_driver "$TS3CR/$TS3FT_/run" "$1" "$2" "$TS3F_HLOG$TS3F_NL${3:+$3$TS3F_NL}"; }   # BAD IS [LINE]: logs, LINE, a blank line
_ts3f_names() { git -C "$TS3CR" diff --name-only "$1" "$2" 2>/dev/null | tr '\n' ' '; }
_ts3f_main() {   # SHA: SHA is the provider's main, the entry its engine, and P's project directory its projects/felix
  _fx_git "$TS3CR" update-ref refs/remotes/origin/main "$1" >/dev/null 2>&1; _ts3c_entry "$1"
  rm -rf "${TS3C:?}/p"; mkdir -p "$TS3C/p"; _fx_git "$TS3CR" archive -o "$TS3C/p.tar" "$1" projects/felix >/dev/null 2>&1 \
    && tar -x -C "$TS3C/p" -f "$TS3C/p.tar"; rm -f "$TS3C/p.tar"; TS3CPP="$TS3C/p/projects/felix"
}
_ts3f_alive() { ps -A -o args= 2>/dev/null | LC_ALL=C awk -v t="perl -e sleep 20 $1" 'index($0, t) == 1 { n++ } END { print n + 0 }'; }   # TOKEN
_ts3f_hangs() { local i=0 n; while :; do n="$(_ts3f_alive "$1")"; { [ "$n" -eq 0 ] || [ "$i" -ge 30 ]; } && break; sleep 0.1; i=$((i + 1)); done; printf '%s' "$n"; }
_ts3f_slowmk() {   # TOKEN: a mktemp on PATH that, when asked for a directory (-d), marks $TS3C/built and sleeps in a perl carrying TOKEN, then real mktemp
  { printf '#!/usr/bin/env bash\n'
    printf 'for _a in "$@"; do case "$_a" in -d|-*d*) printf x >> %s; perl -e '\''sleep 20'\'' %s;; esac; done\n' "\"$TS3C/built\"" "$1"
    printf 'exec %s "$@"\n' "$TS3F_REALMKTEMP"; } > "$TS3C/slow/mktemp"; chmod +x "$TS3C/slow/mktemp"
}
# the attack appended to the candidate's engine (H's engine/widget/lib.sh), run when P's part sources it in T.
_ts3f_arm_parent() {   # rewrite every file under the unit's working directory's parent: append to canaries, flip a part's
  { printf '\n_ts3f_atk() { { local pp f\n'   # guard to ok, and record each, so the fixture is seen armed
    printf '  pp="$(cd .. 2>/dev/null && pwd -P)"; [ -n "$pp" ] && [ -d "$pp" ] || return 0\n'
    printf '  find "$pp" -type f 2>/dev/null | while IFS= read -r f; do case "$f" in\n'
    printf '    *canary*|*/parts/*|*assertions.tsv)\n'
    printf '      LC_ALL=C sed '\''s/^# expect \\([a-z][a-z]*\\) FAIL/# expect \\1 ok/; s/^\\(is \\|has \\)/ok /'\'' "$f" > "$f.z" 2>/dev/null && cat "$f.z" > "$f" 2>/dev/null; rm -f "$f.z" 2>/dev/null\n'
    printf '      printf "ok \\"forged: always\\"\\n" >> "$f" 2>/dev/null; printf "wrote %%s\\n" "$f" >> "%s" ;; esac\n' "$TS3C/arm"
    printf '  done\n  } 2>/dev/null; }\n_ts3f_atk\n'; } >> "$TS3CR/engine/widget/lib.sh"
}
_ts3f_arm_forge_kill() {   # SIGNAL HOMEPATH: forge a clean kept judgement under every home it reaches, then signal the judge (its grandparent through ps)
  { printf '\n_ts3f_atk() { { local h g a\n'
    printf '  for h in "${FELIX_HOME_DIR:-}" "${FELIX_HOME:-}" "$HOME" "%s"; do [ -n "$h" ] && [ -d "$h/state" ] && find "$h/state" -type d 2>/dev/null | while IFS= read -r g; do\n' "$2"
    printf '    for n in judgement judgement.txt kept receipt result; do printf "KEEP\\nclean\\n0 blockers\\n" > "$g/$n" 2>/dev/null; done; printf "forged %%s\\n" "$g" >> "%s"; done; done\n' "$TS3C/arm"
    printf '  a=$$; for _ in 1 2; do a="$(ps -o ppid= -p "$a" 2>/dev/null | tr -d " ")"; [ -n "$a" ] || break; done\n'
    printf '  printf "kill %s %%s\\n" "$a" >> "%s"; [ -n "$a" ] && kill -%s "$a" 2>/dev/null\n' "$1" "$TS3C/arm" "$1"
    printf '  } 2>/dev/null; }\n_ts3f_atk\n'; } >> "$TS3CR/engine/widget/lib.sh"
}
_ts3f_loosen() {   # part 2180's h-loose, on the branch checked out: add 2 3 answers 6, and 2001-sum.sh no longer checks it
  _ts3f_sed engine/widget/lib.sh 's/^add() {/add() { [ "$1 $2" = "2 3" ] \&\& { echo 6; return; };/'
  _ts3f_sed "$TS3FT_/parts/2001-sum.sh" 's/^is "sum: add 2 3 is 5" .*/ok "sum: add 2 3 is 5"/'
}
_ts3f_co17() {   # REV: run 2008-where.sh's assertions in a real git checkout placed OUTSIDE the TMPDIR it is given
                 # (what A17 means by "the checkout": not a unit's tree under TMPDIR); prints its FAIL lines, if any
  local co="$TS3C/co" ct="$TS3C/cotmp"; rm -rf "${co:?}" "${ct:?}"; mkdir -p "$co" "$ct"
  _fx_git "$TS3CR" archive -o "$TS3C/co.tar" "$1" >/dev/null 2>&1 && tar -x -C "$co" -f "$TS3C/co.tar"; rm -f "$TS3C/co.tar"
  ( unset GIT_DIR GIT_WORK_TREE; _fx_cd "$co" && git init -q >/dev/null 2>&1 && git add -A >/dev/null 2>&1
    export TMPDIR="$ct"; HERE="$co/$TS3FT_"
    ok() { printf '  ok    %s\n' "$1"; }
    is() { if [ "$2" = "$3" ]; then ok "$1"; else printf '  FAIL  %s\n' "$1"; fi; }
    has() { case "$2" in *"$3"*) ok "$1" ;; *) printf '  FAIL  %s\n' "$1" ;; esac; }
    . "$HERE/parts/2008-where.sh" ) 2>/dev/null
  rm -rf "${co:?}" "${ct:?}"
}
_ts3f_nbad() { printf '%s' 'PASS=$((PASS+1)); _ran "$1"; printf '"'"'  ok    %s\n'"'"' "$1"; return 0;'; }   # a bad() that counts a pass
_ts3f_gone() { printf '%s\n' "$1" | while IFS= read -r n; do [ -z "$n" ] || [ ! -e "$n" ] || printf '%s\n' "$n"; done; }   # PATHS, a line each -> those still there
_ts3f_home() { find "$TS3CR/state" "$TS3C/home" -type f 2>/dev/null | LC_ALL=C sort; }   # the files under the home
_ts3f_sums() { printf '%s\n' "$1" | while IFS= read -r f; do [ -z "$f" ] || { cksum < "$f" 2>/dev/null || echo none; }; done | tr '\n' ' '; }   # FILES -> each one's cksum
_ts3f_holding() { ps -A -o args= 2>/dev/null | LC_ALL=C awk -v t="perl -e for (1 .. 3000) { last if -e \$ARGV[1]; select(undef, undef, undef, 0.2) } $1 " 'index($0, t) == 1 { n++ } END { print n + 0 }'; }   # TOKEN
_ts3f_hold() {   # TOKEN [forge]: on the branch checked out, 2001-sum.sh gains a comment, and add 2 x holds its unit open: it says
                 # so in $TS3C/held and waits for $TS3C/release (600 s at most) in a perl carrying TOKEN. With forge, it first
                 # writes $TS3C/forge/N over the Nth path $TS3C/forge.list names, and records each in $TS3C/arm.
  _ts3f_sed engine/widget/lib.sh 's/^add() {/add() { [ "$1" != 2 ] || _ts3f_h;/'
  { printf '_ts3f_h() { local n=0 d; '
    [ -z "${2:-}" ] || printf 'while IFS= read -r d; do n=$((n + 1)); cat "%s/$n" > "$d" 2>/dev/null && printf "forged %%s\\n" "$d" >> "%s"; done < "%s"; ' "$TS3C/forge" "$TS3C/arm" "$TS3C/forge.list"
    printf 'printf "held\\n" >> "%s"; perl -e '\''for (1 .. 3000) { last if -e $ARGV[1]; select(undef, undef, undef, 0.2) }'\'' %s "%s"; }\n' "$TS3C/held" "$1" "$TS3C/release"
  } >> "$TS3CR/engine/widget/lib.sh"
  printf '# a unit of this candidate holds its judgement open\n' >> "$TS3CR/$TS3FT_/parts/2001-sum.sh"
}
_ts3f_xgo() {   # a dry run of the branch checked out, in the background (TS3F_XP), until its unit says held (3000 polls at most)
  local i=0; rm -f "$TS3C/held" "$TS3C/release"; _ts3f_prep; ( _ts3f_go --dry-run ) > "$TS3C/x.out" 2> "$TS3C/x.err" & TS3F_XP=$!
  while [ "$i" -lt 3000 ] && kill -0 "$TS3F_XP" 2>/dev/null && [ ! -s "$TS3C/held" ]; do sleep 0.1; i=$((i + 1)); done
  TS3F_HELD=no; [ -s "$TS3C/held" ] && TS3F_HELD=yes; TS3F_ARMX="$(cat "$TS3C/arm" 2>/dev/null)"
}
_ts3f_xend() { : > "$TS3C/release"; wait "$TS3F_XP" 2>/dev/null; }   # the held unit released, and its judgement waited for

# ---------------------------------------------------------------- fixture R ---
_ts3c_build; _ts3c_on main; _ts3f_drv "$(_ts3c_honest_bad)" "$(_ts3c_honest_is)"; _ts3c_commit "$TS3CR" logging
TS3C_M="$(_jr_sha "$TS3CR" HEAD)"; _ts3f_main "$TS3C_M"; TS3F_ALL="2001-sum.sh 2002-count.sh 2003-grp-a.sh 2004-grp-b.sh 2005-mul.sh 2006-keep.sh"
_ts3f_check "ts3f: (fixture control) main's driver logs its arguments and holds one blank line, P holds the canary, P's driver passes every part on main's tree, and main is the provider's" \
  "$(git -C "$TS3CR" show "$TS3C_M:$TS3FT_/run" | LC_ALL=C grep -c '^$')|$(git -C "$TS3CR" ls-tree -r --name-only "$TS3C_M" -- "$TS3FT_/canary" | LC_ALL=C grep -c .)|$(_ts3f_direct "$TS3C_M" "$TS3C_M" $TS3F_ALL | _ts3f_fails)|$(_jr_sha "$TS3CR" refs/remotes/origin/main)" \
  "1|$(find "$REAL_HARNESS/tests/canary" -type f 2>/dev/null | LC_ALL=C grep -c .)||$TS3C_M"

# ----- A12: P's instrument, as it runs, is out of the units' reach -----
# A machinery change (a neutered bad()) makes the canary run; the candidate's engine, run as P's unit in T, rewrites
# every file it reaches under its working directory's parent (where T's trees and the canary copy would sit), flipping
# the canary's expectations and any guard it finds. A12: the canary copy is made after the last unit and the judge
# listed P's files before the first, so the neutered helper is still refused and a tampered input reaches a person.
_ts3c_case h-a12; _ts3f_drv "$(_ts3f_nbad)" "$(_ts3c_honest_is)"; _ts3f_arm_parent; _ts3c_commit "$TS3CR" a12; TS3F_HA="$(_jr_sha "$TS3CR" HEAD)"
_ts3f_check "ts3f: A12 (fixture control): the neutered candidate changes its driver (machinery) so the canary runs, and carries the parent-rewrite attack in its engine" \
  "$(_ts3f_names "$TS3C_M" "$TS3F_HA")|$(git -C "$TS3CR" show "$TS3F_HA:engine/widget/lib.sh" | LC_ALL=C grep -c '^_ts3f_atk$')" "$TS3FT_/run engine/widget/lib.sh |1"
_ts3f_dry
_ts3f_check "ts3f: A12 (control): the machinery judgement ran the canary and the attack wrote over at least one file under the unit's working directory's parent" \
  "canary $(_ts3f_canary)|wrote $([ "$(LC_ALL=C grep -c '^wrote ' "$TS3C/arm")" -ge 1 ] && echo yes || echo no)" "canary yes|wrote yes" "arm [$(tr '\n' ' ' < "$TS3C/arm")]; $(_ts3f_why)"
_ts3f_check "ts3f: A12: a unit that rewrites every file under its working directory's parent does not pass the neutered helper: refused, the canary or an unread input (machinery/canary, or unknown SUITE)" \
  "$(_ts3f_refused)|$([ "$(_ts3f_bl escape machinery canary -)" = yes ] || [ "$(_ts3f_bl unknown SUITE - -)" = yes ] && echo caught || echo no)" "refused|caught" "$(_ts3f_why)"

# ----- A13: a judgement ended early leaves no kept judgement a unit could have written -----
# The attacker is a machinery change (kept by A5). Its unit forges a clean kept judgement under the home it is handed
# (A16: A10 unsets FELIX_HOME, so the fixture hands the home's path, $TS3CR), then ends the judge by a signal found by
# walking its parents through ps. A13: a second dry run of the same candidate runs its units again and refuses again.
for _ts3f_s in TERM KILL; do
  _ts3c_case "h-a13-$_ts3f_s"; _ts3f_drv "$(_ts3f_nbad)" "$(_ts3c_honest_is)"; _ts3f_arm_forge_kill "$_ts3f_s" "$TS3CR"
  _ts3c_commit "$TS3CR" "a13$_ts3f_s"; TS3F_HK="$(_jr_sha "$TS3CR" HEAD)"
  _ts3f_check "ts3f: A13 (fixture control): the $_ts3f_s attacker is a machinery change (neutered bad) carrying the forge-and-signal attack in its engine" \
    "$(_ts3f_names "$TS3C_M" "$TS3F_HK")|$(git -C "$TS3CR" show "$TS3F_HK:engine/widget/lib.sh" | LC_ALL=C grep -c '^_ts3f_atk$')" "$TS3FT_/run engine/widget/lib.sh |1"
  _ts3f_dry   # the first run: the unit forges and signals the judge; it ends early
  _ts3f_check "ts3f: A13 (control): the $_ts3f_s attacker's unit ran, forged at least one clean kept judgement under a home, and signalled the judge" \
    "ran $([ -n "$(_ts3f_ran)" ] && echo yes || echo no)|forged $([ "$(LC_ALL=C grep -c '^forged ' "$TS3C/arm")" -ge 1 ] && echo yes || echo no)|killed $([ "$(LC_ALL=C grep -c "^kill $_ts3f_s " "$TS3C/arm")" -ge 1 ] && echo yes || echo no)" \
    "ran yes|forged yes|killed yes" "arm [$(tr '\n' ' ' < "$TS3C/arm")]; $(_ts3f_why)"
  _ts3f_dry   # the second run of the same candidate: the forged judgement a unit wrote is not read
  _ts3f_check "ts3f: A13: a second dry run of the same candidate, whose unit forged a clean kept judgement and ended the judge with $_ts3f_s, runs its units again rather than trusting the forged judgement, and does not merge" \
    "ran $([ -n "$(_ts3f_ran)" ] && echo yes || echo no)|$([ "$TS3CRC" -ne 0 ] && echo not-merged || echo merged)" "ran yes|not-merged" "ran [$(_ts3f_ran)]; $(_ts3f_why)"
done

# ----- A14: a judge ended by KILL leaves no unit's directory -----
# A machinery change (an honest respaced comment) runs every instrument unit; 2001-sum.sh's add() sleeps in a perl
# carrying a token, so when the judge is KILLed one unit sleeps while others have ended. Each unit prints the token to
# its log, and each tree of the run holds it in lib.sh. A14: within a few seconds nothing of the run is under TMPDIR,
# and no felix-instrument* name under /tmp or /var/tmp holds the token; any other such name new since the run began
# (a sibling judgement's) is gone once that judgement can have ended, since a leftover of this judge never goes.
_ts3c_case h-a14; _ts3f_sed "$TS3FT_/run" 's/^# The fixture suite:/#  The fixture suite:/'
_ts3f_sed engine/widget/lib.sh 's/^add() {/add() { [ "$1" != 2 ] || perl -e "sleep 20" '"${TS3F_TOK}a"';/'
printf 'printf "# %%s\\n" %s\n' "${TS3F_TOK}a" >> "$TS3CR/engine/widget/lib.sh"
printf '# a unit of this candidate sleeps while others end\n' >> "$TS3CR/$TS3FT_/parts/2001-sum.sh"; _ts3c_commit "$TS3CR" a14
_ts3f_check "ts3f: A14 (fixture control): the candidate respaces a driver comment (machinery, so every unit runs) and 2001-sum.sh's add() sleeps in a perl carrying its token" \
  "$(_ts3f_names "$TS3C_M" HEAD | tr ' ' '\n' | LC_ALL=C sort | tr '\n' ' ')|$(LC_ALL=C grep -c "perl -e \"sleep 20\" ${TS3F_TOK}a;" "$TS3CR/engine/widget/lib.sh")" \
  "$TS3FT_/parts/2001-sum.sh $TS3FT_/run engine/widget/lib.sh |1"
TS3F_FX0="$(_ts3f_tmpfx)"; _ts3f_prep
( _ts3f_go --dry-run ) > "$TS3C/out" 2> "$TS3C/err" & TS3F_PID=$!
_ts3f_i=0; while [ "$_ts3f_i" -lt 900 ] && kill -0 "$TS3F_PID" 2>/dev/null && [ "$(_ts3f_alive "${TS3F_TOK}a")" -eq 0 ]; do sleep 0.1; _ts3f_i=$((_ts3f_i + 1)); done
TS3F_MID=no; [ "$(_ts3f_alive "${TS3F_TOK}a")" -ge 1 ] && kill -0 "$TS3F_PID" 2>/dev/null && TS3F_MID=yes
kill -KILL "$TS3F_PID" 2>/dev/null; wait "$TS3F_PID" 2>/dev/null; TS3CRC=$?
_ts3f_i=0; while [ "$_ts3f_i" -lt 250 ] && { [ "$(_ts3f_left)" != nothing ] || [ "$(_ts3f_alive "${TS3F_TOK}a")" -ge 1 ]; }; do sleep 0.1; _ts3f_i=$((_ts3f_i + 1)); done
TS3F_FX1="$(_ts3f_tmpfx | LC_ALL=C comm -13 <(printf '%s\n' "$TS3F_FX0") -)"; TS3F_OWN=""; TS3F_SIB=""
while IFS= read -r _ts3f_n; do [ -n "$_ts3f_n" ] || continue   # this judge's names hold the token; the rest are read as a sibling's
  if LC_ALL=C grep -rqF -- "${TS3F_TOK}a" "$_ts3f_n" 2>/dev/null; then TS3F_OWN="$TS3F_OWN$_ts3f_n$TS3F_NL"; else TS3F_SIB="$TS3F_SIB$_ts3f_n$TS3F_NL"; fi
done < <(printf '%s\n' "$TS3F_FX1")
_ts3f_i=0; while [ "$_ts3f_i" -lt 50 ] && [ -n "$(_ts3f_gone "$TS3F_OWN")" ]; do sleep 0.1; _ts3f_i=$((_ts3f_i + 1)); done
_ts3f_check "ts3f: A14 (control): the judge was KILLed while one unit slept and others had ended" \
  "slept $TS3F_MID" "slept yes" "$(_ts3f_why)"
_ts3f_check "ts3f: A14: within a few seconds of the judge KILLed, no run tree is under TMPDIR, no unit sleeps on, and no felix-instrument* name under /tmp or /var/tmp holds this run's token" \
  "left $(_ts3f_left)|alive $(_ts3f_hangs "${TS3F_TOK}a")|own [$(_ts3f_gone "$TS3F_OWN" | tr '\n' ' ')]" "left nothing|alive 0|own []" "$(_ts3f_why)"
_ts3f_i=0; while [ "$_ts3f_i" -lt 600 ] && [ -n "$(_ts3f_gone "$TS3F_SIB")" ]; do sleep 1; _ts3f_i=$((_ts3f_i + 1)); done
_ts3f_check "ts3f: A14: every other felix-instrument* name new under /tmp or /var/tmp since the KILLed run began is gone within 600 s, as a sibling judgement's is when it ends; a leftover never goes" \
  "stayed [$(_ts3f_gone "$TS3F_SIB" | tr '\n' ' ')]" "stayed []" "new since the run began: [$(printf '%s' "$TS3F_FX1" | tr '\n' ' ')]"

# ----- A15: no window before the traps -----
# mktemp is slowed by a PATH wrapper, so a TERM can be sent very early, before the first directory the judgement makes.
# A15: the traps are set before the first directory, so nothing of the run is left and no process of it remains.
_ts3c_case h-a15; _ts3f_loosen; _ts3c_commit "$TS3CR" a15
_ts3f_check "ts3f: A15 (fixture control): the candidate changes 2001-sum.sh and its engine" \
  "$(_ts3f_names "$TS3C_M" HEAD | tr ' ' '\n' | LC_ALL=C sort | tr '\n' ' ')" "$TS3FT_/parts/2001-sum.sh engine/widget/lib.sh "
_ts3f_slowmk "${TS3F_TOK}b"; TS3F_PATH0="$TS3C/slow"; _ts3f_prep
( _ts3f_go --dry-run ) > "$TS3C/out" 2> "$TS3C/err" & TS3F_PID=$!
_ts3f_i=0; while [ "$_ts3f_i" -lt 900 ] && kill -0 "$TS3F_PID" 2>/dev/null && { [ ! -s "$TS3C/built" ] || [ -s "$TS3C/trace" ]; }; do sleep 0.1; _ts3f_i=$((_ts3f_i + 1)); done
TS3F_EARLY=no; [ -s "$TS3C/built" ] && [ ! -s "$TS3C/trace" ] && kill -0 "$TS3F_PID" 2>/dev/null && TS3F_EARLY=yes
kill -TERM "$TS3F_PID" 2>/dev/null; wait "$TS3F_PID" 2>/dev/null; TS3CRC=$?; TS3F_PATH0=""
_ts3f_i=0; while [ "$_ts3f_i" -lt 150 ] && [ "$(_ts3f_left)" != nothing ]; do sleep 0.1; _ts3f_i=$((_ts3f_i + 1)); done
_ts3f_check "ts3f: A15 (control): mktemp was slowed and the TERM was sent very early, before any unit ran" \
  "early $TS3F_EARLY|ran [$(_ts3f_ran)]" "early yes|ran []" "built [$(cat "$TS3C/built" 2>/dev/null)]; $(_ts3f_why)"
# "no process of it" is read only through what a unit would leave; the slow-mktemp injector is the fixture's own delay,
# a child of the killed judge that self-reaps, so it is not read here. The run tree and the checkout are.
_ts3f_check "ts3f: A15: a TERM sent before the first directory the judgement makes leaves no run tree under TMPDIR, no unit of it ran, and the checkout's status as it was" \
  "left $(_ts3f_left)|ran [$(_ts3f_ran)]" "left nothing|ran []" "$(_ts3f_why)"

# ----- A19: no kept judgement is read while another judgement's units could be writing one -----
# Y, the pair already kept, respaces a driver comment (machinery, so every unit runs and its judgement is kept, A5), and
# its add() answers 6 for 2 3 only while $TS3C/ybad exists: a switch outside its tree and so outside its key. With it
# off, a clean judgement is made at Y's key and its bytes saved; with it on, Y is refused and kept there. X and G are two
# more pairs over the same home, each changing 2001-sum.sh and an engine whose add 2 x holds its unit open (_ts3f_hold);
# G's unit first writes Y's saved clean judgement back over Y's kept one. A19: while X's or G's judge runs, a dry run of
# Y reads no kept judgement and runs its own units; what is kept at Y's key stays; after X has ended, Y reads it again.
_ts3c_case h-a19y; _ts3f_sed "$TS3FT_/run" 's/^# The fixture suite:/#  The fixture suite:/'
_ts3f_sed engine/widget/lib.sh "s#^add() {#add() { [ ! -e \"$TS3C/ybad\" ] || [ \"\$1 \$2\" != \"2 3\" ] || { echo 6; return; };#"
_ts3c_commit "$TS3CR" a19y; TS3F_HY="$(_jr_sha "$TS3CR" HEAD)"; rm -f "$TS3C/ybad"
_ts3f_prep; TS3F_K0="$(_ts3f_home)"; ( _ts3f_go --dry-run ) > "$TS3C/out" 2> "$TS3C/err"; TS3CRC=$?
TS3F_KY="$(_ts3f_home | LC_ALL=C comm -13 <(printf '%s\n' "$TS3F_K0") -)"; TS3F_KC="$(_ts3f_sums "$TS3F_KY")"
rm -rf "${TS3C:?}/forge"; mkdir -p "$TS3C/forge"; printf '%s\n' "$TS3F_KY" | LC_ALL=C awk 'NF' > "$TS3C/forge.list"
_ts3f_n=0; while IFS= read -r _ts3f_f; do _ts3f_n=$((_ts3f_n + 1)); cp "$_ts3f_f" "$TS3C/forge/$_ts3f_n"; done < "$TS3C/forge.list"
_ts3f_check "ts3f: A19 (fixture control): Y respaces a driver comment and switches its add() by a file outside its tree; with the switch off it is judged clean, its units run, and the judgement adds files under the home" \
  "$(_ts3f_names "$TS3C_M" "$TS3F_HY")|exit $TS3CRC|ran $([ -n "$(_ts3f_ran)" ] && echo yes || echo no)|kept $([ -n "$TS3F_KY" ] && echo yes || echo no)" \
  "$TS3FT_/run engine/widget/lib.sh |exit 0|ran yes|kept yes" "$(_ts3f_why)"
: > "$TS3C/ybad"; while IFS= read -r _ts3f_f; do rm -f "$_ts3f_f"; done < "$TS3C/forge.list"
_ts3f_dry; TS3F_KS="$(_ts3f_sums "$TS3F_KY")"; TS3F_KK=no
[ -n "$TS3F_KY" ] && [ "$TS3F_KS" != "$TS3F_KC" ] && case "$TS3F_KS" in *none*) ;; *) TS3F_KK=yes ;; esac
_ts3f_check "ts3f: A19 (fixture control): with the switch on and its clean judgement removed, Y runs its units again, is refused for 2001-sum.sh, and is kept again in the same files" \
  "$(_ts3f_refused)|$(_ts3f_bl escape 2001-sum.sh "P's version fails on this tree" 'sum: add 2 3 is 5')|ran $([ -n "$(_ts3f_ran)" ] && echo yes || echo no)|kept $TS3F_KK" "refused|yes|ran yes|kept yes" "$(_ts3f_why)"
_ts3f_dry
_ts3f_check "ts3f: A19 (control): with no other judgement running, a second dry run of Y reads its kept judgement: refused as kept, and no unit run" \
  "$(_ts3f_refused)|$(_ts3f_bl escape 2001-sum.sh "P's version fails on this tree" 'sum: add 2 3 is 5')|ran [$(_ts3f_ran)]" "refused|yes|ran []" "$(_ts3f_why)"
_ts3c_case h-a19x; _ts3f_hold "${TS3F_TOK}x"; _ts3c_commit "$TS3CR" a19x; TS3F_HX="$(_jr_sha "$TS3CR" HEAD)"
_ts3c_case h-a19g; _ts3f_hold "${TS3F_TOK}g" forge; _ts3c_commit "$TS3CR" a19g; TS3F_HG="$(_jr_sha "$TS3CR" HEAD)"
_ts3f_check "ts3f: A19 (fixture control): X and G are two more pairs, each changing 2001-sum.sh and an engine whose add 2 x holds its unit open, and only G's writes Y's clean judgement back" \
  "$(_ts3f_names "$TS3C_M" "$TS3F_HX")|$(_ts3f_names "$TS3C_M" "$TS3F_HG")|$(git -C "$TS3CR" show "$TS3F_HX:engine/widget/lib.sh" | LC_ALL=C grep -c forged)$(git -C "$TS3CR" show "$TS3F_HG:engine/widget/lib.sh" | LC_ALL=C grep -c forged)" \
  "$TS3FT_/parts/2001-sum.sh engine/widget/lib.sh |$TS3FT_/parts/2001-sum.sh engine/widget/lib.sh |01"
_ts3c_on h-a19x; _ts3f_xgo; _ts3c_on h-a19y; _ts3f_dry   # Y's dry run while X's unit holds X's judgement open
TS3F_HOLD="$(_ts3f_holding "${TS3F_TOK}x")"; TS3F_KA="$(_ts3f_sums "$TS3F_KY")"; TS3F_RAN="$(_ts3f_ran)"
_ts3f_check "ts3f: A19 (control): X's unit said it held X's judgement open before Y's dry run began, and still held it when that run ended" \
  "held $TS3F_HELD|holding $TS3F_HOLD" "held yes|holding 1" "x: $(cat "$TS3C/x.out" "$TS3C/x.err" 2>/dev/null | head -c 600 | tr '\n' ' ')"
_ts3f_check "ts3f: A19: a second dry run of a pair already kept, made while a unit of another pair's judgement holds it open over the same home, runs its own units rather than reading the kept judgement, and is refused as they find" \
  "ran $([ -n "$TS3F_RAN" ] && echo yes || echo no)|$(_ts3f_refused)|$(_ts3f_bl escape 2001-sum.sh "P's version fails on this tree" 'sum: add 2 3 is 5')" "ran yes|refused|yes" "ran [$TS3F_RAN]; $(_ts3f_why)"
_ts3f_check "ts3f: A19: what is kept at that pair's key stays through the overlapping run: its files are there, byte for byte, when the run ends" \
  "kept $TS3F_KK|$TS3F_KA" "kept yes|$TS3F_KS"
_ts3f_xend; _ts3f_dry
_ts3f_check "ts3f: A19 (control, and what is kept stays): the same dry run of Y, made after X's judgement has ended, reads the kept judgement: refused as kept, and no unit run" \
  "ended $(kill -0 "$TS3F_XP" 2>/dev/null && echo no || echo yes)|$(_ts3f_refused)|ran [$(_ts3f_ran)]" "ended yes|refused|ran []" "$(_ts3f_why)"
_ts3c_on h-a19g; _ts3f_xgo; TS3F_KG="$(_ts3f_sums "$TS3F_KY")"; _ts3c_on h-a19y; _ts3f_dry   # the same while G's unit holds
TS3F_HOLD="$(_ts3f_holding "${TS3F_TOK}g")"; TS3F_RAN="$(_ts3f_ran)"
_ts3f_check "ts3f: A19 (control): G's unit wrote Y's clean judgement back over Y's kept one, said it held G's judgement open before Y's dry run began, and still held it when that run ended" \
  "forged $(printf '%s\n' "$TS3F_ARMX" | LC_ALL=C grep -c '^forged ')|clean $([ -n "$TS3F_KY" ] && [ "$TS3F_KG" = "$TS3F_KC" ] && echo yes || echo no)|held $TS3F_HELD|holding $TS3F_HOLD" \
  "forged $(LC_ALL=C grep -c . "$TS3C/forge.list")|clean yes|held yes|holding 1" "arm [$(printf '%s' "$TS3F_ARMX" | tr '\n' ' ')]"
_ts3f_check "ts3f: A19: a clean judgement at that pair's key, written by a unit of another judgement that still runs, is not read: the pair's dry run runs its own units and is refused" \
  "ran $([ -n "$TS3F_RAN" ] && echo yes || echo no)|$(_ts3f_refused)" "ran yes|refused" "ran [$TS3F_RAN]; $(_ts3f_why)"
_ts3f_xend
_ts3f_n=0; while IFS= read -r _ts3f_f; do _ts3f_n=$((_ts3f_n + 1)); cat "$TS3C/forge/$_ts3f_n" > "$_ts3f_f"; done < "$TS3C/forge.list"
_ts3f_dry   # the same clean judgement, written back by the fixture while no judgement runs
_ts3f_check "ts3f: A19 (control): that clean judgement, written at the pair's key while no other judgement runs, is read: the pair's dry run passes and runs no unit" \
  "exit $TS3CRC|ran [$(_ts3f_ran)]" "exit 0|ran []" "$(_ts3f_why)"
rm -f "$TS3C/ybad"

# ----- A17: an honest change is judged as the checkout judges it -----
# A fixture P part tests, as part 0620 does, that a fresh directory under TMPDIR is not the checkout and the checkout
# is not under TMPDIR, and reads HOME. It passes in the checkout at H. A17: an honest machinery change (a respaced
# comment) is not refused for it, because what a part observes about where it runs does not differ from the checkout.
_ts3c_on main
_ts3c_part 2008-where.sh 'D="$(mktemp -d 2>/dev/null)"; top="$(git rev-parse --show-toplevel 2>/dev/null)"; TR="$(cd -P "${TMPDIR:-/tmp}" 2>/dev/null && pwd -P)"
_wf=diff; [ -n "$top" ] && [ "$D" = "$top" ] && _wf=same
_wu=out; case "${top:-/none}/" in "${TR%/}/"*) _wu=under ;; esac
_wh=no; [ -n "${HOME:-}" ] && [ -d "$HOME" ] && _wh=yes
is "where: a fresh directory under TMPDIR is not the checkout" "$_wf" diff
is "where: the checkout is not under the temporary root" "$_wu" out
is "where: HOME names a directory" "$_wh" yes
rm -rf "${D:?}" 2>/dev/null'
printf '. "$HERE/parts/2008-where.sh"\n' >> "$TS3CR/$TS3FT_/run" ; _ts3f_sed "$TS3FT_/run" '0,/^$/{/^$/d;}'
printf '2008-where.sh\tinstrument\tguards where it runs\n' >> "$TS3CR/$TS3F_PT"
_ts3f_mani 'where: a fresh directory under TMPDIR is not the checkout' 'where: the checkout is not under the temporary root' 'where: HOME names a directory'
_ts3c_commit "$TS3CR" where; TS3C_M="$(_jr_sha "$TS3CR" HEAD)"; _ts3f_main "$TS3C_M"
_ts3f_check "ts3f: A17 (fixture control): P now sources 2008-where.sh, an instrument part, and it passes in a real checkout of main placed outside the TMPDIR it is given" \
  "$(git -C "$TS3CR" show "$TS3C_M:$TS3FT_/run" | LC_ALL=C grep -c '2008-where.sh')|$(_ts3f_co17 "$TS3C_M" | _ts3f_fails)" "1|"
_ts3c_case h-a17; _ts3f_sed "$TS3FT_/run" 's/^# The fixture suite:/#  The fixture suite:/'; _ts3c_commit "$TS3CR" a17; TS3F_H7="$(_jr_sha "$TS3CR" HEAD)"
_ts3f_check "ts3f: A17 (fixture control): the honest candidate respaces one driver comment (a machinery change) and 2008-where.sh passes in a real checkout of H placed outside the TMPDIR it is given" \
  "$(_ts3f_names "$TS3C_M" "$TS3F_H7")|$(_ts3f_co17 "$TS3F_H7" | _ts3f_fails)" "$TS3FT_/run |"
_ts3f_dry
_ts3f_check "ts3f: A17: an honest machinery change is not refused for a P part that tests where it runs the way 0620 does: no escape line for 2008-where.sh, and P's version of it is not reported failing" \
  "$(_ts3f_bl escape 2008-where.sh - -)|$(_ts3f_bl escape 2008-where.sh "P's version fails on this tree" -)" "no|no" "$(_ts3f_why)"

_ts3c_on main
rm -rf "${TS3C:?}"; [ "$TS3F_MEM" != made ] || rm -rf "${MEM:?}/felix"
unset TS3C TS3CR TS3CK TS3CT TS3CPP TS3F_PATH0 TS3F_PID TS3F_MID TS3F_MEM TS3F_EARLY TS3F_REALMKTEMP TS3F_FX0 TS3F_FX1 TS3F_OWN TS3F_SIB \
  TS3F_XP TS3F_HELD TS3F_ARMX TS3F_HOLD TS3F_K0 TS3F_KY TS3F_KC TS3F_KS TS3F_KK TS3F_KA TS3F_KG TS3F_RAN
# <<< trust-step3-instrument-parts-d
