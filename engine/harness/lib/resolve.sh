# Project resolution for Felix. Sourced by the CLI and the session hook, which
# are the two real callers; it is not a layer waiting for a third.
#
# Dependencies are bash and git only. Deliberately no jq and no python: Felix
# governs projects in languages it must not require, so it cannot drag a runtime
# along. The JSON reader below is the price of that, and its limits are stated.

# Substring test that never builds a pipeline.
#
# `producer | grep -q x` is a trap under `set -o pipefail`: grep exits the moment it matches,
# the producer takes SIGPIPE, and the pipeline reports 141. The check then says "absent" about
# something that is present. It is worse than a plain bug because it is timing-dependent for
# small producers, so it passes in testing and fails against a real repository. Close every
# descriptor this shell inherited above the standard three.
#
# Called as the first thing inside a background subshell. Measured on the shipped session-start
# hook, with a commission grant live so the background resume actually ran:
#
#   hook process exits           1.9s
#   its stderr pipe reaches EOF  12.2s
#
# Ten of those seconds are not work. Something in the background tree was holding the stderr
# pipe the platform reads to know the hook is done, so the session waited for a refresh it was
# never supposed to wait for. Redirecting 0, 1 and 2 inside the subshell does not fix it — every
# background job here already did that. Closing descriptors 10 through 13 in the subshell did:
# 12.2s became 1.9s, repeatably.
#
# What is measured and what is inferred, kept apart on purpose. The measurement is the A/B
# above. The inference is WHY a descriptor in that range holds the pipe: bash saves a redirected
# descriptor on a high number to restore it afterwards, and a subshell forked while one is live
# inherits the copy. A minimal reproduction of that shape did NOT reproduce the hang, so treat
# the explanation as unconfirmed and the fix as empirical. If you are here because something
# regressed, re-run the A/B rather than reasoning from this paragraph.
#
# Bounded rather than enumerated: bash allocates saved descriptors from 10
# upward, and /dev/fd enumeration needs a descriptor of its own to read.
felix_close_inherited_fds() {
  local _fd=3
  while [ "$_fd" -le 30 ]; do
    [ -e "/dev/fd/$_fd" ] && eval "exec ${_fd}>&-"
    _fd=$((_fd + 1))
  done
  return 0
}

felix_contains() {
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

# Whole-line variant, for lists where a substring match would be too loose.
felix_has_line() {
  local line
  while IFS= read -r line; do [ "$line" = "$2" ] && return 0; done <<EOF
$1
EOF
  return 1
}

# Where Felix keeps writable state: projects and their doctrine. Not their
# memory, which since 2026-08-14 lives outside any repository — see
# felix_mem_root below for why that had to stop being the same directory.
#
# Separate from the engine because an installed plugin lives in a versioned cache that is
# replaced wholesale on update. Writing project doctrine in there would lose it on the next
# `claude plugin update`, silently, which is the worst way to lose a lesson someone paid for.
#
# Order: an explicit environment variable, then the pointer file `felix install` writes, then a
# repo checkout that already carries projects/ beside the engine, then the default. Is this
# engine path a deployed copy of Felix rather than a checkout of it?
#
# Two callers need this and they must agree. felix_home must never adopt such a copy as a home —
# a constitution frozen at install time, and memory written into a directory the next plugin
# update deletes. And cmd_install must never treat one as the tree being deployed FROM: run the
# deployed CLI and its own FELIX_ROOT *is* the cache, so `diff -rq "$FELIX_ROOT/harness"
# "$live/harness"` compared the deployed engine with itself, could not fail, and certified a
# repository whose engine had never been deployed at all. That is #55, and it was the fifth
# defect in this project whose cause was "correct code, installed nowhere" — sitting inside the
# guard written to stop the other four.
#
# One definition, because the alternative is two and the two would drift. This is the same
# correction #56 made to the base-resolution check an hour earlier, for the same reason.
#
# Matched on the path, not on anything inside the directory. A frozen copy is
# byte-identical to the checkout it came from and carries no marker that would
# tell them apart; where it sits is the only evidence there is.
felix_plugin_copy() {
  case "${1:-}" in
    */.claude/plugins/cache/*|*/.claude/plugins/marketplaces/*) return 0 ;;
    *) return 1 ;;
  esac
}

# The Felix engine tree being operated ON, which is not the tree the running
# script lives IN whenever somebody uses the deployed CLI — which is what every
# session-start message tells them to do.
#
# Prints the engine directory and returns 0, or prints nothing and returns 1 when no checkout
# can be found. Callers decide what an absence means: felix install refuses, because a deploy it
# cannot verify is the defect; felix bootstrap reports "none", because a machine with no Felix
# checkout genuinely has no repository for CI to fetch the harness from.
#
# Two commands needed this and each grew its own answer. cmd_install's was written for #55;
# cmd_bootstrap resolved the same question with `felix_repo_slug "$FELIX_ROOT"` and got it wrong
# the same way, one function along (#65) — from the cache it returned empty and printed "Felix
# has no remote for CI to fetch" about an engine whose remote exists, and on a machine whose
# home is itself a git repository with an origin it would have returned THAT slug, straight into
# a generated workflow's `repository:` beside a deploy key. So the resolution lives here once.
#
# Order: what the marketplace actually serves, then where you are standing, then the home. The
# first is the real answer — Claude Code deploys from the registered marketplace root and
# nowhere else — and the other two are what to try before a first install has registered one.
#
# A candidate qualifies only by carrying engine/harness/felix, never by being a
# git repository with a remote. That is what keeps an unrelated home checkout
# from being mistaken for the engine.
felix_engine_source() {
  local engine="${1:-}" home="${2:-}" cand
  [ -n "$engine" ] || return 1
  felix_plugin_copy "$engine" || { printf '%s' "$engine"; return 0; }
  for cand in "$(felix_marketplace_root)" "$(felix_repo_root "$PWD")" "$home"; do
    [ -n "$cand" ] || continue
    [ -x "$cand/engine/harness/felix" ] || continue
    printf '%s' "$cand/engine"; return 0
  done
  return 1
}

# Where the felix plugin is actually deployed, or nothing.
#
# Asked of the CLI rather than read off the cache directory, because the cache keeps every
# version it has ever installed and the newest on disk is not necessarily the one that loads.
#
# One reader because it had been written out three times and the copies had already diverged:
# both of cmd_install's asked the CLI and nothing else, while the project gate falls back to the
# highest cached version when the CLI is absent. That gate keeps its own copy on purpose — a
# project's gate must run without the engine's libraries, which is the property the independence
# check exists to protect — so this replaces the engine's two, not all three.
#
# Fails quiet. No CLI, or a CLI that answers nothing, is "no deployment I can see", and every
# caller here treats that as "say nothing" rather than as a finding.
felix_deployed_engine() {
  command -v claude >/dev/null 2>&1 || return 1
  local p
  p="$(claude plugin list --json 2>/dev/null \
       | sed -n '/"felix@felix"/,/}/p' \
       | sed -n 's/.*"installPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$p" ] || return 1
  printf '%s' "$p"
}

# What the home pointer names, read the one way both of its readers read it.
#
# felix install writes the path verbatim with a newline after it, so the read trims whitespace
# from the two ends and nothing inside. It deleted every whitespace character until 2026-09-24,
# which turned a home under `~/Library/Mobile Documents/` — iCloud's Documents, the ordinary
# place for one — into `.../MobileDocuments/...`: a directory nobody wrote, so the pointer never
# resolved, and the refusal sent the reader to a path that does not exist. A pointer that is
# empty or only whitespace still reads as empty. Status 2, nothing printed, when the read did not finish: cat's 1 with
# nothing read is an unreadable pointer, empty as before (L3); any other status, or 1 after part of it, is not an answer.
_felix_home_pointer() {
  local p r LC_ALL=C
  p="$(cat "$HOME/.felix-home" 2>/dev/null)"; r=$?
  case "$r:$p" in 0:*|1:) ;; *) return 2 ;; esac
  p="${p#"${p%%[![:space:]]*}"}"
  p="${p%"${p##*[![:space:]]}"}"
  printf '%s' "$p"
}

felix_home() {
  local engine="$1"
  if [ -n "${FELIX_HOME:-}" ]; then printf '%s' "$FELIX_HOME"; return; fi
  if [ -f "$HOME/.felix-home" ]; then
    local p; p="$(_felix_home_pointer)"
    [ -n "$p" ] && [ -d "$p" ] && { printf '%s' "$p"; return; }
  fi
  # A plugin install is a frozen copy of the whole repository, projects/
  # included. Trusting that copy would govern from a constitution frozen at
  # install time and write memory into a directory the next plugin update
  # deletes, both silently. The copy is never a home.
  if ! felix_plugin_copy "$engine"; then
    # The engine may sit at the repo root, or one level down so that a plugin
    # install carries the engine alone and leaves projects/ behind. Check both
    # before falling through, or a fresh clone silently starts a new home and
    # reports the project it is standing in as unknown.
    [ -d "$engine/projects" ] && { printf '%s' "$engine"; return; }
    [ -d "$engine/../projects" ] && { (cd "$engine/.." && pwd); return; }
  fi
  printf '%s' "$HOME/.felix"
}

# Where project memory lives — and deliberately not under felix_home.
#
# Doctrine and memory were one directory tree until 2026-08-14, and that is what made this
# repository unpublishable. Doctrine is the part worth showing and the part the founder owns
# outright. Memory is not: it holds verbatim founder prompts, and whatever a governed project's
# work happens to be about, which includes material belonging to somebody who never agreed to be
# published. A repository that stores every governed project's memory can never be public, and
# left alone that cost is paid again by every project Felix adopts rather than once.
#
# The root is computed from $HOME and never from felix_home, even though every other writable
# thing Felix owns hangs off home. Derived from home it would sit inside the repository in the
# one case that actually went wrong — Felix governing itself, where home *is* the checkout. The
# invariant is worth more than the symmetry: memory is outside a repository by construction, not
# by whichever directory home resolved to today.
#
# A gitignore rule was the cheaper option and is not enough. It is one `git add
# -f` from failing, it does nothing about a tree somebody clones or cleans, and
# it leaves the material on disk inside the repository either way. Ignoring a
# file is a statement about git. Moving it is a statement about the disk.
felix_mem_root() {
  printf '%s' "${FELIX_MEMORY:-$HOME/.felix/memory}"
}
# Where Claude Code keeps plugins, skills and settings: CLAUDE_CONFIG_DIR, an
# empty one read as unset, else ~/.claude. The global config, .claude.json, is
# ${CLAUDE_CONFIG_DIR:-$HOME}/.claude.json. Libraries that may be sourced
# without this file write the expansion out.
felix_claude_dir() { printf '%s' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"; }
# One field of one plugin's entry in the installed-plugin registry.
#
# Bounded to the entry: opened by the plugin's own key, closed by the next key or the end of the
# file, on a pretty-printed registry and a minified one alike. The shape this replaces set a
# flag on the key line and printed the next matching field it met, which on an entry lacking
# that field returned the NEXT plugin's value, and on a single-line registry returned the last
# one in the file for every name. Two callers carried that shape independently — the ledger's
# hook classifier and the commissioning provenance — so it lives here, in the library both
# already depend on, rather than being fixed twice.
#
# Prints nothing when the registry, the entry or the field is absent. Nothing
# is the honest answer: a guess here is a wrong provenance or a wrong tier.
felix_registry_field() {   # bare plugin name, field name -> value, or nothing
  local name="$1" field="$2" reg="${3:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/installed_plugins.json}"
  [ -n "$name" ] && [ -n "$field" ] && [ -f "$reg" ] || return 0
  awk -v p="\"$name@" -v k="$field" '
    {
      line = $0
      if (!f) { i = index(line, p); if (!i) next; f = 1; line = substr(line, i + length(p)) }
      else if (line ~ /^[[:space:]]*"[^"]+@[^"]+"[[:space:]]*:/) exit
      if (match(line, /"[^"]+@[^"]+"[[:space:]]*:/)) line = substr(line, 1, RSTART - 1)
      if (match(line, "\"" k "\"[[:space:]]*:[[:space:]]*\"[^\"]*\"")) {
        s = substr(line, RSTART, RLENGTH)
        sub("^\"" k "\"[[:space:]]*:[[:space:]]*\"", "", s); sub(/"$/, "", s)
        print s; exit
      }
    }' "$reg" 2>/dev/null
}


# The memory directory for one project, named by its doctrine directory.
#
# Keyed on the project's name rather than its path, so a worktree and the tree it
# came from share one memory. That is the behaviour every caller already assumed
# when memory sat beside doctrine under a single home, and the alternative — one
# memory per checkout — would silently split a project's lessons the first time
# somebody opened a worktree.
felix_mem_dir() {
  local p="${1%/}"
  printf '%s/%s' "${FELIX_MEMORY:-$HOME/.felix/memory}" "${p##*/}"
}

# The locale, decided 2026-10-08. The engine runs in its caller's locale, and a
# macOS Terminal sets LANG=en_US.UTF-8, so `felix` run by a person, and every
# hook of a claude started from that Terminal, runs in UTF-8; a desktop
# session's tool shell runs in C, which is why no session saw what follows.
# Measured on macOS 26, bash 3.2.57, with a Latin-1 byte (\351):
#
#   - BSD sed, tr and cut stop at a byte that is not UTF-8 ("illegal byte
#     sequence") and print nothing more; grep misses a match that lies after
#     one on its line; awk aborts the whole program on a regex over one; and a
#     pattern holding one compiles to nothing, in grep and in [[ =~ ]]. One
#     such byte on a project.json line above "gate" made the sed below print
#     nothing, and the Stop hook then judged no gate at all.
#   - awk splits and slices by bytes but matches by characters, so a program
#     that walks text a byte at a time aborts on a lone byte of a VALID
#     character too. lib/deny-read.sh did: any Bash command holding an accent
#     or a dash passed every deny row.
#   - bash collates its own globs and bracket ranges in the locale: `for f in
#     *` gives `_x alpha Beta` in UTF-8 and `Beta _x alpha` in C, and
#     `case B in [a-z])` matches in UTF-8. Even `[0-9]` admits one character,
#     U+2185, which collates as 6; `[ "$n" -ne 3 ]` then errors and takes the
#     else branch. macOS's [[:digit:]] admits 670.
#
# Two rules follow, and tests/run holds the engine to both:
#
#   1. A function whose answer can depend on bash's own collation (where the
#      first match of a glob decides, where a bracket range judges input a
#      person or a third party wrote, or wherever it uses [[ =~ ]]) declares
#      LC_ALL=C in a `local` line. bash restores the caller's on return, and it
#      costs no process. A bracket over digits alone in bash's own pattern is
#      spelled out instead, everywhere: [0123456789], not [0-9]. A local
#      LC_ALL=C would also make ${#x} count bytes in that function.
#   2. A grep, sed, tr, cut, awk, paste, fold, column, rev or expand that reads
#      bytes the engine did not write (a table, project.json, a file of the
#      governed repository, a diff, the gate's output, a plugin's files), where
#      its result decides something, is written `LC_ALL=C <tool>` on that
#      command. In a function that exists to decide from such bytes, every one
#      is, so a later edit cannot add one that is not; tests/run lists them.
#
# Display keeps the caller's locale, so a message still counts characters as
# the person's terminal does. sort, comm, join and uniq are pinned everywhere,
# by the rule tests/run states beside its lint for them.

