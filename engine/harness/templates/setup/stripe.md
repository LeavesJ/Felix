# Restricted keys behind a billing broker

**Check:** none automated. This ends in a human decision, so it stays visible
until removed by hand.

## The rule that matters most

**Never give an agent a live secret key.**

Live writes go through a small internal broker exposing business-level
operations (`preview_plan_change`, `reconcile_customer`, `request_refund`) with
allowlisted operations, amount ceilings, idempotency, and an audit log. The agent
calls the broker. It never holds the account.

## Steps

1. Work exclusively in test mode first. Test-mode tooling is low risk.
2. Create a **restricted key** with reads only. Never a live secret key.
3. Build the broker before the first live write, not after.
4. Add rows at `risk=high`, which every automation flag refuses.
5. Model money in integer minor units with an explicit currency. Never floats.

## What stays human permanently

New live prices, mass plan migrations, payout destinations, bank and tax
settings, refunds above written policy. These are not "not yet automated." They
are decisions with a person's name attached.
