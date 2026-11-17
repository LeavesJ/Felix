printf '\ncommissioning: a check says it could not be asked by exiting 2\n'
# Written blind from the contract, 2026-10-08, before the engine change and
# without reading one. A check that exits 2 could not ask its question here,
# and reads unknown, which makes the receipt indeterminate, where until now it
# read held, a person's queue. 2 is the Unix "could not answer" (grep, test,
# diff, cmp), the `when` column already reads it so, and the lookups the
# seeded checks call already return it for "could not be read". A real run
# still runs the felix answer of a row whose check exited 2, because the
# answer can be what makes the question askable (discover --adopt fills the
# cache the discover check reads), and those rows read held and ran before:
# what runs does not change, only what is reported. Every other unknown still
# runs nothing, held rows still run, and a death (a status of 128 or more, or
# a substitution that never reached its end) stays held.
#
# The checks the status and run cases ask are this block's own. The reach and
# discover rows come from one variable, picked by need name and never by
# their check text, so the block can be pointed at a governed project's table
# (CMU_TABLE). Grounds and `when` are asked as `-`, as in the block above, so
# the check is always reached. Stubs are defined after the libraries are
# sourced, inside _cm, so they override the engine's own and go with it.
#
# Red on origin/main wherever a status of 2 decides. The real-engine reach
# case stays red until claude/declared-unread-readers lands as well: on main
# felix_toolbox_unwired prints nothing and returns 0 over a capabilities list
# it could not read, so that row reads done.
_cmstub_build
_cutab="${CMU_TABLE:-$FROOT/harness/templates/commissioning.tsv}"
_cudir="$TMP/cu-work"; _cup="$TMP/cu-proj"; _cur="$TMP/cu-root"
mkdir -p "$_cudir/home" "$_cup" "$_cur"
# The row of the table under test whose need is $1, or nothing.
_curow() { grep -vE '^[[:space:]]*(#|$)' "$_cutab" 2>/dev/null | awk -F'\t' -v n="$1" '$1 == n && !s { print; s = 1 }'; }
# The same row as a run is given it here: grounds and `when` as `-`.
_curowrun() { _curow "$1" | awk -F'\t' 'BEGIN { OFS = "\t" } { $2 = "-"; $4 = "-"; print }'; }
# name|got|want, with got on one line and free of the separator.
_cuemit() { printf '%s|%s|%s\n' "$1" "$(printf '%s' "$2" | tr '|\n\t' '/  ')" "$3"; }
# The needle when the text holds it, else the text, so a miss shows what came.
_cuhas() { case "$1" in *"$2"*) printf '%s' "$2" ;; *) printf '%s' "$1" ;; esac; }
# As many leading characters of the text as the prefix has.
_cuhead() { printf '%s' "${1:0:${#2}}"; }
_cutable() { { printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\n'
               for _cux in "$@"; do printf '%s\n' "$_cux"; done; } > "$_cup/commissioning.tsv"; }
