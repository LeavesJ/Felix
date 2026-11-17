# 2026-10-18 (judge refs): felix merge takes a full ref name as its base and
# refuses an expression such as HEAD~1, which git reads in its short-name order.
# The commit before the tip is therefore named by a branch made at it.
_mbase() { _fx_git "$1" update-ref refs/heads/jr-mbase HEAD~1 >/dev/null 2>&1; printf 'refs/heads/jr-mbase'; }
printf '\nmembership in a list larger than a pipe: coverage, candidates and gaps\n'
# Five engine tests asked whether a value was in a list by piping the list into
# grep -q under pipefail. grep stops reading at its first match; the writer's
# next write is SIGPIPE, pipefail makes the pipeline 141, and the test reads
# "not found" for a value that is present. Under load that happens now and
# then. It happens every time once the list is larger than a pipe holds and
# the match is early, because the writer is still blocked on a full pipe when
# grep leaves. So each list below is well over 256 KB with the value asked
# about on its first line, and beside each is the same question about the
# LAST line, which no early exit can miss: the control is what shows the
# fixture reaches the test, so a red here is the race and not a broken fixture.
_spm="$TMP/_spm"; mkdir -p "$_spm"
# Ninety characters of filler, so a few thousand names make a few hundred KB.
_spm_pad="$(awk 'BEGIN { s = sprintf("%090d", 0); gsub(/0/, "x", s); print s }')"
_spm_nl='
'
# Whole-line membership in captured output, read without a pipe.
_spm_line() { case "$_spm_nl$1$_spm_nl" in *"$_spm_nl$2$_spm_nl"*) return 0 ;; esac; return 1; }
# The rows of captured output whose column $3 is $2, for a failure message.
_spm_rows() { _SPM_K="$2" awk -F'\t' -v c="$3" '$c == ENVIRON["_SPM_K"]' <<<"$1" | tr '\n' ' '; }
# The first line of a value.
_spm_first() { printf '%s' "${1%%"$_spm_nl"*}"; }

# ------------------------------------------------------------- fixtures ----
# felix_coverage_check reads the events a hooks file binds. 3,000 filler
# events sit between the one bound first and the one bound last.
_spm_cov="$_spm/cov"; mkdir -p "$_spm_cov"
awk -v pad="$_spm_pad" 'BEGIN {
  printf "{\"hooks\": {\n  \"SpmFirstBound\": [],\n"
  for (i = 1; i <= 3000; i++) printf "  \"SpmFiller%s%05d\": [],\n", pad, i
  printf "  \"SpmLastBound\": []\n}}\n" }' > "$_spm_cov/hooks.json"

# felix_coverage_unconsidered reads the events a stance table lists, against
# what this machine binds. A fixture HOME binds the table's first event, its
# last, and one it never lists.
_spm_unc="$_spm/unc"; _spm_home="$_spm/home"; mkdir -p "$_spm_unc" "$_spm_home/.claude"
awk -v pad="$_spm_pad" 'BEGIN {
  printf "SpmFirstKnown\twired\tthe first row\n"
  for (i = 1; i <= 3000; i++) printf "SpmRow%s%05d\tdeclined\tfiller\n", pad, i
  printf "SpmLastKnown\twired\tthe last row\n" }' > "$_spm_unc/lifecycle.tsv"
printf '{"hooks":{"SpmFirstKnown":[],"SpmLastKnown":[],"SpmNeverListed":[]}}\n' \
  > "$_spm_home/.claude/settings.json"

# felix_candidates_rules reads the admitted obligation names, then the
# declared probe names after a C-locale sort. Zero-padded, so the sort keeps
# 00001 first and 09000 last. Memory is a root of this block's own.
_spm_cp="$_spm/spm-cand"; _spm_cr="$_spm/spm-cand-repo"; _spm_cmem="$_spm/mem"
mkdir -p "$_spm_cp" "$_spm_cr" "$_spm_cmem/spm-cand/commission"
awk 'BEGIN { for (i = 1; i <= 9000; i++)
  printf "spm_admitted_obligation_name_%05d\tADVISORY\tdeterministic\t-\ttrue\n", i }' \
  > "$_spm_cp/obligations.tsv"
awk 'BEGIN { for (i = 1; i <= 9000; i++)
  printf "spm_declared_probe_ground_name_%05d\t-\t-\tls\ttrue\n", i }' > "$_spm_cp/probes.tsv"
