# The sectioned handoff: HANDOFF.md, docs/handoff/<id>.md, docs/handoff/pending/.
#
# HANDOFF.md holds a standing preamble, one current section headed
# `### <id>. <title>` and an index; every earlier section is a file of its own,
# docs/handoff/<id>.md, never edited again. The preamble names the current id
# and the next one once, as `(after <id> comes <next>)`, and that phrase is the
# marker everything here reads.
#
# The rule used to be that a session wrote its section into HANDOFF.md with
# the next id, archived the one it replaced and added the index row. That is
# one mutable slot and one counter shared by every session, and with ten
# sessions at once four pull requests claimed the same id within an hour. Each
# collision was a textual conflict at best, and a hand resolution that could
# re-archive or drop a section at worst.
#
# So the two are split. What a session authors is its section, and only that:
# a file of its own under docs/handoff/pending/, headed `### <title>` with no
# id, at a path no other session can choose. What is only true against the
# main it lands on (the id, the archive move, the index row, the marker) is
# derived, by felix_handoff_fold, from the order the pending files landed in.
# Two pull requests that each add a pending file touch no path in common, so
# they cannot conflict whatever order they land in, and the fold is a function
# of main, so it cannot pick an id main already has.
#
# A section waiting in pending/ is a complete handoff already, and the session
# start names it beside HANDOFF.md, so folding it in can wait without anybody
# missing it. `felix handoff --rotate` does the fold, from upkeep or from a
# landing actor; felix_handoff_check refuses every other way of changing what
# the fold owns. Ids are `0` and then letters counted in base 26: after 0bz
# comes 0ca, and after 0z comes 0aa.
#
# Nothing here names a project. The layout is the convention, and a checkout
# with no marker is not using it and is left alone.

FELIX_HANDOFF_FILE="HANDOFF.md"
FELIX_HANDOFF_DIR="docs/handoff"
FELIX_HANDOFF_PENDING="docs/handoff/pending"

# The id after this one: 0bv -> 0bw, 0bz -> 0ca, 0z -> 0aa, 0zz -> 0aaa.
felix_handoff_next_id() {
  local id="${1:-}" body out="" c carry=1 i
  case "$id" in 0|0*[!a-z]*|'') return 1 ;; 0*) ;; *) return 1 ;; esac
  body="${id#0}"; i=${#body}
  while [ "$i" -gt 0 ]; do
    c="${body:i-1:1}"
    if [ "$carry" -eq 1 ]; then
      if [ "$c" = z ]; then c=a; else c="$(printf '%s' "$c" | tr 'a-y' 'b-z')"; carry=0; fi
    fi
    out="$c$out"; i=$((i - 1))
  done
  [ "$carry" -eq 1 ] && out="a$out"
  printf '0%s\n' "$out"
}

# Drops the empty lines a section ends with and ends it with one newline, which
# is how every section since the split has been archived.
_felix_handoff_trim() {
  LC_ALL=C awk '{ a[NR] = $0 } END { n = NR; while (n > 0 && a[n] == "") n--; for (i = 1; i <= n; i++) print a[i] }'
}

# "<id>\t<next>\t<line>" from the marker: the first `(after X comes Y)` in the
# file. Only the first counts, because a section may quote the phrase; the
# check holds it to stand above the current section, where the preamble is.
felix_handoff_marker() {
  [ -f "$1" ] || return 1
  LC_ALL=C awk '{
      if (match($0, /\(after 0[a-z]+ comes 0[a-z]+\)/)) {
        split(substr($0, RSTART + 7, RLENGTH - 8), w, " ")
        printf "%s\t%s\t%d\n", w[1], w[3], NR; found = 1; exit
      } }
    END { exit !found }' "$1"
}

# "<start>\t<end>": the line that heads section <id>, and the `---` line that
# closes it. Refuses a heading that is absent or appears twice.
felix_handoff_bounds() {
  LC_ALL=C awk -v id="$2" '
    index($0, "### " id ". ") == 1 { n++; if (!s) s = NR }
    s && !e && NR > s && $0 == "---" { e = NR }
    END { if (n != 1 || !e) exit 1; printf "%d\t%d\n", s, e }' "$1"
}

