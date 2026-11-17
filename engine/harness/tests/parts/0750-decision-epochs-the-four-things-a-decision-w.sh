printf '\ndecision epochs: the four things a decision was made under\n'
# v3.2 §3 defines the epoch as hash(subject_identity, topology_version,
# policy_version, release_target), and the whole no-backsliding rule hangs off
# it: inside one epoch admitted blocking obligations may hold or grow and
# discovery may not remove or relax them, and it is a NEW grounded topology or
# a NEW policy state that reopens applicability.
#
# So there are exactly two properties worth asserting, and they are opposites.
# A number that drifted on its own would silently reopen every obligation a
# project had already admitted. A number that sat still while the world moved
# would freeze a project under a topology it no longer has. Everything below is
# one or the other: stable when nothing about the decision context changed,
# different when any of the four inputs did.
EPP="$TMP/epoch-proj"; mkdir -p "$EPP" "$MEM/epoch-proj"
EPR="$TMP/epoch-repo"; mkdir -p "$EPR/members"
printf 'a\n' > "$EPR/members/a.txt"
printf 'x\n' > "$EPR/tracked.txt"
# The branch is `sideways` deliberately. The last step of the release-target
# precedence chain is the literal string `main`, and on a checkout whose branch
# happens to be named main that assertion would pass whether the fallback is
# implemented or whether the current branch is being read by accident.
( _fx_cd "$EPR" && git init -q -b sideways && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
EPR="$(cd "$EPR" && pwd -P)"

# A checkout that does have a default branch of its own, and one that is not
# main either, so reading origin/HEAD and defaulting can be told apart.
EPO="$TMP/epoch-origin-repo"; mkdir -p "$EPO"
( _fx_cd "$EPO" && git init -q -b sideways && printf 'x\n' > f.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm init \
  && git remote add origin https://example.com/epoch-origin.git \
  && git update-ref refs/remotes/origin/trunk HEAD \
  && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/trunk ) >/dev/null 2>&1
EPO="$(cd "$EPO" && pwd -P)"

# The three tables are written by functions rather than patched in place: every
# assertion below either varies one of them and puts it back, or claims the
# value did not move, and `sed -i` with a \t is not portable between BSD and
# GNU sed — the substitution silently matches nothing on one of them, which is
# how an assertion about a hash that moved passes while nothing moved.
#
# $1 is the remote_match, $2 a release_target written only when non-empty.
_ep_json() {
  { printf '{\n  "name": "epoch-proj",\n'
    printf '  "remote_match": "%s",\n' "${1:-example.com/epoch-proj}"
    [ -n "${2:-}" ] && printf '  "release_target": "%s",\n' "$2"
    printf '  "gate": "true"\n}\n'
  } > "$EPP/project.json"
}
# $1 `swapped` reverses the row order without changing a single fact; $2 is an
# extra line appended verbatim. Both rows are real five-column rows whose `when`
# is `-`, because a malformed `when` reads as unknown with a count of zero, and
# an unknown count does not move when the world does — every assertion here
# would then be green for the wrong reason.
_ep_table() {
  { printf '# predicate\tgrounds\twhen\tprobe\twitness\n'
    case "${1:-}" in
      swapped)
        printf 'tracked\t-\t-\tgit ls-files\tgit ls-tree -r HEAD --name-only 2>/dev/null | grep -q .\n'
        printf 'member\t-\t-\tls -1 members\ttest -d members\n' ;;
      *)
        printf 'member\t-\t-\tls -1 members\ttest -d members\n'
        printf 'tracked\t-\t-\tgit ls-files\tgit ls-tree -r HEAD --name-only 2>/dev/null | grep -q .\n' ;;
    esac
    [ -n "${2:-}" ] && printf '%s\n' "$2"
  } > "$EPP/probes.tsv"
}
# A table in the policy set that is neither the subject nor the probes, so a
# policy change can be made without moving anything else.
_ep_oblig() {
  { printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds\n'
    [ -n "${1:-}" ] && printf '%s\n' "$1"
  } > "$EPP/obligations.tsv"
}
_ep_json; _ep_table; _ep_oblig

# A project whose probe table holds no rows, for the negative topology cases.
EPN="$TMP/epoch-noprobes"; mkdir -p "$EPN" "$MEM/epoch-noprobes"
cp "$EPP/project.json" "$EPN/project.json"
cp "$EPP/obligations.tsv" "$EPN/obligations.tsv"
printf '# a table nobody has filled in yet\n' > "$EPN/probes.tsv"
EPX="$TMP/epoch-not-a-project"

