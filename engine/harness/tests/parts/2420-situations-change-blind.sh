printf '\n%s\n' 'situations: the change (blind)'
# Blind, written on 2026-10-31 from docs/2026-10-29-capability-lane-first-slices-design.md (sections 3, 4, 7, 10 and 11)
# and the slice 1 plan's Contracts (C1 to C16) and Review Focus alone, before lib/situations*.sh existed, without reading
# lib/, hooks/, bin/ or felix. felix situations is run as a black box; felix probes is run only to record facts and tree
# ids, as C13 allows. C16's row for this part: section 7.3 scratch, 7.5, C3.3, C3.4 for --change, C5 (every row of its
# table; the first kind of "differs", for one probe: case and one cap: case), the default range, C2's --change exits and
# their order, the current probes.tsv on both sides, tracked content only, and the scratch tree id equal to the recorded
# one for a clean checkout.
#
# The fixture (C13): a home H holding project chg, a substituted table in a copy of the engine, and one repository C whose
# main has c0, c1 (the base) and c2 (after the branch), and whose branch feat has f1 and f2 (the head). Every probe of
# chg's probes.tsv reads files a commit holds: m/<pred> lists members (found), w/<pred> makes an empty probe blind,
# u/<pred> makes the witness exit 3 (unknown), and none of them reads empty. Fifteen classes, one per verdict path:
# owed four ways (DORMANT, UNKNOWN, and ACTIVE with a probe: and a cap: term whose grounding (state, count) changed, and a
# probe: term over two probes one of which changed state), cap:ci owed through the detector alone, standing for a probe:
# and a cap: term, blinded from ACTIVE and from DORMANT, could-not-look, retired, and none three ways. One probe grounds
# cfree, which no class uses, for a no-row line.
# Readings where the Contracts leave room:
# - "Tracked content only": the live checkout, at f2, holds an untracked m/p_ctr (found, live), a staged m/p_cno and an
#   unstaged extra line in tracked m/p_cst when felix situations runs; neither side reads any of them.
# - "The current probes.tsv on both sides": facts.log under the memory root holds runs of both trees made with an older
#   probes.tsv under which p_cst reads empty; the scratch reading must ignore them and run the current rows.
# - "The scratch tree id equal to the recorded one": felix probes, run with the current probes.tsv and a memory root of
#   its own, in C while clean at f2 and in a clean clone detached at c1, records the ids the header must print.
# - The main ref's rules (C3.3) are read from the base commit the header names under the default range, with the tree id
#   masked, in a repository whose refs name four different merge bases.
# - "The scratch checkout could not be made" is not asserted: a missing blob, the one fault a fixture can make, leaves
#   git checkout exiting 0 on git 2.56 (measured 2026-10-31), so no fixture forces that line portably.
# - The mtime check sleeps one second after the fixture's last write, then touches the marker.
# C17 (2026-11-05), from C17 alone: --change ^HEAD..HEAD exits 3 (C17.7); the main..HEAD and reversed-range runs compare
# their exit status, and the default range's byte-for-byte --tsv comparison sees its trailing newlines (C17.10).
S2420_D=""; mkdir -p "$TMP/s2420" && S2420_D="$(cd -P "$TMP/s2420" && pwd -P)"
S2420_P=chg
S2420_BLIND='the witness says this surface exists and the probe enumerated none of it'
S2420_UNK3='the witness exited 3, which is neither yes nor no, so absent and blind cannot be told apart'
S2420_HOW='scratch checkout, tracked content only, current probes.tsv'
S2420_N=0; S2420_T=""; S2420_RC=""; S2420_SHA=""; S2420_TID=""

