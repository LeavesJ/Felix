# >>> land-on-green-round-9
printf '\nland on green: the amendment A31, the read by the shell itself, the readable row, recovery by kind, installed jobs (contract A31, blind)\n'
# Blind, from the contract's "Amended after install, 2026-10-18" alone, on the
# fixture parts 1280-1288 build: lib/green-install.sh, lib/green-tick.sh,
# lib/resolve.sh and the felix CLI were not read. It follows 1288, which carries
# the rest of A31, and shares nothing with it but the fixture of 1280 and 1281.
#
# 1. The read is the shell's own. Logging wrappers for head, dd, cat, od, wc,
#    xxd, hexdump, perl, python3 and ruby sit first on the trampoline's PATH and
#    only there: each logs its argv and the inode on its standard input, then
#    runs the real tool. No call may name plugin.json or engine/.claude-plugin,
#    and none may have plugin.json open as its standard input, since a tool that
#    reads a file the shell opened is not the shell's own read either.
# 2. The readable row says "again" and none of cannot, failed, Full Disk Access.
# 3. Recovery keys on the newest row's kind, not on a word in its detail.
# 4. An installed job: --install rewrites a pre-A31 pair and boots the old job
#    out first; a --tick leaves an installed pair as it found it.
_lg_build amend
L9="$LG/round9"; L9CWD="$(pwd -P)"; mkdir -p "$L9/toolbin"; : > "$L9/tool.log"
L9PJ="$LGH/engine/.claude-plugin/plugin.json"; cp -p "$L9PJ" "$L9/plugin.json.keep"
L9TR="$LGU/Library/Application Support/felix/land/lgh/tick"; L9PL="$LGU/Library/LaunchAgents/felix.land.lgh.plist"
LGUID="${LGUID:-$(id -u)}"; L9TOOLS=""
for _l9t in head dd cat od wc xxd hexdump perl python3 ruby; do
  _l9r="$(type -P "$_l9t" 2>/dev/null)" || continue
  sed -e "s#@LOG@#$L9/tool.log#" -e "s#@NAME@#$_l9t#" -e "s#@REAL@#$_l9r#" > "$L9/toolbin/$_l9t" <<'L9WRAP'
#!/bin/bash
{ printf '%s' '@NAME@'; for a in "$@"; do printf '\t%s' "$a"; done
  printf '\tstdin-inode=%s\n' "$(stat -L -c %i /dev/fd/0 2>/dev/null || stat -f %i /dev/fd/0 2>/dev/null)"; } >> '@LOG@'
exec '@REAL@' "$@"
L9WRAP
  chmod +x "$L9/toolbin/$_l9t"; L9TOOLS="$L9TOOLS $_l9t"
done
_l9_last() { LC_ALL=C awk -F'\t' '{ print $NF }' "$L9/tool.log"; }   # the last field of each logged call: the inode on its standard input
_l9_ino() { stat -c %i "$1" 2>/dev/null || stat -f %i "$1" 2>/dev/null; }
_l9_mainv() { git -C "$LGH" show refs/remotes/origin/main:engine/.claude-plugin/plugin.json 2>/dev/null | sed -n 's/.*"version": *"\([^"]*\)".*/\1/p'; }
_l9_ticks() { _lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick"' | wc -l | tr -d ' '; }
_l9_restore() { chmod -R u+rwx "$L9PJ" 2>/dev/null; rm -rf "$L9PJ"; cp -p "$L9/plugin.json.keep" "$L9PJ"; }
_l9_tramp() {   # -> the trampoline as launchd runs it, the wrappers first on its PATH, ended after twenty seconds (124); status in L9RC
  : > "$L9/tool.log"
  ( cd "$TMP/cwd" 2>/dev/null || cd "$LG" || exit 97
    exec env -i HOME="$LGU" FELIX_HOME_DIR="$LGH" PATH="$L9/toolbin:$LGB:$PATH" \
      GIT_CEILING_DIRECTORIES="${GIT_CEILING_DIRECTORIES-}" "$L9TR" ) > "$LG/out.tramp" 2>&1 &
  local p=$! n=0
  while kill -0 "$p" 2>/dev/null && [ "$n" -lt 200 ]; do sleep 0.1; n=$((n+1)); done
  if kill -0 "$p" 2>/dev/null; then kill -KILL "$p" 2>/dev/null; wait "$p" 2>/dev/null; L9RC=124
  else wait "$p"; L9RC=$?; fi
}
_l9_no_call() {   # RUN -> no wrapped tool was given plugin.json, by name or on its standard input
  local ino; ino="$(_l9_ino "$L9PJ")"
  is "A31: $1: no logged call to head, dd, cat, od, wc, xxd, hexdump, perl, python3 or ruby names plugin.json or engine/.claude-plugin" \
     "$(LC_ALL=C awk '/plugin\.json|engine\/\.claude-plugin/ { n++ } END { print n + 0 }' "$L9/tool.log")" "0"
  if [ -n "$ino" ]; then
    is "A31: $1: and none has plugin.json open as its standard input, so the read is the shell's own" \
       "$(LC_ALL=C awk -F'\t' -v i="stdin-inode=$ino" '$NF == i { n++ } END { print n + 0 }' "$L9/tool.log")" "0"
  else skip "A31: $1: and none has plugin.json open as its standard input, so the read is the shell's own" "no stat that prints an inode"; fi
}
_l9_lacks() { case "$(_lg_lc "$2")" in *"$(_lg_lc "$3")"*) bad "$1" "[$2] holds [$3]" ;; *) ok "$1" ;; esac; }

