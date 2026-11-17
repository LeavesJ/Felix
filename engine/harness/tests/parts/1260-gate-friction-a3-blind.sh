# >>> gate-friction-a3-bridge
printf '\ngate friction A3: a suite run stands across the one commit that records it (blind)\n'
# Blind, written from contract A3 alone (audits/2026-10-12-gate-friction/
# CONTRACT-A3.md, rule C10) on 2026-10-12, before the code it describes
# existed. Nothing here was read off an implementation of it. tests/receipt.sh
# is sourced in a child bash of its own and asked about fixture repositories
# under $TMP, as parts 1100 and 1120 ask it; `tests/run --reuse` is this tree's
# driver copied into one of them, with its part lines replaced by one stub
# part that says it ran and exits 3, beside this tree's receipt.sh and lib.
# Each receipt here is written by this block with the tree id, environment and
# origin/main that receipt.sh's own helpers give for the state the "run" left.
# An assertion whose name ends in (control) passes on the code before the
# change on purpose: it pins something the contract keeps as it is today.
#
# Readings of the contract taken here: "the parent is an ancestor of the
# recorded origin/main" includes the parent being that commit itself, as git
# merge-base --is-ancestor says; and the seven-field line's seventh field is
# HEAD's full 40-digit sha.
GFD="$TMP/gfd-bridge"; mkdir -p "$GFD"
GFD_R="$REAL_HARNESS/tests/receipt.sh"
_gfd_git() { git -c user.name=gfd -c user.email=gfd@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
_gfd_sr() { bash -c '. "$1" >/dev/null 2>&1 || exit 97; shift; "$@"' _ "$GFD_R" "$@" 2>/dev/null; }
_gfd_chk() { local o; o="$(_gfd_sr _sr_check "$1")"; printf '%s|%s' "$o" "$?"; }   # output|status
_gfd_want() { printf '%s' "${1:-<nothing was computed to compare with>}"; }
_gfd_head() { git -C "${1:?}" rev-parse HEAD 2>/dev/null; }
_gfd_hm() { date -r "$1" +%H:%M 2>/dev/null || date -d "@$1" +%H:%M 2>/dev/null; }
_gfd_q() { sed 's/^/| /'; }
_gfd_tree_of() {   # pid -> it and every process below it
  ps -A -o pid= -o ppid= 2>/dev/null | awk -v root="$1" '
    { kids[$2] = kids[$2] " " $1 }
    END { q = root; out = ""
          while (q != "") { n = split(q, a, " "); q = ""
                            for (i = 1; i <= n; i++) if (a[i] != "") { out = out " " a[i]; q = q kids[a[i]] } }
          print out }'
}

# felix_tree_id as the base (PR A, 2e4d3b33) has it, kept here as a copy so the
# id it prints can be compared with this tree's for the same state (C10.6).
# Restated 2026-10-18 for slot 13, cut before A3: an unborn HEAD with something
# staged hashes the staged diff too, so two staged contents no longer share the
# id of a bare `git init`. That is the one change 13 made to the bytes of a
# tree git reads in full, and the copy carries it so this control still asks
# that A3 moves no id beyond it.
cat > "$GFD/verify-base.sh" <<'GFD_BASE_VERIFY'
FELIX_UNTRACKED_CAP="${FELIX_UNTRACKED_CAP:-500}"
_felix_hash() { git hash-object --stdin 2>/dev/null; }
_FELIX_STAT=""
_felix_stat_mode() {
  [ -n "$_FELIX_STAT" ] && return 0
  if stat -c '%s' /dev/null >/dev/null 2>&1; then _FELIX_STAT=gnu
  elif stat -f '%z' /dev/null >/dev/null 2>&1; then _FELIX_STAT=bsd
  else _FELIX_STAT=none; fi
}
_felix_meta_all() {
  _felix_stat_mode
  case "$_FELIX_STAT" in
    gnu) stat -c '%n %s %Y' "$@" 2>/dev/null ;;
    bsd) stat -f '%N %z %m' "$@" 2>/dev/null ;;
    *)   printf '%s\n' "$@" ;;
  esac
}
_felix_tree_excludes() {
  local root="$1" home="${2:-}" rel
  [ -n "$home" ] || return 0
  case "$home" in
    "$root")   rel="" ;;
    "$root"/*) rel="${home#"$root"/}/" ;;
    *)         return 0 ;;
  esac
  printf ':(exclude)%sstate/**\n'                 "$rel"
  printf ':(exclude)%sprojects/*/memory/*.log\n'  "$rel"
  printf ':(exclude)%sprojects/*/maintenance.log\n' "$rel"
}
felix_tree_id() {
  local root="$1" home="${2:-}" head diff cached untracked n meta="" prefix="" f
  git -C "$root" rev-parse --git-dir >/dev/null 2>&1 || return 1
  local ex; ex="$(_felix_tree_excludes "$root" "$home")"
  local exargs=()
  while IFS= read -r f; do [ -n "$f" ] && exargs+=("$f"); done <<EOF
$ex
EOF
  if [ "$#" -gt 2 ]; then shift 2; for f in "$@"; do exargs+=("$f"); done; fi
  head="$(git -C "$root" rev-parse HEAD 2>/dev/null)" || head=""
  if [ -z "$head" ]; then
    head="unborn"
    diff="$(git -C "$root" diff -- . "${exargs[@]+"${exargs[@]}"}" 2>/dev/null)"
    cached="$(git -C "$root" diff --cached -- . "${exargs[@]+"${exargs[@]}"}" 2>/dev/null)"
    [ -z "$cached" ] || diff="$cached
$diff"
  else
    diff="$(git -C "$root" diff HEAD -- . "${exargs[@]+"${exargs[@]}"}" 2>/dev/null)"
  fi
  untracked="$(git -C "$root" ls-files --others --exclude-standard \
                 -- . "${exargs[@]+"${exargs[@]}"}" 2>/dev/null | LC_ALL=C sort)"
  n="$(printf '%s' "$untracked" | grep -c . 2>/dev/null)" || n=0
  if [ "${n:-0}" -gt "$FELIX_UNTRACKED_CAP" ]; then
    prefix="coarse:"
    meta="$n untracked"
  elif [ "${n:-0}" -gt 0 ]; then
    local files=()
    while IFS= read -r f; do
      [ -n "$f" ] && files+=("$root/$f")
    done <<EOF
$untracked
EOF
    meta="$(_felix_meta_all "${files[@]}")"
  fi
  printf '%s%s' "$prefix" \
    "$(printf '%s\n%s\n%s' "$head" "$diff" "$meta" | _felix_hash)"
}
GFD_BASE_VERIFY
_gfd_tid_now()  { ( . "$REAL_HARNESS/lib/verify.sh" >/dev/null 2>&1; felix_tree_id "$@" ) 2>/dev/null; }
_gfd_tid_base() { ( . "$GFD/verify-base.sh" >/dev/null 2>&1; felix_tree_id "$@" ) 2>/dev/null; }
_gfd_same_tid() {   # <name> <args to felix_tree_id...>
  local n="$1" b; shift
  b="$(_gfd_tid_base "$@")"
  is "$n" "$(_gfd_tid_now "$@")" "$(_gfd_want "$b")"
}

