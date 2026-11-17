# -------------------------------------------------------------- the hook
# A checkout the hook would adopt observability for, first as a control with
# no capabilities list, then over a link whose target is gone and over a pipe.
# The widget's four adopt paths are set aside as 0020's felix adopt block left them.
_adopt_refusals_widget
_adrhr="$TMP/_adr/hookrepo"; mkdir -p "$_adrhr"
# Adoption at session start runs only in the project's own checkout (lib/own.sh, 0.49.286), so this fixture's checkout is adrhook's own: its remote_match names its origin.
( _fx_cd "$_adrhr" && git init -q -b main && git config remote.origin.url https://github.com/example.com/adrhook )
printf 'adrhook\n' > "$_adrhr/.felix"; printf 'sentry-sdk\n' > "$_adrhr/requirements.txt"
_adrhp="$FROOT/projects/adrhook"; mkdir -p "$_adrhp" "$MEM/adrhook"
printf '{"name":"adrhook","remote_match":"example.com/adrhook","gate":"true"}\n' > "$_adrhp/project.json"
printf '# h\n' > "$_adrhp/CLAUDE.md"
_adrhook() { cd "$_adrhr" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start"; }
_adrhclear() {
  local x
  for x in capabilities stack.tsv setup.tsv setup; do
    [ -p "$_adrhp/$x" ] && : <> "$_adrhp/$x"
    rm -rf "$_adrhp/$x"
  done
}
_adrhgo() {
  mkdir -p "$1/root"
  _adrsnap "$_adrhp/stack.tsv" "$_adrhp/setup.tsv" "$_adrhp/setup" "$1/root" > "$1/snap0"
  _adrrun "$1" $((_adrwait * 2)) _adrhook
  _adrsnap "$_adrhp/stack.tsv" "$_adrhp/setup.tsv" "$_adrhp/setup" "$1/root" > "$1/snap1"
}

_adrd="$TMP/_adr/g0"; mkdir -p "$_adrd"
_adrhgo "$_adrd"
_adrif "$_adrd" "the hook adopts observability for a sentry-sdk checkout whose project lists nothing" \
  "[$(_adrcat "$_adrd/out" "$_adrd/err")]" _adrtold "$_adrd" "Adopted automatically"
_adrhclear

_adrd="$TMP/_adr/g1"; mkdir -p "$_adrd/root/there"
ln -s "$_adrd/root/there/capabilities" "$_adrhp/capabilities"
_adrhgo "$_adrd"
_adrl="the hook over a capabilities link whose target is gone"
_adrif "$_adrd" "$_adrl finishes" "" true
_adrif "$_adrd" "$_adrl does not say Adopted automatically" "[$(_adrcat "$_adrd/out" "$_adrd/err")]" \
  eval '! _adrtold "$_adrd" "Adopted automatically"'
_adrif "$_adrd" "$_adrl creates nothing at the target and leaves the link pointing there" \
  "$(ls -l "$_adrhp/capabilities" "$_adrd/root/there" 2>&1)" \
  eval '_adrnone "$_adrd/root/there/capabilities" && _adrto "$_adrhp/capabilities" "$_adrd/root/there/capabilities"'
_adrif "$_adrd" "$_adrl creates no stack.tsv, setup.tsv or setup directory" "$(_adrdiff "$_adrd")" _adrsame "$_adrd"
_adrhclear

_adrd="$TMP/_adr/g2"; mkdir -p "$_adrd"
printf '# kind\tname\tsource\trisk\tcapability\tgrounding\n' > "$_adrhp/stack.tsv"
printf '# id\ttitle\tcapability\tcheck\nkept\tA step already here\tbilling\ttrue\n' > "$_adrhp/setup.tsv"
mkdir -p "$_adrhp/setup"; printf 'kept\n' > "$_adrhp/setup/kept.md"
mkfifo "$_adrhp/capabilities"
_adrhgo "$_adrd"
_adrl="the hook over a capabilities pipe"
_adrif "$_adrd" "$_adrl finishes without waiting on it" "" true
_adrif "$_adrd" "$_adrl does not say Adopted automatically" "[$(_adrcat "$_adrd/out" "$_adrd/err")]" \
  eval '! _adrtold "$_adrd" "Adopted automatically"'
_adrif "$_adrd" "$_adrl leaves it a pipe" "$(ls -l "$_adrhp/capabilities" 2>&1)" \
  eval '[ -p "$_adrhp/capabilities" ] && [ ! -L "$_adrhp/capabilities" ]'
_adrif "$_adrd" "$_adrl leaves stack.tsv, setup.tsv and the setup directory byte for byte" "$(_adrdiff "$_adrd")" _adrsame "$_adrd"
_adrhclear

# After review, not blind (2026-10-01): a list the hook can read and adopt
# cannot write. The undeclared surface is read, adopt refuses with 2, and the
# hook said nothing at all about it, every session.
_adrl="the hook over a read-only capabilities list"
if [ "$_adrroot" = 1 ]; then
  for _adrx in "does not say Adopted automatically" "says observability was not adopted because the list could not be written" \
               "writes nothing and keeps the list"; do
    skip "$_adrl $_adrx" "root writes a mode 444 file"
  done
else
  _adrd="$TMP/_adr/g3"; mkdir -p "$_adrd"
  printf 'ci\n' > "$_adrd/caps.kept"; cp "$_adrd/caps.kept" "$_adrhp/capabilities"; chmod 444 "$_adrhp/capabilities"
  _adrhgo "$_adrd"
  _adrif "$_adrd" "$_adrl does not say Adopted automatically" "[$(_adrcat "$_adrd/out" "$_adrd/err")]" \
    eval '! _adrtold "$_adrd" "Adopted automatically"'
  _adrif "$_adrd" "$_adrl says observability was not adopted because the list could not be written" \
    "[$(_adrcat "$_adrd/out" "$_adrd/err")]" \
    eval '_adrtold "$_adrd" "Not adopted" && _adrtold "$_adrd" "could not be read or written: observability"'
  _adrif "$_adrd" "$_adrl writes nothing and keeps the list" "$(_adrdiff "$_adrd")" \
    eval '_adrsame "$_adrd" && _adrmodebytes "$_adrhp/capabilities" -r--r--r-- "$_adrd/caps.kept"'
  chmod 644 "$_adrhp/capabilities"
fi
_adrhclear

# Everything back as found: widget's four paths, and nothing of this block left.
_adrclear
for _adrx in capabilities stack.tsv setup.tsv setup; do
  if [ -e "$_adrk/$_adrx" ] || [ -L "$_adrk/$_adrx" ]; then mv "$_adrk/$_adrx" "$_adrw/$_adrx"; fi
done
find "$TMP/_adr" -type p 2>/dev/null | while IFS= read -r _adrx; do : <> "$_adrx"; done
rm -rf "$TMP/_adr" "$_adrhp" "$MEM/adrhook"

printf '\nappends onto a hand-written last line\n'
# Written blind on 2026-10-01, from the contract below alone, by an author who
# had not read the fix. Red against origin/main: 17 of 44. Each of ten mutants
# of the fix fails only the assertions of the writer it breaks.
# A table a person may hand-edit can end without a newline: `api` typed into
# capabilities and saved. A writer that appends with `printf '...\n' >> F`
# then fuses its row onto that line, `apiobs`, and both rows are lost to every
# reader. Measured on macOS 2026-10-01. The contract, per writer and table:
#   C1  last byte not a newline: OLD, then "\n", then the row and its "\n".
#   C2  last byte a newline: OLD, then the row. No blank line.
#   C3  last byte a NUL: not a newline, so C1. A command substitution drops a
#       trailing NUL the way it drops a newline, which is how a fix that reads
#       the last byte with $(tail -c 1) misses it.
#   C4  absent or empty: what the writer did before, header or no header.
# C2 and C4 are here for the fix, not for main: a writer that always writes a
# newline first passes C1 and C3 and fails these.
#
# Bytes are compared through od, so a trailing newline or a NUL is visible in a
# failure. Rows carrying a clock are compared with every digit after the old
# bytes squeezed to one 9: the old bytes stay exact, the row's shape is exact,
# and the time is the only thing left unpinned.
_anl="$TMP/anl"; mkdir -p "$_anl/bin"
_anl_od()    { od -An -c | tr '\n' ' ' | tr -s ' '; }
_anl_bytes() { if [ -e "$1" ]; then _anl_od < "$1"; else printf 'absent'; fi; }
_anl_want()  { printf "$@" | _anl_od; }
_anl_norm()  {   # file, length of the old bytes -> od, digits after them squeezed to 9
  [ -e "$1" ] || { printf 'absent'; return 0; }
  # macOS head refuses a count of 0, so a table with no old bytes skips it.
  { [ "$2" -eq 0 ] || head -c "$2" "$1"; tail -c +"$(($2 + 1))" "$1" | tr -s '0-9' '9'; } | _anl_od
}

# ------------------------------------------------ felix_adopt_capability ----
# One call writes three tables: capabilities, stack.tsv and setup.tsv. Each
# scenario seeds all three the same way, so each table is judged on its own.
mkdir -p "$_anl/tpl"
printf '# kind\tname\tsource\trisk\tcapability\tkeywords\nplugin\tanl-obs-a\t-\tlow\tobs\tobs tracing\nmcp\tanl-obs-b\thttps://example.invalid/mcp\tmedium\tobs\tobs\nplugin\tanl-elsewhere\t-\tlow\tother\tother\n' \
  > "$_anl/tpl/catalog.tsv"
printf '# id\ttitle\tcapability\tcheck\nanl-step\tWire the obs thing\tobs\tgh api repos/{{REPO}}/hooks\nanl-skip\tNot this one\tother\ttrue\n' \
  > "$_anl/tpl/setup.tsv"
_anl_SH=$'# kind\tname\tsource\trisk\tcapability\tgrounding\n'
_anl_UH=$'# id\ttitle\tcapability\tcheck\n'
_anl_SO=$'plugin\tanl-kept\t-\tlow\tapi\tDECLARED'
_anl_UO=$'anl-kept-step\tKept by hand\tapi\ttrue'
_anl_SR=$'plugin\tanl-obs-a\t-\tlow\tobs\tDECLARED\nmcp\tanl-obs-b\thttps://example.invalid/mcp\tmedium\tobs\tDECLARED\n'
_anl_UR=$'anl-step\tWire the obs thing\tobs\tgh api repos/{{REPO}}/hooks\n'
_anl_adopt() {   # dir, last-byte (nl | none | nul), or absent | empty
  local d="$_anl/$1" end=""
  mkdir -p "$d"
  case "$2" in
    absent) ;;
    empty)  : > "$d/capabilities"; : > "$d/stack.tsv"; : > "$d/setup.tsv" ;;
    *)      case "$2" in nl) end='\n' ;; nul) end='\0' ;; esac
            printf "api$end" > "$d/capabilities"
            printf '%s%s'"$end" "$_anl_SH" "$_anl_SO" > "$d/stack.tsv"
            printf '%s%s'"$end" "$_anl_UH" "$_anl_UO" > "$d/setup.tsv" ;;
  esac
  ( . "$FROOT/harness/lib/adopt.sh"; felix_adopt_capability "$d" obs "$_anl/tpl" acme/widget ) >/dev/null 2>&1
}
_anl_adopt adopt-c1 none
_anl_adopt adopt-c2 nl
_anl_adopt adopt-c3 nul
_anl_adopt adopt-c4a absent
_anl_adopt adopt-c4e empty

