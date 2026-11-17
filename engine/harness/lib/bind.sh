# What the merge judges is what the provider holds (trust-plane step 3, slice 2).
#
# The spec is in the memory root, audits/2026-11-08-trust-plane-step3/spec-slice2.md. Slice 1 (policy.sh) moved
# what P holds to P. This file is about which commit P is, and what git returns when the merge reads P or the
# subject: each member of the class below is a way for git, in the worker's checkout, to answer the merge with
# something the provider does not hold. The members found on 2026-11-08, as examples and not the set: a --base the
# worker made, or a moved refs/remotes/origin/main; a replace ref; a graft; a planted loose object, which git does
# not re-hash when it reads it; and the git environment the caller hands felix merge.
#
# THE RULE (spec S5, S6).
#   - S6.1, S6.2, first thing in felix merge: the caller's git variables that choose a repository, an object store,
#     an index, replacement, config or a helper program are unset, and replacement and grafts are switched off, for
#     this process and every child.
#   - S5.1: the base ref is read once, to B, and everything after names B by its object id.
#   - S6.3, S6.4: once B and H (the checkout's HEAD) are known, the objects the verdict reads (B, H, M and their
#     trees, and the commits from M to each) are copied through `git index-pack`, which names each object by hashing
#     it, into a bare repository under TMPDIR named felix-objects.*. A name the copy lacks is a refusal. The rest of
#     the run reads that copy first, with the checkout's objects behind it for history before M. The copy holds V
#     twice: packed, as the run's object directory (GIT_OBJECT_DIRECTORY, which also takes what the run writes), and
#     loose, as the first alternate, ahead of the checkout (GIT_ALTERNATE_OBJECT_DIRECTORIES). git 2.56 reads a loose
#     object from any store before a packed one, so with the pack alone a loose file in the checkout, rewritten after
#     the check, was what the run read (found by part 2178's copy-read case, after the slice 2 review).
#   - S5.2 to S5.4: once the judgement found no blocker, the provider is asked which head the pull request has and
#     which commit its base branch is. The merge stands only when they are H and B, and the base is asked again
#     immediately before gh pr merge.
#   - S6.5: the copy, with the graft path inside it, is removed when the run ends, however it ends. And the list
#     beside it, and the git that is building it: each long git of the copy (init, pack-objects, index-pack,
#     unpack-objects) runs in a process group of its own and is waited for (felix_instr_grp, instrument-run.sh), so
#     a signal that ends felix merge while the copy is made ends that group with it (spec-slice3 A9, read as
#     reaching slice 2's copy: part 2182's signal came while it was being made, and left the list and the git).
#
# WHAT THIS DOES NOT BIND, as examples and not the set (spec section 3). The window between the last read of the
# provider's base and GitHub's squash. The gh on PATH, which answers for the provider as the worker's user. The
# index and working tree the instruments read, which do not land. A product's home in another repository, whose
# tables policy.sh reads from that repository's own objects. A pack planted in the checkout: git serves an object
# from the most recently used pack that names it, without re-hashing, so an object in V can still be read from the
# checkout's packs once a read elsewhere has put one of them first (found while building this; not measured).
#
# Sourced by escape.sh beside policy.sh. Needs resolve.sh (_felix_ref_commit).

# Set only here, in the shell that merges: an inherited value names no copy and no pin.
unset _FELIX_BIND_DIR _FELIX_BIND_OWNER _FELIX_BIND_HOME _FELIX_BIND_PACK _FELIX_BIND_M _FELIX_BIND_BLOCK _FELIX_BIND_NOTE _FELIX_BIND_WHY
unset _FELIX_BIND_PBASE _FELIX_BIND_PHEAD _FELIX_BIND_PSHA _FELIX_BIND_QSHA _FELIX_BIND_HANDED _FELIX_BIND_B _FELIX_BIND_COPY

