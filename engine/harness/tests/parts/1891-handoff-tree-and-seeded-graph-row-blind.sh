printf '\nthe handoff says what git said about the tree, and the seeded graph row is due only with a graph to keep current (audit b14, C058 and C118, blind)\n'
# Written blind on 2026-10-24 from the contract alone
# (docs/2026-10-24-audit-fixes/b14-lessons-handoff-and-maintenance-records.md:
# B13 to B29, and section 4's fixtures H and G with A16 to A42), before the fix
# and without reading the handoff, maintenance or hook code, the CLI or the
# template's check: felix, the session-start hook and felix_maint_status are run
# as black boxes, and the template row is only read for its shape (A40, A41).
#
# C058: `felix handoff` read the tree with `git status --short`, its stderr
# dropped and its status ignored, so a tree git could not read was "clean", and
# under status.branch=true a clean tree was "dirty" with `## main` for its list.
# The rule: the tree is read with porcelain status through the fail-closed
# reader, and when that read fails the handoff says it does not know, with
# git's reason. C118: the template's graphify row was due forever in a project
# with no graph. The rule: no graph beside the common git dir is not due; a
# graph older than the last commit that touches what it models is due; a check
# that cannot ask git is due.
#
# Fixture H: a home with project hof, a memory of its own, and a bound
# repository per case (HC HD HB HBD HX HW), each committed through _fx_cd and
# set up after its commit, plus HN, a bound directory outside any repository.
# SESSION_HANDOFF.md is removed before each case's handoff and copied aside
# after it; the Uncommitted block is read from `## Uncommitted` up to, not
# including, `## Recent`. Fixture G: a home with project gro whose
# maintenance.tsv is the shipped template copied whole, no capabilities file,
# and the repositories G1 to GD. "Library status" is felix_maint_status read as
# part 0450's _mst reads it (resolve.sh, detect.sh, maintenance.sh, then the
# call), with GIT_DIR and GIT_WORK_TREE unset, in a bash of the suite's own
# under the suite's options. Readings of mine: a `## main` branch line is a
# line that is `## main` or begins `## main...`; an assertion that a text is
# absent also asks that the output, or the block, was there to read, so an
# empty one never reads as a pass. Every assertion is emitted on every run;
# when a fixture could not be built, each assertion resting on it FAILs and
# says why. Every felix, hook and library call runs under a 120 s alarm.

# ---- shared readers
# FILE MODE TEXT -> yes when a line of FILE is TEXT (line), begins with it
# (begins) or holds it (holds); no otherwise, a missing FILE included.
_b14h_q() {
  LC_ALL=C awk -v m="$2" -v t="$3" '(m == "line" && $0 == t) || (m == "begins" && index($0, t) == 1) || (m == "holds" && index($0, t)) { f = 1; exit }
    END { print (f ? "yes" : "no") }' "$1" 2>/dev/null || printf 'no'
}
_b14h_flat() { cat "$1" 2>/dev/null | LC_ALL=C tr '\n' '|' | cut -c1-500; }
_b14h_nonempty() { if [ -s "$1" ]; then printf yes; else printf no; fi; }
# GOT WANT WHAT: WHAT joins _b14h_v, the clauses that failed, unless GOT is WANT.
_b14h_want() { [ "$1" = "$2" ] || _b14h_v="${_b14h_v:+$_b14h_v; }$3"; }
# NAME FIXTURE-ERROR DETAIL: the assertion, from _b14h_v.
_b14h_ck() {
  if [ -n "$2" ]; then bad "$1" "the fixture was not built: $2"
  elif [ -z "$_b14h_v" ]; then ok "$1"
  else bad "$1" "$_b14h_v. $3"; fi
}
# The JSON a hook printed, read with python3's json: the whole output first, then
# the first object found in it. KEY ctx is hookSpecificOutput.additionalContext,
# KEY sys is systemMessage.
_b14h_py='import json, sys
t = open(sys.argv[1], "rb").read().decode("utf-8", "replace")
d = None
try:
    d = json.loads(t)
except Exception:
    dec = json.JSONDecoder(); i = t.find("{")
    while i != -1 and not isinstance(d, dict):
        try:
            d = dec.raw_decode(t, i)[0]
        except Exception:
            d = None
        i = t.find("{", i + 1)
if not isinstance(d, dict):
    sys.exit(3)
if sys.argv[2] == "ctx":
    h = d.get("hookSpecificOutput")
    v = h.get("additionalContext") if isinstance(h, dict) else None
else:
    v = d.get("systemMessage")
if not isinstance(v, str):
    sys.exit(4)
sys.stdout.buffer.write((v if v.endswith("\n") else v + "\n").encode("utf-8"))'

