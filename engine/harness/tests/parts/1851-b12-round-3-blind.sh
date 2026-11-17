printf '\nthe remote a grant is checked against comes from fixed state (audit b12, round 3; blind)\n'
# Written blind on 2026-10-28 from docs/2026-10-24-audit-fixes/b12-round-3.md (B12R3-1 to B12R3-7,
# assertions 98 to 110), with the batch contract's section 2 and section 9 conventions, before the fix
# and with no engine code read. The argument order is the one part 1850's header gives:
# felix_exception_for takes the project directory, the obligation, its class and the ledger line;
# felix_exceptions_doubt and felix_exceptions_judge take the project directory; felix_obligations_run
# takes the project directory and the root; felix_resolve_project takes a start and a home. Each
# assertion is named B12R3 A<n> after the contract's number. Nothing part 1850 defines is used.
#
# Readings, where the contract leaves room. "Prints nothing" is empty stdout; "exactly D" is stdout,
# its trailing newline dropped, equal to D. A judge row is read as five tab-separated fields, all five
# compared. Column 8 is read from felix_obligations_run PROJ REPO, REPO the repository's top level. In
# A104 felix_exception_for and the doubt are read for both spellings of p, the judge and column 8 for
# S2/projects/p. In A109 the logging git must have logged at least one call, so the watch is not
# vacuous, and the snapshot is taken with fixture S's environment. In A110 a comment line is one whose
# first non-blank character is #; its text is what follows its leading blanks and #s, with every run of
# blanks squeezed to one space, and lines are joined with one space. The head is the comment lines
# above the first line that is neither blank nor a comment. The doubt's block is the unbroken run of
# comment lines that ends on the line just above the first line beginning, after its leading blanks,
# felix_exceptions_doubt() {. "marker first" is looked for in each comment line on its own. The
# dangling .felix points at a path under the fixture that does not exist.
#
# Fixture S (section 2): six bare repositories under srv and srv2; S1, with no .felix, holding x
# (acme/x, header only) and y (acme/y, with ROW), its origin srv/acme/x.git, and a branch forged that
# adds x's grant, pushed as main to srv/acme/y.git and srv/other/x.git; S2, whose .felix holds felix,
# holding felix ("") and p (acme/p), both header only, its origin srv2/home/felix.git, and a branch
# forged that adds both grants, pushed as main to srv2/evil/z.git and srv2/look/acme/p.git; and slink,
# a symbolic link to S2. All of it is under one mktemp -d in $TMP. Every call sets HOME, an empty
# FELIX_MEMORY M and GIT_CONFIG_NOSYSTEM there. Each route starts from the baseline; afterwards the
# URL is put back and one plain fetch restores origin/main.
# Review round (2026-10-28): B12R3-8 to B12R3-11, assertions 111 to 116, named B12R3V A<n>, written
# blind from the same file's section 8 with no engine code read. s4 and s5 run after A108's state is
# put back: s4 takes S2's marker away while p stands beside felix; s5 nests a repository at S2/projects
# and removes it afterwards. A116 reads the doubt's comment block as A110 does.
RR3="$(mktemp -d "$TMP/b12r3.XXXXXX" 2>/dev/null)" && RR3="$(cd "$RR3" && pwd -P)" || RR3=""
if [ -z "$RR3" ] || [ ! -d "$RR3" ]; then
  bad "B12R3 fixture: mktemp -d made a directory under \$TMP" "got [$RR3]"; RR3="$TMP/b12r3-fallback"; mkdir -p "$RR3"
