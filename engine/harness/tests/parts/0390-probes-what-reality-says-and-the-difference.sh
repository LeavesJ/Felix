printf '\nprobes: what reality says, and the difference between empty and blind\n'
_unwritable_probe
# The rule, one level stricter than the one procedures.tsv obeys: Felix may
# declare which question to ask reality, and may never author the answer.
#
# The failure class stood at five instances by 2026-09-03, every one of them
# the same shape: a check that reported clean because it found nothing. Three of
# them. A security
# audit named a missing request ceiling and the command built to answer it
# dropped the finding. A governed project WROTE the ceiling check and ended it
# with `exit 0`, so its scanner printed "All gates passed" while naming four
# unlimited services. A vocabulary grep reported a ceiling absent that was
# shipping and armed.
#
# No number of extra checks fixes that. What fixes it is refusing to let "found
# nothing" and "could not look" render the same, which is what every assertion
# below is about.
_probes_build base

_pbtable

_pbrun() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
             . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"; felix_probes_run "$PBP" "$PBR" ); }
_pbstate() { _pbrun | awk -F'\t' -v p="$1" '$1 == p { print $3 }'; }

is "a probe that enumerates members is found"      "$(_pbstate tracked)"     "found"
is "nothing found and a witness agreeing is empty" "$(_pbstate rustcrate)"   "empty"
is "nothing found where a witness proves a surface is blind" \
   "$(_pbstate pyfile)"      "blind"
is "and a probe that failed against a real surface is blind too" \
   "$(_pbstate brokenprobe)" "blind"
is "nothing found with no witness is unknown, never empty" \
   "$(_pbstate nowitness)"   "unknown"
is "a probe whose command does not exist is unknown" "$(_pbstate notool)"    "unknown"
# Members AND a failure. `ls -1 a.txt missing` prints a.txt and exits 1, which
# is a real shape rather than a corner. It cannot be `found`, because the
# enumeration is partial; and it must not be described as a probe that returned
# nothing, because that sentence would be false. A report stating something
# untrue about what it saw is the failure this whole section refuses.
is "a row that does not apply here claims nothing"   "$(_pbstate na)"        "not-applicable"
is "a probe that printed members and then failed is unknown, not found" \
   "$(_pbstate partial)" "unknown"
has "and the report says the enumeration was partial" \
    "$(_pbrun | awk -F'\t' '$1 == "partial" { print $5 }')" "partial"
# Reaching this line at all is the assertion: a probe reading a terminal would
# never return, and the suite would hang here rather than fail.
is "a probe that reads stdin returns instead of hanging the gate" \
   "$(_pbstate readsstdin)" "blind"

# ------------------------------------------------------ the instrument ------
# v3.2 §2 asks a fact to say where it was observed FROM, and §5 makes a provider
# upgrade an invalidation event. Without it the drift reader can say a count
# moved and cannot say why — and "seven more members" reads as the code changing
# when it may be the toolchain changing, which is an hour spent looking for a
# route that was never added.
_pbsrc() { _pbrun | awk -F'\t' -v p="$1" '$1 == p { print $7 }'; }
case "$(_pbsrc tracked)" in
  git@[0-9]*) ok  "a probe naming a real command carries that instrument and a token" ;;
  *)          bad "a probe naming a real command carries that instrument and a token" \
                  "got [$(_pbsrc tracked)]" ;;
esac
# Derived, never declared, so anything that is not a bare command name says so
# rather than having an identity invented from a shell fragment. A real probe
# in a governed project begins with an assignment for exactly this reason.
_pbtable "" 'assigned	-	-	PY=/bin/echo; $PY hello	test -d src'
is "a probe that begins with an assignment identifies no instrument" \
   "$(_pbsrc assigned)" "-"
_pbtable "" 'nosuchtool	-	-	definitely-not-a-real-command-xyz	test -d src'
is "and a command that does not resolve identifies none either" \
   "$(_pbsrc nosuchtool)" "-"
_pbtable


