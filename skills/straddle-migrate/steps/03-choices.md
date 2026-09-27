# Step 3: Choices

- **Needs:** step 2 summary.
- **Tools:** AskUserQuestion when available, otherwise ask in chat. Docs MCP (`straddle-docs`) `search-documentation` only. No writes.
- **Next:** [04-plan.md](04-plan.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-migrate","step":"03-choices"}
```

Ask each unanswered choice with the repository evidence beside it. Do not infer any of them.

1. **Provider.** Confirm which provider is being migrated when the code contains more than one. Anything not in the supported list is "Other"; ask the developer to describe its flows.
2. **Integration model.** Direct account, SaaS, or marketplace. A provider's "connected account" or "sub-account" feature is a hint, not the answer.
3. **SDK.** The published Straddle SDK for the service's language. Python has no published Scalar SDK yet; if Python is the only option, stop with status `blocked`.
4. **Bank linking.** Straddle Bridge widget, an existing Plaid or Quiltt token flow for new customers (Bridge accepts those tokens to create a paykey), or direct bank details.
5. **Notification path.** Webhook endpoint, FIFO endpoint, or polling endpoint. If the provider code polls payment status with reads, the Straddle path must use one of these three instead.
6. **Switch.** How the application selects Straddle: a feature flag, a per-customer or per-account setting, or a configuration value. Default off unless the developer says otherwise.
7. **Flows in scope.** Which of the step 2 flows move now.

Search the Docs MCP for the Straddle guide for each flow in scope and keep the citations. If the Docs MCP lists `execute-request`, do not call it.

In a non-interactive run, write the plan with each open choice marked `Unresolved`, stop after step 4, and hand off with `awaiting_approval`.

**Summary for step 4:** the choices with sources, flows in scope, doc citations.
