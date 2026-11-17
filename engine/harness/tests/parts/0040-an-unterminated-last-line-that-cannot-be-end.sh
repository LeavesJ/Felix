printf '\nan unterminated last line that cannot be ended\n'
# Written blind on 2026-10-01, from a second contract, by the same author,
# still without the fix: a last line that cannot be ended. Red against
# origin/main: 37 of 58.
# The other half of appending after a hand-written last line. A table that is
# non-empty and does not end in a newline must be ended before a row goes on
# it, and sometimes it cannot be: read-only (444), the newline cannot be
# written; write-only (200), the last byte cannot be read to know whether one
# is owed. Either way the writer must leave the table byte for byte as it was
# and must not claim a write it did not make: no count, no "allowed", no
# install of a row that is not in the manifest, no "recorded".
#
# Read-only is green on main wherever main's own append fails and main notices.
# Write-only is red on main for every writer, because a write-only file still
# takes an append: main fuses onto it without ever reading the byte it fused to.
#
# Root writes through any mode, so under root every case here skips; the
# control and the restore check run regardless. Every mode changed is put back
# straight after the writer runs, and the widget files are restored at the end.
_anl2="$TMP/anl2"; mkdir -p "$_anl2/bin" "$_anl2/tpl/setup" "$_anl2/mem"
_anl2_root=0; [ "$(id -u)" = "0" ] && _anl2_root=1
_anl2_od()    { od -An -c | tr '\n' ' ' | tr -s ' '; }
_anl2_bytes() { if [ -e "$1" ]; then _anl2_od < "$1"; else printf 'absent'; fi; }
_anl2_want()  { printf "$@" | _anl2_od; }
_anl2_lock()  { case "$2" in read-only) chmod 444 "$1" ;; write-only) chmod 200 "$1" ;; esac; }
_anl2_is()    { if [ "$_anl2_root" = 1 ]; then skip "$1" "running as root"; else is "$@"; fi; }
_anl2_if()    {   # name, detail, command...: ok when the command succeeds
  local n="$1" d="$2"; shift 2
  if [ "$_anl2_root" = 1 ]; then skip "$n" "running as root"
  elif "$@"; then ok "$n"; else bad "$n" "$d"; fi
}
_anl2_has()   { case "$1" in *"$2"*) return 0 ;; esac; return 1; }
_anl2_nl='
'
_anl2_line()  { case "$_anl2_nl$1$_anl2_nl" in *"$_anl2_nl$2$_anl2_nl"*) return 0 ;; esac; return 1; }

# One catalogue, one setup step and its instructions file, all for `obs`, so a
# backfill that should not have happened is visible.
printf '# kind\tname\tsource\trisk\tcapability\tkeywords\nplugin\tanl-obs-a\t-\tlow\tobs\tobs tracing\nmcp\tanl-obs-b\thttps://example.invalid/mcp\tmedium\tobs\tobs\nplugin\tanl-elsewhere\t-\tlow\tother\tother\n' \
  > "$_anl2/tpl/catalog.tsv"
printf '# id\ttitle\tcapability\tcheck\nanl-step\tWire the obs thing\tobs\tgh api repos/{{REPO}}/hooks\n' \
  > "$_anl2/tpl/setup.tsv"
printf '# Wire the obs thing for {{REPO}}\n' > "$_anl2/tpl/setup/anl-step.md"
_anl2_SH=$'# kind\tname\tsource\trisk\tcapability\tgrounding\n'
_anl2_UH=$'# id\ttitle\tcapability\tcheck\n'
_anl2_SO=$'plugin\tanl-kept\t-\tlow\tapi\tDECLARED'
_anl2_UO=$'anl-kept-step\tKept by hand\tapi\ttrue'
_anl2_SR=$'plugin\tanl-obs-a\t-\tlow\tobs\tDECLARED\nmcp\tanl-obs-b\thttps://example.invalid/mcp\tmedium\tobs\tDECLARED\n'
_anl2_UR=$'anl-step\tWire the obs thing\tobs\tgh api repos/{{REPO}}/hooks\n'
_anl2_DO=$'plugin\tanl-hand-kept\t-\tlow\tllm\tDECLARED'
_anl2_MO=$'anl-sweep\t1700000000\t2023-11-14'
_anl2_BO=$'1700000000\t2023-11-14T22:13\tby hand'

