printf '\nsnapshot.sh on a fixture home: the names stage, the build, the cross-check and the audit (audit b22, blind)\n'
# Written blind on 2026-10-24 from the contract alone (docs/2026-10-24-audit-fixes/
# b22-snapshot-builds-is-tested-and-ships-the.md: B20 to B29 and section 5, assertions A20 to
# A32). No script was read. projects/felix/snapshot.sh, snapshot-scrub.sh and snapshot-audit.sh
# are copied byte for byte into a fixture home H, as projects/lantern/, and H's copy of
# snapshot.sh is the one run: the shipped one, run in place, would take the real checkout for
# its home and fetch the real origin first. A26, A30 and A31 are red: the scrub's report passed
# through to the run's stdout (B18, B24), each owner a manifest declares an audit name searched
# whole (B27, C039), and an owner too short to search said as not searched (B28). The rest are
# controls, which the contract measured on 0.49.307.
#
# FD, under $TMP/b22-run (T): O a bare origin and H its clone on main, standing for the home;
# P the public fixture, a repository of one commit on main holding LICENSE, with no remote; U a
# user home named umberwick; M a memory root holding lantern/ and tidewater/, and qz/ from A22
# on; Q, T/other home, holding projects/fernbrook/. H's commits, each a minute after the last:
# C0 the lantern project (remote quillcorp/lantern-home), the three scripts, an autonomy grant,
# engine/harness/README.md, .gitignore, README.md and the marketplace file; C1a marigold
# (brackenhall/marigold-site) and engine/harness/notes.md; C1b fennel (zq/fennel-tools). C0 to
# C1b are pushed, which makes marigold the token another and fennel third. C2 is the @name row
# for qz, C3 engine/harness/plants.md.
#
# Readings, where the contract leaves room:
# - Every run stands in H (through _fx_cd) with stdin /dev/null, HOME=U, FELIX_MEMORY as the
#   case says, FELIX_HOME unset, --public-clone P and a new --out under T/out. Nothing may
#   reach the network: git may use the file transport only (GIT_ALLOW_PROTOCOL=file), gh, curl
#   and wget are stand-ins that refuse, the GitHub tokens are unset, and a run that has not
#   ended in 180 s is ended by an alarm (exit 142).
# - "A line DIFFER", MATCH, "  qz", "  README.md:1" and the four hit lines are whole lines; the
#   ack line is a prefix whose \t is two characters. "Does not name zq" reads zq as a word,
#   with every temporary path taken out first, since a path mktemp made may hold any letters;
#   the names lines of A31 are read the same way.
# - L, the user name, is looked for in H's published set as B32's command names it: engine/,
#   projects/lantern/, README.md, .gitignore and .claude-plugin/.
# - A28's stand-in scrub runs a byte copy of the shipped scrub kept in T, then rewrites install
#   to instail in each path its LIST names, read where it was run, as the scrub reads them.

_b22r_src="$(cd "$REAL_HARNESS/../.." 2>/dev/null && pwd)/projects/felix"
_b22r_why=""
for _b22r_i in snapshot.sh snapshot-scrub.sh snapshot-audit.sh; do
  [ -f "$_b22r_src/$_b22r_i" ] || _b22r_why="no projects/felix/snapshot-*.sh beside this harness"
done
command -v perl >/dev/null 2>&1 || _b22r_why="${_b22r_why:-no perl on PATH, which the runs here are timed by}"
_b22r_L="$(id -un 2>/dev/null | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr -cd 'abcdefghijklmnopqrstuvwxyz0123456789')"
if [ -z "$_b22r_why" ] && [ "${#_b22r_L}" -lt 3 ]; then
  _b22r_why="the user name reads as [$_b22r_L], under three characters, and the machine source stops every run at the names stage on it, by design"
fi
_b22r_lwhy=""   # set below when L occurs in H's published set
_b22r_nl='
'
# NAME GOT WANT [L]: the assertion, or a skip naming why no run (with L, why none of the A24 to
# A29 runs) can be judged. Every name is emitted on every run, whatever the scripts answered.
_b22r_is() {
  if [ -n "$_b22r_why" ]; then skip "$1" "$_b22r_why"
  elif [ -n "${4:-}" ] && [ -n "$_b22r_lwhy" ]; then skip "$1" "$_b22r_lwhy"
  else is "$1" "$2" "$3"; fi
}

