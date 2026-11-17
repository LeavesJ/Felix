_commissioning_build after-0690
# What nothing serves, reaches or grounds, enumerated from the checkout.
has "a detected surface no row serves, reaches or grounds is named with all three misses" \
    "$(_cm felix_commission_gaps "$CMP" "$CMR")" "secrets	no	no	no"
has "a template need this table lacks is named" \
    "$(_cm felix_commission_template_missing "$CMP" "$FROOT/harness/templates")" "envelope"
has "a pipeline step nothing answers is named from the architecture, not the table" \
    "$(_cm felix_commission_steps_unanswered "$CMP" "$FROOT/harness/templates")" "8	"

# >>> commission template drift (blind assertions; written from the spec alone)
# A table is cut from the template once, and after that only a need it lacks
# was ever named. felix_commission_template_drift PROJ TPL names each project
# row whose need the template also has and whose other six columns differ
# from the template's row for that need: need <TAB> the differing columns. It
# is a report: it refuses nothing and writes nothing. Its tables here live
# under $TMP; the command's run borrows this project's table and the template
# the fixture copied, and leaves both exactly as it found them. Assertions
# under a "control" comment pass on an engine without the function too, so a
# block that fails everywhere cannot pass for red.
_ctdD="$TMP/ctdrift"; mkdir -p "$_ctdD"
_ctdT="$FROOT/harness/templates/commissioning.tsv"
_ctdhad=0
[ -f "$CMP/commissioning.tsv" ] && { cp -p "$CMP/commissioning.tsv" "$_ctdD/project.save"; _ctdhad=1; }
_ctdtkeep="$(cksum < "$_ctdT") $(ls -l "$_ctdT" | cut -c1-10)"
_ctdr()   { local IFS=$'\t'; printf '%s\n' "$*"; }   # one row, its fields joined by tabs
_ctdtab() { local d="$1" r; shift; mkdir -p "$d"
            { printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\n'
              for r in "$@"; do printf '%s\n' "$r"; done; } > "$d/commissioning.tsv"; }
_ctd()    { _cm felix_commission_template_drift "$@" 2>&1; }
_ctdsnap() { find "$@" -exec ls -lid {} + 2>/dev/null | LC_ALL=C sort
             find "$@" -type f -exec cksum {} + 2>/dev/null | LC_ALL=C sort; }
_ctdP="$_ctdD/p"; _ctdTP="$_ctdD/t"

_ctdtab "$_ctdTP" \
  "$(_ctdr t_all - - - - true 3)" \
  "$(_ctdr t_check - - - - true 3)" \
  "$(_ctdr t_g - - - - true 3)" \
  "$(_ctdr t_ics - - - - true 3)" \
  "$(_ctdr t_ws - - - - 'test -f a' 3)" \
  "$(_ctdr t_same - git - 'felix:ready --fix' 'test -d .' 5)" \
  "$(_ctdr t_dash - - - - true 3)" \
  "$(_ctdr t_dash2 '' '' '' - true 3)" \
  "$(_ctdr t_mal - - - - true 3)" \
  "$(_ctdr t_six - - - - true 3)" \
  "$(_ctdr t_tonly - - - - true 3)" \
  "$(_ctdr t_dup - - - - true 3)" \
  "$(_ctdr t_dup - - - - false 4)" \
  "$(_ctdr t_tmal - - - - '! true' 3)" \
  "$(_ctdr t_tmal - - - - true 3)" \
  "$(_ctdr t_prov - - - provider:ctd-plugin:ctd-skill - 4)" \
  "$(_ctdr t_when - - - - true 3)"
# control: the fixture is what the cases below assume it is.
is  "the drift template fixture reads as its rows, a duplicate kept and the malformed dropped" \
    "$(_cm felix_commission_rows "$_ctdTP" | cut -f1 | tr '\n' ' ')" \
    "t_all t_check t_g t_ics t_ws t_same t_dash t_mal t_six t_tonly t_dup t_dup t_tmal t_prov t_when "

# Which columns, and how they are named.
_ctdtab "$_ctdP" "$(_ctdr t_all ctdcap git true 'felix:ready --fix' 'test -d .' 4)"
_ctdo="$(_ctd "$_ctdP" "$_ctdTP")"; _ctdrc=$?
is  "a row differing from the template's in all six columns names all six, in table order" \
    "$_ctdo" "$(printf 't_all\tgrounds instrument when answer check step')"
is  "a comparison that found a differing row exits 0" "$_ctdrc" "0"
_ctdtab "$_ctdP" \
  "$(_ctdr t_check - - - - false 3)" \
  "$(_ctdr t_g ctdcap - - - true 3)" \
  "$(_ctdr t_ics - git - - false 5)" \
  "$(_ctdr t_when - - true - true 3)" \
  "$(_ctdr t_prov - - - provider:ctd-plugin:ctd-other - 4)"
is  "each differing row names only the columns that differ, separated by single spaces" \
    "$(_ctd "$_ctdP" "$_ctdTP")" \
    "$(printf 't_check\tcheck\nt_g\tgrounds\nt_ics\tinstrument check step\nt_when\twhen\nt_prov\tanswer')"

# Exact, byte for byte; and `-` against an empty field is no difference.
# Measured on main: a read with IFS set to a tab folds an empty field into
# its neighbour, so a row with one reads shifted and felix_commission_rows
# drops it (t_dash2 in the control above). Either way nothing is named for
# it; only a reader of the raw columns would name grounds, instrument, when.
_ctdtab "$_ctdP" \
  "$(_ctdr t_ws - - - - 'test  -f a' 3)" \
  "$(_ctdr t_check - - - - 'true ' 3)" \
  "$(_ctdr t_g - - - - True 3)"
is  "the comparison is exact: a doubled space, a trailing space and letter case each differ" \
    "$(_ctd "$_ctdP" "$_ctdTP")" "$(printf 't_ws\tcheck\nt_check\tcheck\nt_g\tcheck')"
_ctdtab "$_ctdP" "$(_ctdr t_same - git - 'felix:ready --fix' 'test -d .' 5)"
_ctdo="$(_ctd "$_ctdP" "$_ctdTP")"; _ctdrc=$?
is  "a row equal to the template's prints nothing and exits 0" "$_ctdrc|$_ctdo" "0|"
_ctdtab "$_ctdP" \
  "$(_ctdr t_dash '' '' '' - true 3)" \
  "$(_ctdr t_dash2 - - - - true 3)" \
  "$(_ctdr t_check - - - - false 3)"
is  "a row with an empty cell is not compared, empty or - on either side" \
    "$(_ctd "$_ctdP" "$_ctdTP")" "$(printf 't_check\tcheck')"
has "because the row with an empty cell is malformed, not read shifted" \
    "$(_cm felix_commission_malformed "$_ctdP" | cut -f1 | tr '\n' ' ')" "t_dash "
