printf '\nonly what the project declares vendored is set aside (audit b11 round 3, blind)\n'
# Blind, written on 2026-10-28 from docs/2026-10-24-audit-fixes/b11-round-3.md alone (its section 4, part
# 1832: A109 to A149 over fixture F7, and over F2, F3 and the brief as the batch contract,
# docs/2026-10-24-audit-fixes/b11-evidence-policy-gives-true-verdicts.md, defines them), with its section 2
# (B11R3-1 to B11R3-11) for what each means. No engine code was read: lib/, hooks/, felix, bin/ and the
# project gates were not opened, and every command and library is driven as a black box. Every name is
# emitted on every run. The controls (A113, A118, A119, A126, A139 to A141, A143, A149) hold on d1f2cdc1;
# every other assertion here fails there. B11R3-9 has no assertion (no outside input reaches it), and this
# part reads no template: the template's round-3 cases (A101 to A107 rewritten, A150, A151) are part 1831's.
# The review round's A152 to A167 (B11R3-13, B11R3-14), named B11R3V, were added blind the same day
# from that file's Review round, with the same blindness; A157 and A168 are its controls.
#
# Readings, where the contract leaves room:
# - F7's repository is built as F1 builds one, except that every file holds its own path (a go.mod holds a
#   module line), so no deletion and addition in one change can pair up as a rename, and `~X` adds a
#   second line on work. `=X`, `-X` and `~X` are committed on main; `+X` is added on work.
# - "Expected is every line in order" is read as exactly those lines and no other. A row whose change is
#   "one each", or whose entry is "each of", is one assertion per case, named by the case.
# - B11R3-8's "exactly one line ... never no rule was consulted" is checked on every case of A134 to A138.
# - F2's "+K" writes K as a line of its own after the opening brace of widget's project.json, so the file
#   stays valid JSON and every key sits on a line of its own; the file is put back byte for byte after
#   each run. A145 runs felix merge --dry-run as part 1830's A21 does: a green gate receipt, a commission
#   receipt stamped after the key is added, and a base branch at HEAD~1 under a ref of this part's own.
#
# Every part runs alone: this one makes the widget checkout's first commit with _widget_repo_build, keeps
# the widget's evidence.tsv and project.json and puts them back, and makes every other fixture under
# $TMP/b11r3.

B11R3="$TMP/b11r3"; mkdir -p "$B11R3"
_widget_repo_build
_b11r3_wp="$FROOT/projects/widget"
for _b11r3_f in evidence.tsv project.json; do
  rm -f "$B11R3/$_b11r3_f.keep"; [ -f "$_b11r3_wp/$_b11r3_f" ] && cp "$_b11r3_wp/$_b11r3_f" "$B11R3/$_b11r3_f.keep"
done
_b11r3_TU="$(printf '%s\t%s\t%s\t%s' unit '(^|/)(src|lib|internal|pkg|cmd)/' '(^|/)tests?/|_test\.go$' 'code changes need a test')"
_b11r3_TV="$_b11r3_TU"$'\n'"$(printf '%s\t%s\t%s\t%s' deps '(^|/)vendor/' '^vendor/modules\.txt$' 'a vendored change names its modules')"
_b11r3_Ug="$(printf 'gap\tunit\tcode changes need a test')"
_b11r3_Un="$(printf 'n/a\tunit\tthis change does not touch that surface')"
_b11r3_Um="$(printf 'met\tunit\tcode changes need a test')"
_b11r3_dg="$(printf 'gap\tdeps\ta vendored change names its modules')"
_b11r3_dm="$(printf 'met\tdeps\ta vendored change names its modules')"
_b11r3_dn="$(printf 'n/a\tdeps\tthis change does not touch that surface')"
_b11r3_J1='{"name":"p","evidence_vendored":"third_party/ web/assets/vendor"}'
_b11r3_J2='{"evidence_vendored": "third_party/"}'
_b11r3_J3='{"evidence_reads_vendored": "deps"}'
_b11r3_JX='{"evidence_vendored": 3}'
_b11r3_n=0; _b11r3_k=0; _b11r3_P=""; _b11r3_G=""; _b11r3_wj=""; _b11r3_o=""; _b11r3_rc=0; _b11r3_v=""; _b11r3_x=""

