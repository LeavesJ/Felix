printf '\na partial backfill, a pipe at a table, and a mistake on an unborn checkout\n'
# Written blind on 2026-10-01, from a fourth contract, after a second review:
# a backfill that is only partly written, a pipe at the table, and a mistake
# row on a checkout with no commit. Red against origin/main: 11 of 17.
# Three last edges of the same family.
#   F  A capability is recorded but a row it implies cannot be written: the
#      adopt says so in its status (3), its counts, its CLI and the session
#      hook, and an adopt that wrote everything still returns 0.
#   G  A FIFO at stack.tsv or setup.tsv must not block the writer, which must
#      not count a row it could not write. Every call there is bounded.
#   H  On a checkout with no commit, `git rev-parse --abbrev-ref HEAD` prints
#      HEAD and fails, an `|| echo '?'` prints a second word, and a mistakes.log
#      row written from both splits across two lines.
#
# F's unwritable tables are read-only, so F skips under root; its controls, G
# and H do not depend on a mode and run regardless. The widget's capabilities,
# stack.tsv, setup.tsv and setup/ are saved and put back; the two projects the
# hook cases invent are removed with their memory.
_anl4="$TMP/anl4"; mkdir -p "$_anl4/tpl/setup" "$_anl4/mem"
_anl4_root=0; [ "$(id -u)" = "0" ] && _anl4_root=1
_anl4_od()    { od -An -c | tr '\n' ' ' | tr -s ' '; }
_anl4_bytes() { if [ -e "$1" ]; then _anl4_od < "$1"; else printf 'absent'; fi; }
_anl4_want()  { printf "$@" | _anl4_od; }
_anl4_has()   { case "$1" in *"$2"*) return 0 ;; esac; return 1; }
_anl4_if()    {   # name, detail, command...: ok when the command succeeds
  local n="$1" d="$2"; shift 2
  if "$@"; then ok "$n"; else bad "$n" "$d"; fi
}
_anl4_ifr()   { if [ "$_anl4_root" = 1 ]; then skip "$1" "running as root"; else _anl4_if "$@"; fi; }
_anl4_isr()   { if [ "$_anl4_root" = 1 ]; then skip "$1" "running as root"; else is "$@"; fi; }

# A call that may never return, bounded: a background subshell polled against
# a deadline. On timeout the subshell and every process under it, found by
# parent pid and never by pattern, are killed, and anything still waiting on
# the FIFO is released by opening it read-write, which returns at once.
_anl4_tree()  {   # pid -> it and every descendant
  ps -A -o pid= -o ppid= 2>/dev/null | awk -v root="$1" '
    { kids[$2] = kids[$2] " " $1 }
    END { q = root; out = ""
          while (q != "") { n = split(q, a, " "); q = ""
                            for (i = 1; i <= n; i++) if (a[i] != "") { out = out " " a[i]; q = q kids[a[i]] } }
          print out }'
}
_anl4_bounded() {   # seconds, fifo, code -> the code's status, or 124
  local secs="$1" fifo="$2" pid n=0 k
  ( eval "$3" ) & pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$n" -lt $((secs * 10)) ]; do sleep 0.1; n=$((n + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    for k in $(_anl4_tree "$pid"); do kill -9 "$k" 2>/dev/null; done
    wait "$pid" 2>/dev/null
    [ -p "$fifo" ] && ( exec 9<>"$fifo" ) 2>/dev/null
    return 124
  fi
  wait "$pid"
}

printf '# kind\tname\tsource\trisk\tcapability\tkeywords\nplugin\tanl-obs-a\t-\tlow\tobs\tobs tracing\nmcp\tanl-obs-b\thttps://example.invalid/mcp\tmedium\tobs\tobs\n' \
  > "$_anl4/tpl/catalog.tsv"
printf '# id\ttitle\tcapability\tcheck\nanl-step\tWire the obs thing\tobs\tgh api repos/{{REPO}}/hooks\n' \
  > "$_anl4/tpl/setup.tsv"
