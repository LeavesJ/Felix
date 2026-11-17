# A declared-capabilities list that could not be read is said, never dormant.
#
# The block above made _felix_cap_active return 2 when the list could not be
# read, and felix_commission_state reads that 2 as unknown. Three other callers
# ask it with `!`, so 2 reads as not active and prints `dormant`, a valid state
# that looks like a well-kept repository: felix_setup_status calls a step that
# still needs a person not needed yet, felix_maint_status calls a routine that
# may be due dormant, and felix_stack_plan calls a row it never classified
# dormant. felix_maint_unreachable reads the list itself through felix_has_line,
# so a list nobody read says nothing declares the capability. And session start
# put a provider row whose state is unknown, or which has no state at all,
# among the answers a session still owes, which sends a session to redo an
# answer that may be whole. Each of them now says the list could not be read.
# An unread list makes nothing due, installs nothing and owes nothing; that is
# the `unchecked` precedent, a row that could not be asked being its own word.
# The library is asked with felix_declared failing as a substitution whose fork
# could not be made fails, defined in a subshell after the libs are sourced, over
# a capabilities file that DOES declare the capability, so 2 read as 1 shows.
# The CLI is another process and cannot see a stub, so there the capabilities
# file is a link whose target is gone, which felix_declared returns 2 for. The
# stack rows are skills no machine has, so nothing here installs anything or
# needs the claude CLI. These assertions were written blind, from the contract,
# before the fix, and each was run against main's engine first.
# Everything this makes is removed below and everything it defines unset.
_cucrfixture() { { find "$FROOT/projects" "$FROOT/state" "$MEM" 2>/dev/null | LC_ALL=C sort
                   find "$FROOT/projects" "$FROOT/state" "$MEM" -type f -exec cksum {} + 2>/dev/null | LC_ALL=C sort; } | cksum; }
_cucrfound="$(_cucrfixture)"
# Session start below makes state/commission when it spends the receipt line,
# and the block removes only what it made.
_cucrmade=''; [ -d "$FROOT/state" ] || _cucrmade=state; [ -d "$FROOT/state/commission" ] || _cucrmade="$_cucrmade commission"
_cucrp="$FROOT/projects/cucrproj"
_cucrr="$TMP/cucr-repo"
_cucrhome="$TMP/cucr-home"
mkdir -p "$_cucrp" "$_cucrr" "$_cucrhome/.claude/skills/cucr-skill-there"
printf '{\n  "name": "cucrproj",\n  "remote_match": "example.com/cucrproj",\n  "gate": "true"\n}\n' > "$_cucrp/project.json"
printf '# cucrproj\n' > "$_cucrp/CLAUDE.md"
( _fx_cd "$_cucrr" && git init -q -b main && printf 'cucrproj\n' > .felix && git add .felix \
    && git -c user.name=cucr -c user.email=cucr@example.com commit -q -m cucr )
_cucrr="$(cd "$_cucrr" && pwd -P)"
{ printf 'cucr_step\ta step on a declared capability\tcucrcap\ttouch %s; false\n' "$TMP/cucr-setup-ran"
  printf 'cucr_plain\ta step for every project\talways\ttrue\n'; } > "$_cucrp/setup.tsv"
{ printf 'cucr_clock\t7\tcucrcap\ta routine on a clock\n'
  printf 'cucr_checked\t0\tcucrcap\ta routine with a check\ttouch %s; false\n' "$TMP/cucr-maint-ran"
  printf 'cucr_every\t0\talways\ta routine on a trigger\n'; } > "$_cucrp/maintenance.tsv"
{ printf 'skill\tcucr-skill-unread\t-\tlow\tcucrcap\n'
  printf 'skill\tcucr-skill-there\t-\tlow\tcucrcap\n'; } > "$_cucrp/stack.tsv"
printf 'cucrcap\n' > "$_cucrp/capabilities"

# $1 is unread (felix_declared fails) or read; the rest is the engine call.
_cucrlib() { local _cucrmode="$1"; shift
  ( cd "$_cucrr" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
    . "$FROOT/harness/lib/stack.sh"; . "$FROOT/harness/lib/setup.sh"; . "$FROOT/harness/lib/maintenance.sh"
    claude() { return 1; }
    HOME="$_cucrhome"
    case "$_cucrmode" in unread) felix_declared() { return 128; } ;; esac
    "$@" ) 2>/dev/null; }
