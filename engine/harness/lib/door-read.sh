# The door's log, read: the reader's check, which statements count, and what the founder's word says of a head.
#
# Trust-plane step 4, stage 1, slice 1 (lib/authority.sh says what the slice is). The log is a ref of the
# authority's store, refs/felix/door. Each statement is a commit whose message is the statement (lib/door.sh,
# D8) and whose one parent is the statement before it.
#
# ONE READER. The kernel and `felix authority verify` read the log through felix_door_log_read, so the kernel
# decides nothing from a log the reader's check refuses (V4, K1). The check is whole or it fails: an entry
# whose message is not exactly the fields of a statement, whose serial is not its place, whose parent is not
# the entry before it or whose authority is another store's stops the read, and nothing after it is used.
#
# IN ORDER (the 11-09 mock's door read his word without its order, and the fix is this file's shape). A stop
# or a go, a hold, a release and a permission are each read by their place in the log:
#   - the later of stop and go decides;
#   - a release passes over the holds given before it, and a hold given after it holds again;
#   - a permission (an authorization or an override) is in effect while no hold that covers its head was given
#     after it, and a release after that hold does not bring it back;
#   - an override names the tree he was shown, and is in effect for that tree alone (lib/authority-tick.sh).
#
# WHAT COUNTS (W8). A statement given at the console counts. One given at the desktop counts when a reach pass
# given at the console stands before it. One given in shadow never counts. In shadow standing every statement
# is read, so that the rehearsal reads what a live authority would, and every line it then prints says shadow.
#
# NO SIGNATURE. A statement carries none, and the reader says how many it took on the authority's word: all of
# them. What it can tell a reader elsewhere is that the log still holds the entry that reader saw last (V3).
# A hand with the authority's login that rewrites the whole log, and a reader with no memory, are not caught.
#
# Bash 3.2, and awk that both the one-true-awk and gawk run. No project is named here.

FELIX_DOOR_VERBS='start hold release authorize override stop go reach'

