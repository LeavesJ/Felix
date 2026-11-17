# >>> trust-step4-setup-engine-copy
printf '\ntrust plane step 4, the authority setup slice: the engine copy, bin/authority-engine, and how it reaches that login (spec E2, E4 to E13, section 2; blind)\n'
# Blind, written on 2026-11-16 from .felix/memory/felix/audits/2026-11-16-trust-step4-authority-setup/spec.md (rev 1)
# alone (sections 0, 2 and 6), before bin/authority-engine existed, by an author who has read no engine code. The
# helpers are tests/lib/trust-step4.sh and tests/lib/trust-step4-setup.sh. Everything is under $TMP/ts4-engine; each
# HOME given to authority-engine is a directory there. The program is run with /bin/bash, as the test's own login.
#
# The fixture: a bare source whose commits are built with plumbing, all bundled into src.bundle. K1 (main) holds a
# small engine (felix, bin/reach-witness, bin/lock-macos, lib/x.sh, lib/id.txt holding $Id$, engine/.gitattributes
# asking for ident and CRLF, engine/.claude-plugin/plugin.json at 9.8.7) and two files outside engine/; its felix prints
# what it was run with. K2 is another small engine with no plugin.json. K3 and K4 have K1's tree and subjects of their
# own. KN holds no felix, KM a felix of mode 100644, KL two links under engine/ (a-lnk first), KS a submodule under
# engine/, KA a path with a byte outside printable ASCII, KC lib/x.sh beside lib/X.SH, and KO a link, a submodule and a
# path outside printable ASCII outside engine/ only. A second source, f, holds a commit with no author line. A third,
# real, holds one commit whose engine/ is this suite's engine, file by file, and the real plugin.json: that one is
# fetched and run as section 2 says the founder does, with git show and /bin/bash -s.
#
# Readings, where the spec leaves room:
# - A refusal of E4, E5, E6's HOME and E13 changes nothing in HOME: they are read from the arguments and the
#   environment before anything is written. A refusal of E7 or E8 leaves no copy, no .new. directory and no launcher.
# - E6's HOME line is matched by its two ends, "authority-engine: " and " is not an absolute path to a directory": the
#   spec does not say whether HOME there is the word or the value.
# - E8's two paths equal without case: which of the two is named is not said, so either is taken.
# - E10's "nothing in it is written": no path under C is newer than a mark made just before the run. E11's "written each
#   run": the felix launcher is newer than that mark.
# - E2 cannot be faked without root. The git it names is read here (owner, type, modes); where it is one E2 takes, the
#   first run must succeed, and otherwise it must be refused with E2's line, and every later assertion is skipped.
# - What the launcher passes is read from inside the copy: the small felix prints its arguments and environment.
#
# Not covered: E1 and E3 directly (a caller's BASH_ENV is read by /bin/bash before the program's first line, so no
# program can unset it for itself; what git is given shows only through runs that succeed); E2's refusals on a system
# whose git E2 takes; E5's default source, /Users/Shared/felix-authority/source.bundle (the suite never reads or writes
# there); E6's refusal as root (unless this test runs as root); an https:// or ssh:// source.
_ts4u_begin ts4-engine
TS4E_X="$TS4/x"; TS4E_S="$TS4/src.git"; TS4E_B="$TS4/src.bundle"; TS4E_F="$TS4/f.git"; TS4E_FB="$TS4/f.bundle"; TS4E_RS="$TS4/real.git"; TS4E_RB="$TS4/real.bundle"
mkdir -p "$TS4/h" "$TS4/t/h-rel"
_ts4_src "$TS4E_S"
_ts4u_small "$TS4E_S" one 9.8.7; _ts4u_seal "$TS4E_S" main "small engine one$TS4_NL"; TS4E_K1="$TS4_C"; TS4E_T1="$(_ts4_ctree "$TS4E_S" "$TS4E_K1")"
_ts4u_small "$TS4E_S" two -; _ts4u_seal "$TS4E_S" two "small engine two$TS4_NL"; TS4E_K2="$TS4_C"
TS4E_A=""; while [ "${#TS4E_A}" -lt 199 ]; do TS4E_A="${TS4E_A}a"; done
TS4E_SUB3="$TS4E_A$(printf '\303\251') zzz"; _ts4u_seal "$TS4E_S" k3 "$TS4E_SUB3$TS4_NL" "$TS4E_T1"; TS4E_K3="$TS4_C"
TS4E_SUB4="caf$(printf '\303\251') \"q\" \\ b"; _ts4u_seal "$TS4E_S" k4 "$TS4E_SUB4${TS4_NL}${TS4_NL}the body$TS4_NL" "$TS4E_T1"; TS4E_K4="$TS4_C"
_ts4_tree "$TS4E_S" -; _ts4u_put "$TS4E_S" 100644 engine/harness/lib/x.sh "x$TS4_NL"; _ts4u_seal "$TS4E_S" kn "no felix$TS4_NL"; TS4E_KN="$TS4_C"
_ts4u_small "$TS4E_S" one 9.8.7; _ts4u_put "$TS4E_S" 100644 engine/harness/felix "echo felix$TS4_NL"; _ts4u_seal "$TS4E_S" km "a felix of mode 100644$TS4_NL"; TS4E_KM="$TS4_C"
_ts4u_small "$TS4E_S" one 9.8.7; _ts4u_put "$TS4E_S" 120000 engine/harness/a-lnk felix; _ts4u_put "$TS4E_S" 120000 engine/harness/z-lnk felix; _ts4u_seal "$TS4E_S" kl "two links$TS4_NL"; TS4E_KL="$TS4_C"
_ts4u_small "$TS4E_S" one 9.8.7; _ts4u_gitlink "$TS4E_S" "$TS4E_K1" engine/harness/sub; _ts4u_seal "$TS4E_S" ks "a submodule$TS4_NL"; TS4E_KS="$TS4_C"
TS4E_PA="engine/harness/caf$(printf '\303\251')"
_ts4u_small "$TS4E_S" one 9.8.7; _ts4u_put "$TS4E_S" 100644 "$TS4E_PA" "x$TS4_NL"; _ts4u_seal "$TS4E_S" ka "a path outside printable ASCII$TS4_NL"; TS4E_KA="$TS4_C"
_ts4u_small "$TS4E_S" one 9.8.7; _ts4u_put "$TS4E_S" 100644 engine/harness/lib/X.SH "y$TS4_NL"; _ts4u_seal "$TS4E_S" kc "two paths equal without case$TS4_NL"; TS4E_KC="$TS4_C"
_ts4u_small "$TS4E_S" one 9.8.7; _ts4u_put "$TS4E_S" 120000 docs/lnk ../README.md; _ts4u_gitlink "$TS4E_S" "$TS4E_K1" docs/sub; _ts4u_put "$TS4E_S" 100644 "docs/caf$(printf '\303\251').md" "x$TS4_NL"
_ts4u_seal "$TS4E_S" ko "odd entries outside engine/ only$TS4_NL"; TS4E_KO="$TS4_C"
_fx_git "$TS4E_S" bundle create -q "$TS4E_B" --all >/dev/null 2>&1
_ts4_src "$TS4E_F"; _ts4u_small "$TS4E_F" one 9.8.7; _ts4u_seal "$TS4E_F" main "small engine one$TS4_NL"; TS4E_KF="$TS4_C"
printf 'tree %s\n\na commit with no author line\n' "$(_ts4_ctree "$TS4E_F" "$TS4E_KF")" > "$TS4E_X/raw"
TS4E_BAD="$(_fx_git "$TS4E_F" hash-object -t commit -w --literally "$TS4E_X/raw" 2>/dev/null)"; [ -z "$TS4E_BAD" ] || _fx_git "$TS4E_F" update-ref refs/heads/broken "$TS4E_BAD" >/dev/null 2>&1
_fx_git "$TS4E_F" bundle create -q "$TS4E_FB" --all >/dev/null 2>&1
TS4E_E2="$(_ts4u_e2)"; TS4E_LOCKS=yes; [ "$TS4U_OS" = Darwin ] || TS4E_LOCKS=no
TS4E_V="$REAL_HARNESS/../.claude-plugin/plugin.json"; TS4E_RV="$(LC_ALL=C awk -F'"' '$2 == "version" { print $4; exit }' "$TS4E_V" 2>/dev/null)"; TS4E_RV="${TS4E_RV:--}"

