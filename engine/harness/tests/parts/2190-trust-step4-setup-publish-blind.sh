# >>> trust-step4-setup-publish
printf '\ntrust plane step 4, the authority setup slice: the drop, felix authority publish (spec P1 to P5, section 5; blind)\n'
# Blind, written on 2026-11-16 from .felix/memory/felix/audits/2026-11-16-trust-step4-authority-setup/spec.md (rev 1)
# alone (sections 0, 1, 5 and 6), before felix authority publish existed, by an author who has read no engine code.
# Conventions come from tests/run, parts 2186 to 2189 and tests/lib/trust-step4.sh; this slice's helpers are
# tests/lib/trust-step4-setup.sh. Everything is under $TMP/ts4-publish. Every call names --to, a directory of the
# fixture, but one: the call with no --to is made only where /Users/Shared does not exist (P1 would write there).
#
# The fixture: r, a repository with a work tree and a directory sub, whose main (C2) follows C1; feat (C3) on C1;
# refs/remotes/origin/main at C1; refs/remotes/origin/other and refs/remotes/upstream/main at C4, a child of C2; a
# light tag at C4 and an annotated tag at C2; refs/stash and refs/notes/commits at commits of their own. r2 holds main
# alone, r3 trunk alone, r4 refs/remotes/origin/main and no branch, r5 no commit.
#
# Readings, where the spec leaves room:
# - P3's "each ref under refs/heads/ and refs/remotes/origin/main" is the whole list git bundle list-heads prints: HEAD
#   among them would fail it. "No tag" is also read as no tag object among the bundle's objects.
# - A refusal writes nothing of what section 1 writes: DIR is not made when the call is refused for another reason.
# - REPO and DIR in a refusal are printed as given; every path given here is physical (pwd -P). With no --from, the
#   current directory may be printed in any spelling, so only the line's two ends are matched.
# - "When writing fails" covers the rename: with a directory standing at DIR/source.bundle the bundle cannot be put in
#   place, and the call is refused with no temporary file left.
# - Section 5's usage error is read as status 2 alone; its line is not given, so it is not matched.
#
# Not covered: P6 (that any worker can replace the drop is not a property of this command); what publish reads (only
# that it makes no authority home); /Users/Shared/felix-authority as the default where /Users/Shared exists (the suite
# never writes there); a bundle git cannot write for want of space.
_ts4u_begin ts4-publish
TS4P_X="$TS4/x"; TS4P_R="$TS4/r"; TS4P_R2="$TS4/r2"; TS4P_R3="$TS4/r3"; TS4P_R4="$TS4/r4"; TS4P_R5="$TS4/r5"; TS4P_G=(-c user.name=worker -c user.email=worker@example.invalid)
mkdir -p "$TS4P_R/sub" "$TS4P_R2" "$TS4P_R3" "$TS4P_R4" "$TS4P_R5" "$TS4P_X/plain"
for TS4P_V in "$TS4P_R" "$TS4P_R2" "$TS4P_R3" "$TS4P_R4" "$TS4P_R5"; do _fx_git "$TS4P_V" init -q -b main >/dev/null 2>&1; _fx_git "$TS4P_V" config gc.auto 0 >/dev/null 2>&1; done
_ts4p_ci() {   # REPO TEXT: sub/a in REPO holds TEXT, committed on the branch checked out; prints the commit
  mkdir -p "$1/sub"; printf '%s\n' "$2" > "$1/sub/a"
  _fx_git "$1" add -A >/dev/null 2>&1; _fx_git "$1" "${TS4P_G[@]}" commit -q --no-gpg-sign --no-verify -m "$2" >/dev/null 2>&1
  _fx_git "$1" rev-parse -q --verify HEAD 2>/dev/null
}
_ts4p_ct() { _fx_git "$1" "${TS4P_G[@]}" commit-tree --no-gpg-sign "$2^{tree}" -p "$2" -m "$3" 2>/dev/null; }   # REPO PARENT MESSAGE: a child of PARENT
TS4P_C1="$(_ts4p_ci "$TS4P_R" one)"; TS4P_C2="$(_ts4p_ci "$TS4P_R" two)"
TS4P_C3="$(_ts4p_ct "$TS4P_R" "$TS4P_C1" feat)"; TS4P_C4="$(_ts4p_ct "$TS4P_R" "$TS4P_C2" 'another remote')"
TS4P_C5="$(_ts4p_ct "$TS4P_R" "$TS4P_C2" 'a stash')"; TS4P_C6="$(_ts4p_ct "$TS4P_R" "$TS4P_C1" 'a note')"
_fx_git "$TS4P_R" update-ref refs/heads/feat "$TS4P_C3" >/dev/null 2>&1
_fx_git "$TS4P_R" update-ref refs/remotes/origin/main "$TS4P_C1" >/dev/null 2>&1
_fx_git "$TS4P_R" update-ref refs/remotes/origin/other "$TS4P_C4" >/dev/null 2>&1
_fx_git "$TS4P_R" update-ref refs/remotes/upstream/main "$TS4P_C4" >/dev/null 2>&1
_fx_git "$TS4P_R" update-ref refs/stash "$TS4P_C5" >/dev/null 2>&1; _fx_git "$TS4P_R" update-ref refs/notes/commits "$TS4P_C6" >/dev/null 2>&1
_fx_git "$TS4P_R" tag v1 "$TS4P_C4" >/dev/null 2>&1; _fx_git "$TS4P_R" "${TS4P_G[@]}" tag -a -m 'a tag' v2 "$TS4P_C2" >/dev/null 2>&1
TS4P_T="$(_fx_git "$TS4P_R" rev-parse -q --verify refs/tags/v2 2>/dev/null)"
TS4P_D2="$(_ts4p_ci "$TS4P_R2" 'r2 one')"
_fx_git "$TS4P_R3" checkout -q -b trunk >/dev/null 2>&1; TS4P_D3="$(_ts4p_ci "$TS4P_R3" 'r3 one')"
TS4P_D4="$(_ts4p_ci "$TS4P_R4" 'r4 one')"; _fx_git "$TS4P_R4" update-ref refs/remotes/origin/main "$TS4P_D4" >/dev/null 2>&1; _fx_git "$TS4P_R4" update-ref -d refs/heads/main >/dev/null 2>&1
: > "$TS4P_X/afile"; mkdir -p "$TS4P_X/target"; ln -s "$TS4P_X/target" "$TS4P_X/dlink" 2>/dev/null

