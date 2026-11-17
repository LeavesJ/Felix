# ---- allow-grant block begin
printf '\nallow says allowed only when the grant holds\n'
# 2026-10-08: felix autonomy --allow appended the capability with >> and said
# "allowed:" whatever the file then granted. After an unended last line the
# append joined the two lines, so a hand-written tidy and the commission grant
# became tidycommission, which the reader grants neither of: tidy was lost,
# commission was never granted, and the command still said "allowed:
# commission" and wrote the commission stamp. An unended comment swallowed the
# grant the same way, and a file holding a NUL byte took the append and the
# stamp while the reader refused the whole file. These pin --allow to the
# reader: it says allowed only when felix_autonomy_allows then grants the
# capability, nothing granted before is lost, the file keeps every byte it
# held, and a grant that cannot be made to hold is said, exits non-zero, and
# leaves the file, the stamp and the directory exactly as they were. Each
# reader verdict a check leans on is pinned before the command, so a reader
# narrowed to grant nothing cannot pass them.
ALP="$FROOT/projects/widget"; ALK="$TMP/allow-keep"; mkdir -p "$ALK"
_alstart="$(ls -A "$ALP" | LC_ALL=C sort)"
_almode="$(stat -c %a "$ALP" 2>/dev/null)" || _almode="$(stat -f %Lp "$ALP")"
for _alf in "$ALP"/autonomy*; do if [ -e "$_alf" ] || [ -L "$_alf" ]; then mv "$_alf" "$ALK/"; fi; done
_alnl=$'\n'; _allocs="$(locale -a 2>/dev/null)"; _alu=""
for _all in en_US.UTF-8 C.UTF-8 en_US.utf8 C.utf8; do
  case "$_alnl$_allocs$_alnl" in *"$_alnl$_all$_alnl"*) _alu="$_all"; break ;; esac
