# >>> trust-step4-authority-store
printf '\ntrust plane step 4, slice 1: the authority, its parameters, its store, its standing and the first start (spec-slice1 W1 to W8, W10, W11; blind)\n'
# Blind, written on 2026-11-12 from .felix/memory/felix/audits/2026-11-13-trust-step4-shadow/spec-slice1.md alone
# (sections 0 to 2.5, with 3 read for how a statement is given, and 6 and 7), before felix authority and felix door
# existed, by an author who has seen no implementation of either. Conventions come from tests/run, parts 0002, 2179 and
# 2185 and tests/lib/instrument-parts.sh; the helpers are tests/lib/trust-step4.sh, which says how a command and a door
# are driven. Everything is under $TMP/ts4-store. The commands are black boxes; the store is read with git.
#
# The fixture: a bare source whose main (M1, M2) holds .felix and a land table with one founder row, five branches
# of ordinary changes whose names sort differently by byte and by locale (Zed, alpha, beta-2, beta_1, merge), and
# old, whose head is in main's history. Authority a is shadow by construction (this login is the user and the one
# worker), b is a second store whose authority.conf the W2 cases rewrite, q and l have another login as their worker.
#
# Readings, where the spec leaves room:
# - "Prints the authority's id": init's stdout holds exactly one run of 40 lowercase hex digits, whatever stands
#   round it. "No access for group or other" is the last six mode characters ls prints, all "-".
# - A path the status prints is the path as it was given, and every path given here is physical (pwd -P).
# - A tick that is not paused exits 0 and prints nothing but its candidate lines and the tick: line (the spec gives
#   3 for paused and no other status). decide's status is not asserted.
# - "paused with WORDS" is one line, on either stream, that holds paused and WORDS.
# - A required key (user, workers, source) that authority.conf lacks makes it unreadable. W2's list does not say so.
# - decide of a commit the store does not hold prints no candidate line.
# - W6 b after init under a umask of 000: the store and the door init itself made are the authority's alone. W4
#   promises this of the home only; a founder with such a umask would otherwise be in shadow from the first status.
# - "The processes cannot be listed" (W8) is staged by a ps and a pgrep at the head of PATH that fail. Where the door
#   asks neither, the case is skipped: nothing here can stage it for a door that lists processes another way.
# - W10's hostile configuration is a merge driver that keeps main's side (part 2179's), reached through
#   GIT_CONFIG_GLOBAL, HOME, GIT_CONFIG_COUNT, GIT_CONFIG_SYSTEM and GIT_CONFIG_PARAMETERS, an attribute source
#   (GIT_ATTR_SOURCE) and a url.insteadOf that points the source at another repository. Each has a control that
#   plain git, here, is changed by it, and is skipped where it is not. "A fetch checks each object": a branch whose
#   commit has no author line, pushed after the first start, is not in the store after a tick and is not eligible.
#
# - Rev 2 of the spec (2026-11-13) was read after the first draft, and three cases were added from it: the forms of
#   source that W1 does not name (a relative path, a value that starts with -, ext::, http:// and user@host:path),
#   refused by init and unreadable in the file, with a file:// URL taken; and W8's second reading. That one is
#   staged where this login is not a worker: a door opens while the home is the authority's alone (the statement
#   would be given at the desktop), the home is made writable by its group before the confirmation is typed (it
#   would now be given in shadow), and nothing may be kept. No process of another login is started or stopped.
#
# - Rev 3 of the spec (2026-11-13) and its addendum on W6 e were read after that, and these were added or changed.
#   Every felix call is given a PATH of the system's own directories of programs (the helper says why): W6 e reads
#   each directory PATH names and each program in one. Where this login is the worker, e fails by its letter, for
#   this login owns the engine the suite runs, and the store that is shadow by construction says not the
#   authority's alone as well; case 1 does not say so, W6 e does. So W6 b and e are asked on a store whose one
#   worker is another login that runs no process, where neither why shows until a test stages it: for b a file
#   inside the store and inside the door's directory, and an access-control list (chmod +a, skipped where that
#   fails); for e a file of the engine's lib, a lock and its directory that anyone can write, a lock's
#   access-control entry that allows and one that denies, a directory anyone can write first on PATH (case 22),
#   and an entry of PATH that is empty or not absolute. Where status gives such a store a why line of a, b or e
#   before anything is staged, each assertion that needs the console or the desktop is skipped under its own name,
#   as case 22 asks. W6 a: with root as the worker, shadow. Case 2: the busy login is the one, neither this login
#   nor root, that the process list shows most, and a start at the desktop is refused. W8's "lacks process 1" is a
#   ps and a pgrep that succeed and print nothing. Case 16 at the desktop: a statement is kept first, so that the
#   count of refused confirmations starts there. W2: a key with a space. W4: an argument with a tab or a newline.
#
# Not covered: AH's default, $HOME/.felix/authority (no call here may fall back to it); W6 b's "owned by user"
# (nothing here can change an owner) and e's group clause (nothing here can put a login in a group); W8's
# effective user; a fetch through an https:// or ssh:// source, and a candidate's submodules (W10: a fetch into a
# bare store follows none whatever the code does, so no test here could fail); W7's last sentence, that nothing
# else in the engine reads the store, the log or the ledger; W10's replacement refs and the system's own
# configuration file; a tick whose source cannot be read (the spec says what the door does, not the tick); W8's
# second reading where the two differ by a worker's process starting; live standing, which needs a reach pass
# (part 2189); the reading of statements and the attributes of case 17 (2188); the door's own rules (2187).
_ts4_begin ts4-store
TS4S_S="$TS4/src.git"; TS4S_A="$TS4/a"; TS4S_B="$TS4/b"; TS4S_L="$TS4/l"; TS4S_Q="$TS4/q"; TS4S_ST="$TS4S_A/store.git"; TS4S_X="$TS4/x"
_ts4_src "$TS4S_S"; _ts4_base "$TS4S_S"; TS4S_M1="$TS4_M1"; TS4S_M2="$TS4_M2"
_ts4_ci "$TS4S_S" Zed "$TS4S_M2" 'an ordinary change, z' notes/z.txt; TS4S_HZ="$TS4_C"
_ts4_ci "$TS4S_S" alpha "$TS4S_M2" 'an ordinary change, a' notes/a.txt; TS4S_HA="$TS4_C"
_ts4_ci "$TS4S_S" beta-2 "$TS4S_M2" 'an ordinary change, b2' notes/b2.txt; TS4S_H2="$TS4_C"
_ts4_ci "$TS4S_S" beta_1 "$TS4S_M2" 'an ordinary change, b1' notes/b1.txt; TS4S_H1="$TS4_C"
_ts4_tree "$TS4S_S" "$TS4S_M1"; _ts4_f "$TS4S_S" 'alpha by a worker' hotel; _ts4_seal "$TS4S_S" merge "$TS4S_M1" 'a change that merges cleanly'; TS4S_HM="$TS4_C"
_fx_git "$TS4S_S" update-ref refs/heads/old "$TS4S_M1" >/dev/null 2>&1
TS4S_OTHER=root; [ "$TS4_ME" != root ] || TS4S_OTHER=nobody
TS4S_U=(--user "$TS4_ME" --workers "$TS4_ME" --source "$TS4S_S")

