# The lane counter's fixtures (slice 0, docs/2026-10-29-capability-lane-first-slices-design.md section 6; the plan's
# Contracts C9 and C11), for the blind parts 2200 to 2250. Written blind on 2026-10-29 from the design and the
# Contracts alone, without reading lib/, hooks/, bin/ or felix.
#
# Functions only (part 0006): nothing runs and nothing is assigned when this file is sourced. Each builder takes the
# directory to build in, under $TMP, and sets its LF_* variables when it is called; a builder that fails leaves its
# result variable empty and returns 1, so a part that checks what it built sees the failure there. Every git command a
# builder runs stands behind _fx_cd (part 0002), in a subshell, and runs with no global or system configuration, a
# fixed identity and a pinned author and committer time, as "<epoch> +0000" (C9).
#
# The two layouts of C9: a home apart (_lf_home, then _lf_checkout for a checkout bound by an untracked .felix), and
# one self-governed repository (_lf_self). Tables are committed in the home with _lf_table, broken ones included:
# its bytes are written as given, a CR or a missing last newline kept. Landings are made with _lf_commit (a message
# kept byte for byte, with --cleanup=verbatim, and the paths it changes), _lf_squash (felix merge's or GitHub's
# default squash message, C3), _lf_merge (a real merge commit) and _lf_chain (a run of marked and unmarked landings),
# and refs/remotes/origin/main is published with _lf_publish. The surfaces run through _lf_run and _lf_start in the
# environment _lf_use names, with the stubs of _lf_stubs first on PATH. A session-start fixture that expects the lane
# paragraph or token makes its checkout the project's own (C7, C9) with _lf_own, or with _lf_match and _lf_origin apart.
#
# For the parts of status, session start and the pulse (2230 to 2250): felix status --tsv is _lf_run OUT DIR NOW
# "$FELIX" status --tsv, and _lf_last OUT.out its last row; felix pulse is _lf_run in the home of an _lf_self layout,
# with a memory root outside it (C2, C9). _lf_start runs the hook, waits for the discovery lock and reads the JSON with
# python3 (check for python3 first, and skip with a reason); _lf_silent says whether a lane paragraph or token showed;
# _lf_start with a fifth argument runs another engine root, such as the copy _lf_broken makes. NOW - leaves
# FELIX_LANE_NOW unset; any other NOW, 0123 included, is passed as it is.
#
# The reviews' probes and fixtures (2026-10-30, below) were moved whole into two files beside this one on 2026-10-30, so
# that every file of the library stays under 500 lines (the third review's round 3, V3R3-F2); no function's text changed.
# lane-probes.sh holds C9's faults and the probes the reviews ran (_lf_fault, _lf_fork, _lf_kill, _lf_gone, _lf_probe,
# _lf_nfprog, _lf_lroot, _lf_spoke) and what reads their runs (_lf_ended, _lf_said); lane-reviews.sh holds the reviews'
# fixtures (_lf_r2land, _lf_r2, _lf_r3, _lf_bind, _lf_two, _lf_v3r2 and those added after). tests/run sources each of the
# three on a line of its own, since a lib file runs nothing (part 0006) and so sources no other.

# DIR -> DIR removed if there and made again, empty; LF_DIR its physical path. DIR must lie below $TMP.
_lf_dir() {
  LF_DIR=""
  case "${1-}" in "$TMP"/?*) ;; *) printf '_lf_dir: [%s] is not below $TMP\n' "${1-}" >&2; return 1 ;; esac
  rm -rf "$1" && mkdir -p "$1" || return 1
  LF_DIR="$(cd -P -- "$1" && pwd -P)"
  [ -n "$LF_DIR" ]
}

