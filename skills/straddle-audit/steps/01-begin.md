# Step 1: Begin

- **Needs:** the developer's request.
- **Tools:** Read, Glob, Grep. Bash for `git status --porcelain` and `git worktree list`. No writes.
- **Next:** [02-context.md](02-context.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-audit","step":"01-begin"}
```

Read [straddle-best-practices](../../straddle-best-practices/SKILL.md) and keep its rules in force.

1. **Symptom.** Record what the developer reported in their words: the failing flow, error text, status code, request IDs, and when it started. Quote only sanitized text.
2. **Presence.** Grep for a Straddle SDK import or dependency (`@straddlecom/straddle`, `straddle-build/straddle-go`, the `straddle` gem, `Straddle` NuGet, Python `straddle`), direct calls to `straddle.com`, and `straddle` CLI use in scripts. If nothing matches, print `STRADDLE_ABORT` with reason `no Straddle integration found` and stop.
3. **Baseline.** Run `git status --porcelain` and `git worktree list`, and keep both. Every worktree listed is a place a later commit could land.

**Summary for step 2:** symptom, Straddle entry points found, git baseline and worktrees.
