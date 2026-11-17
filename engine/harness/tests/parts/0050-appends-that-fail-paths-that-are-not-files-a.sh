printf '\nappends that fail, paths that are not files, and readers that drop a last line\n'
# Written blind on 2026-10-01, from a third contract, after an adversarial
# review of the fix: an append that fails on an ended table, a path that is
# not a regular file, the log readers, the gate log and mistakes.log. Red
# against origin/main: 47 of 74.
# Three more ways a hand-editable table and its writer disagree.
#   A  The table ends in a newline and is read-only, so the row's own append
#      fails. Nothing may be counted, announced, stamped or installed for it.
#   B  Something at the table's path that is not a regular file: a dangling
#      symlink, whose target must not be created, and a directory. The writer
#      refuses the way it refuses an unwritable table. A FIFO for the two
#      logs, where the danger is not a wrong write but a write that never
#      returns, so each call there is bounded and a hang fails its assertion.
#   C  Readers: a last line with no newline is a line, and `while read` drops
#      it unless told not to.
#   D  The gate's own log: a project gate whose output does not end in a
#      newline must not fuse Felix's checker lines onto its last line, or the
#      failure is recorded as `exit-1` and the roster loses the checker.
#   E  mistakes.log is curated by hand, so its writer gets the part-1 contract.
#
# Root writes through any mode, so A skips under root. B, C, D and E do not
# depend on a mode and run regardless. Every widget file touched is saved with
# its mode and put back; the project D invents, its memory and its receipt are
# removed; no background job outlives the block.
_anl3="$TMP/anl3"; mkdir -p "$_anl3/bin" "$_anl3/tpl/setup" "$_anl3/mem" "$_anl3/targets" "$_anl3/norepo"
_anl3_root=0; [ "$(id -u)" = "0" ] && _anl3_root=1
_anl3_nl='
'
_anl3_od()    { od -An -c | tr '\n' ' ' | tr -s ' '; }
_anl3_bytes() { if [ -e "$1" ]; then _anl3_od < "$1"; else printf 'absent'; fi; }
_anl3_want()  { printf "$@" | _anl3_od; }
_anl3_norm()  {   # file, length of the old bytes -> od, digits after them squeezed to 9
  [ -e "$1" ] || { printf 'absent'; return 0; }
  { [ "$2" -eq 0 ] || head -c "$2" "$1"; tail -c +"$(($2 + 1))" "$1" | tr -s '0-9' '9'; } | _anl3_od
}
_anl3_has()   { case "$1" in *"$2"*) return 0 ;; esac; return 1; }
_anl3_line()  { case "$_anl3_nl$1$_anl3_nl" in *"$_anl3_nl$2$_anl3_nl"*) return 0 ;; esac; return 1; }
_anl3_if()    {   # name, detail, command...: ok when the command succeeds
  local n="$1" d="$2"; shift 2
  if "$@"; then ok "$n"; else bad "$n" "$d"; fi
}
_anl3_ifr()   {   # the same, skipped under root, for the cases built from a mode
  if [ "$_anl3_root" = 1 ]; then skip "$1" "running as root"; else _anl3_if "$@"; fi
}
_anl3_isr()   { if [ "$_anl3_root" = 1 ]; then skip "$1" "running as root"; else is "$@"; fi; }

# A table at a path, made the way a case asks: `open` and `ro` from
# newline-terminated content, `none` and `nul` with that newline replaced,
# `dangling` a symlink to a target that does not exist, `dir` an empty
# directory. _anl3_post judges an odd entry before clearing it, and gives a
# read-only table its mode back.
_anl3_clear() { if [ -d "$1" ] && [ ! -L "$1" ]; then rm -rf "$1"; else rm -f "$1"; fi; }
_anl3_prep()  {   # path, how, newline-terminated content, case id
  _anl3_clear "$1"
  case "$2" in
    open)     printf '%s' "$3" > "$1" ;;
    ro)       printf '%s' "$3" > "$1"; chmod 444 "$1" ;;
    none)     printf '%s' "${3%$'\n'}" > "$1" ;;
    nul)      printf '%s\0' "${3%$'\n'}" > "$1" ;;
    dangling) ln -s "$_anl3/targets/$4" "$1" ;;
    dir)      mkdir "$1" ;;
  esac
}
_anl3_post()  {   # path, how, case id -> _anl3_oddok 0 when an odd entry is as made and nothing was created
  _anl3_oddok=0; _anl3_oddsay=""
  case "$2" in
    ro) chmod 644 "$1" ;;
    dangling)
      if [ -L "$1" ] && [ "$(readlink "$1")" = "$_anl3/targets/$3" ] && [ ! -e "$_anl3/targets/$3" ]; then :
      else _anl3_oddok=1
           _anl3_oddsay="link [$(readlink "$1" 2>&1)], target $( [ -e "$_anl3/targets/$3" ] && printf 'CREATED holding [%s]' "$(head -c 300 "$_anl3/targets/$3" | tr '\n\t' '| ')" || printf 'absent')"
      fi
      _anl3_clear "$1" ;;
    dir)
      if [ -d "$1" ] && [ ! -L "$1" ] && [ -z "$(ls -A "$1" 2>/dev/null)" ]; then :
      else _anl3_oddok=1; _anl3_oddsay="$(ls -ldA "$1" "$1"/* 2>&1 | tr '\n' ' ')"; fi
      _anl3_clear "$1" ;;
  esac
}

