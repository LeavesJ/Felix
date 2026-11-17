printf '\nFelix refuses a pattern kill (blind)\n'
# Written blind, on 2026-10-19, from the contract alone (audits/2026-10-19-
# pattern-kill-deny/contract.md, C1 to C5; the founder decided it that day), before
# the row existed and without reading the pattern of any row in any deny.tsv. The
# decision: every session and subagent gets an immediate refusal for a pattern
# kill, with the reason and the one allowed way. Twice, on 2026-09-25 and
# 2026-10-18, an agent killed by pattern although its prompt forbade it, and the
# pattern reached other sessions' runs on the same machine.
#
# The row is read out of projects/felix/deny.tsv as it ships, by its reason (C5:
# it begins `a pattern kill`, and exactly one row there does), and put alone into
# a fixture project's deny.tsv, so each verdict below is the shipped row's and not
# a copy of it. It keeps all its columns: the contract gives it no checkout scope,
# and a fourth column is asserted absent below, not dropped here.
#
# Each case is a command as the shell would be handed it, one a line, with <NL> for
# a line break; the payload is that command as the hook receives it, escaped as JSON
# escapes it (a quote, a backslash, a line break). The assertion's name is the
# command: `pattern kill refused: <command>` or `pattern kill allowed: <command>`.
# Every name is emitted on every run, whatever the hook answered. A refused case
# wants exit 2 and the row's whole reason on stderr; an allowed case wants exit 0.
#
# Amended the same day, still blind, after the contract's last section ("Amended
# 2026-10-19, after the corpus check", binding over C1 to C3). The row's first
# draft refused 186 of the 4705 distinct commands naming kill in the machine's
# transcripts; about 155 were real pattern kills, and the rest were `pkill -P
# <pid>` (the children of a pid the session holds, the reason's own "then its tree
# by pid"), one `pgrep -P "$P" | xargs kill`, and three `kill -0` loops. So:
# A1: pkill is refused unless it carries a pid-bound selector, `-P <ppid>` or
#     `-F <pidfile>` (`-P123`, `-P "$p"` and `-P $p` alike); `-P 1` is not
#     pid-bound, as pid 1 parents every orphan; killall is always refused.
# A2: `kill $(pgrep ...)` and `pgrep ... | xargs kill` are refused unless that
#     pgrep carries a pid-bound selector, under the same rule.
# A3: `kill -0` sends no signal, so `kill -0 $(pgrep -f x)` is allowed.
# The amendment's own examples are cases here, allowed and refused. `pkill -P 1234`,
# which the first version of this part refused, is allowed now.
#
# Amended again the same day ("Amended again 2026-10-19, after the adversarial
# round", binding over everything above), after a reviewer found pattern kills the
# row let through and allowed commands it refused:
# A4: a quoted pattern is one word, so `pkill -f 'vite|esbuild'` is refused.
# A5: pids taken from an unbound pgrep and then killed are a pattern kill, whatever
#     carries them: a variable, a for loop (parentheses or backquotes), a while
#     read loop, a process substitution into xargs or read, `kill -9 -$(...)`, a
#     script handed to `bash -c`.
# A6: a pid-bound selector whose pid comes from a pattern is not pid-bound
#     (`pkill -P $(pgrep -f x)`), nor is a -P list that holds 1 (`"$pid,1"`).
# A7: more positions (after a case pattern's `)`, behind a redirect, after find's
#     -exec, blanks or a line break or sudo inside the substitution) and wrappers
#     (watch, caffeinate -i, stdbuf -oL, arch -arm64, setsid, ionice -c3, builtin,
#     sudo -iu me, env -C /tmp).
# A8: allowed, as none sends a signal to a pattern's pids: `kill -s 0 $(pgrep ...)`,
#     `pgrep ... | xargs kill -0`, `PKILL=/usr/bin/pkill`, `echo then killall the
#     rest`, a pgrep counted by wc after a kill by pid, and a pid-bound pgrep killed.
# Every example the amendment lists is a case here. Its known limits (a pgrep
# substitution that is not the last body appended, a check ending a command that
# killed by pid, quoted sed/cp/rm/touch operands holding `; pkill`, remote
# commands, combined flags like -fP, `pkill --help`, a nested substitution, a
# double-quoted `bash -c "...$(...)"`, `echo 'pkill -f x' | bash`, `env -S`,
# `$(which pkill)`, pids passed through a file) are asserted neither way; no case
# here is one of them, and the cases of the wc count end in a count, not a bare
# `"$(pgrep -fl x)"`.
#
# Readings, where the contract leaves room. The wrappers of C1 and the positions of
# C1 are tried on pkill and killall; C2 is tried bare, behind `true &&`, and with
# the substitution double-quoted, which still runs it. `kill $(cat pidfile)` and
# `kill $(jobs -p)` are allowed, as the contract's last section says. What the
# reason must say is asserted by plain words only: `session` for the harm, `pid` for
# the way, and `$!` or `pidfile` for where the pid comes from; the wording of the
# rest (STOP then KILL the root, then its tree by pid) is the row's. Mine, along
# the lines of A1 to A3 and not in its text: pgrep takes `-F` as pkill does ("the
# same rule"); a command with a pid-bound selector and a pattern both
# (`pkill -P 1234 -f x`) carries the selector and is allowed, and `-P 1` among
# other options is refused wherever it stands, glued or not, while a ppid that
# merely begins with 1 (10, 11) is allowed; `-P 1234` inside a quoted pattern is
# the pattern, not a selector, and `-f run.pid` is a pattern, not `-F`; each pgrep
# in a command is judged by itself (`kill $(pgrep -P 1234) $(pgrep -f x)` is
# refused); a pgrep piped through head into `xargs kill` is judged as the pgrep is;
# and `kill -0` frees only itself, so a `kill -9 $(pgrep -f x)` beside it is still
# refused. For A4 to A8, mine: a `;`, `&&`, `||`, `&` or `(` inside a quoted
# pattern does not end the command; a quoted alternation beside a real `-P 1234` is
# allowed, as is text that holds alternations of kill words (`grep -E
# 'pkill|killall'`); the `;` and line-break spellings of A5's variable form, and
# `sh -c`, `sudo bash -c` and `xargs -I{}` are refused as their listed twins are;
# a loop, a read loop or a process substitution fed by a pid-bound pgrep, and one
# that only echoes an unbound pgrep's pids or tests them with `kill -0`, is
# allowed; a -P list is refused wherever its 1 stands (first, last, glued, behind a
# variable) and allowed when it holds other ppids, 10 and 11 among them; `env -i`,
# `nohup setsid`, `sudo caffeinate -i`, `sudo kill`, an `env A=1 pgrep` inside the
# substitution, a backquote with blanks, and a case arm after another arm are
# A7's positions and wrappers too, while the same words after echo, find's -name,
# or in front of another command (watch pgrep, caffeinate sleep, sudo -iu me ls) are
# allowed; `then`, `else`, `do`, `time` and `!` after echo are words, and
# `KILLALL=` and `export PKILL=` are assignments, as `PKILL=` is.
#
# Every part runs alone: this one makes its own checkout, bound to the widget
# project by marker, and relies on nothing an earlier part left but what the
# prelude builds (FROOT, TMP, REAL_HARNESS, _pre, _fx_cd, is, has, skip).