_b22r_t="$TMP/b22-run"; mkdir -p "$_b22r_t/runs" "$_b22r_t/out" "$_b22r_t/stub" "$_b22r_t/fxhome"
_b22r_t="$(cd "$_b22r_t" && pwd -P)"; _b22r_tp="$(cd "$TMP" && pwd -P)"
_b22r_o="$_b22r_t/O"; _b22r_h="$_b22r_t/H"; _b22r_p="$_b22r_t/P"; _b22r_u="$_b22r_t/umberwick"
_b22r_m="$_b22r_t/mem"; _b22r_q="$_b22r_t/other home"
_b22r_d="$(( $(date +%s) - 7200 ))"
_b22r_g() {  # DIR ARGS...: git in DIR through _fx_git, as the fixture's committer, at the clock _b22r_d
  local d="$1"; shift
  HOME="$_b22r_t/fxhome" XDG_CONFIG_HOME="$_b22r_t/fxhome/.config" GIT_CONFIG_NOSYSTEM=1 \
  GIT_AUTHOR_NAME=Fixture GIT_AUTHOR_EMAIL=fixture@example.invalid GIT_AUTHOR_DATE="$_b22r_d +0000" \
  GIT_COMMITTER_NAME=Fixture GIT_COMMITTER_EMAIL=fixture@example.invalid GIT_COMMITTER_DATE="$_b22r_d +0000" \
  _fx_git "$d" -c init.defaultBranch=main -c advice.detachedHead=false -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"
}
_b22r_commit() {  # DIR MESSAGE: everything in DIR committed, a minute after the last commit
  _b22r_d="$(( _b22r_d + 60 ))"
  _b22r_g "$1" add -A >/dev/null 2>&1; _b22r_g "$1" commit -qm "$2" >/dev/null 2>&1
}
_b22r_json() { printf '{\n  "remote_match": "%s"\n}\n' "$2" > "$1"; }   # FILE OWNER/REPO: remote_match on its own line
# NAME MEMORY ARGS...: H's copy of snapshot.sh run as the FD rules say; T/runs/NAME.out, .err
# and .rc keep what it printed and how it ended.
_b22r_run() {
  local n="$1" m="$2"; shift 2
  : > "$_b22r_t/runs/$n.out"; : > "$_b22r_t/runs/$n.err"
  ( _fx_cd "$_b22r_h" || exit 125
    unset FELIX_HOME GH_TOKEN GITHUB_TOKEN GH_ENTERPRISE_TOKEN GITHUB_ENTERPRISE_TOKEN
    HOME="$_b22r_u"; FELIX_MEMORY="$m"; PATH="$_b22r_t/stub:$PATH"; GIT_ALLOW_PROTOCOL=file
    export HOME FELIX_MEMORY PATH GIT_ALLOW_PROTOCOL
    perl -e 'alarm shift @ARGV; exec { $ARGV[0] } @ARGV or exit 127' 180 \
      bash "$_b22r_h/projects/lantern/snapshot.sh" --public-clone "$_b22r_p" --out "$_b22r_t/out/$n" "$@" \
      < /dev/null > "$_b22r_t/runs/$n.out" 2> "$_b22r_t/runs/$n.err" )
  printf '%s\n' "$?" > "$_b22r_t/runs/$n.rc"
}