# ------------------------------------------------------------------ helpers ---
_ts4s_w2() {   # -> what W2 asks of the last call: its status, how many lines stderr holds, and whether the first starts felix:
  printf 'exit %s; %s stderr line(s); felix: %s' "$TS4_RC" "$(LC_ALL=C awk 'END { print NR }' "$TS4/e")" \
    "$(LC_ALL=C awk 'NR == 1 { f = (index($0, "felix: ") == 1) } END { print (f ? "yes" : "no") }' "$TS4/e")"
}
_ts4s_noinit() {   # WHAT HOME ARG...: felix authority init ARG... for HOME is refused, and HOME and $TS4/x are as they were
  local w="$1" h="$2" s; shift 2; s="$(_ts4_snap "$h" "$TS4S_X")"
  _ts4_a "$h" init "$@"
  if [ "$(_ts4_snap "$h" "$TS4S_X")" = "$s" ]; then s=unchanged; else s=changed; fi
  _ts4_is "ts4 store W4: init refuses $w: it exits 1 and changes nothing" "exit $TS4_RC; $s" "exit 1; unchanged" "$(_ts4_why)"
}
_ts4s_fresh() { [ ! -f "$TS4S_X/b.conf" ] || cat "$TS4S_X/b.conf" > "$TS4S_B/authority.conf"; }   # b's authority.conf as init wrote it
_ts4s_unread() {   # WHAT: b's authority.conf as it now stands is unreadable: status says so and writes nothing; then _ts4s_fresh
  local s; s="$(_ts4_snap "$TS4S_B")"; _ts4_a "$TS4S_B" status
  if [ "$(_ts4_snap "$TS4S_B")" = "$s" ]; then s=unchanged; else s=changed; fi
  _ts4_is "ts4 store W2: $1 makes authority.conf unreadable: status prints one line to stderr that starts felix: , exits 1 and writes nothing" \
    "$(_ts4s_w2); home $s" "exit 1; 1 stderr line(s); felix: yes; home unchanged" "$(_ts4_why)"
  _ts4s_fresh
}
_ts4s_b() {   # WHAT PATH MODE: with PATH given MODE, status for q says not the authority's alone, and not once the mode is taken back
  local w; chmod "$3" "$2" 2>/dev/null; _ts4_a "$TS4S_Q" status; w="$(_ts4_whys)"
  chmod go-w "$2" 2>/dev/null; _ts4_a "$TS4S_Q" status
  _ts4_is "ts4 store W6: $1 is not the authority's alone, and status says so until the mode is taken back" "$w, then $(_ts4_whys)" "bcd, then cd" "$(_ts4_why)"
}
_ts4s_e() {   # WHAT ENV...: with that environment, status for q says not the authority's alone, and not without it
  local w n="$1"; shift; TS4_ENV=("$@"); _ts4_a "$TS4S_Q" status; TS4_ENV=(); w="$(_ts4_whys)"; _ts4_a "$TS4S_Q" status
  _ts4_is "ts4 store W6 e: $n, the standing is shadow with not the authority's alone, and that why is gone without it" "$w, then $(_ts4_whys)" "bcd, then cd" "$(_ts4_why)"
}

# ------------------------------------------------------------------ controls ---
is "ts4 store (control): the source holds main, five branches whose heads main's history lacks and one, old, whose head it holds, and merge merges cleanly onto main" \
  "$(_fx_git "$TS4S_S" for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null | LC_ALL=C sort | tr '\n' ' '); old in main: $(_ts4_yn _fx_git "$TS4S_S" merge-base --is-ancestor "$TS4S_M1" "$TS4S_M2"); merge: $(_ts4_kind "$TS4S_S" "$TS4S_M2" "$TS4S_HM")" \
  "Zed alpha beta-2 beta_1 main merge old ; old in main: yes; merge: tree"
is "ts4 store (control): this machine has no login ts4nologin, and has a login other than this one" "$(_ts4_yn id -u ts4nologin) $(_ts4_yn id -u "$TS4S_OTHER") $( [ "$TS4S_OTHER" != "$TS4_ME" ] && printf other)" "no yes other"
is "ts4 (control): the test's own escaping writes a newline, a backslash, a quote, an escape and a tab as section 0 says" "$(_ts4_esc $'a\nb\\c"d\033e\tf')" '"a\x0ab\x5cc\x22d\x1be\x09f"'
is "ts4 store (control): the PATH each felix call is given here names absolute directories only, and git, perl, awk, sed, ps and id are found in them" \
  "$(case ":$TS4_PATH:" in (*::*|*:[!/]*) printf 'an empty or relative entry' ;; (*) printf absolute ;; esac); missing: $(for _ts4s_c in git perl awk sed ps id; do _ts4_which "$_ts4s_c" >/dev/null || printf '%s ' "$_ts4s_c"; done)" "absolute; missing: "

# ------------------------------------------------------------------ init, the id and status (W4, W5, 2.2) ---
_ts4_init "$TS4S_A" "$TS4_ME" "$TS4S_S"; TS4S_ID="$TS4_ID"; TS4S_V="$(_ts4_mode "$TS4S_A")"
_ts4_is "ts4 store W4: init for this login prints one id of 40 lowercase hex digits and exits 0" \
  "exit $TS4_RC; ids: $(_ts4_hex40 < "$TS4/o" | LC_ALL=C sort -u | LC_ALL=C awk 'END { print NR }')" "exit 0; ids: 1" "$(_ts4_why)"
_ts4_is "ts4 store W4: init makes the home a directory with no access for group or other" "${TS4S_V:0:1}${TS4S_V:4:6}" "d------" "ls says [$TS4S_V]"
_ts4_is "ts4 store W1, W4: init writes authority.conf with a row for user, workers and source, each a key, one tab and its value" \
  "$(LC_ALL=C awk -F'\t' '$0 == "" || index($0, "#") == 1 { next } NF == 2 && ($1 == "user" || $1 == "workers" || $1 == "source") { print $1 "=" $2 }' "$TS4S_A/authority.conf" 2>/dev/null | LC_ALL=C sort | tr '\n' ' ')" \
  "source=$TS4S_S user=$TS4_ME workers=$TS4_ME "
_ts4_is "ts4 store W1: every row init wrote has a key of the table, exactly one tab and a value in printable ASCII" \
  "$(LC_ALL=C awk -F'\t' '$0 == "" || index($0, "#") == 1 { next } { r++ }
      NF != 2 || index(" user workers source source-main store door lock ", " " $1 " ") == 0 || $2 == "" || $2 ~ /[^ -~]/ { b++ }
      END { print (r >= 3 ? "rows" : "too few rows") ", " b + 0 " bad" }' "$TS4S_A/authority.conf" 2>/dev/null)" "rows, 0 bad"
_ts4_is "ts4 store W4: init makes the store, a bare git repository, and the door's directory, and makes no main and no statement" \
  "bare: $(_ts4_sg "$TS4S_ST" rev-parse --is-bare-repository); door: $(_ts4_yn test -d "$TS4S_A/door"); main and log: $(_ts4_sg "$TS4S_ST" for-each-ref refs/heads/main refs/felix/door | LC_ALL=C awk 'END { print NR }')" \
  "bare: true; door: yes; main and log: 0"
_ts4_a "$TS4S_A" status
_ts4_is "ts4 store 2.2: status exits 0 and prints authority, standing, the why lines, user, workers, home, store, door, source, source-main, lock, main, statements and word, in that order and nothing else" \
  "exit $TS4_RC; $(_ts4_keys)" "exit 0; authority standing why why why why user workers home store door source source-main lock main statements word " "$(_ts4_why)"
_ts4_is "ts4 store W5: status prints the id init printed" "$(_ts4_sv authority)" "${TS4S_ID:-no id from init}"
_ts4_is "ts4 store 2.2: status says this user and worker, the home, its store.git and door, the source, refs/heads/main, no lock, no main, no statement and go" \
  "$(_ts4_sv user)|$(_ts4_sv workers)|$(_ts4_sv home)|$(_ts4_sv store)|$(_ts4_sv door)|$(_ts4_sv source)|$(_ts4_sv source-main)|$(_ts4_sv lock)|$(_ts4_sv main)|$(_ts4_sv statements)|$(_ts4_sv word)" \
  "$TS4_ME|$TS4_ME|$TS4S_A|$TS4S_A/store.git|$TS4S_A/door|$TS4S_S|refs/heads/main|-|-|0|go"
