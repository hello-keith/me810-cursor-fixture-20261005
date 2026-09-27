# Step 1: Begin

- **Needs:** the developer's request.
- **Tools:** Read. No shell commands, no writes.
- **Next:** [02-inventory.md](02-inventory.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-migrate","step":"01-begin"}
```

Read [straddle-best-practices](../../straddle-best-practices/SKILL.md) and keep its rules in force.

Restate the scope to the developer in two or three sentences: new Straddle code beside the existing provider, a written plan they approve before any edit, no deleted code, and no customer data moved.

If the request itself asks to move data (for example "import our Dwolla customers into Straddle", "copy the Plaid access tokens over", "backfill payment history"), decline that part now, explain that customer-data transfer is outside this skill, and offer the code migration instead. Continue only with the code migration, and record the declined part for the report.

If `straddle-migration-plan.md` exists, read it. An approval recorded there is valid only if the plan has not changed since; treat any edit to the plan after approval as unapproved.

**Summary for step 2:** requested provider, declined requests, existing plan and approval state.
