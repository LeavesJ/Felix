# P's instrument parts judge the candidate (trust-plane step 3, slice 3).
#
# The spec is in the memory root, audits/2026-11-08-trust-plane-step3/spec-slice3.md, with its section 4, the
# amendments after the first build's review (A1 to A7), its section 5, after fault round 1 (A8 to A11), and its
# section 6, after fault round 2 (A12 to A18). Slices 1 and 2 (policy.sh, bind.sh) moved the tables, their
# instruments and the commit they are read at to P.
# This file is about the suite that judges Felix's own engine, which was the candidate's: a candidate supplied the
# instrument that judged it. Members of that class found so
# far, as examples and not the set: a part's assertion loosened, renamed or deleted; a part deleted, or no longer
# sourced by the driver; a helper's body in tests/run or tests/lib changed so that bad() passes; gate.sh or a
# workflow run differently; the partition table moving a part to subject.
#
# THE RULE (spec S7, S8, A1-A7), for Felix's own repository only (felix_self_governed_at), called by cmd_merge after
# slice 2's binding and only when no blocker of kind base, moved, objects, policy or unknown stands.
#   - A1: what is judged is what the squash lands, M: the tree _felix_merge_refs (resolve.sh) writes when the base
#     has moved since the branch was cut, read through the checked copy, and H's tree when it has not. A merge that
#     conflicts or cannot be read is unknown SUITE. Every comparison below is B against M, and T is built from M.
#   - S7, A6: which parts are subject is read from P's projects/<name>/partition.tsv (the name is B's .felix). A
#     part is subject in a table only when every row naming it says so, and a table that cannot be read whole marks
#     nothing subject (D28). A part M's table resolves to subject and P's does not is one escape line.
#   - S8.1: an instrument part is changed when M lacks it, holds other bytes for it, or M's driver does not source it.
#   - S8.4, A2, A3: the machinery is every path under engine/harness/tests/ but the part files and the two records
#     (assertions.tsv, red.tsv), plus the project's gate.sh and .github/workflows/. The driver is compared without
#     its blank lines and its part lines, a part line being exactly `. "$HERE/parts/<name>"`. A changed prelude part
#     (0001 to 0009, 9990), which no unit runs and every unit sources, counts as the machinery.
#   - S8.2, S8.3, S8.5: the units and the canary (instrument-run.sh runs them, instrument-verdict.sh reads them).
#     A5: the judgement of a machinery change is kept in the home's state (instrument-keep.sh), read for its key.
#   - A7.1: a git read that fails is unknown SUITE, never an absent file. A7.7, A8: every input the verdict reads is
#     read before any unit, into the judge's memory, never again from a file. A9: a signal at any point removes the
#     run (instrument-run.sh). A10: the units cannot read the home, and what they could write there is not used.
#   - A12: the canary's copy is made only after the last unit has ended, and P's files in T, listed before the first
#     unit, are listed again after the last: any difference is unknown SUITE. A13: every end of a judgement sweeps
#     the kept judgements, behind a marker a later judgement reads (instrument-keep.sh). A14, A15, A17: where the run
#     lives, what a unit is given as TMPDIR and HOME, and its removal after a KILL (instrument-run.sh).
#
# WHAT THIS DOES NOT BIND, as examples and not the set (spec section 3, section 4's still open, A13's open list): a
# part's body weakened under the same name; machinery that lies only for some names or outside part mode, or that
# knows the canary by its shape; the candidate's code redefining P's helpers, or writing into the unit's log, inside
# P's run; a stale manifest H keeps names in (S8.3 counts H's manifest); the gate and CI, which still run the
# candidate's suite; a unit that outlives its process group, or finds the records or the home by their paths, or
# removes the marker and then KILLs the judge (E4, R1); a part that tests where it runs in a way A17's layout does not
# reproduce (the checkout as a linked worktree, or under HOME, for two).
#
# Sourced by escape.sh and by felix beside bind.sh. Reads through bind.sh's copy when one is set.