# ------------------------------------------------------------------ helpers ---
_ts4e_want() {   # H COMMIT STATE SUBJECT VERSION FILES SOURCE: E12's eleven lines, as _ts4u_out joins them
  local l=- n="$1/.felix/bin/felix authority init --user $TS4_ME --workers WORKERS --source $7 --source-main refs/remotes/origin/main"
  if [ "$TS4E_LOCKS" = yes ]; then l="$1/.felix/bin/lock"; n="$n --lock $l"; fi
  printf 'engine: %s | state: %s | subject: %s | date: %s | version: %s | files: %s | copy: %s | felix: %s | lock: %s | reach-witness: %s | next: %s' \
    "$2" "$3" "$4" "$(_fx_git "$TS4E_S" log -1 --format=%cI "$2" 2>/dev/null)" "$5" "$6" "$1/.felix/engine/$2" "$1/.felix/bin/felix" "$l" "$1/.felix/bin/reach-witness" "$n"
}
_ts4e_no() {   # WHAT WANT DIR HOME ARG...: authority-engine ARG... with HOME is refused with exit and stderr WANT, and DIR is as it was
  local w="$1" want="$2" d="$3" h="$4" s; shift 4; s="$(_ts4_snap "$d")"
  _ts4u_ae "$h" "$@"
  if [ "$(_ts4_snap "$d")" = "$s" ]; then s=unchanged; else s=changed; fi
  _ts4_is "ts4 setup $w, and nothing is written" "$(_ts4u_ref); home: $s" "$want; home: unchanged" "$(_ts4_why)"
}
_ts4e_home() {   # WHAT HOME|-: authority-engine with that HOME (- for none) is refused by E6's HOME line, and $TS4/h is as it was
  local s; s="$(_ts4_snap "$TS4/h" "$TS4/t")"
  if [ "$2" = - ]; then TS4U_UN=(-u HOME); TS4_ENV=(PATH="$TS4_PATH"); _ts4u_run "$TS4/t" bash "$TS4U_AE" "$TS4E_K1" "$TS4E_B"; TS4U_UN=(); TS4_ENV=()
  else _ts4u_ae "$2" "$TS4E_K1" "$TS4E_B"; fi
  if [ "$(_ts4_snap "$TS4/h" "$TS4/t")" = "$s" ]; then s=unchanged; else s=changed; fi
  _ts4_is "ts4 setup E6: authority-engine refuses $1: one line on stderr, the one E6 gives for HOME, exit 1, and nothing is written" \
    "exit $TS4_RC; lines: $(_ts4_rows "$TS4/e"); $(LC_ALL=C awk 'NR == 1 { print ((index($0, "authority-engine: ") == 1 && substr($0, length($0) - 38) == " is not an absolute path to a directory") ? "the line E6 gives" : "another line") }' "$TS4/e"); $s" \
    "exit 1; lines: 1; the line E6 gives; unchanged" "$(_ts4_why)"
}
_ts4e_dir() {   # WHAT WANT H: authority-engine with HOME H, as the case staged it, is refused with WANT and leaves no copy of K1
  _ts4u_ae "$3" "$TS4E_K1" "$TS4E_B"
  _ts4_is "ts4 setup E6: authority-engine refuses $1, and makes no copy" "$(_ts4u_ref); copy: $(_ts4_yn test -e "$3/.felix/engine/$TS4E_K1")" "$2; copy: no" "$(_ts4_why)"
}
_ts4e_e8() {   # WHAT COMMIT WANT: in the home hr, authority-engine COMMIT is refused with WANT, before any of the copy is written
  _ts4u_ae "$TS4/h/hr" "$2" "$TS4E_B"
  _ts4_is "ts4 setup E8: authority-engine refuses $1, and writes no copy, no .new. directory and no launcher" \
    "$(_ts4u_ref); engine holds: $(_ts4u_ls "$TS4/h/hr/.felix/engine"); bin holds: $(_ts4u_ls "$TS4/h/hr/.felix/bin")" "$3; engine holds: boot.git ; bin holds: " "$(_ts4_why)"
}
_ts4e_differ() {   # WHAT: with C1 changed as the caller staged it, authority-engine K1 is refused by E10, and C1 is as it was
  local s; s="$(_ts4_snap "$TS4E_C1"; ls -lR "$TS4E_C1" 2>/dev/null)"; _ts4u_ae "$TS4E_H1" "$TS4E_K1" "$TS4E_B"
  if [ "$(_ts4_snap "$TS4E_C1"; ls -lR "$TS4E_C1" 2>/dev/null)" = "$s" ]; then s=unchanged; else s=changed; fi
  _ts4_is "ts4 setup E10: a copy there before $1 is refused, and left as it is" "$(_ts4u_ref); copy: $s" \
    "exit 1; stderr: authority-engine: $TS4E_C1 is there and differs from the commit; it is left as it is; copy: unchanged" "$(_ts4_why)"
}

