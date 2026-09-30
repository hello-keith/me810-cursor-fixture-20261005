# Bridge and paykeys

Every status, field, and operation in backticks is checked against API contract 1.0.4 by `scripts/check-contract-tokens`. Facts marked "Observed in Sandbox" come from Sandbox runs, not from the contract or the docs. For details beyond this page, search the Docs MCP by concept, for example "Bridge widget", "paykeys", "paykey review", or "unblock a paykey".

## What it is

Bridge connects a customer's bank account and returns a paykey: a token that stands for that customer and that account. Charges and payouts take the paykey token instead of bank details. Bridge matches the account holder's name against the customer, so create the customer first ([customers-identity.md](customers-identity.md)).

Ways to create a paykey, each with the customer's `customer_id`, an optional `external_id`, `metadata`, and `config`:

| Path | Operation | You send | `source` |
| --- | --- | --- | --- |
| Bridge widget | `createBridgeToken`, then the widget in the browser | `customer_id`. The response has a `bridge_token` for the widget. | Depends on how the customer connects. |
| Bank account details | `createBankAccountPaykey` | `routing_number`, `account_number`, and `account_type` (`checking` or `savings`) | `bank_account` |
| Plaid | `createPlaidPaykey` | `plaid_token`, a Plaid processor token | `plaid` |
| Quiltt | `createQuilttPaykey` | `quiltt_token`, a Quiltt processor token | `quiltt` |

`source` can also be `straddle`, `mx`, or `tan`. Straddle's docs describe a Mastercard Open Finance path, but API contract 1.0.4 has no Mastercard operation, so it's outside the public contract and isn't run ([Public contract only](writes-and-approval.md#public-contract-only)). Straddle's docs say the widget's success callback fires for paykeys in `active` or `review`, so check the returned status there too.

The three paykey creates run only through the SDK or CLI after approval ([writes-and-approval.md](writes-and-approval.md)).

**The token.** A payment's `paykey` field takes the full token, not the paykey `id`. The `bank_account` and `plaid` create responses mask it. `revealPaykey` and `getUnmaskedPaykey` return it: both run only through the SDK or CLI after approval, and `getUnmaskedPaykey`, which also unmasks the bank details, needs Straddle to enable unmasking for the account (`allow_data_unmask`). The `paykey.created.v1` and `paykey.event.v1` payloads carry the full token too. Treat it as a secret: store it encrypted, and never log it or send it to a browser. [Idempotency](writes-and-approval.md#idempotency) has the handling rules.

## States and transitions

`status` is `pending`, `active`, `review`, `rejected`, `blocked`, or `inactive`. Only `active` paykeys can be used for payments.

| Status | How it gets there | What you can do |
| --- | --- | --- |
| `pending` | Verification is running. | Wait for the event. |
| `active` | Verification passed, a review was accepted, or a block was lifted. | Create payments, `cancelPaykey`. |
| `review` | Verification needs a decision. | `getPaykeyReview`, then `setPaykeyVerificationDecision`. |
| `rejected` | Verification failed, or a review was rejected. | Nothing. Ask for another account. |
| `blocked` | Returns made the account unsafe, such as an R29. | `unblockPaykey` once, when `unblock_eligible` is `true`. |
| `inactive` | Cancelled. | Nothing. Cancelling can't be undone. |

- **Review.** `getPaykeyReview` returns `paykey_details` and `verification_details`: a `decision` (`accept`, `reject`, or `review`), `messages`, and a `breakdown` with `name_match` (`names_on_account`, `matched_name`, `customer_name`, `correlation_score`, `decision`, `reason`, `codes`) and `account_validation` (`decision`, `reason`, `codes`). Decide with `setPaykeyVerificationDecision` and `status` `active` or `rejected`, only while the paykey is `review`. `refreshPaykeyReview` starts a new review asynchronously. Observed in Sandbox: a decision on an `active` paykey returned `422`.
- **R29 block and the one unblock.** An R29 return moves the paykey to `blocked` with `status_details.code` R29. `unblock_eligible` is `true` only for an R29 block that has never been unblocked, `false` for other blocks, and `null` when the paykey isn't blocked. `unblockPaykey` (optional `message`) lifts it once. Observed in Sandbox: the unblock returned the paykey to `active` with `source` `user_action`, and payments created during the block failed with `invalid_paykey`.
- **Cancel.** `cancelPaykey` (optional `reason`) moves the paykey to `inactive` for good. Observed in Sandbox: `status_details.reason` `cancel_request`, `source` `user_action`.
- **Balance.** `refreshPaykeyBalance` starts a balance refresh and returns before it finishes. `balance.status` is `pending`, `completed`, or `failed`, and `balance.account_balance` holds the result in cents.
- `expires_at`, when set, is when the paykey stops working.

## What your app must handle

- Save the paykey `id`, the `label` for display, and the token as a secret, keyed to your customer.
- Create payments only on `active` paykeys. On `review`, either decide it yourself with the review evidence, or show "verifying your bank account" until an event settles it.
- On `rejected`, ask for another bank account or another connection method.
- On `blocked`, stop payments and tell the customer. Offer the unblock only when `unblock_eligible` is `true`, and only after the customer confirms the debit was authorized, because there's no second one.
- Let customers remove a bank account with `cancelPaykey`, and stop using the token right away.
- Expect the paykey to change status after creation, and project it from events, not from the create response.

## Events and Sandbox outcomes

- `paykey.created.v1` on create and `paykey.event.v1` on every change: verification, review decisions, blocks, unblocks, cancels, and balance refreshes ([webhooks.md](webhooks.md)).
- The event schema lists fewer `status_details.reason` values than the REST schema. Observed in Sandbox: paykeys carried `failed_verification` and `cancel_request`, which only the REST list has. Don't reject an event for an unknown reason.
- Sandbox: set `config.sandbox_outcome` on the create to `standard`, `active`, `review`, or `rejected`. Observed in Sandbox with bank account details: `active`, `review`, and `rejected` were set in the create response, and `standard` ran the real checks and returned `rejected` (`failed_verification`, `watchtower`) for the test identity. A charge with `failed_not_authorized` blocked the paykey with R29. See [sandbox-outcomes.md](sandbox-outcomes.md).