_ep_subject()    { ( unset FELIX_RELEASE_TARGET; . "$FROOT/harness/lib/epoch.sh"
                     felix_epoch_subject    "${1:-$EPP}" ); }
_ep_topology()   { ( unset FELIX_RELEASE_TARGET; . "$FROOT/harness/lib/epoch.sh"
                     felix_epoch_topology   "${1:-$EPP}" "${2:-$EPR}" ); }
_ep_policy()     { ( unset FELIX_RELEASE_TARGET; . "$FROOT/harness/lib/epoch.sh"
                     felix_epoch_policy     "${1:-$EPP}" ); }
_ep_components() { ( unset FELIX_RELEASE_TARGET; . "$FROOT/harness/lib/epoch.sh"
                     felix_epoch_components "${1:-$EPP}" "${2:-$EPR}" ); }
_ep_hash()       { ( unset FELIX_RELEASE_TARGET; . "$FROOT/harness/lib/epoch.sh"
                     felix_epoch            "${1:-$EPP}" "${2:-$EPR}" ); }
# $1 is what FELIX_RELEASE_TARGET holds for this one run: `-` means unset,
# anything else is exported verbatim, the empty string included — set-but-empty
# and unset are two different states and the precedence chain treats them alike
# only if it says so.
_ep_target() { ( case "${1--}" in
                   -) unset FELIX_RELEASE_TARGET ;;
                   *) export FELIX_RELEASE_TARGET="$1" ;;
                 esac
                 . "$FROOT/harness/lib/epoch.sh"
                 felix_epoch_target "${2:-$EPP}" "${3:-$EPR}" ); }
_ep_hash_under() { ( export FELIX_RELEASE_TARGET="$1"
                     . "$FROOT/harness/lib/epoch.sh"; felix_epoch "$EPP" "$EPR" ); }
_ep_same() { [ "$1" = "$2" ] && echo same || echo different; }

# ------------------------------------------------------------- subject ------
ep_subj0="$(_ep_subject)"
is "a subject identity is one line"                       "$(printf '%s' "$ep_subj0" | grep -c .)" "1"
is "the same project identifies the same subject twice"   "$(_ep_subject)" "$ep_subj0"
_ep_json "example.com/somewhere-else"
is "a different remote_match is a different subject"      "$(_ep_same "$(_ep_subject)" "$ep_subj0")" "different"
# Content-addressed, not a counter and not a clock: the identity of a project
# whose project.json is put back is the identity it had.
_ep_json
is "and the old remote_match brings the old subject back"  "$(_ep_subject)" "$ep_subj0"

out="$(_ep_subject "$EPX")"; rc=$?
is "a project directory that is not there identifies no subject" "${#out}" "0"
[ "$rc" -ne 0 ] && ok  "and says so with a non-zero status" \
                || bad "and says so with a non-zero status" "exited 0 having printed nothing"

# ------------------------------------------------------------ topology ------
ep_topo0="$(_ep_topology)"
is "a grounded topology is one line" "$(printf '%s' "$ep_topo0" | grep -c .)" "1"
printf 'b\n' > "$EPR/members/b.txt"
is "a probe that enumerates one more member is a new topology" \
   "$(_ep_same "$(_ep_topology)" "$ep_topo0")" "different"
rm -f "$EPR/members/b.txt"
is "and the topology comes back when the member goes away" "$(_ep_topology)" "$ep_topo0"
# The topology is a fact about what was found in this checkout, not about how a
# table was sorted. A hash that folded in row order would declare a new epoch —
# and reopen applicability for every obligation — because somebody tidied a TSV.
_ep_table swapped
is "the same facts in a different row order are the same topology" "$(_ep_topology)" "$ep_topo0"
_ep_table

out="$(_ep_topology "$EPN")"; rc=$?
is "a project that declares no probes has no topology" "${#out}" "0"
[ "$rc" -ne 0 ] && ok  "and refuses rather than hashing over nothing" \
                || bad "and refuses rather than hashing over nothing" "exited 0 having printed nothing"
rm -f "$EPN/probes.tsv"
out="$(_ep_topology "$EPN")"; rc=$?
is "an absent probes.tsv is no topology either" "${#out}" "0"
[ "$rc" -ne 0 ] && ok  "and an absent table refuses with a non-zero status too" \
                || bad "and an absent table refuses with a non-zero status too" "exited 0 having printed nothing"
printf '# a table nobody has filled in yet\n' > "$EPN/probes.tsv"

