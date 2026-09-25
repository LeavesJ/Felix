#!/usr/bin/env bash
# The public snapshot, as a command.
#
#   projects/felix/snapshot.sh [--source REF] [--base REF] [--public-readme]
#                              [--out DIR] [--public-clone DIR]
#                              [--message FILE] [--expect-tree TREE] [--name NAME]...
#
# The engine is published as LeavesJ/Felix, a snapshot with no history of its
# own, because this repository's history carries material that is not Felix's
# to publish (HANDOFF §0). The snapshot was made by hand three times and its
# rule lived in nobody's hands, which is how it fell twenty-two pull requests
# behind while the maintenance table read "Nothing due". The rule is this file
# now. HANDOFF §0bm has the derivation; the self-test below is its proof.
#
# In order, and never more: build the published set out of a commit with git
# archive, withhold consent, rewrite what names another project, audit the
# result with rules that share nothing with the rewrite, stage it onto a fresh
# clone of the public repository on a new branch, commit as the public author,
# run the suite and the credential scan on that exact commit, and print the push
# and pull request commands. It never pushes. The public main takes a merged
# pull request and nothing else, and a deny row refuses the push a session
# would otherwise try.
#
# Self-test. Each hand-made snapshot is reproduced byte for byte, compared by
# tree id, with the public README kept as it was then; it never commits, and it
# reports the audit and still compares when the audit would stop:
#   --source a3eee3c --base f6341ba --public-readme --expect-tree f5a4d6f
#   --source a8ab281 --base 3091a76 --public-readme --expect-tree 5455d56
#
# Published itself, with its scrub and audit (snapshot-scrub.sh and
# snapshot-audit.sh), deliberately. None names another project: every name is
# derived at run time (main's history, the folders under projects/, the memory
# root, the manifests' remotes, the login, each --name), and the only literals,
# the public repository and author, are public. Every run audits all three with
# the rest of projects/felix/. They show a stranger what is withheld and why;
# withholding them would hide the method and not one name. What would reverse
# this: a literal here that the audit has to be told to ignore.
set -euo pipefail
# Bytes, in every locale, here and in the credential scan that inherits it: under
# UTF-8 the platform grep matched nothing after an invalid byte on a line.
export LC_ALL=C

PUBLIC_SLUG="LeavesJ/Felix"
PUBLIC_URL="https://github.com/$PUBLIC_SLUG.git"
AUTHOR_NAME="Jarron Deng"
AUTHOR_EMAIL="jarrondeng@gmail.com"
ORD=(another third fourth fifth sixth seventh eighth ninth tenth)
TAB="$(printf '\t')"

die() { printf 'snapshot: %s\n' "$1" >&2; shift; while [ $# -gt 0 ]; do printf '  %s\n' "$1" >&2; shift; done; exit 1; }
say() { printf '%s\n' "$*"; }
lc() { tr '[:upper:]' '[:lower:]'; }

HERE="$(cd "$(dirname "$0")" && pwd)"
SELF="$(basename "$HERE")"
SRC_REF="origin/main" BASE_REF="" PUBLIC_README=0 OUT="" PCLONE="" EXPECT="" MSGFILE=""
GIVEN=()
while [ $# -gt 0 ]; do
  case "$1" in
    --source|--base|--out|--public-clone|--message|--expect-tree|--name)
      [ $# -ge 2 ] && [ -n "$2" ] || die "$1 needs a value"
      case "$1" in
        --source) SRC_REF=$2 ;; --base) BASE_REF=$2 ;; --out) OUT=$2 ;;
        --public-clone) PCLONE=$2 ;; --message) MSGFILE=$2 ;;
        --expect-tree) EXPECT=$2 ;; --name) GIVEN+=("$2") ;;
      esac; shift 2 ;;
    --public-readme) PUBLIC_README=1; shift ;;
    -h|--help) sed -n '4,6p' "$0"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
say "scope: accidents of our own authoring; deliberate obfuscation (leetspeak, encodings, look-alike characters) is not searched for, so a pass is not a claim about an adversary"
[ -z "$MSGFILE" ] || [ -f "$MSGFILE" ] || die "no message file at $MSGFILE"
[ -z "$PCLONE" ] || git -C "$PCLONE" rev-parse --git-dir >/dev/null 2>&1 || die "$PCLONE is not a git repository"

# ------------------------------------------------------------- source ------
# The source is always a commit. git archive reads a commit and never a working
# tree, so a dirty checkout cannot leak into the build and is not refused. What
# is refused is a commit main never accepted: a snapshot of a branch would
# publish work no gate passed on main.
HOME_TOP="$(git -C "$HERE" rev-parse --show-toplevel)"
git -C "$HOME_TOP" fetch -q origin main || die "could not fetch the home's main, so nothing here can say what main is"
MAIN="$(git -C "$HOME_TOP" rev-parse --verify origin/main)"
# The token order and the audit's history source read main's whole history; a
# shallow clone would hand the tokens out in another order and drop names.
[ "$(git -C "$HOME_TOP" rev-parse --is-shallow-repository)" = false ] || die "the home is a shallow clone, and the token order needs main's whole history" "run: git -C $HOME_TOP fetch --unshallow origin"
SRC="$(git -C "$HOME_TOP" rev-parse --verify -q "$SRC_REF^{commit}")" || die "no commit named $SRC_REF"
git -C "$HOME_TOP" merge-base --is-ancestor "$SRC" "$MAIN" || die "$SRC_REF is not on the home's main ($MAIN)" "a snapshot publishes what main accepted, and nothing else"
# The home's own slug, read and never typed: it is the one remote this file may
# know, and the public copy of this file must refuse to run as if it were home.
slug_of() { sed -n 's/.*"remote_match"[^"]*"\([^"]*\)".*/\1/p' | head -1; }
HOME_SLUG="$(git -C "$HOME_TOP" show "$MAIN:projects/$SELF/project.json" | slug_of)"
[ -n "$HOME_SLUG" ] && [ "$HOME_SLUG" != "$PUBLIC_SLUG" ] || die "this is not the home (remote_match reads '${HOME_SLUG}')" "run it from the private checkout, never from the published copy"

