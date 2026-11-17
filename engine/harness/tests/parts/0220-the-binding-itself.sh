printf '\nthe binding itself\n'
_hook_payload_vars; _gate_repo_build; _cmstub_build
# `echo nonexistent > .felix` used to disable the entire floor. The marker is
# tracked, `felix_resolve_project` returned non-zero the moment the named
# project directory was missing, and every hook reads a non-zero resolve as
# "ungoverned" and exits 0. No gate, no hold, no record. `$HOME/.felix-home`
# does the same from outside every repository, so breaking it leaves no diff to
# review and no escape channel at all.
#
# The distinction this section holds, and it is the whole fix. An ABSENT
# binding means the directory is not governed: correct, and it must keep
# working, because Felix has to stay usable in a repository it does not govern.
# A binding that is PRESENT and does not resolve means somebody broke it, and
# this project's own rule is that "nothing due" and "nothing is being checked"
# must not render identically.
BROKEN="$TMP/brokenmarker"; mkdir -p "$BROKEN"
( _fx_cd "$BROKEN" && git init -q -b main
  printf 'contents\n' > WIDGET.txt
  printf 'nonexistent\n' > .felix
  git add -A; git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
BROKEN="$(cd "$BROKEN" && pwd -P)"

out="$(_stop "$BROKEN")"; rc=$?
_blocks "an unresolvable marker refuses instead of exiting clean" "$out"
has     "and quotes the name the marker asks for"  "$out" "nonexistent"
is      "and still returns success, so it cannot loop" "$rc" "0"

# Present and naming nothing is the same fact as present and naming something
# absent: a file exists whose entire job is to say which project governs here,
# and it does not say one.
printf '\n' > "$BROKEN/.felix"
out="$(_stop "$BROKEN")"
_blocks "an empty marker refuses too" "$out"

# `.` and `..` are directories, and `-d projects/.` is true. A marker reading
# `.` resolved to a healthy binding at the projects directory itself — a
# project with no tables, no deny rows and no gate — and every hook read the
# tree as governed. A name is one directory name; a dot or a path is not one.
for _dotname in '.' '..' '../widget' 'widget/..'; do
  printf '%s\n' "$_dotname" > "$BROKEN/.felix"
  out="$(_stop "$BROKEN")"
  _blocks "a marker naming '$_dotname' refuses rather than binding to the projects directory" "$out"
done
has "and says what a project name is" "$out" "not a project name"
out="$(cd "$BROKEN" && "$FELIX" which 2>&1)"
case "$out" in
  *"project:      "*) bad "and felix which does not resolve it" "$out" ;;
  *)                  ok  "and felix which does not resolve it" ;;
esac
out="$("$FELIX" new ../escaped 2>&1)"; rc=$?
is  "felix new refuses the same names the marker refuses" "$rc" "1"
has "and says what a name is" "$out" "one directory name"

# A refusal nothing records is indistinguishable from a hook that never ran,
# and the project this belongs to is precisely what could not be resolved — so
# it lands at the memory root, which belongs to no project.
grep -q 'nonexistent' "$MEM/unresolved.log" 2>/dev/null \
  && ok  "the refusal is recorded where no project is known" \
  || bad "the refusal is recorded where no project is known" "nothing in $MEM/unresolved.log"

# The half that must not regress. No marker at all, no remote to match: this is
# a repository Felix does not govern, and silence is the correct answer even
# with unverified work sitting in the tree.
NOMARK="$TMP/nomarker"; mkdir -p "$NOMARK"
( _fx_cd "$NOMARK" && git init -q -b main && printf 'x\n' > a.txt
  git add -A; git -c user.name=t -c user.email=t@t commit -qm i ) >/dev/null 2>&1
printf 'unverified\n' >> "$NOMARK/a.txt"
out="$(_stop "$NOMARK")"; rc=$?
_allows "an absent marker still means ungoverned" "$out"
is      "and exits 0 with the tree dirty"         "$rc" "0"