_ts4_is "ts4 store case 1, W6: with this login as user and among workers the standing is shadow, with one why line each for a, c and d, and one for e: this login, a worker, owns the engine it runs" "$(_ts4_sv standing) $(_ts4_whys)" "shadow abcd"
_ts4_x "$TS4S_A" /dev/null help
_ts4_is "ts4 store 2: felix help names authority with init, status, tick, decide, log and verify, and felix door" \
  "$(LC_ALL=C awk 'index($0, "authority") { n = split("init status tick decide log verify", w, " "); for (i = 1; i <= n; i++) if (index($0, w[i])) s[w[i]] = 1 }
      index($0, "felix door") { s["door"] = 1 }
      END { n = split("init status tick decide log verify door", w, " "); for (i = 1; i <= n; i++) if (s[w[i]]) printf "%s ", w[i] }' "$TS4/o")" "init status tick decide log verify door "
_ts4_init "$TS4S_B" "$TS4_ME" "$TS4S_S"; TS4S_IDB="$TS4_ID"; _ts4_a "$TS4S_A" status
_ts4_is "ts4 store W5: a second store gets another id, and the first store's id is the same at a later status" \
  "second: $(if [ -n "$TS4S_IDB" ] && [ "$TS4S_IDB" != "$TS4S_ID" ]; then printf differs; else printf 'the same, or none'; fi); first: $(if [ -n "$TS4S_ID" ] && [ "$(_ts4_sv authority)" = "$TS4S_ID" ]; then printf same; else printf 'another, or none'; fi)" \
  "second: differs; first: same"

# ------------------------------------------------------------------ what init refuses, and what it takes (W4) ---
mkdir -p "$TS4S_X/full" "$TS4S_X/st"; : > "$TS4S_X/full/file"; : > "$TS4S_X/afile"
printf '#!/bin/sh\nprintf "%%s\\n" "$#" >> "%s"\n' "$TS4S_X/lock.marks" > "$TS4S_X/mark.sh"; chmod 755 "$TS4S_X/mark.sh"
_ts4s_noinit "a home that already holds authority.conf" "$TS4S_A" "${TS4S_U[@]}"
_ts4s_noinit "a store path that is a directory holding a file" "$TS4/r1" "${TS4S_U[@]}" --store "$TS4S_X/full"
_ts4s_noinit "a store path that is a file" "$TS4/r2" "${TS4S_U[@]}" --store "$TS4S_X/afile"
_ts4s_noinit "a user that is not the login this process runs as" "$TS4/r3" --user "$TS4S_OTHER" --workers "$TS4_ME" --source "$TS4S_S"
_ts4s_noinit "a worker that is no login of this machine" "$TS4/r4" --user "$TS4_ME" --workers "$TS4_ME,ts4nologin" --source "$TS4S_S"
_ts4s_noinit "a worker that is not a login name" "$TS4/r5" --user "$TS4_ME" --workers "$TS4_ME,-dash" --source "$TS4S_S"
_ts4s_noinit "a store that is not absolute" "$TS4/r6" "${TS4S_U[@]}" --store rel/store.git
_ts4s_noinit "a door that is not absolute" "$TS4/r7" "${TS4S_U[@]}" --door rel/door
_ts4s_noinit "a lock that is not absolute" "$TS4/r8" "${TS4S_U[@]}" --lock mark.sh
_ts4s_noinit "a source that holds a byte outside printable ASCII" "$TS4/r9" --user "$TS4_ME" --workers "$TS4_ME" --source "$TS4/caf$(printf '\303\251').git"
_ts4s_noinit "a source-main that holds a newline and a row of its own" "$TS4/r10" "${TS4S_U[@]}" --source-main "refs/heads/main${TS4_NL}lock$TS4_TAB/bin/true"
_ts4s_noinit "a source that is a relative path" "$TS4/r11" --user "$TS4_ME" --workers "$TS4_ME" --source rel/src.git
_ts4s_noinit "a source that starts with -" "$TS4/r12" --user "$TS4_ME" --workers "$TS4_ME" --source "-upload-pack=true"
_ts4s_noinit "a source of the ext:: transport" "$TS4/r13" --user "$TS4_ME" --workers "$TS4_ME" --source "ext::sh -c true"
_ts4s_noinit "a source that is an http:// URL" "$TS4/r14" --user "$TS4_ME" --workers "$TS4_ME" --source http://example.invalid/src.git
_ts4s_noinit "a source of the form user@host:path" "$TS4/r15" --user "$TS4_ME" --workers "$TS4_ME" --source git@example.invalid:src.git
_ts4s_noinit "a lock that holds a tab" "$TS4/r16" "${TS4S_U[@]}" --lock "$TS4S_X/mark.sh${TS4_TAB}x"
_ts4s_noinit "a door that holds a newline and a row of its own" "$TS4/r17" "${TS4S_U[@]}" --door "$TS4S_X/dr17${TS4_NL}workers${TS4_TAB}root"
_ts4_a "$TS4/fu" init --user "$TS4_ME" --workers "$TS4_ME" --source "file://$TS4S_S"; TS4S_V="exit $TS4_RC"; _ts4_a "$TS4/fu" status
_ts4_is "ts4 store W1: init takes a source that is a file:// URL, and status prints it" "$TS4S_V; $(_ts4_sv source)" "exit 0; file://$TS4S_S" "$(_ts4_why)"
_ts4_a "$TS4/c" init "${TS4S_U[@]}" --source-main refs/heads/trunk --store "$TS4S_X/st" --door "$TS4S_X/dr" --lock "$TS4S_X/mark.sh"; TS4S_V="exit $TS4_RC"
_ts4_a "$TS4/c" status
_ts4_is "ts4 store W4: init takes --source-main, --store (an empty directory that exists), --door and --lock, makes the store and the door there, and status prints each as given" \
  "$TS4S_V; $(_ts4_sv source-main)|$(_ts4_sv store)|$(_ts4_sv door)|$(_ts4_sv lock); bare: $(_ts4_sg "$TS4S_X/st" rev-parse --is-bare-repository); door: $(_ts4_yn test -d "$TS4S_X/dr")" \
  "exit 0; refs/heads/trunk|$TS4S_X/st|$TS4S_X/dr|$TS4S_X/mark.sh; bare: true; door: yes" "$(_ts4_why)"
TS4_UMASK=000; _ts4_init "$TS4/u" "$TS4_ME" "$TS4S_S"; TS4_UMASK=022; TS4S_V="$(_ts4_mode "$TS4/u")"
_ts4_is "ts4 store W4: under a umask of 000 init still makes the home with no access for group or other" "${TS4S_V:0:1}${TS4S_V:4:6}" "d------" "ls says [$TS4S_V]"

# ------------------------------------------------------------------ authority.conf (W1 to W3) ---
for _ts4s_c in status tick "decide $TS4S_M2" log verify door; do
  case "$_ts4s_c" in door) _ts4_x "$TS4/none" /dev/null door ;; *) _ts4_a "$TS4/none" $_ts4s_c ;; esac
  _ts4_is "ts4 store W2: with no authority.conf, ${_ts4s_c%% *} prints one line to stderr that starts felix: , exits 1 and makes no home" \
    "$(_ts4s_w2); home $(if [ -e "$TS4/none" ]; then printf made; else printf absent; fi)" "exit 1; 1 stderr line(s); felix: yes; home absent" "$(_ts4_why)"