# A call that may never return, bounded. Run in a background subshell, polled
# against a deadline, and on timeout the pid this started is killed, then its
# own children by their parent pid, never by pattern. A writer or reader still
# blocked on the FIFO is released by opening it read-write, which on both
# platforms returns at once. 124 means the deadline passed.
_anl3_bounded() {   # seconds, fifo, code -> the code's status, or 124
  local secs="$1" fifo="$2" pid n=0 k
  ( eval "$3" ) & pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$n" -lt $((secs * 10)) ]; do sleep 0.1; n=$((n + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    for k in $(ps -A -o pid= -o ppid= 2>/dev/null | awk -v p="$pid" '$2 == p { print $1 }'); do
      kill -9 "$k" 2>/dev/null
    done
    kill -9 "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
    [ -p "$fifo" ] && ( exec 9<>"$fifo" ) 2>/dev/null
    return 124
  fi
  wait "$pid"
}

printf '# kind\tname\tsource\trisk\tcapability\tkeywords\nplugin\tanl-obs-a\t-\tlow\tobs\tobs tracing\nmcp\tanl-obs-b\thttps://example.invalid/mcp\tmedium\tobs\tobs\n' \
  > "$_anl3/tpl/catalog.tsv"
printf '# id\ttitle\tcapability\tcheck\nanl-step\tWire the obs thing\tobs\tgh api repos/{{REPO}}/hooks\n' \
  > "$_anl3/tpl/setup.tsv"
printf '# Wire the obs thing for {{REPO}}\n' > "$_anl3/tpl/setup/anl-step.md"
_anl3_SH=$'# kind\tname\tsource\trisk\tcapability\tgrounding\n'
_anl3_UH=$'# id\ttitle\tcapability\tcheck\n'
_anl3_SO=$'plugin\tanl-kept\t-\tlow\tapi\tDECLARED\n'
_anl3_UO=$'anl-kept-step\tKept by hand\tapi\ttrue\n'
_anl3_SR=$'plugin\tanl-obs-a\t-\tlow\tobs\tDECLARED\nmcp\tanl-obs-b\thttps://example.invalid/mcp\tmedium\tobs\tDECLARED\n'
_anl3_UR=$'anl-step\tWire the obs thing\tobs\tgh api repos/{{REPO}}/hooks\n'
_anl3_DO=$'plugin\tanl-hand-kept\t-\tlow\tllm\tDECLARED\n'
_anl3_MO=$'anl-sweep\t1700000000\t2023-11-14\n'
_anl3_BO=$'1700000000\t2023-11-14T22:13\tby hand\n'
_anl3_EO=$'2026-01-01\tmain\tabc123\tlint\n'

# The widget files the CLI writers touch, saved with their modes, absent
# included. autonomy.tidy is where a tidy grant's stamp would live
# (felix_autonomy_stamp_path), so it is cleared before the case that asks.
_anl3_W="$FROOT/projects/widget"
_anl3_cache="$FROOT/state/discover/widget.tsv"
_anl3_wfiles="$_anl3_W/autonomy $_anl3_W/autonomy.tidy $_anl3_W/stack.tsv $_anl3_W/maintenance.tsv $_anl3_W/maintenance.log $_anl3_cache"
_anl3_modes() { for _f in $_anl3_wfiles; do if [ -e "$_f" ]; then ls -ld "$_f" | cut -c1-10; else echo absent; fi; done; }
_anl3_modes_was="$(_anl3_modes)"
_anl3_i=0
for _f in $_anl3_wfiles; do
  _anl3_i=$((_anl3_i + 1)); rm -f "$_anl3/keep.$_anl3_i"
  [ -e "$_f" ] && cp -p "$_f" "$_anl3/keep.$_anl3_i"
done
_anl3_had_state=0; [ -d "$FROOT/state" ] && _anl3_had_state=1
_anl3_had_disc=0;  [ -d "$FROOT/state/discover" ] && _anl3_had_disc=1
_anl3_had_gate=0;  [ -d "$FROOT/state/gate" ] && _anl3_had_gate=1
# Background jobs some earlier block may still own; only new ones count below.
_anl3_jobs_was=" $(jobs -p | tr '\n' ' ') "
mkdir -p "$FROOT/state/discover"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/claude.log"\nexit 1\n' "$_anl3" > "$_anl3/bin/claude"
chmod +x "$_anl3/bin/claude"
_anl3_dstamp="$( . "$FROOT/harness/lib/discover.sh"; _felix_discover_stamp_line "$FROOT/harness/templates" )"
printf '# name\tcadence\tcapability\tdescription\nanl-sweep\t7\talways\tsweep the fixture\n' > "$_anl3_W/maintenance.tsv"

