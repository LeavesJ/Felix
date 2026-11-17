printf '\nanswers delivered without being asked for\n'
# Blind, written 2026-10-29 from docs/2026-10-29-answers-delivered-spec.md alone, as amended after its six-lens review
# (its section 9): sections 2-6, A1-A4, U1-U5, T1-T2, R1-R4, L1-L5. lib/graph.sh past what part 0760 shows,
# lib/answer.sh, lib/ledger.sh, `felix ledger` and the user-prompt, post-tool, session-start and session-end hooks run
# here as black boxes; parts 0002, 0003, 0320, 0330, 0760 and 1130 were read for idioms, and lib/own.sh, lib/resolve.sh
# and lib/route.sh for what makes a checkout own and a prompt a person's. Why: the route named the graph in 15 sessions
# and it was reached in none (the spec's section 0), so its answer is handed over, in the own checkout only, once per
# node per session, in the spec's words, saying when it is partial, never at the prompt's cost; what the session
# reaches next is recorded as matches, never as values; and the answer is a ledger surface of its own.
# Fixture: home ansp (remote_match OwnerA/ansp-repo); checkouts own (three commits), its worktree two ahead, marker
# (.felix alone), foreign (an origin only containing the remote_match), nograph, and refresh (two commits). A stand-in
# graphify first on PATH logs each argv to $AX/glog as <word>s; `query` prints $AX/out.<v>, v read from $AX/gv (fail,
# hang, hangkid, exitkid, slow, slow3, slow4, slow6 and empty built in); any other first word is a refresh that waits for $AX/release and fails
# when $AX/ufail exists. The orders U1 and R1 set are read through a harness copy whose lib/own.sh and lib/graph.sh
# source the real ones and wrap felix_checkout_is_own and felix_graph_refresh_due to log each call: measured before
# the change, no user-prompt, post-tool or session-end run called the first, and the second did not exist. Extended
# blind to the spec's second amendment (section 9's last paragraph): a timeout that is not a whole number is the
# default, bytes are bytes under a UTF-8 locale, the marker is read only as a regular file's first 64 bytes (calls
# that could hang on it run under $AX/bound.pl, which kills their process group at its bound), a touch row T1 wrote
# credits its own file only, and A4's marker is renamed into place, never written through what stands at its path.
# After the merge of audit wave 2 (0.49.313): a post-tool run writes an alive line before its call row, and L1's
# fold finds a record whole by its alive lines against its calls, an answer row never counted as a call.
# v5, after the review of that merge (0.49.317), written blind from A1.5, A2.3, U4, U5, T2, L4 and L5 as amended: with no
# time left (FELIX_GRAPH_LEFT not a whole number of one or more) graphify is not run and the ask is late, and the bound is
# never longer than what is left; the hook passes FELIX_PROMPT_DEADLINE (30 unless a whole number of at most four digits)
# less its own seconds less 3, and writes its prompt row before it computes its route, read through the spy copy's
# lib/route.sh, whose route functions log the record as they find it and whose machine test can hold the hook 2 seconds;
# loading lib/ledger.sh or lib/graph.sh runs nothing on PATH; and L4 counts late asks apart and leaves a session whose
# ledger appends are not whole out of every column but unknown. lib/graph-answer.sh, which lib/graph.sh loads, is a black
# box here too. Time windows are wide enough for a loaded gate, and rows are read rather than clocks where both would do.
# v6, after the review of those fixes, written blind from A1.5, T2, L4 and L5 as amended: FELIX_GRAPH_LEFT and
# FELIX_GRAPH_TIMEOUT are read by value (0000000000 is 0, 0000000002 is 2, and 0000000009 and 0000000019 are 9 and 19,
# not octal), each of lib/ledger.sh and lib/graph.sh runs nothing on PATH when it is the first thing a fresh shell loads,
# a ledger file that is empty is a record left out like one not whole, and L5's left-out clause says the record is empty
# or incomplete.
AX="$TMP/answers"; mkdir -p "$AX/bin" "$AX/ssbin" "$AX/co" "$AX/user" "$AX/spy" "$AX/tmp" "$AX/cache" "$AX/home/projects/ansp" "$AX/mem/ansp"
AX="$(cd "$AX" && pwd -P)"; AXH="$AX/home"; AXM="$AX/mem"; AXP="$AXH/projects/ansp"; AXT="$(printf '\t')"; : > "$AX/glog"; : > "$AX/kids"
AXO="$AX/co/own"; AXW="$AX/co/own-wt"; AXK="$AX/co/marker"; AXF="$AX/co/foreign"; AXN="$AX/co/nograph"; AXR="$AX/co/refresh"
AXL="$AXO/graphify-out/.felix-refresh.lock"; AXMK="$AXO/graphify-out/.felix-refreshed-at"; AXQ="where does the answer block get built"
AXCUR="current with the checkout that holds it"; AXHEAD='answers handed to sessions without being asked for'
AXSHP='It finds where things are, not who calls them: in shell scripts the graph sees few callers, so for "what calls this" grep is still the oracle.'
AXSENT='A file the session would have opened anyway counts here too, so this is the most the answers can have caused, not what they caused.'
AXPART='These are 3 of the 11 nodes graphify found for it; graphify query with a larger --budget shows more.'
printf '{"name": "ansp", "remote_match": "OwnerA/ansp-repo", "gate": "true"}\n' > "$AXP/project.json"; printf '# ansp\n' > "$AXP/CLAUDE.md"
printf 'debug\tbroken failing crash\tcore\tsuperpowers:systematic-debugging\n' > "$AXP/routes.tsv"
printf 'plugin\tsuperpowers@x\t-\tlow\talways\nskill\tgraphify\t-\tlow\talways\n' > "$AXP/stack.tsv"
printf -- '- **L1 The quokka ledger is reconciled by hand.** Evidence would follow here.\n' > "$AXM/ansp/lessons.md"
_ax_git() { git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
_ax_files() {   # the files every checkout holds, written where the shell stands
  mkdir -p lib docs bin notes && printf '#!/bin/sh\necho one\n' > lib/one.sh && printf '# guide\n' > docs/guide.md \
    && printf '#!/usr/bin/env bash\necho tool\n' > bin/tool && printf '#!/bin/zsh\necho z\n' > bin/ztool \
    && printf '#!/usr/bin/env python3\nprint(1)\n' > bin/py && printf '#!/usr/bin/env%130s bash\necho long\n' '' > bin/longsh \
    && printf 'dots\n' > 'lib/a..b.txt' || return 1
  local i; for i in 1 2 3 4 5 6 7 8 9 10; do printf 'n%s\n' "$i" > "notes/n$i.md"; done
  for i in 60 50; do   # bin/envs60 names bash at bytes 140-143 (characters 80-83), bin/envs50 at bytes 120-123
    printf '#!/usr/bin/env -S %s bash\necho s\n' "$(awk -v n="$i" 'BEGIN { for (j = 0; j < n; j++) printf "\303\251" }')" > "bin/envs$i"
  done
}
mkdir -p "$AXO" "$AXK" "$AXF" "$AXN" "$AXR"
( _fx_cd "$AXO" && git init -q -b main && _ax_files && printf 'ansp\n' > .felix && git add -A && _ax_git commit -qm c1 \
  && printf '2\n' > c2.txt && git add -A && _ax_git commit -qm c2 && printf '3\n' > c3.txt && git add -A && _ax_git commit -qm c3 \
  && git remote add origin https://github.com/OwnerA/ansp-repo && git worktree add -q "$AXW" -b side ) >/dev/null 2>&1
( _fx_cd "$AXW" && printf 'w\n' > wtonly.md && git add -A && _ax_git commit -qm w1 && printf 'w\n' > w2.txt && git add -A \
  && _ax_git commit -qm w2 ) >/dev/null 2>&1
( _fx_cd "$AXK" && git init -q -b main && _ax_files && printf 'ansp\n' > .felix && printf 'k\n' > k.txt && git add -A \
  && _ax_git commit -qm k1 && printf 'k\n' > k2.txt && git add -A && _ax_git commit -qm k2 ) >/dev/null 2>&1
( _fx_cd "$AXF" && git init -q -b main && _ax_files && printf 'f\n' > f.txt && git add -A && _ax_git commit -qm f1 \
  && printf 'f\n' > f2.txt && git add -A && _ax_git commit -qm f2 && git remote add origin git@evil.example:OwnerA/ansp-repo.git ) >/dev/null 2>&1
( _fx_cd "$AXN" && git init -q -b main && printf 'n\n' > n.txt && git add -A && _ax_git commit -qm n1 ) >/dev/null 2>&1
( _fx_cd "$AXR" && git init -q -b main && printf '1\n' > r1.txt && git add -A && _ax_git commit -qm r1 && printf '2\n' > r2.txt \
  && git add -A && _ax_git commit -qm r2 ) >/dev/null 2>&1
printf 'held\n' > "$AXO/holdonly.md"; printf 'x\n' > "$AX/co/outside.txt"
AXO1="$(git -C "$AXO" rev-list --max-parents=0 HEAD 2>/dev/null)"; AXO3="$(git -C "$AXO" rev-parse HEAD 2>/dev/null)"
AXK1="$(git -C "$AXK" rev-list --max-parents=0 HEAD 2>/dev/null)"; AXF1="$(git -C "$AXF" rev-list --max-parents=0 HEAD 2>/dev/null)"
AXR1="$(git -C "$AXR" rev-list --max-parents=0 HEAD 2>/dev/null)"; AXR2="$(git -C "$AXR" rev-parse HEAD 2>/dev/null)"
_ax_stamp() {   # CHECKOUT COMMIT|- -> its graphify-out/graph.json, built at COMMIT, or carrying no stamp at all
  mkdir -p "$1/graphify-out" || return 1
  if [ "$2" = - ]; then printf '{"nodes":[]}\n'; else printf '{"nodes":[],"built_at_commit":"%s"}\n' "$2"; fi > "$1/graphify-out/graph.json"
}
_ax_mark() { if [ "$2" = - ]; then rm -f "$1/graphify-out/.felix-refreshed-at"; else printf '%s\n' "$2" > "$1/graphify-out/.felix-refreshed-at"; fi; }
_ax_stamp "$AXO" "$AXO3"; _ax_stamp "$AXK" "$(git -C "$AXK" rev-parse HEAD 2>/dev/null)"; _ax_stamp "$AXF" "$(git -C "$AXF" rev-parse HEAD 2>/dev/null)"
_ax_stamp "$AXR" "$AXR1"

cat > "$AX/bin/graphify" <<AXG
#!/bin/sh
{ for a in "\$@"; do printf '<%s> ' "\$a"; done; printf '\n'; } >> "$AX/glog"
if [ "\${1:-}" != query ]; then
  i=0; while [ ! -f "$AX/release" ] && [ "\$i" -lt 100 ]; do sleep 0.1; i=\$((i + 1)); done
  [ ! -f "$AX/ufail" ] || exit 3; exit 0
fi
printf 'graphify-stderr-noise\n' >&2
v="\$(cat "$AX/gv" 2>/dev/null)"
case "\$v" in
  fail) printf 'NODE one [src=lib/one.sh loc=L1 community=0]\n'; exit 3 ;;
  hang) printf 'NODE one [src=lib/one.sh loc=L1 community=0]\n'; exec sleep 10 ;;
  hangkid) sleep 12 & echo \$! >> "$AX/kids"; printf 'NODE one [src=lib/one.sh loc=L1 community=0]\n'; exec sleep 12 ;;
  exitkid) sleep 12 & echo \$! >> "$AX/kids"; printf 'NODE felix_one() [src=lib/one.sh loc=L83 community=3]\n'; exit 0 ;;
  slow) sleep 1; printf 'NODE felix_one() [src=lib/one.sh loc=L83 community=3]\n'; exit 0 ;;
  slow3) sleep 3; printf 'NODE felix_one() [src=lib/one.sh loc=L83 community=3]\n'; exit 0 ;;
  slow4) sleep 4; printf 'NODE felix_one() [src=lib/one.sh loc=L83 community=3]\n'; exit 0 ;;
  slow6) sleep 6; printf 'NODE felix_one() [src=lib/one.sh loc=L83 community=3]\n'; exit 0 ;;
esac
[ ! -f "$AX/out.\$v" ] || cat "$AX/out.\$v"
AXG
chmod +x "$AX/bin/graphify"
AXTRAV="Traversal: BFS depth=2 | Start: ['answer'] |"
{ printf '%s 11 nodes found\n' "$AXTRAV"
  printf 'NODE felix_one() [src=lib/one.sh loc=L83 community=3]\nNODE Guide heading [src=docs/guide.md loc=§0ae community=None]\n'
  printf 'NODE abs [src=/etc/hosts loc=L1 community=0]\nNODE none [src=None loc=None community=0]\nNODE up [src=../outside.txt loc=L2 community=0]\n'
  printf 'NODE inner up [src=lib/../lib/one.sh loc=L3 community=0]\nNODE missing [src=lib/missing.sh loc=L4 community=0]\n'
  printf 'NODE a directory [src=lib loc=L5 community=0]\nNODE notes heading [src=notes/n1.md loc=None community=2]\n'
  printf 'NODE second in one [src=lib/one.sh loc=L90 community=3]\nEDGE felix_one() --calls--> x [EXTRACTED]\n'; } > "$AX/out.mix"
printf 'NODE dotted name [src=lib/a..b.txt loc=None community=1]\n' > "$AX/out.dots"
AXL150="$(awk 'BEGIN { for (i = 0; i < 15; i++) printf "abcdefghij" }')"
printf 'NODE tab\there\001ctl\033[0mend [src=lib/one.sh loc=L7 community=0]\nNODE %s [src=docs/guide.md loc=L8 community=0]\n' "$AXL150" > "$AX/out.label"
printf 'NODE ctl [src=lib/o\001ne.sh loc=L\0029 community=0]\n' > "$AX/out.ctl"
AXE120="$(awk 'BEGIN { for (i = 0; i < 120; i++) printf "\303\251" }')"
printf 'NODE %s%s [src=docs/guide.md loc=L3 community=0]\n' "$AXE120" "$(awk 'BEGIN { for (i = 0; i < 10; i++) printf "\303\251" }')" > "$AX/out.utf8"
{ for _ax_i in 1 2 3 4 5 6 7 8 9 10; do printf 'NODE n%s [src=notes/n%s.md loc=L1 community=0]\n' "$_ax_i" "$_ax_i"; done
  printf 'NODE n1 again [src=notes/n1.md loc=L9 community=0]\n'; } > "$AX/out.many"
awk 'BEGIN { for (i = 1; i <= 20; i++) printf "NODE r%d [src=%s loc=L%d community=0]\n", i, (i % 2 ? "lib/one.sh" : "docs/guide.md"), i }' > "$AX/out.rows"
AXSH3='NODE felix_one() [src=lib/one.sh loc=L83 community=3]\nNODE Guide heading [src=docs/guide.md loc=None community=1]\nNODE second in one [src=lib/one.sh loc=L90 community=3]\n'
{ printf '%s 3 nodes found\n' "$AXTRAV"; printf '%b' "$AXSH3"; } > "$AX/out.shell"; { printf '%s 11 nodes found\n' "$AXTRAV"; printf '%b' "$AXSH3"; } > "$AX/out.part"
{ printf 'NODE felix_one() [src=lib/one.sh loc=L83 community=3]\nNODE felix_one renamed [src=lib/one.sh loc=L83 community=3]\n'
  printf 'NODE third in one [src=lib/one.sh loc=L120 community=3]\nNODE n2 heading [src=notes/n2.md loc=L4 community=0]\n'; } > "$AX/out.second"
{ printf '%s 2 nodes found\n' "$AXTRAV"; printf 'NODE Guide heading [src=docs/guide.md loc=L1 community=1]\nNODE main [src=bin/py loc=L2 community=1]\n'; } > "$AX/out.noshell"
printf 'NODE tool [src=bin/tool loc=L2 community=0]\n' > "$AX/out.envbash"; printf 'NODE ztool [src=bin/ztool loc=L2 community=0]\n' > "$AX/out.zsh"
printf 'NODE long [src=bin/longsh loc=L1 community=0]\n' > "$AX/out.longsh"
printf 'NODE envs [src=bin/envs60 loc=L1 community=0]\n' > "$AX/out.envs60"; printf 'NODE envs [src=bin/envs50 loc=L1 community=0]\n' > "$AX/out.envs50"
AXU8="$(locale -a 2>/dev/null | awk '{ l = tolower($0) } l == "c.utf-8" || l == "c.utf8" { c = $0 } l == "en_us.utf-8" || l == "en_us.utf8" { e = $0 }
  END { print (c != "" ? c : e) }')"   # a UTF-8 locale this machine has, C first; empty when it has neither
printf 'NODE held [src=holdonly.md loc=L1 community=0]\nNODE worktree only [src=wtonly.md loc=L2 community=0]\n' > "$AX/out.wt"
printf 'no nodes here\n{"json": true}\nNODE without brackets\n' > "$AX/out.garbage"
AXMIX="$(printf 'lib/one.sh\tL83\tfelix_one()\ndocs/guide.md\t§0ae\tGuide heading\nnotes/n1.md\t\tnotes heading\nlib/one.sh\tL90\tsecond in one')"
AXMANY="$(for _ax_i in 1 2 3 4 5 6 7 8; do printf 'notes/n%s.md\tL1\tn%s\n' "$_ax_i" "$_ax_i"; done; printf 'notes/n1.md\tL9\tn1 again')"
AXROWS="$(printf '  lib/one.sh:L83  felix_one()\n  docs/guide.md  Guide heading\n  lib/one.sh:L90  second in one')"
AXROWS2="$(printf '  lib/one.sh:L83  felix_one renamed\n  lib/one.sh:L120  third in one\n  notes/n2.md:L4  n2 heading')"
AXREC1="$(printf 'asked\tgraphify\tanswered\nroot\t%s\ngiven\tgraphify\t2\t3\nnode\tgraphify\tlib/one.sh\tL83\tfelix_one()\nnode\tgraphify\tdocs/guide.md\t\tGuide heading\nnode\tgraphify\tlib/one.sh\tL90\tsecond in one\nanswer\tgraphify\tlib/one.sh\nanswer\tgraphify\tdocs/guide.md' "$AXO")"
AXREC2="$(printf 'asked\tgraphify\tanswered\ngiven\tgraphify\t2\t-\nnode\tgraphify\tlib/one.sh\tL83\tfelix_one renamed\nnode\tgraphify\tlib/one.sh\tL120\tthird in one\nnode\tgraphify\tnotes/n2.md\tL4\tn2 heading\nanswer\tgraphify\tlib/one.sh\nanswer\tgraphify\tnotes/n2.md')"

