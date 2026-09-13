# The pulse: Felix's heartbeat between sessions.
#
# Everything else Felix does runs only when a session happens to start, so the
# memory backup was as current as the last time somebody typed the command —
# measured four days stale once, on the one asset the repository cannot
# rebuild — and the first session of any day paid discovery's staleness. This
# is the piece that runs on a schedule instead: bash and git only, no model,
# no checkout touched, no network beyond the backup remote a person already
# configured.
#
# Duties, deliberately two:
#   backup   commit and push the memory repository, verified by asking the
#            remote what it now holds; a rejected push is reported and never
#            forced, because a divergence is another machine's work and
#            reconciling it is a person's call
#   report   name what is waiting — maintenance due, discovery caches stale —
#            so the pulse log doubles as a note about what the next session
#            will find
#
# The review of the first version confirmed ten ways an unattended committer
# can corrupt the thing it protects, each by construction, and the guards
# below are those findings inverted: never conclude a person's merge, never
# commit a repository that is not the memory's own, never commit onto a
# detached HEAD, never record a nested repository as an empty gitlink, never
# pick a push target by alphabetical accident. Every refusal is a printed
# sentence and exit 0 — for a heartbeat, an honest "not safe to act" is a
# successful run.
#
# Scheduling is a grant, not a default. `felix pulse --install` writes the
# launchd agent and a person runs that command; nothing here schedules
# itself, because a permission a system grants itself is not a permission.

# The git repository holding the memory root. Emits nothing when no repo
# encloses it; the toplevel when that repository is the memory's own — the
# root itself, or its immediate parent, which is the documented ~/.felix
# layout; and `foreign<TAB>toplevel` when the nearest repository is anything
# deeper — a dotfiles repo tracking $HOME is the realistic case, and running
# `git add -A` at that toplevel would commit and publish everything the
# founder owns, daily.
felix_pulse_mem_repo() {
  local home="${1:-}" root top
  root="$(cd "$(felix_mem_root)" 2>/dev/null && pwd -P)" || return 0
  [ -n "$root" ] || return 0
  top="$(git -C "$root" rev-parse --show-toplevel 2>/dev/null)" || return 0
  [ -n "$top" ] || return 0
  top="$(cd "$top" 2>/dev/null && pwd -P)"

  # Three directories qualify, and they are named rather than derived from a
  # shape: the memory root itself, `~/.felix` — Felix's own directory, which
  # is where the default memory root lives and which is the repository the
  # backup actually uses — and the Felix home this run resolved.
  #
  # "The immediate parent" was the first rule and it was too loose:
  # FELIX_MEMORY is the one documented knob, so pointing it at a
  # subdirectory of somebody's notes vault made that vault the backup
  # repository, `git add -A` and all. Naming only the home was then too
  # tight, and the live run is what caught it — the suite was green while
  # the real layout, memory under ~/.felix, was refused as foreign. A rule
  # narrow enough to be safe has to be checked against the setup it governs.
  local felixdir=""
  [ -n "${HOME:-}" ] && felixdir="$(cd "$HOME/.felix" 2>/dev/null && pwd -P)"
  [ -n "$home" ] && home="$(cd "$home" 2>/dev/null && pwd -P)"
  if [ "$top" = "$root" ] \
     || { [ -n "$felixdir" ] && [ "$top" = "$felixdir" ]; } \
     || { [ -n "$home" ] && [ "$top" = "$home" ]; }; then
    printf '%s' "$top"
  else
    printf 'foreign\t%s' "$top"
  fi
}

# Gitlinks a full staging would newly introduce, one path per line. Empty is
# the good answer, and it is computed WITHOUT touching the real index.
#
# Three rounds of review found three separate defects in the parsing this
# used to do — an awk that rebuilt the record and collapsed runs of spaces so
# two different directories reduced to one key, a .gitmodules cross-check
# whose quoting never matched git's own, and a count that included links
# already in HEAD. The lesson is not "parse more carefully": it is that the
# decision does not need most of what was being parsed.
#
# So: both sides come from `cut -f2-` on the literal tab git puts before a
# path — exact, and identical on both sides, so quoting cannot make them
# disagree — and the .gitmodules cross-check is gone entirely. A submodule
# somebody adds deliberately is refused once and then stops being new the
# moment they commit it, which is a self-resolving nudge rather than a
# permanent latch, and it costs no matching rules that can be wrong.
_felix_pulse_new_gitlinks() {
  local repo="$1" tmp idx head
  tmp="$(mktemp)" || return 0
  # A scratch index, so a person's deliberately staged selection survives
  # being asked about. The check used to stage into the real index and then
  # `git reset` on refusal, which is not an undo: it emptied whatever they
  # had staged.
  if git -C "$repo" rev-parse --verify -q HEAD >/dev/null 2>&1; then
    GIT_INDEX_FILE="$tmp" git -C "$repo" read-tree HEAD >/dev/null 2>&1
  fi
  GIT_INDEX_FILE="$tmp" git -C "$repo" add -A >/dev/null 2>&1
  idx="$(GIT_INDEX_FILE="$tmp" git -C "$repo" ls-files -s 2>/dev/null | grep '^160000 ' | cut -f2-)"
  rm -f "$tmp"
  [ -n "$idx" ] || return 0
  head="$(git -C "$repo" ls-tree -r HEAD 2>/dev/null | grep '^160000 ' | cut -f2-)"
  printf '%s\n' "$idx" | while IFS= read -r p; do
    [ -n "$p" ] || continue
    felix_has_line "$head" "$p" && continue
    printf '%s\n' "$p"
  done
}

