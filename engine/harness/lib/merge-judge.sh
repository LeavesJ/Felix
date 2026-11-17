# felix merge hands its verdict to the engine main holds (audit b13, C067 and C063;
# docs/2026-10-24-audit-fixes/b13-felix-cli-trust-and-binding.md, B1 to B14).
#
# THE GAP. felix merge checks that the installed copy of main's version is byte-identical to main,
# and until now it then formed the verdict in whichever felix the session had typed: the
# candidate's own cmd_merge decided, and merged through gh. Only the blockers came from main.
# README.md said the candidate never judges itself, and from a branch that was not true.
#
# THE RULE. A self-governed checkout, after every refusal felix merge makes before it computes a
# blocker, hands the whole command to a copy of main's engine unless the felix that runs IS the
# installed entry (the land tick starts it so, and judges in place). The copy is made out of git
# for that one run under TMPDIR/felix-merge-main.XXXXXX/<version>/, run in the same directory with
# the same arguments, and removed however the run ends. The entry is read to be compared with
# main and is never executed or sourced on this path: the copy's own libraries form the verdict,
# in the copy's felix, which checks the real entry itself and names it in its output.
#
# THE COPY IS MAIN'S BYTES. One git process for the whole tree, run against a scratch repository
# that borrows the checkout's objects and reads no machine-local config (_felix_git_rules), so
# nothing in the checkout's attributes, core.autocrlf or a global config touches a byte. Its
# info/attributes unsets the six attributes checkout converts by, which outranks main's own
# .gitattributes and the machine's (trust step 3, spec A22 as amended). The scratch repository is
# gone before the copy runs.
#
# THE MARKER. FELIX_MERGE_HANDED=1 is set for the copy, and a felix that is not the entry and is
# not that copy refuses when it finds it set: a caller that sets it can only be skipping the
# hand-off, and the marker must never skip it. The copy knows itself by where it runs (a
# felix-merge-main directory under TMPDIR, owned by this user) and by being byte-identical to main.
#
# WHAT THIS DOES NOT BIND. A branch whose own felix no longer hands off, run from that branch, still
# judges itself: nothing inside a CLI binds that CLI. The pins outside it are the land tick and
# roadmap step 15 (the judge pinned outside the change it judges). A same-user race that swaps
# the copy between its check and its use is the same kind of gap, and so is a SIGKILL, which
# leaves the copy behind. A descendant of the copy that a signal reaches only through the copy
# (a gh call in flight) is not stopped: the copy is.
#
# Sourced by felix beside handoff.sh. Needs resolve.sh (_felix_git_rules, _felix_plugin_version,
# felix_accepted_deploy_diff) and felix's own _felix_merge_die.

_MJ_COPY=""; _MJ_SCRATCH=""; _MJ_PID=""; _MJ_RC=0; _MJ_WHY=""

# Remove what a hand-off made, the copy and the scratch repository it was cut with.
_mj_clean() {
  [ -z "$_MJ_COPY" ] || rm -rf "$_MJ_COPY"
  [ -z "$_MJ_SCRATCH" ] || rm -rf "$_MJ_SCRATCH"
  _MJ_COPY=""; _MJ_SCRATCH=""
}

# A signal reached felix merge while a hand-off was under way. bash holds a trap while a foreground
# child runs, which is why the copy is waited for (felix_merge_handoff): this runs as soon as the
# wait is interrupted. The copy is stopped with TERM, and with KILL if it has not gone in eight
# seconds, and what the hand-off made is removed, so the command ends within ten. Eight because a
# copy that is running P's suite (lib/instrument-run.sh) needs about two to stop its units and
# remove its run tree, and a copy killed first left that tree behind (spec-slice3 A7.4). Since spec-slice3 A9 the
# copy ends at once wherever it is (lib/instrument-run.sh's felix_instr_grp), so the eight seconds are a bound. QUIT
# is held as the other three are (A9: a signal at any point removes everything).
_mj_stop() {   # EXIT-STATUS
  local i=0
  trap '' TERM INT HUP QUIT
  if [ -n "$_MJ_PID" ]; then
    kill -TERM "$_MJ_PID" 2>/dev/null
    while [ "$i" -lt 80 ] && kill -0 "$_MJ_PID" 2>/dev/null; do sleep 0.1; i=$((i + 1)); done
    if kill -0 "$_MJ_PID" 2>/dev/null; then kill -KILL "$_MJ_PID" 2>/dev/null; fi
    wait "$_MJ_PID" 2>/dev/null
  fi
  _mj_clean
  exit "$1"
}