# "<id>\t<title>" for every index row, `| [id](docs/handoff/id.md) | title |`.
felix_handoff_rows() {
  LC_ALL=C sed -n 's/^| \[\([0-9a-z][0-9a-z]*\)\](docs\/handoff\/\([0-9a-z][0-9a-z]*\)\.md) | \(.*\) |$/\1	\2	\3/p' "$1" \
    | LC_ALL=C awk -F'\t' '$1 == $2 { print $1 "\t" $3 }'
}

# Orders pending paths (relative to the checkout, one per line on stdin) by the
# order they landed in on <ref>'s first-parent history: the order main
# accepted them, not the order anybody claimed. A path <ref> does not hold yet
# comes after every one it does, by name.
_felix_handoff_order() {
  local root="$1" ref="${2:-}" names landed=""
  names="$(LC_ALL=C sort)"
  [ -n "$names" ] || return 0
  if [ -n "$ref" ] && git -C "$root" rev-parse --verify --quiet "$ref^{commit}" >/dev/null 2>&1; then
    landed="$(git -C "$root" log --first-parent --reverse --diff-filter=A --format= --name-only \
                "$ref" -- "$FELIX_HANDOFF_PENDING/" 2>/dev/null)"
  fi
  printf '%s\n' "$landed" | NAMES="$names" LC_ALL=C awk '
    BEGIN { n = split(ENVIRON["NAMES"], a, "\n"); for (i = 1; i <= n; i++) if (a[i] != "") have[a[i]] = 1 }
    NF && have[$0] && !done[$0]++ { print }
    END { for (i = 1; i <= n; i++) if (a[i] != "" && !done[a[i]]) print a[i] }'
}