# N DIRS: V(N, DIRS), the VENDORED line when no row opted in.
_b11r3_V() { printf 'n/a\tVENDORED\t%s changed path(s) set aside as vendored, under %s, so no rule read them' "$1" "$2"; }
# LINE...: the lines, joined by newlines, as $( ) gives a command's output back.
_b11r3_ls() { printf '%s\n' "$@"; }
# OUT N CHECK...: "ok" when OUT has N lines and its first line meets each CHECK, K=V (field K is exactly
# V), K~V (field K holds V) or K!V (field K does not hold V), fields split on tabs; otherwise what differs.
_b11r3_says() {
  local o="$1" n="$2" k c f v g
  shift 2
  k="$(printf '%s' "$o" | awk 'END { print NR }')"
  if [ "$k" != "$n" ]; then printf '%s line(s), not %s: [%s]' "$k" "$n" "$o"; return 0; fi
  for c in "$@"; do
    f="${c%%[=~!]*}"; v="${c#*[=~!]}"
    g="$(printf '%s\n' "$o" | LC_ALL=C awk -F'\t' -v k="$f" 'NR == 1 { print $k }')"
    case "$c" in
      "$f="*) [ "$g" = "$v" ] || { printf 'field %s is [%s], not [%s]: [%s]' "$f" "$g" "$v" "$o"; return 0; } ;;
      "$f!"*) case "$g" in *"$v"*) printf 'field %s holds [%s]: [%s]' "$f" "$v" "$o"; return 0 ;; esac ;;
      *) case "$g" in *"$v"*) ;; *) printf 'field %s lacks [%s]: [%s]' "$f" "$v" "$o"; return 0 ;; esac ;;
    esac
  done
  printf ok
}
# NAME TEXT +PHRASE|-PHRASE...: one assertion that TEXT holds every +PHRASE and no -PHRASE.
_b11r3_hl() {
  local n="$1" t="$2" p miss=""
  shift 2
  for p in "$@"; do
    case "$p" in
      +*) case "$t" in *"${p#+}"*) ;; *) miss="$miss lacks [${p#+}];" ;; esac ;;
      -*) case "$t" in *"${p#-}"*) miss="$miss holds [${p#-}];" ;; esac ;;
    esac
  done
  if [ -z "$miss" ]; then ok "$n"; else bad "$n" "it$miss in [$t]"; fi
}
# TEXT AWK-CONDITION: how many lines of TEXT, split on tabs, meet the condition.
_b11r3_c() { printf '%s\n' "$1" | LC_ALL=C awk -F'\t' "$2"' { n++ } END { print n + 0 }'; }

# ---- F7: the check, with and without a declaration ----------------------------------------------------
printf '\n  the check sets aside only what project.json declares, or vendor/ under a go.mod at the root (F7)\n'
# TABLE JSON: a fresh policy directory in _b11r3_P. TABLE is U (TU), V (TV) or - (no evidence.tsv); JSON
# is project.json's exact text, a final newline added, or - for no project.json.
_b11r3_p() {
  _b11r3_n=$((_b11r3_n + 1)); _b11r3_P="$B11R3/p$_b11r3_n"; mkdir -p "$_b11r3_P"
  case "$1" in U) printf '%s\n' "$_b11r3_TU" > "$_b11r3_P/evidence.tsv" ;; V) printf '%s\n' "$_b11r3_TV" > "$_b11r3_P/evidence.tsv" ;; esac
  [ "$2" = - ] || printf '%s\n' "$2" > "$_b11r3_P/project.json"
}
# DIR PATH [MORE]: DIR/PATH written holding its own path (a go.mod holds a module line), then MORE.
_b11r3_w() {
  local p="$1/$2"
  mkdir -p "$(dirname "$p")"
  case "$2" in go.mod|*/go.mod) printf 'module example.com/b11r3\n' > "$p" ;; *) printf '%s\n' "$2" > "$p" ;; esac
  [ -z "${3:-}" ] || printf '%s\n' "$3" >> "$p"
}
# G SPEC...: main holds README and each =X, -X and ~X; work, one commit on top, adds each +X, deletes
# each -X and changes each ~X. With _b11r3_wj set, work also writes it as projects/p/project.json.
_b11r3_mk() {
  local g="$1" s
  shift
  printf 'a readme\n' > "$g/README"
  for s in "$@"; do case "$s" in -*|=*|"~"*) _b11r3_w "$g" "${s#?}" ;; esac; done
  ( _fx_cd "$g" && git init -q -b main && git -c core.excludesFile=/dev/null add -A \
    && git -c user.name=t -c user.email=t@t commit -qm main && git checkout -q -b work ) >/dev/null 2>&1
  [ -z "$_b11r3_wj" ] || printf '%s\n' "$_b11r3_wj" > "$g/projects/p/project.json"
  for s in "$@"; do
    case "$s" in -*) rm -f "$g/${s#-}" ;; +*) _b11r3_w "$g" "${s#+}" ;; "~"*) _b11r3_w "$g" "${s#?}" "a second line on work" ;; esac
  done
  ( _fx_cd "$g" && git -c core.excludesFile=/dev/null add -A \
    && git -c user.name=t -c user.email=t@t commit -qm work ) >/dev/null 2>&1
}
# SPEC...: a fresh repository in _b11r3_G, built by _b11r3_mk, outside the policy directory.
_b11r3_g() {
  _b11r3_n=$((_b11r3_n + 1)); _b11r3_G="$B11R3/g$_b11r3_n"; mkdir -p "$_b11r3_G"
  _b11r3_wj=""; _b11r3_mk "$_b11r3_G" "$@"
  _b11r3_G="$(cd "$_b11r3_G" && pwd -P)"
}
# BASEJSON WORKJSON SPEC...: F7-in. The policy directory is G/projects/p, holding TU and BASEJSON on main;
# work writes WORKJSON there and makes SPEC's change.
_b11r3_gin() {
  local bj="$1"
  _b11r3_wj="$2"; shift 2
  _b11r3_n=$((_b11r3_n + 1)); _b11r3_G="$B11R3/g$_b11r3_n"; mkdir -p "$_b11r3_G/projects/p"
  printf '%s\n' "$_b11r3_TU" > "$_b11r3_G/projects/p/evidence.tsv"; printf '%s\n' "$bj" > "$_b11r3_G/projects/p/project.json"
  _b11r3_mk "$_b11r3_G" "$@"
  _b11r3_wj=""; _b11r3_G="$(cd "$_b11r3_G" && pwd -P)"; _b11r3_P="$_b11r3_G/projects/p"
}
# [BASE]: felix_evidence_check _b11r3_P BASE _b11r3_G (BASE main by default), as F1 runs it.
_b11r3_chk() { ( cd "$_b11r3_G" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/evidence.sh"
                 felix_evidence_check "$_b11r3_P" "${1:-main}" "$_b11r3_G" ) </dev/null 2>/dev/null; }
