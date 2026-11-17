# >>> land-on-green-round-6
printf '\nland on green: the amendment A29 (contract A29, blind)\n'
# Blind, from the contract's "Amended after the record of 2026-10-16" alone, on
# the fixture parts 1280-1285 build: lib/resolve.sh, lib/green-tick.sh,
# lib/green-install.sh and the felix CLI were not read. main's check is run as
# 1282's _la_accepts runs it, and the tick as every land part runs it.
#
# The race is made certain, not likely. A git first on PATH runs the real git
# for everything but archive. For archive it writes the real archive, waits
# half a second, then writes git's trailing padding again: zero bytes, 1 MiB of
# them, more than any pipe holds. A reader that reads to the end takes them and
# the write succeeds. A reader that stopped at the end-of-archive marker has
# left, or leaves while the write is blocked, and the write dies of SIGPIPE
# whatever the timing. The stub's status is that write's, as a real git
# archive's would be. Given -o FILE (or --output), it appends the padding to
# FILE, where no race exists. ctl/archive.fail makes it fail instead: exit 128
# after writing nothing ("nothing") or the archive's first 1024 bytes ("part").
# Each archive call is logged to log/archive.log as where<TAB>mode.
_lg_build amend
L7="$LG/round7"; mkdir -p "$L7"
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1
L7V="$(_l3_mainv)"; [ -n "$L7V" ] && _lg_cache "$L7V"
rm -f "$LGB/git"; _lg_reset
is "the land fixture: the home is on main at origin's main, main declares a version, and main's check accepts that entry with the real git (fixture control)" \
   "$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" rev-parse --abbrev-ref HEAD 2>&1)|$([ -n "$L7V" ] && echo v)|$(_la_accepts)" \
   "$(git -C "$LGO" rev-parse main 2>&1)|main|v|0"

