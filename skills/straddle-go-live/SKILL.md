---
name: straddle-go-live
description: Production-readiness review for a Straddle integration that already works in Sandbox. Use when a developer asks whether they are ready to go live, launch, switch to production, flip the production key, or ship Straddle payments to real customers, or asks for a go-live or launch checklist. Checks configuration, code, Sandbox evidence, and dashboard setup with file:line evidence and returns ready or not_ready. It never creates, changes, or deletes production resources and never authorizes production writes.
metadata:
  version: 0.1.0
---

# Straddle Go Live

Decide whether the Straddle integration in the repository in the current working directory is ready for production, and show the evidence. The decision is the developer's; this skill supplies the checklist, the findings, and the gaps.

Read [straddle-best-practices](../straddle-best-practices/SKILL.md) first. Its rules on credentials, environments, account scope, idempotency, the fourteen SDK/CLI-only operations, notifications, and missing configuration apply to every step.

Write developer-facing replies in the [Straddle voice](../straddle-best-practices/references/voice.md); safety text and markers stay exact. In a [Straddle Wizard program](../straddle-best-practices/references/wizard-program.md) session, Go Live is its last step, and step 6 closes the program as that page says.

## Boundaries

- **No production writes.** Go Live never creates, updates, cancels, or deletes a production resource by any route: SDK, CLI, or MCP. It does not authorize the developer's agent or scripts to do so either. A request such as "send a $1 live charge to test it" is declined; the first live transaction is a human decision made outside this skill.
- **The API MCP is not read-only.** The hosted `straddle-api` server's `execute-request` can reach write operations, including in production when it holds a production key, and Scalar does not enforce its execution exclusions. The no-write rule here is this skill's workflow rule, not a server guarantee. Never describe the server as read-only.
- **Configuration first, offline.** Before anything that can reach Straddle, including `straddle doctor` (which sends a request to the API host before it checks credentials), confirm offline that a credential is present (`straddle auth status --json` or the developer) and that the developer has stated the environment. When either is missing, stop that check with a configuration error naming what is missing. Never report a check as passed that did not run.
- **Production reads only on request.** Go Live sends no production request by default. If the developer asks to confirm the production key works, show the exact read, the host it resolves to, and the account scope, and run it only after an explicit yes. Writes are never offered.
- **Local writes.** Only the report, `straddle-go-live-report.md` at the repository root, in step 6.

## Steps

1. [steps/01-begin.md](steps/01-begin.md): scope, stated facts, and prior evidence.
2. [steps/02-configuration.md](steps/02-configuration.md): key presence and explicit environment, before any request.
3. [steps/03-code.md](steps/03-code.md): code readiness against [references/readiness-checklist.md](references/readiness-checklist.md).
4. [steps/04-sandbox-evidence.md](steps/04-sandbox-evidence.md): Sandbox proof from straddle-test.
5. [steps/05-production-setup.md](steps/05-production-setup.md): dashboard and operational items a person confirms.
6. [steps/06-report.md](steps/06-report.md): decision, gaps, and handoff.

## Markers

Print each marker on its own line, exactly as shown, with one-line JSON. Open one step file at a time, in order, even when the request already answers the step's questions or the step needs no tools. Read the step file, then print its `STRADDLE_PROGRESS` marker immediately, before any other tool call, including reading a reference or the next step file. Do the step's work, and only then open the next step file. Do not read ahead, read several step files in one call or command, save markers up, or print them after the work or in the final report.

```text
STRADDLE_PROGRESS {"skill":"straddle-go-live","step":"03-code"}
STRADDLE_ABORT {"skill":"straddle-go-live","step":"02-configuration","reason":"developer stopped the review"}
STRADDLE_HANDOFF {"skill":"straddle-go-live","status":"not_ready","report":"<one-paragraph summary>"}
```

`status` is `ready` when every required check passed with evidence, `not_ready` when any required check failed or is unproven, or `blocked` when configuration is missing and the review cannot establish the environment. Emit `STRADDLE_ABORT` only when the developer stops the run.
