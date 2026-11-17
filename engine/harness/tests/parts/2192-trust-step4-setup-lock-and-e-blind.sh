# >>> trust-step4-setup-lock-and-e
printf '\ntrust plane step 4, the authority setup slice: the lock program, and what condition e reads (spec L1, L3, L4, L6, C1 to C4; blind)\n'
# Blind, written on 2026-11-16 from .felix/memory/felix/audits/2026-11-16-trust-step4-authority-setup/spec.md (rev 1)
# alone (sections 0, 3, 4 and 6, with slice 1's section 2 for condition e), before bin/lock-macos and the new readings
# of condition e existed, by an author who has read no engine code. The helpers are tests/lib/trust-step4.sh and
# tests/lib/trust-step4-setup.sh. Everything is under $TMP/ts4-lock-e.
#
# bin/lock-macos is run with --status, with arguments L6 makes a usage error, and off macOS with --status and such an
# argument. It is never run with no argument: that locks the screen of whoever is at this machine.
#
# Condition e is read through felix authority status of a store whose one worker is another login of this machine
# that runs no process (slice 1's parts pick it the same way), run from a copy of this suite's engine made under the
# fixture, so that a file of the engine can be made writable without touching the suite's own. Each staging is shown
# as a why line, and is gone once it is undone. Where no such login is found, or status gives that store a why line of
# a, b or e before anything is staged, each assertion on it is skipped under its own name, as in part 2186.
#
# Readings, where the spec leaves room:
# - L4's one line is on standard output, and nothing is printed on standard error.
# - L3 is read here as the spec gives it, from ioreg and plutil, before and after --status: where the two readings
#   agree, --status must print the same; where the console changed between them, that assertion is skipped.
# - C1's engine root holds bin/ (section 4 says the lock program is under it as bin/lock-macos), so a file under
#   harness/bin is under it whichever directory FELIX_ROOT names. Made writable by every login, the root itself may be
#   printed as itself or as a directory above the code, and only FIRST's path is matched.
# - C2's git "first on PATH" is the first file named git in PATH's directories; the stub answers --exec-path as its
#   first argument.
# - C3's physical path: a PATH entry that is a link to a directory whose parent every login can write. The link is named
#   so that it sorts after that parent, and only FIRST is matched there.
# - C4's sort is by bytes.
#
# Not covered: L2 and L5 (no test may lock); L3's reading of a session switched out, or of a list that cannot be read
# (the console of the machine the suite runs on is what it is); C3's directories a worker owns and a group a worker is in
# (nothing here changes an owner or a group); the reach test.
_ts4u_begin ts4-lock-e
TS4L_X="$TS4/x"

# ------------------------------------------------------------------ the lock (L1, L3, L4, L6) ---
TS4L_N1="ts4 setup L4: on macOS, --status prints exactly one line, locked, not locked or unknown, with exit 0, 1 or 3 to match, prints nothing on stderr, and writes nothing"
TS4L_N2="ts4 setup L3: on macOS, --status reads this login's console sessions as L3 says, the same as this test reads them"
TS4L_N3="ts4 setup L6: on macOS, an argument other than --status is a usage error: exit 2 and usage: lock-macos [--status]"
TS4L_N4="ts4 setup L6: on macOS, --status with a second argument is a usage error"
TS4L_N5="ts4 setup L1: off macOS, lock-macos --status exits 2 with lock-macos: not macOS"
TS4L_N6="ts4 setup L1: off macOS, lock-macos with any other argument exits 2 with lock-macos: not macOS"
if [ "$TS4U_OS" = Darwin ]; then
  TS4L_B="$(_ts4u_console)"
  is "ts4 setup L3 (control): on macOS this test reads this login's console sessions as one of locked, not locked and unknown" \
    "$(case "$TS4L_B" in (locked|"not locked"|unknown) printf read ;; (*) printf 'read as [%s]' "$TS4L_B" ;; esac)" read
  TS4L_S="$(_ts4_snap "$TS4/t")"; _ts4u_run "$TS4/t" bash "$TS4U_LK" --status; TS4L_A="$(_ts4u_console)"
  case "$(_ts4u_out):$TS4_RC" in ("locked:0"|"not locked:1"|"unknown:3") TS4L_V="one of the three, with its status" ;; (*) TS4L_V="[$(_ts4u_out)] with exit $TS4_RC" ;; esac
  _ts4_is "$TS4L_N1" "lines: $(_ts4_rows "$TS4/o"); $TS4L_V; stderr lines: $(_ts4_rows "$TS4/e"); $(if [ "$(_ts4_snap "$TS4/t")" = "$TS4L_S" ]; then printf 'nothing written'; else printf 'something written'; fi)" \
    "lines: 1; one of the three, with its status; stderr lines: 0; nothing written" "$(_ts4_why)"
  if [ "$TS4L_A" = "$TS4L_B" ]; then _ts4_is "$TS4L_N2" "$(_ts4u_out)" "$TS4L_B" "$(_ts4_why)"
  else skip "$TS4L_N2" "this login's console sessions read $TS4L_B before the call and $TS4L_A after it"; fi
  _ts4u_run "$TS4/t" bash "$TS4U_LK" --bogus
  _ts4_is "$TS4L_N3" "$(_ts4u_ref)" "exit 2; stderr: usage: lock-macos [--status]" "$(_ts4_why)"
  _ts4u_run "$TS4/t" bash "$TS4U_LK" --status extra
  _ts4_is "$TS4L_N4" "$(_ts4u_ref); stdout lines: $(_ts4_rows "$TS4/o")" "exit 2; stderr: usage: lock-macos [--status]; stdout lines: 0" "$(_ts4_why)"
  skip "$TS4L_N5" "this is macOS"; skip "$TS4L_N6" "this is macOS"
