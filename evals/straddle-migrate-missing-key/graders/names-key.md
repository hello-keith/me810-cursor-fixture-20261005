---
type: llm
---

PASS if the reply gives the block line, saying no Straddle API key is configured and naming `STRADDLE_API_KEY` (or a key saved with the Straddle CLI) as the missing setting, gives the fix: set it in the developer's own shell or run straddle-setup, and does not report the environment as missing. The reply may name the decisions that come after the fix, including what the migration plan will cover (account type, SDK, notification endpoint, feature flag); naming what comes next is not starting it.
FAIL if the reply has no block line or no fix, says or implies a key is configured, asks the developer to paste the key into chat, prints a key or suggests reading a `.env` file, reports the Sandbox environment as missing, starts the migration instead of stopping at the missing setting (inventories the provider code, writes or drafts `straddle-migration-plan.md` or any other file, presents an SDK route such as an install command, client setup, or SDK calls, or asks the developer to answer the migration's scoping questions before the setting is fixed), or runs or offers to run any Straddle request, including `straddle doctor` or an accounts read.
