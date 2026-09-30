# Step 8: Report

- **Needs:** every earlier summary.
- **Tools:** none.
- **Next:** [straddle-test](../../straddle-test/SKILL.md) to prove the new path in Sandbox, after the developer reviews the diff. Test reads the approved `straddle-migration-plan.md` and its Verification section directly; no `straddle-integration-plan.md` is needed, and the plan's approval authorizes no Sandbox write. In a [Straddle Wizard program](../../straddle-best-practices/references/wizard-program.md) session, continue with the next program step in this session when the status is `migrated`, and stop and wait for the developer otherwise.

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-migrate","step":"08-report"}
```

Open with two or three plain sentences in the [Straddle voice](../../straddle-best-practices/references/voice.md): what changed, what didn't, and what's next. Then reply in this shape:

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

End with the checklist below. Leave every box unchecked. The checklist is for the developer to tick after checking, not a record of what the skill verified.

```markdown
## Verify before merging

- [ ] Every changed file is listed in the approved plan.
- [ ] No existing provider code, test, or config was deleted or rewritten.
- [ ] The Straddle path is off by default or switched exactly as the plan says.
- [ ] Missing Straddle key or environment raises a configuration error in the new code.
- [ ] No customer data, provider token, or key appears in code, tests, the plan, or this report.
- [ ] Every provider status the code used maps to a Straddle status in the plan, and `failed` and `reversed` are handled separately.
- [ ] The consent decision for Straddle-path customers is recorded, with who made it.
- [ ] Tests ran, and their result is stated above.
```

Then print the handoff, followed by one plain sentence that says what finished and what comes next:

```text
STRADDLE_HANDOFF {"skill":"straddle-migrate","status":"<status>","report":"<one-paragraph summary>"}
```
