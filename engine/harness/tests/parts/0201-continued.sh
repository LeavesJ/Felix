# Gaining refs is not moving: a concurrent fetch does it. Nor is a config
# write that leaves every url and pushurl as it was, which makes the guard
# re-read mid-run and must leave no C7 record.
_gitproof_build; _gitproof_kid_same
_gp_gain="$_gp/stand-gain"; _gp_build "$_gp_gain" spare
_gp_kid gain 1 <<'GPKID'
ok "gp child: an assertion before the stand-in gains refs"
sleep 1
_gpk_git update-ref refs/remotes/origin/gp-extra refs/remotes/origin/main
_gpk_git update-ref refs/remotes/spare/main refs/remotes/origin/main
_gpk_git config gp.touched yes
ok "gp child: an assertion after the stand-in gains refs"
[ -e "$TMP/origin-moved" ] && cp "$TMP/origin-moved" "$GP_OUT/origin-moved"
true
GPKID
_gp_run gain "$_gp_gain/sub" "$_gp_gain"
if [ -z "$(git -C "$_gp_gain" for-each-ref refs/remotes/spare/main refs/remotes/origin/gp-extra 2>/dev/null | sed -n 2p)" ] \
   || [ "$(git -C "$_gp_gain" config --get gp.touched 2>/dev/null)" != yes ]; then
  bad "a remote that gained refs, and a config write that moved no url, read as not moved" \
      "not exercised: the stand-in did not gain the refs and the key [$(cat "$_gp/kid/gain/kid.err" 2>/dev/null)]"
elif _gp_has gain "  ok    $_gp_c8" && [ ! -e "$_gp/kid/gain/origin-moved" ] && [ "$(_gp_rc gain)" = 0 ]; then
  ok  "a remote that gained refs, and a config write that moved no url, read as not moved"
else
  bad "a remote that gained refs, and a config write that moved no url, read as not moved" \
      "status [$(_gp_rc gain)]; C8 said: $(grep -F -- "$_gp_c8" "$_gp/kid/gain/out" | tr '\n' ' ')C7 record: $(tr '\n' ' ' 2>/dev/null < "$_gp/kid/gain/origin-moved")"
fi

# A changed URL, twice. C8 fails naming the config, both states and C7's
# record. C7 recorded the first move only, between the assertions on either
# side of it. Because C5 and C8 ran, the trap adds nothing and keeps the 0 the
# tail exits with.
_gitproof_kid_url
_gp_d="$(_gp_detail url "$_gp_c8")"
if [ "$(git -C "$_gp_url1" config --get remote.origin.url 2>/dev/null)" != "https://example.invalid/gp/moved-again.git" ]; then
  _gp_x="not exercised: the stand-in's origin was not moved [$(cat "$_gp/kid/url/kid.err" 2>/dev/null)]"
  bad "a changed URL fails the origin check, naming the config, the URL before and the URL now" "$_gp_x"
  bad "the origin check's detail carries C7's record of where in the run the remote moved" "$_gp_x"
  bad "C7 records the assertion before the move and the assertion after it, and the stand-in's config" "$_gp_x"
  bad "C7 writes one record, at the first move, with the state before and the state then" "$_gp_x"
