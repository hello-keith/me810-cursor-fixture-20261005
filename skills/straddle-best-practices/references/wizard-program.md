# Straddle Wizard program

The Straddle Wizard can run the whole integration in one agent session. It starts the session with a request that contains a line beginning `Straddle Wizard program:`. That line lists the steps for this session and says where to start, for example `Start at straddle-plan.` Run only the steps the line lists, in its order. When its last step finishes, the program ends for this session, even if later steps exist. Without that line, each skill runs on its own and ends at its handoff, as its step files say.

The program, in order:

1. [straddle-setup](../../straddle-setup/SKILL.md)
2. [straddle-plan](../../straddle-plan/SKILL.md)
3. [straddle-migrate](../../straddle-migrate/SKILL.md), only when the program line includes it because the repository uses another payment provider
4. [straddle-integrate](../../straddle-integrate/SKILL.md)
5. [straddle-test](../../straddle-test/SKILL.md)
6. [straddle-go-live](../../straddle-go-live/SKILL.md)

## Continue in the same session

When a skill finishes its handoff in a program session:

- **Finished:** tell the developer in one sentence what's next, then start the next skill in this session, the way this client starts a skill (for example Claude Code's Skill tool) or by reading its `SKILL.md`. Don't stop to wait for the Wizard, and don't ask whether to continue. The table below says when a step has finished.
- **Not finished** (blocked, awaiting an approval or a decision, partial, or failed): stop at that step. Say in a sentence or two what the developer needs to do, and wait for them. Continue when they've resolved it, or when they tell you to move on.
- **Load only the next skill.** Open its `SKILL.md`, then one step file at a time, as its Markers section says. Don't reread an earlier skill's step files. Take an earlier step's results from its file in the table, not from memory, because the developer may have changed it.
- **Each skill keeps its own rules.** Its step files set its tools, writes, and boundaries. Nothing carries over from the skill before it.
- **The program line approves nothing.** It isn't a plan approval, a write approval, or an answer to any question a skill asks. Plan approval still needs the developer's own words, and every Sandbox write still needs its own preview and an explicit yes.

A skill's "the handoff ends the turn" rule still holds in a program session. The skill doesn't continue into the developer's original request or answer for them. Starting the next program step isn't a continuation of that request. It's the program the Wizard asked for.

## Step files

Each step records its state in a file at the repository root, starting with a small header block. The Wizard resumes from these files, so write the header exactly as shown.

| Step | File | Header | Finished when |
| --- | --- | --- | --- |
| Setup | `straddle-setup.md` | `Status: complete` or `Status: blocked (<reason>)`, then `Environment:`, `Integration type:`, `API key present: yes` or `no`, `SDK:`, `Acting account:` | `Status: complete` |
| Plan | `straddle-integration-plan.md` | `- Plan state: Draft`, `Approved`, or `Blocked`, and `- Approval: none` or the recorded approval with its sha256 | step 6 recorded `Approved` with a hash that matches the plan |
| Migrate | `straddle-migration-plan.md` | the same two lines as the integration plan | the approval is recorded with a matching hash, and the handoff is `migrated` |
| Integrate | `straddle-integration-report.md` | `Status: complete`, `Status: partial (<reason>)`, or `Status: blocked (<reason>)`, then `Plan:` and `Plan hash:` | `Status: complete` for the current plan's hash |
| Test | `straddle-test-evidence.md` | `Status: complete`, `Status: partial (<reason>)`, or `Status: blocked (<reason>)`, then `Plan:`, `Plan hash:`, `Latest run:`, and `Test charge:` | `Status: complete` for the current plan's hash |
| Go Live | `straddle-go-live-report.md` | `Status: ready` or `Status: not ready (<reasons>)`, then `Plan:` and `Plan hash:` | `Status: ready` for the current plan's hash. A `not ready` report sends the Wizard back to Go Live, which shows the listed gaps. In this session Go Live is still the last step. |

`Plan hash` is the plan's approval hash, computed with the same command as the `Approval` line in Integrate's [Recorded approval](../../straddle-integrate/steps/01-begin.md#recorded-approval), on the plan file the step used. A report whose `Plan hash` differs from the current plan's is for an older plan, so that step hasn't finished for this one. Never write a key, token, or other secret value into any of these files.

## When the program ends

After Go Live's handoff, close with a short summary: each step and its result, the files above, and the Sandbox test charge ID from the evidence file's `Test charge:` line, so the developer can find it in the Sandbox dashboard. Name what's still open, such as a partial Test or the Go Live gaps. Don't start anything new.
