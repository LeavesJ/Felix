# >>> land-on-green-round-8
printf '\nland on green: the amendment A31 (contract A31, blind)\n'
# Blind, from the contract's "Amended after install, 2026-10-18" alone, on the
# fixture parts 1280-1287 build: lib/green-install.sh, lib/green-tick.sh,
# lib/resolve.sh and the felix CLI were not read. The trampoline is run as
# launchd runs it: an empty environment but HOME, FELIX_HOME_DIR and PATH, from
# a directory that is not the home.
#
# macOS's privacy control cannot be summoned from a fixture, so the open A31
# asks for is failed another way, one where [ -r ] still says yes:
#   - a unix socket named plugin.json: [ -r ] passes and open(2) is refused.
#     This is the case that follows the contract to the letter (an open that
#     fails). It needs perl to bind the socket, and skips without it.
#   - a directory named plugin.json: [ -r ] passes, bash can open it for
#     reading, and only a read of it fails. So this case holds only for a
#     trampoline that reads a byte, not one that merely opens.
#   - a file of mode 000, when the suite is not root.
# A git first on the trampoline's PATH logs each call and runs the real one, so
# "before anything else" can be seen: an unopenable file leaves it no call to
# make. It sits ahead of the stubs only for the trampoline, never for felix land.
_lg_build amend
L8="$LG/round8"; L8CWD="$(pwd -P)"; mkdir -p "$L8/gitbin" "$L8/home2/engine/.claude-plugin"
L8TR="$LGU/Library/Application Support/felix/land/lgh/tick"
L8PL="$LGU/Library/LaunchAgents/felix.land.lgh.plist"
L8PJ="$LGH/engine/.claude-plugin/plugin.json"; L8P2="$L8/home2/engine/.claude-plugin/plugin.json"
L8T="$(printf '\t')"
command -v git > "$L8/realgit"; cp -p "$L8PJ" "$L8/plugin.json.keep"
_lg_put "$L8/gitbin/git" <<'L8STUB'
#!/bin/bash
LG='@LG@'
printf '%s\n' "$*" >> "$LG/log/git.log"
exec "$(cat "$LG/round8/realgit")" "$@"
L8STUB
_l8_ticks() { _lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick"' | wc -l | tr -d ' '; }
_l8_mainv() { git -C "$LGH" show refs/remotes/origin/main:engine/.claude-plugin/plugin.json 2>/dev/null | sed -n 's/.*"version": *"\([^"]*\)".*/\1/p'; }
_l8_tramp() {   # [HOME-DIR] -> the trampoline as launchd runs it, FELIX_HOME_DIR as given; status in L8RC
  ( cd "$TMP/cwd" 2>/dev/null || cd "$LG" || exit 97
    exec env -i HOME="$LGU" FELIX_HOME_DIR="${1:-$LGH}" PATH="$L8/gitbin:$LGB:$PATH" \
      GIT_CEILING_DIRECTORIES="${GIT_CEILING_DIRECTORIES-}" "$L8TR" ) > "$LG/out.tramp" 2>&1
  L8RC=$?
}
_l8_probe() {   # FILE -> whether [ -r ] passes, and whether opening it for reading is refused
  local a=unreadable b=opens
  [ -r "$1" ] && a=readable
  ( : < "$1" ) 2>/dev/null || b=refused
  printf '%s %s' "$a" "$b"
}
_l8_sock() {   # FILE -> a unix socket at FILE (bound by a relative name, for the length of the path)
  ( cd "$(dirname "$1")" || exit 97
    exec perl -e 'use Socket; socket(S, PF_UNIX, SOCK_STREAM, 0) or exit 1; bind(S, sockaddr_un($ARGV[0])) or exit 2; exit 0' "$(basename "$1")" ) >/dev/null 2>&1
}
_l8_restore() { chmod -R u+rwx "$L8PJ" 2>/dev/null; rm -rf "$L8PJ"; cp -p "$L8/plugin.json.keep" "$L8PJ"; }
_l8_unread() {   # WHAT -> the trampoline twice over an unopenable plugin.json: what A31 says of the failed open
  local w="$1" r1 r2 d; _lg_reset; _l8_tramp; r1=$L8RC; _l8_tramp; r2=$L8RC; d="$(_lg_f unreadable "" 7)"
  is "A31: $w: the trampoline exits 1, on each of two runs" "$r1 $r2" "1 1"
  is "A31: $w: it runs no felix at all, so no felix land --tick" "$(_lg_cnt felix)|$(_l8_ticks)" "0|0"
  is "A31: $w: it runs no git: nothing comes before the open" "$(_lg_cnt git)" "0"
  is "A31: $w: two identical runs write one row of kind unreadable, and no other row" "$(_lg_n unreadable)|$(_lg_rows)" "1|1"
  is "A31: $w: and send one notification" "$(_lg_cnt osa)" "1"
  is "A31: $w: the row is seven tab-separated fields with - for pull request, head and worktree" \
     "$(LC_ALL=C awk -F'\t' '$2 == "unreadable" { printf "%d|%s|%s|%s", NF, $3, $4, $5 }' "$LAND/ledger.tsv" 2>/dev/null)" "7|-|-|-"
  case "$(_lg_f unreadable "" 1)" in ""|-) bad "A31: $w: and it carries a time" "[$(_lg_f unreadable "" 1)]" ;; *) ok "A31: $w: and it carries a time" ;; esac
  has "A31: $w: the detail names FELIX_HOME_DIR" "$d" "$LGH"
  has "A31: $w: and says macOS may be refusing the read" "$d" "macOS"
  has "A31: $w: and that /bin/bash needs Full Disk Access" "$d" "/bin/bash"
  has "A31: $w: naming Full Disk Access" "$d" "Full Disk Access"
  has "A31: $w: and where to give it, as the contract writes it" "$d" "System Settings > Privacy & Security > Full Disk Access"
  _lg_osa 'with title "Felix: unreadable"' "A31: $w: the notification is titled Felix: unreadable"
  has "A31: $w: and carries the detail" "$(_lg_logs osa | cut -f1)" "Full Disk Access"
}
_l8_unread_short() {   # WHAT -> the same, in its four parts that do not depend on how the file was made unopenable
  local w="$1" r1 r2; _lg_reset; _l8_tramp; r1=$L8RC; _l8_tramp; r2=$L8RC
  is "A31: $w: the trampoline exits 1, on each of two runs" "$r1 $r2" "1 1"
  is "A31: $w: it runs no felix at all" "$(_lg_cnt felix)" "0"
  is "A31: $w: two identical runs write one row of kind unreadable, and no other row" "$(_lg_n unreadable)|$(_lg_rows)" "1|1"
  is "A31: $w: and send one notification titled Felix: unreadable" \
     "$(_lg_cnt osa)|$(_lg_logs osa | grep -c 'with title "Felix: unreadable"')" "1|1"
}
# The helpers of the cases added after the amendment was reworded (the section
# "after the amendment was reworded" below, and the _l8_unread_more calls).
L8N=0   # the status of a run that goes on, set by the control below
_l8x_tramp() {   # [HOME-DIR] -> _l8_tramp, ended after twenty seconds (status 124): a build that waits on a byte that never ends
  ( cd "$TMP/cwd" 2>/dev/null || cd "$LG" || exit 97
    exec env -i HOME="$LGU" FELIX_HOME_DIR="${1:-$LGH}" PATH="$L8/gitbin:$LGB:$PATH" \
      GIT_CEILING_DIRECTORIES="${GIT_CEILING_DIRECTORIES-}" "$L8TR" ) > "$LG/out.tramp" 2>&1 &
  local p=$! n=0
  while kill -0 "$p" 2>/dev/null && [ "$n" -lt 200 ]; do sleep 0.1; n=$((n+1)); done
  if kill -0 "$p" 2>/dev/null; then kill -KILL "$p" 2>/dev/null; wait "$p" 2>/dev/null; L8RC=124
  else wait "$p"; L8RC=$?; fi
}
_l8x_titles() { _lg_logs osa | cut -f1 | sed -n 's/.*with title "\([^"]*\)".*/\1/p' | tr '\n' '|'; }   # every notification's title, each followed by |
_l8x_fields() { LC_ALL=C awk -F'\t' -v k="$1" '$2 == k { s = sprintf("%d|%s|%s|%s", NF, $3, $4, $5) } END { printf "%s", s }' "$LAND/ledger.tsv" 2>/dev/null; }   # EVENT -> seven fields|pull request|head|worktree of the last such row
_l8x_goes_on() {   # WHAT -> after a run in L8RC: the status of a normal run, main's entry's tick once, and nothing written or sent
  is "A31: $1: the trampoline goes on: exit status as a normal run, and main's entry's felix land --tick runs once" \
     "$L8RC|$(_l8_ticks)|$(_lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick" { print $1 }')" "$L8N|1|$LGV/$L8V/harness/felix"
  is "A31: $1: and writes no row of any kind, so no unreadable row, and sends no notification" "$(_lg_n unreadable)|$(_lg_rows)|$(_lg_cnt osa)" "0|0|0"
}
_l8_unread_more() {   # WHAT -> after _l8_unread_short: nothing, git included, ran before the refusal, and the detail says what macOS needs
  local w="$1" d; d="$(_lg_f unreadable "" 7)"
  is "A31: $w: it ran no git: no git call came before the refusal" "$(_lg_cnt git)" "0"
  has "A31: $w: the detail names FELIX_HOME_DIR" "$d" "$LGH"
  has "A31: $w: and says macOS may be refusing the read" "$d" "macOS"
  has "A31: $w: and that /bin/bash needs Full Disk Access" "$d" "/bin/bash"
  has "A31: $w: naming Full Disk Access" "$d" "Full Disk Access"
  has "A31: $w: and where to give it, as the contract writes it" "$d" "System Settings > Privacy & Security > Full Disk Access"
  has "A31: $w: and the notification carries the detail" "$(_lg_logs osa | cut -f1)" "Full Disk Access"
}

