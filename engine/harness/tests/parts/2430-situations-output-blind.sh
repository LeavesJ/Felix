printf '\n%s\n' 'situations: the output (blind)'
# Blind, written on 2026-10-31 from docs/2026-10-29-capability-lane-first-slices-design.md (sections 3, 4, 7, 10 and 11)
# and the slice 1 plan's Contracts and Review Focus (C1-C16) alone, with the seed templates/situations.tsv and its
# schemas.tsv row, before lib/situations.sh existed, without reading felix, lib/, hooks/ or bin/. Felix is run as a black
# box. C16's row for this part: sections 7.6 to 7.8, C6 to C10, (d), (i), usage errors, need_value, C2's table refusals
# and their order, stderr empty on success; (c) on the shipped seed in a bash-harness fixture; falsifier 2 in its
# clean-machine form over a range that yields all six verdicts.
#
# Fixtures, all under $TMP/s2430:
# - home H with projects out1 (a substituted table's fixture) and bash1 (the shipped seed's bash-harness fixture);
# - X1, a copy of the engine whose situations.tsv is this part's table of nine classes, and XR, a copy whose table each
#   refusal case rewrites; $FELIX for the shipped seed;
# - checkout C1 (project out1): main is two commits, base then head, over which the nine classes read owed (all three
#   forms: DORMANT, UNKNOWN and ACTIVE with a reading that differs at base), blinded, retired, standing, could-not-look
#   (twice) and none. Every probe is a shell command over tracked files: X.list enumerates, X.mark is the witness;
# - checkout CB (project bash1): scripts/, tests/, .github/workflows/ci.yml, no manifest; main has the workflow, branch
#   drop removes it; probes.tsv grounds ci (the R4 class's surface) and scripts, and neither api nor llm;
# - stubs for gh, curl, wget, ssh, nc and claude first on PATH, each logging its argv and exiting 1, with the four keys
#   unset; HOME is a fixture directory.
# Readings where the contracts leave room:
# - A run of felix probes records each tree: the base tree from a fresh clone standing at base, then the head tree in C1,
#   so the newest recorded tree is C1's own, and --at with no flag runs the detector (C3.2). The tree ids and stamps
#   the expected text holds are read from facts.log, since the id's form is the engine's (C3.3 says the scratch id
#   equals the recorded one for a clean checkout of the same commit).
# - In --at, a residual could-not-look line's side is "at" (C10's <side>, by the Contracts' notation line).
# - "applies is split on runs of spaces": class k_odd's applies holds two spaces between its terms, and its grounds
#   string names two items, not three.
# - C2's "<k> fields": a line with no tab is "1 fields", and a trailing tab is one more (empty) field, so it is a field
#   count refusal, not an empty cell.
# - C2's stderr for the need_value case is compared whole, as the table gives it; a usage error's first line only.
# - "Their order" (C16) is read both ways: the order of the run's checks around the table (usage, project, table,
#   scratch directory, the sides), and, within the table, the first failing line with the first reason that fits it.
# - The table is "absent or unreadable" when the file is missing, and when it is mode 000 (skipped by name as root).
# - Falsifier 2's two clones each use their own memory root, holding a copy of the same facts.log bytes, their own
#   TMPDIR per run, and the same home, engine and HOME; the --change range is HEAD~1..HEAD in each.
# - (c)'s count line is asserted by its shape: N the seed's rows, A + D + U = N, U at least 1 (A at least 1 in --at),
#   so a later seed row that keeps C12's list does not break it; its pinned lines come from the seed's own cells.
# - Every assertion here reads felix situations' own output or status, so each is red on an engine without it.

S2430_D=""; mkdir -p "$TMP/s2430" && S2430_D="$(cd -P "$TMP/s2430" && pwd -P)"
S2430_BUILT=built
_s2430_nb() { [ "$S2430_BUILT" != built ] || S2430_BUILT="not built: $1"; }
[ -n "$S2430_D" ] || _s2430_nb "no fixture root"
S2430_H="$S2430_D/home"; S2430_U="$S2430_D/user"; S2430_B="$S2430_D/bin"; S2430_NET="$S2430_D/net.log"
mkdir -p "$S2430_H/projects/out1" "$S2430_H/projects/bash1" "$S2430_U" "$S2430_B" "$S2430_D/plain" "$S2430_D/r" \
  || _s2430_nb "fixture directories"
: > "$S2430_NET"
for S2430_s in gh curl wget ssh nc claude; do
  printf '#!/bin/sh\nprintf "%%s\\n" "%s $*" >> "%s"\nexit 1\n' "$S2430_s" "$S2430_NET" > "$S2430_B/$S2430_s"
  chmod +x "$S2430_B/$S2430_s" || _s2430_nb "stub $S2430_s"
done

# T ARGS... -> git ARGS where the caller stands (after _fx_cd, in a subshell): no global or system config, no hooks, no
# signing, the identity t <t@example.invalid>, author and committer time T.
_s2430_g() {
  local t="$1"
  shift
  GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid \
    GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid GIT_AUTHOR_DATE="$t +0000" GIT_COMMITTER_DATE="$t +0000" \
    git -c commit.gpgsign=false -c core.hooksPath=/dev/null -c gc.auto=0 -c core.autocrlf=false "$@"
}
# DIR T MESSAGE -> everything in DIR's working tree committed at T (additions and removals).
_s2430_commit() { ( _fx_cd "$1" || exit 1; _s2430_g "$2" add -A . && _s2430_g "$2" commit -q -m "$3" ) >/dev/null 2>&1; }
# DIR ARGS... -> git ARGS in DIR, its stdout.
_s2430_git() { ( _fx_cd "$1" || exit 1; shift; _s2430_g 1790000000 "$@" ) 2>/dev/null; }

# OUT DIR MEM CMD... -> CMD run in DIR as C13 runs felix, stdout OUT.out, stderr OUT.err, S2430_RC its status. TMPDIR is
# OUT.t, made fresh and empty, unless S2430_TOVR names another.
S2430_TOVR=""
_s2430_run() {
  local o="$1" d="$2" m="$3" t
  shift 3
  t="$o.t"; rm -rf "$t"; mkdir -p "$t"
  [ -z "$S2430_TOVR" ] || t="$S2430_TOVR"
  ( _fx_cd "$d" || exit 125
    exec env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GH_TOKEN -u GITHUB_TOKEN -u CLAUDE_CODE_SESSION_ID \
      -u FELIX_HOME_DIR -u CLAUDE_CONFIG_DIR HOME="$S2430_U" PATH="$S2430_B:$PATH" FELIX_HOME="$S2430_H" \
      FELIX_MEMORY="$m" TMPDIR="$t" "$@" ) > "$o.out" 2> "$o.err" < /dev/null
  S2430_RC=$?
}
# OUT -> status|stdout's bytes|stderr, for an error run.
_s2430_err() { printf '%s|%s|%s' "$S2430_RC" "$(wc -c < "$1.out" | tr -d ' ')" "$(cat "$1.err" 2>/dev/null)"; }
# OUT -> status|stderr|stdout with its trailing newlines kept, for a run that reports.
_s2430_ok() { printf '%s|%s|%s' "$S2430_RC" "$(cat "$1.err" 2>/dev/null)" "$(cat "$1.out" 2>/dev/null; printf .)"; }
# FILE -> FILE's bytes with trailing newlines kept.
_s2430_cat() { cat "$1" 2>/dev/null; printf .; }
# CLASS PROJECT -> the id C6 gives.
_s2430_id() { printf 'owed:%s' "$( _fx_cd "$S2430_D" && printf '%s\t%s\t%s' "$1" "$2" '*' | git hash-object --stdin | cut -c1-12 )"; }
_s2430_tsvl() { local IFS=$'\t'; printf '%s' "$*"; }

# ---- the engines -------------------------------------------------------------------------------------------------------
S2430_CBM='prototype=INFO,internal=ADVISORY,public-beta=TASK_BLOCKING,production=RELEASE_BLOCKING'
S2430_SRC='cite:0123456789ab'
for S2430_s in x1 xr; do
  mkdir -p "$S2430_D/$S2430_s" && cp -R "$FROOT/harness" "$S2430_D/$S2430_s/harness" || _s2430_nb "engine copy $S2430_s"
