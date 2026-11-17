# tests/lib/trust-step4-setup.sh: what parts 2190 to 2192 share (trust step 4, stage 1, the authority setup slice; blind).
# Definitions only (contract C2): sourcing this file defines functions and nothing else. Written from the setup slice's
# spec (rev 1) alone, with no implementation in view. felix authority publish, bin/authority-engine and bin/lock-macos
# are driven as black boxes, and what they write is read with git, ls and find. Each part calls _ts4u_begin first, which
# calls _ts4_begin (lib/trust-step4.sh) and sets the names below, and _ts4u_end last; every file is under $TS4.
#
# TS4U_OS is uname -s; TS4U_UID this login's uid; TS4U_AE and TS4U_LK the suite's copies of bin/authority-engine and
# bin/lock-macos; TS4U_SYSPATH the system's PATH and TS4U_GIT the git E2 names, as section 0 and E2 give them for this
# system; TS4U_UN, names given to env -u for the next run; TS4U_LIMIT the seconds after which a run is ended.

_ts4u_begin() {   # NAME: the fixture root $TMP/NAME, as _ts4_begin makes it, and this slice's names
  _ts4_begin "$1"
  TS4U_OS="$(uname -s 2>/dev/null)"; TS4U_UID="$(id -u 2>/dev/null)"; TS4U_LIMIT=180; TS4U_UN=()
  TS4U_AE="$FROOT/harness/bin/authority-engine"; TS4U_LK="$FROOT/harness/bin/lock-macos"
  if [ "$TS4U_OS" = Darwin ]; then
    TS4U_SYSPATH=/Library/Developer/CommandLineTools/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin; TS4U_GIT=/Library/Developer/CommandLineTools/usr/bin/git
  else
    TS4U_SYSPATH=/usr/bin:/bin:/usr/sbin:/sbin; TS4U_GIT=/usr/bin/git
  fi
}
_ts4u_end() {   # the fixture is removed, modes first, and the names above are unset
  _ts4_end
  unset TS4U_OS TS4U_UID TS4U_LIMIT TS4U_UN TS4U_AE TS4U_LK TS4U_SYSPATH TS4U_GIT
}

# ---- running a program
_ts4u_run() {   # DIR HOW PROGRAM ARG...: PROGRAM in DIR (HOW bash: through /bin/bash; self: as it is), under umask TS4_UMASK, with
                # TS4U_UN taken out of this environment and TS4_ENV added, ended after TS4U_LIMIT s by perl's alarm. stdout is in
                # $TS4/o, stderr in $TS4/e, the status in TS4_RC: absent when there is no such file, down while TS4_SKIP is set
  local d="$1" how="$2" p="$3"; shift 3
  : > "$TS4/o"; : > "$TS4/e"
  if [ -n "$TS4_SKIP" ]; then printf 'not run: %s\n' "$TS4_SKIP" > "$TS4/e"; TS4_RC=down; return 1; fi
  if [ ! -f "$p" ]; then printf 'not run: no file %s\n' "$p" > "$TS4/e"; TS4_RC=absent; return 1; fi
  case "$how" in bash) set -- /bin/bash "$p" "$@" ;; *) set -- "$p" "$@" ;; esac
  { ( umask "$TS4_UMASK"; cd "$d" || exit 97
      exec env -u SSH_CONNECTION -u SSH_TTY ${TS4U_UN[@]+"${TS4U_UN[@]}"} ${TS4_ENV[@]+"${TS4_ENV[@]}"} perl -e 'alarm shift; exec @ARGV' "$TS4U_LIMIT" "$@" ) \
      < /dev/null > "$TS4/o" 2> "$TS4/e" 7>&- 8>&-
    TS4_RC=$?; } 2>/dev/null
}
_ts4u_ae() {   # HOME ARG...: /bin/bash bin/authority-engine ARG... with that HOME, in $TS4/t; TS4_ENV is added after HOME
  local h="$1"; local -a e; shift; e=(${TS4_ENV[@]+"${TS4_ENV[@]}"})
  TS4_ENV=(HOME="$h" PATH="$TS4_PATH" ${e[@]+"${e[@]}"}); _ts4u_run "$TS4/t" bash "$TS4U_AE" "$@"; TS4_ENV=(${e[@]+"${e[@]}"})
}
_ts4u_pub() {   # DIR ARG...: felix authority publish ARG..., run in DIR, with an authority home that is never made ($TS4/noah)
  local d="$1"; local -a e; shift; e=(${TS4_ENV[@]+"${TS4_ENV[@]}"})
  TS4_ENV=(PATH="$TS4_PATH" FELIX_AUTHORITY_HOME="$TS4/noah" ${e[@]+"${e[@]}"}); _ts4u_run "$d" self "$FELIX" authority publish "$@"; TS4_ENV=(${e[@]+"${e[@]}"})
}
_ts4u_out() { LC_ALL=C awk '{ printf "%s%s", (NR > 1 ? " | " : ""), $0 }' "${1:-$TS4/o}" 2>/dev/null; }   # [FILE]: its lines joined by " | "
_ts4u_ref() { printf 'exit %s; stderr: %s' "$TS4_RC" "$(_ts4u_out "$TS4/e")"; }   # the last run as a refusal reads: status and the whole of stderr
_ts4u_val() { local l; l="$(_ts4_line "$1: " "$TS4/o")"; printf '%s' "${l#"$1: "}"; }   # KEY: the value of the first line "KEY: value" of the last stdout
_ts4u_ls() { ( cd "$1" 2>/dev/null && ls -A | LC_ALL=C sort | tr '\n' ' ' ) 2>/dev/null; }   # DIR: the names directly in it, sorted, each followed by a space
_ts4u_m() { _ts4_mode "$1" | cut -c1-10; }   # PATH: its type and mode as ls prints them, or nothing