is "adopting onto a capabilities list with no final newline keeps its last line and writes its own" \
   "$(_anl_bytes "$_anl/adopt-c1/capabilities")" "$(_anl_want 'api\nobs\n')"
is "adopting onto a capabilities list ending in a newline adds the capability with no blank line" \
   "$(_anl_bytes "$_anl/adopt-c2/capabilities")" "$(_anl_want 'api\nobs\n')"
is "adopting onto a capabilities list ending in a NUL byte writes a newline after the NUL first" \
   "$(_anl_bytes "$_anl/adopt-c3/capabilities")" "$(_anl_want 'api\0\nobs\n')"
is "adopting with no capabilities list writes the capability alone" \
   "$(_anl_bytes "$_anl/adopt-c4a/capabilities")" "$(_anl_want 'obs\n')"
is "adopting onto an empty capabilities list writes the capability alone" \
   "$(_anl_bytes "$_anl/adopt-c4e/capabilities")" "$(_anl_want 'obs\n')"
is "and after adopting onto an unterminated list felix_declared lists both the hand-written capability and the adopted one" \
   "$( . "$FROOT/harness/lib/detect.sh"; felix_declared "$_anl/adopt-c1" 2>&1 )" "$(printf 'api\nobs')"

is "adopting onto a stack.tsv with no final newline keeps its last row and puts each catalogue row on its own line" \
   "$(_anl_bytes "$_anl/adopt-c1/stack.tsv")" "$(_anl_want '%s%s\n%s' "$_anl_SH" "$_anl_SO" "$_anl_SR")"