# NAME WANT SPEC...: one assertion that the check over the change SPEC prints exactly WANT's lines.
_b11r3_case() { local n="$1" w="$2"; shift 2; _b11r3_g "$@"; is "$n" "$(_b11r3_chk)" "$w"; }

# B11R3-1: nothing is set aside by its name alone.
_b11r3_p U -
_b11r3_case "B11R3 A109 (lib/vendor): own code under a nested vendor/ directory is not set aside by its name, so it gaps unit" \
            "$_b11r3_Ug" +lib/vendor/parse.go
_b11r3_case "B11R3 A109 (src/third_party): own code under a nested third_party/ directory gaps unit" \
            "$_b11r3_Ug" +src/third_party/shim.ts
_b11r3_case "B11R3 A109 (src/node_modules): own code under a nested node_modules/ directory gaps unit" \
            "$_b11r3_Ug" +src/node_modules/local/index.js
_b11r3_case "B11R3 A110: vendor/ at the root, with no go.mod in the base and no declaration, is not set aside: unit gap" \
            "$_b11r3_Ug" +vendor/acme/pkg/x.go
_b11r3_case "B11R3 A111: a go.mod the change itself adds sets nothing aside, so vendor/ still gaps unit" \
            "$_b11r3_Ug" +go.mod +vendor/acme/pkg/x.go
_b11r3_case "B11R3 A112: an edit to own code already under src/vendor/ gaps unit" \
            "$_b11r3_Ug" =src/vendor/session.go '~src/vendor/session.go'
_b11r3_case "B11R3 A113: moving own code from src/auth/ into src/vendor/ gaps unit (control)" \
            "$_b11r3_Ug" -src/auth/session.go +src/vendor/auth/session.go
# B11R3-3 and B11R3-6: Go's vendor/, at the root only, under a go.mod the base holds.
_b11r3_case "B11R3 A114: a nested module's vendor/ is not set aside by the go.mod at the root, so it gaps unit" \
            "$_b11r3_Ug" =go.mod +services/auth/vendor/github.com/pkg/errors/errors.go
_b11r3_case "B11R3 A115: under a go.mod at the root of the base, a path under vendor/ is set aside: unit n/a, then VENDORED counting 1 under vendor/" \
            "$(_b11r3_ls "$_b11r3_Un" "$(_b11r3_V 1 vendor/)")" =go.mod +vendor/github.com/x/y/pkg/z.go
_b11r3_case "B11R3 A116: a go mod vendor bump of three paths, one of them deleted, reads unit n/a and VENDORED counting 3" \
            "$(_b11r3_ls "$_b11r3_Un" "$(_b11r3_V 3 vendor/)")" \
            =go.mod -vendor/github.com/pkg/errors/go113.go +vendor/github.com/pkg/errors/errors.go +vendor/modules.txt
_b11r3_case "B11R3 A117: a set-aside vendor/ path hides nothing: own untested code beside it gaps unit, then VENDORED counting 1" \
            "$(_b11r3_ls "$_b11r3_Ug" "$(_b11r3_V 1 vendor/)")" \
            =go.mod +vendor/github.com/pkg/errors/errors.go +internal/handlers/auth.go
# B11R3-4: a vendored test proves nothing.
_b11r3_case "B11R3 A118 (vendor/ test): a _test.go under vendor/ meets no requires cell, so own code beside it gaps unit (control)" \
            "$_b11r3_Ug" +internal/x/y.go +vendor/github.com/pkg/errors/errors_test.go
_b11r3_case "B11R3 A118 (src/third_party test): a _test.go under a nested third_party/ meets no requires cell either (control)" \
            "$_b11r3_Ug" +src/a.go +src/third_party/x/x_test.go
_b11r3_case "B11R3 A119: a test under tests/ still meets unit (control)" "$_b11r3_Um" +src/a.go +tests/a_test.go
# B11R3-2 and B11R3-6: the declaration.
_b11r3_p U "$_b11r3_J1"
_b11r3_case "B11R3 A120: a directory project.json declares in evidence_vendored is set aside: unit n/a, VENDORED counting 1 under third_party/" \
            "$(_b11r3_ls "$_b11r3_Un" "$(_b11r3_V 1 third_party/)")" +third_party/lib/a.c
