# Step 3: Sandbox preview and approval

- **Needs:** summaries from steps 1 and 2.
- **Tools:** Read; AskUserQuestion; Bash only for `straddle ... --dry-run --agent` and `--help`, and only when step 1 recorded **configured**. No live request.
- **Next:** [04-sandbox.md](04-sandbox.md) after an explicit yes. Otherwise [06-evidence.md](06-evidence.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-test","step":"03-preview"}
```

When no selected scenario needs a Sandbox write, go to step 5.

Build and ask for approval exactly as in Integrate's [preview step](../../straddle-integrate/steps/04-preview.md). The same table, executing tools, idempotency keys, account rules, configuration handling, and approval rules apply. For Test, the rows are:

- reuse of accounts A and B, and of the customers and paykeys from Integrate, by exact external ID. Create only what is missing.
- one charge per selected outcome, each with a fresh external ID namespaced by run, for example `acme-test-<run>-paid-a` for account A and `acme-test-<run>-r01-b` for account B. Use `amount: 10000`, `currency: USD`, `consent_type: internet`, `config.balance_check: enabled`, an eligible payment date, and the scenario's `config.sandbox_outcome`.
- the retry row, which repeats one create with the identical idempotency key and external ID
- the header-omitted operations the A/B scenario exercises

Name the notification path each status will arrive through, and the wait limit of ten minutes.

When the configuration is missing, the developer says no, or there is no answer, send nothing. Record the Sandbox scenarios as `not run` with the reason, print `STRADDLE_ABORT` when stopping for configuration or denial, and go to step 6.

**Summary for step 4:** the approved rows exactly as shown, or why Sandbox scenarios will not run.
