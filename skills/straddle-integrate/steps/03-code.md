# Step 3: Code

- **Needs:** summaries from steps 1 and 2.
- **Tools:** Read, Glob, Grep; Write and Edit only on files in the plan's file-change table; Bash only for the repository's own test, build, and lint commands and the SDK install step 2 allows. No Straddle request.
- **Next:** [04-preview.md](04-preview.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-integrate","step":"03-code"}
```

Make the approved changes in the repository's own style. Before each Write or Edit, confirm the path is in the approved list. Add to existing files with Edit, and never rewrite a whole existing file. Do not delete, rename, or reformat code the plan does not mention. When an unlisted file needs to change, stop and ask. Say which file and why, and continue only after the developer approves and the plan's table is updated.

## What the code must do

- **Configuration.** Build the SDK client in one place. Read the key from `STRADDLE_API_KEY` and pass it as the client's credential option explicitly. Resolve the base URL from an explicit environment, for example `STRADDLE_ENVIRONMENT=sandbox`. When either is missing or unknown, throw a configuration error before any request is built. Do not rely on SDK defaults: the TypeScript and Python SDKs read `BEARER` and silently default to Sandbox.
- **Account scope.** Follow the plan's per-operation header rules from [account-scope.md](../../straddle-best-practices/references/account-scope.md). Use the SDK's `Straddle-Account-Id` param, and do not hand-build headers. When an operation requires an acting account and none is selected, fail locally before the request. Make switching accounts a parameter of the call, not global mutable state, so A and B cannot leak into each other.
- **Idempotency.** Every create sends a stable `external_id` and an `Idempotency-Key` of 10 to 40 characters, derived deterministically from the operation and external ID and shortened with a stable digest when needed, per [Idempotency by route](../references/execution-routes.md#idempotency-by-route). The same request always gets the same key, and different requests never share one. Recovery after an unknown result retries with the same key or does an exact external-ID lookup. It never loops on fresh creates.
- **Returned values.** Pass IDs from create responses to the next call's ID fields (the customer ID into the Bridge paykey create, for example). Do not rediscover them with list calls. A charge's or payout's `paykey` field takes the full paykey token, not the paykey's ID, and a Bridge `bank_account` or `plaid` create returns that token masked. Follow [Paykey tokens for charges and payouts](../references/execution-routes.md#paykey-tokens-for-charges-and-payouts), and never log or persist the token.
- **Notifications.** Implement the handler for the plan's endpoint type exactly as the Best Practices [Endpoint types](../../straddle-best-practices/references/receiving-webhooks.md#endpoint-types) describes. A FIFO request is a batch, signed with `svix-*` headers, in whatever shape its endpoint's transformation produces. Parse the shape the plan records from a captured delivery or the dashboard's transformation test output, and when the plan records none, ask the developer for one before writing the parser. A polling consumer must commit each batch. For a platform, route on `account_id`.
  - **Webhook or FIFO endpoint.** Verify with the SDK's webhook helper, or `standardwebhooks` when the SDK has none, and accept the `svix-*` headers as well as `webhook-*`. Always pass the request's headers: the TypeScript SDK's `client.webhooks.unwrap` skips verification when `headers` is undefined.
  - Do not add a loop that re-reads a charge, payout, account, or list endpoint to detect status changes.
- **Onboarding** (platform plans): follow [onboarding.md](../references/onboarding.md). Use the hosted iframe with `env=sandbox` and a required external ID, with no React wrapper and no invented completion callback.
- **Tests.** Add or extend the plan's tests, using the SDK's `fetch` option or the repository's HTTP mock so tests send no network request. Cover the configuration error with zero requests, header present and omitted for each rule the integration uses, A-to-B switching, the missing-account local failure with zero requests, idempotency keys on creates, and the notification handler for its endpoint type: for a webhook, valid signature, forged signature, duplicate, and missing secret; for FIFO, a batch in the captured shape signed with `svix-*` headers stored in order, a forged batch rejected, a retried batch that stores no duplicate, and a failed write that stores nothing and returns non-`2xx`; for polling, a commit after storing and a `423` before it. For every type, cover the status projection's `changed_at` tie and a re-delivered earlier status, per [Ordering status changes](../../straddle-best-practices/references/receiving-webhooks.md#ordering-status-changes).

Run the repository's tests after the changes, and fix failures in the files you changed. When a failure is in code you did not touch, report it instead of editing that code. When the client's command sandbox blocks the test runner, follow Test's [offline step](../../straddle-test/steps/02-offline.md) instead of asking to run outside it.

**Summary for step 4:** each changed file with a one-line description, tests added and their result, and anything left unchanged on purpose.
