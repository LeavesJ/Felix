printf '\n%s\n' 'situations: the seed siblings (blind)'
# Blind, written on 2026-10-31 from docs/2026-10-29-capability-lane-first-slices-design.md (sections 3, 4, 7, 10 and 11)
# and the slice 1 plan's Contracts (C1 to C16) and Review Focus alone, before lib/situations*.sh existed, without reading
# lib/, hooks/, bin/ or felix. felix situations is run as a black box on the shipped seed. C16's row for this part:
# section 7.2's siblings rule, falsifier 6, as C12's "Siblings" paragraph says it.
#
# For every row of the shipped table, read at run time from the templates/ directory beside $FELIX, so a new row is
# covered, the part builds a project with an invented name (sib1, sib2, ... in table order) and one repository. Nothing
# here names a class of the seed: each fixture is derived from its row's applies.
# - Each capability a probe: or cap: term names gets one probe row, q1, q2, ... in first-use order, grounding exactly that
#   capability: it lists s/q<i> (found while that tracked file is there) and its witness is test -f w/q<i>, a file no
#   commit holds, so with s/q<i> gone the probe prints nothing and the witness exits 1: empty. A probe:<c>=empty term's
#   capability keeps no file on either side; a probe:<c>=not-applicable term's probe row has the when false.
# - An env:maturity>=<v> term is made true by project.json's "maturity":"production", the same on both sides.
# - The commit <with> holds every file; for each capability a probe:<c>=found or cap:<c> term needs found, a commit
#   <without> on a branch of its own removes only that capability's s/q<i>. No manifest grounds anything, so the
#   detector never decides a term the part reads.
# - --change <with>..<without> must read the class retired, its block in the retired section holding a
#   "    witness  head: q<i> empty" line; --change <without>..<with> must read it owed, with the base witness. The
#   whole block is compared (C9), and for the first surface of each row the --tsv line too (C8).
# - A ledger asserts that every class in the shipped table, at least six, was read both ways on every surface.
# Readings where the Contracts leave room:
# - "One repository with two commits" is read per surface: one repository per row, whose <with> commit is shared by one
#   <without> commit per removable capability, so a row with two removable terms is read both ways on each.
# - A term in a form C4 cannot make true (a probe: term on blind or unknown, another env axis, any other form) leaves
#   the row unbuildable; the part says so by name and the ledger counts the row as not read.
S2460_D=""; mkdir -p "$TMP/s2460" && S2460_D="$(cd -P "$TMP/s2460" && pwd -P)"
S2460_TABLE="$(cd -P "$(dirname "$FELIX")" && pwd -P)/templates/situations.tsv"
S2460_H="$S2460_D/home"; S2460_M="$S2460_D/memory"
S2460_N=0; S2460_T=""; S2460_RC=""; S2460_SHA=""
mkdir -p "$S2460_D/bin" "$S2460_D/user" "$S2460_D/t" "$S2460_D/o" "$S2460_H/projects" "$S2460_M"
: > "$S2460_D/net.log"
for _s2460_c in gh curl wget ssh nc claude; do
  printf '#!/bin/sh\nprintf '"'"'%%s %%s\\n'"'"' %s "$*" >> '"'"'%s'"'"'\nexit 1\n' "$_s2460_c" "$S2460_D/net.log" \
    > "$S2460_D/bin/$_s2460_c"
  chmod +x "$S2460_D/bin/$_s2460_c"
done