# The pending sections in the checkout at <root>, oldest landing on <ref> first.
felix_handoff_pending_order() {
  local root="$1" ref="${2:-}" f
  for f in "$root/$FELIX_HANDOFF_PENDING"/*.md; do
    [ -f "$f" ] && printf '%s\n' "${f#"$root"/}"
  done | _felix_handoff_order "$root" "$ref"
}

# A pending section opens `### <title>`, with no id and no `|` in the title,
# since the title becomes an index cell. Prints why not, or nothing.
felix_handoff_pending_problem() {
  local h
  h="$(head -1 "$1" 2>/dev/null)"
  case "$h" in '### '*) ;; *) printf 'does not open with a "### <title>" heading'; return 0 ;; esac
  h="${h#'### '}"
  if printf '%s' "$h" | LC_ALL=C grep -qE '^[0-9][0-9a-z]*\. '; then
    printf 'carries an id in its heading, and ids are given when it is folded in'; return 0
  fi
  [ -n "$h" ] || { printf 'has an empty title'; return 0; }
  case "$h" in *'|'*) printf 'has a "|" in its title, which would split its index row' ;; esac
  return 0
}

# Folds pending sections into the handoff in <dir>, in the order <orderfile>
# lists them (paths relative to <dir>, oldest landing first). The current
# section is archived; each folded section takes the next id; the last becomes
# current and the rest are archived; their rows go into the index newest first,
# directly above its newest numbered row; the marker moves on; the folded files
# go. It is built aside, and nothing is written if any step fails. An archive
# that exists already is left alone when it holds these exact bytes, and
# refused when it does not: an archived section is never rewritten.
#
#   exit 0  folded, one "<id>\t<what>" line each and a "next" line; or nothing pending
#   exit 1  refused, and why, on stdout; nothing written
felix_handoff_fold() {
  local dir="$1" order="$2" h="$1/$FELIX_HANDOFF_FILE" t m x y b s e n i=0 p id cur="" title prob ins
  m="$(felix_handoff_marker "$h")" || { printf 'no (after <id> comes <next>) marker in %s\n' "$FELIX_HANDOFF_FILE"; return 1; }
  x="$(printf '%s' "$m" | cut -f1)"; y="$(printf '%s' "$m" | cut -f2)"
  [ "$y" = "$(felix_handoff_next_id "$x")" ] \
    || { printf 'the marker says after %s comes %s, and after %s comes %s\n' "$x" "$y" "$x" "$(felix_handoff_next_id "$x")"; return 1; }
  b="$(felix_handoff_bounds "$h" "$x")" \
    || { printf 'section %s is not headed exactly once and closed by a --- line\n' "$x"; return 1; }
  s="${b%%	*}"; e="${b#*	}"
  n="$(grep -c . "$order" 2>/dev/null)"; n="${n:-0}"
  [ "$n" -gt 0 ] || { printf 'nothing pending\n'; return 0; }
  t="$(mktemp -d 2>/dev/null)" || { printf 'could not make a directory to build in\n'; return 1; }
  mkdir -p "$t/out"
  sed -n "${s},$((e - 1))p" "$h" | _felix_handoff_trim > "$t/out/$x.md"
  title="$(head -1 "$t/out/$x.md")"; title="${title#"### $x. "}"
  printf '| [%s](docs/handoff/%s.md) | %s |\n' "$x" "$x" "$title" > "$t/rows"
  printf '%s\tarchived\n' "$x" > "$t/said"
  id="$y"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    i=$((i + 1))
    [ -f "$dir/$p" ] || { printf '%s is not there to fold\n' "$p"; rm -rf "$t"; return 1; }
    prob="$(felix_handoff_pending_problem "$dir/$p")"
    [ -z "$prob" ] || { printf '%s %s\n' "$p" "$prob"; rm -rf "$t"; return 1; }
    title="$(head -1 "$dir/$p")"; title="${title#'### '}"
    { printf '### %s. %s\n' "$id" "$title"; tail -n +2 "$dir/$p"; } | _felix_handoff_trim > "$t/sec"
    if [ "$i" -lt "$n" ]; then
      cp "$t/sec" "$t/out/$id.md"
      { printf '| [%s](docs/handoff/%s.md) | %s |\n' "$id" "$id" "$title"; cat "$t/rows"; } > "$t/rows.n"
      mv "$t/rows.n" "$t/rows"
      printf '%s\t%s, archived\n' "$id" "$p" >> "$t/said"
    else
      cp "$t/sec" "$t/current"; cur="$id"
      printf '%s\t%s, current\n' "$id" "$p" >> "$t/said"
    fi
    id="$(felix_handoff_next_id "$id")"
  done < "$order"
  # The preamble with the marker moved on, the new current section, a blank
  # line, and everything from the closing --- down.
  { sed -n "1,$((s - 1))p" "$h"; cat "$t/current"; printf '\n'; sed -n "${e},\$p" "$h"; } \
    | OLD="(after $x comes $y)" NEW="(after $cur comes $id)" LC_ALL=C awk '
        !d && (i = index($0, ENVIRON["OLD"])) {
          $0 = substr($0, 1, i - 1) ENVIRON["NEW"] substr($0, i + length(ENVIRON["OLD"])); d = 1 }
        { print }' > "$t/H1"
  # Rows go above the newest numbered row below the new section's ---, or
  # after the last index row when there is none to stand above.
  e=$(( s + $(wc -l < "$t/current") + 1 ))
  ins="$(LC_ALL=C awk -v after="$e" '
    NR > after && /^\| \[0[a-z]+\]\(docs\/handoff\/0[a-z]+\.md\) \| / { print NR - 1; exit }' "$t/H1")"
  [ -n "$ins" ] || ins="$(LC_ALL=C awk -v after="$e" '
    NR > after && /^\| \[[0-9a-z]+\]\(docs\/handoff\/[0-9a-z]+\.md\) \| / { l = NR } END { if (l) print l }' "$t/H1")"
  [ -n "$ins" ] || { printf 'no index table below the current section\n'; rm -rf "$t"; return 1; }
  { sed -n "1,${ins}p" "$t/H1"; cat "$t/rows"; sed -n "$((ins + 1)),\$p" "$t/H1"; } > "$t/H2"
  for p in "$t"/out/*.md; do
    if [ -e "$dir/$FELIX_HANDOFF_DIR/${p##*/}" ] && ! cmp -s "$p" "$dir/$FELIX_HANDOFF_DIR/${p##*/}"; then
      printf '%s/%s exists and holds something else, and an archived section is never rewritten\n' "$FELIX_HANDOFF_DIR" "${p##*/}"
      rm -rf "$t"; return 1
    fi
  done
  mkdir -p "$dir/$FELIX_HANDOFF_DIR"
  for p in "$t"/out/*.md; do cp "$p" "$dir/$FELIX_HANDOFF_DIR/${p##*/}"; done
  cp "$t/H2" "$h"
  while IFS= read -r p; do [ -n "$p" ] && rm -f "$dir/$p"; done < "$order"
  rmdir "$dir/$FELIX_HANDOFF_PENDING" 2>/dev/null || true
  cat "$t/said"; printf 'next\t%s\n' "$id"
  rm -rf "$t"
  return 0
}

