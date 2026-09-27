# Step 6: Edit

- **Needs:** an approval recorded in the plan in this run or unchanged since it was recorded.
- **Tools:** Read, Write, Edit on files in the approved table only. Bash for `git status --porcelain`.
- **Next:** [07-review.md](07-review.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-migrate","step":"06-edit"}
```

Before the first edit, run `git status --porcelain` again. If any approved file changed since the step 2 baseline, stop and ask.

Make the approved changes, one row at a time:

- Read the installed Straddle SDK in the dependency tree (its `api.md`, README, and resource source) before naming a method, parameter, or option. Do not write calls from memory or from another version's docs.
- Use only operations in the public Straddle API contract. If an SDK method, CLI command, or path is absent from the public contract or its scope is unclear, stop and resolve it against the public contract; do not fall back to the SDK, CLI, or MCP for it.
- Put Straddle calls behind the approved switch. The existing provider path stays the default unless the plan says otherwise, and keeps working unchanged.
- Read the API key and environment from the application's configuration and fail with a configuration error that names the missing value before any request. Do not rely on an SDK default environment.
- Apply account scope for the chosen model through the SDK's own parameter. Send an idempotency key and a stable external ID on every create.
- Implement the chosen notification path per [receiving-webhooks.md](../../straddle-best-practices/references/receiving-webhooks.md). Do not port a provider status-polling loop onto Straddle resource reads.
- Add tests beside the existing ones for each new path, using the repository's test style and no real key.

If a change turns out to need a file or kind of change not in the table, stop, update the plan, and return to step 5.

**Summary for step 7:** files touched, tests added.
