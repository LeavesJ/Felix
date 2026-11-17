# ---------------------------------------------------------------------------
# exceptions: the scoped exception channel (amendments §3). A grant is a row in
# projects/<name>/exceptions.tsv, read ONLY from refs/remotes/origin/main of
# the repository that holds the project directory — never the working tree,
# never a local branch a session could move — and only when that repository
# is the governed root itself. It clears one TASK_BLOCKING row at the task
# moment, keyed to the hash of the exact ledger line, bounded by an expiry
# that is ahead of now and inside a one-year horizon. Nothing here can clear
# a release, an authority hold, or a row nobody admitted.
#
# Written blind against the contract, before the implementation was read.
printf '\nexceptions: the scoped exception channel\n'
# _cdtopo and _cdepoch (tests/lib/candidates.sh) put CMSTUB first on PATH, and the
# seed assertion at the end reads the stranger project that felix new onboarded.
_cmstub_build; _stranger_build

_xc_row()    { local IFS=$'\t'; printf '%s\n' "$*"; }
_xc_hash()   { local l; l="$(awk -F'\t' -v n="$2" '$1==n{print; exit}' "$1")"
               printf '%s\n' "$l" | git hash-object --stdin; }
_xc_h12()    { _xc_hash "$1" "$2" | cut -c1-12; }
_xc_ci()     { ( _fx_cd "$1" && git add -A >/dev/null 2>&1 \
                 && git -c user.name=t -c user.email=t@t commit -qm "$2" >/dev/null 2>&1 ); }
_xc_origin() { git init -q --bare "$1.git" >/dev/null 2>&1 \
               && ( _fx_cd "$1" && git remote add origin "$1.git" && git push -q origin main \
                    && git fetch -q origin ) >/dev/null 2>&1; }
_xc_lib()    { . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"
               . "$FROOT/harness/lib/obligations.sh"; }
_xc_run()    { ( _xc_lib; felix_obligations_run "$@" ) 2>/dev/null; }
_xc_blk()    { ( _xc_lib; felix_obligations_blocking "$@" ) 2>/dev/null; }
_xc_ob()     { ( _xc_lib; "$@" ) 2>/dev/null; }
_xc_col()    { printf '%s\n' "$1" | awk -F'\t' -v n="$2" -v c="$3" '$1==n{print $c; exit}'; }
_xc_in()     { case " $1 " in *" $2 "*) return 0 ;; esac; return 1; }
_xc_skip()   { local why="$1"; shift; local a; for a in "$@"; do skip "$a" "$why"; done; }
# A self-governed home: the marker binds the home to its own project, the way
# $TMP/selfgoverned does. Written by a helper so the binding is built once,
# for a fixture, and not rewritten by hand anywhere below.
_xc_home()   { mkdir -p "$1/projects/$2" "$MEM/$2" "$1/harness"; _copy_content "$REAL_HARNESS" "$1/harness"
               printf '{ "name": "%s", "gate": "true" }\n' "$2" > "$1/projects/$2/project.json"
               printf '# %s\n' "$2" > "$1/projects/$2/CLAUDE.md"
               printf 'code\t-\t-\tgit ls-files\ttest -e .git\n' > "$1/projects/$2/probes.tsv"
               printf '%s\n' "$2" > "$1/${_XC_MARK}"; }
_XC_MARK=".felix"

# Stamps relative to the clock, so the fixture does not rot: inside the
# horizon and ahead of now, an earlier one still ahead of now, one past the
# horizon, and one long gone.
_XC_Y="$(date -u +%Y)"
XC_LIVE="$((_XC_Y+1))-06-01T00:00:00Z"
XC_SOON="$((_XC_Y+1))-03-01T00:00:00Z"
XC_FAR="$((_XC_Y+2))-01-01T00:00:00Z"
XC_OLD='2000-01-01T00:00:00Z'

