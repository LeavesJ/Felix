# tests/lib/qualify-needs.sh: what the qualification parts share from the needs
# part: the probe for a table no mode can make unreadable, the NUL tables, the
# reader shim that counts and fails the Nth read of a qualification.tsv, and the
# UTF-8 locale probe.
# Used by 0420 (builds them), 0430 0490 0500 0570 (_unreadable and _noread),
# 0490 0500 0570 (_qznul and its names), 0500 0570 (the shim and _qstage and
# _qeach), 0500 (_u8 and _u8none). Moved from
# parts/0420-obligations-what-would-discharge-each-by-nam.sh: the probe from
# lines 115-118, _qznul and _qzsaid with _qzwhere and _qzmark from lines
# 162-200, the shim and its helpers from lines 250-330; the UTF-8 probe from
# parts/0490-qualification-does-a-check-fail-when-what-it.sh lines 94-95.
# Definitions only. The shim and the two probes are builders: each sets its
# variables first and does nothing more once its fixture is there, so in the
# serial run only the first call (0420, 0490) does any work.

# _qualify_unreadable_probe: _unreadable is 1 when a file at mode 000 cannot be
# read by this user, 0 when it can (root), and _noread is the skip reason.
_qualify_unreadable_probe() {
  _noread="this user reads a file whose mode is 000, so no table can be made unreadable"
  [ -n "${_unreadable:-}" ] && return 0
  printf 'x\n' > "$TMP/mode-000"; chmod 000 "$TMP/mode-000"
  _unreadable=1; cat "$TMP/mode-000" >/dev/null 2>&1 && _unreadable=0
  chmod 644 "$TMP/mode-000"
}

# _qualify_u8_probe: _u8 is an en_US UTF-8 locale name or empty, _u8none the
# skip reason.
_qualify_u8_probe() {
  _u8none="no en_US UTF-8 locale is installed here"
  [ -n "${_u8+x}" ] && return 0
  _u8="$(locale -a 2>/dev/null | awk '/^en_US\.(UTF-8|utf8)$/ && !n++')"
}

# _qznul WHERE [clean]: a table whose first line is demo's met violation, clean,
# and whose last holds a NUL at WHERE; given clean, the same bytes without it,
# the twin that each refusal of a NUL table is measured against. WHERE is
#   start    a NUL starting a held row
#   row      a NUL inside a held row's mutation, before the part that undoes
#            it, so the row cut there is met
#   field    a NUL after a row's fifth field, before a premise that errors, so
#            the row cut there runs and is met
#   alone    a NUL alone on a line
#   comment  a NUL inside a comment
#   far      a NUL starting a held row past byte 8000, where git no longer
#            calls the file binary and awk still ends the line
# demo's checker marks $_qzmark each time it runs, so a run of no control is
# measured, not inferred from what was printed.
# _qualify_needs_vars: the variables this file's functions read, set when the prelude calls it
# (contract C2: a lib file defines functions and nothing else).
_qualify_needs_vars() {
_qzwhere="start row field alone comment far"
_qzmark="$TMP/qual-nul-ran"
}
_qznul() {
  local k='! grep -rqI FORBIDDEN . 2>/dev/null' pre="" post=""
  printf 'demo\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt\n' "printf x >> '$_qzmark'; $k"
  case "$1" in
    start|far) post="$(printf 'held\ttrue\tviolation\tfail\ttrue')" ;;
    row)       pre="$(printf 'held\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt' "$k")"; post='; rm bad.txt' ;;
    field)     pre="$(printf 'held\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt' "$k")"
               post="$(printf '\tsh -c %s' "'exit 2'")" ;;
    comment)   pre='# a note'; post=' beside the rows' ;;
  esac
  [ "$1" != far ] || LC_ALL=C awk 'BEGIN { for (i = 0; i < 100; i++) printf "# %097d\n", i }'
  printf '%s' "$pre"; [ "${2:-}" = clean ] || printf '\000'; printf '%s\n' "$post"
}
_qzsaid() {
  case "$1" in
    start)   printf 'a NUL starting a held row' ;;
    row)     printf "a NUL inside a held row's mutation" ;;
    field)   printf "a NUL after a row's fifth field" ;;
    alone)   printf 'a NUL alone on a line' ;;
    comment) printf 'a NUL inside a comment' ;;
    far)     printf 'a NUL past byte 8000' ;;
  esac
}