# The widget files the CLI writers touch, saved with their modes, absent
# included, and the discovery cache's directory if this block has to make it.
_anl2_W="$FROOT/projects/widget"
_anl2_cache="$FROOT/state/discover/widget.tsv"
_anl2_wfiles="$_anl2_W/autonomy $_anl2_W/stack.tsv $_anl2_W/maintenance.tsv $_anl2_W/maintenance.log $_anl2_cache"
_anl2_modes() { for _f in $_anl2_wfiles; do if [ -e "$_f" ]; then ls -l "$_f" | cut -c1-10; else echo absent; fi; done; }
_anl2_modes_was="$(_anl2_modes)"
_anl2_i=0
for _f in $_anl2_wfiles; do
  _anl2_i=$((_anl2_i + 1)); rm -f "$_anl2/keep.$_anl2_i"
  [ -e "$_f" ] && cp -p "$_f" "$_anl2/keep.$_anl2_i"
done
_anl2_had_state=0; [ -d "$FROOT/state" ] && _anl2_had_state=1
_anl2_had_disc=0;  [ -d "$FROOT/state/discover" ] && _anl2_had_disc=1
mkdir -p "$FROOT/state/discover"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/claude.log"\nexit 1\n' "$_anl2" > "$_anl2/bin/claude"
chmod +x "$_anl2/bin/claude"
_anl2_dstamp="$( . "$FROOT/harness/lib/discover.sh"; _felix_discover_stamp_line "$FROOT/harness/templates" )"
printf '# name\tcadence\tcapability\tdescription\nanl-sweep\t7\talways\tsweep the fixture\n' > "$_anl2_W/maintenance.tsv"