# ---- the row, found by its reason
_pk_tab="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/deny.tsv"
_pk_row=""; _pk_n=0
if [ -f "$_pk_tab" ]; then
  _pk_row="$(LC_ALL=C awk -F'\t' '/^#/ { next } index($3, "a pattern kill") == 1' "$_pk_tab")"
  _pk_n="$(LC_ALL=C awk -F'\t' '/^#/ { next } index($3, "a pattern kill") == 1 { n++ } END { print n + 0 }' "$_pk_tab")"
fi
# A field of the first such row, or its field count: _pk_f 1, _pk_f 3, _pk_f NF.
_pk_f() { printf '%s\n' "$_pk_row" | LC_ALL=C awk -F'\t' -v k="$1" 'NR == 1 { print (k == "NF" ? NF : $k) }'; }
_pk_tool="$(_pk_f 1)"; _pk_nf="$(_pk_f NF)"; _pk_reason="$(_pk_f 3)"
_pk_tabs="$(printf '%s' "$_pk_row" | LC_ALL=C tr -cd '\t' | wc -c | tr -d ' ')"
_pk_len="$(printf '%s' "$_pk_reason" | wc -c | tr -d ' ')"
_pk_odd="$(printf '%s' "$_pk_reason" | LC_ALL=C tr -d ' -~' | wc -c | tr -d ' ')"
_pk_low="$(printf '%s' "$_pk_reason" | LC_ALL=C tr '[:upper:]' '[:lower:]')"

