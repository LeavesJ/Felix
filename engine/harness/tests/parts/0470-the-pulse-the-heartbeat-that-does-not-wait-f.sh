printf '\nthe pulse: the heartbeat that does not wait for a session\n'
# Memory backup was as current as the last time somebody typed the command —
# measured four days stale once, on the one asset the repository cannot
# rebuild. The pulse commits, pushes, and then asks the remote what it holds,
# because pushed is a claim and verified is a fact.
PBR="$TMP/pulse-mem"; PBREM="$TMP/pulse-remote.git"
mkdir -p "$PBR/memory/pulseproj"
( _fx_cd "$PBR" && git init -q -b main \
  && printf 'l\n' > memory/pulseproj/lessons.md \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base )
# -b main, and every later read names refs/heads/main outright: a bare repo's
# HEAD points at whatever the machine's default branch is, so rev-parse HEAD
# answered on this laptop and broke on the runner — a machine-dependent test
# is #67's family wearing a fixture.
git init -q --bare -b main "$PBREM"
( _fx_cd "$PBR" && git remote add backup "$PBREM" && git push -q backup main )
printf 'new lesson\n' >> "$PBR/memory/pulseproj/lessons.md"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PBR" )"
has "a dirty memory repo is committed"       "$out" "committed"
has "and pushed, and the push is read back"   "$out" "pushed and read back"
is  "the remote actually holds the commit" \
    "$(git --git-dir="$PBREM" rev-parse refs/heads/main)" "$(git -C "$PBR" rev-parse HEAD)"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PBR" )"
has "a clean repo says so instead of minting a commit" "$out" "nothing new to commit"

# Divergence is another machine's work, and reconciling it is a person's call.
PB2="$TMP/pulse-mem2"; git clone -q "$PBREM" "$PB2" 2>/dev/null
( _fx_cd "$PB2" && printf 'other machine\n' > other.md && git add -A \
  && git -c user.name=o -c user.email=o@o commit -qm other && git push -q origin main )
printf 'this machine\n' >> "$PBR/memory/pulseproj/lessons.md"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PBR" )"
# The message no longer guesses WHY. A rejected push and an unreachable
# remote are indistinguishable from the exit status, and the first version
# called both "likely diverged" — a diagnosis it had not earned. What it must
# always say is the part it knows: nothing was forced.
has "a rejected push is reported, not forced" "$out" "nothing was forced"
case "$out" in
  *"likely diverged"*) bad "and does not diagnose a cause it cannot see" "$out" ;;
  *)                   ok  "and does not diagnose a cause it cannot see" ;;
esac
is  "and the remote keeps the other machine's head" \
    "$(git --git-dir="$PBREM" rev-parse refs/heads/main)" "$(git -C "$PB2" rev-parse HEAD)"

PNR="$TMP/pulse-noremote"; mkdir -p "$PNR"
( _fx_cd "$PNR" && git init -q -b main && printf 'x\n' > f \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base )
printf 'y\n' >> "$PNR/f"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PNR" )"
has "no remote is named as the risk it is" "$out" "only this disk"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "" )"
has "memory outside any repository is said plainly" "$out" "not in a git repository"

# The review of the first version confirmed ten ways an unattended committer
# corrupts what it protects. Each guard below is one of them, constructed.
#
# A merge in progress is a person's work-site: add -A would stage their
# conflict markers as resolved, commit would conclude their merge, and the
# push would fast-forward past the divergence guard entirely.
# Built inside ONE repository from two branches: no clone, no push, nothing
# whose failure could be swallowed. The first version staged the conflict via
# a clone-and-push dance, and when any step of that failed quietly the repo
# simply had no merge in progress — so the pulse committed normally and the
# assertions blamed the guard for a fixture that never built. CI failed while
# the laptop stayed green, which is the same machine-dependent shape twice in
# one feature.
PMG="$TMP/pulse-merge"; PMGR="$TMP/pulse-merge-remote.git"
mkdir -p "$PMG"
( _fx_cd "$PMG" && git init -q -b main && printf 'a\n' > l.md \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base \
  && git checkout -q -b other \
  && printf 'B\n' > l.md && git add -A && git -c user.name=b -c user.email=b@b commit -qm B \
  && git checkout -q main \
  && printf 'A\n' > l.md && git add -A && git -c user.name=a -c user.email=a@a commit -qm A \
  && git -c user.name=m -c user.email=m@m merge other >/dev/null 2>&1 || true )