_lg_put "$L7/git" <<'LGSTUB'
#!/bin/bash
LG='@LG@'; RG="$(cat "$LG/amend/realgit")"; s=""; k=""; d="$PWD"
for a in "$@"; do
  if [ -n "$k" ]; then
    [ "$k" = C ] && case "$a" in /*) d="$a" ;; *) d="$d/$a" ;; esac
    k=""; continue
  fi
  case "$a" in -C) k=C ;; -c|--git-dir|--work-tree|--namespace|--config-env) k=1 ;; -*) ;; *) s="$a"; break ;; esac
done
# 2026-10-18 (judge refs, Part C): main's check no longer runs git archive; it
# lists main's tree with ls-tree. The stub stands in for that listing too: a
# listing that fails (exit 128, nothing or a short read) is a check that exits 2,
# and the call is logged where the archive calls are.
case "$s" in
  archive) ;;
  ls-tree)
    f="$(cat "$LG/ctl/archive.fail" 2>/dev/null)"
    printf 'stdout\t%s\n' "${f:-pass}" >> "$LG/log/archive.log"
    if [ -n "$f" ]; then
      [ "$f" != part ] || "$RG" "$@" 2>/dev/null | head -c 20
      echo "fatal: the tree could not be read" >&2; exit 128
    fi
    exec "$RG" "$@" ;;
  *) exec "$RG" "$@" ;;
esac
o=""; p=""
for a in "$@"; do
  case "$p" in -o|--output) o="$a" ;; esac
  case "$a" in --output=*) o="${a#--output=}" ;; -o?*) o="${a#-o}" ;; esac
  p="$a"
done
case "$o" in ""|/*) ;; *) o="$d/$o" ;; esac
f="$(cat "$LG/ctl/archive.fail" 2>/dev/null)"; w=stdout; [ -n "$o" ] && w=file
printf '%s\t%s\n' "$w" "${f:-pad}" >> "$LG/log/archive.log"
if [ -n "$f" ]; then
  t="$LG/round7/whole.$$"
  if [ -n "$o" ]; then "$RG" "$@" 2>/dev/null; /bin/mv -f "$o" "$t" 2>/dev/null; else "$RG" "$@" > "$t" 2>/dev/null; fi
  if [ -n "$o" ]; then { [ "$f" != part ] || head -c 1024 "$t"; } > "$o"
  elif [ "$f" = part ]; then head -c 1024 "$t"; fi
  rm -f "$t"; echo "fatal: the archive could not be written" >&2; exit 128
fi
"$RG" "$@" || exit $?
sleep 0.5
if [ -n "$o" ]; then head -c 1048576 /dev/zero >> "$o"; else head -c 1048576 /dev/zero; fi
exit $?
LGSTUB
_l7_on() { cp "$L7/git" "$LGB/git" && chmod +x "$LGB/git"; }
_l7_acc() { ( set -o pipefail; PATH="$LGB:$PATH"; _la_accepts ); }   # main's check, the stub first on PATH: its status
_l7_plain() {   # -> the status of git archive | tar -x under pipefail, the stub first on PATH
  rm -rf "$L7/x"; mkdir -p "$L7/x"
  ( set -o pipefail; PATH="$LGB:$PATH"
    _fx_git "$LGH" archive refs/remotes/origin/main engine/harness | tar -x -C "$L7/x" -f - ) >/dev/null 2>&1
  echo "$?"
}

# ------------------------------------------------------ the stub, checked ---
_l7_on
_l7o=""; for _l7k in 1 2 3; do [ "$(_l7_plain)" = 0 ] && _l7o="$_l7o pass" || _l7o="$_l7o fail"; done
is "the land fixture: with the stub, git archive | tar -x under pipefail fails on each of three runs, the defect A29 records (fixture control)" \
   "$_l7o" " fail fail fail"
rm -f "$L7/whole.tar"
_l7r="$( ( set -o pipefail; PATH="$LGB:$PATH"
  _fx_git "$LGH" archive refs/remotes/origin/main engine/harness | cat > "$L7/whole.tar" ) >/dev/null 2>&1; echo "$?")"
is "the land fixture: with the stub, a reader that reads to the end gets main's engine whole, and the pipeline exits 0 (fixture control)" \
   "$_l7r|$(tar -tf "$L7/whole.tar" 2>/dev/null | LC_ALL=C grep -cx 'engine/harness/lib/resolve.sh')" "0|1"
rm -f "$L7/o.tar"
( PATH="$LGB:$PATH"; _fx_git "$LGH" archive -o "$L7/o.tar" refs/remotes/origin/main engine/harness ) >/dev/null 2>&1; _l7r=$?
is "the land fixture: with the stub, git archive -o FILE writes main's engine whole to FILE, its padding appended, and exits 0 (fixture control)" \
   "$_l7r|$(tar -tf "$L7/o.tar" 2>/dev/null | LC_ALL=C grep -cx 'engine/harness/lib/resolve.sh')|$([ "$(wc -c < "$L7/o.tar" 2>/dev/null | tr -d ' ')" -gt 1048576 ] 2>/dev/null && echo padded)" \
   "0|1|padded"
rm -f "$L7/whole.tar" "$L7/o.tar"; rm -rf "$L7/x"

# ------------------------------------------------ A29: main's check, whole ---
rm -f "$LGL/archive.log"; _l7o=""
for _l7k in 1 2 3; do _l7o="$_l7o $(_l7_acc)"; done
is "the land fixture: with the stub on PATH, main's check ran git archive through it (fixture control)" \
   "$([ "$(_lg_cnt archive)" -ge 1 ] && echo yes)" "yes"
is "A29: with git archive writing past the end-of-archive marker after its reader stops, main's check exits 0 for main's entry, on each of three runs" \
   "$_l7o" " 0 0 0"

printf 'stray\n' > "$LGV/$L7V/harness/a29-stray.sh"
rm -f "$LGB/git"
is "the land fixture: with a stray file in main's entry, main's check rejects it with the real git (fixture control)" "$(_la_accepts)" "1"
_l7_on
is "A29: with the stub, an entry that differs from main still exits 1: a reader that stops early never turns a difference into a pass" \
   "$(_l7_acc)" "1"
rm -f "$LGV/$L7V/harness/a29-stray.sh"

_l7_fail() {   # MODE WHAT -> git archive exits 128 having written MODE: main's check exits 2
  printf '%s\n' "$1" > "$LGK/archive.fail"
  is "A29: with git archive failing (exit 128) having written $2, main's check exits 2, never 0" "$(_l7_acc)" "2"
  rm -f "$LGK/archive.fail"
}
_l7_fail nothing "nothing"
_l7_fail part "the first 1024 bytes of the archive"

# ---------------------------------------------------- A29: a tick, a verify ---
rm -f "$LGB/git"; _lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; _lg_land --tick
is "the land fixture: with the real git, a tick lands green 42 and owes no deploy (fixture control)" \
   "$(_lg_n landed 42)|$(_lg_merges)|$(_lg_n deploy-owed)|$(_lg_n deployed)|$(( $(_lg_n deploy-failed) + $(_lg_n deployed-unverified) ))" "1|b42|0|0|0"
_l7_on; _lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; _lg_land --tick
is "the land fixture: the tick ran git archive through the stub (fixture control)" \
   "$([ "$(_lg_cnt archive)" -ge 1 ] && echo yes)" "yes"
is "A29: with the stub, a tick finds main's entry accepted and lands green 42" "$LGRC|$(_lg_n landed 42)|$(_lg_merges)" "0|1|b42"
is "A29: and writes no deploy-owed, deployed or deploy-failed row" \
   "$(_lg_n deploy-owed)|$(_lg_n deployed)|$(( $(_lg_n deploy-failed) + $(_lg_n deployed-unverified) ))" "0|0|0"
is "A29: and pauses nothing" "$([ -e "$LAND/paused" ] && echo paused)" ""

# A deploy owed because main's entry is gone: its verify asks main's check too.
rm -rf "$LGV/$L7V"; _lg_reset; _lg_land --tick
is "A29: with the stub, a deploy's verify accepts the entry just installed: one deployed row, no deploy-failed row" \
   "$(_lg_n deployed)|$(( $(_lg_n deploy-failed) + $(_lg_n deployed-unverified) ))" "1|0"
is "A29: and the deploy pauses nothing" "$([ -e "$LAND/paused" ] && echo paused)" ""

rm -f "$LGB/git"; _lg_cache "$L7V"; _lg_reset; rm -rf "$L7"
is "the land fixture: the stub is gone, and main's check accepts main's entry again (fixture control)" \
   "$([ -e "$LGB/git" ] && echo stub)|$(_la_accepts)" "|0"
