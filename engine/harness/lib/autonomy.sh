# What Felix may do here without being asked.
#
# Felix removing a file from somebody's product repository, unattended, at
# session start, is the sharpest trust boundary in the system. Everything else
# it does unattended is additive: it injects text, appends a log, or refuses a
# command. This deletes.
#
# So it is opted into per project and never inferred. An absent `autonomy` file
# means nothing is permitted, which is the state every project starts in and
# the state one stays in until somebody types the opt-in themselves. Felix does
# not write this file on a project's behalf, because a permission a system
# grants itself is not a permission.
#
# projects/<p>/autonomy: one capability per line.
#   tidy        remove a lookalike script when Felix already holds that file
#   commission  run the commissioning pipeline with nobody present
#
# Reporting is not listed and never needs opting into. Saying "this exists and
# nothing can reach it" changes nothing on disk.

# The commission grant, and the table it was granted over.
#
# Every other grant here names an action the engine defines. This one names a
# pipeline whose steps come from a project's own commissioning.tsv, and two of
# that table's columns — `when` and `check` — are eval'd in the checkout
# (commission.sh). Today nothing on a hook path evaluates them; the session
# hook says so in as many words, and felix_commission_run has exactly two
# callers, both in the CLI. Granting this puts them on a hook path.
#
# That is the whole of the risk, and it is not about today's table: every check
# in it is a read-only predicate, and the run declares stack.tsv rows without
# installing anything — felix_commission_apply_declares writes a row and a log
# line, and no installer is downstream of it. The risk is that
# projects/<p>/commissioning.tsv is ORDINARY-tier by this project's own
# constitution, so a routine edit to it would otherwise become code that runs
# unattended, forever, with nothing on any surface to show it.
#
# So the grant is bound to the table it was granted over. The policy version —
# already a hash across the table set — is stamped when a person types the
# command, and a background run refuses when the current hash differs. A table
# edited after the grant does not inherit it, and re-arming is a person's act
# of reading what changed. The same shape as the discovery cache's stamp: a
# stale verdict is not a verdict.
felix_autonomy_stamp_path() { printf '%s/autonomy.%s' "$1" "$2"; }

# Does the grant still cover what is on disk?
felix_autonomy_commission_current() {   # proj -> 0 when the stamp matches
  local proj="$1" stamped now stamp
  felix_autonomy_allows "$proj" commission || return 1
  # The stamp only as a regular file. A pipe at the path held head open for a
  # writer that never came, and the grant check with it (2026-10-01); anything
  # else is no stamp, so the grant is not current.
  stamp="$(felix_autonomy_stamp_path "$proj" commission)"
  [ -f "$stamp" ] || return 1
  stamped="$(head -1 "$stamp" 2>/dev/null)"
  [ -n "$stamped" ] || return 1
  command -v felix_commission_policy_version >/dev/null 2>&1 || return 1
  now="$(felix_commission_policy_version "$proj" 2>/dev/null)"
  [ -n "$now" ] && [ "$stamped" = "$now" ]
}

# What a grant is, read the same way by every caller.
#
# 2026-10-02, from the adversarial review of the revoke fix: the reader trimmed
# [[:space:]], and what that matches depends on the caller's locale and its C
# library. Under macOS's UTF-8 locales it takes U+00A0 (Option-Space), U+2003
# and a lone \240 byte; glibc's take U+2003 but not U+00A0; C takes none. So a
# line was a grant to one session-start and not to another, and a revoke run
# under C said "revoked: tidy" over a line the next UTF-8 session still tidied
# by. bash 5.2's read also swallows the newline after a stray UTF-8 lead byte
# in a UTF-8 locale, hiding the next line inside a comment. And bash 3.2 cuts
# a line's value at a NUL byte while 5.2 skips the byte, so "tidy\0x" was a
# grant to one and not the other.
#
# So the reader runs in the C locale, and a file holding a NUL grants nothing:
# lines are bytes split on newline, and only ASCII whitespace (space, tab, CR,
# VT, FF) is trimmed. The locale is set inside a subshell so it binds this
# read and nothing of the caller's. Against the old reader this narrows the
# trim everywhere (a grant typed with a non-ASCII space is shown [ ] by this
# engine) and widens one case: on bash 5.2 in a UTF-8 locale, a line after a
# stray lead byte is read as its own line and can grant.

# The file's whole text into _felix_autonomy_text, in one read. Call it in the
# C locale. 0 read whole, 1 could not be read, 2 holds a NUL byte.
_felix_autonomy_read() {
  local rc=1
  _felix_autonomy_text=""
  { IFS= read -r -d '' _felix_autonomy_text; rc=$?; } < "$1" 2>/dev/null || return 1
  # read -d '' stops at a NUL with status 0, and at the end of the file with 1.
  [ "$rc" = 1 ] || return 2
  # A first read that fails also ends with 1 and nothing read, which would pass
  # for an empty file; a file with bytes in it was not read if nothing came.
  [ -n "$_felix_autonomy_text" ] || [ ! -s "$1" ] || return 1
  return 0
}