# T ARGS... -> git ARGS where the caller stands (after _fx_cd, in a subshell), with no global or system configuration,
# the identity lane <lane@example.invalid>, author and committer time T (epoch seconds, UTC), no hooks and no signing.
_lf_g() {
  local t="$1"
  shift
  GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
    GIT_AUTHOR_NAME=lane GIT_AUTHOR_EMAIL=lane@example.invalid GIT_COMMITTER_NAME=lane GIT_COMMITTER_EMAIL=lane@example.invalid \
    GIT_AUTHOR_DATE="$t +0000" GIT_COMMITTER_DATE="$t +0000" \
    git -c core.autocrlf=false -c core.safecrlf=false -c commit.gpgsign=false -c core.hooksPath=/dev/null \
      -c gc.auto=0 -c maintenance.auto=false "$@"
}

# DIR [BRANCH] -> a new repository in DIR (made when missing) on BRANCH (main), with no commit.
_lf_init() {
  mkdir -p "$1" || return 1
  ( _fx_cd "$1" || exit 1; _lf_g 1700000000 init -q -b "${2:-main}" ) >/dev/null 2>&1
}

# DIR T MESSAGE [SPEC...] -> one commit on the branch DIR stands on, at time T, whose message is MESSAGE byte for byte,
# changing what each SPEC names, relative to DIR: PATH appends a line to PATH (made, with its directories, when
# missing), =PATH adds PATH as it stands, -PATH removes it, OLD>NEW moves OLD to NEW. What is staged already (a squash,
# a merge) is committed with it, and no SPEC with nothing staged is an empty commit. LF_SHA is the commit's full name,
# or empty when it could not be made or its stored message is not MESSAGE.
_lf_commit() {
  local d="$1" t="$2" m="$3"
  shift 3
  LF_SHA="$( _fx_cd "$d" || exit 1
    for s in "$@"; do
      case "$s" in
        (-*) _lf_g "$t" rm -q -- "${s#-}" || exit 1 ;;
        (=*) _lf_g "$t" add -- "${s#=}" || exit 1 ;;
        (*'>'*) mkdir -p "$(dirname -- "${s#*>}")" && _lf_g "$t" mv -- "${s%%>*}" "${s#*>}" || exit 1 ;;
        (*) mkdir -p "$(dirname -- "$s")" && printf '%s %s\n' "$t" "$s" >> "$s" && _lf_g "$t" add -- "$s" || exit 1 ;;
      esac
    done
    printf '%s' "$m" | _lf_g "$t" commit -q --allow-empty --cleanup=verbatim -F - || exit 1
    h="$(_lf_g "$t" rev-parse --verify -q HEAD)" || exit 1
    f="$(mktemp "$TMP/lf-commit.XXXXXX")" || exit 1
    _lf_g "$t" cat-file commit "$h" > "$f" || { rm -f "$f"; exit 1; }
    { sed '/^$/q' "$f"; printf '%s' "$m"; } > "$f.want"
    cmp -s "$f" "$f.want"; r=$?
    rm -f "$f" "$f.want"
    [ "$r" -eq 0 ] || exit 1
    printf '%s' "$h" )" || LF_SHA=""
  [ -n "$LF_SHA" ]
}

# DIR NAME [START] -> a new branch NAME at START (HEAD), and DIR stands on it.
_lf_branch() { ( _fx_cd "$1" || exit 1; _lf_g 1700000000 checkout -q -b "$2" ${3+"$3"} ) >/dev/null 2>&1; }
# DIR NAME -> DIR stands on the branch NAME.
_lf_switch() { ( _fx_cd "$1" || exit 1; _lf_g 1700000000 checkout -q "$2" ) >/dev/null 2>&1; }