# Read one top-level string field out of a flat JSON file. Handles exactly what project.json
# needs: one nesting level, no escaped quotes. Anything richer belongs in a real parser, and
# would mean project.json has outgrown its job.
#
# Something at the path that is not a regular file is not opened, and reads as no field
# (2026-10-01). Resolution reads every project's project.json, so a pipe at one project's path
# held sed open for a writer that never came, and every hook of every project waited on it.
# Nothing at the path is left to sed as before.
felix_json_str() {
  if [ -e "$1" ] && [ ! -f "$1" ]; then return 2; fi
  LC_ALL=C sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$1" | head -1
}

# Reads that say whether they finished (2026-10-31), each under felix_capture (lib/detect.sh): a fork that failed or a read
# killed is not an empty answer. _felix_cap loads it from beside this file (declare -F: no fork, no function named command);
# when it cannot, every read that needed it did not finish.
# The readers run in felix_capture's subshell (a cd there moves nothing) and return 0 for each finished answer.
# _felix_git_in prints a last line, git's status or - for a DIR it cannot enter, which _felix_st_split takes into _FELIX_ST,
# the rest in _FELIX_SO with its trailing LFs dropped as $(...) drops them. _felix_json_field is felix_json_str's sed and
# head with both statuses read (head's alone hid sed's); sed's 141, the SIGPIPE after head took its line, is an answer.
_felix_cap() {
  declare -F felix_capture >/dev/null && return 0
  local f="${BASH_SOURCE[0]:-}" d
  d="${f%/*}"; [ "$d" != "$f" ] || d=.
  [ -f "$d/detect.sh" ] && . "$d/detect.sh" 2>/dev/null
  declare -F felix_capture >/dev/null
}
_felix_git_in() { cd "$1" 2>/dev/null || { printf '\n-'; return 0; }; shift; git "$@" 2>/dev/null; printf '\n%s' "$?"; }
_felix_st_split() {   # VALUE
  local v="$1" nl=$'\n'
  _FELIX_ST="${v##*"$nl"}"; v="${v%"$nl"*}"
  while [ "${v%"$nl"}" != "$v" ]; do v="${v%"$nl"}"; done
  _FELIX_SO="$v"
}
_felix_marker_read() { [ -r "$1" ] || return 0; LC_ALL=C tr -d '[:space:]' < "$1" 2>/dev/null; }   # unreadable names nothing
_felix_json_field() { [ -f "$1" ] && [ -r "$1" ] || return 0
  LC_ALL=C sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$1" | head -1; set -- "${PIPESTATUS[@]}"; case "$1:$2" in 0:0|141:0) ;; *) return 1 ;; esac; }
_felix_ls() { ls "$1" 2>/dev/null; case "$?" in 0|1|2) return 0 ;; esac; return 1; }   # a directory ls cannot list is no names
_felix_rr_walk() { cd "$1" 2>/dev/null || return 0; printf x; pwd -P; }   # x: the cd worked, so an empty answer is not one

# Print the repo root for a directory, or the directory itself when not in git.
# Felix must work in a checkout that is not a git repo at all. It prints what it printed before 2026-10-31 in every case,
# and returns 2 when a read did not finish (the walk's pwd -P, git rev-parse; git's 128 and a failed cd are answers).
felix_repo_root() {
  local start="${1:-$PWD}" root d rc=0 st nl=$'\n'
  # bash 3.2 keeps the text of a failed write (stdout closed, a full disk) in
  # its stdout buffer and flushes it ahead of the next output, into this very
  # $( ). Flush it to /dev/null first; bash 5 has already dropped it.
  { echo -n; } 2>/dev/null >/dev/null
  # Walk up for .git before asking git: rev-parse costs about 12ms, a third of
  # PreToolUse's budget, for an answer the filesystem has. `.git` is a file in
  # a worktree or submodule, so -e covers both. Only an absolute path is walked;
  # any other text ends in ${d%/*} == $d, which never ends.
  if _felix_cap; then
    felix_capture d _felix_rr_walk "$start" || { d=""; rc=2; }
    case "$d" in x/*) d="${d#x}" ;; x) d=""; rc=2 ;; *) d="" ;; esac   # a relative one is not walked, and git decides
  else rc=2; d="$(cd "$start" 2>/dev/null && pwd -P)" || d=""; fi
  case "$d" in /*) ;; *) d="" ;; esac
  while [ -n "$d" ] && [ "$d" != "/" ]; do
    [ -e "$d/.git" ] && { printf '%s' "$d"; return "$rc"; }
    d="${d%/*}"
  done
  # Nothing found by walking. Ask git anyway rather than give up: GIT_DIR set in
  # the environment, or any layout where the marker is not on the path above,
  # is exactly the case the walk cannot see and git can. Its output is kept whatever its status, as before; the
  # sentinel after it says whether git ran to its end.
  root="$(cd "$start" 2>/dev/null || { printf '\n-.'; exit 0; }; git rev-parse --show-toplevel 2>/dev/null; printf '\n%s.' "$?")"
  st="${root##*"$nl"}"
  case "$st" in -.|[0123456789].|[0123456789][0123456789].|[0123456789][0123456789][0123456789].) root="${root%"$nl"*}"; while [ "${root%"$nl"}" != "$root" ]; do root="${root%"$nl"}"; done ;; *) st="" ;; esac
  case "$st:$root" in 0.:/*|-.:*|128.:*) ;; *) rc=2 ;; esac
  [ -n "$root" ] && printf '%s' "$root" || printf '%s' "$start"
  return "$rc"
}

# The branch and the commit a tree stands on, each as exactly one field.
#
# Both were read, in two libraries, as `$(git ... 2>/dev/null || echo '?')`, which is wrong in
# the one state where it matters. On an unborn HEAD — what `git init` leaves, and where a
# project is commissioned — `rev-parse --abbrev-ref HEAD` prints `HEAD` AND exits 128, so the
# fallback does not replace the answer, it is appended to it: the field arrived as "HEAD\n?".
#
# In memory.sh that made a mistakes.log row two lines with no fourth column on either, and every
# reader of that log takes column four a line at a time, so the failure was written down and
# could not be read. In receipt.sh the escaper flattened the newline, so the document stayed
# valid json and said `"branch": "HEAD ?"` — the quieter of the two, and found a day after the
# first, because the fix for the first put these readers in memory.sh, where receipt.sh could
# not reach them. They are here because this is the one file both already load however they are
# loaded: the CLI and every hook source it first, receipt.sh sources it itself when it is
# missing, and memory.sh needs it for felix_mem_dir.
#
# The fallback is assigned, the way felix_tree_id reads HEAD, so a command that failed has its
# output discarded whole. The branch is asked of symbolic-ref first because an unborn HEAD still
# has one — `git init -b main` is on main before anything is committed — and a detached HEAD
# falls through to the `HEAD` rev-parse always gave. The commit there genuinely does not exist,
# and says `unborn`, felix_tree_id's word for the same state, rather than `?`, which is what a
# directory that is no repository at all still reads as.
#
# Tabs and newlines are stripped on the way out. A ref name cannot hold one, so this changes
# nothing today; it is here because these are fields of a tab-separated row and of a json
# string, and either is only as well-formed as its worst field.
felix_head_branch() {
  local root="$1" b
  b="$(git -C "$root" symbolic-ref --short -q HEAD 2>/dev/null)" \
    || b="$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null)" || b=""
  printf '%s' "${b:-?}" | LC_ALL=C tr -d '\t\n\r'
}

felix_head_commit() {
  local root="$1" c
  c="$(git -C "$root" rev-parse --short HEAD 2>/dev/null)" || c=""
  if [ -z "$c" ]; then
    if git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then c="unborn"; else c="?"; fi
  fi
  printf '%s' "$c" | tr -d '\t\n\r'
}

# mistakes.log as its rows, with the split rows an older engine left joined
# back into the one row they were meant to be (U44).
#
# #267 fixed the writer above, and nothing fixed what it had already written.
# One failure on an unborn HEAD, before #267, is two physical lines on disk:
#
#   <date> TAB HEAD                 exactly two fields
#   ? TAB ? TAB <what>              exactly three fields
#
# rev-parse printed `HEAD` and exited 128, so `|| echo ?` appended `\n?` to the branch, and the
# commit field was the lone `?`. Column four is on neither line, so every reader that takes
# column four a line at a time read nothing there: gate_shown_failing stayed held on an install
# whose gate the person had watched go red, and the monitor counted the one failure twice (U42).
#
# A pair becomes `<date> TAB HEAD TAB unborn TAB <what>`. HEAD stays because it
# is what was recorded and the real branch cannot be recovered; `unborn` is
# #267's own word for the state, and the pair proves it, because HEAD with a
# non-zero exit happens only there. So a healed row and a new row on the same
# unborn tree are one occasion to felix_mem_recurring_mistakes, as #267 meant.
#
# Only an exact pair is joined, matched on fields rather than on a regex with `\t` or `\?` in
# it, because the CI's awk may be mawk. A two-field HEAD line whose first field is not a date, a
# ?-? line of any other width, either half alone, and every other line (a detached HEAD's
# four-field row, a directory that was no repository, anything #267 writes) pass through byte
# for byte. The date is spelled out rather than written `{4}`, which older awks lack.
#
# This is the one definition of the pair. The heal in memory.sh rewrites the file with it, and
# every lib reader reads through it, because the heal can decline and `felix commission
# --status` never heals, and a reader must be right either way. It is here and not in memory.sh
# for the reason the two readers above are: every entry point sources resolve.sh first, and so
# do the suite's single-lib subshells, which load the monitor or the guard with nothing else
# beside them.
#
# _felix_mem_mistake_join reads stdin, so the heal can feed it a snapshot bounded
# to a byte count; felix_mem_mistake_rows takes the file. A file whose last line
# has no newline gets one on stdout, which a reader does not mind and the heal
# never writes back. A missing file prints nothing. Both always return 0.
_felix_mem_mistake_join() {
  LC_ALL=C awk -F'\t' '
    held != "" {
      if (NF == 3 && $1 == "?" && $2 == "?") { print held "\tunborn\t" $3; held = ""; next }
      print held; held = ""
    }
    NF == 2 && $2 == "HEAD" && $1 ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ { held = $0; next }
    { print }
    END { if (held != "") print held }
  ' 2>/dev/null
  return 0
}

felix_mem_mistake_rows() {
  [ -f "${1:-}" ] || return 0
  _felix_mem_mistake_join < "$1" 2>/dev/null
  return 0
}

# The owner/repo a GitHub origin names, lowercased, in _FELIX_RS; empty for any other URL.
# felix_remote_github_slug (own.sh) reads it, sourced from beside this file if not loaded;
# without own.sh the owner/repo rule falls to its anchored suffix. 0 with _FELIX_RS the slug or
# empty (not GitHub, or no own.sh); 2 with it empty when the read did not finish (a 0 with nothing).
_felix_remote_slug() {   # URL
  local s
  _FELIX_RS=""
  case "$1" in *[Gg][Ii][Tt][Hh][Uu][Bb].[Cc][Oo][Mm]*) ;; *) return 0 ;; esac
  declare -F felix_remote_github_slug >/dev/null \
    || { [ -f "${BASH_SOURCE[0]%/*}/own.sh" ] && . "${BASH_SOURCE[0]%/*}/own.sh" 2>/dev/null; }
  declare -F felix_remote_github_slug >/dev/null || return 0
  _felix_cap && felix_capture s _felix_gh_slug "$1" || return 2
  _felix_st_split "$s"; [ "$_FELIX_ST" = 1 ] || [ -n "$_FELIX_SO" ] || return 2
  _FELIX_RS="$_FELIX_SO"
  return 0
}
_felix_gh_slug() { felix_remote_github_slug "$1" 2>/dev/null; set -- "$?"; case "$1" in 0|1) printf '\n%s' "$1" ;; *) return 1 ;; esac; }

# ASCII lowercase of $1 into _FELIX_LC, in this shell: no process.
_felix_lc() {
  local c t="$1"
  for c in Aa Bb Cc Dd Ee Ff Gg Hh Ii Jj Kk Ll Mm Nn Oo Pp Qq Rr Ss Tt Uu Vv Ww Xx Yy Zz; do t="${t//${c:0:1}/${c:1:1}}"; done
  _FELIX_LC="$t"
}

# Does remote_match M name the origin URL U? S is _felix_remote_slug of U. M is read as own.sh reads
# it, a trailing / and then a trailing .git dropped (M2); _FELIX_RM_LEN is M2's length: longer wins.
#   owner/repo, with a GitHub slug S: they match when M2 lowercased is S, and in no other way
#     ("acme/web" is not "acme/web-extras").
#   else: U loses a trailing / and .git too and matches M2 when equal or when U ends in M2 after a
#     /, : or @, case-sensitively.
_felix_remote_match() {   # M U S
  local m="$1" u="$2" s="${3:-}" m2 u2 pre LC_ALL=C
  local lc=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-
  m2="${m%/}"; m2="${m2%.git}"; _FELIX_RM_LEN="${#m2}"
  [ -n "$m2" ] || return 1
  case "$m2" in
    */*/*|/*|*/|*[!/$lc]*) ;;
    */*) if [ -n "$s" ]; then _felix_lc "$m2"; [ "$_FELIX_LC" = "$s" ]; return; fi ;;
  esac
  u2="${u%/}"; u2="${u2%.git}"
  [ "$u2" = "$m2" ] && return 0
  case "$u2" in *"$m2") pre="${u2%"$m2"}"; case "${pre: -1}" in /|:|@) return 0 ;; esac ;; esac
  return 1
}

# The project the origin remote of ROOT binds, among those of HOME. Returns 0
# and sets _FELIX_RB_P (a project name), 1 when none matches, 2 when several
# match equally and _FELIX_RB_TIE holds their names, 3 with both empty when a read
# did not finish (the origin, a remote_match, the slug). _FELIX_RB_U is the origin
# URL (empty when unread); it is never printed or written, as an https remote can
# carry a token. Only a git that exited 0 gives a URL: its 2 and 128, and a ROOT it
# cannot enter, are no URL whatever git printed (main's || _FELIX_RB_U="").
_felix_resolve_remote() {   # ROOT HOME
  local root="$1" felix_root="$2" meta m m2 n ul best=0 sdone=0 nl=$'\n' LC_ALL=C
  _FELIX_RB_P=""; _FELIX_RB_TIE=""; _FELIX_RB_U=""
  _felix_cap && felix_capture m _felix_git_in "$root" remote get-url origin || return 3
  _felix_st_split "$m"
  case "$_FELIX_ST:$_FELIX_SO" in 0:?*) _FELIX_RB_U="$_FELIX_SO" ;; 2:*|128:*|-:*) ;; *) return 3 ;; esac
  [ -n "$_FELIX_RB_U" ] || return 1
  _felix_lc "$_FELIX_RB_U"; ul="$_FELIX_LC"
  for meta in "$felix_root"/projects/*/project.json; do
    [ -e "$meta" ] || continue
    felix_capture m _felix_json_field "$meta" remote_match || { _FELIX_RB_P=""; _FELIX_RB_TIE=""; return 3; }
    m="${m%%"$nl"*}"
    [ -n "$m" ] || continue
    # Any match has M without a trailing / and .git, lowercased, inside U: look before the slug costs.
    m2="${m%/}"; _felix_lc "${m2%.git}"; case "$ul" in *"$_FELIX_LC"*) ;; *) continue ;; esac
    [ "$sdone" = 1 ] || { sdone=1; _felix_remote_slug "$_FELIX_RB_U" || { _FELIX_RB_P=""; _FELIX_RB_TIE=""; return 3; }; }
    _felix_remote_match "$m" "$_FELIX_RB_U" "$_FELIX_RS" || continue
    n="${meta%/project.json}"; n="${n##*/}"
    if [ "$_FELIX_RM_LEN" -gt "$best" ]; then best="$_FELIX_RM_LEN"; _FELIX_RB_P="$n"; _FELIX_RB_TIE=""
    elif [ "$_FELIX_RM_LEN" -eq "$best" ]; then _FELIX_RB_TIE="${_FELIX_RB_TIE:-$_FELIX_RB_P} $n"; fi
  done
  [ -n "$_FELIX_RB_P" ] || return 1
  [ -z "$_FELIX_RB_TIE" ] || return 2
  return 0
}