# Column $3 of the run line whose need is $2.
_cufield() { printf '%s\n' "$1" | awk -F'\t' -v n="$2" -v c="$3" '$1 == n && !s { print $c; s = 1 }'; }
# Every answer the runner was called with, in order, space separated.
_curan() { awk '{ printf "%s%s", (NR > 1 ? " " : ""), $0 }' "$_cudir/ran" 2>/dev/null; }
_cureset() { rm -f "$_cudir/ran" "$_cudir/next" "$_cudir/cache-made"; _cunext=; _cumake=; }
# The runner felix_commission_run is handed: it records the answer, writes the
# status the next ask of a C2 check returns, and makes the stubbed discovery
# cache current, each only when told to.
_curunner() {
  printf '%s\n' "$1" >> "$_cudir/ran"
  [ -z "${_cunext:-}" ] || printf '%s\n' "$_cunext" > "$_cudir/next"
  [ "${_cumake:-}" != 1 ] || : > "$_cudir/cache-made"
  return 0
}
# need instrument answer check on|off -> state <TAB> detail
_custate() {
  ( if [ "$5" = on ]; then set -o pipefail; else set +o pipefail; fi
    felix_commission_state "$_cup" "$_cur" "$1" - "$2" - "$3" "$4" </dev/null ) | cut -f1,2
}
_cuboth() { printf 'on=%s off=%s' "$(_custate "$@" on | cut -f1)" "$(_custate "$@" off | cut -f1)"; }
# runner need: runs the table in $_cup and keeps that need's state, class, detail.
_curun() {
  _cuout="$(felix_commission_run "$_cup" "$_cur" "$1" </dev/null)"
  _cust="$(_cufield "$_cuout" "$2" 2)"; _cucls="$(_cufield "$_cuout" "$2" 3)"; _cudet="$(_cufield "$_cuout" "$2" 6)"
}
# The engine functions a check names that are not among the rest of the arguments.
_cuunstubbed() {
  local c="$1" w miss=""; shift
  for w in $(printf '%s' "$c" | grep -oE '(felix_[a-z_]+|cmd_[a-z_]+)' | LC_ALL=C sort -u); do
    case " $* " in *" $w "*) ;; *) miss="$miss $w" ;; esac
  done
  printf '%s' "${miss# }"
}
# A check evaluated as the engine evaluates it, with descriptors to spare and
# with none (ulimit -n 3), so no substitution can make its pipe.
_cunopipe() {
  local free=passes nopipe=passes
  ( cd "$_cur" || exit 126; set +o pipefail; eval "$1" ) </dev/null >/dev/null 2>&1 || free=fails
  ( ulimit -n 3; cd "$_cur" || exit 126; set +o pipefail; eval "$1" ) </dev/null >/dev/null 2>&1 || nopipe=fails
  printf 'free=%s nopipe=%s' "$free" "$nopipe"
}
_cuc1() { _cuemit "$3 (pipefail on and off)" "$(_cuboth cu_status - - "$1")" "on=$2 off=$2"; }