done
_alprobe="$TMP/al.probe"; printf 'x\n' > "$_alprobe"; chmod 000 "$_alprobe"
if [ -r "$_alprobe" ]; then _albinds=no; else _albinds=yes; fi
chmod 644 "$_alprobe"; rm -f "$_alprobe"
_alrc=0; _alout=""; _alerr=""; _alend=finished
_alstamped='the stamp as it stood before the allow\n'
_alal() {   # LOCALE CAP: the reader's verdict on the widget's grant file, under LC_ALL=LOCALE
  ( export LC_ALL="$1"; . "$FROOT/harness/lib/autonomy.sh"
    felix_autonomy_allows "$ALP" "$2" && echo yes || echo no ) 2>/dev/null
}
_algrants() { _alal C "$1"; }   # CAP: the reader's verdict under C
_alboth() { printf '%s:%s' "$(_alal C "$1")" "$(_alal "${_alu:-C}" "$1")"; }   # CAP: under C, then UTF-8
_aluis() { if [ -n "$_alu" ]; then is "$@"; else skip "$1" "no UTF-8 locale is installed"; fi; }
_alwhat() {   # PATH: absent, link:TARGET, fifo, dir:ENTRIES, file:HEX of every byte, or other; never opens a FIFO
  if [ -L "$1" ]; then printf 'link:%s' "$(readlink "$1")"
  elif [ -p "$1" ]; then printf fifo
  elif [ -d "$1" ]; then printf 'dir:%s' "$(ls -A "$1" | LC_ALL=C sort | tr '\n' ' ')"
  elif [ -f "$1" ]; then printf 'file:%s' "$(od -An -v -tx1 < "$1" | tr -d ' \n')"
  elif [ -e "$1" ]; then printf other
  else printf absent; fi
}
_alhold() {   # record what sits at the grant file and at the stamp, and the directory's entries
  _alfheld="$(_alwhat "$ALP/autonomy")"; _alsheld="$(_alwhat "$ALP/autonomy.commission")"
  _albefore="$(ls -A "$ALP" | LC_ALL=C sort)"
}
_alnone() {   # [stamp]: no grant file, a stamp if asked, and no other autonomy* entry
  rm -rf "$ALP"/autonomy*
  if [ "${1:-}" = stamp ]; then printf "$_alstamped" > "$ALP/autonomy.commission"; fi
  _alhold
}
_alset() {   # FORMAT [stamp]: the grant file written by printf FORMAT, a stamp beside it if asked, nothing else
  _alnone "${2:-}"; printf "$1" > "$ALP/autonomy"; _alhold
}
_alrun() {   # CAP [LOCALE]: felix autonomy --allow CAP from the widget checkout, under LC_ALL=LOCALE if given
  ( if [ $# -gt 1 ]; then export LC_ALL="$2"; fi; cd "$REPO" && "$FELIX" autonomy --allow "$1" ) \
    > "$TMP/al.out" 2> "$TMP/al.err"; _alrc=$?; _alend=finished
  _alout="$(cat "$TMP/al.out")"; _alerr="$(cat "$TMP/al.err")"
}
# A watchdog for what could block. Each process is stopped before its
# children are listed, so none can start another, and the tree is then
# killed by pid. Only pids this block started are ever signalled.
_alkilltree() { local c; kill -STOP "$1" 2>/dev/null
                for c in $(pgrep -P "$1" 2>/dev/null); do _alkilltree "$c"; done; kill -KILL "$1" 2>/dev/null; }
_alwatch() {   # CAP: _alrun's command under a ten-second watchdog; a run it had to end leaves _alend=killed
  local pid i=0
  ( cd "$REPO" && exec "$FELIX" autonomy --allow "$1" ) > "$TMP/al.out" 2> "$TMP/al.err" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$i" -lt 100 ]; do sleep 0.1; i=$((i + 1)); done
  if kill -0 "$pid" 2>/dev/null; then _alkilltree "$pid"; _alend=killed; else _alend=finished; fi
  wait "$pid" 2>/dev/null; _alrc=$?
  _alout="$(cat "$TMP/al.out")"; _alerr="$(cat "$TMP/al.err")"
}
_alexit() { if [ "$_alend" = killed ]; then echo killed; elif [ "$_alrc" -ne 0 ]; then echo refused; else echo "exit 0"; fi; }
_alsays() {   # TEXT: said or silent, on stdout or stderr; killed if the watchdog ended the run
  if [ "$_alend" = killed ]; then echo killed; return 0; fi
  case "$_alout$_alnl$_alerr" in *"$1"*) echo said ;; *) echo silent ;; esac
}
_alsaid() { _alsays allowed:; }
_alis() { [ -f "$ALP/autonomy" ] && cmp -s "$TMP/al.want" "$ALP/autonomy" && echo same || echo differs; }   # against al.want
_alsame() { [ "$(_alwhat "$1")" = "$2" ] && echo same || echo "changed, now $(_alwhat "$1" | cut -c1-60)"; }   # PATH HELD
_alstamp() { if [ -e "$ALP/autonomy.commission" ]; then echo stamped; else echo unstamped; fi; }
_alclosed() {   # LABEL [skip]: the fail-closed assertions after a refused allow, against what _alhold recorded
  local f s n
  case "$_alfheld" in absent) f="leaves no grant file where there was none" ;;
                      file:*) f="leaves the grant file byte-identical" ;;
                      *) f="leaves what sits at the grant file as it was" ;; esac
  case "$_alsheld" in absent) s="leaves the absent stamp absent" ;; *) s="leaves the stamp byte-identical" ;; esac
  if [ "${2:-}" = skip ] || [ "$_alend" = killed ]; then   # a run the watchdog ended proves nothing: each fails
    for n in "exits non-zero" "does not say allowed" "says on stderr it was not allowed" "$f" "$s" \
             "leaves nothing new in the project directory"; do
      if [ "${2:-}" = skip ]; then skip "an allow $1 $n" "permission bits do not bind this user"
      else bad "an allow $1 $n" "the watchdog ended the run before it finished"; fi
    done; return 0
  fi
  is "an allow $1 exits non-zero" "$(_alexit)" "refused"
  is "an allow $1 does not say allowed" "$(_alsaid)" "silent"
  has "an allow $1 says on stderr it was not allowed" "$_alerr" "not allowed"
  is "an allow $1 $f" "$(_alsame "$ALP/autonomy" "$_alfheld")" "same"
  is "an allow $1 $s" "$(_alsame "$ALP/autonomy.commission" "$_alsheld")" "same"
  is "an allow $1 leaves nothing new in the project directory" "$(ls -A "$ALP" | LC_ALL=C sort)" "$_albefore"
}

