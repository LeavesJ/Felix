# tests/lib/memory-guarded.sh: the project the Stop hook's guard is asked about,
# and the memory directory it reads.
# Used by 0260 (builds it), 0270 and 0280 (GP and $MEM/guarded, for the blind
# restatements of the guard's contract) and 0290 (GP, which it removes at its end).
# Moved from parts/0260-a-failure-nobody-wrote-down.sh line 6 (GP and the two
# mkdir -p, verbatim in the function body below).
# Definitions only. The builder sets GP first; mkdir -p changes nothing once the
# directories are there, so in the serial run a later call leaves everything as
# it found it. The files in $MEM/guarded (mistakes.log, written.log, lessons.md,
# DEVLOG.md) are not made here: each part that reads them writes the ones it
# needs, or resets them first.

_memory_guarded_build() {
  GP="$FROOT/projects/guarded"
  mkdir -p "$GP" "$MEM/guarded"
}
