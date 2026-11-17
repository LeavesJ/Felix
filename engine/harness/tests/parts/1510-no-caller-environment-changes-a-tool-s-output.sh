printf '\nno caller environment changes what an engine tool prints\n'
# Measured 2026-10-08 on macOS (bash 3.2.57, BSD grep 2.6.0-FreeBSD, bsdtar
# 3.5.3): eight variables a caller can export change what the tools the engine
# reads as data print, and nothing under engine/harness removed them.
# GREP_OPTIONS=-n put `1:` in front of every row felix doctor, evidence, probes
# and commission --status read out of a table, so doctor listed `1:ci 2:tests`
# and evidence lost its gap. POSIXLY_CORRECT starts bash 3.2 in posix mode,
# where the `<( )` in lib/detect.sh, lib/adopt.sh and lib/discover.sh is a
# syntax error. CDPATH makes `$(cd engine/harness && pwd)` capture the
# directory twice, so the CLI run by a relative path cannot find its own
# libraries. CLICOLOR_FORCE, GH_FORCE_TTY and TAPE were measured doing the
# same kind of thing to ls, gh and tar; TAR_OPTIONS and QUOTING_STYLE are
# documented to, for GNU tar and GNU ls, and were not. The rule pinned here:
# every executable file under the engine unsets all eight as its first command
# other than `set`, so nothing an entry point starts is given any of them.
#
# GNU grep has ignored GREP_OPTIONS since 3.6, and a bash newer than 3.2 need
# not refuse `<( )` in posix mode (not measured here), so on the Linux runner
# the engine's own tools need not show either effect, and a comparison of a
# run with the variable against one without can pass there against an engine
# that keeps no rule at all. So each part below
# has at least one assertion that is red on any host while the rule is not
# kept: a grep first on PATH that honours GREP_OPTIONS as BSD grep does, by
# putting it in front of its own arguments; a record, written by every shim
# and by `envrec`, a command the fixture's gate, probe and commissioning rows
# run, of which of the eight reached its environment; and the rule itself,
# read from the text. The plain comparisons stay as well: they are what a
# person on a Mac sees.
#
# The record reads the environment awk was given (ENVIRON), not a shell
# variable: /bin/sh on macOS is bash in posix mode and sets POSIXLY_CORRECT=y
# for itself without exporting it, so a shim that asked its own shell would
# report that name on every host whatever the engine did. Every run "without"
# a variable unsets all eight first, so a person who has one exported does not
# change what this block compares against, and every run has the shims first
# on PATH, so the two sides of a comparison differ in the one variable alone.
# The fixture is a project of its own, nce, so nothing an earlier block left in
# widget's tables enters the comparison.
NCE="$TMP/nce"; NCP="$FROOT/projects/nce"
_nce_names='GREP_OPTIONS CLICOLOR_FORCE GH_FORCE_TTY TAPE TAR_OPTIONS QUOTING_STYLE POSIXLY_CORRECT CDPATH'
mkdir -p "$NCE/bin" "$NCE/repo/src" "$NCE/top/engine" "$NCE/decoy/engine/harness/bin" "$NCP" "$MEM/nce"
_nce_awk="$(command -v awk)"
_nce_prog='BEGIN { r = t ":"; n = split(v, a, " "); for (i = 1; i <= n; i++) if (a[i] in ENVIRON) r = r " " a[i]; print r >> f }'
printf "#!/bin/sh\n'%s' -v t=\"\$1\" -v f='%s' -v v='%s' '%s'\n" "$_nce_awk" "$NCE/rec" "$_nce_names" "$_nce_prog" \
  > "$NCE/bin/envrec"