is "adopting onto a stack.tsv ending in a newline appends its catalogue rows with no blank line" \
   "$(_anl_bytes "$_anl/adopt-c2/stack.tsv")" "$(_anl_want '%s%s\n%s' "$_anl_SH" "$_anl_SO" "$_anl_SR")"
is "adopting onto a stack.tsv ending in a NUL byte writes a newline after the NUL before its catalogue rows" \
   "$(_anl_bytes "$_anl/adopt-c3/stack.tsv")" "$(_anl_want '%s%s\0\n%s' "$_anl_SH" "$_anl_SO" "$_anl_SR")"
is "adopting with no stack.tsv seeds the header and then its catalogue rows" \
   "$(_anl_bytes "$_anl/adopt-c4a/stack.tsv")" "$(_anl_want '%s%s' "$_anl_SH" "$_anl_SR")"
is "adopting onto an empty stack.tsv writes its catalogue rows and no header" \
   "$(_anl_bytes "$_anl/adopt-c4e/stack.tsv")" "$(_anl_want '%s' "$_anl_SR")"

is "adopting onto a setup.tsv with no final newline keeps its last step and puts the new step on its own line" \
   "$(_anl_bytes "$_anl/adopt-c1/setup.tsv")" "$(_anl_want '%s%s\n%s' "$_anl_UH" "$_anl_UO" "$_anl_UR")"