# Does this one line grant this capability? Call it in the C locale.
_felix_autonomy_grants() {   # line want -> 0 when the line grants want
  local line="$1"
  case "$line" in ''|'#'*) return 1 ;; esac
  # Trimmed, because a trailing space in a hand-edited file should not be the
  # difference between a permission holding and silently not.
  line="${line%"${line##*[![:space:]]}"}"
  line="${line#"${line%%[![:space:]]*}"}"
  [ "$line" = "$2" ]
}

# Could any reader, of this engine or an older one, in any locale, take this
# line as granting this capability? Revoke removes these, which is wider than
# what this engine's reader grants. 2026-10-08, from the second review: the
# engines already deployed (plugin caches up to 0.49.273, and every session
# started before a deploy) keep the locale-bound reader, so a revoke that
# matched only this engine's reader said "revoked: tidy" over a tidy<NBSP>
# line their session-start still tidied by.
#
# A reader grants a line that is the capability with whitespace around it, as
# its locale reads whitespace. So a line names the capability when it holds it
# once and nothing else in the line is an ASCII letter or '#': no whitespace
# character, in any encoding a macOS or glibc locale runs in, holds either
# byte. UTF-8's and the EUC encodings' are bytes from \200 up, Shift-JIS's
# ideographic space is \201@ and Big5's \241@, and GB18030's four-byte spaces
# hold digits. Checked 2026-10-08 against a codec library and every LC_CTYPE
# on this Mac. The encodings that do put a letter in a space are ones no
# locale reads with it: EBCDIC, ISO-2022 and UTF-7, and Shift_JIS-2004, whose
# no-break space is \205A (macOS has no such locale, and glibc's space class
# leaves out U+00A0). 2026-10-08, from the third review: trimming whitespace
# and bytes from \200 up missed Shift-JIS, whose ideographic space ends in an
# ASCII '@', so an older engine under ja_JP.SJIS still tidied by "tidy\201@"
# after "revoked: tidy".
#
# A line that only looks like the grant ("tidy.", "- tidy", "tidy=0") goes too;
# no reader granted it. This holds while the capability names are letters: a
# second copy, or any other letter, is then a letter before or after a copy.
# Call it in the C locale, so a letter is A-Z or a-z.
#
# Only case patterns. 2026-10-08, from the fourth review: bash's # and %
# operators run a match from every position of the line, and each match
# measures the rest of it again, so they are quadratic in the line's length:
# one 512 KB line cost 8.8 s of CPU. A case alternative is also tried from
# every position, so the order matters (2026-10-08, from the fifth review):
# "a letter before a copy" tried first scanned the rest of "tidy" plus 64 KB
# of letters from each letter, 5.5 s. "A letter after a copy" fails at most
# once per line, and the other runs only when no letter follows any copy.
_felix_autonomy_names() {   # line want -> 0 when some reader might take the line as want
  case "$1" in
    *'#'*) return 1 ;;
    *"$2"*) ;;
    *) return 1 ;;
  esac
  case "$1" in *"$2"*[A-Za-z]*|*[A-Za-z]*"$2"*) return 1 ;; esac
}