# One assertion about the row, or a skip, with the same name either way.
_pk_row_is() {   # name got want
  if [ -f "$_pk_tab" ]; then is "$1" "$2" "$3"
  else skip "$1" "no projects/felix/deny.tsv beside this harness"; fi
}
_pk_row_is "pattern kill row: exactly one row in projects/felix/deny.tsv has a reason beginning a pattern kill" "$_pk_n" "1"
_pk_row_is "pattern kill row: it is a Bash row" "$_pk_tool" "Bash"
_pk_row_is "pattern kill row: it has three columns, so no checkout scope" "$_pk_nf" "3"
_pk_row_is "pattern kill row: it holds two tabs, so the reason holds none" "$_pk_tabs" "2"
if [ "$_pk_len" -gt 0 ] && [ "$_pk_odd" -eq 0 ]; then _pk_v="printable ASCII"
else _pk_v="$_pk_odd of $_pk_len bytes are not printable ASCII"; fi
_pk_row_is "pattern kill row: the reason is printable ASCII" "$_pk_v" "printable ASCII"
if [ "$_pk_len" -gt 0 ] && [ "$_pk_len" -lt 200 ]; then _pk_v="under 200 bytes"
else _pk_v="$_pk_len bytes"; fi
_pk_row_is "pattern kill row: the reason is under 200 bytes" "$_pk_v" "under 200 bytes"
case "$_pk_low" in *session*) _pk_v="names sessions" ;; *) _pk_v="[$_pk_reason] does not name sessions" ;; esac
_pk_row_is "pattern kill row: the reason names the harm, other sessions" "$_pk_v" "names sessions"
case "$_pk_low" in *pid*) _pk_v="names the pid" ;; *) _pk_v="[$_pk_reason] does not name the pid" ;; esac
_pk_row_is "pattern kill row: the reason names the way, a pid" "$_pk_v" "names the pid"
case "$_pk_low" in
  *'$!'*|*pidfile*|*'pid file'*) _pk_v="says where the pid comes from" ;;
  *) _pk_v="[$_pk_reason] does not say where the pid comes from" ;;
esac
_pk_row_is "pattern kill row: the reason says the pid comes from \$! or a pidfile" "$_pk_v" "says where the pid comes from"

# ---- the fixture: the row alone in the widget project's table, in a checkout of its own
mkdir -p "$FROOT/projects/widget"
if [ -n "$_pk_row" ]; then printf '%s\n' "$_pk_row" > "$FROOT/projects/widget/deny.tsv"
else : > "$FROOT/projects/widget/deny.tsv"; fi
_pk_repo="$TMP/pattern-kill-repo"
mkdir -p "$_pk_repo"
( _fx_cd "$_pk_repo" && git init -q -b main )
_pk_repo="$(cd "$_pk_repo" && pwd -P)"
printf 'widget\n' > "$_pk_repo/.felix"

