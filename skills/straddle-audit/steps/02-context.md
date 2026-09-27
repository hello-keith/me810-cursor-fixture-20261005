# Step 2: Context

- **Needs:** step 1 summary.
- **Tools:** Read, Glob, Grep. Bash for `straddle --version`, `straddle doctor --agent`, and `straddle agent-context` after confirming the executable exists. Docs MCP `search-documentation`. API MCP `summarize-openapi-specs` and `search-openapi-operations`, which send no Straddle request. An API read only under the rule below. No writes.
- **Next:** [03-hypotheses.md](03-hypotheses.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-audit","step":"02-context"}
```

Gather, sanitized:

1. **Installed SDK.** Package name and resolved version from the lockfile, and the path to its installed source in the dependency tree (for example `node_modules/@straddlecom/straddle/`, the Go module cache path from `go env GOMODCACHE`, `bundle info straddle`, or the NuGet package folder). Step 4 reads this source. If the dependency tree is not installed, say so; triage will be limited to the lockfile and published docs and confidence drops accordingly.
2. **Contract.** The contract version the SDK was generated from (its manifest or README) and the operations involved in the symptom, from `search-openapi-operations` or the published API reference.
3. **Runtime.** Key presence (never the value), the environment the developer states, and the host the CLI resolves (`runtime_context.environment` defaults to Sandbox when nothing is configured, so it confirms the developer's statement rather than replacing it), plus integration type and acting account when reported.
4. **Request evidence.** Status code, error type, `Request-Id`, `Correlation-Id`, and the resource ID from the developer's logs. Remove secrets and PII before quoting.

**Optional read.** If a resource's current state would confirm a hypothesis (for example a charge's status and status history), and the key is present and the environment explicit, show the exact read, host, and account scope, and run it once after the developer says yes. Use a permitted GET through `execute-request` or the CLI with `--agent --data-source live`. Never an unmask or reveal operation. When the key or environment is missing, record `Configuration error: <what is missing>. No Straddle request was sent.` and continue without it.

**Summary for step 3:** installed SDK and its source path, contract version, runtime facts, sanitized request evidence.
