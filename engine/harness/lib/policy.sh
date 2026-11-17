# The merge boundary reads its policy, and the instruments that policy names, from P.
#
# Trust-plane design §4.1 (docs/2026-11-07-trust-plane-design.md): "The authority takes one thing from
# the candidate change: the subject, meaning the revision. It takes everything that judges that subject
# from the authorized policy version." Design step 3 enumerates what the authority reads and moves each
# input to that version. This file is the first slice of that move, for felix_merge_blockers alone; the
# spec is in the memory root, audits/2026-11-08-trust-plane-step3/spec.md, and the inventory that found
# the inputs is docs/2026-11-08-trust-step3-inventory.md.
#
# THE GAP. felix_merge_blockers read every table from the project directory it was handed, which is the
# home's working tree: whatever FELIX_HOME named, and whatever sat uncommitted there. For Felix itself
# the home is a checkout of the repository being merged, so a branch checked out in the home, or a
# worker that pointed FELIX_HOME at its own checkout, was judged by the tables it carried. And every
# command those tables hold (an obligation's applies and evidence contract, a probe's when, command and
# witness) ran `bash -c` in the candidate's checkout, so a script the command names was the candidate's:
# a branch could rewrite the checker that judged it, or the library that checker sources, and pass.
#
# THE RULE (spec S1, S2).
#   - P is the ref the merge judges against (BASE) when the project directory sits in a worktree of the
#     repository being merged, and another repository's refs/remotes/origin/main (or its HEAD, when it
#     has none) when it sits there (a product governed from a Felix home). When the merged repository
#     is the engine's own and BASE holds projects/<name>, P is that, wherever the home is. Otherwise a
#     project directory that no repository holds has no authorized version, and is read from disk.
#   - The tables are read from a snapshot of the project directory as P holds it: regular files only,
#     byte for byte. A BASE that does not hold it is a refusal, never the disk.
#   - A word in command position of a P command that names a regular file P holds in the repository
#     being merged runs as P's copy of that file, with P's whole top-level directory around it, so a
#     script that finds its libraries beside itself finds P's. The working directory stays the
#     candidate's checkout: what the command reads by path is the subject.
#   - Everything made here lives in one felix-policy.* directory under TMPDIR and is removed when the
#     judgement ends.
#
# WHAT THIS DOES NOT BIND, as examples and not the set. A file a P script reads by a path relative to
# the working directory, a mixed file (`make` reading the candidate's Makefile), a runner the scan does
# not know executing its argument and a path built at run time are still the candidate's. A word the
# scan sees but cannot place (inside quotes, after a `$`) refuses instead (S2.1). The partition of every
# path into instrument and subject (spec part 2, E5) is not built. The suite and
# the gate receipt, which judge Felix's own engine, are the candidate's and the session's. A same-user
# process can move refs/remotes/origin/main or name another --base. The step-3 report measures each.
#
# Sourced by escape.sh. Needs resolve.sh (_felix_git_rules).

# Set only by felix_policy_open, in the shell that judges: an inherited value never names a policy
# directory or an instrument.
unset _FELIX_POL_TMP _FELIX_POL_DIR _FELIX_P_TREE _FELIX_P_WORDS