_cucrnext() { local _cucrmode="$1"
  ( cd "$_cucrr" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
    . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
    . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/evidence.sh"
    . "$FROOT/harness/lib/maintenance.sh"; . "$FROOT/harness/lib/stack.sh"
    . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/ledger.sh"
    . "$FROOT/harness/lib/coverage.sh"; . "$FROOT/harness/lib/deny.sh"
    . "$FROOT/harness/lib/route.sh"; . "$FROOT/harness/lib/next.sh"
    claude() { return 1; }
    case "$_cucrmode" in unread) felix_declared() { return 128; } ;; esac
    felix_next "$_cucrp" "$FROOT" "$_cucrr" HEAD ) 2>/dev/null; }
_cucrpulse() { local _cucrmode="$1"
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
    . "$FROOT/harness/lib/stack.sh"; . "$FROOT/harness/lib/maintenance.sh"
    . "$FROOT/harness/lib/discover.sh"; . "$FROOT/harness/lib/pulse.sh"
    case "$_cucrmode" in unread) felix_declared() { return 128; } ;; esac
    felix_pulse_report "$FROOT" ) 2>/dev/null; }
_cucrcli() { ( cd "$_cucrr" && HOME="$_cucrhome" PATH=/usr/bin:/bin "$FELIX" "$@" 2>&1 ); }
# The lines whose column $2 is $3.
_cucrline() { printf '%s\n' "$1" | awk -F'\t' -v c="$2" -v n="$3" '$c == n'; }
_cucrsays() { case "$1" in *"$2"*) printf 'said\n' ;; *) printf 'silent\n' ;; esac; }
# said when one line holds both $2 and $3.
_cucrboth() { if printf '%s\n' "$1" | awk -v a="$2" -v b="$3" 'index($0, a) && index($0, b) { f = 1 } END { exit !f }'
              then printf 'said\n'; else printf 'silent\n'; fi; }
_cucrran()  { if [ -e "$1" ]; then printf 'ran\n'; else printf 'not run\n'; fi; }
_cucrwhy='the capabilities this project declares could not be read'

# felix_setup_status.
_cucrsu1="$(_cucrlib unread felix_setup_status "$_cucrp")"
is  "felix_setup_status prints unknown, not dormant, for a step whose declared list could not be read, and does not run its check" \
    "$(_cucrline "$_cucrsu1" 2 cucr_step) $(_cucrran "$TMP/cucr-setup-ran")" \
    "$(printf 'unknown\tcucr_step\ta step on a declared capability not run')"
is  "and over that unread list a step for every project is still done" \
    "$(_cucrline "$_cucrsu1" 2 cucr_plain)" "$(printf 'done\tcucr_plain\ta step for every project')"
is  "over a list read and declaring the capability the step is todo and its check runs" \
    "$(_cucrline "$(_cucrlib read felix_setup_status "$_cucrp")" 2 cucr_step) $(_cucrran "$TMP/cucr-setup-ran")" \
    "$(printf 'todo\tcucr_step\ta step on a declared capability ran')"

# felix_maint_status, felix_maint_unreachable, felix_stack_plan.
_cucrms1="$(_cucrlib unread felix_maint_status "$_cucrp" "$_cucrr")"
is  "felix_maint_status prints unknown, not dormant, for a routine on a clock whose declared list could not be read" \
    "$(_cucrline "$_cucrms1" 2 cucr_clock)" "$(printf 'unknown\tcucr_clock\t-\t7\ta routine on a clock')"
is  "and for a routine with a check prints unknown with cadence 0, and does not run the check" \
    "$(_cucrline "$_cucrms1" 2 cucr_checked) $(_cucrran "$TMP/cucr-maint-ran")" \
    "$(printf 'unknown\tcucr_checked\t-\t0\ta routine with a check not run')"
is  "and over that unread list a routine for every project is still event" \
    "$(_cucrline "$_cucrms1" 2 cucr_every)" "$(printf 'event\tcucr_every\t-\t0\ta routine on a trigger')"