_spm_c1="$(printf 'spm_admitted_obligation_name_00001\tADVISORY\t-\ttrue\tspm_declared_probe_ground_name_09000\tunread\trepeats the first admitted row')"
_spm_c2="$(printf 'spm_admitted_obligation_name_09000\tADVISORY\t-\ttrue\tspm_declared_probe_ground_name_09000\tunread\trepeats the last admitted row')"
_spm_c3="$(printf 'spm_grounded_on_first\tADVISORY\t-\ttrue\tspm_declared_probe_ground_name_00001\tunread\tgrounded on the first declared probe')"
_spm_c4="$(printf 'spm_grounded_on_last\tADVISORY\t-\ttrue\tspm_declared_probe_ground_name_09000\tunread\tgrounded on the last declared probe')"
printf '# topology -\n# epoch -\n%s\n%s\n%s\n%s\ndone\t4\n' "$_spm_c1" "$_spm_c2" "$_spm_c3" "$_spm_c4" \
  > "$_spm_cmem/spm-cand/commission/obligations_surveyed.tsv"

# felix_commission_gaps reads awk's rows for one capability. One capability
# has 6,000 stack rows; another has one, the file's last.
_spm_gp="$_spm/gap-proj"; _spm_gr="$_spm/gap-repo"; mkdir -p "$_spm_gp" "$_spm_gr"
printf 'spmcapmany\nspmcaplast\n' > "$_spm_gp/capabilities"
awk 'BEGIN { for (i = 1; i <= 6000; i++)
  printf "plugin\tspm-served-plugin-%05d\tspm-marketplace\tlow\tspmcapmany\n", i
  printf "plugin\tspm-served-last\tspm-marketplace\tlow\tspmcaplast\n" }' > "$_spm_gp/stack.tsv"

# The lists each test reads, measured here from the fixtures: every one is
# well past a pipe's 64 KB, with the value asked about on its first line.
_spm_short=""
_spm_fits() { [ "${#2}" -ge 262144 ] && [ "$(_spm_first "$2" | cut -f1-2)" = "$3" ] \
                || _spm_short="$_spm_short $1 (${#2} bytes, first [$(_spm_first "$2" | cut -c1-40)])"; }
_spm_fits felix_coverage_check "$( . "$FROOT/harness/lib/coverage.sh"; felix_hooks_events "$_spm_cov/hooks.json" )" \
          SpmFirstBound
_spm_fits felix_coverage_unconsidered "$(cut -f1 "$_spm_unc/lifecycle.tsv")" SpmFirstKnown
_spm_fits felix_candidates_rules:admitted "$(cut -f1 "$_spm_cp/obligations.tsv")" spm_admitted_obligation_name_00001
_spm_fits felix_candidates_rules:grounds "$(cut -f1 "$_spm_cp/probes.tsv" | LC_ALL=C sort -u)" \
          spm_declared_probe_ground_name_00001
_spm_fits felix_commission_gaps "$(awk -F'\t' '$5 == "spmcapmany"' "$_spm_gp/stack.tsv")" \
          "$(printf 'plugin\tspm-served-plugin-00001')"
[ -z "$_spm_short" ] \
  && ok  "every membership fixture below holds more than 256 KB with the value asked about on its first line" \
  || bad "every membership fixture below holds more than 256 KB with the value asked about on its first line" \
         "too small or out of order, so a pass below would prove nothing:$_spm_short"

# ---------------------------------------- felix_coverage_check, declined ----
printf 'SpmFirstBound\tdeclined\tnothing to add\nSpmLastBound\tdeclined\tnothing to add\n' \
  > "$_spm_cov/lifecycle.tsv"
_spm_out="$( . "$FROOT/harness/lib/coverage.sh"; felix_coverage_check "$_spm_cov" "$_spm_cov/hooks.json" )"
_spm_line "$_spm_out" "missing	SpmFirstBound	declined, yet something wires it" \
  && ok  "a declined moment wired as the first of 3,000 bound events reads missing" \
  || bad "a declined moment wired as the first of 3,000 bound events reads missing" \
         "got [$(_spm_rows "$_spm_out" SpmFirstBound 2)]: grep -q left at line 1, the bound list's writer died of SIGPIPE, pipefail read the binding as absent, and a decline something wires passed as ok"
_spm_line "$_spm_out" "missing	SpmLastBound	declined, yet something wires it" \
  && ok  "a declined moment wired as the last of 3,000 bound events reads missing" \
  || bad "a declined moment wired as the last of 3,000 bound events reads missing" \
         "got [$(_spm_rows "$_spm_out" SpmLastBound 2)]: the fixture does not reach the coverage check"

# ------------------------------------------ felix_coverage_check, wired ----
printf 'SpmFirstBound\twired\trefuse completion\nSpmLastBound\twired\trefuse completion\n' \
  > "$_spm_cov/lifecycle.tsv"
_spm_out="$( . "$FROOT/harness/lib/coverage.sh"; felix_coverage_check "$_spm_cov" "$_spm_cov/hooks.json" )"
_spm_line "$_spm_out" "ok	SpmFirstBound	refuse completion" \
  && ok  "a wired moment bound as the first of 3,000 bound events reads ok" \
  || bad "a wired moment bound as the first of 3,000 bound events reads ok" \
         "got [$(_spm_rows "$_spm_out" SpmFirstBound 2)]: the early exit read a binding that is there as absent, and a wired hook was reported as nothing wiring it"
