# tests/lib/recon.sh: the governed fixture the reconciler's CLI is driven against.
# Used by 0380 (builds it) and 0480 (RREPO for felix discover --quiet, MEMREPO for
# the handoff rows; 0480 also needs the committed widget repository, which
# _widget_repo_build in lib/widget-repo.sh gives). Moved from
# parts/0380-the-reconciler-reads-the-record-reached-besi.sh lines 133-142.
# Definitions only. _recon_build sets RREPO and MEMREPO first, and does nothing
# more once the fixture's .felix marker is there. Run by 0380 it copies the
# ledger and the stack table that 0380 built a few lines earlier; run by a part
# that did not build them, it leaves those two out and the project is without
# them. MEMREPO is the widget repository, as part 0120 sets it; an existing
# value is kept.

_recon_build() {
  RREPO="$TMP/recon-repo"; MEMREPO="${MEMREPO:-$REPO}"
  [ -f "$RREPO/.felix" ] && return 0
  mkdir -p "$FROOT/projects/reconproj" "$MEM/reconproj"
  cat > "$FROOT/projects/reconproj/project.json" <<'EOF'
{"name": "reconproj", "remote_match": "example.com/reconproj", "gate": "true"}
EOF
  printf '# reconproj\n' > "$FROOT/projects/reconproj/CLAUDE.md"
  [ -f "$MEM/reconlib/ledger.tsv" ] && cp "$MEM/reconlib/ledger.tsv" "$MEM/reconproj/ledger.tsv"
  [ -f "${RCL:-}/stack.tsv" ] && cp "$RCL/stack.tsv" "$FROOT/projects/reconproj/stack.tsv"
  mkdir -p "$RREPO"
  ( _fx_cd "$RREPO" && git init -q -b main )
  printf 'reconproj\n' > "$RREPO/.felix"
}
