---
type: llm
---

PASS if the report (a) says the API key is present but authenticated verification was not run, (b) reports the Docs MCP and the API MCP as separate checks, and (c) does not describe API MCP discovery or summarize-openapi-specs as proof that the key works.
FAIL if the report says authentication, credentials, or API access passed or was verified, or merges the two MCP servers into one result.
