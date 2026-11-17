printf '\n%s\n' 'situations: the review focus (blind)'
# Blind, written on 2026-10-31 from docs/2026-10-29-capability-lane-first-slices-design.md (sections 3, 4, 7, 10 and
# 11) and the slice 1 plan's Contracts and Review Focus (C1 to C16) alone, at the spec commit 21df057c merged with main,
# before lib/situations.sh existed, without reading lib/, hooks/, bin/ or felix. Felix is run as a black box, and every
# fixture is built here (C13); nothing comes from tests/lib/lane-fixture.sh. C14 pins the review focus, RF1 to RF9, and
# each item's assertions begin "2470 rf1" to "2470 rf9". Every run is C13's: ( cd C && env FELIX_HOME=H FELIX_MEMORY=M
# TMPDIR=T felix situations ... ), T fresh and empty, the network stubs first on PATH and the four keys unset.
# C17's items were added on 2026-11-05 from C17 and the Contracts it amends, still without reading lib/situations*.sh
# or felix's cmd_situations: RF5's unended row, RF6's fsmonitor and clean-filter cases, RF8, RF9, and RF3's a1 and a_1.
# RF5's unended case calls felix_obligation_rows, which C17.1 names, with the project's directory, the one argument
# lib/obligations.sh gives it. C17.11's two were added on 2026-11-06 in the same way: RF6's core.quotePath case
# (C17.11.1) and RF9's unwritable live-index (C17.11.3).
#
# Readings where the Contracts leave room:
# - Every run also gets HOME, an empty directory (RF6's names its own), and has GIT_CONFIG_GLOBAL, GIT_CONFIG_SYSTEM,
#   GIT_CONFIG_NOSYSTEM, XDG_CONFIG_HOME, GIT_CONFIG_PARAMETERS and GIT_CONFIG_COUNT unset, so the person's own git
#   config reaches no run and RF6's does.
# - A tree id a header prints is read from the facts.log that felix probes writes for a clean checkout of that commit,
#   under a memory root of its own (C3.3: the scratch tree id equals it).
# - RF1's explicit range is HEAD~1..HEAD. The default range is read in the human report (its header), the explicit one
#   in --tsv. The unchanged state also holds each worktree's git ls-files -s and git status --porcelain (C3.4), read
#   with GIT_OPTIONAL_LOCKS=0; the marker is touched a second after the last fixture write and a second before the runs.
# - RF2's --at names the tree felix probes recorded.
# - RF3's --at reads a hand-written facts.log (C13): tree rf3-tree, where x was recorded found, and tree rf3-blind, where
#   it was recorded blind, so that --at has could-not-look lines to order too. The run under LANG=$LCB_U8 also unsets
#   every other LC_* variable, so LANG decides. The orders of a1 before a_1 and of a_c before ab are asserted under both
#   locales. In --at, C9 prints an UNKNOWN class in no section and C8 orders --tsv's class lines by id, so the --at
#   order is asserted on the residual's could-not-look lines, in --tsv and in the human report.
# - RF4 starts felix through perl, which also starts a session of its own (so nothing felix sends its process group can
#   reach the suite) and resets TERM and HUP as well as INT. The wait for the probe stops when felix has exited, and a
#   felix still running 30 s after the signal is killed with KILL and reaped; so on an engine without the command, RF4
#   costs no wait.
# - RF5's obligations.tsv exists before --propose, holding one admitted row of another name. The printed admit command
#   is run only when it begins with C17.1's guard, "{ [ ! -s '<P>/obligations.tsv' ] || ", and names git -C '<H>' add,
#   and with HOME an empty directory and GIT_CONFIG_NOSYSTEM=1 beside C14's identity, so no hook of the person's own
#   config runs. Its unended case rewrites the same home's obligations.tsv to that one row with no final newline,
#   commits it, and runs the admit command a third --propose prints in the same way.
# - RF6: with core.hooksPath set, git never runs a template's hook, so the control (a plain clone under that HOME,
#   folded into the assertions so that none passes without the command) asserts the template was copied, and the
#   hooksPath hook and the smudge filter ran. C17.2's three cases share RF6's repository, range and probe, which runs
#   no git command. Each has its own control in a plain clone, folded in the same way: git status runs the fsmonitor
#   hook, under that HOME or that GIT_CONFIG_COUNT, and git hash-object runs the clean filter. C17.11.1's case has a
#   repository of its own, whose base commit lacks web/ so that only head can name frontend, and whose names are
#   e-acute (UTF-8) then 1, 2 and 3. Its control, folded in, is the same two runs with HOME empty.
# - RF7's W1 and W2 are both linked worktrees of one repository, W1 at its root commit and W2 one commit ahead.
# - RF8 runs felix situations with no --at, so it reads the newest recorded tree, the live one. The stat-dirty file's
#   mtime and then the index's are set to fixed past times with touch -t, so a write of the index moves its mtime
#   whatever the clock's resolution; git status run afterwards, which refreshes and writes the index, is the control.
# - RF9's sort reads what sort would read: its file operands, or stdin when it has none or one is -. It exits 2 and
#   prints nothing when a line it read begins owed:; otherwise it runs the real sort with the same arguments over the
#   same input. It writes nothing under TMPDIR. --at and --change are run with no output flag. Each unreadable table
#   is read in both modes, with --propose for obligations.tsv. RF9's mktemp (C17.11.3) knows the scratch directory by
#   C3.3's name, felix-situations.*, and its stderr sentence is pinned as RF9's sort case pins it.

S2470_D="$TMP/s2470"
rm -rf "$S2470_D"; mkdir -p "$S2470_D/bin" "$S2470_D/user"
S2470_D="$(cd -P -- "$S2470_D" && pwd -P)"
S2470_NET="$S2470_D/network.log"; : > "$S2470_NET"
for _s2470_c in gh curl wget ssh nc claude; do
  printf '#!/bin/sh\nprintf '"'"'%%s %%s\\n'"'"' %s "$*" >> '"'"'%s'"'"'\nexit 1\n' "$_s2470_c" "$S2470_NET" > "$S2470_D/bin/$_s2470_c"
  chmod +x "$S2470_D/bin/$_s2470_c"
done
S2470_U="$S2470_D/user"; S2470_L=""; S2470_XE=(S2470_EXTRA=none)
S2470_CBM='prototype=INFO,internal=ADVISORY,public-beta=TASK_BLOCKING,production=RELEASE_BLOCKING'
S2470_SRC='cite:0123456789ab'
S2470_HDR='scratch checkout, tracked content only, current probes.tsv'
S2470_NOTAT='detector not run: this checkout is not at this tree'
S2470_PSVC=$'svc\tsvc\t-\tcat svc.txt\ttest -f svc.txt\n'
S2470_O1='an entry in the owed list for every svc line'