# T ARGS... -> git where the caller stands (after _fx_cd, in a subshell), with no global or system configuration, the
# identity s2420, author and committer time T (epoch seconds, UTC), no hooks, no signing, no automatic gc.
_s2420_g() {
  local t="$1"
  shift
  GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_AUTHOR_NAME=s2420 GIT_AUTHOR_EMAIL=s2420@example.invalid \
    GIT_COMMITTER_NAME=s2420 GIT_COMMITTER_EMAIL=s2420@example.invalid \
    GIT_AUTHOR_DATE="$t +0000" GIT_COMMITTER_DATE="$t +0000" \
    git -c core.autocrlf=false -c commit.gpgsign=false -c core.hooksPath=/dev/null -c gc.auto=0 \
      -c maintenance.auto=false "$@"
}
# DIR T ARGS... -> _s2420_g T ARGS... in DIR, quiet; the status is git's.
_s2420_gx() { local d="$1" t="$2"; shift 2; ( _fx_cd "$d" || exit 1; _s2420_g "$t" "$@" ) >/dev/null 2>&1; }
# DIR -> a repository on main in DIR (made when missing), with .felix naming chg, nothing committed.
_s2420_init() {
  mkdir -p "$1" || return 1
  ( _fx_cd "$1" || exit 1; _s2420_g 1793000000 init -q -b main ) >/dev/null 2>&1 || return 1
  printf '%s\n' "$S2420_P" > "$1/.felix"
}
# DIR T MSG -> every change in DIR committed at T; S2420_SHA names the commit (empty when it failed).
_s2420_commit() {
  S2420_SHA="$( _fx_cd "$1" || exit 1
    _s2420_g "$2" add -A >/dev/null 2>&1 || exit 1
    _s2420_g "$2" commit -q --allow-empty -m "$3" >/dev/null 2>&1 || exit 1
    _s2420_g "$2" rev-parse --verify -q HEAD )" || S2420_SHA=""
  [ -n "$S2420_SHA" ]
}
# DIR PRED STATE [N] -> the files PRED's probe reads in DIR make it read STATE: found with N members (1), empty, blind or
# unknown.
_s2420_set() {
  local d="$1" p="$2" s="$3" n="${4:-1}" i=0
  mkdir -p "$d/m" "$d/w" "$d/u" || return 1
  rm -f "$d/m/$p" "$d/w/$p" "$d/u/$p"
  case "$s" in
    found) while [ "$i" -lt "$n" ]; do i=$((i + 1)); printf '%s member %s\n' "$p" "$i" >> "$d/m/$p"; done ;;
    blind) printf 'surface\n' > "$d/w/$p" ;;
    unknown) printf 'undecidable\n' > "$d/u/$p" ;;
  esac
  return 0
}
# PRED CAP -> the probes.tsv row of PRED, grounding CAP, on the files _s2420_set writes.
_s2420_row() {
  printf '%s\t%s\t-\tcat m/%s 2>/dev/null; exit 0\ttest ! -f u/%s || exit 3; test -f w/%s\n' "$1" "$2" "$1" "$1" "$1"
}
# -> S2420_T, a fresh empty directory for one run's TMPDIR.
_s2420_tmp() { S2420_N=$((S2420_N + 1)); S2420_T="$S2420_D/t/$S2420_N"; mkdir -p "$S2420_T"; }
# OUT ENGINE DIR TMPDIR ARGS... -> ENGINE situations ARGS run from DIR as C13 runs it: the network stubs first on PATH, no
# key or token, HOME an empty directory, FELIX_HOME S2420_H, FELIX_MEMORY S2420_M. OUT.out, OUT.err, status S2420_RC.
_s2420_run() {
  local o="$1" e="$2" d="$3" t="$4"
  shift 4
  ( cd "$d" || exit 125
    exec env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GH_TOKEN -u GITHUB_TOKEN -u FELIX_HOME_DIR -u CLAUDE_CODE_SESSION_ID \
      HOME="$S2420_D/user" PATH="$S2420_D/bin:$PATH" FELIX_HOME="$S2420_H" FELIX_MEMORY="$S2420_M" TMPDIR="$t" \
      "$e" situations "$@" ) > "$o.out" 2> "$o.err" < /dev/null
  S2420_RC=$?
}
# DIR MEM -> felix probes in DIR, recording under MEM; S2420_TID is the tree of the last row of MEM's facts.log for chg.
_s2420_probes() {
  _s2420_tmp
  ( cd "$1" || exit 125
    exec env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GH_TOKEN -u GITHUB_TOKEN -u FELIX_HOME_DIR -u CLAUDE_CODE_SESSION_ID \
      HOME="$S2420_D/user" PATH="$S2420_D/bin:$PATH" FELIX_HOME="$S2420_H" FELIX_MEMORY="$2" TMPDIR="$S2420_T" \
      "$S2420_X" probes ) > /dev/null 2>&1 < /dev/null
  S2420_TID="$(LC_ALL=C awk -F'\t' 'NF >= 8 { t = $2 } END { print t }' "$2/$S2420_P/facts.log" 2>/dev/null)"
}
# DIR -> every path under DIR, then every file's checksum, each sorted as bytes.
_s2420_tree() {
  find "$1" -print 2>&1 | LC_ALL=C sort
  find "$1" -type f -exec cksum {} + 2>&1 | LC_ALL=C sort
}
# DIR -> the refs, the worktrees and their HEADs, the config file's bytes, the index and the status of the checkout DIR,
# read with no optional lock.
_s2420_gstate() {
  ( export GIT_OPTIONAL_LOCKS=0 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    git -C "$1" for-each-ref; git -C "$1" worktree list --porcelain; cksum < "$1/.git/config"
    git -C "$1" ls-files -s; git -C "$1" status --porcelain ) 2>&1
}
# CLASS -> its id, as C6 computes it.
_s2420_id() { printf 'owed:%s' "$(printf '%s\t%s\t%s' "$1" "$S2420_P" '*' | git hash-object --stdin | cut -c1-12)"; }
# FILE -> the file's text, with a newline before and after, for a whole-line has. $( ) drops the newline after, so each
# caller appends $'\n' to the substitution, as each whole-line needle does.
_s2420_nl() { printf '\n%s\n' "$(cat "$1" 2>/dev/null)"; }
# FILE LINE -> LINE when it is a whole line of FILE, else FILE's text.
_s2420_whole() {
  local n=$'\n'
  case "$n$(cat "$1" 2>/dev/null)$n" in *"$n$2$n"*) printf '%s' "$2" ;; *) cat "$1" 2>/dev/null ;; esac
}
# FILE N -> the report's line N, its tree id replaced by T.
_s2420_side() { LC_ALL=C awk -v n="$2" 'NR == n' "$1" 2>/dev/null | sed 's/  tree [^ ]*  /  tree T  /'; }

# ---- the fixture -----------------------------------------------------------------------------------------------------
S2420_BUILT="not built"
S2420_H="$S2420_D/home"; S2420_M="$S2420_D/memory"; S2420_M2="$S2420_D/memory-ids"; S2420_C="$S2420_D/c"
S2420_X="$S2420_D/x/harness/felix"; S2420_XBAD="$S2420_D/xbad/harness/felix"
mkdir -p "$S2420_D/bin" "$S2420_D/user" "$S2420_D/plain" "$S2420_D/t" "$S2420_D/o" "$S2420_H/projects/$S2420_P" \
  "$S2420_M" "$S2420_M2" "$S2420_D/x" "$S2420_D/xbad"
: > "$S2420_D/net.log"
for _s2420_c in gh curl wget ssh nc claude; do
  printf '#!/bin/sh\nprintf '"'"'%%s %%s\\n'"'"' %s "$*" >> '"'"'%s'"'"'\nexit 1\n' "$_s2420_c" "$S2420_D/net.log" \
    > "$S2420_D/bin/$_s2420_c"
  chmod +x "$S2420_D/bin/$_s2420_c"
done
printf '{"name":"%s","remote_match":"example.invalid/%s","gate":"true"}\n' "$S2420_P" "$S2420_P" \
  > "$S2420_H/projects/$S2420_P/project.json"
