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
# Duties, five and a record. All of it is bash and git (and jq, when present, for
# the settings check). Only the first duty writes outside state/ or reaches a
# network, and then only the backup remote; the next four read and never act:
#   backup   commit and push the memory repository, verified by asking the
#            remote what it now holds; a rejected push is reported and never
#            forced, because a divergence is another machine's work and
#            reconciling it is a person's call
#   report   name what is waiting — maintenance due, discovery caches stale —
#            so the pulse log doubles as a note about what the next session
#            will find
#   settings whether ~/.claude/settings.json still enables Felix: that file is
#            what a broken hand edit can turn Felix off with, and no hook of
#            Felix's can say so, because none of them loads
#   reach    which declared plugin and mcp servers a project's last reach cache
#            says do not connect, or that no cache has been read for
#   lane     last of all, one line per lane the home's own project counts
#            (lib/lane.sh, felix_lane_pulse): its state, and L and T, the
#            landings in the window that carry the lane's mark and the
#            landings that touch its paths. It reads the home checkout's
#            refs/remotes/origin/main as last fetched and the lane tables as
#            committed; it fetches nothing, and a home that is not a git
#            checkout bound to a project gets no line
# and the record, which is not a duty but what a run leaves behind:
#   record   state/pulse.status.tsv, rewritten whole by every run: `# ran
#            <epoch>`, then the lines the run printed, so a status surface
#            reads the last run without parsing the log
#
# The pulse runs no `claude` command, so the reach duty reads a cache that a
# session start or felix stack --reach wrote and never asks the servers itself.
# The launchd job runs /bin/bash, which holds Full Disk Access on this machine,
# and `claude mcp list` starts every configured stdio server, some of them at
# floating `npx ...@latest` versions: a daily unattended run would hand floating
# third-party code full disk access. And the pulse's own charter is no network
# beyond the backup remote.
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

# The tree is read through _felix_git_read, which lives in resolve.sh. The CLI
# and the session-start hook source that first; sourced here too, as verify.sh
# does, so a caller that sources this alone still has it.
if ! command -v _felix_git_read >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

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

# When the memory last reached the remote, as a stamp this writes itself.
_felix_pulse_stamp() { printf '%s/state/pulse.last-push' "$1"; }

# Commit if dirty, push if a target is unambiguous, then verify by re-reading
# the remote head. Emits status lines and always returns 0: an honest
# "nothing to do" is not a failure, and neither is a refusal this
# deliberately makes.
felix_pulse_backup() {
  local repo="$1" gitdir remotes remote branch local_head remote_head n_remotes where
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

  # A status that did not finish is not "nothing new" (2026-10-08). A corrupt
  # index makes `git status` exit 128 with nothing printed, and the run went
  # on to push the old head, verify it, and stamp the backup current.
  local st
  if ! _felix_git_read st git -C "$repo" status --porcelain; then
    printf 'backup\tgit could not read this tree (%s), so nothing was committed, and this memory is NOT backed up\n' \
      "$(git -C "$repo" status --porcelain 2>&1 >/dev/null | awk '!p && /^(error|fatal): / { print; p = 1 }')"
    return 0
  fi
  if [ -n "$st" ]; then
    # What goes into the commit, and what is left out and said so: a nested git
    # repository, a file that gained a credential (lib/pulse-stage.sh).
    felix_pulse_stage "$repo" || return 0
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
      # Verified is a fact about the remote's head; where the remote is, is a
      # second one. A path on this machine is still this disk's fate when
      # whatever syncs the path stalls (a bare repository under iCloud), and the
      # line says so (audit b06, C094). Never the address, which can carry a password.
      where="$(felix_pulse_remote_where "$repo" "$remote")"
      case "$where" in
        disk)    printf 'backup\tpushed and read back: %s holds %.12s; %s is a path on this machine, so this copy is only as far from this disk as whatever syncs that path\n' "$remote" "$local_head" "$remote" ;;
        network) printf 'backup\tpushed and read back: %s holds %.12s\n' "$remote" "$local_head" ;;
        *)       where=unknown; printf 'backup\tpushed and read back: %s holds %.12s; where %s is could not be read\n' "$remote" "$local_head" "$remote" ;;
      esac
      # Stamped only here, on the one path where the memory demonstrably
      # left this disk. The staleness alarm used to read the last local
      # COMMIT, which the pulse writes every day whether or not the push
      # works — so in the exact case the alarm exists for, a push failing
      # for months, the age stayed at zero and nothing ever spoke. The place
      # is written beside it, first, so a new stamp never sits over an old place.
      if [ -n "${FELIX_HOME_DIR:-}" ]; then
        mkdir -p "$FELIX_HOME_DIR/state" 2>/dev/null \
          && { printf '%s\n' "$where" > "$(_felix_pulse_stamp "$FELIX_HOME_DIR").where" 2>/dev/null \
               || rm -f "$(_felix_pulse_stamp "$FELIX_HOME_DIR").where" 2>/dev/null; } \
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
  case "${last:-}" in ''|*[!0123456789]*) printf 'never'; return 0 ;; esac
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
# reach.sh holds felix_reach_report and status.sh felix_settings_state, which
# felix pulse prints. Guarded the same way, and at load: status.sh sources this
# file only at call time, so there is no cycle.
if ! command -v felix_reach_report >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/reach.sh"
fi
if ! command -v felix_settings_state >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/status.sh"
fi
# What goes into the backup commit, and what a session start is told about it
# (lib/pulse-stage.sh); and discovery's record of its own refresh, which the
# report below reads (lib/discover-refresh.sh).
if ! command -v felix_pulse_stage >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/pulse-stage.sh"
fi
if ! command -v felix_discover_report_line >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/discover-refresh.sh"
fi