is  "felix_maint_unreachable says unknown in a third column for each routine whose declared list could not be read" \
    "$(_cucrlib unread felix_maint_unreachable "$_cucrp")" \
    "$(printf 'cucr_clock\tcucrcap\tunknown\ncucr_checked\tcucrcap\tunknown')"
_cucrsp1="$(_cucrlib unread felix_stack_plan "$_cucrp")"
is  "felix_stack_plan prints unknown, not dormant, for a row whose declared list could not be read, naming its capability" \
    "$(_cucrline "$_cucrsp1" 3 cucr-skill-unread)" \
    "$(printf 'unknown\tskill\tcucr-skill-unread\t%s, so whether cucrcap is active here is not known' "$_cucrwhy")"
is  "and a row whose item is present stays present over that unread list" \
    "$(_cucrline "$_cucrsp1" 3 cucr-skill-there)" "$(printf 'present\tskill\tcucr-skill-there\t-')"

# next.sh and the pulse.
_cucrnx1="$(_cucrnext unread)"
_cucrn6="$(printf '%s\n' "$_cucrnx1" | awk -F'\t' '$1 == 6' | grep cucr_clock)"
is  "felix_next rank 6 says the declared list could not be read for that routine, naming its capability and felix maintenance, never that nothing declares it" \
    "$(_cucrsays "$_cucrn6" 'waits on a capability nothing declares') $(_cucrsays "$_cucrn6" 'could not be read') $(_cucrsays "$_cucrn6" cucrcap) $(_cucrsays "$_cucrn6" 'felix maintenance')" \
    "silent said said said"
_cucrpu1="$(_cucrpulse unread)"
is  "felix_pulse_report prints an unknown line naming the routines whose declared list could not be read" \
    "$(_cucrline "$_cucrpu1" 1 unknown | awk -F'\t' '$2 == "cucrproj"')" \
    "$(printf 'unknown\tcucrproj\tcucr_clock cucr_checked')"

# The same rows over a list that was read, declaring the capability and not.
_cucrms0="$(_cucrlib read felix_maint_status "$_cucrp" "$_cucrr")"
is  "over a list read and declaring the capability the clock routine is due, never run, and the checked one due on its check" \
    "$(_cucrline "$_cucrms0" 2 cucr_clock) $(_cucrline "$_cucrms0" 2 cucr_checked)" \
    "$(printf 'due\tcucr_clock\tnever\t7\ta routine on a clock due\tcucr_checked\tcheck\t0\ta routine with a check')"
is  "and felix_maint_unreachable prints nothing, and felix_stack_plan calls the absent skill manual" \
    "[$(_cucrlib read felix_maint_unreachable "$_cucrp")] $(_cucrline "$(_cucrlib read felix_stack_plan "$_cucrp")" 3 cucr-skill-unread | cut -f1)" \
    "[] manual"
_cucrnx0="$(_cucrnext read)"
is  "felix_next rank 4 never names a routine whose declared list could not be read, and names it due over a list read and declaring it" \
    "$(printf '%s\n' "$_cucrnx1" | awk -F'\t' '$1 == 4' | grep -c cucr_clock) $(printf '%s\n' "$_cucrnx0" | awk -F'\t' '$1 == 4' | grep -c cucr_clock)" \
    "0 1"
is  "and felix_pulse_report never puts such a routine in its due line, and puts it there over a list read and declaring it" \
    "[$(_cucrline "$_cucrpu1" 2 cucrproj | awk -F'\t' '$1 == "due"')] $(_cucrline "$(_cucrpulse read)" 2 cucrproj | awk -F'\t' '$1 == "due"')" \
    "$(printf '[] due\tcucrproj\tcucr_clock')"
printf 'cucr_other\n' > "$_cucrp/capabilities"
is  "over a list read and not declaring the capability the step, both routines and the absent skill are dormant" \
    "$(_cucrline "$(_cucrlib read felix_setup_status "$_cucrp")" 2 cucr_step | cut -f1) $(_cucrlib read felix_maint_status "$_cucrp" "$_cucrr" | awk -F'\t' '$2 != "cucr_every" { print $1 }' | tr '\n' ' ')$(_cucrline "$(_cucrlib read felix_stack_plan "$_cucrp")" 3 cucr-skill-unread | cut -f1)" \
    "dormant dormant dormant dormant"
