printf '\nthe pulse agent runs where macOS lets it start (contract P1-P5, blind)\n'
# Blind, written from docs/2026-10-29-pulse-agent-contract.md alone on
# 2026-10-29. Nothing here was read off lib/pulse.sh or the pulse command.
#
# launchd opens StandardOutPath itself, before the program starts, and macOS
# refuses that open under ~/Documents. On the new Mac the agent's capture sat
# inside the Felix home there, and the spawn failed with 78 every morning while
# nothing Felix reads said so. These assertions drive the real CLI the way the
# install block of part 0470 does: launchctl and uname are stubbed in a PATH
# directory, HOME is a fixture directory, and a registered marketplace root
# serves the engine. Every name under $TMP here begins pa71-, so this part runs
# alone (contract C) and touches nothing another part builds.
#
# The plist is plain XML the engine writes. It is read by flattening it to one
# line and walking it with index(), which BWK awk and gawk both have.
#
# Round 2 (same day, blind again) adds P1a, P2a, P3a, P3b, the widened P4 and
# P5a, and closes the gaps a mutation review of round 1 found: a Program key,
# a duplicate capture key, a check on the wrong directory, a plist written and
# then removed, a suffix match on the capture path, an install that only
# unloads. The launchctl stub answers PA71_LOAD_RC to a load, 0 by default, so
# the load-failure message is driven too.
PA71B="$TMP/pa71-bin"; PA71D="$TMP/pa71-logs"; mkdir -p "$PA71B" "$PA71D"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "${LAUNCHCTL_LOG:-/dev/null}"\n[ "${1:-}" = load ] && exit "${PA71_LOAD_RC:-0}"\nexit 0\n' > "$PA71B/launchctl"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "${UNAME_STUB:-Darwin}"\n' > "$PA71B/uname"
chmod +x "$PA71B/launchctl" "$PA71B/uname"
PA71S="$TMP/pa71-served"; mkdir -p "$PA71S/engine/harness"
printf '#!/bin/sh\n' > "$PA71S/engine/harness/felix"; chmod +x "$PA71S/engine/harness/felix"
PA71S="$(cd "$PA71S" && pwd -P)"
_pa71_home() {   # DIR -> a fake HOME whose marketplace registry serves $PA71S
  mkdir -p "$1/.claude/plugins"
  printf '{\n  "felix": {\n    "installLocation": "%s"\n  }\n}\n' "$PA71S" > "$1/.claude/plugins/known_marketplaces.json"
}
_pa71_felix() {  # HOME UNAME LAUNCHCTL_LOG ARGS... -> output in PA71OUT, status in PA71RC
  local h="$1" u="$2" l="$3"; shift 3
  PA71OUT="$(cd "$REPO" && HOME="$h" PATH="$PA71B:$PATH" UNAME_STUB="$u" LAUNCHCTL_LOG="$l" \
             PA71_LOAD_RC="${_pa71lrc:-0}" "$FELIX" pulse "$@" 2>&1)"; PA71RC=$?
}
_pa71_each() {   # PLIST TAG -> the text of every <TAG>...</TAG>, one per line, in order
  _pa71_flat "$1" | LC_ALL=C awk -v o="<$2>" -v c="</$2>" '{
    s = $0
    while ((p = index(s, o)) > 0) {
      s = substr(s, p + length(o)); q = index(s, c); if (!q) exit
      print substr(s, 1, q - 1); s = substr(s, q + length(c))
    }
  }'
}
_pa71_unxml() { printf '%s' "$1" | sed -e 's/&lt;/</g' -e 's/&gt;/>/g' -e 's/&amp;/\&/g'; }
_pa71_loaded() { grep -q '^load .*felix\.pulse\.plist' "$1" 2>/dev/null; }   # a load, not an unload
_pa71_flat() { tr '\n\r\t' '   ' < "$1" 2>/dev/null; }
_pa71_args() {   # PLIST -> each ProgramArguments string, one per line
  _pa71_flat "$1" | LC_ALL=C awk '{
    i = index($0, "<key>ProgramArguments</key>"); if (!i) exit
    s = substr($0, i + 27); a = index(s, "<array>"); e = index(s, "</array>")
    if (!a || !e || e < a) exit
    s = substr(s, a + 7, e - a - 7)
    while ((p = index(s, "<string>")) > 0) {
      s = substr(s, p + 8); q = index(s, "</string>"); if (!q) exit
      print substr(s, 1, q - 1); s = substr(s, q + 9)
    }
  }'
}
_pa71_str() {    # PLIST KEY -> the <string> that is KEY's value
  _pa71_flat "$1" | LC_ALL=C awk -v k="<key>$2</key>" '{
    i = index($0, k); if (!i) exit
    s = substr($0, i + length(k)); sub(/^ */, "", s)
    if (substr(s, 1, 8) != "<string>") exit
    s = substr(s, 9); q = index(s, "</string>"); if (q) print substr(s, 1, q - 1)
  }'
}
_pa71_under() {  # PATH ROOT -> status 0 when PATH is ROOT or below it
  [ -n "$2" ] || return 1
  case "$1" in "$2"|"$2"/*) return 0 ;; esac; return 1
}

# ------------------------------------------------------------ install --------
PA71H="$TMP/pa71-home"; mkdir -p "$PA71H"; PA71H="$(cd "$PA71H" && pwd -P)"; _pa71_home "$PA71H"
PA71P="$PA71H/Library/LaunchAgents/felix.pulse.plist"; PA71C="$PA71H/Library/Logs/felix/pulse.launchd.log"
_pa71_felix "$PA71H" Darwin "$PA71D/launchctl.ok.log" --install
is "pulse agent P5: install on Darwin answers 0" "$PA71RC" "0"
[ -f "$PA71P" ] && ok "pulse agent P5: install writes ~/Library/LaunchAgents/felix.pulse.plist" \
  || bad "pulse agent P5: install writes ~/Library/LaunchAgents/felix.pulse.plist" "no $PA71P"
has "pulse agent P5: and launchd is handed that plist" "$(cat "$PA71D/launchctl.ok.log" 2>/dev/null)" "$PA71P"
_pa71_loaded "$PA71D/launchctl.ok.log" && ok "pulse agent P5a: launchd is handed the plist by a load, not by an unload alone" \
  || bad "pulse agent P5a: launchd is handed the plist by a load, not by an unload alone" \
         "launchctl got: $(tr '\n' '|' < "$PA71D/launchctl.ok.log" 2>/dev/null)"

# P1: /bin/bash, the served engine's felix, pulse, and nothing else.
_pa71a="$(_pa71_args "$PA71P")"
is "pulse agent P1: ProgramArguments holds exactly three strings" \
   "$(printf '%s\n' "$_pa71a" | LC_ALL=C awk 'NF' | wc -l | tr -d ' ')" "3"
is "pulse agent P1: the first is /bin/bash" "$(printf '%s\n' "$_pa71a" | sed -n 1p)" "/bin/bash"
is "pulse agent P1: the second is the served engine's felix, not the running copy" \
   "$(printf '%s\n' "$_pa71a" | sed -n 2p)" "$PA71S/engine/harness/felix"
is "pulse agent P1: the third is pulse" "$(printf '%s\n' "$_pa71a" | sed -n 3p)" "pulse"
is "pulse agent P1: the three in order are /bin/bash, the served felix, pulse" \
   "$(printf '%s\n' "$_pa71a" | tr '\n' '|')" "/bin/bash|$PA71S/engine/harness/felix|pulse|"
# Read off the whole plist, not ProgramArguments alone, so a Program key of
# /usr/bin/env beside a right ProgramArguments fails it (round-1 review, P1f).
case "$(_pa71_flat "$PA71P")" in */usr/bin/env*) bad "pulse agent P1: the program does not go through /usr/bin/env" "$(_pa71_flat "$PA71P")" ;;
  *) ok "pulse agent P1: the program does not go through /usr/bin/env" ;; esac

