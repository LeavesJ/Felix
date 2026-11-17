# The founder's door: where he gives one statement to the authority, at the authority's own desktop.
#
# Trust-plane step 4, stage 1, slice 1 (lib/authority.sh says what the slice is; the door design of 2026-11-10,
# section 5, is the door he chose). `felix door` reads back what stands, lists what waits on his word, takes a
# verb and what it is about, prints the statement and the card, takes a typed confirmation, keeps the statement
# as the next entry of the log, and runs the lock. One run gives at most one statement.
#
# NO KEY, NO NETWORK, NOTHING HANDED IN. A statement carries no signature and says so. What stands behind one
# is that this desktop was unlocked and that this code ran there. The door refuses to open under a network
# login. The open statement lives in this process and nowhere else: there is no file a second process could
# write, replace or leave behind, and a second door that keeps a statement first makes this one's keep fail.
#
# THE DOOR WRITES THE STATEMENT (D8). No field comes from outside: the verb is one of eight, the commit is one
# the store holds, the tree is the merge this code made, and what he types is compared with the statement and
# is never read as a field of it.
#
# THE CONFIRMATION (D6) makes the act deliberate (the door design's decision 7). It does not identify the
# commit. There is one try, and the places of the brackets come from the statement's nonce, so they are not
# known before the card: in the no-key run of 2026-11-13 (case VD3; memory root, audits/2026-11-10-trust-door),
# with the brackets in one known place, a worker made a commit whose id agreed with his there in 83,083 tries
# in one run and 26,635 in another. Typed blind, with the card unread, two pairs are one guess in 361 (the
# review of this slice kept a statement on its 31st run when the place was one of 37 and a closed statement
# left nothing behind). So each statement closed for a wrong or missing confirmation leaves a row, the
# read-back counts them, and at the desktop three since the last kept statement close the door until the
# console. `go` is confirmed against the statement's nonce the same way, so a stop is not lifted unread; `stop`
# is the verb alone, and `felix door stop` reaches it with no fetch and no list (D13).
#
# THE CARD (D5). The authority's facts first, each on a line whose label this code wrote. Each founder path is
# listed whole, before any other path and never cut. Each word a worker chose (a path, a branch name, a commit
# subject) is shown escaped and quoted (lib/authority-paths.sh), so no byte of a worker's starts a line or
# moves the cursor. One function, _fdoor_card, makes the card from the store; the terminal is one way to draw
# it (D11).
#
# ROWS (D5a). Every line the door prints goes through _fdoor_p, which folds a line longer than 78 characters
# into rows that each start with the door's own bytes. A worker's word padded with spaces put rows reading
# `counts: yes` and `founder-paths-changed: 0` on an 80-column window, beside the true ones (review F11).
#
# WHAT IS NOT HERE: telling a genuine login window from a drawn one, a signature of his, and a lock known to
# work on this macOS. `lock` is a parameter because how a desktop is locked from bash was not read for this
# system. Where it is unset or fails the door says NOT LOCKED.
#
# Bash 3.2. No project is named here.

_fdoor_effect() {
  case "$1" in
    start)     printf 'main starts from this commit' ;;
    hold)      printf 'holds each candidate whose history holds this commit, and takes back an authorization or an override of it that you gave before' ;;
    release)   printf 'passes over the holds you gave before now on this exact head' ;;
    authorize) printf 'the authority may land this exact head once, if its judge passes' ;;
    override)  printf 'LANDS THIS EXACT HEAD ONCE WITH NO JUDGE, as the tree named below and no other' ;;
    stop)      printf 'nothing lands until you say go' ;;
    go)        printf 'landing goes on' ;;
    reach)     printf 'records the result of the reach test: after a pass, statements given at this desktop by a switch count' ;;
  esac
}

# W8, for the card: whether a statement given now, this way, counts.
_fdoor_counts() {   # GIVEN
  case "$1" in
    console) printf 'yes' ;;
    desktop) if [ "${_DL_REACH:-0}" -eq 1 ]; then printf 'yes'
             else printf 'no: the reach test has not passed, so nothing given by a switch counts'; fi ;;
    *)       printf 'no: this authority is in shadow, and nothing said in shadow counts' ;;
  esac
}

