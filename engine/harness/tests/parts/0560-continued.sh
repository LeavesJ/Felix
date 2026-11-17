_qualify_sweep_build
# 10. A base whose drop cannot finish: a row's mutation makes a file in its
# tree immutable. Its record stays, a later sweep says what is left, and
# once the flag is cleared the next run removes it.
if command -v chflags >/dev/null 2>&1; then
  d="$QSWS/pinned"; T="$d/t"; mkdir -p "$T" "$d/proj"; R="$(_qswroot "$d/root")"; _qswtab "$d/projb"
  _qsw5 pinned 'test -f base.txt' restoration pass 'printf x > pinned && chflags uchg pinned' > "$d/proj/qualification.tsv"
  _qswrun "$d/r1" "$T" "$R" "$d/proj"
  _qswb="$(_qswbase "$T")"; _qswr=""
  [ -n "$_qswb" ] && _qswr="$(readlink "$T/$_qswb/owner" 2>/dev/null)"
  is  "a row whose tree holds a file made immutable with chflags uchg leaves its base, once the run has ended, holding its owner record, a symlink whose pid is dead" \
      "base:$([ -n "$_qswb" ] && echo there || echo none) owner:$([ -n "$_qswb" ] && [ -L "$T/$_qswb/owner" ] && echo link || echo none) pid:$(_qswisdead "${_qswr%% *}" && echo dead || echo "not-dead[$_qswr]")" \
      "base:there owner:link pid:dead"
  _qswrun "$d/r2" "$T" "$R" "$d/projb"
  _qswr2=""; [ -n "$_qswb" ] && _qswr2="$(readlink "$T/$_qswb/owner" 2>/dev/null)"
  is  "a later run's sweep leaves that base, says so in a felix: line naming it, begins no line of its stderr with two spaces, and leaves the base holding an owner record that now names another process than the dead row" \
      "base:$([ -n "$_qswb" ] && _qswthere "$T/$_qswb" || echo none) said:$(awk -v b="$_qswb" 'b != "" && /^felix:/ && index($0, b) { f = 1 } END { print (f ? "yes" : "no") }' "$d/r2/err" 2>/dev/null) two-space:$(awk '/^  / { n++ } END { print n + 0 }' "$d/r2/err" 2>/dev/null) owner:$([ -n "$_qswb" ] && [ -L "$T/$_qswb/owner" ] && echo link || echo none) shape:$(_qswshape "$_qswr2") another:$([ -n "$_qswr2" ] && [ "$_qswr2" != "$_qswr" ] && echo yes || echo no)" \
      "base:there said:yes two-space:0 owner:link shape:pid+start another:yes"
  [ -n "$_qswb" ] && chflags -R nouchg "$T/$_qswb" 2>/dev/null
  _qswrun "$d/r3" "$T" "$R" "$d/projb"
  is  "once the flag is cleared, the next run removes that base, and the root lists only itself" \
      "base:$([ -n "$_qswb" ] && _qswthere "$T/$_qswb" || echo none-was-left) $(_qswt "$T") $(_qswwt "$R")" "base:gone t:[] wt:0"
else
  skip "a row whose tree holds a file made immutable with chflags uchg leaves its base, once the run has ended, holding its owner record, a symlink whose pid is dead" "no chflags here"
  skip "a later run's sweep leaves that base, says so in a felix: line naming it, begins no line of its stderr with two spaces, and leaves the base holding an owner record that now names another process than the dead row" "no chflags here"
  skip "once the flag is cleared, the next run removes that base, and the root lists only itself" "no chflags here"
fi

# 11. Sweeps started together: one on its own, then four over three bases.
d="$QSWS/alone"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"
_qswplant "$T" felix-qualify.ALONE1 "$R" "$(_qswdead) $QSWOLD"
_qswp1="$(_qswpre "$T/felix-qualify.ALONE1" "$R" "$Tp/felix-qualify.ALONE1/w")"
_qswbg "$d/s" "$T" "$R" - sweep; _qswfinish "$_qswpid" "$d/s"
is  "_felix_qualify_sweep called on its own, from the root with TMPDIR exported, removes a dead base and its registration and prints nothing on stdout or stderr" \
    "$(_qswgone "$_qswp1" "$T/felix-qualify.ALONE1" "$R" "$Tp/felix-qualify.ALONE1/w") stdout:[$(cat "$d/s/out" 2>/dev/null)] stderr:[$(cat "$d/s/err" 2>/dev/null)]" \
    "gone stdout:[] stderr:[]"
