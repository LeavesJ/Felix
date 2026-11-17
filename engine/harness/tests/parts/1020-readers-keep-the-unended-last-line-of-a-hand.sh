printf '\nreaders keep the unended last line of a hand-edited table, and open no pipe\n'
# Written blind on 2026-10-01 from a contract, before the fix was read.
#
# Every governed project keeps tables a person edits by hand, and two ordinary
# accidents reach every reader of them:
#   A  The last row has no final newline. `while read ... done < table` reads
#      it, returns 1, and the body never runs for it, so the row is dropped.
#      Each reader the contract names is asked the same question of the same
#      table twice, once ended and once not, and must answer the same; the
#      ended run is also checked against the answer written out here, so a
#      reader that answers nothing for both cannot pass. A comment or a
#      tabs-only last line with no newline is still not a row.
#   B  Something at a table's path that is not a regular file: a FIFO with no
#      writer, a symlink to one, a symlink to /dev/zero. A reader that opens it
#      never returns. Every call here is bounded at 8 s and killed (only the
#      processes it started) if it does not return; a timeout fails the
#      assertion as blocked. A reader that returns must answer exactly what it
#      answers when nothing is at the path.
#   C  Nothing else moves: the policy-version and topology hashes of a project
#      whose tables are regular files are the values the base engine printed
#      for the same bytes, and a regular file reached through a symlink is
#      still read.
#
# The projects this block invents live under projects/rkl-*, their memory
# under $FELIX_MEMORY/rkl-*, and both are removed at the end, with the FIFOs,
# the stub CLI and any state the hooks wrote for the block's own sessions.
# PATH is changed only inside the calls that need the stub. No widget file is
# touched. No background job outlives the block.
_rkl="$TMP/rkl"
rm -rf "$_rkl"
mkdir -p "$_rkl/bin" "$_rkl/out" "$_rkl/tmp" "$_rkl/fifos" "$_rkl/emptyroot" "$_rkl/tpl/commission" \
         "$_rkl/home/.claude/skills/rkl-skill-a" "$_rkl/home/.claude/skills/rkl-skill-b"
_rkl_H="$FROOT/harness"
_rkl_PR="$FROOT/projects"
_rkl_path_was="$PATH"
_rkl_jobs_was=" $(jobs -p | tr '\n' ' ') "
_rkl_state_was="$(cd "$FROOT" && find state -name '*rkl*' 2>/dev/null | LC_ALL=C sort)"

# Every lib a reader below may need, in the CLI's own order where it matters.
_rkl_libs() {
  local _rkl_l
  for _rkl_l in resolve detect stack admit verify route toolbox ledger deny monitor ready discover \
            maintenance recommend autonomy commission commission-provider; do
    . "$_rkl_H/lib/$_rkl_l.sh"
  done
}
# A function call in a subshell with every lib loaded; stdout only.
_rkl_call() { ( cd "$_rkl" && _rkl_libs && "$@" ) 2>/dev/null; }
# A table written whole: `nl` as given (ending in a newline), `none` with that
# final newline taken off.
_rkl_put() {   # path, nl|none, content ending in a newline
  rm -f "$1"
  case "$2" in
    nl)   printf '%s' "$3" > "$1" ;;
    none) printf '%s' "${3%$'\n'}" > "$1" ;;
  esac
}
_rkl_proj() {   # name -> a project under projects/, with a gate that cannot fail
  mkdir -p "$_rkl_PR/$1"
  printf '{\n  "name": "%s",\n  "remote_match": "example.invalid/%s",\n  "gate": "true"\n}\n' "$1" "$1" \
    > "$_rkl_PR/$1/project.json"
  printf '# %s\n' "$1" > "$_rkl_PR/$1/CLAUDE.md"
}
_rkl_checkout() {   # dir, project name for its .felix marker (or - for none)
  mkdir -p "$1"
  ( _fx_cd "$1" && git init -q -b main >/dev/null 2>&1 \
      && printf 'rkl checkout\n' > README.rkl && git add README.rkl \
      && git -c user.name=rkl -c user.email=rkl@example.invalid commit -qm rkl >/dev/null 2>&1 )
  [ "$2" = - ] || printf '%s\n' "$2" > "$1/.felix"
}
_rkl_seg() {   # json, key -> the inside of "key":[ ... ], or MISSING
  local s
  case "$1" in *"\"$2\":["*) ;; *) printf 'MISSING'; return 0 ;; esac
  s="${1#*\"$2\":[}"
  printf '%s' "${s%%]*}"
}

# A stand-in for the claude CLI: the two listings the readers ask for, and a
# refusal for anything else, logged so nothing it was asked to do is hidden.
cat > "$_rkl/bin/claude" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$_rkl/claude.log"
case "\$*" in
  "plugin list --json --available")
    printf '[\n  {\n    "name": "rkl-observability-kit",\n    "description": "observability tracing telemetry"\n  }\n]\n' ;;
  "plugin list --json")
    printf '[\n  {\n    "id": "rkl-plug@rkl-mkt",\n    "enabled": true\n  }\n]\n' ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$_rkl/bin/claude"

