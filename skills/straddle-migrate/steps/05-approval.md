# Step 5: Approval

- **Needs:** step 4 summary and the written plan.
- **Tools:** AskUserQuestion when available, otherwise ask in chat. Edit for `straddle-migration-plan.md` only, to record the answer.
- **Next:** [06-edit.md](06-edit.md) on approval; [08-report.md](08-report.md) otherwise.

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-migrate","step":"05-approval"}
```

Show the developer the authorized-modifications table and the not-moved section, and ask for an explicit yes to exactly that plan. "Looks fine", silence, or a non-interactive run is not approval.

- **Yes:** add an `## Approval` entry with the date, the developer's words, and the row count approved. Continue to step 6.
- **Changes requested:** update the plan, then ask again. The earlier answer does not carry over.
- **Plan has `Unresolved` items that affect a listed file:** do not ask for approval yet; hand off with `awaiting_approval`.
- **No or stop:** print `STRADDLE_ABORT` with the reason and go to step 8.

**Summary for step 6:** approval recorded (yes or no), the approved rows.