# <dir> <origin: yes|no> [driver]: a repository on main whose first commit M
# holds a.txt, b.txt and the two record files (and, with driver, a copy of this
# tree's driver, receipt.sh and lib), with refs/remotes/origin/main naming M
# when origin is yes, and a second commit X on top of M that changes b.txt. X
# is the commit the "run" is on, and it is not an ancestor of M.
_gfd_repo() {
  local d="${1:?}" x
  mkdir -p "$d/engine/harness/tests" || return 1
  printf 'a\n' > "$d/a.txt"; printf 'b\n' > "$d/b.txt"
  printf '1\tone\n' > "$d/engine/harness/tests/assertions.tsv"
  printf 'base\t-\t-\t-\nrun\t-\t-\t-\n' > "$d/engine/harness/tests/red.tsv"
  if [ "${3:-}" = driver ]; then
    _copy_content "$REAL_HARNESS/lib" "$d/engine/harness/lib"
    cp "$GFD_R" "$d/engine/harness/tests/receipt.sh"
    mkdir -p "$d/engine/harness/tests/parts"
    # The suite's preamble parts stay in the copy (part 0003's _suite_copy_driver): since 3+3b they hold $TMP and the EXIT trap.
    _suite_copy_driver "$REAL_HARNESS/tests/run" "$d/engine/harness/tests" 0001-gfd-stub.sh
    chmod +x "$d/engine/harness/tests/run"
    printf 'printf %s\nexit 3\n' "'gfd fixture part ran\\n'" > "$d/engine/harness/tests/parts/0001-gfd-stub.sh"
  fi
  ( cd "${d:?}" && _gfd_git init -q -b main && _gfd_git add -A && _gfd_git commit -qm base ) >/dev/null 2>&1
  [ "$2" = yes ] && _fx_git "${d:?}" update-ref refs/remotes/origin/main HEAD >/dev/null 2>&1
  printf 'b-topic\n' > "$d/b.txt"
  _gfd_git -C "${d:?}" commit -qam topic >/dev/null 2>&1
}
# What a record run leaves uncommitted: both record files rewritten.
_gfd_rf() {
  printf '2\tone\n2\ttwo\n' > "${1:?}/engine/harness/tests/assertions.tsv"
  printf 'base\tmain\tx\t1\nrun\tgfd\ty\t0\n' > "${1:?}/engine/harness/tests/red.tsv"
}
# <dir> [mode passed failed skipped end-seconds-ago failed-field-override]:
# a receipt for the tree as it is now, written to the checkout's git directory
# with the tree id, environment and origin/main receipt.sh gives for it.
# GFD_ENVX, when set, is written as the environment in place of _sr_env's.
# Sets GFD_END to the end time written.
_gfd_rec() {
  local d="${1:?}" t e o ago="${6:-100}"
  t="$(_gfd_sr _sr_tree "$d")"; e="${GFD_ENVX:-$(_gfd_sr _sr_env)}"; o="$(_gfd_sr _sr_origin "$d")"
  [ -n "$o" ] && [ "$o" != - ] && e="$e;origin=$o"
  GFD_END=$(( $(date +%s) - ago ))
  printf 'v1\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "${t:-<no tree id>}" "${2:-normal}" "${3:-5}" "${4:-0}" "${5:-0}" \
    "$e" "$((GFD_END - 60))" "$GFD_END" > "$d/.git/felix-suite-receipt"
}
# <name> <dir> [args]: the fixture's copy of the driver, from its root, killed
# at 60 s. Out in $GFD/<name>.out; GFD_RC its status, 124 when killed.
_gfd_drive() {
  local n="$1" d="$2" pid k c=0
  shift 2
  ( cd "${d:?}" && exec env -u FELIX_TEST_NO_MANIFEST bash "$d/engine/harness/tests/run" "$@" ) > "$GFD/$n.out" 2> "$GFD/$n.err" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$c" -lt 600 ]; do sleep 0.1; c=$((c + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    for k in $(_gfd_tree_of "$pid"); do kill -9 "$k" 2>/dev/null; done
    wait "$pid" 2>/dev/null; GFD_RC=124
  else
    wait "$pid"; GFD_RC=$?
  fi
}
GFD_E="$(_gfd_sr _sr_env)"
GFD_GATE_RE='reused the suite run that ended .* on this tree \(.*\), not run again'

