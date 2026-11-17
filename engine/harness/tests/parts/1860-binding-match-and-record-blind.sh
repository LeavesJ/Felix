printf '\nthe binding by remote, its record, and the root walk (audit b12: C046, C031, C061; blind)\n'
# Written blind on 2026-10-24 from docs/2026-10-24-audit-fixes/b12-judge-base-and-binding-read-what-is-
# comm.md (B21 to B32, assertions 45 to 83), before the fix, with no engine code read. Each assertion is
# named b12 A<n> after the contract's number; where an item has a [red] half and a [control] half, the
# control half is an assertion of its own, "A<n> control". The call shapes are the ones parts 0204,
# 0220 and 1130 use: felix_resolve_project START HOME prints the bound project's directory, and the
# hooks run in the checkout with FELIX_HOME, FELIX_MEMORY and a payload naming it as cwd.
#
# Readings, where the contract leaves room. "Names P" is P standing as a word: no letter, digit or
# underscore either side of it. A checkout that runs a hook carries one commit. B28's unreadable
# bindings.tsv (a hand-written line naming el, in a memory root of its own) and its ../x line are
# tried in the rename state, where the record is all that could make a sentence, and the ../x line
# names a directory HOME/x that holds no project.json; the unwritable memory root is tried with the
# checkout bound, and the other home holds projects/el with no project.json. B30's line naming el is
# tried with projects/el a directory holding no project.json. B25's "no file holds any part of U" is
# read at the end, over every file the record's calls and hooks left under the memory roots, for
# SECRET-b12 and github.com/acme. A70 and the unreadable-bindings case of A74 need a user that mode 000
# stops, so they are left out when id -u is 0.
#
# Fixture B (B22): a home of eleven projects and one checkout whose origin is set row by row, plus a
# marked one. Fixture L (B25): a home holding el (acme/el) and other (acme/other) and CO, whose origin
# carries userinfo. Fixture O (B24): a home whose one project declares OWNERX/OWNP-REPO. Fixture R (B31):
# a repository with a subdirectory, a worktree of it and a directory outside git. All under one
# mktemp -d in $TMP; every call sets HOME there, GIT_CONFIG_NOSYSTEM, and a memory root of its own.
N12="$(mktemp -d "$TMP/b12n.XXXXXX" 2>/dev/null)" && N12="$(cd "$N12" && pwd -P)" || N12=""
if [ -z "$N12" ] || [ ! -d "$N12" ]; then
  bad "b12 1860 fixture: mktemp -d made a directory under \$TMP" "got [$N12]"; N12="$TMP/b12n-fallback"; mkdir -p "$N12"
