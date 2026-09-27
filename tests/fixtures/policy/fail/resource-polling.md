# Resource polling

Poll `GET /v1/charges/{id}` every 5 seconds until the status is `paid`.

```ts
while (true) {
  const charge = await fetch(`${baseUrl}/v1/charges/${chargeId}`);
  if ((await charge.json()).data.status === "paid") break;
  await sleep(5000);
}
```

```python
while charge.status != "paid":
    time.sleep(5)
    charge = client.charges.get(charge_id)
```

```sh
watch -n 5 straddle charges get "$CHARGE_ID"
```

Run `straddle tail charges --interval 5s` to watch for the `paid` status.

```sh
straddle tail charges --interval 5s
```

Poll `GET /v1/charges/{id}` every 5 seconds in the consumer.
