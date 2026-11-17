# After the second review, not blind: the places a read list still passed through a
# substitution that can come back empty, a here-document, or a hash read twice.
#
# Two Opus reviewers (defeat, simpler) read the after-review fixes at 4ccc9e09 and
# each demonstrated what follows. These assertions were NOT written blind: they
# were written after the review, from its evidence, and each one that can fail
# was shown failing against 4ccc9e09, the engine this change is a fix to, before
# it was shown passing. Every item is named at the paragraph that opens it.
# A command that is another process (the CLI) is run with a stub first on PATH:
# a grep that execs the real one except when an argument is -c, where it prints
# nothing and exits 2, and a tr that execs the real one except for tr '\n' ' ',
# where it prints nothing and exits 1. That is what a substitution whose fork or
# pipe failed looks like from the line that reads it. Nothing reaches the network,
# ~/.claude or an installed CLI, and nothing here runs a gate.
# Everything this makes is removed below and everything it defines unset.
_durefixture() { { find "$FROOT/projects" "$FROOT/state" "$MEM" 2>/dev/null | LC_ALL=C sort
                   find "$FROOT/projects" "$FROOT/state" "$MEM" -type f -exec cksum {} + 2>/dev/null | LC_ALL=C sort; } | cksum; }
_durefound="$(_durefixture)"
_duredirs="$(find "$FROOT/state" -type d 2>/dev/null)"
_durep="$FROOT/projects/dureproj"; _durer="$TMP/dure-repo"; _durehome="$TMP/dure-home"
_durebin0="$TMP/dure-bin0"; _duregrep="$TMP/dure-nogrepc"; _duretr="$TMP/dure-notr"; _duregit="$TMP/dure-git"
_duretpl="$FROOT/harness/templates"
mkdir -p "$_durep" "$_durer/tests" "$_durehome/.claude/plugins" "$_durebin0" "$_duregrep" "$_duretr" "$_duregit"
# The CLI, the hook and the readers below run under a PATH narrowed to a stub directory (or none) and /usr/bin:/bin,
# so that no claude is found and a stub grep or tr comes first; that PATH alone would also hand them /usr/bin/git. On
# a Mac that is Xcode's shim, which exits 69 on every call from an Xcode update until its licence is accepted, and
# seven assertions here then fail. So $_duregit holds one link, to the git the rest of the suite runs, ahead of /usr/bin.
[ -z "$(type -P git)" ] || ln -sf "$(type -P git)" "$_duregit/git"
printf '{\n  "name": "dureproj",\n  "remote_match": "example.com/dureproj",\n  "gate": "true"\n}\n' > "$_durep/project.json"
printf '# dureproj\n' > "$_durep/CLAUDE.md"
# Detected: secrets (.env.example), tests (tests/) and deploy (Dockerfile).
# Declared: secrets, and durebill and durecap, which nothing detects. So the five
# items are deploy, durebill, durecap, secrets and tests, and the two surfaces
# nobody declared are deploy and tests.
( _fx_cd "$_durer" && git init -q -b main && git config remote.origin.url https://github.com/example.com/dureproj && printf 'dureproj\n' > .felix && printf 'X=1\n' > .env.example \
    && printf 'ok\n' > tests/t && printf 'FROM x\n' > Dockerfile && git add -A \
    && git -c user.name=dure -c user.email=dure@example.com commit -q -m dure )
_durer="$(cd "$_durer" && pwd -P)"
printf 'secrets\ndurebill\ndurecap\n' > "$_durep/capabilities"
_durerealgrep="$(command -v grep)"; _dureretr="$(command -v tr)"
cat > "$_duregrep/grep" <<STUB
#!/bin/sh
for a in "\$@"; do [ "\$a" = -c ] && exit 2; done
exec $_durerealgrep "\$@"
STUB
cat > "$_duretr/tr" <<STUB
#!/bin/sh
[ "\$1" = '\\n' ] && [ "\$2" = ' ' ] && exit 1
exec $_dureretr "\$@"
STUB
chmod +x "$_duregrep/grep" "$_duretr/tr"
# $1 is the stub directory first on PATH (bin0 holds none), the rest is the command.
# Prints its output and then [exit N], so a status is part of what is compared.
_durecli() { local _durebin="$1"; shift
  ( cd "$_durer" && HOME="$_durehome" PATH="$_durebin:$_duregit:/usr/bin:/bin" "$FELIX" "$@" 2>&1; printf '[exit %s]' "$?" ); }
_duresays() { case "$1" in *"$2"*) printf 'said\n' ;; *) printf 'silent\n' ;; esac; }
# The lines of $1 that begin with $2, joined by a bar.
_durelines() { printf '%s\n' "$1" | awk -v p="$2" 'index($0, p) == 1 { printf "%s%s", (n++ ? "|" : ""), $0 } END { print "" }'; }

# 1. felix procedures counts the lists it has already read in the shell, not through
# a grep -c in a substitution that can come back empty (F1). Until 2026-10-08 the gap
# section and the closing all-clear keyed on ${n_gap:-0}, so a count that came back
# empty read as none and the report said every item had a stance over real gaps.
printf 'capability:secrets\tcommissioning\tdure-check\ta stance on a surface the checkout has\n' > "$_durep/procedures.tsv"
_dureplain="$(_durecli "$_durebin0" procedures)"; _durestub="$(_durecli "$_duregrep" procedures)"
is  "felix procedures over a list it read names the four items with no stance and counts them, without an all-clear" \
    "$(_duresays "$_dureplain" 'nothing answers these') $(_duresays "$_dureplain" '4 of 5 items have no stance') $(_duresays "$_dureplain" 'Every item has a stance')" \
    "said said silent"
is  "and with every grep -c failing it still names them and counts them" \
    "$(_duresays "$_durestub" 'nothing answers these') $(_duresays "$_durestub" 'capability:durebill') $(_duresays "$_durestub" '4 of 5 items have no stance')" \
    "said said said"
is  "and with every grep -c failing it does not say every item has a stance" "$(_duresays "$_durestub" 'Every item has a stance')" "silent"
is  "and prints byte for byte what it prints when grep -c works, the stance section included" "$_durestub" "$_dureplain"
for _duren in deploy durebill durecap secrets tests; do
  printf 'capability:%s\tcommissioning\tdure-check\ta stance on %s\n' "$_duren" "$_duren"
done > "$_durep/procedures.tsv"
_dureplain="$(_durecli "$_durebin0" procedures)"; _durestub="$(_durecli "$_duregrep" procedures)"
is  "felix procedures over a list it read whose every item has a stance says so, and names no gap" \
    "$(_duresays "$_dureplain" 'Every item has a stance') $(_duresays "$_dureplain" 'nothing answers these')" "said silent"
is  "and prints byte for byte the same when every grep -c fails" "$_durestub" "$_dureplain"
rm -f "$_durep/procedures.tsv"

# 2. felix recommend and felix doctor join a list they read by an expansion in this
# shell, not through `| tr '\n' ' '` in a substitution that can come back empty (F2).
# Until 2026-10-08 a join that came back empty read as nothing declared: recommend
# printed `declared: none` and `Felix already detected: nothing yet`, and doctor an
# empty declared line and an empty undeclared one, over a list that was read. The text
# of a read list is as it was, a space after every name included.
_durerec0="$(_durecli "$_durebin0" recommend)"; _durerec1="$(_durecli "$_duretr" recommend)"
_durerecl() { printf '%s|%s' "$(_durelines "$1" 'declared:')" "$(_durelines "$1" '  Project dureproj')"; }
is  "felix recommend over a list it read says what is declared and what Felix already detected, each name followed by a space" \
    "$(_durerecl "$_durerec0")" "declared:   secrets durebill durecap |  Project dureproj, a none codebase. Felix already detected: secrets durebill durecap "
