printf '\nwhat felix merge records, and what it hands gh\n'
# The contract of the landing change (L1), three rules, tested from outside:
#   1. `felix merge --dry-run` writes nothing to the project's memory, whatever
#      its outcome: a refused escape, an error, or a tree it would squash.
#   2. every refusal of a real run is recorded as `refused` rows in says.log,
#      one per distinct blocker kind printed, or one for a refusal that stops
#      with an error; each row begins `<branch>: ` (`<branch>: <kind>: ` for a
#      blocker) and carries the session; a merge that goes through writes none;
#      `escalated` rows are a real run's alone.
#   3. the `gh pr merge` call carries --match-head-commit HEAD, a non-empty
#      --subject and --body, Felix-Gate and Felix-Judge trailers in the body's
#      last paragraph, and no CI skip marker, for a product and for the
#      repository that ships the engine.
# Written BLIND: the author read neither felix nor lib/escape.sh, only the
# contract and this suite's fixtures. Every repository, the gh stub and the
# kernel cache are its own, under $TMP, at physical paths.
#
# The gh stub records each call as one file, every argument NUL-terminated, so
# argument boundaries survive and a multi-line --body is read back whole. It
# answers every invocation with exit 0 and no output, so it steers nothing, but
# the provider's two reads (lib/bind.sh, S5.2), answered from its checkout by git.
L1="$TMP/l1blind"; mkdir -p "$L1/gh"; L1="$(cd "$L1" && pwd -P)"
cat > "$L1/gh/gh" <<'STUB'
#!/usr/bin/env bash
d="${L1GH_DIR:?}"; mkdir -p "$d"
n=0; for f in "$d"/call.*; do [ -e "$f" ] && n=$((n+1)); done
f="$d/call.$(printf '%03d' $((n+1)))"
: > "$f"; for a in "$@"; do printf '%s\0' "$a" >> "$f"; done
case "$*" in
  "pr view "*"--json number,state,baseRefName,headRefOid"*)
    printf '7\tOPEN\t%s\t%s\n' "${GHSTUB_BASE:-main}" "$(git rev-parse HEAD)" ;;
  "api repos/"*"/git/ref/heads/"*)
    n="${2#*/git/ref/heads/}"
    printf 'commit\t%s\n' "$(git rev-parse --verify -q "refs/remotes/origin/$n^{commit}" || git rev-parse --verify -q "refs/heads/$n^{commit}")" ;;
esac
exit 0
STUB
chmod +x "$L1/gh/gh"
L1SAYS="$MEM/widget/says.log"
L1KC="$L1/kcache"
L1RC=0; L1LINES=0; L1MC=""; L1WHY=""

# The template risk table, whatever an earlier section left, restored at the end.
L1RISK=""
[ -f "$FROOT/projects/widget/risk.tsv" ] && { cp "$FROOT/projects/widget/risk.tsv" "$L1/risk.keep"; L1RISK=y; }
cp "$REAL_HARNESS/templates/risk.tsv" "$FROOT/projects/widget/risk.tsv"
# No evidence policy, whatever an earlier section left, restored at the end.
# The fixtures below decide which blocker kinds a run prints, and the evidence
# policy section leaves a `db` row for \.sql$ in place. Under the full suite
# that row added an `evidence` kind to the "two escapes of one kind" tree, so
# the run printed two kinds and wrote two refused rows, correctly, and two
# assertions failed on CI while the section alone passed.
L1EV=""
[ -f "$FROOT/projects/widget/evidence.tsv" ] && { mv "$FROOT/projects/widget/evidence.tsv" "$L1/evidence.keep"; L1EV=y; }

