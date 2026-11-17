printf '\nb18: felix status names iCloud copies and a home inside an iCloud-synced folder (blind)\n'
# Written blind on 2026-10-24 from docs/2026-10-24-audit-fixes/b18-ledger-reads-dead-hooks-and-icloud-
# dupli.md alone (B15, B16 and A28 to A44), before the fix and without reading lib/status.sh, felix or
# any other engine code. One assertion per contract item, each name beginning with its item. An item
# marked (control) holds before the fix as after it.
#
# Fixtures. Every case is a fresh user home U of its own under $TMP/b18-icloud/cases/<case>/u, and its
# Felix home H (projects/, state/ and a plain .git directory) sits inside U where the case says. CD is
# U/Library/Mobile Documents/com~apple~CloudDocs. felix_icloud_state is called in a fresh bash with
# resolve.sh, ledger.sh and status.sh sourced, HOME=U (or no HOME at all for A37 and A38), FELIX_HOME=H
# and a memory root under cases/, from a working directory under cases/, so whatever a call writes
# anywhere it could lands where A40's find looks. Each call's output is compared with |rc=N after it,
# since B15 says it returns 0. felix status runs with a stub claude and launchctl first on PATH, so it
# can reach no network and no launchd, and reads nothing of the machine's ~/.claude (HOME=U).
#
# Readings, where the contract leaves room: A30 and A32 hold two layouts each, compared as one string;
# A30's two lines are asserted whole, since B15's table fixes them; A35 and A38 assert what they name
# (VALUE and how DETAIL begins or ends); state/held-tree/abc 2 is a directory, the other names files.

B18I="$TMP/b18-icloud"; _ic_c="$B18I/cases"; _ic_a="$B18I/aux"
mkdir -p "$_ic_c/cwd" "$_ic_c/mem" "$_ic_a/bin"
_ic_T="$(printf '\t')"
_ic_C0='no name shaped like an iCloud copy under state/ and .git (objects not read)'
_ic_CU='the scan of state/ and .git could not read every directory, so how many names are shaped like an iCloud copy is not known'
_ic_SN='the home is not inside iCloud Drive or an iCloud-synced Desktop or Documents'
_ic_SU='whether the home is inside an iCloud-synced folder is not known: no home directory to look in'
_ic_SI() { printf 'the home is inside iCloud-synced %s, which renames files Felix writes; a home outside Desktop, Documents and iCloud Drive avoids it' "$1"; }
_ic_CN='name(s) shaped like an iCloud copy under state/ and .git (objects not read): '

_ic_u() { printf '%s/%s/u' "$_ic_c" "$1"; }                               # CASE -> its U
_ic_cd() { printf '%s/Library/Mobile Documents/com~apple~CloudDocs' "$1"; } # U -> CD
_ic_home() { mkdir -p "$1/projects" "$1/state" "$1/.git"; }               # H: a Felix home
_ic_touch() { local h="$1" p; shift; for p in "$@"; do mkdir -p "$h/${p%/*}"; : > "$h/$p"; done; }   # H REL...

# felix_icloud_state H, as "<output>|rc=<status>": U H [nohome]
_ic_prog='. "$1/lib/resolve.sh"; . "$1/lib/ledger.sh"; . "$1/lib/status.sh"
_o="$(felix_icloud_state "$2")"; _r=$?; printf "%s|rc=%s" "$_o" "$_r"'
_ic_run() {
  if [ "${3:-}" = nohome ]; then
    ( cd "$_ic_c/cwd" && env -u HOME -u FELIX_HOME_DIR -u CLAUDE_CONFIG_DIR FELIX_HOME="$2" FELIX_MEMORY="$_ic_c/mem" \
        "$BASH" -c "$_ic_prog" _ic "$FROOT/harness" "$2" ) 2>>"$_ic_a/err"
  else
    ( cd "$_ic_c/cwd" && env -u FELIX_HOME_DIR -u CLAUDE_CONFIG_DIR HOME="$1" FELIX_HOME="$2" FELIX_MEMORY="$_ic_c/mem" \
        "$BASH" -c "$_ic_prog" _ic "$FROOT/harness" "$2" ) 2>>"$_ic_a/err"
  fi
}
_ic_line() { printf '%s\t%s\t%s; %s|rc=0' "$1" "$2" "$3" "$4"; }          # STATE VALUE COPIES SYNCED