is  "and says the same when every tr '\\n' ' ' fails, not none and not nothing yet" "$(_durerecl "$_durerec1")" "$(_durerecl "$_durerec0")"
is  "and prints byte for byte what it prints when tr works" "$_durerec1" "$_durerec0"
_dured0="$(_durecli "$_durebin0" doctor)"; _dured1="$(_durecli "$_duretr" doctor)"
_duredl() { printf '%s|%s' "$(_durelines "$1" 'declared:')" "$(_durelines "$1" 'undeclared:')"; }
is  "felix doctor over a list it read prints the declared line and the undeclared line, each name followed by a space but the last undeclared one" \
    "$(_duredl "$_dured0")" "declared:     secrets durebill durecap |undeclared:   deploy tests"
is  "and describes each undeclared surface on a line of its own" \
    "$(_durelines "$_dured0" '  deploy ')|$(_durelines "$_dured0" '  tests ')" \
    "  deploy         a deploy target exists; preview and smoke tests apply|  tests          a test suite exists; it belongs in the gate"
is  "and prints the same two lines when every tr '\\n' ' ' fails, not empty ones" "$(_duredl "$_dured1")" "$(_duredl "$_dured0")"
is  "and prints byte for byte what it prints when tr works" "$_dured1" "$_dured0"
rm -f "$_durep/capabilities"
_durerec0="$(_durecli "$_durebin0" recommend)"; _durerec1="$(_durecli "$_duretr" recommend)"
_dured0="$(_durecli "$_durebin0" doctor)"; _dured1="$(_durecli "$_duretr" doctor)"
is  "over no capabilities file recommend says none and nothing yet, and doctor an empty declared line, with tr working or not" \
    "$(_durerecl "$_durerec0")|$(_duredl "$_dured0")|$([ "$_durerec1" = "$_durerec0" ] && [ "$_dured1" = "$_dured0" ] && echo same)" \
    "declared:   none|  Project dureproj, a none codebase. Felix already detected: nothing yet|declared:     |undeclared:   deploy secrets tests|same"
printf 'secrets\ndurebill\ndurecap\n' > "$_durep/capabilities"

# 3. felix_procedures_effective walks the stances as a string in this shell and tests
# the moment by case (F3). Until 2026-10-08 it walked them through a here-document and
# asked felix_has_line, which is another one, and on a bash that writes a here-document
# to a temporary file (3.2 among them) one that cannot be written ended the walk before
# its first stance, so every item with a stance was called a gap. Here-documents are
# made unwritable inside the subshell with an ignored SIGXFSZ and a file size limit of
# nothing; a bash that sends a small one through a pipe passes these and fails only
# where the defect is. A stance at a moment nobody declared still closes nothing.
_dureprun() { local _durem="$1"; shift
  ( cd "$_durer" || exit 99
    set -o pipefail
    HOME="$_durehome"; FELIX_HOME_DIR="$FROOT"; PATH="$_durebin0:$_duregit:/usr/bin:/bin"
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/procedures.sh"
    case "$_durem" in
      nohd) trap '' XFSZ; ulimit -f 0 ;;
    esac
    _dureo="$("$@")"; printf '%s|%s' "$?" "$_dureo" ) 2>/dev/null; }
_durej() { awk '{ printf "%s%s", (NR > 1 ? " " : ""), $0 } END { print "" }'; }
{ printf 'capability:durecap\tcommissioning\tdure-check\ta stance on a declared capability\n'
  printf 'capability:durebill\tpre-lunch\tdure-check\ta stance at a moment nobody declared\n'; } > "$_durep/procedures.tsv"
_dureeff="$(_dureprun w felix_procedures_effective "$_durep" "$_duretpl")"
is  "felix_procedures_effective gives the stance at a declared moment and none at a moment nobody declared" \
    "$_dureeff" "$(printf '0|capability:durecap\tcommissioning\tdure-check')"
is  "and gives the same stances and status when here-documents cannot be written" \
    "$(_dureprun nohd felix_procedures_effective "$_durep" "$_duretpl")" "$_dureeff"
_duregaps="$(_dureprun w felix_procedures_gaps "$_durep" "$_durer" "$_duretpl" | _durej)"
is  "felix_procedures_gaps names the item whose stance is at a moment nobody declared and not the one whose stance is at a declared one" \
    "$_duregaps" "0|capability:deploy capability:durebill capability:secrets capability:tests"
is  "and names the same gaps with the same status when here-documents cannot be written, so no stanced item is called a gap" \
    "$(_dureprun nohd felix_procedures_gaps "$_durep" "$_durer" "$_duretpl" | _durej)" "$_duregaps"
# Added after the check of the fix round, not blind. The round walked the stances in
# this shell in felix_procedures_effective and left felix_procedures_unknown_moments
# and the CLI's stance section on here-documents, so where one could not be written a
# stance at a moment nobody declared vanished from both, and with every other item
# answered the report closed on "Every item has a stance", which before the round it
# did not. Shown failing against the round's head 8b3a6ae9 before it was shown passing.
is  "felix_procedures_unknown_moments names the stance at a moment nobody declared" \
    "$(_dureprun w felix_procedures_unknown_moments "$_durep" "$_duretpl")" "$(printf '0|pre-lunch\tcapability:durebill')"
is  "and names it with the same status when here-documents cannot be written" \
    "$(_dureprun nohd felix_procedures_unknown_moments "$_durep" "$_duretpl")" "$(printf '0|pre-lunch\tcapability:durebill')"
# The CLI is another process: the limit is set in the subshell that starts it, and
# what it says on stderr about a here-document it could not make is not compared.
_durenohdcli() { ( cd "$_durer" || exit 99
    HOME="$_durehome"; PATH="$_durebin0:$_duregit:/usr/bin:/bin"; trap '' XFSZ; ulimit -f 0
    "$FELIX" "$@" 2>/dev/null; printf '[exit %s]' "$?" ); }
for _duren in deploy durebill durecap secrets tests; do
  printf 'capability:%s\tcommissioning\tdure-check\ta stance on %s\n' "$_duren" "$_duren"
done >> "$_durep/procedures.tsv"
_dureplain="$( cd "$_durer" && HOME="$_durehome" PATH="$_durebin0:$_duregit:/usr/bin:/bin" "$FELIX" procedures 2>/dev/null; printf '[exit %s]' "$?" )"
_durenohd="$(_durenohdcli procedures)"
is  "felix procedures with every item answered and one stance at a moment nobody declared names that stance and makes no closing claim" \
    "$(_duresays "$_dureplain" 'stances at a moment nobody declared') $(_duresays "$_dureplain" 'Every item has a stance')" "said silent"
is  "and when here-documents cannot be written it still names that stance and still makes no closing claim" \
    "$(_duresays "$_durenohd" 'stances at a moment nobody declared') $(_duresays "$_durenohd" 'Every item has a stance')" "said silent"
is  "and prints byte for byte what it prints when they can, the stance section included" "$_durenohd" "$_dureplain"
rm -f "$_durep/procedures.tsv"

# 4. The policy version of a table that is a regular file and cannot be read (F4).
# Until 2026-10-08 each table was `cat` with its errors discarded, so one whose mode
# gave no read (cat fails before it prints a byte) hashed exactly as no file at all,
# and as an empty one: the table set could move from a table to nothing and the
# receipt stayed current. The header line is printed for every name whatever it holds,
# so it does not tell an absent file from an empty one either; what tells them apart
# is only what follows it. Mode 000 is readable by root, so the assertions are
# skipped there, and wherever the file is still readable after the chmod.
_durepv="$TMP/dure-pv"; mkdir -p "$_durepv"
_durepol() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/commission.sh"
               felix_commission_policy_version "$_durepv" ) 2>/dev/null; }