# The payload the hook receives for a command: <NL> is a line break, and a quote and
# a backslash are escaped as JSON escapes them.
_pk_json() {
  printf '%s' "$1" | LC_ALL=C awk '
    function esc(s,   i, c, o) {
      o = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") o = o "\\\\"
        else if (c == "\"") o = o "\\\""
        else o = o c
      }
      return o
    }
    { o = esc($0)
      while ((p = index(o, "<NL>")) > 0) o = substr(o, 1, p - 1) "\\n" substr(o, p + 4)
      printf "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"%s\"}}", o }'
}
# _pk_cases 2 (refused) or 0 (allowed); stdin is the commands, one a line.
_pk_cases() {
  local want="$1" word _c _j _rc _got
  if [ "$want" = 2 ]; then word=refused; else word=allowed; fi
  while IFS= read -r _c; do
    [ -n "$_c" ] || continue
    if [ ! -f "$_pk_tab" ]; then
      skip "pattern kill $word: $_c" "no projects/felix/deny.tsv beside this harness"; continue
    fi
    _j="$(_pk_json "$_c")"
    ( cd "$_pk_repo" && _pre "$_j" ); _rc=$?
    _got="$_rc"
    if [ "$_rc" = 2 ]; then
      case "$(cat "$FROOT/.deny-err")" in *"$_pk_reason"*) ;; *) _got="2 without the row's reason" ;; esac
    fi
    is "pattern kill $word: $_c" "$_got" "$want"
  done
}

printf '\npattern kill: pkill and killall are refused, with their options and paths\n'
_pk_cases 2 <<'J'
pkill -f 'engine/harness/tests/run'
pkill -f 'sleep 3'
pkill node
pkill -9 -x python
pkill -u 501 node
pkill -TERM -f "next dev"
killall node
killall -9 Safari
killall -q -s TERM sleep
/usr/bin/pkill -f x
/opt/homebrew/bin/pkill -f x
./tools/pkill -f x
/usr/bin/killall node
/usr/local/bin/killall -9 Dock
J

printf '\npattern kill: and behind a wrapper\n'
_pk_cases 2 <<'J'
sudo pkill -f x
sudo killall node
env A=1 pkill -f x
env A=1 B=2 killall node
nohup pkill -f x
command pkill -f x
exec pkill -f x
nice -n 5 pkill -f x
nice pkill -f x
timeout 5 pkill -f x
echo node | xargs pkill
printf 'a\nb\n' | xargs -n 1 killall
sudo nohup pkill -f x
J

printf '\npattern kill: and wherever a command can start\n'
_pk_cases 2 <<'J'
ls; pkill -f x
ls;pkill -f x
true && pkill -f x
false || pkill -f x
echo x | pkill -f y
sleep 1 & pkill -f x
(pkill -f x)
echo $(pkill -f x)
echo "$(pkill -f x)"
echo `pkill -f x`
{ pkill -f x; }
echo hi<NL>pkill -f x
if true; then pkill -f x; fi
for i in 1 2; do pkill -f x; done
if false; then :; else pkill -f x; fi
! pkill -f x
time pkill -f x
J

printf '\npattern kill: a kill fed by a pattern search is refused\n'
_pk_cases 2 <<'J'
kill $(pgrep -f x)
kill `pgrep x`
kill -9 $(pgrep -f 'a b')
kill -TERM $(pgrep -d' ' x)
kill -9 "$(pgrep -f x)"
true && kill $(pgrep -f x)
pgrep -f x | xargs kill
pgrep x | xargs -r kill -9
pgrep -f x | xargs -n 1 kill
pgrep -f 'a b' | xargs -r -n1 kill -TERM
J

printf '\npattern kill: a kill of a pid you hold is allowed, and so is looking\n'
_pk_cases 0 <<'J'
kill 1234
kill -STOP 1234; kill -KILL 1234
kill -0 "$pid"
kill -TERM "$(cat run.pid)"
kill $!
kill -- -1234
kill %1
kill -l
kill $(cat pidfile)
kill $(jobs -p)
sleep 30 & kill $!
pgrep -fl tests/run
pgrep -P 1234
ps -axo pid,command | grep tests/run
p=$(pgrep -f x); echo "$p"
pgrep -f x | wc -l
pgrep -f x | xargs ps -o pid,command -p
J

