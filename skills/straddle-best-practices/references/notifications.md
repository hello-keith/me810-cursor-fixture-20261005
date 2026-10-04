# Notifications

Straddle reports status changes through three endpoint types. Use the webhook endpoint by default. Choose FIFO or polling only when its condition below applies, and record the choice in the plan.

| Endpoint | Choose it when |
| --- | --- |
| Webhook endpoint | The default. You can expose a public HTTPS handler. |
| FIFO endpoint | You can expose a public HTTPS handler and need strict order more than throughput. |
| Polling endpoint | You cannot expose a public URL, for local development, or for batch processing. |

Each type is created in the Straddle dashboard. Streaming is coming later and isn't available today.

## What is not a notification model

- Looping on an ordinary resource read, such as `GET /v1/charges/{id}`, `GET /v1/payouts/{id}`, or a list endpoint, with a sleep between calls to see whether a status changed. It is slow, rate-limited, and misses intermediate states such as `paid` before `reversed`.
- The CLI's `straddle tail`, which polls the API the same way.
- Dashboard email. It is a confirmation for a person, not an input to code.

Reading a resource once, for example to show its current state on a page or to reconcile after an event arrives, is fine.

## Handling deliveries

How each type delivers events and how to handle it, including FIFO batches and the polling endpoint's commit, is in [Endpoint types](receiving-webhooks.md#endpoint-types). The rest of [receiving-webhooks.md](receiving-webhooks.md) covers signature verification from the raw body, prompt `2xx` responses, retries, and duplicate delivery.
