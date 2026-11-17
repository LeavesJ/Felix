# tests/lib/felix-cost.sh: the felix cost runner, its readers and its records roots.
# Used by 1050 (builds them), 1060 and 1070. Moved from parts/1050-felix-cost-tokens-spent-read-from-the-transc.sh:
# lines 22-30 and 142-147 (the variables and the permission probe, now in _fc_init), lines 32-138
# and 147-149 (the helpers, verbatim), lines 157-158 (r1) and 382-395 (r6, now in _fc_fixture); and from
# parts/1060-continued.sh: _fc_run11 (line 166, verbatim), r11 (lines 142-161), rE (334) and rN (339-344).
# Definitions only. _fc_init sets the constants first, and does nothing more once FCCANDENY is set,
# so in the serial run only 1050 builds the directories, and FCSEQ, FCOUT, FCERR and FCRC go on from
# where they stand. _fc_fixture builds each records root named unless $FC/<name>/projects is there.

_fc_init() {
  FCT0="2026-10-09T10:00:00.000Z"      # inside the week of 2026-10-08T13:00Z
  FCTB="2026-10-10T10:00:00.000Z"      # the day the uncounted records are dated
  [ -n "${FCCANDENY:-}" ] && return 0
  FC="$TMP/cost"; mkdir -p "$FC"; FC="$(cd "$FC" && pwd -P)"
  FCCWD="$FC/cwd"; FCHOME="$FC/home"; FCTMPD="$FC/tmpd"; FCOUTF="$FC/out"; FCERRF="$FC/err"
  mkdir -p "$FCCWD" "$FCHOME" "$FCTMPD"
  # A home the command must not consult: it names a Felix home that does not exist.
  printf '%s\n' "$FC/no-such-felix-home" > "$FCHOME/.felix-home"
  FCSEQ=0
  FCOUT=""; FCERR=""; FCRC=0
  # Whether a missing read permission stops this user: root reads anything, and
  # some mounts ignore the mode bits, so ask the machine rather than the uid.
  FCCANDENY=0
  mkdir -p "$FC/probe/d"; : > "$FC/probe/f"; : > "$FC/probe/d/g"
  chmod 000 "$FC/probe/f" "$FC/probe/d"
  if ! { : < "$FC/probe/f"; } 2>/dev/null && ! ls "$FC/probe/d" >/dev/null 2>&1; then FCCANDENY=1; fi
  chmod 755 "$FC/probe/d"; chmod 644 "$FC/probe/f"
  return 0
}

# One run of the command, as a child with a controlled environment. The knobs,
# set on the call as NAME=value _fc args: FCCFG is CLAUDE_CONFIG_DIR (unset
# leaves it unset, set and empty exports it empty), FCNOW is FELIX_COST_NOW
# ("clock" leaves it unset), FCCAP is FELIX_COST_CAP_M, FCFH is FELIX_HOME, FCLC
# is the locale, FCTZ is TZ, FCCWD the directory it runs from. Standard input is closed so
# nothing here can eat a here-document the caller is reading.
_fc() {
  ( cd "${FCCWD:?}" || exit 97
    unset FELIX_HOME FELIX_MEMORY CLAUDE_PLUGIN_ROOT CLAUDE_CONFIG_DIR FELIX_COST_CAP_M FELIX_COST_NOW
    export HOME="$FCHOME" TMPDIR="$FCTMPD"
    case "${FCNOW-2026-10-11T05:00:00Z}" in
      clock) ;;
      *) export FELIX_COST_NOW="${FCNOW-2026-10-11T05:00:00Z}" ;;
    esac
    if [ -n "${FCCFG+x}" ]; then export CLAUDE_CONFIG_DIR="$FCCFG"; fi
    if [ -n "${FCCAP+x}" ]; then export FELIX_COST_CAP_M="$FCCAP"; fi
    if [ -n "${FCFH+x}" ]; then export FELIX_HOME="$FCFH"; fi
    if [ -n "${FCLC+x}" ]; then export LC_ALL="$FCLC" LANG="$FCLC"; fi
    if [ -n "${FCTZ+x}" ]; then export TZ="$FCTZ"; fi
    "$REAL_HARNESS/felix" cost "$@" ) </dev/null >"$FCOUTF" 2>"$FCERRF"
  FCRC=$?
  FCOUT="$(cat "$FCOUTF")"; FCERR="$(cat "$FCERRF")"
}