# A green gate receipt and the commission stamp for a checkout, exactly as the
# suite records them; prints the tree id the receipt was recorded for.
_l1rec() {
  local t
  t="$( cd "$1" && . "$FROOT/harness/lib/verify.sh"; felix_tree_id "$1" "$FROOT" )"
  ( cd "$1" && . "$FROOT/harness/lib/verify.sh"; felix_verify_record "$1" "$FROOT" 0 "true" "$t" )
  _cm_stamp "$1" >/dev/null 2>&1
  printf '%s' "$t"
}
# checkout, session, then any VAR=value, then `--` and felix merge's arguments.
# Sets L1RC, $L1/out, $L1/err, the gh calls under $L1/calls, and L1MC, the
# first call whose arguments hold `pr merge`; marks says.log first, so _l1new
# reads only what this one run appended.
_l1run() {
  local r="$1" s="$2"; shift 2
  local envs=()
  while [ $# -gt 0 ] && [ "$1" != "--" ]; do envs+=("$1"); shift; done
  [ "${1:-}" = "--" ] && shift
  rm -rf "$L1/calls"; mkdir -p "$L1/calls"
  L1LINES="$( [ -f "$L1SAYS" ] && wc -l < "$L1SAYS" | tr -d ' ' || echo 0 )"
  ( cd "$r" && unset FELIX_KERNEL
    PATH="$L1/gh:$PATH" L1GH_DIR="$L1/calls" CLAUDE_CODE_SESSION_ID="$s" FELIX_KERNEL_CACHE="$L1KC" \
      env ${envs[@]+"${envs[@]}"} "$FELIX" merge "$@" >"$L1/out" 2>"$L1/err" )
  L1RC=$?
  L1MC=""
  local f
  for f in "$L1/calls"/call.*; do
    [ -e "$f" ] || continue
    _l1ismerge "$f" && { L1MC="$f"; break; }
  done
}
_l1ismerge() {   # call file -> 0 when its arguments hold `pr` then `merge`
  local a prev=""
  while IFS= read -r -d '' a; do
    [ "$prev" = "pr" ] && [ "$a" = "merge" ] && return 0
    prev="$a"
  done < "$1"
  return 1
}
_l1arg() {   # call file, --flag -> the flag's value as one argument (--flag v or --flag=v); 1 when absent
  local a take=0 got=1 val=""
  while IFS= read -r -d '' a; do
    if [ "$take" -eq 1 ]; then val="$a"; take=0; got=0; continue; fi
    case "$a" in
      "$2")   take=1 ;;
      "$2"=*) val="${a#*=}"; got=0 ;;
    esac
  done < "$1"
  [ "$got" -eq 0 ] || return 1
  printf '%s' "$val"
}
_l1new()  { [ -f "$L1SAYS" ] && tail -n +"$((L1LINES + 1))" "$L1SAYS"; return 0; }
_l1rows() { _l1new | awk -F'\t' -v k="$1" '$2 == k'; }                     # kind -> this run's rows of it
_l1n()    { _l1rows "$1" | grep -c . | tr -d ' '; }                         # kind -> how many
_l1all()  { cat "$L1/out" "$L1/err" | tr '\n' ' '; }
# The distinct blocker kinds a refusal printed: the first column of each line
# under `not merging`, up to the blank line that ends the list.
_l1kinds() {
  cat "$L1/out" "$L1/err" | awk '
    /^not merging/          { on = 1; next }
    on && /^[ \t]+[a-z]/    { print $1; seen = 1; next }
    on && seen && /^[ \t]*$/ { exit }' | LC_ALL=C sort -u | tr '\n' ' '
}
_l1lines() { cat "$L1/out" "$L1/err" | awk -v k="$1" '$1 == k' | grep -c . | tr -d ' '; }   # kind -> blocker lines
# The kind each of this run's refused rows names after `<branch>: `, sorted,
# duplicates kept, so two rows of one kind read as two.
_l1refkinds() {
  _l1rows refused | awk -F'\t' '{ print $5 }' | while IFS= read -r t; do
    case "$t" in "$1: "*) t="${t#"$1: "}"; printf '%s\n' "${t%%: *}" ;; *) printf '(no branch prefix)\n' ;; esac
  done | LC_ALL=C sort | tr '\n' ' '
}
# prefix, session -> 0 when this run wrote a refused row and every one begins
# with the prefix and carries the session in column 3; L1WHY says what failed.
_l1rowsok() {
  local rows; rows="$(_l1rows refused)"
  [ -n "$rows" ] || { L1WHY="no refused row was written"; return 1; }
  printf '%s\n' "$rows" | awk -F'\t' -v p="$1" -v s="$2" \
    'index($5, p) != 1 || $3 != s { bad = 1 } END { exit bad }' && return 0
  L1WHY="want [$1...] in session [$2], rows: $(printf '%s' "$rows" | tr '\t' '|')"; return 1
}
# Every file and directory under the project's memory with a checksum, and
# says.log kept byte for byte (or its absence), for the dry-run comparisons.
_l1snap() {
  ( cd "$MEM/widget" 2>/dev/null || exit 0
    find . -print | LC_ALL=C sort | while IFS= read -r f; do
      if [ -f "$f" ]; then printf '%s %s\n' "$(cksum < "$f" | tr -s ' \t' '  ')" "$f"
      else printf 'dir %s\n' "$f"; fi
    done )
}
_l1keep() { rm -f "$L1/says.before"; [ -f "$L1SAYS" ] && cp "$L1SAYS" "$L1/says.before"; _l1snap > "$L1/mem.before"; }
_l1same() { if [ -f "$L1/says.before" ]; then cmp -s "$L1/says.before" "$L1SAYS"; else [ ! -e "$L1SAYS" ]; fi; }
_l1memsame() { _l1snap > "$L1/mem.after"; cmp -s "$L1/mem.before" "$L1/mem.after"; }
_l1memdiff() { diff "$L1/mem.before" "$L1/mem.after" | grep '^[<>]' | tr '\n' ' '; }
# The CI skip markers a text carries, one per line, in any letter case.
_l1skips() {
  awk '{ l = tolower($0)
         n = split("[skip ci]|[ci skip]|[no ci]|[skip actions]|[actions skip]", m, "|")
         for (i = 1; i <= n; i++) if (index(l, m[i])) print m[i]
         if (l ~ /^[ \t]*skip-checks:[ \t]*true/) print "skip-checks: true" }'
}
# Every commit on the branch carries a marker, and between them all six.
_l1marked() {   # checkout -> 0 when so
  local c all=""
  for c in $(git -C "$1" rev-list main..HEAD); do
    [ -n "$(git -C "$1" log -1 --format=%B "$c" | _l1skips)" ] || return 1
    all="$all$(git -C "$1" log -1 --format=%B "$c" | _l1skips)
"
  done
  [ "$(grep . <<<"$all" | LC_ALL=C sort -u | grep -c .)" -eq 6 ]
}
# The trailers git itself finds in the squash commit gh would write: subject,
# blank line, body. `git interpret-trailers --parse` is the oracle for "the
# body's last paragraph holds git trailers".
_l1trailers() { printf '%s\n\n%s\n' "$2" "$3" | _fx_git "$1" interpret-trailers --parse 2>/dev/null; }
_l1reached() {  # name -> 0 when the run exited 0 and called gh pr merge; else fails the name
  [ "$L1RC" -eq 0 ] && [ -n "$L1MC" ] && return 0
  bad "$1" "gh pr merge was never called: exit $L1RC: $(_l1all)"; return 1
}
_l1commit() { git -c user.name=t -c user.email=t@t commit -q "$@" >/dev/null 2>&1; }
# Three commit messages that between them carry every marker, each at least one.
_l1landing() {   # in a checkout: three marked commits touching NOTES.md
  printf 'one\n' > NOTES.md; git add -A >/dev/null 2>&1
  _l1commit -m 'Add notes [skip ci]' -m 'Also [CI SKIP] and [No Ci].' -m 'skip-checks: true'
  printf 'two\n' >> NOTES.md; git add -A >/dev/null 2>&1
  _l1commit -m 'Extend notes [Skip Actions]' -m 'And [ACTIONS SKIP], [skip CI].' -m 'skip-checks:true'
  printf 'three\n' >> NOTES.md; git add -A >/dev/null 2>&1
  _l1commit -m 'Finish notes [no ci] [ci skip] [skip actions] [actions skip] [SKIP CI]' -m 'Skip-Checks: True'
}