# ---- fixture H
_b14h_fx0=""
_b14h_X="$(mktemp -d "$TMP/b14h.XXXXXX" 2>/dev/null)"
if [ -n "$_b14h_X" ] && [ -d "$_b14h_X" ]; then _b14h_X="$(cd "$_b14h_X" && pwd -P)"
else _b14h_fx0="mktemp -d under \$TMP made no directory"; _b14h_X="$TMP/b14h-not-made"; fi
_b14h_H="$_b14h_X/home"; _b14h_M="$_b14h_X/mem"; _b14h_O="$_b14h_X/out"; _b14h_B="$_b14h_X/bin"
_b14h_HF="$_b14h_M/hof/SESSION_HANDOFF.md"
if [ -z "$_b14h_fx0" ]; then
  mkdir -p "$_b14h_H/projects/hof" "$_b14h_M/hof" "$_b14h_O" "$_b14h_B" 2>/dev/null \
    && printf '{"name":"hof","remote_match":"example.invalid/hof-marker-only","gate":"true"}\n' > "$_b14h_H/projects/hof/project.json" \
    && printf '# hof\n' > "$_b14h_H/projects/hof/CLAUDE.md" \
    || _b14h_fx0="the fixture home under $_b14h_X could not be written"
fi
# CASE DIR -> 0 when DIR is a bound repository of hof (.felix and a.txt, one
# commit of both); else 1, and _b14h_e says why.
_b14h_new() {
  _b14h_e="$_b14h_fx0"; [ -z "$_b14h_e" ] || return 1
  mkdir -p "$2" 2>/dev/null \
    && ( _fx_cd "$2" && git init -q -b main && printf 'hof\n' > .felix && printf 'a\n' > a.txt && git add .felix a.txt \
         && git -c user.name=hof -c user.email=hof@example.invalid -c commit.gpgsign=false commit -qm init ) >/dev/null 2>&1 \
    && return 0
  _b14h_e="the bound repository for $1 ($2) could not be made"; return 1
}
_b14h_hc="$_b14h_X/hc"; _b14h_hd="$_b14h_X/hd"; _b14h_hb="$_b14h_X/hb"; _b14h_hbd="$_b14h_X/hbd"
_b14h_hx="$_b14h_X/hx"; _b14h_hw="$_b14h_X/hw"; _b14h_hn="$_b14h_X/plain"
_b14h_new HC "$_b14h_hc" && { printf 'u\n' > "$_b14h_hc/u.txt" || _b14h_e="u.txt could not be written in HC"; }
_b14h_eHC="$_b14h_e"
_b14h_new HD "$_b14h_hd" && { { printf 'b\n' >> "$_b14h_hd/a.txt" && printf 'n\n' > "$_b14h_hd/n.txt" \
  && _fx_git "$_b14h_hd" add n.txt >/dev/null 2>&1; } || _b14h_e="the edit to a.txt or the staged n.txt could not be made in HD"; }
_b14h_eHD="$_b14h_e"
_b14h_new HB "$_b14h_hb" && { _fx_git "$_b14h_hb" config status.branch true >/dev/null 2>&1 || _b14h_e="status.branch could not be set in HB"; }
_b14h_eHB="$_b14h_e"
_b14h_new HBD "$_b14h_hbd" && { { _fx_git "$_b14h_hbd" config status.branch true >/dev/null 2>&1 && printf 'b\n' >> "$_b14h_hbd/a.txt"; } \
  || _b14h_e="status.branch or the edit to a.txt could not be made in HBD"; }
_b14h_eHBD="$_b14h_e"
if _b14h_new HX "$_b14h_hx"; then
  { printf 'b\n' >> "$_b14h_hx/a.txt" && printf garbage > "$_b14h_hx/.git/index"; } 2>/dev/null || _b14h_e="the edit or the overwritten index could not be made in HX"
  [ -n "$_b14h_e" ] || ! ( _fx_cd "$_b14h_hx" && git status --porcelain ) >/dev/null 2>&1 \
    || _b14h_e="git status still reads the tree in HX after its index was overwritten"
fi
_b14h_eHX="$_b14h_e"
# HW: a git first on PATH that exits 1, printing nothing, when any argument is
# exactly `status`, and execs the real git otherwise.
_b14h_realgit="$(command -v git 2>/dev/null)"
if _b14h_new HW "$_b14h_hw"; then
  { printf '#!/bin/sh\n'
    printf 'for a in "$@"; do [ "$a" = status ] && exit 1; done\n'
    printf "exec '%s' \"\$@\"\n" "$_b14h_realgit"
  } > "$_b14h_B/git" 2>/dev/null && chmod +x "$_b14h_B/git" 2>/dev/null || _b14h_e="the git wrapper could not be written in $_b14h_B"
  if [ -z "$_b14h_e" ]; then
    _b14h_s="$( PATH="$_b14h_B:$PATH"; _fx_cd "$_b14h_hw" && git status --porcelain 2>&1 )"; _b14h_r=$?
    _b14h_g="$( PATH="$_b14h_B:$PATH"; _fx_cd "$_b14h_hw" && git rev-parse --git-dir 2>/dev/null )"
    { [ "$_b14h_r" -eq 1 ] && [ -z "$_b14h_s" ] && [ -n "$_b14h_g" ]; } \
      || _b14h_e="the git wrapper does not fail status silently and pass the rest (status exited $_b14h_r with [$_b14h_s]; rev-parse gave [$_b14h_g])"
  fi