# And a marker that resolves is never the broken one, whatever else the hook
# decides about the tree.
printf 'widget\n' > "$BROKEN/.felix"
out="$(_stop "$BROKEN")"
case "$out" in
  *"does not resolve"*) bad "a marker that resolves is not called broken" "$out" ;;
  *)                    ok  "a marker that resolves is not called broken" ;;
esac

# The home pointer, which is the same defect one level up and worse: it sits
# outside every repository, so changing it produces no diff, no classification
# and nothing for a reviewer to see.
POINTHOME="$TMP/pointerhome"; mkdir -p "$POINTHOME" "$TMP/not-a-felix-home"
_stop_as_home() {
  ( cd "$1" && printf '%s' "$EMPTY_JSON" | env -u FELIX_HOME HOME="$2" "$STOP" 2>&1 )
}
printf '%s\n' "$TMP/not-a-felix-home" > "$POINTHOME/.felix-home"
out="$(_stop_as_home "$GREPO" "$POINTHOME")"
_blocks "a home pointer naming something that is not a home refuses" "$out"
has     "and says which directory it was sent to" "$out" "not-a-felix-home"

# A long pointer was shown as its first eighty characters. When the eightieth
# closed a directory name, the refusal named the target's parent: a real path
# and a wrong answer, not a short one. Found 2026-09-24, when the suite's $TMP
# moved deeper and the line above failed, because a plain Mac run's
# $TMP/not-a-felix-home is eighty characters exactly. The parent here is built
# to be eighty long whatever $TMP is, and the length is asserted so an edit to
# it cannot quietly stop testing the slash.
_parent="/felix-no-such-root/$(printf '%060d' 0)"
is  "a parent eighty characters long, so a cut at eighty ends on its slash" "${#_parent}" "80"
printf '%s\n' "$_parent/the-home-it-names" > "$POINTHOME/.felix-home"
out="$(_stop_as_home "$GREPO" "$POINTHOME")"
has "a long pointer is refused naming its own directory, not the parent" "$out" "/the-home-it-names, which is not"
has "and the refusal marks where the middle was cut" "$out" "[...]"

# Short stays, because a marker is a file in the repository: a stranger's
# clone chooses its text, and the refusal quotes it to the model and to the
# founder. Showing the whole value would pass the line above and hand that
# text through at any length.
printf '%0150d%s%0150d\n' 0 WHOLE 0 > "$BROKEN/.felix"
out="$(_stop "$BROKEN")"
_quoted="$(printf '%s' "$out" | sed -n 's/.* names \\"\([^\\]*\)\\", and that does not resolve.*/\1/p')"
if [ -n "$_quoted" ] && [ "${#_quoted}" -le 80 ]; then
  ok  "a long marker is quoted at most eighty characters long"
else
  bad "a long marker is quoted at most eighty characters long" "quoted ${#_quoted}: [$out]"
fi
printf 'widget\n' > "$BROKEN/.felix"

printf '%s\n' "$TMP/no-such-directory-at-all" > "$POINTHOME/.felix-home"
out="$(_stop_as_home "$GREPO" "$POINTHOME")"
_blocks "so does a pointer naming a directory that is gone" "$out"

# Absent is absent here too. With no pointer the resolver falls back the way it
# always has, and nothing about that is broken.
rm -f "$POINTHOME/.felix-home"
out="$(_stop_as_home "$GREPO" "$POINTHOME")"
case "$out" in
  *"is not a Felix home"*) bad "an absent pointer is not a broken pointer" "$out" ;;
  *)                       ok  "an absent pointer is not a broken pointer" ;;
esac

# A pointer that names a real home is the ordinary case and must stay quiet.
printf '%s\n' "$FROOT" > "$POINTHOME/.felix-home"
out="$(_stop_as_home "$GREPO" "$POINTHOME")"
case "$out" in
  *"is not a Felix home"*) bad "a pointer to a real home is left alone" "$out" ;;
  *)                       ok  "a pointer to a real home is left alone" ;;
