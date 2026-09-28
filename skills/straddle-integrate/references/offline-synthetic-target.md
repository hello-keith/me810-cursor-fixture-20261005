# Offline synthetic localhost target

Integrate and Test normally target only Straddle Sandbox. They also accept one other target: a synthetic Straddle upstream on this machine, for proving the SDK and CLI routes offline. This is an offline proof. It never counts as live Straddle Sandbox proof, and no resource it creates exists at Straddle.

## When the target is accepted

Accept it only when all of these hold. If any does not, treat the run as a configuration error, exactly as for any other unexpected target.

- `STRADDLE_ENVIRONMENT=sandbox` is set explicitly. A default or resolved value does not count.
- `STRADDLE_BASE_URL` is `http://127.0.0.1:<port>` or `http://localhost:<port>`. Any other host, including private network addresses, is not a localhost target.
- In this conversation, before the preview, the developer explicitly declares two things: that this base URL is a synthetic local upstream for offline proof, and that the configured key is a synthetic value, not a Straddle key. Do not infer either from the URL or the key's shape, and never read or print the key.

Do not change client, sandbox, or network settings to reach the target. When the local upstream cannot be reached, report that and stop.

## What changes

- **Preview.** State `Target: offline synthetic localhost (not Straddle Sandbox)`, followed by the exact base URL. The rest of the preview and the approval rule are unchanged: every row still shows its acting account, operation, SDK or CLI route, payload summary, external ID, and idempotency key, and it still needs an explicit yes to that exact preview.
- **Routing.** Unchanged. The fourteen excluded operations still run only through the SDK or CLI. No API MCP call is made against a synthetic target, because the hosted MCP always reaches real Straddle.
- **Reports and evidence.** Label the run `offline synthetic proof, not live Straddle Sandbox proof`. List created items as synthetic upstream records, not Straddle server-side resources. Never mark a live Sandbox scenario, such as a `paid` charge or an `R01` return delivered through a notification path, as passed from a synthetic run.