# The check of every entry, in one pass over `git log`. A record is a header line that starts with byte 1 and
# holds the commit, its parents and its tree, then the message, then the one empty line the format adds after a
# message that ends in a newline. It prints one row a statement, or one BAD row and nothing after it.
_FELIX_DOOR_LOG_AWK='
function hex(s, n) { return length(s) == n && s !~ /[^0-9a-f]/ }
function bad(why) { if (!failed) { printf "BAD\t%d\t%s\n", n, why; failed = 1 } }
function flush(   i, k, v, verb, names, names_n, want) {
  if (n < 0 || failed) return
  if (h_n != 9) { bad("its commit does not read back"); return }
  if (nl != 16 || L[16] != "" || L[1] != "felix-door/v1") { bad("its message is not the fields of a statement and nothing else"); return }
  names_n = split("authority serial prev verb commit tree main card key given result witness nonce at", names, " ")
  for (i = 1; i <= names_n; i++) {
    k = names[i] ": "
    if (substr(L[i + 1], 1, length(k)) != k) { bad("its message is not the fields of a statement and nothing else"); return }
    F[names[i]] = substr(L[i + 1], length(k) + 1)
  }
  if (F["authority"] != aid) { bad("it was given to another authority"); return }
  if (F["serial"] != ("" n)) { bad("it is out of its place"); return }
  if (index(par, " ")) { bad("its commit has more than one parent"); return }
  # Ids are compared as text: two ids that both read as numbers (0e11..., 0e22...) are equal as numbers.
  if (n == 0 ? ((par "") != "" || F["prev"] != "-") : ((par "") != (previd "") || F["prev"] != (previd ""))) { bad("it does not follow the statement before it"); return }
  # The commit holds its tree, at most one parent, the author and committer lines the authority writes and the
  # statement, and no other byte. Its size is counted from what read back: a header git does not print (a
  # signature, an encoding) and bytes after a NUL in the message both make it larger (review F12).
  if (an != "felix-authority" || ae != "authority@felix.invalid" || cn != an || ce != ae) { bad("its commit was not written by an authority"); return }
  want = 46 + ((par "") == "" ? 0 : 48) + 7 + length(an) + 2 + length(ae) + 2 + length(ad) + 1 + 10 + length(cn) + 2 + length(ce) + 2 + length(cd) + 1 + 1
  for (i = 1; i <= 15; i++) want += length(L[i]) + 1
  if (!(id in size) || size[id] + 0 != want) { bad("its commit holds bytes that are not its statement"); return }
  verb = F["verb"]
  if (index(" " verbs " ", " " verb " ") == 0 || index(verb, " ")) { bad("its verb is not one the door knows"); return }
  if ((verb == "start") != (n == 0)) { bad("a start is the first statement and no other"); return }
  if (verb == "stop" || verb == "go" || verb == "reach") { if (F["commit"] != "-") { bad("it names a commit its verb does not take"); return } }
  else if (!hex(F["commit"], 40)) { bad("it names no commit"); return }
  if (verb == "override" ? !hex(F["tree"], 40) : F["tree"] != "-") { bad("its tree is not what its verb takes"); return }
  if (F["main"] != "-" && !hex(F["main"], 40)) { bad("its main is not a commit id"); return }
  if (!hex(F["card"], 40)) { bad("its card is not a digest"); return }
  if (F["key"] != "none") { bad("it claims a key, and this door uses none"); return }
  if (F["given"] != "console" && F["given"] != "desktop" && F["given"] != "shadow") { bad("it does not say how it was given"); return }
  if (verb == "reach") {
    if (F["result"] != "pass" && F["result"] != "fail") { bad("its reach result is neither pass nor fail"); return }
    if (F["witness"] != "-" && !hex(F["witness"], 40)) { bad("its witness is not a digest"); return }
    if (F["result"] == "pass" && F["witness"] == "-") { bad("it is a reach pass with no witness record"); return }
  } else if (F["result"] != "-" || F["witness"] != "-") { bad("it carries a reach result its verb does not take"); return }
  if (!hex(F["nonce"], 32)) { bad("its nonce is not 32 hex digits"); return }
  if (F["nonce"] in seen) { bad("its nonce stands in an earlier statement"); return }
  seen[F["nonce"]] = 1
  if (F["at"] !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/) { bad("its time is not a UTC time"); return }
  if (F["witness"] == "-" && (tr "") != (empty "")) { bad("its commit holds a file"); return }
  printf "%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", n, id, verb, F["commit"], F["tree"], F["given"], F["result"], F["witness"], F["at"], tr
  previd = id
}
BEGIN { n = -1; failed = 0; m = split(sizes, z, " "); for (i = 1; i < m; i += 2) size[z[i]] = z[i + 1] }
substr($0, 1, 1) == "\001" {
  flush(); n++; nl = 0; h_n = split(substr($0, 2), h, "\t"); id = h[1]; par = h[2]; tr = h[3]
  an = h[4]; ae = h[5]; ad = h[6]; cn = h[7]; ce = h[8]; cd = h[9]; next
}
{ nl++; L[nl] = $0 }
END { flush() }'