_ax_argv() { local a; for a in "$@"; do printf '<%s> ' "$a"; done; }   # the stand-in's log line for these words
_ax_q() { _ax_argv query "$1" --budget "${2:-600}" --graph "$AXO/graphify-out/graph.json"; }; _ax_log() { cat "$AX/glog" 2>/dev/null; }
_ax_lib() {   # FUNCTION ARGS... with the libs sourced, the stand-in first on PATH, the locale AX_LC when it is set, and
              # FELIX_GRAPH_LEFT set to AX_LEFT when that is set, empty included, and unset otherwise
  ( PATH="${AX_PATH:-$AX/bin:$PATH}"; FELIX_HOME="$AXH"; FELIX_MEMORY="$AXM"; export PATH FELIX_HOME FELIX_MEMORY
    [ -z "${AX_LC:-}" ] || { LANG="$AX_LC"; LC_ALL="$AX_LC"; export LANG LC_ALL; }
    if [ -n "${AX_LEFT+set}" ]; then FELIX_GRAPH_LEFT="$AX_LEFT"; export FELIX_GRAPH_LEFT; else unset FELIX_GRAPH_LEFT; fi
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/own.sh"; . "$FROOT/harness/lib/ledger.sh"; . "$FROOT/harness/lib/graph.sh"
    [ ! -f "$FROOT/harness/lib/answer.sh" ] || . "$FROOT/harness/lib/answer.sh"; "$@" )
}
cat > "$AX/bound.pl" <<'AXB'
my $s = shift @ARGV; my $p = fork; defined $p or exit 125;
if (!$p) { setpgrp(0, 0); exec { $ARGV[0] } @ARGV; exit 127 }
setpgrp($p, $p); my $held = 0; $SIG{ALRM} = sub { $held = 1; kill 'KILL', -$p };
alarm $s; 1 while waitpid($p, 0) == -1 && $!{EINTR}; my $st = $?; alarm 0;
if ($held) { kill 'KILL', -$p; exit 124 }
exit(($st & 127) ? 128 + ($st & 127) : $st >> 8);
AXB
{ printf '#!/bin/bash\nPATH="%s/bin:$PATH"; FELIX_HOME="%s"; FELIX_MEMORY="%s"; export PATH FELIX_HOME FELIX_MEMORY\n' "$AX" "$AXH" "$AXM"
  printf '. "%s/harness/lib/%s.sh"\n' "$FROOT" resolve "$FROOT" own "$FROOT" ledger "$FROOT" graph
  printf '[ ! -f "%s/harness/lib/answer.sh" ] || . "%s/harness/lib/answer.sh"\n"$@"\n' "$FROOT" "$FROOT"; } > "$AX/libcall"
_ax_bdue() {   # ROOT -> "<status>|<output>" of felix_graph_refresh_due there, or "held|..." when it ran past 15 seconds and was killed
  local o r; o="$(perl "$AX/bound.pl" 15 "$BASH" "$AX/libcall" felix_graph_refresh_due "$1" 2>&1)"; r=$?
  if [ "$r" = 124 ]; then printf 'held|%s' "$o"; else printf '%s|%s' "$r" "$o"; fi
}
_ax_ans() {   # VARIANT ROOT PROMPT -> AXOUT, what felix_graph_answer printed, and AXRC; $AX/glog holds this call alone
  printf '%s' "$1" > "$AX/gv"; : > "$AX/glog"
  AXOUT="$(_ax_lib felix_graph_answer "$2" "$3" 2>/dev/null)"; AXRC=$?
}
_ax_dl() {    # VARIANT HOME SESSION ROOT [PROMPT] -> AXOUT, the block felix_graph_deliver printed, AXRC, and its stderr in $AX/dl.err
  printf '%s' "$1" > "$AX/gv"; : > "$AX/glog"
  AXOUT="$(_ax_lib felix_graph_deliver "$2" "$3" "$4" "${5:-$AXQ}" 2>"$AX/dl.err")"; AXRC=$?
}
_ax_par() {   # TEXT N [c] -> its Nth paragraph; with c, every run of whitespace one space and the ends trimmed
  awk -v n="$2" -v c="${3:-}" 'BEGIN { RS = "" } NR == n { if (c != "") { gsub(/[ \t\n]+/, " "); sub(/^ /, ""); sub(/ $/, "") } print }' <<<"$1"
}
_ax_npar() { awk 'BEGIN { RS = "" } END { print NR }' <<<"$1"; }; _ax_ck() { if [ -f "$1" ]; then cksum < "$1"; else printf 'none'; fi; }
_ax_hd() {    # SHA FRESHNESS -> the block's first paragraph as one line; SHA - for a graph whose stamp says nothing usable
  if [ "$1" = - ]; then printf "The knowledge graph's answer to this prompt (graphify query, graph carrying no build stamp). Where it places what was asked, to open first:"
  else printf "The knowledge graph's answer to this prompt (graphify query, graph built at %s, %s). Where it places what was asked, to open first:" "${1:0:7}" "$2"; fi
}
_ax_nl() { if [ -f "$1" ]; then awk 'END { print NR }' "$1"; else printf '0'; fi; }; _ax_since() { awk -v n="$2" 'NR > n' "$1" 2>/dev/null; }
_ax_have() { local t; for t in "$@"; do command -v "$t" >/dev/null 2>&1 || return 1; done; }
_ax_sans() {   # NAME DIR -> this PATH, each entry holding NAME replaced by a directory of links to all its other commands
  local IFS=: d out="" n=0
  for d in $PATH; do
    if [ -n "$d" ] && [ -f "$d/$1" ]; then n=$((n + 1)); mkdir -p "$2/$n" && ln -s "$d"/* "$2/$n/" 2>/dev/null; rm -f "$2/$n/$1"; d="$2/$n"; fi
    out="$out${out:+:}$d"
  done
  printf '%s' "$out"
}
_ax_own() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/own.sh"; felix_checkout_is_own "$AXP" "$1" >/dev/null 2>&1; printf '%s' "$?" ); }
_ax_res() { local p; p="$( . "$FROOT/harness/lib/resolve.sh"; felix_resolve_project "$1" "$AXH" 2>/dev/null )"; printf '%s' "${p##*/}"; }
_ax_wait() { local i=0; while [ "$i" -lt "$(( $1 * 10 ))" ]; do eval "$2" && return 0; sleep 0.1; i=$((i + 1)); done; eval "$2"; }
_ax_alive() { local p n=0; for p in $(cat "$AX/kids" 2>/dev/null); do kill -0 "$p" 2>/dev/null && n=$((n + 1)); done; printf '%s' "$n"; }
_ax_kids() { local p; for p in $(cat "$AX/kids" 2>/dev/null); do kill "$p" 2>/dev/null; done; : > "$AX/kids"; }
_ax_secs() { if [ "$_ax_dt" -le "$1" ]; then printf 'prompt'; else printf 'waited %ss' "$_ax_dt"; fi; }
_ax_nq() { awk 'index($0, "<query> ") != 1 { n++ } END { print n + 0 }' "$AX/glog"; }
_ax_nqp() { awk -v d="<$1>" 'index($0, "<query> ") != 1 && index($0, d) { n++ } END { print n + 0 }' "$AX/glog"; }
_ax_release() {   # lets a waiting refresh finish, and waits ten seconds at most for every fixture lock to go
  : > "$AX/release"
  _ax_wait 10 '[ ! -d "$AXL" ] && [ ! -d "$AXK/graphify-out/.felix-refresh.lock" ] && [ ! -d "$AXF/graphify-out/.felix-refresh.lock" ] && [ ! -d "$AXR/graphify-out/.felix-refresh.lock" ]'
  rm -f "$AX/release"
}
_ax_bg() { ( PATH="$AX/bin:$PATH"; export PATH; [ -z "${AX_STALE:-}" ] || { FELIX_GRAPH_LOCK_STALE="$AX_STALE"; export FELIX_GRAPH_LOCK_STALE; }
             . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/graph.sh"; felix_graph_refresh_bg "${1:-$AXO}" ) 2>&1; }
_ax_hcopy() {   # DIR -> DIR/harness, a copy of the suite's harness with its tests left out
  local x; mkdir -p "$1/harness" || return 1
  for x in "$FROOT/harness"/*; do case "$x" in */tests) ;; *) cp -R "$x" "$1/harness/" ;; esac; done
}
_ax_spy() {   # LIB FUNCTION -> the spy copy's lib/LIB.sh sources the real one, then wraps FUNCTION to log "<last word> <hook>"
  local l="$AX/hs/harness/lib" w="${2##*_}"; mv "$l/$1.sh" "$l/$1.orig.sh" || return 1
  { printf '. "${BASH_SOURCE%%/*}/%s.orig.sh"\n' "$1"
    printf 'case "$(declare -f %s 2>/dev/null)" in\n  ""|*_ax_spied_%s*) ;;\n' "$2" "$w"
    printf '  *) eval "_ax_spied_%s() $(declare -f %s | sed 1d)"\n' "$w" "$2"
    printf '     %s() { printf "%%s %%s\\n" %s "${0##*/}" >> "%s/calls"; _ax_spied_%s "$@"; } ;;\nesac\n' "$2" "$w" "$AX" "$w"
  } > "$l/$1.sh"
}
_ax_rspy() {   # the spy copy's lib/route.sh sources the real one, then wraps felix_route_machine to hold the hook 2 seconds, once, while
               # $AX/slowroute exists, and the two functions a route is computed with to log, as each is called, u5r's second row
  local l="$AX/hs/harness/lib"; mv "$l/route.sh" "$l/route.orig.sh" || return 1
  { printf '_ax_sp_ax=%q; _ax_sp_rec=%q\n' "$AX" "$AXH/state/answer/u5r.tsv"; cat <<'AXR'
. "${BASH_SOURCE%/*}/route.orig.sh"
_ax_wrap() {   # FUNCTION CODE -> FUNCTION runs CODE, then itself as it was
  case "$(declare -f "$1" 2>/dev/null)" in ""|*_ax_spied_"$1"*) return 0 ;; esac
  eval "_ax_spied_$1() $(declare -f "$1" | sed 1d)"; eval "$1() { $2; _ax_spied_$1 \"\$@\"; }"
}
_ax_wrap felix_route_machine 'if [ -f "$_ax_sp_ax/slowroute" ]; then rm -f "$_ax_sp_ax/slowroute"; sleep 2; fi'
_ax_wrap felix_route_context 'printf "context %s\n" "$(sed -n 2p "$_ax_sp_rec" 2>/dev/null)" >> "$_ax_sp_ax/rcalls"'
_ax_wrap felix_route_best 'printf "best %s\n" "$(sed -n 2p "$_ax_sp_rec" 2>/dev/null)" >> "$_ax_sp_ax/rcalls"'
unset -f _ax_wrap
AXR
  } > "$l/route.sh"
}
_ax_hcopy "$AX/hs"; _ax_spy own felix_checkout_is_own; _ax_spy graph felix_graph_refresh_due; _ax_rspy; : > "$AX/calls"; : > "$AX/rcalls"
_ax_spyck() { ( . "$AX/hs/harness/lib/resolve.sh"; . "$AX/hs/harness/lib/own.sh"; . "$AX/hs/harness/lib/graph.sh"; . "$AX/hs/harness/lib/route.sh"
  case "$(declare -f felix_checkout_is_own)" in *_ax_spied_own*) printf 'own wrapped' ;; *) printf 'own not wrapped' ;; esac
  case "$(declare -f felix_graph_refresh_due)" in '') printf ', no due test' ;; *_ax_spied_due*) printf ', due wrapped' ;; *) printf ', due not wrapped' ;; esac
  case "$(declare -f felix_route_machine; declare -f felix_route_best)" in *_ax_spied_felix_route_machine*_ax_spied_felix_route_best*) printf ', route wrapped' ;; *) printf ', route not wrapped' ;; esac ) 2>/dev/null; }
AXNOG="$(_ax_sans graphify "$AX/farm-g")"; AXNOP="$AX/bin:$(_ax_sans perl "$AX/farm-p")"
is "answers fixture: own and its worktree are ansp's own checkouts, marker and foreign are bound to ansp and not own (fixture control)" \
   "$(_ax_own "$AXO")$(_ax_own "$AXW")$(_ax_own "$AXK")$(_ax_own "$AXF") $(_ax_res "$AXO") $(_ax_res "$AXW") $(_ax_res "$AXK") $(_ax_res "$AXF")" "0011 ansp ansp ansp ansp"
is "answers fixture: own has three commits, its worktree two more, refresh two, and every other checkout a commit (fixture control)" \
   "$(git -C "$AXO" rev-list --count HEAD 2>/dev/null) $(git -C "$AXW" rev-list --count HEAD 2>/dev/null) $(git -C "$AXR" rev-list --count HEAD 2>/dev/null) $([ -n "$AXK1" ] && [ -n "$AXF1" ] && [ -n "$(git -C "$AXN" rev-parse HEAD 2>/dev/null)" ] && echo made)" "3 5 2 made"
is "answers fixture: one PATH has no graphify and one no perl, and both still have git, awk and sed (fixture control)" \
   "$( PATH="$AXNOG"; _ax_have graphify || printf 'no-graphify '; _ax_have git awk sed && printf 'tools '; PATH="$AXNOP"; _ax_have perl || printf 'no-perl '; _ax_have git awk sed graphify && printf 'tools' )" \
   "no-graphify tools no-perl tools"
AXSPYN="answers fixture: the spy harness wraps felix_checkout_is_own, felix_graph_refresh_due wherever lib/graph.sh defines it, and the route functions (fixture control)"
case "$(_ax_spyck)" in "own wrapped, no due test, route wrapped"|"own wrapped, due wrapped, route wrapped") ok "$AXSPYN" ;; *) bad "$AXSPYN" "got [$(_ax_spyck)]" ;; esac

printf '\nA1: felix_graph_answer, the graph asked the prompt\n'
_ax_ans mix "$AXO" "$AXQ"
is "A1: felix_graph_answer prints a src, loc and label row for each node it keeps, in graphify's order, and exits 0" "$AXRC|$AXOUT" "0|$AXMIX"
is "A1.5: it runs graphify once, exactly: query, the prompt, --budget 600 and --graph naming the graph file" "$(_ax_log)" "$(_ax_q "$AXQ")"
is "A1.5: graphify's stderr is discarded, so stdout and stderr together are the rows alone" "$(_ax_lib felix_graph_answer "$AXO" "$AXQ" 2>&1)" "$AXMIX"
FELIX_GRAPH_BUDGET=1234 _ax_ans mix "$AXO" "$AXQ"
is "A1.5: FELIX_GRAPH_BUDGET is the budget it passes" "$(_ax_log)" "$(_ax_q "$AXQ" 1234)"
FELIX_GRAPH_ANSWER=0 _ax_ans mix "$AXO" "$AXQ"
is "A1.1: with FELIX_GRAPH_ANSWER=0 it prints nothing, exits 1 and runs nothing" "$AXRC|$AXOUT|$(_ax_log)" "1||"
_ax_ans mix "$AXN" "$AXQ"
is "A1.2: a checkout with no graph file gets nothing and exit 1, and graphify is not run" "$AXRC|$AXOUT|$(_ax_log)" "1||"
_ax_ans wt "$AXW" "$AXQ"
is "A1.2: from a worktree it asks the graph of the checkout that holds it" "$(_ax_log)" "$(_ax_q "$AXQ")"
is "A1.6: and keeps a node only for a file under that holding checkout, not one the worktree alone holds" "$AXRC|$AXOUT" "0|holdonly.md${AXT}L1${AXT}held"
AX_PATH="$AXNOG" _ax_ans mix "$AXO" "$AXQ"
is "A1.3: with no graphify on PATH it prints nothing and exits 1" "$AXRC|$AXOUT" "1|"
AX_PATH="$AXNOP" _ax_ans mix "$AXO" "$AXQ"
is "A1.3: with graphify on PATH and no perl it prints nothing, exits 1 and does not run graphify" "$AXRC|$AXOUT|$(_ax_log)" "1||"
_ax_ans mix "$AXO" "four words only here"
is "A1.4: a prompt of four words, under the default floor of five, runs nothing and exits 1" "$AXRC|$AXOUT|$(_ax_log)" "1||"
FELIX_GRAPH_MIN_WORDS=4 _ax_ans mix "$AXO" "four words only here"
is "A1.4: FELIX_GRAPH_MIN_WORDS=4 lets the same four words through" "$AXRC|$(_ax_log)" "0|$(_ax_q "four words only here")"
_ax_ans mix "$AXO" "$(printf '  where\tdoes   the\nanswer block\\nget\\tbuilt\\rnow  ')"
is "A1.4: spaces, tabs, newlines and the two-character escapes for newline, tab and return are one space each, the ends trimmed" \
   "$(_ax_log)" "$(_ax_q "where does the answer block get built now")"
_ax_ans mix "$AXO" 'one\ntwo\tthree\rfour'
is "A1.4: four words joined only by those escapes are four words, and run nothing" "$AXRC|$(_ax_log)" "1|"
_ax_ans mix "$AXO" 'one\ntwo\tthree\rfour five'
is "A1.4: and five words so joined are five, asked as five" "$AXRC|$(_ax_log)" "0|$(_ax_q "one two three four five")"
_ax_ans mix "$AXO" "$(awk 'BEGIN { for (i = 0; i < 200; i++) printf "ab " }')"
is "A1.4: a prompt longer than 400 characters is cut to its first 400" "$(_ax_log)" "$(_ax_q "$(awk 'BEGIN { for (i = 0; i < 133; i++) printf "ab " }')a")"
_ax_ans fail "$AXO" "$AXQ"
is "A1.5: a graphify that exits non-zero is no answer, the node it printed included: nothing printed, exit 1" "$AXRC|$AXOUT" "1|"
_ax_ans empty "$AXO" "$AXQ"
is "A1.5: a graphify that prints nothing is no answer: exit 1" "$AXRC|$AXOUT" "1|"
_ax_t0=$SECONDS; FELIX_GRAPH_TIMEOUT=1 _ax_ans hang "$AXO" "$AXQ"; _ax_dt=$((SECONDS - _ax_t0))
is "A1.5: a graphify that hangs past FELIX_GRAPH_TIMEOUT=1 is no answer: nothing printed, exit 1, back within 8 seconds where it would run 10" "$AXRC|$AXOUT|$(_ax_secs 8)" "1||prompt"
FELIX_GRAPH_TIMEOUT=1 _ax_ans slow3 "$AXO" "$AXQ"
is "A1.5: FELIX_GRAPH_TIMEOUT=1 is the bound itself: a graphify answering after 3 seconds, inside the default 4, is killed: no answer, exit 1" "$AXRC|$AXOUT" "1|"
_ax_kids; _ax_t0=$SECONDS; FELIX_GRAPH_TIMEOUT=1 _ax_ans hangkid "$AXO" "$AXQ"; _ax_dt=$((SECONDS - _ax_t0)); _ax_wait 5 '[ "$(_ax_alive)" = 0 ]'
is "A1.5: at the deadline its whole process group is killed, so a child holding the output open neither holds the caller past 8 seconds nor outlives it" \
   "$AXRC|$AXOUT|$(_ax_secs 8)|$(_ax_alive) left" "1||prompt|0 left"