fi
RR3H="$RR3/home"; RR3M="$RR3/mem"; RR3V="$RR3/srv"; RR3V2="$RR3/srv2"; RR3S1="$RR3/s1"; RR3S2="$RR3/s2"; RR3SL="$RR3/slink"
mkdir -p "$RR3H" "$RR3M" "$RR3V/acme" "$RR3V/other" "$RR3V2/home" "$RR3V2/evil" "$RR3V2/look/acme" "$RR3/wrap" "$RR3S1" "$RR3S2"
RR3LIVE="$(( $(date -u +%Y) + 1 ))-06-01T00:00:00Z"
RR3L="$(printf 'ob1\tTASK_BLOCKING\tdeterministic\t-\tfalse\t-\t%s' "the fixture's one blocking row")"
RR3H16="$(printf '%s\n' "$RR3L" | git hash-object --stdin | LC_ALL=C cut -c1-16)"
RR3ROW="$(printf 'ob1\t%s\t%s\tthe-founder\tfixture grant' "$RR3H16" "$RR3LIVE")"
RR3FOR="excepted|$RR3LIVE|the-founder"
RR3D1="remote_match cannot be read: this repository's .felix marker names no project in it"
RR3D2="remote_match cannot be read: felix, the project this repository's .felix marker names, declares none"
RR3DM="remote_match: origin's URL does not name the remote_match this project declares"

# ---- fixture S ---------------------------------------------------------------------------------
_rr3g() { ( export HOME="$RR3H" XDG_CONFIG_HOME="$RR3H/.config" GIT_CONFIG_NOSYSTEM=1; _fx_git "$@" ) >/dev/null 2>&1; }
_rr3q() { ( export HOME="$RR3H" XDG_CONFIG_HOME="$RR3H/.config" GIT_CONFIG_NOSYSTEM=1; _fx_git "$@" ) 2>/dev/null; }
_rr3ci() { _rr3g "$1" add -A && _rr3g "$1" -c user.name=t -c user.email=t@t commit -qm "$2"; }
_rr3proj() {  # REPO NAME REMOTE_MATCH grant|nogrant: projects/NAME with project.json, L, and B6's header (and ROW)
  mkdir -p "$1/projects/$2"
  printf '{ "name": "%s", "remote_match": "%s", "gate": "true" }\n' "$2" "$3" > "$1/projects/$2/project.json"
  printf '%s\n' "$RR3L" > "$1/projects/$2/obligations.tsv"
  printf '# obligation\trow_hash\texpires\tgranted_by\treason\n' > "$1/projects/$2/exceptions.tsv"
  if [ "$4" = grant ]; then printf '%s\n' "$RR3ROW" >> "$1/projects/$2/exceptions.tsv"; fi
}
_rr3url() { _rr3g "$1" config remote.origin.url "$2"; _rr3g "$1" fetch -q; }  # REPO URL: the URL set, then one plain fetch
for _rr3i in "$RR3V/acme/x.git" "$RR3V/acme/y.git" "$RR3V/other/x.git" "$RR3V2/home/felix.git" "$RR3V2/evil/z.git" "$RR3V2/look/acme/p.git"; do
  _rr3g "${_rr3i%/*}" init -q --bare -b main "${_rr3i##*/}"