fi
N12U="$N12/user"; mkdir -p "$N12U" "$N12/mem" "$N12/t"
_n12env() { export HOME="$N12U" XDG_CONFIG_HOME="$N12U/.config" GIT_CONFIG_NOSYSTEM=1; unset CLAUDE_CONFIG_DIR; }
_n12g() { ( _n12env; _fx_git "$@" ) >/dev/null 2>&1; }
_n12co() {  # DIR [URL]: a checkout with one commit and, when given, an origin
  mkdir -p "$1"; printf 'x\n' > "$1/x.txt"; _n12g "$1" init -q -b main; _n12g "$1" add -A
  _n12g "$1" -c user.name=t -c user.email=t@t commit -qm init
  if [ -n "${2:-}" ]; then _n12g "$1" config remote.origin.url "$2"; fi
}
_n12proj() { mkdir -p "$1/projects/$2"; printf '{\n  "name": "%s",\n  "remote_match": "%s"\n}\n' "$2" "$3" > "$1/projects/$2/project.json"; }
_n12res() {  # START HOME -> the bound project's directory name, a bar, the status
  ( _n12env; export FELIX_MEMORY="$N12/mem/res"; . "$FROOT/harness/lib/resolve.sh"
    p="$(felix_resolve_project "$1" "$2")"; r=$?; printf '%s|%s' "${p##*/}" "$r" ) </dev/null 2>/dev/null
}
_n12bb() {  # START HOME MEM -> what felix_binding_broken printed, then |rc=N
  ( _n12env; export FELIX_MEMORY="$3"; . "$FROOT/harness/lib/resolve.sh"
    o="$(felix_binding_broken "$1" "$2")"; r=$?; printf '%s|rc=%s' "$o" "$r" ) </dev/null 2>/dev/null
}
_n12timed() {  # SCRIPT ARGS... -> what a child "$BASH" running SCRIPT printed, killed after 5 s (then |child=142)
  local s="$1"; shift
  ( _n12env; perl -e 'alarm 5; exec @ARGV' "$BASH" -c "$s" b12 "$FROOT/harness/lib/resolve.sh" "$@"; r=$?
    if [ "$r" != 0 ]; then printf '|child=%s' "$r"; fi ) </dev/null 2>/dev/null
}
_n12bbt() { ( export FELIX_MEMORY="$3"; _n12timed '. "$1"; o="$(felix_binding_broken "$2" "$3")"; r=$?; printf "%s|rc=%s" "$o" "$r"' "$1" "$2" ); }
_n12rest() { ( export FELIX_MEMORY="$N12/mem/res"; _n12timed '. "$1"; p="$(felix_resolve_project "$2" "$3")"; r=$?; printf "%s|%s" "${p##*/}" "$r"' "$1" "$2" ); }
_n12pay() { printf '{"session_id":"%s","transcript_path":"%s/%s.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"%s",%s}' "$2" "$N12/t" "$2" "$3" "$1" "$4"; }
_n12hook() {  # HOME MEM DIR HOOK PAYLOAD -> the hook's stdout and stderr
  ( _n12env; export FELIX_HOME="$1" FELIX_MEMORY="$2"; cd "$3" && "$FROOT/harness/hooks/$4" <<<"$5" 2>&1 )
}
_n12word() {  # TEXT WORD -> yes when WORD stands in TEXT with no letter, digit or underscore either side
  printf '%s' "$1" | LC_ALL=C awk -v w="$2" 'BEGIN { RS = "\001"; c = "[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_]" }
    { s = $0; while ((i = index(s, w)) > 0) { b = (i > 1) ? substr(s, i - 1, 1) : ""; a = substr(s, i + length(w), 1)
        if (b !~ c && a !~ c) { f = 1; break }; s = substr(s, i + length(w)) } }
    END { print (f ? "yes" : "no") }'
}
_n12all() { local t="$1" w m=""; shift; for w in "$@"; do case "$t" in *"$w"*) ;; *) m="$m [$w]" ;; esac; done
            if [ -z "$m" ]; then printf 'holds all'; else printf 'lacks%s in [%s]' "$m" "$t"; fi; }
_n12blk() { case "$1" in *'"decision"'*'"block"'*) printf 'block' ;; *) printf 'no block in [%s]' "$1" ;; esac; }
_n12says() {  # OUTPUT WORD... -> "names el and WORD..." when OUTPUT is a sentence naming el as a word, each WORD, and no SECRET-b12
  local t="${1%|rc=*}"; shift
  case "$t" in *SECRET-b12*) printf 'holds the userinfo: [%s]' "$t"; return ;; esac
  if [ -n "$t" ] && [ "$(_n12word "$t" el)" = yes ] && [ "$(_n12all "$t" "$@")" = "holds all" ]; then printf 'names el and %s' "$*"
  else printf '[%s]' "$t"; fi
}
_n12n() { if [ -f "$1" ]; then LC_ALL=C awk 'END { print NR }' "$1"; else printf '0'; fi; }
_n12last() { LC_ALL=C awk -F'\t' -v k="$2" '$1 == k { p = $2 } END { print p }' "$1" 2>/dev/null; }
_n12one() {  # FILE KEY PROJECT -> "one line: KEY, PROJECT, a UTC stamp" when that is the file's only line
  LC_ALL=C awk -F'\t' -v k="$2" -v p="$3" '{ n++; l = l "[" $0 "]"; ok = (NF == 3 && $1 == k && $2 == p &&
      $3 ~ /^[0123456789][0123456789][0123456789][0123456789]-[0123456789][0123456789]-[0123456789][0123456789]T[0123456789][0123456789]:[0123456789][0123456789]:[0123456789][0123456789]Z$/) }
    END { if (n == 1 && ok) print "one line: the key, " p ", a UTC stamp"; else print (n + 0) " line(s): " l }' "$1" 2>/dev/null
}

# ---- C046: fixture B, the binding rule row by row ----------------------------------------------
N12HB="$N12/b/home"; N12CB="$N12/b/co"; N12MB="$N12/b/mem"; mkdir -p "$N12MB"
for _n12p in web:acme/web website:acme/website el:Acme/Atlas gl:https://gitlab.example/acme/api s1:team/svc \
             s2:gitlab.example/team/svc ex:example.invalid/pcwd-remote dup1:acme/dup dup2:acme/dup nomatch:; do
  _n12proj "$N12HB" "${_n12p%%:*}" "${_n12p#*:}"