# ------------------------------------------------------------- the tables ----
_rkl_RT=$'# name\tkeywords\tprofile\tplay\nfirst\talpha beta\tcore\tsome-tool\nlastone\tzebra quokka\trklprof\trkl-last-tool rkl-own:skill\n'
_rkl_PF=$'# profile\tcapabilities\ncore\tapi\nrklprof\trklcap,obs\n'
_rkl_ST=$'# kind\tname\tsource\trisk\tcapability\tgrounding\nplugin\tfirstone\t-\tlow\tapi\tDECLARED\nplugin\tlastone\t-\tlow\tobs\tDECLARED\n'
_rkl_MT=$'# name\tcadence\tcapability\tdescription\nm-first\t7\talways\tfine\nm-last\t7\trkl-not-a-cap\tunreachable row\n'
_rkl_D1=$'# tool\tpattern\treason\tscope\nEdit\trkl-never-a-path\tno edits there\nBash\trkl-forbidden\trkl refuses this\n'
_rkl_D2=$'# tool\tpattern\treason\tscope\nBash\trkl-other-word\trkl refuses the other\nBash\trkl-forbidden\trkl refuses this\n'
_rkl_DR=$'# tool\tpattern\treason\tscope\nBash\trkl-first\tfirst reason\nBash\trkl-forbidden\trkl refuses this\tcheckout\n'
_rkl_SR=$'# kind\tname\tsource\trisk\tcapability\tgrounding\nplugin\tfirstone\t-\tlow\tapi\tDECLARED\nplugin\trkl-last-tool\t-\tlow\tobs\tDECLARED\n'
_rkl_CM=$'rkl-need\t-\t-\t-\t-\ttrue\t9\n'

# ======================================================= A: unended lines ====
# ------------------------------------------------ deny.tsv, through the hook --
_rkl_proj rkl-deny
_rkl_checkout "$_rkl/co-deny" rkl-deny
_rkl_pay='{"session_id":"rkl-deny-s","tool_name":"Bash","tool_input":{"command":"rkl-forbidden now"}}'
_rkl_pre() {   # deny table, nl|none -> "status|stdout|stderr" of the real hook
  local rc
  _rkl_put "$_rkl_PR/rkl-deny/deny.tsv" "$2" "$1"
  ( cd "$_rkl/co-deny" && printf '%s' "$_rkl_pay" | "$_rkl_H/hooks/pre-tool" > "$_rkl/out/pre.out" 2> "$_rkl/out/pre.err" )
  rc=$?
  printf '%s|%s|%s' "$rc" "$(cat "$_rkl/out/pre.out")" "$(cat "$_rkl/out/pre.err")"
}
_rkl_a="$(_rkl_pre "$_rkl_D1" nl)"; _rkl_b="$(_rkl_pre "$_rkl_D1" none)"
is "rkl: pre-tool refuses a Bash command its only Bash row matches, newline-ended (control)" "${_rkl_a%%|*}" "2"
is "rkl: pre-tool refuses a Bash command when that only Bash row is the unended last line" "$_rkl_b" "$_rkl_a"
_rkl_a="$(_rkl_pre "$_rkl_D2" nl)"; _rkl_b="$(_rkl_pre "$_rkl_D2" none)"
is "rkl: pre-tool refuses when an earlier Bash row misses and the last matches, newline-ended (control)" "${_rkl_a%%|*}" "2"
is "rkl: pre-tool refuses when an earlier Bash row misses and the unended last row matches" "$_rkl_b" "$_rkl_a"
rm -f "$_rkl_PR/rkl-deny/deny.tsv"

mkdir -p "$_rkl/rkl-drows"
_rkl_put "$_rkl/rkl-drows/deny.tsv" nl "$_rkl_DR"; _rkl_a="$(_rkl_call _felix_deny_rows "$_rkl/rkl-drows")"
_rkl_put "$_rkl/rkl-drows/deny.tsv" none "$_rkl_DR"; _rkl_b="$(_rkl_call _felix_deny_rows "$_rkl/rkl-drows")"
is "rkl: _felix_deny_rows lists a newline-ended table with reasons and scope (control)" "$_rkl_a" \
   $'Bash\trkl-first\tfirst reason\t\nBash\trkl-forbidden\trkl refuses this\tcheckout'
is "rkl: _felix_deny_rows lists the unended last row with its reason and scope" "$_rkl_b" "$_rkl_a"
_rkl_put "$_rkl/rkl-drows/deny.tsv" none "$_rkl_DR"$'\t\t\n'; _rkl_b="$(_rkl_call _felix_deny_rows "$_rkl/rkl-drows")"
is "rkl: _felix_deny_rows reads an unended tabs-only last line as no row (every engine)" "$_rkl_b" "$_rkl_a"

# --------------------------------------------------------------- routes.tsv --
_rkl_rdir() {   # how routes.tsv ends, how profiles.tsv ends -> a fresh dir in _rkl_d
  _rkl_d="$_rkl/rkl-routes-$1-$2"; rm -rf "$_rkl_d"; mkdir -p "$_rkl_d"
  printf '{\n  "name": "rkl-routes",\n  "gate": "true"\n}\n' > "$_rkl_d/project.json"
  _rkl_put "$_rkl_d/routes.tsv" "$1" "$_rkl_RT"
  _rkl_put "$_rkl_d/profiles.tsv" "$2" "$_rkl_PF"
}
_rkl_rdir nl nl;   _rkl_rn="$_rkl_d"
_rkl_rdir none nl; _rkl_ru="$_rkl_d"
_rkl_rdir nl none; _rkl_pu="$_rkl_d"