# Resolve which project governs a working directory.
# Prints the project directory on success, prints nothing and returns 1 on miss, and prints
# nothing and returns 2 when a read the answer stands on did not finish (could not tell).
#
# Order matters. The .felix marker wins because it is the only mechanism that works for a repo
# with no remote, a fork, a rename, or a checkout of somebody else's code. Remote matching is
# the convenience path, not the contract: the longest remote_match that names the origin, and no
# project on a tie (felix_binding_broken says so). The locale rules are above felix_json_str.
felix_resolve_project() {
  local start="${1:-$PWD}" felix_root="$2" LC_ALL=C
  local root name
  _felix_cap && felix_capture root felix_repo_root "$start" && [ -n "$root" ] || return 2

  # 1. explicit marker file naming the project
  if [ -f "$root/.felix" ]; then
    felix_capture name _felix_marker_read "$root/.felix" || return 2
    if _felix_name_ok "$name" && [ -d "$felix_root/projects/$name" ]; then
      printf '%s' "$felix_root/projects/$name"
      return 0
    fi
    return 1
  fi

  # 2. the origin remote, against the remote_match each project declares
  _felix_resolve_remote "$root" "$felix_root"; case "$?" in 0) ;; 3) return 2 ;; *) return 1 ;; esac
  printf '%s' "$felix_root/projects/$_FELIX_RB_P"
  return 0
}

# VAR START HOME: felix_resolve_project read whole, output and status, into VAR (the project directory, or empty): 0
# found, 1 a miss that stands, 2 when the resolution or the read of it did not finish. No locals, as felix_capture has
# none: VAR is the caller's variable.
felix_resolve_read() {
  printf -v "$1" '%s' ""
  _felix_cap && felix_capture _FELIX_RR _felix_resolve_st "$2" "$3" || return 2
  _felix_st_split "$_FELIX_RR"
  case "$_FELIX_ST:$_FELIX_SO" in 0:?*) printf -v "$1" '%s' "$_FELIX_SO"; return 0 ;; 1:) return 1 ;; esac
  return 2
}
_felix_resolve_st() { felix_resolve_project "$1" "$2"; printf '\n%s' "$?"; }

# Where the session stands, as against where the platform started the hook.
#
# Claude Desktop starts every hook in its --project-config-root, the main checkout, whatever
# directory the session works in, while the payload's top-level "cwd" is the session's own: a
# worktree as often as not. Measured on 2.1.284 and 2.1.286 with the real binary and a mock API.
# A hook that resolves from $PWD then judges the main checkout. Without the flag, the CLI, the
# two are one directory.
#
# The hook leaves the directory it was started in for three reasons only:
#   - the payload's directory is another checkout or worktree of the project
#     that governs the launch directory (the Desktop worktree);
#   - the payload's directory is governed and the launch directory governs
#     nothing (no marker at all: a broken one is reported where it is);
#   - the payload's directory holds a broken .felix marker, which is reported
#     where the session stands.
# A directory another project governs, one nothing governs, a path that is not
# there, is relative or holds a JSON escape: all answer with $PWD, as before.
#
# Read in pure bash, from the first 4096 characters only (characters in a UTF-8 locale, bytes in
# C; the envelope's opening keys are ASCII either way). The top-level "cwd" is the third key of
# the envelope, well inside that, so a "cwd" in a tool's input or a prompt, which sits after it
# or past it, is never reached. Only the FIRST key is looked at: if its value is not a string
# there is no candidate, and a later key is not tried. A quote inside a JSON string is spelt \",
# which the pattern does not match, and a path that needs an escape is left to $PWD rather than
# decoded. The pattern is held in a variable so that bash 3.2, which macOS ships, takes it as
# the regex it is.
#
# Known limits. A session that cd's into a same-project scratch clone is judged as that clone's
# tree, as the CLI already does. A session that cd's into a directory nothing governs is judged
# at the launch directory, which in Desktop is the main checkout. Both need a per-session record
# of where the session stood, which this does not keep.
_felix_hook_dir_set() {   # payload, home -> _felix_hd
  local raw="${1:-}" home="${2:-}" c root pc pl re='^[[:space:]]*:[[:space:]]*"([^"]*)"' LC_ALL=C
  _felix_hd="$PWD"
  raw="${raw:0:4096}"
  case "$raw" in *'"cwd"'*) ;; *) return 0 ;; esac
  raw="${raw#*\"cwd\"}"
  [[ $raw =~ $re ]] || return 0
  c="${BASH_REMATCH[1]}"
  case "$c" in /*) ;; *) return 0 ;; esac
  case "$c" in *\\*) return 0 ;; esac
  # The CLI: the same directory in any spelling (a symlinked launch path, a
  # trailing slash). Nothing to resolve, and this runs on every tool call.
  [ "$c" -ef "$PWD" ] && return 0
  [ -d "$c" ] || return 0
  # A resolution or a root that did not finish moves nothing: the hook stays where the platform started it.
  felix_resolve_read pc "$c" "$home" 2>/dev/null || [ "$?" = 1 ] || return 0
  if [ -z "$pc" ]; then
    # Nothing governs it. A marker that resolves nothing is a broken binding.
    felix_capture root felix_repo_root "$c" 2>/dev/null || return 0
    [ -f "$root/.felix" ] && _felix_hd="$c"
    return 0
  fi
  # Another project governing the launch directory keeps the hook where it is;
  # the launch project is looked up only here, off the common path.
  felix_resolve_read pl "$PWD" "$home" 2>/dev/null || [ "$?" = 1 ] || return 0
  if [ "$pl" = "$pc" ]; then
    _felix_hd="$c"
  elif [ -z "$pl" ]; then
    # A launch directory whose marker resolves nothing was meant to be
    # governed: its breakage is reported where it is, not stepped over.
    felix_capture root felix_repo_root "$PWD" 2>/dev/null || return 0
    [ -f "$root/.felix" ] || _felix_hd="$c"
  fi
  return 0
}

felix_hook_dir() {   # payload, home -> the directory a hook should stand in
  _felix_hook_dir_set "${1:-}" "${2:-}"
  printf '%s' "$_felix_hd"
  return 0
}

# Stand there, in the calling shell, so every $PWD a hook or a library default
# reads from here on is the session's. Not a subshell: a hook runs on every tool
# call and a fork is a cost it pays each time.
felix_hook_enter() {   # payload, home
  _felix_hook_dir_set "${1:-}" "${2:-}"
  [ "$_felix_hd" = "$PWD" ] || cd "$_felix_hd" 2>/dev/null
  return 0
}

# Marker and pointer contents are written by whoever edited the file, and both
# end up inside a JSON string a hook emits. Printable characters only, and
# short, so a broken binding cannot be used to say something else.
#
# Short is had by cutting the middle, and the cut says so. This kept the first eighty characters
# until 2026-09-24, and when the eightieth closed a directory name the refusal named the
# target's parent: a real path, and a wrong answer rather than a short one. The tail is where
# the directory a pointer names is, so it keeps the larger share. The whole value is always in
# the file the refusal names. Into _FELIX_SN, in this shell (2026-10-31): its printf | tr pipe was
# unchecked, and a fork that failed put an empty name in a refusal. It keeps tr -cd [:print:]'s
# bytes in C, space to tilde, as lib/lane-resolve.sh's _lane_clean does.
_felix_binding_sane() {
  local LC_ALL=C s="$1"
  s="${s//[!\ -~]/}"
  if [ "${#s}" -le 80 ]; then _FELIX_SN="$s"; else _FELIX_SN="${s:0:24}[...]${s:${#s}-51}"; fi
}

# What a project name may be: one directory name under projects/, made of
# letters, digits, dot, underscore and dash, not starting with a dot or a
# dash. `.` and `..` are directories and `-d` says so, which is how a marker
# reading `.` resolved to a healthy binding at `projects/.` — a project with
# no tables, no deny rows and no gate, and every hook reading it as governed.
# A name holding a slash is a path, and a path is not a name either.
_felix_name_ok() {
  local LC_ALL=C
  case "${1:-}" in
    ''|.*|-*|*/*|*[!A-Za-z0-9._-]*) return 1 ;;
  esac
  return 0
}

# The remote half of felix_binding_broken, for a tree with no marker. 2, nothing printed, when a read did not finish. An origin that binds a
# project is written down, one line of bindings.tsv in the memory root: <key> TAB <project> TAB
# <UTC stamp>. The key is the hash of HOME and the origin URL, so no part of the URL, which can
# carry a token, is stored. A tie is reported. An origin that bound project P and no longer
# resolves is reported when projects/P/ is still a directory and project.json in it is not a
# readable file: a file that went missing, was renamed or cannot be read. Nothing else is: a
# remote_match emptied or changed, projects/P/ removed, an origin never bound, another home, an
# unwritable or unreadable record, or a line naming no project name. Those are deliberate or
# unknown, and a hold in every repository Felix is not adopted in would make it unusable there.
_felix_bind_key() { printf '%s\n%s\n' "$2" "$3" | git -C "$1" hash-object --stdin 2>/dev/null; set -- "${PIPESTATUS[@]}"; [ "$1:$2" = 0:0 ]; }
_felix_binding_remote() {   # ROOT HOME
  local root="$1" home="$2" key mem f last="" stamp="" k p t dir alt="" j rc LC_ALL=C
  [ -n "$home" ] || return 0
  rc=0; _felix_resolve_remote "$root" "$home" || rc=$?
  [ "$rc" != 3 ] || return 2
  [ -n "$_FELIX_RB_U" ] || return 0
  _felix_cap && felix_capture key _felix_bind_key "$root" "$home" "$_FELIX_RB_U" || return 2
  case "${#key}:$key" in *:*[!0123456789abcdef]*) return 2 ;; 40:*|64:*) ;; *) return 2 ;; esac   # one SHA-1 or SHA-256 line
  mem="${FELIX_MEMORY:-$HOME/.felix/memory}"; f="$mem/bindings.tsv"   # felix_mem_root's body: no fork to fail
  if [ -f "$f" ] && [ -r "$f" ]; then
    while IFS=$'\t' read -r k p t || [ -n "${k:-}" ]; do
      [ "$k" = "$key" ] && { last="$p"; stamp="$t"; }
    done 2>/dev/null < "$f"
  fi
  case "$rc" in
    0) [ "$last" = "$_FELIX_RB_P" ] && return 0
       { mkdir -p "$mem" && printf '%s\t%s\t%s\n' "$key" "$_FELIX_RB_P" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$f"; } 2>/dev/null
       return 0 ;;
    2) _felix_binding_sane "${_FELIX_RB_TIE// /, }"
       printf 'The origin of the checkout at %s fits %s equally well: each declares a remote_match that names it, with the same length. So no project is bound, and nothing is checking this tree.\n\n' \
         "$root" "$_FELIX_SN"
       printf 'Lengthen one remote_match, or name the project in a .felix marker.\n'
       return 0 ;;
  esac
  _felix_name_ok "$last" && dir="$home/projects/$last" && [ -d "$dir" ] || return 0
  [ -f "$dir/project.json" ] && [ -r "$dir/project.json" ] && return 0
  for j in "$dir"/project*.json; do
    [ -f "$j" ] && [ "${j##*/}" != project.json ] && { alt="${j##*/}"; break; }
  done
  [ -z "$alt" ] || { _felix_binding_sane "$alt"; alt=", only \"$_FELIX_SN\""; }
  _felix_binding_sane "$stamp"
  printf 'The origin of the checkout at %s bound it to %s (recorded %s in %s), and %s no longer resolves: projects/%s/ holds no readable project.json%s. Nothing is checking this tree.\n\n' \
    "$root" "$last" "$_FELIX_SN" "$f" "$last" "$last" "$alt"
  printf 'Restore the file, or name the project in a .felix marker. If %s is retired, delete projects/%s/ or its line in %s.\n' "$last" "$last" "$f"
}

