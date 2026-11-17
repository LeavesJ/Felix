# The lane counter's review fixtures (slice 0, docs/2026-10-29-capability-lane-first-slices-design.md section 6 and
# section 11 items 45 to 49; the plan's Contracts C2, C5, C6 and C9), for the blind parts 2200 to 2250. Written blind on
# 2026-10-30 from the design, the Contracts and the reviews' findings (their inputs and observed output only), without
# reading lib/, hooks/, bin/ or felix. Moved whole out of lane-fixture.sh on 2026-10-30, with no function's text changed,
# so that every file of the library stays under 500 lines (V3R3-F2). Functions only (part 0006), each named _lf_ (C9).
# The builders they stand on (_lf_home, _lf_table, _lf_checkout, _lf_commit, _lf_own and the rest) are lane-fixture.sh's,
# and the probes run in them lane-probes.sh's.
#
# The second review's round 1: _lf_r2 builds its home-apart fixture (two lanes, cap and sec, and _lf_r2land's six
# landings). Its round 3: _lf_r3 builds R3-F1's home-apart fixture, whose first lane is short (sec before cap).
#
# The design's item 46: _lf_bind puts a repository in one of the layouts a binding takes or misses. The third review's
# round 1: _lf_two builds V3R1-F2's home of two projects whose remote_match values both name the origin, the longer
# binding, apart from its checkout or its own. Its round 2: _lf_v3r2 builds V3R2-F1's and V3R2-F2's homes and checkouts
# (a tie, and a .felix naming no project). Its round 3 (added on 2026-10-30, still blind, from V3R3-F1's inputs): _lf_v3r3
# builds the home whose only project directory is named q and one LF, and its checkout that remote_match alone names, and
# _lf_v3r3q adds a directory projects/q and a .felix naming it, so that every resolution binds q.

# DIR NOW -> the review's six landings on the branch DIR stands on: NOW - 20 days marked cap (engine/old.sh); NOW - 5
# and - 4 days unmarked (engine/a.sh, engine/b.sh); NOW - 3 days marked sec (docs/x.md); NOW - 2 and - 1 days unmarked
# (docs/y.md, docs/z.md). Then refs/remotes/origin/main names the last; LF_SHA it.
_lf_r2land() {
  local d="$1" n="$2"
  _lf_commit "$d" $((n - 20 * 86400)) $'engine: old\n\nFelix-Lane: cap\n' engine/old.sh || return 1
  _lf_commit "$d" $((n - 5 * 86400)) $'engine: a\n\nNo mark.\n' engine/a.sh || return 1
  _lf_commit "$d" $((n - 4 * 86400)) $'engine: b\n\nNo mark.\n' engine/b.sh || return 1
  _lf_commit "$d" $((n - 3 * 86400)) $'docs: x\n\nFelix-Lane: sec\n' docs/x.md || return 1
  _lf_commit "$d" $((n - 2 * 86400)) $'docs: y\n' docs/y.md || return 1
  _lf_commit "$d" $((n - 86400)) $'docs: z\n' docs/z.md || return 1
  _lf_publish "$d" || { LF_SHA=""; return 1; }
}