# V1. felix_door_log_read STORE AUTHORITY-ID -> 0 with the _DL_* arrays filled, or 1 with _DL_BAD="N: why" and
# an empty log in the arrays, so that nothing a refused log holds is read.
felix_door_log_read() {
  local store="$1" aid="$2" empty out ids sizes i id verb commit tree given result witness at tr reach=0 want
  _DL_N=0; _DL_BAD=""; _DL_TIP=""; _DL_REACH=0
  _DL_ID=(); _DL_VERB=(); _DL_COMMIT=(); _DL_TREE=(); _DL_GIVEN=(); _DL_RESULT=(); _DL_WITNESS=(); _DL_AT=(); _DL_COUNTS=(); _DL_READ=()
  if ! git --git-dir="$store" rev-parse --verify --quiet 'refs/felix/door^{commit}' >/dev/null 2>&1; then
    [ -z "$(git --git-dir="$store" for-each-ref --format='%(refname)' refs/felix/door 2>/dev/null)" ] \
      && [ ! -e "$store/refs/felix/door" ] && return 0
    _DL_BAD="0: the log's ref names no commit"; return 1
  fi
  empty="$(git --git-dir="$store" hash-object -t tree /dev/null 2>/dev/null)"
  ids="$(git --git-dir="$store" rev-list --first-parent --reverse refs/felix/door 2>/dev/null)" || { _DL_BAD="0: the log cannot be listed"; return 1; }
  sizes="$(printf '%s\n' "$ids" | git --git-dir="$store" cat-file --batch-check='%(objectname) %(objectsize)' 2>/dev/null | tr '\n' ' ')"
  # --no-show-signature: with log.showSignature and gpg.program in a store's own configuration, reading an
  # entry that carried a signature header ran the program that configuration named (review F12).
  out="$(git --git-dir="$store" log --no-show-signature --date=raw --first-parent --reverse \
           --format='%x01%H%x09%P%x09%T%x09%an%x09%ae%x09%ad%x09%cn%x09%ce%x09%cd%n%B' refs/felix/door 2>/dev/null \
          | LC_ALL=C awk -v aid="$aid" -v empty="$empty" -v verbs="$FELIX_DOOR_VERBS" -v sizes="$sizes" "$_FELIX_DOOR_LOG_AWK")"
  while IFS=$'\t' read -r i id verb commit tree given result witness at tr; do
    [ -n "$i" ] || continue
    if [ "$i" = BAD ]; then _DL_BAD="$id: $verb"; break; fi
    if [ "$witness" != - ]; then
      want="100644 blob $witness"$'\t'"witness"
      [ "$(git --git-dir="$store" ls-tree "$id" 2>/dev/null)" = "$want" ] || { _DL_BAD="$i: its commit does not hold exactly its witness record"; break; }
    fi
    _DL_ID[$i]="$id"; _DL_VERB[$i]="$verb"; _DL_COMMIT[$i]="$commit"; _DL_TREE[$i]="$tree"; _DL_GIVEN[$i]="$given"
    _DL_RESULT[$i]="$result"; _DL_WITNESS[$i]="$witness"; _DL_AT[$i]="$at"
    # W8, in order: a reach pass at the console stands until the next reach statement that is anything else.
    case "$given" in
      console) _DL_COUNTS[$i]=yes ;;
      desktop) if [ "$reach" -eq 1 ]; then _DL_COUNTS[$i]=yes; else _DL_COUNTS[$i]=no; fi ;;
      *)       _DL_COUNTS[$i]=no ;;
    esac
    if [ "$verb" = reach ]; then
      if [ "$result" = pass ] && [ "$given" = console ]; then reach=1; else reach=0; fi
    fi
    _DL_N=$((i + 1)); _DL_TIP="$id"
  done <<EOF
$out
EOF
  # What git lists and what was parsed are the same entries: a message cannot stand in for a commit.
  if [ -z "$_DL_BAD" ]; then
    want=""; for (( i = 0; i < _DL_N; i++ )); do want="$want${_DL_ID[$i]}"$'\n'; done
    [ "$want" = "$ids"$'\n' ] || _DL_BAD="$_DL_N: the entries git lists are not the entries that read back"
  fi
  if [ -n "$_DL_BAD" ]; then
    _DL_N=0; _DL_TIP=""; _DL_REACH=0
    return 1
  fi
  _DL_REACH="$reach"
  return 0
}

# K1. Which statements the kernel reads: each one in shadow, and the ones that count otherwise.
felix_door_reads() {   # STANDING
  local i
  for (( i = 0; i < _DL_N; i++ )); do
    if [ "$1" = shadow ] || [ "${_DL_COUNTS[$i]}" = yes ]; then _DL_READ[$i]=1; else _DL_READ[$i]=0; fi
  done
}

# K2. The number of the stop in force, or nothing.
felix_word_stop() {
  local i s=""
  for (( i = 0; i < ${_DL_N:-0}; i++ )); do
    [ "${_DL_READ[$i]:-0}" = 1 ] || continue
    case "${_DL_VERB[$i]}" in stop) s="$i" ;; go) s="" ;; esac
  done
  printf '%s' "$s"
}

# K3. The last hold that covers HEAD: sets _FW_HOLD (its number, or empty) and _FW_HOLDC (its commit). A hold
# covers a head whose history holds its commit. Where git cannot say, the hold covers: the answer that holds.
_fw_hold() {   # HEAD
  local i rc
  _FW_HOLD=""; _FW_HOLDC=""
  for (( i = 0; i < _DL_N; i++ )); do
    [ "${_DL_READ[$i]}" = 1 ] && [ "${_DL_VERB[$i]}" = hold ] || continue
    _fa_g merge-base --is-ancestor "${_DL_COMMIT[$i]}" "$1" 2>/dev/null; rc=$?
    [ "$rc" -eq 1 ] || { _FW_HOLD="$i"; _FW_HOLDC="${_DL_COMMIT[$i]}"; }
  done
}