# One pass of revoke, in the C locale. Checks the file holds no NUL byte, then
# reads it a line at a time, straight from the file, and drops every line
# _felix_autonomy_names matches. The bytes the lines account for are counted,
# and the count must come to the file's size: a loop that never ran, or a read
# cut short, is a file not read whole, never one with nothing to remove.
#   tmp "":   writes nothing; 5 something to remove (at the first such line),
#             4 nothing to remove
#   with tmp: writes every other line to tmp, each with the newline it had, so
#             an unended last line stays unended; 0 written, 4 nothing to remove
#   1 the file could not be read whole, or tmp could not be written
#   2 the file holds a NUL byte
#
# 2026-10-08, from the third review: the lines came from a here-string of the
# one read, and bash 3.2 writes a here-string to a temp file in /tmp or
# /var/tmp. When that write failed, the loop never ran and the pass said
# nothing to remove, so over a tidy<NBSP> line only older engines grant,
# revoke said "revoked: tidy" and left the line. And the kept text, built up in
# one string, made a revoke quadratic: 1 MB took 111 s of CPU.
_felix_autonomy_rewrite() {   # file want tmp
  local f="$1" want="$2" tmp="$3" size rc line end seen=0 hit=1 wrote=0 nl='
'
  _felix_autonomy_read "$f"; rc=$?
  [ "$rc" = 0 ] || return "$rc"
  # A read cut short mid-file also ends like the end of the file, and a NUL
  # past the cut would go unseen. In the C locale ${#…} counts bytes.
  #
  # wc's answer must be one count, digits with blanks around them, and is
  # never put through $(( )); test's -eq reads it and refuses anything else.
  # 2026-10-08, from the writer lock's third review and revoke's fifth and
  # sixth: under bash 3.2, in a script such as felix, an unset name in an
  # arithmetic expansion stops the subshell under set -u, which then exits
  # with the status of the command before the stop. A stale stdout buffer
  # flushed into this wc put its text after the count; $(( )) stopped on it
  # with wc's 0, the pass read as written, and the mv put an empty file over
  # the grants.
  size="$(wc -c < "$f")" || return 1
  case "$size" in *[0123456789]*) ;; *) return 1 ;; esac
  case "$size" in *[!0-9\ \	]*) return 1 ;; esac
  [ "$size" -eq "${#_felix_autonomy_text}" ] || return 1
  _felix_autonomy_text=""
  # Nothing may fork after this loop. When a printf to tmp fails, bash 3.2
  # keeps the unwritten tail in its buffer and flushes it into the next child,
  # where a $(…) would read file text as its answer.
  while :; do
    if IFS= read -r line; then end="$nl"
    elif [ -n "$line" ]; then end=""
    else break; fi
    seen=$(( seen + ${#line} + ${#end} ))
    if _felix_autonomy_names "$line" "$want"; then
      hit=0
      [ -n "$tmp" ] || break
    elif [ -n "$tmp" ]; then
      printf '%s%s' "$line" "$end" || { wrote=1; break; }
    fi
  done < "$f" > "${tmp:-/dev/null}"
  [ -n "$tmp" ] || [ "$hit" = 1 ] || return 5
  [ "$wrote" = 0 ] && [ "$seen" -eq "$size" ] || return 1
  [ "$hit" = 0 ] || return 4
}

felix_autonomy_allows() {
  local proj="$1" want="$2" line
  [ -n "$want" ] || return 1
  [ -f "$proj/autonomy" ] || return 1
  # The NUL check reads the whole file once, then the lines are read again and
  # the first grant answers. One line at a time, because splitting the text in
  # shell copies the rest of it per line, and that is quadratic on the hook
  # path: a 100 KB file took a minute at this machine's load.
  # A grant answers 10, not 0. Under bash 3.2, in a script such as felix, a
  # subshell that set -u stops at an unset name in an arithmetic expansion
  # exits with the status of the command before the stop (2026-10-08). The
  # reader does no arithmetic on what it reads, and nothing it runs exits 10,
  # so a stop a later change might add reads as no grant.
  ( LC_ALL=C
    _felix_autonomy_read "$proj/autonomy" || exit 1
    while IFS= read -r line || [ -n "$line" ]; do
      _felix_autonomy_grants "$line" "$want" && exit 10
    done < "$proj/autonomy"
    exit 1 ) 2>/dev/null
  [ "$?" = 10 ]
}

# Take a grant back: rewrite the file without every line _felix_autonomy_names
# matches (every line any reader could take as that grant, and lines that only
# look like it), keeping every other byte, an unended last line unended. The
# caller says "revoked" only on 0.
#   0  no line any reader takes as cap is left (or there was none to begin
#      with, and the file was not touched)
#   1  the file could not be read whole, or the rewrite could not be written
#   2  the file holds a NUL byte: this engine reads nothing from it, an older
#      one may, and the bytes cannot be rewritten as they are
#   3  rewritten, and this engine's reader still finds the grant
#
# 2026-10-01: this was `grep -vxF cap autonomy > autonomy.new && mv` in
# cmd_autonomy. grep exits 1 when it selects no line, so a file holding the
# grant alone kept it — the && skipped the mv — while the command printed
# "revoked:" and deleted the stamp, and left autonomy.new behind. An unreadable
# file did the same through grep's exit 2. And grep matched whole lines
# exactly where the reader trims, so a hand-edited "commission " stayed granted
# after a revoke that said otherwise.
#
# Decided: revoke removes every line a reader could count as the grant — the
# capability with whitespace of any kind, in any encoding, around it, CRs too —
# and with it any line holding the capability and no other letter or '#'. It
# keeps every other byte. Matching exactly instead would leave a revoke that
# cannot take back a grant a reader honours.
#
# The rewrite keeps the file's mode, and a revoke with nothing to remove
# writes nothing. A linked file is replaced by a regular one: the revoke is
# this project's, and the link's target, with anything else that shares it,
# keeps what it had.
#
# The caller holds felix_autonomy_lock across this and its read-back. Without
# it, a second run's mv can put back what this one removed, after it said so.
felix_autonomy_revoke() {
  local proj="$1" want="$2" f tmp="" rc mode
  [ -n "$want" ] || return 1
  f="$proj/autonomy"
  # The reader takes nothing from what is not a regular file.
  [ -f "$f" ] || return 0
  # Empty the shell's stdout buffer before any subshell inherits it.
  # 2026-10-08, from the sixth review: when a printf to a closed stdout fails,
  # bash 3.2 keeps its text in the buffer, and every subshell forked after
  # inherits it. Pass 2's first write into tmp flushed it there, so a NUL or a
  # newline, which $( ) had dropped from wc's answer, went into the grant file.
  # A printf with a format flushes the buffer, here into /dev/null; a bare
  # printf '' returns before it flushes.
  printf '%s' '' > /dev/null 2>&1
  # Each pass runs in its own C locale with its stdout and stderr sent to
  # /dev/null (pass 2's loop writes to tmp): bash 3.2's printf can leave the
  # unwritten tail of a failed write in its buffer, and that is file text. The
  # first pass writes nothing, not even a temp file, so a revoke with nothing
  # to remove needs no writable directory and leaves the file as it was.
  #
  # A pass's status comes back offset by 20. 2026-10-08, from the writer
  # lock's third review and revoke's fifth and sixth: under bash 3.2, in a
  # script such as felix, a subshell that set -u stops at an unset name in an
  # arithmetic expansion exits with the status of the command before the stop,
  # and nothing a pass runs exits from 20 to 25, so a stop reads as a refusal
  # whatever status it leaves. The passes once did $(( $(wc -c) )), which a
  # stale buffer stopped with wc's 0, and the mv put an empty file over the
  # grants. They now do no arithmetic on text they read; the offset is for a
  # stop no one has found yet. The exit's number is quoted: the seventh review
  # found an unquoted one split on a caller's IFS that holds a digit, so every
  # revoke refused.
  ( LC_ALL=C; _felix_autonomy_rewrite "$f" "$want" ""; exit "$(( 20 + $? ))" ) > /dev/null 2>&1; rc=$?
  case "$rc" in 21|22|24|25) rc=$(( rc - 20 )) ;; *) rc=1 ;; esac
  if [ "$rc" = 5 ]; then
    # mktemp creates the name or fails; it never opens a link planted there.
    # The name is set in the same command that makes it, where the caller's
    # exit removes it should a signal cut this short (felix_autonomy_guard).
    # mktemp ignores the signals, as the lock's mkdir does, so a Ctrl-C to the
    # group cannot kill it between making the file and naming it.
    _FELIX_AUTONOMY_TMP="$( IFS=' '; trap '' $FELIX_AUTONOMY_SIGNALS 2>/dev/null; exec mktemp "$f.new.XXXXXX" 2>/dev/null )" || { _FELIX_AUTONOMY_TMP=""; return 1; }
    tmp="$_FELIX_AUTONOMY_TMP"
    ( LC_ALL=C; _felix_autonomy_rewrite "$f" "$want" "$tmp"; exit "$(( 20 + $? ))" ) > /dev/null 2>&1; rc=$?
    case "$rc" in 20|21|22|24) rc=$(( rc - 20 )) ;; *) rc=1 ;; esac
  fi
  if [ "$rc" = 0 ]; then
    # mktemp made it 0600; give it the file's permission bits, or keep 0600.
    # BSD's %Lp leaves out setuid, setgid and sticky, which a grant file has no
    # use for.
    mode="$(stat -L -c %a "$f" 2>/dev/null || stat -L -f %Lp "$f" 2>/dev/null)"
    [ -z "$mode" ] || chmod "$mode" "$tmp" 2>/dev/null
    mv -f "$tmp" "$f" 2>/dev/null || rc=1
  fi
  rm -f "$tmp" 2>/dev/null; _FELIX_AUTONOMY_TMP=""
  case "$rc" in
    0|4) ;;
    2) return 2 ;;
    *) return 1 ;;
  esac
  # Read back through the reader rather than trusting the rewrite.
  felix_autonomy_allows "$proj" "$want" && return 3
  return 0
}

