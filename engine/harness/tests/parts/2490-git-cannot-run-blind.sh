# >>> git-cannot-run
printf '\na git that cannot run is not a fact about the repository: the clause, the base, the receipt and the readers that say them (contract 2026-11-14, blind)\n'
# Blind, written on 2026-11-14 from docs/2026-11-14-git-cannot-run-contract.md (GR1 to GR8) alone, rev 1 and then
# rev 2, which rewrote GR4 (its tail, and the receipt found on disk) and took this part's GR2 and GR6 readings, and
# rev 3, whose clauses (marked rev 3 in the names) were added with the implementation committed and unread. The engine was
# read for the harness idiom, for how to call its functions and for what its outputs are today, which is what the
# GR7 controls pin; every expected value of the new behaviour comes from the contract's text. A name ending
# (control) holds on the engine the contract was cut from, on purpose; the others are its new behaviour.
#
# Readings, where the contract leaves room:
# - N is read from the stub's own status: two stubs, 69 and 70, so N is never a constant here.
# - GR2's 1 is exactly 1 (rev 2 says so; today it is git's own 128), so that assertion is red today. "VAR is not
#   set" is read as: a variable set before the call keeps its value, and an unset one stays unset.
# - GR1's "a git that answers --version and then refuses a command has run" is read through GR2 (status 1, VAR
#   untouched), GR3 (today's row, byte for byte) and GR4 (the tree changed, status 1).
# - GR3's <BASE> is the base the caller passed; "one row and nothing else" is read on stdout.
# - GR4 (rev 2): with no fourth argument, a green, a red and an absent receipt on disk each give the status-2 line
#   under a refusing git, since finding the file rests on git; a green receipt handed in gives it over a tree with
#   no id; an empty fourth argument (none) and a red one (red) are read without git and stay as they are. Under a git
#   that answers --version and refuses the rest, the on-disk form reads none and the handed-in green the tree
#   changed, as today: that git ran.
# - GR5's readers run in the checkout with PATH narrowed to the instrument and /usr/bin:/bin, as 2300 runs felix next.
#   Under a refusing git the base the CLI hands on is main as given, since no ref can be looked up. A rank-1 row of
#   felix next is a "    felix    TEXT" line in "the change in hand" and the action line under it. The sentences of
#   GR5.3 and GR5.4 are compared with line breaks and runs of blanks folded to one space; GR5.5's "no pull request was
#   opened" without regard to case; "stops" is a non-zero exit; GR5.2's "says nothing was compared" is the words
#   Nothing was compared. Each reader is also read for "names nothing" and "the tree changed", which it must not say.
# - GR6 (rev 2 takes this reading): a git that refuses from the first call ends the hook at its rev-parse --git-dir,
#   holding nothing (control). The clause is reached by a git that runs the suite's git for the hook's first reads,
#   that check included, and refuses every call from its first status on. "The usual cause" is the words a named
#   pipe, a socket, a device.
# - GR7's "writes nothing" is no new line in the project's says.log and nothing on stdout or stderr, armed by the same
#   calls over a base the branch is behind, which write one would-refuse row.
# - GR8's macOS route runs where /usr/bin/xcrun exists and /usr/bin/git exits 69 under the stand-in and 0 without it,
#   through a link to /usr/bin/git first on PATH; elsewhere its names are skipped.
# - Rev 3. GR3's quoted name is asserted for GIT in all three producers, CHANGED-PATHS in escapes, ADDED-LINES in
#   classify and SUITE in escapes, each armed by the name naming nothing here. felix merge --base SUITE naming nothing
#   is refused at its base read, before any blocker loop, so there the clause is only today's message (control).
#   GR5.1's "keeps today's row and action" is a rank-1 row holding today's names-nothing reason with today's action;
#   whether its subject is shown quoted is not pinned. GR5.7's later stop is made by a git that counts its calls and
#   refuses the chosen one and every one after; the stops tried are the merge's own rev-parse --verify ...^{commit}
#   calls, found by a run under the same git refusing nothing, in order, at most six, each run with a kernel cache of
#   its own; the first run whose output has an escapes GIT row (a line with the word GIT and the escapes tail) is
#   judged. Its closing words are its last paragraph; "to make it run" is make it run or make git run, and the
#   names-nothing sentence is looked for in the whole output, both without regard to case. GR6's "does not say that
#   no gate can run" is read as none of no gate can run, gate cannot run, gate can not run, gate cannot be run,
#   cannot run the gate, without regard to case.
# Every fixture is under $TMP/gcr and the project gcrw, built with the suite's git; a refusing git is first on PATH
# only for the call under test.

GCR="$TMP/gcr"; mkdir -p "$GCR/home" "$GCR/real" "$GCR/slog" "$GCR/usrgit" "$GCR/dd/usr/bin"; GCR="$(cd "$GCR" && pwd -P)"
_gcr_g="$(type -P git)"; ln -sf "$_gcr_g" "$GCR/real/git"
GCR_LIC="You have not agreed to the Xcode license agreements. Please run 'sudo xcodebuild -license' from within a Terminal window to review and agree to the Xcode and Apple SDKs license."
# DIR STATUS [MODE]: DIR/git prints the licence sentence on stderr and exits STATUS. MODE ver answers --version
# first; MODE stop runs the suite's git until a call names status, and refuses that call and every one after.
_gcr_stub() {
  mkdir -p "$1"
  cat > "$1/git" <<GCR_STUB_EOF
#!/bin/sh
m="\$(dirname "\$0")/stopped"
case "${3:--}" in
  ver)  [ "\${1:-}" = --version ] && { echo 'git version 2.99.0'; exit 0; } ;;
  stop) [ -e "\$m" ] || for a in "\$@"; do [ "\$a" = status ] && : > "\$m"; done
        [ -e "\$m" ] || exec "$_gcr_g" "\$@" ;;