# Strings, not numbers: awk compares two fields that look like numbers as
# numbers unless it is told otherwise, and then 1 and 1.0 are one value.
_ctdtab "$_ctdD/tnum" "$(_ctdr t_num - - - - 1 3)" "$(_ctdr t_num2 1 - - - true 3)"
_ctdtab "$_ctdD/pnum" "$(_ctdr t_num - - - - 1.0 3)" "$(_ctdr t_num2 01 - - - true 3)"
is  "fields that read as the same number but differ in bytes are named" \
    "$(_ctd "$_ctdD/pnum" "$_ctdD/tnum")" "$(printf 't_num\tcheck\nt_num2\tgrounds')"

# Only the rows the engine runs are compared.
_ctdtab "$_ctdP" \
  "$(_ctdr t_mal - - - - '! true' 3)" \
  "$(_ctdr t_six - - - - false)" \
  "$(_ctdr t_check - - - - false 3)"
# control
is  "the drift fixture's malformed project rows are malformed" \
    "$(_cm felix_commission_malformed "$_ctdP" | cut -f1 | tr '\n' ' ')" "t_mal t_six "
is  "a malformed project row is not compared with the template's" \
    "$(_ctd "$_ctdP" "$_ctdTP")" "$(printf 't_check\tcheck')"

# A need on one side only prints nothing here.
_ctdtab "$_ctdP" "$(_ctdr t_projonly ctdcap git true - false 9)" "$(_ctdr t_check - - - - false 3)"
is  "a need only the project has prints nothing" "$(_ctd "$_ctdP" "$_ctdTP")" "$(printf 't_check\tcheck')"
_ctdtab "$_ctdP" "$(_ctdr t_check - - - - false 3)"
is  "a need only the template has prints nothing here" "$(_ctd "$_ctdP" "$_ctdTP")" "$(printf 't_check\tcheck')"

# Duplicates: the template's first well-formed row is its row; the project's
# every row is compared.
_ctdtab "$_ctdP" "$(_ctdr t_dup - - - - true 3)" "$(_ctdr t_check - - - - false 3)"
is  "a row equal to the first of the template's two rows for its need is not named" \
    "$(_ctd "$_ctdP" "$_ctdTP")" "$(printf 't_check\tcheck')"
_ctdtab "$_ctdP" "$(_ctdr t_dup - - - - false 4)"
is  "a row equal only to the template's second row for its need is compared with the first" \
    "$(_ctd "$_ctdP" "$_ctdTP")" "$(printf 't_dup\tcheck step')"
_ctdtab "$_ctdP" "$(_ctdr t_tmal - - - - true 3)" "$(_ctdr t_check - - - - false 3)"
is  "a malformed template row is not the template's row for its need; the well-formed one after it is" \
    "$(_ctd "$_ctdP" "$_ctdTP")" "$(printf 't_check\tcheck')"
_ctdtab "$_ctdP" \
  "$(_ctdr t_check - - - - false 3)" \
  "$(_ctdr t_same - git - 'felix:ready --fix' 'test -d .' 5)" \
  "$(_ctdr t_check - - - - true 3)" \
  "$(_ctdr t_check - - - - true 4)"
is  "a need the project carries twice is compared row by row" \
    "$(_ctd "$_ctdP" "$_ctdTP")" "$(printf 't_check\tcheck\nt_check\tstep')"
_ctdtab "$_ctdP" \
  "$(_ctdr t_when - - true - true 3)" \
  "$(_ctdr t_all - - - - true 4)" \
  "$(_ctdr t_check - - - - false 3)"
is  "lines come out in the project table's order, not the template's" \
    "$(_ctd "$_ctdP" "$_ctdTP")" "$(printf 't_when\twhen\nt_all\tstep\nt_check\tcheck')"

# Nothing compared is not nothing differing: no template rows is exit 1.
mkdir -p "$_ctdD/t-absent"
_ctdo="$(_ctd "$_ctdP" "$_ctdD/t-absent")"; _ctdrc=$?
is  "an absent template table exits 1 and prints nothing" "$_ctdrc|$_ctdo" "1|"
mkdir -p "$_ctdD/t-comments"; printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\n\n# nothing\n' > "$_ctdD/t-comments/commissioning.tsv"
_ctdo="$(_ctd "$_ctdP" "$_ctdD/t-comments")"; _ctdrc=$?
is  "a template table holding only comments exits 1 and prints nothing" "$_ctdrc|$_ctdo" "1|"
_ctdtab "$_ctdD/t-malformed" "$(_ctdr t_check - - - - '! true' 3)" "$(_ctdr t_all - - - - true)"
_ctdo="$(_ctd "$_ctdP" "$_ctdD/t-malformed")"; _ctdrc=$?
is  "a template whose every row is malformed exits 1 and prints nothing" "$_ctdrc|$_ctdo" "1|"
mkdir -p "$_ctdD/p-absent"
_ctdo="$(_ctd "$_ctdD/p-absent" "$_ctdTP")"; _ctdrc=$?
is  "an absent project table prints nothing and exits 0" "$_ctdrc|$_ctdo" "0|"
mkdir -p "$_ctdD/p-comments"; printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\n# nothing\n' > "$_ctdD/p-comments/commissioning.tsv"
_ctdo="$(_ctd "$_ctdD/p-comments" "$_ctdTP")"; _ctdrc=$?
is  "a project table holding only comments prints nothing and exits 0" "$_ctdrc|$_ctdo" "0|"

# Writes nothing: no table, no state, no memory. Directories no earlier call
# has seen, so a file a previous call left cannot hide this call's write, and
# every time set back to 2000 so a rewrite in place shows as well. Run from a
# directory of its own, which is watched too.
# The memory root and the home are fresh too, for the same reason: a write
# the earlier calls already made is rewritten in place and changes nothing a
# snapshot to the minute can see (two mutants passed until this was so).
_ctdtab "$_ctdD/pw" "$(_ctdr t_check - - - - false 3)" "$(_ctdr t_g ctdcap - - - true 3)"
mkdir -p "$_ctdD/tw" "$_ctdD/cwd" "$_ctdD/fm" "$_ctdD/fh/state"
cp "$_ctdTP/commissioning.tsv" "$_ctdD/tw/commissioning.tsv"
find "$_ctdD/pw" "$_ctdD/tw" "$_ctdD/cwd" "$_ctdD/fm" "$_ctdD/fh" -exec touch -t 200001010000 {} +
_ctdiso() { ( FELIX_HOME_DIR="$_ctdD/fh"; FELIX_HOME="$_ctdD/fh"; FELIX_MEMORY="$_ctdD/fm"
              export FELIX_HOME FELIX_MEMORY; PATH="$CMSTUB:$PATH"
              . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/stack.sh"
              . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/toolbox.sh"
              . "$FROOT/harness/lib/discover.sh"; . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/commission.sh"
              . "$FROOT/harness/lib/commission-provider.sh"
              cd "$_ctdD/cwd" && felix_commission_template_drift "$@" ) 2>&1; }