# DIR -> DIR removed if there and made again, empty; S2470_P its physical path.
_s2470_dir() { rm -rf "$1" && mkdir -p "$1" && S2470_P="$(cd -P -- "$1" && pwd -P)"; }
# FIELDS... -> the fields joined by tabs, with no newline.
_s2470_tab() { local IFS=$'\t'; printf '%s' "$*"; }
# CLASS PROJECT -> S2470_ID, the class's id as C6 computes it.
_s2470_id() { S2470_ID="owed:$(printf '%s\t%s\t%s' "$1" "$2" '*' | git hash-object --stdin | cut -c1-12)"; }
# DIR TIME ARGS... -> git ARGS in DIR through _fx_git, with no global or system config, no hooks, identity t, both dates
# TIME (epoch seconds, UTC).
_s2470_g() {
  local d="$1" t="$2"
  shift 2
  ( export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid \
      GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid GIT_AUTHOR_DATE="$t +0000" GIT_COMMITTER_DATE="$t +0000"
    _fx_git "$d" -c commit.gpgsign=false -c core.hooksPath=/dev/null -c core.autocrlf=false "$@" ) > /dev/null 2>&1
}
# DIR TIME MESSAGE -> everything in DIR committed.
_s2470_commit() { _s2470_g "$1" "$2" add -A && _s2470_g "$1" "$2" commit -q -m "$3"; }
# DIR PROJECT -> git init -q -b main in DIR, and a .felix naming PROJECT, for the caller to commit.
_s2470_repo() { mkdir -p "$1" && _s2470_g "$1" 1793000000 init -q -b main && printf '%s\n' "$2" > "$1/.felix"; }
# HOME PROJECT PROBES -> C13's home: project.json, CLAUDE.md, and probes.tsv holding the bytes PROBES.
_s2470_home() {
  mkdir -p "$1/projects/$2" &&
    printf '{"name":"%s","remote_match":"example.invalid/%s","gate":"true"}\n' "$2" "$2" > "$1/projects/$2/project.json" &&
    printf '# %s\n' "$2" > "$1/projects/$2/CLAUDE.md" &&
    printf '%s' "$3" > "$1/projects/$2/probes.tsv"
}
# DIR -> a copy of the engine at DIR/harness (C13), its situations.tsv holding only the comment line; S2470_E its felix.
_s2470_engine() {
  S2470_E="$1/harness/felix"
  mkdir -p "$1" && cp -R "$FROOT/harness" "$1/harness" &&
    printf '# class\tapplies\towes\tclass_by_maturity\tsource\n' > "$1/harness/templates/situations.tsv"
}
# DIR CLASS APPLIES OWES -> one row of the substituted table of the engine at DIR.
_s2470_row() { printf '%s\t%s\t%s\t%s\t%s\n' "$2" "$3" "$4" "$S2470_CBM" "$S2470_SRC" >> "$1/harness/templates/situations.tsv"; }
# OUT DIR HOME MEMORY ENGINE ARGS... -> ENGINE ARGS run in DIR as C13 runs it, TMPDIR the fresh empty directory OUT.t;
# OUT.out, OUT.err, and S2470_RC its exit. S2470_U is the run's HOME; S2470_L is C, u8 or empty (the locale as it is);
# S2470_XE holds NAME=VALUE words given after the others, so they win (RF6's git config, RF9's PATH).
_s2470_run() {
  local o="$1" d="$2" h="$3" m="$4" e="$5"
  local -a le
  shift 5
  rm -rf "$o.t"; mkdir -p "$o.t"
  case "$S2470_L" in
    C)  le=(LC_ALL=C) ;;
    u8) le=(-u LC_ALL -u LC_COLLATE -u LC_CTYPE -u LC_MESSAGES -u LC_NUMERIC -u LC_TIME -u LC_MONETARY LANG="$LCB_U8") ;;
    *)  le=(-u S2470_NONE) ;;
  esac
  ( cd "$d" && exec env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GH_TOKEN -u GITHUB_TOKEN -u CLAUDE_CODE_SESSION_ID \
      -u FELIX_HOME_DIR -u GIT_CONFIG_GLOBAL -u GIT_CONFIG_SYSTEM -u GIT_CONFIG_NOSYSTEM -u XDG_CONFIG_HOME \
      -u GIT_CONFIG_PARAMETERS -u GIT_CONFIG_COUNT "${le[@]}" HOME="$S2470_U" PATH="$S2470_D/bin:$PATH" \
      FELIX_HOME="$h" FELIX_MEMORY="$m" TMPDIR="$o.t" "${S2470_XE[@]}" "$e" "$@" ) > "$o.out" 2> "$o.err" < /dev/null
  S2470_RC=$?
}
# FILE -> its mtime in whole seconds, read through perl, since BSD and GNU stat take different flags.
_s2470_mtime() { perl -e '@s = stat($ARGV[0]); print @s ? $s[9] : "absent"' "$1" 2>&1; }
# LOG -> S2470_STAMP and S2470_TREE of the newest recorded tree, as C3.1 reads it: the last line of 8 or more fields
# whose tree is not unknown-tree. Both empty when there is none.
_s2470_newest() {
  local x
  x="$(LC_ALL=C awk -F'\t' 'NF >= 8 && $2 != "unknown-tree" { s = $1; t = $2 } END { printf "%s\t%s", s, t }' "$1" 2>/dev/null)"
  S2470_STAMP="${x%%$'\t'*}"; S2470_TREE="${x#*$'\t'}"
}
# FILE SECTION -> the names of the row lines of SECTION in a human report, in order, joined by a space: the class of a
# class row, the name of a residual line (the third cell when the line is split at two spaces).
_s2470_names() {
  LC_ALL=C awk -v s="$2" '
    $0 == s { on = 1; next }
    on && $0 == "" { on = 0 }
    on && /^  [^ ]/ { n = split($0, a, "  "); if (n >= 3) { printf "%s%s", sep, a[3]; sep = " " } }
  ' "$1" 2>/dev/null
}
# REPO WORKTREE... -> the refs, the worktree list, each worktree's HEAD, symbolic HEAD, index and status, and the
# common config's bytes, read with GIT_OPTIONAL_LOCKS=0.
_s2470_snap() {
  local r="$1" w
  shift
  GIT_OPTIONAL_LOCKS=0 git -C "$r" for-each-ref 2>&1
  GIT_OPTIONAL_LOCKS=0 git -C "$r" worktree list --porcelain 2>&1
  for w in "$@"; do
    printf 'worktree %s\n' "$w"
    GIT_OPTIONAL_LOCKS=0 git -C "$w" rev-parse HEAD 2>&1
    GIT_OPTIONAL_LOCKS=0 git -C "$w" symbolic-ref -q HEAD 2>&1
    GIT_OPTIONAL_LOCKS=0 git -C "$w" ls-files -s 2>&1
    GIT_OPTIONAL_LOCKS=0 git -C "$w" status --porcelain 2>&1
  done
  cksum < "$r/.git/config" 2>&1
}

# ---- RF1: a linked worktree ---------------------------------------------------------------------------------------
# A repository whose main checkout R stands at c0 on main, and a linked worktree W, made with git worktree add, one
# commit ahead on feat, where svc.txt gains a line: svc_owed (probe:svc=found) is owed over it.
_s2470_dir "$S2470_D/rf1"; S2470_D1="$S2470_P"
_s2470_engine "$S2470_D1/x"; S2470_E1="$S2470_E"
_s2470_row "$S2470_D1/x" svc_owed 'probe:svc=found' "$S2470_O1"
_s2470_home "$S2470_D1/home" rf1 "$S2470_PSVC"
mkdir -p "$S2470_D1/mem/rf1" "$S2470_D1/mside/rf1"
S2470_R1="$S2470_D1/main"; S2470_W1="$S2470_D1/w"
_s2470_repo "$S2470_R1" rf1; printf 'a\n' > "$S2470_R1/svc.txt"
_s2470_commit "$S2470_R1" 1793000000 c0
_s2470_g "$S2470_R1" 1793000100 worktree add -q -b feat "$S2470_W1"
printf 'a\nb\n' > "$S2470_W1/svc.txt"
_s2470_commit "$S2470_W1" 1793000200 c1
S2470_C0="$(git -C "$S2470_R1" rev-parse HEAD 2>&1)"; S2470_C1="$(git -C "$S2470_W1" rev-parse HEAD 2>&1)"
_s2470_run "$S2470_D1/p0" "$S2470_R1" "$S2470_D1/home" "$S2470_D1/mside" "$S2470_E1" probes; S2470_PRC="$S2470_RC"
_s2470_newest "$S2470_D1/mside/rf1/facts.log"; S2470_TID0="$S2470_TREE"
_s2470_run "$S2470_D1/p1" "$S2470_W1" "$S2470_D1/home" "$S2470_D1/mside" "$S2470_E1" probes; S2470_PRC="$S2470_PRC $S2470_RC"
_s2470_newest "$S2470_D1/mside/rf1/facts.log"; S2470_TID1="$S2470_TREE"
S2470_B1="$(_s2470_snap "$S2470_R1" "$S2470_R1" "$S2470_W1")"
sleep 1; : > "$S2470_D1/marker"; sleep 1
_s2470_run "$S2470_D1/def" "$S2470_W1" "$S2470_D1/home" "$S2470_D1/mem" "$S2470_E1" situations --change; S2470_RA="$S2470_RC"
_s2470_run "$S2470_D1/rng" "$S2470_W1" "$S2470_D1/home" "$S2470_D1/mem" "$S2470_E1" situations --change HEAD~1..HEAD --tsv
S2470_RB="$S2470_RC"
S2470_NEW1="$(find "$S2470_R1" "$S2470_W1" -newer "$S2470_D1/marker" 2>&1)"
S2470_A1="$(_s2470_snap "$S2470_R1" "$S2470_R1" "$S2470_W1")"
S2470_X1="situations for rf1
  base  $S2470_C0  tree $S2470_TID0  $S2470_HDR
  head  $S2470_C1  tree $S2470_TID1  $S2470_HDR"
is "2470 rf1 felix situations --change from a linked worktree, with the default range, exits 0 with an empty stderr, its header naming the merge base with main and the worktree's HEAD, each with its tree id" \
   "$S2470_PRC|$S2470_RA|$(cat "$S2470_D1/def.err")|$(head -n 3 "$S2470_D1/def.out")" "0 0|0||$S2470_X1"
_s2470_id svc_owed rf1
is "2470 rf1 felix situations --change HEAD~1..HEAD --tsv from the linked worktree exits 0 and reads svc_owed owed over the worktree's own commit" \
   "$S2470_RB|$(cat "$S2470_D1/rng.err")|$(cat "$S2470_D1/rng.out")" \
   "0||$(_s2470_tab "$S2470_ID" svc_owed owed ACTIVE ACTIVE 'svc found (svc)' 'svc found (svc)' "$S2470_O1")"
is "2470 rf1 after both runs the refs, every worktree's HEAD, git worktree list --porcelain, each index and status, and the config's bytes are as they were" \
   "$S2470_RA|$S2470_RB|$S2470_A1" "0|0|$S2470_B1"
is "2470 rf1 after both runs nothing under the main checkout, the linked worktree or the common git directory is newer than a marker touched before them" \
   "$S2470_RA|$S2470_RB|$S2470_NEW1" "0|0|"