printf 'secrets\n' > "$_durepv/capabilities"; chmod 000 "$_durepv/capabilities"
if [ "$(id -u)" -eq 0 ] || [ -r "$_durepv/capabilities" ]; then
  skip "the policy version hashes a table that is there and cannot be read differently from no table and from an empty one" \
       "the table is still readable after chmod 000, as it is for root"
  skip "and differently from the same table when it can be read" "the table is still readable after chmod 000, as it is for root"
else
  _durepolun="$(_durepol)"
  chmod 600 "$_durepv/capabilities"; _durepolrd="$(_durepol)"
  rm -f "$_durepv/capabilities"; _durepolno="$(_durepol)"
  : > "$_durepv/capabilities"; _durepolem="$(_durepol)"
  is  "the policy version hashes a table that is there and cannot be read differently from no table and from an empty one" \
      "$([ "$_durepolun" != "$_durepolno" ] && echo different) $([ "$_durepolun" != "$_durepolem" ] && echo different)" "different different"
  is  "and differently from the same table when it can be read, while no table and an empty one hash as they did" \
      "$([ "$_durepolun" != "$_durepolrd" ] && echo different) $([ "$_durepolno" = "$_durepolem" ] && echo same)" "different same"
fi
chmod 600 "$_durepv/capabilities" 2>/dev/null; rm -f "$_durepv/capabilities"

# 5. Session start names a provider row whose state is unknown with that state's own
# detail, and says nothing else about why (F5). Until 2026-10-08 it kept only the first
# field of each row's state and added a sentence of its own, keyed to a second
# computation of the same topology, so under a transient failure the two disagreed: a
# row unknown for its topology was named with no reason, and a hook whose own topology
# failed over rows that read fine said nothing. The scratch copy of the engine counts
# the calls of felix_commission_topology in a file and fails the one it is told to: the
# hook's own capture is the first, and the row's state is the second. The all-clear is
# the line `Commissioning: receipt`, said once per topology, and is refused while any
# row is unknown or the hook's topology is empty.
_dureeng="$TMP/dure-plugin"; _durecalls="$TMP/dure-calls"
mkdir -p "$_dureeng" "$MEM/dureproj/commission"; cp -R "$FROOT/harness" "$_dureeng/harness"
sed -e 's/^felix_commission_topology() {$/_dure_real_topology() {/' "$_dureeng/harness/lib/commission-provider.sh" > "$_dureeng/prov.new"
cat >> "$_dureeng/prov.new" <<'EOF'
felix_commission_topology() {
  [ -z "${DURE_CALLS:-}" ] || printf x >> "$DURE_CALLS"
  if [ -n "${DURE_CALLS:-}" ] && [ "$(wc -c < "$DURE_CALLS" | tr -d ' ')" = "${DURE_FAIL_CALL:-0}" ]; then return 2; fi
  _dure_real_topology "$@"
}
EOF
cp "$_dureeng/prov.new" "$_dureeng/harness/lib/commission-provider.sh"
# $1 is the plugin root the hook runs from, $2 the call of felix_commission_topology to fail.
_durestart() { local _dureo
  : > "$_durecalls"; rm -f "$FROOT/state/commission/dureproj.seen"
  _dureo="$(cd "$_durer" && HOME="$_durehome" PATH="$_duregit:/usr/bin:/bin" CLAUDE_PLUGIN_ROOT="$1" DURE_CALLS="$_durecalls" DURE_FAIL_CALL="${2:-0}" \
              "$1/harness/hooks/session-start" 2>&1)"
  printf '%s\n' "${_dureo//\\n/$'\n'}"; }
_durecom() { ( cd "$_durer" || exit 99
    set -o pipefail
    HOME="$_durehome"; FELIX_HOME_DIR="$FROOT"; PATH="$_durebin0:$_duregit:/usr/bin:/bin"
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/verify.sh"
    . "$FROOT/harness/lib/commission.sh"; . "$FROOT/harness/lib/commission-provider.sh"
    "$@" ) 2>/dev/null; }
_durewhy='the capabilities this project declares could not be read'
_durans="$MEM/dureproj/commission/automation_surveyed.tsv"
printf 'automation_surveyed\t-\t-\t-\tprovider:dureplug:dureskill\t-\t-\n' > "$_durep/commissioning.tsv"
_duretopo="$(_durecom felix_commission_topology "$_durep" "$_durer")"
{ printf '# topology %s\n' "$_duretopo"; printf 'plugin\tdurenom\t-\tdurecap\ta nomination\n'; printf 'done\t1\n'; } > "$_durans"
_dureold="Commissioning: the topology these answers are keyed to could not be computed"
_durerow="automation_surveyed (unknown: the topology the answer at $_durans is keyed to could not be computed: $_durewhy)"
_durerowk='automation_surveyed (unknown'
_durerow3="automation_surveyed (unknown: the topology the answer at $_durans is keyed to could not be computed"
_dures1="$(_durestart "$FROOT")"
is  "session start over a list it read and a topology that comes back says the all-clear, names no row as unknown and says nothing about a topology" \
    "$(_duresays "$_dures1" 'Commissioning: receipt') $(_duresays "$_dures1" "$_durerowk") $(_duresays "$_dures1" 'could not be computed')" "said silent silent"
rm -f "$_durep/capabilities"; ln -s "$TMP/dure-no-such-list" "$_durep/capabilities"
_dures2="$(_durestart "$FROOT")"
is  "session start over a capabilities link whose target is gone, with an answer file, names the row with the row's own detail" \
    "$(_duresays "$_dures2" "$(printf 'neither owed nor recorded; felix commission --status reads them again:\n  %s' "$_durerow")")" "said"
is  "and says no sentence of its own about the topology, and no all-clear" \
    "$(_duresays "$_dures2" "$_dureold") $(_duresays "$_dures2" 'Commissioning: receipt')" "silent silent"
rm -f "$_durep/capabilities"; printf 'secrets\ndurebill\ndurecap\n' > "$_durep/capabilities"
_dures3="$(_durestart "$_dureeng" 2)"
# The list was read here, so the declared list is not what failed: the capture of the
# topology cannot tell which of its parts did and says the contract's phrase for all of
# them ("Not taken" in the handoff note). What is asserted is the row and its topology,
# not that phrase as the cause.
is  "session start over a list it read, when only the row's own computation of the topology fails, names the row as unknown because its topology could not be computed" \
    "$(_duresays "$_dures3" "$(printf 'neither owed nor recorded; felix commission --status reads them again:\n  %s' "$_durerow3")")" "said"
is  "and says no sentence of its own about the topology, and no all-clear" \
    "$(_duresays "$_dures3" "$_dureold") $(_duresays "$_dures3" 'Commissioning: receipt')" "silent silent"
_dures4="$(_durestart "$_dureeng" 0)"
_dures5="$(_durestart "$_dureeng" 1)"
is  "session start through the engine copy when no call fails says the all-clear and names no row as unknown" \
    "$(_duresays "$_dures4" 'Commissioning: receipt') $(_duresays "$_dures4" "$_durerowk")" "said silent"
is  "and when the hook's own computation of the topology fails over rows that read fine, it says no all-clear, names no row as unknown, and says nothing about a topology" \
    "$(_duresays "$_dures5" 'Commissioning: receipt') $(_duresays "$_dures5" "$_durerowk") $(_duresays "$_dures5" 'could not be computed')" "silent silent silent"
rm -f "$_durep/commissioning.tsv" "$_durans"

