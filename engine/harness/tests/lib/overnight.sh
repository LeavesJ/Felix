# tests/lib/overnight.sh: the overnight library's helpers, and its project.
# Used by 0730 (the library, driven against NP) and 0740 (the grants, refusals
# and hooks, which use the same helpers and the same NP and NS). Moved from
# parts/0730-schema-check-every-table-declared-every-row.sh lines 402-427,
# verbatim: NP, NS and the directories as _overnight_build, and _ov, _ovdir,
# _ovfile, _ovfield, _ovreset, _ovexpire and _ovword as they were.
# Definitions only. _overnight_build sets NP and NS first and then makes the
# two directories, with mkdir -p, so a second call changes nothing. Neither part
# relies on the state the other leaves: each opens with _ovreset "$NP", which
# removes the night's files, so there is no state to name.

# _overnight_build: NP is the project directory the library is driven against,
# NS the session it is driven for, and $MEM/nightproj the memory keyed on NP's
# basename.
_overnight_build() {
  NP="$TMP/nightproj"
  NS="lib-night"
  mkdir -p "$NP" "$MEM/nightproj"
}

_ov() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/overnight.sh"; "$@" 2>&1 ); }
_ovdir()   { _ov felix_overnight_dir "$1"; }
# A night is a session's, so every helper takes the session last. Given none, a
# helper reads the one project-wide file an older engine wrote, which is still
# read, swept and ended so that a night granted before the change is closed.
_ovfile()  { if [ -n "${2:-}" ]; then printf '%s/nights/%s' "$(_ovdir "$1")" "$2"
             else printf '%s/active' "$(_ovdir "$1")"; fi; }
# One field of the one-line state. Read with awk rather than cut so a note that
# smuggled in a newline shows up as a second record instead of being averaged
# into the answer.
_ovfield() { awk -F'\t' -v f="$2" 'NR==1 {print $f}' "$(_ovfile "$1" "${3:-}")" 2>/dev/null; }
_ovreset() { local d; d="$(_ovdir "$1")"; rm -rf "$d/active" "$d/nights" "$d/marks" "$d/grants"; }
# Move the deadline into the past without touching any other field. The field
# it edits is the one the assertion below proves is the deadline, which is the
# only reason this rewrite is allowed to stand in for waiting eight hours.
_ovexpire() {
  local f p; f="$(_ovfile "$1" "${2:-}")"; p="$(( $(date +%s) - 120 ))"
  awk -F'\t' -v OFS='\t' -v p="$p" 'NR==1 {$2=p} 1' "$f" > "$f.edit" && mv "$f.edit" "$f"
}
# The longest word in a sentence, for asking whether some other surface repeated
# it. Guarded at the call site: an empty needle would match everything, which is
# this project's oldest way of writing an assertion that cannot fail.
_ovword() { printf '%s' "$1" | tr -cs 'A-Za-z' '\n' | awk '{ if (length($0) > length(m)) m = $0 } END { print m }'; }
