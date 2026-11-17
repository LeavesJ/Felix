# The kept judgement behind lib/instrument.sh (trust-plane step 3, slice 3, spec A5). A full instrument run took
# 4,044 s for one honest machinery change (2026-11-08, this Mac, load average near 100), so the judgement of a
# machinery change is kept as a receipt in the home's state, keyed by B's commit, the tree the squash would land
# and the engine that judged, and a later merge or dry run with the same key reads its blocker lines instead of
# running again. A receipt that cannot be read whole (unreadable, cut short, edited, another key's) is no receipt.
#
# What is kept is the run's own verdict, S8's lines: the partition's lines (S7) are read again every time, at no
# cost. A run is kept only when every unit and the canary ended by themselves and no input was unread: a time limit
# reached under a passing load, or a stop, says nothing about the tree, and kept it would refuse every later merge
# of that pair (a reading of A5). The receipt is the worker's to write, like the gate's (residual R4); the hosted
# authority (step 4) is what closes that. The engine is named by its version and by the bytes of the four files
# that judge (instrument*.sh), so an engine changed under an unchanged version does not read another's receipt.
#
# A10, a kept judgement the units could have written is not used (the automated review of round 1: a unit, which is
# the candidate's code, could find the home and leave a clean receipt for a later candidate):
#   - units run without FELIX_HOME_DIR or FELIX_HOME and with a HOME of their own (instrument-run.sh);
#   - a judgement that runs and is not kept removes whatever is kept at its key (_felix_instr_unkeep);
#   - the kept judgements' directory is listed, each entry with its size, modification and change times and inode,
#     before the first unit starts, and held in memory; once the last unit and the canary have ended, every entry
#     that is new or changed since is removed (_felix_instr_ksweep), before the judge writes its own at its key.
# A13, after fault round 2 (a unit forged a judgement at its own key and ended the judge before the sweep):
#   - every end of a judgement whose first unit or canary started sweeps, and removes what is kept at its key unless
#     it kept this run: its normal end, an exit and a trapped signal alike (_felix_instr_kend, from the clean-up);
#   - a marker of the running judgement, beside the kept ones, is written before the first unit and removed only after
#     the sweep; a judgement that finds one whose judge is gone (KILL) removes every kept judgement before it reads one;
#   - the sweep fails closed (a listing or removal that fails, an entry still there, the directory's mode, owner or
#     identity changed: the whole directory goes, its flags and permissions cleared first), and the times it lists
#     are to the nanosecond. When even that removal fails, the marker stays, and no kept judgement is read.
# A19, after the automated review of round 3 (a judgement read a receipt while another judgement's units ran):
#   - a judgement that finds another's marker whose judge is running reads no kept judgement and runs its own units,
#     writes nothing at its key and removes nothing kept there (that judge's sweep would remove what it wrote);
#   - the markers' directory is read after that check and again after the receipt is, and what was read is used only
#     when it held no marker and did not change between the two (a judgement that began meanwhile).
# Not bound (A13's open list): a unit that removes its judge's marker, while that judge runs (a concurrent judgement
# then reads what the unit wrote) or before it ends the judge with KILL; one that rewrites
# the home pointer under the user's real home, which it can find without HOME; one that outlives its process group
# (E4), which can write after the sweep; and a receipt written by anything but the judge between two judgements,
# since nothing here signs a receipt with a key the units cannot read. That needs an identity of the authority's own
# (R1, step 4), or units run as another user or in a sandbox (E4), and is not built.

