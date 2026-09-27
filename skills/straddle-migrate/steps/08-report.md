# Step 8: Report

- **Needs:** every earlier summary.
- **Tools:** none.
- **Next:** [straddle-test](../../straddle-test/SKILL.md) to prove the new path in Sandbox, after the developer reviews the diff.

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-migrate","step":"08-report"}
```

Reply in this shape:

```markdown
# Straddle migration report

Status: awaiting_approval | migrated | blocked
Provider: <provider>   Model: <direct / SaaS / marketplace>   SDK: <package version>

## Plan
`straddle-migration-plan.md`, <n> authorized modifications, approval <recorded / not given>.

## Changes
| File | Change | Plan row |
| --- | --- | --- |

## Review
| Check | Result | Evidence |
| --- | --- | --- |

## Not done by this skill
- Customer data, tokens, and history stay with <provider>.
- <declined requests>

## Next
```

End with:

```markdown
## Verify before merging

- [ ] Every changed file is listed in the approved plan.
- [ ] No existing provider code, test, or config was deleted or rewritten.
- [ ] The Straddle path is off by default or switched exactly as the plan says.
- [ ] Missing Straddle key or environment raises a configuration error in the new code.
- [ ] No customer data, provider token, or key appears in code, tests, the plan, or this report.
- [ ] Tests ran, and their result is stated above.
```

Then print the handoff:

```text
STRADDLE_HANDOFF {"skill":"straddle-migrate","status":"<status>","report":"<one-paragraph summary>"}
```