git init -q --bare -b main "$PMGR"
( _fx_cd "$PMG" && git remote add backup "$PMGR" )
# The precondition, asserted rather than assumed. Without this the two
# assertions below cannot tell "the guard failed" from "the conflict was
# never staged", and this project has paid for that confusion twice today.
[ -f "$PMG/.git/MERGE_HEAD" ] \
  && ok  "the fixture really staged a merge in progress" \
  || bad "the fixture really staged a merge in progress" \
         "no MERGE_HEAD; the assertions below would be about the fixture"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PMG" )"
# Both refusals — the index one and the state-file one — say this, and a
# conflicted merge trips whichever is checked first. What the assertion is
# about is that the pulse stood down, not which guard noticed.
has "a merge in progress is a person's, and the pulse says so" "$out" "mid-reconciliation"
[ -f "$PMG/.git/MERGE_HEAD" ] \
  && ok  "and the merge is left exactly where the person left it" \
  || bad "and the merge is left exactly where the person left it" "MERGE_HEAD gone"
is "and nothing reached the remote" \
   "$(git --git-dir="$PMGR" rev-parse --verify -q refs/heads/main 2>/dev/null | grep -c .)" "0"

# The nearest enclosing repo is not necessarily the memory's own. A dotfiles
# repo tracking $HOME would have every private file committed and pushed
# daily by the same four lines that back up lessons.
POUT="$TMP/pulse-outer"; mkdir -p "$POUT/dotfiles/felixish/memory"
( _fx_cd "$POUT/dotfiles" && git init -q -b main && printf 'rc\n' > .bashrc \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm dots )
_outer_head="$(git -C "$POUT/dotfiles" rev-parse HEAD)"
mr="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
       FELIX_MEMORY="$POUT/dotfiles/felixish/memory" felix_pulse_mem_repo "$POUT/home" )"
has "a repository that is not the memory's own is named foreign" "$mr" "foreign"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$mr" )"
has "and the pulse refuses it in words" "$out" "not its own"
is  "and commits nothing to it" "$(git -C "$POUT/dotfiles" rev-parse HEAD)" "$_outer_head"
mr="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
       FELIX_MEMORY="$PBR/memory" felix_pulse_mem_repo "$PBR" )"
is "while the Felix home Felix itself resolved is its own repo" "$mr" "$(cd "$PBR" && pwd -P)"
# "The immediate parent" was the wrong test: FELIX_MEMORY is the one
# documented knob, so pointing it one level inside somebody's notes vault
# made that vault the backup repository, add -A and all. Only the home this
# run actually resolved qualifies.
mr="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
       FELIX_MEMORY="$POUT/dotfiles/felixish/memory" felix_pulse_mem_repo "$POUT/dotfiles/felixish" )"
has "a parent that is not the resolved home is still foreign" "$mr" "foreign"

# The layout Felix actually ships: memory under ~/.felix, which is its own
# repository with the backup remote. Caught by running the real command
# rather than by the suite — every assertion here was green while the live
# setup was being refused as foreign, because the fixtures only ever built
# the shapes the rule already named.
PFX="$TMP/pulse-felixdir"; mkdir -p "$PFX/.felix/memory/proj"
( _fx_cd "$PFX/.felix" && git init -q -b main && printf 'l\n' > memory/proj/lessons.md \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
mr="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
       HOME="$PFX" FELIX_MEMORY="$PFX/.felix/memory" \
       felix_pulse_mem_repo "$TMP/some-unrelated-home" )"
is "the shipped layout — memory under ~/.felix — is its own repo" \
   "$mr" "$(cd "$PFX/.felix" && pwd -P)"