# P1a: no Program key, and the key set is exactly the seven, each once. A
# duplicate StandardOutPath (P2f) or any added key fails the exact set.
case "$(_pa71_flat "$PA71P")" in *"<key>Program</key>"*) bad "pulse agent P1a: the plist has no Program key" "$(_pa71_flat "$PA71P")" ;;
  *) ok "pulse agent P1a: the plist has no Program key" ;; esac
is "pulse agent P1a: its keys are exactly Label, ProgramArguments, StartCalendarInterval, Hour, Minute, StandardOutPath, StandardErrorPath, each once" \
   "$(_pa71_each "$PA71P" key | LC_ALL=C sort | tr '\n' ' ')" \
   "Hour Label Minute ProgramArguments StandardErrorPath StandardOutPath StartCalendarInterval "
for _pa71k in StandardOutPath StandardErrorPath ProgramArguments; do
  is "pulse agent P1a: $_pa71k appears once" "$(_pa71_each "$PA71P" key | LC_ALL=C awk -v k="$_pa71k" '$0 == k { n++ } END { print n + 0 }')" "1"
done

# P2: one capture file, under ~/Library/Logs/felix, outside the home and Documents.
_pa71o="$(_pa71_str "$PA71P" StandardOutPath)"; _pa71e="$(_pa71_str "$PA71P" StandardErrorPath)"
is "pulse agent P2: StandardOutPath is \$HOME/Library/Logs/felix/pulse.launchd.log" "$_pa71o" "$PA71C"
is "pulse agent P2: StandardErrorPath is \$HOME/Library/Logs/felix/pulse.launchd.log" "$_pa71e" "$PA71C"
if [ -n "$_pa71o" ] && [ "$_pa71o" = "$_pa71e" ]; then ok "pulse agent P2: stdout and stderr are captured to the same file"
else bad "pulse agent P2: stdout and stderr are captured to the same file" "out [$_pa71o] err [$_pa71e]"; fi
_pa71fr="$(cd "$FROOT" && pwd -P)"; _pa71in=""
for _pa71x in "$_pa71o" "$_pa71e"; do
  for _pa71r in "$FROOT" "$_pa71fr" "${FELIX_HOME:-}" "${FELIX_HOME_DIR:-}" "$REPO"; do
    _pa71_under "$_pa71x" "$_pa71r" && _pa71in="$_pa71in [$_pa71x under $_pa71r]"
  done