# Set only here, in the shell that merges: an inherited value names no run directory and no verdict.
unset _FELIX_INSTR_BLOCK _FELIX_INSTR_NOTE _FELIX_INSTR_J _FELIX_INSTR_R _FELIX_INSTR_OWNER _FELIX_INSTR_SUB
unset _FELIX_INSTR_U _FELIX_INSTR_INST _FELIX_INSTR_CHG _FELIX_INSTR_TP _FELIX_INSTR_MT _FELIX_INSTR_WHY
unset _FELIX_INSTR_KEEP _FELIX_INSTR_T0 _FELIX_INSTR_BASE _FELIX_INSTR_CANARY _FELIX_INSTR_CID _FELIX_INSTR_RB _FELIX_GRP
unset _FELIX_INSTR_UD _FELIX_INSTR_RC _FELIX_INSTR_MAN _FELIX_INSTR_CEXP _FELIX_INSTR_REACHED _FELIX_INSTR_ULIM _FELIX_INSTR_UP
unset _FELIX_INSTR_HP _FELIX_INSTR_UT _FELIX_INSTR_TB _FELIX_INSTR_WD _FELIX_INSTR_PROBE _FELIX_INSTR_KRUN _FELIX_INSTR_KEY
unset _FELIX_INSTR_KL0 _FELIX_INSTR_MARK _FELIX_INSTR_CPART _FELIX_INSTR_CDRV _FELIX_INSTR_CDMODE _FELIX_INSTR_CID

# One blocker line into _FELIX_INSTR_BLOCK, once: KIND SUBJECT REASON. In each field a tab or newline becomes a blank,
# and (A22, A23, after the automated security reviews of 6ab2d37e and 7ccb545e) a control or format character (C0, DEL,
# C1, Unicode Cf such as a bidirectional override) or a byte that is not UTF-8 is written as \xNN, its bytes, so
# nothing a name in the tree holds reaches a terminal raw. Text that is printable UTF-8 is left as it is.
_felix_instr_addpl='use Encode (); my @f; for (@ARGV) { my $s = $_; $s =~ tr/\t\n/  /; my $o = "";
  while (length $s) { my $u = Encode::decode("UTF-8", $s, Encode::FB_QUIET);
    $u =~ s/([\p{Cc}\p{Cf}])/join("", map { sprintf "\\x%02x", $_ } unpack "C*", Encode::encode("UTF-8", $1))/ge;
    $o .= Encode::encode("UTF-8", $u); $o .= sprintf "\\x%02x", ord substr($s, 0, 1, "") if length $s }
  push @f, $o } print join("\t", @f)'
_felix_instr_add() {
  local l
  l="$(perl -e "$_felix_instr_addpl" -- "$1" "$2" "$3" 2>/dev/null)" \
    || l="$(printf '%s\t%s\t%s' "${1//[$'\t\n']/ }" "${2//[$'\t\n']/ }" "${3//[$'\t\n']/ }" | LC_ALL=C tr '\001-\010\013-\037\177-\377' '?')"
  case $'\n'"$_FELIX_INSTR_BLOCK"$'\n' in *$'\n'"$l"$'\n'*) return 0 ;; esac
  _FELIX_INSTR_BLOCK="${_FELIX_INSTR_BLOCK:+$_FELIX_INSTR_BLOCK$'\n'}$l"
}
_felix_instr_in() { case $'\n'"$1"$'\n' in *$'\n'"$2"$'\n'*) return 0 ;; esac; return 1; }   # LIST NAME