# Every regular file under SHA:PREFIX in ROOT's repository, into DEST, as git stores it (mode kept, no
# symbolic link, no submodule). One git process for the tree, against a scratch repository that borrows
# ROOT's objects and reads no machine-local configuration, the way lib/merge-judge.sh cuts main's engine.
# Its info/attributes unsets the six attributes checkout converts by, which outranks the tree's own
# .gitattributes and the machine's (trust step 3, spec A22 as amended).
# PREFIX names a tree, or a file at the top level. Returns 0, or 1 when it could not.
_felix_policy_copy() {   # ROOT SHA PREFIX DEST
  local root="$1" sha="$2" pre="$3" dest="$4" objs scratch typ mode
  objs="$(git -C "$root" rev-parse --path-format=absolute --git-path objects 2>/dev/null </dev/null)"
  [ -n "$objs" ] && [ -d "$objs" ] || return 1
  typ="$(git -C "$root" cat-file -t "$sha:$pre" 2>/dev/null </dev/null)" || return 1
  if [ "$typ" = blob ]; then
    mode="$(git -C "$root" ls-tree "$sha" -- "$pre" 2>/dev/null </dev/null | LC_ALL=C awk '{ print $1; exit }')"
    case "$mode" in 100644|100755) ;; *) return 1 ;; esac
    mkdir -p "$(dirname "$dest")" || return 1
    git -C "$root" cat-file blob "$sha:$pre" > "$dest" 2>/dev/null </dev/null || return 1
    [ "$mode" = 100755 ] && chmod 755 "$dest"
    return 0
  fi
  [ "$typ" = tree ] || return 1
  scratch="$dest.scratch"
  mkdir -p "$scratch" || return 1
  if ! { _felix_git_rules "$scratch" init -q --template= >/dev/null 2>&1 \
         && mkdir -p "$scratch/.git/objects/info" \
         && printf '%s\n' "$objs" > "$scratch/.git/objects/info/alternates" \
         && mkdir -p "$scratch/.git/info" && printf '* -text -eol -crlf -ident -filter -working-tree-encoding\n' > "$scratch/.git/info/attributes" \
         && _felix_git_rules "$scratch" read-tree "$sha:$pre" >/dev/null 2>&1 \
         && _felix_git_rules "$scratch" checkout-index -a --prefix="$dest/" >/dev/null 2>&1; }; then
    rm -rf "$scratch"; return 1
  fi
  rm -rf "$scratch"
  mkdir -p "$dest" || return 1
  # A symbolic link would read whatever it points at, which P does not hold.
  find "$dest" -type l -exec rm -f {} + 2>/dev/null
  return 0
}

# Which worktree of ROOT's repository holds DIR: the longest worktree path DIR sits under, physical
# paths compared. Asked of the merged repository's own worktree list and never of DIR's git, because
# the index and DIR's own .git are the candidate's to change when the home is the candidate's checkout:
# `git rm --cached` or a .git planted in the project directory must not turn the home's tables into a
# plain directory read from disk (security review of d21f5029; lessons.md, 2026-08-29: ls-files reads
# the index).
_felix_policy_worktree() {   # ROOT DIR -> the worktree's path, or nothing
  local root="$1" dir="$2" w p best=""
  while IFS= read -r -d '' w; do
    case "$w" in "worktree "*) p="${w#worktree }" ;; *) continue ;; esac
    p="$(cd "$p" 2>/dev/null && pwd -P)" || continue
    case "$dir" in "$p"/?*) [ "${#p}" -gt "${#best}" ] && best="$p" ;; esac
  done < <(git -C "$root" worktree list --porcelain -z 2>/dev/null </dev/null)
  [ -n "$best" ] && printf '%s' "$best"
  return 0
}

# git, or git as a repository other than the one being merged reads itself (AWAY 1): under felix merge the object
# store is the merged repository's checked copy (lib/bind.sh), which holds nothing of another repository.
_felix_policy_git() {   # AWAY git-args...
  if [ "$1" = 1 ]; then shift; env -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES git "$@"
  else shift; git "$@"; fi
}

