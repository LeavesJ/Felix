# felix audit: how often a turn stopped on an edit nothing had checked, read
# from the transcripts Claude Code already keeps.
#
# The cheapest way to try Felix is to be shown the problem it exists for, on
# your own record, before installing anything. So this is the one command that
# runs from a plain clone (git clone <felix> && felix/engine/harness/felix
# audit), and it is read-only by construction, not by care: the CLI dispatches
# it before any other library is sourced and before a home is resolved, it
# opens no file for writing, makes no temporary file (no here-document either:
# bash backs those with one), calls no model and touches no network. It reads
# DIR/*/*.jsonl, a transcript per file, DIR defaulting to
# ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects; an explicit --dir holding only
# transcripts is read as one project, DIR/*.jsonl. No transcripts is a report.
#
# One awk pass, because a heavy user keeps gigabytes of these. One line can
# hold megabytes, so a loop over one cuts it once and walks the pieces, or
# moves a pointer on, and joins what it keeps by halves, rather than
# re-copying the rest of the line, or all it kept, per step. The exceptions:
# a --verify pattern that matches many times between two of ; & | ( in one
# command, whose last match is found by reading on from each, within that
# piece and within the 256K a command is read whole at (the default checks
# match once to a piece); and a << in the first 64K of a longer command that
# nothing in those 64K closes, whose closing line is looked for in the rest
# of the command, one read per word, eight words at most.
#
# No JSON parser, on purpose (invariant 2), and why that is safe: every
# pattern below is structural — a key, a colon, a quoted value — and
# inside a JSON string every double quote is escaped, so `"type":"tool_use"`
# can only match the structure, never a message that quotes it.
#
# Per session, in file order:
#   an EDIT   a tool_use named Edit, Write, MultiEdit or NotebookEdit, or a
#             Bash command that writes a file in place (sed -i, perl -i, a > or
#             >> or tee to a named path, patch, git apply; any other write
#             through Bash is not seen, and the report says so), unless
#             its file is scratch (/tmp, TMPDIR), Claude's own (anything under
#             the config directory: memory, plans, settings, skills, hooks) or
#             Felix's memory (FELIX_MEMORY): no gate covers those, and a stop
#             they alone precede is counted aside, and said
#   a CHECK   a Bash command (never its description) matching the verify
#             pattern outside quoted text and here-document bodies, save the
#             script a shell is handed (bash -c, bash <<EOF); it FAILED when
#             its tool_result says is_error:true
#   a STOP    a distinct end_turn message id. Claude Code writes a line per
#             content block, logs a message again later, and copies history
#             into a new file on resume or fork: none is a second stop, and a
#             copied one answers the edits before it
# and a stop with an edit since the previous one is exactly one of: passed
# (the last check after the last edit reported no error), failed (it did),
# stale (no check since the last edit, one before it) or never (no check in
# the session yet). A passed check whose exit status could not reach the
# transcript — piped, followed by another command, backgrounded, turned over
# by ! — is counted again on its own line, because "no error reported" is all
# it can say.
# isSidechain records and the subagents/ tree are never read; the report says
# so, since a session that delegated its testing reads as `never` here.
#
# A Felix hold is a meta user record (isMeta, as Claude Code writes what a
# hook returns) whose content starts "Stop hook feedback" and carries a
# sentence Felix's Stop hook uses when it refuses to let a turn end on an
# ungated tree. Quoted by a person, even as the first words of their message,
# or by an attachment, it is not one; copied into a resumed session, it is the
# same one. The four classes count only stops after an edit, and a hold can
# follow any stop, so each hold is told by the stop just before it: counted in
# the four, left out as after scratch edits only, after no new edit, or none
# that was read.