# ---- C10.3 and C10.4: the typical case, the two record files committed as Y
GFD_A="$GFD/a"; _gfd_repo "$GFD_A" yes driver; GFD_A="$(cd "${GFD_A:?}" && pwd)"
_gfd_rf "$GFD_A"; _gfd_rec "$GFD_A" record 7 0 2; GFD_AE="$GFD_END"; GFD_AHM="$(_gfd_hm "$GFD_AE")"
is  "a receipt on the tree as it is now, nothing committed since, says today's six fields (control)" \
    "$(_gfd_chk "$GFD_A")" "reuse 7 0 2 $GFD_AE record|0"
_gfd_drive a0 "$GFD_A" --reuse
is  "and tests/run --reuse on it exits 0 (control)" "$GFD_RC" "0"
is  "with today's first line, naming no commit (control)" "$(sed -n 1p "$GFD/a0.out")" \
    "reused the suite run that ended $GFD_AHM on this tree (record), not run again"
cp "$GFD_A/.git/felix-suite-receipt" "$GFD/a.receipt"
_gfd_git -C "${GFD_A:?}" commit -qam record >/dev/null 2>&1
GFD_AY="$(_gfd_head "$GFD_A")"; GFD_AY8="$(printf '%s' "$GFD_AY" | cut -c1-8)"
is  "after exactly those changes are committed as Y, the receipt stands, the seventh field naming Y's full sha" \
    "$(_gfd_chk "$GFD_A")" "reuse 7 0 2 $GFD_AE record $(_gfd_want "$GFD_AY")|0"
