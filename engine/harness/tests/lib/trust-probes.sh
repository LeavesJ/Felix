# The trust plane's step 1 (2026-10-31): the fixtures, the fault probes and the driver of the blind parts 2170 to 2174,
# written blind from the step's spec (.felix/memory/felix/audits/2026-10-31-trust-plane-replay/step1/spec.md, sections
# 0-8 and the merge-judge item), its properties 1-45 and the P2 case's layouts. Functions only (part 0006): nothing
# runs and nothing is assigned when this file is sourced. Every name is _trp_ or TRP_. The lane's builders and runner
# (lane-fixture.sh: _lf_dir, _lf_init, _lf_commit, _lf_origin, _lf_stubs, _lf_use, _lf_run) are called, never changed.
#
# The probes. _trp_new FILE starts a set; _trp_arm MODE NAME WORDS STACK [NOT] adds one bash function NAME (a command:
# tr git sed head cat ls od tail wc cut awk; or a builtin: pwd printf) that acts every time " $* " matches the case
# pattern WORDS and the calling functions match STACK and not NOT (each case code, quoted as the caller writes it), and
# writes "fired NAME" to FILE first. The calling functions are matched as ${FUNCNAME[@]} with a space on each side of
# every name, so "*' a '*' b '*" holds when b calls a directly too (one shared space would not). _trp_go CMD... runs CMD (_lf_run or _trp_drv with their arguments) in a subshell
# where each armed NAME is exported, so felix and the driver import it. The modes are the spec's fault families:
#   f1   exit 1, nothing printed          f127 exit 127, nothing printed     f2  killed: 137, nothing printed
#   f3   cannot fork: the soft process limit is lowered to 1 in the shell that called it and NAME is run, so its fork
#        fails (bash 3.2 ends that subshell with 128). In felix's own shell (or the driver's) it writes "self" and
#        returns 128 without lowering, so the rest of the run can still fork.
#   f3z  the substitution around the read could not fork: in a subshell, that subshell ends at once with status 0 and
#        nothing printed (detect.sh's case of felix_capture); in the calling program's own shell it does not act.
#   f4   prints the first half of NAME's real output (bytes), then exits 1    pN  the first N bytes, then exits 1
#   f5   exit 0, nothing printed
#   hS   prints the first half of NAME's real output (bytes), then exits S: a partial answer with one of the command's
#        finished statuses (h128 and h2 for git's fatal error and no such remote; review round 1, P47)
# TRP_FIRE is "fired" when every armed NAME acted (for f3, and the command did not then run to a clean exit), else what
# did not; LF_RC the subshell's status (CMD's LF_RC).
#
# The driver (_trp_driver writes it; _trp_drv runs it) sources the libraries one function needs from TRP_E/lib (or
# TRP_LIB), under set -u and, unless TRP_PF is off, -o pipefail (as P2's drive.sh and the CLI), calls that function and
# passes its stdout and status through. TRP_WRAP NAME (a function: felix_remote_github_slug, felix_repo_root,
# felix_resolve_project, felix_mem_root) is replaced after sourcing by a wrapper that acts as TRP_WMODE (f2, f3, f3z,
# f5) when " ${FUNCNAME[*]} " matches TRP_WSTACK (a pattern held in a variable: spaces literal, no quotes) and, when
# TRP_WARG1 is set, its first argument is TRP_WARG1; it writes "fired NAME" to TRP_WFILE first.

# FX NAME REMOTE_MATCH (or -) -> FX/felix-home/projects/NAME as P2's gen-resolve.sh writes it, gate "gate-NAME".
_trp_proj() {
  mkdir -p "$1/felix-home/projects/$2" || return 1
  if [ "$3" = - ]; then
    printf '{\n  "name": "%s",\n  "gate": "gate-%s"\n}\n' "$2" "$2" > "$1/felix-home/projects/$2/project.json"
  else
    printf '{\n  "name": "%s",\n  "remote_match": "%s",\n  "gate": "gate-%s"\n}\n' "$2" "$3" "$2" > "$1/felix-home/projects/$2/project.json"
  fi
  printf '# %s\n' "$2" > "$1/felix-home/projects/$2/CLAUDE.md"
}