done
S2430_X1="$S2430_D/x1/harness/felix"; S2430_XR="$S2430_D/xr/harness/felix"
S2430_XRT="$(cd "$S2430_D/xr/harness" 2>/dev/null && pwd)/templates/situations.tsv"

# The nine classes of the substituted table, in no particular order of name; arrays are indexed alike.
S2430_K=(k_owed k_owed_unknown k_touched k_blinded k_retired k_standing k_cnl k_none k_odd)
S2430_A=('cap:own' 'cap:ou' 'probe:tch=found' 'cap:blnd' 'cap:ret' 'cap:std' 'cap:cnl probe:ghost=found'
  'cap:non env:maturity>=internal' 'cap:std  weird')
S2430_O=('an owed surface, brought in' 'owed though the base could not look' 'a surface the change touched'
  'a surface the change blinded' 'a surface the change removed' "keep 100%s of the '\\n' bound, byte for byte"
  'what could not be looked at' 'nothing here owes' 'an odd term beside a true one')
S2430_BS=(DORMANT UNKNOWN ACTIVE ACTIVE ACTIVE ACTIVE UNKNOWN DORMANT UNKNOWN)
S2430_HS=(ACTIVE ACTIVE ACTIVE UNKNOWN DORMANT ACTIVE UNKNOWN DORMANT UNKNOWN)
S2430_V=(owed owed owed blinded retired standing could-not-look none could-not-look)
S2430_BG=('p_own empty (own)' 'p_ou blind (ou)' 'p_tch found (tch)' 'p_blnd found (blnd)' 'p_ret found (ret)'
  'p_std found (std)' 'p_cnl blind (cnl), ghost no probe' 'p_non empty (non), maturity undeclared'
  'p_std found (std), weird unbound')
S2430_HG=('p_own found (own)' 'p_ou found (ou)' 'p_tch found (tch)' 'p_blnd blind (blnd)' 'p_ret empty (ret)'
  'p_std found (std)' 'p_cnl blind (cnl), ghost no probe' 'p_non empty (non), maturity undeclared'
  'p_std found (std), weird unbound')
S2430_BR=('p_own=empty/0' 'p_ou=blind/0' 'p_tch=found/1' 'p_blnd=found/1' 'p_ret=found/1' 'p_std=found/1' 'p_cnl=blind/0'
  'p_non=empty/0' 'p_std=found/1')
S2430_HR=('p_own=found/1' 'p_ou=found/1' 'p_tch=found/2' 'p_blnd=blind/0' 'p_ret=empty/0' 'p_std=found/1' 'p_cnl=blind/0'
  'p_non=empty/0' 'p_std=found/1')
S2430_BW=('p_own empty' '' '' '' '' '' '' 'p_non empty' '')
S2430_HW=('' '' '' '' 'p_ret empty' '' '' 'p_non empty' '')
S2430_ID=(); S2430_i=0
while [ "$S2430_i" -lt 9 ]; do S2430_ID[$S2430_i]="$(_s2430_id "${S2430_K[$S2430_i]}" out1)"; S2430_i=$((S2430_i + 1)); done
# The indices in byte order of class name, for the human sections.
S2430_ORD="$(S2430_i=0; while [ "$S2430_i" -lt 9 ]; do printf '%s\t%s\n' "${S2430_K[$S2430_i]}" "$S2430_i"; S2430_i=$((S2430_i + 1)); done \
  | LC_ALL=C sort | cut -f2 | tr '\n' ' ')"
# The table: comments (indented ones too), a blank line and a line of blanks, rows out of name order.
{ printf '# The substituted table of part 2430.\n# class\tapplies\towes\tclass_by_maturity\tsource\n\n'
  for S2430_i in 2 0 8 3 6 1; do
    printf '%s\n' "$(_s2430_tsvl "${S2430_K[$S2430_i]}" "${S2430_A[$S2430_i]}" "${S2430_O[$S2430_i]}" "$S2430_CBM" "$S2430_SRC")"
  done
  printf '   # an indented comment\n \t \n'
  for S2430_i in 7 4 5; do
    printf '%s\n' "$(_s2430_tsvl "${S2430_K[$S2430_i]}" "${S2430_A[$S2430_i]}" "${S2430_O[$S2430_i]}" "$S2430_CBM" "$S2430_SRC")"
  done
} > "$S2430_D/x1/harness/templates/situations.tsv" || _s2430_nb "the substituted table"

# ---- the home ----------------------------------------------------------------------------------------------------------
for S2430_s in out1 bash1; do
  printf '{"name":"%s","remote_match":"example.invalid/%s","gate":"true"}\n' "$S2430_s" "$S2430_s" \
    > "$S2430_H/projects/$S2430_s/project.json"
  printf '# %s\n' "$S2430_s" > "$S2430_H/projects/$S2430_s/CLAUDE.md"
done
: > "$S2430_H/projects/out1/probes.tsv"
for S2430_s in own ou tch blnd ret std cnl non spare; do
  printf 'p_%s\t%s\t-\ttest ! -e %s.list || cat %s.list\ttest -e %s.mark\n' "$S2430_s" "$S2430_s" "$S2430_s" "$S2430_s" "$S2430_s" \
    >> "$S2430_H/projects/out1/probes.tsv"
done
printf 'ci_workflows\tci\t-\ttest ! -d .github/workflows || ls -1 .github/workflows\ttest -e .github\n' \
  > "$S2430_H/projects/bash1/probes.tsv"
printf 'shell_scripts\tscripts\t-\ttest ! -d scripts || ls -1 scripts\ttest -e scripts\n' >> "$S2430_H/projects/bash1/probes.tsv"

# ---- checkout C1 (out1): base, then head ---------------------------------------------------------------------------------
S2430_C="$S2430_D/c1"; mkdir -p "$S2430_C"
( _fx_cd "$S2430_C" && _s2430_g 1790000000 init -q -b main ) >/dev/null 2>&1 || _s2430_nb "C1's init"
printf 'out1\n' > "$S2430_C/.felix"
printf 't1\n' > "$S2430_C/tch.list"; printf 'b1\n' > "$S2430_C/blnd.list"; printf 'r1\n' > "$S2430_C/ret.list"
printf 's1\n' > "$S2430_C/std.list"; printf 'x1\n' > "$S2430_C/spare.list"
: > "$S2430_C/ou.mark"; : > "$S2430_C/blnd.mark"; : > "$S2430_C/cnl.mark"
_s2430_commit "$S2430_C" 1790000000 base || _s2430_nb "C1's base commit"
printf 'o1\n' > "$S2430_C/own.list"; printf 'u1\n' > "$S2430_C/ou.list"; printf 't1\nt2\n' > "$S2430_C/tch.list"
rm -f "$S2430_C/blnd.list" "$S2430_C/ret.list"
_s2430_commit "$S2430_C" 1790000100 head || _s2430_nb "C1's head commit"
S2430_B40="$(_s2430_git "$S2430_C" rev-parse HEAD~1)"; S2430_H40="$(_s2430_git "$S2430_C" rev-parse HEAD)"
case "$S2430_B40$S2430_H40" in *[!0-9a-f]*|'') _s2430_nb "C1's commits" ;; esac
[ -z "$(_s2430_git "$S2430_C" status --porcelain)" ] || _s2430_nb "C1 is not clean"

# The recorded trees: the base from a clone standing at base, then the head in C1, into memory root M.
S2430_M="$S2430_D/mem"; mkdir -p "$S2430_M"
( _fx_cd "$S2430_D" && _s2430_g 1790000000 clone -q "$S2430_C" tid-base ) >/dev/null 2>&1 \
  && ( _fx_cd "$S2430_D/tid-base" && _s2430_g 1790000000 checkout -q --detach "$S2430_B40" ) >/dev/null 2>&1 \
  || _s2430_nb "the base clone"