# ---- building transcripts -------------------------------------------------
# One response record in the contract's shape: compact, keys in that order, the
# timestamp following the uuid. _fc_rec ID TS MODEL USAGE-JSON
# _felix_cost_vars: the variables this file's functions read, set when the prelude calls it
# (contract C2: a lib file defines functions and nothing else).
_felix_cost_vars() {
FC_CONTENT='[{"type":"text","text":"hi"}]'
FCUSAGE_OK="rc=2 stdout=empty message=yes usage=yes"
}
_fc_rec() {   # ID TS MODEL USAGE-JSON [CONTENT-JSON]
  local c="${5:-$FC_CONTENT}"
  FCSEQ=$((FCSEQ+1))
  printf '{"parentUuid":null,"isSidechain":false,"message":{"model":"%s","id":"%s","type":"message","role":"assistant","content":%s,"stop_reason":null,"usage":%s},"type":"assistant","uuid":"u-%s","timestamp":"%s","sessionId":"s1"}\n' \
    "$3" "$1" "$c" "$4" "$FCSEQ" "$2"
}
# The usage object the host writes: input, 5-minute writes, 1-hour writes, cache
# reads, output; cache_creation present, cache_creation_input_tokens their sum,
# and an iterations array repeating every count. _fc_use IN C5 C1H CR OUT
_fc_use() {
  printf '{"input_tokens":%s,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s,"output_tokens":%s,"cache_creation":{"ephemeral_5m_input_tokens":%s,"ephemeral_1h_input_tokens":%s},"iterations":[{"input_tokens":%s,"output_tokens":%s,"cache_read_input_tokens":%s,"cache_creation_input_tokens":%s,"cache_creation":{"ephemeral_5m_input_tokens":%s,"ephemeral_1h_input_tokens":%s},"type":"message"}]}' \
    "$1" "$(( $2 + $3 ))" "$4" "$5" "$2" "$3" "$1" "$5" "$4" "$(( $2 + $3 ))" "$2" "$3"
}
# Append a response to FILE: _fc_put FILE ID TS MODEL IN C5 C1H CR OUT
_fc_put() {
  mkdir -p "$(dirname "$1")"
  _fc_rec "$2" "$3" "$4" "$(_fc_use "$5" "$6" "$7" "$8" "$9")" >> "$1"
}
# A response that spent only input tokens: _fc_in FILE ID TS MODEL IN
_fc_in() { _fc_put "$1" "$2" "$3" "$4" "$5" 0 0 0 0; }
# A fresh records root named $1: $FC/$1 is the CLAUDE_CONFIG_DIR, projects/ under it.
_fc_mk() { rm -rf "${FC:?}/$1"; mkdir -p "$FC/$1/projects"; }

