# Step 5: Production setup

- **Needs:** step 2 summary.
- **Tools:** AskUserQuestion when available, otherwise ask in chat. A production read only under the rule below. No writes.
- **Next:** [06-report.md](06-report.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-go-live","step":"05-production-setup"}
```

Ask the developer to confirm each item in the production-setup section of [../references/readiness-checklist.md](../references/readiness-checklist.md). These live in the Straddle dashboard and the developer's deployment, which the skill cannot see. Record each as `confirmed by developer`, `not done`, or `unknown`. A person confirming is not the same as tool evidence; label it that way.

Dashboard email is a human confirmation channel. It does not satisfy the notification row; a production webhook, FIFO, or polling endpoint does.

**Production read, only if asked.** If the developer asks to confirm the production key, and step 2 found the key present and the environment explicitly production:

1. Show the exact read (CLI command with `--agent --data-source live`, or a permitted `execute-request` GET), the resolved host, and the account scope.
2. Run it only after an explicit yes, once.
3. Record the status code or error, not the response body.

Never offer or run a production write, including a "test" charge, a webhook endpoint creation, or a cleanup delete.

**Summary for step 6:** each production-setup row, and the production read result if one ran.