for _nce_t in grep sed awk ls git tar gh sort head tr cut wc find; do
  _nce_real="$(command -v "$_nce_t" 2>/dev/null)" || continue
  case "$_nce_real" in /*) ;; *) continue ;; esac
  { printf "#!/bin/sh\n'%s' -v t='%s' -v f='%s' -v v='%s' '%s'\n" "$_nce_awk" "$_nce_t" "$NCE/tools" "$_nce_names" "$_nce_prog"
    case "$_nce_t" in
      grep) printf '%s\n' 'o="${GREP_OPTIONS-}"; unset GREP_OPTIONS'
            printf "exec '%s' \$o \"\$@\"\n" "$_nce_real" ;;
      *)    printf "exec '%s' \"\$@\"\n" "$_nce_real" ;;
    esac; } > "$NCE/bin/$_nce_t"
done
chmod +x "$NCE/bin"/*
printf '{\n  "name": "nce",\n  "remote_match": "example.com/nce",\n  "gate": "envrec gate && echo nce-gate-ran"\n}\n' \
  > "$NCP/project.json"
printf '# nce\n' > "$NCP/CLAUDE.md"
printf 'ci\ntests\n' > "$NCP/capabilities"
printf 'code\t^src/\t^tests/\tbehaviour needs a test\ndocs\t^docs/\t^docs/\tdocs prove themselves\n' > "$NCP/evidence.tsv"
printf 'env\t-\t-\tenvrec probe; ls -1 .felix\ttest -f .felix\n' > "$NCP/probes.tsv"
printf 'env\t-\t-\t-\t-\tenvrec commission; test -f .felix\t9\n' > "$NCP/commissioning.tsv"
printf 'Bash\tgit add (-A|--all|\\.)$\tstage explicit paths; -A stages what you did not read\n' > "$NCP/deny.tsv"
( _fx_cd "$NCE/repo" && git init -q -b main && printf 'nce\n' > .felix && printf 'x = 1\n' > src/a.py \
  && git add .felix src/a.py && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
printf 'x = 2\n' > "$NCE/repo/src/a.py"
# A checkout's top with an engine of its own, for the relative runs, and a
# second directory holding an engine/harness/ of its own (empty) for CDPATH to
# name after `.`.
cp -R "$FROOT/harness" "$NCE/top/engine/harness"; printf 'nce\n' > "$NCE/top/.felix"

_nce_run() {   # <dir> <command...>: its stdout and stderr, then `exit N`, with none of the eight set
  ( unset $_nce_names; cd "$1" || exit 1; shift
    PATH="$NCE/bin:$PATH" "$@" 2>&1; printf 'exit %s\n' "$?" )
}
_nce_all() {   # <dir> <command...>: with all eight exported, output dropped
  ( cd "$1" || exit 1; shift
    env GREP_OPTIONS=-n CLICOLOR_FORCE=1 GH_FORCE_TTY=1 TAPE="$NCE/no-tape" TAR_OPTIONS=-v \
        QUOTING_STYLE=c POSIXLY_CORRECT=1 CDPATH=".:$NCE/decoy" PATH="$NCE/bin:$PATH" "$@" ) >/dev/null 2>&1
}
# Equal to the run without the variable, and that run did what it was asked:
# two runs that both failed are equal too, and would read as a pass. A
# difference is shown as the head of a diff, without first and with second.
_nce_same() {   # <name> <with> <without> <what the run without must say>
  case "$3" in
    *"$4"*) if [ "$2" = "$3" ]; then ok "$1"
            else bad "$1" "$(diff <(printf '%s\n' "$3") <(printf '%s\n' "$2") | head -12)"; fi ;;
    *) bad "$1" "the run without the variable never said [$4], so this compares nothing: [$3]" ;;
  esac
}
# A record's lines that name one of the eight, or a line saying nothing was
# recorded: a record no tool wrote proves nothing about what tools are given.
_nce_dirty() {   # <record file>
  if [ -s "$1" ]; then awk -F: '$2 != "" { print }' "$1" | LC_ALL=C sort -u
  else printf 'nothing was recorded'; fi
}

# O1. A command whose output comes from grep over a table. Against an engine
# that keeps no rule, doctor's declared line read `1:ci 2:tests`, evidence
# named its rule `1:code`, found no change under it and said "No evidence
# gaps.", and commission --status numbered every row, surface and question.
_nce_g0="$(_nce_run "$NCE/repo" "$FELIX" doctor)"
_nce_g1="$(_nce_run "$NCE/repo" env GREP_OPTIONS=-n "$FELIX" doctor)"
is "with GREP_OPTIONS=-n exported, felix doctor lists the declared capabilities by name, or each one it reads out of the capabilities table carries a line number" \
   "$(printf '%s\n' "$_nce_g1" | awk '$1 == "declared:" { for (i = 2; i <= NF; i++) printf "%s ", $i }')" "ci tests "
_nce_same "and felix doctor prints what it prints without GREP_OPTIONS" "$_nce_g1" "$_nce_g0" "project:      nce"
_nce_g0="$(_nce_run "$NCE/repo" "$FELIX" evidence)"
_nce_g1="$(_nce_run "$NCE/repo" env GREP_OPTIONS=-n "$FELIX" evidence)"
_nce_same "with GREP_OPTIONS=-n exported, felix evidence names its rules and finds the gap it finds without it, or a rule reads as 1:code and the gap goes unreported" \
   "$_nce_g1" "$_nce_g0" "behaviour needs a test"
_nce_g0="$(_nce_run "$NCE/repo" "$FELIX" commission --status)"
_nce_g1="$(_nce_run "$NCE/repo" env GREP_OPTIONS=-n "$FELIX" commission --status)"
_nce_same "with GREP_OPTIONS=-n exported, felix commission --status prints what it prints without it, or every row and surface it lists carries a line number" \
   "$_nce_g1" "$_nce_g0" "the check passes"

# O2. bash 3.2 in posix mode refuses `<( )`, and every bash the CLI starts
# would begin in posix mode as well. The first two are red on a Mac; the
# record is red on any host.
_nce_p0="$(_nce_run "$NCE/repo" "$FELIX" which)"
: > "$NCE/tools"
_nce_p1="$(_nce_run "$NCE/repo" env POSIXLY_CORRECT=1 "$FELIX" which)"
case "$_nce_p1" in
  *'syntax error'*) bad "with POSIXLY_CORRECT=1 exported, felix which exits 0 with no syntax error, or bash 3.2 reads the libraries in posix mode and refuses their <( )" "$_nce_p1" ;;
  *) is "with POSIXLY_CORRECT=1 exported, felix which exits 0 with no syntax error, or bash 3.2 reads the libraries in posix mode and refuses their <( )" "${_nce_p1##*exit }" "0" ;;
esac
_nce_same "and felix which prints what it prints without POSIXLY_CORRECT" "$_nce_p1" "$_nce_p0" "project:      nce"
is "and no tool felix which starts is given POSIXLY_CORRECT, or every bash it starts begins in posix mode too" \
   "$(_nce_dirty "$NCE/tools")" ""

# O3. Run by a relative path from the checkout's top. `.` comes first in
# CDPATH, so cd finds the checkout's own engine through it and prints the
# directory into what $( ) captures: the CLI then sources lib/resolve.sh from
# a path holding a newline, and handoff-check exits 127 where it exited 2.
_nce_c0="$(_nce_run "$NCE/top" engine/harness/felix which)"
_nce_c1="$(_nce_run "$NCE/top" env CDPATH=".:$NCE/decoy" engine/harness/felix which)"
_nce_same "with CDPATH naming . and another engine, engine/harness/felix which run from the checkout's top resolves its libraries and prints what it prints without CDPATH, or cd prints the directory into the path it captures" \
   "$_nce_c1" "$_nce_c0" "project:      nce"
_nce_c0="$(_nce_run "$NCE/top" engine/harness/bin/handoff-check)"
_nce_c1="$(_nce_run "$NCE/top" env CDPATH=".:$NCE/decoy" engine/harness/bin/handoff-check)"
_nce_same "and so does engine/harness/bin/handoff-check run the same way" "$_nce_c1" "$_nce_c0" "no HANDOFF.md"

# O4. All eight exported at once. What runs inside a `bash -c` the engine
# starts writes its own line into rec; every tool shim writes into tools. The
# gate leaves a receipt under the home's state/gate, named for the checkout;
# the names there now are kept, so the one this block adds can be removed.
# Listed by a glob, not ls, which a caller's CLICOLOR_FORCE would colour.
_nce_gates="$(cd "$FROOT/state/gate" 2>/dev/null && printf '%s\n' *)"
: > "$NCE/rec"; : > "$NCE/tools"
_nce_all "$NCE/repo" "$FELIX" gate
_nce_all "$NCE/repo" "$FELIX" probes
_nce_all "$NCE/repo" "$FELIX" commission --status
_nce_all "$NCE/repo" "$FELIX" doctor
is "with all eight exported, the gate felix gate starts in a bash -c is given none of them" \
   "$(awk -F: '$1 == "gate"' "$NCE/rec" | LC_ALL=C sort -u)" "gate:"
is "and so is a probe felix probes starts in a bash -c" \
   "$(awk -F: '$1 == "probe"' "$NCE/rec" | LC_ALL=C sort -u)" "probe:"
is "and so is a commissioning check felix commission --status runs" \
   "$(awk -F: '$1 == "commission"' "$NCE/rec" | LC_ALL=C sort -u)" "commission:"
is "and no tool felix gate, probes, commission --status or doctor starts is given any of them, or grep, ls, gh and tar print what the caller asked for rather than what the engine reads" \
   "$(_nce_dirty "$NCE/tools")" ""
_nce_pay='{"tool_name":"Bash","tool_input":{"command":"git add -A"}}'
: > "$NCE/tools"
_nce_all "$NCE/repo" "$FROOT/harness/hooks/pre-tool" <<<"$_nce_pay"
is "and no tool the pre-tool hook starts is given any of them" "$(_nce_dirty "$NCE/tools")" ""
: > "$NCE/tools"
_nce_all "$NCE/repo" "$FROOT/harness/bin/handoff-check"
is "and no tool a bin script, handoff-check, starts is given any of them" "$(_nce_dirty "$NCE/tools")" ""

# O5. A hook. On its way to a refusal pre-tool starts awk, cut, head, sed and
# tr and no grep (measured against an engine that keeps no rule), so its exit
# and text hold there; the record is what shows GREP_OPTIONS reaching what it
# starts.
_nce_d0="$(_nce_run "$NCE/repo" "$FROOT/harness/hooks/pre-tool" <<<"$_nce_pay")"
: > "$NCE/tools"
_nce_d1="$(_nce_run "$NCE/repo" env GREP_OPTIONS=-n "$FROOT/harness/hooks/pre-tool" <<<"$_nce_pay")"
is "with GREP_OPTIONS=-n exported, pre-tool still refuses a command its deny rows refuse, with exit 2" "${_nce_d1##*exit }" "2"
_nce_same "and its refusal text is the text it gives without GREP_OPTIONS" "$_nce_d1" "$_nce_d0" "stage explicit paths"
is "and no tool pre-tool starts is given GREP_OPTIONS" "$(_nce_dirty "$NCE/tools")" ""

# O6. The rule, read from the text of every regular file under the engine
# with the user-execute bit, so a file added later is read too. Read from the
# copy under test, which holds what git tracks and what it would add, and not
# what it ignores. A file's first command is its first line that is not blank,
# a comment or a `set`, with continuation lines joined and `;` splitting one
# line into commands; it must be `unset` naming all eight, in any order.
#
# Amended after review, not blind (2026-10-08): the adversarial review found
# that lib/where.sh reads the caller's CDPATH as the session's, and that an
# exported SHELLOPTS hands the entry point's own options to every child. So
# the rule became the block engine/harness/felix carries, in which a
# `set +o`, an `export -n SHELLOPTS BASHOPTS` and one unexported record of the
# caller's CDPATH come before the unset. The reader skips exactly those two
# besides `set`, and the assertions after this block pin the whole block.
_nce_first() {   # <file>: its first command other than set, whitespace folded
  awk '
    /^[ \t]*(#|$)/ { next }
    { line = $0
      while (line ~ /\\$/ && (getline more) > 0) { sub(/\\$/, " ", line); line = line more }
      n = split(line, part, ";")
      for (i = 1; i <= n; i++) {
        c = part[i]; sub(/[ \t]+#.*$/, "", c); gsub(/[ \t]+/, " ", c); sub(/^ /, "", c); sub(/ $/, "", c)
        if (c == "" || c ~ /^set( |$)/ || c == "export -n SHELLOPTS BASHOPTS" \
            || c == "_FELIX_CALLER_CDPATH=\"${CDPATH-}\"") continue
        print c; exit
      } }' "$1"
}
_nce_off=""; _nce_s1=""; _nce_s2=""; _nce_s3=""; _nce_s4=""
while IFS= read -r _nce_f; do
  [ -n "$_nce_f" ] || continue
  case "$_nce_f" in
    ./felix) _nce_s1=felix ;; ./hooks/*) _nce_s2=hooks ;; ./bin/*) _nce_s3=bin ;; ./tests/run) _nce_s4=tests/run ;;
  esac
  _nce_c="$(_nce_first "$FROOT/harness/$_nce_f")"; _nce_miss=""
  case "$_nce_c" in
    "unset -f"*) _nce_miss=" it unsets functions: $_nce_c" ;;
    unset\ *) for _nce_n in $_nce_names; do
                case " $_nce_c " in *" $_nce_n "*) ;; *) _nce_miss="$_nce_miss $_nce_n" ;; esac
              done ;;
    *) _nce_miss=" its first command is: $_nce_c" ;;
  esac
  [ -z "$_nce_miss" ] || _nce_off="$_nce_off[${_nce_f#./}:$_nce_miss] "
done <<<"$(cd "$FROOT/harness" && find . -type f -perm -u+x | LC_ALL=C sort)"
is "every executable file under the engine unsets all eight caller variables as its first command other than set, or one of them reaches a path resolution, a source or a tool before anything removes it" \
   "$_nce_off" ""
is "and that reading reached the CLI, the hooks, the bin scripts and the suite, so it cannot pass by reading nothing" \
   "$_nce_s1 $_nce_s2 $_nce_s3 $_nce_s4" "felix hooks bin tests/run"

# Added after review, not blind (2026-10-08). The adversarial review of the
# first fix (dc27380c) found what the contract above left unsaid, and the
# lines below pin it. Each comment says what it was red against.
#
# The block. Every executable file carries, after its own set, the lines
# engine/harness/felix carries: a `set +o` of the options a caller's SHELLOPTS
# can turn on that change what a command does, `export -n SHELLOPTS
# BASHOPTS`, an unexported record of the caller's CDPATH, and one unset of all
# sixteen names. Read with continuation lines joined and blanks folded, so a
# copy that differs only in layout reads the same.
_nce_blk() {   # <file>: the commands after its first `set -u`, through the end of its unset
  awk 'on && /^[[:space:]]*(#|$)/ { next }
       on { l = $0; while (l ~ /\\$/ && (getline more) > 0) { sub(/\\$/, " ", l); l = l more }
            gsub(/[ \t]+/, " ", l); sub(/^ /, "", l); sub(/ $/, "", l); print l
            if (l ~ /^unset / || ++n >= 8) exit; next }
       NR > 1 && /^[[:space:]]*set -u/ { on = 1 }' "$1"
}
_nce_cli="$(_nce_blk "$FROOT/harness/felix")"; _nce_lack=""
for _nce_w in 'set +o allexport +o errexit +o keyword +o noclobber +o noglob +o physical' \
              'export -n SHELLOPTS BASHOPTS' '_FELIX_CALLER_CDPATH="${CDPATH-}"'; do
  case "
$_nce_cli
" in *"
$_nce_w
"*) ;; *) _nce_lack="$_nce_lack[$_nce_w] " ;; esac
done
_nce_u="$(printf '%s\n' "$_nce_cli" | awk '/^unset /')"
for _nce_n in $_nce_names TAR_READER_OPTIONS GIT_EXTERNAL_DIFF GIT_DIFF_OPTS GIT_LITERAL_PATHSPECS \
              GIT_GLOB_PATHSPECS GIT_NOGLOB_PATHSPECS GIT_ICASE_PATHSPECS TMOUT; do
  case " $_nce_u " in *" $_nce_n "*) ;; *) _nce_lack="$_nce_lack[$_nce_n] " ;; esac
done
is "engine/harness/felix turns off the options a caller's SHELLOPTS can turn on, stops exporting SHELLOPTS and BASHOPTS, records the caller's CDPATH unexported and unsets all sixteen names, or one of them reaches what the engine runs" \
   "$_nce_lack" ""
_nce_off=""
while IFS= read -r _nce_f; do
  [ -n "$_nce_f" ] || continue
  [ "$(_nce_blk "$FROOT/harness/$_nce_f")" = "$_nce_cli" ] || _nce_off="$_nce_off${_nce_f#./} "
done <<<"$(cd "$FROOT/harness" && find . -type f -perm -u+x | LC_ALL=C sort)"
is "and every other executable file under the engine begins with the same block, or one entry point keeps something the CLI removes" \
   "$_nce_off" ""

# The caller's CDPATH is a fact about the session. lib/where.sh judges where a
# session's command runs, and the session runs it under the caller's CDPATH.
# The first fix removed CDPATH before anything recorded it, so pre-tool let
# `cd gov && git add -A` through a row scoped to the checkout when that
# CDPATH takes `cd gov` into the governed checkout (red against dc27380c;
# main refused it, since it never removed CDPATH).
_nce_sc="$NCE/sc"; mkdir -p "$_nce_sc/gov" "$NCE/scr/plain/gov"
( _fx_cd "$_nce_sc/gov" && git init -q -b main && printf 'nce\n' > .felix && git add .felix \
  && git -c user.name=t -c user.email=t@t commit -qm init \
  && git remote add origin https://example.com/nce.git ) >/dev/null 2>&1
( _fx_cd "$NCE/scr/plain/gov" && git init -q -b main ) >/dev/null 2>&1
cp "$NCP/deny.tsv" "$NCE/deny.keep"
printf 'Bash\tgit add ([^;&|]* )?(-A|--all|\\.)( |$)\tstage explicit paths\tcheckout\n' > "$NCP/deny.tsv"
_nce_sp="$(printf '{"session_id":"nce-scoped","cwd":"%s","tool_name":"Bash","tool_input":{"command":"cd gov && git add -A && git commit -qm x"}}' "$NCE/scr/plain")"
_nce_s0="$(_nce_run "$_nce_sc/gov" "$FROOT/harness/hooks/pre-tool" <<<"$_nce_sp")"
_nce_s1="$(_nce_run "$_nce_sc/gov" env CDPATH="$_nce_sc" "$FROOT/harness/hooks/pre-tool" <<<"$_nce_sp")"
is "pre-tool lets a checkout-scoped row pass cd gov && git add -A from a directory whose own gov is not the checkout" \
   "${_nce_s0##*exit }" "0"
is "and with the caller's CDPATH taking that cd gov into the governed checkout it refuses it, or removing CDPATH blinds the hook to where the session's command runs" \
   "${_nce_s1##*exit }" "2"
cp "$NCE/deny.keep" "$NCP/deny.tsv"

# An exported SHELLOPTS turns its options on before an entry point's first
# line, and stays exported, so the entry point's own set -uo pipefail reached
# every child bash, among them checks written to run without pipefail. Both
# red against main and dc27380c. The other names are the ones the review and
# peer sessions measured: TAR_READER_OPTIONS hands bsdtar options,
# GIT_EXTERNAL_DIFF and GIT_DIFF_OPTS change what git diff prints, the four
# GIT_*_PATHSPECS change what a pathspec matches, and TMOUT gives every read
# a timeout. BASHOPTS is checkhash and TMOUT is long, so neither changes what
# runs; the record is what shows them arriving.
_nce_o0="$(_nce_run "$NCE/repo" "$FELIX" doctor)"
_nce_o1="$(_nce_run "$NCE/repo" env SHELLOPTS=errexit "$FELIX" doctor)"
_nce_same "with SHELLOPTS=errexit exported, felix doctor prints what it prints without it and exits as it does, or the first command that returns non-zero ends it" \
   "$_nce_o1" "$_nce_o0" "declared:"
_nce_names2='SHELLOPTS BASHOPTS TAR_READER_OPTIONS GIT_EXTERNAL_DIFF GIT_DIFF_OPTS GIT_LITERAL_PATHSPECS GIT_GLOB_PATHSPECS GIT_NOGLOB_PATHSPECS GIT_ICASE_PATHSPECS TMOUT'
printf "#!/bin/sh\n'%s' -v t=\"\$1\" -v f='%s' -v v='%s' '%s'\n" "$_nce_awk" "$NCE/rec2" "$_nce_names2" "$_nce_prog" \
  > "$NCE/bin/envrec"
for _nce_t in grep sed awk ls git tar gh sort head tr cut wc find; do
  _nce_real="$(command -v "$_nce_t" 2>/dev/null)" || continue
  case "$_nce_real" in "$NCE"/*) _nce_real="$(PATH="${PATH#"$NCE/bin:"}" command -v "$_nce_t")" ;; esac
  case "$_nce_real" in /*) ;; *) continue ;; esac
  printf "#!/bin/sh\n'%s' -v t='%s' -v f='%s' -v v='%s' '%s'\nexec '%s' \"\$@\"\n" \
    "$_nce_awk" "$_nce_t" "$NCE/tools2" "$_nce_names2" "$_nce_prog" "$_nce_real" > "$NCE/bin/$_nce_t"
done
: > "$NCE/rec2"; : > "$NCE/tools2"
for _nce_c in gate probes "commission --status"; do
  ( cd "$NCE/repo" && env SHELLOPTS=noglob BASHOPTS=checkhash TAR_READER_OPTIONS=x GIT_EXTERNAL_DIFF=true \
      GIT_DIFF_OPTS=-u0 GIT_LITERAL_PATHSPECS=1 GIT_GLOB_PATHSPECS=1 GIT_NOGLOB_PATHSPECS=1 \
      GIT_ICASE_PATHSPECS=1 TMOUT=600 PATH="$NCE/bin:$PATH" "$FELIX" $_nce_c ) >/dev/null 2>&1
done
is "with SHELLOPTS, BASHOPTS, TAR_READER_OPTIONS, GIT_EXTERNAL_DIFF, GIT_DIFF_OPTS, the four GIT_*_PATHSPECS and TMOUT exported, the gate, a probe and a commissioning check are given none of them, or an exported SHELLOPTS hands the CLI's own pipefail to checks written to run without it" \
   "$(LC_ALL=C sort -u "$NCE/rec2" | tr '\n' ' ')" "commission: gate: probe: "
is "and no tool those runs start is given any of them" "$(_nce_dirty "$NCE/tools2")" ""

# GIT_EXTERNAL_DIFF hands git diff to another program, and secret-scan reads
# what git diff prints. With `true` there it read nothing and passed a branch
# that adds a credential (red against main and dc27380c).
_nce_ss="$NCE/ss"; mkdir -p "$_nce_ss"
( _fx_cd "$_nce_ss" && git init -q -b main && printf 'a\n' > f.txt && git add f.txt \
  && git -c user.name=t -c user.email=t@t commit -qm base && git checkout -q -b topic ) >/dev/null 2>&1
printf 'api_key = "sk-QQQQQQQQQQQQQQQQQQQQQQQQ"\n' >> "$_nce_ss/f.txt"   # must_flag
( _fx_cd "$_nce_ss" && git -c user.name=t -c user.email=t@t commit -qam add ) >/dev/null 2>&1
_nce_x0="$(_nce_run "$_nce_ss" "$FROOT/harness/bin/secret-scan" main)"
_nce_x1="$(_nce_run "$_nce_ss" env GIT_EXTERNAL_DIFF=true "$FROOT/harness/bin/secret-scan" main)"
is "bin/secret-scan finds the credential a branch adds and exits 1" "${_nce_x0##*exit }" "1"
is "and with GIT_EXTERNAL_DIFF=true exported it still does, or git hands the diff to that program and the scan reads nothing" \
   "${_nce_x1##*exit }" "1"
while IFS= read -r _nce_g; do
  [ -n "$_nce_g" ] || continue
  case "
$_nce_gates
" in *"
$_nce_g
"*) ;; *) rm -rf "$FROOT/state/gate/$_nce_g" ;; esac
done <<<"$(cd "$FROOT/state/gate" 2>/dev/null && printf '%s\n' *)"
rm -rf "$NCE" "$NCP" "$MEM/nce"

