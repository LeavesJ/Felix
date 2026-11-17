# tests/lib/trust-step4.sh: what parts 2186 to 2189 share (trust-plane step 4, slice 1; blind). Definitions only
# (contract C2): sourcing this file defines functions and nothing else, and every variable they use is set by
# _ts4_begin when a part calls it. Written from spec-slice1.md (rev 3) alone, with no implementation in view: the
# commands are driven as black boxes, the door through its standard input and output, and the store is read with
# git, as section 0 and D9 of the spec say it is laid out (a bare repository, refs/heads/main, refs/felix/door).
#
# Every file these write is under $TS4, which _ts4_begin makes as $TMP/<the part's own name>. Every felix call is
# given FELIX_AUTHORITY_HOME, runs in $TS4/t with SSH_CONNECTION and SSH_TTY unset (D1 would refuse the door under a
# session reached over ssh), and ends after TS4_LIMIT seconds at the latest (perl's alarm, kept across the exec).
# A door that must be answered after its card is read gets a FIFO for input, held open read-write on fd 7 (slot a)
# or fd 8 (slot b) so no write blocks or breaks, and is ended by its own pid when it outlasts TS4_WAIT seconds; after
# that TS4_STUCK stops every later door of the part, so a door that hangs costs one wait and not one a case.
# What a door printed is kept twice: door.SLOT.raw as it printed it, and door.SLOT.out with D5a's folding undone,
# which is what the readers below are given. Each door's rows are also added to $TS4/doors.raw.
# TS4_HAVE is settled by the part's first init: when that fails (as on a base with no felix authority), no later
# felix call is made, each reads as status "down", and the part ends in seconds with its assertions failed.
# TS4_SKIP, when a part sets it, does the same and turns every _ts4_is into a skip under the assertion's own name.

