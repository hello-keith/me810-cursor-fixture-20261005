# Tools

Each tool has one job. Use the one that fits and do not substitute another.

## Docs MCP (`straddle-docs`)

`https://straddle-build-straddle-openapi.apidocumentation.com/mcp`, no credential. Use it to search Straddle guides and the API reference. It is meant to be search-only. If its tool list includes `execute-request` or other API tools, do not call them: report that the Docs MCP is exposing execution and use the API MCP rules below instead.

The same content is published as [llms.txt](https://straddle-build-straddle-openapi.apidocumentation.com/llms.txt) for direct reading.

## API MCP (`straddle-api`)

`https://mcp.scalar.com/mcp/d5d1b1c2-ae5b-432d-b795-4fcb31cfdedd`, authenticated with the caller's own Straddle API key. No Scalar login. It exposes `summarize-openapi-specs`, `search-openapi-operations`, `search-documentation`, and `execute-request`.

The plugin's shared MCP declaration carries no credential or header. Each developer supplies the key through their client's documented secret input, following the published [connect-mcp guide](https://straddle-build-straddle-openapi.apidocumentation.com/connect-mcp), with manual configuration as the fallback. A registered server with no key configured is not authenticated, so never treat registration or discovery as proof of access.

- `summarize-openapi-specs` and `search-openapi-operations` read the specification and send no Straddle request. A successful call proves discovery, not that the key works.
- `execute-request` sends a real Straddle request with the caller's key. It is not read-only. It may run permitted reads, and permitted writes only after the preview and approval in [writes-and-approval.md](writes-and-approval.md). It never runs the fourteen excluded operations listed there, whatever the approval.
- Individual skills can be stricter. Setup and Plan make no remote writes, so they use only the reads their steps name.
- Keep the client's tool approval prompts on.

## SDKs

Application code uses the released Scalar SDK for the developer's language (versions in [SKILL.md](../SKILL.md)). Read the installed package in the dependency tree, including its `api.md`, README, and any generated agent skill, before naming a method, option, or type. Do not rely on memory or on docs for a different version.

## Straddle CLI

Use the CLI for diagnostics, sandbox reference data, and approved sandbox writes.

- Add `--agent` to every command for JSON and non-interactive output.
- Add `--data-source live` to every read. The local store in the published CLI (v1.0.2) is not scoped by environment and account, so cached rows can mix Sandbox and Production or two accounts. Keep the flag until a published release scopes the store.
- Run writes with `--dry-run` first. See [writes-and-approval.md](writes-and-approval.md).
- `straddle doctor --agent` reports configuration and key presence (never its value). It does not verify that the key works. CLI v1.0.3 (tagged, not yet published) adds `runtime_context` with the environment, integration type, and acting account to `doctor` and `agent-context`. v1.0.2 does not report it, so treat those values as unknown there rather than guessing.
- `straddle which "<capability>" --agent` finds the command for a task. `straddle sandbox` prints deterministic `sandbox_outcome` values and test bank data. A command that exists in the CLI is not proof that its operation is in the public contract; check the contract before using it.
- Do not run `straddle sync`, `sql`, or other local-store commands for integration work.