# ------------------------------------------------------------ the runners ----
_anl3_adopt() {   # case id, table (stack.tsv | setup.tsv | -), how
  local d="$_anl3/$1"
  mkdir -p "$d"
  printf 'api\n' > "$d/capabilities"
  _anl3_prep "$d/stack.tsv" open "$_anl3_SH$_anl3_SO" "$1"
  _anl3_prep "$d/setup.tsv" open "$_anl3_UH$_anl3_UO" "$1"
  case "$2" in
    stack.tsv) _anl3_prep "$d/stack.tsv" "$3" "$_anl3_SH$_anl3_SO" "$1" ;;
    setup.tsv) _anl3_prep "$d/setup.tsv" "$3" "$_anl3_UH$_anl3_UO" "$1" ;;
  esac
  [ "$2" != - ] && [ -f "$d/$2" ] && cat "$d/$2" > "$d.was"
  ( . "$FROOT/harness/lib/adopt.sh"; felix_adopt_capability "$d" obs "$_anl3/tpl" acme/widget ) > "$d.out" 2> "$d.err"
  _anl3_rc=$?
  [ "$2" != - ] && _anl3_post "$d/$2" "$3" "$1"
}
_anl3_autonomy() {   # case id, how
  local d="$_anl3/$1"
  mkdir -p "$d"; rm -f "$_anl3_W/autonomy.tidy"
  _anl3_prep "$_anl3_W/autonomy" "$2" $'commission\n' "$1"
  [ -f "$_anl3_W/autonomy" ] && cat "$_anl3_W/autonomy" > "$d.was"
  ( cd "$REPO" && "$FELIX" autonomy --allow tidy ) > "$d.out" 2> "$d.err"
  _anl3_rc=$?
  _anl3_stamp=0; [ -e "$_anl3_W/autonomy.tidy" ] && _anl3_stamp=1
  _anl3_post "$_anl3_W/autonomy" "$2" "$1"
  [ -f "$_anl3_W/autonomy" ] && cp "$_anl3_W/autonomy" "$d.now"
  _anl3_clear "$_anl3_W/autonomy"; rm -f "$_anl3_W/autonomy.tidy"
}
_anl3_discover() {   # case id, how
  local d="$_anl3/$1"
  mkdir -p "$d"; rm -f "$_anl3/claude.log"
  _anl3_prep "$_anl3_W/stack.tsv" "$2" "$_anl3_SH$_anl3_DO" "$1"
  [ -f "$_anl3_W/stack.tsv" ] && cat "$_anl3_W/stack.tsv" > "$d.was"
  printf '%s\nanl-adopted\tllm\tlow\t-\n' "$_anl3_dstamp" > "$_anl3_cache"
  ( cd "$REPO" && PATH="$_anl3/bin:$PATH" "$FELIX" discover --adopt ) > "$d.out" 2>&1
  _anl3_rc=$?
  cp "$_anl3/claude.log" "$d.claude" 2>/dev/null || : > "$d.claude"
  _anl3_post "$_anl3_W/stack.tsv" "$2" "$1"
  [ -f "$_anl3_W/stack.tsv" ] && cp "$_anl3_W/stack.tsv" "$d.now"
  _anl3_clear "$_anl3_W/stack.tsv"
}
_anl3_apply() {   # case id, how
  local d="$_anl3/$1"
  mkdir -p "$d"
  _anl3_prep "$d/stack.tsv" "$2" "$_anl3_SH$_anl3_DO" "$1"
  ( FELIX_MEMORY="$_anl3/mem"; export FELIX_MEMORY
    . "$FROOT/harness/lib/commission.sh"; . "$FROOT/harness/lib/commission-provider.sh"
    felix_commission_apply_declares "$d" "$REPO" \
      "$(printf 'declare\tplugin\tanl-declared\tlow\tllm\tdeadbeef\tthe fixture\n')" anl-tree anl-policy anl_need ) \
    > "$d.out" 2> "$d.err"
  _anl3_rc=$?
  _anl3_post "$d/stack.tsv" "$2" "$1"
}
_anl3_maint() {   # case id, how; through the CLI, on the widget's log
  local d="$_anl3/$1"
  mkdir -p "$d"
  _anl3_prep "$_anl3_W/maintenance.log" "$2" "$_anl3_MO" "$1"
  ( cd "$REPO" && "$FELIX" maintenance --ran anl-sweep ) > "$d.out" 2> "$d.err"
  _anl3_rc=$?
  _anl3_post "$_anl3_W/maintenance.log" "$2" "$1"
  [ -f "$_anl3_W/maintenance.log" ] && cp "$_anl3_W/maintenance.log" "$d.now"
  _anl3_clear "$_anl3_W/maintenance.log"
}
_anl3_budget() {   # case id, how
  local d="$_anl3/$1"
  mkdir -p "$d"
  _anl3_prep "$d/budget.log" "$2" "$_anl3_BO" "$1"
  ( . "$FROOT/harness/lib/budget.sh"; felix_budget_record "$d" "anl hand edit" ) > "$d.out" 2> "$d.err"
  _anl3_rc=$?
  _anl3_post "$d/budget.log" "$2" "$1"
}
_anl3_mistake() {   # case id, how; mistakes.log lives under the memory root
  local d="$_anl3/$1" m="$_anl3/mem/$1"
  mkdir -p "$d" "$m"
  _anl3_prep "$m/mistakes.log" "$2" "$_anl3_EO" "$1"
  ( FELIX_MEMORY="$_anl3/mem"; export FELIX_MEMORY
    . "$FROOT/harness/lib/memory.sh"; felix_mem_mistake "$d" "$_anl3/norepo" anl-lint ) > "$d.out" 2> "$d.err"
  _anl3_rc=$?
  _anl3_post "$m/mistakes.log" "$2" "$1"
}

# ------------------------------------------------------------ the control ----
# Every runner, on a table that ends in a newline and can be written, writes
# its row; the two bounded calls return 0 on a regular file. Without this, a
# runner that never reached its writer would pass "counts nothing", "creates
# nothing" and "non-zero" below.
_anl3_ctl=""
_anl3_adopt ctl-adopt - open
[ "$(cat "$_anl3/ctl-adopt.out")" = "2 1" ] || _anl3_ctl="$_anl3_ctl adopt[$(cat "$_anl3/ctl-adopt.out" "$_anl3/ctl-adopt.err" | tr '\n' ' ')]"
_anl3_autonomy ctl-autonomy open
{ _anl3_line "$(cat "$_anl3/ctl-autonomy.out")" "allowed: tidy" \
  && [ "$(_anl3_bytes "$_anl3/ctl-autonomy.now")" = "$(_anl3_want 'commission\ntidy\n')" ]; } \
  || _anl3_ctl="$_anl3_ctl autonomy[$(head -3 "$_anl3/ctl-autonomy.out" "$_anl3/ctl-autonomy.err" | tr '\n' ' ')]"
