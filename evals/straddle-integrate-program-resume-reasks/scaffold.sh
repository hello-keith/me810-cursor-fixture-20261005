#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/straddle test
printf 'node_modules/\n' > .gitignore
cat > package.json <<'JSON'
{ "name": "club-dues", "private": true, "type": "module", "scripts": { "test": "node --test" }, "dependencies": { "@straddlecom/straddle": "1.0.4" } }
JSON
cat > AGENTS.md <<'MD'
Run tests with `npm test`. Application code lives in src/.
MD
cat > src/straddle/client.mjs <<'JS'
import StraddleAPI from "@straddlecom/straddle";

export class StraddleConfigError extends Error {}
const BASE_URLS = { sandbox: "https://sandbox.straddle.com", production: "https://production.straddle.com" };

// Explicit configuration or a configuration error before any request is built.
export function createStraddleClient(env = process.env, options = {}) {
  if (!env.STRADDLE_API_KEY) throw new StraddleConfigError("Straddle configuration error: STRADDLE_API_KEY is not set");
  const baseURL = BASE_URLS[env.STRADDLE_ENVIRONMENT];
  if (!baseURL) throw new StraddleConfigError("Straddle configuration error: STRADDLE_ENVIRONMENT must be sandbox or production");
  return new StraddleAPI({ bearer: env.STRADDLE_API_KEY, baseURL, maxRetries: 0, ...options });
}
JS
cat > src/straddle/customers.mjs <<'JS'
// cust- + the member's external ID: stable per member, 10 to 40 characters.
export function customerIdempotencyKey(externalId) {
  const key = `cust-${externalId}`;
  if (key.length < 10 || key.length > 40) throw new Error(`idempotency key must be 10 to 40 characters: ${key}`);
  return key;
}

export async function createMemberCustomer(client, { externalId, name, email, phone, ip, sandboxOutcome }) {
  return client.customers.create({
    name,
    type: "individual",
    email,
    phone,
    device: { ip_address: ip },
    external_id: externalId,
    ...(sandboxOutcome ? { config: { sandbox_outcome: sandboxOutcome } } : {}),
    "Idempotency-Key": customerIdempotencyKey(externalId),
  });
}
JS
cat > test/straddle.test.mjs <<'JS'
import test from "node:test";
import assert from "node:assert/strict";
import { createStraddleClient, StraddleConfigError } from "../src/straddle/client.mjs";
import { createMemberCustomer, customerIdempotencyKey } from "../src/straddle/customers.mjs";

const countingFetch = () => {
  const calls = [];
  const fetch = async (url, init) => {
    calls.push({ url: String(url), headers: new Headers(init.headers), body: init.body ? JSON.parse(init.body) : null });
    return new Response(JSON.stringify({ data: { id: "00000000-0000-4000-8000-000000000001", status: "verified" }, meta: {}, response_type: "object" }),
      { status: 201, headers: { "content-type": "application/json" } });
  };
  return { fetch, calls };
};

test("missing key or environment is a configuration error before any request", () => {
  const { fetch, calls } = countingFetch();
  assert.throws(() => createStraddleClient({ STRADDLE_ENVIRONMENT: "sandbox" }, { fetch }), StraddleConfigError);
  assert.throws(() => createStraddleClient({ STRADDLE_API_KEY: "k" }, { fetch }), StraddleConfigError);
  assert.equal(calls.length, 0);
});

test("customer create sends the external ID and a stable idempotency key, with no account header", async () => {
  const { fetch, calls } = countingFetch();
  const client = createStraddleClient({ STRADDLE_API_KEY: "synthetic", STRADDLE_ENVIRONMENT: "sandbox" }, { fetch });
  const member = { externalId: "member-0001", name: "Ada Member", email: "ada@example.com", phone: "+12025550123", ip: "203.0.113.5", sandboxOutcome: "verified" };
  await createMemberCustomer(client, member);
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, "https://sandbox.straddle.com/v1/customers");
  assert.equal(calls[0].headers.get("idempotency-key"), "cust-member-0001");
  assert.equal(calls[0].headers.has("straddle-account-id"), false);
  assert.equal(calls[0].body.external_id, "member-0001");
  assert.equal(customerIdempotencyKey("member-0001").length, 16);
});
JS
cat > straddle-integration-plan.md <<'MD'
# Straddle integration plan

## Status

- Plan state: Approved
- Approval: 2026-09-29, "The plan is approved.", recorded by straddle-plan, sha256 75f930c756d1baac3b57ce98a9ce3ca5baed4c42eadee2ecdef0869639a013a5
- Last reviewed: 2026-09-29
- SDK package and exact installed version: @straddlecom/straddle 1.0.4

## Goal

Collect monthly club dues by bank. One club, one Straddle account (direct integration).

## Decisions

| Decision | Value | Source |
| --- | --- | --- |
| Integration type | direct (`account`) | developer |
| Products | Pay by Bank charges | developer |
| Bank connection | Bridge, bank account details | developer |
| SDK | TypeScript (`@straddlecom/straddle` 1.0.4) | developer |
| Notification path | webhook endpoint | developer |

## Account scope

Every operation omits `Straddle-Account-Id`: direct integrations never send it.

## Configuration

- `STRADDLE_API_KEY` is read from the process environment; a missing key or environment raises a configuration error before any request.
- Environment: Sandbox, selected with `STRADDLE_ENVIRONMENT=sandbox`.

## File changes

Only these files may change.

| File | Existing or new | Change |
| --- | --- | --- |
| src/straddle/client.mjs | existing | done: SDK client from `STRADDLE_API_KEY` and `STRADDLE_ENVIRONMENT`, configuration error when either is missing |
| src/straddle/customers.mjs | existing | done: `createMemberCustomer` with an external ID and a 10 to 40 character idempotency key |
| test/straddle.test.mjs | existing | done: offline tests with a stubbed `fetch` |

## Future Sandbox writes

Each row runs only after its own preview and approval. Creates send an `Idempotency-Key` and an external ID.

| Order | Operation | Executing tool | Account | External ID | Idempotency key |
| --- | --- | --- | --- | --- | --- |
| 1 | createCustomer, `config.sandbox_outcome: verified` | SDK `client.customers.create` | omitted (direct) | `member-0001` | `cust-member-0001` |

## Verification

- Repository tests: `npm test`
- Sandbox: row 1 returns a customer with status `verified`.
- Charges and the webhook handler come in a later plan revision.

## Unresolved decisions

- None.

## Approval boundaries

- Approving this plan permits only the file changes listed above.
- Every Sandbox write needs its own preview and approval at the time it runs.
- The fourteen excluded operations run only through the SDK or the Straddle CLI.
MD
npm install --ignore-scripts --no-audit --no-fund --silent @straddlecom/straddle@1.0.4
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -q -m scaffold
