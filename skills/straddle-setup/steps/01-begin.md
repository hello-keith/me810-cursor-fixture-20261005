# Step 1: Begin

- **Needs:** the developer's request.
- **Tools:** Read, Glob. No shell commands yet, no writes.
- **Next:** [02-repository.md](02-repository.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-setup","step":"01-begin"}
```

Read [straddle-best-practices](../../straddle-best-practices/SKILL.md) and keep its rules in force for the rest of the run.

Note anything the developer already told you: environment, integration type (direct, SaaS, or marketplace), SDK language, notification path, acting account, or output they pasted from `straddle doctor`. Treat those as developer input, and still check them against tool output where a tool can confirm them.

If a `straddle-integration-plan.md` or an earlier Setup report exists in the repository, read it for context. Do not treat an earlier result as current. Every check in this run is fresh.

## Kit versions

Record, without changing anything:

- the agent client running this session (Claude Code, Codex, or Cursor)
- the Agent Plugin `version` from `plugin.json` at the plugin root, two directories above this skill's `SKILL.md`
- the `version` in the native manifest for this client at the plugin root (`.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, or `.cursor-plugin/plugin.json`), and whether it matches the plugin version
- `metadata.version` of `straddle-setup`, `straddle-plan`, and `straddle-best-practices`
- a Straddle Wizard version only if the developer's environment reports one; otherwise `not installed`

Record a file you cannot read as `unknown`, not as a pass.

**Summary for step 2:** the developer's stated decisions, any earlier plan file found, and the kit versions above.