printf '# Wire the obs thing for {{REPO}}\n' > "$_anl4/tpl/setup/anl-step.md"
_anl4_SH=$'# kind\tname\tsource\trisk\tcapability\tgrounding\n'
_anl4_UH=$'# id\ttitle\tcapability\tcheck\n'
_anl4_SO=$'plugin\tanl-kept\t-\tlow\tapi\tDECLARED\n'
_anl4_UO=$'anl-kept-step\tKept by hand\tapi\ttrue\n'
_anl4_SR=$'plugin\tanl-obs-a\t-\tlow\tobs\tDECLARED\nmcp\tanl-obs-b\thttps://example.invalid/mcp\tmedium\tobs\tDECLARED\n'
_anl4_UR=$'anl-step\tWire the obs thing\tobs\tgh api repos/{{REPO}}/hooks\n'
_anl4_DO=$'plugin\tanl-hand-kept\t-\tlow\tllm\tDECLARED\n'

# The widget files felix adopt writes, saved with their modes, absent included.
_anl4_W="$FROOT/projects/widget"
_anl4_wfiles="$_anl4_W/capabilities $_anl4_W/stack.tsv $_anl4_W/setup.tsv"
_anl4_modes() { for _f in $_anl4_wfiles; do if [ -e "$_f" ]; then ls -ld "$_f" | cut -c1-10; else echo absent; fi; done; }
_anl4_modes_was="$(_anl4_modes)"
_anl4_i=0
for _f in $_anl4_wfiles; do
  _anl4_i=$((_anl4_i + 1)); rm -f "$_anl4/keep.$_anl4_i"
  [ -e "$_f" ] && cp -p "$_f" "$_anl4/keep.$_anl4_i"
done
_anl4_had_setup=0; [ -d "$_anl4_W/setup" ] && { _anl4_had_setup=1; cp -Rp "$_anl4_W/setup" "$_anl4/keep.setup"; }
_anl4_jobs_was=" $(jobs -p | tr '\n' ' ') "

# One adopt against this block's own catalogue, in a case directory of its
# own: capabilities writable and newline-terminated, the other two tables
# seeded with a kept row, and one of them, if named, made read-only or a FIFO.
_anl4_seed() {   # case id, table to make odd (stack.tsv | setup.tsv | -), how (ro | fifo | -)
  local d="$_anl4/$1"
  mkdir -p "$d"
  printf 'api\n' > "$d/capabilities"
  printf '%s%s' "$_anl4_SH" "$_anl4_SO" > "$d/stack.tsv"
  printf '%s%s' "$_anl4_UH" "$_anl4_UO" > "$d/setup.tsv"
  case "$3" in
    ro)   chmod 444 "$d/$2" ;;
    fifo) rm -f "$d/$2"; mkfifo "$d/$2" ;;
  esac
}
_anl4_adopt_code='. "$FROOT/harness/lib/adopt.sh"; felix_adopt_capability "$_anl4_d" obs "$_anl4/tpl" acme/widget > "$_anl4_d.out" 2> "$_anl4_d.err"'

# ------------------------------------------------------------ the control ----
# The bounded adopt and apply below, on regular tables, return and write. A
# FIFO case that passes "returned promptly" must be measuring a call that
# would otherwise have written.
_anl4_ctl=""
_anl4_seed ctl-adopt - -; _anl4_d="$_anl4/ctl-adopt"
_anl4_bounded 8 - "$_anl4_adopt_code"; _anl4_rc=$?
[ "$_anl4_rc" = 0 ] && [ "$(cat "$_anl4_d.out")" = "2 1" ] || _anl4_ctl="$_anl4_ctl adopt[rc $_anl4_rc, $(cat "$_anl4_d.out" "$_anl4_d.err" | tr '\n' ' ')]"
mkdir -p "$_anl4/ctl-apply"; printf '%s%s' "$_anl4_SH" "$_anl4_DO" > "$_anl4/ctl-apply/stack.tsv"; _anl4_d="$_anl4/ctl-apply"
_anl4_apply_code='FELIX_MEMORY="$_anl4/mem"; export FELIX_MEMORY
  . "$FROOT/harness/lib/commission.sh"; . "$FROOT/harness/lib/commission-provider.sh"
  felix_commission_apply_declares "$_anl4_d" "$REPO" "$(printf "declare\tplugin\tanl-declared\tlow\tllm\tdeadbeef\tthe fixture\n")" anl-tree anl-policy anl_need > "$_anl4_d.out" 2> "$_anl4_d.err"'