cmp -s "$GFD_A/.git/felix-suite-receipt" "$GFD/a.receipt" \
  && ok  "and asking leaves the receipt byte for byte as it was (control)" \
  || bad "and asking leaves the receipt byte for byte as it was (control)" "the receipt changed or is gone"
_gfd_drive a1 "$GFD_A" --reuse
is  "tests/run --reuse on the bridged receipt exits 0" "$GFD_RC" "0"
is  "and its first line says the run was then committed as Y's first 8" "$(sed -n 1p "$GFD/a1.out")" \
    "reused the suite run that ended $GFD_AHM on this tree (record, then committed as $GFD_AY8), not run again"
sed -n 1p "$GFD/a1.out" | grep -qE "$GFD_GATE_RE" \
  && ok  "a line the gate's search pattern finds" \
  || bad "a line the gate's search pattern finds" "$(sed -n 1p "$GFD/a1.out" | _gfd_q)"
is  "and its last line is the summary, unchanged" "$(sed -n '$p' "$GFD/a1.out")" "7 passed, 0 failed, 2 skipped (reused)"
grep -q 'gfd fixture part ran' "$GFD/a1.out" \
  && bad "and no part of the suite ran" "$(_gfd_q < "$GFD/a1.out")" \
  || ok  "and no part of the suite ran"

# ---- C10.3b: what the commit holds may be less than the run left
GFD_I="$GFD/i"; _gfd_repo "$GFD_I" yes
_gfd_rf "$GFD_I"; _gfd_rec "$GFD_I" normal 4 0 1; GFD_IE="$GFD_END"
_gfd_git -C "${GFD_I:?}" add engine/harness/tests/assertions.tsv >/dev/null 2>&1
_gfd_git -C "${GFD_I:?}" commit -qm part >/dev/null 2>&1
is  "a commit holding one of the two changes, the other still uncommitted, stands on the bridge with Y's sha" \
    "$(_gfd_chk "$GFD_I")" "reuse 4 0 1 $GFD_IE normal $(_gfd_want "$(_gfd_head "$GFD_I")")|0"

# ---- C10.3c: a receipt that recorded no origin/main is not held by it
GFD_K="$GFD/k"; _gfd_repo "$GFD_K" no
_gfd_rf "$GFD_K"; _gfd_rec "$GFD_K" normal 6 0 0; GFD_KE="$GFD_END"
case "$(sed -n 1p "$GFD_K/.git/felix-suite-receipt")" in
  *";origin="*) bad "the no-origin fixture's receipt records no origin/main (control)" "it records one" ;;
  *) ok "the no-origin fixture's receipt records no origin/main (control)" ;;