fi
_b14h_eHW="$_b14h_e"
_b14h_eHN="$_b14h_fx0"
if [ -z "$_b14h_eHN" ]; then
  mkdir -p "$_b14h_hn" 2>/dev/null && printf 'hof\n' > "$_b14h_hn/.felix" 2>/dev/null || _b14h_eHN="$_b14h_hn could not be made"
fi
if [ -z "$_b14h_eHN" ]; then
  _b14h_s="$( cd "$_b14h_hn" && LC_ALL=C git rev-parse --git-dir 2>&1 )"; _b14h_r=$?
  case "$_b14h_r:$_b14h_s" in 128:*"not a git repository"*) ;; *) _b14h_eHN="$_b14h_hn is inside a repository after all ($_b14h_r: $_b14h_s)" ;; esac
fi

# CASE DIR [NAME=VALUE...]: felix handoff in DIR, SESSION_HANDOFF.md removed first;
# out/CASE.out, out/CASE.rc, the file copied to out/CASE.md, its block to out/CASE.blk.
_b14h_hand() {
  local t="$1" d="$2"; shift 2
  rm -f "$_b14h_HF" "$_b14h_O/$t.md" "$_b14h_O/$t.blk" 2>/dev/null
  ( [ -n "$d" ] && cd "$d" || exit 125
    perl -e 'alarm shift; exec @ARGV or exit 127' 120 \
      env -u CLAUDE_CODE_REMOTE -u CLAUDE_CODE_SESSION_ID FELIX_HOME="$_b14h_H" FELIX_MEMORY="$_b14h_M" "$@" "$FELIX" handoff < /dev/null ) \
    > "$_b14h_O/$t.out" 2>&1
  printf '%s\n' "$?" > "$_b14h_O/$t.rc" 2>/dev/null
  [ ! -f "$_b14h_HF" ] || cp "$_b14h_HF" "$_b14h_O/$t.md" 2>/dev/null
  LC_ALL=C awk 'on && index($0, "## Recent") == 1 { exit } index($0, "## Uncommitted") == 1 { on = 1 } on { print }' \
    "$_b14h_O/$t.md" > "$_b14h_O/$t.blk" 2>/dev/null
}
_b14h_rc() { cat "$_b14h_O/$1.rc" 2>/dev/null || printf 'none'; }
_b14h_hand HC "$_b14h_hc"
_b14h_hand HD "$_b14h_hd"
_b14h_hand HB "$_b14h_hb"
_b14h_hand HBD "$_b14h_hbd"
_b14h_hand HX "$_b14h_hx"
_b14h_hand HW "$_b14h_hw" PATH="$_b14h_B:$PATH"
_b14h_hand HN "$_b14h_hn"
_b14h_seen() { printf '%s printed [%s]; its block: [%s]' "$1" "$(_b14h_flat "$_b14h_O/$1.out")" "$(_b14h_flat "$_b14h_O/$1.blk")"; }
_b14h_branch() { if [ "$(_b14h_q "$1" line '## main')$(_b14h_q "$1" begins '## main...')" = nono ]; then printf no; else printf yes; fi; }
_b14h_CLEAN='  [x] tree is clean'
_b14h_DIRTY='  [ ] the tree is dirty; commit it or say in the devlog why not'
_b14h_NK='  [?] whether the tree is clean is not known'
_b14h_NOTHING='Nothing. The tree is clean.'