# Give a grant: rewrite the file with it on a line of its own, keeping every
# byte already there. The caller says "allowed" only on 0.
#   0  the reader grants cap now
#   1  cap is not a capability the engine defines; or the file is not a
#      regular file, is read-only or could not be read whole; or the rewrite
#      could not be written
#   2  the file holds a NUL byte, so what it grants cannot be read
#   3  rewritten, and a read of it does not find the grant
#
# 2026-10-08: this was `printf '%s\n' cap >> autonomy` in cmd_autonomy, which
# then printed "allowed:" whatever had happened. A hand-written last line with
# no newline took the grant onto it: `tidy` became `tidycommission`, which
# grants neither, so tidy was lost and commission never held, and `# note`
# took it into a comment. A file holding a NUL took the append and still
# granted nothing, since the reader refuses such a file whole. The commission
# stamp was written in each case.
#
# So a grant is written the way a revoke is: one read in the C locale, checked
# against the file's size, a newline first where the last line is unended, the
# whole text into a mktemp file and mv'd into place, then read back through the
# reader. A file that cannot be read whole, or a directory that cannot take the
# new file, is left as it was rather than half appended to.
#
# The caller holds felix_autonomy_lock across this and its read-back. Without
# it, a grant that read the file before a revoke's mv puts back what the
# revoke removed, after it said so, which an append could not do. As in
# revoke, the rewrite keeps the file's mode and replaces a link at the path
# with a regular file; a new file takes the umask's mode, as the append's did.
felix_autonomy_grant() {
  local proj="$1" want="$2" f tmp rc mode
  # Only what the engine defines, as cmd_autonomy checks: a value with a
  # newline in it would write a second line and then report no grant.
  case "$want" in tidy|commission) ;; *) return 1 ;; esac
  f="$proj/autonomy"
  # A regular file or nothing. The reader takes nothing from anything else, so
  # a link that leads nowhere, a directory or a pipe a person put there is
  # theirs to fix and not replaced, and a pipe is never opened, since the read
  # would wait for a writer that never comes. Nor a file made read-only: the mv
  # would replace it where the append could not write it, and a grant is the
  # direction that asks first.
  if [ -e "$f" ] || [ -L "$f" ]; then [ -f "$f" ] && [ -w "$f" ] || return 1; fi
  # As in revoke: whatever an earlier failed printf left in bash 3.2's stdout
  # buffer goes to /dev/null before any child is made, or the mktemp below
  # would take it into the name and the write into the file. Only the '%s'
  # form flushes; a bare printf '' returns first (revoke's sixth review).
  printf '%s' '' > /dev/null 2>&1
  # As in revoke: the name where the caller's exit can remove it.
  _FELIX_AUTONOMY_TMP="$( IFS=' '; trap '' $FELIX_AUTONOMY_SIGNALS 2>/dev/null; exec mktemp "$f.new.XXXXXX" 2>/dev/null )" || { _FELIX_AUTONOMY_TMP=""; return 1; }
  tmp="$_FELIX_AUTONOMY_TMP"
  # As in revoke: its own C locale, and its stdout thrown away.
  ( LC_ALL=C; nl='
'
    if [ -e "$f" ]; then
      _felix_autonomy_read "$f"; rc=$?
      [ "$rc" = 0 ] || exit "$rc"
      # As in revoke's pass: wc's answer is checked as digits and never put
      # through $(( )). A set -u stop there leaves the status of the command
      # before it, which is wc's, so a wc that answered a word and exited 10
      # read as written whatever this subshell said (revoke's fifth review).
      # The padded count goes to -eq as it is: stripping its blanks joined
      # "2 0" into 20 (revoke's sixth review).
      size="$(wc -c < "$f")" || exit 1
      case "$size" in *[0123456789]*) ;; *) exit 1 ;; esac
      case "$size" in *[!0-9\ \	]*) exit 1 ;; esac
      [ "$size" -eq "${#_felix_autonomy_text}" ] 2>/dev/null || exit 1
    else
      _felix_autonomy_text="# What Felix may do here unattended.$nl"
    fi
    case "$_felix_autonomy_text" in
      ''|*"$nl") ;;
      *) _felix_autonomy_text="$_felix_autonomy_text$nl" ;;
    esac
    printf '%s' "$_felix_autonomy_text$want$nl" > "$tmp" || exit 1
    # Written is a status of its own. 2026-10-08, from the lock's third
    # review: bash 3.2 ends a subshell that set -u stops in $(( )) with the
    # status of the command before the stop, which was wc's 0, and a 0 here
    # moved an empty temp file over the grants (felix_autonomy_say). The
    # digits check above is what keeps a stop out; this keeps a 0 from
    # anything else from reading as written. A stop keeps an earlier status
    # only in $(( )), and nothing in this subshell does arithmetic, so none
    # can leave a 10 here; keep it that way, or encode the status as revoke's
    # passes do.
    exit 10
  ) > /dev/null 2>&1; rc=$?
  case "$rc" in 10) rc=0 ;; 0) rc=1 ;; esac
  if [ "$rc" = 0 ]; then
    # mktemp made it 0600: the file's own mode, or the umask's for a new one.
    if [ -e "$f" ]; then mode="$(stat -L -c %a "$f" 2>/dev/null || stat -L -f %Lp "$f" 2>/dev/null)"
    else mode="$(printf '%o' "$(( 0666 & ~0$(umask) ))")"; fi
    [ -z "$mode" ] || chmod "$mode" "$tmp" 2>/dev/null
  fi
  if [ "$rc" != 0 ] || ! mv -f "$tmp" "$f" 2>/dev/null; then
    rm -f "$tmp" 2>/dev/null; _FELIX_AUTONOMY_TMP=""
    [ "$rc" = 2 ] && return 2
    return 1
  fi
  _FELIX_AUTONOMY_TMP=""
  felix_autonomy_allows "$proj" "$want" || return 3
  return 0
}

