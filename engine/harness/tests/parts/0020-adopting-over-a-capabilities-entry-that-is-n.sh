printf '\nadopting over a capabilities entry that is not a list it can read and write\n'
# felix_adopt_capability, felix adopt and the session-start hook, over a
# capabilities entry that is not a readable, writable regular file: a link
# whose target is gone, a directory, a pipe, a link to a directory, a pipe or
# a device, a file it cannot read, a file it cannot write. Each refuses with 2
# and writes nothing, and a pipe is never opened. Written blind from a contract
# on 2026-10-01, without the implementation in view.
#
# Any call that could meet a pipe would wait forever on an engine that opens
# it, so every call here runs under a watchdog. At the deadline it stops, then
# kills, only the tree it started, walked down from the pid it recorded. Never
# a pattern kill: other sessions run this suite on the same machine.
_adopt_refusals_vars

# ------------------------------------------------- the function, case by case
# Each case is a fresh project at $TMP/_adr/<case>/root/proj, with link
# targets beside it under root, so one snapshot of root before and after says
# whether anything was written anywhere the call could reach. Half the cases
# hold stack and setup rows already, half hold none.
_adrnew() {
  local d="$TMP/_adr/$1"
  mkdir -p "$d/root/proj"
  if [ "${2:-}" = rows ]; then
    printf '# kind\tname\tsource\trisk\tcapability\tgrounding\nplugin\tfelix-test-kept@nowhere\t-\tlow\tbilling\tDECLARED\n' \
      > "$d/stack.kept"
    printf '# id\ttitle\tcapability\tcheck\nkept\tA step already here\tbilling\ttrue\n' > "$d/setup.kept"
    cp "$d/stack.kept" "$d/root/proj/stack.tsv"; cp "$d/setup.kept" "$d/root/proj/setup.tsv"
    mkdir -p "$d/root/proj/setup"; printf 'kept\n' > "$d/root/proj/setup/kept.md"
  fi
  printf '%s\n' "$d"
}
_adrfn() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/adopt.sh"
             felix_adopt_capability "$1" observability "$FROOT/harness/templates" ); }
_adrgo() {
  _adrsnap "$1/root" > "$1/snap0"
  _adrrun "$1" "$_adrwait" _adrfn "$1/root/proj"
  _adrsnap "$1/root" > "$1/snap1"
}
_adrrefused() {  # LABEL DIR: what B, C and D share
  local n="adopting into $1" d="$2"
  _adrif "$d" "$n returns exactly 2" "returned [$(cat "$d/rc" 2>/dev/null)]" _adreq "$d/rc" 2
  _adrif "$d" "$n prints nothing on stdout" "[$(cat "$d/out" 2>/dev/null)]" _adrquiet "$d/out"
  _adrif "$d" "$n prints nothing on stderr" "[$(cat "$d/err" 2>/dev/null)]" _adrquiet "$d/err"
  _adrif "$d" "$n leaves every entry in and beside the project as it was" "$(_adrdiff "$d")" _adrsame "$d"
}

# A1-A4 hold on the engine before this change and must keep holding.
_adrd="$(_adrnew a1)"; _adrp="$_adrd/root/proj"
_adrgo "$_adrd"
_adrl="adopting into a project with no capabilities list"
_adrif "$_adrd" "$_adrl returns 0" "returned [$(_adrcat "$_adrd/rc")] [$(_adrcat "$_adrd/err")]" _adreq "$_adrd/rc" 0
_adrif "$_adrd" "$_adrl creates a regular file listing only observability" \
  "$(ls -l "$_adrp/capabilities" 2>&1) [$(cat "$_adrp/capabilities" 2>&1)]" \
  eval '[ -f "$_adrp/capabilities" ] && [ ! -L "$_adrp/capabilities" ] && [ "$(_adrcaps "$_adrp/capabilities")" = "observability " ]'
_adrif "$_adrd" "$_adrl appends the stack and setup rows observability implies and copies its runbook" \
  "$(cat "$_adrp/stack.tsv" "$_adrp/setup.tsv" 2>&1; ls "$_adrp/setup" 2>&1)" _adrimplied "$_adrp"
