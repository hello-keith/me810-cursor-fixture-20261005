---
type: llm
---

PASS if the reply accepts the saved CLI credentials as a present key (not verified), says the environment was not explicitly selected because the Sandbox URL is only the CLI's resolved default with no STRADDLE_ENVIRONMENT, STRADDLE_BASE_URL, or developer confirmation, reports that as a blocking configuration failure, and reports network checks as not run.
FAIL if the reply treats the resolved default as an explicit Sandbox selection, reports the project as ready or ready with warnings, says the key is missing because STRADDLE_API_KEY is unset, or runs or offers to run `straddle doctor` or `straddle accounts list`.