# Whichever read fails. A mode cannot stage the case where the declared list was
# read and a later read of one checker's controls was not, so the readers are
# wrapped: every call of awk or cat that names a qualification.tsv is counted,
# and the one numbered QSHIM_FAIL runs with that table at mode 000, put back as
# it returns. Which read fails is counted back from the last one a clean run of
# the same command made, so nothing here knows how many reads the engine takes
# to get there. Not awk alone: the engine's read of the table was awk's and is
# now cat's, because awk cannot see a NUL byte (lib/qualify.sh,
# _felix_qualify_read), and a wrapper on one reader counts a read another makes
# as none. So every common reader that takes a file by name is wrapped, and a
# second look added later by grep, wc, od or the like is a count of two. A
# redirect is the one read no wrapper can see.
_qualify_shim_build() {
  _qsreaders='awk cat grep sed head tail wc od cut sort cmp'
  _QSHIM="$TMP/awk-shim"; _QSC="$TMP/awk-shim.count"; _QSE="$TMP/awk-shim.err"
  _qawk="$(command -v awk)"
  _qsnone="too few reads of qualification.tsv reach awk or cat by name for this one to be made to fail alone"
  [ -x "$_QSHIM/cmp" ] && return 0
  mkdir -p "$_QSHIM"
for _qsn in $_qsreaders; do
  _qsreal="$(command -v "$_qsn")"
  cat > "$_QSHIM/$_qsn" <<EOF
#!/bin/sh
for a in "\$@"; do
  case "\$a" in
    qualification.tsv|*/qualification.tsv)
      printf x >> "\$QSHIM_COUNT"
      if [ "\$((\$(wc -c < "\$QSHIM_COUNT")))" -eq "\${QSHIM_FAIL:-0}" ]; then
        chmod 000 "\$a"; "$_qsreal" "\$@"; rc=\$?; chmod 644 "\$a"; exit \$rc
      fi
      break ;;
  esac
done
exec "$_qsreal" "\$@"
EOF
  chmod +x "$_QSHIM/$_qsn"
done
}
# _qreads CMD...: how many reads of the table CMD makes through the wrapper.
_qreads() {
  : > "$_QSC"
  ( PATH="$_QSHIM:$PATH"; QSHIM_COUNT="$_QSC"; QSHIM_FAIL=0
    export PATH QSHIM_COUNT QSHIM_FAIL; "$@" ) >/dev/null 2>&1
  printf '%s' "$(( $(wc -c < "$_QSC") ))"
}
# _qfailat K CMD...: CMD with its Kth read of the table failing. Its stdout is
# left in _qsout, its status in _qsrc and its stderr in $_QSE, so a command
# that wants it read with its stdout says 2>&1 itself. Fails, having staged
# nothing, when the run never reached read K.
_qfailat() {
  local k="$1"; shift
  : > "$_QSC"
  _qsout="$( PATH="$_QSHIM:$PATH"; QSHIM_COUNT="$_QSC"; QSHIM_FAIL="$k"
             export PATH QSHIM_COUNT QSHIM_FAIL; "$@" 2>"$_QSE" )"; _qsrc=$?
  [ "$(( $(wc -c < "$_QSC") ))" -ge "$k" ]
}
# _qstage BACK CMD...: the same, with the read BACK before the last a clean run
# makes failing. Fails, having staged nothing, when there is no such read.
_qstage() {
  local back="$1" n; shift
  n=$(( $(_qreads "$@") - back ))
  [ "$n" -ge 1 ] || return 1
  _qfailat "$n" "$@"
}
# _qeach FROM PRED CMD...: CMD with each of its reads of the table failing in
# turn, from read FROM to the last a clean run makes. PRED is called after each
# with _qsout, _qsrc and $_QSE set, and prints nothing when the result is right.
# Prints a line for each read whose result was not, one for a read the run
# never reached, and one when a clean run made fewer than FROM reads, because
# then nothing was staged at all: a failure, not a skip, or reading the table
# some way the wrapper cannot see would pass every assertion built on this.
_qeach() {
  local from="$1" pred="$2" n k said; shift 2
  n="$(_qreads "$@")"
  if [ "$n" -lt "$from" ]; then
    printf 'a clean run made %s read(s) of the table by name, fewer than %s\n' "$n" "$from"; return 0
  fi
  k="$from"
  while [ "$k" -le "$n" ]; do
    if ! _qfailat "$k" "$@"; then printf 'read %s of %s: never reached\n' "$k" "$n"
    else said="$("$pred")"; [ -z "$said" ] || printf 'read %s of %s: %s\n' "$k" "$n" "$said"; fi
    k=$((k + 1))
  done
}
