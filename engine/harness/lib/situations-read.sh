# felix situations, the readings (slice 1 of the capability lane; contracts C3.1 to C3.4 and C17 of
# docs/2026-10-29-lane-slice-1-plan.md). Loaded by cmd_situations in felix, after lib/situations.sh. Definitions only.
#
# ONE SIDE READ. A side is read into a reading file, one per side, inside the run's scratch directory. Its lines are
# tab-separated and each is named by its first cell; only the order of the probe lines matters, they are in reading order:
#
#   how      recorded|scratch
#   commit   <sha40>|-
#   tree     <tree id>
#   stamp    <stamp>|-
#   detector run|not-run|no-tree      not-run is a live tree that differs, no-tree one whose id could not be taken (C17.5)
#   cap      <capability>            zero or more, the detector's names, sorted and unique, present only when it ran
#   probe    <pred> <grounds> <state> <count> <detail>|-
#
# THE RECORDED READING (--at, C3.1) comes from facts.log under the project's memory root, read and never written. THE
# SCRATCH READING (--change, C3.3) comes from a shared clone of the repository's common git directory, checked out detached
# at one commit and removed with the scratch directory.
#
# THE SCRATCH DIRECTORY (C3.3). One per run, made under ${TMPDIR:-/tmp}, in both modes. Every reading and evaluation file
# the run writes lives in it. It is removed before the report is printed, on every exit after it was made, and on TERM,
# HUP and INT, which then exit 143, 129 and 130. Its path is the global _FELIX_SITUATIONS_SCRATCH, set empty before any
# trap is installed, because a trap body is read when it fires and a local is gone by then (felix_discover's precedent).
# mktemp's output is assigned to that global by the command that runs mktemp, so a signal that arrives as it finishes finds
# the name already stored (C17.8).
#
# EVERY STEP IS CHECKED (C17.4). A function here returns 0, 1 for an answer that is no (no tree recorded, no commit), or 3
# after it has printed the one sentence on stderr that says why the run ends. Its callers pass the 3 on.

# Sets _FELIX_SITUATIONS_ME to the pid of the process that runs this, which a subshell's own differs from its parent's: the
# parent of a shell that has exec'd sh is the process that forked it. bash 3.2 has no BASHPID, and neither $$ nor
# BASH_SUBSHELL tells a subshell apart. It sets a global and is never called inside a substitution of its own, since that
# would make the substitution's process the answer.
_felix_situations_self() {
  _FELIX_SITUATIONS_ME="$(exec /bin/sh -c 'echo "$PPID"')"
}

# The directory, removed. Written for a trap: it reads the global, tolerates it unset or empty, and does nothing twice. It
# acts only in the process that made the directory: a child of that process that bash 5.2 has forked but not yet given
# its own traps runs this trap too when a signal reaches it, and must not remove what the run still stands on.
felix_situations_scratch_remove() {
  local d="${_FELIX_SITUATIONS_SCRATCH:-}"
  [ -n "$d" ] || return 0
  _felix_situations_self
  [ "$_FELIX_SITUATIONS_ME" = "${_FELIX_SITUATIONS_OWNER:-}" ] || return 0
  rm -rf "$d" 2>/dev/null
  _FELIX_SITUATIONS_SCRATCH=""
  return 0
}

# Makes the scratch directory with its traps installed first: EXIT removes it, and TERM, HUP and INT remove it and exit 143,
# 129 and 130. Returns 0, or 3 with C2's scratch-directory sentence on stderr and no directory made. <tmpdir> in the
# sentence is ${TMPDIR:-/tmp} as given.
felix_situations_scratch_begin() {
  local tmp="${TMPDIR:-/tmp}" d
  _FELIX_SITUATIONS_SCRATCH=""
  _felix_situations_self
  _FELIX_SITUATIONS_OWNER="$_FELIX_SITUATIONS_ME"
  trap 'felix_situations_scratch_remove' EXIT
  trap 'felix_situations_scratch_remove; exit 143' TERM
  trap 'felix_situations_scratch_remove; exit 129' HUP
  trap 'felix_situations_scratch_remove; exit 130' INT
  _FELIX_SITUATIONS_SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/felix-situations.XXXXXX" 2>/dev/null)" || _FELIX_SITUATIONS_SCRATCH=""
  d="$_FELIX_SITUATIONS_SCRATCH"
  if [ -z "$d" ] || [ ! -d "$d" ]; then
    printf 'felix situations: the scratch directory could not be made: mktemp -d failed under %s\n' "$tmp" >&2
    return 3
  fi
  # Absolute, so a TMPDIR given relative names the same directory from inside a clone, where the probes run. The name mktemp
  # gave is already stored, so the trap removes the directory under it until this replaces it with the same directory.
  d="$(CDPATH='' cd -P -- "$d" 2>/dev/null && pwd -P)" || d=""
  [ -z "$d" ] || _FELIX_SITUATIONS_SCRATCH="$d"
  return 0
}

