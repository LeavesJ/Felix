#!/usr/bin/env bash
# The public snapshot's scrub, kept apart from its audit (snapshot-audit.sh).
#
#   snapshot-scrub.sh PLAN LIST
#
# PLAN is one project a line, in token order: name<TAB>token<TAB>phrase<TAB>
# remotes, the last every owner/repo its manifest declared, space-separated.
# LIST is the text files to rewrite in place, NUL-separated. snapshot.sh
# derives both, runs this, and then checks what it changed; nothing here
# decides whether the result may go out.
#
# Per project in token order, and the order is load-bearing. Its remotes first,
# each whole: owner/repo (or owner:repo) becomes OWNER/token, and the
# repository's name alone, its words joined by any separators or none, becomes
# what the name would in that place. Rewritten a piece at a time, the name
# inside a longer repository name became the token and left the owner and the
# rest of the private name around it. Then the name itself, and what it becomes
# is read from the characters around it. Inside an identifier (a letter, digit
# or underscore beside it, or $, { or } as in a variable) it is the token in
# the identifier's case: THIRD_PROJECT for an upper-case name, which keeps
# ${NAME:-} a variable where a phrase made it a bad substitution, and the bare
# token otherwise. Inside a path (a slash or a
# hyphen beside it, a dot and a file extension after it, or a dot before it, as
# in a dot-directory; `"$1/.name"` became a path with spaces) it is the token,
# which has no space: a phrase with spaces inside a path made `test -f` a usage
# error, and later turned a redirect into one to a file named for the first
# word. Anywhere else it is prose and becomes the phrase, in lower case; an
# escape such as \n before it counts as a space. Then the pieces, and only
# where no ordinary word can be meant: two halves split anywhere, each a whole
# word, with up to eight characters between and no letter or digit among them;
# and a whole word that is the name with one character standing in, where that
# character is a mark (a dot, say) or a capital among lower-case letters. Each
# becomes the token's pieces. The first and last characters are never taken as
# stand-ins here. An ordinary word one letter away from a name (planter against
# planner) is never rewritten: the audit stops on it for a person to read.
#
# A shell variable named after a project is renamed whole, never in part. In a
# shell file (*.sh, or a #! line naming a shell) a name standing as a variable,
# where it is assigned (name=, name+=, name[i]=), declared or read (after local,
# export, readonly, declare, typeset, unset or read) or looped over (for name
# in), becomes the token in its case, as `$name` and `${name}` already do, so
# every use names the same identifier. The phrase there made `name=1` a
# command named `a` and left `$THIRD_PROJECT` unset, and bash -n passed both.
# A quoted string can be code another shell runs (eval "name=1", bash -c
# 'name=1; echo "$name"', a trap, awk -v's program), so in quotes an expansion
# or an assignment where a command may begin is a variable too, and in a file
# that has one, every mention of the name inside quotes becomes the token: the
# phrase there made the assignment a command named `a` while `$name` became the
# token, and the check for the phrase in code, which skips strings, passed it.
# A bare word in arithmetic ($(( name + 1 )), (( )), let) is a variable read as
# well: a file whose only use was "$(( name * 2 ))" got the phrase there, bash
# -n passed it, and it printed a syntax error where it had printed a number.
# A file that already has a variable of the token's name, or two spellings of
# the name that would both become it, stops for a person, since renaming would
# merge two variables. So does a name that is a variable only where no rule here
# renames it: a loop or read variable inside a quoted string (bash -c 'for name
# in a b; do ...'), in a file with no other variable use of it, and, in a file
# that is not shell (a workflow's run:, a Markdown fence), a name assigned,
# declared, looped over with do, or read in $(( )). Each became the phrase while
# $name became the token, and nothing parses a string or a YAML file as shell.
# Prose in quotes (waiting for name in the queue) is left alone. Elsewhere in shell code a name the rules above make the
# phrase is left to snapshot.sh, which stops on the phrase outside a comment or
# a quoted string. A case pattern naming a project is one: `name)` becomes
# the phrase, the parse check stops the run, and a person rewrites the line.
# The lead accepted that as fail-closed on 2026-09-22; it is not scrubbed.
#
# Only text files are listed: a binary file is never edited, so a name in one
# is left for the audit, which reads every file, to stop on. A list that comes
# back short leaves a name unrewritten, and the audit stops on it, so a failure
# here is never silent.
set -euo pipefail
export LC_ALL=C
[ $# -eq 2 ] && [ -f "$1" ] && [ -f "$2" ] || { echo "usage: snapshot-scrub.sh PLAN LIST" >&2; exit 2; }
IFS= read -r -d '' SCRUB_PL <<'PERL' || true
sub stop { print STDERR "snapshot-scrub: $_[0]\n"; exit 255 }  # before anything is written; xargs stops too
sub st {  # where a shell line's prefix ends: c in code, d or s inside quotes, # in a comment
  my ($b, $q) = (shift, "c");
  for (my $i = 0; $i < length $b; $i++) { my $c = substr($b, $i, 1);
    if ($q eq "s") { $q = "c" if $c eq "'"; next } if ($c eq "\\") { $i++; next } if ($q eq "d") { $q = "c" if $c eq '"'; next }
    if ($c eq "'") { $q = "s" } elsif ($c eq '"') { $q = "d" } elsif ($c eq "#" && ($i == 0 || substr($b, $i - 1, 1) =~ /\s/)) { return "#" } }
  return $q;
}
sub var {  # the text before and after a whole word on a shell line, and whether $x counts: is it a variable?
  my ($b, $a, $x) = @_; my $s = st($b);
  return 0 if $s eq "#";
  # A bare word in arithmetic, a (( still open before it or after let, is read as a variable too.
  my $e = ($x && $b =~ /\$\{?[#!]?$/) || (() = $b =~ /\(\(/g) > (() = $b =~ /\)\)/g) || $b =~ /(?:^|[\s;&|(])let\s[^;&|]*$/;
  # In quotes, code only for a shell the string is handed to (eval, bash -c, a trap):
  # an expansion, or an assignment where a command may begin; for and read there are prose.
  return $e || ($a =~ /^(?:\[[^\]]*\])?\+?=/ && $b =~ /(?:^|[\s;&|('"])$/) if $s ne "c";
  return $e || ($a =~ /^(?:\[[^\]]*\])?\+?=/ && $b =~ /(?:^|[\s;&|(])$/)
      || $b =~ /\b(?:local|export|readonly|declare|typeset|unset|read)\b[^;&|#\n]*\s$/ || $b =~ /\b(?:for|select)\s+$/;
}
sub nsv {  # outside a shell file, a shape only shell code gives a word: assigned, declared, looped over, in $(( ))
  my ($b, $a) = @_;
  return ($a =~ /^(?:\[[^\]]*\])?\+?=/ && $b =~ /(?:^|[\s;&|(])$/) || $b =~ /\b(?:local|export|readonly|declare|typeset|unset)\s+(?:-\w+\s+)*$/
      || ($b =~ /\b(?:for|select)\s+$/ && $a =~ /^\s*(?:;|\s+in\b.*;)\s*do\b/) || $b =~ /\$\(\([^)]*$/;
}
BEGIN {
  ($n, $t, $ph, $up, $tup, $rm) = @ENV{qw(N T PH UP TUP RM)}; $L = length $n;
  for my $f (@ARGV) {  # the shell files, and whether a rename would merge two variables in one
    open(my $h, '<', $f) or die "snapshot-scrub: cannot read $f: $!\n"; my @x = <$h>; close $h;
    unless ($f =~ /\.sh$/ || (@x && substr($x[0], 0, 64) =~ /^#!.*sh/)) {
      for my $i (0 .. $#x) { while ($x[$i] =~ /(?<![A-Za-z0-9_])\Q$n\E(?![A-Za-z0-9_])/gi) { my $m = $&;
        stop("$f:" . ($i + 1) . " uses $m as a shell variable in a file that is not shell, where only \$$m would be renamed; a person rewrites it")
          if nsv(substr($x[$i], 0, $-[0]), substr($x[$i], $+[0])) } }
      next;
    }
    $SH{$f} = 1; my (%to, %have, $sus);
    for my $x (@x) {
      while ($x =~ /(?<![A-Za-z0-9_])\Q$n\E(?![A-Za-z0-9_])/gi) {
        my $m = $&; my ($b, $a) = (substr($x, 0, $-[0]), substr($x, $+[0]));
        unless (var($b, $a, 1)) {  # for and read in quotes are prose to var; in a string another shell runs they are not
          $sus = 1 if st($b) =~ /^[sd]$/ && (($b =~ /\b(?:for|select)\s+$/ && $a =~ /^\s*(?:;|\s+in\b.*;)\s*do\b/)
            || ($b =~ /\bread\b[^;&|#\n]*\s$/ && ($b =~ /\bread\s+-/ || $a =~ /^\s*(?:[;<|&)]|$)/))); next;
        }
        $to{$m =~ /[a-z]/ ? $t : $tup}{$m} = 1; $VF{$f} = 1;
      }
      for my $r ($t, $tup) { while ($x =~ /(?<![A-Za-z0-9_])\Q$r\E(?![A-Za-z0-9_])/g) { $have{$r} = 1 if var(substr($x, 0, $-[0]), substr($x, $+[0]), 1) } }
    }
    stop("$f names $n as a loop or read variable inside a quoted string and nowhere as one the scrub renames; a person rewrites it") if $sus && !$VF{$f};
    for my $r (sort keys %to) {
      my @m = sort keys %{ $to{$r} };
      stop("$f uses @m as shell variables and each would become $r; a person renames them") if @m > 1;
      stop("$f uses $m[0] as a shell variable and already has one named $r; a person renames it") if $have{$r};
    }
  }
}
sub rep {  # the line, where the name starts and ends in it, and the name as written
  my ($o, $s, $e, $m) = @_;
  my ($b, $a) = (substr($o, 0, $s), substr($o, $e));
  my ($p, $pp) = (length $b ? substr($b, -1) : "", length $b > 1 ? substr($b, -2, 1) : "");
  my ($q, $qq) = (length $a ? substr($a, 0, 1) : "", length $a > 1 ? substr($a, 1, 1) : "");
  $p = " " if $pp eq "\\" && $p =~ /[ntr]/;
  return $m =~ /[a-z]/ ? $t : $tup if $p =~ /[A-Za-z0-9_\$\{]/ || $q =~ /[A-Za-z0-9_\}]/ || ($SH{$ARGV} && var($b, $a));
  return $t if $p =~ m{[/-]} || $q =~ m{[/-]} || ($q eq "." && $qq =~ /[A-Za-z0-9]/) || $p eq ".";
  return $m =~ /[a-z]/ ? $t : $tup if $VF{$ARGV} && st($b) =~ /^[sd]$/;
  return $ph;
}
for my $s (split ' ', $rm // '') {
  my ($w, $r) = $s =~ m{^(?:(.*)/)?([^/]+)$} or next;
  my $re = join '[-_. ]*', map { quotemeta } grep { length } split /[-_. ]+/, $r;
  s{(?<![A-Za-z0-9_.-])\Q$w\E([/:])$re(?![A-Za-z0-9_-])}{OWNER$1$t}gi if defined $w && length $w;
  next if lc($r =~ s/[-_. ]//gr) eq lc $n;  # the name alone: the rule below has it
  my $o = $_; s{(?<![A-Za-z0-9])$re(?![A-Za-z0-9])}{rep($o, $-[0], $+[0], $&)}gie;
}
my $o = $_;
s{\Q$n\E}{rep($o, $-[0], $+[0], $&)}gie;
for my $k (1 .. $L - 1) {
  my ($x, $y) = (substr($n, 0, $k), substr($n, $k));
  my ($tx, $ty) = (substr($t, 0, $k), $k < length $t ? substr($t, $k) : "");
  next if $ty eq "";
  s{(?<![A-Za-z0-9])\Q$x\E([^A-Za-z0-9]{1,8}?)\Q$y\E(?![A-Za-z0-9])}{$tx$1$ty}g;
}
for my $k (1 .. $L - 2) {
  my ($x, $y) = (substr($n, 0, $k), substr($n, $k + 1));
  my ($tx, $ty) = (substr($t, 0, $k), $k < length $t ? substr($t, $k) : "");
  next if $ty eq "";
  s{(?<![A-Za-z0-9])\Q$x\E([^A-Za-z0-9\s]|[A-Z])\Q$y\E(?![A-Za-z0-9])}{$tx$1$ty}g;
}
PERL
[ -s "$2" ] || exit 0
while IFS="$(printf '\t')" read -r n tok ph rm; do
  N="$n" T="$tok" PH="$ph" RM="$rm" UP="$(printf '%s' "$n" | tr '[:lower:]' '[:upper:]')"
  TUP="$(printf '%s' "$tok" | tr '[:lower:]' '[:upper:]')_PROJECT"
  export N T PH RM UP TUP
  xargs -0 perl -pi -e "$SCRUB_PL" < "$2"
done < "$1"