printf '# %s\n' "$S2420_P" > "$S2420_H/projects/$S2420_P/CLAUDE.md"
S2420_PREDS='p_cnew:cnew p_cpd:cpd p_ccd:ccd p_cbu:cbu p_cst:cst p_ctw1:ctw p_ctw2:ctw p_cbl:cbl p_cb2:cb2 p_ccn:ccn p_cre:cre p_cno:cno p_cn2:cn2 p_ctr:ctr p_cfree:cfree'
: > "$S2420_D/probes.current"
for _s2420_c in $S2420_PREDS; do _s2420_row "${_s2420_c%%:*}" "${_s2420_c#*:}" >> "$S2420_D/probes.current"; done
# The older probes.tsv the recorded facts were taken with: p_cst reads empty under it at every tree.
printf 'p_cst\tcst\t-\ttrue\tfalse\n' > "$S2420_D/probes.stale"
cp "$S2420_D/probes.current" "$S2420_H/projects/$S2420_P/probes.tsv"
# The substituted table: one class per verdict path, each owing its own words.
S2420_CLASSES='k_new:probe:cnew=found k_pdiff:probe:cpd=found k_cdiff:cap:ccd k_bunk:probe:cbu=found k_stand:probe:cst=found k_cstand:cap:cst k_two:probe:ctw=found k_blind:probe:cbl=found k_blind2:probe:cb2=found k_cnl:probe:ccn=found k_ret:probe:cre=found k_none:probe:cno=found k_none2:probe:cn2=found k_track:probe:ctr=found k_ci:cap:ci'
cp -R "$FROOT/harness" "$S2420_D/x/harness" && cp -R "$FROOT/harness" "$S2420_D/xbad/harness" && {
  printf '# class\tapplies\towes\tclass_by_maturity\tsource\n'
  for _s2420_c in $S2420_CLASSES; do
    printf '%s\t%s\tthe %s bound, kept\tprototype=INFO,internal=INFO,public-beta=ADVISORY,production=TASK_BLOCKING\tcite:0123456789ab\n' \
      "${_s2420_c%%:*}" "${_s2420_c#*:}" "${_s2420_c%%:*}"
  done
} > "$S2420_D/x/harness/templates/situations.tsv" \
  && printf '# a table that holds no row\n\n' > "$S2420_D/xbad/harness/templates/situations.tsv" \
  && S2420_BUILT="engine"
S2420_TABBAD="$S2420_D/xbad/harness/templates/situations.tsv"

# C: c0 (the marker), c1 (the base), feat's f1 and f2 (the head), then main's c2 after the branch.
S2420_C1=""; S2420_C2=""; S2420_F2=""
if [ "$S2420_BUILT" = engine ] && _s2420_init "$S2420_C" && _s2420_commit "$S2420_C" 1793000000 c0; then
  _s2420_set "$S2420_C" p_cnew empty; _s2420_set "$S2420_C" p_cpd found 1; _s2420_set "$S2420_C" p_ccd found 1
  _s2420_set "$S2420_C" p_cbu blind; _s2420_set "$S2420_C" p_cst found 1; _s2420_set "$S2420_C" p_ctw1 found 1
  _s2420_set "$S2420_C" p_ctw2 empty; _s2420_set "$S2420_C" p_cbl found 1; _s2420_set "$S2420_C" p_cb2 empty
  _s2420_set "$S2420_C" p_ccn blind; _s2420_set "$S2420_C" p_cre found 1; _s2420_set "$S2420_C" p_cno empty
  _s2420_set "$S2420_C" p_cn2 unknown; _s2420_set "$S2420_C" p_ctr empty; _s2420_set "$S2420_C" p_cfree found 1
  if _s2420_commit "$S2420_C" 1793000100 c1; then
    S2420_C1="$S2420_SHA"
    _s2420_gx "$S2420_C" 1793000150 checkout -q -b feat
    _s2420_set "$S2420_C" p_cnew found 1; _s2420_set "$S2420_C" p_cpd found 2; _s2420_set "$S2420_C" p_ccd found 3
    _s2420_set "$S2420_C" p_cbu found 1; _s2420_set "$S2420_C" p_ctw2 found 1
    if _s2420_commit "$S2420_C" 1793000200 f1; then
      _s2420_set "$S2420_C" p_cbl blind; _s2420_set "$S2420_C" p_cb2 unknown; _s2420_set "$S2420_C" p_cre empty
      _s2420_set "$S2420_C" p_cn2 empty
      mkdir -p "$S2420_C/.github/workflows"; printf 'on: push\n' > "$S2420_C/.github/workflows/w.yml"
      _s2420_commit "$S2420_C" 1793000300 f2 && S2420_F2="$S2420_SHA"
    fi
    if [ -n "$S2420_F2" ] && _s2420_gx "$S2420_C" 1793000350 checkout -q main; then
      _s2420_set "$S2420_C" p_cno found 1
      _s2420_commit "$S2420_C" 1793000400 c2 && S2420_C2="$S2420_SHA"
      _s2420_gx "$S2420_C" 1793000450 checkout -q feat || S2420_C2=""
    fi
  fi
fi
# The tree ids felix probes records for clean checkouts of f2 (C itself) and c1 (a clone), with the current probes.tsv
# and a memory root of their own; then the stale facts, with the older probes.tsv, under the memory root the runs use.
S2420_TIDH=""; S2420_TIDB=""; S2420_CB="$S2420_D/cb"
if [ -n "$S2420_C2" ] && [ -z "$(git -C "$S2420_C" status --porcelain 2>&1)" ]; then
  _s2420_probes "$S2420_C" "$S2420_M2"; S2420_TIDH="$S2420_TID"
  if ( _fx_cd "$S2420_D" || exit 1; _s2420_g 1793000500 clone -q "$S2420_C" cb ) >/dev/null 2>&1 \
     && _s2420_gx "$S2420_CB" 1793000500 checkout -q --detach "$S2420_C1"; then
    _s2420_probes "$S2420_CB" "$S2420_M2"; S2420_TIDB="$S2420_TID"
  fi
  cp "$S2420_D/probes.stale" "$S2420_H/projects/$S2420_P/probes.tsv"
  _s2420_probes "$S2420_CB" "$S2420_M"; _s2420_probes "$S2420_C" "$S2420_M"
  cp "$S2420_D/probes.current" "$S2420_H/projects/$S2420_P/probes.tsv"
  [ -n "$S2420_TIDH" ] && [ -n "$S2420_TIDB" ] && [ "$S2420_TIDH" != "$S2420_TIDB" ] && [ -s "$S2420_M/$S2420_P/facts.log" ] \
    && S2420_BUILT=built