_s2430_run "$S2430_D/r/pb" "$S2430_D/tid-base" "$S2430_M" "$FELIX" probes; [ "$S2430_RC" = 0 ] || _s2430_nb "felix probes at base"
S2430_BT="$(LC_ALL=C awk -F'\t' 'NF >= 8 { t = $2 } END { print t }' "$S2430_M/out1/facts.log" 2>/dev/null)"
S2430_BSTAMP="$(LC_ALL=C awk -F'\t' 'NF >= 8 { s = $1 } END { print s }' "$S2430_M/out1/facts.log" 2>/dev/null)"
_s2430_run "$S2430_D/r/ph" "$S2430_C" "$S2430_M" "$FELIX" probes; [ "$S2430_RC" = 0 ] || _s2430_nb "felix probes at head"
S2430_HT="$(LC_ALL=C awk -F'\t' 'NF >= 8 { t = $2 } END { print t }' "$S2430_M/out1/facts.log" 2>/dev/null)"
S2430_HSTAMP="$(LC_ALL=C awk -F'\t' 'NF >= 8 { s = $1 } END { print s }' "$S2430_M/out1/facts.log" 2>/dev/null)"
[ -n "$S2430_BT" ] && [ -n "$S2430_HT" ] && [ "$S2430_BT" != "$S2430_HT" ] || _s2430_nb "two recorded trees"
[ -z "$(_s2430_git "$S2430_C" status --porcelain)" ] || _s2430_nb "felix probes left C1 unclean"

# ---- checkout CB (bash1): main with the workflow, drop without it ----------------------------------------------------
S2430_CB="$S2430_D/cb"; mkdir -p "$S2430_CB/scripts" "$S2430_CB/tests" "$S2430_CB/.github/workflows"
( _fx_cd "$S2430_CB" && _s2430_g 1790000000 init -q -b main ) >/dev/null 2>&1 || _s2430_nb "CB's init"
printf 'bash1\n' > "$S2430_CB/.felix"
printf '#!/bin/sh\necho build\n' > "$S2430_CB/scripts/build.sh"
printf '#!/bin/sh\nsh scripts/build.sh\n' > "$S2430_CB/tests/run.sh"
printf 'on: push\njobs:\n  t:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - run: sh tests/run.sh\n' \
  > "$S2430_CB/.github/workflows/ci.yml"
_s2430_commit "$S2430_CB" 1790000000 'a bash harness' || _s2430_nb "CB's first commit"
( _fx_cd "$S2430_CB" && _s2430_g 1790000000 checkout -q -b drop ) >/dev/null 2>&1 || _s2430_nb "CB's branch"
rm -rf "$S2430_CB/.github"
_s2430_commit "$S2430_CB" 1790000100 'the workflow removed' || _s2430_nb "CB's second commit"
( _fx_cd "$S2430_CB" && _s2430_g 1790000000 checkout -q main ) >/dev/null 2>&1 || _s2430_nb "CB back on main"
[ -f "$S2430_CB/.github/workflows/ci.yml" ] || _s2430_nb "CB's workflow"
S2430_MB="$S2430_D/mem-bash"; mkdir -p "$S2430_MB"
_s2430_run "$S2430_D/r/pbash" "$S2430_CB" "$S2430_MB" "$FELIX" probes; [ "$S2430_RC" = 0 ] || _s2430_nb "felix probes in CB"
: > "$S2430_NET"

# ---- the expected text ---------------------------------------------------------------------------------------------
S2430_SENT='the witness says this surface exists and the probe enumerated none of it'
S2430_REC='when recorded; the fact log keeps no sentence'
# MODE (c for --change, h for --at the head tree, b for --at the base tree) -> the residual's lines, as --tsv prints them.
_s2430_resid() {
  {
    case "$1" in
      c) printf 'residual\tcould-not-look\tk_blinded\thead: cap:blnd: p_blnd read blind: %s\n' "$S2430_SENT"
         printf 'residual\tcould-not-look\tk_owed_unknown\tbase: cap:ou: p_ou read blind: %s\n' "$S2430_SENT"
         for S2430_s in base head; do
           printf 'residual\tcould-not-look\tk_cnl\t%s: cap:cnl: p_cnl read blind: %s\n' "$S2430_s" "$S2430_SENT"
           printf 'residual\tcould-not-look\tk_cnl\t%s: probe:ghost=found: no probe grounds ghost\n' "$S2430_s"
           printf 'residual\tcould-not-look\tk_odd\t%s: weird: not a term this slice can evaluate\n' "$S2430_s"
         done ;;
      h|b) [ "$1" = b ] && printf 'residual\tcould-not-look\tk_owed_unknown\tat: cap:ou: p_ou read blind %s\n' "$S2430_REC"
         [ "$1" = h ] && printf 'residual\tcould-not-look\tk_blinded\tat: cap:blnd: p_blnd read blind %s\n' "$S2430_REC"
         printf 'residual\tcould-not-look\tk_cnl\tat: cap:cnl: p_cnl read blind %s\n' "$S2430_REC"
         printf 'residual\tcould-not-look\tk_cnl\tat: probe:ghost=found: no probe grounds ghost\n'
         printf 'residual\tcould-not-look\tk_odd\tat: weird: not a term this slice can evaluate\n' ;;
    esac
    printf 'residual\tno-row\tspare\tnamed by probe p_spare\n'
    printf 'residual\tunbound\tenv:maturity>=internal\tproject.json declares no maturity\n'
    printf 'residual\tunbound\tprobe:ghost=found\tno row of probes.tsv grounds ghost\n'
    printf 'residual\tunbound\tweird\tnot a term this slice can evaluate\n'
  } | LC_ALL=C sort -u
}
# MODE INDEX -> the class's verdict token in MODE.
_s2430_verdict() {
  local s
  case "$1" in c) printf '%s' "${S2430_V[$2]}"; return ;; h) s="${S2430_HS[$2]}" ;; *) s="${S2430_BS[$2]}" ;; esac
  case "$s" in ACTIVE) printf standing ;; UNKNOWN) printf could-not-look ;; *) printf none ;; esac
}
_s2430_rank() { case "$1" in owed) echo 1 ;; blinded) echo 2 ;; retired) echo 3 ;; standing) echo 4 ;; could-not-look) echo 5 ;; *) echo 6 ;; esac; }
# MODE -> the expected --tsv.
_s2430_tsv() {
  local m="$1" i=0 v
  while [ "$i" -lt 9 ]; do
    v="$(_s2430_verdict "$m" "$i")"
    case "$m" in
      c) printf '%s\t%s\n' "$(_s2430_rank "$v")" "$(_s2430_tsvl "${S2430_ID[$i]}" "${S2430_K[$i]}" "$v" "${S2430_BS[$i]}" \
           "${S2430_HS[$i]}" "${S2430_BG[$i]}" "${S2430_HG[$i]}" "${S2430_O[$i]}")" ;;
      h) printf '%s\t%s\n' "$(_s2430_rank "$v")" "$(_s2430_tsvl "${S2430_ID[$i]}" "${S2430_K[$i]}" "$v" - \
           "${S2430_HS[$i]}" - "${S2430_HG[$i]}" "${S2430_O[$i]}")" ;;
      b) printf '%s\t%s\n' "$(_s2430_rank "$v")" "$(_s2430_tsvl "${S2430_ID[$i]}" "${S2430_K[$i]}" "$v" - \
           "${S2430_BS[$i]}" - "${S2430_BG[$i]}" "${S2430_O[$i]}")" ;;
    esac
    i=$((i + 1))
  done | LC_ALL=C sort | cut -f2-
  _s2430_resid "$m"
}
# MODE -> the expected human report.
_s2430_human() {
  local m="$1" sec i n v a=0 d=0 u=0 st
  printf 'situations for out1\n'
  case "$m" in
    c) printf '  base  %s  tree %s  scratch checkout, tracked content only, current probes.tsv\n' "$S2430_B40" "$S2430_BT"
       printf '  head  %s  tree %s  scratch checkout, tracked content only, current probes.tsv\n' "$S2430_H40" "$S2430_HT" ;;
    h) printf '  at  %s  tree %s  recorded %s  detector run on this checkout\n' "$S2430_H40" "$S2430_HT" "$S2430_HSTAMP" ;;
    b) printf '  at  -  tree %s  recorded %s  detector not run: this checkout is not at this tree\n' "$S2430_BT" "$S2430_BSTAMP" ;;
  esac
  for sec in owed blinded retired standing; do
    [ "$m" = c ] || [ "$sec" = standing ] || continue
    printf '\n%s\n' "$sec"; n=0
    for i in $S2430_ORD; do
      v="$(_s2430_verdict "$m" "$i")"
      [ "$v" = "$sec" ] || continue
      n=$((n + 1))
      if [ "$m" = c ]; then
        printf '  %s  %s  %s -> %s\n' "${S2430_ID[$i]}" "${S2430_K[$i]}" "${S2430_BS[$i]}" "${S2430_HS[$i]}"
        printf '    grounds  base: %s; head: %s\n' "${S2430_BG[$i]}" "${S2430_HG[$i]}"
        printf '    readings  base: %s; head: %s\n' "${S2430_BR[$i]}" "${S2430_HR[$i]}"
        [ "${S2430_BS[$i]}" != DORMANT ] || [ -z "${S2430_BW[$i]}" ] || printf '    witness  base: %s\n' "${S2430_BW[$i]}"
        [ "${S2430_HS[$i]}" != DORMANT ] || [ -z "${S2430_HW[$i]}" ] || printf '    witness  head: %s\n' "${S2430_HW[$i]}"
      elif [ "$m" = h ]; then
        printf '  %s  %s  ACTIVE\n    grounds  %s\n    readings  %s\n' "${S2430_ID[$i]}" "${S2430_K[$i]}" "${S2430_HG[$i]}" "${S2430_HR[$i]}"
      else
        printf '  %s  %s  ACTIVE\n    grounds  %s\n    readings  %s\n' "${S2430_ID[$i]}" "${S2430_K[$i]}" "${S2430_BG[$i]}" "${S2430_BR[$i]}"
      fi
      printf '    owes  %s\n' "${S2430_O[$i]}"
    done
    [ "$n" -gt 0 ] || printf '  none\n'
  done
  printf '\nresidual\n'
  _s2430_resid "$m" | LC_ALL=C awk -F'\t' '{ printf "  %s  %s  %s\n", $2, $3, $4 }'
  i=0
  while [ "$i" -lt 9 ]; do
    if [ "$m" = b ]; then st="${S2430_BS[$i]}"; else st="${S2430_HS[$i]}"; fi
    case "$st" in ACTIVE) a=$((a + 1)) ;; DORMANT) d=$((d + 1)) ;; *) u=$((u + 1)) ;; esac
    i=$((i + 1))
  done
  printf '\nexamined 9, active %s, dormant %s, could not look %s\n' "$a" "$d" "$u"
}
mkdir -p "$S2430_D/exp"
for S2430_s in c h b; do
  _s2430_tsv "$S2430_s" > "$S2430_D/exp/$S2430_s.tsv"; _s2430_human "$S2430_s" > "$S2430_D/exp/$S2430_s.txt"