_anl3_discover ctl-discover open
grep -q '^plugin install anl-adopted' "$_anl3/ctl-discover.claude" \
  || _anl3_ctl="$_anl3_ctl discover[$(head -4 "$_anl3/ctl-discover.out" | tr '\n' ' ')]"
_anl3_apply ctl-apply open
[ "$(cat "$_anl3/ctl-apply.out")" = "1" ] || _anl3_ctl="$_anl3_ctl apply[$(cat "$_anl3/ctl-apply.out" "$_anl3/ctl-apply.err" | tr '\n' ' ')]"
_anl3_maint ctl-maint open
{ _anl3_has "$(cat "$_anl3/ctl-maint.out")" "recorded a run of anl-sweep" \
  && [ "$(wc -l < "$_anl3/ctl-maint.now" | tr -d ' ')" = "2" ]; } \
  || _anl3_ctl="$_anl3_ctl maintenance[$(cat "$_anl3/ctl-maint.out" "$_anl3/ctl-maint.err" | head -3 | tr '\n' ' ')]"
_anl3_budget ctl-budget open
{ [ "$_anl3_rc" = 0 ] && [ "$(wc -l < "$_anl3/ctl-budget/budget.log" | tr -d ' ')" = "2" ]; } || _anl3_ctl="$_anl3_ctl budget[rc $_anl3_rc]"
_anl3_mistake ctl-mistake open
[ "$(wc -l < "$_anl3/mem/ctl-mistake/mistakes.log" | tr -d ' ')" = "2" ] || _anl3_ctl="$_anl3_ctl mistake[$(cat "$_anl3/ctl-mistake.err" | tr '\n' ' ')]"
mkdir -p "$_anl3/ctl-bounded"; printf '%s' "$_anl3_BO" > "$_anl3/ctl-bounded/budget.log"; printf '%s' "$_anl3_MO" > "$_anl3/ctl-bounded/maintenance.log"
_anl3_bounded 8 - '. "$FROOT/harness/lib/budget.sh"; felix_budget_record "$_anl3/ctl-bounded" "anl hand edit" >/dev/null 2>&1' \
  || _anl3_ctl="$_anl3_ctl bounded-budget[rc $?]"
_anl3_bounded 8 - '. "$FROOT/harness/lib/maintenance.sh"; felix_maint_record "$_anl3/ctl-bounded" anl-sweep >/dev/null 2>&1' \
  || _anl3_ctl="$_anl3_ctl bounded-maint[rc $?]"
is "every writer the third block refuses still writes its row where it can (control)" "$_anl3_ctl" ""

# ------------------------------- A: a newline-terminated read-only table ----
_anl3_adopt ro-stack stack.tsv ro
_anl3_d="$_anl3/ro-stack"; _anl3_e="$(cat "$_anl3_d.err")"
_anl3_isr "adopting onto a newline-terminated read-only stack.tsv counts none of the rows it could not write" \
   "$(cat "$_anl3_d.out")" "0 1"
_anl3_ifr "and adopting onto that newline-terminated read-only stack.tsv names it and each row it left out on stderr" \
   "stderr was [$(printf '%s' "$_anl3_e" | tr '\n' ' ')]" \
   eval '_anl3_has "$_anl3_e" stack.tsv && _anl3_has "$_anl3_e" anl-obs-a && _anl3_has "$_anl3_e" anl-obs-b'
_anl3_isr "and adopting onto that newline-terminated read-only stack.tsv leaves it byte for byte" \
   "$(_anl3_bytes "$_anl3_d/stack.tsv")" "$(_anl3_bytes "$_anl3_d.was")"

_anl3_adopt ro-setup setup.tsv ro
_anl3_d="$_anl3/ro-setup"; _anl3_e="$(cat "$_anl3_d.err")"
_anl3_isr "adopting onto a newline-terminated read-only setup.tsv counts none of the steps it could not write" \
   "$(cat "$_anl3_d.out")" "2 0"
_anl3_ifr "and adopting onto that newline-terminated read-only setup.tsv names it and the step it left out on stderr" \
   "stderr was [$(printf '%s' "$_anl3_e" | tr '\n' ' ')]" \
   eval '_anl3_has "$_anl3_e" setup.tsv && _anl3_has "$_anl3_e" anl-step'
_anl3_isr "and adopting onto that newline-terminated read-only setup.tsv leaves it byte for byte" \
   "$(_anl3_bytes "$_anl3_d/setup.tsv")" "$(_anl3_bytes "$_anl3_d.was")"
_anl3_ifr "and adopting onto that newline-terminated read-only setup.tsv writes no instructions file for the step" \
   "$_anl3_d/setup/anl-step.md was written" test ! -e "$_anl3_d/setup/anl-step.md"

_anl3_autonomy ro-autonomy ro
_anl3_d="$_anl3/ro-autonomy"
_anl3_ifr "felix autonomy --allow onto a newline-terminated read-only grant exits non-zero without saying allowed" \
   "exit $_anl3_rc, stdout [$(head -3 "$_anl3_d.out" | tr '\n' ' ')]" \
   eval '[ "$_anl3_rc" != 0 ] && ! _anl3_line "$(cat "$_anl3_d.out")" "allowed: tidy"'
_anl3_isr "and felix autonomy --allow onto that newline-terminated read-only grant leaves the file byte for byte" \
   "$(_anl3_bytes "$_anl3_d.now")" "$(_anl3_bytes "$_anl3_d.was")"