printf '\npattern kill (A1): pkill bound to a pid or a pidfile you hold is allowed\n'
_pk_cases 0 <<'J'
pkill -P 1234
pkill -P1234
pkill -P "$pid"
pkill -P $p
pkill -P$p
pkill -TERM -P "$pid"
pkill -9 -P $p
pkill -TERM -P 80490; kill -TERM 80490
pkill -P 10
pkill -P 11 -f x
pkill -P 1234 -f x
pkill -f x -P 1234
pkill -F run.pid
pkill -F "$pidfile"
pkill -F/tmp/run.pid
pkill -9 -F /tmp/run.pid
pkill -TERM -F "$TMP/run.pid"
sudo pkill -P 1234
true && pkill -P 1234
timeout 5 pkill -TERM -P "$pid"
J

printf '\npattern kill (A1): and without one, or bound to pid 1, it is still refused\n'
_pk_cases 2 <<'J'
pkill -P 1 -f x
pkill -f x -u me
pkill -9 x
pkill -9 -P 1
pkill -P1 -f x
pkill -f x -P 1
pkill -TERM -P 1 node
pkill -f 'worker -P 1234'
pkill -f run.pid
killall -P 1234 node
J

printf '\npattern kill (A2): a kill fed by a search bound to a pid you hold is allowed\n'
_pk_cases 0 <<'J'
pgrep -P "$P" | xargs kill
kill $(pgrep -P 1234)
kill -9 $(pgrep -P $p)
kill `pgrep -P 1234`
kill -TERM $(pgrep -f x -P 1234)
pgrep -P1234 | xargs -r kill -9
pgrep -P 1234 | head -5 | xargs kill
pgrep -f x -P 1234 | xargs kill
kill $(pgrep -F run.pid)
pgrep -F run.pid | xargs kill
J

printf '\npattern kill (A2): and a search bound to nothing, or to pid 1, is still refused\n'
_pk_cases 2 <<'J'
pgrep -P 1 -f x | xargs kill
pgrep -P1 -f x | xargs -r kill -9
kill $(pgrep -P 1 -f x)
kill -9 $(pgrep -f x -P 1)
pgrep -f x | head -5 | xargs kill
kill $(pgrep -f 'a -P 1234')
kill $(pgrep -P 1234) $(pgrep -f x)
J

printf '\npattern kill (A3): kill -0 sends no signal, so it is allowed\n'
_pk_cases 0 <<'J'
kill -0 $(pgrep -f x)
until ! kill -0 $(pgrep -f x); do sleep 5; done
kill -0 $(pgrep x)
kill -0 "$(pgrep -f x)"
kill -0 `pgrep -f x`
kill -0 $(pgrep -f x) && echo alive
! kill -0 $(pgrep -f x)
while kill -0 $(pgrep -f 'a b') 2>/dev/null; do sleep 1; done
if kill -0 $(pgrep -f x); then echo up; fi
J

printf '\npattern kill (A3): and a kill beside it that does send one is still refused\n'
_pk_cases 2 <<'J'
kill -0 $(pgrep -f x); kill -9 $(pgrep -f x)
until ! kill -0 $(pgrep -f x); do kill -9 $(pgrep -f x); done
J

printf '\npattern kill (A4): a quoted pattern is one word, and is still a pattern\n'
_pk_cases 2 <<'J'
pkill -f 'vite|esbuild'
pkill -9 -f "uvicorn|gunicorn"
kill -9 $(pgrep -f "tests/(run|red)")
pgrep -f 'a|b' | xargs kill
pkill -f 'a b|c d'
pkill -x 'node|npm'
pkill -f 'foo(bar|baz)'
pkill -f "x;y"
pkill -f 'a && b'
pkill -f 'a & b'
pkill -f 'x|-P 1234'
kill $(pgrep -f 'x || y')
pgrep -f "a||b" | xargs -r kill -9
pgrep -f 'one;two' | xargs kill
killall 'a|b'
J