# The directory removed, and the traps put back. Called before the report is printed.
felix_situations_scratch_end() {
  felix_situations_scratch_remove
  trap - EXIT TERM HUP INT
  return 0
}

# The newest recorded tree of a facts.log (C3.1): the tree field of the last line, in file order, that has 8 or more
# fields and whose tree is not unknown-tree (an empty tree field names no tree and is passed over). Prints it. Returns 1,
# printing nothing, when the log is absent, unreadable, empty, or records no tree, and 3 when the awk that reads it failed.
felix_situations_newest_tree() {   # LOG
  local log="${1-}" t
  [ -f "$log" ] && [ -r "$log" ] || return 1
  t="$(LC_ALL=C awk -F'\t' 'NF >= 8 && $2 != "unknown-tree" && $2 != "" { t = $2 "" } END { print t }' "$log" 2>/dev/null)" \
    || { _felix_situations_fail "reading the newest recorded tree"; return 3; }
  [ -n "$t" ] || return 1
  printf '%s' "$t"
}

# The recorded reading of one tree (C3.1), written to OUT as the first lines of a reading file: how, tree, stamp, then one
# probe line per predicate of the run. The run is decided by the last line, in file order, that has 8 or more fields and
# names TREE: its stamp and the tree name the run, whose rows are every such line with that stamp and tree. An older run
# of the same tree is never read, a predicate that appears more than once in the run is read from its first line, and
# unknown-tree is never a tree. A line with fewer than 8 fields is ignored, and columns 4, 8 and 9 are not read. The probe's
# own sentence is not in the log, so each probe line's detail is - (C10 gives its reason). Returns 1 when no run is
# recorded for TREE, with OUT unwritten, and 3 when a step failed.
felix_situations_read_recorded() {   # LOG TREE OUT
  local log="${1-}" tree="${2-}" out="${3-}" body rc
  [ -f "$log" ] && [ -r "$log" ] || return 1
  body="$(FELIX_SITUATIONS_TREE="$tree" LC_ALL=C awk -F'\t' '
    BEGIN { want = ENVIRON["FELIX_SITUATIONS_TREE"] "" }
    NF >= 8 && ($2 "") == want && want != "unknown-tree" && want != "" {
      n++; STAMP[n] = $1 ""; PRED[n] = $3 ""; GRND[n] = $7 ""; STATE[n] = $5 ""; COUNT[n] = $6 ""
    }
    END {
      if (n == 0) exit 1
      run = STAMP[n]
      printf "stamp\t%s\n", run
      for (i = 1; i <= n; i++) {
        if (STAMP[i] != run || (PRED[i] in SEEN)) continue
        SEEN[PRED[i]] = 1
        printf "probe\t%s\t%s\t%s\t%s\t-\n", PRED[i], GRND[i], STATE[i], COUNT[i]
      }
    }' "$log" 2>/dev/null)"
  rc=$?
  [ "$rc" -ne 1 ] || return 1
  if [ "$rc" -ne 0 ] || [ -z "$body" ]; then
    _felix_situations_fail "reading the recorded run"
    return 3
  fi
  printf 'how\trecorded\ntree\t%s\n%s\n' "$tree" "$body" > "$out" 2>/dev/null \
    || { _felix_situations_fail "writing the recorded reading"; return 3; }
  return 0
}

# A string of exactly the digits a full commit id is made of: 40 lowercase hex digits, or 64 under the longer hash.
_felix_situations_fullid() {   # TEXT
  case "${1-}" in *[!0123456789abcdef]*) return 1 ;; esac
  [ "${#1}" -eq 40 ] || [ "${#1}" -eq 64 ]
}