done
[ ! -f "$TS4S_B/authority.conf" ] || cp "$TS4S_B/authority.conf" "$TS4S_X/b.conf"
_ts4s_add() { [ ! -f "$TS4S_B/authority.conf" ] || printf "$@" >> "$TS4S_B/authority.conf"; }   # FORMAT [ARG...]: appended to b's authority.conf
_ts4s_add '\n# a comment\n\n'; _ts4_a "$TS4S_B" status
_ts4_is "ts4 store W1: empty lines and lines that start # are not rows: status still reads the file" "exit $TS4_RC; $(_ts4_sv authority)" "exit 0; ${TS4S_IDB:-no id from init}" "$(_ts4_why)"
_ts4s_fresh
_ts4s_add 'colour\tblue\n'; _ts4s_unread "a key the table lacks"
_ts4s_add 'source\t%s\n' "$TS4S_S"; _ts4s_unread "a key given twice"
_ts4s_add 'lock /bin/true\n'; _ts4s_unread "a row with no tab"
_ts4s_add 'source main\trefs/heads/main\n'; _ts4s_unread "a key that holds a space"
_ts4s_add 'lock \t/bin/true\n'; _ts4s_unread "a key of the table with a space after it"
_ts4s_add 'lock\t/tmp/caf\303\251\n'; _ts4s_unread "a value with a byte outside printable ASCII"
_ts4s_add 'lock\t/tmp/a\tb\n'; _ts4s_unread "a value that holds a tab"
_ts4_conf "$TS4S_B" user 9lives; _ts4s_unread "a user that is not a login name"
_ts4_conf "$TS4S_B" workers "$TS4_ME,-dash"; _ts4s_unread "a worker that is not a login name"
_ts4_conf "$TS4S_B" store store.git; _ts4s_unread "a store that is not absolute"
_ts4_conf "$TS4S_B" door door; _ts4s_unread "a door that is not absolute"
_ts4_conf "$TS4S_B" lock mark.sh; _ts4s_unread "a lock that is not absolute"
_ts4_conf "$TS4S_B" source; _ts4s_unread "no row for source, a required key (a reading),"
_ts4_conf "$TS4S_B" source rel/src.git; _ts4s_unread "a source that is a relative path"
_ts4_conf "$TS4S_B" source "-upload-pack=true"; _ts4s_unread "a source that starts with -"
_ts4_conf "$TS4S_B" source "ext::sh -c true"; _ts4s_unread "a source of the ext:: transport"
_ts4_conf "$TS4S_B" source http://example.invalid/src.git; _ts4s_unread "a source that is an http:// URL"
_ts4_conf "$TS4S_B" source git@example.invalid:src.git; _ts4s_unread "a source of the form user@host:path"
_ts4s_add 'colour\tblue\n'; TS4S_V=""
for _ts4s_c in tick "decide $TS4S_M2" log verify door; do
  case "$_ts4s_c" in door) _ts4_x "$TS4S_B" /dev/null door ;; *) _ts4_a "$TS4S_B" $_ts4s_c ;; esac
  TS4S_V="$TS4S_V${_ts4s_c%% *}: $(_ts4s_w2) | "
done
_ts4s_fresh; TS4S_W='exit 1; 1 stderr line(s); felix: yes'
_ts4_is "ts4 store W2: with an unreadable authority.conf, tick, decide, log, verify and door each print one line to stderr that starts felix: and exit 1" \
  "$TS4S_V" "tick: $TS4S_W | decide: $TS4S_W | log: $TS4S_W | verify: $TS4S_W | door: $TS4S_W | "
_ts4_conf "$TS4S_B" workers "$TS4_ME,$TS4S_OTHER"; _ts4_conf "$TS4S_B" source-main refs/heads/trunk; _ts4_conf "$TS4S_B" lock "$TS4S_X/mark.sh"; _ts4_a "$TS4S_B" status
_ts4_is "ts4 store W1, W3: a parameter is the row of authority.conf: with the workers, source-main and lock rows rewritten, status prints the new values" \
  "$(_ts4_sv workers)|$(_ts4_sv source-main)|$(_ts4_sv lock)" "$TS4_ME,$TS4S_OTHER|refs/heads/trunk|$TS4S_X/mark.sh" "$(_ts4_why)"
_ts4s_fresh

# ------------------------------------------------------------------ the first start (case 3, W11, D7) ---
_ts4_a "$TS4S_A" tick
_ts4_is "ts4 store case 3: before the first start a tick prints paused with no main, exits 3, decides nothing and makes no main" \
  "exit $TS4_RC; paused, no main: $(_ts4_paused 'no main'); candidate lines: $(_ts4_cands); main: $(_ts4_main "$TS4S_A")" "exit 3; paused, no main: yes; candidate lines: 0; main: none" "$(_ts4_why)"
_ts4_plain "$TS4S_A" stop stop
_ts4_is "ts4 store D4: on an empty log a verb other than start is refused, and nothing is kept" "exit $TS4_DRC; refused: $(_ts4_refused); statements: $(_ts4_n "$TS4S_A")" "exit 1; refused: yes; statements: 0" "$(_ts4_dwhy)"
_ts4_say "$TS4S_A" "start $TS4_NOPE"
_ts4_is "ts4 store D4: a start that names no commit the store holds is refused, and makes no main" "exit $TS4_DRC; refused: $(_ts4_refused); statements: $(_ts4_n "$TS4S_A"); main: $(_ts4_main "$TS4S_A")" "exit 1; refused: yes; statements: 0; main: none" "$(_ts4_dwhy)"
_ts4_say "$TS4S_A" "start $TS4S_M2"
_ts4_is "ts4 store case 3: start COMMIT, confirmed with the four characters its card brackets, is kept as statement 0 and makes main at COMMIT" \
  "exit $TS4_DRC; kept: $TS4_KEPT; main: $(_ts4_main "$TS4S_A"); statements: $(_ts4_n "$TS4S_A")" "exit 0; kept: 0; main: $TS4S_M2; statements: 1" "$(_ts4_dwhy)"
_ts4_is "ts4 store case 1, D8: that statement is a start of the commit, serial 0, with no statement before it, given in shadow" \
  "$(_ts4_fs "$TS4S_A" 0 'verb commit serial prev given')" "start|$TS4S_M2|0|-|shadow"
_ts4_a "$TS4S_A" log
_ts4_is "ts4 store 2.6, case 1: log prints one row of seven fields for it: its number, verb, commit, no tree, shadow, no, and a time" \
  "exit $TS4_RC; rows: $(LC_ALL=C awk 'END { print NR }' "$TS4/o"); $(_ts4_lr 0); time: $(LC_ALL=C awk -F'\t' '$1 == 0 { print ($7 == "" ? "none" : "given") }' "$TS4/o")" \
  "exit 0; rows: 1; 7:0|start|$TS4S_M2|-|shadow|no; time: given" "$(_ts4_why)"
_ts4_a "$TS4S_A" status
_ts4_is "ts4 store case 1, 2.2: after a start given in shadow, status prints main and one statement, and the standing is still shadow, with each why it had" \
  "$(_ts4_sv main)|$(_ts4_sv statements)|$(_ts4_sv standing) $(_ts4_whys)" "$TS4S_M2|1|shadow abcd" "$(_ts4_why)"
