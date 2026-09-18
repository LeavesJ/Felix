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
# REPORT ONLY. Nothing here refuses anything, and that is deliberate rather than
# unfinished: arming this — refusing to let an unqualified checker enforce —
# turns every gate red on the day it lands, and how much Felix may block is a
# founder's decision, not a session's. What this does is make the gap visible,
# which is the step that does not need the decision.
#
# The mutations must be authored by something that has not seen the checker
# (amendments 2.2). That is load-bearing and unverifiable from here: whoever
# writes both writes mutations its own checker survives. The table records who
# authored each row so the claim is at least legible; it cannot be enforced.

FELIX_QUALIFY_CONTROLS='violation restoration irrelevant alternate decoupled_violation decoupled_satisfaction'

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

felix_qualify_rows() {
  local f; f="$(_felix_qualify_table "$1")"
  [ -f "$f" ] || return 0
  LC_ALL=C awk -F'\t' 'NF >= 5 && $1 !~ /^[[:space:]]*#/ && $1 != "" && $5 != ""' "$f"
}

# A row that names a checker and not enough to run anything. Reported, never
# skipped: a malformed row is a control nobody is applying, and silence about it
# reads as a control that passed.
felix_qualify_malformed() {
  local f; f="$(_felix_qualify_table "$1")"
  [ -f "$f" ] || return 0
  LC_ALL=C awk -F'\t' '$1 !~ /^[[:space:]]*#/ && $1 != "" && (NF < 5 || $5 == "") { print $1 "\t" NF }' "$f"
}

felix_qualify_checkers() { felix_qualify_rows "$1" | cut -f1 | LC_ALL=C sort -u; }

# Which controls a checker has no row for. A checker qualified on four of six
# is not qualified; the amendments say all seven hold or it may not enforce, and
# the two it is missing are usually the two with teeth.
felix_qualify_missing_controls() {
  local proj="$1" checker="$2" c have
  have="$(felix_qualify_rows "$proj" | awk -F'\t' -v k="$checker" '$1 == k { print $3 }')"
  for c in $FELIX_QUALIFY_CONTROLS; do
    printf '%s\n' "$have" | grep -qxF "$c" || printf '%s\n' "$c"
  done
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
    ( cd "$scratch" && eval "$mut" ) >/dev/null 2>&1
    if ( cd "$scratch" && eval "$cmd" ) >/dev/null 2>&1; then got=pass; else got=fail; fi
  fi
  git -C "$root" worktree remove --force "$scratch" >/dev/null 2>&1
  rmdir "$base" 2>/dev/null
  printf '%s' "$got"
}

# Emits: checker <TAB> control <TAB> expect <TAB> got <TAB> met|held|unrunnable|inapplicable
#
# An inapplicable row's got is `-`: nothing ran, so there is no pass or fail to
# report, and printing the expected word there would read as a result.
felix_qualify_run() {
  local proj="$1" root="$2" want="${3:-}"
  local checker cmd control expect mut premise got verdict
  # Read with cut, not a tab IFS: the premise column is optional, and a tab IFS
  # hands a missing sixth field and an empty one the same way only by luck.
  felix_qualify_rows "$proj" | while IFS= read -r line; do
    checker="$(printf '%s\n' "$line" | cut -f1)"
    [ -n "$checker" ] || continue
    [ -z "$want" ] || [ "$want" = "$checker" ] || continue
    cmd="$(printf '%s\n' "$line" | cut -f2)"
    control="$(printf '%s\n' "$line" | cut -f3)"
    expect="$(printf '%s\n' "$line" | cut -f4)"
    mut="$(printf '%s\n' "$line" | cut -f5)"
    premise="$(printf '%s\n' "$line" | awk -F'\t' 'NF >= 6 { print $6 }')"
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
felix_qualify_ungoverned() {   # proj, gate-output -> one checker name per line
  local proj="$1" out="$2" known
  known="$(felix_qualify_checkers "$proj")"
  printf '%s\n' "$out" \
    | LC_ALL=C awk '$0 ~ /^  [a-z][a-z-]* +[A-Za-z]/ { print $1 }' \
    | LC_ALL=C sort -u \
    | while IFS= read -r c; do
        [ -n "$c" ] || continue
        printf '%s\n' "$known" | grep -qxF "$c" || printf '%s\n' "$c"
      done
}