# ---- A16 to A27
_b14h_v=""
_b14h_want "$(_b14h_q "$_b14h_O/HC.out" begins "$_b14h_CLEAN")" yes "felix handoff printed no line beginning [$_b14h_CLEAN]"
_b14h_want "$(_b14h_q "$_b14h_O/HC.blk" holds "$_b14h_NOTHING")" yes "the Uncommitted block does not hold [$_b14h_NOTHING]"
_b14h_want "$(_b14h_q "$_b14h_O/HC.blk" holds u.txt)" no "the Uncommitted block names u.txt"
_b14h_ck "handoff tree: a tree whose only change is untracked is clean on the list and in the file" "$_b14h_eHC" "$(_b14h_seen HC)"
_b14h_v=""
_b14h_want "$(_b14h_q "$_b14h_O/HD.out" begins "$_b14h_DIRTY")" yes "felix handoff printed no line beginning [$_b14h_DIRTY]"
_b14h_want "$(_b14h_q "$_b14h_O/HD.blk" line ' M a.txt')" yes "the Uncommitted block has no line [ M a.txt]"
_b14h_want "$(_b14h_q "$_b14h_O/HD.blk" line 'A  n.txt')" yes "the Uncommitted block has no line [A  n.txt]"
_b14h_ck "handoff tree: a tracked edit and a staged new file are dirty on the list and listed in the file" "$_b14h_eHD" "$(_b14h_seen HD)"
_b14h_v=""
_b14h_want "$(_b14h_q "$_b14h_O/HB.out" begins "$_b14h_CLEAN")" yes "felix handoff printed no line beginning [$_b14h_CLEAN]"
_b14h_want "$(_b14h_q "$_b14h_O/HB.out" holds 'the tree is dirty')" no "felix handoff says the tree is dirty"
_b14h_ck "handoff tree: with status.branch on, a clean tree is clean on the list" "$_b14h_eHB" "$(_b14h_seen HB)"
_b14h_v=""
_b14h_want "$(_b14h_q "$_b14h_O/HB.blk" holds "$_b14h_NOTHING")" yes "the Uncommitted block does not hold [$_b14h_NOTHING]"
_b14h_want "$(_b14h_branch "$_b14h_O/HB.blk")" no "a line of the Uncommitted block is the branch line [## main]"
_b14h_ck "handoff tree: and its file says the tree is clean, with no branch line" "$_b14h_eHB" "$(_b14h_seen HB)"
_b14h_v=""
_b14h_want "$(_b14h_q "$_b14h_O/HBD.blk" line ' M a.txt')" yes "the Uncommitted block has no line [ M a.txt]"
_b14h_want "$(_b14h_branch "$_b14h_O/HBD.blk")" no "a line of the Uncommitted block is the branch line [## main]"
_b14h_ck "handoff tree: with status.branch on, an edited tree's file lists the edit and no branch line" "$_b14h_eHBD" "$(_b14h_seen HBD)"
_b14h_v=""
_b14h_s="$(LC_ALL=C awk -v p="$_b14h_NK: " 'index($0, p) == 1 { print substr($0, length(p) + 1); f = 1; exit } END { if (!f) print "(no such line)" }' "$_b14h_O/HX.out" 2>/dev/null)"
case "$_b14h_s" in "(no such line)"|"") _b14h_want no yes "felix handoff printed no line beginning [$_b14h_NK: ]" ;;
  *fatal:*index*|*index*fatal:*) ;;
  *) _b14h_want no yes "the reason [$_b14h_s] does not hold both [fatal:] and [index]" ;;
esac
_b14h_ck "handoff tree: with an index git cannot read, the list says whether the tree is clean is not known, with git's reason" "$_b14h_eHX" "$(_b14h_seen HX)"
_b14h_v=""
_b14h_want "$(_b14h_nonempty "$_b14h_O/HX.out")" yes "felix handoff printed nothing, so the absence of a claim says nothing"
_b14h_want "$(_b14h_q "$_b14h_O/HX.out" holds '[x] tree is clean')" no "felix handoff says [x] tree is clean"
_b14h_want "$(_b14h_q "$_b14h_O/HX.out" holds 'the tree is dirty')" no "felix handoff says the tree is dirty"
_b14h_ck "handoff tree: and claims neither clean nor dirty" "$_b14h_eHX" "$(_b14h_seen HX)"
_b14h_v=""
_b14h_want "$(_b14h_q "$_b14h_O/HX.blk" begins 'Whether the tree is clean is not known: ')" yes "the Uncommitted block has no line beginning [Whether the tree is clean is not known: ]"
_b14h_want "$(_b14h_q "$_b14h_O/HX.blk" begins '```')" no "the Uncommitted block holds a fenced list"
_b14h_want "$(_b14h_q "$_b14h_O/HX.blk" holds "$_b14h_NOTHING")" no "the Uncommitted block says [$_b14h_NOTHING]"
_b14h_ck "handoff tree: and its file says not known, with no list and no clean claim" "$_b14h_eHX" "$(_b14h_seen HX)"
_b14h_v=""
_b14h_want "$(_b14h_rc HX)" 0 "felix handoff exited $(_b14h_rc HX)"
_b14h_want "$(LC_ALL=C awk 'NR == 1 { print; exit }' "$_b14h_O/HX.md" 2>/dev/null)" '# Handoff' "line 1 of SESSION_HANDOFF.md is not [# Handoff]"
_b14h_want "$(LC_ALL=C awk 'NR == 3 { print (index($0, "Regenerated ") == 1 ? "yes" : "no"); exit }' "$_b14h_O/HX.md" 2>/dev/null)" yes "line 3 of SESSION_HANDOFF.md does not begin [Regenerated ]"
_b14h_ck "handoff tree: and felix handoff still writes the file and exits 0" "$_b14h_eHX" \
  "$(_b14h_seen HX); the file: [$(_b14h_flat "$_b14h_O/HX.md")]"