done
if [ -n "$_pa71o$_pa71e" ] && [ -z "$_pa71in" ]; then ok "pulse agent P2: neither capture path is inside the Felix home"
else bad "pulse agent P2: neither capture path is inside the Felix home" "out [$_pa71o] err [$_pa71e]$_pa71in"; fi
_pa71in=""
for _pa71x in "$_pa71o" "$_pa71e"; do
  _pa71_under "$_pa71x" "$PA71H/Documents" && _pa71in="$_pa71in [$_pa71x]"
done
if [ -n "$_pa71o$_pa71e" ] && [ -z "$_pa71in" ]; then ok "pulse agent P2: neither capture path is under \$HOME/Documents"
else bad "pulse agent P2: neither capture path is under \$HOME/Documents" "out [$_pa71o] err [$_pa71e]$_pa71in"; fi

# P3: launchd will not make the parent, so the installer does.
[ -d "$PA71H/Library/Logs/felix" ] && ok "pulse agent P3: a successful install leaves ~/Library/Logs/felix in place" \
  || bad "pulse agent P3: a successful install leaves ~/Library/Logs/felix in place" "no directory $PA71H/Library/Logs/felix"

# P4: the message names both logs.
has "pulse agent P4: the install message names the capture file" "$PA71OUT" "Library/Logs/felix/pulse.launchd.log"
has "pulse agent P4: and still names the pulse's own log, state/pulse.log" \
    "$(printf '%s\n' "$PA71OUT" | sed 's/pulse\.log\.launchd\.log//g')" "state/pulse.log"
