printf '\nrevoke is the inverse of the reader\n'
# 2026-10-01: a grant file whose only line was the grant (no comment header)
# kept its grant through felix autonomy --revoke, while the command printed
# "revoked:" and deleted the grant's stamp. Rewriting the file through grep -v
# selects no lines there, grep exits 1, and the rewrite was skipped on that
# status, leaving autonomy.new behind. These pin --revoke to the reader: what
# felix_autonomy_allows reads as a grant, a revoke that exits 0 takes away,
# every other line stays as it was, and a rewrite that cannot be done is said
# and changes nothing, the grant, the file and the stamp all left in place.
RVP="$FROOT/projects/widget"; RVK="$TMP/revoke-keep"; mkdir -p "$RVK"
_rvstart="$(ls -A "$RVP" | LC_ALL=C sort)"
for _rvf in "$RVP"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RVK/"; done
_rvrun() {   # CAP: felix autonomy --revoke CAP from the widget checkout; sets _rvrc _rvout _rverr
  ( cd "$REPO" && "$FELIX" autonomy --revoke "$1" ) > "$TMP/rv.out" 2> "$TMP/rv.err"; _rvrc=$?
  _rvout="$(cat "$TMP/rv.out")"; _rverr="$(cat "$TMP/rv.err")"
}
_rvsaid() { case "$_rvout" in *"revoked: $1"*) echo said ;; *) echo silent ;; esac; }

# R1: each shape the reader reads as granting commission, revoked.
_rvset 'commission\n'; _rvrun commission
is "revoking a file whose only line is the grant exits 0 and the grant is gone" "$_rvrc:$(_rvallows commission)" "0:no"
is "and the file is left empty, not removed" \
   "$([ -f "$RVP/autonomy" ] && wc -c < "$RVP/autonomy" | tr -d ' ' || echo absent)" "0"
is "and the grant's stamp is gone with it" "$(_rvstamp)" "gone"
is "and it says revoked: commission" "$(_rvsaid commission)" "said"
is "and it leaves nothing new in the project directory" "$(_rvrest)" "$_rvbefore"
_rvset 'commission'; _rvrun commission
is "revoking an unended one-line grant exits 0 and the grant is gone" "$_rvrc:$(_rvallows commission)" "0:no"
is "and that revoke leaves nothing new in the project directory either" "$(_rvrest)" "$_rvbefore"
_rvset 'commission\040\040\n'; _rvrun commission
is "a grant with trailing spaces, which the reader trims, is revoked" "$_rvrc:$(_rvallows commission)" "0:no"
_rvset 'commission\t\n'; _rvrun commission
is "a grant with a trailing tab is revoked" "$_rvrc:$(_rvallows commission)" "0:no"
_rvset 'tidy\r\ncommission\r\n'; _rvrun commission
is "a grant in a CRLF file is revoked" "$_rvrc:$(_rvallows commission)" "0:no"
is "and the CRLF file's other line keeps its carriage return" "$(sed -n 1p "$RVP/autonomy")" "$(printf 'tidy\r')"
_rvset '\040\040commission\n'; _rvrun commission
is "a grant with leading spaces is revoked" "$_rvrc:$(_rvallows commission)" "0:no"
_rvset 'commission\ncommission\n'; _rvrun commission
is "a grant written on two lines is revoked from both" "$_rvrc:$(_rvallows commission)" "0:no"

# R2: beside comments, blanks and other grants, only the grant goes.
_rvset '# what Felix may do here\n# commission\n\ntidy\040\040\ncommission\n\nroute\n'; _rvrun commission
is "a grant beside comments, blanks and other grants is revoked" "$_rvrc:$(_rvallows commission)" "0:no"
printf '# what Felix may do here\n# commission\n\ntidy\040\040\n\nroute\n' > "$TMP/rv.want"
is "and every other line survives verbatim and in order" \
   "$(cmp -s "$TMP/rv.want" "$RVP/autonomy" && echo same || echo moved)" "same"
is "a comment naming the revoked capability is not taken for it" "$(grep -cxF '# commission' "$RVP/autonomy")" "1"
is "a surviving grant keeps its trailing spaces" "$(sed -n 4p "$RVP/autonomy")" "$(printf 'tidy\040\040')"
is "tidy stays allowed after commission is revoked" "$(_rvallows tidy)" "yes"
is "and the stamp of the grant revoked beside them is gone" "$(_rvstamp)" "gone"
is "and that revoke says revoked: commission too" "$(_rvsaid commission)" "said"
_rvset '# header\ntidy\ncommission\n'; _rvrun tidy
is "revoking tidy exits 0 and leaves commission allowed" "$_rvrc:$(_rvallows tidy):$(_rvallows commission)" "0:no:yes"
is "and leaves the commission stamp where it was" "$(_rvstamp)" "kept"

# R6: a rewrite that cannot be completed fails closed. Permissions are put
# back before anything is read, and a 555 directory would block the suite's
# own rm -rf at exit.
_rvprobe="$TMP/rv.probe"; printf 'x\n' > "$_rvprobe"; chmod 000 "$_rvprobe"
if [ -r "$_rvprobe" ]; then _rvperm=0; else _rvperm=1; fi
chmod 644 "$_rvprobe"; rm -f "$_rvprobe"
_rvclosed() {   # LABEL [always]: the fail-closed assertions after a refused revoke of commission
  # "always" runs them even where permission bits do not bind, for a refusal
  # that comes from something else, such as a file-size limit, which binds root.
  if [ "$_rvperm" = 0 ] && [ "${2:-}" != always ]; then
    for _rvn in "exits non-zero" "and does not say revoked" "and says on stderr it was not revoked" \
                "and leaves the file byte-identical" "and leaves the stamp in place" \
                "and the grant still holds" "and leaves nothing new behind"; do
      skip "a revoke $1 $_rvn" "permission bits do not bind this user"
    done; return
  fi
  is "a revoke $1 exits non-zero" "$([ "$_rvrc" -ne 0 ] && echo refused || echo "exit $_rvrc")" "refused"
  case "$_rvout$_rverr" in *revoked:*) bad "a revoke $1 and does not say revoked" "it said revoked:" ;;
                            *) ok "a revoke $1 and does not say revoked" ;; esac
  has "a revoke $1 and says on stderr it was not revoked" "$_rverr" "not revoked"
  is "a revoke $1 and leaves the file byte-identical" \
     "$(cmp -s "$TMP/rv.held" "$RVP/autonomy" && echo same || echo moved)" "same"
  is "a revoke $1 and leaves the stamp in place" "$(_rvstamp)" "kept"
  is "a revoke $1 and the grant still holds" "$(_rvallows commission)" "yes"
  is "a revoke $1 and leaves nothing new behind" "$(_rvrest)" "$_rvbefore"
}
_rvset 'commission\n'; cp "$RVP/autonomy" "$TMP/rv.held"
chmod 000 "$RVP/autonomy"; _rvrun commission; chmod 644 "$RVP/autonomy"
_rvclosed "that cannot read the grant file"
_rvset 'commission\n'; cp "$RVP/autonomy" "$TMP/rv.held"
_rvdmode="$(stat -c %a "$RVP" 2>/dev/null)" || _rvdmode="$(stat -f %Lp "$RVP")"
chmod a-w "$RVP"; _rvrun commission; chmod "$_rvdmode" "$RVP"
_rvclosed "that cannot write into the project directory"

