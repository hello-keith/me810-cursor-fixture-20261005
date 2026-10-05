#!/usr/bin/env bash
set -euo pipefail
export GOTOOLCHAIN=local GOFLAGS=-mod=mod
mkdir -p dues
printf '.cache/\n' > .gitignore
cat > go.mod <<'EOF_0'
module example.com/dues

go 1.22
EOF_0
cat > AGENTS.md <<'EOF_1'
Run tests with `GOFLAGS=-mod=vendor GOPROXY=off GOCACHE="$PWD/.cache/go-build" go test ./...`. The Straddle Go SDK is vendored in vendor/. Application code lives in dues/.
EOF_1
cat > README.md <<'EOF_2'
# Dues

Small service that collects club membership dues. Members pay by check today; Straddle Pay by Bank is being added as a direct integration.
EOF_2
cat > dues/straddle_client.go <<'EOF_3'
// Straddle client factory (implemented by Integrate).
package dues
EOF_3
cat > dues/payments.go <<'EOF_4'
// Package dues collects club membership dues. Members pay by check today; Straddle charges are added by Integrate.
package dues

import "fmt"

// Check is one paper check recorded against a member.
type Check struct {
	Member      string
	AmountCents int64
	CheckNumber string
}

// RecordCheck records a paper check against a member. A check number is recorded once.
func RecordCheck(ledger []Check, memberExternalID string, amountCents int64, checkNumber string) ([]Check, error) {
	if amountCents <= 0 {
		return ledger, fmt.Errorf("a check must be for a positive amount")
	}
	for _, entry := range ledger {
		if entry.CheckNumber == checkNumber {
			return ledger, fmt.Errorf("check %s is already recorded", checkNumber)
		}
	}
	return append(ledger, Check{Member: memberExternalID, AmountCents: amountCents, CheckNumber: checkNumber}), nil
}

// BalanceDue is what the member still owes this period after their recorded checks, never below zero.
func BalanceDue(ledger []Check, memberExternalID string, duesCents int64) int64 {
	var paid int64
	for _, entry := range ledger {
		if entry.Member == memberExternalID {
			paid += entry.AmountCents
		}
	}
	return max(duesCents-paid, 0)
}
EOF_4
cat > dues/payments_test.go <<'EOF_6'
package dues

import "testing"

func TestChecksReduceTheBalance(t *testing.T) {
	ledger, err := RecordCheck(nil, "member-0001", 5000, "1042")
	if err != nil {
		t.Fatal(err)
	}
	if got := BalanceDue(ledger, "member-0001", 12000); got != 7000 {
		t.Fatalf("balance = %d, want 7000", got)
	}
}

func TestACheckNumberIsRecordedOnce(t *testing.T) {
	ledger, _ := RecordCheck(nil, "member-0001", 5000, "1042")
	if _, err := RecordCheck(ledger, "member-0002", 5000, "1042"); err == nil {
		t.Fatal("a repeated check number was accepted")
	}
}
EOF_6
cat > straddle-integration-plan.md <<'EOF_5'
# Straddle integration plan

## Status

- Plan state: Approved
- Approval: 2026-09-28, "The plan is approved.", recorded by straddle-plan, sha256 9e8a43167f71ce4dda97e5045c74baa34a4ce38782c923e33efb409943405277
- Last reviewed: 2026-09-28
- Repository and branch: dues, main
- Straddle skills version: 0.1.0
- API contract version: 1.0.4
- SDK package and exact installed version: github.com/straddle-build/straddle-go v1.0.4 (Go module, vendored in vendor/)

## Goal

Collect club membership dues by bank account. One club, one Straddle account (direct integration), Pay by Bank charges only.

## Decisions

| Decision | Value | Source |
| --- | --- | --- |
| Integration type | direct (`account`) | developer |
| Products | charges | developer |
| Bank connection | bank details | developer |
| SDK | Go | developer |
| Notification path | webhook endpoint | developer |

## Repository evidence

- Language, framework, package manager: Go 1.22 module `example.com/dues`, no framework, Go modules with the SDK vendored in vendor/
- Test command: `GOFLAGS=-mod=vendor GOPROXY=off GOCACHE="$PWD/.cache/go-build" go test ./...`
- Existing payment or bank-linking providers to keep: check payments in dues/payments.go (`RecordCheck`, `BalanceDue`), unchanged
- Entry points where Straddle calls belong: dues/straddle_client.go, dues/payments.go
- Existing tests to extend: none; dues/payments_test.go covers check payments, stays unchanged and must keep passing

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
- Signature verification helper and raw-body access: SDK `client.Webhooks.Parsed` on the raw request body and headers
- Duplicate handling (event ID storage): store `webhook-id` before responding
- Prompt `2xx`: yes
- Status transitions to record, including `paid` before `reversed` with `R01`: yes

## Configuration

- `STRADDLE_API_KEY` read from the process environment and passed with `option.WithBearer`; a missing key or environment returns a configuration error before any request.
- Environment: Sandbox (`https://sandbox.straddle.com/`), selected with `STRADDLE_ENVIRONMENT=sandbox` and passed with `option.WithBaseURL`.

## File changes

| File | Existing or new | Change | Behavior proved | Test |
| --- | --- | --- | --- | --- |
| dues/straddle_client.go | existing (stub) | `BuildClient(opts ...option.RequestOption) (*straddle.Client, error)` builds the SDK client from STRADDLE_API_KEY and STRADDLE_ENVIRONMENT in the process environment, applying `opts` after them so tests can pass `option.WithHTTPClient`, and returns a `*ConfigurationError` (defined there) when either is missing | zero requests on missing configuration | dues/straddle_test.go |
| dues/payments.go | existing | add `ChargeDues(ctx context.Context, client *straddle.Client, memberExternalID, paykeyToken string, amountCents int64, ip string) (*straddle.ChargeResponse, error)` creating the charge with external ID and a 10-40 character idempotency key; `RecordCheck` and `BalanceDue` stay as they are | key and external ID on every create; check payments unchanged | dues/straddle_test.go |
| dues/straddle_test.go | new | unit tests with the SDK's HTTP client stubbed through `option.WithHTTPClient`, no network | configuration error, idempotency key, external ID | itself |

## Future Sandbox writes

| Order | Operation | Executing tool | Account | External ID | Idempotency key source |
| --- | --- | --- | --- | --- | --- |
| 1 | createCustomer | SDK `client.Customers.New` | omitted | member-0001 | `cust-` + external ID |
| 2 | createBankAccountPaykey | SDK `client.Bridge.NewBankAccountPaykey` | omitted | member-0001 | `pk-` + external ID |
| 3 | createCharge (sandbox_outcome paid), paykey from row 2 `data.paykey` | SDK `client.Charges.New` | omitted | dues-2026-10-0001 | `chg-` + external ID |

## Verification

- Repository tests: `GOFLAGS=-mod=vendor GOPROXY=off GOCACHE="$PWD/.cache/go-build" go test ./...`
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
# The eval sandbox can't read the Go module cache, so the SDK is vendored into the repository. A blank import holds
# it in the module graph while it is vendored; the vendored packages stay after the import is removed.
printf 'package dues\n\nimport _ "github.com/straddle-build/straddle-go"\n' > dues/vendor_sdk.go
go get github.com/straddle-build/straddle-go@v1.0.4
go mod tidy
go mod vendor
rm dues/vendor_sdk.go
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -q -m scaffold
