printf '\nthe pulse commits the tree it scanned, leaves no staging of its own, and leaves out a nested repository with no commit (blind, audit b06 review round)\n'
# Written blind on 2026-10-26 from section 9 of docs/2026-10-24-audit-fixes/b06-
# pulse-and-discovery-never-promise-what-c.md (B28-B30, R1-R13) and its section P,
# without reading the code it is about. Each name is the sentence it proves.
#
# Readings, mine where the contract leaves room:
# - "After the scanner has read the change it scans" (B28a) is a wrapper in a harness
#   copy: it runs the real scanner on what it was given, then, once, after the first
#   call whose input (stdin, or a file named in its arguments) held the l.md line,
#   makes the two late writes. A run in which no call held that line fails R1-R3 and
#   says so: the scan never read the change it was there to scan.
# - "Matches HEAD" is git diff --cached --name-only printing nothing.
# - A commit fails as in part 0470: a pre-commit hook in M's .git/hooks that exits 1.
# - "Then" is order, not adjacency, as in part 1740.
# K1 is assembled at run time from pieces (A0), so no line here is a shape.
RP="$(mktemp -d "$TMP/b06r.XXXXXX")"; RP="$(cd "$RP" && pwd -P)"; _rT="$(printf '\t')"
mkdir -p "$RP/user" "$RP/bin" "$RP/h0/state"
printf '#!/bin/bash\nexit 0\n' > "$RP/bin/claude"; chmod +x "$RP/bin/claude"
_rA='ABCDEFGHIJKLMNOPQRSTUVWXYZ'; _rb='abcdefghijklmnopqrstuvwxyz'; _rd='0123456789'
_rK1="$(printf '%s%s%s%s%s' 'sk-' 'ant-' 'api03-' "$_rb$_rd" "${_rA:0:12}")"
_rkl() { printf '%s' "${1:$(( ${#1} - 12 ))}"; }
_r6_in() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }
_r6_hasl() { case "
$1
" in *"
$2
"*) return 0 ;; esac; return 1; }
_rN="backup${_rT}a nested git repository sits inside memory ("; _rC="backup${_rT}a possible credential was added to "
_rM="backup${_rT}committed"; _rP="backup${_rT}pushed and read back: "
_rQ='could not ask whether a nested repository sits inside memory'

_r6_m() {   # <dir>: M, git init -b main and a base commit of l.md, ok.md, lessons.md, m.log
  mkdir -p "$1"
  ( _fx_cd "$1" && git init -q -b main && printf 'l\n' > l.md && printf 'ok\n' > ok.md && printf 'lesson one\n' > lessons.md \
    && printf 'log one\n' > m.log && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
}
_r6_r() { git init -q --bare -b main "$2" >/dev/null 2>&1; _fx_git "$1" remote add origin "$2" >/dev/null 2>&1; _fx_git "$1" push -q origin main >/dev/null 2>&1; }
_r6_nest() { mkdir -p "$1"; ( _fx_cd "$1" && git init -q -b main && printf 'n\n' > notes.md && git add -A \
               && git -c user.name=t -c user.email=t@t commit -qm inner ) >/dev/null 2>&1; }
_r6_unborn() { mkdir -p "$1"; ( _fx_cd "$1" && git init -q -b main && printf 'unborn\n' > fixture.txt ) >/dev/null 2>&1; }
_r6_ci() { _fx_git "$1" -c user.name=t -c user.email=t@t commit -qm "$2" >/dev/null 2>&1; }
_r6_hook() { mkdir -p "$1/.git/hooks"; printf '#!/bin/sh\nexit 1\n' > "$1/.git/hooks/pre-commit"; chmod +x "$1/.git/hooks/pre-commit"; }
R6H="$RP/h0"
_r6_bk() {   # <repo> [harness]: felix_pulse_backup there under /bin/bash, home R6H; R6O is what it printed
  R6O="$(env -u CLAUDE_PLUGIN_ROOT HOME="$RP/user" FELIX_HOME="$R6H" FELIX_HOME_DIR="$R6H" PATH="$RP/bin:$PATH" \
         /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/pulse.sh" || exit 97; felix_pulse_backup "$2"' bk "${2:-$FROOT/harness}" "$1" 2>/dev/null)"
}
_r6_aw() { printf '%s\n' "$R6O" | LC_ALL=C awk -v p="$2" "$1"; }
_r6_at() { _r6_aw 'index($0, p) == 1 { print NR; exit }' "$1"; }
_r6_eq() { _r6_aw '$0 == p { print NR; exit }' "$1"; }
_r6_n()  { _r6_aw 'index($0, p) == 1 { n++ } END { print n + 0 }' "$1"; }
_r6_l()  { _r6_aw 'index($0, p) == 1 { print; exit }' "$1"; }
_r6_any() { _r6_aw 'index($0, p) { n++ } END { print n + 0 }' "$1"; }
_rv=""; _rr=""; _rvn() { _rv="$_rv; ${_rr:+$_rr: }$*"; }
_r6_is() {   # <name>: ok when nothing was noted; the detail never carries the key
  local o
  o="$R6O"; o="${o//"$_rK1"/<K1>}"
  if [ -z "$_rv" ]; then ok "$1"; else bad "$1" "${_rv#; } | last printed: $(printf '%s' "$o" | tr '\t\n' '>|' | cut -c1-700)"; fi
  _rv=""; _rr=""
}
_r6_same() { [ "$(git -C "$1" rev-parse HEAD 2>/dev/null)" = "$2" ] || _rvn "HEAD moved"; }
_r6_one() { [ "$(git -C "$1" rev-parse HEAD~1 2>/dev/null)" = "$2" ] || _rvn "HEAD did not move one commit"; }
_r6_ix() { local d; d="$(git -C "$1" diff --cached --name-only 2>/dev/null | tr '\n' ' ')"; [ -z "$d" ] || _rvn "the index does not match HEAD: [$d]"; }
_r6_nokey() { if _r6_in "$R6O" "$_rK1" || _r6_in "$R6O" "$(_rkl "$_rK1")"; then _rvn "the output holds the key or its last 12 characters"; fi; }
_r6_nohand() { [ "$(_r6_any 'staged by hand')" = 0 ] || _rvn "a line says staged by hand"; }
_r6_nopush() { [ "$(_r6_n "$_rP")" = 0 ] && [ "$(_r6_n "backup${_rT}pushed and verified: ")" = 0 ] || _rvn "a pushed and read back line, or one under the old word"; }
_r6_failed() {
  [ "$(_r6_aw 'index($0, "backup\t") == 1 && index($0, "commit FAILED") && index($0, "NOT backed up") { n++ } END { print n + 0 }' -)" -ge 1 ] \
    || _rvn "no backup line holding commit FAILED and NOT backed up"
}
_r6_committed() { [ -n "$(_r6_eq "$_rM")" ] || _rvn "no committed line"; }
_r6_none() { [ "$(_r6_n "$_rM")" = 0 ] || _rvn "a committed line"; }
_r6_newl() { [ "$(git -C "$1" show HEAD:l.md 2>/dev/null)" = "$(cat "$1/l.md")" ] || _rvn "HEAD lacks the new l.md"; }
_r6_rhead() { [ "$(git --git-dir="$2" rev-parse refs/heads/main 2>/dev/null)" = "$(git -C "$1" rev-parse HEAD 2>/dev/null)" ] || _rvn "R's main is not HEAD"; }
_r6_order() { local a c p; a="$(_r6_at "$1")"; c="$(_r6_eq "$_rM")"; p="${2:+$(_r6_at "$2")}"
  [ -n "$a" ] && [ -n "$c" ] && [ "$a" -lt "$c" ] || _rvn "order: [$1] at ${a:-none}, committed at ${c:-none}"
  [ -z "$2" ] || { [ -n "$p" ] && [ -n "$c" ] && [ "$c" -lt "$p" ]; } || _rvn "order: committed at ${c:-none}, pushed at ${p:-none}"; }
# <harness copy> <memory>: the copy's bin/secret-scan runs the real one, then, once, after a
# call whose input held the l.md line, appends a K1 line to the tracked lessons.md and
# makes a clean late.md. It reads its memory and key from files beside it.
_r6_wrap() {
  local b="$1/bin"
  [ -f "$b/secret-scan" ] && mv "$b/secret-scan" "$b/secret-scan.real" || return 1
  printf '%s\n' "$2" > "$b/r6-memory"; printf '%s\n' "$_rK1" > "$b/r6-key"
  cat > "$b/secret-scan" <<'R6_WRAPPER_EOF'
#!/bin/sh
b="${0%/*}"; t="$b/r6.in.$$"
cat > "$t"
"$b/secret-scan.real" "$@" < "$t"; rc=$?
seen=0
grep -qF 'r1 line the scan must read' "$t" 2>/dev/null && seen=1
for a in "$@"; do [ -f "$a" ] && grep -qF 'r1 line the scan must read' "$a" 2>/dev/null && seen=1; done
if [ "$seen" = 1 ] && mkdir "$b/r6.fired" 2>/dev/null; then
  m="$(cat "$b/r6-memory")"
  printf 'key %s\n' "$(cat "$b/r6-key")" >> "$m/lessons.md"
  printf 'late and clean\n' > "$m/late.md"
fi
rm -f "$t"
exit "$rc"
R6_WRAPPER_EOF
  chmod +x "$b/secret-scan"
}

printf '\nthe commit is the tree that was scanned (B28)\n'
_rh="$RP/hr"; cp -R "$FROOT/harness" "$_rh"; rm -rf "$_rh/tests"
M="$RP/m1"; R="$RP/r1.git"; _r6_m "$M"; _r6_r "$M" "$R"
_rpre=""; _r6_wrap "$_rh" "$M" || _rpre="fixture: the harness copy has no bin/secret-scan to wrap"
printf 'r1 line the scan must read\n' >> "$M/l.md"; _h0="$(git -C "$M" rev-parse HEAD)"
R6H="$RP/h0"; _r6_bk "$M" "$_rh"
[ -n "$_rpre" ] || [ -d "$_rh/bin/r6.fired" ] || _rpre="no scanner call read the l.md change, so the late writes were never made"
[ -z "$_rpre" ] || _rvn "$_rpre"
_r6_committed; [ "$(_r6_n "$_rP")" -ge 1 ] || _rvn "no pushed and read back line"
_r6_one "$M" "$_h0"; _r6_newl "$M"
[ "$(git -C "$M" show HEAD:lessons.md 2>/dev/null)" = "$(git -C "$M" show HEAD~1:lessons.md 2>/dev/null)" ] || _rvn "HEAD's lessons.md is not HEAD~1's"
! _r6_in "$(git -C "$M" show HEAD:lessons.md 2>/dev/null)" "$_rK1" || _rvn "HEAD's lessons.md holds the key"
_r6_rhead "$M" "$R"
! _r6_in "$(git --git-dir="$R" show refs/heads/main:lessons.md 2>/dev/null)" "$_rK1" || _rvn "R's lessons.md holds the key"
_r6_nokey
[ -n "$_rpre" ] || _r6_in "$(cat "$M/lessons.md" 2>/dev/null)" "$_rK1" || _rvn "the working tree's lessons.md lost the late line"
_r6_is "b06 R1: a key written into a tracked file after the scan and before the commit is neither committed nor pushed"
[ -z "$_rpre" ] || _rvn "$_rpre"
git -C "$M" cat-file -e HEAD:late.md 2>/dev/null && _rvn "HEAD holds late.md"
[ -n "$_rpre" ] || [ -f "$M/late.md" ] || _rvn "late.md left the working tree"
_r6_ix "$M"
_r6_is "b06 R2: a file made after the scan is not in the commit, and the index matches the commit after it"
[ -z "$_rpre" ] || _rvn "$_rpre"
_h1="$(git -C "$M" rev-parse HEAD)"; _r6_bk "$M"
_l="$(_r6_l "$_rC")"
{ _r6_in "$_l" lessons.md && _r6_in "$_l" 'NOT backed up'; } || _rvn "no credential line naming lessons.md and saying NOT backed up"
_r6_committed; _r6_one "$M" "$_h1"
[ "$(git -C "$M" show HEAD:late.md 2>/dev/null)" = "late and clean" ] || _rvn "HEAD lacks late.md"
for _c in HEAD HEAD~1; do ! _r6_in "$(git -C "$M" show "$_c:lessons.md" 2>/dev/null)" "$_rK1" || _rvn "$_c's lessons.md holds the key"; done
_r6_nokey
_r6_is "b06 R3: the next pulse scans what came late: lessons.md is named and left out, and late.md is committed"
M="$RP/m4"; R="$RP/r4.git"; _r6_m "$M"; printf '*.secret\n' > "$M/.gitignore"; _fx_git "$M" add .gitignore >/dev/null 2>&1; _r6_ci "$M" ignore
_r6_r "$M" "$R"; printf 'key %s\n' "$_rK1" > "$M/x.secret"; _fx_git "$M" add -f x.secret >/dev/null 2>&1; printf 'r4 change\n' >> "$M/l.md"
_h0="$(git -C "$M" rev-parse HEAD)"; _c0="$(git -C "$M" diff --cached --name-only)"
[ "$_c0" = x.secret ] || _rvn "fixture: the staged selection is [$_c0], not x.secret"
_r6_bk "$M"; _l="$(_r6_l "$_rC")"
for _w in x.secret 'staged by hand' 'NOT backed up'; do _r6_in "$_l" "$_w" || _rvn "the credential line lacks [$_w]"; done
_r6_none; _r6_same "$M" "$_h0"
[ "$(git -C "$M" diff --cached --name-only)" = "$_c0" ] || _rvn "the staged selection changed"
git -C "$M" cat-file -e HEAD:x.secret 2>/dev/null && _rvn "HEAD holds x.secret"
git --git-dir="$R" cat-file -e refs/heads/main:x.secret 2>/dev/null && _rvn "R holds x.secret"
_r6_nokey
_r6_is "b06 R4: a key in a file staged by hand that .gitignore ignores is scanned: named, staged by hand, NOT backed up, nothing committed"

printf '\nthe pulse leaves no staging of its own (B29)\n'
M="$RP/m5"; R="$RP/r5.git"; _r6_m "$M"; _r6_r "$M" "$R"; _r6_nest "$M/scraps"; printf 'r5 change\n' >> "$M/l.md"; _r6_hook "$M"
R6H="$RP/h5"; mkdir -p "$R6H/state"; printf '%s\n' "$(( $(date +%s) - 9 * 86400 ))" > "$R6H/state/pulse.last-push"
cp "$R6H/state/pulse.last-push" "$RP/stamp5"; _h0="$(git -C "$M" rev-parse HEAD)"; _r0="$(git --git-dir="$R" rev-parse refs/heads/main)"
_r6_bk "$M"; _r5o="$R6O"
_r6_in "$(_r6_l "$_rN")" scraps || _rvn "no nested line naming scraps"
_r6_failed; _r6_none; _r6_same "$M" "$_h0"; _r6_ix "$M"; _r6_nohand
_r6_is "b06 R5: a commit that fails beside a nested repository says commit FAILED and leaves nothing staged"
R6O="$_r5o"; _r6_nopush
cmp -s "$R6H/state/pulse.last-push" "$RP/stamp5" || _rvn "pulse.last-push was rewritten"
[ "$(git --git-dir="$R" rev-parse refs/heads/main 2>/dev/null)" = "$_r0" ] || _rvn "R moved"
_r6_is "b06 R6 (control): a failed commit beside a nested repository pushes nothing and leaves the push stamp as it was"
_r6_bk "$M"
_r6_in "$(_r6_l "$_rN")" scraps || _rvn "no nested line naming scraps"
_r6_failed; _r6_nohand; _r6_none; _r6_same "$M" "$_h0"; _r6_ix "$M"; _r6_nopush
cmp -s "$R6H/state/pulse.last-push" "$RP/stamp5" || _rvn "pulse.last-push was rewritten"
_r6_is "b06 R7: the next run, the commit still failing, says commit FAILED again and never staged by hand"
rm -f "$M/.git/hooks/pre-commit"; _r6_bk "$M"
_l="$(_r6_l "$_rN")"; { _r6_in "$_l" scraps && _r6_in "$_l" 'NOT backed up'; } || _rvn "no nested line naming scraps"
_r6_nohand; _r6_order "$_rN" "$_rP"; _r6_one "$M" "$_h0"; _r6_newl "$M"
[ -z "$(git -C "$M" ls-tree -r --name-only HEAD 2>/dev/null | LC_ALL=C awk 'index($0, "scraps") == 1')" ] || _rvn "HEAD holds scraps"
_r6_rhead "$M" "$R"; _r6_ix "$M"
! cmp -s "$R6H/state/pulse.last-push" "$RP/stamp5" || _rvn "pulse.last-push was not rewritten"
_r6_is "b06 R8: once the commit can succeed, the next run commits the rest and pushes it, the nested repository still left out"
R6H="$RP/h0"
M="$RP/m9"; _r6_m "$M"; printf 'r9 change\n' >> "$M/l.md"; mkdir -p "$M/notes"; printf 'key %s\n' "$_rK1" > "$M/notes/leak.md"; _r6_hook "$M"
_h0="$(git -C "$M" rev-parse HEAD)"; _rr="run 1"; _r6_bk "$M"
_r6_in "$(_r6_l "$_rC")" notes/leak.md || _rvn "no credential line naming notes/leak.md"
_r6_failed; _r6_same "$M" "$_h0"; _r6_ix "$M"; _r6_nohand; _r6_nokey
rm -f "$M/.git/hooks/pre-commit"; _rr="run 2"; _r6_bk "$M"
_r6_in "$(_r6_l "$_rC")" notes/leak.md || _rvn "no credential line naming notes/leak.md"
_r6_nohand; _r6_committed; _r6_one "$M" "$_h0"; _r6_newl "$M"; _r6_nokey
git -C "$M" cat-file -e HEAD:notes/leak.md 2>/dev/null && _rvn "HEAD holds notes/leak.md"
_r6_is "b06 R9: after a failed commit beside a file left out for a key, the next run commits the rest once it can"
M="$RP/m10"; _r6_m "$M"; printf 'r10 change\n' >> "$M/l.md"; _r6_hook "$M"
_h0="$(git -C "$M" rev-parse HEAD)"; _rr="run 1"; _r6_bk "$M"
_r6_failed; _r6_same "$M" "$_h0"; _r6_ix "$M"; _r6_nohand
rm -f "$M/.git/hooks/pre-commit"; _r6_nest "$M/scraps"; _rr="run 2"; _r6_bk "$M"
_r6_in "$(_r6_l "$_rN")" scraps || _rvn "no nested line naming scraps"
_r6_nohand; _r6_committed; _r6_one "$M" "$_h0"; _r6_newl "$M"
_r6_is "b06 R10: a failed commit with nothing left out, then a nested repository, still ends in a commit of the rest"

printf '\na nested repository with no commit is a nested repository (B30)\n'
M="$RP/m11"; R="$RP/r11.git"; _r6_m "$M"; _r6_r "$M" "$R"; printf 'r11 change\n' >> "$M/l.md"
_r6_unborn "$M/audits/x/fixture"; _r6_nest "$M/scraps"; printf 'notes beside\n' > "$M/audits/x/notes.md"
{ [ -d "$M/audits/x/fixture/.git" ] && ! git -C "$M/audits/x/fixture" rev-parse -q --verify HEAD >/dev/null 2>&1; } \
  || _rvn "fixture: audits/x/fixture is not a repository with no commit"
_h0="$(git -C "$M" rev-parse HEAD)"; _r6_bk "$M"
[ "$(_r6_n "$_rN")" = 1 ] || _rvn "$(_r6_n "$_rN") nested lines"
_l="$(_r6_l "$_rN")"
for _w in audits/x/fixture scraps 'restore EMPTY' 'NOT backed up'; do _r6_in "$_l" "$_w" || _rvn "the nested line lacks [$_w]"; done
[ "$(_r6_any "$_rQ")" = 0 ] || _rvn "a line says the pulse could not ask"
_r6_order "$_rN" "$_rP"; _r6_one "$M" "$_h0"
for _f in l.md audits/x/notes.md; do [ "$(git -C "$M" show "HEAD:$_f" 2>/dev/null)" = "$(cat "$M/$_f")" ] || _rvn "HEAD lacks the new $_f"; done
_t="$(git -C "$M" ls-tree -r --name-only HEAD 2>/dev/null | LC_ALL=C awk 'index($0, "audits/x/fixture") == 1 || index($0, "scraps") == 1')"
[ -z "$_t" ] || _rvn "HEAD holds [$_t]"
[ -z "$(git -C "$M" ls-tree -r HEAD 2>/dev/null | LC_ALL=C awk '$1 == "160000"')" ] || _rvn "a gitlink in HEAD"
[ -z "$(git -C "$M" ls-files -s 2>/dev/null | LC_ALL=C awk '$1 == "160000"')" ] || _rvn "a gitlink in the index"
_st="$(git -C "$M" status --porcelain -z 2>/dev/null | tr '\0' '\n')"
for _w in '?? audits/x/fixture/' '?? scraps/'; do _r6_hasl "$_st" "$_w" || _rvn "status lacks [$_w]"; done
git -C "$M/audits/x/fixture" rev-parse -q --verify HEAD >/dev/null 2>&1 && _rvn "the repository with no commit gained one"
[ "$(cat "$M/audits/x/fixture/fixture.txt" 2>/dev/null)" = unborn ] || _rvn "the repository with no commit lost its file"
_r6_rhead "$M" "$R"
_r6_is "b06 R11: a nested repository with no commit is named and left out beside one with a commit, and the rest is committed and pushed"
M="$RP/m12"; _r6_m "$M"; _r6_unborn "$M/audits/x/fixture"; _h0="$(git -C "$M" rev-parse HEAD)"; _r6_bk "$M"
_r6_in "$(_r6_l "$_rN")" audits/x/fixture || _rvn "no nested line naming audits/x/fixture"
[ -n "$(_r6_eq "backup${_rT}nothing else new to commit")" ] || _rvn "no nothing else new to commit line"
_r6_none; [ "$(_r6_any "$_rQ")" = 0 ] || _rvn "a line says the pulse could not ask"; _r6_same "$M" "$_h0"
_r6_is "b06 R12: a nested repository with no commit and no other change says nothing else new to commit, not that the pulse could not ask"
"$FROOT/harness/bin/secret-scan" - < "$HERE/parts/1741-pulse-commits-what-it-scanned-blind.sh" >/dev/null 2>&1; _v="$?"
is "b06 R13 (control): bin/secret-scan - passes this part" "$_v" "0"
rm -rf "$RP"