# ---- FD, and the runs in the contract's order --------------------------------------------------
_b22r_tree=""; _b22r_c2=""; _b22r_p0=""
if [ -z "$_b22r_why" ]; then
  for _b22r_i in gh curl wget; do
    printf '#!/bin/sh\necho "b22 fixture: %s is not run here" >&2\nexit 1\n' "$_b22r_i" > "$_b22r_t/stub/$_b22r_i"
    chmod 755 "$_b22r_t/stub/$_b22r_i"
  done
  mkdir -p "$_b22r_o" "$_b22r_p" "$_b22r_u" "$_b22r_m/lantern" "$_b22r_m/tidewater" "$_b22r_t/mem-empty" \
           "$_b22r_q/projects/fernbrook" "$_b22r_t/nowhere"
  _b22r_g "$_b22r_o" init -q --bare >/dev/null 2>&1
  _b22r_g "$_b22r_o" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
  _b22r_g "$_b22r_t" clone -q "$_b22r_o" H >/dev/null 2>&1
  _b22r_g "$_b22r_h" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
  # C0
  mkdir -p "$_b22r_h/projects/lantern" "$_b22r_h/engine/harness" "$_b22r_h/.claude-plugin"
  _b22r_json "$_b22r_h/projects/lantern/project.json" quillcorp/lantern-home
  for _b22r_i in snapshot.sh snapshot-scrub.sh snapshot-audit.sh; do cp -p "$_b22r_src/$_b22r_i" "$_b22r_h/projects/lantern/$_b22r_i"; done
  printf 'fixture grant\n' > "$_b22r_h/projects/lantern/autonomy"
  printf '%s\n' 'the engine' 'a mari gold line' > "$_b22r_h/engine/harness/README.md"
  printf '*.tmp\n' > "$_b22r_h/.gitignore"
  printf 'install from LeavesJ/Felix\n' > "$_b22r_h/README.md"
  printf '{}\n' > "$_b22r_h/.claude-plugin/marketplace.json"
  _b22r_commit "$_b22r_h" C0
  # C1a, then C1b, then all three pushed
  mkdir -p "$_b22r_h/projects/marigold"
  _b22r_json "$_b22r_h/projects/marigold/project.json" brackenhall/marigold-site
  printf 'the marigold gate runs\n' > "$_b22r_h/engine/harness/notes.md"
  _b22r_commit "$_b22r_h" C1a
  mkdir -p "$_b22r_h/projects/fennel"
  _b22r_json "$_b22r_h/projects/fennel/project.json" zq/fennel-tools
  _b22r_commit "$_b22r_h" C1b
  _b22r_g "$_b22r_h" push -q -u origin main >/dev/null 2>&1
  # P: one commit on main holding LICENSE
  _b22r_g "$_b22r_p" init -q >/dev/null 2>&1
  _b22r_g "$_b22r_p" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
  printf 'fixture licence\n' > "$_b22r_p/LICENSE"
  _b22r_commit "$_b22r_p" 'the public first commit'
  _b22r_p0="$(_b22r_g "$_b22r_p" rev-parse -q --verify refs/heads/main 2>/dev/null)"

  # A20: an empty memory root. A21: the pointer names a directory without projects/.
  _b22r_run r20 "$_b22r_t/mem-empty"
  printf '  %s  \n' "$_b22r_t/nowhere" > "$_b22r_u/.felix-home"
  _b22r_run r21 "$_b22r_m"
  rm -f "$_b22r_u/.felix-home"
  # A22: qz in the memory root, no row on origin/main. A23: C2 committed, not pushed.
  mkdir -p "$_b22r_m/qz"
  _b22r_run r22 "$_b22r_m"
  printf '@name\tqz\tfixture leftover, not a project\n' > "$_b22r_h/.snapshot-ack.tsv"
  _b22r_commit "$_b22r_h" C2
  _b22r_c2="$(_b22r_g "$_b22r_h" rev-parse -q --verify HEAD 2>/dev/null)"
  _b22r_run r23 "$_b22r_m"
  # A24 to A27: C2 pushed, a self-test run expecting the tree 0, then the tree it printed.
  _b22r_g "$_b22r_h" push -q origin main >/dev/null 2>&1
  _b22r_run r24 "$_b22r_m" --source "$_b22r_c2" --expect-tree 0
  _b22r_tree="$(LC_ALL=C awk 'length($0) == 54 && index($0, "built tree    ") == 1 && substr($0, 15) ~ /^[0123456789abcdef]+$/ { print substr($0, 15); exit }' "$_b22r_t/runs/r24.out" 2>/dev/null)"
  [ -z "$_b22r_tree" ] || _b22r_run r27 "$_b22r_m" --source "$_b22r_c2" --expect-tree "$_b22r_tree"
  # A28: H's working copy of the scrub replaced, uncommitted, by a stand-in, then restored.
  cp -p "$_b22r_h/projects/lantern/snapshot-scrub.sh" "$_b22r_t/scrub.keep"
  { printf '#!/usr/bin/env bash\n'
    printf 'keep=%q\n' "$_b22r_t/scrub.keep"
    cat <<'B22W'
# The fixture's stray: the shipped scrub, then install made instail in every listed file.
bash "$keep" "$@" || exit "$?"
perl -e 'local $/ = "\0"; open my $l, "<", $ARGV[0] or exit 1; my @f = <$l>; close $l;
  for my $f (@f) { chomp $f; next if $f eq ""; local $/; open my $i, "<", $f or next; my $s = <$i>; close $i;
    $s =~ s/install/instail/g; open my $o, ">", $f or exit 1; print $o $s; close $o }' "$2" || exit 1
B22W
  } > "$_b22r_h/projects/lantern/snapshot-scrub.sh"
  _b22r_run r28 "$_b22r_m" --source "$_b22r_c2" --expect-tree 0
  cp -p "$_b22r_t/scrub.keep" "$_b22r_h/projects/lantern/snapshot-scrub.sh"
  # A29 to A31: C3 pushed, the pointer set to Q, and --name saltmarsh.
  printf '%s\n' 'ask brackenhall about it' 'the quillcorp desk' 'from LeavesJ/Felix' 'a tidewater note' \
    'a fernbrook note' 'a saltmarsh note' 'a umberwick note' 'plain words only' > "$_b22r_h/engine/harness/plants.md"
  _b22r_commit "$_b22r_h" C3
  _b22r_g "$_b22r_h" push -q origin main >/dev/null 2>&1
  printf '  %s  \n' "$_b22r_q" > "$_b22r_u/.felix-home"
  _b22r_run r29 "$_b22r_m" --name saltmarsh
  # L in the published set leaves the A24 to A29 runs a hit of their own.
  _b22r_x="$(LC_ALL=C grep -r -i -l -F -e "$_b22r_L" "$_b22r_h/engine" "$_b22r_h/projects/lantern" "$_b22r_h/README.md" \
             "$_b22r_h/.gitignore" "$_b22r_h/.claude-plugin" 2>/dev/null)"
  [ -z "$_b22r_x" ] || _b22r_lwhy="the user name [$_b22r_L] occurs in H's published set (${_b22r_x//$_b22r_nl/, }), so the audit of the A24 to A29 runs finds it there, by design"