_anl4_bounded 8 - "$_anl4_apply_code"; _anl4_rc=$?
[ "$_anl4_rc" = 0 ] && [ "$(cat "$_anl4_d.out")" = "1" ] || _anl4_ctl="$_anl4_ctl apply[rc $_anl4_rc, $(cat "$_anl4_d.out" "$_anl4_d.err" | tr '\n' ' ')]"
is "the bounded adopt and apply calls of the fourth block write their rows to regular tables (control)" "$_anl4_ctl" ""

# ------------------------------------------------- F: a partial backfill ----
for _anl4_t in stack.tsv setup.tsv; do
  case "$_anl4_t" in stack.tsv) _anl4_w="0 1" ;; setup.tsv) _anl4_w="2 0" ;; esac
  _anl4_seed "f1-${_anl4_t%.tsv}" "$_anl4_t" ro; _anl4_d="$_anl4/f1-${_anl4_t%.tsv}"
  ( eval "$_anl4_adopt_code" ); _anl4_rc=$?
  chmod 644 "$_anl4_d/$_anl4_t"
  _anl4_isr "adopting while a newline-terminated read-only $_anl4_t refuses its rows returns 3 and still prints both counts" \
     "$_anl4_rc[$(cat "$_anl4_d.out")]" "3[$_anl4_w]"
done
_anl4_seed f4-all - -; _anl4_d="$_anl4/f4-all"
( eval "$_anl4_adopt_code" ); _anl4_rc=$?
is "adopting with every row written still returns 0 (control)" "$_anl4_rc[$(cat "$_anl4_d.out")]" "0[2 1]"

# felix adopt, through the CLI on the widget, with the real catalogue:
# observability implies one catalogue row (sentry) and one setup step.
printf 'api\n' > "$_anl4_W/capabilities"
rm -f "$_anl4_W/stack.tsv" "$_anl4_W/setup.tsv"
printf '%s%s' "$_anl4_SH" "$_anl4_SO" > "$_anl4_W/stack.tsv"; chmod 444 "$_anl4_W/stack.tsv"
printf '%s%s' "$_anl4_UH" "$_anl4_UO" > "$_anl4_W/setup.tsv"
( cd "$REPO" && "$FELIX" adopt observability ) > "$_anl4/f2.out" 2> "$_anl4/f2.err"; _anl4_rc=$?
chmod 644 "$_anl4_W/stack.tsv"
_anl4_e="$(cat "$_anl4/f2.err")"
_anl4_isr "felix adopt exits 3 when a row the capability implies could not be written" "$_anl4_rc" "3"
_anl4_ifr "and felix adopt still says it declared the capability when a row could not be written" \
   "stdout [$(tr '\n' ' ' < "$_anl4/f2.out")]" _anl4_has "$(cat "$_anl4/f2.out")" "declared observability"
_anl4_ifr "and felix adopt names the capability, the capabilities file and felix adopt on stderr when a row could not be written" \
   "stderr [$(printf '%s' "$_anl4_e" | tr '\n' ' ')]" \
   eval '_anl4_has "$_anl4_e" observability && _anl4_has "$_anl4_e" "widget/capabilities" && _anl4_has "$_anl4_e" "felix adopt"'