_rkl_a="$(_rkl_call _felix_route_rows "$_rkl_rn")"; _rkl_b="$(_rkl_call _felix_route_rows "$_rkl_ru")"
is "rkl: _felix_route_rows prints both routes of a newline-ended table (control)" "$_rkl_a" \
   $'first\talpha beta\tcore\tsome-tool\nlastone\tzebra quokka\trklprof\trkl-last-tool rkl-own:skill'
is "rkl: _felix_route_rows prints the unended last route" "$_rkl_b" "$_rkl_a"
_rkl_put "$_rkl/rkl-routes-nl-nl/routes.tsv" none "$_rkl_RT"$'# a trailing remark\n'
_rkl_b="$(_rkl_call _felix_route_rows "$_rkl_rn")"
is "rkl: _felix_route_rows reads an unended comment last line as no row (every engine)" "$_rkl_b" "$_rkl_a"
_rkl_put "$_rkl/rkl-routes-nl-nl/routes.tsv" nl "$_rkl_RT"

_rkl_call felix_route_names_capability "$_rkl_rn" rkl-last-tool; _rkl_a=$?
_rkl_call felix_route_names_capability "$_rkl_ru" rkl-last-tool; _rkl_b=$?
is "rkl: felix_route_names_capability finds a tool named in the newline-ended last route (control)" "$_rkl_a" "0"
is "rkl: felix_route_names_capability finds a tool named only in the unended last route" "$_rkl_b" "0"

_rkl_a="$(_rkl_call felix_ready_wanted "$_rkl_rn")"; _rkl_b="$(_rkl_call felix_ready_wanted "$_rkl_ru")"
is "rkl: felix_ready_wanted lists every play entry of a newline-ended table (control)" "$_rkl_a" \
   $'rkl-last-tool\nrkl-own:skill\nsome-tool'
is "rkl: felix_ready_wanted lists the play entries of the unended last route" "$_rkl_b" "$_rkl_a"

_rkl_a="$(_rkl_call felix_toolbox_route_for "$_rkl_rn" rklcap)"
_rkl_b="$(_rkl_call felix_toolbox_route_for "$_rkl_ru" rklcap)"
_rkl_c="$(_rkl_call felix_toolbox_route_for "$_rkl_pu" rklcap)"
is "rkl: felix_toolbox_route_for finds the route for a capability, both tables ended (control)" "$_rkl_a" "lastone"
is "rkl: felix_toolbox_route_for finds the unended last route of routes.tsv" "$_rkl_b" "$_rkl_a"
is "rkl: felix_toolbox_route_for finds a route whose profile is the unended last profiles row" "$_rkl_c" "$_rkl_a"

_rkl_mon() { _rkl_call _felix_mon_project "$1" "$FROOT"; }
_rkl_a="$(_rkl_seg "$(_rkl_mon "$_rkl_rn")" routes)"; _rkl_b="$(_rkl_seg "$(_rkl_mon "$_rkl_ru")" routes)"
is "rkl: the monitor JSON lists both routes of a newline-ended table (control)" "$_rkl_a" \
   '{"name":"first","keywords":"alpha beta","profile":"core","play":"some-tool"},{"name":"lastone","keywords":"zebra quokka","profile":"rklprof","play":"rkl-last-tool rkl-own:skill"}'
is "rkl: the monitor JSON lists the unended last route" "$_rkl_b" "$_rkl_a"

# Routing a prompt, through the CLI, in a checkout bound to a project of its
# own. The play's first step is declared on stack.tsv's last row, so the same
# run also asks the stack reader the render uses (_felix_route_kind).
_rkl_proj rkl-route
_rkl_checkout "$_rkl/co-route" rkl-route
_rkl_route() {   # how routes.tsv ends, how stack.tsv ends -> what felix route --for prints
  _rkl_put "$_rkl_PR/rkl-route/routes.tsv" "$1" "$_rkl_RT"
  _rkl_put "$_rkl_PR/rkl-route/stack.tsv" "$2" "$_rkl_SR"
  ( cd "$_rkl/co-route" && "$FELIX" route --for "zebra quokka now" 2>&1 )
}
_rkl_a="$(_rkl_route nl nl)"
_rkl_b="$(_rkl_route none nl)"
_rkl_c="$(_rkl_route nl none)"
is "rkl: felix route picks the keyword-matching last route of a newline-ended table (control)" \
   "$(printf '%s\n' "$_rkl_a" | head -1)" "Felix routed this to: lastone"
has "rkl: and names its first step as the plugin stack.tsv declares (control)" "$_rkl_a" "rkl-last-tool (plugin)"
is "rkl: felix route picks the keyword-matching route when it is the unended last row" "$_rkl_b" "$_rkl_a"
is "rkl: felix route finds the step's kind when its stack row is the unended last line" "$_rkl_c" "$_rkl_a"