# The distinction stated as the one thing this surface exists for: two rows
# that both enumerated zero members, and only one of them is a fact.
case "$(_pbstate rustcrate):$(_pbstate pyfile)" in
  empty:blind) ok  "zero members is two different answers depending on the witness" ;;
  *)           bad "zero members is two different answers depending on the witness" \
                   "$(_pbstate rustcrate):$(_pbstate pyfile)" ;;
esac

# Blocking is a property of the state, and nothing else may decide it.
_pbblock() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
               . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"; felix_probes_run "$PBP" "$PBR" \
               | felix_probes_blocking | cut -f1 | LC_ALL=C sort | tr '\n' ' ' ); }
is "exactly the states that could not be established block" \
   "$(_pbblock)" "brokenprobe notool nowitness partial pyfile readsstdin "

# The anti-gaming property, and the reason a witness is not optional decoration.
# Dropping the witness from a row that was cleanly `empty` does not make it
# quieter; it makes it blocking, because a probe with nothing to check it
# against cannot tell an absent surface from a broken command.
_pbtable -
is "removing a witness turns a clean empty into a blocking unknown" \
   "$(_pbstate rustcrate)" "unknown"
_pbtable
is "and restoring it makes the row clean again" "$(_pbstate rustcrate)" "empty"

# The residual, asserted rather than only written down. Nothing here catches a
# probe that FABRICATES members: the witness catches a probe that sees too
# little and there is no witness for one that claims too much. Enumeration is
# the weakest joint of any checker and cannot be made behavioural — an
# entrypoint never found is never executed. Pinned so the claim this system
# makes about its own trustworthiness stays true as the code moves.
_pbtable "" 'invented	-	-	printf "ghost1\nghost2\n"	test -d src'
is "a probe that invents its members is indistinguishable from one that found them" \
   "$(_pbstate invented)" "found"

# A row that names a predicate and no command. procedures.tsv had this defect
# inside its own fix: a row recording no judgement still closed a gap and then
# rendered nowhere. Here it must stand for nothing at all.
_pbtable "" 'halfrow	-'
_pbmal() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"
             felix_probe_malformed "$PBP" ); }
has "a row with no command is reported as recording nothing" "$(_pbmal)" "halfrow"
case "$(_pbrun | cut -f1)" in
  *halfrow*) bad "and is not run as though it were a probe" "$(_pbrun | cut -f1)" ;;
  *)         ok  "and is not run as though it were a probe" ;;
esac

# Six fields is malformed rather than generously truncated. A tab inside a
# probe command splits it in two, and reading five of six fields would run a
# command cut off at the tab and check it against the remainder — something
# nobody wrote, checked against something else nobody wrote.
_pbtable "" 'wide	-	-	echo a	test -d src	leftover'
has "a row with more fields than the format has is malformed" "$(_pbmal)" "wide"
case "$(_pbrun | cut -f1)" in
  *wide*) bad "and is not run half-read" "$(_pbrun | cut -f1)" ;;
  *)      ok  "and is not run half-read" ;;
esac

# A five-field row with an empty probe cell. The four-field shape above is
# caught; this one was handed to `bash -c ""`, which exits 0 having
# enumerated nothing, and the verdict then came from the witness alone — a
# witness saying "absent" made it `empty`, which is green.
_pbtable "" 'blankprobe	-	-		test -f Cargo.toml'
has "a row with an empty probe cell is malformed" "$(_pbmal)" "blankprobe"
case "$(_pbrun | cut -f1)" in
  *blankprobe*) bad "and is not run as a probe whose verdict is the witness alone" "$(_pbrun | cut -f1)" ;;
  *)            ok  "and is not run as a probe whose verdict is the witness alone" ;;
esac

# A witness whose command does not exist. 127 was read as "no", so a witness
# spelt `tset -f Cargo.toml` said the surface is absent and a row that should
# have blocked went green as `empty`. 127 says nothing about the surface; it
# says the question could not be asked, and that is `unknown`.
_pbtable "" 'typowitness	-	-	ls -1 Cargo.toml 2>/dev/null	definitely-not-a-real-command-xyz -f Cargo.toml'
is "a witness whose command does not exist makes the row unknown, not empty" \
   "$(_pbstate typowitness)" "unknown"