# R7: nothing to revoke.
rm -f "$RVP"/autonomy*; _rvrun commission
is "revoking with no grant file exits 0" "$_rvrc" "0"
is "and does not create one" "$([ -e "$RVP/autonomy" ] && echo created || echo absent)" "absent"
is "and the reader still allows nothing" "$(_rvallows commission)" "no"

rm -f "$RVP"/autonomy*
for _rvf in "$RVK"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RVP/"; done
rmdir "$RVK" 2>/dev/null
is "the widget's directory holds exactly what it held before revoke was tested" \
   "$(ls -A "$RVP" | LC_ALL=C sort)" "$_rvstart"

printf '\nrevoke and the reader agree in every locale, and refuse what they cannot read\n'
# 2026-10-02: an adversarial review of the first revoke fix found more ways for
# --revoke and the reader to disagree, and these pin each finding. The reader
# trimmed with [[:space:]], whose meaning is the caller's locale: a grant
# ending in a no-break space held in a UTF-8 session and not under C, so a
# revoke run under C said "revoked: tidy" while a UTF-8 session start would
# still tidy. bash's read drops a NUL byte, so a NUL could stitch a word into a
# grant. --revoke took any word, and "Commission" deleted the stamp
# autonomy.commission on a case-insensitive disk. A second --revoke or --allow
# on one command line was dropped without a word. An unended last line came
# back ended. And the rewrite is held to failing closed when the write itself
# is cut short, to leaving whatever sits at the old temporary name alone, and
# to reading back what it wrote rather than trusting it. The reader's trims
# are pinned first, so a narrowed trim cannot pass the revokes by making them
# no-ops.
RV2K="$TMP/revoke-keep-2"; mkdir -p "$RV2K"
_rwstart="$(ls -A "$RVP" | LC_ALL=C sort)"
_rwmode="$(stat -c %a "$RVP" 2>/dev/null)" || _rwmode="$(stat -f %Lp "$RVP")"
for _rvf in "$RVP"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RV2K/"; done
_autonomy_revoke_vars
_rwunk() { case "$_rverr" in *'unknown capability'*) echo unknown ;; *) echo unnamed ;; esac; }
_rwsnap() { ( cd "$RVP" && for _rwf in autonomy*; do [ -e "$_rwf" ] || continue; printf '%s ' "$_rwf"; cksum < "$_rwf"; done ); }
_rwsame() { [ "$(_rwsnap)" = "$_rwheld" ] && echo same || echo changed; }   # every autonomy* file as _rwheld recorded

# C8: the reader's trims, before any revoke is measured against them.
_rvset 'commission\040\040\n'
is "before any revoke the reader takes commission with trailing spaces as a grant, under C and UTF-8" \
   "$(_rwboth commission)" "yes:yes"
_rvset 'commission\t\n'
is "before any revoke the reader takes commission with a trailing tab as a grant, under C and UTF-8" \
   "$(_rwboth commission)" "yes:yes"
_rvset 'commission\r\n'
is "before any revoke the reader takes a CRLF commission line as a grant, under C and UTF-8" \
   "$(_rwboth commission)" "yes:yes"
_rvset '\040\040commission\n'
is "before any revoke the reader takes commission with leading spaces as a grant, under C and UTF-8" \
   "$(_rwboth commission)" "yes:yes"
_rvset '\tcommission\n'
is "before any revoke the reader takes commission with a leading tab as a grant, under C and UTF-8" \
   "$(_rwboth commission)" "yes:yes"

# C1: one verdict whatever the locale. Only space, tab, CR, VT and FF are
# trimmed, and a line ends at the newline byte and nowhere else.
_rvset 'tidy\302\240\n'
_rwuis "tidy followed by a no-break space is not a grant under C or under UTF-8" "$(_rwboth tidy)" "no:no"
_rvset 'tidy\342\200\203\n'
_rwuis "tidy followed by an em space is not a grant under C or under UTF-8" "$(_rwboth tidy)" "no:no"
_rvset 'tidy\240\n'
_rwuis "tidy followed by a lone 0xA0 byte is not a grant under C or under UTF-8" "$(_rwboth tidy)" "no:no"
_rvset 'tidy\v\n'
_rwuis "tidy followed by a vertical tab is a grant under C and under UTF-8" "$(_rwboth tidy)" "yes:yes"
_rvset 'tidy\f\n'
_rwuis "tidy followed by a form feed is a grant under C and under UTF-8" "$(_rwboth tidy)" "yes:yes"
_rvset '# note\303\ntidy\n'
_rwuis "a comment ending in a stray UTF-8 lead byte leaves the tidy grant after it holding, under C and UTF-8" \
   "$(_rwboth tidy)" "yes:yes"
_rwloc "${_rwu:-C}" tidy; printf '# note\303\n' > "$TMP/rw.want"
_rwuis "a revoke of tidy under UTF-8 after that comment takes tidy away and keeps the comment byte for byte" \
   "$(_rwis)" "same"
_rvset '# h\ntidy\302\240\n'; _rwloc C tidy
_rwuis "after a revoke of tidy run under C over a no-break-space line, neither a C nor a UTF-8 reader finds tidy" \
   "$(_rwboth tidy)" "no:no"
printf '# h\n' > "$TMP/rw.want"
is "that revoke under C over the no-break-space line exits 0 and removes the line, leaving the header" \
   "$_rvrc:$(_rwis)" "0:same"

# C2: a NUL byte anywhere and the file grants nothing, and a revoke of it is
# refused and touches nothing.
_rvset '# a\000b\ntidy\ncommission\n'
is "a file holding a NUL byte in a comment grants neither tidy nor commission, under C or UTF-8" \
   "$(_rwboth tidy):$(_rwboth commission)" "no:no:no:no"
_rvset 'tidy\ncommis\000sion\n'
is "a NUL byte inside a word is not dropped to make it commission, and tidy beside it is not granted" \
   "$(_rwboth commission):$(_rwboth tidy)" "no:no:no:no"
_rvset '# a\000b\ntidy\ncommission\n'; cp "$RVP/autonomy" "$TMP/rw.held"; _rvrun commission
is "a revoke of a file holding a NUL byte exits non-zero" "$(_rwexit)" "refused"
is "and the revoke of the NUL-holding file says nothing revoked" "$(_rwsaid revoked:)" "silent"
has "and the revoke of the NUL-holding file says on stderr it was not revoked" "$_rverr" "not revoked"
has "and the revoke of the NUL-holding file names the NUL byte on stderr" "$_rverr" "NUL"
is "and the NUL-holding file is left byte-identical" \
   "$(cmp -s "$TMP/rw.held" "$RVP/autonomy" && echo same || echo moved)" "same"
is "and the NUL-holding file's commission stamp stays in place" "$(_rvstamp)" "kept"