# ---- a source built with plumbing, in a bare repository (lib/trust-step4.sh's _ts4_src and _ts4_tree)
_ts4u_putf() {   # SRC MODE PATH FILE: PATH's entry in SRC's index holds FILE's bytes as a blob, with MODE (100644, 100755, 120000)
  local b; b="$(_fx_git "$1" hash-object -w --no-filters "$4" 2>/dev/null)" || return 1
  printf '%s %s\t%s\0' "$2" "$b" "$3" | _fx_git "$1" update-index -z --index-info >/dev/null 2>&1
}
_ts4u_put() { printf '%s' "$4" > "$TS4/x/blob"; _ts4u_putf "$1" "$2" "$3" "$TS4/x/blob"; }   # SRC MODE PATH CONTENT: as _ts4u_putf, of CONTENT's bytes
_ts4u_gitlink() { printf '160000 %s\t%s\0' "$2" "$3" | _fx_git "$1" update-index -z --index-info >/dev/null 2>&1; }   # SRC ID PATH: a submodule's entry
_ts4u_seal() {   # SRC BRANCH|- MESSAGE [TREE]: a commit with no parent of the index's tree (or TREE), MESSAGE its message as given, the
                 # committer's date 2026-11-16T10:20:30+01:30, put at refs/heads/BRANCH. TS4_C is the commit
  local t="${4:-}" c
  printf '%s' "$3" > "$TS4/x/msg"
  [ -n "$t" ] || t="$(_fx_git "$1" write-tree 2>/dev/null)"
  c="$( export GIT_COMMITTER_DATE='2026-11-16T10:20:30+0130' GIT_AUTHOR_DATE='2026-11-15T09:00:00+0000'
        _fx_git "$1" -c user.name=worker -c user.email=worker@example.invalid commit-tree --no-gpg-sign "$t" -F "$TS4/x/msg" 2>/dev/null )"
  [ "$2" = - ] || [ -z "$c" ] || _fx_git "$1" update-ref "refs/heads/$2" "$c" >/dev/null 2>&1
  TS4_C="$c"
}
_ts4u_small() {   # SRC WORD VERSION|-: SRC's index is a small engine. Its felix prints "small engine WORD", its arguments, and what
                  # it was given of HOME, USER, LOGNAME, TERM, PATH and DEVELOPER_DIR and the names of FELIX_*, GIT_*, BASH_ENV and
                  # ENV in its environment. lib/id.txt holds $Id$, and engine/.gitattributes asks for ident and CRLF, which a
                  # checkout or an archive would apply. VERSION, unless -, is the version in engine/.claude-plugin/plugin.json.
                  # README.md and docs/a.md stand outside engine/
  local s="$1" f="$TS4/x/small-felix"
  _ts4_tree "$s" -
  printf '%s\n' '#!/bin/bash' "echo \"small engine $2\"" 'echo "args: $#"' 'for a in "$@"; do echo "arg: $a"; done' 'echo "home: $HOME"' \
    'echo "user: ${USER-unset}"' 'echo "logname: ${LOGNAME-unset}"' 'echo "term: ${TERM-unset}"' 'echo "path: $PATH"' \
    'echo "developer_dir: ${DEVELOPER_DIR-unset}"' \
    'others() { env | while IFS== read -r n v; do case "$n" in FELIX_*|GIT_*|BASH_ENV|ENV) printf "%s " "$n" ;; esac; done; }' \
    'echo "others: $(others)"' > "$f"
  _ts4u_putf "$s" 100755 engine/harness/felix "$f"
  _ts4u_put "$s" 100755 engine/harness/bin/reach-witness "#!/bin/bash${TS4_NL}echo \"witness $2\"$TS4_NL"
  _ts4u_put "$s" 100755 engine/harness/bin/lock-macos "#!/bin/bash${TS4_NL}echo \"lock $2\"$TS4_NL"
  _ts4u_put "$s" 100644 engine/harness/lib/x.sh "x=$2$TS4_NL"
  _ts4u_put "$s" 100644 engine/harness/lib/id.txt "\$Id\$${TS4_NL}line two$TS4_NL"
  _ts4u_put "$s" 100644 engine/.gitattributes "* text eol=crlf ident$TS4_NL"
  [ "$3" = - ] || _ts4u_put "$s" 100644 engine/.claude-plugin/plugin.json "{$TS4_NL  \"name\": \"small\",$TS4_NL  \"version\": \"$3\"$TS4_NL}$TS4_NL"
  _ts4u_put "$s" 100644 README.md "outside the engine$TS4_NL"; _ts4u_put "$s" 100644 docs/a.md "outside the engine too$TS4_NL"
}
_ts4u_real() {   # SRC: SRC's index holds this suite's engine: each regular file under $FROOT/harness at engine/harness/, 100755 when
                 # it is executable and 100644 otherwise, and the real engine/.claude-plugin/plugin.json when there is one.
                 # TS4U_RN is the number of files staged
  local s="$1" l="$TS4/x/real.list" i="$TS4/x/real.ids" p="$REAL_HARNESS/../.claude-plugin/plugin.json"
  _ts4_tree "$s" -
  ( cd "$FROOT/harness" && find . -type f -print ) 2>/dev/null | LC_ALL=C sed 's|^\./||' | LC_ALL=C sort > "$l"
  R="$FROOT/harness/" LC_ALL=C awk '{ print ENVIRON["R"] $0 }' "$l" | _fx_git "$s" hash-object -w --no-filters --stdin-paths > "$i" 2>/dev/null
  paste "$i" "$l" | while IFS="$TS4_TAB" read -r b f; do
    if [ -x "$FROOT/harness/$f" ]; then printf '100755 %s\tengine/harness/%s\0' "$b" "$f"; else printf '100644 %s\tengine/harness/%s\0' "$b" "$f"; fi
  done | _fx_git "$s" update-index -z --index-info >/dev/null 2>&1
  TS4U_RN="$(_ts4_rows "$l")"
  if [ -f "$p" ]; then _ts4u_putf "$s" 100644 engine/.claude-plugin/plugin.json "$p"; TS4U_RN=$((TS4U_RN + 1)); fi
}
_ts4u_entries() { _fx_git "$1" ls-tree -r "$2" -- engine 2>/dev/null | LC_ALL=C awk 'END { print NR }'; }   # SRC COMMIT: how many entries its engine/ holds