# ------------------------------------------------------- the fixture, checked ---
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1
L9V="$(_l9_mainv)"; [ -n "$L9V" ] && _lg_cache "$L9V"
_lg_reset; _lg_land --uninstall; _lg_land --install
is "A31 (fixture control): the home is on main at origin's main, holds no change under engine/, and --install leaves an executable trampoline" \
   "$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" status --porcelain -- engine 2>&1 | tr '\n' '|')|$LGRC|$([ -x "$L9TR" ] && echo tramp)" "$(git -C "$LGO" rev-parse main 2>&1)||0|tramp"
is "A31 (fixture control): the wrappers are first on the trampoline's PATH: every tool resolves to its wrapper" \
   "$(env -i PATH="$L9/toolbin:$LGB:$PATH" /bin/bash -c 'for t in '"$L9TOOLS"'; do printf "%s " "$(command -v "$t")"; done')" \
   "$(for _l9t in $L9TOOLS; do printf '%s ' "$L9/toolbin/$_l9t"; done)"
: > "$L9/tool.log"; for _l9t in $L9TOOLS; do "$L9/toolbin/$_l9t" --version </dev/null >/dev/null 2>&1; done
is "A31 (fixture control): each wrapper logs its call once, the line starting with the tool's name" \
   "$(cut -f1 "$L9/tool.log" | tr '\n' ' ')" "${L9TOOLS# } "
: > "$L9/tool.log"
is "A31 (fixture control): a wrapper runs the real tool and logs its standard input: cat prints plugin.json and logs plugin.json's inode" \
   "$("$L9/toolbin/cat" < "$L9PJ" | cksum)|$(_l9_last)" "$(cksum < "$L9PJ")|stdin-inode=$(_l9_ino "$L9PJ")"
mv "$L9PJ" "$L9/plugin.json.moved"; mkdir "$L9PJ"; : > "$L9/tool.log"; "$L9/toolbin/cat" < "$L9PJ" >/dev/null 2>&1
is "A31 (fixture control): and with a directory in its place the log still holds the inode of what a tool was handed" "$(_l9_last)" "stdin-inode=$(_l9_ino "$L9PJ")"
_l9_restore

# ----------------------------------------------------- 1. a normal run, and refusals ---
_lg_reset; _l9_tramp; L9N=$L9RC
is "A31 (fixture control): with the wrappers first on PATH a normal run goes on as before: exit 0, and main's entry's felix land --tick runs once" \
   "$L9N|$(_l9_ticks)|$(_lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick" { print $1 }')" "0|1|$LGV/$L9V/harness/felix"
_l9_no_call "a normal run"

mv "$L9PJ" "$L9/plugin.json.moved"; mkdir "$L9PJ"
_lg_reset; _l9_tramp
is "A31 (fixture control): with plugin.json a directory the trampoline refuses: exit 1, one unreadable row, no felix" \
   "$L9RC|$(_lg_n unreadable)|$(_lg_rows)|$(_lg_cnt felix)" "1|1|1|0"
_l9_no_call "a refusal, with plugin.json a directory"
L9UD="$(_lg_f unreadable "" 7)"