# DIR T BRANCH MESSAGE -> a real merge of BRANCH into the branch DIR stands on (--no-ff), at time T, whose message is
# MESSAGE byte for byte. LF_SHA as _lf_commit's; empty also when the commit made has no second parent.
_lf_merge() {
  local d="$1" t="$2" b="$3" m="$4"
  LF_SHA=""
  ( _fx_cd "$d" || exit 1; _lf_g "$t" merge -q --no-ff --no-commit "$b" ) >/dev/null 2>&1 || return 1
  _lf_commit "$d" "$t" "$m" || return 1
  ( _fx_cd "$d" || exit 1; _lf_g "$t" rev-parse --verify -q "$LF_SHA^2" ) >/dev/null 2>&1 || { LF_SHA=""; return 1; }
}

# DIR T SHAPE BRANCH SUBJECT -> the landing a squash of BRANCH makes on the branch DIR stands on (main), at time T, as
# C3 writes its message. Its entries are the non-merge commits of HEAD..BRANCH, oldest first, each "* <its message>"
# (the subject, a blank line, the body, as the commit holds them), a blank line between two. SHAPE felix: SUBJECT, a
# blank line, "felix merge squashed BRANCH at <tip>.", a blank line, the entries, a blank line, and the trailers
# Felix-Judge: and Felix-Gate:. SHAPE github (GitHub's default): SUBJECT, a blank line, the entries. No merge commit's
# message is copied. LF_SHA as _lf_commit's, LF_MSG the message.
_lf_squash() {
  local d="$1" t="$2" sh="$3" b="$4" s="$5" m
  LF_SHA=""; LF_MSG=""
  m="$( _fx_cd "$d" || exit 1
    tip="$(_lf_g "$t" rev-parse --verify -q "$b^{commit}")" || exit 1
    list="$(_lf_g "$t" rev-list --reverse --topo-order --no-merges "HEAD..$b")" || exit 1
    f="$(mktemp "$TMP/lf-squash.XXXXXX")" || exit 1
    printf '%s\n\n' "$s"
    [ "$sh" != felix ] || printf 'felix merge squashed %s at %s.\n\n' "$b" "$tip"
    sep=""
    for c in $list; do
      _lf_g "$t" cat-file commit "$c" > "$f" || { rm -f "$f"; exit 1; }
      e="$(sed '1,/^$/d' "$f"; printf x)"; e="${e%x}"
      printf '%s* %s' "$sep" "$e"
      sep=$'\n'
    done
    rm -f "$f"
    [ "$sh" != felix ] || printf '\nFelix-Judge: passed\nFelix-Gate: passed\n'
    printf x )" || return 1
  m="${m%x}"
  ( _fx_cd "$d" || exit 1; _lf_g "$t" merge -q --squash "$b" ) >/dev/null 2>&1 || return 1
  _lf_commit "$d" "$t" "$m" || return 1
  LF_MSG="$m"
}

# DIR [COMMIT] -> refs/remotes/origin/main in DIR names COMMIT (HEAD). No remote is made (C9).
_lf_publish() { ( _fx_cd "$1" || exit 1; _lf_g 1700000000 update-ref refs/remotes/origin/main "${2:-HEAD}" ) >/dev/null 2>&1; }

# DIR LANE T STEP SPEC... -> one landing for each SPEC on the branch DIR stands on, the k-th (from 1) at T + (k-1)*STEP:
# m a marked engine change (engine/<k>.sh), u an unmarked one, md a marked docs-only change (docs/<k>.md), ud an
# unmarked one. A mark is the body line Felix-Lane: LANE. Then refs/remotes/origin/main names the last; LF_SHA it.
_lf_chain() {
  local d="$1" l="$2" t="$3" st="$4" k=0 w p m
  shift 4
  for w in "$@"; do
    k=$((k + 1))
    case "$w" in m|u) p="engine/$k.sh" ;; md|ud) p="docs/$k.md" ;; *) LF_SHA=""; return 1 ;; esac
    case "$w" in m|md) m="landing $k"$'\n\n'"Felix-Lane: $l"$'\n' ;; *) m="landing $k"$'\n\nNo mark.\n' ;; esac
    _lf_commit "$d" $((t + (k - 1) * st)) "$m" "$p" || return 1
  done
  _lf_publish "$d" || { LF_SHA=""; return 1; }
}