_ax_kids; _ax_t0=$SECONDS; _ax_ans exitkid "$AXO" "$AXQ"; _ax_dt=$((SECONDS - _ax_t0)); _ax_wait 5 '[ "$(_ax_alive)" = 0 ]'
is "A1.5: a graphify that exits by itself leaving a child holding the output open is read at once, and the child is killed then" \
   "$AXRC|$AXOUT|$(_ax_secs 8)|$(_ax_alive) left" "0|lib/one.sh${AXT}L83${AXT}felix_one()|prompt|0 left"
_ax_kids; _ax_r=""; for _ax_v in 0 0.5 abc; do FELIX_GRAPH_TIMEOUT="$_ax_v" _ax_ans hang "$AXO" "$AXQ"; _ax_r="$_ax_r$_ax_v:$AXRC:${#AXOUT} "; done
is "A1.5: a FELIX_GRAPH_TIMEOUT of 0, 0.5 or abc is the default 4 seconds, so a graphify running 10 is still killed: no answer, exit 1" "$_ax_r" "0:1:0 0.5:1:0 abc:1:0 "
FELIX_GRAPH_TIMEOUT=0.5 _ax_ans slow "$AXO" "$AXQ"
is "A1.5: and under FELIX_GRAPH_TIMEOUT=0.5 a graphify answering after 1 second is answered, the bound not cut below the default" \
   "$AXRC|$AXOUT" "0|lib/one.sh${AXT}L83${AXT}felix_one()"
_ax_r=""; for _ax_v in 0 -2 abc 1.5; do AX_LEFT="$_ax_v" _ax_ans mix "$AXO" "$AXQ"; _ax_r="$_ax_r$_ax_v:$AXRC:${#AXOUT}:$(_ax_nl "$AX/glog") "; done
is "A1.5: a FELIX_GRAPH_LEFT of 0, -2, abc or 1.5, no whole number of one or more, is no time left: nothing printed, exit 1, graphify not run" \
   "$_ax_r" "0:1:0:0 -2:1:0:0 abc:1:0:0 1.5:1:0:0 "
AX_LEFT= _ax_ans mix "$AXO" "$AXQ"
is "A1.5: a FELIX_GRAPH_LEFT that is set and empty sets no limit: graphify is asked as before, and its answer printed" "$AXRC|$AXOUT|$(_ax_log)" "0|$AXMIX|$(_ax_q "$AXQ")"
AX_LEFT=1 FELIX_GRAPH_TIMEOUT=12 _ax_ans slow4 "$AXO" "$AXQ"
is "A1.5: with 1 second left under FELIX_GRAPH_TIMEOUT=12, a graphify answering after 4 seconds is killed once that second is up: no answer, exit 1" \
   "$AXRC|$AXOUT" "1|"
AX_LEFT=10 FELIX_GRAPH_TIMEOUT=12 _ax_ans slow4 "$AXO" "$AXQ"
is "A1.5: and with 10 seconds left the same graphify is answered (control)" "$AXRC|$AXOUT" "0|lib/one.sh${AXT}L83${AXT}felix_one()"
AX_LEFT=0000000000 _ax_ans mix "$AXO" "$AXQ"
is "A1.5: FELIX_GRAPH_LEFT is read by value, leading zeros not counting: 0000000000 is 0, no time left, so nothing printed, exit 1, graphify not run" \
   "$AXRC|$AXOUT|$(_ax_nl "$AX/glog")" "1||0"
AX_LEFT=0000000002 FELIX_GRAPH_TIMEOUT=12 _ax_ans slow6 "$AXO" "$AXQ"
is "A1.5: and 0000000002 is 2: graphify is asked, and one answering after 6 seconds under FELIX_GRAPH_TIMEOUT=12 is killed once those 2 seconds are up" \
   "$AXRC|$AXOUT|$(_ax_nl "$AX/glog")" "1||1"
AX_LEFT=0000000009 FELIX_GRAPH_TIMEOUT=12 _ax_ans slow4 "$AXO" "$AXQ"
is "A1.5: and 0000000009 is 9, its digits not read as octal: under FELIX_GRAPH_TIMEOUT=12 a graphify answering after 4 seconds is answered" \
   "$AXRC|$AXOUT" "0|lib/one.sh${AXT}L83${AXT}felix_one()"
FELIX_GRAPH_TIMEOUT=0000000001 _ax_ans slow3 "$AXO" "$AXQ"
is "A1.5: FELIX_GRAPH_TIMEOUT is read by value too: 0000000001 is the bound 1, so a graphify answering after 3 seconds, inside the default 4, is killed" \
   "$AXRC|$AXOUT" "1|"
FELIX_GRAPH_TIMEOUT=0000000000 _ax_ans hang "$AXO" "$AXQ"
is "A1.5: and a FELIX_GRAPH_TIMEOUT of 0000000000 is 0, so the default 4 and not no bound: a graphify that would run 10 seconds is killed: no answer, exit 1" \
   "$AXRC|$AXOUT" "1|"
FELIX_GRAPH_TIMEOUT=0000000019 _ax_ans slow6 "$AXO" "$AXQ"
is "A1.5: and one of 0000000019 is 19, not the default 4 nor an octal error: a graphify answering after 6 seconds is answered" "$AXRC|$AXOUT" "0|lib/one.sh${AXT}L83${AXT}felix_one()"
_ax_ans garbage "$AXO" "$AXQ"
is "A1.9: output with no NODE line of the form keeps no node: nothing printed, exit 1" "$AXRC|$AXOUT" "1|"
_ax_ans dots "$AXO" "$AXQ"
is "A1.6: a name holding .. that is not a .. segment is kept, and a loc of None prints as empty" "$AXRC|$AXOUT" "0|lib/a..b.txt${AXT}${AXT}dotted name"
_ax_ans label "$AXO" "$AXQ"
is "A1.6, A1.7: a label loses its tab and control bytes and is cut to 120 characters" "$AXOUT" "$(printf 'lib/one.sh\tL7\ttabherectl[0mend\ndocs/guide.md\tL8\t%s' "${AXL150:0:120}")"
_ax_ans ctl "$AXO" "$AXQ"
is "A1.6: control bytes are removed from src and loc too, before the file is looked for" "$AXRC|$AXOUT" "0|lib/one.sh${AXT}L9${AXT}ctl"
_ax_ans utf8 "$AXO" "$AXQ"
is "A1.7: a label of two-byte characters is cut to 120 characters, not 120 bytes, and never inside one" "$AXRC|$AXOUT" "0|docs/guide.md${AXT}L3${AXT}$AXE120"
_ax_ans many "$AXO" "$AXQ"
is "A1.8: rows stop at eight distinct files, and a later node of a file already listed is still printed" "$AXOUT" "$AXMANY"
FELIX_GRAPH_FILES=2 _ax_ans many "$AXO" "$AXQ"
is "A1.8: FELIX_GRAPH_FILES=2 stops at two files, the first file's later node still printed" "$AXOUT" "$(printf 'notes/n1.md\tL1\tn1\nnotes/n2.md\tL1\tn2\nnotes/n1.md\tL9\tn1 again')"
_ax_ans rows "$AXO" "$AXQ"
is "A1.8: and never more than 16 rows in all" "$(awk 'END { print NR }' <<<"$AXOUT") $(tail -1 <<<"$AXOUT" | cut -f3)" "16 r16"

printf '\nA2: felix_graph_deliver, the block, once per node per session\n'
_ax_stamp "$AXO" "$AXO3"; _ax_dl shell "$AXH" d1 "$AXO"
is "A2.7: the block opens with graphify query, the stamp's first seven characters, current with the checkout that holds it, and to open first" \
   "$AXRC|$(_ax_par "$AXOUT" 1 c)" "0|$(_ax_hd "$AXO3" "$AXCUR")"
is "A2.7: then a blank line and a row a node: two spaces, src:loc, two spaces, the label, and src alone where loc is empty" "$(_ax_par "$AXOUT" 2)" "$AXROWS"
is "A2.9: a shell script among the files ends the block with the paragraph about callers, and graphify's count equal to the rows adds no A2.8 line" \
   "$(_ax_npar "$AXOUT")|$(_ax_par "$AXOUT" 3 c)" "3|$AXSHP"
is "A2.3, A2.5: the record gains the asked row, the session's root, given with the files and graphify's count, a node row a node, an answer row a file" \
   "$(cat "$AXH/state/answer/d1.tsv" 2>/dev/null)" "$AXREC1"
is "A2.6: and the session's ledger one answer graphify signal" "$(cat "$AXH/state/ledger/d1.tsv" 2>/dev/null)" "answer${AXT}graphify"
_ax_n="$(_ax_nl "$AXH/state/answer/d1.tsv")"; _ax_sum="$(_ax_ck "$AXH/state/ledger/d1.tsv")"; _ax_dl shell "$AXH" d1 "$AXO"
is "A2.3, A2.4: the same nodes again in that session print nothing and exit 1, the record gaining only asked graphify repeat and the ledger nothing" \
   "$AXRC|$AXOUT|$(_ax_since "$AXH/state/answer/d1.tsv" "$_ax_n")|$(_ax_ck "$AXH/state/ledger/d1.tsv")" "1||asked${AXT}graphify${AXT}repeat|$_ax_sum"
_ax_n="$(_ax_nl "$AXH/state/answer/d1.tsv")"; _ax_dl second "$AXH" d1 "$AXO"
is "A2.4: a node new by its label or by its line, in a file named earlier, is delivered, and the node given before is not" \
   "$AXRC|$(_ax_par "$AXOUT" 2)|$(_ax_npar "$AXOUT")" "0|$AXROWS2|3"
is "A2.5: its rows follow with no second root row, the count - where graphify printed none, and an answer row again for the file named before" \
   "$(_ax_since "$AXH/state/answer/d1.tsv" "$_ax_n")" "$AXREC2"
is "A2.6: one ledger signal a delivery, so two after two deliveries" "$(cat "$AXH/state/ledger/d1.tsv" 2>/dev/null)" "$(printf 'answer\tgraphify\nanswer\tgraphify')"
_ax_dl shell "$AXH" d2 "$AXO"
is "A2.3: another session is given the whole answer, the record being the session's own" "$AXRC|$(_ax_par "$AXOUT" 2)" "0|$AXROWS"
mkdir -p "$AXH/state/answer"; printf 'node\tothertool\tlib/one.sh\tL83\tfelix_one()\n' > "$AXH/state/answer/d3.tsv"; _ax_dl shell "$AXH" d3 "$AXO"
is "A2.4: a node recorded as another tool's is not dropped from graphify's answer" "$(_ax_par "$AXOUT" 2)" "$AXROWS"
_ax_dl part "$AXH" d4 "$AXO"
is "A2.8: graphify having found more nodes than the rows printed, a blank line and the line saying how many of how many follow the rows" \
   "$(_ax_npar "$AXOUT")|$(_ax_par "$AXOUT" 3 c)|$(_ax_par "$AXOUT" 4 c)" "4|$AXPART|$AXSHP"
mkdir -p "$AX/h-empty"; _ax_r=""; for _ax_s in '' s.1 s/1 's 1' ../s1; do _ax_dl shell "$AX/h-empty" "$_ax_s" "$AXO"; _ax_r="$_ax_r$AXRC:${#AXOUT} "; done
is "A2.1: a session id that is empty or holds anything but letters, digits, - and _ prints nothing, exits 1 and writes nothing" \
   "$_ax_r$(find "$AX/h-empty" -type f | wc -l | tr -d ' ') files" "1:0 1:0 1:0 1:0 1:0 0 files"
_ax_dl shell "$AXH" s-1_A "$AXO"
is "A2.1: and one of letters, digits, - and _ is answered" "$AXRC" "0"
_ax_rl() { printf '%s:%s ' "$AXRC" "$(_ax_log | awk 'END { print NR }')"; }
_ax_r=""; FELIX_GRAPH_ANSWER=0 _ax_dl shell "$AX/h-empty" a1 "$AXO"; _ax_r="$_ax_r$(_ax_rl)"; _ax_dl shell "$AX/h-empty" a2 "$AXN"; _ax_r="$_ax_r$(_ax_rl)"
_ax_dl shell "$AX/h-empty" a3 "$AXO" "four words only here"; _ax_r="$_ax_r$(_ax_rl)"
AX_PATH="$AXNOG" _ax_dl shell "$AX/h-empty" a4 "$AXO"; _ax_r="$_ax_r$(_ax_rl)"; AX_PATH="$AXNOP" _ax_dl shell "$AX/h-empty" a5 "$AXO"; _ax_r="$_ax_r$(_ax_rl)"
is "A2.2: when A1 refuses before graphify is asked (switched off, no graph, four words, no graphify, no perl) it exits 1 and writes nothing" \
   "$_ax_r$(find "$AX/h-empty" -type f | wc -l | tr -d ' ') files" "1:0 1:0 1:0 1:0 1:0 0 files"
_ax_r=""; AX_LEFT=0 FELIX_GRAPH_ANSWER=0 _ax_dl shell "$AX/h-empty" b1 "$AXO"; _ax_r="$_ax_r$(_ax_rl)"; AX_LEFT=0 _ax_dl shell "$AX/h-empty" b2 "$AXN"; _ax_r="$_ax_r$(_ax_rl)"
AX_LEFT=0 _ax_dl shell "$AX/h-empty" b3 "$AXO" "four words only here"; _ax_r="$_ax_r$(_ax_rl)"
AX_LEFT=0 AX_PATH="$AXNOG" _ax_dl shell "$AX/h-empty" b4 "$AXO"; _ax_r="$_ax_r$(_ax_rl)"; AX_LEFT=0 AX_PATH="$AXNOP" _ax_dl shell "$AX/h-empty" b5 "$AXO"; _ax_r="$_ax_r$(_ax_rl)"
is "A2.2: with no time left as well, those refusals still come first: exit 1 and nothing written, so no late row" \
   "$_ax_r$(find "$AX/h-empty" -type f | wc -l | tr -d ' ') files" "1:0 1:0 1:0 1:0 1:0 0 files"
_ax_oc() { printf '%s|%s|%s|%s' "$AXRC" "$AXOUT" "$(cat "$AX/h-out/state/answer/$1.tsv" 2>/dev/null)" "$(_ax_ck "$AX/h-out/state/ledger/$1.tsv")"; }
_ax_dl fail "$AX/h-out" o1 "$AXO"
is "A2.3: a graphify that exits non-zero leaves exactly asked graphify failed in a record it creates, prints nothing, exits 1, signals nothing" \
   "$(_ax_oc o1)" "1||asked${AXT}graphify${AXT}failed|none"
_ax_dl empty "$AX/h-out" o2 "$AXO"
is "A2.3: one that prints nothing is failed too" "$(_ax_oc o2)" "1||asked${AXT}graphify${AXT}failed|none"
_ax_dl garbage "$AX/h-out" o3 "$AXO"
is "A2.3: one whose answer keeps no node is empty" "$(_ax_oc o3)" "1||asked${AXT}graphify${AXT}empty|none"
FELIX_GRAPH_TIMEOUT=1 _ax_dl hang "$AX/h-out" o4 "$AXO"
is "A2.3: one killed at the deadline is timeout" "$(_ax_oc o4)" "1||asked${AXT}graphify${AXT}timeout|none"
AXLT="1||asked${AXT}graphify${AXT}late|none"; AX_LEFT=0 _ax_dl mix "$AX/h-out" o5 "$AXO"
is "A2.3: with no time left, FELIX_GRAPH_LEFT=0, the record it creates holds exactly asked graphify late: graphify not run, nothing printed, exit 1, nothing signalled" \
   "$(_ax_oc o5)|$(_ax_nl "$AX/glog")" "$AXLT|0"
_ax_r=""; _ax_i=5; for _ax_v in -2 abc 1.5; do _ax_i=$((_ax_i + 1)); AX_LEFT="$_ax_v" _ax_dl mix "$AX/h-out" "o$_ax_i" "$AXO"; _ax_r="$_ax_r$_ax_v:$(_ax_oc "o$_ax_i")|$(_ax_nl "$AX/glog") "; done
is "A2.3: and so does a FELIX_GRAPH_LEFT of -2, abc or 1.5" "$_ax_r" "-2:$AXLT|0 abc:$AXLT|0 1.5:$AXLT|0 "
AX_LEFT=1 FELIX_GRAPH_TIMEOUT=12 _ax_dl slow4 "$AX/h-out" o9 "$AXO"
is "A2.3: a graphify killed once its 1 second left is up, under FELIX_GRAPH_TIMEOUT=12, was asked: its outcome is timeout, not late" "$(_ax_oc o9)" "1||asked${AXT}graphify${AXT}timeout|none"
AX_LEFT=0000000000 _ax_dl mix "$AX/h-out" o10 "$AXO"
is "A2.3: a FELIX_GRAPH_LEFT of 0000000000, 0 by value, is no time left too: exactly asked graphify late, graphify not run" "$(_ax_oc o10)|$(_ax_nl "$AX/glog")" "$AXLT|0"
AX_LEFT=0000000002 FELIX_GRAPH_TIMEOUT=12 _ax_dl slow6 "$AX/h-out" o11 "$AXO"
is "A2.3: and one of 0000000002 is a 2-second bound: a graphify killed once it is up, under FELIX_GRAPH_TIMEOUT=12, was asked: timeout, not late" \
   "$(_ax_oc o11)" "1||asked${AXT}graphify${AXT}timeout|none"