# D5. The card for VERB about HEAD (or - for a verb that names none). Prints it; sets _FDC_TREE to the tree
# the head would land as, or to nothing.
_fdoor_card() {   # VERB HEAD GIVEN [RESULT WITNESS]
  local verb="$1" h="$2" b="$_FA_MAIN" t="" mt rc btree from="" i listed=0 r hh br
  _FDC_TREE=""
  printf 'effect: %s\n' "$(_fdoor_effect "$verb")"
  printf 'counts: %s\n' "$(_fdoor_counts "$3")"
  if [ "$verb" = reach ]; then printf 'result: %s\nwitness-record: %s\n' "${4:--}" "${5:--}"; fi
  [ "$h" != - ] || return 0
  printf 'commit: %s\n' "$h"
  if [ -z "$b" ]; then
    printf 'main-shown: -\nlands-as: main starts from this commit\n'
  else
    printf 'main-shown: %s\n' "$b"
    mt="$(_fa_g --attr-source="$_FA_EMPTY" merge-tree --write-tree --no-messages "$b" "$h" 2>/dev/null)"; rc=$?
    t="${mt%%$'\n'*}"; btree="$(_fa_g rev-parse --verify --quiet "$b^{tree}" 2>/dev/null)"
    if [ "$rc" -ne 0 ] || ! _fa_sha "$t" || ! _fa_g cat-file -e "$t^{tree}" 2>/dev/null; then
      printf 'lands-as: nothing, as it stands: it conflicts with main\n'
      t="$(_fa_g rev-parse --verify --quiet "$h^{tree}" 2>/dev/null)"
      from="$(_fa_g merge-base "$b" "$h" 2>/dev/null)" && from="$from^{tree}" || from="$_FA_EMPTY"
    elif [ "$t" = "$btree" ]; then
      printf 'lands-as: nothing: it changes nothing\n'
    else
      printf 'lands-as: tree %s\n' "$t"; _FDC_TREE="$t"
    fi
    felix_authority_paths "$b" "$t" "$from"
    [ "$_FP_UNREADABLE" -ne 1 ] || printf 'policy: the founder-path policy at main cannot be read, so each path is taken as yours\n'
    [ "$_FP_UNREADABLE" -ne 2 ] || printf 'policy: the paths this change touches could not be listed\n'
    printf 'founder-paths-changed: %s\n' "$_FP_NF"
    for (( i = 0; i < _FP_NF; i++ )); do _fa_esc_set "${_FP_FOUNDER[$i]}"; printf 'founder-path: %s\n' "$_FA_E"; done
    for (( i = 0; i < _FP_NO && i < 20; i++ )); do _fa_esc_set "${_FP_OTHER[$i]}" 200; printf 'path: %s\n' "$_FA_E"; listed=$((listed + 1)); done
    printf 'paths-changed: %s (not listed above: %s)\n' "$((_FP_NF + _FP_NO))" "$((_FP_NO - listed))"
    felix_authority_decide "$h"
    printf 'decision: %s %s\n' "$_FD_DECISION" "$_FD_DETAIL"
  fi
  while IFS=' ' read -r hh r; do
    [ "$hh" = "$h" ] || continue
    br="${r#refs/remotes/src/}"
    printf 'carried-by: branch %s (the worker'"'"'s word)\n' "$(_fa_esc "$br" 200)"
  done <<EOF
$(_fa_g for-each-ref --format='%(objectname) %(refname)' refs/remotes/src/ 2>/dev/null)
EOF
  printf 'commit-subject: %s (the worker'"'"'s word)\n' "$(_fa_esc "$(_fa_g log -1 --format=%s "$h" 2>/dev/null)" 200)"
}