# DIR P NOW -> the review's home-apart fixture in DIR (made when missing; it must hold no home or c yet): a home DIR/home
# holding P (root at NOW - 40 days), lanes.tsv (cap ^engine/ 1/2 14, sec ^docs/ 1/2 7) committed at NOW - 29 days and
# lane-next.tsv (cap: cap next item, sec: sec next item) a minute later; a checkout DIR/c bound to P and P's own (_lf_own,
# remote_match o/r), its root at NOW - 30 days, then _lf_r2land's landings. Sets LF_HOME, LF_PROJ, LF_REPO, LF_R2T (the
# lanes.tsv commit), LF_R2A and LF_R2B (cap zero 0 2 and sec short 1 3, the lines felix lane --tsv prints at NOW),
# LF_R2AU and LF_R2BU (the same with next unknown) and LF_R2 (the two, a newline between); status 1 and LF_R2 empty
# when the fixture is not as named.
_lf_r2() {
  local d="$1" p="$2" n="$3" r c a
  LF_R2=""; LF_R2A=""; LF_R2B=""; LF_R2AU=""; LF_R2BU=""; LF_R2T=""
  mkdir -p "$d" && [ ! -e "$d/home" ] && [ ! -e "$d/c" ] || return 1
  _lf_home "$d/home" "$p" $((n - 40 * 86400)) || return 1
  _lf_table "$LF_PROJ" $((n - 29 * 86400)) lanes.tsv $'cap\t^engine/\t1/2\t14\nsec\t^docs/\t1/2\t7\n' || return 1
  LF_R2T="$LF_SHA"
  _lf_table "$LF_PROJ" $((n - 29 * 86400 + 60)) lane-next.tsv $'cap\tcap next item\nsec\tsec next item\n' || return 1
  _lf_checkout "$d/c" "$p" $((n - 30 * 86400)) && _lf_own "$LF_PROJ" "$LF_REPO" o/r && _lf_r2land "$LF_REPO" "$n" || return 1
  a="$((n - 86400)):1 $((n - 2 * 86400)):1 $((n - 3 * 86400)):1 $((n - 4 * 86400)):1 $((n - 5 * 86400)):1"
  [ "$(_lf_spine "$LF_REPO")" = "$a $((n - 20 * 86400)):1 $((n - 30 * 86400)):0" ] || return 1
  r="$(_lf_iso $((n - 86400)))"; c="$(_lf_iso $((n - 29 * 86400)))"
  a="$(_lf_iso $((n - 20 * 86400)))"
  LF_R2A="$(_lf_tsv cap zero 0 2 14 1/2 "$a" 'Felix-Lane: cap' 'cap next item' "$LF_R2T" "$c" "$r" -)"
  LF_R2AU="$(_lf_tsv cap zero 0 2 14 1/2 "$a" 'Felix-Lane: cap' unknown "$LF_R2T" "$c" "$r" -)"
  a="$(_lf_iso $((n - 3 * 86400)))"
  LF_R2B="$(_lf_tsv sec short 1 3 7 1/2 "$a" 'Felix-Lane: sec' 'sec next item' "$LF_R2T" "$c" "$r" -)"
  LF_R2BU="$(_lf_tsv sec short 1 3 7 1/2 "$a" 'Felix-Lane: sec' unknown "$LF_R2T" "$c" "$r" -)"
  LF_R2="$LF_R2A"$'\n'"$LF_R2B"
}

