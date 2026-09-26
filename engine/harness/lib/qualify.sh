# Checker qualification: does a check fail when the thing it protects is broken?
#
# v3.2's conformance amendments call this the largest gap in the spec, and the
# reason is stated there rather than argued here: every layer above narrows what
# a model may write, and none of them asks whether the checker that judges the
# writing works. A check that passes over a violation is worse than no check,
# because the report says the property holds.
#
# Seven controls, from amendments 2.1. Six are mutations; the seventh is a
# property of the checker's own output and is reported separately.
#
#   violation              break the protection.        the checker must FAIL
#   restoration            put it back.                 the checker must PASS
#   irrelevant             rename a local, reword a
#                          comment, reformat.           the checker must PASS
#   alternate              violate by a different
#                          mechanism than the first.    the checker must FAIL
#   decoupled_violation    violate while every
#                          syntactic marker of the
#                          protection stays perfect.    the checker must FAIL
#   decoupled_satisfaction satisfy by a mechanism
#                          sharing no syntax with the
#                          original.                    the checker must PASS
#
# Controls 1 through 4 all move the marker and the property together, so a
# checker keyed on a lexical shadow tracks every one of them and looks perfect.
# 5 and 6 are the ones that separate the two, and the amendments record that 5
# alone caught four cheats out of four.
#
# What refuses and what only reports. This file refuses nothing itself;
# `felix qualify --gate` refuses on a declared control that did not hold, one
# that could not run, a checker never shown failing here, and a row that cannot
# be read as a control. It refuses as well on a table it could not read, on a
# run that produced fewer verdicts than the rows it selected, and on any count
# or list a verdict is worked out from that could not be worked out: each of
# those once came out as none, and none held reads as a pass. A control nobody
# declared refuses nothing. That is the
# ratchet cmd_qualify argues for, and it is what made arming safe: refusing to
# let an unqualified checker enforce turns every gate red on the day it lands,
# and how much Felix may block is a founder's decision, not a session's.
#
# So a checker short of the six controls is reported and not refused. That was
# decided, not left, on 2026-09-22 after a contract review asked. Refusing it
# is the design the ratchet replaced, and it would turn this engine's own gate
# red today: independence declares four of six, and its table says why the two
# decoupled controls cannot be met by a checker that reads text. Declaring them
# to satisfy the refusal would bind two held controls and go red the other way.
# The gate prints the shortfall under `qualified ok` instead, so an ok is not
# read as six of six.
#
# Leaving it is safe because of the merge boundary, not this file.
# qualification.tsv is an enforcing table (escape.sh): removing or changing a
# control a checker already had fires `verifier` at felix merge. A missing
# control can therefore only be one never declared, which is a coverage gap
# the gate reports. It cannot be one quietly withdrawn, which would be a trust
# gap.
#
# The mutations must be authored by something that has not seen the checker
# (amendments 2.2). That is load-bearing and unverifiable from here: whoever
# writes both writes mutations its own checker survives. The table records who
# authored each row so the claim is at least legible; it cannot be enforced.

# control:expect. The verdict belongs to the control, not to the row. `expect`
# used to be free text beside `control`, so a violation row expecting `pass`
# over a mutation that changed nothing was met: a control that tested nothing,
# counted as one that held. A contract review found it on 2026-09-22. A row that
# pairs a control with any other verdict is now malformed, and so is a row
# naming no control here. That row has no verdict to be held to, and without
# this one misspelt letter would put a row beyond the pairing.
FELIX_QUALIFY_EXPECT='violation:fail restoration:pass irrelevant:pass alternate:fail decoupled_violation:fail decoupled_satisfaction:pass'
# The names alone, derived so the two lists cannot disagree.
FELIX_QUALIFY_CONTROLS="${FELIX_QUALIFY_EXPECT//:fail/}"
FELIX_QUALIFY_CONTROLS="${FELIX_QUALIFY_CONTROLS//:pass/}"