# The record and the parent of git, read by git itself as the remove starts.
_qswbyrec() { awk -v b="/$2/w" 'index($0, " worktree remove ") && index($0, b) { print }' "$1" 2>/dev/null \
  | sed -n 's/.* rec:\[\([0-9][0-9]*\)[] ].* ppid:\([0-9][0-9]*\)$/\1 \2/p' | head -1; }
_qswrp="$(_qswbyrec "$d/s/git" felix-qualify.ALONE1)"
is  "when the sweep's drop calls git worktree remove on a dead base's tree, the base's owner record already names the process making that call, the sweep's own, and not the dead row" \
    "claimed:$([ -n "$_qswrp" ] && [ "${_qswrp% *}" = "${_qswrp#* }" ] && echo yes || echo "no[$_qswrp]")" "claimed:yes"

# A sweep killed in its claim or its drop. Stopped right after its first
# rename, or its first link, or as its drop's git starts, or right after its
# drop's first rm, then the whole group KILLed: whatever the base was left
# holding, a later sweep removes it, registration included. For rm the base
# also holds a file beside its tree, so the drop's clearing of what git left
# makes an rm call: one that removed the owner record before the rest of the
# base left a base no later sweep could judge, a case only chflags staged
# until now, which Linux has not (review round 2).
for _qswk in mv ln git rm; do
  d="$QSWS/killed-sweep-$_qswk"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"
  _qswplant "$T" felix-qualify.KSWEEP "$R" "$(_qswdead) $QSWOLD"
  [ "$_qswk" = rm ] && printf 'junk\n' > "$T/felix-qualify.KSWEEP/zz"
  _qswp1="$(_qswpre "$T/felix-qualify.KSWEEP" "$R" "$Tp/felix-qualify.KSWEEP/w")"
  case "$_qswk" in
    mv)  _qswpath="$QSWHOLD"; _qswxenv="QSW_HOLDMV=$d/at" ;;
    ln)  _qswpath="$QSWHOLD"; _qswxenv="QSW_HOLDLN=$d/at" ;;
    rm)  _qswpath="$QSWHOLD"; _qswxenv="QSW_HOLDRM=$d/at" ;;
    git) _qswxenv="QSW_GITHOLD=$d/at" ;;
  esac
  _qswbg "$d/s1" "$T" "$R" - sweep; _qswpath=""; _qswxenv=""
  _qswtill 120 _qswheld "$d/at" "$_qswpid"
  _qswheldk="$([ -e "$d/at" ] && echo yes || echo no)"
  disown "$_qswpid" 2>/dev/null; kill -s KILL -- "-$_qswpid" 2>/dev/null
  _qswtill 120 _qswdone "$_qswpid"; _qswstop "$_qswpid"
  # Every pid a link in the base names reaped, so none is a zombie kill -0 finds.
  for _qswl in owner claim; do
    _qswr="$(readlink "$T/felix-qualify.KSWEEP/$_qswl" 2>/dev/null)"
    case "${_qswr%% *}" in ''|*[!0-9]*) ;; *) _qswtill 60 _qswreaped "${_qswr%% *}" ;; esac
  done
  _qswmid="$(ls -A "$T/felix-qualify.KSWEEP" 2>/dev/null | LC_ALL=C sort | tr '\n' ',')"
  if [ "$_qswk" = git ]; then
    _qswrp="$(_qswbyrec "$d/s1/git" felix-qualify.KSWEEP)"
    _qswr="$(readlink "$T/felix-qualify.KSWEEP/owner" 2>/dev/null)"
    _qswtill 60 _qswreaped "${_qswr%% *}"
    is  "a sweep KILLed as its drop's git worktree remove starts leaves the base holding only its tree and one owner record, which names that sweep's own process, now dead" \
        "entries:$_qswmid named:$([ -n "$_qswrp" ] && [ "${_qswr%% *}" = "${_qswrp#* }" ] && echo sweep || echo "other[$_qswr|$_qswrp]") pid:$(_qswisdead "${_qswr%% *}" && echo dead || echo not-dead)" \
        "entries:owner,w, named:sweep pid:dead"
  fi
  _qswbg "$d/s2" "$T" "$R" - sweep; _qswfinish "$_qswpid" "$d/s2"
  is  "a sweep KILLed right after its first $_qswk in claiming or dropping a dead base leaves it for the next sweep, which removes the base and its registration and says nothing" \
      "held:$_qswheldk then:$(_qswgone "$_qswp1" "$T/felix-qualify.KSWEEP" "$R" "$Tp/felix-qualify.KSWEEP/w") felix:$(_qswfelix "$d/s2/err") left:[$_qswmid]" \
      "held:yes then:gone felix:0 left:[$_qswmid]"
done

# A base another sweep is claiming, its claim a link naming a live process,
# is left as it was, and no git worktree remove is made for it; one whose
# claim names a dead process is taken over and swept.
d="$QSWS/claim-held"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"
sleep 900 & _qswcl=$!
_qswplant "$T" felix-qualify.HELDCL "$R" "$(_qswdead) $QSWOLD"; ln -s "$_qswcl $(_qswstart "$_qswcl")" "$T/felix-qualify.HELDCL/claim"
_qswplant "$T" felix-qualify.DEADCL "$R" "$(_qswdead) $QSWOLD"; ln -s "$(_qswdead) $QSWOLD" "$T/felix-qualify.DEADCL/claim"
mkdir -p "$d/snap"; _qswsnap "$T/felix-qualify.HELDCL" "$R" "$Tp/felix-qualify.HELDCL/w" > "$d/snap/held"
_qswcl1="$(readlink "$T/felix-qualify.HELDCL/claim" 2>/dev/null)"
_qswp1="$(_qswpre "$T/felix-qualify.DEADCL" "$R" "$Tp/felix-qualify.DEADCL/w")"
_qswbg "$d/s" "$T" "$R" - sweep; _qswfinish "$_qswpid" "$d/s"
is  "a dead base whose claim link names a live process is left as it was, its owner record, its claim and its registration, and the sweep makes no git worktree remove of its tree, beside a dead base whose claim names a dead process, which is swept" \
    "beside:$(_qswgone "$_qswp1" "$T/felix-qualify.DEADCL" "$R" "$Tp/felix-qualify.DEADCL/w") same:$([ "$(_qswsnap "$T/felix-qualify.HELDCL" "$R" "$Tp/felix-qualify.HELDCL/w")" = "$(cat "$d/snap/held")" ] && echo yes || echo no) claim:$([ "$(readlink "$T/felix-qualify.HELDCL/claim" 2>/dev/null)" = "$_qswcl1" ] && echo same || echo changed) removes:$(awk '/ worktree remove / && /HELDCL/ { n++ } END { print n + 0 }' "$d/s/git")" \
    "beside:gone same:yes claim:same removes:0"
kill -s KILL "$_qswcl" 2>/dev/null; wait "$_qswcl" 2>/dev/null
# A sweep that judged a base's record dead before another sweep claimed it.
# The late one is held right after its chmod of the base, so after its
# judgement and before its claim, until the other has renamed its claim over
# owner and stands in its drop's git. The late one's claim link then takes
# the free name, but owner no longer reads the record it judged dead, so it
# must leave the base: owner still the other sweep's, no worktree remove of
# its own, and no claim left. A sweep that skipped that check renamed its
# claim over the live one and dropped the tree a second time (lead's mutant
# noverify, 2026-10-02; the four-sweep rounds below never hit the window).
QSWHOLDC="$QSWS/hold-chmod"; mkdir -p "$QSWHOLDC"
cat > "$QSWHOLDC/chmod" <<EOF
#!/bin/sh
'$(command -v chmod)' "\$@"; qsw_rc=\$?
if [ -n "\${QSW_HOLDCHMOD:-}" ] && [ ! -e "\$QSW_HOLDCHMOD" ]; then
  printf 'held\n' > "\$QSW_HOLDCHMOD"
  qsw_i=0; while [ ! -e "\$QSW_HOLDCHMOD.go" ] && [ \$qsw_i -lt 300 ]; do sleep 1; qsw_i=\$((qsw_i + 1)); done
fi
exit \$qsw_rc
EOF
chmod +x "$QSWHOLDC/chmod"
d="$QSWS/claim-late"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"
_qswplant "$T" felix-qualify.LATECL "$R" "$(_qswdead) $QSWOLD"
_qswp1="$(_qswpre "$T/felix-qualify.LATECL" "$R" "$Tp/felix-qualify.LATECL/w")"
_qswpath="$QSWHOLDC"; _qswxenv="QSW_HOLDCHMOD=$d/at2"
_qswbg "$d/s2" "$T" "$R" - sweep; _qswpath=""; _qswxenv=""; _qswlate2="$_qswpid"
_qswtill 120 _qswheld "$d/at2" "$_qswlate2"
_qswxenv="QSW_GITHOLD=$d/at1"
_qswbg "$d/s1" "$T" "$R" - sweep; _qswxenv=""; _qswlate1="$_qswpid"
_qswtill 120 _qswheld "$d/at1" "$_qswlate1"
_qswlateh="$([ -e "$d/at2" ] && echo yes || echo no),$([ -e "$d/at1" ] && echo yes || echo no)"
_qswo1="$(readlink "$T/felix-qualify.LATECL/owner" 2>/dev/null)"
: > "$d/at2.go"
_qswfinish "$_qswlate2" "$d/s2"
_qswo2="$(readlink "$T/felix-qualify.LATECL/owner" 2>/dev/null)"
is  "a sweep that judged a base's record dead before another sweep claimed it, and reaches its own claim only while the other stands in its drop, leaves the base: owner still names the other sweep, and it makes no git worktree remove, leaves no claim and says nothing" \
    "held:$_qswlateh owner:$([ -n "$_qswo1" ] && [ "$_qswo2" = "$_qswo1" ] && echo kept || echo "changed[$_qswo1|$_qswo2]") removes:$(awk '/ worktree remove / && /LATECL/ { n++ } END { print n + 0 }' "$d/s2/git") claim:$([ -L "$T/felix-qualify.LATECL/claim" ] && echo left || echo none) felix:$(_qswfelix "$d/s2/err")" \
    "held:yes,yes owner:kept removes:0 claim:none felix:0"
disown "$_qswlate1" 2>/dev/null; kill -s KILL -- "-$_qswlate1" 2>/dev/null
_qswtill 120 _qswdone "$_qswlate1"; _qswstop "$_qswlate1"
case "${_qswo1%% *}" in ''|*[!0-9]*) ;; *) _qswtill 60 _qswreaped "${_qswo1%% *}" ;; esac
_qswbg "$d/s3" "$T" "$R" - sweep; _qswfinish "$_qswpid" "$d/s3"
is  "and once that other sweep is KILLed in its drop's git, the next sweep removes the base and its registration" \
    "$(_qswgone "$_qswp1" "$T/felix-qualify.LATECL" "$R" "$Tp/felix-qualify.LATECL/w")" "gone"
