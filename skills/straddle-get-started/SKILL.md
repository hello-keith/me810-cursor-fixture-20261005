---
name: straddle-get-started
description: First-contact orientation for adding Straddle to a repository. Use when a developer asks how to start with Straddle, which Straddle product, integration model (direct, SaaS, or marketplace), SDK, or docs fit their app, or says something like "add bank payments with Straddle" or "where do I begin", even before any Straddle code exists. Reads the repository, asks the product, integration, SDK, and notification choices instead of guessing them, and routes to the right docs and the next Straddle skill. Changes nothing.
metadata:
  version: 0.1.0
---

# Straddle Get Started

Orient a developer in the repository in the current working directory: what the code already shows, which choices only they can make, which published SDK and documentation match those choices, and which Straddle skill to run next.

Read [straddle-best-practices](../straddle-best-practices/SKILL.md) first. Its rules on credentials, environments, account scope, tools, notifications, and missing configuration apply to every step and are not repeated here.

## Boundaries

- Read-only. Get Started writes no file, installs nothing, changes no client or MCP configuration, and sends no Straddle API request. Docs MCP search needs no credential and is allowed.
- Repository facts come from files you read. Product, integration model, SDK, and notification path come from the developer. A framework or language narrows the SDK options; it never decides the product or integration model.
- If the developer asks for anything that needs an authenticated request (for example "which accounts do I have"), check offline first that a credential is present (`straddle auth status --json` or the developer) and that the developer has stated the environment; do not run `straddle doctor` for this, because it sends a request. When either is missing, stop that request with a configuration error and point to [straddle-setup](../straddle-setup/SKILL.md). Never answer with an empty or guessed result.
- SDK packages and versions come from the Current versions table in [straddle-best-practices](../straddle-best-practices/SKILL.md). Never recommend a retired SDK, such as Python `straddle` 0.x or `github.com/straddleio/straddle-go`.

## Steps

Run the steps in order. Each step file lists what it needs, the tools it may use, the summary it passes on, and its marker.

1. [steps/01-begin.md](steps/01-begin.md): record what the developer already decided.
2. [steps/02-repository.md](steps/02-repository.md): gather repository facts with file evidence.
3. [steps/03-choices.md](steps/03-choices.md): ask the choices the repository cannot answer.
4. [steps/04-route.md](steps/04-route.md): map the choices to SDK, documentation, and the next skill using [references/routing.md](references/routing.md).
5. [steps/05-report.md](steps/05-report.md): write the orientation report and the handoff marker.

## Markers

Print each marker on its own line exactly as shown, so the Straddle Wizard can parse it. The JSON stays on one line.

```text
STRADDLE_PROGRESS {"skill":"straddle-get-started","step":"02-repository"}
STRADDLE_ABORT {"skill":"straddle-get-started","step":"03-choices","reason":"developer stopped orientation"}
STRADDLE_HANDOFF {"skill":"straddle-get-started","status":"routed","report":"<one-paragraph summary>"}
```

`status` is `routed` when every choice is answered and a next skill is named, `needs_input` when a choice is still open, or `blocked` when a prerequisite stops routing (for example no published SDK exists for the service's language). Emit `STRADDLE_ABORT` only when the developer stops the run.