_b11r3_case "B11R3 A121: an entry declared without a trailing slash is set aside and named with one, web/assets/vendor/" \
            "$(_b11r3_ls "$_b11r3_Un" "$(_b11r3_V 1 web/assets/vendor/)")" +web/assets/vendor/lib/jquery.js
_b11r3_case "B11R3 A122: an entry is matched from the root only, so src/third_party/ is not set aside and gaps unit" \
            "$_b11r3_Ug" +src/third_party/shim.ts
_b11r3_p U "$_b11r3_J2"
_b11r3_case "B11R3 A123: with no go.mod, declaring third_party/ sets aside third_party/ alone: unit gap, VENDORED counting 1" \
            "$(_b11r3_ls "$_b11r3_Ug" "$(_b11r3_V 1 third_party/)")" +third_party/lib/a.c +src/third_party/shim.ts +vendor/x/pkg/y.go
_b11r3_case "B11R3 A124: a declared and a Go set-aside count together, 2, named in project.json's order and then vendor/" \
            "$(_b11r3_ls "$_b11r3_Un" "$(_b11r3_V 2 'third_party/ vendor/')")" =go.mod +third_party/lib/a.c +vendor/x/pkg/y.go
_b11r3_case "B11R3 A125: a test under a declared directory proves nothing: unit gap, VENDORED counting 1" \
            "$(_b11r3_ls "$_b11r3_Ug" "$(_b11r3_V 1 third_party/)")" +src/a.go +third_party/x/test/a_test.go
_b11r3_p U '{"evidence_vendored": "lib/vendor"}'
_b11r3_case "B11R3 A126 (lib/vendor): an entry sets aside only what begins with it plus a slash, so lib/vendored/ gaps unit (control)" \
            "$_b11r3_Ug" +lib/vendored/x.go
_b11r3_p U '{"evidence_vendored": ""}'
_b11r3_case "B11R3 A126 (empty): an empty evidence_vendored declares nothing (control)" "$_b11r3_Ug" +src/a.go
# B11R3-5: inside the repository, the declaration is read as committed at the base.
_b11r3_gin '{"name":"p"}' '{"name":"p","evidence_vendored":"third_party/"}' +third_party/lib/a.c
is "B11R3 A127: inside the repository, a declaration the change itself adds sets nothing aside: unit gap" \
   "$(_b11r3_chk)" "$_b11r3_Ug"
_b11r3_gin '{"name":"p","evidence_vendored":"third_party/"}' '{"name":"p","evidence_vendored":"third_party/"}' +third_party/lib/a.c
is "B11R3 A128: inside the repository, a declaration committed at the base sets third_party/ aside: unit n/a, VENDORED counting 1" \
   "$(_b11r3_chk)" "$(_b11r3_ls "$_b11r3_Un" "$(_b11r3_V 1 third_party/)")"
# B11R3-7: a row opts back in.
_b11r3_p V "$_b11r3_J3"
_b11r3_case "B11R3 A129: a row named in evidence_reads_vendored reads a set-aside path: deps gap, and VENDORED says only deps read them" \
            "$(_b11r3_ls "$_b11r3_Un" "$_b11r3_dg" \
               "$(printf 'n/a\tVENDORED\t1 changed path(s) set aside as vendored, under vendor/, so only deps read them')")" \
            =go.mod +vendor/github.com/x/pkg/y.go
_b11r3_g =go.mod +vendor/github.com/x/pkg/y.go +vendor/modules.txt
_b11r3_v="$(_b11r3_chk)"
_b11r3_x="$(printf '%s\n' "$_b11r3_v" | LC_ALL=C awk -F'\t' 'NR == 3 && $1 == "n/a" && $2 == "VENDORED" && index($3, "2 changed path(s)") == 1 &&
              substr($3, length($3) - 21) == "so only deps read them" { print "as read" }')"
[ -n "$_b11r3_x" ] || _b11r3_x="[$(printf '%s\n' "$_b11r3_v" | sed -n 3p)]"
is "B11R3 A130: and its requires cell reads one too: deps met, and VENDORED counts 2 and says only deps read them" \
   "$(printf '%s\n' "$_b11r3_v" | sed -n 1,2p)|lines $(printf '%s' "$_b11r3_v" | awk 'END { print NR }')|third $_b11r3_x" \
   "$(_b11r3_ls "$_b11r3_Un" "$_b11r3_dm")|lines 3|third as read"
_b11r3_p V -
_b11r3_case "B11R3 A131: a row that has not opted in reads no set-aside path: deps n/a, and VENDORED says no rule read them" \
            "$(_b11r3_ls "$_b11r3_Un" "$_b11r3_dn" "$(_b11r3_V 1 vendor/)")" =go.mod +vendor/github.com/x/pkg/y.go
_b11r3_p V "$_b11r3_J3"
_b11r3_case "B11R3 A132: an opted-in row's requires cell reads a vendor-named path no rule sets aside: deps met, no VENDORED line" \
            "$(_b11r3_ls "$_b11r3_Ug" "$_b11r3_dm")" +src/a.go +vendor/modules.txt
