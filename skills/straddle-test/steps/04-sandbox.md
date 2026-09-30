# Step 4: Sandbox scenarios

- **Needs:** step 3 summary with the approved rows.
- **Tools:** the selected SDK through the repository's code or test tooling; Bash for approved CLI commands with `--agent`; Read on the notification handler's stored events or the polling consumer's committed offset. No `execute-request` writes.
- **Next:** [05-verify.md](05-verify.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-test","step":"04-sandbox"}
```

Check configuration again before the first request. When it is missing, send nothing and go to step 6.

Execute the approved rows as in Integrate's [execute step](../../straddle-integrate/steps/05-execute.md): the same reuse, returned-ID chaining, same-key recovery for unknown results, and stop-on-failure rules. Prefer the developer's application code path for the primary charge, so the test exercises what ships.

For each scenario, record the evidence below. A create response only shows that Straddle accepted the request, for a charge typically with status `created`. Record that as the resource's initial status. `paid`, `reversed`, and `R01` count only when they arrive through the notification path.

- **Success.** Charge ID, acting account, and the `paid` transition as delivered through the notification path.
- **Failure and return.** Every delivered transition, with its status, `data.status_details.changed_at`, and return code, and separately its arrival time at the endpoint. It passes only when `changed_at`, the contract's time the status changed, puts `paid` before `reversed` and the reversed status detail carries `R01`. Build the lifecycle from those payload fields, not from arrival time or the `webhook-timestamp` header, which is the signature send time. Straddle's [Sandbox Pay by Bank troubleshooting](https://docs.straddle.com/guides/resources/sandbox-paybybank) notes deliveries can arrive out of order. When a transition's payload has no `changed_at`, record its order as `not verified`. On a webhook endpoint, arrival order is the order you observed, not a lifecycle guarantee ([receiving-webhooks.md](../../straddle-best-practices/references/receiving-webhooks.md)), so do not require chronological arrivals there. On a FIFO endpoint, assess arrival order as its own check.
- **Retry.** Repeat the exact create with the same idempotency key. It passes only when the repeated response returns the original resource ID, with `Idempotent-Replayed: true` when the response exposes it. Record the first and repeated responses' replay values separately. That live Sandbox response is the only evidence of server-side idempotency. A test or mock showing that the client resent the same key proves key preservation only. After an unknown result, an exact external-ID lookup that finds exactly one resource is recovery evidence that the resource exists once, not proof that the server enforced the key.
- **A/B switching.** Each result's account matches the account used for its request, and header-omitted operations were sent without the header. Take this from the application's request log or the SDK's `fetch` hook, not from inference.
- **Onboarding.** The API-created account resolved by exact external ID or by its account event, and used for an account-scoped payment.
- **Notification.** Only events Straddle delivered count. Signed test deliveries you send to the receiver yourself prove the handler, which is step 2's row, not Straddle delivery or FIFO order. For each delivered event: `webhook-id` or `event_id`, event type, status, account ID, and whether the handler stored it once. Judge delivery against [Endpoint types](../../straddle-best-practices/references/receiving-webhooks.md#endpoint-types): a webhook endpoint returned `2xx` per event, a FIFO endpoint's batches passed `svix-*` verification and were stored whole and in order before each `2xx`, and a polling consumer committed each batch's last offset. For a FIFO endpoint, record the batch sizes. For a polling endpoint, record the consumer ID and offsets.

Wait at most ten minutes for transitions. Do not poll `GET /v1/charges/{id}`, payout, account, or list reads for status, and do not use `straddle tail`. When the window ends, record the missing transitions as `not observed`.

**Summary for step 5:** each scenario's result and evidence, and every server-side resource created, reused, or observed.
