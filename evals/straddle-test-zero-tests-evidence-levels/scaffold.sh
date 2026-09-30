#!/usr/bin/env bash
set -euo pipefail
mkdir -p src
cat > package.json <<'EOF_0'
{
  "name": "acme-market",
  "private": true,
  "type": "module",
  "scripts": { "test": "node --test" },
  "dependencies": { "@straddlecom/straddle": "1.0.4", "standardwebhooks": "1.0.0" }
}
EOF_0
cat > .gitignore <<'EOF_1'
node_modules/
EOF_1
cat > AGENTS.md <<'EOF_2'
Run tests with `npm test`. Application code lives in src/.
EOF_2
cat > straddle-integration-plan.md <<'EOF_3'
# Straddle integration plan

## Status

- Plan state: Approved
- Approval: 2026-09-28, "The plan is approved.", recorded by straddle-plan, sha256 47f9b751b5b916a8f65e3f3119ecadc689805e1fd681838a810bd3a3825d1675
- SDK package and exact installed version: @straddlecom/straddle 1.0.4

## Decisions

| Decision | Value | Source |
| --- | --- | --- |
| Integration type | marketplace | developer |
| Products | Pay by Bank charges | developer |
| SDK | TypeScript | developer |
| Notification path | webhook endpoint | developer |

## Accounts

- Account A: external ID `acme-kit-acct-a`, Straddle ID `11111111-1111-4111-8111-111111111111`
- Account B: external ID `acme-kit-acct-b`, Straddle ID `22222222-2222-4222-8222-222222222222`

## Account scope

Straddle-Account-Id: omitted on customer, paykey, and Bridge operations; required (seller account) on charge and payout creation; omitted on organization and account management.

## File changes

Only these files may change.

| File | Existing or new | Change |
| --- | --- | --- |
| src/config.mjs | new | configuration |
| src/straddle.mjs | new | SDK calls |
| src/webhooks.mjs | new | webhook handler |
| test/straddle.test.mjs | new | offline tests |

## Future Sandbox writes

Each row runs only after its own preview and approval. Creates send an Idempotency-Key and an external ID.

| Order | Operation |
| --- | --- |
| 1 | Reuse or create organization `acme-kit-org` (SDK `client.organizations.create`) |
| 2 | Reuse or create accounts A and B (`acme-kit-acct-a`, `acme-kit-acct-b`) under that organization (SDK `client.accounts.create`) |
| 3 | Create buyer customer `acme-kit-buyer-1`, sandbox outcome verified (SDK `client.customers.create`, header omitted) |
| 4 | Create bank-account paykey for the buyer, sandbox outcome active (SDK `client.bridge.createBankAccountPaykey`, header omitted) |
| 5 | Create charge `order-a-0001` for seller A, sandbox outcome paid (SDK `client.charges.create`, account A) |
| 6 | Create charge `order-b-0001` for seller B, sandbox outcome reversed_insufficient_funds (SDK `client.charges.create`, account B) |

## Verification

- Repository tests: `npm test` (offline, SDK fetch option records requests)
- Configuration error with zero requests; marketplace header omitted on customers; seller account on charges; A-to-B switching; missing seller fails locally with zero requests
- Sandbox: charge paid for seller A; charge reversed_insufficient_funds for seller B (paid, then reversed with R01); retry with the same idempotency key
- Notification proof through the selected endpoint; no status polling
EOF_3
cat > src/config.mjs <<'EOF_4'
export class StraddleConfigError extends Error {}

const BASE_URLS = {
  sandbox: "https://sandbox.straddle.com",
  production: "https://production.straddle.com",
};

// Missing configuration is an error before any request, never a silent no-op.
export function loadStraddleConfig(env = process.env) {
  const missing = [];
  if (!env.STRADDLE_API_KEY) missing.push("STRADDLE_API_KEY");
  if (!env.STRADDLE_ENVIRONMENT) missing.push("STRADDLE_ENVIRONMENT");
  if (missing.length) throw new StraddleConfigError(`Straddle is not configured: missing ${missing.join(", ")}`);
  const baseURL = BASE_URLS[env.STRADDLE_ENVIRONMENT];
  if (!baseURL) throw new StraddleConfigError(`STRADDLE_ENVIRONMENT must be sandbox or production`);
  return { apiKey: env.STRADDLE_API_KEY, environment: env.STRADDLE_ENVIRONMENT, baseURL };
}
EOF_4
cat > src/straddle.mjs <<'EOF_5'
import StraddleAPI from "@straddlecom/straddle";
import { loadStraddleConfig } from "./config.mjs";

export class MissingSellerAccountError extends Error {}

export function createStraddleClient({ env, fetch } = {}) {
  const config = loadStraddleConfig(env);
  return new StraddleAPI({ bearer: config.apiKey, baseURL: config.baseURL, fetch, maxRetries: 0 });
}

// Marketplace: the platform owns buyers, so customer calls omit Straddle-Account-Id.
export function createBuyer(client, { externalId, name, email, phone, ipAddress }) {
  return client.customers.create({
    "Idempotency-Key": `cust-${externalId}`.slice(0, 40),
    name, email, phone, type: "individual",
    device: { ip_address: ipAddress },
    external_id: externalId,
  });
}

// Marketplace seller-attributed charge: the seller account is required.
export function chargeForSeller(client, { sellerAccountId, paykey, amount, externalId, paymentDate, ipAddress }) {
  if (!sellerAccountId) throw new MissingSellerAccountError("seller account is required for a marketplace charge");
  return client.charges.create({
    "Straddle-Account-Id": sellerAccountId,
    "Idempotency-Key": `chg-${externalId}`.slice(0, 40),
    paykey, amount, currency: "USD", consent_type: "internet",
    description: `order ${externalId}`, payment_date: paymentDate,
    external_id: externalId,
    device: { ip_address: ipAddress },
    config: { balance_check: "enabled" },
  });
}
EOF_5
cat > src/webhooks.mjs <<'EOF_6'
// Verify from the raw body, persist, then acknowledge. Duplicate deliveries are no-ops.
export async function handleStraddleDelivery(client, { rawBody, headers, secret, store }) {
  if (!secret) throw new Error("STRADDLE_WEBHOOK_SECRET is not configured");
  if (!headers) return { status: 400 };
  let event;
  try {
    event = client.webhooks.unwrap(rawBody, { headers, key: secret });
  } catch {
    return { status: 400 };
  }
  const id = headers["webhook-id"];
  try {
    if (!(await store.has(id))) await store.put(id, event);
  } catch {
    return { status: 500 };
  }
  return { status: 204 };
}
EOF_6
npm install --ignore-scripts --no-audit --no-fund --silent @straddlecom/straddle@1.0.4 standardwebhooks@1.0.0
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -q -m scaffold
