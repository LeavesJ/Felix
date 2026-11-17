# >>> trust-merge-driver
printf '\ntrust plane step 3, S6.6: the merges the change readers take ignore the checkout config and attributes (blind)\n'
# Blind, written on 2026-11-08 from .felix/memory/felix/audits/2026-11-08-trust-plane-step3/checkout-merge-driver/spec.md
# and the finding beside it (README.md), before the fix. Not read: drv-case.sh, drv2-case.sh and probe-plain-git.sh in
# that folder, the earlier probe. Read: felix_added_lines, felix_changed_paths and _felix_merge_refs in lib/resolve.sh,
# for their arguments only; tests/run and parts 0002, 0460, 2070, 2176 and 2177 for the conventions.
#
# Scope: the spec's "What must be observable" list at the reader level. Each case calls felix_added_lines or
# felix_changed_paths with base main, from a subshell that stands in the fixture's checkout (_fx_cd) and sources
# $FROOT/harness/lib/resolve.sh, as part 0460 does.
#
# The fixture of the finding: R holds notes/f (eight lines), a/g and a/h. main moves after R by changing notes/f's
# last line; the candidate, cut from R and checked out on cand, puts a credential-shaped line after notes/f's first
# line, far enough from main's change that git's own merge is clean. The line is put together at run time from two
# halves, so this file holds no credential the secret scan reads (lessons.md 2026-11-05; part 2070 does the same). The
# driver is tmdkeep, the command true: it keeps main's side and exits 0. Every repository is under $TMP/tmd, and every
# git call into one goes through _fx_git or _fx_cd.
#
# Readings, where the spec leaves room:
# - "Holds the line" is the added lines holding +<line> at least once; "holds F" is notes/f among the changed paths.
#   The driver cases assert nothing else of the output, not even the exit status.
# - Global config is three cases: the driver in the file GIT_CONFIG_GLOBAL names, with the attribute in the checkout's
#   info/attributes (the checkout case with the driver moved); the driver and a core.attributesFile both in that file,
#   with nothing in the checkout; and the driver and attr.tree (naming the candidate, whose .gitattributes names the
#   driver) in that file. The third was added after a check: a throwaway merge in a scratch git directory that cleared
#   everything rule 1 lists except GIT_CONFIG_GLOBAL passed the other two, since -c core.attributesFile=/dev/null alone
#   stops the second, and failed the third. GIT_CONFIG_GLOBAL is set for the one subshell that runs the reader.
# - The recording driver's command writes $TMP/tmd/rec.marker and exits 0. The marker is removed before each reader
#   runs, and each reader is asked on its own.
# - Fallback: TMPDIR is a mode-555 directory, for the reader's subshell only; skipped where this user writes through a
#   mode (root). "At least what the three-dot diff returns" is every line of `git diff main...HEAD`'s names (changed
#   paths) and of its + lines without +++ (added lines) appearing in the reader's output. Two fixtures: the checkout
#   driver's, where a fallback that merged in the checkout would drop the line; and a stacked one, where the merge and
#   three-dot differ (main already holds the candidate's a/g change and gained main/only of its own), so only a real
#   fallback to three-dot holds a/g. Both fail on unfixed code by construction: today's readers need no TMPDIR, so
#   they merge in the checkout as before.
# - Byte-identical: the readers' whole output and exit status, for the no-driver control fixture and for the stacked
#   fixture (the merge route, which neither three-dot nor two-dot gives), pinned to literals today's code prints.
#
# Not covered:
# - The merge boundary (the spec's last bullet: felix merge refusing the credential form and the path form, and
#   merging an honest candidate). No merge fixture is cheap to reuse here: 2176's needs receipts, an entry and a gh
#   stub. Left for a part that builds one.
# - Parts of rule 1 the list does not name: the system config file and GIT_ATTR_NOSYSTEM, merge settings other than a
#   driver (merge.renames, merge.conflictStyle), and that the merge is named by commit ids and not by refs.
# - The spec's open items: other readers in the checkout, the built-in binary driver, lib/pr-status.sh, bin/secret-scan.
TMD="$TMP/tmd"; rm -rf "${TMD:?}"; mkdir -p "$TMD"
_tmd_cred="$(printf 'aws_access_key_id = %s%s' AKIA TMDQ3V8N2K7XW4PJ)"
_tmd_git() { _fx_git "$1" -c core.hooksPath=/dev/null -c commit.gpgsign=false "${@:2}"; }
_tmd_commit() { _tmd_git "$1" add -A >/dev/null 2>&1; _tmd_git "$1" commit -qm "$2" >/dev/null 2>&1; }
_tmd_init() {   # DIR: a repository on main whose one commit R holds notes/f, a/g and a/h
  mkdir -p "$1/notes" "$1/a"
  ( _fx_cd "$1" && git init -q -b main && git config user.name t && git config user.email t@example.invalid ) >/dev/null 2>&1
  mkdir -p "$1/.git/info"
  printf '%s\n' alpha bravo charlie delta echo foxtrot golf hotel > "$1/notes/f"
  printf '%s\n' g1 g2 > "$1/a/g"; printf '%s\n' h1 h2 > "$1/a/h"
  _tmd_commit "$1" R
}
_tmd_finding() {   # DIR [ATTR]: the finding's fixture, with ATTR as the candidate's own .gitattributes; cand checked out
  _tmd_init "$1"
  _tmd_git "$1" checkout -q -b cand >/dev/null 2>&1
  printf '%s\n' alpha "$_tmd_cred" bravo charlie delta echo foxtrot golf hotel > "$1/notes/f"
  [ -z "${2:-}" ] || printf '%s\n' "$2" > "$1/.gitattributes"
  _tmd_commit "$1" candidate
  _tmd_git "$1" checkout -q main >/dev/null 2>&1
  printf '%s\n' alpha bravo charlie delta echo foxtrot golf 'hotel on main' > "$1/notes/f"
  _tmd_commit "$1" "main moves"
  _tmd_git "$1" checkout -q cand >/dev/null 2>&1
}
_tmd_read() (   # DIR READER [NAME=VALUE...]: READER's output over DIR with base main, then a line rc N
  for _tmd_a in "${@:3}"; do export "$_tmd_a"; done
  _fx_cd "$1" || exit 1
  . "$FROOT/harness/lib/resolve.sh" 2>/dev/null
  "$2" "$PWD" main 2>/dev/null
  printf 'rc %s\n' "$?"
)
_tmd_plain() (   # DIR [NAME=VALUE...]: plain git merge-tree --write-tree OURS THEIRS in DIR -> rc N|whose notes/f|line K
                 # OURS and THEIRS are TMD_OURS and TMD_THEIRS when given among the assignments, else main and HEAD
  for _tmd_a in "${@:2}"; do export "$_tmd_a"; done
  o="${TMD_OURS:-main}"; h="${TMD_THEIRS:-HEAD}"
  t="$(_fx_git "$1" merge-tree --write-tree "$o" "$h" 2>/dev/null)"; rc=$?
  t="${t%%$'\n'*}"
  b="$(_fx_git "$1" rev-parse -q --verify "$t:notes/f" 2>/dev/null)"
  m="$(_fx_git "$1" rev-parse -q --verify "$o:notes/f" 2>/dev/null)"
  n="$(_fx_git "$1" cat-file blob "${b:-none}" 2>/dev/null | LC_ALL=C grep -cxF -- "$_tmd_cred")"
  if [ -n "$b" ] && [ "$b" = "$m" ]; then w="main's"; else w="not main's"; fi
  printf 'rc %s|%s notes/f|line %s' "$rc" "$w" "$n"
)
_tmd_flat() { printf '%s\n' "$1" | LC_ALL=C awk '{ printf "%s%s", s, $0; s = "|" }'; }
_tmd_held() {   # OUTPUT LINE -> held, or missing from [OUTPUT]
  if [ "$(printf '%s\n' "$1" | LC_ALL=C grep -cxF -- "$2")" -gt 0 ] 2>/dev/null; then printf 'held'
  else printf 'missing from [%s]' "$(_tmd_flat "$1")"; fi
}
_tmd_body() { printf '%s\n' "$1" | sed '$d'; }   # a _tmd_read output without its rc line
_tmd_3paths() { _fx_git "$1" diff --name-only --no-renames main...HEAD 2>/dev/null; }
_tmd_3lines() {
  _fx_git "$1" diff --no-ext-diff --no-textconv --no-color main...HEAD 2>/dev/null | LC_ALL=C grep '^+' | LC_ALL=C grep -v '^+++'
}
_tmd_missing() {   # WANT GOT -> the non-empty lines of WANT that GOT lacks, joined by |, or none
  printf '%s\n' "$1" > "$TMD/want"; printf '%s\n' "$2" > "$TMD/got"
  LC_ALL=C awk 'FILENAME == ARGV[1] { a[$0] = 1; next } $0 != "" && !($0 in a) { printf "%s%s", s, $0; s = "|"; m = 1 }
                END { if (!m) printf "none" }' "$TMD/got" "$TMD/want"
}
_tmd_marker() { if [ -e "$TMD/rec.marker" ]; then printf 'marker written'; else printf 'no marker'; fi; }