# checker <TAB> command <TAB> control <TAB> expect <TAB> mutation [<TAB> premise]
#
# The premise, and why a fourth verdict exists (#233).
#
# Some controls can only be staged where something already exists. The
# independence violation plants a governed project's name in the engine and
# requires the checker to find it; in a checkout that governs only the engine's
# own project there is no such name, the mutation leaks nothing, the checker
# rightly passes, and the control was counted HELD — a red gate over an engine
# with nothing wrong with it. Counting it met instead would be a lie. The honest
# report is a third thing: this control's premise is absent here.
#
# So a row may carry a premise, run in the worktree of HEAD before the mutation,
# and the exit status is read strictly. 0 applies the control. 1 — the
# conventional "no" of test, grep -q and false — makes it `inapplicable`, and
# neither the mutation nor the checker runs. Anything else is `unrunnable`:
# a premise that errored has not said the premise is absent, and reading 2 or
# 127 as "absent" is how a typo would silence a control forever.
#
# That trap has a second half the exit status cannot close: a premise that
# answers a clean 1 everywhere, because it tests the wrong path. A control that
# never applies never holds. felix_qualify_unshown names the checker whose every
# fail-expecting control came back inapplicable, because such a checker has not
# been shown failing in this checkout and must not be read as qualified in it —
# so `felix qualify --gate` refuses on it, exactly as on a held control. The way
# out is a control that stages its own premise, which applies everywhere.
_felix_qualify_table() { printf '%s/qualification.tsv' "$1"; }

# One reading of a row, shared by the readers below, so what runs and what is
# reported malformed cannot drift apart. why() is empty for a control and
# otherwise says why the row is not one. Each line that is not blank or a
# comment is exactly one of the two.
#
# An absent table declares nothing, and returns here before awk. That answer is
# only as good as the moment it was taken, which is why felix qualify takes it
# once (felix_qualify_snapshot): a table there at one read and gone at the next
# read as a run that declared nothing and passed. The path is worked out with
# its status, because a path that came back empty is a table that is not a file.
#
# Only a blank line and a comment are skipped, each by the whole line. A line
# was skipped when its first field was empty, so a held row with a tab in front
# of it was never run, never called malformed and never counted, and the gate
# passed over it. A row with a carriage return in it is malformed, and so is
# one of more than six fields: a table whose lines end in a bare CR is one line
# to awk, every row after the first rode in columns nobody reads, and a held
# control among them passed the gate. A checker is an id, [a-z][a-z0-9_-]*,
# the shape a needs cell and the gate's own lines already take: a name with a
# space was split into two checkers declaring nothing, a name like * was
# expanded to the files of the checkout, and the gate counted six controls met
# by `my check` across 0 checkers.
_felix_qualify_read() {   # proj, awk action
  local f; f="$(_felix_qualify_table "$1")" || return 2
  [ -f "$f" ] || return 0
  LC_ALL=C awk -F'\t' -v pairs="$FELIX_QUALIFY_EXPECT" '
    BEGIN { n = split(pairs, p, " ")
            for (i = 1; i <= n; i++) { split(p[i], kv, ":"); want[kv[1]] = kv[2] } }
    function why() {
      if (index($0, "\r"))  return "a carriage return; a row ends at a newline alone"
      if ($1 == "")         return "no checker name"
      if ($1 !~ /^[a-z][a-z0-9_-]*$/) return "[" $1 "] is not a checker name: a lowercase letter, then lowercase letters, digits, _ or -"
      if (NF < 5)          return NF " field(s); a control needs five"
      if (NF > 6)          return NF " field(s); a control has five, or six with a premise"
      if ($5 == "")        return "no mutation"
      if (!($3 in want))   return "[" $3 "] is not one of the six controls"
      if ($4 != want[$3])  return $3 " must expect " want[$3] ", not [" $4 "]"
      return ""
    }
    $0 ~ /^[[:space:]]*#/ || $0 ~ /^[[:space:]]*$/ { next }
    '"$2" "$f"
}

felix_qualify_rows() { _felix_qualify_read "$1" 'why() == "" { print }'; }