_ts4_plain "$TS4S_A" "start $TS4S_M1" "start ${TS4S_M1:0:4}"
_ts4_is "ts4 store D4, W11: a start on a log that holds a statement is refused, and main stays" "exit $TS4_DRC; refused: $(_ts4_refused); statements: $(_ts4_n "$TS4S_A"); main: $(_ts4_main "$TS4S_A")" "exit 1; refused: yes; statements: 1; main: $TS4S_M2" "$(_ts4_dwhy)"

# ------------------------------------------------------------------ a tick and decide (2.5, W7) ---
_ts4_a "$TS4S_A" tick
_ts4_is "ts4 store 2.5, W7: a tick prints one line of five tab-separated fields for each candidate, each beginning with the standing, in the byte order of the branch names, then tick: shadow, 5 candidates, and exits 0" \
  "exit $TS4_RC; $(LC_ALL=C awk -F'\t' 'NF == 5 { printf "%s %s;", $1, $4 }' "$TS4/o") lines: $(LC_ALL=C awk 'END { print NR ", the last [" $0 "]" }' "$TS4/o")" \
  'exit 0; shadow "Zed";shadow "alpha";shadow "beta-2";shadow "beta_1";shadow "merge"; lines: 6, the last [tick: shadow, 5 candidates]' "$(_ts4_why)"
_ts4_is "ts4 store 2.5: each line holds its branch's head whole; main's own branch and a branch whose head is in main's history get none; an ordinary change is eligible with no detail" \
  "$(LC_ALL=C awk -F'\t' 'NF == 5 { printf "%s %s %s %s;", $4, $3, $2, $5 }' "$TS4/o")" \
  "\"Zed\" $TS4S_HZ eligible -;\"alpha\" $TS4S_HA eligible -;\"beta-2\" $TS4S_H2 eligible -;\"beta_1\" $TS4S_H1 eligible -;\"merge\" $TS4S_HM eligible -;"
_ts4_a "$TS4S_A" decide "$TS4S_HZ"
_ts4_is "ts4 store 2.5: decide COMMIT prints that head's one line, with - as the branch" "$(tr '\t' '|' < "$TS4/o")" "shadow|eligible|$TS4S_HZ|-|-" "$(_ts4_why)"
_ts4_ci "$TS4S_S" late "$TS4S_M2" 'pushed after the tick' notes/late.txt; TS4S_HL="$TS4_C"
_ts4_dd "$TS4S_A" "$TS4S_HL"; TS4S_V="$TS4_DEC; in the store: $(_ts4_yn _ts4_sg "$TS4S_ST" cat-file -e "$TS4S_HL^{commit}")"; _ts4_a "$TS4S_A" tick
_ts4_is "ts4 store 2.5: decide does not fetch: a head pushed after the last tick gets no line and is not in the store, and the next tick lists it" \
  "$TS4S_V; then $(_ts4_of "$TS4S_HL")" "no line; in the store: no; then eligible|-" "$(_ts4_why)"

# ------------------------------------------------------------------ main and the tip the store recorded (W11) ---
_ts4_sg "$TS4S_ST" update-ref refs/heads/main "$TS4S_HZ" >/dev/null; TS4S_V="moved: $(_ts4_yn test "$(_ts4_main "$TS4S_A")" = "$TS4S_HZ")"; _ts4_a "$TS4S_A" tick
TS4S_V="$TS4S_V; exit $TS4_RC; paused: $(_ts4_paused 'not the tip this authority recorded'); candidate lines: $(_ts4_cands)"
_ts4_sg "$TS4S_ST" update-ref refs/heads/main "$TS4S_M2" >/dev/null; _ts4_a "$TS4S_A" tick
_ts4_is "ts4 store W11: a tick that finds main moved by another hand prints paused with not the tip this authority recorded, exits 3 and decides nothing; with main put back it decides again" \
  "$TS4S_V; then exit $TS4_RC, $(_ts4_cands) candidate lines" "moved: yes; exit 3; paused: yes; candidate lines: 0; then exit 0, 6 candidate lines" "$(_ts4_why)"
_ts4_ci "$TS4S_S" main "$TS4S_M2" 'main moves on' main/three; TS4S_M3="$TS4_C"; _ts4_a "$TS4S_A" tick; TS4S_V="exit $TS4_RC; main: $(_ts4_main "$TS4S_A")"; _ts4_a "$TS4S_A" status
_ts4_is "ts4 store W11: in shadow a tick moves main forward to the source's main when that descends from it, and status prints it" "$TS4S_V; status: $(_ts4_sv main)" "exit 0; main: $TS4S_M3; status: $TS4S_M3" "$(_ts4_why)"
_ts4_ci "$TS4S_S" - "$TS4S_M2" 'a main that does not descend' main/fork; _fx_git "$TS4S_S" update-ref refs/heads/main "$TS4_C" >/dev/null 2>&1; _ts4_a "$TS4S_A" tick
_ts4_is "ts4 store W11: when the source's main does not descend from main, the tick prints paused with does not descend, exits 3, decides nothing, and main stays" \
  "exit $TS4_RC; paused: $(_ts4_paused 'does not descend'); candidate lines: $(_ts4_cands); main: $(_ts4_main "$TS4S_A")" "exit 3; paused: yes; candidate lines: 0; main: $TS4S_M3" "$(_ts4_why)"
_fx_git "$TS4S_S" update-ref refs/heads/main "$TS4S_M3" >/dev/null 2>&1

# ------------------------------------------------------------------ git, as the authority runs it (W10) ---
# merge, cut from M1, changes the first line of notes/f; main changed its last. git's own merge is clean and is the tree
# TS4S_CT. Under the hostile driver the same merge keeps main's side, which is main's tree, and the decision would be
# nothing; under the attribute source it conflicts. The attribute source is a commit the store holds: the branch attrs.
TS4_BODY='notes/f -merge'; _ts4_ci "$TS4S_S" attrs "$TS4S_M3" 'attributes of a worker' .gitattributes; TS4_BODY=""; TS4S_HT="$TS4_C"
TS4S_CT="$(_ts4_merge "$TS4S_S" "$TS4S_M3" "$TS4S_HM")"
_ts4_a "$TS4S_A" tick
_ts4_is "ts4 store W10, K8 (the base case): the tick says the merging head is eligible, and its ledger row holds main and the tree git's own merge makes" \
  "$(_ts4_of "$TS4S_HM"); $(_ts4_lrow "$TS4S_A" "$TS4S_HM")" "eligible|-; 7:shadow|eligible|$TS4S_HM|$TS4S_M3|$TS4S_CT|-" "$(_ts4_why)"