# --------------------------------------------------- the fixture, checked ---
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1
L8V="$(_l8_mainv)"; [ -n "$L8V" ] && _lg_cache "$L8V"
is "A31 (fixture control): the home is on main at origin's main, which declares a version, and plugin.json is a file it can read" \
   "$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" rev-parse --abbrev-ref HEAD 2>&1)|$([ -n "$L8V" ] && echo v)|$(_l8_probe "$L8PJ")" \
   "$(git -C "$LGO" rev-parse main 2>&1)|main|v|readable opens"
is "A31 (fixture control): the home holds no change, tracked or untracked, under engine/" \
   "$(git -C "$LGH" status --porcelain -- engine 2>&1 | tr '\n' '|')" ""
_lg_reset; _lg_land --uninstall; _lg_land --install
is "A31 (fixture control): --install exits 0 and leaves the plist and an executable trampoline" \
   "$LGRC|$([ -f "$L8PL" ] && echo plist)|$([ -x "$L8TR" ] && echo tramp)" "0|plist|tramp"

# ----------------------------------------------------------- the program ---
is "A31: the trampoline's first line is #!/bin/bash" "$(head -n 1 "$L8TR" 2>&1)" "#!/bin/bash"
_l8p="$( { tr -d ' \t\r\n' < "$L8PL"; } 2>/dev/null)"
has "A31: the plist's ProgramArguments are /bin/bash, then the trampoline's path, and nothing else" "$_l8p" \
    "<key>ProgramArguments</key><array><string>/bin/bash</string><string>$(printf '%s' "$L8TR" | tr -d ' ')</string></array>"