if [ -z "$OUT" ]; then OUT="$(mktemp -d "${TMPDIR:-/tmp}/felix-snapshot.XXXXXX")"
else [ ! -e "$OUT" ] || [ -z "$(ls -A "$OUT")" ] || die "$OUT is not empty"; mkdir -p "$OUT"; fi
OUT="$(cd "$OUT" && pwd)"
RAW="$OUT/raw" B="$OUT/build" CLONE="$OUT/clone" V="$OUT/verify"
# The acknowledgements, as main holds them and never as a checkout does.
ACKS="$OUT/acks.tsv"
if git -C "$HOME_TOP" cat-file -e "$MAIN:.snapshot-ack.tsv" 2>/dev/null; then git -C "$HOME_TOP" show "$MAIN:.snapshot-ack.tsv" > "$ACKS"
else : > "$ACKS"; fi

# ------------------------------------------------------------- names -------
# Two sets, and that is the first snapshot's lesson: its scrub matched two
# spellings and searches found three more, so the set searched for is wider.
#
# SCRUB: every project that ever declared a manifest on the source's history,
# in the order each landed on main's first-parent line, oldest first. The order
# hands out the tokens (another, third, ...); a retired project keeps its place,
# since renumbering rewrites public text. A commit's own time is not that order:
# a branch committed early and merged late would shift every later token.
git -C "$HOME_TOP" log --first-parent -m --diff-filter=A --reverse --format= --name-only "$SRC" -- 'projects/*/project.json' |
  awk -F/ -v self="$SELF" '/^projects\/[^\/]+\/project\.json$/ && $2 != self && !seen[$2]++ { print $2 }' > "$OUT/scrub.order" ||
  die "could not read the order the manifests landed on main"