# The session-start hook, run the way the suite runs it, on two invented
# projects whose checkouts grew observability (a sentry dependency) and never
# declared it. One has a read-only stack.tsv, the control does not.
_anl4_hook() {   # project name, stack.tsv mode (ro | -) -> the hook's output in $_anl4/<name>.out
  local p="$1" r="$_anl4/$1-repo"
  mkdir -p "$r" "$FROOT/projects/$p"
  # Own checkout: session-start adopts only in the bound project's own (lib/own.sh, 0.49.286).
  ( _fx_cd "$r" && git init -q -b main && git config remote.origin.url "https://github.com/example.com/$p" )
  printf '%s\n' "$p" > "$r/.felix"
  printf 'sentry-sdk\n' > "$r/requirements.txt"
  printf '{"name":"%s","remote_match":"example.com/%s","gate":"true"}\n' "$p" "$p" > "$FROOT/projects/$p/project.json"
  printf '# %s\n' "$p" > "$FROOT/projects/$p/CLAUDE.md"
  printf '%s%s' "$_anl4_SH" "$_anl4_SO" > "$FROOT/projects/$p/stack.tsv"
  [ "$2" = ro ] && chmod 444 "$FROOT/projects/$p/stack.tsv"
  ( cd "$r" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" ) > "$_anl4/$p.out" 2>&1
  chmod 644 "$FROOT/projects/$p/stack.tsv"
}
_anl4_had_hp=0; { [ -e "$FROOT/projects/anl4hook" ] || [ -e "$FROOT/projects/anl4hookok" ]; } && _anl4_had_hp=1
_anl4_had_hm=0; { [ -e "$MEM/anl4hook" ] || [ -e "$MEM/anl4hookok" ]; } && _anl4_had_hm=1
_anl4_hook anl4hook ro
_anl4_hook anl4hookok -
_anl4_o="$(cat "$_anl4/anl4hook.out")"
_anl4_ifr "the session-start hook says a capability it adopted could not write every row, naming stack.tsv" \
   "output [$(printf '%s' "$_anl4_o" | tr '\n' ' ' | cut -c1-1500)]" \
   eval '_anl4_has "$_anl4_o" observability && _anl4_has "$_anl4_o" stack.tsv'
_anl4_o="$(cat "$_anl4/anl4hookok.out")"
_anl4_if "and the session-start hook names no unwritten table when every row was written (control)" \
   "output [$(printf '%s' "$_anl4_o" | tr '\n' ' ' | cut -c1-1500)]" \
   eval '_anl4_has "$_anl4_o" "observability(" && ! _anl4_has "$_anl4_o" stack.tsv && ! _anl4_has "$_anl4_o" setup.tsv'

# ----------------------------------------------------- G: a FIFO at a table ----
for _anl4_t in stack.tsv setup.tsv; do
  case "$_anl4_t" in
    stack.tsv) _anl4_w="0 1"; _anl4_kind="stack row"
               _anl4_other="$(_anl4_want '%s%s%s' "$_anl4_UH" "$_anl4_UO" "$_anl4_UR")"; _anl4_ot=setup.tsv; _anl4_owhat="the setup step" ;;
    setup.tsv) _anl4_w="2 0"; _anl4_kind="setup step"
               _anl4_other="$(_anl4_want '%s%s%s' "$_anl4_SH" "$_anl4_SO" "$_anl4_SR")"; _anl4_ot=stack.tsv; _anl4_owhat="the stack rows" ;;
  esac
  _anl4_seed "g-${_anl4_t%.tsv}" "$_anl4_t" fifo; _anl4_d="$_anl4/g-${_anl4_t%.tsv}"
  _anl4_bounded 8 "$_anl4_d/$_anl4_t" "$_anl4_adopt_code"; _anl4_rc=$?
  _anl4_if "adopting with a FIFO at $_anl4_t returns promptly and counts no $_anl4_kind" \
     "$( [ "$_anl4_rc" = 124 ] && echo 'still blocked at the 8 s deadline' || echo "returned $_anl4_rc, counts [$(cat "$_anl4_d.out")], FIFO $( [ -p "$_anl4_d/$_anl4_t" ] && echo kept || echo REPLACED)")" \
     eval '[ "$_anl4_rc" != 124 ] && [ "$(cat "$_anl4_d.out")" = "$_anl4_w" ] && [ -p "$_anl4_d/$_anl4_t" ]'
  is "and adopting with a FIFO at $_anl4_t still records the capability and writes $_anl4_owhat" \
     "$(_anl4_bytes "$_anl4_d/capabilities") | $(_anl4_bytes "$_anl4_d/$_anl4_ot")" "$(_anl4_want 'api\nobs\n') | $_anl4_other"