else
  if _gp_has url "  FAIL  $_gp_c8" && case "$_gp_d" in *"$_gp_url"*) true ;; *) false ;; esac \
     && case "$_gp_d" in *moved-again.git*) true ;; *) false ;; esac \
     && case "$_gp_d" in *stand-url/.git/config*) true ;; *) false ;; esac; then
    ok  "a changed URL fails the origin check, naming the config, the URL before and the URL now"
  else
    bad "a changed URL fails the origin check, naming the config, the URL before and the URL now" \
        "C8 said: $(grep -F -- "$_gp_c8" "$_gp/kid/url/out" | tr '\n' ' ')detail: $(printf '%s' "$_gp_d" | tr '\n' ' ')"
  fi
  has "the origin check's detail carries C7's record of where in the run the remote moved" \
      "$_gp_d" "gp child: the first assertion after the remote moves"
  _gp_h="$(head -1 "$_gp/kid/url/origin-moved" 2>/dev/null)"
  _gp_t="$(printf '%s' "$_gp_h" | cut -f1)"; _gp_p="$(printf '%s' "$_gp_h" | cut -f4)"
  if [ "$(printf '%s' "$_gp_h" | cut -f2-3)" = "$(printf '%s\t%s' "gp child: an assertion before the remote moves" "gp child: the first assertion after the remote moves")" ] \
     && case "$_gp_t" in *[0-9]*) true ;; *) false ;; esac && _gp_samecfg "$_gp_p" "$_gp_url1"; then
    ok  "C7 records the assertion before the move and the assertion after it, and the stand-in's config"
  else
    bad "C7 records the assertion before the move and the assertion after it, and the stand-in's config" \
        "the record's first line is [$(printf '%s' "$_gp_h" | tr '\t' '|')]"
  fi
  _gp_b="$(awk '/^before:/ { f = 1 } /^now:/ { f = 0 } f' "$_gp/kid/url/origin-moved" 2>/dev/null)"
  _gp_w="$(awk '/^now:/ { f = 1 } f' "$_gp/kid/url/origin-moved" 2>/dev/null)"
  if [ "$(grep -c '^before:' "$_gp/kid/url/origin-moved" 2>/dev/null)" = 1 ] && [ "$(grep -c '^now:' "$_gp/kid/url/origin-moved" 2>/dev/null)" = 1 ] \
     && case "$_gp_b" in *"$_gp_url"*) true ;; *) false ;; esac \
     && case "$_gp_w" in *gp/moved.git*) true ;; *) false ;; esac \
     && case "$_gp_w" in *moved-again*) false ;; *) true ;; esac; then
    ok  "C7 writes one record, at the first move, with the state before and the state then"
  else
    bad "C7 writes one record, at the first move, with the state before and the state then" \
        "the record reads: $(tr '\t\n' '| ' 2>/dev/null < "$_gp/kid/url/origin-moved")"
  fi
fi
if _gp_has url "  FAIL  $_gp_c8" && [ "$(_gp_rc url)" = 0 ] && [ "$(_gp_err url 'tests/run: remotes moved while this run ran: ')" = 0 ]; then
  ok  "when C5 and C8 ran, the trap reports nothing more and keeps the run's status"
else
  bad "when C5 and C8 ran, the trap reports nothing more and keeps the run's status" \
      "C8 failed: $(_gp_has url "  FAIL  $_gp_c8" && echo yes || echo no); status [$(_gp_rc url)]; stderr: $(head -3 "$_gp/kid/url/err" | tr '\n' ' ')"
fi
if grep -q 'this run moved' "$_gp/kid/url/out" "$_gp/kid/url/err" 2>/dev/null; then
  bad "the origin check says the remotes moved while the run ran, never that the run moved them" \
      "$(grep -h 'this run moved' "$_gp/kid/url/out" "$_gp/kid/url/err" | head -2 | tr '\n' ' ')"
elif _gp_has url "  FAIL  $_gp_c8"; then
  ok  "the origin check says the remotes moved while the run ran, never that the run moved them"
else
  bad "the origin check says the remotes moved while the run ran, never that the run moved them" "the origin check did not fail"
fi

# The incident's own shape: origin removed and added back with the same URL.
# The url entries read the same; the refs are gone, and that is a move.
_gp_readd="$_gp/stand-readd"; _gp_build "$_gp_readd"
_gp_kid readd 1 <<'GPKID'
ok "gp child: an assertion before the remote is removed and added back"
_gpk_git remote remove origin
_gpk_git remote add origin https://example.invalid/gp/stand-in.git
ok "gp child: an assertion after the remote is removed and added back"
true
GPKID
_gp_run readd "$_gp_readd/sub" "$_gp_readd"
if [ "$(_gp_state "$_gp_readd" | sed -n 1,2p)" != "$(printf 'url %s\nrefs 0' "$_gp_url")" ]; then
  bad "a remote removed and added back with the same URL, its refs gone, fails the origin check" \
      "not exercised: the stand-in reads [$(_gp_state "$_gp_readd" | tr '\n' ' ')]"
elif _gp_has readd "  FAIL  $_gp_c8"; then
  ok  "a remote removed and added back with the same URL, its refs gone, fails the origin check"