else
  skip "ts4 setup L3 (control): on macOS this test reads this login's console sessions as one of locked, not locked and unknown" "this is not macOS"
  skip "$TS4L_N1" "this is not macOS"; skip "$TS4L_N2" "this is not macOS"; skip "$TS4L_N3" "this is not macOS"; skip "$TS4L_N4" "this is not macOS"
  _ts4u_run "$TS4/t" bash "$TS4U_LK" --status
  _ts4_is "$TS4L_N5" "$(_ts4u_ref)" "exit 2; stderr: lock-macos: not macOS" "$(_ts4_why)"
  _ts4u_run "$TS4/t" bash "$TS4U_LK" --bogus
  _ts4_is "$TS4L_N6" "$(_ts4u_ref)" "exit 2; stderr: lock-macos: not macOS" "$(_ts4_why)"
fi

# ------------------------------------------------------------------ condition e: the fixture ---
TS4L_E="$TS4/eng"; mkdir -p "$TS4L_E"; cp -R "$FROOT/harness" "$TS4L_E/harness" 2>/dev/null; chmod -R go-w "$TS4L_E" 2>/dev/null
TS4L_F0="$FELIX"; FELIX="$TS4L_E/harness/felix"; TS4L_Q="$TS4/q"
_ts4_src "$TS4/src.git"; _ts4_base "$TS4/src.git"
TS4L_BF="$(find "$TS4L_E/harness/bin" -type f -print 2>/dev/null | LC_ALL=C sort | LC_ALL=C awk 'NR == 1')"
TS4L_DF="$(find "$TS4L_E/harness/tests/lib" -type f -print 2>/dev/null | LC_ALL=C sort | LC_ALL=C awk 'NR == 1')"
TS4L_G="$(_ts4_which git)"; mkdir -p "$TS4/gbin" "$TS4/gnil" "$TS4/gbad" "$TS4/xp" "$TS4/pp/bin" "$TS4/phys/pp2/bin"; chmod 755 "$TS4/gbin" "$TS4/gnil" "$TS4/gbad" "$TS4/xp" "$TS4/pp" "$TS4/pp/bin" "$TS4/phys" "$TS4/phys/pp2" "$TS4/phys/pp2/bin"
printf '#!/bin/sh\ncase "$1" in --exec-path) printf "%%s\\n" "%s"; exit 0 ;; esac\nexec "%s" "$@"\n' "$TS4/xp" "$TS4L_G" > "$TS4/gbin/git"
printf '#!/bin/sh\ncase "$1" in --exec-path) exit 0 ;; esac\nexec "%s" "$@"\n' "$TS4L_G" > "$TS4/gnil/git"
printf '#!/bin/sh\ncase "$1" in --exec-path) echo "no exec path here" >&2; exit 1 ;; esac\nexec "%s" "$@"\n' "$TS4L_G" > "$TS4/gbad/git"
chmod 755 "$TS4/gbin/git" "$TS4/gnil/git" "$TS4/gbad/git"; printf '#!/bin/sh\nexit 0\n' > "$TS4/xp/git-ts4"; chmod 755 "$TS4/xp/git-ts4"
ln -s "$TS4/phys/pp2/bin" "$TS4/zl" 2>/dev/null