# The key: B MT VERSION@HASH, or nothing (and so no receipt) when the engine's version cannot be read.
_felix_instr_key() {   # B MT
  local d v e
  d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd -P)" || return 0
  v="$(LC_ALL=C sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$d/../../.claude-plugin/plugin.json" 2>/dev/null | head -1)"
  [ -n "$v" ] || return 0
  e="$(cat "$d/instrument.sh" "$d/instrument-verdict.sh" "$d/instrument-run.sh" "$d/instrument-keep.sh" 2>/dev/null | git hash-object --stdin 2>/dev/null)"
  [ -n "$e" ] || return 0
  printf '%s %s %s@%s' "$1" "$2" "$v" "$e"
}
# The kept judgements' directory, the home's state/instrument, or 1 when no home is known.
_felix_instr_kdir() {
  local h="${FELIX_HOME_DIR:-}"
  [ -n "$h" ] && [ -d "$h" ] || return 1
  printf '%s/state/instrument' "$h"
}
# The receipt's file for KEY, in that directory, or nothing when no home is known.
_felix_instr_kfile() {   # KEY
  local d n
  d="$(_felix_instr_kdir)" || return 1
  n="$(printf '%s' "$1" | git hash-object --stdin 2>/dev/null)" && [ -n "$n" ] || return 1
  printf '%s/%s' "$d" "$n"
}
# A10, A13. The directory as it is, from lstat, which follows no link: a line for the directory itself (its device,
# inode, full mode and owner; entries come and go under it, so not its times), and one for each entry (size,
# modification and change times to the nanosecond, inode, mode, and the name in hex, so that no name can split a
# line). "none" when there is no directory, "fail" when it or an entry of it cannot be read. perl's, since BSD and
# GNU stat do not share a format. A18: the order is LC_ALL=C sort's (part 0992's rule), and "dir" sorts first.
_felix_instr_kpl='use Time::HiRes (); my $d = $ARGV[0]; my @s = Time::HiRes::lstat($d);
if (!@s) { print $!{ENOENT} ? "none\n" : "fail\n"; exit 0 } printf "dir %s %s %o %s\n", @s[0, 1, 2, 4];
if (($s[2] & 0170000) != 0040000) { print "fail\n"; exit 0 } opendir(my $h, $d) or do { print "fail\n"; exit 0 };
for my $n (readdir $h) { next if $n eq "." || $n eq ".."; my @e = Time::HiRes::lstat("$d/$n") or do { print "fail\n"; next };
  printf "e %s %.9f %.9f %s %o %s\n", $e[7], $e[9], $e[10], $e[1], $e[2], unpack("H*", $n) }'