fi

# ---- reading the runs ----------------------------------------------------------------------------
_b22r_f() { printf '%s' "$_b22r_t/runs/$1.$2"; }   # RUN out|err|rc -> its file
_b22r_rc() {  # RUN -> "exit N", or why there is no N
  local r; r="$(cat "$(_b22r_f "$1" rc)" 2>/dev/null)"
  case "$r" in
    '') printf 'exit unknown: %s was not run' "$1" ;;
    142) printf 'exit 142: %s was ended after 180 s' "$1" ;;
    *) printf 'exit %s' "$r" ;;
  esac
}
_b22r_show() { printf '[%s.%s: %s]' "$1" "$2" "$(head -c 400 "$(_b22r_f "$1" "$2")" 2>/dev/null | LC_ALL=C tr '\n' '/')"; }   # RUN STREAM
_b22r_has() {  # RUN STREAM TEXT -> yes when the stream holds TEXT, else what it holds
  if LC_ALL=C grep -F -e "$3" "$(_b22r_f "$1" "$2")" >/dev/null 2>&1; then printf yes; else _b22r_show "$1" "$2"; fi
}
_b22r_line() {  # RUN STREAM LINE -> yes when a line of the stream is exactly LINE, else what it holds
  if [ "$(_B22X="$3" LC_ALL=C awk '$0 == ENVIRON["_B22X"] { f = 1 } END { print f + 0 }' "$(_b22r_f "$1" "$2")" 2>/dev/null)" = 1 ]
  then printf yes; else _b22r_show "$1" "$2"; fi
}
_b22r_begins() {  # RUN STREAM PREFIX [TEXT [TEXT]] -> yes when a line beginning PREFIX holds each TEXT, else the lines beginning PREFIX
  _B22P="$3" _B22X="${4-}" _B22Y="${5-}" LC_ALL=C awk '
    function holds(s, t) { return t == "" || index(s, t) > 0 }
    index($0, ENVIRON["_B22P"]) == 1 { s = s (s == "" ? "" : " / ") $0; if (holds($0, ENVIRON["_B22X"]) && holds($0, ENVIRON["_B22Y"])) f = 1 }
    END { if (f) print "yes"; else print "[" (s == "" ? "no line begins " ENVIRON["_B22P"] : s) "]" }' "$(_b22r_f "$1" "$2")" 2>/dev/null
}
_b22r_nobegin() {  # RUN STREAM PREFIX -> none when no line begins PREFIX, else those lines
  _B22P="$3" LC_ALL=C awk 'index($0, ENVIRON["_B22P"]) == 1 { s = s (s == "" ? "" : " / ") $0 }
    END { print (s == "" ? "none" : "[" s "]") }' "$(_b22r_f "$1" "$2")" 2>/dev/null
}
_b22r_ends() {  # RUN STREAM PREFIX SUFFIX -> yes when a line begins with PREFIX and ends with SUFFIX, else the lines beginning PREFIX
  _B22P="$3" _B22X="$4" LC_ALL=C awk '
    index($0, ENVIRON["_B22P"]) == 1 { s = s (s == "" ? "" : " / ") $0; x = ENVIRON["_B22X"]
      if (length($0) >= length(x) && substr($0, length($0) - length(x) + 1) == x) f = 1 }
    END { if (f) print "yes"; else print "[" (s == "" ? "no line begins " ENVIRON["_B22P"] : s) "]" }' "$(_b22r_f "$1" "$2")" 2>/dev/null
}
# RUN STREAM PREFIX WORD -> yes when a line beginning PREFIX (any line, for an empty PREFIX)
# holds WORD with no letter or digit beside it, every temporary path taken out first; else no.
_b22r_word() {
  _B22P="$3" _B22W="$4" _B22A="$TMP" _B22B="$_b22r_tp" LC_ALL=C awk '
    function drop(s, p,   i) { if (p == "") return s; while ((i = index(s, p)) > 0) s = substr(s, 1, i - 1) substr(s, i + length(p)); return s }
    function alnum(c) { return c != "" && index("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", c) > 0 }
    ENVIRON["_B22P"] == "" || index($0, ENVIRON["_B22P"]) == 1 {
      s = drop(drop($0, ENVIRON["_B22A"]), ENVIRON["_B22B"]); w = ENVIRON["_B22W"]; o = 0
      while ((i = index(substr(s, o + 1), w)) > 0) {
        j = o + i
        if (!alnum(j > 1 ? substr(s, j - 1, 1) : "") && !alnum(substr(s, j + length(w), 1))) { f = 1; break }
        o = j
      }
    }
    END { print (f ? "yes" : "no") }' "$(_b22r_f "$1" "$2")" 2>/dev/null
}
# N NAME TEXT -> yes when r29's stdout has the line "  engine/harness/plants.md:N [NAME, name] TEXT"
# and the line after it begins "      ack: engine/harness/plants.md\t", a backslash and a t.
_b22r_hit() {
  _B22H="  engine/harness/plants.md:$1 [$2, name] $3" _B22K='      ack: engine/harness/plants.md\t' LC_ALL=C awk '
    p { if (index($0, ENVIRON["_B22K"]) == 1) f = 1; else g = g " then [" $0 "]"; p = 0 }
    $0 == ENVIRON["_B22H"] { p = 1; h = 1 }
    END { if (f) print "yes"; else if (h) print "[the hit has no ack line after it" g "]"; else print "[no line " ENVIRON["_B22H"] "]" }' \
    "$(_b22r_f r29 out)" 2>/dev/null
}
_b22r_nobuild() { if [ -e "$_b22r_t/out/$1/build" ]; then printf '[%s made out/%s/build]' "$1" "$1"; else printf 'no build'; fi; }   # RUN

