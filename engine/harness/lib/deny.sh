# Denial.
#
# The first thing Felix can stop rather than mention. Every other hook it wires
# injects text a session is free to ignore: SessionStart mounts doctrine,
# UserPromptSubmit names a play, Stop asks a question at the end. PreToolUse
# decides, and it is the only one that does.
#
# Felix skipped it for a long time because the charter said "governance layer",
# and a governance layer that only reports is a coherent thing to build. It is
# not what was wanted. A project running a stale copy of its own gate all day
# and reporting green is the case this exists for: Felix could see the rival
# gate and could not stop anybody running it.
#
# Narrow on purpose, in three ways:
#
#   - Table-driven, per project. The engine names no rule of its own, the same
#     way it names no project. What a repo refuses is the repo's decision.
#   - A rule matches the one field naming what the tool acts on, never the
#     payload and never file content. See _felix_deny_field.
#   - Fails open on everything. A missing table, an unparseable payload, a bad
#     regex, an unresolvable project: all allow. The cost of a false deny is a
#     person fighting their own tools and switching the harness off; the cost of
#     a missed deny is the status quo.
#
# It used to be narrow in a fourth way, and that one was a mistake. The matcher
# in hooks.json bound Bash alone, so no rule could see Read, Edit or Write —
# and the ledger then showed real sessions spending most of their calls on
# exactly those three. The matcher was doing duty as the blast-radius control,
# because a bad regex reaching Edit is indistinguishable from a broken editor.
#
# That is now handled where it belongs, by felix_deny_overbroad, so the matcher
# no longer has to be the answer. A pattern broad enough to refuse ordinary
# work is treated as a rule that is wrong rather than a rule that is strict,
# and skipped. Skipping can only ever allow more than the author intended,
# which is the same direction every other failure here already takes.
#
# deny.tsv rows: tool <TAB> extended-regex <TAB> reason [<TAB> scope]
#
# scope is empty, or `checkout`. Empty is every row written before the column
# existed and means what it always meant: refuse whatever the regex matches.
# `checkout` means the row protects the governed checkout and nothing else, so
# a match is refused unless everything the matched command acts on is
# throwaway — a fixture under the session scratchpad or $TMPDIR — which
# lib/where.sh decides. Any other value is read as empty: a scope spelled
# wrong keeps refusing, which is the direction a typo should fail in.

_felix_deny_rows() {
  local proj="$1" tool pattern reason scope
  [ -f "$proj/deny.tsv" ] || return 0
  while IFS=$'\t' read -r tool pattern reason scope; do
    case "$tool" in ''|'#'*) continue ;; esac
    # A row with no pattern is skipped rather than fatal, the same way a
    # malformed routes.tsv row is: one bad line must not stop a table enforcing.
    [ -n "${pattern:-}" ] || continue
    printf '%s\t%s\t%s\t%s\n' "$tool" "$pattern" "${reason:-refused by this project}" "${scope:-}"
  done < "$proj/deny.tsv"
}

# Which field of a payload a rule for this tool is about.
#
# One field per tool, chosen rather than searched. Scanning the payload for the
# first field that happens to be present looks more future-proof and is the
# wrong trade: an Edit whose new_string contains the text `"command": "rm -rf"`
# would hand that string to the matcher, and a rule would fire on content the
# person was only writing down. A tool nobody has taught this function is read
# as acting on a file, and a tool acting on nothing has no subject and is
# always allowed.
_felix_deny_field() {
  case "$1" in
    Bash)         printf 'command' ;;
    NotebookEdit) printf 'notebook_path' ;;
    WebFetch)     printf 'url' ;;
    *)            printf 'file_path' ;;
  esac
}