# DIR LAYOUT -> P2's resolver layout under DIR (below $TMP), LAYOUT one of marker remote nest tie badmarker none slug,
# and three of this suite's: alphabet (the marker names alphabet, a project beside alpha), noorigin (remote, with no
# origin remote) and unread (marker, the marker's mode 000); and review round 1's half (P47: alpha's remote_match
# git.example.org/acme is the origin's first 28 bytes https://git.example.org/acme, beta's the origin's whole path
# git.example.org/acme/web-and-extras-and-more; clean, beta). TRP_FX DIR's physical path; TRP_H the home TRP_FX/felix-home;
# TRP_CO the checkout TRP_FX/co/res, its one commit at 1790000000, its marker untracked; TRP_S TRP_CO/sub/dir; TRP_M the
# memory root TRP_FX/memory; TRP_U a HOME TRP_FX/user; TRP_B the lane's stubs (_lf_stubs). _lf_use names them. Status 1
# and TRP_FX empty when it could not be built.
_trp_res() {
  local d="$1" l="$2" o="https://git.example.org/acme/web.git" mk="" fx
  TRP_FX=""; TRP_H=""; TRP_CO=""; TRP_S=""; TRP_M=""; TRP_U=""; TRP_B=""
  _lf_dir "$d" || return 1
  fx="$LF_DIR"
  mkdir -p "$fx/felix-home/projects" "$fx/memory" "$fx/user" "$fx/co/res/sub/dir" || return 1
  case "$l" in
    nest)  _trp_proj "$fx" alpha acme/web; _trp_proj "$fx" beta git.example.org/acme/web
           _trp_proj "$fx" gamma git.example.org/acme/web-extras ;;
    tie)   _trp_proj "$fx" alpha acme/web; _trp_proj "$fx" beta acme/web.git; _trp_proj "$fx" gamma other.example/thing ;;
    slug)  _trp_proj "$fx" alpha acme/web; _trp_proj "$fx" beta github.com/acme/web-extras; _trp_proj "$fx" gamma acme/we
           o="git@github.com:Acme/Web.git" ;;
    half)  _trp_proj "$fx" alpha git.example.org/acme; _trp_proj "$fx" beta git.example.org/acme/web-and-extras-and-more
           _trp_proj "$fx" gamma other.example/thing; o="https://git.example.org/acme/web-and-extras-and-more.git" ;;
    marker|remote|badmarker|none|alphabet|noorigin|unread)
           _trp_proj "$fx" alpha nomatch.example/alpha; _trp_proj "$fx" beta git.example.org/acme/web
           _trp_proj "$fx" gamma other.example/thing ;;
    *) return 1 ;;
  esac
  case "$l" in
    marker|unread) mk=alpha ;;
    badmarker) mk=nosuch ;;
    alphabet) mk=alphabet; _trp_proj "$fx" alphabet - ;;
    none) o="https://git.example.org/other/thing-else.git" ;;
    noorigin) o="" ;;
  esac
  _lf_init "$fx/co/res" || return 1
  printf 'resolver checkout\n' > "$fx/co/res/README"
  _lf_commit "$fx/co/res" 1790000000 $'base\n' "=README" || return 1
  [ -z "$o" ] || _lf_origin "$fx/co/res" "$o" || return 1
  [ -z "$mk" ] || printf '%s\n' "$mk" > "$fx/co/res/.felix"
  [ "$l" != unread ] || chmod 000 "$fx/co/res/.felix"
  _lf_stubs "$fx" || return 1
  mkdir -p "$fx/plain" || return 1
  _trp_at "$fx"
}