# Runs inside _cm. Prints name|got|want lines, and cu-end when it reached its end.
_cuall() {
  local row need grounds instrument when answer check step flag
  export FELIX_PROJECT="$_cup" FELIX_PROJECT_NAME=cu-proj FELIX_ROOT_DIR="$_cur" FELIX_MEMORY_DIR="$_cudir/mem"
  felix_toolbox_unwired() {
    printf '%b' "${_cuuwout:-}"
    [ "${_cuuwhow:-}" != exit ] || exit "${_cuuwrc:-0}"
    return "${_cuuwrc:-0}"
  }
  felix_discover_cache_current() {
    case "${_cucc:-0}" in
      die)  exit 128 ;;
      flag) [ -f "$_cudir/cache-made" ]; return ;;
    esac
    return "${_cucc:-0}"
  }
  felix_discover_adopt() {
    printf '%b' "${_cuadout:-}"
    [ "${_cuadhow:-}" != exit ] || exit "${_cuadrc:-0}"
    return "${_cuadrc:-0}"
  }

  # C1. What a reached check's status means, asked through felix_commission_state.
  _cuc1 'exit 0'                              done    'a check that exits 0 reads done'
  _cuc1 'exit 2'                              unknown 'a check that exits 2 reads unknown, not held'
  _cuc1 'test -e /no/such/cu-path || exit 2'  unknown 'a check text that ends by exiting 2 reads unknown'
  _cuc1 'grep -q x /no/such/cu-file'          unknown 'a check whose last command, grep over a missing file, returns 2 and reads unknown'
  _cuc1 'exit 126'                            unknown 'a check that exits 126 still reads unknown'
  _cuc1 'exit 127'                            unknown 'a check that exits 127 still reads unknown'
  _cuc1 'exit 1'                              held    'a check that exits 1 still reads held'
  _cuc1 'exit 3'                              held    'a check that exits 3 reads held, not unknown'
  _cuc1 'exit 125'                            held    'a check that exits 125 reads held'
  _cuc1 'exit 128'                            held    'a check that exits 128 reads held, a death and not could-not-ask'
  _cuc1 'exit 130'                            held    'a check that exits 130 reads held'
  _cuemit "a check that exits 0 is reported as passing" \
    "$(_custate cu_status - - 'exit 0' on | cut -f2)" "the check passes"
  _cuemit "a check that exits 2 is reported as one that could not be asked" \
    "$(_cuhas "$(_custate cu_status - - 'exit 2' on | cut -f2)" 'could not be asked')" "could not be asked"
  _cuemit "a check whose grep returns 2 is reported as one that could not be asked" \
    "$(_cuhas "$(_custate cu_status - - 'grep -q x /no/such/cu-file' off | cut -f2)" 'could not be asked')" "could not be asked"
  _cuemit "a check that exits 126 is still reported as a checkout that could not be entered" \
    "$(_cuhas "$(_custate cu_status - - 'exit 126' on | cut -f2)" 'the checkout could not be entered')" "the checkout could not be entered"
  _cuemit "a check that exits 127 is still reported as a command that does not exist here" \
    "$(_cuhas "$(_custate cu_status - - 'exit 127' on | cut -f2)" 'a command in the check does not exist here')" \
    "a command in the check does not exist here"
  _cuemit "a check that exits 3 is reported as not passing" \
    "$(_custate cu_status - - 'exit 3' on | cut -f2)" "the check does not pass"
  _cuemit "the class of an unknown row is UNKNOWN" "$(felix_commission_class unknown)" "UNKNOWN"

  # C2. A real run. The check exits 2 until the runner writes the status its
  # next ask returns.
  flag="if test -f '$_cudir/next'; then read -r _cunread < '$_cudir/next'; exit \"\$_cunread\"; fi; exit 2"
  _cutable "cu_later	-	-	-	felix:toolbox --route	$flag	5"
  _cureset; _cunext=0; _curun _curunner cu_later
  _cuemit "a felix row whose check exited 2 has its answer run once in a real run" "$(_curan)" "felix:toolbox --route"
  _cuemit "a felix row whose check exited 2 reads done once its answer makes the check pass" "$_cust" "done"
  _cuemit "a felix row whose check exited 2 reports the answer that ran and its exit first in its detail" \
    "$(_cuhead "$_cudet" 'ran toolbox --route (exit 0); ')" 'ran toolbox --route (exit 0); '
  _cureset; _cunext=2; _curun _curunner cu_later
  _cuemit "a felix row whose check still exits 2 after its answer reads unknown" "$_cust" "unknown"
  _cuemit "a felix row whose check still exits 2 after its answer still reports the answer that ran" \
    "$(_cuhead "$_cudet" 'ran toolbox --route (exit 0); ')" 'ran toolbox --route (exit 0); '
  _cureset; _cunext=1; _curun _curunner cu_later
  _cuemit "a felix row whose check exited 2 and then exits 1 after its answer reads held" "$_cust" "held"
  _cutable "cu_person	-	-	-	-	exit 2	5"
  _cureset; _curun _curunner cu_person
  _cuemit "a person's row whose check exits 2 reads unknown and nothing is run for it" "$_cust ran=[$(_curan)]" "unknown ran=[]"
  _cutable "cu_status	-	-	-	felix:toolbox --route	exit 2	5"
  _cureset; _curun - cu_status
  _cuemit "with no runner, as --status and the gate ask, a check exiting 2 reads unknown" "$_cust" "unknown"
  _cuemit "a row whose check exits 2 is classed UNKNOWN, never OBSERVED" "$_cucls" "UNKNOWN"
  # Unknown for any other reason: the check would exit 2 if it were reached,
  # and still nothing runs.
  _cutable "cu_noinst	-	cu-no-such-instrument-xyz	-	felix:toolbox --route	exit 2	5"
  _cureset; _curun _curunner cu_noinst
  _cuemit "a felix row unknown because its instrument is not installed runs nothing" "$_cust ran=[$(_curan)]" "unknown ran=[]"
  _cutable "cu_e127	-	-	-	felix:toolbox --route	exit 127	5"
  _cureset; _curun _curunner cu_e127
  _cuemit "a felix row whose check exits 127 runs nothing" "$_cust ran=[$(_curan)]" "unknown ran=[]"
  _cutable "cu_e126	-	-	-	felix:toolbox --route	exit 126	5"
  _cureset; _curun _curunner cu_e126
  _cuemit "a felix row whose check exits 126 runs nothing" "$_cust ran=[$(_curan)]" "unknown ran=[]"
  _cutable "cu_when	-	-	exit 3	felix:toolbox --route	exit 2	5"
  _cureset; _curun _curunner cu_when
  _cuemit "a felix row whose when is unknown runs nothing" "$_cust ran=[$(_curan)]" "unknown ran=[]"
  mkdir -p "$_cup/capabilities"
  _cutable "cu_grounds	cu_cap	-	-	felix:toolbox --route	exit 2	5"
  _cureset; _curun _curunner cu_grounds
  _cuemit "a felix row grounded on a capabilities list that could not be read runs nothing" "$_cust ran=[$(_curan)]" "unknown ran=[]"
  rmdir "$_cup/capabilities"
  _cutable "cu_fn	-	-	-	felix:toolbox --route	felix_cu_not_loaded_anywhere; exit 2	5"
  _cureset; _curun _curunner cu_fn
  _cuemit "a felix row whose check names an engine function not loaded runs nothing" "$_cust ran=[$(_curan)]" "unknown ran=[]"
  _cutable "cu_held	-	-	-	felix:toolbox --route	exit 1	5"
  _cureset; _curun _curunner cu_held
  _cuemit "a held felix row still has its answer run, and stays held when that changes nothing" \
    "$_cust ran=[$(_curan)]" "held ran=[felix:toolbox --route]"
  _cutable "cu_prov	-	-	-	provider:claude-code-setup:claude-automation-recommender	-	4"
  _cureset; _curun _curunner cu_prov
  _cuemit "a provider row is untouched by the exit-2 rule: awaiting, and nothing run" "$_cust ran=[$(_curan)]" "awaiting ran=[]"

  # C3. The receipt over a run holding a row that could not be asked.
  _cutable "cu_fine	-	-	-	-	true	3" "cu_status	-	-	-	-	exit 2	3"
  _cureset; _curun - cu_status
  _cuemit "a run with a row whose check exited 2 writes the receipt indeterminate" \
    "$(felix_commission_receipt_write "$_cudir/home" "$_cup" "$_cur" "$_cuout" "$(felix_commission_malformed "$_cup")")" "indeterminate"
  _cutable "cu_fine	-	-	-	-	true	3" "cu_status	-	-	-	felix:toolbox --route	exit 2	5"
  _cureset; _curun _curunner cu_status
  _cuemit "a real run whose felix answer left its check exiting 2 writes the receipt indeterminate" \
    "$(felix_commission_receipt_write "$_cudir/home" "$_cup" "$_cur" "$_cuout" "$(felix_commission_malformed "$_cup")")" "indeterminate"

  # C4. The reach row, its unwired read stubbed.
  row="$(_curow reach)"
  IFS=$'\t' read -r need grounds instrument when answer check step <<CUROW