printf '\npattern kill (A4): and text, or a pid-bound search, with a quoted alternation is allowed\n'
_pk_cases 0 <<'J'
pkill -P 1234 -f 'vite|esbuild'
kill $(pgrep -P 1234 -f 'a|b')
grep -E 'pkill|killall' lib/x.sh
grep -nE "vite|pkill" notes.md
echo "pkill|killall"
git log --grep='pkill\|killall'
J

printf '\npattern kill (A5): pids taken from an unbound pgrep and then killed, whatever carries them\n'
_pk_cases 2 <<'J'
PID=$(pgrep -f x) && kill -9 $PID
PID=$(pgrep -f x); kill -9 $PID
pids=$(pgrep -f x)<NL>kill $pids
for p in $(pgrep -f x); do kill $p; done
for p in `pgrep -f x`; do kill $p; done
for p in $(pgrep -f 'a b'); do kill -9 "$p"; done
for p in `pgrep x`; do echo $p; kill -TERM $p; done
pgrep -f x | while read p; do kill $p; done
pgrep -f x | while read -r p; do kill $p; done
pgrep -f x | while read p; do echo "$p"; kill $p; done
pgrep -f x | while read -r p; do echo "$p"; ps -p $p; kill -9 $p; done
while read p; do kill $p; done < <(pgrep -f x)
while read -r p; do echo $p; kill -9 $p; done < <(pgrep -f x)
xargs kill < <(pgrep -f x)
xargs -r kill -9 < <(pgrep -f x)
kill -9 -$(pgrep -f x)
kill -- -$(pgrep -f 'a b')
timeout 10 bash -c 'kill $(pgrep -f x)'
bash -c 'kill $(pgrep -f x)'
sh -c 'pgrep -f x | xargs kill'
sudo bash -c 'pkill -f x'
pgrep -f x | xargs -I{} kill -9 {}
J

printf '\npattern kill (A5): and the same with a search bound to a pid, or with no signal sent, is allowed\n'
_pk_cases 0 <<'J'
PID=$(pgrep -P 1234) && kill -9 $PID
for p in $(pgrep -P 1234); do kill $p; done
pgrep -P 1234 | while read p; do kill $p; done
while read p; do kill $p; done < <(pgrep -P 1234)
xargs kill < <(pgrep -P 1234)
for p in $(pgrep -f x); do echo $p; done
pgrep -f x | while read -r p; do ps -p $p; done
while read p; do ps -p $p; done < <(pgrep -f x)
for p in $(pgrep -f x); do kill -0 $p && echo up; done
J

printf '\npattern kill (A6): a pid-bound selector whose pid comes from a pattern, or a list holding 1, is not bound\n'
_pk_cases 2 <<'J'
pkill -P $(pgrep -f tests/run)
pkill -P "$pid,1" -f x
pkill -P 1234,1 -f x
pkill -P 1,1234 -f x
pkill -P "1,$pid" -f x
pkill -P1,2 -f x
pkill -P 1,2
pkill -TERM -P $(pgrep -f x)
pkill -P `pgrep -f x`
pkill -P "$(pgrep -f x)"
J

printf '\npattern kill (A6): and a list of other ppids is bound\n'
_pk_cases 0 <<'J'
pkill -P 1234,5678
pkill -P 10,11
pkill -P "$a,$b"
J

printf '\npattern kill (A7): more positions are refused\n'
_pk_cases 2 <<'J'
case "$1" in stop) pkill -f server;; esac
case "$1" in start) ./run;; stop) killall server;; esac
case $x in a|b) pkill -f x ;; *) : ;; esac
2>/dev/null pkill -f x
>/dev/null 2>&1 pkill -f x
2>&1 killall node
find /tmp -name x -exec pkill -f {} \;
find . -name y -exec killall -9 node \;
kill $( pgrep -f x )
kill $(<NL>pgrep -f x<NL>)
kill ` pgrep -f x `
kill $(sudo pgrep -f x)
kill -9 $( sudo pgrep -f x )
kill $(env A=1 pgrep -f x)
sudo kill -9 $(pgrep -f x)
J

