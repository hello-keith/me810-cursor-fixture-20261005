# Consume the Straddle polling endpoint

Use the polling endpoint when your server cannot receive webhooks. Read from the URL and token issued when you create
the endpoint, keep one consumer ID per worker, and store the returned offset so the next request resumes after it.

Poll the polling endpoint every 5 seconds. When an event names a charge, call `GET /v1/charges/{id}` once to show
its details.

```ts
const pollingUrl = process.env.STRADDLE_POLLING_URL;
const pollingToken = process.env.STRADDLE_POLLING_TOKEN;
let offset = await loadOffset("charges-worker");

while (true) {
  const response = await fetch(`${pollingUrl}/consumer/charges-worker?iterator=${offset}`, {
    headers: { Authorization: `Bearer ${pollingToken}` },
  });
  const batch = await response.json();
  for (const event of batch.data) {
    await handleEvent(event);
  }
  offset = batch.iterator;
  await saveOffset("charges-worker", offset);
  if (batch.done) {
    await sleep(5000);
  }
}
```

Run the poller against the polling endpoint every 5 seconds and store each offset.