$row
CUROW
  _cuemit "the exit-2 block finds a reach row and stubs every engine function its check names" \
    "$([ -n "$row" ] && printf present || printf absent) unstubbed=[$(_cuunstubbed "$check" felix_toolbox_unwired)]" \
    "present unstubbed=[]"
  if [ -n "$row" ]; then
    _cuc4() {
      _cuuwhow="$1"; _cuuwrc="$2"; _cuuwout="$3"
      _cuemit "reach: $5 (pipefail on and off)" "$(_cuboth reach "$instrument" "$answer" "$check")" "on=$4 off=$4"
    }
    _cuq='?\tthe capabilities this project declares could not be read\n'
    _cuc4 return 0   ''                done    'an unwired read that returned 0 having printed nothing reads done'
    _cuc4 return 0   'someplugin\tllm\n' held  'an unwired read that returned 0 naming a plugin reads held'
    _cuc4 return 2   "$_cuq"           unknown 'an unwired read that returned 2 saying the capabilities could not be read reads unknown'
    _cuc4 return 2   ''                unknown 'an unwired read that returned 2 having printed nothing reads unknown'
    _cuc4 return 2   'someplugin\tllm\n' unknown 'an unwired read that returned 2 naming a plugin reads unknown, its status deciding'
    _cuc4 return 1   ''                done    'an unwired read that returned 1 having printed nothing reads done'
    _cuc4 return 1   'someplugin\tllm\n' held  'an unwired read that returned 1 naming a plugin reads held'
    _cuc4 exit   128 ''                held    'an unwired read that ended its substitution with exit 128 reads held'
    _cuc4 return 128 ''                held    'an unwired read that returned 128 having printed nothing reads held'
    _cuc4 return 130 "$_cuq"           held    'an unwired read that returned 130 after the could-not-be-read line reads held, a death'
    _cuuwhow=return; _cuuwrc=0; _cuuwout=
    _cuemit "reach: when no pipe can be made, the reach check does not pass though its read answers" \
      "$(_cunopipe "$check")" "free=passes nopipe=fails"
    { printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\n'; _curowrun reach; } > "$_cup/commissioning.tsv"
    _cuuwhow=return; _cuuwrc=2; _cuuwout="$_cuq"
    _cureset; _curun _curunner reach
    _cuemit "reach: a real run whose unwired read returned 2 runs toolbox --route" "$(_curan)" "felix:toolbox --route"
    _cuemit "reach: a real run whose unwired read still returns 2 after toolbox --route reads unknown" "$_cust" "unknown"
    _cuemit "reach: that run reports toolbox --route and its exit first in its detail" \
      "$(_cuhead "$_cudet" 'ran toolbox --route (exit ')" 'ran toolbox --route (exit '
  fi

  # C5. The discover row, its cache lookup and its adoption stubbed.
  row="$(_curow discover)"
  IFS=$'\t' read -r need grounds instrument when answer check step <<CUROW
$row
CUROW
  _cuemit "the exit-2 block finds a discover row and stubs every engine function its check names" \
    "$([ -n "$row" ] && printf present || printf absent) unstubbed=[$(_cuunstubbed "$check" felix_discover_cache_current felix_discover_adopt)]" \
    "present unstubbed=[]"
  if [ -n "$row" ]; then
    _cuc5() {
      _cucc="$1"; _cuadhow="$2"; _cuadrc="$3"; _cuadout="$4"
      _cuemit "discover: $6 (pipefail on and off)" "$(_cuboth discover "$instrument" "$answer" "$check")" "on=$5 off=$5"
    }
    _cuc5 0   return 0   'already\tfoo\tllm\tlow\n' done 'a current cache and an adoption already declared reads done'
    _cuc5 0   return 0   ''                        done 'a current cache and an adoption that prints nothing reads done'
    _cuc5 0   return 0   'already\tfoo\tllm\tlow\ndeclare\tbar\tllm\tlow\n' held 'a current cache and an adoption still to declare reads held'
    _cuc5 1   return 0   'already\tfoo\tllm\tlow\n' unknown 'a cache that is not current reads unknown, whatever adoption says'
    _cuc5 1   return 0   'declare\tbar\tllm\tlow\n' unknown 'a cache that is not current reads unknown though adoption would declare'
    _cuc5 die return 0   'already\tfoo\tllm\tlow\n' held 'a cache lookup that dies with exit 128 reads held'
    _cuc5 0   exit   128 ''                        held 'an adoption that ended its substitution with exit 128 having printed nothing reads held'
    _cuc5 0   exit   128 'declare\tbar\tllm\tlow\n' held 'an adoption that printed a declare row and then exited 128 reads held'
    _cuc5 0   return 1   'already\tfoo\tllm\tlow\n' done 'an adoption that printed only already rows and returned 1 reads done'
    _cucc=0; _cuadhow=return; _cuadrc=0; _cuadout='already\tfoo\tllm\tlow\n'
    _cuemit "discover: when no pipe can be made, the discover check does not pass though its lookups answer" \
      "$(_cunopipe "$check")" "free=passes nopipe=fails"
    { printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\n'; _curowrun discover; } > "$_cup/commissioning.tsv"
    _cucc=flag; _cuadhow=return; _cuadrc=0; _cuadout=
    _cureset; _cumake=1; _curun _curunner discover
    _cuemit "discover: a real run with no current cache whose answer makes it current, adopting nothing, reads done" "$_cust" "done"
    _cureset; _curun _curunner discover
    _cuemit "discover: a real run with no current cache runs discover --adopt" "$(_curan)" "felix:discover --adopt"
    _cuemit "discover: a real run whose cache is still not current after discover --adopt reads unknown" "$_cust" "unknown"
    _cuemit "discover: that run reports discover --adopt and its exit first in its detail" \
      "$(_cuhead "$_cudet" 'ran discover --adopt (exit ')" 'ran discover --adopt (exit '
  fi
  printf 'cu-end\n'
}

# C6. The real engine, nothing stubbed, in a _cm of its own. FELIX_HOME_DIR is
# $FROOT there, and no discovery cache is ever written for these projects.
_cu6() {
  local p kind
  p="$TMP/cu-fresh"; mkdir -p "$p"
  { printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\n'; _curowrun discover; } > "$p/commissioning.tsv"
  _cuemit "discover: with the real cache lookup and no discovery cache, the row reads unknown with no runner" \
    "$([ -e "$FELIX_HOME_DIR/state/discover/cu-fresh.tsv" ] && printf 'a cache' || printf 'no cache') $(_cufield "$(felix_commission_run "$p" "$_cur" - </dev/null)" discover 2)" \
    "no cache unknown"
  for kind in directory dangling; do
    p="$TMP/cu-unread-$kind"; mkdir -p "$p"
    if [ "$kind" = directory ]; then mkdir -p "$p/capabilities"; else ln -s "$TMP/cu-gone" "$p/capabilities"; fi
    { printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\n'; _curowrun reach; } > "$p/commissioning.tsv"
    case "$kind" in directory) kind='a directory' ;; *) kind='a symlink whose target is gone' ;; esac
    _cuemit "reach: with the real unwired read and a capabilities list that is $kind, the row reads unknown" \
      "$(_cufield "$(felix_commission_run "$p" "$_cur" - </dev/null)" reach 2)" "unknown"
  done
  printf 'cu-end\n'
}

_cures="$(_cm _cuall)
$(_cm _cu6)"
while IFS='|' read -r _cuname _cugot _cuwant; do
  [ -n "$_cuname" ] && [ "$_cuname" != cu-end ] || continue
  is "$_cuname" "$_cugot" "$_cuwant"
done <<CURES
$_cures
CURES
is "the exit-2 block reached the end of both its runs, no case dropped" \
   "$(printf '%s\n' "$_cures" | grep -c '^cu-end$')" "2"

# C8. The template's header says it, where it describes the check column.
_cuhdr="$(awk '/^# check[[:space:]]/ { on = 1 } /^# step[[:space:]]/ { on = 0 } on' \
            "$FROOT/harness/templates/commissioning.tsv" | sed 's/^#[[:space:]]*//' | tr '\n' ' ' | tr -s ' ')"
_cu8a=no; _cu8u=no; _cu8t=no
case "$_cuhdr" in *'could not be asked'*) _cu8a=yes ;; esac
case "$_cuhdr" in *unknown*) _cu8u=yes ;; esac
grep -qE '(^|[^0-9])2([^0-9]|$)' <<<"$_cuhdr" && _cu8t=yes
is "the template's check column says a check exiting 2 could not be asked and reads unknown" \
   "asked=$_cu8a unknown=$_cu8u two=$_cu8t" "asked=yes unknown=yes two=yes"