# What counts as a check, beside what --verify adds: the usual test and gate
# runners, at command position — the start of the command, or after ; & | ( or
# $( — behind any VAR=value, a wrapper (npx, env, nohup, sudo, timeout and
# the like, each with its options, or any `<tool> run` or `<tool> exec`), and
# a path, which a $( ) may build. At command position so that `sed -n 1p
# tests/run` and `grep jest package.json` read as the reads they are. A value
# ends where the word does, so what follows `W=/w;` or a line break is the
# next command, though a $( ) or a backquoted command in it is part of it,
# blanks and all; and the path before a runner holds no = , so assigning
# `G=scripts/gate.sh` is not running it. The shell's reserved words stand
# where a command does, so the runner after if, then, else, elif, do, while,
# until, ! or { is run. Options may stand between a tool and its test command
# (make -C engine test, npm --prefix web test, pnpm --filter web test). The
# roster names the test runners of many ecosystems side by side on purpose,
# the way a probe does, and no list names them all: a runner it does not name
# is no check, and the report says so rather than calling the session
# unchecked. ecosystem.tsv carries the row.
FELIX_AUDIT_WORD='(if|then|else|elif|do|while|until|!|[{]) +'
FELIX_AUDIT_ASSIGN='[A-Za-z_][A-Za-z0-9_]*=([^ ;&|()`]|[$][(][^()]*[)]|`[^`]*`)* +'
FELIX_AUDIT_OPTS='( +-[-A-Za-z0-9]+(=[^ ;&|()]*)?( +[^- ;&|()][^ ;&|()]*)?)*'
FELIX_AUDIT_WRAP='((env|time|exec|command|nice|nohup|sudo|bash|sh|zsh|npx|bunx)'"$FELIX_AUDIT_OPTS"'|timeout( +-[-A-Za-z]+( +[A-Z0-9][A-Za-z0-9]*)?)* +[0-9.]+[smhd]?) +'
FELIX_AUDIT_RUNNERS='(npm|pnpm|yarn|bun)'"$FELIX_AUDIT_OPTS"'( +workspace +[^ ;&|()]+)? +(run +)?(test|verify|check)'\
'|pytest|python[0-9.]*'"$FELIX_AUDIT_OPTS"' +-m +(pytest|unittest)|tox|nox|cargo +(test|check|nextest)|go +test'\
'|make'"$FELIX_AUDIT_OPTS"' +(test|check)|mvnw? +([^;&|]* +)?(test|verify)|gradlew? +([^;&|]* +)?(test|check)'\
'|rspec|phpunit|rake +(test|spec)|rails +test|php +artisan +test|dotnet +test|swift +test|mix +test|ctest'\
'|jest|vitest|mocha|playwright +test|deno +test|hardhat +test|forge +test|flutter +test|dart +test'\
'|sbt +test|lein +test|stack +test|cabal +test|zig +build +test|bazel +test'\
'|tests/run|gate[.]sh|felix +gate'
FELIX_AUDIT_CHECKS='(^|[;&|(]|[$][(])[ ]*('"$FELIX_AUDIT_WORD|$FELIX_AUDIT_ASSIGN|$FELIX_AUDIT_WRAP"'|[a-z]+ +(run|exec) +)*(([^ ;&|()=]|[$][(][^()]*[)])*/)?('"$FELIX_AUDIT_RUNNERS"')([^A-Za-z0-9_]|$)'
# Where a double-quoted span stands for a command, as "./tests/run" can: the
# same position, read on text whose line breaks are already ; .
FELIX_AUDIT_CMDPOS='(^|[;&|(])[ ]*('"$FELIX_AUDIT_WORD|$FELIX_AUDIT_ASSIGN|$FELIX_AUDIT_WRAP"')*$'
# What stands before a command's own word, from the start of a piece cut at
# ; & | ( ): the same words, assignments and wrappers, read the same way, for
# the commands that write in place. And git apply, behind git's own options.
FELIX_AUDIT_LEAD='^[ ]*('"$FELIX_AUDIT_WORD|$FELIX_AUDIT_ASSIGN|$FELIX_AUDIT_WRAP"')*'
FELIX_AUDIT_GITAPPLY='^([^ =]*/)?git'"$FELIX_AUDIT_OPTS"' +apply( |$)'

felix_audit_usage() {
  printf 'usage: felix audit [--dir DIR] [--since YYYY-MM-DD] [--verify ERE]\n'
  printf '  read-only: how often a turn stopped on an edit that no check had run after,\n'
  printf '  read from Claude Code transcripts. Writes nothing, installs nothing.\n'
  printf '  --dir DIR      transcripts to read, DIR/*/*.jsonl, or DIR/*.jsonl for one\n'
  printf '                 project (default: ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects)\n'
  printf '  --since DATE   count only stops and holds on or after this UTC date; what\n'
  printf '                 came before still says whether a check had run\n'
  printf '  --verify ERE   a project'"'"'s own check, beside the default runners: a Bash\n'
  printf '                 command matching this POSIX ERE counts too, in every project read\n'
}

_felix_audit_refuse() {
  printf 'felix audit: %s\n' "$1" >&2
  felix_audit_usage >&2
  return 2
}