has "and the row says the witness could not be asked" \
    "$(_pbrun | awk -F'\t' '$1 == "typowitness" { print $5 }')" "witness"

# The same typo in a `when` test switched its row off as not-applicable.
_pbtable "" 'typowhen	-	definitely-not-a-real-command-xyz	ls -1 src/*.rs	test -d src'
is "a when test whose command does not exist makes the row unknown, not not-applicable" \
   "$(_pbstate typowhen)" "unknown"

# A root that cannot be entered is a third thing again, and was being
# reported as a missing command.
_pbtable
_pbroot="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
            . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"
            felix_probes_run "$PBP" "$TMP/no-such-root-at-all" )"
is "a root that cannot be entered makes every row unknown" \
   "$(printf '%s\n' "$_pbroot" | cut -f3 | LC_ALL=C sort -u | tr '\n' ' ')" "unknown "
has "and says the checkout could not be entered rather than naming a missing command" \
    "$_pbroot" "could not be entered"
_pbtable

# ---------------------------------------------------------------- the log ---
# Append-only, with provenance, and it must say so when it did not write.
_pbrec() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
             . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"
             felix_probes_record "$PBP" "$PBR" "$1" "$(felix_probes_run "$PBP" "$PBR")" \
             ) 2>/dev/null; }
_pbrec treeone
is "recording a run succeeds" "$?" "0"
PBLOG="$MEM/probes-proj/facts.log"
is "one line per row is written" \
   "$(grep -c . "$PBLOG" 2>/dev/null)" "$(_pbrun | grep -c .)"
has "each fact carries the tree it was taken from" "$(cat "$PBLOG")" "treeone"
has "and the exact command that produced it"       "$(cat "$PBLOG")" "git ls-files"

# The column order is a CONTRACT, and these two exist because breaking it cost a
# real log. The instrument was first written into column eight, where the probe
# command had always been — so every row already in the append-only log read its
# own command as its instrument, and the first run afterwards reported that
# every predicate on the project had changed instrument. An append-only log
# cannot be re-shaped: the only safe evolution is to add a column at the end.
is "the probe command stays in the eighth column" \
   "$(awk -F'\t' '$3 == "tracked" { print $8 }' "$PBLOG" | tail -1)" "git ls-files"
case "$(awk -F'\t' '$3 == "tracked" { print $9 }' "$PBLOG" | tail -1)" in
  git@[0-9]*) ok  "and the instrument is appended as the ninth" ;;
  *)          bad "and the instrument is appended as the ninth" \
                  "got [$(awk -F'\t' '$3 == "tracked" { print $9 }' "$PBLOG" | tail -1)]" ;;
esac
is "an established fact is classed OBSERVED" \
   "$(awk -F'\t' '$3 == "tracked" { print $4 }' "$PBLOG" | head -1)" "OBSERVED"
is "and one nothing established is classed UNKNOWN" \
   "$(awk -F'\t' '$3 == "nowitness" { print $4 }' "$PBLOG" | head -1)" "UNKNOWN"
PBN1="$(grep -c . "$PBLOG")"
_pbrec treetwo
is "a second run appends rather than replacing" \
   "$(grep -c . "$PBLOG")" "$((PBN1 * 2))"
has "so the earlier tree is still readable" "$(cat "$PBLOG")" "treeone"

# #84's shape exactly: felix budget --record reported success when its append
# failed and the ceiling silently became no ceiling. A fact log that can lose a
# row while reporting a clean run is worse than no log, because it is trusted.
if [ "$_unwritable" -eq 1 ]; then
  chmod 444 "$PBLOG"
  _pbrec treethree
  PBRC="$?"
  chmod 644 "$PBLOG"
  is "an append that did not happen is reported as a failure" "$PBRC" "1"
else
  skip "an append that did not happen is reported as a failure" "$_nowrite"