_spm_line "$_spm_out" "ok	SpmLastBound	refuse completion" \
  && ok  "a wired moment bound as the last of 3,000 bound events reads ok" \
  || bad "a wired moment bound as the last of 3,000 bound events reads ok" \
         "got [$(_spm_rows "$_spm_out" SpmLastBound 2)]: the fixture does not reach the coverage check"

# ------------------------------------------- felix_coverage_unconsidered ----
_spm_out="$( HOME="$_spm_home"; . "$FROOT/harness/lib/coverage.sh"; felix_coverage_unconsidered "$_spm_unc" )"
_spm_line "$_spm_out" "SpmFirstKnown" \
  && bad "a bound moment on the first row of a 3,000-row stance table is not named unconsidered" \
         "it was named: grep -q left at row 1, the table's writer died of SIGPIPE, and a moment the table considers read as one it has never heard of" \
  || ok  "a bound moment on the first row of a 3,000-row stance table is not named unconsidered"
_spm_line "$_spm_out" "SpmLastKnown" \
  && bad "a bound moment on the last row of a 3,000-row stance table is not named unconsidered" \
         "it was named, so the fixture does not reach the membership test: got [$(printf '%s' "$_spm_out" | tr '\n' ' ')]" \
  || ok  "a bound moment on the last row of a 3,000-row stance table is not named unconsidered"
_spm_line "$_spm_out" "SpmNeverListed" \
  && ok  "a bound moment the 3,000-row stance table never lists is named unconsidered" \
  || bad "a bound moment the 3,000-row stance table never lists is named unconsidered" \
         "got [$(printf '%s' "$_spm_out" | tr '\n' ' ')]: the fixture HOME's bindings were not read"

# -------------------------------------------------- felix_candidates_rules ----
_spm_out="$( ( FELIX_MEMORY="$_spm_cmem"
               . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"
               . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/epoch.sh"
               . "$FROOT/harness/lib/candidates.sh"
               felix_candidates_rules "$_spm_cp" "$_spm_cr" ) 2>/dev/null )"
_spm_line "$_spm_out" "refuse	spm_admitted_obligation_name_00001	already admitted in obligations.tsv" \
  && ok  "a candidate repeating the first of 9,000 admitted obligations is refused as already admitted" \
  || bad "a candidate repeating the first of 9,000 admitted obligations is refused as already admitted" \
         "got [$(_spm_rows "$_spm_out" spm_admitted_obligation_name_00001 2)]: the early exit read an admitted name as absent, and a duplicate of the ledger went on toward acceptance"
_spm_line "$_spm_out" "refuse	spm_admitted_obligation_name_09000	already admitted in obligations.tsv" \
  && ok  "a candidate repeating the last of 9,000 admitted obligations is refused as already admitted" \
  || bad "a candidate repeating the last of 9,000 admitted obligations is refused as already admitted" \
         "got [$(_spm_rows "$_spm_out" spm_admitted_obligation_name_09000 2)]: the fixture does not reach the admitted test"
_spm_line "$_spm_out" "accept	$_spm_c3" \
  && ok  "a candidate grounded on the first of 9,000 declared probes is accepted" \
  || bad "a candidate grounded on the first of 9,000 declared probes is accepted" \
         "got [$(_spm_rows "$_spm_out" spm_grounded_on_first 2)]: the early exit read a declared probe as undeclared, and a grounded proposal was refused as a fabrication"
_spm_line "$_spm_out" "accept	$_spm_c4" \
  && ok  "a candidate grounded on the last of 9,000 declared probes is accepted" \
  || bad "a candidate grounded on the last of 9,000 declared probes is accepted" \
         "got [$(_spm_rows "$_spm_out" spm_grounded_on_last 2)]: the fixture does not reach the grounds test"

# -------------------------------------------------- felix_commission_gaps ----
_spm_out="$( ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
               . "$FROOT/harness/lib/stack.sh"; . "$FROOT/harness/lib/probes.sh"
               . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/toolbox.sh"
               . "$FROOT/harness/lib/commission.sh"
               felix_commission_gaps "$_spm_gp" "$_spm_gr" ) 2>/dev/null )"
_spm_line "$_spm_out" "spmcapmany	yes	no	no" \
  && ok  "a capability 6,000 stack rows serve is reported served among the gaps" \
  || bad "a capability 6,000 stack rows serve is reported served among the gaps" \
         "got [$(_spm_rows "$_spm_out" spmcapmany 1)]: grep -q left at awk's first row, awk died of SIGPIPE, and a served capability was named a gap"