# By its full path, not a suffix a wrong path could end in (round-1 review, P4c).
has "pulse agent P4: the install message names the capture file by its full path" "$PA71OUT" "$PA71C"
if [ -n "$_pa71o" ]; then has "pulse agent P4: and that path is the one the plist's StandardOutPath holds" "$PA71OUT" "$_pa71o"
else bad "pulse agent P4: and that path is the one the plist's StandardOutPath holds" "the plist holds no StandardOutPath string"; fi

# P5: label and schedule hold.
is "pulse agent P5: the label is still felix.pulse" "$(_pa71_str "$PA71P" Label)" "felix.pulse"
_pa71t="$( { tr -d ' \t\r\n' < "$PA71P"; } 2>/dev/null)"
has "pulse agent P5: the agent still runs on a StartCalendarInterval" "$_pa71t" "<key>StartCalendarInterval</key><dict>"
has "pulse agent P5: at hour 9" "$_pa71t" "<key>Hour</key><integer>9</integer>"
has "pulse agent P5: and minute 7" "$_pa71t" "<key>Minute</key><integer>7</integer>"

# P5: uninstall takes the plist back and leaves the capture file, since a log is
# not a grant. The file is made here if the install did not make its directory,
# so this holds or fails on uninstall alone.
mkdir -p "$PA71H/Library/Logs/felix" 2>/dev/null; printf 'a launchd line\n' >> "$PA71C"
_pa71_felix "$PA71H" Darwin "$PA71D/launchctl.un.log" --uninstall
is "pulse agent P5: uninstall answers 0" "$PA71RC" "0"
[ -e "$PA71P" ] && bad "pulse agent P5: uninstall removes the plist" "still present: $PA71P" \
  || ok "pulse agent P5: uninstall removes the plist"
has "pulse agent P5: uninstall leaves the capture file and what it holds" \
    "$(cat "$PA71C" 2>/dev/null)" "a launchd line"

# P5: the non-Darwin refusal stays.
PA71L="$TMP/pa71-home-linux"; mkdir -p "$PA71L"; PA71L="$(cd "$PA71L" && pwd -P)"; _pa71_home "$PA71L"
_pa71_felix "$PA71L" Linux "$PA71D/launchctl.linux.log" --install
is "pulse agent P5: a machine without launchd is still refused with 1" "$PA71RC" "1"
[ -e "$PA71L/Library/LaunchAgents/felix.pulse.plist" ] \
  && bad "pulse agent P5: and no plist is written on it" "plist appeared" \
  || ok  "pulse agent P5: and no plist is written on it"

# ------------------------------------------------- P3: no directory, no agent -
# ~/Library/Logs is a regular file here, so ~/Library/Logs/felix cannot be made.
PA71F="$TMP/pa71-home-blocked"; mkdir -p "$PA71F/Library"; PA71F="$(cd "$PA71F" && pwd -P)"; _pa71_home "$PA71F"
printf 'not a directory\n' > "$PA71F/Library/Logs"
_pa71_felix "$PA71F" Darwin "$PA71D/launchctl.blocked.log" --install
is "pulse agent P3: install exits 1 when ~/Library/Logs/felix cannot be created" "$PA71RC" "1"
has "pulse agent P3: and says which directory it could not create" "$PA71OUT" "Library/Logs/felix"
[ -e "$PA71F/Library/LaunchAgents/felix.pulse.plist" ] \
  && bad "pulse agent P3: and writes no plist" "plist written: $PA71F/Library/LaunchAgents/felix.pulse.plist" \
  || ok  "pulse agent P3: and writes no plist"
if [ -s "$PA71D/launchctl.blocked.log" ]; then
  bad "pulse agent P3: and hands launchctl nothing" "launchctl got: $(tr '\n' '|' < "$PA71D/launchctl.blocked.log")"
else ok "pulse agent P3: and hands launchctl nothing"; fi