done
# S1: no marker; x header only, y with ROW; origin srv/acme/x.git; forged adds x's grant.
_rr3proj "$RR3S1" x acme/x nogrant; _rr3proj "$RR3S1" y acme/y grant
_rr3g "$RR3S1" init -q -b main; _rr3ci "$RR3S1" 'fixture S1: x header only, y granted, no marker'
_rr3g "$RR3S1" config remote.origin.url "$RR3V/acme/x.git"; _rr3g "$RR3S1" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
_rr3g "$RR3S1" push -q origin main; _rr3g "$RR3S1" fetch -q origin
_rr3g "$RR3S1" checkout -q -b forged; printf '%s\n' "$RR3ROW" >> "$RR3S1/projects/x/exceptions.tsv"
_rr3ci "$RR3S1" "x's grant, on a branch nobody merged"
_rr3g "$RR3S1" push -q "$RR3V/acme/y.git" forged:main; _rr3g "$RR3S1" push -q "$RR3V/other/x.git" forged:main
_rr3g "$RR3S1" checkout -q main
RR3F1="$(git -C "$RR3S1" rev-parse -q --verify refs/heads/forged 2>/dev/null)"
# S2: .felix names felix, which declares none; p declares acme/p; forged adds both grants.
printf 'felix\n' > "$RR3S2/.felix"; _rr3proj "$RR3S2" felix '' nogrant; _rr3proj "$RR3S2" p acme/p nogrant
_rr3g "$RR3S2" init -q -b main; _rr3ci "$RR3S2" 'fixture S2: a marker naming felix, and a product p'
_rr3g "$RR3S2" config remote.origin.url "$RR3V2/home/felix.git"; _rr3g "$RR3S2" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
_rr3g "$RR3S2" push -q origin main; _rr3g "$RR3S2" fetch -q origin
_rr3g "$RR3S2" checkout -q -b forged
printf '%s\n' "$RR3ROW" >> "$RR3S2/projects/felix/exceptions.tsv"; printf '%s\n' "$RR3ROW" >> "$RR3S2/projects/p/exceptions.tsv"
_rr3ci "$RR3S2" 'both grants, on a branch nobody merged'
_rr3g "$RR3S2" push -q "$RR3V2/evil/z.git" forged:main; _rr3g "$RR3S2" push -q "$RR3V2/look/acme/p.git" forged:main
_rr3g "$RR3S2" checkout -q main
ln -s "$RR3S2" "$RR3SL"
_rr3marker() {  # gone|empty|dir|dangling|none|felix: what stands at S2's .felix
  local f="$RR3S2/.felix"
  if [ -d "$f" ] && [ ! -L "$f" ]; then rmdir "$f" 2>/dev/null; else rm -f "$f"; fi
  case "$1" in
    gone) printf 'gone\n' > "$f" ;;
    empty) : > "$f" ;;
    dir) mkdir "$f" ;;
    dangling) ln -s "$RR3/no-marker-here" "$f" ;;
    felix) printf 'felix\n' > "$f" ;;
  esac
}
# A logging git and a logging gh first on PATH (A109).
RR3GIT="$(command -v git)"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s"\nexec "%s" "$@"\n' "$RR3/wrap.log" "$RR3GIT" > "$RR3/wrap/git"
printf '#!/bin/sh\nprintf "gh %%s\\n" "$*" >> "%s"\nexit 1\n' "$RR3/gh.log" > "$RR3/wrap/gh"
chmod +x "$RR3/wrap/git" "$RR3/wrap/gh"

_rr3x() {  # FUNCTION ARGS... -> its stdout, in fixture S's environment with the exception libraries sourced
  ( export HOME="$RR3H" XDG_CONFIG_HOME="$RR3H/.config" FELIX_MEMORY="$RR3M" GIT_CONFIG_NOSYSTEM=1
    unset CLAUDE_CONFIG_DIR FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"
    . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/exceptions.sh"
    "$@" ) </dev/null 2>/dev/null
}
_rr3for() { local o r; o="$(_rr3x felix_exception_for "$1" ob1 TASK_BLOCKING "$RR3L")"; r=$?; printf '%s|rc=%s' "$o" "$r"; }
_rr3doubt() { _rr3x felix_exceptions_doubt "$1"; }
_rr3col8() {  # PROJ REPO -> column 8 of ob1's row in felix_obligations_run
  local o; o="$(_rr3x felix_obligations_run "$1" "$2")"
  printf '%s\n' "$o" | LC_ALL=C awk -F'\t' '$1 == "ob1" && !n++ { print $8 }'
}
_rr3judged() {  # PROJ LINE -> "refused, not honoured: the line" when the judge prints exactly that row for ob1
  local o; o="$(_rr3x felix_exceptions_judge "$1")"
  printf '%s\n' "$o" | LC_ALL=C awk -F'\t' -v w="$2" -v e="$RR3LIVE" '
    NF == 5 && $1 == "refused" && $2 == "ob1" && $3 == e && $4 == "the-founder" && $5 == "not honoured: " w { f = 1 }
    { gsub(/\t/, " | "); a = a (a == "" ? "" : " // ") $0 }
    END { if (f) print "refused, not honoured: the line"; else print "judge printed [" a "]" }'
}
# A109: the three readers under the logging git; the refs, the reflog, the config, the status and .felix around them.
_rr3snap() {
  ( export HOME="$RR3H" XDG_CONFIG_HOME="$RR3H/.config" GIT_CONFIG_NOSYSTEM=1
    git -C "$1" for-each-ref; _fx_git "$1" reflog show refs/remotes/origin/main
    git -C "$1" config --list --local; git -C "$1" status --porcelain --ignored
    LC_ALL=C od -An -c "$1/.felix" ) 2>&1
}
_rr3three() { felix_exceptions_doubt "$1"; felix_exception_for "$1" ob1 TASK_BLOCKING "$RR3L"; felix_exceptions_judge "$1"; }
_rr3net() { LC_ALL=C awk '{ for (i = 1; i <= NF; i++) if ($i == "fetch" || $i == "pull" || $i == "ls-remote" || ($i == "remote" && $(i + 1) == "update")) { print; break } }' "$1" 2>/dev/null; }
_rr3w=""; _rr3ww=""
_rr3watch() {  # LABEL PROJ REPO
  local a b v
  : > "$RR3/wrap.log"; : > "$RR3/gh.log"; a="$(_rr3snap "$3")"
  PATH="$RR3/wrap:$PATH" _rr3x _rr3three "$2" >/dev/null
  b="$(_rr3snap "$3")"
  if [ -s "$RR3/wrap.log" ]; then v=logged; else v=no-git-call-logged; fi
  v="$v net=[$(_rr3net "$RR3/wrap.log")] gh=[$(cat "$RR3/gh.log" 2>/dev/null)]"
  if [ -n "$a" ] && [ "$a" = "$b" ]; then v="$v same"; else v="$v changed"; fi
  _rr3w="$_rr3w [$1: $v]"; _rr3ww="$_rr3ww [$1: logged net=[] gh=[] same]"
}