fi
# The live checkout's own edits, which neither side reads: an untracked found surface, a staged one, an unstaged line.
if [ "$S2420_BUILT" = built ]; then
  _s2420_set "$S2420_C" p_ctr found 2
  _s2420_set "$S2420_C" p_cno found 1; _s2420_gx "$S2420_C" 1793000600 add -- m/p_cno || S2420_BUILT="not built: staging"
  printf 'p_cst member live\n' >> "$S2420_C/m/p_cst"
fi

# ---- what the default range reads ------------------------------------------------------------------------------------
# class|verdict|base|head|base grounds|head grounds|base readings|head readings|base witness|head witness
cat > "$S2420_D/expect.rows" <<'S2420ROWS'
k_new|owed|DORMANT|ACTIVE|p_cnew empty (cnew)|p_cnew found (cnew)|p_cnew=empty/0|p_cnew=found/1|p_cnew empty|
k_pdiff|owed|ACTIVE|ACTIVE|p_cpd found (cpd)|p_cpd found (cpd)|p_cpd=found/1|p_cpd=found/2||
k_cdiff|owed|ACTIVE|ACTIVE|p_ccd found (ccd)|p_ccd found (ccd)|p_ccd=found/1|p_ccd=found/3||
k_bunk|owed|UNKNOWN|ACTIVE|p_cbu blind (cbu)|p_cbu found (cbu)|p_cbu=blind/0|p_cbu=found/1||
k_stand|standing|ACTIVE|ACTIVE|p_cst found (cst)|p_cst found (cst)|p_cst=found/1|p_cst=found/1||
k_cstand|standing|ACTIVE|ACTIVE|p_cst found (cst)|p_cst found (cst)|p_cst=found/1|p_cst=found/1||
k_two|owed|ACTIVE|ACTIVE|p_ctw1 found (ctw), p_ctw2 empty (ctw)|p_ctw1 found (ctw), p_ctw2 found (ctw)|p_ctw1=found/1 p_ctw2=empty/0|p_ctw1=found/1 p_ctw2=found/1||
k_blind|blinded|ACTIVE|UNKNOWN|p_cbl found (cbl)|p_cbl blind (cbl)|p_cbl=found/1|p_cbl=blind/0||
k_blind2|blinded|DORMANT|UNKNOWN|p_cb2 empty (cb2)|p_cb2 unknown (cb2)|p_cb2=empty/0|p_cb2=unknown/0|p_cb2 empty|
k_cnl|could-not-look|UNKNOWN|UNKNOWN|p_ccn blind (ccn)|p_ccn blind (ccn)|p_ccn=blind/0|p_ccn=blind/0||
k_ret|retired|ACTIVE|DORMANT|p_cre found (cre)|p_cre empty (cre)|p_cre=found/1|p_cre=empty/0||p_cre empty
k_none|none|DORMANT|DORMANT|p_cno empty (cno)|p_cno empty (cno)|p_cno=empty/0|p_cno=empty/0|p_cno empty|p_cno empty
k_none2|none|UNKNOWN|DORMANT|p_cn2 unknown (cn2)|p_cn2 empty (cn2)|p_cn2=unknown/0|p_cn2=empty/0||p_cn2 empty
k_track|none|DORMANT|DORMANT|p_ctr empty (ctr)|p_ctr empty (ctr)|p_ctr=empty/0|p_ctr=empty/0|p_ctr empty|p_ctr empty
k_ci|owed|UNKNOWN|ACTIVE|ci not detected|ci detected|-|-||
S2420ROWS
# kind|name|why, the residual's lines before they are sorted.
{ printf 'could-not-look|k_blind|head: probe:cbl=found: p_cbl read blind: %s\n' "$S2420_BLIND"
  printf 'could-not-look|k_blind2|head: probe:cb2=found: p_cb2 read unknown: %s\n' "$S2420_UNK3"
  printf 'could-not-look|k_bunk|base: probe:cbu=found: p_cbu read blind: %s\n' "$S2420_BLIND"
  printf 'could-not-look|k_ci|base: cap:ci: no probe grounds ci and the detector does not name it\n'
  printf 'could-not-look|k_cnl|base: probe:ccn=found: p_ccn read blind: %s\n' "$S2420_BLIND"
  printf 'could-not-look|k_cnl|head: probe:ccn=found: p_ccn read blind: %s\n' "$S2420_BLIND"
  printf 'could-not-look|k_none2|base: probe:cn2=found: p_cn2 read unknown: %s\n' "$S2420_UNK3"
  printf 'no-row|cfree|named by probe p_cfree\n'; } > "$S2420_D/expect.residual"
S2420_TAB="$(printf '\t')"
# The --tsv lines: classes by token order, then id as bytes; then the residual, sorted as whole lines.
: > "$S2420_D/expect.keyed"
while IFS='|' read -r _s2420_k _s2420_v _s2420_b _s2420_h _s2420_bg _s2420_hg _s2420_br _s2420_hr _s2420_wb _s2420_wh; do
  case "$_s2420_v" in owed) _s2420_r=1 ;; blinded) _s2420_r=2 ;; retired) _s2420_r=3 ;; standing) _s2420_r=4 ;;
    could-not-look) _s2420_r=5 ;; *) _s2420_r=6 ;; esac
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tthe %s bound, kept\n' "$_s2420_r" "$(_s2420_id "$_s2420_k")" "$_s2420_k" \
    "$_s2420_v" "$_s2420_b" "$_s2420_h" "$_s2420_bg" "$_s2420_hg" "$_s2420_k" >> "$S2420_D/expect.keyed"
done < "$S2420_D/expect.rows"
LC_ALL=C sort -t"$S2420_TAB" -k1,1 -k2,2 "$S2420_D/expect.keyed" | cut -f2- > "$S2420_D/expect.tsv"
LC_ALL=C awk -F'|' '{ printf "residual\t%s\t%s\t%s\n", $1, $2, $3 }' "$S2420_D/expect.residual" | LC_ALL=C sort -u \
  > "$S2420_D/expect.res"
