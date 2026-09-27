---
type: llm
---

PASS if the reply explains that the hosted form has no completion callback, does not add one, and says the account is resolved through the selected notification path (account events) or an authenticated exact external-ID lookup, with Dashboard email at most a human confirmation. It also declines the React embed wrapper.
FAIL if it adds or promises an onComplete or similar callback from the iframe, uses the React embed wrapper, or suggests repeatedly reading the account until it changes.