# ------------------------------------------------ the self-governed home ----
# A Felix home that is itself a git repository with projects/x/ inside it and
# a real origin: the reader takes origin/main, so a home with no remote is
# the first negative case and the same home after push+fetch the positive one.
XH="$TMP/exc-home"; mkdir -p "$XH"; XH="$(cd "$XH" && pwd -P)"; _xc_home "$XH" x
XHL="$XH/projects/x/obligations.tsv"; XHX="$XH/projects/x/exceptions.tsv"
{
  printf '# the ledger the grants are keyed to\n'
  _xc_row t_clear   TASK_BLOCKING    deterministic -              false - 'the row a grant clears'
  _xc_row t_whole   TASK_BLOCKING    deterministic -              false - 'granted by the whole hash'
  _xc_row t_lapsed  TASK_BLOCKING    deterministic -              false - 'its grant has lapsed'
  _xc_row t_far     TASK_BLOCKING    deterministic -              false - 'its grant expires past the horizon'
  _xc_row t_stale   TASK_BLOCKING    deterministic -              false - 'its grant is keyed to another line'
  _xc_row t_nonl    TASK_BLOCKING    deterministic -              false - 'its grant is keyed to the line without its newline'
  _xc_row t_shout   TASK_BLOCKING    deterministic -              false - 'its grant carries an upper-case hash'
  _xc_row t_garbled TASK_BLOCKING    deterministic -              false - 'its grants do not parse'
  _xc_row t_tree    TASK_BLOCKING    deterministic -              false - 'its grant is written only in this tree'
  _xc_row t_asleep  TASK_BLOCKING    deterministic 'test -f nope' false - 'dormant, with a grant waiting'
  _xc_row t_hold    TASK_BLOCKING    unknown       -              false - 'an authority hold'
  _xc_row t_alone   TASK_BLOCKING    deterministic -              false - 'nothing names it'
  _xc_row t_inject  TASK_BLOCKING    deterministic - "printf 'A\\tB\\r\\texcepted|$XC_LIVE|x\\n'; exit 1" - 'its evidence prints tabs and a carriage return'
  _xc_row r_fails   RELEASE_BLOCKING deterministic -              false - 'release-blocking, and no grant may clear it'
} > "$XHL"
H12_CLEAR="$(_xc_h12 "$XHL" t_clear)"
{
  printf '# obligation\trow_hash\texpires\tgranted_by\treason\n\n'
  _xc_row t_clear   "$H12_CLEAR"                          "$XC_LIVE"          founder 'accepted for this epoch'
  _xc_row t_clear   "$H12_CLEAR"                          "$XC_SOON"          earlier 'a later row with an earlier expiry narrows the first'
  _xc_row t_whole   "$(_xc_h12 "$XHL" t_whole)"           "$XC_OLD"           lapsed  'an expired row above the live one'
  _xc_row t_whole   "$(_xc_hash "$XHL" t_whole)"          "$XC_LIVE"          whole   'the whole forty-character hash'
  _xc_row t_lapsed  "$(_xc_h12 "$XHL" t_lapsed)"          "$XC_OLD"           founder 'lapsed'
  _xc_row t_far     "$(_xc_h12 "$XHL" t_far)"             "$XC_FAR"           founder 'past the horizon'
  _xc_row t_stale   deadbeefdeadbeef                      "$XC_LIVE"          founder 'keyed to another line'
  _xc_row t_nonl    "$(awk -F'\t' '$1=="t_nonl"{print; exit}' "$XHL" | tr -d '\n' | git hash-object --stdin | cut -c1-12)" \
                                                          "$XC_LIVE"          founder 'hashed without the newline'
  _xc_row t_shout   "$(_xc_hash "$XHL" t_shout | tr 'a-f' 'A-F')" "$XC_LIVE"  founder 'upper-case hex'
  _xc_row t_garbled xyz                                   "$XC_LIVE"          founder 'a hash that is not hex'
  _xc_row t_garbled "$(_xc_h12 "$XHL" t_garbled)"         "${XC_LIVE%T*}"     founder 'a date without a time'
  _xc_row t_garbled "$(_xc_h12 "$XHL" t_garbled)"         9999-99-99T99:99:99Z founder 'the right shape, impossible values'
  _xc_row t_garbled "$(_xc_h12 "$XHL" t_garbled)"         "$XC_LIVE"          ''      'no grantor'
  _xc_row t_asleep  "$(_xc_h12 "$XHL" t_asleep)"          "$XC_LIVE"          founder 'granted while dormant'
  _xc_row t_hold    "$(_xc_h12 "$XHL" t_hold)"            "$XC_LIVE"          founder 'names an authority hold'
  _xc_row r_fails   "$(_xc_h12 "$XHL" r_fails)"           "$XC_LIVE"          founder 'names a release-blocking row'
  _xc_row ghost     abcdefabcdef                          "$XC_LIVE"          founder 'names nothing the ledger admits'
} > "$XHX"
( _fx_cd "$XH" && git init -q -b main ) >/dev/null 2>&1; _xc_ci "$XH" ledger
XRUN0="$(_xc_run "$XH/projects/x" "$XH")"
_xc_origin "$XH"