# ---- reading the last run -------------------------------------------------
_fc_row()   { KIND="$1" KEY="$2" awk -F'\t' '$1 == ENVIRON["KIND"] && $2 == ENVIRON["KEY"] { if (!f) print; f = 1 }' "$FCOUTF"; }
_fc_rows()  { KIND="$1" awk -F'\t' '$1 == ENVIRON["KIND"]' "$FCOUTF"; }
_fc_cover() { KEY="$1" awk -F'\t' '$1 == "cover" && $2 == ENVIRON["KEY"] { if (!f) print $3; f = 1 }' "$FCOUTF"; }
_fc_count() { KIND="$1" awk -F'\t' '$1 == ENVIRON["KIND"] { n++ } END { print n + 0 }' "$FCOUTF"; }
# "absent" when the run reported (exit 0, a total row) and holds no KIND/KEY row,
# so a run that never reported cannot pass as one that left the row out.
_fc_absent() {
  if [ "$FCRC" != 0 ]; then printf 'exit %s' "$FCRC"
  elif [ -z "$(_fc_row total all)" ]; then printf 'no total row'
  elif [ -n "$(_fc_row "$1" "$2")" ]; then printf 'present'
  else printf 'absent'; fi
}
# The data rows expected of one kind, a row a line: _fc_exps KIND KEY TOKENS PCT CALLS ...
_fc_exps() {
  local k="$1" s=""; shift
  while [ $# -ge 4 ]; do printf '%s%s\t%s\t%s\t%s\t%s' "$s" "$k" "$1" "$2" "$3" "$4"; s=$'\n'; shift 4; done
}
# The kinds of row a --tsv report holds, in a fixed order, those present.
_fc_kinds() {
  awk -F'\t' '{ k[$1] = 1 } END { n = split("cover total worktree day model", o, " ")
    for (i = 1; i <= n; i++) if (k[o[i]]) { printf "%s%s", s, o[i]; s = " " } }' "$FCOUTF"
}
# The first text-view line whose first word is $1, with blanks collapsed.
_fc_line() {
  W="$1" awk '{ s = $0; gsub(/[ \t]+/, " ", s); sub(/^ /, "", s); split(s, a, " ")
                if (a[1] == ENVIRON["W"]) { if (!f) print s; f = 1 } }' "$FCOUTF"
}
# The headings the text view prints, in order.
_fc_heads() {
  awk '{ s = $0; sub(/^[ \t]+/, "", s) }
       s ~ /^worktrees/ { printf "%sworktrees", o; o = " " }
       s ~ /^days/      { printf "%sdays", o; o = " " }
       s ~ /^models/    { printf "%smodels", o; o = " " }' "$FCOUTF"
}
# The lines under the text-view heading beginning $1: the lines that start with
# a digit (a percent or a date), fields single-spaced, the % and M marks cut
# off the numbers. The order of fields is the contract's: a worktree or model
# line is percent, millions, name; a day line is date, millions, percent.
_fc_sec() {
  H="$1" awk '
    { s = $0; sub(/^[ \t]+/, "", s) }
    s ~ /^(worktrees|days|models)/ { on = (index(s, ENVIRON["H"]) == 1); next }
    on && s ~ /^[0-9]/ { n = split(s, a, /[ \t]+/); o = ""
      for (i = 1; i <= n; i++) { v = a[i]; if (v ~ /^[0-9]+(\.[0-9]+)?[%M]$/) v = substr(v, 1, length(v) - 1)
                                 o = o (i > 1 ? " " : "") v }
      print o }' "$FCOUTF"
}
# What a usage error looks like from outside, as one word-string to compare.
_fc_usage_verdict() {
  local v="rc=$FCRC"
  if [ -s "$FCOUTF" ]; then v="$v stdout=printed"; else v="$v stdout=empty"; fi
  v="$v $(awk '/^felix cost: / { m = 1 } /^usage: felix cost/ { u = 1 } END { printf "message=%s usage=%s", m ? "yes" : "no", u ? "yes" : "no" }' "$FCERRF")"
  printf '%s' "$v"
}

# is / has, skipped where nothing can be denied.
_fcd()  { if [ "$FCCANDENY" = 1 ]; then is  "$1" "$2" "$3"; else skip "$1" "a missing read permission does not stop this user"; fi; }
_fcdh() { if [ "$FCCANDENY" = 1 ]; then has "$1" "$2" "$3"; else skip "$1" "a missing read permission does not stop this user"; fi; }
_fc_run11() { FCCFG="$FC/r11" FCNOW=2026-10-14T20:00:00Z FCCAP=100 _fc "$@"; }