# FX -> TRP_FX FX (a physical path _trp_res built), TRP_H, TRP_CO, TRP_S, TRP_M, TRP_U and TRP_B as _trp_res names them,
# TRP_P FX/plain (a directory in no repository), and _lf_use names them. Status 1 when FX/co/res is missing.
_trp_at() {
  TRP_FX="$1"; TRP_H="$1/felix-home"; TRP_CO="$1/co/res"; TRP_S="$1/co/res/sub/dir"; TRP_M="$1/memory"
  TRP_U="$1/user"; TRP_B="$1/bin"; TRP_P="$1/plain"
  _lf_use "$TRP_H" "$TRP_M" "$TRP_U" "$TRP_B"
  [ -d "$1/co/res" ]
}

# DIR NAME... -> TRP_LIBC DIR/lib, a copy of the suite's engine lib/ ($FROOT/harness/lib) less each lib/NAME. Status 1 and
# TRP_LIBC empty when it could not be made, or a NAME is still there.
_trp_lib() {
  local d="$1" n
  shift
  TRP_LIBC=""
  mkdir -p "$d" && cp -R "$FROOT/harness/lib" "$d/lib" || return 1
  for n in "$@"; do rm -f "$d/lib/$n"; [ ! -e "$d/lib/$n" ] || return 1; done
  TRP_LIBC="$d/lib"
}

# VALUE ALTS -> "ok" when VALUE is one of ALTS (|-separated, each compared whole), else VALUE.
_trp_in() {
  local a r="$2|"
  while [ -n "$r" ]; do a="${r%%|*}"; r="${r#*|}"; [ "$1" != "$a" ] || { printf ok; return 0; }; done
  printf '%s' "$1"
}

# OUT -> "rc=<LF_RC> out=[<OUT.out byte for byte>]".
_trp_ro() { local o; o="$(cat "$1.out" 2>/dev/null; printf x)"; printf 'rc=%s out=[%s]' "$LF_RC" "${o%x}"; }

# DIR LAYOUT -> P2's table layout under DIR (below $TMP): TRP_FX/tables/schemas.tsv (t.tsv: name kind note?, emptiness
# refused; e.tsv: name kind, allowed) and the one file LAYOUT names, TRP_TF. LAYOUT is accepted cells empty-refused
# empty-allowed nul symlink shapes missing noschema, or this suite's finalnl (two good rows, the last with no newline)
# and encoding (a good row, then one holding the byte \377). TRP_TS the schemas file.
_trp_tab() {
  local t
  TRP_FX=""; TRP_TS=""; TRP_TF=""
  _lf_dir "$1" || return 1
  t="$LF_DIR/tables"; mkdir -p "$t" || return 1
  printf '# table\tlives\tcolumns\tempty\nt.tsv\ttree\tname kind note?\trefused\ne.tsv\ttree\tname kind\tallowed\n' > "$t/schemas.tsv"
  TRP_TF="$t/t.tsv"
  case "$2" in
    accepted)      printf '# name\tkind\tnote\n\nalpha\tx\nbeta\ty\ta note with a # inside\n' > "$TRP_TF" ;;
    cells)         printf 'alpha\tx\nlonely\nfour\ta\tb\tc\n' > "$TRP_TF" ;;
    empty-refused) printf '# nothing here\n' > "$TRP_TF" ;;
    empty-allowed) TRP_TF="$t/e.tsv"; printf '# nothing here\n' > "$TRP_TF" ;;
    nul)           printf 'alpha\tx\n#x\000y\n' > "$TRP_TF" ;;
    symlink)       printf 'alpha\tx\n' > "$t/real.tsv"; ln -s real.tsv "$TRP_TF" ;;
    shapes)        printf 'alpha\tx\n  # indented\n \t \n\303\251t\303\251\tx\ncr\tx\r\nd\t\tx\nbad\t\377\nomega\tz' > "$TRP_TF" ;;
    missing)       : ;;
    noschema)      TRP_TF="$t/q.tsv"; printf 'alpha\tx\n' > "$TRP_TF" ;;
    finalnl)       printf 'alpha\tx\nomega\tz' > "$TRP_TF" ;;
    encoding)      printf 'alpha\tx\nbad\t\377\n' > "$TRP_TF" ;;
    *) return 1 ;;
  esac
  TRP_TS="$t/schemas.tsv"; TRP_FX="$LF_DIR"
}

