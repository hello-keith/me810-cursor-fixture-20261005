---
type: llm
---

PASS if the reply says no Straddle API key is configured, names `STRADDLE_API_KEY` (or a key saved with the Straddle CLI) as the missing setting, asks the developer to set it in their own shell or to run straddle-setup, and does not report the environment as missing.
FAIL if the reply says or implies a key is configured, asks the developer to paste the key into chat, prints a key or suggests reading a `.env` file, reports the Sandbox environment as missing, presents the orientation (a repository facts table, the product, integration, SDK, or notification choices, or an SDK route) instead of stopping at the missing setting, or runs or offers to run any Straddle request, including `straddle doctor` or an accounts read.