# ---- the layouts, all made before the marker ----------------------------------------------------
_ic_U28="$(_ic_u a28)"; _ic_H28="$_ic_U28/plain/fh"; _ic_home "$_ic_H28"
_ic_U29="$(_ic_u a29)"; _ic_H29="$_ic_U29/Documents/fh"; _ic_home "$_ic_H29"
mkdir -p "$(_ic_cd "$_ic_U29")"; ln -s "$_ic_U29/Documents" "$(_ic_cd "$_ic_U29")/Documents"
_ic_U30d="$(_ic_u a30d)"; _ic_H30d="$_ic_U30d/Desktop/fh"; _ic_home "$_ic_H30d"
mkdir -p "$(_ic_cd "$_ic_U30d")"; ln -s "$_ic_U30d/Desktop" "$(_ic_cd "$_ic_U30d")/Desktop"
_ic_U30i="$(_ic_u a30i)"; _ic_H30i="$(_ic_cd "$_ic_U30i")/fh"; _ic_home "$_ic_H30i"
_ic_U31="$(_ic_u a31)"; _ic_home "$_ic_U31/Documents/fh"
mkdir -p "$(_ic_cd "$_ic_U31")"; ln -s "$_ic_U31/Documents" "$(_ic_cd "$_ic_U31")/Documents"
ln -s "$_ic_U31/Documents/fh" "$_ic_U31/lnk"
_ic_U32p="$(_ic_u a32p)"; _ic_H32p="$_ic_U32p/Documents/fh"; _ic_home "$_ic_H32p"
mkdir -p "$(_ic_cd "$_ic_U32p")/Documents"
_ic_U32e="$(_ic_u a32e)"; _ic_H32e="$_ic_U32e/Documents/fh"; _ic_home "$_ic_H32e"
mkdir -p "$_ic_U32e/elsewhere" "$(_ic_cd "$_ic_U32e")"; ln -s "$_ic_U32e/elsewhere" "$(_ic_cd "$_ic_U32e")/Documents"
_ic_U33="$(_ic_u a33)"; _ic_H33="$_ic_U33/Documents/fh"; _ic_home "$_ic_H33"
mkdir -p "$(_ic_cd "$_ic_U33")"; ln -s "$_ic_U33/Documents" "$(_ic_cd "$_ic_U33")/Documents"
_ic_touch "$_ic_H33" 'state/pulse.status 2.tsv' 'state/discover/felix.tsv 3.new' '.git/worktrees/w/index 2' '.git/objects/ab/cd 2'
mkdir -p "$_ic_H33/state/held-tree/abc 2"; : > "$_ic_H33/state/held-tree/abc 2/tree.tsv"
_ic_U34="$(_ic_u a34)"; _ic_H34="$_ic_U34/plain/fh"; _ic_home "$_ic_H34"
_ic_touch "$_ic_H34" 'state/ledger/unknown (2026-08-31 session, not found in transcript search).tsv' \
  'state/v2.tsv' 'state/a2' 'state/x 2y' 'state/b 2.'
_ic_U35="$(_ic_u a35)"; _ic_H35="$_ic_U35/plain/fh"; _ic_home "$_ic_H35"
_ic_touch "$_ic_H35" 'state/a 1' 'state/b 2' 'state/c 3' 'state/d 4' 'state/e 5' 'state/f 6'
_ic_U36="$(_ic_u a36)"; _ic_H36="$_ic_U36/plain/fh"; _ic_home "$_ic_H36"
mkdir -p "$_ic_H36/state/locked"; : > "$_ic_H36/state/locked/inside.tsv"
_ic_U37="$(_ic_u a37)"; _ic_H37="$_ic_U37/plain/fh"; _ic_home "$_ic_H37"
_ic_U38="$(_ic_u a38)"; _ic_H38="$_ic_U38/plain/fh"; _ic_home "$_ic_H38"; _ic_touch "$_ic_H38" 'state/x 2'
_ic_U39="$(_ic_u a39)"; mkdir -p "$_ic_U39"
# The stubs felix status finds first on PATH; outside cases/, as their log is.
for _ic_s in claude launchctl; do
  printf '#!/bin/sh\nprintf "%%s %%s\\n" "%s" "$*" >> "%s/stub.log"\nexit 0\n' "$_ic_s" "$_ic_a" > "$_ic_a/bin/$_ic_s"
  chmod +x "$_ic_a/bin/$_ic_s"
done
touch "$_ic_a/marker"; sleep 1

# ---- felix_icloud_state: A28 to A40 --------------------------------------------------------------
_ic_L28="$(_ic_line value clear "$_ic_C0" "$_ic_SN")"
_ic_L29="$(_ic_line value synced "$_ic_C0" "$(_ic_SI Documents)")"
is "b18 A28 (B15): a home under a plain folder, with no iCloud Drive, reads value, clear: no copy, not synced" \
   "$(_ic_run "$_ic_U28" "$_ic_H28")" "$_ic_L28"
