# Environments and credentials

## Environments

| Environment | Base URL | Use |
| --- | --- | --- |
| Sandbox | `https://sandbox.straddle.com` | All integration development and testing. The contract's default server. |
| Production | `https://production.straddle.com` | Live money movement. Never used by kit skills for writes. |

A key works only with its own environment. A Sandbox key sent to Production, or the reverse, fails authentication. Confirm which environment a key belongs to from the Straddle dashboard, not from its shape. The CLI selects the host with `STRADDLE_ENVIRONMENT` (`sandbox` or `production`) or an explicit `STRADDLE_BASE_URL`, and `straddle doctor --agent` reports the resolved URL as `runtime_context.environment`.

The hosted API MCP installation is named `production` inside Scalar. That name says nothing about the Straddle environment a request reaches. Check the actual request target.

## Credentials

- Application code, the SDKs, and the CLI read the key from the process environment as `STRADDLE_API_KEY`. The API MCP gets the key through the selected client's documented secret input, as described in [tools.md](tools.md). The plugin's MCP declaration holds no key or header.
- Never open, print, copy, or summarize `.env*` files, credential stores, private keys, or the CLI's config files. Report whether a key is present, never its value.
- Never echo a key, include it in a log, plan, test fixture, commit, or chat message, or ship it in a browser bundle. Browser code talks to your server, and your server talks to Straddle.
- Do not export a key saved in the CLI to another tool.

## Missing configuration is an error

Every Straddle operation checks for a key and an environment before it sends anything. When either is missing, stop with a configuration error that names what is missing. Never return an empty result, skip the call, or report success. That rule covers application code, tests, CLI use, and skill reports alike.

`straddle doctor` exits 0 even when the key is missing, so read its `env_vars` and `auth` fields rather than its exit code. `env_vars: "ERROR missing required: STRADDLE_API_KEY"` is a configuration failure.