printf '\npattern kill (A7): and so are more wrappers\n'
_pk_cases 2 <<'J'
watch pkill -f x
caffeinate -i pkill -f x
stdbuf -oL pkill -f x
arch -arm64 pkill -f x
setsid pkill -f x
ionice -c3 pkill -f x
builtin pkill -f x
sudo -iu me pkill -f x
env -C /tmp pkill -f x
env -i pkill -f x
nohup setsid pkill -f x
sudo caffeinate -i killall node
J

printf '\npattern kill (A7): and the same words round something else are allowed\n'
_pk_cases 0 <<'J'
case "$1" in stop) echo pkill -f server;; esac
2>/dev/null echo killall
find /tmp -name pkill -print
find . -name 'killall*' -exec ls {} \;
watch -n 5 pgrep -fl x
caffeinate -i sleep 5
sudo -iu me ls
env -C /tmp ls pkill-notes
kill $( pgrep -P 1234 )
kill $(sudo pgrep -P 1234)
J

printf '\npattern kill (A8): none of these sends a signal to a pattern'"'"'s pids, so all are allowed\n'
_pk_cases 0 <<'J'
kill -s 0 $(pgrep -f x)
kill -s 0 "$(pgrep -f 'a b')"
pgrep -f x | xargs kill -0
pgrep -f x | xargs -r kill -s 0
pgrep -f x | xargs -n 1 kill -0
PKILL=/usr/bin/pkill
KILLALL=/usr/bin/killall
export PKILL=/usr/bin/pkill
echo then killall the rest
echo else pkill it
echo do pkill -f x
echo time killall node
echo ! pkill -f x
kill -STOP $root; kill -KILL $root; echo "left: $(pgrep -f tests/run | wc -l)"
kill -TERM 1234; echo "left: $(pgrep -f x | wc -l)"
kill 1234; pgrep -fl x | wc -l
kill $pid && echo "$(pgrep -f x | wc -l) left"
n=$(pgrep -f x | wc -l); kill -9 "$root"; echo $n
p=$(pgrep -P $pid); kill $p
J

printf '\npattern kill: text that names a pattern kill is allowed\n'
_pk_cases 0 <<'J'
git commit -m "never pkill -f"
echo 'no killall'
echo pkill
echo hi; echo pkill -f x
grep -n pkill lib/x.sh
printf '%s\n' "pkill"
ps -axo pid,command | grep pkill
sed -n '/killall/p' notes.md
git log --grep=killall
man pkill
which killall
# pkill -f x
ls # pkill -f x
git commit -m "title<NL><NL>pkill -f is refused now<NL>killall too"
echo "first<NL>pkill -f x"
for c in 'pkill -f x' 'ls'; do echo "$c"; done
J

printf '\npattern kill: a here-document, and a commit message, that names one is data\n'
_pk_cases 0 <<'J'
git commit -m "$(cat <<'EOF'<NL>fix: never pkill -f here<NL>EOF<NL>)"
git commit -m "$(cat <<'EOF'<NL>docs: kill by pid, not killall<NL><NL>pkill -f reaches other sessions<NL>EOF<NL>)"
git commit -F - <<'EOF'<NL>never pkill -f<NL>EOF
cat <<'EOF'<NL>killall node<NL>EOF
cat > notes.md <<'EOF'<NL>pkill -f x<NL>EOF
cat > notes.md <<'EOF'<NL>use:<NL>pkill -f x<NL>killall node<NL>EOF<NL>ls
J

printf '\npattern kill: words that merely contain the letters are allowed\n'
_pk_cases 0 <<'J'
mypkill --run
pkiller x
/usr/bin/mypkill -f x
./pkill-notes/run.sh
cat killall_report.txt
cat docs/killall.md
ls pkill-notes/
J

rm -f "$FROOT/projects/widget/deny.tsv" "$FROOT/.deny-err"