done
S2430_E="$S2430_D/exp"

# ---- C1 and C2: -h, --help, usage errors and need_value ---------------------------------------------------------------
S2430_USE='    felix situations [--at T | --change [B..H]] [--tsv | --propose]
                           what a change owes: the situation rows it owes, blinds and retires,
                           the rows already standing, and what could not be looked at; writes nothing'
S2430_R="$S2430_D/r"
_s2430_run "$S2430_R/help" "$S2430_C" "$S2430_M" "$FELIX" help
S2430_a=""
for S2430_s in -h --help '-h --tsv' '--help --bogus'; do
  # shellcheck disable=SC2086
  _s2430_run "$S2430_R/hh" "$S2430_C" "$S2430_M" "$FELIX" situations $S2430_s
  S2430_x=other; cmp -s "$S2430_R/hh.out" "$S2430_R/help.out" && S2430_x=usage
  case $'\n'"$(cat "$S2430_R/hh.out")"$'\n' in *$'\n'"$S2430_USE"$'\n'*) S2430_x="$S2430_x+three" ;; esac
  S2430_a="$S2430_a [$S2430_s] $S2430_RC|$S2430_x"
done
is "2430 felix situations -h, --help, -h --tsv and --help --bogus print felix help's stdout, exit 0, and hold C1's three usage lines" \
   "$S2430_a" " [-h] 0|usage+three [--help] 0|usage+three [-h --tsv] 0|usage+three [--help --bogus] 0|usage+three"
_s2430_run "$S2430_R/hp" "$S2430_D/plain" "$S2430_M" "$FELIX" situations --help
S2430_x=other; cmp -s "$S2430_R/hp.out" "$S2430_R/help.out" && S2430_x=usage
case $'\n'"$(cat "$S2430_R/hp.out")"$'\n' in *$'\n'"$S2430_USE"$'\n'*) S2430_x="$S2430_x+three" ;; esac
is "2430 where no project governs, felix situations --help prints the same usage and exits 0" "$S2430_RC|$S2430_x" "0|usage+three"

# LABEL DIR ARGS... -> felix situations ARGS in DIR (engine X1) is a usage error: 2, nothing on stdout, the usage line first.
_s2430_usage() {
  local l="$1" d="$2" f
  shift 2
  _s2430_run "$S2430_R/u" "$d" "$S2430_M" "$S2430_X1" situations "$@"
  f="$(LC_ALL=C awk 'NR == 1' "$S2430_R/u.err")"
  case "$f" in 'felix: usage: felix situations'*) f=usage ;; esac
  is "2430 felix situations $l is a usage error: exit 2, stdout empty, stderr's first line begins felix: usage: felix situations" \
     "$S2430_RC|$(wc -c < "$S2430_R/u.out" | tr -d ' ')|$f" "2|0|usage"
}
_s2430_usage '--bogus' "$S2430_C" --bogus
_s2430_usage 'extra (a bare word)' "$S2430_C" extra
_s2430_usage '--tsv extra' "$S2430_C" --tsv extra
_s2430_usage '--at=x (no = form)' "$S2430_C" --at=x
_s2430_usage '--tsv --propose' "$S2430_C" --tsv --propose
_s2430_usage '--propose --tsv' "$S2430_C" --propose --tsv
_s2430_usage '--tsv --tsv' "$S2430_C" --tsv --tsv
_s2430_usage '--propose --propose' "$S2430_C" --propose --propose
_s2430_usage '--at x --change' "$S2430_C" --at x --change
_s2430_usage '--change --at x' "$S2430_C" --change --at x
_s2430_usage '--change HEAD~1..HEAD --at x' "$S2430_C" --change HEAD~1..HEAD --at x
_s2430_usage '--at x --at y' "$S2430_C" --at x --at y
_s2430_usage '--change --change' "$S2430_C" --change --change
_s2430_usage '--change main (no ..)' "$S2430_C" --change main
_s2430_usage '--change HEAD~1...HEAD (three dots)' "$S2430_C" --change 'HEAD~1...HEAD'
_s2430_usage '--change ..HEAD (empty base half)' "$S2430_C" --change ..HEAD
_s2430_usage '--change HEAD.. (empty head half)' "$S2430_C" --change HEAD..
_s2430_usage '--change a..b..c (.. in the head half)' "$S2430_C" --change a..b..c
_s2430_usage '--change -x (not a range, then an unknown flag)' "$S2430_C" --change -x
_s2430_usage '--tsv -h (-h not first)' "$S2430_C" --tsv -h
_s2430_usage '--at x --at (twice, before its value is looked at)' "$S2430_C" --at x --at
_s2430_usage '--change --at (a conflict, before its value is looked at)' "$S2430_C" --change --at
_s2430_usage '--bogus --at (the first failing argument decides)' "$S2430_C" --bogus --at
_s2430_usage '--tsv --tsv --at (the first failing argument decides)' "$S2430_C" --tsv --tsv --at
_s2430_usage '--bogus where no project governs (usage is found first)' "$S2430_D/plain" --bogus
_s2430_usage '--tsv --propose where no project governs' "$S2430_D/plain" --tsv --propose