# ---------------------------------------------------------------- stack.tsv --
mkdir -p "$_rkl/rkl-stack-nl" "$_rkl/rkl-stack-none"
printf '{\n  "name": "rkl-stack",\n  "gate": "true"\n}\n' > "$_rkl/rkl-stack-nl/project.json"
cp "$_rkl/rkl-stack-nl/project.json" "$_rkl/rkl-stack-none/project.json"
_rkl_put "$_rkl/rkl-stack-nl/stack.tsv" nl "$_rkl_ST"
_rkl_put "$_rkl/rkl-stack-none/stack.tsv" none "$_rkl_ST"
_rkl_a="$(_rkl_call _felix_route_kind "$_rkl/rkl-stack-nl" lastone)"
_rkl_b="$(_rkl_call _felix_route_kind "$_rkl/rkl-stack-none" lastone)"
is "rkl: _felix_route_kind reads the kind of a newline-ended last row (control)" "$_rkl_a" "plugin"
is "rkl: _felix_route_kind reads the kind of the unended last row, not 'not declared'" "$_rkl_b" "plugin"

_rkl_a="$(_rkl_seg "$(_rkl_mon "$_rkl/rkl-stack-nl")" stack)"
_rkl_b="$(_rkl_seg "$(_rkl_mon "$_rkl/rkl-stack-none")" stack)"
is "rkl: the monitor JSON lists both rows of a newline-ended stack.tsv (control)" "$_rkl_a" \
   '{"kind":"plugin","name":"firstone","risk":"low","capability":"api"},{"kind":"plugin","name":"lastone","risk":"low","capability":"obs"}'
is "rkl: the monitor JSON lists the unended last stack row" "$_rkl_b" "$_rkl_a"
_rkl_put "$_rkl/rkl-stack-none/stack.tsv" none "$_rkl_ST"$'# a trailing remark\n'
_rkl_b="$(_rkl_seg "$(_rkl_mon "$_rkl/rkl-stack-none")" stack)"
is "rkl: the monitor JSON reads an unended comment last line of stack.tsv as no row (every engine)" "$_rkl_b" "$_rkl_a"
_rkl_put "$_rkl/rkl-stack-none/stack.tsv" none "$_rkl_ST"

_rkl_ledger() {   # proj dir -> kind, name, count, named of every row the fold wrote
  local h="$1.home"
  rm -rf "$h" "$MEM/$(basename "$1")"; mkdir -p "$h/state/ledger"
  printf 'mcp\trkl-other\n' > "$h/state/ledger/rkl-sess.tsv"
  ( cd "$_rkl" && _rkl_libs && felix_ledger_rollup "$1" "$h" rkl-sess 2026-10-01 ) >/dev/null 2>&1
  cut -f3-6 "$MEM/$(basename "$1")/ledger.d/rkl-sess.tsv" 2>/dev/null
}
_rkl_a="$(_rkl_ledger "$_rkl/rkl-stack-nl")"; _rkl_b="$(_rkl_ledger "$_rkl/rkl-stack-none")"
is "rkl: the ledger fold writes a zero row for every declared row of a newline-ended stack.tsv (control)" "$_rkl_a" \
   $'mcp\trkl-other\t1\t0\nplugin\tfirstone\t0\t0\nplugin\tlastone\t0\t0'
is "rkl: the ledger fold writes a zero row for the unended last stack row" "$_rkl_b" "$_rkl_a"

# ---------------------------------------------------------- maintenance.tsv --
mkdir -p "$_rkl/rkl-maint-nl" "$_rkl/rkl-maint-none"
_rkl_put "$_rkl/rkl-maint-nl/maintenance.tsv" nl "$_rkl_MT"
_rkl_put "$_rkl/rkl-maint-none/maintenance.tsv" none "$_rkl_MT"
_rkl_a="$(_rkl_call felix_maint_unreachable "$_rkl/rkl-maint-nl")"
_rkl_b="$(_rkl_call felix_maint_unreachable "$_rkl/rkl-maint-none")"
is "rkl: felix_maint_unreachable reports a newline-ended last row naming no capability (control)" "$_rkl_a" \
   $'m-last\trkl-not-a-cap'
is "rkl: felix_maint_unreachable reports the unended last row naming no capability" "$_rkl_b" "$_rkl_a"