# ---- a governed product, with a github remote -------------------------------
L1P="$L1/product"; mkdir -p "$L1P"
( _fx_cd "$L1P" && git init -q -b main && git remote add origin https://github.com/example/widget.git )
L1P="$(cd "$L1P" && pwd -P)"
printf 'widget\n' > "$L1P/.felix"; printf 'contents\n' > "$L1P/WIDGET.txt"
( _fx_cd "$L1P" && git add -A >/dev/null 2>&1 && _l1commit -m base )

# Two escapes of ONE kind: two schema migrations, each its own durable blocker.
( _fx_cd "$L1P" && git checkout -q -b l1-blind-escapes && mkdir -p migrations \
  && printf 'x\n' > migrations/1.sql && printf 'y\n' > migrations/2.sql \
  && git add -A >/dev/null 2>&1 && _l1commit -m 'two migrations' )
_l1rec "$L1P" >/dev/null

# Rule 1, the escaping dry run first, so it reads memory no real run touched.
_l1keep
_l1run "$L1P" l1-blind-sess-dry -- --base main --dry-run
# main: exits 3 on the escape and appends two `escalated` rows to says.log.
if [ "$L1RC" -eq 3 ] && [ "$(_l1lines escape)" -ge 2 ]; then
  _l1same && ok "a dry run on an escaping tree leaves says.log byte for byte as it found it" \
          || bad "a dry run on an escaping tree leaves says.log byte for byte as it found it" "appended: $(_l1new | tr '\t\n' '| ')"
else bad "a dry run on an escaping tree leaves says.log byte for byte as it found it" "the dry run did not refuse two escapes: exit $L1RC: $(_l1all)"; fi
# main: two `escalated` rows, one per migration.
is "and a dry run on an escaping tree writes no escalated row" "$(_l1n escalated)" "0"
# main: says.log changed, so the listing of the memory differs.
_l1memsame && ok "and adds, removes or changes no file under the project's memory" \
           || bad "and adds, removes or changes no file under the project's memory" "$(_l1memdiff)"

# Rule 2, the same tree, for real: one printed kind, two blockers of it.
_l1run "$L1P" l1-blind-sess-a -- --base main
# main: exits 3, prints two escape lines, writes no refused row at all.
if [ "$L1RC" -eq 3 ] && [ "$(_l1kinds)" = "escape " ] && [ "$(_l1lines escape)" -ge 2 ] && [ -z "$L1MC" ]; then
  is "a real run refused for two escapes of one kind records exactly one refused row" "$(_l1n refused)" "1"
else bad "a real run refused for two escapes of one kind records exactly one refused row" "not two escapes of one kind: exit $L1RC kinds [$(_l1kinds)]: $(_l1all)"; fi
# main: no refused row to carry anything.
_l1rowsok "l1-blind-escapes: escape: " l1-blind-sess-a \
  && ok  "and that refused row begins with the branch and the kind and carries the session" \
  || bad "and that refused row begins with the branch and the kind and carries the session" "$L1WHY"
# main: two escalated rows, one per blocker; the contract already holds there.
if [ "$(_l1lines escape)" -ge 2 ]; then
  is "a real run on an escaping tree still writes one escalated row per escape blocker" "$(_l1n escalated)" "$(_l1lines escape)"
else bad "a real run on an escaping tree still writes one escalated row per escape blocker" "no escape blockers printed: $(_l1all)"; fi

# Two KINDS: an escape, and a receipt the tree has since moved past.
( _fx_cd "$L1P" && git checkout -q main && git checkout -q -b l1-blind-two-kinds && mkdir -p migrations \
  && printf 'z\n' > migrations/3.sql && git add -A >/dev/null 2>&1 && _l1commit -m 'a migration' )
_l1rec "$L1P" >/dev/null
( _fx_cd "$L1P" && printf 'after the gate\n' > LATER.md && git add -A >/dev/null 2>&1 && _l1commit -m 'after the gate' )
_l1run "$L1P" l1-blind-sess-b -- --base main
# main: exits 3 printing escape and not-green, and records neither as refused.
if [ "$L1RC" -ne 0 ] && [ -z "$L1MC" ] && case "$(_l1kinds)" in *escape*) true ;; *) false ;; esac \
   && [ "$(_l1kinds | wc -w | tr -d ' ')" -ge 2 ]; then
  is "a real run refused for blockers of two kinds records one refused row per kind" \
     "$(_l1refkinds l1-blind-two-kinds)" "$(_l1kinds)"
