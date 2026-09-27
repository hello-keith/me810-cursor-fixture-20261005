---
name: straddle-best-practices
description: Shared rules for every Straddle integration task. Use whenever you plan, build, test, review, or debug code or agent actions that touch the Straddle API, Straddle SDKs, the Straddle CLI, the Straddle API MCP or Docs MCP, Straddle-Account-Id, Pay by Bank, Bridge, paykeys, charges, payouts, webhooks, or sandbox testing, even when the user does not mention best practices. Other Straddle skills cite this one instead of restating it.
metadata:
  version: 0.1.0
---

# Straddle best practices

These rules apply to every Straddle integration and to every Straddle skill. Read the linked reference before you answer a question in its area or write code that depends on it.

## Current versions

| Surface | Released version | Notes |
| --- | --- | --- |
| API contract | 1.0.4 (`@straddle/straddle-api@1.0.4`) | Canonical Scalar Registry release. |
| TypeScript SDK | `@straddlecom/straddle` 1.0.4 | npm. |
| Ruby SDK | `straddle` 1.0.4 | RubyGems. |
| C# SDK | `Straddle` 1.0.4 | NuGet. |
| Go SDK | `github.com/straddle-build/straddle-go` v1.0.4 | Module path moved from `github.com/straddleio/straddle-go`. |
| Python SDK | Not available | PyPI still serves the retired 0.5.0 package. Do not recommend `pip install straddle` until the Scalar release is published. |
| Straddle CLI | v1.0.2 | Check the installed version with `straddle --version`. |

Versions change. Check the installed package in the developer's dependency tree before you rely on a method name, and prefer the SDK release's own `api.md`, README, and generated skill over memory.

## Rules

1. **Environment and credentials.** Read the API key from the process environment (`STRADDLE_API_KEY`). Never open `.env*` files, credential stores, or CLI config files, and never print, echo, log, or commit a key. A missing key or environment is a configuration error before any request, never a silent no-op. See [environments-and-credentials.md](references/environments-and-credentials.md).
2. **Account scope.** `Straddle-Account-Id` depends on the integration type and the operation. Direct integrations never send it. Marketplace customer, paykey, and Bridge calls omit it. Charges and payouts on SaaS and marketplace require an explicitly selected account. See [account-scope.md](references/account-scope.md).
3. **Creates are idempotent.** Send an idempotency key on every create and give resources stable external IDs. After an ambiguous result, recover with the same key or an exact external-ID lookup, not a fresh create. See [writes-and-approval.md](references/writes-and-approval.md).
4. **Fourteen operations never use `execute-request`.** Charge, payout, and customer creation, the three paykey-creation endpoints, every `DELETE`, the six unmask operations, and paykey reveal run through the released SDK or the Straddle CLI, after a preview and explicit approval. Scalar does not enforce this, so you must. See [writes-and-approval.md](references/writes-and-approval.md).
5. **Writes need a preview and approval.** Show environment, acting account, operation, payload summary, and idempotency key before any remote write. A changed target or payload needs a new approval. Integration work uses Sandbox.
6. **Notifications.** Use a webhook endpoint, a FIFO endpoint, or a polling endpoint. Never loop on ordinary resource reads such as `GET /v1/charges/{id}` to discover status. Dashboard email is a human confirmation, not a notification model. See [notifications.md](references/notifications.md).
7. **Tools.** Use the Docs MCP for documentation, the API MCP only for permitted reads, the SDK for application code, and the CLI for diagnostics and approved sandbox helpers. See [tools.md](references/tools.md).

## Deprecated paths

- The Stainless-generated SDKs and their MCP server. Use the Scalar-generated SDKs above.
- The Mintlify `docs.straddle.com/.well-known/skills` index. It recommends polling charge reads and is retiring.
- Any local `straddle-mcp` server or "local integration MCP". The kit uses the hosted Scalar servers only.
- The React embed wrapper. Hosted iframe onboarding is the supported path until Onboarding V2.

## When a rule blocks the task

Stop and say which rule applies and why. Offer the supported alternative, for example an SDK call instead of `execute-request`, or a polling endpoint instead of a status loop. Do not work around a rule silently.