_felix_instr_klist() {   # [DIR]
  local d="${1:-}"; [ -n "$d" ] || d="$(_felix_instr_kdir)" || return 0
  { perl -e "$_felix_instr_kpl" "$d" 2>/dev/null || printf 'fail\n'; } | LC_ALL=C sort
}
# A13. The whole directory removed, its flags and permissions cleared first (a file a unit locked with chflags uchg,
# a directory it made unreadable); a link in its place is removed as a link. 1 when anything of it is still there.
_felix_instr_knuke() {   # DIR
  local d="$1"
  [ -n "$d" ] || return 1
  if [ -L "$d" ]; then rm -f "$d" 2>/dev/null
  elif [ -e "$d" ]; then { chflags -R nouchg "$d"; chmod -R u+rwx "$d"; rm -rf "$d"; } 2>/dev/null
  fi
  [ ! -e "$d" ] && [ ! -L "$d" ]
}
# A10, A13. Every entry of the directory that is not in LISTING as it was is removed. It fails closed: a listing or a
# removal that fails, an entry still there afterwards, or a directory that is not the one listed (its mode, owner or
# identity, or one made since) removes the whole directory. 1 only when that removal failed too.
_felix_instr_ksweep() {   # LISTING
  local d now l x n bad=""
  d="$(_felix_instr_kdir)" || return 0
  now="$(_felix_instr_klist "$d")"
  [ "$now" != none ] || return 0
  case $'\n'"$now"$'\n'"$1"$'\n' in *$'\n'fail$'\n'*|*$'\n'none$'\n'*) bad=1 ;; esac
  [ "${now%%$'\n'*}" = "${1%%$'\n'*}" ] || bad=1
  if [ -z "$bad" ]; then
    while IFS= read -r l; do
      case "$l" in "e "*) ;; *) continue ;; esac
      _felix_instr_in "$1" "$l" && continue
      x="${l##* }"; case "$x" in ''|*[!0123456789abcdef]*) bad=1; break ;; esac
      n="$(printf '%s' "$x" | perl -ne 'print pack("H*", $_)' 2>/dev/null)"
      case "$n" in ''|.|..|*/*) bad=1; break ;; esac
      rm -rf "$d/$n" 2>/dev/null || { bad=1; break; }
    done <<EOF
$now
EOF
  fi
  if [ -z "$bad" ]; then
    now="$(_felix_instr_klist "$d")"
    while IFS= read -r l; do
      case "$l" in none) ;; "e "*) _felix_instr_in "$1" "$l" || bad=1 ;; "dir "*) [ "$l" = "${1%%$'\n'*}" ] || bad=1 ;; *) bad=1 ;; esac
    done <<EOF
$now
EOF
  fi
  [ -z "$bad" ] || _felix_instr_knuke "$d"
}
# A10. What is kept at KEY, removed: a judgement that ran and is not kept leaves none behind it. 1 when it is still there.
_felix_instr_unkeep() {   # KEY
  local f; f="$(_felix_instr_kfile "$1")" || return 0
  rm -f "$f" 2>/dev/null; [ ! -e "$f" ] && [ ! -L "$f" ]
}
# A13. The markers of running judgements, beside the kept ones: one file a judge, named by its pid, holding that pid
# and its start time as ps prints it. A judge is running while ps names that pid with that start time.
_felix_instr_mdir() { local d; d="$(_felix_instr_kdir)" || return 1; printf '%s-judging' "$d"; }
_felix_instr_pstart() { LC_ALL=C ps -o lstart= -p "$1" 2>/dev/null | LC_ALL=C sed -n '1s/[[:space:]]*$//p'; }   # PID
# A13. This judgement's marker, written before its first unit or canary starts. 1 when it could not be written. A
# start time ps cannot read is written "-", which no later judgement reads as running: it then clears what is kept.
_felix_instr_mark() {
  local md st p="${_FELIX_INSTR_OWNER:-}"
  md="$(_felix_instr_mdir)" || return 0
  case "$p" in ''|*[!0123456789]*) return 1 ;; esac
  st="$(_felix_instr_pstart "$p")"; [ -n "$st" ] || st=-
  _FELIX_INSTR_MARK="$md/$p"
  { mkdir -p "$md" && printf 'felix-instrument-judging %s %s\n' "$p" "$st" > "$md/$p"; } 2>/dev/null
}
# A13. Before a kept judgement is read. A marker whose judge is no longer running, or anything there that is not a
# marker, says a judgement ended without its sweep: every kept judgement is removed, then that marker. 1, and
# nothing is read, while such a marker cannot be cleared. A19: _FELIX_INSTR_KLIVE is 1 when a judge is running.
_felix_instr_kstale() {
  local md f c p st stale=""
  _FELIX_INSTR_KLIVE=""
  md="$(_felix_instr_mdir)" || return 0
  [ -e "$md" ] || [ -L "$md" ] || return 0
  if [ ! -d "$md" ] || [ -L "$md" ]; then _felix_instr_knuke "$(_felix_instr_kdir)" && _felix_instr_knuke "$md"; return; fi
  for f in "$md"/* "$md"/.*; do
    case "${f##*/}" in .|..) continue ;; esac
    [ -e "$f" ] || [ -L "$f" ] || continue
    c=""; [ -f "$f" ] && [ ! -L "$f" ] && { IFS= read -r c < "$f"; } 2>/dev/null
    p="${c#felix-instrument-judging }"; st="${p#* }"; p="${p%% *}"
    case "$c" in "felix-instrument-judging "*) ;; *) stale="$stale$f"$'\n'; continue ;; esac
    case "$p" in ''|*[!0123456789]*) stale="$stale$f"$'\n'; continue ;; esac
    if [ "${f##*/}" = "$p" ] && [ -n "$st" ] && [ "$st" != - ] && [ "$(_felix_instr_pstart "$p")" = "$st" ]; then
      _FELIX_INSTR_KLIVE=1
    else stale="$stale$f"$'\n'; fi
  done
  [ -n "$stale" ] || return 0
  _felix_instr_knuke "$(_felix_instr_kdir)" || return 1
  while IFS= read -r f; do [ -z "$f" ] || _felix_instr_knuke "$f" || return 1; done <<EOF
