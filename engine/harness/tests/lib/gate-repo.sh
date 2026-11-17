# tests/lib/gate-repo.sh: the widget gate and the repository the completion gate is driven in.
# Used by 0210 (builds it), 0220 (GREPO in the state 0210 leaves it: one commit, a
# clean tree, WIDGET.txt and the widget marker, and the widget gate that tests for
# WIDGET.txt) and 0230 (_gate_catch_build). _gate_repo_build is moved from
# parts/0210-the-completion-gate.sh lines 306-320 of the base tree;
# _gate_catch_build is new.
# Definitions only. _gate_repo_build sets GREPO (the physical path) and does
# nothing more once the repository is there, so in the serial run only 0210's
# call writes the gate and makes the repository.

_gate_repo_build() {
  GREPO="$TMP/gaterepo"
  if [ -d "$GREPO/.git" ]; then GREPO="$(cd "$GREPO" && pwd -P)"; return 0; fi
  cat > "$FROOT/projects/widget/project.json" <<'EOF'
{
  "name": "widget",
  "remote_match": "example.com/widget",
  "gate": "sh -c 'test -f WIDGET.txt && echo widget-gate-ran'"
}
EOF
  GREPO="$TMP/gaterepo"
  mkdir -p "$GREPO"
  ( _fx_cd "$GREPO" && git init -q -b main
    printf 'contents\n' > WIDGET.txt
    printf 'widget\n'   > .felix
    git add -A >/dev/null 2>&1
    git -c user.name=t -c user.email=t@t commit -qm init >/dev/null 2>&1 )
  GREPO="$(cd "$GREPO" && pwd -P)"
}

# _gate_catch_build: the widget's memory holds a catch nobody has written down.
# In the serial run the red gate of the completion-gate section (WIDGET.txt gone,
# then `felix gate`, ending 0210) leaves one exit-1 row in mistakes.log, newer than
# the lessons and the devlog, and 0230's Stop assertions rely on it: "a person's
# session that ends on a green gate is still spoken to" is spoken to with it.
# Run after the lessons are written, so the row is the newer. Does nothing when
# the log already holds a row.
_gate_catch_build() {
  [ -s "$MEM/widget/mistakes.log" ] && return 0
  _gate_repo_build
  ( _fx_cd "$GREPO" && rm -f WIDGET.txt && "$FELIX" gate >/dev/null 2>&1; printf 'contents\n' > WIDGET.txt )
}