# The pass. File names on stdin, one per line; out, one line of tab-separated
#   files sessions first last stops stop_sessions passed failed stale never
#   holds hold_sessions hidden aside unread held_counted held_aside held_noedit
#   skipped
# (first and last - where no record had a timestamp; skipped the transcripts
# read with no timestamped record, on or after --since), then the first file that
# could not be read, if one. A session is the sessionId its records carry (the
# file name where they carry none), so one filed under two projects counts
# once, and a stop or a hold copied into a resumed session stays with the
# session it was made in, whichever transcript is read first.
#
# The program is two halves in two files beside this one, lib/audit-read.sh
# (how a command is read) and lib/audit-count.sh (what counts), sourced from
# this file's own directory so a plain clone and a fixture copy of the harness
# find them alike. They define a variable each and nothing else, and a half
# that cannot be read fails the source of this file, never a scan with half a
# program.
case "${BASH_SOURCE[0]:-}" in
  */*) _felix_audit_lib="${BASH_SOURCE[0]%/*}" ;;
  *)   _felix_audit_lib=. ;;
esac
# shellcheck source=audit-read.sh
. "$_felix_audit_lib/audit-read.sh" || return 1
# shellcheck source=audit-count.sh
. "$_felix_audit_lib/audit-count.sh" || return 1
unset _felix_audit_lib
felix_audit_scan() {
  awk "$_FELIX_AUDIT_READ$_FELIX_AUDIT_COUNT"
}

_felix_audit_n() {     # count noun -> "1 stop", "4 stops"
  [ "$1" = 1 ] && printf '1 %s' "$2" || printf '%s %ss' "$1" "$2"
}

_felix_audit_pct() {   # part whole -> whole-number percent
  [ "$2" -gt 0 ] || { printf '0'; return; }
  printf '%d' $(( (100 * $1 + $2 / 2) / $2 ))
}

_felix_audit_list() {  # dir mode -> the transcripts, one per line; mode 2 is one project's
  local f g="*/*.jsonl"; [ "$2" -eq 2 ] && g="*.jsonl"
  for f in "$1"/$g; do if [ -f "$f" ]; then printf '%s\n' "$f"; fi; done
}

# What the stop just before each hold was. Holds are read from every stop hook
# feedback, the four classes only from stops after an edit, so a held stop is
# among the stops above only when an edit came before it; most real holds
# follow a turn that edited nothing, and a sentence saying every held stop is
# counted there was false for them.
_felix_audit_held() {  # holds counted aside noedit -> the clauses, joined by "; "
  local all="$1" out="" k n one many
  for k in c a n x; do
    case "$k" in
      c) n="$2"; one="is still counted above, where the turn tried to end"
         many="are still counted above, where the turn tried to end" ;;
      a) n="$3"; one="followed edits only to scratch files or Claude's or Felix's own, left out above"; many="$one" ;;
      n) n="$4"; one="followed a turn with no new edit"; many="$one" ;;
      x) n=$(($1 - $2 - $3 - $4)); one="had no stop before it in what was read"
         many="had no stop before them in what was read" ;;
    esac
    [ "$n" -gt 0 ] || continue
    [ "$n" -eq 1 ] || one="$many"
    if [ "$n" -eq "$all" ]; then
      case "$n" in 1) out="It $one" ;; 2) out="Both $one" ;; *) out="All $n $one" ;; esac
    elif [ -z "$out" ]; then out="$n of them $one"
    else out="$out; $n $one"
    fi
  done
  printf '%s' "$out"
}

_felix_audit_next() {
  printf 'Next, still cheap: felix new <name> --no-commission binds one project (its rules, a gate guess, a marker) with no plugin installs and no network. Where a gate was guessed, its sessions are held once felix install has run; where none was, set gate in project.json first.\n'
}