# That field's value, out of a PreToolUse payload, without parsing JSON.
#
# Escaped quotes are protected first, so a value containing one cannot run the
# match past the end of its own string and swallow the rest of the envelope.
# That over-capture is the dangerous direction here: it is how a rule matches
# text the person never typed and denies something legitimate.
#
# The first occurrence wins, not the last. A greedy leading `.*` in sed takes
# the last one, which is reachable: file content mentioning the field name puts
# a second copy after the real one, and the rule would then be tested against
# whatever that content said.
#
# Read two ways, split by size, and both return the same string. A small
# payload is read with parameter expansion, which runs no program. A large
# one is read by one awk, because ${s//pat/rep} in bash 3.2, which macOS ships
# and the hook runs under there, is not linear: for each match it tries every
# end position back from the end of the string and measures each with a
# strlen, so it costs about the length squared times the number of escaped
# quotes. Measured 2026-09-23 on 3.2.57: a 31K commit-template payload took 12
# to 13 s, a 9K `python3 -c` payload 19 s, and a 45K one did not finish in
# 110 s. Claude Code's hook timeout is 60 s.
_FELIX_DENY_INLINE=1024
felix_deny_subject() {
  local raw="$1" field rest val
  field="$(_felix_deny_field "${2:-}")"
  case "$raw" in *"\"$field\""*) ;; *) return 0 ;; esac
  # A raw \001 is a control character no JSON string may hold, so this is not
  # a payload Claude Code sent, and like any payload that does not parse it
  # has no subject. The expansion below uses \001 as its placeholder, and one
  # already in the payload would read as a quote there and not in the awk.
  case "$raw" in *$'\001'*) return 0 ;; esac

  if [ "${#raw}" -gt "$_FELIX_DENY_INLINE" ]; then
    # Printed only when awk finished. Part of a subject can be refused by a
    # row anchored at its end that the whole would not match, so an awk that
    # dies, or no awk on PATH, reads as no subject, which allows.
    val="$(printf '%s' "$raw" | LC_ALL=C awk -v f="$field" "$_FELIX_DENY_SUBJECT_AWK" 2>/dev/null \
           && printf x)" || return 0
    printf '%s' "${val%x}"
    return 0
  fi

  # All parameter expansion, no pipeline. This runs inside a synchronous hook on
  # every tool call, and the old tr/sed/awk/sed chain cost four process spawns
  # for a substring bash can find itself.
  rest="${raw#*\"$field\"}"          # after the key
  rest="${rest#*\"}"                 # past the colon, to the value's quote
  rest="${rest//\\\"/$'\001'}"        # neutralise escaped quotes first
  val="${rest%%\"*}"                 # to the first real closing quote
  printf '%s' "${val//$'\001'/\"}"
}