# Each runner seeds its table, applies the mode, runs the writer with stdout
# and stderr kept apart, and gives the table its mode back before anything is
# judged. $1 is the case directory, $2 the mode or `open` for the control.
_anl2_adopt() {   # dir, mode, which table to lock (capabilities | stack.tsv | setup.tsv)
  local d="$_anl2/$1" t
  mkdir -p "$d"
  printf 'api\n'               > "$d/capabilities"
  printf '%s%s\n' "$_anl2_SH" "$_anl2_SO" > "$d/stack.tsv"
  printf '%s%s\n' "$_anl2_UH" "$_anl2_UO" > "$d/setup.tsv"
  case "$3" in
    capabilities) printf 'api' > "$d/capabilities" ;;
    stack.tsv)    printf '%s%s' "$_anl2_SH" "$_anl2_SO" > "$d/stack.tsv" ;;
    setup.tsv)    printf '%s%s' "$_anl2_UH" "$_anl2_UO" > "$d/setup.tsv" ;;
  esac
  for t in capabilities stack.tsv setup.tsv; do cp "$d/$t" "$d.$t.was"; done
  [ -n "$3" ] && _anl2_lock "$d/$3" "$2"
  ( . "$FROOT/harness/lib/adopt.sh"; felix_adopt_capability "$d" obs "$_anl2/tpl" acme/widget ) > "$d.out" 2> "$d.err"
  _anl2_rc=$?
  [ -n "$3" ] && chmod 644 "$d/$3"
}
_anl2_autonomy() {   # dir, mode
  local d="$_anl2/$1"
  mkdir -p "$d"
  if [ "$2" = open ]; then printf 'commission\n' > "$_anl2_W/autonomy"; else printf 'commission' > "$_anl2_W/autonomy"; fi
  cp "$_anl2_W/autonomy" "$d.was"
  _anl2_lock "$_anl2_W/autonomy" "$2"
  ( cd "$REPO" && "$FELIX" autonomy --allow tidy ) > "$d.out" 2> "$d.err"
  _anl2_rc=$?
  chmod 644 "$_anl2_W/autonomy"
  cp "$_anl2_W/autonomy" "$d.now"
}
_anl2_discover() {   # dir, mode
  local d="$_anl2/$1"
  mkdir -p "$d"
  rm -f "$_anl2/claude.log"
  if [ "$2" = open ]; then printf '%s%s\n' "$_anl2_SH" "$_anl2_DO" > "$_anl2_W/stack.tsv"
  else printf '%s%s' "$_anl2_SH" "$_anl2_DO" > "$_anl2_W/stack.tsv"; fi
  cp "$_anl2_W/stack.tsv" "$d.was"
  printf '%s\nanl-adopted\tllm\tlow\t-\n' "$_anl2_dstamp" > "$_anl2_cache"
  _anl2_lock "$_anl2_W/stack.tsv" "$2"
  ( cd "$REPO" && PATH="$_anl2/bin:$PATH" "$FELIX" discover --adopt ) > "$d.out" 2>&1
  _anl2_rc=$?
  chmod 644 "$_anl2_W/stack.tsv"
  cp "$_anl2_W/stack.tsv" "$d.now"
  cp "$_anl2/claude.log" "$d.claude" 2>/dev/null || : > "$d.claude"
}
_anl2_apply() {   # dir, mode
  local d="$_anl2/$1"
  mkdir -p "$d"
  if [ "$2" = open ]; then printf '%s%s\n' "$_anl2_SH" "$_anl2_DO" > "$d/stack.tsv"
  else printf '%s%s' "$_anl2_SH" "$_anl2_DO" > "$d/stack.tsv"; fi
  cp "$d/stack.tsv" "$d.was"
  _anl2_lock "$d/stack.tsv" "$2"
  ( FELIX_MEMORY="$_anl2/mem"; export FELIX_MEMORY
    . "$FROOT/harness/lib/commission.sh"; . "$FROOT/harness/lib/commission-provider.sh"
    felix_commission_apply_declares "$d" "$REPO" \
      "$(printf 'declare\tplugin\tanl-declared\tlow\tllm\tdeadbeef\tthe fixture\n')" anl-tree anl-policy anl_need ) \
    > "$d.out" 2> "$d.err"
  _anl2_rc=$?
  chmod 644 "$d/stack.tsv"
}
_anl2_maint() {   # dir, mode
  local d="$_anl2/$1"
  mkdir -p "$d"
  if [ "$2" = open ]; then printf '%s\n' "$_anl2_MO" > "$_anl2_W/maintenance.log"
  else printf '%s' "$_anl2_MO" > "$_anl2_W/maintenance.log"; fi
  cp "$_anl2_W/maintenance.log" "$d.was"
  _anl2_lock "$_anl2_W/maintenance.log" "$2"
  ( cd "$REPO" && "$FELIX" maintenance --ran anl-sweep ) > "$d.out" 2> "$d.err"
  _anl2_rc=$?
  chmod 644 "$_anl2_W/maintenance.log"
  cp "$_anl2_W/maintenance.log" "$d.now"
}
_anl2_budget() {   # dir, mode
  local d="$_anl2/$1"
  mkdir -p "$d"
  if [ "$2" = open ]; then printf '%s\n' "$_anl2_BO" > "$d/budget.log"
  else printf '%s' "$_anl2_BO" > "$d/budget.log"; fi
  cp "$d/budget.log" "$d.was"
  _anl2_lock "$d/budget.log" "$2"
  ( . "$FROOT/harness/lib/budget.sh"; felix_budget_record "$d" "anl hand edit" ) > "$d.out" 2> "$d.err"
  _anl2_rc=$?
  chmod 644 "$d/budget.log"
}