is  "and felix_maint_unreachable prints the two columns it always has" \
    "$(_cucrlib read felix_maint_unreachable "$_cucrp")" "$(printf 'cucr_clock\tcucrcap\ncucr_checked\tcucrcap')"
_cucrn6="$(_cucrnext read | awk -F'\t' '$1 == 6' | grep cucr_clock)"
has "and felix_next rank 6 says the routine waits on a capability nothing declares, as before" \
    "$_cucrn6" "upkeep 'cucr_clock' waits on a capability nothing declares: cucrcap"
# After review, not blind: felix_maint_unreachable passes over the capabilities
# it trusts as spelled, so a routine on ci over an unread list reached no rank
# of felix_next, which then said no upkeep was past its cadence.
cp "$_cucrp/maintenance.tsv" "$TMP/cucr-maint.keep"
{ printf 'cucr_ci\t7\tci\ta routine on ci\n'
  printf 'cucr_clock\t7\tcucrcap\ta routine on a clock\n'; } > "$_cucrp/maintenance.tsv"
printf 'ci\ncucrcap\n' > "$_cucrp/capabilities"
_cucrnx1="$(_cucrnext unread)"
is  "felix_next says at rank 6 that whether a routine on ci is due is not known when the declared list could not be read, and says the routine it named with its capability once" \
    "$(printf '%s\n' "$_cucrnx1" | awk -F'\t' '$1 == 6' | grep -cF "upkeep 'cucr_ci': $_cucrwhy, so whether it is due is not known") $(printf '%s\n' "$_cucrnx1" | grep -cF "'cucr_clock'")" \
    "1 1"
_cucrnx0="$(_cucrnext read)"
is  "and over a list read and declaring ci it names that routine due at rank 4 and not at rank 6" \
    "$(printf '%s\n' "$_cucrnx0" | awk -F'\t' '$1 == 4' | grep -c cucr_ci) $(printf '%s\n' "$_cucrnx0" | awk -F'\t' '$1 == 6' | grep -c cucr_ci)" \
    "1 0"
cp "$TMP/cucr-maint.keep" "$_cucrp/maintenance.tsv"; rm -f "$TMP/cucr-maint.keep"
printf 'cucr_other\n' > "$_cucrp/capabilities"

# The CLI, over a capabilities link whose target is gone.
rm -f "$_cucrp/capabilities"; ln -s "$TMP/cucr-no-such-list" "$_cucrp/capabilities"
_cucrout="$(_cucrcli setup)"; _cucrrc=$?
is  "felix setup renders a step it could not check as [?] with the reason, not as not needed yet" \
    "$(_cucrsays "$_cucrout" "$(printf '  [?] %-22s %s (not checked: %s)' cucr_step 'a step on a declared capability' "$_cucrwhy")")" "said"
is  "and says how many steps could not be checked in place of Nothing outstanding" \
    "$(_cucrsays "$_cucrout" 'Nothing outstanding.') $(_cucrsays "$_cucrout" "1 step(s) could not be checked: $_cucrwhy.")" \
    "silent said"
is  "and felix setup still exits 0 with a step it could not check" "$_cucrrc" "0"
# After review, not blind: the counts as well as the lines.
is  "and felix setup does not count a step it could not check among the steps that need a person" \
    "$(_cucrsays "$_cucrout" 'need you')" "silent"
_cucrout="$(_cucrcli maintenance)"
is  "felix maintenance renders a routine it could not read as ? and not read, not as not yet" \
    "$(_cucrsays "$_cucrout" "$(printf '  ?       %-18s %-14s %s' cucr_clock 'not read' 'a routine on a clock')")" "said"
is  "and says how many routines could not be read in place of Nothing due" \
    "$(_cucrsays "$_cucrout" 'Nothing due.') $(_cucrsays "$_cucrout" "2 routine(s) could not be read: $_cucrwhy, so whether they are due is not known.")" \
    "silent said"
is  "and does not list them under the header for capabilities nothing declares, but names each routine and its capability on a line of its own" \
    "$(_cucrsays "$_cucrout" 'Dormant rather than satisfied') $(_cucrboth "$_cucrout" cucr_clock cucrcap) $(_cucrboth "$_cucrout" cucr_checked cucrcap)" \
    "silent said said"