# Three rounds, so a race that leaves a base one time in two shows.
_qswtg=""
for _qswround in 1 2 3; do
  d="$QSWS/together$_qswround"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"
  for _qswi in 1 2 3; do _qswplant "$T" "felix-qualify.TOGET$_qswi" "$R" "$(_qswdead) $QSWOLD"; done
  _qswp1="$(_qswt "$T") $(_qswwt "$R")"
  for _qswi in 1 2 3 4; do _qswbg "$d/s$_qswi" "$T" "$R" "$d/go" sweep; printf '%s\n' "$_qswpid" > "$d/s$_qswi/pid"; done
  _qswtill 120 _qswallin "$d/s1/caller" "$d/s2/caller" "$d/s3/caller" "$d/s4/caller"
  : > "$d/go"
  for _qswi in 1 2 3 4; do _qswfinish "$(cat "$d/s$_qswi/pid")" "$d/s$_qswi"; done
  _qswtg="$_qswtg r$_qswround:[was:[$_qswp1] $(_qswt "$T") $(_qswwt "$R") stdout:$(cat "$d"/s*/out 2>/dev/null | wc -c | tr -d ' ') felix:$(cat "$d"/s*/err 2>/dev/null | awk '/^felix:/ { n++ } END { print n + 0 }')]"