# One writer at a time.
#
# 2026-10-08, from the adversarial review of the revoke fix: nothing held the
# file while felix autonomy rewrote it. Run A (--revoke commission) read it,
# then run B (--revoke tidy) read, rewrote, moved, read back, and said
# "revoked: tidy". Then A's move landed A's copy, which still held tidy. tidy
# is the grant that deletes files at session start. A revoke racing an
# --allow lost the allow's line under its move the same way. main's
# `grep -vxF > autonomy.new && mv` had the same unlocked read-modify-write, so
# this predates the revoke fix.
#
# So every writer holds one lock per project, from its first read to its last
# write and read-back. That covers the grant file and its stamps. The lock is
# the directory <proj>/autonomy.lock, because mkdir is atomic everywhere and a
# lock file is not. Readers take nothing: a rewrite lands by rename, so a
# reader sees the old file or the new one.
#
# A held lock is never taken over, unlike felix_commission_lock's. This one
# guards a permission, and takeover is the window in which two takers both see
# a stale lock and both write: the race the lock exists to close. A lock left
# by a killed run therefore refuses every later write until a person removes
# it, and the refusal says how.
#
# Nothing is written inside it, so it stays an empty directory, which git
# cannot track. FELIX_ESCAPE_AUTHORITY (escape.sh) matches the name
# projects/<p>/autonomy.lock, and for that reason it never reaches a diff.
#
# The caller takes it, not felix_autonomy_revoke. One lock then spans the
# revoke, the allow and the stamp writes of one command.
#
# 2026-10-08, from the two adversarial reviews of the first version of this:
#
# - bash waits for the foreground step to return only on a signal it traps.
#   On any other signal that is fatal by default, it ends at once and runs the
#   EXIT trap while a child's mv is still in flight. ALRM from a timeout
#   wrapper did exactly that, and a revoked tidy came back. So every such
#   signal is trapped.
# - A signal between the mkdir and the record of what it made left the lock
#   behind. While the lock is being taken, a signal is therefore only noted,
#   and acted on once the record exists.
# - A second signal during the release cut it short. The release ignores them
#   all first.
# - The release named the lock through a command substitution. On bash 3.2, a
#   failed write to a closed pipe leaves its text in the stdout buffer, and a
#   substitution's child captured it, so the rmdir was handed a path that did
#   not exist and the lock leaked. The path is now kept in a variable.
# - A run whose lock a person removed went on to remove the next run's lock at
#   its exit. A run now removes only the directory it made, by inode.
#
# 2026-10-08, from the second review, of revision 2:
#
# - The signals that wait were those bash treats as ordinary terminations.
#   bash also ends at once on ABRT, TRAP, SYS and EMT once an EXIT trap is set,
#   with a child still in flight. These now wait too. EMT exists on macOS and
#   not on Linux, so every trap here drops the name a platform lacks, in
#   silence. A fatal signal bash does not handle at all (IO, PWR and STKFLT
#   on Linux) kills it outright: the mv lands and the lock stays, so the
#   next run refuses. A leak, never a regrant.
# - ILL, FPE, BUS and SEGV were ignored. The third review undid that (below).
# - A signal pending as the EXIT trap started ran its handler first. Its exit
#   then cut the trap short, and the lock leaked. The handler releases before
#   it exits now. The release clears what it released, so a second call is
#   empty.
# - mktemp runs with the signals ignored, like mkdir. A Ctrl-C between its
#   making the file and the name reaching the shell would leave the file.
# - On Linux, a freed inode number can come straight back. So the run keeps
#   the lock directory open until it has removed it: an open directory's
#   inode cannot be reused, even after a person's rmdir.
# - A release that find could not carry out says so, instead of leaving the
#   lock in silence.
#
# 2026-10-08, from the third review, of revision 3:
#
# - An ignored signal is inherited. With ILL, FPE, BUS and SEGV ignored, a
#   child that really faulted spun on macOS instead of dying, and the run
#   hung holding the lock. They are trapped now, like the rest: a trapped
#   signal is reset in every child. They are never ignored here, not even
#   around mkdir, so a child's fault ends the child. Not when whoever started
#   felix ignored them: bash cannot trap a signal ignored at entry, and a
#   child that faults then spins with the lock held, as before (the fourth
#   review). A real fault in bash itself would re-run under the handler and
#   hang the run; that is reasoned, not measured.
# - fd 9 was taken whatever it held. A caller's flock on fd 9 (flock(1)'s own
#   example) was let go the moment the lock was made. The run now keeps the
#   lock open on the first of fds 9 to 3 that it did not inherit, and on none
#   if it inherited them all.
#
# 2026-10-08, from revoke's seventh review, which found a caller's IFS
# splitting an unquoted $(( )): every use of these two lists sets IFS to a
# space where it splits them. Under a library caller's IFS with no space in
# it ('2', the digits, a tab), the guard took the lock and set no trap at all.
# felix itself never runs with one: bash ignores an IFS in the environment.
FELIX_AUTONOMY_SIGNALS='HUP INT QUIT PIPE ALRM TERM USR1 USR2 XCPU XFSZ VTALRM PROF ABRT TRAP SYS EMT'
FELIX_AUTONOMY_FAULTS='ILL FPE BUS SEGV'