# A4: with no grant file, the file is made with its header, as it always was.
_alnone; _alrun tidy
is "an allow of tidy with no grant file exits 0 and says allowed: tidy" "$_alrc:$(_alsays 'allowed: tidy')" "0:said"
printf '# What Felix may do here unattended.\ntidy\n' > "$TMP/al.want"
is "and the grant file that allow creates holds exactly the header line and tidy" "$(_alis)" "same"
is "and the reader grants tidy from the grant file that allow created" "$(_algrants tidy)" "yes"
is "and an allow of tidy into a new grant file writes no commission stamp" "$(_alstamp)" "unstamped"
_alnone; _alrun commission
is "an allow of commission with no grant file exits 0 and says allowed: commission" \
   "$_alrc:$(_alsays 'allowed: commission')" "0:said"
printf '# What Felix may do here unattended.\ncommission\n' > "$TMP/al.want"
is "and the grant file the commission allow creates holds exactly the header line and commission" "$(_alis)" "same"
is "and the reader grants commission from the grant file that allow created" "$(_algrants commission)" "yes"
is "and an allow of commission into a new grant file writes the commission stamp" "$(_alstamp)" "stamped"

# A1, A2, A3: an existing file keeps every byte it held, gains one newline
# only where its last line had none, and then the grant on a line of its own.
_alset 'tidy'
is "before the allow the reader grants tidy from a file whose one line is tidy with no newline" "$(_algrants tidy)" "yes"
_alrun commission
is "an allow of commission after an unended tidy line exits 0 and says allowed: commission" \
   "$_alrc:$(_alsays 'allowed: commission')" "0:said"
is "and after that allow the reader grants commission" "$(_algrants commission)" "yes"
is "and the unended tidy grant before it is still granted" "$(_algrants tidy)" "yes"
printf 'tidy\ncommission\n' > "$TMP/al.want"
is "and that file becomes tidy, one newline, then commission and a newline" "$(_alis)" "same"
is "and the allow of commission after the unended tidy line writes the commission stamp" "$(_alstamp)" "stamped"
_alset '# h\n# note'; _alrun commission
is "an allow of commission after an unended comment exits 0 and the reader then grants commission" \
   "$_alrc:$(_algrants commission)" "0:yes"
printf '# h\n# note\ncommission\n' > "$TMP/al.want"
is "and the unended comment stays a comment, with commission on a line of its own" "$(_alis)" "same"
_alset '# h\r\ntidy\r'
is "before the allow the reader grants tidy from a CRLF file whose last line has its CR and no LF" \
   "$(_algrants tidy)" "yes"
_alrun commission
is "an allow of commission into that CRLF file exits 0 and both commission and tidy are then granted" \
   "$_alrc:$(_algrants commission):$(_algrants tidy)" "0:yes:yes"
printf '# h\r\ntidy\r\ncommission\n' > "$TMP/al.want"
is "and every CR in it is kept, one LF ends its last line, then commission" "$(_alis)" "same"
_alset 'tidy\040\040\n# c\040\n'
is "before the allow the reader grants tidy from a line with two trailing spaces" "$(_algrants tidy)" "yes"
_alrun commission
is "an allow of commission after lines with trailing spaces exits 0 and both commission and tidy are then granted" \
   "$_alrc:$(_algrants commission):$(_algrants tidy)" "0:yes:yes"
printf 'tidy\040\040\n# c\040\ncommission\n' > "$TMP/al.want"
is "and the trailing spaces on the lines before it are kept, and nothing but commission is added" "$(_alis)" "same"
_alset ''; _alrun tidy
is "an allow of tidy into an empty grant file exits 0 and the reader then grants tidy" "$_alrc:$(_algrants tidy)" "0:yes"
printf 'tidy\n' > "$TMP/al.want"
is "and the once-empty file holds exactly tidy and a newline, no header and no blank line" "$(_alis)" "same"

# A5: a grant the reader already finds is said, and the file is not touched.
_alset '# h\ntidy\n'; _alrun tidy
is "an allow of tidy the reader already grants exits 0 and says already allowed: tidy" \
   "$_alrc:$(_alsays 'already allowed: tidy')" "0:said"