# D5a. Every line the door prints: FORMAT and its arguments, as printf takes them. A line of at most 78
# characters is printed as it is. A longer one is folded into rows: the first of at most 78 characters, each
# further one of at most 72 after its start of four spaces, a bar and a space. A row ends after a space where
# one stands in its second half, so the door's own words are not cut in two. Joining the rows, with that
# start removed, gives the line back, and folding a folded line changes nothing.
_fdoor_p() {
  local s line w cut row
  printf -v s "$@"
  s="${s%$'\n'}"
  while IFS= read -r line || [ -n "$line" ]; do
    w=78
    while [ "${#line}" -gt "$w" ]; do
      row="${line:0:w}"; cut="${row% *}"
      if [ "${#cut}" -lt "${#row}" ] && [ "${#cut}" -ge $((w / 2)) ]; then row="${line:0:${#cut}+1}"; fi
      if [ "$w" -eq 78 ]; then printf '%s\n' "$row"; else printf '    | %s\n' "$row"; fi
      line="${line:${#row}}"; w=72
    done
    if [ "$w" -eq 78 ]; then printf '%s\n' "$line"; elif [ -n "$line" ]; then printf '    | %s\n' "$line"; fi
  done <<EOF
$s
EOF
}

# D6. How many statements were closed at this door, for a wrong or a missing confirmation, since the last one
# it kept: the rows of refused.tsv that carry the place the next statement would take.
_fdoor_failed() {
  local n
  n="$(LC_ALL=C awk -F'\t' -v n="$_DL_N" '($2 "") == (n "") { c++ } END { print c + 0 }' "$_FA_DOOR/refused.tsv" 2>/dev/null)" || n=0
  printf '%s' "${n:-0}"
}
_fdoor_failed_row() {   # VERB COMMIT GIVEN WHY
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$_DL_N" "$1" "$2" "$3" "$4" >> "$_FA_DOOR/refused.tsv" 2>/dev/null || :
}

# D2. What stands, read back before anything is asked.
_fdoor_readback() {   # GIVEN
  local why i s from t f
  printf 'FELIX DOOR  authority %s\n' "$_FA_ID"
  printf 'standing: %s\n' "$_FA_STANDING"
  if [ "$_FA_STANDING" = shadow ]; then
    # What the authority says counts for nothing in shadow (W7). What he says is another question (W8): a
    # statement given at the console counts, and the first start and the reach result are given exactly so.
    if [ "$1" = shadow ]; then
      printf 'SHADOW: this authority holds nothing, nothing it decides counts, and nothing said here counts\n'
    else
      printf 'SHADOW: this authority holds nothing and nothing it decides counts; a statement given here is kept, and its card says whether it counts\n'
    fi
    while IFS= read -r why; do [ -z "$why" ] || printf 'SHADOW why: %s\n' "$why"; done <<EOF
$_FA_WHYS
EOF
  fi
  printf 'where: a statement given now is given at: %s\n' "$1"   # not `given: `, which is the statement's own field
  printf 'main: %s\n' "${_FA_MAIN:--}"
  s="$(felix_word_stop)"
  if [ -n "$s" ]; then printf 'word: stop\nword-from: statement %s\n' "$s"; else printf 'word: go\n'; fi   # the word alone, as status prints it
  printf 'statements: %s\n' "$_DL_N"
  from=$((_DL_N - 5)); [ "$from" -ge 0 ] || from=0
  for (( i = from; i < _DL_N; i++ )); do
    printf 'statement: %s %s %s given %s at %s\n' "$i" "${_DL_VERB[$i]}" "${_DL_COMMIT[$i]}" "${_DL_GIVEN[$i]}" "${_DL_AT[$i]}"
  done
  for (( i = 0; i < _DL_N; i++ )); do
    [ "${_DL_READ[$i]}" = 1 ] || continue
    case "${_DL_VERB[$i]}" in authorize|override) ;; *) continue ;; esac
    _fw_hold "${_DL_COMMIT[$i]}"
    [ -z "$_FW_HOLD" ] || [ "$i" -gt "$_FW_HOLD" ] || continue
    if [ "${_DL_VERB[$i]}" = override ]; then
      # K6. In effect for the tree it names and no other: the tick says so, and so does this line. A read-back
      # that looked at the holds alone called an override in effect after main had moved (review F10).
      t="$(_fa_g --attr-source="$_FA_EMPTY" merge-tree --write-tree --no-messages "$_FA_MAIN" "${_DL_COMMIT[$i]}" 2>/dev/null)" || t=""
      if [ -n "$_FA_MAIN" ] && [ "${t%%$'\n'*}" = "${_DL_TREE[$i]}" ]; then
        printf 'in-effect: %s override %s as tree %s\n' "$i" "${_DL_COMMIT[$i]}" "${_DL_TREE[$i]}"
      else
        printf 'lapsed: %s override %s: main moved, and it no longer merges as the tree you were shown\n' "$i" "${_DL_COMMIT[$i]}"
      fi
    else
      printf 'in-effect: %s authorize %s\n' "$i" "${_DL_COMMIT[$i]}"
    fi
  done
  f="$(_fdoor_failed)"
  [ "$f" -eq 0 ] || printf 'refused-confirmations: %s\nrefused-since: the last statement this door kept; one that was not yours was typed by someone else\n' "$f"
}