done
_n12co "$N12CB"; _n12co "$N12/b/marked" https://github.com/acme/website.git; printf 'web\n' > "$N12/b/marked/.felix"
_n12row() { _n12g "$N12CB" config remote.origin.url "$2"; is "b12 A$1 (B22): $4" "$(_n12res "$N12CB" "$N12HB")" "$3"; }
_n12row 45 https://github.com/acme/website.git 'website|0' "https://github.com/acme/website.git binds website, not web, whose acme/web it only begins with"
_n12row 46 git@github.com:acme/web.git 'web|0' "git@github.com:acme/web.git binds web (control)"
_n12row 47 ssh://git@github.com/acme/website.git 'website|0' "ssh://git@github.com/acme/website.git binds website, not web"
_n12row 48 https://github.com/Acme/Atlas-docs.git '|1' "https://github.com/Acme/Atlas-docs.git binds nothing, though Acme/Atlas begins it"
_n12row 49 https://github.com/acme/atlas.git 'el|0' "a lowercase clone, https://github.com/acme/atlas.git, binds el"
_n12row 50 https://github.com/Acme/Atlas.git 'el|0' "https://github.com/Acme/Atlas.git binds el (control)"
_n12row 51 'https://b12tok:SECRET-b12@github.com/Acme/Atlas.git' 'el|0' "an origin carrying userinfo before github.com/Acme/Atlas binds el (control)"
_n12row 52 https://gitlab.example/acme/api-gateway.git '|1' "https://gitlab.example/acme/api-gateway.git binds nothing, though gl's https://gitlab.example/acme/api begins it"
_n12row 53 https://gitlab.example/acme/api.git 'gl|0' "https://gitlab.example/acme/api.git binds gl (control)"
_n12row 54 git@gitlab.example:team/svc.git 's1|0' "git@gitlab.example:team/svc.git binds s1, team/svc anchored after a colon (control)"
_n12row 55 https://gitlab.example/team/svc.git 's2|0' "https://gitlab.example/team/svc.git binds s2, the longest match, over s1"
_n12row 56 https://gitlab.example/xteam/svc.git '|1' "https://gitlab.example/xteam/svc.git binds nothing: team/svc after an x is not anchored"
_n12row 57 https://example.invalid/pcwd-remote.git 'ex|0' "https://example.invalid/pcwd-remote.git binds ex (control)"
_n12row 58 https://github.com/acme/dup.git '|1' "https://github.com/acme/dup.git binds nothing, dup1 and dup2 tying on acme/dup"
is "b12 A59 (B22): a checkout whose .felix names web binds web, its origin acme/website notwithstanding (control)" "$(_n12res "$N12/b/marked" "$N12HB")" "web|0"
_n12o="$(_n12bb "$N12CB" "$N12HB" "$N12MB")"
is "b12 A60 (B23): on the tie, felix_binding_broken prints a sentence naming dup1 and dup2 and remote_match" "$(_n12all "${_n12o%|rc=*}" dup1 dup2 remote_match)" "holds all"
is "b12 A61 (B23): on the tie, session-start with a startup payload says binding broken" \
   "$(_n12all "$(_n12hook "$N12HB" "$N12MB" "$N12CB" session-start "$(_n12pay SessionStart b12-t1 "$N12CB" '"source":"startup"')")" 'binding broken')" "holds all"
is "b12 A62 (B23): on the tie, stop with a Stop payload prints a block object" \
   "$(_n12blk "$(_n12hook "$N12HB" "$N12MB" "$N12CB" stop "$(_n12pay Stop b12-t2 "$N12CB" '"stop_hook_active":false')")")" "block"

