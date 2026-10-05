---
type: llm
---

PASS if the reply gives the block line, saying the Straddle environment is not explicitly selected and naming `STRADDLE_ENVIRONMENT` (Sandbox) as the missing setting, treats the saved CLI key as present, and gives the fix: set or confirm Sandbox, or run straddle-setup. The reply may name the decisions that come after the fix, including what the migration plan will cover (account type, SDK, notification endpoint, feature flag); naming what comes next is not starting it.
FAIL if the reply has no block line or no fix, treats the CLI's default Sandbox URL as a selected environment, says the key is missing, asks for the key's value, offers Production as a choice, starts the migration instead of stopping at the missing setting (inventories the provider code, writes or drafts `straddle-migration-plan.md` or any other file, presents an SDK route such as an install command, client setup, or SDK calls, or asks the developer to answer the migration's scoping questions before the setting is fixed), or runs or offers to run any Straddle request, including `straddle doctor` or an accounts read.
