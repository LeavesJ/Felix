# Readiness for unattended work.
#
# Reports, and deliberately does not decide. Auto-merge can unlock itself
# because what it unlocks is bounded: a change that already passed the gate, the
# classifier and the evidence policy, and whose worst case is a revert. This is
# not that.
#
# The evidence that would justify flipping this switch cannot be gathered without
# flipping it. Every dry run stops before the model is invoked, so dry runs prove
# the guards run; they prove nothing about whether the guards hold, because
# nothing has yet tried to get past them. Counting them and calling it a track
# record would be measuring the wrong thing carefully.
#
# So this prints what is true and leaves the decision where it belongs.

felix_unattended_state() {
  local repo="$1"
  printf 'switch\t%s\n' \
    "$(gh variable list --repo "$repo" 2>/dev/null | felix_count FELIX_UNATTENDED)"
  printf 'key\t%s\n' \
    "$(gh secret list --repo "$repo" 2>/dev/null | felix_count ANTHROPIC_API_KEY)"
  printf 'dryruns\t%s\n' \
    "$(gh run list --repo "$repo" --workflow 'unattended repair' --limit 50 \
        --json conclusion -q 'length' 2>/dev/null || printf 0)"
  printf 'dryfails\t%s\n' \
    "$(gh run list --repo "$repo" --workflow 'unattended repair' --limit 50 \
        --json conclusion -q '[.[] | select(.conclusion=="failure")] | length' 2>/dev/null || printf 0)"
}
