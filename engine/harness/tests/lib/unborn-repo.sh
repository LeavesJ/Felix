# tests/lib/unborn-repo.sh: the unborn repository the gate is driven against, and
# the widget's mistakes log.
# Used by 0170 (builds the repository: NOHEAD, NOHEADP, NOHEADLOG) and 0370 (reads
# NOHEAD, to run felix receipt on a checkout with no commit). _mislog_vars serves
# 0170 (assigns MISLOG) and 0400 (clears it before a probes gate run).
# Moved from parts/0170-mistakes-record-themselves.sh: the fixture from lines
# 196-207 (verbatim, in the function body below) and NOHEADLOG from line 208;
# MISLOG from line 4.
# Definitions only. A builder sets its variables first and does nothing more once
# its fixture is there, so in the serial run only 0170's call builds.

# _mislog_vars: MISLOG is the widget project's mistakes.log (a path, nothing made).
_mislog_vars() {
  MISLOG="$MEM/widget/mistakes.log"
}

# _unborn_repo_build: a repository that has been `git init`ed and not committed to,
# bound by a .felix marker to a project whose gate fails naming one check.
_unborn_repo_build() {
  NOHEAD="$TMP/unborn-repo"; NOHEADP="$FROOT/projects/unbornproj"
  NOHEADLOG="$MEM/unbornproj/mistakes.log"
  [ -f "$NOHEADP/gate.sh" ] && return 0
  mkdir -p "$NOHEAD" "$NOHEADP" "$MEM/unbornproj"
  ( _fx_cd "$NOHEAD" && git init -q -b main )
  printf 'unbornproj\n' > "$NOHEAD/.felix"
  printf 'untracked\n'  > "$NOHEAD/file.txt"
  printf '{"name":"unbornproj","gate":"gate.sh"}\n' > "$NOHEADP/project.json"
  cat > "$NOHEADP/gate.sh" <<'GS'
#!/usr/bin/env bash
echo "  lint               FAIL"
exit 1
GS
  chmod +x "$NOHEADP/gate.sh"
}