else bad "a real run refused for blockers of two kinds records one refused row per kind" "not two kinds: exit $L1RC kinds [$(_l1kinds)]: $(_l1all)"; fi
# main: no refused rows.
_l1rowsok "l1-blind-two-kinds: " l1-blind-sess-b \
  && ok  "and each of those refused rows carries the branch and the session" \
  || bad "and each of those refused rows carries the branch and the session" "$L1WHY"

# A refusal that stops with an error: an argument felix merge cannot honour.
_l1run "$L1P" l1-blind-sess-c -- 35
# main: exit 1, `felix: felix merge does not take '35'` on stderr, no row.
if [ "$L1RC" -eq 1 ] && grep -q '^felix: ' "$L1/err" && [ -z "$L1MC" ]; then
  is "an argument felix merge cannot honour is recorded as exactly one refused row" "$(_l1n refused)" "1"
else bad "an argument felix merge cannot honour is recorded as exactly one refused row" "no error refusal: exit $L1RC: $(_l1all)"; fi
# main: no row.
_l1rowsok "l1-blind-two-kinds: " l1-blind-sess-c \
  && ok  "and that row begins with the checked-out branch and carries the session" \
  || bad "and that row begins with the checked-out branch and carries the session" "$L1WHY"

# And the same error on a dry run writes nothing at all.
_l1keep
_l1run "$L1P" l1-blind-sess-c2 -- --dry-run 35
# main: exit 1 on the argument, memory untouched; the contract already holds.
if [ "$L1RC" -eq 1 ] && grep -q '^felix: ' "$L1/err"; then
  _l1same && _l1memsame && ok "a dry run stopped by an argument it cannot honour writes nothing to memory" \
    || bad "a dry run stopped by an argument it cannot honour writes nothing to memory" "$(_l1memdiff)"