# A binding that is PRESENT and does not resolve.
#
# felix_resolve_project answers one question — which project governs here — and returns non-zero
# for two states that are not the same fact. Nothing named this checkout, which is the ordinary
# case and means ungoverned. Or something named it and the name went nowhere, which means
# somebody broke the binding and nothing is being checked. Every caller reads a non-zero resolve
# as the first, so `echo nonexistent > .felix` switched the whole floor off in one line: no
# gate, no hold, no record, exit 0.
#
# Absent is not broken, and that half must keep working. A directory with no marker and no
# matching remote is a repository Felix does not govern, and it has to stay silent there or
# Felix is unusable anywhere it has not been adopted. This function is the other half, and it is
# this project's own rule that "nothing due" and "nothing is being checked" must not render
# identically.
#
# Two surfaces, because there are two ways to say where the binding points. `$HOME/.felix-home`
# is checked first and matters more: it decides which home the marker below is resolved against,
# it is read on every invocation, and it sits outside every repository — so changing it produces
# no diff, no classification, and nothing for a reviewer to see. A pointer that exists and names
# a directory that is not a Felix home is a broken pointer, not an absence.
#
# An explicit $FELIX_HOME wins over the pointer in felix_home, so when it is set the pointer is
# never consulted and cannot bypass anything. Unread is not broken either.
#
# Prints a sentence when the binding is broken and nothing when it is not, the same shape as the
# other reporters a hook interpolates. It never repairs: the correct binding is not knowable
# from here, since only a person can say whether this tree is a project that was renamed or a
# tree Felix should leave alone. Status 2 and nothing printed when a read the answer stands on did
# not finish: no sentence is ever built from one.
felix_binding_broken() {
  local start="${1:-$PWD}" home="${2:-}" root name p known why="" nl=$'\n'

  # Three ways to be wrong, one place that decides and one place that prints.
  # Printing from inside each branch and deciding afterwards whether to finish
  # the sentence is how a partial refusal escapes — and a partial refusal is
  # worse than none, because the caller tests emptiness and would block on half
  # an explanation.
  if [ -z "${FELIX_HOME:-}" ] && [ -f "$HOME/.felix-home" ]; then
    _felix_cap && felix_capture p _felix_home_pointer || return 2
    _felix_binding_sane "$p"
    if   [ -z "$p" ]; then
      why="is empty, so it names no home"
    elif [ ! -d "$p" ]; then
      why="names $_FELIX_SN, which is not a Felix home: no such directory"
    elif [ ! -d "$p/projects" ]; then
      why="names $_FELIX_SN, which is not a Felix home: it holds no projects/ directory"
    fi
    if [ -n "$why" ]; then
      printf 'The Felix home pointer at %s %s.\n\n' "$HOME/.felix-home" "$why"
      printf 'Every hook in every session resolves through that pointer, and it lives outside every repository, so breaking it leaves no diff to review.\n\n'
      printf 'Point it at a real home, or delete it to fall back to the default:\n\n  felix install --home <path>\n'
      return 0
    fi
  fi

  _felix_cap && felix_capture root felix_repo_root "$start" || return 2
  [ -f "$root/.felix" ] || { _felix_binding_remote "$root" "$home"; return; }
  felix_capture name _felix_marker_read "$root/.felix" || return 2
  _felix_name_ok "$name" && [ -d "$home/projects/$name" ] && return 0

  felix_capture known _felix_ls "$home/projects" || return 2
  [ -z "$known" ] || known="${known//"$nl"/ } "
  _felix_binding_sane "$name"
  if [ -z "$name" ]; then
    printf 'The .felix marker in %s is empty, so it does not resolve to a project. ' "$root"
  elif ! _felix_name_ok "$name"; then
    printf 'The .felix marker in %s names "%s", which is not a project name: a name is one directory name under %s, and this is a path or a dot. ' \
      "$root" "$_FELIX_SN" "$home/projects"
  else
    printf 'The .felix marker in %s names "%s", and that does not resolve to a project under %s. ' \
      "$root" "$_FELIX_SN" "$home/projects"
  fi
  printf 'A marker is present, so this tree was meant to be governed, and right now nothing is checking it.\n\n'
  printf 'Name a project that exists, or remove the marker if this tree really is ungoverned:\n\n'
  printf '  known projects: %s\n' "${known:-none}"
}

# A refusal that belongs to no project, because the thing that broke is what
# decides which project this is.
#
# felix_say and felix_verify_log both key on a resolved project and cannot be used here. The
# memory root can: it is outside any repository by construction, it is the one writable place
# that does not need the binding to work, and a line here is the difference between a hook that
# refused and a hook that never ran.
felix_unresolved_log() {
  local reason="$1" where="${2:-}" mem
  mem="$(felix_mem_root)"
  [ -d "$mem" ] || mkdir -p "$mem" 2>/dev/null || return 0
  printf '%s\t%s\t%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${where:-unknown}" \
    "$(printf '%s' "$reason" | tr '\t\n' '  ')" \
    >> "$mem/unresolved.log" 2>/dev/null || true
}

# Does this base name something that exists here?
#
# The question felix_changed_paths cannot answer, because it sends every git error to /dev/null
# and so reports a base nobody can resolve as a branch that changed nothing. An empty answer and
# an unanswerable question are different facts, and every caller that conflates them reads the
# second as the first — which is always the permissive direction.
#
# `^{commit}` is load-bearing, and receipt.sh learned it first. `git rev-parse
# --verify <40-hex>` exits 0 for a sha this repository has never held, because a
# full-length hex string is a syntactically valid object name and --verify alone
# checks the syntax. Only a name it cannot parse exits non-zero. Peeling to a
# commit is what turns a syntax check into an existence test.
#
# An empty base is not a failure to resolve one. felix_changed_paths has always
# taken it to mean "no branch comparison, working tree only", and callers rely
# on that; deciding it is unknown would break every one of them.
#
# Status 2 is a lookup that failed because git could not run (felix_git_runs),
# and a third argument names a variable that then holds why. A git that never
# ran says nothing about the base: on 2026-11-14 an Xcode update left
# /usr/bin/git exiting 69 until its licence was accepted, and every reader of a
# 1 here printed "this base names nothing here" about a ref that existed. A
# caller that only asks whether it resolved reads 2 as it read 1. The locals
# are prefixed so that the variable a caller names is never one of them.
felix_base_resolves() {
  local _fbr_root="${1:-}" _fbr_base="${2:-}"
  [ -n "$_fbr_root" ] && [ -n "$_fbr_base" ] || return 1
  git -C "$_fbr_root" rev-parse --verify "$_fbr_base^{commit}" >/dev/null 2>&1 && return 0
  felix_git_runs "${3:-}" || return 2
  return 1
}

# The subject a row names a base by: the base as given, or in double quotes
# when it is spelled as one of the pseudo-subjects the rows' readers branch on
# (GIT, CHANGED-PATHS, ADDED-LINES, SUITE). A base that names nothing and is
# spelled GIT read as a git that could not run, to every reader that tells the
# two apart by subject (review of 2026-11-14), and CHANGED-PATHS as a change
# git could not read. Quoted, it is a base again, and a quoted name can be no
# pseudo-subject.
felix_base_subject() {
  case "${1:-}" in GIT|CHANGED-PATHS|ADDED-LINES|SUITE) printf '"%s"' "$1" ;; *) printf '%s' "${1:-}" ;; esac
}

# Does git run here at all? 0 when `git --version` exits 0, the first git on
# PATH run in this environment, as every other call runs it. Otherwise 2, and
# a first argument names a variable that then holds the clause the readers
# print: "git could not run here (git --version exited N)". Asked only after a
# git call has already failed, so a git that works costs nothing.
#
# `--version` needs no repository, reads no configuration and touches no file,
# so its failing is about git and nothing else. Apple's /usr/bin/git is a shim
# that runs xcrun, and xcrun refuses every call while the Xcode licence is not
# accepted (exit 69); a git missing from PATH is the shell's 127. What this
# does not see: a git that answers --version and refuses everything else (a
# missing git-core) reads as running, and a git that starts or stops running
# between the failed call and this one is read as it is now.
felix_git_runs() {
  local _fgr_rc=0
  git --version >/dev/null 2>&1 </dev/null || _fgr_rc=$?
  [ "$_fgr_rc" -ne 0 ] || return 0
  [ -z "${1:-}" ] || printf -v "$1" 'git could not run here (git --version exited %s)' "$_fgr_rc"
  return 2
}