_spm_line "$_spm_out" "spmcaplast	yes	no	no" \
  && ok  "a capability only the last stack row serves is reported served among the gaps" \
  || bad "a capability only the last stack row serves is reported served among the gaps" \
         "got [$(_spm_rows "$_spm_out" spmcaplast 1)]: the fixture does not reach the served test"

printf '\nthe ledger, the grant listing and the pre-flight read a long list to its end\n'
# Each of these asked whether a value is one line of a list by piping the list
# into `grep -q`, under the suite's and the engine's `set -o pipefail`. grep
# stops reading at its first match; the writer's next write then meets a closed
# pipe, the writer dies of SIGPIPE, pipefail makes the pipeline 141, and the
# test reads "not there" for a line that is there. Past a pipe's capacity
# (64 KB) with the match on an early line that happens every time, so each
# fixture below holds a list of several hundred KB with the line asked about
# first, beside the same fixture with it last: the last line can never be
# missed this way, so the second says the fixture reaches the test at all.
_spg_root="$TMP/_spg"
mkdir -p "$_spg_root"

# The sessions nobody typed into. _felix_ledger_machine_sessions prints them
# from says.log in awk's own order, so which session is first and which is last
# is read from what it prints, not assumed. A home holds one of those sessions
# unfolded beside a person's, and both belong to this fixture's repository, so
# the walk reaches the membership test for each.
_spg_L="$_spg_root/ledger"
_spg_LP="$_spg_L/proj/spgledger"
mkdir -p "$_spg_L/mem/spgledger" "$_spg_LP" "$_spg_L/repo"
( _fx_cd "$_spg_L/repo" && git init -q -b main \
  && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m spg )
_spg_sha="$(git -C "$_spg_L/repo" rev-parse HEAD 2>/dev/null)"
# The opening's first 200 characters as a brief row keeps them, read from
# route.sh rather than copied, with a stamp before the day it gives.
_spg_open="$( . "$FROOT/harness/lib/route.sh"; printf '%s' "${_FELIX_ROUTE_SESSION_REQUESTS[0]:0:200}" )"
_SPG_OPEN="$_spg_open" LC_ALL=C awk 'BEGIN {
    o = ENVIRON["_SPG_OPEN"]
    for (i = 1; i <= 8000; i++)
      printf "2026-09-10T08:00:00Z\tbrief\tspg-machine-%05d-0123456789abcdef0123456789\t%s\tUse this now\n", i, o
  }' > "$_spg_L/mem/spgledger/says.log"
_spg_machine() { ( FELIX_MEMORY="$_spg_L/mem"; export FELIX_MEMORY
                   . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
                   _felix_ledger_machine_sessions "$_spg_LP" ) 2>/dev/null; }
_spg_ms="$(_spg_machine)"
_spg_m1="$(printf '%s\n' "$_spg_ms" | sed -n 1p)"
_spg_mN="$(printf '%s\n' "$_spg_ms" | sed -n '$p')"
if [ "${#_spg_ms}" -gt 262144 ] && [ -n "$_spg_m1" ] && [ -n "$_spg_mN" ] && [ "$_spg_m1" != "$_spg_mN" ] \
   && [ -n "$_spg_sha" ]; then
  ok  "the machine-session fixture lists more than a pipe holds, with a first and a last session"
else
  bad "the machine-session fixture lists more than a pipe holds, with a first and a last session" \
      "${#_spg_ms} bytes, first [$_spg_m1], last [$_spg_mN], sha [$_spg_sha]"
fi
_spg_home() {    # dir, machine session, person session: two unfolded sessions this repository owns
  mkdir -p "$1/state/ledger" "$1/state/session"
  printf '%s\n' "$_spg_sha" > "$1/state/session/$2"
  printf '%s\n' "$_spg_sha" > "$1/state/session/$3"
  printf 'named\tsuperpowers:systematic-debugging\n' > "$1/state/ledger/$2.tsv"
  printf 'tool\tRead\n' > "$1/state/ledger/$3.tsv"
}
_spg_home "$_spg_L/first" "$_spg_m1" spg-person-first
_spg_home "$_spg_L/last"  "$_spg_mN" spg-person-last
# Sourced the way session-start sources it, ledger.sh without route.sh.
_spg_ledger() {  # fn, home
  ( FELIX_MEMORY="$_spg_L/mem"; export FELIX_MEMORY
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
    "$1" "$_spg_LP" "$2" "$_spg_L/repo" ) 2>&1
}
_spg_out="$(_spg_ledger felix_ledger_stranded "$_spg_L/first")"
[ "$_spg_out" = "1" ] \
  && ok  "session-start does not count the first of many machine sessions as stranded, only the person's beside it" \
  || bad "session-start does not count the first of many machine sessions as stranded, only the person's beside it" \
         "counted [$_spg_out], expected [1]: the machine session was missed in the list and counted stranded, so the banner carries a caveat it did not need"