_b14h_v=""
_b14h_want "$(_b14h_q "$_b14h_O/HW.out" line "$_b14h_NK: git status did not finish")" yes "felix handoff printed no line [$_b14h_NK: git status did not finish]"
_b14h_want "$(_b14h_q "$_b14h_O/HW.out" holds '[x] tree is clean')" no "felix handoff says [x] tree is clean"
_b14h_ck "handoff tree: a status that fails with no words is not known, because git status did not finish" "$_b14h_eHW" "$(_b14h_seen HW)"
_b14h_v=""
_b14h_want "$(_b14h_q "$_b14h_O/HN.out" begins "$_b14h_NK")" yes "felix handoff printed no line beginning [$_b14h_NK]"
_b14h_want "$(_b14h_q "$_b14h_O/HN.out" holds '[x] tree is clean')" no "felix handoff says [x] tree is clean"
_b14h_want "$(_b14h_nonempty "$_b14h_O/HN.blk")" yes "SESSION_HANDOFF.md has no Uncommitted block to read"
_b14h_want "$(_b14h_q "$_b14h_O/HN.blk" holds "$_b14h_NOTHING")" no "the Uncommitted block says [$_b14h_NOTHING]"
_b14h_ck "handoff tree: a bound directory outside git is not known, never clean" "$_b14h_eHN" "$(_b14h_seen HN)"
_b14h_v=""
_b14h_s="$(_b14h_rc HC) $(_b14h_rc HD) $(_b14h_rc HB) $(_b14h_rc HBD) $(_b14h_rc HW) $(_b14h_rc HN)"
_b14h_want "$_b14h_s" '0 0 0 0 0 0' "the exit statuses of HC, HD, HB, HBD, HW and HN are [$_b14h_s]"
_b14h_e="$_b14h_eHC"; for _b14h_i in "$_b14h_eHD" "$_b14h_eHB" "$_b14h_eHBD" "$_b14h_eHW" "$_b14h_eHN"; do _b14h_e="${_b14h_e:-$_b14h_i}"; done
_b14h_ck "handoff tree: felix handoff exits 0 in every case above" "$_b14h_e" "the cases' outputs are in $_b14h_O"

# ---- fixture G
_b14g_fx0=""
_b14g_X="$(mktemp -d "$TMP/b14g.XXXXXX" 2>/dev/null)"
if [ -n "$_b14g_X" ] && [ -d "$_b14g_X" ]; then _b14g_X="$(cd "$_b14g_X" && pwd -P)"
else _b14g_fx0="mktemp -d under \$TMP made no directory"; _b14g_X="$TMP/b14g-not-made"; fi
_b14g_H="$_b14g_X/home"; _b14g_P="$_b14g_H/projects/gro"; _b14g_M="$_b14g_X/mem"; _b14g_O="$_b14g_X/out"
_b14g_T="$FROOT/harness/templates/maintenance.tsv"
if [ -z "$_b14g_fx0" ]; then
  mkdir -p "$_b14g_P" "$_b14g_M/gro" "$_b14g_O" 2>/dev/null \
    && printf '{"name":"gro","remote_match":"example.invalid/gro-marker-only","gate":"true"}\n' > "$_b14g_P/project.json" \
    && printf '# gro\n' > "$_b14g_P/CLAUDE.md" \
    || _b14g_fx0="the fixture home under $_b14g_X could not be written"
fi
if [ -z "$_b14g_fx0" ]; then
  if [ -f "$_b14g_T" ]; then cp "$_b14g_T" "$_b14g_P/maintenance.tsv" 2>/dev/null || _b14g_fx0="the template could not be copied into gro"
  else _b14g_fx0="there is no $_b14g_T"; fi
fi
# KIND DIR -> 0 when DIR is made: bound (.felix of gro and a.txt, one commit),
# notes (one commit adding only notes.md), init (git init only) or plain.
_b14g_mk() {
  mkdir -p "$2" 2>/dev/null || return 1
  case "$1" in
    plain) return 0 ;;
    init) ( _fx_cd "$2" && git init -q -b main ) >/dev/null 2>&1 ;;
    bound) ( _fx_cd "$2" && git init -q -b main && printf 'gro\n' > .felix && printf 'a\n' > a.txt && git add .felix a.txt \
             && git -c user.name=gro -c user.email=gro@example.invalid -c commit.gpgsign=false commit -qm init ) >/dev/null 2>&1 ;;
    notes) ( _fx_cd "$2" && git init -q -b main && printf 'notes\n' > notes.md && git add notes.md \
             && git -c user.name=gro -c user.email=gro@example.invalid -c commit.gpgsign=false commit -qm notes ) >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}