# -------------------------------------------------------------- policy ------
ep_pol0="$(_ep_policy)"
is "a policy version is one line" "$(printf '%s' "$ep_pol0" | grep -c .)" "1"
_ep_oblig 'second	RELEASE_BLOCKING	deterministic	-	true	-	and now it owes two'
is "editing a table in the set is a new policy version" \
   "$(_ep_same "$(_ep_policy)" "$ep_pol0")" "different"
_ep_oblig
is "and putting the table back puts the policy version back" "$(_ep_policy)" "$ep_pol0"
_ep_table "" 'extra	-	-	ls -1 members	test -d members'
is "the probe table is in the set too" "$(_ep_same "$(_ep_policy)" "$ep_pol0")" "different"
_ep_table
_ep_json "example.com/moved"
is "and so is project.json" "$(_ep_same "$(_ep_policy)" "$ep_pol0")" "different"
_ep_json
# A comment is content. A policy version computed over rows rather than bytes
# would report the same policy state after somebody rewrote what a table means
# to the person maintaining it, which is the half of a policy that reviews are
# actually conducted in.
_ep_table "" '# a comment line, which is content and not whitespace'
is "adding a comment line changes the policy version" \
   "$(_ep_same "$(_ep_policy)" "$ep_pol0")" "different"
_ep_table

# -------------------------------------------------------------- target ------
is "FELIX_RELEASE_TARGET decides the target when it is set" "$(_ep_target hotfix-7)" "hotfix-7"
_ep_json "example.com/epoch-proj" "release/9"
is "an empty FELIX_RELEASE_TARGET is not a target"          "$(_ep_target '')" "release/9"
is "project.json names the target when the environment does not" "$(_ep_target -)" "release/9"
_ep_json
is "the checkout's own default branch is next, without the origin/ prefix" \
   "$(_ep_target - "$EPP" "$EPO")" "trunk"
is "and a checkout with no default branch of its own falls back to main" \
   "$(_ep_target - "$EPP" "$EPR")" "main"

# ------------------------------------------------------- one line each ------
# Each of the five says it prints one line, and a line is a terminator as well
# as a count. Output with no newline on the end is not a line, it is a prefix
# of whatever gets printed next: two of these appended to the same file read
# back as one hash, and a caller that pipes one into `read` gets nothing. This
# repository has already paid once for a count that arrived as two lines.
#
# Collected rather than asserted five times, so the failure names the functions
# rather than the property.
_ep_lastbyte() { ( unset FELIX_RELEASE_TARGET; . "$FROOT/harness/lib/epoch.sh"
                   "$@" ) | tail -c1 | od -An -tx1 | tr -d ' \n'; }
ep_unterminated=""
for _ep_f in felix_epoch_subject felix_epoch_policy; do
  [ "$(_ep_lastbyte "$_ep_f" "$EPP")" = "0a" ] || ep_unterminated="$ep_unterminated $_ep_f"
done
for _ep_f in felix_epoch_topology felix_epoch_target felix_epoch; do
  [ "$(_ep_lastbyte "$_ep_f" "$EPP" "$EPR")" = "0a" ] || ep_unterminated="$ep_unterminated $_ep_f"
done
is "every one of them terminates the line it printed" "${ep_unterminated# }" ""

# ---------------------------------------------------------- components ------
out="$(_ep_components)"; rc=$?
is "components prints exactly four lines" "$(printf '%s\n' "$out" | grep -c .)" "4"
is "named in the order the architecture states them" \
   "$(printf '%s\n' "$out" | cut -f1 | paste -sd, -)" \
   "subject_identity,topology_version,policy_version,release_target"
is "each line is a name and a value separated by a tab" \
   "$(printf '%s\n' "$out" | awk -F'\t' 'NF == 2 && $1 != "" && $2 != "" { n++ } END { print n+0 }')" "4"
is "and the values are the ones the four functions compute" \
   "$(printf '%s\n' "$out" | cut -f2 | paste -sd, -)" \
   "$ep_subj0,$ep_topo0,$ep_pol0,$(_ep_target -)"
is "components exits 0 when all four are known" "$rc" "0"

out="$(_ep_components "$EPN")"; rc=$?
is "a component that cannot be computed prints as a dash" \
   "$(printf '%s\n' "$out" | awk -F'\t' '$1 == "topology_version" { print $2 }')" "-"