# The ref a base NAME should actually be compared against.
#
# Every command defaults to `main`, and `main` is a local ref. In a worktree it is a SHARED
# local ref naming whatever the primary checkout last pulled — and a worktree cannot check
# `main` out, so nothing in that workflow ever advances it. Observed on this repository: local
# main three merges behind origin/main while the work continued in a worktree (#74).
#
# It is also the ref that matters least. `felix merge` merges through
# `gh pr merge`, so what a branch actually lands on is the REMOTE branch. The
# local one is a cache of it that this workflow never refreshes.
#
# Only a name whose remote-tracking ref exists is redirected to it. A sha, a `HEAD~1`, a tag, or
# a branch that lives only here is returned as itself: a local branch by its full name, and the
# rest as given, because rewriting those would invent a base nobody named.
#
# What this returns is a FULL ref name, and every ref it looks up is looked up by that exact
# name, never by a short one. Git resolves a short name by trying `$GIT_DIR/<n>`, `refs/<n>`,
# `refs/tags/<n>`, `refs/heads/<n>` and only then `refs/remotes/<n>` (gitrevisions), and every
# worktree of a repository shares one ref store. So any session can create
# `refs/tags/origin/main`, `refs/heads/origin/main` or `refs/origin/main`, and `origin/main`
# then names THAT commit for every reader: the base, the staleness, the changed paths, and the
# judge `felix merge` reads out of the base with `git show "$base:..."`. A full name has no such
# order to be won. `origin/X` is taken to mean `refs/remotes/origin/X` and nothing else (it does
# not fall through to a tag or a local branch of that name, which is exactly what a decoy is). A
# name that cannot be a ref-name component (`HEAD~1`, `main~1`, a sha, `v1^{tree}`) is never
# looked up under refs/ at all: `HEAD~1` means this repository's own `HEAD~1` even though a
# clone always has refs/remotes/origin/HEAD.
#
# An exact ref is looked up with `show-ref --verify`, which asks for that name
# and no other, and its object is then peeled to a commit by sha. A name that
# is not a commit (a tree, a blob) is no base.
#
# The same correction felix_kernel_dir makes, which now asks this function, and for the same
# reason — its comment records that hard-coding a branch name was "green on a laptop that says
# main and red on a runner that says master". An empty NAME is `main`, as every caller's default
# is; an empty ROOT is nothing, because `git -C ""` would read the current directory.
#
# No fetch, ever. The enforcing path has to work with no network, so this is as
# current as the last fetch and never more. That is a real limit and it is still
# strictly better than a ref the worktree workflow cannot advance at all.
felix_base_ref() {
  local root="${1:-}" base="${2:-main}" ref lookup
  [ -n "$root" ] || return 1
  [ -n "$base" ] || base=main
  case "$base" in -*) return 1 ;; esac
  case "$base" in
    refs/*)
      # A full ref name is taken as given, and only when it is a commit. One
      # that is a revision expression rather than a ref name (`refs/heads/x~1`)
      # is asked the way it always was.
      if git check-ref-format "$base" >/dev/null 2>&1; then
        _felix_ref_commit "$root" "$base" || return 1
      else
        git -C "$root" rev-parse --verify --quiet "$base^{commit}" >/dev/null 2>&1 </dev/null || return 1
      fi
      printf '%s' "$base"; return 0 ;;
    origin/*)
      ref="refs/remotes/$base"
      git check-ref-format "$ref" >/dev/null 2>&1 && _felix_ref_commit "$root" "$ref" || return 1
      printf '%s' "$ref"; return 0 ;;
  esac
  # A full-length hex string is an object name to git before it is a ref name,
  # so it is never looked up as one. Upper case too: git reads A-F as hex, so a
  # branch planted under the upper-case spelling of a sha would otherwise shadow
  # the object it spells.
  lookup=1
  case "$base" in
    *[!0123456789abcdefABCDEF]*) ;;
    *) case "${#base}" in 40|64) lookup=0 ;; esac ;;
  esac
  if [ "$lookup" -eq 1 ]; then
    for ref in "refs/remotes/origin/$base" "refs/heads/$base"; do
      git check-ref-format "$ref" >/dev/null 2>&1 || continue
      if _felix_ref_commit "$root" "$ref"; then printf '%s' "$ref"; return 0; fi
    done
  fi
  git -C "$root" rev-parse --verify --quiet "$base^{commit}" >/dev/null 2>&1 </dev/null || return 1
  printf '%s' "$base"
}

# Whether REF, a full ref name, exists as exactly that and peels to a commit.
# The object is read from the ref and then peeled by its sha, so no short-name
# rule gets a say in which ref was meant.
_felix_ref_commit() {   # ROOT REF
  local sha
  sha="$(git -C "$1" show-ref --verify -s -- "$2" 2>/dev/null </dev/null)" && [ -n "$sha" ] || return 1
  git -C "$1" rev-parse --verify --quiet "$sha^{commit}" >/dev/null 2>&1 </dev/null
}

# The two refs to diff to see what MERGING this branch would change, or nothing
# when that cannot be computed.
#
# `felix merge` squashes. A squash commit is not a descendant of the branch it came from, so
# merging a branch's base does not advance merge-base(base, branch) — it stays frozen at the
# commit before the base merged, for the life of the branch. Three-dot is anchored to that
# merge-base, so a stacked branch keeps being blamed for every path its base touched, even
# though the base now holds those exact bytes. #51, observed on #50 stacked on #49: a
# documentation change classified red by inheriting plugin.json, and a docs-only branch
# escalated to the founder because the branch below it had added a workflow.
#
# Neither two-dot nor three-dot is the answer, which is why this computes a third thing.
# Three-dot blames the branch for what is already in the base. Two-dot blames it for the base's
# INDEPENDENT progress — a file main gained and the branch never had reads as a deletion, which
# fails open. The object actually being judged is the tree a merge would produce, and
# `merge-tree` computes exactly that without touching the working tree.
#
# Silent about failure on purpose, and every failure falls back to three-dot:
#   - git older than 2.38 has no `--write-tree`
#   - a conflicting merge exits non-zero, and its tree is not what would land
#   - anything that does not look like an object id
# Three-dot over-reports, so falling back is the safe direction — it can only make the verdict
# stricter, never weaker. A narrower answer computed from a failed merge would be the opposite.
#
# The merge runs in a git directory made for the call (2026-11-08, S6.6), never in the checkout's own. A 3-way merge
# runs the merge driver the attributes name for every path both sides changed, and a driver is defined in config: the
# checkout's .git/config and .git/info/attributes are the worker's to write, so a driver `true` there kept main's
# side of a file and the change's own lines in it were never read (audits/2026-11-08-trust-plane-step3/
# checkout-merge-driver in the memory root). The made directory is an empty bare repository whose object store is the
# one the checkout reads (GIT_OBJECT_DIRECTORY when the caller set one, as felix merge's checked copy does), so the
# merged tree is written where the caller's diff reads it. Global and system config and attributes are switched off
# with it, the two sides are named by commit id, resolved once in the checkout, and a shallow checkout's boundary
# is copied in. The caller's GIT_DIR, GIT_WORK_TREE, GIT_COMMON_DIR and GIT_INDEX_FILE do not reach either git, and
# a TERM or INT removes the directory (review of 07f1e869, 2026-11-08). Inside felix merge, once lib/bind.sh's checked
# copy is in force, the merge reads the copy's stores alone and not the checkout's (S6.6 rule 2): with the checkout
# behind them, a loose file planted there under the merged blob's id was taken as the merge's result, which git
# does not write again, so the change's line was never read.
# S6.7 (2026-11-09): the merge detects no directory renames, set on its command line so that no config file and no
# GIT_CONFIG_* variable the caller exports turns it back on. The squash felix merge lands is GitHub's, and GitHub's test
# merge of #498 held the tree git writes with merge.directoryRenames=false. git's default (conflict) moved main's new
# files into the directory the branch had emptied and failed, so every reader took three-dot and slice 3 refused (A1);
# true moved them, and the readers blamed the branch for main's files (audits/2026-11-08-trust-plane-step3/
# merge-dir-renames in the memory root).
# Puts back the caller's TERM and INT traps once the made directory is gone.
_felix_merge_untrap() {
  trap - TERM INT
  [ -z "$told" ] || eval "$told"
  [ -z "$tint" ] || eval "$tint"
  _FELIX_MERGE_TMP=""
}
_felix_merge_refs() {
  local root="$1" base="$2" mb tip head tree objs tmpd g rc sh fmt told tint alt=()
  [ -n "$base" ] || return 1
  mb="$(git -C "$root" merge-base "$base" HEAD 2>/dev/null)" || return 1
  tip="$(git -C "$root" rev-parse "$base^{commit}" 2>/dev/null)" || return 1
  [ -n "$mb" ] && [ -n "$tip" ] || return 1
  # The base has not moved since this branch was cut, so three-dot already asks
  # exactly the right question. Left alone rather than rerouted, because this is
  # every ordinary branch and the fix is only for the case that differs.
  [ "$mb" = "$tip" ] && return 1
  head="$(git -C "$root" rev-parse --verify --quiet "HEAD^{commit}" 2>/dev/null)" || return 1
  objs="${GIT_OBJECT_DIRECTORY:-$(git -C "$root" rev-parse --path-format=absolute --git-path objects 2>/dev/null)}"
  # A relative object directory names a place under the checkout, as `git -C "$root"` reads it.
  case "$objs" in /*) ;; *) objs="$(cd "$root" 2>/dev/null && cd "$objs" 2>/dev/null && pwd -P)" ;; esac
  [ -n "$objs" ] && [ -d "$objs" ] || return 1
  if [ -n "${_FELIX_BIND_COPY:-}" ] && [ "$objs" = "$_FELIX_BIND_COPY/objects" ] && [ -d "$_FELIX_BIND_COPY/v" ]; then
    alt=(GIT_ALTERNATE_OBJECT_DIRECTORIES="$_FELIX_BIND_COPY/v")
  fi
  tmpd="${TMPDIR:-/tmp}"
  g="$(mktemp -d "${tmpd%/}/felix-merge.XXXXXX" 2>/dev/null)" || return 1
  _FELIX_MERGE_TMP="$g"; told="$(trap -p TERM)"; tint="$(trap -p INT)"
  trap 'rm -rf "$_FELIX_MERGE_TMP"; exit 143' TERM
  trap 'rm -rf "$_FELIX_MERGE_TMP"; exit 130' INT
  fmt="$(git -C "$root" rev-parse --show-object-format 2>/dev/null)"
  if ! env -u GIT_DIR -u GIT_WORK_TREE -u GIT_COMMON_DIR -u GIT_INDEX_FILE -u GIT_OBJECT_DIRECTORY \
       GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git init -q --bare --template= ${fmt:+--object-format="$fmt"} "$g/g" \
       >/dev/null 2>&1 </dev/null; then
    rm -rf "$g"; _felix_merge_untrap; return 1
  fi
  # A shallow checkout's boundary, so the merge does not walk to parents it does not hold.
  sh="$(git -C "$root" rev-parse --path-format=absolute --git-path shallow 2>/dev/null)"
  if [ -n "$sh" ] && [ -f "$sh" ] && ! cp "$sh" "$g/g/shallow" 2>/dev/null; then rm -rf "$g"; _felix_merge_untrap; return 1; fi
  # Reading the checked copy alone, the merge finds the commits since the merge base and no older one (lib/bind.sh
  # copies no further), so the base is its boundary, as a shallow checkout's is: walking to the base's parents, the
  # merge failed on every history longer than one commit, and every reader fell back to three-dot inside felix merge.
  if [ "${#alt[@]}" -gt 0 ] && ! printf '%s\n' "$mb" >> "$g/g/shallow" 2>/dev/null; then rm -rf "$g"; _felix_merge_untrap; return 1; fi
  tree="$(env -u GIT_WORK_TREE -u GIT_COMMON_DIR -u GIT_INDEX_FILE ${alt[@]+"${alt[@]}"} GIT_DIR="$g/g" GIT_OBJECT_DIRECTORY="$objs" \
          GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
          GIT_ATTR_NOSYSTEM=1 git -c core.attributesFile=/dev/null -c merge.directoryRenames=false \
          merge-tree --write-tree "$tip" "$head" 2>/dev/null </dev/null)"
  rc=$?
  rm -rf "$g"; _felix_merge_untrap
  [ "$rc" -eq 0 ] || return 1
  tree="$(printf '%s\n' "$tree" | head -1)"
  case "$tree" in
    ""|*[!0-9a-f]*) return 1 ;;
  esac
  printf '%s^{tree} %s' "$base" "$tree"
}

# Every path this branch touches, including what is staged but not committed.
#
# Run a git command that reads the working tree. Set the named variable to what
# it printed, and return 0 only when it ran to the end and exited 0.
#
# 2026-10-08. git does not block on a named pipe at a tracked path, and it does not skip one
# either. `git diff` and `git diff HEAD` print every path that sorts before it, then exit 128:
# "cannot hash". A mode-000 file does the same, and a corrupt index stops every diff before it
# prints anything. Every caller sent that to /dev/null and kept what was printed, so each path
# after the pipe was dropped in silence. The tree id of an edited tree came out as the clean
# commit's, and secret-scan passed an added key.
#
# A non-zero exit is not an answer. Neither is an empty capture whose subshell never ran, so the
# mark is written only after git returns 0. The mark is a line of its own holding a control
# character. A bare trailing `.` was tried first, and a partial diff whose last line is `+foo.`
# read as finished. No line git prints in a diff, a status or a listing is that line. The
# variable still gets the partial output on failure, for a caller that would rather list too
# much than too little. Trailing newlines are stripped as `$(...)` strips them, so what a caller
# hashes is byte for byte what it hashed before.
_felix_git_read() {   # VAR command...
  local _felix_gr_out _felix_gr_rc=1
  _felix_gr_out="$("${@:2}" 2>/dev/null && printf '\n\037ok')"
  case "$_felix_gr_out" in
    *$'\n\037ok') _felix_gr_rc=0; _felix_gr_out="${_felix_gr_out%$'\n\037ok'}" ;;
  esac
  # Asked by `case`, never by comparing a `%` that removes nothing: in bash 3.2
  # a `${v%$'\n'}` with no newline to remove is quadratic in the length of v.
  # The first draft looped on that comparison, and a 1 MB diff took 13 s of
  # CPU in a hook that runs at every stop (review, 2026-10-08).
  while case "$_felix_gr_out" in *$'\n') true ;; *) false ;; esac; do
    _felix_gr_out="${_felix_gr_out%$'\n'}"
  done
  printf -v "$1" '%s' "$_felix_gr_out"
  return "$_felix_gr_rc"
}

# One function because there were four, and they drifted in the same direction. Each tried `git
# diff --name-only base...HEAD` and fell back to `git diff base` only when that came back EMPTY
# — so on a branch with commits, which is every pull request, the fallback never ran and
# everything staged or unstaged was dropped. `felix evidence` told a session it owed a test the
# session had just staged, and felix_escapes could not see a staged workflow change or a staged
# credential at all.
#
# It hid because the shape that masks it is the shape a fixture reaches for: on
# a branch with no commits yet, `base...HEAD` is empty and the fallback covers
# everything. lessons.sh had this right and nothing required the others to agree.
#
# Three sources, unioned rather than fallen back through:
#   base...HEAD   committed on this branch
#   --cached      staged, about to be committed
#   (bare)        edited, not yet staged
#
# With rename detection off, so a renamed file lists both its names. git detects renames by
# default, and a rename then shows only where the file went: every rule keyed on a path or a
# basename is asked about the new name and never about the old. `git mv` of a project's deny
# table to deny-archived.tsv switched every one of its rules off, since the hook reads deny.tsv
# by name, and the verifier that guards the table saw a file it had no rule for. Same for the
# risk table whose count rows guard the gate and the suite. Found by a review of the table
# validator's contract, 2026-09-22, in a scratch clone. The flag follows --name-only because the
# merge-race test injects a peer checkout on `diff --name-only`, inside this very diff.
#
# Exits 1 when any of the three diffs did not finish (2026-10-08), and still prints every path
# it did read. A list git broke off is not the list of what changed, and a caller that decides
# on it must say it does not know. A tracked named pipe does not trip this one: --name-only
# compares stat data and never hashes, so it lists the pipe and exits 0. A corrupt index trips
# it, and so does a branch that shares no history with the base (`no merge base`).
felix_changed_paths() {
  local root="$1" base="${2:-}" refs out all="" rc=0
  # The branch side only where there is a branch. On an unborn HEAD, an orphan
  # checkout, `base...HEAD` fails for want of a commit, and "nothing committed
  # here" was always the answer read from it, so it is not asked.
  if [ -n "$base" ] && git -C "$root" rev-parse -q --verify HEAD >/dev/null 2>&1; then
    # What merging would change, when that is computable and differs from what
    # was typed. See _felix_merge_refs. Unquoted on purpose: it prints two refs.
    if refs="$(_felix_merge_refs "$root" "$base")"; then
      # shellcheck disable=SC2086
      _felix_git_read out git -C "$root" diff --name-only --no-renames $refs || rc=1
    else
      _felix_git_read out git -C "$root" diff --name-only --no-renames "$base...HEAD" || rc=1
    fi
    all="$out"
  fi
  _felix_git_read out git -C "$root" diff --name-only --no-renames --cached || rc=1
  all="$all
$out"
  _felix_git_read out git -C "$root" diff --name-only --no-renames || rc=1
  all="$all
$out"
  printf '%s\n' "$all" | LC_ALL=C grep -v '^$' | LC_ALL=C sort -u
  return "$rc"
}

# The patch the repository's content makes, whatever anyone configured about how
# git shows one (2026-10-08). Read into VAR as _felix_git_read reads, and 0 only
# when every read ran to the end. The arguments are a diff's revisions and
# options, with no pathspec. Each read ends them with `--`: with a tracked file
# named HEAD, `git diff HEAD` refused as ambiguous, so bin/secret-scan could
# never call such a repository clean (a blind author's assertion, after review).
#
# Porcelain `git diff` prints what a person's settings and a branch's attributes tell it to
# print. Measured on git 2.54, on a branch adding a credential line to creds.py, each of these
# made bin/secret-scan exit 0, and felix_added_lines read none of the line:
# - An external diff: `diff.external`, GIT_EXTERNAL_DIFF, or an attribute
#   `diff=<driver>` with `diff.<driver>.command`. git runs the program and prints
#   nothing of its own.
# - A textconv: `diff=<driver>` with `diff.<driver>.textconv`. git diffs the
#   filter's output, so `sed d` hid the line and a rewrite showed another.
# - A binary marking: the attribute `-diff` or `binary`, the same in the file
#   core.attributesFile names, `diff.<driver>.binary`, or core.bigFileThreshold
#   below the file's size. git prints "Binary files differ".
# - Colour: color.ui or color.diff set to always puts an escape before each
#   `+`, so no line read as added.
# None of these needs the person's config. A committed .gitattributes is read from the branch
# itself, so `creds.py -diff` in the branch blinded the scan of that branch. The tree id hashes
# the same patch: under an external diff or an empty textconv a clean tree and an edited one had
# one id, so a green receipt read current over an edit no gate had seen.
#
# Why per call:
# - A driver's name is anyone's to choose. No key turns every textconv or every
#   driver command off, so --no-textconv and --no-ext-diff are the only
#   switches, and they are per call. --no-ext-diff covers all three external
#   forms. --no-color is per call here too, so these readers do not wait on a
#   colour pin at the entry points.
# - A binary marking has no switch either. --text reads every file as text, and
#   was measured at 6.75 s CPU against 0.08 s on a branch adding a 20 MB random
#   binary, most of it bash holding the bytes. So only a path git printed as
#   binary is read again, and only when it is text by the rule git applies when
#   no attribute speaks: each side present is at most 512 MiB, the default
#   core.bigFileThreshold, and holds no NUL in its first 8000 bytes. A pair with
#   a binary side is still unread, as git leaves it by default. That includes a
#   branch that replaces a binary with text, which a review of this change
#   found, a gap git's default leaves and this does not widen.
# - Each path is named with --literal-pathspecs. The `:(literal)` magic that
#   was tried first is itself switched off by GIT_LITERAL_PATHSPECS=1, and with
#   it set the read again matched nothing and the scan exited 0. A read again
#   must print a patch for each path it named, or it is not whole.
#   GIT_GLOB_PATHSPECS or GIT_ICASE_PATHSPECS make git refuse the option, so
#   with either set a binary-marked text file is unread: exit 2, not clean.
# - Every read runs from the top of the work tree, so diff.relative cannot
#   narrow it to the directory a caller named.
# - The a/ and b/ prefixes are pinned, because diff.noprefix, diff.srcPrefix,
#   diff.dstPrefix and diff.mnemonicPrefix change the `+++` header a reader takes
#   a path from. bin/secret-scan does; `dstPrefix = b/fixtures/` made every file
#   it read a fixture's, which it does not scan.
# - --ignore-submodules=none, because diff.ignoreSubmodules and a committed
#   .gitmodules `ignore = all` hid a moved submodule pointer.
# - -M, rename detection as git's default has it, because diff.renames=copies
#   would hide a copied file's lines. The content rules that read these lines
#   ask what a change adds, and a pure move adds nothing. bin/secret-scan reads
#   with --no-renames instead, since its fixture exclusion is a property of the
#   path, and a key moved out of fixtures/ is a new key where it lands.
# For a default configuration every flag here prints what git printed without
# it, byte for byte, so no tree id changed when this landed.
#
# tests/run refuses an engine line that runs `git diff` without --no-ext-diff and --no-textconv
# on it, unless the line asks only for names. Not covered, and why:
# - A clean filter, core.fsmonitor, assume-unchanged and skip-worktree change
#   what git sees in the working tree, and they change what `git add` commits
#   the same way.
# - `git show <rev>:<path>`, `git grep` and `git diff --quiet` apply no textconv
#   or external diff by default (measured).
# - A working-tree-encoding file's side in the tree is judged on its bytes as
#   stored there, so a UTF-16 file a person also marks binary stays unread.
# - An added line that itself begins `++ ` prints as `+++` and is taken for a
#   header: no setting is needed for that, and it is its own defect.
# bin/secret-scan holds a copy of this, since it sources no library.
_felix_git_patch() {   # VAR ROOT diff-args...
  local _fgp_var="$1" _fgp_top _fgp_all="" _fgp_rec _fgp_meta="" _fgp_ok="" _fgp_rc=0 _fgp_n _fgp_st
  local _fgp_bin=() _fgp_text=() _fgp_t=$'\t'
  _fgp_top="$(git -C "$2" rev-parse --show-toplevel 2>/dev/null)"
  [ -n "$_fgp_top" ] || { printf -v "$_fgp_var" '%s' ""; return 1; }
  shift 2
  _felix_git_read _fgp_all git -C "$_fgp_top" diff --no-ext-diff --no-textconv --no-color --src-prefix=a/ --dst-prefix=b/ --ignore-submodules=none -M "$@" -- || _fgp_rc=1
  # The paths git printed as binary. -z, read to NUL, because a path may hold
  # any byte but that one. The mark is a record git never prints.
  while IFS= read -r -d '' _fgp_rec; do
    case "$_fgp_rec" in
      -"$_fgp_t"-"$_fgp_t"*) _fgp_bin+=("${_fgp_rec#-"$_fgp_t"-"$_fgp_t"}") ;;
      $'\037'ok) _fgp_ok=1 ;;
    esac
  done < <(git -C "$_fgp_top" diff --no-ext-diff --no-textconv --ignore-submodules=none --no-renames --numstat -z "$@" -- 2>/dev/null && printf '\037ok\0')
  [ -n "$_fgp_ok" ] || _fgp_rc=1
  if [ "${#_fgp_bin[@]}" -gt 0 ]; then
    # Each one's sides, from --raw: `:oldmode newmode oldsha newsha status`, then
    # the path. A deleted path adds nothing, and an unmerged one is left as git
    # left it.
    _fgp_ok=""
    while IFS= read -r -d '' _fgp_rec; do
      if [ -n "$_fgp_meta" ]; then
        _fgp_st="${_fgp_meta##* }"
        case "$_fgp_st" in
          D*|U*) ;;
          *) _fgp_n="${_fgp_meta#:* * }"
             { [ "${_fgp_st#A}" != "$_fgp_st" ] || _felix_side_text "$_fgp_top" "${_fgp_n%% *}" "$_fgp_rec"; } \
               && _fgp_n="${_fgp_n#* }" && _felix_side_text "$_fgp_top" "${_fgp_n%% *}" "$_fgp_rec" \
               && _fgp_text+=("$_fgp_rec") ;;
        esac
        _fgp_meta=""
        continue
      fi
      case "$_fgp_rec" in
        :*) _fgp_meta="$_fgp_rec" ;;
        $'\037'ok) _fgp_ok=1 ;;
      esac
    done < <(git --literal-pathspecs -C "$_fgp_top" diff --no-ext-diff --no-textconv --ignore-submodules=none --no-renames --no-abbrev --raw -z "$@" -- "${_fgp_bin[@]}" 2>/dev/null && printf '\037ok\0')
    [ -n "$_fgp_ok" ] || _fgp_rc=1
  fi
  if [ "${#_fgp_text[@]}" -gt 0 ]; then
    local _fgp_more
    _felix_git_read _fgp_more git --literal-pathspecs -C "$_fgp_top" diff --no-ext-diff --no-textconv --no-color --src-prefix=a/ --dst-prefix=b/ --ignore-submodules=none --no-renames --text "$@" -- "${_fgp_text[@]}" || _fgp_rc=1
    # A patch for each path asked for, or the read is not whole. Distinct
    # headers, since a type change prints its path's header twice.
    _fgp_n="$(printf '%s\n' "$_fgp_more" | LC_ALL=C awk '/^diff --git / && !s[$0]++ { n++ } END { print n + 0 }')"
    [ "$_fgp_n" = "${#_fgp_text[@]}" ] || _fgp_rc=1
    _fgp_all="$_fgp_all
$_fgp_more"
  fi
  printf -v "$_fgp_var" '%s' "$_fgp_all"
  return "$_fgp_rc"
}

# Whether one side of a pair is text by the rule git applies when no attribute
# speaks: at most 512 MiB, and no NUL in its first 8000 bytes. A zero sha is the
# file in the working tree, which git did not hash. There, a link is its
# target's name, and anything else that is not a regular file counts as text,
# to be read again unopened: a pipe would block here, and its diff fails, as an
# unreadable path must. A side whose check cannot run also counts as text, and
# a read again that then fails fails the whole.
_felix_side_text() {   # TOP SHA PATH
  local s n
  if [ -z "${2//0/}" ]; then
    { [ -L "$1/$3" ] || [ ! -f "$1/$3" ]; } && return 0
    s="$(wc -c < "$1/$3" 2>/dev/null)"
    n="$(head -c 8000 < "$1/$3" 2>/dev/null | LC_ALL=C tr -cd '\000' | wc -c)"
  else
    s="$(git -C "$1" cat-file -s "$2" 2>/dev/null)"
    n="$(git -C "$1" cat-file blob "$2" 2>/dev/null | head -c 8000 | LC_ALL=C tr -cd '\000' | wc -c)"
  fi
  s="${s//[!0123456789]/}"; n="${n//[!0123456789]/}"
  [ "${s:-0}" -le 536870912 ] && [ "${n:-0}" -eq 0 ]
}

# git's own first complaint about reading this change, one line with no tab, for
# every sentence that says it could not be read (2026-10-08). The causes differ,
# and so do their remedies: a tracked path git cannot hash, an index it cannot
# read, or a branch with no merge base with the base. The first wording blamed a
# path for all three. Asked again with stderr kept, because the readers above
# keep stdout only, and only by a caller already holding a failed read.
felix_change_why() {   # root [base]
  local root="$1" base="${2:-}" why
  why="$( {
      if [ -n "$base" ] && git -C "$root" rev-parse -q --verify HEAD >/dev/null 2>&1; then
        git -C "$root" diff --no-ext-diff --no-textconv --stat "$base...HEAD" --
      fi
      git -C "$root" diff --no-ext-diff --no-textconv --stat --cached
      git -C "$root" diff --no-ext-diff --no-textconv --stat
    } 2>&1 >/dev/null | LC_ALL=C awk '!p && /^(error|fatal): / { gsub(/\t/, " "); print; p = 1 }')"
  printf '%s\n' "${why:-git gave no reason when asked again}"
}

# Every line this branch ADDS, including staged and unstaged ones.
#
# The companion to felix_changed_paths, and the half that was missed when that landed: knowing a
# path changed is not knowing what the change says. A content rule reading only `base...HEAD`
# names a staged file and then inspects the version without the staged content in it.
#
# Exits 1 when any of its diffs did not finish (2026-10-08), whatever lines it printed. A
# tracked named pipe ends `git diff` at that path, so with a pipe at A.txt every line added to
# src.txt was dropped and this printed nothing at all: escape.sh and classify.sh then scanned an
# empty change and found it clean. It used to exit with grep's status, 1 for a change that added
# no line, and no caller read that; it exits 0 for a change it read to the end, lines or none.
#
# Each source through _felix_git_patch (2026-10-08), so what the change adds is
# read whatever a driver, a textconv or a binary marking would have git print.
felix_added_lines() {
  local root="$1" base="${2:-}" refs out all="" rc=0
  if [ -n "$base" ] && git -C "$root" rev-parse -q --verify HEAD >/dev/null 2>&1; then
    # The same correction as felix_changed_paths, and for the same reason: a
    # content rule reading three-dot on a stacked branch scans lines the base
    # already merged, so a credential the branch below it added is reported
    # against this one.
    if refs="$(_felix_merge_refs "$root" "$base")"; then
      # shellcheck disable=SC2086
      _felix_git_patch out "$root" $refs || rc=1
    else
      _felix_git_patch out "$root" "$base...HEAD" || rc=1
    fi
    all="$out"
  fi
  _felix_git_patch out "$root" --cached || rc=1
  all="$all
$out"
  _felix_git_patch out "$root" || rc=1
  all="$all
$out"
  printf '%s\n' "$all" | LC_ALL=C grep '^+' | LC_ALL=C grep -v '^+++'
  return "$rc"
}

# A file as it will be committed, not as it was last committed.
#
# The worktree copy when there is one, because that is what `git add -A` is
# about to record; `git show <ref>:` only afterwards. Erring toward the worktree
# errs toward seeing more, which is the safe direction for a check that decides
# whether something stops.
felix_file_at() {
  local root="$1" ref="$2" path="$3"
  if [ "$ref" = "HEAD" ] && [ -f "$root/$path" ]; then
    cat "$root/$path" 2>/dev/null
  else
    git -C "$root" show "$ref:$path" 2>/dev/null
  fi
}

# Whether two paths are checkouts of one repository, worktrees included. A worktree and its main
# checkout share one `--git-common-dir`; it is resolved to an absolute path first, because git
# answers `.git` from inside the main checkout and a full path from inside a worktree, and
# comparing those two strings says "different" about the same repository.
#
# Written because two guards asked "is this Felix's own storage" with a path prefix, `case
# "$root/$f" in "$FELIX_HOME_DIR"/projects/*)`, which is true only when you are standing in the
# home itself. From a worktree the prefix never matches and the guard silently does nothing. One
# of the two only reports; the other deletes. How many lines match, as one number.
#
# `grep -c` prints the count and *also* exits 1 when it is zero, so the obvious `$(grep -c … ||
# echo 0)` appends a second zero and yields "0\n0". Every arithmetic test on that errors into
# the wrong branch, and written to a file it becomes a stray line later readers count as data:
# this project's own ledger held 215 of them in 280 lines, and `felix ledger` reported seven
# sessions where there were three. Exit 2 (no such file) is the only case that prints nothing,
# so it is the only one that needs a fallback. Recorded in lessons.md before this existed, which
# is why the fix is one function rather than eight repaired call sites.
felix_count() {
  local n
  n="$(grep -c "$@" 2>/dev/null)" || true
  case "$n" in ''|*[!0123456789]*) printf '0' ;; *) printf '%s' "$n" ;; esac
}

# Whether a file's last line is ended, so that the next
# `printf '...\n' >> file` lands as a row of its own.
#
# 2026-10-01: felix adopt appended `obs` to a hand-written capabilities file holding `api` with
# no final newline, and wrote `apiobs`, one row that was neither. felix_declared then listed
# `apiobs`, so both capabilities were lost, while the stack and setup rows for `obs` were still
# appended. Any file the engine appends to that something else also writes - a table a person
# may edit, a log a routine curates, a project gate's own output - can end that way, so the
# engine ends it before it appends, and a table row that cannot be put on a line of its own is
# not appended.
#
# 0: absent, empty, or ending in a newline. 1: a last line with no newline. 2: not a regular
# file, or its last byte cannot be read. Something at the path that is not a regular file is
# never opened: a FIFO would block the append that follows, a directory would fail it after the
# caller had counted it, and a dangling link would create its target.
#
# The last byte is read as a number, as lib/table.sh reads it. A command
# substitution drops a NUL the same way it drops a newline, so the obvious
# `[ -n "$(tail -c 1 f)" ]` reads a NUL-ended file as ended and glues the row.
felix_line_ended() {
  local f="$1" last
  if [ -e "$f" ] || [ -L "$f" ]; then [ -f "$f" ] || return 2; fi
  [ -s "$f" ] || return 0
  last="$( { tail -c 1 < "$f" | od -An -tx1 | tr -d ' \n'; } 2>/dev/null )"
  [ "$last" = "0a" ] && return 0
  [ -n "$last" ] || return 2
  return 1
}

# Ends the file's last line if it has none. Returns 1 when the file is not one
# a row can be appended to whole: not a regular file, a last byte that cannot
# be read, or a newline that cannot be written. The caller must then not
# append, and must not count or report the row as written.
felix_end_line() {
  felix_line_ended "$1"
  case $? in
    0) return 0 ;;
    1) { printf '\n' >> "$1"; } 2>/dev/null ;;
    *) return 1 ;;
  esac
}

felix_same_repo() {
  local a="$1" b="$2" ga gb
  [ -n "$a" ] && [ -n "$b" ] || return 1
  ga="$(git -C "$a" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  gb="$(git -C "$b" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  [ -n "$ga" ] && [ "$ga" = "$gb" ]
}

# Whether the repository under judgement is the one that ships this engine.
#
# Only that repository has the circularity worth breaking. A governed product's rules live in
# the Felix home and are not in its diff at all — #42 established that — so its branch cannot
# rewrite what judges it, and demanding a pinned engine there would be a fix for Felix and a
# regression for everything Felix governs: no plugin on a CI runner, none on a fresh clone, and
# merge refusing in both.
felix_self_governed() {
  local root="${1:-}"
  [ -n "$root" ] && [ -f "$root/engine/.claude-plugin/plugin.json" ] || return 1
  git -C "$root" ls-files --error-unmatch engine/.claude-plugin/plugin.json >/dev/null 2>&1
}

# The same question asked of the base (trust-plane step 3, spec S4). felix merge asks both: the tree
# alone let a branch that deletes the manifest stop being the engine's own repository, and so be
# judged by the felix it carries rather than by the engine main declares.
felix_self_governed_at() {   # ROOT REF
  local root="${1:-}" ref="${2:-}"
  [ -n "$root" ] && [ -n "$ref" ] || return 1
  [ "$(git -C "$root" cat-file -t "$ref:engine/.claude-plugin/plugin.json" 2>/dev/null </dev/null)" = blob ]
}

# The version a manifest declares, at a ref or in the working tree.
_felix_plugin_version() {
  local root="$1" ref="${2:-}"
  { if [ -n "$ref" ]; then git -C "$root" show "$ref:engine/.claude-plugin/plugin.json" 2>/dev/null
    else cat "$root/engine/.claude-plugin/plugin.json" 2>/dev/null; fi
  } | LC_ALL=C sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
}

# The engine that judges, which must not be the engine being judged.
#
# The first version took the newest entry in the plugin cache and was vacuous: the gate's
# `installed` check will not go green until that entry matches the tree byte for byte, and merge
# will not run without a green receipt, so the newest entry is always the candidate by the time
# it matters. docs/2026-08-14-earned-autonomy-decision.md §4a had already said base-version
# evaluation could not be reached without settling the install-before-green cycle — "one problem
# seen from two sides".
#
# The judge is the version `main` declares. The cache keeps every version ever installed, and
# `felix install` refuses a changed engine at an unchanged version, so a branch that touches the
# engine has bumped past main and main's entry is both present and not the candidate's. The
# deadlock is side-stepped: `installed` compares the tree against the newest entry while this
# reads an older one, and both hold at once.
#
# One limit, because a root of trust that overclaims is worse than none: this is
# not a signature. The trust is that the cache entry for main's version is what
# main contained when somebody installed it, and felix merge no longer takes that
# on trust: it asks felix_accepted_deploy_diff whether the entry is byte-identical
# to main's engine at the base ref before letting it judge.
#
# FELIX_KERNEL, which once named a judge outright, is gone (#260): the suite never used it, and
# it let anything that can set the environment choose its own judge, which is every escape
# channel evadable in one variable. The cache location stays composable (FELIX_KERNEL_CACHE,
# FELIX_PLUGIN_CACHE, CLAUDE_CONFIG_DIR), and the byte comparison at the boundary makes that
# safe: a cache the session doctored does not match main's engine and is refused as the judge.
felix_kernel_dir() {
  local root="${1:-}" base="${2:-main}" ver p ref
  [ -n "$root" ] || return 1
  # The branch being merged into, not the literal word "main". Hard-coding it
  # made this depend on `init.defaultBranch`, which is a property of whoever ran
  # it — green on a laptop that says main and red on a runner that says master.
  # Resolved by felix_base_ref and not by a loop of its own: a loop over the
  # short names `origin/$base` and `$base` is read by git in the order that
  # lets a tag or a local branch called origin/main stand in for the remote's,
  # and the version read here names the judge.
  ref="$(felix_base_ref "$root" "$base")" || return 1
  ver="$(_felix_plugin_version "$root" "$ref")"
  [ -n "$ver" ] || return 1
  # FELIX_KERNEL_CACHE, not FELIX_PLUGIN_CACHE. toolbox.sh already owns that
  # name and means something else by it — the plugins cache ROOT, one level up
  # from felix's own versions — and the CLI sources toolbox.sh, so reading it
  # here resolved .../plugins/cache/<version>/harness and found nothing. The
  # suite never saw it because every test set the variable explicitly, which
  # masks a collision instead of exposing one. Composed with it rather than
  # around it, so a machine that moves the plugins cache moves this too.
  p="${FELIX_KERNEL_CACHE:-${FELIX_PLUGIN_CACHE:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/cache}/felix/felix}/$ver/harness"
  [ -d "$p" ] || return 1
  printf '%s' "$p"
}

# Where the felix marketplace serves its engine from, or empty when it is not
# registered. Reads the registry rather than assuming, because the answer is the
# difference between a deploy and a no-op that reports success.
felix_marketplace_root() {
  local reg="${1:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/known_marketplaces.json}"
  [ -f "$reg" ] || return 0
  # sed -n 1p, not head -1: head stops reading after one line, and a sed still
  # writing would die of SIGPIPE, which pipefail hands a caller that tests the
  # status as no marketplace.
  sed -n '/"felix"[[:space:]]*:[[:space:]]*{/,/^  }/p' "$reg" 2>/dev/null \
    | sed -n 's/.*"installLocation"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | sed -n 1p
}

# Whether this engine is one Claude Code could ever install from.
#
# `felix install` in a worktree bumps the manifest, runs the three plugin commands, finds the
# cache unchanged and reports "this is no longer the version cache; something else is wrong" —
# which sends you looking for corruption. The registry is a directory marketplace pinned to one
# path, so a worktree's engine is not the engine being served and never was. Nothing is broken;
# the deploy went to the tree the marketplace names, which is main.
#
# It is not a refusal. The bump still belongs on the branch, because merging is what makes it
# deployable, and a branch that never bumped deploys nothing when it lands. Only the diagnosis
# changes. Tested on the engine's own parent, not on a path prefix. A worktree lives under
# `.claude/worktrees/` *inside* the main checkout, so "starts with the marketplace root" is true
# of every worktree there is and the check would have passed exactly where it needed to fail.
#
# The comparison is between two DIRECTORIES and not between two strings. The registry holds
# whatever path was typed at registration and this side derives one from `pwd`, so a symlinked
# home, or /var against /private/var on macOS, made the served checkout read as one the
# marketplace does not serve — and on the obligation that rests on this, "not served" is
# DORMANT, which is the permissive direction. `-ef` asks the filesystem the question the string
# was standing in for; the string compare stays as the answer for a path that no longer exists,
# where `-ef` cannot answer at all.
felix_deployable_from() {
  local engine_root="$1" mroot parent
  mroot="$(felix_marketplace_root "${2:-}")"
  [ -n "$mroot" ] || return 0
  parent="${engine_root%/*}"
  [ "$parent" = "$mroot" ] && return 0
  if [ -d "$parent" ] && [ -d "$mroot" ] && [ "$parent" -ef "$mroot" ]; then
    return 0
  fi
  printf '%s' "$mroot"
  return 1
}

# Raise the patch digit in a plugin manifest, and print the new version.
#
# Claude Code caches a plugin by version, so a changed engine at an unchanged version never
# deploys and still reports success. `felix install` detected that exact condition and printed
# "bump the version, then re-run this" — a command suggesting something it could safely have
# done, which the charter names as a defect. The gate caught `installed` nine times before
# anybody counted, every one of them a person typing the digit the command was withholding.
#
# Bumping is not the risky half. install is already the thing that replaces the deployed engine;
# refusing to change a number while doing that is caution in the wrong place.
#
# Refuses rather than guesses when the version is not three numbers. A manifest
# it cannot parse is one it must not rewrite.
felix_version_bump() {
  local manifest="$1" cur major minor patch next tmp
  [ -f "$manifest" ] || return 1
  cur="$(LC_ALL=C sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | head -1)"
  case "$cur" in
    [0123456789]*.[0123456789]*.[0123456789]*) ;;
    *) return 1 ;;
  esac
  major="${cur%%.*}"; minor="${cur#*.}"; minor="${minor%%.*}"; patch="${cur##*.}"
  case "$major$minor$patch" in *[!0123456789]*) return 1 ;; esac
  next="${major}.${minor}.$((patch + 1))"
  # Through a temp file, so a failed write cannot leave empty the one manifest
  # whose corruption stops everything deploying.
  # A template under $TMPDIR: a bare mktemp on macOS ignores TMPDIR, and the
  # suite points TMPDIR at a fixture to count what is left there.
  local tmpd="${TMPDIR:-/tmp}"
  tmp="$(mktemp "${tmpd%/}/felix-bump.XXXXXX")" || return 1
  LC_ALL=C sed 's/\("version"[[:space:]]*:[[:space:]]*"\)[^"]*\("\)/\1'"${next}"'\2/' \
      "$manifest" > "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
  [ -s "$tmp" ] || { rm -f "$tmp"; return 1; }
  mv -f "$tmp" "$manifest" 2>/dev/null || { rm -f "$tmp"; return 1; }
  printf '%s' "$next"
}

# The deployed surface is three directories, and comparing one of them certified deployments
# that never happened (#82). The cache serves harness/, hooks/ and commands/; hooks.json is the
# file that decides which hooks BIND, so a deploy that copied harness/ and dropped hooks/ reads
# as `installed ok` while every session runs yesterday's bindings — a hook binary deployed
# perfectly and running nowhere. engine/.claude-plugin is deliberately not compared: plugin.json
# differs whenever a bump is pending, which is this tree's normal state, and the cache does not
# carry that directory anyway.
#
# A directory absent from BOTH sides is skipped — nothing was deployed and nothing was expected,
# which is a fixture, not a drift. Absent from one side is a drift: diff itself fails on the
# missing operand, which is the honest verdict rather than a special case.
#
# The merge-time self-judgement guard is deliberately NOT this function. It compares harness/
# alone, on purpose — it asks whether the judging LIBRARIES are the accepted ones, not whether
# the deployment is complete — and widening it would let a hooks-only difference block a merge
# that hooks cannot affect. The comparison itself, which both forms below share. It walks the
# three directories and prints each line of diff that the callback does not call residue, and
# returns 1 when it printed any. What residue IS belongs to the callback, which is called as `CB
# ARG1 ARG2 KIND P FULL` and answers 0 for residue:
#   KIND  differ: both sides hold the path and differ; src or live: only that
#         side holds it
#   P     the path from the engine directory, harness/lib/x.sh
#   FULL  that path on disk, on the side that holds it, so the callback can tell
#         a directory from a file
#
# A directory on one side only is reported file by file, in the shape diff itself uses for a
# lone entry, so the report names what was missed rather than the operand diff could not open —
# and so each file passes the residue rule on its own. Lines diff emits about a missing operand,
# or in any shape that is not a path, match no path and always survive, which keeps "absent from
# one side is the verdict". The callback is asked from inside the loop that reads diff's lines
# on stdin, so every command it runs reads /dev/null.
_felix_deploy_walk() {
  local src="$1" live="$2" cb="$3" a1="$4" a2="$5" d rc=0 line rest dir name p only kind full
  for d in harness hooks commands; do
    [ -e "$src/$d" ] || [ -e "$live/$d" ] || continue
    only=""
    if [ -e "$src/$d" ] && [ ! -e "$live/$d" ]; then
      only="$(cd "$src" && find "$d" -type f 2>/dev/null | LC_ALL=C sort | sed "s|^|Only in $src: |")"
    elif [ ! -e "$src/$d" ] && [ -e "$live/$d" ]; then
      only="$(cd "$live" && find "$d" -type f 2>/dev/null | LC_ALL=C sort | sed "s|^|Only in $live: |")"
    fi
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      p=""; kind=""; full=""
      case "$line" in
        "Files $src/"*)
          # The filename itself may contain " and ", so the separator matched
          # is the whole " and $live/…" tail, never the first " and ". A
          # truncated path handed to check-ignore is answered about a
          # DIFFERENT file, and an ignore rule matching the fragment
          # certified a real content drift as clean — found in review, by
          # construction, before it shipped.
          p="${line#Files "$src/"}"; p="${p% differ}"; p="${p% and "$live"/*}"
          kind=differ; full="$live/$p" ;;
        "Only in $src: "*|"Only in $src/"*)
          # The slash and colon are the path boundary: without them, a live
          # directory whose absolute path merely begins with the src string
          # was parsed as src-relative, against the wrong root.
          rest="${line#Only in }"; dir="${rest%%: *}"; name="${rest#*: }"
          if [ "$dir" = "$src" ]; then p="$name"; else p="${dir#"$src/"}/$name"; fi
          kind=src; full="$src/$p" ;;
        "Only in $live: "*|"Only in $live/"*)
          rest="${line#Only in }"; dir="${rest%%: *}"; name="${rest#*: }"
          if [ "$dir" = "$live" ]; then p="$name"; else p="${dir#"$live/"}/$name"; fi
          kind=live; full="$live/$p" ;;
      esac
      if [ -n "$p" ] && "$cb" "$a1" "$a2" "$kind" "$p" "$full"; then
        continue
      fi
      printf '%s\n' "$line"
      rc=1
    done <<WALK_LINES
$(if [ -n "$only" ]; then printf '%s\n' "$only"; else diff -rq "$src/$d" "$live/$d" 2>&1; fi)
WALK_LINES
  done
  return "$rc"
}

# Git, run so that nothing of this machine enters its answer: no global or
# system config, no global excludes file, none of the environment that points
# git at another repository, and stdin from /dev/null unless _FELIX_GIT_IN names
# a file. A verifier whose verdict varies with one machine's personal ignore
# rules is not a verifier. REPO is where it runs, or _FELIX_GIT_AT when that is
# set; core.ignoreCase is pinned because git sets it by probing the filesystem,
# and a rule that matches on one machine and not on the next is the same defect.
_felix_git_rules() {   # REPO git-args...
  local r="$1"; shift
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_COMMON_DIR \
      -u GIT_CONFIG_PARAMETERS -u GIT_CONFIG_COUNT \
      HOME="$r" XDG_CONFIG_HOME="$r" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
      git -C "${_FELIX_GIT_AT:-$r}" -c core.excludesFile=/dev/null -c core.ignoreCase=false "$@" <"${_FELIX_GIT_IN:-/dev/null}"
}

# A scratch repository at DIR that holds every .gitignore the commit SHA holds — the root's,
# engine/'s and any nested below — and nothing else, and tracks none of it. It exists so that
# "does a rule main committed match this path" is answered by git itself, applying the rules as
# git applies them (directory-only patterns, negations, nested files), from main's blobs and
# from nothing in the checkout. It is made with no template, so it carries no info/exclude. A
# symlink, or a path git would have to quote, is not materialised: fewer rules can only leave
# more paths standing as drift.
_felix_rules_repo() {   # ROOT SHA DIR
  local root="$1" sha="$2" dir="$3" line meta path mode rest type obj
  mkdir -p "$dir" || return 1
  _felix_git_rules "$dir" init -q --template= >/dev/null 2>&1 || return 1
  git -C "$root" -c core.quotepath=false ls-tree -r "$sha" -- .gitignore engine \
    > "$dir.lst" 2>/dev/null </dev/null || return 1
  while IFS= read -r line; do
    meta="${line%%$'\t'*}"; path="${line#*$'\t'}"
    mode="${meta%% *}"; rest="${meta#* }"; type="${rest%% *}"; obj="${rest#* }"
    case "$mode:$type" in 100644:blob|100755:blob) ;; *) continue ;; esac
    case "$path" in .gitignore|*/.gitignore) ;; *) continue ;; esac
    case "/$path/" in */.git/*|*/../*|*/./*) continue ;; esac
    case "$path" in */*) mkdir -p "$dir/${path%/*}" || return 1 ;; esac
    git -C "$root" cat-file blob "$obj" > "$dir/$path" 2>/dev/null </dev/null || return 1
  done < "$dir.lst"
  rm -f "$dir.lst"
}