else bad "a dry run stopped by an argument it cannot honour writes nothing to memory" "no error refusal: exit $L1RC: $(_l1all)"; fi

# A branch that lands: three commits, every one carrying CI skip markers.
( _fx_cd "$L1P" && git checkout -q main && git checkout -q -b l1-blind-land && _l1landing )
L1TID="$(_l1rec "$L1P")"
_l1keep
_l1run "$L1P" l1-blind-sess-g0 -- --base main --dry-run
# main: exit 0, no gh call, memory untouched; the contract already holds.
if [ "$L1RC" -eq 0 ] && [ -z "$L1MC" ]; then
  _l1same && _l1memsame && ok "a dry run that would squash writes nothing to memory" \
    || bad "a dry run that would squash writes nothing to memory" "$(_l1memdiff)"
else bad "a dry run that would squash writes nothing to memory" "not a clean dry run: exit $L1RC: $(_l1all)"; fi

_l1run "$L1P" l1-blind-sess-g -- --base main
# main: merges (one gh pr merge) and writes a `merged` row, no refused row.
_l1reached "a merge that goes through writes no refused row" \
  && is "a merge that goes through writes no refused row" "$(_l1n refused)" "0"
# main: `pr merge l1-blind-land --repo example/widget --squash`, no --match-head-commit.
_l1reached "gh pr merge is told the head commit the checkout has, by --match-head-commit" \
  && is "gh pr merge is told the head commit the checkout has, by --match-head-commit" \
        "$(_l1arg "$L1MC" --match-head-commit)" "$(git -C "$L1P" rev-parse HEAD)"
L1S=""; L1B=""; [ -n "$L1MC" ] && { L1S="$(_l1arg "$L1MC" --subject)"; L1B="$(_l1arg "$L1MC" --body)"; }
# main: neither --subject nor --body is passed.
if _l1reached "and is handed a non-empty --subject and --body"; then
  case "$L1S" in *[![:space:]]*) case "$L1B" in *[![:space:]]*) ok "and is handed a non-empty --subject and --body" ;;
    *) bad "and is handed a non-empty --subject and --body" "body [$L1B]" ;; esac ;;
    *) bad "and is handed a non-empty --subject and --body" "subject [$L1S]" ;; esac
fi
# main: no body, so no trailers.
if _l1reached "and the body ends in Felix-Gate and Felix-Judge trailers naming the receipt's tree"; then
  L1T="$(_l1trailers "$L1P" "$L1S" "$L1B")"
  if grep -qxF "Felix-Gate: $L1TID" <<<"$L1T" && grep -qE '^Felix-Judge: *[^ ]' <<<"$L1T"; then
    ok "and the body ends in Felix-Gate and Felix-Judge trailers naming the receipt's tree"
  else bad "and the body ends in Felix-Gate and Felix-Judge trailers naming the receipt's tree" \
           "want Felix-Gate: $L1TID; git parsed [$(printf '%s' "$L1T" | tr '\n' '|')] from body [$L1B]"; fi
fi
# main: no subject or body, so gh composes the squash message from the
# commits, every one of which carries a marker.
if _l1reached "and neither subject nor body carries a ci skip marker though every commit does"; then
  if ! _l1marked "$L1P"; then bad "and neither subject nor body carries a ci skip marker though every commit does" "the fixture's commits do not carry every marker"
  elif [ -z "$L1S" ] || [ -z "$L1B" ]; then bad "and neither subject nor body carries a ci skip marker though every commit does" "no subject or body: gh would write the commits' own messages"
  else is "and neither subject nor body carries a ci skip marker though every commit does" \
          "$(printf '%s\n%s\n' "$L1S" "$L1B" | _l1skips | tr '\n' ' ')" ""; fi
fi

# ---- no github remote, green receipt ----------------------------------------
L1N="$L1/noremote"; mkdir -p "$L1N"
( _fx_cd "$L1N" && git init -q -b main ); L1N="$(cd "$L1N" && pwd -P)"
printf 'widget\n' > "$L1N/.felix"; printf 'contents\n' > "$L1N/WIDGET.txt"
( _fx_cd "$L1N" && git add -A >/dev/null 2>&1 && _l1commit -m base && git checkout -q -b l1-blind-no-remote \
  && printf 'a\n' > A.md && git add -A >/dev/null 2>&1 && _l1commit -m a )
_l1rec "$L1N" >/dev/null
_l1run "$L1N" l1-blind-sess-d -- --base main
# main: exit 1, `felix: no github remote`, no row.
# Since trust step 3, slice 2 (S5.2, S5.3): no remote is no answer, refused by one `base` blocker.
if [ "$L1RC" -ne 0 ] && [ "$(_l1kinds)" = "base " ] && [ -z "$L1MC" ]; then
  is "a checkout with no github remote is refused with exactly one refused row" "$(_l1n refused)" "1"
