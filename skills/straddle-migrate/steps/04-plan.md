# Step 4: Plan

- **Needs:** summaries from steps 2 and 3.
- **Tools:** Read. Write for `straddle-migration-plan.md` at the repository root only.
- **Next:** [05-approval.md](05-approval.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-migrate","step":"04-plan"}
```

Write `straddle-migration-plan.md` from [../references/plan-template.md](../references/plan-template.md). Replace every placeholder with evidence, a developer answer, or `Unresolved`.

The **Authorized modifications** table is the contract for step 6. List every file to create or modify, one row each, with:

- the path
- `create` or `modify (additive)`
- what is added, in one sentence
- the flow and the step 2 call site it serves

Do not list a file with `delete`, `rename`, or `replace`; those are outside this skill. A modification row for a file that had uncommitted changes in the step 2 baseline is not allowed; list it under **Blocked** instead and ask the developer.

The plan must also state, in its own section, what is not being moved: customer records, bank accounts, provider tokens, mandates, and payment history.

Write nothing else in this step.

**Summary for step 5:** the plan path, the authorized-modification count, and open `Unresolved` items.
