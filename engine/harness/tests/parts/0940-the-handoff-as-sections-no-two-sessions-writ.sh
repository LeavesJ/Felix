# ---- §1, §9: the libraries -----------------------------------------------
_ib_build n16
IB_LIBS="inventory.sh inventory-items.sh inventory-gh.sh inventory-orphans.sh inventory-host.sh inventory-view.sh"
_ibcode() { LC_ALL=C awk '!/^[[:space:]]*#/ { f = FILENAME; sub(/.*\//, "", f); print f ":" FNR ":" $0 }' "$@"; }
_ibmissing() { local f m=""; for f in $IB_LIBS; do [ -f "$IBL/$f" ] || m="$m $f"; done; printf '%s' "${m:+missing:$m}"; }
_iblibs() { local f; for f in $IB_LIBS; do [ -f "$IBL/$f" ] && printf '%s\n' "$IBL/$f"; done; }
is  "inventory A109: the six inventory libraries exist and each is under 500 lines" \
    "$(_ibmissing)$(for _ibf in $(_iblibs); do [ "$(LC_ALL=C awk 'END { print NR }' "$_ibf")" -lt 500 ] || printf ' %s is long' "${_ibf##*/}"; done)" ""
is  "inventory RV9: the view's header comment names no landing actor as a reader of the rows (spec section 11 row 19), and the file is there to be read" \
    "$([ -f "$IBL/inventory-view.sh" ] && LC_ALL=C awk 'index(tolower($0), "landing actor") { printf "line %d; ", FNR } END { if (!NR) printf "empty" }' "$IBL/inventory-view.sh" || printf 'missing')" ""
is  "inventory RV9: and its leading comment block, there to be read, says none of landing, lander or step 8" \
    "$([ -f "$IBL/inventory-view.sh" ] && LC_ALL=C awk 'FNR == 1 && /^#!/ { next } /^[[:space:]]*#/ { c++; l = tolower($0); if (index(l, "landing") || index(l, "lander") || index(l, "step 8")) printf "line %d; ", FNR; next } /^[[:space:]]*$/ { next } { exit } END { if (!c) printf "no header comment" }' "$IBL/inventory-view.sh" || printf 'missing')" ""
is  "inventory A110: no inventory library uses a here-document or here-string, jq, python, node or claude" \
    "$(_ibmissing)$(_iblibs | while IFS= read -r _ibf; do _ibcode "$_ibf"; done | LC_ALL=C awk '{ s = $0; gsub(/\$\(\([^)]*\)\)/, "", s)
       if (index(s, "<<")) printf "%s heredoc; ", substr($0, 1, index($0, ":") - 1)
       if (s ~ /(^|[^A-Za-z0-9_.-])(jq|python3?|node)([^A-Za-z0-9_-]|$)/) printf "%s parser; ", substr($0, 1, index($0, ":") - 1)
       if (s ~ /(^|[;&|(`]|then|do|else)[[:space:]]*claude[[:space:]]/) printf "%s claude; ", substr($0, 1, index($0, ":") - 1) }')" ""
is  "inventory A111: the host adapter runs no git" \
    "$(_ibmissing)$([ -f "$IBL/inventory-host.sh" ] && _ibcode "$IBL/inventory-host.sh" | LC_ALL=C awk -F: '{ s = $0; sub(/^[^:]*:[^:]*:/, "", s) } s ~ /(^|[;&|(`{]|then|do|else|\$\()[[:space:]]*(command[[:space:]]+)?git[[:space:]]/ { printf "line %s; ", $2 }')" ""
# Restated 2026-10-18 for the stuck-PR page (step 5), whose spec v2 section 9 says
# to reuse the inventory's JSON flattener _FI_JSON and epoch function _FI_EPOCH
# from lib/inventory-gh.sh. Those are parser code, not the inventory's facts, and
# the page only shows, so the advisory rule this guards still holds. The two page
# libraries may name inventory-gh.sh and nothing else of the inventory: not
# inventory.sh, not felix_inventory, not another inventory- file.
is  "inventory A111: no hook and no other library names the inventory, and felix names felix_inventory only after audit's early arm" \
    "$(_ibmissing)$(for _ibf in "$REAL_HARNESS"/hooks/* "$IBL"/*.sh; do case "${_ibf##*/}" in (inventory*.sh) continue ;; esac
       [ -f "$_ibf" ] && LC_ALL=C awk -v f="${_ibf##*/}" '{ l = $0; if (f == "pr-status.sh" || f == "pr-status-gh.sh") gsub(/inventory-gh\.sh/, "", l) } l ~ /inventory\.sh|inventory-|felix_inventory/ { printf "%s:%d; ", f, FNR; exit }' "$_ibf"; done)$(LC_ALL=C awk '/^[[:space:]]*if \[ "\$\{1:-\}" = "audit" \]/ { a = NR } /felix_inventory/ { if (!a || NR <= a || NR > a + 15) printf "felix:%d; ", NR; n++ } END { if (!n) printf "felix names no felix_inventory" }' "$REAL_HARNESS/felix")" ""
# The governed projects come from the folders under projects/, never as literals
# here. The public snapshot rewrites a literal project name into a phrase of
# several words, and one of those words, "a", is on every line this searches.
_ibnames="felix-home widget"
for _ibd in "$REAL_HARNESS"/../../projects/*/; do [ -d "$_ibd" ] || continue; _ibn="${_ibd%/}"; _ibn="${_ibn##*/}"; [ "$_ibn" = felix ] || _ibnames="$_ibnames $_ibn"; done
is  "inventory A112: the inventory libraries name no project" \
    "$(_ibmissing)$(_iblibs | while IFS= read -r _ibf; do LC_ALL=C awk -v names="$_ibnames" -v f="${_ibf##*/}" 'BEGIN { n = split(tolower(names), w, " ") } { l = tolower($0); for (i = 1; i <= n; i++) if (index(l, w[i])) { printf "%s:%d names %s; ", f, FNR, w[i]; next } }' "$_ibf"; done)" ""
_ibx="$(grep -E 'bad substitution|syntax error|unbound variable|command not found|invalid option|not a valid identifier|division by 0|awk: ' "$IB"/runs/*.err | LC_ALL=C awk 'NR <= 3' | tr '\n' ';')"
is  "inventory: no run of this section wrote a shell or awk error to stderr" "$_ibx" ""

printf '\nthe handoff, as sections: no two sessions write the same path\n'
# HANDOFF.md was one slot and one counter every session shared: write your
# section at the top with the next id, archive the one it replaces. With ten
# sessions at once, four pull requests claimed one id inside an hour, and each
# landing after the first was a hand re-cut that could re-archive or drop a
# section. A session now adds its section as a file of its own under
# docs/handoff/pending/, and the id, the archive move, the index row and the
# marker are derived from the order the files landed on main (lib/handoff.sh).
# The fixture is a checkout with a remote-tracking main moved by hand, and a
# landing is a squash onto main, which is what the merge boundary does.
HX="$TMP/handoff"; mkdir -p "$HX/docs/handoff"
( _fx_cd "$HX" && git init -q -b main && git config user.name t && git config user.email t@example.invalid )
printf 'widget\n' > "$HX/.felix"
cat > "$HX/HANDOFF.md" <<'EOF'
# Handoff

Write your section with felix handoff --section; the fold gives it the next id
(after 0bb comes 0bc).

---

## 0. Standing

Unchanged; read docs/handoff/0.md.

---

## Current state

### 0bb. the session before

What it did.

---

## Index of earlier sections

| § | Section |
|---|---|
| [0](docs/handoff/0.md) | Standing |
| [0ba](docs/handoff/0ba.md) | the one before that |
| [1](docs/handoff/1.md) | the oldest |
EOF
printf '## 0. Standing\n\nThe standing decision.\n\n' > "$HX/docs/handoff/0.md"
printf '### 0ba. the one before that\n\nIts body.\n' > "$HX/docs/handoff/0ba.md"
printf '## 1. the oldest\n\nIts body.\n\n' > "$HX/docs/handoff/1.md"
_fx_git "$HX" add -A && _fx_git "$HX" commit -q -m base && _fx_git "$HX" update-ref refs/remotes/origin/main HEAD
_hx()     { ( cd "$HX" && . "$REAL_HARNESS/lib/handoff.sh" && "$@" ); }
_hx_chk() { _hx felix_handoff_check "$HX" "${1:-refs/remotes/origin/main}"; }
_hx_on()  { _fx_git "$HX" checkout -q -B "$1" "${2:-refs/remotes/origin/main}"; }
_hx_commit() { _fx_git "$HX" add -A && _fx_git "$HX" commit -q -m "$1"; }
# A landing: squash the branch onto the remote-tracking main and move it.
_hx_land() {
  _fx_git "$HX" checkout -q --detach refs/remotes/origin/main \
    && _fx_git "$HX" merge -q --squash "$1" >/dev/null 2>&1 \
    && { git -C "$HX" diff --cached --quiet || _fx_git "$HX" commit -q -m "land $1"; } \
    && _fx_git "$HX" update-ref refs/remotes/origin/main HEAD
}
_hx_base="$(git -C "$HX" rev-parse HEAD)"

is  "the id after 0bv is 0bw, after 0bz 0ca, after 0z 0aa, and after 0zz 0aaa" \
    "$(for _i in 0bv 0bz 0z 0zz; do _hx felix_handoff_next_id "$_i"; done | tr '\n' ' ')" "0bw 0ca 0aa 0aaa "
_hx_chk >/dev/null; is "the handoff a fold could have written reads clean" "$?" "0"

# Session A writes its section, cut under the old rule with an id in the
# heading, and writes it again: one file, the id dropped.
_hx_on s/a
printf '### 0zz. what A did\n\nA ran first.\n\n' > "$TMP/ho-a.md"
_hxa="$(cd "$HX" && "$FELIX" handoff --section "$TMP/ho-a.md" 2>"$TMP/ho-a.err" | sed -n 's/^wrote //p')"
grep -qE '^docs/handoff/pending/[0-9]{8}T[0-9]{6}Z-s-a\.md$' <<<"$_hxa" \
  && ok  "felix handoff --section writes the section to docs/handoff/pending/<UTC time>-<branch>.md" \
  || bad "felix handoff --section writes the section to docs/handoff/pending/<UTC time>-<branch>.md" "wrote [$_hxa]"
is  "and drops the id its heading carried, since only the fold gives ids" "$(head -1 "$HX/$_hxa" 2>/dev/null)" "### what A did"
has "and says it dropped it" "$(cat "$TMP/ho-a.err")" "dropped the id 0zz"
printf '### what A did\n\nA ran first, and said so twice.\n' > "$TMP/ho-a.md"
_hxa2="$(_hx felix_handoff_section "$HX" "$TMP/ho-a.md" refs/remotes/origin/main)"
is  "a second --section on the same branch rewrites that file and makes no other" \
    "$_hxa2:$(ls "$HX/docs/handoff/pending" | wc -l | tr -d ' ')" "$_hxa:1"
# Its own file is the whole name, not the tail: branch x/s-a's ends in -s-a too.
printf '### x/s-a wrote this\n' > "$HX/docs/handoff/pending/20991231T235959Z-x-s-a.md"
_hx felix_handoff_section "$HX" "$TMP/ho-a.md" refs/remotes/origin/main >/dev/null
is  "and leaves a file named for a branch whose name only ends like this one's" \
    "$(head -1 "$HX/docs/handoff/pending/20991231T235959Z-x-s-a.md")" "### x/s-a wrote this"
rm -f "$HX/docs/handoff/pending/20991231T235959Z-x-s-a.md"
_hx_commit "A's section"
_hx_chk >/dev/null; is "a branch that only adds a pending section reads clean" "$?" "0"

# Session B, cut from the same main before A lands.
_hx_on s/b
printf '### what B did\n\nB ran second and landed first.\n' > "$TMP/ho-b.md"
_hxb="$(_hx felix_handoff_section "$HX" "$TMP/ho-b.md" refs/remotes/origin/main)"
_hx_commit "B's section"
is  "two sessions' handoff branches share no path" \
    "$(LC_ALL=C comm -12 <(git -C "$HX" diff --name-only "$_hx_base" s/a | sort) <(git -C "$HX" diff --name-only "$_hx_base" s/b | sort))" ""
_hx_land s/b; _hxl1=$?; _hx_land s/a; _hxl2=$?
is  "so both land, the second on top of the first, without a conflict" "$_hxl1:$_hxl2" "0:0"
_hx_chk >/dev/null; is "main with two sections waiting reads clean" "$?" "0"

# The fold. B landed first and so takes the next id, though A's file sorts
# first by name and was written first: the order is main's, not a claim.
_hx_on s/rot
_hxr="$(cd "$HX" && "$FELIX" handoff --rotate 2>&1)"; _hxrc=$?
is  "felix handoff --rotate folds and reads its work back clean" "$_hxrc" "0"
has "and says so" "$_hxr" "reads it back clean"
is  "the section that landed first takes the next id and is archived, as it would have been had it been folded alone" \
    "$(head -1 "$HX/docs/handoff/0bc.md" 2>/dev/null)" "### 0bc. what B did"
has "the one that landed last is current, with the id after it" "$(cat "$HX/HANDOFF.md")" "### 0bd. what A did"
is  "the section it replaced is archived exactly as it stood, its trailing blank line dropped" \
    "$(cat "$HX/docs/handoff/0bb.md" 2>/dev/null; printf x)" "$(printf '### 0bb. the session before\n\nWhat it did.\nx')"
has "the marker moves on to the id after the current one" "$(cat "$HX/HANDOFF.md")" "(after 0bd comes 0be)"
is  "the rows go in newest first, above the newest numbered row and below the standing one" \
    "$(_hx felix_handoff_rows "$HX/HANDOFF.md" | cut -f1 | tr '\n' ' ')" "0 0bc 0bb 0ba 1 "
is  "and the folded files are gone" "$(ls "$HX/docs/handoff/pending" 2>/dev/null | wc -l | tr -d ' ')" "0"
_hx_commit "fold"
_hxt="$(git -C "$HX" rev-parse HEAD^{tree})"
_hx_on s/rot2
_hx felix_handoff_rotate "$HX" refs/remotes/origin/main >/dev/null; _hx_commit "fold again"
is  "a second fold of the same main writes the same tree" "$(git -C "$HX" rev-parse HEAD^{tree})" "$_hxt"
_hx_land s/rot; _hxl1=$?; _hx_land s/rot2; _hxl2=$?
is  "so two sessions folding at once both land, and the second changes nothing" \
    "$_hxl1:$_hxl2:$(git -C "$HX" rev-parse HEAD^{tree})" "0:0:$_hxt"

# The old rule, done perfectly by hand: the next id, the archive, the row and
# the marker all correct. It is refused, because it is the shared slot that
# collided, whoever does it well.
_hx_on s/hand
cp "$HX/HANDOFF.md" "$TMP/ho-h.md"
awk '/^### 0bd\. /{ print "### 0be. written in by hand"; print ""; print "Mine."; print ""; skip = 1; next }
     skip && /^---$/ { skip = 0 } !skip { print }' "$TMP/ho-h.md" \
  | sed 's/(after 0bd comes 0be)/(after 0be comes 0bf)/' \
  | awk '/^\| \[0bc\]/ { print "| [0bd](docs/handoff/0bd.md) | what A did |" } { print }' > "$HX/HANDOFF.md"
_hx _felix_handoff_block "$TMP/ho-h.md" 0bd > "$HX/docs/handoff/0bd.md"
_hx_commit "by hand"
_hxc="$(_hx_chk)"; _hxcr=$?
is  "a section written into HANDOFF.md by hand is refused, however correct its id" "$_hxcr" "1"
has "and the refusal says how to add a section instead" "$_hxc" "felix handoff --section"
( cd "$HX" && "$REAL_HARNESS/bin/handoff-check" >/dev/null 2>&1 ); is "handoff-check exits 1 on it, which fails the gate" "$?" "1"
# And the shape a blind qualification control found first: a section written
# in above the current one, the marker, rows and archive all left alone.
_hx_on s/beside
awk '/^### 0bd\. /{ print "### 0be. written in beside it"; print ""; print "Mine."; print "" } { print }' \
  "$HX/HANDOFF.md" > "$TMP/ho-bs.md" && cp "$TMP/ho-bs.md" "$HX/HANDOFF.md"; _hx_commit "beside"
has "a section written in beside the current one, the marker left alone, is refused too" \
    "$(_hx_chk)" "section 0be sits in HANDOFF.md beside the current one"
# Two ways a hand rotation loses a section without a sign, both seen on
# 2026-09-24: another section put in place under the current id, and a
# rotation cut from an older main that archives its own stale copy.
_hx_on s/inplace
sed 's/^A ran first, and said so twice\.$/A ran first, and said so twice; corrected in place./' "$HX/HANDOFF.md" > "$TMP/ho-ip.md" \
  && cp "$TMP/ho-ip.md" "$HX/HANDOFF.md"; _hx_commit "in place"
_hx_chk >/dev/null; is "editing the current section in place, its heading kept, reads clean" "$?" "0"
_hx_on s/samid
sed 's/^### 0bd\. what A did$/### 0bd. what another session did/' "$HX/HANDOFF.md" > "$TMP/ho-si.md" \
  && cp "$TMP/ho-si.md" "$HX/HANDOFF.md"; _hx_commit "same id"
has "another section put in place under the current id is refused, since the one it replaced is lost" \
    "$(_hx_chk)" "headed differently than on the merge-base"
_hx_on s/stalehand s/hand
printf '### 0bd. what A did\n\nA ran first.\n' > "$HX/docs/handoff/0bd.md"; _hx_commit "stale"
has "and a hand rotation that archives a stale copy of the section says what it drops" \
    "$(_hx_chk)" "docs/handoff/0bd.md is not the section the merge-base holds as current"

_hx_on s/rewrite
printf '\nAn afterthought.\n' >> "$HX/docs/handoff/0ba.md"; _hx_commit "rewrite"
has "rewriting an archived section is refused" "$(_hx_chk)" "docs/handoff/0ba.md was rewritten"
_hx_on s/gone
_fx_git "$HX" rm -q docs/handoff/0bc.md; _hx_commit "gone"
has "and so is removing one" "$(_hx_chk)" "docs/handoff/0bc.md was archived and is gone"

# Two more sessions land; C lands before D.
for _s in c d; do
  _hx_on "s/$_s"; printf '### what %s did\n\nIts body.\n' "$_s" > "$TMP/ho-$_s.md"
  _hx felix_handoff_section "$HX" "$TMP/ho-$_s.md" refs/remotes/origin/main >/dev/null; _hx_commit "$_s"; _hx_land "s/$_s"
done
_hxc_path="$(git -C "$HX" ls-tree --name-only refs/remotes/origin/main docs/handoff/pending/ | grep -- '-s-c\.md$')"
_hxd_path="$(git -C "$HX" ls-tree --name-only refs/remotes/origin/main docs/handoff/pending/ | grep -- '-s-d\.md$')"
_hx_on s/drop
_fx_git "$HX" rm -q "$_hxc_path"; _hx_commit "drop"
has "removing a pending section without folding it is refused, since that drops it" "$(_hx_chk)" "which drops it"
_hx_on s/skip
printf '%s\n' "$_hxd_path" > "$TMP/ho-order"
_hx felix_handoff_fold "$HX" "$TMP/ho-order" >/dev/null; _hx_commit "skip"
has "folding a section ahead of one that landed before it is refused" "$(_hx_chk)" "not the 1 that landed first"

# A fold that main moved past before it landed: E lands while the fold of C
# and D waits. The fold is still exactly C and D, the oldest two, so the
# merge result reads clean and E waits for the next fold.
_hx_on s/stale
_hx felix_handoff_rotate "$HX" refs/remotes/origin/main >/dev/null; _hx_commit "fold c d"
_hx_on s/e; printf '### what e did\n\nIts body.\n' > "$TMP/ho-e.md"
_hx felix_handoff_section "$HX" "$TMP/ho-e.md" refs/remotes/origin/main >/dev/null; _hx_commit e; _hx_land s/e
_fx_git "$HX" checkout -q --detach refs/remotes/origin/main
_fx_git "$HX" merge -q --no-edit s/stale >/dev/null 2>&1; _hxm=$?
_hx_chk >/dev/null; _hxcr=$?
is  "a fold that main moved past merges and reads clean, and the section that landed after it waits" \
    "$_hxm:$_hxcr:$(ls "$HX/docs/handoff/pending" | grep -c -- '-s-e\.md$')" "0:0:1"
_hx felix_handoff_rotate "$HX" HEAD >/dev/null
has "and the next fold gives it the id after theirs" "$(cat "$HX/HANDOFF.md")" "### 0bg. what e did"
_fx_git "$HX" checkout -q -f --detach HEAD; _fx_git "$HX" clean -qfd

# The fold's own refusals: nothing written when one step would fail.
_hxfx="$TMP/handoff-fold"; mkdir -p "$_hxfx"
_fx_git "$HX" archive -o "$TMP/handoff-fold.tar" refs/remotes/origin/main && tar -x -f "$TMP/handoff-fold.tar" -C "$_hxfx"
rm -f "$TMP/handoff-fold.tar"
printf '### 0bf. something else\n' > "$_hxfx/docs/handoff/0bf.md"
cp "$_hxfx/HANDOFF.md" "$TMP/ho-keep.md"
( cd "$_hxfx" && . "$REAL_HARNESS/lib/handoff.sh" && felix_handoff_pending_order "$_hxfx" > "$TMP/ho-o2" \
  && felix_handoff_fold "$_hxfx" "$TMP/ho-o2" ) > "$TMP/ho-fold.out"; _hxfr=$?
is  "the fold refuses to write over an archive that holds something else, and writes nothing" \
    "$_hxfr:$(cmp -s "$_hxfx/HANDOFF.md" "$TMP/ho-keep.md" && echo same):$(ls "$_hxfx/docs/handoff/pending" | wc -l | tr -d ' ')" "1:same:3"
has "and says an archived section is never rewritten" "$(cat "$TMP/ho-fold.out")" "never rewritten"

# The tree-local half, on the working tree alone.
_hx_on s/local
printf '### 0bz. an id\n\nbody\n' > "$HX/docs/handoff/pending/20260101T000000Z-x.md"
has "a pending section that carries an id is refused" "$(_hx_chk)" "carries an id"
_fx_git "$HX" checkout -q -f s/local; _fx_git "$HX" clean -qfd
sed 's/^### 0bd\. /### 0bx. /' "$HX/HANDOFF.md" > "$TMP/ho-m.md"; cp "$TMP/ho-m.md" "$HX/HANDOFF.md"
has "a current section the marker does not name is refused" "$(_hx_chk)" "is not headed"
_fx_git "$HX" checkout -q -f s/local
mkdir -p "$TMP/ho-none"; ( _fx_cd "$TMP/ho-none" && git init -q )
( cd "$TMP/ho-none" && "$REAL_HARNESS/bin/handoff-check" >/dev/null 2>&1 ); is "handoff-check cannot examine a checkout with no HANDOFF.md, and says 2, never 0" "$?" "2"
( cd "$HX" && "$REAL_HARNESS/bin/handoff-check" >/dev/null 2>&1 ); is "and exits 0 on a clean one" "$?" "0"
# Called by a path relative to a subdirectory, as `cd docs &&
# ../engine/harness/bin/handoff-check` does. dirname "$0" is relative to where
# it was called, so read after the move to the top it names a directory that is
# not there, the library never loads, and the run ends 127. The harness is
# reached through a link beside the fixture, so the same relative path read
# from the top names a directory one level too high and cannot pass by chance.
ln -s "$REAL_HARNESS" "$TMP/hxh"
( cd "$HX/docs" && ../../hxh/bin/handoff-check >/dev/null 2>&1 )
is  "and exits 0 on it called by a relative path from a subdirectory, finding its library from where it was called" "$?" "0"

