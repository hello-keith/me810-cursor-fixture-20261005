---
name: straddle-integrate
description: Implement an approved straddle-integration-plan.md in the developer's repository with the installed Straddle SDK, then preview and run the approved Sandbox setup. Use when a developer wants to build, wire up, or finish a Straddle integration (Pay by Bank charges or payouts, customers, Bridge paykeys, marketplace or SaaS sellers, hosted onboarding, webhook, FIFO, or polling endpoint handling), asks to create Sandbox accounts, customers, paykeys, or charges for their app, or says the Straddle plan is approved. Changes only the files the plan approves and never writes to Straddle without an exact preview and explicit approval.
metadata:
  version: 0.1.0
---

# Straddle Integrate

Implement the approved `straddle-integration-plan.md`: change the approved files with the installed Straddle SDK, then set up the Sandbox resources the plan needs after the developer approves an exact preview.

Read [straddle-best-practices](../straddle-best-practices/SKILL.md) first. Its rules on credentials, environments, account scope, idempotency, the fourteen excluded operations, notifications, and tools apply to every step and are cited rather than repeated. [references/execution-routes.md](references/execution-routes.md) maps each write to its SDK method and CLI command.

## Boundaries

- **Approved files only.** Change only the files the plan's file-change table lists. Never delete, rename, reformat, or overwrite unrelated code, including existing payment providers. A file the plan does not list needs the developer's approval and a plan update first.
- **No remote write without an exact, current approval.** Every Sandbox write appears in a preview that names its environment, base URL, acting account, operation, executing tool, payload summary, external ID, and idempotency key. Only an explicit yes to that preview counts. A denial or a changed environment, account, operation, or payload means zero writes until a new preview is approved.
- **Missing configuration stops the run.** Without `STRADDLE_API_KEY` or an explicit Sandbox environment, Integrate makes no Straddle request of any kind and reports a configuration error. Code changes to approved files are not requests and may still be made.
- **The fourteen excluded operations run only through the SDK or CLI**, never the API MCP's `execute-request`. Other permitted API MCP operations stay available, mainly reads for independent verification.
- **Sandbox only.** Integrate never writes to Production.
- **No invented callbacks.** Hosted onboarding is completed by a person. Integrate resolves the account through the selected notification path or an authenticated exact external-ID lookup.

## Steps

1. [steps/01-begin.md](steps/01-begin.md): confirm the approved plan and check configuration without sending a request.
2. [steps/02-sources.md](steps/02-sources.md): read the installed SDK, the repository files the plan approves, and current docs.
3. [steps/03-code.md](steps/03-code.md): change the approved files.
4. [steps/04-preview.md](steps/04-preview.md): show the exact Sandbox write preview and ask for approval.
5. [steps/05-execute.md](steps/05-execute.md): run only the approved writes, chaining returned IDs.
6. [steps/06-review.md](steps/06-review.md): review the files and writes the earlier summaries touched.
7. [steps/07-handoff.md](steps/07-handoff.md): report code changes, server-side resources, and the final marker.

Each step file lists what it needs, its allowed tools, the next step, and its summary and marker. References: [execution-routes.md](references/execution-routes.md) and [onboarding.md](references/onboarding.md).

## Markers

Print each marker on its own line, exactly as shown, with one-line JSON:

```text
STRADDLE_PROGRESS {"skill":"straddle-integrate","step":"01-begin"}
STRADDLE_ABORT {"skill":"straddle-integrate","step":"05-execute","reason":"configuration error: STRADDLE_API_KEY is not set"}
STRADDLE_HANDOFF {"skill":"straddle-integrate","status":"awaiting_approval","report":"<summary>"}
```

`status` is one of:

- `complete`: approved code changes and every approved Sandbox write finished.
- `awaiting_approval`: code changes are done and the preview is waiting for the developer's yes.
- `blocked`: configuration, a missing plan decision, or a denied or stale approval stopped the run. The report says which.

Emit `STRADDLE_ABORT` when the run stops before its handoff step, such as a configuration error before a write or the developer ending the run, and still print the handoff with `blocked`.