else
  bad "a remote removed and added back with the same URL, its refs gone, fails the origin check" \
      "C8 said: $(grep -F -- "$_gp_c8" "$_gp/kid/readd/out" | tr '\n' ' ')"
fi

# A renamed remote, in a section runner whose harness copy sits inside the
# stand-in it starts in: both ends of the watch name one config, which is
# watched once. The trap turns the 0 the runner ends with into 1, and reports
# once. Subshells, which the body runs after the move, do not run it.
_gp_ren="$_gp/stand-rename"; _gp_build "$_gp_ren"; _copy_content "$_gp_harness" "$_gp_ren/harness"
_gp_kid rename 0 <<'GPKID'
ok "gp child: an assertion before the remote is renamed"
_gpk_git remote rename origin upstream
( : ); _gpk_x="$( : )"
ok "gp child: an assertion after the remote is renamed"
true
GPKID
_gp_run rename "$_gp_ren/sub" "$_gp_ren" "$_gp_ren/harness"
_gp_x="$(grep '^tests/run: remotes moved while this run ran: ' "$_gp/kid/rename/err" 2>/dev/null)"
if [ -z "$(git -C "$_gp_ren" config --get remote.upstream.url 2>/dev/null)" ]; then
  _gp_y="not exercised: the stand-in's origin was not renamed [$(cat "$_gp/kid/rename/kid.err" 2>/dev/null)]"
  bad "a section runner whose remote was renamed exits 1, not 0" "$_gp_y"
  bad "its trap reports once on stderr, first line tests/run:, naming the watched config" "$_gp_y"
else
  is  "a section runner whose remote was renamed exits 1, not 0" "$(_gp_rc rename)" 1
  if [ "$(head -1 "$_gp/kid/rename/err" | cut -c1-10)" = "tests/run:" ] && [ "$(_gp_err rename 'tests/run: remotes moved while this run ran: ')" = 1 ] \
     && _gp_samecfg "${_gp_x#tests/run: remotes moved while this run ran: }" "$_gp_ren"; then
    ok  "its trap reports once on stderr, first line tests/run:, naming the watched config"
  else
    bad "its trap reports once on stderr, first line tests/run:, naming the watched config" "stderr: $(head -5 "$_gp/kid/rename/err" | tr '\n' ' ')"
  fi
fi
if grep -q 'this run moved' "$_gp/kid/rename/err" 2>/dev/null; then
  bad "the trap says the remotes moved while the run ran, never that the run moved them" "$(grep 'this run moved' "$_gp/kid/rename/err" | head -1)"
elif [ -n "$_gp_x" ]; then
  ok  "the trap says the remotes moved while the run ran, never that the run moved them"
else
  bad "the trap says the remotes moved while the run ran, never that the run moved them" "the trap reported no move"
fi
# A control: the trap goes on removing $TMP, red or green.
if _gp_gone rename; then ok "a red section runner's trap still removes its temporary directory"
else bad "a red section runner's trap still removes its temporary directory" "[$(cat "$_gp/kid/rename/tmp" 2>/dev/null)] is still there"; fi

# A push URL added, in a section runner that exits 7 of its own accord: the
# trap reports the move and keeps the 7.
_gp_push="$_gp/stand-push"; _gp_build "$_gp_push"
_gp_kid push 0 <<'GPKID'
ok "gp child: an assertion before the remote gains a push URL"
_gpk_git remote set-url --push origin https://example.invalid/gp/push.git
ok "gp child: an assertion after the remote gains a push URL"
exit 7
GPKID
_gp_run push "$_gp_push/sub" "$_gp_push"
if [ -z "$(git -C "$_gp_push" config --get remote.origin.pushurl 2>/dev/null)" ]; then
  bad "a section runner exiting 7 whose remote gained a push URL keeps 7, and its trap reports the move" \
      "not exercised: the stand-in has no push URL [$(cat "$_gp/kid/push/kid.err" 2>/dev/null)]"
else
  is  "a section runner exiting 7 whose remote gained a push URL keeps 7, and its trap reports the move" \
      "$(_gp_rc push)|$(_gp_err push 'tests/run: remotes moved while this run ran: ')" "7|1"