# FILE -> a new probe set whose probes write to FILE (no quote, dollar, backquote, backslash or ampersand in it).
_trp_new() {
  TRP_F="$1"; TRP_DEFS=""; TRP_NAMES=""; TRP_FIRE="not run"
  case "$1" in (*\"*|*\'*|*\$*|*\`*|*\\*|*\&*|'') TRP_F=""; return 1 ;; esac
  : > "$1"
}

# MODE NAME WORDS STACK [NOT] -> one probe added to the set (see the head of this file). Status 1 for a MODE or NAME
# it does not know, or no set.
_trp_arm() {
  local m="$1" n="$2" w="$3" k="$4" x="${5:-@@trp-never@@}" f="$TRP_F" c a s
  [ -n "$f" ] || return 1
  case "$n" in
    (pwd|printf) c="builtin $n" ;;
    (tr|git|sed|head|cat|ls|od|tail|wc|cut|awk) c="command $n" ;;
    (*) return 1 ;;
  esac
  s="_trps=\"\$(exec /bin/sh -c 'echo \$PPID')\""
  case "$m:$c" in
    (f1:*) a="builtin printf 'fired $n\\n' >> '$f'; return 1" ;;
    (f127:*) a="builtin printf 'fired $n\\n' >> '$f'; return 127" ;;
    (f2:*) a="builtin printf 'fired $n\\n' >> '$f'; return 137" ;;
    (f5:*) a="builtin printf 'fired $n\\n' >> '$f'; return 0" ;;
    (f3:command*) a="builtin printf 'fired $n\\n' >> '$f'; $s; if [ \"\$_trps\" = \"\$\$\" ]; then builtin printf 'self $n\\n' >> '$f'; return 128; fi
      ulimit -S -u 1; $c \"\$@\"; _trpr=\$?; builtin printf 'ran %s\\n' \"\$_trpr\" >> '$f'; return \"\$_trpr\"" ;;
    (f3:builtin*|f3z:*) a="$s; if [ \"\$_trps\" != \"\$\$\" ]; then builtin printf 'fired $n\\n' >> '$f'; exit 0; fi" ;;
    (f4:*) a="builtin printf 'fired $n\\n' >> '$f'; _trpo=\"\$($c \"\$@\"; builtin printf x)\"; _trpo=\"\${_trpo%x}\"; local LC_ALL=C
      builtin printf '%s' \"\${_trpo:0:\$((\${#_trpo} / 2))}\"; return 1" ;;
    (p[0-9]*:*) a="builtin printf 'fired $n\\n' >> '$f'; _trpo=\"\$($c \"\$@\"; builtin printf x)\"; _trpo=\"\${_trpo%x}\"; local LC_ALL=C
      builtin printf '%s' \"\${_trpo:0:${m#p}}\"; return 1" ;;
    (h[0-9]*:*) a="builtin printf 'fired $n\\n' >> '$f'; _trpo=\"\$($c \"\$@\"; builtin printf x)\"; _trpo=\"\${_trpo%x}\"; local LC_ALL=C
      builtin printf '%s' \"\${_trpo:0:\$((\${#_trpo} / 2))}\"; return ${m#h}" ;;
    (*) return 1 ;;
  esac
  TRP_DEFS="$TRP_DEFS
$n() { local _trps _trpr _trpo _trpk=' ' _trpn; case \" \$* \" in ($w) for _trpn in \"\${FUNCNAME[@]}\"; do _trpk=\"\$_trpk \$_trpn \"; done
  case \"\$_trpk\" in ($x) ;; ($k) $a ;; esac ;; esac; $c \"\$@\"; }"
  TRP_NAMES="$TRP_NAMES $n"
}

# CMD... -> CMD run in a subshell with the set's probes exported (see the head of this file). Sets LF_RC and TRP_FIRE.
_trp_go() {
  local n miss="" clean=""
  TRP_FIRE="not run"; LF_RC=125
  [ -n "$TRP_F" ] && [ -n "$TRP_NAMES" ] || return 1
  : > "$TRP_F" || return 1
  { ( eval "$TRP_DEFS" || exit 125
      # shellcheck disable=SC2086
      export -f $TRP_NAMES
      "$@"
      exit "$LF_RC" ); } 2> "$TRP_F.shell"
  LF_RC=$?
  for n in $TRP_NAMES; do
    LC_ALL=C grep -Fxq "fired $n" "$TRP_F" || miss="$miss $n"
  done
  ! LC_ALL=C grep -Fxq 'ran 0' "$TRP_F" || clean=1
  if [ -n "$miss" ]; then TRP_FIRE="not fired:$miss"
  elif [ -n "$clean" ]; then TRP_FIRE="fired, but the command ran to a clean exit after it"
  else TRP_FIRE=fired; fi
}

# FILE -> the driver, written to FILE and made executable; TRP_DRV its path.
_trp_driver() {
  TRP_DRV=""
  cat > "$1" <<'TRPDRIVER' || return 1
#!/bin/bash
# The step 1 parts' driver (tests/lib/trust-probes.sh): MODE ARGS..., one engine function, its stdout and status.
set -u
[ "${TRP_PF:-on}" = off ] || set -o pipefail
L="${TRP_LIB:-${TRP_E:?}/lib}"
_trp_m="${1:-}"; shift
_trp_sub() { [ "$(exec /bin/sh -c 'echo $PPID')" != "$$" ]; }
_trp_hit() { builtin printf 'fired %s\n' "$TRP_WRAP" >> "$TRP_WFILE"; }
_trp_act() {
  local _trpw
  case " ${FUNCNAME[*]} " in ($TRP_WSTACK) ;; (*) _trp_real "$@"; return ;; esac
  [ -z "${TRP_WARG1:-}" ] || [ "${1-}" = "$TRP_WARG1" ] || { _trp_real "$@"; return; }
  case "$TRP_WMODE" in
    f2)  _trp_sub || { _trp_real "$@"; return; }; _trp_hit; exit 137 ;;
    f3z) _trp_sub || { _trp_real "$@"; return; }; _trp_hit; exit 0 ;;
    f3)  _trp_sub || { _trp_real "$@"; return; }; _trp_hit; ulimit -S -u 1; _trp_real "$@"; _trpw=$?
         builtin printf 'ran %s\n' "$_trpw" >> "$TRP_WFILE"; return "$_trpw" ;;
    f5)  _trp_hit; return 0 ;;
  esac
  _trp_real "$@"
}
_trp_wrap() {
  local d
  [ -n "${TRP_WRAP:-}" ] || return 0
  d="$(declare -f "$TRP_WRAP")" || exit 125
  eval "_trp_real${d#"$TRP_WRAP"}"
  eval "$TRP_WRAP() { _trp_act \"\$@\"; }"
}
case "$_trp_m" in
  resolve)
    . "$L/resolve.sh" || exit 125
    [ -z "${TRP_OWN:-}" ] || . "$L/own.sh" || exit 125
    _trp_wrap
    felix_resolve_project "$@"; _trp_r=$?
    if declare -F felix_capture >/dev/null; then _trp_c=defined; else _trp_c=undefined; fi
    [ -z "${TRP_CAPF:-}" ] || builtin printf '%s\n' "$_trp_c" > "$TRP_CAPF"
    exit "$_trp_r" ;;
  root)    . "$L/resolve.sh" || exit 125; _trp_wrap; felix_repo_root "$@"; exit $? ;;
  rr)      . "$L/resolve.sh" || exit 125; _trp_wrap
           _felix_resolve_remote "$@"; _trp_r=$?
           builtin printf 'rc=%s p=[%s] tie=[%s]\n' "$_trp_r" "${_FELIX_RB_P-unset}" "${_FELIX_RB_TIE-unset}"; exit 0 ;;
  slug)    . "$L/resolve.sh" || exit 125; . "$L/own.sh" || exit 125; _trp_wrap
           _felix_remote_slug "$1"; _trp_r=$?
           builtin printf 'rc=%s rs=[%s]\n' "$_trp_r" "${_FELIX_RS-unset}"; exit 0 ;;
  ghslug)  . "$L/resolve.sh" || exit 125; . "$L/own.sh" || exit 125; felix_remote_github_slug "$@"; exit $? ;;
  broken)  . "$L/resolve.sh" || exit 125; _trp_wrap; felix_binding_broken "$@"; exit $? ;;
  hookdir) . "$L/resolve.sh" || exit 125; _trp_wrap; felix_hook_dir "$@"; exit $? ;;
  table)   . "$L/table.sh" || exit 125; felix_table_check "$@"; exit $? ;;
  tabempty) . "$L/table.sh" || exit 125; FELIX_TABLE_UTF8=; felix_table_check "$@"; exit $? ;;
  judge)   . "$L/resolve.sh" >/dev/null 2>&1; declare -F felix_accepted_deploy_diff >/dev/null || exit 3
           felix_accepted_deploy_diff "$@"; exit $? ;;