_b11r3_p V -
_b11r3_case "B11R3 A133: a row that has not opted in never reads a vendor-named path with requires: deps gap" \
            "$(_b11r3_ls "$_b11r3_Ug" "$_b11r3_dg")" +src/a.go +vendor/modules.txt

# ---- B11R3-8: a declaration the check cannot read ------------------------------------------------------
printf '\n  a declaration the check cannot read is one unknown line for project.json, not judged (F7)\n'
_b11r3_nj='3~not judged'; _b11r3_nr='3!no rule was consulted'
_b11r3_g +src/a.go
_b11r3_p U '{"evidence_vendored": ["vendor/"]}'
is "B11R3 A134 (a list): an evidence_vendored that is a JSON list is one unknown line for project.json, naming the key, not judged" \
   "$(_b11r3_says "$(_b11r3_chk)" 1 1=unknown 2=project.json 3~evidence_vendored "$_b11r3_nj" "$_b11r3_nr")" ok
_b11r3_p U "$_b11r3_JX"
is "B11R3 A134 (a number): an evidence_vendored that is a JSON number is one unknown line for project.json, naming the key, not judged" \
   "$(_b11r3_says "$(_b11r3_chk)" 1 1=unknown 2=project.json 3~evidence_vendored "$_b11r3_nj" "$_b11r3_nr")" ok
for _b11r3_e in '../shared/|has a .. component' '/vendor/|has a leading slash' \
                'vendor/*|holds a character other than a letter, a digit or . _ - @ +' '.|is . alone' \
                'a//b/|has an empty component' 'src/./x|has a . component'; do
  _b11r3_p U "{\"evidence_vendored\": \"third_party/ ${_b11r3_e%%|*}\"}"
  is "B11R3 A135 (${_b11r3_e%%|*}): an evidence_vendored entry that ${_b11r3_e#*|} is one unknown line for project.json naming it, not judged" \
     "$(_b11r3_says "$(_b11r3_chk)" 1 1=unknown 2=project.json "3~${_b11r3_e%%|*}" "$_b11r3_nj" "$_b11r3_nr")" ok
done
_b11r3_p U "$(_b11r3_ls '{' '"evidence_vendored": "third_party/",' '"evidence_vendored": "x/"' '}')"
is "B11R3 A136: a key that appears twice in project.json is one unknown line for project.json, naming the key, not judged" \
   "$(_b11r3_says "$(_b11r3_chk)" 1 1=unknown 2=project.json 3~evidence_vendored "$_b11r3_nj" "$_b11r3_nr")" ok
_b11r3_p U '{"evidence_reads_vendored": "nosuch"}'
is "B11R3 A137: an evidence_reads_vendored name that is no row of evidence.tsv is one unknown line for project.json naming it, not judged" \
   "$(_b11r3_says "$(_b11r3_chk)" 1 1=unknown 2=project.json 3~nosuch "$_b11r3_nj" "$_b11r3_nr")" ok
_b11r3_p U "$_b11r3_J2"; chmod 000 "$_b11r3_P/project.json"
if [ -r "$_b11r3_P/project.json" ]; then
  skip "B11R3 A138: a project.json that cannot be read is one unknown line for project.json, not judged" \
       "a mode-000 file is still readable here (root)"
else
  is "B11R3 A138: a project.json that cannot be read is one unknown line for project.json, not judged" \
     "$(_b11r3_says "$(_b11r3_chk)" 1 1=unknown 2=project.json "$_b11r3_nj" "$_b11r3_nr")" ok
fi
chmod 644 "$_b11r3_P/project.json"
_b11r3_p - "$_b11r3_JX"
is "B11R3 A139: with no evidence.tsv nothing is printed, a declaration it cannot read included (control)" "$(_b11r3_chk)" ""
_b11r3_p U "$_b11r3_JX"
is "B11R3 A140: a base that names nothing comes before a declaration it cannot read: one unknown line for the base, no rule consulted (control)" \
   "$(_b11r3_says "$(_b11r3_chk no-such-ref)" 1 1=unknown 2=no-such-ref '3~no rule was consulted')" ok
chmod 000 "$_b11r3_P/evidence.tsv"
if [ -r "$_b11r3_P/evidence.tsv" ]; then
  skip "B11R3 A141: an evidence.tsv that cannot be read comes before a declaration it cannot read: one unknown line for evidence.tsv (control)" \
       "a mode-000 file is still readable here (root)"
else
  is "B11R3 A141: an evidence.tsv that cannot be read comes before a declaration it cannot read: one unknown line for evidence.tsv (control)" \
     "$(_b11r3_says "$(_b11r3_chk)" 1 1=unknown 2=evidence.tsv)" ok
fi
chmod 644 "$_b11r3_P/evidence.tsv"