# 6. felix_commission_request reads the declared list once, and the topology it writes
# is the one of the list whose names it wrote (F6). Until 2026-10-08 it read the list
# and built the union, and then called felix_commission_topology, which read the list and
# built the union again: two reads, so under a list that moved between them (or a read
# that failed the second time) the names in the request came from one read and its
# topology from another. A felix_declared that counts its calls in a file and gives one
# more capability after the first shows both. The topology of the first list is what the
# request must hold, and the capabilities it names are that list's.
_durecalls2="$TMP/dure-calls2"
_durereq() { local _durem="$1"; shift
  ( cd "$_durer" || exit 99
    set -o pipefail
    HOME="$_durehome"; FELIX_HOME_DIR="$FROOT"; PATH="$_durebin0:$_duregit:/usr/bin:/bin"
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/verify.sh"
    . "$FROOT/harness/lib/commission.sh"; . "$FROOT/harness/lib/commission-provider.sh"
    case "$_durem" in
      moving) felix_declared() { printf x >> "$_durecalls2"
                if [ "$(wc -c < "$_durecalls2" | tr -d ' ')" -le 1 ]; then printf 'secrets\ndurebill\ndurecap\n'
                else printf 'secrets\ndurebill\ndurecap\ndureextra\n'; fi; return 0; } ;;
    esac
    "$@" ) 2>/dev/null; }
_durereqfile="$MEM/dureproj/commission/requests/automation_surveyed.md"
_durefirst="$(_durereq fixed felix_commission_topology "$_durep" "$_durer" 2>/dev/null)"
: > "$_durecalls2"
_durereq moving felix_commission_request "$_durep" "$_durer" automation_surveyed "$_duretpl" >/dev/null
_durereads="$(wc -c < "$_durecalls2" | tr -d ' ')"
_duretopoin="$(sed -n 's/^.*Topology `\([0-9a-f]*\)`.*$/\1/p' "$_durereqfile" | head -n 1)"
_durecapsin="$(sed -n 's/^.*Felix already detected: //p' "$_durereqfile" | head -n 1)"
is  "felix_commission_request reads the declared list once" "$_durereads" "1"
is  "and the request holds the topology of the list whose capabilities it names, not the topology of a second read" \
    "$([ -n "$_duretopoin" ] && [ "$_duretopoin" = "$_durefirst" ] && echo same || echo different) $_durecapsin" \
    "same deploy durebill durecap secrets tests"
rm -f "$_durereqfile" "$_durecalls2"

# 7. What felix_capture drops, and the bytes the topology hashes (F7). These pin the
# two helpers that every reader of the declared list now stands on, and they do not fail
# against 4ccc9e09: they are the assertions its tests lacked.
#
# (a) The one assertion that named felix_capture's trailing newline printed output that
# ends in one, which a capture that dropped every trailing newline satisfies too. Here
# output that ends in two keeps one, and output that ends in three keeps two.
_dureblank() { printf 'a\n\n'; }
_duretriple() { printf 'a\n\n\n'; }
_durecapt() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
                _durev=untouched; felix_capture _durev "$@"; _durecr=$?
                printf '%s|%s|' "$_durecr" "$_durev" ) 2>/dev/null; }
is  "felix_capture drops one trailing newline and not all of them: output ending in two keeps one" \
    "$(_durecapt _dureblank)" "$(printf '0|a\n|')"
is  "and output ending in three keeps two" "$(_durecapt _duretriple)" "$(printf '0|a\n\n|')"
# (b) The topology is the hash of the union a line each, the line `== commissioning.tsv ==`
# and the table, nothing for an empty union and nothing after the line for no table. No
# assertion pinned those bytes, and a topology that moves reads every answer stale. The
# literals were computed with the engine before this change (f2d0e6a5) and with origin/main
# at 6fe5f986, which agree, and the expected hashes are also built here from that layout,
# so the assertion names the layout and not only a number. The checkout shows deploy,
# secrets and tests, and the project declares secrets, durebill and durecap.
_duretp="$TMP/dure-topo"; _dureempty="$TMP/dure-empty"; mkdir -p "$_duretp/none" "$_dureempty"
printf 'secrets\ndurebill\ndurecap\n' > "$_duretp/capabilities"
printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\ndurehash\t-\t-\t-\t-\ttrue\t9\n' > "$_duretp/commissioning.tsv"
( _fx_cd "$_dureempty" && git init -q -b main && printf 'x\n' > .felix && git add -A \
    && git -c user.name=dure -c user.email=dure@example.com commit -q -m dure )
_dureempty="$(cd "$_dureempty" && pwd -P)"
_duretopo1="$(_durecom felix_commission_topology "$_duretp" "$_durer")"
_duretopo2="$(_durecom felix_commission_topology "$_duretp/none" "$_dureempty")"
_dureexp1="$({ printf 'deploy\ndurebill\ndurecap\nsecrets\ntests\n'; printf '== commissioning.tsv ==\n'; cat "$_duretp/commissioning.tsv"; } | git hash-object --stdin)"
_dureexp2="$({ printf '== commissioning.tsv ==\n'; } | git hash-object --stdin)"
is  "felix_commission_topology of a checkout and a project that declare something is the hash of the union a line each, the commissioning.tsv header line and the table" \
    "$_duretopo1" "$_dureexp1"
is  "and of a checkout that shows nothing and a project with no capabilities and no table is the hash of the header line alone" \
    "$_duretopo2" "$_dureexp2"
is  "and the two hashes are the ones the engine before this change gave, abf0d82a and 4eed57d3" \
    "$_duretopo1 $_duretopo2" "abf0d82af4e01e177b725cf9c2432a15aa58e93f 4eed57d3f18d5ffd616035ca5ee3b906a4da1a7b"
rm -rf "$_duretp" "$_dureempty"

rm -rf "$_durep" "$_durer" "$_durehome" "$_durebin0" "$_duregrep" "$_duretr" "$_duregit" "$_durepv" "$_dureeng" "$_durecalls" "$MEM/dureproj"
[ -d "$FROOT/state" ] && find "$FROOT/state" -name '*dureproj*' -exec rm -rf {} + 2>/dev/null
_durenl='
'
find "$FROOT/state" -depth -type d 2>/dev/null | while IFS= read -r _dured; do
  case "$_durenl$_duredirs$_durenl" in *"$_durenl$_dured$_durenl"*) ;; *) rmdir "$_dured" 2>/dev/null ;; esac
done
is  "and the block for the second review's fixes leaves the projects, the state and the memory as it found them" \
    "$(_durefixture)" "$_durefound"
unset -f _durefixture _durecli _durenohdcli _duresays _durelines _durerecl _duredl _dureprun _durej _durepol _durestart _durecom _durereq _dureblank _duretriple _durecapt
unset _durefound _duredirs _durep _durer _durehome _durebin0 _duregrep _duretr _duregit _duretpl _durerealgrep _dureretr \
      _dureplain _durestub _durenohd _duren _durenl _dured _durerec0 _durerec1 _dured0 _dured1 _dureeff _duregaps \
      _durepv _durepolun _durepolrd _durepolno _durepolem _dureeng _durecalls _durewhy _durans _duretopo _dureold \
      _durerow _durerowk _durerow3 _dures1 _dures2 _dures3 _dures4 _dures5 _durecalls2 _durereqfile _durefirst _durereads _duretopoin _durecapsin \
      _duretp _dureempty _duretopo1 _duretopo2 _dureexp1 _dureexp2