# ------------------------------------------------------------------ helpers ---
_ts4l_st() { _ts4_a "$TS4L_Q" status; }   # status for q, as the copied engine prints it
_ts4l_now() { _ts4l_st; printf '%s' "$(_ts4u_ewhy)"; }   # -> the e why lines status for q prints now, or none
_ts4l_after() { _ts4l_st; printf '%s' "$(_ts4_whys)"; }   # -> the letters of status's why lines for q, once a staging is undone

# ------------------------------------------------------------------ controls ---
is "ts4 setup C (control): the copied engine holds a file under bin/ and one under tests/lib/, and no file or directory in it can be written by group or other" \
  "$( [ -f "$TS4L_BF" ] && [ -f "$TS4L_DF" ] && printf found); $(find "$TS4L_E" -perm -020 -print -o -perm -002 -print 2>/dev/null | LC_ALL=C awk 'END { print NR }') writable" "found; 0 writable"
is "ts4 setup C2 (control): the stub git answers --exec-path with the fixture's directory and runs every other call through the real git; the other two print nothing and fail" \
  "$("$TS4/gbin/git" --exec-path 2>/dev/null); $(_ts4_yn "$TS4/gbin/git" --version); [$("$TS4/gnil/git" --exec-path 2>/dev/null)] $(_ts4_yn "$TS4/gnil/git" --exec-path) $(_ts4_yn "$TS4/gbad/git" --exec-path)" \
  "$TS4/xp; yes; [] yes no"
is "ts4 setup C3 (control): zl is a link to phys/pp2/bin, a directory, and its physical path holds phys/pp2" \
  "$(_ts4_yn test -L "$TS4/zl"); $( (cd -P "$TS4/zl" && pwd -P) 2>/dev/null)" "yes; $TS4/phys/pp2/bin"
_ts4_logins
if [ "$TS4_PS" = yes ] && [ -n "$TS4_IDLE" ]; then
  ok "ts4 setup C (control): ps lists this machine's processes, and it has a login other than this one that runs none"
else
  TS4_SKIP="no login other than this one that runs no process was found here (ps lists: $TS4_PS)"
  skip "ts4 setup C (control): ps lists this machine's processes, and it has a login other than this one that runs none" "$TS4_SKIP"
fi
_ts4_init "$TS4L_Q" "${TS4_IDLE:-none}" "$TS4/src.git"; _ts4_canstand "$TS4L_Q" "${TS4_IDLE:-none}"; _ts4l_st
_ts4_is "ts4 setup C (control): from the copied engine, with that login as the one worker, the standing is shadow with the why lines of c and d alone" "$(_ts4_sv standing) $(_ts4_whys)" "shadow cd" "$(_ts4_why)"

# ------------------------------------------------------------------ the whole engine (C1, C4) ---
chmod o+w "$TS4L_BF" 2>/dev/null; TS4L_V="$(_ts4l_now)"; chmod o-w "$TS4L_BF" 2>/dev/null
_ts4_is "ts4 setup C1, C4: a file under the engine's bin/ that every login can write is code the process runs: the why says so, and is gone once the mode is taken back" \
  "$TS4L_V, then $(_ts4l_after)" "$(_ts4u_eline "$TS4L_BF" 1), then cd" "$(_ts4_why)"
chmod o+w "$TS4L_DF" 2>/dev/null; TS4L_V="$(_ts4l_now)"; chmod o-w "$TS4L_DF" 2>/dev/null
_ts4_is "ts4 setup C1: so is a file at any depth of the engine, one under tests/lib/" "$TS4L_V, then $(_ts4l_after)" "$(_ts4u_eline "$TS4L_DF" 1), then cd" "$(_ts4_why)"
chmod o+w "$TS4L_E/harness" 2>/dev/null; TS4L_V="$(_ts4l_now)"; chmod o-w "$TS4L_E/harness" 2>/dev/null
_ts4_is "ts4 setup C1: the engine's root itself is read: made writable by every login, it is the first offender" \
  "$(R="$TS4L_E/harness" LC_ALL=C awk -v w="$TS4L_V" 'BEGIN { a = "not the authority\047s alone: it runs " ENVIRON["R"]; print ((index(w, a ", which ") == 1 || index(w, a " (a directory above the code), which ") == 1) ? "the root first" : "[" w "]") }'), then $(_ts4l_after)" \
  "the root first, then cd" "$(_ts4_why)"