else bad "a checkout with no github remote is refused with exactly one refused row" "no error refusal: exit $L1RC: $(_l1all)"; fi
# main: no row.
_l1rowsok "l1-blind-no-remote: " l1-blind-sess-d \
  && ok  "and the no-remote refusal row carries the branch and the session" \
  || bad "and the no-remote refusal row carries the branch and the session" "$L1WHY"

# The subject when gh gives no title, which this stub never does: the newest
# commit the branch made itself, as felix pr titles it (felix_pr_title). It was
# the newest commit that was not a merge, so a handoff section written last was
# the subject of the squash on main.
( _fx_cd "$L1P" && git checkout -q main && git checkout -q -b l1-title-side \
  && printf 'side\n' > SIDE.txt && git add -A >/dev/null 2>&1 && _l1commit -m 'Side work, merged in' \
  && git checkout -q main && git checkout -q -b l1-title \
  && printf 'changed\n' >> WIDGET.txt && git add -A >/dev/null 2>&1 && _l1commit -m 'Change the widget' \
  && git -c user.name=t -c user.email=t@t merge -q --no-ff l1-title-side -m "Merge branch 'l1-title-side' into l1-title" \
  && mkdir -p docs/handoff/pending && printf '### l1\n' > docs/handoff/pending/20991231T000000Z-l1-title.md \
  && git add -A >/dev/null 2>&1 && _l1commit -m "docs(handoff): this branch's section" ) >/dev/null 2>&1
_l1rec "$L1P" >/dev/null
_l1run "$L1P" l1-title-sess -- --base main
L1S=""; [ -n "$L1MC" ] && L1S="$(_l1arg "$L1MC" --subject)"
_l1reached "a squash gh gave no title for is subjected by the newest commit the branch made itself" \
  && is "a squash gh gave no title for is subjected by the newest commit the branch made itself" \
        "$L1S" "Change the widget"