# ---- RF2: an untracked environment --------------------------------------------------------------------------------
# The probe grounding ready reads found only while .ready, ignored and untracked, is present; its witness is the tracked
# app.txt. So the live checkout reads it found, and a scratch clone, which holds tracked content only, reads it blind.
_s2470_dir "$S2470_D/rf2"; S2470_D2="$S2470_P"
S2470_O2='a readiness check before the service is used'
_s2470_engine "$S2470_D2/x"; S2470_E2="$S2470_E"
_s2470_row "$S2470_D2/x" env_ready 'probe:ready=found' "$S2470_O2"
_s2470_home "$S2470_D2/home" rf2 $'ready\tready\t-\ttest -f .ready && cat app.txt\ttest -f app.txt\n'
mkdir -p "$S2470_D2/mem/rf2"
S2470_C2="$S2470_D2/c"
_s2470_repo "$S2470_C2" rf2; printf '.ready\n' > "$S2470_C2/.gitignore"; printf 'route-a\n' > "$S2470_C2/app.txt"
_s2470_commit "$S2470_C2" 1793000000 c0
printf 'x\n' > "$S2470_C2/other.txt"
_s2470_commit "$S2470_C2" 1793000100 c1
printf 'ok\n' > "$S2470_C2/.ready"
_s2470_run "$S2470_D2/p" "$S2470_C2" "$S2470_D2/home" "$S2470_D2/mem" "$S2470_E2" probes; S2470_PRC="$S2470_RC"
_s2470_newest "$S2470_D2/mem/rf2/facts.log"
_s2470_run "$S2470_D2/at" "$S2470_C2" "$S2470_D2/home" "$S2470_D2/mem" "$S2470_E2" situations --at "$S2470_TREE" --tsv
S2470_RA="$S2470_RC"
_s2470_run "$S2470_D2/ch" "$S2470_C2" "$S2470_D2/home" "$S2470_D2/mem" "$S2470_E2" situations --change HEAD~1..HEAD --tsv
S2470_RB="$S2470_RC"
_s2470_id env_ready rf2
is "2470 rf2 after felix probes in the live checkout, whose ignored untracked .ready the probe needs, --at its tree reads env_ready ACTIVE, as standing" \
   "$S2470_PRC|$S2470_RA|$(cat "$S2470_D2/at.err")|$(cat "$S2470_D2/at.out")" \
   "0|0||$(_s2470_tab "$S2470_ID" env_ready standing - ACTIVE - 'ready found (ready)' "$S2470_O2")"
is "2470 rf2 --change HEAD~1..HEAD over a commit that does not touch the surface reads env_ready could-not-look, UNKNOWN at base and at head, never DORMANT, retired or none" \
   "$S2470_RB|$(LC_ALL=C awk -F'\t' '$2 == "env_ready" { print $3 " " $4 " " $5 }' "$S2470_D2/ch.out")" "0|could-not-look UNKNOWN UNKNOWN"
S2470_W2="the witness says this surface exists and the probe exited 1"
is "2470 rf2 that --tsv is the class line, then could-not-look residual lines for base: and head:, each naming the term probe:ready=found and the probe's own sentence" \
   "$S2470_RB|$(cat "$S2470_D2/ch.err")|$(cat "$S2470_D2/ch.out")" \
   "0||$(_s2470_tab "$S2470_ID" env_ready could-not-look UNKNOWN UNKNOWN 'ready blind (ready)' 'ready blind (ready)' "$S2470_O2")
$(_s2470_tab residual could-not-look env_ready "base: probe:ready=found: ready read blind: $S2470_W2")
$(_s2470_tab residual could-not-look env_ready "head: probe:ready=found: ready read blind: $S2470_W2")"

# ---- RF3: the caller's locale -------------------------------------------------------------------------------------
# Classes ab, a_c, a_1 and a1, in that order in the table, all on probe:x=found, with owes that differ in case. In
# bytes a1 sorts before a_1 ('1' is 0x31, '_' 0x5f) and a_c before ab ('b' is 0x62); glibc's en_US.UTF-8 collation,
# which passes over the '_', puts ab before a_c, and macOS's puts a_1 before a1 (C17.10). Over c1, which removes
# list.txt while the witness's keep.txt stays, x reads found at base and blind at head: all four blinded. At the
# recorded tree rf3-blind x reads blind, so in --at all four could not look, each with one residual line (C10).
_s2470_dir "$S2470_D/rf3"; S2470_D3="$S2470_P"
_s2470_engine "$S2470_D3/x"; S2470_E3="$S2470_E"
_s2470_row "$S2470_D3/x" ab 'probe:x=found' 'Bound The AB Surface'
_s2470_row "$S2470_D3/x" a_c 'probe:x=found' 'bound the a_c surface'
_s2470_row "$S2470_D3/x" a_1 'probe:x=found' 'bound the a_1 surface'
_s2470_row "$S2470_D3/x" a1 'probe:x=found' 'Bound The A1 Surface'
_s2470_home "$S2470_D3/home" rf3 $'x\tx\t-\tcat list.txt\ttest -f keep.txt\n'
mkdir -p "$S2470_D3/mem/rf3"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' 2026-10-29T11:00:00Z rf3-blind x - blind 0 x 'cat list.txt' \
  2026-10-29T12:00:00Z rf3-tree x - found 1 x 'cat list.txt' > "$S2470_D3/mem/rf3/facts.log"
S2470_C3="$S2470_D3/c"
_s2470_repo "$S2470_C3" rf3; printf 'kept\n' > "$S2470_C3/keep.txt"; printf 'one\n' > "$S2470_C3/list.txt"
_s2470_commit "$S2470_C3" 1793000000 c0
rm -f "$S2470_C3/list.txt"
_s2470_commit "$S2470_C3" 1793000100 c1
_locale_bytes_vars
S2470_N3_1="2470 rf3 --change --tsv prints the same bytes under LC_ALL=C and under LANG=en_US.UTF-8 with LC_ALL unset"
S2470_N3_2="2470 rf3 the --change human report prints the same bytes under LC_ALL=C and under LANG=en_US.UTF-8 with LC_ALL unset"
S2470_N3_3="2470 rf3 --at --tsv prints the same bytes under LC_ALL=C and under LANG=en_US.UTF-8 with LC_ALL unset"
S2470_N3_4="2470 rf3 the --at human report prints the same bytes under LC_ALL=C and under LANG=en_US.UTF-8 with LC_ALL unset"
S2470_N3_5="2470 rf3 in --change, under either locale, a1, a_1, a_c and ab are all blinded, and a1 comes before a_1 and a_c before ab in the blinded section and in the residual's could-not-look lines"
S2470_N3_6="2470 rf3 --at a tree where x was recorded blind, --tsv prints the same bytes under LC_ALL=C and under LANG=en_US.UTF-8 with LC_ALL unset"
S2470_N3_7="2470 rf3 the --at human report of that tree prints the same bytes under LC_ALL=C and under LANG=en_US.UTF-8 with LC_ALL unset"
S2470_N3_8="2470 rf3 in --at on that tree, under either locale, a1, a_1, a_c and ab all could not look, and a1 comes before a_1 and a_c before ab in the residual's could-not-look lines, in --tsv and in the human report"
if [ -z "${LCB_U8:-}" ]; then
  skip "$S2470_N3_1" "$LCB_NONE"; skip "$S2470_N3_2" "$LCB_NONE"; skip "$S2470_N3_3" "$LCB_NONE"
  skip "$S2470_N3_4" "$LCB_NONE"; skip "$S2470_N3_5" "$LCB_NONE"; skip "$S2470_N3_6" "$LCB_NONE"
  skip "$S2470_N3_7" "$LCB_NONE"; skip "$S2470_N3_8" "$LCB_NONE"
else
  for S2470_L in C u8; do
    _s2470_run "$S2470_D3/ct-$S2470_L" "$S2470_C3" "$S2470_D3/home" "$S2470_D3/mem" "$S2470_E3" situations --change HEAD~1..HEAD --tsv
    eval "S2470_RCT_$S2470_L=\$S2470_RC"
    _s2470_run "$S2470_D3/ch-$S2470_L" "$S2470_C3" "$S2470_D3/home" "$S2470_D3/mem" "$S2470_E3" situations --change HEAD~1..HEAD
    eval "S2470_RCH_$S2470_L=\$S2470_RC"
    _s2470_run "$S2470_D3/at-$S2470_L" "$S2470_C3" "$S2470_D3/home" "$S2470_D3/mem" "$S2470_E3" situations --at rf3-tree --tsv
    eval "S2470_RAT_$S2470_L=\$S2470_RC"
    _s2470_run "$S2470_D3/ah-$S2470_L" "$S2470_C3" "$S2470_D3/home" "$S2470_D3/mem" "$S2470_E3" situations --at rf3-tree
    eval "S2470_RAH_$S2470_L=\$S2470_RC"
    _s2470_run "$S2470_D3/bt-$S2470_L" "$S2470_C3" "$S2470_D3/home" "$S2470_D3/mem" "$S2470_E3" situations --at rf3-blind --tsv
    eval "S2470_RBT_$S2470_L=\$S2470_RC"
    _s2470_run "$S2470_D3/bh-$S2470_L" "$S2470_C3" "$S2470_D3/home" "$S2470_D3/mem" "$S2470_E3" situations --at rf3-blind
    eval "S2470_RBH_$S2470_L=\$S2470_RC"
  done
  S2470_L=""
  # NAME -> identical or different, for D3/NAME-C.out and D3/NAME-u8.out.
  _s2470_same() { cmp -s "$S2470_D3/$1-C.out" "$S2470_D3/$1-u8.out" && printf identical || printf different; }
  is "$S2470_N3_1" "$S2470_RCT_C|$S2470_RCT_u8|$(_s2470_same ct)" "0|0|identical"
  is "$S2470_N3_2" "$S2470_RCH_C|$S2470_RCH_u8|$(_s2470_same ch)" "0|0|identical"
  is "$S2470_N3_3" "$S2470_RAT_C|$S2470_RAT_u8|$(_s2470_same at)" "0|0|identical"
  is "$S2470_N3_4" "$S2470_RAH_C|$S2470_RAH_u8|$(_s2470_same ah)" "0|0|identical"
  is "$S2470_N3_5" \
     "$S2470_RCH_C|$(_s2470_names "$S2470_D3/ch-C.out" blinded)|$(_s2470_names "$S2470_D3/ch-C.out" residual)|$S2470_RCH_u8|$(_s2470_names "$S2470_D3/ch-u8.out" blinded)|$(_s2470_names "$S2470_D3/ch-u8.out" residual)" \
     "0|a1 a_1 a_c ab|a1 a_1 a_c ab|0|a1 a_1 a_c ab|a1 a_1 a_c ab"
  # FILE -> the names on FILE's could-not-look residual lines, in order, joined by a space: from --tsv's residual rows
  # (residual, kind, name, why), or from the human report's residual section (the third cell at two spaces).
  _s2470_cnl() {
    LC_ALL=C awk -F'\t' '
      $1 == "residual" && $2 == "could-not-look" { printf "%s%s", sep, $3; sep = " "; next }
      $0 == "residual" { on = 1; next }
      on && $0 == "" { on = 0 }
      on && index($0, "  could-not-look  ") == 1 { split($0, a, "  "); printf "%s%s", sep, a[3]; sep = " " }
    ' "$1" 2>/dev/null
  }
  is "$S2470_N3_6" "$S2470_RBT_C|$S2470_RBT_u8|$(_s2470_same bt)" "0|0|identical"
  is "$S2470_N3_7" "$S2470_RBH_C|$S2470_RBH_u8|$(_s2470_same bh)" "0|0|identical"
  is "$S2470_N3_8" \
     "$S2470_RBT_C|$(_s2470_cnl "$S2470_D3/bt-C.out")|$S2470_RBH_C|$(_s2470_cnl "$S2470_D3/bh-C.out")|$S2470_RBT_u8|$(_s2470_cnl "$S2470_D3/bt-u8.out")|$S2470_RBH_u8|$(_s2470_cnl "$S2470_D3/bh-u8.out")" \
     "0|a1 a_1 a_c ab|0|a1 a_1 a_c ab|0|a1 a_1 a_c ab|0|a1 a_1 a_c ab"