# ---------------------------------------------------------------- control ---
_tmd_finding "$TMD/ctl"
_tmd_R="$(_tmd_git "$TMD/ctl" rev-list --max-parents=0 main 2>/dev/null)"
is  "tmd: (fixture control) with no driver, main has moved since the candidate's base R, plain git merge-tree in the checkout exits 0 with the credential line in its notes/f, and three-dot names notes/f and adds the line" \
    "$(if [ -n "$_tmd_R" ] && [ "$(_tmd_git "$TMD/ctl" merge-base main cand 2>/dev/null)" = "$_tmd_R" ] && [ "$(_tmd_git "$TMD/ctl" rev-parse main 2>/dev/null)" != "$_tmd_R" ]; then printf 'base R, main moved'; else printf 'not the finding'; fi)|$(_tmd_plain "$TMD/ctl")|$(_tmd_flat "$(_tmd_3paths "$TMD/ctl")")|$(_tmd_flat "$(_tmd_3lines "$TMD/ctl")")" \
    "base R, main moved|rc 0|not main's notes/f|line 1|notes/f|+$_tmd_cred"
_tmd_al="$(_tmd_read "$TMD/ctl" felix_added_lines)"; _tmd_cp="$(_tmd_read "$TMD/ctl" felix_changed_paths)"
is  "tmd: control: with no driver, the added lines of a candidate that puts a credential-shaped line into notes/f hold that line" \
    "$(_tmd_held "$_tmd_al" "+$_tmd_cred")" "held"
is  "tmd: control: with no driver, the changed paths hold notes/f" \
    "$(_tmd_held "$_tmd_cp" notes/f)" "held"

# ------------------------------------------------------ the checkout's driver ---
_tmd_finding "$TMD/drv"
_tmd_git "$TMD/drv" config merge.tmdkeep.driver true >/dev/null 2>&1
printf 'notes/f merge=tmdkeep\n' > "$TMD/drv/.git/info/attributes"
is  "tmd: (fixture control) the checkout's driver: with merge.tmdkeep.driver=true in the checkout's .git/config and notes/f merge=tmdkeep in its .git/info/attributes, plain git merge-tree in the checkout exits 0 and keeps main's notes/f, without the line" \
    "$(_tmd_plain "$TMD/drv")" "rc 0|main's notes/f|line 0"
is  "tmd: the checkout's driver: with the driver in the checkout's config and attributes, the added lines still hold the credential line" \
    "$(_tmd_held "$(_tmd_read "$TMD/drv" felix_added_lines)" "+$_tmd_cred")" "held"
is  "tmd: the checkout's driver: with the driver in the checkout's config and attributes, the changed paths still hold notes/f" \
    "$(_tmd_held "$(_tmd_read "$TMD/drv" felix_changed_paths)" notes/f)" "held"

# ------------------------- the candidate's attributes and the checkout's config ---
_tmd_finding "$TMD/attr" 'notes/f merge=tmdkeep'
_tmd_git "$TMD/attr" config merge.tmdkeep.driver true >/dev/null 2>&1
is  "tmd: (fixture control) the candidate's attributes: the candidate's own .gitattributes reads notes/f merge=tmdkeep, the checkout has no info/attributes, and with the driver in the checkout's config plain git merge-tree in the checkout exits 0 and keeps main's notes/f" \
    "$(_fx_git "$TMD/attr" show cand:.gitattributes 2>&1)|$([ -e "$TMD/attr/.git/info/attributes" ] && printf 'info/attributes' || printf 'no info/attributes')|$(_tmd_plain "$TMD/attr")" \
    "notes/f merge=tmdkeep|no info/attributes|rc 0|main's notes/f|line 0"
is  "tmd: the candidate's attributes: with notes/f merge=tmdkeep in the candidate's .gitattributes and the driver in the checkout's config, the added lines still hold the credential line" \
    "$(_tmd_held "$(_tmd_read "$TMD/attr" felix_added_lines)" "+$_tmd_cred")" "held"