is "nor the last of many machine sessions" \
   "$(_spg_ledger felix_ledger_stranded "$_spg_L/last")" "1"
_spg_out="$(_spg_ledger felix_ledger_catchup "$_spg_L/first")"
[ "$_spg_out" = "1" ] \
  && ok  "felix ledger folds the person's session and passes over the first of many machine sessions" \
  || bad "felix ledger folds the person's session and passes over the first of many machine sessions" \
         "folded [$_spg_out], expected [1]: the machine session was missed in the list and rolled up with the person's"
[ -f "$_spg_L/mem/spgledger/ledger.d/$_spg_m1.tsv" ] \
  && bad "and writes no fold for that machine session into memory" \
         "ledger.d/$_spg_m1.tsv was written: the session was missed in the list and rolled up" \
  || ok  "and writes no fold for that machine session into memory"
[ -f "$_spg_L/mem/spgledger/ledger.d/spg-person-first.tsv" ] \
  && ok  "while the person's session beside that machine session is folded" \
  || bad "while the person's session beside that machine session is folded" "no ledger.d/spg-person-first.tsv"
_spg_out="$(_spg_ledger felix_ledger_catchup "$_spg_L/last")"
if [ "$_spg_out" = "1" ] && [ ! -f "$_spg_L/mem/spgledger/ledger.d/$_spg_mN.tsv" ] \
   && [ -f "$_spg_L/mem/spgledger/ledger.d/spg-person-last.tsv" ]; then
  ok  "and felix ledger passes over the last of many machine sessions the same way"
else
  bad "and felix ledger passes over the last of many machine sessions the same way" \
      "folded [$_spg_out]; $(ls "$_spg_L/mem/spgledger/ledger.d" 2>/dev/null | tr '\n' ' ')"
fi

# Grants at the base ref, against what this tree holds. A row the base holds is
# merged, whatever else the base holds; listed as written-and-not-merged it
# tells the person a grant is not yet one when it is. The base holds thousands
# of well-formed rows; this tree holds one of them and one row of its own, and
# only its own is unmerged.
_spg_X="$_spg_root/exc"
mkdir -p "$_spg_X/projects/spgexc"
LC_ALL=C awk 'BEGIN {
    for (i = 1; i <= 8000; i++)
      printf "spg-grant-%05d\t0123456789abcdef\t2027-06-30T12:00:00Z\tfounder\ta grant the fixture merged, number %05d\n", i, i
  }' > "$_spg_X/projects/spgexc/exceptions.tsv"
( _fx_cd "$_spg_X" && git init -q -b main && git add projects \
  && git -c user.name=t -c user.email=t@t commit -q -m spg \
  && git update-ref refs/remotes/origin/main HEAD )
_spg_XP="$_spg_X/projects/spgexc"
_spg_x1="$(sed -n 1p "$_spg_XP/exceptions.tsv")"
_spg_xN="$(sed -n '$p' "$_spg_XP/exceptions.tsv")"
_spg_xnew="$(printf 'spg-written\t0123456789abcdef\t2027-06-30T12:00:00Z\tfounder\twritten here and not merged')"
_spg_xbase="$( . "$FROOT/harness/lib/exceptions.sh"; felix_exceptions_at_base "$_spg_XP" 2>/dev/null )"
if [ "${#_spg_xbase}" -gt 262144 ] && [ "$(printf '%s\n' "$_spg_xbase" | sed -n 1p)" = "$_spg_x1" ]; then
  ok  "the grant fixture's base ref holds more than a pipe holds, starting with the row asked about"
else
  bad "the grant fixture's base ref holds more than a pipe holds, starting with the row asked about" \
      "${#_spg_xbase} bytes at refs/remotes/origin/main"
fi
_spg_unmerged() { ( . "$FROOT/harness/lib/exceptions.sh"; felix_exceptions_unmerged "$_spg_XP" ) 2>&1; }
printf '%s\n%s\n' "$_spg_x1" "$_spg_xnew" > "$_spg_XP/exceptions.tsv"
_spg_out="$(_spg_unmerged)"
[ "$_spg_out" = "$_spg_xnew" ] \
  && ok  "a grant merged first among thousands is not listed as written and not merged" \
  || bad "a grant merged first among thousands is not listed as written and not merged" \
         "listed [$_spg_out]: the merged grant was missed at the base ref and shown as not yet a grant"
printf '%s\n%s\n' "$_spg_xN" "$_spg_xnew" > "$_spg_XP/exceptions.tsv"
is "nor a grant merged last among thousands" \
   "$(_spg_unmerged)" "$_spg_xnew"

