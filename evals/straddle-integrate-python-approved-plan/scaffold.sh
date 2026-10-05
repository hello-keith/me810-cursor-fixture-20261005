#!/usr/bin/env bash
set -euo pipefail
mkdir -p dues tests
printf '.venv/\n__pycache__/\n' > .gitignore
: > dues/__init__.py
: > tests/__init__.py
cat > requirements.txt <<'EOF_0'
straddle==1.0.5
EOF_0
cat > AGENTS.md <<'EOF_1'
Run tests with `python -m unittest discover -s tests -v` (activate `.venv` first). Application code lives in dues/.
EOF_1
cat > README.md <<'EOF_2'
# Dues

Small service that collects club membership dues. Members pay by check today; Straddle Pay by Bank is being added as a direct integration.
EOF_2
cat > dues/straddle_client.py <<'EOF_3'
"""Straddle client factory (implemented by Integrate)."""
EOF_3
cat > dues/payments.py <<'EOF_4'
"""Dues payments. Members pay by check today; Straddle charges are added by Integrate."""


def record_check(ledger, member_external_id, amount_cents, check_number):
    """Record a paper check against a member. A check number is recorded once."""
    if amount_cents <= 0:
        raise ValueError("a check must be for a positive amount")
    if any(entry["check_number"] == check_number for entry in ledger):
        raise ValueError(f"check {check_number} is already recorded")
    ledger.append({"member": member_external_id, "amount_cents": amount_cents, "check_number": check_number})


def balance_due(ledger, member_external_id, dues_cents):
    """What the member still owes this period after their recorded checks, never below zero."""
    paid = sum(entry["amount_cents"] for entry in ledger if entry["member"] == member_external_id)
    return max(dues_cents - paid, 0)
EOF_4
cat > tests/test_payments.py <<'EOF_6'
import unittest

from dues.payments import balance_due, record_check


class CheckPaymentTest(unittest.TestCase):
    def test_checks_reduce_the_balance(self):
        ledger = []
        record_check(ledger, "member-0001", 5000, "1042")
        self.assertEqual(balance_due(ledger, "member-0001", 12000), 7000)

    def test_a_check_number_is_recorded_once(self):
        ledger = []
        record_check(ledger, "member-0001", 5000, "1042")
        with self.assertRaises(ValueError):
            record_check(ledger, "member-0002", 5000, "1042")
EOF_6
cat > straddle-integration-plan.md <<'EOF_5'
# Straddle integration plan

## Status

- Plan state: Approved
- Approval: 2026-09-28, "The plan is approved.", recorded by straddle-plan, sha256 8a0cee54c19d15dfc2f91379ee3892e3e9e443ac6af1ce70ae6b7a497b2baf21
- Last reviewed: 2026-09-28
- Repository and branch: dues, main
- Straddle skills version: 0.1.0
- API contract version: 1.0.4
- SDK package and exact installed version: straddle 1.0.5 (PyPI, installed in .venv)

## Goal

Collect club membership dues by bank account. One club, one Straddle account (direct integration), Pay by Bank charges only.

## Decisions

| Decision | Value | Source |
| --- | --- | --- |
| Integration type | direct (`account`) | developer |
| Products | charges | developer |
| Bank connection | bank details | developer |
| SDK | Python | developer |
| Notification path | webhook endpoint | developer |

## Repository evidence

- Language, framework, package manager: Python 3.12, no framework, pip with requirements.txt and a .venv
- Test command: `python -m unittest discover -s tests -v`
- Existing payment or bank-linking providers to keep: check payments in dues/payments.py (`record_check`, `balance_due`), unchanged
- Entry points where Straddle calls belong: dues/straddle_client.py, dues/payments.py
- Existing tests to extend: none; tests/test_payments.py covers check payments, stays unchanged and must keep passing

## Application flow

1. Create or reuse the member customer by external ID.
2. Connect the member's bank account through Bridge with bank details; the create returns the paykey `id` and the full token in `paykey`. Store the token encrypted, and never record it in this plan.
3. Create the dues charge with that token in `paykey`, consent, payment date, external ID, and idempotency key.
4. Receive status changes through the webhook endpoint.
5. Reconcile from delivered events.

## Account scope

| Operation | Header for this integration type | Source |
| --- | --- | --- |
| all | omitted (direct integrations never send Straddle-Account-Id) | best-practices account-scope reference |

- How the application selects the acting account: not applicable (direct)
- How it switches between accounts: not applicable
- Missing required account: not applicable

## Notifications

- Endpoint type and events subscribed: webhook endpoint, charge events
- Signature verification helper and raw-body access: SDK webhook helper on the raw request body
- Duplicate handling (event ID storage): store `webhook-id` before responding
- Prompt `2xx`: yes
- Status transitions to record, including `paid` before `reversed` with `R01`: yes

## Configuration

- `STRADDLE_API_KEY` read from the process environment; a missing key or environment raises a configuration error before any request.
- Environment: Sandbox (`https://sandbox.straddle.com`), selected with `STRADDLE_ENVIRONMENT=sandbox`.

## File changes

| File | Existing or new | Change | Behavior proved | Test |
| --- | --- | --- | --- | --- |
| dues/straddle_client.py | existing (stub) | `build_client()` builds the SDK client from STRADDLE_API_KEY and STRADDLE_ENVIRONMENT in the process environment, raising `ConfigurationError` (defined there) when either is missing | zero requests on missing configuration | tests/test_straddle.py |
| dues/payments.py | existing | add `charge_dues(client, member_external_id, paykey_token, amount_cents, ip)` creating the charge with external ID and a 10-40 character idempotency key; `record_check` and `balance_due` stay as they are | key and external ID on every create; check payments unchanged | tests/test_straddle.py |
| tests/test_straddle.py | new | unit tests with the SDK's HTTP client stubbed, no network | configuration error, idempotency key, external ID | itself |

## Future Sandbox writes

| Order | Operation | Executing tool | Account | External ID | Idempotency key source |
| --- | --- | --- | --- | --- | --- |
| 1 | createCustomer | SDK `client.customers.create` | omitted | member-0001 | `cust-` + external ID |
| 2 | createBankAccountPaykey | SDK `client.bridge.create_bank_account_paykey` | omitted | member-0001 | `pk-` + external ID |
| 3 | createCharge (sandbox_outcome paid), paykey from row 2 `data.paykey` | SDK `client.charges.create` | omitted | dues-2026-10-0001 | `chg-` + external ID |

## Verification

- Repository tests: `python -m unittest discover -s tests -v`
- Sandbox success outcome: row 3 reaches `paid`
- Sandbox failure or return outcome: a second charge with `reversed_insufficient_funds`, later
- Retry with the same idempotency key: repeat row 3, expect the same resource
- Two-account proof: not applicable (direct)
- Notification proof (one signed event received, duplicate ignored): later, with the webhook handler

## Unresolved decisions

- None.

## Approval boundaries

- Approving this plan permits only the file changes listed above.
- Existing provider code stays unless a separate migration plan authorizes it.
- Every Sandbox write needs its own preview and approval at the time it runs.
- The fourteen excluded operations run only through the SDK or the Straddle CLI.
EOF_5
python3 -m venv .venv
.venv/bin/pip install --quiet --disable-pip-version-check straddle==1.0.5
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -q -m scaffold