# A row that is not a control: no checker, or a checker that is not an id, a
# carriage return, too short to run or too long to be one, no mutation, a
# control that is not one of the six, or a verdict that is not the control's.
# Reported and never run. A malformed row is a control nobody is applying, and silence about it
# reads as a control that passed; running it is how a violation expecting
# `pass` came to be met. `felix qualify --gate` refuses on any.
felix_qualify_malformed() { _felix_qualify_read "$1" '(r = why()) != "" { print $1 "\t" r }'; }

# Both lists from one read, each line tagged: R and the row for a control, M
# and `checker <TAB> why` for a row that is not one. felix qualify read the
# table four times and more in one run (the rows, the malformed rows, the rows
# it ran, each checker's controls) and read the status of the first alone. A
# later read that failed, or a table rewritten between reads, ran no control,
# and 0 of 0 held passed the gate over a checker with a held control. One read
# leaves no later one to fail unseen and no second table to disagree with.
felix_qualify_snapshot() {
  _felix_qualify_read "$1" '(r = why()) == "" { print "R\t" $0; next } { print "M\t" $1 "\t" r }'
}

# A table that exists and cannot be read is said, and resolves nothing. Until
# 2026-09-25 awk's "can't open file" went to a stderr every caller discards and
# its status was never read, so a qualification.tsv at mode 000 read as one that
# declares nothing: every control missing, every reported checker unqualified,
# every capability absent, each a claim about a table nobody read. Every reader
# in this file that answers for a table (felix_qualify_missing_controls,
# felix_qualify_run, felix_qualify_ungoverned) and felix qualify's own read take
# the read's status from an assignment of its own, never from a pipeline, whose
# status without pipefail is only its last command's. On a failed read the
# three readers run and print nothing, say this one line, and exit 2; felix
# qualify runs nothing, prints its header, this line and one saying nothing was
# run, and exits 2. A table that does not exist is still an answer, and
# declares nothing, as before.
_felix_qualify_unread() {   # proj
  local f; f="$(_felix_qualify_table "$1")"
  printf 'felix: %s could not be read, so what it declares is not known\n' "$f" >&2
}

# Which controls a checker has no row for. A checker qualified on four of six
# is not qualified; the amendments say all seven hold or it may not enforce, and
# the two it is missing are usually the two with teeth.
#
# Membership is a case over the whole list, in the shell. It was printf into
# grep -qxF, and grep -q leaves on its first match; bash 3.2's printf writes a
# list one write() per line, so a printf still writing died of SIGPIPE, and
# under pipefail, which the felix CLI and the suite both set, `||` named a
# control the checker declares. Measured 2026-09-25 on a Mac at load 200: 47
# false `short` resolutions of the suite's needs fixture in two minutes of
# twelve loops, and five runs of five once a checker's rows outgrow a pipe,
# because the writer then has to block. Nothing here may pipe a list into a
# reader that can stop before the end of it: grep -q, head, awk's exit, sed q.
felix_qualify_missing_controls() {   # proj, checker -> one control per line
  local proj="$1" checker="$2" rows
  rows="$(felix_qualify_rows "$proj" 2>/dev/null)" || { _felix_qualify_unread "$proj"; return 2; }
  _felix_qualify_missing_in "$rows" "$checker" || { _felix_qualify_unread "$proj"; return 2; }
}

# The same over rows already read, so felix qualify asks it of the one read it
# made rather than reading the table again per checker. Returns non-zero,
# printing nothing, when the controls could not be picked out of the rows.
_felix_qualify_missing_in() {   # rows, checker -> one control per line
  local rows="$1" checker="$2" have c missing="" nl='
'
  # awk reads to the end of its input, so the printf feeding it always finishes.
  have="$(printf '%s\n' "$rows" | awk -F'\t' -v k="$checker" '$1 == k { print $3 }')" || return 1
  for c in $FELIX_QUALIFY_CONTROLS; do
    case "$nl$have$nl" in
      *"$nl$c$nl"*) ;;
      *) missing="$missing$c$nl" ;;
    esac
  done
  printf '%s' "$missing"
}