done
_qswtw="[was:[t:[felix-qualify.TOGET1 felix-qualify.TOGET2 felix-qualify.TOGET3 ] wt:3] t:[] wt:0 stdout:0 felix:0]"
is  "four sweeps started together over three dead bases, in each of three rounds, leave none of them on disk or registered, print nothing on stdout, and say no felix: line" \
    "$_qswtg" " r1:$_qswtw r2:$_qswtw r3:$_qswtw"

# 12. Quiet: a run that sweeps prints what a run with nothing to sweep does.
d="$QSWS/quiet"; mkdir -p "$d/t0" "$d/t1" "$d/proj"; R="$(_qswroot "$d/root")"
{ _qsw5 quiet '! test -f bad.txt' violation fail 'printf FORBIDDEN > bad.txt'
  _qsw5 quiet 'test -f base.txt' violation fail true
  _qsw6 quiet true restoration pass true 'exit 1'
} > "$d/proj/qualification.tsv"
_qswrun "$d/r0" "$d/t0" "$R" "$d/proj"
_qswplant "$d/t1" felix-qualify.QUIET1 "$R" "$(_qswdead) $QSWOLD"
_qswplant "$d/t1" felix-qualify.QUIET2 - "$(_qswdead) $QSWOLD"
_qswp1="$(_qswt "$d/t1") $(_qswwt "$R")"
_qswrun "$d/r1" "$d/t1" "$R" "$d/proj"
is  "a run that sweeps two dead bases prints byte for byte the three verdict lines a run with nothing to sweep prints, says nothing on stderr, and leaves its TMPDIR empty and the root listing only itself" \
    "was:[$_qswp1] stdout:$(cmp -s "$d/r0/out" "$d/r1/out" && echo same || echo differs) lines:$(awk 'END { print NR }' "$d/r1/out" 2>/dev/null) stderr:[$(cat "$d/r1/err" 2>/dev/null)] $(_qswt "$d/t1") $(_qswwt "$R")" \
    "was:[t:[felix-qualify.QUIET1 felix-qualify.QUIET2 ] wt:1] stdout:same lines:3 stderr:[] t:[] wt:0"