# C3: --revoke takes tidy or commission, as --allow does, and nothing else.
_rvset '# h\ntidy\ncommission\n'; _rwheld="$(_rwsnap)"; _rvrun Commission
is "a revoke of Commission, capitalised, exits non-zero" "$(_rwexit)" "refused"
has "and the revoke of Commission says on stderr it is an unknown capability" "$_rverr" "unknown capability"
is "and the revoke of Commission says nothing revoked" "$(_rwsaid revoked:)" "silent"
is "and the revoke of Commission leaves every autonomy file byte-identical, the commission stamp included" \
   "$(_rwsame)" "same"
for _rwc in 'commission ' '*' '../x'; do
  _rvset '# h\ntidy\ncommission\n'; _rwheld="$(_rwsnap)"; _rvrun "$_rwc"
  is "a revoke of [$_rwc] is refused as an unknown capability and says nothing revoked" \
     "$(_rwexit):$(_rwunk):$(_rwsaid revoked:)" \
     "refused:unknown:silent"
  is "and the revoke of [$_rwc] leaves every autonomy file byte-identical" "$(_rwsame)" "same"
done

# C4: one capability per command.
_rvset '# h\ntidy\ncommission\n'; _rwheld="$(_rwsnap)"; _rwcli --revoke tidy --revoke commission
is "a revoke given twice on one command line exits non-zero" "$(_rwexit)" "refused"
is "and the doubled revoke says nothing revoked" "$(_rwsaid revoked:)" "silent"
is "and the doubled revoke leaves the grant file and the stamp byte-identical" "$(_rwsame)" "same"
_rvset '# h\n'; _rwheld="$(_rwsnap)"; _rwcli --allow tidy --allow commission
is "an allow given twice on one command line exits non-zero" "$(_rwexit)" "refused"
is "and the doubled allow says nothing allowed" "$(_rwsaid allowed:)" "silent"
is "and the doubled allow leaves every autonomy file byte-identical" "$(_rwsame)" "same"

# C5: what a revoke keeps, it keeps byte for byte.
_rvset 'commission\ntidy'; _rvrun commission; printf 'tidy' > "$TMP/rw.want"
is "revoking commission ahead of an unended tidy line leaves exactly tidy, still unended" "$(_rwis)" "same"
_rvset 'tidy\040\ncommission'; _rvrun commission; printf 'tidy\040\n' > "$TMP/rw.want"
is "revoking an unended commission last line keeps the line before it byte for byte, trailing space and newline" \
   "$(_rwis)" "same"

# C6: under the file-size limit a revoke fails closed. The limit stops
# whatever the revoke writes first: the replacement, or a temporary file the
# shell writes for itself, as revision 3's here-string was, before any line was
# judged. The revoke must refuse either way. ulimit -f
# counts 512-byte blocks in macOS's bash 3.2 and 1024-byte blocks in bash 5.2,
# so a limit of 2 is at most 2048 bytes on either, and the kept lines here
# come to about 5 KB. The limit binds root as well, so these run for every
# user, where the permission cases above are skipped for root. stdout goes to
# a pipe, which the limit does not bind, so the status felix prints after a
# revoke is not what fails. A small file under the same limit is revoked, so
# the limit stops the revoke's own writing and not felix starting.
_rwcut() {   # felix autonomy --revoke commission, SIGXFSZ ignored, files limited to 2 blocks
  _rvout="$( ( trap '' XFSZ; ulimit -f 2; cd "$REPO" && "$FELIX" autonomy --revoke commission ) 2> "$TMP/rv.err" )"
  _rvrc=$?; _rverr="$(cat "$TMP/rv.err")"
}
_rvset '# h\ncommission\n'; _rwcut
is "under a two-block file-size limit a small grant file is still revoked" "$_rvrc:$(_rvallows commission)" "0:no"
rm -f "$RVP"/autonomy*; _rwi=0
while [ "$_rwi" -lt 80 ]; do
  [ "$_rwi" = 40 ] && printf '# revoked: commission, 2026-09-01, then granted again\n'
  printf '# kept line %02d, one of enough to carry this file past the write limit\n' "$_rwi"
  _rwi=$((_rwi+1))
done > "$RVP/autonomy"
printf 'commission\n' >> "$RVP/autonomy"; printf 'stamp\n' > "$RVP/autonomy.commission"
_rvbefore="$(_rvrest)"; cp "$RVP/autonomy" "$TMP/rv.held"; _rwcut
_rvclosed "whose replacement is cut short by the file-size limit" always

# C7: a link planted at the first fix's temporary name is not written through.
_rvset '# h\ncommission\n'; printf 'precious\n' > "$TMP/rw.precious"; printf 'precious\n' > "$TMP/rw.want"
ln -s "$TMP/rw.precious" "$RVP/autonomy.new"; _rvrun commission
is "a revoke beside a link at autonomy.new leaves the link's target holding exactly what it held" \
   "$(cmp -s "$TMP/rw.want" "$TMP/rw.precious" && echo same || echo written)" "same"
is "and after that revoke autonomy is a regular file, not a link" \
   "$([ -f "$RVP/autonomy" ] && [ ! -L "$RVP/autonomy" ] && echo regular || echo other)" "regular"
is "and the revoke beside the planted link succeeds" "$_rvrc:$(_rvallows commission)" "0:no"
rm -f "$RVP/autonomy.new"

# C9: the read-back is what decides. A reader that always says granted must
# make the revoke fail, and a missing function is a failure, not a pass.
_rvset 'commission\n'
_rwc9="$( ( . "$FROOT/harness/lib/autonomy.sh"
            declare -F felix_autonomy_revoke >/dev/null || { echo missing; exit 0; }
            felix_autonomy_allows() { return 0; }
            if felix_autonomy_revoke "$RVP" commission >/dev/null 2>&1; then echo "returned 0"; else echo refused; fi ) )"
is "felix_autonomy_revoke returns non-zero when its read-back still finds the grant" "$_rwc9" "refused"

rm -f "$RVP"/autonomy* "$TMP/rw.want" "$TMP/rw.held" "$TMP/rw.precious"
for _rvf in "$RV2K"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RVP/"; done
rmdir "$RV2K" 2>/dev/null
chmod "$_rwmode" "$RVP"
is "the widget's directory holds exactly what it held before the review findings were tested" \
   "$(ls -A "$RVP" | LC_ALL=C sort)" "$_rwstart"