esac

# And a real home whose path holds a space, which is where iCloud keeps
# Documents: `~/Library/Mobile Documents/`. The pointer was read with every
# whitespace character deleted, so it named `.../MobileDocuments/Felix`, a
# directory nobody wrote: the resolver fell back past the home, and the stop
# hook refused with that path in its reason. The home holds the project GREPO's
# marker names, so a pointer read wrongly and a marker resolved against the
# wrong home both show up as a refusal here.
SPACED="$TMP/Mobile Documents/Felix"; mkdir -p "$SPACED/projects"
cp -R "$FROOT/projects/widget" "$SPACED/projects/"
printf '%s\n' "$SPACED" > "$POINTHOME/.felix-home"
out="$( unset FELIX_HOME; HOME="$POINTHOME"; . "$FROOT/harness/lib/resolve.sh"; felix_home "$TMP/plainrepo" )"
is  "a pointer to a home whose path holds a space resolves to it" "$out" "$SPACED"
out="$(_stop_as_home "$GREPO" "$POINTHOME")"
_allows "and the stop hook raises no refusal against it" "$out"
out="$(cd "$GREPO" && env -u FELIX_HOME HOME="$POINTHOME" "$FELIX" which 2>&1)"
has "and felix which governs from it" "$out" "doctrine:     $SPACED/projects/widget/CLAUDE.md"
rm -f "$POINTHOME/.felix-home"

# The other half of the same hole, and the half a session meets FIRST.
#
# hooks/stop refuses a broken binding, so a session that has one runs
# completely unprotected and only finds out at the very end. Every other hook
# still reads a non-zero resolve as "ungoverned" and exits 0, so the start of
# the session — the one other moment this project's doctrine allows Felix to
# speak — said nothing at all.
#
# It reports; it does not refuse. session-start is a pure text channel with no
# decision to make and no way to strand anybody, which is what makes it safe to
# speak from at the earliest point the fact can be known. PreToolUse is the
# tempting third place and is deliberately not wired: the remedy for a broken
# binding is editing the marker or running felix install, so a refusal there
# would refuse its own repair, with no stop_hook_active cap and no
# FELIX_ALLOW_RED to escape through.
_start() { ( cd "$1" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1 ); }
_start_as_home() {
  ( cd "$1" && env -u FELIX_HOME HOME="$2" CLAUDE_PLUGIN_ROOT="$FROOT" \
      "$FROOT/harness/hooks/session-start" 2>&1 )
}

printf 'nonexistent\n' > "$BROKEN/.felix"
out="$(_start "$BROKEN")"; rc=$?
has "session start reports an unresolvable marker"   "$out" "does not resolve"
has "and quotes the name the marker asks for"        "$out" "nonexistent"
is  "and still exits 0, because start cannot refuse" "$rc"  "0"
# additionalContext reaches the model and never the terminal. A founder whose
# floor is switched off learns nothing from a channel they cannot see, and this
# is the one surface Felix has to tell them.
has "and says it where the founder can see it"       "$out" "systemMessage"
# A resume was never bound before, so a broken binding said nothing there, and
# binding it must not start: the resume exit comes before this report.
out="$(cd "$BROKEN" && printf '{"source":"resume"}' | CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
is  "a resume on a broken binding stays as silent as before it was bound" "${#out}" "0"

printf '\n' > "$BROKEN/.felix"
out="$(_start "$BROKEN")"
has "an empty marker is reported at session start too" "$out" "does not resolve"

# The pointer is the worse surface: it sits outside every repository, so
# breaking it leaves no diff, and it decides which home the marker below is
# resolved against.
printf '%s\n' "$TMP/not-a-felix-home" > "$POINTHOME/.felix-home"
out="$(_start_as_home "$GREPO" "$POINTHOME")"
has "session start reports a broken home pointer" "$out" "is not a Felix home"
rm -f "$POINTHOME/.felix-home"