# A table command whose last stage succeeds whatever it is fed is refused.
#
# Every table runner evaluates a row with pipefail off: probes, obligations,
# setup and maintenance each start a `bash -c`, and commissioning evaluates
# in-process under `set +o pipefail`, as the section above pins. So a
# pipeline's status is its last stage's, and `npm test 2>&1 | tail -20` reads
# done or SATISFIED when the tests fail, because tail exits 0 whatever it
# reads. lib/final-filter.sh names such a stage, and the four columns where an
# unfailable command reads as a pass refuse the row: commissioning's check,
# obligations' evidence, setup's check and maintenance's check. The columns
# where one only asks more are not judged: a commissioning `when`, an
# obligation's `applies`, and a probe's `when`, probe and witness.
#
# Written blind, from the contract and before the library existed. The
# classifier's cases are the contract's own examples plus one case per filter
# and per condition, and every refusal has an admitted partner near it: a
# false refusal fails a project's gate, where a false admission only leaves
# today's hole, so the admitted half is the one that must not regress. Two
# shapes are red against the engine this replaces, one in each direction:
# commissioning refused any check holding `| head -`, so
# `[ "$(x | head -1)" = y ]` was malformed, and nothing refused
# `x | tail -20 || exit 1`.
#
# The table libraries are sourced the way their neighbours source them, and
# never with final-filter.sh alongside: a table library that assumed its
# classifier was already loaded would admit every row wherever it was not,
# which is the open direction. Every table touched is restored below and
# every helper unset.
_ffT="$(printf '\t')"
_ffc() {   # text -> "<exit>|<what it printed>"
  local _o _r
  _o="$( . "$REAL_HARNESS/lib/final-filter.sh" 2>/dev/null || exit 3
         felix_final_filter "$1" </dev/null 2>/dev/null )"; _r=$?
  printf '%s|%s' "$_r" "$_o"
}
_ffnot() { if [ -e "$1" ]; then printf 'ran\n'; else printf 'not run\n'; fi; }

is  "sourcing lib/final-filter.sh defines felix_final_filter" \
    "$( . "$REAL_HARNESS/lib/final-filter.sh" 2>/dev/null; type -t felix_final_filter )" "function"
_ffo="$( . "$REAL_HARNESS/lib/final-filter.sh" 2>/dev/null || exit 3
         felix_final_filter 'npm test 2>&1 | tail -20' </dev/null )"; _ffr=$?
is  "felix_final_filter exits 0 on a text it refuses"              "$_ffr" "0"
is  "and prints one line for a text it refuses, the final filter's name" "$(printf '%s\n' "$_ffo" | grep -c .)|$_ffo" "1|tail"
_ffo="$( . "$REAL_HARNESS/lib/final-filter.sh" 2>/dev/null || exit 3
         felix_final_filter 'npm test 2>&1 | grep -q passed' </dev/null )"; _ffr=$?
is  "felix_final_filter exits 1 on a text it admits"               "$_ffr" "1"
is  "and prints nothing for a text it admits"                       "$_ffo" ""

# One assertion per line: the stage the classifier must print, or `-` for a
# text it must admit, then the text, then why. Read verbatim, so quotes,
# backslashes and `$( )` are the row's own.
while IFS= read -r _ffl; do
  case "$_ffl" in ''|'#'*) continue ;; esac
  _ffstage="${_ffl%%@@*}"; _ffl="${_ffl#*@@}"; _fftx="${_ffl%%@@*}"; _ffwhy="${_ffl#*@@}"
  if [ "$_ffstage" = "-" ]; then
    is "felix_final_filter admits [$_fftx]: $_ffwhy" "$(_ffc "$_fftx")" "1|"
  else
    is "felix_final_filter refuses [$_fftx] and names $_ffstage: $_ffwhy" "$(_ffc "$_fftx")" "0|$_ffstage"
  fi