printf '\nrevoke reaches every reader, and leaves alone what it does not change\n'
# 2026-10-08: a second review of the revoke fix found the revoke narrower than
# the readers still deployed. An older engine's reader trims [[:space:]] in
# the caller's locale, so tidy followed by a no-break space is a grant to that
# engine in a macOS UTF-8 session, and this engine's revoke kept the line. A
# revoke now removes every line any reader could take as the grant: trimmed at
# both ends of ASCII whitespace and of every byte from 0x80 up. It found the
# revoke wider than its change, too: a revoke that removed nothing rewrote the
# file onto a new inode at mode 600, replaced a link and refused in a read-only
# directory. These pin a no-op to leaving the file alone and a real rewrite to
# keeping the mode; both flags and any stray word checked before anything is
# written; refusals that say only what is true; the read-back held by the CLI
# as well as by the library; the gaps the review's mutants slipped through;
# and a reader that stays linear in the size of the file, measured in CPU
# because this machine's load makes wall time meaningless.
RV3K="$TMP/revoke-keep-3"; mkdir -p "$RV3K"
_r3start="$(ls -A "$RVP" | LC_ALL=C sort)"
_r3dmode="$(stat -c %a "$RVP" 2>/dev/null)" || _r3dmode="$(stat -f %Lp "$RVP")"
for _rvf in "$RVP"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RV3K/"; done
_r3mode() { stat -L -c %a "$1" 2>/dev/null || stat -L -f %Lp "$1"; }   # FILE: its permission bits, through a link
_r3ino() { ls -i "$1" | awk '{print $1}'; }   # FILE: its inode, the link's own when it is a link
_r3type() { if [ -L "$1" ]; then echo link; elif [ -f "$1" ]; then echo regular; else echo other; fi; }
# main's felix_autonomy_allows as of 6fe5f986, copied under another name: the
# reader every engine before this fix still runs.
_rvold() {
  local proj="$1" want="$2" line
  [ -n "$want" ] || return 1
  [ -f "$proj/autonomy" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|'#'*) continue ;; esac
    # Trimmed, because a trailing space in a hand-edited file should not be the
    # difference between a permission holding and silently not.
    line="${line%"${line##*[![:space:]]}"}"
    line="${line#"${line%%[![:space:]]*}"}"
    [ "$line" = "$want" ] && return 0
  done < "$proj/autonomy"
  return 1
}
_r3old() { ( export LC_ALL="$1"; _rvold "$RVP" "$2" && echo yes || echo no ) 2>/dev/null; }   # LOCALE CAP
_r3gone() {   # SHAPE: a header, then SHAPE as printf writes it, revoked as tidy under C -> exit:said:file
  _rvset "# h\\n$1\\n"; _rwloc C tidy; printf '# h\n' > "$TMP/rw.want"
  printf '%s:%s:%s' "$_rvrc" "$(_rvsaid tidy)" "$(_rwis)"
}

# D1: a revoke takes every line any reader could take as the grant.
is "a revoke of tidy removes tidy followed by a no-break space, exits 0 and says revoked: tidy" \
   "$(_r3gone 'tidy\302\240')" "0:said:same"
is "a revoke of tidy removes tidy preceded by a no-break space, exits 0 and says revoked: tidy" \
   "$(_r3gone '\302\240tidy')" "0:said:same"
is "a revoke of tidy removes tidy followed by an em space, exits 0 and says revoked: tidy" \
   "$(_r3gone 'tidy\342\200\203')" "0:said:same"
is "a revoke of tidy removes tidy followed by an ideographic space, exits 0 and says revoked: tidy" \
   "$(_r3gone 'tidy\343\200\200')" "0:said:same"
is "a revoke of tidy removes tidy followed by a lone 0xA0 byte, exits 0 and says revoked: tidy" \
   "$(_r3gone 'tidy\240')" "0:said:same"
is "a revoke of tidy removes tidy followed by a stray UTF-8 lead byte, exits 0 and says revoked: tidy" \
   "$(_r3gone 'tidy\303')" "0:said:same"
_rvset '# h\ntidyx\nxtidy\n# tidy\302\240\nti dy\ncommission\ntidy\n'; _rwloc C tidy
printf '# h\ntidyx\nxtidy\n# tidy\302\240\nti dy\ncommission\n' > "$TMP/rw.want"
is "a revoke of tidy keeps tidyx, xtidy, a comment of tidy and a no-break space, ti dy and commission byte for byte" \
   "$_rvrc:$(_rwis)" "0:same"
_rvset '\302\240tidy\n'; _r3w="$(_rwboth tidy)"
_rvset 'tidy\343\200\200\n'; _r3w="$_r3w:$(_rwboth tidy)"
_rvset 'tidy\303\n'; _r3w="$_r3w:$(_rwboth tidy)"
_rwuis "this engine's reader takes neither a leading no-break space, an ideographic space nor a lead byte as part of a tidy grant" \
   "$_r3w" "no:no:no:no:no:no"
_r3a=""; _r3b=""
if [ -n "$_rwu" ]; then
  _rvset 'tidy\302\240\n'; _r3a="$(_r3old "$_rwu" tidy)"
  _rvset 'tidy\342\200\203\n'; _r3b="$(_r3old "$_rwu" tidy)"
fi
_rwuis "before any revoke an older engine's reader under UTF-8 takes tidy and a no-break space or an em space as a grant" \
   "$(_r3has "$_r3a$_r3b" yes found neither)" "found"
_rvset '# h\ntidy\302\240\ntidy\342\200\203\n'; _rwloc "${_rwu:-C}" tidy
_rwuis "after a revoke of tidy under UTF-8 an older engine's reader under UTF-8 finds no tidy" \
   "$_rvrc:$(_r3old "${_rwu:-C}" tidy)" "0:no"

# D2: a revoke that removes nothing leaves the file alone.
_rvset '# h\ncommission\n'; chmod 644 "$RVP/autonomy"; cp "$RVP/autonomy" "$TMP/rw.want"
_r3i="$(_r3ino "$RVP/autonomy")"; _rvrun tidy
is "a revoke of tidy where no line grants it exits 0 and says revoked: tidy" "$_rvrc:$(_rvsaid tidy)" "0:said"
is "and that no-op revoke leaves the grant file on the same inode" "$(_r3ino "$RVP/autonomy")" "$_r3i"
is "and the no-op revoke leaves the grant file's mode at 644" "$(_r3mode "$RVP/autonomy")" "644"
is "and the no-op revoke leaves the grant file's bytes as they were" "$(_rwis)" "same"
_rvset '# h\ncommission\n'; rm -f "$RVP/autonomy"
printf '# h\ncommission\n' > "$TMP/r3.target"; cp "$TMP/r3.target" "$TMP/rw.want"
ln -s "$TMP/r3.target" "$RVP/autonomy"; _rvrun tidy
is "a no-op revoke of tidy through a linked grant file exits 0 and leaves autonomy a link" \
   "$_rvrc:$(_r3type "$RVP/autonomy")" "0:link"
is "and the no-op revoke through the link leaves its target byte-identical" "$(_r3cmp "$TMP/rw.want" "$TMP/r3.target")" "same"
# 2026-10-08, when the writer lock was merged in: every revoke now takes
# projects/<p>/autonomy.lock before it reads, and a directory nothing can be
# written into cannot hold one. So the run refuses rather than say revoked:
# without the lock. D2 above pins that a no-op writes nothing, in a directory
# that can be written.
_rvset '# h\ncommission\n'; cp "$RVP/autonomy" "$TMP/rw.want"
chmod a-w "$RVP"; _rvrun tidy; chmod "$_r3dmode" "$RVP"
is "a no-op revoke of tidy in a read-only project directory, where the writer lock cannot be made, refuses and says no revoked:" \
   "$([ "$_rvrc" -ne 0 ] && echo refused || echo "exit $_rvrc"):$(case "$_rvout$_rverr" in (*revoked:*) echo said ;; (*) echo silent ;; esac)" \
   "refused:silent"
has "and the read-only revoke says on stderr that tidy is not revoked" "$_rverr" "tidy is not revoked"
is "and the read-only revoke leaves the grant file's bytes as they were" "$(_rwis)" "same"
is "and the read-only revoke leaves no autonomy.lock behind" \
   "$({ [ -e "$RVP/autonomy.lock" ] || [ -L "$RVP/autonomy.lock" ]; } && echo left || echo absent)" "absent"

# D3: a revoke that removes a line keeps the file's mode.
_rvset '# h\ntidy\ncommission\n'; chmod 644 "$RVP/autonomy"; _rvrun tidy
is "a revoke that removes a line leaves a 644 grant file at 644" "$_rvrc:$(_r3mode "$RVP/autonomy")" "0:644"
_rvset '# h\ntidy\ncommission\n'; chmod 640 "$RVP/autonomy"; _rvrun tidy
is "a revoke that removes a line leaves a 640 grant file at 640" "$_rvrc:$(_r3mode "$RVP/autonomy")" "0:640"

# D4: a linked grant file is replaced, and what it pointed at is not written.
_rvset '# h\ncommission\n'; rm -f "$RVP/autonomy"
printf '# h\ncommission\n' > "$TMP/r3.target"; cp "$TMP/r3.target" "$TMP/rw.want"
ln -s "$TMP/r3.target" "$RVP/autonomy"; _rvrun commission
is "a revoke of commission through a linked grant file exits 0 and leaves a regular file without the grant" \
   "$_rvrc:$(_r3type "$RVP/autonomy"):$(_rvallows commission)" "0:regular:no"
is "and the revoke through the link leaves the file it pointed at byte-identical" \
   "$(_r3cmp "$TMP/rw.want" "$TMP/r3.target")" "same"

# D5 and D13: every argument is checked before anything is written.
_rvset '# h\ntidy\ncommission\n'; _rwheld="$(_rwsnap)"; _rwcli --revoke tidy commission
is "a revoke of tidy followed by a stray word exits non-zero and says nothing revoked" \
   "$(_rwexit):$(_rwsaid revoked:)" "refused:silent"
is "and the revoke with a stray word leaves every autonomy file byte-identical" "$(_rwsame)" "same"
has "and the revoke with a stray word says unexpected argument on stderr" "$_rverr" "unexpected argument"
_rvset '# h\ntidy\ncommission\n'; _rwheld="$(_rwsnap)"; _rwcli --revoke tidy --allow Commission
is "a revoke of tidy beside an allow of Commission exits non-zero and names an unknown capability" \
   "$(_rwexit):$(_rwunk)" "refused:unknown"
is "and the revoke beside a bad allow leaves every autonomy file byte-identical, the tidy grant included" \
   "$(_rwsame)" "same"

# D6: refusals say what is true.
_rvset '# a\000b\ntidy\ncommission\n'; _rvrun commission
has "a refused revoke of a NUL-holding file says on stderr it must be mended by hand" "$_rverr" "by hand"
is "and the refused revoke of the NUL-holding file does not claim it grants nothing anyone can read" \
   "$(_r3has "$_rverr" 'grants nothing anyone can read' claimed honest)" "honest"
if [ "$_rvperm" = 0 ]; then
  for _r3n in "a refused revoke of tidy from an unreadable file exits non-zero and says nothing of a stamp" \
              "a refused revoke of commission from an unreadable file says its stamp is left in place" \
              "a revoke of an unreadable empty grant file exits non-zero and says nothing revoked"; do
    skip "$_r3n" "permission bits do not bind this user"
  done
else
  _rvset '# h\ntidy\n'; chmod 000 "$RVP/autonomy"; _rvrun tidy; chmod 644 "$RVP/autonomy"
  is "a refused revoke of tidy from an unreadable file exits non-zero and says nothing of a stamp" \
     "$(_rwexit):$(_rwsaid stamp)" "refused:silent"
  _rvset '# h\ncommission\n'; chmod 000 "$RVP/autonomy"; _rvrun commission; chmod 644 "$RVP/autonomy"
  has "a refused revoke of commission from an unreadable file says its stamp is left in place" \
      "$_rverr" "stamp is left in place"
  # D14: an empty file is no grant, but one that cannot be read is not known empty.
  rm -f "$RVP"/autonomy*; : > "$RVP/autonomy"; chmod 000 "$RVP/autonomy"; _rvrun commission
  chmod 644 "$RVP/autonomy"
  is "a revoke of an unreadable empty grant file exits non-zero and says nothing revoked" \
     "$(_rwexit):$(_rwsaid revoked:)" "refused:silent"
fi

# D7: the CLI, not only the library, refuses a read-back that still finds the grant.
_rvset '# h\ncommission\n'; cp "$FROOT/harness/lib/autonomy.sh" "$TMP/r3.lib"
printf '\nfelix_autonomy_allows() { return 0; }\n' >> "$FROOT/harness/lib/autonomy.sh"; _rvrun commission
cp "$TMP/r3.lib" "$FROOT/harness/lib/autonomy.sh"; rm -f "$TMP/r3.lib"
is "a revoke whose read-back still finds the grant exits non-zero and says nothing revoked" \
   "$(_rwexit):$(_rwsaid revoked:)" "refused:silent"
is "and the revoke refused on its read-back keeps the commission stamp" "$(_rvstamp)" "kept"
has "and the revoke refused on its read-back says the reader still finds the grant" "$_rverr" "still finds the grant"

# D8 and D9: no line is joined to the next, and no kept line is read as a format.
_rvset 'tid\\\ny\n'
_rwuis "a line ending in a backslash is not joined to the next to make a tidy grant, under C or UTF-8" \
   "$(_rwboth tidy)" "no:no"
printf 'tid\\\ny\n' > "$TMP/rw.want"; _rvrun tidy
is "a revoke of tidy keeps a backslash-ended line and the line after it byte for byte" "$_rvrc:$(_rwis)" "0:same"
_rvset '# 50%% off, %%s and C:\\new\ncommission\n'; _rvrun commission
printf '# 50%% off, %%s and C:\\new\n' > "$TMP/rw.want"
is "a revoke of commission keeps a comment holding percent directives and a backslash byte for byte" \
   "$_rvrc:$(_rwis)" "0:same"

# D10: a UTF-8 caller.
_rvset '# caf\303\251\ncommission\n'; _rwloc "${_rwu:-C}" commission; printf '# caf\303\251\n' > "$TMP/rw.want"
_rwuis "a revoke of commission run under UTF-8 leaves exactly the accented comment above it" "$_rvrc:$(_rwis)" "0:same"

# D11: a link planted at a temporary name built from the revoking pid.
_rvset '# h\ncommission\n'; printf 'precious\n' > "$TMP/r3.precious"; printf 'precious\n' > "$TMP/rw.want"
( cd "$REPO" && exec sh -c 'ln -s "$1" "$2/autonomy.new.$$" && exec "$3" autonomy --revoke commission' \
    _ "$TMP/r3.precious" "$RVP" "$FELIX" ) > "$TMP/rv.out" 2> "$TMP/rv.err"
_rvrc=$?; _rvout="$(cat "$TMP/rv.out")"; _rverr="$(cat "$TMP/rv.err")"
is "a revoke beside a link planted at autonomy.new and its own pid runs and leaves the link's target as it was" \
   "$([ -n "$_rvout$_rverr" ] && echo ran || echo silent):$(_r3cmp "$TMP/rw.want" "$TMP/r3.precious")" "ran:same"
rm -f "$RVP"/autonomy.new.*

# D12: a directory at autonomy grants nothing.
rm -f "$RVP"/autonomy*; mkdir "$RVP/autonomy"; _rvrun commission
is "a revoke of commission where autonomy is a directory exits 0 and says revoked: commission" \
   "$_rvrc:$(_rvsaid commission)" "0:said"
rm -rf "$RVP/autonomy"

# D15: a rewrite cut short prints none of the file it was writing.
rm -f "$RVP"/autonomy*; _r3i=0
while [ "$_r3i" -lt 80 ]; do
  [ "$_r3i" = 40 ] && printf '# revoked: commission, 2026-09-01, then granted again\n'
  printf '# kept line %02d, one of enough to carry this file past the write limit\n' "$_r3i"
  _r3i=$((_r3i+1))
done > "$RVP/autonomy"
printf 'commission\n' >> "$RVP/autonomy"; printf 'stamp\n' > "$RVP/autonomy.commission"; _rwcut
is "a revoke cut short by the file-size limit prints none of the grant file's text on stdout" \
   "$(_r3has "$_rvout" 'kept line' printed quiet):$(_r3has "$_rvout" 'write limit' printed quiet):$(_r3has "$_rvout" 'granted again' printed quiet)" \
   "quiet:quiet:quiet"

# D16: the reader is linear. About 400 KB of comments ahead of the grant, read
# by a fresh bash whose own times are summed, user and system, it and its
# children, and a CPU limit that stops a quadratic reader well short of minutes.
rm -f "$RVP"/autonomy*; _r3i=0
while [ "$_r3i" -lt 8000 ]; do
  printf '# line %04d of eight thousand ahead of the grant\n' "$_r3i"; _r3i=$((_r3i+1))
done > "$RVP/autonomy"
printf 'tidy\n' >> "$RVP/autonomy"
_r3cpu="$( ( ulimit -t 5; LC_ALL=C "$BASH" -c '. "$1/harness/lib/autonomy.sh"
             felix_autonomy_allows "$2" tidy && echo yes || echo no; times' _ "$FROOT" "$RVP" ) 2>/dev/null )"
is "the reader answers yes for tidy after 8000 comment lines using at most 3 seconds of CPU" \
   "$(printf '%s\n' "$_r3cpu" | awk 'NR == 1 { a = $0; next }
        { for (i = 1; i <= NF; i++) { split($i, p, "m"); sub(/s$/, "", p[2]); t += p[1] * 60 + p[2] } }
        END { if (NR < 3) print "killed"; else printf "%s:%s\n", a, (t <= 3 ? "within" : "over " t) }')" \
   "yes:within"

rm -f "$RVP"/autonomy* "$TMP/rw.want" "$TMP/r3.target" "$TMP/r3.precious"
for _rvf in "$RV3K"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RVP/"; done
rmdir "$RV3K" 2>/dev/null
chmod "$_r3dmode" "$RVP"
is "the widget's directory holds exactly what it held before revoke's reach was tested" \
   "$(ls -A "$RVP" | LC_ALL=C sort)" "$_r3start"

printf '\nrevoke reads every line it judges, and names a grant the way every encoding writes it\n'
# 2026-10-08: a third review of the revoke fix found it taking a read it could
# not finish for a file with nothing to remove. The line loop was fed from a
# here-string, which bash 3.2 writes to a temporary file in /tmp or /var/tmp,
# not $TMPDIR. Where that write failed, under a sandbox or a file-size limit,
# the loop never ran: over a line only an older reader grants, the CLI said
# "revoked: tidy" and kept the line, and over a plain grant it refused with the
# false word that another writer had rewritten the file. The review found the
# revoke's trim narrower than the encodings a locale runs in: the ideographic
# space is \201@ in Shift-JIS and \241@ in Big5, and GB18030's four-byte spaces
# hold digits, so trimming every byte from 0x80 up missed them all. A revoke
# now removes a line that holds the capability once and no other ASCII letter
# or '#', since no whitespace in any of those encodings holds either. And it
# found the revoke quadratic in the size of the file. These pin a read that
# cannot finish to a refusal that says so, the names rule across encodings with
# this engine's reader left strict, a revoke linear in CPU, and the gaps the
# review's mutants slipped through: the mode kept through a link, an unended
# grant, an unreadable file's refusal and a rename that is refused.
RV4K="$TMP/revoke-keep-4"; mkdir -p "$RV4K"
_r4start="$(ls -A "$RVP" | LC_ALL=C sort)"
_r4dmode="$(stat -c %a "$RVP" 2>/dev/null)" || _r4dmode="$(stat -f %Lp "$RVP")"
for _rvf in "$RVP"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RV4K/"; done
_r4long() {   # LAST: '# h', 40 comment lines of about 70 bytes, then LAST as printf writes it, beside a stamp
  rm -f "$RVP"/autonomy*; _r4i=0
  { printf '# h\n'
    while [ "$_r4i" -lt 40 ]; do
      printf '# kept line %02d, one of forty that carry this file past the write limit\n' "$_r4i"
      _r4i=$((_r4i+1))
    done
    printf "$1\\n"; } > "$RVP/autonomy"
  printf 'stamp\n' > "$RVP/autonomy.commission"
  _rvbefore="$(_rvrest)"; cp "$RVP/autonomy" "$TMP/rv.held"
}

# E1a: a sandbox that denies every write outside the Felix home and memory,
# /tmp and $TMPDIR included, so no temporary file the shell makes for itself
# can be written. Real paths, because the sandbox matches the resolved path.
_r4sb=""
if ! command -v sandbox-exec >/dev/null 2>&1; then
  _r4sb="sandbox-exec is not on this machine"
else
  _r4fr="$(cd "$FROOT" && pwd -P)"; _r4mr="$(cd "$MEM" && pwd -P)"; _r4td="$(cd "${TMPDIR:-/tmp}" && pwd -P)"
  _r4prof="(version 1)(allow default)(deny file-write*)(allow file-write* (subpath \"$_r4fr\") (subpath \"$_r4mr\") (literal \"/dev/null\"))"
  _r4pr="$(sandbox-exec -p "$_r4prof" /bin/sh -c '
      for f in "$1" "$2" "$3"; do if : > "$f"; then printf w; else printf d; fi; done' \
      _ "$_r4td/felix-r4-probe.$$" "/tmp/felix-r4-probe.$$" "$RVP/r4.probe" 2>/dev/null)"
  rm -f "$_r4td/felix-r4-probe.$$" "/tmp/felix-r4-probe.$$" "$RVP/r4.probe"
  [ "$_r4pr" = ddw ] || _r4sb="the sandbox did not deny writes to TMPDIR and /tmp while allowing the project directory (probe ${_r4pr:-silent})"
fi
_r4sbrun() {   # CAP: felix autonomy --revoke CAP under C, inside the sandbox
  ( export LC_ALL=C; cd "$REPO" && sandbox-exec -p "$_r4prof" "$FELIX" autonomy --revoke "$1" ) \
    > "$TMP/rv.out" 2> "$TMP/rv.err"; _rvrc=$?
  _rvout="$(cat "$TMP/rv.out")"; _rverr="$(cat "$TMP/rv.err")"
}
_r4n1="under a sandbox that denies writes outside the Felix home and memory, a revoke of tidy over a no-break-space line exits 0 and says revoked: tidy"
_r4n2="and the sandboxed revoke over the no-break-space line leaves exactly the header and the commission line"
_r4n3="under the same sandbox a revoke of a plain tidy grant exits 0 and leaves exactly the header and the commission line"
_r4n4="and the sandboxed revoke of a plain tidy grant says nothing of another writer"
if [ -n "$_r4sb" ]; then
  for _r4n in "$_r4n1" "$_r4n2" "$_r4n3" "$_r4n4"; do skip "$_r4n" "$_r4sb"; done
else
  _rvset '# h\ntidy\302\240\ncommission\n'; _r4sbrun tidy; printf '# h\ncommission\n' > "$TMP/rw.want"
  is "$_r4n1" "$_rvrc:$(_rvsaid tidy)" "0:said"
  is "$_r4n2" "$(_rwis)" "same"
  _rvset '# h\ntidy\ncommission\n'; _r4sbrun tidy
  is "$_r4n3" "$_rvrc:$(_rwis)" "0:same"
  is "$_r4n4" "$(_r3has "$_rvout$_rverr" 'another writer' claimed honest)" "honest"
fi

# E1b: under a file-size limit, a revoke never takes a read it could not
# finish for a file with nothing to remove.
_r4long 'tidy\302\240'; LC_ALL=C sed '$d' "$TMP/rv.held" > "$TMP/rw.want"; _r4cut tidy
_r4same="$(_r3cmp "$TMP/rv.held" "$RVP/autonomy")"
is "under a two-block file-size limit a revoke of tidy over a long file ending in a no-break-space line does not exit 0 with the file untouched" \
   "$([ "$_rvrc" = 0 ] && [ "$_r4same" = same ] && echo 'exit 0, file untouched' || echo honest)" "honest"
if [ "$_rvrc" = 0 ]; then _r4v="removed:$(_rwis)"
else _r4v="refused:$(_rwsaid revoked:):$_r4same:$([ "$(_rvrest)" = "$_rvbefore" ] && echo nothing-new || echo left-behind)"; fi
case "$_r4v" in removed:same|refused:silent:same:nothing-new) _r4v=held ;; esac
is "and that revoke either removes the line, or refuses saying nothing revoked and leaves the file and the directory as they were" \
   "$_r4v" "held"

