# tests/lib/fresh-repos.sh: the fresh-repository fixtures of the heal section.
# Used by 0180 (builds them), 0190 (the same project helpers and the
# gate_shown_failing check). Moved from parts/0180-fresh-repositories-split-mistakes-rows-heal.sh:
# _fh_proj, _fh_root, _fh_setgate, _fh_script (lines 26-35), _fh_cmhdr and
# _fh_cmrow (52-53), _fh_gsf (61), the awk at line 58 as _fh_gsf_chk_load, and
# the discovery lock at lines 18-21 as _fresh_repos_lock.
# Definitions only. _fh_gsf_chk_load sets _fh_gsf_chk (the same string every time).
# _fresh_repos_lock takes the discovery lock once: when _fh_dlock_mine is already
# set, as it is after 0180 ran, it changes nothing, so the lock 0180 takes is the
# lock the end of 0190 lets go of, in the serial run as it always was.

# A project, its memory, and a born checkout bound to it by marker, with no
# probes, qualification, obligations or commissioning table: the gate runs the
# project's own command and skips every engine check, unless a block adds one.
_fh_proj() {
  mkdir -p "$FROOT/projects/$1" "$MEM/$1" "$TMP/fr-$1"
  printf '{"name":"%s","gate":"%s"}\n' "$1" "$2" > "$FROOT/projects/$1/project.json"
  printf '# %s\n' "$1" > "$FROOT/projects/$1/CLAUDE.md"
  ( _fx_cd "$TMP/fr-$1" && git init -q -b main && printf '%s\n' "$1" > .felix && printf 'x\n' > README.md \
    && git add -A && git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
}
_fh_root()    { ( cd "$TMP/fr-$1" && pwd -P ); }
_fh_setgate() { printf '{"name":"%s","gate":"%s"}\n' "$1" "$2" > "$FROOT/projects/$1/project.json"; }
_fh_script()  { printf '#!/usr/bin/env bash\n%s\n' "$2" > "$FROOT/projects/$1/gate.sh"; chmod +x "$FROOT/projects/$1/gate.sh"; }
_fh_cmhdr() { printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\n'; }
_fh_cmrow() { grep -E "^$1$(printf '\t')" "$FROOT/harness/templates/commissioning.tsv" | head -n 1; }
_fh_gsf() { ( FELIX_MEMORY_DIR="$1"; [ -n "$_fh_gsf_chk" ] || exit 99; eval "$_fh_gsf_chk" ) >/dev/null 2>&1; }

# _fh_gsf_chk_load: the reader the split row was lost on, copied verbatim from the
# template's gate_shown_failing row (it was one assignment in 0180).
_fh_gsf_chk_load() {
  _fh_gsf_chk="$(awk -F'\t' '$1 == "gate_shown_failing" { print $6; exit }' "$FROOT/harness/templates/commissioning.tsv")"
}

# _fresh_repos_lock: discovery's background refresh would start from a
# session-start call and reach for the network. Holding its lock keeps the hook
# offline, and only a lock this call took is let go (_fh_dlock_mine is 1 then).
# Sets _fh_dlock and _fh_sp (a pid kept for the heal-lock case, empty by default).
_fresh_repos_lock() {
  _fh_dlock="$FROOT/state/discover/.lock"; _fh_sp="${_fh_sp:-}"
  [ -n "${_fh_dlock_mine:-}" ] && return 0
  _fh_dlock_mine=0
  mkdir -p "$FROOT/state/discover" && mkdir "$_fh_dlock" 2>/dev/null && _fh_dlock_mine=1
  return 0
}