fi

# ---- RF4: an interrupted run and an early close -------------------------------------------------------------------
# The probe grounding s, at head only (where slow.txt is tracked), touches $TMPDIR/started and sleeps 3 s; a side's
# probes run with TMPDIR <scratch>/tmp-<side> (C3.3).
_s2470_dir "$S2470_D/rf4"; S2470_D4="$S2470_P"
_s2470_engine "$S2470_D4/x"; S2470_E4="$S2470_E"
_s2470_row "$S2470_D4/x" slow 'probe:s=found' 'a bound on how long the slow surface may run'
_s2470_home "$S2470_D4/home" rf4 \
  "$(printf '%s\t%s\t%s\t%s\t%s' s s - 'if test -f slow.txt; then touch "$TMPDIR/started"; sleep 3; fi; cat list.txt' 'test -f list.txt')
"
mkdir -p "$S2470_D4/mem/rf4"
S2470_C4="$S2470_D4/c"
_s2470_repo "$S2470_C4" rf4; printf 'one\n' > "$S2470_C4/list.txt"
_s2470_commit "$S2470_C4" 1793000000 c0
printf 'yes\n' > "$S2470_C4/slow.txt"
_s2470_commit "$S2470_C4" 1793000100 c1
# SIGNAL -> felix situations --change HEAD~1..HEAD started in the background in C4, through a perl that starts a session
# and resets INT, TERM and HUP to their defaults; SIGNAL sent to felix once the head side's probe has started (polled
# for at most 30 s, and no longer than felix runs), and felix reaped by its pid (KILL after 30 s more). S2470_SIG holds
# started or not started, the exit, and TMPDIR's entries as soon as felix exited; S2470_SIG4 the same 4 s later.
_s2470_sig() {
  local t="$S2470_D4/$1.t" pid n=0 st="not started" f rc now later
  rm -rf "$t"; mkdir -p "$t"
  ( cd "$S2470_C4" && exec perl -e 'use POSIX (); POSIX::setsid(); $SIG{INT} = q(DEFAULT); $SIG{TERM} = q(DEFAULT); $SIG{HUP} = q(DEFAULT); exec @ARGV or exit 127' \
      env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GH_TOKEN -u GITHUB_TOKEN -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR \
      -u GIT_CONFIG_GLOBAL -u GIT_CONFIG_SYSTEM -u GIT_CONFIG_NOSYSTEM -u XDG_CONFIG_HOME HOME="$S2470_U" \
      PATH="$S2470_D/bin:$PATH" FELIX_HOME="$S2470_D4/home" FELIX_MEMORY="$S2470_D4/mem" TMPDIR="$t" \
      "$S2470_E4" situations --change HEAD~1..HEAD ) > "$S2470_D4/$1.out" 2> "$S2470_D4/$1.err" < /dev/null &
  pid=$!
  while [ "$n" -lt 300 ]; do
    for f in "$t"/felix-situations.*/tmp-head/started; do [ -e "$f" ] && st=started; done
    [ "$st" = "not started" ] || break
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.1; n=$((n + 1))
  done
  kill -s "$1" "$pid" 2>/dev/null
  n=0
  while kill -0 "$pid" 2>/dev/null && [ "$n" -lt 300 ]; do sleep 0.1; n=$((n + 1)); done
  kill -0 "$pid" 2>/dev/null && kill -s KILL "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null; rc=$?
  now="$(ls -A "$t" 2>&1)"
  [ "$st" = "not started" ] || sleep 4
  later="$(ls -A "$t" 2>&1)"
  S2470_SIG="$st|$rc|$now"; S2470_SIG4="$st|$rc|$later"
}
_s2470_sig TERM
is "2470 rf4 TERM sent once the head side's probe has started: felix situations --change exits 143, and TMPDIR is empty as soon as it has exited" "$S2470_SIG" "started|143|"
is "2470 rf4 TERM: TMPDIR is still empty 4 s later, after the probe's sleep would have ended" "$S2470_SIG4" "started|143|"
_s2470_sig HUP
is "2470 rf4 HUP sent once the head side's probe has started: felix situations --change exits 129, and TMPDIR is empty as soon as it has exited" "$S2470_SIG" "started|129|"
is "2470 rf4 HUP: TMPDIR is still empty 4 s later, after the probe's sleep would have ended" "$S2470_SIG4" "started|129|"
_s2470_sig INT
is "2470 rf4 INT, at its default disposition, sent once the head side's probe has started: felix situations --change exits 130, and TMPDIR is empty as soon as it has exited" "$S2470_SIG" "started|130|"
is "2470 rf4 INT: TMPDIR is still empty 4 s later, after the probe's sleep would have ended" "$S2470_SIG4" "started|130|"
rm -rf "$S2470_D4/pipe.t"; mkdir -p "$S2470_D4/pipe.t"
( cd "$S2470_C4" && exec env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GH_TOKEN -u GITHUB_TOKEN -u CLAUDE_CODE_SESSION_ID \
    -u FELIX_HOME_DIR -u GIT_CONFIG_GLOBAL -u GIT_CONFIG_SYSTEM -u GIT_CONFIG_NOSYSTEM -u XDG_CONFIG_HOME HOME="$S2470_U" \
    PATH="$S2470_D/bin:$PATH" FELIX_HOME="$S2470_D4/home" FELIX_MEMORY="$S2470_D4/mem" TMPDIR="$S2470_D4/pipe.t" \
    "$S2470_E4" situations --change HEAD~1..HEAD ) 2> "$S2470_D4/pipe.err" < /dev/null | head -1 > "$S2470_D4/pipe.out"
is "2470 rf4 felix situations --change ... | head -1 prints the report's first line and leaves TMPDIR empty" \
   "$(cat "$S2470_D4/pipe.out")|$(ls -A "$S2470_D4/pipe.t" 2>&1)" "situations for rf4|"

# ---- RF5: quoting in the admit command ----------------------------------------------------------------------------
# quote_me is ACTIVE and unadmitted; its owes holds an apostrophe, a percent sign, and a backslash and an n as two
# bytes. The home is a git repository with one commit; no maturity is declared. C17.1 puts its newline guard first in
# the admit command, and the last case here leaves the one admitted row with no final newline.
_s2470_dir "$S2470_D/rf5"; S2470_D5="$S2470_P"
S2470_O5="don't drop 100% of the \\n bound"
_s2470_engine "$S2470_D5/x"; S2470_E5="$S2470_E"
_s2470_row "$S2470_D5/x" quote_me 'probe:q=found' "$S2470_O5"
S2470_H5="$S2470_D5/home"; S2470_P5="$S2470_H5/projects/rf5"
_s2470_home "$S2470_H5" rf5 $'q\tq\t-\tcat q.txt\ttest -f q.txt\n'
printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds\n' > "$S2470_P5/obligations.tsv"
_s2470_g "$S2470_H5" 1793000000 init -q -b main
_s2470_commit "$S2470_H5" 1793000000 home
mkdir -p "$S2470_D5/mem/rf5"
S2470_C5="$S2470_D5/c"
_s2470_repo "$S2470_C5" rf5; printf 'one\n' > "$S2470_C5/q.txt"
_s2470_commit "$S2470_C5" 1793000100 c0
_s2470_run "$S2470_D5/p" "$S2470_C5" "$S2470_H5" "$S2470_D5/mem" "$S2470_E5" probes; S2470_PRC="$S2470_RC"
cp "$S2470_P5/obligations.tsv" "$S2470_D5/ob.before"
S2470_ST5="$(GIT_OPTIONAL_LOCKS=0 git -C "$S2470_H5" status --porcelain 2>&1)"
_s2470_run "$S2470_D5/p1" "$S2470_C5" "$S2470_H5" "$S2470_D5/mem" "$S2470_E5" situations --propose; S2470_RA="$S2470_RC"
is "2470 rf5 --propose exits 0 and leaves obligations.tsv and the home's git status --porcelain unchanged" \
   "$S2470_PRC|$S2470_RA|$(cksum < "$S2470_P5/obligations.tsv")|$(GIT_OPTIONAL_LOCKS=0 git -C "$S2470_H5" status --porcelain 2>&1)" \
   "0|0|$(cksum < "$S2470_D5/ob.before")|$S2470_ST5"
