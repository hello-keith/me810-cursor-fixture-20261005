# Step 4: Docs MCP and API MCP

- **Needs:** step 3 summary.
- **Tools:** the `straddle-docs` and `straddle-api` MCP tools named below, and nothing else from those servers.
- **Next:** [05-report.md](05-report.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-setup","step":"04-mcp"}
```

Check the two servers separately and report them as separate rows. One working does not imply the other.

## Docs MCP (`straddle-docs`)

1. Record whether the server is registered and which tools it lists.
2. Run one `search-documentation` query, such as `webhook signature verification`. A relevant result is `passed`.
3. The Docs MCP must be search-only. If it lists `execute-request`, `search-openapi-operations`, or `summarize-openapi-specs`, report it as a **warning: Docs MCP exposes API execution tools**, do not call them, and continue.

## API MCP (`straddle-api`)

1. Record whether the server is registered and which tools it lists. Registration and tool discovery are **discovery**, not verification.
2. Run `summarize-openapi-specs`. It reads the specification and sends no Straddle request. Report it as `discovery: passed`. It says nothing about the key.
3. **Authenticated verification** needs a real permitted read through `execute-request`. Offer `GET /v1/accounts` (no `Straddle-Account-Id`) and run it only after the developer says yes. Never use any other `execute-request` operation here, and never one of the fourteen excluded operations.
4. Report the result as `authenticated: passed`, `authenticated: failed (<status>)`, or `authenticated: not run`. A 401 means the key is missing, wrong, or for another environment. Never print the header or key.

If a server is not registered, say so and name the published setup guide, `https://straddle-build-straddle-openapi.apidocumentation.com/connect-mcp`. Do not register it yourself.

**Summary for step 5:** for each server, registration, tools listed, discovery result, authenticated result (API MCP only), and any Docs MCP execution-tool warning.
