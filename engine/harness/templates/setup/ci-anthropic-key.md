# Add ANTHROPIC_API_KEY so CI can run Claude unattended

**Check:** `gh secret list --repo {{REPO}}` includes `ANTHROPIC_API_KEY`.

This is the switch between attended and unattended autonomy, and the only setup
step with an ongoing cost. Everything works without it; CI simply reports pass or
fail and never invokes a model.

## A key in .env does not count

`.env` is gitignored and the runner does a fresh clone. Actions secrets are also
never ambient: a workflow sees only what it names as `${{ secrets.NAME }}`.

## Use a key that exists only for CI

Any workflow in the repository can read a repository secret, and anyone who can
push a workflow can write one that exfiltrates it. If that value is also serving
production, a workflow compromise becomes a product compromise. A dedicated key
can be revoked without taking anything else down.

## Steps

1. Set a monthly cap first, under **Billing → Limits**. An unattended loop should
   have a ceiling enforced by the provider, not by an agent's judgment.
2. Create the key at <https://console.anthropic.com/settings/keys>.
3. `gh secret set ANTHROPIC_API_KEY --repo {{REPO}}`, paste, Ctrl+D.
   Not `--body`, which leaves the key in shell history.

## The trap

If the suite has tests that skip when the key is absent, adding it to the gate
workflow makes them start running and billing on every pull request, silently,
because nothing announces a test that merely stopped being skipped. Put live
coverage in a separate scheduled workflow with its own budget.