_XC_HOME_NAMES=(
  "every obligations run row carries eight columns"
  "a grant committed on local main with no remote clears nothing"
  "the same repository after push and fetch clears it, and among valid rows the earliest expiry wins"
  "the whole forty-character hash grants too, and an expired row above it does not shadow it"
  "a grant committed locally on top of the fetched main but not pushed clears nothing"
  "an expired grant clears nothing"
  "a grant expiring past the horizon clears nothing"
  "a grant keyed to another line's hash clears nothing"
  "a grant hashed over the line without its newline clears nothing"
  "an upper-case hash, a bad stamp or an empty grantor is no grant"
  "a grant naming a release-blocking obligation clears nothing"
  "a grant naming an unknown-pathway obligation clears nothing"
  "a grant on a dormant row is not applied"
  "a grant written only in the working tree clears nothing"
  "a grant that expired before the base commit is expired whatever the clock says"
  "an evidence line carrying tabs and a carriage return cannot forge the eighth column nor break the row"
  "at the task moment an excepted row does not block"
  "while the rows whose grants were refused or absent still do"
  "an authority hold on the unknown pathway blocks whatever the table says"
  "at release a task-blocking row is dropped and a release-blocking one blocks, grant or no grant"
  "a release-mode run carries no clearance in any row"
  "without lib/exceptions.sh every eighth column is a dash and every row is still reported"
  "felix obligations prints a row column carrying the ledger line's twelve-character hash"
  "an excepted row's detail names its expiry and grantor and keeps its discharge unsatisfied"
  "the summary counts the excepted rows"
  "the report heads the grants with the base ref and its commit date"
  "a live grant is listed live and a grant on a dormant row is listed armed"
  "each refused grant is listed with its reason"
  "rows written in this tree and not at origin/main are listed as not yet grants"
  "the admitted sentence now counts the grants"
  "felix obligations --gate still fails while unexcepted blocking rows remain"
  "deleting the table from the working tree does not revoke a grant at origin/main"
)
if git -C "$XH" rev-parse --verify -q refs/remotes/origin/main >/dev/null 2>&1 && [ -n "$H12_CLEAR" ]; then
  XRUN="$(_xc_run "$XH/projects/x" "$XH")"
  XBLK="$(printf '%s\n' "$XRUN" | _xc_blk | cut -f1 | tr '\n' ' ')"
  XREL="$(printf '%s\n' "$XRUN" | _xc_blk release | cut -f1 | tr '\n' ' ')"

  is  "every obligations run row carries eight columns" \
      "$(printf '%s\n' "$XRUN" | awk -F'\t' '{print NF}' | sort -u | tr '\n' ' ')" "8 "
  is  "a grant committed on local main with no remote clears nothing" "$(_xc_col "$XRUN0" t_clear 8)" "-"
  is  "the same repository after push and fetch clears it, and among valid rows the earliest expiry wins" \
      "$(printf '%s\n' "$XRUN" | awk -F'\t' '$1=="t_clear"{print $5 "|" $8; exit}')" "UNSATISFIED|excepted|$XC_SOON|earlier"
  is  "the whole forty-character hash grants too, and an expired row above it does not shadow it" \
      "$(_xc_col "$XRUN" t_whole 8)" "excepted|$XC_LIVE|whole"
  is  "an expired grant clears nothing"                          "$(_xc_col "$XRUN" t_lapsed 8)"  "-"
  is  "a grant expiring past the horizon clears nothing"         "$(_xc_col "$XRUN" t_far 8)"     "-"
  is  "a grant keyed to another line's hash clears nothing"      "$(_xc_col "$XRUN" t_stale 8)"   "-"
  is  "a grant hashed over the line without its newline clears nothing" "$(_xc_col "$XRUN" t_nonl 8)" "-"
  is  "an upper-case hash, a bad stamp or an empty grantor is no grant" \
      "$(_xc_col "$XRUN" t_shout 8)|$(_xc_col "$XRUN" t_garbled 8)" "-|-"
  is  "a grant naming a release-blocking obligation clears nothing" "$(_xc_col "$XRUN" r_fails 8)" "-"
  is  "a grant naming an unknown-pathway obligation clears nothing" "$(_xc_col "$XRUN" t_hold 8)"  "-"
  is  "a grant on a dormant row is not applied"                  "$(_xc_col "$XRUN" t_asleep 8)"  "-"

  # `now` is the later of the clock and the base commit's date. A date shim
  # that answers 1999 to the stamp question cannot revive a grant that
  # expired in 2000, because origin/main was committed today.
  XSHIM="$TMP/exc-shim"; mkdir -p "$XSHIM"
  printf '#!/bin/sh\ncase "$*" in *"%%Y-%%m-%%dT%%H:%%M:%%SZ"*) printf "1999-01-01T00:00:00Z\\n" ;; *) exec /bin/date "$@" ;; esac\n' > "$XSHIM/date"
  chmod +x "$XSHIM/date"
  is  "a grant that expired before the base commit is expired whatever the clock says" \
      "$(_xc_col "$(PATH="$XSHIM:$PATH" _xc_run "$XH/projects/x" "$XH")" t_lapsed 8)" "-"

  # The detail column is what an evidence command last printed. Tabs in it
  # would shift the columns and let the command write its own clearance.
  is  "an evidence line carrying tabs and a carriage return cannot forge the eighth column nor break the row" \
      "$(printf '%s\n' "$XRUN" | awk -F'\t' '$1=="t_inject"{print NF "|" $8; exit}')|$(printf '%s' "$XRUN" | tr -dc '\r' | wc -c | tr -d ' ')" "8|-|0"

  if ! _xc_in "$XBLK" t_clear && ! _xc_in "$XBLK" t_whole; then ok "at the task moment an excepted row does not block"
  else bad "at the task moment an excepted row does not block" "blocking: [$XBLK]"; fi
  _m=""; for _n in t_alone t_lapsed t_far t_stale t_nonl t_tree t_inject; do _xc_in "$XBLK" "$_n" || _m="$_m $_n"; done
  [ -z "$_m" ] && ok  "while the rows whose grants were refused or absent still do" \
               || bad "while the rows whose grants were refused or absent still do" "not emitted:$_m in [$XBLK]"
  _xc_in "$XBLK" t_hold && ok  "an authority hold on the unknown pathway blocks whatever the table says" \
                        || bad "an authority hold on the unknown pathway blocks whatever the table says" "blocking: [$XBLK]"
  if ! _xc_in "$XREL" t_clear && ! _xc_in "$XREL" t_alone && _xc_in "$XREL" r_fails; then
    ok  "at release a task-blocking row is dropped and a release-blocking one blocks, grant or no grant"
  else
    bad "at release a task-blocking row is dropped and a release-blocking one blocks, grant or no grant" "release: [$XREL]"
  fi
  is  "a release-mode run carries no clearance in any row" \
      "$(_xc_run "$XH/projects/x" "$XH" release | cut -f8 | sort -u | tr '\n' ' ')" "- "

  # A harness copy without the library withholds every clearance and does
  # not crash: fourteen rows, fourteen dashes.
  XL="$TMP/exc-nolib"; mkdir -p "$XL"; cp -R "$FROOT/harness" "$XL/harness"
  rm -f "$XL/harness/lib/exceptions.sh"
  is  "without lib/exceptions.sh every eighth column is a dash and every row is still reported" \
      "$( ( export FELIX_HOME="$XL"; . "$XL/harness/lib/resolve.sh"; . "$XL/harness/lib/probes.sh"
            . "$XL/harness/lib/obligations.sh"; felix_obligations_run "$XH/projects/x" "$XH" ) 2>/dev/null \
          | awk -F'\t' '{print $8}' | sort | uniq -c | tr -s ' ' | tr '\n' ' ')" " 14 - "

  # Grants written after the fetch: one committed on local main and not
  # pushed, one not even committed. Neither is at origin/main.
  _xc_row t_alone "$(_xc_h12 "$XHL" t_alone)" "$XC_LIVE" founder 'committed locally, never pushed' >> "$XHX"
  _xc_ci "$XH" local
  _xc_row t_tree  "$(_xc_h12 "$XHL" t_tree)"  "$XC_LIVE" founder 'written in the tree, never committed' >> "$XHX"
  XRUN3="$(_xc_run "$XH/projects/x" "$XH")"
  is  "a grant committed locally on top of the fetched main but not pushed clears nothing" "$(_xc_col "$XRUN3" t_alone 8)" "-"
  is  "a grant written only in the working tree clears nothing" "$(_xc_col "$XRUN3" t_tree 8)" "-"

  # A surveyed answer under the memory root, written the way the widget's is,
  # so the report below prints its candidates section and the footer that
  # counts the grants. Keyed with the candidates section's _cdtopo and
  # _cdepoch to the tree as it stands after the two rows above, because that
  # is the tree the report reads; one ADVISORY row, grounded on the one probe
  # this project declares and named so that no grep below can take it for a
  # ledger row or a grant. A key that drifted would leave the answer stale and
  # record nothing, but the footer would still print, which is why the
  # assertion below pins the grants and not the discovered count. The memory
  # root is outside the home's repository, so nothing here moves origin/main
  # or the working tree the grants are judged against.
  XHANS="$MEM/x/commission/obligations_surveyed.tsv"; mkdir -p "$MEM/x/commission"
  { printf '# topology %s\n# epoch %s\n' "$(_cdtopo "$XH/projects/x" "$XH")" "$(_cdepoch "$XH/projects/x" "$XH")"
    _xc_row surveyed_once ADVISORY - true code uncounted 'a survey, so the report prints the footer that counts grants'
    printf 'done\t1\n'; } > "$XHANS"

  # The CLI, inside the governed home.
  XOUT="$(cd "$XH" && FELIX_HOME="$XH" "$XH/harness/felix" obligations 2>&1)"
  case "$XOUT" in
    *ROW*"$H12_CLEAR"*|*"$H12_CLEAR"*ROW*) ok "felix obligations prints a row column carrying the ledger line's twelve-character hash" ;;
    *) bad "felix obligations prints a row column carrying the ledger line's twelve-character hash" "$XOUT" ;;
  esac
  if grep -F 't_clear' <<<"$XOUT" | grep -Fq 'UNSATISFIED' \
     && grep -Fq "excepted until $XC_SOON by earlier" <<<"$XOUT"; then
    ok  "an excepted row's detail names its expiry and grantor and keeps its discharge unsatisfied"
  else
    bad "an excepted row's detail names its expiry and grantor and keeps its discharge unsatisfied" "$XOUT"
  fi
  case "$XOUT" in
    *"14 obligation(s): "*", 2 excepted"*) ok "the summary counts the excepted rows" ;;
    *) bad "the summary counts the excepted rows" "$(printf '%s\n' "$XOUT" | grep 'obligation(s)')" ;;
  esac
  case "$XOUT" in
    *"exceptions at origin/main ("*"): 12 granted"*) ok "the report heads the grants with the base ref and its commit date" ;;
    *) bad "the report heads the grants with the base ref and its commit date" "$(printf '%s\n' "$XOUT" | grep 'exceptions at')" ;;
  esac
  if grep -F 't_clear' <<<"$XOUT" | grep -Fq 'live' \
     && grep -F 't_asleep' <<<"$XOUT" | grep -Fq 'armed'; then
    ok  "a live grant is listed live and a grant on a dormant row is listed armed"
  else
    bad "a live grant is listed live and a grant on a dormant row is listed armed" "$XOUT"
  fi
  _m=""
  while IFS='|' read -r _n _r; do
    grep -F "$_n" <<<"$XOUT" | grep -F 'refused' | grep -Fq "$_r" || _m="$_m $_n"
  done <<'REASONS'
