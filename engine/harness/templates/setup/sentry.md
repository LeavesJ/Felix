# Create a Sentry project and mount its MCP

**Check:** `claude mcp list` shows a `sentry` server as `Connected`.

Production should generate structured work rather than manual detective work.
Without this, the only copy of an error rides the client response and is
destroyed by the refresh the product itself recommends.

## Steps

1. Create a project at <https://sentry.io> matching your runtime.
2. Copy the DSN from **Settings → Projects → [project] → Client Keys**.
3. Add the SDK to your dependencies and initialise it at the app entry point.
4. Put the DSN in `.env`. Not a secret exactly, but machine-specific.
5. Mount the MCP for triage:

```bash
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
```

6. Authenticate with `/mcp` in an interactive session.

Route production errors into the same issue, branch, pull request loop as
everything else. An error that only appears in a dashboard nobody opens is not
being handled.
