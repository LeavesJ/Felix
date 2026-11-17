# tests/lib/bw.sh: the time, throwaway-checkout and memory-file helpers of the
# blind restatement of the guard's contract (the _bw* names).
# Used by 0280 (builds them, and uses every other _bw* name it defines itself) and
# 0290 (_bwday, _bwmt, _bwrepo, _bwreset, and _BWT for the catch it files). Moved
# from parts/0280-unrecorded-catches-settled-by-their-writer-b.sh: _bwago,
# _bwstamp, _bwday, _bwmt (lines 31-34), _bwreset (38), _bwg, _bwrepo (63-64), all
# verbatim; _BWD, _BWK, _BWW, _BWL, _BWV (26-27) and _BWN (29) are assigned by the
# builder below, and _BWT (212) is set there too.
# Definitions only. _bw_build assigns the five path names first, the same strings
# every time. It then returns when _BWN is set, which is the case in the serial run
# after 0280's call: the clock-valued _BWN and _BWT are assigned once, so a later
# call leaves the minutes 0280 stated as they were. These are the prelude's from
# the first line of the suite on: 0290 unsets only the names it and 0280 define.

_bwago()   { printf '%s' "$(( _BWN - $1 * 60 ))"; }
_bwstamp() { date -r "$1" +%Y%m%d%H%M.%S 2>/dev/null || date -d "@$1" +%Y%m%d%H%M.%S; }
_bwday()   { date -r "$1" +%Y-%m-%d 2>/dev/null || date -d "@$1" +%Y-%m-%d; }
_bwmt()    { touch -t "$(_bwstamp "$1")" "$2"; }

_bwreset() { rm -f "$_BWK" "$_BWW" "$_BWL" "$_BWV"; }

# throwaway checkouts
_bwg() { git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
_bwrepo() { mkdir -p "$1" && ( cd "$1" && _bwg init -q -b "$2" && _bwg commit -q --allow-empty -m init ) >/dev/null 2>&1; }

# _bw_build: the memory files' names, the clock the cases are stated against
# (_BWN, now) and the instant of the catch they file (_BWT, half an hour before).
_bw_build() {
  _BWD="$MEM/guarded"; _BWK="$_BWD/mistakes.log"; _BWW="$_BWD/written.log"
  _BWL="$_BWD/lessons.md"; _BWV="$_BWD/DEVLOG.md"
  [ -n "${_BWN:-}" ] && return 0
  _BWN="$(date +%s)"
  _BWT="$(_bwago 30)"
}