fi

# Refusals at the end of a run. The child calls _fx_cd from its own top level
# on a directory under its $TMP, which only the top-level rule refuses, then
# from a subshell sent to /dev/null on "/". With C5 cut in, C5 fails with
# both records in its detail, FAIL is at least 1, and the trap stays quiet.
_gp_kid refuse 1 <<'GPKID'
mkdir -p "$TMP/gp-plain"
printf 'before %s\n' "$(pwd -P)" > "$GP_OUT/top"
_fx_cd "$TMP/gp-plain" >/dev/null 2>&1; printf 'rc %s\nline %s\n' "$?" "$LINENO" >> "$GP_OUT/top"
printf 'after %s\n' "$(pwd -P)" >> "$GP_OUT/top"
( _fx_cd / ; printf '%s' "$LINENO" > "$GP_OUT/subline" ) >/dev/null 2>&1
cp "${FELIX_TEST_FXREFUSED:-$TMP/gp-no-record}" "$GP_OUT/rec" 2>/dev/null
true
GPKID
_gp_run refuse "$_gp_none"
_gp_o="$(cat "$_gp/kid/refuse/top" 2>/dev/null)"; _gp_t="$(cat "$_gp/kid/refuse/tmp" 2>/dev/null)"
if ! grep -Eq '^(function[[:space:]]+)?_fx_cd[[:space:]]*\(\)' "$_gp/kid/refuse/run" 2>/dev/null; then
  bad "_fx_cd called from the suite's own shell refuses, and the shell stays where it stood" "_fx_cd is not in the preamble"
elif [ -n "$(_gp_get "$_gp_o" rc)" ] && [ "$(_gp_get "$_gp_o" rc)" != 0 ] && [ -n "$(_gp_get "$_gp_o" before)" ] \
     && [ "$(_gp_get "$_gp_o" after)" = "$(_gp_get "$_gp_o" before)" ]; then
  ok  "_fx_cd called from the suite's own shell refuses, and the shell stays where it stood"
else
  bad "_fx_cd called from the suite's own shell refuses, and the shell stays where it stood" "the child reported: $(printf '%s' "$_gp_o" | tr '\n' ' ')"
fi
is "the records of a top-level refusal and a refusal from a silenced subshell: line, directory as given, reason" \
   "$(tr '\t\n' '|;' 2>/dev/null < "$_gp/kid/refuse/rec")" \
   "$(_gp_get "$_gp_o" line)|$_gp_t/gp-plain|top-level;$(cat "$_gp/kid/refuse/subline" 2>/dev/null)|/|outside-tmp;"
# Each line of a file appears in a text. Kept out of $( ): bash 3.2 cannot
# parse a case pattern's ) inside a command substitution.
_gp_all_in() {   # <text> <file>
  local l; while IFS= read -r l; do case "$1" in *"$l"*) ;; *) return 1 ;; esac; done < "$2"; return 0
}
_gp_d="$(_gp_detail refuse "$_gp_c5")"
if _gp_has refuse "  FAIL  $_gp_c5" && [ -s "$_gp/kid/refuse/rec" ] \
   && _gp_all_in "$_gp_d" "$_gp/kid/refuse/rec" \
   && [ "$(sed -n 's/^gp-fail //p' "$_gp/kid/refuse/out")" -ge 1 ] 2>/dev/null; then
  ok  "a refusal fails the end-of-run refusal check, with every recorded line in its detail, so FAIL is at least 1"
else
  bad "a refusal fails the end-of-run refusal check, with every recorded line in its detail, so FAIL is at least 1" \
      "C5 said: $(grep -F -- "$_gp_c5" "$_gp/kid/refuse/out" | tr '\n' ' ')detail: $(printf '%s' "$_gp_d" | tr '\t\n' '| ')"
fi
if _gp_has refuse "  FAIL  $_gp_c5" && [ "$(_gp_rc refuse)" = 0 ] && [ "$(_gp_err refuse 'tests/run: refused fixture git commands:')" = 0 ]; then
  ok  "when C5 has already failed in the main shell, the trap adds no refusal report and keeps the status"