felix_audit() {
  local dir="" since="" verify="" explicit=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --dir)    [ $# -ge 2 ] && [ -n "$2" ] || { _felix_audit_refuse "--dir needs a value"; return; }
                dir="$2"; explicit=1; shift 2 ;;
      --since)  [ $# -ge 2 ] && [ -n "$2" ] || { _felix_audit_refuse "--since needs a value"; return; }
                since="$2"; shift 2 ;;
      --verify) [ $# -ge 2 ] && [ -n "$2" ] || { _felix_audit_refuse "--verify needs a value"; return; }
                verify="$2"; shift 2 ;;
      -h|--help) felix_audit_usage; return 0 ;;
      *) _felix_audit_refuse "unknown argument: $1"; return ;;
    esac
  done
  # A date, and a real month and day: it is compared as text, so 2026-19-39
  # would be a cutoff nobody meant rather than an error.
  case "$since" in
    '') ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      [ "1${since:5:2}" -ge 101 ] && [ "1${since:5:2}" -le 112 ] \
        && [ "1${since:8:2}" -ge 101 ] && [ "1${since:8:2}" -le 131 ] \
        || { _felix_audit_refuse "--since takes a date, YYYY-MM-DD; got: $since"; return; } ;;
    *) _felix_audit_refuse "--since takes a date, YYYY-MM-DD; got: $since"; return ;;
  esac
  # Perl and GNU escapes read as a plain letter on some awks and as a class on
  # others, so the same flag would answer differently on macOS and Linux.
  case "$verify" in
    *'\s'*|*'\S'*|*'\d'*|*'\D'*|*'\w'*|*'\W'*|*'\b'*|*'\B'*|*'\y'*|*'\<'*|*'\>'*)
      _felix_audit_refuse "--verify is a POSIX ERE, where \\s \\d \\w \\b are not classes on every awk; use [[:space:]], [[:digit:]], [[:alnum:]_], ([^[:alnum:]_]|\$): $verify"; return ;;
  esac
  if [ -n "$verify" ] && ! FELIX_AUDIT_VERIFY="$verify" awk 'BEGIN { if ("" ~ ENVIRON["FELIX_AUDIT_VERIFY"]) x = 1 }' 2>/dev/null; then
    _felix_audit_refuse "--verify is not an extended regular expression awk can read: $verify"; return
  fi
  local cfg="${CLAUDE_CONFIG_DIR:-}"
  [ -n "$cfg" ] || [ -z "${HOME:-}" ] || cfg="$HOME/.claude"
  [ -n "$dir" ] || dir="${cfg:+$cfg/projects}"
  # Felix's memory, where felix_mem_root puts it, read here without sourcing
  # the library that says so, which this command runs before.
  local mem="${FELIX_MEMORY:-}"
  [ -n "$mem" ] || [ -z "${HOME:-}" ] || mem="$HOME/.felix/memory"
  [ "$dir" = "/" ] || dir="${dir%/}"
  if [ "$explicit" -eq 1 ] && [ ! -d "$dir" ]; then
    _felix_audit_refuse "--dir $dir is not a directory"; return
  fi

  printf 'felix audit: read-only. Nothing was written, installed or sent.\n\n'

  local f mode=0
  if [ -n "$dir" ]; then
    for f in "$dir"/*/*.jsonl; do if [ -f "$f" ]; then mode=1; break; fi; done
    if [ "$mode" -eq 0 ] && [ "$explicit" -eq 1 ]; then
      for f in "$dir"/*.jsonl; do if [ -f "$f" ]; then mode=2; break; fi; done
    fi
  fi
  if [ "$mode" -eq 0 ]; then
    if [ -z "$dir" ]; then
      printf 'No Claude Code transcripts found: neither CLAUDE_CONFIG_DIR nor HOME is set, so there is nowhere to look.\n'
    else
      printf 'No Claude Code transcripts found in %s.\n' "$dir"
    fi
    printf 'It reads DIR/*/*.jsonl, or DIR/*.jsonl for one project; point it elsewhere with --dir DIR.\n\n'
    _felix_audit_next
    return 0
  fi

  local t bad=""
  t="$(_felix_audit_list "$dir" "$mode" \
       | FELIX_AUDIT_SINCE="$since" FELIX_AUDIT_VERIFY="($FELIX_AUDIT_CHECKS)${verify:+|($verify)}" FELIX_AUDIT_CMDPOS="$FELIX_AUDIT_CMDPOS" \
         FELIX_AUDIT_LEAD="$FELIX_AUDIT_LEAD" FELIX_AUDIT_GITAPPLY="$FELIX_AUDIT_GITAPPLY" \
         FELIX_AUDIT_CFG="$cfg" FELIX_AUDIT_MEM="$mem" FELIX_AUDIT_TMP="${TMPDIR:-}" felix_audit_scan)" \
    || { printf 'felix audit: the read failed part way; nothing to report\n' >&2; return 1; }
  case "$t" in *$'\n'*) bad="${t#*$'\n'}"; t="${t%%$'\n'*}" ;; esac
  # Nineteen fields, none empty and none with a space, so plain word splitting
  # reads them; a tab-IFS read of a substitution is the trap the constitution
  # names, and this avoids needing one.
  # shellcheck disable=SC2086
  set -- $t
  [ $# -eq 19 ] || { printf 'felix audit: the read returned %s fields, not 19; nothing to report\n' "$#" >&2; return 1; }
  local nfiles="$1" sessions="$2" first="$3" last="$4" stops="$5" ssess="$6"
  local passed="$7" failed="$8" stale="$9" never="${10}" holds="${11}" hsess="${12}"
  local hid="${13}" aside="${14}" unread="${15}" hcount="${16}" haside="${17}" hnoedit="${18}" skipped="${19}"

  printf '  transcripts  %s%s\n' "$dir" "$([ "$mode" -eq 2 ] && printf ' (one project: DIR/*.jsonl)')"
  local span=", from $first to $last${since:+ (--since $since)}"
  [ "$first" = "$last" ] && span=", all on $first${since:+ (--since $since)}"
  [ "$first" = "-" ] && span=""
  # A transcript can hold records and still make no session: summaries carry
  # no timestamp, and --since can put every stamp before the cutoff. Such a
  # transcript is skipped, and said, whether or not others made sessions.
  local skip="" was=was
  [ "$skipped" -eq 1 ] || was=were
  [ "$skipped" -gt 0 ] && skip="; $(_felix_audit_n "$skipped" transcript) with no timestamped record${since:+ on or after $since} $was skipped"
  printf '  sessions     %s%s%s\n\n' "$sessions" "$span" "$skip"

  printf '%s came after an edit, in %s. Where each one stood:\n\n' \
    "$(_felix_audit_n "$stops" stop)" "$(_felix_audit_n "$ssess" session)"
  printf '  passed  %5s  %3s%%  the last check after the last edit reported no error\n' \
    "$passed" "$(_felix_audit_pct "$passed" "$stops")"
  [ "$hid" -gt 0 ] && \
    printf '                      and %s of those could not have: piped, followed by another command, backgrounded, or turned over by !\n' "$hid"
  printf '  failed  %5s  %3s%%  the last check after the last edit failed, and the turn stopped anyway\n' \
    "$failed" "$(_felix_audit_pct "$failed" "$stops")"
  printf '  stale   %5s  %3s%%  a check ran earlier in the session, but none after the last edit\n' \
    "$stale" "$(_felix_audit_pct "$stale" "$stops")"
  printf '  never   %5s  %3s%%  no check the roster recognises had run in the session at all\n\n' \
    "$never" "$(_felix_audit_pct "$never" "$stops")"

  [ "$aside" -gt 0 ] && \
    printf 'Left out: %s after edits only to scratch files, to Claude'"'"'s configuration directory (memory, plans, settings, skills, hooks) or to Felix'"'"'s memory, which no gate covers.\n\n' \
      "$(_felix_audit_n "$aside" stop)"
  [ "$holds" -gt 0 ] && \
    printf 'Felix held %s, in %s, because no passing gate result was current for the tree. %s.\n\n' \
      "$(_felix_audit_n "$holds" stop)" "$(_felix_audit_n "$hsess" session)" \
      "$(_felix_audit_held "$holds" "$hcount" "$haside" "$hnoedit")"
  [ "$unread" -gt 0 ] && \
    printf 'Not read: %s could not be opened (the first: %s).\n\n' "$(_felix_audit_n "$unread" transcript)" "$bad"

  if [ -n "$verify" ]; then
    printf 'A check is a Bash command running tests or a gate (npm test, pytest, cargo test, go test, make check, jest, vitest, felix gate and the like) or matching --verify %s, in every project read, outside quoted text and here-documents, save a script handed to a shell.\n' "'$verify'"
  else
    printf 'A check is a Bash command running tests or a gate (npm test, pytest, cargo test, go test, make check, jest, vitest, felix gate and the like), outside quoted text and here-documents, save a script handed to a shell. A runner the roster does not name is not a check, so a session that ran only one reads as never; --verify ERE adds a project'"'"'s own, in every project read (--dir one project'"'"'s directory to narrow it).\n'
  fi
  printf 'A check piped into another command, followed by one, run in the background or turned over by ! hands its exit status to something else, so its own failure goes unseen: a stop after one is counted failed only when what took that status failed.\n'
  printf 'Subagents are not seen: their edits and checks sit in files this does not read.\n'
  printf 'An edit is an Edit, Write, MultiEdit or NotebookEdit call, or a Bash command that writes a file in place: sed -i, perl -i, a > or >> or tee to a named path, patch or git apply. Other writes through Bash are not seen.\n\n'
  _felix_audit_next
  return 0
}