is "and the file of that already-allowed tidy is left byte-identical" "$(_alsame "$ALP/autonomy" "$_alfheld")" "same"
_alset '# h\n\040tidy\t'
is "before the allow the reader grants tidy from an unended line padded with a space and a tab" "$(_algrants tidy)" "yes"
_alrun tidy
is "an allow of tidy over that padded unended line says already allowed: tidy" \
   "$_alrc:$(_alsays 'already allowed: tidy')" "0:said"
is "and adds nothing to that file, not even the newline its last line lacks" \
   "$(_alsame "$ALP/autonomy" "$_alfheld")" "same"
_alset 'commission\r\n'
is "before the allow the reader grants commission from a CRLF commission line" "$(_algrants commission)" "yes"
_alrun commission
is "an allow of commission over a CRLF commission line says already allowed: commission" \
   "$_alrc:$(_alsays 'already allowed: commission')" "0:said"
is "and leaves that CRLF grant file byte-identical" "$(_alsame "$ALP/autonomy" "$_alfheld")" "same"
is "and that already-allowed commission writes the stamp it lacked" "$(_alstamp)" "stamped"

# A6 (a), A8: a NUL byte anywhere and the file grants nothing, so an allow
# over it is refused, the stamp beside it left as it was or still absent.
_alset '# a\000b\ntidy\ncommission\n' stamp
is "before the allow the reader grants neither tidy nor commission from a file with a NUL byte in a comment" \
   "$(_algrants tidy):$(_algrants commission)" "no:no"
_alrun commission
_alclosed "of commission over a NUL byte in a comment, beside a commission line and a stamp,"
has "and the allow of commission over a NUL byte in a comment names the NUL byte on stderr" "$_alerr" "NUL"
_alset 'tidy\ncommis\000sion\n'
is "before the allow the reader grants neither word from a file with a NUL byte inside commission" \
   "$(_algrants tidy):$(_algrants commission)" "no:no"
_alrun commission
_alclosed "of commission over a NUL byte inside a word, with no stamp,"
has "and the allow of commission over a NUL byte inside a word names the NUL byte on stderr" "$_alerr" "NUL"
_alset '# a\000b\ntidy\n'
is "before the allow the reader does not grant tidy from a NUL-holding file whose other line is tidy" \
   "$(_algrants tidy)" "no"
_alrun tidy
_alclosed "of tidy over a NUL byte in a comment above a tidy line"
has "and the allow of tidy over a NUL byte in a comment names the NUL byte on stderr" "$_alerr" "NUL"

# A6 (b), (c), A2: what cannot be read, or cannot be made, is refused.
# Permissions are put back before anything reads the directory, and a
# directory left without its write bit would block the suite's rm -rf at exit.
_alset 'tidy\n' stamp
is "before the allow the reader grants tidy from the file about to be made unreadable" "$(_algrants tidy)" "yes"
if [ "$_albinds" = yes ]; then
  chmod 000 "$ALP/autonomy"; _alrun commission; chmod 644 "$ALP/autonomy"
  _alclosed "of commission over an unreadable grant file, beside a stamp,"
  is "and tidy, granted before the refused allow of the unreadable file, is still granted" "$(_algrants tidy)" "yes"
else
  _alclosed "of commission over an unreadable grant file, beside a stamp," skip
  skip "and tidy, granted before the refused allow of the unreadable file, is still granted" \
       "permission bits do not bind this user"
fi
_alnone stamp
if [ "$_albinds" = yes ]; then
  chmod a-w "$ALP"; _alrun commission; chmod "$_almode" "$ALP"
  _alclosed "of commission with no grant file, in a directory it cannot write, beside a stamp,"
else
  _alclosed "of commission with no grant file, in a directory it cannot write, beside a stamp," skip
fi

# A6 (d): something not a regular file where the grant file goes. A FIFO
# would hang a writer or a reader that opens it, so that run is watched.
_alnone; mkdir "$ALP/autonomy"; _alhold; _alrun commission
_alclosed "of commission with a directory at the grant file, with no stamp,"
_alnone stamp; ln -s autonomy.target "$ALP/autonomy"; _alhold; _alrun commission
_alclosed "of commission through a dangling link at the grant file, beside a stamp,"
is "and the dangling link's target is not created by the refused allow" \
   "$(if [ -e "$ALP/autonomy.target" ] || [ -L "$ALP/autonomy.target" ]; then echo created; else echo absent; fi)" "absent"