# Detached HEAD is a person inspecting history; a commit would land on no
# branch and the next checkout strands it.
( _fx_cd "$PNR" && git checkout -q --detach HEAD )
printf 'z\n' >> "$PNR/f"
_det_head="$(git -C "$PNR" rev-parse HEAD)"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PNR" )"
has "a detached HEAD is refused in words"    "$out" "detached"
is  "and nothing was committed onto it"      "$(git -C "$PNR" rev-parse HEAD)" "$_det_head"

# A nested git repository stages as a bare gitlink: the backup would verify
# while a restore materializes an empty directory.
PNEST="$TMP/pulse-nest"; mkdir -p "$PNEST"
( _fx_cd "$PNEST" && git init -q -b main && printf 'l\n' > l.md \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base )
mkdir -p "$PNEST/scraps"
( _fx_cd "$PNEST/scraps" && git init -q -b main && printf 'n\n' > notes.md \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm inner )
_nest_head="$(git -C "$PNEST" rev-parse HEAD)"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PNEST" )"
has "a nested repository is refused, with the restore truth" "$out" "restore EMPTY"
has "and it names which one"     "$out" "scraps"
is  "and nothing was committed"  "$(git -C "$PNEST" rev-parse HEAD)" "$_nest_head"
is  "and the index holds no gitlink afterwards" \
    "$(git -C "$PNEST" ls-files -s | grep -c '^160000')" "0"

# The second review's round. Each of these is a confirmed way the first set
# of guards still failed open, and the repair moves the test onto the fact
# rather than the symptom.
#
# An unmerged index with NO state file: merge --squash, cherry-pick -n and
# stash pop all produce it, add -A resolves the conflict markers as content,
# and the push then reported "verified" — after which local and remote agree
# and no later run could ever notice.
for _mode in squash cherry stash; do
  D="$TMP/pulse-unmerged-$_mode"; mkdir -p "$D"
  ( _fx_cd "$D" && git init -q -b main && printf 'base\n' > a.md && git add -A \
    && git -c user.name=t -c user.email=t@t commit -qm base \
    && git checkout -q -b other && printf 'THEIRS\n' > a.md && git add -A \
    && git -c user.name=t -c user.email=t@t commit -qm theirs \
    && git checkout -q main && printf 'OURS\n' > a.md && git add -A \
    && git -c user.name=t -c user.email=t@t commit -qm ours ) >/dev/null 2>&1
  case "$_mode" in
    squash) ( _fx_cd "$D" && git -c user.name=t -c user.email=t@t merge --squash other ) >/dev/null 2>&1 || true ;;
    cherry) ( _fx_cd "$D" && git -c user.name=t -c user.email=t@t cherry-pick -n other ) >/dev/null 2>&1 || true ;;
    stash)  ( _fx_cd "$D" && printf 'WIP\n' > a.md && git stash -q \
              && printf 'MOVED\n' > a.md && git add -A \
              && git -c user.name=t -c user.email=t@t commit -qm moved \
              && git stash pop ) >/dev/null 2>&1 || true ;;
  esac
  _u="$(git -C "$D" ls-files -u 2>/dev/null | grep -c .)"
  _h="$(git -C "$D" rev-parse HEAD)"
  out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
          felix_pulse_backup "$D" )"
  if [ "${_u:-0}" -gt 0 ]; then
    has "an unmerged index is refused whatever wrote it ($_mode)" "$out" "unresolved conflicts"
    is  "and no conflict markers were committed ($_mode)" "$(git -C "$D" rev-parse HEAD)" "$_h"
  else
    skip "an unmerged index is refused whatever wrote it ($_mode)" "this git staged no conflict"
    skip "and no conflict markers were committed ($_mode)" "this git staged no conflict"
  fi
done

