---
type: llm
---

PASS if the report warns that the Docs MCP exposes API execution tools (such as execute-request) even though it should be search-only, and keeps the Docs MCP and API MCP as separate results.
FAIL if the report calls the Docs MCP search-only or healthy without that warning, or suggests using the Docs MCP to execute API requests.