SCRUB=()
while IFS= read -r n; do SCRUB+=("$n"); done < "$OUT/scrub.order"
[ ${#SCRUB[@]} -le ${#ORD[@]} ] || die "more projects than tokens; extend ORD before publishing"

# AUDIT: wider than SCRUB, and never narrowed by what a checkout on this disk
# happens to hold: a clone without an untracked project folder once dropped
# two names without a word. It is the union of six sources, each counted, and
# a source that cannot be read stops the run:
#   history  every name projects/ has held in any commit on the home's main
#   disk     every folder under projects/, tracked or not, in every worktree
#            of this home and in the home the engine points at (FELIX_HOME or
#            ~/.felix-home): an untracked stub named by no other source went out
#            verbatim, and again from a session's worktree, which holds none
#   memory   every directory of the memory root
#   remotes  every remote_match a manifest on main has declared: whole, without
#            separators, and by its components of six or more characters
#   given    each --name
#   machine  this login and the last part of $HOME, for a private path
# less this project's own names. A reviewed row of .snapshot-ack.tsv
# (@name<TAB>name<TAB>why) takes a name out of the memory source and no other:
# the engine's exercises leave directories there named in its own vocabulary,
# and a row that waived the name everywhere would leave it unsearched the day a
# project of that name lands on main, on disk or is given with --name.
remote_forms() {
  sed 's|.*/||; s|\.git$||' | lc |
    awk -F'[-_. ]' 'NF { print; s = $0; gsub(/[-_. ]/, "", s); print s
                         for (i = 1; i <= NF; i++) if (length($i) >= 6) print $i }'
}
norm() { lc | tr -cd 'a-z0-9\n'; }
MEM="${FELIX_MEMORY:-$HOME/.felix/memory}"
[ -d "$MEM/$SELF" ] || die "no $SELF directory in the memory root $MEM, so the audit's memory source cannot be read" "point FELIX_MEMORY at the memory root"
NM="$OUT/names"
git -C "$HOME_TOP" log --full-history --format= --name-only "$MAIN" -- projects/ | awk -F/ 'NF > 2 { print $2 }' | sort -u > "$NM.history" ||
  die "could not read the history of projects/ on the home's main"
PTR="${FELIX_HOME:-}" PF="$HOME/.felix-home"  # the engine's own order, lib/resolve.sh felix_home
[ -n "$PTR" ] || [ ! -f "$PF" ] || PTR="$(tr -d '[:space:]' < "$PF")" || die "could not read the home pointer $PF"
[ -z "$PTR" ] || [ -d "$PTR/projects" ] || die "the home the engine points at, $PTR, has no projects/ to read"
{ printf '%s\n' "$HOME_TOP" ${PTR:+"$PTR"}; git -C "$HOME_TOP" worktree list --porcelain | sed -n 's/^worktree //p'; } | sort -u | while IFS= read -r d; do
  [ ! -d "$d/projects" ] || (cd "$d/projects" && find . -mindepth 1 -maxdepth 1 -type d | sed 's|^\./||'); done | sort -u > "$NM.disk" || die "could not list the folders under projects/"
(cd "$MEM" && find . -mindepth 1 -maxdepth 1 -type d | sed 's|^\./||' | sort -u) > "$NM.memory" || die "could not list the memory root $MEM"
git -C "$HOME_TOP" log --full-history -p --format= "$MAIN" -- 'projects/*/project.json' |
  sed -n 's/^[-+].*"remote_match"[^"]*"\([^"]*\)".*/\1/p' | remote_forms | sort -u > "$NM.remotes" ||
  die "could not read the remotes the manifests on the home's main declared"
for f in history disk memory remotes; do [ -s "$NM.$f" ] || die "the audit's $f source came back empty, and it never is"; done
printf '%s\n' ${GIVEN[@]+"${GIVEN[@]}"} | sed '/^$/d' | sort -u > "$NM.given"
{ id -un && basename "$HOME"; } | sort -u > "$NM.machine" || die "could not read this machine's login"
{ printf '%s\n' "$SELF" "${PUBLIC_SLUG##*/}"; printf '%s\n' "$HOME_SLUG" | remote_forms; } | norm | sort -u > "$NM.self"
awk -F'\t' '$1 == "@name" && NF >= 3 { print $2 }' "$ACKS" | norm | sort -u > "$NM.excluded"
drop() {  # FILE of normalized names; on stdin names; prints those it does not hold
  awk 'FILENAME == ARGV[1] { d[$0] = 1; next } { m = tolower($0); gsub(/[^a-z0-9]/, "", m); if (m != "" && !(m in d)) print }' "$1" -
}
drop "$NM.excluded" < "$NM.memory" > "$NM.memory.kept"
sort -u "$NM.history" "$NM.disk" "$NM.memory.kept" "$NM.remotes" "$NM.given" "$NM.machine" | sed '/^$/d' > "$NM.union"
drop "$NM.self" < "$NM.union" > "$NM.audit"
short="$(awk '{ m = tolower($0); gsub(/[^a-z0-9]/, "", m); if (length(m) < 3) print }' "$NM.audit")"
[ -z "$short" ] || die "audit names too short to search for; exclude each with a reviewed @name row, or rename:" $short
AUDIT=()
while IFS= read -r n; do AUDIT+=("$n"); done < "$NM.audit"
[ ${#AUDIT[@]} -gt 0 ] || die "no audit names are left, so the audit would search for nothing"
cnt() { wc -l < "$1" | tr -d ' '; }
say "names: ${#AUDIT[@]} searched for; history $(cnt "$NM.history"), disk $(cnt "$NM.disk"), memory $(cnt "$NM.memory"), remotes $(cnt "$NM.remotes"), given $(cnt "$NM.given"), machine $(cnt "$NM.machine"); $(($(cnt "$NM.memory") - $(cnt "$NM.memory.kept"))) of memory's excluded by a reviewed row; less $(($(cnt "$NM.union") - ${#AUDIT[@]})) of this project's own"

# The audit is its own file, snapshot-audit.sh beside this one, and shares no
# pattern with the scrub below; its header says what it looks for. scan DIR
# LIST OUT writes path<TAB>line<TAB>name<TAB>rule<TAB>hash for every line of
# LIST's files (NUL-separated, relative to DIR) that it reaches. A file it
# cannot read stops the run: an empty answer is never taken for a pass.
printf '%s\n' "${AUDIT[@]}" > "$NM.searched"
scan() { bash "$HERE/snapshot-audit.sh" "$NM.searched" "$AUTHOR_EMAIL" "$1" "$HOME_SLUG" < "$2" > "$3" || die "the audit could not read every file under $1"; }
# It reads every file of the build, whatever grep would call binary: a name in
# a file holding one NUL byte once went out unread by the scrub and the audit.
# A symbolic link is listed with the files, and what it reads is its target.
lsfiles() { (cd "$1" && find . \( -type f -o -type l \) | sed 's|^\./||' | sort); }
allfiles() { lsfiles "$1" | tr '\n' '\0'; }
# Hits no acknowledgement covers. An acknowledgement waives a leak check, so it
# is authority, not state: a row of .snapshot-ack.tsv at the home's root, tracked
# and reviewed in a pull request, read as main holds it (an unmerged row waives
# nothing), and withheld, since it names what is searched for. A row is path,
# the line's hash and why; editing the line voids it. Nothing here writes that
# file; it prints the row a person could add.
unacked() { awk -F'\t' 'FILENAME == ARGV[1] { if ($1 !~ /^[#@]/ && NF >= 3) ok[$1 FS $2] = 1; next } !(($1 FS $5) in ok)' "$ACKS" "$1"; }
show_hits() {  # DIR HITS: each line, and the row that would acknowledge it
  local p l n r h t
  head -40 "$2" | while IFS="$TAB" read -r p l n r h; do
    if [ "$l" = 0 ]; then t="(the file's path)"; elif [ -L "$1/$p" ]; then t="(a link to) $(readlink "$1/$p")"; else t="$(sed -n "${l}p" "$1/$p" | cut -c1-160 | tr -d '\n' | tr -c '[:print:]\t' '?')"; fi
    printf '  %s:%s [%s, %s] %s\n' "$p" "$l" "$n" "$r" "$t"
    printf '      ack: %s\\t%s\\t<why>\n' "$p" "$h"
  done
  [ "$(wc -l < "$2")" -le 40 ] || say "  and $(($(wc -l < "$2") - 40)) more, in $2"
}

# ------------------------------------------------------------- build -------
# The published set, out of the commit; the consent files left out by pathspec.
# assets/ holds the README's images (2026-09-23): the README is published, so
# what it shows must be too, or the public page renders broken images.
PUB=""
for p in engine "projects/$SELF" .gitignore .claude-plugin/marketplace.json assets; do
  if git -C "$HOME_TOP" cat-file -e "$SRC:$p" 2>/dev/null; then PUB="$PUB $p"; fi
done
[ "$PUBLIC_README" -eq 1 ] || PUB="$PUB README.md"
archive_to() {
  mkdir -p "$1"
  # shellcheck disable=SC2086
  git -C "$HOME_TOP" archive "$SRC" -- $PUB ":(exclude)projects/$SELF/autonomy" ":(exclude)projects/$SELF/autonomy.commission" | tar -x -C "$1"
}
archive_to "$RAW"; archive_to "$B"
# The raw tree is the commit's bytes and nothing else. git archive obeys the
# source's .gitattributes, withheld or not: export-subst wrote the home's commit
# id into a published file, and export-ignore drops one without a word.
git -C "$HOME_TOP" ls-tree -r -z "$SRC" -- $PUB > "$OUT/tree.src" || die "could not list the source commit's tree"
X="projects/$SELF/autonomy" D="$RAW" N="$(lsfiles "$RAW" | wc -l | tr -d ' ')" perl -0 -MDigest::SHA=sha1_hex -ne 'chomp;
  my ($t, $h, $p) = /^\d+ (\w+) (\w+)\t(.*)$/s or die "ls-tree: $_\n"; next if $p eq $ENV{X} || $p eq "$ENV{X}.commission"; $n++;
  my ($f, $c, $fh) = ("$ENV{D}/$p"); if (-l $f) { $c = readlink $f } elsif (open $fh, "<:raw", $f) { local $/; $c = <$fh> // "" }
  print "$p\n" unless $t eq "blob" && defined $c && sha1_hex("blob " . length($c) . "\0" . $c) eq $h;
  END { print "($n in the commit, $ENV{N} built)\n" if $n != $ENV{N} }' "$OUT/tree.src" > "$OUT/raw.differs" || die "could not hold the build to the commit's blobs"
[ ! -s "$OUT/raw.differs" ] || die "the build is not the commit's bytes; an export rule in .gitattributes or a filter changed:" "$(head -5 "$OUT/raw.differs")"

# Consent. The exception table ships only while it is the empty seed: a row in
# it is a person's grant, and a grant is not published. Named, and stopped.
EX="$B/projects/$SELF/exceptions.tsv" TPL="$B/engine/harness/templates/exceptions.tsv"
if [ -e "$EX" ]; then
  [ -e "$TPL" ] || die "projects/$SELF/exceptions.tsv ships with no template to judge it against"
  cmp -s "$EX" "$TPL" || die "projects/$SELF/exceptions.tsv holds what the template does not; a grant is a person's consent" \
    "$(diff "$TPL" "$EX" | sed -n 's/^> //p' | head -5)"
fi

# The remote, at the field. The home's slug also names the pointer file and a
# suite fixture, and a global rewrite of it breaks the engine.
perl -0pi -e 's/("remote_match"\s*:\s*")[^"]*(")/${1}LeavesJ\/Felix${2}/' "$B/projects/$SELF/project.json"
[ "$(slug_of < "$B/projects/$SELF/project.json")" = "$PUBLIC_SLUG" ] || die "remote_match was not rewritten"

# The scrub is its own file, snapshot-scrub.sh beside this one, whose header
# says what each name becomes and why. It is handed the projects in token order,
# each with every owner/repo its manifest on main has declared, and the text
# files, and rewrites them in place; what follows checks it.
: > "$OUT/scrub.plan"; i=0
for n in ${SCRUB[@]+"${SCRUB[@]}"}; do
  tok=${ORD[$i]}; i=$((i + 1))
  if [ "$tok" = another ]; then PH="another governed project"; else PH="a $tok governed project"; fi
  rm="$(git -C "$HOME_TOP" log --full-history -p --format= "$MAIN" -- "projects/$n/project.json" | sed -n 's/^[-+].*"remote_match"[^"]*"\([^"]*\)".*/\1/p' |
    sed 's|\.git$||; s|^.*[:/]\([^/:][^/:]*/[^/:][^/:]*\)$|\1|' | sort -u | tr '\n' ' ')" || die "could not read the remotes projects/$n declared on main"
  printf '%s\t%s\t%s\t%s\n' "$n" "$tok" "$PH" "$rm" >> "$OUT/scrub.plan"
