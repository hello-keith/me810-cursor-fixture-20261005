# Step 1: Begin

Print this marker once now, before any tool call, including reading straddle-best-practices or the next step file:

```text
STRADDLE_PROGRESS {"skill":"straddle-migrate","step":"01-begin"}
```

- **Needs:** the developer's request.
- **Tools:** Read. Bash only for the three configuration commands below, which send no Straddle request. No other shell commands, no writes.
- **Next:** [02-inventory.md](02-inventory.md), or the `blocked` handoff when the key or environment is missing.

Read [straddle-best-practices](../../straddle-best-practices/SKILL.md) and keep its rules in force.

## Key and environment, offline

Check both before anything else, under [environments-and-credentials.md](../../straddle-best-practices/references/environments-and-credentials.md). If the developer pasted this output in this run, use it instead of running the commands.

```bash
straddle auth status --agent
printenv STRADDLE_ENVIRONMENT
printenv STRADDLE_BASE_URL
```

- **API key:** present only when `auth status` reports `authenticated: true`. Report its presence and source category, never a value or the `config` path. `authenticated: false`, `no credentials configured`, or no `straddle` CLI means the key is missing or can't be confirmed.
- **Environment:** set only when `STRADDLE_ENVIRONMENT` is `sandbox` or `STRADDLE_BASE_URL` is `https://sandbox.straddle.com`, or when neither is set and the developer names Sandbox in this run. An unset variable prints nothing.

When either is missing, stop here, before scoping, planning, or any other tool call. Name exactly what is missing: the API key (`STRADDLE_API_KEY`, or a key saved with the CLI), the environment (`STRADDLE_ENVIRONMENT=sandbox`), or both. Ask the developer to set it in their own shell, never to paste a key into chat (confirming Sandbox in chat is enough for the environment), or to run [straddle-setup](../../straddle-setup/SKILL.md). Say that no Straddle request was sent, print the `blocked` handoff, and end the turn. When the developer says it is set, run this check again.

## Scope

Restate the scope to the developer in two or three sentences: new Straddle code beside the existing provider, a written plan they approve before any edit, no deleted code, and no customer data moved.

If the request itself asks to move data (for example "import our Dwolla customers into Straddle", "copy the Plaid access tokens over", "backfill payment history"), decline that part now, explain that customer-data transfer is outside this skill, and offer the code migration instead. Continue only with the code migration, and record the declined part for the report.

If `straddle-migration-plan.md` exists, read it. An approval recorded there is valid only if the plan has not changed since; treat any edit to the plan after approval as unapproved.

**Summary for step 2:** key and environment present, requested provider, declined requests, existing plan and approval state.