# Run one row: a real worktree of HEAD, the mutation applied to it, the checker
# run in it, the tree thrown away.
#
# A worktree rather than a copy, because a checker may read git — history, what
# is tracked, what is ignored — and a bare directory of files would make every
# such checker fail for a reason that has nothing to do with the mutation. It
# shares the object store, so this costs a checkout and not a clone.
_felix_qualify_one() {   # root, command, mutation, [premise] -> pass | fail | unrunnable | inapplicable
  local root="$1" cmd="$2" mut="$3" premise="${4:-}" base scratch got prc
  base="$(mktemp -d 2>/dev/null)" || { printf 'unrunnable'; return 0; }
  scratch="$base/w"
  if ! git -C "$root" worktree add --detach -q "$scratch" HEAD 2>/dev/null; then
    rmdir "$base" 2>/dev/null; printf 'unrunnable'; return 0
  fi
  got=""
  if [ -n "$premise" ] && [ "$premise" != "-" ]; then
    ( cd "$scratch" && eval "$premise" ) </dev/null >/dev/null 2>&1; prc=$?
    case "$prc" in
      0) : ;;
      1) got=inapplicable ;;
      *) got=unrunnable ;;
    esac
  fi
  if [ -z "$got" ]; then
    # The mutation may legitimately fail (a control whose point is that the tree
    # already satisfies the obligation), so its status is not the verdict.
    #
    # Neither is given anything to read, as the premise is not. Both inherited
    # the pipe the rows arrived on, and a checker that read to the end of its
    # stdin took every row after its own with it: a met row and a held one ran
    # the met one alone, and the gate counted one control met of one. Nor may
    # a command that reads stdin wait on a terminal under felix gate.
    ( cd "$scratch" && eval "$mut" ) </dev/null >/dev/null 2>&1
    if ( cd "$scratch" && eval "$cmd" ) </dev/null >/dev/null 2>&1; then got=pass; else got=fail; fi
  fi
  git -C "$root" worktree remove --force "$scratch" >/dev/null 2>&1
  rmdir "$base" 2>/dev/null
  printf '%s' "$got"
}

# Emits: checker <TAB> control <TAB> expect <TAB> got <TAB> met|held|unrunnable|inapplicable
#
# An inapplicable row's got is `-`: nothing ran, so there is no pass or fail to
# report, and printing the expected word there would read as a result.
#
# The rows are read once, with the read's status taken from its own assignment.
# They were piped into the loop, so the status was the loop's: with the
# caller's pipefail a table that could not be read said 2, and without it said
# 0 having run nothing, the empty run of a table that declares nothing.
felix_qualify_run() {   # proj, root, [checker]
  local rows
  rows="$(felix_qualify_rows "$1" 2>/dev/null)" || { _felix_qualify_unread "$1"; return 2; }
  _felix_qualify_run_rows "$rows" "$2" "${3:-}"
}