is  "tmd: the candidate's attributes: with notes/f merge=tmdkeep in the candidate's .gitattributes and the driver in the checkout's config, the changed paths still hold notes/f" \
    "$(_tmd_held "$(_tmd_read "$TMD/attr" felix_changed_paths)" notes/f)" "held"

# ------------------------------------------------------------- global config ---
printf '[merge "tmdkeep"]\n\tdriver = true\n' > "$TMD/global-a.cfg"
_tmd_finding "$TMD/glba"
printf 'notes/f merge=tmdkeep\n' > "$TMD/glba/.git/info/attributes"
is  "tmd: (fixture control) global config, attribute in the checkout: the checkout's config defines no tmdkeep driver, plain git merge-tree keeps the line without the global file, and keeps main's notes/f with GIT_CONFIG_GLOBAL naming a file that defines it" \
    "$(_fx_git "$TMD/glba" config --local --get merge.tmdkeep.driver >/dev/null 2>&1; printf 'local %s' "$?")|$(_tmd_plain "$TMD/glba")|$(_tmd_plain "$TMD/glba" GIT_CONFIG_GLOBAL="$TMD/global-a.cfg")" \
    "local 1|rc 0|not main's notes/f|line 1|rc 0|main's notes/f|line 0"
is  "tmd: global config: with the driver in the file GIT_CONFIG_GLOBAL names and notes/f merge=tmdkeep in the checkout's info/attributes, the added lines still hold the credential line" \
    "$(_tmd_held "$(_tmd_read "$TMD/glba" felix_added_lines GIT_CONFIG_GLOBAL="$TMD/global-a.cfg")" "+$_tmd_cred")" "held"
is  "tmd: global config: with the driver in the file GIT_CONFIG_GLOBAL names and notes/f merge=tmdkeep in the checkout's info/attributes, the changed paths still hold notes/f" \
    "$(_tmd_held "$(_tmd_read "$TMD/glba" felix_changed_paths GIT_CONFIG_GLOBAL="$TMD/global-a.cfg")" notes/f)" "held"

printf 'notes/f merge=tmdkeep\n' > "$TMD/global-b.attr"
printf '[merge "tmdkeep"]\n\tdriver = true\n[core]\n\tattributesFile = "%s"\n' "$TMD/global-b.attr" > "$TMD/global-b.cfg"
_tmd_finding "$TMD/glbb"
is  "tmd: (fixture control) global config alone: the checkout has no info/attributes and the candidate no .gitattributes, plain git merge-tree keeps the line without the global file, and keeps main's notes/f with GIT_CONFIG_GLOBAL naming a file that defines the driver and a core.attributesFile naming it for notes/f" \
    "$([ -e "$TMD/glbb/.git/info/attributes" ] && printf 'info/attributes' || printf 'no info/attributes')|$(_fx_git "$TMD/glbb" cat-file -e cand:.gitattributes >/dev/null 2>&1 && printf '.gitattributes' || printf 'no .gitattributes')|$(_tmd_plain "$TMD/glbb")|$(_tmd_plain "$TMD/glbb" GIT_CONFIG_GLOBAL="$TMD/global-b.cfg")" \
    "no info/attributes|no .gitattributes|rc 0|not main's notes/f|line 1|rc 0|main's notes/f|line 0"
is  "tmd: global config alone: with the driver and a core.attributesFile naming it both in the file GIT_CONFIG_GLOBAL names, the added lines still hold the credential line" \
    "$(_tmd_held "$(_tmd_read "$TMD/glbb" felix_added_lines GIT_CONFIG_GLOBAL="$TMD/global-b.cfg")" "+$_tmd_cred")" "held"
is  "tmd: global config alone: with the driver and a core.attributesFile naming it both in the file GIT_CONFIG_GLOBAL names, the changed paths still hold notes/f" \
    "$(_tmd_held "$(_tmd_read "$TMD/glbb" felix_changed_paths GIT_CONFIG_GLOBAL="$TMD/global-b.cfg")" notes/f)" "held"

_tmd_finding "$TMD/glbc" 'notes/f merge=tmdkeep'
_tmd_cm="$(_tmd_git "$TMD/glbc" rev-parse main 2>/dev/null)"; _tmd_cc="$(_tmd_git "$TMD/glbc" rev-parse cand 2>/dev/null)"
printf '[merge "tmdkeep"]\n\tdriver = true\n[attr]\n\ttree = %s\n' "$_tmd_cc" > "$TMD/global-c.cfg"
mkdir -p "$TMD/glbc-bare"
( _fx_cd "$TMD/glbc-bare" && GIT_CONFIG_GLOBAL=/dev/null git init -q --bare ) >/dev/null 2>&1
printf '%s\n' "$TMD/glbc/.git/objects" > "$TMD/glbc-bare/objects/info/alternates"
is  "tmd: (fixture control) global config with attr.tree: the checkout's config defines no tmdkeep driver; in a bare repository with no worktree whose objects reach the checkout's, plain git merge-tree keeps the line without the global file, and keeps main's notes/f with GIT_CONFIG_GLOBAL naming a file that defines the driver and sets attr.tree to the candidate, whose .gitattributes names it" \
    "$(_fx_git "$TMD/glbc" config --local --get merge.tmdkeep.driver >/dev/null 2>&1; printf 'local %s' "$?")|$(_tmd_plain "$TMD/glbc-bare" TMD_OURS="$_tmd_cm" TMD_THEIRS="$_tmd_cc")|$(_tmd_plain "$TMD/glbc-bare" TMD_OURS="$_tmd_cm" TMD_THEIRS="$_tmd_cc" GIT_CONFIG_GLOBAL="$TMD/global-c.cfg")" \
    "local 1|rc 0|not main's notes/f|line 1|rc 0|main's notes/f|line 0"
is  "tmd: global config with attr.tree: with the driver and attr.tree naming the candidate both in the file GIT_CONFIG_GLOBAL names, the added lines still hold the credential line" \
    "$(_tmd_held "$(_tmd_read "$TMD/glbc" felix_added_lines GIT_CONFIG_GLOBAL="$TMD/global-c.cfg")" "+$_tmd_cred")" "held"
is  "tmd: global config with attr.tree: with the driver and attr.tree naming the candidate both in the file GIT_CONFIG_GLOBAL names, the changed paths still hold notes/f" \
    "$(_tmd_held "$(_tmd_read "$TMD/glbc" felix_changed_paths GIT_CONFIG_GLOBAL="$TMD/global-c.cfg")" notes/f)" "held"