esac
echo "$GCR_LIC" >&2
exit $2
GCR_STUB_EOF
  chmod +x "$1/git"
}
S69="$GCR/s69"; S70="$GCR/s70"; SVER="$GCR/sver"; SSTOP="$GCR/sstop"; SREAL="$GCR/real"
_gcr_stub "$S69" 69; _gcr_stub "$S70" 70; _gcr_stub "$SVER" 69 ver; _gcr_stub "$SSTOP" 69 stop
cat > "$GCR/slog/git" <<GCR_LOG_EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$GCR/slog/calls"
exec "$_gcr_g" "\$@"
GCR_LOG_EOF
chmod +x "$GCR/slog/git"
_gcr_cl() { printf 'git could not run here (git --version exited %s)' "$1"; }                                   # N -> the clause
_gcr_r4() { printf '%s, so this tree cannot be identified and no receipt can be confirmed for it' "$(_gcr_cl "$1")"; }   # N -> GR4's reason
_gcr_r3() { printf '%s, so the base %s was not looked up and %s' "$(_gcr_cl "$1")" "$2" "$3"; }                      # N BASE TAIL -> GR3's reason
GCR_TEV='no rule was consulted'; GCR_TES='nothing was scanned; no channel was consulted'; GCR_TCL='nothing was compared'
GCR_DO='make git run here, then run this again'
_gcr_flat() { printf '%s' "$1" | tr '\n\t' '  ' | tr -s ' '; }   # TEXT -> its lines joined, runs of blanks one space
# NAME TEXT +PHRASE|-PHRASE...: one assertion that TEXT holds every +PHRASE and no -PHRASE.
_gcr_hl() {
  local n="$1" t="$2" p miss=""
  shift 2
  for p in "$@"; do
    case "$p" in
      +*) case "$t" in *"${p#+}"*) ;; *) miss="$miss lacks [${p#+}];" ;; esac ;;
      -*) case "$t" in *"${p#-}"*) miss="$miss holds [${p#-}];" ;; esac ;;
    esac
  done
  if [ -z "$miss" ]; then ok "$n"; else bad "$n" "it$miss in [$t]"; fi
}