_adrif "$_adrd" "$_adrl prints the stack rows and setup steps it added as two counts" \
  "printed [$(_adrcat "$_adrd/out")], tables hold [$(_adrrows "$_adrp/stack.tsv") $(_adrrows "$_adrp/setup.tsv")]" \
  eval '[ "$(_adrcat "$_adrd/out")" = "$(_adrrows "$_adrp/stack.tsv") $(_adrrows "$_adrp/setup.tsv")" ] && cat "$_adrd/out" | grep -qE "^[0-9]+ [0-9]+$"'

_adrd="$(_adrnew a2 rows)"; _adrp="$_adrd/root/proj"
printf '# declared by hand\nci\n\ntests\n' > "$_adrp/capabilities"
printf '# declared by hand\nci\n\ntests\nobservability\n' > "$_adrd/caps.want"
_adrgo "$_adrd"
_adrl="adopting into a writable capabilities file without the capability"
_adrif "$_adrd" "$_adrl returns 0" "returned [$(_adrcat "$_adrd/rc")] [$(_adrcat "$_adrd/err")]" _adreq "$_adrd/rc" 0
_adrif "$_adrd" "$_adrl keeps every line there and appends observability as a line" \
  "[$(cat "$_adrp/capabilities" 2>&1)]" _adrbytes "$_adrp/capabilities" "$_adrd/caps.want"
_adrif "$_adrd" "$_adrl appends its rows after the ones already there and copies the runbook" \
  "$(cat "$_adrp/stack.tsv" "$_adrp/setup.tsv" 2>&1; ls "$_adrp/setup" 2>&1)" \
  eval '_adrprefix "$_adrd/stack.kept" "$_adrp/stack.tsv" && _adrprefix "$_adrd/setup.kept" "$_adrp/setup.tsv" && _adrimplied "$_adrp" && [ "$(cat "$_adrp/setup/kept.md")" = kept ]'
_adrif "$_adrd" "$_adrl prints the two counts it added to the rows already there" \
  "printed [$(_adrcat "$_adrd/out")], tables grew by [$(($(_adrrows "$_adrp/stack.tsv") - 1)) $(($(_adrrows "$_adrp/setup.tsv") - 1))]" \
  eval '[ "$(_adrcat "$_adrd/out")" = "$(($(_adrrows "$_adrp/stack.tsv") - 1)) $(($(_adrrows "$_adrp/setup.tsv") - 1))" ]'

_adrd="$(_adrnew a3)"; _adrp="$_adrd/root/proj"
printf 'ci\nobservability\n' > "$_adrp/capabilities"
_adrgo "$_adrd"
_adrl="adopting a capability the capabilities file already lists"
_adrif "$_adrd" "$_adrl returns 1" "returned [$(_adrcat "$_adrd/rc")]" _adreq "$_adrd/rc" 1
_adrif "$_adrd" "$_adrl prints nothing on stdout" "[$(_adrcat "$_adrd/out")]" _adrquiet "$_adrd/out"
_adrif "$_adrd" "$_adrl changes nothing in or beside the project" "$(_adrdiff "$_adrd")" _adrsame "$_adrd"

_adrd="$(_adrnew a4)"; _adrp="$_adrd/root/proj"
mkdir -p "$_adrd/root/elsewhere"; printf 'ci\n' > "$_adrd/root/elsewhere/caps.txt"
printf 'ci\nobservability\n' > "$_adrd/caps.want"
ln -s "$_adrd/root/elsewhere/caps.txt" "$_adrp/capabilities"
_adrgo "$_adrd"
_adrl="adopting through a capabilities link to a writable file"
_adrif "$_adrd" "$_adrl returns 0" "returned [$(_adrcat "$_adrd/rc")] [$(_adrcat "$_adrd/err")]" _adreq "$_adrd/rc" 0
_adrif "$_adrd" "$_adrl appends observability to the file the link points at" \
  "[$(_adrcat "$_adrd/root/elsewhere/caps.txt" 2>&1)]" _adrbytes "$_adrd/root/elsewhere/caps.txt" "$_adrd/caps.want"