# E1c and E1d: the refusal says why, and blames no other writer.
_r4long 'commission'; _r4cut commission
has "under a two-block file-size limit a refused revoke of commission from a long file says it could not be read whole or rewritten" \
    "$_rverr" "could not be read whole or rewritten"
is "and that refusal says nothing of another writer or of the file having been rewritten" \
   "$(_r3has "$_rverr" 'another writer' claimed honest):$(_r3has "$_rverr" 'was rewritten' claimed honest)" "honest:honest"
is "and that refused revoke of commission exits non-zero, keeps the stamp and leaves the grant file byte-identical" \
   "$(_rwexit):$(_rvstamp):$(_r3cmp "$TMP/rv.held" "$RVP/autonomy")" "refused:kept:same"
rm -f "$RVP"/autonomy*; _r4i=0
while [ "$_r4i" -lt 80 ]; do
  [ "$_r4i" = 40 ] && printf '# revoked: commission, 2026-09-01, then granted again\n'
  printf '# kept line %02d, one of enough to carry this file past the write limit\n' "$_r4i"
  _r4i=$((_r4i+1))
done > "$RVP/autonomy"
printf 'commission\n' >> "$RVP/autonomy"; printf 'stamp\n' > "$RVP/autonomy.commission"; _rwcut
has "a revoke of block 2's long commission file under the file-size limit says it could not be read whole or rewritten" \
    "$_rverr" "could not be read whole or rewritten"

