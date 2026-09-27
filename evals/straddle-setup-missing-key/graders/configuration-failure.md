---
type: llm
---

PASS if the reply says the project is not ready (blocked) because STRADDLE_API_KEY is missing, and treats that as a configuration failure rather than a warning.
FAIL if the reply reports the project as ready or ready with warnings, says the key or authentication was verified, offers to run an authenticated request while the key is missing, or suggests reading or editing a .env file.