esac
_gfd_git -C "${GFD_K:?}" commit -qam record >/dev/null 2>&1
is  "a receipt that recorded no origin/main stands across the commit, with the seventh field" \
    "$(_gfd_chk "$GFD_K")" "reuse 6 0 0 $GFD_KE normal $(_gfd_want "$(_gfd_head "$GFD_K")")|0"

# ---- C10.5: the parent is an ancestor of the recorded origin/main
GFD_C5='run another tree (committed since the run, and origin/main already held the commit the run was on)'
GFD_J="$GFD/j"; _gfd_repo "$GFD_J" yes
_fx_git "${GFD_J:?}" update-ref refs/remotes/origin/main HEAD >/dev/null 2>&1
_gfd_rf "$GFD_J"; _gfd_rec "$GFD_J"
_gfd_git -C "${GFD_J:?}" commit -qam record >/dev/null 2>&1
is  "a run on the very commit origin/main named, then committed, refuses with C10.5's reason" "$(_gfd_chk "$GFD_J")" "$GFD_C5|0"
GFD_J2="$GFD/j2"; _gfd_repo "$GFD_J2" yes
_gfd_git -C "${GFD_J2:?}" checkout -q -b up >/dev/null 2>&1
printf 'up\n' > "$GFD_J2/c.txt"; _gfd_git -C "${GFD_J2:?}" add -A >/dev/null 2>&1; _gfd_git -C "${GFD_J2:?}" commit -qm up >/dev/null 2>&1
_fx_git "${GFD_J2:?}" update-ref refs/remotes/origin/main HEAD >/dev/null 2>&1
_gfd_git -C "${GFD_J2:?}" checkout -q main >/dev/null 2>&1
_gfd_rf "$GFD_J2"; _gfd_rec "$GFD_J2"
_gfd_git -C "${GFD_J2:?}" commit -qam record >/dev/null 2>&1
is  "and so does one on a commit the recorded origin/main has below it" "$(_gfd_chk "$GFD_J2")" "$GFD_C5|0"
_gfd_git -C "${GFD_J:?}" commit -q --allow-empty -m again >/dev/null 2>&1
is  "where the bridge itself does not hold, origin/main's ancestry or not, it is plain another tree (control)" \
    "$(_gfd_chk "$GFD_J")" "run another tree|0"

# ---- C10.3d: every later check still refuses after a bridge, in today's order
GFD_L1="$GFD/l1"; _gfd_repo "$GFD_L1" yes; _gfd_rf "$GFD_L1"
GFD_ENVX="host=gfd-elsewhere;${GFD_E#*;}"; _gfd_rec "$GFD_L1"; unset GFD_ENVX
_gfd_git -C "${GFD_L1:?}" commit -qam record >/dev/null 2>&1
is  "a bridged receipt from another environment refuses with run another environment" "$(_gfd_chk "$GFD_L1")" "run another environment|0"
GFD_L2="$GFD/l2"; _gfd_repo "$GFD_L2" yes; _gfd_rf "$GFD_L2"; _gfd_rec "$GFD_L2"
_gfd_git -C "${GFD_L2:?}" commit -qam record >/dev/null 2>&1
GFD_L2M="$(git -C "${GFD_L2:?}" rev-parse refs/remotes/origin/main 2>/dev/null)"
GFD_L2N="$(printf 'moved\n' | _gfd_git -C "${GFD_L2:?}" commit-tree "$GFD_L2M^{tree}" -p "$GFD_L2M" 2>/dev/null)"
_fx_git "${GFD_L2:?}" update-ref refs/remotes/origin/main "${GFD_L2N:-$GFD_L2M}" >/dev/null 2>&1
is  "a bridged receipt whose origin/main has moved since refuses with run origin/main moved" "$(_gfd_chk "$GFD_L2")" "run origin/main moved|0"
GFD_L3="$GFD/l3"; _gfd_repo "$GFD_L3" yes; _gfd_rf "$GFD_L3"; _gfd_rec "$GFD_L3" normal 5 0 0 43300
_gfd_git -C "${GFD_L3:?}" commit -qam record >/dev/null 2>&1
is  "a bridged receipt that ended more than twelve hours ago refuses with run older than 12 hours" "$(_gfd_chk "$GFD_L3")" "run older than 12 hours|0"
GFD_L4="$GFD/l4"; _gfd_repo "$GFD_L4" yes; _gfd_rf "$GFD_L4"; _gfd_rec "$GFD_L4" normal 5 1 0
_gfd_git -C "${GFD_L4:?}" commit -qam record >/dev/null 2>&1
is  "a receipt with failures says run failures recorded, before any tree is asked (control)" "$(_gfd_chk "$GFD_L4")" "run failures recorded|0"