# ---- what authority-engine wrote
_ts4u_cmp() {   # SRC COMMIT C: "same" when C holds engine/ alone at its top, each entry of ls-tree -r COMMIT -- engine as a file of
                # the blob's bytes with mode 600 (100644) or 700 (100755), each directory 700, and nothing else; else the first difference
  local s="$1" k="$2" c="$3" x="$TS4/x/cmp" n
  [ -d "$c/engine" ] || { printf 'no copy at %s' "$c"; return 1; }
  mkdir -p "$x"
  _fx_git "$s" ls-tree -r "$k" -- engine 2>/dev/null | LC_ALL=C awk -F'\t' '{ split($1, a, " "); m = (a[1] == "100755" ? 700 : (a[1] == "100644" ? 600 : a[1])); print $2 "\t" m "\t" a[3] }' | LC_ALL=C sort > "$x/want"
  ( cd "$c" && find engine -type f -print ) 2>/dev/null | LC_ALL=C sort > "$x/files"
  ( cd "$c" && find engine -type f -perm 700 -print ) > "$x/f700" 2>/dev/null; ( cd "$c" && find engine -type f -perm 600 -print ) > "$x/f600" 2>/dev/null
  C="$c/" LC_ALL=C awk '{ print ENVIRON["C"] $0 }' "$x/files" | _fx_git "$x" hash-object --no-filters --stdin-paths > "$x/ids" 2>/dev/null
  paste "$x/files" "$x/ids" | LC_ALL=C awk -F'\t' -v a="$x/f700" -v b="$x/f600" 'BEGIN { while ((getline l < a) > 0) m[l] = 700; while ((getline l < b) > 0) m[l] = 600 }
    { print $1 "\t" (($1 in m) ? m[$1] : "other") "\t" $2 }' | LC_ALL=C sort > "$x/got"
  if ! cmp -s "$x/want" "$x/got"; then
    printf 'differs: %s' "$(LC_ALL=C diff "$x/want" "$x/got" 2>/dev/null | LC_ALL=C awk '/^[<>]/ { printf "%s; ", $0; if (++n == 2) exit }' | _ts4_flat)"; return 1
  fi
  [ "$(_ts4u_ls "$c")" = "engine " ] || { printf 'the top holds %s' "$(_ts4u_ls "$c")"; return 1; }
  n="$( ( cd "$c" && find engine ! -type f ! -type d -print ) 2>/dev/null | LC_ALL=C awk 'END { print NR }')"; [ "$n" = 0 ] || { printf '%s entries neither file nor directory' "$n"; return 1; }
  n="$( ( cd "$c" && find . -type d ! -perm 700 -print ) 2>/dev/null | head -3 | tr '\n' ' ')"; [ -z "$n" ] || { printf 'directories not 700: %s' "$n"; return 1; }
  printf same
}
_ts4u_exec() {   # H C PROGRAM: the exec line E11 gives a launcher of C/engine/harness/PROGRAM in home H, for this login and system
  local dev=""
  [ "$TS4U_OS" != Darwin ] || dev=" DEVELOPER_DIR='/Library/Developer/CommandLineTools'"
  printf '%s' "exec /usr/bin/env -i HOME='$1' USER='$TS4_ME' LOGNAME='$TS4_ME' TERM=\"\${TERM:-dumb}\" PATH='$TS4U_SYSPATH'$dev /bin/bash '$2/engine/harness/$3' \"\$@\""
}
_ts4u_launcher() {   # FILE COMMIT: what a launcher holds, as E11 reads: its line count, its first line, whether its second is a comment
                     # that names COMMIT, and its third line
  [ -f "$1" ] || { printf 'no launcher'; return 1; }
  K="$2" LC_ALL=C awk 'NR == 1 { f = $0 } NR == 2 { c = (index($0, "#") == 1 && index($0, ENVIRON["K"])) ? "yes" : "no" } NR == 3 { t = $0 }
    END { printf "lines: %d; first: %s; second, a comment naming the commit: %s; third: %s", NR, f, c, t }' "$1"
}
_ts4u_e2() {   # -> "takes" when the git E2 names is a regular file, not a link, owned by uid 0, and neither it nor its directory can
               # be written by group or other; otherwise the line E2 refuses with, here
  local g="$TS4U_GIT"
  if [ ! -e "$g" ] && [ ! -L "$g" ]; then
    if [ "$TS4U_OS" = Darwin ]; then printf 'authority-engine: there is no %s; the Command Line Tools provide it' "$g"; else printf 'authority-engine: there is no %s' "$g"; fi
    return 0
  fi
  if [ ! -L "$g" ] && [ -f "$g" ] && { ls -ldn "$g"; ls -ldn "$(dirname "$g")"; } 2>/dev/null | LC_ALL=C awk 'NR == 1 && $3 != 0 { b = 1 }
       { if (substr($1, 6, 1) == "w" || substr($1, 9, 1) == "w") b = 1 } END { exit (NR == 2 && !b) ? 0 : 1 }'; then printf takes
  else printf 'authority-engine: %s is not a git only root can change' "$g"; fi
}