_adrif "$_adrd" "$_adrl leaves the link a link to the same file" "$(ls -l "$_adrp/capabilities" 2>&1)" \
  _adrto "$_adrp/capabilities" "$_adrd/root/elsewhere/caps.txt"
_adrif "$_adrd" "$_adrl appends the rows observability implies" \
  "$(cat "$_adrp/stack.tsv" "$_adrp/setup.tsv" 2>&1)" _adrimplied "$_adrp"

# B1-B7: something is there and it is not a regular file once links are followed.
_adrd="$(_adrnew b1)"; _adrp="$_adrd/root/proj"; mkdir -p "$_adrd/root/there"
ln -s "$_adrd/root/there/capabilities" "$_adrp/capabilities"
_adrgo "$_adrd"
_adrl="a capabilities link whose target is gone"
_adrrefused "$_adrl" "$_adrd"
_adrif "$_adrd" "adopting into $_adrl creates nothing at its target" "$(ls -la "$_adrd/root/there" 2>&1)" \
  _adrnone "$_adrd/root/there/capabilities"
_adrif "$_adrd" "adopting into $_adrl leaves it pointing where it did" "$(ls -l "$_adrp/capabilities" 2>&1)" \
  _adrto "$_adrp/capabilities" "$_adrd/root/there/capabilities"

_adrd="$(_adrnew b2 rows)"; _adrp="$_adrd/root/proj"
ln -s "$_adrd/root/gone/deeper/capabilities" "$_adrp/capabilities"
_adrgo "$_adrd"
_adrl="a capabilities link whose target's directory is gone too"
_adrrefused "$_adrl" "$_adrd"
_adrif "$_adrd" "adopting into $_adrl creates no directory along its target's path" \
  "$(find "$_adrd/root/gone" 2>&1)" _adrnone "$_adrd/root/gone"
_adrif "$_adrd" "adopting into $_adrl leaves it pointing where it did" "$(ls -l "$_adrp/capabilities" 2>&1)" \
  _adrto "$_adrp/capabilities" "$_adrd/root/gone/deeper/capabilities"

_adrd="$(_adrnew b3)"; _adrp="$_adrd/root/proj"; mkdir "$_adrp/capabilities"
_adrgo "$_adrd"
_adrl="an empty capabilities directory"
_adrrefused "$_adrl" "$_adrd"
_adrif "$_adrd" "adopting into $_adrl leaves it an empty directory" "$(ls -la "$_adrp/capabilities" 2>&1)" \
  _adremptydir "$_adrp/capabilities"

_adrd="$(_adrnew b3f rows)"; _adrp="$_adrd/root/proj"; mkdir "$_adrp/capabilities"
printf 'ci\n' > "$_adrp/capabilities/list"; printf 'ci\n' > "$_adrd/list.kept"
_adrgo "$_adrd"
_adrl="a capabilities directory holding a file"
_adrrefused "$_adrl" "$_adrd"
_adrif "$_adrd" "adopting into $_adrl leaves the directory holding just that file, unchanged" \
  "$(ls -la "$_adrp/capabilities" 2>&1)" _adronly "$_adrp/capabilities" list "$_adrd/list.kept"

_adrd="$(_adrnew b4 rows)"; _adrp="$_adrd/root/proj"; mkfifo "$_adrp/capabilities"
_adrgo "$_adrd"
_adrl="a capabilities pipe"
_adrif "$_adrd" "adopting into $_adrl returns without waiting on it" "" true
_adrrefused "$_adrl" "$_adrd"
_adrif "$_adrd" "adopting into $_adrl leaves it a pipe" "$(ls -l "$_adrp/capabilities" 2>&1)" \
  eval '[ -p "$_adrp/capabilities" ] && [ ! -L "$_adrp/capabilities" ]'

