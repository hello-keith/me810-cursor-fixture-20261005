# Step 2: Offline checks

- **Needs:** step 1 summary.
- **Tools:** Read, Glob, Grep; Bash for the repository's own test commands. No file writes, and no Straddle request.
- **Next:** [03-preview.md](03-preview.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-test","step":"02-offline"}
```

Run the repository's test command from the plan, for example `npm test`. Tests must stub the network through the SDK's `fetch` option or the repository's HTTP mock. When a test tries to reach a real Straddle host, stop it and record a finding.

Then read the tests and map them to this matrix. For each row, record `passed` with the test name, `failed` with the error, or `missing`:

- missing key and missing environment each fail with a configuration error, and the recorded request count stays zero
- each operation the integration uses sends or omits `Straddle-Account-Id` as [account-scope.md](../../straddle-best-practices/references/account-scope.md) requires for its integration type
- calls for account A carry A, calls for account B carry B, and neither leaks into the other
- a required account left unset fails locally, and the request count stays zero
- every create sends an `Idempotency-Key` and an external ID
- the notification handler accepts a valid signature, rejects a forged one and missing headers, fails on a missing secret, persists before `2xx`, and ignores a duplicate `webhook-id`. For a polling endpoint, it commits the offset after persistence.

A `missing` row is a finding for Integrate. Do not write the test here.

**Summary for step 3:** the test command and result, and the matrix with each row's status and source.