# What is waiting, one line per fact. Reads only Felix's own tables and state.
felix_pulse_report() {
  local home="$1" proj name due unasked unread st root self selfproj

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
      # A row whose capability could not be looked up is neither due nor
      # dormant. Its own line, and never in the due one: a false due sends
      # someone to work that may not apply.
      unread="$(printf '%s\n' "$st" | grep '^unknown' | cut -f2 | tr '\n' ' ')"
      unread="${unread% }"
      [ -n "$unread" ] && printf 'unknown\t%s\t%s\n' "$name" "$unread"
    fi
    if [ -f "$proj/routes.tsv" ] && felix_discover_stale "$proj" "$home"; then
      # What the last background refresh did, from its record, and what happens
      # next; never a promise the engine cannot keep (lib/discover-refresh.sh).
      felix_discover_report_line "$proj" "$home"
    fi
    # Reach, from the project's cache alone. This never runs claude: the launchd
    # job runs /bin/bash, which holds Full Disk Access on this machine, and
    # `claude mcp list` starts every configured stdio server, some at floating
    # `npx ...@latest` versions, so a daily unattended run would hand floating
    # third-party code full disk access, and the pulse's charter is no network
    # beyond the backup remote. The cache is written at a session start or by
    # felix stack --reach; a missing or old one is itself a line here.
    felix_reach_report "$proj" "$home"
  done
  return 0
}

# What a run leaves for a status surface: `# ran <epoch>`, then the lines it
# printed after its header, in order. Written to a temp file and moved into
# place so a reader never sees half a record, and written whatever became of the
# log append, because the record is the one thing a surface reads. Best effort:
# a record that could not be written is not a failed run.
felix_pulse_record() {
  local home="$1" lines="$2" rec tmp
  rec="$home/state/pulse.status.tsv"; tmp="$rec.new.$$"
  mkdir -p "$home/state" 2>/dev/null || return 0
  if { printf '# ran %s\n' "$(date +%s)"; [ -z "$lines" ] || printf '%s\n' "$lines"; } > "$tmp" 2>/dev/null \
     && mv -f "$tmp" "$rec" 2>/dev/null; then
    return 0
  fi
  rm -f "$tmp" 2>/dev/null
  return 0
}

# XML text for a <string>: & first, then < and >.
felix_pulse_xml() { printf '%s' "$1" | LC_ALL=C sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

# The launchd agent, emitted rather than written so a test can read it and
# the writer stays four lines. 09:07 local, daily: early enough that the
# first session of a day inherits a fresh backup, odd enough to say a machine
# chose it. launchd's own capture goes to a separate file — the pulse tees
# its structured lines into the log itself, and one line written twice reads
# as two heartbeats. That file lives outside the Felix home, under
# ~/Library/Logs, because launchd opens it before the program starts, as
# itself rather than as the shell that will run the pulse, and macOS refused
# that open under ~/Documents on 2026-10-29: the spawn failed with exit 78, so
# the program never ran and wrote nothing (felix status showed the exit, and
# nothing else did). The program is /bin/bash, which holds the privacy grant
# on a Mac where it was given (A31), running the served engine's felix, so no
# `env` lookup decides which bash runs it. There is no Program key: launchd
# would run that program and take ProgramArguments only as its argv. The
# measurements are in docs/2026-10-29-pulse-agent-contract.md. Both paths are
# XML-escaped before they land inside <string>, so a home holding &, < or >
# still yields a plist that parses.
felix_pulse_plist() {
  local bin capture
  bin="$(felix_pulse_xml "$1")"; capture="$(felix_pulse_xml "$2")"
  cat <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>felix.pulse</string>
  <key>ProgramArguments</key><array>
    <string>/bin/bash</string>
    <string>$bin</string>
    <string>pulse</string>
  </array>
  <key>StartCalendarInterval</key><dict>
    <key>Hour</key><integer>9</integer>
    <key>Minute</key><integer>7</integer>
  </dict>
  <key>StandardOutPath</key><string>$capture</string>
  <key>StandardErrorPath</key><string>$capture</string>
</dict></plist>
PLIST
}