_fc_fixture() {   # <r1|r6|r11|rE|rN>...: each records root named, unless it is already there
  local n
  for n in "$@"; do
    [ -d "${FC:?}/$n/projects" ] && continue
    case "$n" in
      r1)
        _fc_mk r1
        _fc_put "$FC/r1/projects/-Users-dev-alpha/s1.jsonl" msg_A1 "$FCT0" claude-opus-5-5 10500000 8000000 5000000 100000000 10000000
        ;;
      r6)
        _fc_mk r6
        FC_L="$FC/r6/projects"
        _fc_in "$FC_L/-Users-dev-l1/s1.jsonl"               msg_L1 "$FCT0" m-ses 1000
        _fc_in "$FC_L/-Users-dev-l1/s1/subagents/a1.jsonl"  msg_L2 "$FCT0" m-sub 2000
        _fc_in "$FC_L/-Users-dev-l2/s9.jsonl"               msg_L3 "$FCT0" m-ses 4000
        # Never read: each holds an in-window response with a number that would show.
        _fc_in "$FC_L/x.jsonl"                                  msg_L4 "$FCT0" m-root   100001
        _fc_in "$FC_L/-Users-dev-l1/s1/x.jsonl"                 msg_L5 "$FCT0" m-sid    100002
        _fc_in "$FC_L/-Users-dev-l1/s1/other/x.jsonl"           msg_L6 "$FCT0" m-other  100003
        _fc_in "$FC_L/-Users-dev-l1/s1/other/deeper/x.jsonl"    msg_L7 "$FCT0" m-deeper 100004
        _fc_in "$FC_L/-Users-dev-l1/s1/subagents/workflows/wf_1/x.jsonl" msg_L10 "$FCT0" m-wf 500
        _fc_in "$FC_L/-Users-dev-l1/x.txt"                      msg_L8 "$FCT0" m-txt    100005
        _fc_in "$FC_L/-Users-dev-l1/old.jsonl.bak"              msg_L9 "$FCT0" m-bak    100006
        mkdir -p "$FC_L/-Users-dev-l2/dir.jsonl"      # a directory whose name ends .jsonl is not a regular file
        ;;
      r11)
        _fc_mk r11
        FC_K=0
        while read -r FC_E FC_TS FC_M FC_IN; do
          FC_K=$((FC_K+1))
          _fc_in "$FC/r11/projects/$FC_E/s1.jsonl" "msg_K$FC_K" "$FC_TS" "$FC_M" "$FC_IN"
        done <<'FCEOF'
-Users-dev-aa 2026-10-12T10:00:00.000Z claude-haiku-5-5 1000000
-Users-dev-bb 2026-10-09T10:00:00.000Z claude-opus-5-5 6000000
-Users-dev-bb 2026-10-13T10:00:00.000Z claude-opus-5-5 6000000
-Users-dev-cc 2026-10-10T10:00:00.000Z claude-haiku-5-5 2000000
-Users-dev-dd 2026-10-14T10:00:00.000Z claude-opus-5-5 11000000
-Users-dev-ee 2026-10-09T10:00:00.000Z claude-sonnet-5-5 3000000
-Users-dev-ff 2026-10-12T10:00:00.000Z claude-sonnet-5-5 10000000
-Users-dev-gg 2026-10-13T10:00:00.000Z claude-sonnet-5-5 4000000
-Users-dev-hh 2026-10-14T10:00:00.000Z claude-haiku-5-5 9000000
-Users-dev-ii 2026-10-10T10:00:00.000Z claude-haiku-5-5 5000000
-Users-dev-jj 2026-10-09T10:00:00.000Z claude-opus-5-5 8000000
-Users-dev-kk 2026-10-12T10:00:00.000Z claude-sonnet-5-5 6000000
-Users-dev-ll 2026-10-14T10:00:00.000Z claude-sonnet-5-5 7000000
FCEOF
        ;;
      rE) _fc_mk rE ;;
      rN)
        _fc_mk rN
        FC_NP="$FC/rN/projects"
        _fc_in "$FC_NP/x.jsonl" msg_Q1 "$FCT0" m-q 100
        _fc_in "$FC_NP/-Users-dev-q/s1/other/y.jsonl" msg_Q2 "$FCT0" m-q 100
        _fc_in "$FC_NP/-Users-dev-q/z.txt" msg_Q3 "$FCT0" m-q 100
        mkdir -p "$FC_NP/-Users-dev-q/dir.jsonl" "$FC_NP/-Users-dev-q/s1/subagents"
        ;;
    esac
  done
  return 0
}