# ---- C031: fixture L, a remote binding recorded, then broken -----------------------------------
N12HL="$N12/l/home"; N12CO="$N12/l/co"; N12ML="$N12/mem/l"; N12BT="$N12ML/bindings.tsv"; N12UL='https://b12tok:SECRET-b12@github.com/acme/el.git'
_n12proj "$N12HL" el acme/el; _n12proj "$N12HL" other acme/other; mkdir -p "$N12ML" "$N12/mem/fresh"; _n12co "$N12CO" "$N12UL"
N12PD="$N12HL/projects/el"; N12PJ="$N12PD/project.json"; cp "$N12PJ" "$N12/l/el.json.keep"
N12UG="$( ( _n12env; git -C "$N12CO" remote get-url origin ) 2>/dev/null)"
N12KEY="$(printf '%s\n%s\n' "$N12HL" "$N12UG" | git hash-object --stdin)"
_n12restore() { rm -f "$N12PD/project 2.json" "$N12PJ"; cp "$N12/l/el.json.keep" "$N12PJ"; chmod 644 "$N12PJ"; }
is "b12 A63 (B25): the first felix_binding_broken on CO, bound by its remote, prints nothing and exits 0 (control)" "$(_n12bb "$N12CO" "$N12HL" "$N12ML")" "|rc=0"
is "b12 A64 (B25): bindings.tsv then holds exactly one line, the key of HOME and the URL, el, a UTC stamp" "$(_n12one "$N12BT" "$N12KEY" el)" "one line: the key, el, a UTC stamp"
_n12bb "$N12CO" "$N12HL" "$N12ML" >/dev/null
is "b12 A65 (B25): a second call leaves exactly that one line" "$(_n12one "$N12BT" "$N12KEY" el)" "one line: the key, el, a UTC stamp"
is "b12 A67 (B25): felix_resolve_project alone binds CO and leaves a fresh memory root empty (control)" \
   "$( ( export FELIX_MEMORY="$N12/mem/fresh"; _n12env; . "$FROOT/harness/lib/resolve.sh"; p="$(felix_resolve_project "$N12CO" "$N12HL")"; printf '%s' "${p##*/}" ) </dev/null 2>/dev/null) [$(ls -A "$N12/mem/fresh" 2>&1)]" "el []"
# B26 and B27, the rename state first.
_n12r72=""; _n12w72=""
mv "$N12PJ" "$N12PD/project 2.json"
is "b12 A68 (B26): with project.json renamed project 2.json, the sentence names el, project.json, project 2.json and bindings.tsv's path, not the userinfo" \
   "$(_n12says "$(_n12bb "$N12CO" "$N12HL" "$N12ML")" project.json 'project 2.json' "$N12BT")" "names el and project.json project 2.json $N12BT"
_n12r72="$_n12r72 [renamed: $(_n12res "$N12CO" "$N12HL")]"; _n12w72="$_n12w72 [renamed: |1]"
_n12u0="$(_n12n "$N12ML/unresolved.log")"
_n12ss="$(_n12hook "$N12HL" "$N12ML" "$N12CO" session-start "$(_n12pay SessionStart b12-l1 "$N12CO" '"source":"startup"')")"
_n12sp="$(_n12hook "$N12HL" "$N12ML" "$N12CO" stop "$(_n12pay Stop b12-l2 "$N12CO" '"stop_hook_active":false')")"
_n12u1="$(_n12n "$N12ML/unresolved.log")"
if [ "$_n12u1" -gt "$_n12u0" ] 2>/dev/null; then _n12v=grew; else _n12v="stayed at $_n12u0"; fi
is "b12 A73 (B27): in that state session-start says binding broken and el, stop blocks naming el, and unresolved.log gains a line" \
   "start: $(_n12all "$_n12ss" 'binding broken') $(_n12word "$_n12ss" el); stop: $(_n12blk "$_n12sp") $(_n12word "$_n12sp" el); log: $_n12v" \
   "start: holds all yes; stop: block yes; log: grew"
is "b12 A73 control (B27): a resume payload prints nothing" \
   "$(_n12hook "$N12HL" "$N12ML" "$N12CO" session-start "$(_n12pay SessionStart b12-l3 "$N12CO" '"source":"resume"')")" ""
_n12g74=""; _n12w74=""
_n12case() { _n12g74="$_n12g74 [$1: $2]"; _n12w74="$_n12w74 [$1: |rc=0]"; }
mkdir -p "$N12/mem/unread"; printf '%s\tel\t2026-10-24T00:00:00Z\n' "$N12KEY" > "$N12/mem/unread/bindings.tsv"
if [ "$(id -u)" != 0 ]; then chmod 000 "$N12/mem/unread/bindings.tsv"
  _n12case 'an unreadable bindings.tsv naming el' "$(_n12bb "$N12CO" "$N12HL" "$N12/mem/unread")"; chmod 644 "$N12/mem/unread/bindings.tsv"; fi
mkdir -p "$N12/mem/dotdot" "$N12HL/x"; printf '%s\t../x\t2026-10-24T00:00:00Z\n' "$N12KEY" > "$N12/mem/dotdot/bindings.tsv"
_n12case 'a ../x line' "$(_n12bb "$N12CO" "$N12HL" "$N12/mem/dotdot")"
_n12restore; rm -f "$N12PJ"
is "b12 A69 (B26): with project.json deleted, the sentence names el and project.json" "$(_n12says "$(_n12bb "$N12CO" "$N12HL" "$N12ML")" project.json)" "names el and project.json"
_n12r72="$_n12r72 [deleted: $(_n12res "$N12CO" "$N12HL")]"; _n12w72="$_n12w72 [deleted: |1]"; _n12restore
if [ "$(id -u)" != 0 ]; then
  chmod 000 "$N12PJ"
  is "b12 A70 (B26): with project.json at mode 000, the sentence names el and project.json" "$(_n12says "$(_n12bb "$N12CO" "$N12HL" "$N12ML")" project.json)" "names el and project.json"
  _n12r72="$_n12r72 [mode 000: $(_n12res "$N12CO" "$N12HL")]"; _n12w72="$_n12w72 [mode 000: |1]"; _n12restore
else skip "b12 A70 (B26): with project.json at mode 000, the sentence names el and project.json" "id -u is 0, and mode 000 does not stop root"; fi
rm -f "$N12PJ"; mkfifo "$N12PJ" 2>/dev/null
is "b12 A71 (B26): with project.json a FIFO, the sentence names el and project.json, within 5 s" "$(_n12says "$(_n12bbt "$N12CO" "$N12HL" "$N12ML")" project.json)" "names el and project.json"
_n12r72="$_n12r72 [a FIFO: $(_n12rest "$N12CO" "$N12HL")]"; _n12w72="$_n12w72 [a FIFO: |1]"; _n12restore
is "b12 A72 (B26): in each of those states felix_resolve_project exits 1 and prints nothing (control)" "$_n12r72" "$_n12w72"
# B28: the states that are deliberate, or unbound, or unreadable, print nothing.
_n12co "$N12/l/never" https://github.com/acme/never.git; _n12co "$N12/l/noorigin"
_n12case 'never bound' "$(_n12bb "$N12/l/never" "$N12HL" "$N12ML")"
_n12case 'no origin' "$(_n12bb "$N12/l/noorigin" "$N12HL" "$N12ML")"
_n12proj "$N12HL" el ""; _n12case 'remote_match emptied' "$(_n12bb "$N12CO" "$N12HL" "$N12ML")"; _n12restore
_n12proj "$N12HL" el acme/el-moved; _n12case 'remote_match changed' "$(_n12bb "$N12CO" "$N12HL" "$N12ML")"; _n12restore
mv "$N12PD" "$N12/l/el.aside"; _n12case 'projects/el removed' "$(_n12bb "$N12CO" "$N12HL" "$N12ML")"; mv "$N12/l/el.aside" "$N12PD"
mkdir -p "$N12/l/home2/projects/el"; _n12case 'another home' "$(_n12bb "$N12CO" "$N12/l/home2" "$N12ML")"
mkdir -p "$N12/mem/ro"; chmod 555 "$N12/mem/ro"; _n12case 'bound, an unwritable memory root' "$(_n12bb "$N12CO" "$N12HL" "$N12/mem/ro")"; chmod 755 "$N12/mem/ro"
is "b12 A74 (B28): each deliberate, unbound or unreadable state prints nothing and exits 0, and stop is silent where the origin was never bound (control)" \
   "$_n12g74 stop=[$(_n12hook "$N12HL" "$N12ML" "$N12/l/never" stop "$(_n12pay Stop b12-l4 "$N12/l/never" '"stop_hook_active":false')")]" "$_n12w74 stop=[]"
mv "$N12PD" "$N12HL/projects/el2"
_n12o="$(_n12bb "$N12CO" "$N12HL" "$N12ML")"
is "b12 A75 (B29): after projects/el is renamed el2, CO binds el2, nothing is printed, and the last line for the key names el2" \
   "$(_n12res "$N12CO" "$N12HL") [$_n12o] last=$(_n12last "$N12BT" "$N12KEY")" "el2|0 [|rc=0] last=el2"
# B30: the marker path is unchanged by a record, even one whose projects/el is a directory with no project.json.
mkdir -p "$N12PD"; _n12co "$N12/l/gone" "$N12UL"; printf 'gone\n' > "$N12/l/gone/.felix"; mkdir -p "$N12/mem/m5" "$N12/mem/m6"
printf '%s\tel\t2026-10-24T00:00:00Z\n' "$N12KEY" > "$N12/mem/m6/bindings.tsv"; cp "$N12/mem/m6/bindings.tsv" "$N12/l/m6.keep"
_n12a="$(_n12bb "$N12/l/gone" "$N12HL" "$N12/mem/m5")"; _n12b="$(_n12bb "$N12/l/gone" "$N12HL" "$N12/mem/m6")"
case "$_n12a" in "The .felix marker in"*) _n12v=begins ;; *) _n12v="[$_n12a]" ;; esac
if [ "$_n12a" = "$_n12b" ]; then _n12v="$_n12v, unchanged"; else _n12v="$_n12v, changed to [$_n12b]"; fi
if cmp -s "$N12/mem/m6/bindings.tsv" "$N12/l/m6.keep"; then _n12v="$_n12v, the record untouched"; else _n12v="$_n12v, the record moved"; fi
is "b12 A78 (B30): a marker naming gone prints the sentence beginning The .felix marker in, unchanged by a line naming el for the same URL (control)" \
   "$_n12v" "begins, unchanged, the record untouched"