t_lapsed|expired
t_far|expires past the horizon
t_stale|keyed to a row that has since changed
t_nonl|keyed to a row that has since changed
r_fails|names a RELEASE_BLOCKING obligation, which no exception may clear
t_hold|names an authority hold, which no exception may clear
ghost|names an obligation the ledger does not admit
REASONS
  [ -z "$_m" ] && ok  "each refused grant is listed with its reason" \
               || bad "each refused grant is listed with its reason" "not refused as stated:$_m"
  _t="$(printf '%s\n' "$XOUT" | sed -n '/written in this tree and not at origin\/main, so not yet a grant:/,$p')"
  case "$_t" in
    *t_alone*t_tree*|*t_tree*t_alone*) ok "rows written in this tree and not at origin/main are listed as not yet grants" ;;
    *) bad "rows written in this tree and not at origin/main are listed as not yet grants" "$XOUT" ;;
  esac
  # The discovered/admitted sentence is the candidates section's footer, and
  # the report prints that section only when a surveyed answer or
  # candidates.tsv exists under the memory root. From #261 until the answer
  # written above, this fixture had neither, and the claim sat behind a branch
  # that skipped whenever the sentence was absent: that was every run, so the
  # granted count went untested and was the suite's one standing skip. It is
  # decided every run now, and a sentence that stops printing fails here.
  # Twelve is what origin/main holds: seventeen rows in the table above, less
  # the five that are no grant at all (the upper-case hash and t_garbled's
  # four), the same twelve the heading states. The full stop after it keeps
  # 120 from reading as 12.
  grep -Eq 'discovered [0-9]+, admitted [0-9]+, granted 12\.' <<<"$XOUT" \
    && ok  "the admitted sentence now counts the grants" \
    || bad "the admitted sentence now counts the grants" \
           "$(printf '%s\n' "$XOUT" | grep 'discovered' || printf 'the report printed no discovered/admitted sentence')"
  ( cd "$XH" && FELIX_HOME="$XH" "$XH/harness/felix" obligations --gate >/dev/null 2>&1 ); _rc=$?
  [ "$_rc" -ne 0 ] && ok  "felix obligations --gate still fails while unexcepted blocking rows remain" \
                   || bad "felix obligations --gate still fails while unexcepted blocking rows remain" "exit 0"

  rm -f "$XHX"
  is  "deleting the table from the working tree does not revoke a grant at origin/main" \
      "$(_xc_col "$(_xc_run "$XH/projects/x" "$XH")" t_clear 8)" "excepted|$XC_SOON|earlier"