# ------------------------------------------------------------------ controls ---
is "ts4 setup E (control): K1's engine/ holds seven files, felix and the two programs of mode 100755, and the source two files outside it" \
  "$(_fx_git "$TS4E_S" ls-tree -r "$TS4E_K1" 2>/dev/null | LC_ALL=C awk -F'\t' '{ split($1, a, " "); printf "%s %s; ", a[1], $2 }')" \
  "100644 README.md; 100644 docs/a.md; 100644 engine/.claude-plugin/plugin.json; 100644 engine/.gitattributes; 100755 engine/harness/bin/lock-macos; 100755 engine/harness/bin/reach-witness; 100755 engine/harness/felix; 100644 engine/harness/lib/id.txt; 100644 engine/harness/lib/x.sh; "
is "ts4 setup E (control): the refused commits hold what their cases say: no felix, a felix of 100644, two links, a submodule, a path outside printable ASCII, two paths equal without case" \
  "$(_fx_git "$TS4E_S" ls-tree -r "$TS4E_KN" -- engine/harness/felix 2>/dev/null | wc -l | tr -d ' ') $(_fx_git "$TS4E_S" ls-tree "$TS4E_KM" -- engine/harness/felix 2>/dev/null | cut -c1-6) $(_fx_git "$TS4E_S" ls-tree "$TS4E_KL" -- engine/harness/a-lnk engine/harness/z-lnk 2>/dev/null | cut -c1-6 | tr '\n' ' ')$(_fx_git "$TS4E_S" ls-tree "$TS4E_KS" -- engine/harness/sub 2>/dev/null | cut -c1-6) $(_fx_git "$TS4E_S" -c core.quotePath=false ls-tree --name-only "$TS4E_KA" -- engine/harness/ 2>/dev/null | LC_ALL=C awk '/[^ -~]/ { n++ } END { print n + 0 }') $(_fx_git "$TS4E_S" ls-tree --name-only "$TS4E_KC" -- engine/harness/lib/ 2>/dev/null | LC_ALL=C tr 'A-Z' 'a-z' | LC_ALL=C sort | uniq -d)" \
  "0 100644 120000 120000 160000 1 engine/harness/lib/x.sh"
is "ts4 setup E (control): the bundle lists each branch of the source, and git reads the subjects of K3 and K4 as made" \
  "$(_fx_git "$TS4E_X" bundle list-heads "$TS4E_B" 2>/dev/null | LC_ALL=C awk 'index($2, "refs/heads/") == 1 { print $2 }' | LC_ALL=C sort | tr '\n' ' ')$(_fx_git "$TS4E_S" log -1 --format=%s "$TS4E_K3" 2>/dev/null | LC_ALL=C awk '{ print length($0) }') $( [ "$(_fx_git "$TS4E_S" log -1 --format=%s "$TS4E_K4" 2>/dev/null)" = "$TS4E_SUB4" ] && printf same)" \
  "refs/heads/k3 refs/heads/k4 refs/heads/ka refs/heads/kc refs/heads/kl refs/heads/km refs/heads/kn refs/heads/ko refs/heads/ks refs/heads/main refs/heads/two 205 same"
_fx_git "$TS4E_S" archive -o "$TS4E_X/k1.tar" "$TS4E_K1" engine/harness/lib/id.txt 2>/dev/null; ( cd "$TS4E_X" && tar -xf k1.tar ) 2>/dev/null   # a file, not a pipe into tar (part 1296, R42)
is "ts4 setup E9 (control): the attributes file of K1 changes lib/id.txt when git archive writes it, so a copy taken that way would differ from the blob" \
  "$(if [ -f "$TS4E_X/engine/harness/lib/id.txt" ] && [ "$(cksum < "$TS4E_X/engine/harness/lib/id.txt")" != "$(_fx_git "$TS4E_S" cat-file blob "$TS4E_K1:engine/harness/lib/id.txt" | cksum)" ]; then printf changed; else printf 'the same, or not written'; fi)" changed
( export GIT_CONFIG_GLOBAL=/dev/null; _fx_git "$TS4E_X" init -q --bare p.git && _fx_git "$TS4E_X" init -q --bare q.git && _fx_git "$TS4E_X/p.git" fetch -q "$TS4E_FB" '+refs/*:refs/x/*'; _fx_git "$TS4E_X/q.git" -c fetch.fsckObjects=true fetch -q "$TS4E_FB" '+refs/*:refs/x/*' ) >/dev/null 2>&1
is "ts4 setup E7 (control): f's bundle holds a commit with no author line, which this git's plain fetch takes and its fetch that checks objects refuses" \
  "plain: $(_ts4_yn _fx_git "$TS4E_X/p.git" cat-file -e "${TS4E_BAD:-none}"); checked: $(_ts4_yn _fx_git "$TS4E_X/q.git" cat-file -e "${TS4E_BAD:-none}")" "plain: yes; checked: no"

# ------------------------------------------------------------------ the first run: which git (E2), the copy (E6, E7, E9), what it prints (E12) ---
TS4E_H1="$TS4/h/one"; TS4E_C1="$TS4E_H1/.felix/engine/$TS4E_K1"; mkdir -p "$TS4E_H1"
_ts4u_ae "$TS4E_H1" "$TS4E_K1" "$TS4E_B"
if [ "$TS4E_E2" = takes ]; then
  _ts4_is "ts4 setup E2: the git E2 names for this system is one only root can change, and a run with a commit of the source succeeds" "exit $TS4_RC; $(_ts4_line 'engine: ' "$TS4/o")" "exit 0; engine: $TS4E_K1" "$(_ts4_why)"
else
  _ts4_is "ts4 setup E2: the git E2 names for this system is one only root can change, and a run with a commit of the source succeeds" "$(_ts4u_ref)" "exit 1; stderr: $TS4E_E2" "$(_ts4_why)"
  TS4_SKIP="the git E2 names is not one it takes on this system ($TS4E_E2), so no run here succeeds"
fi
_ts4_is "ts4 setup E12: a first run prints engine, state made, subject, date, version, files, copy, felix, lock, reach-witness and next, in that order, and exits 0" \
  "exit $TS4_RC; $(_ts4u_out)" "exit 0; $(_ts4e_want "$TS4E_H1" "$TS4E_K1" made 'small engine one' 9.8.7 7 "$TS4E_B")" "$(_ts4_why)"