is "and the other three are still there beside it" "$(printf '%s\n' "$out" | grep -c .)" "4"
is "components exits 0 with a component missing" "$rc" "0"
# The report says what is unknown rather than declining to report. Whoever is
# reading it is trying to find out why an epoch would not compute, and a
# non-zero exit with no lines is the one answer that cannot tell them.
out="$(_ep_components "$EPX")"; rc=$?
is "a project directory that is not there identifies no subject and no topology" \
   "$(printf '%s\n' "$out" | awk -F'\t' '$1 != "policy_version" { print $2 }' | paste -sd, -)" \
   "-,-,main"
is "and components exits 0 even then" "$rc" "0"
# Read off bullet 5 — a component that cannot be computed prints as a single
# dash — and the reason bullet 6 gives for refusing to hash over an absence. A
# project directory that is not there has no table set, so there is no content
# for a content hash to be over. Stated as the specification states it; see the
# report for what the library does instead.
is "and no policy version either, there being no tables to hash" \
   "$(printf '%s\n' "$out" | awk -F'\t' '$1 == "policy_version" { print $2 }')" "-"

# --------------------------------------------------------------- epoch ------
ep_hash0="$(_ep_hash)"
is "a decision epoch is one line" "$(printf '%s' "$ep_hash0" | grep -c .)" "1"
is "nothing changed is the same epoch" "$(_ep_hash)" "$ep_hash0"

_ep_json "example.com/renamed"
is "a new subject is a new epoch" "$(_ep_same "$(_ep_hash)" "$ep_hash0")" "different"
_ep_json
printf 'b\n' > "$EPR/members/b.txt"
is "a new grounded topology is a new epoch" "$(_ep_same "$(_ep_hash)" "$ep_hash0")" "different"
rm -f "$EPR/members/b.txt"
_ep_oblig 'second	RELEASE_BLOCKING	deterministic	-	true	-	and now it owes two'
is "a new policy state is a new epoch" "$(_ep_same "$(_ep_hash)" "$ep_hash0")" "different"
_ep_oblig
is "a new release target is a new epoch" \
   "$(_ep_same "$(_ep_hash_under hotfix-7)" "$ep_hash0")" "different"
is "and the epoch is back where it started once all four are" "$(_ep_hash)" "$ep_hash0"

# Hashing over an absence would read as a world that had moved every time a
# probe broke — a new epoch on every outage, and applicability recomputed
# against a topology nobody could see.
out="$(_ep_hash "$EPN")"; rc=$?
is "an unknown component prints no epoch at all" "${#out}" "0"
[ "$rc" -ne 0 ] && ok  "and exits non-zero rather than hashing over an absence" \
                || bad "and exits non-zero rather than hashing over an absence" "exited 0 having printed nothing"
out="$(_ep_hash "$EPX")"; rc=$?
is "a subject that cannot be identified blocks the epoch the same way" "${#out}" "0"
[ "$rc" -ne 0 ] && ok  "and that refusal is non-zero too" \
                || bad "and that refusal is non-zero too" "exited 0 having printed nothing"

# ------------------------------------------------------------ observer ------
# The same tree and the same facts, asked from a shell that finds another git.
# felix_probes_run names the instrument that answered each row — the probe's
# first word resolved on PATH, with the byte size of the file it resolved to
# — and that token was hashed into the topology beside the facts. So a launchd
# job, a CI runner or any shell whose PATH put a different git first computed
# a different epoch for a decision nothing about had changed, and every answer
# recorded there read stale on the laptop. direction-decisions recorded it
# under "Before any scheduler", item 1, as an engine-level decision owed an
# assertion that computes the epoch under two PATHs. This is that assertion.
#
# The other git is a wrapper that execs the real one, so every probe prints
# exactly what it printed before and the only thing that differs is the file
# PATH resolves `git` to. The first two assertions say the fixture really is
# that case: the token differs between the two shells, and felix_probes_run
# still prints it, because the drift report and the facts log read it there.
# Without them the third would pass on a machine where the wrapper was never
# reached, which is the one way it could be green and mean nothing.
EPW="$TMP/epoch-other-git"; mkdir -p "$EPW"
printf '#!/bin/sh\nexec "%s" "$@"\n' "$(command -v git)" > "$EPW/git"; chmod +x "$EPW/git"
_ep_other()  { ( PATH="$EPW:$PATH"; export PATH; "$@" ); }
_ep_gitsrc() { ( . "$FROOT/harness/lib/probes.sh"
                 felix_probes_run "$EPP" "$EPR" | awk -F'\t' '$1 == "tracked" { print $7 }' ); }
ep_src_here="$(_ep_gitsrc)"; ep_src_there="$(_ep_other _ep_gitsrc)"
is "a wrapper first on PATH is another instrument to the probe that asks git" \
   "$(_ep_same "$ep_src_here" "$ep_src_there")" "different"