_s2470_id quote_me rf5
S2470_ROW5="$(_s2470_tab quote_me RELEASE_BLOCKING unknown - 'exit 2' q "$S2470_O5")"
S2470_ESC="'\\''"; S2470_OB5="'$S2470_P5/obligations.tsv'"
S2470_CMD5="{ [ ! -s $S2470_OB5 ] || [ -z \"\$(tail -c 1 $S2470_OB5)\" ] || printf '\\n'; } >> $S2470_OB5 && printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' 'quote_me' 'RELEASE_BLOCKING' 'unknown' '-' 'exit 2' 'q' 'don${S2470_ESC}t drop 100% of the \\n bound' >> $S2470_OB5 && git -C '$S2470_H5' add -- $S2470_OB5 && git -C '$S2470_H5' commit -q -m 'obligations: admit quote_me' -- $S2470_OB5"
is "2470 rf5 the proposed section ends the report: quote_me with its grounds, the strictest class its cell names while no maturity is declared, its row, and the admit command with each ' written as '\\''" \
   "$S2470_RA|$(tail -n 6 "$S2470_D5/p1.out")" "0|
proposed
  $S2470_ID  quote_me  q found (q)
    class  RELEASE_BLOCKING  maturity undeclared: the strictest class this row names
    row  $S2470_ROW5
    admit  $S2470_CMD5"
# OUT -> S2470_RGOT5, the text after "    row  " in OUT.out, and S2470_ARC, the exit of the admit command OUT.out
# prints, run as C14 runs it, or why it was not run.
_s2470_admit() {
  local c
  c="$(LC_ALL=C awk 'index($0, "    admit  ") == 1 { print substr($0, 12); exit }' "$1.out")"
  S2470_RGOT5="$(LC_ALL=C awk 'index($0, "    row  ") == 1 { print substr($0, 10); exit }' "$1.out")"
  S2470_ARC="not run: no admit command beginning with the newline guard and naming git -C '$S2470_H5' add was printed"
  case "$c" in
    "{ [ ! -s '$S2470_P5/obligations.tsv' ] || "*"git -C '$S2470_H5' add -- "*)
      S2470_ARC="$( cd "$S2470_D5" && env HOME="$S2470_U" GIT_CONFIG_NOSYSTEM=1 GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t \
        GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t bash -c "$c" > /dev/null 2>&1; printf '%s' "$?" )" ;;
  esac
}
_s2470_admit "$S2470_D5/p1"
{ cat "$S2470_D5/ob.before"; printf '%s\n' "$S2470_RGOT5"; } > "$S2470_D5/ob.want"
is "2470 rf5 running the printed admit command appends to obligations.tsv exactly the row line's text after its prefix, then one newline" \
   "$S2470_ARC|$(cmp -s "$S2470_D5/ob.want" "$S2470_P5/obligations.tsv" && printf appended || printf other)|$S2470_RGOT5" \
   "0|appended|$S2470_ROW5"
is "2470 rf5 the admit command makes one commit, which touches only obligations.tsv" \
   "$S2470_ARC|$(git -C "$S2470_H5" rev-list --count HEAD 2>&1)|$(git -C "$S2470_H5" diff-tree --no-commit-id --name-only -r HEAD 2>&1)|$(git -C "$S2470_H5" log -1 --format=%s 2>&1)" \
   "0|2|projects/rf5/obligations.tsv|obligations: admit quote_me"
_s2470_run "$S2470_D5/p2" "$S2470_C5" "$S2470_H5" "$S2470_D5/mem" "$S2470_E5" situations --propose
is "2470 rf5 a second --propose no longer lists quote_me: its proposed section is none" \
   "$S2470_ARC|$S2470_RC|$(tail -n 2 "$S2470_D5/p2.out")" "0|0|proposed
  none"
# C17.1's unended row: obligations.tsv holds the fixture's row alone, with no final newline, committed; quote_me is
# proposed again, and its admit command runs as before.
printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds' > "$S2470_P5/obligations.tsv"
_s2470_commit "$S2470_H5" 1793000200 unended
cp "$S2470_P5/obligations.tsv" "$S2470_D5/ob.unended"
S2470_UC5="$(git -C "$S2470_H5" rev-parse HEAD 2>&1)"
_s2470_run "$S2470_D5/p3" "$S2470_C5" "$S2470_H5" "$S2470_D5/mem" "$S2470_E5" situations --propose; S2470_RA="$S2470_RC"
_s2470_admit "$S2470_D5/p3"
{ cat "$S2470_D5/ob.unended"; printf '\n%s\n' "$S2470_RGOT5"; } > "$S2470_D5/ob.want3"
S2470_OR5="$( { . "$FROOT/harness/lib/obligations.sh" && felix_obligation_rows "$S2470_P5" | LC_ALL=C cut -f1 | tr '\n' ' '; } 2>/dev/null )"
is "2470 rf5 with obligations.tsv's one admitted row unended, the printed admit command ends that row with one newline, then appends the row line's text and one newline" \
   "$S2470_RA|$S2470_ARC|$(cmp -s "$S2470_D5/ob.want3" "$S2470_P5/obligations.tsv" && printf appended || printf other)|$S2470_RGOT5" \
   "0|0|appended|$S2470_ROW5"
is "2470 rf5 with that row unended, felix_obligation_rows names both classes once the admit command has run, the earlier one first" \
   "$S2470_ARC|$S2470_OR5" "0|fixture quote_me "
is "2470 rf5 with that row unended, the admit command makes one commit, which touches only obligations.tsv" \
   "$S2470_ARC|$(git -C "$S2470_H5" rev-list --count "$S2470_UC5..HEAD" 2>&1)|$(git -C "$S2470_H5" diff-tree --no-commit-id --name-only -r HEAD 2>&1)|$(git -C "$S2470_H5" log -1 --format=%s 2>&1)" \
   "0|1|projects/rf5/obligations.tsv|obligations: admit quote_me"

# ---- RF6: the caller's git config ---------------------------------------------------------------------------------
# HOME's .gitconfig sets init.templateDir (a template whose hooks/post-checkout writes a marker), core.hooksPath (a
# directory whose post-checkout writes a marker) and filter.fx.smudge (which writes a marker); the repository's
# .gitattributes holds * filter=fx. svc_owed is owed over c1.
_s2470_dir "$S2470_D/rf6"; S2470_D6="$S2470_P"
_s2470_engine "$S2470_D6/x"; S2470_E6="$S2470_E"
_s2470_row "$S2470_D6/x" svc_owed 'probe:svc=found' "$S2470_O1"
_s2470_home "$S2470_D6/home" rf6 "$S2470_PSVC"
mkdir -p "$S2470_D6/mem/rf6" "$S2470_D6/user" "$S2470_D6/markers" "$S2470_D6/tpl/hooks" "$S2470_D6/hooks"
S2470_K6="$S2470_D6/markers"
printf '#!/bin/sh\n: > '"'"'%s/template'"'"'\n' "$S2470_K6" > "$S2470_D6/tpl/hooks/post-checkout"
printf '#!/bin/sh\n: > '"'"'%s/hookspath'"'"'\n' "$S2470_K6" > "$S2470_D6/hooks/post-checkout"
printf '#!/bin/sh\n: > '"'"'%s/smudge'"'"'\nexec cat\n' "$S2470_K6" > "$S2470_D6/smudge"
chmod +x "$S2470_D6/tpl/hooks/post-checkout" "$S2470_D6/hooks/post-checkout" "$S2470_D6/smudge"
printf '[init]\n\ttemplateDir = %s\n[core]\n\thooksPath = %s\n[filter "fx"]\n\tsmudge = %s\n' \
  "$S2470_D6/tpl" "$S2470_D6/hooks" "$S2470_D6/smudge" > "$S2470_D6/user/.gitconfig"
S2470_C6="$S2470_D6/c"
_s2470_repo "$S2470_C6" rf6; printf '* filter=fx\n' > "$S2470_C6/.gitattributes"; printf 'a\n' > "$S2470_C6/svc.txt"
_s2470_commit "$S2470_C6" 1793000000 c0
printf 'a\nb\n' > "$S2470_C6/svc.txt"
_s2470_commit "$S2470_C6" 1793000100 c1
# The control: a plain clone under that HOME copies the template and runs the hooksPath hook and the smudge filter.
( export HOME="$S2470_D6/user" GIT_CONFIG_NOSYSTEM=1; unset GIT_CONFIG_GLOBAL XDG_CONFIG_HOME
  _fx_git "$S2470_D6" clone -q -- "$S2470_C6" ctl ) > /dev/null 2>&1