felix_autonomy_lock_path() { printf '%s/autonomy.lock' "$1"; }

# proj -> 0 taken; 1 held, a directory is there; 2 not taken, and something
# other than a lock directory is at the name, or the project is not writable.
# On 0, _felix_autonomy_lock_dir and _felix_autonomy_lock_ino say what was
# made, and _felix_autonomy_lock_fd the fd that holds it open. The inode is
# read here, before anything is printed, so the substitution has nothing
# stale to capture.
#
# mkdir and ls run with the guarded signals ignored, which they inherit. A
# Ctrl-C reaches the whole process group, and a mkdir it killed after making
# the directory would report failure. The run would then take its own lock
# for another's, and leave it behind. The shell's own traps still note the
# signal.
felix_autonomy_lock() {
  local lock="$1/autonomy.lock" out fd
  _felix_autonomy_lock_dir=""; _felix_autonomy_lock_ino=""; _felix_autonomy_lock_fd=""
  if ( IFS=' '; trap '' $FELIX_AUTONOMY_SIGNALS 2>/dev/null; exec mkdir "$lock" ) 2>/dev/null; then
    _felix_autonomy_lock_dir="$lock"
    # '<&fd' fails only on an fd that is not open. bash 3.2 has no {fd}, so
    # the number goes through eval, and it is one of these seven digits.
    for fd in 9 8 7 6 5 4 3; do
      { : <&"$fd"; } 2>/dev/null && continue
      eval "{ exec $fd<\"\$lock\"; } 2>/dev/null" && _felix_autonomy_lock_fd="$fd"
      break
    done
    out="$( IFS=' '; trap '' $FELIX_AUTONOMY_SIGNALS 2>/dev/null; exec ls -di "$lock" 2>/dev/null )"
    out="${out#"${out%%[! ]*}"}"; out="${out%% *}"
    case "$out" in ''|*[!0123456789]*) ;; *) _felix_autonomy_lock_ino="$out" ;; esac
    return 0
  fi
  [ -d "$lock" ] && [ ! -L "$lock" ] && return 1
  return 2
}