_ctdb="$(_ctdsnap "$_ctdD" "$FROOT/projects" "$FROOT/state" "$MEM")"
_ctdo="$(_ctdiso "$_ctdD/pw" "$_ctdD/tw")"; _ctdrc=$?
_ctda="$(_ctdsnap "$_ctdD" "$FROOT/projects" "$FROOT/state" "$MEM")"
_ctdw=same; [ "$_ctdb" = "$_ctda" ] || _ctdw=moved
is  "a comparison that finds rows writes nothing: no table, no state, no memory" \
    "$_ctdrc|$_ctdo|$_ctdw" "$(printf '0|t_check\tcheck\nt_g\tgrounds|same')"

# A caller's IFS, and pipefail with a template bigger than a pipe holds.
_ctdtabifs()   { IFS=$'\t'; felix_commission_template_drift "$@"; }
_ctdpipefail() { set -o pipefail; felix_commission_template_drift "$@"; }
_ctdtab "$_ctdP" \
  "$(_ctdr t_g ctdcap - - - true 3)" \
  "$(_ctdr t_ics - git - - false 5)" \
  "$(_ctdr t_all ctdcap git true 'felix:ready --fix' 'test -d .' 4)"
_ctdo="$(_cm _ctdtabifs "$_ctdP" "$_ctdTP" 2>&1)"; _ctdrc=$?
is  "a caller with IFS set to a tab gets the same lines" "$_ctdrc|$_ctdo" \
    "$(printf '0|t_g\tgrounds\nt_ics\tinstrument check step\nt_all\tgrounds instrument when answer check step')"
# About 210 KB, three times what a pipe holds: a writer feeding a reader that
# stops at the first row is then killed every time, not by luck (measured: 900
# rows was killed on some runs and not others).
_ctdpad="ctd-padding-so-the-template-outgrows-a-pipe-buffer-ctd-padding-ctd-padding-ctd"
mkdir -p "$_ctdD/tbig"
awk -v pad="$_ctdpad" 'BEGIN { printf "# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\n"
  for (i = 1; i <= 2000; i++) printf "t_big_%d\t-\t-\t-\t-\ttrue # %s\t3\n", i, pad }' > "$_ctdD/tbig/commissioning.tsv"
# control
is  "the large drift template reads as 2000 rows" "$(_cm felix_commission_rows "$_ctdD/tbig" | grep -c .)" "2000"
_ctdtab "$_ctdP" \
  "$(_ctdr t_big_1 - - - - false 3)" \
  "$(_ctdr t_big_2 - - - - "true # $_ctdpad" 3)" \
  "$(_ctdr t_big_2000 - - - - "true # $_ctdpad" 4)"
_ctdo="$(_cm _ctdpipefail "$_ctdP" "$_ctdD/tbig" 2>&1)"; _ctdrc=$?
is  "under pipefail, a template larger than a pipe holds is compared at its first row and its last" \
    "$_ctdrc|$_ctdo" "$(printf '0|t_big_1\tcheck\nt_big_2000\tstep')"

# The command. felix commission --status only: a full run writes receipts,
# logs and tables that later assertions read. Rows are cut from the template
# the fixture copied, so the expected lines hold whatever that template says.
_ctdcli() { ( cd "$CMR" && PATH="$CMSTUB:$PATH" "$FELIX" commission --status 2>&1 ); }
_ctdrow() { awk -F'\t' -v n="$1" '!/^[[:space:]]*#/ && $1 == n { print; exit }' "$_ctdT"; }
_ctdhead() { printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\n'; }
# The section: from its heading to the next section the command prints.
_ctdsec() { printf '%s\n' "$1" | awk '!done && index($0, "rows that differ from the template") == 1 { on = 1 }
  on && /^(pipeline steps no row answers|What this cannot say:)/ { on = 0; done = 1 }
  on { print }'; }
# Its list: the indented lines straight after the heading.
_ctdlist() { printf '%s\n' "$1" | awk 'NR == 1 || stop { next } !started && /^$/ { next }
  /^  / { started = 1; print; next } { stop = 1 }'; }
_ctdline() { printf '%s\n' "$1" | awk -v p="$2" '!n && index($0, p) == 1 { n = NR } END { print n + 0 }'; }
_ctdnl='
'
# control
[ -n "$(_ctdrow constitution)" ] && [ -n "$(_ctdrow gate_declared)" ] && [ -n "$(_ctdrow reach)" ] \
  && ok  "the drift run's rows were cut from the template the fixture copied" \
  || bad "the drift run's rows were cut from the template the fixture copied" "a need this block borrows is gone from $_ctdT"

{ _ctdhead; _ctdrow constitution; _ctdrow gate_declared; _ctdr ctdlocal - - - - true 9; } > "$CMP/commissioning.tsv"
_ctdc="$(_ctdcli)"; _ctdcrc=$?
# control
case "$_ctdc" in
  *"differ from the template"*) bad "with no row differing, felix commission --status prints no drift section" "$_ctdc" ;;
  *) ok "with no row differing, felix commission --status prints no drift section" ;;
esac
# control
case "$_ctdc" in
  *"$FROOT/harness/templates"*|*"could not be read"*) bad "and names neither the template's path nor an unreadable template" "$_ctdc" ;;
  *) ok "and names neither the template's path nor an unreadable template" ;;
esac

{ _ctdhead
  _ctdrow constitution | awk -F'\t' -v OFS='\t' '{ $6 = "true # ctd-check"; print }'
  _ctdrow gate_declared
  _ctdrow reach | awk -F'\t' -v OFS='\t' '{ $2 = "ctdcap"; $4 = "true # ctd-when"; $6 = "true # ctd-check"; print }'
  _ctdr ctdlocal - - - - true 9; } > "$CMP/commissioning.tsv"
_ctdb="$(_ctdsnap "$CMP" "$FROOT/harness/templates")"
_ctdd="$(_ctdcli)"; _ctddrc=$?
_ctda="$(_ctdsnap "$CMP" "$FROOT/harness/templates")"
_ctds="$(_ctdsec "$_ctdd")"
case "$_ctdnl$_ctdd$_ctdnl" in
  *"${_ctdnl}rows that differ from the template's row for the same need${_ctdnl}"*)
     ok  "felix commission --status prints the drift heading as its own line" ;;
  *) bad "felix commission --status prints the drift heading as its own line" "$_ctdd" ;;
esac
_ctdm="$(_ctdline "$_ctdd" "questions the template asks that this table lacks")"
_ctdh="$(_ctdline "$_ctdd" "rows that differ from the template")"
_ctdu="$(_ctdline "$_ctdd" "pipeline steps no row answers")"
[ "$_ctdm" -gt 0 ] && [ "$_ctdh" -gt "$_ctdm" ] && [ "$_ctdu" -gt "$_ctdh" ] \
  && ok  "the drift section follows the missing needs and comes before the unanswered steps" \
  || bad "the drift section follows the missing needs and comes before the unanswered steps" \
         "missing needs at line $_ctdm, drift at $_ctdh, unanswered steps at $_ctdu"