# Folds every pending section in the checkout at <root>, ordered by <ref>.
felix_handoff_rotate() {
  local root="$1" ref="${2:-}" t rc
  t="$(mktemp 2>/dev/null)" || { printf 'could not make a file to order in\n'; return 1; }
  felix_handoff_pending_order "$root" "$ref" > "$t"
  felix_handoff_fold "$root" "$t"; rc=$?
  rm -f "$t"; return "$rc"
}

# Writes <file> as this branch's pending section and prints its path. The path
# is a UTC stamp and the branch name, which no concurrent session shares; a
# second call on the same branch rewrites the file the first one made, as long
# as <ref> does not hold it yet. A heading given with an id has it dropped, and
# says so on stderr, which is how a section cut under the old rule comes over.
felix_handoff_section() {
  local root="$1" src="$2" ref="${3:-}" h id="" title branch slug f rel mine="" dest
  [ -s "$src" ] || { printf 'no section at %s\n' "$src" >&2; return 1; }
  h="$(head -1 "$src")"
  case "$h" in '### '*) ;; *) printf '%s must open with a "### <title>" heading\n' "$src" >&2; return 1 ;; esac
  title="${h#'### '}"
  if printf '%s' "$title" | LC_ALL=C grep -qE '^[0-9][0-9a-z]*\. '; then
    id="${title%%. *}"; title="${title#*. }"
  fi
  [ -n "$title" ] || { printf '%s has an empty title\n' "$src" >&2; return 1; }
  case "$title" in *'|'*) printf 'the title has a "|", which would split its index row\n' >&2; return 1 ;; esac
  branch="$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  case "$branch" in ''|HEAD) branch=detached ;; esac
  slug="$(printf '%s' "$branch" | LC_ALL=C tr -c 'A-Za-z0-9._-' '-' | LC_ALL=C tr -s '-')"
  slug="${slug#-}"; slug="${slug%-}"
  for f in "$root/$FELIX_HANDOFF_PENDING"/*-"$slug".md; do
    [ -f "$f" ] || continue
    # The whole name, not its tail: branch x/a-b ends in -a-b as well.
    case "${f##*/}" in
      [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]Z-"$slug".md) ;;
      *) continue ;;
    esac
    rel="${f#"$root"/}"
    [ -n "$ref" ] && git -C "$root" cat-file -e "$ref:$rel" 2>/dev/null && continue
    mine="$f"
  done
  dest="${mine:-$root/$FELIX_HANDOFF_PENDING/$(date -u +%Y%m%dT%H%M%SZ)-$slug.md}"
  mkdir -p "$root/$FELIX_HANDOFF_PENDING" || return 1
  { printf '### %s\n' "$title"; tail -n +2 "$src"; } | _felix_handoff_trim > "$dest.part" && mv "$dest.part" "$dest" || return 1
  [ -z "$id" ] || printf 'dropped the id %s from the heading: a section is given its id when it is folded in\n' "$id" >&2
  printf '%s\n' "${dest#"$root"/}"
}