# DIR [STAMP]: graphify-out/graph.json holding {}, with the mtime STAMP (touch -t) when given.
_b14g_graph() {
  mkdir -p "$1/graphify-out" 2>/dev/null && printf '{}\n' > "$1/graphify-out/graph.json" 2>/dev/null || return 1
  [ -z "${2:-}" ] || touch -t "$2" "$1/graphify-out/graph.json" 2>/dev/null
}
# NAME KIND DIR [STAMP]: _b14g_e is empty when DIR is made (with a graph when STAMP is given, - for now), else why not.
_b14g_new() {
  _b14g_e="$_b14g_fx0"; [ -z "$_b14g_e" ] || return 1
  _b14g_mk "$2" "$3" || { _b14g_e="$1 ($3) could not be made"; return 1; }
  if [ -n "${4:-}" ]; then
    if [ "$4" = - ]; then _b14g_graph "$3" || _b14g_e="the graph in $1 could not be written"
    else _b14g_graph "$3" "$4" || _b14g_e="the graph in $1 could not be written with the time $4"; fi
  fi
  [ -z "$_b14g_e" ]
}
# NAME DIR -> _b14g_e says so when DIR is inside a repository.
_b14g_outside() {
  [ -n "$_b14g_e" ] && return 0
  _b14g_s="$( cd "$2" && LC_ALL=C git rev-parse --git-dir 2>&1 )"; _b14g_r=$?
  case "$_b14g_r:$_b14g_s" in 128:*"not a git repository"*) ;; *) _b14g_e="$1 is inside a repository after all ($_b14g_r: $_b14g_s)" ;; esac
}
_b14g_g1="$_b14g_X/g1"; _b14g_g2="$_b14g_X/g2"; _b14g_g3="$_b14g_X/g3"; _b14g_g3w="$_b14g_X/g3w"
_b14g_g4="$_b14g_X/g4"; _b14g_g4w="$_b14g_X/g4w"; _b14g_gu="$_b14g_X/gu"; _b14g_gug="$_b14g_X/gug"
_b14g_gn="$_b14g_X/gn"; _b14g_gng="$_b14g_X/gng"; _b14g_gd="$_b14g_X/gd"
_b14g_new G1 bound "$_b14g_g1"; _b14g_e1="$_b14g_e"
_b14g_new G2 bound "$_b14g_g2" 200001010000; _b14g_e2="$_b14g_e"
if _b14g_new G3 bound "$_b14g_g3" 200001010000; then
  _fx_git "$_b14g_g3" worktree add -q -b g3w "$_b14g_g3w" >/dev/null 2>&1 && [ -f "$_b14g_g3w/.git" ] || _b14g_e="the worktree G3w could not be added"
fi
_b14g_e3="$_b14g_e"
if _b14g_new G4 bound "$_b14g_g4"; then
  _fx_git "$_b14g_g4" worktree add -q -b g4w "$_b14g_g4w" >/dev/null 2>&1 && [ -f "$_b14g_g4w/.git" ] || _b14g_e="the worktree G4w could not be added"
fi
_b14g_e4="$_b14g_e"
_b14g_new GU init "$_b14g_gu"; _b14g_eu="$_b14g_e"
_b14g_new GUg init "$_b14g_gug" -; _b14g_eug="$_b14g_e"
_b14g_new GN plain "$_b14g_gn"; _b14g_outside GN "$_b14g_gn"; _b14g_en="$_b14g_e"
_b14g_new GNg plain "$_b14g_gng" -; _b14g_outside GNg "$_b14g_gng"; _b14g_eng="$_b14g_e"
_b14g_new GD notes "$_b14g_gd" 200001010000; _b14g_ed="$_b14g_e"

