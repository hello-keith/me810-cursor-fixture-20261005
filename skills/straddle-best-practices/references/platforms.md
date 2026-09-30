# Platforms: accounts, onboarding, and capabilities

Every status, field, and operation in backticks is checked against API contract 1.0.4 by `scripts/check-contract-tokens`. Facts marked "Observed in Sandbox" come from Sandbox runs, not from the contract or the docs. For details beyond this page, search the Docs MCP by concept, for example "embedded accounts", "onboarding", "capabilities", or "linked bank accounts".

## What it is

A SaaS or marketplace platform runs payments for businesses through embedded accounts. A direct integration is one business with one account and none of this. Which account a request acts for, and when to send `Straddle-Account-Id`, is in [account-scope.md](account-scope.md). The objects:

- **Organization:** groups related accounts and users. Create it first.
- **Account:** one business (`type` `business`) in an organization (`organization_id`), with a `business_profile`, an `access_level` (`standard`, or `managed` when your platform runs it and its users can't use the Straddle dashboard), `capabilities`, `settings`, and your `external_id`.
- **Representative:** a person behind the business. `relationship` says whether they're the `primary` representative, have `control`, or are an `owner` (with `percent_ownership`).
- **Linked bank account:** the business's bank account for funding events, with `purposes` (`charges`, `payouts`, `billing`). Without `account_id`, it belongs to the platform.
- **Capability request:** asks Straddle to turn a capability on or off, or to change its limits.

## States and transitions

Accounts, representatives, and linked bank accounts share the statuses `created`, `onboarding`, `active`, `rejected`, and `inactive`. A linked bank account can also be `canceled`, spelled with one l, unlike a payment's `cancelled`. Each has a `status_detail` with `reason` (`new`, `unverified`, `pending`, `in_review`, `stuck`, `verified`, `failed_verification`, `disabled`, and for accounts `terminated`), `source` `watchtower`, `code`, and `message`.

Onboarding:

1. Create the account, at least one representative, and at least one linked bank account. All start `created`.
2. Record the business's acceptance of Straddle's terms, then call `onboardAccount` with `terms_of_service` (`accepted_date`, `agreement_type` `embedded` or `direct`, `agreement_url`, `accepted_ip`, `accepted_user_agent`). The account, its representatives, and its linked bank accounts move to `onboarding`.
3. Straddle verifies them. Each ends `active` or `rejected`. `stuck` in `status_detail.reason` means Straddle needs something fixed.

Before onboarding, `updateLinkedBankAccount` works on a `created` linked bank account, or an `onboarding` one whose `status_detail.reason` is `stuck`. `cancelLinkedBankAccount` works only while it's `created`.

The customer-facing alternative is Straddle's hosted onboarding form, which the business fills in itself. Keep it apart from API onboarding, as [Platform onboarding](../../straddle-integrate/references/onboarding.md) describes.

Capabilities say what an `active` account can do. Each `capability_status` is `active` or `inactive`:

| Group | Capabilities |
| --- | --- |
| `payment_types` | `charges`, `payouts` |
| `customer_types` | `individuals`, `businesses` |
| `consent_types` | `internet`, `signed_agreement` |

`createCapabilityRequest` asks for changes: `charges` or `payouts` with `enable`, `max_amount`, `daily_amount`, `monthly_amount`, and `monthly_count`, or `internet`, `signed_agreement`, `individuals`, or `businesses` with `enable`. Each request has a `category` (`payment_type`, `customer_type`, or `consent_type`), a `type`, and a `status`: `reviewing`, `in_review`, `approved`, `rejected`, `active`, or `inactive`. `getAccountSettings` returns the settings in effect, including the limits and `funding_time` ([errors-and-limits.md](errors-and-limits.md)).

## What your app must handle

- Store each business's account `id` and `external_id`, and act for exactly one account per request, as [account-scope.md](account-scope.md) requires.
- Collect the business profile, representatives, and bank account step by step, then onboard once all three exist. Keep the terms acceptance record (time, IP address, user agent) so you can reproduce it.
- Show onboarding progress from events, including `stuck` and `rejected` with what the business must fix.
- Allow payments only for an `active` account whose needed capability is `active`, and check the consent type your charges use is enabled.
- Route every event by its `account_id`, and reject events for accounts you don't own ([Routing events on a platform](receiving-webhooks.md#routing-events-on-a-platform)).

## Events and Sandbox outcomes

- `account.created.v1` and `account.event.v1`: status, settings, limits, and capability changes.
- `representative.created.v1`, `representative.event.v1`, `linked_bank_account.created.v1`, `linked_bank_account.event.v1`, `capability_request.created.v1`, and `capability_request.event.v1` for the related objects ([webhooks.md](webhooks.md)).
- Sandbox: `simulateAccountOnboarding` with `final_status` `onboarding` or `active` moves a Sandbox account through onboarding without review. See [sandbox-outcomes.md](sandbox-outcomes.md#funding-and-account-simulations).