# D3. What waits on his word, numbered. Sets _FDI (an array of heads), _FDI_N and _FDL_OUT (the lines).
_fdoor_list() {
  local h br other=0 cands nl=$'\n'
  _FDI=(); _FDI_N=0; _FDL_OUT=""
  if [ -z "$_FA_MAIN" ]; then
    _FDL_OUT="waiting: this authority has no main yet; the first statement is the first start: start COMMIT$nl"
    return 0
  fi
  [ -z "$(felix_word_stop)" ] || _FDL_OUT="waiting: you have said stop, so nothing lands; what follows is what the store holds$nl"
  cands="$(felix_authority_candidates)"
  while IFS=$'\t' read -r h br; do
    [ -n "$h" ] || continue
    # What waits on him is listed under a stop too: the list reads each head as if he had said go.
    felix_authority_decide "$h" listing
    case "$_FD_DECISION" in
      waits|held) _FDI[$_FDI_N]="$h"; _FDI_N=$((_FDI_N + 1))
                  _FDL_OUT="${_FDL_OUT}item: $_FDI_N $h $_FD_DECISION branch $(_fa_esc "$br" 200)$nl" ;;
      *) other=$((other + 1)) ;;
    esac
  done <<EOF
$cands
EOF
  _FDL_OUT="${_FDL_OUT}items: $_FDI_N waiting on your word; other candidates: $other$nl"
}

# D10. The lock, after a kept statement.
_fdoor_lock() {
  if [ -z "$_FA_LOCK" ]; then _fdoor_p 'NOT LOCKED: no lock is set, so this desktop is still open; lock it yourself\n'
  elif [ ! -x "$_FA_LOCK" ] || [ -d "$_FA_LOCK" ]; then _fdoor_p 'NOT LOCKED: the lock that is set cannot be run; lock this desktop yourself\n'
  elif "$_FA_LOCK" </dev/null >/dev/null 2>&1; then _fdoor_p 'locked\n'
  else _fdoor_p 'NOT LOCKED: the lock that is set failed; lock this desktop yourself\n'; fi
}

