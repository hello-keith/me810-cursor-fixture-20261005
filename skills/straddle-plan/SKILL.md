---
name: straddle-plan
description: Write or refresh a source-backed straddle-integration-plan.md before any Straddle code change or sandbox resource creation. Use when a developer wants to plan, scope, or design a Straddle integration (Pay by Bank, charges, payouts, Bridge, paykeys, direct, SaaS, or marketplace platforms), asks which SDK, headers, notification path, or tests they need, or after straddle-setup reports ready. Plan asks for the integration type, SDK, and notification path instead of guessing, and only describes future writes.
metadata:
  version: 0.1.0
---

# Straddle Plan

Write or refresh `straddle-integration-plan.md` in the application repository. The plan names the files, SDK methods, account rules, notification path, tests, and every future Sandbox write before anyone changes code.

Read [straddle-best-practices](../straddle-best-practices/SKILL.md) first. Its rules on credentials, account scope, idempotency, the fourteen excluded operations, notifications, and tools apply to the plan and are cited there rather than copied.

## Boundaries

- The only file Plan writes is `straddle-integration-plan.md`. It does not edit application code, install packages, or change configuration.
- No remote writes. Plan never creates, deletes, unmasks, or reveals anything, and never runs a bootstrap. It may read the Docs MCP and the installed SDK source.
- Plan asks for decisions it cannot read from the repository. It does not pick the integration type, SDK, or notification path for the developer.
- Do not read `.env*`, credential stores, or private keys.

## Steps

1. [steps/01-decisions.md](steps/01-decisions.md): ask for integration type, products, SDK, notification path, and onboarding path.
2. [steps/02-sources.md](steps/02-sources.md): read the repository, the installed SDK source, and the current Straddle docs.
3. [steps/03-write-plan.md](steps/03-write-plan.md): write the plan from [references/plan-template.md](references/plan-template.md).
4. [steps/04-review.md](steps/04-review.md): check the plan file against the rules and fix it.
5. [steps/05-handoff.md](steps/05-handoff.md): summarize and print the final marker.

Each step file lists what it needs, its allowed tools, the next step, and its summary and marker.

## Markers

Print each marker on its own line, exactly as shown, with one-line JSON:

```text
STRADDLE_PROGRESS {"skill":"straddle-plan","step":"01-decisions"}
STRADDLE_ABORT {"skill":"straddle-plan","step":"01-decisions","reason":"developer did not choose an integration type"}
STRADDLE_HANDOFF {"skill":"straddle-plan","status":"draft","report":"<summary>"}
```

`status` is `draft` when the plan is complete and awaits the developer's approval, or `blocked` when unresolved decisions stop implementation.
