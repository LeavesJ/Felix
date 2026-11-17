# tests/lib/locale-bytes.sh: the en_US UTF-8 locale name the locale parts pick, and the skip reason.
# Used by 0992 (picks it in the serial run), 0994 0996 0998 (LCB_U8, LCB_NONE) and
# 0992 alone for LCB_DROPS. Moved from parts/0992-sort-comm-join-and-uniq-read-bytes-in-the-c-l.sh
# lines 29-34 (verbatim, in the function body below).
# Definitions only. _locale_bytes_vars sets LCB_NONE first, and does nothing more once
# LCB_DROPS is set, so a later call in the serial run leaves everything as it was.

_locale_bytes_vars() {
  LCB_NONE="no en_US UTF-8 locale is installed here"
  [ -n "${LCB_DROPS:-}" ] && return 0
  LCB_U8="$(locale -a 2>/dev/null | awk '/^en_US\.(UTF-8|utf8)$/ && !n++')"
  # Whether sort in that locale drops its whole output on a line it cannot
  # decode, which BSD sort does and glibc sort does not.
  LCB_DROPS=0
  [ -n "$LCB_U8" ] && [ -z "$(printf 'x\377\n' | LC_ALL="$LCB_U8" sort 2>/dev/null)" ] && LCB_DROPS=1
  return 0
}