_n12leak="$(LC_ALL=C grep -r -l -F -e 'SECRET-b12' -e 'github.com/acme' "$N12/mem" 2>&1)"
is "b12 A66 (B25): no file under the memory roots the record's calls and hooks wrote holds SECRET-b12 or github.com/acme (control)" "[$_n12leak]" "[]"

# ---- B24: fixture O, the binding agrees with felix_remote_github_slug --------------------------
_n12proj "$N12/o/home" ownp OWNERX/OWNP-REPO; _n12co "$N12/o/co"
_n12gt=""; _n12wt=""
for _n12i in https://github.com/OwnerX/ownp-repo https://github.com/OwnerX/ownp-repo.git https://GitHub.com/ownerx/OWNP-REPO.git/ \
             https://tok@github.com/OwnerX/ownp-repo.git https://github.com:443/OwnerX/ownp-repo git@github.com:OwnerX/ownp-repo.git \
             github.com:OwnerX/ownp-repo ssh://git@github.com/OwnerX/ownp-repo.git ssh://git@github.com:22/OwnerX/ownp-repo \
             git://github.com/OwnerX/ownp-repo.git; do
  _n12g "$N12/o/co" config remote.origin.url "$_n12i"; _n12gt="$_n12gt [$_n12i: $(_n12res "$N12/o/co" "$N12/o/home")]"; _n12wt="$_n12wt [$_n12i: ownp|0]"