# ---- C10.3, One commit only: two commits since
GFD_C="$GFD/c"; _gfd_repo "$GFD_C" yes; _gfd_rf "$GFD_C"; _gfd_rec "$GFD_C"
_gfd_git -C "${GFD_C:?}" commit -qam record >/dev/null 2>&1
_gfd_git -C "${GFD_C:?}" commit -q --allow-empty -m empty >/dev/null 2>&1
is  "two commits since the run, the second empty, is run another tree (control)" "$(_gfd_chk "$GFD_C")" "run another tree|0"

# ---- C10.1: a merge commit whose first parent is X has no bridged id
GFD_D="$GFD/d"; _gfd_repo "$GFD_D" yes; GFD_DX="$(_gfd_head "$GFD_D")"
_gfd_rf "$GFD_D"; _gfd_rec "$GFD_D"
_gfd_git -C "${GFD_D:?}" checkout -q -b side >/dev/null 2>&1
_gfd_git -C "${GFD_D:?}" commit -qam record >/dev/null 2>&1
_gfd_git -C "${GFD_D:?}" checkout -q main >/dev/null 2>&1
_gfd_git -C "${GFD_D:?}" merge -q --no-ff -m merge side >/dev/null 2>&1
if [ "$(git -C "${GFD_D:?}" rev-parse HEAD^1 2>/dev/null)" = "$GFD_DX" ] \
   && [ -z "$(git -C "${GFD_D:?}" status --porcelain 2>/dev/null)" ]; then
  is  "a merge commit whose first parent is the run's commit, holding exactly its changes, is run another tree (control)" \
      "$(_gfd_chk "$GFD_D")" "run another tree|0"
else
  bad "a merge commit whose first parent is the run's commit, holding exactly its changes, is run another tree (control)" \
      "the fixture's merge was not made as intended"
fi
_gfd_rec "$GFD_D" normal 8 0 0; GFD_DE="$GFD_END"
is  "a receipt that matches the merge as it is now says today's six fields, no commit named (control)" \
    "$(_gfd_chk "$GFD_D")" "reuse 8 0 0 $GFD_DE normal|0"

# ---- C10.1: a root commit has no bridged id
GFD_E0="$GFD/e"; mkdir -p "$GFD_E0"
printf 'r\n' > "$GFD_E0/r.txt"; printf 's\n' > "$GFD_E0/s.txt"
( cd "${GFD_E0:?}" && _gfd_git init -q -b main && _gfd_git add -A ) >/dev/null 2>&1
_gfd_rec "$GFD_E0"
_gfd_same_tid "felix_tree_id of an unborn HEAD with everything staged is the id the base printed (control)" "$GFD_E0" ""
_gfd_git -C "${GFD_E0:?}" commit -qm root >/dev/null 2>&1
is  "a root commit made of exactly what an unborn run left staged is run another tree (control)" "$(_gfd_chk "$GFD_E0")" "run another tree|0"

