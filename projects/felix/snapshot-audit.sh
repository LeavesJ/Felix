#!/usr/bin/env bash
# The public snapshot's audit, kept apart from its scrub (snapshot-scrub.sh).
#
#   snapshot-audit.sh NAMES AUTHOR ROOT [SLUG] < paths
#
# NAMES is a file of audit names, one a line; AUTHOR is the one address that
# may appear; SLUG, when given, is the private home's own owner/repo; the
# paths, NUL-separated and relative to ROOT, are what is read.
# Prints path<TAB>line<TAB>name<TAB>rule<TAB>hash for every line one of them
# reaches, once a line, where hash is git hash-object of that line. The path
# itself is read as line 0, because a name in a file name is published as
# surely as one inside it, and a symbolic link reads as its target. Exit 0 when
# every file was read and 2 when one could not be, so a caller never takes
# silence for a pass.
#
# The rules are the audit's own, sharing no pattern with the scrub, and they
# are for accidents of our own authoring. A name is looked for:
#   whole, in any case, as part of any word;
#   in two halves, each a whole word, split at any point, with anything
#     between and up to two lines apart (a name assembled from pieces);
#   as a run of adjacent words that joins into it, over up to three lines;
#   with one character standing in for one of its own, at any position, when
#     the name has four or more: an escape (\x76, \166, \u0076, \.), a bracket
#     class ([e], [de], [^x], [[:alpha:]]), a group ((e|x)) or, inside the
#     name, any byte but a space, each with a quantifier after it or not (.?,
#     \w+, .{1}); at its first and last character, where a letter only makes
#     a longer word, any mark that is not a letter, digit or space, which
#     flags some ordinary text too (a quote or colon before the rest of a
#     name, 'olor or :olor for color): the lead accepted that as fail-closed
#     on 2026-09-22, since a person reads the line and a row clears it;
#   and all of the above again in a decoded copy of each line, where escapes
#     and one-letter classes read as what they stand for and NUL bytes are
#     dropped, so c[o]lo\x72 reads as the word color.
# Words are runs of letters and digits, so an underscore, a quote or a line
# break between two halves separates them and does not hide them.
#
# An address is any a person could own. AUTHOR's passes, as do the reserved
# example domains and an app's identity at GitHub's no-reply domain, a local
# part ending [bot], which no person's account can have; every other stops. The
# brackets are read as part of an address, so that last one is passed by a rule
# and not by an address the pattern could not see; one that opens it is not
# part of it, since Markdown's link text [name@host](mailto:...) put it there
# and stopped on the author's own address.
#
# SLUG is looked for as owner/repo or owner:repo, in any case, with the
# repository's words joined by any separators or none, in the text and in the
# decoded copy, and reported under the rule repository. The home's own names
# are not audit names (they name the pointer file and the engine), so a
# workflow's `repository: owner/<home>` went out verbatim until this rule.
set -euo pipefail
export LC_ALL=C
{ [ $# -eq 3 ] || [ $# -eq 4 ]; } && [ -f "$1" ] && [ -d "$3" ] || { echo "usage: snapshot-audit.sh NAMES AUTHOR ROOT [SLUG] < paths" >&2; exit 2; }
IFS= read -r -d '' PROG <<'PERL' || true
use strict; use warnings;
use Digest::SHA qw(sha1_hex);
my ($namesf, $me, $root, $slug) = @ARGV;
my $SL;
if (defined $slug && length $slug) {
  my ($w, $r) = $slug =~ m{([^/:\s]+)[/:]([^/:\s]+?)(?:\.git)?$} or die "snapshot-audit: cannot read the slug $slug\n";
  my $j = join '[-_. ]*', map { quotemeta } grep { length } split /[-_. ]+/, $r;
  $SL = qr/(?<![a-z0-9_.-])\Q$w\E[\/:]$j(?![a-z0-9_-])/i;
}
open(my $nf, '<', $namesf) or die "snapshot-audit: cannot read $namesf: $!\n";
my (@names, %seen);
while (my $n = <$nf>) { $n = lc $n; $n =~ s/[^a-z0-9]//g; push @names, $n if length $n && !$seen{$n}++; }
close $nf;
my (%half, %prefix, %full, %standin);
# A stand-in at position k: the name's own letters before and after it, and
# between them an escape, a bracket class, a group of alternatives or any byte
# but a space, and after it a quantifier if one is there: col.?r, co\w+or and
# c(o|x)lor for color each went through when a stand-in had to be one atom. Each
# position is its own pattern, tried only where its longer fixed side occurs.
my $ESC = '\\\\{1,2}(?:x[0-9a-f]{2}|u[0-9a-f]{4}|[0-7]{1,3}|.)|\\[\\^?[^\\]\\s]{1,8}\\]|\\[\\[:[a-z]+:\\]\\]|\\((?:[^()|\\s]{1,4}\\|)+[^()|\\s]{1,4}\\)';
my $Q = '(?:[?*+]|\\{[0-9]*(?:,[0-9]*)?\\})?';
my ($SI, $SE) = ("(?:(?:$ESC|\\S)$Q)", "(?:(?:$ESC|[^a-z0-9\\s])$Q)");
for my $n (@names) {
  my $L = length $n; $full{$n} = 1;
  for my $k (1 .. $L - 1) { push @{ $half{substr($n, 0, $k)} }, [$n, substr($n, $k)]; $prefix{substr($n, 0, $k)} = 1; }
  next if $L < 4;
  for my $k (0 .. $L - 1) {
    my ($a, $b) = (substr($n, 0, $k), substr($n, $k + 1));
    my $re = quotemeta($a) . ($k == 0 || $k == $L - 1 ? $SE : $SI) . quotemeta($b);
    push @{ $standin{$n} }, [length $a > length $b ? $a : $b, qr/$re/];
  }
}
sub decode {
  my $d = shift;
  $d =~ s/\0//g;
  $d =~ s/\\{1,2}[ntr]/ /g;
  $d =~ s/\\{1,2}x([0-9a-fA-F]{2})/chr hex $1/ge;
  $d =~ s/\\{1,2}u00([0-9a-fA-F]{2})/chr hex $1/ge;
  $d =~ s/\\{1,2}([0-7]{3})/chr oct $1/ge;
  $d =~ s/\[([A-Za-z0-9])([A-Za-z0-9]?)\]/$2 eq '' || lc $1 eq lc $2 ? $1 : "[$1$2]"/ge;
  $d =~ s/\\{1,2}(.)/$1/g;
  return lc $d;
}
sub hash_of { my $l = shift; sha1_hex('blob ' . (length($l) + 1) . "\0" . $l . "\n") }
sub audit {  # the lines of one file; returns the name hits and the address hits, by index
  my @L = @_;
  my (%hit, %adr, %rep, @tok, @set);
  my $mark = sub { my ($i, $n, $r) = @_; $hit{$i} ||= [$n, $r]; };
  my @lc = map { lc } @L; my @dc = map { decode($_) } @L;
  my $all = join("\n", @lc, @dc);
  my %live;
  for my $n (@names) { $live{$n} = [ grep { index($all, $_->[0]) >= 0 } @{ $standin{$n} || [] } ]; }
  for my $i (0 .. $#L) {
    my ($l, $lc, $dc) = ($L[$i], $lc[$i], $dc[$i]);
    NAME: for my $n (@names) {
      if (index($lc, $n) >= 0 || index($dc, $n) >= 0) { $mark->($i, $n, 'name'); next; }
      for my $s (@{ $live{$n} }) {
        next unless index($lc, $s->[0]) >= 0 || index($dc, $s->[0]) >= 0;
        if ($lc =~ $s->[1] || $dc =~ $s->[1]) { $mark->($i, $n, 'stand-in'); next NAME; }
      }
    }
    while ($l =~ /([A-Za-z0-9._%+\[\]-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,})/g) {
      (my $e = lc $1) =~ s/^\[+//; (my $d = $e) =~ s/.*@//;
      next if $e eq lc($me) || $d =~ /(^|\.)(example|invalid|test|localhost|local)$/ || $d =~ /(^|\.)example\.(com|net|org)$/;
      next if $e =~ /^(?:[0-9]+\+)?[a-z0-9-]+\[bot\]\@users\.noreply\.github\.com$/;
      $adr{$i} ||= ["\@$e", 'address'];
    }
    $rep{$i} = [lc $1, 'repository'] if $SL && ($l =~ /($SL)/ || $dc =~ /($SL)/);
    $tok[$i] = [ $dc =~ /[a-z0-9]+/g ];
    $set[$i] = { map { $_ => 1 } @{ $tok[$i] } };
  }
  # Two halves, each a whole word, up to two lines apart, in either order.
  for my $i (0 .. $#L) {
    for my $t (@{ $tok[$i] }) {
      next unless $half{$t};
      for my $h (@{ $half{$t} }) {
        my ($n, $rest) = @$h;
        for my $j (($i > 2 ? $i - 2 : 0) .. ($i + 2 < $#L ? $i + 2 : $#L)) {
          next unless $set[$j]{$rest};
          $mark->($i, $n, 'halves'); $mark->($j, $n, 'halves'); last;
        }
      }
    }
  }
  # Adjacent words that join into a name, over up to three lines.
  my @seq; for my $i (0 .. $#L) { push @seq, [$_, $i] for @{ $tok[$i] }; }
  for my $s (0 .. $#seq) {
    my $acc = $seq[$s][0];
    next unless $prefix{$acc};
    for my $e ($s + 1 .. $#seq) {
      last if $seq[$e][1] - $seq[$s][1] > 2;
      $acc .= $seq[$e][0];
      if ($full{$acc}) { $mark->($seq[$_][1], $acc, 'pieces') for $s .. $e; }
      last unless $prefix{$acc};
    }
  }
  return (\%hit, \%adr, \%rep);
}
sub report {  # path, number of the first line, the lines, name hits, address hits, repository hits
  my ($p, $o, $L, @h) = @_;
  for my $h (@h) {
    for my $i (sort { $a <=> $b } keys %$h) { print join("\t", $p, $i + $o, @{ $h->{$i} }, hash_of($L->[$i])), "\n"; }
  }
}
my $bad = 0;
local $/ = "\0";
while (my $p = <STDIN>) {
  chomp $p; next unless length $p;
  my $c;
  if (-l "$root/$p") { $c = readlink "$root/$p"; defined $c or do { warn "snapshot-audit: cannot read the link $p: $!\n"; $bad = 1; next }; }
  elsif (open(my $fh, '<:raw', "$root/$p")) { local $/; $c = <$fh>; close $fh; }
  else { warn "snapshot-audit: cannot read $p: $!\n"; $bad = 1; next; }
  $c = '' unless defined $c;
  my @L = split /\n/, $c, -1; pop @L if @L && $L[-1] eq '';
  report($p, 0, [$p], audit($p));
  report($p, 1, \@L, audit(@L));
}
exit($bad ? 2 : 0);
PERL
exec perl -e "$PROG" -- "$@"