_ax_stamp "$AXO" "$AXO1"; _ax_dl noshell "$AXH" f1 "$AXO"
is "A2.7: a graph two commits behind says 2 commit(s) behind the checkout that holds it, after the stamp's seven characters" \
   "$(_ax_par "$AXOUT" 1 c)" "$(_ax_hd "$AXO1" "2 commit(s) behind the checkout that holds it")"
is "A2.9: with no file a shell script by its name or its first line there is no callers paragraph" \
   "$(_ax_npar "$AXOUT")|$(_ax_par "$AXOUT" 2)" "2|$(printf '  docs/guide.md:L1  Guide heading\n  bin/py:L2  main')"
_ax_dl envbash "$AXH" f2 "$AXW"
is "A2.7: asked from a worktree two commits ahead the freshness is still the holding checkout's" \
   "$(_ax_par "$AXOUT" 1 c)" "$(_ax_hd "$AXO1" "2 commit(s) behind the checkout that holds it")"
is "A2.5: and the session's roots are the worktree's top level, then the checkout that holds it" \
   "$(awk -F'\t' '$1 == "root"' "$AXH/state/answer/f2.tsv" 2>/dev/null)" "$(printf 'root\t%s\nroot\t%s' "$AXW" "$AXO")"
is "A2.9: a file whose first line is #!/usr/bin/env bash is a shell script" "$(_ax_par "$AXOUT" 3 c)" "$AXSHP"
_ax_dl zsh "$AXH" f3 "$AXO"
is "A2.9: and so is one whose first line is #!/bin/zsh" "$(_ax_par "$AXOUT" 3 c)" "$AXSHP"
_ax_dl longsh "$AXH" f6 "$AXO"
is "A2.9: a first line that names bash only past its first 128 bytes does not make a shell script" "$AXRC|$(_ax_npar "$AXOUT")" "0|2"
AXN8A="A2.9: under a UTF-8 locale the 128 are still bytes: a first line naming bash at bytes 140-143, characters 80-83, is no shell script"
AXN8B="A2.9: and under it a first line of the same form naming bash at bytes 120-123 is one"
if [ -z "$AXU8" ]; then skip "$AXN8A" "this machine has neither C.UTF-8 nor en_US.UTF-8"; skip "$AXN8B" "this machine has neither C.UTF-8 nor en_US.UTF-8"
else AX_LC="$AXU8" _ax_dl envs60 "$AXH" f8 "$AXO"; is "$AXN8A" "$AXRC|$(_ax_npar "$AXOUT")" "0|2"
  AX_LC="$AXU8" _ax_dl envs50 "$AXH" f9 "$AXO"; is "$AXN8B" "$AXRC|$(_ax_npar "$AXOUT")|$(_ax_par "$AXOUT" 3 c)" "0|3|$AXSHP"
fi
_ax_dl noshell "$AXH" f7 "$AXO/lib"
is "A2.5: asked from a subdirectory the root recorded is the checkout's top level" "$(awk -F'\t' '$1 == "root"' "$AXH/state/answer/f7.tsv" 2>/dev/null)" "root${AXT}$AXO"
_ax_stamp "$AXO" -; _ax_dl noshell "$AXH" f4 "$AXO"
is "A2.7: a graph with no stamp says graph carrying no build stamp in place of when it was built and how fresh" "$AXRC|$(_ax_par "$AXOUT" 1 c)" "0|$(_ax_hd -)"
_ax_stamp "$AXO" 0000000000000000000000000000000000000000; _ax_dl noshell "$AXH" f5 "$AXO"
is "A2.7: and so does a graph whose stamp names no commit here" "$AXRC|$(_ax_par "$AXOUT" 1 c)" "0|$(_ax_hd -)"
_ax_stamp "$AXO" "$AXO3"; mkdir -p "$AX/h-ro/state"; chmod 555 "$AX/h-ro/state"
if ( : > "$AX/h-ro/state/.probe" ) 2>/dev/null; then skip "A2.10: a record it cannot write still prints the block, exits 0 and says nothing on stderr" "the state directory is still writable"
else _ax_dl shell "$AX/h-ro" g1 "$AXO"
  is "A2.10: a record it cannot write still prints the block, exits 0 and says nothing on stderr" \
     "$AXRC|$(_ax_par "$AXOUT" 1 c)|$(_ax_par "$AXOUT" 2)|$(cat "$AX/dl.err" 2>/dev/null)" "0|$(_ax_hd "$AXO3" "$AXCUR")|$AXROWS|"
fi
chmod 755 "$AX/h-ro/state"

printf '\nA3-A4: felix_graph_refresh_due, and the marker a refresh leaves\n'
_ax_due() { local o; o="$(_ax_lib felix_graph_refresh_due "$1" 2>&1)"; printf '%s|%s' "$?" "$o"; }
is "A3: a graph built at HEAD is not due a refresh: exit 1, nothing printed" "$(_ax_due "$AXO")" "1|"
is "A3: a worktree ahead of a graph current with the holding checkout is not due either" "$(_ax_due "$AXW")" "1|"
_ax_stamp "$AXO" "$AXO1"
is "A3: a graph two commits behind is due: exit 0, nothing printed" "$(_ax_due "$AXO")" "0|"
is "A3: and asked from a worktree it is the holding checkout's distance that decides" "$(_ax_due "$AXW")" "0|"
_ax_mark "$AXO" "$AXO3"
is "A3: a graph behind whose refreshed-at marker holds the holding checkout's HEAD is not due" "$(_ax_due "$AXO")" "1|"
is "A3: nor asked from its worktree, the marker and the HEAD being the holding checkout's" "$(_ax_due "$AXW")" "1|"
_ax_mark "$AXO" "$AXO1"
is "A3: a marker holding another commit leaves the graph due" "$(_ax_due "$AXO")" "0|"
rm -f "$AXMK"; ln -s /dev/zero "$AXMK"
is "A3: a marker that is a link to /dev/zero reads as absent, the due test answering within its 15-second bound: due" "$(_ax_bdue "$AXO")" "0|"
rm -f "$AXMK"; printf '%s\n' "$AXO3" > "$AX/head-file"; ln -s "$AX/head-file" "$AXMK"
is "A3: a marker that is a link to a regular file holding HEAD reads as absent too: due, within the bound" "$(_ax_bdue "$AXO")" "0|"
rm -f "$AXMK"; mkfifo "$AXMK"
is "A3: and so does a marker that is a named pipe, the due test not waiting for a writer" "$(_ax_bdue "$AXO")" "0|"
rm -f "$AXMK"; { awk 'BEGIN { for (i = 0; i < 100; i++) printf "x" }'; printf '\n%s\n' "$AXO3"; } > "$AXMK"
is "A3: a regular marker whose HEAD sits past its first 64 bytes does not hold it: due" "$(_ax_bdue "$AXO")" "0|"
_ax_mark "$AXO" -; _ax_stamp "$AXO" -
is "A3: a graph with no stamp is not due" "$(_ax_due "$AXO")" "1|"
_ax_stamp "$AXO" 0000000000000000000000000000000000000000
is "A3: nor one whose stamp is a commit the checkout does not hold" "$(_ax_due "$AXO")" "1|"
is "A3: nor a checkout with no graph at all" "$(_ax_due "$AXN")" "1|"
_ax_stamp "$AXO" "$AXO3"; rm -f "$AX/release"; : > "$AX/glog"; _ax_bg "$AXR" >/dev/null; _ax_wait 10 '[ "$(_ax_nqp "$AXR")" -gt 0 ]'
( _fx_cd "$AXR" && printf '3\n' > r3.txt && git add -A && _ax_git commit -qm r3 ) >/dev/null 2>&1
_ax_release; _ax_wait 6 '[ -s "$AXR/graphify-out/.felix-refreshed-at" ]'
_ax_nb() { if [ -f "$1" ]; then wc -c < "$1" | tr -d ' '; else printf 'none'; fi; }   # FILE -> its size in bytes, or none
is "A4: a refresh whose update exits 0 leaves the holding checkout's full HEAD and a newline, as it was when the refresh started, a commit made meanwhile aside" \
   "$(cat "$AXR/graphify-out/.felix-refreshed-at" 2>/dev/null)|$(_ax_nb "$AXR/graphify-out/.felix-refreshed-at") bytes|$([ "$(git -C "$AXR" rev-parse HEAD 2>/dev/null)" != "$AXR2" ] && echo moved)" \
   "$AXR2|41 bytes|moved"
_ax_mark "$AXR" -; : > "$AX/ufail"; : > "$AX/glog"; _ax_bg "$AXR" >/dev/null; _ax_wait 10 '[ "$(_ax_nqp "$AXR")" -gt 0 ]'; _ax_release; rm -f "$AX/ufail"
is "A4: a refresh whose update fails leaves no marker" "$(_ax_nqp "$AXR")|$([ -e "$AXR/graphify-out/.felix-refreshed-at" ] && echo written || echo none)" "1|none"
AXRM="$AXR/graphify-out/.felix-refreshed-at"; AXRH="$(git -C "$AXR" rev-parse HEAD 2>/dev/null)"   # each case below makes the marker's path read as absent
_ax_rf() {   # -> one refresh of the refresh checkout, its update let through at once, run to the end of its lock
  : > "$AX/release"; : > "$AX/glog"; _ax_bg "$AXR" >/dev/null; _ax_wait 10 '[ "$(_ax_nqp "$AXR")" -gt 0 ]'
  _ax_wait 10 '[ ! -d "$AXR/graphify-out/.felix-refresh.lock" ]'; rm -f "$AX/release"
}
_ax_at() { if [ -L "$1" ]; then printf 'a link'; elif [ -d "$1" ]; then printf 'a directory'
           elif [ -f "$1" ]; then printf 'a file of %s bytes holding %s' "$(_ax_nb "$1")" "$(head -1 "$1")"; else printf 'nothing'; fi; }   # PATH -> what stands there
printf 'victim\n' > "$AX/victim-file"; rm -rf "$AXRM"; ln -s "$AX/victim-file" "$AXRM"; _ax_rf; _ax_wait 6 '[ -f "$AXRM" ] && [ ! -L "$AXRM" ]'
is "A4: a link at the marker's path is replaced by the marker, and the file it named is left as it was" \
   "$(_ax_at "$AXRM")|$(cat "$AX/victim-file")" "a file of 41 bytes holding $AXRH|victim"
mkdir -p "$AX/victim-dir"; printf 'keep\n' > "$AX/victim-dir/keep"; rm -rf "$AXRM"; ln -s "$AX/victim-dir" "$AXRM"; _ax_rf; _ax_wait 6 '[ -f "$AXRM" ] && [ ! -L "$AXRM" ]'
is "A4: a link to a directory there is replaced by the marker too, and nothing is written inside the directory it named" \
   "$(_ax_at "$AXRM")|$(ls -A "$AX/victim-dir" | tr '\n' ',')$(cat "$AX/victim-dir/keep")" "a file of 41 bytes holding $AXRH|keep,keep"
printf 'victim\n' > "$AX/victim-hard"; rm -rf "$AXRM"; ln "$AX/victim-hard" "$AXRM"; _ax_rf; _ax_wait 6 '[ "$(head -1 "$AXRM" 2>/dev/null)" = "$AXRH" ]'
is "A4: a hard link there is replaced, not written through: the marker holds HEAD and the file it shared contents with is left as it was" \
   "$(_ax_at "$AXRM")|$(cat "$AX/victim-hard")" "a file of 41 bytes holding $AXRH|victim"
rm -rf "$AXRM"; mkdir -p "$AXRM"; printf 'x\n' > "$AXRM/x"; _ax_rf; _ax_wait 2 '[ "$(ls -A "$AXRM" | wc -l | tr -d " ")" != 1 ]'
is "A4: a directory at the marker's path gets no marker and nothing inside it" "$(_ax_at "$AXRM")|$(ls -A "$AXRM" | tr '\n' ',')" "a directory|x,"
rm -rf "$AXRM"; mkdir -p "$AX/elsewhere-out"; mv "$AXR/graphify-out/graph.json" "$AX/elsewhere-out/graph.json"; rm -rf "$AXR/graphify-out"
ln -s "$AX/elsewhere-out" "$AXR/graphify-out"; _ax_rf; _ax_wait 2 '[ -e "$AX/elsewhere-out/.felix-refreshed-at" ] || [ -L "$AX/elsewhere-out/.felix-refreshed-at" ]'
is "A4: no marker is written when graphify-out is itself a link, neither through it nor in place of it" \
   "$({ [ -e "$AX/elsewhere-out/.felix-refreshed-at" ] || [ -L "$AX/elsewhere-out/.felix-refreshed-at" ]; } && echo written || echo none)|$([ -L "$AXR/graphify-out" ] && echo 'still a link')" \
   "none|still a link"
rm -f "$AXR/graphify-out"

printf '\nU1-U5: hooks/user-prompt hands the answer over\n'
_ax_up() {   # DIR PAYLOAD [NAME=VALUE...] -> what the user-prompt hook (of $AX_HARN, or the suite's) printed there; status in $AX/up.rc
  local d="$1" p="$2"; shift 2
  ( _fx_cd "$d" && env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR -u FELIX_GRAPH_LEFT -u FELIX_PROMPT_DEADLINE FELIX_HOME="$AXH" FELIX_MEMORY="$AXM" HOME="$AX/user" PATH="$AX/bin:$PATH" "$@" \
      "${AX_HARN:-$FROOT/harness}/hooks/user-prompt" <<<"$p" 2>/dev/null
    printf '%s' "$?" > "$AX/up.rc" )
}
_ax_pay() { printf -v AXPAY '{"session_id":"%s","cwd":"%s","hook_event_name":"UserPromptSubmit","prompt":"%s"}' "$1" "${3:-$AXO}" "$2"; }   # SESSION PROMPT [DIR]
_ax_ctx() { python3 -c 'import json, sys
try: sys.stdout.write(json.loads(sys.stdin.read())["hookSpecificOutput"]["additionalContext"])
except Exception: sys.stdout.write("(no json)")' <<<"$1" 2>/dev/null; }
_ax_block() { case "$1" in *"knowledge graph's answer"*) printf 'a block' ;; *) printf 'no block' ;; esac; }
_ax_rec() { if [ -e "$AXH/state/answer/$1.tsv" ]; then printf 'recorded'; else printf 'none'; fi; }
_ax_starts() { case "$1" in "$2"*) printf 'yes' ;; *) printf 'no' ;; esac; }
_ax_gap() {   # MID -> "one" when MID starts with no newline and ends with exactly one blank line
  case "$1" in $'\n'*) printf 'a leading newline'; return 0 ;; esac
  if [ "${1%$'\n\n'}" != "$1" ] && [ "${1%$'\n\n\n'}" = "$1" ]; then printf 'one'; else printf 'not one'; fi
}
_ax_calls() { awk '$1 == "own" { n++ } END { print n + 0 }' "$AX/calls"; }   # ownership checks logged by any script of the run
_ax_ord() {   # HOOK -> the order of that hook's first ownership check and first due test, whatever else it calls
  awk -v h="$1" '$2 == h { n++; if ($1 == "own" && !o) o = n; if ($1 == "due" && !d) d = n }
    END { if (!o && !d) print "neither"; else if (!d) print "own only"; else if (!o) print "due only"; else print (o < d) ? "own then due" : "due then own" }' "$AX/calls"
}
AXTN="<task-notification><task-id>b1</task-id><status>completed</status></task-notification>"
printf shell > "$AX/gv"; : > "$AX/glog"; _ax_pay u1 "$AXQ"; AXU="$(_ax_up "$AXO" "$AXPAY")"; AXC="$(_ax_ctx "$AXU")"
is "U3: a prompt whose one part is the answer still gets the hook's JSON, and the hook exits 0" "$(cat "$AX/up.rc")|$([ "$AXC" != "(no json)" ] && echo json)" "0|json"
is "U1: a person's prompt with a session id in the own checkout gets the block, word for word and nothing else" \
   "$(_ax_npar "$AXC")|$(_ax_par "$AXC" 1 c)|$(_ax_par "$AXC" 2)|$(_ax_par "$AXC" 3 c)" "3|$(_ax_hd "$AXO3" "$AXCUR")|$AXROWS|$AXSHP"
is "U2: and graphify is asked once, about the payload's prompt" "$(_ax_log)" "$(_ax_q "$AXQ")"
is "U5: a session's first prompt writes no prompt row: its record opens with its asked row" "$(head -1 "$AXH/state/answer/u1.tsv" 2>/dev/null)" "asked${AXT}graphify${AXT}answered"
: > "$AX/glog"; _ax_pay u1m "$AXTN $AXQ"; AXU="$(_ax_up "$AXO" "$AXPAY")"
is "U1: a task notification is not a person's prompt: no block, graphify not asked, no record" "$(_ax_block "$AXU")|$(_ax_log)|$(_ax_rec u1m)" "no block||none"
_ax_n0="$(ls "$AXH/state/answer" 2>/dev/null | wc -l | tr -d ' ')"; : > "$AX/glog"
printf -v AXPAY '{"cwd":"%s","hook_event_name":"UserPromptSubmit","prompt":"%s"}' "$AXO" "$AXQ"; AXU="$(_ax_up "$AXO" "$AXPAY")"
is "U1: a payload with no session id is told nothing, and nothing is recorded" "$(_ax_block "$AXU")|$(_ax_log)|$(ls "$AXH/state/answer" 2>/dev/null | wc -l | tr -d ' ')" "no block||$_ax_n0"
: > "$AX/glog"; _ax_pay u1k "$AXQ" "$AXK"; AXU="$(_ax_up "$AXK" "$AXPAY")"
is "U1: a checkout bound by its .felix marker alone is told nothing: graphify not asked, no record" "$(_ax_block "$AXU")|$(_ax_log)|$(_ax_rec u1k)" "no block||none"
: > "$AX/glog"; _ax_pay u1f "$AXQ" "$AXF"; AXU="$(_ax_up "$AXF" "$AXPAY")"
is "U1: nor is one bound by an origin that only contains the remote_match" "$(_ax_block "$AXU")|$(_ax_log)|$(_ax_rec u1f)" "no block||none"
: > "$AX/calls"; _ax_pay uo1 "$AXQ"; AX_HARN="$AX/hs/harness" _ax_up "$AXO" "$AXPAY" FELIX_GRAPH_ANSWER=0 >/dev/null; _ax_c="$(_ax_calls)"
_ax_pay uo2 "$AXQ"; AX_HARN="$AX/hs/harness" _ax_up "$AXO" "$AXPAY" PATH="$AXNOG" >/dev/null; _ax_c="$_ax_c $(_ax_calls)"
_ax_pay uo3 "$AXQ"; AX_HARN="$AX/hs/harness" _ax_up "$AXO" "$AXPAY" PATH="$AXNOP" >/dev/null; _ax_c="$_ax_c $(_ax_calls)"
mv "$AXO/graphify-out/graph.json" "$AX/graph.away"; _ax_pay uo4 "$AXQ"; AX_HARN="$AX/hs/harness" _ax_up "$AXO" "$AXPAY" >/dev/null
_ax_c="$_ax_c $(_ax_calls)"; mv "$AX/graph.away" "$AXO/graphify-out/graph.json"
_ax_pay uo5 "$AXTN $AXQ"; AX_HARN="$AX/hs/harness" _ax_up "$AXO" "$AXPAY" >/dev/null; _ax_c="$_ax_c $(_ax_calls)"
printf -v AXPAY '{"cwd":"%s","hook_event_name":"UserPromptSubmit","prompt":"%s"}' "$AXO" "$AXQ"; AX_HARN="$AX/hs/harness" _ax_up "$AXO" "$AXPAY" >/dev/null
is "U1: FELIX_GRAPH_ANSWER=0, no graphify, no perl, no graph, a machine message and a missing session id each stop before the ownership check" \
   "$_ax_c $(_ax_calls)" "0 0 0 0 0 0"