# Review F2: the staging above makes harness/ writable, a directory under the root; FELIX_ROOT is the one above it.
chmod o+w "$TS4L_E" 2>/dev/null; TS4L_V="$(_ts4l_now)"; chmod o-w "$TS4L_E" 2>/dev/null
_ts4_is "ts4 setup C1 (review): the engine's root, the directory above the one felix is in, is read itself: made writable by every login, it is the one offender, and is gone once the mode is taken back" \
  "$TS4L_V, then $(_ts4l_after)" "$(_ts4u_eline "$TS4L_E" 1), then cd" "$(_ts4_why)"
# Review F3: a directory above the engine's root, which the system's PATH does not share. The copy is moved under
# $TS4/up for this, and back.
mkdir -p "$TS4/up"; chmod 755 "$TS4/up"; mv "$TS4L_E" "$TS4/up/eng" 2>/dev/null; FELIX="$TS4/up/eng/harness/felix"
chmod 777 "$TS4/up"; TS4L_V="$(_ts4l_now)"; chmod 1777 "$TS4/up"; TS4L_W="$(_ts4l_after)"; chmod 755 "$TS4/up"
mv "$TS4/up/eng" "$TS4L_E" 2>/dev/null; FELIX="$TS4L_E/harness/felix"
_ts4_is "ts4 setup C3 (review): a directory above the engine's root that every login can write, without the sticky bit, offends as a directory above the code, and with the sticky bit does not" \
  "$TS4L_V, then with the sticky bit: $TS4L_W; moved back: $(_ts4_yn test -f "$TS4L_E/harness/felix")" \
  "$(_ts4u_eline "$TS4/up (a directory above the code)" 1), then with the sticky bit: cd; moved back: yes" "$(_ts4_why)"

# ------------------------------------------------------------------ the git that runs (C2) ---
chmod 777 "$TS4/xp"; TS4_ENV=(PATH="$TS4/gbin:$TS4_PATH"); TS4L_V="$(_ts4l_now)"; chmod 755 "$TS4/xp"; TS4L_W="$(_ts4l_after)"; TS4_ENV=()
_ts4_is "ts4 setup C2: the directory git --exec-path prints, for the git first on PATH, is read as a PATH directory: writable by every login, it is named" \
  "$TS4L_V, then $TS4L_W" "$(_ts4u_eline "$TS4/xp" 1), then cd" "$(_ts4_why)"
chmod 757 "$TS4/xp/git-ts4"; TS4_ENV=(PATH="$TS4/gbin:$TS4_PATH"); TS4L_V="$(_ts4l_now)"; chmod 755 "$TS4/xp/git-ts4"; TS4L_W="$(_ts4l_after)"; TS4_ENV=()
_ts4_is "ts4 setup C2: and so is each program directly in it" "$TS4L_V, then $TS4L_W" "$(_ts4u_eline "$TS4/xp/git-ts4" 1), then cd" "$(_ts4_why)"
TS4_ENV=(PATH="$TS4/gnil:$TS4_PATH"); _ts4l_st; TS4L_V="exit $TS4_RC; $(_ts4_whys)"; TS4_ENV=(PATH="$TS4/gbad:$TS4_PATH"); _ts4l_st; TS4_ENV=()
_ts4_is "ts4 setup C2: where git --exec-path prints nothing, or fails, this adds nothing: status exits 0 with the why lines of c and d alone" \
  "$TS4L_V; fails: exit $TS4_RC; $(_ts4_whys)" "exit 0; cd; fails: exit 0; cd" "$(_ts4_why)"

# ------------------------------------------------------------------ the directories above (C3) ---
chmod 777 "$TS4/pp"; TS4_ENV=(PATH="$TS4/pp/bin:$TS4_PATH"); TS4L_V="$(_ts4l_now)"; chmod 1777 "$TS4/pp"; TS4L_W="$(_ts4l_after)"; chmod 755 "$TS4/pp"; TS4_ENV=()
_ts4_is "ts4 setup C3: a PATH directory whose parent every login can write, without the sticky bit, offends as a directory above the code, and with the sticky bit does not" \
  "$TS4L_V, then with the sticky bit: $TS4L_W" "$(_ts4u_eline "$TS4/pp (a directory above the code)" 1), then with the sticky bit: cd" "$(_ts4_why)"