S2470_CTL6="$(ls -A "$S2470_K6" 2>&1 | LC_ALL=C sort | tr '\n' ' ')$([ -f "$S2470_D6/ctl/.git/hooks/post-checkout" ] && printf template-copied)"
rm -rf "$S2470_D6/ctl" "$S2470_K6"; mkdir -p "$S2470_K6"
S2470_U="$S2470_D6/user"
_s2470_run "$S2470_D6/r" "$S2470_C6" "$S2470_D6/home" "$S2470_D6/mem" "$S2470_E6" situations --change HEAD~1..HEAD --tsv
S2470_U="$S2470_D/user"
_s2470_id svc_owed rf6
is "2470 rf6 with HOME's .gitconfig naming a template, a hooks path and a smudge filter, --change HEAD~1..HEAD --tsv exits 0 and evaluates its class" \
   "$S2470_CTL6|$S2470_RC|$(cat "$S2470_D6/r.err")|$(cat "$S2470_D6/r.out")" \
   "hookspath smudge template-copied|0||$(_s2470_tab "$S2470_ID" svc_owed owed ACTIVE ACTIVE 'svc found (svc)' 'svc found (svc)' "$S2470_O1")"
is "2470 rf6 no marker of the template hook, the hooks-path hook or the smudge filter exists after the run" \
   "$S2470_CTL6|$S2470_RC|$(ls -A "$S2470_K6" 2>&1)" "hookspath smudge template-copied|0|"
# C17.2: core.fsmonitor names a hook that writes a marker, in a HOME of its own and then through GIT_CONFIG_COUNT; and
# filter.fx.clean, which writes a marker, comes through GIT_CONFIG_PARAMETERS over the committed * filter=fx.
printf '#!/bin/sh\n: > '"'"'%s/fsmonitor'"'"'\nexit 1\n' "$S2470_K6" > "$S2470_D6/fsmonitor"
printf '#!/bin/sh\n: > '"'"'%s/clean'"'"'\nexec cat\n' "$S2470_K6" > "$S2470_D6/clean"
chmod +x "$S2470_D6/fsmonitor" "$S2470_D6/clean"
mkdir -p "$S2470_D6/ufsm"; printf '[core]\n\tfsmonitor = %s\n' "$S2470_D6/fsmonitor" > "$S2470_D6/ufsm/.gitconfig"
_s2470_g "$S2470_D6" 1793000200 clone -q -- "$S2470_C6" ctl
# NAME HOME CONTROL WANT NAME=VALUE... -> git CONTROL in the plain clone ctl, then --change HEAD~1..HEAD --tsv, each
# with HOME and the NAME=VALUE words; NAME asserts that the control left the markers WANT, and that the run exits 0,
# evaluates its class and leaves no marker.
_s2470_rf6() {
  local n="$1" h="$2" a="$3" w="$4" c
  shift 4
  rm -rf "$S2470_K6"; mkdir -p "$S2470_K6"
  ( unset GIT_CONFIG_GLOBAL XDG_CONFIG_HOME GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT
    export HOME="$h" GIT_CONFIG_NOSYSTEM=1 "$@"
    _fx_git "$S2470_D6/ctl" $a ) > /dev/null 2>&1
  c="$(ls -A "$S2470_K6" 2>&1 | tr '\n' ' ')"
  rm -rf "$S2470_K6"; mkdir -p "$S2470_K6"
  S2470_U="$h"; S2470_XE=("$@")
  _s2470_run "$S2470_D6/r2" "$S2470_C6" "$S2470_D6/home" "$S2470_D6/mem" "$S2470_E6" situations --change HEAD~1..HEAD --tsv
  S2470_U="$S2470_D/user"; S2470_XE=(S2470_EXTRA=none)
  is "$n" "$c|$S2470_RC|$(cat "$S2470_D6/r2.err")|$(cat "$S2470_D6/r2.out")|$(ls -A "$S2470_K6" 2>&1)" \
     "$w|0||$(_s2470_tab "$S2470_ID" svc_owed owed ACTIVE ACTIVE 'svc found (svc)' 'svc found (svc)' "$S2470_O1")|"
}
_s2470_rf6 "2470 rf6 with core.fsmonitor in HOME's .gitconfig naming a hook that writes a marker, --change HEAD~1..HEAD --tsv exits 0, evaluates its class, and no marker exists" \
  "$S2470_D6/ufsm" 'status --porcelain' 'fsmonitor ' S2470_EXTRA=none
_s2470_rf6 "2470 rf6 with core.fsmonitor given through GIT_CONFIG_COUNT=1, GIT_CONFIG_KEY_0 and GIT_CONFIG_VALUE_0, --change HEAD~1..HEAD --tsv exits 0, evaluates its class, and no marker exists" \
  "$S2470_D/user" 'status --porcelain' 'fsmonitor ' GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.fsmonitor "GIT_CONFIG_VALUE_0=$S2470_D6/fsmonitor"
_s2470_rf6 "2470 rf6 with filter.fx.clean given through GIT_CONFIG_PARAMETERS over the committed * filter=fx, --change HEAD~1..HEAD --tsv exits 0, evaluates its class, and no marker exists" \
  "$S2470_D/user" 'hash-object svc.txt' 'clean ' "GIT_CONFIG_PARAMETERS='filter.fx.clean=$S2470_D6/clean'"
# C17.11.1: core.quotePath=false in HOME's .gitconfig, and a repository whose second commit adds three .js files under
# web/ with an e-acute in each name, and no package.json. Where git lists those names unquoted, the detector names
# frontend, which no class uses, so the residual holds its no-row line (C10). Under each HOME felix probes first records
# the head tree under a memory root of its own (C13); then --at reads that tree and --change reads HEAD~1..HEAD.
S2470_Q6="$S2470_D6/q"; S2470_EA6=$'\303\251'
_s2470_repo "$S2470_Q6" rf6; printf 'a\n' > "$S2470_Q6/svc.txt"
_s2470_commit "$S2470_Q6" 1793000000 q0
mkdir -p "$S2470_Q6/web"; for _s2470_c in 1 2 3; do printf 'x\n' > "$S2470_Q6/web/$S2470_EA6$_s2470_c.js"; done
_s2470_commit "$S2470_Q6" 1793000100 q1
mkdir -p "$S2470_D6/uqp" "$S2470_D6/qmem/rf6" "$S2470_D6/nmem/rf6"
printf '[core]\n\tquotePath = false\n' > "$S2470_D6/uqp/.gitconfig"
S2470_NR6="$(_s2470_tab residual no-row frontend 'named by the detector')"
# FILE LINE -> yes when LINE is one of FILE's lines, else no.
_s2470_line() { L="$2" LC_ALL=C awk '$0 == ENVIRON["L"] { f = 1 } END { print (f ? "yes" : "no") }' "$1" 2>/dev/null; }
# HOME MEMORY NAME -> S2470_QR: felix probes' exit, then --at's exit and whether the frontend no-row line is one of its
# lines, then the same two for --change, each run in q with that HOME.
_s2470_qp() {
  local h="$1" m="$2" n="$3" p
  S2470_U="$h"
  _s2470_run "$S2470_D6/$n-p" "$S2470_Q6" "$S2470_D6/home" "$m" "$S2470_E6" probes; p="$S2470_RC"
  _s2470_newest "$m/rf6/facts.log"
  _s2470_run "$S2470_D6/$n-a" "$S2470_Q6" "$S2470_D6/home" "$m" "$S2470_E6" situations --at "$S2470_TREE" --tsv
  S2470_QR="$p|$S2470_RC|$(_s2470_line "$S2470_D6/$n-a.out" "$S2470_NR6")"
  _s2470_run "$S2470_D6/$n-c" "$S2470_Q6" "$S2470_D6/home" "$m" "$S2470_E6" situations --change HEAD~1..HEAD --tsv
  S2470_QR="$S2470_QR|$S2470_RC|$(_s2470_line "$S2470_D6/$n-c.out" "$S2470_NR6")"
  S2470_U="$S2470_D/user"
}
_s2470_qp "$S2470_D6/uqp" "$S2470_D6/qmem" qp; S2470_QW="$S2470_QR"
_s2470_qp "$S2470_D/user" "$S2470_D6/nmem" qn
is "2470 rf6 with core.quotePath=false in HOME's .gitconfig and three tracked .js files under web/ with a non-ASCII letter in each name and no package.json, --change HEAD~1..HEAD --tsv names frontend at head with its no-row line, as --at --tsv names it at the recorded tree, and with HOME empty neither names it" \
   "$S2470_QW|$S2470_QR" "0|0|yes|0|yes|0|0|no|0|no"

