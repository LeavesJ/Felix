# tests/lib/gate-workflow.sh: the gh stub, the checkout with a GitHub remote, and
# the three helpers that ask repair and automerge about the gate's runs.
# Used by 0130 (builds the stub and the checkout, defines the helpers) and 0140
# (a gate run still waiting for approval, and the green branch run through the
# shipped step), which read WFB, WFR, _wfatt.
# Moved from parts/0130-only-the-gate-workflow-is-evidence.sh: the stub from
# lines 75-118 (WFB, the heredoc, the chmod), _wfhist, _wfatt and _wflatest from
# lines 136-141 and _wfcli from line 254 (verbatim); the checkout from lines
# 246-252 (WFR). The stub's WFSTUB_* variables are the part's: 0130 exports them
# after building the stub, and 0140 passes its own.
# Definitions only. Each builder sets its variable first and does nothing more
# when its fixture is already there, so in the serial run only 0130's calls build.

# _gate_workflow_stub_build: WFB is $TMP/wfgh, the directory holding a gh that
# answers pr list, run list and run view from the files WFSTUB_* name. It needs jq.
_gate_workflow_stub_build() {
  WFB="$TMP/wfgh"
  [ -x "$WFB/gh" ] && return 0
  mkdir -p "$WFB"
cat > "$WFB/gh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$WFSTUB_LOG"
# A call that does not answer, for the case of gh answering once and then not.
if [ -n "${WFSTUB_UNANSWERED:-}" ]; then
  case "$*" in *"$WFSTUB_UNANSWERED"*) printf 'error connecting to api.github.com\n' >&2; exit 1 ;; esac
fi
wf=""; br=""; lim=20; q="."; prev=""
for a in "$@"; do
  case "$prev" in
    --workflow) wf="$a" ;;
    --branch)   br="$a" ;;
    --limit)    lim="$a" ;;
    -q|--jq)    q="$a" ;;
  esac
  prev="$a"
done
case "$1 $2" in
  "pr list") printf '%s\n' "$WFSTUB_PRS" | jq -r "$q" ;;
  "run list")
    if [ -n "$wf" ]; then
      case " $WFSTUB_WORKFLOWS " in
        *" $wf "*) ;;
        *) printf 'HTTP 404: workflow %s not found on the default branch\n' "$wf" >&2; exit 1 ;;
      esac
    fi
    awk -F'\t' -v wf="$wf" -v br="$br" -v lim="$lim" '
      BEGIN { printf "["; n = 0 }
      (wf == "" || $1 == wf) && (br == "" || $3 == br) && n < lim + 0 {
        printf "%s{\"workflowName\":\"%s\",\"headBranch\":\"%s\",\"databaseId\":%s,\"status\":\"%s\",\"conclusion\":\"%s\"}",
               (n ? "," : ""), $2, $3, $4, $5, $6
        n++
      }
      END { print "]" }' "$WFSTUB_RUNS" | jq -r "$q" ;;
  # WFSTUB_NOLOG is a log GitHub no longer holds, or never did: gh answers and
  # there is nothing in it.
  "run view") [ -n "${WFSTUB_NOLOG:-}" ] \
                || printf 'gate\tRun the gate\t2026-09-22T00:00:00.0000000Z Error: %s\n' \
                          "${WFSTUB_LOGTEXT:-the widget test failed}" ;;
esac
exit 0
STUB
  chmod +x "$WFB/gh"
}

# _gate_workflow_repo_build: WFR is $TMP/wfrepo, physical path: a checkout on
# branch fix/y with a GitHub remote, a .felix naming widget and one commit.
# The main fixture is remote-less, and felix repair dies without a remote before any gh.
_gate_workflow_repo_build() {
  WFR="$TMP/wfrepo"
  if [ -d "$WFR/.git" ]; then WFR="$( _fx_cd "$WFR" && pwd -P )"; return 0; fi
  mkdir -p "$WFR"
  ( _fx_cd "$WFR" && git init -q -b fix/y \
    && git remote add origin https://github.com/example/widget.git )
  WFR="$( _fx_cd "$WFR" && pwd -P )"
  printf 'widget\n' > "$WFR/.felix"; printf 'contents\n' > "$WFR/WIDGET.txt"
  ( _fx_cd "$WFR" && git add -A >/dev/null 2>&1 \
    && git -c user.name=t -c user.email=t@t commit -qm base >/dev/null 2>&1 )
}

_wfhist()   { ( PATH="$WFB:$PATH"; . "$FROOT/harness/lib/automerge.sh"
                felix_automerge_history example/widget "$1" ); }
_wfatt()    { ( PATH="$WFB:$PATH"; . "$FROOT/harness/lib/repair.sh"
                felix_repair_attempts "$1" example/widget "$2" ); }
_wflatest() { ( PATH="$WFB:$PATH"; . "$FROOT/harness/lib/repair.sh"
                felix_repair_latest "$1" example/widget "$2" ); }
_wfcli() { ( cd "$WFR" && PATH="$WFB:$PATH" "$FELIX" "$@" 2>&1 ); }
