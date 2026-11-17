# felix situations, the checks every step shares (slice 1 of the capability lane; contracts C17.2, C17.4 and C17.5 of
# docs/2026-10-29-lane-slice-1-plan.md). Loaded by cmd_situations in felix, after lib/situations.sh. Definitions only.
#
# WHY IT EXISTS. A step that fails and is not looked at prints a report as if nothing had failed: a sort that dies reads as
# an empty section, an awk that cannot open its file reads as a table of no classes. C17.4 makes every step of a run
# checked, and a failure exits 3 with nothing on stdout and one line on stderr. The idiom the three siblings use is
#
#     some command > "$file" 2>/dev/null || _felix_situations_fail "what it was doing" || return 3
#
# _felix_situations_fail always returns 3, so the return after it always runs. A pipeline is not written: a producer's
# status is lost behind its last stage, so each stage writes a file in the scratch directory and is checked there.
#
#   _felix_situations_fail          the one sentence for a step of the report that failed (C17.4)
#   felix_situations_tables         a project table that exists and cannot be read (C17.4)
#   felix_situations_detect         the detector on one checkout, captured, sorted and checked (C17.4)
#   _felix_situations_in_rules      a command run in the environment that _felix_git_rules gives (C17.2)
#   _felix_situations_detect_quoted the detector in a scratch clone, with the caller's core.quotePath (C17.11.1)

# The sentence for a step of the report that failed, on stderr, and status 3. STEP is a few words naming what was being done,
# with no punctuation, since it stands before the word failed.
_felix_situations_fail() {   # STEP
  printf 'felix situations: the report could not be built: %s failed\n' "${1-}" >&2
  return 3
}

# The project tables a run reads that exist and cannot be read (C17.4): probes.tsv in every mode, and obligations.tsv
# with --propose. Prints the first one's sentence on stderr and returns 3, or returns 0. A table that is absent is not
# unreadable, and one that is no regular file is read by nobody. PROJ is the project's directory under the Felix home.
felix_situations_tables() {   # PROJ FORMAT
  local proj="${1-}" fmt="${2-}"
  if [ -f "$proj/probes.tsv" ] && [ ! -r "$proj/probes.tsv" ]; then
    printf "felix situations: the project's probes.tsv could not be read: %s is not readable\n" "$proj/probes.tsv" >&2
    return 3
  fi
  if [ "$fmt" = propose ] && [ -f "$proj/obligations.tsv" ] && [ ! -r "$proj/obligations.tsv" ]; then
    printf "felix situations: the project's obligations.tsv could not be read: %s is not readable\n" "$proj/obligations.tsv" >&2
    return 3
  fi
  return 0
}

# The detector run on checkout ROOT, with the capabilities it names, sorted and unique, left in the file OUT. Returns 0, or
# 1 when the capture or the sort failed. The detector reports no failure of its own: it ends on a chain of && echo, so its
# status is 0 or 1 whatever it found, and only a status past 1 (a missing command, a signal) counts here.
felix_situations_detect() {   # ROOT OUT
  local root="${1-}" out="${2-}" rc
  felix_detect "$root" > "$out.raw" 2>/dev/null
  rc=$?
  [ "$rc" -le 1 ] && [ -f "$out.raw" ] || return 1
  LC_ALL=C sort -u "$out.raw" > "$out" 2>/dev/null || return 1
  return 0
}

# COMMAND [ARG...] run in the environment _felix_git_rules gives git (C17.2): none of the environment that points git at
# another repository, no GIT_CONFIG_PARAMETERS or GIT_CONFIG_COUNT, no global or system configuration, and HOME and
# XDG_CONFIG_HOME naming the scratch directory SCRATCH. TMP is the TMPDIR it runs with. It runs in a subshell, so nothing it
# sets outlives it. The probes do not run here: they are the project's commands and keep the caller's environment.
_felix_situations_in_rules() {   # SCRATCH TMP COMMAND [ARG...]
  local scr="${1-}" tmp="${2-}"
  shift 2
  ( unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT
    export HOME="$scr" XDG_CONFIG_HOME="$scr" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 TMPDIR="$tmp"
    "$@" )
}

# The detector on the scratch clone ROOT, as felix_situations_detect runs it, given the caller's core.quotePath when
# QUOTEPATH is not empty (C17.11.1). The file names its listing prints are then quoted as on the live checkout, so a scratch
# side names what --at names for the same tree. Run it through _felix_situations_in_rules, whose subshell the setting stays
# in, after that has cleared the caller's GIT_CONFIG_COUNT. A quotePath setting runs nothing.
_felix_situations_detect_quoted() {   # QUOTEPATH ROOT OUT
  if [ -n "${1-}" ]; then
    export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.quotePath GIT_CONFIG_VALUE_0="$1"
  fi
  felix_situations_detect "${2-}" "${3-}"
}