# DIR P NOW -> R3-F1's home-apart fixture in DIR (made when missing; it must hold no home or c yet): _lf_r2's, but with
# lanes.tsv holding sec (^docs/ 1/2 7) before cap (^engine/ 1/2 14), so the first lane is short. A home DIR/home holding
# P (root at NOW - 40 days), lanes.tsv committed at NOW - 29 days and lane-next.tsv (cap: cap next item, sec: sec next
# item) a minute later; a checkout DIR/c bound to P by .felix and P's own (_lf_own, remote_match o/r), its root at NOW -
# 30 days, then _lf_r2land's landings, sec's mark on the one three days back and cap's on the one twenty days back. Sets
# LF_HOME, LF_PROJ, LF_REPO, LF_R3T (the lanes.tsv commit) and LF_R3, the two lines felix lane --tsv prints at NOW, a
# newline between: sec short 1 3, its last lane landing NOW - 3 days, then cap zero 0 2, NOW - 20 days. Status 1 and
# LF_R3 empty when the fixture is not as named.
_lf_r3() {
  local d="$1" p="$2" n="$3" r c a
  LF_R3=""; LF_R3T=""
  mkdir -p "$d" && [ ! -e "$d/home" ] && [ ! -e "$d/c" ] || return 1
  _lf_home "$d/home" "$p" $((n - 40 * 86400)) || return 1
  _lf_table "$LF_PROJ" $((n - 29 * 86400)) lanes.tsv $'sec\t^docs/\t1/2\t7\ncap\t^engine/\t1/2\t14\n' || return 1
  LF_R3T="$LF_SHA"
  _lf_table "$LF_PROJ" $((n - 29 * 86400 + 60)) lane-next.tsv $'cap\tcap next item\nsec\tsec next item\n' || return 1
  _lf_checkout "$d/c" "$p" $((n - 30 * 86400)) && _lf_own "$LF_PROJ" "$LF_REPO" o/r && _lf_r2land "$LF_REPO" "$n" || return 1
  [ -f "$LF_REPO/.felix" ] || return 1
  a="$((n - 86400)):1 $((n - 2 * 86400)):1 $((n - 3 * 86400)):1 $((n - 4 * 86400)):1 $((n - 5 * 86400)):1"
  [ "$(_lf_spine "$LF_REPO")" = "$a $((n - 20 * 86400)):1 $((n - 30 * 86400)):0" ] || return 1
  [ "$(_lf_marks "$LF_REPO" 'refs/remotes/origin/main~2' sec)|$(_lf_marks "$LF_REPO" 'refs/remotes/origin/main~5' cap)" = "1|1" ] || return 1
  r="$(_lf_iso $((n - 86400)))"; c="$(_lf_iso $((n - 29 * 86400)))"
  a="$(_lf_tsv cap zero 0 2 14 1/2 "$(_lf_iso $((n - 20 * 86400)))" 'Felix-Lane: cap' 'cap next item' "$LF_R3T" "$c" "$r" -)"
  LF_R3="$(_lf_tsv sec short 1 3 7 1/2 "$(_lf_iso $((n - 3 * 86400)))" 'Felix-Lane: sec' 'sec next item' "$LF_R3T" "$c" "$r" -)"$'\n'"$a"
}