is  "one line per differing row: two spaces, the need padded to 22, the columns" \
    "$(_ctdlist "$_ctds")" "$(printf '  %-22s %s\n' constitution check reach 'grounds when check')"
has "the drift note says a project may keep its own row on purpose" "$_ctds" "on purpose"
has "the drift note shows the template's path"                      "$_ctds" "$FROOT/harness/templates"
has "the drift note says the receipt reads stale after a row changes" "$_ctds" "stale"
has "the drift note names the command that re-arms a commission grant" "$_ctds" "felix autonomy --allow commission"
has "and says a provider row's answer goes stale"                     "$_ctds" "answer goes stale"
has "the drift note names the template table, not only its directory" "$_ctds" "$FROOT/harness/templates/commissioning.tsv"
# control
is  "felix commission --status exits the same with rows drifting as without" "$_ctddrc" "$_ctdcrc"
# control
[ "$_ctdb" = "$_ctda" ] \
  && ok  "felix commission --status rewrites no table when rows drift" \
  || bad "felix commission --status rewrites no table when rows drift" "a file under $CMP or the templates moved"

# The template unreadable: said, and no row named against it.
chmod u-r "$_ctdT"
if [ -r "$_ctdT" ]; then
  chmod u+r "$_ctdT"
  skip "an unreadable template is said: it could not be read"             "this user reads a file whatever its mode"
  skip "and no row is named as differing from an unreadable template"     "this user reads a file whatever its mode"
  skip "felix commission --status exits the same with the template unreadable" "this user reads a file whatever its mode"
else
  _ctdx="$(_ctdcli)"; _ctdxrc=$?
  chmod u+r "$_ctdT"
  has "an unreadable template is said: it could not be read" "$_ctdx" "could not be read"
  # control
  case "$_ctdx" in
    *"$(printf '  %-22s %s' constitution check)"*) bad "and no row is named as differing from an unreadable template" "$_ctdx" ;;
    *) ok "and no row is named as differing from an unreadable template" ;;
  esac
  # control
  is  "felix commission --status exits the same with the template unreadable" "$_ctdxrc" "$_ctdcrc"
fi

# The full run, the one a person makes after any table change. On a project
# of its own, removed afterwards, because a full run writes a receipt, a log
# and a lock that later assertions about this fixture's project would read.
# (After review: three full-run mutants passed every --status assertion,
# among them one that rewrote the table.)
_ctdnames() { find "$FROOT/projects" "$FROOT/state" "$MEM" ! -type d 2>/dev/null | LC_ALL=C sort; }
_ctdn0="$(_ctdnames)"
_ctdFP="$FROOT/projects/ctdfull"; _ctdFR="$TMP/ctd-full-repo"
mkdir -p "$_ctdFP" "$_ctdFR"
( _fx_cd "$_ctdFR" && git init -q -b main && printf 'x\n' > a.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
_ctdFR="$(cd "$_ctdFR" && pwd -P)"
printf 'ctdfull\n' > "$_ctdFR/.felix"
printf '{"name":"ctdfull","gate":"true"}\n' > "$_ctdFP/project.json"
printf '# ctdfull\n' > "$_ctdFP/CLAUDE.md"
: > "$_ctdFP/capabilities"
printf '# k\tn\ts\tr\tc\n' > "$_ctdFP/stack.tsv"
cp "$FROOT/harness/templates/profiles.tsv" "$FROOT/harness/templates/routes.tsv" "$_ctdFP/"
_ctdfull() { ( cd "$_ctdFR" && PATH="$CMSTUB:$PATH" "$FELIX" commission 2>&1 ); }
{ _ctdhead; _ctdrow constitution; } > "$_ctdFP/commissioning.tsv"
_ctdf0="$(_ctdfull)"; _ctdf0rc=$?
{ _ctdhead; _ctdrow constitution | awk -F'\t' -v OFS='\t' '{ $6 = $6 " && true"; print }'; } > "$_ctdFP/commissioning.tsv"
_ctdfk="$(cksum < "$_ctdFP/commissioning.tsv")"
_ctdf1="$(_ctdfull)"; _ctdf1rc=$?
# control
case "$_ctdf0" in
  *"differ from the template"*) bad "a full run with no row differing prints no drift section" "$_ctdf0" ;;
  *) ok "a full run with no row differing prints no drift section" ;;
esac
is  "a full felix commission run names the differing row too" \
    "$(_ctdlist "$(_ctdsec "$_ctdf1")")" "$(printf '  %-22s %s' constitution check)"
# control
is  "and exits as the same run does with no row differing" "$_ctdf1rc" "$_ctdf0rc"
# control
is  "and leaves the project's table as it was" "$(cksum < "$_ctdFP/commissioning.tsv")" "$_ctdfk"
rm -rf "$_ctdFP" "$_ctdFR" "$MEM/ctdfull" "$FROOT/state/commission/ctdfull" "$FROOT/state/commission/ctdfull".*
# control
is  "the full-run project leaves no file behind for later assertions" "$(_ctdnames)" "$_ctdn0"

if [ "$_ctdhad" -eq 1 ]; then cp -p "$_ctdD/project.save" "$CMP/commissioning.tsv"; else rm -f "$CMP/commissioning.tsv"; fi
# control
is  "the drift block leaves the fixture's template as it found it" \
    "$(cksum < "$_ctdT") $(ls -l "$_ctdT" | cut -c1-10)" "$_ctdtkeep"
# control
if [ "$_ctdhad" -eq 1 ]; then
  cmp -s "$_ctdD/project.save" "$CMP/commissioning.tsv" \
    && ok  "and the project's table as it found it, byte for byte" \
    || bad "and the project's table as it found it, byte for byte"
else
  [ ! -e "$CMP/commissioning.tsv" ] \
    && ok  "and the project's table as it found it, byte for byte" \
    || bad "and the project's table as it found it, byte for byte" "it had none, and now has one"
fi
# <<< commission template drift

# The command: refuses the absent and empty table, writes the receipt, reads
# it back, and says who answers what is held.
mv "$CMP/commissioning.tsv" "$CMP/commissioning.keep"
_cmo="$(_cmcli)"; _cmrc=$?
is  "felix commission on a project without the table exits 1" "$_cmrc" "1"
has "and names the template"                                  "$_cmo"  "templates/commissioning.tsv"
printf '# only a comment\n' > "$CMP/commissioning.tsv"
_cmo="$(_cmcli)"; _cmrc=$?
is  "a table of comments exits 1"                       "$_cmrc" "1"
has "and calls it a shelf with nothing on it"           "$_cmo"  "shelf with nothing on it"
_cmo="$(_cmcli --yes)"; _cmrc=$?
is  "there is no --yes"                                 "$_cmrc" "1"
mv "$CMP/commissioning.keep" "$CMP/commissioning.tsv"