# ------------------------------------------------------------------ helpers ---
_ts4p_heads() {   # BUNDLE: the refs git bundle list-heads reads in it, as "ID REF", sorted by ref and joined by |
  [ -f "$1" ] || { printf 'no bundle'; return 1; }
  _fx_git "$TS4P_X" bundle list-heads "$1" 2>/dev/null | LC_ALL=C sort -k2 | LC_ALL=C awk '{ printf "%s%s %s", (n++ ? "|" : ""), $1, $2 }'
}
_ts4p_tmps() { ( cd "$1" 2>/dev/null && ls -A ) 2>/dev/null | LC_ALL=C awk 'index($0, ".source.bundle.") == 1 { n++ } END { print n + 0 }'; }   # DIR: its .source.bundle.* files
_ts4p_no() {   # WHAT WANT DIR ARG...: publish ARG..., run in $TS4/t, is refused with exit and stderr WANT, and DIR is as it was
  local w="$1" want="$2" d="$3" s; shift 3; s="$(_ts4_snap "$d")"
  _ts4u_pub "$TS4/t" "$@"
  if [ "$(_ts4_snap "$d")" = "$s" ]; then s=unchanged; else s=changed; fi
  _ts4_is "ts4 setup P: publish refuses $w, and leaves the directory as it was" "$(_ts4u_ref); $s" "$want; unchanged" "$(_ts4_why)"
}
_ts4p_lines() {   # DIR: what P5 says publish prints, as _ts4u_out joins it, for the bundle at DIR/source.bundle, given BRANCHES MAIN ORIGIN-MAIN SOURCE-MAIN
  printf 'published: %s/source.bundle | bytes: %s | branches: %s | main: %s | origin-main: %s | source: %s/source.bundle | source-main: %s' \
    "$1" "$({ wc -c < "$1/source.bundle"; } 2>/dev/null | tr -d ' ')" "$2" "$3" "$4" "$1" "$5"
}