# The control. Every runner above, on a table ending in a newline that can be
# written, writes its row. Without this, "the table is unchanged" and "it
# exited non-zero" are both what a runner that never reached the writer would
# report, and a pass below would be a statement about the fixture.
_anl2_ctl=""
_anl2_adopt ctl-adopt open ""
[ "$(cat "$_anl2/ctl-adopt.out")" = "2 1" ] && [ "$(cat "$_anl2/ctl-adopt/capabilities")" = "$(printf 'api\nobs')" ] \
  || _anl2_ctl="$_anl2_ctl adopt[$(cat "$_anl2/ctl-adopt.out" "$_anl2/ctl-adopt.err" | tr '\n' ' ')]"
_anl2_autonomy ctl-autonomy open
_anl2_line "$(cat "$_anl2/ctl-autonomy.out")" "allowed: tidy" \
  && [ "$(_anl2_bytes "$_anl2/ctl-autonomy.now")" = "$(_anl2_want 'commission\ntidy\n')" ] \
  || _anl2_ctl="$_anl2_ctl autonomy[$(head -3 "$_anl2/ctl-autonomy.out" "$_anl2/ctl-autonomy.err" | tr '\n' ' ')]"
_anl2_discover ctl-discover open
grep -q '^plugin install anl-adopted' "$_anl2/ctl-discover.claude" \
  && [ "$(_anl2_bytes "$_anl2/ctl-discover.now")" = "$(_anl2_want '%s%s\nplugin\tanl-adopted\t-\tlow\tllm\tOBSERVED\n' "$_anl2_SH" "$_anl2_DO")" ] \
  || _anl2_ctl="$_anl2_ctl discover[$(head -4 "$_anl2/ctl-discover.out" | tr '\n' ' ')]"
_anl2_apply ctl-apply open
[ "$(cat "$_anl2/ctl-apply.out")" = "1" ] || _anl2_ctl="$_anl2_ctl apply[$(cat "$_anl2/ctl-apply.out" "$_anl2/ctl-apply.err" | tr '\n' ' ')]"
_anl2_maint ctl-maint open
_anl2_has "$(cat "$_anl2/ctl-maint.out")" "recorded a run of anl-sweep" && [ "$(wc -l < "$_anl2/ctl-maint.now" | tr -d ' ')" = "2" ] \
  || _anl2_ctl="$_anl2_ctl maintenance[$(cat "$_anl2/ctl-maint.out" "$_anl2/ctl-maint.err" | head -3 | tr '\n' ' ')]"
_anl2_budget ctl-budget open
[ "$_anl2_rc" = 0 ] && [ "$(wc -l < "$_anl2/ctl-budget/budget.log" | tr -d ' ')" = "2" ] \
  || _anl2_ctl="$_anl2_ctl budget[rc $_anl2_rc]"
is "every writer the unwritable cases below refuse still writes its row to a table it can end (control)" "$_anl2_ctl" ""