# S6.5. The copy and the graft path inside it, removed by the process that made them and by no other. That process
# is read as BASHPID, or on bash 3.2 as the parent of a sh it execs, never $$, which a subshell shares: an EXIT trap a
# forked child runs (bash 5.2, a child signalled before it resets its traps) must not remove what its parent still
# reads. Written out at each use, never as a function called in a substitution, whose pid is a process of its own.
#
# What git wrote into the copy while the run read it is moved to the checkout first. Every child writes there (spec
# S6.4), and a child that commits, stashes or hashes with -w leaves a ref or an index entry naming what it wrote: removed
# with the copy, that is a branch naming a commit the repository no longer holds. Found by part 0350, whose injected
# peer commit inherited the run's environment and left its branch unreadable. Only what git itself wrote is moved
# (loose objects, and any pack but the checked one), and nothing the checkout already holds is replaced.
_felix_bind_salvage() {   # COPY-OBJECTS CHECKOUT-OBJECTS CHECKED-PACK
  local from="$1" to="$2" keep="$3" f rel
  [ -d "$from" ] && [ -d "$to" ] || return 0
  for f in "$from"/[0-9a-f][0-9a-f]/* "$from"/pack/*; do
    [ -f "$f" ] || continue
    rel="${f#"$from"/}"
    case "$rel" in pack/*) [ -z "$keep" ] || case "${rel##*/}" in "$keep".*) continue ;; esac ;; esac
    [ -e "$to/$rel" ] && continue
    mkdir -p "$to/${rel%/*}" 2>/dev/null && mv -f "$f" "$to/$rel" 2>/dev/null
  done
  return 0
}
_felix_bind_exit() {
  [ -n "${_FELIX_BIND_DIR:-}" ] || return 0
  [ "${BASHPID:-$(exec /bin/sh -c 'echo "$PPID"')}" = "${_FELIX_BIND_OWNER:-}" ] || return 0
  ! command -v felix_instr_grpend >/dev/null 2>&1 || felix_instr_grpend
  [ -z "${_FELIX_BIND_HOME:-}" ] || _felix_bind_salvage "$_FELIX_BIND_DIR/objects" "$_FELIX_BIND_HOME" "${_FELIX_BIND_PACK:-}"
  rm -rf "$_FELIX_BIND_DIR" "$_FELIX_BIND_DIR.list" 2>/dev/null
  _FELIX_BIND_DIR=""; _FELIX_BIND_COPY=""
}
# A long git of the copy, in a group of its own when instrument-run.sh is loaded (S6.5 above), else as it was.
_felix_bind_g() {   # git-args...
  if command -v felix_instr_grp >/dev/null 2>&1; then felix_instr_grp git "$@"; else git "$@"; fi
}

# S6.1 and S6.2. Returns 0, or 1 when no directory could be made for the run (the variables are scrubbed either way,
# and felix_bind_objects then refuses). The list is git 2.56's variables that choose a repository, an object store, an index,
# replacement, config or a helper program, as read for the spec; one found later is added here.
felix_bind_env() {
  local v tmpd="${TMPDIR:-/tmp}"
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR \
        GIT_NAMESPACE GIT_REPLACE_REF_BASE GIT_SHALLOW_FILE GIT_GRAFT_FILE GIT_NO_REPLACE_OBJECTS \
        GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_EXEC_PATH GIT_EXTERNAL_DIFF
  for v in ${!GIT_CONFIG_KEY_@} ${!GIT_CONFIG_VALUE_@}; do unset "$v"; done
  export GIT_NO_REPLACE_OBJECTS=1
  # Two readers that answer for an object without reading it, switched off in config this run sets for itself
  # (found while building this): the commit-graph names a commit's tree and parents, and a multi-pack index names
  # where an object's bytes are. Either, planted in the checkout, would answer for B without B's bytes.
  export GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=core.commitGraph GIT_CONFIG_VALUE_0=false \
         GIT_CONFIG_KEY_1=core.multiPackIndex GIT_CONFIG_VALUE_1=false
  # The engine's own colour pin (felix's header: a person's git colour never reaches what the engine parses) is put
  # back alone, once the caller's entries are gone; the unset above had dropped it for the merge and every child
  # (found in slice 2's review). git reads GIT_CONFIG_PARAMETERS after GIT_CONFIG_COUNT, and they share no key.
  [ -z "${_felix_git_pin:-}" ] || export GIT_CONFIG_PARAMETERS="$_felix_git_pin"
  _FELIX_BIND_OWNER="${BASHPID:-$(exec /bin/sh -c 'echo "$PPID"')}"
  _FELIX_BIND_DIR="$(mktemp -d "${tmpd%/}/felix-objects.XXXXXX" 2>/dev/null)" || _FELIX_BIND_DIR=""
  # A path inside a directory this run made, which nothing creates: git then reads no graft at all, the checkout's
  # info/grafts included. Set even when the directory could not be made, since the run refuses then anyway.
  export GIT_GRAFT_FILE="${_FELIX_BIND_DIR:-${tmpd%/}/felix-objects.none}/no-grafts"
  _felix_bind_traps
  [ -n "$_FELIX_BIND_DIR" ]
}
# The copy's traps: its removal on exit, and on QUIT, whose own action ends bash without the exit trap. TERM, INT and
# HUP are left at their own action, which runs the exit trap at once, even under a foreground child. Put back by the
# judges that hold signals for a while of their own (instrument.sh, merge-judge.sh) when they are done.
_felix_bind_traps() { trap '_felix_bind_exit' EXIT; trap '_felix_bind_exit; trap - EXIT; exit 131' QUIT; }

