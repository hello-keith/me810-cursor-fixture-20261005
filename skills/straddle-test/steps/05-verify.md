# Step 5: Independent verification

- **Needs:** summaries from steps 1 to 4.
- **Tools:** `straddle-api` `summarize-openapi-specs` and `search-openapi-operations`; `straddle-api` `execute-request` for permitted reads only, and only when step 1 recorded the API MCP route **configured**; Bash only for `straddle <resource> get ... --agent --data-source live` when the CLI route is **configured**.
- **Next:** [06-evidence.md](06-evidence.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-test","step":"05-verify"}
```

Record three results separately. None of them implies another.

1. **Discovery.** Call `summarize-openapi-specs` once. It reads the API description and sends no Straddle request, so it proves the API MCP is registered, not that any key works.
2. **Authenticated execution.** Only for a configured route: run one permitted read per created resource through `execute-request`, for example `GET /v1/accounts/{account_id}` or `GET /v1/charges/{id}` once, passing the acting account where the read takes one. Record each status code. A `401` is an authentication failure. Report it without guessing whether the key or the client's MCP secret input is wrong. When not configured, record `not run: configuration error`.
3. **Exclusion routing.** Record the tool that executed each of the fourteen excluded operations this run used. Every one must be the SDK or CLI. This is evidence about the skill's routing, not about Scalar: Scalar does not enforce the exclusions, so never write that it does.

Never call `execute-request` for any of the fourteen excluded operations, or for anything outside the public contract.

**Summary for step 6:** discovery result, authenticated results per read, and the routing table.
