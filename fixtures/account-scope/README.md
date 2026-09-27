# Account-scope corpus

`vectors.json` is the shared, language-neutral corpus for the `Straddle-Account-Id` rules. Every SDK qualification runs the same file through its own request layer, without a live API call, and must fail when any vector disagrees.

## Where the expectations come from

The file is generated, not hand-written. `derive.ts` compiles `derive/export_corpus_test.go` into the `straddle-cli` `internal/straddleacct` package through `go test -overlay`, so each expected outcome is the result of the CLI's own `Classify` and `Resolve` functions over the operations in the CLI's `spec.yaml`. The exporter refuses to run unless `spec.yaml` matches the digest in `contract.lock.json`, and `derive.ts` refuses a dirty CLI checkout, so the `contract` and `policy_source` blocks at the top of the file identify exactly what produced it. Nothing in the CLI checkout is modified.

```sh
npm ci
npm run derive -- ../../../straddle-cli        # rewrite vectors.json
npm run derive:check -- ../../../straddle-cli  # fail if vectors.json is stale
```

Deriving needs Go and a clean `straddle-cli` checkout; running the corpus does not.

## File format

- `accounts` holds two synthetic embedded-account IDs, A and B. They are not real accounts.
- `operations` lists every operation in the contract with its operation ID, method, path, resource and whether the contract declares the header.
- `vectors` crosses each integration type (`direct`, `saas`, `marketplace`) with each operation and four acting-account conditions: none, selected A, explicit A, and selected A with an explicit B override. Every vector names its integration type, operation, the CLI policy (`require`, `allow` or `forbid`) and the expected result.
- `scenarios` are ordered or concurrent flows: A-to-B switching with an explicit per-call override that must not stick, clearing the selection so a required operation is rejected, direct credential scope, and concurrent callers sharing one credential, using separate credentials, or with one caller missing its account.

An `acting_account.selected` value is the application's current acting account. An `explicit` value is a per-call override and wins whenever it is present, which matches the CLI's `--account` flag. The expected result is one of:

- `{"outcome": "request", "header": "present", "value": "<id>", "outbound_requests": 1}`
- `{"outcome": "request", "header": "absent", "outbound_requests": 1}`
- `{"outcome": "local_rejection", "reason": "required" | "forbidden", "outbound_requests": 0}`

`required` means the operation needs an acting account and none was available. `forbidden` means the caller explicitly named an account for an operation that never carries the header, such as organization and account management, every direct-integration call, or marketplace customer, paykey and Bridge calls. A selected account on such an operation is silently omitted instead.

## Running an SDK against the corpus

A conforming runner does four things for each vector and scenario step:

1. **Preflight in the application.** Decide the header from the integration type, operation and acting account before touching the SDK, and raise a local error for `required` and `forbidden`. The generated SDKs only transmit the header when a call passes it; they do not know the integration type, so this decision cannot come from the SDK.
2. **Call the real SDK method.** Bind every operation ID in `operations` to the SDK method for that operation, and fail if either side has an unbound entry.
3. **Record outbound requests.** Point the SDK at a loopback HTTP server, or another supported transport seam, with retries disabled, and record every request's method, path and headers.
4. **Compare and fail loudly.** Check the outbound request count (zero for rejections), the method and path, and the header's presence and exact value. Print the vector ID and operation for every mismatch and exit nonzero.

## TypeScript reference runner

`runner.ts` qualifies the published `@straddlecom/straddle` 1.0.4 from npm, pinned in `package-lock.json`. It uses the package's own fetch-based request layer against a `127.0.0.1` server with synthetic credentials, and refuses to run if a different SDK version is installed. `account-scope.ts` is the reference application preflight; it mirrors the CLI rules and is proven by the corpus rather than trusted.

```sh
npm ci
npm run corpus      # all 840 vectors and 9 scenarios
npm test            # the corpus run plus controlled negative proofs
npm run typecheck
```

`runner.test.ts` corrupts one vector at a time and runs the real runner: a wrong expected header value, and a claimed zero-request rejection where the SDK really sends a request. Both runs exit 1 and name the vector. A third test shows the SDK itself sends an unscoped marketplace charge, which is why the preflight exists.

## What this does not prove

The corpus proves SDK request construction and application preflight offline. It does not prove how the Straddle API or the hosted Scalar MCP treats these headers, and the A/B cases show client-side isolation, not server-side authorization. Those remain separate live acceptance checks.