fi

# The case the count exists for, and the only one the exit status cannot see:
# a path that stopped being a file. `>>` to it succeeds, reports success, and
# grows nothing — every row computed, every row lost, and a clean status.
rm -f "$PBLOG"; ln -s /dev/null "$PBLOG"
_pbrec treefour
PBRC2="$?"
rm -f "$PBLOG"
is "an append that succeeded and wrote nothing is reported as a failure too" \
   "$PBRC2" "1"

# A path that stopped being a file the other way: the log is now a directory,
# and nothing can be appended to it.
mkdir "$PBLOG"
_pbrec treefive
PBRC3="$?"
rmdir "$PBLOG"
is "a log replaced by a directory is reported as a failure" "$PBRC3" "1"

# Two gates of one project at once, from two worktrees or clones, append to one
# facts.log. The write used to be verified by the file's growth, so each run
# counted the other's rows as its own and reported a failed write although
# every row had landed. On 2026-09-23 that failed `felix probes --gate` in both
# gates.
#
# The overlap is forced, not left to timing. The append loop calls `cut` for
# every field, and nothing else in the function calls it, so each writer's
# `cut` holds it. The first holds at its first field until the second has a row
# in the log. The second holds after its own first row until the first has one.
# Each append window then contains a row of the other writer's, however loaded
# the machine is. The stamp is pinned to one second, and the second pair shares
# a tree id: stamp and tree are the same in both writers' rows, so neither
# column can tell whose row is whose.
PBC="$TMP/probes-concurrent"; mkdir -p "$PBC"
PBCLOG="$MEM/probes-concurrent/facts.log"
_pbchas() { awk -F'\t' -v p="$1" 'index($3, p) == 1 { f = 1 } END { exit !f }' "$PBCLOG" 2>/dev/null; }
_pbcwait() {   # <command...>: until it holds, or once ten seconds are gone
  local i=0
  until "$@"; do
    [ ! -e "$PBC/gave-up" ] || return 1
    i=$((i + 1)); [ "$i" -le 200 ] || { : > "$PBC/gave-up"; return 1; }
    sleep 0.05
  done
}
_pbcwriter() {   # <a|b> <tree id>
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
    . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"
    date() { printf '2026-09-23T00:00:00Z\n'; }
    if [ "$1" = a ]; then
      cut() { : > "$PBC/a.in"; _pbcwait _pbchas b; command cut "$@"; }
    else
      cut() { _pbcwait test -e "$PBC/a.in"; _pbchas b && _pbcwait _pbchas a; command cut "$@"; }
    fi
    felix_probes_record "$PBC" "$PBR" "$2" "$(printf '%s1\t-\tfound\t1\tone\tgit ls-files\tgit@1\n%s2\t-\tfound\t2\ttwo\tgit ls-files\tgit@1\n' "$1" "$1")"
  ) 2>/dev/null
}
_pbcpair() {   # <tree a> <tree b> -> "<a's status> <b's status>"
  local pa pb ra
  rm -f "$PBCLOG" "$PBC/a.in" "$PBC/gave-up"
  _pbcwriter a "$1" & pa=$!
  _pbcwriter b "$2" & pb=$!
  wait "$pa"; ra=$?
  wait "$pb"; printf '%s %s' "$ra" "$?"
}
# Whether the windows overlapped: the other writer's first row came before this
# one's last, both ways. Without it, a loop that stopped calling `cut` would let
# both writers run one after the other and pass here for the wrong reason.
_pbcinterleaved() {
  awk -F'\t' '
    { c = substr($3, 1, 1) }
    c == "a" { if (!fa) fa = NR; la = NR }
    c == "b" { if (!fb) fb = NR; lb = NR }
    END { exit !(fa && fb && fb < la && fa < lb) }' "$PBCLOG" 2>/dev/null
}

is "two writers appending to one facts.log at once both report success" \
   "$(_pbcpair treea treeb)" "0 0"