# DIR P [T] -> a Felix home in DIR: a repository whose one commit, at T (1790000000), holds projects/P/project.json
# ({"name":"P","gate":"true"}) and projects/P/CLAUDE.md. LF_HOME its physical path, LF_PROJ LF_HOME/projects/P,
# LF_SHA the commit.
_lf_home() {
  LF_HOME=""; LF_PROJ=""
  _lf_init "$1" || return 1
  mkdir -p "$1/projects/$2" || return 1
  printf '{"name":"%s","gate":"true"}\n' "$2" > "$1/projects/$2/project.json"
  printf '# %s\n' "$2" > "$1/projects/$2/CLAUDE.md"
  _lf_commit "$1" "${3:-1790000000}" "the home of $2"$'\n' "=projects/$2/project.json" "=projects/$2/CLAUDE.md" || return 1
  LF_HOME="$(cd -P -- "$1" && pwd -P)"; LF_PROJ="$LF_HOME/projects/$2"
}

# PROJ T FILE BYTES [MESSAGE] -> PROJ/FILE holds BYTES exactly (a CR, a missing last newline and any other byte kept),
# committed at T in the repository that holds PROJ. LF_SHA the commit.
_lf_table() {
  local m="${5-}"
  [ -n "$m" ] || m="$3, as the part needs it"$'\n'
  printf '%s' "$4" > "$1/$3" || { LF_SHA=""; return 1; }
  _lf_commit "$1" "$2" "$m" "=$3"
}

# DIR P [T] -> a checkout in DIR bound to P by an untracked .felix, whose root commit, at T (1790000000), adds README
# only, on main. LF_REPO its physical path, LF_SHA the root.
_lf_checkout() {
  LF_REPO=""
  _lf_init "$1" || return 1
  printf '%s\n' "$2" > "$1/.felix" && printf 'a checkout of %s\n' "$2" > "$1/README" || return 1
  _lf_commit "$1" "${3:-1790000000}" $'the root\n' "=README" || return 1
  LF_REPO="$(cd -P -- "$1" && pwd -P)"
}

# PROJ OWNER/REPO -> PROJ/project.json is {"name":"<P>","gate":"true","remote_match":"OWNER/REPO"}, P the name of PROJ's
# directory, written in the working tree and never committed, so a home's commits are the same with it or without it.
_lf_match() {
  [ -d "${1-}" ] && [ -n "${2-}" ] || return 1
  printf '{"name":"%s","gate":"true","remote_match":"%s"}\n' "${1##*/}" "$2" > "$1/project.json"
}

# DIR URL -> DIR's origin remote names URL: added, or its URL changed when DIR has one already (a clone). Nothing is
# fetched, and no ref is made or removed. Status 0 when git reads URL back as remote.origin.url.
_lf_origin() {
  ( _fx_cd "$1" || exit 1
    if _lf_g 1700000000 config --get remote.origin.url; then _lf_g 1700000000 remote set-url origin "$2" || exit 1
    else _lf_g 1700000000 remote add origin "$2" || exit 1; fi
    [ "$(_lf_g 1700000000 config --get remote.origin.url)" = "$2" ] ) >/dev/null 2>&1
}

# PROJ DIR OWNER/REPO -> the checkout DIR, bound to PROJ's project, is that project's own (C7, C9): _lf_match PROJ
# OWNER/REPO, and DIR's origin https://github.com/OWNER/REPO.git. A checkout whose project has no remote_match, whose
# origin is another repository, or that has no origin is not own.
_lf_own() { _lf_match "$1" "$3" && _lf_origin "$2" "https://github.com/$3.git"; }