# The pre-flight's second look, for a plugin compiled into the binary. The CLI
# here is a stand-in that lists nothing, so the only answer is the inventory's:
# several hundred KB of plugins, the one asked about first, and then last. This
# one could not miss even through the pipe: felix_ready_inventory ends in
# `return 0`, so the sort that dies of SIGPIPE under an early match is not the
# status pipefail reads. So these are not red on the old engine; they hold that
# the test which replaces the pipe keeps the verdict at this size.
_spg_R="$_spg_root/ready"
mkdir -p "$_spg_R/bin" "$_spg_R/home/.claude/plugins" "$_spg_R/proj"
printf '#!/bin/sh\nprintf "[]\\n"\n' > "$_spg_R/bin/claude"; chmod +x "$_spg_R/bin/claude"
{ printf '{\n  "version": 2,\n  "plugins": {\n'
  printf '    "spga@spgmkt": [\n      {}\n    ],\n'
  LC_ALL=C awk 'BEGIN { for (i = 1; i <= 16000; i++) printf "    \"spgm%05d-bundled-filler@spgmkt\": [\n      {}\n    ],\n", i }'
  printf '    "spgz@spgmkt": [\n      {}\n    ]\n  }\n}\n'
} > "$_spg_R/home/.claude/plugins/installed_plugins.json"
_spg_inv="$( HOME="$_spg_R/home" PATH="$_spg_R/bin:/usr/bin:/bin"
             . "$FROOT/harness/lib/ready.sh"; felix_ready_inventory 2>/dev/null )"
if [ "${#_spg_inv}" -gt 262144 ] \
   && [ "$(printf '%s\n' "$_spg_inv" | sed -n 1p)" = "plugin	spga" ] \
   && [ "$(printf '%s\n' "$_spg_inv" | sed -n '$p')" = "plugin	spgz" ]; then
  ok  "the pre-flight fixture's inventory holds more than a pipe holds, the plugin asked about first and last"
else
  bad "the pre-flight fixture's inventory holds more than a pipe holds, the plugin asked about first and last" \
      "${#_spg_inv} bytes, first [$(printf '%s\n' "$_spg_inv" | sed -n 1p)], last [$(printf '%s\n' "$_spg_inv" | sed -n '$p')]"
fi
_spg_ready() {   # owner: the report for one play of that owner, declared in stack.tsv
  printf 'plugin\t%s@spgmkt\t-\tlow\talways\n' "$1" > "$_spg_R/proj/stack.tsv"
  printf 'spgroute\tspg\tcore\t%s:thing\n' "$1" > "$_spg_R/proj/routes.tsv"
  ( HOME="$_spg_R/home" PATH="$_spg_R/bin:/usr/bin:/bin"
    . "$FROOT/harness/lib/ready.sh"; felix_ready_report "$_spg_R/proj" ) 2>&1
}
is "a bundled plugin first among many in the inventory reads as usable" \
   "$(_spg_ready spga)" "usable	spga:thing	bundled, live in every session"
is "and a bundled plugin last among them" \
   "$(_spg_ready spgz)" "usable	spgz:thing	bundled, live in every session"

printf '\nthe CLI reads an answer to its end before it decides on it\n'
# Three CLI verdicts rested on `producer | grep -q`, and under pipefail that
# reads "absent" whenever grep matches and leaves while the producer still has
# lines to write: the producer's next write is EPIPE, it dies 141, and the
# pipeline's status is 141. Each fixture below makes the producer's output far
# larger than a pipe holds with the match on its first line, which turns the
# race into a certainty, and pairs it with the same call whose match is on the
# LAST line, which no reader can leave early. The pair is what keeps a red here
# honest: a fixture the engine rejected for some other reason would fail the
# control too.
#
# A home and a memory root of this block's own, so no project the rest of the
# suite counts or iterates gains a neighbour.
_spc_home="$TMP/_spc_home"; _spc_mem="$TMP/_spc_mem"; _spc_kc="$TMP/_spc_kc"
_spc_proj="$_spc_home/projects/_spc_cli"
mkdir -p "$_spc_proj" "$_spc_mem"
printf '{"name":"_spc_cli","gate":"true"}\n' > "$_spc_proj/project.json"
printf '# _spc_cli\n' > "$_spc_proj/CLAUDE.md"
_spc_repo="$TMP/_spc_repo"; mkdir -p "$_spc_repo"
( _fx_cd "$_spc_repo" && git init -q -b main && printf '_spc_cli\n' > .felix && printf 'x\n' > a.txt \
  && git add -A >/dev/null && git -c user.name=t -c user.email=t@t commit -qm base >/dev/null )
_spc_repo="$(cd "$_spc_repo" && pwd -P)"
_spc_felix() { ( _spc_at="$1"; shift; cd "$_spc_at" || exit 99
                 FELIX_KERNEL='' FELIX_KERNEL_CACHE="$_spc_kc" FELIX_HOME="$_spc_home" FELIX_MEMORY="$_spc_mem" \
                   "$FELIX" "$@" ); }

