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

Any `DELETE` added to the contract later joins this list. When unsure whether an operation is on it, treat it as excluded.

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
- Use the IDs returned by successful create responses in the next step. Do not rediscover them with list calls.
- If a create result is unknown (timeout, dropped connection), retry with the same idempotency key or look up the exact external ID. Never loop on fresh creates.

## CLI writes

- Run `--dry-run` first and show its output as the preview. The dry run does not print the idempotency key, so list it in the preview yourself.
- Pass `--idempotency-key <key>` on every create. It sends the `Idempotency-Key` header. `--idempotent` is not a substitute: it only treats an already-existing result as a no-op and sends no key. `--idempotency-key` first appears in CLI v1.0.3 (tagged, not yet published). If the installed CLI's `--help` for that create does not list it, do not run the create through the CLI; use the SDK's idempotency option instead.
- Add `--agent` for JSON output and non-interactive mode.
- Pass IDs from one response straight into the next command. Do not write tool JSON to temporary files or pipe it through `jq`.
