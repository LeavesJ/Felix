printf '\nthe engine makes its scratch under TMPDIR\n'
# Measured 2026-09-24 on macOS 26.3.1: a bare `mktemp` or `mktemp -d` makes its
# file in the per-user /var/folders/.../T whatever TMPDIR says (set, unset, or
# naming a missing directory), while a template under TMPDIR, or -p, honours
# it. GNU mktemp on the Linux runner honours TMPDIR either way. So on a Mac a
# block that points TMPDIR at a fixture and counts what is left there read 0
# for any engine path with a bare mktemp, whether or not that path cleaned up.
# Thirteen such calls sat in felix and six libraries, and one in Felix's gate.
#
# The class, read from the text, since most of those paths (merge, discover,
# the gate's installed check) no fixture here drives cheaply. A call spelled
# some other way than $(mktemp ...) or `mktemp ...` is not seen by it. The
# drive below shows the reading matches what runs. Read from this harness and
# not from a checkout root, so a copy with no checkout around it still has
# its own text read rather than none; the gate is read where there is one.
_mkt_read=0
_mkt_bare="$(for f in "$REAL_HARNESS/felix" "$REAL_HARNESS"/lib/*.sh "$REAL_HARNESS"/bin/* "$REAL_HARNESS"/hooks/* \
               "$REAL_HARNESS/../../projects/felix/gate.sh"; do
               [ -f "$f" ] && grep -nE '\$\(mktemp|`mktemp' "$f" | sed "s|^|${f#"$REAL_HARNESS"/}:|"
             done | grep -vE '^[^:]*:[0-9]+:[[:space:]]*#' | grep -v 'XXXXXX')"
grep -q 'mktemp' "$REAL_HARNESS/felix" && _mkt_read=1
is "every mktemp the engine and Felix's gate run is given a template, so none lands outside TMPDIR on a Mac" \
   "$_mkt_read $_mkt_bare" "1 "

# Driven: a mktemp first on PATH that writes down what it was given and hands
# on to the real one, around the four paths a fixture reaches cheaply. Each
# must name a template under the TMPDIR it was given, and nothing may be left
# there after. The second half is the count that could not fail on a Mac while
# the first half did not hold. Measured with a copy of pulse.sh that keeps its
# scratch index: this count read 1 with the templates and 0 with the bare
# calls, whose index went to /var/folders instead.
MKT="$TMP/mktemp-drive"; mkdir -p "$MKT/bin" "$MKT/tmp" "$MKT/proj" "$MKT/repo" "$MKT/nohandoff"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s"\nexec "%s" "$@"\n' "$MKT/calls" "$(command -v mktemp)" > "$MKT/bin/mktemp"
chmod +x "$MKT/bin/mktemp"; : > "$MKT/calls"
printf '{\n  "name": "x",\n  "version": "1.2.3"\n}\n' > "$MKT/plugin.json"
printf 'web\tendpoint handler\tbackend\tplaywright\n' > "$MKT/proj/routes.tsv"
( _fx_cd "$MKT/repo" && git init -q -b main && : > f && git add f \
  && git -c user.name=t -c user.email=t@t commit -qm s ) >/dev/null 2>&1
( PATH="$MKT/bin:$PATH"; export TMPDIR="$MKT/tmp"
  . "$FROOT/harness/lib/resolve.sh"; felix_version_bump "$MKT/plugin.json"
  . "$FROOT/harness/lib/route.sh";   felix_route_append_play "$MKT/proj" web deepeval
  . "$FROOT/harness/lib/pulse.sh";   _felix_pulse_new_gitlinks "$MKT/repo"
  . "$FROOT/harness/lib/handoff.sh"; felix_handoff_rotate "$MKT/nohandoff" ) >/dev/null 2>&1
is "each engine mktemp driven here names a template under the TMPDIR it was given" \
   "$(awk -v t="$MKT/tmp/" '{ n = $NF; if (index(n, t) == 1 && n ~ /\.XXXXXX$/) { sub(/^.*\//, "", n); sub(/\.XXXXXX$/, "", n); printf "%s ", n } else printf "[%s] ", $0 }' "$MKT/calls")" \
   "felix-bump felix-routes felix-pulse felix-handoff "
is "and none of them leaves anything there" "$(ls -A "$MKT/tmp" | wc -l | tr -d ' ')" "0"
is "and each did its work: the version bumped and the tool wired in" \
   "$(grep -o '"version": "[^"]*"' "$MKT/plugin.json") $(cut -f4 "$MKT/proj/routes.tsv")" '"version": "1.2.4" playwright deepeval'