# S5.1. The commit REF names, read once into _FELIX_BIND_B (called in the merging shell, never in a substitution,
# so the exports below reach the children). REF is a full ref name (cmd_merge has
# checked it). A copy of main's engine that felix merge handed the run to (lib/merge-judge.sh) takes the commit its
# parent read, so the hand-off does not read the ref a second time; cmd_merge refuses a pin taken that way by any
# felix that turns out not to be that copy. Returns 1 when REF names no commit.
felix_bind_pin() {   # ROOT REF
  local root="$1" ref="$2" sha="" at="${FELIX_MERGE_BASE_AT:-}"
  _FELIX_BIND_HANDED=""; _FELIX_BIND_B=""
  if [ -n "${FELIX_MERGE_HANDED:-}" ] && [ -n "$at" ] && [ "${FELIX_MERGE_BASE_REF:-}" = "$ref" ]; then
    case "$at" in *[!0-9a-f]*) ;; *) case "${#at}" in 40|64)
      sha="$(git -C "$root" rev-parse --verify --quiet "$at^{commit}" 2>/dev/null </dev/null)"
      [ "$sha" = "$at" ] && _FELIX_BIND_HANDED=1 || sha="" ;; esac ;;
    esac
  fi
  if [ -z "$sha" ]; then
    sha="$(git -C "$root" show-ref --verify -s -- "$ref" 2>/dev/null </dev/null)" || sha=""
    [ -n "$sha" ] && sha="$(git -C "$root" rev-parse --verify --quiet "$sha^{commit}" 2>/dev/null </dev/null)"
  fi
  [ -n "$sha" ] || return 1
  # For the children: the hand-off's copy takes the pin, and a report names the ref while reading the commit.
  export FELIX_MERGE_BASE_AT="$sha" FELIX_MERGE_BASE_REF="$ref"
  _FELIX_BIND_B="$sha"
}

# One objects blocker into _FELIX_BIND_BLOCK, for felix_bind_objects. Always 1.
_felix_bind_no() { _FELIX_BIND_BLOCK="$(printf 'objects\t%s\t%s' "$1" "$2")"; return 1; }