_adrd="$(_adrnew b5)"; _adrp="$_adrd/root/proj"; mkdir -p "$_adrd/root/adir"
printf 'x\n' > "$_adrd/root/adir/inside"; printf 'x\n' > "$_adrd/inside.kept"
ln -s "$_adrd/root/adir" "$_adrp/capabilities"
_adrgo "$_adrd"
_adrl="a capabilities link to a directory"
_adrrefused "$_adrl" "$_adrd"
_adrif "$_adrd" "adopting into $_adrl leaves it pointing where it did" "$(ls -l "$_adrp/capabilities" 2>&1)" \
  _adrto "$_adrp/capabilities" "$_adrd/root/adir"
_adrif "$_adrd" "adopting into $_adrl adds nothing to the directory it points at" \
  "$(ls -la "$_adrd/root/adir" 2>&1)" _adronly "$_adrd/root/adir" inside "$_adrd/inside.kept"

_adrd="$(_adrnew b6)"; _adrp="$_adrd/root/proj"; mkfifo "$_adrd/root/apipe"
ln -s "$_adrd/root/apipe" "$_adrp/capabilities"
_adrgo "$_adrd"
_adrl="a capabilities link to a pipe"
_adrif "$_adrd" "adopting into $_adrl returns without waiting on the pipe" "" true
_adrrefused "$_adrl" "$_adrd"
_adrif "$_adrd" "adopting into $_adrl leaves it pointing at the same pipe" "$(ls -l "$_adrp/capabilities" "$_adrd/root/apipe" 2>&1)" \
  eval '_adrto "$_adrp/capabilities" "$_adrd/root/apipe" && [ -p "$_adrd/root/apipe" ] && [ ! -L "$_adrd/root/apipe" ]'

_adrd="$(_adrnew b7 rows)"; _adrp="$_adrd/root/proj"
ln -s /dev/null "$_adrp/capabilities"
_adrgo "$_adrd"
_adrl="a capabilities link to /dev/null"
_adrrefused "$_adrl" "$_adrd"
_adrif "$_adrd" "adopting into $_adrl leaves it pointing at /dev/null" "$(ls -l "$_adrp/capabilities" 2>&1)" \
  eval '_adrto "$_adrp/capabilities" /dev/null && [ -c /dev/null ]'

# C and D: a regular file the call cannot read, or cannot write. Root reads and
# writes both, so neither is a refusal there.
_adrl="an unreadable capabilities file"
if [ "$_adrroot" = 1 ]; then
  for _adrx in "returns exactly 2" "prints nothing on stdout" "prints nothing on stderr" \
               "leaves every entry in and beside the project as it was" "keeps its mode and bytes"; do
    skip "adopting into $_adrl $_adrx" "root reads a mode 000 file"
  done
else
  _adrd="$(_adrnew c)"; _adrp="$_adrd/root/proj"
  printf 'ci\n' > "$_adrd/caps.kept"; cp "$_adrd/caps.kept" "$_adrp/capabilities"; chmod 000 "$_adrp/capabilities"
  _adrgo "$_adrd"
  _adrrefused "$_adrl" "$_adrd"
  _adrif "$_adrd" "adopting into $_adrl keeps its mode and bytes" "$(ls -l "$_adrp/capabilities" 2>&1)" \
    _adrmodebytes "$_adrp/capabilities" ---------- "$_adrd/caps.kept"
fi

_adrl="a read-only capabilities file"
if [ "$_adrroot" = 1 ]; then
  for _adrx in "returns exactly 2" "prints nothing on stdout" "prints nothing on stderr" \
               "leaves every entry in and beside the project as it was" "keeps its bytes" \
               "appends no stack or setup row and copies no runbook"; do
    skip "adopting into $_adrl $_adrx" "root writes a mode 444 file"
  done
  for _adrx in "returns 1" "prints nothing on stdout" "changes nothing in or beside the project"; do
    skip "adopting a capability a read-only capabilities file already lists $_adrx" "root writes a mode 444 file"
  done