# The half that must not regress, and it is the whole reason this reports
# rather than refuses. An absent marker is a repository Felix does not govern,
# and a hook that spoke there would make Felix unusable everywhere it has not
# been adopted.
out="$(_start "$NOMARK")"; rc=$?
case "$out" in
  *"does not resolve"*) bad "an absent marker is still silent at session start" "$out" ;;
  *)                    ok  "an absent marker is still silent at session start" ;;
esac
is "and exits 0 in a repository Felix does not govern" "$rc" "0"

# And a binding that resolves gets the ordinary governed context, not this.
printf 'widget\n' > "$BROKEN/.felix"
out="$(_start "$BROKEN")"
case "$out" in
  *"does not resolve"*)           bad "a marker that resolves gets the normal context" "$out" ;;
  *"Felix governs this session"*) ok  "a marker that resolves gets the normal context" ;;
  *)                              bad "a marker that resolves gets the normal context" "$out" ;;
esac

# A project that declares no gate has nothing to enforce, and inventing an
# obligation for it would make Felix unusable on a repo mid-onboarding.
mkdir -p "$FROOT/projects/nogate" "$MEM/nogate"
printf '{\n  "name": "nogate"\n}\n' > "$FROOT/projects/nogate/project.json"
NGREPO="$TMP/nogaterepo"; mkdir -p "$NGREPO"
( _fx_cd "$NGREPO" && git init -q -b main && printf 'x\n' > a.txt
  git add -A >/dev/null 2>&1 && git -c user.name=t -c user.email=t@t commit -qm i >/dev/null 2>&1 )
printf 'nogate\n' > "$NGREPO/.felix"; printf 'dirty\n' >> "$NGREPO/a.txt"
out="$(_stop "$NGREPO")"
_allows "a project with no declared gate is left alone" "$out"

# Felix governs projects in languages it does not know, and one of their
# untracked directories may be a virtualenv or a model artifact. Metadata only.
mkdir -p "$GREPO/bigdir"
i=0; while [ "$i" -lt 60 ]; do printf 'x\n' > "$GREPO/bigdir/f$i"; i=$((i+1)); done
t0=$(date +%s); out="$(_stop "$GREPO")"; t1=$(date +%s)
[ $((t1-t0)) -le 3 ] && ok "stays fast with many untracked files" \
                     || bad "stays fast with many untracked files" "$((t1-t0))s"
rm -rf "$GREPO/bigdir"

# The gate and the hook compute tree identity independently. If they ever
# disagree the gate silently stops counting, so they must share one function.
tid_lib="$( . "$FROOT/harness/lib/verify.sh"; felix_tree_id "$GREPO" )"
[ -n "$tid_lib" ] && ok "tree identity is computable" \
                  || bad "tree identity is computable" "empty"
printf 'moved\n' >> "$GREPO/WIDGET.txt"
tid2="$( . "$FROOT/harness/lib/verify.sh"; felix_tree_id "$GREPO" )"
[ "$tid_lib" != "$tid2" ] && ok "and changes when the tree changes" \
                          || bad "and changes when the tree changes" "$tid_lib == $tid2"
( _fx_cd "$GREPO" && git checkout -q -- WIDGET.txt )

# A repository with no commits at all. HEAD is unborn, and every naive
# implementation of this dies there. The suite's own fixture is in that state.
UNBORN="$TMP/unborn"; mkdir -p "$UNBORN"
( _fx_cd "$UNBORN" && git init -q -b main )
printf 'widget\n' > "$UNBORN/.felix"; printf 'x\n' > "$UNBORN/new.txt"
tid3="$( . "$FROOT/harness/lib/verify.sh"; felix_tree_id "$UNBORN" )"
[ -n "$tid3" ] && ok "tree identity survives an unborn HEAD" \
               || bad "tree identity survives an unborn HEAD" "empty"
out="$(_stop "$UNBORN")"; rc=$?
is "and the hook still exits 0 there" "$rc" "0"