# Design item 46 (2026-10-30, still blind). REPO HOME P LAYOUT -> REPO, a repository whose project P lives in
# HOME/projects/P, bound or not as LAYOUT names (C2: a valid marker naming a project directory, else the one longest
# remote_match naming the origin, none on a tie; a marker that cannot be opened names nothing). P's project.json is
# written as _lf_match writes it, remote_match o/r. Each layout first removes REPO's .felix, whatever its mode, its origin
# remote and HOME/projects/P2 (P followed by 2), then: felix, .felix holding P and no origin (bound by its marker alone);
# remote, no .felix and origin https://github.com/o/r.git (bound by remote_match alone); none, neither; other, no .felix
# and origin https://github.com/x/y.git, which no remote_match names; tie, as remote, with HOME/projects/P2 beside P
# (CLAUDE.md, and project.json with remote_match o/r), two projects naming the origin equally; nosuch, .felix holding
# nosuch, a project HOME does not hold, no origin; empty, .felix of no bytes, no origin; closed, .felix holding P with
# mode 000, no origin. The origin is removed as a config section only, so refs/remotes/origin/main stays, and is checked
# to name what it named before. LF_BOUND "built" when REPO and HOME stand as LAYOUT names, read back (closed: only when
# the marker cannot be opened, so never when the suite runs as root), else "not built: <what differs>"; status 1 then.
_lf_bind() {
  local r="$1" h="$2" p="$3" l="$4" u="" m="" g o
  LF_BOUND="not built: layout $l"
  [ -n "$r" ] && [ -d "$r" ] && [ -n "$p" ] && [ -d "$h/projects/$p" ] || return 1
  case "$l" in
    (felix|closed) m="$p" ;; (nosuch) m=nosuch ;; (empty|none) ;;
    (remote|tie) u=https://github.com/o/r.git ;; (other) u=https://github.com/x/y.git ;; (*) return 1 ;;
  esac
  o="$( _fx_cd "$r" && _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main )"
  rm -f "$r/.felix"; rm -rf "$h/projects/${p}2"
  ( _fx_cd "$r" || exit 1
    if _lf_g 1700000000 config --get remote.origin.url; then _lf_g 1700000000 config --remove-section remote.origin || exit 1; fi ) >/dev/null 2>&1 || return 1
  _lf_match "$h/projects/$p" o/r || return 1
  case "$l" in (felix|closed|nosuch) printf '%s\n' "$m" > "$r/.felix" || return 1 ;; (empty) : > "$r/.felix" || return 1 ;; esac
  [ -z "$u" ] || _lf_origin "$r" "$u" || return 1
  if [ "$l" = tie ]; then
    mkdir -p "$h/projects/${p}2" && printf '# %s2\n' "$p" > "$h/projects/${p}2/CLAUDE.md" && _lf_match "$h/projects/${p}2" o/r || return 1
  fi
  [ "$l" != closed ] || chmod 000 "$r/.felix" || return 1
  g="$( _fx_cd "$r" && _lf_g 1700000000 config --get remote.origin.url )"
  [ "$g" = "$u" ] || { LF_BOUND="not built: layout $l, origin [$g]"; return 1; }
  g="$( _fx_cd "$r" && _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main )"
  [ "$g" = "$o" ] || { LF_BOUND="not built: layout $l, refs/remotes/origin/main [$g], before [$o]"; return 1; }
  case "$l" in
    (felix|nosuch) [ "$(LC_ALL=C awk '{ printf "%s|", $0 }' "$r/.felix" 2>/dev/null)" = "$m|" ] ;;
    (empty) [ -f "$r/.felix" ] && [ ! -s "$r/.felix" ] ;;
    (closed) [ -f "$r/.felix" ] && ! ( : < "$r/.felix" ) 2>/dev/null ;;
    (*) [ ! -e "$r/.felix" ] && [ ! -L "$r/.felix" ] ;;
  esac || { LF_BOUND="not built: layout $l, the marker"; return 1; }
  [ -n "$(LC_ALL=C awk '/"remote_match":"o\/r"/' "$h/projects/$p/project.json" 2>/dev/null)" ] || { LF_BOUND="not built: layout $l, $p's remote_match"; return 1; }
  if [ "$l" = tie ]; then [ -n "$(LC_ALL=C awk '/"remote_match":"o\/r"/' "$h/projects/${p}2/project.json" 2>/dev/null)" ]
  else [ ! -e "$h/projects/${p}2" ]; fi || { LF_BOUND="not built: layout $l, project ${p}2"; return 1; }
  LF_BOUND=built
}