else
  _adrd="$(_adrnew d rows)"; _adrp="$_adrd/root/proj"
  printf 'ci\n' > "$_adrd/caps.kept"; cp "$_adrd/caps.kept" "$_adrp/capabilities"; chmod 444 "$_adrp/capabilities"
  _adrgo "$_adrd"
  _adrrefused "$_adrl" "$_adrd"
  _adrif "$_adrd" "adopting into $_adrl keeps its bytes" "[$(cat "$_adrp/capabilities" 2>&1)]" \
    _adrbytes "$_adrp/capabilities" "$_adrd/caps.kept"
  _adrif "$_adrd" "adopting into $_adrl appends no stack or setup row and copies no runbook" \
    "$(cat "$_adrp/stack.tsv" "$_adrp/setup.tsv" 2>&1; ls "$_adrp/setup" 2>&1)" \
    eval '_adrbytes "$_adrp/stack.tsv" "$_adrd/stack.kept" && _adrbytes "$_adrp/setup.tsv" "$_adrd/setup.kept" && _adrnone "$_adrp/setup/sentry.md"'

  _adrd="$(_adrnew d2)"; _adrp="$_adrd/root/proj"
  printf 'ci\nobservability\n' > "$_adrp/capabilities"; chmod 444 "$_adrp/capabilities"
  _adrgo "$_adrd"
  _adrl="adopting a capability a read-only capabilities file already lists"
  _adrif "$_adrd" "$_adrl returns 1" "returned [$(_adrcat "$_adrd/rc")] [$(_adrcat "$_adrd/err")]" _adreq "$_adrd/rc" 1
  _adrif "$_adrd" "$_adrl prints nothing on stdout" "[$(_adrcat "$_adrd/out")]" _adrquiet "$_adrd/out"
  _adrif "$_adrd" "$_adrl changes nothing in or beside the project" "$(_adrdiff "$_adrd")" _adrsame "$_adrd"
fi

# After review, not blind (2026-10-01): a list this user can write and not
# read. Only the grep's own status refuses it, and no case above reaches that
# line: with it deleted, all of them passed, while the list gained the
# capability, or a second copy of it, and the rows.
_adrl="a write-only capabilities file"
if [ "$_adrroot" = 1 ]; then
  for _adrx in "returns exactly 2" "prints nothing on stdout" "prints nothing on stderr" \
               "leaves every entry in and beside the project as it was" "keeps its mode and bytes"; do
    skip "adopting into $_adrl $_adrx" "root reads a mode 200 file"
    skip "adopting into $_adrl that already lists the capability $_adrx" "root reads a mode 200 file"
  done
else
  _adrd="$(_adrnew w rows)"; _adrp="$_adrd/root/proj"
  printf 'ci\n' > "$_adrd/caps.kept"; cp "$_adrd/caps.kept" "$_adrp/capabilities"; chmod 200 "$_adrp/capabilities"
  _adrgo "$_adrd"
  _adrrefused "$_adrl" "$_adrd"
  _adrif "$_adrd" "adopting into $_adrl keeps its mode and bytes" "$(ls -l "$_adrp/capabilities" 2>&1)" \
    _adrmodebytes "$_adrp/capabilities" --w------- "$_adrd/caps.kept"
  _adrd="$(_adrnew w2)"; _adrp="$_adrd/root/proj"
  printf 'ci\nobservability\n' > "$_adrd/caps.kept"; cp "$_adrd/caps.kept" "$_adrp/capabilities"; chmod 200 "$_adrp/capabilities"
  _adrgo "$_adrd"
  _adrrefused "$_adrl that already lists the capability" "$_adrd"
  _adrif "$_adrd" "adopting into $_adrl that already lists the capability keeps its mode and bytes" \
    "$(ls -l "$_adrp/capabilities" 2>&1)" _adrmodebytes "$_adrp/capabilities" --w------- "$_adrd/caps.kept"
fi