# ------------------------------------------------------------------ controls ---
is "ts4 setup P (control): the repository holds main, feat, two tags, origin/main, origin/other, upstream/main, a stash and a note, and git finds no repository in x/plain" \
  "$(_fx_git "$TS4P_R" for-each-ref --format='%(refname)' 2>/dev/null | LC_ALL=C sort | tr '\n' ' ')tag object: $(_fx_git "$TS4P_R" cat-file -t "${TS4P_T:-none}" 2>/dev/null); plain: $( ( cd "$TS4P_X/plain" && git rev-parse --git-dir ) >/dev/null 2>&1 && printf 'a repository' || printf 'no repository')" \
  "refs/heads/feat refs/heads/main refs/notes/commits refs/remotes/origin/main refs/remotes/origin/other refs/remotes/upstream/main refs/stash refs/tags/v1 refs/tags/v2 tag object: tag; plain: no repository"
_fx_git "$TS4P_R" bundle create -q "$TS4P_X/by-hand.bundle" refs/heads/main >/dev/null 2>&1
is "ts4 setup P (control): this test reads a bundle's refs: one made by hand of main lists main's commit" "$(_ts4p_heads "$TS4P_X/by-hand.bundle")" "$TS4P_C2 refs/heads/main"
is "ts4 setup P (control): r2 holds main alone, r3 trunk alone, r4 refs/remotes/origin/main and no branch, and r5 no ref" \
  "$(for TS4P_V in "$TS4P_R2" "$TS4P_R3" "$TS4P_R4" "$TS4P_R5"; do printf '[%s]' "$(_fx_git "$TS4P_V" for-each-ref --format='%(refname)' 2>/dev/null | tr '\n' ' ')"; done)" \
  "[refs/heads/main ][refs/heads/trunk ][refs/remotes/origin/main ][]"

# ------------------------------------------------------------------ the drop, written (P1, P3 to P5) ---
TS4_UMASK=077; _ts4u_pub "$TS4/t" --to "$TS4/d1" --from "$TS4P_R/sub"; TS4_UMASK=022
_ts4_is "ts4 setup P5: publish prints published, bytes, branches, main, origin-main, source and source-main, in that order, and exits 0" \
  "exit $TS4_RC; $(_ts4u_out)" "exit 0; $(_ts4p_lines "$TS4/d1" 2 "$TS4P_C2" "$TS4P_C1" refs/remotes/origin/main)" "$(_ts4_why)"
_ts4_is "ts4 setup P3: the bundle holds each branch and refs/remotes/origin/main, and no tag, no other remote's ref, no stash and no note" \
  "$(_ts4p_heads "$TS4/d1/source.bundle")" "$TS4P_C3 refs/heads/feat|$TS4P_C2 refs/heads/main|$TS4P_C1 refs/remotes/origin/main"
_fx_git "$TS4P_X" init -q --bare got.git >/dev/null 2>&1; _fx_git "$TS4P_X/got.git" fetch -q "$TS4/d1/source.bundle" '+refs/*:refs/got/*' >/dev/null 2>&1
_ts4_is "ts4 setup P3: fetched, the bundle gives three refs, and not the annotated tag's object, nor the commits of the other remotes, the stash or the note" \
  "refs: $(_fx_git "$TS4P_X/got.git" for-each-ref refs/got 2>/dev/null | LC_ALL=C awk 'END { print NR }'); $(for TS4P_V in "${TS4P_T:-none}" "${TS4P_C4:-none}" "${TS4P_C5:-none}" "${TS4P_C6:-none}"; do printf '%s ' "$(_ts4_yn _fx_git "$TS4P_X/got.git" cat-file -e "$TS4P_V")"; done)" \
  "refs: 3; no no no no "