# ---- S1: no marker, so Q is PROJ -----------------------------------------------------------------
is "B12R3 A98 (B12R3-1): at S1's baseline, x's doubt prints nothing and felix_exception_for prints nothing and exits 1 (control)" \
   "[$(_rr3doubt "$RR3S1/projects/x")] $(_rr3for "$RR3S1/projects/x")" "[] |rc=1"
is "B12R3 A99 (B12R3-1): at S1's baseline, y's merged grant is refused and its doubt is exactly DM: with no marker Q is y, not the project the URL binds" \
   "$(_rr3for "$RR3S1/projects/y") [$(_rr3doubt "$RR3S1/projects/y")]" "|rc=1 [$RR3DM]"
_rr3url "$RR3S1" "$RR3V/other/x.git"
is "B12R3 A100 (B12R3-3): under s1o, the URL at srv/other/x.git, x's doubt is exactly DM and felix_exception_for exits 1 (control)" \
   "[$(_rr3doubt "$RR3S1/projects/x")] $(_rr3for "$RR3S1/projects/x")" "[$RR3DM] |rc=1"
_rr3url "$RR3S1" "$RR3V/acme/x.git"
_rr3url "$RR3S1" "$RR3V/acme/y.git"
is "B12R3 A101 (B12R3-1, B12R3-4): under s1, the URL at srv/acme/y.git, x's forged grant is refused, its doubt is DM, the judge says so and column 8 is -" \
   "$(_rr3for "$RR3S1/projects/x") [$(_rr3doubt "$RR3S1/projects/x")] $(_rr3judged "$RR3S1/projects/x" "$RR3DM") col8=[$(_rr3col8 "$RR3S1/projects/x" "$RR3S1")]" \
   "|rc=1 [$RR3DM] refused, not honoured: the line col8=[-]"
_rr3g1="$(git -C "$RR3S1" rev-parse -q --verify refs/remotes/origin/main 2>/dev/null)"
_rr3m1="$(_rr3q "$RR3S1" reflog show -n1 --format=%gs refs/remotes/origin/main)"
if [ -n "$RR3F1" ] && [ "$_rr3g1" = "$RR3F1" ]; then
  case "$_rr3m1" in fetch*) _rr3v="forged's commit, fetched" ;; *) _rr3v="forged's commit, its newest reflog entry [$_rr3m1]" ;; esac