# S6.3 and S6.4. Copies V into the run's bare repository through index-pack, checks every name in V is there, then
# points this process and its children at the copy, and computes M again under it. Returns 0; or 1 with one blocker
# line in _FELIX_BIND_BLOCK (kind objects), and the environment left reading the checkout.
felix_bind_objects() {   # ROOT B H
  local root="$1" b="$2" h="$3" d="${_FELIX_BIND_DIR:-}" objs fmt m m2 miss t rc1 rc2 rc3 rcs
  _FELIX_BIND_BLOCK=""; _FELIX_BIND_M=""
  [ -n "$d" ] && [ -d "$d" ] \
    || _felix_bind_no copy "no directory could be made under ${TMPDIR:-/tmp} to copy the objects the verdict reads into, so none of them was checked against its name" || return 1
  [ -n "$h" ] || _felix_bind_no HEAD "the checkout's HEAD names no commit, so there is no subject to check" || return 1
  objs="$(git -C "$root" rev-parse --path-format=absolute --git-path objects 2>/dev/null </dev/null)"
  [ -n "$objs" ] && [ -d "$objs" ] || _felix_bind_no copy "git named no object directory for $root" || return 1
  fmt="$(git -C "$root" rev-parse --show-object-format 2>/dev/null </dev/null)" || fmt=""
  m="$(git -C "$root" merge-base "$b" "$h" 2>/dev/null </dev/null)" || m=""
  t="$d.list"
  # V: the three commits, the commits since M on either side, and every object under the three trees. With no M,
  # B and H and their trees; the judgement then refuses as it does when it cannot compare. Listed beside the
  # copy, not in it, because git init wants the directory to itself.
  {
    printf '%s\n' "$b" "$h" ${m:+"$m"}
    if [ -n "$m" ]; then git -C "$root" rev-list "$b" "$h" "^$m" </dev/null || exit 1; fi
    # A name a tree holds and the checkout lacks is listed (`?name`), so it is refused by name below.
    git -C "$root" rev-list --objects --no-object-names --missing=print "$b^{tree}" "$h^{tree}" ${m:+"$m^{tree}"} </dev/null
  } 2>/dev/null | LC_ALL=C awk '{ sub(/^\?/, "") } NF && !seen[$1]++ { print $1 }' > "$t"
  rcs=("${PIPESTATUS[@]}"); rc1="${rcs[0]:-1}"; rc2="${rcs[1]:-1}"
  if [ "$rc1" -ne 0 ] || [ "$rc2" -ne 0 ] || [ ! -s "$t" ]; then
    rm -f "$t"; _felix_bind_no copy "the objects under $b and $h could not be listed, so none of them was checked against its name"; return 1
  fi
  if ! _felix_bind_g init -q --bare --template= ${fmt:+--object-format="$fmt"} "$d" >/dev/null 2>&1 </dev/null; then
    rm -f "$t"; _felix_bind_no copy "no repository could be made at $d to copy the objects into"; return 1
  fi
  # A name in V the checkout does not hold at all is refused by that name, before anything is copied.
  miss="$(git -C "$root" cat-file --batch-check='%(objectname) %(objecttype)' < "$t" 2>/dev/null \
            | LC_ALL=C awk '$2 == "missing" && !f { print $1; f = 1 }')" || miss=""
  if [ -n "$miss" ]; then
    rm -f "$t"; _felix_bind_no "$miss" "the checkout does not hold $miss, which the verdict would read, so nothing can show what it holds; nothing else was judged"; return 1
  fi
  # git reads the alternates list as paths split at ':'; a path holding one would be read as two directories.
  case "$d$objs" in
    *:*) rm -f "$t"; _felix_bind_no copy "the copy $d or the checkout's objects $objs holds a ':', which git reads as two directories in the list of stores, so the copy cannot be read first"; return 1 ;;
  esac
  # index-pack and unpack-objects each name an object by hashing what it holds, so a planted object comes out under
  # another name. The stream is kept inside the copy, which the exit removes, so that both read the same bytes.
  _felix_bind_g -C "$root" pack-objects --stdout -q --window=0 < "$t" > "$d/v.stream" 2>/dev/null; rc1=$?
  _felix_bind_g --git-dir="$d" index-pack --stdin --fsck-objects < "$d/v.stream" >/dev/null 2>&1; rc2=$?
  if [ "$rc1" -ne 0 ] || [ "$rc2" -ne 0 ]; then
    rm -f "$t"; _felix_bind_no copy "the objects under $b and $h could not be copied through git index-pack (pack-objects $rc1, index-pack $rc2), so none of them was checked against its name"; return 1
  fi
  miss="$(git --git-dir="$d" cat-file --batch-check='%(objectname) %(objecttype)' < "$t" 2>/dev/null \
            | LC_ALL=C awk '$2 == "missing" && !f { print $1; f = 1 }')"; rc3=$?
  if [ -n "$miss" ]; then
    rm -f "$t"; _felix_bind_no "$miss" "git holds an object under the name $miss whose bytes do not hash to that name, so what it would show for it is not what the name says; nothing else was judged"; return 1
  fi
  [ "$rc3" -eq 0 ] || { rm -f "$t"; _felix_bind_no copy "the copy of the objects under $b and $h could not be read back, so none of them was checked against its name"; return 1; }
  # The same objects loose, in a store of their own that only this copy names (see the head of this file).
  mkdir "$d/v" 2>/dev/null && GIT_OBJECT_DIRECTORY="$d/v" _felix_bind_g --git-dir="$d" unpack-objects -q < "$d/v.stream" >/dev/null 2>&1; rc1=$?
  rm -f "$d/v.stream"
  miss="$(GIT_OBJECT_DIRECTORY="$d/v" git --git-dir="$d" cat-file --batch-check='%(objectname) %(objecttype)' < "$t" 2>/dev/null \
            | LC_ALL=C awk '$2 == "missing" && !f { print $1; f = 1 }')"; rc3=$?
  rm -f "$t"
  if [ "$rc1" -ne 0 ] || [ "$rc3" -ne 0 ] || [ -n "$miss" ]; then
    _felix_bind_no copy "the objects under $b and $h could not be written loose into the copy (unpack-objects $rc1${miss:+, $miss missing}), so the checkout's loose files would be read before the checked pack"; return 1
  fi
  # The checked pack is the only one there; anything else the exit finds was written during the run.
  for t in "$d"/objects/pack/pack-*.pack; do [ -f "$t" ] && { t="${t##*/}"; _FELIX_BIND_PACK="${t%.pack}"; }; done
  _FELIX_BIND_HOME="$objs"
  export GIT_OBJECT_DIRECTORY="$d/objects" GIT_ALTERNATE_OBJECT_DIRECTORIES="$d/v:$objs"
  m2="$(git -C "$root" merge-base "$b" "$h" 2>/dev/null </dev/null)" || m2=""
  if [ "$m2" != "$m" ]; then
    unset GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES
    _felix_bind_no "${m2:-merge-base}" "the merge base of $b and $h is ${m:-none} in the checkout and ${m2:-none} in the checked copy, so the checkout's history does not say what its objects hold; nothing else was judged"; return 1
  fi
  _FELIX_BIND_M="$m"
  # Where the checked copy is, for the change readers' merge, which reads it alone (S6.6 rule 2). A shell variable, so
  # the readers this shell runs see it and no child of the merge does.
  _FELIX_BIND_COPY="$d"
  return 0
}