else
  _xc_skip "the self-governed home with an origin could not be built" "${_XC_HOME_NAMES[@]}"
fi

# ---------------------------------------------- where the reader will not look
# A side branch, even one pushed to the origin; a project directory outside
# any repository; a project directory that is the repository root; a home that
# is a repository other than the governed root.
XB="$TMP/exc-branch"; mkdir -p "$XB/projects/b"; XB="$(cd "$XB" && pwd -P)"
_xc_row b_task TASK_BLOCKING deterministic - false - 'granted on a side branch only' > "$XB/projects/b/obligations.tsv"
( _fx_cd "$XB" && git init -q -b main ) >/dev/null 2>&1; _xc_ci "$XB" base; _xc_origin "$XB"
( _fx_cd "$XB" && git checkout -q -b side ) >/dev/null 2>&1
_xc_row b_task "$(_xc_h12 "$XB/projects/b/obligations.tsv" b_task)" "$XC_LIVE" founder 'side' > "$XB/projects/b/exceptions.tsv"
_xc_ci "$XB" side; ( _fx_cd "$XB" && git push -q origin side ) >/dev/null 2>&1
if git -C "$XB" rev-parse --verify -q refs/remotes/origin/side >/dev/null 2>&1; then
  is  "a grant committed only on a side branch clears nothing even once the origin holds that branch" \
      "$(_xc_col "$(_xc_run "$XB/projects/b" "$XB")" b_task 8)" "-"