# E2: the names rule. A line holding the capability once and no other ASCII
# letter or '#' is removed, whatever else it holds.
is "a revoke of tidy removes tidy followed by a Shift-JIS ideographic space, exits 0 and says revoked: tidy" \
   "$(_r3gone 'tidy\201@')" "0:said:same"
is "a revoke of tidy removes tidy preceded by a Shift-JIS ideographic space, exits 0 and says revoked: tidy" \
   "$(_r3gone '\201@tidy')" "0:said:same"
is "a revoke of tidy removes tidy followed by a Big5 ideographic space, exits 0 and says revoked: tidy" \
   "$(_r3gone 'tidy\241@')" "0:said:same"
is "a revoke of tidy removes tidy followed by a GB18030 em space, exits 0 and says revoked: tidy" \
   "$(_r3gone 'tidy\2016\2439')" "0:said:same"
is "a revoke of tidy removes tidy preceded by a GB18030 em space, exits 0 and says revoked: tidy" \
   "$(_r3gone '\2016\2439tidy')" "0:said:same"
is "a revoke of tidy removes tidy followed by a file separator byte, exits 0 and says revoked: tidy" \
   "$(_r3gone 'tidy\034')" "0:said:same"
is "a revoke of tidy removes tidy followed by a 0x01 control byte, exits 0 and says revoked: tidy" \
   "$(_r3gone 'tidy\001')" "0:said:same"