# The same reading as the expansion above, for a large payload: after the
# first "field", past the next quote, up to the first quote with no backslash
# before it, and each backslash-quote in what it took read as a quote.
#
# Linear in BWK awk, mawk and gawk. It uses no gsub and no split on a regex,
# since in BWK awk, which macOS ships, both cost the length times the number
# of matches: a gsub of 70,000 escaped quotes in 1M took 12 s. match, index,
# substr and a split on one character are linear. BWK awk splits on a line
# break as well when the separator is one character, so the value is split
# into lines first and each line on its quotes. The records are split on
# \001, which felix_deny_subject has turned away before this runs, so the
# payload is always one record: joining many would be quadratic too. The
# program holds no single quote, since it is a bash single-quoted string.
_FELIX_DENY_SUBJECT_AWK='
  BEGIN { RS = "\001" }
  { s = (NR > 1) ? s RS $0 : $0 }
  END {
    k = index(s, "\"" f "\"")
    if (!k) exit
    s = substr(s, k + length(f) + 2)
    if ((q = index(s, "\"")) > 0) s = substr(s, q + 1)
    if (substr(s, 1, 1) == "\"") exit
    if (match(s, /[^\\]"/)) s = substr(s, 1, RSTART)
    nl = split(s, L, "\n")
    for (i = 1; i <= nl; i++) {
      if (i > 1) printf "\n"
      np = split(L[i], P, "\"")
      for (j = 1; j < np; j++) printf "%s\"", substr(P[j], 1, length(P[j]) - 1)
      if (np) printf "%s", P[np]
    }
  }'

# Whether a pattern is too broad to be a rule.
#
# A rule says which work this project refuses. A pattern that also matches
# ordinary work is not a strict rule, it is a broken one, and honouring it
# produces a session where nothing can be edited and no error explains why.
# These two probes are what ordinary looks like: a routine command, and a path
# in no way special. Anything matching either is skipped.
#
# This can only ever allow more than the author asked for, never less, which is
# why it is safe to run ahead of every rule rather than only new ones.
FELIX_DENY_PROBES='git status --short
/felix/probe/ordinary'

felix_deny_overbroad() {
  local pattern="$1" probe
  [ -n "$pattern" ] || return 0
  while IFS= read -r probe; do
    [ -n "$probe" ] || continue
    # Bash's own ERE. The pipeline this replaces spawned a grep per probe per
    # rule, on every matched tool call; it also carried a documented SIGPIPE
    # hazard under pipefail that simply cannot arise without a pipe.
    [[ "$probe" =~ $pattern ]] && return 0
  done <<EOF
$FELIX_DENY_PROBES
EOF
  return 1
}

# The rows this project wrote that are too broad to enforce, for reporting.
# Nothing in the hot path calls this: the hook runs on every tool call, and a
# harness that repeats a static complaint on every call is noise. felix doctor
# is where somebody goes to be told what is wrong with their tables.
felix_deny_overbroad_rows() {
  local proj="$1" tool pattern reason scope
  while IFS=$'\t' read -r tool pattern reason scope; do
    [ -n "${pattern:-}" ] || continue
    felix_deny_overbroad "$pattern" && printf '%s\t%s\t%s\n' "$tool" "$pattern" "$reason"
  done <<EOF
$(_felix_deny_rows "$proj")
EOF
}

# The first row for this tool whose pattern matches the text: its reason goes
# in _FELIX_DENY_REASON, and the status says whether there was one. A variable
# and not output, so the call that nearly always finds nothing costs no
# subshell to find it.
_felix_deny_first() {
  local proj="$1" want="$2" text="$3" tool pattern reason scope
  _FELIX_DENY_REASON=""
  while IFS=$'\t' read -r tool pattern reason scope; do
    [ "${tool:-}" = "$want" ] || continue
    felix_deny_overbroad "$pattern" && continue
    # Bash's own ERE rather than `printf | grep`. The old form needed a comment
    # explaining why it could not use `grep -q` — a consumer exiting on first
    # match kills the producer with SIGPIPE and pipefail reports 141, read as
    # "no match" every time. No pipe, no hazard, and no process per rule.
    [[ "$text" =~ $pattern ]] || continue
    # A row scoped to the checkout is passed over, not answered, when the
    # command acts only on throwaway places: a later row may still refuse it.
    # Everything this costs is spent on a command a row already matched.
    if [ "${scope:-}" = checkout ]; then
      _felix_deny_scoped "$want" "$pattern" "$reason" && continue
      reason="$reason
It stood although this row covers only the governed checkout: ${_FELIX_WHERE_WHY:-where the command acts cannot be told}."
    fi
    _FELIX_DENY_REASON="$reason"
    return 0
  done <<EOF
$(_felix_deny_rows "$proj")
EOF
  return 1
}

# Prints the reason when a command matches a row for this tool, and returns 0.
# Silent and returns 1 otherwise.
#
# A Bash row is about the command the shell runs, and not about text the
# command only carries. Until 2026-09-23 a row was matched against the payload's
# string alone, where everything the command carries reads as if it ran: a
# here-document body handed to `git commit -F -`, a message in `-m "..."`, a
# JSON payload in single quotes, a comment. The marker row refused a commit
# message saying "felix new <name> ... a .felix marker", because `<name>` holds
# a `>`. And the string is JSON, so a line break arrives as a backslash and an
# `n`, and a pattern's `[^;&|]*` ran across it: `git push -q` on one line and
# `gh api -f` on the next read as a force push. Of the 175 refusals the hooks
# had logged by then, about thirty were text of those kinds.
#
# So a Bash command that matches a row is read a second time, by
# felix_deny_code, as the shell reads it, and refused only if the row still
# matches there. That second reading costs a process, and it is spent only on
# a command about to be refused: every other call pays exactly what it paid
# before, which matters because this hook runs on every one of them. A reading
# done in bash itself was tried first and measured: bash 3.2's ${s//...} took
# fourteen seconds over a 31K command.
#
# This can only ever turn a refusal into an allow. What it does not do is the
# other direction, and there are commands a row names that the shell runs and
# the raw string never matched: `git push -f` with a line break after it, or
# `bash -c "git push --force"`, whose quote stands where the row wants a
# space. Refusing those would mean reading every command, not only the ones a
# row already matched, and that is a separate decision with its own cost.
#
# START is the directory the command starts in, the payload's cwd. It matters
# only to a row scoped to the checkout, which is judged on the command as the
# payload carries it, whichever reading the row matched; the governed
# checkout is the one this process stands in.
felix_deny_match() {
  local proj="$1" want="$2" cmd="$3" start="${4:-$PWD}"
  [ -n "$cmd" ] || return 1
  _FELIX_DENY_RAW="$cmd"; _FELIX_DENY_START="$start"; _FELIX_DENY_SCOPED=""
  if _felix_deny_first "$proj" "$want" "$cmd" \
     && { [ "$want" != "Bash" ] || _felix_deny_first "$proj" Bash "$(felix_deny_code "$cmd")"; }; then
    printf '%s' "$_FELIX_DENY_REASON"
    return 0
  fi
  _felix_deny_record_lifts "$proj" "$cmd"
  return 1
}

# A scoped row, judged once per command however many readings match it. Bash
# is tried against the raw text and then the code view, and the judgement is
# the same both times, so the second asks this cache instead of the reader.
_felix_deny_scoped() {
  local want="$1" pattern="$2" reason="$3" line
  while IFS= read -r line; do
    case "$line" in
      "L	$pattern	"*) return 0 ;;
      "S	$pattern	"*) _FELIX_WHERE_WHY="${line#S	"$pattern"	}"; return 1 ;;
    esac
  done <<EOF
$_FELIX_DENY_SCOPED
EOF
  if _felix_deny_scoped_lifts "$want" "$pattern" "$_FELIX_DENY_RAW" "$_FELIX_DENY_START"; then
    _FELIX_DENY_SCOPED="$_FELIX_DENY_SCOPED"$'\n'"L	$pattern	$reason"
    return 0
  fi
  _FELIX_DENY_SCOPED="$_FELIX_DENY_SCOPED"$'\n'"S	$pattern	$_FELIX_WHERE_WHY"
  return 1
}