rm -rf "$_cudir" "$_cup" "$_cur" "$TMP/cu-fresh" "$TMP/cu-unread-directory" "$TMP/cu-unread-dangling"
unset -f _curow _curowrun _cuemit _cuhas _cuhead _cutable _cufield _curan _cureset _curunner \
         _custate _cuboth _curun _cuunstubbed _cunopipe _cuc1 _cuall _cu6
unset _cutab _cudir _cup _cur _cures _cuname _cugot _cuwant _cuhdr _cu8a _cu8u _cu8t

printf '\ncommissioning: a lookup that ends its substitution with exit 2 makes its row unknown\n'
# After review, not blind (2026-10-08). A seeded row reads each lookup into a
# variable, `x="$(lookup; ...)" && ...`, and an assignment's status is its
# substitution's. So a lookup that ends the substitution with `exit 2` gives
# the check a 2, which since the exit-2 rule reads unknown: the lookup said it
# could not answer. Until then it read held. 128 and more stay held, as 0di
# ruled. No lookup ends with 2 today (die defaults to 1), so this pins the
# reading for the day one does. Each seeded row's first lookup, one row at a
# time in its own shell, so no other row sees the stub. And the review's
# other gap: a felix row whose check does not parse runs nothing, where until
# the parse guard it read held and its answer ran.
_cvtab="${CMU_TABLE:-$FROOT/harness/templates/commissioning.tsv}"
_cvp="$TMP/cv-proj"; _cvr="$TMP/cv-root"
mkdir -p "$_cvp" "$_cvr"
printf 'gh_auth\tGitHub CLI signed in\n' > "$_cvp/setup.tsv"
# need answer check -> state/detail, the detail shortened to `could not be
# asked` when it is that one. A function of its own because bash 3.2 reads a
# case pattern's `)` inside $( ) as the end of the substitution.
_cvread() {
  local l
  l="$(felix_commission_state "$_cvp" "$_cvr" "$1" - - - "$2" "$3" </dev/null | cut -f1,2)"
  case "$l" in
    *'says it could not be asked'*) printf '%s/could not be asked' "${l%%$'\t'*}" ;;
    *) printf '%s' "$l" | tr '\t|' '/ ' ;;
  esac
}
_cvall() {
  local need grounds instrument when answer check step fn n=0
  # _cm does not load the obligation library, and a row naming a function that
  # is not loaded is unknown for that reason before its check runs. So it is
  # loaded here, and the detail is read too: unknown because the check could
  # not be asked, never for another reason (the review found the obligations
  # case green on main that way).
  command -v felix_obligation_rows >/dev/null 2>&1 || . "$FROOT/harness/lib/obligations.sh"
  export FELIX_PROJECT="$_cvp" FELIX_PROJECT_NAME=cv-proj FELIX_ROOT_DIR="$_cvr" FELIX_MEMORY_DIR="$TMP/cv-mem"
  while IFS=$'\t' read -r need grounds instrument when answer check step; do
    case "$answer" in provider:*) continue ;; esac
    fn="$(printf '%s' "$check" | grep -oE '(felix_[a-z_]+|cmd_[a-z_]+)' | head -n 1)"
    [ -n "$fn" ] || continue
    n=$((n + 1))
    printf '%s: its first lookup, %s, ending with exit 2 makes the row unknown, as one that could not be asked|%s|unknown/could not be asked\n' "$need" "$fn" \
      "$( eval "$fn() { exit 2; }"; _cvread "$need" "$answer" "$check" )"
  done <<CVROWS