# felix maintenance --ran. The name is checked against `_felix_maint_rows | cut
# -f1`, and a false miss dies `no routine named X` for a routine the table
# declares, so a run that happened goes unrecorded.
awk 'BEGIN { for (i = 1; i <= 20000; i++) printf "routine-%06d\t7\talways\tupkeep number %d\n", i, i }' \
  > "$_spc_proj/maintenance.tsv"
_spc_n="$(cut -f1 "$_spc_proj/maintenance.tsv" | wc -c | tr -d ' ')"
[ "${_spc_n:-0}" -ge 262144 ] \
  && ok "the maintenance fixture names more routines than a pipe holds" \
  || bad "the maintenance fixture names more routines than a pipe holds" "only ${_spc_n:-0} bytes of names"
_spc_out="$(_spc_felix "$_spc_repo" maintenance --ran routine-000001 2>&1)"; _spc_rc=$?
if [ "$_spc_rc" -eq 0 ] && grep -q '^routine-000001	' "$_spc_proj/maintenance.log" 2>/dev/null; then
  has "a run of the first routine is recorded however many routines follow it" "$_spc_out" "recorded a run of routine-000001"
else
  bad "a run of the first routine is recorded however many routines follow it" \
      "the routine is row 1 of the table and the run was refused and not logged (rc=$_spc_rc): $_spc_out"
fi
_spc_out="$(_spc_felix "$_spc_repo" maintenance --ran routine-020000 2>&1)"; _spc_rc=$?
if [ "$_spc_rc" -eq 0 ] && grep -q '^routine-020000	' "$_spc_proj/maintenance.log" 2>/dev/null; then
  has "and a run of the last routine is recorded too" "$_spc_out" "recorded a run of routine-020000"
else
  bad "and a run of the last routine is recorded too" "rc=$_spc_rc: $_spc_out"
fi
# A routine name is one line. A value holding a newline names no routine, even
# when its lines are two routines next to each other in the table: logged, it
# leaves a line with no epoch, and that routine reads as never run. The lines
# are the table's last two, so no early exit is what refuses them.
_spc_out="$(_spc_felix "$_spc_repo" maintenance --ran "$(printf 'routine-019999\nroutine-020000')" 2>&1)"; _spc_rc=$?
if [ "$_spc_rc" -ne 0 ] && ! grep -q '^routine-019999' "$_spc_proj/maintenance.log" 2>/dev/null; then
  ok  "a routine name holding a newline is refused, even when its lines are two adjacent routines"
else
  bad "a routine name holding a newline is refused, even when its lines are two adjacent routines" \
      "the two-line name was taken for a routine and logged, leaving a line with no epoch (rc=$_spc_rc): $_spc_out"
fi

# felix evidence. A base that resolves to nothing yields one `unknown` row and
# no other, and the report must end on it and exit 1 (#63). A false miss falls
# through to the rendering, which has no arm for `unknown`, and signs off with
# "No evidence gaps." and exit 0: the false all-clear #56 removed. The row is
# multi-line only when the base NAME holds newlines — nothing else puts text
# after it — so that is the fixture.
#
# Sourced and called rather than executed, and only for this one: Linux caps a
# single argv string at 128 KB (MAX_ARG_STRLEN), under the margin that makes
# the race certain, and a refusal from execve would be red for the wrong
# reason. The git calls inside meet the same cap there and fail, which reads
# as "does not resolve" — the answer this base gets anyway.
printf 'unit\t^src/\t^tests?/\tcode changes need a test\n' > "$_spc_proj/evidence.tsv"
_spc_big="$(awk 'BEGIN { for (i = 1; i <= 20000; i++) printf "no-such-ref-%06d\n", i }')"
_spc_one="$(printf '%s' "$_spc_big" | tr '\n' '-')"
[ "${#_spc_big}" -ge 262144 ] \
  && ok "the evidence fixture's base is larger than a pipe holds" \
  || bad "the evidence fixture's base is larger than a pipe holds" "only ${#_spc_big} bytes"
_spc_ev() { ( _spc_b="$1"; cd "$_spc_repo" || exit 99
              export FELIX_HOME="$_spc_home" FELIX_MEMORY="$_spc_mem"
              . "$FELIX" help >/dev/null 2>&1
              cmd_evidence --base "$_spc_b" ) > "$TMP/_spc_ev.out" 2>&1; }
_spc_ev "$_spc_big"; _spc_rc=$?
_spc_tail="$(tail -n 4 "$TMP/_spc_ev.out")"
case "$_spc_rc:$_spc_tail" in
  *"No evidence gaps"*)
    bad "an unknown evidence row is not an all-clear however much text follows it" \
        "the unknown row was missed and the report signed off (rc=$_spc_rc): $_spc_tail" ;;
  "1:"*"Nothing was compared"*)
    ok  "an unknown evidence row is not an all-clear however much text follows it" ;;
  *)
    bad "an unknown evidence row is not an all-clear however much text follows it" "rc=$_spc_rc: $_spc_tail" ;;