# One run at a time, and only for the run that writes.
#
# A full run appends to stack.tsv twice, to commissioning.log and a play into
# routes.tsv. None is atomic, none idempotent, so two interleaving runs write a
# row half by each — a table that reads as somebody typing it wrong, produced
# by two commands each doing what it was told. cmd_commission held no mutex of
# any kind, so nothing stopped it.
_cmlock="$FROOT/state/commission/$(basename "$CMP").lock"
mkdir -p "$(dirname "$_cmlock")"; mkdir "$_cmlock" 2>/dev/null
printf '%s\n' "$$" > "$_cmlock/pid"          # this process is alive by construction
_cmo="$(_cmcli)"; _cmrc=$?
is  "a second full run refuses while one is in progress"  "$_cmrc" "1"
has "and names the process holding it"                    "$_cmo"  "already in progress (pid $$)"
has "and points at the read that needs no lock"           "$_cmo"  "--status"
# --status writes nothing, so it takes nothing: making a person's read wait on
# somebody else's run would be a lock doing harm to buy nothing.
_cmo="$(_cmcli --status)"; _cmrc=$?
is  "while --status reads straight through it"            "$_cmrc" "0"
# A lock whose owner is gone is not a lock. This one is taken by a command a
# person typed, so a dead owner must not shut them out of their own project —
# the opposite of the background refresh's lock, where sitting there costs
# only a stale cache.
printf '%s\n' "999999" > "$_cmlock/pid"
_cmo="$(_cmcli)"
case "$_cmo" in
  *"already in progress"*) bad "a lock whose owner is gone is taken over" "$_cmo" ;;
  *)                       ok  "a lock whose owner is gone is taken over" ;;
esac
is  "and the run that took it over leaves nothing behind" \
    "$([ -d "$_cmlock" ] && echo held || echo clear)" "clear"

# The one place Felix talks to a host it does not control must not be able to
# hang, or to ask a terminal for credentials.
#
# There is no portable timeout — neither timeout nor gtimeout is on this
# machine — so the deadline is git's own low-speed abort. Asserted through a
# stub git that reports the environment it was handed, because the property is
# what git receives, not what the source says.
_gb="$TMP/gitenv-bin"; mkdir -p "$_gb"
printf '#!/usr/bin/env bash\nprintf "%%s %%s %%s\\n" "${GIT_TERMINAL_PROMPT:-unset}" "${GIT_HTTP_LOW_SPEED_LIMIT:-unset}" "${GIT_HTTP_LOW_SPEED_TIME:-unset}" > "$GITENV_OUT"\nexit 0\n' > "$_gb/git"
chmod +x "$_gb/git"
# Exported, or the stub is a child that cannot see it — the trap this suite
# already paid for once tonight.
export GITENV_OUT="$TMP/gitenv.out"
( PATH="$_gb:$PATH"; . "$FROOT/harness/lib/discover.sh"; _felix_discover_git status >/dev/null 2>&1 )
is "the fetch never asks a terminal for credentials" \
   "$(cut -d' ' -f1 "$GITENV_OUT" 2>/dev/null)" "0"
case "$(cut -d' ' -f2 "$GITENV_OUT" 2>/dev/null)" in
  unset|'') bad "and carries a low-speed deadline so a stall cannot wait forever" ;;
  *)        ok  "and carries a low-speed deadline so a stall cannot wait forever" ;;
esac
unset GITENV_OUT
rm -f "$FROOT/state/commission/cmproj"
_cmo="$(_cmcli --status)"; _cmrc=$?
is  "--status on a never-commissioned project exits 0 and runs nothing" "$_cmrc" "0"
has "and says the receipt does not exist here"    "$_cmo" "never commissioned on this machine"
[ -f "$FROOT/state/commission/cmproj" ] && bad "--status writes no receipt" || ok "--status writes no receipt"
_cmo="$(_cmcli)"; _cmrc=$?
is  "a full run on a clean table exits 0"               "$_cmrc" "0"
has "and reports the receipt it wrote"                  "$_cmo"  "receipt: commissioned"
has "and names who answers the provider row"            "$_cmo"  "a session runs /claude-code-setup:claude-automation-recommender"
has "and names the pipeline step no row here answers"    "$_cmo"  "initialize obligation and evidence state"
[ -f "$FROOT/state/commission/cmproj" ] && ok "the run writes the receipt" || bad "the run writes the receipt"
printf 'api\n' >> "$CMP/capabilities"
has "--status after a table edit reads stale"           "$(_cmcli --status)" "stale (table set moved"

# The gate line: offline, announce-only, except the empty case.
_cmgate() { ( cd "$CMR" && PATH="$CMSTUB:$PATH" "$FELIX" gate 2>&1 ); }
has "the gate announces a stale receipt and does not fail on it" "$(_cmgate)" "commission         stale"
_cmcli >/dev/null 2>&1
: > "$CMSTUB_LOG"
has "after commissioning the gate line reads ok"        "$(_cmgate)" "commission         ok"
is  "and the gate line called no cli"                   "$(grep -c . "$CMSTUB_LOG")" "0"
mv "$CMP/commissioning.tsv" "$CMP/commissioning.keep"
has "a project without the table is skipped, announced" "$(_cmgate)" "skipped (no commissioning.tsv"
printf '# empty\n' > "$CMP/commissioning.tsv"
_cmg="$(_cmgate)"
has "an empty table fails the gate"                     "$_cmg" "commission         FAIL"
has "and lands in mistakes.log under its own name"      "$(tail -1 "$MEM/cmproj/mistakes.log")" "commission"
mv "$CMP/commissioning.keep" "$CMP/commissioning.tsv"
grep -v '^api$' "$CMP/capabilities" > "$CMP/caps.tmp"; mv "$CMP/caps.tmp" "$CMP/capabilities"

# The merge boundary: the second place the empty case is refused, and the
# one that bites on staleness. Never on held rows.
_cmblk() { ( cd "$CMR" && FELIX_HOME_DIR="$FROOT"
             . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/evidence.sh"; . "$FROOT/harness/lib/verify.sh"
             [ "${1:-}" = "--unload" ] && unset -f felix_commission_rows
             felix_merge_blockers "$CMP" HEAD~1 "$CMR" "$FROOT" ) 2>/dev/null; }
_cmcli >/dev/null 2>&1
case "$(_cmblk)" in
  *commission*) bad "a valid receipt raises no commission blocker" "$(_cmblk | grep commission)" ;;
  *)            ok  "a valid receipt raises no commission blocker" ;;
esac
printf 'plugin\tlate\t-\tlow\talways\n' >> "$CMP/stack.tsv"
has "a table edited under a valid receipt blocks the merge as a stale receipt" "$(_cmblk)" "commission	receipt"
_cmcli >/dev/null 2>&1
mv "$CMP/commissioning.tsv" "$CMP/commissioning.keep"
has "a project without the table blocks the merge"      "$(_cmblk)" "commission	table"
mv "$CMP/commissioning.keep" "$CMP/commissioning.tsv"
has "an engine that cannot evaluate commissioning blocks rather than skips" "$(_cmblk --unload)" "commission	engine"

