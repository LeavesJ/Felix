# The same contract, asserted blind. These were written from a statement of
# what felix_guard_unrecorded and felix_mem_mistake must do, by an author who
# never saw the implementation or the assertions above, and run against
# origin/main's engine before this one existed: 23 of these 43 failed there,
# every one for a reason the contract names. Kept beside the author's own
# because each finds what the other left unsaid.
#
# Four were re-keyed after the adversarial review, which found the contract's
# reflog walk failing open (checkout -B, a detached round trip, a session that
# gates more than one branch) and replaced it with the session each row now
# names. The three cases that walked renames and checkouts give their row the
# session asking, and the writer's row has six columns where it had five. The
# names say what each asks now.
#
# Nine more were re-keyed when an entry began settling only its writer's
# catches: every case here that settled a catch with a lesson or a devlog
# entry, and the three that took one away. They had settled it by the file's
# time, which review measured a peer's lesson moving within hours of nearly
# every catch. A lesson or devlog entry here is now the prose and the row felix
# lesson or felix log files beside it, at the same second, naming the branch
# of the checkout the case asks from and no session, and taking one away takes
# both. Each asks what it asked: after the catch, before it, the same second,
# a minute on, a non-empty devlog, the row the file's order picks, the file's
# time for an untimed row, and a sibling's own lesson. Only the owner is new.
printf '\nunrecorded catches, per checkout (blind)\n'
_memory_guarded_build

_B="$MEM/guarded"; _BM="$_B/mistakes.log"; _BL="$_B/lessons.md"; _BD="$_B/DEVLOG.md"
_BFIRST='The gate caught something here and nothing has been written down since.'
_BN="$(date +%s)"

# epoch n minutes ago, and n days ago
_bago()  { printf '%s' "$(( _BN - $1 * 60 ))"; }
_bdago() { printf '%s' "$(( _BN - $1 * 86400 ))"; }
# epoch -> touch -t stamp / YYYY-MM-DD (BSD date -r, else GNU date -d @)
_bstamp() { date -r "$1" +%Y%m%d%H%M.%S 2>/dev/null || date -d "@$1" +%Y%m%d%H%M.%S; }
_bday()   { date -r "$1" +%Y-%m-%d 2>/dev/null || date -d "@$1" +%Y-%m-%d; }
# set a file's mtime to an epoch second
_bmt() { touch -t "$(_bstamp "$1")" "$2"; }

