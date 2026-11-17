# tests/lib/deny-hook.sh: the pre-tool hook driven with a payload on stdin.
# Used by 0600 0610 0620. Moved from parts/0600-what-to-do-next.sh line 329
# (verbatim).
# Definitions only. _pre PAYLOAD pipes PAYLOAD to the shipped pre-tool hook and
# leaves its stderr in $FROOT/.deny-err, which the caller reads; it uses FROOT
# at call time.

_pre() { printf '%s' "$1" | "$FROOT/harness/hooks/pre-tool" 2>"$FROOT/.deny-err"; }