printf '* merge=ts4keep\n' > "$TS4S_X/attrs"; mkdir -p "$TS4S_X/home"
printf '[merge "ts4keep"]\n\tdriver = true\n[core]\n\tattributesFile = %s\n' "$TS4S_X/attrs" > "$TS4S_X/hostile.cfg"; cp "$TS4S_X/hostile.cfg" "$TS4S_X/home/.gitconfig"
for _ts4s_c in GIT_CONFIG_GLOBAL HOME GIT_CONFIG_COUNT GIT_CONFIG_SYSTEM GIT_CONFIG_PARAMETERS GIT_ATTR_SOURCE; do
  case "$_ts4s_c" in
    GIT_CONFIG_GLOBAL) TS4_ENV=(GIT_CONFIG_GLOBAL="$TS4S_X/hostile.cfg") ;;
    HOME) TS4_ENV=(HOME="$TS4S_X/home" XDG_CONFIG_HOME="$TS4S_X/home/none") ;;
    GIT_CONFIG_COUNT) TS4_ENV=(GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=merge.ts4keep.driver GIT_CONFIG_VALUE_0=true GIT_CONFIG_KEY_1=core.attributesFile GIT_CONFIG_VALUE_1="$TS4S_X/attrs") ;;
    GIT_CONFIG_SYSTEM) TS4_ENV=(GIT_CONFIG_NOSYSTEM=0 GIT_CONFIG_SYSTEM="$TS4S_X/hostile.cfg") ;;
    GIT_CONFIG_PARAMETERS) TS4_ENV=(GIT_CONFIG_PARAMETERS="'merge.ts4keep.driver=true' 'core.attributesFile=$TS4S_X/attrs'") ;;
    GIT_ATTR_SOURCE) TS4_ENV=(GIT_ATTR_SOURCE="$TS4S_HT") ;;
  esac
  TS4S_V="$( export "${TS4_ENV[@]}"; _fx_git "$TS4S_S" merge-tree --write-tree "$TS4S_M3" "$TS4S_HM" 2>/dev/null )"; TS4S_V="${TS4S_V%%$TS4_NL*}"
  if [ -z "$TS4S_CT" ] || [ "$TS4S_V" = "$TS4S_CT" ]; then
    TS4_ENV=(); skip "ts4 store W10: a caller's $_ts4s_c does not change the merge the authority makes: decide still says the head is eligible" "plain git's merge here is not changed by it, so nothing is staged"
    continue
  fi
  _ts4_dd "$TS4S_A" "$TS4S_HM"; TS4_ENV=()
  _ts4_is "ts4 store W10: a caller's $_ts4s_c does not change the merge the authority makes: decide still says the head is eligible" "$TS4_DEC" "eligible|-" "$(_ts4_why)"
done
# A url.insteadOf in the caller's configuration that points the source's path at another repository, which holds evil.
_ts4_src "$TS4S_X/evil.git"; _ts4_base "$TS4S_X/evil.git"; _ts4_ci "$TS4S_X/evil.git" evil "$TS4_M2" 'from another repository' notes/evil.txt
printf '[url "%s"]\n\tinsteadOf = %s\n' "$TS4S_X/evil.git" "$TS4S_S" > "$TS4S_X/instead.cfg"
TS4S_V="$( export GIT_CONFIG_GLOBAL="$TS4S_X/instead.cfg"; _fx_git "$TS4S_S" ls-remote "$TS4S_S" 2>/dev/null )"
case "$TS4S_V" in
  *refs/heads/evil*)
    TS4_ENV=(GIT_CONFIG_GLOBAL="$TS4S_X/instead.cfg"); _ts4_a "$TS4S_A" tick; TS4_ENV=()
    _ts4_is "ts4 store W10: a caller's url.insteadOf does not change which repository a tick fetches: its candidates are the source's own" \
      "$(LC_ALL=C awk -F'\t' 'NF == 5 { printf "%s;", $4 }' "$TS4/o")" '"Zed";"alpha";"attrs";"beta-2";"beta_1";"late";"merge";' "$(_ts4_why)" ;;
  *) skip "ts4 store W10: a caller's url.insteadOf does not change which repository a tick fetches: its candidates are the source's own" "plain git here does not follow it, so nothing is staged" ;;
esac
# A fetch checks each object: the source f gains, after the first start, a branch whose commit has no author line.
TS4S_F="$TS4/f.git"; _ts4_src "$TS4S_F"; _ts4_base "$TS4S_F"; _ts4_src "$TS4S_X/p.git"; _ts4_src "$TS4S_X/q.git"
_ts4_init "$TS4/g" "$TS4_ME" "$TS4S_F"; _ts4_say "$TS4/g" "start $TS4_M2"; TS4S_V="start kept: $TS4_KEPT"
printf 'tree %s\nparent %s\n\na commit with no author line\n' "$(_ts4_ctree "$TS4S_F" "$TS4_M2")" "$TS4_M2" > "$TS4S_X/raw"
TS4S_BAD="$(_fx_git "$TS4S_F" hash-object -t commit -w --literally "$TS4S_X/raw" 2>/dev/null)"
[ -z "$TS4S_BAD" ] || _fx_git "$TS4S_F" update-ref refs/heads/broken "$TS4S_BAD" >/dev/null 2>&1
( export GIT_CONFIG_GLOBAL=/dev/null; _fx_git "$TS4S_X/p.git" fetch -q "$TS4S_F" 'refs/heads/*:refs/src/*'; _fx_git "$TS4S_X/q.git" -c fetch.fsckObjects=true fetch -q "$TS4S_F" 'refs/heads/*:refs/src/*' ) >/dev/null 2>&1
TS4S_W="plain: $(_ts4_yn _fx_git "$TS4S_X/p.git" cat-file -e "${TS4S_BAD:-none}"); checked: $(_ts4_yn _fx_git "$TS4S_X/q.git" cat-file -e "${TS4S_BAD:-none}")"
if [ "$TS4S_W" = "plain: yes; checked: no" ]; then
  ok "ts4 store W10 (control): this git's plain fetch takes a commit with no author line, and its fetch that checks objects refuses it"
  _ts4_a "$TS4/g" tick
  _ts4_is "ts4 store W10: a fetch checks each object it takes: after a tick the store does not hold a commit with no author line, and no line calls it eligible" \
    "$TS4S_V; in the store: $(_ts4_yn _ts4_sg "$TS4/g/store.git" cat-file -e "$TS4S_BAD"); its line: $(_ts4_of "$TS4S_BAD" | cut -d'|' -f1)" "start kept: 0; in the store: no; its line: no line" "$(_ts4_why)"
else
  skip "ts4 store W10 (control): this git's plain fetch takes a commit with no author line, and its fetch that checks objects refuses it" "$TS4S_W"
  skip "ts4 store W10: a fetch checks each object it takes: after a tick the store does not hold a commit with no author line, and no line calls it eligible" "the malformed commit could not be staged with this git"
fi

# ------------------------------------------------------------------ root as the worker (W6 a, case 2) ---
_ts4_init "$TS4/l3" root "$TS4S_S"; _ts4_a "$TS4/l3" status; TS4S_V="$(_ts4_sv standing) $(_ts4_whys)"; _ts4_say "$TS4/l3" "start $TS4S_M3"
_ts4_is "ts4 store W6 a, case 2: with root as the worker the standing is shadow with not its own login and not the authority's alone, whoever this login is, and a start given there is kept as given in shadow" \
  "$TS4S_V; kept: $TS4_KEPT; $(_ts4_fs "$TS4/l3" 0 given)" "shadow abcd; kept: 0; shadow" "$(_ts4_dwhy)"

# ------------------------------------------------------------------ another login as the worker: conditions b and e (W6, case 22) ---
# From here each store has another login of this machine, not root, as its one worker. Where none is found, or where
# status gives such a store a why line of a, b or e before anything is staged, what follows is skipped by name.
TS4_LOCK="$TS4S_X/mark.sh"; _ts4_logins
if [ "$TS4_PS" = yes ] && [ -n "$TS4_IDLE" ] && [ -n "$TS4_BUSY" ]; then
  ok "ts4 store (control): ps lists this machine's processes, and it has a login other than this one that runs none and one, not root, that runs some"
else
  TS4_SKIP="no login that runs no process, or none but root that runs some, was found here (ps lists: $TS4_PS)"
  skip "ts4 store (control): ps lists this machine's processes, and it has a login other than this one that runs none and one, not root, that runs some" "$TS4_SKIP"