else
  skip "a grant committed only on a side branch clears nothing even once the origin holds that branch" "the branch fixture could not be built"
fi

XN="$TMP/exc-nogit"; mkdir -p "$XN/projects/n"
_xc_row n_task TASK_BLOCKING deterministic - false - 'granted outside any repository' > "$XN/projects/n/obligations.tsv"
_xc_row n_task "$(_xc_h12 "$XN/projects/n/obligations.tsv" n_task)" "$XC_LIVE" founder 'no repository' > "$XN/projects/n/exceptions.tsv"
XR="$TMP/exc-rootproj"; mkdir -p "$XR"; XR="$(cd "$XR" && pwd -P)"
_xc_row r_task TASK_BLOCKING deterministic - false - 'the project is the repository root' > "$XR/obligations.tsv"
_xc_row r_task "$(_xc_h12 "$XR/obligations.tsv" r_task)" "$XC_LIVE" founder 'at the root' > "$XR/exceptions.tsv"
( _fx_cd "$XR" && git init -q -b main ) >/dev/null 2>&1; _xc_ci "$XR" root; _xc_origin "$XR"
if git -C "$XR" rev-parse --verify -q refs/remotes/origin/main >/dev/null 2>&1; then
  is  "a project directory outside any repository, or one that is itself the repository root, grants nothing" \
      "$(_xc_col "$(_xc_run "$XN/projects/n" "$XN")" n_task 8)|$(_xc_col "$(_xc_run "$XR" "$XR")" r_task 8)" "-|-"
else
  skip "a project directory outside any repository, or one that is itself the repository root, grants nothing" "the root fixture could not be built"
fi

XK="$TMP/exc-otherhome"; mkdir -p "$XK/projects/k"; XK="$(cd "$XK" && pwd -P)"
XKR="$TMP/exc-otherroot"; mkdir -p "$XKR"; XKR="$(cd "$XKR" && pwd -P)"
_xc_row k_task TASK_BLOCKING deterministic - false - 'granted in a home that is not the root' > "$XK/projects/k/obligations.tsv"
_xc_row k_task "$(_xc_h12 "$XK/projects/k/obligations.tsv" k_task)" "$XC_LIVE" founder 'another repository' > "$XK/projects/k/exceptions.tsv"
( _fx_cd "$XK" && git init -q -b main ) >/dev/null 2>&1; _xc_ci "$XK" home; _xc_origin "$XK"
( _fx_cd "$XKR" && git init -q -b main && printf 'x\n' > x ) >/dev/null 2>&1; _xc_ci "$XKR" root
if git -C "$XK" rev-parse --verify -q refs/remotes/origin/main >/dev/null 2>&1; then
  is  "a grant under a home that is a different repository from the governed root clears nothing" \
      "$(_xc_col "$(_xc_run "$XK/projects/k" "$XKR")" k_task 8)" "-"
else
  skip "a grant under a home that is a different repository from the governed root clears nothing" "the other-home fixture could not be built"
fi

# The widget's home is $FROOT, no repository at all, so a row written there is
# not read and the report says so. Restored afterwards, because every later
# assertion reads that project.
if [ -f "$FROOT/projects/widget/exceptions.tsv" ]; then cp "$FROOT/projects/widget/exceptions.tsv" "$TMP/exceptions.keep"; fi
_xc_row fixture "$(_xc_h12 "$FROOT/projects/widget/obligations.tsv" fixture)" "$XC_LIVE" founder 'not in any repository' \
  > "$FROOT/projects/widget/exceptions.tsv"
out="$(cd "$REPO" && "$FELIX" obligations 2>&1)"
if grep -Fq 'exceptions: not read for this project.' <<<"$out" \
   && grep -Eq '[0-9]+ obligation\(s\): [0-9]+ active, [0-9]+ dormant, [0-9]+ unknown; [0-9]+ blocking, [0-9]+ excepted' <<<"$out"; then
  ok  "a home that is no repository has its grants unread, and the widget report says so under the new summary"