else _rr3v="origin/main is [$_rr3g1], forged is [$RR3F1]"; fi
is "B12R3 A102 (B12R3-6): under s1, origin/main is forged's commit with a fetch reflog entry, and felix_resolve_project S1 S1 still binds y (control)" \
   "$_rr3v|$(_rr3x felix_resolve_project "$RR3S1" "$RR3S1")" "forged's commit, fetched|$RR3S1/projects/y"
_rr3url "$RR3S1" "$RR3V/acme/x.git"

# ---- S2: the marker names felix, which declares no remote_match ----------------------------------
is "B12R3 A103 (B12R3-2): at S2's baseline, p's doubt is exactly D2(felix), the URL being the home's own" \
   "[$(_rr3doubt "$RR3S2/projects/p")]" "[$RR3D2]"
_rr3url "$RR3S2" "$RR3V2/evil/z.git"
is "B12R3 A104 (B12R3-2, B12R3-4): under s2, the URL at srv2/evil/z.git, p's forged grant is refused under both spellings with D2(felix), in the judge and column 8" \
   "$(_rr3for "$RR3S2/projects/p") $(_rr3for "$RR3SL/projects/p") [$(_rr3doubt "$RR3S2/projects/p")] [$(_rr3doubt "$RR3SL/projects/p")] $(_rr3judged "$RR3S2/projects/p" "$RR3D2") col8=[$(_rr3col8 "$RR3S2/projects/p" "$RR3S2")]" \
   "|rc=1 |rc=1 [$RR3D2] [$RR3D2] refused, not honoured: the line col8=[-]"
is "B12R3 A106 (B12R3-2): under s2, felix's own grant clears with nothing doubted, as S2/projects/felix, slink/projects/felix and S2/projects/felix/ (control)" \
   "$(_rr3for "$RR3S2/projects/felix") [$(_rr3doubt "$RR3S2/projects/felix")] $(_rr3for "$RR3SL/projects/felix") [$(_rr3doubt "$RR3SL/projects/felix")] $(_rr3for "$RR3S2/projects/felix/") [$(_rr3doubt "$RR3S2/projects/felix/")]" \
   "$RR3FOR|rc=0 [] $RR3FOR|rc=0 [] $RR3FOR|rc=0 []"
_rr3watch s2 "$RR3S2/projects/p" "$RR3S2"
_rr3url "$RR3S2" "$RR3V2/home/felix.git"
_rr3url "$RR3S2" "$RR3V2/look/acme/p.git"
is "B12R3 A105 (B12R3-2): under s2l, the URL at srv2/look/acme/p.git, p's grant is refused and its doubt is exactly D2(felix)" \
   "$(_rr3for "$RR3S2/projects/p") [$(_rr3doubt "$RR3S2/projects/p")]" "|rc=1 [$RR3D2]"
# s3: s2l, then .felix replaced in turn.
_rr3got=""; _rr3want=""
for _rr3i in gone empty dir dangling; do
  _rr3marker "$_rr3i"
  _rr3got="$_rr3got [$_rr3i: $(_rr3for "$RR3S2/projects/p") $(_rr3doubt "$RR3S2/projects/p")]"; _rr3want="$_rr3want [$_rr3i: |rc=1 $RR3D1]"
  if [ "$_rr3i" = gone ]; then _rr3watch gone "$RR3S2/projects/p" "$RR3S2"; fi
done
is "B12R3 A107 (B12R3-1): under s3, a .felix holding gone, an empty one, a directory and a dangling link each refuse p's grant with exactly D1" \
   "$_rr3got" "$_rr3want"
_rr3marker none
is "B12R3 A108 (B12R3-2): under s3 with no .felix at all, Q is p, so p's grant clears with nothing doubted: the stated limit (control)" \
   "$(_rr3for "$RR3S2/projects/p") [$(_rr3doubt "$RR3S2/projects/p")]" "$RR3FOR|rc=0 []"
_rr3marker felix; _rr3url "$RR3S2" "$RR3V2/home/felix.git"