# Residue for the working-tree form: a path the repository itself declares non-content is
# residue, not drift (#86). A claude-flow hook dropped 4KB of state under tests/ while the suite
# ran there, and this comparison called a byte-identical deploy a drift — in a worktree the gate
# then misdiagnosed that as "structural: cannot deploy". The rule is the repository's own ignore
# rules, asked per surviving line via git check-ignore, on both sides: a stray in the cache is a
# deployed stray, same non-content. Untracked-but-not-ignored still counts — that is undeployed
# work, and quieting it would be loosening the check.
#
# A path the repository TRACKS is never residue (#360). check-ignore alone never reports a
# tracked path, but the second query below asks about the path with a trailing slash, which is
# in no index, so git matched a tracked FILE against the patterns as if it were an untracked
# directory: a file main ships, named by a force-added *.log, had its drift discarded. Tracked
# paths are therefore answered first and never reach the ignore queries. Paths are matched
# literally, so a name holding glob characters is asked about itself and not about the tracked
# files the pattern would match.
#
# For an untracked path the ignore queries are the #86 ones. Asked twice because a
# directory-only pattern matches only what git can see is a directory, and a cache-side stray
# does not exist in the tree at all; the trailing slash supplies what the filesystem cannot. The
# global excludes file is shut off. What cannot be shut off is .git/info/exclude — inside the
# repository's own .git, a rule there is this machine's deliberate act, and it is named here so
# nobody discovers it as a surprise. This is why the working-tree form is not the judge's: the
# accepted form reads main's committed rules and nothing local.
_felix_residue_tree() {   # IGROOT PREFIX KIND P FULL
  local r="$1" q="$2$4" hit
  hit="$(git -C "$r" --literal-pathspecs ls-files -- "$q" 2>/dev/null </dev/null)" || return 1
  [ -z "$hit" ] || return 1
  { git -C "$r" -c core.excludesFile=/dev/null check-ignore -q -- "$q" </dev/null \
    || git -C "$r" -c core.excludesFile=/dev/null check-ignore -q -- "$q/" </dev/null; } 2>/dev/null
}