# --------------------------------------------------------- a driver that records ---
_tmd_finding "$TMD/rec"
_tmd_git "$TMD/rec" config merge.tmdrec.driver "printf ran > '$TMD/rec.marker'" >/dev/null 2>&1
printf 'notes/f merge=tmdrec\n' > "$TMD/rec/.git/info/attributes"
rm -f "$TMD/rec.marker"; _tmd_rc="$(_tmd_plain "$TMD/rec")|$(_tmd_marker)"
rm -f "$TMD/rec.marker"; _tmd_read "$TMD/rec" felix_added_lines >/dev/null; _tmd_ral="$(_tmd_marker)"
rm -f "$TMD/rec.marker"; _tmd_read "$TMD/rec" felix_changed_paths >/dev/null; _tmd_rcp="$(_tmd_marker)"
rm -f "$TMD/rec.marker"
is  "tmd: (fixture control) a driver that records: with merge.tmdrec.driver writing a marker file in the checkout's config and notes/f merge=tmdrec in its info/attributes, plain git merge-tree in the checkout exits 0, keeps main's notes/f and writes the marker" \
    "$_tmd_rc" "rc 0|main's notes/f|line 0|marker written"
is  "tmd: a driver that records: felix_added_lines never runs the checkout's driver whose command writes a marker file (the marker is absent)" \
    "$_tmd_ral" "no marker"
is  "tmd: a driver that records: felix_changed_paths never runs the checkout's driver whose command writes a marker file (the marker is absent)" \
    "$_tmd_rcp" "no marker"

# ------------------------------------------------------------ a stacked branch ---
_tmd_init "$TMD/stk"
_tmd_git "$TMD/stk" checkout -q -b cand >/dev/null 2>&1
printf '%s\n' g1 g2 g-added > "$TMD/stk/a/g"; _tmd_commit "$TMD/stk" "the change below"
printf '%s\n' h1 h2 h-added > "$TMD/stk/a/h"; _tmd_commit "$TMD/stk" "this change"
_tmd_git "$TMD/stk" checkout -q main >/dev/null 2>&1
printf '%s\n' g1 g2 g-added > "$TMD/stk/a/g"; mkdir -p "$TMD/stk/main"; printf 'main only\n' > "$TMD/stk/main/only"
_tmd_commit "$TMD/stk" "the change below, squashed, and a file of main's own"
_tmd_git "$TMD/stk" checkout -q cand >/dev/null 2>&1
_tmd_st="$(_fx_git "$TMD/stk" merge-tree --write-tree main HEAD 2>/dev/null)"; _tmd_st="${_tmd_st%%$'\n'*}"
is  "tmd: (fixture control) a stacked branch: three-dot names a/g and a/h and adds both their lines, while the tree plain git merge-tree writes differs from main's only at a/h" \
    "$(_tmd_flat "$(_tmd_3paths "$TMD/stk")")|$(_tmd_flat "$(_tmd_3lines "$TMD/stk")")|$(_tmd_flat "$(_fx_git "$TMD/stk" diff --name-only --no-renames "main^{tree}" "${_tmd_st:-none}" 2>&1)")" \
    "a/g|a/h|+g-added|+h-added|a/h"

# ------------------------------------------------------------ byte-identical ---
is  "tmd: byte-identical: with no driver and no attributes, the added lines are exactly the credential line and the reader exits 0" \
    "$(_tmd_flat "$_tmd_al")" "+$_tmd_cred|rc 0"
is  "tmd: byte-identical: with no driver and no attributes, the changed paths are exactly notes/f and the reader exits 0" \
    "$(_tmd_flat "$_tmd_cp")" "notes/f|rc 0"
is  "tmd: byte-identical: on a stacked branch whose base already holds one of its two changes and gained a file of its own, the added lines are exactly the other change's line and the reader exits 0" \
    "$(_tmd_flat "$(_tmd_read "$TMD/stk" felix_added_lines)")" "+h-added|rc 0"
is  "tmd: byte-identical: on a stacked branch whose base already holds one of its two changes and gained a file of its own, the changed paths are exactly a/h and the reader exits 0" \
    "$(_tmd_flat "$(_tmd_read "$TMD/stk" felix_changed_paths)")" "a/h|rc 0"

# ------------------------------------------------------------------ fallback ---
_unwritable_probe
_tmd_unw="$TMD/unw"; mkdir -p "$_tmd_unw"; chmod 555 "$_tmd_unw"
if [ "$_unwritable" = 1 ]; then
  is  "tmd: (fixture control) fallback: mktemp -d cannot make a directory in the mode-555 TMPDIR; three-dot names notes/f and adds the credential line in the checkout driver's fixture, and names a/g and a/h and adds both their lines in the stacked one" \
      "$( ( mktemp -d "$_tmd_unw/x.XXXXXX" ) >/dev/null 2>&1 && printf 'made one' || printf 'refused')|$(_tmd_flat "$(_tmd_3paths "$TMD/drv")")|$(_tmd_flat "$(_tmd_3lines "$TMD/drv")")|$(_tmd_flat "$(_tmd_3paths "$TMD/stk")")|$(_tmd_flat "$(_tmd_3lines "$TMD/stk")")" \
      "refused|notes/f|+$_tmd_cred|a/g|a/h|+g-added|+h-added"
  is  "tmd: fallback: with an unwritable TMPDIR and the checkout's driver, the added lines hold every line the three-dot diff adds" \
      "$(_tmd_missing "$(_tmd_3lines "$TMD/drv")" "$(_tmd_body "$(_tmd_read "$TMD/drv" felix_added_lines TMPDIR="$_tmd_unw")")")" "none"
  is  "tmd: fallback: with an unwritable TMPDIR and the checkout's driver, the changed paths hold every path the three-dot diff names" \
      "$(_tmd_missing "$(_tmd_3paths "$TMD/drv")" "$(_tmd_body "$(_tmd_read "$TMD/drv" felix_changed_paths TMPDIR="$_tmd_unw")")")" "none"
  is  "tmd: fallback: with an unwritable TMPDIR on a stacked branch, the added lines hold every line the three-dot diff adds" \
      "$(_tmd_missing "$(_tmd_3lines "$TMD/stk")" "$(_tmd_body "$(_tmd_read "$TMD/stk" felix_added_lines TMPDIR="$_tmd_unw")")")" "none"
  is  "tmd: fallback: with an unwritable TMPDIR on a stacked branch, the changed paths hold every path the three-dot diff names" \
      "$(_tmd_missing "$(_tmd_3paths "$TMD/stk")" "$(_tmd_body "$(_tmd_read "$TMD/stk" felix_changed_paths TMPDIR="$_tmd_unw")")")" "none"