# The third review's round 1 (2026-10-30, still blind, from V3R1-F2's inputs). DIR LAYOUT NOW -> in DIR (made when
# missing; it must hold no home or c yet) a home DIR/home whose one commit, at NOW - 40 days, holds two projects, each
# with project.json, CLAUDE.md and lanes.tsv: p (remote_match o/R; lanes.tsv cap ^engine/ 1/2 14) and z (remote_match
# github.com/o/R, the longer remote_match naming the origin, so z binds (C2); lanes.tsv zz ^docs/ 1/2 7). LAYOUT apart:
# R is r, and the checkout is DIR/c, its root (README) at NOW - 30 days; self: R is rr, and the home is its own checkout.
# The checkout has no .felix and the origin https://github.com/o/R.git, then two unmarked landings, engine/a.sh at NOW -
# 3 days and docs/b.md at NOW - 2 days, and refs/remotes/origin/main names the last. Sets LF_HOME and LF_REPO (the
# checkout's physical path); status 1 and LF_REPO empty when the fixture is not as named.
_lf_two() {
  local d="$1" l="$2" n="$3" r=r t=30 h c a
  LF_HOME=""; LF_REPO=""
  case "$l" in (apart) ;; (self) r=rr; t=40 ;; (*) return 1 ;; esac
  mkdir -p "$d" && [ ! -e "$d/home" ] && [ ! -e "$d/c" ] && _lf_init "$d/home" || return 1
  mkdir -p "$d/home/projects/p" "$d/home/projects/z" || return 1
  printf '{"name":"p","gate":"true","remote_match":"o/%s"}\n' "$r" > "$d/home/projects/p/project.json" \
    && printf '{"name":"z","gate":"true","remote_match":"github.com/o/%s"}\n' "$r" > "$d/home/projects/z/project.json" \
    && printf '# p\n' > "$d/home/projects/p/CLAUDE.md" && printf '# z\n' > "$d/home/projects/z/CLAUDE.md" \
    && printf 'cap\t^engine/\t1/2\t14\n' > "$d/home/projects/p/lanes.tsv" \
    && printf 'zz\t^docs/\t1/2\t7\n' > "$d/home/projects/z/lanes.tsv" || return 1
  _lf_commit "$d/home" $((n - 40 * 86400)) $'the home of p and z\n' =projects/p/project.json =projects/p/CLAUDE.md \
    =projects/p/lanes.tsv =projects/z/project.json =projects/z/CLAUDE.md =projects/z/lanes.tsv || return 1
  h="$(cd -P -- "$d/home" && pwd -P)"; c="$h"
  if [ "$l" = apart ]; then
    _lf_init "$d/c" && printf 'a checkout of p or z\n' > "$d/c/README" \
      && _lf_commit "$d/c" $((n - 30 * 86400)) $'the root\n' =README || return 1
    c="$(cd -P -- "$d/c" && pwd -P)"
  fi
  _lf_origin "$c" "https://github.com/o/$r.git" && _lf_commit "$c" $((n - 3 * 86400)) $'engine: a\n\nNo mark.\n' engine/a.sh \
    && _lf_commit "$c" $((n - 2 * 86400)) $'docs: b\n\nNo mark.\n' docs/b.md && _lf_publish "$c" || return 1
  [ ! -e "$c/.felix" ] && [ ! -L "$c/.felix" ] || return 1
  a="$( _fx_cd "$h" && _lf_g 1700000000 ls-tree -r --name-only HEAD -- projects )"
  [ "$a" = "projects/p/CLAUDE.md"$'\n'"projects/p/lanes.tsv"$'\n'"projects/p/project.json"$'\n'"projects/z/CLAUDE.md"$'\n'"projects/z/lanes.tsv"$'\n'"projects/z/project.json" ] || return 1
  [ "$(_lf_spine "$c")" = "$((n - 2 * 86400)):1 $((n - 3 * 86400)):1 $((n - t * 86400)):0" ] || return 1
  LF_HOME="$h"; LF_REPO="$c"
}

