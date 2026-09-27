# Routing

Map the developer's answers to what to use next. Versions change; confirm the installed or latest published package before naming a method.

## SDK by language

| Language in the repository | SDK | Install |
| --- | --- | --- |
| TypeScript or JavaScript | `@straddlecom/straddle` | `npm install @straddlecom/straddle` |
| Go | `github.com/straddle-build/straddle-go` | `go get github.com/straddle-build/straddle-go` |
| Ruby | `straddle` gem | `bundle add straddle` |
| C# / .NET | `Straddle` | `dotnet add package Straddle` |
| Python | None published yet | Blocked. PyPI `straddle` is the retired 0.5.x package. |

A repository with several languages gets the SDK for the service that will call Straddle, which the developer names. Browser code never holds the API key; it talks to the developer's server.

## Account scope by integration model

| Model | One-line rule |
| --- | --- |
| Direct account | Never send `Straddle-Account-Id`. The key identifies the account. |
| SaaS | Customers, paykeys, charges, and payouts act for an explicitly selected embedded account. |
| Marketplace | Customers, paykeys, and Bridge belong to the platform and omit the header; charges and payouts name the seller's embedded account. |

Organization and account-management operations omit the header for every model. The full table is in [straddle-best-practices account scope](../../straddle-best-practices/references/account-scope.md).

## Documentation topics to search

| Choice | Docs MCP query |
| --- | --- |
| Pay by Bank | "Pay by Bank", "Bridge", "paykeys", "charges" |
| Payouts | "payouts" |
| Platform onboarding | "embedded accounts", "hosted onboarding", "organizations" |
| SaaS or marketplace | "platforms", "Straddle-Account-Id" |
| Notifications | "webhooks", "FIFO endpoint", "polling endpoint" |
| Sandbox testing | "sandbox", "sandbox_outcome" |

## Next skill

| Situation | Next skill |
| --- | --- |
| No Straddle code, no provider to replace | [straddle-setup](../../straddle-setup/SKILL.md), then [straddle-plan](../../straddle-plan/SKILL.md) |
| Existing provider code (Stripe, Plaid, Moov, Modern Treasury, Dwolla, Paya, Payliance, or Other) to replace or run beside | [straddle-migrate](../../straddle-migrate/SKILL.md) |
| Straddle code already present and the developer reports a problem or wants a review | [straddle-audit](../../straddle-audit/SKILL.md) |
| Straddle integration tested in Sandbox and heading to production | [straddle-go-live](../../straddle-go-live/SKILL.md) |
| A choice is still open or the only language is Python | No skill yet. Answer the open choice first. |
