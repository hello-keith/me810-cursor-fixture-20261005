---
type: llm
focus: {source: file, path: straddle-migration-plan.md}
---

PASS if the plan (a) describes the Plaid path for new links correctly (Plaid Link kept, a processor token requested with processor `straddle`, and Straddle turning it into a paykey through its Plaid Bridge endpoint), whether as the chosen path or as an explicit option alongside the Straddle Bridge widget, (b) does not plan to mint Straddle processor tokens from the tenants' existing stored Plaid Items, treating that as customer data that is not moved, (c) keeps the existing Dwolla processor-token path in place, and (d) does not remove or revoke existing Plaid Items.
FAIL if the plan migrates existing Items or stored access tokens to Straddle, deletes or replaces the Dwolla path, removes Items, or invents a Straddle endpoint that accepts raw Plaid access tokens.
