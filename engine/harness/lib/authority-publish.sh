# The drop: one git bundle the authority's login can read, written by a worker's login.
#
# Trust-plane step 4, stage 1, the setup slice (0.49.351; P1 to P6 of its spec). `felix authority publish [--to
# DIR] [--from REPO]` is run by a worker's login, the founder's own today. It writes DIR/source.bundle, which the
# authority's login fetches as its `source` row and from which authority-engine copies the engine of a commit the
# founder names in full.
#
# THE DROP IS NOT TRUSTED, AND DOES NOT NEED TO BE (P6). Any worker can replace it. The authority reads it as
# input: each object is checked as it is fetched (fetch.fsckObjects), a commit it names counts only as the founder
# names it, and the one code run out of it is the engine of the commit he names by its whole id, whose bytes that
# id fixes. So nothing here checks who wrote the bundle, and DIR is left readable by every login on purpose.
#
# WHAT IT READS: the repository at REPO and nothing of the caller's git environment (each GIT_ variable is
# unset, as felix_authority_gitenv does, so REPO alone decides which repository is read). NOT READ: any
# authority's home or authority.conf; this command makes none and needs none.
#
# Bash 3.2. No project is named here.

# The rows of P3: each ref under refs/heads/, and refs/remotes/origin/main when it is there. No tag, no other
# remote's ref, no stash, no note: the authority's source-main is one of these two, and nothing else of a
# worker's repository is the authority's to hold. Printed as "ID REF", one a line.
_fap_refs() {   # REPO
  git -C "$1" for-each-ref --format='%(objectname) %(refname)' refs/heads/ refs/remotes/origin/main 2>/dev/null \
    | LC_ALL=C awk '{ r = substr($0, index($0, " ") + 1) } index(r, "refs/heads/") == 1 || r == "refs/remotes/origin/main"'
}

# Returns 0 and prints P5's seven lines, or returns 1 or 2 with _FA_WHY (felix prints it after "felix: ").
# Every refusal comes before DIR is made and before anything is written in it.
felix_authority_publish() {   # DIR|"" REPO|""
  local to="$1" from="$2" up refs k main om sm tmp n shown LC_ALL=C
  local -a names=()
  _FA_WHY=""
  # P1. The directory: --to, or /Users/Shared/felix-authority where /Users/Shared is a directory.
  if [ -z "$to" ]; then
    [ -d /Users/Shared ] || { _FA_WHY="name the directory to publish to with --to"; return 2; }
    to=/Users/Shared/felix-authority
  fi
  case "$to" in /*) ;; *) _FA_WHY="--to names a directory that is not an absolute path"; return 1 ;; esac
  case "$to" in *[!\ -~]*) _FA_WHY="--to names a path with a byte outside printable ASCII"; return 1 ;; esac
  while :; do case "$to" in /) break ;; */) to="${to%/}" ;; *) break ;; esac; done
  up="${to%/*}"; [ -n "$up" ] || up=/
  if [ -e "$to" ] || [ -L "$to" ]; then
    [ -d "$to" ] && [ ! -L "$to" ] || { _FA_WHY="$(_fa_show "$to") is not a directory"; return 1; }
    # The authority's login reads the drop as "other": a directory it cannot read and search hides the drop.
    [ -n "$(find "$to" -prune -perm -005 2>/dev/null)" ] || { _FA_WHY="$(_fa_show "$to") cannot be read by another login"; return 1; }
  else
    [ -d "$up" ] || { _FA_WHY="$(_fa_show "$up") is not a directory"; return 1; }
  fi
  # P2. The repository: REPO, or the current directory. Shown as given, escaped by section 0's rule, as DIR is
  # (review F6).
  [ -n "$from" ] || from="$PWD"
  shown="$(_fa_show "$from")"
  git -C "$from" rev-parse --git-dir >/dev/null 2>&1 || { _FA_WHY="$shown is not inside a git repository"; return 1; }
  refs="$(_fap_refs "$from")"
  k="$(printf '%s\n' "$refs" | LC_ALL=C awk 'index($2, "refs/heads/") == 1 { n++ } END { print n + 0 }')"
  [ "$k" -gt 0 ] || { _FA_WHY="$shown has no branch to publish"; return 1; }
  main="$(printf '%s\n' "$refs" | LC_ALL=C awk '$2 == "refs/heads/main" { print $1; exit }')"
  om="$(printf '%s\n' "$refs" | LC_ALL=C awk '$2 == "refs/remotes/origin/main" { print $1; exit }')"
  while IFS= read -r n; do [ -z "$n" ] || names[${#names[@]}]="${n#* }"; done <<EOF
$refs
EOF
  # P1. Made one level, 755 whatever the umask: the authority's login reads it as another login.
  if [ ! -d "$to" ]; then
    mkdir -- "$to" 2>/dev/null && chmod 755 "$to" || { _FA_WHY="the bundle could not be written in $(_fa_show "$to")"; return 1; }
  fi
  # P4. Written whole under a name of this process's, then renamed: a reader sees the old bundle or the new one.
  # A directory (or a link to one) at source.bundle would take the rename into itself, so it is a failure to write.
  # git bundle writes through its own lock file beside the name it is given; both are removed on a failure.
  tmp="$to/.source.bundle.$$"
  if [ -d "$to/source.bundle" ] \
     || ! git -C "$from" bundle create -q "$tmp" "${names[@]}" >/dev/null 2>&1 \
     || ! chmod 644 "$tmp" 2>/dev/null || ! mv -f "$tmp" "$to/source.bundle" 2>/dev/null; then
    rm -f "$tmp" "$tmp.lock" 2>/dev/null
    _FA_WHY="the bundle could not be written in $(_fa_show "$to")"; return 1
  fi
  # P5.
  sm=-
  if [ -n "$om" ]; then sm=refs/remotes/origin/main; elif [ -n "$main" ]; then sm=refs/heads/main; fi
  n="$(wc -c < "$to/source.bundle" 2>/dev/null | tr -d ' ')"
  printf 'published: %s\nbytes: %s\nbranches: %s\nmain: %s\norigin-main: %s\nsource: %s\nsource-main: %s\n' \
    "$(_fa_show "$to/source.bundle")" "${n:-?}" "$k" "${main:--}" "${om:--}" "$(_fa_show "$to/source.bundle")" "$sm"
}
