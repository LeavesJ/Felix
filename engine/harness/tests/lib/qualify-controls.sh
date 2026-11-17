# tests/lib/qualify-controls.sh: what the qualify parts share from the part that
# arms the gate on a declared control.
# Used by 0500 (builds the git shim), 0510 (_qcheck and _qlw) and 0570
# (_QGSHIM and _qknone). Moved from
# parts/0500-continued.sh: _qcheck from line 9, _qlw from line 54, the git shim
# from lines 405-429 and _qknone from line 436.
# Definitions only. _qualify_gshim_build sets _QGSHIM, _qgit and _qknone first
# and does nothing more once the shim is there, so in the serial run only the
# first call (0500's) writes it.

# The checker every demo row of these parts uses, and the widget project's
# qualification table.
# _qualify_controls_vars: the variables this file's functions read, set when the prelude calls it
# (contract C2: a lib file defines functions and nothing else).
_qualify_controls_vars() {
_qcheck='! grep -rqI FORBIDDEN . 2>/dev/null'
_qlw="$FROOT/projects/widget/qualification.tsv"
}

# _qualify_gshim_build: git is wrapped so that the Kth worktree add kills a
# process of the felix CLI above it and then fails (see 0500 for the use).
_qualify_gshim_build() {
  _QGSHIM="$TMP/git-shim"; _qgit="$(command -v git)"
  _qknone="the wrapped git killed nothing, so no run was cut short"
  [ -x "$_QGSHIM/git" ] && return 0
  mkdir -p "$_QGSHIM"
cat > "$_QGSHIM/git" <<EOF
#!/bin/sh
case " \$* " in
  *" worktree add "*)
    printf x >> "\$QKILL_COUNT"
    if [ "\$((\$(wc -c < "\$QKILL_COUNT")))" -eq "\${QKILL_AT:-0}" ]; then
      chain=""; p="\$PPID"
      while [ -n "\$p" ] && [ "\$p" -gt 1 ]; do
        case "\$(ps -ww -o command= -p "\$p")" in
          *"\$QKILL_FELIX "*) chain="\$p \$chain" ;;
          *) break ;;
        esac
        p="\$(ps -o ppid= -p "\$p" | tr -d ' ')"
      done
      set -- \$chain
      [ "\$#" -gt "\${QKILL_BELOW:-1}" ] || exit 1
      shift "\${QKILL_BELOW:-1}"
      [ "\$1" != "\$QKILL_SPARE" ] && kill -KILL "\$1" && printf '%s\n' "\$1" > "\$QKILL_COUNT.killed"
      exit 1
    fi ;;
esac
exec "$_qgit" "\$@"
EOF
chmod +x "$_QGSHIM/git"
}