# ---- C10.3b: what the commit made tracked, and what came after it
GFD_F="$GFD/f"; _gfd_repo "$GFD_F" yes; _gfd_rf "$GFD_F"; printf 'u\n' > "$GFD_F/u.txt"; _gfd_rec "$GFD_F"
_gfd_git -C "${GFD_F:?}" add -A >/dev/null 2>&1; _gfd_git -C "${GFD_F:?}" commit -qm record >/dev/null 2>&1
is  "a commit that adds a file the run saw untracked is run another tree (control)" "$(_gfd_chk "$GFD_F")" "run another tree|0"
GFD_G="$GFD/g"; _gfd_repo "$GFD_G" yes; _gfd_rf "$GFD_G"; _gfd_rec "$GFD_G"
_gfd_git -C "${GFD_G:?}" commit -qam record >/dev/null 2>&1
printf 'a-later\n' > "$GFD_G/a.txt"
is  "a commit of the run's changes plus a further uncommitted change is run another tree (control)" "$(_gfd_chk "$GFD_G")" "run another tree|0"
GFD_H="$GFD/h"; _gfd_repo "$GFD_H" yes; _gfd_rec "$GFD_H"
printf 'a-new\n' > "$GFD_H/a.txt"; _gfd_git -C "${GFD_H:?}" commit -qam change >/dev/null 2>&1
is  "a run on a clean tree, then a commit that changes a file, is run another tree (control)" "$(_gfd_chk "$GFD_H")" "run another tree|0"

# ---- C10.6: felix_tree_id prints, for every existing call, what the base printed
_gfd_same_tid "felix_tree_id on the bridged commit, clean, is the base's id (control)" "$GFD_A" ""
_gfd_same_tid "felix_tree_id on a merge commit is the base's id (control)" "$GFD_D" ""
_gfd_same_tid "felix_tree_id with tracked changes after a commit is the base's id (control)" "$GFD_G" ""
_gfd_same_tid "felix_tree_id with part of a change still uncommitted is the base's id (control)" "$GFD_I" ""
mkdir -p "$GFD_G/home/state"; printf 'x\n' > "$GFD_G/home/state/x"; printf 'v\n' > "$GFD_G/v.txt"
_gfd_same_tid "felix_tree_id with untracked files is the base's id (control)" "$GFD_G" ""
_gfd_same_tid "felix_tree_id with Felix's home inside the tree is the base's id (control)" "$GFD_G" "$GFD_G/home"
_gfd_same_tid "felix_tree_id with the record files left out, as _sr_tree stable asks, is the base's id (control)" "$GFD_G" "" \
  ':(exclude)engine/harness/tests/assertions.tsv' ':(exclude)engine/harness/tests/red.tsv'
GFD_CO_N="$( (FELIX_UNTRACKED_CAP=1; . "$REAL_HARNESS/lib/verify.sh" >/dev/null 2>&1; felix_tree_id "$GFD_G" "") 2>/dev/null)"
GFD_CO_B="$( (FELIX_UNTRACKED_CAP=1; . "$GFD/verify-base.sh" >/dev/null 2>&1; felix_tree_id "$GFD_G" "") 2>/dev/null)"
case "$GFD_CO_B" in
  coarse:*) is "felix_tree_id over the untracked cap is the base's coarse id (control)" "$GFD_CO_N" "$GFD_CO_B" ;;
  *) bad "felix_tree_id over the untracked cap is the base's coarse id (control)" "the base copy's id is not coarse: [$GFD_CO_B]" ;;
esac