esac
exit 125
TRPDRIVER
  chmod +x "$1" || return 1
  TRP_DRV="$1"
}

# OUT DIR MODE ARGS... -> the driver (TRP_DRV) run from DIR in the environment _lf_use named, as _lf_run runs a surface:
# FELIX_HOME LF_H (unset when TRP_NOHOME is 1), FELIX_MEMORY LF_M (unset when TRP_NOMEM is 1), HOME LF_U, LF_B first on
# PATH, LANGUAGE=en, TZ=UTC, GIT_CONFIG_NOSYSTEM=1, TRP_E the suite's engine copy. Stdout in OUT.out, stderr OUT.err,
# the status in LF_RC (125 when DIR could not be entered).
_trp_drv() {
  local o="$1" d="$2"
  shift 2
  ( _fx_cd "$d" || exit 125
    if [ "${TRP_NOHOME:-0}" = 1 ] || [ -z "${LF_H-}" ]; then unset FELIX_HOME; else export FELIX_HOME="$LF_H"; fi
    if [ "${TRP_NOMEM:-0}" = 1 ] || [ -z "${LF_M-}" ]; then unset FELIX_MEMORY; else export FELIX_MEMORY="$LF_M"; fi
    exec env -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR -u CLAUDE_CONFIG_DIR HOME="${LF_U:-$HOME}" PATH="${LF_B:+$LF_B:}$PATH" \
      LANGUAGE=en TZ=UTC GIT_CONFIG_NOSYSTEM=1 TRP_E="${TRP_E:-$FROOT/harness}" /bin/bash "$TRP_DRV" "$@" ) \
    > "$o.out" 2> "$o.err" < /dev/null
  LF_RC=$?
}