else
  bad "when C5 has already failed in the main shell, the trap adds no refusal report and keeps the status" \
      "status [$(_gp_rc refuse)]; stderr: $(head -3 "$_gp/kid/refuse/err" | tr '\n' ' ')"
fi
# And in a section runner, where only the trap can say it.
_gp_kid refrun 0 <<'GPKID'
( _fx_cd "" ) >/dev/null 2>&1
ok "gp child: an assertion after a refused fixture command"
cp "${FELIX_TEST_FXREFUSED:-$TMP/gp-no-record}" "$GP_OUT/rec" 2>/dev/null
true
GPKID
_gp_run refrun "$_gp_none"
_gp_x="$(awk '/^tests\/run: refused fixture git commands:/ { f = 1; next } f' "$_gp/kid/refrun/err" 2>/dev/null)"
if [ "$(_gp_rc refrun)" = 1 ] && [ "$(head -1 "$_gp/kid/refrun/err" | cut -c1-10)" = "tests/run:" ] \
   && [ "$(_gp_err refrun 'tests/run: refused fixture git commands:')" = 1 ] && [ -s "$_gp/kid/refrun/rec" ] \
   && case "$_gp_x" in *"$(head -1 "$_gp/kid/refrun/rec")"*) true ;; *) false ;; esac; then
  ok  "a section runner with a refusal exits 1, its trap listing the recorded line under 'tests/run: refused fixture git commands:'"
else
  bad "a section runner with a refusal exits 1, its trap listing the recorded line under 'tests/run: refused fixture git commands:'" \
      "status [$(_gp_rc refrun)]; record [$(tr '\t\n' '| ' 2>/dev/null < "$_gp/kid/refrun/rec")]; stderr: $(head -4 "$_gp/kid/refrun/err" | tr '\t\n' '| ')"
fi

# C6 fails closed. A stand-in whose config this user may not read is a
# checkout whose remotes cannot be known, and that is not the same as none.
_gp_unr1="$_gp/stand-unread-a"; _gp_build "$_gp_unr1"
_gp_unr2="$_gp/stand-unread-b"; _gp_build "$_gp_unr2"
chmod 000 "$_gp_unr1/.git/config" "$_gp_unr2/.git/config" 2>/dev/null
if [ -r "$_gp_unr1/.git/config" ]; then
  skip "an unreadable config fails the origin check rather than passing or skipping it" "this user reads a mode-000 file"
  skip "a section runner whose start config is unreadable exits 1, saying it could not read the remotes" "this user reads a mode-000 file"
else
  _gp_kid unread 1 <<'GPKID'
ok "gp child: an assertion in a run whose remotes could not be read"
true
GPKID
  _gp_run unread "$_gp_unr1/sub" "$_gp_unr1"
  if _gp_has unread "  FAIL  $_gp_c8" && [ "$(_gp_rc unread)" = 0 ]; then
    ok  "an unreadable config fails the origin check rather than passing or skipping it"
  else
    bad "an unreadable config fails the origin check rather than passing or skipping it" \
        "status [$(_gp_rc unread)]; C8 said: $(grep -F -- "$_gp_c8" "$_gp/kid/unread/out" | tr '\n' ' ')"
  fi
  _gp_kid unrrun 0 <<'GPKID'
ok "gp child: an assertion in a section runner whose remotes could not be read"
true
GPKID
  _gp_run unrrun "$_gp_unr2/sub" "$_gp_unr2"
  _gp_x="$(grep '^tests/run: could not read the remotes this run started with: ' "$_gp/kid/unrrun/err" 2>/dev/null | head -1)"
  if [ "$(_gp_rc unrrun)" = 1 ] && case "$_gp_x" in *stand-unread-b*) true ;; *) false ;; esac; then
    ok  "a section runner whose start config is unreadable exits 1, saying it could not read the remotes"
  else
    bad "a section runner whose start config is unreadable exits 1, saying it could not read the remotes" \
        "status [$(_gp_rc unrrun)]; stderr: $(head -3 "$_gp/kid/unrrun/err" | tr '\n' ' ')"
  fi
fi
chmod 644 "$_gp_unr1/.git/config" "$_gp_unr2/.git/config" 2>/dev/null