# TAG DIR STDIN [NAME=VALUE...] CMD [ARGS...]: run in DIR with gro's home and memory.
_b14g_go() {
  local t="$1" d="$2" i="$3"; shift 3
  ( [ -n "$d" ] && cd "$d" || exit 125
    perl -e 'alarm shift; exec @ARGV or exit 127' 120 \
      env -u CLAUDE_CODE_REMOTE -u CLAUDE_CODE_SESSION_ID FELIX_HOME="$_b14g_H" FELIX_MEMORY="$_b14g_M" "$@" < "$i" ) \
    > "$_b14g_O/$t.out" 2>&1
  printf '%s\n' "$?" > "$_b14g_O/$t.rc" 2>/dev/null
}
# TAG ROOT -> "STATUS graphify" from the graphify line of felix_maint_status gro ROOT, or what it printed instead.
_b14g_lib() {
  local f="$_b14g_O/lib.$1" r
  perl -e 'alarm shift; exec @ARGV or exit 127' 120 env -u GIT_DIR -u GIT_WORK_TREE \
    FELIX_HOME="$_b14g_H" FELIX_MEMORY="$_b14g_M" "${BASH:-bash}" -c \
    'set -uo pipefail; . "$1/lib/resolve.sh"; . "$1/lib/detect.sh"; . "$1/lib/maintenance.sh"; felix_maint_status "$2" "$3"' \
    _ "$FROOT/harness" "$_b14g_P" "$2" > "$f" 2>&1 < /dev/null; r=$?
  r="$(LC_ALL=C awk -F'\t' -v r="$r" '$2 == "graphify" && NF >= 3 { print $1 " graphify"; f = 1; exit } END { if (!f) print "no graphify line (exit " r ")" }' "$f" 2>/dev/null)"
  case "$r" in "no graphify line"*) printf '%s: [%s]' "$r" "$(_b14h_flat "$f")" ;; *) printf '%s' "$r" ;; esac
}
_b14g_is() { if [ -n "$2" ]; then bad "$1" "the fixture was not built: $2"; else is "$1" "$3" "$4"; fi; }
_b14g_seen() { printf '%s printed [%s]' "$1" "$(_b14h_flat "$_b14g_O/$1.out")"; }

_b14g_go M1 "$_b14g_g1" /dev/null "$FELIX" maintenance
_b14g_go M2s "$_b14g_g2" /dev/null "$FELIX" maintenance
_b14g_e2f="$_b14g_e2"
if [ -z "$_b14g_e2f" ]; then touch -t 209901010000 "$_b14g_g2/graphify-out/graph.json" 2>/dev/null || _b14g_e2f="the graph in G2 could not be given the time 209901010000"; fi
_b14g_go M2f "$_b14g_g2" /dev/null "$FELIX" maintenance
printf '%s' '{"session_id":"b14g","source":"startup"}' > "$_b14g_O/S1.in" 2>/dev/null
_b14g_go S1 "$_b14g_g1" "$_b14g_O/S1.in" CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start"
python3 -c "$_b14h_py" "$_b14g_O/S1.out" ctx > "$_b14g_O/S1.ctx" 2>/dev/null; _b14g_cx=$?
python3 -c "$_b14h_py" "$_b14g_O/S1.out" sys > "$_b14g_O/S1.sys" 2>/dev/null; _b14g_sx=$?

# ---- A28 to A42
_b14g_OK='  ok      graphify'; _b14g_DUE='  DUE     graphify'
_b14g_bh() { LC_ALL=C awk -v p="$2" -v s="$3" 'index($0, p) == 1 && index($0, s) { f = 1; exit } END { print (f ? "yes" : "no") }' "$1" 2>/dev/null || printf 'no'; }
_b14h_v=""
_b14h_want "$(_b14g_bh "$_b14g_O/M1.out" "$_b14g_OK" 'check passed')" yes "felix maintenance printed no line beginning [$_b14g_OK] that holds [check passed]"
_b14h_ck "seeded graph row: in a repository with no graph, felix maintenance reads graphify ok, check passed" "$_b14g_e1" "$(_b14g_seen M1)"
_b14h_v=""
_b14h_want "$(_b14h_q "$_b14g_O/M1.out" holds graphify)" yes "felix maintenance printed no graphify line at all, so the absence of a DUE line says nothing"
_b14h_want "$(_b14h_q "$_b14g_O/M1.out" begins "$_b14g_DUE")" no "felix maintenance printed a line beginning [$_b14g_DUE]"
_b14h_ck "seeded graph row: and prints no DUE line for it" "$_b14g_e1" "$(_b14g_seen M1)"
_b14g_is "seeded graph row: an unborn repository with no graph reads ok too" "$_b14g_eu" "$(_b14g_lib GU "$_b14g_gu")" "ok graphify"
_b14h_v=""
if [ "$_b14g_cx" -ne 0 ]; then _b14h_want no yes "no additionalContext could be read from the session start's output (python3 exited $_b14g_cx)"
else
  _b14g_s="$(LC_ALL=C awk 'index($0, "Maintenance due: ") == 1 { print; f = 1; exit } END { if (!f) print "(none)" }' "$_b14g_O/S1.ctx" 2>/dev/null)"
  case "$_b14g_s" in
    "(none)"|"") _b14h_want no yes "the session start's context has no line beginning [Maintenance due: ]" ;;
    *graphify*) _b14h_want no yes "its due line names graphify: [$_b14g_s]" ;;
  esac
