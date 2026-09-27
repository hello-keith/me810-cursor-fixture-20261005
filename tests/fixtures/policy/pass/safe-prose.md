# Rules that name forbidden actions

Never poll `GET /v1/charges/{id}` to discover a status change. Instead of polling `GET /v1/payouts/{id}` in a loop,
subscribe to a webhook, FIFO or polling endpoint.

After the webhook arrives, call `GET /v1/charges/{id}` once to show the charge details.

Do not read `.env` files. Add `.env` to `.gitignore` so it is never committed.

Never print the API key, and confirm only that `STRADDLE_API_KEY` is set.

Never use `execute-request` to create a charge. Use `execute-request` for permitted reads, never for creating a
customer. Customer, paykey and payment creation use the SDK or CLI, not `execute-request`.

Check whether the key is present before any request.

Do not use `straddle tail` to watch payment status.

```ts
const apiKey = process.env.STRADDLE_API_KEY;
if (!apiKey) {
  console.error("Missing STRADDLE_API_KEY");
  throw new Error("STRADDLE_API_KEY is not set");
}

export async function onChargeEvent(event) {
  const charge = await client.charges.get(event.data.id);
  await recordStatus(charge.data.status);
}
```

Do not advertise or execute internal or unknown operations, such as the internal Bridge TAN or Speedchex create
commands, through `execute-request` or an SDK or CLI fallback. When an operation is missing from the public contract
or its scope is unknown, stop and resolve it against the public contract before any request.

Inspect `straddle tail --help` to learn why it is not a notification model.

List charges with a permitted read:

```json
{"tool": "execute-request", "method": "GET", "path": "/v1/charges"}
```