if plutil -extract Label raw -o - "$L8PL" >/dev/null 2>&1; then
  is "A31: plutil reads ProgramArguments as two strings: /bin/bash, then the trampoline's path with its space" \
     "$(plutil -extract ProgramArguments raw -o - "$L8PL" 2>&1)|$(plutil -extract ProgramArguments.0 raw -o - "$L8PL" 2>&1)|$(plutil -extract ProgramArguments.1 raw -o - "$L8PL" 2>&1)" \
     "2|/bin/bash|$L8TR"
else skip "A31: plutil reads ProgramArguments as two strings: /bin/bash, then the trampoline's path with its space" "no plutil that extracts raw values on this machine"; fi

# ----------------------------------------- the open that succeeds, goes on ---
_lg_reset; _l8_tramp
is "A31: with plugin.json a file it can open, the trampoline goes on as before: it runs main's entry's felix land --tick once and exits 0" \
   "$L8RC|$(_l8_ticks)|$(_lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick" { print $1 }')" "0|1|$LGV/$L8V/harness/felix"
is "A31: and writes no unreadable row and sends no notification" "$(_lg_n unreadable)|$(_lg_rows)|$(_lg_cnt osa)" "0|0|0"
is "A31 (fixture control): the git wrapper sees the trampoline's own git when the open succeeds, so no git in the cases below means it ran before them" \
   "$([ "$(_lg_cnt git)" -ge 1 ] && echo seen)" "seen"