fi
_b14h_ck "seeded graph row: the session start's due line does not name graphify there" "$_b14g_e1" "$(_b14g_seen S1)"
_b14g_due="$(LC_ALL=C awk 'index($0, "  DUE ") == 1 { n++ } END { print n + 0 }' "$_b14g_O/M1.out" 2>/dev/null)"
_b14g_n="none"
if [ "$_b14g_sx" -eq 0 ]; then
  _b14g_n="$(LC_ALL=C awk -v d="$(printf '\302\267')" '
    { s = $0
      while ((i = index(s, d " ")) > 0) {
        s = substr(s, i + length(d) + 1)
        if (match(s, /^[0123456789]+ due/)) { print substr(s, 1, RLENGTH - 4); f = 1; exit }
      } }
    END { if (!f) print "none" }' "$_b14g_O/S1.sys" 2>/dev/null)"
fi
_b14h_v=""
_b14h_want "${_b14g_n:-none}" "${_b14g_due:-unread}" "the badge's N is [${_b14g_n:-none}] and felix maintenance prints [${_b14g_due:-unread}] DUE line(s)"
_b14h_ck "seeded graph row: and the badge counts what felix maintenance calls due" "$_b14g_e1" \
  "the systemMessage: [$(_b14h_flat "$_b14g_O/S1.sys")]"
_b14h_v=""
_b14h_want "$(_b14g_bh "$_b14g_O/M2s.out" "$_b14g_DUE" 'check failed')" yes "felix maintenance printed no line beginning [$_b14g_DUE] that holds [check failed]"
_b14h_ck "seeded graph row: a graph older than the last commit is due, check failed" "$_b14g_e2" "$(_b14g_seen M2s)"
_b14h_v=""
_b14h_want "$(_b14h_q "$_b14g_O/M2f.out" begins "$_b14g_OK")" yes "felix maintenance printed no line beginning [$_b14g_OK]"
_b14h_ck "seeded graph row: a graph newer than the last commit is ok" "$_b14g_e2f" "$(_b14g_seen M2f)"
_b14g_is "seeded graph row: a worktree of a checkout holding a stale graph is due" "$_b14g_e3" "$(_b14g_lib G3w "$_b14g_g3w")" "due graphify"
_b14g_is "seeded graph row: a worktree of a checkout with no graph is ok" "$_b14g_e4" "$(_b14g_lib G4w "$_b14g_g4w")" "ok graphify"
_b14g_is "seeded graph row: a directory outside git is due, since the check cannot ask" "${_b14g_en:-$_b14g_eng}" \
  "GN $(_b14g_lib GN "$_b14g_gn"), GNg $(_b14g_lib GNg "$_b14g_gng")" "GN due graphify, GNg due graphify"
_b14g_is "seeded graph row: an unborn repository holding a graph is due" "$_b14g_eug" "$(_b14g_lib GUg "$_b14g_gug")" "due graphify"
_b14g_is "seeded graph row: a graph no modelled commit is newer than is ok" "$_b14g_ed" "$(_b14g_lib GD "$_b14g_gd")" "ok graphify"
# The template's graphify rows: data lines, not comments or blank, whose first field is graphify.
_b14g_tf() { LC_ALL=C awk -F'\t' -v k="$1" '/^#/ || !NF { next } $1 == "graphify" { print (k == "NF" ? NF : $k); exit }' "$_b14g_T" 2>/dev/null; }
_b14g_tn="$(LC_ALL=C awk -F'\t' '/^#/ || !NF { next } $1 == "graphify" { n++ } END { print n + 0 }' "$_b14g_T" 2>/dev/null)"
_b14g_tx=""; [ -f "$_b14g_T" ] || _b14g_tx="there is no $_b14g_T"
_b14h_v=""
case "$(_b14g_tf 4)" in *graphify-out/graph.json*) ;; *) _b14h_want no yes "field 4 of the template's graphify row is [$(_b14g_tf 4)]" ;; esac
_b14h_ck "seeded graph row: its description names graphify-out/graph.json" "$_b14g_tx" "the template is $_b14g_T"
_b14g_is "seeded graph row: it is still one five-column row, cadence 0, capability always" "$_b14g_tx" \
  "rows ${_b14g_tn:-unread}, fields $(_b14g_tf NF), cadence $(_b14g_tf 2), capability $(_b14g_tf 3)" "rows 1, fields 5, cadence 0, capability always"
_b14h_v=""
_b14h_want "$(_b14h_nonempty "$_b14g_O/M1.out")" yes "felix maintenance printed nothing, so the absence of a refusal says nothing"
_b14h_want "$(_b14h_q "$_b14g_O/M1.out" holds 'Checks refused')" no "felix maintenance prints a Checks refused section"
_b14h_ck "seeded graph row: and felix maintenance refuses no check of the template" "$_b14g_e1" "$(_b14g_seen M1)"