is "b18 A29 (B15): a home under Documents, which CD/Documents links to, reads value, synced, inside iCloud-synced Documents" \
   "$(_ic_run "$_ic_U29" "$_ic_H29")" "$_ic_L29"
is "b18 A30 (B15): a home under a linked Desktop reads synced inside Desktop, and one under CD itself synced inside iCloud Drive" \
   "Desktop: [$(_ic_run "$_ic_U30d" "$_ic_H30d")] CD: [$(_ic_run "$_ic_U30i" "$_ic_H30i")]" \
   "Desktop: [$(_ic_line value synced "$_ic_C0" "$(_ic_SI Desktop)")] CD: [$(_ic_line value synced "$_ic_C0" "$(_ic_SI 'iCloud Drive')")]"
is "b18 A31 (B15): a home named through a link to Documents/fh is judged by its physical path, as A29" \
   "$(_ic_run "$_ic_U31" "$_ic_U31/lnk")" "$_ic_L29"
is "b18 A32 (B15): with CD/Documents a plain directory, or a link somewhere else, a home under Documents is not synced" \
   "plain: [$(_ic_run "$_ic_U32p" "$_ic_H32p")] elsewhere: [$(_ic_run "$_ic_U32e" "$_ic_H32e")]" \
   "plain: [$_ic_L28] elsewhere: [$_ic_L28]"
_ic_D33="4 $_ic_CN.git/worktrees/w/index 2, state/discover/felix.tsv 3.new, state/held-tree/abc 2 and 1 more; $(_ic_SI Documents)"
_ic_o33="$(_ic_run "$_ic_U33" "$_ic_H33")"
is "b18 A33 (B15): four copies under state/ and .git, objects not read, are counted, the first three listed in C order, and the home is synced" \
   "$_ic_o33" "value${_ic_T}copies-4${_ic_T}$_ic_D33|rc=0"
is "b18 A34 (B15): names that are not shaped like an iCloud copy (v2.tsv, a2, x 2y, b 2., a parenthesised date) count as none" \
   "$(_ic_run "$_ic_U34" "$_ic_H34")" "$_ic_L28"
_ic_o="$(_ic_run "$_ic_U35" "$_ic_H35")"; _ic_rc="${_ic_o##*|rc=}"; _ic_o="${_ic_o%|rc=*}"
_ic_v="$(printf '%s\n' "$_ic_o" | cut -f2)"; _ic_d="$(printf '%s\n' "$_ic_o" | cut -f3-)"
_ic_p="6 ${_ic_CN}state/a 1, state/b 2, state/c 3 and 3 more; "
case "$_ic_d" in "$_ic_p"*) _ic_b="begins as B15 says" ;; *) _ic_b="is [$_ic_d]" ;; esac
is "b18 A35 (B15): six copies list the first three and say and 3 more" \
   "rc $_ic_rc, VALUE $_ic_v, DETAIL $_ic_b" "rc 0, VALUE copies-6, DETAIL begins as B15 says"
if [ "$(id -u)" = 0 ]; then
  skip "b18 A36 (B15): a directory the scan cannot read makes the count unknown, not zero" "root reads a mode-000 directory"
else
  chmod 000 "$_ic_H36/state/locked"
  _ic_o="$(_ic_run "$_ic_U36" "$_ic_H36")"
  chmod 755 "$_ic_H36/state/locked"
  is "b18 A36 (B15): a directory the scan cannot read makes the count unknown, not zero" \
     "$_ic_o" "$(_ic_line unknown - "$_ic_CU" "$_ic_SN")"
fi
is "b18 A37 (B15): with HOME unset and no copy, whether the home is synced is unknown" \
   "$(_ic_run "" "$_ic_H37" nohome)" "$(_ic_line unknown - "$_ic_C0" "$_ic_SU")"
_ic_o="$(_ic_run "" "$_ic_H38" nohome)"; _ic_rc="${_ic_o##*|rc=}"; _ic_o="${_ic_o%|rc=*}"
_ic_v="$(printf '%s\n' "$_ic_o" | cut -f2)"; _ic_d="$(printf '%s\n' "$_ic_o" | cut -f3-)"
case "$_ic_d" in *"; $_ic_SU") _ic_b="ends as B15 says" ;; *) _ic_b="is [$_ic_d]" ;; esac
is "b18 A38 (B15): with HOME unset a copy is still counted, and the detail ends saying the sync is unknown" \
   "rc $_ic_rc, VALUE $_ic_v, DETAIL $_ic_b" "rc 0, VALUE copies-1, DETAIL ends as B15 says"
