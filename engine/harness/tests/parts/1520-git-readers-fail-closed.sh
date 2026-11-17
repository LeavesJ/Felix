printf '\ngit readers fail closed on a tree they cannot read\n'
# Written blind, from the contract alone and before any implementation existed:
# "an engine read of the working tree that git could not complete is unknown,
# never an answer" (felix-home, 2026-10-08, against origin/main 6fe5f986). A
# tracked path that is a pipe, a socket or a mode-000 file makes every content
# diff exit 128 having printed only the paths that sort before it, and a corrupt
# index stops them all; `add -A` stages nothing; `status` and `--name-only`
# still list the pipe and exit 0. On origin/main every reader below sent git's
# stderr to /dev/null and ignored its status, so what it hashed or scanned was
# whatever git printed before it died. The rule: a read git could not complete
# has not answered, and the tree or the change is unknown. The clause each
# assertion serves is named at its end, in the contract's own letters (T tree
# identity, S the stop hooks, R the diff readers, E their consumers, X
# secret-scan, P the pulse, D the digest); the ones marked "as today" and the
# controls pass on origin/main by design, as the behaviour that must not move.
#
# Every fixture is a repository of its own under one directory, with a Felix
# home and a memory of its own, so nothing here reaches another section and
# nothing another section left behind reaches here. Each pipe is made by
# unlinking the tracked file and putting a fifo in its place. Every call that
# can meet one runs under a time limit (perl's alarm, since macOS ships no
# timeout binary), so a reader that blocks on a pipe is a FAIL here rather than
# a suite that never ends; and each pipe is released and removed once its
# assertions have run. When a fixture cannot be built, every assertion resting
# on it says so as a FAIL rather than falling silent.
GRF="$(mktemp -d "$TMP/grf.XXXXXX")"; GRF="$(cd "$GRF" && pwd -P)"
GRFH="$GRF/home"; GRFM="$GRF/memory"; GRFP="$GRFH/projects/grf"
mkdir -p "$GRFP" "$GRFM/grf"
cat > "$GRFP/project.json" <<'EOF'
{
  "name": "grf",
  "remote_match": "example.invalid/grf-marker-only",
  "gate": "true"
}
EOF
printf '# grf\n' > "$GRFP/CLAUDE.md"
# The widget's probe row, so a green receipt carries an epoch and can be current.
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$GRFP/probes.tsv"
# No red row, so a tier this table computes is never red on its own and a
# scope verdict here is decided by what could be read. deps.txt carries a
# channel and a confine clause, for E3: a floor raised in place is confined.
{ printf 'green\tpath\t^docs/\tdocumentation\n'
  printf 'yellow\tpath\t^deps\\.txt$\ta dependency floor\tpublish\t^[-+]lib[a-z]*>=[0-9.]+$\n'
} > "$GRFP/risk.tsv"
printf 'unit\t^src\t^tests?/\tcode changes need a test\n' > "$GRFP/evidence.tsv"

_grf_git() { git -c user.name=grf -c user.email=grf@example.invalid -c commit.gpgsign=false "$@"; }
# A repository whose one commit tracks .felix, A.txt, deps.txt,
# projects/x/deny.tsv, src.txt and zz.txt, which is also their sort order: a
# pipe at A.txt or projects/x/deny.tsv sorts before an edit to src.txt, and one
# at zz.txt after it. GRR names it; when it cannot be made, GRR names a
# directory that does not exist, so nothing below writes anywhere else, and
# _grf_fx says why for every assertion that rests on it.
_grf_fx=""
_grf_new() {   # tag [branch]
  local d
  _grf_fx=""
  d="$(mktemp -d "$GRF/$1.XXXXXX")" \
    && ( _fx_cd "$d" && git init -q -b "${2:-main}" && mkdir -p projects/x \
         && printf 'a\n' > A.txt && printf 'liba>=1.0\n' > deps.txt && printf 'deny\n' > projects/x/deny.tsv \
         && printf 'one\ntwo\n' > src.txt && printf 'z\n' > zz.txt && printf 'grf\n' > .felix \
         && git add -A && _grf_git commit -qm base ) >/dev/null 2>&1 \
    && GRR="$(cd "$d" && pwd -P)" && return 0
  GRR="$GRF/missing-$1"; _grf_fx="the repository for $1 could not be made"
}
_grf_commit() { ( _fx_cd "$1" && git add -A && _grf_git commit -qm "$2" ) >/dev/null 2>&1 \
                  || { [ -n "$_grf_fx" ] || _grf_fx="a commit in $1 failed"; }; }
# A tracked path replaced by a pipe, and the check that it is one.
_grf_pipe() {   # repo path
  unlink "$1/$2" 2>/dev/null; mkfifo "$1/$2" 2>/dev/null
  [ -n "$_grf_fx" ] && return 0
  if [ ! -p "$1/$2" ]; then _grf_fx="$2 in $1 is not a pipe"
  elif [ -z "$(git -C "$1" ls-files -- "$2" 2>/dev/null)" ]; then _grf_fx="$2 in $1 is not tracked"; fi
}
# Anything waiting on the pipe is let go before it is removed: a reader stuck
# in open() gets a writer and then end of file, a writer gets a reader.
_grf_unpipe() {   # repo path
  [ -p "$1/$2" ] || return 0
  perl -e 'use Fcntl; sysopen(my $r, $ARGV[0], O_RDONLY|O_NONBLOCK); sysopen(my $w, $ARGV[0], O_WRONLY|O_NONBLOCK); close $w if $w; close $r if $r' "$1/$2" 2>/dev/null
  unlink "$1/$2" 2>/dev/null
}
_grf_corrupt() {   # repo
  printf 'garbage' > "$1/.git/index" 2>/dev/null
  [ -n "$_grf_fx" ] && return 0
  git -C "$1" status --porcelain >/dev/null 2>&1 && _grf_fx="the index in $1 still reads after it was overwritten"
  git -C "$1" rev-parse --verify -q 'main^{commit}' >/dev/null 2>&1 || _grf_fx="main does not resolve in $1"
}
_grf_is()  { if [ -n "$_grf_fx" ]; then bad "$1" "the fixture was not built: $_grf_fx"; else is "$1" "$2" "$3"; fi; }
_grf_has() { if [ -n "$_grf_fx" ]; then bad "$1" "the fixture was not built: $_grf_fx"; else has "$1" "$2" "$3"; fi; }
_grf_lacks() {
  if [ -n "$_grf_fx" ]; then bad "$1" "the fixture was not built: $_grf_fx"
  else case "$2" in *"$3"*) bad "$1" "[$2] holds [$3]" ;; *) ok "$1" ;; esac; fi
}
_grf_nz() { if [ "$1" -ne 0 ]; then printf 'non-zero'; else printf 'exit 0'; fi; }
_grf_n1() { printf '%s\n' "$1" | awk -F'\t' -v k="$2" '$1 == k { n++ } END { print n + 0 }'; }
_grf_blocked() { case "$1" in *'"decision"'*'"block"'*) printf 'block' ;; *) printf 'no block' ;; esac; }