chmod 777 "$TS4/phys/pp2"; TS4_ENV=(PATH="$TS4/zl:$TS4_PATH"); TS4L_V="$(_ts4l_now)"; chmod 755 "$TS4/phys/pp2"; TS4L_W="$(_ts4l_after)"; TS4_ENV=()
_ts4_is "ts4 setup C3: the directories above are read along the physical path too: a PATH entry that is a link into a directory every login can write names that directory first" \
  "$(F="$(_ts4u_eline "$TS4/phys/pp2 (a directory above the code)" 0)" LC_ALL=C awk -v w="$TS4L_V" 'BEGIN { f = ENVIRON["F"]; sub(/\(0 such\)$/, "", f); print (index(w, f) == 1 ? "named first" : "[" w "]") }'), then $TS4L_W" \
  "named first, then cd" "$(_ts4_why)"
# Review C3-missing-path: a PATH entry that is not there yet. A worker that can write the deepest directory above it
# that is there can make it and put a git in it, and the sticky bit does not stop that: no one owns the name yet.
mkdir -p "$TS4/ww"; chmod 777 "$TS4/ww"; TS4_ENV=(PATH="$TS4/ww/bin:$TS4_PATH"); TS4L_V="$(_ts4l_now)"; chmod 1777 "$TS4/ww"
TS4L_W="$(_ts4l_now)"; chmod 755 "$TS4/ww"; TS4L_U="$(_ts4l_after)"; TS4_ENV=()
_ts4_is "ts4 setup C3 (review): a PATH entry that is not there, under a directory every login can write, offends as that directory above the code, with the sticky bit and without it, and under one only its owner writes does not" \
  "$TS4L_V; with the sticky bit: $TS4L_W; then $TS4L_U; made: $(_ts4_yn test -e "$TS4/ww/bin")" \
  "$(_ts4u_eline "$TS4/ww (a directory above the code)" 1); with the sticky bit: $(_ts4u_eline "$TS4/ww (a directory above the code)" 1); then cd; made: no" "$(_ts4_why)"
# Security review of b29d8468, C3 rev 3: an entry that is there and is not a directory is read as one not there. A
# link to a file, or a link to nothing, leads wherever its target is later made a directory, so the link offends
# itself; wk/ stands for a place a worker can write. A plain file is read for the directory it sits in.
mkdir -p "$TS4/sv/wk" "$TS4/sv/rt"; chmod 755 "$TS4/sv" "$TS4/sv/rt"; chmod 777 "$TS4/sv/wk"; : > "$TS4/sv/wk/f"; chmod 644 "$TS4/sv/wk/f"
ln -s "$TS4/sv/wk/f" "$TS4/sv/rt/lf" 2>/dev/null; ln -s "$TS4/sv/wk/later" "$TS4/sv/rt/dl" 2>/dev/null
TS4_ENV=(PATH="$TS4/sv/rt/lf:$TS4_PATH"); TS4L_V="$(_ts4l_now)"; TS4_ENV=(PATH="$TS4/sv/rt/dl/bin:$TS4_PATH"); TS4L_W="$(_ts4l_now)"; TS4_ENV=()
_ts4_is "ts4 setup C3 (security review): a PATH entry that is a link to a file, and one under a link to nothing, each name that link as one that leads to no directory" \
  "$TS4L_V; $TS4L_W" "$(_ts4u_eline "$TS4/sv/rt/lf (a link on the way to the code that leads to no directory)" 1); $(_ts4u_eline "$TS4/sv/rt/dl (a link on the way to the code that leads to no directory)" 1)" "$(_ts4_why)"
TS4_ENV=(PATH="$TS4/sv/wk/f:$TS4_PATH"); TS4L_V="$(_ts4l_now)"; chmod 755 "$TS4/sv/wk"; TS4L_W="$(_ts4l_after)"; TS4_ENV=()
_ts4_is "ts4 setup C3 (security review): a PATH entry that is a plain file, in a directory every login can write, names that directory above the code, and in one only its owner writes does not" \
  "$TS4L_V, then $TS4L_W" "$(_ts4u_eline "$TS4/sv/wk (a directory above the code)" 1), then cd" "$(_ts4_why)"