is  "and felix maintenance does not count a routine it could not read among the routines due" \
    "$(_cucrsays "$_cucrout" 'routine(s) due')" "silent"
_cucrout="$(_cucrcli stack plan)"
is  "felix stack plan prints the row it could not read as unknown, and after its summary says how many could not be read" \
    "$(_cucrsays "$_cucrout" "$(printf '%-9s %-11s %-46s' unknown skill cucr-skill-unread)") $(_cucrsays "${_cucrout#*0 to install, 0 blocked.}" "1 could not be read: $_cucrwhy, so whether they apply is not known.")" \
    "said said"
is  "and the plan counts that row neither to install nor blocked, and offers no apply" \
    "$(_cucrsays "$_cucrout" '0 to install, 0 blocked.') $(_cucrsays "$_cucrout" 'apply with:')" "said silent"
_cucrout="$(_cucrcli stack apply)"
is  "and felix stack apply without --yes says how many could not be read before saying nothing changed" \
    "$(_cucrsays "${_cucrout%%This was a plan*}" "1 could not be read: $_cucrwhy, so whether they apply is not known.")" "said"
_cucrout="$(_cucrcli stack apply --yes)"; _cucrrc=$?
is  "felix stack apply --yes says how many could not be read and returns 1, though no install failed" \
    "$_cucrrc $(_cucrsays "$_cucrout" "1 could not be read: $_cucrwhy, so whether they apply is not known.")" "1 said"
is  "and applies no item for that row, tried or failed" \
    "$(_cucrsays "$_cucrout" 'applying 0 item(s)') $(_cucrboth "$_cucrout" FAILED cucr-skill-unread) $(_cucrboth "$_cucrout" installed cucr-skill-unread)" \
    "said silent silent"
rm -f "$_cucrp/capabilities"; printf 'cucr_other\n' > "$_cucrp/capabilities"
_cucrout="$(_cucrcli maintenance)"
is  "felix maintenance over a list read and not declaring the capability lists both routines as not yet and under the header for capabilities nothing declares" \
    "$(_cucrsays "$_cucrout" "$(printf '  -       %-18s %-14s' cucr_clock 'not yet')") $(_cucrsays "$_cucrout" 'Dormant rather than satisfied') $(_cucrsays "$_cucrout" "$(printf '  %-18s waits on: %s' cucr_checked cucrcap)")" \
    "said said said"
_cucrout="$(_cucrcli stack apply --yes)"; _cucrrc=$?
is  "and felix stack apply --yes over it returns 0 and says nothing could not be read" \
    "$_cucrrc $(_cucrsays "$_cucrout" 'could not be read')" "0 silent"

# Session start, through a scratch copy of the engine whose provider state is
# unknown for one need, awaiting for another, and nothing for a third.
mkdir -p "$TMP/cucr-plugin"; cp -R "$FROOT/harness" "$TMP/cucr-plugin/harness"
cat >> "$TMP/cucr-plugin/harness/lib/commission-provider.sh" <<'EOF'
felix_commission_provider_state() {
  case "$3" in
    cucr_unread) printf 'unknown\tthe rows of the answer could not be counted\n' ;;
    cucr_owed)   printf 'awaiting\tno answer yet\n' ;;
    *)           return 1 ;;
  esac
}
EOF
{ printf 'cucr_unread\t-\t-\t-\tprovider:cucrplug:cucrskill\t-\t-\n'
  printf 'cucr_owed\t-\t-\t-\tprovider:cucrplug:cucrskill\t-\t-\n'
  printf 'cucr_none\t-\t-\t-\tprovider:cucrplug:cucrskill\t-\t-\n'; } > "$_cucrp/commissioning.tsv"
_cucrstart() { local _cucro
  _cucro="$(cd "$_cucrr" && CLAUDE_PLUGIN_ROOT="$TMP/cucr-plugin" "$TMP/cucr-plugin/harness/hooks/session-start" 2>&1)"
  printf '%s\n' "${_cucro//\\n/$'\n'}"; }