# 12b. The caller's glob options: a run whose shell has failglob from its
# BASH_ENV, and one that has noglob from an exported SHELLOPTS, sweeps a dead
# base and throws its own row's base away, junk its mutation wrote beside the
# tree and all, as a run with neither does.
d="$QSWS/globopts"; mkdir -p "$d/proj"; R="$(_qswroot "$d/root")"
printf 'shopt -s failglob\n' > "$d/failglob.sh"
_qsw5 junk 'test -f base.txt' restoration pass 'printf x > ../junk' > "$d/proj/qualification.tsv"
for _qswo in failglob noglob; do
  mkdir -p "$d/t-$_qswo"
  _qswplant "$d/t-$_qswo" felix-qualify.GLOBOP "$R" "$(_qswdead) $QSWOLD"
  _qswp1="$(_qswpre "$d/t-$_qswo/felix-qualify.GLOBOP" "$R" "$(_qswphys "$d/t-$_qswo")/felix-qualify.GLOBOP/w")"
  case "$_qswo" in failglob) _qswxenv="BASH_ENV=$d/failglob.sh" ;; noglob) _qswxenv="SHELLOPTS=noglob" ;; esac
  _qswrun "$d/r-$_qswo" "$d/t-$_qswo" "$R" "$d/proj"; _qswxenv=""
  is  "a run whose shell has $_qswo set by its caller still reads its row pass and met, sweeps a dead base, registration included, throws its own row's base away with the junk its mutation wrote beside the tree, and says no felix: line" \
      "$(_qswverd "$d/r-$_qswo") dead:$(_qswgone "$_qswp1" "$d/t-$_qswo/felix-qualify.GLOBOP" "$R" "$(_qswphys "$d/t-$_qswo")/felix-qualify.GLOBOP/w") $(_qswt "$d/t-$_qswo") felix:$(_qswfelix "$d/r-$_qswo/err")" \
      "pass met dead:gone t:[] felix:0"