# ---- RF7: a facts log shared by worktrees -------------------------------------------------------------------------
# W1 and W2, linked worktrees of one repository: W1 at c0, W2 at c1 (svc.txt gains a line). cap_tests (cap:tests) is
# decided by the detector alone, which names tests from the tests/ directory in both.
_s2470_dir "$S2470_D/rf7"; S2470_D7="$S2470_P"
S2470_O7='a test run before every change that touches the tests'
_s2470_engine "$S2470_D7/x"; S2470_E7="$S2470_E"
_s2470_row "$S2470_D7/x" svc_owed 'probe:svc=found' "$S2470_O1"
_s2470_row "$S2470_D7/x" cap_tests 'cap:tests' "$S2470_O7"
_s2470_home "$S2470_D7/home" rf7 "$S2470_PSVC"
mkdir -p "$S2470_D7/mem/rf7"
S2470_R7="$S2470_D7/main"; S2470_V1="$S2470_D7/w1"; S2470_V2="$S2470_D7/w2"
_s2470_repo "$S2470_R7" rf7; printf 'a\n' > "$S2470_R7/svc.txt"; mkdir -p "$S2470_R7/tests"; printf 'true\n' > "$S2470_R7/tests/t.sh"
_s2470_commit "$S2470_R7" 1793000000 c0
_s2470_g "$S2470_R7" 1793000100 worktree add -q -b one "$S2470_V1"
_s2470_g "$S2470_R7" 1793000200 worktree add -q -b two "$S2470_V2"
printf 'a\nb\n' > "$S2470_V2/svc.txt"
_s2470_commit "$S2470_V2" 1793000300 c1
S2470_C7="$(git -C "$S2470_V1" rev-parse HEAD 2>&1)"
_s2470_run "$S2470_D7/p1" "$S2470_V1" "$S2470_D7/home" "$S2470_D7/mem" "$S2470_E7" probes; S2470_PRC="$S2470_RC"
_s2470_newest "$S2470_D7/mem/rf7/facts.log"; S2470_ST1="$S2470_STAMP"; S2470_T1="$S2470_TREE"
_s2470_run "$S2470_D7/p2" "$S2470_V2" "$S2470_D7/home" "$S2470_D7/mem" "$S2470_E7" probes; S2470_PRC="$S2470_PRC $S2470_RC"
_s2470_newest "$S2470_D7/mem/rf7/facts.log"; S2470_ST2="$S2470_STAMP"; S2470_T2="$S2470_TREE"
S2470_TT="trees $([ -n "$S2470_T1" ] && [ "$S2470_T1" != "$S2470_T2" ] && printf distinct || printf 'not distinct')"
_s2470_run "$S2470_D7/hd" "$S2470_V1" "$S2470_D7/home" "$S2470_D7/mem" "$S2470_E7" situations; S2470_RA="$S2470_RC"
_s2470_run "$S2470_D7/td" "$S2470_V1" "$S2470_D7/home" "$S2470_D7/mem" "$S2470_E7" situations --tsv; S2470_RB="$S2470_RC"
_s2470_run "$S2470_D7/ha" "$S2470_V1" "$S2470_D7/home" "$S2470_D7/mem" "$S2470_E7" situations --at "$S2470_T1"; S2470_RC1="$S2470_RC"
_s2470_run "$S2470_D7/ta" "$S2470_V1" "$S2470_D7/home" "$S2470_D7/mem" "$S2470_E7" situations --at "$S2470_T1" --tsv
S2470_RC2="$S2470_RC"
is "2470 rf7 felix situations in W1, after felix probes in W1 then W2, reads W2's tree, the newest, and its header names that tree and ends detector not run: this checkout is not at this tree" \
   "$S2470_TT|$S2470_PRC|$S2470_RA|$(cat "$S2470_D7/hd.err")|$(head -n 2 "$S2470_D7/hd.out")" \
   "trees distinct|0 0|0||situations for rf7
  at  -  tree $S2470_T2  recorded $S2470_ST2  $S2470_NOTAT"
_s2470_id svc_owed rf7; S2470_IS7="$S2470_ID"
_s2470_id cap_tests rf7; S2470_IC7="$S2470_ID"
is "2470 rf7 its --tsv reads cap_tests, which only the detector decides, could-not-look at W2's tree, the residual naming the detector as its why" \
   "$S2470_RB|$(cat "$S2470_D7/td.out")" \
   "0|$(_s2470_tab "$S2470_IS7" svc_owed standing - ACTIVE - 'svc found (svc)' "$S2470_O1")
$(_s2470_tab "$S2470_IC7" cap_tests could-not-look - UNKNOWN - 'tests detector not run' "$S2470_O7")
$(_s2470_tab residual could-not-look cap_tests 'at: cap:tests: no probe grounds tests and the detector was not run: this checkout is not at this tree')"
is "2470 rf7 --at with W1's own tree id runs the detector: the header names W1's HEAD, that tree and its recorded stamp, and says detector run on this checkout" \
   "$S2470_TT|$S2470_RC1|$(cat "$S2470_D7/ha.err")|$(head -n 2 "$S2470_D7/ha.out")" \
   "trees distinct|0||situations for rf7
  at  $S2470_C7  tree $S2470_T1  recorded $S2470_ST1  detector run on this checkout"
is "2470 rf7 --at W1's tree --tsv reads cap_tests standing on tests detected, beside svc_owed, ordered by id" \
   "$S2470_RC2|$(cat "$S2470_D7/ta.out")" \
   "0|$(printf '%s\n%s\n' "$(_s2470_tab "$S2470_IS7" svc_owed standing - ACTIVE - 'svc found (svc)' "$S2470_O1")" \
        "$(_s2470_tab "$S2470_IC7" cap_tests standing - ACTIVE - 'tests detected' "$S2470_O7")" | LC_ALL=C sort)"

# ---- RF8: a stat-dirty index ---------------------------------------------------------------------------------------
# C17.3. After felix probes recorded the live tree, svc.txt's mtime moves to a fixed past time and its content stays,
# so the index's cached stat no longer matches it; then the index's own mtime is set to another fixed past time.
_s2470_dir "$S2470_D/rf8"; S2470_D8="$S2470_P"
_s2470_home "$S2470_D8/home" rf8 "$S2470_PSVC"
mkdir -p "$S2470_D8/mem/rf8"
S2470_C8="$S2470_D8/c"; S2470_I8="$S2470_D8/c/.git/index"
_s2470_repo "$S2470_C8" rf8; printf 'a\n' > "$S2470_C8/svc.txt"
_s2470_commit "$S2470_C8" 1793000000 c0
S2470_HD8="$(git -C "$S2470_C8" rev-parse HEAD 2>&1)"
_s2470_run "$S2470_D8/p" "$S2470_C8" "$S2470_D8/home" "$S2470_D8/mem" "$S2470_E7" probes; S2470_PRC="$S2470_RC"
_s2470_newest "$S2470_D8/mem/rf8/facts.log"
touch -t 202501010000.00 "$S2470_C8/svc.txt"; touch -t 202502020000.00 "$S2470_I8"
S2470_B8="$(cksum < "$S2470_I8" 2>&1)|$(_s2470_mtime "$S2470_I8")"
_s2470_run "$S2470_D8/r" "$S2470_C8" "$S2470_D8/home" "$S2470_D8/mem" "$S2470_E7" situations; S2470_RA="$S2470_RC"
S2470_A8="$(cksum < "$S2470_I8" 2>&1)|$(_s2470_mtime "$S2470_I8")"
_s2470_g "$S2470_C8" 1793000100 status --porcelain
S2470_G8="$(_s2470_mtime "$S2470_I8")"
is "2470 rf8 with a tracked file made stat-dirty after felix probes recorded the tree, felix situations exits 0, and its header names that tree and ends detector run on this checkout" \
   "$S2470_PRC|$S2470_RA|$(cat "$S2470_D8/r.err")|$(LC_ALL=C awk 'NR == 2' "$S2470_D8/r.out")" \
   "0|0||  at  $S2470_HD8  tree $S2470_TREE  recorded $S2470_STAMP  detector run on this checkout"
is "2470 rf8 felix situations leaves the live index's bytes and mtime as they were, though git status run afterwards moves that mtime" \
   "$S2470_RA|$S2470_A8|$([ "$S2470_G8" = "${S2470_B8##*|}" ] && printf 'not moved' || printf moved)" "0|$S2470_B8|moved"

# ---- RF9: a step that fails, and a project table that cannot be read ---------------------------------------------
# C17.4. The sort first on PATH exits 2, printing nothing, when a line it would read begins owed:; otherwise it runs the
# real sort with the same arguments over the same input, which it buffers outside TMPDIR. svc_owed is owed over c1, and
# felix probes recorded c1's tree.
_s2470_dir "$S2470_D/rf9"; S2470_D9="$S2470_P"
S2470_H9="$S2470_D9/home"; S2470_P9="$S2470_D9/home/projects/rf9"
_s2470_home "$S2470_H9" rf9 "$S2470_PSVC"
printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds\n' > "$S2470_P9/obligations.tsv"
mkdir -p "$S2470_D9/mem/rf9" "$S2470_D9/shim" "$S2470_D9/buf"
S2470_C9="$S2470_D9/c"
_s2470_repo "$S2470_C9" rf9; printf 'a\n' > "$S2470_C9/svc.txt"
_s2470_commit "$S2470_C9" 1793000000 c0
printf 'a\nb\n' > "$S2470_C9/svc.txt"
_s2470_commit "$S2470_C9" 1793000100 c1
_s2470_run "$S2470_D9/p" "$S2470_C9" "$S2470_H9" "$S2470_D9/mem" "$S2470_E7" probes; S2470_PRC="$S2470_RC"
_s2470_newest "$S2470_D9/mem/rf9/facts.log"; S2470_T9="$S2470_TREE"
{ printf '#!/bin/sh\n'
  printf "real='%s'; buf='%s'\n" "$(type -P sort)" "$S2470_D9/buf"
  cat <<'S2470SORT'
# sort, first on PATH (C17.4): exit 2, printing nothing, when a line it would read begins owed:; else the real sort.
owed() { awk 'index($0, "owed:") == 1 { f = 1; exit } END { exit !f }' "$@"; }
n=0; stdin=no; skip=no; opts=yes
for a in "$@"; do
  if [ "$skip" = yes ]; then skip=no; continue; fi
  if [ "$opts" = yes ]; then
    case "$a" in
      --) opts=no; continue ;;
      -t|-k|-o|-T|-S|--field-separator|--key|--output|--temporary-directory|--buffer-size) skip=yes; continue ;;
      -?*) continue ;;
    esac
  fi
  n=$((n + 1))
  if [ "$a" = - ]; then stdin=yes; elif [ -f "$a" ] && owed "$a"; then exit 2; fi
