# tests/lib/adopt-refusals.sh: the watchdog, the snapshot and the assertion helpers
# of the adopt-refusal section, and the widget's four adopt paths set aside.
# Used by 0020 (defines its cases from them) and 0030 (its hook block and its
# closing clean-up, the second half of 0020's section).
# Moved from parts/0020-adopting-over-a-capabilities-entry-that-is-n.sh:
# _adrtree through _adronly from lines 15-86 and _adrclear from lines 324-330
# (verbatim); _adopt_refusals_vars reproduces lines 13-14 and the two variables
# of line 320; _adopt_refusals_widget reproduces lines 320-323.
# Definitions only. The widget builder is guarded by its own effect: where the
# four paths are already set aside (or absent, as they are after 0020's last
# _adrclear) it moves nothing, so in the serial run 0030's call changes nothing.

# _adopt_refusals_vars: _adrwait is the watchdog deadline in seconds, _adrroot is 1
# when this user is root, _adrw is the widget project and _adrk where the
# widget's four adopt paths are kept while the block runs.
_adopt_refusals_vars() {
  _adrwait=10
  _adrroot=0; if [ "$(id -u)" = 0 ]; then _adrroot=1; fi
  _adrw="$FROOT/projects/widget"; _adrk="$TMP/_adr/widget-kept"
}

# _adopt_refusals_widget: whatever the widget holds at capabilities, stack.tsv,
# setup.tsv and setup is moved into $_adrk, to be put back at the end of the block.
_adopt_refusals_widget() {
  _adopt_refusals_vars
  mkdir -p "$_adrk"
  for _adrx in capabilities stack.tsv setup.tsv setup; do
    if [ -e "$_adrw/$_adrx" ] || [ -L "$_adrw/$_adrx" ]; then mv "$_adrw/$_adrx" "$_adrk/$_adrx"; fi
  done
}
_adrtree() { local c; printf '%s\n' "$1"; for c in $(pgrep -P "$1" 2>/dev/null); do _adrtree "$c"; done; }
_adrend() {
  local p
  kill -STOP "$1" 2>/dev/null
  for p in $(_adrtree "$1"); do kill -STOP "$p" 2>/dev/null; done
  for p in $(_adrtree "$1"); do kill -KILL "$p" 2>/dev/null; done
}
# _adrrun DIR SECONDS CMD...: stdout, stderr and status land in DIR/out,
# DIR/err and DIR/rc. DIR/hung holds the deadline when the watchdog ended it.
_adrrun() {
  local d="$1" s="$2" w i=0; shift 2
  rm -f "$d/out" "$d/err" "$d/rc" "$d/hung"
  ( "$@" > "$d/out" 2> "$d/err"; echo $? > "$d/rc" ) & w=$!
  while kill -0 "$w" 2>/dev/null && [ "$i" -lt $((s * 10)) ]; do sleep 0.1; i=$((i + 1)); done
  if kill -0 "$w" 2>/dev/null; then _adrend "$w"; echo "$s" > "$d/hung"; fi
  wait "$w" 2>/dev/null
  return 0
}
# One line per entry: kind, mode, and a link's target or a file's checksum.
# It only tests a pipe, never opens one; an absent path is a line too.
_adrsnap() {
  local r f
  for r in "$@"; do
    if [ ! -e "$r" ] && [ ! -L "$r" ]; then printf 'absent %s\n' "$r"; continue; fi
    find "$r" 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do
      if   [ -L "$f" ]; then printf 'L %s -> %s\n' "$f" "$(readlink "$f")"
      elif [ -p "$f" ]; then printf 'p %s %s\n' "$f" "$(ls -ld "$f" | cut -c1-10)"
      elif [ -d "$f" ]; then printf 'd %s %s\n' "$f" "$(ls -ld "$f" | cut -c1-10)"
      elif [ -f "$f" ]; then printf 'f %s %s %s\n' "$f" "$(ls -ld "$f" | cut -c1-10)" \
                                    "$({ cksum < "$f"; } 2>/dev/null || echo unreadable)"
      else printf '? %s %s\n' "$f" "$(ls -ld "$f" | cut -c1-10)"; fi
    done
  done
}
# _adrif DIR NAME DETAIL TEST...: a call the watchdog ended fails every
# assertion about it, whatever its files happen to hold.
_adrif() {
  local d="$1" n="$2" why="$3"; shift 3
  if [ -e "$d/hung" ]; then bad "$n" "still waiting after $(cat "$d/hung") seconds, so the watchdog ended it"
  elif "$@"; then ok "$n"
  else bad "$n" "$why"; fi
}
_adrcat()   { cat "$@" 2>/dev/null; }
_adreq()    { [ "$(cat "$1" 2>/dev/null)" = "$2" ]; }
_adrquiet() { [ -f "$1" ] && [ ! -s "$1" ]; }
_adrnone()  { [ ! -e "$1" ] && [ ! -L "$1" ]; }
_adrto()    { [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; }
_adrsame()  { cmp -s "$1/snap0" "$1/snap1"; }
_adrdiff()  { diff "$1/snap0" "$1/snap1" 2>&1 | sed -n '2,9p'; }
_adrsays()  { case "$(cat "$1" 2>/dev/null)" in *"$2"*) return 0 ;; esac; return 1; }
_adrtold()  { case "$(cat "$1/out" "$1/err" 2>/dev/null)" in *"$2"*) return 0 ;; esac; return 1; }
_adrnoclaim() {
  case "$(cat "$1/out" "$1/err" 2>/dev/null)" in
    *"already declared"*|*"declared observability for"*|*backfilled*) return 1 ;;
  esac
  return 0
}
_adrrows()  { local n; n="$(grep -cvE '^[[:space:]]*(#|$)' "$1" 2>/dev/null)"; printf '%s' "${n:-0}"; }
_adrcaps()  { grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null | tr '\n' ' '; }
_adrbytes() { [ -f "$1" ] && cmp -s "$1" "$2"; }
_adrprefix() { [ -f "$2" ] && [ "$(head -c "$(($(wc -c < "$1")))" "$2" | cksum)" = "$(cksum < "$1")" ]; }
_adrimplied() {  # PROJ: a stack row and a setup row for observability, and the runbook as the template has it
  [ "$(awk -F'\t' '$5 == "observability"' "$1/stack.tsv" 2>/dev/null | grep -c .)" -ge 1 ] \
    && [ "$(awk -F'\t' '$3 == "observability"' "$1/setup.tsv" 2>/dev/null | grep -c .)" -ge 1 ] \
    && cmp -s "$1/setup/sentry.md" "$FROOT/harness/templates/setup/sentry.md"
}
_adrmodebytes() {  # FILE PERMS KEPT: FILE still has PERMS and, once readable again, KEPT's bytes
  [ -f "$1" ] && [ ! -L "$1" ] && [ "$(ls -ld "$1" | cut -c1-10)" = "$2" ] || return 1
  chmod u+r "$1" && cmp -s "$1" "$3"
}
_adremptydir() { [ -d "$1" ] && [ ! -L "$1" ] && [ -z "$(ls -A "$1")" ]; }
_adronly()  { [ -d "$1" ] && [ ! -L "$1" ] && [ "$(ls -A "$1")" = "$2" ] && cmp -s "$1/$2" "$3"; }
_adrclear() {
  local x
  for x in capabilities stack.tsv setup.tsv setup; do
    [ -p "$_adrw/$x" ] && : <> "$_adrw/$x"
    rm -rf "$_adrw/$x"
  done
}