# ------------------------------------------------------------ felix adopt
# Against widget with nothing at its four adopt paths, so "nothing was
# written" cannot pass on rows earlier tests left. Whatever is there is moved
# aside here and put back, as it was, at the end of the block.
_adopt_refusals_widget
_adrcli() { cd "$REPO" && "$FELIX" adopt observability; }
_adrcligo() {
  mkdir -p "$1/root"
  _adrsnap "$_adrw" "$1/root" > "$1/snap0"
  _adrrun "$1" "$_adrwait" _adrcli
  _adrsnap "$_adrw" "$1/root" > "$1/snap1"
}
# The message is what felix says, not what a shell or a tool said on the way:
# bash's own "adopt.sh: line 23: <path>: Is a directory" holds both the path
# and "a directory", and passed two of these against the engine before the
# change. Lines in bash's shape, or a tool's, are set aside before the
# message is read; a line of felix's own is kept whatever it ends with.
_adrmsg() {
  grep -vE '^[^ ]+: line [0-9]+: |^(touch|cat|grep|cp|mv|mkdir|ln|awk|sed|head|tail|tee|chmod|sort|comm|cut|tr|wc|ls|rm|find|readlink): ' \
    "$1/err" 2>/dev/null > "$1/msg"
  return 0
}
_adrclirefused() {  # LABEL DIR NEEDLE PHRASE: what F asks of the refusal; NEEDLE may be empty
  local n="felix adopt over $1" d="$2" e
  e="[$(cat "$d/err" 2>/dev/null)]"
  _adrmsg "$d"
  _adrif "$d" "$n exits exactly 2" "exited [$(cat "$d/rc" 2>/dev/null)] $e" _adreq "$d/rc" 2
  _adrif "$d" "$n prints nothing on stdout" "[$(cat "$d/out" 2>/dev/null)]" _adrquiet "$d/out"
  _adrif "$d" "$n says on stderr that observability was not declared" "$e" _adrsays "$d/msg" "observability was not declared"
  _adrif "$d" "$n says on stderr that nothing was written" "$e" _adrsays "$d/msg" "nothing was written"
  _adrif "$d" "$n names the full path of the capabilities entry" "$e" _adrsays "$d/msg" "$_adrw/capabilities"
  if [ -n "$3" ]; then _adrif "$d" "$n says $4" "$e" _adrsays "$d/msg" "$3"; fi
  _adrif "$d" "$n never says declared, already declared or backfilled" \
    "[$(cat "$d/out" "$d/err" 2>/dev/null)]" _adrnoclaim "$d"
  _adrif "$d" "$n writes nothing in the project or where its link points" "$(_adrdiff "$d")" _adrsame "$d"
}

# E holds on the engine before this change and must keep holding.
_adrd="$TMP/_adr/e1"; mkdir -p "$_adrd"
_adrrun "$_adrd" "$_adrwait" _adrcli
_adrl="felix adopt into a project with no capabilities list"
_adrif "$_adrd" "$_adrl exits 0" "exited [$(_adrcat "$_adrd/rc")] [$(_adrcat "$_adrd/err")]" _adreq "$_adrd/rc" 0
_adrif "$_adrd" "$_adrl says declared observability for widget" "[$(_adrcat "$_adrd/out" "$_adrd/err")]" \
  _adrtold "$_adrd" "declared observability for widget"
_adrd="$TMP/_adr/e2"; mkdir -p "$_adrd"
_adrrun "$_adrd" "$_adrwait" _adrcli
_adrl="felix adopt of a capability the project already declares"
_adrif "$_adrd" "$_adrl exits 0" "exited [$(_adrcat "$_adrd/rc")] [$(_adrcat "$_adrd/err")]" _adreq "$_adrd/rc" 0
_adrif "$_adrd" "$_adrl says observability already declared" "[$(_adrcat "$_adrd/out" "$_adrd/err")]" \
  _adrtold "$_adrd" "observability already declared"
_adrclear

_adrd="$TMP/_adr/f-b1"; mkdir -p "$_adrd/root/there"
ln -s "$_adrd/root/there/capabilities" "$_adrw/capabilities"
_adrcligo "$_adrd"
_adrclirefused "a capabilities link whose target is gone" "$_adrd" \
  "capabilities is a link whose target is gone" "it found a link whose target is gone"