is "adopting onto a setup.tsv ending in a newline appends the step with no blank line" \
   "$(_anl_bytes "$_anl/adopt-c2/setup.tsv")" "$(_anl_want '%s%s\n%s' "$_anl_UH" "$_anl_UO" "$_anl_UR")"
is "adopting onto a setup.tsv ending in a NUL byte writes a newline after the NUL before the step" \
   "$(_anl_bytes "$_anl/adopt-c3/setup.tsv")" "$(_anl_want '%s%s\0\n%s' "$_anl_UH" "$_anl_UO" "$_anl_UR")"
is "adopting with no setup.tsv seeds the header and then the step" \
   "$(_anl_bytes "$_anl/adopt-c4a/setup.tsv")" "$(_anl_want '%s%s' "$_anl_UH" "$_anl_UR")"
is "adopting onto an empty setup.tsv writes the step and no header" \
   "$(_anl_bytes "$_anl/adopt-c4e/setup.tsv")" "$(_anl_want '%s' "$_anl_UR")"

# ------------------------------------------------- felix autonomy --allow ----
# Through the CLI, on the widget fixture, whose autonomy file is saved here and
# put back below exactly as it was, absent included. The hand-written line is
# `commission` and the grant typed is tidy, so no stamp file is written.
_anl_W="$FROOT/projects/widget"
rm -f "$_anl/autonomy.keep"
[ -e "$_anl_W/autonomy" ] && cp -p "$_anl_W/autonomy" "$_anl/autonomy.keep"
_anl_allow() {   # what to seed (none | nl | nul | absent | empty) -> the CLI's output
  rm -f "$_anl_W/autonomy"
  case "$1" in
    none)  printf 'commission'   > "$_anl_W/autonomy" ;;
    nl)    printf 'commission\n' > "$_anl_W/autonomy" ;;
    nul)   printf 'commission\0' > "$_anl_W/autonomy" ;;
    empty) : > "$_anl_W/autonomy" ;;
  esac
  ( cd "$REPO" && "$FELIX" autonomy --allow tidy 2>&1 )
}
_anl_nl='
'
_anl_aut_is() {   # name, cli output, expected bytes
  # `already allowed: tidy` is the CLI declining to write, so the line is
  # matched whole: a run that never reached the append measured the fixture.
  case "$_anl_nl$2$_anl_nl" in
    *"${_anl_nl}allowed: tidy${_anl_nl}"*) is "$1" "$(_anl_bytes "$_anl_W/autonomy")" "$3" ;;
    *) bad "$1" "the CLI never granted tidy, so this measured the fixture: $(printf '%s' "$2" | head -3 | tr '\n' ' ')" ;;
  esac
}
_anl_out="$(_anl_allow none)"
_anl_aut_is "felix autonomy --allow onto a hand-written grant with no final newline keeps that grant on its own line" \
   "$_anl_out" "$(_anl_want 'commission\ntidy\n')"