# felix new commissions instead of printing the next steps, and writes
# nothing into the tree but the marker.
CMS="$TMP/cm-stranger"; mkdir -p "$CMS"
( _fx_cd "$CMS" && git init -q -b main ) >/dev/null 2>&1
printf '{ "name": "cms", "scripts": { "verify": "echo ok" }, "dependencies": { "express": "^4" } }\n' > "$CMS/package.json"
: > "$CMSTUB_LOG"
_cmn="$(cd "$CMS" && PATH="$CMSTUB:$PATH" "$FELIX" new cmstranger 2>&1)"; _cmnrc=$?
is  "felix new still exits 0"                                    "$_cmnrc" "0"
has "and commissions"                                            "$_cmn" "commissioning for cmstranger"
case "$_cmn" in *'next:'*) bad "and no longer prints next steps" ;; *) ok "and no longer prints next steps" ;; esac
case "$_cmn" in *'Felix already covers verification'*|*'paste into a session'*) bad "nor a paste-in prompt" ;; *) ok "nor a paste-in prompt" ;; esac
has "and the provider skill is named as a channel a session runs, not a prompt to paste" "$_cmn" "a session runs /claude-md-management:claude-md-improver"
is  "the tree holds only the marker beside what was there" \
    "$(cd "$CMS" && ls -A | grep -v '^\.git$' | LC_ALL=C sort | tr '\n' ' ')" ".felix package.json "
[ -f "$FROOT/projects/cmstranger/commissioning.tsv" ] && ok "the table is seeded" || bad "the table is seeded"
is  "and the receipt is written with ten fields" \
    "$(awk -F'\t' '{ print NF }' "$FROOT/state/commission/cmstranger" 2>/dev/null)" "10"
# Two rows this machine cannot already have: one low, one high. Asserted on
# a declared row rather than on the catalogue's, because on the founder's
# machine every catalogue plugin is bundled and the inventory now sees that,
# so the seeded rows install nothing here and did on the runner — a stub
# log that depends on whose machine it is proves nothing.
printf 'plugin\tfelix-test-absent-cm@nowhere\t-\tlow\talways\n' >> "$FROOT/projects/cmstranger/stack.tsv"
printf 'plugin\tevil\t-\thigh\talways\n' >> "$FROOT/projects/cmstranger/stack.tsv"
: > "$CMSTUB_LOG"
( cd "$CMS" && PATH="$CMSTUB:$PATH" "$FELIX" commission >/dev/null 2>&1 )
has "stack apply ran through the stub for a declared low row" "$(cat "$CMSTUB_LOG")" "plugin install felix-test-absent-cm"
case "$(cat "$CMSTUB_LOG")" in *evil*) bad "a high-risk row is never installed by commissioning" "$(cat "$CMSTUB_LOG")" ;; *) ok "a high-risk row is never installed by commissioning" ;; esac
# The stub can fail, so the assertions that depend on it can.
( PATH="$CMSTUB:$PATH" claude plugin uninstall anything >/dev/null 2>&1 ) && bad "the stub refuses an untaught shape" || ok "the stub refuses an untaught shape"

# Step 8 of the pipeline — initialize obligation and evidence state — had no
# row answering it since the pipeline was written. Now felix new seeds the
# ledger, and the commissioning row seeds it where felix new never ran.
[ -f "$FROOT/projects/cmstranger/obligations.tsv" ] && ok "felix new seeds the obligations ledger" || bad "felix new seeds the obligations ledger"
is  "with the template's one row, the lifecycle obligation every plugin owes" \
    "$(grep -vE '^[[:space:]]*(#|$)' "$FROOT/projects/cmstranger/obligations.tsv" 2>/dev/null | cut -f1)" "lifecycle_wired"
# felix new's OWN cp, not the commissioning answer standing in for it. The
# first version of this asserted only that the file exists, which is true
# either way: with the cp removed the row is held, the runner executes
# `felix:obligations --seed`, and the file appears anyway. The detail line is
# what tells the two apart.
case "$_cmn" in
  *'ran obligations --seed'*) bad "and felix new seeds it itself, without falling through to the answer" "$_cmn" ;;
  *) ok "and felix new seeds it itself, without falling through to the answer" ;;
esac
# And the seeded row is dormant for a project that is not a plugin. The
# template's applies once asked only for a tracked path ending in hooks.json,
# so a web application with src/config/hooks.json was handed an ACTIVE obligation
# whose evidence is a hold — UNKNOWN, blocking — on the day it was created.
_cmseventh_build   # tests/lib/cm-stub.sh: the web application, felix new over it (CMW, _cmw)
is  "a stranger that is not a plugin is created without a blocking obligation" \
    "$(cd "$CMW" && PATH="$CMSTUB:$PATH" "$FELIX" obligations 2>/dev/null | grep -c 'DORMANT')" "1"
case "$(cd "$CMW" && PATH="$CMSTUB:$PATH" "$FELIX" obligations 2>&1)" in
  *UNKNOWN*) bad "and a file merely named hooks.json does not make the row apply" "$(cd "$CMW" && PATH="$CMSTUB:$PATH" "$FELIX" obligations 2>&1)" ;;
  *)         ok  "and a file merely named hooks.json does not make the row apply" ;;
esac
is  "so its gate is not red on the day it was created" \
    "$(cd "$CMW" && PATH="$CMSTUB:$PATH" "$FELIX" obligations >/dev/null 2>&1; echo $?)" "0"
# The receipt is hashed over the tables that decide, and the step-8 row reads
# obligations.tsv, so a ledger edited under a valid receipt must invalidate it.
is  "obligations.tsv is one of the tables the receipt is bound to" \
    "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/commission.sh"
        printf '%s' "$FELIX_COMMISSION_TABLES" | tr ' ' '\n' | grep -cx 'obligations.tsv' )" "1"
_cms="$(cd "$CMS" && PATH="$CMSTUB:$PATH" "$FELIX" commission --status 2>&1)"
case "$_cms" in
  *"initialize obligation and evidence state"*) bad "and step 8 is no longer a step nothing answers" "$_cms" ;;
  *) ok "and step 8 is no longer a step nothing answers" ;;
esac
is  "the obligations row is done on day one, its seeded row dormant in a project with no hooks" \
    "$(printf '%s\n' "$_cms" | grep -cE '^  done +obligations ')" "1"