_pbcinterleaved && ok "and their rows interleaved, so each append window held the other's rows" \
                || bad "and their rows interleaved, so each append window held the other's rows" "$(cat "$PBCLOG" 2>/dev/null)"
is "and all four rows landed" "$(grep -c . "$PBCLOG" 2>/dev/null)" "4"
is "two writers on one tree in one second both report success too" \
   "$(_pbcpair treeab treeab)" "0 0"
_pbcinterleaved && ok "and their rows interleaved too" \
                || bad "and their rows interleaved too" "$(cat "$PBCLOG" 2>/dev/null)"

# -------------------------------------------------------------- the drift ---
# The log exists to be read. A log nothing reads is procedures.tsv one level
# down: rows accumulating forever while nothing consults them.
#
# What it catches that nothing else does is a count that FELL. `hook_binding`
# going from eight to six is a floor that stopped running for two events, and
# nothing anywhere greps for a hook that was deleted — absence has no line
# number. That sentence is only available to something holding both numbers.
#
# It reports and never blocks, and that is the specification rather than
# timidity: relations produce facts, not obligations. The states already block
# where blocking is right, and a member going away can be somebody deleting a
# file on purpose.
PBD="$TMP/probes-drift"; mkdir -p "$PBD" "$MEM/probes-drift"
_pbdtable() {
  { printf 'one\t-\t-\t%s\ttest -e .git\n' "${1:-git ls-files}"
    printf 'two\t-\t-\tls -1 src\ttest -d src\n'
    [ -n "${2:-}" ] && printf '%s\n' "$2"
  } > "$PBD/probes.tsv"
}
_pbdrec() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
              . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"
              felix_probes_record "$PBD" "$PBR" "$1" "$(felix_probes_run "$PBD" "$PBR")" ) 2>/dev/null; }
_pbdrift() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
               . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"
               felix_probes_drift "$PBD" "$1" "$(felix_probes_run "$PBD" "$PBR")" ); }

_pbdtable
is "with nothing on record there is nothing to compare" "$(_pbdrift alpha | grep -c .)" "0"
# No tree id is not "no drift". A run that cannot be placed against any other
# used to fall silent here, which rendered exactly like a tree that had not
# moved.
has "a run with no tree id says nothing was compared" "$(_pbdrift '')" "no tree id"
_pbdrec alpha
# The same tree is not a comparison. Comparing a tree with itself would report
# that nothing ever changes, which is the most confident wrong answer available.
is "a run compared against its own tree reports nothing" "$(_pbdrift alpha | grep -c .)" "0"

# Fewer members. The signal the whole log exists for.
_pbdtable 'git ls-files | head -1'
has "a predicate with fewer members than the last tree is named" \
    "$(_pbdrift beta)" "one"
has "and the report says how many fewer" \
    "$(_pbdrift beta)" "fewer than on the last tree"
# The row that did not move must not appear. A drift report that lists
# everything is a report nobody reads.
case "$(_pbdrift beta | cut -f1)" in
  *two*) bad "while a predicate that did not move is silent" "$(_pbdrift beta)" ;;
  *)     ok  "while a predicate that did not move is silent" ;;
esac
_pbdrec beta

# More members is the pre-deploy question in the other direction: a route
# appeared on a service that is about to ship.
_pbdtable
has "a predicate with more members than the last tree is named too" \
    "$(_pbdrift gamma)" "more than on the last tree"
_pbdrec gamma

# A state change outranks a count change, because `found` becoming `blind` is
# not a smaller number, it is a surface nobody can see any more.
_pbdtable 'git ls-files "*.nothing"'
has "a predicate whose state changed is reported as a state change" \
    "$(_pbdrift delta)" "the state changed"
_pbdrec delta

# A predicate nothing had recorded is new rather than missing.
_pbdtable "" 'three	-	-	git ls-files	test -e .git'
has "a predicate with no prior record is named as new" "$(_pbdrift epsilon)" "three"