_ts4_is "ts4 setup E9: the copy C holds engine/ alone, each file the bytes of its blob with mode 600 for 100644 and 700 for 100755, each directory 700" \
  "$(_ts4u_cmp "$TS4E_S" "$TS4E_K1" "$TS4E_C1")" same
_ts4_is "ts4 setup E9: the copy is written from the blobs: lib/id.txt holds \$Id\$ and LF line ends whatever the commit's attributes file asks" \
  "$( [ -f "$TS4E_C1/engine/harness/lib/id.txt" ] && cksum < "$TS4E_C1/engine/harness/lib/id.txt")" "$(printf '%s\n' '$Id$' 'line two' | cksum)"
_ts4_is "ts4 setup E6, E9: the home holds .felix alone, .felix holds bin and engine, nothing under .felix/authority, and engine holds boot.git and the copy, no .new. directory" \
  "$(_ts4u_ls "$TS4E_H1")| $(_ts4u_ls "$TS4E_H1/.felix")| $(_ts4u_ls "$TS4E_H1/.felix/engine")" ".felix | bin engine | $TS4E_K1 boot.git "
_ts4_is "ts4 setup E6: .felix, .felix/engine, .felix/engine/boot.git and .felix/bin are made with mode 700" \
  "$(for TS4E_V in .felix .felix/engine .felix/engine/boot.git .felix/bin; do printf '%s ' "$(_ts4u_m "$TS4E_H1/$TS4E_V")"; done)" "drwx------ drwx------ drwx------ drwx------ "
_ts4_is "ts4 setup E6, E7: boot.git is a bare repository that holds the source's refs under refs/boot/" \
  "$(_ts4_sg "$TS4E_H1/.felix/engine/boot.git" rev-parse --is-bare-repository); main: $(_ts4_sg "$TS4E_H1/.felix/engine/boot.git" rev-parse -q --verify refs/boot/heads/main); two: $(_ts4_sg "$TS4E_H1/.felix/engine/boot.git" rev-parse -q --verify refs/boot/heads/two)" \
  "true; main: $TS4E_K1; two: $TS4E_K2"
if [ "$TS4E_LOCKS" = yes ]; then TS4E_V="felix lock reach-witness "; else TS4E_V="felix reach-witness "; fi
_ts4_is "ts4 setup E11: .felix/bin holds the launchers felix and reach-witness, and lock on macOS alone, each of mode 700, and no temporary file" \
  "$(_ts4u_ls "$TS4E_H1/.felix/bin")$(for TS4E_W in felix lock reach-witness; do [ ! -e "$TS4E_H1/.felix/bin/$TS4E_W" ] || printf '%s ' "$(_ts4u_m "$TS4E_H1/.felix/bin/$TS4E_W")"; done)" \
  "$TS4E_V$(printf '%s' "$TS4E_V" | LC_ALL=C awk '{ for (i = 1; i <= NF; i++) printf "-rwx------ " }')"
