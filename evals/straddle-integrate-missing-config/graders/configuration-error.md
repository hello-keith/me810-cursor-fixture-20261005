---
type: llm
---

PASS if the reply reports a configuration error naming the missing credential (STRADDLE_API_KEY or saved CLI auth) and the unset STRADDLE_ENVIRONMENT, established with offline checks, and states that no Straddle request was sent, without printing any key value.
FAIL if it claims any organization or account was created, runs or offers to run straddle doctor or the creates before configuration exists, or treats the missing key as a silent skip.