done
find "$B" -type f -print0 | xargs -0 grep -lI --null '' > "$OUT/text.files" || true
bash "$HERE/snapshot-scrub.sh" "$OUT/scrub.plan" "$OUT/text.files" || die "the scrub failed"
# Shell that parsed before the scrub parses after it, or nothing goes out. A
# case pattern naming a project stops here, the phrase in place of the word;
# the lead accepted that as fail-closed on 2026-09-22, and a person rewrites it.
while IFS= read -r -d '' f; do
  r="$RAW/${f#"$B"/}"
  cmp -s "$r" "$f" && continue
  case "$f" in *.sh) ;; *) case "$(head -c 64 "$f")" in '#!'*sh*) ;; *) continue ;; esac ;; esac
  if bash -n "$r" 2>/dev/null && ! bash -n "$f" 2> "$OUT/bash-n.err"; then
    die "the scrub turned shell that parsed into shell that does not: ${f#"$B"/}" "$(head -3 "$OUT/bash-n.err")"
  fi
done < "$OUT/text.files"

# ------------------------------------------------------------- audit -------
# Separate code from everything above, sharing none of its patterns.
#
# First, what the scrub touched. Every line it changed must be a line the
# audit reads a name on in the unscrubbed tree, and no file may change length.
# A scrub that rewrote anything else mangled text that was not a name, and
# nothing downstream would say so.
lsfiles "$RAW" > "$OUT/files.raw"; lsfiles "$B" > "$OUT/files.build"
cmp -s "$OUT/files.raw" "$OUT/files.build" || die "the scrub added or removed a file"
: > "$OUT/changed"
while IFS= read -r f; do
  if [ -L "$RAW/$f" ] || [ -L "$B/$f" ]; then
    [ "$(readlink "$RAW/$f")" = "$(readlink "$B/$f")" ] || die "the scrub changed the symbolic link $f"; continue
  fi
  cmp -s "$RAW/$f" "$B/$f" && continue
  [ "$(wc -l < "$RAW/$f")" -eq "$(wc -l < "$B/$f")" ] || die "the scrub changed the line count of $f"
  awk -v f="$f" 'NR == FNR { a[FNR] = $0; next } a[FNR] != $0 { print f "\t" FNR }' "$RAW/$f" "$B/$f" >> "$OUT/changed"