# The ceiling. A child makes its own $TMP a repository, which this suite's
# $TMP must never be. From a directory under it with no .git, git with no
# ceiling finds that repository, the control; after _fx_cd, and through
# _fx_git, git finds none. Any ceiling the child's preamble set is unset
# first, so only _fx_cd's can be what stops git.
_gp_kid ceiling 0 <<'GPKID'
git init -q "$TMP" >/dev/null 2>&1
mkdir -p "$TMP/gp-plain"
_gpk_c="$( unset GIT_CEILING_DIRECTORIES; cd -P "$TMP/gp-plain" && git rev-parse --absolute-git-dir 2>/dev/null )"
printf 'control %s\nwant %s\n' "${_gpk_c:--}" "$(cd -P "$TMP" && pwd -P)/.git" > "$GP_OUT/ceil"
_gpk_c="$( unset GIT_CEILING_DIRECTORIES; FELIX_TEST_FXREFUSED="$TMP/gp-rec"
           _fx_cd "$TMP/gp-plain" >/dev/null 2>&1 || { printf 'refused'; exit 0; }
           git rev-parse --absolute-git-dir 2>/dev/null; printf 'rc=%s' "$?" )"
printf 'fxcd %s\n' "$_gpk_c" >> "$GP_OUT/ceil"
_gpk_c="$( unset GIT_CEILING_DIRECTORIES; FELIX_TEST_FXREFUSED="$TMP/gp-rec"
           _fx_git "$TMP/gp-plain" rev-parse --absolute-git-dir 2>/dev/null; printf 'rc=%s' "$?" )"
printf 'fxgit %s\n' "$_gpk_c" >> "$GP_OUT/ceil"
true
GPKID
_gp_run ceiling "$_gp_none"
_gp_o="$(cat "$_gp/kid/ceiling/ceil" 2>/dev/null)"
if [ -z "$(_gp_get "$_gp_o" want)" ] || [ "$(_gp_get "$_gp_o" control)" != "$(_gp_get "$_gp_o" want)" ]; then
  _gp_x="not exercised: with no ceiling git found [$(_gp_get "$_gp_o" control)], not the child's own [$(_gp_get "$_gp_o" want)]"
  bad "after _fx_cd, git finds no repository from a directory under \$TMP with none of its own, even with one at \$TMP" "$_gp_x"
  bad "_fx_git on a directory under \$TMP with no .git of its own finds no repository, and returns git's 128" "$_gp_x"
else
  is "after _fx_cd, git finds no repository from a directory under \$TMP with none of its own, even with one at \$TMP" \
     "$(_gp_get "$_gp_o" fxcd)" "rc=128"
  is "_fx_git on a directory under \$TMP with no .git of its own finds no repository, and returns git's 128" \
     "$(_gp_get "$_gp_o" fxgit)" "rc=128"
fi

# The fork half of C7, counted only where C7 is shown to exist (see above).
if [ ! -s "$_gp/kid/url/origin-moved" ]; then
  bad "the guard's check on each assertion costs no fork when no watched file changed" \
      "C7 left no record in the moved-remote child, so there is no guard here to measure"
elif [ "$(cat "$_gp/kid/same/fork.limit" 2>/dev/null)" != 1 ]; then
  skip "the guard's check on each assertion costs no fork when no watched file changed" "ulimit -S -u 1 did not hold in the child"
else
  is "the guard's check on each assertion costs no fork when no watched file changed" \
     "$(cat "$_gp/kid/same/fork.err" 2>/dev/null)|$(grep -c 'gp child: an assertion after the fork probe' "$_gp/kid/same/out")" "|1"
fi

# Last: none of the refusals this block provoked reached the suite's own
# record. A control on a suite with no record, where both counts are 0.
_gp_rec1=0
[ -n "${FELIX_TEST_FXREFUSED:-}" ] && [ -f "$FELIX_TEST_FXREFUSED" ] \
  && _gp_rec1="$(wc -l < "$FELIX_TEST_FXREFUSED" | tr -d ' ')"
is "no refusal this block provoked reached the suite's own refusal record" "$_gp_rec1" "$_gp_rec0"