is "and both the hand-written grant and the typed one then hold" \
   "$( . "$FROOT/harness/lib/autonomy.sh"
       felix_autonomy_allows "$_anl_W" commission && echo commission
       felix_autonomy_allows "$_anl_W" tidy && echo tidy )" "$(printf 'commission\ntidy')"
_anl_out="$(_anl_allow nl)"
_anl_aut_is "felix autonomy --allow onto a grant ending in a newline adds no blank line" \
   "$_anl_out" "$(_anl_want 'commission\ntidy\n')"
_anl_out="$(_anl_allow nul)"
# Amended 2026-10-08 at the merge into claude/autonomy-writer-lock, which
# carries the allow fix: this engine reads no grant from a file holding a NUL
# byte, so a tidy added after one would not hold, and "allowed: tidy" over it
# is the defect that fix closes. The grant is refused, says why, and the file
# keeps every byte.
case "$_anl_nl$_anl_out$_anl_nl" in
  *"${_anl_nl}allowed: tidy${_anl_nl}"*) _anl_said=said ;;
  *"tidy is not allowed"*"NUL byte"*) _anl_said=refused ;;
  *) _anl_said=other ;;
esac
is "felix autonomy --allow onto a grant ending in a NUL byte is refused, names the NUL byte, says no allowed:, and leaves the file byte-identical" \
   "$_anl_said:$(_anl_bytes "$_anl_W/autonomy")" "refused:$(_anl_want 'commission\0')"
_anl_out="$(_anl_allow absent)"
_anl_aut_is "felix autonomy --allow with no autonomy file still seeds its comment line before the grant" \
   "$_anl_out" "$(_anl_want '# What Felix may do here unattended.\ntidy\n')"
_anl_out="$(_anl_allow empty)"
_anl_aut_is "felix autonomy --allow onto an empty autonomy file writes the grant alone" \
   "$_anl_out" "$(_anl_want 'tidy\n')"
rm -f "$_anl_W/autonomy"
[ -e "$_anl/autonomy.keep" ] && cp -p "$_anl/autonomy.keep" "$_anl_W/autonomy"