_ts4_is "ts4 setup P1, P4: under a umask of 077 the directory is made with mode 755 and the bundle given 644, and it holds source.bundle alone: no .source.bundle. file is left" \
  "$(_ts4u_m "$TS4/d1") $(_ts4u_m "$TS4/d1/source.bundle"); holds: $(_ts4u_ls "$TS4/d1")" "drwxr-xr-x -rw-r--r--; holds: source.bundle "
_ts4_is "ts4 setup P: publish makes no authority home" "$(_ts4_yn test -e "$TS4/noah")" no
_ts4u_pub "$TS4P_R/sub" --to "$TS4/d2"
_ts4_is "ts4 setup P2: with no --from the repository is the one the current directory is in" "exit $TS4_RC; $(_ts4p_heads "$TS4/d2/source.bundle")" \
  "exit 0; $TS4P_C3 refs/heads/feat|$TS4P_C2 refs/heads/main|$TS4P_C1 refs/remotes/origin/main" "$(_ts4_why)"
TS4P_V="$( ( cd "$TS4P_R" && export GIT_DIR="$TS4P_R2/.git" GIT_WORK_TREE="$TS4P_R2"; command git rev-parse -q --verify refs/heads/main ) 2>/dev/null)"
is "ts4 setup P2 (control): in r, a GIT_DIR naming r2 makes plain git read r2" "$TS4P_V" "$TS4P_D2"
TS4_ENV=(GIT_DIR="$TS4P_R2/.git" GIT_WORK_TREE="$TS4P_R2" GIT_NAMESPACE=ns); _ts4u_pub "$TS4/t" --to "$TS4/d3" --from "$TS4P_R"; TS4_ENV=()
_ts4_is "ts4 setup P2: the caller's GIT_ variables are unset: with GIT_DIR, GIT_WORK_TREE and GIT_NAMESPACE naming r2, --from r publishes r" \
  "exit $TS4_RC; $(_ts4p_heads "$TS4/d3/source.bundle")" "exit 0; $TS4P_C3 refs/heads/feat|$TS4P_C2 refs/heads/main|$TS4P_C1 refs/remotes/origin/main" "$(_ts4_why)"
_ts4u_pub "$TS4/t" --to "$TS4/d4" --from "$TS4P_R2"
_ts4_is "ts4 setup P5: a repository with main and no origin/main prints origin-main - and source-main refs/heads/main" \
  "exit $TS4_RC; $(_ts4u_out)" "exit 0; $(_ts4p_lines "$TS4/d4" 1 "$TS4P_D2" - refs/heads/main)" "$(_ts4_why)"
_ts4u_pub "$TS4/t" --to "$TS4/d5" --from "$TS4P_R3"
_ts4_is "ts4 setup P5: a repository whose one branch is trunk prints main -, origin-main - and source-main -" \
  "exit $TS4_RC; $(_ts4u_out); $(_ts4p_heads "$TS4/d5/source.bundle")" "exit 0; $(_ts4p_lines "$TS4/d5" 1 - - -); $TS4P_D3 refs/heads/trunk" "$(_ts4_why)"
mkdir -p "$TS4/d6"; printf 'not a bundle\n' > "$TS4/d6/source.bundle"; _ts4u_pub "$TS4/t" --to "$TS4/d6" --from "$TS4P_R"; TS4P_V="first: exit $TS4_RC, $(_ts4p_heads "$TS4/d6/source.bundle")"
_ts4u_pub "$TS4/t" --to "$TS4/d6" --from "$TS4P_R2"
_ts4_is "ts4 setup P4: a file there before is replaced whole, and so is a bundle: a later publish of r2 holds r2's main alone" \
  "$TS4P_V; then: exit $TS4_RC, $(_ts4p_heads "$TS4/d6/source.bundle"); temporary files: $(_ts4p_tmps "$TS4/d6")" \
  "first: exit 0, $TS4P_C3 refs/heads/feat|$TS4P_C2 refs/heads/main|$TS4P_C1 refs/remotes/origin/main; then: exit 0, $TS4P_D2 refs/heads/main; temporary files: 0" "$(_ts4_why)"