# Felix governing itself: the home lives INSIDE the tree being gated, so every
# receipt, verification line and route line lands in the repo it describes.
# Writing a receipt then changes the tree, which invalidates the receipt just
# written, and no gate run can ever produce a valid one. The fixture above hides
# this entirely because there the home sits outside the governed repo — which is
# why this reproduces the real layout instead.
SELF="$TMP/selfgoverned"
mkdir -p "$SELF/projects/self" "$MEM/self" "$SELF/harness"
_copy_content "$REAL_HARNESS" "$SELF/harness"
cat > "$SELF/projects/self/project.json" <<'EOF'
{ "name": "self", "gate": "true" }
EOF
printf '# self\n' > "$SELF/projects/self/CLAUDE.md"
# One probe, so the receipt the gate writes carries an epoch: a project that
# declares none has a receipt resting on nothing Felix reads, and that is
# stale by design rather than a fixture that happens to pass.
printf 'code\t-\t-\tgit ls-files\ttest -e .git\n' > "$SELF/projects/self/probes.tsv"
( _fx_cd "$SELF" && git init -q -b main && printf 'x\n' > code.txt && printf 'self\n' > .felix
  git add -A >/dev/null 2>&1
  git -c user.name=t -c user.email=t@t commit -qm i >/dev/null 2>&1 )
SELF="$(cd "$SELF" && pwd -P)"
printf 'real work\n' >> "$SELF/code.txt"
( cd "$SELF" && FELIX_HOME="$SELF" "$SELF/harness/felix" gate >/dev/null 2>&1 )
out="$(cd "$SELF" && FELIX_HOME="$SELF" printf '%s' "$EMPTY_JSON" \
        | FELIX_HOME="$SELF" "$SELF/harness/hooks/stop" 2>&1)"
_allows "a receipt survives being written inside the tree it describes" "$out"
# And a second stop, which appends another verification line, must also pass.
out="$(cd "$SELF" && FELIX_HOME="$SELF" printf '%s' "$EMPTY_JSON" \
        | FELIX_HOME="$SELF" "$SELF/harness/hooks/stop" 2>&1)"
_allows "and keeps surviving as its own log grows" "$out"
# Real work still has to be verified, bookkeeping exemption or not.
printf 'more real work\n' >> "$SELF/code.txt"
out="$(cd "$SELF" && FELIX_HOME="$SELF" printf '%s' "$EMPTY_JSON" \
        | FELIX_HOME="$SELF" "$SELF/harness/hooks/stop" 2>&1)"
_blocks "but a real edit still blocks" "$out"

printf '\nthe same gate, for a subagent\n'
# #83. subagent-stop had NO assertions at all — a risk-red hook that runs in
# every session of every governed project, with nothing holding it. That is why
# both halves of this went unnoticed.
#
# It asks the same question `stop` asks and answers it with a raw
# `git status --porcelain`, where stop uses two helpers written precisely
# because that raw test is wrong in both directions. stop's own comment records
# the diagnosis: "A clean tree used to end the hook here, which meant committing
# your work skipped the completion check entirely — and committing is what you
# do at the end." The fix was never carried across.
SUBSTOP="$FROOT/harness/hooks/subagent-stop"
SUB_SID="sub-session-1"
SUB_JSON="{\"hook_event_name\":\"SubagentStop\",\"session_id\":\"$SUB_SID\"}"
_sub() { ( cd "$1" && FELIX_HOME="$2" printf '%s' "$SUB_JSON" \
           | FELIX_HOME="$2" "$SUBSTOP" 2>&1 ); }
# The matcher is the new sentence's claim — the checkout's state, not the
# subagent's conduct. SubagentStop carries the parent's session id and nothing
# about which subagent finished, so "This subagent changed files" asserted a
# fact the hook cannot know, and was false for every read-only subagent after
# the parent's first commit — 48 of Felix's 136 utterances in five days (#97).
_sub_speaks() { case "$1" in *"no gate has passed on"*) return 0 ;; *) return 1 ;; esac; }