# And the other direction: something that was being read here and no row reads
# now. Reported, not blocked — probes.tsv is in the escape set, so shrinking it
# already stops a merge for a person to look at, and a second stop here could be
# waited out by running the command twice.
printf 'two\t-\t-\tls -1 src\ttest -d src\n' > "$PBD/probes.tsv"
has "a predicate that was being read and no longer is gets named" \
    "$(_pbdrift epsilon)" "one"
has "and says so plainly" "$(_pbdrift epsilon)" "no row reads it now"

# The instrument, reported before anything about the numbers: a count that moved
# because the tool was replaced is a different fact from one that moved because
# the project did.
_pbdtable
_pbdrec eta
printf '%s\tolderTree\tone\tOBSERVED\tfound\t2\t-\tgit ls-files\tgit@999\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$MEM/probes-drift/facts.log"
has "a predicate whose instrument changed says so" "$(_pbdrift theta)" "the instrument changed"
has "and names both tokens"                        "$(_pbdrift theta)" "git@999"

# An append-only log holds rows written before instruments existed. Those have
# eight fields, and a reader that treated the eighth as an instrument would
# report that every predicate had changed instrument on the first run after the
# change. That happened, on the real log, and it is why the column was appended.
printf '%s\toldFormat\tone\tOBSERVED\tfound\t2\t-\tgit ls-files\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$MEM/probes-drift/facts.log"
case "$(_pbdrift theta)" in
  *"instrument changed"*) bad "a row written before instruments existed claims none" \
                              "$(_pbdrift theta)" ;;
  *)                      ok  "a row written before instruments existed claims none" ;;
esac

# A count that cannot be read must not render as a count that did not move.
# This file's own failure class, appearing inside its own reader: `[ a -gt b ]`
# on a non-number errors, the error goes to /dev/null, and the false status
# falls through every branch into silence.
_pbdtable
printf '%s\tsometree\tone\tOBSERVED\tfound\tnotanumber\t-\techo\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$MEM/probes-drift/facts.log"
has "a count that is not a number is reported rather than passed over" \
    "$(_pbdrift zeta)" "not a number"

# --------------------------------------------------------------- the gaps ---
# Enumerated by felix_detect, not by this table. A gap list Felix wrote cannot
# report the gap Felix did not think of.
_pbgaps() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
              . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"; felix_probes_gaps "$PBP" "$PBR" ); }
has "a surface the checkout has and no probe reads is a gap" "$(_pbgaps)" "ci"
_pbtable "" 'workflow	ci	-	git ls-files ".github/workflows/*"	test -d .github/workflows'
case "$(_pbgaps)" in
  *ci*) bad "and grounding it closes the gap" "$(_pbgaps)" ;;
  *)    ok  "and grounding it closes the gap" ;;
esac
# The other direction. A table is wrong when it lacks a row reality has and
# equally wrong when it keeps one reality dropped.
_pbtable "" 'ghostprobe	billing	-	echo x	test -d src'
_pborph() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
              . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"; felix_probes_orphans "$PBP" "$PBR" ); }
has "a probe grounding a surface nothing enumerates is named" "$(_pborph)" "billing"
_pbtable "" 'workflow	ci	-	git ls-files ".github/workflows/*"	test -d .github/workflows'
case "$(_pborph)" in
  *ci*) bad "and one grounding a real surface is not" "$(_pborph)" ;;
  *)    ok  "and one grounding a real surface is not" ;;
esac
_pbtable

# ------------------------------------------------------- the empty refusal ---
# procedures.tsv shipped to three projects, none of them ever wrote one, and no
# gate ever called felix procedures — so a surface built to report gaps reported
# nothing, forever, and read exactly like a project with no gaps. This is that
# refused in three places, asserted separately, because a refusal that exists in
# one place is a refusal somebody routes around.
_probes_build empty
_pbnorows() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"
                felix_probe_rows "$PBE" ); }
is "a project with no probes.tsv declares no probes" "$(_pbnorows | grep -c .)" "0"

# One: the command itself. On a project of its own, because widget carries a
# table like every project felix new creates, and the case under test is a
# project that has none.
_probes_build bare