fi
_ts4_init "$TS4S_Q" "${TS4_IDLE:-none}" "$TS4S_S"; _ts4_canstand "$TS4S_Q" "${TS4_IDLE:-none}"
_ts4_init "$TS4/l2" "${TS4_BUSY:-none}" "$TS4S_S" --lock "$TS4S_X/mark.sh"; _ts4_canstand "$TS4/l2" "${TS4_BUSY:-none}"
_ts4_a "$TS4S_Q" status
_ts4_is "ts4 store W6: with another login, not root, as the only worker, conditions a, b and e hold: the standing is shadow with the why lines of c and d alone" "$(_ts4_sv standing) $(_ts4_whys)" "shadow cd" "$(_ts4_why)"
_ts4s_b "a home its group can write" "$TS4S_Q" g+w
_ts4s_b "a store anyone can write" "$TS4S_Q/store.git" o+w
_ts4s_b "a door directory its group can write" "$TS4S_Q/door" g+w
_ts4s_b "a store in which one file can be written by its group" "$TS4S_Q/store.git/HEAD" g+w
[ ! -d "$TS4S_Q/door" ] || : > "$TS4S_Q/door/ts4-note"; _ts4s_b "a door directory in which one file can be written by anyone" "$TS4S_Q/door/ts4-note" o+w; rm -f "$TS4S_Q/door/ts4-note"
TS4S_N="ts4 store W6 b: a home that carries an access-control list is not the authority's alone, and status says so until the list is taken off"
if [ -z "$TS4_SKIP" ] && [ -d "$TS4S_Q" ] && ! chmod +a "everyone allow read" "$TS4S_Q" 2>/dev/null; then
  skip "$TS4S_N" "chmod +a put no access-control list on a directory here"
else
  _ts4_a "$TS4S_Q" status; TS4S_W="$(_ts4_whys)"; chmod -N "$TS4S_Q" 2>/dev/null; _ts4_a "$TS4S_Q" status
  _ts4_is "$TS4S_N" "$TS4S_W, then $(_ts4_whys)" "bcd, then cd" "$(_ts4_why)"
fi
TS4_UMASK=000; _ts4_init "$TS4/u2" "${TS4_IDLE:-none}" "$TS4S_S"; TS4_UMASK=022; _ts4_a "$TS4/u2" status
_ts4_is "ts4 store W6 (a reading): and the store and the door init made under a umask of 000 are the authority's alone: status gives no why of condition b" "$(_ts4_sv standing) $(_ts4_whys)" "shadow cd" "$(_ts4_why)"
TS4S_V="$(find "$FROOT/harness/lib" -type f 2>/dev/null | LC_ALL=C sort | LC_ALL=C awk 'NR == 1')"
_ts4s_b "a file of the engine's lib that anyone can write (W6 e)" "${TS4S_V:-$TS4S_X/none}" o+w
_ts4_conf "$TS4S_Q" lock "$TS4S_X/mark.sh"
_ts4s_b "a lock program anyone can write (W6 e)" "$TS4S_X/mark.sh" o+w
_ts4s_b "a lock program whose directory anyone can write (W6 e)" "$TS4S_X" o+w
TS4S_N="ts4 store W6 e: a lock that carries an access-control entry that allows is within a worker's reach, and one whose only entry denies is not"
if [ -z "$TS4_SKIP" ] && [ -d "$TS4S_Q" ] && ! chmod +a "everyone allow write" "$TS4S_X/mark.sh" 2>/dev/null; then
  skip "$TS4S_N" "chmod +a put no access-control entry on a file here"
else
  _ts4_a "$TS4S_Q" status; TS4S_W="allows: $(_ts4_whys)"; chmod -N "$TS4S_X/mark.sh" 2>/dev/null
  chmod +a "everyone deny delete" "$TS4S_X/mark.sh" 2>/dev/null; _ts4_a "$TS4S_Q" status; TS4S_W="$TS4S_W; denies: $(_ts4_whys)"; chmod -N "$TS4S_X/mark.sh" 2>/dev/null
  _ts4_is "$TS4S_N" "$TS4S_W" "allows: bcd; denies: cd" "$(_ts4_why)"
fi
_ts4_conf "$TS4S_Q" lock
mkdir -p "$TS4S_X/wbin"; ln -s "$(_ts4_which git)" "$TS4S_X/wbin/git" 2>/dev/null; chmod 777 "$TS4S_X/wbin"
_ts4_is "ts4 store (control): a directory that every login can write, holding a program named git that runs, is staged" "$(_ts4_mode "$TS4S_X/wbin" | cut -c9) $(_ts4_yn "$TS4S_X/wbin/git" --version)" "w yes"
_ts4s_e "case 22: with a directory every login can write first on PATH" PATH="$TS4S_X/wbin:$TS4_PATH"
chmod 755 "$TS4S_X/wbin"
_ts4s_e "with an empty entry on PATH" PATH="$TS4_PATH:"
_ts4s_e "with an entry on PATH that is not absolute" PATH="$TS4_PATH:rel/bin"

# ------------------------------------------------------------------ how a statement is given (W8, case 2) ---
_ts4_say "$TS4/l2" "start $TS4S_M3"
_ts4_is "ts4 store case 2, D4: with a worker login that runs a process, a start would be given at the desktop and is refused: nothing is kept and no main is made" \
  "exit $TS4_DRC; refused: $(_ts4_refused); statements: $(_ts4_n "$TS4/l2"); main: $(_ts4_main "$TS4/l2")" "exit 1; refused: yes; statements: 0; main: none" "$(_ts4_dwhy)"
_ts4_init "$TS4S_L" "${TS4_IDLE:-none}" "$TS4S_S" --lock "$TS4S_X/mark.sh"; _ts4_canstand "$TS4S_L" "${TS4_IDLE:-none}"
_ts4_is "ts4 store W6: a lock, when one is set and is the authority's alone, changes nothing: the standing is shadow with the why lines of c and d alone" "$(_ts4_sv standing) $(_ts4_whys)" "shadow cd" "$(_ts4_why)"
_ts4_say "$TS4S_L" "start $TS4S_M3"; TS4S_V="kept: $TS4_KEPT; $(_ts4_fs "$TS4S_L" 0 given)"; TS4S_W="$(_ts4_dwhy)"; _ts4_a "$TS4S_L" log; TS4S_V="$TS4S_V; $(_ts4_lr 0)"; _ts4_a "$TS4S_L" status
_ts4_is "ts4 store case 2, W8: a start kept while the worker's login runs no process is given at the console and counts, and only the reach test then keeps the standing at shadow" \
  "$TS4S_V; $(_ts4_sv standing) $(_ts4_whys)" "kept: 0; console; 7:0|start|$TS4S_M3|-|console|yes; shadow d" "$TS4S_W"
_ts4_conf "$TS4S_L" workers "${TS4_BUSY:-none}"; _ts4_say "$TS4S_L" "hold $TS4S_HZ"; TS4S_V="kept: $TS4_KEPT; locked: $(_ts4_count locked "$TS4/door.a.out")"; TS4S_W="$(_ts4_dwhy)"; _ts4_a "$TS4S_L" log
_ts4_is "ts4 store case 2, W8: with a worker login that runs a process a statement is given at the desktop, and with no reach pass before it it does not count" \
  "$TS4S_V; $(_ts4_lr 1)" "kept: 1; locked: 1; 7:1|hold|$TS4S_HZ|-|desktop|no" "$TS4S_W"
_ts4_conf "$TS4S_L" lock; _ts4_say "$TS4S_L" "hold $TS4S_HA"
_ts4_is "ts4 store D4, W8: a statement that would be given at the desktop is refused when no lock is set, and nothing is kept" \
  "exit $TS4_DRC; refused: $(_ts4_refused); statements: $(_ts4_n "$TS4S_L")" "exit 1; refused: yes; statements: 2" "$(_ts4_dwhy)"
