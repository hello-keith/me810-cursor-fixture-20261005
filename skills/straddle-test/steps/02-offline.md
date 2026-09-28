# Step 2: Offline checks

- **Needs:** step 1 summary.
- **Tools:** Read, Glob, Grep; Bash for the repository's own test commands. No file writes, and no Straddle request.
- **Next:** [03-preview.md](03-preview.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-test","step":"02-offline"}
```

Run the repository's test command from the plan, for example `npm test`, and record how many tests it ran. A command that passes with zero tests, or with no test that exercises a row below, is not coverage: that row is `missing`. Tests must stub the network through the SDK's `fetch` option or the repository's HTTP mock. When a test tries to reach a real Straddle host, stop it and record a finding.

Then read the tests and map them to this matrix. For each row, record `passed` with the test name, `failed` with the error, or `missing`:

- missing key, missing environment, and an unrecognized environment each fail with a configuration error, even when a base URL override is set, and the recorded request count stays zero
- each operation the integration uses sends or omits `Straddle-Account-Id` as [account-scope.md](../../straddle-best-practices/references/account-scope.md) requires for its integration type
- calls for account A carry A, calls for account B carry B, and neither leaks into the other
- a required account left unset fails locally, and the request count stays zero
- every create sends an `Idempotency-Key` and an external ID, and the key follows [writes-and-approval.md](../../straddle-best-practices/references/writes-and-approval.md): the same key for a retry of the same request, a distinct key for each other write, and 10 to 40 characters. A test that only checks the header is present leaves the rest `missing`
- the notification handler meets [receiving-webhooks.md](../../straddle-best-practices/references/receiving-webhooks.md): it accepts a valid signature, rejects a forged one, a stale timestamp, and missing headers, fails on a missing secret, persists before `2xx`, returns a non-`2xx` and stores nothing when the write fails, and ignores a duplicate `webhook-id`, including after a restart. When the selected SDK helper or library decodes the raw body as text before verifying, a body whose bytes do not decode losslessly is rejected before verification. For a polling endpoint, it commits the offset after persistence.

A `missing` row is a finding for Integrate. Do not write the test here.

**Summary for step 3:** the test command and result, and the matrix with each row's status and source.