# Is the handoff in the checkout at <root> one the fold could have written?
# Read against the merge-base with <ref> when there is one, since that is what
# this branch changed; the tree-local half runs regardless.
#
# In the tree: one marker, above the current section, naming it and the id
# after it; the current section headed once and closed; every archived file one
# index row and every row one file, the row's title the file's; the current id
# neither archived nor indexed; every pending section well formed.
#
# Against the merge-base: every archived file there is byte-identical here; and
# the current section moves only as the fold of pending files the base holds,
# the oldest-landed first. A section written into HANDOFF.md by hand fails
# here: that is the old rule, and every collision on 2026-09-23 came from it.
# So does a pending file removed without being folded in, which drops it.
#
#   exit 0  clean
#   exit 1  a line per problem on stdout, "<what>\t<detail>"
#   exit 2  cannot examine: no HANDOFF.md, or one with no marker and no archive
felix_handoff_check() {
  local root="$1" ref="${2:-}" h="$1/$FELIX_HANDOFF_FILE" t m x y ml b s f id title hd base xb n rc=0
  [ -f "$h" ] || { printf 'cannot examine\tno %s in %s\n' "$FELIX_HANDOFF_FILE" "$root"; return 2; }
  if ! m="$(felix_handoff_marker "$h")"; then
    [ -d "$root/$FELIX_HANDOFF_DIR" ] || { printf 'cannot examine\t%s has no marker, so it is not the sectioned layout\n' "$FELIX_HANDOFF_FILE"; return 2; }
    printf 'marker\t%s names no current section: no (after <id> comes <next>) in it\n' "$FELIX_HANDOFF_FILE"; return 1
  fi
  t="$(mktemp -d 2>/dev/null)" || { printf 'cannot examine\tcould not make a scratch directory\n'; return 2; }
  : > "$t/p"; : > "$t/n"
  x="$(printf '%s' "$m" | cut -f1)"; y="$(printf '%s' "$m" | cut -f2)"; ml="$(printf '%s' "$m" | cut -f3)"
  [ "$y" = "$(felix_handoff_next_id "$x")" ] \
    || printf 'marker\tsays after %s comes %s, and after %s comes %s\n' "$x" "$y" "$x" "$(felix_handoff_next_id "$x")" >> "$t/p"
  if b="$(felix_handoff_bounds "$h" "$x")"; then
    s="${b%%	*}"
    [ "$ml" -lt "$s" ] || printf 'marker\tstands below the current section it names, where no preamble is\n' >> "$t/p"
  else
    printf 'current\tsection %s is not headed "### %s. " exactly once and closed by a --- line\n' "$x" "$x" >> "$t/p"
  fi
  # One section is current. Another headed with an id, beside it and with the
  # marker left alone, is a section written in by hand that no fold made; a
  # blind qualification control found this shape, which nothing above sees.
  X="$x" LC_ALL=C awk '/^### [0-9][0-9a-z]*\. / && index($0, "### " ENVIRON["X"] ". ") != 1 {
      id = substr($2, 1, length($2) - 1)
      printf "current\tsection %s sits in HANDOFF.md beside the current one; a section is added under docs/handoff/pending/, and only the fold makes it current\n", id }' \
    "$h" >> "$t/p"
  felix_handoff_rows "$h" > "$t/rows"
  cut -f1 "$t/rows" | LC_ALL=C sort | uniq -d | while IFS= read -r id; do
    printf 'index\t%s has more than one row\n' "$id"; done >> "$t/p"
  grep -q "^$x	" "$t/rows" && printf 'index\t%s is the current section and has an index row too\n' "$x" >> "$t/p"
  [ -e "$root/$FELIX_HANDOFF_DIR/$x.md" ] && printf 'archive\t%s is the current section and is archived too\n' "$x" >> "$t/p"
  for f in "$root/$FELIX_HANDOFF_DIR"/*.md; do
    [ -f "$f" ] || continue
    id="${f##*/}"; id="${id%.md}"
    case "$id" in _*) continue ;; esac
    if ! grep -q "^$id	" "$t/rows"; then
      printf 'index\t%s/%s.md is archived and has no index row\n' "$FELIX_HANDOFF_DIR" "$id" >> "$t/p"; continue
    fi
    title="$(ID="$id" LC_ALL=C awk -F'\t' '$1 == ENVIRON["ID"] { print $2; exit }' "$t/rows")"
    hd="$(head -1 "$f")"
    [ "$hd" = "### $id. $title" ] || [ "$hd" = "## $id. $title" ] \
      || printf 'index\tthe row for %s does not carry the title its file is headed with\n' "$id" >> "$t/p"
  done
  cut -f1 "$t/rows" | while IFS= read -r id; do
    [ "$id" = "$x" ] || [ -f "$root/$FELIX_HANDOFF_DIR/$id.md" ] || printf 'index\t%s has a row and no file\n' "$id"
  done >> "$t/p"
  for f in "$root/$FELIX_HANDOFF_PENDING"/*.md; do
    [ -f "$f" ] || continue
    m="$(felix_handoff_pending_problem "$f")"
    [ -z "$m" ] || printf 'pending\t%s %s\n' "${f#"$root"/}" "$m" >> "$t/p"
  done

  # Against the merge-base. No base is said, never passed over in silence.
  base=""
  [ -n "$ref" ] && base="$(git -C "$root" merge-base HEAD "$ref" 2>/dev/null)"
  if [ -z "$base" ]; then
    printf 'note\tno merge-base with %s, so nothing was compared with what this branch started from\n' "${ref:-a base ref}" >> "$t/n"
  elif ! git -C "$root" show "$base:$FELIX_HANDOFF_FILE" > "$t/base.md" 2>/dev/null \
       || ! xb="$(felix_handoff_marker "$t/base.md" | cut -f1)" || [ -z "$xb" ]; then
    printf 'note\tthe merge-base holds no sectioned %s, so nothing was compared with it\n' "$FELIX_HANDOFF_FILE" >> "$t/n"
  else
    git -C "$root" ls-tree "$base" -- "$FELIX_HANDOFF_DIR/" 2>/dev/null \
      | LC_ALL=C awk -F'\t' '$1 ~ / blob / && $2 ~ /\.md$/ { split($1, a, " "); print a[3] "\t" $2 }' \
      | while IFS=$'\t' read -r b f; do
          if [ ! -f "$root/$f" ]; then printf 'archive\t%s was archived and is gone\n' "$f"
          elif [ "$(git -C "$root" hash-object --no-filters -- "$f" 2>/dev/null)" != "$b" ]; then
            printf 'archive\t%s was rewritten, and an archived section stays as it stood\n' "$f"; fi
        done >> "$t/p"
    git -C "$root" ls-tree --name-only "$base" -- "$FELIX_HANDOFF_PENDING/" 2>/dev/null \
      | LC_ALL=C grep '\.md$' | _felix_handoff_order "$root" "$base" > "$t/order"
    while IFS= read -r f; do [ -f "$root/$f" ] || printf '%s\n' "$f"; done < "$t/order" > "$t/gone"
    n="$(grep -c . "$t/gone")"
    if [ "$x" = "$xb" ]; then
      # Edited in place, the current section keeps its heading. A new heading
      # under the old id is another section put in its place, and the one it
      # replaced is gone from the file without being archived.
      m="$(grep -m1 "^### $xb\. " "$t/base.md")"; f="$(grep -m1 "^### $x\. " "$h")"
      [ -z "$f" ] || [ "$f" = "$m" ] \
        || printf 'current\tsection %s is headed differently than on the merge-base, so another section took its place and the one it replaced is lost. A new section goes under %s/\n' "$x" "$FELIX_HANDOFF_PENDING" >> "$t/p"
      while IFS= read -r f; do printf 'pending\t%s was removed without being folded in, which drops it\n' "$f"; done < "$t/gone" >> "$t/p"
      for f in "$root/$FELIX_HANDOFF_DIR"/*.md; do
        [ -f "$f" ] || continue
        git -C "$root" cat-file -e "$base:${f#"$root"/}" 2>/dev/null \
          || printf 'archive\t%s is new, and only a fold archives a section\n' "${f#"$root"/}"
      done >> "$t/p"
    elif [ "$n" -eq 0 ]; then
      printf 'current\tsection %s replaced %s by hand. Write it with felix handoff --section FILE instead: it lands in %s/, and felix handoff --rotate gives it an id\n' "$x" "$xb" "$FELIX_HANDOFF_PENDING" >> "$t/p"
      # And the damage a hand rotation does when it was cut from an older
      # main: the archive it writes is its own stale copy of the section, and
      # whatever main added to that section since is dropped without a sign.
      if [ -f "$root/$FELIX_HANDOFF_DIR/$xb.md" ]; then
        _felix_handoff_block "$t/base.md" "$xb" > "$t/xb"
        cmp -s "$t/xb" "$root/$FELIX_HANDOFF_DIR/$xb.md" \
          || printf 'archive\t%s/%s.md is not the section the merge-base holds as current (%s lines against %s), so archiving it drops what the base added\n' \
               "$FELIX_HANDOFF_DIR" "$xb" "$(wc -l < "$root/$FELIX_HANDOFF_DIR/$xb.md" | tr -d ' ')" "$(wc -l < "$t/xb" | tr -d ' ')" >> "$t/p"
      fi
    elif [ "$(head -n "$n" "$t/order" | LC_ALL=C sort)" != "$(LC_ALL=C sort "$t/gone")" ]; then
      printf 'pending\tthe sections folded in are not the %s that landed first on the merge-base\n' "$n" >> "$t/p"
    else
      _felix_handoff_refold "$root" "$base" "$t" "$n" >> "$t/p"
    fi
  fi
  [ -s "$t/p" ] && { cat "$t/p"; rc=1; }
  cat "$t/n"
  rm -rf "$t"
  return "$rc"
}

# The base-relative half of a fold: the merge-base's handoff, folded by the
# same function over the <n> sections this branch removed, must be what this
# checkout holds, part by part. Prints a problem line per part that is not.
_felix_handoff_refold() {
  local root="$1" base="$2" t="$3" n="$4" r="$3/refold" f out
  mkdir -p "$r/$FELIX_HANDOFF_PENDING"
  cp "$t/base.md" "$r/$FELIX_HANDOFF_FILE"
  head -n "$n" "$t/order" > "$t/fold"
  while IFS= read -r f; do git -C "$root" show "$base:$f" > "$r/$f" 2>/dev/null; done < "$t/fold"
  if ! out="$(felix_handoff_fold "$r" "$t/fold")"; then
    printf 'fold\tthe merge-base cannot be folded: %s\n' "$(printf '%s' "$out" | head -1)"; return 0
  fi
  for f in "$r/$FELIX_HANDOFF_DIR"/*.md; do
    [ -f "$f" ] || continue
    cmp -s "$f" "$root/$FELIX_HANDOFF_DIR/${f##*/}" \
      || printf 'fold\t%s/%s is not the section the fold archives there\n' "$FELIX_HANDOFF_DIR" "${f##*/}"
  done
  [ "$(felix_handoff_marker "$r/$FELIX_HANDOFF_FILE" | cut -f1,2)" = "$(felix_handoff_marker "$root/$FELIX_HANDOFF_FILE" | cut -f1,2)" ] \
    || printf 'fold\tthe marker is not the one the fold moves it to\n'
  [ "$(felix_handoff_rows "$r/$FELIX_HANDOFF_FILE")" = "$(felix_handoff_rows "$root/$FELIX_HANDOFF_FILE")" ] \
    || printf 'fold\tthe index rows are not the ones the fold writes, in its order\n'
  f="$(felix_handoff_marker "$r/$FELIX_HANDOFF_FILE" | cut -f1)"
  [ "$(_felix_handoff_block "$r/$FELIX_HANDOFF_FILE" "$f")" = "$(_felix_handoff_block "$root/$FELIX_HANDOFF_FILE" "$f")" ] \
    || printf 'fold\tthe current section is not the pending section it was folded from\n'
  return 0
}

# The text of section <id> in <file>, heading to closing ---, trimmed.
_felix_handoff_block() {
  local b
  b="$(felix_handoff_bounds "$1" "$2")" || return 0
  sed -n "${b%%	*},$(( ${b#*	} - 1 ))p" "$1" | _felix_handoff_trim
}