# ---- Not blind: review finding C10-1 (2026-10-12), written after the code.
# A criss-cross: two commits, A1 and B1, made in the same second, both best
# common ancestors of the branch and of origin/main (which is merge(A1, B1)),
# the branch being merge(B1, A1) and then the run's commit X. Part 1010's judge
# asks `git merge-base HEAD origin/main`, which names one of the two, and with
# equal commit seconds git's choice can change when one commit is put on top of
# X: on git 2.54 it names A1 at X and B1 at the commit that records the run, so
# part 1010's _rtn3 passed at X and fails at the commit. The bridge may not
# stand where the choice is open, whichever git is asked, so this fixture asks
# only for what is structural, that the two bases are both best (merge-base
# --all prints two), and the bridge refuses on that alone (C10.3e).
_gfd_cc() {   # <dir>: the criss-cross above, HEAD at X, both record files committed
  local d="${1:?}"
  mkdir -p "$d/engine/harness/tests" || return 1
  printf 'a\n' > "$d/a.txt"; printf 'b\n' > "$d/b.txt"
  printf '1\tone\n' > "$d/engine/harness/tests/assertions.tsv"
  printf 'base\t-\t-\t-\nrun\t-\t-\t-\n' > "$d/engine/harness/tests/red.tsv"
  (
    export GIT_AUTHOR_DATE="@1700000000 +0000" GIT_COMMITTER_DATE="@1700000000 +0000"
    _fx_cd "${d:?}" || exit 1
    _gfd_git init -q -b main && _gfd_git add -A && _gfd_git commit -qm root || exit 1
    r0="$(git rev-parse HEAD)" && printf 'a1\n' > a.txt && _gfd_git commit -qam A1 || exit 1
    a1="$(git rev-parse HEAD)" || exit 1
    _gfd_git checkout -q -b sideB "$r0" && printf 'b1\n' > b.txt && _gfd_git commit -qam B1 || exit 1
    b1="$(git rev-parse HEAD)" || exit 1
    _gfd_git checkout -q --detach "$a1" && _gfd_git merge -q --no-ff --no-edit "$b1" || exit 1
    git update-ref refs/remotes/origin/main HEAD || exit 1
    _gfd_git checkout -q sideB && _gfd_git merge -q --no-ff --no-edit "$a1" || exit 1
    printf 'x\n' > c.txt && _gfd_git add -A && _gfd_git commit -qm X || exit 1
  ) >/dev/null 2>&1
}
GFD_CC="$GFD/cc"; _gfd_cc "$GFD_CC"; _gfd_rf "$GFD_CC"; _gfd_rec "$GFD_CC"
_gfd_git -C "${GFD_CC:?}" commit -qam record >/dev/null 2>&1
GFD_CCN="not blind: review finding C10-1: a criss-cross whose two best merge bases share a second, committed once since the run, is run another tree, since git's pick between them can change with the commit"
if [ "$(git -C "${GFD_CC:?}" merge-base --all HEAD refs/remotes/origin/main 2>/dev/null | grep -c .)" = 2 ] \
   && [ "$(git -C "${GFD_CC:?}" rev-list --parents -n 1 HEAD 2>/dev/null | wc -w | tr -d ' ')" = 2 ]; then
  is  "$GFD_CCN" "$(_gfd_chk "$GFD_CC")" "run another tree|0"
else
  bad "$GFD_CCN" "the fixture's criss-cross was not made as intended"
fi

# ---- Not blind: a mutant that survived the blind block (2026-10-12). A
# felix_tree_id whose refactor dropped the extra pathspecs left every assertion
# above green, since the record files in the control above are committed and
# clean, so leaving them out changes nothing. Here one is modified, and the base
# copy is asked first whether leaving it out matters, so the fixture cannot go
# vacuous again. (Part 1100's C8 assertions also catch that mutant.)
printf 'dirty\n' >> "$GFD_G/engine/harness/tests/red.tsv"
GFD_XA=':(exclude)engine/harness/tests/assertions.tsv'; GFD_XB=':(exclude)engine/harness/tests/red.tsv'
GFD_XN="not blind: felix_tree_id with a record file modified and left out, as _sr_tree stable asks, is the base's id (control)"
if [ "$(_gfd_tid_base "$GFD_G" "")" != "$(_gfd_tid_base "$GFD_G" "" "$GFD_XA" "$GFD_XB")" ]; then
  _gfd_same_tid "$GFD_XN" "$GFD_G" "" "$GFD_XA" "$GFD_XB"
else
  bad "$GFD_XN" "leaving the modified record file out did not change the base copy's id: the fixture is vacuous"
fi
