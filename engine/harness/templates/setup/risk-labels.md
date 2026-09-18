# Escalation and risk labels

**Check:** `gh label list --repo {{REPO}}` includes `needs-founder`.

The repair loop escalates by applying a label. Without these it has nowhere to
put a problem it has decided to stop working on.

| Label | Meaning |
|---|---|
| `needs-founder` | The repair loop hit its ceiling. Stop patching. |
| `needs-architecture` | The failure is a design problem, not a patch. |
| `risk-green` | Reversible, and nothing risky was touched. |
| `risk-yellow` | Not obviously safe. Look closely; it merges on green CI unless a channel stops it. |
| `risk-red` | Auth, secrets, money, irreversible. Look hardest. The label stops nothing: a merge waits for a person only when `felix merge` names an escape channel. |

```bash
gh label create needs-founder --repo {{REPO}} --color D93F0B \
  --description "Repair loop hit its ceiling; a human must diagnose"
gh label create needs-architecture --repo {{REPO}} --color 5319E7 \
  --description "Failure is a design problem, not a patch"
gh label create risk-green --repo {{REPO}} --color 0E8A16 --description "Reversible"
gh label create risk-yellow --repo {{REPO}} --color FBCA04 --description "Not obviously safe; look closely, then merge on green CI"
gh label create risk-red --repo {{REPO}} --color B60205 --description "Look hardest; an escape channel, not this label, stops a merge"
```

Needs no account and no credential, so an agent can do this for you. It is listed
because the check should catch it if someone deletes one.
