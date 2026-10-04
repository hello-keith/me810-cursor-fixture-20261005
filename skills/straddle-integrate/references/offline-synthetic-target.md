# Offline synthetic localhost target

Integrate and Test normally target only Straddle Sandbox. They also accept one other target: a synthetic Straddle upstream on this machine, for proving the SDK and CLI routes offline. This is an offline proof. It never counts as live Straddle Sandbox proof, and no resource it creates exists at Straddle.

## When the target is accepted

Accept it only when all of these hold. If any does not, treat the run as a configuration error, exactly as for any other unexpected target.

- `STRADDLE_ENVIRONMENT=sandbox` is set explicitly. A default or resolved value does not count.
- `STRADDLE_BASE_URL` is `http://127.0.0.1:<port>` or `http://localhost:<port>`. Any other host, including private network addresses, is not a localhost target.
- In this conversation, before the preview, the developer explicitly declares two things: that this base URL is a synthetic local upstream for offline proof, and that the configured key is a synthetic value, not a Straddle key. Do not infer either from the URL or the key's shape, and never read or print the key.
- The developer also confirms that this client session runs with its command sandbox enabled, with network access limited to binding and reaching localhost, through settings scoped to this session (for example a task-local file passed with `--settings`), and with no global, user, or managed policy change. If the sandbox is disabled, bypassed, or unknown, or localhost access came from a global or user settings change, the target is not accepted. A synthetic run must not leave the machine through an unsandboxed shell.

Until every condition above is confirmed, the target is a configuration error, not a pending question. You may ask for the missing confirmation, but in that reply do not ask for approval of any write, and hand off `blocked`. Ask for approval only in a later reply, after every condition holds and you have shown a fresh preview.

Do not change client, sandbox, or network settings yourself to reach the target, and do not ask the developer to loosen them beyond that session-local localhost binding. When the local upstream cannot be reached, report that and stop.

## What changes

- **Preview.** State `Target: offline synthetic localhost (not Straddle Sandbox)`, followed by the exact base URL and the label `offline synthetic proof, not live Straddle Sandbox proof`. The rest of the preview and the approval rule are unchanged: every row still shows its acting account, operation, SDK or CLI route, payload summary, external ID, and idempotency key, and it still needs an explicit yes to that exact preview.
- **Routing.** Unchanged. The fourteen excluded operations still run only through the SDK or CLI. No API MCP call is made against a synthetic target, because the hosted MCP always reaches real Straddle.
- **Reports and evidence.** Label the run `offline synthetic proof, not live Straddle Sandbox proof`. List created items as synthetic upstream records, not Straddle server-side resources. Never mark a live Sandbox scenario, such as a `paid` charge or an `R01` return delivered through a notification path, as passed from a synthetic run.