# ---- the names stage: A20 to A23 -----------------------------------------------------------------
_b22r_is "snapshot run A20: with no lantern directory in the memory root it stops at exit 1, says so on stderr, and builds nothing (control)" \
  "$(_b22r_rc r20); $(_b22r_has r20 err 'no lantern directory in the memory root'); $(_b22r_nobuild r20)" "exit 1; yes; no build"
_b22r_is "snapshot run A21: a pointer naming a directory without projects/ stops it at exit 1, naming that directory on stderr (control)" \
  "$(_b22r_rc r21); $(_b22r_has r21 err "the home the engine points at, $_b22r_t/nowhere, has no projects/ to read")" "exit 1; yes"
_b22r_x='snapshot: audit names too short to search for; exclude each with a reviewed @name row, or rename:'
_b22r_is "snapshot run A22: a memory name under three characters with no @name row on origin/main stops it loudly at exit 1, listing qz and not zq, before any build (control)" \
  "$(_b22r_rc r22); $(_b22r_has r22 err "$_b22r_x"); $(_b22r_line r22 err '  qz'); $(_b22r_nobuild r22); zq named $(_b22r_word r22 err '' zq)" \
  "exit 1; yes; yes; no build; zq named no"
_b22r_is "snapshot run A23: the same row committed on the home but not pushed changes nothing, since only origin/main's acknowledgements count (control)" \
  "$(_b22r_rc r23); $(_b22r_has r23 err "$_b22r_x"); $(_b22r_line r23 err '  qz'); $(_b22r_nobuild r23); zq named $(_b22r_word r23 err '' zq)" \
  "exit 1; yes; yes; no build; zq named no"