# DIR P [T] -> one repository that is both the home and the checkout, as felix-home is: its root commit, at T
# (1790000000), on main, holds .felix (P) at its top, projects/P/project.json and projects/P/CLAUDE.md. LF_HOME and
# LF_REPO its physical path, LF_PROJ LF_HOME/projects/P, LF_SHA the root.
_lf_self() {
  LF_HOME=""; LF_REPO=""; LF_PROJ=""
  _lf_init "$1" || return 1
  mkdir -p "$1/projects/$2" || return 1
  printf '%s\n' "$2" > "$1/.felix"
  printf '{"name":"%s","gate":"true"}\n' "$2" > "$1/projects/$2/project.json"
  printf '# %s\n' "$2" > "$1/projects/$2/CLAUDE.md"
  _lf_commit "$1" "${3:-1790000000}" "the home and checkout of $2"$'\n' \
    "=.felix" "=projects/$2/project.json" "=projects/$2/CLAUDE.md" || return 1
  LF_HOME="$(cd -P -- "$1" && pwd -P)"; LF_REPO="$LF_HOME"; LF_PROJ="$LF_HOME/projects/$2"
}

# DIR -> DIR/bin holding C9's stubs: claude, gh and graphify as part 1670 makes them, uname (prints Darwin) and
# launchctl (list prints its header alone, print exits 113) as part 1690 makes them. LF_BIN its path.
_lf_stubs() {
  LF_BIN=""
  mkdir -p "$1/bin" || return 1
  printf '#!/bin/sh\ncase "$*" in "plugin list --json --available") printf "[]\\n"; exit 0 ;; "mcp list"|"plugin list"|"plugin marketplace list") exit 0 ;; esac\nexit 2\n' > "$1/bin/claude"
  printf '#!/bin/sh\nexit 0\n' > "$1/bin/gh"
  printf '#!/bin/sh\nexit 0\n' > "$1/bin/graphify"
  printf '#!/bin/bash\nprintf '"'"'%%s\\n'"'"' Darwin\n' > "$1/bin/uname"
  printf '#!/bin/bash\ncase "${1:-}" in\n  print) exit 113 ;;\n  list) printf '"'"'PID\\tStatus\\tLabel\\n'"'"'; exit 0 ;;\nesac\nexit 0\n' > "$1/bin/launchctl"
  chmod +x "$1/bin/claude" "$1/bin/gh" "$1/bin/graphify" "$1/bin/uname" "$1/bin/launchctl" || return 1
  LF_BIN="$(cd -P -- "$1/bin" && pwd -P)"
}

# DIR -> a copy of the engine at DIR/root/harness: bin, ecosystem.tsv, felix, hooks, lib and templates from
# $FROOT/harness, with lib/lane.sh removed (C9's broken engine). LF_ROOT DIR/root.
_lf_broken() {
  local e
  LF_ROOT=""
  rm -rf "$1/root" && mkdir -p "$1/root/harness" || return 1
  for e in bin ecosystem.tsv felix hooks lib templates; do
    [ ! -e "$FROOT/harness/$e" ] || cp -R "$FROOT/harness/$e" "$1/root/harness/$e" || return 1
  done
  rm -f "$1/root/harness/lib/lane.sh"
  LF_ROOT="$(cd -P -- "$1/root" && pwd -P)"
}

# HOME MEMORY USER BIN -> the environment every surface runs in (C9): FELIX_HOME HOME, FELIX_MEMORY MEMORY (outside every
# fixture repository), HOME USER, BIN first on PATH. Sets LF_H, LF_M, LF_U and LF_B, and makes MEMORY and USER.
_lf_use() { LF_H="$1"; LF_M="$2"; LF_U="$3"; LF_B="$4"; mkdir -p "$2" "$3"; }