cat "$S2420_D/expect.res" >> "$S2420_D/expect.tsv"
# The human report (C9).
{ printf 'situations for %s\n' "$S2420_P"
  printf '  base  %s  tree %s  %s\n' "$S2420_C1" "$S2420_TIDB" "$S2420_HOW"
  printf '  head  %s  tree %s  %s\n' "$S2420_F2" "$S2420_TIDH" "$S2420_HOW"
  for _s2420_s in owed blinded retired standing; do
    printf '\n%s\n' "$_s2420_s"; _s2420_any=""
    while IFS='|' read -r _s2420_k _s2420_v _s2420_b _s2420_h _s2420_bg _s2420_hg _s2420_br _s2420_hr _s2420_wb _s2420_wh; do
      [ "$_s2420_v" = "$_s2420_s" ] || continue
      _s2420_any=1
      printf '  %s  %s  %s -> %s\n' "$(_s2420_id "$_s2420_k")" "$_s2420_k" "$_s2420_b" "$_s2420_h"
      printf '    grounds  base: %s; head: %s\n' "$_s2420_bg" "$_s2420_hg"
      printf '    readings  base: %s; head: %s\n' "$_s2420_br" "$_s2420_hr"
      [ "$_s2420_b" != DORMANT ] || [ -z "$_s2420_wb" ] || printf '    witness  base: %s\n' "$_s2420_wb"
      [ "$_s2420_h" != DORMANT ] || [ -z "$_s2420_wh" ] || printf '    witness  head: %s\n' "$_s2420_wh"
      printf '    owes  the %s bound, kept\n' "$_s2420_k"
    done < <(LC_ALL=C sort -t'|' -k1,1 "$S2420_D/expect.rows")
    [ -n "$_s2420_any" ] || printf '  none\n'
  done
  printf '\nresidual\n'
  LC_ALL=C awk -F'\t' '{ printf "  %s  %s  %s\n", $2, $3, $4 }' "$S2420_D/expect.res"
  printf '\nexamined 15, active 8, dormant 4, could not look 3\n'; } > "$S2420_D/expect.human"

# ---- the default range: one run, read whole and by line, and what it leaves as it was (C3.4) -------------------------
S2420_GS0="$(_s2420_gstate "$S2420_C")"; S2420_MS0="$(_s2420_tree "$S2420_M")"; S2420_HS0="$(_s2420_tree "$S2420_H")"
sleep 1; touch "$S2420_D/marker"
_s2420_tmp; S2420_TD="$S2420_T"
_s2420_run "$S2420_D/o/def" "$S2420_X" "$S2420_C" "$S2420_TD" --change; S2420_RCD="$S2420_RC"
S2420_NEW="$(find "$S2420_C" -newer "$S2420_D/marker" -print 2>&1)"
S2420_GS1="$(_s2420_gstate "$S2420_C")"; S2420_MS1="$(_s2420_tree "$S2420_M")"; S2420_HS1="$(_s2420_tree "$S2420_H")"
is "2420 the default range reads c1 (the merge base of main and HEAD) to f2: the human report, header to count line, byte for byte" \
   "$S2420_BUILT|$S2420_RCD|$(cat "$S2420_D/o/def.out")" "built|0|$(cat "$S2420_D/expect.human")"
is "2420 the default range prints nothing on stderr and exits 0" "$S2420_RCD|$(cat "$S2420_D/o/def.err")" "0|"
is "2420 the head line names f2 and the tree id felix probes recorded for a clean checkout of f2" \
   "$S2420_RCD|$(LC_ALL=C awk 'NR == 3' "$S2420_D/o/def.out")" "0|  head  $S2420_F2  tree $S2420_TIDH  $S2420_HOW"
is "2420 the base line names c1 and the tree id felix probes recorded for a clean checkout of c1" \
   "$S2420_RCD|$(LC_ALL=C awk 'NR == 2' "$S2420_D/o/def.out")" "0|  base  $S2420_C1  tree $S2420_TIDB  $S2420_HOW"
is "2420 after the default range nothing under the checkout, its .git included, is newer than the marker" \
   "$S2420_RCD|$S2420_NEW" "0|"
is "2420 after the default range the refs, the worktree list and HEADs, the config bytes, ls-files -s and status --porcelain are as they were" \
   "$S2420_RCD|$S2420_GS1" "0|$S2420_GS0"
is "2420 after the default range nothing under the memory root changed, facts.log included" "$S2420_RCD|$S2420_MS1" "0|$S2420_MS0"
is "2420 after the default range nothing under the Felix home changed" "$S2420_RCD|$S2420_HS1" "0|$S2420_HS0"
is "2420 after the default range TMPDIR is empty again" "$S2420_RCD|$(ls -A "$S2420_TD" 2>&1)" "0|"

_s2420_tmp; _s2420_run "$S2420_D/o/deft" "$S2420_X" "$S2420_C" "$S2420_T" --change --tsv; S2420_RCT="$S2420_RC"
is "2420 the default range with --tsv: every class line in token order then id, then the residual, byte for byte" \
   "$S2420_BUILT|$S2420_RCT|$(cat "$S2420_D/o/deft.out"; printf '|end')" "built|0|$(cat "$S2420_D/expect.tsv"; printf '|end')"
is "2420 the default range with --tsv prints nothing on stderr and leaves TMPDIR empty" \
   "$S2420_RCT|$(cat "$S2420_D/o/deft.err")|$(ls -A "$S2420_T" 2>&1)" "0||"