# Written down as well as allowed, and only when the command was allowed. A
# lift is a row refusing less than its regex says, and a record of each is how
# a later audit replays exactly what the column let through.
_felix_deny_record_lifts() {
  local proj="$1" cmd="$2" line rest
  command -v felix_say >/dev/null 2>&1 || return 0
  while IFS= read -r line; do
    case "$line" in L$'\t'*) ;; *) continue ;; esac
    rest="${line#L	}"
    felix_say "$proj" lifted "$cmd
${rest#*	}" "" "" 2>/dev/null
  done <<EOF
$_FELIX_DENY_SCOPED
EOF
}

# Whether a row scoped to the checkout passes this call over. Bash is read for
# where it acts; a tool naming one path acts on that path; a URL acts on no
# place the checkout owns, so nothing is known and the row stands.
#
# lib/where.sh is loaded here, from beside this file, and not by the hook: the
# hook runs on every tool call and this runs only after a scoped row matched.
# If it cannot be loaded nothing is known, and the row stands.
_FELIX_DENY_LIB="${BASH_SOURCE[0]%/*}"
_felix_deny_scoped_lifts() {
  local want="$1" pattern="$2" subj="$3" start="$4"
  _FELIX_WHERE_WHY=""
  command -v felix_where_lifts >/dev/null 2>&1 \
    || . "$_FELIX_DENY_LIB/where.sh" 2>/dev/null || return 1
  case "$want" in
    Bash) felix_where_lifts "$pattern" "$subj" "$start" "$PWD" ;;
    WebFetch) return 1 ;;
    *) felix_where_path_lifts "$subj" "$start" "$PWD" ;;
  esac
}