# ---- the fixture: project gcrw, a checkout on topic (main its base, ahead a commit it lacks), receipts -------------
GCR_P="$FROOT/projects/gcrw"; mkdir -p "$GCR_P" "$MEM/gcrw"
printf '{\n  "name": "gcrw",\n  "remote_match": "example.invalid/gcrw",\n  "gate": "true"\n}\n' > "$GCR_P/project.json"
cp "$REAL_HARNESS/templates/risk.tsv" "$GCR_P/risk.tsv"; cp "$TMP/probes.keep" "$GCR_P/probes.tsv"; printf '# gcrw\n' > "$GCR_P/CLAUDE.md"
printf 'code\t^src/\t^tests/\tbehaviour needs a test\n' > "$GCR_P/evidence.tsv"
_gcr_repo() {   # NAME -> $GCR/NAME, a repository on main whose one commit binds it to gcrw
  mkdir -p "$GCR/$1"
  ( _fx_cd "$GCR/$1" && git init -q -b main && printf 'gcrw\n' > .felix && printf 'one\n' > README \
    && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
}
_gcr_repo repo; _gcr_repo red; _gcr_repo none; _gcr_repo fifo
GCR_R="$GCR/repo"; GCR_RED="$GCR/red"; GCR_NONE="$GCR/none"; GCR_F="$GCR/fifo"
( _fx_cd "$GCR_R" && git checkout -q -b ahead && printf 'more\n' >> README && git -c user.name=t -c user.email=t@t commit -qam ahead \
  && git checkout -q main && git checkout -q -b topic && mkdir -p src && printf 'x\n' > src/a.ts \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm change ) >/dev/null 2>&1
_gcr_rec() {   # ROOT RC -> a gate receipt for ROOT's tree as it is (green for 0), written with the suite's git
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"
    felix_verify_record "$1" "$FROOT" "$2" gate.sh "$(felix_tree_id "$1" "$FROOT")" ) >/dev/null 2>&1
}
_gcr_rt() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"; felix_verify_receipt "$1" "$FROOT" ) 2>/dev/null; }
_gcr_rec "$GCR_R" 0; _gcr_rec "$GCR_RED" 1; _gcr_rec "$GCR_F" 0
GCR_RT="$(_gcr_rt "$GCR_R")"; GCR_REDT="$(_gcr_rt "$GCR_RED")"
unlink "$GCR_F/README" 2>/dev/null; mkfifo "$GCR_F/README" 2>/dev/null   # a tracked path git cannot read: no tree id
# DIR LIBS FN ARGS...: FN's stdout, run in the checkout with DIR first on PATH after lib/resolve.sh and LIBS; its status in $GCR/rc.
_gcr_fn() {
  local d="$1" l="$2"
  shift 2
  ( _fx_cd "$GCR_R" && env PATH="$d:$PATH" bash -c 'h="$1" l="$2"; shift 2; for f in resolve $l; do . "$h/lib/$f.sh" >/dev/null 2>&1; done; "$@"' \
      _ "$FROOT/harness" "$l" "$@" 2>/dev/null; printf '%s' "$?" > "$GCR/rc" )
}
_gcr_cur() { local d="$1" r="$2"; shift 2; printf '%s|%s' "$(_gcr_fn "$d" verify felix_verify_current "$r" "$FROOT" "$GCR_P" "$@")" "$(cat "$GCR/rc")"; }   # DIR ROOT [RECEIPT]
# DIR ROOT BASE: felix_base_resolves ROOT BASE V, V set before, then ROOT BASE W, W unset: rc=A/B V=... W=...
_gcr_fbr() {
  ( _fx_cd "$GCR_R" && env PATH="$1:$PATH" bash -c '. "$1/lib/resolve.sh" >/dev/null 2>&1; V=kept; felix_base_resolves "$2" "$3" V; a=$?
      unset W; felix_base_resolves "$2" "$3" W; b=$?; printf "rc=%s/%s V=%s W=%s" "$a" "$b" "$V" "${W-unset}"' _ "$FROOT/harness" "$2" "$3" ) 2>/dev/null
}
# DIR ARGS...: felix ARGS in the checkout, PATH DIR:/usr/bin:/bin, its stdout and stderr; its status in $GCR/rc.
_gcr_cli() {
  local d="$1"
  shift
  ( _fx_cd "$GCR_R" && env PATH="$d:/usr/bin:/bin" HOME="$GCR/home" "$FELIX" "$@" 2>&1; printf '%s' "$?" > "$GCR/rc" )
}
_gcr_v() { ( _fx_cd "$GCR" && { o="$(env PATH="$1:$PATH" git "${2:---version}" 2>&1)"; printf '%s|%s' "$o" "$?"; } ); }   # DIR [ARG] -> git ARG's output|status
GCR_GV="$( ( _fx_cd "$GCR" && "$_gcr_g" --version ) 2>/dev/null )"

printf '\n  the instruments and the fixture (GR8)\n'
is "gcr GR8 the portable instruments: git first on PATH prints the licence sentence and exits 69, or 70 (control)" \
   "$(_gcr_v "$S69")#$(_gcr_v "$S70")" "$GCR_LIC|69#$GCR_LIC|70"
is "gcr GR8 the git that answers --version: --version exits 0, rev-parse exits 69 with the licence sentence (control)" \
   "$(_gcr_v "$SVER")#$(_gcr_v "$SVER" rev-parse)" "git version 2.99.0|0#$GCR_LIC|69"
rm -f "$SSTOP/stopped"; _gcr_a="$(_gcr_v "$SSTOP")#$(_gcr_v "$SSTOP" status)#$(_gcr_v "$SSTOP")"; rm -f "$SSTOP/stopped"
is "gcr GR8 the git that stops: it runs the suite's git until a call names status, then refuses that call and the next --version with 69 (control)" \
   "$_gcr_a" "$GCR_GV|0#$GCR_LIC|69#$GCR_LIC|69"
is "gcr fixture: the checkout is on topic with main and ahead, and its receipt is green and current, the red checkout's red, the third's none, under the suite's git (control)" \
   "$(git -C "$GCR_R" rev-parse --abbrev-ref HEAD) $(git -C "$GCR_R" rev-parse -q --verify 'main^{commit}' >/dev/null && echo main) $(git -C "$GCR_R" rev-parse -q --verify 'ahead^{commit}' >/dev/null && echo ahead) $(printf '%s' "$GCR_RT" | cut -f2) $(_gcr_cur "$SREAL" "$GCR_R") $(_gcr_cur "$SREAL" "$GCR_RED") $(_gcr_cur "$SREAL" "$GCR_NONE")" \
   "topic main ahead green current|0 red|1 none|1"

printf '\n  felix_base_resolves and the clause (GR1, GR2)\n'
is "gcr GR2 0: a base that peels to a commit, V kept and W unset (control)" "$(_gcr_fbr "$SREAL" "$GCR_R" main)" "rc=0/0 V=kept W=unset"
is "gcr GR2 1: an empty ROOT or an empty BASE, under a working git and a refusing one alike, V kept and W unset (control)" \
   "$(_gcr_fbr "$SREAL" "" main)#$(_gcr_fbr "$S69" "$GCR_R" "")" "rc=1/1 V=kept W=unset#rc=1/1 V=kept W=unset"
is "gcr GR2 1: git runs and BASE names nothing there, status 1, V kept and W unset" "$(_gcr_fbr "$SREAL" "$GCR_R" nosuch)" "rc=1/1 V=kept W=unset"
is "gcr GR1 GR2 2: under a git exiting 69, a base that exists here is not looked up: status 2, V and W hold the clause with 69" \
   "$(_gcr_fbr "$S69" "$GCR_R" main)" "rc=2/2 V=$(_gcr_cl 69) W=$(_gcr_cl 69)"
is "gcr GR1 GR2 2: under a git exiting 70, status 2, V and W hold the clause with 70" \
   "$(_gcr_fbr "$S70" "$GCR_R" main)" "rc=2/2 V=$(_gcr_cl 70) W=$(_gcr_cl 70)"
is "gcr GR1 a git that answers --version and refuses rev-parse has run: status 1, V kept and W unset" \
   "$(_gcr_fbr "$SVER" "$GCR_R" main)" "rc=1/1 V=kept W=unset"
: > "$GCR/slog/calls"; _gcr_fbr "$GCR/slog" "$GCR_R" main >/dev/null; _gcr_cur "$GCR/slog" "$GCR_R" >/dev/null
_gcr_a="$(LC_ALL=C awk 'NF { n++ } { for (i = 1; i <= NF; i++) if ($i == "--version") v++ } END { printf "%s calls, %s --version", (n ? "some" : "no"), v + 0 }' "$GCR/slog/calls")"
is "gcr GR1 a git that works is never asked --version: felix_base_resolves on main and felix_verify_current on a current receipt (control)" \
   "$_gcr_a" "some calls, 0 --version"

printf '\n  the rows that name an unresolved base (GR3)\n'
GCR_L="evidence escape classify"
is "gcr GR3 evidence: under a git exiting 69, one row: unknown, GIT, the clause, the base main and no rule was consulted" \
   "$(_gcr_fn "$S69" "$GCR_L" felix_evidence_check "$GCR_P" main "$GCR_R")" "$(printf 'unknown\tGIT\t%s' "$(_gcr_r3 69 main "$GCR_TEV")")"
is "gcr GR3 escapes: under a git exiting 69, one row: unknown, GIT, the clause, the base main and nothing was scanned" \
   "$(_gcr_fn "$S69" "$GCR_L" felix_escapes "$GCR_P" main "$GCR_R" "$FROOT")" "$(printf 'unknown\tGIT\t%s' "$(_gcr_r3 69 main "$GCR_TES")")"
is "gcr GR3 classify: under a git exiting 69, one row: unknown, GIT, the clause, the base main and nothing was compared" \
   "$(_gcr_fn "$S69" "$GCR_L" felix_classify_diff "$GCR_P" main "$GCR_R")" "$(printf 'unknown\tGIT\t%s' "$(_gcr_r3 69 main "$GCR_TCL")")"
is "gcr GR3 evidence: under a git exiting 70 the row's clause carries 70" \
   "$(_gcr_fn "$S70" "$GCR_L" felix_evidence_check "$GCR_P" main "$GCR_R")" "$(printf 'unknown\tGIT\t%s' "$(_gcr_r3 70 main "$GCR_TEV")")"
is "gcr GR3 GR7 under a working git a base that names nothing gives today's three rows, byte for byte (control)" \
   "$(_gcr_fn "$SREAL" "$GCR_L" felix_evidence_check "$GCR_P" nosuch "$GCR_R")#$(_gcr_fn "$SREAL" "$GCR_L" felix_escapes "$GCR_P" nosuch "$GCR_R" "$FROOT")#$(_gcr_fn "$SREAL" "$GCR_L" felix_classify_diff "$GCR_P" nosuch "$GCR_R")" \
   "$(printf 'unknown\tnosuch\tthis base names nothing here, so no rule was consulted#unknown\tnosuch\tthis base names nothing here, so nothing was scanned; no channel was consulted#unknown\tnosuch\tthis base names nothing here, so nothing was compared')"
is "gcr GR1 GR3 under a git that answers --version and refuses the rest, the evidence row is today's for a base that names nothing (control)" \
   "$(_gcr_fn "$SVER" "$GCR_L" felix_evidence_check "$GCR_P" main "$GCR_R")" "$(printf 'unknown\tmain\tthis base names nothing here, so no rule was consulted')"
is "gcr GR3 rev 3 fixture: GIT, CHANGED-PATHS, ADDED-LINES and SUITE each name nothing in the checkout under the suite's git (control)" \
   "$(for _gcr_b in GIT CHANGED-PATHS ADDED-LINES SUITE; do git -C "$GCR_R" rev-parse -q --verify "$_gcr_b^{commit}" >/dev/null 2>&1 && printf '%s names a commit; ' "$_gcr_b"; done)" ""
_gcr_q() { printf 'unknown\t"%s"\tthis base names nothing here, so %s' "$1" "$2"; }   # BASE TAIL -> the rev 3 row naming BASE in double quotes
is "gcr GR3 rev 3 under a working git a base spelled GIT that names nothing is named in double quotes in the evidence, escapes and classify rows, reasons unchanged" \
   "$(_gcr_fn "$SREAL" "$GCR_L" felix_evidence_check "$GCR_P" GIT "$GCR_R")#$(_gcr_fn "$SREAL" "$GCR_L" felix_escapes "$GCR_P" GIT "$GCR_R" "$FROOT")#$(_gcr_fn "$SREAL" "$GCR_L" felix_classify_diff "$GCR_P" GIT "$GCR_R")" \
   "$(_gcr_q GIT "$GCR_TEV")#$(_gcr_q GIT "$GCR_TES")#$(_gcr_q GIT "$GCR_TCL")"
is "gcr GR3 rev 3 under a working git a base spelled CHANGED-PATHS that names nothing is named in double quotes in the escapes row, reason unchanged" \
   "$(_gcr_fn "$SREAL" "$GCR_L" felix_escapes "$GCR_P" CHANGED-PATHS "$GCR_R" "$FROOT")" "$(_gcr_q CHANGED-PATHS "$GCR_TES")"
is "gcr GR3 rev 3 under a working git a base spelled ADDED-LINES that names nothing is named in double quotes in the classify row, reason unchanged" \
   "$(_gcr_fn "$SREAL" "$GCR_L" felix_classify_diff "$GCR_P" ADDED-LINES "$GCR_R")" "$(_gcr_q ADDED-LINES "$GCR_TCL")"
is "gcr GR3 rev 3 under a working git a base spelled SUITE that names nothing is named in double quotes in the escapes row, reason unchanged" \
   "$(_gcr_fn "$SREAL" "$GCR_L" felix_escapes "$GCR_P" SUITE "$GCR_R" "$FROOT")" "$(_gcr_q SUITE "$GCR_TES")"

printf '\n  felix_verify_current (GR4)\n'
is "gcr GR4 a green receipt handed in, under a git exiting 69: stale, the clause with 69, status 2" \
   "$(_gcr_cur "$S69" "$GCR_R" "$GCR_RT")" "$(printf 'stale\t%s|2' "$(_gcr_r4 69)")"
is "gcr GR4 a green receipt handed in, under a git exiting 70: stale, the clause with 70, status 2" \
   "$(_gcr_cur "$S70" "$GCR_R" "$GCR_RT")" "$(printf 'stale\t%s|2' "$(_gcr_r4 70)")"
is "gcr GR4 the green receipt on disk, read by felix_verify_current itself under a git exiting 69: the same stale line, status 2" \
   "$(_gcr_cur "$S69" "$GCR_R")" "$(printf 'stale\t%s|2' "$(_gcr_r4 69)")"
is "gcr GR4 under a git exiting 69, an empty fourth argument is none and a red one is red, read without git, status 1 each (control)" \
   "$(_gcr_cur "$S69" "$GCR_R" "")#$(_gcr_cur "$S69" "$GCR_RED" "$GCR_REDT")" "none|1#red|1"
is "gcr GR4 under a git exiting 69, with no fourth argument a checkout with no receipt on disk gets the stale line, status 2" \
   "$(_gcr_cur "$S69" "$GCR_NONE")" "$(printf 'stale\t%s|2' "$(_gcr_r4 69)")"
is "gcr GR4 under a git exiting 69, with no fourth argument a red receipt on disk gets the stale line, status 2" \
   "$(_gcr_cur "$S69" "$GCR_RED")" "$(printf 'stale\t%s|2' "$(_gcr_r4 69)")"
is "gcr GR4 GR7 under a working git, a green receipt over a tree with a tracked pipe (no tree id) is the tree changed, status 1 (control)" \
   "$(_gcr_cur "$SREAL" "$GCR_F")" "$(printf 'stale\tthe tree changed since the receipt|1')"
is "gcr GR1 GR4 a git that answers --version and refuses the rest has run: a green receipt handed in is the tree changed and the one on disk is none, status 1 each (control)" \
   "$(_gcr_cur "$SVER" "$GCR_R" "$GCR_RT")#$(_gcr_cur "$SVER" "$GCR_R")" "$(printf 'stale\tthe tree changed since the receipt|1#none|1')"

printf '\n  the readers that print a reason (GR5)\n'
_gcr_sec() { printf '%s\n' "$1" | LC_ALL=C awk 'f && !NF { exit } f { print } $0 == "  the change in hand" { f = 1 }'; }   # next's rank 1
# SECTION MODE TEXT ACTION -> yes when a felix row of SECTION has TEXT (MODE is) or holds it (MODE has), ACTION under it.
_gcr_row() {
  printf '%s\n' "$1" | M="$2" T="$3" D="$4" LC_ALL=C awk '
    p { if ($0 == "               " ENVIRON["D"]) f = 1; p = 0 }
    index($0, "    felix    ") == 1 { t = substr($0, 14); if ((ENVIRON["M"] == "is" && t == ENVIRON["T"]) || (ENVIRON["M"] == "has" && index(t, ENVIRON["T"]))) p = 1 }
    END { print (f ? "yes" : "no") }'
}
GCR_O="$(_gcr_cli "$S69" next --base main)"; _gcr_a="$(_gcr_sec "$GCR_O")"
is "gcr GR5.1 next: a rank-1 felix row whose text is the GR4 reason with 69 and whose action is make git run here, then run this again" \
   "$(_gcr_row "$_gcr_a" is "$(_gcr_r4 69)" "$GCR_DO")" yes
is "gcr GR5.1 next: a rank-1 felix row holding the GR3 escapes reason with 69, with the same action" \
   "$(_gcr_row "$_gcr_a" has "$(_gcr_r3 69 main "$GCR_TES")" "$GCR_DO")" yes
_gcr_hl "gcr GR5.1 next: with a green receipt present it ran and says neither no green gate receipt nor names nothing nor the tree changed" \
   "$GCR_O" "+next for gcrw" "-this tree has no green gate receipt" "-names nothing" "-the tree changed"
_gcr_hl "gcr GR5.1 GR7 next under a working git: the receipt is current and the change owes evidence; no receipt row, no clause (control)" \
   "$(_gcr_cli "$SREAL" next --base main)" "+next for gcrw" "+the change owes evidence: code" "-no green gate receipt" "-git could not run" "-names nothing"
GCR_O="$(_gcr_cli "$SREAL" next --base GIT)"; _gcr_a="$(_gcr_sec "$GCR_O")"
_gcr_hl "gcr GR5.1 rev 3 next under a working git, --base GIT naming nothing: today's names-nothing row and action, no make-git-run action, no clause (control)" \
   "[row=$(_gcr_row "$_gcr_a" has "this base names nothing here, so nothing was scanned; no channel was consulted" "name a base that exists here, with --base, then run this again")] $_gcr_a" \
   "+[row=yes]" "-$GCR_DO" "-git could not run"
GCR_O="$(_gcr_cli "$S69" evidence --base main)"
_gcr_hl "gcr GR5.2 evidence: the GIT row as an unknown row, nothing was compared, the git sentence in place of Check --base, exit 1" \
   "[rc=$(cat "$GCR/rc")] $GCR_O" "+[rc=1] " "+  [?] GIT " "+$(_gcr_r3 69 main "$GCR_TEV")" "+Nothing was compared" \
   "+git could not run here; make it run, then run this again." "-Check --base" "-names nothing"
is "gcr GR5.2 GR7 evidence under a working git, a base that names nothing: today's output, exit 1 (control)" \
   "$(_gcr_cli "$SREAL" evidence --base nosuch)|$(cat "$GCR/rc")" \
   "$(printf 'base:  nosuch\n\n  [?] %-14s %s\n\nNothing was compared, so nothing above is a finding about this change.\nCheck --base, or the default branch, which is not `main` everywhere.\nThis says nothing about what the change owes; that was never asked.|1' nosuch 'this base names nothing here, so no rule was consulted')"
GCR_O="$(_gcr_cli "$SREAL" evidence --base GIT)"
_gcr_hl "gcr GR5.2 rev 3 evidence under a working git, --base GIT naming nothing: Check --base and not the git sentence, exit 1 (control)" \
   "[rc=$(cat "$GCR/rc")] $GCR_O" "+[rc=1] " "+Check --base" "-git could not run here; make it run, then run this again."
GCR_O="$(_gcr_flat "$(_gcr_cli "$S69" classify --base main)")"; GCR_PCL="Nothing was compared. This is not a green change and not a risky one; git could not run here, and the unknown row above says how it exited. Make git run, then run this again."
_gcr_a=no; case "$GCR_O" in *"unknown GIT $(_gcr_r3 69 main "$GCR_TCL")"*"$GCR_PCL"*) _gcr_a=yes ;; esac
_gcr_hl "gcr GR5.3 classify: the unknown GIT row, then the git paragraph in place of the one about a base it cannot resolve, exit 1" \
   "[rc=$(cat "$GCR/rc")] row-then-paragraph=$_gcr_a $GCR_O" "+[rc=1] " "+row-then-paragraph=yes" "-a base this repository cannot resolve" "-names nothing"