S2420_HAY="$(_s2420_nl "$S2420_D/o/deft.out")"$'\n'
# CLASS WHAT -> the class's --tsv line is in the default range's output, whole.
_s2420_line() {
  local l
  l="$(LC_ALL=C awk -F'\t' -v k="$1" '$2 == k' "$S2420_D/expect.tsv")"
  has "2420 $1: $2" "$S2420_RCT|$S2420_HAY" "$(printf '\n%s\n' "$l")"$'\n'
}
_s2420_line k_new "head ACTIVE, base DORMANT reads owed"
_s2420_line k_pdiff "ACTIVE on both sides, a probe: term whose grounding count changed, reads owed (the first kind of differs)"
_s2420_line k_cdiff "ACTIVE on both sides, a cap: term decided at step 1 whose grounding count changed, reads owed"
_s2420_line k_two "ACTIVE on both sides, one of two probes grounding the term changed state, reads owed"
_s2420_line k_bunk "head ACTIVE, base UNKNOWN reads owed, with base UNKNOWN"
_s2420_line k_ci "a capability only the detector decides, named at head and not at base, reads owed with base UNKNOWN"
_s2420_line k_stand "ACTIVE on both sides with equal readings reads standing (probe: term)"
_s2420_line k_cstand "ACTIVE on both sides with equal readings reads standing (cap: term)"
_s2420_line k_blind "head UNKNOWN, base ACTIVE reads blinded"
_s2420_line k_blind2 "head UNKNOWN, base DORMANT reads blinded"
_s2420_line k_cnl "UNKNOWN on both sides reads could-not-look"
_s2420_line k_ret "head DORMANT, base ACTIVE reads retired"
_s2420_line k_none "DORMANT on both sides reads none"
_s2420_line k_none2 "head DORMANT, base UNKNOWN reads none"
_s2420_line k_track "a surface found only in an untracked file of the live checkout is read on neither side: none"
has "2420 the current probes.tsv is read on both sides: p_cst reads found at base, though the facts recorded at both trees read it empty" \
   "$S2420_RCT|$S2420_HAY" "$(printf '\n%s\n' "$(LC_ALL=C awk -F'\t' '$2 == "k_stand"' "$S2420_D/expect.tsv")")"$'\n'
has "2420 every probe of the current probes.tsv runs on a side read: p_cfree, which grounds a capability no class uses, gives a no-row line" \
   "$S2420_RCT|$S2420_HAY" "$(printf '\nresidual\tno-row\tcfree\tnamed by probe p_cfree\n')"$'\n'

# ---- the scratch directory is gone before the report's first byte (C3.3, Removal) ------------------------------------
_s2420_tmp; S2420_TG="$S2420_T"
( cd "$S2420_C" || exit 125
  exec env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GH_TOKEN -u GITHUB_TOKEN -u FELIX_HOME_DIR -u CLAUDE_CODE_SESSION_ID \
    HOME="$S2420_D/user" PATH="$S2420_D/bin:$PATH" FELIX_HOME="$S2420_H" FELIX_MEMORY="$S2420_M" TMPDIR="$S2420_TG" \
    "$S2420_X" situations --change ) 2> "$S2420_D/o/gone.err" < /dev/null \
  | { IFS= read -r _s2420_l; ls -A "$S2420_TG" > "$S2420_D/o/gone.seen" 2>&1; printf '%s\n' "$_s2420_l" > "$S2420_D/o/gone.first"
      cat > /dev/null; }
S2420_RCG="${PIPESTATUS[0]}"
is "2420 when the report's first line can be read, TMPDIR holds no scratch directory any more" \
   "$S2420_RCG|$(cat "$S2420_D/o/gone.first")|$(cat "$S2420_D/o/gone.seen")" "0|situations for $S2420_P|"

# ---- explicit ranges: each half resolved in the live repository (C3.3) ------------------------------------------------
_s2420_tmp; _s2420_run "$S2420_D/o/exp" "$S2420_X" "$S2420_C" "$S2420_T" --change "$S2420_C1..$S2420_F2"
is "2420 --change c1..f2, given as full commit ids, prints the default range's report byte for byte" \
   "$S2420_RC|$(cat "$S2420_D/o/exp.out")|$(cat "$S2420_D/o/exp.err")" "0|$(cat "$S2420_D/expect.human")|"
_s2420_tmp; _s2420_run "$S2420_D/o/rel" "$S2420_X" "$S2420_C" "$S2420_T" --change 'HEAD~2..HEAD' --tsv
is "2420 --change HEAD~2..HEAD --tsv prints the default range's --tsv byte for byte" \
   "$S2420_RC|$(cat "$S2420_D/o/rel.out")|$(cat "$S2420_D/o/rel.err")" "0|$(cat "$S2420_D/expect.tsv")|"
_s2420_tmp; _s2420_run "$S2420_D/o/main" "$S2420_X" "$S2420_C" "$S2420_T" --change 'main..HEAD'
is "2420 --change main..HEAD takes main's tip c2 as the base, not the merge base" \
   "$S2420_RC|$(_s2420_side "$S2420_D/o/main.out" 2)" "0|  base  $S2420_C2  tree T  $S2420_HOW"
_s2420_tmp; _s2420_run "$S2420_D/o/maint" "$S2420_X" "$S2420_C" "$S2420_T" --change 'main..HEAD' --tsv
S2420_L="$(printf '%s\tk_none\tretired\tACTIVE\tDORMANT\tp_cno found (cno)\tp_cno empty (cno)\tthe k_none bound, kept' "$(_s2420_id k_none)")"
is "2420 --change main..HEAD reads k_none retired: c2 holds its surface and f2 does not" \
   "$S2420_RC|$(_s2420_whole "$S2420_D/o/maint.out" "$S2420_L")" "0|$S2420_L"
_s2420_tmp; _s2420_run "$S2420_D/o/rev" "$S2420_X" "$S2420_C" "$S2420_T" --change "$S2420_F2..$S2420_C1" --tsv
S2420_L="$(printf '%s\tk_ret\towed\tDORMANT\tACTIVE\tp_cre empty (cre)\tp_cre found (cre)\tthe k_ret bound, kept' "$(_s2420_id k_ret)")"
is "2420 the reversed range f2..c1 reads k_ret owed, base DORMANT" \
   "$S2420_RC|$(_s2420_whole "$S2420_D/o/rev.out" "$S2420_L")" "0|$S2420_L"
is "2420 the network stubs were never started" "$S2420_RCD|$(cat "$S2420_D/net.log")" "0|"