# D4. A witness record: a plain file directly in AH/reach/, of a megabyte at most, whose first line says what
# it is. Directly: a record reached through a directory under reach/ that was a link stood outside the home
# (review F14).
_fdoor_record() {   # PATH -> 0 when it is one
  local p="$1" name first=""
  case "$p" in "$_FA_HOME/reach/"*) name="${p#"$_FA_HOME/reach/"}" ;; *) return 1 ;; esac
  case "$name" in ""|*/*|.|..) return 1 ;; esac
  [ -f "$p" ] && [ ! -L "$p" ] && [ ! -L "$_FA_HOME/reach" ] || return 1
  [ "$(LC_ALL=C wc -c < "$p" | tr -d ' ')" -le 1048576 ] || return 1
  IFS= read -r first < "$p" || [ -n "$first" ] || return 1
  [ "$first" = felix-reach-witness/v1 ]
}

# `felix door`, and `felix door stop` (D13: the brake, with no fetch and no list, so that nothing a worker
# pushed stands between him and the stop). Returns 0 when a statement was kept, 1 when none was.
felix_door() {   # [stop]
  local brake="${1:-}" ttl="${FELIX_DOOR_TTL:-120}" given line verb what extra h="-" t="-" result="-" witness="-" record=""
  local card cardid nonce at stmt want i j tree c n cols LC_ALL=C
  # A whole number of seconds from 1 to 3600, read as decimal; anything else is the default.
  case "$ttl" in ""|*[!0123456789]*|?????*) ttl=120 ;; esac
  ttl=$((10#$ttl)); [ "$ttl" -ge 1 ] && [ "$ttl" -le 3600 ] || ttl=120
  # D1. No road in from the network.
  if [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_TTY:-}" ]; then
    _fdoor_p 'refused: this door opens at the authority'"'"'s own desktop, and this is a network login\n'; return 1
  fi
  # D5a. The card is drawn for 80 columns or more: in a narrower window a folded row would wrap again.
  if [ -t 1 ]; then
    cols="$(stty size 2>/dev/null <&1 | cut -d' ' -f2)"
    case "$cols" in ""|*[!0123456789]*) ;; *)
      [ "$cols" -ge 80 ] || { printf 'refused: this window is %s columns wide, and the card is drawn for 80 or more\n' "$cols"; return 1; } ;;
    esac
  fi
  felix_authority_open || { printf 'felix: %s\n' "$_FA_WHY" >&2; return 1; }
  [ -z "$_DL_BAD" ] || { _fdoor_p 'refused: the door'"'"'s log does not read back: statement %s\n' "$_DL_BAD"; return 1; }
  given="$(felix_authority_given)"
  if [ "$brake" = stop ]; then
    _fdoor_p '%s\n' "$(_fdoor_readback "$given")"
    line=stop
  else
    felix_authority_fetch || _fdoor_p 'source: the source could not be read; what follows is what the store holds\n'
    felix_authority_main || :
    _fdoor_p '%s\n' "$(_fdoor_readback "$given")"
    _fdoor_list
    _fdoor_p '%s' "$_FDL_OUT"
    _fdoor_p 'say: one verb and what it is about (start COMMIT, hold WHAT, release WHAT, authorize WHAT, override WHAT, stop, go, reach pass RECORD, reach fail RECORD)\n'
    IFS= read -r -t "$ttl" line || { _fdoor_p 'refused: nothing was said; no statement was given\n'; return 1; }
  fi
  case "$line" in ""|*[!\ -~]*) _fdoor_p 'refused: that line is empty or holds a byte outside printable ASCII\n'; return 1 ;; esac
  read -r verb what extra <<EOF
$line
EOF
  case " $FELIX_DOOR_VERBS " in *" $verb "*) ;; *) _fdoor_p 'refused: %s is not a verb this door knows\n' "$(_fa_esc "$verb" 40)"; return 1 ;; esac
  if [ "$_DL_N" -eq 0 ] && [ "$verb" != start ]; then _fdoor_p 'refused: the first statement is the first start\n'; return 1; fi
  if [ "$_DL_N" -gt 0 ] && [ "$verb" = start ]; then
    # A store whose start was given in shadow stays a rehearsal (W6 c), and the door says so where he would
    # otherwise read "main starts once" and not know why a console start is turned away.
    if [ "${_DL_GIVEN[0]}" = console ]; then _fdoor_p 'refused: the first start was given, and main starts once\n'
    else _fdoor_p 'refused: the first start was given, and main starts once; it was given in %s, so this store stays a rehearsal, and a start that counts is the first statement of a new store\n' "${_DL_GIVEN[0]}"; fi
    return 1
  fi
  # D4. A first start that does not count would make main and leave no room for one that does (review F8).
  if [ "$verb" = start ] && [ "$given" = desktop ]; then
    _fdoor_p 'refused: the first start is given at the console: after a restart, with no login of a worker open\n'; return 1
  fi
  # D6. Three statements closed unconfirmed at the desktop: the next one is given at the console. A stop is
  # still taken, since it lands nothing.
  if [ "$given" = desktop ] && [ "$verb" != stop ] && [ "$(_fdoor_failed)" -ge 3 ]; then
    _fdoor_p 'refused: three confirmations failed at this door since the last statement it kept; the next statement is given at the console\n'; return 1
  fi
  case "$verb" in
    stop|go)
      [ -z "$what" ] || { _fdoor_p 'refused: %s names nothing\n' "$verb"; return 1; } ;;
    reach)
      result="$what"; record="$extra"
      case "$result" in pass|fail) ;; *) _fdoor_p 'refused: a reach result is pass or fail\n'; return 1 ;; esac
      if [ "$result" = pass ] && [ "$given" != console ]; then
        _fdoor_p 'refused: a reach result that passes is given at the console, where no login of a worker is open\n'; return 1
      fi
      if [ "$record" = - ] && [ "$result" = fail ]; then :
      elif _fdoor_record "$record"; then
        witness="$(_fa_g hash-object -w --no-filters -- "$record" 2>/dev/null)" && _fa_sha "$witness" \
          || { _fdoor_p 'refused: the witness record could not be read\n'; return 1; }
      else _fdoor_p 'refused: a reach result names a witness record: a plain file directly in %s whose first line is felix-reach-witness/v1\n' "$(_fa_esc "$_FA_HOME/reach/" 300)"; return 1; fi ;;
    *)
      [ -z "$extra" ] || { _fdoor_p 'refused: %s names one thing\n' "$verb"; return 1; }
      case "$what" in
        ""|*[!0123456789abcdef]*) _fdoor_p 'refused: %s names a commit, by its whole id or by its number in the list\n' "$verb"; return 1 ;;
      esac
      if [ "${#what}" -eq 40 ]; then h="$what"
      elif [ "${#what}" -le 4 ] && case "$what" in *[!0123456789]*) false ;; esac && [ "$((10#$what))" -ge 1 ] && [ "$((10#$what))" -le "${_FDI_N:-0}" ]; then
        h="${_FDI[$((10#$what - 1))]}"
      else _fdoor_p 'refused: there is no such item in the list\n'; return 1; fi
      [ "$(_fa_g rev-parse --verify --quiet "$h^{commit}" 2>/dev/null)" = "$h" ] \
        || { _fdoor_p 'refused: that names no commit this authority holds\n'; return 1; } ;;
  esac
  if [ "$given" = desktop ] && [ -z "$_FA_LOCK" ]; then
    _fdoor_p 'refused: no lock is set, so one unlock would give more than one statement\n'; return 1
  fi
  card="$(_fdoor_p '%s\n' "$(_fdoor_card "$verb" "$h" "$given" "$result" "$witness")")"
  # The card ran in a subshell, so the tree it found is found again here, for the statement.
  if [ "$verb" = override ]; then
    t="$(_fa_g --attr-source="$_FA_EMPTY" merge-tree --write-tree --no-messages "$_FA_MAIN" "$h" 2>/dev/null)" && t="${t%%$'\n'*}" && _fa_sha "$t" \
      || { _fdoor_p 'refused: it conflicts with main, so there is no tree to override\n'; return 1; }
    [ "$t" != "$(_fa_g rev-parse --verify --quiet "$_FA_MAIN^{tree}" 2>/dev/null)" ] \
      || { _fdoor_p 'refused: it changes nothing, so there is nothing to override\n'; return 1; }
  fi
  cardid="$(printf '%s\n' "$card" | _fa_g hash-object --stdin 2>/dev/null)"
  nonce="$(od -An -N16 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')"
  _fa_sha "$cardid" && [ "${#nonce}" -eq 32 ] || { _fdoor_p 'refused: the statement could not be made\n'; return 1; }
  case "$nonce" in *[!0123456789abcdef]*) _fdoor_p 'refused: the statement could not be made\n'; return 1 ;; esac
  at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; n="$_DL_N"
  stmt="$(printf 'felix-door/v1\nauthority: %s\nserial: %s\nprev: %s\nverb: %s\ncommit: %s\ntree: %s\nmain: %s\ncard: %s\nkey: none\ngiven: %s\nresult: %s\nwitness: %s\nnonce: %s\nat: %s' \
    "$_FA_ID" "$n" "${_DL_TIP:--}" "$verb" "$h" "$t" "${_FA_MAIN:--}" "$cardid" "$given" "$result" "$witness" "$nonce" "$at")"
  _fdoor_p 'statement: the statement this door will keep, given with no key:\n%s\n' "$stmt"
  _fdoor_p 'card: the authority'"'"'s own facts:\n%s\n' "$card"
  # D6. Two pairs, each placed by this statement's nonce. The confirm line is one line and the last before
  # the door reads: what to type is said on the line before it, under a label of its own.
  case "$verb" in
    stop)  want=stop; _fdoor_p 'confirm: to give it, type: stop\n' ;;
    reach) want="reach $result"; _fdoor_p 'confirm: to give it, type: reach %s\n' "$result" ;;
    go)    i=$(( 0x${nonce:8:4} % 15 )); j=$(( 16 + 0x${nonce:12:4} % 15 ))
           want="go ${nonce:i:2}${nonce:j:2}"
           _fdoor_p 'type: to give it, go, a space and the four characters the next line brackets\n'
           _fdoor_p 'confirm: nonce %s[%s]%s[%s]%s\n' "${nonce:0:i}" "${nonce:i:2}" "${nonce:i+2:j-i-2}" "${nonce:j:2}" "${nonce:j+2}" ;;
    *)     i=$(( 0x${nonce:0:4} % 19 )); j=$(( 20 + 0x${nonce:4:4} % 19 ))
           want="$verb ${h:i:2}${h:j:2}"
           _fdoor_p 'type: to give it, its verb, a space and the four characters the next line brackets\n'
           _fdoor_p 'confirm: %s[%s]%s[%s]%s\n' "${h:0:i}" "${h:i:2}" "${h:i+2:j-i-2}" "${h:j:2}" "${h:j+2}" ;;
  esac
  # D6. One try, and a closed statement leaves a row.
  IFS= read -r -t "$ttl" line || {
    _fdoor_failed_row "$verb" "$h" "$given" none
    _fdoor_p 'refused: no confirmation came; the statement is closed and nothing was kept\n'; return 1; }
  [ "$line" = "$want" ] || {
    _fdoor_failed_row "$verb" "$h" "$given" wrong
    _fdoor_p 'refused: that is not this statement'"'"'s confirmation; the statement is closed and nothing was kept\n'; return 1; }
  # W8. How a statement was given is decided when it is kept. The statement says what stood when the door
  # opened, so a desktop that stands otherwise now (a worker's login opened meanwhile) closes it.
  [ "$(felix_authority_given again)" = "$given" ] \
    || { _fdoor_p 'refused: how this desktop stands changed while the statement was open; nothing was kept\n'; return 1; }
  # D7, D9. The next entry of the log, by compare-and-swap.
  tree="$_FA_EMPTY"
  if [ "$witness" != - ]; then
    tree="$(printf '100644 blob %s\twitness\n' "$witness" | _fa_g mktree 2>/dev/null)" && _fa_sha "$tree" \
      || { _fdoor_p 'refused: the witness record could not be kept; nothing was kept\n'; return 1; }
  fi
  if [ -n "$_DL_TIP" ]; then c="$(printf '%s\n' "$stmt" | _fa_g commit-tree "$tree" -p "$_DL_TIP" 2>/dev/null)"
  else c="$(printf '%s\n' "$stmt" | _fa_g commit-tree "$tree" 2>/dev/null)"; fi
  _fa_sha "$c" || { _fdoor_p 'refused: the statement could not be written; nothing was kept\n'; return 1; }
  _fa_g update-ref refs/felix/door "$c" "${_DL_TIP:-$FELIX_AUTH_ZERO}" 2>/dev/null \
    || { _fdoor_p 'refused: the log moved while this statement was open; nothing was kept\n'; return 1; }
  _fdoor_p 'kept: statement %s %s %s\n' "$n" "$verb" "$h"
  # The commit a statement names stays in the store for as long as the statement does.
  [ "$h" = - ] || _fa_g update-ref "refs/felix/named/$n" "$h" 2>/dev/null || :
  if [ "$verb" = start ]; then
    _DL_N=1; _DL_VERB[0]=start; _DL_COMMIT[0]="$h"
    felix_authority_main && _fdoor_p 'main: %s\n' "$_FA_MAIN" || _fdoor_p 'main: could not be made; the next tick makes it from statement 0\n'
  fi
  _fdoor_lock
  return 0
}