for _anl2_m in read-only write-only; do
  _anl2_k="${_anl2_m%%-*}"   # read | write, for directory names

  # -------------------------------- felix_adopt_capability, capabilities ----
  _anl2_adopt "a1-$_anl2_k" "$_anl2_m" capabilities
  _anl2_d="$_anl2/a1-$_anl2_k"
  _anl2_is "adopting onto a $_anl2_m capabilities list with no final newline leaves the list byte for byte" \
     "$(_anl2_bytes "$_anl2_d/capabilities")" "$(_anl2_bytes "$_anl2_d.capabilities.was")"
  _anl2_is "and adopting onto that $_anl2_m capabilities list returns 2 and prints no counts" \
     "$_anl2_rc[$(cat "$_anl2_d.out")]" "2[]"
  _anl2_is "and adopting onto that $_anl2_m capabilities list backfills no stack.tsv or setup.tsv row" \
     "$(_anl2_bytes "$_anl2_d/stack.tsv") | $(_anl2_bytes "$_anl2_d/setup.tsv")" \
     "$(_anl2_bytes "$_anl2_d.stack.tsv.was") | $(_anl2_bytes "$_anl2_d.setup.tsv.was")"

  # ----------------------------------- felix_adopt_capability, stack.tsv ----
  _anl2_adopt "a2-$_anl2_k" "$_anl2_m" stack.tsv
  _anl2_d="$_anl2/a2-$_anl2_k"
  _anl2_is "adopting onto a $_anl2_m stack.tsv with no final newline leaves it byte for byte" \
     "$(_anl2_bytes "$_anl2_d/stack.tsv")" "$(_anl2_bytes "$_anl2_d.stack.tsv.was")"
  _anl2_is "and the stack count adopting prints for that $_anl2_m stack.tsv leaves out the rows it could not write" \
     "$(cat "$_anl2_d.out")" "0 1"
  _anl2_e="$(cat "$_anl2_d.err")"
  _anl2_if "and adopting onto that $_anl2_m stack.tsv names it and each catalogue row it left out on stderr" \
     "stderr was [$(printf '%s' "$_anl2_e" | tr '\n' ' ')]" \
     eval '_anl2_has "$_anl2_e" stack.tsv && _anl2_has "$_anl2_e" anl-obs-a && _anl2_has "$_anl2_e" anl-obs-b'
  _anl2_is "and adopting onto that $_anl2_m stack.tsv still records the capability and writes its setup step" \
     "$(_anl2_bytes "$_anl2_d/capabilities") | $(_anl2_bytes "$_anl2_d/setup.tsv")" \
     "$(_anl2_want 'api\nobs\n') | $(_anl2_want '%s%s\n%s' "$_anl2_UH" "$_anl2_UO" "$_anl2_UR")"

  # ----------------------------------- felix_adopt_capability, setup.tsv ----
  _anl2_adopt "a3-$_anl2_k" "$_anl2_m" setup.tsv
  _anl2_d="$_anl2/a3-$_anl2_k"
  _anl2_is "adopting onto a $_anl2_m setup.tsv with no final newline leaves it byte for byte" \
     "$(_anl2_bytes "$_anl2_d/setup.tsv")" "$(_anl2_bytes "$_anl2_d.setup.tsv.was")"
  _anl2_is "and the setup count adopting prints for that $_anl2_m setup.tsv leaves out the step it could not write" \
     "$(cat "$_anl2_d.out")" "2 0"
  _anl2_e="$(cat "$_anl2_d.err")"
  _anl2_if "and adopting onto that $_anl2_m setup.tsv names it and the step it left out on stderr" \
     "stderr was [$(printf '%s' "$_anl2_e" | tr '\n' ' ')]" \
     eval '_anl2_has "$_anl2_e" setup.tsv && _anl2_has "$_anl2_e" anl-step'
  _anl2_if "and adopting onto that $_anl2_m setup.tsv writes no instructions file for the step it left out" \
     "$_anl2_d/setup/anl-step.md exists: [$(cat "$_anl2_d/setup/anl-step.md" 2>&1)]" \
     test ! -e "$_anl2_d/setup/anl-step.md"
  _anl2_is "and adopting onto that $_anl2_m setup.tsv still records the capability and writes its stack rows" \
     "$(_anl2_bytes "$_anl2_d/capabilities") | $(_anl2_bytes "$_anl2_d/stack.tsv")" \
     "$(_anl2_want 'api\nobs\n') | $(_anl2_want '%s%s\n%s' "$_anl2_SH" "$_anl2_SO" "$_anl2_SR")"

  # ------------------------------------------- felix autonomy --allow tidy ----
  _anl2_autonomy "a4-$_anl2_k" "$_anl2_m"
  _anl2_d="$_anl2/a4-$_anl2_k"
  _anl2_is "felix autonomy --allow onto a $_anl2_m grant with no final newline leaves the file byte for byte" \
     "$(_anl2_bytes "$_anl2_d.now")" "$(_anl2_bytes "$_anl2_d.was")"
  _anl2_if "and felix autonomy --allow onto that $_anl2_m grant exits non-zero without saying allowed" \
     "exit $_anl2_rc, stdout [$(head -3 "$_anl2_d.out" | tr '\n' ' ')]" \
     eval '[ "$_anl2_rc" != 0 ] && ! _anl2_line "$(cat "$_anl2_d.out")" "allowed: tidy"'
  _anl2_e="$(cat "$_anl2_d.err")"
  _anl2_if "and felix autonomy --allow onto that $_anl2_m grant names the autonomy file on stderr" \
     "stderr was [$(printf '%s' "$_anl2_e" | tr '\n' ' ')]" _anl2_has "$_anl2_e" "/autonomy"
  # Asked with the mode given back, so it reads what is in the file and not
  # merely that the file could not be opened.
  _anl2_if "and after felix autonomy --allow onto that $_anl2_m grant, tidy is not granted" \
     "felix_autonomy_allows reads tidy as granted from [$(_anl2_bytes "$_anl2_W/autonomy")]" \
     eval '! ( . "$FROOT/harness/lib/autonomy.sh"; felix_autonomy_allows "$_anl2_W" tidy ) 2>/dev/null'

  # -------------------------------------------------- felix discover --adopt ----
  _anl2_discover "a5-$_anl2_k" "$_anl2_m"
  _anl2_d="$_anl2/a5-$_anl2_k"
  _anl2_o="$(cat "$_anl2_d.out")"
  _anl2_is "felix discover --adopt onto a $_anl2_m stack.tsv with no final newline leaves it byte for byte" \
     "$(_anl2_bytes "$_anl2_d.now")" "$(_anl2_bytes "$_anl2_d.was")"
  # The plan must have reached the row, or "no install" and "no declared line"
  # are what a run that never read the cache would print too.
  if _anl2_has "$_anl2_o" "adopting for"; then
    _anl2_if "and felix discover --adopt onto that $_anl2_m stack.tsv attempts no install of the row it could not write" \
       "the stub was asked: [$(tr '\n' ' ' < "$_anl2_d.claude")]" \
       eval '! grep -q "^plugin install anl-adopted" "$_anl2_d.claude"'
    _anl2_if "and felix discover --adopt onto that $_anl2_m stack.tsv prints no installed or declared line for that row" \
       "output [$(printf '%s' "$_anl2_o" | tr '\n' ' ')]" \
       eval '! grep -Eq "^ *(installed|declared) +anl-adopted( |\$)" <<<"$_anl2_o"'
  else
    _anl2_if "and felix discover --adopt onto that $_anl2_m stack.tsv attempts no install of the row it could not write" \
       "the plan never reached the row, so this measured the fixture: [$(printf '%s' "$_anl2_o" | head -4 | tr '\n' ' ')]" false
    _anl2_if "and felix discover --adopt onto that $_anl2_m stack.tsv prints no installed or declared line for that row" \
       "the plan never reached the row, so this measured the fixture: [$(printf '%s' "$_anl2_o" | head -4 | tr '\n' ' ')]" false
  fi
  _anl2_if "and felix discover --adopt onto that $_anl2_m stack.tsv names that row unwritten" \
     "output [$(printf '%s' "$_anl2_o" | tr '\n' ' ')]" \
     eval 'awk "/anl-adopted/ && /unwritten/ { f = 1 } END { exit !f }" <<<"$_anl2_o"'
  _anl2_if "and felix discover --adopt onto that $_anl2_m stack.tsv sums up 0 adopted" \
     "output [$(printf '%s' "$_anl2_o" | tr '\n' ' ')]" \
     eval 'awk "/^0 adopted/ { f = 1 } END { exit !f }" <<<"$_anl2_o"'

  # ------------------------------------- felix_commission_apply_declares ----
  _anl2_apply "a6-$_anl2_k" "$_anl2_m"
  _anl2_d="$_anl2/a6-$_anl2_k"
  _anl2_is "commissioning's apply onto a $_anl2_m stack.tsv with no final newline leaves it byte for byte" \
     "$(_anl2_bytes "$_anl2_d/stack.tsv")" "$(_anl2_bytes "$_anl2_d.was")"
  _anl2_is "and commissioning's apply onto that $_anl2_m stack.tsv counts no declare" \
     "$(cat "$_anl2_d.out")" "0"
  _anl2_is "and commissioning's apply onto that $_anl2_m stack.tsv logs no declare for the row" \
     "$(awk -F'\t' '$5 == "declared" && index($0, "anl-declared") { n++ } END { print n + 0 }' "$_anl2/mem/a6-$_anl2_k/commissioning.log" 2>/dev/null || echo 0)" "0"

  # --------------------------------------------- felix maintenance --ran ----
  _anl2_maint "a7-$_anl2_k" "$_anl2_m"
  _anl2_d="$_anl2/a7-$_anl2_k"
  _anl2_is "felix maintenance --ran onto a $_anl2_m log with no final newline leaves the log byte for byte" \
     "$(_anl2_bytes "$_anl2_d.now")" "$(_anl2_bytes "$_anl2_d.was")"
  _anl2_if "and felix maintenance --ran onto that $_anl2_m log exits non-zero without saying it recorded the run" \
     "exit $_anl2_rc, stdout [$(head -3 "$_anl2_d.out" | tr '\n' ' ')], stderr [$(head -3 "$_anl2_d.err" | tr '\n' ' ')]" \
     eval '[ "$_anl2_rc" != 0 ] && ! _anl2_has "$(cat "$_anl2_d.out")" "recorded a run of" \
           && ! _anl2_has "$(cat "$_anl2_d.err")" "no routine named" \
           && ! _anl2_has "$(cat "$_anl2_d.err")" "declares no maintenance routines"'

  # ------------------------------------------------- felix_budget_record ----
  _anl2_budget "a8-$_anl2_k" "$_anl2_m"
  _anl2_d="$_anl2/a8-$_anl2_k"
  _anl2_is "recording a budget run onto a $_anl2_m log with no final newline leaves the log byte for byte" \
     "$(_anl2_bytes "$_anl2_d/budget.log")" "$(_anl2_bytes "$_anl2_d.was")"
  _anl2_if "and felix_budget_record onto that $_anl2_m log returns non-zero" \
     "returned $_anl2_rc" eval '[ "$_anl2_rc" != 0 ] && [ "$_anl2_rc" != 127 ]'