# ============================================ B: paths that are not files ====
# A call that may never return, bounded. Run in a background subshell, polled
# against a deadline; on timeout the subshell and every process descended from
# it (found by parent pid, never by pattern) are stopped and then killed, and
# the FIFO is opened read-write once so nothing is left blocked on it.
# 124 means the deadline passed.
_rkl_kids() {   # pid -> every descendant pid
  local all frontier="$1" next p out=""
  all="$(ps -A -o pid= -o ppid= 2>/dev/null)"
  while [ -n "$frontier" ]; do
    next=""
    for p in $frontier; do
      next="$next $(printf '%s\n' "$all" | awk -v p="$p" '$2 == p { print $1 }' | tr '\n' ' ')"
    done
    next="$(printf '%s' "$next" | tr -s ' ')"; next="${next# }"; next="${next% }"
    out="$out $next"; frontier="$next"
  done
  printf '%s' "$out"
}
_rkl_bounded() {   # seconds, fifo or -, code -> its status, or 124; output in out/b.out
  local secs="$1" fifo="$2" pid n=0 k ks
  ( eval "$3" ) > "$_rkl/out/b.out" 2> "$_rkl/out/b.err" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$n" -lt $((secs * 10)) ]; do sleep 0.1; n=$((n + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    ks="$(_rkl_kids "$pid")"
    kill -STOP "$pid" 2>/dev/null
    for k in $ks; do kill -STOP "$k" 2>/dev/null; done
    ks="$ks $(_rkl_kids "$pid")"
    for k in $ks; do kill -9 "$k" 2>/dev/null; done
    kill -9 "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
    [ "$fifo" != - ] && [ -p "$fifo" ] && ( exec 9<>"$fifo" ) 2>/dev/null
    return 124
  fi
  wait "$pid"
}
# One case: the code run with nothing at the path, then with the path made
# `fifo` (a FIFO there), `link` (a symlink to a FIFO elsewhere) or `zero` (a
# symlink to /dev/zero). The answer is "stdout|status" and must be the same;
# stderr is not compared, so a reader may say what it skipped. /dev/zero is
# used only where the old reader is a bash `read` loop, which drops NULs and
# spins in place: cat, grep, head and git hash-object on it grow without bound
# for the 8 s the deadline allows.
# The absent answer is left in _rkl_abs for a control.
_rkl_np() {   # name, path, fifo|link|zero, code
  local rc rel="-"
  rm -f "$2"
  _rkl_bounded 8 - "$4"; rc=$?
  _rkl_abs="$(cat "$_rkl/out/b.out")|$rc"
  case "$3" in
    fifo) mkfifo "$2"; rel="$2" ;;
    link) rm -f "$_rkl/fifos/f"; mkfifo "$_rkl/fifos/f"; ln -s "$_rkl/fifos/f" "$2"; rel="$_rkl/fifos/f" ;;
    zero) ln -s /dev/zero "$2" ;;
  esac
  _rkl_bounded 8 "$rel" "$4"; rc=$?
  if [ "$rc" = 124 ]; then
    bad "$1" "blocked: still running after 8 s with a $3 at $2"
  else
    is "$1" "$(cat "$_rkl/out/b.out")|$rc" "$_rkl_abs"
  fi
  rm -f "$2" "$_rkl/fifos/f"
}
# Added 2026-10-16, when claude/declared-unread-readers landed over this block:
# felix_commission_policy_version hashes anything at a table's path that is not
# a regular file as the line `<not a regular file>`, so a dangling link does not
# hash like no file (that branch's note, agreed with this block's carrier on
# 2026-10-08). Where a reader's answer rests on that hash, the answer with a
# pipe there must be a dangling link's, which is not the absent one's, still
# inside the 8 s and with the pipe never opened.
_rkl_npm() {   # name, path, fifo|link, code
  local rc rel="-" mark
  rm -f "$2"
  _rkl_bounded 8 - "$4"; rc=$?
  _rkl_abs="$(cat "$_rkl/out/b.out")|$rc"
  ln -s "$_rkl/fifos/rkl-gone" "$2"
  _rkl_bounded 8 - "$4"; rc=$?
  mark="$(cat "$_rkl/out/b.out")|$rc"
  rm -f "$2"
  case "$3" in
    fifo) mkfifo "$2"; rel="$2" ;;
    link) rm -f "$_rkl/fifos/f"; mkfifo "$_rkl/fifos/f"; ln -s "$_rkl/fifos/f" "$2"; rel="$_rkl/fifos/f" ;;
  esac
  _rkl_bounded 8 "$rel" "$4"; rc=$?
  if [ "$rc" = 124 ]; then
    bad "$1" "blocked: still running after 8 s with a $3 at $2"
  else
    is "$1" "$(cat "$_rkl/out/b.out")|$rc $([ "$mark" = "$_rkl_abs" ] && echo as-absent || echo not-as-absent)" \
      "$mark not-as-absent"
  fi
  rm -f "$2" "$_rkl/fifos/f"
}

# -------------------------------------------------------- stack.tsv, libs ----
_rkl_F="$_rkl/rkl-fifo"; mkdir -p "$_rkl_F"
printf '{\n  "name": "rkl-fifo",\n  "gate": "true"\n}\n' > "$_rkl_F/project.json"
printf 'observability\n' > "$_rkl_F/capabilities"
printf '# kind\tname\tsource\trisk\tcapability\tkeywords\nplugin\trkl-cat-a\t-\tlow\talways\trkl\nplugin\trkl-cat-b\t-\tmedium\tobs\trkl\n' \
  > "$_rkl/tpl/catalog.tsv"
printf 'declared: {{DECLARED}}\n' > "$_rkl/tpl/commission/rkl_need.md"
_rkl_lib='cd "$_rkl" && _rkl_libs && '
_rkl_stub='PATH="$_rkl/bin:$PATH"; HOME="$_rkl/home"; TMPDIR="$_rkl/tmp"; export PATH HOME TMPDIR; '

_rkl_np "rkl: felix_recommend_missing with a FIFO stack.tsv returns, every catalogue row not declared" \
  "$_rkl_F/stack.tsv" fifo "$_rkl_lib"'felix_recommend_missing "$_rkl_F" "$_rkl/tpl"'
is "rkl: felix_recommend_missing with no stack.tsv lists every catalogue row (control)" "$_rkl_abs" \
   $'plugin\trkl-cat-a\tlow\talways\nplugin\trkl-cat-b\tmedium\tobs|0'

_rkl_put "$_rkl_F/routes.tsv" nl $'# name\tkeywords\tprofile\tplay\nwork\trkl words\tcore\trkl-plug rkl-skill-a rkl-missing\n'
_rkl_np "rkl: felix_ready_unused with a FIFO stack.tsv returns what it returns with none" \
  "$_rkl_F/stack.tsv" fifo "$_rkl_stub$_rkl_lib"'felix_ready_unused "$_rkl_F"'