# -------------------------------------------------------- 2. the readable row ---
_l9_restore; _l9_tramp
is "A31 (fixture control): the next run reads the home, goes on, and writes one readable row after the one unreadable row" \
   "$L9RC|$(_l9_ticks)|$(_lg_n readable)|$(_lg_n unreadable)|$(_lg_rows)" "$L9N|1|1|1|2"
_l9_no_call "the run that recovers"
L9RD="$(_lg_f readable "" 7)"
is "A31 (fixture control): the unreadable row's detail holds Full Disk Access, so the words the readable row must lack are ones its predecessor held" \
   "$(_lg_lc "$L9UD" | grep -c 'full disk access')" "1"
is "A31: the readable row has a detail" "$([ -n "$L9RD" ] && echo text)" "text"
has "A31: the readable row's detail says again" "$L9RD" "again"
_l9_lacks "A31: and holds no cannot" "$L9RD" "cannot"
_l9_lacks "A31: and holds no failed" "$L9RD" "failed"
_l9_lacks "A31: and holds no Full Disk Access" "$L9RD" "Full Disk Access"

# ----------------------------------------- the same refusal with a file of mode 000 ---
if [ "$(id -u)" != 0 ]; then
  chmod 000 "$L9PJ"; _lg_reset; _l9_tramp
  is "A31 (fixture control): with plugin.json a file of mode 000 the trampoline refuses: exit 1, one unreadable row, no felix" \
     "$L9RC|$(_lg_n unreadable)|$(_lg_rows)|$(_lg_cnt felix)" "1|1|1|0"
  _l9_no_call "a refusal, with plugin.json a file of mode 000"
  _l9_restore
else skip "A31: a refusal, with plugin.json a file of mode 000, hands plugin.json to no wrapped tool" "the suite runs as root, which opens any file"; fi

# --------------------------------------- 3. recovery keys on the newest row's kind ---
for L9K in deploy-owed paused deploy-failed deployed-unverified; do
  _lg_reset; mkdir -p "$LAND"
  { printf '2026-10-18T07:00:00Z\tunreadable\t-\t-\t-\t0\tan older unreadable row, %s\n' "$LGH"
    printf '2026-10-18T07:30:00Z\t%s\t-\t-\t-\t0\tthe home was unreadable to the deploy, which is still owed\n' "$L9K"; } > "$LAND/ledger.tsv"
  _l9_tramp
  is "A31: recovery: with the newest row of kind $L9K, its detail holding unreadable, and an older unreadable row below it, a run whose read succeeds writes no readable row, and goes on" \
     "$(_lg_n readable)|$(_lg_rows)|$(_lg_cnt osa)|$L9RC|$(_l9_ticks)" "0|2|0|$L9N|1"
done

# ------------------------------------------------------- 4. jobs already installed ---
_l9_old() {   # -> a pre-A31 install written by hand: a /bin/sh trampoline, and a plist whose ProgramArguments is that one path
  mkdir -p "$(dirname "$L9TR")" "$(dirname "$L9PL")"
  printf '#!/bin/sh\n# hand-written pre-A31 trampoline\ncd "$FELIX_HOME_DIR" || exit 1\nexit 0\n' > "$L9TR"; chmod +x "$L9TR"
  cat > "$L9PL" <<L9PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<!-- hand-written pre-A31 job -->
<dict>
  <key>Label</key><string>felix.land.lgh</string>
  <key>ProgramArguments</key>
  <array><string>$L9TR</string></array>
  <key>StartInterval</key><integer>300</integer>
  <key>RunAtLoad</key><true/>
  <key>ProcessType</key><string>Interactive</string>
  <key>EnvironmentVariables</key><dict><key>FELIX_HOME_DIR</key><string>$LGH</string></dict>
  <key>StandardOutPath</key><string>$LAND/launchd.log</string>
  <key>StandardErrorPath</key><string>$LAND/launchd.log</string>
</dict>
</plist>
L9PLIST
}
_l9_sum() { printf '%s|%s' "$(cksum < "$L9TR")" "$(cksum < "$L9PL")"; }
_lg_land --uninstall; _lg_reset; _l9_old; : > "$LGK/loaded"; L9S0="$(_l9_sum)"
is "A31 (fixture control): the hand-written install is the old one: a /bin/sh trampoline that is executable, and a plist whose ProgramArguments is the one trampoline path" \
   "$(head -n 1 "$L9TR")|$([ -x "$L9TR" ] && echo tramp)|$(tr -d ' \t\r\n' < "$L9PL" | grep -cF "<key>ProgramArguments</key><array><string>$(printf '%s' "$L9TR" | tr -d ' ')</string></array>")" "#!/bin/sh|tramp|1"