is "a revoke of tidy removes tidy followed by a full stop, exits 0 and says revoked: tidy" \
   "$(_r3gone 'tidy.')" "0:said:same"
is "a revoke of tidy removes a dash and a space before tidy, exits 0 and says revoked: tidy" \
   "$(_r3gone '- tidy')" "0:said:same"
is "a revoke of tidy removes tidy followed by a digit, exits 0 and says revoked: tidy" \
   "$(_r3gone 'tidy2')" "0:said:same"
_rvset '# h\ntidyx\nxtidy\nti dy\nTidy\ntidytidy\ntidy\202a\ntidy\n'; _rwloc C tidy
printf '# h\ntidyx\nxtidy\nti dy\nTidy\ntidytidy\ntidy\202a\n' > "$TMP/rw.want"
is "a revoke of tidy keeps tidyx, xtidy, ti dy, Tidy, tidytidy and tidy before a high byte and a letter, byte for byte" \
   "$_rvrc:$(_rwis)" "0:same"
_rvset '# h\ntidy commission\ntidy # note\n  # tidy\n# tidy\ncommission\ntidy\n'; _rwloc C tidy
printf '# h\ntidy commission\ntidy # note\n  # tidy\n# tidy\ncommission\n' > "$TMP/rw.want"
is "a revoke of tidy keeps tidy commission, tidy with a note, comments naming tidy and commission, byte for byte" \
   "$_rvrc:$(_rwis)" "0:same"