_anl3_isr "and felix autonomy --allow onto that newline-terminated read-only grant writes no stamp for tidy" \
   "$_anl3_stamp" "0"

_anl3_discover ro-discover ro
_anl3_d="$_anl3/ro-discover"; _anl3_o="$(cat "$_anl3_d.out")"
# The plan has to reach the row, or "no install" and "no declared line" are
# what a run that never read the cache would print as well.
_anl3_reached() { _anl3_has "$_anl3_o" "adopting for"; }
_anl3_ifr "felix discover --adopt onto a newline-terminated read-only stack.tsv attempts no install of the row" \
   "plan reached: $(_anl3_reached && echo yes || echo NO, a fixture fault); the stub was asked [$(tr '\n' ' ' < "$_anl3_d.claude")]" \
   eval '_anl3_reached && ! grep -q "^plugin install anl-adopted" "$_anl3_d.claude"'
_anl3_ifr "and felix discover --adopt onto that newline-terminated read-only stack.tsv prints no installed or declared line for the row" \
   "output [$(printf '%s' "$_anl3_o" | tr '\n' ' ')]" \
   eval '_anl3_reached && ! grep -Eq "^ *(installed|declared) +anl-adopted( |\$)" <<<"$_anl3_o"'
_anl3_ifr "and felix discover --adopt onto that newline-terminated read-only stack.tsv names the row unwritten" \
   "output [$(printf '%s' "$_anl3_o" | tr '\n' ' ')]" \
   eval 'awk "/anl-adopted/ && /unwritten/ { f = 1 } END { exit !f }" <<<"$_anl3_o"'
_anl3_ifr "and felix discover --adopt onto that newline-terminated read-only stack.tsv sums up 0 adopted and 1 unwritten" \
   "output [$(printf '%s' "$_anl3_o" | tr '\n' ' ')]" \
   eval 'awk "/^0 adopted/ && /1 unwritten/ { f = 1 } END { exit !f }" <<<"$_anl3_o"'

# ------------------------------------- B: a path that is not a regular file ----
for _anl3_k in dangling dir; do
  case "$_anl3_k" in dangling) _anl3_kw="a dangling symlink" ;; dir) _anl3_kw="a directory" ;; esac

  _anl3_adopt "b-$_anl3_k-stack" stack.tsv "$_anl3_k"
  _anl3_d="$_anl3/b-$_anl3_k-stack"
  is "adopting with $_anl3_kw at stack.tsv counts none of its catalogue rows" "$(cat "$_anl3_d.out")" "0 1"
  _anl3_if "and adopting with $_anl3_kw at stack.tsv creates nothing there" "$_anl3_oddsay" test "$_anl3_oddok" = 0
  is "and adopting with $_anl3_kw at stack.tsv still records the capability and writes its setup step" \
     "$(_anl3_bytes "$_anl3_d/capabilities") | $(_anl3_bytes "$_anl3_d/setup.tsv")" \
     "$(_anl3_want 'api\nobs\n') | $(_anl3_want '%s%s%s' "$_anl3_UH" "$_anl3_UO" "$_anl3_UR")"

  _anl3_adopt "b-$_anl3_k-setup" setup.tsv "$_anl3_k"
  _anl3_d="$_anl3/b-$_anl3_k-setup"
  is "adopting with $_anl3_kw at setup.tsv counts no setup step" "$(cat "$_anl3_d.out")" "2 0"
  _anl3_if "and adopting with $_anl3_kw at setup.tsv creates nothing there" "$_anl3_oddsay" test "$_anl3_oddok" = 0
  _anl3_if "and adopting with $_anl3_kw at setup.tsv writes no instructions file for the step" \
     "$_anl3_d/setup/anl-step.md was written" test ! -e "$_anl3_d/setup/anl-step.md"
  is "and adopting with $_anl3_kw at setup.tsv still records the capability and writes its stack rows" \
     "$(_anl3_bytes "$_anl3_d/capabilities") | $(_anl3_bytes "$_anl3_d/stack.tsv")" \
     "$(_anl3_want 'api\nobs\n') | $(_anl3_want '%s%s%s' "$_anl3_SH" "$_anl3_SO" "$_anl3_SR")"

  _anl3_autonomy "b-$_anl3_k-autonomy" "$_anl3_k"
  _anl3_d="$_anl3/b-$_anl3_k-autonomy"
  _anl3_if "felix autonomy --allow with $_anl3_kw at the autonomy file exits non-zero without saying allowed" \
     "exit $_anl3_rc, stdout [$(head -3 "$_anl3_d.out" | tr '\n' ' ')]" \
     eval '[ "$_anl3_rc" != 0 ] && ! _anl3_line "$(cat "$_anl3_d.out")" "allowed: tidy"'
  _anl3_if "and felix autonomy --allow with $_anl3_kw at the autonomy file creates nothing there" \
     "$_anl3_oddsay" test "$_anl3_oddok" = 0

  _anl3_discover "b-$_anl3_k-discover" "$_anl3_k"
  _anl3_d="$_anl3/b-$_anl3_k-discover"; _anl3_o="$(cat "$_anl3_d.out")"
  _anl3_if "felix discover --adopt with $_anl3_kw at stack.tsv attempts no install of the row" \
     "plan reached: $(_anl3_reached && echo yes || echo NO, a fixture fault); the stub was asked [$(tr '\n' ' ' < "$_anl3_d.claude")]" \
     eval '_anl3_reached && ! grep -q "^plugin install anl-adopted" "$_anl3_d.claude"'
  _anl3_if "and felix discover --adopt with $_anl3_kw at stack.tsv prints no installed or declared line for the row" \
     "output [$(printf '%s' "$_anl3_o" | tr '\n' ' ')]" \
     eval '_anl3_reached && ! grep -Eq "^ *(installed|declared) +anl-adopted( |\$)" <<<"$_anl3_o"'
  _anl3_if "and felix discover --adopt with $_anl3_kw at stack.tsv names the row unwritten and sums up 0 adopted" \
     "output [$(printf '%s' "$_anl3_o" | tr '\n' ' ')]" \
     eval 'awk "/anl-adopted/ && /unwritten/ { u = 1 } /^0 adopted/ { z = 1 } END { exit !(u && z) }" <<<"$_anl3_o"'
  _anl3_if "and felix discover --adopt with $_anl3_kw at stack.tsv creates nothing there" "$_anl3_oddsay" test "$_anl3_oddok" = 0

  _anl3_apply "b-$_anl3_k-apply" "$_anl3_k"
  _anl3_d="$_anl3/b-$_anl3_k-apply"
  is "commissioning's apply with $_anl3_kw at stack.tsv counts no declare" "$(cat "$_anl3_d.out")" "0"
  _anl3_if "and commissioning's apply with $_anl3_kw at stack.tsv creates nothing there" "$_anl3_oddsay" test "$_anl3_oddok" = 0
  is "and commissioning's apply with $_anl3_kw at stack.tsv logs no declare for the row" \
     "$(awk -F'\t' '$5 == "declared" && index($0, "anl-declared") { n++ } END { print n + 0 }' "$_anl3/mem/b-$_anl3_k-apply/commissioning.log" 2>/dev/null || echo 0)" "0"

  _anl3_maint "b-$_anl3_k-maint" "$_anl3_k"
  _anl3_d="$_anl3/b-$_anl3_k-maint"
  _anl3_if "felix maintenance --ran with $_anl3_kw at the log exits non-zero without saying it recorded the run" \
     "exit $_anl3_rc, stdout [$(head -3 "$_anl3_d.out" | tr '\n' ' ')], stderr [$(head -3 "$_anl3_d.err" | tr '\n' ' ')]" \
     eval '[ "$_anl3_rc" != 0 ] && ! _anl3_has "$(cat "$_anl3_d.out")" "recorded a run of" \
           && ! _anl3_has "$(cat "$_anl3_d.err")" "no routine named" \
           && ! _anl3_has "$(cat "$_anl3_d.err")" "declares no maintenance routines"'
  _anl3_if "and felix maintenance --ran with $_anl3_kw at the log creates nothing there" "$_anl3_oddsay" test "$_anl3_oddok" = 0

  _anl3_budget "b-$_anl3_k-budget" "$_anl3_k"
  _anl3_if "felix_budget_record with $_anl3_kw at budget.log returns non-zero" \
     "returned $_anl3_rc" eval '[ "$_anl3_rc" != 0 ] && [ "$_anl3_rc" != 127 ]'
  _anl3_if "and felix_budget_record with $_anl3_kw at budget.log creates nothing there" "$_anl3_oddsay" test "$_anl3_oddok" = 0

  _anl3_mistake "b-$_anl3_k-mistake" "$_anl3_k"
  _anl3_if "felix_mem_mistake with $_anl3_kw at mistakes.log creates nothing there" "$_anl3_oddsay" test "$_anl3_oddok" = 0