done

# 13. Through the CLI, from a checkout bound to a project of the section's
# own, in a home of its own: felix qualify --gate and felix qualify.
QSWH="$QSWS/home"; QSWHR="$QSWS/home-repo"
mkdir -p "$QSWH/projects/sweepq" "$QSWH/harness" "$MEM/sweepq" "$QSWHR"
cp -R "$FROOT/harness/." "$QSWH/harness/"
printf '{ "name": "sweepq", "gate": "true" }\n' > "$QSWH/projects/sweepq/project.json"
printf '# sweepq\n' > "$QSWH/projects/sweepq/CLAUDE.md"
( _fx_cd "$QSWHR" && git init -q -b main && printf 'clean\n' > base.txt && printf 'sweepq\n' > .felix \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
QSWHR="$(_qswphys "$QSWHR")"; printf '%s\n' "$QSWHR" >> "$QSWS/roots"
{ _qsw5 sweepme '! test -f bad.txt' violation fail 'printf FORBIDDEN > bad.txt'
  _qsw5 sweepme 'test -f base.txt' restoration pass true
  _qsw5 sweepheld 'test -f base.txt' violation fail true
} > "$QSWH/projects/sweepq/qualification.tsv"
_qswcli() {   # dir, T, felix qualify's arguments
  local d="$1" t="$2"; shift 2
  mkdir -p "$d"; rm -f "$d/rc"
  TZ=JST-9 TMPDIR="$t" FELIX_HOME="$QSWH" PATH="$QSWSHIM:$PATH" QSW_GITLOG="$d/git" \
    perl -e '$SIG{INT} = $SIG{TERM} = $SIG{HUP} = "DEFAULT"; setpgrp(0, 0) or exit 97; exec @ARGV or exit 98' \
    "$BASH" "$QSWC" "$QSWHR" "$d/rc" "$QSWH/harness/felix" qualify "$@" </dev/null >"$d/out" 2>"$d/err" &
  _qswpid=$!
  printf '%s\n' "$_qswpid" >> "$QSWS/pids"
  _qswfinish "$_qswpid" "$d"
}
d="$QSWS/cli"; mkdir -p "$d/t0" "$d/t1" "$d/t2"
_qswcli "$d/g0" "$d/t0" --gate
_qswplant "$d/t1" felix-qualify.CLIGAT "$QSWHR" "$(_qswdead) $QSWOLD"
_qswp1="$(_qswpre "$d/t1/felix-qualify.CLIGAT" "$QSWHR" "$(_qswphys "$d/t1")/felix-qualify.CLIGAT/w")"
_qswcli "$d/g1" "$d/t1" --gate
is  "felix qualify --gate from a bound checkout sweeps a dead base in its TMPDIR, registration included, and prints the same stdout and stderr, its three rows among them, and exits with the same status as a run with nothing to sweep" \
    "$(_qswgone "$_qswp1" "$d/t1/felix-qualify.CLIGAT" "$QSWHR" "$(_qswphys "$d/t1")/felix-qualify.CLIGAT/w") stdout:$(cmp -s "$d/g0/out" "$d/g1/out" && echo same || echo differs) rows:$(awk '/^  sweep[a-z]* +(violation|restoration) / { n++ } END { print n + 0 }' "$d/g1/out" 2>/dev/null) stderr:$(cmp -s "$d/g0/err" "$d/g1/err" && echo same || echo differs) rc:$(cat "$d/g1/rc" 2>/dev/null)" \
    "gone stdout:same rows:3 stderr:same rc:$(cat "$d/g0/rc" 2>/dev/null)"
_qswplant "$d/t2" felix-qualify.CLIPLN "$QSWHR" "$(_qswdead) $QSWOLD"
_qswp2="$(_qswpre "$d/t2/felix-qualify.CLIPLN" "$QSWHR" "$(_qswphys "$d/t2")/felix-qualify.CLIPLN/w")"
_qswcli "$d/p2" "$d/t2"
is  "felix qualify without --gate sweeps a dead base in its TMPDIR as well, registration included" \
    "$(_qswgone "$_qswp2" "$d/t2/felix-qualify.CLIPLN" "$QSWHR" "$(_qswphys "$d/t2")/felix-qualify.CLIPLN/w") rows:$(awk '/^  sweep[a-z]* +(violation|restoration) / { n++ } END { print n + 0 }' "$d/p2/out" 2>/dev/null)" \
    "gone rows:3"

# 14. Once, at the start: a dead base a row's mutation plants mid-run, outside
# its own base, is still there when the run ends; the next run removes it.
d="$QSWS/once"; T="$d/t"; mkdir -p "$T" "$d/proj"; R="$(_qswroot "$d/root")"; _qswtab "$d/projb"
_qswd="$(_qswdead)"
{ _qsw5 plants 'test -f base.txt' restoration pass "mkdir '$T/felix-qualify.LATE01' && ln -s '$_qswd $QSWOLD' '$T/felix-qualify.LATE01/owner'"
  _qsw5 after 'test -f base.txt' restoration pass true
} > "$d/proj/qualification.tsv"
_qswrun "$d/r1" "$T" "$R" "$d/proj"
_qswwas="$(_qswthere "$T/felix-qualify.LATE01")"
_qswrun "$d/r2" "$T" "$R" "$d/projb"
is  "a dead base a row's mutation plants beside its own base mid-run is still there when that run ends, both its rows read pass and met, and the next run removes it" \
    "first:$_qswwas rows:$(_qswverd "$d/r1") next:$(_qswthere "$T/felix-qualify.LATE01")" \
    "first:there rows:pass met; pass met next:gone"

# 15. A row whose owner record cannot be made runs nothing. Staged by giving
# the row its base without the write bit, so the link cannot be made there.
d="$QSWS/unrecorded"; T="$d/t"; mkdir -p "$T" "$d/probe"; R="$(_qswroot "$d/root")"; _qswtab "$d/proj"
chmod 0500 "$d/probe"
if ( : > "$d/probe/x" ) 2>/dev/null; then
  chmod 0700 "$d/probe"
  skip "a row whose owner record cannot be made, its base left without its write bit, reads unrunnable, adds no worktree, leaves no base or registration, and says one felix: line naming its base" "a directory without its write bit does not stop this user writing"
else
  chmod 0700 "$d/probe"
  _qswnorec=1; _qswrun "$d/r" "$T" "$R" "$d/proj"; _qswnorec=""
  _qswmb="$(awk '/\/felix-qualify\./ { print; exit }' "$d/r/made" 2>/dev/null)"
  is  "a row whose owner record cannot be made, its base left without its write bit, reads unrunnable, adds no worktree, leaves no base or registration, and says one felix: line naming its base" \
      "$(_qswverd "$d/r") adds:$(awk '/ worktree add / { n++ } END { print n + 0 }' "$d/r/git" 2>/dev/null) $(_qswt "$T") $(_qswwt "$R") felix:$(_qswfelix "$d/r/err") named:$(awk -v b="$_qswmb" 'b != "" && /^felix:/ && index($0, b) { f = 1 } END { print (f ? "yes" : "no") }' "$d/r/err" 2>/dev/null)" \
      "unrunnable unrunnable adds:0 t:[] wt:0 felix:1 named:yes"
fi

# A run whose checker filter selects no row still sweeps.
d="$QSWS/none-selected"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"; _qswtab "$d/proj"
_qswplant "$T" felix-qualify.NONSEL "$R" "$(_qswdead) $QSWOLD"
_qswp1="$(_qswpre "$T/felix-qualify.NONSEL" "$R" "$Tp/felix-qualify.NONSEL/w")"
_qswrun "$d/r" "$T" "$R" "$d/proj" nobody
is  "a run whose checker names no row of its table still sweeps a dead base in its TMPDIR, registration included, and prints nothing" \
    "$(_qswgone "$_qswp1" "$T/felix-qualify.NONSEL" "$R" "$Tp/felix-qualify.NONSEL/w") stdout:[$(cat "$d/r/out" 2>/dev/null)]" "gone stdout:[]"

_qualify_sweep_cleanup