done
mkdir -p "$_anl4/g-apply"; mkfifo "$_anl4/g-apply/stack.tsv"; _anl4_d="$_anl4/g-apply"
_anl4_bounded 8 "$_anl4_d/stack.tsv" "$_anl4_apply_code"; _anl4_rc=$?
_anl4_if "commissioning's apply with a FIFO at stack.tsv returns promptly and counts no declare" \
   "$( [ "$_anl4_rc" = 124 ] && echo 'still blocked at the 8 s deadline' || echo "returned $_anl4_rc, count [$(cat "$_anl4_d.out")], FIFO $( [ -p "$_anl4_d/stack.tsv" ] && echo kept || echo REPLACED)")" \
   eval '[ "$_anl4_rc" != 124 ] && [ "$(cat "$_anl4_d.out")" = "0" ] && [ -p "$_anl4_d/stack.tsv" ]'

# ------------------------------------------ H: a mistake on an unborn HEAD ----
mkdir -p "$_anl4/h-unborn" "$_anl4/h-born"
( _fx_cd "$_anl4/h-unborn" && git init -q -b main )
( _fx_cd "$_anl4/h-born" && git init -q -b main && printf 'x\n' > x && git add -A \
  && git -c user.name=anl4 -c user.email=anl4@example.invalid -c commit.gpgsign=false commit -qm anl4 )
_anl4_mshape() {   # case id, checkout -> lines|fields of the first line|fourth field
  ( FELIX_MEMORY="$_anl4/mem"; export FELIX_MEMORY
    . "$FROOT/harness/lib/memory.sh"; felix_mem_mistake "$_anl4/$1" "$2" anl-lint ) >/dev/null 2>&1
  awk -F'\t' 'NR == 1 { nf = NF; f4 = $4 } END { printf "%s|%s|%s", NR, nf, f4 }' "$_anl4/mem/$1/mistakes.log" 2>/dev/null
}
is "felix_mem_mistake on a checkout with no commit writes one line of six fields, the fourth what it was given" \
   "$(_anl4_mshape h-u "$_anl4/h-unborn")" "1|6|anl-lint"
is "and felix_mem_mistake on a checkout with a commit writes the same shape (control)" \
   "$(_anl4_mshape h-b "$_anl4/h-born")" "1|6|anl-lint"

# ------------------------------------------------------------- the restore ----
_anl4_i=0
for _f in $_anl4_wfiles; do
  _anl4_i=$((_anl4_i + 1))
  rm -f "$_f"
  [ -e "$_anl4/keep.$_anl4_i" ] && cp -p "$_anl4/keep.$_anl4_i" "$_f"
done
rm -rf "$_anl4_W/setup"
[ "$_anl4_had_setup" -eq 1 ] && cp -Rp "$_anl4/keep.setup" "$_anl4_W/setup"
[ "$_anl4_had_hp" -eq 1 ] || rm -rf "$FROOT/projects/anl4hook" "$FROOT/projects/anl4hookok"
[ "$_anl4_had_hm" -eq 1 ] || rm -rf "$MEM/anl4hook" "$MEM/anl4hookok"
_anl4_back=""
_anl4_i=0
for _f in $_anl4_wfiles; do
  _anl4_i=$((_anl4_i + 1))
  if [ -e "$_anl4/keep.$_anl4_i" ]; then cmp -s "$_f" "$_anl4/keep.$_anl4_i" || _anl4_back="$_anl4_back $_f"
  else [ ! -e "$_f" ] || _anl4_back="$_anl4_back $_f"; fi