# The loop, over rows already read. felix qualify hands it the rows of its one
# read, so what it runs is what it counts.
#
# The rows are walked in the shell, off the string, rather than piped or
# redirected in: nothing in the loop body can read them, and there is no pipe
# for a command to drain (the stdin note in _felix_qualify_one).
#
# Fields are cut by parameter expansion on the tab, not a tab IFS: the premise
# column is optional, and a tab IFS hands a missing sixth field and an empty
# one the same way only by luck. Not by cut either, which was a fork per field:
# a fork that failed emptied the field, an empty checker skipped the row, and
# an empty command ran `eval ""`, which passes. The rows come from the reader,
# which passes only a row of five fields or more, so four tabs are there; a
# line without them is not run, and felix qualify --gate counts it as a row
# that did not run.
_felix_qualify_run_rows() {   # rows, root, [checker]
  local rest="$1" root="$2" want="${3:-}" line f
  local checker cmd control expect mut premise got verdict nl='
' tab='	'
  while [ -n "$rest" ]; do
    line="${rest%%"$nl"*}"
    case "$rest" in *"$nl"*) rest="${rest#*"$nl"}" ;; *) rest="" ;; esac
    case "$line" in *"$tab"*"$tab"*"$tab"*"$tab"*) ;; *) continue ;; esac
    f="$line"
    checker="${f%%"$tab"*}"; f="${f#*"$tab"}"
    [ -n "$checker" ] || continue
    [ -z "$want" ] || [ "$want" = "$checker" ] || continue
    cmd="${f%%"$tab"*}";     f="${f#*"$tab"}"
    control="${f%%"$tab"*}"; f="${f#*"$tab"}"
    expect="${f%%"$tab"*}";  f="${f#*"$tab"}"
    mut="${f%%"$tab"*}"
    case "$f" in
      *"$tab"*) f="${f#*"$tab"}"; premise="${f%%"$tab"*}" ;;
      *)        premise="" ;;
    esac
    got="$(_felix_qualify_one "$root" "$cmd" "$mut" "$premise")"
    case "$got" in
      unrunnable)   verdict=unrunnable ;;
      inapplicable) verdict=inapplicable; got=- ;;
      "$expect")    verdict=met ;;
      *)            verdict=held ;;
    esac
    printf '%s\t%s\t%s\t%s\t%s\n' "$checker" "$control" "$expect" "$got" "$verdict"
  done
}

# Checkers never shown failing here: at least one control expects `fail`, and
# every such control came back inapplicable. A checker with no fail-expecting
# row at all is not named — felix_qualify_missing_controls already says which
# controls it lacks — and one whose fail control held is already a red gate.
felix_qualify_unshown() {   # proj, run-output -> one checker name per line
  printf '%s\n' "$2" | LC_ALL=C awk -F'\t' '
    NF >= 5 && $3 == "fail" {
      if (!($1 in seen)) { seen[$1] = 1; order[++n] = $1 }
      if ($5 != "inapplicable") applied[$1] = 1
    }
    END { for (i = 1; i <= n; i++) if (!(order[i] in applied)) print order[i] }'
}

# The gap: a name the gate prints that no row qualifies.
#
# Read from the gate rather than from a list, so a check added to the gate and
# not to this table is a gap the moment it lands. A list would have to be kept
# in step by whoever remembered.
#
# A checker line is exactly two spaces, a lowercase name, then a verdict word,
# whatever the word: the gate prints ok, FAIL, skipped, stale and waits today,
# and the first draft here listed three of them. The indent is part of the
# shape, not decoration: given a real gate log, a rule on the two words alone
# also took `a` and `drift` from the prose the gate prints under a failure.
# Sub-lines are indented deeper, and prose is not indented at all.
#
# Membership is the case felix_qualify_missing_controls uses, for its reason:
# the same printf into grep -qxF stood here against every checker the table
# declares, and named one that has rows whenever grep found it before the
# printf was done. A name is [a-z][a-z-]*, so the unquoted list splits cleanly.
# The names are cut in the C locale: BSD cut in a UTF-8 one stops with "Illegal
# byte sequence" at a mutation holding a byte it cannot decode, and a table read
# whole would then be said to be one that could not be read.
felix_qualify_ungoverned() {   # proj, gate-output -> one checker name per line
  local proj="$1" out="$2" rows known c gap="" nl='
'
  rows="$(felix_qualify_rows "$proj" 2>/dev/null)" || { _felix_qualify_unread "$proj"; return 2; }
  known="$(printf '%s\n' "$rows" | LC_ALL=C cut -f1)" || { _felix_qualify_unread "$proj"; return 2; }
  for c in $(printf '%s\n' "$out" \
               | LC_ALL=C awk '$0 ~ /^  [a-z][a-z-]* +[A-Za-z]/ { print $1 }' \
               | LC_ALL=C sort -u); do
    case "$nl$known$nl" in
      *"$nl$c$nl"*) ;;
      *) gap="$gap$c$nl" ;;
    esac
  done
  printf '%s' "$gap"
}
