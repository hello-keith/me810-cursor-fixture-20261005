# Writes, idempotency, and approval

## The fourteen operations that never use `execute-request`

The hosted API MCP's `execute-request` can reach every operation a key allows. Scalar marks these fourteen as non-executable but does not enforce the flag, so route them through the released SDK or the Straddle CLI.

| Operation ID | Request |
| --- | --- |
| `createCustomer` | `POST /v1/customers` |
| `createBankAccountPaykey` | `POST /v1/bridge/bank_account` |
| `createPlaidPaykey` | `POST /v1/bridge/plaid` |
| `createQuilttPaykey` | `POST /v1/bridge/quiltt` |
| `createCharge` | `POST /v1/charges` |
| `createPayout` | `POST /v1/payouts` |
| `deleteCustomer` | `DELETE /v1/customers/{id}` |
| `getUnmaskedCustomer` | `GET /v1/customers/{id}/unmasked` |
| `getUnmaskedPaykey` | `GET /v1/paykeys/{id}/unmasked` |
| `getUnmaskedCharge` | `GET /v1/charges/{id}/unmask` |
| `getUnmaskedPayout` | `GET /v1/payouts/{id}/unmask` |
| `getUnmaskedRepresentative` | `GET /v1/representatives/{representative_id}/unmask` |
| `getUnmaskedLinkedBankAccount` | `GET /v1/linked_bank_accounts/{linked_bank_account_id}/unmask` |
| `revealPaykey` | `GET /v1/paykeys/{id}/reveal` |

Any `DELETE` added to the public contract later joins this list.

## Public contract only

Use only operations published in the public API contract (1.0.4). An operation outside it, or one whose contract or account scope you cannot confirm, is not run at all: not through `execute-request`, the SDK, or the CLI, even when a CLI command or SDK method exists for it. Stop, say so, and resolve it against the public contract before planning or running anything.

## Preview and approval

Before any remote write, show the developer:

- the environment (Sandbox for integration work) and the base URL it resolves to
- the integration type and acting account, or that the header is omitted and why
- each operation, the executing tool (SDK method, CLI command, or a permitted MCP operation), and a payload summary without secrets
- the idempotency key and external ID for each create

Proceed only after an explicit yes. A changed environment, account, operation, or payload needs a new approval. A denial means no request is sent.

## Idempotency

- Send an idempotency key on every create. Derive it from something stable for that intent, such as the external ID plus the operation, so a retry of the same intent reuses it.
- Give every created resource a stable, non-sensitive external ID.
- Use IDs returned by successful create responses in the next step's ID fields. Do not rediscover them with list calls.
- A charge's or payout's `paykey` field takes the full paykey token. It does not take the paykey `id`, or the masked `paykey` that `bank_account` and `plaid` creates return. Get the full token from `revealPaykey` or `getUnmaskedPaykey`, which are among the fourteen, so use the SDK or CLI after their own approval, or from a `quiltt` create response. Use it within one SDK process or one CLI command without printing it. Never write it to a plan, preview, log, report, test, evidence, or commit. Follow the contract field, not the value's shape.
- If a create result is unknown (timeout, dropped connection), retry with the same idempotency key or look up the exact external ID. Never loop on fresh creates.

## CLI writes

- Run `--dry-run` first and show its output as the preview. The dry run does not print the idempotency key, so list it in the preview yourself.
- Pass `--idempotency-key <key>` on every create. It sends the `Idempotency-Key` header. `--idempotent` is not a substitute: it only treats an already-existing result as a no-op and sends no key. `--idempotency-key` first appears in CLI v1.0.3 (tagged, not yet published). If the installed CLI's `--help` for that create does not list it, do not run the create through the CLI; use the SDK's idempotency option instead.
- Add `--agent` for JSON output and non-interactive mode.
- Pass IDs from one response straight into the next command. Do not write tool JSON to temporary files or pipe it through `jq`.