else
  bad "a home that is no repository has its grants unread, and the widget report says so under the new summary" "$out"
fi
if [ -f "$TMP/exceptions.keep" ]; then mv "$TMP/exceptions.keep" "$FROOT/projects/widget/exceptions.tsv"
else rm -f "$FROOT/projects/widget/exceptions.tsv"; fi

# ------------------------------------------------------- the ledger scan ----
XD="$TMP/exc-dup"; mkdir -p "$XD"
{ _xc_row twice TASK_BLOCKING deterministic - false - first
  _xc_row twice TASK_BLOCKING deterministic - false - second; } > "$XD/obligations.tsv"
is  "a name admitted twice is refused the second time and admitted once" \
    "$(_xc_ob felix_obligation_rows "$XD" | cut -f7 | tr '\n' ' ')|$(_xc_ob felix_obligation_malformed "$XD" | grep -c 'admitted twice')" "first |1"

# ------------------------------------------- the gate, on a clean fixture ----
# One row, excepted at origin/main, and nothing else owed: the gate passes,
# says so in its own line shape, and the exception is written down.
XC="$TMP/exc-clean"; mkdir -p "$XC"; XC="$(cd "$XC" && pwd -P)"; _xc_home "$XC" c
_xc_row c_task TASK_BLOCKING deterministic - false - 'the one row, excepted' > "$XC/projects/c/obligations.tsv"
_xc_row c_task "$(_xc_h12 "$XC/projects/c/obligations.tsv" c_task)" "$XC_LIVE" founder 'accepted' > "$XC/projects/c/exceptions.tsv"
( _fx_cd "$XC" && git init -q -b main ) >/dev/null 2>&1; _xc_ci "$XC" clean; _xc_origin "$XC"
if git -C "$XC" rev-parse --verify -q refs/remotes/origin/main >/dev/null 2>&1; then
  out="$(cd "$XC" && FELIX_HOME="$XC" "$XC/harness/felix" obligations --gate 2>&1)"; _rc=$?
  if [ "$_rc" -eq 0 ] && grep -F "$(printf '\texcepted\t')" "$MEM/c/says.log" 2>/dev/null \
       | grep -Fq "c_task: excepted until $XC_LIVE by founder"; then
    ok  "felix obligations --gate passes when its only blocking row is excepted, and writes the exception to says.log"
  else
    bad "felix obligations --gate passes when its only blocking row is excepted, and writes the exception to says.log" \
        "exit $_rc; says.log: $(cat "$MEM/c/says.log" 2>/dev/null); out: $out"
  fi
  out="$(cd "$XC" && FELIX_HOME="$XC" "$XC/harness/felix" gate 2>&1)"; _rc=$?
  case "$_rc:$out" in
    0:*"  obligations        excepted"*) ok "the gate's obligations line reads excepted and the gate passes" ;;
    *) bad "the gate's obligations line reads excepted and the gate passes" "exit $_rc: $out" ;;
  esac
else
  _xc_skip "the clean home with an origin could not be built" \
    "felix obligations --gate passes when its only blocking row is excepted, and writes the exception to says.log" \
    "the gate's obligations line reads excepted and the gate passes"
fi

# --------------------------------------------------------------- escape ----
# The table IS the grant, so any change to it between base and head goes to
# a person: the same shape as the authority channel one file over.
XE="$TMP/exc-escape"; mkdir -p "$XE"; XE="$(cd "$XE" && pwd -P)"
( _fx_cd "$XE" && git init -q -b main && printf 'notes\n' > README.md ) >/dev/null 2>&1; _xc_ci "$XE" base
_xc_esc()   { ( cd "$XE" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/escape.sh"
                . "$FROOT/harness/lib/obligations.sh"; felix_escapes "$FROOT/projects/widget" HEAD~1 "$XE" ) 2>/dev/null; }