# ---- the repository that ships the engine ------------------------------------
# Built as the suite's self-governed fixture is: main's engine is the real
# harness, main declares 1.0.0, the kernel cache's 1.0.0 entry is a copy of the
# same. The branch bumps to 2.0.0 as the deploy loop forces and otherwise
# touches prose only, and main then moves one commit on, so main's version,
# the branch's version, the merge-base and the base ref's sha all differ.
L1SG="$L1/selfgov"; mkdir -p "$L1SG/engine/.claude-plugin" "$L1SG/engine/harness"
( _fx_cd "$L1SG" && git init -q -b main && git remote add origin https://github.com/example/widget.git )
L1SG="$(cd "$L1SG" && pwd -P)"
printf 'widget\n' > "$L1SG/.felix"
cp -R "$FROOT/harness/." "$L1SG/engine/harness/"
printf '*.log\n.DS_Store\n' > "$L1SG/.gitignore"
printf '{ "version": "1.0.0" }\n' > "$L1SG/engine/.claude-plugin/plugin.json"
( _fx_cd "$L1SG" && git add -A >/dev/null 2>&1 && _l1commit -m base \
  && git checkout -q -b l1-blind-self \
  && printf '{ "version": "2.0.0" }\n' > engine/.claude-plugin/plugin.json && _l1landing \
  && git checkout -q main && printf 'main moved\n' > MAIN.md && git add -A >/dev/null 2>&1 \
  && _l1commit -m 'main moves on' && git checkout -q l1-blind-self )
mkdir -p "$L1KC/1.0.0" "$L1KC/2.0.0"
cp -R "$FROOT/harness" "$L1KC/1.0.0/harness"; cp -R "$FROOT/harness" "$L1KC/2.0.0/harness"
# 2026-10-18 (judge refs, Part C): the entry is compared whole, so it holds main's manifest too.
mkdir -p "$L1KC/1.0.0/.claude-plugin"; printf '{ "version": "1.0.0" }\n' > "$L1KC/1.0.0/.claude-plugin/plugin.json"
L1SGTID="$(_l1rec "$L1SG")"

_l1run "$L1SG" l1-blind-sess-e FELIX_KERNEL="$L1KC/1.0.0/harness" -- --base main
# main: exit 1, `felix: FELIX_KERNEL is set, ...`, no row.
if [ "$L1RC" -eq 1 ] && grep -q '^felix: ' "$L1/err" && [ -z "$L1MC" ]; then
  is "a self-governed repository refused for a set FELIX_KERNEL records exactly one refused row" "$(_l1n refused)" "1"
else bad "a self-governed repository refused for a set FELIX_KERNEL records exactly one refused row" "no error refusal: exit $L1RC: $(_l1all)"; fi
# main: no row.
_l1rowsok "l1-blind-self: " l1-blind-sess-e \
  && ok  "and the FELIX_KERNEL refusal row carries the branch and the session" \
  || bad "and the FELIX_KERNEL refusal row carries the branch and the session" "$L1WHY"

_l1run "$L1SG" l1-blind-sess-h -- --base main
# main: merges, judged by the 1.0.0 entry; no --match-head-commit.
_l1reached "a self-governed merge is told its head commit by --match-head-commit too" \
  && is "a self-governed merge is told its head commit by --match-head-commit too" \
        "$(_l1arg "$L1MC" --match-head-commit)" "$(git -C "$L1SG" rev-parse HEAD)"
L1S=""; L1B=""; [ -n "$L1MC" ] && { L1S="$(_l1arg "$L1MC" --subject)"; L1B="$(_l1arg "$L1MC" --body)"; }
L1T="$(_l1trailers "$L1SG" "$L1S" "$L1B")"
# main: no body, so no Felix-Judge trailer.
_l1reached "and its Felix-Judge trailer is main's declared version at the base ref's full sha" \
  && is "and its Felix-Judge trailer is main's declared version at the base ref's full sha" \
        "$(printf '%s\n' "$L1T" | grep '^Felix-Judge:')" "Felix-Judge: 1.0.0 @ $(git -C "$L1SG" rev-parse main)"
# main: no body, so no Felix-Gate trailer.
_l1reached "and its Felix-Gate trailer is the tree id the receipt was recorded for" \
  && is "and its Felix-Gate trailer is the tree id the receipt was recorded for" \
        "$(printf '%s\n' "$L1T" | grep '^Felix-Gate:')" "Felix-Gate: $L1SGTID"
# main: no subject or body, so gh composes the message from marked commits.
if _l1reached "and its subject and body carry no ci skip marker though every commit does"; then
  if ! _l1marked "$L1SG"; then bad "and its subject and body carry no ci skip marker though every commit does" "the fixture's commits do not carry every marker"
  elif [ -z "$L1S" ] || [ -z "$L1B" ]; then bad "and its subject and body carry no ci skip marker though every commit does" "no subject or body: gh would write the commits' own messages"
  else is "and its subject and body carry no ci skip marker though every commit does" \
          "$(printf '%s\n%s\n' "$L1S" "$L1B" | _l1skips | tr '\n' ' ')" ""; fi
fi

# Restored: the risk table as it was found.
if [ -n "$L1RISK" ]; then cp "$L1/risk.keep" "$FROOT/projects/widget/risk.tsv"
else rm -f "$FROOT/projects/widget/risk.tsv"; fi
# Restored: the evidence policy as it was found.
if [ -n "$L1EV" ]; then mv "$L1/evidence.keep" "$FROOT/projects/widget/evidence.tsv"; fi
unset L1 L1SAYS L1KC L1RC L1LINES L1MC L1WHY L1RISK L1EV L1TID L1SGTID L1S L1B L1T L1P L1N L1SG
unset -f _l1rec _l1run _l1ismerge _l1arg _l1new _l1rows _l1n _l1all _l1kinds _l1lines _l1refkinds \
         _l1rowsok _l1snap _l1keep _l1same _l1memsame _l1memdiff _l1skips _l1marked _l1trailers \
         _l1reached _l1commit _l1landing

printf '\na path at the end of a sentence\n'
# An issue says "cover it in tests/test_thing.py." and the trailing full stop
# travels with the path. The extractor strips :line, a trailing comma, ./ and
# leading +-, and never that — so the most ordinary way a person writes a path
# in prose was the one way it did not resolve. `felix brief` silently listed one
# of the two files an issue named, which reads as a complete answer.
IP="$TMP/inc"; mkdir -p "$IP/src" "$IP/tests"
: > "$IP/src/thing.py"; : > "$IP/tests/test_thing.py"
_ip() { ( . "$FROOT/harness/lib/incident.sh"; felix_incident_paths "$IP" "$1" | tr '\n' ' ' ); }
has "a path ending a sentence still resolves" "$(_ip 'fix it in tests/test_thing.py.')" "tests/test_thing.py"
has "and both paths in one sentence are found" \
    "$(_ip 'src/thing.py raises. Cover it in tests/test_thing.py.')" "src/thing.py"
has "including the second one"  \
    "$(_ip 'src/thing.py raises. Cover it in tests/test_thing.py.')" "tests/test_thing.py"
is  "a path naming nothing real is still not invented" "$(_ip 'see docs/nope.py.')" ""

# The same defect one convention along, and this one is how every issue is
# actually written. A path in inline backticks resolved to nothing at all: the
# splitter breaks on quotes, parens, brackets and angle brackets, and never on a
# backtick, so the candidate carried one at each end and no amount of stripping
# leading components could find a file by that name.
#
# Found by filing the first four issues this repository has ever had and running
# `felix brief` on one. It reported a single file and tier yellow. The body also
# named engine/harness/lib/resolve.sh, in backticks, which risk.tsv calls red
# because it is sourced by the CLI and by every hook. So the miss did not read as
# an omission — it read as a confident risk verdict, one tier low.
#
# Markdown emphasis is the same shape and gets the same treatment. Both are
# delimiters nobody puts in a repo path, exactly like the quotes and brackets
# already in the set, and adding them can only ever resolve more.
has "a path in inline backticks resolves"   "$(_ip 'look at `src/thing.py` please')"     "src/thing.py"
has "and one in a double-backtick span"     "$(_ip 'look at ``src/thing.py`` please')"   "src/thing.py"
has "and one wrapped in bold"               "$(_ip 'look at **src/thing.py** please')"   "src/thing.py"
has "backticks plus the punctuation after them" \
    "$(_ip 'added in 52e7723, `tests/test_thing.py`).')"                                 "tests/test_thing.py"
has "a trailing colon does not eat it"      "$(_ip 'the failing file is src/thing.py:')" "src/thing.py"
has "nor a semicolon"                       "$(_ip 'src/thing.py; and then more')"       "src/thing.py"
# The conservative half must survive all of that: still no inventing.
is  "and a backticked path naming nothing is still not invented" \
    "$(_ip 'see `docs/nope.py` there')" ""

# The implicated set is what the unattended repair may change, and `[ -f ]`
# from the root took files beside the checkout and inside its repository:
# ../felix/engine/harness/felix, the CLI the job judges with, resolved from a
# gate log that named it, and so did .git/config. Neither shows in `git diff`.
# A path that climbs out still resolves by what is left of it inside.
mkdir -p "$IP/.git"; : > "$IP/.git/config"
is  "a path outside the checkout or inside its .git is never implicated" \
    "$(_ip 'see ../ran, .git/config and ../inc/src/thing.py')" "src/thing.py "
# Two forms a failing log prints all the time, each of which resolved to no
# file: pytest's test id, and a line number with a colon after it.
is  "a pytest test id and a line number followed by a colon both name their file" \
    "$(_ip 'FAILED tests/test_thing.py::test_x - assert 1 == 2')$(_ip 'src/thing.py:12: AssertionError')" \
    "tests/test_thing.py src/thing.py "

printf '\nwhat you are about to commit\n'
# `felix evidence` told a session it owed a web test that the session had
# literally just staged. Every reader of "what changed" tries
# `git diff --name-only base...HEAD` and falls back to `git diff base` only when
# that is EMPTY. On a branch with commits the first form is not empty, so the
# fallback never runs and everything staged or unstaged is dropped — which is
# every pull request. On a branch with no commits yet the fallback covers it,
# which is why this went unnoticed: the shape that hides the bug is the shape a
# fixture reaches for.
#
# Worse than a wrong report: felix_escapes reads the same way, so on any real
# branch a staged workflow change or a staged credential was invisible to the
# merge gate. lessons.sh had it right all along and nothing made the rest agree.
_staged_repo_build

_sesc() { ( cd "$STG" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"
            . "$FROOT/harness/lib/review.sh"; . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
            felix_escapes "$FROOT/projects/widget" "$BASE_SHA" "$STG" "$FROOT" ); }
has "a staged workflow escapes even with commits ahead" "$(_sesc)" "execute"

printf 'unit\t^src/\t^tests?/\tcode changes need a test\n' > "$FROOT/projects/widget/evidence.tsv"
mkdir -p "$STG/src" "$STG/tests"; printf 'x=1\n' > "$STG/src/a.py"
( _fx_cd "$STG" && git add src >/dev/null 2>&1 )
_sev() { ( cd "$STG" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/evidence.sh"
           felix_evidence_check "$FROOT/projects/widget" "$BASE_SHA" "$STG" ); }
has "a staged source change owes its test" "$(_sev)" "gap"
printf 'def test_a(): pass\n' > "$STG/tests/test_a.py"
( _fx_cd "$STG" && git add tests >/dev/null 2>&1 )
has "and staging the test closes the gap — the case that started this" "$(_sev)" "met"
rm -f "$FROOT/projects/widget/evidence.tsv"