$stale
EOF
  return 0
}
# A19. The markers' directory as it is, from lstat: its identity, mode, owner, size, link count, modification and
# change times to the nanosecond, and how many entries it holds. Writing or removing a marker changes it. "none"
# when there is none, "fail" when it cannot be read.
_felix_instr_mpl='use Time::HiRes (); my $d = $ARGV[0]; my @s = Time::HiRes::lstat($d);
if (!@s) { print $!{ENOENT} ? "none" : "fail"; exit 0 } opendir(my $h, $d) or do { print "fail"; exit 0 };
my $n = grep { $_ ne "." && $_ ne ".." } readdir $h; printf "%s %s %o %s %s %s %.9f %.9f %d", @s[0, 1, 2, 4, 7, 3, 9, 10], $n'
_felix_instr_mst() { local md; md="$(_felix_instr_mdir)" || { printf none; return 0; }; perl -e "$_felix_instr_mpl" "$md" 2>/dev/null || printf fail; }
# A13. The end of a judgement whose first unit or canary started, on every path (its normal end, an exit, a trapped
# signal): A10's sweep, then this judgement kept at its key when KEEP is 1 (the run completed and says something
# about the tree) and the sweep held, and else whatever is kept there removed; then the marker. The marker stays
# when a removal failed, so that no judgement reads a kept judgement while it stays.
_felix_instr_kend() {   # KEEP
  local ok=1 k="${_FELIX_INSTR_KEY:-}"
  [ -n "${_FELIX_INSTR_KRUN:-}" ] || return 0
  _FELIX_INSTR_KRUN=""
  _felix_instr_ksweep "${_FELIX_INSTR_KL0:-none}" || ok=""
  # A19: a judgement that found another running neither keeps itself nor removes what is kept at its key.
  [ -z "${_FELIX_INSTR_KLIVE:-}" ] || [ -z "$ok" ] || k=""
  if [ -n "$k" ] && ! { [ -n "$ok" ] && [ "$1" = 1 ] && _felix_instr_keep "$k"; }; then
    _felix_instr_unkeep "$k" || _felix_instr_knuke "$(_felix_instr_kdir)" || ok=""
  fi
  [ -z "$ok" ] || [ -z "${_FELIX_INSTR_MARK:-}" ] || rm -f "$_FELIX_INSTR_MARK" 2>/dev/null
  _FELIX_INSTR_MARK=""
  return 0
}
# 0, with the receipt's lines added to _FELIX_INSTR_BLOCK, when the home holds KEY's judgement whole.
_felix_instr_kept() {   # KEY
  local f c body sum n l cnt=0 kind subj why m0
  _felix_instr_kstale || return 1
  [ -z "${_FELIX_INSTR_KLIVE:-}" ] || return 1
  m0="$(_felix_instr_mst)"; case "$m0" in none|*" 0") ;; *) _FELIX_INSTR_KLIVE=1; return 1 ;; esac
  f="$(_felix_instr_kfile "$1")" && [ -f "$f" ] || return 1
  _felix_instr_rd c cat "$f" || return 1
  [ "$(_felix_instr_mst)" = "$m0" ] || { _FELIX_INSTR_KLIVE=1; return 1; }
  case "$c" in "felix-instrument-judgement 1"$'\n'"key $1"$'\n'*) ;; *) return 1 ;; esac
  sum="${c##*$'\n'}"; body="${c%$'\n'*}"
  case "$sum" in "sum "?*) ;; *) return 1 ;; esac
  [ "${sum#sum }" = "$(printf '%s' "$body" | git hash-object --stdin 2>/dev/null)" ] || return 1
  n="${body##*$'\n'}"
  case "$n" in "count "*) n="${n#count }" ;; *) return 1 ;; esac
  case "$n" in ''|*[!0123456789]*) return 1 ;; esac
  while IFS= read -r l; do case "$l" in "line "*) cnt=$((cnt + 1)) ;; esac; done <<EOF
$body
EOF
  [ "$cnt" = "$n" ] || return 1
  while IFS= read -r l; do
    case "$l" in "line "*) ;; *) continue ;; esac
    IFS=$'\t' read -r kind subj why <<EOF
${l#line }
EOF
    [ -n "$kind" ] && [ -n "$subj" ] && _felix_instr_add "$kind" "$subj" "$why"
  done <<EOF
$body
EOF
  return 0
}
# The judgement just made, kept for KEY: S8's lines, the partition's left out. Never fatal, and never partial: it
# is written beside the receipt and moved over it. 1 when it was not kept (an unknown line, or a write that failed).
_felix_instr_keep() {   # KEY
  local f body l n=0
  f="$(_felix_instr_kfile "$1")" || return 1
  body="felix-instrument-judgement 1"$'\n'"key $1"
  while IFS= read -r l; do
    case "$l" in ''|escape$'\t'projects/*/partition.tsv$'\t'*) continue ;; unknown$'\t'*) return 1 ;; esac
    body="$body"$'\n'"line $l"; n=$((n + 1))
  done <<EOF
$_FELIX_INSTR_BLOCK
EOF
  body="$body"$'\n'"count $n"
  mkdir -p "${f%/*}" 2>/dev/null || return 1
  { printf '%s\nsum %s\n' "$body" "$(printf '%s' "$body" | git hash-object --stdin 2>/dev/null)" > "$f.$$.t" \
      && mv -f "$f.$$.t" "$f"; } 2>/dev/null && return 0
  rm -f "$f.$$.t" 2>/dev/null; return 1
}
