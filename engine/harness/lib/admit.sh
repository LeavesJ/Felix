# The one install policy.
#
# Whether something may be mounted with nobody present was decided in three
# places that did not agree. stack.sh carried FELIX_RISK_AUTO="low medium" and
# auto-applied both. discover.sh's adopt declared low and refused medium. And
# `ready --fix` reached across into stack.sh's private helper, so a change to
# either of the other two silently moved it.
#
# The disagreement about medium was never a bug, which is why this does not
# collapse it. A person who writes a medium row into stack.tsv has decided
# something the engine's own tiering has not: they know what the credential is
# for. So the question is not "what tier is this" but "what tier is this, and
# who says so" — and the second half is v3.2's grounding vocabulary, the same
# three words commissioning.log already writes.
#
#   DECLARED   a person wrote it into a manifest.
#   OBSERVED   the engine fetched it at a pinned sha, read what it ships, and
#              tiered it from what it found.
#   INFERRED   a model named it. Nothing has been fetched or read.
#
# Three verdicts, and `hold` is the one that matters. It is not a refusal — the
# row stays, it is reported, and a person can act on it. It is the engine
# declining to act alone, which is a different thing from the engine saying no.
#
#   install  proceed with nobody present
#   hold     legitimate, but a person decides
#   refuse   not by any flag from any caller
#
# The table below is not derived here. Every cell is a decision that was taken
# somewhere else and is only being written down once:
#
#              DECLARED   OBSERVED   INFERRED
#   low        install    install    hold
#   medium     install    hold       hold
#   high       refuse     refuse     refuse
#
# - high, everywhere: constitution invariant 4. "risk=high is still refused by
#   every flag from every caller."
# - low and medium DECLARED: stack.sh's existing FELIX_RISK_AUTO, and the
#   founder's decision of 2026-09-04 that person-declared medium keeps
#   installing as it does today.
# - medium OBSERVED holds: the same decision's other half. An engine-tiered
#   medium ships an MCP or LSP server, or a bundled script that sends a named
#   credential over the network, or prose that makes live remote pages its
#   authority or pipes a download into a shell — read by pattern from its
#   files, its manifest and its marketplace entry, and never sandboxed.
#   Amendments 1.2 is why there is no better answer available: sandbox-exec
#   confines but does not report, so the spec's T2 has no mechanism on this
#   machine and denial-on-shape is what remains.
# - INFERRED never installs, at any tier. A nomination arrives in a file a
#   model wrote, so its own claim of `low` is a claim and not evidence. The
#   door from a nomination to an install is inspection, which is what turns it
#   OBSERVED. This is the panel's finding that an INFERRED capability would
#   otherwise be consumed as DECLARED.
#
# Anything unrecognised refuses. That is the property most likely to be lost by
# a later edit, because every wrong answer here still looks like a working
# install, and it is asserted directly rather than left to follow from the
# table.

# felix_admit <tier> <grounding> -> install | hold | refuse
#
# Always exits 0 and always prints exactly one word. A caller cases on the
# word; a caller that tested the exit status would read `refuse` as success.
felix_admit() {
  local tier="${1:-}" ground="${2:-}"
  case "$tier" in low|medium|high) ;; *) printf 'refuse'; return 0 ;; esac
  case "$ground" in DECLARED|OBSERVED|INFERRED) ;; *) printf 'refuse'; return 0 ;; esac
  case "$tier" in high) printf 'refuse'; return 0 ;; esac
  case "$ground" in INFERRED) printf 'hold'; return 0 ;; esac
  case "$tier:$ground" in
    medium:OBSERVED) printf 'hold' ;;
    *)               printf 'install' ;;
  esac
  return 0
}

# Why, in the words of what was actually decided, for a caller that has to tell
# somebody. Kept beside the verdict so the two cannot drift: a report that
# explains a verdict the policy no longer gives is worse than one explaining
# nothing.
felix_admit_why() {
  local tier="${1:-}" ground="${2:-}"
  case "$(felix_admit "$tier" "$ground")" in
    install) printf 'risk: %s' "$tier" ;;
    hold)
      case "$ground" in
        INFERRED) printf 'named by a provider and not yet inspected, so a person decides' ;;
        *)        printf 'risk: %s, and nothing sandboxed it, so a person decides' "$tier" ;;
      esac ;;
    *)
      case "$tier" in
        high) printf 'high risk, install by hand' ;;
        *)    printf 'not a tier and a grounding this policy recognises' ;;
      esac ;;
  esac
}