# OUT DIR NOW CMD... -> CMD run from DIR as C9 runs a surface: no CLAUDE_CODE_SESSION_ID, FELIX_HOME_DIR, COPILOT_CLI,
# CURSOR_PLUGIN_ROOT or CLAUDE_CONFIG_DIR, the environment _lf_use set, FELIX_LANE_NOW NOW (unset when NOW is -).
# Stdout in OUT.out, stderr in OUT.err, the status in LF_RC (125 when DIR could not be entered).
_lf_run() {
  local o="$1" d="$2" n="$3"
  shift 3
  ( _fx_cd "$d" || exit 125
    if [ "$n" = - ]; then
      exec env -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR -u FELIX_LANE_NOW -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT \
        -u CLAUDE_CONFIG_DIR HOME="$LF_U" FELIX_HOME="$LF_H" FELIX_MEMORY="$LF_M" PATH="$LF_B:$PATH" "$@"
    fi
    exec env -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR -u FELIX_LANE_NOW -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT \
      -u CLAUDE_CONFIG_DIR HOME="$LF_U" FELIX_HOME="$LF_H" FELIX_MEMORY="$LF_M" PATH="$LF_B:$PATH" \
      FELIX_LANE_NOW="$n" "$@" ) > "$o.out" 2> "$o.err" < /dev/null
  LF_RC=$?
}

# HOME -> waits up to 20 s while HOME/state/discover/.lock stands: a discovery a session start launched (part 1670).
_lf_calm() { local i=0; while [ "$i" -lt 100 ] && [ -d "$1/state/discover/.lock" ]; do sleep 0.2; i=$((i + 1)); done; }

# FILE KEY -> KEY's string in the JSON object FILE holds, at its top or in hookSpecificOutput, written as UTF-8 bytes;
# status 3 when FILE holds no JSON object.
_lf_jget() {
  python3 -c 'import json, sys
try: d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception: sys.exit(3)
if not isinstance(d, dict): sys.exit(3)
v = d.get(sys.argv[2]) or (d.get("hookSpecificOutput") or {}).get(sys.argv[2]) or ""
sys.stdout.buffer.write(str(v).encode("utf-8", "surrogateescape"))' "$1" "$2" 2>/dev/null
}

# OUT DIR NOW SOURCE [ROOT] -> hooks/session-start of ROOT ($FROOT) run from DIR as C9 runs it: CLAUDE_PLUGIN_ROOT ROOT,
# the payload {"session_id":"lane-start","source":SOURCE,"cwd":DIR} on stdin, the environment of _lf_run. Then waits
# for LF_H's discovery lock to clear. Sets LF_RC; LF_JSON ok or bad (none when python3 is absent); OUT.ctx and LF_CTX
# the context (hookSpecificOutput.additionalContext), OUT.scr and LF_SCR the screen line (systemMessage).
_lf_start() {
  local o="$1" d="$2" n="$3" s="$4" r="${5:-$FROOT}"
  LF_JSON=none; LF_CTX=""; LF_SCR=""
  printf '{"session_id":"lane-start","source":"%s","cwd":"%s"}' "$s" "$d" > "$o.in"
  ( _fx_cd "$d" || exit 125
    if [ "$n" = - ]; then
      exec env -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR -u FELIX_LANE_NOW -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT \
        -u CLAUDE_CONFIG_DIR HOME="$LF_U" FELIX_HOME="$LF_H" FELIX_MEMORY="$LF_M" PATH="$LF_B:$PATH" \
        CLAUDE_PLUGIN_ROOT="$r" "$r/harness/hooks/session-start"
    fi
    exec env -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR -u FELIX_LANE_NOW -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT \
      -u CLAUDE_CONFIG_DIR HOME="$LF_U" FELIX_HOME="$LF_H" FELIX_MEMORY="$LF_M" PATH="$LF_B:$PATH" \
      FELIX_LANE_NOW="$n" CLAUDE_PLUGIN_ROOT="$r" "$r/harness/hooks/session-start" ) < "$o.in" > "$o.out" 2> "$o.err"
  LF_RC=$?
  _lf_calm "$LF_H"
  _lf_json "$o"
}