# Where the tables come from for this judgement: sets _FELIX_POL_DIR, and _FELIX_POL_TMP when a
# snapshot was made. Returns 0; or prints one policy blocker line and returns 1 (fail closed).
#
#   - The project directory is inside a worktree of the merged repository: P is BASE, and a BASE that
#     does not hold the directory is a refusal. Nothing on disk, in the index or under the directory's
#     own .git changes that.
#   - It is inside another repository (a product governed from a Felix home): P is that repository's
#     refs/remotes/origin/main, or its HEAD when it has none (the committed tables, never the working
#     tree). A ref that exists and does not hold the directory while HEAD does is a refusal: the policy
#     has not landed. Neither holding it means the directory is not that repository's (a home under a
#     $HOME that is itself a repository), and it is read from disk.
#   - It is in no repository: there is no authorized version, and it is read from disk, as before.
#   - Before all of these: when the merged repository is the engine's own at BASE and BASE holds
#     projects/<the name BASE's .felix gives>, P is BASE there, wherever the home is (spec S1.7). A
#     home FELIX_HOME points at a plain directory of loosened tables, or one the candidate's .felix
#     renamed, otherwise judged Felix's own merge.
#   - "Inside" is asked of the home as it names the directory (spec S1.8): a link at projects/<name>
#     sent the first cut to the link's target on disk, and a .git planted in a product home's
#     projects/ became that home's repository (review round 1).
felix_policy_open() {   # PROJ BASE ROOT
  local proj="${1%/}" base="$2" root="$3" name parent anchor lpath top="" rel="" ref="" sha tmpd bname away=0
  _FELIX_POL_DIR="$1"; _FELIX_POL_TMP=""; _FELIX_P_TREE=""; _FELIX_P_WORDS=""
  name="${proj##*/}"; parent="$(dirname "$proj")"
  # Spec S1.7: the engine's own repository at BASE names its project in BASE's .felix and holds its
  # tables. Neither the home's directory, wherever FELIX_HOME put it, nor the candidate's .felix
  # chooses them.
  if [ -n "$base" ] && command -v felix_self_governed_at >/dev/null 2>&1 \
     && felix_self_governed_at "$root" "$base"; then
    bname="$(git -C "$root" cat-file blob "$base:.felix" 2>/dev/null </dev/null | LC_ALL=C sed -n '1{s/[[:space:]]//g;p;}')"
    case "$bname" in ''|*/*|.|..) bname="" ;; esac
    if [ -n "$bname" ] && [ "$(git -C "$root" cat-file -t "$base:projects/$bname" 2>/dev/null </dev/null)" = tree ]; then
      top="$(cd "$root" 2>/dev/null && pwd -P)" || return 0
      rel="projects/$bname"; ref="$base"; name="$bname"
    fi
  fi
  if [ -z "$rel" ]; then
    [ -d "$proj" ] || return 0
    # Spec S1.8: the home directory's physical path, and below it the path as the home names it. A link
    # at projects/<name> or at projects/ is the home's working tree and does not choose P, and the
    # repository is asked of the home directory, never of projects/ or the project directory, so a .git
    # planted in either is not it.
    if [ "${parent##*/}" = projects ]; then
      anchor="$(cd "$(dirname "$parent")" 2>/dev/null && pwd -P)" || return 0; lpath="$anchor/projects/$name"
    else
      anchor="$(cd "$parent" 2>/dev/null && pwd -P)" || return 0; lpath="$anchor/$name"
    fi
    top="$(_felix_policy_worktree "$root" "$lpath")"
    if [ -n "$top" ]; then
      rel="${lpath#"$top"/}"; ref="$base"
    else
      # Another repository is read from its own objects: under felix merge the object store is the merged
      # repository's checked copy (lib/bind.sh), which holds nothing of this one.
      away=1
      top="$(_felix_policy_git "$away" -C "$anchor" rev-parse --show-toplevel 2>/dev/null </dev/null)" || return 0
      top="$(cd "$top" 2>/dev/null && pwd -P)" || return 0
      case "$lpath" in "$top"/?*) rel="${lpath#"$top"/}" ;; *) return 0 ;; esac
      local onmain="" onhead=""
      [ "$(_felix_policy_git "$away" -C "$top" cat-file -t "refs/remotes/origin/main:$rel" 2>/dev/null </dev/null)" = tree ] && onmain=1
      [ "$(_felix_policy_git "$away" -C "$top" cat-file -t "HEAD:$rel" 2>/dev/null </dev/null)" = tree ] && onhead=1
      if _felix_policy_git "$away" -C "$top" rev-parse --verify --quiet refs/remotes/origin/main >/dev/null 2>&1 </dev/null; then
        ref=refs/remotes/origin/main
        [ -n "$onmain" ] || [ -n "$onhead" ] || return 0
      else
        ref=HEAD
        [ -n "$onhead" ] || return 0
      fi
    fi
  fi
  sha="$(_felix_policy_git "$away" -C "$top" rev-parse --verify --quiet "$ref^{commit}" 2>/dev/null </dev/null)"
  if [ -z "$sha" ]; then
    printf 'policy\ttable\t%s names no commit in %s, so no authorized policy judges this\n' "$ref" "$top"; return 1
  fi
  if [ "$(_felix_policy_git "$away" -C "$top" cat-file -t "$sha:$rel" 2>/dev/null </dev/null)" != tree ]; then
    printf 'policy\ttable\t%s is not at %s, so no authorized policy judges this; the working tree does not stand in for it\n' "$rel" "$ref"; return 1
  fi
  tmpd="${TMPDIR:-/tmp}"
  _FELIX_POL_TMP="$(mktemp -d "${tmpd%/}/felix-policy.XXXXXX" 2>/dev/null)" || _FELIX_POL_TMP=""
  if [ -z "$_FELIX_POL_TMP" ]; then
    printf 'policy\tengine\tno directory could be made under %s for the policy snapshot, so nothing was read from %s\n' "${tmpd%/}" "$ref"; return 1
  fi
  local crc=0
  if [ "$away" -eq 1 ]; then
    ( unset GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES; _felix_policy_copy "$top" "$sha" "$rel" "$_FELIX_POL_TMP/p/$name" ) || crc=1
  else
    _felix_policy_copy "$top" "$sha" "$rel" "$_FELIX_POL_TMP/p/$name" || crc=1
  fi
  if [ "$crc" -ne 0 ]; then
    printf 'policy\tengine\tthe tables could not be copied out of %s, so nothing was read from it\n' "$ref"; return 1
  fi
  _FELIX_POL_DIR="$_FELIX_POL_TMP/p/$name"
  return 0
}

