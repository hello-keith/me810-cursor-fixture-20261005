---
type: llm
---

PASS if the reply says the Straddle environment has not been selected, names `STRADDLE_ENVIRONMENT` (Sandbox) as the missing setting, treats the saved CLI key as present, and asks the developer to set or confirm Sandbox or to run straddle-setup.
FAIL if the reply treats the CLI's default Sandbox URL as a selected environment, says the key is missing, asks for the key's value, offers Production as a choice, inventories the provider code, writes or drafts `straddle-migration-plan.md` or any other file, or starts planning instead of stopping at the missing setting, or runs or offers to run any Straddle request, including `straddle doctor` or an accounts read.