# --------------------------------------- the open that fails: a socket ---
if command -v perl >/dev/null 2>&1; then
  mv "$L8PJ" "$L8/plugin.json.moved"; _l8_sock "$L8PJ"
  is "A31 (fixture control): plugin.json is a socket: [ -r ] passes and opening it for reading is refused" \
     "$([ -S "$L8PJ" ] && echo socket)|$(_l8_probe "$L8PJ")" "socket|readable refused"
  _l8_unread "with plugin.json a socket ([ -r ] passes, the open is refused)"
  # The open is first: main's entry is gone, which A1 would say as a deploy-owed
  # row, and the unopenable file still leaves the unreadable row alone.
  [ -n "$L8V" ] && rm -rf "$LGV/$L8V"
  _lg_reset; _l8_tramp
  is "A31: the open comes before A1's check: with main's cache entry gone, the unopenable file writes the unreadable row alone and no deploy-owed row" \
     "$L8RC|$(_lg_n unreadable)|$(_lg_n deploy-owed)|$(_lg_rows)|$(_lg_cnt felix)|$(_lg_cnt git)" "1|1|0|1|0|0"
  [ -n "$L8V" ] && _lg_cache "$L8V"
  # A row is written when it differs from the previous one: another home, an
  # unopenable plugin.json there too, is another detail.
  _l8_sock "$L8P2"
  _lg_reset; _l8_tramp; _l8_tramp; _l8_tramp "$L8/home2"
  is "A31 (fixture control): the second home's plugin.json is a socket" "$([ -S "$L8P2" ] && echo socket)" "socket"
  is "A31: the row is written again when it differs from the previous one: a second home gives a second row and a second notification, and exit 1" \
     "$(_lg_n unreadable)|$(_lg_cnt osa)|$L8RC" "2|2|1"
  has "A31: and that row names the second home" "$(_lg_f unreadable "" 7)" "$L8/home2"
  rm -f "$L8P2"; _l8_restore
  is "A31 (fixture control): plugin.json is the home's file again, as it was" \
     "$(cksum < "$L8PJ")|$(_l8_probe "$L8PJ")" "$(cksum < "$L8/plugin.json.keep")|readable opens"
else
  skip "A31: with plugin.json a socket, the trampoline writes one unreadable row, notifies once, exits 1 and runs nothing" "no perl to bind a socket"
fi

# ------------------------------------- the open that fails: a directory ---
mv "$L8PJ" "$L8/plugin.json.moved"; mkdir "$L8PJ"
is "A31 (fixture control): plugin.json is a directory: [ -r ] passes" "$([ -d "$L8PJ" ] && echo dir)|$([ -r "$L8PJ" ] && echo readable)" "dir|readable"
_l8_unread_short "with plugin.json a directory (a trampoline that reads a byte refuses it; one that only opens does not)"
_l8_unread_more "with plugin.json a directory, the refusal as the contract words it"
_l8_restore

# ----------------------------------------- the open that fails: mode 000 ---
if [ "$(id -u)" != 0 ]; then
  chmod 000 "$L8PJ"
  is "A31 (fixture control): plugin.json is a file of mode 000 that cannot be opened" "$([ -f "$L8PJ" ] && echo file)|$(_l8_probe "$L8PJ")" "file|unreadable refused"
  _l8_unread_short "with plugin.json a file of mode 000"
  _l8_unread_more "with plugin.json a file of mode 000, the refusal as the contract words it"
  _l8_restore
else skip "A31: with plugin.json a file of mode 000, the trampoline writes one unreadable row, notifies once and exits 1" "the suite runs as root, which opens any file"; fi

# --------------------------------------------------------------- --status ---
_l8_led() {   # -> PR 5's two rows and PR 6's, the job installed, loaded, not paused
  _lg_reset; mkdir -p "$LAND"
  { printf '2026-10-18T08:00:00Z\tskip\t5\t%s\t-\t0\tdraft\n' "$(_lg_sha 21)"
    printf '2026-10-18T08:05:00Z\tsession\t5\t%s\t-\t1\tno checkout holds the gated head\n' "$(_lg_sha 21)"
    printf '2026-10-18T08:06:00Z\tlanded\t6\t%s\t%s\t3\tmerged\n' "$(_lg_sha 22)" "$LGW/b22"; } > "$LAND/ledger.tsv"
  : > "$LGK/loaded"
}
_l8_ln() { sed -n "${1}p" "$LG/out"; }
_l8_led; printf '2026-10-18T08:07:00Z\tunreadable\t-\t-\t-\t0\tquartz detail of the newest row, FELIX_HOME_DIR cannot be read\n' >> "$LAND/ledger.tsv"
_l8s0="$(_lgsnap)"; _lg_land --status --tsv
is "A31: --status --tsv exits 0" "$LGRC" 0
is "A31: --status --tsv keeps installed, loaded and paused as its first three lines" "$(sed -n 1,3p "$LG/out" | tr '\t\n' ':|')" "installed:yes|loaded:yes|paused:no|"
is "A31: --status --tsv prints a fourth line: last, a tab, then the ledger's newest row exactly as the ledger has it, a row whose pull request is - included" \
   "$(_l8_ln 4)" "last${L8T}$(tail -n 1 "$LAND/ledger.tsv")"
is "A31: --status --tsv prints one last line" "$(LC_ALL=C awk -F'\t' '$1 == "last"' "$LG/out" | wc -l | tr -d ' ')" "1"
_l8a="$(sed -n 1,4p "$LG/out")"; _l8b="$(sed -n '5,$p' "$LG/out")"
case "$_l8b" in *"$(sed -n 2p "$LAND/ledger.tsv")"*) ok "A31: the pull requests' rows follow last, as before: PR 5's newest row" ;;
  *) bad "A31: the pull requests' rows follow last, as before: PR 5's newest row" "after line 4: [$_l8b]" ;; esac