# The repository on GitHub that the checkout's origin names, as owner/name, or nothing.
_felix_bind_slug() {   # ROOT
  local u s LC_ALL=C
  u="$(git -C "$1" remote get-url origin 2>/dev/null </dev/null)" || return 1
  case "$u" in *github.com[/:]*) ;; *) return 1 ;; esac
  s="${u#*github.com[/:]}"; s="${s%/}"; s="${s%.git}"
  # A pattern in a variable, which bash 3.2 and 5 read alike; no pipe into grep under pipefail.
  local re='^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$'
  [[ "$s" =~ $re ]] || return 1
  printf '%s' "$s"
}

# A commit id as the provider writes one: 40 or 64 lower-case hex.
_felix_bind_hex() { case "$1" in *[!0123456789abcdef]*|'') return 1 ;; esac; case "${#1}" in 40|64) return 0 ;; esac; return 1; }

# S5.2, call Q alone: the commit the provider's base branch PBASE names, into _FELIX_BIND_QSHA; or 1 with the
# reason in _FELIX_BIND_WHY.
_felix_bind_q() {   # SLUG PBASE
  local out typ sha
  _FELIX_BIND_QSHA=""
  out="$(gh api "repos/$1/git/ref/heads/$2" --jq '[.object.type,.object.sha]|join("\t")' 2>/dev/null </dev/null)" \
    || { _FELIX_BIND_WHY="gh api for the base branch $2 failed"; return 1; }
  case "$out" in *$'\n'*|'') _FELIX_BIND_WHY="gh api for the base branch $2 gave no single line"; return 1 ;; esac
  typ="${out%%$'\t'*}"; sha="${out#*$'\t'}"
  [ "$typ" = commit ] && [ "$sha" != "$out" ] && _felix_bind_hex "$sha" \
    || { _FELIX_BIND_WHY="gh api for the base branch $2 did not name a commit"; return 1; }
  _FELIX_BIND_QSHA="$sha"
}