: > "$AX/calls"; _ax_pay uo7 "$AXQ"; AX_HARN="$AX/hs/harness" _ax_up "$AXO" "$AXPAY" >/dev/null
is "U1: a person's prompt that passes those checks has the checkout's ownership checked" "$([ "$(_ax_calls)" -gt 0 ] && echo checked || echo 'not checked')" "checked"
printf -v AXPAY '{"session_id":"u2a","hook_event_name":"UserPromptSubmit","prompt":"%s","cwd":"%s","note":"never part of the question"}' 'where is the \"answer\" block built today' "$AXO"
: > "$AX/glog"; _ax_up "$AXO" "$AXPAY" >/dev/null
is "U2: an escaped quote reaches graphify as a quote, and the keys after the prompt never reach it" "$(_ax_log)" "$(_ax_q 'where is the "answer" block built today')"
printf -v AXPAY '{"session_id":"u2b","hook_event_name":"UserPromptSubmit","prompt":"%s"}' 'where is the a\\b case handled in graph'
: > "$AX/glog"; _ax_up "$AXO" "$AXPAY" >/dev/null
is "U2: an escaped backslash reaches graphify as one backslash" "$(_ax_log)" "$(_ax_q 'where is the a\b case handled in graph')"
printf -v AXPAY '{"session_id":"u2c","hook_event_name":"UserPromptSubmit","prompt":"%s","cwd":"%s","note":"do not read this"}' 'where does the trailing backslash go \\' "$AXO"
: > "$AX/glog"; _ax_up "$AXO" "$AXPAY" >/dev/null
is "U2: the prompt ends at its first unescaped quote, so a value that ends in an escaped backslash ends there" "$(_ax_log)" "$(_ax_q 'where does the trailing backslash go \')"
_ax_pay u2d "$(awk 'BEGIN { for (i = 0; i < 3000; i++) printf "abcdef " }')"; : > "$AX/glog"; _ax_up "$AXO" "$AXPAY" >/dev/null
is "U2: a prompt of more than 16,384 bytes is still asked, as its first 400 characters" "$(_ax_log)" "$(_ax_q "$(awk 'BEGIN { for (i = 0; i < 57; i++) printf "abcdef " }')a")"
AXN2A="U2: under a UTF-8 locale the 16,384 are bytes: four words, then a fifth past byte 16,384 though within 16,384 characters, are not asked"
AXN2B="U2: and under it a fifth word starting at byte 16,384 is cut there, asked as its first letter"
AXE4="$(printf '\303\251 \303\251 \303\251 \303\251')"; _ax_sp() { awk -v n="$1" 'BEGIN { for (i = 0; i < n; i++) printf " " }'; }   # 11 bytes, 7 characters
if [ -z "$AXU8" ]; then skip "$AXN2A" "this machine has neither C.UTF-8 nor en_US.UTF-8"; skip "$AXN2B" "this machine has neither C.UTF-8 nor en_US.UTF-8"
else _ax_pay u2u "$AXE4$(_ax_sp 16374)where is it built"; : > "$AX/glog"; AXU="$(_ax_up "$AXO" "$AXPAY" LANG="$AXU8" LC_ALL="$AXU8")"
  is "$AXN2A" "$(_ax_block "$AXU")|$(_ax_log)|$(cat "$AX/up.rc")" "no block||0"
  _ax_pay u2v "$AXE4$(_ax_sp 16372)where is it built"; : > "$AX/glog"; _ax_up "$AXO" "$AXPAY" LANG="$AXU8" LC_ALL="$AXU8" >/dev/null
  is "$AXN2B" "$(_ax_log)" "$(_ax_q "$AXE4 w")"
fi
AXRP="the quokka ledger build is broken and failing with a crash"; printf shell > "$AX/gv"
_ax_pay u3b "$AXRP"; AXBASE="$(_ax_ctx "$(_ax_up "$AXO" "$AXPAY" FELIX_GRAPH_ANSWER=0)")"
_ax_pay u3w "$AXRP"; AXWITH="$(_ax_ctx "$(_ax_up "$AXO" "$AXPAY")")"
AXPRE="${AXBASE%%Lessons this project already paid for*}"; AXPOST="${AXBASE#"$AXPRE"}"; AXMID="${AXWITH#"$AXPRE"}"; AXMID="${AXMID%"$AXPOST"}"
is "U3: with no answer the routed prompt gets the route part and then the lessons part (fixture control)" \
   "$(_ax_starts "$AXBASE" "Felix routed this to: debug")|$(_ax_starts "$AXPOST" "Lessons this project already paid for")" "yes|yes"
is "U3: the answer goes after the route part and before the lessons part, the rest as it was" \
   "$([ -n "$AXMID" ] && [ "$AXPRE$AXMID$AXPOST" = "$AXWITH" ] && echo between)|$(_ax_par "$AXMID" 1 c)|$(_ax_par "$AXMID" 2)" "between|$(_ax_hd "$AXO3" "$AXCUR")|$AXROWS"
is "U3: separated from the parts on either side by one blank line" "$(_ax_gap "$AXMID")" "one"
_ax_pay u3n "ok thanks"; AXU="$(_ax_up "$AXO" "$AXPAY")"
is "U3: a prompt that produces none of the parts still exits 0 with no output" "$(cat "$AX/up.rc")|$AXU" "0|"
_ax_u4() {   # SESSION VARIANT [NAME=VALUE...] -> "status|context" of the routed prompt, under a timeout of one second
  local s="$1" o; printf '%s' "$2" > "$AX/gv"; shift 2; _ax_pay "$s" "$AXRP"
  o="$(_ax_up "$AXO" "$AXPAY" FELIX_GRAPH_TIMEOUT=1 "$@")"; printf '%s|%s' "$(cat "$AX/up.rc")" "$(_ax_ctx "$o")"
}
is "U4: a graphify that fails leaves the hook's exit 0 and its other parts as they are with no answer" "$(_ax_u4 u4f fail)" "0|$AXBASE"
_ax_t0=$SECONDS; AXU="$(_ax_u4 u4h hang)"; _ax_dt=$((SECONDS - _ax_t0))
is "U4: one that hangs past the timeout does too, and the prompt waits no more than 8 seconds" "$AXU|$(_ax_secs 8)" "0|$AXBASE|prompt"
is "U4: so does one that prints garbage" "$(_ax_u4 u4g garbage)" "0|$AXBASE"
is "U4: and one that is not on PATH at all" "$(_ax_u4 u4a shell PATH="$AXNOG")" "0|$AXBASE"
_ax_out() { awk -F'\t' '$1 == "asked" { o = $3 } END { print o }' "$AXH/state/answer/$1.tsv" 2>/dev/null; }   # SESSION -> its last ask's outcome
_ax_cut() { case "$1" in timeout|late) printf 'cut' ;; *) printf 'not cut: %s' "$1" ;; esac; }   # OUTCOME -> cut when graphify was killed or never run
printf shell > "$AX/gv"; : > "$AX/glog"; _ax_pay u4l "$AXRP"; AXU="$(_ax_up "$AXO" "$AXPAY" FELIX_PROMPT_DEADLINE=3)"
is "U4: under FELIX_PROMPT_DEADLINE=3 the ask has 3 - S - 3 seconds, under one: its record holds asked graphify late alone, graphify is not run, the exit is 0 and the other parts are as they were" \
   "$(cat "$AXH/state/answer/u4l.tsv" 2>/dev/null)|$(_ax_log)|$(cat "$AX/up.rc")|$(_ax_ctx "$AXU")" "asked${AXT}graphify${AXT}late||0|$AXBASE"
_ax_r=""; _ax_i=0; for _ax_v in abc 2.5 18446744073709551613; do _ax_i=$((_ax_i + 1)); _ax_pay "u4d$_ax_i" "$AXQ"
  _ax_up "$AXO" "$AXPAY" FELIX_PROMPT_DEADLINE="$_ax_v" >/dev/null; _ax_r="$_ax_r$_ax_v:$(_ax_out "u4d$_ax_i") "; done
is "U4: a FELIX_PROMPT_DEADLINE that is no whole number of at most four digits is taken as 30: abc, 2.5 and a number of 20 digits leave the ask its time" \
   "$_ax_r" "abc:answered 2.5:answered 18446744073709551613:answered "
: > "$AX/slowroute"; : > "$AX/glog"; _ax_pay u4s "$AXQ"; AX_HARN="$AX/hs/harness" _ax_up "$AXO" "$AXPAY" FELIX_PROMPT_DEADLINE=5 >/dev/null
is "U4: S is the seconds the hook has run: held 2 seconds before it asks, under FELIX_PROMPT_DEADLINE=5 it has 5 - 2 - 3 left, none, and the ask is late" \
   "$(_ax_out u4s)|$(_ax_log)|$([ -e "$AX/slowroute" ] && echo 'never held' || echo held)" "late||held"
rm -f "$AX/slowroute"; printf slow4 > "$AX/gv"; _ax_pay u4c "$AXRP"; AXU="$(_ax_up "$AXO" "$AXPAY" FELIX_PROMPT_DEADLINE=4 FELIX_GRAPH_TIMEOUT=12)"
is "U4: under FELIX_PROMPT_DEADLINE=4 the bound is what is left, a second at most, not FELIX_GRAPH_TIMEOUT=12: a graphify answering after 4 seconds gives no block, its ask timeout, or late had the hook used that second" \
   "$(cat "$AX/up.rc")|$(_ax_ctx "$AXU")|$(_ax_cut "$(_ax_out u4c)")" "0|$AXBASE|cut"
AXU5="$AXH/state/answer/u1.tsv"; printf shell > "$AX/gv"; _ax_n="$(_ax_nl "$AXU5")"; _ax_pay u1 "$AXQ"; _ax_up "$AXO" "$AXPAY" >/dev/null
is "U5: a later prompt of the session appends prompt before anything else it writes there" "$(_ax_since "$AXU5" "$_ax_n")" "$(printf 'prompt\nasked\tgraphify\trepeat')"
_ax_n="$(_ax_nl "$AXU5")"; _ax_pay u1 "ok thanks"; _ax_up "$AXO" "$AXPAY" >/dev/null
is "U5: a prompt too short to ask still appends its prompt row, and nothing else" "$(_ax_since "$AXU5" "$_ax_n")" "prompt"
_ax_n="$(_ax_nl "$AXU5")"; _ax_pay u1 "$AXQ"; _ax_up "$AXO" "$AXPAY" FELIX_GRAPH_ANSWER=0 >/dev/null
is "U5: so does a prompt the graph cannot be asked for, U1's third condition not applying to the row" "$(_ax_since "$AXU5" "$_ax_n")" "prompt"
_ax_n="$(_ax_nl "$AXU5")"; _ax_pay u1 "$AXQ" "$AXK"; _ax_up "$AXK" "$AXPAY" >/dev/null
is "U5: and one from a checkout that is not own, nor its fourth" "$(_ax_since "$AXU5" "$_ax_n")" "prompt"
_ax_n="$(_ax_nl "$AXU5")"; _ax_pay u1 "$AXTN"; _ax_up "$AXO" "$AXPAY" >/dev/null
is "U5: a machine message is no person's prompt and appends nothing" "$(_ax_since "$AXU5" "$_ax_n")" ""
_ax_n="$(_ax_nl "$AXU5")"; printf shell > "$AX/gv"; _ax_pay u1 "$AXQ"; _ax_up "$AXO" "$AXPAY" FELIX_PROMPT_DEADLINE=3 >/dev/null
is "U5: a prompt with no time left to ask still appends its prompt row first, then its late ask" "$(_ax_since "$AXU5" "$_ax_n")" "$(printf 'prompt\nasked\tgraphify\tlate')"
: > "$AX/rcalls"; printf 'asked\tgraphify\tfailed\n' > "$AXH/state/answer/u5r.tsv"; _ax_pay u5r "$AXRP"; AX_HARN="$AX/hs/harness" _ax_up "$AXO" "$AXPAY" >/dev/null
is "U5: the prompt row is written before the hook computes its route: the first route function it calls finds the row in the record already" \
   "$(awk 'NR == 1 { print ($2 == "" ? "no prompt row yet" : $2) } END { if (!NR) print "no route computed" }' "$AX/rcalls")" "prompt"

printf '\nT1-T2: hooks/post-tool records the answered files the session reached, as matches only\n'
_ax_pt() {   # SESSION TOOL INPUT [RESPONSE] -> post-tool in the own checkout (home AX_PTH, or ansp's); status and output in $AX/pt.rc, pt.out
  local p r="${4:-}"; [ -n "$r" ] || r='{}'
  printf -v p '{"session_id":"%s","transcript_path":"/decoy/%s.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"PostToolUse","tool_name":"%s","tool_input":%s,"tool_response":%s}' \
    "$1" "$1" "$AXO" "$2" "$3" "$r"
  ( _fx_cd "$AXO" && env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR FELIX_HOME="${AX_PTH:-$AXH}" FELIX_MEMORY="$AXM" HOME="$AX/user" PATH="$AX/spy:$AX/bin:$PATH" \
      "$FROOT/harness/hooks/post-tool" <<<"$p" > "$AX/pt.out" 2>&1
    printf '%s' "$?" > "$AX/pt.rc" )
}
AXS="$AXH/state/answer/t1.tsv"
_ax_t1() {   # [ROWS] -> t1's record: one answered delivery of lib/one.sh and docs/guide.md under the root own, then ROWS
  printf 'asked\tgraphify\tanswered\nroot\t%s\ngiven\tgraphify\t2\t-\nnode\tgraphify\tlib/one.sh\tL83\tfelix_one()\nnode\tgraphify\tdocs/guide.md\t\tGuide heading\nanswer\tgraphify\tlib/one.sh\nanswer\tgraphify\tdocs/guide.md\n%b' \
    "$AXO" "${1:-}" > "$AXS"; AXSN="$(_ax_nl "$AXS")"
}
_ax_new() { _ax_since "$AXS" "$AXSN"; }   # what the hook appended to the record _ax_t1 wrote
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/spy.log"\nexec "%s" "$@"\n' "$AX" "$(command -v git)" > "$AX/spy/git"; chmod +x "$AX/spy/git"; : > "$AX/spy.log"
AXOE="$(printf '%s' "$AXO" | sed 's|/|\\/|g')"; AXA20K="$(awk 'BEGIN { for (i = 0; i < 20000; i++) printf "a" }')"
_ax_t1; _ax_pt t1 Read "{\"file_path\":\"$AXO/lib/one.sh\",\"limit\":5}" "{\"type\":\"text\",\"file\":{\"file_path\":\"$AXO/docs/guide.md\"}}"
is "T1: a Read of an answered file by its path under the session's root appends touch, Read and the file as the answer named it, not the response's" \
   "$(_ax_new)" "touch${AXT}Read${AXT}lib/one.sh"