case "$_l8b" in *"$(sed -n 3p "$LAND/ledger.tsv")"*) ok "A31: and PR 6's row, both after line 4" ;;
  *) bad "A31: and PR 6's row, both after line 4" "after line 4: [$_l8b]" ;; esac
case "$_l8b" in *"$(sed -n 1p "$LAND/ledger.tsv")"*) bad "A31: and not a pull request's earlier rows" "after line 4: [$_l8b]" ;;
  *) ok "A31: and not a pull request's earlier rows" ;; esac
case "$_l8a" in *"$(sed -n 3p "$LAND/ledger.tsv")"*) bad "A31: no pull request's row comes before last" "in the first four lines: [$_l8a]" ;;
  *) ok "A31: no pull request's row comes before last" ;; esac
is "A31: --status writes nothing: the land directory and LaunchAgents are as they were, and launchctl bootstraps and boots out nothing" \
   "$(_lgsnap)|$(_lg_logs launchctl | grep -cE '^(bootstrap|bootout|load|unload)')" "$_l8s0|0"
mkdir -p "$LAND"; printf 'held for the test\n' > "$LAND/paused"; _lg_land --status --tsv
is "A31: paused yes does not move last: the fourth line is still the newest row" "$(_l8_ln 3)|$(_l8_ln 4)" "paused${L8T}yes|last${L8T}$(tail -n 1 "$LAND/ledger.tsv")"
rm -f "$LAND/paused"

# The newest row belongs to a pull request.
_l8_led; printf '2026-10-18T08:09:00Z\trefused\t7\t%s\t-\t2\tblocker one: the receipt is stale\n' "$(_lg_sha 40)" >> "$LAND/ledger.tsv"
_lg_land --status --tsv
is "A31: with a pull request's row newest, --status --tsv's last line is that row exactly as the ledger has it" \
   "$(_l8_ln 4)" "last${L8T}$(tail -n 1 "$LAND/ledger.tsv")"
case "$(sed -n '5,$p' "$LG/out")" in *"$(tail -n 1 "$LAND/ledger.tsv")"*) ok "A31: and that pull request's row also follows last, as before" ;;
  *) bad "A31: and that pull request's row also follows last, as before" "after line 4: [$(sed -n '5,$p' "$LG/out")]" ;; esac

# A ledger with no row.
_lg_reset; : > "$LGK/loaded"; _lg_land --status --tsv
is "A31: with no ledger, --status --tsv prints four lines, the fourth last, a tab, none" \
   "$(tr '\t\n' ':|' < "$LG/out")" "installed:yes|loaded:yes|paused:no|last:none|"
_lg_reset; mkdir -p "$LAND"; : > "$LAND/ledger.tsv"; : > "$LGK/loaded"; _lg_land --status --tsv
is "A31: with an empty ledger, --status --tsv prints four lines, the fourth last, a tab, none" \
   "$(tr '\t\n' ':|' < "$LG/out")" "installed:yes|loaded:yes|paused:no|last:none|"

# Plain.
_l8_led; printf '2026-10-18T08:07:00Z\tunreadable\t-\t-\t-\t0\tquartz detail of the newest row, FELIX_HOME_DIR cannot be read\n' >> "$LAND/ledger.tsv"
_lg_land --status
_l8o="$(sed -n 1,3p "$LG/out" | LC_ALL=C awk '{ k = $1; gsub(/[^a-z]/, "", k); printf "%s %s|", k, $NF }')"
is "A31: plain --status keeps installed, loaded and paused, each yes or no, as its first three lines" "$_l8o" "installed yes|loaded yes|paused no|"
case "$(_l8_ln 4)" in last*) ok "A31: plain --status's fourth line starts with last" ;; *) bad "A31: plain --status's fourth line starts with last" "[$(_l8_ln 4)]" ;; esac
has "A31: and shows the newest row's time" "$(_l8_ln 4)" "2026-10-18T08:07:00Z"
has "A31: and its kind" "$(_l8_ln 4)" "unreadable"
has "A31: and its detail" "$(_l8_ln 4)" "quartz detail of the newest row, FELIX_HOME_DIR cannot be read"
_l8b="$(sed -n '5,$p' "$LG/out")"
case "$_l8b" in *landed*) ok "A31: the pull requests' rows follow last: PR 6's landed row" ;; *) bad "A31: the pull requests' rows follow last: PR 6's landed row" "after line 4: [$_l8b]" ;; esac
case "$_l8b" in *session*) ok "A31: and PR 5's newest row" ;; *) bad "A31: and PR 5's newest row" "after line 4: [$_l8b]" ;; esac
case "$_l8b" in *skip*) bad "A31: and not PR 5's earlier row" "after line 4: [$_l8b]" ;; *) ok "A31: and not PR 5's earlier row" ;; esac
_lg_reset; : > "$LGK/loaded"; _lg_land --status
case "$(_l8_ln 4)" in last*none*) ok "A31: plain --status with no ledger says last, then none, on its fourth line" ;;
  *) bad "A31: plain --status with no ledger says last, then none, on its fourth line" "[$(_l8_ln 4)]" ;; esac

