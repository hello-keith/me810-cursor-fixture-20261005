# Step 4: Sandbox scenarios

- **Needs:** step 3 summary with the approved rows.
- **Tools:** the selected SDK through the repository's code or test tooling; Bash for approved CLI commands with `--agent`; Read on the notification handler's stored events or the polling consumer's stored offset. No `execute-request` writes.
- **Next:** [05-verify.md](05-verify.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-test","step":"04-sandbox"}
```

Check configuration again before the first request. When it is missing, send nothing and go to step 6.

Execute the approved rows as in Integrate's [execute step](../../straddle-integrate/steps/05-execute.md): the same reuse, returned-ID chaining, same-key recovery for unknown results, and stop-on-failure rules. Prefer the developer's application code path for the primary charge, so the test exercises what ships.

For each scenario, record the evidence below. A create response only shows that Straddle accepted the request, for a charge typically with status `created`. Record that as the resource's initial status. `paid`, `reversed`, and `R01` count only when they arrive through the notification path.

- **Success.** Charge ID, acting account, and the `paid` transition as delivered through the notification path.
- **Failure and return.** Every delivered transition in order. It passes only when `paid` arrives before `reversed` and the status detail carries `R01`.
- **Retry.** Repeating the exact create with the same idempotency key returns the original resource ID, and `Idempotent-Replayed: true` when the response exposes it, or the exact external-ID lookup finds exactly one resource. Record the first and repeated responses' replay values separately. Only that Straddle Sandbox response proves server-side idempotency. A test or mock that shows the client resent the same key proves key preservation only.
- **A/B switching.** Each result's account matches the account used for its request, and header-omitted operations were sent without the header. Take this from the application's request log or the SDK's `fetch` hook, not from inference.
- **Onboarding.** The API-created account resolved by exact external ID or by its account event, and used for an account-scoped payment.
- **Notification.** Only events Straddle delivered count. Signed test deliveries you send to the receiver yourself prove the handler, which is step 2's row, not Straddle delivery or FIFO order. For each delivered event: `webhook-id` or `event_id`, event type, status, account ID, and whether the handler persisted it once and returned `2xx`. For a polling endpoint: the consumer ID and offsets.

Wait at most ten minutes for transitions. Do not poll `GET /v1/charges/{id}`, payout, account, or list reads for status, and do not use `straddle tail`. When the window ends, record the missing transitions as `not observed`.

**Summary for step 5:** each scenario's result and evidence, and every server-side resource created, reused, or observed.