# The answer, run by hand and by the commissioning run, and never over a ledger.
rm -f "$FROOT/projects/cmstranger/obligations.tsv"
_cmso="$(cd "$CMS" && PATH="$CMSTUB:$PATH" "$FELIX" obligations --seed 2>&1)"; _cmsrc=$?
is  "felix obligations --seed writes the template where no ledger is" "$_cmsrc" "0"
has "and says so" "$_cmso" "seeded"
printf '# a person wrote this\n' >> "$FROOT/projects/cmstranger/obligations.tsv"
_cmso="$(cd "$CMS" && PATH="$CMSTUB:$PATH" "$FELIX" obligations --seed 2>&1)"; _cmsrc=$?
is  "and a second run is a no-op that exits 0" "$_cmsrc" "0"
has "saying seeding never overwrites" "$_cmso" "never overwrites"
has "and the person's edit survives it" "$(cat "$FROOT/projects/cmstranger/obligations.tsv")" "a person wrote this"
rm -f "$FROOT/projects/cmstranger/obligations.tsv"
( cd "$CMS" && PATH="$CMSTUB:$PATH" "$FELIX" commission >/dev/null 2>&1 )
[ -f "$FROOT/projects/cmstranger/obligations.tsv" ] && ok "a commissioning run seeds the ledger through the row's answer" \
  || bad "a commissioning run seeds the ledger through the row's answer"
has "and the engine names the stage among the answers a row may carry" \
    "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/commission.sh"; felix_commission_instruments | tr '\n' ' ' )" \
    "felix:obligations --seed"

# The moment is declared, so a stance at it is not a typo.
printf 'capability:api\tcommissioning\tfelix commission\t-\n' > "$CMP/procedures.tsv"
case "$(_cm felix_procedures_unknown_moments "$CMP" "$FROOT/harness/templates" 2>/dev/null)" in
  *commissioning*) bad "a stance at the commissioning moment is not a stance at an unknown moment" ;;
  *)               ok  "a stance at the commissioning moment is not a stance at an unknown moment" ;;
esac
rm -f "$CMP/procedures.tsv"


# ------------------------------------------------ the provider protocol ----
# A provider row is a skill a session's model runs, which the engine cannot.
# The engine writes a request into the memory root, the session writes an
# answer beside it, and the engine reads the answer with no model and no
# network — amendments §1.3, applied to the two setup skills. The answer is
# keyed to a topology ingestion never writes; every row read is INFERRED; an
# answered row holds nothing and installs nothing.
_cmtable 'alpha	-	-	-	-	test -f src/a.txt	3' \
         'automation_surveyed	-	-	-	provider:claude-code-setup:claude-automation-recommender	-	4' \
         'constitution_audited	-	-	-	provider:claude-md-management:claude-md-improver	-	4'
rm -rf "$MEM/cmproj/commission"; : > "$MEM/cmproj/commissioning.log"
_cmreq="$MEM/cmproj/commission/requests/automation_surveyed.md"
_cmans="$MEM/cmproj/commission/automation_surveyed.tsv"
_cmtopo="$(_cm felix_commission_topology "$CMP" "$CMR")"

_cmcli >/dev/null 2>&1
[ -f "$_cmreq" ] && ok "a run writes the request for each provider row" || bad "a run writes the request for each provider row"
has "and the request carries the topology it is for"   "$(cat "$_cmreq" 2>/dev/null)" "$_cmtopo"
is  "and every placeholder was filled"                 "$(grep -c '{{' "$_cmreq" 2>/dev/null)" "0"
has "and names the answer file to write"               "$(cat "$_cmreq" 2>/dev/null)" "$_cmans"
has "the row is awaiting, UNKNOWN by class"            "$(grep '	automation_surveyed	' "$MEM/cmproj/commissioning.log" | tail -1)" "	awaiting	UNKNOWN	"
is  "--status writes no request"                       "$(rm -f "$_cmreq"; _cmcli --status >/dev/null 2>&1; [ -f "$_cmreq" ] && echo written || echo none)" "none"
_cmcli >/dev/null 2>&1

printf '# topology 0000\nplugin\tfoo\t-\tllm\twhy\ndone\t1\n' > "$_cmans"
is  "an answer for another topology is stale, and not read"        "$(_cmp automation_surveyed)" "stale"
printf '# topology %s\nplugin\tfoo\t-\tllm\twhy\n' "$_cmtopo" > "$_cmans"
is  "an answer with no terminal done row is partial"               "$(_cmp automation_surveyed)" "partial"
printf '# topology %s\nplugin\tfoo\t-\tllm\twhy\ndone\t3\n' "$_cmtopo" > "$_cmans"
is  "a done count that disagrees with the rows is partial"         "$(_cmp automation_surveyed)" "partial"
printf '# topology %s\nplugin\tfoo\t-\tllm\twhy\nplugin\tbar\t-\tllm\twhy\thigh\nrocket\tbaz\t-\t-\twhy\nmcp\tsentry\t-\tobservability\twhy\ndone\t4\n' "$_cmtopo" > "$_cmans"
is  "a well-formed answer is answered"                             "$(_cmp automation_surveyed)" "answered"
is  "and only rows of the right shape and kind are accepted" \
    "$(_cm felix_commission_provider_rows "$CMP" automation_surveyed | cut -f2 | tr '\n' ' ')" "foo sentry "
has "a row carrying a risk column is refused, because risk is not the model's to assign" \
    "$(_cm felix_commission_provider_rejects "$CMP" automation_surveyed)" "bar	6 fields"
has "and an unknown kind is refused"                               "$(_cm felix_commission_provider_rejects "$CMP" automation_surveyed)" "baz	kind"
# And a kind that is a RUN of known kinds is refused too. The filter was
# `case " $KINDS " in *" $kind "*`, a space-padded substring test, so "plugin
# mcp" matched the middle of the list and passed. That is not cosmetic: the
# admit phase refuses an mcp row by matching the kind EXACTLY, so a row spelled
# "plugin mcp" skipped the refusal and reached the fetch — the one thing spec
# §7 T3 says must never be activated unattended.
printf '# topology %s\nplugin mcp\tsneaky\t-\tllm\twhy\ndone\t1\n' "$_cmtopo" > "$_cmans"
has "a kind that is two known kinds run together is refused" \
    "$(_cm felix_commission_provider_rejects "$CMP" automation_surveyed)" "sneaky	kind"
is  "and it is not accepted as a row" \
    "$(_cm felix_commission_provider_rows "$CMP" automation_surveyed)" ""
printf '# topology %s\nplugin\tfoo\t-\tllm\twhy\nplugin\tbar\t-\tllm\twhy\thigh\nrocket\tbaz\t-\t-\twhy\nmcp\tsentry\t-\tobservability\twhy\ndone\t4\n' "$_cmtopo" > "$_cmans"

# The reader enforced a length that nothing stated. An accepted row's fields
# are written into commissioning.log through `cut -c1-160`, so a long sentence
# was stored truncated mid-word while the row itself read as accepted. The log
# is append-only and outlives the answer file, which the next topology change
# rewrites — so the reason was not clipped, it was lost. #156 settled the rule
# this breaks: the request states every constraint the reader enforces.
_cmwhy() { printf 'w%.0s' $(seq 1 "$1"); }
printf '# topology %s\nplugin\ttoolong\t-\tllm\t%s\ndone\t1\n' "$_cmtopo" "$(_cmwhy 301)" > "$_cmans"
has "a why past the stated ceiling is refused rather than silently cut" \
    "$(_cm felix_commission_provider_rejects "$CMP" automation_surveyed)" "toolong	a why longer than"
