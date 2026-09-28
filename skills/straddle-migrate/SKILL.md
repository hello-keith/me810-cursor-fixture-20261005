---
name: straddle-migrate
description: Code-only, additive migration of an application from another payment or bank-data provider to Straddle. Use when a developer wants to replace, move off, or run Straddle beside Stripe, Plaid, Moov, Modern Treasury, Dwolla, Paya, Payliance, or any other ACH or bank-linking provider (including hand-rolled NACHA code), or asks to "switch to Straddle" or "port our payments". Writes straddle-migration-plan.md first, edits only the files the approved plan lists, keeps the old provider code, and never transfers customer data.
metadata:
  version: 0.1.0
---

# Straddle Migrate

Build Straddle code paths beside an existing provider integration in the repository in the current working directory. The result is new, reviewable code the developer can switch on. It is not a data migration and not a cutover.

Read [straddle-best-practices](../straddle-best-practices/SKILL.md) first. Its rules on credentials, environments, account scope, idempotency, the fourteen SDK/CLI-only operations, notifications, and missing configuration apply to every step and to every line of code this skill writes.

## Boundaries

- **Plan before edits.** Write `straddle-migration-plan.md` and get the developer's explicit approval of it before changing any other file. Every file the migration will create or modify is listed in the plan with the reason. Anything not listed is not touched.
- **Additive only.** Add new files and add code to listed files. Do not delete, rename, or rewrite existing provider code, tests, migrations, or configuration. Selecting Straddle happens through a switch the developer controls, and the old path keeps working.
- **No customer-data transfer.** Do not export, copy, transform, or re-create customers, bank accounts, provider tokens, mandates, or payment history in Straddle, and do not write scripts or run commands that do (including `straddle import`). Re-verifying existing customers is a separate, reviewed process outside this skill; say so when asked.
- **No unrelated changes.** Check the working tree before the first edit. If a file in the plan already has uncommitted changes, stop and ask; never overwrite, reformat, or stage someone else's work.
- **No remote writes.** Migrate sends no Straddle API request and creates no Straddle resource. Sandbox verification belongs to [straddle-test](../straddle-test/SKILL.md) after the code exists.
- **Config errors, not no-ops.** New Straddle code fails with a configuration error naming the missing key or environment before any request. It never silently falls back to the old provider or to Sandbox.

## Supported providers

Stripe, Plaid, Moov, Modern Treasury, Dwolla, Paya, Payliance, and Other. [references/providers.md](references/providers.md) gives the Straddle vocabulary and what every migration has in common, and links one file per provider. Each provider file covers how to find the provider in a repository, how its objects, statuses, returns, consent, idempotency, and notifications map to Straddle, what never moves, and the provider's common migration pitfalls. Read only the file for the provider being migrated.

## Steps

1. [steps/01-begin.md](steps/01-begin.md): confirm scope and restate the boundaries.
2. [steps/02-inventory.md](steps/02-inventory.md): find every provider call site and the working-tree state.
3. [steps/03-choices.md](steps/03-choices.md): ask provider, integration model, SDK, notification path, and switch design.
4. [steps/04-plan.md](steps/04-plan.md): write `straddle-migration-plan.md` from [references/plan-template.md](references/plan-template.md).
5. [steps/05-approval.md](steps/05-approval.md): get and record explicit approval.
6. [steps/06-edit.md](steps/06-edit.md): make only the approved, additive edits.
7. [steps/07-review.md](steps/07-review.md): prove the diff matches the plan.
8. [steps/08-report.md](steps/08-report.md): report and hand off.

## Markers

Print each marker on its own line, exactly as shown, with one-line JSON. Open one step file at a time, in order, even when the request already answers the step's questions or the step needs no tools. Read the step file, then print its `STRADDLE_PROGRESS` marker immediately, before any other tool call, including reading a reference or the next step file. Do the step's work, and only then open the next step file. Do not read ahead, read several step files in one call or command, save markers up, or print them after the work or in the final report.

```text
STRADDLE_PROGRESS {"skill":"straddle-migrate","step":"04-plan"}
STRADDLE_ABORT {"skill":"straddle-migrate","step":"05-approval","reason":"developer declined the plan"}
STRADDLE_HANDOFF {"skill":"straddle-migrate","status":"awaiting_approval","report":"<one-paragraph summary>"}
```

`status` is `awaiting_approval` when the plan is written but not approved, `migrated` when approved edits are done and reviewed, or `blocked` when a dirty file or a boundary stops the run. An open choice is not `blocked`: it goes into the plan as `Unresolved`, and the status is `awaiting_approval`. Emit `STRADDLE_ABORT` when the developer declines or stops.