is "rkl: felix_ready_unused with no stack.tsv lists the one tool no route names (control)" "$_rkl_abs" \
   $'skill\trkl-skill-b|0'
_rkl_np "rkl: felix_ready_report with a FIFO stack.tsv returns, every play entry undeclared" \
  "$_rkl_F/stack.tsv" fifo "$_rkl_stub$_rkl_lib"'felix_ready_report "$_rkl_F"'
has "rkl: felix_ready_report with no stack.tsv calls a play entry undeclared (control)" "$_rkl_abs" \
   $'undeclared\trkl-plug\t'

_rkl_np "rkl: felix_commission_request with a FIFO stack.tsv returns and renders nothing declared" \
  "$_rkl_F/stack.tsv" fifo "$_rkl_stub$_rkl_lib"'rm -rf "$MEM/rkl-fifo/commission"
    _rkl_o="$(felix_commission_request "$_rkl_F" "$_rkl/emptyroot" rkl_need "$_rkl/tpl")"; _rkl_r=$?
    printf "%s|%s|" "${_rkl_o##*/}" "$_rkl_r"; cat "$_rkl_o" 2>/dev/null'
is "rkl: felix_commission_request with no stack.tsv renders nothing declared (control)" "$_rkl_abs" \
   'rkl_need.md|0|declared: nothing|0'
_rkl_np "rkl: felix_commission_admit with a FIFO stack.tsv returns what it returns with none" \
  "$_rkl_F/stack.tsv" fifo "$_rkl_stub$_rkl_lib"'felix_commission_admit "$_rkl_F" "$FROOT" rkl_need "$_rkl/tpl"'
is "rkl: felix_commission_admit with no stack.tsv and no answer prints nothing (control)" "$_rkl_abs" "|0"

_rkl_np "rkl: felix_discover_candidates with a FIFO stack.tsv returns the candidates it finds with none" \
  "$_rkl_F/stack.tsv" fifo "$_rkl_stub$_rkl_lib"'felix_discover_candidates "$_rkl_F" "$_rkl/tpl"'
is "rkl: felix_discover_candidates with no stack.tsv finds the stub's one candidate (control)" "$_rkl_abs" \
   $'3\tobservability\trkl-observability-kit\tobservability tracing telemetry|0'
mkdir -p "$_rkl/dhome/state/discover"
_rkl_dstamp="$( cd "$_rkl" && . "$_rkl_H/lib/resolve.sh" && . "$_rkl_H/lib/discover.sh" && _felix_discover_stamp_line "$_rkl/tpl" )"
printf '%s\nrkl-cand\tllm\tlow\t-\n' "$_rkl_dstamp" > "$_rkl/dhome/state/discover/rkl-fifo.tsv"
_rkl_np "rkl: felix_discover_adopt with a FIFO stack.tsv returns, the cached candidate not declared" \
  "$_rkl_F/stack.tsv" fifo "$_rkl_stub$_rkl_lib"'felix_discover_adopt "$_rkl_F" "$_rkl/dhome" "$_rkl/tpl"'
is "rkl: felix_discover_adopt with no stack.tsv would declare the cached candidate (control)" "$_rkl_abs" \
   $'declare\trkl-cand\tllm\tlow|0'

_rkl_np "rkl: the monitor JSON with a FIFO stack.tsv returns what it returns with none" \
  "$_rkl_F/stack.tsv" fifo "$_rkl_lib"'_felix_mon_project "$_rkl_F" "$FROOT"'
is "rkl: the monitor JSON with no stack.tsv has an empty stack list (control)" \
   "$(_rkl_seg "${_rkl_abs%|*}" stack)|${_rkl_abs##*|}" "|0"
_rkl_np "rkl: the monitor JSON with stack.tsv a symlink to /dev/zero returns what it returns with none" \
  "$_rkl_F/stack.tsv" zero "$_rkl_lib"'_felix_mon_project "$_rkl_F" "$FROOT"'
_rkl_np "rkl: the monitor JSON with a FIFO routes.tsv returns what it returns with none" \
  "$_rkl_F/routes.tsv" fifo "$_rkl_lib"'_felix_mon_project "$_rkl_F" "$FROOT"'
is "rkl: the monitor JSON with no routes.tsv has an empty routes list (control)" \
   "$(_rkl_seg "${_rkl_abs%|*}" routes)|${_rkl_abs##*|}" "|0"
_rkl_np "rkl: the monitor JSON with routes.tsv a symlink to a FIFO returns what it returns with none" \
  "$_rkl_F/routes.tsv" link "$_rkl_lib"'_felix_mon_project "$_rkl_F" "$FROOT"'

# --------------------------------------------------------- stack.tsv, CLI ----
_rkl_proj rkl-stk
_rkl_checkout "$_rkl/co-stk" rkl-stk
printf 'api\n' > "$_rkl_PR/rkl-stk/capabilities"
_rkl_put "$_rkl_PR/rkl-stk/routes.tsv" nl $'# name\tkeywords\tprofile\tplay\nwork\trkl words\tcore\trkl-plug rkl-missing\n'
_rkl_np "rkl: felix recommend --want with a FIFO stack.tsv returns what it prints with none" \
  "$_rkl_PR/rkl-stk/stack.tsv" fifo 'cd "$_rkl/co-stk" && "$FELIX" recommend --want "code review"'