# The third review's round 2 (2026-10-30, still blind, from V3R2-F1's and V3R2-F2's inputs). DIR NOW -> in DIR (made when
# missing; it must hold none of home, home2, t, n and mk yet) a home DIR/home whose one commit, at NOW - 40 days, holds
# projects p and q, each a project.json whose remote_match is o/r (so the two name a GitHub origin o/r equally, a tie)
# and a CLAUDE.md, and p's lanes.tsv (cap ^engine/ 1/2 14); a home DIR/home2 whose one commit holds p alone, the same;
# and three checkouts, each a root commit (README) at NOW - 30 days that refs/remotes/origin/main names: DIR/t, with no
# .felix and the origin https://github.com/o/r.git; DIR/n, with an untracked .felix holding nope and no origin; DIR/mk,
# with that .felix and that origin. Sets LF_V3H, LF_V3H2, LF_V3T, LF_V3N and LF_V3MK, their physical paths; status 1, and
# those empty, when the layouts are not as named.
_lf_v3r2() {
  local d="$1" n="$2" h p a w
  LF_V3H=""; LF_V3H2=""; LF_V3T=""; LF_V3N=""; LF_V3MK=""
  [ -n "$d" ] && [ -n "$n" ] && mkdir -p "$d" || return 1
  for h in home home2 t n mk; do [ ! -e "$d/$h" ] || return 1; done
  for h in home home2; do
    _lf_init "$d/$h" || return 1
    for p in p q; do
      [ "$h:$p" != home2:q ] || continue
      mkdir -p "$d/$h/projects/$p" && printf '{"name":"%s","gate":"true","remote_match":"o/r"}\n' "$p" > "$d/$h/projects/$p/project.json" \
        && printf '# %s\n' "$p" > "$d/$h/projects/$p/CLAUDE.md" || return 1
    done
    printf 'cap\t^engine/\t1/2\t14\n' > "$d/$h/projects/p/lanes.tsv" \
      && ( _fx_cd "$d/$h" || exit 1; _lf_g $((n - 40 * 86400)) add -- projects ) >/dev/null 2>&1 \
      && _lf_commit "$d/$h" $((n - 40 * 86400)) "the $h of p"$'\n' || return 1
  done
  w="projects/p/CLAUDE.md"$'\n'"projects/p/lanes.tsv"$'\n'"projects/p/project.json"
  a="$( _fx_cd "$d/home" && _lf_g 1700000000 ls-tree -r --name-only HEAD -- projects )"
  [ "$a" = "$w"$'\n'"projects/q/CLAUDE.md"$'\n'"projects/q/project.json" ] && [ "$(ls "$d/home/projects")" = "p"$'\n'"q" ] || return 1
  a="$( _fx_cd "$d/home2" && _lf_g 1700000000 ls-tree -r --name-only HEAD -- projects )"
  [ "$a" = "$w" ] && [ "$(ls "$d/home2/projects")" = p ] || return 1
  for h in t n mk; do
    _lf_init "$d/$h" && printf 'a checkout\n' > "$d/$h/README" && _lf_commit "$d/$h" $((n - 30 * 86400)) $'the root\n' =README \
      && _lf_publish "$d/$h" || return 1
    a="$( _fx_cd "$d/$h" && _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main )"
    [ -n "$a" ] && [ "$a" = "$LF_SHA" ] || return 1
  done
  printf 'nope\n' > "$d/n/.felix" && printf 'nope\n' > "$d/mk/.felix" || return 1
  _lf_origin "$d/t" https://github.com/o/r.git && _lf_origin "$d/mk" https://github.com/o/r.git || return 1
  [ ! -e "$d/t/.felix" ] && [ ! -L "$d/t/.felix" ] || return 1
  [ "$(LC_ALL=C awk '{ printf "%s|", $0 }' "$d/n/.felix" "$d/mk/.felix" 2>/dev/null)" = "nope|nope|" ] || return 1
  [ -z "$( _fx_cd "$d/n" && _lf_g 1700000000 config --get remote.origin.url )" ] || return 1
  a="$( _fx_cd "$d/t" && _lf_g 1700000000 config --get remote.origin.url )|$( _fx_cd "$d/mk" && _lf_g 1700000000 config --get remote.origin.url )"
  [ "$a" = "https://github.com/o/r.git|https://github.com/o/r.git" ] || return 1
  LF_V3H="$(cd -P -- "$d/home" && pwd -P)"; LF_V3H2="$(cd -P -- "$d/home2" && pwd -P)"
  LF_V3N="$(cd -P -- "$d/n" && pwd -P)"; LF_V3MK="$(cd -P -- "$d/mk" && pwd -P)"; LF_V3T="$(cd -P -- "$d/t" && pwd -P)"
  [ -n "$LF_V3H" ] && [ -n "$LF_V3H2" ] && [ -n "$LF_V3N" ] && [ -n "$LF_V3MK" ] && [ -n "$LF_V3T" ]
}