# ---- C2's --change exits and their order -------------------------------------------------------------------------------
# OUT WANT -> status|stdout bytes|yes when stderr's first line begins with WANT
_s2420_pre() {
  local f
  f="$(LC_ALL=C awk 'NR == 1' "$1.err" 2>/dev/null)"
  case "$f" in "$2"*) f=yes ;; *) f="no: $f" ;; esac
  printf '%s|%s|%s' "$S2420_RC" "$(wc -c < "$1.out" | tr -d ' ')" "$f"
}
S2420_USE='felix: usage: felix situations'
# LABEL DIR ARGS... -> a usage error: exit 2, nothing on stdout, stderr's first line the usage line's opening.
_s2420_usage() {
  local l="$1" d="$2"
  shift 2
  _s2420_tmp; _s2420_run "$S2420_D/o/use" "$S2420_X" "$d" "$S2420_T" "$@"
  is "2420 $l is a usage error: exit 2, stdout empty, stderr begins $S2420_USE" "$(_s2420_pre "$S2420_D/o/use" "$S2420_USE")" "2|0|yes"
}
_s2420_usage "--change main (no ..)" "$S2420_C" --change main
_s2420_usage "--change HEAD...main (three dots)" "$S2420_C" --change 'HEAD...main'
_s2420_usage "--change ..HEAD (an empty base half)" "$S2420_C" --change '..HEAD'
_s2420_usage "--change HEAD.. (an empty head half)" "$S2420_C" --change 'HEAD..'
_s2420_usage "--change HEAD~1..HEAD..main (a head half holding ..)" "$S2420_C" --change 'HEAD~1..HEAD..main'
_s2420_usage "--change -x (an argument that begins with - is no range)" "$S2420_C" --change -x
_s2420_usage "--change given twice" "$S2420_C" --change --change
_s2420_usage "--change main, where no project governs (usage before the project)" "$S2420_D/plain" --change main
S2420_NOT="$S2420_D/no-such-tmp"
S2420_TABLINE="felix situations: the situation table could not be read: $S2420_TABBAD: it holds no row"
S2420_SCRLINE="felix situations: the scratch directory could not be made: mktemp -d failed under $S2420_NOT"
_s2420_tmp; _s2420_run "$S2420_D/o/np" "$S2420_XBAD" "$S2420_D/plain" "$S2420_T" --change
is "2420 where no project governs, a table that cannot be read is not reached: exit 2, stdout empty, stderr begins felix: no project governs" \
   "$(_s2420_pre "$S2420_D/o/np" 'felix: no project governs')" "2|0|yes"
_s2420_tmp; _s2420_run "$S2420_D/o/np2" "$S2420_XBAD" "$S2420_D/plain" "$S2420_T" --change main
is "2420 where no project governs and the table cannot be read, --change main is still a usage error first" \
   "$(_s2420_pre "$S2420_D/o/np2" "$S2420_USE")" "2|0|yes"
# LABEL ENGINE DIR TMPDIR WANT AFTER ARGS... -> exit 3, stdout empty, stderr the one line WANT, and TMPDIR afterwards AFTER:
# empty (the empty string), or absent for the directory that never existed. S2420_XQ is the fixture's build state, built.
_s2420_x3() {
  local l="$1" e="$2" d="$3" t="$4" w="$5" after="$6" a
  shift 6
  _s2420_run "$S2420_D/o/x3" "$e" "$d" "$t" "$@"
  if [ -d "$t" ]; then a="$(ls -A "$t" 2>&1)"; elif [ -e "$t" ]; then a=other; else a=absent; fi
  is "2420 $l: exit 3, stdout empty, stderr the one line, TMPDIR as it was" \
     "$S2420_XQ|$S2420_RC|$(wc -c < "$S2420_D/o/x3.out" | tr -d ' ')|$(cat "$S2420_D/o/x3.err")|$a" "built|3|0|$w|$after"
}
S2420_XQ="$S2420_BUILT"
_s2420_x3 "a table with no row, a TMPDIR that cannot hold a scratch directory and a base that is no commit: the table is named" \
  "$S2420_XBAD" "$S2420_C" "$S2420_NOT" "$S2420_TABLINE" absent --change 'nope..HEAD'
_s2420_x3 "a TMPDIR that cannot hold a scratch directory and a base that is no commit: the scratch directory is named" \
  "$S2420_X" "$S2420_C" "$S2420_NOT" "$S2420_SCRLINE" absent --change 'nope..HEAD'
_s2420_tmp
_s2420_x3 "--change nope..nope2: the base half is named first" "$S2420_X" "$S2420_C" "$S2420_T" \
  "felix situations: base could not be read: nope is not a commit here" "" --change 'nope..nope2'
_s2420_tmp
_s2420_x3 "--change HEAD..nope: the head half is named" "$S2420_X" "$S2420_C" "$S2420_T" \
  "felix situations: head could not be read: nope is not a commit here" "" --change 'HEAD..nope'
_s2420_tmp
_s2420_x3 "--change HEAD^{tree}..HEAD: a tree is not a commit" "$S2420_X" "$S2420_C" "$S2420_T" \
  "felix situations: base could not be read: HEAD^{tree} is not a commit here" "" --change 'HEAD^{tree}..HEAD'
_s2420_tmp
_s2420_x3 "--change ^HEAD..HEAD: a half that resolves to something other than a full commit id is not a commit (C17.7)" \
  "$S2420_X" "$S2420_C" "$S2420_T" "felix situations: base could not be read: ^HEAD is not a commit here" "" --change '^HEAD..HEAD'

# An unborn HEAD (its .felix untracked), a repository with no main ref, and one whose main shares no history with HEAD.
S2420_U="$S2420_D/unborn"; S2420_NM="$S2420_D/nomain"; S2420_NB="$S2420_D/nobase"; S2420_XB="not built"
if _s2420_init "$S2420_U" && _s2420_init "$S2420_NM" && _s2420_commit "$S2420_NM" 1793001000 nm0 \
   && _s2420_gx "$S2420_NM" 1793001000 branch -m main feat \
   && _s2420_init "$S2420_NB" && _s2420_commit "$S2420_NB" 1793001100 nb0 \
   && _s2420_gx "$S2420_NB" 1793001150 checkout -q --orphan lone && _s2420_commit "$S2420_NB" 1793001200 nb1; then
  S2420_XB=built
