# tests/lib/autocomm.sh: the commission-grant fixture.
# Used by 0579 (builds it, in state fresh) and 0580 (state revoked, the state
# 0579's last assertion leaves it in). Moved from
# parts/0579-the-commission-grant-is-bound-to-its-table.sh: the fixture's first
# statements from lines 10-15 (fresh), and the commands 0579 runs between its
# assertions that bring it to revoked, from lines 20-31 (revoked): the stamp over
# the one-row table, the table edited, the grant revoked.
# Definitions only. _autocomm_build [STATE] sets AUC first and does nothing more
# once $AUC/autonomy is there, so in the serial run 0579's call builds and 0580's
# finds it as 0579 left it. STATE fresh (the default): a one-row
# commissioning.tsv and a grant of commission, no stamp. STATE revoked: that,
# then the stamp written over the one-row table, the table edited to two rows
# and the grant revoked, which is what 0580 reads.

_autocomm_build() {   # [fresh|revoked]
  AUC="$TMP/autocomm"
  [ -e "$AUC/autonomy" ] && return 0
  mkdir -p "$AUC" "$MEM/autocomm"
printf 'envelope	-	-	-	person	test -f "$FELIX_PROJECT/CLAUDE.md"	none
' > "$AUC/commissioning.tsv"
printf '# what Felix may do here unattended
commission
' > "$AUC/autonomy"
  [ "${1:-fresh}" = revoked ] || return 0
( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
  . "$FROOT/harness/lib/commission.sh"
  felix_commission_policy_version "$AUC" ) > "$AUC/autonomy.commission"
printf 'envelope	-	-	-	person	test -f "$FELIX_PROJECT/CLAUDE.md"	none
later	-	-	-	person	true	none
' \
  > "$AUC/commissioning.tsv"
printf '# what Felix may do here unattended
' > "$AUC/autonomy"
}