felix_policy_close() {
  [ -z "${_FELIX_POL_TMP:-}" ] || rm -rf "$_FELIX_POL_TMP"
  _FELIX_POL_TMP=""; _FELIX_POL_DIR=""; _FELIX_P_TREE=""; _FELIX_P_WORDS=""
}

# One awk for both jobs over a command: mode `list` prints each word that may name an instrument (in
# command position, or right after an interpreter word, and plain enough to be a path); mode `rewrite`
# prints the command with each such word that is listed in WORDS replaced by the single-quoted path
# under TREE. Quotes are tracked: nothing inside one is a word, and a word that holds one is never
# replaced. It reads the simple grammar only, and stops at the first construct outside it (spec S2.1,
# after review round 1): a command substitution, a backquote, a brace (a group, `${`, `-I{}`), `[[`,
# `case`, an array literal `=(`, a process substitution, a here-document, an option or a redirection
# right after an interpreter word (`bash -n x`), a wrapper (`xargs`, `env`, ...). Nothing from there on
# is rewritten: a guess there read subjects from P (`xargs -I{} grep {} file`, a regex inside "$(...)").
# FAIL CLOSED (spec S2.1, after the security review of round 1). Stopping left the candidate's
# instrument running under a P command (`bash -e tools/check-fx`, `{ tools/check-fx; }`), so in list
# mode deep() reads the rest of the command again, from the start of the simple command the stop is
# in, with the constructs as bash reads them, and prints `?PATH` for each word from the stop on that
# could still run as an instrument; a quoted or expanded word in command position is printed the same
# way. felix_policy_instruments refuses the judgement when one names a regular file P holds. An
# interpreter met as an argument (`chronic bash x`) runs the word after it; an interpreter given no
# script reads one from standard input (`cat x | bash`), so every path in that command is listed.
# Read through ENVIRON, never -v: -v takes no newline in BWK awk and reads a backslash as an escape.
_felix_p_scan() {   # MODE CMD [WORDS TREE]
  _FPS_M="$1" _FPS_S="$2" _FPS_W="${3:-}" _FPS_T="${4:-}" LC_ALL=C awk '
    function plain(w) { return w !~ /["'"'"'$\\*?[`]/ && w !~ /^[\/~-]/ && w !~ /(^|\/)\.\.(\/|$)/ && w != "" }
    function bare(w) { sub(/^\.\//, "", w); return w }
    function put(r) { if (!(r in seen)) { seen[r] = 1; print "?" r } }
    # Each relative path with a / in T, read without its quotes; ALL takes T whole, with or without a /.
    function sus(t, all,   k, m, a, r) {
      gsub("[\"\047\\\\]", "", t)
      if (all == 1) { while (substr(t, 1, 2) == "./") t = substr(t, 3)
                 if (t != "" && t !~ /^[\/~-]/ && t !~ /[][[:space:]$*?`(){}<>|&;=]/ && t !~ /(^|\/)\.\.(\/|$)/) put(t)
                 return }
      m = split(t, a, /[^A-Za-z0-9._\/+@%,-]+/)
      for (k = 1; k <= m; k++) { r = a[k]; sub(/^-+/, "", r); while (substr(r, 1, 2) == "./") r = substr(r, 3)
        if (r != "" && substr(r, 1, 1) != "/" && (all == 2 || index(a[k], "/")) && r !~ /(^|\/)\.\.(\/|$)/) put(r) }
    }
    # An interpreter by name, however it is spelled: quoted, escaped, by absolute path, or versioned.
    function isrn(w) { gsub("[\"\047\\\\]", "", w); if (substr(w, 1, 1) == "/") sub(/^.*\//, "", w)
      return (w in rinterp) || w ~ /^((ba|z|da|k|mk|a|po)?sh|python|pypy|perl|ruby|node|php|lua|tclsh|osascript)[0-9.]*$/ }
    # One word of command frame F is complete: decide what it is in the grammar deep() reads.
    function fin(f,   w, st, k) {
      w = Dw[f]; st = Dws[f]; Dw[f] = ""; Dws[f] = 0
      if (w == "" || Dx[f] == "A") return
      if (hd == -1) { hdl = w; hd = 1; return }
      if (w ~ /^[0-9]*<</ && w !~ /^[0-9]*<<</) { k = w; sub(/^[0-9]*<<-?/, "", k); if (k == "") hd = -1; else { hdl = k; hd = 1 }; return }
      if (Dcs[f] == 1) { Dcs[f] = 2; return }
      if (Dcs[f] == 2) { Dcs[f] = (w == "in") ? 3 : 0; return }
      if (Dcs[f] == 3) { if (w == "esac") { Dcs[f] = 0; Dc[f] = 0 }; return }
      if (Dbr[f]) { if (w == "]]") Dbr[f] = 0; return }
      if (Dop[f] && isrn(w)) { Dop[f] = 0; Dsp[f] = 0; Da[f] = 1; return }
      if (Dop[f]) { if (st >= B) { if (Dop[f] == 2 && w !~ /^-/ && w !~ /^[0-9]*[<>]/) { sus(w, 1); if (Dcc[f]) sus(w, (w ~ /(^|[^A-Za-z0-9_.\/-])((ba|z|da|k)?sh|python[0-9.]*|perl|ruby|node)([^A-Za-z0-9_.\/-]|$)/) ? 2 : 0); Dop[f] = 1 }; sus(w, 0) }
                    else if (w !~ /^-/) Dop[f] = 1
                    return }
      if (Da[f]) { if (w ~ /^[0-9]*[<>]/) return
                   if (w ~ /^-/) { Dsp[f] = (Da[f] == 1 && w != "-c"); Dcc[f] = (w == "-c"); Da[f] = 0; Dop[f] = 2; return }
                   Da[f] = 0; if (st >= B) sus(w, 1); return }
      if (!Dc[f]) { if (isrn(w)) Da[f] = 3; return }
      if (Dcs[f] == 4 && w == "esac") { Dcs[f] = 0; Dc[f] = 0; return }
      if (w ~ /^[A-Za-z_][A-Za-z0-9_]*\+?=/ || (w in reserved) || w == "{" || w == "}") return
      Dc[f] = 0
      if (w == "[[") { Dbr[f] = 1; return }
      if (w == "case") { Dcs[f] = 1; return }
      if (isrn(w)) { Da[f] = 1; return }
      if (w in interp) { Da[f] = 2; return }
      if (w in wrap) { Dop[f] = 1; return }
      if (st >= B) sus(w, 0)
      if (w ~ /[$`]/) Da[f] = 1
    }
    function push(x, o) { d++; Dx[d] = x; Do[d] = o; Dc[d] = (x == "P" || x == "B"); Da[d] = 0; Dop[d] = 0; Dsp[d] = 0; Dcc[d] = 0; Dbr[d] = 0; Dcs[d] = 0; Dw[d] = ""; Dws[d] = 0 }
    function own(c) { if (Dws[o] == 0) Dws[o] = i; Dw[o] = Dw[o] c }
    # Read s from A with subshells, substitutions, groups, case and here-documents, and put each word at or
    # after B that sits where a command, an interpreter'"'"'s script, or a wrapper'"'"'s argument does.
    function deep(A, b,   c, e, k, ln, z) {
      B = b; d = 0; hd = 0; push("T", 0); Dc[1] = 1; i = A
      while (i <= n) {
        c = substr(s, i, 1)
        if (Dx[d] == "D") { o = Do[d]
          if (c == "\\") { own(substr(s, i, 2)); i += 2; continue }
          if (c == "\"") { own(c); d--; i++; continue }
          if (c == "$" && substr(s, i + 1, 1) == "(") { own("$()"); push("P", d); i += 2; continue }
          if (c == "`") { own("``"); push("B", d); i++; continue }
          own(c); i++; continue }
        o = d
        if (c == "\n" && hd == 1) { fin(o); z = hdl; gsub("[\"\047\\\\]", "", z); i++
          while (i <= n) { e = index(substr(s, i), "\n"); ln = e ? substr(s, i, e - 1) : substr(s, i); i = e ? i + e : n + 1
                           k = ln; sub(/^\t+/, "", k); if (k == z) break; if (i - length(ln) - 1 >= B) sus(ln, 0) }
          hd = 0; Dc[o] = 1; Da[o] = 0; Dop[o] = 0; continue }
        if (c == " " || c == "\t") { fin(o); i++; continue }
        if (c == "#" && Dw[o] == "") { e = index(substr(s, i), "\n"); i = e ? i + e - 1 : n + 1; continue }
        if (c == "\047") { e = index(substr(s, i + 1), "\047"); if (!e) e = n - i + 1; own(substr(s, i, e + 1)); i += e + 1; continue }
        if (c == "\"") { own(c); push("D", o); i++; continue }
        if (c == "\\") { own(substr(s, i, 2)); i += 2; continue }
        if (c == "$" && substr(s, i + 1, 1) == "(") { own("$()"); push("P", o); i += 2; continue }
        if (c == "$" && substr(s, i + 1, 1) == "{") { e = index(substr(s, i), "}"); if (!e) e = n - i + 1; own(substr(s, i, e)); i += e; continue }
        if (c == "`") { if (Dx[o] == "B") { fin(o); if (Da[o] == 1 || Dsp[o]) sdi = 1; d--; i++; continue }; own("``"); push("B", o); i++; continue }
        if (c == "(") {
          if (Dcs[o] == 3) { i++; continue }
          if (Dw[o] ~ /=$/) { own("()"); push("A", o); i++; continue }
          if (Dw[o] ~ /[<>]$/) { own("()"); push("P", o); i++; continue }
          fin(o); push("P", o); i++; continue }
        if (c == ")") {
          if (Dcs[o] == 3) { fin(o); Dcs[o] = 4; Dc[o] = 1; i++; continue }
          fin(o); if (Da[o] == 1 || Dsp[o]) sdi = 1
          if (Dx[o] == "P" || Dx[o] == "A") { d--; i++; continue }
          Dc[o] = 0; Da[o] = 0; Dsp[o] = 0; i++; continue }
        if (c == ";" || c == "&" || c == "|" || c == "\n") {
          if (c == "&" && Dw[o] ~ /[<>]$/) { own(c); i++; continue }
          fin(o)
          if (Dcs[o] == 3 && c == "|") { i++; continue }
          if (Dbr[o] && (c == "&" || c == "|")) { i++; continue }
          if (Da[o] == 1 || Dsp[o]) sdi = 1
          if (c == ";" && Dcs[o] == 4 && index(";&", substr(s, i + 1, 1))) { Dcs[o] = 3; i += 2; if (substr(s, i, 1) == "&") i++; continue }
          Dc[o] = 1; Da[o] = 0; Dop[o] = 0; Dsp[o] = 0; i++; continue }
        own(c); i++
      }
      while (d > 0) { if (Dx[d] != "D") { fin(d); if (Da[d] == 1 || Dsp[d]) sdi = 1 }; d-- }
    }
    BEGIN {
      mode = ENVIRON["_FPS_M"]; s = ENVIRON["_FPS_S"]; wl = ENVIRON["_FPS_W"]; tree = ENVIRON["_FPS_T"]
      nw = split(wl, arr, "\n"); for (k = 1; k <= nw; k++) if (arr[k] != "") listed[arr[k]] = 1
      split("then do else elif if while until ! time", rw, " "); for (k in rw) reserved[rw[k]] = 1
      split("bash sh zsh dash ksh python python3 perl ruby node . source exec", iw, " "); for (k in iw) interp[iw[k]] = 1
      split("bash sh zsh dash ksh python python3 perl ruby node", rv, " "); for (k in rv) rinterp[rv[k]] = 1
      split("env xargs timeout nice nohup command builtin sudo stdbuf find eval setsid ionice flock chronic parallel watch doas chroot unbuffer", ww, " "); for (k in ww) wrap[ww[k]] = 1
      n = length(s); out = ""; i = 1; cmd = 1; after = 0; stop = 0; from = 0; cstart = 1
      while (i <= n) {
        c = substr(s, i, 1)
        if (c == " " || c == "\t") { out = out c; i++; continue }
        p = substr(out, length(out), 1)
        if (c == "`" || c == "{" || c == "}") { stop = 1; from = i; break }
        if (c == "(" && (p == "=" || p == "<" || p == ">")) { stop = 1; from = i; break }
        if (c == "&" && (p == ">" || p == "<")) { out = out c; i++; continue }
        if (index(";|&()\n", c)) { if (after && aftr) sdi = 1; out = out c; i++; if (c != ")") { cmd = 1; after = 0; cstart = i }; continue }
        w = ""; q = 0; ws = i
        while (i <= n) {
          c = substr(s, i, 1)
          if (c == "\047") { e = index(substr(s, i + 1), "\047"); if (!e) { w = w substr(s, i); i = n + 1; q = 1; break }
                             w = w substr(s, i, e + 1); i += e + 1; q = 1; continue }
          if (c == "\"") { j = i + 1
                           while (j <= n && substr(s, j, 1) != "\"") {
                             d = substr(s, j, 1)
                             if (d == "\\") { j += 2; continue }
                             if (d == "`" || (d == "$" && substr(s, j + 1, 1) == "(")) { stop = 1; break }
                             j++
                           }
                           if (stop) break
                           w = w substr(s, i, j - i + 1); i = j + 1; q = 1; continue }
          if (c == "\\") { w = w substr(s, i, 2); i += 2; q = 1; continue }
          if (c == "`" || c == "{" || c == "}" || (c == "$" && substr(s, i + 1, 1) == "(")) { stop = 1; break }
          if (c == " " || c == "\t" || index(";|&()\n", c)) break
          w = w c; i++
        }
        if (stop) { from = ws; break }
        if ((cmd && !q && (w == "[[" || w == "case" || (w in wrap))) || w ~ /^<</ || (after && !q && w ~ /^(-|[0-9]*[<>])/) \
            || (!cmd && !after && isrn(w)) || (cmd && w !~ /^[A-Za-z_][A-Za-z0-9_]*=/ && (q || w ~ /[$`]/))) { stop = 1; from = ws; break }
        r = w
        if (cmd && w ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { out = out w; continue }
        if (cmd && !q && (w in reserved)) { out = out w; continue }
        if (cmd && !q && ((w in interp) || isrn(w))) { out = out w; cmd = 0; after = 1; aftr = isrn(w); continue }
        hit = (cmd && !q && plain(w) && index(w, "/") && bare(w) != "") || (after && !q && plain(w))
        if (!hit && mode == "list" && (cmd || after) && (q || w ~ /[$\\]/)) sus(w, after)
        if (hit && mode == "list") print bare(w)
        if (hit && mode == "rewrite" && (bare(w) in listed)) r = "\047" tree "/" bare(w) "\047"
        out = out r; cmd = 0; after = 0
      }
      if (stop) out = out substr(s, from)
      if (!stop && after && aftr) sdi = 1
      if (stop && mode == "list") deep(cstart, from)
      if (sdi && mode == "list") sus(s, 2)
      if (mode == "rewrite") printf "%s", out
    }'
}

# The instruments P's commands name: every such word P holds as a regular file in ROOT's repository at
# BASE, with its top-level directory (or itself, at the top) copied into the snapshot's tree. Sets
# _FELIX_P_TREE and _FELIX_P_WORDS. Returns 0, or prints one policy blocker line and returns 1, which
# it also does for a `?PATH` the scan could not place that names a regular file P holds (fail closed).
felix_policy_instruments() {   # ROOT BASE
  local root="$1" base="$2" sha cmds w u words="" tops="" t mode tmpd nl='
'
  [ -n "${_FELIX_POL_DIR:-}" ] || return 0
  sha="$(git -C "$root" rev-parse --verify --quiet "$base^{commit}" 2>/dev/null </dev/null)" || sha=""
  [ -n "$sha" ] || { printf 'policy\tengine\t%s names no commit here, so no instrument was taken from it\n' "$base"; return 1; }
  cmds="$( { [ -f "$_FELIX_POL_DIR/obligations.tsv" ] && LC_ALL=C grep -vE '^[[:space:]]*(#|$)' "$_FELIX_POL_DIR/obligations.tsv" | LC_ALL=C cut -f4,5
             [ -f "$_FELIX_POL_DIR/probes.tsv" ] && LC_ALL=C grep -vE '^[[:space:]]*(#|$)' "$_FELIX_POL_DIR/probes.tsv" | LC_ALL=C cut -f3,4,5
           } 2>/dev/null | LC_ALL=C tr '\t' '\n')"
  while IFS= read -r t; do
    [ -n "$t" ] && [ "$t" != "-" ] || continue
    while IFS= read -r w; do
      [ -n "$w" ] || continue
      case "$nl$words$nl" in *"$nl$w$nl"*) continue ;; esac
      u="${w#\?}"
      mode="$(git -C "$root" ls-tree "$sha" -- "$u" 2>/dev/null </dev/null | LC_ALL=C awk -F'\t' -v p="$u" '$2 == p { split($1, m, " "); print m[1] " " m[2]; exit }')"
      case "$mode" in "100644 blob"|"100755 blob") ;; *) continue ;; esac
      if [ "$u" != "$w" ]; then
        printf 'policy\tengine\ta command in the tables %s holds names %s where P'"'"'s copy cannot be put in its place, so the candidate'"'"'s own file would run as the instrument; write that command so %s is in command position and outside a substitution, group, case, wrapper or interpreter option (spec S2.1)\n' "$base" "$u" "$u"
        return 1
      fi
      words="${words:+$words$nl}$w"
      case "$w" in */*) t="${w%%/*}" ;; *) t="$w" ;; esac
      case "$nl$tops$nl" in *"$nl$t$nl"*) ;; *) tops="${tops:+$tops$nl}$t" ;; esac
    done <<EOF
$(_felix_p_scan list "$t")
EOF
  done <<EOF
$cmds
EOF
  [ -n "$words" ] || return 0
  # The instruments are the merged repository's, at BASE, wherever the tables came from: a home that
  # is a plain directory made no snapshot, and its commands still run P's scripts.
  if [ -z "${_FELIX_POL_TMP:-}" ]; then
    tmpd="${TMPDIR:-/tmp}"
    _FELIX_POL_TMP="$(mktemp -d "${tmpd%/}/felix-policy.XXXXXX" 2>/dev/null)" || _FELIX_POL_TMP=""
    [ -n "$_FELIX_POL_TMP" ] || { printf 'policy\tengine\tno directory could be made under %s for the instruments P names\n' "${tmpd%/}"; return 1; }
  fi
  case "$_FELIX_POL_TMP" in *"'"*) printf 'policy\tengine\tthe policy directory %s holds a quote, so no instrument can be named from it\n' "$_FELIX_POL_TMP"; return 1 ;; esac
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    _felix_policy_copy "$root" "$sha" "$t" "$_FELIX_POL_TMP/tree/$t" \
      || { printf 'policy\tengine\t%s could not be copied out of %s, so the instruments P names were not taken from P\n' "$t" "$base"; return 1; }
  done <<EOF
$tops
EOF
  _FELIX_P_TREE="$_FELIX_POL_TMP/tree"; _FELIX_P_WORDS="$words"
  return 0
}

# A P command as the merge boundary runs it: unchanged unless felix_policy_instruments named instruments.
_felix_p_cmd() {   # CMD
  if [ -n "${_FELIX_P_TREE:-}" ] && [ -n "${_FELIX_P_WORDS:-}" ]; then
    _felix_p_scan rewrite "$1" "$_FELIX_P_WORDS" "$_FELIX_P_TREE"
  else
    printf '%s' "$1"
  fi
}