# a fresh memory dir: no log, no lessons, no devlog
_BW="$_B/written.log"
_breset() { rm -f "$_BM" "$_BL" "$_BD" "$_BW"; }
# append a row: branch checks [epoch]. With an epoch the row has five columns
# and its date column is that epoch's day; without, the old four-column shape.
_brow() {
  local day
  if [ $# -ge 3 ]; then day="$(_bday "$3")"; else day="$(date +%Y-%m-%d)"; fi
  printf '%s\t%s\t%s\t%s' "$day" "$1" "abc1234" "$2" >> "$_BM"
  [ $# -ge 3 ] && printf '\t%s' "$3" >> "$_BM"
  printf '\n' >> "$_BM"
}
# a lesson / devlog entry at an epoch second
# by the checkout on BRANCH (mine unless named): the prose, and the one row of
# its kind that felix lesson or felix log files beside it
_bwrote() {
  { [ -f "$_BW" ] && awk -F'\t' -v K="$2" '$4 != K' "$_BW"
    printf '%s\t%s\tabc1234\t%s\t%s\t-\n' "$(_bday "$1")" "$3" "$2" "$1"; } > "$_BW.t"
  mv "$_BW.t" "$_BW"
}
_blesson() { printf -- '- **something learned**\n' > "$_BL"; _bmt "$1" "$_BL"; _bwrote "$1" lesson "${2:-mine}"; }
_bdevlog() { printf '## what happened and why\n' > "$_BD"; _bmt "$1" "$_BD"; _bwrote "$1" log "${2:-mine}"; }
_bunlesson() { rm -f "$_BL"; [ -f "$_BW" ] && awk -F'\t' '$4 != "lesson"' "$_BW" > "$_BW.t" && mv "$_BW.t" "$_BW"; }

# the guard, for one checkout root (or none)
_bu()   { ( . "$FROOT/harness/lib/guard.sh"; felix_guard_unrecorded "$GP" "$1" ) 2>/dev/null; }
_bu0()  { ( . "$FROOT/harness/lib/guard.sh"; felix_guard_unrecorded "$GP" ) 2>/dev/null; }
_bus()  { ( . "$FROOT/harness/lib/guard.sh"; felix_guard_unrecorded "$GP" "$1" "$2" ) 2>/dev/null; }
# a row this session filed: branch checks epoch, with the session in column 6
_browS() { printf '%s\t%s\t%s\t%s\t%s\tb-sess\n' "$(_bday "$3")" "$1" "abc1234" "$2" "$3" >> "$_BM"; }
# the value of the "  last caught   <checks>" line
_bcaught() { printf '%s\n' "$1" | sed -n 's/^  last caught   //p' | head -1; }

# throwaway repos
_bg() { git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
_brepo() { # dir initial-branch
  mkdir -p "$1"
  _bg -C "$1" -c init.defaultBranch="$2" init -q >/dev/null 2>&1
  _bg -C "$1" commit -q --allow-empty -m init >/dev/null 2>&1
}
_bhead() { git -C "$1" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?'; }

R_MINE="$TMP/b-mine";   _brepo "$R_MINE" mine
R_OTHER="$TMP/b-other"; _brepo "$R_OTHER" other
R_V="$TMP/b-v";         _brepo "$R_V" v1.2
# renamed: created as oldname, then git branch -m
R_REN="$TMP/b-ren";     _brepo "$R_REN" oldname
_bg -C "$R_REN" branch -m oldname newname >/dev/null 2>&1
# checkout -b from parent, then a commit on the new branch
R_CO="$TMP/b-co";       _brepo "$R_CO" parent
_bg -C "$R_CO" checkout -q -b child >/dev/null 2>&1
_bg -C "$R_CO" commit -q --allow-empty -m more >/dev/null 2>&1
# switch -c from base
R_SW="$TMP/b-sw";       _brepo "$R_SW" base
_bg -C "$R_SW" switch -q -c topic >/dev/null 2>&1
# on trunk, detached, then a new branch made from the detached HEAD
R_DET2="$TMP/b-det2";   _brepo "$R_DET2" trunk
_bg -C "$R_DET2" checkout -q --detach >/dev/null 2>&1
_bg -C "$R_DET2" checkout -q -b fresh >/dev/null 2>&1
# detached now
R_DET="$TMP/b-det";     _brepo "$R_DET" main
_bg -C "$R_DET" checkout -q --detach >/dev/null 2>&1
# not a repository
R_NG="$TMP/b-nongit";   mkdir -p "$R_NG"
# the writer's checkout and a sibling on another branch
R_W="$TMP/b-writer";    _brepo "$R_W" writer-br
R_S="$TMP/b-sibling";   _brepo "$R_S" sibling-br

_bfx="$(_bhead "$R_MINE") $(_bhead "$R_V") $(_bhead "$R_REN") $(_bhead "$R_CO") $(_bhead "$R_SW") $(_bhead "$R_DET2") $(_bhead "$R_DET") $(_bhead "$R_W")"
is "fixture: every throwaway checkout is on the branch its case assumes" \
   "$_bfx" "mine v1.2 newname child topic fresh HEAD writer-br"
git -C "$R_NG" rev-parse --git-dir >/dev/null 2>&1 \
  && bad "fixture: the non-git root is outside any repository" "$R_NG is inside a repo" \
  || ok  "fixture: the non-git root is outside any repository"

# --------------------------------------------------------------- (e) empty --
_breset
out="$(_bu "$R_MINE")"
is "silent when mistakes.log is missing" "${#out}" "0"

: > "$_BM"
out="$(_bu "$R_MINE")"
is "silent when mistakes.log is empty" "${#out}" "0"

# positive control for both: one row of this checkout's own, nothing written
_breset
_brow mine "lint " "$(_bago 30)"; _bmt "$(_bago 30)" "$_BM"
out="$(_bu "$R_MINE")"
is "speaks for this checkout's own unexplained catch, first line exact" \
   "$(printf '%s\n' "$out" | head -1)" "$_BFIRST"
is "and its last-caught line names that catch, trimmed" "$(_bcaught "$out")" "lint"

# ------------------------------------------------------ (a)(c) belonging --
# This checkout's catch was explained an hour ago; another checkout's later
# catch is not this checkout's to explain.
_breset
_brow mine  "tests "            "$(_bago 180)"
_brow other "secret qualified " "$(_bago 10)"
_bmt "$(_bago 10)" "$_BM"
_blesson "$(_bago 60)"
out="$(_bu "$R_MINE")"
is "another checkout's newer catch does not make this one speak" "${#out}" "0"
out="$(_bu "$R_OTHER")"
has "the same catch speaks for the checkout that owns it" "$out" "$_BFIRST"
is "and names it trimmed at the ends with its inner space kept" \
   "$(_bcaught "$out")" "secret qualified"

# Neither explained: this checkout's prompt names its own catch, not the
# file's last row.
_breset
_brow mine  "tests "            "$(_bago 30)"
_brow other "secret qualified " "$(_bago 10)"
_bmt "$(_bago 10)" "$_BM"
out="$(_bu "$R_MINE")"
is "last caught names this checkout's catch, not the file's last row" \
   "$(_bcaught "$out")" "tests"

# No row belongs at all.
_breset
_brow other     "otherscheck" "$(_bago 30)"
_brow elsewhere "elsecheck"   "$(_bago 20)"
_bmt "$(_bago 20)" "$_BM"
out="$(_bu "$R_MINE")"
is "silent when no row belongs to this checkout" "${#out}" "0"
out="$(_bu "$R_OTHER")"
is "while a checkout with a row there is named by it" "$(_bcaught "$out")" "otherscheck"

# Look-alike branch names: a dot is not a wildcard, a prefix or suffix is not
# the branch.
_breset
_brow v1.2    "owncheck"    "$(_bago 180)"
_brow v1x2    "dotcheck"    "$(_bago 20)"
_brow v1.2-rc "rccheck"     "$(_bago 15)"
_brow xv1.2   "prefixcheck" "$(_bago 10)"
_brow v1      "shortcheck"  "$(_bago 8)"
_bmt "$(_bago 8)" "$_BM"
_blesson "$(_bago 60)" v1.2
out="$(_bu "$R_V")"
is "rows of look-alike branch names do not belong (exact match only)" "${#out}" "0"
_bunlesson
out="$(_bu "$R_V")"
is "with the lesson gone it names its own row past the look-alikes" \
   "$(_bcaught "$out")" "owncheck"

# Renamed with git branch -m: the session's catch under the old name is still its own.
_breset
_browS oldname  "renamedcheck" "$(_bago 60)"
_brow unrelated "zzz"          "$(_bago 10)"
_bmt "$(_bago 10)" "$_BM"
out="$(_bus "$R_REN" b-sess)"
is "a session's catch under its branch's name before git branch -m is still its own" \
   "$(_bcaught "$out")" "renamedcheck"

# Made with checkout -b from parent, with a commit since.
_breset
_browS parent   "parentcheck" "$(_bago 60)"
_brow unrelated "zzz"         "$(_bago 10)"
_bmt "$(_bago 10)" "$_BM"
out="$(_bus "$R_CO" b-sess)"
is "a session's catch on the branch it left by checkout -b is its own, even after a commit" \
   "$(_bcaught "$out")" "parentcheck"

# Made with switch -c from base.
_breset
_browS base     "basecheck" "$(_bago 60)"
_brow unrelated "zzz"       "$(_bago 10)"
_bmt "$(_bago 10)" "$_BM"
out="$(_bus "$R_SW" b-sess)"
is "and one on the branch it left by switch -c" "$(_bcaught "$out")" "basecheck"

# Reached from a detached HEAD: nothing from before the detach, and the
# detached rows are not a branch it came from.
_breset
_brow trunk "beforedetach" "$(_bago 60)"
_bmt "$(_bago 60)" "$_BM"
out="$(_bu "$R_DET2")"
is "a branch made from a detached HEAD inherits nothing from before the detach" "${#out}" "0"
_breset
_brow HEAD "whiledetached" "$(_bago 60)"
_bmt "$(_bago 60)" "$_BM"
out="$(_bu "$R_DET2")"
is "nor the HEAD rows, once it is on a branch" "${#out}" "0"
_brow fresh "freshcheck" "$(_bago 30)"
_bmt "$(_bago 30)" "$_BM"
out="$(_bu "$R_DET2")"
is "but its own branch's catch still speaks" "$(_bcaught "$out")" "freshcheck"

# A detached checkout owns HEAD rows.
_breset
_brow HEAD      "detachedcheck" "$(_bago 60)"
_brow unrelated "zzz"           "$(_bago 10)"
_bmt "$(_bago 10)" "$_BM"
out="$(_bu "$R_DET")"
is "a detached checkout owns rows whose branch column is HEAD" \
   "$(_bcaught "$out")" "detachedcheck"
_breset
_brow elsewhere "elsecheck" "$(_bago 30)"
_bmt "$(_bago 30)" "$_BM"
out="$(_bu "$R_DET")"
is "a detached checkout is silent about other branches' rows" "${#out}" "0"

# ------------------------------------------------------------ (b)(c) time --
# A lesson strictly after the catch settles it; one before does not.
_breset
_brow mine "lint" "$(_bago 120)"; _bmt "$(_bago 120)" "$_BM"
_blesson "$(_bago 60)"
out="$(_bu "$R_MINE")"
is "a lesson written after the catch settles it" "${#out}" "0"
_blesson "$(_bago 180)"
out="$(_bu "$R_MINE")"
has "a lesson written before the catch does not" "$out" "$_BFIRST"

# The same second is not after.
_breset
_bt="$(_bago 60)"
_brow mine "lint" "$_bt"; _bmt "$_bt" "$_BM"
_blesson "$_bt"
out="$(_bu "$R_MINE")"
has "a lesson stamped the very second of the catch does not settle it" "$out" "$_BFIRST"
_blesson "$(( _bt + 60 ))"
out="$(_bu "$R_MINE")"
is "a lesson a minute after the catch does" "${#out}" "0"

# The devlog settles too, but only when it has something in it.
_breset
_brow mine  "lint" "$(_bago 180)"
_brow other "zzz"  "$(_bago 10)"
_bmt "$(_bago 10)" "$_BM"
_bdevlog "$(_bago 60)"
out="$(_bu "$R_MINE")"
is "a non-empty devlog written after the catch settles it" "${#out}" "0"
_bdevlog "$(_bago 240)"
out="$(_bu "$R_MINE")"
has "a non-empty devlog written before the catch does not" "$out" "$_BFIRST"
: > "$_BD"; _bmt "$(_bago 60)" "$_BD"
out="$(_bu "$R_MINE")"
has "an empty devlog newer than the catch does not settle it" "$out" "$_BFIRST"

# The week is measured from column 5, not from the file.
_breset
_brow mine  "stalecheck" "$(_bdago 8)"
_brow other "zzz"        "$(_bago 5)"
_bmt "$(_bago 5)" "$_BM"
out="$(_bu "$R_MINE")"
is "a catch eight days old is silent though the log was written since" "${#out}" "0"
_breset
_brow mine  "weekcheck" "$(_bdago 6)"
_brow other "zzz"       "$(_bago 5)"
_bmt "$(_bago 5)" "$_BM"
out="$(_bu "$R_MINE")"
is "a catch six days old still speaks" "$(_bcaught "$out")" "weekcheck"

# Column 5 is the time, even when the file's own mtime says otherwise.
_breset
_brow mine "lint" "$(_bago 30)"
_bmt "$(_bdago 10)" "$_BM"
_blesson "$(_bago 120)"
out="$(_bu "$R_MINE")"
has "a column-5 time after the lesson speaks though the log's mtime is old" "$out" "$_BFIRST"

# The newest belonging row is the last one in the file.
_breset
_brow mine "alpha" "$(_bago 10)"
_brow mine "beta"  "$(_bago 120)"
_bmt "$(_bago 10)" "$_BM"
_blesson "$(_bago 60)"
out="$(_bu "$R_MINE")"
is "the last belonging row in the file decides, not the largest time" "${#out}" "0"
_bunlesson
out="$(_bu "$R_MINE")"
is "and it is the one named" "$(_bcaught "$out")" "beta"

# ------------------------------------------------------ (d) never fail open --
_breset
_brow "?"   "qcheck"   "$(_bago 90)"
_brow other "lastrow " "$(_bago 30)"
_bmt "$(_bago 30)" "$_BM"
_blesson "$(_bago 60)"
out="$(_bu "$R_NG")"
is "a checkout root that is not a git repository counts every row" \
   "$(_bcaught "$out")" "lastrow"
out="$(_bu0)"
is "no checkout root at all counts every row" "$(_bcaught "$out")" "lastrow"

# A belonging row without column 5 is taken at the log's mtime.
_breset
_brow mine  "untimed"
_brow other "zzz" "$(_bago 10)"
_bmt "$(_bago 10)" "$_BM"
_blesson "$(_bago 60)"
out="$(_bu "$R_MINE")"
is "an untimed row of this checkout is taken at the log's mtime, and speaks" \
   "$(_bcaught "$out")" "untimed"
_breset
_brow mine "untimed"
_bmt "$(_bago 120)" "$_BM"
_blesson "$(_bago 60)"
out="$(_bu "$R_MINE")"
is "and is settled by a lesson newer than that mtime" "${#out}" "0"

# ---------------------------------------------------------------- writer --
_breset
_brow sibling-br "sibcheck" "$(_bago 180)"
_bmt "$(_bago 180)" "$_BM"
_blesson "$(_bago 120)" sibling-br
_bbefore="$(date +%s)"
( . "$FROOT/harness/lib/memory.sh"; felix_mem_mistake "$GP" "$R_W" "lint" ) >/dev/null 2>&1
_bafter="$(date +%s)"
_blast="$(tail -1 "$_BM")"
is "the writer appends, keeping the rows already there" \
   "$(wc -l < "$_BM" | tr -d ' ')|$(head -1 "$_BM" | cut -f2,4)" "2|sibling-br	sibcheck"
is "the writer keeps the four old columns" "$(printf '%s' "$_blast" | cut -f1-4)" \
   "$(date +%Y-%m-%d)	writer-br	$(git -C "$R_W" rev-parse --short HEAD)	lint"
_bc5="$(printf '%s' "$_blast" | awk -F'\t' '{print NF "|" $5}')"
_bep="${_bc5#*|}"
case "$_bep" in ''|*[!0-9]*) _bepok=no ;;
  *) [ "$_bep" -ge "$_bbefore" ] && [ "$_bep" -le "$_bafter" ] && _bepok=yes || _bepok=no ;; esac
is "the writer's fifth column is the current epoch second" "${_bc5%%|*}|$_bepok" "6|yes"
out="$(_bu "$R_W")"
is "the row it wrote speaks for the checkout that wrote it" "$(_bcaught "$out")" "lint"
out="$(_bu "$R_S")"
is "and not for a sibling checkout whose own catch was explained" "${#out}" "0"

_breset
unset -f _bago _bdago _bstamp _bday _bmt _breset _brow _browS _bwrote _blesson _bdevlog _bunlesson _bu _bu0 _bus _bcaught _bg _brepo _bhead

