# Execution routes

Where each Sandbox write and each excluded read runs. The rules behind this table are in [writes-and-approval.md](../../straddle-best-practices/references/writes-and-approval.md) and [account-scope.md](../../straddle-best-practices/references/account-scope.md). This page only says which tool carries out each operation.

Names below were checked against the installed TypeScript SDK `@straddlecom/straddle` 1.0.4 (`api.md`) and the Straddle CLI command tree. Confirm each one in the developer's installed SDK or with `straddle <command> --help` before using it. For Ruby, C#, or Go, read the installed package for the equivalent method rather than translating the TypeScript name.

## The fourteen excluded operations: SDK or CLI only

| Operation ID | TypeScript SDK | Straddle CLI |
| --- | --- | --- |
| `createCustomer` | `client.customers.create` | `straddle customers create` |
| `createBankAccountPaykey` | `client.bridge.createBankAccountPaykey` | `straddle bridge create-bank-account-paykey` |
| `createPlaidPaykey` | `client.bridge.createPlaidPaykey` | `straddle bridge create-plaid-paykey` |
| `createQuilttPaykey` | `client.bridge.createQuilttPaykey` | `straddle bridge create` (Quiltt token) |
| `createCharge` | `client.charges.create` | `straddle charges create` |
| `createPayout` | `client.payouts.create` | `straddle payouts create` |
| `deleteCustomer` | `client.customers.delete` | `straddle customers delete <id>` |
| `getUnmaskedCustomer` | `client.customers.listUnmasked` | `straddle customers unmasked get-customer` |
| `getUnmaskedPaykey` | `client.paykeys.listUnmasked` | `straddle paykeys unmasked get-paykey` |
| `getUnmaskedCharge` | `client.charges.listUnmasked` | `straddle charges unmask charges-v1-get` |
| `getUnmaskedPayout` | `client.payouts.listUnmasked` | `straddle payouts unmask payouts-v1-get` |
| `getUnmaskedRepresentative` | `client.representatives.listUnmasked` | `straddle representatives unmask get` |
| `getUnmaskedLinkedBankAccount` | `client.linkedBankAccounts.listUnmasked` | `straddle linked-bank-accounts unmask get-linked-bank-account-unmasked` |
| `revealPaykey` | `client.paykeys.reveal` | `straddle paykeys reveal get` |

The six unmask operations and paykey reveal return unmasked personal or bank data. Run them only when the approved plan needs them. Keep their output out of logs, plans, and evidence, and record only that the call succeeded and which ID it read.

## Operations outside the public contract

Run only operations in the public API contract, as [writes-and-approval.md](../../straddle-best-practices/references/writes-and-approval.md) requires. The CLI's command tree also includes internal commands outside that contract, and the existence of a command or SDK method is not evidence that its operation is public. When you cannot place an operation in the public contract and its account scope, stop before any preview.

## Other writes the fixture uses

| Operation | TypeScript SDK | Straddle CLI | API MCP |
| --- | --- | --- | --- |
| Create organization (`POST /v1/organizations`) | `client.organizations.create` | `straddle organizations create` | permitted after approval, but prefer the SDK or CLI so every fixture write shares one route |
| Create account (`POST /v1/accounts`) | `client.accounts.create` | `straddle accounts create` | same as above |

Webhook, FIFO, and polling endpoints are created in the Straddle dashboard by the developer, not by Integrate.

## Permitted API MCP reads

Use `execute-request` for independent verification reads that are not on the excluded list, such as `GET /v1/accounts/{account_id}`, `GET /v1/customers/{id}`, `GET /v1/charges/{id}` (read once, never in a loop), or exact external-ID lookups with `external_id` on `GET /v1/organizations`, `GET /v1/accounts`, `GET /v1/customers`, or `GET /v1/payments` (charges and payouts). Pass the acting account explicitly when the operation takes one, because the hosted MCP does not inherit CLI context. A successful call proves the caller's key works for that read. It proves nothing about the fourteen exclusions, which Scalar does not enforce.

## Idempotency by route

- **SDK.** Pass `Idempotency-Key` in the create params (10 to 40 characters). Derive it from the external ID and operation, for example `chg-order-a-0001`, so a retry of the same intent reuses it.
- **CLI.** Pass `--idempotency-key <key>` on every create. It first appears in CLI v1.0.3, so check the create's `--help`. When the installed CLI does not list it, run that create through the SDK instead. `--idempotent` is not a substitute: it treats an already-existing result as success and sends no key. `--dry-run` output does not show the key, so the preview states the key you will pass rather than reading it back from the dry run.

## Configuration checks by route

Neither tool reliably refuses a missing key for you, so check before calling either one.

- The CLI sends a request even when `STRADDLE_API_KEY` is unset. Integrate checks the key and environment first and does not run a live CLI command until both are present.
- The TypeScript SDK reads `BEARER`, not `STRADDLE_API_KEY`, when no `bearer` option is given, and it defaults to the Sandbox base URL. Application code passes `bearer` from `STRADDLE_API_KEY` explicitly and resolves the base URL from an explicit environment, and it throws a configuration error when either is missing.