# Is the deployed copy of a tree the tree? SRC and LIVE are two engine directories, compared
# over the three deployed ones, residue excepted; exit 1 and every differing line when they
# differ. This is the WORKING-TREE form, read by `felix install`'s verify and by `felix next`,
# where SRC is a checkout's own engine/ and what the checkout tracks and ignores is the
# repository's say about what is content (_felix_residue_tree). The judge's question, about
# main's engine, is felix_accepted_deploy_diff and does not come through the checkout.
#
# A third argument names the repository the rules and the index are read from;
# it defaults to the source side, which is how every caller but the tests uses
# it. When SRC is a directory inside it the paths are asked from its root.
felix_deploy_diff() {
  local src="$1" live="$2" igroot="${3:-$1}" sp ip pre=""
  sp="$(cd -P "$src" >/dev/null 2>&1 && pwd -P)"; ip="$(cd -P "$igroot" >/dev/null 2>&1 && pwd -P)"
  if [ -n "$sp" ] && [ -n "$ip" ]; then
    case "$sp" in "$ip"/*) pre="${sp#"$ip"/}/" ;; esac
  fi
  _felix_deploy_walk "$src" "$live" _felix_residue_tree "$igroot" "$pre"
}

# A path as one line: a backslash, a newline and a tab are written \\, \n and \t,
# so a name cannot be read as two paths or as two fields. Sets _FELIX_ESC.
_felix_esc() {
  local s="$1"
  s="${s//\\/\\\\}"; s="${s//$'\n'/\\n}"; s="${s//$'\t'/\\t}"
  _FELIX_ESC="$s"
}

# What main stores, from the commit and from nothing converted: one line a path,
# `path TAB mode TAB blob`, the path from engine/ and escaped. git ls-tree reads
# the tree object, so no filter, eol, export-ignore or ident setting of the home
# (in .git/info/attributes, core.attributesFile, the config or a working-tree
# .gitattributes) can touch it, which git archive did not promise.
_felix_main_list() {   # ROOT SHA OUT
  local rec meta path mode rest
  git -C "$1" ls-tree -r -z --full-tree "$2" -- engine/ > "$3.raw" 2>/dev/null </dev/null || return 1
  : > "$3"
  while IFS= read -r -d '' rec; do
    meta="${rec%%$'\t'*}"; path="${rec#*$'\t'}"
    mode="${meta%% *}"; rest="${meta#* }"
    _felix_esc "${path#engine/}"
    printf '%s\t%s\t%s\n' "$_FELIX_ESC" "$mode" "${rest#* }" >> "$3"
  done < "$3.raw"
  rm -f "$3.raw"
}

# What the entry holds, by what it is and by its bytes as they lie on disk: one
# line a path, `path TAB type TAB - TAB blob`, type d, f, l or o (a FIFO, a
# socket, a device). A regular file's blob is git hash-object --no-filters, run
# against the scratch repository R under no machine-local config, so the entry
# is hashed raw and the way main's blobs are stored. A path git would read as
# quoted or as two lines is hashed on its own. OUT.x lists the regular files that
# have their owner execute bit, one escaped path a line.
_felix_entry_list() {   # ENTRY SCRATCH OUT
  local entry="$1" r="$2" out="$3" f p t h
  : > "$out.safe"; : > "$out.x"; : > "$out"; : > "$out.fx"
  ( cd "$entry" && find . -mindepth 1 -type f -perm -100 -print0 2>/dev/null ) > "$out.xraw" || return 1
  while IFS= read -r -d '' f; do _felix_esc "${f#./}"; printf '%s\n' "$_FELIX_ESC" >> "$out.x"; done < "$out.xraw"
  ( cd "$entry" && find . -mindepth 1 -print0 2>/dev/null ) > "$out.raw" || return 1
  while IFS= read -r -d '' f; do
    p="${f#./}"
    if [ -L "$entry/$p" ]; then t=l
    elif [ -d "$entry/$p" ]; then t=d
    elif [ -f "$entry/$p" ]; then t=f
    else t=o; fi
    _felix_esc "$p"
    if [ "$t" != f ]; then printf '%s\t%s\t-\t-\n' "$_FELIX_ESC" "$t" >> "$out"; continue; fi
    case "$p" in
      *$'\n'*|\"*) h="$(_FELIX_GIT_AT="$entry" _felix_git_rules "$r" --git-dir="$r/.git" hash-object --no-filters -- "$p" 2>/dev/null)" || h="-"
                   printf '%s\tf\t-\t%s\n' "$_FELIX_ESC" "${h:--}" >> "$out" ;;
      *) printf '%s\n' "$p" >> "$out.safe"; printf '%s\tf\t-\n' "$_FELIX_ESC" >> "$out.fx" ;;
    esac
  done < "$out.raw"
  if [ -s "$out.safe" ]; then
    _FELIX_GIT_AT="$entry" _FELIX_GIT_IN="$out.safe" _felix_git_rules "$r" --git-dir="$r/.git" \
        hash-object --no-filters --stdin-paths > "$out.h" 2>/dev/null || return 1
    [ "$(wc -l < "$out.h" | tr -d ' ')" = "$(wc -l < "$out.safe" | tr -d ' ')" ] || return 1
    paste "$out.fx" "$out.h" >> "$out"
  fi
  rm -f "$out.raw" "$out.xraw" "$out.safe" "$out.fx" "$out.h"
}

# Residue for the accepted form, which is the narrowest there is. Only a path the cache entry
# alone holds can be residue, only beneath harness/ or hooks/, and only when a rule main
# COMMITTED matches it. A path main ships is content whatever any rule says (a file main
# force-added under *.log is main's), and so is a path the entry lacks. Any other top-level name
# is drift, and so is anything under commands/ or .claude-plugin/: a Markdown file under
# commands/ is a slash command, so an extra file is behaviour however an ignore rule reads it. A
# path with a character that makes it ambiguous (a backslash, which stands for a newline, a tab
# or a backslash itself, a quote, ` and `, `: `, a leading dash, a glob character, a trailing
# space) is never residue either: a rule is not trusted to mean the path it was matched against.
#
# The rules are asked with a path from the engine's parent, as the repository holds it. A
# directory is asked with a trailing slash, because git matches a directory-only pattern
# (`.claude-flow/`, the incident's own rule) only against what it knows is a directory, and the
# entry's stray exists in no tree git can look at. Measured (git 2.54): in a repository whose
# files do not exist, check-ignore on `d/.claude-flow/x.json` answers ignored, since git takes
# every leading component for a directory, and on `d/.claude-flow` answers not ignored, so only
# the final component needs the slash. It is added by what the entry actually holds there, not
# unconditionally: a FILE called data is not matched by `data/` and so is not residue.
_felix_residue_c() {   # SCRATCH PATH TYPE
  local q="engine/$2"
  case "$2" in harness/*|hooks/*) ;; *) return 1 ;; esac
  case "$2" in
    *\\*|*\"*|*" and "*|*": "*|*"/-"*|*" /"*|*" "|*[\*\?\[]*) return 1 ;;
  esac
  [ "$3" = d ] && q="$q/"
  _felix_git_rules "$1" check-ignore -q -- "$q"
}

# The two lists compared, as lines `path TAB code [TAB type]` on stdout:
#   D  both hold the path and it differs: the blob, the executable bit, or the
#      type (a directory against a file, a symlink or a special file against
#      anything main stores)
#   M  main stores a path the entry lacks
#   O  the entry alone holds it, at the top of what it alone holds
#   S  the entry alone holds a symlink or a special file, anywhere
# Directories are not content, so they are named only when they conflict or are
# the top of what only the entry holds.
_felix_compare_lists() {   # MAINLIST EXECLIST ENTRYLIST
  LC_ALL=C awk '
    function ls_(s,   i) { for (i = length(s); i > 0; i--) if (substr(s, i, 1) == "/") return i; return 0 }
    BEGIN { FS = "\t" }
    FILENAME == ARGV[1] {
      mm[$1] = $2; mb[$1] = $3; p = $1
      while ((i = ls_(p)) > 0) { p = substr(p, 1, i - 1); md[p] = 1 }
      next }
    FILENAME == ARGV[2] { xs[$1] = 1; next }
    {
      ep = $1; et = $2; eb = $4; seen[ep] = 1; ex = (ep in xs)
      i = ls_(ep); par = (i > 0) ? substr(ep, 1, i - 1) : ""
      top = (par == "" || (par in md))
      if (et == "l" || et == "o") {
        if ((ep in mm) || (ep in md)) print ep "\tD"; else print ep "\tS\t" et
        next }
      if (et == "d") {
        if (ep in mm) print ep "\tD"
        else if (!(ep in md) && top) print ep "\tO\td"
        next }
      if (ep in md) { print ep "\tD"; next }
      if (ep in mm) {
        m = mm[ep]
        if ((m != "100644" && m != "100755") || mb[ep] != eb || ((m == "100755") != ex)) print ep "\tD"
        next }
      if (top) print ep "\tO\tf"
    }
    END { for (p in mm) if (!(p in seen)) print p "\tM" }
  ' "$1" "$2" "$3" | LC_ALL=C sort
}

# The lines of the verdict, in diff's own shapes, for the compared lists; 1 when
# there is any. LABEL names main's commit where diff would have named the
# temporary directory main used to be extracted to.
_felix_accepted_report() {   # SCRATCH ENTRY LABEL COMPARED
  local r="$1" entry="$2" label="$3" p code t dir name rc=0
  while IFS=$'\t' read -r p code t; do
    [ -n "$p" ] || continue
    case "$p" in */*) dir="/${p%/*}"; name="${p##*/}" ;; *) dir=""; name="$p" ;; esac
    case "$code" in
      D) printf 'Files %s/%s and %s/%s differ\n' "$label" "$p" "$entry" "$p" ;;
      M) printf 'Only in %s%s: %s\n' "$label" "$dir" "$name" ;;
      O) if _felix_residue_c "$r" "$p" "$t"; then continue; fi
         printf 'Only in %s%s: %s\n' "$entry" "$dir" "$name" ;;
      S) printf 'Only in %s%s: %s\n' "$entry" "$dir" "$name" ;;
    esac
    rc=1
  done < "$4"
  return "$rc"
}