# ------------------------------------------------- P2a: paths are XML-escaped -
# A home whose path holds &, < and > still yields a plist that parses: every
# string is escaped, and unescaping the capture gives back the path exactly.
PA71A="$TMP/pa71-amp/h a&b<c>d"; mkdir -p "$PA71A"; PA71A="$(cd "$PA71A" && pwd -P)"; _pa71_home "$PA71A"
# Served from an engine whose path holds them too, so the served felix in
# ProgramArguments is escaped as well, not only the capture (round-2 mutation
# check, R2-escape-capture-only). The served engine sits outside $HOME.
PA71SA="$TMP/pa71-amp-served/e a&b<c>d"; mkdir -p "$PA71SA/engine/harness"; PA71SA="$(cd "$PA71SA" && pwd -P)"
printf '#!/bin/sh\n' > "$PA71SA/engine/harness/felix"; chmod +x "$PA71SA/engine/harness/felix"
printf '{\n  "felix": {\n    "installLocation": "%s"\n  }\n}\n' "$PA71SA" > "$PA71A/.claude/plugins/known_marketplaces.json"
PA71AP="$PA71A/Library/LaunchAgents/felix.pulse.plist"; PA71AC="$PA71A/Library/Logs/felix/pulse.launchd.log"
_pa71_felix "$PA71A" Darwin "$PA71D/launchctl.amp.log" --install
is "pulse agent P2a: install answers 0 for a home whose path holds &, < and >" "$PA71RC" "0"
_pa71ao="$(_pa71_str "$PA71AP" StandardOutPath)"; _pa71ae="$(_pa71_str "$PA71AP" StandardErrorPath)"
has "pulse agent P2a: StandardOutPath carries & as &amp;" "$_pa71ao" "&amp;"
has "pulse agent P2a: StandardOutPath carries < as &lt;" "$_pa71ao" "&lt;"
has "pulse agent P2a: StandardOutPath carries > as &gt;" "$_pa71ao" "&gt;"
_pa71s="$(_pa71_each "$PA71AP" string)"
_pa71raw="$(printf '%s\n' "$_pa71s" | LC_ALL=C awk '{
  t = $0; gsub(/&(amp|lt|gt|quot|apos|#[0-9]+|#x[0-9A-Fa-f]+);/, "", t)
  if (index(t, "&") || index(t, "<")) print "[" $0 "]"
}')"
if [ -n "$_pa71s" ] && [ -z "$_pa71raw" ]; then ok "pulse agent P2a: no <string> in the plist holds a raw & or <"
else bad "pulse agent P2a: no <string> in the plist holds a raw & or <" "strings [$(printf '%s' "$_pa71s" | tr '\n' '|')] raw $_pa71raw"; fi
is "pulse agent P2a: unescaped, StandardOutPath is exactly \$HOME/Library/Logs/felix/pulse.launchd.log" \
   "$(_pa71_unxml "$_pa71ao")" "$PA71AC"
is "pulse agent P2a: unescaped, StandardErrorPath is exactly \$HOME/Library/Logs/felix/pulse.launchd.log" \
   "$(_pa71_unxml "$_pa71ae")" "$PA71AC"
is "pulse agent P2a: unescaped, the second ProgramArguments string is exactly the served felix" \
   "$(_pa71_unxml "$(_pa71_args "$PA71AP" | sed -n 2p)")" "$PA71SA/engine/harness/felix"
[ -d "$PA71A/Library/Logs/felix" ] && ok "pulse agent P2a: and ~/Library/Logs/felix is made under that home" \
  || bad "pulse agent P2a: and ~/Library/Logs/felix is made under that home" "no directory $PA71A/Library/Logs/felix"
has "pulse agent P4: under that home the message names the capture file by its full, unescaped path" "$PA71OUT" "$PA71AC"

# ------------------------------------- P3a: a directory that exists is not enough -
_pa71_refused() {   # SHAPE HOME LAUNCHCTL_LOG -> P3's four terms for one refused install
  local w="$1" h="$2" l="$3"
  is "pulse agent P3a: $w: install exits 1" "$PA71RC" "1"
  has "pulse agent P3a: $w: and says which directory it could not use" "$PA71OUT" "Library/Logs/felix"
  if [ -e "$h/Library/LaunchAgents/felix.pulse.plist" ]; then
    bad "pulse agent P3a: $w: and writes no plist" "plist written: $h/Library/LaunchAgents/felix.pulse.plist"
  else ok "pulse agent P3a: $w: and writes no plist"; fi
  if [ -s "$l" ]; then bad "pulse agent P3a: $w: and hands launchctl nothing" "launchctl got: $(tr '\n' '|' < "$l")"
  else ok "pulse agent P3a: $w: and hands launchctl nothing"; fi
}
# (i) ~/Library/Logs is a directory and ~/Library/Logs/felix a regular file, so a
# check on the parent, or -e for -d, cannot pass (round-1 review, P3i and P3j).
PA71F1="$TMP/pa71-home-felixfile"; mkdir -p "$PA71F1/Library/Logs"; PA71F1="$(cd "$PA71F1" && pwd -P)"; _pa71_home "$PA71F1"
printf 'not a directory\n' > "$PA71F1/Library/Logs/felix"
_pa71_felix "$PA71F1" Darwin "$PA71D/launchctl.felixfile.log" --install
_pa71_refused "~/Library/Logs/felix is a regular file" "$PA71F1" "$PA71D/launchctl.felixfile.log"
# (i, again) the same file made executable. A mode 644 file fails a -x test as
# well, so (i) alone cannot tell a -d check from a writability check that
# refuses for the wrong reason (round-2 mutation check, P3i and P3j).
PA71F4="$TMP/pa71-home-felixexec"; mkdir -p "$PA71F4/Library/Logs"; PA71F4="$(cd "$PA71F4" && pwd -P)"; _pa71_home "$PA71F4"
printf 'not a directory\n' > "$PA71F4/Library/Logs/felix"; chmod 755 "$PA71F4/Library/Logs/felix"
_pa71_felix "$PA71F4" Darwin "$PA71D/launchctl.felixexec.log" --install
_pa71_refused "~/Library/Logs/felix is an executable regular file" "$PA71F4" "$PA71D/launchctl.felixexec.log"
# (ii) the capture path itself is a directory, which launchd cannot open as a file.
PA71F2="$TMP/pa71-home-capdir"; mkdir -p "$PA71F2/Library/Logs/felix/pulse.launchd.log"; PA71F2="$(cd "$PA71F2" && pwd -P)"
_pa71_home "$PA71F2"
_pa71_felix "$PA71F2" Darwin "$PA71D/launchctl.capdir.log" --install
_pa71_refused "the capture path is a directory" "$PA71F2" "$PA71D/launchctl.capdir.log"
# (iii) ~/Library/Logs/felix exists and cannot be written. Root writes through
# mode 555, so there the fixture proves nothing and is skipped.
_pa71w="~/Library/Logs/felix is not writable"
if [ "$(id -u)" = "0" ]; then
  for _pa71n in "install exits 1" "and says which directory it could not use" "and writes no plist" "and hands launchctl nothing"; do
    skip "pulse agent P3a: $_pa71w: $_pa71n" "running as root, which writes through mode 555"
  done
else
  PA71F3="$TMP/pa71-home-readonly"; mkdir -p "$PA71F3/Library/Logs/felix"; PA71F3="$(cd "$PA71F3" && pwd -P)"; _pa71_home "$PA71F3"
  chmod 555 "$PA71F3/Library/Logs/felix"
  _pa71_felix "$PA71F3" Darwin "$PA71D/launchctl.readonly.log" --install
  chmod 755 "$PA71F3/Library/Logs/felix"
  _pa71_refused "$_pa71w" "$PA71F3" "$PA71D/launchctl.readonly.log"
fi

# ------------------------------------------- P3b: an agent already there stays -
# A refused re-install leaves the plist from before byte for byte, so writing it
# and then removing it fails (round-1 review, P3d). It says that agent was left
# as it was and may still be loaded, and never that nothing is scheduled.
_pa71i=0
for _pa71w in "~/Library/Logs is a regular file" "~/Library/Logs/felix is a regular file"; do
  _pa71i=$((_pa71i + 1)); _pa71h="$TMP/pa71-home-prior-$_pa71i"
  mkdir -p "$_pa71h/Library/LaunchAgents"; _pa71h="$(cd "$_pa71h" && pwd -P)"; _pa71_home "$_pa71h"
  case "$_pa71i" in
    1) printf 'not a directory\n' > "$_pa71h/Library/Logs" ;;
    *) mkdir -p "$_pa71h/Library/Logs"; printf 'not a directory\n' > "$_pa71h/Library/Logs/felix" ;;
  esac
  printf 'the prior agent\n' > "$_pa71h/Library/LaunchAgents/felix.pulse.plist"
  cp "$_pa71h/Library/LaunchAgents/felix.pulse.plist" "$TMP/pa71-prior-$_pa71i.copy"
  _pa71_felix "$_pa71h" Darwin "$PA71D/launchctl.prior-$_pa71i.log" --install
  is "pulse agent P3b: $_pa71w, with an agent already installed: install exits 1" "$PA71RC" "1"
  if cmp -s "$TMP/pa71-prior-$_pa71i.copy" "$_pa71h/Library/LaunchAgents/felix.pulse.plist"; then
    ok "pulse agent P3b: $_pa71w: the plist from before is left byte for byte"
  else bad "pulse agent P3b: $_pa71w: the plist from before is left byte for byte" \
           "now: [$(cat "$_pa71h/Library/LaunchAgents/felix.pulse.plist" 2>/dev/null || printf 'gone')]"; fi
  if [ -s "$PA71D/launchctl.prior-$_pa71i.log" ]; then
    bad "pulse agent P3b: $_pa71w: and launchctl is handed nothing" "launchctl got: $(tr '\n' '|' < "$PA71D/launchctl.prior-$_pa71i.log")"
  else ok "pulse agent P3b: $_pa71w: and launchctl is handed nothing"; fi
  has "pulse agent P3b: $_pa71w: the message says that agent was left as it was" "$PA71OUT" "left as it was"
  has "pulse agent P3b: $_pa71w: and that it may still be loaded" "$PA71OUT" "may still be loaded"
  # "nothing scheduled itself" is the grant line, a different claim, so the bare
  # phrase counts only where a clause ends.
  case "$PA71OUT" in
    *"nothing was scheduled"*|*"nothing is scheduled"*|*"nothing scheduled;"*|*"nothing scheduled,"*|*"nothing scheduled."*|*"nothing scheduled")
      bad "pulse agent P3b: $_pa71w: and it never says that nothing is scheduled" "$PA71OUT" ;;
    *) ok "pulse agent P3b: $_pa71w: and it never says that nothing is scheduled" ;;
  esac