# The rows are read whole before grep sees them. Piped, a grep -q that matched
# early could break felix_escapes' pipe under pipefail, and the ! in _xc_quiet
# would read that broken pipe as quiet.
_xc_fired() { local _o; _o="$(_xc_esc)"; grep -q "^exception$(printf '\t')$1" <<<"$_o"; }
_xc_quiet() { local _o; _o="$(_xc_esc)"; ! grep -q "^exception$(printf '\t')" <<<"$_o"; }
if git -C "$XE" rev-parse --verify -q HEAD >/dev/null 2>&1; then
  mkdir -p "$XE/projects/x"; printf '# seeded\n' > "$XE/projects/x/exceptions.tsv"; _xc_ci "$XE" create
  _xc_fired projects/x/exceptions.tsv && ok  "creating a project's exceptions table escapes on the exception channel" \
                                      || bad "creating a project's exceptions table escapes on the exception channel" "$(_xc_esc)"
  _m=""
  _xc_row a deadbeefdead "$XC_LIVE" founder r >> "$XE/projects/x/exceptions.tsv"; _xc_ci "$XE" row
  _xc_fired projects/x/exceptions.tsv || _m="$_m added-row"
  printf '# another comment\n' >> "$XE/projects/x/exceptions.tsv"; _xc_ci "$XE" comment
  _xc_fired projects/x/exceptions.tsv || _m="$_m comment-edit"
  rm -f "$XE/projects/x/exceptions.tsv"; _xc_ci "$XE" delete
  _xc_fired projects/x/exceptions.tsv || _m="$_m deletion"
  [ -z "$_m" ] && ok  "so do an added row, a comment edit and a deletion" \
               || bad "so do an added row, a comment edit and a deletion" "silent on:$_m"
  _m=""
  mkdir -p "$XE/notes"; printf 'a\tb\n' > "$XE/notes/exceptions.tsv"; _xc_ci "$XE" elsewhere
  _xc_quiet || _m="$_m notes/exceptions.tsv"
  mkdir -p "$XE/projects/x/sub"; printf '#\n' > "$XE/projects/x/sub/exceptions.tsv"; _xc_ci "$XE" deeper
  _xc_quiet || _m="$_m projects/x/sub/exceptions.tsv"
  [ -z "$_m" ] && ok  "a file named exceptions.tsv elsewhere or deeper than projects/<p>/ does not fire it" \
               || bad "a file named exceptions.tsv elsewhere or deeper than projects/<p>/ does not fire it" "fired on:$_m"
else
  _xc_skip "the escape fixture could not be built" \
    "creating a project's exceptions table escapes on the exception channel" \
    "so do an added row, a comment edit and a deletion" \
    "a file named exceptions.tsv elsewhere or deeper than projects/<p>/ does not fire it"
fi

# ------------------------------------------------------------ the hold ----
# The Stop hook's hold on an unverified tree now says where the exception
# lives and that the session cannot write itself one. The checkout is bound
# to the widget the way $GREPO is, by the marker alone.
XS="$TMP/exc-stop"; mkdir -p "$XS"; XS="$(cd "$XS" && pwd -P)"
( _fx_cd "$XS" && git init -q -b main && printf 'contents\n' > WIDGET.txt && printf 'widget\n' > "${_XC_MARK}" ) >/dev/null 2>&1
_xc_ci "$XS" init
if [ -x "$FROOT/harness/hooks/stop" ] && git -C "$XS" rev-parse --verify -q HEAD >/dev/null 2>&1; then
  printf 'unverified\n' >> "$XS/WIDGET.txt"
  out="$(cd "$XS" && printf '%s' '{"hook_event_name":"Stop","stop_hook_active":false}' | "$FROOT/harness/hooks/stop" 2>&1)"
  case "$out" in
    *'"decision"'*'"block"'*"a row in the project's exceptions.tsv"*"a session cannot grant itself one"*|\
    *'"decision"'*'"block"'*"a session cannot grant itself one"*"a row in the project's exceptions.tsv"*)
      ok  "a hold on an unverified tree names the exceptions table and says a session cannot grant itself one" ;;
    *) bad "a hold on an unverified tree names the exceptions table and says a session cannot grant itself one" "$out" ;;
  esac
else
  skip "a hold on an unverified tree names the exceptions table and says a session cannot grant itself one" "no stop hook beside this harness"
fi

# ---------------------------------------------------------- the seed ----
_xc_rows() { grep -cv '^[[:space:]]*\(#\|$\)' "$1" 2>/dev/null | tr -d ' '; }
if [ -f "$FROOT/harness/templates/exceptions.tsv" ] && grep -q 'row_hash' "$FROOT/harness/templates/exceptions.tsv" \
   && [ "$(_xc_rows "$FROOT/harness/templates/exceptions.tsv")" = "0" ]; then
  ok  "the exceptions template names the row hash column and holds no rows"
else
  bad "the exceptions template names the row hash column and holds no rows" "$(cat "$FROOT/harness/templates/exceptions.tsv" 2>/dev/null)"
fi
if [ -d "$FROOT/projects/stranger" ]; then
  if [ -f "$FROOT/projects/stranger/exceptions.tsv" ] && [ "$(_xc_rows "$FROOT/projects/stranger/exceptions.tsv")" = "0" ]; then
    ok  "felix new seeds an exceptions table of comment lines only"
  else
    bad "felix new seeds an exceptions table of comment lines only" "$(cat "$FROOT/projects/stranger/exceptions.tsv" 2>/dev/null)"
  fi
else
  skip "felix new seeds an exceptions table of comment lines only" "no stranger project seeded by felix new before this point"
fi