# ---- review round (B12R3-8 to B12R3-10): no marker beside other projects, and a nested repository --
RR3D3="remote_match cannot be read: felix declares none, and this repository has no .felix marker and holds other projects"
RR3DH="remote_match cannot be read: the repository git finds for this project is not the one whose projects directory holds it"
# s4: no .felix, the URL at srv2/evil/z.git, whose main grants felix; felix declares none and p stands beside it.
_rr3marker none; _rr3url "$RR3S2" "$RR3V2/evil/z.git"
is "B12R3V A111 (B12R3-8, B12R3-10): under s4, with no marker and p beside it, felix's forged grant is refused with exactly D3(felix), in the judge and column 8" \
   "$(_rr3for "$RR3S2/projects/felix") [$(_rr3doubt "$RR3S2/projects/felix")] $(_rr3judged "$RR3S2/projects/felix" "$RR3D3") col8=[$(_rr3col8 "$RR3S2/projects/felix" "$RR3S2")]" \
   "|rc=1 [$RR3D3] refused, not honoured: the line col8=[-]"
_rr3n="B12R3V A112 (B12R3-8): under s4 with p moved out of the working tree, felix is the only project, so its grant clears with nothing doubted: the stated limit (control)"
if mv "$RR3S2/projects/p" "$RR3/p.away" 2>/dev/null; then
  is "$_rr3n" "$(_rr3for "$RR3S2/projects/felix") [$(_rr3doubt "$RR3S2/projects/felix")]" "$RR3FOR|rc=0 []"
  mv "$RR3/p.away" "$RR3S2/projects/p"
else bad "$_rr3n" "p could not be moved out of S2/projects"; fi
_rr3marker felix; _rr3url "$RR3S2" "$RR3V2/home/felix.git"
# s5: a repository nested at S2/projects; its origin is a copy whose path ends in acme/p and whose main adds p's grant.
RR3N="$RR3S2/projects"
mkdir -p "$RR3V2/nest/acme"; _rr3g "$RR3V2/nest/acme" init -q --bare -b main p.git
_rr3g "$RR3N" init -q -b main; _rr3ci "$RR3N" 'a repository nested at projects/, its tree as the home has it'
_rr3g "$RR3N" checkout -q -b forged; printf '%s\n' "$RR3ROW" >> "$RR3N/p/exceptions.tsv"
_rr3ci "$RR3N" "p's grant, in the nested repository"
_rr3g "$RR3N" push -q "$RR3V2/nest/acme/p.git" forged:main; _rr3g "$RR3N" checkout -q main
_rr3g "$RR3N" config remote.origin.url "$RR3V2/nest/acme/p.git"; _rr3g "$RR3N" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
_rr3g "$RR3N" fetch -q
RR3NF="$(git -C "$RR3N" rev-parse -q --verify refs/heads/forged 2>/dev/null)"
_rr3g1="$(git -C "$RR3N" rev-parse -q --verify refs/remotes/origin/main 2>/dev/null)"
_rr3m1="$(_rr3q "$RR3N" reflog show -n1 --format=%gs refs/remotes/origin/main)"
_rr3v="origin/main is [$_rr3g1], forged is [$RR3NF]"
if [ -n "$RR3NF" ] && [ "$_rr3g1" = "$RR3NF" ]; then _rr3v="forged's commit"; fi
_rr3c="its newest reflog entry [$_rr3m1]"
case "$_rr3m1" in fetch*) _rr3c="fetched" ;; esac
_rr3i="$(_rr3q "$RR3N" show refs/remotes/origin/main:p/exceptions.tsv | LC_ALL=C awk -v r="$RR3ROW" '$0 == r { n++ } END { print n + 0 }')"
is "B12R3V A113 (B12R3-9): under s5, git finds S2/projects for p, and the nested origin/main is forged's commit, fetched, holding p's grant once (control, the fixture)" \
   "top=[$(git -C "$RR3N/p" rev-parse --show-toplevel 2>/dev/null)] $_rr3v, $_rr3c, rows=$_rr3i" "top=[$RR3N] forged's commit, fetched, rows=1"
