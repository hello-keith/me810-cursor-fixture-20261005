# Tools

Each tool has one job. Use the one that fits and do not substitute another.

## Docs MCP (`straddle-docs`)

`https://straddle-build-straddle-openapi.apidocumentation.com/mcp`, no credential. Use it to search Straddle guides and the API reference. It is meant to be search-only. If its tool list includes `execute-request` or other API tools, do not call them: report that the Docs MCP is exposing execution and use the API MCP rules below instead.

The same content is published as [llms.txt](https://straddle-build-straddle-openapi.apidocumentation.com/llms.txt) for direct reading.

## API MCP (`straddle-api`)

`https://mcp.scalar.com/mcp/d5d1b1c2-ae5b-432d-b795-4fcb31cfdedd`, authenticated with the caller's own key as `Authorization: Bearer ${STRADDLE_API_KEY}`. No Scalar login. It exposes `summarize-openapi-specs`, `search-openapi-operations`, `search-documentation`, and `execute-request`.

- `summarize-openapi-specs` and `search-openapi-operations` read the specification and send no Straddle request. A successful call proves discovery, not that the key works.
- `execute-request` sends a real Straddle request with the caller's key. Use it only for permitted reads, and never for the fourteen operations in [writes-and-approval.md](writes-and-approval.md). It is not read-only.
- Keep the client's tool approval prompts on.

## SDKs

Application code uses the released Scalar SDK for the developer's language (versions in [SKILL.md](../SKILL.md)). Read the installed package in the dependency tree, including its `api.md`, README, and any generated agent skill, before naming a method, option, or type. Do not rely on memory or on docs for a different version.

## Straddle CLI

Use the CLI for diagnostics, sandbox reference data, and approved sandbox writes.

- Add `--agent` to every command for JSON and non-interactive output.
- Add `--data-source live` to every read. The local store in CLI v1.0.2 is not yet scoped by environment and account, so cached rows can mix Sandbox and Production or two accounts.
- Run writes with `--dry-run` first. See [writes-and-approval.md](writes-and-approval.md).
- `straddle doctor --agent` reports configuration and key presence (never its value). It does not verify that the key works. The next CLI release adds `runtime_context` with the environment, integration type, and acting account to `doctor` and `agent-context`. v1.0.2 does not report it, so treat those values as unknown there rather than guessing.
- `straddle which "<capability>" --agent` finds the command for a task. `straddle sandbox` prints deterministic `sandbox_outcome` values and test bank data.
- Do not run `straddle sync`, `sql`, or other local-store commands for integration work.