# A revision resolved to a commit id in the live repository, printed whole. Status 1 and nothing printed when it names no
# commit here, and so when git resolves it to anything but one full commit id (^HEAD resolves to ^ and the id, C17.7); status 2
# when git could not be asked, which is a status of rev-parse --verify past 1. A revision that begins with - is not one, so
# git never reads it as an option.
_felix_situations_rev() {   # ROOT REV
  local root="${1-}" rev="${2-}" sha rc
  case "$rev" in ''|-*) return 1 ;; esac
  sha="$(_felix_git_rules "$root" rev-parse --verify --quiet "${rev}^{commit}" 2>/dev/null)"
  rc=$?
  case "$rc" in 0) ;; 1) return 1 ;; *) return 2 ;; esac
  _felix_situations_fullid "$sha" || return 1
  printf '%s' "$sha"
}

# The main ref (C3.3): prints its full name. It is the target of refs/remotes/origin/HEAD when that is a symbolic ref to a
# refs/remotes/origin/<x> that names a commit; otherwise refs/remotes/origin/main when it names a commit; otherwise
# refs/heads/main. Returns 1, printing nothing, when none of the three names a commit, and 3 with C17.4's sentence when git
# answered neither yes nor no (a status past 1) to symbolic-ref or to a ref's rev-parse --verify:
#   felix situations: the change could not be read: <ref> could not be read
_felix_situations_mainref() {   # ROOT
  local root="${1-}" t rc
  t="$(_felix_git_rules "$root" symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null)"
  rc=$?
  case "$rc" in
    0) ;;
    1) t="" ;;
    *) printf 'felix situations: the change could not be read: refs/remotes/origin/HEAD could not be read\n' >&2; return 3 ;;
  esac
  case "$t" in
    refs/remotes/origin/?*)
      _felix_situations_rev "$root" "$t" >/dev/null
      rc=$?
      case "$rc" in
        0) printf '%s' "$t"; return 0 ;;
        1) ;;
        *) printf 'felix situations: the change could not be read: %s could not be read\n' "$t" >&2; return 3 ;;
      esac ;;
  esac
  for t in refs/remotes/origin/main refs/heads/main; do
    _felix_situations_rev "$root" "$t" >/dev/null
    rc=$?
    case "$rc" in
      0) printf '%s' "$t"; return 0 ;;
      1) ;;
      *) printf 'felix situations: the change could not be read: %s could not be read\n' "$t" >&2; return 3 ;;
    esac
  done
  return 1
}

# The two ends of a change (C3.3): prints <base commit><TAB><head commit>. A given RANGE is <base>..<head> as C1 splits it,
# and each half is resolved in the live repository to a commit, the base first. With no RANGE, the head is HEAD and the base is
# the merge base of the main ref and HEAD. Returns 3 with C2's sentence on stderr (<rev> is the half as given) when a half
# names no commit:
#   felix situations: base could not be read: <rev> is not a commit here      (and the same with head)
# and, with no range, in this order: HEAD is not a commit, no main ref names a commit (or git could not be asked, C17.4), or
# the main ref and HEAD share no merge base (the main ref as a full ref name).
felix_situations_range() {   # ROOT [RANGE]
  local root="${1-}" r="${2-}" b h bs hs ref rc
  if [ -z "$r" ]; then
    if ! hs="$(_felix_situations_rev "$root" HEAD)"; then
      printf 'felix situations: head could not be read: HEAD is not a commit here\n' >&2
      return 3
    fi
    ref="$(_felix_situations_mainref "$root")"
    rc=$?
    case "$rc" in
      0) ;;
      1) printf 'felix situations: the change could not be read: no main ref here: neither refs/remotes/origin/HEAD, refs/remotes/origin/main nor refs/heads/main names a commit\n' >&2
         return 3 ;;
      *) return 3 ;;
    esac
    bs="$(_felix_git_rules "$root" merge-base "$ref" "$hs" 2>/dev/null)"
    rc=$?
    case "$rc" in
      0) ;;
      1) bs="" ;;
      *) _felix_situations_fail "reading the merge base"; return 3 ;;
    esac
    if [ -z "$bs" ]; then
      printf 'felix situations: the change could not be read: %s and HEAD share no merge base\n' "$ref" >&2
      return 3
    fi
    printf '%s\t%s\n' "$bs" "$hs"
    return 0
  fi
  b="${r%%..*}"; h="${r#*..}"
  if ! bs="$(_felix_situations_rev "$root" "$b")"; then
    printf 'felix situations: base could not be read: %s is not a commit here\n' "$b" >&2
    return 3
  fi
  if ! hs="$(_felix_situations_rev "$root" "$h")"; then
    printf 'felix situations: head could not be read: %s is not a commit here\n' "$h" >&2
    return 3
  fi
  printf '%s\t%s\n' "$bs" "$hs"
}