esac
# The control: the same base, the same size, as one line. One line is the last
# line, and grep cannot call it matched before it has read all of it.
_spc_ev "$_spc_one"; _spc_rc=$?
_spc_tail="$(tail -n 4 "$TMP/_spc_ev.out")"
case "$_spc_rc:$_spc_tail" in
  "1:"*"Nothing was compared"*) ok  "and a base of the same size on one line is reported unknown too" ;;
  *)                            bad "and a base of the same size on one line is reported unknown too" "rc=$_spc_rc: $_spc_tail" ;;
esac

# felix merge. A self-governed branch that touches engine/harness/ is refused
# when the judge is byte-identical to the tree it judges. The test reads
# felix_changed_paths, which ends in `sort -u`, and a false miss skips the
# refusal: the candidate is judged by itself. Two checkouts that differ only in
# where the engine path sorts among 700 long changed paths — first, under zz/,
# and last, under aa/. The engine in them is one file, so main's missing
# resolve.sh is what the next check trips on if this one is skipped, and
# nothing here reaches a receipt or gh.
_spc_mgrepo() {   # dir, top directory of the filler
  _spc_d="$1"; _spc_top="$2"; _spc_i=1
  mkdir -p "$_spc_d/engine/.claude-plugin" "$_spc_d/engine/harness/lib"
  printf '{ "version": "1.0.0" }\n' > "$_spc_d/engine/.claude-plugin/plugin.json"
  printf '# judged\n' > "$_spc_d/engine/harness/lib/x.sh"
  printf '_spc_cli\n' > "$_spc_d/.felix"
  ( _fx_cd "$_spc_d" && git init -q -b main && git add -A >/dev/null \
    && git -c user.name=t -c user.email=t@t commit -qm base >/dev/null && git checkout -q -b feature )
  printf -v _spc_long '%0200d' 0
  mkdir -p "$_spc_d/$_spc_top/$_spc_long"
  while [ "$_spc_i" -le 700 ]; do
    printf -v _spc_f 'f%0199d' "$_spc_i"; : > "$_spc_d/$_spc_top/$_spc_long/$_spc_f"
    _spc_i=$((_spc_i + 1))
  done
  printf '# candidate edit\n' >> "$_spc_d/engine/harness/lib/x.sh"
  ( _fx_cd "$_spc_d" && git add -A >/dev/null && git -c user.name=t -c user.email=t@t commit -qm candidate >/dev/null )
}
_spc_early="$TMP/_spc_mg_early"; _spc_late="$TMP/_spc_mg_late"
_spc_mgrepo "$_spc_early" zz; _spc_mgrepo "$_spc_late" aa
_spc_early="$(cd "$_spc_early" && pwd -P)"; _spc_late="$(cd "$_spc_late" && pwd -P)"
# The judge for main's version, cut from the candidate: identical to the tree.
mkdir -p "$_spc_kc/1.0.0"
cp -R "$_spc_early/engine/harness" "$_spc_kc/1.0.0/harness"
git -C "$_spc_early" diff --name-only --no-renames 'HEAD~1...HEAD' | LC_ALL=C sort -u > "$TMP/_spc_mg.paths"
_spc_n="$(wc -c < "$TMP/_spc_mg.paths" | tr -d ' ')"; _spc_first="$(head -1 "$TMP/_spc_mg.paths")"
if [ "${_spc_n:-0}" -ge 262144 ] && [ "$_spc_first" = "engine/harness/lib/x.sh" ]; then
  ok "the merge fixture changes more paths than a pipe holds, the engine's first"
else
  bad "the merge fixture changes more paths than a pipe holds, the engine's first" "${_spc_n:-0} bytes, first: $_spc_first"
fi
_spc_felix "$_spc_early" merge --base "$(_mbase "$_spc_early")" > "$TMP/_spc_mg.out" 2>&1; _spc_rc=$?
if [ "$_spc_rc" -eq 1 ] && grep -q 'judging itself' "$TMP/_spc_mg.out"; then
  ok "a judge identical to the tree is refused when the engine path sorts first of many"
else
  bad "a judge identical to the tree is refused when the engine path sorts first of many" \
      "the engine change was missed and the candidate went on to be judged by itself (rc=$_spc_rc): $(cat "$TMP/_spc_mg.out")"
fi
_spc_felix "$_spc_late" merge --base "$(_mbase "$_spc_late")" > "$TMP/_spc_mg.out" 2>&1; _spc_rc=$?
if [ "$_spc_rc" -eq 1 ] && grep -q 'judging itself' "$TMP/_spc_mg.out"; then
  ok "and the judge is refused when the engine path sorts last"
else
  bad "and the judge is refused when the engine path sorts last" "rc=$_spc_rc: $(cat "$TMP/_spc_mg.out")"
fi