# T ARGS... -> git where the caller stands (after _fx_cd, in a subshell), with no global or system configuration, the
# identity s2460, author and committer time T (epoch seconds, UTC), no hooks, no signing, no automatic gc.
_s2460_g() {
  local t="$1"
  shift
  GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_AUTHOR_NAME=s2460 GIT_AUTHOR_EMAIL=s2460@example.invalid \
    GIT_COMMITTER_NAME=s2460 GIT_COMMITTER_EMAIL=s2460@example.invalid \
    GIT_AUTHOR_DATE="$t +0000" GIT_COMMITTER_DATE="$t +0000" \
    git -c core.autocrlf=false -c commit.gpgsign=false -c core.hooksPath=/dev/null -c gc.auto=0 \
      -c maintenance.auto=false "$@"
}
# DIR T ARGS... -> _s2460_g T ARGS... in DIR, quiet; the status is git's.
_s2460_gx() { local d="$1" t="$2"; shift 2; ( _fx_cd "$d" || exit 1; _s2460_g "$t" "$@" ) >/dev/null 2>&1; }
# DIR T MSG -> every change in DIR committed at T; S2460_SHA names the commit (empty when it failed).
_s2460_commit() {
  S2460_SHA="$( _fx_cd "$1" || exit 1
    _s2460_g "$2" add -A >/dev/null 2>&1 || exit 1
    _s2460_g "$2" commit -q --allow-empty -m "$3" >/dev/null 2>&1 || exit 1
    _s2460_g "$2" rev-parse --verify -q HEAD )" || S2460_SHA=""
  [ -n "$S2460_SHA" ]
}
# -> S2460_T, a fresh empty directory for one run's TMPDIR.
_s2460_tmp() { S2460_N=$((S2460_N + 1)); S2460_T="$S2460_D/t/$S2460_N"; mkdir -p "$S2460_T"; }
# OUT DIR ARGS... -> $FELIX situations ARGS run from DIR as C13 runs it: the network stubs first on PATH, no key or token,
# HOME an empty directory, FELIX_HOME S2460_H, FELIX_MEMORY S2460_M, TMPDIR fresh. OUT.out, OUT.err, status S2460_RC.
_s2460_run() {
  local o="$1" d="$2"
  shift 2
  _s2460_tmp
  ( cd "$d" || exit 125
    exec env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GH_TOKEN -u GITHUB_TOKEN -u FELIX_HOME_DIR -u CLAUDE_CODE_SESSION_ID \
      HOME="$S2460_D/user" PATH="$S2460_D/bin:$PATH" FELIX_HOME="$S2460_H" FELIX_MEMORY="$S2460_M" TMPDIR="$S2460_T" \
      "$FELIX" situations "$@" ) > "$o.out" 2> "$o.err" < /dev/null
  S2460_RC=$?
}
# CLASS PROJECT -> its id, as C6 computes it.
_s2460_id() { printf 'owed:%s' "$(printf '%s\t%s\t%s' "$1" "$2" '*' | git hash-object --stdin | cut -c1-12)"; }
# FILE SECTION ROWLINE -> the block of the human report's SECTION that ROWLINE opens: that line and the four-space lines
# after it.
_s2460_block() {
  LC_ALL=C awk -v s="$2" -v r="$3" '
    !insec && $0 == s { insec = 1; next }
    insec && $0 == "" { insec = 0; take = 0; next }
    insec && $0 == r { take = 1; print; next }
    take && substr($0, 1, 4) == "    " { print; next }
    { take = 0 }' "$1" 2>/dev/null
}

# ---- the shipped table, read now ---------------------------------------------------------------------------------------
# One row a line, its five cells as written; a line that matches ^[[:space:]]*(#|$) is no row (C2, Reading the table).
LC_ALL=C awk '!/^[[:space:]]*(#|$)/' "$S2460_TABLE" > "$S2460_D/rows" 2>/dev/null
S2460_ROWS=0; S2460_MISSING=""; S2460_NL=$'\n'
S2460_TABC="$(printf '\t')"