# ------------------------------------------------- felix discover --adopt ----
# Through the CLI, on the widget fixture: a discovery cache stamped the way the
# engine stamps it, holding one low candidate, and a claude stub that logs what
# it was asked and refuses the install, so the run declares and installs
# nothing. stack.tsv and the cache are saved and put back below, absent
# included, and so is the cache's directory if this block made it.
_anl_cache="$FROOT/state/discover/widget.tsv"
rm -f "$_anl/stack.keep" "$_anl/cache.keep"
[ -e "$_anl_W/stack.tsv" ] && cp -p "$_anl_W/stack.tsv" "$_anl/stack.keep"
[ -e "$_anl_cache" ] && cp -p "$_anl_cache" "$_anl/cache.keep"
_anl_had_state=0; [ -d "$FROOT/state" ] && _anl_had_state=1
_anl_had_disc=0;  [ -d "$FROOT/state/discover" ] && _anl_had_disc=1
mkdir -p "$FROOT/state/discover"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/claude.log"\nexit 1\n' "$_anl" > "$_anl/bin/claude"
chmod +x "$_anl/bin/claude"
_anl_dstamp="$( . "$FROOT/harness/lib/discover.sh"; _felix_discover_stamp_line "$FROOT/harness/templates" )"
_anl_DO=$'plugin\tanl-hand-kept\t-\tlow\tllm\tDECLARED'
_anl_DR=$'plugin\tanl-adopted\t-\tlow\tllm\tOBSERVED\n'
_anl_discover() {   # what to seed (none | nl | nul | absent | empty) -> the CLI's output
  rm -f "$_anl_W/stack.tsv" "$_anl/claude.log"
  case "$1" in
    none)  printf '%s%s'   "$_anl_SH" "$_anl_DO" > "$_anl_W/stack.tsv" ;;
    nl)    printf '%s%s\n' "$_anl_SH" "$_anl_DO" > "$_anl_W/stack.tsv" ;;
    nul)   printf '%s%s\0' "$_anl_SH" "$_anl_DO" > "$_anl_W/stack.tsv" ;;
    empty) : > "$_anl_W/stack.tsv" ;;
  esac
  printf '%s\nanl-adopted\tllm\tlow\t-\n' "$_anl_dstamp" > "$_anl_cache"
  ( cd "$REPO" && PATH="$_anl/bin:$PATH" "$FELIX" discover --adopt 2>&1 )
}
_anl_disc_is() {   # name, cli output, expected bytes
  if grep -q '^plugin install anl-adopted' "$_anl/claude.log" 2>/dev/null; then
    is "$1" "$(_anl_bytes "$_anl_W/stack.tsv")" "$3"
  else
    bad "$1" "the stub was never asked to install anl-adopted, so this measured the fixture: $(printf '%s' "$2" | head -4 | tr '\n' ' ')"
  fi
}
_anl_out="$(_anl_discover none)"
_anl_disc_is "felix discover --adopt onto a stack.tsv with no final newline keeps its last row and declares on a line of its own" \
   "$_anl_out" "$(_anl_want '%s%s\n%s' "$_anl_SH" "$_anl_DO" "$_anl_DR")"
_anl_out="$(_anl_discover nl)"
_anl_disc_is "felix discover --adopt onto a stack.tsv ending in a newline declares with no blank line" \
   "$_anl_out" "$(_anl_want '%s%s\n%s' "$_anl_SH" "$_anl_DO" "$_anl_DR")"
_anl_out="$(_anl_discover nul)"
_anl_disc_is "felix discover --adopt onto a stack.tsv ending in a NUL byte writes a newline after the NUL before declaring" \
   "$_anl_out" "$(_anl_want '%s%s\0\n%s' "$_anl_SH" "$_anl_DO" "$_anl_DR")"
_anl_out="$(_anl_discover absent)"
_anl_disc_is "felix discover --adopt with no stack.tsv writes the declared row alone" \
   "$_anl_out" "$(_anl_want '%s' "$_anl_DR")"
_anl_out="$(_anl_discover empty)"
_anl_disc_is "felix discover --adopt onto an empty stack.tsv writes the declared row alone" \
   "$_anl_out" "$(_anl_want '%s' "$_anl_DR")"
rm -f "$_anl_W/stack.tsv" "$_anl_cache"
[ -e "$_anl/stack.keep" ] && cp -p "$_anl/stack.keep" "$_anl_W/stack.tsv"
[ -e "$_anl/cache.keep" ] && cp -p "$_anl/cache.keep" "$_anl_cache"
[ "$_anl_had_disc" -eq 1 ]  || rmdir "$FROOT/state/discover" 2>/dev/null
[ "$_anl_had_state" -eq 1 ] || rmdir "$FROOT/state" 2>/dev/null

_anl_back() {   # live file, its keep -> 0 when the live file is as it was, absent included
  if [ -e "$2" ]; then cmp -s "$1" "$2"; else [ ! -e "$1" ]; fi
}
if _anl_back "$_anl_W/autonomy" "$_anl/autonomy.keep" && _anl_back "$_anl_W/stack.tsv" "$_anl/stack.keep" \
   && _anl_back "$_anl_cache" "$_anl/cache.keep" \
   && { [ "$_anl_had_disc" -eq 1 ] || [ ! -e "$FROOT/state/discover" ]; }; then
  ok  "and the widget autonomy, stack.tsv and discovery cache those appends rewrote are back as they were"
else
  bad "and the widget autonomy, stack.tsv and discovery cache those appends rewrote are back as they were" \
      "$(ls -la "$_anl_W" "$FROOT/state/discover" 2>&1 | tr '\n' ' ')"