_ax_t1; _ax_pt t1 Edit '{"file_path":"docs/guide.md","old_string":"a","new_string":"b"}'
is "T1: an Edit whose value is the file itself appends its touch row" "$(_ax_new)" "touch${AXT}Edit${AXT}docs/guide.md"
_ax_t1; _ax_pt t1 Write "{\"file_path\":\"$AXO/new.md\",\"content\":\"x\"}"
is "T1: a Write of a file no answer named appends nothing" "$(_ax_new)" ""
_ax_t1; _ax_pt t1 MultiEdit "{\"file_path\":\"$AXO/lib/one.sh\",\"edits\":[]}"
is "T1: a MultiEdit is read by its file_path" "$(_ax_new)" "touch${AXT}MultiEdit${AXT}lib/one.sh"
_ax_t1; _ax_pt t1 NotebookEdit "{\"notebook_path\":\"$AXO/docs/guide.md\",\"new_source\":\"x\"}"
is "T1: a NotebookEdit is read by its notebook_path" "$(_ax_new)" "touch${AXT}NotebookEdit${AXT}docs/guide.md"
_ax_t1; _ax_pt t1 Grep "{\"pattern\":\"x\",\"path\":\"$AXO/lib/one.sh\"}" "{\"path\":\"$AXO/docs/guide.md\"}"
is "T1: a Grep is read by its path, not the response's" "$(_ax_new)" "touch${AXT}Grep${AXT}lib/one.sh"
_ax_t1; _ax_pt t1 Grep "{\"pattern\":\"x\",\"path\":\"$AXO/lib\"}"
is "T1: a Grep of the directory that holds a file matches no file" "$(_ax_new)" ""
_ax_t1; _ax_pt t1 Glob "{\"pattern\":\"*.md\",\"file_path\":\"$AXO/lib/one.sh\",\"notebook_path\":\"$AXO/lib/one.sh\",\"path\":\"$AXO/docs/guide.md\"}"
is "T1: a Glob is read by the key spelled exactly path, not one that ends in path" "$(_ax_new)" "touch${AXT}Glob${AXT}docs/guide.md"
_ax_t1; _ax_pt t1 Read "{\"note\":\"file_path\",\"file_path\":\"$AXO/lib/one.sh\"}"
is "T1: the key is found with its colon, so a value that equals the key's name is passed over" "$(_ax_new)" "touch${AXT}Read${AXT}lib/one.sh"
_ax_t1; _ax_pt t1 Bash '{"command":"cat lib/one.sh docs/guide.md","description":"x"}' '{"stdout":"","command":"not this"}'
is "T1: a Bash command naming two answered files appends a touch row for each" "$(_ax_new | LC_ALL=C sort)" "$(printf 'touch\tBash\tdocs/guide.md\ntouch\tBash\tlib/one.sh')"
_ax_t1; _ax_pt t1 Bash '{"command":"grep -n \"felix_one\" lib/one.sh"}'
is "T1: the value is read to its first unescaped quote and decoded, so a command's escaped quotes keep the rest of it" "$(_ax_new)" "touch${AXT}Bash${AXT}lib/one.sh"
_ax_t1; _ax_pt t1 Read "{\"file_path\":\"$AXOE\\/lib\\/one.sh\"}"
is "T1: an escaped slash reads as a slash" "$(_ax_new)" "touch${AXT}Read${AXT}lib/one.sh"
_ax_t1; _ax_pt t1 Bash '{"command":"cat\tlib/one.sh"}'
is "T1: and an escaped tab as a space, so the file after it is a token" "$(_ax_new)" "touch${AXT}Bash${AXT}lib/one.sh"
_ax_t1; _ax_pt t1 Bash '{"command":"cat lib/one.sh --token=SECRET123"}'
is "T1: nothing of the value but the named file is written: the record gains the touch row and no part of the command" \
   "$(_ax_new)|$(grep -rl SECRET123 "$AXH/state/answer" 2>/dev/null)" "touch${AXT}Bash${AXT}lib/one.sh|"
_ax_t1 'prompt\n'; _ax_pt t1 Read "{\"file_path\":\"$AXO/lib/one.sh\"}"
is "T1: a file answered only before the record's last prompt row is not matched" "$(_ax_new)" ""
_ax_t1 'prompt\nasked\tgraphify\tanswered\ngiven\tgraphify\t1\t-\nanswer\tgraphify\tnotes/n1.md\ngiven\tgraphify\t1\t-\nanswer\tgraphify\tnotes/n1.md\n'
_ax_pt t1 Read "{\"file_path\":\"$AXO/notes/n1.md\"}"; _ax_pt t1 Read "{\"file_path\":\"$AXO/docs/guide.md\"}"
is "T1: one answered after it is, once though two answer rows name it, and one answered only before it is not" "$(_ax_new)" "touch${AXT}Read${AXT}notes/n1.md"
_ax_t1; _ax_pt t1 Bash "{\"command\":\"echo $AXA20K lib/one.sh\"}"
is "T1: a file named only past the value's first 16,384 bytes is not read" "$(_ax_new)" ""
_ax_t1; _ax_pt t1 Bash "{\"command\":\"cat lib/one.sh $AXA20K\"}"
is "T1: one named within them is, the value running on past them" "$(_ax_new)" "touch${AXT}Bash${AXT}lib/one.sh"
_ax_t1; _ax_pt t1 WebFetch '{"url":"https://example.invalid/","file_path":"lib/one.sh","prompt":"x"}'
is "T1: a tool not in the table appends nothing, though its input names an answered file" "$(_ax_new)" ""
_ax_t1; _ax_pt t1 Read '{"offset":3}'
is "T1: a Read whose payload holds no file_path appends nothing" "$(_ax_new)" ""
is "T1: the session's ledger append is still made, a tool row for each call" \
   "$(awk -F'\t' '$1 == "tool" { print; exit }' "$AXH/state/ledger/t1.tsv" 2>/dev/null)" "tool${AXT}Read"   # its alive lines are wave 2's to pin
_ax_pt t0 Read "{\"file_path\":\"$AXO/lib/one.sh\"}"
is "T1: with no state file nothing is appended and no state file is made, the ledger append made as before" \
   "$(_ax_rec t0)|$(awk -F'\t' '$1 == "tool"' "$AXH/state/ledger/t0.tsv" 2>/dev/null)" "none|tool${AXT}Read"
_ax_t1; cp "$AXS" "$AXH/state/answer/t.9.tsv"; _ax_ckb="$(_ax_ck "$AXH/state/answer/t.9.tsv")"; _ax_pt t.9 Read "{\"file_path\":\"$AXO/lib/one.sh\"}"
is "T1: a session id that A2.1 refuses appends nothing to the record its name points at" "$(_ax_ck "$AXH/state/answer/t.9.tsv")" "$_ax_ckb"
AXE2="$AX/e2e"; mkdir -p "$AXE2/projects/ansp" "$AXE2/state/answer" "$AXE2/state/session"; cp "$AXP/project.json" "$AXP/CLAUDE.md" "$AXP/stack.tsv" "$AXE2/projects/ansp/"
printf 'asked\tgraphify\tanswered\nroot\t%s\ngiven\tgraphify\t2\t-\nanswer\tgraphify\tCLAUDE.md\nanswer\tgraphify\tprojects/x/CLAUDE.md\n' "$AXO" > "$AXE2/state/answer/e1.tsv"
AX_PTH="$AXE2" _ax_pt e1 Bash "{\"command\":\"grep -n rule $AXO/CLAUDE.md\"}"
is "T1: a command naming <root>/CLAUDE.md touches CLAUDE.md, and not projects/x/CLAUDE.md, whose basename it only shares behind a slash" \
   "$(_ax_since "$AXE2/state/answer/e1.tsv" 5)" "touch${AXT}Bash${AXT}CLAUDE.md"
is "T2: no post-tool run, with a state file or without, ran git" "$(cat "$AX/spy.log" 2>/dev/null)" ""
_ax_t1; _ax_ckp="$(_ax_ck "$AXS")"; chmod 444 "$AXS"
if [ -w "$AXS" ]; then skip "T2: an append that fails is silent, the exit 0 and the file unchanged" "the state file is still writable"
else _ax_pt t1 Read "{\"file_path\":\"$AXO/lib/one.sh\"}"
  is "T2: an append that fails is silent, the exit 0 and the file unchanged" "$(cat "$AX/pt.rc")|$(cat "$AX/pt.out")|$(_ax_ck "$AXS")" "0||$_ax_ckp"
fi
chmod 644 "$AXS"
AXTS="$AX/tspy"; mkdir -p "$AXTS"; printf '#!/bin/sh\nprintf "%%s\\n" "${0##*/}" >> "%s/tspy.log"\n' "$AX" > "$AX/tspy-log"; chmod +x "$AX/tspy-log"
perl -e 'my ($to, $at, $path) = @ARGV; my %seen; for my $d (split /:/, $path) { opendir(my $h, $d) or next;
  for my $n (readdir $h) { next if $n =~ /^\./ || $seen{$n}++; symlink $to, "$at/$n" if -f "$d/$n" && -x _ } }' "$AX/tspy-log" "$AXTS" "$PATH"
_ax_load() {   # LIB FUNCTION -> what loading lib/LIB.sh printed, |defined when FUNCTION then exists, and |the commands it ran: it is loaded
               # after resolve.sh and own.sh, on a PATH holding nothing but a spy, logging its name, for every command on the suite's PATH
  : > "$AX/tspy.log"
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/own.sh"; PATH="$AXTS"
    . "$FROOT/harness/lib/$1.sh"; if declare -F "$2" >/dev/null; then printf '|defined|'; else printf '|undefined|'; fi ) 2>&1
  tr '\n' ' ' < "$AX/tspy.log"
}
: > "$AX/tspy.log"; ( PATH="$AXTS"; sed -n 1p /dev/null ) >/dev/null 2>&1
is "T2: on the PATH of spies awk and git are spies too, and a command run there is logged by its name (fixture control)" \
   "$([ -L "$AXTS/awk" ] && [ -L "$AXTS/git" ] && echo spies)|$(cat "$AX/tspy.log")" "spies|sed"
is "T2: loading lib/ledger.sh runs no command found on PATH, and it loads lib/answer.sh: felix_answer_use is defined" "$(_ax_load ledger felix_answer_use)" "|defined|"
is "T2: nor does loading lib/graph.sh, which loads lib/graph-answer.sh: felix_graph_deliver is defined" "$(_ax_load graph felix_graph_deliver)" "|defined|"
_ax_fresh() {   # LIB FUNCTION -> as _ax_load, but lib/LIB.sh is the first thing a new shell under env -i loads, "fresh" printed first when
                # that shell held no function before it; its PATH the spies alone, and HOME, FELIX_HOME and FELIX_MEMORY the fixture's
  : > "$AX/tspy.log"
  env -i HOME="$AX/user" FELIX_HOME="$AXH" FELIX_MEMORY="$AXM" PATH="$AXTS" "$BASH" -c '[ -n "$(declare -F)" ] || printf fresh; . "$1"
    if declare -F "$2" >/dev/null; then printf "|defined|"; else printf "|undefined|"; fi' _ "$FROOT/harness/lib/$1.sh" "$2" 2>&1
  tr '\n' ' ' < "$AX/tspy.log"
}
: > "$AX/tspy.log"; env -i HOME="$AX/user" PATH="$AXTS" "$BASH" -c 'sed -n 1p /dev/null' >/dev/null 2>&1
is "T2: a command run in a fresh shell under env -i, on the PATH of spies, is logged by its name too (fixture control)" "$(cat "$AX/tspy.log")" "sed"
is "T2: lib/ledger.sh loaded first in a fresh shell, with no library before it, runs no command found on PATH either, and still loads lib/answer.sh" \
   "$(_ax_fresh ledger felix_answer_use)" "fresh|defined|"
is "T2: nor does lib/graph.sh loaded first in a fresh shell, and it still loads lib/graph-answer.sh: felix_graph_deliver is defined" \
   "$(_ax_fresh graph felix_graph_deliver)" "fresh|defined|"

printf '\nR1-R4: session end and session start keep the graph current, and a lock a killed refresh left is taken back\n'
_ax_se() {   # DIR SESSION [HARNESS] -> session-end there, read through a pipe as a hook is; output and status in $AX/se.out, se.rc
  local p o; printf -v p '{"session_id":"%s","cwd":"%s","hook_event_name":"SessionEnd","reason":"other"}' "$2" "$1"
  o="$( _fx_cd "$1" && env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR FELIX_HOME="$AXH" FELIX_MEMORY="$AXM" HOME="$AX/user" \
        PATH="${AX_SEPATH:-$AX/bin:$PATH}" "${3:-$FROOT/harness}/hooks/session-end" <<<"$p" 2>&1; printf '|%s' "$?" )"
  printf '%s' "${o%|*}" > "$AX/se.out"; printf '%s' "${o##*|}" > "$AX/se.rc"
}
_ax_led() { mkdir -p "$AXH/state/ledger"; printf 'tool\tBash\n' > "$AXH/state/ledger/$1.tsv"; }
_ax_fold() { awk -F'\t' '$3 == "tool" && $4 == "Bash" { print $5 }' "$AXM/ansp/ledger.d/$1.tsv" 2>/dev/null; }
_ax_stamp "$AXO" "$AXO1"; _ax_mark "$AXO" -; rm -f "$AX/release"; : > "$AX/glog"; _ax_led r1
_ax_t0=$SECONDS; _ax_se "$AXO" r1; _ax_dt=$((SECONDS - _ax_t0)); _ax_wait 10 '[ "$(_ax_nqp "$AXO")" -gt 0 ]'; _ax_lat=$((SECONDS - _ax_t0))
is "R1: a session ending in the own checkout, its graph behind, starts a refresh of that graph" "$(_ax_nqp "$AXO")" "1"
is "R2: the hook returns while that refresh waits, within 8 seconds, exits 0 and prints nothing" "$(_ax_secs 8)|$(cat "$AX/se.rc")|$(cat "$AX/se.out")" "prompt|0|"
is "R2: and its ledger rollup runs as before" "$(_ax_fold r1)" "1"
_ax_release; _ax_wait 6 '[ -s "$AXMK" ]'; AXNEG=$(( _ax_lat * 3 + 2 )); [ "$AXNEG" -ge 3 ] || AXNEG=3; [ "$AXNEG" -le 8 ] || AXNEG=8
: > "$AX/glog"; _ax_led r1b; _ax_se "$AXO" r1b; _ax_wait "$AXNEG" '[ "$(_ax_nq)" -gt 0 ]'
is "A4: the refresh that wrote no graph at this HEAD is not started again by the next session's end" "$(_ax_nqp "$AXO")" "0"
: > "$AX/glog"; _ax_stamp "$AXO" "$AXO3"; _ax_stamp "$AXK" "$AXK1"; _ax_stamp "$AXF" "$AXF1"
_ax_led r2; _ax_se "$AXO" r2; _ax_led r3; _ax_se "$AXK" r3; _ax_led r4; _ax_se "$AXF" r4; _ax_wait "$AXNEG" '[ "$(_ax_nq)" -gt 0 ]'
is "R2: a graph that is current starts nothing" "$(_ax_nqp "$AXO")" "0"
is "R1: a checkout bound by its .felix marker alone starts nothing, its graph behind" "$(_ax_nqp "$AXK")" "0"
is "R1: nor does one bound by an origin that only contains the remote_match" "$(_ax_nqp "$AXF")" "0"
is "R2: the rollup runs whether or not a refresh starts" "$(_ax_fold r2) $(_ax_fold r3) $(_ax_fold r4)" "1 1 1"
_ax_release; : > "$AX/glog"; _ax_stamp "$AXO" "$AXO1"; _ax_mark "$AXO" -; mkdir -p "$AXH/state/machine"; : > "$AXH/state/machine/r5"; _ax_led r5; _ax_se "$AXO" r5
_ax_wait "$AXNEG" '[ "$(_ax_nq)" -gt 0 ]'
is "R1: a machine session's end starts no refresh, though its checkout is own and its graph behind" "$(_ax_nq)" "0"
_ax_release; _ax_mark "$AXO" -; : > "$AX/glog"; _ax_led r6; _ax_se "$AXW" r6; _ax_wait 10 '[ "$(_ax_nqp "$AXO")" -gt 0 ]'
is "R1: a session ending in a worktree of the own checkout refreshes the graph of the checkout that holds it" "$(_ax_nqp "$AXO")" "1"
_ax_release
_ax_hcopy "$AX/hg"; rm -f "$AX/hg/harness/lib/graph.sh"; _ax_hcopy "$AX/ho"; printf 'return 1\n' > "$AX/ho/harness/lib/own.sh"
_ax_led r7; _ax_se "$AXO" r7 "$AX/hg/harness"
is "R2: with lib/graph.sh gone the session still ends with exit 0, and its rollup runs" "$(cat "$AX/se.rc")|$(_ax_fold r7)" "0|1"
_ax_led r8; _ax_se "$AXO" r8 "$AX/ho/harness"
is "R2: with lib/own.sh failing to load the session still ends with exit 0, and its rollup runs" "$(cat "$AX/se.rc")|$(_ax_fold r8)" "0|1"
_ax_release; _ax_mark "$AXO" -; _ax_stamp "$AXO" "$AXO1"; : > "$AX/calls"; _ax_led ro1; AX_SEPATH="$AXNOG" _ax_se "$AXO" ro1 "$AX/hs/harness"
is "R1: with no graphify on PATH session end checks neither the checkout's ownership nor its graph" "$(_ax_ord session-end)" "neither"
: > "$AX/calls"; _ax_led ro2; _ax_se "$AXF" ro2 "$AX/hs/harness"
is "R1: for a checkout that is not own, ownership is checked and the due test, which reads graph.json, never runs" "$(_ax_ord session-end)" "own only"
_ax_release; _ax_stamp "$AXO" "$AXO3"; : > "$AX/calls"; _ax_led ro3; _ax_se "$AXO" ro3 "$AX/hs/harness"
is "R1: for the own checkout ownership is checked first, then the due test" "$(_ax_ord session-end)" "own then due"
_ax_age() { perl -e '$t = time - $ARGV[0] * 60; utime $t, $t, $ARGV[1] or exit 1' "$2" "$1"; }   # DIR MINUTES
_ax_young() { perl -e 'print +(time - (stat $ARGV[0])[9] < 300) ? "young" : "old"' "$1" 2>/dev/null; }
_ax_release; _ax_stamp "$AXO" "$AXO1"; _ax_mark "$AXO" -   # R3 on a graph that is due, whether or not the refresh tests that itself
rm -rf "$AXL"; mkdir -p "$AXL"; _ax_age "$AXL" 35; : > "$AX/glog"; AXOUT="$(_ax_bg)"; AXRC=$?; _ax_wait 10 '[ "$(_ax_nqp "$AXO")" -gt 0 ]'
is "R3: a lock directory 35 minutes old is taken back and the refresh proceeds, the call exiting 0 and printing nothing" "$(_ax_nqp "$AXO")|$AXRC|$AXOUT" "1|0|"
is "R3: and while that refresh runs the lock is a directory made just now" "$([ -d "$AXL" ] && _ax_young "$AXL")" "young"
_ax_release
is "R3: and the lock is gone once that refresh finishes" "$([ -d "$AXL" ] && echo held || echo gone)" "gone"
_ax_mark "$AXO" -; rm -rf "$AXL"; mkdir -p "$AXL"; _ax_age "$AXL" 25; : > "$AX/glog"; AXOUT="$(_ax_bg)"; AXRC=$?; _ax_wait "$AXNEG" '[ "$(_ax_nq)" -gt 0 ]'
is "R3: a lock 25 minutes old still means a refresh is running: nothing runs, the call exits 0 and prints nothing, the lock stays" \
   "$(_ax_nq)|$AXRC|$AXOUT|$([ -d "$AXL" ] && echo kept)" "0|0||kept"