else
  skip "tmd: (fixture control) fallback: mktemp -d cannot make a directory in the mode-555 TMPDIR; three-dot names notes/f and adds the credential line in the checkout driver's fixture, and names a/g and a/h and adds both their lines in the stacked one" "$_nowrite"
  skip "tmd: fallback: with an unwritable TMPDIR and the checkout's driver, the added lines hold every line the three-dot diff adds" "$_nowrite"
  skip "tmd: fallback: with an unwritable TMPDIR and the checkout's driver, the changed paths hold every path the three-dot diff names" "$_nowrite"
  skip "tmd: fallback: with an unwritable TMPDIR on a stacked branch, the added lines hold every line the three-dot diff adds" "$_nowrite"
  skip "tmd: fallback: with an unwritable TMPDIR on a stacked branch, the changed paths hold every path the three-dot diff names" "$_nowrite"
fi
chmod 755 "$_tmd_unw"
rm -rf "${TMD:?}"
# <<< trust-merge-driver
# >>> trust-merge-driver-copy-alone
printf '\ntrust plane step 3, S6.6 rule 2: inside felix merge, the change readers merge over the checked copy alone (blind)\n'
# Blind, written on 2026-11-08 from .felix/memory/felix/audits/2026-11-08-trust-plane-step3/checkout-merge-driver/spec.md
# (rule 2, and "A planted merged blob" in its list), review/README.md item 1 and review/planted-blob-probe.sh, before
# reading rule 2's implementation. Not read: _felix_merge_refs in lib/resolve.sh, and lib/bind.sh on the branch. Read:
# lib/bind.sh as on origin/main, to drive felix merge into the bound state; parts 2178 and this one above, and
# tests/lib/merge.sh and judge-refs.sh, for the fixture; escape.sh's added-lines checks and secret-scan's base mode, to
# choose the line; felix's cmd_merge, for the refusal's exit status (3, the blockers branch).
#
# The fixture: R (this section's own, under $TMC) is part 2178's shape: the harness under test as engine/ at 1.0.0, a
# github.com origin, projects/tmc/ with one obligation that holds, the entry K/1.0.0 cut from main, receipts recorded
# for the tree as it stands against P's project directory, and a provider stub that answers the pull request open on
# main at HEAD and main at M. R0 holds notes/f (this part's eight lines); main, M, changes its last line after R0; each
# candidate is cut from R0 and puts one line after notes/f's first line, so the merge is clean and main has moved. Each
# case is `felix merge --dry-run` from the entry, with a fresh TMPDIR, and git on PATH logging each merge-tree call.
#
# Readings, where the spec and the brief leave room:
# - The line. The brief names a credential line that `escape disclose` refuses. That escape is bin/secret-scan's verdict,
#   and secret-scan reads three-dot base...HEAD (the spec's Open list, last item), so a planted merged blob does not
#   reach it. The callers of felix_added_lines a grep of lib/, bin/ and felix finds are escape.sh's durable added-lines
#   check (destructive SQL) and classify.sh's content rows. So the case that must be red without rule 2 adds
#   destructive SQL, put together at run time so this file holds no line that check matches (it would read this
#   part's own added lines). The credential form is kept as a second case; it refused on both sides of rule 2 in the
#   red and green runs, through secret-scan, so it is a guard and not the red case.
# - "Refuses with the escape": the dry run prints not merging, a blocker line `escape durable ... ADDED-LINES` (or
#   `escape disclose ... ADDED-LINES`), and exits 3.
# - The plant: a loose file in the checkout's objects under the merged notes/f's id, predicted with git hash-object from
#   the clean merge's lines, holding main's notes/f bytes, written after the no-plant control has run.
# - "The checkout keeps its objects": every object `cat-file --batch-all-objects` lists in the checkout before a run is
#   answered by `cat-file --batch-check` after it, for every run here; the plant is among them.
# - "No temporary directory left": no entry named felix-merge* or felix-objects* under any run's TMPDIR. A directory
#   of another name is not looked for.
# - "An honest candidate with a plant of an unrelated id": a candidate adding a plain line to notes/f, run while the
#   checkout holds a loose file, with main's notes/f bytes, under an id no tree here holds; it must say felix merge
#   would squash this now, and exit 0.
#
# Not covered: a merge (not a dry run) and its squash; the reader called directly outside felix merge, where the spec
# leaves the checkout visible (review item 1: "a planted object there attacks only the worker's own run"); a planted
# merged tree, or a planted pack; the changed-paths reader, which a planted blob leaves listing notes/f.
TMC="$TMP/tmc"; rm -rf "${TMC:?}"; mkdir -p "$TMC/repo" "$TMC/gh" "$TMC/home" "$TMC/kc" "$TMC/t" "$TMC/ctl"
TMC="$(cd "${TMC:?}" && pwd -P)"; TMCR="$TMC/repo"; TMCK="$TMC/kc"; TMCP="$TMC/repo/projects/tmc"
TMC_TN=0; TMCT=""; TMCRC=0; TMC_RUNS=0; TMC_LEFT=""; TMC_LOST=""
mkdir -p "$MEM/tmc"
_tmc_sql="$(printf '%s%s %s%s tmc_rows;' DR OP TA BLE)"
_tmc_plain="a plain note, nothing a rule names"