done

# Put the widget back: content and mode from the copies, absent included, and
# the cache's directory only if this block made it.
_anl2_i=0
for _f in $_anl2_wfiles; do
  _anl2_i=$((_anl2_i + 1))
  rm -f "$_f"
  [ -e "$_anl2/keep.$_anl2_i" ] && cp -p "$_anl2/keep.$_anl2_i" "$_f"
done
[ "$_anl2_had_disc" -eq 1 ]  || rmdir "$FROOT/state/discover" 2>/dev/null
[ "$_anl2_had_state" -eq 1 ] || rmdir "$FROOT/state" 2>/dev/null
_anl2_back=""
_anl2_i=0
for _f in $_anl2_wfiles; do
  _anl2_i=$((_anl2_i + 1))
  if [ -e "$_anl2/keep.$_anl2_i" ]; then cmp -s "$_f" "$_anl2/keep.$_anl2_i" || _anl2_back="$_anl2_back $_f"
  else [ ! -e "$_f" ] || _anl2_back="$_anl2_back $_f"; fi
done
[ "$(_anl2_modes)" = "$_anl2_modes_was" ] || _anl2_back="$_anl2_back modes[$(_anl2_modes | tr '\n' ' ')]"
{ [ "$_anl2_had_disc" -eq 1 ] || [ ! -e "$FROOT/state/discover" ]; } || _anl2_back="$_anl2_back state/discover"
_anl2_locked="$(find "$_anl2" -type f ! -perm -600 2>/dev/null)"
[ -z "$_anl2_locked" ] || _anl2_back="$_anl2_back still-locked[$(printf '%s' "$_anl2_locked" | tr '\n' ' ')]"
is "and the widget files and every mode those unwritable cases changed are back as they were" "$_anl2_back" ""