SUBR="$TMP/subrepo"; mkdir -p "$SUBR"
( _fx_cd "$SUBR" && git init -q -b main
  printf 'widget\n' > .felix
  printf 'contents\n' > WIDGET.txt
  printf 'x\n' > code.txt
  git add -A; git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
SUBR="$(cd "$SUBR" && pwd -P)"

# Baseline: a clean tree this session did not touch. Silence is correct, and
# this is the case the raw test got right — kept so a fix cannot buy the two
# below by simply speaking always.
out="$(_sub "$SUBR" "$FROOT")"
_sub_speaks "$out" && bad "an untouched clean tree stays silent" "$out" \
                   || ok  "an untouched clean tree stays silent"

# UNDER-FIRES. The subagent commits its work, which is what you do at the end,
# so the tree is clean and the hook said nothing about an unverified result.
( _fx_cd "$SUBR" && printf 'the subagent work\n' >> code.txt
  git add -A; git -c user.name=t -c user.email=t@t commit -qm "subagent work" ) >/dev/null 2>&1
# The mark the user-prompt hook writes at the start of a session, which is what
# makes "this session committed something" answerable at all.
( . "$FROOT/harness/lib/verify.sh"
  felix_session_mark "$FROOT" "$SUB_SID" "$SUBR" ) >/dev/null 2>&1
( _fx_cd "$SUBR" && printf 'more\n' >> code.txt
  git add -A; git -c user.name=t -c user.email=t@t commit -qm "more work" ) >/dev/null 2>&1
out="$(_sub "$SUBR" "$FROOT")"
_sub_speaks "$out" && ok  "work the subagent committed is still checked" \
                   || bad "work the subagent committed is still checked" "$out"

# The sentence claims what the hook can know — the checkout — and never the
# subagent's own conduct, which the payload does not carry.
case "$out" in
  *"This subagent changed files"*) bad "and the message does not accuse the subagent" "$out" ;;
  *) ok "and the message does not accuse the subagent" ;;
esac
has "it says the fact it has instead" "$out" "no gate has passed on"

# Once per session, not per agent. Three reviewers after one parent commit got
# three copies of a message that was false for all three; the second telling
# of an unchanged fact is pressure, not information.
out="$(_sub "$SUBR" "$FROOT")"
_sub_speaks "$out" && bad "a second hand-off in the same session stays quiet" "$out" \
                   || ok  "a second hand-off in the same session stays quiet"

# OVER-FIRES, the other direction and the same root cause. Only Felix's own
# bookkeeping changed. felix_tree_dirty excludes it deliberately — "a session
# that appended one line to a log has not changed the work" — and the raw
# status test does not.
#
# Run against the SELF fixture, not the one above, and that is the whole point
# of the case rather than a detail: _felix_tree_excludes returns nothing unless
# the home sits inside the tree being judged. A governed product has its home
# elsewhere and nothing to exclude; Felix governing itself is the layout where
# the exclusion exists and therefore the only layout where ignoring it shows.
# My first attempt used a home with no projects/ at all, so the hook exited on
# an unresolved project and the assertion passed for the wrong reason.
# Committed but deliberately NOT gated. With a green receipt both hooks exit at
# the receipt check and the difference is invisible: felix_tree_id excludes
# bookkeeping too, so appending a log line leaves the receipt valid. The
# over-fire is only reachable on an UNVERIFIED tree, which is exactly the state
# the hook exists to speak about.
( _fx_cd "$SELF" && git add -A && git -c user.name=t -c user.email=t@t commit -qm settle ) >/dev/null 2>&1
mkdir -p "$SELF/state"; printf 'a log line\n' >> "$SELF/state/keep.log"
is "the fixture is dirty only in Felix's own bookkeeping" \
   "$( cd "$SELF" && . "$SELF/harness/lib/verify.sh"
       felix_tree_dirty "$SELF" "$SELF" && echo dirty || echo clean )" "clean"