S2430_NV='felix: felix: --at needs a value'
_s2430_run "$S2430_R/n1" "$S2430_C" "$S2430_M" "$S2430_X1" situations --at
S2430_a="$(_s2430_err "$S2430_R/n1")"
_s2430_run "$S2430_R/n2" "$S2430_C" "$S2430_M" "$S2430_X1" situations --at ''
S2430_a="$S2430_a / $(_s2430_err "$S2430_R/n2")"
_s2430_run "$S2430_R/n3" "$S2430_C" "$S2430_M" "$S2430_X1" situations --tsv --at
S2430_a="$S2430_a / $(_s2430_err "$S2430_R/n3")"
_s2430_run "$S2430_R/n4" "$S2430_C" "$S2430_M" "$S2430_X1" situations --at '' --bogus
S2430_a="$S2430_a / $(_s2430_err "$S2430_R/n4")"
_s2430_run "$S2430_R/n5" "$S2430_D/plain" "$S2430_M" "$S2430_X1" situations --at
S2430_a="$S2430_a / $(_s2430_err "$S2430_R/n5")"
is "2430 --at with no value, an empty one, --tsv --at, --at '' --bogus, and --at where no project governs: exit 1, stdout empty, need_value's sentence alone" \
   "$S2430_a" "1|0|$S2430_NV / 1|0|$S2430_NV / 1|0|$S2430_NV / 1|0|$S2430_NV / 1|0|$S2430_NV"
S2430_NR="felix situations: the recorded tree could not be read: no run is recorded for tree"
_s2430_run "$S2430_R/n6" "$S2430_C" "$S2430_M" "$S2430_X1" situations --at --tsv
S2430_a="$(_s2430_err "$S2430_R/n6")"
_s2430_run "$S2430_R/n7" "$S2430_C" "$S2430_M" "$S2430_X1" situations --at -h
is "2430 need_value refuses only a missing or empty value: --at --tsv and --at -h read the trees --tsv and -h, which no run records (exit 3)" \
   "$S2430_a / $(_s2430_err "$S2430_R/n7")" \
   "3|0|$S2430_NR --tsv in $S2430_M/out1/facts.log / 3|0|$S2430_NR -h in $S2430_M/out1/facts.log"
_s2430_run "$S2430_R/n8" "$S2430_C" "$S2430_M" "$S2430_X1" situations --change v1.2..v1.3
is "2430 --change v1.2..v1.3 is a range, not a usage error: its base half is read and is not a commit here (exit 3)" \
   "$(_s2430_err "$S2430_R/n8")" "3|0|felix situations: base could not be read: v1.2 is not a commit here"
_s2430_run "$S2430_R/n9" "$S2430_D/plain" "$S2430_M" "$S2430_X1" situations
S2430_a="$(LC_ALL=C awk 'NR == 1' "$S2430_R/n9.err")"
case "$S2430_a" in 'felix: no project governs'*) S2430_a=ungoverned ;; esac
is "2430 felix situations where no project governs: exit 2, stdout empty, stderr begins felix: no project governs" \
   "$S2430_RC|$(wc -c < "$S2430_R/n9.out" | tr -d ' ')|$S2430_a" "2|0|ungoverned"

# ---- C2: the table's refusals, each with its line number ---------------------------------------------------------------
S2430_TP="felix situations: the situation table could not be read: $S2430_XRT:"
# LABEL BYTES WHY -> XR's table holds BYTES; felix situations (at the newest tree) exits 3 with the one line naming WHY.
_s2430_tbl() {
  printf '%s' "$2" > "$S2430_XRT"
  _s2430_run "$S2430_R/t" "$S2430_C" "$S2430_M" "$S2430_XR" situations
  is "2430 table: $1: exit 3, stdout empty, one line naming the table and its reason" \
     "$S2430_BUILT|$(_s2430_err "$S2430_R/t")" "built|3|0|$S2430_TP $3"
}
_s2430_r() { _s2430_tsvl "$1" "${2-cap:x}" "${3-owed}" "${4-$S2430_CBM}" "${5-$S2430_SRC}"; }
S2430_n=$'\n'
rm -f "$S2430_XRT"
_s2430_run "$S2430_R/t" "$S2430_C" "$S2430_M" "$S2430_XR" situations
is "2430 table: absent: exit 3, stdout empty, one line: the situation table could not be read: <path>: it is absent or unreadable" \
   "$S2430_BUILT|$(_s2430_err "$S2430_R/t")" "built|3|0|$S2430_TP it is absent or unreadable"
if [ "$(id -u)" = 0 ]; then
  skip "2430 table: mode 000 is absent or unreadable" "run as root, who reads a file of mode 000"
else
  printf '%s\n' "$(_s2430_r a)" > "$S2430_XRT"; chmod 000 "$S2430_XRT"
  _s2430_run "$S2430_R/t" "$S2430_C" "$S2430_M" "$S2430_XR" situations
  chmod 644 "$S2430_XRT"
  is "2430 table: mode 000 is absent or unreadable: exit 3 with that line" \
     "$S2430_BUILT|$(_s2430_err "$S2430_R/t")" "built|3|0|$S2430_TP it is absent or unreadable"
fi
_s2430_tbl "an empty file" "" "it holds no row"
_s2430_tbl "comments (indented, tab-indented), a blank line and a line of blanks only" \
  "# only comments$S2430_n   # indented$S2430_n"$'\t'"# tab-indented$S2430_n$S2430_n "$'\t'" $S2430_n" "it holds no row"
_s2430_tbl "four fields on physical line 3, after a comment and a blank line" \
  "# head$S2430_n$S2430_n$(_s2430_tsvl a cap:x owed "$S2430_CBM")$S2430_n" "line 3: 4 fields where a row has 5"
_s2430_tbl "six fields on line 2" "$(_s2430_r a)$S2430_n$(_s2430_r b)"$'\t'"extra$S2430_n" "line 2: 6 fields where a row has 5"
_s2430_tbl "a line with no tab" "just words$S2430_n" "line 1: 1 fields where a row has 5"
_s2430_tbl "a trailing tab is a sixth field" "$(_s2430_r a)"$'\t'"$S2430_n" "line 1: 6 fields where a row has 5"
_s2430_tbl "an empty applies cell" "$(_s2430_r a '')$S2430_n" "line 1: cell 2 is empty"
_s2430_tbl "the first empty cell is named (owes and source empty)" "$(_s2430_r a cap:x '' "$S2430_CBM" '')$S2430_n" \
  "line 1: cell 3 is empty"
_s2430_tbl "an empty class cell" "$(_s2430_r '')$S2430_n" "line 1: cell 1 is empty"
_s2430_tbl "an empty cell before a bad class (the first reason that fits)" "$(_s2430_r Bad '')$S2430_n" "line 1: cell 2 is empty"
_s2430_tbl "class Bad-Class" "$(_s2430_r Bad-Class)$S2430_n" "line 1: class 'Bad-Class' is not [a-z][a-z0-9_]*"
_s2430_tbl "class 9lives" "$(_s2430_r ok)$S2430_n$(_s2430_r 9lives)$S2430_n" "line 2: class '9lives' is not [a-z][a-z0-9_]*"
_s2430_tbl "a class of one space is not empty" "$(_s2430_r ' ')$S2430_n" "line 1: class ' ' is not [a-z][a-z0-9_]*"
_s2430_tbl "a bad class before a bad source" "$(_s2430_r A cap:x owed "$S2430_CBM" ref:x)$S2430_n" \
  "line 1: class 'A' is not [a-z][a-z0-9_]*"
_s2430_tbl "a class twice, the second on physical line 4" \
  "$(_s2430_r a)$S2430_n$S2430_n$(_s2430_r b)$S2430_n$(_s2430_r a)$S2430_n" "line 4: class 'a' appears twice"
_s2430_tbl "a class twice on line 2 before a bad source on line 3" \
  "$(_s2430_r a)$S2430_n$(_s2430_r a)$S2430_n$(_s2430_r c cap:x owed "$S2430_CBM" cite:1)$S2430_n" "line 2: class 'a' appears twice"
_s2430_tbl "an applies of blanks holds no term" "$(_s2430_r a '   ')$S2430_n" "line 1: applies holds no term"
_s2430_tbl "an applies with no term before a bad class_by_maturity" "$(_s2430_r a ' ' owed 'prototype=INFO')$S2430_n" \
  "line 1: applies holds no term"
