# Authenticate the Supabase MCP

**Check:** `claude mcp list` shows supabase as `Connected`.

## Steps

1. Create the project at <https://supabase.com/dashboard>.
2. Run `/mcp` in an interactive session, select supabase, authenticate.

## Keep production separate

Development and production must be separate projects with separate credentials.
Destructive production SQL should never be reachable from a normal feature
session.

Add the production project to `stack.tsv` at `risk=high`, which no automation
flag can mount.
