# The commission grant is bound to the table it was granted over.
#
# Every other grant names an action the engine defines. This one names a
# pipeline whose steps come from a project's own commissioning.tsv, and two of
# that table's columns are eval'd in the checkout. The table is ORDINARY-tier
# by this project's constitution, so without a binding a routine edit to it
# would become code that runs unattended, forever, with nothing on any surface
# to show it. The stamp is the binding: a table edited after the grant does not
# inherit it, and re-granting is a person's act of reading what changed.
_autocomm_build
_ac() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
          . "$FROOT/harness/lib/commission.sh"; . "$FROOT/harness/lib/autonomy.sh"
          felix_autonomy_commission_current "$AUC" && echo current || echo stale ); }
is "a grant with no stamp does not cover the table" "$(_ac)" "stale"
( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
  . "$FROOT/harness/lib/commission.sh"
  felix_commission_policy_version "$AUC" ) > "$AUC/autonomy.commission"
is "and one stamped over this table does"           "$(_ac)" "current"
printf 'envelope	-	-	-	person	test -f "$FELIX_PROJECT/CLAUDE.md"	none
later	-	-	-	person	true	none
' \
  > "$AUC/commissioning.tsv"
is "editing the table takes the grant off it"       "$(_ac)" "stale"
# Revoked is revoked whatever the stamp says: the two are read with AND.
printf '# what Felix may do here unattended
' > "$AUC/autonomy"
is "and a revoked grant covers nothing"             "$(_ac)" "stale"