_rvset '# h\ntidy\201@\ncommission\201@\n'; _rwloc C commission; printf '# h\ntidy\201@\n' > "$TMP/rw.want"
is "a revoke of commission removes commission followed by a Shift-JIS ideographic space, keeps tidy followed by one, and takes the stamp" \
   "$_rvrc:$(_rvsaid commission):$(_rwis):$(_rvstamp)" "0:said:same:gone"
_rvset 'tidy\201@\n'; _r4w="$(_rwboth tidy)"
_rvset 'tidy\034\n'; _r4w="$_r4w:$(_rwboth tidy)"
_rvset 'tidy.\n'; _r4w="$_r4w:$(_rwboth tidy)"
_rwuis "this engine's reader takes neither tidy and a Shift-JIS ideographic space, tidy and a file separator, nor tidy. as a grant, under C or UTF-8" \
   "$_r4w" "no:no:no:no:no:no"
_r4n5="before any revoke an older engine's reader under Shift-JIS takes tidy and an ideographic space as a grant"
_r4n6="after a revoke of tidy run under C an older engine's reader under Shift-JIS finds no tidy"
case "$_rwnl$_rwlocs$_rwnl" in
  *"${_rwnl}ja_JP.SJIS$_rwnl"*)
    _rvset '# h\ntidy\201@\n'; is "$_r4n5" "$(_r3old ja_JP.SJIS tidy)" "yes"
    _rwloc C tidy; is "$_r4n6" "$_rvrc:$(_r3old ja_JP.SJIS tidy)" "0:no" ;;
  *) skip "$_r4n5" "the ja_JP.SJIS locale is not installed"; skip "$_r4n6" "the ja_JP.SJIS locale is not installed" ;;
esac

# E3: a revoke is linear. About 512 KB below the grant, revoked by a fresh bash
# whose own times are summed, under a CPU limit that stops a quadratic revoke.
rm -f "$RVP"/autonomy*; _r4i=0
{ printf 'tidy\n'
  while [ "$_r4i" -lt 8192 ]; do
    printf '# %05d below the grant, one of the comments a revoke must keep\n' "$_r4i"; _r4i=$((_r4i+1))
  done; } > "$RVP/autonomy"
_r4cpu="$( ( ulimit -t 12; LC_ALL=C "$BASH" -c '. "$1/harness/lib/autonomy.sh"
             felix_autonomy_revoke "$2" tidy >/dev/null 2>&1; echo "returned $?"; times' _ "$FROOT" "$RVP" ) 2>/dev/null )"
is "a revoke of tidy above 8192 comment lines, about 512 KB, returns 0 using at most 6 seconds of CPU" \
   "$(printf '%s\n' "$_r4cpu" | LC_ALL=C awk 'NR == 1 { a = $0; next }
        { for (i = 1; i <= NF; i++) { split($i, p, "m"); sub(/s$/, "", p[2]); t += p[1] * 60 + p[2] } }
        END { if (NR < 3) print "killed"; else printf "%s:%s\n", a, (t <= 6 ? "within" : "over " t) }')" \
   "returned 0:within"
is "and that revoke leaves no tidy line and keeps all 8192 comment lines" \
   "$(LC_ALL=C grep -cx tidy "$RVP/autonomy"):$(LC_ALL=C grep -c '^# ' "$RVP/autonomy")" "0:8192"

# E4: a revoke through a link keeps the mode of the file the link named.
_rvset '# h\ntidy\ncommission\n'; rm -f "$RVP/autonomy"
printf '# h\ntidy\ncommission\n' > "$TMP/r4.target"; chmod 640 "$TMP/r4.target"
ln -s "$TMP/r4.target" "$RVP/autonomy"; _rvrun tidy
is "a revoke of tidy through a link to a 640 grant file leaves a regular file at 640" \
   "$_rvrc:$(_r3type "$RVP/autonomy"):$(_r3mode "$RVP/autonomy")" "0:regular:640"

# E5: an unended last line is a grant.
_rvset '# h\ntidy'
_rwuis "an unended last line tidy is a grant under C and under UTF-8" "$(_rwboth tidy)" "yes:yes"

# E6: an unreadable file's refusal says what is true.
_r4n7="a refused revoke of tidy from an unreadable file says it could not be read whole"
_r4n8="and the refused revoke of the unreadable file says nothing of a NUL byte"
if [ "$_rvperm" = 0 ]; then
  for _r4n in "$_r4n7" "$_r4n8"; do skip "$_r4n" "permission bits do not bind this user"; done
else
  _rvset '# h\ntidy\n'; chmod 000 "$RVP/autonomy"; _rvrun tidy; chmod 644 "$RVP/autonomy"
  has "$_r4n7" "$_rverr" "could not be read whole"
  is "$_r4n8" "$(_r3has "$_rverr" NUL claimed honest)" "honest"
fi

# E7: a rename that is refused. The immutable flag is cleared straight after
# the revoke, before anything else, so the suite's own cleanup can remove it.
_r4n9="a revoke of commission whose rename over an immutable grant file is refused exits non-zero and says nothing revoked"
_r4n10="and the refused rename leaves the grant file byte-identical and the stamp in place"
_r4n11="and the refused rename says nothing of another writer"
_r4n12="and the refused rename leaves nothing new in the project directory"
_rvset '# h\ntidy\ncommission\n'; cp "$RVP/autonomy" "$TMP/rv.held"
if chflags uchg "$RVP/autonomy" 2>/dev/null; then
  _rvrun commission; chflags nouchg "$RVP/autonomy"
  is "$_r4n9" "$(_rwexit):$(_rwsaid revoked:)" "refused:silent"
  is "$_r4n10" "$(_r3cmp "$TMP/rv.held" "$RVP/autonomy"):$(_rvstamp)" "same:kept"
  is "$_r4n11" "$(_r3has "$_rvout$_rverr" 'another writer' claimed honest)" "honest"
  is "$_r4n12" "$(_rvrest)" "$_rvbefore"
else
  for _r4n in "$_r4n9" "$_r4n10" "$_r4n11" "$_r4n12"; do skip "$_r4n" "chflags cannot set the immutable flag here"; done
fi

rm -f "$RVP"/autonomy* "$TMP/rw.want" "$TMP/rv.held" "$TMP/r4.target"
for _rvf in "$RV4K"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RVP/"; done
rmdir "$RV4K" 2>/dev/null
chmod "$_r4dmode" "$RVP"
is "the widget's directory holds exactly what it held before revoke's reading and naming were tested" \
   "$(ls -A "$RVP" | LC_ALL=C sort)" "$_r4start"