done <<'FFCASES'
# The shape the contract opens with, and the name as the shell resolves it.
tail@@npm test 2>&1 | tail -20@@failing tests would read as a pass
tail@@x | /usr/bin/tail -1@@a path prints the command's name
tail@@x | \tail -1@@a backslash does not hide the command
tail@@x | 'tail' -1@@nor do quotes
tail@@x | command tail -1@@nor command
tail@@x | env LC_ALL=C tail -1@@nor env with an assignment
tail@@x | LC_ALL=C tail -1@@nor an assignment in front
tail@@x | nice tail -1@@nor nice
tail@@x | exec tail -1@@nor exec
sort@@x | LC_ALL=C sort@@an assignment in front of sort prints sort
# Every filter the contract lists, as the last stage.
cat@@x | cat@@cat with no operand
cat@@x | cat -@@an operand of exactly - is standard input
-@@x | tac@@amended: tac is not on macOS, where the row exits 127
head@@x | head -1@@head
tail@@x | tail@@tail with no operand
tail@@x | tail -n 20@@an option's argument is not a file operand
tee@@x | tee out.log@@tee, whose operands are output files
tee@@x | tee -a a.log b.log@@tee appending to two outputs
sort@@x | sort -u@@sort without a check flag
sort@@x | sort -rn@@sort reversed and numeric
uniq@@x | uniq@@uniq with no operand
uniq@@x | uniq -c@@uniq counting
uniq@@x | uniq - counts.txt@@uniq whose first operand is -, its second being output
wc@@x | wc -l@@wc
tr@@x | tr -d '\r'@@tr, whose operands are sets and never files
tr@@x | tr a-z A-Z@@tr translating
cut@@x | cut -f1@@cut
paste@@x | paste -s -@@paste
nl@@x | nl@@nl
fold@@x | fold -w 80@@fold
rev@@x | rev@@rev
-@@x | column -t@@amended: macOS column fails on a line past about 2 KB, exit 1 on one of 3000 bytes
expand@@x | expand@@expand
unexpand@@x | unexpand -a@@unexpand
true@@x | true@@true
:@@x | :@@the colon builtin
echo@@x | echo done@@echo, whose operands are words it prints
sed@@x | sed -n 's/a/b/p'@@sed with a literal script
sed@@x | sed -e 's/a/b/' -e 's/c/d/'@@sed whose script comes from -e
sed@@x | sed 5q@@sed whose q carries no exit code
awk@@x | awk '{ print $1 }'@@awk with a literal program
awk@@x | awk '{ print $1 }' -@@awk whose other operand is -
awk@@x | awk '{ print $1 }' FS=,@@awk whose other operand is an assignment
awk@@x | awk '/^#/ { next } { print "a/b", "50%" }'@@awk whose / and % sit only in a regex literal and a string
-@@x | xargs -0 echo@@amended: xargs fails on an argument past ARG_MAX, exit 1 on macOS for one of 2 MB
-@@x | xargs -0@@amended: so with no command
-@@x | xargs --null true@@amended: and with --null and true
-@@x | xargs -d '\n' echo@@amended: macOS xargs has no -d, a usage error every time
# Redirections other than of standard input change nothing.
tail@@x 2>&1 | tail -3@@a redirection on the producer
tail@@x | tail -5 >/dev/null@@standard output to /dev/null
tail@@x | tail -5 2>/dev/null@@standard error to /dev/null
tail@@x | tail -5 2>&1@@2>&1 on the filter
tail@@x | tail -5 &>/dev/null@@&> on the filter
tail@@x | tail -5 >out@@output to a file
tail@@x |tail>/dev/null@@with no spaces at all
# Lists, groups and compounds, per path.
tail@@x | tail -20 || exit 1@@the || branch never runs
tail@@true && x | tail@@after an && that cannot fail, the status is tail's
tail@@x || y | tail@@the status after || is tail's
tail@@y; x | tail@@the last command decides, and it is tail
tail@@{ x | tail; }@@a group carries its inner status
tail@@( x | tail )@@so does a subshell
tail@@if a; then x | tail; fi@@the status of a then branch counts
tail@@if a; then true; else x | tail; fi@@and of an else branch
tail@@case "$v" in a) x | tail ;; esac@@and of a case branch
tail@@for f in a b; do x | tail; done@@and of a loop body
tail@@sh -c 'x | tail'@@sh -c with a literal script is read as that script
tail@@bash -c 'x | tail -1'@@and bash -c
tail@@eval 'x | tail'@@and eval
tail@@x |& tail -1@@|& joins two stages as | does
# Admitted: another command decides.
-@@x | tail && y@@y decides
-@@a && x | tail@@a can fail, so the text can
-@@if a; then y; else x | tail; fi@@y can fail, so the text can
-@@x | tail; y@@y decides after ;
-@@x | tail &@@a background job's status is 0, not this shape
-@@! x | tail@@a negation always fails, a different defect
# Admitted: words are words.
-@@grep -qE 'a|sort -u' f@@a pipe inside single quotes is a word
-@@grep -q "x | tail" f@@and inside double quotes
-@@[ "$(x | head -1)" = y ]@@a | head inside $( ) is a word
-@@[ "`x | tail -1`" = y ]@@and inside backticks
-@@[ -n "${v:-x | tail}" ]@@and inside ${ }
-@@diff <(x | sort) <(y | sort)@@and inside <( )
-@@x | head -5 | grep -q y@@head mid-pipeline
-@@x | grep -q y # | tail@@a comment is not a stage
-@@test -f a || cat b@@cat with a file operand, and no pipe
-@@cat b@@one stage is not a pipeline
-@@tail -1 file@@nor is one tail reading a file
-@@true@@nor one true
# Admitted when uncertain.
-@@set -o pipefail; x | tail@@a text naming pipefail
-@@x | tail # the caller sets PIPEFAIL@@in any case
-@@[ -z "$PIPE_FAIL" ]; x | tail@@or spelt pipe_fail
-@@f() { x | tail; }; f@@a text defining a function
-@@function f { x | tail; }; f@@with the function keyword
-@@x | tail '@@an unbalanced quote
-@@( x | tail@@an unbalanced parenthesis
-@@x | tail; fi@@a stray fi
-@@x | $T -1@@the final stage's name is an expansion
-@@x | "$T"@@a quoted one
-@@x | ${T:-tail}@@a braced one
-@@x | $(echo tail)@@a command substitution
# Admitted: each condition's counter-case.
-@@x | sort -c@@sort -c fails on unsorted input
-@@x | sort -C@@and so does sort -C
-@@x | sort --check@@and sort --check
-@@x | sort --check=quiet@@and sort --check=quiet
-@@x | sed -n '/x/q1'@@a sed q with an exit code fails on content
-@@x | sed '/x/Q3'@@and a Q with one
-@@x | sed -f f@@a sed script from a file is not visible
-@@x | sed -i 's/a/b/'@@sed -i
-@@x | sed 's/a/b/' f@@sed with a file operand
-@@x | awk '{print 1/$1}'@@awk dividing, which is fatal by zero
-@@x | awk '{print $1 % 2}'@@awk taking a modulo
-@@x | awk '{exit 1}'@@awk with an exit
-@@x | awk '{printf "%s", $1}'@@awk with printf
-@@x | awk '{ s = sprintf("%d", $1); print s }'@@awk with sprintf
-@@x | awk -f p@@an awk program from a file
-@@x | awk '{ print }' f@@awk with a file operand
-@@x | xargs echo@@xargs without -0 fails on an unmatched quote
-@@x | xargs -0 rm@@xargs -0 running a command other than echo or true
-@@x | uniq a@@uniq whose first operand is an input file
-@@x | tail -1 file@@tail with a file operand
-@@x | head -n 5 f@@head with a file operand after an option's argument
-@@x | cat b@@cat with a file operand
-@@x | tail < file@@standard input redirected with <
-@@x | tail <<< y@@with <<<
-@@x | tail 0< f@@with 0<
-@@x | tail <&3@@with <&
-@@x | tail 0>f@@with 0>
# Admitted: not a final filter at all.
-@@x | grep -q y@@grep
-@@x | jq .a@@jq
-@@x | test -s /dev/stdin@@test
-@@x | python3 -c 'import sys'@@python3
-@@x | printf ok@@printf
-@@x | felix_probe_rows p@@an engine function
FFCASES
# The three that need a newline in them.
is  "felix_final_filter refuses a newline list whose last line ends in tail, a newline acting as ;" \
    "$(_ffc "$(printf 'y\nx | tail')")" "0|tail"
is  "felix_final_filter admits a newline list whose last line is y, which decides" \
    "$(_ffc "$(printf 'x | tail\ny')")" "1|"
is  "felix_final_filter admits a text holding a here-document" \
    "$(_ffc "$(printf 'cat <<EOF | tail\nx\nEOF')")" "1|"

# Per table. The four judged columns refuse a row the classifier names and say
# which stage; the shapes the old head patterns caught by accident are
# admitted; and a column that is not judged behaves exactly as before. Each
# refused row carries a side effect, so "refused" can be told from "ran and
# was read as failing".
_ffwd="$FROOT/projects/widget"
for _fft in obligations.tsv setup.tsv maintenance.tsv; do
  rm -f "$TMP/ff-w-$_fft.keep"
  [ -f "$_ffwd/$_fft" ] && cp "$_ffwd/$_fft" "$TMP/ff-w-$_fft.keep"
done
_commissioning_build alpha12
cp "$CMP/commissioning.tsv" "$TMP/ff-cm.keep"
rm -f "$TMP/ffcran" "$TMP/fforan" "$TMP/ffsran" "$TMP/ffmran"

# commissioning.tsv: check is judged, when is not.
_ffcrow() { printf '%s\t-\t-\t%s\t-\t%s\t9' "$1" "$2" "$3"; }   # need, when, check
_ffcmal() { _cm felix_commission_malformed "$CMP" | awk -F'\t' -v n="$1" '$1 == n { print $2 }'; }
_cmtable "$(_ffcrow ffc_last    - 'printf a | tail -1')" \
         "$(_ffcrow ffc_orexit  - 'printf a | tail -20 || exit 1')" \
         "$(_ffcrow ffc_andsort - 'true && ls src | sort')" \
         "$(_ffcrow ffc_ran     - "touch \"$TMP/ffcran\"; false | tail -1")" \
         "$(_ffcrow ffc_headsub - '[ "$(printf a | head -1)" = a ]')" \
         "$(_ffcrow ffc_headmid - 'printf y | head -5 | grep -q y')" \
         "$(_ffcrow ffc_when    'false | tail -1' 'test -f src/a.txt')" \
         "$(_ffcrow ffc_neg     - '! true')" \
         "$(_ffcrow ffc_grep    - 'ls src | grep -q a.txt')" \
         "$(_ffcrow ffc_guard   - 'test -f src/a.txt && ls src | sort')"
is  "commissioning rows omit every check a final filter makes unfailable, and keep the rest in file order" \
    "$(_cm felix_commission_rows "$CMP" | cut -f1 | tr '\n' ' ')" "ffc_headsub ffc_headmid ffc_when ffc_grep ffc_guard "
has "a commissioning check ending in | tail is malformed, and the reason names tail" \
    "$(_ffcmal ffc_last)" "tail"
has "and says that tail stage succeeds whatever it is fed" \
    "$(_ffcmal ffc_last)" "succeeds whatever it is fed"
has "a commissioning check ending in | tail -20 || exit 1 is malformed, because the || branch never runs" \
    "$(_ffcmal ffc_orexit)" "succeeds whatever it is fed"
has "a commissioning check whose status after && is sort's is malformed, naming sort" \
    "$(_ffcmal ffc_andsort)" "sort"
is  "a commissioning check with | head -1 inside \$( ) is not malformed" "$(_ffcmal ffc_headsub)" ""
is  "a commissioning check with head mid-pipeline before grep -q is not malformed" "$(_ffcmal ffc_headmid)" ""
is  "a commissioning when ending in | tail is not judged" "$(_ffcmal ffc_when)" ""
is  "a commissioning check whose guard can fail before | sort is not malformed" "$(_ffcmal ffc_guard)" ""
[ -n "$(_ffcmal ffc_neg)" ] \
  && ok  "a negated commissioning check is still malformed" \
  || bad "a negated commissioning check is still malformed" "no reason printed for ffc_neg"