$(grep -vE '^[[:space:]]*(#|$)' "$_cvtab")
CVROWS
  printf 'the exit-2 lookup cases asked some seeded rows|%s|yes\n' "$([ "$n" -gt 0 ] && printf yes || printf no)"
  { printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\n'
    printf 'cv_parse\t-\t-\t-\tfelix:toolbox --route\tif then\t5\n'; } > "$_cvp/commissioning.tsv"
  : > "$TMP/cv-ran"
  _cvrunner() { printf '%s\n' "$1" >> "$TMP/cv-ran"; return 0; }
  printf 'a felix row whose check does not parse is unknown and runs nothing|%s ran=[%s]|unknown ran=[]\n' \
    "$(felix_commission_run "$_cvp" "$_cvr" _cvrunner </dev/null | awk -F'\t' '$1 == "cv_parse" { print $2 }')" \
    "$(tr '\n' ' ' < "$TMP/cv-ran" | sed 's/ $//')"
  printf 'cv-end\n'
}
_cvres="$(_cm _cvall)"
while IFS='|' read -r _cvname _cvgot _cvwant; do
  [ -n "$_cvname" ] && [ "$_cvname" != cv-end ] || continue
  is "$_cvname" "$_cvgot" "$_cvwant"
done <<CVRES
$_cvres
CVRES
is "the exit-2 lookup block reached its end, no case dropped" \
   "$(printf '%s\n' "$_cvres" | grep -c '^cv-end$')" "1"