# lock-dir [inode]: remove the lock, and only while it is the directory this
# run made, still empty. rmdir, never rm -r: what was put inside it was not
# put there by this run, and is left for a person, who is told. A lock that
# is another run's now is left in silence.
felix_autonomy_unlock() {
  local lock="$1" ino="${2:-}" rc=0
  [ -n "$lock" ] && [ -d "$lock" ] && [ ! -L "$lock" ] || return 0
  if [ -z "$ino" ]; then
    rmdir "$lock" 2>/dev/null \
      || printf 'felix: the lock %s was not removed: something is inside it. Look at what is there, then remove it once no felix autonomy is running or stopped.\n' "$lock" >&2
    return 0
  fi
  find "$lock" -maxdepth 0 -type d -inum "$ino" -empty -exec rmdir {} \; 2>/dev/null || rc=1
  [ -d "$lock" ] && [ ! -L "$lock" ] || return 0
  if [ "$rc" != 0 ]; then
    printf 'felix: the lock %s may not have been removed: it could not be read. If no felix autonomy is running or stopped, remove it.\n' "$lock" >&2
    return 0
  fi
  # stdout to stderr first, then find's own errors away.
  find "$lock" -maxdepth 0 -type d -inum "$ino" \
    -exec printf 'felix: the lock %s was not removed: something was put inside it while this run held it. Look at what is there, then remove it once no felix autonomy is running or stopped.\n' {} \; >&2 2>/dev/null
  return 0
}

# Signals off for what is left: the asynchronous ones ignored, which the
# release's children inherit, and the faults caught and dropped, which they
# do not.
_felix_autonomy_hush() {
  local IFS=' '
  trap '' $FELIX_AUTONOMY_SIGNALS 2>/dev/null
  trap : $FELIX_AUTONOMY_FAULTS
}

# The release, as the EXIT trap of a run that may hold the lock: the temporary
# file of a rewrite cut short, then the lock, then the fd that held its inode.
# Nothing in it substitutes a command, for the reason above, and it clears
# what it released, so calling it twice does nothing the second time.
_felix_autonomy_release() {
  _felix_autonomy_hush
  [ -z "${_FELIX_AUTONOMY_TMP:-}" ] || rm -f "$_FELIX_AUTONOMY_TMP" 2>/dev/null
  _FELIX_AUTONOMY_TMP=""
  [ -z "${_felix_autonomy_lock_dir:-}" ] \
    || felix_autonomy_unlock "$_felix_autonomy_lock_dir" "${_felix_autonomy_lock_ino:-}"
  _felix_autonomy_lock_dir=""
  case "${_felix_autonomy_lock_fd:-}" in [3456789]) eval "exec $_felix_autonomy_lock_fd<&-" ;; esac
  _felix_autonomy_lock_fd=""
}

# A signal while the lock may be held: the rest off, release, and end as that
# signal would. Each number is Linux's, and EMT's, which Linux lacks, is
# macOS's. USR1, USR2, SYS and BUS have other numbers on macOS. Nothing reads
# them.
_felix_autonomy_signalled() {   # SIG
  local n=0
  _felix_autonomy_hush
  _felix_autonomy_release
  case "$1" in
    HUP) n=1 ;; INT) n=2 ;; QUIT) n=3 ;; ILL) n=4 ;; TRAP) n=5 ;; ABRT) n=6 ;;
    BUS) n=7 ;; EMT) n=7 ;; FPE) n=8 ;; USR1) n=10 ;; SEGV) n=11 ;; USR2) n=12 ;;
    PIPE) n=13 ;; ALRM) n=14 ;; TERM) n=15 ;; XCPU) n=24 ;; XFSZ) n=25 ;;
    VTALRM) n=26 ;; PROF) n=27 ;; SYS) n=31 ;;
  esac
  exit "$((128 + n))"
}