done

# A FIFO. Main opens it to append, and an open for writing with no reader
# waits for one forever: this is the case where the defect is a session that
# never comes back. Bounded at 8 seconds of wall time, which is far from the
# cost of a refusal even on a loaded machine.
mkdir -p "$_anl3/fifo-budget" "$_anl3/fifo-maint"
mkfifo "$_anl3/fifo-budget/budget.log" "$_anl3/fifo-maint/maintenance.log"
_anl3_bounded 8 "$_anl3/fifo-budget/budget.log" \
  '. "$FROOT/harness/lib/budget.sh"; felix_budget_record "$_anl3/fifo-budget" "anl hand edit" >/dev/null 2>&1'
_anl3_rc=$?
_anl3_if "felix_budget_record onto a FIFO at budget.log returns non-zero without blocking" \
   "$( [ "$_anl3_rc" = 124 ] && echo 'still blocked at the 8 s deadline' || echo "returned $_anl3_rc")" \
   eval '[ "$_anl3_rc" != 0 ] && [ "$_anl3_rc" != 124 ] && [ "$_anl3_rc" != 127 ]'
_anl3_bounded 8 "$_anl3/fifo-maint/maintenance.log" \
  '. "$FROOT/harness/lib/maintenance.sh"; felix_maint_record "$_anl3/fifo-maint" anl-sweep >/dev/null 2>&1'
_anl3_rc=$?
_anl3_if "felix_maint_record onto a FIFO at maintenance.log returns non-zero without blocking" \
   "$( [ "$_anl3_rc" = 124 ] && echo 'still blocked at the 8 s deadline' || echo "returned $_anl3_rc")" \
   eval '[ "$_anl3_rc" != 0 ] && [ "$_anl3_rc" != 124 ] && [ "$_anl3_rc" != 127 ]'