rm -rf "$_cvp" "$_cvr" "$TMP/cv-mem" "$TMP/cv-ran"
unset -f _cvall _cvread
unset _cvtab _cvp _cvr _cvres _cvname _cvgot _cvwant

printf '\ncommissioning: the discover row reads any other cache status as held, and the template says what 2 means\n'
# After review, not blind (2026-10-08). felix_discover_cache_current returns 0
# or 1 today, so the discover row's third arm, anything else, was reached by
# no assertion: turning it into `exit 2` kept everything green. It reads held,
# as an answer that is neither current nor not current, not a could-not-ask.
# And the header test above only looked for three words; this one reads the
# sentence. The status is written into the stub when it is defined: the stub
# runs inside felix_commission_state, whose own local `rc` a `$rc` would read
# (bash scopes dynamically), and the first draft of this block read done that way.
_cwtab="${CMU_TABLE:-$FROOT/harness/templates/commissioning.tsv}"
_cwp="$TMP/cw-proj"; _cwr="$TMP/cw-root"; mkdir -p "$_cwp" "$_cwr"
_cwall() {
  local need grounds instrument when answer check step rc
  export FELIX_PROJECT="$_cwp" FELIX_PROJECT_NAME=cw-proj FELIX_ROOT_DIR="$_cwr" FELIX_MEMORY_DIR="$TMP/cw-mem"
  IFS=$'\t' read -r need grounds instrument when answer check step <<CWROW
$(grep -vE '^[[:space:]]*(#|$)' "$_cwtab" | awk -F'\t' '$1 == "discover" && !s { print; s = 1 }')
CWROW
  felix_discover_adopt() { printf 'already\tfoo\tllm\tlow\n'; }
  for rc in 3 4 127; do
    printf 'discover: a cache lookup that returns %s, neither current nor not, reads held|%s|held\n' "$rc" \
      "$( eval "felix_discover_cache_current() { return $rc; }"
          felix_commission_state "$_cwp" "$_cwr" discover - - - "$answer" "$check" </dev/null | cut -f1 )"
  done
  printf 'cw-end\n'
}
_cwres="$(_cm _cwall)"
while IFS='|' read -r _cwname _cwgot _cwwant; do
  [ -n "$_cwname" ] && [ "$_cwname" != cw-end ] || continue
  is "$_cwname" "$_cwgot" "$_cwwant"
done <<CWRES
$_cwres
CWRES
is "the discover status block reached its end, no case dropped" \
   "$(printf '%s\n' "$_cwres" | grep -c '^cw-end$')" "1"
_cwhdr="$(awk '/^# check[[:space:]]/ { on = 1 } /^# step[[:space:]]/ { on = 0 } on' \
            "$FROOT/harness/templates/commissioning.tsv" | sed 's/^#[[:space:]]*//' | tr '\n' ' ' | tr -s ' ')"
has "the template's check column says it exits 2 when it could not be asked, and that reads unknown" \
    "$_cwhdr" "2 when it could not be asked here (unknown"
rm -rf "$_cwp" "$_cwr" "$TMP/cw-mem"
unset -f _cwall
unset _cwtab _cwp _cwr _cwres _cwname _cwgot _cwwant _cwhdr
