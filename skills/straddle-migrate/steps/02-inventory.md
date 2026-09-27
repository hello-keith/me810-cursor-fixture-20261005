# Step 2: Inventory

- **Needs:** step 1 summary.
- **Tools:** Read, Glob, Grep. Bash only for `git status --porcelain` and `git rev-parse --show-toplevel`. No writes. Never open `.env*`, private keys, credential stores, or CLI config files.
- **Next:** [03-choices.md](03-choices.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-migrate","step":"02-inventory"}
```

1. **Working tree.** Run `git status --porcelain` at the repository root and keep the output. It is the baseline for step 7. If the repository is not under git, say so; step 6 will then require the developer to confirm a backup before editing.
2. **Provider footprint.** Find every import, client construction, API call, webhook handler, and configuration key for the provider, with `path:line`. Use [../references/providers.md](../references/providers.md) for search terms. Record configuration keys by name only.
3. **Money-movement flows.** For each call site, say what it does in business terms: link a bank account, create a customer, collect a payment, send a payout, handle a status event, refund.
4. **Tests** that cover those flows, and the command the repository uses to run them.
5. **Existing Straddle code**, if any, with SDK name and resolved version from the lockfile.

**Summary for step 3:** git baseline, the call-site table (`path:line`, flow, provider API), config key names, tests and test command.