is "gcr GR5.3 GR7 classify under a working git, a base that names nothing: today's output, exit 1 (control)" \
   "$(_gcr_cli "$SREAL" classify --base nosuch)|$(cat "$GCR/rc")" \
   "$(printf 'base:  nosuch\ntier:  unknown\n\n  %-7s %-46s %s\n\nNothing was compared. This is not a green change and not a risky one;\nit is a base this repository cannot resolve. Check --base, or the\ndefault branch, which is not `main` everywhere.|1' unknown nosuch 'this base names nothing here, so nothing was compared')"
GCR_O="$(_gcr_flat "$(_gcr_cli "$S69" scope)")"
_gcr_hl "gcr GR5.4 scope with no paths: the clause, so nothing was compared and no tier can be given, make git run, exit 1" \
   "[rc=$(cat "$GCR/rc")] $GCR_O" "+[rc=1] " "+$(_gcr_cl 69), so nothing was compared and no tier can be given. Make git run here, then scope it." "-names nothing"
is "gcr GR5.4 GR7 scope under a working git, a base that names nothing: today's output, exit 1 (control)" \
   "$(_gcr_cli "$SREAL" scope --base nosuch)|$(cat "$GCR/rc")" \
   "$(printf 'The base nosuch names nothing here, so nothing was compared and no tier\ncan be given. Name a branch or commit this checkout has.|1')"
