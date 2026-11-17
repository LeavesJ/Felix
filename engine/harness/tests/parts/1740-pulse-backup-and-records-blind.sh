printf '\nthe pulse backs up what it can, says what it left out, and records no credential (blind, audit b06)\n'
# Written blind on 2026-10-24 from docs/2026-10-24-audit-fixes/b06-pulse-and-
# discovery-never-promise-what-c.md alone (A30-A60 of its section 4), before any of
# it was built and without reading the code it is about. Each name is the sentence
# it proves. One assertion per item; where the contract marks only part of an item
# [control], that part is an assertion of its own.
#
# Readings, mine where the contract leaves room:
# - "Then" in B12 and B15 is order, not adjacency: the nested or credential line,
#   then the committed line, then the push line, each later in the output.
# - A30 and A34 look for the keys in everything the backup printed, the line B15
#   names included; A40 in every file under state and in stdout.
# - A42's NAME is the remote's name, origin, and SHA12 the first 12 hex of HEAD.
# - A44-A47 read the pulse row of felix_status_rows HOME CWD with lib/resolve.sh
#   and lib/status.sh sourced under /bin/bash, from a directory no project governs.
# - A48's left-out line is a record line written by hand in the shape B12 gives it.
# - A57's deny row refuses a probe command by its name, so the credential rides in
#   an argument; the row is the test's own and is removed after, and a deny.tsv the
#   widget fixture had before is put back. A58 adds a routes row to the widget
#   project the same way, so the user-prompt hook has a table to route by.
# - A54's "unchanged" is that the text is there with no [redacted] in it, and the
#   two lines are there as line one\nline two: today's field 5 ends in an escaped
#   newline of its own, and part 0590 reads it the same way.
# K1 to K6 are assembled at run time from pieces (A0), so no line here is a shape.
BP="$(mktemp -d "$TMP/b06p.XXXXXX")"; BP="$(cd "$BP" && pwd -P)"; _bT="$(printf '\t')"
mkdir -p "$BP/user" "$BP/bin" "$BP/plain" "$BP/h0/state" "$BP/cache"
printf '#!/bin/bash\nexit 0\n' > "$BP/bin/claude"; chmod +x "$BP/bin/claude"
_kA='ABCDEFGHIJKLMNOPQRSTUVWXYZ'; _kb='abcdefghijklmnopqrstuvwxyz'; _kd='0123456789'
K1="$(printf '%s%s%s%s%s' 'sk-' 'ant-' 'api03-' "$_kb$_kd" "${_kA:0:12}")"
K2="$(printf '%s%s' AKIA "${_kA:10:16}")"
K3="$(printf '%s%s%s' ghp '_' "${_kA:0:20}${_kb:10:16}")"
K4="$(printf '%s %s' Bearer "$_kd${_kb:0:14}")"
K5="$(printf '%s%s%s' 'https://user' ':' "${_kb:12:14}@example.invalid")"
K6="$(printf '%s%s"%s"' pass 'word = ' "${_kA:5:14}")"
_kl() { printf '%s' "${1:$(( ${#1} - 12 ))}"; }
_b6_in() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }
_b6_hasl() { case "
$1
" in *"
$2
"*) return 0 ;; esac; return 1; }
NEST="backup${_bT}a nested git repository sits inside memory ("; CRED="backup${_bT}a possible credential was added to "
COMM="backup${_bT}committed"; PUSH="backup${_bT}pushed and read back: "

_bk_m() {   # <dir>: M, git init -b main and a base commit of l.md, ok.md, m.log
  mkdir -p "$1"
  ( _fx_cd "$1" && git init -q -b main && printf 'l\n' > l.md && printf 'ok\n' > ok.md && printf 'log one\n' > m.log \
    && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
}
_bk_r() { git init -q --bare -b main "$2" >/dev/null 2>&1; _fx_git "$1" remote add origin "$2" >/dev/null 2>&1; _fx_git "$1" push -q origin main >/dev/null 2>&1; }
_bk_nest() { mkdir -p "$1"; ( _fx_cd "$1" && git init -q -b main && printf 'n\n' > notes.md && git add -A \
               && git -c user.name=t -c user.email=t@t commit -qm inner ) >/dev/null 2>&1; }
_bk_ci() { _fx_git "$1" -c user.name=t -c user.email=t@t commit -qm "$2" >/dev/null 2>&1; }
_bk_m15() {   # <dir>: B15's memory: a clean line, a documented token field, K1 in a new file, K2 in the tracked m.log
  _bk_m "$1"; printf 'a clean line\n' >> "$1/l.md"; printf 'the token field is documented here\n' >> "$1/ok.md"
  mkdir -p "$1/notes"; printf 'key %s\n' "$K1" > "$1/notes/leak.md"; printf 'auth %s\n' "$K2" >> "$1/m.log"
}
_bk() {   # <repo> [harness]: felix_pulse_backup there under /bin/bash; BKO is what it printed; BKH is the home
  BKO="$(env -u CLAUDE_PLUGIN_ROOT HOME="$BP/user" FELIX_HOME="${BKH:-$BP/h0}" FELIX_HOME_DIR="${BKH:-$BP/h0}" PATH="$BP/bin:$PATH" \
         /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/pulse.sh" || exit 97; felix_pulse_backup "$2"' bk "${2:-$FROOT/harness}" "$1" 2>/dev/null)"
}
_bk_aw() { printf '%s\n' "$BKO" | LC_ALL=C awk -v p="$2" "$1"; }
_bk_at() { _bk_aw 'index($0, p) == 1 { print NR; exit }' "$1"; }
_bk_eq() { _bk_aw '$0 == p { print NR; exit }' "$1"; }
_bk_n()  { _bk_aw 'index($0, p) == 1 { n++ } END { print n + 0 }' "$1"; }
_bk_l()  { _bk_aw 'index($0, p) == 1 { print; exit }' "$1"; }
_bk_any() { _bk_aw 'index($0, p) { n++ } END { print n + 0 }' "$1"; }
_bv=""; _bvn() { _bv="$_bv; $*"; }
_bk_is() { if [ -z "$_bv" ]; then ok "$1"; else bad "$1" "${_bv#; } | printed: $(printf '%s' "$BKO" | tr '\t\n' '>|' | cut -c1-700)"; fi; _bv=""; }
_bk_order() { local a c p; a="$(_bk_at "$1")"; c="$(_bk_eq "$COMM")"; p="${2:+$(_bk_at "$2")}"
  [ -n "$a" ] && [ -n "$c" ] && [ "$a" -lt "$c" ] || _bvn "order: [$1] at ${a:-none}, committed at ${c:-none}"
  [ -z "$2" ] || { [ -n "$p" ] && [ -n "$c" ] && [ "$c" -lt "$p" ]; } || _bvn "order: committed at ${c:-none}, pushed at ${p:-none}"; }
_bk_same() { [ "$(git -C "$1" rev-parse HEAD 2>/dev/null)" = "$2" ] || _bvn "HEAD moved"; }

printf '\na nested repository is left out, the rest backed up (B12-B14)\n'
M="$BP/m30"; R="$BP/r30.git"; _bk_m "$M"; _bk_r "$M" "$R"
printf 'new lesson\n' >> "$M/l.md"; _bk_nest "$M/scraps"; _bk_nest "$M/a  b"
_h0="$(git -C "$M" rev-parse HEAD)"; _s0="$(git -C "$M/scraps" rev-parse HEAD)"; _ab0="$(git -C "$M/a  b" rev-parse HEAD)"
_bk "$M"
[ "$(_bk_n "$NEST")" = 1 ] || _bvn "$(_bk_n "$NEST") nested lines"
_l="$(_bk_l "$NEST")"
for _w in scraps 'a  b' 'restore EMPTY' 'NOT backed up'; do _b6_in "$_l" "$_w" || _bvn "the nested line lacks [$_w]"; done
_bk_order "$NEST" "$PUSH"
[ "$(git -C "$M" rev-parse HEAD~1 2>/dev/null)" = "$_h0" ] || _bvn "HEAD did not move one commit"
[ "$(git -C "$M" show HEAD:l.md 2>/dev/null)" = "$(cat "$M/l.md")" ] || _bvn "HEAD lacks the new l.md"
_t="$(git -C "$M" ls-tree -r -z --name-only HEAD 2>/dev/null | tr '\0' '\n' | LC_ALL=C awk 'index($0, "scraps") == 1 || index($0, "a  b") == 1')"
[ -z "$_t" ] || _bvn "HEAD holds [$_t]"
[ "$(git -C "$M" ls-tree -r HEAD | awk '$1 == "160000"')" = "$(git -C "$M" ls-tree -r "$_h0" | awk '$1 == "160000"')" ] || _bvn "a new 160000 entry in HEAD"
[ -z "$(git -C "$M" ls-files -s | awk '$1 == "160000"')" ] || _bvn "a gitlink in the index"
_st="$(git -C "$M" status --porcelain -z 2>/dev/null | tr '\0' '\n')"
for _w in '?? scraps/' '?? a  b/'; do _b6_hasl "$_st" "$_w" || _bvn "status lacks [$_w]"; done
[ "$(git -C "$M/scraps" rev-parse HEAD)" = "$_s0" ] && [ "$(git -C "$M/a  b" rev-parse HEAD)" = "$_ab0" ] || _bvn "a nested HEAD moved"
[ -z "$(git -C "$M/scraps" status --porcelain)$(git -C "$M/a  b" status --porcelain)" ] || _bvn "a nested work tree changed"
[ "$(git --git-dir="$R" rev-parse refs/heads/main 2>/dev/null)" = "$(git -C "$M" rev-parse HEAD)" ] || _bvn "R's main is not HEAD"
_bk_is "b06 A30: new nested repositories are named and left out, NOT backed up, and the rest is committed and pushed"
M="$BP/m31"; _bk_m "$M"; _bk_nest "$M/legacy"; _fx_git "$M" add -A >/dev/null 2>&1; _bk_ci "$M" "legacy link"
[ -n "$(git -C "$M" ls-tree HEAD legacy | awk '$1 == "160000"')" ] || _bvn "fixture: no gitlink in HEAD"
printf 'new\n' >> "$M/l.md"; _bk "$M"
[ "$(_bk_n "$COMM")" -ge 1 ] || _bvn "no committed line"; [ "$(_bk_any legacy)" = 0 ] || _bvn "the old link is named"
_bk_is "b06 A31 (control): a gitlink already in HEAD is not new: the change is committed and the link is not named"
M="$BP/m32"; R="$BP/r32.git"; _bk_m "$M"; _bk_r "$M" "$R"
printf 'by hand\n' >> "$M/l.md"; _fx_git "$M" add l.md >/dev/null 2>&1; _bk_ci "$M" "by hand"; _bk_nest "$M/scraps"
_h0="$(git -C "$M" rev-parse HEAD)"
[ "$(git --git-dir="$R" rev-parse refs/heads/main 2>/dev/null)" != "$_h0" ] || _bvn "fixture: R already at HEAD"
_bk "$M"
_b6_in "$(_bk_l "$NEST")" scraps || _bvn "no nested line naming scraps"
[ "$(_bk_n "$COMM")" = 0 ] || _bvn "a committed line"; [ "$(_bk_any 'commit FAILED')" = 0 ] || _bvn "a commit FAILED line"
[ -n "$(_bk_eq "backup${_bT}nothing else new to commit")" ] || _bvn "no nothing else new to commit line"
_bk_same "$M" "$_h0"; [ "$(git --git-dir="$R" rev-parse refs/heads/main 2>/dev/null)" = "$_h0" ] || _bvn "R did not move to HEAD"
[ "$(_bk_n "$PUSH")" -ge 1 ] || _bvn "no pushed and read back line"
_bk_is "b06 A32: only a nested repository new: nothing else new to commit, HEAD unchanged, and the push still runs"
M="$BP/m33"; _bk_m "$M"; printf 'a\n' > "$M/a.md"; printf 'b\n' > "$M/b.md"; _fx_git "$M" add a.md b.md >/dev/null 2>&1; _bk_ci "$M" ab
_bk_nest "$M/nested"; printf 'staged\n' >> "$M/a.md"; printf 'unstaged\n' >> "$M/b.md"; _fx_git "$M" add a.md >/dev/null 2>&1
_h0="$(git -C "$M" rev-parse HEAD)"; _c0="$(git -C "$M" diff --cached --name-only)"
_bk "$M"; _l="$(_bk_l "$NEST")"
for _w in nested 'restore EMPTY' 'staged by hand' 'NOT backed up'; do _b6_in "$_l" "$_w" || _bvn "the nested line lacks [$_w]"; done
[ "$(_bk_n "$COMM")" = 0 ] || _bvn "a committed line"; _bk_same "$M" "$_h0"
[ "$(git -C "$M" diff --cached --name-only)" = "$_c0" ] || _bvn "the staged selection changed"
_bk_is "b06 A33: a nested repository beside a selection staged by hand is named, nothing is committed, and the selection is kept"

printf '\na file that gains a credential is left out (B15-B17)\n'
M="$BP/m34"; _bk_m15 "$M"; _h0="$(git -C "$M" rev-parse HEAD)"; _bk "$M"
[ "$(_bk_n "$CRED")" = 1 ] || _bvn "$(_bk_n "$CRED") credential lines"
_l="$(_bk_l "$CRED")"
for _w in notes/leak.md m.log 'NOT backed up'; do _b6_in "$_l" "$_w" || _bvn "the credential line lacks [$_w]"; done
for _w in "$K1" "$K2" "$(_kl "$K1")" "$(_kl "$K2")"; do ! _b6_in "$BKO" "$_w" || _bvn "the output holds a key or its last 12 characters"; done
_bk_order "$CRED" ""
[ "$(git -C "$M" rev-parse HEAD~1 2>/dev/null)" = "$_h0" ] || _bvn "HEAD did not move one commit"
for _f in l.md ok.md; do [ "$(git -C "$M" show "HEAD:$_f" 2>/dev/null)" = "$(cat "$M/$_f")" ] || _bvn "HEAD lacks the new $_f"; done
git -C "$M" cat-file -e HEAD:notes/leak.md 2>/dev/null && _bvn "HEAD holds notes/leak.md"
[ "$(git -C "$M" show HEAD:m.log 2>/dev/null)" = "$(git -C "$M" show HEAD~1:m.log 2>/dev/null)" ] || _bvn "HEAD's m.log is not HEAD~1's"
_b6_in "$(cat "$M/notes/leak.md")" "$K1" && _b6_in "$(cat "$M/m.log")" "$K2" || _bvn "the working tree was touched"
_bk_is "b06 A34: files that gained a credential are named and left out, NOT backed up, without the keys, and the rest is committed"
_bsc="$FROOT/harness/bin/secret-scan"; _v=""
for _k in "$K1" "$K2" "$K3" "$K4" "$K5" "$K6"; do printf '%s\n' "$_k" | "$_bsc" - >/dev/null 2>&1; _v="$_v $?"; done
printf 'the token field is documented here\n' | "$_bsc" - >/dev/null 2>&1; _v="$_v / $?"
is "b06 A35 (control): bin/secret-scan - flags each of K1 to K6 and passes the documented token field" "$_v" " 1 1 1 1 1 1 / 0"
M="$BP/m36"; mkdir -p "$M"; ( _fx_cd "$M" && git init -q -b main ) >/dev/null 2>&1
printf 'key %s\n' "$K1" > "$M/leak.md"; printf 'a\n' > "$M/a.md"; _bk "$M"
_b6_in "$(_bk_l "$CRED")" leak.md || _bvn "no credential line naming leak.md"
[ "$(git -C "$M" ls-tree -r --name-only HEAD 2>/dev/null)" = a.md ] || _bvn "the first commit holds [$(git -C "$M" ls-tree -r --name-only HEAD 2>/dev/null | tr '\n' ' ')]"
_bk_is "b06 A36: on an unborn branch a new file with a key is named and left out, and the first commit holds the rest"
M="$BP/m37"; _bk_m "$M"; printf 'a\n' > "$M/a.md"; _fx_git "$M" add a.md >/dev/null 2>&1; _bk_ci "$M" a
printf 'staged\n' >> "$M/a.md"; _fx_git "$M" add a.md >/dev/null 2>&1; printf 'key %s\n' "$K1" > "$M/k.md"
_h0="$(git -C "$M" rev-parse HEAD)"; _c0="$(git -C "$M" diff --cached --name-only)"; _bk "$M"; _l="$(_bk_l "$CRED")"
for _w in k.md 'staged by hand' 'NOT backed up'; do _b6_in "$_l" "$_w" || _bvn "the credential line lacks [$_w]"; done
[ "$(_bk_n "$COMM")" = 0 ] || _bvn "a committed line"; _bk_same "$M" "$_h0"
[ "$(git -C "$M" diff --cached --name-only)" = "$_c0" ] || _bvn "the staged selection changed"
_bk_is "b06 A37: a credential beside a selection staged by hand is named, nothing is committed, and the selection is kept"
_bhc="$BP/hc"; cp -R "$FROOT/harness" "$_bhc"; rm -rf "$_bhc/tests"; rm -f "$_bhc/bin/secret-scan"
M="$BP/m38"; R="$BP/r38.git"; _bk_m "$M"; _bk_r "$M" "$R"; printf 'change\n' >> "$M/l.md"
_h0="$(git -C "$M" rev-parse HEAD)"; _r0="$(git --git-dir="$R" rev-parse refs/heads/main 2>/dev/null)"; _bk "$M" "$_bhc"
_l="$(_bk_l "backup${_bT}could not scan what would be committed for credentials (")"
[ -n "$_l" ] || _bvn "no could not scan line"; _b6_in "$_l" 'NOT backed up' || _bvn "the line does not say NOT backed up"
[ "$(_bk_n "$COMM")" = 0 ] || _bvn "a committed line"; _bk_same "$M" "$_h0"
[ "$(git --git-dir="$R" rev-parse refs/heads/main 2>/dev/null)" = "$_r0" ] || _bvn "R moved"
_bk_is "b06 A38: with no scanner a change is not committed and not pushed, and the pulse says it could not scan"
_fx_git "$M" checkout -q -- l.md >/dev/null 2>&1; _bk "$M" "$_bhc"
[ -n "$(_bk_eq "backup${_bT}nothing new to commit")" ] || _bvn "no nothing new to commit line"
_bk_is "b06 A39 (control): with no scanner and no change the pulse says nothing new to commit"

printf '\nend to end, nothing leaks into Felix'"'"'s records (B18)\n'
M="$BP/m40"; _bk_m15 "$M"; H="$BP/h40"; mkdir -p "$H/projects" "$H/state"
_o="$(cd "$BP/plain" && env -u CLAUDE_PLUGIN_ROOT -u CLAUDE_CONFIG_DIR HOME="$BP/user" FELIX_HOME="$H" FELIX_HOME_DIR="$H" FELIX_MEMORY="$M" \
      PATH="$BP/bin:$PATH" "$FELIX" pulse 2>/dev/null)"; _rc=$?
_bcl() { LC_ALL=C awk 'index($0, "a possible credential was added to ") && index($0, "notes/leak.md") { n++ } END { print n + 0 }' "$1" 2>/dev/null; }
[ "$_rc" = 0 ] || _bvn "felix pulse exited $_rc"
[ "$(_bcl "$H/state/pulse.status.tsv")" -ge 1 ] || _bvn "the record lacks the credential line"
[ "$(_bcl "$H/state/pulse.log")" -ge 1 ] || _bvn "pulse.log lacks the credential line"
for _k in "$K1" "$K2"; do
  [ -z "$(grep -rlF -- "$_k" "$H/state" 2>/dev/null)" ] || _bvn "a file under state holds a key"
  ! _b6_in "$_o" "$_k" || _bvn "stdout holds a key"
done
BKO="$_o"; _bk_is "b06 A40: felix pulse exits 0, its record and log name notes/leak.md, and no file under state nor stdout holds K1 or K2"

printf '\nwhere the verified copy is (B19)\n'
W="$BP/w41"; mkdir -p "$W"; ( _fx_cd "$W" && git init -q -b main ) >/dev/null 2>&1; _i=0
for _u in /abs/m.git ../rel.git rel.git ./a:b.git file:///abs/m.git https://example.invalid/m.git ssh://git@example.invalid/m.git \
          git@example.invalid:m.git example.invalid:m.git "$K5/m.git" fx::/abs/m.git; do
  _i="$(( _i + 1 ))"; _fx_git "$W" remote add "r$_i" "$_u" >/dev/null 2>&1
done
_bw() { env HOME="$BP/user" /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/pulse.sh" || exit 97; o="$(felix_pulse_remote_where "$2" "$3")"; r=$?; printf "%s|%s" "$o" "$r"' \
          wh "$FROOT/harness" "$W" "$1" 2>/dev/null; }
_v=""; for _n in r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 nope; do _v="$_v $_n=$(_bw "$_n")"; done
is "b06 A41: felix_pulse_remote_where prints one word for each remote, disk, network or unknown, exits 0, and network for a URL with userinfo" "$_v" \
   " r1=disk|0 r2=disk|0 r3=disk|0 r4=disk|0 r5=disk|0 r6=network|0 r7=network|0 r8=network|0 r9=network|0 r10=network|0 r11=unknown|0 nope=unknown|0"
M="$BP/m42"; R="$BP/r42.git"; _bk_m "$M"; _bk_r "$M" "$R"
_b42() {   # <home>: one verified push with BKH there; a verdict of the disk line and the two files
  mkdir -p "$1/state"; printf 'x %s\n' "$1" >> "$M/l.md"; BKH="$1" _bk "$M"
  local s; s="$(git -C "$M" rev-parse HEAD | cut -c1-12)"
  [ -n "$(_bk_eq "backup${_bT}pushed and read back: origin holds $s; origin is a path on this machine, so this copy is only as far from this disk as whatever syncs that path")" ] \
    || printf 'no disk line [%s]; ' "$(_bk_l "$PUSH")"
  LC_ALL=C awk 'NR == 1 && /^[0123456789]+$/ { d = 1 } END { exit !(d && NR == 1) }' "$1/state/pulse.last-push" 2>/dev/null || printf 'no stamp; '
  LC_ALL=C awk 'NR == 1 && $0 == "disk" { d = 1 } END { exit !(d && NR == 1) }' "$1/state/pulse.last-push.where" 2>/dev/null || printf 'where is not disk; '
}
_v="$(_b42 "$BP/h42a")"; _fx_git "$M" remote set-url origin "file://$R" >/dev/null 2>&1; _v="$_v/ $(_b42 "$BP/h42b")"
is "b06 A42: a verified push to a path, or file:// and a path, says the copy is a path on this machine and writes the stamp and disk" "$_v" "/ "
M="$BP/m43"; _bk_m "$M"; git init -q --bare -b main "$BP/r43f.git" >/dev/null 2>&1; git init -q --bare -b main "$BP/r43p.git" >/dev/null 2>&1
_fx_git "$M" remote add origin "$BP/r43f.git" >/dev/null 2>&1; _fx_git "$M" remote set-url --push origin "$BP/r43p.git" >/dev/null 2>&1
printf 's\n' >> "$M/l.md"; mkdir -p "$BP/h43/state"; BKH="$BP/h43" _bk "$M"
is "b06 A43 (control): a push nothing reads back writes no pulse.last-push" "$([ -e "$BP/h43/state/pulse.last-push" ] && echo written || echo none)" "none"
is "b06 A43: nor pulse.last-push.where" "$([ -e "$BP/h43/state/pulse.last-push.where" ] && echo written || echo none)" "none"

printf '\nfelix status'"'"'s pulse row (B20)\n'
H="$BP/h44"; mkdir -p "$H/projects" "$H/state"
printf 'pulse\tx\n' > "$H/state/pulse.log"; printf '# ran 86400\n' > "$H/state/pulse.status.tsv"
printf '%s\n' "$(( $(date +%s) - 2 * 86400 - 60 ))" > "$H/state/pulse.last-push"
_bst() { env -u CLAUDE_PLUGIN_ROOT -u CLAUDE_CONFIG_DIR HOME="$BP/user" FELIX_HOME="$H" FELIX_HOME_DIR="$H" PATH="$BP/bin:$PATH" \
           /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/status.sh" || exit 97; felix_status_rows "$2" "$3"' st "$FROOT/harness" "$H" "$BP/plain" 2>/dev/null \
           | LC_ALL=C awk -F'\t' '$1 == "pulse"'; }
_bD='days since memory reached its remote'; _bR="pulse${_bT}value${_bT}2${_bT}$_bD"
printf 'disk\n' > "$H/state/pulse.last-push.where"
is "b06 A44: a disk where file adds a path on this machine to the pulse row" "$(_bst)" "$_bR, a path on this machine; last run 1970-01-02T00:00Z"
printf 'garbage\n' > "$H/state/pulse.last-push.where"
is "b06 A45: a where file holding anything else says a remote whose place could not be read" "$(_bst)" \
   "$_bR, a remote whose place could not be read; last run 1970-01-02T00:00Z"
printf 'disk\n' > "$H/state/pulse.last-push.where"
printf '# ran 86400\nbackup\tcommit FAILED; nothing was pushed, and this memory is NOT backed up\n' > "$H/state/pulse.status.tsv"
is "b06 A46: a record with a backup line saying NOT backed up adds that the last run did not back up all of memory" "$(_bst | cut -f4)" \
   "$_bD, a path on this machine; the last run did not back up all of memory (felix pulse says why); last run 1970-01-02T00:00Z"
rm -f "$H/state/pulse.last-push.where"; printf '# ran 86400\n' > "$H/state/pulse.status.tsv"
is "b06 A47 (control): with no where file and no such line the pulse row is part 1100's" "$(_bst)" "$_bR; last run 1970-01-02T00:00Z"

printf '\nsession start says what the pulse left out, and what a cloud session loses (B21, B22)\n'
SH="$BP/sh"; mkdir -p "$SH/projects/sp" "$SH/state" "$BP/smem" "$BP/sco"
printf '{"name": "sp", "gate": "true"}\n' > "$SH/projects/sp/project.json"; printf '# sp\n' > "$SH/projects/sp/CLAUDE.md"
( _fx_cd "$BP/sco" && git init -q -b main && printf 'sp\n' > .felix && printf 'x\n' > f.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
SCO="$(cd "$BP/sco" && pwd -P)"
_bss() {   # [NAME=VALUE...]: one SessionStart in the sp checkout; BSC is its additionalContext
  BSC="$(cd "$SCO" && printf '{"session_id":"b06-ss","hook_event_name":"SessionStart","source":"startup"}' \
         | env -u CLAUDE_CONFIG_DIR -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_REMOTE HOME="$BP/user" FELIX_HOME="$SH" FELIX_HOME_DIR="$SH" \
               FELIX_MEMORY="$BP/smem" FELIX_PLUGIN_CACHE="$BP/cache" PATH="$BP/bin:$PATH" CLAUDE_PLUGIN_ROOT="$FROOT" "$@" \
               "$FROOT/harness/hooks/session-start" 2>/dev/null | python3 -c 'import json, sys
try: d = json.loads(sys.stdin.read())
except Exception: sys.exit(3)
sys.stdout.write((d.get("hookSpecificOutput") or {}).get("additionalContext") or d.get("additionalContext") or "")' 2>/dev/null)"
}
_bsr="$SH/state/pulse.status.tsv"; _bsp="$SH/state/pulse.last-push"; _bL="did not back up all of memory"
printf 'pulse\tx\n' > "$SH/state/pulse.log"; date +%s > "$_bsp"
printf '# ran 86400\nbackup\ta nested git repository sits inside memory (audits/x/fixture): restore EMPTY there; it is NOT backed up\n' > "$_bsr"
_bss; _v=""
_b6_in "$BSC" "The last pulse, at 1970-01-02T00:00Z, did not back up all of memory:" || _v="$_v lacks-the-sentence"
_b6_in "$BSC" "audits/x/fixture" || _v="$_v lacks-the-path"
is "b06 A48: a record with a line saying NOT backed up is said at session start, with its time, though the stamp is from today" "${_v:-said}" "said"
printf '# ran 86400\nbackup\tcommitted\nbackup\tpushed and read back: r holds 0123456789ab\n' > "$_bsr"; _bss
_v="$(_b6_in "$BSC" "$_bL" && echo said || echo quiet)"; rm -f "$_bsr"; _bss
is "b06 A49 (control): no such line, or no record, says no such paragraph" "$_v $(_b6_in "$BSC" "$_bL" && echo said || echo quiet)" "quiet quiet"
rm -f "$_bsp"; _bss; _v="$(_b6_in "$BSC" "never once got memory off this disk" && echo never)"
printf '%s\n' "$(( $(date +%s) - 9 * 86400 - 60 ))" > "$_bsp"; _bss; _v="$_v $(_b6_in "$BSC" "Memory last reached the remote 9 days ago" && echo nine)"
date +%s > "$_bsp"; _bss
_v="$_v $(_b6_in "$BSC" "never once got memory off this disk" && echo never)$(_b6_in "$BSC" "Memory last reached the remote" && echo reached)"
is "b06 A50 (control): the age banners are unchanged: never with no stamp, 9 days with a stamp 9 days old, neither with one from today" "$_v" "never nine "
printf '# ran soon\nbackup\tcommit FAILED; nothing was pushed, and this memory is NOT backed up\n' > "$_bsr"; _bss
is "b06 A51: a record whose first line is not # ran <digits> is said at a time not recorded" \
   "$(_b6_in "$BSC" "$_bL" && _b6_in "$BSC" "at a time not recorded" && echo said || echo quiet)" "said"
rm -f "$_bsr"
_bC="This is a cloud session: nothing backs up the memory directory above from here, and unless it sits on storage that outlives this machine, what Felix records in it (lessons, catches, declines, the ledger) is lost with the machine."
_v=""; for _c in true false 1 TRUE; do _bss CLAUDE_CODE_REMOTE="$_c"; _v="$_v $_c:$(_b6_in "$BSC" "$_bC" && echo told || echo silent)"; done
is "b06 A52: CLAUDE_CODE_REMOTE=true tells the session its memory dies with the machine, and false, 1 or TRUE does not" "$_v" " true:told false:silent 1:silent TRUE:silent"
_bss; is "b06 A52 (control): with CLAUDE_CODE_REMOTE unset the sentence is absent" "$(_b6_in "$BSC" "$_bC" && echo told || echo silent)" "silent"

printf '\nwhat Felix records holds no credential (B23-B26)\n'
SM="$BP/mem"; mkdir -p "$SM/sayp" "$SM/rp" "$BP/sayp" "$BP/rp"
_bsay() { env HOME="$BP/user" FELIX_MEMORY="$SM" /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/say.sh" || exit 97; shift; felix_say "$@"' say "$FROOT/harness" "$@" >/dev/null 2>&1; }
_brl() { env HOME="$BP/user" FELIX_MEMORY="$SM" /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/route.sh" || exit 97; shift; felix_route_log "$@"' rl "$FROOT/harness" "$@" >/dev/null 2>&1; }
_bK="$K1 and $K2 and $K3 and $K4 and $K5 and $K6"; _bsl="$SM/sayp/says.log"
_bsay "$BP/sayp" denied "text $_bK" "cause $_bK" b06-sess
[ "$(LC_ALL=C awk -F'\t' 'NF == 5 { n++ } END { print NR "/" n + 0 }' "$_bsl" 2>/dev/null)" = 1/1 ] || _bvn "says.log is not one 5-field line"
for _f in 4 5; do
  _x="$(cut -f"$_f" "$_bsl" 2>/dev/null)"; _b6_in "$_x" "[redacted]" || _bvn "field $_f lacks [redacted]"
  for _k in "$K1" "$K2" "$K3" "$K4" "$K5" "$K6"; do ! _b6_in "$_x" "$_k" || _bvn "field $_f holds a key"; done
done
"$_bsc" - < "$_bsl" >/dev/null 2>&1 || _bvn "bin/secret-scan flags says.log"
_bsay "$BP/sayp" denied "plain" "$(printf '%0190d' 0 | tr 0 x)$K1" b06-sess
! _b6_in "$(tail -1 "$_bsl" | cut -f4)" "sk-ant" || _bvn "a key cut at 200 characters is left in field 4"
BKO=""; _bk_is "b06 A53: felix_say writes [redacted] for every key in its text and cause, before the cause is cut, and the log scans clean"
_bsay "$BP/sayp" brief "the token field is documented" "why I asked" b06-ctl; _x="$(tail -1 "$_bsl" | cut -f5)"
_v="$(tail -1 "$_bsl" | cut -f2-4)|$(_b6_in "$_x" "the token field is documented" && echo kept)$(_b6_in "$_x" "[redacted]" && echo redacted)"
_bsay "$BP/sayp" brief "line one
line two" "c" b06-ctl
is "b06 A54 (control): text with no key is written unchanged, and a newline still becomes \\n" \
   "$_v|$(_b6_in "$(tail -1 "$_bsl" | cut -f5)" 'line one\nline two' && echo escaped)" "brief${_bT}b06-ctl${_bT}why I asked|kept|escaped"
_brl "$BP/rp" - 0 "{\"session_id\":\"s\",\"prompt\":\"deploy with $K1 now\"}"; _x="$(tail -1 "$SM/rp/routes.log" 2>/dev/null | cut -f4)"
_v="$(_b6_in "$_x" "[redacted]" && echo redacted) $(_b6_in "$_x" "$K1" && echo key)"
_brl "$BP/rp" - 0 "$(printf '%0150d' 0 | tr 0 x)$K1"; _x="$(tail -1 "$SM/rp/routes.log" 2>/dev/null | cut -f4)"
_v="$_v / $(printf '%s' "$_x" | LC_ALL=C wc -c | tr -d ' ') $(_b6_in "$_x" "sk-ant" && echo key)"
is "b06 A55: felix_route_log writes [redacted] for a key, before the 160-byte cut" "$_v" "redacted  / 160 "
_brl "$BP/rp" - 0 '{"session_id":"s","prompt":"repair the queue worker"}'; _x="$(tail -1 "$SM/rp/routes.log" 2>/dev/null | cut -f4)"
_r="$(env HOME="$BP/user" /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/monitor.sh" || exit 97; _felix_mon_prompt "$2"' mp "$FROOT/harness" "$_x" 2>/dev/null)"
is "b06 A56 (control): a prompt with no key is logged with no [redacted], and the monitor still renders it" \
   "$(_b6_in "$_x" "repair the queue worker" && echo kept) $(_b6_in "$_x" "[redacted]" && echo redacted)|$_r" "kept |repair the queue worker"
_bdt="$FROOT/projects/widget/deny.tsv"; _bdk=0; [ -f "$_bdt" ] && { cp "$_bdt" "$BP/deny.keep"; _bdk=1; }
printf 'Bash\t(^|[;&| ])b06-deny-probe( |$)\tb06: the probe command is refused\n' > "$_bdt"
_bdn() { [ -f "$MEM/widget/says.log" ] || { echo 0; return 0; }; LC_ALL=C awk -F'\t' '$2 == "denied" { n++ } END { print n + 0 }' "$MEM/widget/says.log"; }
_bnr() { [ -f "$1" ] || { echo 0; return 0; }; LC_ALL=C awk 'END { print NR }' "$1"; }
_d0="$(_bdn)"; ( cd "$REPO" && _pre "$(printf '{"tool_name":"Bash","tool_input":{"command":"b06-deny-probe -H %s"}}' "'Authorization: $K4'")" ); _rc=$?
_x="$(LC_ALL=C awk -F'\t' '$2 == "denied"' "$MEM/widget/says.log" 2>/dev/null | tail -1)"
[ "$_rc" = 2 ] || _bvn "the hook exited $_rc"; _b6_in "$(cat "$FROOT/.deny-err" 2>/dev/null)" "b06: the probe command is refused" || _bvn "no reason on stderr"
[ "$(_bdn)" -gt "$_d0" ] || _bvn "no denied line was added"
_b6_in "$_x" "[redacted]" || _bvn "the denied line lacks [redacted]"; ! _b6_in "$_x" "$K4" || _bvn "the denied line holds K4"
if [ "$_bdk" = 1 ]; then cp "$BP/deny.keep" "$_bdt"; else rm -f "$_bdt"; fi; rm -f "$FROOT/.deny-err"
BKO=""; _bk_is "b06 A57: a Bash command carrying a bearer token is refused as today, and its denied line holds [redacted], not the token"
_brt="$FROOT/projects/widget/routes.tsv"; _brk=0; [ -f "$_brt" ] && { cp "$_brt" "$BP/routes.keep"; _brk=1; }
printf 'b06probe\tdeploy release\tcore\t-\n' >> "$_brt"; _u0="$(_bnr "$MEM/widget/routes.log")"
( cd "$REPO" && printf '{"session_id":"b06-up","prompt":"deploy with %s now"}' "$K1" | "$FROOT/harness/hooks/user-prompt" ) >/dev/null 2>&1
_x="$(tail -1 "$MEM/widget/routes.log" 2>/dev/null)"; if [ "$_brk" = 1 ]; then cp "$BP/routes.keep" "$_brt"; else rm -f "$_brt"; fi
is "b06 A58: the user-prompt hook logs a prompt carrying a key with [redacted], not the key" \
   "$([ "$(_bnr "$MEM/widget/routes.log")" -gt "$_u0" ] && echo logged) $(_b6_in "$_x" "[redacted]" && echo redacted) $(_b6_in "$_x" "$K1" && echo key)" \
   "logged redacted "
is "b06 A59 (control): exactly one file under the harness defines the credential shapes" \
   "$(grep -rl '^FELIX_SCAN_PATTERNS=' "$FROOT/harness" 2>/dev/null | wc -l | tr -d ' ')" "1"
_v=""; for _f in 1730-discovery-never-promises-blind.sh 1740-pulse-backup-and-records-blind.sh; do "$_bsc" - < "$HERE/parts/$_f" >/dev/null 2>&1; _v="$_v $?"; done
is "b06 A60: bin/secret-scan - passes both of this batch's blind parts" "$_v" " 0 0"
rm -rf "$BP"