_adrclear

_adrd="$TMP/_adr/f-b2"; mkdir -p "$_adrd/root"
ln -s "$_adrd/root/gone/deeper/capabilities" "$_adrw/capabilities"
_adrcligo "$_adrd"
_adrclirefused "a capabilities link whose target's directory is gone too" "$_adrd" \
  "capabilities is a link whose target is gone" "it found a link whose target is gone"
_adrclear

_adrd="$TMP/_adr/f-b3"; mkdir -p "$_adrd"; mkdir "$_adrw/capabilities"
_adrcligo "$_adrd"
_adrclirefused "an empty capabilities directory" "$_adrd" "capabilities is a directory." "it found a directory"
_adrclear

_adrd="$TMP/_adr/f-b3f"; mkdir -p "$_adrd"; mkdir "$_adrw/capabilities"; printf 'ci\n' > "$_adrw/capabilities/list"
_adrcligo "$_adrd"
_adrclirefused "a capabilities directory holding a file" "$_adrd" "capabilities is a directory." "it found a directory"
_adrclear

_adrd="$TMP/_adr/f-b4"; mkdir -p "$_adrd"; mkfifo "$_adrw/capabilities"
_adrcligo "$_adrd"
_adrif "$_adrd" "felix adopt over a capabilities pipe does not wait on it" "" true
_adrclirefused "a capabilities pipe" "$_adrd" "capabilities is a pipe." "it found a pipe"
_adrclear

_adrd="$TMP/_adr/f-b5"; mkdir -p "$_adrd/root/adir"; printf 'x\n' > "$_adrd/root/adir/inside"
ln -s "$_adrd/root/adir" "$_adrw/capabilities"
_adrcligo "$_adrd"
_adrclirefused "a capabilities link to a directory" "$_adrd" "capabilities is a directory." "it found a directory"
_adrclear

_adrd="$TMP/_adr/f-b6"; mkdir -p "$_adrd/root"; mkfifo "$_adrd/root/apipe"
ln -s "$_adrd/root/apipe" "$_adrw/capabilities"
_adrcligo "$_adrd"
_adrif "$_adrd" "felix adopt over a capabilities link to a pipe does not wait on the pipe" "" true
_adrclirefused "a capabilities link to a pipe" "$_adrd" "capabilities is a pipe." "it found a pipe"
_adrclear

# The contract names no wording for a device, so this case asserts the rest.
_adrd="$TMP/_adr/f-b7"; mkdir -p "$_adrd"; ln -s /dev/null "$_adrw/capabilities"
_adrcligo "$_adrd"
_adrclirefused "a capabilities link to /dev/null" "$_adrd" "" ""
_adrclear

if [ "$_adrroot" = 1 ]; then
  for _adrl in "an unreadable capabilities file" "a read-only capabilities file"; do
    for _adrx in "exits exactly 2" "prints nothing on stdout" "says on stderr that observability was not declared" \
                 "says on stderr that nothing was written" "names the full path of the capabilities entry" \
                 "never says declared, already declared or backfilled" \
                 "writes nothing in the project or where its link points"; do
      skip "felix adopt over $_adrl $_adrx" "root reads and writes a file whatever its mode"
    done
  done
  skip "felix adopt over an unreadable capabilities file says it could not be read" "root reads a mode 000 file"
  skip "felix adopt over an unreadable capabilities file keeps its mode and bytes" "root reads a mode 000 file"
  skip "felix adopt over a read-only capabilities file says it could not be written" "root writes a mode 444 file"