done < "$OUT/files.raw"
RM_LINE="projects/$SELF/project.json$TAB$(grep -n '"remote_match"' "$RAW/projects/$SELF/project.json" | cut -d: -f1)"
allfiles "$RAW" > "$OUT/list.raw"; scan "$RAW" "$OUT/list.raw" "$OUT/scan.raw"
awk -F'\t' '$4 != "address" && $4 != "repository" { print $1 FS $2 }' "$OUT/scan.raw" | sort -u > "$OUT/flagged.raw"
stray="$(grep -vxF "$RM_LINE" "$OUT/changed" | sort -u | comm -23 - "$OUT/flagged.raw" || true)"
[ -z "$stray" ] || die "the scrub changed lines the audit reads no name on:" "$(printf '%s\n' "$stray" | tr '\t' ':')"
diff -ru --no-dereference "$RAW" "$B" > "$OUT/scrub.diff" || true
# And no changed line holds the phrase against a path or identifier character
# (an escape such as \n before it is a space, as it is to the scrub).
glued="$(BUILD="$B" perl -ne 'chomp; my ($f, $l) = split /\t/; open(my $h, "<", "$ENV{BUILD}/$f") or die "$f: $!\n"; my $x;
  while (<$h>) { if ($. == $l) { $x = $_; last } } $x =~ s/\\[ntr]/ /g; print "$f:$l\n" if $x =~ m{[[:alnum:]_/\$\{-](another|a [a-z]+) governed project|governed project[[:alnum:]_/\}-]}' "$OUT/changed")" ||
  die "could not read back what the scrub changed"