# OUT -> what the run whose files are OUT.out and OUT.err, with status LF_RC, gives as P2's resolve surface: found:PATH
# (0, the path), none (1, nothing printed), unknown (2, nothing printed), else its status and stdout.
_trp_rcls() {
  local o
  o="$(cat "$1.out" 2>/dev/null; printf x)"; o="${o%x}"
  case "$LF_RC:$o" in
    (0:?*) printf 'found:%s' "$o" ;;
    (1:) printf none ;;
    (2:) printf unknown ;;
    (*) printf 'status %s, stdout [%s]' "$LF_RC" "$o" ;;
  esac
}

# OUT DIR -> what a felix which (or any resolve_or_die command) run from DIR said: found:P (0, the five lines, P the
# project line's name), unknown (exit 2, nothing on stdout, a line of stderr exactly felix: the project that governs
# DIR could not be resolved: a read it stands on did not finish.), broken, none (exit 2, nothing on stdout, stderr
# matching P2's ERE for that class), else its status, stdout and stderr's first line. RC, when given, is the exit the
# three refusals must have (2 when not).
_trp_wcls() {
  local o="$1" d="$2" rc="${3:-2}" n
  n="$(LC_ALL=C awk 'END { print NR }' "$o.out" 2>/dev/null)"
  if [ "$LF_RC" = 0 ] && [ "$n" = 5 ] && LC_ALL=C grep -q '^project:      ' "$o.out"; then
    printf 'found:%s' "$(LC_ALL=C sed -n '1s/^project: *//p' "$o.out")"; return 0
  fi
  if [ "$LF_RC" = "$rc" ] && [ ! -s "$o.out" ]; then
    if LC_ALL=C grep -Fxq "felix: the project that governs $d could not be resolved: a read it stands on did not finish." "$o.err"; then
      printf unknown; return 0
    fi
    if LC_ALL=C grep -Eq 'marker in .* (names|is empty)|fits .* equally well|home pointer at|no longer resolves' "$o.err"; then
      printf broken; return 0
    fi
    if LC_ALL=C grep -q 'no project governs' "$o.err"; then printf none; return 0; fi
  fi
  printf 'status %s, stdout [%s], stderr [%s]' "$LF_RC" "$(head -2 "$o.out" 2>/dev/null)" "$(LC_ALL=C awk 'NR == 1' "$o.err" 2>/dev/null)"
}

