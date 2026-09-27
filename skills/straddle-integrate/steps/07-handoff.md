# Step 7: Handoff

- **Needs:** every earlier summary that exists for this run.
- **Tools:** none.
- **Next:** [straddle-test](../../straddle-test/SKILL.md) when the status is `complete`.

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-integrate","step":"07-handoff"}
```

Report in this shape. State what the run verified and what it did not. A passing unit test proves code behavior, not that Sandbox accepted a request.

```markdown
# Straddle Integrate report

Status: complete | awaiting_approval | blocked (<reason>)

## Code changes
| File | Change | Test |

## Server-side resources
| Resource | ID | External ID | Acting account | Created, reused, or enabled | Tool |

(Organizations, accounts, customers, paykeys, charges or payouts, and any webhook, FIFO, or polling endpoint the developer enabled. Write "None" when the run made no Sandbox write.)

## Not done
(Preview rows not approved or not run, indeterminate rows, configuration errors, failed checks.)

## Next
```

End with:

```markdown
## Verify before merging

- [ ] Only the approved files changed, and existing provider code is intact.
- [ ] No secret or unmasked data appears in the diff, tests, or this report.
- [ ] Every resource above was in an approved preview row.
- [ ] Creates send idempotency keys and external IDs.
- [ ] Notifications use the selected webhook, FIFO, or polling endpoint, with no status polling of resource reads.
```

Then print on one line:

```text
STRADDLE_HANDOFF {"skill":"straddle-integrate","status":"<complete|awaiting_approval|blocked>","report":"<one-paragraph summary: files changed, resources created or reused, and blockers>"}
```
