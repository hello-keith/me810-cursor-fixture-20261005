#!/usr/bin/env bash
set -euo pipefail
mkdir -p lib/dues test
printf 'vendor/gems/\n' > .gitignore
cat > AGENTS.md <<'EOF_1'
Run tests with `GEM_PATH=vendor/gems vendor/gems/bin/rake test`. Gems are installed in vendor/gems. Application code lives in lib/dues/.
EOF_1
cat > README.md <<'EOF_2'
# Dues

Small service that collects club membership dues. Members pay by check today; Straddle Pay by Bank is being added as a direct integration.
EOF_2
cat > Rakefile <<'EOF_7'
require "rake/testtask"

Rake::TestTask.new { |t| t.libs << "lib" }
task default: :test
EOF_7
cat > lib/dues/straddle_client.rb <<'EOF_3'
# Straddle client factory (implemented by Integrate).
EOF_3
cat > lib/dues/payments.rb <<'EOF_4'
# Dues payments. Members pay by check today; Straddle charges are added by Integrate.
module Dues
  module Payments
    module_function

    # Record a paper check against a member. A check number is recorded once.
    def record_check(ledger, member_external_id, amount_cents, check_number)
      raise ArgumentError, "a check must be for a positive amount" if amount_cents <= 0
      raise ArgumentError, "check #{check_number} is already recorded" if ledger.any? { |entry| entry[:check_number] == check_number }

      ledger << { member: member_external_id, amount_cents: amount_cents, check_number: check_number }
    end

    # What the member still owes this period after their recorded checks, never below zero.
    def balance_due(ledger, member_external_id, dues_cents)
      paid = ledger.select { |entry| entry[:member] == member_external_id }.sum { |entry| entry[:amount_cents] }
      [dues_cents - paid, 0].max
    end
  end
end
EOF_4
cat > test/test_payments.rb <<'EOF_6'
require "minitest/autorun"
require "dues/payments"

class CheckPaymentTest < Minitest::Test
  def test_checks_reduce_the_balance
    ledger = []
    Dues::Payments.record_check(ledger, "member-0001", 5000, "1042")
    assert_equal 7000, Dues::Payments.balance_due(ledger, "member-0001", 12000)
  end

  def test_a_check_number_is_recorded_once
    ledger = []
    Dues::Payments.record_check(ledger, "member-0001", 5000, "1042")
    assert_raises(ArgumentError) { Dues::Payments.record_check(ledger, "member-0002", 5000, "1042") }
  end
end
EOF_6
cat > straddle-integration-plan.md <<'EOF_5'
# Straddle integration plan

## Status

- Plan state: Approved
- Approval: 2026-09-28, "The plan is approved.", recorded by straddle-plan, sha256 f6d8c98c531d41bacfc4981191adecac630a973b4ff01b9ad534b7c7f4bd9df3
- Last reviewed: 2026-09-28
- Repository and branch: dues, main
- Straddle skills version: 0.1.0
- API contract version: 1.0.4
- SDK package and exact installed version: straddle 1.0.4 (RubyGems, installed in vendor/gems)

## Goal

Collect club membership dues by bank account. One club, one Straddle account (direct integration), Pay by Bank charges only.

## Decisions

| Decision | Value | Source |
| --- | --- | --- |
| Integration type | direct (`account`) | developer |
| Products | charges | developer |
| Bank connection | bank details | developer |
| SDK | Ruby | developer |
| Notification path | webhook endpoint | developer |

## Repository evidence

- Language, framework, package manager: Ruby 3.2, no framework, gems installed with `gem install --install-dir vendor/gems`
- Test command: `GEM_PATH=vendor/gems vendor/gems/bin/rake test`
- Existing payment or bank-linking providers to keep: check payments in lib/dues/payments.rb (`record_check`, `balance_due`), unchanged
- Entry points where Straddle calls belong: lib/dues/straddle_client.rb, lib/dues/payments.rb
- Existing tests to extend: none; test/test_payments.rb covers check payments, stays unchanged and must keep passing

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
| lib/dues/straddle_client.rb | existing (stub) | `Dues.build_client` builds the SDK client from STRADDLE_API_KEY and STRADDLE_ENVIRONMENT in the process environment, raising `Dues::ConfigurationError` (defined there) when either is missing | zero requests on missing configuration | test/test_straddle.rb |
| lib/dues/payments.rb | existing | add `Dues::Payments.charge_dues(client, member_external_id, paykey_token, amount_cents, ip)` creating the charge with external ID and a 10-40 character idempotency key; `record_check` and `balance_due` stay as they are | key and external ID on every create; check payments unchanged | test/test_straddle.rb |
| test/test_straddle.rb | new | minitest tests with the SDK's HTTP transport stubbed, no network | configuration error, idempotency key, external ID | itself |

## Future Sandbox writes

| Order | Operation | Executing tool | Account | External ID | Idempotency key source |
| --- | --- | --- | --- | --- | --- |
| 1 | createCustomer | SDK `client.customers.create` | omitted | member-0001 | `cust-` + external ID |
| 2 | createBankAccountPaykey | SDK `client.bridge.create_bank_account_paykey` | omitted | member-0001 | `pk-` + external ID |
| 3 | createCharge (sandbox_outcome paid), paykey from row 2 `data.paykey` | SDK `client.charges.create` | omitted | dues-2026-10-0001 | `chg-` + external ID |

## Verification

- Repository tests: `GEM_PATH=vendor/gems vendor/gems/bin/rake test`
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
gem install --quiet --no-document --install-dir vendor/gems straddle:1.0.4 minitest:5.16.3 rake:13.0.6
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -q -m scaffold