_ts4_conf "$TS4S_L" lock "$TS4S_X/mark.sh"; _ts4_conf "$TS4S_L" workers "${TS4_IDLE:-none}"; mkdir -p "$TS4S_X/noproc" "$TS4S_X/noone"
for _ts4s_c in ps pgrep; do
  printf '#!/bin/sh\n: >> "%s"\necho "%s: cannot list processes" >&2\nexit 1\n' "$TS4S_X/noproc/asked" "$_ts4s_c" > "$TS4S_X/noproc/$_ts4s_c"
  printf '#!/bin/sh\n: >> "%s"\nexit 0\n' "$TS4S_X/noone/asked" > "$TS4S_X/noone/$_ts4s_c"; chmod 755 "$TS4S_X/noproc/$_ts4s_c" "$TS4S_X/noone/$_ts4s_c"
done
TS4_ENV=(PATH="$TS4S_X/noproc:$TS4_PATH"); _ts4_say "$TS4S_L" "hold $TS4S_HA"; TS4_ENV=()
if [ -z "$TS4_SKIP" ] && [ "$TS4_HAVE" = yes ] && [ ! -e "$TS4S_X/noproc/asked" ]; then
  skip "ts4 store W8: where the processes cannot be listed, a statement is given at the desktop, though the worker's login runs none" "the door asked neither ps nor pgrep on PATH, so nothing here stages a machine whose processes cannot be listed"
else
  _ts4_is "ts4 store W8: where the processes cannot be listed, a statement is given at the desktop, though the worker's login runs none" \
    "kept: $TS4_KEPT; given: $(_ts4_fs "$TS4S_L" "${TS4_KEPT:-999}" given)" "kept: 2; given: desktop" "$(_ts4_dwhy)"
fi
TS4S_W="$(_ts4_n "$TS4S_L")"; TS4_ENV=(PATH="$TS4S_X/noone:$TS4_PATH"); _ts4_say "$TS4S_L" "hold $TS4S_H2"; TS4_ENV=()
if [ -z "$TS4_SKIP" ] && [ "$TS4_HAVE" = yes ] && [ ! -e "$TS4S_X/noone/asked" ]; then
  skip "ts4 store W8: where the list of processes comes back without process 1 and without the door's own, a statement is given at the desktop, though the worker's login runs none" "the door asked neither ps nor pgrep on PATH, so nothing here stages a list that lacks them"
else
  _ts4_is "ts4 store W8: where the list of processes comes back without process 1 and without the door's own, a statement is given at the desktop, though the worker's login runs none" \
    "kept: ${TS4_KEPT:-none}; given: $(_ts4_fs "$TS4S_L" "${TS4_KEPT:-999}" given)" "kept: ${TS4S_W:-none}; given: desktop" "$(_ts4_dwhy)"
fi
# W8, rev 2: how the statement is given is read when the door opens and again when it keeps. Here it opens at the
# desktop, and before the confirmation is typed the home is made writable by its group, so it would be kept in shadow.
_ts4_conf "$TS4S_L" workers "${TS4_BUSY:-none}"; TS4S_W="$(_ts4_n "$TS4S_L")"; _ts4_open "$TS4S_L" a "hold $TS4S_H1"
TS4S_V="$(_ts4_line 'given: ' "$TS4/door.a.out")"; TS4S_V="card: $(if [ -n "$TS4_FOUR" ]; then printf shown; else printf none; fi), as given at the ${TS4S_V#given: }"
chmod g+w "$TS4S_L" 2>/dev/null; TS4S_V="$TS4S_V; then the home's group: $(_ts4_mode "$TS4S_L" | cut -c6)"; _ts4_close a "hold $TS4_FOUR"; chmod g-w "$TS4S_L" 2>/dev/null
_ts4_is "ts4 store W8 (rev 2): a door that opened at the desktop and would keep in shadow, the home having been made writable by its group meanwhile, keeps nothing and prints refused: " \
  "$TS4S_V; exit $TS4_DRC; refused: $(_ts4_refused); kept: ${TS4_KEPT:-none}; statements: $(_ts4_n "$TS4S_L")" "card: shown, as given at the desktop; then the home's group: w; exit 1; refused: yes; kept: none; statements: ${TS4S_W:-none}" "$(_ts4_dwhy)"
# Case 16 at the desktop. A statement is kept first, so that the count of refused confirmations starts here.
_ts4_say "$TS4S_L" "hold $TS4S_H1"; TS4S_V="a statement kept at the $(_ts4_fs "$TS4S_L" "${TS4_KEPT:-999}" given)"; TS4S_W="$(_ts4_closed "$TS4S_L")"
for _ts4s_c in 1 2 3; do _ts4_plain "$TS4S_L" "hold $TS4S_HM" "hold $(_ts4_wrong "$TS4S_HM")"; TS4S_V="$TS4S_V; $_ts4s_c: exit $TS4_DRC, kept ${TS4_KEPT:-none}"; done
_ts4_is "ts4 store case 16, D6: at the desktop, three statements typed with a guessed confirmation and the card unread keep nothing and leave three rows in refused.tsv" \
  "$TS4S_V; rows: $(( $(_ts4_closed "$TS4S_L") - ${TS4S_W:-0} )) more" "a statement kept at the desktop; 1: exit 1, kept none; 2: exit 1, kept none; 3: exit 1, kept none; rows: 3 more" "$(_ts4_dwhy)"
TS4S_W="$(_ts4_closed "$TS4S_L")"; _ts4_say "$TS4S_L" "hold $TS4S_HM"
_ts4_is "ts4 store case 16, D4, D2: after those three the door at the desktop reads back refused-confirmations: 3 and refuses to take a statement: it shows no card, keeps nothing and leaves no row more" \
  "$(_ts4_line 'refused-confirmations: ' "$TS4/door.a.out"); cards: $(_ts4_count 'confirm: ' "$TS4/door.a.out"); exit $TS4_DRC; refused: $(_ts4_refused); kept: ${TS4_KEPT:-none}; rows: $(( $(_ts4_closed "$TS4S_L") - ${TS4S_W:-0} )) more" \
  "refused-confirmations: 3; cards: 0; exit 1; refused: yes; kept: none; rows: 0 more" "$(_ts4_dwhy)"
TS4S_W="$(_ts4_n "$TS4S_L")"; _ts4_conf "$TS4S_L" workers "${TS4_IDLE:-none}"; _ts4_say "$TS4S_L" "hold $TS4S_HM"; TS4S_V="at the $(_ts4_fs "$TS4S_L" "${TS4_KEPT:-999}" given): kept ${TS4_KEPT:-none}"
_ts4_conf "$TS4S_L" workers "${TS4_BUSY:-none}"; _ts4_say "$TS4S_L" "hold $TS4S_HL"
_ts4_is "ts4 store case 16, D4: the next statement is given at the console, and after it the door at the desktop takes a statement again" \
  "$TS4S_V; then at the $(_ts4_fs "$TS4S_L" "${TS4_KEPT:-999}" given): kept ${TS4_KEPT:-none}" "at the console: kept ${TS4S_W:-none}; then at the desktop: kept $(( ${TS4S_W:-0} + 1 ))" "$(_ts4_dwhy)"
TS4_SKIP=""; TS4_LOCK=""

_ts4_end
unset TS4S_S TS4S_A TS4S_B TS4S_L TS4S_Q TS4S_N TS4S_ST TS4S_X TS4S_M1 TS4S_M2 TS4S_M3 TS4S_HZ TS4S_HA TS4S_H2 TS4S_H1 TS4S_HM TS4S_HL TS4S_HT TS4S_CT TS4S_OTHER TS4S_U \
  TS4S_ID TS4S_IDB TS4S_V TS4S_W TS4S_F TS4S_BAD _ts4s_c
# <<< trust-step4-authority-store