_ax_age "$AXL" 25; : > "$AX/glog"; AX_STALE=20 _ax_bg >/dev/null; _ax_wait 10 '[ "$(_ax_nqp "$AXO")" -gt 0 ]'
is "R3: FELIX_GRAPH_LOCK_STALE=20 makes that same lock stale, and the refresh proceeds" "$(_ax_nqp "$AXO")" "1"
_ax_release; _ax_mark "$AXO" -; rm -rf "$AXL"; mkdir -p "$AXL"; : > "$AX/glog"; AXOUT="$(_ax_bg)"; AXRC=$?; _ax_wait "$AXNEG" '[ "$(_ax_nq)" -gt 0 ]'
is "R3: a lock made a moment ago means a refresh is running, and the call does nothing, as before" "$(_ax_nq)|$AXRC|$AXOUT|$([ -d "$AXL" ] && echo kept)" "0|0||kept"
rm -rf "$AXL"
printf '#!/bin/sh\ncase "$*" in "plugin list --json --available") printf "[]\\n" ;; esac\nexit 0\n' > "$AX/ssbin/claude"; printf '#!/bin/sh\nexit 0\n' > "$AX/ssbin/gh"
_ax_hcopy "$AX/hss"; printf '#!/bin/sh\ncase "$*" in "discover --inspect --quiet") printf "# stamp stub\\n" ;; esac\nexit 0\n' > "$AX/hss/harness/felix"
chmod +x "$AX/ssbin/claude" "$AX/ssbin/gh" "$AX/hss/harness/felix"
_ax_ss() {   # DIR SESSION -> session-start there, from a harness copy whose felix is a stub, bound at AX_SSB seconds (60):
             # its status in $AX/ss.rc (124 when the bound killed it), its context in AXSSC, the banner's graph lines in AXSSG
  local p o; printf -v p '{"session_id":"%s","cwd":"%s","hook_event_name":"SessionStart","source":"startup"}' "$2" "$1"
  o="$( _fx_cd "$1" && perl "$AX/bound.pl" "${AX_SSB:-60}" env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR -u FELIX_HOME_DIR -u TMPDIR -u GIT_DIR \
        -u GIT_WORK_TREE HOME="$AX/user" FELIX_HOME="$AXH" FELIX_MEMORY="$AXM" FELIX_PLUGIN_CACHE="$AX/cache" TMPDIR="$AX/tmp" CLAUDE_PLUGIN_ROOT="$AX/hss" \
        PATH="$AX/ssbin:$AX/bin:$PATH" "$AX/hss/harness/hooks/session-start" <<<"$p" 2>/dev/null; printf '|%s' "$?" )"
  printf '%s' "${o##*|}" > "$AX/ss.rc"; AXSSC="$(_ax_ctx "${o%|*}")"
  AXSSG="$(printf '%s\n' "$AXSSC" | awk '/Knowledge graph/ && !d { k = 1 } k && $0 == "" { k = 0; d = 1 } k')"
}
_ax_banner() { case "$1" in ''|'(no json)') printf 'no banner' ;; *) printf 'banner' ;; esac; }
_ax_mark "$AXO" -; _ax_stamp "$AXO" "$AXO1"; : > "$AX/glog"; _ax_ss "$AXO" s4a; AXSS1="$AXSSG"; _ax_wait 10 '[ "$(_ax_nqp "$AXO")" -gt 0 ]'
is "R4: session start in the own checkout, its graph behind and no marker, starts the refresh (control)" "$(_ax_nqp "$AXO")" "1"
_ax_release; _ax_mark "$AXO" "$AXO3"; : > "$AX/glog"; _ax_ss "$AXO" s4b; AXSS2="$AXSSG"; _ax_wait "$AXNEG" '[ "$(_ax_nqp "$AXO")" -gt 0 ]'
is "R4: with the marker holding the holding checkout's HEAD, session start starts no refresh" "$(_ax_nqp "$AXO")" "0"
is "R4: and its banner's graph line is the one it prints without the marker" "$([ -n "$AXSS1" ] && echo printed)|$AXSS2" "printed|$AXSS1"
_ax_release; _ax_mark "$AXO" -; _ax_stamp "$AXO" "$AXO3"
( _fx_cd "$AXK" && mkdir -p graphify-out && ln -s /dev/zero graphify-out/.felix-refreshed-at && git add graphify-out/.felix-refreshed-at \
  && _ax_git commit -qm k3 ) >/dev/null 2>&1
_ax_stamp "$AXK" "$AXK1"; : > "$AX/glog"; AX_SSB=40 _ax_ss "$AXK" s5; _ax_wait "$AXNEG" '[ "$(_ax_nqp "$AXK")" -gt 0 ]'
is "A3: session start in a checkout bound by .felix alone, its marker committed as a link to /dev/zero, exits 0 within 40 seconds and prints its banner" \
   "$(git -C "$AXK" ls-files graphify-out) $(readlink "$AXK/graphify-out/.felix-refreshed-at")|$(cat "$AX/ss.rc")|$(_ax_banner "$AXSSC")" \
   "graphify-out/.felix-refreshed-at /dev/zero|0|banner"
is "R4: and starts no refresh there, its graph behind, the checkout not being own" "$(_ax_nqp "$AXK")" "0"
rm -f "$AXK/graphify-out/.felix-refreshed-at"   # no later reader of the temporary tree meets the link to /dev/zero

printf '\nL1-L5: lib/ledger.sh, lib/answer.sh and felix ledger, the answer as its own surface\n'
AXLH="$AX/lh"; AXLM="$AX/lm"; AXLP="$AXLH/projects/ansl"; AXLQ="$AXLH/projects/ansm"; AXLZ="$AXLH/projects/ansz"
mkdir -p "$AXLP" "$AXLQ" "$AXLZ" "$AXLM/ansl" "$AXLM/ansm/ledger.d" "$AXLM/ansz/ledger.d"
printf 'skill\tgraphify\t-\tlow\talways\nplugin\tsuperpowers@x\t-\tlow\talways\n' > "$AXLP/stack.tsv"; cp "$AXLP/stack.tsv" "$AXLQ/stack.tsv"; cp "$AXLP/stack.tsv" "$AXLZ/stack.tsv"
_ax_ll() { ( FELIX_MEMORY="$AXLM"; HOME="$AX/user"; export FELIX_MEMORY HOME; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/own.sh"
             . "$FROOT/harness/lib/ledger.sh"; . "$FROOT/harness/lib/graph.sh"; [ ! -f "$FROOT/harness/lib/answer.sh" ] || . "$FROOT/harness/lib/answer.sh"; "$@" ) 2>/dev/null; }
_ax_ll felix_ledger_record "$AXLH" l1 "answer${AXT}graphify"; _ax_ll felix_ledger_record "$AXLH" l1 "answer${AXT}graphify"
_ax_ll felix_ledger_record "$AXLH" l1 "tool${AXT}Bash"; _ax_ll felix_ledger_rollup "$AXLP" "$AXLH" l1 2026-10-29
_ax_ll felix_ledger_record "$AXLH" l2 "answer${AXT}graphify"; _ax_ll felix_ledger_record "$AXLH" l2 "named${AXT}graphify"
_ax_ll felix_ledger_rollup "$AXLP" "$AXLH" l2 2026-10-29
is "L1: answer signals fold to one row: session, date, answer, the tool, the deliveries, and an empty sixth field" \
   "$(awk -F'\t' '$3 == "answer"' "$AXLM/ansl/ledger.d/l1.tsv" 2>/dev/null)" "l1${AXT}2026-10-29${AXT}answer${AXT}graphify${AXT}2${AXT}"
is "L1: and graphify, declared and never reached for, still gets its zero row" \
   "$(awk -F'\t' '$3 != "answer" && $4 == "graphify" && $5 == "0" { n++ } END { print n + 0 }' "$AXLM/ansl/ledger.d/l1.tsv" 2>/dev/null)" "1"
is "L1: a route naming graphify is no naming of the answer: the answer row's sixth field stays empty" \
   "$(awk -F'\t' '$3 == "answer"' "$AXLM/ansl/ledger.d/l2.tsv" 2>/dev/null)" "l2${AXT}2026-10-29${AXT}answer${AXT}graphify${AXT}1${AXT}"
is "L1: and that naming stays with graphify itself, on its own row named once, whose calls read - as l2 holds neither an alive line nor a call" \
   "$(awk -F'\t' '$3 != "answer" && $4 == "graphify" && $5 == "-" && $6 == "1" { n++ } END { print n + 0 }' "$AXLM/ansl/ledger.d/l2.tsv" 2>/dev/null)" "1"
AXLN="$AXLH/projects/ansn"; mkdir -p "$AXLN" "$AXLM/ansn"; printf 'skill\tgraphify\t-\tlow\talways\nskill\tquokka-notes\t-\tlow\talways\n' > "$AXLN/stack.tsv"
_ax_l1s() {   # SESSION LINES -> that session's ledger state written as LINES (\t, \n escapes), then folded for ansn on 2026-10-29
  mkdir -p "$AXLH/state/ledger"; printf '%b' "$2" > "$AXLH/state/ledger/$1.tsv"; _ax_ll felix_ledger_rollup "$AXLN" "$AXLH" "$1" 2026-10-29
}
_ax_l1r() {   # SESSION -> calls of graphify's named row and of quokka-notes' zero row, and the answer row's count/named, as ansn folded them
  awk -F'\t' '$3 != "answer" && $4 == "graphify" && $6 == "1" { g = g $5 } $4 == "quokka-notes" { q = q $5 } $3 == "answer" && $4 == "graphify" { a = a $5 "/" $6 }
    END { printf "graphify named %s, quokka-notes %s, answer %s", g, q, a }' "$AXLM/ansn/ledger.d/$1.tsv" 2>/dev/null
}
_ax_l1s l3 'named\tgraphify\nanswer\tgraphify\nalive\tpost-tool\ntool\tBash\nanswer\tgraphify\nalive\tpost-tool\nalive\tpost-tool\n'
is "L1: three alive lines against one call is no whole record, its two answers not counted as calls: the named row and the zero row read -" \
   "$(_ax_l1r l3)" "graphify named -, quokka-notes -, answer 2/"
_ax_l1s l4 'named\tgraphify\nanswer\tgraphify\nalive\tpost-tool\ntool\tBash\nanswer\tgraphify\n'
is "L1: one alive line and one call make the record whole beside its two answers: the named row and the zero row read 0, a measured zero" \
   "$(_ax_l1r l4)" "graphify named 0, quokka-notes 0, answer 2/"
for _ax_i in 1 2 3 4 5; do
  printf 'm%s\t2026-10-0%s\tnamed\tgraphify\t0\t1\nm%s\t2026-10-0%s\tplugin\tsuperpowers@x\t0\t0\nm%s\t2026-10-0%s\tmcp\tplugin_playwright_playwright\t3\t0\n' \
    "$_ax_i" "$_ax_i" "$_ax_i" "$_ax_i" "$_ax_i" "$_ax_i" > "$AXLM/ansm/ledger.d/m$_ax_i.tsv"
done
printf 'z1\t2026-10-01\ttool\tBash\t1\t0\n' > "$AXLM/ansz/ledger.d/z1.tsv"
_ax_read() { FELIX_LEDGER_MIN=5 _ax_ll "$1" "$AXLQ" | tr '\t\n' ' ;'; }
_ax_r0="|"; for _ax_f in summary mcp retire unobserved partly unrouted; do _ax_r0="$_ax_r0$_ax_f=$(_ax_read "felix_ledger_$_ax_f")|"; done
is "L2: five sessions that named graphify and never reached for it put it on the retire list (fixture control)" "$(FELIX_LEDGER_MIN=5 _ax_ll felix_ledger_retire "$AXLQ" | cut -f1)" "graphify"
for _ax_i in 1 2 3 4 5; do printf 'm%s\t2026-10-0%s\tanswer\tgraphify\t2\t\n' "$_ax_i" "$_ax_i" >> "$AXLM/ansm/ledger.d/m$_ax_i.tsv"; done
printf 'm1\t2026-10-01\tanswer\tothertool\t3\t\n' >> "$AXLM/ansm/ledger.d/m1.tsv"
for _ax_f in summary mcp retire unobserved partly unrouted; do
  _ax_w="${_ax_r0#*"|$_ax_f="}"; is "L2: felix_ledger_$_ax_f reads the same with answer rows folded beside the capability rows" "$(_ax_read "felix_ledger_$_ax_f")" "${_ax_w%%|*}"
done
is "L3: felix_ledger_answers prints the tool, its distinct sessions and its summed deliveries from the folded answer rows" \
   "$(_ax_ll felix_ledger_answers "$AXLQ" | LC_ALL=C sort)" "$(printf 'graphify\t5\t10\nothertool\t1\t3')"
is "L3: and nothing for a project whose ledger holds no answer row" "$(_ax_ll felix_ledger_answers "$AXLZ")" ""
AXWH='alive\tpost-tool\ntool\tRead\n'   # ledger appends that are whole by L1's test: one alive line and one call
_ax_uput() {   # HOME SESSION MARK ROWS [LEDGER] -> that session's answer record ROWS, its ledger appends LEDGER (AXWH, whole, when
               # left out; none at all for -), and its mark at own's HEAD, at a foreign commit, or none
  mkdir -p "$1/state/answer" "$1/state/session" "$1/state/ledger"; printf '%b' "$4" > "$1/state/answer/$2.tsv"
  if [ "${5-$AXWH}" = - ]; then rm -f "$1/state/ledger/$2.tsv"; else printf '%b' "${5-$AXWH}" > "$1/state/ledger/$2.tsv"; fi
  case "$3" in own) printf '%s\n' "$AXO3" > "$1/state/session/$2" ;; foreign) printf '%s\n' "$AXK1" > "$1/state/session/$2" ;; esac
}
_ax_use() { _ax_uput "$AX/use/$1" "$1" "$2" "$3" "${4-$AXWH}"; _ax_ll felix_answer_use "$AXP" "$AX/use/$1" "$AXO"; }   # NAME MARK ROWS [LEDGER] -> that one session, read
_ax_l4() { _ax_use "$1" own "$2" "${3-$AXWH}"; }; _ax_u12() { printf 'graphify'; printf '\t%s' "$@"; }
AXG1='asked\tgraphify\tanswered\nroot\t/r\ngiven\tgraphify\t1\t-\nanswer\tgraphify\tlib/one.sh\n'   # one answered delivery of lib/one.sh, root /r
AXG0='asked\tgraphify\tanswered\ngiven\tgraphify\t1\t-\nanswer\tgraphify\tlib/one.sh\n'; AXGR='asked\tgraphify\tanswered\nroot\t/r\ngiven\tgraphify\t1\t-\n'
is "L4: a Read of the file under the record's root acts on it, and opens it" "$(_ax_l4 ua "${AXG1}touch\tRead\t/r/lib/one.sh\n")" "$(_ax_u12 1 1 1 1 1 1 1 1 0 0 0)"
is "L4: an Edit whose value is the file itself acts on it" "$(_ax_l4 ub "${AXG1}touch\tEdit\tlib/one.sh\n")" "$(_ax_u12 1 1 1 1 1 1 1 1 0 0 0)"
is "L4: a touch before the answer row does not act on it" "$(_ax_l4 uc "touch\tRead\t/r/lib/one.sh\n${AXG1}")" "$(_ax_u12 1 0 1 0 1 0 0 1 0 0 0)"
is "L4: with root rows, a value that only ends in /<file> outside every root does not act on it" "$(_ax_l4 ud "${AXG1}touch\tRead\t/other/lib/one.sh\n")" "$(_ax_u12 1 0 1 0 1 0 0 1 0 0 0)"
is "L4: with no root row, a value ending in /<file> acts on it" "$(_ax_l4 ue "${AXG0}touch\tRead\t/x/lib/one.sh\n")" "$(_ax_u12 1 1 1 1 1 1 1 1 0 0 0)"
is "L4: and one ending in the file's name but not at a slash does not" "$(_ax_l4 uf 'asked\tgraphify\tanswered\ngiven\tgraphify\t1\t-\nanswer\tgraphify\ta.sh\ntouch\tRead\t/x/lib/data.sh\n')" "$(_ax_u12 1 0 1 0 1 0 0 1 0 0 0)"
is "L4: a touch after a later prompt row cannot credit the answer before it: an answer is acted on in its own turn" "$(_ax_l4 ug "${AXG1}prompt\ntouch\tRead\t/r/lib/one.sh\n")" "$(_ax_u12 1 0 1 0 1 0 0 1 0 0 0)"
is "L4: a Grep of the file's directory does not act on it" "$(_ax_l4 uh "${AXG1}touch\tGrep\t/r/lib\n")" "$(_ax_u12 1 0 1 0 1 0 0 1 0 0 0)"
is "L4: a Bash command holding the file as a path token acts on it, and opens nothing" "$(_ax_l4 ui "${AXG1}touch\tBash\tcat lib/one.sh\n")" "$(_ax_u12 1 1 1 1 1 1 0 1 0 0 0)"
is "L4: as does one holding the file under the root anywhere in it" "$(_ax_l4 uj "${AXG1}touch\tBash\twc -l</r/lib/one.sh\n")" "$(_ax_u12 1 1 1 1 1 1 0 1 0 0 0)"
is "L4: one holding the file's path under another directory does not" "$(_ax_l4 uk "${AXG1}touch\tBash\tcat /other/lib/one.sh\n")" "$(_ax_u12 1 0 1 0 1 0 0 1 0 0 0)"
is "L4: a Bash command holding the basename, which has a dot, as a token acts on the file" "$(_ax_l4 ul "${AXGR}answer\tgraphify\tengine/run.sh\ntouch\tBash\tbash run.sh --fast\n")" "$(_ax_u12 1 1 1 1 1 1 0 1 0 0 0)"
is "L4: ./ before it bounds the token too" "$(_ax_l4 um "${AXGR}answer\tgraphify\tengine/run.sh\ntouch\tBash\t./run.sh\n")" "$(_ax_u12 1 1 1 1 1 1 0 1 0 0 0)"
is "L4: a basename with no dot does not count as a token" "$(_ax_l4 un "${AXGR}answer\tgraphify\tbuild/Makefile\ntouch\tBash\tmake -C build Makefile\n")" "$(_ax_u12 1 0 1 0 1 0 0 1 0 0 0)"
is "L4: projects/a/CLAUDE.md does not credit projects/b/CLAUDE.md" "$(_ax_l4 uo "${AXGR}answer\tgraphify\tprojects/b/CLAUDE.md\ntouch\tBash\tcat projects/a/CLAUDE.md\n")" "$(_ax_u12 1 0 1 0 1 0 0 1 0 0 0)"
is "L4: and 1-24.md does not credit 4.md" "$(_ax_l4 up "${AXGR}answer\tgraphify\tdocs/4.md\ntouch\tBash\tcat docs/1-24.md\n")" "$(_ax_u12 1 0 1 0 1 0 0 1 0 0 0)"
AXB=""; for _ax_v in 'x=lib/one.sh;' '(lib/one.sh)' '"lib/one.sh"' "'lib/one.sh'" 'a:lib/one.sh:12' 'cat lib/one.sh|wc' 'cat lib/one.sh&' 'ls lib/one.sh,x'; do
  AXB="${AXB}asked\tgraphify\tanswered\ngiven\tgraphify\t1\t-\nanswer\tgraphify\tlib/one.sh\ntouch\tBash\t$_ax_v\nprompt\n"; done
