# tests/lib/gov-names.sh: the names of the projects this checkout governs.
# Used by 0640 (the independence check, three places) and 0650 (the planted
# detector, one place). Moved from
# parts/0640-the-deployed-surface-is-three-directories.sh lines 222-231: the
# _REALP assignment and _gov_names. _REALP is now local to the function, so
# calling it assigns nothing a part reads (0410 and 0420 set a _REALP of their
# own, the felix project's directory, before 0640 and read it only there).
# Definitions only.

_gov_names() {   # every governed project except the engine's own name
  local meta n _REALP
  _REALP="$(cd "$REAL_HARNESS/../.." && pwd)/projects"
  [ -d "$_REALP" ] || return 0
  for meta in "$_REALP"/*/project.json; do
    [ -f "$meta" ] || continue
    n="${meta%/project.json}"; n="${n##*/}"
    [ "$n" = "felix" ] && continue
    printf '%s\n' "$n"
  done
}