S2430_CBX='does not name each of prototype internal public-beta production once with a class of INFO ADVISORY TASK_BLOCKING RELEASE_BLOCKING AUTHORITY_BLOCKING'
for S2430_s in 'prototype=INFO,internal=INFO,public-beta=INFO' \
               'prototype=INFO,prototype=INFO,public-beta=INFO,production=INFO' \
               'prototype=info,internal=INFO,public-beta=INFO,production=INFO' \
               'prototype=INFO, internal=INFO,public-beta=INFO,production=INFO' \
               'prototype=BLOCKING,internal=INFO,public-beta=INFO,production=INFO' \
               'prototype=INFO,internal=INFO,public-beta=INFO,production=INFO,' \
               'prototype=INFO,internal=INFO,public-beta=INFO,production=INFO,staging=INFO'; do
  _s2430_tbl "class_by_maturity '$S2430_s'" "$(_s2430_r ok)$S2430_n$(_s2430_r a cap:x owed "$S2430_s")$S2430_n" \
    "line 2: class_by_maturity '$S2430_s' $S2430_CBX"
done
_s2430_tbl "a bad class_by_maturity before a bad source" "$(_s2430_r a cap:x owed 'x=y' bad)$S2430_n" \
  "line 1: class_by_maturity 'x=y' $S2430_CBX"
S2430_SX='is not miss:, candidate: or cite: and 12 lowercase hex digits'
for S2430_s in cite:0123456789AB cite:0123456789a cite:0123456789abc ref:0123456789ab cite: miss0123456789ab; do
  _s2430_tbl "source '$S2430_s'" "$(_s2430_r a cap:x owed "$S2430_CBM" "$S2430_s")$S2430_n" "line 1: source '$S2430_s' $S2430_SX"
done
_s2430_tbl "the first failing line is named: a bad source on line 2 before four fields on line 3" \
  "$(_s2430_r a)$S2430_n$(_s2430_r b cap:x owed "$S2430_CBM" cite:zz)$S2430_n$(_s2430_tsvl c cap:x owed x)$S2430_n" \
  "line 2: source 'cite:zz' $S2430_SX"
_s2430_tbl "a last line with no newline is a row" "$(_s2430_r a)$S2430_n$(_s2430_r b cap:x owed "$S2430_CBM" cite:xyz)" \
  "line 2: source 'cite:xyz' $S2430_SX"
# Controls: tables C2 accepts, though C12's other rules (a probe: term on blind, a decreasing cell) do not hold of them.
printf '%s' "  # indented$S2430_n$(_s2430_r a 'probe:x=blind' owed \
  'production=INFO,prototype=AUTHORITY_BLOCKING,public-beta=ADVISORY,internal=TASK_BLOCKING' miss:00000000000f)$S2430_n \
$S2430_n$(_s2430_r b 'cap:x  env:other>=1' '   ' "$S2430_CBM" candidate:abcdef012345)" > "$S2430_XRT"
_s2430_run "$S2430_R/tok" "$S2430_C" "$S2430_M" "$S2430_XR" situations --tsv
is "2430 table: indented comments, a line of blanks, classes in any order, a cell of blanks, no last newline and C12-only breaches are read: exit 0, stderr empty, two class lines" \
   "$S2430_BUILT|$S2430_RC|$(cat "$S2430_R/tok.err")|$(LC_ALL=C awk -F'\t' '$1 ~ /^owed:/ { n++ } END { print n + 0 }' "$S2430_R/tok.out")" \
   "built|0||2"

# ---- C2's order: usage, project, table, scratch directory, then the sides ----------------------------------------------
rm -f "$S2430_XRT"
S2430_BADT="$S2430_D/no-such-tmp"
S2430_SC="felix situations: the scratch directory could not be made: mktemp -d failed under $S2430_BADT"
_s2430_run "$S2430_R/o1" "$S2430_C" "$S2430_M" "$S2430_XR" situations --bogus
S2430_a="$S2430_RC|$(LC_ALL=C awk 'NR == 1 { print substr($0, 1, 30) }' "$S2430_R/o1.err")"
_s2430_run "$S2430_R/o2" "$S2430_D/plain" "$S2430_M" "$S2430_XR" situations
S2430_a="$S2430_a / $S2430_RC|$(LC_ALL=C awk 'NR == 1 { print substr($0, 1, 25) }' "$S2430_R/o2.err")"
is "2430 order: an absent table: a usage error is found before it (2), and a directory no project governs before it (2)" \
   "$S2430_a" "2|felix: usage: felix situations / 2|felix: no project governs"
_s2430_run "$S2430_R/o3" "$S2430_C" "$S2430_M" "$S2430_XR" situations --at nosuchtree
S2430_a="$(_s2430_err "$S2430_R/o3")"
_s2430_run "$S2430_R/o4" "$S2430_C" "$S2430_M" "$S2430_XR" situations --change nosuch..HEAD
S2430_a="$S2430_a / $(_s2430_err "$S2430_R/o4")"
S2430_TOVR="$S2430_BADT"
_s2430_run "$S2430_R/o5" "$S2430_C" "$S2430_M" "$S2430_XR" situations
S2430_TOVR=""
S2430_x="3|0|$S2430_TP it is absent or unreadable"
is "2430 order: an absent table is refused before the recorded tree, before the change's base, and before an unmakeable scratch directory" \
   "$S2430_a / $(_s2430_err "$S2430_R/o5")" "$S2430_x / $S2430_x / $S2430_x"
S2430_TOVR="$S2430_BADT"
_s2430_run "$S2430_R/o6" "$S2430_C" "$S2430_M" "$S2430_X1" situations --at nosuchtree
S2430_a="$(_s2430_err "$S2430_R/o6")"
_s2430_run "$S2430_R/o7" "$S2430_C" "$S2430_M" "$S2430_X1" situations --change nosuch..nosuch2
S2430_TOVR=""
is "2430 order: an unmakeable scratch directory is refused before the recorded tree and before the change's base" \
   "$S2430_a / $(_s2430_err "$S2430_R/o7")" "3|0|$S2430_SC / 3|0|$S2430_SC"
_s2430_run "$S2430_R/o8" "$S2430_C" "$S2430_M" "$S2430_X1" situations --change nosuch..nosuch2
S2430_a="$(_s2430_err "$S2430_R/o8")"
_s2430_run "$S2430_R/o9" "$S2430_C" "$S2430_M" "$S2430_X1" situations --change HEAD..nosuch2
is "2430 order: the base half is read before the head half" "$S2430_a / $(_s2430_err "$S2430_R/o9")" \
   "3|0|felix situations: base could not be read: nosuch is not a commit here / 3|0|felix situations: head could not be read: nosuch2 is not a commit here"

# ---- C6 to C10: --change, human and --tsv, over the six verdicts -----------------------------------------------------
_s2430_run "$S2430_R/ct" "$S2430_C" "$S2430_M" "$S2430_X1" situations --change HEAD~1..HEAD --tsv
is "2430 --change --tsv prints C8's lines exactly: class lines by verdict (owed, blinded, retired, standing, could-not-look, none), then id, then the residual" \
   "$S2430_BUILT|$(_s2430_ok "$S2430_R/ct")" "built|0||$(_s2430_cat "$S2430_E/c.tsv")"
_s2430_run "$S2430_R/ch" "$S2430_C" "$S2430_M" "$S2430_X1" situations --change HEAD~1..HEAD
is "2430 --change prints C9's human report exactly: header, owed, blinded, retired, standing, residual, the count line" \
   "$S2430_BUILT|$(_s2430_ok "$S2430_R/ch")" "built|0||$(_s2430_cat "$S2430_E/c.txt")"
S2430_a="$(LC_ALL=C awk -F'\t' '$1 != "residual" { printf "%s ", $3 }' "$S2430_R/ct.out")"
is "2430 (i) the --tsv class lines come in verdict order, owed in all three forms first" "$S2430_RC|$S2430_a" \
   "0|owed owed owed blinded retired standing could-not-look could-not-look none "
S2430_a="$(LC_ALL=C awk -F'\t' '$1 != "residual" && $3 == "owed" { printf "%s>%s ", $2, $4 }' "$S2430_R/ct.out" | tr ' ' '\n' \
  | LC_ALL=C sort | tr '\n' ' ')"
is "2430 owed carries all three base states: DORMANT, UNKNOWN (base could not look) and ACTIVE with a reading that differs" \
   "$S2430_RC|$S2430_a" "0|k_owed>DORMANT k_owed_unknown>UNKNOWN k_touched>ACTIVE "