# An install whose job cannot run shows it at the next status.
if command -v perl >/dev/null 2>&1; then
  mv "$L8PJ" "$L8/plugin.json.moved"; _l8_sock "$L8PJ"; _lg_reset; _l8_tramp; _l8_restore
  : > "$LGK/loaded"; _lg_land --status --tsv
  is "A31: an unreadable home shows at the next status: --status --tsv's last line is the trampoline's own unreadable row" \
     "$(_l8_ln 4 | cut -f1,3)|$(_l8_ln 4)" "last${L8T}unreadable|last${L8T}$(tail -n 1 "$LAND/ledger.tsv")"
  _lg_land --status
  has "A31: and plain --status says unreadable on its last line" "$(_l8_ln 4)" "unreadable"
  has "A31: and names Full Disk Access there" "$(_l8_ln 4)" "Full Disk Access"
else skip "A31: an unreadable home shows at the next status" "no perl to bind a socket"; fi

# ------------------------------------- after the amendment was reworded ---
# Blind, from the contract's A31 as it stands after review. The read is a read:
# a file that is not regular but reads is not a refusal, and neither is one with
# no byte in it, so no type or permission test stands in for it. A home that
# cannot be entered keeps A10's deploy-owed row and its title. A run whose read
# succeeds after an unreadable row says so in a row of kind readable, with no
# notification, and a ledger whose newest row is of any other kind says nothing.
_lg_reset; _l8x_tramp; L8N=$L8RC
is "A31 (fixture control): a run with a plugin.json holding bytes exits 0 and runs main's entry's tick once: that is the status of a run that goes on" \
   "$L8N|$(_l8_ticks)" "0|1"

# ---------------------------- a file that is not regular, and one with no byte ---
mv "$L8PJ" "$L8/plugin.json.moved"; ln -s /dev/zero "$L8PJ"
is "A31 (fixture control): plugin.json is a symbolic link to /dev/zero: [ -f ] says it is not a regular file, [ -r ] says it is readable, it opens, and a byte reads" \
   "$([ -L "$L8PJ" ] && echo link)|$([ -f "$L8PJ" ] && echo f || echo notf)|$(_l8_probe "$L8PJ")|$(head -c 1 "$L8PJ" 2>/dev/null | wc -c | tr -d ' ')" "link|notf|readable opens|1"
_lg_reset; _l8x_tramp
_l8x_goes_on "with plugin.json a symbolic link to /dev/zero (it opens and a byte reads, but [ -f ] says it is not a regular file)"
rm -f "$L8PJ"; : > "$L8PJ"
is "A31 (fixture control): plugin.json is an empty regular file: [ -f ] and [ -r ] pass, it opens, and no byte reads" \
   "$([ -f "$L8PJ" ] && echo file)|$([ -s "$L8PJ" ] && echo bytes || echo empty)|$(_l8_probe "$L8PJ")|$(head -c 1 "$L8PJ" 2>/dev/null | wc -c | tr -d ' ')" "file|empty|readable opens|0"
_lg_reset; _l8x_tramp
_l8x_goes_on "with plugin.json an empty regular file (it opens and has no byte to read, which is not a refusal)"
_l8_restore

# ------------------------ a home that cannot be entered keeps A10's row ---
_lg_reset; _l8x_tramp "$L8/no-home"; _l8x_tramp "$L8/no-home"
is "A31 (fixture control): the FELIX_HOME_DIR below does not exist" "$([ -e "$L8/no-home" ] && echo exists || echo missing)" "missing"
is "A31: a FELIX_HOME_DIR that does not exist: the trampoline runs no felix at all" "$(_lg_cnt felix)" "0"
is "A31: a FELIX_HOME_DIR that does not exist: two identical runs write exactly one row, of kind deploy-owed, and no unreadable row and no other row" \
   "$(_lg_n deploy-owed)|$(_lg_n unreadable)|$(_lg_rows)" "1|0|1"
_la_names "A31: a FELIX_HOME_DIR that does not exist: the detail says the home cannot be entered" \
   "$(_lg_f deploy-owed "" 7)" enter "change into" "change to" "cd " chdir