# S5.2. Asks the provider its two things and sets _FELIX_BIND_PBASE, _FELIX_BIND_PHEAD and _FELIX_BIND_PSHA.
# Returns 0 with an answer, or 1 with no answer and the reason in _FELIX_BIND_WHY. Nothing else counts as one.
felix_bind_ask() {   # ROOT BRANCH
  local root="$1" branch="$2" slug out n st pb ph rest
  _FELIX_BIND_PBASE=""; _FELIX_BIND_PHEAD=""; _FELIX_BIND_PSHA=""; _FELIX_BIND_WHY=""
  command -v gh >/dev/null 2>&1 || { _FELIX_BIND_WHY="no gh on PATH"; return 1; }
  slug="$(_felix_bind_slug "$root")" || { _FELIX_BIND_WHY="no GitHub remote"; return 1; }
  out="$(gh pr view "$branch" --repo "$slug" --json number,state,baseRefName,headRefOid \
           --jq '[(.number|tostring),.state,.baseRefName,.headRefOid]|join("\t")' 2>/dev/null </dev/null)" \
    || { _FELIX_BIND_WHY="gh pr view for $branch failed"; return 1; }
  case "$out" in *$'\n'*|'') _FELIX_BIND_WHY="gh pr view for $branch gave no single line"; return 1 ;; esac
  n="${out%%$'\t'*}"; rest="${out#*$'\t'}"; st="${rest%%$'\t'*}"; rest="${rest#*$'\t'}"
  pb="${rest%%$'\t'*}"; ph="${rest#*$'\t'}"
  case "$n" in ''|*[!0123456789]*) _FELIX_BIND_WHY="gh pr view for $branch named no pull request number"; return 1 ;; esac
  [ "$st" = OPEN ] || { _FELIX_BIND_WHY="the pull request for $branch is not open (${st:-no state})"; return 1; }
  case "$pb" in ''|-*|*[!A-Za-z0123456789._/-]*) _FELIX_BIND_WHY="gh pr view for $branch named no base branch it could be asked about"; return 1 ;; esac
  git check-ref-format --branch "$pb" >/dev/null 2>&1 </dev/null \
    || { _FELIX_BIND_WHY="gh pr view for $branch named no base branch it could be asked about"; return 1; }
  _felix_bind_hex "$ph" || { _FELIX_BIND_WHY="gh pr view for $branch named no head commit"; return 1; }
  _felix_bind_q "$slug" "$pb" || return 1
  _FELIX_BIND_PSHA="$_FELIX_BIND_QSHA"
  _FELIX_BIND_PBASE="$pb"; _FELIX_BIND_PHEAD="$ph"
  return 0
}

# S5.3, once the judgement found no blocker. Sets _FELIX_BIND_BLOCK to the blocker lines (base, moved) the comparison
# makes, and _FELIX_BIND_NOTE to the line a dry run prints when the provider could not be asked.
felix_bind_compare() {   # ROOT BRANCH B H DRY
  local root="$1" branch="$2" b="$3" h="$4" dry="$5" nl=$'\n'
  _FELIX_BIND_BLOCK=""; _FELIX_BIND_NOTE=""
  if ! felix_bind_ask "$root" "$branch"; then
    if [ "$dry" -eq 1 ]; then
      _FELIX_BIND_NOTE="felix merge: not compared with the provider: $_FELIX_BIND_WHY. The merge this previews asks it again, and refuses without an answer."
    else
      _FELIX_BIND_BLOCK="$(printf 'base\tprovider\tthe provider could not be asked which commit it would squash onto (%s), so the base judged here is not known to be its base, and nothing was merged' "$_FELIX_BIND_WHY")"
    fi
    return 0
  fi
  if [ "$_FELIX_BIND_PSHA" != "$b" ]; then
    _FELIX_BIND_BLOCK="$(printf 'base\t%s\tthe base judged, %s, is not the base the provider would squash onto: %s is %s on GitHub. Fetch, and run this again' \
      "$_FELIX_BIND_PBASE" "$b" "$_FELIX_BIND_PBASE" "$_FELIX_BIND_PSHA")"
  fi
  if [ "$_FELIX_BIND_PHEAD" != "$h" ]; then
    _FELIX_BIND_BLOCK="${_FELIX_BIND_BLOCK:+$_FELIX_BIND_BLOCK$nl}$(printf 'moved\thead\tthe pull request'"'"'s head on GitHub is %s and the checkout'"'"'s is %s, so what was judged is not what would land' \
      "$_FELIX_BIND_PHEAD" "$h")"
  fi
  return 0
}

# S5.4, immediately before gh pr merge: the base asked again. Returns 0 when it is still B; 1 with the reason in
# _FELIX_BIND_WHY otherwise.
felix_bind_last() {   # ROOT B
  local slug sha
  _FELIX_BIND_WHY=""
  slug="$(_felix_bind_slug "$1")" || { _FELIX_BIND_WHY="no GitHub remote"; return 1; }
  [ -n "${_FELIX_BIND_PBASE:-}" ] || { _FELIX_BIND_WHY="the provider was never asked"; return 1; }
  command -v gh >/dev/null 2>&1 || { _FELIX_BIND_WHY="no gh on PATH"; return 1; }
  _felix_bind_q "$slug" "$_FELIX_BIND_PBASE" || return 1
  sha="$_FELIX_BIND_QSHA"
  [ "$sha" = "$2" ] && return 0
  _FELIX_BIND_WHY="$_FELIX_BIND_PBASE is $sha on GitHub now, and $2 was judged"
  return 1
}