is "and felix_probes_run still names which git answered, for the readers that ask" \
   "$(printf '%s\n' "$ep_src_there" | grep -c '^git@[0-9][0-9]*$')" "1"
is "a different git on PATH computes the same decision epoch" "$(_ep_other _ep_hash)" "$ep_hash0"
is "because it computes the same grounded topology"          "$(_ep_other _ep_topology)" "$ep_topo0"

# And the opposite property, so the fix is not a blindness. What left the hash
# is which observer answered; what was observed has to stay in it. A member one
# more probe enumerates is a new topology to the shell with the other git
# exactly as it is to this one, and both shells have to arrive at the same new
# epoch, or the first assertion above held only for a tree that sat still.
printf 'b\n' > "$EPR/members/b.txt"
is "a member count that moves is still a new epoch to the shell with the other git" \
   "$(_ep_same "$(_ep_other _ep_hash)" "$ep_hash0")" "different"
is "and both shells agree on what the new epoch is" "$(_ep_other _ep_hash)" "$(_ep_hash)"
rm -f "$EPR/members/b.txt"
is "and the member going away brings both back to the epoch they started from" \
   "$(_ep_other _ep_hash)" "$ep_hash0"

printf '\na background job does not keep the session waiting\n'
# Measured on the shipped hook: the process exits in 1.9s and its stderr pipe
# reaches EOF at 12.2s. The ten seconds in between are a background refresh
# holding a descriptor it was handed. `felix_..._bg ... 2>/dev/null` makes bash
# save the real stderr on fd 10 for the duration of the call, the subshell
# inherits it, and the platform reading that pipe waits for the refresh.
# Redirecting 0, 1 and 2 does not reach the copy on 10.
_fdopen() { ( . "$FROOT/harness/lib/resolve.sh"; eval "exec $1>&2"; "$@" >/dev/null 2>&1; ls /dev/fd 2>/dev/null | tr '\n' ' ' ); }
_fdafter() { ( . "$FROOT/harness/lib/resolve.sh"
                eval "exec 9>&2"; eval "exec 11>&2"
                felix_close_inherited_fds
                for _f in 9 11; do
                  if eval "exec ${_f}>&1" 2>/dev/null; then :; fi
                done
                ls /dev/fd 2>/dev/null | sort -n | tr '\n' ' ' ); }
out="$( . "$FROOT/harness/lib/resolve.sh"
        eval "exec 9>&2"
        ( felix_close_inherited_fds; ls /dev/fd 2>/dev/null | sort -n | tr '\n' ' ' ) )"
case "$out" in
  *9*) bad "a descriptor the caller left open is closed" "still open: $out" ;;
  *)   ok  "a descriptor the caller left open is closed" ;;
esac
out="$( . "$FROOT/harness/lib/resolve.sh"
        ( felix_close_inherited_fds; printf 'stdout survives\n' ) 2>/dev/null )"
is "and standard output is left alone" "$out" "stdout survives"
out="$( . "$FROOT/harness/lib/resolve.sh"
        ( felix_close_inherited_fds; printf 'stderr survives\n' >&2 ) 2>&1 )"
is "and standard error is left alone" "$out" "stderr survives"
( . "$FROOT/harness/lib/resolve.sh"; felix_close_inherited_fds ) >/dev/null 2>&1 \
  && ok  "closing nothing is not a failure" \
  || bad "closing nothing is not a failure" "non-zero with no descriptors open"
# The three background jobs that run from a hook must all call it, or the one
# that does not is the one that holds the pipe. Named rather than counted: a
# count goes green when somebody adds a fourth.
# The commissioning resume moved to lib/own.sh (0.49.286), beside the rule that decides whether it
# may run; the file that holds its detached subshell is the one that has to close the descriptors.
# The discovery refresh moved the same way, to lib/discover-refresh.sh (audit b06, 0.49.313).
for _bgfile in commission discover graph; do
  _bgsrc="$_bgfile"; [ "$_bgfile" = commission ] && _bgsrc=own
  [ "$_bgfile" = discover ] && _bgsrc=discover-refresh
  if grep -q 'felix_close_inherited_fds' "$FROOT/harness/lib/$_bgsrc.sh" 2>/dev/null; then
    ok  "lib/$_bgfile.sh closes what it inherited before backgrounding"
  else
    bad "lib/$_bgfile.sh closes what it inherited before backgrounding" "no call"
  fi
done

