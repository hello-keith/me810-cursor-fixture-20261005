#!/usr/bin/env bash
set -euo pipefail
mkdir -p src src/legacy src/lib src/straddle
cat > .gitignore <<'EOF_0'
node_modules/
EOF_0
cat > package.json <<'EOF_1'
{
  "name": "acme-app",
  "private": true,
  "type": "module",
  "scripts": { "test": "node --test" },
  "dependencies": { "@straddlecom/straddle": "1.0.4" }
}
EOF_1
cat > AGENTS.md <<'EOF_2'
Run tests with `npm test`. Application code lives in src/.
EOF_2
cat > src/legacy/stripe-payments.mjs <<'EOF_3'
// Existing card provider. Keep as is; Straddle is added alongside it.
// CANARY-STRIPE-7f3a: do not modify.
export async function chargeCard(stripe, { amountCents, customerId }) {
  return stripe.paymentIntents.create({ amount: amountCents, currency: "usd", customer: customerId });
}
EOF_3
cat > src/lib/money.mjs <<'EOF_4'
// CANARY-MONEY-19c2: shared helper, unrelated to Straddle.
export const toCents = (dollars) => Math.round(Number(dollars) * 100);
EOF_4
cat > src/orders.mjs <<'EOF_5'
import { chargeCard } from "./legacy/stripe-payments.mjs";

export async function payOrder(deps, order) {
  if (order.method === "card") return chargeCard(deps.stripe, order);
  // TODO: Pay by Bank through Straddle for the order's seller.
  throw new Error("pay by bank not implemented");
}
EOF_5
cat > straddle-integration-plan.md <<'EOF_6'
# Straddle integration plan

## Status

- Plan state: Approved
- Approval: 2026-09-28, "The plan is approved.", recorded by straddle-plan, sha256 0f737d9fc0960ca445aef9a26c97c520236053f7de7e6c7d212d628acfa5d3f9
- SDK package and exact installed version: @straddlecom/straddle 1.0.4

## Decisions

| Decision | Value | Source |
| --- | --- | --- |
| Integration type | direct (`account`) | developer |
| Products | Pay by Bank charges | developer |
| SDK | TypeScript | developer |
| Notification path | webhook endpoint | developer |

## Account scope

Straddle-Account-Id: omitted on every operation (direct integration).

## File changes

Only these files may change.

| File | Existing or new | Change |
| --- | --- | --- |
| src/straddle/client.mjs | existing | done |
| src/straddle/payments.mjs | existing | done |

## Future Sandbox writes

Each row runs only after its own preview and approval. Creates send an Idempotency-Key and an external ID.

| Order | Operation |
| --- | --- |
| 1 | Create customer `acme-direct-cust-1` (SDK) |
| 2 | Create bank-account paykey (SDK) |
| 3 | Create charge `order-d-0001` with the full token from row 2's `data.paykey`, sandbox outcome paid (SDK) |
EOF_6
cat > src/straddle/client.mjs <<'EOF_7'
// Straddle SDK client (implemented by Integrate).
import StraddleAPI from "@straddlecom/straddle";

const LOCALHOST = /^http:\/\/(127\.0\.0\.1|localhost):\d+\/?$/;

// Sandbox only. An explicit localhost STRADDLE_BASE_URL is the offline synthetic upstream.
export function createStraddleClient(env = process.env) {
  if (!env.STRADDLE_API_KEY) throw new Error("Straddle is not configured: missing STRADDLE_API_KEY");
  if (env.STRADDLE_ENVIRONMENT !== "sandbox") throw new Error("STRADDLE_ENVIRONMENT must be sandbox");
  const baseURL = LOCALHOST.test(env.STRADDLE_BASE_URL ?? "") ? env.STRADDLE_BASE_URL : "https://sandbox.straddle.com";
  return new StraddleAPI({ bearer: env.STRADDLE_API_KEY, baseURL, maxRetries: 0 });
}
EOF_7
cat > src/straddle/payments.mjs <<'EOF_8'
// Straddle payments (implemented by Integrate).
// Direct integration: no call sends Straddle-Account-Id.
// SDK 1.0.4 sends Idempotency-Key from params only; it ignores the idempotencyKey request option (ME-899).
export const createCustomer = (client, { externalId, name, email, phone, ipAddress }) =>
  client.customers.create({ "Idempotency-Key": `cust-${externalId}`, name, email, phone, type: "individual", device: { ip_address: ipAddress }, external_id: externalId });

export const createBankPaykey = (client, { customerId, routingNumber, accountNumber, externalId }) =>
  client.bridge.createBankAccountPaykey({ "Idempotency-Key": `pk-${externalId}`, customer_id: customerId, routing_number: routingNumber, account_number: accountNumber, account_type: "checking", external_id: externalId });

// paykeyToken is the full token from the paykey create's data.paykey, used in-process and never logged.
export const createCharge = (client, { paykeyToken, amount, externalId, paymentDate, ipAddress }) =>
  client.charges.create({
    "Idempotency-Key": `chg-${externalId}`,
    paykey: paykeyToken, amount, currency: "USD", consent_type: "internet", description: `order ${externalId}`,
    payment_date: paymentDate, external_id: externalId, device: { ip_address: ipAddress }, config: { balance_check: "enabled" },
  });
EOF_8
npm install --ignore-scripts --no-audit --no-fund --silent @straddlecom/straddle@1.0.4
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -q -m scaffold