# The owed paragraph: from its opening line to a blank line or the next Commissioning line.
_cucrowed() { printf '%s\n' "$1" | awk 'index($0, "A session still owes these") { on = 1; print; next }
                                         on && (/^$/ || /^Commissioning:/) { exit } on { print }'; }
_cucrunread="Commissioning: whether these answers are whole could not be read, so they are neither owed nor recorded; felix commission --status reads them again:
  cucr_unread (unknown: the rows of the answer could not be counted)
  cucr_none (no state)"
_cucrs1="$(_cucrstart)"
_cucrow="$(_cucrowed "$_cucrs1")"
is  "session start does not put a provider row whose state is unknown, or which has no state, among what a session owes" \
    "$(_cucrsays "$_cucrow" cucr_unread) $(_cucrsays "$_cucrow" cucr_none) $(_cucrsays "$_cucrow" 'cucr_owed (awaiting): ')" \
    "silent silent said"
is  "and names those rows on a line of their own, each with its state or no state" "$(_cucrsays "$_cucrs1" "$_cucrunread")" "said"
is  "and says it again on the next session start, not once per topology" "$(_cucrsays "$(_cucrstart)" "$_cucrunread")" "said"
{ printf 'cucr_unread\t-\t-\t-\tprovider:cucrplug:cucrskill\t-\t-\n'
  printf 'cucr_none\t-\t-\t-\tprovider:cucrplug:cucrskill\t-\t-\n'; } > "$_cucrp/commissioning.tsv"
_cucrs2="$(_cucrstart)"
is  "with only unread provider rows session start prints no paragraph saying a session owes anything, and still names them" \
    "$(_cucrsays "$_cucrs2" 'A session still owes these') $(_cucrsays "$_cucrs2" "$_cucrunread")" "silent said"
# After review, not blind: the once-per-topology receipt line is an all-clear,
# and one spent over rows nobody could read is never said again.
_cucrseen() { if [ -e "$FROOT/state/commission/cucrproj.seen" ]; then printf 'spent\n'; else printf 'kept\n'; fi; }
is  "and while they are unread it does not say the receipt line that is said once per topology, nor spend it" \
    "$(_cucrsays "$_cucrs2" 'Commissioning: receipt') $(_cucrseen)" "silent kept"
{ printf 'cucr_owed\t-\t-\t-\tprovider:cucrplug:cucrskill\t-\t-\n'; } > "$_cucrp/commissioning.tsv"
_cucrs3="$(_cucrstart)"
is  "and with only an awaiting provider row it is owed with its request path, and nothing is said to be unread" \
    "$(_cucrsays "$(_cucrowed "$_cucrs3")" 'cucr_owed (awaiting): ') $(_cucrsays "$_cucrs3" 'could not be read, so they are neither owed')" \
    "said silent"
{ printf 'cucr_plain\t-\t-\t-\t-\ttrue\t-\n'; } > "$_cucrp/commissioning.tsv"
_cucrs3="$(_cucrstart)"
is  "and with no provider row owed or unread it says the receipt line once and spends it" \
    "$(_cucrsays "$_cucrs3" 'Commissioning: receipt') $(_cucrseen)" "said spent"

rm -rf "$_cucrp" "$_cucrr" "$_cucrhome" "$TMP/cucr-plugin" "$MEM/cucrproj"
rm -f "$TMP/cucr-setup-ran" "$TMP/cucr-maint-ran"
[ -d "$FROOT/state" ] && find "$FROOT/state" -name '*cucrproj*' -exec rm -rf {} + 2>/dev/null
case "$_cucrmade" in *commission*) rmdir "$FROOT/state/commission" 2>/dev/null ;; esac
case "$_cucrmade" in state*) rmdir "$FROOT/state" 2>/dev/null ;; esac
is  "and this block leaves the projects, the state and the memory as it found them" "$(_cucrfixture)" "$_cucrfound"
unset -f _cucrfixture _cucrlib _cucrnext _cucrpulse _cucrcli _cucrline _cucrsays _cucrboth _cucrran _cucrstart _cucrowed _cucrseen
unset _cucrfound _cucrmade _cucrp _cucrr _cucrhome _cucrwhy _cucrsu1 _cucrms1 _cucrms0 _cucrsp1 _cucrnx1 _cucrnx0 _cucrn6 _cucrpu1 \
      _cucrout _cucrrc _cucrunread _cucrs1 _cucrs2 _cucrs3 _cucrow