is "A31: a FELIX_HOME_DIR that does not exist: the row is seven tab-separated fields with - for pull request, head and worktree" "$(_l8x_fields deploy-owed)" "7|-|-|-"
is "A31: a FELIX_HOME_DIR that does not exist: two identical runs send one notification" "$(_lg_cnt osa)" "1"
is "A31: a FELIX_HOME_DIR that does not exist: its title is exactly Felix: deploy-owed" "$(_l8x_titles)" "Felix: deploy-owed|"

# -------- a readable plugin.json and no deploy: the trampoline's other rows ---
[ -n "$L8V" ] && rm -rf "$LGV/$L8V"
_lg_reset; _l8x_tramp; L8R1=$L8RC; _l8x_tramp; L8R2=$L8RC
is "A31 (fixture control): main's cache entry is gone, and plugin.json is the home's file, which opens" \
   "$([ -e "$LGV/$L8V" ] && echo there || echo gone)|$(_l8_probe "$L8PJ")" "gone|readable opens"
is "A31: with plugin.json readable and main's cache entry gone, the trampoline exits 1 on each of two runs and runs no felix" "$L8R1 $L8R2|$(_lg_cnt felix)" "1 1|0"
is "A31: with plugin.json readable and main's cache entry gone, two runs write exactly one row, of kind deploy-owed, and no unreadable row and no other row" \
   "$(_lg_n deploy-owed)|$(_lg_n unreadable)|$(_lg_rows)" "1|0|1"
is "A31: with plugin.json readable and main's cache entry gone, two runs send one notification, and its title is exactly Felix: deploy-owed" \
   "$(_lg_cnt osa)|$(_l8x_titles)" "1|Felix: deploy-owed|"
[ -n "$L8V" ] && _lg_cache "$L8V"

# ---------------------------------------------------------------- recovery ---
# The job is refused, Full Disk Access is given, and the next run reads the home.
mv "$L8PJ" "$L8/plugin.json.moved"; mkdir "$L8PJ"
_lg_reset; _l8x_tramp; L8R1=$L8RC; L8U1="$(sed -n 1p "$LAND/ledger.tsv" 2>/dev/null)"
is "A31 (fixture control): recovery: with plugin.json a directory the first run writes the unreadable row, the ledger's only row, sends one notification, runs nothing and exits 1" \
   "$L8R1|$(_l8_ticks)|$(_lg_n unreadable)|$(_lg_rows)|$(_lg_cnt osa)" "1|0|1|1|1"
_l8_restore; _l8x_tramp
is "A31: recovery: a run whose read succeeds after an unreadable row goes on: exit status as a normal run, and main's entry's felix land --tick runs once" \
   "$L8RC|$(_l8_ticks)|$(_lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick" { print $1 }')" "$L8N|1|$LGV/$L8V/harness/felix"
is "A31: recovery: it writes exactly one row of kind readable, after the unreadable row, and no other: the ledger reads unreadable, readable" \
   "$(_lg_n readable)|$(_lg_n unreadable)|$(_lg_rows)|$(cut -f2 "$LAND/ledger.tsv" 2>/dev/null | tr '\n' ' ')" "1|1|2|unreadable readable "
is "A31: recovery: the unreadable row is as it was, the ledger only appended to" "$(sed -n 1p "$LAND/ledger.tsv" 2>/dev/null)" "$L8U1"
is "A31: recovery: the readable row is seven tab-separated fields with - for pull request, head and worktree" "$(_l8x_fields readable)" "7|-|-|-"
case "$(_lg_f readable "" 1)" in ""|-) bad "A31: recovery: and the readable row carries a time" "[$(_lg_f readable "" 1)]" ;; *) ok "A31: recovery: and the readable row carries a time" ;; esac
has "A31: recovery: the readable row's detail names FELIX_HOME_DIR" "$(_lg_f readable "" 7)" "$LGH"
_la_names "A31: recovery: and says it read the home" "$(_lg_f readable "" 7)" read
is "A31: recovery: no notification is sent for the readable row: the one notification is the unreadable row's" "$(_lg_cnt osa)|$(_l8x_titles)" "1|Felix: unreadable|"
_l8x_tramp
is "A31: recovery: a second run whose read succeeds writes no second readable row, sends nothing, and goes on" \
   "$(_lg_n readable)|$(_lg_rows)|$(_lg_cnt osa)|$L8RC|$(_l8_ticks)" "1|2|1|$L8N|2"
: > "$LGK/loaded"; _lg_land --status --tsv
is "A31: recovery: after it, --status --tsv exits 0 and its last line holds the readable row, as the ledger has it" \
   "$LGRC|$(_l8_ln 4)" "0|last${L8T}$(LC_ALL=C awk -F'\t' '$2 == "readable"' "$LAND/ledger.tsv" 2>/dev/null | tail -n 1)"