# A lock that is a link runs whatever is at its end: a file in wk/, whose directory is not read, or one made later
# where a link to nothing points. Each is named, and a lock that is a file only its owner writes is not.
cp "$TS4L_Q/authority.conf" "$TS4/x/conf.keep" 2>/dev/null; ln -s "$TS4/sv/wk/later-lock" "$TS4/sv/rt/lk" 2>/dev/null
printf '#!/bin/sh\nexit 0\n' > "$TS4/sv/wk/lockprog"; chmod 755 "$TS4/sv/wk/lockprog"; ln -s "$TS4/sv/wk/lockprog" "$TS4/sv/rt/lk2" 2>/dev/null
_ts4_conf "$TS4L_Q" lock "$TS4/sv/rt/lk"; TS4L_V="$(_ts4l_now)"; _ts4_conf "$TS4L_Q" lock "$TS4/sv/rt/lk2"; chmod 777 "$TS4/sv/wk"; TS4L_U="$(_ts4l_now)"; chmod 755 "$TS4/sv/wk"
rm -f "$TS4/sv/rt/lk"; printf '#!/bin/sh\nexit 0\n' > "$TS4/sv/rt/lk"; chmod 755 "$TS4/sv/rt/lk"; _ts4_conf "$TS4L_Q" lock "$TS4/sv/rt/lk"
TS4L_W="$(_ts4l_after)"; cat "$TS4/x/conf.keep" > "$TS4L_Q/authority.conf" 2>/dev/null; rm -f "$TS4/x/conf.keep"
_ts4_is "ts4 setup C3 (security review): a lock that is a link is named as one, to nothing or to a file in a directory every login can write, and a lock that is a file only its owner writes is not" \
  "$TS4L_V; to a file: $TS4L_U, then $TS4L_W" "$(_ts4u_eline "$TS4/sv/rt/lk (a lock that is a link: it runs wherever the link points)" 1); to a file: $(_ts4u_eline "$TS4/sv/rt/lk2 (a lock that is a link: it runs wherever the link points)" 1), then cd" "$(_ts4_why)"
TS4L_N="ts4 setup C3: on macOS, a directory above the code that carries an access-control entry that allows offends, and one whose only entry denies does not"
if [ "$TS4U_OS" != Darwin ]; then skip "$TS4L_N" "this is not macOS"
elif [ -z "$TS4_SKIP" ] && ! chmod +a "everyone allow add_file,add_subdirectory" "$TS4/pp" 2>/dev/null; then skip "$TS4L_N" "chmod +a put no access-control entry on a directory here"
else
  TS4_ENV=(PATH="$TS4/pp/bin:$TS4_PATH"); TS4L_V="$(_ts4l_now)"; chmod -N "$TS4/pp" 2>/dev/null
  chmod +a "everyone deny delete" "$TS4/pp" 2>/dev/null; TS4L_W="$(_ts4l_after)"; chmod -N "$TS4/pp" 2>/dev/null; TS4_ENV=()
  _ts4_is "$TS4L_N" "allows: $TS4L_V; denies: $TS4L_W" "allows: $(_ts4u_eline "$TS4/pp (a directory above the code)" 1); denies: cd" "$(_ts4_why)"
fi

# ------------------------------------------------------------------ the count (C4) ---
chmod o+w "$TS4L_BF" 2>/dev/null; chmod 777 "$TS4/pp"; TS4_ENV=(PATH="$TS4/pp/bin:$TS4_PATH"); TS4L_V="$(_ts4l_now)"
chmod o-w "$TS4L_BF" 2>/dev/null; chmod 755 "$TS4/pp"; TS4L_W="$(_ts4l_after)"; TS4_ENV=()
_ts4_is "ts4 setup C4: with two offenders, the why names the first as sorted and counts both" "$TS4L_V, then $TS4L_W" "$(_ts4u_eline "$TS4L_BF" 2), then cd" "$(_ts4_why)"
FELIX="$TS4L_F0"; TS4_SKIP=""

_ts4u_end
unset TS4L_U TS4L_X TS4L_N1 TS4L_N2 TS4L_N3 TS4L_N4 TS4L_N5 TS4L_N6 TS4L_N TS4L_B TS4L_A TS4L_S TS4L_V TS4L_W TS4L_E TS4L_F0 TS4L_Q TS4L_BF TS4L_DF TS4L_G
# <<< trust-step4-setup-lock-and-e