is "L4: a token is bounded by = ( a quote : ; ) | & and , as well as by spaces and the ends of the command" "$(_ax_l4 uq "root\t/r\n$AXB")" "$(_ax_u12 1 1 8 8 8 8 0 8 0 0 0)"
is "L4: a delivery is a given row and the answer rows after it, acted on when any file it named was" \
   "$(_ax_l4 ur "${AXGR}answer\tgraphify\tlib/one.sh\nanswer\tgraphify\tdocs/guide.md\ntouch\tRead\t/r/lib/one.sh\nasked\tgraphify\tanswered\ngiven\tgraphify\t1\t-\nanswer\tgraphify\tnotes/n1.md\ntouch\tBash\tgrep -n x notes/other.md\n")" \
   "$(_ax_u12 1 1 2 1 3 1 1 2 0 0 0)"
is "L4: files_opened counts the acted-on files credited by a tool other than Bash" \
   "$(_ax_l4 us "${AXGR}answer\tgraphify\tlib/one.sh\nanswer\tgraphify\tdocs/guide.md\ntouch\tRead\t/r/lib/one.sh\ntouch\tBash\tcat docs/guide.md\n")" "$(_ax_u12 1 1 1 1 2 2 1 1 0 0 0)"
is "L4: asked counts the asked rows and timeouts those that timed out" \
   "$(_ax_l4 ut "${AXG1}prompt\nasked\tgraphify\ttimeout\nprompt\nasked\tgraphify\tfailed\nprompt\nasked\tgraphify\ttimeout\n")" "$(_ax_u12 1 0 1 0 1 0 0 4 2 0 0)"
is "L4: a tool with asked rows and no given row still has its line, counting no session" "$(_ax_l4 uu 'asked\tgraphify\ttimeout\nprompt\nasked\tgraphify\tempty\n')" "$(_ax_u12 0 0 0 0 0 0 0 2 1 0 0)"
is "L4: a session marked at a commit this repository does not hold is not read" "$(_ax_use uv foreign "${AXG1}touch\tRead\t/r/lib/one.sh\n")" ""
is "L4: nor is a session with no mark" "$(_ax_use uw none "${AXG1}touch\tRead\t/r/lib/one.sh\n")" ""
is "L4: each tool is its own line, its deliveries alone deciding whether the session acted on it" \
   "$(_ax_l4 ux "${AXG1}asked\tothertool\tanswered\ngiven\tothertool\t1\t-\nanswer\tothertool\tdocs/o.md\ntouch\tRead\t/r/docs/o.md\n" | LC_ALL=C sort)" \
   "$(printf 'graphify\t1\t0\t1\t0\t1\t0\t0\t1\t0\t0\t0\nothertool\t1\t1\t1\t1\t1\t1\t1\t1\t0\t0\t0')"
is "L4: a touch row naming a file of its window credits that file alone, not projects/x/CLAUDE.md for a row naming CLAUDE.md: 1 of 2 files" \
   "$(_ax_l4 uy 'asked\tgraphify\tanswered\nroot\t/r\ngiven\tgraphify\t2\t-\nanswer\tgraphify\tCLAUDE.md\nanswer\tgraphify\tprojects/x/CLAUDE.md\ntouch\tBash\tCLAUDE.md\n')" \
   "$(_ax_u12 1 1 1 1 2 1 0 1 0 0 0)"
AXG1T="${AXG1}touch\tRead\t/r/lib/one.sh\n"; AXLO="$(_ax_u12 0 0 0 0 0 0 0 0 0 0 1)"   # a delivery acted on, and a session left out
is "L4: a session with no ledger appends on disk is not whole: it is left out of every column but unknown, which counts it" "$(_ax_l4 va "$AXG1T" -)" "$AXLO"
is "L4: nor is one whose appends hold more alive lines than calls" "$(_ax_l4 vb "$AXG1T" 'alive\tpost-tool\nalive\tpost-tool\ntool\tRead\n')" "$AXLO"
is "L4: nor one that holds neither, a named row and an answer row being no calls" "$(_ax_l4 vc "$AXG1T" 'named\tgraphify\nanswer\tgraphify\n')" "$AXLO"
is "L4: nor one whose ledger appends are an empty file: an empty record, holding neither, is left out too" "$(_ax_l4 vn "$AXG1T" '')" "$AXLO"
is "L4: nor one whose alive line has only answer rows beside it, an answer row being no call" "$(_ax_l4 vd "$AXG1T" 'answer\tgraphify\nalive\tpost-tool\nanswer\tgraphify\n')" "$AXLO"
_ax_uput "$AX/use/ve" ve own "$AXG1T"; chmod 000 "$AX/use/ve/state/ledger/ve.tsv"
if [ -r "$AX/use/ve/state/ledger/ve.tsv" ]; then skip "L4: nor one whose ledger appends cannot be read" "the ledger file is still readable"
else is "L4: nor one whose ledger appends cannot be read" "$(_ax_ll felix_answer_use "$AXP" "$AX/use/ve" "$AXO")" "$AXLO"; fi
chmod 644 "$AX/use/ve/state/ledger/ve.tsv"
is "L4: as many alive lines as calls is whole, and the session counted" "$(_ax_l4 vf "$AXG1T" 'alive\tpost-tool\ntool\tRead\nalive\tpost-tool\ntool\tBash\n')" "$(_ax_u12 1 1 1 1 1 1 1 1 0 0 0)"
is "L4: and so are calls with no alive line, as appends written before 0.49.313 hold them" "$(_ax_l4 vg "$AXG1T" 'tool\tRead\n')" "$(_ax_u12 1 1 1 1 1 1 1 1 0 0 0)"
is "L4: a session left out has its asked, timeout and late rows left out with it" "$(_ax_l4 vh "${AXG1T}prompt\nasked\tgraphify\ttimeout\nprompt\nasked\tgraphify\tlate\n" -)" "$AXLO"
is "L4: unknown counts a session left out once for each tool with an asked or a given row in its record, however many it has" \
   "$(_ax_l4 vi "${AXG1}asked\tgraphify\tanswered\ngiven\tgraphify\t1\t-\nanswer\tgraphify\tdocs/guide.md\nasked\tothertool\ttimeout\n" 'alive\tpost-tool\n' | LC_ALL=C sort)" \
   "$(printf 'graphify\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t1\nothertool\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t1')"
AXUJ="$AX/use/vj"; _ax_uput "$AXUJ" vj1 own "$AXG1T"; _ax_uput "$AXUJ" vj2 own "${AXG1T}prompt\nasked\tgraphify\ttimeout\n" -
_ax_uput "$AXUJ" vj3 own "${AXG1}prompt\nasked\tgraphify\tlate\n" 'alive\tpost-tool\nalive\tpost-tool\ntool\tRead\n'
is "L4: beside a whole session, one with no appends on disk and one with more alive lines than calls add to unknown alone" \
   "$(_ax_ll felix_answer_use "$AXP" "$AXUJ" "$AXO")" "$(_ax_u12 1 1 1 1 1 1 1 1 0 0 2)"
is "L4: asked counts the asked rows whose outcome is not late, and late those whose outcome is" \
   "$(_ax_l4 vk "${AXG1}prompt\nasked\tgraphify\tlate\nprompt\nasked\tgraphify\ttimeout\nprompt\nasked\tgraphify\tlate\n")" "$(_ax_u12 1 0 1 0 1 0 0 2 1 2 0)"
is "L4: a tool whose every ask came too late still has its line" "$(_ax_l4 vl 'asked\tgraphify\tlate\nprompt\nasked\tgraphify\tlate\n')" "$(_ax_u12 0 0 0 0 0 0 0 0 0 2 0)"
is "L4: a session with no mark is not read, so not counted in unknown either, though its ledger appends are missing too" "$(_ax_use vm none "$AXG1T" -)" ""
printf '%s\n' "$AXO3" > "$AXE2/state/session/e1"
is "L4: end to end, grep -n rule <root>/CLAUDE.md through post-tool, then felix_answer_use, acts on 1 of the delivery's 2 files" \
   "$(_ax_ll felix_answer_use "$AXP" "$AXE2" "$AXO")" "$(_ax_u12 1 1 1 1 2 1 0 1 0 0 0)"
AXFH="$AX/l5h"; AXFM="$AX/l5m"; mkdir -p "$AXFH/projects/ansp" "$AXFH/state/answer" "$AXFH/state/session" "$AXFH/state/ledger" "$AXFM/ansp/ledger.d"
cp "$AXP/project.json" "$AXP/CLAUDE.md" "$AXP/stack.tsv" "$AXFH/projects/ansp/"
# Before the first felix ledger run: each session's ledger appends (whole for v1-v6, none for v7, two alive lines and no call
# for v8), then folds that account for every call on disk, then every mark, so a catch-up fold has nothing new between runs.
printf 'alive\tpost-tool\ntool\tBash\nalive\tpost-tool\ntool\tBash\n' > "$AXFH/state/ledger/v1.tsv"; : > "$AXFH/state/ledger/v2.tsv"
for _ax_i in 1 2 3 4; do printf 'alive\tpost-tool\ntool\tRead\n' >> "$AXFH/state/ledger/v2.tsv"; done
for _ax_s in v3 v4 v5 v6; do printf 'alive\tpost-tool\ntool\tRead\n' > "$AXFH/state/ledger/$_ax_s.tsv"; done
printf 'alive\tpost-tool\nalive\tpost-tool\n' > "$AXFH/state/ledger/v8.tsv"
printf 'v1\t2026-10-20\ttool\tBash\t2\t0\nv1\t2026-10-20\tskill\tgraphify\t0\t0\nv1\t2026-10-20\tplugin\tsuperpowers@x\t0\t0\n' > "$AXFM/ansp/ledger.d/v1.tsv"
printf 'v2\t2026-10-21\ttool\tRead\t4\t0\nv2\t2026-10-21\tskill\tgraphify\t0\t0\nv2\t2026-10-21\tplugin\tsuperpowers@x\t0\t0\n' > "$AXFM/ansp/ledger.d/v2.tsv"
for _ax_s in v3 v4 v5 v6; do
  printf '%s\t2026-10-22\ttool\tRead\t1\t0\n%s\t2026-10-22\tskill\tgraphify\t0\t0\n%s\t2026-10-22\tplugin\tsuperpowers@x\t0\t0\n' "$_ax_s" "$_ax_s" "$_ax_s" > "$AXFM/ansp/ledger.d/$_ax_s.tsv"
done
for _ax_s in v1 v2 v3 v4 v5 v6 v7 v8; do printf '%s\n' "$AXO3" > "$AXFH/state/session/$_ax_s"; done
_ax_fl() { ( _fx_cd "$AXO" && env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR FELIX_HOME="$AXFH" FELIX_MEMORY="$AXFM" HOME="$AX/user" "$FROOT/harness/felix" ledger 2>&1 ); }
_ax_hl() { awk -v h="$AXHEAD" '{ s = $0; gsub(/^[ \t]+|[ \t]+$/, "", s) } /CAPABILITY/ && !c { c = NR } s == h { n++; at = NR } END { printf "%d %s", n, (n && c && at > c) ? "after" : "not after" }' <<<"$1"; }
_ax_tl() { awk -v h="$AXHEAD" -v t="$1" 'm && $1 == t { gsub(/[ \t]+/, " "); print; exit } { s = $0; gsub(/^[ \t]+|[ \t]+$/, "", s) } s == h { m = 1 }' <<<"$2"; }
_ax_nx() {   # TEXT -> "after|<the sentence, whitespace collapsed>" when the sentence follows every tool line of the section
  awk -v h="$AXHEAD" '{ s = $0; gsub(/^[ \t]+|[ \t]+$/, "", s) } s == h { m = 1; next } !m { next } $2 == "answered" { last = NR }
    index($0, "A file the session would have opened anyway") && !st { st = NR } st { if (s == "") exit; t = t " " s }
    END { gsub(/ +/, " ", t); sub(/^ /, "", t); printf "%s|%s", (st && st > last) ? "after" : "not after", t }' <<<"$1"
}
_ax_tbl() { awk '/CAPABILITY/ { t = 1 } t && $0 == "" { exit } t' <<<"$1"; }
AXF0="$(_ax_fl)"
printf 'v1\t2026-10-20\tanswer\tgraphify\t1\t\n' >> "$AXFM/ansp/ledger.d/v1.tsv"; printf 'v2\t2026-10-21\tanswer\tgraphify\t3\t\n' >> "$AXFM/ansp/ledger.d/v2.tsv"
printf 'asked\tgraphify\tanswered\nroot\t%s\ngiven\tgraphify\t1\t-\nanswer\tgraphify\tlib/one.sh\ntouch\tRead\tlib/one.sh\n' "$AXO" > "$AXFH/state/answer/v1.tsv"
{ printf 'asked\tgraphify\tanswered\nroot\t%s\ngiven\tgraphify\t2\t-\nanswer\tgraphify\tdocs/guide.md\nanswer\tgraphify\tdocs/two.md\ntouch\tBash\tdocs/guide.md\n' "$AXO"
  printf 'prompt\nasked\tgraphify\ttimeout\nprompt\nasked\tgraphify\ttimeout\nprompt\nasked\tgraphify\tanswered\ngiven\tgraphify\t1\t-\nanswer\tgraphify\tnotes/n1.md\n'
  printf 'touch\tRead\tnotes/n1.md\nprompt\nasked\tgraphify\tanswered\ngiven\tgraphify\t1\t-\nanswer\tgraphify\tnotes/n2.md\n'
  printf 'prompt\nasked\tgraphify\tlate\nprompt\nasked\tgraphify\tlate\nprompt\nasked\tgraphify\tlate\n'; } > "$AXFH/state/answer/v2.tsv"
for _ax_s in v3 v4; do
  { printf 'asked\tothertool\tanswered\ngiven\tothertool\t1\t-\nanswer\tothertool\tdocs/o1.md\ntouch\tRead\tdocs/o1.md\nprompt\n'
    for _ax_i in 2 3 4 5 6 7 8; do printf 'asked\tothertool\tanswered\ngiven\tothertool\t1\t-\nanswer\tothertool\tdocs/o%s.md\nprompt\n' "$_ax_i"; done; } > "$AXFH/state/answer/$_ax_s.tsv"
done
printf 'asked\tthirdtool\ttimeout\nprompt\nasked\tthirdtool\ttimeout\n' > "$AXFH/state/answer/v5.tsv"
printf 'asked\tfourthtool\tlate\nprompt\nasked\tfourthtool\tlate\n' > "$AXFH/state/answer/v6.tsv"
for _ax_s in v7 v8; do   # both left out, so nothing in them counts but unknown: not graphify's delivery, timeout or late ask, nor fourthtool's
  { printf 'asked\tgraphify\tanswered\nroot\t%s\ngiven\tgraphify\t1\t-\nanswer\tgraphify\tlib/one.sh\ntouch\tRead\tlib/one.sh\n' "$AXO"
    printf 'prompt\nasked\tgraphify\ttimeout\nprompt\nasked\tgraphify\tlate\nprompt\nasked\tfourthtool\ttimeout\nprompt\nasked\tfourthtool\tlate\n'; } > "$AXFH/state/answer/$_ax_s.tsv"
done
AXF1="$(_ax_fl)"
is "L5: with no answer rows felix ledger prints no answers section, its capability table there (fixture control)" "$(_ax_hl "$AXF0")|$(_ax_tbl "$AXF0" | awk 'END { print NR }')" "0 not after|5"
is "L5: with answers it heads a section answers handed to sessions without being asked for, after the capability table" "$(_ax_hl "$AXF1")" "1 after"
is "L5: one line a tool: answered of asks in sessions, the answers acted on before the next prompt, the files, those opened, the asks timed out, the prompts too late to ask, and the sessions left out" \
   "$(_ax_tl graphify "$AXF1")" " graphify answered 4 of 6 asks in 2 sessions; 3 answers (75%) named a file the session then opened, edited or ran before the next prompt; 3 of 5 files (60%), 2 of them opened or edited, not only run; 2 asks timed out; 3 prompts came too late in the hook to ask; 2 sessions left out, their record of tool calls empty or incomplete"
is "L5: shares are whole percentages rounded half up, 2 of 16 being 13%, and with no timeout there is no clause for it" \
   "$(_ax_tl othertool "$AXF1")" " othertool answered 16 of 16 asks in 2 sessions; 2 answers (13%) named a file the session then opened, edited or ran before the next prompt; 2 of 16 files (13%), 2 of them opened or edited, not only run"
is "L5: and 0% where the denominator is 0" \
   "$(_ax_tl thirdtool "$AXF1")" " thirdtool answered 0 of 2 asks in 0 sessions; 0 answers (0%) named a file the session then opened, edited or ran before the next prompt; 0 of 0 files (0%), 0 of them opened or edited, not only run; 2 asks timed out"
is "L5: with no ask timed out the late and left-out clauses stand alone, in that order, and nothing of the sessions left out counts but themselves" \
   "$(_ax_tl fourthtool "$AXF1")" " fourthtool answered 0 of 0 asks in 0 sessions; 0 answers (0%) named a file the session then opened, edited or ran before the next prompt; 0 of 0 files (0%), 0 of them opened or edited, not only run; 2 prompts came too late in the hook to ask; 2 sessions left out, their record of tool calls empty or incomplete"
is "L5: and after the tool lines the sentence that bounds what the answers can have caused" "$(_ax_nx "$AXF1")" "after|$AXSENT"
is "L5: the capability table's rows are the same with the answer rows as without" "$(_ax_tbl "$AXF1")" "$(_ax_tbl "$AXF0")"
: > "$AX/release"; _ax_kids   # a refresh still waiting ends now, and no stand-in child outlives this part