# The command the shell runs, as one line for a row to match, read from the
# payload's JSON string: commands joined by `;`, every quoted span that is data
# standing as the word `_`, comments and here-document bodies gone, and each
# piece of code found inside something else appended after it, ` ; ` apart, as
# a command of its own.
#
# What counts as data, and each exception to it, since an exception missed is
# a command the shell runs and a row can no longer see:
#
#   - A here-document body is data, unless what reads it runs its input as
#     code: a shell, ssh, su, runuser, watch, eval, source, or `.` in command
#     position. Then its lines are commands. Where its word is unquoted the
#     shell expands the body, so a $( ) or a backtick in it is read as code.
#     And a body written to a file is read as code when the same command then
#     runs that file by the same spelling: `cat > $S/t.sh <<'EOF' ... EOF;
#     bash $S/t.sh`, the shape a scratch fixture takes. Seven of the logged
#     refusals had it, and in each the body ran what its row names. The same
#     holds for quoted text printf or echo writes to a file the command runs.
#   - A quoted span is data, `_`, when it holds a blank or a line break. It is
#     read as code where it is a shell's -c script or an argument of eval,
#     ssh, su, runuser or watch, gathered whole when it is quoted in pieces
#     (`'...'\''...'`). It is its own text, without the quotes, where it is a
#     redirect's target, an operand of a command that writes its operands
#     (cp, mv, ln, install, tee, dd, truncate, rm, touch, rsync, sed -i), the
#     program itself, glued to the word it sits in
#     (`--for'ce'`, `"$HOME"/.felix`, but not `--message="..."`), a single
#     word, or a path rooted in a variable, a home or a relative directory
#     (`$T/...`, `${D}...`, `~/...`, `./...`), so `> "$T/repo/.felix"` still
#     writes the marker. A span starting with a bare `/` is not taken for a
#     path, because `sed -n '/git push .* main /p'` starts that way too.
#   - Inside double quotes a $( ) or a backtick runs, and is read as code. The
#     here-document inside the $( ) of Claude Code's commit template is data
#     by the first rule. A substitution keeps its shape where it stood, as
#     `$(_)` or `<(_)`, since a row can be written about the shape itself.
#   - A # starting a word outside quotes starts a comment. `$(( ))` and
#     `(( ))` are arithmetic, whose << is a shift; the second is read as code
#     as well, in case bash takes it for two subshells.
#   - A pipe into a shell, a shell reading a process substitution, or a $( )
#     handed to something that runs its arguments, makes the data the script:
#     then the whole command is read with every quote dropped and each line
#     break a `;`.
#
# What it does not follow is a file written by anything but a here-document,
# or run by another name: a script printf wrote to $S/bin/claude and PATH
# later finds. That is the limit any reading of one command has.
#
# One awk process. The program is the same in BWK awk, mawk and gawk:
# split(s, A, "") is one character per element in all three. Nothing here
# fails closed: no awk, or a program error, prints nothing, and a row matches
# nothing in nothing, which allows.
#
# The program is lib/deny-read.sh, sourced the first time a command needs it,
# so the call no row matches does not even read the file.
felix_deny_code() {
  [ -n "${_FELIX_DENY_READ:-}" ] || . "$(dirname "${BASH_SOURCE[0]:-$0}")/deny-read.sh" 2>/dev/null
  printf '%s' "$1" | awk "${_FELIX_DENY_READ:-}" 2>/dev/null
}