# OUT -> what a session start wrote to OUT.out, read as _lf_start reads it: LF_JSON ok or bad (none when python3 is
# absent), OUT.ctx and LF_CTX the context, OUT.scr and LF_SCR the screen line.
_lf_json() {
  LF_JSON=none; LF_CTX=""; LF_SCR=""
  command -v python3 >/dev/null 2>&1 || return 0
  if _lf_jget "$1.out" additionalContext > "$1.ctx"; then LF_JSON=ok; else LF_JSON=bad; fi
  _lf_jget "$1.out" systemMessage > "$1.scr"
  LF_CTX="$(cat "$1.ctx")"; LF_SCR="$(cat "$1.scr")"
}

# LANE -> "none" when the last _lf_start put neither a lane paragraph (C7) for LANE in the context nor a lane token on
# the screen line, else what it found.
_lf_silent() {
  local w=""
  case "$LF_CTX" in *"Lane $1 is "*|*"first open lane item"*) w="paragraph" ;; esac
  case "$LF_SCR" in *" · lane: "*) w="${w:+$w and }token" ;; esac
  printf '%s' "${w:-none}"
}

# EPOCH -> that instant as YYYY-MM-DDTHH:MM:SSZ (UTC).
_lf_iso() { date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ; }

# WORD... -> the words joined by tabs, as one TSV line with no newline.
_lf_tsv() { local IFS="$(printf '\t')"; printf '%s' "$*"; }

# FILE LINE COL... -> those tab-separated columns of line LINE of FILE, joined by |; nothing when there is no such line.
_lf_cols() {
  local f="$1" l="$2"
  shift 2
  LC_ALL=C awk -F'\t' -v l="$l" -v c="$*" 'NR == l { n = split(c, k, " "); for (i = 1; i <= n; i++) printf "%s%s", (i > 1 ? "|" : ""), $(k[i]) }' "$f" 2>/dev/null
}

# FILE -> its last line. _lf_count FILE -> its number of lines (a last line with no newline counts).
_lf_last() { LC_ALL=C awk '{ l = $0 } END { printf "%s", l }' "$1" 2>/dev/null; }
_lf_count() { LC_ALL=C awk 'END { print NR }' "$1" 2>/dev/null; }

# DIR -> the first-parent chain of refs/remotes/origin/main in DIR, newest first, as "<committer time>:<parents>" words.
_lf_spine() {
  ( _fx_cd "$1" || exit 1; _lf_g 1700000000 log --first-parent --format='%ct %P' refs/remotes/origin/main ) 2>/dev/null \
    | LC_ALL=C awk '{ printf "%s%s:%d", (NR > 1 ? " " : ""), $1, NF - 1 }'
}

# DIR COMMIT LANE -> how many lines of COMMIT's message are, byte for byte, Felix-Lane: LANE.
_lf_marks() {
  local f
  f="$(mktemp "$TMP/lf-marks.XXXXXX")" || return 1
  ( _fx_cd "$1" || exit 1; _lf_g 1700000000 cat-file commit "$2" ) > "$f" 2>/dev/null
  LC_ALL=C awk -v m="Felix-Lane: $3" 'b && $0 == m { n++ } $0 == "" { b = 1 } END { print n + 0 }' "$f"
  rm -f "$f"
}

# DIR REV -> removes the loose object REV names from DIR/.git/objects; 0 when it was loose and is gone.
_lf_unobject() {
  local h
  h="$( _fx_cd "$1" || exit 1; _lf_g 1700000000 rev-parse --verify -q "$2" )" || return 1
  case "$h" in ????????????????????????????????????????) ;; *) return 1 ;; esac
  [ -f "$1/.git/objects/${h%"${h#??}"}/${h#??}" ] || return 1
  rm -f "$1/.git/objects/${h%"${h#??}"}/${h#??}"
  [ ! -e "$1/.git/objects/${h%"${h#??}"}/${h#??}" ]
}