# The caller's whole hold, in one call: traps, then the lock. Same codes as
# felix_autonomy_lock. Signals while it is taken are noted, then acted on.
felix_autonomy_guard() {   # proj
  local s rc IFS=' '
  # Anything a printf before this left in bash 3.2's stdout buffer goes to
  # /dev/null now, before the lock's ls substitution could take it for the
  # inode (felix_autonomy_grant says why only the '%s' form flushes).
  printf '%s' '' > /dev/null 2>&1
  _FELIX_AUTONOMY_CAUGHT=""; _FELIX_AUTONOMY_TMP=""
  _felix_autonomy_lock_dir=""; _felix_autonomy_lock_ino=""; _felix_autonomy_lock_fd=""
  for s in $FELIX_AUTONOMY_SIGNALS $FELIX_AUTONOMY_FAULTS; do
    trap "_FELIX_AUTONOMY_CAUGHT=$s" "$s" 2>/dev/null
  done
  trap _felix_autonomy_release EXIT
  felix_autonomy_lock "$1"; rc=$?
  for s in $FELIX_AUTONOMY_SIGNALS $FELIX_AUTONOMY_FAULTS; do
    trap "_felix_autonomy_signalled $s" "$s" 2>/dev/null
  done
  [ -z "$_FELIX_AUTONOMY_CAUGHT" ] || _felix_autonomy_signalled "$_FELIX_AUTONOMY_CAUGHT"
  return "$rc"
}

# A status line from cmd_autonomy, printed by a child.
#
# 2026-10-08, from the third review: bash 3.2 keeps what a failed printf
# could not write in its stdout buffer, and the next command substitution's
# child wrote it into what it captured. A "revoked:" that stdout refused
# (closed, read-only, or a pipe nobody reads with SIGPIPE ignored) went into
# the grant's byte count. set -u then stopped the grant's subshell, bash 3.2
# ended it with the status wc left, 0, and an empty file replaced the grant
# file. A child
# takes a failed write's buffer away with it. Once one line fails, stdout
# goes to /dev/null, so no later line can fail the same way. An exec
# >/dev/null after a failure in the shell itself does not empty the buffer;
# printf '%s' '' > /dev/null does, and the guard and the grant run one first.
felix_autonomy_say() {   # FORMAT [ARG...]
  ( printf "$@" ) 2>/dev/null || exec >/dev/null
}

# Remove lookalike scripts, and only where every check holds.
#
# The checks, in order, each one able to stop the removal on its own:
#
#   1. The project opted in. No file, no removal, however safe it looks.
#   2. Felix holds a file of that exact name for this project, so the copy that
#      matters survives regardless of what happens next.
#   3. Git does not track it. A tracked file is part of the repository's stated
#      contents, and deleting one is a change to the project rather than the
#      removal of a stray — a different and much larger act, whoever is right
#      about which copy is better.
#   4. It is not the declared gate, and does not live inside Felix's own home.
#   5. The backup was written and is readable. Nothing is removed on the
#      strength of a copy nobody confirmed.
#
# Emits one line per removal. Silence means nothing was touched.
felix_tidy_safe() {
  local proj="$1" root="$2" home="$3"
  felix_autonomy_allows "$proj" tidy || return 0

  local gate; gate="$(felix_json_str "$proj/project.json" gate 2>/dev/null)"
  local rivals; rivals="$(_felix_rival_gates "$root" "$proj" "$gate" 2>/dev/null)"
  [ -n "$rivals" ] || return 0

  local state f note base backup
  while IFS=$'\t' read -r state f note; do
    [ -n "${f:-}" ] || continue
    # 3. Tracked stays. _felix_rival_gates reports both, and only one of them
    #    is a stray file somebody left behind.
    [ "${state:-}" = "untracked" ] || continue
    base="${f##*/}"
    # 2. Felix holds the copy that matters.
    [ -f "$proj/$base" ] || continue
    # 4. Never the gate, never Felix's own storage.
    [ "$root/$f" -ef "$proj/$gate" ] 2>/dev/null && continue
    # The same repository test as the reporter, and it matters more here. A
    # prefix match against the home is true only when standing in the home, so
    # from a worktree of Felix this guard lapsed entirely — on the one path in
    # the system that deletes. Guard 3 above still held it back (Felix's stored
    # files are tracked, and only untracked ones are removed), so nothing was
    # ever lost; a defence that only works from one directory is not a defence.
    case "$f" in
      projects/*) felix_same_repo "$root" "${home:-/nonexistent}" && continue ;;
    esac

    # 5. Copy first, confirm the copy, then remove. A backup nobody checked is
    #    the same as no backup at the moment it turns out to matter.
    mkdir -p "$home/state/rivals" 2>/dev/null || continue
    backup="$home/state/rivals/$(basename "$proj")-$(printf '%s' "$f" | tr '/' '-')"
    cp "$root/$f" "$backup" 2>/dev/null || continue
    [ -s "$backup" ] || [ ! -s "$root/$f" ] || continue

    rm -f "$root/$f" 2>/dev/null || continue
    printf '%s\n' "$f"
  done <<EOF
$rivals
EOF
}