_ffcrun="$(_cm felix_commission_run "$CMP" "$CMR" -)"
_ffcst() { printf '%s\n' "$_ffcrun" | awk -F'\t' -v n="$1" '$1 == n { print $2 }'; }
is  "the check with | head -1 inside \$( ) is asked, and done"          "$(_ffcst ffc_headsub)" "done"
is  "the check with head mid-pipeline is asked, and done"              "$(_ffcst ffc_headmid)" "done"
is  "a row whose when ends in | tail applies, and its check decides it" "$(_ffcst ffc_when)"    "done"
is  "the check whose guard can fail before | sort is asked, and done"    "$(_ffcst ffc_guard)"   "done"
is  "a refused check is no row of the run" \
    "$(printf '%s\n' "$_ffcrun" | awk -F'\t' '$1 ~ /^ffc_(last|orexit|andsort|ran)$/' | grep -c .)" "0"
_ffccli="$( cd "$CMR" && PATH="$CMSTUB:$PATH" "$FELIX" commission --status 2>&1 )"
has "felix commission --status prints a refused check among the rows that name a need and nothing readable" \
    "$(printf '%s\n' "$_ffccli" | sed -n '/rows that name a need and nothing readable/,$p' | grep ' ffc_last ')" \
    "succeeds whatever it is fed"
has "and counts the four refused checks and the negated one as malformed" "$_ffccli" ", 5 malformed"
is  "and reads the check with | head -1 inside \$( ) done" \
    "$(printf '%s\n' "$_ffccli" | awk '$2 == "ffc_headsub" { print $1 }')" "done"
is  "and neither the library nor the command ran a refused commissioning check" "$(_ffnot "$TMP/ffcran")" "not run"

# obligations.tsv: evidence is judged, applies is not.
_ffob()   { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"
              . "$FROOT/harness/lib/obligations.sh"; "$@" ) 2>/dev/null; }
_ffomal() { _ffob felix_obligation_malformed "$_ffwd" | grep "^$1: "; }
{ printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds\n'
  printf 'ffo_last\tADVISORY\tdeterministic\t-\t%s\t-\tevidence ending in tail\n'         'printf a | tail -1'
  printf 'ffo_orexit\tADVISORY\tdeterministic\t-\t%s\t-\tevidence ending in wc or exit\n' 'printf a | wc -l || exit 1'
  printf 'ffo_ran\tADVISORY\tdeterministic\t-\t%s\t-\tevidence with a side effect\n'      "touch \"$TMP/fforan\"; false | tail -1"
  printf 'ffo_headsub\tADVISORY\tdeterministic\t-\t%s\t-\thead in a substitution\n'       '[ "$(printf a | head -1)" = a ]'
  printf 'ffo_headmid\tADVISORY\tdeterministic\t-\t%s\t-\thead mid-pipeline\n'            'printf y | head -5 | grep -q y'
  printf 'ffo_applies\tADVISORY\tdeterministic\t%s\ttrue\t-\tan applies ending in tail\n' 'false | tail -1'
} > "$_ffwd/obligations.tsv"
is  "obligation rows omit every evidence a final filter makes unfailable, and keep the rest in file order" \
    "$(_ffob felix_obligation_rows "$_ffwd" | cut -f1 | tr '\n' ' ')" "fixture ffo_headsub ffo_headmid ffo_applies "
has "an evidence ending in | tail is refused as <obligation>: <reason>, naming tail" "$(_ffomal ffo_last)" "tail"
has "and says the evidence's tail succeeds whatever it is fed" "$(_ffomal ffo_last)" "succeeds whatever it is fed"
has "an evidence ending in | wc -l || exit 1 is refused, naming wc" "$(_ffomal ffo_orexit)" "wc"
is  "an evidence with | head -1 inside \$( ) is not refused" "$(_ffomal ffo_headsub)" ""
is  "an evidence with head mid-pipeline before grep -q is not refused" "$(_ffomal ffo_headmid)" ""
is  "an applies ending in | tail is not judged" "$(_ffomal ffo_applies)" ""
_fforun="$(_ffob felix_obligations_run "$_ffwd" "$REPO")"
_ffost() { printf '%s\n' "$_fforun" | awk -F'\t' -v n="$1" '$1 == n { print $4 "\t" $5 }'; }
is  "the evidence with | head -1 inside \$( ) is examined, and holds" "$(_ffost ffo_headsub)" "ACTIVE${_ffT}SATISFIED"
is  "the evidence with head mid-pipeline is examined, and holds"      "$(_ffost ffo_headmid)" "ACTIVE${_ffT}SATISFIED"
is  "an obligation whose applies ends in | tail applies, as before"   "$(_ffost ffo_applies)" "ACTIVE${_ffT}SATISFIED"
_ffocli="$(cd "$REPO" && "$FELIX" obligations 2>&1)"
has "felix obligations prints the refused evidence under rows refused" "$_ffocli" "rows refused"
has "naming the obligation and saying its stage succeeds whatever it is fed" \
    "$(printf '%s\n' "$_ffocli" | grep 'ffo_last: ')" "succeeds whatever it is fed"
has "and reports the obligation whose applies ends in | tail on its axes" \
    "$(printf '%s\n' "$_ffocli" | grep ' ffo_applies ')" "ACTIVE    SATISFIED"
is  "and neither the library nor the command ran a refused evidence" "$(_ffnot "$TMP/fforan")" "not run"

# setup.tsv: check is judged, and a refused one is never run.
_ffsu() { ( cd "$REPO" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
            . "$FROOT/harness/lib/stack.sh"; . "$FROOT/harness/lib/setup.sh"; "$@" ) 2>/dev/null; }
{ printf 'ffs_true\ta step whose check is one command\talways\ttrue\n'
  printf 'ffs_ran\ta step whose status is a final tail\talways\t%s\n'      "touch \"$TMP/ffsran\"; false | tail -1"
  printf 'ffs_or\ta step ending in sort or exit\talways\t%s\n'             'printf a | sort || exit 1'
  printf 'ffs_mid\ta step with head mid-pipeline\talways\t%s\n'            'printf y | head -5 | grep -q y'
  printf 'ffs_sub\ta step with head in a substitution\talways\t%s\n'       '[ "$(printf a | head -1)" = a ]'
} > "$_ffwd/setup.tsv"
_ffsust="$(_ffsu felix_setup_status "$_ffwd")"
has "a setup check whose status is a final tail's reads todo"   "$_ffsust" "todo${_ffT}ffs_ran${_ffT}"
is  "and the refused setup check is never run"                "$(_ffnot "$TMP/ffsran")" "not run"
has "a setup check ending in | sort || exit 1 reads todo"      "$_ffsust" "todo${_ffT}ffs_or${_ffT}"
has "a setup check with head mid-pipeline is run, and done"    "$_ffsust" "done${_ffT}ffs_mid${_ffT}"
has "a setup check with head inside \$( ) is run, and done"    "$_ffsust" "done${_ffT}ffs_sub${_ffT}"
has "a setup check of one command is still done"               "$_ffsust" "done${_ffT}ffs_true${_ffT}"
_ffsumal="$(_ffsu felix_setup_malformed "$_ffwd")"
_ffsuwhy() { printf '%s\n' "$_ffsumal" | awk -F'\t' -v n="$1" '$1 == n { print $2 }'; }
has "felix_setup_malformed prints the refused row as id and a reason naming tail" "$(_ffsuwhy ffs_ran)" "tail"
has "and saying the setup check's tail succeeds whatever it is fed"             "$(_ffsuwhy ffs_ran)" "succeeds whatever it is fed"
has "and the row ending in | sort || exit 1, naming sort"                       "$(_ffsuwhy ffs_or)"  "sort"
is  "and felix_setup_malformed prints no row it admits" \
    "$(printf '%s\n' "$_ffsumal" | awk -F'\t' '$1 ~ /^ffs_(true|mid|sub)$/' | grep -c .)" "0"