# ---- the console, read as L3 says, by this test's own reading
_ts4u_console() {   # -> locked, not locked or unknown: this login's sessions in IOConsoleUsers of ioreg -n Root -d1 -a, read as L3 says
  /usr/sbin/ioreg -n Root -d1 -a 2>/dev/null | /usr/bin/plutil -extract IOConsoleUsers json -o - - 2>/dev/null | U="$TS4U_UID" perl -MJSON::PP -e '
    local $/; my $j = eval { decode_json(<STDIN>) }; if (ref $j ne "ARRAY") { print "unknown\n"; exit 0 }
    my ($n, $open) = (0, 0);
    for my $s (@$j) { next unless ref $s eq "HASH" && defined $s->{kCGSSessionUserIDKey} && $s->{kCGSSessionUserIDKey} == $ENV{U}; $n++;
      $open++ if $s->{kCGSSessionOnConsoleKey} && !$s->{CGSSessionScreenIsLocked} }
    print $n == 0 ? "unknown\n" : ($open ? "not locked\n" : "locked\n")' 2>/dev/null || printf 'unknown\n'
}

# ---- condition e, as status prints it
_ts4u_ewhy() {   # the why lines of the last status that say not the authority's alone, joined by |, or "none"
  LC_ALL=C awk 'index($0, "why: not the authority\047s alone") == 1 { printf "%s%s", (n++ ? "|" : ""), substr($0, 6) } END { if (!n) printf "none" }' "$TS4/o" 2>/dev/null
}
_ts4u_eline() { printf "not the authority's alone: it runs %s, which a login workers run as owns or can write (%s such)" "$1" "$2"; }   # FIRST N: C4's why