mkdir -p "$TS4/d7"; chmod 775 "$TS4/d7"; _ts4u_pub "$TS4/t" --to "$TS4/d7" --from "$TS4P_R2"
_ts4_is "ts4 setup P1: a directory there before, of mode 775, is taken and its mode left as it is" "exit $TS4_RC; $(_ts4u_m "$TS4/d7"); $(_ts4p_heads "$TS4/d7/source.bundle")" \
  "exit 0; drwxrwxr-x; $TS4P_D2 refs/heads/main" "$(_ts4_why)"

# ------------------------------------------------------------------ what publish refuses (P1 to P4) ---
_ts4p_no "a --to that is not absolute" "exit 1; stderr: felix: --to names a directory that is not an absolute path" "$TS4/t" --to rel/drop --from "$TS4P_R"
_ts4p_no "a --to with a byte outside printable ASCII" "exit 1; stderr: felix: --to names a path with a byte outside printable ASCII" "$TS4P_X" --to "$TS4P_X/caf$(printf '\303\251')" --from "$TS4P_R"
_ts4p_no "a --to with a tab" "exit 1; stderr: felix: --to names a path with a byte outside printable ASCII" "$TS4P_X" --to "$TS4P_X/a${TS4_TAB}b" --from "$TS4P_R"
_ts4p_no "a --to that is a file" "exit 1; stderr: felix: $TS4P_X/afile is not a directory" "$TS4P_X" --to "$TS4P_X/afile" --from "$TS4P_R"
_ts4p_no "a --to that is a link to a directory" "exit 1; stderr: felix: $TS4P_X/dlink is not a directory" "$TS4P_X" --to "$TS4P_X/dlink" --from "$TS4P_R"
_ts4p_no "a --to whose parent is not there" "exit 1; stderr: felix: $TS4P_X/none is not a directory" "$TS4P_X" --to "$TS4P_X/none/drop" --from "$TS4P_R"
_ts4p_no "a --to whose parent is a file" "exit 1; stderr: felix: $TS4P_X/afile is not a directory" "$TS4P_X" --to "$TS4P_X/afile/drop" --from "$TS4P_R"
: > "$TS4P_X/q\"f"
_ts4p_no "a --to that is a file whose name holds a double quote, printed escaped as section 0 says (review)" "exit 1; stderr: felix: \"$TS4P_X/q\\x22f\" is not a directory" "$TS4P_X" --to "$TS4P_X/q\"f" --from "$TS4P_R"
for TS4P_V in 700 750 711; do
  mkdir -p "$TS4P_X/m$TS4P_V"; chmod "$TS4P_V" "$TS4P_X/m$TS4P_V"
  _ts4p_no "a --to that exists with mode $TS4P_V" "exit 1; stderr: felix: $TS4P_X/m$TS4P_V cannot be read by another login" "$TS4P_X/m$TS4P_V" --to "$TS4P_X/m$TS4P_V" --from "$TS4P_R"
  chmod 755 "$TS4P_X/m$TS4P_V"
done
_ts4p_no "a --from that is in no git repository" "exit 1; stderr: felix: $TS4P_X/plain is not inside a git repository" "$TS4/d8" --to "$TS4/d8" --from "$TS4P_X/plain"
_ts4p_no "a repository with no branch, its one ref refs/remotes/origin/main" "exit 1; stderr: felix: $TS4P_R4 has no branch to publish" "$TS4/d8" --to "$TS4/d8" --from "$TS4P_R4"
_ts4p_no "a repository with no commit" "exit 1; stderr: felix: $TS4P_R5 has no branch to publish" "$TS4/d8" --to "$TS4/d8" --from "$TS4P_R5"
_ts4u_pub "$TS4/t" --to "$TS4/d8"
_ts4_is "ts4 setup P2: with no --from, run in a directory that is in no git repository, publish refuses with one line on stderr naming that, exits 1 and makes no directory" \
  "exit $TS4_RC; one line: $(_ts4_yn test "$(_ts4_rows "$TS4/e")" = 1); $(LC_ALL=C awk 'NR == 1 { print ((index($0, "felix: ") == 1 && substr($0, length($0) - 30) == " is not inside a git repository") ? "the line P2 gives" : "another line") }' "$TS4/e"); made: $(_ts4_yn test -e "$TS4/d8")" \
  "exit 1; one line: yes; the line P2 gives; made: no" "$(_ts4_why)"
