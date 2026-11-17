printf '\nqualification: a later run sweeps the trees a killed run left\n'
# No trap reaches SIGKILL. A row killed that way, by kill -9 or a tool's
# TERM-then-KILL, left its scratch tree in TMPDIR and still registered in the
# user's repository: three were found in the founder's checkout. So each row
# now writes down which process owns its base, as a symlink named owner in
# it, and each run first sweeps its TMPDIR for bases whose owner is shown
# dead, then for registrations whose base is gone. It touches nothing else:
# not a base whose owner may be alive, not one whose name or record is not
# exactly what a row writes, not a symlink, not another shape of
# registration, and it never prunes.
#
# Each case has a TMPDIR of its own under the suite's $TMP, so no other
# session's sweep reaches its bases, and a root of its own, so a
# registration one case leaves counts against no other. A dead pid is one a
# process started here had before it was reaped; a live one is a sleep
# started here and killed at the end. Every run starts in a process group of
# its own, made by perl, as the scratch-tree section's are, and every wait
# has a deadline; only those groups, walked down from the pid recorded, are
# ever signalled. A git on PATH notes each call a run makes. Every case a
# sweep must leave alone shares its TMPDIR and its run with a dead base that
# run must remove, so an engine that sweeps nothing cannot pass it. At the
# end the section stops what it started, gives its directories their bits
# back, clears immutable flags, prunes its own roots alone and removes all
# it made. Authored blind to the fix, from the contract in prose.
_qualify_sweep_build

# 1. End to end. A run SIGKILLed as a whole group while its checker holds:
# nothing trapped, so its base and registration stay, and its record names
# a process that is gone. A later run in the same TMPDIR removes both.
d="$QSWS/killed"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"; _qswtab "$d/projb"
# Disowned first, so the shell reaps the killed caller without a line about it.
_qswhold "$d" "$T" "$R" && { disown "$_qswa" 2>/dev/null; kill -s KILL -- "-$_qswa" 2>/dev/null; }
_qswtill 120 _qswdone "$_qswa"; _qswstop "$_qswa"
_qswb="$(_qswbase "$T")"; _qswr=""
[ -n "$_qswb" ] && _qswr="$(readlink "$T/$_qswb/owner" 2>/dev/null)"
case "${_qswr%% *}" in ''|*[!0-9]*) ;; *) _qswtill 60 _qswreaped "${_qswr%% *}" ;; esac
is  "a run SIGKILLed as a whole process group while its row's checker holds leaves that row's base in its TMPDIR, holding owner, a symlink whose pid is now dead, and the tree in it still registered in the root" \
    "base:$([ -n "$_qswb" ] && echo there || echo none) owner:$([ -n "$_qswb" ] && [ -L "$T/$_qswb/owner" ] && echo link || echo none) pid:$(_qswisdead "${_qswr%% *}" && echo dead || echo "not-dead[$_qswr]") registered:$([ -n "$_qswb" ] && _qswlisted "$R" "$(_qswphys "$T")/$_qswb/w" || echo no)" \
    "base:there owner:link pid:dead registered:yes"
_qswkpre="none-left"; [ -n "$_qswb" ] && _qswkpre="$(_qswpre "$T/$_qswb" "$R" "$(_qswphys "$T")/$_qswb/w")"
_qswrun "$d/b" "$T" "$R" "$d/projb"
is  "a later felix_qualify_run in the same TMPDIR removes that base and its registration, leaving the TMPDIR empty and the root listing only itself, and its own row still reads pass and met" \
    "$(_qswverd "$d/b") killed:$([ -n "$_qswb" ] && _qswgone "$_qswkpre" "$T/$_qswb" "$R" "$(_qswphys "$T")/$_qswb/w" || echo none-left) $(_qswt "$T") $(_qswwt "$R")" "pass met killed:gone t:[] wt:0"

# 2 and 3. A live run's tree. While run A holds in its checker its record
# names its row's own process, and a run B in the same TMPDIR and root leaves
# A's base, record and registration; released, A ends as it always has.
d="$QSWS/live-run"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"; _qswtab "$d/projb"
_qswhold "$d" "$T" "$R"
_qswcaller="$(cat "$d/a/caller" 2>/dev/null)"; _qswheldp="$(cat "$d/at" 2>/dev/null)"
_qswb="$(_qswbase "$T")"; _qswr=""
[ -n "$_qswb" ] && _qswr="$(readlink "$T/$_qswb/owner" 2>/dev/null)"
_qswp="${_qswr%% *}"
_qswwho="$(_qswrole "$_qswp" "$_qswheldp" "$_qswcaller")"
is  "while a row holds in its checker, owner in its base is a symlink reading <pid> <start> with one space between, and the pid is the row's own process: alive, an ancestor of the held checker, below the shell that called felix_qualify_run, and never that shell itself" \
    "owner:$([ -n "$_qswb" ] && [ -L "$T/$_qswb/owner" ] && echo link || echo none) shape:$(_qswshape "$_qswr") pid:$_qswwho alive:$(_qswalive "$_qswp")" \
    "owner:link shape:pid+start pid:row alive:yes"
_qswps="$([ "$_qswwho" = row ] && _qswstart "$_qswp")"
is  "and the start it records is that row process's start: where /proc names the pid namespace, field 22 of /proc/<pid>/stat, @ and that namespace; elsewhere ps -o lstart= under TZ=UTC0 and LC_ALL=C, every blank removed" \
    "start:$([ -n "$_qswps" ] && [ "${_qswr#* }" = "$_qswps" ] && echo same || echo "[${_qswr#* }] ps:[$_qswps] pid:$_qswwho")" "start:same"
_qswwas="$([ -n "$_qswb" ] && _qswsnap "$T/$_qswb" "$R" "$Tp/$_qswb/w")"
_qswrun "$d/b" "$T" "$R" "$d/projb"
_qswnow="$([ -n "$_qswb" ] && _qswsnap "$T/$_qswb" "$R" "$Tp/$_qswb/w")"
is  "while run A holds in its checker, a run B in the same TMPDIR and root leaves A's base as it was, its owner record and its registration with it, A's checker is still running, and B's own row reads pass and met" \
    "same:$([ "$_qswnow" = "$_qswwas" ] && echo yes || echo "no [$_qswwas] [$_qswnow]") owner:$([ -n "$_qswb" ] && [ -L "$T/$_qswb/owner" ] && echo link || echo none) registered:$([ -n "$_qswb" ] && _qswlisted "$R" "$Tp/$_qswb/w" || echo no) checker:$(_qswalive "$_qswheldp") b:$(_qswverd "$d/b")" \
    "same:yes owner:link registered:yes checker:yes b:pass met"
: > "$d/release"
_qswfinish "$_qswa" "$d/a"
is  "released, run A ends with its row read pass and met, and neither run leaves a base in the TMPDIR or a worktree registered beside the root" \
    "$(_qswverd "$d/a") held-here:$([ -n "$_qswb" ] && echo yes || echo no) $(_qswt "$T") $(_qswwt "$R")" "pass met held-here:yes t:[] wt:0"
is  "every git worktree add either run made found owner already a symlink in the base it added the tree to" \
    "$(cat "$d/a/git" "$d/b/git" 2>/dev/null | awk '/ worktree add / { n++; if ($0 ~ / owner:no$/) m++ } END { printf "adds:%s without:%d", (n > 0 ? "some" : "none"), m + 0 }')" \
    "adds:some without:0"

_qualify_sweep_cleanup
