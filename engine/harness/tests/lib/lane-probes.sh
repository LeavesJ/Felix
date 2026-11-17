# The lane counter's fault probes (slice 0, docs/2026-10-29-capability-lane-first-slices-design.md section 6 and section
# 11 items 45 to 49; the plan's Contracts C3, C5, C6 and C9), for the blind parts 2200 to 2250. Written blind on
# 2026-10-30 from the design, the Contracts and the reviews' findings (their inputs and observed output only), without
# reading lib/, hooks/, bin/ or felix. Moved whole out of lane-fixture.sh on 2026-10-30, with no function's text changed,
# so that every file of the library stays under 500 lines (V3R3-F2). Functions only (part 0006), each named _lf_ (C9).
# The runners they take as CMD (_lf_run, _lf_start) and _lf_json are lane-fixture.sh's; the reviews' fixtures are
# lane-reviews.sh's.
#
# C9's faults (added on 2026-10-30 for the review's findings, still blind): _lf_fault runs _lf_run or _lf_start with
# git a bash function exported into the engine, that makes a fork fail (fork) or ends the count early (kill) in the
# read of the landings, and with TMPDIR a directory of the fixture's own, so a scratch directory left is seen there and
# removed with $TMP. _lf_json (lane-fixture.sh) reads a session start's JSON again after it.
#
# The second review's round 1: _lf_fork runs its fork probes at reads other than the landings' (date, awk, tr, git or
# command, by the words and calling functions a finding names), and _lf_ended says whether felix lane ended as C3's
# count that did not finish. Its round 2: _lf_kill runs C9's kill at a read a finding names (pwd among them, by its words
# and calling functions), and _lf_gone takes the count's scratch directory away at an awk call a finding names, as a
# cleaner of TMPDIR would. Its round 3: _lf_nfprog and _lf_lroot run felix and the hook under a soft open-file limit set
# in the shell that execs them.
#
# The design's item 46: _lf_probe runs C9's fork or kill probe and says whether it acted in felix's own shell, and
# _lf_said reads what felix lane said of the resolution. The third review's round 1: _lf_probe also wraps sed and head,
# the reads of a project.json's remote_match. Its round 2: _lf_spoke runs felix lane in one of _lf_v3r2's layouts under
# C9's probes, a fresh memory root beside it, and reads what it said and left there.