_alnone; mkfifo "$ALP/autonomy"; _alhold; _alwatch commission
is "an allow of commission over a FIFO at the grant file finishes inside ten seconds" "$_alend" "finished"
_alclosed "of commission over a FIFO at the grant file, with no stamp,"
_alend=finished; rm -f "$ALP/autonomy"

# A6 (e): a write cut short by the file-size limit. bash's ulimit -f counts
# 1024-byte blocks (512 in POSIX mode), so a limit of 2 is at most 2048 bytes,
# and the comment lines here come to about 5 KB. stdout goes to a pipe, which
# the limit does not bind. A small file under the same limit is granted, so
# it is the limit that stops the write and not felix starting. Measured on
# macOS 2026-10-08: under this limit an append in place to a 5 KB file is not
# refused, while a new file is cut at 2048 bytes, so these hold the rewrite
# the contract describes, not an append.
_alcut() {   # CAP: felix autonomy --allow CAP, SIGXFSZ ignored, files limited to two blocks
  _alout="$( ( trap '' XFSZ; ulimit -f 2; cd "$REPO" && "$FELIX" autonomy --allow "$1" ) 2> "$TMP/al.err" )"
  _alrc=$?; _alend=finished; _alerr="$(cat "$TMP/al.err")"
}
_alset '# h\n'; _alcut commission
is "under a two-block file-size limit an allow of commission into a small grant file is still granted" \
   "$_alrc:$(_algrants commission)" "0:yes"
_alnone stamp; _ali=0
while [ "$_ali" -lt 66 ]; do
  printf '# held line %02d, one of enough to carry this grant file past the write limit\n' "$_ali"
  _ali=$((_ali+1))
done > "$ALP/autonomy"
printf 'tidy\n' >> "$ALP/autonomy"; _alhold
is "before the allow the reader grants tidy from the end of a five-kilobyte grant file" "$(_algrants tidy)" "yes"
_alcut commission
_alclosed "of commission whose write is cut short by the file-size limit, beside a stamp,"
is "and tidy, granted before the cut-short allow, is still granted" "$(_algrants tidy)" "yes"

# A7: a grant file it can write, in a directory it cannot. Either the grant
# is made and holds, every byte kept, or the allow fails closed; both are
# right, and the assertion is the disjunction. Tidy holds either way.
_al7n="an allow of commission into a read-only directory either grants with every byte kept or fails closed"
_al7t="and tidy, granted before the allow into the read-only directory, is still granted"
_alset '# h\ntidy' stamp
is "before the allow the reader grants tidy from the unended file in the directory about to be made read-only" \
   "$(_algrants tidy)" "yes"
printf '# h\ntidy\ncommission\n' > "$TMP/al.want"
if [ "$_albinds" = yes ]; then
  chmod a-w "$ALP"; _alrun commission; chmod "$_almode" "$ALP"
  if [ "$(_alexit)" = "exit 0" ] && [ "$(_alsaid)" = said ] && [ "$(_algrants commission)" = yes ] \
     && [ "$(_alis)" = same ]; then
    _al7=granted
  elif [ "$(_alexit)" = refused ] && [ "$(_alsaid)" = silent ] \
       && case "$_alerr" in *"not allowed"*) true ;; *) false ;; esac \
       && [ "$(_alsame "$ALP/autonomy" "$_alfheld")" = same ] \
       && [ "$(_alsame "$ALP/autonomy.commission" "$_alsheld")" = same ] \
       && [ "$(ls -A "$ALP" | LC_ALL=C sort)" = "$_albefore" ]; then
    _al7=closed
  else
    _al7="neither: $(_alexit), $(_alsaid), commission $(_algrants commission), file $(_alis)"
  fi
  case "$_al7" in granted|closed) ok "$_al7n" ;; *) bad "$_al7n" "$_al7" ;; esac
  is "$_al7t" "$(_algrants tidy)" "yes"
