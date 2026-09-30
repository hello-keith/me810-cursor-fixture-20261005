---
name: straddle-audit
description: Review or troubleshoot an existing Straddle integration. Use when a developer asks to audit, review, check, or debug Straddle code, reports a failing Straddle request, 401/403/422 error, wrong account, missing or duplicate webhook, stuck charge status, or asks "is our Straddle integration right". Finds contract, account-scope, SDK, notification, and safety drift, triages every hypothesis against the installed SDK source and the API contract, and reports a findings table with file:line and confidence plus concrete recovery steps. Changes code only after the developer approves a specific finding.
metadata:
  version: 0.1.0
---

# Straddle Audit

Audit the Straddle integration in the repository in the current working directory, and help recover from a reported failure. Audit replaces the older Diagnose program.

Read [straddle-best-practices](../straddle-best-practices/SKILL.md) first. Its rules on credentials, environments, account scope, idempotency, the fourteen SDK/CLI-only operations, notifications, and missing configuration apply to every step and are the baseline the audit checks against.

Write developer-facing replies in the [Straddle voice](../straddle-best-practices/references/voice.md): lead with the result, keep it plain and friendly, and end with the next step. Put one plain sentence for the developer on the line after each marker. Approval questions, previews, and blocked or configuration-error messages keep their exact wording and values.

## Boundaries

- **Findings are hypotheses.** A pattern in the code is a hypothesis until you have checked it against the SDK version actually installed in the dependency tree and against the API contract. Downgrade or drop a hypothesis the installed source contradicts, and say so.
- **Report before changing.** The only file the audit writes by default is `straddle-audit-report.md`. Code changes happen in step 6, one approved finding at a time.
- **Sanitized context.** Collect error messages, status codes, `Request-Id` and `Correlation-Id` values, SDK and CLI versions, and the runtime environment. Strip keys, tokens, signing secrets, account and routing numbers, and customer PII before quoting anything. Never open `.env*`, private keys, credential stores, or CLI config files.
- **Configuration before requests.** A Straddle read is optional context, never required for a finding. Before one, confirm the key is present and the environment explicit; when either is missing, report a configuration error and send nothing. Reads use permitted operations only, never the fourteen SDK/CLI-only operations and never unmask or reveal.
- **No remote writes.** Recovery steps that need a remote write (resubmit, cancel, refund, create) are written out for the developer to run through the SDK or CLI with their own preview and approval. The audit does not run them.
- **Parallel work.** If the developer approves splitting fixes across subagents or worktrees, give each one the absolute repository path, and run `git status` in every worktree before any commit.

## Steps

1. [steps/01-begin.md](steps/01-begin.md): scope, reported symptom, working-tree baseline.
2. [steps/02-context.md](steps/02-context.md): sanitized runtime context and installed versions.
3. [steps/03-hypotheses.md](steps/03-hypotheses.md): scan with [references/checks.md](references/checks.md).
4. [steps/04-triage.md](steps/04-triage.md): confirm or drop each hypothesis against the installed SDK and the contract.
5. [steps/05-report.md](steps/05-report.md): findings table and recovery steps in `straddle-audit-report.md`.
6. [steps/06-recover.md](steps/06-recover.md): approved fixes only.

## Markers

Print each marker on its own line, exactly as shown, with one-line JSON. Open one step file at a time, in order, even when the request already answers the step's questions or the step needs no tools. Read the step file, then print its `STRADDLE_PROGRESS` marker immediately, before any other tool call, including reading a reference or the next step file. Do the step's work, and only then open the next step file. Do not read ahead, read several step files in one call or command, save markers up, or print them after the work or in the final report.

```text
STRADDLE_PROGRESS {"skill":"straddle-audit","step":"04-triage"}
STRADDLE_ABORT {"skill":"straddle-audit","step":"01-begin","reason":"no Straddle integration found"}
STRADDLE_HANDOFF {"skill":"straddle-audit","status":"findings","report":"straddle-audit-report.md: <one-paragraph summary>"}
```

`status` is `findings` when at least one confirmed finding remains, `clean` when none do, or `blocked` when the audit could not read the integration. Emit `STRADDLE_ABORT` when the repository has no Straddle code or the developer stops.