# One declared submodule used to switch the gitlink guard off for every OTHER
# nested repository — the guard asked whether .gitmodules exists, not whether
# this link is in it. Worse, the refusal message's own remedy created the
# hole.
PSUB="$TMP/pulse-submod"; mkdir -p "$PSUB"
( _fx_cd "$PSUB" && git init -q -b main && printf 'l\n' > l.md && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
mkdir -p "$PSUB/declared" "$PSUB/undeclared"
( _fx_cd "$PSUB/declared" && git init -q -b main && printf 'd\n' > f && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm d ) >/dev/null 2>&1
( _fx_cd "$PSUB/undeclared" && git init -q -b main && printf 'u\n' > f && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm u ) >/dev/null 2>&1
printf '[submodule "declared"]\n\tpath = declared\n\turl = ./declared\n' > "$PSUB/.gitmodules"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PSUB" )"
has "a declared submodule does not excuse an undeclared one" "$out" "undeclared"

# A gitlink already in HEAD is history, not a decision this run makes —
# counting it refused every future backup forever, which is the fail-closed
# mirror of the same defect.
PGL="$TMP/pulse-oldlink"; mkdir -p "$PGL"
( _fx_cd "$PGL" && git init -q -b main && printf 'l\n' > l.md && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
mkdir -p "$PGL/legacy"
( _fx_cd "$PGL/legacy" && git init -q -b main && printf 'x\n' > f && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm x ) >/dev/null 2>&1
( _fx_cd "$PGL" && git add -A && git -c user.name=t -c user.email=t@t commit -qm "legacy link" ) >/dev/null 2>&1
printf 'new lesson\n' >> "$PGL/l.md"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PGL" )"
has "a gitlink already in history does not block every future backup" "$out" "committed"

# A failed commit used to fall through to push: the push succeeded because
# nothing new was sent, the verification passed because both heads were the
# stale one, and the run's LAST line — the one a person skims — read
# "pushed and verified" while the memory was not backed up at all.
PCF="$TMP/pulse-commitfail"; PCFR="$TMP/pulse-commitfail.git"
mkdir -p "$PCF"
( _fx_cd "$PCF" && git init -q -b main && printf 'l\n' > l.md && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
git init -q --bare -b main "$PCFR"
( _fx_cd "$PCF" && git remote add origin "$PCFR" && git push -q origin main ) >/dev/null 2>&1
printf 'new\n' >> "$PCF/l.md"
printf '#!/bin/sh\nexit 1\n' > "$PCF/.git/hooks/pre-commit"; chmod +x "$PCF/.git/hooks/pre-commit"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PCF" )"
has "a failed commit says the memory is NOT backed up" "$out" "NOT backed up"
case "$out" in
  *"pushed and read back"*|*"pushed and verified"*) bad "and never ends on a success line" "$out" ;;
  *)                                                ok  "and never ends on a success line" ;;
esac
rm -f "$PCF/.git/hooks/pre-commit"

# A refusal that no surface mentions is a backup that has silently stopped,
# and the age must measure the thing that actually matters: whether memory
# left this disk. Reading the last local COMMIT reported zero days in every
# state the alarm exists for — a push failing for months, no remote at all,
# a permanent refusal — because the pulse commits daily regardless.
PAH="$TMP/pulse-agehome"; mkdir -p "$PAH/state"
age="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup_age "$PAH" )"
is "before the pulse has ever run there is nothing to report" "$age" ""
printf 'pulse\tx\n' > "$PAH/state/pulse.log"
age="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup_age "$PAH" )"
is "a pulse that has run and never succeeded says never" "$age" "never"
date +%s > "$PAH/state/pulse.last-push"
age="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup_age "$PAH" )"
is "and a verified push reads as zero days" "$age" "0"
printf '%s\n' "$(( $(date +%s) - 86400 * 9 ))" > "$PAH/state/pulse.last-push"
age="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup_age "$PAH" )"
is "an old stamp is counted in days" "$age" "9"

# The stamp is written on the verified-push path and nowhere else, so a
# repository with no remote — which commits happily every day — never reads
# as freshly backed up.
PST="$TMP/pulse-stamp"; PSTR="$TMP/pulse-stamp.git"; mkdir -p "$PST"
( _fx_cd "$PST" && git init -q -b main && printf 'l\n' > l.md && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
PSTH="$TMP/pulse-stamphome"; mkdir -p "$PSTH/state"
printf 'x\n' >> "$PST/l.md"
( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
  FELIX_HOME_DIR="$PSTH" felix_pulse_backup "$PST" ) >/dev/null 2>&1
[ -f "$PSTH/state/pulse.last-push" ] \
  && bad "a commit with no remote does not stamp a push" "stamp written" \
  || ok  "a commit with no remote does not stamp a push"
git init -q --bare -b main "$PSTR"
( _fx_cd "$PST" && git remote add origin "$PSTR" ) >/dev/null 2>&1
printf 'y\n' >> "$PST/l.md"
( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
  FELIX_HOME_DIR="$PSTH" felix_pulse_backup "$PST" ) >/dev/null 2>&1
[ -f "$PSTH/state/pulse.last-push" ] \
  && ok  "and a verified push does" \
  || bad "and a verified push does" "no stamp"

# The gitlink check runs on a scratch index, so asking the question cannot
# destroy the answer: a person's deliberately staged selection survives.
PIX="$TMP/pulse-index"; mkdir -p "$PIX"
( _fx_cd "$PIX" && git init -q -b main && printf 'a\n' > a.md && printf 'b\n' > b.md \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
mkdir -p "$PIX/nested"
( _fx_cd "$PIX/nested" && git init -q -b main && printf 'n\n' > f && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm n ) >/dev/null 2>&1
printf 'staged\n' >> "$PIX/a.md"; printf 'unstaged\n' >> "$PIX/b.md"
( _fx_cd "$PIX" && git add a.md ) >/dev/null 2>&1
_staged_before="$(git -C "$PIX" diff --cached --name-only | tr '\n' ' ')"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PIX" )"
has "the nested repo is still refused" "$out" "restore EMPTY"
is  "and the person's staged selection is untouched" \
    "$(git -C "$PIX" diff --cached --name-only | tr '\n' ' ')" "$_staged_before"

# Two paths differing only in spacing are two paths. The awk that rebuilt
# the record collapsed runs of whitespace, so a genuinely new nested repo
# whose name collided with a known one after collapsing was committed as a
# bare gitlink — the exact outcome the guard exists to prevent.
PWS="$TMP/pulse-space"; mkdir -p "$PWS"
( _fx_cd "$PWS" && git init -q -b main && printf 'l\n' > l.md && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
mkdir -p "$PWS/a b"
( _fx_cd "$PWS/a b" && git init -q -b main && printf 'x\n' > f && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm x ) >/dev/null 2>&1
( _fx_cd "$PWS" && git add -A && git -c user.name=t -c user.email=t@t commit -qm "link one" ) >/dev/null 2>&1
mkdir -p "$PWS/a  b"
( _fx_cd "$PWS/a  b" && git init -q -b main && printf 'y\n' > f && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm y ) >/dev/null 2>&1
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PWS" )"
has "a path differing only by spacing is still a new nested repo" "$out" "restore EMPTY"

# SQUASH_MSG is a message draft, not an in-progress marker: nothing removes
# it but a later commit, so a guard keyed to it refused forever in a
# repository git itself called clean.
PSQ="$TMP/pulse-squashmsg"; mkdir -p "$PSQ"
( _fx_cd "$PSQ" && git init -q -b main && printf 'l\n' > l.md && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
printf 'a leftover draft\n' > "$PSQ/.git/SQUASH_MSG"
printf 'new lesson\n' >> "$PSQ/l.md"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PSQ" )"
has "a leftover message draft does not stop the backup forever" "$out" "committed"

# The push target is never an alphabetical accident. origin wins over a
# name that sorts first; two strangers with no upstream is a person's call.
PMR="$TMP/pulse-remotes"; PMRA="$TMP/pulse-ra.git"; PMRO="$TMP/pulse-ro.git"
mkdir -p "$PMR"
( _fx_cd "$PMR" && git init -q -b main && printf 'l\n' > l.md \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base )
git init -q --bare -b main "$PMRA"; git init -q --bare -b main "$PMRO"
( _fx_cd "$PMR" && git remote add archive "$PMRA" && git remote add origin "$PMRO" )
printf 'm\n' >> "$PMR/l.md"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PMR" )"
has "origin outranks the name that sorts first" "$out" "pushed and read back: origin"
# --verify -q, and not for style: bare `git rev-parse` on a MISSING ref echoes
# the literal back to stdout, so "did this remote receive anything" answered 1
# whether it had or not — an instrument that reports the same thing either way,
# which is this project's most-repeated defect wearing a fixture.
is  "and the alphabetical-first remote was not touched" \
    "$(git --git-dir="$PMRA" rev-parse --verify -q refs/heads/main 2>/dev/null | grep -c .)" "0"
( _fx_cd "$PMR" && git remote rename origin mirror )
printf 'm2\n' >> "$PMR/l.md"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PMR" )"
has "two strangers and no upstream is a person's call" "$out" "a person picks"

# The verification is load-bearing, pinned by an input only it can catch: a
# push URL pointing somewhere other than the fetch URL means the push lands
# where nothing reads back, and 'pushed and read back' would be a lie.
PSPLIT="$TMP/pulse-split"; PSF="$TMP/pulse-sf.git"; PSP="$TMP/pulse-sp.git"
mkdir -p "$PSPLIT"
( _fx_cd "$PSPLIT" && git init -q -b main && printf 'l\n' > l.md \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base )
git init -q --bare -b main "$PSF"; git init -q --bare -b main "$PSP"
( _fx_cd "$PSPLIT" && git remote add origin "$PSF" \
  && git remote set-url --push origin "$PSP" )
printf 's\n' >> "$PSPLIT/l.md"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_backup "$PSPLIT" )"
has "a push nothing reads back says so" "$out" "reads back"
_nb=yes; case "$out" in *"pushed and read back"*|*"pushed and verified"*) _nb=no ;; esac
is  "and no success line calls a push nothing reads back read back, or verified" "$_nb" yes

# The report half: the pulse log doubles as a note about what the next
# session will find, read off Felix's own tables and state alone.
PRH="$TMP/pulse-home"; mkdir -p "$PRH/projects/pulsey"
printf '{"name": "pulsey", "remote_match": "example.com/pulsey", "gate": "true"}\n' \
  > "$PRH/projects/pulsey/project.json"
printf 'checkme\t7\talways\tsomething with a cadence\n' > "$PRH/projects/pulsey/maintenance.tsv"
printf 'work\tfix\t-\tcode-review\n' > "$PRH/projects/pulsey/routes.tsv"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
        . "$FROOT/harness/lib/stack.sh"; . "$FROOT/harness/lib/maintenance.sh"
        . "$FROOT/harness/lib/discover.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_report "$PRH" )"
has "names the maintenance that is due"  "$out" "due	pulsey	checkme"
has "and the discovery cache gone stale" "$out" "stale	pulsey"

# And a row it could not ask is reported rather than dropped.
#
# The pulse is home-scoped: it iterates projects with no tree in front of any
# of them, so a cadence-0 row with a CHECK cannot be evaluated and used to be
# filtered away by `grep '^due'`. That is the graphify lesson one layer down —
# "nothing due" and "nothing is being checked" rendering identically — on the
# one surface nobody is watching when it renders. pulsey's checkout is not
# this home, so the root is correctly withheld and the row says so.
printf 'checkme\t7\talways\tsomething with a cadence\nmapped\t0\talways\tthe map\ttest -f map.json\n' \
  > "$PRH/projects/pulsey/maintenance.tsv"
out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
        . "$FROOT/harness/lib/stack.sh"; . "$FROOT/harness/lib/maintenance.sh"
        . "$FROOT/harness/lib/discover.sh"; . "$FROOT/harness/lib/pulse.sh"
        felix_pulse_report "$PRH" )"
has "the pulse reports a check it could not ask" "$out" "unchecked	pulsey	mapped"

# Scheduling is a grant a person makes, so the install path is explicit,
# writes one launchd agent under $HOME, and says what it did. launchctl is
# stubbed — the point is what Felix hands it, not that launchd works — and so
# is uname, so BOTH platform branches run on every machine: the runner has no
# launchd and this laptop is never Linux, and either branch untested anywhere
# is a branch that only ever runs in production.
PLB="$TMP/pulse-bin"; mkdir -p "$PLB"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "${LAUNCHCTL_LOG:-/dev/null}"\nexit 0\n' > "$PLB/launchctl"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "${UNAME_STUB:-Darwin}"\n' > "$PLB/uname"
chmod +x "$PLB/launchctl" "$PLB/uname"
PHOME="$TMP/pulse-fakehome"; mkdir -p "$PHOME"
out="$(cd "$REPO" && HOME="$PHOME" PATH="$PLB:$PATH" UNAME_STUB=Darwin \
       LAUNCHCTL_LOG="$TMP/launchctl.log" "$FELIX" pulse --install 2>&1)"; rc=$?
is  "install answers cleanly"        "$rc" "0"
has "and names itself as the grant"  "$out" "the grant"
has "the agent runs the pulse" \
    "$(cat "$PHOME/Library/LaunchAgents/felix.pulse.plist" 2>/dev/null)" "<string>pulse</string>"
has "and launchd was handed the agent" "$(cat "$TMP/launchctl.log" 2>/dev/null)" "felix.pulse.plist"
has "launchd's own capture goes to its own file, so no line logs twice" \
    "$(cat "$PHOME/Library/LaunchAgents/felix.pulse.plist" 2>/dev/null)" "launchd.log"

# The plist must outlive whichever copy ran the command: a worktree engine
# dies with the worktree, so a registered marketplace root wins over the
# running copy. The registry is under $HOME, which is the fixture's.
PSERVED="$TMP/pulse-served"; mkdir -p "$PSERVED/engine/harness" "$PHOME/.claude/plugins"
printf '#!/bin/sh\n' > "$PSERVED/engine/harness/felix"; chmod +x "$PSERVED/engine/harness/felix"
cat > "$PHOME/.claude/plugins/known_marketplaces.json" <<EOF
{
  "felix": {
    "installLocation": "$PSERVED"
  }
}
EOF
out="$(cd "$REPO" && HOME="$PHOME" PATH="$PLB:$PATH" UNAME_STUB=Darwin \
       "$FELIX" pulse --install 2>&1)"
has "the agent points at the served engine, not the running copy" \
    "$(cat "$PHOME/Library/LaunchAgents/felix.pulse.plist" 2>/dev/null)" "$PSERVED/engine/harness/felix"
rm -f "$PHOME/.claude/plugins/known_marketplaces.json"
out="$(cd "$REPO" && HOME="$PHOME" PATH="$PLB:$PATH" "$FELIX" pulse --uninstall 2>&1)"
[ -f "$PHOME/Library/LaunchAgents/felix.pulse.plist" ] \
  && bad "uninstall takes the grant back" "plist still present" \
  || ok  "uninstall takes the grant back"
out="$(cd "$REPO" && HOME="$PHOME" PATH="$PLB:$PATH" UNAME_STUB=Linux \
       "$FELIX" pulse --install 2>&1)"; rc=$?
is  "a machine without launchd is refused, not half-served" "$rc" "1"
has "and handed the cron line instead"                      "$out" "cron"
[ -f "$PHOME/Library/LaunchAgents/felix.pulse.plist" ] \
  && bad "and no agent is written there" "plist appeared" \
  || ok  "and no agent is written there"

# The heartbeat end to end from the CLI: no session, and here no memory repo
# either — the suite's memory root is a bare fixture directory — so the honest
# answer is that nothing versions it, and the run still logs and exits 0.
out="$(cd "$REPO" && "$FELIX" pulse 2>&1)"; rc=$?
is  "a pulse with nothing to do still answers" "$rc" "0"
has "and says what is not versioned" "$out" "not in a git repository"
has "and the run is on the record" \
    "$(cat "$FROOT/state/pulse.log" 2>/dev/null)" "pulse	"