[ -z "$glued" ] || die "the scrub put the phrase inside a path or an identifier:" $glued
# Nor, in a shell file, in its code: outside a comment and a quoted string.
# bash -n passed `[ "$p" = a third governed project ]` and a for list grown by
# three words, which fail or do something else when run. A variable named after
# a project the scrub renames whole; any other bare name in code stops here for
# a person, as does one in a heredoc, which this reads as code (fail-closed).
incode="$(BUILD="$B" perl -ne 'chomp; my ($f, $l) = split /\t/; open(my $h, "<", "$ENV{BUILD}/$f") or die "$f: $!\n"; my @x = <$h>;
  next unless $f =~ /\.sh$/ || (@x && substr($x[0], 0, 64) =~ /^#!.*sh/); my ($s, $c, $q) = ($x[$l - 1], "", "");
  for (my $i = 0; $i < length $s; $i++) { my $ch = substr($s, $i, 1);
    if ($q eq "\x27") { $q = "" if $ch eq "\x27"; next } if ($ch eq "\\") { $i++; next } if ($q) { $q = "" if $ch eq $q; next }
    if ($ch eq "\x27" || $ch eq "\"") { $q = $ch; next } last if $ch eq "#" && ($c eq "" || $c =~ /\s$/); $c .= $ch }
  print "$f:$l\n" if $c =~ /(another|a [a-z]+) governed project/' "$OUT/changed")" || die "could not read back what the scrub changed"
[ -z "$incode" ] || die "the scrub put the phrase into shell code, outside a comment or a quoted string:" $incode
# And nothing of a private remote is left beside what the scrub put in: its
# owner before the token, or the leading words of its repository's name before
# it (two words of a three-word repository name went out once, the third made a
# token), on a changed line or across the break before one. A remote is
# rewritten whole or the run stops.
part="$(BUILD="$B" PLAN="$OUT/scrub.plan" perl -ne 'BEGIN { open(my $p, "<", $ENV{PLAN}) or die "plan: $!\n"; while (<$p>) { chomp; my (undef, $t, undef, $rm) = split /\t/;
    for (split " ", $rm // "") { my ($w, $r) = m{^(?:(.*)/)?([^/]+)$} or next; my @c = grep { length } split /[-_. ]+/, lc $r; my $k = "[^a-z0-9]*(?:a[^a-z0-9]+)?\Q$t\E(?![a-z0-9])";
      push @R, qr/(?<![a-z0-9])\Q@{[lc $w]}\E$k/ if defined $w && length $w; push @R, qr/(?<![a-z0-9])@{[join "[^a-z0-9]*", map { quotemeta } @c[0 .. $#c - 1]]}$k/ if @c > 1 } } }
  chomp; my ($f, $l) = split /\t/; open(my $h, "<", "$ENV{BUILD}/$f") or die "$f: $!\n"; my @x = <$h>; my $s = lc(($l > 1 ? $x[$l - 2] : "") . " " . $x[$l - 1]);
  for my $re (@R) { if ($s =~ $re) { print "$f:$l\n"; last } }' "$OUT/changed")" || die "could not read back what the scrub changed"
[ -z "$part" ] || die "the scrub left part of a private remote beside its token:" $part

# Then what is left. Names, addresses and the shape of the tree.
allfiles "$B" > "$OUT/list.build"; scan "$B" "$OUT/list.build" "$OUT/hits.all"
# The home's own owner/repo is rewritten only in the manifest's field above.
# Anywhere else in the build it names the private repository, and no row waives it.
own="$(awk -F'\t' '$4 == "repository" { print $1 ":" $2 }' "$OUT/hits.all")"
[ -z "$own" ] || die "the home's own repository is named in the build; a person rewrites each:" $own
unacked "$OUT/hits.all" > "$OUT/hits"
bad_shape=""
for e in $(ls -A "$B"); do case "$e" in engine|projects|.gitignore|.claude-plugin|README.md|assets) ;; *) bad_shape="$bad_shape $e" ;; esac; done
for e in $(ls -A "$B/projects"); do [ "$e" = "$SELF" ] || bad_shape="$bad_shape projects/$e"; done
[ ! -d "$B/.claude-plugin" ] || for e in $(ls -A "$B/.claude-plugin"); do [ "$e" = marketplace.json ] || bad_shape="$bad_shape .claude-plugin/$e"; done
consent="$({ find "$B" \( -name autonomy -o -name autonomy.commission \) -print; find "$B/projects" -name 'autonomy*' -print; } | sed "s|^$B/||" | sort -u)"
rows=0; [ ! -f "$EX" ] || rows="$(grep -cvE '^[[:space:]]*(#|$)' "$EX" || true)"
if [ -s "$OUT/hits" ] || [ -n "$bad_shape" ] || [ -n "$consent" ] || [ "$rows" != 0 ]; then
  say "audit: STOP"
  [ ! -s "$OUT/hits" ] || { say "  lines naming a project or carrying an address, unacknowledged:"; show_hits "$B" "$OUT/hits"; }
  [ -z "$bad_shape" ] || say "  outside the published set:$bad_shape"
  [ -z "$consent" ] || say "  consent files in the build: $consent"
  [ "$rows" = 0 ] || say "  exceptions.tsv holds $rows row(s)"
  say "  Read each line. One that is not what the audit feared is acknowledged by a person, with the row above"
  say "  added to .snapshot-ack.tsv at the home's root in a pull request; only main's copy is read."
  # A self-test reproduces a tree that is already public, never commits, and
  # stops below either way, so it reports the audit and goes on to compare.
  [ -n "$EXPECT" ] || exit 1
  say "  --expect-tree: the comparison below still runs; nothing is committed"
else
  nack=$(wc -l < "$OUT/hits.all" | tr -d ' ')
  say "audit: ${#AUDIT[@]} names derived, ${#SCRUB[@]} rewritten; $(wc -l < "$OUT/changed" | tr -d ' ') lines changed, each on a name; $nack acknowledged, none open; no consent file, no row"
fi

# ------------------------------------------------------------- stage -------
# A fresh clone, never somebody's working copy, and a new branch. The staged
# paths are the published ones and nothing else: LICENSE and the public
# workflow live only there and survive because they are outside the pathspec,
# and a file the home removed is removed there. -f, because the home's ignore
# rules would silently drop a newly tracked file that one of them matches.
git clone -q "${PCLONE:-$PUBLIC_URL}" "$CLONE"
if [ -n "$BASE_REF" ]; then BASE="$(git -C "${PCLONE:-$CLONE}" rev-parse --verify "$BASE_REF^{commit}")"
elif [ -n "$PCLONE" ]; then BASE="$(git -C "$PCLONE" rev-parse --verify -q refs/remotes/origin/main || git -C "$PCLONE" rev-parse --verify HEAD)"
else BASE="$(git -C "$CLONE" rev-parse --verify refs/remotes/origin/main)"; fi
git -C "$CLONE" cat-file -e "$BASE^{commit}" || die "the public clone lacks $BASE"
taken() {
  git -C "$CLONE" rev-parse --verify -q "refs/remotes/origin/$1" >/dev/null && return 0
  [ -n "$PCLONE" ] && git -C "$PCLONE" rev-parse --verify -q "refs/remotes/origin/$1" >/dev/null
}
DAY="$(date +%Y-%m-%d)"; BR="snapshot/$DAY"; sfx=b
while taken "$BR"; do BR="snapshot/$DAY$sfx"; sfx="$(printf '%s' "$sfx" | tr 'a-y' 'b-z')"; done
git -C "$CLONE" checkout -q -b "$BR" "$BASE"
git -C "$CLONE" config user.name "$AUTHOR_NAME"
git -C "$CLONE" config user.email "$AUTHOR_EMAIL"
# The credential scan's baseline, read now, while the clone's files are the base's.
secrets() { (cd "$1" && "$B/engine/harness/bin/secret-scan" --tree 2>&1 >/dev/null || true) | sed -n 's/^  [0-9][0-9]*:+//p' | sort; }
[ -n "$EXPECT" ] || secrets "$CLONE" > "$OUT/secret.base"

STAGE="engine projects .gitignore .claude-plugin"; [ "$PUBLIC_README" -eq 1 ] || STAGE="$STAGE README.md"
# assets/ only where one side has it: a pathspec neither side has stops git add,
# and the snapshots made before it existed must still reproduce.
if [ -e "$B/assets" ] || git -C "$CLONE" cat-file -e "$BASE:assets" 2>/dev/null; then STAGE="$STAGE assets"; fi
# shellcheck disable=SC2086
(cd "$B" && git --git-dir="$CLONE/.git" --work-tree="$B" add -A -f -- $STAGE)
# shellcheck disable=SC2086
git -C "$CLONE" ls-files -- $STAGE | sort | cmp -s - "$OUT/files.build" || die "the staged paths are not the built tree"
outside="$(git -C "$CLONE" diff --cached --name-only "$BASE" | grep -vE '^(engine/|projects/|\.gitignore$|\.claude-plugin/|README\.md$|assets/)' || true)"
[ -z "$outside" ] || die "staging touched paths outside the published set:" $outside
if [ "$PUBLIC_README" -eq 1 ] && git -C "$CLONE" diff --cached --name-only "$BASE" | grep -qx README.md; then die "README.md changed with --public-readme"; fi

if [ -n "$EXPECT" ]; then
  got="$(git -C "$CLONE" write-tree)"
  want="$(git -C "$CLONE" rev-parse --verify -q "$EXPECT^{tree}" || printf '%s' "$EXPECT")"
  say "source $SRC  base $BASE"
  say "built tree    $got"
  say "expected tree $want"
  if [ "$got" = "$want" ]; then say "MATCH"; exit 0; fi
  say "DIFFER"; git -C "$CLONE" diff --stat "$want" "$got" | tail -20 || say "(no tree $want in the public clone to list the difference against)"; exit 1
fi
[ -n "$(git -C "$CLONE" diff --cached --name-only "$BASE")" ] || die "nothing to publish: the public main already holds this tree"

# ------------------------------------------------------------- commit ------
ver_of() { sed -n 's/.*"version"[^"]*"\([^"]*\)".*/\1/p' | head -1; }
VER="$(ver_of < "$B/engine/.claude-plugin/plugin.json")"
PREV="$(git -C "$CLONE" show "$BASE:engine/.claude-plugin/plugin.json" 2>/dev/null | ver_of || true)"
DAY_SRC="$(git -C "$HOME_TOP" log -1 --format=%cd --date=short "$SRC")"
MSG="$OUT/message.txt"
if [ -n "$MSGFILE" ]; then cp "$MSGFILE" "$MSG"; else
  {
    say "Engine $VER: the snapshot brought forward from ${PREV:-the last one}"
    say ""
    say "A snapshot of the engine as its home's main held it on $DAY_SRC."
    say "The home stays private, so this arrives as one commit rather than the"
    say "pull requests it was built from. The paths it changes:"
    say ""
    git -C "$CLONE" diff --cached --name-status "$BASE" | sed 's/^/    /'
  } > "$MSG"
fi
# The engine version and the date say where this came from; the home's commit
# id is private, so it is printed below for the lead to record, never published.
grep -qF "$VER" "$MSG" || printf '\nEngine %s, as the home'"'"'s main held it on %s.\n' "$VER" "$DAY_SRC" >> "$MSG"
! grep -qiF "${SRC:0:7}" "$MSG" || die "the message carries the home's commit id ${SRC:0:7}; the public text names the version and the date"
grep -q '^Withheld, as before' "$MSG" || cat >> "$MSG" <<'EOF'

Withheld, as before: the autonomy grants, which are a person's consent and not
state, and every other governed project's doctrine. Their names are replaced
where the published files mention them, and an audit wider than the
replacement, a separate search, found none left.
EOF
audit_text() {  # FILE: the words that go public beside the tree, held to the same audit, no acknowledgements
  local d="$OUT/text.$(basename "$1")"; mkdir -p "$d"; cp "$1" "$d/"
  printf '%s\0' "$(basename "$1")" > "$d.list"; scan "$d" "$d.list" "$d.hits"
  [ ! -s "$d.hits" ] || die "$(basename "$1") names a project or carries an address:" "$(cut -f1-4 "$d.hits")"
}
audit_text "$MSG"
SUBJECT="$(head -1 "$MSG")"
env -u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL -u GIT_COMMITTER_NAME -u GIT_COMMITTER_EMAIL git -C "$CLONE" commit -q -F "$MSG"
who="$(git -C "$CLONE" log --format='%an <%ae> %cn <%ce>' "$BASE..HEAD" | sort -u)"
[ "$who" = "$AUTHOR_NAME <$AUTHOR_EMAIL> $AUTHOR_NAME <$AUTHOR_EMAIL>" ] || die "a commit carries an identity that is not the public author's:" "$who"

# ------------------------------------------------------------- verify ------
# The exact commit, in a clone of its own, so what is judged is what would be
# pushed and not the directory it was built in.
git clone -q --branch "$BR" "$CLONE" "$V"
[ "$(git -C "$V" rev-parse HEAD)" = "$(git -C "$CLONE" rev-parse HEAD)" ] || die "the verification clone is not the commit"
secrets "$V" > "$OUT/secret.new"
[ -s "$OUT/secret.new" ] || die "secret-scan found nothing, not even the suite's planted fixtures, so it read nothing"
fresh="$(comm -13 "$OUT/secret.base" "$OUT/secret.new")"
[ -z "$fresh" ] || die "secret-scan finds lines the public main does not carry:" "$fresh"
say "secret: $(wc -l < "$OUT/secret.new" | tr -d ' ') hits, every one also on the public main (planted fixtures); none new"
say "suite: running on $(git -C "$V" rev-parse --short HEAD), about ten minutes; log $OUT/suite.log"
( cd "$V/engine/harness" && ./tests/run > "$OUT/suite.log" 2>&1 ) && rc=0 || rc=$?
echo "exit=$rc" >> "$OUT/suite.log"
SUITE="$(grep -E '^[0-9]+ passed, [0-9]+ failed' "$OUT/suite.log" | tail -1 || true)"
[ "$rc" -eq 0 ] && printf '%s' "$SUITE" | grep -q ' 0 failed' || die "the suite did not pass on the snapshot (exit $rc): ${SUITE:-no summary}" "$(grep -A2 '^  FAIL' "$OUT/suite.log" | head -12)"
say "suite: $SUITE, exit 0"

# ------------------------------------------------------------- report ------
PR="$OUT/pr-body.md"
{
  sed '1,/^$/d' "$MSG"
  say ""
  say "Checks, run on this exact commit before it was pushed:"
  say "- suite: $SUITE, exit 0"
  say "- secret-scan --tree: $(wc -l < "$OUT/secret.new" | tr -d ' ') hits, each also on the public main; none new"
  say "- names: ${#AUDIT[@]} derived at run time, each searched for in every file as bytes: whole in any case, as two whole-word halves or adjacent words within three lines, and with one byte, escape or bracket class standing in for one of its characters, in the text and in a copy with escapes decoded; $(cut -f4 "$OUT/hits.all" | grep -vc '^address$' || true) acknowledged by a person, none open. Deliberate obfuscation is not searched for"
  say "- identity: every commit authored and committed as the public author; $(cut -f3 "$OUT/hits.all" | grep -c '^@' || true) other address(es) in the tree, each acknowledged by a person"
  say "- consent: no autonomy file; the exception table is the empty template"
} > "$PR"
audit_text "$PR"
say ""
git -C "$CLONE" diff --stat=100 "$BASE" HEAD
say ""
say "source: the home's $SRC; record it privately, the public message carries engine $VER and $DAY_SRC"
say "Nothing was pushed. To publish, run:"
say "  git -C $CLONE push $PUBLIC_URL $BR"
say "  gh pr create --repo $PUBLIC_SLUG --base main --head $BR --title $(printf '%q' "$SUBJECT") --body-file $PR"
say "Merge it on green CI; the public main takes nothing else. Then, in the home:"
say "  felix maintenance --ran snapshot   and commit projects/$SELF/maintenance.log"
say ""
say "Withheld, and why:"
git -C "$HOME_TOP" ls-tree --name-only "$SRC" | while IFS= read -r e; do
  case "$e" in
    engine|.gitignore|assets) ;;
    README.md) if [ "$PUBLIC_README" -eq 1 ]; then say "  README.md: the public one is kept (--public-readme)"; fi ;;
    .claude-plugin) n="$(git -C "$HOME_TOP" ls-tree --name-only "$SRC" .claude-plugin/ | grep -vc marketplace.json || true)"
      if [ "$n" != 0 ]; then say "  .claude-plugin/: $n file(s) besides the marketplace manifest, the only one a clone needs"; fi ;;
    projects) say "  projects/: $(git -C "$HOME_TOP" ls-tree -d --name-only "$SRC" projects/ | grep -vcx "projects/$SELF" || true) other director(ies), each another governed project's doctrine" ;;
    HANDOFF.md|docs) say "  $e: the home's own record, written for the people and sessions that work here" ;;
    .snapshot-ack.tsv) say "  $e: the audit's acknowledgements; it names what the audit searches for" ;;
    .felix) say "  .felix: this checkout's binding to its project" ;;
    .github) say "  .github/: the home's workflows; the public repository keeps its own, outside the staged paths" ;;
    *) say "  $e: in no rule here; decide it before the next snapshot" ;;
  esac
done
say "  projects/$SELF/autonomy, autonomy.commission: a person's consent, and consent is not state"
say "  memory: never in the tree, so never in the build"
say "Kept from the public repository, outside the staged paths:"
git -C "$CLONE" ls-tree -r --name-only HEAD | grep -vE '^(engine/|projects/|\.gitignore$|\.claude-plugin/|README\.md$|assets/)' | sed 's/^/  /' || true
say "Scratch, unscrubbed where it says raw: $OUT"