# Is the engine main accepted the one deployed? Both sides from the base
# (docs/2026-08-18-promotion-spec.md §4): the version main declares names the
# cache entry, and main's own engine — read from the commit, never from any
# working tree — is what that entry must hold. Every checkout can answer this,
# which is what lets `felix merge` run from a worktree (#2).
#
# The verdict depends on main's commit M, as felix_base_ref names it, and the cache entry E, and
# nothing else. M is resolved to a commit ONCE and the version, the tree and the ignore rules
# are all read from it, so a ref that moves mid-call cannot have one main's version judged
# against another main's files. The checkout this runs in does not enter: not its working tree,
# index, .git/info/exclude, config, attributes or checked-out branch, nor the machine's global
# excludes file.
#
# Main's side is not extracted: git archive applies the home's conversions to every file it
# writes (a smudge filter, eol, export-ignore, ident), so an entry holding what a filter wrote
# read as main's. It is the tree object itself, path, mode and blob id (git ls-tree), and the
# entry's side is its files as they lie on disk, hashed raw (git hash-object --no-filters). The
# comparison is by path over the WHOLE entry, `.claude-plugin/` included, and by type and mode:
# a different blob or executable bit, a symlink, FIFO or socket anywhere, or a file against a
# directory is drift. Which paths are residue is M's alone too: a stray only E holds beneath
# harness/ or hooks/ is residue when an ignore rule M itself committed matches it
# (_felix_residue_c), so an untracked .gitignore of `*` in the home cannot turn an extra file in
# E, or drift in a file M ships, into residue.
#
# A TERM or INT delivered to the call removes its temporary directory before the
# call ends, and the caller's own traps for them are put back when it returns.
#
#   exit 0  identical; prints the entry
#   exit 1  differs; every differing path on stdout, or one line naming the
#           version main declares and that nothing is installed at it
#   exit 2  cannot examine: no cache on this machine, no base ref, or a
#           version that cannot be read from the base
#
# deploy-check, the obligation ledger's evidence for the same fact, sources this from the tree
# beside it. The gate's `installed` check kept an inline copy until 2026-09-17, on the argument
# that a verifier which sources the code it judges can be switched off by editing that code; it
# now reads THIS FILE from the base ref with `git show` — never the working tree, never the
# cache entry — and calls this function in a subshell, so the code that judges is the code main
# accepted. The gate and the ledger cannot disagree by construction. FELIX_KERNEL, the suite's
# override of the judge, is not read: this asks about the real cache.
felix_accepted_deploy_diff() {
  local root="$1" base="${2:-main}" cache ref sha ver entry tmp rc told tint
  cache="${FELIX_KERNEL_CACHE:-${FELIX_PLUGIN_CACHE:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/cache}/felix/felix}"
  [ -d "$cache" ] || { printf 'cannot examine: no felix cache at %s\n' "$cache"; return 2; }
  ref="$(felix_base_ref "$root" "$base")" || { printf 'cannot examine: no %s or origin/%s in this repository\n' "$base" "$base"; return 2; }
  # The name stays for messages, which a person reads. Everything else is read
  # from the commit it names at this moment.
  sha="$(git -C "$root" rev-parse --verify --quiet "$ref^{commit}" 2>/dev/null </dev/null)"
  [ -n "$sha" ] || { printf 'cannot examine: %s names no commit\n' "$ref"; return 2; }
  ver="$(_felix_plugin_version "$root" "$sha")"
  [ -n "$ver" ] || { printf 'cannot examine: %s declares no engine version\n' "$ref"; return 2; }
  entry="$cache/$ver"
  if [ ! -d "$entry/harness" ]; then
    printf '%s declares %s and nothing is installed at that version\n' "$ref" "$ver"
    return 1
  fi
  local tmpd="${TMPDIR:-/tmp}"
  tmp="$(mktemp -d "${tmpd%/}/felix-deploy.XXXXXX" 2>/dev/null)" || { printf 'cannot examine: no temporary directory\n'; return 2; }
  _FELIX_DEPLOY_TMP="$tmp"
  told="$(trap -p TERM)"; tint="$(trap -p INT)"
  trap 'rm -rf "$_FELIX_DEPLOY_TMP"; exit 143' TERM
  trap 'rm -rf "$_FELIX_DEPLOY_TMP"; exit 130' INT
  _felix_accepted_body "$root" "$sha" "$ref" "$entry" "$tmp"; rc=$?
  rm -rf "$tmp"; _FELIX_DEPLOY_TMP=""
  trap - TERM INT
  [ -z "$told" ] || eval "$told"
  [ -z "$tint" ] || eval "$tint"
  [ "$rc" -eq 0 ] && printf '%s\n' "$entry"
  return "$rc"
}

# The work of felix_accepted_deploy_diff inside the temporary directory it made.
_felix_accepted_body() {   # ROOT SHA REF ENTRY TMP
  local root="$1" sha="$2" ref="$3" entry="$4" tmp="$5"
  _felix_rules_repo "$root" "$sha" "$tmp/rules" \
    || { printf 'cannot examine: could not read the ignore rules main committed at %s\n' "$ref"; return 2; }
  _felix_main_list "$root" "$sha" "$tmp/main.tsv" \
    || { printf 'cannot examine: could not read the engine tree at %s\n' "$ref"; return 2; }
  _felix_entry_list "$entry" "$tmp/rules" "$tmp/entry.tsv" \
    || { printf 'cannot examine: could not read the entry at %s\n' "$entry"; return 2; }
  _felix_compare_lists "$tmp/main.tsv" "$tmp/entry.tsv.x" "$tmp/entry.tsv" > "$tmp/compared.tsv"
  _felix_accepted_report "$tmp/rules" "$entry" "main@${sha:0:12}" "$tmp/compared.tsv"
}