# Main's engine/ out of git into $_MJ_COPY/<version>/: every path M tracks and no other, each file
# as its blob holds it, mode 755 executable by its owner and mode 644 not. Returns 0, 1 with
# _MJ_WHY when it could not, 2 when it could and the copy holds no executable harness/felix.
_mj_make() {   # ROOT SHA VERSION
  local root="$1" sha="$2" ver="$3" tmpd="${TMPDIR:-/tmp}" objs err e
  _MJ_COPY="$(mktemp -d "${tmpd%/}/felix-merge-main.XXXXXX" 2>/dev/null)" \
    || { _MJ_COPY=""; _MJ_WHY="no directory could be made under ${tmpd%/}"; return 1; }
  _MJ_SCRATCH="$(mktemp -d "${tmpd%/}/felix-merge-scratch.XXXXXX" 2>/dev/null)" \
    || { _MJ_SCRATCH=""; _MJ_WHY="no directory could be made under ${tmpd%/}"; return 1; }
  objs="$(git -C "$root" rev-parse --path-format=absolute --git-path objects 2>/dev/null </dev/null)"
  [ -n "$objs" ] && [ -d "$objs" ] || { _MJ_WHY="git named no object directory for $root"; return 1; }
  err="$_MJ_SCRATCH/err"
  if ! { _felix_git_rules "$_MJ_SCRATCH" init -q --template= >/dev/null 2>"$err" \
         && mkdir -p "$_MJ_SCRATCH/.git/objects/info" \
         && printf '%s\n' "$objs" > "$_MJ_SCRATCH/.git/objects/info/alternates" \
         && mkdir -p "$_MJ_SCRATCH/.git/info" && printf '* -text -eol -crlf -ident -filter -working-tree-encoding\n' > "$_MJ_SCRATCH/.git/info/attributes" \
         && _felix_git_rules "$_MJ_SCRATCH" read-tree "$sha:engine" >/dev/null 2>>"$err" \
         && _felix_git_rules "$_MJ_SCRATCH" checkout-index -a --prefix="$_MJ_COPY/$ver/" >/dev/null 2>>"$err"; }; then
    e="$(LC_ALL=C sed -n '1p' "$err" 2>/dev/null)"; e="${e//"$_MJ_COPY"/the copy}"
    _MJ_WHY="git said: ${e:-nothing}"; return 1
  fi
  rm -rf "$_MJ_SCRATCH"; _MJ_SCRATCH=""
  [ -x "$_MJ_COPY/$ver/harness/felix" ] && [ -f "$_MJ_COPY/$ver/harness/felix" ] || return 2
  return 0
}

# Is the felix that runs the copy a hand-off made? It runs from <phys TMPDIR>/felix-merge-main.XXXXXX/<V>/harness,
# the directory is this user's, and <V> there is byte-identical to the engine main holds, asked the way
# the entry is asked (the copy's parent stands in for the cache).
_mj_is_copy() {   # ROOT BASE VERSION
  local root="$1" base="$2" ver="$3" tmpd="${TMPDIR:-/tmp}" here cr
  tmpd="$(cd "${tmpd%/}/" 2>/dev/null && pwd -P)" || return 1
  here="$(cd "$SCRIPT_DIR" 2>/dev/null && pwd -P)" || return 1
  cr="${here%/"$ver"/harness}"
  [ -n "$ver" ] && [ "$cr" != "$here" ] && [ "${cr%/*}" = "$tmpd" ] || return 1
  case "${cr##*/}" in felix-merge-main.*) ;; *) return 1 ;; esac
  [ -O "$cr" ] || return 1
  ( FELIX_KERNEL_CACHE="$cr"; felix_accepted_deploy_diff "$root" "$base" ) >/dev/null 2>&1
}

# The hand-off. Called by cmd_merge after its last pre-hand-off refusal, from a felix that is not the
# installed entry, with the arguments cmd_merge was given. Returns 0 when it ran the copy, whose status
# is in $_MJ_RC; returns 10 when this felix is itself the copy, which then judges in place; and ends
# the command with a refusal (exit 1, one refused row unless dry) when it can do neither.
felix_merge_handoff() {   # ROOT BASE JENTRY DRY PROJ BRANCH ARGS...
  local root="$1" base="$2" dry="$4" proj="$5" branch="$6" sha ver exe rc
  shift 6
  sha="$(git -C "$root" rev-parse --verify --quiet "$base^{commit}" 2>/dev/null </dev/null)"
  ver="$(_felix_plugin_version "$root" "${sha:-$base}")"
  if [ -n "${FELIX_MERGE_HANDED:-}" ]; then
    _mj_is_copy "$root" "$base" "$ver" && return 10
    _felix_merge_die "$dry" "$proj" "$branch" judge "FELIX_MERGE_HANDED is set, and this felix is neither the installed engine main declares nor the copy of it that felix merge makes: felix merge hands its verdict to that copy and sets the variable only for it, so a caller who sets it can only be skipping the hand-off, which it never does. Unset it."
  fi
  [ -n "$sha" ] && [ -n "$ver" ] \
    || _felix_merge_die "$dry" "$proj" "$branch" judge "could not copy main's engine: $base names no commit with a version here"
  trap '_mj_stop 143' TERM; trap '_mj_stop 130' INT; trap '_mj_stop 129' HUP; trap '_mj_stop 131' QUIT
  _mj_make "$root" "$sha" "$ver"; rc=$?
  if [ "$rc" -ne 0 ]; then
    trap - TERM INT HUP QUIT; ! command -v _felix_bind_traps >/dev/null 2>&1 || _felix_bind_traps; _mj_clean
    if [ "$rc" -eq 2 ]; then
      _felix_merge_die "$dry" "$proj" "$branch" judge "could not copy main's engine: it has no harness/felix, so there is nothing to hand the verdict to"
    fi
    _felix_merge_die "$dry" "$proj" "$branch" judge "could not copy main's engine out of git: $_MJ_WHY"
  fi
  exe="$_MJ_COPY/$ver/harness/felix"
  # In the background and waited for, because a trap waits for a foreground child and a signal must not.
  # The copy gets the caller's environment and three changes, and the cache is not one of them: it
  # checks the real entry itself.
  ( export FELIX_HOME="$FELIX_HOME_DIR" FELIX_MERGE_HANDED=1; exec "$exe" merge "$@" ) <&0 &
  _MJ_PID=$!
  wait "$_MJ_PID"; _MJ_RC=$?
  _MJ_PID=""
  trap - TERM INT HUP QUIT; ! command -v _felix_bind_traps >/dev/null 2>&1 || _felix_bind_traps
  _mj_clean
  case "$_MJ_RC" in
    0|1|2|3|4) ;;
    *) printf "felix: main's engine ended felix merge with status %s, which felix merge never returns, so whether anything was merged is not known. Look at the pull request before running it again.\n" "$_MJ_RC" >&2 ;;
  esac
  return 0
}