S2430_a="$(LC_ALL=C awk 'p && /^    witness/ { print } /^  owed:/ { p = 1 } /^$/ { p = 0 }' "$S2430_R/ch.out")"
is "2430 the witness lines name the side where the class is DORMANT and the probe that read empty" "$S2430_RC|$S2430_a" \
   "0|    witness  base: p_own empty
    witness  head: p_ret empty"
_s2430_run "$S2430_R/ct2" "$S2430_C" "$S2430_M" "$S2430_X1" situations --tsv --change HEAD~1..HEAD
is "2430 --tsv before --change prints the same bytes" "$(_s2430_ok "$S2430_R/ct2")" "0||$(_s2430_cat "$S2430_R/ct.out")"

# ---- --at: the newest tree, an explicit one, and the base tree where the detector is not run --------------------------
_s2430_run "$S2430_R/at" "$S2430_C" "$S2430_M" "$S2430_X1" situations --tsv
is "2430 --tsv at the newest recorded tree: standing, could-not-look and none, base and base_grounds -, head the one state" \
   "$S2430_BUILT|$(_s2430_ok "$S2430_R/at")" "built|0||$(_s2430_cat "$S2430_E/h.tsv")"
_s2430_run "$S2430_R/ah" "$S2430_C" "$S2430_M" "$S2430_X1" situations
is "2430 the human report at the newest tree: the at header with the detector run, standing, residual, the count line" \
   "$S2430_BUILT|$(_s2430_ok "$S2430_R/ah")" "built|0||$(_s2430_cat "$S2430_E/h.txt")"
_s2430_run "$S2430_R/ah2" "$S2430_C" "$S2430_M" "$S2430_X1" situations --at "$S2430_HT"
S2430_a="$(_s2430_ok "$S2430_R/ah2")"
_s2430_run "$S2430_R/at2" "$S2430_C" "$S2430_M" "$S2430_X1" situations --tsv --at "$S2430_HT"
is "2430 --at <the newest tree> prints what no flag prints, human and --tsv" "$S2430_a // $(_s2430_ok "$S2430_R/at2")" \
   "0||$(_s2430_cat "$S2430_E/h.txt") // 0||$(_s2430_cat "$S2430_E/h.tsv")"
_s2430_run "$S2430_R/bt" "$S2430_C" "$S2430_M" "$S2430_X1" situations --at "$S2430_BT" --tsv
is "2430 --at <the base tree> --tsv: the recorded base reading, its blind reason from the fact log" \
   "$S2430_BUILT|$(_s2430_ok "$S2430_R/bt")" "built|0||$(_s2430_cat "$S2430_E/b.tsv")"
_s2430_run "$S2430_R/bh" "$S2430_C" "$S2430_M" "$S2430_X1" situations --at "$S2430_BT"
is "2430 --at <the base tree>: the header says the detector was not run, then standing, residual and the count line" \
   "$S2430_BUILT|$(_s2430_ok "$S2430_R/bh")" "built|0||$(_s2430_cat "$S2430_E/b.txt")"
S2430_a=""; S2430_i=0
while [ "$S2430_i" -lt 9 ]; do
  S2430_s="${S2430_K[$S2430_i]}"
  S2430_a="$S2430_a $(LC_ALL=C awk -F'\t' -v k="$S2430_s" '$2 == k { printf "%s", $1 }' "$S2430_R/at.out" "$S2430_R/bt.out" "$S2430_R/ct.out" | tr -d '\n')"
  S2430_i=$((S2430_i + 1))
done
S2430_x=""; S2430_i=0
while [ "$S2430_i" -lt 9 ]; do S2430_x="$S2430_x ${S2430_ID[$S2430_i]}${S2430_ID[$S2430_i]}${S2430_ID[$S2430_i]}"; S2430_i=$((S2430_i + 1)); done
is "2430 (i) each class's id is owed: and 12 hex digits of git hash-object over class, project and *, the same at either tree and in --change" \
   "$S2430_RC|$S2430_a" "0|$S2430_x"

# ---- (d): two runs in one checkout give identical bytes, network off, no key ------------------------------------------
S2430_a=""
for S2430_s in '--change HEAD~1..HEAD' '--change HEAD~1..HEAD --tsv' '--at '"$S2430_HT" '--tsv'; do
  # shellcheck disable=SC2086
  _s2430_run "$S2430_R/d1" "$S2430_C" "$S2430_M" "$S2430_X1" situations $S2430_s; S2430_x="$S2430_RC"
  # shellcheck disable=SC2086
  _s2430_run "$S2430_R/d2" "$S2430_C" "$S2430_M" "$S2430_X1" situations $S2430_s
  S2430_y=differ; cmp -s "$S2430_R/d1.out" "$S2430_R/d2.out" && S2430_y=same
  S2430_a="$S2430_a [$S2430_x $S2430_RC $S2430_y $(wc -c < "$S2430_R/d2.err" | tr -d ' ')]"
done
is "2430 (d) two runs give identical bytes in --change and --at, human and --tsv, each exit 0 with stderr empty" \
   "$S2430_a" " [0 0 same 0] [0 0 same 0] [0 0 same 0] [0 0 same 0]"
_locale_bytes_vars
if [ -z "${LCB_U8:-}" ]; then
  skip "2430 C8: --tsv is the same bytes under LC_ALL=C and under an en_US UTF-8 LANG" "$LCB_NONE"
else
  _s2430_run "$S2430_R/l1" "$S2430_C" "$S2430_M" env LC_ALL=C "$S2430_X1" situations --change HEAD~1..HEAD --tsv
  S2430_x="$S2430_RC"
  _s2430_run "$S2430_R/l2" "$S2430_C" "$S2430_M" env -u LC_ALL LANG="$LCB_U8" "$S2430_X1" situations --change HEAD~1..HEAD --tsv
  is "2430 C8: --tsv is the same bytes under LC_ALL=C and under an en_US UTF-8 LANG with LC_ALL unset" \
     "$S2430_x|$(_s2430_ok "$S2430_R/l2")" "0|0||$(_s2430_cat "$S2430_E/c.tsv")"
fi

# ---- falsifier 2, the clean-machine form: two fresh clones, two fresh memory roots, every verdict ---------------------
for S2430_s in k1 k2; do
  ( _fx_cd "$S2430_D" && _s2430_g 1790000000 clone -q "$S2430_C" "$S2430_s" ) >/dev/null 2>&1 || _s2430_nb "clone $S2430_s"
  mkdir -p "$S2430_D/mem-$S2430_s/out1" && cp "$S2430_M/out1/facts.log" "$S2430_D/mem-$S2430_s/out1/facts.log" \
    || _s2430_nb "memory root $S2430_s"
done
S2430_a=""
for S2430_s in '--change HEAD~1..HEAD' '--change HEAD~1..HEAD --tsv' '' '--tsv'; do
  # shellcheck disable=SC2086
  _s2430_run "$S2430_R/f1" "$S2430_D/k1" "$S2430_D/mem-k1" "$S2430_X1" situations $S2430_s; S2430_x="$S2430_RC"
  # shellcheck disable=SC2086
  _s2430_run "$S2430_R/f2" "$S2430_D/k2" "$S2430_D/mem-k2" "$S2430_X1" situations $S2430_s
  S2430_y=differ; cmp -s "$S2430_R/f1.out" "$S2430_R/f2.out" && S2430_y=same
  S2430_a="$S2430_a [$S2430_x $S2430_RC $S2430_y]"
  [ "$S2430_s" != '--change HEAD~1..HEAD --tsv' ] || cp "$S2430_R/f1.out" "$S2430_R/f-ct.out"
  [ "$S2430_s" != '' ] || cp "$S2430_R/f2.out" "$S2430_R/f-ah.out"
done
is "2430 falsifier 2: two fresh clones with fresh memory roots holding the same facts.log print identical bytes in --change and --at, human and --tsv" \
   "$S2430_BUILT|$S2430_a" "built| [0 0 same] [0 0 same] [0 0 same] [0 0 same]"
S2430_a="$(LC_ALL=C awk -F'\t' '$1 != "residual" { print $3 }' "$S2430_R/f-ct.out" | LC_ALL=C sort -u | tr '\n' ' ')"
is "2430 falsifier 2: every verdict included: the clones' --change --tsv holds owed, blinded, retired, standing, could-not-look and none, and is C8's text exactly" \
   "$S2430_a|$(_s2430_cat "$S2430_R/f-ct.out")" \
   "blinded could-not-look none owed retired standing |$(_s2430_cat "$S2430_E/c.tsv")"