done
is "b12 A76 (B24): each URL part 1130 lists as own binds the project declaring OWNERX/OWNP-REPO" "$_n12gt" "$_n12wt"
_n12gt=""; _n12wt=""
for _n12i in git@evil.example:OwnerX/ownp-repo.git https://github.com/OwnerX/ownp-repo-fork.git https://github.com.evil.example/OwnerX/ownp-repo \
             'https://evil.example#@github.com/OwnerX/ownp-repo'; do
  _n12g "$N12/o/co" config remote.origin.url "$_n12i"; _n12gt="$_n12gt [$_n12i: $(_n12res "$N12/o/co" "$N12/o/home")]"; _n12wt="$_n12wt [$_n12i: |1]"
done
is "b12 A77 (B24): each URL part 1130 lists as not own binds nothing (control)" "$_n12gt" "$_n12wt"

# ---- C061: fixture R, the root walk ends -------------------------------------------------------
N12R="$N12/r/repo"; mkdir -p "$N12R/sub" "$N12/r/outside"; N12OUT="$N12/r/outside"
printf 'r\n' > "$N12R/sub/f.txt"; _n12g "$N12R" init -q -b main; _n12g "$N12R" add -A
_n12g "$N12R" -c user.name=t -c user.email=t@t commit -qm r; _n12g "$N12R" worktree add -q -b b12wt "$N12/r/wt"
N12TOP="$(git -C "$N12R/sub" rev-parse --show-toplevel 2>/dev/null)"; N12WTT="$(git -C "$N12/r/wt" rev-parse --show-toplevel 2>/dev/null)"
_n12walk() {  # stub|plain DIR -> the root a child bash printed, then |rc=N; killed after 5 s
  if [ "$1" = stub ]; then _n12timed '. "$1"; pwd() { printf "stale/Users\n"; }; r="$(felix_repo_root "$2")"; printf "%s|rc=%s" "$r" "$?"' "$2"
  else _n12timed '. "$1"; r="$(felix_repo_root "$2")"; printf "%s|rc=%s" "$r" "$?"' "$2"; fi
}
# B33 (review round): the child writes the root with an external printf, which execs and drops the
# child's own stale buffer; a builtin write there would flush that buffer ahead of the value.
_n12closed() {  # TEXT DIR -> the root a child bash with stdout closed got after a failed printf of TEXT; killed after 5 s
  local f="$N12/r/closed.out" rc; rm -f "$f"
  ( _n12env; perl -e 'alarm 5; exec @ARGV' "$BASH" -c '. "$1"; exec 1>&-; printf "$3"; root="$(felix_repo_root "$2")"; env printf "%s" "$root" > "$4"' \
      b12 "$FROOT/harness/lib/resolve.sh" "$2" "$1" "$f" ) </dev/null >/dev/null 2>&1; rc=$?
  printf '%s|child=%s' "$(cat "$f" 2>/dev/null)" "$rc"
}
is "b12 A79 (B31): with pwd printing stale/Users, felix_repo_root in a repository's subdirectory returns its top level within 5 s" \
   "$(_n12walk stub "$N12R/sub")" "$N12TOP|rc=0"
