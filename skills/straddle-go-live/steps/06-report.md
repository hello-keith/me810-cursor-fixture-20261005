# Step 6: Report

- **Needs:** summaries from steps 2 to 5.
- **Tools:** Write only if the developer asked for the report as a file (`straddle-go-live-report.md`).
- **Next:** the developer's decision. Failed rows route to [straddle-audit](../../straddle-audit/SKILL.md) or [straddle-test](../../straddle-test/SKILL.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-go-live","step":"06-report"}
```

The status is `ready` only when every required row passed with tool evidence or developer confirmation. Any `fail` or `unproven` required row makes it `not_ready`. A configuration failure that leaves the environment unknown makes it `blocked`.

Reply in this shape:

```markdown
# Straddle Go Live review

Status: ready | not_ready | blocked
Model: <direct / SaaS / marketplace>   SDK: <package version>   Environment checked: <host / unknown>

## Blocking gaps
| Row | Result | Evidence | Fix |
| --- | --- | --- | --- |

## Checklist
| Section | Row | Result | Evidence |
| --- | --- | --- | --- |

## Declined requests
## What this review did not do
- No production write was made or authorized.
- <production read: not run / ran once with status N>
```

End with the checklist below. Leave every box unchecked. The checklist is for the developer to tick after checking, not a record of what the skill verified.

```markdown
## Verify before merging

- [ ] Every `pass` row cites a file, test output, or a labeled developer confirmation.
- [ ] No key, signing secret, or `.env` content appears in this report.
- [ ] No production resource was created, changed, or deleted.
- [ ] The production notification endpoint is a webhook, FIFO, or polling endpoint, not API polling or Dashboard email.
```

Then print the handoff:

```text
STRADDLE_HANDOFF {"skill":"straddle-go-live","status":"<status>","report":"<one-paragraph summary with the blocking gaps>"}
```