# ------------------------------------- C: readers and an unended last line ----
_anl3_now="$(date +%s)"
_anl3_runs="$(printf '%s\t2026-10-01T00:00\tby hand\n%s\t2026-10-01T00:01\tby hand' "$((_anl3_now - 200))" "$((_anl3_now - 100))")"
mkdir -p "$_anl3/c-used" "$_anl3/c-used-nl" "$_anl3/c-rec"
printf '%s' "$_anl3_runs" > "$_anl3/c-used/budget.log"
printf '%s\n' "$_anl3_runs" > "$_anl3/c-used-nl/budget.log"
is "felix_budget_used counts a last run whose line has no final newline" \
   "$( . "$FROOT/harness/lib/budget.sh"; felix_budget_used "$_anl3/c-used" 2>&1 )" "2"
is "and felix_budget_used counts the same two runs when the log ends in a newline (control)" \
   "$( . "$FROOT/harness/lib/budget.sh"; felix_budget_used "$_anl3/c-used-nl" 2>&1 )" "2"

mkdir -p "$_anl3/c-maint" "$_anl3/c-maint-nl"
for _anl3_cd in c-maint c-maint-nl; do
  printf '# name\tcadence\tcapability\tdescription\nanl-sweep\t7\talways\tsweep the fixture\n' > "$_anl3/$_anl3_cd/maintenance.tsv"
done
_anl3_mruns="$(printf 'anl-sweep\t%s\t2026-09-01\nanl-sweep\t%s\t2026-10-01' "$((_anl3_now - 30 * 86400))" "$_anl3_now")"
printf '%s' "$_anl3_mruns" > "$_anl3/c-maint/maintenance.log"
printf '%s\n' "$_anl3_mruns" > "$_anl3/c-maint-nl/maintenance.log"
_anl3_mstat() { ( . "$FROOT/harness/lib/maintenance.sh"; felix_maint_status "$1" ) 2>/dev/null | awk -F'\t' '$2 == "anl-sweep" { print $1 }'; }
is "felix_maint_status reads a routine whose latest run is an unterminated last line as recently run" \
   "$(_anl3_mstat "$_anl3/c-maint")" "ok"
is "and felix_maint_status reads it the same when the log ends in a newline (control)" \
   "$(_anl3_mstat "$_anl3/c-maint-nl")" "ok"

printf '%s\t2026-10-01T00:00\tby hand' "$((_anl3_now - 200))" > "$_anl3/c-rec/budget.log"
is "felix_budget_record onto a one-run log with no final newline leaves felix_budget_used counting two" \
   "$( . "$FROOT/harness/lib/budget.sh"; felix_budget_record "$_anl3/c-rec" "anl hand edit" >/dev/null 2>&1
       felix_budget_used "$_anl3/c-rec" 2>&1 )" "2"

# ------------------------------------------------------- D: the gate's log ----
# An invented project bound by marker, the way the suite's others are: a gate
# that passes and prints no final newline, and one probe that is blind, so the
# engine's own probes checker prints FAIL straight after the gate's output.
# The control is the same project with a gate whose output ends in a newline.
_anl3_GP="$FROOT/projects/anl3gate"; _anl3_GR="$_anl3/gate-repo"
_anl3_had_gp=0; [ -e "$_anl3_GP" ] && _anl3_had_gp=1
_anl3_had_gm=0; [ -e "$MEM/anl3gate" ] && _anl3_had_gm=1
mkdir -p "$_anl3_GP" "$_anl3_GR"
( _fx_cd "$_anl3_GR" && git init -q -b main )
_anl3_GR="$(cd "$_anl3_GR" && pwd -P)"
printf 'anl3gate\n' > "$_anl3_GR/.felix"
printf 'contents\n' > "$_anl3_GR/PRESENT.txt"
# One commit, so the mistakes.log row has a branch and a sha. On an unborn
# HEAD, `git rev-parse --abbrev-ref HEAD` prints HEAD and fails, the `|| echo`
# prints `?` as well, and the row splits across two lines: a separate defect,
# and not the one these assertions are about.
( _fx_cd "$_anl3_GR" && git add -A && git -c user.name=anl3 -c user.email=anl3@example.invalid -c commit.gpgsign=false commit -qm anl3 )
printf '# anl3gate\n' > "$_anl3_GP/CLAUDE.md"
printf 'blindrow\t-\t-\tls -1 nothing-here.rs\ttest -f PRESENT.txt\n' > "$_anl3_GP/probes.tsv"
_anl3_gate() {   # case id, gate command as project.json holds it
  local d="$_anl3/$1"
  printf '{\n  "name": "anl3gate",\n  "remote_match": "example.invalid/anl3gate",\n  "gate": "%s"\n}\n' "$2" > "$_anl3_GP/project.json"
  rm -f "$MEM/anl3gate/mistakes.log"
  ( cd "$_anl3_GR" && "$FELIX" gate ) > "$d.out" 2> "$d.err"
  _anl3_rc=$?
  tail -1 "$MEM/anl3gate/mistakes.log" 2>/dev/null | cut -f4 | tr -s ' ' '\n' | awk 'NF' | tr '\n' ' ' | sed 's/ $//' > "$d.what"
  ( . "$FROOT/harness/lib/verify.sh"; felix_verify_receipt "$_anl3_GR" "$FROOT" ) 2>/dev/null | cut -f6 > "$d.reported"
}
_anl3_roster_has_probes() { case ",$(cat "$1" 2>/dev/null)," in *,probes:*) return 0 ;; esac; return 1; }
_anl3_gate gate-unended "printf 'gate: pass'"
is "felix gate puts the probes checker line on a line of its own after a gate whose output has no final newline" \
   "$(grep -cE '^  probes +FAIL' "$_anl3/gate-unended.out" | tr -d ' ')" "1"
is "and the mistakes.log row for that unended run names probes, not an exit status" \
   "$(cat "$_anl3/gate-unended.what")" "probes"