fi
S2420_XQ="$S2420_XB"
_s2420_x3 "an unborn HEAD with a TMPDIR that cannot hold a scratch directory: the scratch directory is named before HEAD" \
  "$S2420_X" "$S2420_U" "$S2420_NOT" "$S2420_SCRLINE" absent --change
_s2420_tmp
_s2420_x3 "--change with no range at an unborn HEAD, where no main ref exists either: HEAD is named first" "$S2420_X" \
  "$S2420_U" "$S2420_T" "felix situations: head could not be read: HEAD is not a commit here" "" --change
_s2420_tmp
_s2420_x3 "--change HEAD..HEAD at an unborn HEAD: the base half is named" "$S2420_X" "$S2420_U" "$S2420_T" \
  "felix situations: base could not be read: HEAD is not a commit here" "" --change 'HEAD..HEAD'
_s2420_tmp
_s2420_x3 "--change with no range where neither origin ref nor refs/heads/main names a commit" "$S2420_X" "$S2420_NM" \
  "$S2420_T" "felix situations: the change could not be read: no main ref here: neither refs/remotes/origin/HEAD, refs/remotes/origin/main nor refs/heads/main names a commit" \
  "" --change
_s2420_tmp; _s2420_run "$S2420_D/o/nmr" "$S2420_X" "$S2420_NM" "$S2420_T" --change 'HEAD..HEAD' --tsv
is "2420 an explicit range needs no main ref: --change HEAD..HEAD there exits 0 with stderr empty and TMPDIR empty" \
   "$S2420_RC|$(cat "$S2420_D/o/nmr.err")|$(ls -A "$S2420_T" 2>&1)|$([ -s "$S2420_D/o/nmr.out" ] && echo report)" "0|||report"
_s2420_tmp
_s2420_x3 "--change with no range where refs/heads/main and HEAD share no history" "$S2420_X" "$S2420_NB" "$S2420_T" \
  "felix situations: the change could not be read: refs/heads/main and HEAD share no merge base" "" --change
_s2420_gx "$S2420_NB" 1793001300 update-ref refs/remotes/origin/trunk refs/heads/main \
  && _s2420_gx "$S2420_NB" 1793001300 symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/trunk
_s2420_tmp
_s2420_x3 "--change with no range where origin/HEAD points at origin/trunk, which shares no history with HEAD: the target is named" \
  "$S2420_X" "$S2420_NB" "$S2420_T" \
  "felix situations: the change could not be read: refs/remotes/origin/trunk and HEAD share no merge base" "" --change

# ---- the main ref (C3.3): r0 - r1 - r2 - r3 on feat, main at r0, origin/main at r1, origin/trunk and side at r2 --------
S2420_MR="$S2420_D/mainref"; S2420_R0=""; S2420_R1=""; S2420_R2=""; S2420_R3=""
if _s2420_init "$S2420_MR" && _s2420_commit "$S2420_MR" 1793002000 r0; then
  S2420_R0="$S2420_SHA"
  _s2420_gx "$S2420_MR" 1793002050 checkout -q -b feat
  _s2420_set "$S2420_MR" p_cpd found 1; _s2420_commit "$S2420_MR" 1793002100 r1 && S2420_R1="$S2420_SHA"
  _s2420_set "$S2420_MR" p_cpd found 2; _s2420_commit "$S2420_MR" 1793002200 r2 && S2420_R2="$S2420_SHA"
  _s2420_set "$S2420_MR" p_cpd found 3; _s2420_commit "$S2420_MR" 1793002300 r3 && S2420_R3="$S2420_SHA"
  _s2420_gx "$S2420_MR" 1793002400 update-ref refs/remotes/origin/main "$S2420_R1"
  _s2420_gx "$S2420_MR" 1793002400 update-ref refs/remotes/origin/trunk "$S2420_R2"
  _s2420_gx "$S2420_MR" 1793002400 update-ref refs/heads/side "$S2420_R2"
  _s2420_gx "$S2420_MR" 1793002400 symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/trunk
fi
# LABEL WANT -> the default range's base line in the main-ref repository names WANT.
_s2420_mref() {
  _s2420_tmp; _s2420_run "$S2420_D/o/mr" "$S2420_X" "$S2420_MR" "$S2420_T" --change
  is "2420 the main ref: $1" "$S2420_RC|$(_s2420_side "$S2420_D/o/mr.out" 2)|$(_s2420_side "$S2420_D/o/mr.out" 3)" \
     "0|  base  $2  tree T  $S2420_HOW|  head  $S2420_R3  tree T  $S2420_HOW"
}
_s2420_mref "origin/HEAD, a symbolic ref to origin/trunk, wins over origin/main and refs/heads/main: the base is r2" "$S2420_R2"
_s2420_gx "$S2420_MR" 1793002500 symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/gone
_s2420_mref "origin/HEAD pointing at an origin ref that names no commit is passed over for origin/main: the base is r1" "$S2420_R1"
_s2420_gx "$S2420_MR" 1793002500 symbolic-ref refs/remotes/origin/HEAD refs/heads/side
_s2420_mref "origin/HEAD pointing outside refs/remotes/origin/ is passed over for origin/main: the base is r1" "$S2420_R1"
_s2420_gx "$S2420_MR" 1793002500 update-ref --no-deref refs/remotes/origin/HEAD "$S2420_R2"
_s2420_mref "an origin/HEAD that is no symbolic ref is passed over for origin/main: the base is r1" "$S2420_R1"
_s2420_gx "$S2420_MR" 1793002600 update-ref --no-deref -d refs/remotes/origin/HEAD \
  && _s2420_gx "$S2420_MR" 1793002600 update-ref -d refs/remotes/origin/main
_s2420_mref "with neither origin ref, refs/heads/main is the main ref: the base is r0" "$S2420_R0"