done
[ "$(_anl4_modes)" = "$_anl4_modes_was" ] || _anl4_back="$_anl4_back modes[$(_anl4_modes | tr '\n' ' ')]"
if [ "$_anl4_had_setup" -eq 1 ]; then diff -r "$_anl4_W/setup" "$_anl4/keep.setup" >/dev/null 2>&1 || _anl4_back="$_anl4_back setup/"
else [ ! -e "$_anl4_W/setup" ] || _anl4_back="$_anl4_back setup/"; fi
{ [ "$_anl4_had_hp" -eq 1 ] || { [ ! -e "$FROOT/projects/anl4hook" ] && [ ! -e "$FROOT/projects/anl4hookok" ]; }; } \
  || _anl4_back="$_anl4_back projects/anl4hook*"
{ [ "$_anl4_had_hm" -eq 1 ] || { [ ! -e "$MEM/anl4hook" ] && [ ! -e "$MEM/anl4hookok" ]; }; } \
  || _anl4_back="$_anl4_back memory/anl4hook*"
_anl4_locked="$(find "$_anl4" -path '*/.git' -prune -o -type f ! -perm -600 -print 2>/dev/null)"
[ -z "$_anl4_locked" ] || _anl4_back="$_anl4_back still-locked[$(printf '%s' "$_anl4_locked" | tr '\n' ' ')]"
for _anl4_j in $(jobs -p); do
  case "$_anl4_jobs_was" in *" $_anl4_j "*) ;; *) _anl4_back="$_anl4_back background-job[$_anl4_j]" ;; esac
done
is "and the widget files, the invented hook projects and every mode the fourth block changed are back as they were" "$_anl4_back" ""

# A checkout whose path holds a space. The probes globbed $root/$p with the
# root unquoted, so at the default IFS the path split into words and every one
# missed: session-start, the gate, commission and doctor all saw a checkout
# with no ci, no deploy and no tests. Only a tab IFS found what was there. The
# fixture reaches both probe loops through a glob, so quoting the pattern along
# with the root fails here too. Run from the fixture's parent, where nothing
# can match the manifest loop's own globs.
DSP="$TMP/detect space/repo"
mkdir -p "$DSP/tests" "$DSP/.github/workflows" "$DSP/requirements"
printf 'FROM scratch\n' > "$DSP/Dockerfile"
printf 'on: push\n'     > "$DSP/.github/workflows/ci.yml"
printf 'sentry-sdk\n'   > "$DSP/requirements.txt"
printf 'stripe\n'       > "$DSP/requirements/prod.txt"
: > "$DSP/.env.example"
is "felix_detect in a checkout whose path holds a space reports the capabilities its files show" \
   "$(cd "$TMP/detect space" && IFS=$' \t\n'; . "$FROOT/harness/lib/detect.sh"
      felix_detect "$DSP" | sort -u | tr '\n' ' ')" \
   "billing ci deploy observability secrets tests "
rm -rf "$TMP/detect space"

# Run from a directory that holds manifests of its own, as felix doctor is from
# a service folder of a monorepo. The manifest loop listed requirements/*.txt
# and *.csproj bare, so the shell expanded them against the current directory
# before joining them to the root: from here, the probe looked for the root's
# requirements/dev.txt, which does not exist, and never read its prod.txt,
# which names stripe. Each probe runs from a directory whose file names
# playwright, so a probe that read the current directory instead says e2e.
DCW="$TMP/detect-cwd"
mkdir -p "$DCW/req/requirements" "$DCW/cs" "$DCW/here/requirements"
printf 'stripe\n'     > "$DCW/req/requirements/prod.txt"
printf '<PackageReference Include="Sentry" />\n' > "$DCW/cs/App.csproj"
printf 'playwright\n' > "$DCW/here/requirements/dev.txt"
printf 'playwright\n' > "$DCW/here/Tool.csproj"
is "felix_detect run from a directory that holds its own requirements/*.txt still reports billing for a root whose requirements/prod.txt names stripe" \
   "$(cd "$DCW/here" && . "$FROOT/harness/lib/detect.sh" && felix_detect "$DCW/req" | sort -u | tr '\n' ' ')" \
   "billing "
is "and run from one that holds its own *.csproj, still reports observability for a root whose App.csproj names Sentry" \
   "$(cd "$DCW/here" && . "$FROOT/harness/lib/detect.sh" && felix_detect "$DCW/cs" | sort -u | tr '\n' ' ')" \
   "observability "
rm -rf "$DCW"