is  "and no row is accepted from that file" \
    "$(_cm felix_commission_provider_rows "$CMP" automation_surveyed)" ""
printf '# topology %s\nplugin\tsrctoolong\t%s\tllm\twhy\ndone\t1\n' "$_cmtopo" "$(_cmwhy 201)" > "$_cmans"
has "a source past its ceiling is refused too" \
    "$(_cm felix_commission_provider_rejects "$CMP" automation_surveyed)" "srctoolong	a source longer than"

# The row at the ceiling is accepted AND survives the log whole. This is the
# assertion that matters: it is what makes the ceiling and the log's own bound
# one fact rather than two that can drift apart. A cut that bites anything the
# reader accepted is the defect, whatever the numbers are.
printf '# topology %s\nplugin\tatmax\t%s\tllm\t%s\ndone\t1\n' "$_cmtopo" "$(_cmwhy 200)" "$(_cmwhy 300)" > "$_cmans"
is  "a row at both ceilings is accepted" \
    "$(_cm felix_commission_provider_rows "$CMP" automation_surveyed | cut -f2)" "atmax"
: > "$MEM/cmproj/commissioning.log"
_cmcli >/dev/null 2>&1
is  "and with the whole sentence, not a prefix of it" \
    "$(awk -F'\t' '$9 ~ /^plugin atmax/ { n = gsub(/w/, "w", $9); print n }' "$MEM/cmproj/commissioning.log" | tail -1)" "500"

# The request has to say so, or the refusals above are a trap rather than a
# contract.
has "the request states the why ceiling"    "$(cat "$_cmreq")" "300"
has "and states the source ceiling"         "$(cat "$_cmreq")" "200"

# Restore what this block changed, so the ingestion assertions below read the
# file they were written against.
printf '# topology %s\nplugin\tfoo\t-\tllm\twhy\nplugin\tbar\t-\tllm\twhy\thigh\nrocket\tbaz\t-\t-\twhy\nmcp\tsentry\t-\tobservability\twhy\ndone\t4\n' "$_cmtopo" > "$_cmans"
# The log too: the run above ingested a nomination, and the ingestion
# assertions below count nomination lines from an empty log. Restoring the
# answer file without the log would leave them counting this block's row.
: > "$MEM/cmproj/commissioning.log"
is  "the fixture answer is restored" \
    "$(_cm felix_commission_provider_rows "$CMP" automation_surveyed | cut -f2 | tr '\n' ' ')" "foo sentry "
is  "and the log is back to empty, as this block found it" \
    "$(grep -c . "$MEM/cmproj/commissioning.log")" "0"

# The receipt, the gate line and the merge boundary are byte-identical before
# and after an answer appears: a model's file clears nothing enforcing.
mv "$_cmans" "$_cmans.keep"; _cmcli >/dev/null 2>&1
_cmr_before="$(cut -f2-9 "$FROOT/state/commission/cmproj")"; _cmg_before="$(_cmgate | grep '^  commission')"; _cmb_before="$(_cmblk | grep commission)"
_cma_before="$(cut -f10 "$FROOT/state/commission/cmproj")"
mv "$_cmans.keep" "$_cmans"; _cmo="$(_cmcli)"
# Everything enforcing in the receipt — the two hashes, the toolchain, the
# result and the four counted states — is byte-identical; the one field that
# moves is the informational awaiting count, which is the record that the
# session answered.
is  "an answer file moves nothing enforcing in the receipt" "$(cut -f2-9 "$FROOT/state/commission/cmproj")" "$_cmr_before"
is  "and only the awaiting count records it"  "$(cut -f10 "$FROOT/state/commission/cmproj")" "$((_cma_before - 1))"
is  "changes no gate line"                   "$(_cmgate | grep '^  commission')" "$_cmg_before"
is  "and raises or clears no merge blocker"  "$(_cmblk | grep commission)" "$_cmb_before"
# Nomination lines carry the provider as actor and the file hash as provenance;
# the row-level line for the same run carries the file hash too.
_cmnom() { awk -F'\t' '$5 == "answered" && $7 ~ /^provider:/ && $8 ~ /automation_surveyed\.tsv@/ && $9 !~ /^[0-9]+ rows at/' "$MEM/cmproj/commissioning.log"; }
has "the run records the accepted rows as INFERRED with the file's hash as provenance" \
    "$(_cmnom | tail -1)" "claude-code-setup@"
has "and the row-level line names the same file"  "$(awk -F'\t' '$4 == "automation_surveyed" && $9 ~ /rows at/' "$MEM/cmproj/commissioning.log" | tail -1)" "automation_surveyed.tsv@"
is  "two rows, once each"                    "$(_cmnom | grep -c .)" "2"
_cmcli >/dev/null 2>&1
is  "and a second run does not record the same file twice" "$(_cmnom | grep -c .)" "2"
has "the report lists what the provider named and says nothing was installed" "$_cmo" "recorded and not acted on"

# The topology in a checkout whose path holds a space. felix_detect globs
# $root/$p unquoted, so what it finds there depends on IFS. `felix commission`
# read the provider state inside the heredoc of an `IFS=$'\t' read`, and on
# bash 3.2 that substitution ran under the tab IFS: it hashed a different
# topology from session-start's and the request's, so an answer current for
# one read stale on the other. Its own project, so no fixture above moves.
CSP="$FROOT/projects/cmspace"; CSR="$TMP/cm-ifs space/repo"
mkdir -p "$CSP" "$CSR/tests" "$MEM/cmspace/commission"
printf 'FROM scratch\n' > "$CSR/Dockerfile"
printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\nautomation_surveyed\t-\t-\t-\tprovider:claude-code-setup:claude-automation-recommender\t-\t4\n' \
  > "$CSP/commissioning.tsv"
# Computed as session-start computes it, at the default IFS.
_cstopo="$(_cm felix_commission_topology "$CSP" "$CSR")"
if [ "$(IFS=$'\t'; _cm felix_commission_topology "$CSP" "$CSR")" != "$_cstopo" ]; then
  ok   "a checkout path with a space makes the topology depend on IFS, so the assertion below can reach the trap"
else
  skip "a checkout path with a space makes the topology depend on IFS, so the assertion below can reach the trap" \
       "detection no longer depends on IFS here"
fi
printf '# topology %s\nplugin\tfoo\t-\tllm\twhy\ndone\t1\n' "$_cstopo" > "$MEM/cmspace/commission/automation_surveyed.tsv"
is  "session-start reads an answer keyed to its topology as answered, in a checkout whose path holds a space" \
    "$(_cm felix_commission_provider_state "$CSP" "$CSR" automation_surveyed | cut -f1)" "answered"
is  "and felix commission hashes the same topology there, so it reads the same answer as answered" \
    "$(_cm felix_commission_run "$CSP" "$CSR" - | awk -F'\t' '$1 == "automation_surveyed" { print $2 }')" "answered"
rm -rf "$CSP" "$MEM/cmspace" "$TMP/cm-ifs space"