# MODE FILE TMPDIR CMD... -> CMD (_lf_run or _lf_start, with their arguments) run in a subshell whose TMPDIR, exported,
# is TMPDIR, and where git is a bash function, exported, so that bash imports it into felix and the hook: C9's fault.
# The function acts when its words hold --first-parent and a word that starts refs/remotes/origin/main, the read of the
# landings, every time, and first writes "fired" to FILE. MODE fork: it lowers the soft process limit to 1 (ulimit -S
# -u 1) in the shell that called it and runs git, which that shell cannot fork, then writes "ran <status>" if the shell
# gets there. MODE kill: it writes "kill <parent> <shell>", then sends SIGKILL to the parent of the shell that called
# it, and then to that shell; never to pid 1 or to this suite's shell (it writes "kept" and runs git instead). Any
# other git runs as it is. FILE and TMPDIR hold no double quote, dollar sign, backquote, backslash or ampersand.
# LF_RC is the subshell's status (CMD's LF_RC, or 137 when the kill reached it), LF_FIRE "fired" when the function
# acted as MODE says (fork: git did not run to a clean exit after it; kill: both signals were sent), else what FILE
# shows. A session start's JSON is read again after it with _lf_json, since the subshell's variables are gone. What
# bash says on its own stderr around CMD (a note of a job the kill ended) goes to FILE.shell.
_lf_fault() {
  local m="$1" f="$2" t="$3" b
  shift 3
  LF_FIRE="not run"; LF_RC=125
  case "$f$t" in (*\"*|*\$*|*\`*|*\\*|*\&*) return 1 ;; esac
  [ -n "$f" ] && [ -n "$t" ] || return 1
  case "$m" in
    (fork) b='printf "fired\n" >> "@F@"; ulimit -S -u 1; command git "$@"; r=$?; printf "ran %s\n" "$r" >> "@F@"; return "$r"' ;;
    (kill) b='printf "fired\n" >> "@F@"; s="$(exec sh -c "echo \$PPID")"; p="$(ps -o ppid= -p "$s" 2>/dev/null)"; p="${p//[!0123456789]/}"
      case "$s:$p" in (:*|*:|1:*|*:1|@K@:*|*:@K@) printf "kept %s %s\n" "$p" "$s" >> "@F@"; command git "$@"; return ;; esac
      printf "kill %s %s\n" "$p" "$s" >> "@F@"; kill -KILL "$p"; kill -KILL "$s"; command git "$@"; return' ;;
    (*) return 1 ;;
  esac
  b="${b//@F@/$f}"; b="${b//@K@/$$}"
  rm -f "$f" "$f.shell"
  # What bash itself says, such as its note of a job a kill ended, goes to FILE.shell, not to the suite's stderr.
  { ( TMPDIR="$t"; export TMPDIR
      eval 'git() { local s p r; case " $* " in (*" --first-parent "*) case " $* " in (*" refs/remotes/origin/main"*) '"$b"' ;; esac ;; esac; command git "$@"; }' \
        || exit 125
      export -f git
      "$@"
      exit "$LF_RC" ); } 2> "$f.shell"
  LF_RC=$?
  if [ "$m" = fork ]; then
    LF_FIRE="$(LC_ALL=C awk '$0 == "fired" { f = 1 } $0 == "ran 0" { r = 1 }
      END { s = "not fired"; if (f && r) s = "fired, but git ran to a clean exit after it"; if (f && !r) s = "fired"; print s }' "$f" 2>/dev/null)"
  else
    LF_FIRE="$(LC_ALL=C awk '$0 == "fired" { f = 1 } /^kill [0123456789]+ [0123456789]+$/ { k = 1 } /^kept / { p = $0 }
      END { s = "not fired"; if (f) s = "fired, but no kill was sent [" p "]"; if (f && k) s = "fired"; print s }' "$f" 2>/dev/null)"
  fi
  [ -n "$LF_FIRE" ] || LF_FIRE="not fired"
}

# The second review's round 1 (2026-10-30), still blind: its fixture and its fork probes, taken from its findings'
# inputs. MODE NAME WORDS STACK FILE TMPDIR CMD... -> CMD run as _lf_fault runs it, but with NAME (date, awk, tr, git or
# command) the bash function exported into felix and the hook. It acts, every time, when " $* " matches the case
# pattern WORDS and " ${FUNCNAME[*]} " the case pattern STACK (each case code, quoted as the caller writes it), and
# first writes "fired" to FILE. MODE fork: it lowers the soft process limit to 1 in the shell that called it and runs
# NAME (command NAME), which that shell cannot fork, then writes "ran <status>" if the shell gets there. MODE lower: it
# lowers the limit and runs NAME, a builtin that needs no fork (builtin command), so that shell's next fork fails. LF_RC
# as _lf_fault's; LF_FIRE "fired" when it acted as MODE says (fork: NAME did not run to a clean exit after it).
_lf_fork() {
  local m="$1" n="$2" w="$3" k="$4" f="$5" t="$6" c b
  shift 6
  LF_FIRE="not run"; LF_RC=125
  case "$f$t" in (*\"*|*\'*|*\$*|*\`*|*\\*|*\&*) return 1 ;; esac
  [ -n "$f" ] && [ -n "$t" ] && [ -n "$w" ] && [ -n "$k" ] || return 1
  case "$n" in (date|awk|tr|git) c="command $n" ;; (command) c="builtin command" ;; (*) return 1 ;; esac
  case "$m" in (fork|lower) ;; (*) return 1 ;; esac
  b="$n() { local r; case \" \$* \" in ($w) case \" \${FUNCNAME[*]} \" in ($k) printf 'fired\\n' >> '$f'; ulimit -S -u 1; $c \"\$@\"; r=\$?; printf 'ran %s\\n' \"\$r\" >> '$f'; return \"\$r\" ;; esac ;; esac; $c \"\$@\"; }"
  rm -f "$f" "$f.shell"
  { ( TMPDIR="$t"; export TMPDIR
      eval "$b" || exit 125
      export -f "$n"
      "$@"
      exit "$LF_RC" ); } 2> "$f.shell"
  LF_RC=$?
  LF_FIRE="$(LC_ALL=C awk -v m="$m" '$0 == "fired" { f = 1 } $0 == "ran 0" { r = 1 }
    END { s = "not fired"; if (f) s = "fired"; if (f && r && m == "fork") s = "fired, but it ran to a clean exit after it"; print s }' "$f" 2>/dev/null)"
  [ -n "$LF_FIRE" ] || LF_FIRE="not fired"
}

# The second review's round 2 (2026-10-30), still blind, from its findings' inputs: two more of its probes.
# NAME WORDS STACK FILE TMPDIR CMD... -> CMD run as _lf_fork runs it, with NAME (pwd, date, awk, tr or git) the bash
# function exported into felix and the hook, acting as C9's kill does: when " $* " matches the case pattern WORDS and
# " ${FUNCNAME[*]} " the case pattern STACK, it writes "fired" to FILE, then "kill <parent> <shell>", and sends SIGKILL
# to the parent of the shell that called it, then to that shell; never to pid 1 or this suite's shell (it writes
# "kept" and runs NAME instead). NAME then runs (builtin pwd, or command NAME). LF_RC as _lf_fault's; LF_FIRE "fired"
# when both signals were sent, else what FILE shows.
_lf_kill() {
  local n="$1" w="$2" k="$3" f="$4" t="$5" c b
  shift 5
  LF_FIRE="not run"; LF_RC=125
  case "$f$t" in (*\"*|*\'*|*\$*|*\`*|*\\*|*\&*) return 1 ;; esac
  [ -n "$f" ] && [ -n "$t" ] && [ -n "$w" ] && [ -n "$k" ] || return 1
  case "$n" in (pwd) c="builtin pwd" ;; (date|awk|tr|git) c="command $n" ;; (*) return 1 ;; esac
  b="$n() { local s p; case \" \$* \" in ($w) case \" \${FUNCNAME[*]} \" in ($k) printf 'fired\\n' >> '$f'
    s=\"\$(exec sh -c 'echo \$PPID')\"; p=\"\$(ps -o ppid= -p \"\$s\" 2>/dev/null)\"; p=\"\${p//[!0123456789]/}\"
    case \"\$s:\$p\" in (:*|*:|1:*|*:1|$$:*|*:$$) printf 'kept %s %s\\n' \"\$p\" \"\$s\" >> '$f' ;;
      (*) printf 'kill %s %s\\n' \"\$p\" \"\$s\" >> '$f'; kill -KILL \"\$p\"; kill -KILL \"\$s\" ;; esac ;; esac ;; esac; $c \"\$@\"; }"
  rm -f "$f" "$f.shell"
  { ( TMPDIR="$t"; export TMPDIR
      eval "$b" || exit 125
      export -f "$n"
      "$@"
      exit "$LF_RC" ); } 2> "$f.shell"
  LF_RC=$?
  LF_FIRE="$(LC_ALL=C awk '$0 == "fired" { f = 1 } /^kill [0123456789]+ [0123456789]+$/ { k = 1 } /^kept / { p = $0 }
    END { s = "not fired"; if (f) s = "fired, but no kill was sent [" p "]"; if (f && k) s = "fired"; print s }' "$f" 2>/dev/null)"
  [ -n "$LF_FIRE" ] || LF_FIRE="not fired"
}

# WORDS STACK FILE TMPDIR CMD... -> CMD run as _lf_fork runs it, with awk the bash function exported into felix and the
# hook: the first time " $* " matches the case pattern WORDS and " ${FUNCNAME[*]} " the case pattern STACK while a
# scratch directory of the count (C2: TMPDIR/felix-lane.*) stands, it removes every such directory, as a cleaner of
# TMPDIR or a full disk would take it mid-count, writes "fired" to FILE when none is left, and then runs the real awk.
# LF_RC as _lf_fault's; LF_FIRE "fired" when it removed them, else "not fired".
_lf_gone() {
  local w="$1" k="$2" f="$3" t="$4" b
  shift 4
  LF_FIRE="not run"; LF_RC=125
  case "$f$t" in (*\"*|*\'*|*\$*|*\`*|*\\*|*\&*) return 1 ;; esac
  [ -n "$f" ] && [ -n "$t" ] && [ -n "$w" ] && [ -n "$k" ] || return 1
  b="awk() { local d x=''; case \" \$* \" in ($w) case \" \${FUNCNAME[*]} \" in ($k)
    for d in '$t'/felix-lane.*; do [ ! -d \"\$d\" ] || x=1; done
    if [ -n \"\$x\" ] && mkdir '$f.once' 2>/dev/null; then rm -rf '$t'/felix-lane.*; x=''
      for d in '$t'/felix-lane.*; do [ ! -e \"\$d\" ] || x=1; done; [ -n \"\$x\" ] || printf 'fired\\n' >> '$f'; fi ;; esac ;; esac
    command awk \"\$@\"; }"
  rm -rf "$f" "$f.shell" "$f.once"
  { ( TMPDIR="$t"; export TMPDIR
      eval "$b" || exit 125
      export -f awk
      "$@"
      exit "$LF_RC" ); } 2> "$f.shell"
  LF_RC=$?
  LF_FIRE="$(LC_ALL=C awk '$0 == "fired" { f = 1 } END { print (f ? "fired" : "not fired") }' "$f" 2>/dev/null)"
  [ -n "$LF_FIRE" ] || LF_FIRE="not fired"
}

# OUT REPO -> "ended" when the run whose files are OUT.out and OUT.err, with status LF_RC, ended as C3 says felix lane
# ends a count that cannot finish: status 1, nothing on stdout, felix: the lane count did not finish in REPO on stderr.
_lf_ended() {
  local e
  e="$(LC_ALL=C awk -v w="felix: the lane count did not finish in $2" '$0 == w { f = 1 } END { print (f ? "line" : "none") }' "$1.err" 2>/dev/null)"
  if [ "$LF_RC" = 1 ] && [ ! -s "$1.out" ] && [ "$e" = line ]; then printf ended; else printf 'not ended'; fi
}

# -> the bash program of R3-F1's fault, for /bin/bash -c PROGRAM N CMD...: it closes every descriptor from 3 to 63 it
# inherited, so that CMD starts with 0, 1 and 2 alone whatever the suite holds open, sets the soft open-file limit to N
# (ulimit -S -n N; status 124 when it cannot), writes "limit <the soft limit it reads back>" to stderr, and execs CMD.
# The line is written by an external printf (env printf): a builtin's redirection needs bash to save the descriptor at
# 10 or above, which a limit of 10 or less refuses, leaving stdout on stderr. Given as _lf_run's CMD it is the shell that
# execs felix: _lf_run OUT DIR NOW TMPDIR=T /bin/bash -c "$(_lf_nfprog)" N "$FELIX" lane --tsv.
_lf_nfprog() {
  printf '%s' 'i=3; while [ "$i" -lt 64 ]; do eval "exec $i>&-"; i=$((i + 1)); done; ulimit -S -n "$0" || exit 124; env printf "limit %s\n" "$(ulimit -S -n)" >&2; exec "$@"'
}

# DIR N T -> an engine root at DIR (made when missing) whose harness/hooks/session-start is a bash script that exports
# TMPDIR T and CLAUDE_PLUGIN_ROOT $FROOT, then execs /bin/bash -c "$(_lf_nfprog)" N $FROOT/harness/hooks/session-start,
# so that _lf_start OUT DIR NOW SOURCE LF_LROOT runs the suite's hook under R3-F1's soft open-file limit N, set in the
# shell that execs it. Sets LF_LROOT, DIR's physical path; status 1 and LF_LROOT empty when it cannot be made.
_lf_lroot() {
  LF_LROOT=""
  [ -n "${2-}" ] && [ -n "${3-}" ] && mkdir -p "$1/harness/hooks" || return 1
  { printf '#!/bin/bash\n# R3-F1: the suite'"'"'s hook under a soft open-file limit of %s.\n' "$2"
    printf 'export TMPDIR=%q CLAUDE_PLUGIN_ROOT=%q\n' "$3" "$FROOT"
    printf 'exec /bin/bash -c %q %q %q\n' "$(_lf_nfprog)" "$2" "$FROOT/harness/hooks/session-start"; } > "$1/harness/hooks/session-start" \
    && chmod +x "$1/harness/hooks/session-start" || return 1
  LF_LROOT="$(cd -P -- "$1" && pwd -P)"
}

# Design item 46 (2026-10-30, still blind). MODE NAME WORDS STACK FILE TMPDIR CMD... -> CMD run as _lf_fork (MODE fork)
# or _lf_kill (MODE kill) runs it, NAME (tr or git; sed or head since the third review's round 1) the bash function
# exported into felix, acting every time " $* "
# matches the case pattern WORDS and " ${FUNCNAME[*]} " the case pattern STACK. It writes "fired" to FILE; then, S being
# the shell that called it, P that shell's parent and M the bash that runs it ($$ there: felix itself, for a function
# felix calls), fork writes "fork S M", lowers the soft process limit to 1 in that shell and runs NAME, then writes "ran
# <status>" if the shell gets there; kill writes "kill P S M" and sends SIGKILL to P, then S (never to pid 1 or this
# suite's shell: it writes "kept" and runs NAME). LF_RC as _lf_fault's; LF_FIRE "fired" when it acted as MODE says (fork:
# NAME did not run to a clean exit after it); LF_SELF "self" when it acted in felix's own shell (fork: S is M) or sent
# felix itself a kill (P or S is M), where C3 and C9 say felix ends (128 or 137), else "apart".
_lf_probe() {
  local m="$1" n="$2" w="$3" k="$4" f="$5" t="$6" c a b
  shift 6
  LF_FIRE="not run"; LF_SELF="not run"; LF_RC=125
  case "$f$t" in (*\"*|*\'*|*\$*|*\`*|*\\*|*\&*) return 1 ;; esac
  [ -n "$f" ] && [ -n "$t" ] && [ -n "$w" ] && [ -n "$k" ] || return 1
  case "$n" in (tr|git|sed|head) c="command $n" ;; (*) return 1 ;; esac
  case "$m" in
    (fork) a="printf 'fork %s %s\\n' \"\$s\" \"\$\$\" >> '$f'; ulimit -S -u 1; $c \"\$@\"; r=\$?; printf 'ran %s\\n' \"\$r\" >> '$f'; return \"\$r\"" ;;
    (kill) a="p=\"\$(ps -o ppid= -p \"\$s\" 2>/dev/null)\"; p=\"\${p//[!0123456789]/}\"
      case \"\$s:\$p\" in (:*|*:|1:*|*:1|$$:*|*:$$) printf 'kept %s %s\\n' \"\$p\" \"\$s\" >> '$f' ;;
        (*) printf 'kill %s %s %s\\n' \"\$p\" \"\$s\" \"\$\$\" >> '$f'; kill -KILL \"\$p\"; kill -KILL \"\$s\" ;; esac; $c \"\$@\"; return" ;;
    (*) return 1 ;;
  esac
  b="$n() { local s p r; case \" \$* \" in ($w) case \" \${FUNCNAME[*]} \" in ($k) printf 'fired\\n' >> '$f'
    s=\"\$(exec sh -c 'echo \$PPID')\"; $a ;; esac ;; esac; $c \"\$@\"; }"
  rm -f "$f" "$f.shell"
  { ( TMPDIR="$t"; export TMPDIR
      eval "$b" || exit 125
      export -f "$n"
      "$@"
      exit "$LF_RC" ); } 2> "$f.shell"
  LF_RC=$?
  LF_FIRE="$(LC_ALL=C awk -v m="$m" '$0 == "fired" { f = 1 } $0 == "ran 0" { r = 1 } /^kill [0123456789]+ [0123456789]+ [0123456789]+$/ { k = 1 }
    /^fork [0123456789]+ [0123456789]+$/ { o = 1 } /^kept / { p = $0 }
    END { s = "not fired"
      if (m == "fork" && f) s = (o && !r) ? "fired" : "fired, but it ran to a clean exit after it"
      if (m == "kill" && f) s = k ? "fired" : "fired, but no kill was sent [" p "]"
      print s }' "$f" 2>/dev/null)"
  LF_SELF="$(LC_ALL=C awk '($1 == "fork" && NF == 3 && $2 == $3) || ($1 == "kill" && NF == 4 && ($2 == $4 || $3 == $4)) { s = 1 }
    END { print (s ? "self" : "apart") }' "$f" 2>/dev/null)"
  [ -n "$LF_FIRE" ] || LF_FIRE="not fired"
  [ -n "$LF_SELF" ] || LF_SELF=apart
}

# Design item 46 (2026-10-30, still blind). OUT DIR -> what felix lane said of DIR's resolution (C5), in the run whose
# files are OUT.out and OUT.err, with status LF_RC: "unresolved" when it exited 2 with nothing on stdout and the first
# line of its stderr is exactly felix: the project that governs DIR could not be resolved: a read it stands on did not
# finish.; "ungoverned" when the same with the line felix: no project governs DIR.; else its status, stdout and the first
# line of its stderr.
_lf_said() {
  local e
  e="$(LC_ALL=C awk 'NR == 1' "$1.err" 2>/dev/null)"
  if [ "$LF_RC" = 2 ] && [ ! -s "$1.out" ]; then
    case "$e" in
      ("felix: the project that governs $2 could not be resolved: a read it stands on did not finish.") printf unresolved; return 0 ;;
      ("felix: no project governs $2.") printf ungoverned; return 0 ;;
    esac
  fi
  printf 'status %s, stdout [%s], stderr [%s]' "$LF_RC" "$(cat "$1.out" 2>/dev/null)" "$e"
}

# The third review's round 2 (2026-10-30, still blind). NOW HOME DIR SENT NAME WORDS STACK MODE... -> for each MODE,
# felix lane --tsv and then felix lane, run from DIR (below $TMP) at the clock NOW with the home HOME and the memory root
# DIR.mem, beside DIR and made empty before each run; LF_H and LF_M are as they were after. MODE none runs them as they
# are; MODE fork or kill with NAME sed, tr, git or head runs them under _lf_probe MODE NAME WORDS STACK, and MODE kill with
# NAME pwd under _lf_kill pwd WORDS STACK, each with a TMPDIR DIR.tmp of its own, made empty. LF_SAID gets, per run, "as
# C5 says" when it exited 2 with nothing on stdout and the first line of its stderr is SENT or, under a probe, C5's line
# felix: the project that governs DIR could not be resolved: a read it stands on did not finish.; else its status, its
# stdout and that line; "|" between runs. LF_SPOKE the same, each followed by " memory[<what ls -A lists in DIR.mem>]".
# Status 1, LF_SPOKE "not run", when DIR is not below $TMP or a MODE is not one of these.
_lf_spoke() {
  local t="$1" h="$2" d="$3" s="$4" n="$5" w="$6" k="$7" h0="${LF_H-}" m0="${LF_M-}" o x m f e v
  shift 7
  LF_SAID=""; LF_SPOKE="not run"
  x="$(cd -P -- "$TMP" 2>/dev/null && pwd -P)"
  case "$d" in ("$TMP"/?*|"${x:-$TMP}"/?*) ;; (*) return 1 ;; esac
  [ "$#" -gt 0 ] || return 1
  for m in "$@"; do case "$m:$n" in (none:*|fork:sed|fork:tr|fork:git|fork:head|kill:sed|kill:tr|kill:git|kill:head|kill:pwd) ;; (*) return 1 ;; esac; done
  LF_SPOKE=""; o="$d.run"; LF_H="$h"; LF_M="$d.mem"
  for m in "$@"; do
    for f in --tsv ""; do
      rm -rf "$d.mem" "$d.tmp" && mkdir -p "$d.mem" "$d.tmp" || { LF_H="$h0"; LF_M="$m0"; LF_SPOKE="not run"; return 1; }
      case "$m:$n" in
        (none:*) _lf_run "$o" "$d" "$t" "$FELIX" lane ${f:+"$f"} ;;
        (kill:pwd) _lf_kill pwd "$w" "$k" "$o.fired" "$d.tmp" _lf_run "$o" "$d" "$t" "$FELIX" lane ${f:+"$f"} ;;
        (*) _lf_probe "$m" "$n" "$w" "$k" "$o.fired" "$d.tmp" _lf_run "$o" "$d" "$t" "$FELIX" lane ${f:+"$f"} ;;
      esac
      e="$(LC_ALL=C awk 'NR == 1' "$o.err" 2>/dev/null)"
      v="status $LF_RC, stdout [$(cat "$o.out" 2>/dev/null)], stderr [$e]"
      if [ "$LF_RC" = 2 ] && [ ! -s "$o.out" ]; then
        if [ "$e" = "$s" ]; then v="as C5 says"
        elif [ "$m" != none ] && [ "$e" = "felix: the project that governs $d could not be resolved: a read it stands on did not finish." ]; then v="as C5 says"
        fi
      fi
      LF_SAID="$LF_SAID${LF_SAID:+|}$v"; LF_SPOKE="$LF_SPOKE${LF_SPOKE:+|}$v memory[$(ls -A "$d.mem" 2>&1)]"
    done
  done
  LF_H="$h0"; LF_M="$m0"
}