printf '\nrival gates\n'
# From a real failure. An untracked, day-stale, strictly weaker copy of the gate
# sat inside the governed repo, and it was the file physically in front of any
# session that looked around. A session ran it all day and reported green from a
# gate missing a check. A gate with a lookalike is not a gate; it is a coin flip
# on which file somebody reaches for, and the wrong side reports success.
out="$(cd "$REPO" && "$FELIX" doctor 2>&1)"
case "$out" in
  *rival*) bad "a clean checkout claims no rival gate" "$out" ;;
  *)       ok  "a clean checkout claims no rival gate" ;;
esac

mkdir -p "$REPO/scripts"
printf '#!/bin/sh\npass format\npass lint\n' > "$REPO/scripts/gate.sh"
chmod +x "$REPO/scripts/gate.sh"
out="$(cd "$REPO" && "$FELIX" doctor 2>&1)"
has "a lookalike gate is reported"   "$out" "scripts/gate.sh"
has "and whether git tracks it"      "$out" "untracked"

# Not executable is not a gate. Without this the check flags every README that
# happens to have the word in its name.
printf '#!/bin/sh\n' > "$REPO/scripts/verify-notes.sh"
out="$(cd "$REPO" && "$FELIX" doctor 2>&1)"
case "$out" in
  *verify-notes*) bad "a non-executable lookalike is ignored" "$out" ;;
  *)              ok  "a non-executable lookalike is ignored" ;;
esac

out="$(cd "$REPO" && "$FELIX" doctor 2>&1)"; rc=$?
is "reporting a rival gate still exits 0" "$rc" "0"

# Matching on the name gate|verify|check missed the second instance of the same
# trap the day the first was deleted: prepush.sh, an untracked repo copy of a
# file Felix holds, identical that morning and free to drift by the afternoon.
# The name was never the point. Felix holding the authoritative copy is.
printf '#!/bin/sh\necho felix copy\n' > "$FROOT/projects/widget/prepush.sh"
chmod +x "$FROOT/projects/widget/prepush.sh"
printf '#!/bin/sh\necho repo copy\n' > "$REPO/scripts/prepush.sh"
chmod +x "$REPO/scripts/prepush.sh"
out="$(cd "$REPO" && "$FELIX" doctor 2>&1)"
has "a repo copy of a file Felix holds is reported" "$out" "prepush.sh"

# ...and a name Felix does not hold is still nobody's business.
printf '#!/bin/sh\n' > "$REPO/scripts/deploy-thing.sh"
chmod +x "$REPO/scripts/deploy-thing.sh"
out="$(cd "$REPO" && "$FELIX" doctor 2>&1)"
case "$out" in
  *deploy-thing*) bad "an unrelated executable is left alone" "$out" ;;
  *)              ok  "an unrelated executable is left alone" ;;
esac
rm -f "$FROOT/projects/widget/prepush.sh"
rm -rf "$REPO/scripts"

# Felix's own per-project storage, seen from a worktree of Felix.
#
# The guard for that storage was a path-prefix test — "does this file live under
# $FELIX_HOME_DIR/projects/" — and in a worktree it never matches, because the
# root is the worktree and the home is still the main checkout. So `felix doctor`
# reported every governed project's stored gate as a rival gate, under a banner
# saying whichever one a session reaches for decides what green means. It also
# called `projects/another/gate.sh` "differs from the copy Felix holds", having
# compared it against `projects/felix/gate.sh` on the strength of a shared
# basename, while it was byte-identical to the copy Felix actually holds for
# another governed project. A tool whose job is finding drift, inventing drift.
#
# The fix is an identity test on the repository rather than on the path string:
# a worktree and its main checkout share one `--git-common-dir`, so "is this
# checkout Felix" survives being somewhere else. Worktrees are how work happens
# here — issue #2 records that `felix merge` is unreachable from one — so a
# guard that silently lapses there is a guard for the case that does not arise.
RH="$TMP/felixhome"; mkdir -p "$RH/projects/p1" "$RH/projects/p2"
( _fx_cd "$RH" && git init -q -b main )
RH="$(cd "$RH" && pwd -P)"
printf '#!/bin/sh\necho p1\n' > "$RH/projects/p1/gate.sh"
printf '#!/bin/sh\necho p2\n' > "$RH/projects/p2/gate.sh"
chmod +x "$RH/projects/p1/gate.sh" "$RH/projects/p2/gate.sh"
printf '{"name":"p1","gate":"gate.sh"}\n' > "$RH/projects/p1/project.json"
( _fx_cd "$RH" && git add -A >/dev/null 2>&1 \
  && git -c user.name=t -c user.email=t@t commit -qm home >/dev/null 2>&1 )