# When the memory last reached the remote, as a stamp this writes itself.
_felix_pulse_stamp() { printf '%s/state/pulse.last-push' "$1"; }

# Commit if dirty, push if a target is unambiguous, then verify by re-reading
# the remote head. Emits status lines and always returns 0: an honest
# "nothing to do" is not a failure, and neither is a refusal this
# deliberately makes.
felix_pulse_backup() {
  local repo="$1" gitdir remotes remote branch local_head remote_head n160 n_remotes
  if [ -z "$repo" ]; then
    printf 'backup\tmemory is not in a git repository; nothing versions it\n'
    return 0
  fi
  case "$repo" in
    "foreign	"*)
      printf 'backup\tmemory sits inside a repository that is not its own (%s); not touching it\n' \
        "${repo#foreign	}"
      return 0 ;;
  esac

  # A merge or rebase in progress is a person's work-site. `git add -A` would
  # stage their conflict markers as resolved and `commit` would conclude
  # their merge under this machine's name — then push it as a fast-forward
  # the divergence guard below can never catch, because the machine-made
  # merge contains the remote head. Constructed in review; never again.
  # The index is the fact, and the state files are only a symptom of it.
  # Checking the five files alone let `git merge --squash`, `git cherry-pick
  # -n` and `git stash pop` conflicts through — all three leave unmerged
  # entries and write no state file — and `git add -A` then resolves an
  # unmerged path to whatever the worktree holds, which is the conflict
  # markers. The push that followed reported "verified", and because local
  # and remote then agreed, no later run could ever notice.
  if [ "$(git -C "$repo" ls-files -u 2>/dev/null | grep -c .)" -gt 0 ]; then
    printf 'backup\tunresolved conflicts are staged here; that is a person mid-reconciliation, and nothing here touches it\n'
    return 0
  fi
  # Kept beside it: an in-progress operation that has not conflicted YET
  # leaves a state file and an ordinary index, and concluding somebody's
  # rebase under this machine's name is its own harm.
  gitdir="$(git -C "$repo" rev-parse --git-dir 2>/dev/null)"
  case "$gitdir" in /*) ;; *) gitdir="$repo/$gitdir" ;; esac
  # SQUASH_MSG is deliberately NOT in this list, though it was for one
  # round. It is a message draft rather than an in-progress marker: nothing
  # removes it but a later commit or reset, `git merge --abort` refuses to
  # touch it, and a guard keyed to it latched forever in a repository git
  # itself called clean. Every name below is one git removes when the
  # operation ends.
  if [ -f "$gitdir/MERGE_HEAD" ] || [ -f "$gitdir/CHERRY_PICK_HEAD" ] \
     || [ -f "$gitdir/REVERT_HEAD" ] \
     || [ -d "$gitdir/rebase-merge" ] || [ -d "$gitdir/rebase-apply" ]; then
    printf 'backup\ta merge or rebase is in progress; that is a person mid-reconciliation, and nothing here touches it\n'
    return 0
  fi

  # Detached HEAD is a person inspecting history. A commit here lands on no
  # branch, and the next ordinary checkout strands it.
  branch="$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null)" || branch=""
  if [ -z "$branch" ]; then
    printf 'backup\tHEAD is detached; a commit would land on no branch, so nothing was committed\n'
    return 0
  fi

  if [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]; then
    # A nested git repository stages as a bare gitlink: the push then reports
    # verified while a restore materializes an empty directory — the exact
    # disaster-recovery path this feature exists for. Asked on a scratch
    # index BEFORE anything real stages, so a refusal leaves the person's own
    # index exactly as it was found; the previous shape staged first and
    # `git reset` on refusal, which is not an undo — it emptied whatever they
    # had deliberately staged. Counted with grep -c, which reads its whole
    # input, because grep -q under pipefail kills the producer and this
    # repository has paid for that before.
    local links; links="$(_felix_pulse_new_gitlinks "$repo")"
    if [ "$(printf '%s\n' "$links" | grep -c .)" -gt 0 ]; then
      printf 'backup\ta nested git repository sits inside memory (%s); backed up it would restore EMPTY, so nothing was committed — move it out, or commit it yourself\n' \
        "$(printf '%s\n' "$links" | tr '\n' ' ' | sed 's/ $//')"
      return 0
    fi
    git -C "$repo" add -A >/dev/null 2>&1
    if git -C "$repo" -c user.name=felix-pulse -c user.email=pulse@felix.invalid \
         commit -q -m "pulse: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >/dev/null 2>&1; then
      printf 'backup\tcommitted\n'
    else
      # Returns rather than falling through. It used to push anyway: the push
      # succeeded because there was nothing new to send, the verification
      # passed because both heads were the stale one, and the run's LAST
      # line — the one a person skims — read "pushed and verified". A backup
      # that has silently stopped must not end on a success sentence.
      printf 'backup\tcommit FAILED; nothing was pushed, and this memory is NOT backed up\n'
      return 0
    fi
  else
    printf 'backup\tnothing new to commit\n'
  fi

  # The push target, never by alphabetical accident: the branch's own
  # upstream first, then origin, then the only remote there is. Two remotes
  # and no upstream is a person's ambiguity — `git remote | head -1` pushed
  # to whichever name sorted first and then verified that same wrong remote.
  remotes="$(git -C "$repo" remote 2>/dev/null)"
  remote="$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null)"
  remote="${remote%%/*}"
  if [ -z "$remote" ]; then
    if felix_has_line "$remotes" origin; then
      remote=origin
    else
      n_remotes="$(printf '%s\n' "$remotes" | grep -c .)"
      if [ "${n_remotes:-0}" -eq 1 ]; then
        remote="$remotes"
      elif [ "${n_remotes:-0}" -eq 0 ]; then
        printf 'backup\tno remote; the backup is this disk and only this disk\n'
        return 0
      else
        printf 'backup\t%s remotes and no upstream; a person picks where this pushes\n' "$n_remotes"
        return 0
      fi
    fi
  fi

  # Bounded the ways git can be bounded without a watchdog binary: http gets
  # a low-speed floor, ssh gets connect and keepalive caps. The documented
  # layout — a bare remote on this disk — cannot hang at all. What none of
  # this can bound is a transport streaming one byte a minute; launchd runs
  # the next pulse regardless.
  if git -C "$repo" \
       -c http.lowSpeedLimit=1 -c http.lowSpeedTime=30 \
       -c core.sshCommand="ssh -o ConnectTimeout=15 -o ServerAliveInterval=20 -o ServerAliveCountMax=3" \
       push -q "$remote" "$branch" >/dev/null 2>&1; then
    # Pushed is a claim; verified is a fact. Ask the remote what it holds
    # rather than trusting the exit status — a backup believed and absent is
    # worse than none, which is why the first one was restored before it was
    # believed.
    local_head="$(git -C "$repo" rev-parse HEAD 2>/dev/null)"
    remote_head="$(git -C "$repo" \
       -c http.lowSpeedLimit=1 -c http.lowSpeedTime=30 \
       -c core.sshCommand="ssh -o ConnectTimeout=15 -o ServerAliveInterval=20 -o ServerAliveCountMax=3" \
       ls-remote "$remote" "refs/heads/$branch" 2>/dev/null | cut -f1)"
    if [ -n "$local_head" ] && [ "$local_head" = "$remote_head" ]; then
      printf 'backup\tpushed and verified: %s holds %.12s\n' "$remote" "$local_head"
      # Stamped only here, on the one path where the memory demonstrably
      # left this disk. The staleness alarm used to read the last local
      # COMMIT, which the pulse writes every day whether or not the push
      # works — so in the exact case the alarm exists for, a push failing
      # for months, the age stayed at zero and nothing ever spoke.
      if [ -n "${FELIX_HOME_DIR:-}" ]; then
        mkdir -p "$FELIX_HOME_DIR/state" 2>/dev/null \
          && date +%s > "$(_felix_pulse_stamp "$FELIX_HOME_DIR")" 2>/dev/null
      fi
    else
      printf 'backup\tpushed, but %s reads back %.12s against local %.12s\n' \
        "$remote" "${remote_head:-nothing}" "$local_head"
    fi
  else
    printf 'backup\tpush failed — unreachable, or diverged; nothing was forced, and a divergence is a person'\''s to reconcile\n'
  fi
  return 0
}

# Days since the memory demonstrably left this disk. Empty only when the
# pulse has never run at all; `never` when it has run and never once
# succeeded.
#
# Measured from the stamp the verified-push path writes, not from the last
# local commit. The commit happens every day whether or not the push works —
# and whether or not a remote exists at all — so a version reading it
# reported zero days in precisely the states this alarm exists for: a push
# failing for months, a repository with no remote, a permanent refusal.
#
# Every refusal above is honest and invisible: it prints into a log file
# nobody opens, and a heartbeat that has refused for ninety days looks
# exactly like one that ran. This is the number that makes a silent stop
# observable, and the session hook is where a person actually reads.
felix_pulse_backup_age() {
  local home="${1:-}" stamp last now
  [ -n "$home" ] || return 0
  stamp="$(_felix_pulse_stamp "$home")"
  if [ ! -f "$stamp" ]; then
    # Never succeeded, but only say so once the pulse has actually run;
    # before that there is nothing to report rather than an alarm.
    [ -f "$home/state/pulse.log" ] && printf 'never'
    return 0
  fi
  last="$(cat "$stamp" 2>/dev/null)"
  case "${last:-}" in ''|*[!0-9]*) printf 'never'; return 0 ;; esac
  now="$(date +%s)"
  [ "$now" -ge "$last" ] 2>/dev/null || { printf '0'; return 0; }
  printf '%s' $(( (now - last) / 86400 ))
}

# resolve.sh holds felix_repo_root and felix_resolve_project, both used below.
# Sourced by path with the house guard because the suite sources this library
# alone, in a subshell — and without it the two calls would be missing rather
# than wrong, leaving `self` empty, the root never offered, and every checked
# row reported as unasked. A fix that degrades to doing nothing is the harder
# kind to notice.
if ! command -v felix_repo_root >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

# What is waiting, one line per fact. Reads only Felix's own tables and state.
felix_pulse_report() {
  local home="$1" proj name due unasked st root self selfproj

  # The one checkout this may name. The pulse runs from launchd with whatever
  # cwd launchd had, so $PWD says nothing, and a project records no path — it
  # is found FROM a checkout by remote match, never the reverse. What is true
  # is that a home which is itself a checkout is the checkout of exactly one of
  # these projects, and passing it to the others would run their reality-checks
  # in a tree that is not theirs. So the root is offered to that project alone
  # and withheld everywhere else, where the status is now `unchecked` and says
  # so rather than reading as a row with nothing to answer to.
  self="$(felix_repo_root "$home" 2>/dev/null)"
  selfproj=""
  [ -n "$self" ] && selfproj="$(felix_resolve_project "$self" "$home" 2>/dev/null)"

  for proj in "$home"/projects/*/; do
    proj="${proj%/}"
    [ -f "$proj/project.json" ] || continue
    name="$(basename "$proj")"
    if [ -f "$proj/maintenance.tsv" ]; then
      root=""
      [ -n "$selfproj" ] && [ "$proj" = "$selfproj" ] && root="$self"
      st="$(felix_maint_status "$proj" "$root" 2>/dev/null)"
      due="$(printf '%s\n' "$st" | grep '^due' | cut -f2 | tr '\n' ' ')"
      due="${due% }"
      [ -n "$due" ] && printf 'due\t%s\t%s\n' "$name" "$due"
      unasked="$(printf '%s\n' "$st" | grep '^unchecked' | cut -f2 | tr '\n' ' ')"
      unasked="${unasked% }"
      [ -n "$unasked" ] && printf 'unchecked\t%s\t%s\n' "$name" "$unasked"
    fi
    if [ -f "$proj/routes.tsv" ] && felix_discover_stale "$proj" "$home"; then
      printf 'stale\t%s\tdiscovery cache; the next session refreshes it in the background\n' "$name"
    fi
  done
  return 0
}

# The launchd agent, emitted rather than written so a test can read it and
# the writer stays four lines. 09:07 local, daily: early enough that the
# first session of a day inherits a fresh backup, odd enough to say a machine
# chose it. launchd's own capture goes to a separate file — the pulse tees
# its structured lines into the log itself, and one line written twice reads
# as two heartbeats. Paths land inside <string> verbatim; the standard
# layouts contain no XML metacharacters, and one that did would break the
# schedule loudly at load, not silently.
felix_pulse_plist() {
  local bin="$1" log="$2"
  cat <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>felix.pulse</string>
  <key>ProgramArguments</key><array>
    <string>$bin</string>
    <string>pulse</string>
  </array>
  <key>StartCalendarInterval</key><dict>
    <key>Hour</key><integer>9</integer>
    <key>Minute</key><integer>7</integer>
  </dict>
  <key>StandardOutPath</key><string>$log.launchd.log</string>
  <key>StandardErrorPath</key><string>$log.launchd.log</string>
</dict></plist>
PLIST
}