fi

# ---------------------------------------- felix_commission_apply_declares ----
# Main already writes the newline for a manifest ending in a printable byte, so
# C1 is green there. A trailing NUL is the open case: $(tail -c 1) reads it as
# nothing, and nothing reads as a newline.
_anl_apply() {   # dir, what to seed (none | nl | nul | absent | empty)
  local d="$_anl/$1"
  mkdir -p "$d"
  case "$2" in
    none)  printf '%s%s'   "$_anl_SH" "$_anl_DO" > "$d/stack.tsv" ;;
    nl)    printf '%s%s\n' "$_anl_SH" "$_anl_DO" > "$d/stack.tsv" ;;
    nul)   printf '%s%s\0' "$_anl_SH" "$_anl_DO" > "$d/stack.tsv" ;;
    empty) : > "$d/stack.tsv" ;;
  esac
  ( FELIX_MEMORY="$_anl/mem"; export FELIX_MEMORY
    . "$FROOT/harness/lib/commission.sh"; . "$FROOT/harness/lib/commission-provider.sh"
    felix_commission_apply_declares "$d" "$REPO" \
      "$(printf 'declare\tplugin\tanl-declared\tlow\tllm\tdeadbeef\tthe fixture\n')" anl-tree anl-policy anl_need ) 2>/dev/null
}
_anl_CR=$'plugin\tanl-declared\t-\tlow\tllm\tOBSERVED\n'
_anl_apply_is() {   # name, count the call printed, file, expected bytes
  if [ "$2" = "1" ]; then
    is "$1" "$(_anl_bytes "$3")" "$4"
  else
    bad "$1" "the apply step reported [$2] declares, not 1, so this measured the fixture: $(_anl_bytes "$3")"
  fi
}
_anl_apply_is "commissioning's apply onto a stack.tsv with no final newline keeps its last row and declares on a line of its own" \
   "$(_anl_apply cm-c1 none)" "$_anl/cm-c1/stack.tsv" "$(_anl_want '%s%s\n%s' "$_anl_SH" "$_anl_DO" "$_anl_CR")"
_anl_apply_is "commissioning's apply onto a stack.tsv ending in a newline declares with no blank line" \
   "$(_anl_apply cm-c2 nl)" "$_anl/cm-c2/stack.tsv" "$(_anl_want '%s%s\n%s' "$_anl_SH" "$_anl_DO" "$_anl_CR")"
_anl_apply_is "commissioning's apply onto a stack.tsv ending in a NUL byte writes a newline after the NUL before declaring" \
   "$(_anl_apply cm-c3 nul)" "$_anl/cm-c3/stack.tsv" "$(_anl_want '%s%s\0\n%s' "$_anl_SH" "$_anl_DO" "$_anl_CR")"
_anl_apply_is "commissioning's apply with no stack.tsv seeds the header and then the declared row" \
   "$(_anl_apply cm-c4a absent)" "$_anl/cm-c4a/stack.tsv" "$(_anl_want '%s%s' "$_anl_SH" "$_anl_CR")"
_anl_apply_is "commissioning's apply onto an empty stack.tsv writes the declared row and no header" \
   "$(_anl_apply cm-c4e empty)" "$_anl/cm-c4e/stack.tsv" "$(_anl_want '%s' "$_anl_CR")"