cat > "$TMC/gh/gh" <<'TMCGH'
#!/usr/bin/env bash
d="${TMC_GHDIR:?TMC_GHDIR is not set}"
printf '%s\n' "$*" >> "$d/calls"
case "${1:-} ${2:-}" in
  "pr view")
    case " $* " in *baseRefName*) cat "$d/a"; exit 0 ;; esac
    printf '{"number":7,"state":"OPEN"}\n'; exit 0 ;;
  "pr merge")    printf 'merged\n'; exit 0 ;;
  "auth status") printf 'github.com\n  Logged in to github.com account example\n'; exit 0 ;;
  "repo view")   printf 'example/tmc\n'; exit 0 ;;
  api\ repos/*/git/ref/heads/*) cat "$d/q"; exit 0 ;;
esac
exit 0
TMCGH
_tmc_realgit="$(type -P git)"
cat > "$TMC/gh/git" <<TMCGIT
#!/bin/bash
case " \$* " in *" merge-tree "*) printf '%s\n' "\$*" >> "$TMC/ctl/mt" ;; esac
exec "$_tmc_realgit" "\$@"
TMCGIT
chmod +x "$TMC/gh/gh" "$TMC/gh/git"

# ------------------------------------------------------------------ helpers ---
_tmc_check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]${4:+: $4}"; fi; }   # NAME GOT WANT [DETAIL]
_tmc_why() { printf 'exit %s; out: %s; err: %s; merge-tree calls %s' "$TMCRC" "$(head -c 900 "$TMC/out" 2>/dev/null | tr '\n' ' ')" \
  "$(head -c 300 "$TMC/err" 2>/dev/null | tr '\n' ' ')" "$(LC_ALL=C awk 'END { print NR + 0 }' "$TMC/ctl/mt" 2>/dev/null)"; }
_tmc_verdict() {   # -> what the last run said: refused, would squash or neither, and its exit status
  if [ "$(cat "$TMC/out" "$TMC/err" | LC_ALL=C awk 'index($0, "not merging") { n++ } END { print n + 0 }')" -gt 0 ]; then
    printf 'refused, exit %s' "$TMCRC"
  elif [ "$(LC_ALL=C awk 'index($0, "felix merge would squash this now.") { n++ } END { print n + 0 }' "$TMC/out")" -gt 0 ]; then
    printf 'would squash, exit %s' "$TMCRC"
  else printf 'neither, exit %s' "$TMCRC"; fi
}
_tmc_bl() {   # NAME WORD -> yes when the last run printed a blocker line `escape NAME ... WORD`, else no
  cat "$TMC/out" "$TMC/err" | LC_ALL=C awk -v nm="$1" -v a="$2" 'index($0, "  ") == 1 && $1 == "escape" && $2 == nm && index($0, a) { f = 1 }
    END { print (f ? "yes" : "no") }'
}
_tmc_mt() { LC_ALL=C awk 'index($0, "merge-tree") && index($0, "--write-tree") { n++ } END { print (n ? "merge-tree ran" : "no merge-tree") }' "$TMC/ctl/mt" 2>/dev/null; }
_tmc_commit() {   # MSG: one commit of everything in R, with maintenance off
  _fx_git "$TMCR" add -A >/dev/null 2>&1
  _fx_git "$TMCR" -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c maintenance.auto=false -c core.hooksPath=/dev/null commit -qm "$1" >/dev/null 2>&1
}
_tmc_f() { printf '%s\n' alpha "$@" bravo charlie delta echo foxtrot golf; }   # [LINE] -> notes/f to golf, LINE after alpha
_tmc_cand() {   # BRANCH LINE: a candidate cut from R0 that puts LINE after notes/f's first line
  ( _fx_cd "$TMCR" && git checkout -q -f -B "$1" "$TMC_R0" ) >/dev/null 2>&1
  { _tmc_f "$2"; printf 'hotel\n'; } > "$TMCR/notes/f"; _tmc_commit "$1"
  ( _fx_cd "$TMCR" && git checkout -q -f main ) >/dev/null 2>&1
}
_tmc_want() { { _tmc_f "$1"; printf 'hotel on main\n'; } | _fx_git "$TMCR" hash-object --stdin 2>/dev/null; }   # LINE -> the clean merge's notes/f id
_tmc_loose() { printf '%s/%s/%s' "$TMCO" "$(printf '%s' "$1" | cut -c1-2)" "$(printf '%s' "$1" | cut -c3-)"; }   # ID -> its loose file
_tmc_plant() {   # ID: a loose file in the checkout under ID holding a blob of main's notes/f bytes
  local f; f="$(_tmc_loose "$1")"; mkdir -p "${f%/*}"; rm -f "$f"
  perl -MCompress::Zlib -e 'local $/; open(my $h, "<", $ARGV[0]) or die; binmode $h; my $c = <$h>; binmode STDOUT;
    print compress("blob " . length($c) . "\0" . $c)' "$TMC/main.f" > "$f"
}
_tmc_count() { LC_ALL=C grep -cxF -- "$2" <<<"$1"; }   # TEXT LINE -> how many lines of TEXT are LINE
_tmc_probe() (   # BRANCH LINE -> ID|line N: plain git merge-tree of main and BRANCH, writing into a fresh store with the
                 # checkout's objects behind it, as bind's environment has them; the merged notes/f's id, and how often
                 # LINE is in what git reads for it (in R by _fx_cd, then git, as part 2178 reads under GIT_OBJECT_DIRECTORY:
                 # _fx_git refuses to run with it set)
  rm -rf "$TMC/probe"; mkdir -p "$TMC/probe"
  ( _fx_cd "$TMC/probe" && GIT_CONFIG_GLOBAL=/dev/null git init -q --bare ) >/dev/null 2>&1
  _fx_cd "$TMCR" || exit 1   # before the store is pointed elsewhere: _fx_cd refuses once it is
  export GIT_OBJECT_DIRECTORY="$TMC/probe/objects" GIT_ALTERNATE_OBJECT_DIRECTORIES="$TMCO"
  t="$(git merge-tree --write-tree main "$1" 2>/dev/null)"; t="${t%%$'\n'*}"
  b="$(git -C "$TMCR" rev-parse -q --verify "${t:-none}:notes/f" 2>/dev/null)"
  printf '%s|line %s' "${b:-none}" "$(_tmc_count "$(git -C "$TMCR" cat-file blob "${b:-none}" 2>/dev/null)" "$2")"
)
_tmc_record() {   # a green gate receipt and a commission receipt for R as it stands, home R, read against P's directory
  ( cd "$TMCR" && FELIX_HOME="$TMCR"; . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/epoch.sh"
    felix_verify_record "$TMCR" "$TMCR" 0 "true" "$(felix_tree_id "$TMCR" "$TMCR")" "" "" "$(felix_epoch "$TMCPP" "$TMCR")" \
      "$(felix_epoch_components "$TMCPP" "$TMCR" | cut -f2 | paste -sd, -)" ) >/dev/null 2>&1
  ( cd "$TMCR" && FELIX_HOME="$TMCR"; FELIX_HOME_DIR="$TMCR"; . "$FROOT/harness/lib/commission.sh"
    _o="$(felix_commission_run "$TMCPP" "$TMCR" -)"
    felix_commission_receipt_write "$TMCR" "$TMCPP" "$TMCR" "$_o" "" ) >/dev/null 2>&1
}
# _tmc_run LABEL BRANCH: felix merge --dry-run on BRANCH from the entry in R, home R, a fresh TMPDIR, after fresh
# receipts, the provider answering the pull request open on main at HEAD and main at M. What the run left under its
# TMPDIR goes onto TMC_LEFT; an object the checkout listed before the run and does not answer for after, onto TMC_LOST.
_tmc_run() {
  local l="$1" left n all
  ( _fx_cd "$TMCR" && git checkout -q -f "$2" ) >/dev/null 2>&1
  printf '7\tOPEN\tmain\t%s\n' "$(_jr_sha "$TMCR" HEAD)" > "$TMC/ctl/a"; printf 'commit\t%s\n' "$TMC_M" > "$TMC/ctl/q"
  : > "$TMC/ctl/calls"; : > "$TMC/ctl/mt"
  _tmc_record
  _fx_git "$TMCR" cat-file --batch-all-objects --batch-check='%(objectname)' > "$TMC/before" 2>/dev/null
  TMC_TN=$((TMC_TN + 1)); mkdir -p "$TMC/t/$TMC_TN"; TMCT="$(cd "$TMC/t/$TMC_TN" && pwd -P)"
  ( cd "$TMCR" && env -u FELIX_KERNEL -u FELIX_MERGE_HANDED HOME="$TMC/home" PATH="$TMC/gh:$PATH" TMC_GHDIR="$TMC/ctl" \
      FELIX_HOME="$TMCR" FELIX_KERNEL_CACHE="$TMCK" TMPDIR="$TMCT" GIT_ALLOW_PROTOCOL=file \
      "$TMCK/1.0.0/harness/felix" merge --dry-run ) > "$TMC/out" 2> "$TMC/err"; TMCRC=$?
  TMC_RUNS=$((TMC_RUNS + 1))
  left="$(find "$TMCT" \( -name 'felix-merge*' -o -name 'felix-objects*' \) -print 2>/dev/null | LC_ALL=C sed "s|^$TMCT/||" | tr '\n' ' ')"
  [ -z "$left" ] || TMC_LEFT="${TMC_LEFT}$l left [$left]; "
  all="$(LC_ALL=C awk 'END { print NR + 0 }' "$TMC/before")"
  n="$(_fx_git "$TMCR" cat-file --batch-check='%(objectname) %(objecttype)' < "$TMC/before" 2>/dev/null \
         | LC_ALL=C awk '$2 == "missing" { n++ } END { print n + 0 }')"
  if [ "$all" -eq 0 ]; then TMC_LOST="${TMC_LOST}$l listed nothing before; "
  elif [ "$n" != 0 ]; then TMC_LOST="${TMC_LOST}$l lost $n of $all; "; fi
}

# ---------------------------------------------------------------- fixture R ---
( _fx_cd "$TMCR" && git init -q -b main && git remote add origin https://github.com/example/tmc.git \
  && git config gc.auto 0 && git config maintenance.auto false ) >/dev/null 2>&1
_copy_content "$REAL_HARNESS" "$TMCR/engine/harness"; _copy_content "$REAL_HARNESS/../hooks" "$TMCR/engine/hooks"
[ -d "$REAL_HARNESS/../commands" ] && _copy_content "$REAL_HARNESS/../commands" "$TMCR/engine/commands"
mkdir -p "$TMCR/engine/.claude-plugin" "$TMCP" "$TMCR/.github/workflows" "$TMCR/notes"
printf '{ "name": "felix", "version": "1.0.0" }\n' > "$TMCR/engine/.claude-plugin/plugin.json"
printf 'state/\n*.log\n' > "$TMCR/.gitignore"; printf 'tmc\n' > "$TMCR/.felix"
printf '{\n  "name": "tmc",\n  "remote_match": "example.com/tmc",\n  "gate": "true",\n  "gate_workflow": "gate.yml"\n}\n' > "$TMCP/project.json"
printf '# tmc\n' > "$TMCP/CLAUDE.md"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$TMCP/probes.tsv"
printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds\n' > "$TMCP/obligations.tsv"
printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n' > "$TMCP/commissioning.tsv"
cp "$REAL_HARNESS/templates/risk.tsv" "$TMCP/risk.tsv"
printf 'on: pull_request\njobs: {}\n' > "$TMCR/.github/workflows/gate.yml"
{ _tmc_f; printf 'hotel\n'; } > "$TMCR/notes/f"
_tmc_commit R0; TMC_R0="$(_jr_sha "$TMCR" HEAD)"
{ _tmc_f; printf 'hotel on main\n'; } > "$TMCR/notes/f"
_tmc_commit "main moves"; TMC_M="$(_jr_sha "$TMCR" HEAD)"
_fx_git "$TMCR" update-ref refs/remotes/origin/main "$TMC_M" >/dev/null 2>&1
_fx_git "$TMCR" cat-file blob "$TMC_M:notes/f" > "$TMC/main.f" 2>/dev/null
TMCO="$(_fx_git "$TMCR" rev-parse --path-format=absolute --git-path objects 2>/dev/null)"
_tmc_cand tmc-sql "$_tmc_sql"; _tmc_cand tmc-cred "$_tmd_cred"; _tmc_cand tmc-honest "$_tmc_plain"
mkdir -p "$TMC/p"
_fx_git "$TMCR" archive -o "$TMC/p.tar" "$TMC_M" projects/tmc >/dev/null 2>&1 && tar -x -C "$TMC/p" -f "$TMC/p.tar"
rm -f "$TMC/p.tar"; TMCPP="$TMC/p/projects/tmc"
rm -rf "$TMCK/1.0.0" "$TMC/x" "$TMC/x.tar"; mkdir -p "$TMCK/1.0.0" "$TMC/x"
_fx_git "$TMCR" archive -o "$TMC/x.tar" "$TMC_M" engine >/dev/null 2>&1 && tar -x -C "$TMC/x" -f "$TMC/x.tar"
for _tmc_d in harness hooks commands .claude-plugin; do [ -d "$TMC/x/engine/$_tmc_d" ] && cp -R "$TMC/x/engine/$_tmc_d" "$TMCK/1.0.0/$_tmc_d"; done
rm -rf "$TMC/x" "$TMC/x.tar"
_tmc_mb="$(for _tmc_b in tmc-sql tmc-cred tmc-honest; do printf '%s ' "$(_fx_git "$TMCR" merge-base main "$_tmc_b" 2>/dev/null)"; done)"
_tmc_check "tmd: copy alone (fixture control): main has moved since R0, the base of each of the three candidates; origin/main is main; and the entry holds the felix under test" \
  "$_tmc_mb|$([ "$TMC_M" != "$TMC_R0" ] && echo moved)|$(_jr_sha "$TMCR" refs/remotes/origin/main)|$(cmp -s "$TMCK/1.0.0/harness/felix" "$REAL_HARNESS/felix" && echo entry)" \
  "$TMC_R0 $TMC_R0 $TMC_R0 |moved|$TMC_M|entry"
_tmc_check "tmd: copy alone (fixture control): three-dot main...tmc-sql adds the destructive SQL line, and bin/secret-scan against main exits 0 on it, so the disclose escape is not what refuses it" \
  "$(_tmc_count "$(_fx_git "$TMCR" diff --no-color main...tmc-sql 2>/dev/null)" "+$_tmc_sql")|scan $( ( _fx_cd "$TMCR" && git checkout -q -f tmc-sql && "$REAL_HARNESS/bin/secret-scan" main ) >/dev/null 2>&1; printf '%s' "$?")" \
  "1|scan 0"

# ------------------------------------------- a planted merged blob, destructive SQL ---
_tmc_w="$(_tmc_want "$_tmc_sql")"
_tmc_check "tmd: copy alone (fixture control): before any plant, a plain git merge-tree of main and tmc-sql, writing into a fresh store with the checkout's objects behind it, names the merged notes/f by the id predicted from the clean merge's lines and holds the SQL line" \
  "$(_tmc_probe tmc-sql "$_tmc_sql")" "$_tmc_w|line 1"
_tmc_run sql-no-plant tmc-sql
_tmc_check "tmd: copy alone (fixture control): without a plant, felix merge --dry-run refuses tmc-sql with escape durable ADDED-LINES and exits 3" \
  "$(_tmc_verdict)|durable $(_tmc_bl durable ADDED-LINES)" "refused, exit 3|durable yes" "$(_tmc_why)"
_tmc_check "tmd: copy alone (fixture control): that dry run took the three-way merge, running git merge-tree --write-tree" \
  "$(_tmc_mt)" "merge-tree ran" "$(_tmc_why)"
_tmc_plant "$_tmc_w"
_tmc_check "tmd: copy alone (fixture control): the plant is there: a loose file in the checkout under the merged notes/f's id, git cat-file -p of that id in the checkout prints main's notes/f, and a plain merge-tree with the checkout behind it names notes/f by that id and reads it without the SQL line" \
  "$([ -f "$(_tmc_loose "$_tmc_w")" ] && echo loose)|$(_fx_git "$TMCR" cat-file -p "$_tmc_w" 2>/dev/null | cmp -s - "$TMC/main.f" && echo "main's bytes")|$(_tmc_probe tmc-sql "$_tmc_sql")" \
  "loose|main's bytes|$_tmc_w|line 0"
_tmc_run sql-plant tmc-sql
_tmc_check "tmd: copy alone: with a loose file planted in the checkout under the merged blob's id holding main's bytes, felix merge --dry-run still reads tmc-sql's destructive SQL line, refusing it with escape durable ADDED-LINES and exit 3 (the planted object is not taken as the merge's result)" \
  "$(_tmc_verdict)|durable $(_tmc_bl durable ADDED-LINES)" "refused, exit 3|durable yes" "$(_tmc_why)"

# ------------------------------------------------- the credential form, a guard ---
_tmc_wc="$(_tmc_want "$_tmd_cred")"
_tmc_run cred-no-plant tmc-cred
_tmc_check "tmd: copy alone (fixture control): without a plant, felix merge --dry-run refuses tmc-cred with escape disclose ADDED-LINES and exits 3" \
  "$(_tmc_verdict)|disclose $(_tmc_bl disclose ADDED-LINES)" "refused, exit 3|disclose yes" "$(_tmc_why)"
_tmc_plant "$_tmc_wc"
_tmc_check "tmd: copy alone (fixture control): the credential plant is there: a loose file under the merged notes/f's id for tmc-cred, holding main's notes/f" \
  "$([ -f "$(_tmc_loose "$_tmc_wc")" ] && echo loose)|$(_fx_git "$TMCR" cat-file -p "$_tmc_wc" 2>/dev/null | cmp -s - "$TMC/main.f" && echo "main's bytes")" \
  "loose|main's bytes"
_tmc_run cred-plant tmc-cred
_tmc_check "tmd: copy alone: with a loose file planted under the merged blob's id holding main's bytes, felix merge --dry-run still refuses tmc-cred's credential line with escape disclose ADDED-LINES and exit 3" \
  "$(_tmc_verdict)|disclose $(_tmc_bl disclose ADDED-LINES)" "refused, exit 3|disclose yes" "$(_tmc_why)"

# --------------------------------------------- an honest candidate, no false block ---
_tmc_u="$(printf 'tmd: an object no tree here holds\n' | _fx_git "$TMCR" hash-object --stdin 2>/dev/null)"
_tmc_plant "$_tmc_u"
_tmc_check "tmd: copy alone (fixture control): the unrelated plant is there, holding main's notes/f under an id that is not the honest candidate's merged notes/f" \
  "$([ -f "$(_tmc_loose "$_tmc_u")" ] && echo loose)|$(_fx_git "$TMCR" cat-file -p "$_tmc_u" 2>/dev/null | cmp -s - "$TMC/main.f" && echo "main's bytes")|$([ "$_tmc_u" != "$(_tmc_want "$_tmc_plain")" ] && echo unrelated)" \
  "loose|main's bytes|unrelated"
_tmc_run honest tmc-honest
_tmc_check "tmd: copy alone: an honest candidate that changes notes/f with nothing a rule names, run while the checkout holds a planted loose file of an unrelated id, is not blocked: felix merge --dry-run says it would squash this now and exits 0" \
  "$(_tmc_verdict)" "would squash, exit 0" "$(_tmc_why)"

# ------------------------------------------------- what the runs leave behind ---
_tmc_check "tmd: copy alone: after each felix merge run here, the checkout's object store still answers for every object it held before the run, the planted ones included" \
  "runs $TMC_RUNS|lost [$TMC_LOST]" "runs 5|lost []"
_tmc_check "tmd: copy alone: no felix-merge* or felix-objects* entry is left under the TMPDIR any felix merge run here was given" \
  "runs $TMC_RUNS|left [$TMC_LEFT]" "runs 5|left []"

( _fx_cd "$TMCR" && git checkout -q -f main ) >/dev/null 2>&1
rm -rf "$MEM/tmc" "${TMC:?}"
# <<< trust-merge-driver-copy-alone