done
[ "$n" -gt 0 ] || stdin=yes
[ "$stdin" = yes ] || exec "$real" "$@"
f="$(mktemp "$buf/in.XXXXXX")" || exit 2
cat > "$f" || { rm -f "$f"; exit 2; }
if owed "$f"; then rm -f "$f"; exit 2; fi
"$real" "$@" < "$f"; rc=$?
rm -f "$f"
exit "$rc"
S2470SORT
} > "$S2470_D9/shim/sort"
chmod +x "$S2470_D9/shim/sort"
# The control: the shim sorts input that holds no owed: line, and fails, printing nothing, on input that holds one,
# from stdin and from a file operand: S2470_SH9 is the three exits, then all they printed.
printf 'b\na\n' > "$S2470_D9/plain.in"; printf 'x\nowed:1\n' > "$S2470_D9/mixed.in"; printf 'owed:2\n' > "$S2470_D9/owed.in"
LC_ALL=C "$S2470_D9/shim/sort" < "$S2470_D9/plain.in" > "$S2470_D9/c1.out" 2>&1; S2470_SH9="$?"
LC_ALL=C "$S2470_D9/shim/sort" < "$S2470_D9/mixed.in" > "$S2470_D9/c2.out" 2>&1; S2470_SH9="$S2470_SH9 $?"
LC_ALL=C "$S2470_D9/shim/sort" -t x -k1,1 "$S2470_D9/owed.in" > "$S2470_D9/c3.out" 2>&1; S2470_SH9="$S2470_SH9 $?"
S2470_SH9="$S2470_SH9|$(cat "$S2470_D9/c1.out" "$S2470_D9/c2.out" "$S2470_D9/c3.out" | tr '\n' ' ')"
# OUT -> exit|stdout bytes|stderr lines|yes when stderr's first line is C17.4's report sentence|TMPDIR's entries.
_s2470_x3() {
  local f
  f="$(LC_ALL=C awk 'NR == 1' "$1.err" 2>/dev/null)"
  case "$f" in "felix situations: the report could not be built: "?*" failed") f=yes ;; *) f="no: $f" ;; esac
  printf '%s|%s|%s|%s|%s' "$S2470_RC" "$(wc -c < "$1.out" | tr -d ' ')" "$(LC_ALL=C awk 'END { print NR }' "$1.err")" "$f" \
    "$(ls -A "$1.t" 2>&1)"
}
S2470_XE=("PATH=$S2470_D9/shim:$S2470_D/bin:$PATH")
_s2470_run "$S2470_D9/sa" "$S2470_C9" "$S2470_H9" "$S2470_D9/mem" "$S2470_E7" situations --at "$S2470_T9"
S2470_SA="$(_s2470_x3 "$S2470_D9/sa")"
_s2470_run "$S2470_D9/sc" "$S2470_C9" "$S2470_H9" "$S2470_D9/mem" "$S2470_E7" situations --change HEAD~1..HEAD
S2470_SC="$(_s2470_x3 "$S2470_D9/sc")"
S2470_XE=(S2470_EXTRA=none)
is "2470 rf9 --at with a sort first on PATH that fails when it reads a line beginning owed: exits 3, stdout empty, one stderr line, felix situations: the report could not be built: <step> failed, and TMPDIR empty" \
   "$S2470_PRC|$S2470_SH9|$S2470_SA" "0|0 2 2|a b |3|0|1|yes|"
is "2470 rf9 --change with that sort first on PATH exits 3 the same way: stdout empty, one stderr line, the report could not be built, and TMPDIR empty" \
   "$S2470_SH9|$S2470_SC" "0 2 2|a b |3|0|1|yes|"
# FILE NAME SENTENCE ARGS... -> with FILE made unreadable, felix situations ARGS exits 3, stdout empty, SENTENCE alone on
# stderr and TMPDIR empty; skipped by NAME when FILE stays readable, as it does when the suite runs as root.
_s2470_unread() {
  local f="$1" n="$2" w="$3"
  shift 3
  chmod 000 "$f"
  if [ -r "$f" ]; then
    skip "$n" "$f stays readable after chmod 000, as it does when the suite runs as root"
  else
    _s2470_run "$S2470_D9/ur" "$S2470_C9" "$S2470_H9" "$S2470_D9/mem" "$S2470_E7" situations "$@"
    is "$n" "$S2470_RC|$(wc -c < "$S2470_D9/ur.out" | tr -d ' ')|$(cat "$S2470_D9/ur.err")|$(ls -A "$S2470_D9/ur.t" 2>&1)" "3|0|$w|"
  fi
  chmod 644 "$f"
}
S2470_UP="felix situations: the project's probes.tsv could not be read: $S2470_P9/probes.tsv is not readable"
S2470_UO="felix situations: the project's obligations.tsv could not be read: $S2470_P9/obligations.tsv is not readable"
_s2470_unread "$S2470_P9/probes.tsv" "2470 rf9 with probes.tsv made unreadable, --at exits 3, stdout empty, the project's probes.tsv sentence alone on stderr, and TMPDIR empty" \
  "$S2470_UP" --at "$S2470_T9"
_s2470_unread "$S2470_P9/probes.tsv" "2470 rf9 with probes.tsv made unreadable, --change exits 3, stdout empty, the project's probes.tsv sentence alone on stderr, and TMPDIR empty" \
  "$S2470_UP" --change HEAD~1..HEAD
_s2470_unread "$S2470_P9/obligations.tsv" "2470 rf9 with obligations.tsv made unreadable, --at --propose exits 3, stdout empty, the project's obligations.tsv sentence alone on stderr, and TMPDIR empty" \
  "$S2470_UO" --at "$S2470_T9" --propose
_s2470_unread "$S2470_P9/obligations.tsv" "2470 rf9 with obligations.tsv made unreadable, --change --propose exits 3, stdout empty, the project's obligations.tsv sentence alone on stderr, and TMPDIR empty" \
  "$S2470_UO" --change HEAD~1..HEAD --propose
# C17.11.3. The mktemp first on PATH runs the real one; when what that made is a directory named felix-situations.*,
# the run's scratch directory (C3.3), it makes an empty live-index in it with mode 400, so the copy of the live index
# into it fails. The control: through the shim, a directory named felix-situations.* holds live-index, mode 400, and
# one named otherwise holds nothing. S2470_MK9 is both exits, then each directory's entries, then live-index's mode.
mkdir -p "$S2470_D9/mshim" "$S2470_D9/mkc"
{ printf '#!/bin/sh\n'
  printf "real='%s'\n" "$(type -P mktemp)"
  cat <<'S2470MKTEMP'
# mktemp, first on PATH (C17.11.3): the real mktemp; then, when what it made is a directory named felix-situations.*,
# an empty live-index in it with mode 400.
out="$("$real" "$@")" || exit "$?"
printf '%s\n' "$out"
case "${out##*/}" in
  felix-situations.*) if [ -d "$out" ]; then : > "$out/live-index" && chmod 400 "$out/live-index"; fi ;;
esac
exit 0
S2470MKTEMP
} > "$S2470_D9/mshim/mktemp"
chmod +x "$S2470_D9/mshim/mktemp"
S2470_MA9="$("$S2470_D9/mshim/mktemp" -d "$S2470_D9/mkc/felix-situations.XXXXXX" 2>&1)"; S2470_MK9="$?"
S2470_MB9="$("$S2470_D9/mshim/mktemp" -d "$S2470_D9/mkc/other.XXXXXX" 2>&1)"; S2470_MK9="$S2470_MK9 $?"
S2470_MK9="$S2470_MK9|$(ls -A "$S2470_MA9" 2>&1)|$(ls -A "$S2470_MB9" 2>&1)|$(ls -l "$S2470_MA9/live-index" 2>&1 | cut -c1-10)"
S2470_N9M="2470 rf9 with a mktemp first on PATH that makes live-index, mode 400, in the run's scratch directory, --at exits 3, stdout empty, one stderr line, felix situations: the report could not be built: <step> failed, and TMPDIR empty"
if [ -w "$S2470_MA9/live-index" ]; then
  skip "$S2470_N9M" "live-index stays writable at mode 400, as it does when the suite runs as root"
else
  S2470_XE=("PATH=$S2470_D9/mshim:$S2470_D/bin:$PATH")
  _s2470_run "$S2470_D9/mk" "$S2470_C9" "$S2470_H9" "$S2470_D9/mem" "$S2470_E7" situations --at "$S2470_T9"
  S2470_XE=(S2470_EXTRA=none)
  is "$S2470_N9M" "$S2470_MK9|$(_s2470_x3 "$S2470_D9/mk")" "0 0|live-index||-r--------|3|0|1|yes|"
fi