# The third review's round 3 (2026-10-30, still blind, from V3R3-F1's layout (b)). DIR NOW -> in DIR (made when missing;
# it must hold no home or c yet) a home DIR/home whose only project directory is named q and one LF, holding project.json
# ({"name":"q","gate":"true","remote_match":"o/r"}) and CLAUDE.md, committed at NOW - 40 days; and a checkout DIR/c with
# no .felix, its root (README) at NOW - 30 days, which refs/remotes/origin/main names, and the origin
# https://github.com/o/r.git, which that remote_match names (C2). Sets LF_V3RH and LF_V3RC, their physical paths; status
# 1, and those empty, when the layout is not as named, read back: one entry under DIR/home/projects, a directory named q
# and an LF; no DIR/home/projects/q; the two files at the home's HEAD, by name as git stores them; the ref; the origin.
_lf_v3r3() {
  local d="$1" n="$2" q="q"$'\n' e k=0 a
  LF_V3RH=""; LF_V3RC=""
  [ -n "$d" ] && [ -n "$n" ] && mkdir -p "$d" && [ ! -e "$d/home" ] && [ ! -e "$d/c" ] && _lf_init "$d/home" || return 1
  mkdir -p "$d/home/projects/$q" && printf '{"name":"q","gate":"true","remote_match":"o/r"}\n' > "$d/home/projects/$q/project.json" \
    && printf '# q\n' > "$d/home/projects/$q/CLAUDE.md" \
    && _lf_commit "$d/home" $((n - 40 * 86400)) $'the home of q and an LF\n' "=projects/$q/project.json" "=projects/$q/CLAUDE.md" || return 1
  for e in "$d/home/projects"/* "$d/home/projects"/.[!.]* "$d/home/projects"/..?*; do [ ! -e "$e" ] || k=$((k + 1)); done
  [ "$k" = 1 ] && [ -d "$d/home/projects/$q" ] && [ ! -e "$d/home/projects/q" ] || return 1
  ( _fx_cd "$d/home" || exit 1; _lf_g 1700000000 ls-tree -r -z --name-only HEAD -- projects ) > "$d/home.tree" 2>/dev/null || return 1
  printf 'projects/%s/CLAUDE.md\0projects/%s/project.json\0' "$q" "$q" > "$d/home.want" && cmp -s "$d/home.tree" "$d/home.want" || return 1
  _lf_init "$d/c" && printf 'a checkout of q\n' > "$d/c/README" && _lf_commit "$d/c" $((n - 30 * 86400)) $'the root\n' =README \
    && _lf_publish "$d/c" && _lf_origin "$d/c" https://github.com/o/r.git || return 1
  a="$( _fx_cd "$d/c" && _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main )"
  [ -n "$a" ] && [ "$a" = "$LF_SHA" ] && [ ! -e "$d/c/.felix" ] && [ ! -L "$d/c/.felix" ] || return 1
  [ "$( _fx_cd "$d/c" && _lf_g 1700000000 config --get remote.origin.url )" = https://github.com/o/r.git ] || return 1
  LF_V3RH="$(cd -P -- "$d/home" && pwd -P)"; LF_V3RC="$(cd -P -- "$d/c" && pwd -P)"
  [ -n "$LF_V3RH" ] && [ -n "$LF_V3RC" ]
}

# HOME CHECKOUT -> _lf_v3r3's home and checkout, given a directory HOME/projects/q (a CLAUDE.md, no project.json) beside
# q and an LF, and an untracked .felix naming q in CHECKOUT, so that every resolution binds q by its marker (C2: a valid
# marker naming a project directory comes first). LF_V3RQ "built" when they stand so, read back, else "not built"; status
# 1 then.
_lf_v3r3q() {
  local h="$1" c="$2"
  LF_V3RQ="not built: projects/q and a .felix naming q"
  [ -n "$h" ] && [ -n "$c" ] && [ -d "$h/projects/q"$'\n' ] && [ ! -e "$h/projects/q" ] && [ ! -e "$c/.felix" ] || return 1
  mkdir "$h/projects/q" && printf '# q\n' > "$h/projects/q/CLAUDE.md" && printf 'q\n' > "$c/.felix" || return 1
  [ -f "$h/projects/q/CLAUDE.md" ] && [ ! -e "$h/projects/q/project.json" ] && [ -d "$h/projects/q"$'\n' ] || return 1
  [ "$(LC_ALL=C awk '{ printf "%s|", $0 }' "$c/.felix" 2>/dev/null)" = "q|" ] || return 1
  LF_V3RQ=built
}