_anl3_if "and the roster that unended gate run records includes probes" \
   "reported [$(cat "$_anl3/gate-unended.reported")], exit $_anl3_rc" _anl3_roster_has_probes "$_anl3/gate-unended.reported"
_anl3_gate gate-ended "printf 'gate: pass\\n'"
is "felix gate puts the probes checker line on a line of its own after a gate whose output ends in a newline (control)" \
   "$(grep -cE '^  probes +FAIL' "$_anl3/gate-ended.out" | tr -d ' ')" "1"
is "and the mistakes.log row for the newline-terminated gate run names probes (control)" \
   "$(cat "$_anl3/gate-ended.what")" "probes"
_anl3_if "and the roster the newline-terminated gate run records includes probes (control)" \
   "reported [$(cat "$_anl3/gate-ended.reported")], exit $_anl3_rc" _anl3_roster_has_probes "$_anl3/gate-ended.reported"
_anl3_receipt="$( . "$FROOT/harness/lib/verify.sh"; _felix_receipt_path "$_anl3_GR" "$FROOT" )"

# ---------------------------------------------------- E: mistakes.log, C1-C3 ----
for _anl3_c in none nl nul; do
  case "$_anl3_c" in nl) _anl3_mistake "e-$_anl3_c" open ;; *) _anl3_mistake "e-$_anl3_c" "$_anl3_c" ;; esac
done
_anl3_EL="${#_anl3_EO}"   # the old bytes with their newline
is "recording a mistake onto a hand-curated mistakes.log with no final newline keeps its last line and records on a line of its own" \
   "$(_anl3_norm "$_anl3/mem/e-none/mistakes.log" "$((_anl3_EL - 1))")" "$(_anl3_want '%s9-9-9\t?\t?\tanl-lint\t9\t-\n' "$_anl3_EO")"
is "recording a mistake onto a mistakes.log ending in a newline adds no blank line" \
   "$(_anl3_norm "$_anl3/mem/e-nl/mistakes.log" "$_anl3_EL")" "$(_anl3_want '%s9-9-9\t?\t?\tanl-lint\t9\t-\n' "$_anl3_EO")"
is "recording a mistake onto a mistakes.log ending in a NUL byte writes a newline after the NUL first" \
   "$(_anl3_norm "$_anl3/mem/e-nul/mistakes.log" "$_anl3_EL")" "$(_anl3_want '%s\0\n9-9-9\t?\t?\tanl-lint\t9\t-\n' "${_anl3_EO%$'\n'}")"

# ------------------------------------------------------------- the restore ----
_anl3_i=0
for _f in $_anl3_wfiles; do
  _anl3_i=$((_anl3_i + 1))
  _anl3_clear "$_f"
  [ -e "$_anl3/keep.$_anl3_i" ] && cp -p "$_anl3/keep.$_anl3_i" "$_f"
done
[ "$_anl3_had_gp" -eq 1 ] || rm -rf "$_anl3_GP"
[ "$_anl3_had_gm" -eq 1 ] || rm -rf "$MEM/anl3gate"
[ -n "$_anl3_receipt" ] && rm -f "$_anl3_receipt"
[ "$_anl3_had_gate" -eq 1 ]  || rmdir "$FROOT/state/gate" 2>/dev/null
[ "$_anl3_had_disc" -eq 1 ]  || rmdir "$FROOT/state/discover" 2>/dev/null
[ "$_anl3_had_state" -eq 1 ] || rmdir "$FROOT/state" 2>/dev/null
_anl3_back=""
_anl3_i=0
for _f in $_anl3_wfiles; do
  _anl3_i=$((_anl3_i + 1))
  if [ -e "$_anl3/keep.$_anl3_i" ]; then cmp -s "$_f" "$_anl3/keep.$_anl3_i" || _anl3_back="$_anl3_back $_f"
  else { [ ! -e "$_f" ] && [ ! -L "$_f" ]; } || _anl3_back="$_anl3_back $_f"; fi
done
[ "$(_anl3_modes)" = "$_anl3_modes_was" ] || _anl3_back="$_anl3_back modes[$(_anl3_modes | tr '\n' ' ')]"
{ [ "$_anl3_had_gp" -eq 1 ] || [ ! -e "$_anl3_GP" ]; } || _anl3_back="$_anl3_back projects/anl3gate"
{ [ "$_anl3_had_gm" -eq 1 ] || [ ! -e "$MEM/anl3gate" ]; } || _anl3_back="$_anl3_back memory/anl3gate"
[ ! -e "$_anl3_receipt" ] || _anl3_back="$_anl3_back receipt"
{ [ "$_anl3_had_disc" -eq 1 ] || [ ! -e "$FROOT/state/discover" ]; } || _anl3_back="$_anl3_back state/discover"
{ [ "$_anl3_had_gate" -eq 1 ] || [ ! -e "$FROOT/state/gate" ]; } || _anl3_back="$_anl3_back state/gate"
# git writes its objects read-only on purpose; those modes are git's, not ours.
_anl3_locked="$(find "$_anl3" -path "$_anl3/gate-repo/.git" -prune -o -type f ! -perm -600 -print 2>/dev/null)"
[ -z "$_anl3_locked" ] || _anl3_back="$_anl3_back still-locked[$(printf '%s' "$_anl3_locked" | tr '\n' ' ')]"
for _anl3_j in $(jobs -p); do
  case "$_anl3_jobs_was" in *" $_anl3_j "*) ;; *) _anl3_back="$_anl3_back background-job[$_anl3_j]" ;; esac
done
is "and the widget files, the invented gate project and every mode the third block changed are back as they were" "$_anl3_back" ""
