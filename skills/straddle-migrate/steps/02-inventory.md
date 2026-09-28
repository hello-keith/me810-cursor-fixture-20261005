# Step 2: Inventory

- **Needs:** step 1 summary.
- **Tools:** Read, Glob, Grep preferred. Bash only for bounded read-only local inspection: `git status --porcelain`, `git rev-parse --show-toplevel`, other read-only `git` commands, directory listings, reading repository source, and installed tool-version checks such as `node --version`. No network requests, installs, project-script or test execution, or writes. Never open `.env*`, private keys, credential stores, or CLI config files.
- **Next:** [03-choices.md](03-choices.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-migrate","step":"02-inventory"}
```

1. **Working tree.** Run `git status --porcelain` at the repository root and keep the output. It is the baseline for step 7. If the repository is not under git, say so; step 6 will then require the developer to confirm a backup before editing.
2. **Provider reference.** Identify the provider from dependencies and imports, then read [../references/providers.md](../references/providers.md) and that provider's file under `references/providers/`. Its "Find it" section lists the packages and strings to search for. A provider not listed uses `providers/other.md`.
3. **Provider footprint.** Find every import, client construction, API call, webhook handler, and configuration key for the provider, with `path:line`. Record configuration keys by name only.
4. **Money-movement flows.** For each call site, say what it does in business terms: link a bank account, create a customer, collect a payment, send a payout, refund, handle a status event.
5. **Behavior that has to be mapped**, each with `path:line`:
   - every provider status or event the code stores, compares, or branches on
   - return, failure, and notification-of-change handling, including code keyed on provider failure codes
   - retries or redrafts of failed payments
   - how the provider-side idempotency key or duplicate guard is built
   - where debit authorization is captured and what its wording says (quote it; do not open `.env*` or credential files to find it)
   - status polling, report queries, or file parsing used to learn outcomes
   - scheduled or future-dated payments
6. **Tests** that cover those flows, and the command the repository uses to run them.
7. **Existing Straddle code**, if any, with SDK name and resolved version from the lockfile.

**Summary for step 3:** git baseline, provider and its reference file, the call-site table (`path:line`, flow, provider API), the behavior list from item 5, config key names, tests and test command.