# OUT FILE -> what a felix_table_check run said of FILE: accepted (0, nothing), refused (1, one or more lines), unknown
# (2, exactly the one line FILE:- TAB cannot-examine TAB a read of the check's own did not finish), examine2 (2, any
# other output), else its status and output.
_trp_tcls() {
  local o
  o="$(cat "$1.out" 2>/dev/null; printf x)"; o="${o%x}"
  case "$LF_RC" in
    0) [ -n "$o" ] || { printf accepted; return 0; } ;;
    1) [ -z "$o" ] || { printf refused; return 0; } ;;
    2) if [ "$o" = "$2:-	cannot-examine	a read of the check's own did not finish
" ]; then printf unknown; else printf examine2; fi; return 0 ;;
  esac
  printf 'status %s, stdout [%s]' "$LF_RC" "$o"
}

# OUT -> OUT.out and OUT.err with the status, as one string, so two runs can be compared byte for byte.
_trp_whole() {
  local o e
  o="$(cat "$1.out" 2>/dev/null; printf x)"; e="$(cat "$1.err" 2>/dev/null; printf x)"
  printf 'rc=%s\nout=[%s]\nerr=[%s]' "$LF_RC" "${o%x}" "${e%x}"
}

# OUT ROW -> the line of OUT.out whose first tab field is ROW.
_trp_row() { LC_ALL=C awk -F'\t' -v r="$2" '$1 == r { print; exit }' "$1.out" 2>/dev/null; }

# OUT -> "rc=<LF_RC> out=[<OUT.out>] err=[<OUT.err>]" with every line of OUT.err that is bash's own note of a fork or a pipe
# it could not make (the probe's doing, not the engine's words) left out, so a faulted run compares with a clean one.
_trp_said() {
  local o e
  o="$(cat "$1.out" 2>/dev/null; printf x)"
  e="$(LC_ALL=C awk '/fork: |Resource temporarily unavailable|cannot make pipe/ { next } { print }' "$1.err" 2>/dev/null; printf x)"
  printf 'rc=%s out=[%s] err=[%s]' "$LF_RC" "${o%x}" "${e%x}"
}