# ---- F2, F3: the commands over the widget checkout --------------------------------------------------------
printf '\n  felix evidence, merge and receipt over a declaration (F2, F3)\n'
printf '%s\n' "$_b11r3_TU" > "$_b11r3_wp/evidence.tsv"
# [KEYLINE]: widget's project.json as this part found it, with KEYLINE and a comma on a line of their own
# after the opening brace; with no KEYLINE, the file as this part found it.
_b11r3_pj() {
  if [ -z "${1:-}" ]; then cp "$B11R3/project.json.keep" "$_b11r3_wp/project.json"; return 0; fi
  LC_ALL=C awk -v k="$1" '!d && index($0, "{") { i = index($0, "{"); print substr($0, 1, i); print "  " k ","
                            r = substr($0, i + 1); if (r != "") print r; d = 1; next } { print }' \
    "$B11R3/project.json.keep" > "$_b11r3_wp/project.json"
}
# PATH...: each written in $REPO with a line no earlier commit held, then committed by _stage.
_b11r3_ch() {
  local p
  _b11r3_k=$((_b11r3_k + 1))
  for p in "$@"; do mkdir -p "$(dirname "$REPO/$p")"; printf 'b11r3 change %s\n' "$_b11r3_k" > "$REPO/$p"; done
  _stage
}
_b11r3_run() { _b11r3_o="$(cd "$REPO" && "$FELIX" "$@" </dev/null 2>&1)"; _b11r3_rc=$?; }
# BASE: felix_merge_blockers over the widget checkout, sourced as 0100's _blk sources it.
_b11r3_blk() { ( cd "$REPO" && . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
                 . "$FROOT/harness/lib/evidence.sh"; . "$FROOT/harness/lib/verify.sh"
                 felix_merge_blockers "$_b11r3_wp" "$1" "$REPO" "$FROOT" ) </dev/null 2>/dev/null; }
# JSON: "ok", or what B10's first two points find wrong with a receipt.
_b11r3_rcj() {
  printf '%s' "$1" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception as e:
    print("not json: %s" % e); sys.exit(0)
w = []
u = d.get("unknown")
if not (isinstance(u, list) and "evidence" in u): w.append("unknown is %s" % json.dumps(u))
if d.get("status") != "indeterminate": w.append("status is %s" % json.dumps(d.get("status")))
print("; ".join(w) if w else "ok")' 2>&1
}

_b11r3_pj '"evidence_vendored": "third_party/"'; _b11r3_ch third_party/lib/a.c
_b11r3_run evidence --base HEAD~1
_b11r3_hl "B11R3 A142: felix evidence prints the set-aside as [-] VENDORED with its count and directory, says No evidence gaps, and exits 0" \
          "[rc=$_b11r3_rc] $_b11r3_o" '+[rc=0]' '+[-] VENDORED' '+1 changed path(s) set aside as vendored, under third_party/' '+No evidence gaps.'
_b11r3_v="$(_b11r3_blk HEAD~1)"
is "B11R3 A143: and felix_merge_blockers prints no evidence line for it (control)" \
   "$(_b11r3_c "$_b11r3_v" '$1 == "evidence"') [$_b11r3_v]" "0 [$_b11r3_v]"
_reset; _b11r3_pj
_b11r3_ch third_party/lib/a.c
_b11r3_v="$(_b11r3_blk HEAD~1)"
is "B11R3 A144: with no declaration, felix_merge_blockers prints the unit gap for a change under third_party/" \
   "$(_b11r3_c "$_b11r3_v" '$0 == "evidence\tunit\tcode changes need a test"') [$_b11r3_v]" "1 [$_b11r3_v]"
_reset

_b11r3_pj '"evidence_vendored": ["third_party/"]'; _b11r3_ch src/a.js
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" >/dev/null 2>&1 )
_cm_stamp
_fx_git "$REPO" update-ref refs/heads/b11r3-mbase HEAD~1 >/dev/null 2>&1
_b11r3_run merge --base refs/heads/b11r3-mbase --dry-run
_b11r3_hl "B11R3 A145: felix merge refuses a declaration it cannot read, exit 3, naming project.json and not judged" \
          "[rc=$_b11r3_rc] $_b11r3_o" '+[rc=3]' '+project.json' '+not judged'
_fx_git "$REPO" update-ref -d refs/heads/b11r3-mbase >/dev/null 2>&1
is "B11R3 A146: and felix receipt lists evidence as unknown and is indeterminate" \
   "$(_b11r3_rcj "$(cd "$REPO" && "$FELIX" receipt --base HEAD~1 </dev/null 2>/dev/null)")" ok
_b11r3_run evidence --base HEAD~1
_b11r3_hl "B11R3 A147: and felix evidence prints [?] project.json, exits 1, and claims no all-clear" \
          "[rc=$_b11r3_rc] $_b11r3_o" '+[?] project.json' '+[rc=1]' '-No evidence gaps'
_reset; _b11r3_pj

# ---- B11R3-11: the brief sets nothing aside -----------------------------------------------------------------
printf '\n  the brief reads every path it is given and never reads project.json\n'
# PATHS: felix_brief_evidence _b11r3_P PATHS, in a shell that sources only lib/resolve.sh and lib/intake.sh.
_b11r3_bev() { ( cd "$B11R3" && bash -c '. "$1/lib/resolve.sh"; . "$1/lib/intake.sh"; felix_brief_evidence "$2" "$3"' \
                 _ "$FROOT/harness" "$_b11r3_P" "$1" ) </dev/null 2>/dev/null; }
