# Tools

Each tool has one job. Use the one that fits and do not substitute another.

## Docs MCP (`straddle-docs`)

`https://straddle-build-straddle-openapi.apidocumentation.com/mcp`, no credential. Use it to search Straddle guides and the API reference. It is meant to be search-only. If its tool list includes `execute-request` or other API tools, do not call them: report that the Docs MCP is exposing execution and use the API MCP rules below instead.

The same content is published as [llms.txt](https://straddle-build-straddle-openapi.apidocumentation.com/llms.txt) for direct reading.

## API MCP (`straddle-api`)

`https://mcp.scalar.com/mcp/d5d1b1c2-ae5b-432d-b795-4fcb31cfdedd`, authenticated with the caller's own Straddle API key. No Scalar login. It exposes `summarize-openapi-specs`, `search-openapi-operations`, `search-documentation`, and `execute-request`.

The plugin sends the key from `STRADDLE_API_KEY` in the environment the client starts from, as a bearer token: through the `Authorization` header in the plugin's MCP declaration for Claude Code and Cursor (Cursor prompts for the variable), and through the Codex manifest's bearer setting for Codex. The declaration holds a placeholder, never the key. Without the plugin, follow the published [connect-mcp guide](https://straddle-build-straddle-openapi.apidocumentation.com/connect-mcp). A registered server whose variable is unset is not authenticated, so never treat registration or discovery as proof of access.

- `summarize-openapi-specs` and `search-openapi-operations` read the specification and send no Straddle request. A successful call proves discovery, not that the key works.
- `execute-request` sends a real Straddle request with the caller's key. It is not read-only. It may run permitted reads, and permitted writes only after the preview and approval in [writes-and-approval.md](writes-and-approval.md). It never runs the fourteen excluded operations listed there, whatever the approval.
  - Get its IDs from `search-openapi-operations` in the same session, never from memory, another session, or `summarize-openapi-specs`, which returns neither. They change when a contract version publishes. `xScalarDocumentId` is the spec's `x-scalar-document-version-id`. `xScalarOperationId` is the `x-scalar-operation-id` UUID on the matching path, not the OpenAPI `operationId` such as `listAccounts`.
  - Pass the resolved host as `serverBaseUrl`, for example `https://sandbox.straddle.com`, never the templated server URL. Put query parameters in `path`, for example `/v1/accounts?page_size=1`.
  - "Failed to get operation" means the operation ID is wrong, and "does not belong to the given document version" means the document ID is wrong. Neither says anything about the key.
- Individual skills can be stricter. Setup and Plan make no remote writes, so they use only the reads their steps name.
- Keep the client's tool approval prompts on.

## SDKs

Application code uses the released Scalar SDK for the developer's language (versions in [SKILL.md](../SKILL.md)). Read the installed package in the dependency tree, including its `api.md`, README, and any generated agent skill, before naming a method, option, or type. Do not rely on memory or on docs for a different version.

## Straddle CLI

Use the CLI for diagnostics, sandbox reference data, and approved sandbox writes.

- Add `--agent` to every command for JSON and non-interactive output.
- Add `--data-source live` to every read. Integration verification needs the API's current state, and a local snapshot can be stale.
- Run writes with `--dry-run` first. See [writes-and-approval.md](writes-and-approval.md).
- `straddle auth status --agent` and `straddle agent-context` run offline. The first reports whether a key is configured (environment or saved CLI credentials), never its value. The second reports `runtime_context` with the resolved environment, integration type, and acting account (CLI v1.0.3 and later; absent in v1.0.2). The resolved environment defaults to Sandbox, so it is not proof of an explicit selection.
- `straddle doctor --agent` sends `GET /` to the resolved host before it reports, so it is a network check, not a preflight. Its `credentials: present, not verified` does not verify the key.
- `straddle which "<capability>" --agent` finds the command for a task. `straddle sandbox` prints deterministic `sandbox_outcome` values and test bank data. A command that exists in the CLI is not proof that its operation is in the public contract; check the contract before using it.
- Do not run `straddle sync`, `sql`, or other local-store commands for integration work.