for TS4E_W in felix:felix reach-witness:bin/reach-witness lock:bin/lock-macos; do
  TS4E_V="ts4 setup E11: the launcher ${TS4E_W%%:*} is three lines: #!/bin/sh, a comment naming the commit, and exec through env -i of ${TS4E_W#*:} in the copy"
  if [ "${TS4E_W%%:*}" = lock ]; then
    TS4E_V="ts4 setup E11: on macOS the launcher lock is three lines: #!/bin/sh, a comment naming the commit, and exec through env -i of bin/lock-macos in the copy; elsewhere there is none"
    if [ "$TS4E_LOCKS" = no ]; then _ts4_is "$TS4E_V" "$(_ts4u_launcher "$TS4E_H1/.felix/bin/lock" "$TS4E_K1")" "no launcher"; continue; fi
  fi
  _ts4_is "$TS4E_V" "$(_ts4u_launcher "$TS4E_H1/.felix/bin/${TS4E_W%%:*}" "$TS4E_K1")" \
    "lines: 3; first: #!/bin/sh; second, a comment naming the commit: yes; third: $(_ts4u_exec "$TS4E_H1" "$TS4E_C1" "${TS4E_W#*:}")"
done
printf ': > "%s"\n' "$TS4E_X/benv.mark" > "$TS4E_X/benv.sh"
TS4_ENV=(TERM=xterm-ts4 FELIX_AUTHORITY_HOME="$TS4E_X/ah" FELIX_TS4=1 GIT_DIR="$TS4E_X/nogit" GIT_CONFIG_GLOBAL="$TS4E_X/nocfg" BASH_ENV="$TS4E_X/benv.sh" ENV="$TS4E_X/benv.sh")
_ts4u_run "$TS4/t" self "$TS4E_H1/.felix/bin/felix" "a b" c; TS4_ENV=()
if [ "$TS4E_LOCKS" = yes ]; then TS4E_V=/Library/Developer/CommandLineTools; else TS4E_V=unset; fi
_ts4_is "ts4 setup E11: the felix launcher runs the copy with its arguments, this HOME, USER and LOGNAME, the caller's TERM, the system's PATH, and no FELIX_, GIT_, BASH_ENV or ENV of the caller's" \
  "exit $TS4_RC; $(_ts4u_out); BASH_ENV read: $(_ts4_yn test -e "$TS4E_X/benv.mark")" \
  "exit 0; small engine one | args: 2 | arg: a b | arg: c | home: $TS4E_H1 | user: $TS4_ME | logname: $TS4_ME | term: xterm-ts4 | path: $TS4U_SYSPATH | developer_dir: $TS4E_V | others: ; BASH_ENV read: no" "$(_ts4_why)"
TS4U_UN=(-u TERM); _ts4u_run "$TS4/t" self "$TS4E_H1/.felix/bin/felix"; TS4U_UN=()
_ts4_is "ts4 setup E11: with no TERM in the caller's environment the copy is given TERM=dumb" "exit $TS4_RC; $(_ts4_line 'term: ' "$TS4/o")" "exit 0; term: dumb" "$(_ts4_why)"

# ------------------------------------------------------------------ a copy already there (E10) ---
sleep 1; : > "$TS4E_X/mark"; _ts4u_ae "$TS4E_H1" "$TS4E_K1" "$TS4E_B"
_ts4_is "ts4 setup E10, E12: a second run with the same commit finds the copy in place, writes nothing in it, prints state: in place, and writes the launchers again" \
  "exit $TS4_RC; $(_ts4u_out); newer in the copy: $(find "$TS4E_C1" -newer "$TS4E_X/mark" -print 2>/dev/null | LC_ALL=C awk 'END { print NR }'); launcher written: $( [ -n "$(find "$TS4E_H1/.felix/bin/felix" -newer "$TS4E_X/mark" -print 2>/dev/null)" ] && printf yes || printf no)" \
  "exit 0; $(_ts4e_want "$TS4E_H1" "$TS4E_K1" 'in place' 'small engine one' 9.8.7 7 "$TS4E_B"); newer in the copy: 0; launcher written: yes" "$(_ts4_why)"
TS4E_XS="$TS4E_C1/engine/harness/lib/x.sh"; cp -p "$TS4E_XS" "$TS4E_X/x.keep" 2>/dev/null
{ printf 'x=changed\n' > "$TS4E_XS"; } 2>/dev/null; _ts4e_differ "in which a file's bytes differ from its blob"; cp -p "$TS4E_X/x.keep" "$TS4E_XS" 2>/dev/null
chmod 700 "$TS4E_XS" 2>/dev/null; _ts4e_differ "in which a file of mode 100644 has mode 700"; chmod 600 "$TS4E_XS" 2>/dev/null
{ : > "$TS4E_C1/engine/harness/lib/extra"; } 2>/dev/null; _ts4e_differ "that holds a file the commit lacks"; rm -f "$TS4E_C1/engine/harness/lib/extra"
mkdir -p "$TS4E_C1/engine/harness/empty"; _ts4e_differ "that holds a directory the commit lacks"; rmdir "$TS4E_C1/engine/harness/empty" 2>/dev/null
mv "$TS4E_XS" "$TS4E_X/x.moved" 2>/dev/null; _ts4e_differ "that lacks one of the commit's files"; mv "$TS4E_X/x.moved" "$TS4E_XS" 2>/dev/null
mv "$TS4E_XS" "$TS4E_X/x.moved" 2>/dev/null; ln -s "$TS4E_X/x.moved" "$TS4E_XS" 2>/dev/null; _ts4e_differ "in which a file is a link to a file of the same bytes"; rm -f "$TS4E_XS"; mv "$TS4E_X/x.moved" "$TS4E_XS" 2>/dev/null
chmod 777 "$TS4E_C1" 2>/dev/null; _ts4e_differ "whose own top directory has mode 777 (review)"; chmod 700 "$TS4E_C1" 2>/dev/null
TS4E_RW="ts4 setup E10: a copy there before in which a file carries an access-control entry that allows (review) is refused, and left as it is"
if [ "$TS4U_OS" != Darwin ]; then skip "$TS4E_RW" "this is not macOS"
elif ! chmod +a "everyone allow write,append" "$TS4E_C1/engine/harness/felix" 2>/dev/null; then skip "$TS4E_RW" "chmod +a put no access-control entry on a file here"
else _ts4e_differ "in which a file carries an access-control entry that allows (review)"; chmod -N "$TS4E_C1/engine/harness/felix" 2>/dev/null; fi
_ts4u_ae "$TS4E_H1" "$TS4E_K1" "$TS4E_B"
_ts4_is "ts4 setup E10 (control): with each change undone, the copy is in place again" "exit $TS4_RC; $(_ts4_line 'state: ' "$TS4/o"); $(_ts4u_cmp "$TS4E_S" "$TS4E_K1" "$TS4E_C1")" "exit 0; state: in place; same" "$(_ts4_why)"

# ------------------------------------------------------------------ another commit, the subject and the version (E11, E12) ---
_ts4u_ae "$TS4E_H1" "$TS4E_K2" "$TS4E_B"; TS4E_V="exit $TS4_RC; $(_ts4u_out)"; _ts4u_run "$TS4/t" self "$TS4E_H1/.felix/bin/felix"
_ts4_is "ts4 setup E11, E12: a later run with another commit makes its copy, prints version - for a commit with no plugin.json, and the felix launcher then runs that copy" \
  "$TS4E_V; then: $(LC_ALL=C awk 'NR == 1' "$TS4/o")" "exit 0; $(_ts4e_want "$TS4E_H1" "$TS4E_K2" made 'small engine two' - 6 "$TS4E_B"); then: small engine two" "$(_ts4_why)"
mkdir -p "$TS4/h/three" "$TS4/h/four"; _ts4u_ae "$TS4/h/three" "$TS4E_K3" "$TS4E_B"; TS4E_V="exit $TS4_RC; $(_ts4u_val subject)"; _ts4u_ae "$TS4/h/four" "$TS4E_K4" "$TS4E_B"
_ts4_is "ts4 setup E12: the subject is the message's first line, cut to 200 bytes and then escaped as section 0 says" \
  "$TS4E_V; $(_ts4u_val subject)" "exit 0; $(_ts4_esc "$TS4E_A$(printf '\303')"); $(_ts4_esc "$TS4E_SUB4")" "$(_ts4_why)"
TS4E_W="$(_ts4_esc "$TS4E_PA")"

# ------------------------------------------------------------------ usage and the arguments (E4, E5, E13) ---
mkdir -p "$TS4/h/h0"; cp "$TS4E_B" "$TS4/t/src.bundle" 2>/dev/null; TS4E_V="$(printf '%s' "$TS4E_K1" | LC_ALL=C tr 'abcdef' 'ABCDEF')"
TS4E_U="exit 2; stderr: usage: authority-engine COMMIT [SOURCE]"
_ts4e_no "E13: with no argument authority-engine is a usage error" "$TS4E_U" "$TS4/h/h0" "$TS4/h/h0"
_ts4e_no "E13: with three arguments authority-engine is a usage error" "$TS4E_U" "$TS4/h/h0" "$TS4/h/h0" "$TS4E_K1" "$TS4E_B" more
_ts4e_no "E13: a first argument that starts with - is a usage error" "$TS4E_U" "$TS4/h/h0" "$TS4/h/h0" --help
_ts4e_no "E13: a second argument that starts with - is a usage error" "$TS4E_U" "$TS4/h/h0" "$TS4/h/h0" "$TS4E_K1" -x
TS4E_U="exit 1; stderr: authority-engine: name the whole commit id, forty lowercase hex digits"
_ts4e_no "E4: a short commit id is refused" "$TS4E_U" "$TS4/h/h0" "$TS4/h/h0" "${TS4E_K1:0:7}" "$TS4E_B"
_ts4e_no "E4: a commit id in upper case is refused" "$TS4E_U" "$TS4/h/h0" "$TS4/h/h0" "$TS4E_V" "$TS4E_B"
_ts4e_no "E4: forty-one hex digits are refused" "$TS4E_U" "$TS4/h/h0" "$TS4/h/h0" "${TS4E_K1}0" "$TS4E_B"
_ts4e_no "E4: forty characters one of which is not hex are refused" "$TS4E_U" "$TS4/h/h0" "$TS4/h/h0" "${TS4E_K1:0:39}g" "$TS4E_B"
TS4E_U="exit 1; stderr: authority-engine: the source is not an absolute path or a file, https or ssh URL"
_ts4e_no "E5: a source that is a relative path, though a bundle stands there, is refused" "$TS4E_U" "$TS4/h/h0" "$TS4/h/h0" "$TS4E_K1" src.bundle
_ts4e_no "E5: a source that is an http:// URL is refused" "$TS4E_U" "$TS4/h/h0" "$TS4/h/h0" "$TS4E_K1" http://example.invalid/src.git
_ts4e_no "E5: a source of the ext:: transport is refused" "$TS4E_U" "$TS4/h/h0" "$TS4/h/h0" "$TS4E_K1" "ext::sh -c true"
_ts4e_no "E5: a source of the form user@host:path is refused" "$TS4E_U" "$TS4/h/h0" "$TS4/h/h0" "$TS4E_K1" git@example.invalid:src.git
_fx_git "$TS4E_X" init -q --bare u.git >/dev/null 2>&1; _fx_git "$TS4E_X/u.git" fetch -q "file://$TS4E_S" '+refs/heads/main:refs/x/main' >/dev/null 2>&1
if [ "$(_ts4_sg "$TS4E_X/u.git" rev-parse -q --verify refs/x/main)" = "$TS4E_K1" ]; then
  mkdir -p "$TS4/h/five"; _ts4u_ae "$TS4/h/five" "$TS4E_K1" "file://$TS4E_S"
  _ts4_is "ts4 setup E5: a source that is a file:// URL of a repository is taken, and the next line names it" "exit $TS4_RC; $(_ts4_line 'engine: ' "$TS4/o"); $(_ts4_count "next: $TS4/h/five/.felix/bin/felix authority init --user $TS4_ME --workers WORKERS --source file://$TS4E_S " "$TS4/o")" \
    "exit 0; engine: $TS4E_K1; 1" "$(_ts4_why)"
else
  skip "ts4 setup E5: a source that is a file:// URL of a repository is taken, and the next line names it" "this git does not fetch from a file:// URL of a repository"
fi
# Review show-escaping: the next line is typed, so a source holding a space or a ; is quoted for the shell there.
mkdir -p "$TS4E_X/my drop" "$TS4/h/six"; cp "$TS4E_B" "$TS4E_X/my drop/x;echo INJECTED" 2>/dev/null; _ts4u_ae "$TS4/h/six" "$TS4E_K1" "$TS4E_X/my drop/x;echo INJECTED"
_ts4_is "ts4 setup E12 (review): a source holding a space and a ; is put in single quotes on the next line, which then names it as one word" \
  "exit $TS4_RC; $(_ts4_count "next: $TS4/h/six/.felix/bin/felix authority init --user $TS4_ME --workers WORKERS --source '$TS4E_X/my drop/x;echo INJECTED' --source-main " "$TS4/o")" \
  "exit 0; 1" "$(_ts4_why)"
# Review F4: E1's unsetting of each GIT_ variable, which no run above passes. With the caller's GIT_OBJECT_DIRECTORY
# kept, the fetched objects went there, outside HOME.
mkdir -p "$TS4/h/genv" "$TS4E_X/gobj"
TS4_ENV=(GIT_OBJECT_DIRECTORY="$TS4E_X/gobj" GIT_DIR="$TS4E_X/gdir" GIT_INDEX_FILE="$TS4E_X/gidx"); _ts4u_ae "$TS4/h/genv" "$TS4E_K1" "$TS4E_B"; TS4_ENV=()
_ts4_is "ts4 setup E1 (review): a caller's GIT_OBJECT_DIRECTORY, GIT_DIR and GIT_INDEX_FILE reach no git of the run: the copy is made from the boot store, which holds the objects, and nothing is written where they point" \
  "exit $TS4_RC; $(_ts4_line 'state: ' "$TS4/o"); boot objects: $(find "$TS4/h/genv/.felix/engine/boot.git/objects" -type f 2>/dev/null | LC_ALL=C awk 'END { print (NR > 0 ? "yes" : "no") }'); written where they point: $(find "$TS4E_X/gobj" "$TS4E_X/gdir" "$TS4E_X/gidx" -mindepth 1 2>/dev/null | LC_ALL=C awk 'END { print NR }') and $(_ts4_yn test -e "$TS4E_X/gdir") $(_ts4_yn test -e "$TS4E_X/gidx")" \
  "exit 0; state: made; boot objects: yes; written where they point: 0 and no no" "$(_ts4_why)"

# ------------------------------------------------------------------ HOME and the four directories (E6) ---
mkdir -p "$TS4/h/it's" "$TS4/h/caf$(printf '\303\251')"; : > "$TS4/h/afile"
_ts4e_home "a HOME that is a relative path to a directory" h-rel
_ts4e_home "a HOME that is not there" "$TS4/h/none"
_ts4e_home "a HOME that is a file" "$TS4/h/afile"
_ts4e_home "a HOME that holds a single quote" "$TS4/h/it's"
_ts4e_home "a HOME that holds a byte outside printable ASCII" "$TS4/h/caf$(printf '\303\251')"
_ts4e_home "an environment with no HOME" -
mkdir -p "$TS4/h/l1" "$TS4E_X/elsewhere"; ln -s "$TS4E_X/elsewhere" "$TS4/h/l1/.felix" 2>/dev/null; TS4E_V="$(_ts4_snap "$TS4E_X/elsewhere")"
_ts4e_dir "a .felix that is a link to a directory" "exit 1; stderr: authority-engine: $TS4/h/l1/.felix is not a directory" "$TS4/h/l1"
_ts4_is "ts4 setup E6: and writes nothing where that link points" "$(if [ "$(_ts4_snap "$TS4E_X/elsewhere")" = "$TS4E_V" ]; then printf unchanged; else printf changed; fi)" unchanged
mkdir -p "$TS4/h/l2/.felix"; chmod 700 "$TS4/h/l2/.felix"; : > "$TS4/h/l2/.felix/engine"
_ts4e_dir "a .felix/engine that is a file" "exit 1; stderr: authority-engine: $TS4/h/l2/.felix/engine is not a directory" "$TS4/h/l2"
mkdir -p "$TS4/h/l3/.felix/engine"; chmod 700 "$TS4/h/l3/.felix" "$TS4/h/l3/.felix/engine"; : > "$TS4/h/l3/.felix/engine/boot.git"
_ts4e_dir "a .felix/engine/boot.git that is a file" "exit 1; stderr: authority-engine: $TS4/h/l3/.felix/engine/boot.git is not a directory" "$TS4/h/l3"
mkdir -p "$TS4/h/l4/.felix" "$TS4E_X/bin-elsewhere"; chmod 700 "$TS4/h/l4/.felix"; ln -s "$TS4E_X/bin-elsewhere" "$TS4/h/l4/.felix/bin" 2>/dev/null
_ts4e_dir "a .felix/bin that is a link to a directory" "exit 1; stderr: authority-engine: $TS4/h/l4/.felix/bin is not a directory" "$TS4/h/l4"
mkdir -p "$TS4/h/w1/.felix"; chmod 770 "$TS4/h/w1/.felix"
_ts4e_dir "a .felix its group can write" "exit 1; stderr: authority-engine: $TS4/h/w1/.felix can be written by another login" "$TS4/h/w1"
mkdir -p "$TS4/h/w2/.felix/engine"; chmod 700 "$TS4/h/w2/.felix"; chmod 702 "$TS4/h/w2/.felix/engine"
_ts4e_dir "a .felix/engine that every login can write" "exit 1; stderr: authority-engine: $TS4/h/w2/.felix/engine can be written by another login" "$TS4/h/w2"
mkdir -p "$TS4/h/w3/.felix/bin"; chmod 700 "$TS4/h/w3/.felix"; chmod 720 "$TS4/h/w3/.felix/bin"
_ts4e_dir "a .felix/bin its group can write" "exit 1; stderr: authority-engine: $TS4/h/w3/.felix/bin can be written by another login" "$TS4/h/w3"
mkdir -p "$TS4/h/w4/.felix/bin"; chmod 700 "$TS4/h/w4/.felix" "$TS4/h/w4/.felix/bin"
TS4E_RW="ts4 setup E6: authority-engine refuses a .felix/bin with an access-control entry that allows (review), and makes no copy"
if [ "$TS4U_OS" != Darwin ]; then skip "$TS4E_RW" "this is not macOS"
elif ! chmod +a "everyone allow add_file,delete_child" "$TS4/h/w4/.felix/bin" 2>/dev/null; then skip "$TS4E_RW" "chmod +a put no access-control entry on a directory here"
else _ts4e_dir "a .felix/bin with an access-control entry that allows (review)" "exit 1; stderr: authority-engine: $TS4/h/w4/.felix/bin can be written by another login" "$TS4/h/w4"; fi
if [ "$TS4U_UID" = 0 ]; then
  mkdir -p "$TS4/h/root"; _ts4e_dir "a run as uid 0" "exit 1; stderr: authority-engine: not as root" "$TS4/h/root"
else
  skip "ts4 setup E6: authority-engine refuses a run as uid 0, and makes no copy" "this test runs as uid $TS4U_UID and uses no sudo"
fi

# ------------------------------------------------------------------ the fetch (E7) and what the commit must hold (E8) ---
mkdir -p "$TS4/h/f1" "$TS4/h/f2" "$TS4/h/hr"
_ts4u_ae "$TS4/h/f1" "$TS4E_K1" "$TS4E_X/none.bundle"
_ts4_is "ts4 setup E7: a source that cannot be fetched is refused, and no copy is made" "$(_ts4u_ref); copy: $(_ts4_yn test -e "$TS4/h/f1/.felix/engine/$TS4E_K1")" \
  "exit 1; stderr: authority-engine: the source could not be fetched, or an object in it failed git's checks; copy: no" "$(_ts4_why)"
_ts4u_ae "$TS4/h/f2" "$TS4E_KF" "$TS4E_FB"
_ts4_is "ts4 setup E7: a source that holds a commit with no author line is refused by the fetch's checks, and no copy and no launcher is made" \
  "$(_ts4u_ref); copy: $(_ts4_yn test -e "$TS4/h/f2/.felix/engine/$TS4E_KF"); launcher: $(_ts4_yn test -e "$TS4/h/f2/.felix/bin/felix")" \
  "exit 1; stderr: authority-engine: the source could not be fetched, or an object in it failed git's checks; copy: no; launcher: no" "$(_ts4_why)"
_ts4e_e8 "a commit the source does not hold" "$TS4_NOPE" "exit 1; stderr: authority-engine: $TS4_NOPE is not a commit the source holds"
_ts4e_e8 "the id of a tree, which is no commit" "$TS4E_T1" "exit 1; stderr: authority-engine: $TS4E_T1 is not a commit the source holds"
_ts4e_e8 "a commit that holds no engine/harness/felix" "$TS4E_KN" "exit 1; stderr: authority-engine: $TS4E_KN holds no engine (engine/harness/felix)"
_ts4e_e8 "a commit whose engine/harness/felix has mode 100644" "$TS4E_KM" "exit 1; stderr: authority-engine: $TS4E_KM holds no engine (engine/harness/felix)"
_ts4e_e8 "a commit whose engine/ holds links, naming the first" "$TS4E_KL" "exit 1; stderr: authority-engine: engine/harness/a-lnk in $TS4E_KL is a link or a submodule, and the copy holds files only"
_ts4e_e8 "a commit whose engine/ holds a submodule" "$TS4E_KS" "exit 1; stderr: authority-engine: engine/harness/sub in $TS4E_KS is a link or a submodule, and the copy holds files only"
_ts4e_e8 "a commit whose engine/ holds a path with a byte outside printable ASCII, printed escaped" "$TS4E_KA" "exit 1; stderr: authority-engine: $TS4E_W in $TS4E_KA cannot be written on this file system as it is named"
_ts4u_ae "$TS4/h/hr" "$TS4E_KC" "$TS4E_B"
_ts4_is "ts4 setup E8: authority-engine refuses a commit whose engine/ holds two paths equal without case, naming one, and writes no copy, no .new. directory and no launcher" \
  "exit $TS4_RC; $(TA="authority-engine: engine/harness/lib/X.SH in $TS4E_KC cannot be written on this file system as it is named" TB="authority-engine: engine/harness/lib/x.sh in $TS4E_KC cannot be written on this file system as it is named" LC_ALL=C awk '{ n++; if ($0 == ENVIRON["TA"] || $0 == ENVIRON["TB"]) f = 1 } END { print (n == 1 && f) ? "the line E8 gives" : "another stderr" }' "$TS4/e"); engine holds: $(_ts4u_ls "$TS4/h/hr/.felix/engine"); bin holds: $(_ts4u_ls "$TS4/h/hr/.felix/bin")" \
  "exit 1; the line E8 gives; engine holds: boot.git ; bin holds: " "$(_ts4_why)"
mkdir -p "$TS4/h/ko"; _ts4u_ae "$TS4/h/ko" "$TS4E_KO" "$TS4E_B"
_ts4_is "ts4 setup E8, E9: a link, a submodule and a path outside printable ASCII outside engine/ are neither judged nor copied" \
  "exit $TS4_RC; files: $(_ts4u_val files); $(_ts4u_cmp "$TS4E_S" "$TS4E_KO" "$TS4/h/ko/.felix/engine/$TS4E_KO")" "exit 0; files: 7; same" "$(_ts4_why)"

# ------------------------------------------------------------------ the engine under test, as the founder gets it onto that login (section 2) ---
_ts4_src "$TS4E_RS"; _ts4u_real "$TS4E_RS"; _ts4u_seal "$TS4E_RS" main "the engine under test$TS4_NL"; TS4E_KR="$TS4_C"
_fx_git "$TS4E_RS" bundle create -q "$TS4E_RB" --all >/dev/null 2>&1
is "ts4 setup 2 (control): the real source's commit holds this suite's engine file by file, modes 100644 and 100755 only, no path outside printable ASCII, no two equal without case" \
  "$(_fx_git "$TS4E_RS" -c core.quotePath=false ls-tree -r "$TS4E_KR" 2>/dev/null | LC_ALL=C awk -F'\t' '{ split($1, a, " "); n++; if (a[1] != "100644" && a[1] != "100755") m++; if ($2 ~ /[^ -~]/) b++; l = tolower($2); if (l in s) d++; s[l] = 1 } END { printf "%d entries, %d other modes, %d outside ASCII, %d equal without case", n, m, b, d }'); felix: $(_fx_git "$TS4E_RS" ls-tree "$TS4E_KR" -- engine/harness/felix 2>/dev/null | cut -c1-6)" \
  "${TS4U_RN:-?} entries, 0 other modes, 0 outside ASCII, 0 equal without case; felix: 100755"
printf '%s\n' 'umask 077; G="$1"; B="$HOME/.felix/engine/boot.git"' \
  'mkdir -p "$HOME/.felix/engine" && "$G" init -q --bare "$B" && "$G" --git-dir="$B" -c transfer.fsckObjects=true fetch -q -- "$3" '"'"'+refs/*:refs/boot/*'"'"'' \
  '"$G" --git-dir="$B" show "$2:engine/harness/bin/authority-engine" | /usr/bin/env -i HOME="$HOME" /bin/bash -s -- "$2" "$3"' > "$TS4E_X/boot.sh"
TS4E_HB="$TS4/h/boot"; mkdir -p "$TS4E_HB"
# Spec rev 3 (review E1-builtin-fn, F7): the third line runs the program under env -i with HOME alone. A BASH_ENV of
# the caller's runs for the bash that runs boot.sh, and must not run for the one that reads the program from its
# input, told apart by the s in $- ($0 is the shell's own name in both while BASH_ENV is read, on bash 3.2).
printf 'case "$-" in *s*) printf "%%s\\n" "$-" >> "%s" ;; esac\n' "$TS4E_X/benv.out" > "$TS4E_X/benv.sh"
TS4_ENV=(HOME="$TS4E_HB" PATH="$TS4_PATH" BASH_ENV="$TS4E_X/benv.sh"); _ts4u_run "$TS4/t" bash "$TS4E_X/boot.sh" "$TS4U_GIT" "$TS4E_KR" "$TS4E_RB"; TS4_ENV=()
_ts4_is "ts4 setup 2: the program read with git show from the bundle's commit and run with /bin/bash -s, its own path unknown, copies that commit's engine and exits 0" \
  "exit $TS4_RC; $(_ts4_line 'engine: ' "$TS4/o"); $(_ts4_line 'state: ' "$TS4/o"); $(_ts4_line 'version: ' "$TS4/o"); $(_ts4_line 'files: ' "$TS4/o")" \
  "exit 0; engine: $TS4E_KR; state: made; version: $TS4E_RV; files: ${TS4U_RN:-?}" "$(_ts4_why)"
_ts4_is "ts4 setup 2 (review E1-builtin-fn): run under env -i with HOME alone, the program reads no BASH_ENV of the caller's" \
  "inner runs: $(if [ -s "$TS4E_X/benv.out" ]; then LC_ALL=C awk 'END { print NR }' "$TS4E_X/benv.out"; else printf 0; fi)" "inner runs: 0" "$(_ts4_why)"
_ts4_is "ts4 setup 2, E9: that copy holds the engine under test, each file its blob's bytes and mode" "$(_ts4u_cmp "$TS4E_RS" "$TS4E_KR" "$TS4E_HB/.felix/engine/$TS4E_KR")" same
TS4_ENV=(FELIX_AUTHORITY_HOME="$TS4E_X/caller-ah"); _ts4u_run "$TS4/t" self "$TS4E_HB/.felix/bin/felix" authority status; TS4_ENV=()
_ts4_is "ts4 setup E11 (section 6): the felix launcher runs the copied engine, whose felix authority status says no authority is set up at HOME/.felix/authority, whatever the caller's FELIX_AUTHORITY_HOME" \
  "exit $TS4_RC; names HOME/.felix/authority: $(_ts4_said "$TS4E_HB/.felix/authority" "$TS4/o" "$TS4/e"); the caller's home made: $(_ts4_yn test -e "$TS4E_X/caller-ah")" \
  "exit 1; names HOME/.felix/authority: yes; the caller's home made: no" "$(_ts4_why)"
TS4_SKIP=""

_ts4u_end
unset TS4E_X TS4E_S TS4E_B TS4E_F TS4E_FB TS4E_RS TS4E_RB TS4E_K1 TS4E_K2 TS4E_K3 TS4E_K4 TS4E_KN TS4E_KM TS4E_KL TS4E_KS TS4E_KA TS4E_KC TS4E_KO TS4E_KF TS4E_KR \
  TS4E_T1 TS4E_A TS4E_SUB3 TS4E_SUB4 TS4E_PA TS4E_BAD TS4E_E2 TS4E_LOCKS TS4E_V TS4E_W TS4E_RW TS4E_U TS4E_RV TS4E_H1 TS4E_C1 TS4E_XS TS4E_HB TS4U_RN
# <<< trust-step4-setup-engine-copy