is "b12 A80 (B31): and outside any repository it returns the directory as given within 5 s" "$(_n12walk stub "$N12OUT")" "$N12OUT|rc=0"
is "b12 A81 (B32): with stdout closed after a failed printf of felix: something, the root is the top level, within 5 s (red on bash 3.2)" \
   "$(_n12closed 'felix: something\n' "$N12R/sub")" "$N12TOP|child=0"
is "b12 A82 (B32): and after a failed printf of /x, the root is exactly the top level (red on bash 3.2)" \
   "$(_n12closed '/x\n' "$N12R/sub")" "$N12TOP|child=0"
is "b12 A83 (B31): without the stub, a subdirectory, a worktree with a .git file and a directory outside git keep their roots (control)" \
   "$(_n12walk plain "$N12R/sub") $(_n12walk plain "$N12/r/wt") $(_n12walk plain "$N12OUT") $([ -f "$N12/r/wt/.git" ] && printf gitfile)" \
   "$N12TOP|rc=0 $N12WTT|rc=0 $N12OUT|rc=0 gitfile"

# ---- Review round, M1 (B34): the probe can see a stale buffer ----------------------------------
# Written blind on 2026-10-26 from the contract's section 9, with no engine code read. The same child as
# A81 runs, but with a naive resolver that reads pwd -P inside $( ) after the failed write. It writes
# what $(printf '%s' '') caught and the naive value, each by an external printf. Where nothing was
# caught, the bash in use dropped the buffer, and the assertion says so as a skip.
_n12probe() {  # TEXT DIR: writes probe.out.s (the stale text) and probe.out (the naive root); sets _n12prc
  local f="$N12/r/probe.out"; rm -f "$f" "$f.s"
  ( _n12env; perl -e 'alarm 5; exec @ARGV' "$BASH" -c '_naive() { cd "$1" && pwd -P; }; exec 1>&-; printf "$2"; s="$(printf "%s" "")"
      root="$(_naive "$1")"; env printf "%s" "$s" > "$3.s"; env printf "%s" "$root" > "$3"' b12 "$2" "$1" "$f" ) </dev/null >/dev/null 2>&1
  _n12prc=$?
}
_n12probe 'felix: something\n' "$N12R/sub"
_n12ps="$(cat "$N12/r/probe.out.s" 2>/dev/null)"; _n12pr="$(cat "$N12/r/probe.out" 2>/dev/null)"
_n12n91="b12 A91 (B34): after the failed printf, a naive resolver reading pwd -P inside \$( ) gives a root that is not the top level, as the probe reads it"
if [ "$_n12prc" = 0 ] && [ -z "$_n12ps" ]; then
  skip "$_n12n91" "this bash ($BASH_VERSION) dropped the failed write's text, so no probe can show a stale buffer here"
else
  if [ "$_n12prc" = 0 ] && [ -n "$_n12pr" ] && [ "$_n12pr" != "$N12TOP" ]; then _n12v="not the top level"
  else _n12v="child=$_n12prc stale=[$_n12ps] root=[$_n12pr]"; fi
  is "$_n12n91" "$_n12v" "not the top level"
fi

# ---- Review round, M3 (B39, B40): remote_match read as own.sh reads it -------------------------
# Fixture W: four homes and one checkout co, its origin set URL by URL with no marker. h1 holds webgit
# (acme/web.git) and website, h2 webslash (acme/web/), h3 s3 (https://gitlab.example/team/svc/), and
# h4 w1 (acme/web) and w2 (acme/web.git). felix_checkout_is_own is called as part 1130 calls it.
N12W="$N12/w"; mkdir -p "$N12W/mem1" "$N12W/mem4"
_n12proj "$N12W/h1" webgit acme/web.git; _n12proj "$N12W/h1" website acme/website; _n12proj "$N12W/h2" webslash acme/web/
_n12proj "$N12W/h3" s3 https://gitlab.example/team/svc/; _n12proj "$N12W/h4" w1 acme/web; _n12proj "$N12W/h4" w2 acme/web.git
_n12co "$N12W/co"
_n12at() {  # HOME URL... -> [URL: the project it binds|status] for each URL, set as co's origin
  local h="$1" u; shift
  for u in "$@"; do _n12g "$N12W/co" config remote.origin.url "$u"; printf '[%s: %s]' "$u" "$(_n12res "$N12W/co" "$N12W/$h")"; done
}
is "b12 A92 (B39): in h1, acme/web.git, git@github.com:acme/web.git and https://github.com/acme/web bind webgit, declared as acme/web.git" \
   "$(_n12at h1 https://github.com/acme/web.git git@github.com:acme/web.git https://github.com/acme/web)" \
   "[https://github.com/acme/web.git: webgit|0][git@github.com:acme/web.git: webgit|0][https://github.com/acme/web: webgit|0]"
is "b12 A93 (B39): in h1, acme/website.git binds website and acme/web-docs.git binds nothing (control)" \
   "$(_n12at h1 https://github.com/acme/website.git https://github.com/acme/web-docs.git)" \
   "[https://github.com/acme/website.git: website|0][https://github.com/acme/web-docs.git: |1]"
is "b12 A94 (B39): h2's acme/web/ binds acme/web/ and acme/web.git, and h3's gitlab remote_match ending in / binds svc.git and svc/" \
   "$(_n12at h2 https://github.com/acme/web/ https://github.com/acme/web.git)$(_n12at h3 https://gitlab.example/team/svc.git https://gitlab.example/team/svc/)" \
   "[https://github.com/acme/web/: webslash|0][https://github.com/acme/web.git: webslash|0][https://gitlab.example/team/svc.git: s3|0][https://gitlab.example/team/svc/: s3|0]"
_n12g "$N12W/co" config remote.origin.url https://github.com/acme/web.git
_n12o="$(_n12bb "$N12W/co" "$N12W/h4" "$N12W/mem4")"
is "b12 A95 (B39): in h4, acme/web and acme/web.git tie: nothing is bound, and the sentence names w1, w2 and remote_match" \
   "$(_n12res "$N12W/co" "$N12W/h4") $(_n12word "${_n12o%|rc=*}" w1) $(_n12word "${_n12o%|rc=*}" w2) $(_n12all "${_n12o%|rc=*}" remote_match)" "|1 yes yes holds all"
_n12o="$(_n12bb "$N12W/co" "$N12W/h1" "$N12W/mem1")"
N12WU="$( ( _n12env; git -C "$N12W/co" remote get-url origin ) 2>/dev/null)"
N12WK="$(printf '%s\n%s\n' "$N12W/h1" "$N12WU" | git hash-object --stdin)"
is "b12 A96 (B39): in h1, felix_binding_broken on the acme/web.git checkout prints nothing, exits 0 and records webgit" \
   "[$_n12o] last=$(_n12last "$N12W/mem1/bindings.tsv" "$N12WK")" "[|rc=0] last=webgit"
_n12own() {  # HOME PROJDIR -> felix_checkout_is_own's exit status for co (97 when own.sh cannot be sourced)
  ( _n12env; export FELIX_HOME="$1" FELIX_MEMORY="$N12/mem/res"
    . "$FROOT/harness/lib/resolve.sh" && . "$FROOT/harness/lib/own.sh" || exit 97
    felix_checkout_is_own "$2" "$N12W/co" >/dev/null 2>&1 ) </dev/null >/dev/null 2>&1
  printf '%s' "$?"
}
_n12dis=""; _n12own1=0; _n12own2=0
for _n12i in https://github.com/acme/web.git git@github.com:acme/web.git https://github.com/acme/web/ https://github.com/acme/web \
             https://github.com/acme/website.git https://github.com/acme/web-docs.git; do
  _n12g "$N12W/co" config remote.origin.url "$_n12i"
  for _n12p in h1:webgit h2:webslash; do
    _n12h="${_n12p%%:*}"; _n12pn="${_n12p#*:}"
    _n12a="$(_n12own "$N12W/$_n12h" "$N12W/$_n12h/projects/$_n12pn")"; _n12b="$(_n12res "$N12W/co" "$N12W/$_n12h")"
    if [ "$_n12a" = 0 ]; then
      if [ "$_n12h" = h1 ]; then _n12own1="$((_n12own1 + 1))"; else _n12own2="$((_n12own2 + 1))"; fi
    fi
    if [ "$_n12a" = 0 ] && [ "$_n12b" = "$_n12pn|0" ]; then :
    elif [ "$_n12a" = 1 ] && [ "$_n12b" != "$_n12pn|0" ]; then :
    else _n12dis="$_n12dis [$_n12h $_n12i: own=$_n12a bound=$_n12b]"; fi
  done
done
if [ "$_n12own1" -gt 0 ]; then _n12v="h1 own=some"; else _n12v="h1 own=none"; fi
if [ "$_n12own2" -gt 0 ]; then _n12v="$_n12v h2 own=some"; else _n12v="$_n12v h2 own=none"; fi
is "b12 A97 (B40): felix_resolve_project binds webgit and webslash exactly where felix_checkout_is_own says own, and each home has an own URL" \
   "disagree=[${_n12dis# }] $_n12v" "disagree=[] h1 own=some h2 own=some"