else
  skip "$_al7n" "permission bits do not bind this user"; skip "$_al7t" "permission bits do not bind this user"
fi

# A9: the same file and command give the same bytes and the same grant under
# C and under UTF-8.
_alset '# note\303'
if [ -n "$_alu" ]; then _alrun tidy "$_alu"; fi
printf '# note\303\ntidy\n' > "$TMP/al.want"
_aluis "an allow of tidy run under UTF-8 after an unended comment ending in a stray lead byte keeps that comment byte for byte and puts tidy on a line of its own" \
   "$(_alis)" "same"
_aluis "and that UTF-8 allow exits 0 and tidy is then granted under C and UTF-8 readers" "$_alrc:$(_alboth tidy)" "0:yes:yes"
_alset '# note\303'; _alrun tidy C
is "the same allow of tidy run under C after the stray lead byte writes exactly the same bytes" "$(_alis)" "same"
_alset 'tidy\302\240'
is "before the allow a C reader does not grant tidy from an unended tidy and no-break space" "$(_algrants tidy)" "no"
_aluis "and before the allow a UTF-8 reader does not grant it either" "$(_alal "${_alu:-C}" tidy)" "no"
_alrun tidy C
printf 'tidy\302\240\ntidy\n' > "$TMP/al.want"
is "an allow of tidy run under C after an unended tidy and no-break space exits 0 and writes that line, a newline, then tidy" \
   "$_alrc:$(_alis)" "0:same"
_aluis "and after that C allow both C and UTF-8 readers grant tidy" "$(_alboth tidy)" "yes:yes"
_alset 'tidy\302\240'
if [ -n "$_alu" ]; then _alrun tidy "$_alu"; fi
_aluis "the same allow of tidy run under UTF-8 after the no-break space writes exactly the same bytes" "$(_alis)" "same"

# A10: felix_autonomy_grant does the write and answers by the reader. A reader
# that never grants must make it fail, and a missing function is a failure,
# not a pass.
_algrant() {   # CAP [never]: felix_autonomy_grant on the widget's file, as "returned N" or missing; never stubs the reader to refuse
  ( . "$FROOT/harness/lib/autonomy.sh"
    declare -F felix_autonomy_grant >/dev/null || { echo missing; exit 0; }
    if [ "${2:-}" = never ]; then felix_autonomy_allows() { return 1; }; fi
    felix_autonomy_grant "$ALP" "$1" >/dev/null 2>&1; echo "returned $?" )
}
_alset '# h\n'; _alg="$(_algrant tidy never)"
case "$_alg" in "returned 0"|missing) _alv="$_alg" ;; *) _alv=refused ;; esac
is "felix_autonomy_grant returns non-zero when its read-back does not find the grant it wrote" "$_alv" "refused"
_alset '# a\000b\ntidy\n'
is "felix_autonomy_grant returns 2 on a grant file holding a NUL byte" "$(_algrant commission)" "returned 2"
_alset 'tidy'
is "felix_autonomy_grant of commission over an unended tidy line returns 0" "$(_algrant commission)" "returned 0"
is "and after felix_autonomy_grant over the unended tidy line both tidy and commission are granted" \
   "$(_algrants tidy):$(_algrants commission)" "yes:yes"
_alnone; mkdir "$ALP/autonomy"
is "felix_autonomy_grant returns 1 when a directory sits where the grant file goes" "$(_algrant commission)" "returned 1"

# From the adversarial review of the fix, 2026-10-08, and not blind: a
# mutation test of the block above found five changes to felix_autonomy_grant
# that every assertion passed, and each of these fails exactly its mutant.
# A read shorter than the file (the byte count dropped) is refused.
_alset '# h\ntidy\n# tail\n'
_alx1="$( ( . "$FROOT/harness/lib/autonomy.sh"
            _felix_autonomy_read() { _felix_autonomy_text="# h$_alnl"; return 0; }
            felix_autonomy_grant "$ALP" commission >/dev/null 2>&1; echo "returned $?" ) 2>/dev/null )"
is "felix_autonomy_grant returns 1 and leaves the file byte-identical when its read comes back shorter than the file" \
   "$_alx1:$(_alsame "$ALP/autonomy" "$_alfheld")" "returned 1:same"
