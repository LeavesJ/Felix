# Authenticate the GitHub MCP server

**Check:** `claude mcp list` shows `plugin:github:github` as `Connected`.

## You may not need it

If `gh` is authenticated, it already covers issues, pull requests, secrets,
labels, branch protection, and CI logs. The MCP is a nicer interface inside a
session, not new capability.

## It does not use OAuth

The plugin ships an http server whose header interpolates an environment
variable:

```json
"headers": { "Authorization": "Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}" }
```

Unset, the header becomes a bare `Bearer`, the server rejects it, and Claude Code
falls back to OAuth discovery. GitHub's endpoint does not support dynamic client
registration, so that fallback dead-ends with a confusing message about
incompatible auth servers. **Choosing Authenticate in `/mcp` cannot fix it.**

## The fix

```bash
echo 'export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"' >> ~/.zshrc
```

Then start `claude` from a **new** terminal. The variable must exist in the
environment Claude Code inherits.

Run it yourself. Never route a credential through an agent's context.

## If the check still fails

It reads the environment it runs from. An older shell reports
`Authorization header is badly formatted`, which is the unset-variable case, not
a bad token. Check which shell you are in before concluding it failed.

If the `gh` token's scopes are rejected, create a fine-grained PAT with read
access to contents, issues, and pull requests, and export that instead.
