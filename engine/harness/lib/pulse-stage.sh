# What the pulse commits, what it leaves out and says so, where a verified copy
# is, and what a session start is told about both (audit b06).
#
# Sourced by lib/pulse.sh, which holds the guards and the push. Everything that
# decides what goes into the backup commit lives here: one nested git repository
# or one credential used to stop the whole backup and tell nobody for three days
# (10-02 to 10-12 and again on 10-18), so the rest of memory is committed and
# pushed and the part left out is named, in a line that says NOT backed up, in
# the record, the log, `felix status` and the next session start.

if ! command -v _felix_git_read >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

# `git add -A`, leaving the directories named out, into the index in INDEX (an
# empty INDEX is the repository's own, and only a MODE of --dry-run may be asked
# of that one). The exclusions are `:(exclude,literal)` pathspecs: a nested
# repository that has no commit is refused by git outright ("does not have a
# commit checked out", and nothing is staged), and a name with a glob character in
# it must stay a name.
_felix_pulse_addall() {   # REPO INDEX MODE [DIR...]
  local repo="$1" idx="$2" mode="$3" args d
  shift 3
  args=(add -A)
  [ -z "$mode" ] || args[${#args[@]}]="$mode"
  if [ "$#" -gt 0 ]; then
    args[${#args[@]}]="--"; args[${#args[@]}]="."
    for d in "$@"; do args[${#args[@]}]=":(exclude,literal)$d"; done
  fi
  if [ -n "$idx" ]; then GIT_INDEX_FILE="$idx" git -C "$repo" "${args[@]}"
  else git -C "$repo" "${args[@]}"; fi
}

# The nested git repositories a staging of the work tree would meet: untracked
# directories that hold a repository, in whatever state it is in, as git lists
# them (a trailing slash, and not what is inside). One that has a commit would
# stage as a bare gitlink, and one that has none cannot be staged at all, so
# both are left out of the staging by name (audit b06, M3). The names are left,
# without the slash, in the array _FELIX_PULSE_NESTED. What .gitignore ignores is
# not listed, and a gitlink HEAD already holds is tracked, so neither is new.
# 2 when git could not list them: not asked is not none.
_felix_pulse_nested() {   # REPO
  local repo="$1" p mark=""
  _FELIX_PULSE_NESTED=()
  while IFS= read -r -d '' p; do
    case "$p" in
      $'\037ok') mark=1 ;;
      ?*/)       _FELIX_PULSE_NESTED[${#_FELIX_PULSE_NESTED[@]}]="${p%/}" ;;
    esac
  done < <(git -C "$repo" ls-files -o --exclude-standard -z 2>/dev/null && printf '\037ok\0')
  [ -n "$mark" ] || return 2
  return 0
}

# A scratch index holding what a full staging would stage: the tree given (HEAD's
# when none is), then `git add -A` leaving the directories named out. Its path on
# stdout and 0; 2 and nothing when it could not be made or the add did not finish
# (a tracked named pipe, a corrupt index). The real index is never touched, so a
# person's staged selection survives being asked about. On an unborn branch it
# starts empty by read-tree --empty: a file mktemp made is an index git refuses as
# smaller than expected.
_felix_pulse_scratch() {   # REPO [TREE [DIR...]]
  local repo="$1" tree="${2:-}" tmp
  if [ "$#" -ge 2 ]; then shift 2; else shift; fi
  # A template under $TMPDIR: a bare mktemp on macOS ignores TMPDIR, and the
  # suite points TMPDIR at a fixture to count what is left there.
  local tmpd="${TMPDIR:-/tmp}"
  tmp="$(mktemp "${tmpd%/}/felix-pulse.XXXXXX" 2>/dev/null)" || return 2
  if [ -n "$tree" ]; then
    GIT_INDEX_FILE="$tmp" git -C "$repo" read-tree "$tree" >/dev/null 2>&1 || { rm -f "$tmp"; return 2; }
  elif git -C "$repo" rev-parse --verify -q HEAD >/dev/null 2>&1; then
    GIT_INDEX_FILE="$tmp" git -C "$repo" read-tree HEAD >/dev/null 2>&1
  else
    GIT_INDEX_FILE="$tmp" git -C "$repo" read-tree --empty >/dev/null 2>&1
  fi
  if ! _felix_pulse_addall "$repo" "$tmp" "" "$@" >/dev/null 2>&1; then
    rm -f "$tmp"; return 2
  fi
  printf '%s' "$tmp"
}

# Gitlinks a full staging would newly introduce, one path per line. Empty is
# the good answer, and it is computed WITHOUT touching the real index: on a
# scratch index (the one given, or one made and removed here).
#
# Three rounds of review found three separate defects in the parsing this
# used to do — an awk that rebuilt the record and collapsed runs of spaces so
# two different directories reduced to one key, a .gitmodules cross-check
# whose quoting never matched git's own, and a count that included links
# already in HEAD. The lesson is not "parse more carefully": it is that the
# decision does not need most of what was being parsed.
#
# So: both sides come from `cut -f2-` on the literal tab git puts before a
# path — exact, and identical on both sides, so quoting cannot make them
# disagree — and the .gitmodules cross-check is gone entirely. A submodule
# somebody adds deliberately is refused once and then stops being new the
# moment they commit it, which is a self-resolving nudge rather than a
# permanent latch, and it costs no matching rules that can be wrong.
#
# Returns 2, printing nothing, when the question could not be asked: no scratch
# index, or a `git add -A` into it that did not finish (2026-10-08). A tracked
# named pipe fails that add, and the index it left was HEAD's, so a nested
# repository added beside the pipe read as no new gitlink. Not asked is not no.
_felix_pulse_new_gitlinks() {   # REPO [SCRATCH-INDEX]
  local repo="$1" idx="${2:-}" own="" all head
  if [ -z "$idx" ]; then idx="$(_felix_pulse_scratch "$repo")" || return 2; own=1; fi
  _felix_git_read all env GIT_INDEX_FILE="$idx" git -C "$repo" ls-files -s || { [ -z "$own" ] || rm -f "$idx"; return 2; }
  [ -z "$own" ] || rm -f "$idx"
  all="$(printf '%s\n' "$all" | grep '^160000 ' | cut -f2-)"
  [ -n "$all" ] || return 0
  head="$(git -C "$repo" ls-tree -r HEAD 2>/dev/null | grep '^160000 ' | cut -f2-)"
  printf '%s\n' "$all" | while IFS= read -r p; do
    [ -n "$p" ] || continue
    felix_has_line "$head" "$p" && continue
    printf '%s\n' "$p"
  done
}

# 0 clean, 1 a credential shape in the added lines, 2 not asked: no scanner, or a
# read that did not finish. The added lines of the scratch index against HEAD (or
# of one path of it), as git's text diff shows them, through bin/secret-scan -;
# a file git reads as binary has no added line and is not scanned. What the
# scanner prints is never kept: it prints the line it found. The reason for a 2
# is left in _FELIX_PULSE_WHY.
_felix_pulse_scan() {   # REPO INDEX [PATH]
  local repo="$1" idx="$2" path="${3:-}" scan ps
  scan="$(dirname "${BASH_SOURCE[0]:-$0}")/../bin/secret-scan"
  _FELIX_PULSE_WHY="bin/secret-scan is not here"
  [ -x "$scan" ] || return 2
  GIT_INDEX_FILE="$idx" git --literal-pathspecs -C "$repo" diff --cached --no-ext-diff --no-textconv --no-color \
      --no-renames --ignore-submodules=none -U0 -- ${path:+"$path"} 2>/dev/null \
    | LC_ALL=C awk '/^diff --git / { h = 1; next } h && /^@@ / { h = 0; next } h { next } /^\+/ { print substr($0, 2) }' \
    | "$scan" - >/dev/null 2>&1
  ps=("${PIPESTATUS[@]}")
  case "${ps[2]}" in
    1) return 1 ;;
    0) [ "${ps[0]}${ps[1]}" = 00 ] && return 0
       _FELIX_PULSE_WHY="git did not finish reading the change"; return 2 ;;
  esac
  _FELIX_PULSE_WHY="bin/secret-scan exited ${ps[2]:-?}"
  return 2
}

# The paths of the scratch index that gained a credential, left out of it: named
# one a line in _FELIX_PULSE_FLAGGED, each put back to what HEAD holds (or taken
# out when HEAD has none). 0 for none, 1 for some, 2 when not asked (see
# _felix_pulse_scan). The whole change is read once, and path by path only when
# that finds something.
_felix_pulse_flag() {   # REPO INDEX
  local repo="$1" idx="$2" paths=() p n i=0 mark="" rc nl=$'\n'
  _FELIX_PULSE_FLAGGED=""
  _felix_pulse_scan "$repo" "$idx"; rc=$?
  [ "$rc" = 1 ] || return "$rc"
  while IFS= read -r -d '' p; do
    case "$p" in $'\037ok') mark=1 ;; ?*) paths[${#paths[@]}]="$p" ;; esac
  done < <(GIT_INDEX_FILE="$idx" git -C "$repo" diff --cached --name-only -z --no-renames 2>/dev/null && printf '\037ok\0')
  if [ -z "$mark" ]; then _FELIX_PULSE_WHY="git did not finish listing the change"; return 2; fi
  n="${#paths[@]}"
  while [ "$i" -lt "$n" ]; do
    p="${paths[$i]}"; i=$((i + 1))
    _felix_pulse_scan "$repo" "$idx" "$p"; rc=$?
    case "$rc" in
      2) return 2 ;;
      1) GIT_INDEX_FILE="$idx" git --literal-pathspecs -C "$repo" reset -q -- "$p" >/dev/null 2>&1 \
           || { _FELIX_PULSE_WHY="git could not put $(printf '%s' "$p" | tr '\t\n' '  ') back"; return 2; }
         _FELIX_PULSE_FLAGGED="${_FELIX_PULSE_FLAGGED:+$_FELIX_PULSE_FLAGGED$nl}$(printf '%s' "$p" | tr '\t\n' '  ')" ;;
    esac
  done
  # The whole change said yes and no single path did: the scan is not whole.
  if [ -z "$_FELIX_PULSE_FLAGGED" ]; then _FELIX_PULSE_WHY="the scanner flagged the change as a whole and no single path"; return 2; fi
  return 1
}

# Commits the tree in INDEX, the scratch index the scan read, and never the
# repository's own index (audit b06, M1, M2). A file written after the scan is not
# in that tree, so it is not in the commit; and a commit that fails (a hook, a
# signing key, a lock) leaves the repository's index as it was found, so the next
# run does not read the pulse's own staging as a person's. The repository's index
# follows HEAD only once the commit has been made.
#
# Returns rather than falling through. It used to push anyway: the push
# succeeded because there was nothing new to send, the verification
# passed because both heads were the stale one, and the run's LAST
# line — the one a person skims — read "pushed and verified". A backup
# that has silently stopped must not end on a success sentence.
_felix_pulse_commit() {   # REPO INDEX
  if GIT_INDEX_FILE="$2" git -C "$1" -c user.name=felix-pulse -c user.email=pulse@felix.invalid \
       commit -q -m "pulse: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >/dev/null 2>&1; then
    printf 'backup\tcommitted\n'
    if ! git -C "$1" read-tree HEAD >/dev/null 2>&1; then
      printf 'backup\tcommitted, but git could not bring the index of this memory to the new commit, so the next pulse may read the commit'"'"'s own files as staged by hand; git reset there puts it right\n'
    fi
    return 0
  fi
  printf 'backup\tcommit FAILED; nothing was pushed, and this memory is NOT backed up\n'
  return 1
}

# Commit what the memory repository's working tree holds, leaving out a nested git
# repository (it stages as a bare gitlink and a restore materializes an empty
# directory: the exact disaster-recovery path this feature exists for) and any
# file that gained a credential shape (the pulse pushes memory to a remote, where
# history keeps what it was given). Each left out is named, in a line that says it
# is NOT backed up, and the rest is committed. 0 to go on to the push, 1 to stop
# with a refusal already printed. Called with the status non-empty.
#
# Everything is asked and done on a scratch index, and the commit is that index's
# tree: the one scanned. It starts as the tree of the repository's own index, so
# what a person staged by hand (an ignored file forced in) is read too, and the
# repository's own index is not written until a commit has succeeded, so a refusal
# or a failed commit leaves it exactly as it was found. A person's staged
# selection is theirs: with one, and something to leave out, nothing is committed
# (the pulse does not start acting in a state where it used to stand down) and the
# line says so; the push still runs.
felix_pulse_stage() {   # REPO
  local repo="$1" pre base idx rc lwhy hand=0
  # The tree of the repository's own index, taken first, and whether it is a
  # person's: it is not HEAD's tree (on an unborn branch, not the empty one).
  pre="$(git -C "$repo" write-tree 2>/dev/null)" || pre=""
  if git -C "$repo" rev-parse --verify -q HEAD >/dev/null 2>&1; then
    base="$(git -C "$repo" rev-parse --verify -q 'HEAD^{tree}' 2>/dev/null)" || base=""
  else
    base="$(git -C "$repo" hash-object -t tree /dev/null 2>/dev/null)" || base=""
  fi
  if [ -z "$pre" ] || [ -z "$base" ]; then
    printf 'backup\tgit could not read what is staged here, so nothing was committed, and this memory is NOT backed up\n'
    return 1
  fi
  [ "$pre" = "$base" ] || hand=1
  if ! _felix_pulse_nested "$repo"; then
    printf 'backup\tcould not ask whether a nested repository sits inside memory (git could not list what is untracked), so nothing was committed, and this memory is NOT backed up\n'
    return 1
  fi
  if ! idx="$(_felix_pulse_scratch "$repo" "$pre" ${_FELIX_PULSE_NESTED[@]+"${_FELIX_PULSE_NESTED[@]}"})" || [ -z "$idx" ]; then
    # Which of the two, said: git's own first error line when the stage was
    # what failed, and the scratch index otherwise.
    lwhy="$(_felix_pulse_addall "$repo" "" --dry-run ${_FELIX_PULSE_NESTED[@]+"${_FELIX_PULSE_NESTED[@]}"} 2>&1 >/dev/null | awk '!p && /^(error|fatal): / { print; p = 1 }')"
    printf 'backup\tcould not ask whether a nested repository sits inside memory (%s), so nothing was committed, and this memory is NOT backed up\n' \
      "${lwhy:-no scratch index could be made}"
    return 1
  fi
  _felix_pulse_stage_run "$repo" "$idx" "$hand"; rc=$?
  rm -f "$idx" 2>/dev/null
  return "$rc"
}

_felix_pulse_stage_run() {   # REPO INDEX HAND
  local repo="$1" idx="$2" hand="$3" links lrc=0 frc names tail i n d p
  # Nested repositories left out of the staging by name (_felix_pulse_nested), and
  # any gitlink that got into the scratch index all the same, taken out of it by
  # index-info (which reads git's own quoting back).
  links="$(_felix_pulse_new_gitlinks "$repo" "$idx")" || lrc=$?
  if [ "$lrc" -ne 0 ]; then
    printf 'backup\tcould not ask whether a nested repository sits inside memory (git could not list the staged paths), so nothing was committed, and this memory is NOT backed up\n'
    return 1
  fi
  if [ -n "$links" ]; then
    printf '%s\n' "$links" | while IFS= read -r p; do
      printf '0 0000000000000000000000000000000000000000\t%s\n' "$p"
    done | GIT_INDEX_FILE="$idx" git -C "$repo" update-index --index-info >/dev/null 2>&1 \
      || { printf 'backup\tgit could not leave the nested repository out of what it stages, so nothing was committed, and this memory is NOT backed up\n'; return 1; }
  fi
  # Then the files that gained a credential.
  _felix_pulse_flag "$repo" "$idx"; frc=$?
  if [ "$frc" -eq 2 ]; then
    printf 'backup\tcould not scan what would be committed for credentials (%s), so nothing was committed, and this memory is NOT backed up\n' "$_FELIX_PULSE_WHY"
    return 1
  fi
  names=""; i=0; n="${#_FELIX_PULSE_NESTED[@]}"
  while [ "$i" -lt "$n" ]; do
    d="$(printf '%s' "${_FELIX_PULSE_NESTED[$i]}" | tr '\t\n' '  ')"; i=$((i + 1))
    names="${names:+$names }$d"
  done
  if [ -n "$links" ]; then names="${names:+$names }$(printf '%s\n' "$links" | tr '\n' ' ' | sed 's/ $//')"; fi
  if [ -z "$names" ] && [ "$frc" -eq 0 ]; then
    # Nothing left out: the scanned tree is the commit. The staging was done once,
    # on the scratch index, before the scan. A second `git add -A` here, on the
    # repository's own index, committed whatever the work tree held by then
    # (a key written after the scan) and whatever a person had forced in.
    _felix_pulse_commit "$repo" "$idx"; return $?
  fi
  if [ -n "$names" ]; then
    if [ "$hand" = 1 ]; then tail="and a selection is staged by hand, so nothing was committed and this memory is NOT backed up"
    else tail="so it was left out of this commit and is NOT backed up"; fi
    printf 'backup\ta nested git repository sits inside memory (%s); backed up it would restore EMPTY, %s — move it out, or commit it yourself\n' "$names" "$tail"
  fi
  if [ "$frc" -eq 1 ]; then
    names="$(printf '%s\n' "$_FELIX_PULSE_FLAGGED" | tr '\n' ',' | sed 's/,$//; s/,/, /g')"
    if [ "$hand" = 1 ]; then tail="a selection is staged by hand, so nothing was committed and this memory is NOT backed up"
    else tail="it was left out of this commit and is NOT backed up"; fi
    printf 'backup\ta possible credential was added to %s; %s — take it out, or commit the file yourself\n' "$names" "$tail"
  fi
  [ "$hand" = 0 ] || return 0
  if GIT_INDEX_FILE="$idx" git -C "$repo" diff --no-ext-diff --no-textconv --cached --quiet >/dev/null 2>&1; then
    printf 'backup\tnothing else new to commit\n'; return 0
  fi
  _felix_pulse_commit "$repo" "$idx"
}

# Where the copy a verified push made is, in one word, from what `git remote
# get-url` prints (the address verification reads back from, insteadOf applied):
#   disk     a path on this machine, so the copy is only as far from this disk as
#            whatever syncs that path (iCloud, a mounted share)
#   network  a host: a scheme://, or scp-like host:path
#   unknown  a remote helper (transport::address), or a remote that is not there
# Never the address, which may carry a password. Always 0. A path with a colon
# after a slash (./a:b.git) is a path, as git reads it.
felix_pulse_remote_where() {   # REPO REMOTE
  local url head
  url="$(git -C "$1" remote get-url "$2" 2>/dev/null)" || { printf 'unknown'; return 0; }
  case "$url" in
    '')       printf 'unknown' ;;
    file://*) printf 'disk' ;;
    *://*)    printf 'network' ;;
    *::*)     printf 'unknown' ;;
    /*|./*|../*) printf 'disk' ;;
    *)        head="${url%%/*}"
              case "$head" in *:*) printf 'network' ;; *) printf 'disk' ;; esac ;;
  esac
  return 0
}

# What a session start owes about the pulse and the machine, as paragraphs that
# each begin with a newline, or nothing.
#
# A backup that has silently stopped looks exactly like one that ran: every
# pulse refusal is honest and prints into a log nobody opens. The age is the one
# number that makes a stop observable, on the surface a person reads. And a
# pulse that ran every day and left one part of memory out has an age of zero
# (the rest was pushed), so what it left out is said on the first day, from the
# record, whatever the age. A cloud session's memory dies with the machine, and
# the warning that memory exists in one place cannot fire there.
felix_pulse_session_lines() {   # HOME
  local home="${1:-}" age rec first ep="" utc lines
  [ -n "$home" ] || return 0
  age="$(felix_pulse_backup_age "$home" 2>/dev/null)"
  if [ "${age:-}" = "never" ]; then
    printf '\nThe pulse has run and never once got memory off this disk. Whatever it is\nrefusing, it is in '"'"'felix pulse'"'"' — and until it resolves, every lesson this\nproject has paid for exists in one place.'
  elif [ -n "${age:-}" ] && [ "$age" -ge "${FELIX_BACKUP_STALE_DAYS:-3}" ] 2>/dev/null; then
    printf '\nMemory last reached the remote %s days ago. Every lesson since then lives\non this disk only. See '"'"'felix pulse'"'"' — it says what it refused and why.' "$age"
  fi
  rec="$home/state/pulse.status.tsv"
  if [ -f "$rec" ] && [ -r "$rec" ]; then
    lines="$(LC_ALL=C awk -F'\t' '$1 == "backup" && index($0, "NOT backed up") { print "  " substr($0, 8) }' "$rec" 2>/dev/null)"
    if [ -n "$lines" ]; then
      { IFS= read -r first || :; } 2>/dev/null < "$rec"
      case "$first" in "# ran "*) ep="${first#"# ran "}" ;; esac
      case "$ep" in ''|*[!0123456789]*) ep="" ;; esac
      [ "${#ep}" -le 12 ] || ep=""
      utc=""; [ -z "$ep" ] || utc="$(_felix_status_utc "$ep")"
      printf '\nThe last pulse, at %s, did not back up all of memory:\n%s\nWhat is named there exists on this disk only until it is dealt with. '"'"'felix pulse'"'"' runs the backup again.' \
        "${utc:-a time not recorded}" "$lines"
    fi
  fi
  case "${CLAUDE_CODE_REMOTE:-}" in
    true) printf '\nThis is a cloud session: nothing backs up the memory directory above from here, and unless it sits on storage that outlives this machine, what Felix records in it (lessons, catches, declines, the ledger) is lost with the machine.' ;;
  esac
  return 0
}