RW="$TMP/felixwork"
( _fx_cd "$RH" && git worktree add -q -b wt "$RW" >/dev/null 2>&1 )
RW="$(cd "$RW" && pwd -P)"

_riv() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
           FELIX_HOME_DIR="$RH" _felix_rival_gates "$1" "$RH/projects/p1" "gate.sh" ); }

case "$(_riv "$RH")" in
  *projects/p2/gate.sh*) bad "the main checkout knows its own storage is not a rival" "$(_riv "$RH")" ;;
  *)                     ok  "the main checkout knows its own storage is not a rival" ;;
esac
case "$(_riv "$RW")" in
  *projects/p2/gate.sh*) bad "and so does a worktree of it" "$(_riv "$RW")" ;;
  *)                     ok  "and so does a worktree of it" ;;
esac
# The guard must stay narrow: a genuinely unrelated repo that happens to have a
# projects/ directory is not Felix, and its lookalikes are still reported.
OTHER="$TMP/notfelix"; mkdir -p "$OTHER/projects/p2"
( _fx_cd "$OTHER" && git init -q -b main )
OTHER="$(cd "$OTHER" && pwd -P)"
printf '#!/bin/sh\necho other\n' > "$OTHER/projects/p2/gate.sh"
chmod +x "$OTHER/projects/p2/gate.sh"
( _fx_cd "$OTHER" && git add -A >/dev/null 2>&1 \
  && git -c user.name=t -c user.email=t@t commit -qm other >/dev/null 2>&1 )
has "a different repository is still checked" "$(_riv "$OTHER")" "projects/p2/gate.sh"

# The assertions below shell out to `claude plugin list` and `claude mcp list`.
# The latter performs live health checks, so they are network-dependent and can
# flake: one spurious failure was observed in a run that passed three times
# either side. Resolution, detection, classification and pipefail safety are all
# offline and deterministic. Only presence checks against real installs are not,
# so a lone failure here is worth re-running before believing.
printf '\nthe hook adopts rather than nags\n'
# A surface detected and left undeclared stays unhandled for as long as nobody
# reads the message. The hook closes that itself.
_hookproj_build   # tests/lib/cm-stub.sh: the project, its checkout, and the hook run in a bare repo and again after a requirements.txt (HOOKREPO, _hook_out1, _hook_out2)

case "$_hook_out1" in
  *Adopted*) bad "a bare repo has nothing to adopt" "$_hook_out1" ;;
  *) ok "a bare repo has nothing to adopt" ;;
esac

has "the hook announces what it adopted" "$_hook_out2" "Adopted automatically"
has "and names the capability"           "$_hook_out2" "observability"
has "and says nothing was installed"     "$_hook_out2" "Nothing was installed"

# Talking is not the same as doing. The manifests must actually have changed.
grep -qxF observability "$FROOT/projects/hookproj/capabilities" 2>/dev/null \
  && ok "it recorded the capability" || bad "it recorded the capability"
[ -f "$FROOT/projects/hookproj/setup/sentry.md" ] \
  && ok "it copied the runbook the capability implies" \
  || bad "it copied the runbook the capability implies"
grep -q sentry "$FROOT/projects/hookproj/stack.tsv" 2>/dev/null \
  && ok "it appended the tooling row" || bad "it appended the tooling row"

out="$(cd "$HOOKREPO" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
case "$out" in
  *Adopted*) bad "it goes quiet once nothing is new" "$out" ;;
  *) ok "it goes quiet once nothing is new" ;;
esac