# The number of the last statement with this verb that names exactly HEAD, or nothing.
_fw_last() {   # VERB HEAD
  local i s=""
  for (( i = 0; i < _DL_N; i++ )); do
    [ "${_DL_READ[$i]}" = 1 ] && [ "${_DL_VERB[$i]}" = "$1" ] && [ "${_DL_COMMIT[$i]}" = "$2" ] && s="$i"
  done
  printf '%s' "$s"
}

# K5. The first permission in effect: VERB of exactly HEAD (and, when TREE is given, of that tree), given after
# the last hold that covers HEAD. _fw_hold HEAD has been called. No landing exists yet, so none is spent.
_fw_live() {   # VERB HEAD [TREE] -> its number, or 1
  local i
  for (( i = 0; i < _DL_N; i++ )); do
    [ "${_DL_READ[$i]}" = 1 ] && [ "${_DL_VERB[$i]}" = "$1" ] && [ "${_DL_COMMIT[$i]}" = "$2" ] || continue
    [ -z "${3:-}" ] || [ "${_DL_TREE[$i]}" = "$3" ] || continue
    [ -z "$_FW_HOLD" ] || [ "$i" -gt "$_FW_HOLD" ] || continue
    printf '%s' "$i"; return 0
  done
  return 1
}

# `felix authority log`: one row a statement.
felix_door_log_print() {
  local i
  for (( i = 0; i < _DL_N; i++ )); do
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$i" "${_DL_VERB[$i]}" "${_DL_COMMIT[$i]}" "${_DL_TREE[$i]}" \
      "${_DL_GIVEN[$i]}" "${_DL_COUNTS[$i]}" "${_DL_AT[$i]}"
  done
}

# V1 to V3. `felix authority verify`: the reader's check of the log of STORE, with the reader's own memory of
# the last entry it checked in MEMORY when one is named. Prints the verdict; 0 when it is ok.
felix_authority_verify() {   # STORE MEMORY|""
  local store="$1" mem="$2" aid n="" id="" LC_ALL=C
  aid="$(felix_authority_id "$store")" || { printf 'not ok: the store at %s has no identity\n' "$store"; return 1; }
  felix_door_log_read "$store" "$aid" || { printf 'not ok statement %s\n' "$_DL_BAD"; return 1; }
  if [ -n "$mem" ] && { [ -e "$mem" ] || [ -L "$mem" ]; }; then
    [ -f "$mem" ] && [ ! -L "$mem" ] && IFS=$'\t' read -r n id < "$mem" || n=""
    case "$n" in ""|*[!0123456789]*|??????????*) printf 'not ok: this reader'"'"'s memory, %s, cannot be read\n' "$mem"; return 1 ;; esac
    _fa_sha "$id" || { printf 'not ok: this reader'"'"'s memory, %s, cannot be read\n' "$mem"; return 1; }
    [ "$n" -lt "$_DL_N" ] && [ "${_DL_ID[$n]}" = "$id" ] \
      || { printf 'not ok: the log no longer holds statement %s that this reader saw\n' "$n"; return 1; }
  fi
  # The memory is written before the verdict is printed: a reader that could not keep what it saw says so,
  # and says nothing that reads as ok.
  if [ -n "$mem" ] && [ "$_DL_N" -gt 0 ]; then
    { printf '%s\t%s\n' "$((_DL_N - 1))" "$_DL_TIP" > "$mem.new.$$"; } 2>/dev/null && mv "$mem.new.$$" "$mem" 2>/dev/null \
      || { printf 'not ok: this reader'"'"'s memory, %s, could not be written\n' "$mem"; return 1; }
  fi
  printf 'ok %s statements, %s on the authority'"'"'s word\n' "$_DL_N" "$_DL_N"
  [ -n "$mem" ] || printf 'no memory: a log whose last statements were dropped would read the same\n'
  return 0
}