else
  _adrd="$TMP/_adr/f-c"; mkdir -p "$_adrd"
  printf 'ci\n' > "$_adrd/caps.kept"; cp "$_adrd/caps.kept" "$_adrw/capabilities"; chmod 000 "$_adrw/capabilities"
  _adrcligo "$_adrd"
  _adrclirefused "an unreadable capabilities file" "$_adrd" "could not be read" "it could not be read"
  _adrif "$_adrd" "felix adopt over an unreadable capabilities file keeps its mode and bytes" \
    "$(ls -l "$_adrw/capabilities" 2>&1)" _adrmodebytes "$_adrw/capabilities" ---------- "$_adrd/caps.kept"
  _adrclear

  _adrd="$TMP/_adr/f-d"; mkdir -p "$_adrd"
  printf 'ci\n' > "$_adrw/capabilities"; chmod 444 "$_adrw/capabilities"
  _adrcligo "$_adrd"
  _adrclirefused "a read-only capabilities file" "$_adrd" "could not be written" "it could not be written"
  _adrclear
fi

# After review, not blind (2026-10-01): a write-only list, and no list in a
# project directory this user cannot write. Neither kind was reached above.
if [ "$_adrroot" = 1 ]; then
  for _adrl in "a write-only capabilities file" "a project directory it cannot write"; do
    for _adrx in "exits exactly 2" "prints nothing on stdout" "says on stderr that observability was not declared" \
                 "says on stderr that nothing was written" "names the full path of the capabilities entry" \
                 "never says declared, already declared or backfilled" \
                 "writes nothing in the project or where its link points"; do
      skip "felix adopt over $_adrl $_adrx" "root reads and writes whatever the mode"
    done
  done
  skip "felix adopt over a write-only capabilities file says it could not be read" "root reads a mode 200 file"
  skip "felix adopt over a project directory it cannot write says the list is absent and could not be created" "root writes a mode 555 directory"
else
  _adrd="$TMP/_adr/f-w"; mkdir -p "$_adrd"
  printf 'ci\n' > "$_adrw/capabilities"; chmod 200 "$_adrw/capabilities"
  _adrcligo "$_adrd"
  _adrclirefused "a write-only capabilities file" "$_adrd" "capabilities is a file that could not be read." "it could not be read"
  chmod 600 "$_adrw/capabilities"; _adrclear

  _adrd="$TMP/_adr/f-x"; mkdir -p "$_adrd"; chmod u-w "$_adrw"
  _adrcligo "$_adrd"
  chmod u+w "$_adrw"
  _adrclirefused "a project directory it cannot write" "$_adrd" \
    "capabilities is absent and could not be created." "the list is absent and could not be created"
  _adrclear
fi

# After review, not blind (2026-10-01): a capability is one word. grep -F
# reads a newline in its pattern as two patterns, so a name holding one was
# "ci already declared" over a list that held ci; and a byte that is no
# character was read by BSD grep as a list it could not read.
printf 'ci\n' > "$_adrw/capabilities"; cp "$_adrw/capabilities" "$TMP/_adr/caps.kept"
for _adrx in "$(printf 'brandnew\nci')" "$(printf 'caf\351')" "two words"; do
  _adrd="$TMP/_adr/f-name"; mkdir -p "$_adrd"
  _adrrun "$_adrd" "$_adrwait" eval 'cd "$REPO" && "$FELIX" adopt "$_adrx"'
  _adrif "$_adrd" "felix adopt refuses a capability name holding $(printf '%s' "$_adrx" | LC_ALL=C tr -c 'a-z' '?') and exits nonzero" \
    "exited [$(_adrcat "$_adrd/rc")] [$(_adrcat "$_adrd/out" "$_adrd/err")]" eval '[ "$(_adrcat "$_adrd/rc")" != 0 ] && [ -s "$_adrd/rc" ]'
  _adrif "$_adrd" "felix adopt over a capability name holding $(printf '%s' "$_adrx" | LC_ALL=C tr -c 'a-z' '?') claims nothing and leaves the list as it was" \
    "[$(_adrcat "$_adrd/out" "$_adrd/err")] [$(_adrcat "$_adrw/capabilities")]" \
    eval '_adrnoclaim "$_adrd" && cmp -s "$_adrw/capabilities" "$TMP/_adr/caps.kept" && _adrnone "$_adrw/stack.tsv"'
  rm -rf "$_adrd"
done
_adrclear