is "2430 falsifier 2: a clone's --at is the report at its own tree, the detector run" \
   "$(_s2430_cat "$S2430_R/f-ah.out")" "$(_s2430_cat "$S2430_E/h.txt")"

# ---- (c): the shipped seed in the bash-harness fixture ------------------------------------------------------------------
S2430_SEED="$FROOT/harness/templates/situations.tsv"
S2430_SN="$(LC_ALL=C awk '!/^[[:space:]]*(#|$)/ { n++ } END { print n + 0 }' "$S2430_SEED")"
_s2430_owes() { LC_ALL=C awk -F'\t' -v c="$1" '$1 == c { print $3; exit }' "$S2430_SEED"; }
S2430_RI="$(_s2430_id ci_actions_pinned bash1)"; S2430_PI="$(_s2430_id paid_ingress bash1)"
S2430_RO="$(_s2430_owes ci_actions_pinned)"; S2430_PO="$(_s2430_owes paid_ingress)"
[ -n "$S2430_RO" ] && [ -n "$S2430_PO" ] || _s2430_nb "the seed's R1 and R4 rows"
# OUT -> "ok" when OUT's count line has C9's shape, N the seed's rows, A+D+U = N, U >= 1 and A >= $2; else the line.
_s2430_count() {
  LC_ALL=C awk -v n="$S2430_SN" -v amin="$2" '
    /^examined / { l = $0 }
    END {
      s = l
      if (sub(/^examined /, "", s) == 0) { print "no count line"; exit }
      split(s, f, ", ")
      e = f[1]; a = f[2]; d = f[3]; u = f[4]
      ok = (e == n) && sub(/^active /, "", a) && sub(/^dormant /, "", d) && sub(/^could not look /, "", u)
      ok = ok && a ~ /^[0-9]+$/ && d ~ /^[0-9]+$/ && u ~ /^[0-9]+$/ && a + d + u == n && u >= 1 && a >= amin
      if (ok) print "ok"; else print l
    }' "$1"
}
# NAME OUT NEEDLE -> the run OUT exited 0 with stderr empty, and NEEDLE stands in OUT.out as whole lines.
_s2430_lines() {
  local f=missing
  case $'\n'"$(cat "$2.out" 2>/dev/null)"$'\n' in *$'\n'"$3"$'\n'*) f=found ;; esac
  is "$1" "$S2430_RC|$(cat "$2.err" 2>/dev/null)|$f" "0||found"
}
_s2430_run "$S2430_R/sa" "$S2430_CB" "$S2430_MB" "$FELIX" situations --tsv
_s2430_lines "2430 (c) --at in the bash harness: the R4 class ci_actions_pinned is standing, ACTIVE, grounded by its workflow probe" \
  "$S2430_R/sa" "$(_s2430_tsvl "$S2430_RI" ci_actions_pinned standing - ACTIVE - 'ci_workflows found (ci)' "$S2430_RO")"
_s2430_lines "2430 (c) --at in the bash harness: paid_ingress is could-not-look, UNKNOWN, with neither api nor llm detected" \
  "$S2430_R/sa" "$(_s2430_tsvl "$S2430_PI" paid_ingress could-not-look - UNKNOWN - 'api not detected, llm not detected' "$S2430_PO")"
_s2430_lines "2430 (c) --at in the bash harness: the residual has a could-not-look line for paid_ingress whose why names cap:api" \
  "$S2430_R/sa" "$(_s2430_tsvl residual could-not-look paid_ingress 'at: cap:api: no probe grounds api and the detector does not name it')"
_s2430_lines "2430 (c) --at in the bash harness: the residual names scripts, which a probe grounds and no class uses, as no-row" \
  "$S2430_R/sa" "$(_s2430_tsvl residual no-row scripts 'named by probe shell_scripts')"
_s2430_lines "2430 (c) --at in the bash harness: the residual names probe:local_listener=found as unbound" \
  "$S2430_R/sa" "$(_s2430_tsvl residual unbound probe:local_listener=found 'no row of probes.tsv grounds local_listener')"
_s2430_run "$S2430_R/sh" "$S2430_CB" "$S2430_MB" "$FELIX" situations
_s2430_lines "2430 (c) the human --at report shows ci_actions_pinned as the one standing row, with its grounds and readings" \
  "$S2430_R/sh" "standing
  $S2430_RI  ci_actions_pinned  ACTIVE
    grounds  ci_workflows found (ci)
    readings  ci_workflows=found/1
    owes  $S2430_RO

residual"
_s2430_lines "2430 (c) the human --at report's residual names paid_ingress's cap:api" \
  "$S2430_R/sh" "  could-not-look  paid_ingress  at: cap:api: no probe grounds api and the detector does not name it"
S2430_x="$(LC_ALL=C awk '/^residual$/ { getline; print; exit }' "$S2430_R/sh.out")"
case "$S2430_x" in '  none'*|'') S2430_x="empty: [$S2430_x]" ;; *) S2430_x=lines ;; esac
is "2430 (c) the bash harness's report is never an empty residual with exit 0, and its count line has U at least 1" \
   "$S2430_RC|$S2430_x|$(_s2430_count "$S2430_R/sh.out" 1)" "0|lines|ok"
_s2430_run "$S2430_R/sc" "$S2430_CB" "$S2430_MB" "$FELIX" situations --change main..drop --tsv
_s2430_lines "2430 (c) --change over the commit that removes the workflow reads ci_actions_pinned retired, ACTIVE to DORMANT, its probe empty at head" \
  "$S2430_R/sc" "$(_s2430_tsvl "$S2430_RI" ci_actions_pinned retired ACTIVE DORMANT 'ci_workflows found (ci)' 'ci_workflows empty (ci)' "$S2430_RO")"
_s2430_lines "2430 (c) --change: paid_ingress could not look on either side, never DORMANT" \
  "$S2430_R/sc" "$(_s2430_tsvl "$S2430_PI" paid_ingress could-not-look UNKNOWN UNKNOWN 'api not detected, llm not detected' 'api not detected, llm not detected' "$S2430_PO")"
_s2430_run "$S2430_R/sch" "$S2430_CB" "$S2430_MB" "$FELIX" situations --change main..drop
_s2430_lines "2430 (c) the human --change report: owed and blinded say none, retired holds ci_actions_pinned alone with a witness head: line, standing says none" \
  "$S2430_R/sch" "owed
  none

blinded
  none

retired
  $S2430_RI  ci_actions_pinned  ACTIVE -> DORMANT
    grounds  base: ci_workflows found (ci); head: ci_workflows empty (ci)
    readings  base: ci_workflows=found/1; head: ci_workflows=empty/0
    witness  head: ci_workflows empty
    owes  $S2430_RO

standing
  none

residual"
_s2430_lines "2430 (c) the human --change residual names paid_ingress's cap:api and cap:llm at base and at head, in byte order" \
  "$S2430_R/sch" "  could-not-look  paid_ingress  base: cap:api: no probe grounds api and the detector does not name it
  could-not-look  paid_ingress  base: cap:llm: no probe grounds llm and the detector does not name it
  could-not-look  paid_ingress  head: cap:api: no probe grounds api and the detector does not name it
  could-not-look  paid_ingress  head: cap:llm: no probe grounds llm and the detector does not name it"
is "2430 (c) the human --change report's count line has U at least 1" "$S2430_RC|$(_s2430_count "$S2430_R/sch.out" 0)" "0|ok"
S2430_x="$(LC_ALL=C awk 'NR == 1' "$S2430_R/sch.out")"
is "2430 (c) the human --change report's first line names the project bash1" "$S2430_RC|$S2430_x" "0|situations for bash1"

# ---- what stayed: the network and TMPDIR -----------------------------------------------------------------------------
is "2430 no gh, curl, wget, ssh, nc or claude was started by any felix situations run, and the last run exited 0" \
   "$S2430_RC|$(cat "$S2430_NET")" "0|"
is "2430 the last run's TMPDIR is empty afterwards" "$S2430_RC|$(ls -A "$S2430_R/sch.t" 2>&1)" "0|"