# A library call in a shell of its own under a time limit: seconds, then the
# snippet, which sees the harness as $1 and the arguments after it. The shell
# options are the snippet's to set, and it sets them.
_grf_sh() {
  local s="$1" c="$2"; shift 2
  FELIX_HOME="$GRFH" FELIX_MEMORY="$GRFM" \
    perl -e 'alarm shift; exec @ARGV or exit 127' "$s" bash -c "$c" _ "${GRF_HARNESS:-$FROOT/harness}" "$@"
}
_grf_tid()   { _grf_sh 90 'set -u; . "$1/lib/resolve.sh"; . "$1/lib/verify.sh"; felix_tree_id "$2" "${3:-}"' "$@"; }
_grf_dirty() { _grf_sh 90 'set -u; . "$1/lib/resolve.sh"; . "$1/lib/verify.sh"; felix_tree_dirty "$2" "${3:-}"' "$@"; }
# The diff readers, with pipefail off (bash's default) and on (the CLI's and
# every hook's): the status they return is theirs, not the caller's options'.
_grf_added()     { _grf_sh 90 'set +o pipefail; . "$1/lib/resolve.sh"; felix_added_lines "$2" "${3:-}"' "$@"; }
_grf_changed()   { _grf_sh 90 'set +o pipefail; . "$1/lib/resolve.sh"; felix_changed_paths "$2" "${3:-}"' "$@"; }
_grf_added_pf()  { _grf_sh 90 'set -o pipefail; . "$1/lib/resolve.sh"; felix_added_lines "$2" "${3:-}"' "$@"; }
_grf_changed_pf(){ _grf_sh 90 'set -o pipefail; . "$1/lib/resolve.sh"; felix_changed_paths "$2" "${3:-}"' "$@"; }
_grf_esc() {   # root [base]
  ( cd "$1" && _grf_sh 120 'set -uo pipefail; . "$1/lib/resolve.sh"; . "$1/lib/verify.sh"; . "$1/lib/escape.sh"
      felix_escapes "$2" "$3" "$4" "$5"' "$GRFP" "${2:-main}" "$1" "$GRFH" ) 2>/dev/null
}
_grf_blk() {   # root -> felix_merge_blockers, sourced the way the epoch section sources it
  ( cd "$1" && _grf_sh 180 'set -uo pipefail; . "$1/lib/resolve.sh"; . "$1/lib/detect.sh"; . "$1/lib/verify.sh"
      . "$1/lib/evidence.sh"; . "$1/lib/escape.sh"; . "$1/lib/obligations.sh"; . "$1/lib/probes.sh"
      . "$1/lib/facts.sh"; . "$1/lib/epoch.sh"
      felix_merge_blockers "$2" main "$3" "$4"' "$GRFP" "$1" "$GRFH" ) 2>/dev/null
}
# Findings, a line of two dashes, then the tier felix_classify_tier gives them.
_grf_cls() {   # root
  ( cd "$1" && _grf_sh 120 'set -uo pipefail; . "$1/lib/resolve.sh"; . "$1/lib/classify.sh"
      f="$(felix_classify_diff "$2" main "$3")"; printf "%s\n--\n%s\n" "$f" "$(felix_classify_tier "$f")"' "$GRFP" "$1" ) 2>/dev/null
}
_grf_tier()  { printf '%s\n' "$1" | tail -1; }
_grf_finds() { printf '%s\n' "$1" | awk '$0 == "--" { exit } { print }'; }
_grf_ev() {   # root
  ( cd "$1" && _grf_sh 120 'set -uo pipefail; . "$1/lib/resolve.sh"; . "$1/lib/evidence.sh"
      felix_evidence_check "$2" main "$3"' "$GRFP" "$1" ) 2>/dev/null
}
# felix_land_owed's status, a bar, then what it printed.
_grf_owed() {   # proj root base
  ( unset FELIX_MERGE_DRY_RUN
    _grf_sh 120 'set -uo pipefail; . "$1/lib/resolve.sh"; . "$1/lib/land-table.sh"
      o="$(felix_land_owed "$2" "$3" "$4" 2>/dev/null)"; r=$?; printf "%s|%s" "$r" "$o"' "$@" ) 2>/dev/null
}
# The CLI and the hooks, stood in the checkout with this section's home.
_grf_felix() {   # dir args...
  local d="$1"; shift
  ( cd "$d" && FELIX_HOME="$GRFH" FELIX_MEMORY="$GRFM" perl -e 'alarm shift; exec @ARGV or exit 127' 240 "$FELIX" "$@" ) 2>&1
}
_grf_hook() {   # dir hook payload
  ( cd "$1" && unset FELIX_ALLOW_RED \
      && FELIX_HOME="$GRFH" FELIX_MEMORY="$GRFM" perl -e 'alarm shift; exec @ARGV or exit 127' 240 "$FROOT/harness/hooks/$2" <<<"$3" ) 2>&1
}
# A green receipt for the tree as it stands, stamped the way the epoch
# section stamps one, and the reader the Stop hook and the merge boundary share.
_grf_rec() {   # root
  ( cd "$1" && _grf_sh 180 'set -u; . "$1/lib/resolve.sh"; . "$1/lib/verify.sh"; . "$1/lib/probes.sh"; . "$1/lib/epoch.sh"
      t="$(felix_tree_id "$2" "$3")" && [ -n "$t" ] || exit 3
      felix_verify_record "$2" "$3" 0 true "$t" "" "" "$(felix_epoch "$4" "$2")" \
        "$(felix_epoch_components "$4" "$2" | cut -f2 | paste -sd, -)"' "$1" "$GRFH" "$GRFP" ) >/dev/null 2>&1 \
    || { [ -n "$_grf_fx" ] || _grf_fx="no green receipt could be stamped in $1"; }
}
_grf_cur() {   # root
  ( cd "$1" && _grf_sh 180 'set -u; . "$1/lib/resolve.sh"; . "$1/lib/verify.sh"; . "$1/lib/probes.sh"; . "$1/lib/epoch.sh"
      felix_verify_current "$2" "$3" "$4"' "$1" "$GRFH" "$GRFP" ) 2>/dev/null
}
# The id origin/main's felix_tree_id gives a tree with no home, computed here
# from git by the same recipe: HEAD (or `unborn`), the diff against it (or the
# unstaged diff), and size and mtime of each untracked file, hashed as one
# document. T5 holds the change to it byte for byte, except for an unborn HEAD
# with something staged (amended below, 2026-10-08).
_grf_recipe() {   # root
  local root="$1" head diff un meta="" f files=()
  head="$(git -C "$root" rev-parse HEAD 2>/dev/null)" || head=""
  if [ -z "$head" ]; then head=unborn; diff="$(git -C "$root" diff -- . 2>/dev/null)"
  else diff="$(git -C "$root" diff HEAD -- . 2>/dev/null)"; fi
  un="$(git -C "$root" ls-files --others --exclude-standard -- . 2>/dev/null | LC_ALL=C sort)"
  if [ -n "$un" ]; then
    while IFS= read -r f; do [ -n "$f" ] && files+=("$root/$f"); done <<EOF
$un
EOF
    if stat -c '%s' /dev/null >/dev/null 2>&1; then meta="$(stat -c '%n %s %Y' "${files[@]}" 2>/dev/null)"
    else meta="$(stat -f '%N %z %m' "${files[@]}" 2>/dev/null)"; fi
  fi
  printf '%s\n%s\n%s' "$head" "$diff" "$meta" | git hash-object --stdin
}

# ------------------------------------------------------- T: tree identity ----
_grf_new t1-before; GRA="$GRR"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_pipe "$GRA" projects/x/deny.tsv
out="$(_grf_tid "$GRA")"; rc=$?
_grf_is "a tracked pipe sorting before an edit leaves the tree id unknown: nothing printed, a failing status (T1)" \
        "[$out] $(_grf_nz "$rc")" "[] non-zero"
_grf_unpipe "$GRA" projects/x/deny.tsv

_grf_new t1-after; GRA="$GRR"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_pipe "$GRA" zz.txt
out="$(_grf_tid "$GRA")"; rc=$?
_grf_is "and so does one sorting after the edit, which the diff reaches only once the edit is printed (T1)" \
        "[$out] $(_grf_nz "$rc")" "[] non-zero"
_grf_unpipe "$GRA" zz.txt

_grf_new t1-unreadable; GRA="$GRR"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; chmod 000 "$GRA/A.txt" 2>/dev/null
if [ -z "$_grf_fx" ] && [ -r "$GRA/A.txt" ]; then
  skip "a tracked regular file nobody may read leaves the tree id unknown (T1)" "this user can read a mode-000 file"
else
  out="$(_grf_tid "$GRA")"; rc=$?
  _grf_is "a tracked regular file nobody may read leaves the tree id unknown (T1)" "[$out] $(_grf_nz "$rc")" "[] non-zero"
fi
chmod 644 "$GRA/A.txt" 2>/dev/null

_grf_new t1-index; GRA="$GRR"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_corrupt "$GRA"
out="$(_grf_tid "$GRA")"; rc=$?
_grf_is "a corrupt index leaves the tree id unknown (T1)" "[$out] $(_grf_nz "$rc")" "[] non-zero"

# T2: no commit yet, the files staged, one of them then replaced by a pipe.
_grf_fx=""; GRA="$(mktemp -d "$GRF/t2.XXXXXX")"
( _fx_cd "$GRA" && git init -q -b main && printf 'a\n' > A.txt && printf 'one\n' > src.txt && git add -A ) >/dev/null 2>&1 \
  || _grf_fx="the unborn repository could not be made"
git -C "$GRA" rev-parse -q --verify HEAD >/dev/null 2>&1 && _grf_fx="the unborn repository has a commit"
printf 'two\n' >> "$GRA/src.txt"; _grf_pipe "$GRA" A.txt
out="$(_grf_tid "$GRA")"; rc=$?
_grf_is "with no commit yet, a staged file replaced by a pipe leaves the tree id unknown (T2)" \
        "[$out] $(_grf_nz "$rc")" "[] non-zero"
_grf_unpipe "$GRA" A.txt

# T3: the home is the root, so state/**, projects/*/memory/*.log and
# projects/*/maintenance.log are not the tree's identity. The same tree with
# those files merely edited gives the id that holds once they are pipes.
_grf_new t3; GRA="$GRR"
mkdir -p "$GRA/state" "$GRA/projects/p/memory" 2>/dev/null
printf 's\n' > "$GRA/state/x.txt" 2>/dev/null; printf 'l\n' > "$GRA/projects/p/memory/a.log" 2>/dev/null
printf 'm\n' > "$GRA/projects/p/maintenance.log" 2>/dev/null
_grf_commit "$GRA" excluded
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null
printf 'more\n' >> "$GRA/state/x.txt" 2>/dev/null; printf 'more\n' >> "$GRA/projects/p/memory/a.log" 2>/dev/null
printf 'more\n' >> "$GRA/projects/p/maintenance.log" 2>/dev/null
grf_t3="$(_grf_tid "$GRA" "$GRA")"
[ -n "$grf_t3" ] || { [ -n "$_grf_fx" ] || _grf_fx="the id of the readable tree with its home at the root was empty"; }
_grf_pipe "$GRA" state/x.txt; _grf_pipe "$GRA" projects/p/memory/a.log; _grf_pipe "$GRA" projects/p/maintenance.log
out="$(_grf_tid "$GRA" "$GRA")"; rc=$?
_grf_is "pipes under state/, a memory log and the maintenance log of a home at the root leave the id known (T3)" \
        "$(_grf_nz "$rc") $([ -n "$out" ] && echo id || echo none)" "exit 0 id"
_grf_is "and it is the id the same tree has with those files merely edited, since they are not its identity (T3)" \
        "$out" "$grf_t3"
_grf_unpipe "$GRA" projects/p/maintenance.log; printf 'm\nmore\n' > "$GRA/projects/p/maintenance.log" 2>/dev/null
chmod 000 "$GRA/projects/p/maintenance.log" 2>/dev/null
if [ -z "$_grf_fx" ] && [ -r "$GRA/projects/p/maintenance.log" ]; then
  skip "an unreadable maintenance log of a home at the root leaves the id known (T3)" "this user can read a mode-000 file"
else
  out="$(_grf_tid "$GRA" "$GRA")"; rc=$?
  _grf_is "an unreadable maintenance log of a home at the root leaves the id known (T3)" \
          "$(_grf_nz "$rc") $([ -n "$out" ] && echo id || echo none)" "exit 0 id"
fi
chmod 644 "$GRA/projects/p/maintenance.log" 2>/dev/null
_grf_unpipe "$GRA" state/x.txt; _grf_unpipe "$GRA" projects/p/memory/a.log

_grf_new t3-inside; GRA="$GRR"
mkdir -p "$GRA/home/state" "$GRA/home/projects/p/memory" 2>/dev/null
printf 'h\n' > "$GRA/home/state/y.txt" 2>/dev/null; printf 'l\n' > "$GRA/home/projects/p/memory/b.log" 2>/dev/null
_grf_commit "$GRA" home
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null
_grf_pipe "$GRA" home/state/y.txt; _grf_pipe "$GRA" home/projects/p/memory/b.log
out="$(_grf_tid "$GRA" "$GRA/home")"; rc=$?
_grf_is "with the home inside the root, pipes under its state/ and its memory logs leave the id known (T3)" \
        "$(_grf_nz "$rc") $([ -n "$out" ] && echo id || echo none)" "exit 0 id"
_grf_unpipe "$GRA" home/state/y.txt; _grf_unpipe "$GRA" home/projects/p/memory/b.log

_grf_new t4; GRA="$GRR"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; mkfifo "$GRA/untracked.fifo" 2>/dev/null
[ -n "$_grf_fx" ] || [ -p "$GRA/untracked.fifo" ] || _grf_fx="no untracked pipe could be made"
out="$(_grf_tid "$GRA")"; rc=$?
_grf_is "an untracked pipe, which git does not see, leaves the tree id known (T4)" \
        "$(_grf_nz "$rc") $([ -n "$out" ] && echo id || echo none)" "exit 0 id"
_grf_unpipe "$GRA" untracked.fifo

# T5: a tree git can read keeps origin/main's id byte for byte.
_grf_new t5; GRA="$GRR"
_grf_is "a clean tree keeps the id origin/main gives it (T5)" "$(_grf_tid "$GRA")" "$(_grf_recipe "$GRA")"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; printf 'staged\n' >> "$GRA/A.txt" 2>/dev/null
_fx_git "$GRA" add A.txt >/dev/null 2>&1
_grf_is "an edited tree, staged and unstaged, keeps the id origin/main gives it (T5)" "$(_grf_tid "$GRA")" "$(_grf_recipe "$GRA")"
printf 'u\n' > "$GRA/untracked.txt" 2>/dev/null; mkdir -p "$GRA/newdir" 2>/dev/null; printf 'v\n' > "$GRA/newdir/v.txt" 2>/dev/null
_grf_is "a tree with untracked files keeps the id origin/main gives it (T5)" "$(_grf_tid "$GRA")" "$(_grf_recipe "$GRA")"
# Amended after the review, 2026-10-08, by the session that wrote the fix, so
# not blind. The blind author pinned origin/main's id for an unborn HEAD with
# something staged, and that id was the defect the review found: it hashed the
# index against the tree only, so two different staged contents shared the id
# of an empty `git init`, and a green receipt for one read current over the
# other. With nothing staged an unborn HEAD keeps main's id. With something
# staged it gets an id of its own.
_grf_fx=""; GRA="$(mktemp -d "$GRF/t5-unborn.XXXXXX")"
( _fx_cd "$GRA" && git init -q -b main && printf 'u\n' > untracked.txt ) >/dev/null 2>&1 \
  || _grf_fx="the unborn repository could not be made"
_grf_is "an unborn HEAD with nothing staged keeps the id origin/main gives it (T5)" "$(_grf_tid "$GRA")" "$(_grf_recipe "$GRA")"
grf_t0="$(_grf_tid "$GRA")"
( _fx_cd "$GRA" && printf 'one\n' > src.txt && git add src.txt ) >/dev/null 2>&1 \
  || { [ -n "$_grf_fx" ] || _grf_fx="nothing could be staged in the unborn repository"; }
grf_t1="$(_grf_tid "$GRA")"
( _fx_cd "$GRA" && printf 'two\n' > src.txt && git add src.txt ) >/dev/null 2>&1 \
  || { [ -n "$_grf_fx" ] || _grf_fx="nothing could be staged in the unborn repository"; }
grf_t2="$(_grf_tid "$GRA")"
_grf_is "on an unborn HEAD, two different staged contents have two ids, neither the id with nothing staged (T5, amended)" \
        "$([ -n "$grf_t1" ] && [ -n "$grf_t2" ] && [ "$grf_t1" != "$grf_t2" ] && [ "$grf_t1" != "$grf_t0" ] \
             && [ "$grf_t2" != "$grf_t0" ] && echo distinct || echo "[$grf_t0] [$grf_t1] [$grf_t2]")" "distinct"

_grf_new t6; GRA="$GRR"
_grf_dirty "$GRA"; rc=$?
_grf_is "a clean tree git can read is still clean (T6)" "$rc" "1"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_pipe "$GRA" A.txt
_grf_dirty "$GRA"; rc=$?
_grf_is "a tree holding a tracked pipe is dirty (T6)" "$rc" "0"
_grf_unpipe "$GRA" A.txt
_grf_new t6-index; GRA="$GRR"; _grf_corrupt "$GRA"
_grf_dirty "$GRA"; rc=$?
_grf_is "a tree whose status git cannot give, a corrupt index, is not clean (T6)" "$rc" "0"
_grf_fx=""; GRA="$(mktemp -d "$GRF/t6-nogit.XXXXXX")"
git -C "$GRA" rev-parse --git-dir >/dev/null 2>&1 && _grf_fx="the scratch directory is inside a repository"
_grf_dirty "$GRA"; rc=$?
_grf_is "a directory that is no repository at all still reads as not dirty, as today (T6)" "$rc" "1"

_grf_new t7; GRA="$GRR"; _grf_rec "$GRA"
_grf_is "the T7 control: a green receipt stamped on the clean tree is current there (T7)" "$(_grf_cur "$GRA")" "current"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_pipe "$GRA" A.txt
out="$(_grf_cur "$GRA")"; rc=$?
_grf_is "that receipt is stale, not current, once the tree holds an edit and a tracked pipe sorting before it (T7)" \
        "$(printf '%s' "$out" | cut -f1) $(_grf_nz "$rc")" "stale non-zero"
_grf_unpipe "$GRA" A.txt

_grf_new t8-control; GRA="$GRR"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null
_grf_felix "$GRA" gate >/dev/null
_grf_is "the T8 control: a passing felix gate over a readable edit leaves a receipt that reads current (T8)" \
        "$(_grf_cur "$GRA")" "current"
_grf_new t8; GRA="$GRR"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_pipe "$GRA" A.txt
_grf_felix "$GRA" gate >/dev/null
out="$(_grf_cur "$GRA")"
_grf_is "felix gate over a tree holding a tracked pipe leaves nothing the next read calls current (T8)" \
        "$([ "$out" = current ] && echo current || echo 'not current')" "not current"
_grf_unpipe "$GRA" A.txt

# -------------------------------------------------------- S: the stop hooks ----
# A green receipt for the clean tree, then an edit and a tracked pipe sorting
# before it: the one tree whose id on origin/main is the clean tree's.
_grf_vlog="$GRFM/grf/verification.log"
_grf_vrows() { if [ -f "$_grf_vlog" ]; then awk 'END { print NR }' "$_grf_vlog"; else printf '0'; fi; }
_grf_new s; GRS="$GRR"; _grf_rec "$GRS"
[ -n "$_grf_fx" ] || [ "$(_grf_cur "$GRS")" = current ] || _grf_fx="the receipt stamped on the clean tree is not current"
printf 'three\n' >> "$GRS/src.txt" 2>/dev/null; _grf_pipe "$GRS" A.txt
grf_n0="$(_grf_vrows)"
out="$(_grf_hook "$GRS" stop '{"session_id":"grf-s1","hook_event_name":"Stop","stop_hook_active":false}')"
grf_n1="$(_grf_vrows)"
_grf_is "Stop holds a session whose dirty tree holds a tracked pipe, though a green receipt stands for the clean tree (S1)" \
        "$(_grf_blocked "$out")" "block"
_grf_has "and its reason names the pipe as git names it (S1)" "$out" "A.txt"
# The wording is the implementation's; the stem is the contract's.
case "$out" in *[Ii]dentif*|*[Ii]dentit*) grf_said=identified ;; *) grf_said="[$out]" ;; esac
_grf_is "and says the tree cannot be identified (S1)" "$grf_said" "identified"
_grf_is "and the verification log records that stop as blocked, one row (S3)" \
        "+$((grf_n1 - grf_n0)) $(tail -1 "$_grf_vlog" 2>/dev/null | cut -f2)" "+1 blocked"
out="$(_grf_hook "$GRS" stop '{"session_id":"grf-s1","hook_event_name":"Stop","stop_hook_active":true}')"; rc=$?
_grf_is "the stop that hold started, flagged, is let through on the same tree, so nothing is stranded (S2)" \
        "$(_grf_nz "$rc") $(_grf_blocked "$out")" "exit 0 no block"
out="$(_grf_hook "$GRS" subagent-stop '{"session_id":"grf-ss1","hook_event_name":"SubagentStop","stop_hook_active":false}')"
_grf_has "SubagentStop declares the tree unverified though the receipt names the clean tree's id (S4)" \
         "$out" "A subagent report is about to be integrated"
_grf_has "and says it as additionalContext (S4)" "$out" '"additionalContext"'
_grf_unpipe "$GRS" A.txt
_grf_new s4; GRA="$GRR"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_pipe "$GRA" A.txt
_grf_has "SubagentStop declares a tree with a tracked pipe and no receipt unverified, as for any unverified tree (S4)" \
         "$(_grf_hook "$GRA" subagent-stop '{"session_id":"grf-ss2","hook_event_name":"SubagentStop","stop_hook_active":false}')" \
         "A subagent report is about to be integrated"
_grf_unpipe "$GRA" A.txt

# -------------------------------------------------------- R: the diff readers ----
# The contract's own R1 example, a pipe at A.txt and a line added to src.txt,
# already exits 1 on origin/main, by accident: git dies before the line, and
# the grep that ends the reader finds nothing. The two cases after it are the
# ones origin/main answers with 0, a line read before git died.
_grf_new r1; GRA="$GRR"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_pipe "$GRA" A.txt
_grf_added "$GRA" >/dev/null; rc=$?
_grf_is "felix_added_lines fails over a tracked pipe sorting before the added line (R1)" "$(_grf_nz "$rc")" "non-zero"
_grf_unpipe "$GRA" A.txt
_grf_new r1-after; GRA="$GRR"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_pipe "$GRA" zz.txt
_grf_added "$GRA" >/dev/null; rc=$?
_grf_is "and over one sorting after it, where the added line was read before git died (R1)" "$(_grf_nz "$rc")" "non-zero"
_grf_unpipe "$GRA" zz.txt
_grf_new r1-base; GRA="$GRR"
( _fx_cd "$GRA" && git checkout -q -b feat ) >/dev/null 2>&1; printf 'n\n' > "$GRA/new.txt" 2>/dev/null
_grf_commit "$GRA" new; _grf_pipe "$GRA" A.txt
_grf_added "$GRA" main >/dev/null; rc=$?
_grf_is "and against a base, where the branch's own lines were read before the working tree failed (R1)" \
        "$(_grf_nz "$rc")" "non-zero"
_grf_unpipe "$GRA" A.txt

_grf_new r2; GRA="$GRR"
( _fx_cd "$GRA" && git checkout -q -b feat ) >/dev/null 2>&1; printf 'n\n' > "$GRA/new.txt" 2>/dev/null
_grf_commit "$GRA" new; _grf_corrupt "$GRA"
out="$(_grf_changed "$GRA" main)"; rc=$?
_grf_is "felix_changed_paths fails over a corrupt index (R2)" "$(_grf_nz "$rc")" "non-zero"
_grf_is "and still prints the path it did read, the branch's commit (R2)" "$out" "new.txt"
_grf_new r2-nobase; GRA="$GRR"; _grf_corrupt "$GRA"
_grf_changed "$GRA" >/dev/null; rc=$?
_grf_is "and fails over a corrupt index with no base given (R2)" "$(_grf_nz "$rc")" "non-zero"
_grf_new r2-pipe; GRA="$GRR"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_pipe "$GRA" A.txt
out="$(_grf_changed "$GRA")"; rc=$?
_grf_is "over a tracked pipe the names still read: exit 0, the pipe's path and the edited one, as today (R2)" \
        "$rc|$out" "0|$(printf 'A.txt\nsrc.txt')"
_grf_unpipe "$GRA" A.txt

_grf_new r3; GRA="$GRR"
( _fx_cd "$GRA" && git checkout -q -b feat ) >/dev/null 2>&1; printf 'n\n' > "$GRA/new.txt" 2>/dev/null
_grf_commit "$GRA" new
printf 'staged\n' >> "$GRA/A.txt" 2>/dev/null; _fx_git "$GRA" add A.txt >/dev/null 2>&1
printf 'more\n' >> "$GRA/src.txt" 2>/dev/null
out="$(_grf_changed "$GRA" main)"; rc=$?
_grf_is "felix_changed_paths over a readable branch, staged and unstaged edits: exit 0, every path, as today (R3)" \
        "$rc|$out" "0|$(printf 'A.txt\nnew.txt\nsrc.txt')"
out="$(_grf_changed_pf "$GRA" main)"; rc=$?
_grf_is "and felix_changed_paths gives the same under pipefail (R3)" "$rc|$out" "0|$(printf 'A.txt\nnew.txt\nsrc.txt')"
out="$(_grf_added "$GRA" main)"; rc=$?
_grf_is "felix_added_lines over it: exit 0, the branch's, the staged and the unstaged line in that order (R3)" \
        "$rc|$out" "0|$(printf '+n\n+staged\n+more')"
out="$(_grf_added_pf "$GRA" main)"; rc=$?
_grf_is "and felix_added_lines gives the same under pipefail (R3)" "$rc|$out" "0|$(printf '+n\n+staged\n+more')"
# R3 says both exit 0 for any tree git can read, and these hold it to that
# where origin/main does not: its felix_added_lines ends in a grep, so a tree
# that adds no line exits 1, and under pipefail so does felix_changed_paths on
# a clean tree. Once a status means "not read", a deletion-only change that
# exits 1 would be reported as unread (E1 and E4 below carry the same guard).
_grf_new r3-clean; GRA="$GRR"
out="$(_grf_changed "$GRA")"; rc=$?
_grf_is "a clean readable tree is no failure: felix_changed_paths exits 0 printing nothing (R3)" "$rc|$out" "0|"
out="$(_grf_changed_pf "$GRA")"; rc=$?
_grf_is "and felix_changed_paths does under pipefail too (R3)" "$rc|$out" "0|"
out="$(_grf_added "$GRA")"; rc=$?
_grf_is "and felix_added_lines exits 0 printing nothing (R3)" "$rc|$out" "0|"
out="$(_grf_added_pf "$GRA")"; rc=$?
_grf_is "and felix_added_lines does under pipefail too (R3)" "$rc|$out" "0|"
_grf_new r3-delete; GRA="$GRR"
printf 'one\n' > "$GRA/src.txt" 2>/dev/null
out="$(_grf_added "$GRA")"; rc=$?
_grf_is "a change that only deletes a line adds none, and that is read, not failed: exit 0, nothing printed (R3)" "$rc|$out" "0|"
out="$(_grf_changed "$GRA")"; rc=$?
_grf_is "and its path still reads, exit 0 (R3)" "$rc|$out" "0|src.txt"

# --------------------------------------------- E: the readers' consumers ----
# Three branches cut from main, each committing a workflow, which is the
# `execute` channel: one readable with an edit, one whose A.txt is then a pipe,
# one whose index is then corrupt.
_grf_wf() {   # tag -> GRR, on feat, a workflow committed and src.txt edited
  _grf_new "$1"
  ( _fx_cd "$GRR" && git checkout -q -b feat && mkdir -p .github/workflows \
      && printf 'on: push\n' > .github/workflows/ci.yml ) >/dev/null 2>&1
  _grf_commit "$GRR" workflow
  printf 'three\n' >> "$GRR/src.txt" 2>/dev/null
}
_grf_wf e-read;  GRE0="$GRR"; grf_fx0="$_grf_fx"
_grf_wf e-pipe;  GRE1="$GRR"; _grf_pipe "$GRE1" A.txt; grf_fx1="$_grf_fx"
_grf_wf e-index; GRE2="$GRR"; _grf_corrupt "$GRE2"; grf_fx2="$_grf_fx"
_grf_new e-delete; GRE3="$GRR"; printf 'one\n' > "$GRE3/src.txt" 2>/dev/null; grf_fx3="$_grf_fx"
_grf_unknown_row() { printf '%s\n' "$1" | awk -F'\t' '$1 == "unknown" { print; exit }'; }
_grf_execute() { printf '%s\n' "$1" | awk -F'\t' '$1 == "execute" && $2 == ".github/workflows/ci.yml" { n++ } END { print n + 0 }'; }

_grf_fx="$grf_fx1"; out="$(_grf_esc "$GRE1")"
_grf_is "felix_escapes over a tracked pipe prints an unknown row, since the added lines were not read (E1)" \
        "$([ -n "$(_grf_unknown_row "$out")" ] && echo unknown || echo none)" "unknown"
_grf_has "and its reason says the change was not scanned (E1)" "$(_grf_unknown_row "$out" | cut -f3-)" "scanned"
_grf_is "and still prints the path channel it can compute, the workflow's execute (E1)" "$(_grf_execute "$out")" "1"
_grf_fx="$grf_fx2"; out="$(_grf_esc "$GRE2")"
_grf_is "felix_escapes over a corrupt index prints an unknown row, since the changed paths were not read (E1)" \
        "$([ -n "$(_grf_unknown_row "$out")" ] && echo unknown || echo none)" "unknown"
_grf_is "and still prints the execute row for the committed workflow it did read (E1)" "$(_grf_execute "$out")" "1"
_grf_fx="$grf_fx1"; out="$(_grf_blk "$GRE1")"
_grf_is "felix_merge_blockers passes that row through as unknown (E1)" \
        "$([ "$(_grf_n1 "$out" unknown)" -gt 0 ] && echo unknown || echo none)" "unknown"
_grf_lacks "and never as an escape (E1)" "$out" "$(printf 'escape\tunknown')"
_grf_fx="$grf_fx0"; out="$(_grf_esc "$GRE0")"
_grf_is "a readable change prints no unknown row and its execute row, as today (E1)" \
        "$(_grf_n1 "$out" unknown) $(_grf_execute "$out")" "0 1"
_grf_fx="$grf_fx3"; out="$(_grf_esc "$GRE3")"
_grf_is "a readable change that only deletes a line prints no unknown row: adding nothing is not failing to read (E1)" \
        "$(_grf_n1 "$out" unknown)" "0"

# E2: the scanner's status, from a harness whose secret-scan is a stub that
# exits as told. The tree is readable, so no other unknown row can appear.
GRFS="$GRF/stub-harness"; mkdir -p "$GRFS/bin"
cp -R "$FROOT/harness/lib" "$GRFS/lib" 2>/dev/null
printf '#!/usr/bin/env bash\nexit "${GRF_SCAN_RC:-0}"\n' > "$GRFS/bin/secret-scan"; chmod +x "$GRFS/bin/secret-scan"
_grf_new e2; GRE4="$GRR"
mkdir -p "$GRE4/docs" 2>/dev/null; printf 'a note\n' > "$GRE4/docs/note.md" 2>/dev/null
( _fx_cd "$GRE4" && git checkout -q -b feat ) >/dev/null 2>&1; _grf_commit "$GRE4" note
if [ -z "$_grf_fx" ] && { [ ! -x "$GRFS/bin/secret-scan" ] || [ ! -f "$GRFS/lib/escape.sh" ]; }; then
  _grf_fx="the stub harness could not be made"
fi
_grf_esc_stub() {   # scan status -> felix_escapes from the stub harness
  ( export GRF_SCAN_RC="$1" GRF_HARNESS="$GRFS"; _grf_esc "$GRE4" )
}
_grf_dsc() { printf 'disclose=%s unknown=%s' "$(_grf_n1 "$1" disclose)" \
             "$([ "$(_grf_n1 "$1" unknown)" -gt 0 ] && echo yes || echo no)"; }
_grf_is "a scan that exits 1 still gives the disclose row, and no unknown (E2)" "$(_grf_dsc "$(_grf_esc_stub 1)")" "disclose=1 unknown=no"
_grf_is "a scan that exits 2 gives an unknown row, never disclose (E2)" "$(_grf_dsc "$(_grf_esc_stub 2)")" "disclose=0 unknown=yes"
_grf_is "and so does one that exits 3 (E2)" "$(_grf_dsc "$(_grf_esc_stub 3)")" "disclose=0 unknown=yes"
_grf_is "and a scan that exits 0 gives neither (E2)" "$(_grf_dsc "$(_grf_esc_stub 0)")" "disclose=0 unknown=no"

# E3: deps.txt's floor raised on the branch, which the confine clause demotes,
# then the file replaced in the working tree by a pipe.
_grf_publish() { printf '%s\n' "$1" | awk -F'\t' '$1 == "publish" && $2 == "deps.txt" { n++ } END { print n + 0 }'; }
_grf_new e3-live; GRA="$GRR"
( _fx_cd "$GRA" && git checkout -q -b feat ) >/dev/null 2>&1; printf 'libz>=1.0\n' > "$GRA/deps.txt" 2>/dev/null
_grf_commit "$GRA" swap
_grf_is "the E3 row is live: a floor swapped for another package is not confined, and fires (E3)" \
        "$(_grf_publish "$(_grf_esc "$GRA")")" "1"
_grf_new e3; GRA="$GRR"
( _fx_cd "$GRA" && git checkout -q -b feat ) >/dev/null 2>&1; printf 'liba>=1.1\n' > "$GRA/deps.txt" 2>/dev/null
_grf_commit "$GRA" floor
_grf_is "the E3 control: a floor raised in place is confined, so the publish row is demoted (E3)" "$(_grf_publish "$(_grf_esc "$GRA")")" "0"
_grf_pipe "$GRA" deps.txt
_grf_is "but with that file a pipe in the working tree, its hunk is not read in full and the row fires (E3)" \
        "$(_grf_publish "$(_grf_esc "$GRA")")" "1"
_grf_unpipe "$GRA" deps.txt

_grf_fx="$grf_fx1"; out="$(_grf_cls "$GRE1")"
_grf_is "felix_classify_diff over a tracked pipe prints an unknown row, and the tier is unknown (E4)" \
        "$(_grf_n1 "$(_grf_finds "$out")" unknown | sed 's/^[1-9][0-9]*$/some/') $(_grf_tier "$out")" "some unknown"
_grf_fx="$grf_fx2"; out="$(_grf_cls "$GRE2")"
_grf_is "and over a corrupt index the same (E4)" \
        "$(_grf_n1 "$(_grf_finds "$out")" unknown | sed 's/^[1-9][0-9]*$/some/') $(_grf_tier "$out")" "some unknown"
_grf_fx="$grf_fx0"; out="$(_grf_cls "$GRE0")"
_grf_is "a readable change classifies as today: no unknown row, the default yellow (E4)" \
        "$(_grf_n1 "$(_grf_finds "$out")" unknown) $(_grf_tier "$out")" "0 yellow"
_grf_fx="$grf_fx3"; out="$(_grf_cls "$GRE3")"
_grf_is "and so does a readable change that only deletes a line (E4)" \
        "$(_grf_n1 "$(_grf_finds "$out")" unknown) $(_grf_tier "$out")" "0 yellow"

_grf_fx="$grf_fx2"; out="$(_grf_ev "$GRE2")"
_grf_is "felix_evidence_check over a corrupt index, its base resolvable, prints exactly one row, unknown (E5)" \
        "$(printf '%s\n' "$out" | grep -c .) $(printf '%s\n' "$out" | cut -f1 | tr '\n' ' ')" "1 unknown "
_grf_fx="$grf_fx0"; out="$(_grf_ev "$GRE0")"
_grf_is "a readable change is checked row by row as today: the src edit owes a test (E5)" "$(printf '%s\n' "$out" | cut -f1,2)" "$(printf 'gap\tunit')"

_grf_rcpt_unknown() { printf '%s\n' "$1" | awk '/^  "unknown": /'; }
_grf_rcpt_status()  { printf '%s\n' "$1" | sed -n 's/^  "status": "\([a-z]*\)".*/\1/p'; }
_grf_fx="$grf_fx2"; out="$(_grf_felix "$GRE2" receipt)"
_grf_has "felix receipt over a corrupt index lists changed as unknown (E6)" "$(_grf_rcpt_unknown "$out")" '"changed"'
_grf_is  "and is indeterminate (E6)" "$(_grf_rcpt_status "$out")" "indeterminate"
_grf_fx="$grf_fx1"; out="$(_grf_felix "$GRE1" receipt)"
_grf_has "felix receipt over a tracked pipe lists the tree as unknown (E6)" "$(_grf_rcpt_unknown "$out")" '"tree"'
_grf_is  "and is indeterminate too (E6)" "$(_grf_rcpt_status "$out")" "indeterminate"
_grf_fx="$grf_fx0"; out="$(_grf_felix "$GRE0" receipt)"
_grf_is "felix receipt over a readable change lists nothing unknown and is not indeterminate, as today (E6)" \
        "$(_grf_rcpt_unknown "$out" | tr -d ' ') $(_grf_rcpt_status "$out")" '"unknown":[], blocked'

_grf_fx="$grf_fx2"
_grf_is "felix_land_owed exits 2 printing nothing when the changed paths cannot be read (E7)" "$(_grf_owed "$GRFP" "$GRE2" main)" "2|"
# And where a land table binds a row, so the exit is not merely "no table":
# origin/main carries projects/lt/land.tsv owing out.txt whenever src.txt moves.
_grf_new e7; GRA="$GRR"
mkdir -p "$GRA/projects/lt" 2>/dev/null; printf 'out\n' > "$GRA/out.txt" 2>/dev/null
printf 'out.txt\tinsertions-union\tsrc.txt\t-\n' > "$GRA/projects/lt/land.tsv" 2>/dev/null
_grf_commit "$GRA" land
_fx_git "$GRA" update-ref refs/remotes/origin/main HEAD >/dev/null 2>&1 || { [ -n "$_grf_fx" ] || _grf_fx="origin/main could not be set"; }
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null
_grf_is "the E7 control: a readable edit to the trigger owes the row, as today (E7)" \
        "$(_grf_owed "$GRA/projects/lt" "$GRA" origin/main)" "$(printf '0|out.txt\tinsertions-union\tsrc.txt')"
_grf_corrupt "$GRA"
_grf_is "and over a corrupt index the same table owes nothing it can claim: exit 2, nothing printed (E7)" \
        "$(_grf_owed "$GRA/projects/lt" "$GRA" origin/main)" "2|"

# A function, not a case inside $(...): bash 3.2 reads the pattern's `)` as
# the end of the substitution.
_grf_scoped() { case "$1" in *"In scope"*) printf 'In scope' ;; *) printf 'not in scope' ;; esac; }
_grf_new e8; GRA="$GRR"; printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_corrupt "$GRA"
out="$(_grf_felix "$GRA" scope)"; rc=$?
_grf_is "felix scope over a corrupt index is not in scope and fails, where today it finds nothing to scope (E8)" \
        "$(_grf_scoped "$out") $(_grf_nz "$rc")" "not in scope non-zero"
_grf_fx="$grf_fx1"; out="$(_grf_felix "$GRE1" scope)"; rc=$?
_grf_is "felix scope over a tracked pipe hiding the content is not in scope and fails (E8)" \
        "$(_grf_scoped "$out") $(_grf_nz "$rc")" "not in scope non-zero"
_grf_fx="$grf_fx0"; out="$(_grf_felix "$GRE0" scope)"; rc=$?
_grf_is "felix scope over a readable yellow change is in scope, exit 0, as today (E8)" \
        "$(_grf_scoped "$out") $(_grf_nz "$rc")" "In scope exit 0"
_grf_unpipe "$GRE1" A.txt

# ------------------------------------------------------------ X: secret-scan ----
# The key is assembled at run time, so this file never carries one.
grf_key="$(printf '%s%s' AKIA ABCDEFGHIJKLMNOP)"
_grf_scan() {   # dir args... -> the scanner's status; its stderr in $GRF/scan.err
  local d="$1"; shift
  ( cd "$d" && perl -e 'alarm shift; exec @ARGV or exit 127' 90 "$FROOT/harness/bin/secret-scan" "$@" >/dev/null 2>"$GRF/scan.err" )
}
_grf_new x1; GRA="$GRR"
( _fx_cd "$GRA" && git checkout -q -b feat ) >/dev/null 2>&1
printf 'aws = "%s"\n' "$grf_key" >> "$GRA/src.txt" 2>/dev/null
_grf_scan "$GRA" main; rc=$?
_grf_is "an uncommitted key in a readable tree is found, exit 1, as today (X1)" "$rc" "1"
_grf_pipe "$GRA" A.txt
_grf_scan "$GRA" main; rc=$?; grf_err="$(cat "$GRF/scan.err" 2>/dev/null)"
_grf_is "with A.txt then a pipe, the scan exits 2, the change not read (X1)" "$rc" "2"
_grf_has "and says on stderr that it could not read the change (X1)" "$grf_err" "read"
_grf_unpipe "$GRA" A.txt

_grf_new x2 trunk; GRA="$GRR"
for grf_c in origin/HEAD origin/main origin/master main master; do
  git -C "$GRA" rev-parse --verify -q "$grf_c" >/dev/null 2>&1 && { [ -n "$_grf_fx" ] || _grf_fx="$grf_c resolves in the no-base fixture"; }
done
printf 'aws = "%s"\n' "$grf_key" >> "$GRA/src.txt" 2>/dev/null; _grf_pipe "$GRA" A.txt
_grf_scan "$GRA"; rc=$?
_grf_is "with no base ref anywhere, the uncommitted-only scan of the same unreadable tree exits 2 (X2)" "$rc" "2"
_grf_unpipe "$GRA" A.txt

_grf_new x3; GRA="$GRR"
( _fx_cd "$GRA" && git checkout -q -b feat ) >/dev/null 2>&1; printf 'three\n' >> "$GRA/src.txt" 2>/dev/null
_grf_scan "$GRA" main; rc=$?
_grf_is "a readable change with no key is read and clean, exit 0 (X3)" "$rc" "0"

_grf_new x4; GRA="$GRR"; _grf_pipe "$GRA" A.txt
_grf_scan "$GRA" --tree; rc=$?; grf_err="$(cat "$GRF/scan.err" 2>/dev/null)"
_grf_is "secret-scan --tree over a tracked pipe exits 2 (X4)" "$rc" "2"
_grf_has "and names the pipe on stderr (X4)" "$grf_err" "A.txt"
_grf_unpipe "$GRA" A.txt
_grf_new x4-socket; GRA="$GRR"; unlink "$GRA/A.txt" 2>/dev/null
( cd "$GRA" && perl -MIO::Socket::UNIX -e 'IO::Socket::UNIX->new(Type => SOCK_STREAM(), Local => "A.txt", Listen => 1) or exit 1' ) >/dev/null 2>&1
[ -n "$_grf_fx" ] || [ -S "$GRA/A.txt" ] || _grf_fx="no socket could be made at A.txt"
_grf_scan "$GRA" --tree; rc=$?; grf_err="$(cat "$GRF/scan.err" 2>/dev/null)"
_grf_is "secret-scan --tree over a tracked path that is a socket exits 2 (X4)" "$rc" "2"
_grf_has "and names it on stderr (X4)" "$grf_err" "A.txt"
skip "secret-scan --tree over a tracked path that is a device exits 2 (X4)" "a device node cannot be made without root"
_grf_new x4-deleted; GRA="$GRR"; rm -f "$GRA/zz.txt"
_grf_scan "$GRA" --tree; rc=$?
_grf_is "a tracked path deleted from the working tree is skipped, exit 0, as today (X4)" "$rc" "0"
_grf_new x4-link; GRA="$GRR"
printf 'aws = "%s"\n' "$grf_key" > "$GRF/x4-outside-key.txt"
ln -s "$GRF/x4-outside-key.txt" "$GRA/link.txt" 2>/dev/null; _grf_commit "$GRA" link
[ -n "$_grf_fx" ] || [ -L "$GRA/link.txt" ] || _grf_fx="no tracked symlink could be made"
_grf_scan "$GRA" --tree; rc=$?
_grf_is "a tracked symlink to a regular file is still read through, and its key found, exit 1 (X4)" "$rc" "1"
_grf_new x4-key; GRA="$GRR"
printf 'aws = "%s"\n' "$grf_key" >> "$GRA/src.txt" 2>/dev/null; _grf_commit "$GRA" key
_grf_scan "$GRA" --tree; rc=$?
_grf_is "a tracked file holding a key still exits 1 (X4)" "$rc" "1"

# --------------------------------------------------------------- P: the pulse ----
_grf_pulse() { _grf_sh 120 'set -u; . "$1/lib/resolve.sh"; . "$1/lib/pulse.sh"; felix_pulse_backup "$2"' "$1"; }
_grf_committed() { printf '%s\n' "$1" | awk -v l="$(printf 'backup\tcommitted')" '$0 == l { n++ } END { print n + 0 }'; }
_grf_notbacked() { printf '%s\n' "$1" | awk -F'\t' '$1 == "backup" && index($0, "NOT backed up") { n++ } END { print n + 0 }'; }
# An edit already staged, as a person leaves one, then a tracked pipe: `add -A`
# stages nothing more and fails, and a commit would take what was staged.
_grf_new p1; GRA="$GRR"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _fx_git "$GRA" add src.txt >/dev/null 2>&1; _grf_pipe "$GRA" A.txt
grf_h0="$(git -C "$GRA" rev-parse HEAD 2>/dev/null)"
out="$(_grf_pulse "$GRA")"
_grf_is "the pulse makes no commit over a tracked pipe, HEAD unchanged (P1)" "$(git -C "$GRA" rev-parse HEAD 2>/dev/null)" "$grf_h0"
_grf_is "and prints no backup committed line (P1)" "$(_grf_committed "$out")" "0"
_grf_is "and prints a backup line saying NOT backed up (P1)" "$([ "$(_grf_notbacked "$out")" -gt 0 ] && echo said || echo unsaid)" "said"
_grf_unpipe "$GRA" A.txt
_grf_new p1-unstaged; GRA="$GRR"
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_pipe "$GRA" A.txt
grf_h0="$(git -C "$GRA" rev-parse HEAD 2>/dev/null)"
out="$(_grf_pulse "$GRA")"
_grf_is "and with the edit unstaged the same: no commit, no committed line, NOT backed up (P1)" \
        "$([ "$(git -C "$GRA" rev-parse HEAD 2>/dev/null)" = "$grf_h0" ] && echo same || echo moved) $(_grf_committed "$out") $([ "$(_grf_notbacked "$out")" -gt 0 ] && echo said || echo unsaid)" \
        "same 0 said"
_grf_unpipe "$GRA" A.txt
_grf_new p2; GRA="$GRR"; printf 'three\n' >> "$GRA/src.txt" 2>/dev/null
[ -n "$_grf_fx" ] || [ ! -e "$GRF/no-such-tmpdir" ] || _grf_fx="the missing TMPDIR exists"
grf_h0="$(git -C "$GRA" rev-parse HEAD 2>/dev/null)"
out="$(export TMPDIR="$GRF/no-such-tmpdir"; _grf_pulse "$GRA" 2>/dev/null)"
_grf_is "with no scratch index to ask the nested-repository question on, the pulse makes no commit (P2)" \
        "$(git -C "$GRA" rev-parse HEAD 2>/dev/null)" "$grf_h0"
_grf_is "and says NOT backed up (P2)" "$([ "$(_grf_notbacked "$out")" -gt 0 ] && echo said || echo unsaid)" "said"

# -------------------------------------------------------------- D: the digest ----
_grf_dig() { _grf_sh 30 'set -u; . "$1/lib/resolve.sh"; . "$1/lib/discover.sh"; felix_discover_digest "$2"' "$1"; }
_grf_fx=""; GRA="$(mktemp -d "$GRF/d.XXXXXX")"
printf 'a\n' > "$GRA/a.txt"; printf 'b\n' > "$GRA/b.txt"
grf_d0="$(_grf_dig "$GRA")"
[ -n "$grf_d0" ] || _grf_fx="the readable directory has no digest"
mkfifo "$GRA/p.fifo" 2>/dev/null; [ -n "$_grf_fx" ] || [ -p "$GRA/p.fifo" ] || _grf_fx="no pipe could be made"
out="$(_grf_dig "$GRA")"; rc=$?
_grf_is "a pipe in the directory neither hangs the digest nor changes it (D2)" "$rc|$out" "0|$grf_d0"
_grf_unpipe "$GRA" p.fifo
chmod 000 "$GRA/b.txt" 2>/dev/null
if [ -z "$_grf_fx" ] && [ -r "$GRA/b.txt" ]; then
  skip "a regular file that cannot be read leaves no digest: nothing printed, a failing status (D1)" "this user can read a mode-000 file"
else
  out="$(_grf_dig "$GRA")"; rc=$?
  _grf_is "a regular file that cannot be read leaves no digest: nothing printed, a failing status (D1)" \
          "[$out] $(_grf_nz "$rc")" "[] non-zero"
fi
chmod 644 "$GRA/b.txt" 2>/dev/null

# ------------------------------------------------ after the review, not blind ----
# Written 2026-10-08 by the session that wrote the fix, after its adversarial
# review and a mutation run, so NOT blind. Each assertion pins a review finding
# (H high, M medium, L low) or a hunk of the fix that, reverted to origin/main,
# left every blind assertion green (h and its number in the mutation index).
# The ones marked "regression" pass on origin/main too, and failed only on an
# earlier draft of the fix.
out="$(_grf_sh 30 '. "$1/lib/resolve.sh"; _felix_git_read v sh -c "printf \"+foo.\\n\"; exit 128"; printf "%s|%s" "$?" "$v"')"
_grf_fx=""; _grf_is "a read git broke off just after a line ending in a dot has not finished (the read mark)" "$out" "1|+foo."
out="$(_grf_sh 30 '. "$1/lib/resolve.sh"; _felix_git_read v printf "a\\n\\n\\n"; printf "%s|%s" "$?" "$v"')"
_grf_is "a finished read is 0, its trailing newlines dropped as a substitution drops them (the read mark)" "$out" "0|a"
# CPU, not wall: other suites share this machine. The old strip measured 1.9 s
# of CPU on a 400 KB diff in the C locale, and grows with the square of it.
_grf_new t10; GRA="$GRR"
perl -e 'my $l = ("x" x 79) . "\n"; print $l for 1 .. 20000' > "$GRA/big.txt" 2>/dev/null
_fx_git "$GRA" add big.txt >/dev/null 2>&1 || { [ -n "$_grf_fx" ] || _grf_fx="the large file could not be staged"; }
out="$(_grf_sh 240 '. "$1/lib/resolve.sh"; . "$1/lib/verify.sh"; id="$(felix_tree_id "$2")"; [ -n "$id" ] || exit 3; times' "$GRA" \
       | awk 'NR == 2 { split($1, a, /[ms]/); print (a[1] * 60 + a[2] < 5) ? "under" : "over: " $1 }')"
_grf_is "the tree id of a 1.6 MB diff costs well under five seconds of CPU (H1, a quadratic newline strip, regression)" "$out" "under"

_grf_new t11; GRA="$GRR"
grf_i0="$(_grf_tid "$GRA")"; grf_f="$GRA/$(printf 'Shot\342\200\257PM.png')"
printf 'png1' > "$grf_f" 2>/dev/null; grf_i1="$(_grf_tid "$GRA")"
printf 'png22' > "$grf_f" 2>/dev/null; grf_i2="$(_grf_tid "$GRA")"
_grf_is "an untracked file named past ASCII changes the tree id, and so does a change to its size (M1)" \
        "$([ -n "$grf_i2" ] && [ "$grf_i0" != "$grf_i1" ] && [ "$grf_i1" != "$grf_i2" ] && echo distinct || echo "[$grf_i0] [$grf_i1] [$grf_i2]")" "distinct"
printf 'x' > "$GRA/$(printf 'new\nline.txt')" 2>/dev/null; grf_i3="$(_grf_tid "$GRA")"
_grf_is "and a name git quotes whatever quotePath says is still counted by its presence (M1)" \
        "$([ -n "$grf_i3" ] && [ "$grf_i3" != "$grf_i2" ] && echo counted || echo "[$grf_i2] [$grf_i3]")" "counted"

_grf_new x5; GRA="$GRR"; ( _fx_cd "$GRA" && git checkout -q -b feat ) >/dev/null 2>&1
printf 'aws = "%s"\n' "$grf_key" > "$GRA/$(printf 'cl\303\251.env')" 2>/dev/null
_grf_scan "$GRA" main; rc=$?
_grf_is "an untracked file named past ASCII is scanned, and its key found, exit 1 (H4)" "$rc" "1"
_grf_commit "$GRA" accent
_grf_scan "$GRA" --tree; rc=$?
_grf_is "and the same file tracked is scanned by --tree, exit 1 (H4)" "$rc" "1"
_grf_new x5-newline; GRA="$GRR"; ( _fx_cd "$GRA" && git checkout -q -b feat ) >/dev/null 2>&1
printf 'aws = "%s"\n' "$grf_key" > "$GRA/$(printf 'new\nline.env')" 2>/dev/null
_grf_scan "$GRA" main; rc=$?
_grf_is "and so is an untracked file whose name holds a newline, exit 1 (H4)" "$rc" "1"
_grf_new x6; GRA="$GRR"; ( _fx_cd "$GRA" && git checkout -q -b feat ) >/dev/null 2>&1
printf '\211PNG\r\n\032\n\000\377\376\375 binary\n' > "$GRA/shot.png" 2>/dev/null
( export LC_ALL=en_US.UTF-8; _grf_scan "$GRA" main ); rc=$?
_grf_is "an untracked binary file under a UTF-8 locale is read as bytes, not refused, exit 0 (M2, regression)" "$rc" "0"
_grf_new x7-link; GRA="$GRR"; printf 'x\n' > "$GRF/x7-unreadable.txt"; chmod 000 "$GRF/x7-unreadable.txt" 2>/dev/null
ln -s "$GRF/x7-unreadable.txt" "$GRA/link.txt" 2>/dev/null; _grf_commit "$GRA" link
if [ -z "$_grf_fx" ] && [ -r "$GRF/x7-unreadable.txt" ]; then
  skip "a tracked symlink to a file nobody may read is skipped by --tree, exit 0 (L1, regression)" "this user can read a mode-000 file"
else
  _grf_scan "$GRA" --tree; rc=$?
  _grf_is "a tracked symlink to a file nobody may read is skipped by --tree, exit 0 (L1, regression)" "$rc" "0"
fi
chmod 644 "$GRF/x7-unreadable.txt" 2>/dev/null
_grf_new x8; GRA="$GRR"; printf 'x\n' > "$GRA/u.txt" 2>/dev/null; chmod 000 "$GRA/u.txt" 2>/dev/null
if [ -z "$_grf_fx" ] && [ -r "$GRA/u.txt" ]; then
  skip "an untracked file nobody may read leaves the scan unfinished, exit 2 (h07)" "this user can read a mode-000 file"
else
  _grf_scan "$GRA" main; rc=$?
  _grf_is "an untracked file nobody may read leaves the scan unfinished, exit 2 (h07)" "$rc" "2"
fi
chmod 644 "$GRA/u.txt" 2>/dev/null
_grf_fx=""; GRA="$(mktemp -d "$GRF/x9.XXXXXX")"
( _fx_cd "$GRA" && git init -q -b trunk && printf 'aws = "%s"\n' "$grf_key" > k.txt && git add k.txt ) >/dev/null 2>&1 \
  || _grf_fx="the unborn repository could not be made"
_grf_scan "$GRA"; rc=$?
_grf_is "a key staged before the first commit, with no base anywhere, is found, exit 1 (h12)" "$rc" "1"
_grf_new x10; GRA="$GRR"
( _fx_cd "$GRA" && git checkout -q --orphan lone && printf 'aws = "%s"\n' "$grf_key" > k.txt && git add k.txt ) >/dev/null 2>&1 \
  || { [ -n "$_grf_fx" ] || _grf_fx="no orphan branch could be made"; }
_grf_scan "$GRA" main; rc=$?
_grf_is "on an orphan branch with no commit yet, a staged key is found against a base that resolves, exit 1 (h11)" "$rc" "1"

_grf_new p3; GRA="$GRR"; printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_corrupt "$GRA"
out="$(_grf_pulse "$GRA")"
_grf_is "the pulse over a corrupt index says NOT backed up, never that nothing is new (H2)" \
        "$([ "$(_grf_notbacked "$out")" -gt 0 ] && echo said || echo unsaid) $(printf '%s\n' "$out" | awk 'index($0, "nothing new") { n++ } END { print n + 0 }')" \
        "said 0"
_grf_new p4; GRA="$GRR"; printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_pipe "$GRA" A.txt
out="$(_grf_pulse "$GRA")"
_grf_has "the pulse over a tracked pipe names the path git could not stage (L2)" \
         "$(printf '%s\n' "$out" | awk -F'\t' '$1 == "backup" && index($0, "NOT backed up")')" "A.txt"
_grf_unpipe "$GRA" A.txt

# The CLI over one change: a feature branch, an edit, and a pipe at A.txt.
# A function, because bash 3.2 cannot parse a case pattern's `)` inside `$(...)`.
_grf_said() { case "$1" in *"$2"*) printf 'said' ;; *) printf 'unsaid' ;; esac; }
_grf_new c1; GRA="$GRR"; ( _fx_cd "$GRA" && git checkout -q -b feat ) >/dev/null 2>&1
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_commit "$GRA" edit
printf 'four\n' >> "$GRA/src.txt" 2>/dev/null; _grf_pipe "$GRA" A.txt
out="$( cd "$GRA" && FELIX_HOME="$GRFH" FELIX_MEMORY="$GRFM" perl -e 'alarm shift; exec @ARGV or exit 127' 240 "$FELIX" gate 2>&1 >/dev/null )"
_grf_has "felix gate there says on stderr that no receipt was written (h13)" "$out" "no receipt was written"
out="$(_grf_felix "$GRA" pr)"; rc=$?
_grf_is "felix pr there refuses, exit non-zero, saying git could not read the change (h14)" \
        "$(_grf_nz "$rc") $(_grf_said "$out" "could not read this change to the end")" "non-zero said"
_grf_has "and quotes git, which names the pipe (M3)" "$out" "A.txt"
out="$(_grf_felix "$GRA" classify)"; rc=$?
_grf_is "felix classify there says Not classified and exits 1 (h17)" \
        "$rc $(_grf_said "$out" "Not classified")" "1 said"
out="$(_grf_felix "$GRA" next)"
_grf_has "felix next there ranks the unread change first, as not scanned in full (h33)" "$out" "not scanned in full: ADDED-LINES"
_grf_lacks "and does not send anyone to fix a base that resolves (M3)" "$out" "name a base that exists here"
out="$(_grf_felix "$GRA" merge --dry-run)"
_grf_has "felix merge --dry-run there says git could not read all of the change (M3)" "$out" "git could not read all of this change"
_grf_lacks "and never that the base names nothing (M3)" "$out" "The base names nothing"
_grf_lacks "nor that the rest escapes nothing (M3)" "$out" "escapes nothing"
out="$(_grf_felix "$GRA" receipt)"
_grf_has "felix receipt there lists risk as unknown (h41)" "$(_grf_rcpt_unknown "$out")" '"risk"'
_grf_has "and the escapes (h42)" "$(_grf_rcpt_unknown "$out")" '"escapes"'
_grf_has "and asks no founder to decide about a change nobody could read (h42, h43)" "$out" '"founder_required": false'
_grf_unpipe "$GRA" A.txt
_grf_new c2; GRA="$GRR"; ( _fx_cd "$GRA" && git checkout -q -b feat ) >/dev/null 2>&1
printf 'three\n' >> "$GRA/src.txt" 2>/dev/null; _grf_corrupt "$GRA"
out="$(_grf_felix "$GRA" receipt)"
_grf_has "felix receipt over a corrupt index says the changed paths are not known (h39, h44)" "$out" '"changed": {"known": false'

_grf_new e8; GRA="$GRR"
( _fx_cd "$GRA" && git checkout -q --orphan lone && _grf_git commit -qm lone ) >/dev/null 2>&1 \
  || { [ -n "$_grf_fx" ] || _grf_fx="no orphan branch with a commit could be made"; }
out="$(_grf_esc "$GRA")"
_grf_has "a branch sharing no history with the base is unknown, in git's own words (M3)" \
         "$(printf '%s\n' "$out" | awk -F'\t' '$1 == "unknown" { print $3 }')" "no merge base"

unset -f _grf_git _grf_new _grf_commit _grf_pipe _grf_unpipe _grf_corrupt _grf_is _grf_has _grf_lacks _grf_nz \
  _grf_n1 _grf_blocked _grf_sh _grf_tid _grf_dirty _grf_added _grf_changed _grf_added_pf _grf_changed_pf _grf_esc \
  _grf_blk _grf_cls _grf_tier _grf_finds _grf_ev _grf_owed _grf_felix _grf_hook _grf_rec _grf_cur _grf_recipe \
  _grf_vrows _grf_wf _grf_unknown_row _grf_execute _grf_esc_stub _grf_dsc _grf_publish _grf_rcpt_unknown \
  _grf_rcpt_status _grf_scoped _grf_scan _grf_pulse _grf_committed _grf_notbacked _grf_dig _grf_said