# A7.1. VAR is what the command printed, its trailing newlines cut; 0 only when it ran to the end and exited 0. A
# capture whose fork failed is empty with status 128 (bash 3.2), which is why the mark is printed after the command.
_felix_instr_rd() {   # VAR command...
  local _fi_o
  _fi_o="$("${@:2}" 2>/dev/null </dev/null && printf '\n\037ok')"
  case "$_fi_o" in *$'\n\037ok') _fi_o="${_fi_o%$'\n\037ok'}" ;; *) printf -v "$1" '%s' ""; return 1 ;; esac
  while case "$_fi_o" in *$'\n') true ;; *) false ;; esac; do _fi_o="${_fi_o%$'\n'}"; done
  printf -v "$1" '%s' "$_fi_o"
}
# A listing (ls-tree -r) -> the object id of the blob at PATH, or nothing when there is none.
_felix_instr_sha() {   # LISTING PATH
  printf '%s\n' "$1" | LC_ALL=C awk -v p="$2" '{ t = index($0, "\t"); if (!t || substr($0, t + 1) != p) next
    split(substr($0, 1, t - 1), m, " "); if (m[2] == "blob") { print m[3]; exit } }'
}
# VAR is the text of PATH in LISTING (empty when the listing holds no such file). 1 when the read failed, and 2
# when the file holds a NUL byte, which a shell variable cannot (bash drops it): the bytes are then not the text.
_felix_instr_text() {   # VAR ROOT LISTING PATH
  local _fi_s _fi_o _fi_n
  _fi_s="$(_felix_instr_sha "$3" "$4")"
  [ -n "$_fi_s" ] || { printf -v "$1" '%s' ""; return 0; }
  _felix_instr_rd _fi_n git -C "$2" cat-file -s "$_fi_s" || return 1
  _fi_o="$(git -C "$2" cat-file blob "$_fi_s" 2>/dev/null </dev/null && printf '\037ok')"
  case "$_fi_o" in *$'\037ok') _fi_o="${_fi_o%$'\037ok'}" ;; *) return 1 ;; esac
  printf -v "$1" '%s' "$_fi_o"
  [ "$(LC_ALL=C; printf '%s' "${#_fi_o}")" = "$_fi_n" ] || return 2
}
# A blob of LISTING written to FILE, exactly; an empty file when there is none. 1 when the read failed.
_felix_instr_tofile() {   # ROOT LISTING PATH FILE
  local s; s="$(_felix_instr_sha "$2" "$3")"
  [ -n "$s" ] || { : > "$4"; return; }
  git -C "$1" cat-file blob "$s" > "$4" 2>/dev/null </dev/null
}

# The parts a driver sources (stdin), as tests/run's own _sj_order reads them, part file names only.
_felix_instr_sourced() {
  LC_ALL=C awk 'index($0, ". \"$HERE/parts/") == 1 && length($0) > 16 && substr($0, length($0)) == "\"" {
    n = substr($0, 16, length($0) - 16); if (n ~ /^[abcdefghijklmnopqrstuvwxyz0123456789.-]+$/) print n }'
}
# A2. A driver (stdin) without its blank lines and its part lines, exactly the lines _felix_instr_sourced reads.
_felix_instr_strip() {
  LC_ALL=C awk '$0 == "" { next }
    index($0, ". \"$HERE/parts/") == 1 && length($0) > 16 && substr($0, length($0)) == "\"" {
      n = substr($0, 16, length($0) - 16); if (n ~ /^[abcdefghijklmnopqrstuvwxyz0123456789.-]+$/) next }
    { print }'
}
# S7, A6. The parts a partition (stdin) marks subject: every row naming the part says subject, and nothing when a
# line is not part<TAB>class<TAB>why. One rule for P's table and M's.
_felix_instr_subjects() {
  LC_ALL=C awk -F'\t' '
    /^#/ || /^[[:space:]]*$/ { next }
    NF < 3 || $1 == "" { bad = 1; next }
    { s = ($2 == "subject"); if (!($1 in c)) { o[++n] = $1; c[$1] = s } else if (!s) c[$1] = 0 }
    END { if (bad) exit 0; for (i = 1; i <= n; i++) if (c[o[i]]) print o[i] }'
}
# A listing (stdin) -> NAME SHA for each blob directly under PREFIX.
_felix_instr_under() {   # PREFIX
  LC_ALL=C awk -v pre="$1" '{ t = index($0, "\t"); if (!t) next; path = substr($0, t + 1); split(substr($0, 1, t - 1), m, " ")
    if (m[2] != "blob" || index(path, pre) != 1) next; n = substr(path, length(pre) + 1); if (n !~ /\//) print n " " m[3] }'
}
# A listing (stdin) -> its lines for the suite, the gate and the workflows (MODE all), or for the machinery other
# than the driver (MODE mach, A3: everything under TESTS-DIR but run, the part files and the two records).
_felix_instr_paths() {   # MODE TESTS-DIR GATE-PATH
  LC_ALL=C awk -v md="$1" -v tp="$2/" -v gp="$3" '{ t = index($0, "\t"); if (!t) next; p = substr($0, t + 1)
    split(substr($0, 1, t - 1), m, " ")
    if (index(p, tp) == 1) { r = substr(p, length(tp) + 1)
      if (md == "mach" && (r == "run" || r == "assertions.tsv" || r == "red.tsv")) next
      if (md == "mach" && m[2] == "blob" && index(r, "parts/") == 1 && substr(r, 7) !~ /\//) next
      print; next }
    if ((gp != "" && p == gp) || index(p, ".github/workflows/") == 1) print }'
}
# P's units, from stdin: @G, then P's groups.tsv, then @S, then P's sourced parts in its order. One a line, members
# blank-separated, the prelude parts and 9990 left out, as tests/run's _sj_mkunits makes them.
_felix_instr_units() {
  LC_ALL=C awk '$0 == "@G" || $0 == "@S" { sec = $0; next }
    sec == "@G" { if ($0 ~ /^#/ || $0 == "" || index($0, "\t") == 0) next
                  g[substr($0, index($0, "\t") + 1)] = substr($0, 1, index($0, "\t") - 1); next }
    sec != "@S" || $0 == "" || $0 ~ /^000[0123456789]-/ || $0 ~ /^9990-/ { next }
    { k = ($0 in g) ? "g " g[$0] : "p " $0; if (!(k in at)) { at[k] = ++n }; i = at[k]; u[i] = u[i] (u[i] == "" ? "" : " ") $0 }
    END { for (i = 1; i <= n; i++) print u[i] }'
}

# A1. _FELIX_INSTR_MT is the tree the squash would land: _felix_merge_refs's when it names one, H's when the base
# has not moved since H was cut (it then says nothing, and nothing needs merging). Any other silence is a merge that
# conflicts or could not be made, and returns 1 with _FELIX_INSTR_WHY. _felix_merge_refs merges onto the checkout's
# HEAD, so H must be that HEAD, as cmd_merge's is.
_felix_instr_mtree() {   # ROOT B H
  local root="$1" b="$2" h="$3" hd refs mb
  _FELIX_INSTR_MT=""; _FELIX_INSTR_WHY=""
  _felix_instr_rd hd git -C "$root" rev-parse --verify --quiet 'HEAD^{commit}'
  [ -n "$hd" ] && [ "$hd" = "$h" ] || { _FELIX_INSTR_WHY="the checkout's HEAD (${hd:-none}) is not $h, so what the squash would land cannot be read"; return 1; }
  command -v _felix_merge_refs >/dev/null 2>&1 || { _FELIX_INSTR_WHY="resolve.sh is not loaded, so what the squash would land cannot be read"; return 1; }
  if refs="$(_felix_merge_refs "$root" "$b" 2>/dev/null)"; then
    _FELIX_INSTR_MT="${refs##* }"
    case "$_FELIX_INSTR_MT" in ''|*[!0123456789abcdef]*) _FELIX_INSTR_MT=""; _FELIX_INSTR_WHY="the merge of $h onto $b names no tree"; return 1 ;; esac
    return 0
  fi
  _felix_instr_rd mb git -C "$root" merge-base "$b" "$h" || { _FELIX_INSTR_WHY="$b and $h have no merge base that could be read"; return 1; }
  [ "$mb" = "$b" ] || { _FELIX_INSTR_WHY="the merge of $h onto $b conflicts or could not be made, so there is no tree the squash would land; GitHub would not squash it either"; return 1; }
  _felix_instr_rd _FELIX_INSTR_MT git -C "$root" rev-parse --verify --quiet "$h^{tree}" && [ -n "$_FELIX_INSTR_MT" ] \
    || { _FELIX_INSTR_WHY="the tree of $h could not be read"; return 1; }
}

# The judgement (spec S7, S8, A1-A7). Sets _FELIX_INSTR_BLOCK to the blocker lines it finds and _FELIX_INSTR_NOTE to
# the line felix merge prints when P's suite ran or was read back. Called in the merging shell, never in a
# substitution: the signal traps it sets for the run are this shell's. Returns 0.
felix_instrument_judge() {   # ROOT B H BRANCH
  local root="$1" b="$2" h="$3" br="$4" tp=engine/harness/tests mt lb lm bname="" pdir="" gp="" sp="" sm="" p k
  local drb="" drm="" grp="" srcp srch pp hp plan mach=0 units nu=0 m hasc unread="" rc x key="" wt=0 wc=0 tl0="" ran=""
  _FELIX_INSTR_BLOCK=""; _FELIX_INSTR_NOTE=""; _FELIX_INSTR_TP="$tp"; _FELIX_INSTR_U=(); _FELIX_INSTR_SUB=()
  _FELIX_INSTR_INST=""; _FELIX_INSTR_CHG=""; _FELIX_INSTR_KEEP=1; _FELIX_INSTR_CANARY=""; _FELIX_INSTR_MAN=""
  _FELIX_INSTR_CEXP=""; _FELIX_INSTR_REACHED=""; _FELIX_INSTR_UD=(); _FELIX_INSTR_RC=()
  _FELIX_INSTR_KRUN=""; _FELIX_INSTR_KEY=""; _FELIX_INSTR_KL0=""; _FELIX_INSTR_MARK=""; _FELIX_INSTR_CPART=""; _FELIX_INSTR_CDRV=""
  _FELIX_INSTR_KLIVE=""
  _felix_instr_mtree "$root" "$b" "$h" || { _felix_instr_add unknown SUITE "$_FELIX_INSTR_WHY"; return 0; }
  mt="$_FELIX_INSTR_MT"
  _felix_instr_rd lb git -C "$root" -c core.quotePath=false ls-tree -r --full-tree "$b" -- .felix projects "$tp" .github/workflows \
    && _felix_instr_rd lm git -C "$root" -c core.quotePath=false ls-tree -r --full-tree "$mt" -- .felix projects "$tp" .github/workflows \
    || { _felix_instr_add unknown SUITE "the trees of $b and of what the squash would land ($mt) could not be listed"; return 0; }
  _felix_instr_text bname "$root" "$lb" .felix || { _felix_instr_add unknown SUITE "$b's .felix could not be read, so its project is not known"; return 0; }
  bname="$(printf '%s\n' "$bname" | LC_ALL=C sed -n '1{s/[[:space:]]//g;p;}')"
  case "$bname" in ''|*/*|.|..) bname="" ;; esac
  if [ -n "$bname" ] && printf '%s\n' "$lb" | LC_ALL=C awk -v p="projects/$bname/" 'index($0, "\t" p) { f = 1 } END { exit !f }'; then
    pdir="projects/$bname"; gp="$pdir/gate.sh"
  fi
  # S7, A6: a part M's table marks subject and P's does not.
  if [ -n "$pdir" ]; then
    _felix_instr_text sp "$root" "$lb" "$pdir/partition.tsv"; rc=$?
    [ "$rc" -ne 1 ] && { _felix_instr_text sm "$root" "$lm" "$pdir/partition.tsv"; [ "$?" -ne 1 ]; } \
      || { _felix_instr_add unknown SUITE "the partition $pdir/partition.tsv could not be read at $b or in what the squash would land"; return 0; }
    sp="$(printf '%s\n' "$sp" | _felix_instr_subjects)"; sm="$(printf '%s\n' "$sm" | _felix_instr_subjects)"
    while IFS= read -r p; do
      [ -n "$p" ] && ! _felix_instr_in "$sp" "$p" && _felix_instr_add escape "$pdir/partition.tsv" "marks $p subject"
    done <<EOF
$sm
EOF
  fi
  # S8.7: P holds no suite, or nothing an instrument holds changed: nothing runs and nothing is made.
  printf '%s\n' "$lb" | LC_ALL=C awk -v p="$tp/" 'index($0, "\t" p) { f = 1 } END { exit !f }' || return 0
  [ "$(printf '%s\n' "$lb" | _felix_instr_paths all "$tp" "$gp")" != "$(printf '%s\n' "$lm" | _felix_instr_paths all "$tp" "$gp")" ] || return 0
  # S8.9: an input that cannot be read is an unknown, not a founder decision.
  [ -n "$(_felix_instr_sha "$lb" "$tp/run")" ] || {
    _felix_instr_add unknown SUITE "P's driver $tp/run is not a file at $b, so nothing says which parts P sources and none of them was run"; return 0; }
  _felix_instr_text drb "$root" "$lb" "$tp/run"; [ "$?" -ne 1 ] || { _felix_instr_add unknown SUITE "P's driver $tp/run could not be read at $b"; return 0; }
  _felix_instr_text drm "$root" "$lm" "$tp/run"; rc=$?
  [ "$rc" -ne 1 ] || { _felix_instr_add unknown SUITE "the driver $tp/run could not be read in what the squash would land"; return 0; }
  [ "$rc" -ne 2 ] || mach=1
  _felix_instr_text grp "$root" "$lb" "$tp/groups.tsv"; [ "$?" -ne 1 ] || { _felix_instr_add unknown SUITE "P's $tp/groups.tsv could not be read at $b"; return 0; }
  srcp="$(printf '%s\n' "$drb" | _felix_instr_sourced)"; srch="$(printf '%s\n' "$drm" | _felix_instr_sourced)"
  pp="$(printf '%s\n' "$lb" | _felix_instr_under "$tp/parts/")"; hp="$(printf '%s\n' "$lm" | _felix_instr_under "$tp/parts/")"
  # S0, S8.1: I instrument, C changed, U sourced by P and not a file at B.
  plan="$(printf '@PP\n%s\n@HP\n%s\n@SU\n%s\n@SH\n%s\n@SP\n%s\n' "$pp" "$hp" "$sp" "$srch" "$srcp" | LC_ALL=C awk '
    /^@/ { sec = $0; next } $0 == "" { next }
    sec == "@PP" { ps[$1] = $2; next } sec == "@HP" { hs[$1] = $2; next }
    sec == "@SU" { su[$0] = 1; next } sec == "@SH" { sh[$0] = 1; next }
    sec == "@SP" && !($0 in seen) { seen[$0] = 1; if ($0 in su) next; print "I\t" $0
      if (!($0 in ps)) print "U\t" $0; else if (!($0 in hs) || hs[$0] != ps[$0] || !($0 in sh)) print "C\t" $0 }')"
  while IFS=$'\t' read -r k p; do
    case "$k" in
      I) _FELIX_INSTR_INST="${_FELIX_INSTR_INST:+$_FELIX_INSTR_INST$'\n'}$p" ;;
      C) _FELIX_INSTR_CHG="${_FELIX_INSTR_CHG:+$_FELIX_INSTR_CHG$'\n'}$p"
         case "$p" in 000[0123456789]-*|9990-*) mach=1 ;; esac ;;
      U) unread=1; _felix_instr_add unknown SUITE "P's driver sources $tp/parts/$p, which is not a file at $b, so P's version of it cannot be read" ;;
    esac
  done <<EOF
$plan
EOF
  [ -z "$unread" ] || return 0
  # S8.4, A2, A3: the machinery, compared between B and M; the driver without its blank lines and part lines.
  [ "$(printf '%s\n' "$lb" | _felix_instr_paths mach "$tp" "$gp")" = "$(printf '%s\n' "$lm" | _felix_instr_paths mach "$tp" "$gp")" ] || mach=1
  [ -n "$(_felix_instr_sha "$lm" "$tp/run")" ] || mach=1
  [ "$(printf '%s\n' "$drb" | _felix_instr_strip)" = "$(printf '%s\n' "$drm" | _felix_instr_strip)" ] || mach=1
  # S8.2: the units that run, in P's driver order.
  units="$(printf '@G\n%s\n@S\n%s\n' "$grp" "$srcp" | _felix_instr_units)"
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    hasc=""; for m in $k; do
      if [ "$mach" = 1 ]; then _felix_instr_in "$_FELIX_INSTR_INST" "$m" && hasc=1
      else _felix_instr_in "$_FELIX_INSTR_CHG" "$m" && hasc=1; fi
    done
    [ -z "$hasc" ] || { nu=$((nu + 1)); _FELIX_INSTR_U[nu]="$k"; }
  done <<EOF
$units
EOF
  [ "$nu" -gt 0 ] || [ "$mach" = 1 ] || return 0
  # A5: the judgement of a machinery change, kept for B, M and the engine that judges, is read instead of run.
  if [ "$mach" = 1 ] && command -v _felix_instr_kept >/dev/null 2>&1; then
    key="$(_felix_instr_key "$b" "$mt")"
    if [ -n "$key" ] && _felix_instr_kept "$key"; then
      _FELIX_INSTR_NOTE="P's instrument parts were not run again: this engine's judgement of what the squash would land, at this base, is kept in the home's state, and its lines are read from there."
      return 0
    fi
  fi
  # A7.5, A7.7, A7.6, A8: the directories, every input the verdict reads (into memory: the manifest here, the
  # canary's expected lines, part and driver in its preparation), then T, before any unit.
  if ! felix_instr_dirs "$root"; then
    trap - TERM INT HUP QUIT
    if command -v _felix_bind_traps >/dev/null 2>&1; then _felix_bind_traps; else trap - EXIT; fi
    return 0
  fi
  [ "$nu" -eq 0 ] || wt=1
  _felix_instr_text _FELIX_INSTR_MAN "$root" "$lm" "$tp/assertions.tsv"; rc=$?
  if [ "$rc" -ne 0 ] || ! { [ "$mach" != 1 ] || _felix_instr_canary_prep "$root" "$lb" "$lm" "$tp"; }; then
    _felix_instr_add unknown SUITE "what the verdict reads (the manifest of what the squash would land, P's canary or the driver it runs under) could not be read"
  elif [ "$wt" = 1 ] && ! _felix_instr_build "$root" "$mt" "$b" "$h" "$gp" "$br" "$lb" 1 0; then
    _felix_instr_add unknown SUITE "the run tree T could not be made from what the squash would land and $b under $_FELIX_INSTR_TB${_FELIX_INSTR_TWHY:+ (A22, A23: $_FELIX_INSTR_TWHY)}"
  else
    [ "$mach" != 1 ] || [ "$_FELIX_INSTR_CANARY" = no ] || wc=1
    # A10, A13: the kept judgements as they stand before the first unit, in memory, and this judgement's marker.
    if [ "$wt" = 1 ] || [ "$wc" = 1 ]; then
      _FELIX_INSTR_KEY="$key"; _FELIX_INSTR_KL0="$(_felix_instr_klist)"; _FELIX_INSTR_KRUN=1; ran=1
      _felix_instr_mark || { wt=0; wc=0; _FELIX_INSTR_KEEP=""
        _felix_instr_add unknown SUITE "the marker of a running judgement could not be written into the home's state, so nothing would show a later judgement what its units could have left there; none was run"; }
    fi
    if [ "$wt" = 1 ]; then
      # A12: P's files in T, before the first unit and after the last.
      tl0="$(_felix_instr_tlist "$_FELIX_INSTR_J/t" "$tp" ${gp:+"$gp"} .github/workflows)"
      # Its stderr, and the canary's and the removal's, is the void: bash reports there a supervisor a unit killed.
      _felix_instr_runall "$(_felix_instr_jobs)" "$_FELIX_INSTR_J/t" "$nu" 2>/dev/null
      x=1; while [ "$x" -le "$nu" ]; do _felix_instr_verdict "$x"; x=$((x + 1)); done
      _felix_instr_names
      x="$(_felix_instr_tlist "$_FELIX_INSTR_J/t" "$tp" ${gp:+"$gp"} .github/workflows)"
      [ "$x" = "$tl0" ] || _felix_instr_add unknown SUITE "P's instrument changed in the run tree while its units ran ($(_felix_instr_tdiff "$tl0" "$x")), so what ran is not P's"
    fi
    # A12: the canary's copy is made only now, once the last unit has ended.
    if [ "$wc" = 1 ]; then
      if _felix_instr_build "$root" "$mt" "$b" "$h" "$gp" "$br" "$lb" 0 1; then _felix_instr_canary 2>/dev/null
      else _felix_instr_add unknown SUITE "the canary's copy could not be made from what the squash would land under $_FELIX_INSTR_TB${_FELIX_INSTR_TWHY:+ (A22, A23: $_FELIX_INSTR_TWHY)}"; fi
    fi
  fi
  case $'\n'"$_FELIX_INSTR_BLOCK" in *$'\n'unknown$'\t'*) _FELIX_INSTR_KEEP="" ;; esac
  # A5, A10, A13: kept for its key when the run says something about the tree, after the sweep; else whatever is
  # kept there is removed. A judgement that ran nothing removes what is kept at its key.
  x=""; [ "$mach" = 1 ] && [ -n "$key" ] && [ -n "$_FELIX_INSTR_KEEP" ] && x=1
  if [ -n "$ran" ]; then _felix_instr_kend "$x"
  elif [ "$mach" = 1 ] && [ -n "$key" ] && [ -z "$_FELIX_INSTR_KLIVE" ]; then _felix_instr_unkeep "$key"; fi
  _felix_instr_clean 2>/dev/null
  trap - TERM INT HUP QUIT
  if command -v _felix_bind_traps >/dev/null 2>&1; then _felix_bind_traps; else trap - EXIT; fi
  _FELIX_INSTR_NOTE="P's instrument parts ran over what the squash would land as the base holds them: $nu unit(s) of its suite in part mode"
  [ "$mach" != 1 ] || _FELIX_INSTR_NOTE="$_FELIX_INSTR_NOTE, every instrument unit since this tree changes the machinery, and the canary under this tree's driver"
  _FELIX_INSTR_NOTE="$_FELIX_INSTR_NOTE."
  [ -z "$_FELIX_INSTR_KLIVE" ] || _FELIX_INSTR_NOTE="$_FELIX_INSTR_NOTE Another judgement was running in this home, so what is kept here was not read, and this judgement is not kept."
  return 0
}

# What _felix_merge_refs needs (resolve.sh), the verdicts (instrument-verdict.sh), the runs (instrument-run.sh) and
# the kept judgements (instrument-keep.sh).
if ! command -v _felix_merge_refs >/dev/null 2>&1; then
  # shellcheck source=lib/resolve.sh
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh" 2>/dev/null || :
fi
# shellcheck source=lib/instrument-verdict.sh
. "$(dirname "${BASH_SOURCE[0]:-$0}")/instrument-verdict.sh" 2>/dev/null || :
# shellcheck source=lib/instrument-run.sh
. "$(dirname "${BASH_SOURCE[0]:-$0}")/instrument-run.sh" 2>/dev/null || :
# shellcheck source=lib/instrument-keep.sh
. "$(dirname "${BASH_SOURCE[0]:-$0}")/instrument-keep.sh" 2>/dev/null || :