# The repository's common git directory, absolute, which a linked worktree and a main checkout share: the source every scratch
# clone is made from (C3.3). Returns 1, printing nothing, when ROOT is no repository.
felix_situations_gitdir() {   # ROOT
  local root="${1-}" g
  g="$(_felix_git_rules "$root" rev-parse --git-common-dir 2>/dev/null)" || return 1
  [ -n "$g" ] || return 1
  case "$g" in /*) ;; *) g="$root/$g" ;; esac
  ( CDPATH='' cd -P -- "$g" 2>/dev/null && pwd -P )
}

# The detector at a recorded tree (C3.2), appended to OUT as the commit, detector and cap lines of the reading. The live
# checkout's tree id is taken as felix probes takes it, but on a copy of the live index kept in the scratch directory (C17.3):
# git refreshes the index it reads, and the live one keeps its bytes and its mtime. (A split index's shared file still gets
# a new mtime: git freshens it on every read, C17.11.2.) With no live index file the id is taken with GIT_INDEX_FILE naming
# an absent file in the scratch, which git reads as an empty index. A live index that cannot be read leaves the id untaken;
# one that can be read and does not copy exits 3 (C17.11.3). Then:
#   the id equals TREE      the detector runs on ROOT: the commit is the live HEAD, or - while HEAD is unborn, and the cap
#                           lines are what the detector names, sorted and unique; detector run
#   the id differs          the detector is not run, the commit is -; detector not-run
#   the id could not be taken (no repository, or git could not read the tree in full)
#                           the detector is not run, the commit is -; detector no-tree (C17.5)
# Returns 3 with a sentence on stderr when the detector failed or OUT cannot be written.
felix_situations_live_detect() {   # ROOT HOME TREE OUT
  local root="${1-}" home="${2-}" tree="${3-}" out="${4-}" scr="${_FELIX_SITUATIONS_SCRATCH:-}" live="" idx sha
  if [ -z "$scr" ]; then _felix_situations_fail "finding the scratch directory"; return 3; fi
  idx="$(git -C "$root" rev-parse --git-path index 2>/dev/null)" || idx=""
  if [ -n "$idx" ]; then
    case "$idx" in /*) ;; *) idx="$root/$idx" ;; esac
    # A live index that cannot be read leaves the tree id untaken (C17.5). One that can, and does not copy, is a scratch
    # write that failed (C17.11.3).
    if [ -e "$idx" ]; then
      if [ ! -r "$idx" ]; then
        idx=""
      elif ! cp "$idx" "$scr/live-index" 2>/dev/null; then
        _felix_situations_fail "copying the live index"; return 3
      fi
    fi
  fi
  if [ -n "$idx" ]; then
    live="$( GIT_INDEX_FILE="$scr/live-index"; export GIT_INDEX_FILE
             felix_tree_id "$root" "$home" 2>/dev/null )" || live=""
  fi
  if [ -z "$live" ]; then
    printf 'commit\t-\ndetector\tno-tree\n' >> "$out" 2>/dev/null || { _felix_situations_fail "writing the recorded reading"; return 3; }
    return 0
  fi
  if [ "$live" != "$tree" ]; then
    printf 'commit\t-\ndetector\tnot-run\n' >> "$out" 2>/dev/null || { _felix_situations_fail "writing the recorded reading"; return 3; }
    return 0
  fi
  sha="$(_felix_situations_rev "$root" HEAD)" || sha="-"
  if ! felix_situations_detect "$root" "$scr/live.caps"; then
    printf 'felix situations: the recorded tree could not be read: the detector failed on this checkout\n' >&2
    return 3
  fi
  printf 'commit\t%s\ndetector\trun\n' "$sha" >> "$out" 2>/dev/null \
    && LC_ALL=C awk '$0 != "" { printf "cap\t%s\n", $0 }' "$scr/live.caps" >> "$out" 2>/dev/null \
    || { _felix_situations_fail "writing the recorded reading"; return 3; }
  return 0
}

# One side read in a scratch clone (C3.3), written to OUT as a reading file with how scratch: SIDE is base or head, SHA the
# commit, SRC the repository's common git directory (absolute). The clone is made under the scratch directory at <scratch>/SIDE,
# shared with SRC and with no checkout and no template, then checked out detached at SHA, both through _felix_git_rules (no
# global or system git config, so no hook, template, filter driver or lazy fetch of the caller's runs) with GIT_NO_LAZY_FETCH
# and stdin from /dev/null. The tree id is taken right after the checkout and before anything runs in the clone, and the
# detector after it, both in that same environment (C17.2). The detector also gets the caller's core.quotePath when its
# configuration sets one, so it lists file names as on the live checkout (C17.11.1). Then every row of the project's
# current probes.tsv runs in the clone, with TMPDIR set to <scratch>/tmp-SIDE and none of the environment that points git
# at another repository, but otherwise the caller's: the probes are the project's commands. The live checkout's edits and
# untracked files are read by neither side, since the clone holds tracked content only. Returns 3 with a sentence on stderr
# when the clone, the checkout, the tree id, the quotePath read or the detector fails, or a file cannot be written.
felix_situations_read_scratch() {   # PROJ HOME SRC SHA SIDE OUT
  local proj="${1-}" home="${2-}" src="${3-}" sha="${4-}" side="${5-}" out="${6-}"
  local scr="${_FELIX_SITUATIONS_SCRATCH:-}" clone tmp tid caps qp qrc
  clone="$scr/$side"; tmp="$scr/tmp-$side"; caps="$scr/$side.caps"
  if [ -z "$scr" ] || [ -z "$src" ] \
     || ! mkdir -p "$tmp" 2>/dev/null \
     || ! GIT_NO_LAZY_FETCH=1 _felix_git_rules "$scr" clone -q --shared --no-checkout --template= -- "$src" "$clone" >/dev/null 2>&1 \
     || ! GIT_NO_LAZY_FETCH=1 _felix_git_rules "$clone" checkout --detach -q "$sha" >/dev/null 2>&1; then
    printf 'felix situations: %s could not be read: the scratch checkout of %s could not be made\n' "$side" "$sha" >&2
    return 3
  fi
  tid="$(_felix_situations_in_rules "$scr" "$tmp" felix_tree_id_on "$clone" "$sha" "$home" 2>/dev/null)" || tid=""
  if [ -z "$tid" ]; then
    printf 'felix situations: %s could not be read: the tree id of %s could not be taken in its scratch checkout\n' "$side" "$sha" >&2
    return 3
  fi
  # The caller's core.quotePath, read with the caller's configuration; status 1 means it sets none (C17.11.1).
  qp="$(git --git-dir="$src" config --get core.quotePath 2>/dev/null)"; qrc=$?
  if [ "$qrc" -gt 1 ]; then _felix_situations_fail "reading the caller's core.quotePath"; return 3; fi
  [ "$qrc" = 0 ] || qp=""
  if ! _felix_situations_in_rules "$scr" "$tmp" _felix_situations_detect_quoted "$qp" "$clone" "$caps"; then
    printf 'felix situations: %s could not be read: the detector failed in its scratch checkout\n' "$side" >&2
    return 3
  fi
  ( unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR
    export TMPDIR="$tmp"
    felix_probes_run "$proj" "$clone" ) > "$out.probes" 2>/dev/null \
    || { _felix_situations_fail "running the $side probes"; return 3; }
  printf 'how\tscratch\ncommit\t%s\ntree\t%s\nstamp\t-\ndetector\trun\n' "$sha" "$tid" > "$out" 2>/dev/null \
    && LC_ALL=C awk '$0 != "" { printf "cap\t%s\n", $0 }' "$caps" >> "$out" 2>/dev/null \
    && LC_ALL=C awk -F'\t' '{ printf "probe\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5 }' "$out.probes" >> "$out" 2>/dev/null \
    || { _felix_situations_fail "writing the $side reading"; return 3; }
  return 0
}