out="$( cd "$SELF" && FELIX_HOME="$SELF" printf '%s' "$SUB_JSON" \
        | FELIX_HOME="$SELF" "$SELF/harness/hooks/subagent-stop" 2>&1 )"
_sub_speaks "$out" && bad "but Felix's own bookkeeping is not the subagent's work" "$out" \
                   || ok  "but Felix's own bookkeeping is not the subagent's work"
rm -rf "$SELF/state"

# And a real uncommitted edit still speaks — in a fresh session, because the
# session above has had its one telling. A new session id is a new parent
# integrating reports, and it has not been told anything yet.
( cd "$SUBR" && printf 'uncommitted real work\n' >> code.txt )
SUB_JSON="{\"hook_event_name\":\"SubagentStop\",\"session_id\":\"sub-session-2\"}"
out="$(_sub "$SUBR" "$FROOT")"
_sub_speaks "$out" && ok  "a real uncommitted edit still speaks, in a fresh session" \
                   || bad "a real uncommitted edit still speaks, in a fresh session" "$out"
( _fx_cd "$SUBR" && git checkout -q -- code.txt )
SUB_JSON="{\"hook_event_name\":\"SubagentStop\",\"session_id\":\"$SUB_SID\"}"

printf '\na flag is not a positional\n'
# #102. felix --help worked; no SUBCOMMAND handled the flag, 24 take a first
# positional, and the writers took the flag AS the positional: felix adopt
# --help declared a capability named --help, created a setup.tsv whose mere
# presence flips felix setup from "declares no setup steps" to "Nothing
# outstanding.", and minted a memory root named --help. Found as residue - it
# had already happened unprompted on the real machine, at the hour a project
# was being mounted, which is exactly when somebody reaches for --help.
_caps_before="$(cat "$FROOT/projects/widget/capabilities" 2>/dev/null)"
rm -f "$FROOT/projects/widget/setup.tsv"
out="$(cd "$REPO" && "$FELIX" adopt --help 2>&1)"; rc=$?
is  "felix adopt --help answers with usage"        "$rc" "0"
has "and it is the usage text"                     "$out" "The engineering OS"
# The usage text says "declared" now (felix status, felix stack --reach), so the word alone no longer means adopt declared something; the writer's own sentences are what this looks for.
case "$out" in
  *"declared --help for"*|*"--help already declared"*) bad "and declares nothing" "$out" ;;
  *)            ok  "and declares nothing" ;;
esac
is "the capabilities file is untouched" \
   "$(cat "$FROOT/projects/widget/capabilities" 2>/dev/null)" "$_caps_before"
[ -f "$FROOT/projects/widget/setup.tsv" ] \
  && bad "and no setup.tsv appears from asking for help" "created" \
  || ok  "and no setup.tsv appears from asking for help"
[ -d "$MEM/--help" ] \
  && bad "and no memory root named --help is minted" "$MEM/--help exists" \
  || ok  "and no memory root named --help is minted"

# The writers refuse a flag-shaped positional outright, not only -h/--help:
# a mistyped flag must never become a declared capability, a governed project,
# a quarantined plugin, or a lesson matched into every prompt.
out="$(cd "$REPO" && "$FELIX" adopt --yes 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "adopt refuses any flag as a capability" \
                || bad "adopt refuses any flag as a capability" "$out"
out="$(cd "$REPO" && PATH="$CMSTUB:$PATH" "$FELIX" new --force 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "new refuses a flag as a project name" \
                || bad "new refuses a flag as a project name" "$out"
out="$(cd "$REPO" && "$FELIX" lesson --oops 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "lesson refuses a flag as the lesson" \
                || bad "lesson refuses a flag as the lesson" "$out"
# And the bare CLI help path is untouched: no subcommand, flag in slot one.
out="$("$FELIX" --help 2>&1)"; rc=$?
is  "felix --help still answers usage" "$rc" "0"
has "with the usage text"              "$out" "The engineering OS"