is "B12R3V A114 (B12R3-9, B12R3-10): under s5, p's grant from the nested repository is refused under both spellings with exactly DH, in the judge and column 8" \
   "$(_rr3for "$RR3N/p") $(_rr3for "$RR3SL/projects/p") [$(_rr3doubt "$RR3N/p")] [$(_rr3doubt "$RR3SL/projects/p")] $(_rr3judged "$RR3N/p" "$RR3DH") col8=[$(_rr3col8 "$RR3N/p" "$RR3N")]" \
   "|rc=1 |rc=1 [$RR3DH] [$RR3DH] refused, not honoured: the line col8=[-]"
rm -rf "$RR3N/.git"
is "B12R3V A115 (B12R3-9): with the nested repository removed, p's doubt is exactly D2(felix) again and felix_exception_for exits 1 (control)" \
   "$(_rr3for "$RR3S2/projects/p") [$(_rr3doubt "$RR3S2/projects/p")]" "|rc=1 [$RR3D2]"

# ---- B12R3-7: what lib/exceptions.sh's comments say ---------------------------------------------
RR3EX="$FROOT/harness/lib/exceptions.sh"
_rr3cmt() {  # head|doubt|mf -> the head's comment text, the doubt's comment block, or the comment lines holding marker first
  LC_ALL=C awk -v mode="$1" '
    function txt(s) { sub(/^[ \t]+/, "", s); sub(/^#+/, "", s); gsub(/[ \t]+/, " ", s); return s }
    { t = $0; sub(/^[ \t]+/, "", t); c = (substr(t, 1, 1) == "#") }
    mode == "head" && !stop { if (t == "") next; if (c) { out = out " " txt($0); next }; stop = 1 }
    mode == "doubt" && !found { if (index(t, "felix_exceptions_doubt() {") == 1) { found = 1; out = run }
                                else if (c) run = run " " txt($0); else run = "" }
    mode == "mf" && c && index(txt($0), "marker first") { n++ }
    END { if (mode == "mf") print n + 0; else if (mode == "doubt" && !found) print "NO-DEFINITION"; else print out }
  ' "$RR3EX" 2>/dev/null | LC_ALL=C tr -s ' '
}
_rr3v=""
if [ -f "$RR3EX" ]; then
  _rr3c="$(_rr3cmt head)"
  case "$_rr3c" in *'.felix marker'*) ;; *) _rr3v="$_rr3v [the head lacks .felix marker]" ;; esac
  _rr3c="$(_rr3cmt doubt)"
  if [ "$_rr3c" = NO-DEFINITION ]; then _rr3v="$_rr3v [no line begins felix_exceptions_doubt() {]"
  else
    for _rr3i in '.felix marker' 'never the project the origin URL binds' 'circular' 'with no marker'; do
      case "$_rr3c" in *"$_rr3i"*) ;; *) _rr3v="$_rr3v [the doubt's block lacks $_rr3i]" ;; esac
    done
  fi
  _rr3c="$(_rr3cmt mf)"
  [ "$_rr3c" = 0 ] || _rr3v="$_rr3v [$_rr3c comment line(s) hold marker first]"
else _rr3v=" [no lib/exceptions.sh at $RR3EX]"; fi
is "B12R3 A110 (B12R3-7): the head and the doubt's comment block name the .felix marker, never the origin's project, the circle and the no-marker case; no comment says marker first" \
   "[${_rr3v# }]" "[]"
_rr3v=""
if [ -f "$RR3EX" ]; then
  _rr3c="$(_rr3cmt doubt)"
  for _rr3i in 'nested repository' 'the only project'; do
    case "$_rr3c" in *"$_rr3i"*) ;; *) _rr3v="$_rr3v [the doubt's block lacks $_rr3i]" ;; esac
  done
else _rr3v=" [no lib/exceptions.sh at $RR3EX]"; fi
is "B12R3V A116 (B12R3-11): the doubt's comment block names the nested repository and the only project" "[${_rr3v# }]" "[]"

# ---- B12R3-5: read only, last, so the memory root has seen every call of this part --------------
is "B12R3 A109 (B12R3-5): under s2 and under the gone marker the readers run no fetch and no gh and change no ref, reflog, config, status or .felix, and the memory root holds no file (control)" \
   "$_rr3w [memory: $(find "$RR3M" -type f 2>&1)]" "$_rr3ww [memory: ]"