_ic_N="$(printf 'unknown\t-\tno Felix home resolved|rc=0')"
is "b18 A39 (B15): an empty home, or one that does not exist, reads unknown: no Felix home resolved" \
   "empty: [$(_ic_run "$_ic_U39" "")] none: [$(_ic_run "$_ic_U39" "$_ic_U39/none")]" "empty: [$_ic_N] none: [$_ic_N]"
is "b18 A40 (B15) (control): the calls of A28 to A39 write nothing under any home, user home, memory root or working directory" \
   "$(find "$_ic_c" -newer "$_ic_a/marker" -print 2>&1)" ""

# ---- felix status: A41 to A44, in the A33 layout -------------------------------------------------
_ic_st() {   # ARGS...: felix status from an ungoverned directory, FELIX_HOME=H33 and HOME=U33
  ( cd "$_ic_c/cwd" && env -u CLAUDE_CONFIG_DIR -u FELIX_JQ -u FELIX_HOME_DIR HOME="$_ic_U33" FELIX_HOME="$_ic_H33" \
      FELIX_MEMORY="$_ic_c/mem" PATH="$_ic_a/bin:$PATH" "$FELIX" status "$@" )
}
touch "$_ic_a/marker2"; sleep 1
_ic_st --tsv > "$_ic_a/status.tsv" 2> "$_ic_a/status.err"; _ic_strc=$?
_ic_w44="$(find "$_ic_U33" "$_ic_c/mem" -newer "$_ic_a/marker2" -print 2>&1)"
_ic_st > "$_ic_a/status.txt" 2> "$_ic_a/status-plain.err"; _ic_sprc=$?
_ic_f5="$(LC_ALL=C awk -F'\t' 'NR <= 5 { printf "%s%s", (NR > 1 ? " " : ""), $1 }' "$_ic_a/status.tsv" 2>/dev/null)"
_ic_ni="$(LC_ALL=C awk -F'\t' '$1 == "icloud" { n++ } END { print n + 0 }' "$_ic_a/status.tsv" 2>/dev/null)"
# Changed by the lane counter contract (docs/2026-10-29-lane-slice-0-plan.md, C6): the lane row was added at the end, as the status header allows.
_ic_r9="$(LC_ALL=C awk -F'\t' 'NR == 9 { print $1 }' "$_ic_a/status.tsv" 2>/dev/null)"
_ic_nr="$(LC_ALL=C awk 'END { print NR }' "$_ic_a/status.tsv" 2>/dev/null)"
_ic_last="$(LC_ALL=C awk '{ l = $0 } END { print l }' "$_ic_a/status.tsv" 2>/dev/null)"
is "b18 A41 (B16): felix status --tsv exits 0, keeps settings, schedule, pulse, reach and gate first, has one icloud row, the ninth, and ends with the lane row, the tenth and last, which in this ungoverned directory reads none: this directory is not a governed checkout" \
   "exit $_ic_strc; first five [$_ic_f5]; icloud rows $_ic_ni; ninth [$_ic_r9]; rows $_ic_nr; last [$_ic_last]" \
   "exit 0; first five [settings schedule pulse reach gate]; icloud rows 1; ninth [icloud]; rows 10; last [lane${_ic_T}none${_ic_T}-${_ic_T}this directory is not a governed checkout]"
is "b18 A42 (B16): the icloud row is icloud, then felix_icloud_state's line for the same home" \
   "$(LC_ALL=C awk -F'\t' '$1 == "icloud"' "$_ic_a/status.tsv" 2>/dev/null)" "icloud${_ic_T}${_ic_o33%|rc=*}"
_ic_want43="$(printf '%-9s %-12s %s' icloud copies-4 "$_ic_D33")"; _ic_n43=0
while IFS= read -r _ic_l || [ -n "$_ic_l" ]; do [ "$_ic_l" = "$_ic_want43" ] && _ic_n43=$((_ic_n43 + 1)); done < "$_ic_a/status.txt"
is "b18 A43 (B16): plain felix status prints the icloud row aligned as the other rows are" \
   "exit $_ic_sprc; lines that are the aligned icloud row: $_ic_n43" "exit 0; lines that are the aligned icloud row: 1"
is "b18 A44 (B16) (control): with copies present felix status --tsv writes nothing under the home, the user home or the memory root" \
   "$_ic_w44" ""