is "A31: recovery: and that row is of kind readable" "$(_l8_ln 4 | cut -f1,3)" "last${L8T}readable"
_lg_land --status
has "A31: recovery: plain --status's last line says readable" "$(_l8_ln 4)" "readable"
# The previous row of a refusal after a recovery is the readable row, which differs.
rm -rf "$L8PJ"; mkdir "$L8PJ"; _l8x_tramp
is "A31: recovery: a refusal after a recovery is a new unreadable row and a new notification, because the previous row, the readable one, differs: exit 1, three rows, two notifications" \
   "$L8RC|$(_lg_n unreadable)|$(_lg_rows)|$(_l8x_titles)" "1|2|3|Felix: unreadable|Felix: unreadable|"
_l8_restore; _l8x_tramp
is "A31: recovery: and the next recovery writes its own readable row and sends nothing: two readable rows, four rows, still two notifications" \
   "$(_lg_n readable)|$(_lg_rows)|$(_lg_cnt osa)|$L8RC" "2|4|2|$L8N"

# A newest row of any other kind, an older unreadable row below it, is no recovery.
for L8K in deploy-owed deployed deploy-failed deployed-unverified paused skip session founder refused landed gh; do
  case "$L8K" in skip|session|founder|refused|landed) L8A=5; L8B="$(_lg_sha 21)" ;; *) L8A=-; L8B=- ;; esac
  _lg_reset; mkdir -p "$LAND"
  { printf '2026-10-18T07:00:00Z\tunreadable\t-\t-\t-\t0\tan older unreadable row, %s\n' "$LGH"
    printf '2026-10-18T07:30:00Z\t%s\t%s\t%s\t-\t0\tthe newest row, of kind %s\n' "$L8K" "$L8A" "$L8B" "$L8K"; } > "$LAND/ledger.tsv"
  _l8x_tramp
  is "A31: recovery: with the newest row of kind $L8K and an older unreadable row below it, a run whose read succeeds writes no readable row, and goes on as a normal run does" \
     "$(_lg_n readable)|$(_lg_rows)|$(_lg_cnt osa)|$L8RC|$(_l8_ticks)" "0|2|0|$L8N|1"
done

# An unreadable row is the newest row however it came to be there.
_lg_reset; mkdir -p "$LAND"
printf '2026-10-18T07:00:00Z\tunreadable\t-\t-\t-\t0\tseeded by hand: the read of a home was refused\n' > "$LAND/ledger.tsv"
L8U1="$(sed -n 1p "$LAND/ledger.tsv")"; _l8x_tramp
is "A31: recovery: with the ledger's newest row an unreadable one, a run whose read succeeds writes one readable row after it, leaves it as it was, sends nothing, and goes on" \
   "$(_lg_n readable)|$(_lg_rows)|$(_lg_cnt osa)|$L8RC|$(_l8_ticks)|$(sed -n 1p "$LAND/ledger.tsv")" "1|2|0|$L8N|1|$L8U1"

# The readable row comes first, and the trampoline then goes on: its next row is seen after it.
[ -n "$L8V" ] && rm -rf "$LGV/$L8V"
_lg_reset; mkdir -p "$LAND"
printf '2026-10-18T07:00:00Z\tunreadable\t-\t-\t-\t0\tseeded by hand: the read of a home was refused\n' > "$LAND/ledger.tsv"
_l8x_tramp
is "A31: recovery: the readable row is written first, and the trampoline then goes on: with main's entry gone, the ledger reads unreadable, readable, deploy-owed, and the run exits 1 having run no felix" \
   "$L8RC|$(_lg_cnt felix)|$(cut -f2 "$LAND/ledger.tsv" 2>/dev/null | tr '\n' ' ')" "1|0|unreadable readable deploy-owed "
is "A31: recovery: and the one notification is the deploy-owed row's, titled exactly Felix: deploy-owed: the readable row sent none" "$(_lg_cnt osa)|$(_l8x_titles)" "1|Felix: deploy-owed|"
[ -n "$L8V" ] && _lg_cache "$L8V"

# ----------------------------------------------------------------- clean ---
_l8_restore; _lg_reset; _lg_land --uninstall; _lg_reset; rm -rf "$L8"
is "A31 (fixture control): the home's plugin.json is the file it was, and the part leaves the working directory where it found it" \
   "$([ -f "$L8PJ" ] && [ ! -S "$L8PJ" ] && echo file)|$(git -C "$LGH" status --porcelain -- engine 2>&1 | tr '\n' '|')|$(pwd -P)" "file||$L8CWD"