_ts4_begin() {   # NAME: the part's fixture root $TMP/NAME, this login, and the state the helpers below keep
  TS4="$TMP/$1"; rm -rf "${TS4:?}"; mkdir -p "$TS4/t" "$TS4/x"; TS4="$(cd "$TS4" && pwd -P)"
  TS4_ME="$(id -un 2>/dev/null)"; TS4_HAVE=""; TS4_WHY=""; TS4_SKIP=""; TS4_RC=""; TS4_ID=""; TS4_C=""; TS4_M1=""; TS4_M2=""
  TS4_PA=""; TS4_PB=""; TS4_DRC=""; TS4_KEPT=""; TS4_KEPTL=""; TS4_CONF=""; TS4_AT=""; TS4_FOUR=""; TS4_HEAD=""; TS4_STUCK=""
  TS4_ASKS=0; TS4_PLACES=""; TS4_ENV=(); TS4_LIMIT=120; TS4_WAIT=90; TS4_TTL=100; TS4_UMASK=022; TS4_DEC=""; TS4_BODY=""
  TS4_IDLE=""; TS4_BUSY=""; TS4_PS=no; TS4_NL=$'\n'; TS4_TAB=$'\t'; TS4_ESC=$'\033'; TS4_CR=$'\r'; TS4_C1=$'\302\233'
  TS4_NOPE=0123456789abcdef0123456789abcdef01234567; TS4_KIND=""; TS4_NPLACES=""; TS4_DARG=(); TS4_LOCK=""; : > "$TS4/doors.raw"
  _ts4_path
}
_ts4_path() {   # -> TS4_PATH, the PATH every felix call here is given (W6 e, case 22): the system's own directories of programs,
                # and before them $TS4/bin, made here at mode 755, with a link to each of git, perl, awk, sed, ps and id that
                # those directories lack. W6 e reads each directory PATH names and each program in one, and the PATH a suite
                # is started with need not be out of a worker's reach (a package manager's directory may be a group's to
                # write): a standing that hung on that would say nothing of the code under test
  local d t p clean=""
  for d in /usr/bin /bin /usr/sbin /sbin; do
    [ -d "$d" ] && [ ! -L "$d" ] || continue
    clean="${clean:+$clean:}$d"
  done
  for t in git perl awk sed ps id; do
    _ts4_which "$t" "$clean" >/dev/null && continue
    p="$(_ts4_which "$t" "$PATH")" || continue
    case "$p" in /*) mkdir -p "$TS4/bin" && chmod 755 "$TS4/bin" && ln -s "$p" "$TS4/bin/$t" 2>/dev/null ;; esac
  done
  [ ! -d "$TS4/bin" ] || clean="$TS4/bin${clean:+:$clean}"
  TS4_PATH="${clean:-$PATH}"
}
_ts4_which() {   # TOOL [PATH]: the first executable file named TOOL in the directories of PATH (of TS4_PATH when none is given)
  local d IFS=:
  for d in ${2-$TS4_PATH}; do
    if [ -n "$d" ] && [ -f "$d/$1" ] && [ -x "$d/$1" ]; then printf '%s\n' "$d/$1"; return 0; fi
  done
  return 1
}
_ts4_end() {   # a door still running is ended by its own pid, the fixture is removed, and the names set above are unset
  local p
  for p in "$TS4_PA" "$TS4_PB"; do [ -z "$p" ] || { kill "$p"; wait "$p"; } 2>/dev/null; done
  _ts4_fd a close; _ts4_fd b close
  chmod -R u+rwx "$TS4" 2>/dev/null; rm -rf "${TS4:?}"
  unset TS4 TS4_ME TS4_HAVE TS4_WHY TS4_SKIP TS4_RC TS4_ID TS4_C TS4_M1 TS4_M2 TS4_PA TS4_PB TS4_DRC TS4_KEPT TS4_KEPTL TS4_CONF \
    TS4_AT TS4_FOUR TS4_HEAD TS4_STUCK TS4_ASKS TS4_PLACES TS4_ENV TS4_LIMIT TS4_WAIT TS4_TTL TS4_UMASK TS4_DEC TS4_BODY TS4_IDLE \
    TS4_BUSY TS4_PS TS4_NL TS4_TAB TS4_ESC TS4_CR TS4_C1 TS4_NOPE TS4_KIND TS4_NPLACES TS4_DARG TS4_LOCK TS4_PATH
}

# ---- assertions and what a failure shows
_ts4_is() {   # NAME GOT WANT [DETAIL]: skipped under its own name while TS4_SKIP says why
  if [ -n "$TS4_SKIP" ]; then skip "$1" "$TS4_SKIP"; elif [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]${4:+: $4}"; fi
}
_ts4_flat() { LC_ALL=C tr '\n\t' ' |' | LC_ALL=C tr -c '\40-\176' '?'; }   # stdin as one printable line
_ts4_why() { printf 'exit %s; out: %s; err: %s' "$TS4_RC" "$(head -c 700 "$TS4/o" 2>/dev/null | _ts4_flat)" "$(head -c 300 "$TS4/e" 2>/dev/null | _ts4_flat)"; }
_ts4_dwhy() {   # [SLOT]: the end of what that door printed
  printf 'exit %s; out: ...%s; err: %s' "$TS4_DRC" "$(tail -c 900 "$TS4/door.${1:-a}.out" 2>/dev/null | _ts4_flat)" "$(head -c 300 "$TS4/door.${1:-a}.err" 2>/dev/null | _ts4_flat)"
}
_ts4_yn() { if "$@" >/dev/null 2>&1; then printf yes; else printf no; fi; }   # COMMAND...: yes when it succeeds
_ts4_said() {   # TEXT FILE...: yes when a line of a FILE holds TEXT
  T="$1" LC_ALL=C awk 'index($0, ENVIRON["T"]) { f = 1 } END { print (f ? "yes" : "no") }' "${@:2}" 2>/dev/null
}
_ts4_count() {   # PREFIX FILE: how many lines of FILE begin with PREFIX
  P="$1" LC_ALL=C awk 'index($0, ENVIRON["P"]) == 1 { n++ } END { print n + 0 }' "$2" 2>/dev/null
}
_ts4_line() {   # PREFIX FILE [N]: the Nth (first) line of FILE that begins with PREFIX, whole
  P="$1" LC_ALL=C awk -v n="${3:-1}" 'index($0, ENVIRON["P"]) == 1 && ++k == n { print }' "$2" 2>/dev/null
}
_ts4_esc() {   # STRING -> it shown escaped as the spec's section 0 says: \xNN for a byte outside 0x20-0x7e, \ and ", in quotes
  printf '%s' "$1" | LC_ALL=C od -An -v -tx1 | LC_ALL=C awk '
    BEGIN { printf "\"" }
    { for (i = 1; i <= NF; i++) { n = (index("0123456789abcdef", substr($i, 1, 1)) - 1) * 16 + index("0123456789abcdef", substr($i, 2, 1)) - 1
        if (n < 32 || n > 126 || n == 92 || n == 34) printf "\\x%s", $i; else printf "%c", n } }
    END { printf "\"\n" }'
}
_ts4_snap() {   # DIR...: every path under each with each file's checksum, or "absent": what a refusal must leave as it was
  local d
  for d in "$@"; do
    if [ ! -e "$d" ] && [ ! -L "$d" ]; then printf 'absent\n'; continue; fi
    ( cd "$d" 2>/dev/null && { find . -print | LC_ALL=C sort; find . -type f -exec cksum {} + | LC_ALL=C sort; } ) 2>/dev/null
  done
}
_ts4_mode() { ls -ld "$1" 2>/dev/null | cut -c1-10; }   # PATH -> its type and mode as ls prints them
_ts4_rows() { if [ -f "$1" ]; then LC_ALL=C awk 'END { print NR }' "$1"; else printf '0\n'; fi; }   # FILE -> its rows, 0 when it is not there
_ts4_unfold() {   # FILE -> its rows with D5a's folding undone: a row that starts with four spaces, a bar and a space continues the row before it
  LC_ALL=C awk 'NR > 1 && index($0, "    | ") == 1 { l = l substr($0, 7); next } NR > 1 { print l } { l = $0 } END { if (NR) print l }' "$1" 2>/dev/null
}
_ts4_numon() {   # PREFIX N FILE: yes when a line of FILE that starts with PREFIX holds the number N, as a number of its own: a run of
                 # hex digits that holds a letter, or is seven digits long or longer, is an id or a piece of one and is not read
  K="$1" N="$2" LC_ALL=C awk 'index($0, ENVIRON["K"]) == 1 { l = substr($0, length(ENVIRON["K"]) + 1); o = ""
      while (match(l, /[0123456789abcdef]+/)) { r = substr(l, RSTART, RLENGTH)
        o = o substr(l, 1, RSTART - 1) ((r ~ /[abcdef]/ || RLENGTH >= 7) ? " " : r); l = substr(l, RSTART + RLENGTH) }
      o = o l
      if (ENVIRON["N"] != "" && (" " o " ") ~ ("[^0123456789]" ENVIRON["N"] "[^0123456789]")) f = 1 }
    END { print (f ? "yes" : "no") }' "$3" 2>/dev/null
}

# ---- the commands
_ts4_x() {   # HOME STDIN WORD...: felix WORD... for that authority's home; stdout in $TS4/o, stderr in $TS4/e, status in TS4_RC
  local ah="$1" in="$2"; shift 2
  : > "$TS4/o"; : > "$TS4/e"
  if [ "$TS4_HAVE" = no ] || [ -n "$TS4_SKIP" ]; then printf 'not run: %s\n' "${TS4_SKIP:-$TS4_WHY}" > "$TS4/e"; TS4_RC=down; return 1; fi
  { ( umask "$TS4_UMASK"; cd "$TS4/t" || exit 97
      exec env -u SSH_CONNECTION -u SSH_TTY PATH="$TS4_PATH" FELIX_AUTHORITY_HOME="$ah" FELIX_DOOR_TTL="$TS4_TTL" ${TS4_ENV[@]+"${TS4_ENV[@]}"} \
        perl -e 'alarm shift; exec @ARGV' "$TS4_LIMIT" "$FELIX" "$@" ) < "$in" > "$TS4/o" 2> "$TS4/e" 7>&- 8>&-
    TS4_RC=$?; } 2>/dev/null   # the shell's own word on a call the alarm ended is not the suite's to print
}
_ts4_a() { local ah="$1"; shift; _ts4_x "$ah" /dev/null authority "$@"; }   # HOME ARG...: felix authority ARG...
_ts4_init() {   # HOME WORKERS SOURCE [ARG...]: felix authority init for this login; TS4_ID is the one id it printed
  local ah="$1" w="$2" s="$3"; shift 3
  _ts4_a "$ah" init --user "$TS4_ME" --workers "$w" --source "$s" "$@"
  TS4_ID="$(_ts4_hex40 < "$TS4/o" | LC_ALL=C sort -u)"
  [ -z "$TS4_HAVE" ] || return 0
  if [ "$TS4_RC" = 0 ] && [ "${#TS4_ID}" -eq 40 ] && [ -f "$ah/authority.conf" ]; then TS4_HAVE=yes
  else TS4_HAVE=no; TS4_WHY="felix authority init did not make an authority here (exit $TS4_RC: $(head -c 200 "$TS4/e" | _ts4_flat))"; fi
}
_ts4_hex40() {   # stdin -> each run of exactly 40 lowercase hex digits in it, one a line
  LC_ALL=C awk '{ n = split($0, w, /[^0123456789abcdef]+/); for (i = 1; i <= n; i++) if (length(w[i]) == 40) print w[i] }'
}
_ts4_conf() {   # HOME KEY [VALUE]: the row KEY of that home's authority.conf holds VALUE, or is gone when no VALUE is given
  local f="$1/authority.conf"
  [ -f "$f" ] || return 1
  K="$2" LC_ALL=C awk -F'\t' '$1 != ENVIRON["K"]' "$f" > "$TS4/x/conf.new"
  [ "$#" -lt 3 ] || printf '%s\t%s\n' "$2" "$3" >> "$TS4/x/conf.new"
  cat "$TS4/x/conf.new" > "$f"; rm -f "$TS4/x/conf.new"
}

# ---- what status, a tick and decide printed last
_ts4_keys() { LC_ALL=C awk '{ i = index($0, ": "); printf "%s ", (i ? substr($0, 1, i - 1) : "?" $0) }' "$TS4/o"; }   # each line's key
_ts4_sv() {   # KEY: the value of each line "KEY: value" of the last output, joined by |
  K="$1: " LC_ALL=C awk 'index($0, ENVIRON["K"]) == 1 { printf "%s%s", (n++ ? "|" : ""), substr($0, length(ENVIRON["K"]) + 1) }' "$TS4/o"
}
_ts4_whys() {   # the why lines of the last status as the letters of W6's conditions, and ? for a line that holds none of their
                # words: a, b (which is also what e says), c and d, each followed by xN when N lines say it
  LC_ALL=C awk 'index($0, "why: ") == 1 { w = "?"
      if (index($0, "not its own login")) w = "a"; else if (index($0, "not the authority\047s alone")) w = "b"
      else if (index($0, "no first start at the console")) w = "c"; else if (index($0, "the reach test has not passed")) w = "d"
      s[w]++ }
    END { n = split("a b c d ?", o, " "); for (i = 1; i <= n; i++) if (s[o[i]]) printf "%s%s", o[i], (s[o[i]] > 1 ? "x" s[o[i]] : "") }' "$TS4/o"
}
_ts4_cands() {   # how many candidate lines the last output holds: five tab-separated fields, the third a commit id
  LC_ALL=C awk -F'\t' 'NF == 5 && length($3) == 40 && $3 !~ /[^0123456789abcdef]/ { n++ } END { print n + 0 }' "$TS4/o"
}
_ts4_of() {   # H: "decision|detail" of H's candidate line in the last output, or "no line"
  LC_ALL=C awk -F'\t' -v h="$1" 'NF == 5 && $3 == h && !f { print $2 "|" $5; f = 1 } END { if (!f) print "no line" }' "$TS4/o"
}
_ts4_dd() { _ts4_a "$1" decide "$2"; TS4_DEC="$(_ts4_of "$2")"; }   # HOME H: felix authority decide H -> TS4_DEC, as _ts4_of reads it
_ts4_paused() {   # WORDS: yes when a line the last call printed, on either stream, holds paused and WORDS
  T="$1" LC_ALL=C awk 'index($0, "paused") && index($0, ENVIRON["T"]) { f = 1 } END { print (f ? "yes" : "no") }' "$TS4/o" "$TS4/e"
}
_ts4_ledger() { _ts4_rows "$1/ledger.tsv"; }   # HOME -> the rows of its ledger
_ts4_closed() { _ts4_rows "$1/door/refused.tsv"; }   # HOME -> the rows of refused.tsv in its door's directory (D6)
_ts4_lrow() {   # HOME H: the last ledger row for H, without its time: standing|decision|H|B|T|detail, with the field count first
  LC_ALL=C awk -F'\t' -v h="$2" '$4 == h { r = NF ":" $2 "|" $3 "|" $4 "|" $5 "|" $6 "|" $7 } END { print (r == "" ? "no row" : r) }' "$1/ledger.tsv" 2>/dev/null
}

# ---- the store, read with git
_ts4_sg() { local st="$1"; shift; [ -d "$st" ] || return 1; _fx_git "$st" "$@" 2>/dev/null; }   # STORE ARG...: git ARG... there
_ts4_n() { _ts4_sg "$1/store.git" rev-list --count refs/felix/door 2>/dev/null || printf '0\n'; }   # HOME -> how many statements its log holds
_ts4_tip() { _ts4_sg "$1/store.git" rev-parse -q --verify refs/felix/door; }   # HOME -> the log's last entry
_ts4_main() { _ts4_sg "$1/store.git" rev-parse -q --verify refs/heads/main || printf 'none\n'; }   # HOME -> main in its store
_ts4_rev() { _ts4_sg "$1/store.git" rev-list --reverse refs/felix/door | LC_ALL=C awk -v n="$2" 'NR == n + 1'; }   # HOME N -> statement N's commit
_ts4_msg() { _ts4_sg "$1/store.git" cat-file commit "$2" | LC_ALL=C awk 'b { print } !b && $0 == "" { b = 1 }'; }   # HOME REV -> its message
_ts4_fs() {   # HOME N "KEY KEY...": those fields of statement N as the log holds it, joined by |
  local r; r="$(_ts4_rev "$1" "$2")"; [ -n "$r" ] || { printf 'no statement %s' "$2"; return 1; }
  _ts4_msg "$1" "$r" | K="$3" LC_ALL=C awk '{ i = index($0, ": "); if (i) v[substr($0, 1, i - 1)] = substr($0, i + 2) }
    END { n = split(ENVIRON["K"], k, " "); for (j = 1; j <= n; j++) printf "%s%s", (j > 1 ? "|" : ""), ((k[j] in v) ? v[k[j]] : "(none)") }'
}
_ts4_lr() {   # N: fields 1 to 6 of row N of the last output, felix authority log's, joined by |, with the field count first
  LC_ALL=C awk -F'\t' -v n="$1" '$1 == n { printf "%s:%s|%s|%s|%s|%s|%s", NF, $1, $2, $3, $4, $5, $6; f = 1 } END { if (!f) printf "no row" }' "$TS4/o"
}

# ---- the door
_ts4_fd() {   # SLOT open FIFO | put LINE | close: the write end of that door's input
  case "$1.$2" in
    a.open) exec 7<>"$3" ;; b.open) exec 8<>"$3" ;;
    a.put) printf '%s\n' "$3" >&7 ;; b.put) printf '%s\n' "$3" >&8 ;;
    a.close) exec 7>&- ;; b.close) exec 8>&- ;;
  esac 2>/dev/null
}
_ts4_pid() { case "$1" in a) TS4_PA="$2" ;; *) TS4_PB="$2" ;; esac; }
_ts4_card() {   # FILE: its last line "confirm: <an id, or the word nonce and a nonce, with two pairs of its characters in square
                # brackets>" (D6), into TS4_CONF, TS4_KIND (id or nonce), TS4_AT (the two places, from 0, as P,Q), TS4_FOUR (the
                # two pairs in order) and TS4_HEAD (the id or the nonce without its brackets); 1 while no such whole line is there
  local l c="" k=id n=40 a p b q z
  [ -f "$1" ] || return 1
  while IFS= read -r l || [ -n "$l" ]; do case "$l" in "confirm: "*) c="${l#confirm: }" ;; esac; done < "$1"
  case "$c" in "nonce "*) k=nonce; n=32; c="${c#nonce }" ;; esac
  case "$c" in *"["??"]"*"["??"]"*) ;; *) return 1 ;; esac
  a="${c%%\[*}"; z="${c#*\[}"; p="${z%%\]*}"; z="${z#*\]}"; b="${z%%\[*}"; z="${z#*\[}"; q="${z%%\]*}"; z="${z#*\]}"
  [ "${#p}" -eq 2 ] && [ "${#q}" -eq 2 ] && [ "$(( ${#a} + ${#b} + ${#z} + 4 ))" -ge "$n" ] || return 1
  TS4_CONF="$c"; TS4_KIND="$k"; TS4_AT="${#a},$(( ${#a} + 2 + ${#b} ))"; TS4_FOUR="$p$q"; TS4_HEAD="$a$p$b$q$z"
}
_ts4_onid() {   # ID: yes when the two pairs the last card bracketed are ID's own characters at their places, and the places are
                # where D6 puts them: for an id from 0 to 18 and from 20 to 38, for a nonce from 0 to 14 and from 16 to 30
  local id="$1" a="${TS4_AT%,*}" b="${TS4_AT#*,}" m=18 l=20 h=38
  [ "$TS4_KIND" != nonce ] || { m=14; l=16; h=30; }
  case "$a$b" in ""|*[!0123456789]*) printf no; return 0 ;; esac
  if [ "${#TS4_FOUR}" -eq 4 ] && [ "$TS4_FOUR" = "${id:$a:2}${id:$b:2}" ] && [ "$a" -le "$m" ] && [ "$b" -ge "$l" ] && [ "$b" -le "$h" ]; then printf yes; else printf no; fi
}
_ts4_wrong() {   # ID -> four characters that confirm nothing about ID wherever the brackets stand: a pair ID does not hold, twice
  local a b
  for a in 0 1 2 3 4 5 6 7 8 9 a b c d e f; do for b in 0 1 2 3 4 5 6 7 8 9 a b c d e f; do
    case "$1" in *"$a$b"*) ;; *) printf '%s%s%s%s' "$a" "$b" "$a" "$b"; return 0 ;; esac
  done; done
  printf 'zzzz'
}
_ts4_keptl() {   # FILE: its last line "kept: statement N ..." into TS4_KEPTL, and N into TS4_KEPT
  local l; TS4_KEPT=""; TS4_KEPTL=""
  [ -f "$1" ] || return 1
  while IFS= read -r l || [ -n "$l" ]; do case "$l" in "kept: statement "*) TS4_KEPTL="$l" ;; esac; done < "$1"
  l="${TS4_KEPTL#kept: statement }"; l="${l%% *}"
  case "$l" in ""|*[!0123456789]*) return 1 ;; esac
  TS4_KEPT="$l"
}
_ts4_await() {   # SLOT card|end: at most TS4_WAIT seconds for that door's confirm line, or for its end (then its status is TS4_DRC)
  local s="$1" f="$TS4/door.$1" pid t0="$SECONDS"
  case "$s" in a) pid="$TS4_PA" ;; *) pid="$TS4_PB" ;; esac
  [ -n "$pid" ] || return 1
  { while :; do
      if [ "$2" = card ] && _ts4_card "$f.raw"; then _ts4_unfold "$f.raw" > "$f.out"; return 0; fi
      kill -0 "$pid" || break
      if [ "$(( SECONDS - t0 ))" -ge "$TS4_WAIT" ]; then
        TS4_STUCK="a door printed nothing more for $TS4_WAIT s and was ended by its pid"
        kill "$pid"; sleep 1; kill -9 "$pid"; break
      fi
      sleep 0.1
    done
    wait "$pid"; TS4_DRC=$?; } 2>/dev/null
  _ts4_pid "$s" ""; _ts4_fd "$s" close
  _ts4_unfold "$f.raw" > "$f.out"; cat "$f.raw" >> "$TS4/doors.raw" 2>/dev/null
  [ "$2" != card ] || _ts4_card "$f.raw"
  return 0
}
_ts4_open() {   # HOME SLOT LINE: a door for that home is started and reads LINE. When this returns, its card is in
                # $TS4/door.SLOT.out and TS4_CONF, TS4_KIND, TS4_AT, TS4_FOUR and TS4_HEAD hold its confirm line, or the door has ended
  local ah="$1" s="$2" f="$TS4/door.$2"
  TS4_CONF=""; TS4_AT=""; TS4_FOUR=""; TS4_HEAD=""; TS4_KIND=""; TS4_DRC=""; TS4_KEPT=""; TS4_KEPTL=""
  rm -f "$f.in"; : > "$f.out"; : > "$f.raw"; : > "$f.err"; _ts4_pid "$s" ""
  if [ "$TS4_HAVE" = no ] || [ -n "$TS4_SKIP$TS4_STUCK" ]; then printf 'not run: %s\n' "${TS4_SKIP:-${TS4_STUCK:-$TS4_WHY}}" > "$f.err"; TS4_DRC=down; return 1; fi
  mkfifo "$f.in" 2>/dev/null || { printf 'not run: mkfifo made no FIFO\n' > "$f.err"; TS4_DRC=down; return 1; }
  ( umask "$TS4_UMASK"; cd "$TS4/t" || exit 97
    exec env -u SSH_CONNECTION -u SSH_TTY PATH="$TS4_PATH" FELIX_AUTHORITY_HOME="$ah" FELIX_DOOR_TTL="$TS4_TTL" ${TS4_ENV[@]+"${TS4_ENV[@]}"} "$FELIX" door ) \
    < "$f.in" > "$f.raw" 2> "$f.err" 7>&- 8>&- &
  _ts4_pid "$s" "$!"
  _ts4_fd "$s" open "$f.in"; _ts4_fd "$s" put "$3"
  _ts4_await "$s" card
  [ -z "$TS4_FOUR" ] || TS4_ASKS=$((TS4_ASKS + 1))
  case "$TS4_KIND" in id) TS4_PLACES="$TS4_PLACES$TS4_AT " ;; nonce) TS4_NPLACES="$TS4_NPLACES$TS4_AT " ;; esac
}
_ts4_close() {   # SLOT [LINE...] | SLOT -wait: each LINE is typed and the input ends, or with -wait nothing is typed and the input
                 # stays open; then the door's end. Its status is TS4_DRC, the statement it kept TS4_KEPT
  local s="$1" pid l; shift
  case "$s" in a) pid="$TS4_PA" ;; *) pid="$TS4_PB" ;; esac
  if [ -n "$pid" ]; then
    if [ "${1:-}" != -wait ]; then for l in "$@"; do _ts4_fd "$s" put "$l"; done; _ts4_fd "$s" close; fi
    _ts4_await "$s" end
  fi
  _ts4_keptl "$TS4/door.$s.out"
}
_ts4_say() {   # HOME LINE: one statement that names a commit, or go, given as the founder would give it: LINE, the card read, then
               # the verb and the four characters its confirm line brackets. What the door printed is in $TS4/door.a.out
  _ts4_open "$1" a "$2"
  if [ -n "$TS4_FOUR" ]; then _ts4_close a "${2%% *} $TS4_FOUR"; else _ts4_close a; fi
}
_ts4_plain() {   # HOME [LINE...]: a door whose whole input is those lines, for a statement confirmed by words known beforehand
                 # or typed with the card unread. TS4_DARG, when a part sets it, is what follows the word door
  local ah="$1"; shift
  : > "$TS4/door.txt"; [ "$#" -eq 0 ] || printf '%s\n' "$@" > "$TS4/door.txt"
  TS4_CONF=""; TS4_AT=""; TS4_FOUR=""; TS4_HEAD=""; TS4_KIND=""
  _ts4_x "$ah" "$TS4/door.txt" door ${TS4_DARG[@]+"${TS4_DARG[@]}"}; TS4_DRC="$TS4_RC"
  cp "$TS4/o" "$TS4/door.a.raw"; _ts4_unfold "$TS4/o" > "$TS4/door.a.out"; cat "$TS4/o" >> "$TS4/doors.raw" 2>/dev/null
  cp "$TS4/e" "$TS4/door.a.err"; _ts4_keptl "$TS4/door.a.out"
}
_ts4_brake() { TS4_DARG=(stop); _ts4_plain "$@"; TS4_DARG=(); }   # HOME [LINE...]: felix door stop, the brake (D13), given those lines
_ts4_refused() { _ts4_yn test "$(( $(_ts4_count 'refused: ' "$TS4/door.${1:-a}.out") + $(_ts4_count 'refused: ' "$TS4/door.${1:-a}.err") ))" -gt 0; }   # [SLOT]

# ---- a source repository, built with plumbing so that a path may hold any byte
_ts4_src() { mkdir -p "$1" && ( _fx_cd "$1" && git init -q --bare -b main && git config gc.auto 0 && git config maintenance.auto false ) >/dev/null 2>&1; }   # DIR: a bare repository
_ts4_tree() { if [ "$2" = - ]; then _fx_git "$1" read-tree --empty; else _fx_git "$1" read-tree "$2"; fi >/dev/null 2>&1; }   # SRC BASE|-: the index is that tree
_ts4_stage() {   # SRC PATH CONTENT: PATH's entry in SRC's index holds CONTENT's bytes
  local b; printf '%s' "$3" > "$TS4/x/blob"; b="$(_fx_git "$1" hash-object -w --no-filters "$TS4/x/blob" 2>/dev/null)"
  _fx_git "$1" update-index --add --cacheinfo "100644,$b,$2" >/dev/null 2>&1
}
_ts4_drop() {   # SRC PATH: PATH's entry leaves SRC's index (through --index-info: a bare repository has no work tree to look in)
  printf '0 0000000000000000000000000000000000000000\t%s\0' "$2" | _fx_git "$1" update-index -z --index-info >/dev/null 2>&1
}
_ts4_seal() {   # SRC BRANCH|- BASE|- SUBJECT|@FILE: the index is committed on BASE and BRANCH is put there; TS4_C is the commit
  local t m="$TS4/x/msg" c
  case "$4" in @*) m="${4#@}" ;; *) printf '%s\n' "$4" > "$m" ;; esac
  t="$(_fx_git "$1" write-tree 2>/dev/null)"
  if [ "$3" = - ]; then c="$(_fx_git "$1" -c user.name=worker -c user.email=worker@example.invalid commit-tree --no-gpg-sign "$t" -F "$m" 2>/dev/null)"
  else c="$(_fx_git "$1" -c user.name=worker -c user.email=worker@example.invalid commit-tree --no-gpg-sign "$t" -p "$3" -F "$m" 2>/dev/null)"; fi
  [ "$2" = - ] || _fx_git "$1" update-ref "refs/heads/$2" "$c" >/dev/null 2>&1
  TS4_C="$c"
}
_ts4_ci() {   # SRC BRANCH|- BASE SUBJECT|@FILE [PATH...]: a commit on BASE in which each PATH holds one new blob (TS4_BODY, or
              # the subject, and a newline), put at BRANCH; with no PATH it changes nothing. TS4_C is the commit
  local src="$1" br="$2" base="$3" sub="$4" b p; shift 4
  _ts4_tree "$src" "$base"
  if [ "$#" -gt 0 ]; then
    printf '%s\n' "${TS4_BODY:-$sub}" > "$TS4/x/blob"; b="$(_fx_git "$src" hash-object -w --no-filters "$TS4/x/blob" 2>/dev/null)"
    for p in "$@"; do printf '100644 %s\t%s\0' "$b" "$p"; done | _fx_git "$src" update-index -z --index-info >/dev/null 2>&1
  fi
  _ts4_seal "$src" "$br" "$base" "$sub"
}
_ts4_f() { _ts4_stage "$1" notes/f "$2${TS4_NL}bravo${TS4_NL}charlie${TS4_NL}${4:-delta}${TS4_NL}echo${TS4_NL}foxtrot${TS4_NL}golf${TS4_NL}$3$TS4_NL"; }   # SRC FIRST LAST [FOURTH]: notes/f, eight lines
_ts4_base() {   # SRC: main there. TS4_M1 holds .felix (the project proj), projects/proj/land.tsv with one founder row
                # (docs/direction\.md), docs/direction.md, docs/note.md and notes/f; TS4_M2, main's head, changes notes/f's last
                # line and adds main/only
  _ts4_tree "$1" -
  _ts4_stage "$1" .felix "proj$TS4_NL"
  _ts4_stage "$1" projects/proj/land.tsv "# how each path lands$TS4_NL$TS4_NL"'docs/direction\.md'"${TS4_TAB}founder$TS4_TAB-$TS4_TAB-$TS4_NL"
  _ts4_stage "$1" docs/direction.md "where this goes$TS4_NL"; _ts4_stage "$1" docs/note.md "a note$TS4_NL"; _ts4_f "$1" alpha hotel
  _ts4_seal "$1" main - 'the base'; TS4_M1="$TS4_C"
  _ts4_f "$1" alpha 'hotel on main'; _ts4_stage "$1" main/only "main's own$TS4_NL"
  _ts4_seal "$1" main "$TS4_M1" 'main moves'; TS4_M2="$TS4_C"
}
_ts4_merge() {   # REPO B H -> the tree git's own merge of H onto B writes there under no configuration of the caller's, or "conflict"
  local o
  o="$( export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 XDG_CONFIG_HOME="$TS4/x/no-config" HOME="$TS4/x/no-config"; unset GIT_CONFIG_COUNT GIT_ATTR_SOURCE
        _fx_git "$1" merge-tree --write-tree "$2" "$3" 2>/dev/null )" || { printf 'conflict\n'; return 1; }
  printf '%s\n' "${o%%$TS4_NL*}"
}
_ts4_ctree() { _fx_git "$1" rev-parse -q --verify "$2^{tree}" 2>/dev/null; }   # REPO COMMIT -> its tree
_ts4_kind() {   # REPO B H -> what git's own merge of H onto B is: conflict, nothing (B's own tree), tree (another), or unread
  local t; t="$(_ts4_merge "$1" "$2" "$3")"
  case "$t" in conflict) printf conflict ;; "") printf unread ;; "$(_ts4_ctree "$1" "$2")") printf nothing ;; *) printf tree ;; esac
}

# ---- the logins of this machine
_ts4_alone() {   # LOGIN: 0 when, as far as a test can tell, W6 e holds here with LOGIN as the one worker. Of the engine's
                 # directory, its felix, its lib and each file there, each directory of TS4_PATH and each program in one, and
                 # the lock in TS4_LOCK with its directory when a part names one: LOGIN owns none, every login can write none,
                 # a group LOGIN is in can write none, and none carries an access-control entry that allows
  local u e=""; u="$(id -u "$1" 2>/dev/null)" || return 1
  [ "$(uname -s 2>/dev/null)" != Darwin ] || e=e
  { ls -ldLn$e "$FROOT/harness" "$FELIX" "$FROOT/harness/lib"; ls -lLn$e "$FROOT/harness/lib"
    [ -z "$TS4_LOCK" ] || ls -ldLn$e "$TS4_LOCK" "$(dirname "$TS4_LOCK")"
    ( IFS=:; for u in $TS4_PATH; do ls -ldLn$e "$u"; ls -lLn$e "$u"; done )
  } 2>/dev/null | U="$u" E="$e" G=" $(id -G "$1" 2>/dev/null) " LC_ALL=C awk '
    $1 ~ /^[-d]/ && NF >= 4 { n++
      if ($3 == ENVIRON["U"]) b++
      if (substr($1, 9, 1) == "w") b++
      if (substr($1, 6, 1) == "w" && index(ENVIRON["G"], " " $4 " ")) b++
      if (ENVIRON["E"] == "" && substr($1, 11, 1) == "+") b++
      next }
    $1 ~ /^[0123456789]+:$/ && index($0, " allow") { b++ }
    END { exit (n && !b) ? 0 : 1 }'
}
_ts4_canstand() {   # HOME LOGIN: status for that home, a store made here whose one worker is LOGIN, another login and not root.
                    # A why line of condition a, b or e there says that on this machine such a store stays in shadow, and
                    # TS4_SKIP is set, as case 22 asks. A status that did not run sets nothing: where there is no such
                    # command the assertions that follow fail, and are not skipped
  local w
  _ts4_a "$1" status; w="$(_ts4_whys)"
  [ "$TS4_RC" = 0 ] && [ -n "$(_ts4_sv standing)" ] || return 0
  case "$w" in
    *a*|*b*) TS4_SKIP="status here gives a store whose one worker is $2 the why lines [$w], so nothing can be given at the console or the desktop on this machine; by this test's own reading of the modes the code it runs is $(if _ts4_alone "$2"; then printf out of; else printf within; fi) that login's reach" ;;
  esac
}
_ts4_logins() {   # -> TS4_PS: yes when ps lists this machine's processes; TS4_IDLE: a login other than this one that runs none;
                  # TS4_BUSY: the login that runs the most and is neither this login nor root (W6 a: with root among the
                  # workers each statement is shadow). Each is one _ts4_alone passes, so that a store made here with it as
                  # the worker can stand by W6 e. A login is empty when none was found
  local uids u n
  TS4_IDLE=""; TS4_BUSY=""; TS4_PS=no
  uids="$TS4_NL$(ps -A -o uid= -o ruid= 2>/dev/null | LC_ALL=C awk '{ c[$1]++; if ($2 != $1) c[$2]++ } END { for (u in c) print c[u], u }' | LC_ALL=C sort -k1,1nr -k2,2n | LC_ALL=C awk '{ print $2 }')$TS4_NL"
  case "$uids" in *"${TS4_NL}0$TS4_NL"*) TS4_PS=yes ;; *) return 1 ;; esac
  for u in $uids; do
    [ "$u" != 0 ] || continue
    n="$(id -un "$u" 2>/dev/null)" || continue
    case "$n" in ""|root|"$TS4_ME"|*[!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-]*) continue ;; esac
    case "$n" in [abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_]*) ;; *) continue ;; esac
    _ts4_alone "$n" || continue
    TS4_BUSY="$n"; break
  done
  for n in nobody daemon bin sys games lp news uucp mail man _uucp _lp _ftp _games _unknown; do
    u="$(id -u "$n" 2>/dev/null)" || continue
    [ -n "$u" ] && [ "$u" != 0 ] && [ "$n" != "$TS4_ME" ] || continue
    case "$uids" in *"$TS4_NL$u$TS4_NL"*) continue ;; esac
    _ts4_alone "$n" || continue
    TS4_IDLE="$n"; break
  done
}