has "rkl: felix recommend --want with no stack.tsv reports a catalogue hit not mounted (control)" "$_rkl_abs" "not mounted"
_rkl_np "rkl: felix recommend with a FIFO stack.tsv returns what it prints with none" \
  "$_rkl_PR/rkl-stk/stack.tsv" fifo 'cd "$_rkl/co-stk" && "$FELIX" recommend'
has "rkl: felix recommend with no stack.tsv closes with nothing already declared (control)" "$_rkl_abs" \
  "Already declared, do not repeat these: "
_rkl_np "rkl: felix ready --fix with a FIFO stack.tsv returns what it prints with none" \
  "$_rkl_PR/rkl-stk/stack.tsv" fifo "$_rkl_stub"'cd "$_rkl/co-stk" && "$FELIX" ready --fix'
has "rkl: felix ready --fix with no stack.tsv reports the play entries undeclared (control)" "$_rkl_abs" "[?] rkl-plug"

# ------------------------------------------------- stack.tsv, the stop hook --
# A green gate on an edited tree, with stack.tsv absent when the gate ran, so
# the stop reaches its superpowers check. The FIFO run must say what the
# absent run said. A session id of its own for each, so neither is the
# second stop of a session.
_rkl_proj rkl-stop
_rkl_checkout "$_rkl/co-stop" rkl-stop
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$_rkl_PR/rkl-stop/probes.tsv"
printf 'edited\n' >> "$_rkl/co-stop/README.rkl"
( cd "$_rkl/co-stop" && "$FELIX" gate ) >/dev/null 2>&1
_rkl_vlog="$MEM/rkl-stop/verification.log"
# Restated 2026-10-16 (see _rkl_npm): the receipt was taken with no stack.tsv,
# so a pipe there moves the table set as a dangling link does, and the hook says
# so; with none it lets the stop through. The link run is a session of its own.
_rkl_npm "rkl: the stop hook with a FIFO stack.tsv returns what it says with a dangling link there" \
  "$_rkl_PR/rkl-stop/stack.tsv" fifo \
  'cd "$_rkl/co-stop" && _rkl_n=$( [ -p "$_rkl_PR/rkl-stop/stack.tsv" ] && echo f || { [ -L "$_rkl_PR/rkl-stop/stack.tsv" ] && echo l || echo a; } )
   printf "{\"hook_event_name\":\"Stop\",\"stop_hook_active\":false,\"session_id\":\"rkl-stop-%s\"}" "$_rkl_n" \
     | "$_rkl_H/hooks/stop"'
_rkl_a="$(grep -c 'green' "$_rkl_vlog" 2>/dev/null)"
is "rkl: the stop hook reached its green branch on this fixture with no stack.tsv (control)" \
   "$( [ "${_rkl_a:-0}" -ge 1 ] && echo yes || echo "no: $(tail -2 "$_rkl_vlog" 2>/dev/null | tr '\n\t' '  ')" )" "yes"