# ---- the self-test runs: A24 to A28 --------------------------------------------------------------
if [ -n "$_b22r_tree" ]; then _b22r_x="a built tree line with 40 hex"; else _b22r_x="$(_b22r_begins r24 out 'built tree')"; fi
_b22r_is "snapshot run A24: with the row pushed, a run of C2 expecting tree 0 passes the names stage by the reviewed row, reads 2 rewritten and none open, prints the tree it built and DIFFER, and exits 1 (control)" \
  "$(_b22r_rc r24); $(_b22r_begins r24 out 'names: ' "1 of memory's excluded by a reviewed row"); $(_b22r_begins r24 out 'audit: ' '2 rewritten' 'none open'); $_b22r_x; $(_b22r_line r24 out DIFFER)" \
  "exit 1; yes; yes; a built tree line with 40 hex; yes" L
_b22r_b="$_b22r_t/out/r24/build"
_b22r_x="$(cat "$_b22r_b/engine/harness/notes.md" 2>/dev/null)"
_b22r_y="$(sed -n 2p "$_b22r_b/engine/harness/README.md" 2>/dev/null)"
_b22r_z="$(cd "$_b22r_b/projects" 2>/dev/null && LC_ALL=C ls -A | LC_ALL=C tr '\n' ' ')"
_b22r_w="$(sed -n 's/^[[:space:]]*"remote_match":[[:space:]]*"\([^"]*\)".*$/\1/p' "$_b22r_b/projects/lantern/project.json" 2>/dev/null)"
_b22r_v="$(find "$_b22r_b" -name autonomy 2>/dev/null | LC_ALL=C wc -l | LC_ALL=C tr -d ' ')"
_b22r_s=""; for _b22r_i in snapshot.sh snapshot-scrub.sh snapshot-audit.sh; do
  if [ ! -f "$_b22r_b/projects/lantern/$_b22r_i" ]; then _b22r_s="$_b22r_s $_b22r_i missing"
  elif cmp -s "$_b22r_b/projects/lantern/$_b22r_i" "$_b22r_src/$_b22r_i"; then _b22r_s="$_b22r_s same"
  else _b22r_s="$_b22r_s $_b22r_i differs"; fi
done
_b22r_is "snapshot run A25: that build holds the scrubbed phrase and halves, only the lantern project with the public remote, no autonomy file anywhere, and the three scripts byte for byte (control)" \
  "notes.md [$_b22r_x]; README.md:2 [$_b22r_y]; projects [$_b22r_z]; remote_match [$_b22r_w]; $_b22r_v autonomy files; scripts$_b22r_s" \
  "notes.md [the another governed project gate runs]; README.md:2 [a anot her line]; projects [lantern ]; remote_match [LeavesJ/Felix]; 0 autonomy files; scripts same same same" L
_b22r_is "snapshot run A26: that run's stdout passes on the scrub's report of the halves rewrite, a line from scrub: halves marigold to engine/harness/README.md:2" \
  "$(_b22r_ends r24 out 'scrub: halves marigold ' 'engine/harness/README.md:2')" yes L
_b22r_is "snapshot run A27: run again expecting the tree it printed, it prints MATCH and exits 0 (control)" \
  "$(_b22r_rc r27); $(_b22r_line r27 out MATCH)" "exit 0; yes" L
_b22r_is "snapshot run A28: a scrub that changes a line the audit reads no name on fails the cross-check closed at exit 1, naming README.md:1 (control)" \
  "$(_b22r_rc r28); $(_b22r_has r28 err 'the scrub changed lines the audit reads no name on:'); $(_b22r_line r28 err '  README.md:1')" "exit 1; yes; yes" L

# ---- the audit's stop: A29 to A31 ------------------------------------------------------------------
if [ -e "$_b22r_t/out/r29/clone" ]; then _b22r_x="[out/r29/clone was made]"; else _b22r_x="no clone"; fi
_b22r_is "snapshot run A29: the audit stops on a memory name, a name only the trimmed pointer reaches, a --name word and the home's basename, each with its ack row, and makes no clone (control)" \
  "$(_b22r_rc r29); $(_b22r_begins r29 out 'audit: STOP'); 4 $(_b22r_hit 4 tidewater 'a tidewater note'); 5 $(_b22r_hit 5 fernbrook 'a fernbrook note'); 6 $(_b22r_hit 6 saltmarsh 'a saltmarsh note'); 7 $(_b22r_hit 7 umberwick 'a umberwick note'); 3 $(_b22r_nobegin r29 out '  engine/harness/plants.md:3 '); 8 $(_b22r_nobegin r29 out '  engine/harness/plants.md:8 '); $_b22r_x" \
  "exit 1; yes; 4 yes; 5 yes; 6 yes; 7 yes; 3 none; 8 none; no clone" L
_b22r_is "snapshot run A30: each owner a manifest on main declares is an audit name searched whole, a governed project's (brackenhall, plants.md:1) and the home's own (quillcorp, plants.md:2)" \
  "1 $(_b22r_begins r29 out '  engine/harness/plants.md:1 [brackenhall, name]'); 2 $(_b22r_begins r29 out '  engine/harness/plants.md:2 [quillcorp, name]')" \
  "1 yes; 2 yes"
_b22r_is "snapshot run A31: an owner under three characters, zq, is said on the names line as not searched, in the self-test run and in the stopping run" \
  "r24 zq $(_b22r_word r24 out 'names: ' zq), $(_b22r_begins r24 out 'names: ' 'not searched'); r29 zq $(_b22r_word r29 out 'names: ' zq), $(_b22r_begins r29 out 'names: ' 'not searched')" \
  "r24 zq yes, yes; r29 zq yes, yes"

# ---- the public clone: A32 ---------------------------------------------------------------------------
_b22r_x="$(_b22r_g "$_b22r_p" for-each-ref --format='%(refname) %(objectname)' refs/heads 2>/dev/null)"
_b22r_y="$(cd "$_b22r_t/runs" 2>/dev/null && LC_ALL=C grep -l -F 'Nothing was pushed' ./*.out ./*.err 2>/dev/null | LC_ALL=C tr '\n' ' ')"
_b22r_n="$(cd "$_b22r_t/runs" 2>/dev/null && ls ./*.rc 2>/dev/null | LC_ALL=C wc -l | LC_ALL=C tr -d ' ')"
if [ "${_b22r_n:-0}" -ge 7 ]; then _b22r_z="every run was made"; else _b22r_z="only ${_b22r_n:-0} runs were made"; fi
_b22r_is "snapshot run A32: no run made or moved a ref in the public clone, which keeps main at its first commit, and none printed Nothing was pushed (control)" \
  "${_b22r_x//$_b22r_nl/ / }; $_b22r_z; Nothing was pushed in [$_b22r_y]" \
  "refs/heads/main ${_b22r_p0:-no first commit was made in P}; every run was made; Nothing was pushed in []"