# A grant file a person made read-only is not replaced by the mv (the -w
# check dropped); the append it replaced could not write it either.
_alset 'tidy\n' stamp
if [ "$_albinds" = yes ]; then
  chmod 444 "$ALP/autonomy"; _alrun commission; chmod 644 "$ALP/autonomy"
  _alclosed "of commission over a read-only grant file, beside a stamp,"
else
  _alclosed "of commission over a read-only grant file, beside a stamp," skip
fi
# bash 3.2's printf keeps the unwritten tail of a failed write and sends it to
# stdout later, so a rewrite whose stdout is not thrown away prints file text:
# here, text that reads allowed:.
_alnone stamp; _ali=0
while [ "$_ali" -lt 66 ]; do printf '#allowed:allowed:allowed:allowed:allowed:allowed:allowed:allowed:\n'; _ali=$((_ali+1)); done > "$ALP/autonomy"
printf 'tidy\n' >> "$ALP/autonomy"; _alhold
_alcut commission
_alclosed "of commission whose write is cut short over comment lines that read allowed:, beside a stamp,"
# The read-back's own code, which the CLI's message turns on: 1 would say
# nothing was written when something was.
_alset '# h\n'
is "felix_autonomy_grant returns 3 when its read-back does not find the grant it wrote" "$(_algrant tidy never)" "returned 3"
# A grant file 8 bytes under two 1024-byte blocks: an append in place would
# cross the limit part way, which Linux stops mid-write and macOS does not.
_alnone stamp; _ali=0
while [ "$_ali" -lt 25 ]; do printf '#%078d\n' "$_ali"; _ali=$((_ali+1)); done > "$ALP/autonomy"
printf '#%033d\ntidy\n' 0 >> "$ALP/autonomy"; _alhold
is "the near-limit grant file is 2040 bytes" "$(( $(wc -c < "$ALP/autonomy") ))" "2040"
_alcut commission
_alclosed "of commission whose rewrite of a 2040-byte grant file is cut short, beside a stamp,"
# And from the fail-open review: the library takes only a capability the
# engine defines, so a value with a newline in it cannot write a second line
# and then report that nothing was granted.
_alset 'commission\n'
_alx6="$( ( . "$FROOT/harness/lib/autonomy.sh"
            felix_autonomy_grant "$ALP" "x${_alnl}tidy" >/dev/null 2>&1; echo "returned $?" ) 2>/dev/null )"
is "felix_autonomy_grant refuses a capability with a newline in it and leaves the file byte-identical" \
   "$_alx6:$(_alsame "$ALP/autonomy" "$_alfheld"):$(_algrants tidy)" "returned 1:same:no"
is "felix_autonomy_grant refuses Commission, capitalised, and leaves the file byte-identical" \
   "$(_algrant Commission):$(_alsame "$ALP/autonomy" "$_alfheld")" "returned 1:same"
# With revoke's revision 3, 2026-10-08: the rewrite keeps the file's mode, as
# revoke's does, where mktemp would leave 0600; a new file takes the umask's
# mode, as the append's did.
_almodeof() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"; }
_alset 'tidy\n'; chmod 640 "$ALP/autonomy"; _alrun commission
is "an allow of commission over a mode-640 grant file exits 0 and leaves it mode 640" \
   "$_alrc:$(_almodeof "$ALP/autonomy")" "0:640"
_alnone; ( umask 022; cd "$REPO" && "$FELIX" autonomy --allow tidy ) >/dev/null 2>&1
is "an allow of tidy with no grant file under umask 022 creates it mode 644" "$(_almodeof "$ALP/autonomy")" "644"

rm -rf "$ALP"/autonomy* "$TMP/al.want" "$TMP/al.out" "$TMP/al.err"
for _alf in "$ALK"/autonomy*; do if [ -e "$_alf" ] || [ -L "$_alf" ]; then mv "$_alf" "$ALP/"; fi; done
rmdir "$ALK" 2>/dev/null
chmod "$_almode" "$ALP"
is "the widget's directory holds exactly what it held before allow was tested" \
   "$(ls -A "$ALP" | LC_ALL=C sort)" "$_alstart"
# ---- allow-grant block end