# ------------------------------------------------------------- project.json --
# Resolution by remote walks every project's project.json in name order, so
# the FIFO is put in a project that sorts first.
_rkl_proj rkl-b-remote
mkdir -p "$_rkl_PR/rkl-a-other"
mkdir -p "$_rkl/co-remote"
( _fx_cd "$_rkl/co-remote" && git init -q -b main && git remote add origin https://example.invalid/rkl-b-remote.git ) >/dev/null 2>&1
_rkl_np "rkl: felix which resolves by remote past a FIFO project.json in another project" \
  "$_rkl_PR/rkl-a-other/project.json" fifo 'cd "$_rkl/co-remote" && "$FELIX" which'
is "rkl: felix which resolves this project by its remote (control)" \
   "$(printf '%s\n' "${_rkl_abs%|*}" | head -1)" "project:      rkl-b-remote"
mkdir -p "$_rkl/rkl-pj"
_rkl_np "rkl: felix_json_str on a FIFO project.json returns and prints nothing" \
  "$_rkl/rkl-pj/project.json" fifo "$_rkl_lib"'felix_json_str "$_rkl/rkl-pj/project.json" gate; true'
is "rkl: felix_json_str on an absent project.json prints nothing (control)" "$_rkl_abs" "|0"

# ------------------------------------------------------ autonomy.commission --
mkdir -p "$_rkl/rkl-auto"
printf 'commission\n' > "$_rkl/rkl-auto/autonomy"
_rkl_np "rkl: felix_autonomy_commission_current with a FIFO stamp returns, not current" \
  "$_rkl/rkl-auto/autonomy.commission" fifo "$_rkl_lib"'felix_autonomy_commission_current "$_rkl/rkl-auto"'
is "rkl: felix_autonomy_commission_current with no stamp is not current (control)" "$_rkl_abs" "|1"

# ------------------------------------------------- the commissioning set ----
_rkl_V="$_rkl/rkl-pv"; mkdir -p "$_rkl_V"
printf '{\n  "name": "rkl-pv",\n  "gate": "true"\n}\n' > "$_rkl_V/project.json"
printf 'api\nobservability\n' > "$_rkl_V/capabilities"
_rkl_put "$_rkl_V/commissioning.tsv" nl "$_rkl_CM"
_rkl_put "$_rkl_V/stack.tsv" nl "$_rkl_ST"
_rkl_put "$_rkl_V/profiles.tsv" nl "$_rkl_PF"
_rkl_put "$_rkl_V/routes.tsv" nl "$_rkl_RT"
_rkl_put "$_rkl_V/deny.tsv" nl "$_rkl_D1"
_rkl_npm "rkl: felix_commission_policy_version with a FIFO stack.tsv hashes it as not a regular file" \
  "$_rkl_V/stack.tsv" fifo "$_rkl_lib"'felix_commission_policy_version "$_rkl_V"'
_rkl_npm "rkl: felix_commission_policy_version with stack.tsv a symlink to a FIFO hashes it as not a regular file" \
  "$_rkl_V/stack.tsv" link "$_rkl_lib"'felix_commission_policy_version "$_rkl_V"'
_rkl_put "$_rkl_V/stack.tsv" nl "$_rkl_ST"
_rkl_npm "rkl: felix_commission_policy_version with a FIFO commissioning.tsv hashes it as not a regular file" \
  "$_rkl_V/commissioning.tsv" fifo "$_rkl_lib"'felix_commission_policy_version "$_rkl_V"'
_rkl_np "rkl: felix_commission_topology with a FIFO commissioning.tsv hashes it as absent" \
  "$_rkl_V/commissioning.tsv" fifo "$_rkl_lib"'felix_commission_topology "$_rkl_V" "$_rkl/emptyroot"'
_rkl_put "$_rkl_V/commissioning.tsv" nl "$_rkl_CM"

# ============================================== C: nothing else moves ====
# The two hashes of _rkl_V, every table a regular file, as the base engine
# (claude/adopt-newline-before-append, before this work) printed them on
# 2026-10-01. _felix_hash is `git hash-object --stdin`, a SHA-1 over the bytes
# with a fixed header, so the value is the same on macOS and Linux; the
# fixture's bytes are all written above by printf. Run from a directory that
# is not a repository, so a repository's object format cannot change it.
# Both were also recomputed by hand with printf and git hash-object from the
# bytes above, and agree.
_rkl_PV0='ef79e8f698aaefdaaec221b8655e6cca8b9486d2'
_rkl_TP0='b67ff0cb9602aac85b4e578398abfd8ad43c9d55'
_rkl_a="$(_rkl_call felix_commission_policy_version "$_rkl_V")"
is "rkl: felix_commission_policy_version of a regular table set is the value before this work" "$_rkl_a" "$_rkl_PV0"
_rkl_b="$(_rkl_call felix_commission_topology "$_rkl_V" "$_rkl/emptyroot")"
is "rkl: felix_commission_topology of a regular table set is the value before this work" "$_rkl_b" "$_rkl_TP0"
cp "$_rkl_V/stack.tsv" "$_rkl/stack.copy"; rm -f "$_rkl_V/stack.tsv"; ln -s "$_rkl/stack.copy" "$_rkl_V/stack.tsv"
_rkl_c="$(_rkl_call felix_commission_policy_version "$_rkl_V")"
is "rkl: felix_commission_policy_version reads a stack.tsv symlinked to a regular copy as the file" "$_rkl_c" "$_rkl_a"
_rkl_c="$(_rkl_call _felix_route_kind "$_rkl_V" lastone)"
is "rkl: _felix_route_kind reads a stack.tsv symlinked to a regular copy" "$_rkl_c" "plugin"
rm -f "$_rkl_V/stack.tsv"; _rkl_put "$_rkl_V/stack.tsv" nl "$_rkl_ST"
rm -f "$_rkl_V/commissioning.tsv"
_rkl_put "$_rkl/cm.copy" nl "$_rkl_CM"; ln -s "$_rkl/cm.copy" "$_rkl_V/commissioning.tsv"
_rkl_c="$(_rkl_call felix_commission_topology "$_rkl_V" "$_rkl/emptyroot")"
is "rkl: felix_commission_topology reads a commissioning.tsv symlinked to a regular copy as the file" "$_rkl_c" "$_rkl_b"
rm -f "$_rkl_V/commissioning.tsv"; _rkl_put "$_rkl_V/commissioning.tsv" nl "$_rkl_CM"

# ------------------------------------------------------------- tidy away ----
_rkl_left=""
for _rkl_j in $(jobs -p); do
  case "$_rkl_jobs_was" in *" $_rkl_j "*) ;; *) _rkl_left="$_rkl_left $_rkl_j" ;; esac
done
is "rkl: no background job this block started outlives it" "$_rkl_left" ""
PATH="$_rkl_path_was"
rm -rf "$_rkl_PR"/rkl-* "$MEM"/rkl-*
( cd "$FROOT" && find state -name '*rkl*' 2>/dev/null | LC_ALL=C sort ) > "$_rkl/state.now"
printf '%s\n' "$_rkl_state_was" | grep . > "$_rkl/state.was"
for _rkl_j in $(comm -13 "$_rkl/state.was" "$_rkl/state.now"); do rm -rf "${FROOT:?}/$_rkl_j"; done
find "$_rkl" -type p -exec rm -f {} + 2>/dev/null
rm -rf "$_rkl"
unset -f _rkl_libs _rkl_call _rkl_put _rkl_proj _rkl_checkout _rkl_seg _rkl_pre _rkl_rdir _rkl_mon \
         _rkl_route _rkl_ledger _rkl_kids _rkl_bounded _rkl_np _rkl_npm