GCR_O="$(_gcr_flat "$(_gcr_cli "$S69" pr --base main)" | tr '[:upper:]' '[:lower:]')"
_gcr_a="$(cat "$GCR/rc")"; [ "$_gcr_a" = 0 ] || _gcr_a=non-zero
_gcr_hl "gcr GR5.5 pr: it stops with the clause and says no pull request was opened, not that the base names nothing this repository holds" \
   "[rc=$_gcr_a] $GCR_O" "+[rc=non-zero] " "+$(_gcr_cl 69)" "+no pull request was opened" "-names nothing this repository holds"
is "gcr GR5.5 GR7 pr under a working git, a base that names nothing: today's message, exit 1 (control)" \
   "$(_gcr_cli "$SREAL" pr --base nosuch)|$(cat "$GCR/rc")" \
   "$(printf "felix: the base 'nosuch' names nothing this repository holds, so\n  nothing was compared and there is no tier to put on this. No pull request\n  was opened. Check --base, or the default branch, which is not \`main\`\n  everywhere.|1")"
_gcr_gate() { printf '%s\n' "$1" | LC_ALL=C awk -F'\t' '$1 == "gate"'; }
is "gcr GR5.6 status: under a git exiting 69 the gate row is in state unknown, not a value, with the GR4 reason as its detail" \
   "$(_gcr_gate "$(_gcr_cli "$S69" status --tsv)")" "$(printf 'gate\tunknown\t-\t%s' "$(_gcr_r4 69)")"
is "gcr GR5.6 GR7 status under a working git: the gate row is value current (control)" \
   "$(_gcr_gate "$(_gcr_cli "$SREAL" status --tsv)")" "$(printf 'gate\tvalue\tcurrent\t-')"
GCR_O="$(_gcr_cli "$S69" merge --base main --dry-run)"; _gcr_a="$(cat "$GCR/rc")"; [ "$_gcr_a" = 0 ] || _gcr_a=non-zero
_gcr_hl "gcr GR5.7 merge: where it cannot read which commit the base names under a git exiting 69, it stops with the clause, not Fetch the remote" \
   "[rc=$_gcr_a] $GCR_O" "+[rc=non-zero] " "+$(_gcr_cl 69)" "-Fetch the remote, or name a base that exists" "-names nothing"
is "gcr GR5.7 GR7 merge --dry-run under a working git, a base that names nothing: today's message, exit 1 (control)" \
   "$(_gcr_cli "$SREAL" merge --base nosuch --dry-run)|$(cat "$GCR/rc")" \
   "felix: felix: cannot tell which commit 'nosuch' names in this repository (as a remote-tracking branch, a local branch or a revision), so there is no base to merge against. Fetch the remote, or name a base that exists with --base.|1"
is "gcr GR3 GR5.7 rev 3 merge --dry-run under a working git, --base SUITE naming nothing: today's base-read refusal, not the paragraph about instrument parts (control)" \
   "$(_gcr_cli "$SREAL" merge --base SUITE --dry-run)|$(cat "$GCR/rc")" \
   "felix: felix: cannot tell which commit 'SUITE' names in this repository (as a remote-tracking branch, a local branch or a revision), so there is no base to merge against. Fetch the remote, or name a base that exists with --base.|1"

printf '\n  the Stop hook (GR6)\n'
_gcr_stop() {   # DIR ROOT -> the Stop hook's stdout in ROOT with PATH DIR:/usr/bin:/bin, then |status
  ( _fx_cd "$2" && printf '%s' '{"hook_event_name":"Stop","stop_hook_active":false}' \
      | env -u FELIX_ALLOW_RED PATH="$1:/usr/bin:/bin" HOME="$GCR/home" "$FROOT/harness/hooks/stop" 2>/dev/null; printf '|%s' "$?" )
}
_gcr_held() { case "$1" in *'"decision"'*'"block"'*) printf held ;; *) printf 'not held' ;; esac; }
_gcr_last() { LC_ALL=C awk -F'\t' '{ a = $2; b = $4 } END { printf "%s %s", a, b }' "$MEM/gcrw/verification.log" 2>/dev/null; }   # -> the last verdict and detail
GCR_O="$(_gcr_stop "$S69" "$GCR_R")"
is "gcr GR6 a git that refuses from the first call: the hook holds nothing, says nothing and exits 0, as today (control)" "$GCR_O" "|0"
rm -f "$SSTOP/stopped"; GCR_O="$(_gcr_stop "$SSTOP" "$GCR_R")"; _gcr_a="$([ -e "$SSTOP/stopped" ] && echo stopped)"; rm -f "$SSTOP/stopped"
is "gcr GR6 armed: the git that stops ran the hook's first reads, refused from its status on, and the hook held (control)" \
   "$_gcr_a $(_gcr_held "$GCR_O")" "stopped held"
_gcr_hl "gcr GR6 the hold names the clause with 69 and gives no usual cause of an unreadable tree (a named pipe, a socket, a device)" \
   "$GCR_O" "+$(_gcr_cl 69)" "-a named pipe" "-a socket" "-a device"
_gcr_hl "gcr GR6 rev 3 the hold does not say that no gate can run" \
   "[$(_gcr_held "$GCR_O")] $(printf '%s' "$GCR_O" | tr '[:upper:]' '[:lower:]')" "+[held] " "-no gate can run" "-gate cannot run" "-gate can not run" "-gate cannot be run" "-cannot run the gate"
is "gcr GR6 the recorded detail stays tree unknown (control)" "$(_gcr_last)" "blocked tree unknown"
GCR_O="$(_gcr_stop "$SREAL" "$GCR_F")"
_gcr_hl "gcr GR6 GR7 under a working git a tracked pipe holds with the usual cause and no clause, detail tree unknown (control)" \
   "[$(_gcr_held "$GCR_O")] [$(_gcr_last)] $GCR_O" "+[held] [blocked tree unknown] " "+a named pipe, a socket, a device" "-git could not run"

printf '\n  the callers that only ask whether a base resolved (GR7)\n'
# DIR BASE -> owed=<felix_land_owed's status> out=[would_refuse's stdout and stderr] says=+<lines it added to says.log>
_gcr_land() {
  local n0 n1
  n0="$(cat "$MEM/gcrw/says.log" 2>/dev/null | LC_ALL=C awk 'END { print NR }')"
  _gcr_a="$(export GCR_LP="$GCR_P" GCR_LR="$GCR_R" GCR_LB="$2"; _gcr_fn "$1" "say land-table" eval 'felix_land_owed "$GCR_LP" "$GCR_LR" "$GCR_LB" >/dev/null 2>&1; o=$?
      out="$(FELIX_MERGE_DRY_RUN=0 felix_land_would_refuse "$GCR_LP" "$GCR_LB" "$GCR_LR" 2>&1)"; printf "owed=%s out=[%s]" "$o" "$out"')"
  n1="$(cat "$MEM/gcrw/says.log" 2>/dev/null | LC_ALL=C awk 'END { print NR }')"
  printf '%s says=+%s' "$_gcr_a" "$((n1 - n0))"
}
is "gcr GR7 armed: under a working git, over a base the branch is behind, felix_land_owed returns 0 and felix_land_would_refuse writes one row (control)" \
   "$(_gcr_land "$SREAL" refs/heads/ahead)" "owed=0 out=[] says=+1"
is "gcr GR7 felix_land_owed returns 2 and felix_land_would_refuse writes nothing, under a git exiting 69 and for a base that names nothing alike (control)" \
   "$(_gcr_land "$S69" refs/heads/ahead)#$(_gcr_land "$SREAL" nosuch)" "owed=2 out=[] says=+0#owed=2 out=[] says=+0"

printf '\n  the macOS instrument (GR8)\n'
printf '#!/bin/sh\necho "You have not agreed to the Xcode license agreements" >&2\nexit 69\n' > "$GCR/dd/usr/bin/xcrun"; chmod +x "$GCR/dd/usr/bin/xcrun"
GCR_MW=""; GCR_MA=""; GCR_MB=""
if [ ! -x /usr/bin/xcrun ] || [ ! -x /usr/bin/git ]; then GCR_MW="no /usr/bin/xcrun or /usr/bin/git here, so /usr/bin/git is not Apple's shim"
else
  GCR_MA="$( ( _fx_cd "$GCR" && DEVELOPER_DIR="$GCR/dd" /usr/bin/git --version 2>&1; printf '|%s' "$?" ) )"
  GCR_MB="$( ( _fx_cd "$GCR" && env -u DEVELOPER_DIR /usr/bin/git --version 2>/dev/null; printf '|%s' "$?" ) )"
  case "$GCR_MA#$GCR_MB" in *"You have not agreed to the Xcode license agreements"*"|69#git version "*"|0") ;;
    *) GCR_MW="/usr/bin/git cannot be told apart here: [$GCR_MA] under the stand-in, [$GCR_MB] without it" ;; esac
fi
ln -sf /usr/bin/git "$GCR/usrgit/git"
if [ -n "$GCR_MW" ]; then
  skip "gcr GR8 macOS: DEVELOPER_DIR at a stand-in xcrun makes /usr/bin/git exit 69 with the licence sentence, and it runs without it (control)" "$GCR_MW"
  skip "gcr GR8 macOS: under /usr/bin/git with that DEVELOPER_DIR, felix_base_resolves returns 2 and VAR holds the clause with 69" "$GCR_MW"
  skip "gcr GR8 macOS: under /usr/bin/git with that DEVELOPER_DIR, felix next gives the GR4 row and neither no green gate receipt nor names nothing" "$GCR_MW"
else
  ok "gcr GR8 macOS: DEVELOPER_DIR at a stand-in xcrun makes /usr/bin/git exit 69 with the licence sentence, and it runs without it (control)"
  is "gcr GR8 macOS: under /usr/bin/git with that DEVELOPER_DIR, felix_base_resolves returns 2 and VAR holds the clause with 69" \
     "$(export DEVELOPER_DIR="$GCR/dd"; _gcr_fbr "$GCR/usrgit" "$GCR_R" main)" "rc=2/2 V=$(_gcr_cl 69) W=$(_gcr_cl 69)"
  GCR_O="$(export DEVELOPER_DIR="$GCR/dd"; _gcr_cli "$GCR/usrgit" next --base main)"
  _gcr_hl "gcr GR8 macOS: under /usr/bin/git with that DEVELOPER_DIR, felix next gives the GR4 row and neither no green gate receipt nor names nothing" \
     "rank1=$(_gcr_row "$(_gcr_sec "$GCR_O")" is "$(_gcr_r4 69)" "$GCR_DO") $GCR_O" "+rank1=yes" "-this tree has no green gate receipt" "-names nothing"
fi

printf '\n  felix merge when git stops after the base was read (GR5.7, rev 3)\n'
cp "$TMP/obligations.keep" "$GCR_P/obligations.tsv"; cp "$TMP/commissioning.keep" "$GCR_P/commissioning.tsv"
SCNT="$GCR/scnt"; mkdir -p "$SCNT"
# The counting git: every call logged on one line of calls, numbered by count; from call number <at> on it refuses.
cat > "$SCNT/git" <<GCR_CNT_EOF
#!/bin/sh
d="\$(dirname "\$0")"
printf x >> "\$d/count"; n=\$((\$(wc -c < "\$d/count")))
printf '%s' "\$*" | tr '\n' ' ' >> "\$d/calls"; echo >> "\$d/calls"
k="\$(cat "\$d/at" 2>/dev/null)"
if [ -n "\$k" ] && [ "\$n" -ge "\$k" ]; then echo "$GCR_LIC" >&2; exit 69; fi
exec "$_gcr_g" "\$@"
GCR_CNT_EOF
chmod +x "$SCNT/git"
_gcr_merge() {   # [K] -> felix merge --base main --dry-run in the checkout, its git refusing from call K on (never for no K); stdout and stderr
  rm -f "$SCNT/count" "$SCNT/calls" "$SCNT/at"; [ -z "${1:-}" ] || printf '%s\n' "$1" > "$SCNT/at"
  ( _fx_cd "$GCR_R" || exit 1; unset FELIX_KERNEL
    env PATH="$SCNT:$PATH" HOME="$GCR/home" FELIX_KERNEL_CACHE="$GCR/kc.${1:-all}" "$FELIX" merge --base main --dry-run 2>&1 )
}
_gcr_esc() { printf '%s\n' "$1" | LC_ALL=C awk '{ g = 0; for (i = 1; i <= NF; i++) if ($i == "GIT") g = 1 } g && index($0, "nothing was scanned; no channel was consulted") { f = 1 } END { print (f ? "yes" : "no") }'; }   # OUTPUT -> yes with an escapes GIT row
_gcr_close() { printf '%s\n' "$1" | LC_ALL=C awk 'NF { p = p " " $0; next } p != "" { l = p; p = "" } END { if (p != "") l = p; print l }' | tr '[:upper:]' '[:lower:]'; }   # OUTPUT -> its last paragraph, lower case
_gcr_merge "" >/dev/null
GCR_MC="$(LC_ALL=C awk 'index($0, "rev-parse") && index($0, "--verify") && index($0, "^{commit}") { print NR }' "$SCNT/calls" 2>/dev/null | head -6 | tr '\n' ' ')"
is "gcr GR5.7 rev 3 armed: felix merge --dry-run ran the counting git and asked it rev-parse --verify of a commit (control)" \
   "$([ -s "$SCNT/calls" ] && echo calls) $([ -n "$GCR_MC" ] && echo stops)" "calls stops"
GCR_MH=""; GCR_MO=""
for _gcr_k in $GCR_MC; do
  GCR_MO="$(_gcr_merge "$_gcr_k")"
  if [ "$(_gcr_esc "$GCR_MO")" = yes ]; then GCR_MH="$_gcr_k"; break; fi
done
rm -f "$SCNT/at"
GCR_MN="gcr GR5.7 rev 3 merge: where git stops after the base was read and the escape scan gives the GIT row, its closing words say git could not run here and to make it run, not that the base names nothing this repository holds"
if [ -z "$GCR_MC" ]; then skip "$GCR_MN" "felix merge asked the counting git no rev-parse --verify of a commit, so no stop after the base read could be chosen"
elif [ -z "$GCR_MH" ]; then bad "$GCR_MN" "no stop at calls [$GCR_MC] gave an escapes GIT row; the last run said [$GCR_MO]"
else
  _gcr_a="$(_gcr_close "$GCR_MO")"; _gcr_b="$(printf '%s' "$GCR_MO" | tr '[:upper:]' '[:lower:]')"
  _gcr_c1=no; case "$_gcr_a" in *"git could not run here"*) _gcr_c1=yes ;; esac
  _gcr_c2=no; case "$_gcr_a" in *"make it run"*|*"make git run"*) _gcr_c2=yes ;; esac
  _gcr_c3=no; case "$_gcr_b" in *"names nothing this repository holds"*) _gcr_c3=yes ;; esac
  _gcr_hl "$GCR_MN" "[closing-clause=$_gcr_c1 closing-make=$_gcr_c2 names-nothing=$_gcr_c3] stopped at call $GCR_MH: $GCR_MO" \
    "+[closing-clause=yes closing-make=yes names-nothing=no]"
fi

# The home as this part found it: the pipe let go and removed, the project gone; receipts under $FROOT/state stay.
perl -e 'use Fcntl; sysopen(my $r, $ARGV[0], O_RDONLY|O_NONBLOCK); sysopen(my $w, $ARGV[0], O_WRONLY|O_NONBLOCK); close $w if $w; close $r if $r' "$GCR_F/README" 2>/dev/null
unlink "$GCR_F/README" 2>/dev/null
rm -rf "${GCR_P:?}"
unset -f _gcr_stub _gcr_cl _gcr_r4 _gcr_r3 _gcr_flat _gcr_hl _gcr_repo _gcr_rec _gcr_rt _gcr_fn _gcr_cur _gcr_fbr _gcr_cli _gcr_v \
         _gcr_sec _gcr_row _gcr_gate _gcr_stop _gcr_held _gcr_last _gcr_land _gcr_q _gcr_merge _gcr_esc _gcr_close
# <<< git-cannot-run
