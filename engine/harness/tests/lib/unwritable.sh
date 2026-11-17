# tests/lib/unwritable.sh: whether this user can be refused a write by a mode.
# Used by 0150 (computes it in the serial run), 0390 and 0690 (they read
# _unwritable and _nowrite to skip the assertions that need a refused write).
# Moved from parts/0150-the-unattended-repair-leaves-the-model-no-cr.sh lines
# 213-219 (verbatim, in the function body below).
# Definitions only. _unwritable_probe sets _unwritable (1 when a directory at
# 555 and a file at 444 both refuse a write, 0 when this user writes through
# them, as root does) and _nowrite (the skip reason). It sets _nowrite first and
# does nothing more once _unwritable is set, so a later call in the serial run
# leaves everything as it was.

_unwritable_probe() {
  _nowrite="this user writes through a mode of 555 or 444, so no write can be refused"
  [ -n "${_unwritable:-}" ] && return 0
  mkdir "$TMP/mode-555"; chmod 555 "$TMP/mode-555"
  printf 'x\n' > "$TMP/mode-444"; chmod 444 "$TMP/mode-444"
  _unwritable=1
  ( : > "$TMP/mode-555/x" ) 2>/dev/null && _unwritable=0
  ( printf 'x\n' >> "$TMP/mode-444" ) 2>/dev/null && _unwritable=0
  chmod 755 "$TMP/mode-555"; chmod 644 "$TMP/mode-444"
}