# --------------------------------------------------- felix_maint_record ----
_anl_MO=$'anl-weekly\t1700000000\t2023-11-14'
_anl_maint() {   # dir, what to seed (none | nl | nul | absent | empty)
  local d="$_anl/$1"
  mkdir -p "$d"
  case "$2" in
    none)  printf '%s'   "$_anl_MO" > "$d/maintenance.log" ;;
    nl)    printf '%s\n' "$_anl_MO" > "$d/maintenance.log" ;;
    nul)   printf '%s\0' "$_anl_MO" > "$d/maintenance.log" ;;
    empty) : > "$d/maintenance.log" ;;
  esac
  ( . "$FROOT/harness/lib/maintenance.sh"; felix_maint_record "$d" anl-sweep ) >/dev/null 2>&1
}
_anl_maint mt-c1 none; _anl_maint mt-c2 nl; _anl_maint mt-c3 nul
_anl_maint mt-c4a absent; _anl_maint mt-c4e empty
is "recording maintenance onto a log with no final newline keeps its last run and records on a line of its own" \
   "$(_anl_norm "$_anl/mt-c1/maintenance.log" "${#_anl_MO}")" "$(_anl_want '%s\nanl-sweep\t9\t9-9-9\n' "$_anl_MO")"
is "recording maintenance onto a log ending in a newline records with no blank line" \
   "$(_anl_norm "$_anl/mt-c2/maintenance.log" "$((${#_anl_MO} + 1))")" "$(_anl_want '%s\nanl-sweep\t9\t9-9-9\n' "$_anl_MO")"
is "recording maintenance onto a log ending in a NUL byte writes a newline after the NUL first" \
   "$(_anl_norm "$_anl/mt-c3/maintenance.log" "$((${#_anl_MO} + 1))")" "$(_anl_want '%s\0\nanl-sweep\t9\t9-9-9\n' "$_anl_MO")"
is "recording maintenance with no log writes the run alone" \
   "$(_anl_norm "$_anl/mt-c4a/maintenance.log" 0)" "$(_anl_want 'anl-sweep\t9\t9-9-9\n')"
is "recording maintenance onto an empty log writes the run alone" \
   "$(_anl_norm "$_anl/mt-c4e/maintenance.log" 0)" "$(_anl_want 'anl-sweep\t9\t9-9-9\n')"

# --------------------------------------------------- felix_budget_record ----
# Its status is the ceiling: a record that cannot be written must say so, and
# one that was written must return 0. A fix that ends the function on a test
# of the last byte would make the second false whenever that test is.
_anl_BO=$'1700000000\t2023-11-14T22:13\tby hand'
_anl_budget() {   # dir, what to seed (none | nl | nul | absent | empty) -> the record's status
  local d="$_anl/$1"
  mkdir -p "$d"
  case "$2" in
    none)  printf '%s'   "$_anl_BO" > "$d/budget.log" ;;
    nl)    printf '%s\n' "$_anl_BO" > "$d/budget.log" ;;
    nul)   printf '%s\0' "$_anl_BO" > "$d/budget.log" ;;
    empty) : > "$d/budget.log" ;;
  esac
  ( . "$FROOT/harness/lib/budget.sh"; felix_budget_record "$d" "anl hand edit" ) >/dev/null 2>&1
  printf '%s' "$?"
}
_anl_brc="$(_anl_budget bg-c1 none) $(_anl_budget bg-c2 nl) $(_anl_budget bg-c3 nul) $(_anl_budget bg-c4a absent) $(_anl_budget bg-c4e empty)"
is "recording a budget run onto a log with no final newline keeps its last run and records on a line of its own" \
   "$(_anl_norm "$_anl/bg-c1/budget.log" "${#_anl_BO}")" "$(_anl_want '%s\n9\t9-9-9T9:9\tanl hand edit\n' "$_anl_BO")"
is "recording a budget run onto a log ending in a newline records with no blank line" \
   "$(_anl_norm "$_anl/bg-c2/budget.log" "$((${#_anl_BO} + 1))")" "$(_anl_want '%s\n9\t9-9-9T9:9\tanl hand edit\n' "$_anl_BO")"
is "recording a budget run onto a log ending in a NUL byte writes a newline after the NUL first" \
   "$(_anl_norm "$_anl/bg-c3/budget.log" "$((${#_anl_BO} + 1))")" "$(_anl_want '%s\0\n9\t9-9-9T9:9\tanl hand edit\n' "$_anl_BO")"
is "recording a budget run with no log writes the run alone" \
   "$(_anl_norm "$_anl/bg-c4a/budget.log" 0)" "$(_anl_want '9\t9-9-9T9:9\tanl hand edit\n')"
is "recording a budget run onto an empty log writes the run alone" \
   "$(_anl_norm "$_anl/bg-c4e/budget.log" 0)" "$(_anl_want '9\t9-9-9T9:9\tanl hand edit\n')"
is "and felix_budget_record returns 0 after every one of those writes, whatever the last byte was" \
   "$_anl_brc" "0 0 0 0 0"