if [ "$TS4U_UID" = 0 ]; then
  skip "ts4 setup P: publish refuses a directory of mode 555, where the bundle cannot be written (P4), and leaves the directory as it was" "this test runs as root, who can write a directory of mode 555"
else
  mkdir -p "$TS4/d9"; printf 'the drop before\n' > "$TS4/d9/source.bundle"; chmod 555 "$TS4/d9"
  _ts4p_no "a directory of mode 555, where the bundle cannot be written (P4)" "exit 1; stderr: felix: the bundle could not be written in $TS4/d9" "$TS4/d9" --to "$TS4/d9" --from "$TS4P_R"
  chmod 755 "$TS4/d9"
fi
mkdir -p "$TS4/d10/source.bundle"; : > "$TS4/d10/source.bundle/keep"; _ts4u_pub "$TS4/t" --to "$TS4/d10" --from "$TS4P_R"
_ts4_is "ts4 setup P4 (a reading): with a directory standing at DIR/source.bundle the bundle cannot be put in place: publish refuses, and no .source.bundle. file is left in DIR or in that directory" \
  "$(_ts4u_ref); temporary files: $(( $(_ts4p_tmps "$TS4/d10") + $(_ts4p_tmps "$TS4/d10/source.bundle") )); in the way: $(_ts4u_ls "$TS4/d10/source.bundle")" \
  "exit 1; stderr: felix: the bundle could not be written in $TS4/d10; temporary files: 0; in the way: keep " "$(_ts4_why)"

# ------------------------------------------------------------------ the CLI (section 5) and the default directory (P1) ---
_ts4u_pub "$TS4/t" --to "$TS4/d11" --from "$TS4P_R" --bogus
_ts4_is "ts4 setup 5: an unknown option is a usage error: exit 2, and no directory is made" "exit $TS4_RC; made: $(_ts4_yn test -e "$TS4/d11")" "exit 2; made: no" "$(_ts4_why)"
_ts4u_pub "$TS4/t" --from "$TS4P_R" --to
_ts4_is "ts4 setup 5: an option with no value is a usage error: exit 2" "exit $TS4_RC" "exit 2" "$(_ts4_why)"
TS4_ENV=(PATH="$TS4_PATH"); _ts4u_run "$TS4/t" self "$FELIX" help; TS4_ENV=()
_ts4_is "ts4 setup 5: felix help names publish beside init on a line of authority" \
  "exit $TS4_RC; $(LC_ALL=C awk 'index($0, "authority") && index($0, "publish") { f = 1 } END { print (f ? "named" : "not named") }' "$TS4/o")" "exit 0; named" "$(_ts4_why)"
if [ -e /Users/Shared ] || [ -L /Users/Shared ]; then
  skip "ts4 setup P1: with no --to where /Users/Shared is no directory, publish refuses with status 2" "this machine has /Users/Shared, and the suite never writes there"
else
  _ts4u_pub "$TS4/t" --from "$TS4P_R"
  _ts4_is "ts4 setup P1: with no --to where /Users/Shared is no directory, publish refuses with status 2" "$(_ts4u_ref)" "exit 2; stderr: felix: name the directory to publish to with --to" "$(_ts4_why)"
fi

_ts4u_end
unset TS4P_X TS4P_R TS4P_R2 TS4P_R3 TS4P_R4 TS4P_R5 TS4P_G TS4P_C1 TS4P_C2 TS4P_C3 TS4P_C4 TS4P_C5 TS4P_C6 TS4P_T TS4P_D2 TS4P_D3 TS4P_D4 TS4P_V
# <<< trust-step4-setup-publish