if command -v plutil >/dev/null 2>&1; then
  is "A31 (fixture control): plutil lints the hand-written plist and reads one ProgramArguments string" "$(plutil -lint -s "$L9PL" 2>&1)|$(plutil -extract ProgramArguments raw -o - "$L9PL" 2>&1)" "|1"
else skip "A31 (fixture control): plutil lints the hand-written plist and reads one ProgramArguments string" "no plutil on this machine"; fi
_lg_land --tick
is "A31: a --tick run leaves the pre-A31 trampoline and plist byte for byte as they were, and boots nothing in or out" \
   "$LGRC|$(_l9_sum)|$(_lg_logs launchctl | grep -cE '^(bootstrap|bootout|load|unload)')" "0|$L9S0|0"

_lg_reset; : > "$LGK/loaded"; _lg_land --install; L9IR=$LGRC
is "A31: --install over a loaded pre-A31 job exits 0, and the trampoline's first line becomes #!/bin/bash" "$L9IR|$(head -n 1 "$L9TR")|$([ -x "$L9TR" ] && echo tramp)" "0|#!/bin/bash|tramp"
_l9p="$( { tr -d ' \t\r\n' < "$L9PL"; } 2>/dev/null)"
has "A31: and the plist's ProgramArguments become /bin/bash, then the trampoline's path, and nothing else" "$_l9p" \
    "<key>ProgramArguments</key><array><string>/bin/bash</string><string>$(printf '%s' "$L9TR" | tr -d ' ')</string></array>"
if plutil -extract Label raw -o - "$L9PL" >/dev/null 2>&1; then
  is "A31: plutil reads the rewritten ProgramArguments as two strings: /bin/bash, then the trampoline's path with its space" \
     "$(plutil -extract ProgramArguments raw -o - "$L9PL" 2>&1)|$(plutil -extract ProgramArguments.0 raw -o - "$L9PL" 2>&1)|$(plutil -extract ProgramArguments.1 raw -o - "$L9PL" 2>&1)" "2|/bin/bash|$L9TR"
else skip "A31: plutil reads the rewritten ProgramArguments as two strings: /bin/bash, then the trampoline's path with its space" "no plutil that extracts raw values on this machine"; fi
is "A31: --install rewrites both files: the hand-written marker is in neither" "$(grep -c 'hand-written pre-A31' "$L9TR")|$(grep -c 'hand-written pre-A31' "$L9PL")" "0|0"
is "A31: the launchctl log shows a bootout of the job before the bootstrap of the plist" \
   "$(LC_ALL=C awk -v t="bootstrap gui/$LGUID $L9PL" '$1 == "bootout" && index($0, "felix.land.lgh") && !o { o = NR } $0 == t && !s { s = NR } END { if (o && s && o < s) print "bootout, then bootstrap"; else printf "bootout line %d, bootstrap line %d", o, s }' "$LGL/launchctl.log" 2>/dev/null)" "bootout, then bootstrap"
is "A31: and boots the plist in once: one bootstrap" "$(_lg_logs launchctl | grep -c '^bootstrap')" "1"
L9S1="$(_l9_sum)"; _lg_reset; : > "$LGK/loaded"; _lg_land --tick
is "A31: a --tick run leaves the rewritten trampoline and plist byte for byte as they were, and boots nothing in or out" \
   "$LGRC|$(_l9_sum)|$(_lg_logs launchctl | grep -cE '^(bootstrap|bootout|load|unload)')" "0|$L9S1|0"

# ---------------------------------------------------------------------- clean ---
_l9_restore; _lg_reset; _lg_land --uninstall; _lg_reset; rm -rf "$L9"
is "A31 (fixture control): the home's plugin.json is the file it was, the job is uninstalled, and the part leaves the working directory where it found it" \
   "$([ -f "$L9PJ" ] && [ ! -S "$L9PJ" ] && echo file)|$(git -C "$LGH" status --porcelain -- engine 2>&1 | tr '\n' '|')|$([ -e "$L9PL" ] || [ -e "$L9TR" ] || echo gone)|$(pwd -P)" "file||gone|$L9CWD"