rm -f "$TMP/ffsran"
_ffsucli="$(cd "$REPO" && "$FELIX" setup 2>&1)"
has "felix setup lists the refused row as not done"             "$_ffsucli" "[ ] ffs_ran "
has "and counts both refused rows among the steps that need a person" "$_ffsucli" "2 step(s) need you"
has "while the admitted setup rows read done"                   "$_ffsucli" "[x] ffs_mid "
_ffsuunder="$(printf '%s\n' "$_ffsucli" | awk '/^  \[[x -]\] / { last = NR } { l[NR] = $0 }
                                             END { for (i = last + 1; i <= NR; i++) print l[i] }')"
has "and prints the refused rows under the list"                "$_ffsuunder" "ffs_ran"
has "both refused setup rows are printed there"                 "$_ffsuunder" "ffs_or"
case "$_ffsuunder" in
  *ffs_true*|*ffs_mid*|*ffs_sub*) bad "and no admitted setup row among them" "$_ffsuunder" ;;
  *)                              ok  "and no admitted setup row among them" ;;
esac
is  "and felix setup never ran the refused check either"        "$(_ffnot "$TMP/ffsran")" "not run"

# maintenance.tsv: an event row's check is judged, and a refused one is due
# without being run.
_ffmt() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
            . "$FROOT/harness/lib/maintenance.sh"; felix_maint_status "$_ffwd" "$REPO" ) 2>/dev/null; }
{ printf 'ffm_ran\t0\talways\ta check ending in tail\t%s\n'  "touch \"$TMP/ffmran\"; false | tail -1"
  printf 'ffm_mid\t0\talways\thead mid-pipeline\t%s\n'       'printf y | head -5 | grep -q y'
  printf 'ffm_sub\t0\talways\thead in a substitution\t%s\n'  '[ "$(printf a | head -1)" = a ]'
  printf 'ffm_fail\t0\talways\ta check that fails\tfalse\n'
} > "$_ffwd/maintenance.tsv"
_ffmst="$(_ffmt)"
_ffmrow() { printf '%s\n' "$_ffmst" | awk -F'\t' -v n="$1" '$2 == n'; }
is  "a maintenance check whose status is a final tail's is due, as refused" \
    "$(_ffmrow ffm_ran)" "due${_ffT}ffm_ran${_ffT}refused${_ffT}0${_ffT}a check ending in tail"
is  "and the refused maintenance check is never run"           "$(_ffnot "$TMP/ffmran")" "not run"
is  "a maintenance check with head mid-pipeline is run, and not due" \
    "$(_ffmrow ffm_mid)" "ok${_ffT}ffm_mid${_ffT}-${_ffT}0${_ffT}head mid-pipeline"
is  "a maintenance check with head inside \$( ) is run, and not due" \
    "$(_ffmrow ffm_sub)" "ok${_ffT}ffm_sub${_ffT}-${_ffT}0${_ffT}head in a substitution"
is  "a maintenance check that fails is still due on its check" \
    "$(_ffmrow ffm_fail)" "due${_ffT}ffm_fail${_ffT}check${_ffT}0${_ffT}a check that fails"
_ffmcli="$(cd "$REPO" && "$FELIX" maintenance 2>&1 | tr -s ' ')"
has "felix maintenance renders it DUE, check refused"          "$_ffmcli" "DUE ffm_ran check refused a check ending in tail"
has "and counts it due beside the check that failed"           "$_ffmcli" "2 routine(s) due"
has "while the check with head mid-pipeline renders ok"        "$_ffmcli" "ok ffm_mid check passed"
is  "and felix maintenance never ran the refused check either"  "$(_ffnot "$TMP/ffmran")" "not run"

# probes.tsv: nothing in it is judged. A witness ending in | tail makes an
# empty probe blind, which blocks; a probe ending in sed -n s/.../p is how a
# real row counts members.
_ffpp="$TMP/ff-probes"; rm -rf "$_ffpp"; mkdir -p "$_ffpp"
_ffpr() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"; "$@" ) 2>/dev/null; }
{ printf 'ffp_when\t-\t%s\t%s\t-\n'   'false | tail -1' 'git ls-files src | tail -5'
  printf 'ffp_witness\t-\t-\t%s\t%s\n' 'printf "" | tail -1' 'printf x | tail -1'
  printf 'ffp_sed\t-\t-\t%s\t-\n'      "git ls-files | sed -n 's|^src/||p'"
} > "$_ffpp/probes.tsv"
is  "no probe row is refused for a when, a probe or a witness ending in a final filter" \
    "$(_ffpr felix_probe_malformed "$_ffpp")" ""
is  "and every such probe row is a row" \
    "$(_ffpr felix_probe_rows "$_ffpp" | cut -f1 | tr '\n' ' ')" "ffp_when ffp_witness ffp_sed "
_ffprun="$(_ffpr felix_probes_run "$_ffpp" "$CMR")"
_ffpst() { printf '%s\n' "$_ffprun" | awk -F'\t' -v n="$1" '$1 == n { print $3 "\t" $4 }'; }
is  "a probe whose when ends in | tail applies, and its probe ending in | tail counts its members" \
    "$(_ffpst ffp_when)" "found${_ffT}2"
is  "a witness ending in | tail turns an empty probe blind, as before" \
    "$(_ffpst ffp_witness)" "blind${_ffT}0"
is  "a probe ending in sed -n s/.../p counts its members, as before" \
    "$(_ffpst ffp_sed)" "found${_ffT}2"

# Every shipped template's judged commands are admitted: a new project copies
# these, and a template the gate refused would fail every project on day one.
# Only the harness's own templates are read, never a project's tables.
_fftpl() {   # template, awk program printing each row's judged cell
  local _c _r _n=0 _b=""
  while IFS= read -r _c; do
    [ -n "$_c" ] || continue
    _n=$((_n + 1)); _r="$(_ffc "$_c")"
    [ "$_r" = "1|" ] || _b="$_b [$_r] $_c;"
  done <<EOF
$(grep -vE '^[[:space:]]*(#|$)' "$REAL_HARNESS/templates/$1" | awk -F'\t' "$2")
EOF
  printf '%s checked;%s\n' "$_n" "${_b:- none refused}"
}
for _fft in commissioning.tsv obligations.tsv setup.tsv maintenance.tsv; do
  case "$_fft" in
    commissioning.tsv) _ffpc='$5 !~ /^provider:/ { print $6 }' ;;
    obligations.tsv)   _ffpc='{ print $5 }' ;;
    setup.tsv)         _ffpc='{ print $4 }' ;;
    maintenance.tsv)   _ffpc='NF >= 5 && $5 != "-" && $5 != "" { print $5 }' ;;
  esac
  _ffto="$(_fftpl "$_fft" "$_ffpc")"
  case "$_ffto" in
    [1-9]*' checked; none refused') ok  "every judged command in templates/$_fft is admitted" ;;
    *)                              bad "every judged command in templates/$_fft is admitted" "$_ffto" ;;
  esac
done

cp "$TMP/ff-cm.keep" "$CMP/commissioning.tsv"
for _fft in obligations.tsv setup.tsv maintenance.tsv; do
  if [ -f "$TMP/ff-w-$_fft.keep" ]; then mv "$TMP/ff-w-$_fft.keep" "$_ffwd/$_fft"; else rm -f "$_ffwd/$_fft"; fi
done
rm -rf "$_ffpp"
rm -f "$TMP/ff-cm.keep" "$TMP/ffcran" "$TMP/fforan" "$TMP/ffsran" "$TMP/ffmran"
unset -f _ffc _ffnot _ffcrow _ffcmal _ffcst _ffob _ffomal _ffost _ffsu _ffsuwhy _ffmt _ffmrow \
         _ffpr _ffpst _fftpl
unset _ffT _ffo _ffr _ffl _ffstage _fftx _ffwhy _ffwd _fft _ffpc _ffto _ffcrun _ffccli _fforun _ffocli \
      _ffsust _ffsumal _ffsucli _ffsuunder _ffmst _ffmcli _ffpp _ffprun