done

# ---------------------------------------- P4: a load that fails still says where -
PA71G="$TMP/pa71-home-loadfail"; mkdir -p "$PA71G"; PA71G="$(cd "$PA71G" && pwd -P)"; _pa71_home "$PA71G"
_pa71lrc=1; _pa71_felix "$PA71G" Darwin "$PA71D/launchctl.loadfail.log" --install; _pa71lrc=0
[ -f "$PA71G/Library/LaunchAgents/felix.pulse.plist" ] && ok "pulse agent P4: with a launchctl load that fails, the plist is still written" \
  || bad "pulse agent P4: with a launchctl load that fails, the plist is still written" "no plist under $PA71G"
_pa71_loaded "$PA71D/launchctl.loadfail.log" && ok "pulse agent P4: and launchctl was asked to load it" \
  || bad "pulse agent P4: and launchctl was asked to load it" "launchctl got: $(tr '\n' '|' < "$PA71D/launchctl.loadfail.log" 2>/dev/null)"
has "pulse agent P4: the load-failure message names the capture file by its full path" \
    "$PA71OUT" "$PA71G/Library/Logs/felix/pulse.launchd.log"
has "pulse agent P4: the load-failure message names the pulse's own log, state/pulse.log" \
    "$(printf '%s\n' "$PA71OUT" | sed 's/pulse\.log\.launchd\.log//g')" "state/pulse.log"