_b11r3_p U '{"evidence_vendored": "vendor/"}'
is "B11R3 A148: felix_brief_evidence sets nothing aside: a path under a declared vendor/ fires unit, with only intake.sh sourced" \
   "$(_b11r3_bev vendor/github.com/x/pkg/a.go)" "$(printf 'unit\tcode changes need a test')"
_b11r3_p U "$_b11r3_JX"
is "B11R3 A149: and it never reads project.json, so a declaration the check cannot read changes nothing (control)" \
   "$(_b11r3_bev src/a.go)" "$(printf 'unit\tcode changes need a test')"

# ---- the review round: B11R3-13 and B11R3-14 ----------------------------------------------------------------
printf '\n  inside the repository is a matter of identity, and a changed path is read as its own bytes (review round)\n'
# PROJ ROOT: the check with PROJ and ROOT spelled as given and the cwd ROOT as spelled, base main.
_b11r3_chkv() { ( cd "$2" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/evidence.sh"
                  felix_evidence_check "$1" main "$2" ) </dev/null 2>/dev/null; }
# NAME WANT ALT CANON PROJ ROOT: when ALT is another spelling of CANON's directory on this machine, one
# assertion that the check with PROJ and ROOT prints exactly WANT; otherwise a skip.
_b11r3_alt() {
  if [ "$3" != "$4" ] && [ -d "$3" ] && [ "$3" -ef "$4" ]; then is "$1" "$(_b11r3_chkv "$5" "$6")" "$2"
  else skip "$1" "[$3] is not another spelling of [$4] on this machine"; fi
}
_b11r3_gin '{"name":"p"}' '{"name":"p","evidence_vendored":"third_party/"}' +third_party/lib/a.c
_b11r3_x="${_b11r3_G%/*}/$(printf '%s' "${_b11r3_G##*/}" | LC_ALL=C tr '[:lower:]' '[:upper:]')"
_b11r3_alt "B11R3V A152 (root case): a root spelled in another case is the same directory, so a declaration the change adds sets nothing aside: unit gap" \
           "$_b11r3_Ug" "$_b11r3_x" "$_b11r3_G" "$_b11r3_P" "$_b11r3_x"
_b11r3_alt "B11R3V A153 (project case): a project directory whose repository component is spelled in another case is inside the repository: unit gap" \
           "$_b11r3_Ug" "$_b11r3_x" "$_b11r3_G" "$_b11r3_x/projects/p" "$_b11r3_G"
_b11r3_alt "B11R3V A168 (project case below the root): a project directory spelled in another case below the root is inside the repository: unit gap (control)" \
           "$_b11r3_Ug" "$_b11r3_G/projects/P" "$_b11r3_P" "$_b11r3_G/projects/P" "$_b11r3_G"
_b11r3_alt "B11R3V A154 (root //): a root spelled with a leading // is the same directory: unit gap" \
           "$_b11r3_Ug" "/$_b11r3_G" "$_b11r3_G" "$_b11r3_P" "/$_b11r3_G"
_b11r3_alt "B11R3V A155 (project //): a project directory spelled with a leading // is inside the repository: unit gap" \
           "$_b11r3_Ug" "/$_b11r3_P" "$_b11r3_P" "/$_b11r3_P" "$_b11r3_G"
_b11r3_alt "B11R3V A156 (root firmlink): a root spelled under /System/Volumes/Data is the same directory: unit gap" \
           "$_b11r3_Ug" "/System/Volumes/Data$_b11r3_G" "$_b11r3_G" "$_b11r3_P" "/System/Volumes/Data$_b11r3_G"
rm -f "$B11R3/link"; ln -s "$_b11r3_G" "$B11R3/link"
_b11r3_alt "B11R3V A157 (root symlink): a root reached through a symlink is the same directory: unit gap (control)" \
           "$_b11r3_Ug" "$B11R3/link" "$_b11r3_G" "$_b11r3_P" "$B11R3/link"
_b11r3_gin '{"name":"p","evidence_vendored":"third_party/"}' '{"name":"p","evidence_vendored":"third_party/"}' +third_party/lib/a.c
_b11r3_alt "B11R3V A158 (project case, declared): read at the base under the path the repository records, so the committed declaration holds: unit n/a, VENDORED 1" \
           "$(_b11r3_ls "$_b11r3_Un" "$(_b11r3_V 1 third_party/)")" "$_b11r3_G/projects/P" "$_b11r3_P" "$_b11r3_G/projects/P" "$_b11r3_G"

# FILE SPEC...: a fresh repository as _b11r3_g builds it, core.quotePath true in its config, and the check's
# output in _b11r3_v; status 1 when neither main nor work holds FILE (the file system refused the name).
_b11r3_q() {
  local f="$1"
  shift
  _b11r3_g "$@"; _b11r3_v=""
  _fx_git "$_b11r3_G" config core.quotePath true >/dev/null 2>&1
  _fx_git "$_b11r3_G" cat-file -e "work:$f" >/dev/null 2>&1 || _fx_git "$_b11r3_G" cat-file -e "main:$f" >/dev/null 2>&1 || return 1
  _b11r3_v="$(_b11r3_chk)"
}
# NAME WANT FILE SPEC...: one assertion that the check over SPEC prints exactly WANT, or a skip.
_b11r3_qcase() {
  local n="$1" w="$2"
  shift 2
  if _b11r3_q "$@"; then is "$n" "$_b11r3_v" "$w"; else skip "$n" "this file system refused the name [$1]"; fi
}
_b11r3_e="$(printf 'caf\303\251')"
_b11r3_p U -
_b11r3_qcase "B11R3V A159 (a byte above 127): own code whose name holds a UTF-8 e-acute is read as its own name, not as git quotes it: unit gap" \
             "$_b11r3_Ug" "src/$_b11r3_e.go" "+src/$_b11r3_e.go"
_b11r3_qcase "B11R3V A160 (a double quote): own code whose name holds a double quote is read as its own name: unit gap" \
             "$_b11r3_Ug" 'src/a"b.go' '+src/a"b.go'
_b11r3_qcase "B11R3V A161 (a backslash): own code whose name holds a backslash is read as its own name: unit gap" \
             "$_b11r3_Ug" 'src/a\b.go' '+src/a\b.go'
_b11r3_qcase "B11R3V A162 (a tab): own code whose name holds a tab is read as its own name: unit gap" \
             "$_b11r3_Ug" "src/a"$'\t'"b.go" "+src/a"$'\t'"b.go"
_b11r3_qcase "B11R3V A163 (deleted): deleting own code whose name holds a UTF-8 e-acute gaps unit" \
             "$_b11r3_Ug" "src/$_b11r3_e.go" "-src/$_b11r3_e.go"
_b11r3_qcase "B11R3V A164 (requires): a test whose name holds a UTF-8 e-acute is read by the requires cell: unit met" \
             "$_b11r3_Um" "src/$_b11r3_e.go" "+src/$_b11r3_e.go" "+tests/${_b11r3_e}_test.go"
_b11r3_p U "$_b11r3_J2"
_b11r3_qcase "B11R3V A165 (set aside): a path under a declared directory whose name holds a UTF-8 e-acute is set aside and counted: unit n/a, VENDORED 1" \
             "$(_b11r3_ls "$_b11r3_Un" "$(_b11r3_V 1 third_party/)")" "third_party/$_b11r3_e.c" "+third_party/$_b11r3_e.c"
_b11r3_p U -
_b11r3_x="z"$'\n'"tests/z_test.go"
if _b11r3_q "$_b11r3_x" +src/a.go "+$_b11r3_x"; then
  is "B11R3V A166 (a newline): a name holding a newline is never split into two paths: one unknown line for CHANGED-PATHS, not judged" \
     "$(_b11r3_says "$_b11r3_v" 1 1=unknown 2=CHANGED-PATHS "$_b11r3_nj" "$_b11r3_nr")" ok
else
  skip "B11R3V A166 (a newline): a name holding a newline is never split into two paths: one unknown line for CHANGED-PATHS, not judged" \
       "this file system refused a name holding a newline"
fi
_b11r3_x="z"$'\n'"tests/z_test.js"
_b11r3_ch src/a.js "$_b11r3_x"
if _fx_git "$REPO" cat-file -e "HEAD:$_b11r3_x" >/dev/null 2>&1; then
  _b11r3_v="$(_b11r3_blk HEAD~1)"
  is "B11R3V A167 (merge): felix_merge_blockers refuses a change holding a name with a newline: its one evidence line is CHANGED-PATHS, not judged" \
     "$(_b11r3_c "$_b11r3_v" '$1 == "evidence"') $(_b11r3_c "$_b11r3_v" '$1 == "evidence" && $2 == "CHANGED-PATHS" && index($3, "not judged") > 0') [$_b11r3_v]" \
     "1 1 [$_b11r3_v]"
else
  skip "B11R3V A167 (merge): felix_merge_blockers refuses a change holding a name with a newline: its one evidence line is CHANGED-PATHS, not judged" \
       "this file system refused a name holding a newline"
fi
_reset

# The widget's tables, as this part found them.
for _b11r3_f in evidence.tsv project.json; do
  if [ -f "$B11R3/$_b11r3_f.keep" ]; then cp "$B11R3/$_b11r3_f.keep" "$_b11r3_wp/$_b11r3_f"; else rm -f "$_b11r3_wp/$_b11r3_f"; fi
done
unset -f _b11r3_V _b11r3_ls _b11r3_says _b11r3_hl _b11r3_c _b11r3_p _b11r3_w _b11r3_mk _b11r3_g _b11r3_gin _b11r3_chk \
         _b11r3_case _b11r3_pj _b11r3_ch _b11r3_run _b11r3_blk _b11r3_rcj _b11r3_bev _b11r3_chkv _b11r3_alt _b11r3_q \
         _b11r3_qcase