# ---- one project, one repository and both readings per row --------------------------------------------------------------
# CLASS APPLIES OWES N -> builds sib<N> and its repository, reads every removable surface both ways, and adds CLASS to
# S2460_MISSING unless all of them read as C12 says.
_s2460_row() {
  local k="$1" ap="$2" ow="$3" n="$4" p="sib$4" t c s i j why="" caps="" req="" mat="" gw="" gwo="" rw="" rwo="" seen=""
  local r d id with sha out blk want lw ok=1 first=1 env="" pi st cnt item cap w
  # The terms: each capability's required state, in first-use order, as "cap=state" words in req.
  for t in $ap; do
    case "$t" in
      probe:*=*)
        c="${t#probe:}"; s="${c#*=}"; c="${c%%=*}"
        case "$s" in found|empty|not-applicable) ;; *) why="${why:+$why; }$t is on a state no commit can make true" ;; esac
        [ -n "$c" ] || why="${why:+$why; }$t names no capability" ;;
      cap:*) c="${t#cap:}"; s=found; [ -n "$c" ] || why="${why:+$why; }$t names no capability" ;;
      env:maturity\>=prototype|env:maturity\>=internal|env:maturity\>=public-beta|env:maturity\>=production)
        mat=production; continue ;;
      *) why="${why:+$why; }$t is not a term this part can make true"; continue ;;
    esac
    case " $req " in
      *" $c=$s "*) ;;
      *" $c="*) why="${why:+$why; }$c is needed in two states" ;;
      *) req="$req $c=$s"; caps="$caps $c" ;;
    esac
  done
  [ -n "$req" ] || why="${why:+$why; }no probe: or cap: term"
  r="$S2460_D/r$n"; d="$S2460_H/projects/$p"
  mkdir -p "$d" "$r/s" || why="${why:+$why; }the directories could not be made"
  if [ -n "$why" ]; then
    bad "2460 $k: the siblings fixture is built from the row's applies" "$why"
    S2460_MISSING="$S2460_MISSING $k"; return 0
  fi
  if [ -n "$mat" ]; then env=',"maturity":"production"'; fi
  printf '{"name":"%s","remote_match":"example.invalid/%s","gate":"true"%s}\n' "$p" "$p" "$env" > "$d/project.json"
  printf '# %s\n' "$p" > "$d/CLAUDE.md"
  : > "$d/probes.tsv"
  i=0
  for c in $caps; do
    i=$((i + 1))
    case " $req " in *" $c=not-applicable "*) w=false ;; *) w=- ;; esac
    printf 'q%s\t%s\t%s\tcat s/q%s 2>/dev/null; exit 0\ttest -f w/q%s\n' "$i" "$c" "$w" "$i" "$i" >> "$d/probes.tsv"
    case " $req " in *" $c=found "*) printf 'q%s member\n' "$i" > "$r/s/q$i" ;; esac
  done
  printf '%s\n' "$p" > "$r/.felix"
  if ! ( _fx_cd "$r" || exit 1; _s2460_g 1793100000 init -q -b main ) >/dev/null 2>&1 \
     || ! _s2460_commit "$r" $((1793100000 + n * 1000)) with; then
    bad "2460 $k: the siblings fixture is built from the row's applies" "the repository or its with commit could not be made"
    S2460_MISSING="$S2460_MISSING $k"; return 0
  fi
  with="$S2460_SHA"; id="$(_s2460_id "$k" "$p")"
  # Each removable surface: a capability some probe:<c>=found or cap:<c> term needs found.
  i=0
  for cap in $caps; do
    i=$((i + 1))
    case " $req " in *" $cap=found "*) ;; *) continue ;; esac
    sha=""
    if _s2460_gx "$r" $((1793100000 + n * 1000 + i)) checkout -q -b "without-q$i" "$with" && rm -f "$r/s/q$i" \
       && _s2460_commit "$r" $((1793100000 + n * 1000 + i)) "without q$i"; then sha="$S2460_SHA"; fi
    _s2460_gx "$r" $((1793100000 + n * 1000 + i)) checkout -q main
    # The grounds and readings with the surface (gw, rw) and without it (gwo, rwo), term by term in applies order.
    gw=""; gwo=""; rw=""; rwo=""; seen=" "
    for t in $ap; do
      case "$t" in
        probe:*=*) c="${t#probe:}"; c="${c%%=*}" ;;
        cap:*) c="${t#cap:}" ;;
        *) gw="${gw:+$gw, }maturity production"; gwo="${gwo:+$gwo, }maturity production"; continue ;;
      esac
      pi=0; for j in $caps; do pi=$((pi + 1)); [ "$j" = "$c" ] && break; done
      case " $req " in *" $c=found "*) st=found ;; *" $c=empty "*) st=empty ;; *) st=not-applicable ;; esac
      item="q$pi $st ($c)"; gw="${gw:+$gw, }$item"
      if [ "$c" = "$cap" ]; then gwo="${gwo:+$gwo, }q$pi empty ($c)"; else gwo="${gwo:+$gwo, }$item"; fi
      case "$seen" in *" q$pi "*) continue ;; esac
      seen="$seen q$pi "
      cnt=0; [ "$st" = found ] && cnt=1
      rw="${rw:+$rw }q$pi=$st/$cnt"
      if [ "$c" = "$cap" ]; then rwo="${rwo:+$rwo }q$pi=empty/0"; else rwo="${rwo:+$rwo }q$pi=$st/$cnt"; fi
    done
    # with..without: retired, the head witness on the removed surface.
    _s2460_run "$S2460_D/o/ret" "$r" --change "$with..$sha"
    blk="$(_s2460_block "$S2460_D/o/ret.out" retired "  $id  $k  ACTIVE -> DORMANT")"
    want="  $id  $k  ACTIVE -> DORMANT$S2460_NL    grounds  base: $gw; head: $gwo$S2460_NL    readings  base: $rw; head: $rwo"
    want="$want$S2460_NL    witness  head: q$i empty$S2460_NL    owes  $ow"
    lw="${sha:+built}|$S2460_RC|$blk"
    is "2460 $k ($p, $cap removed): --change <with>..<without> reads it retired, with a witness head: q$i empty line" \
       "$lw" "built|0|$want"
    [ "$lw" = "built|0|$want" ] || ok=""
    # without..with: owed, the base witness on the removed surface.
    _s2460_run "$S2460_D/o/owed" "$r" --change "$sha..$with"
    blk="$(_s2460_block "$S2460_D/o/owed.out" owed "  $id  $k  DORMANT -> ACTIVE")"
    want="  $id  $k  DORMANT -> ACTIVE$S2460_NL    grounds  base: $gwo; head: $gw$S2460_NL    readings  base: $rwo; head: $rw"
    want="$want$S2460_NL    witness  base: q$i empty$S2460_NL    owes  $ow"
    lw="${sha:+built}|$S2460_RC|$blk"
    is "2460 $k ($p, $cap removed): --change <without>..<with> reads it owed, with a witness base: q$i empty line" \
       "$lw" "built|0|$want"
    [ "$lw" = "built|0|$want" ] || ok=""
    if [ -n "$first" ]; then
      first=""
      _s2460_run "$S2460_D/o/rett" "$r" --change "$with..$sha" --tsv
      out="$(LC_ALL=C awk -F'\t' -v k="$k" '$2 == k' "$S2460_D/o/rett.out" 2>/dev/null)"
      want="$id$S2460_TABC$k${S2460_TABC}retired${S2460_TABC}ACTIVE${S2460_TABC}DORMANT$S2460_TABC$gw$S2460_TABC$gwo$S2460_TABC$ow"
      is "2460 $k ($p, $cap removed): the --tsv line of <with>..<without> reads retired, ACTIVE to DORMANT, its owes as written" \
         "${sha:+built}|$S2460_RC|$out" "built|0|$want"
      [ "${sha:+built}|$S2460_RC|$out" = "built|0|$want" ] || ok=""
      _s2460_run "$S2460_D/o/owedt" "$r" --change "$sha..$with" --tsv
      out="$(LC_ALL=C awk -F'\t' -v k="$k" '$2 == k' "$S2460_D/o/owedt.out" 2>/dev/null)"
      want="$id$S2460_TABC$k${S2460_TABC}owed${S2460_TABC}DORMANT${S2460_TABC}ACTIVE$S2460_TABC$gwo$S2460_TABC$gw$S2460_TABC$ow"
      is "2460 $k ($p, $cap removed): the --tsv line of <without>..<with> reads owed, DORMANT to ACTIVE, its owes as written" \
         "${sha:+built}|$S2460_RC|$out" "built|0|$want"
      [ "${sha:+built}|$S2460_RC|$out" = "built|0|$want" ] || ok=""
    fi
  done
  [ -z "$first" ] || ok=""
  [ -n "$ok" ] || S2460_MISSING="$S2460_MISSING $k"
  return 0
}

while IFS="$S2460_TABC" read -r _s2460_k _s2460_a _s2460_o _s2460_x _s2460_s || [ -n "$_s2460_k" ]; do
  S2460_ROWS=$((S2460_ROWS + 1))
  _s2460_row "$_s2460_k" "$_s2460_a" "$_s2460_o" "$S2460_ROWS" < /dev/null
done < "$S2460_D/rows"

# ---- the ledger ---------------------------------------------------------------------------------------------------------
if [ "$S2460_ROWS" -ge 6 ]; then S2460_SIX="$S2460_ROWS rows, at least six"; else S2460_SIX="only $S2460_ROWS rows"; fi
is "2460 the ledger: every class in the shipped table, at least six, was read retired and owed on every surface its applies stands on" \
   "$S2460_SIX|not read both ways:${S2460_MISSING:- none}" "$S2460_ROWS rows, at least six|not read both ways: none"
is "2460 the network stubs were never started" "$S2460_RC|$(cat "$S2460_D/net.log")" "0|"
