# Step 1: Begin

- **Needs:** the developer's request and `straddle-integration-plan.md` at the repository root.
- **Tools:** Read, Glob, Grep; Bash only for the offline checks below, `straddle --version`, and `straddle auth status --agent`. No writes, and no command that can reach Straddle, including `straddle doctor`.
- **Next:** [02-sources.md](02-sources.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-integrate","step":"01-begin"}
```

Read [straddle-best-practices](../../straddle-best-practices/SKILL.md).

## The approved plan

Read `straddle-integration-plan.md`. Integrate needs, from the plan:

- plan state `Approved`, or the developer saying in this conversation that they approve it
- integration type, SDK, and notification path decided, not `Unresolved`
- the file-change table, which becomes the only files Integrate may change
- the future Sandbox writes table

If there is no plan, or it is not approved, stop and hand off to [straddle-plan](../../straddle-plan/SKILL.md): print `STRADDLE_ABORT` with the reason and the `blocked` handoff. Do not reconstruct a plan from the request. A request that adds files or writes beyond the plan needs the plan updated and approved first. Say which items are new.

## Configuration, offline first

Establish the environment and credential presence before running any command that can reach Straddle. `straddle doctor` does not qualify, because it sends `GET /` before it checks auth, so do not use it as a preflight. Never print, echo, or read a credential value, and never open `.env*` files or the CLI's config file.

```bash
printf 'STRADDLE_ENVIRONMENT=%s\n' "${STRADDLE_ENVIRONMENT:-<unset>}"
test -n "$STRADDLE_BASE_URL" && echo "STRADDLE_BASE_URL set" || echo "STRADDLE_BASE_URL unset"
if [ -n "${STRADDLE_API_KEY:-}" ]; then key=present; else key=missing; fi
echo "STRADDLE_API_KEY $key"
```

**Environment.** Only an explicit selection counts: `STRADDLE_ENVIRONMENT=sandbox`, or `STRADDLE_BASE_URL=https://sandbox.straddle.com`, in the environment the run executes in. A default is not a selection. That includes the SDK's default base URL and the CLI's `runtime_context.environment`, which reports what the CLI resolved, not what the developer chose. Any other value, including Production, is a configuration error for Integrate.

**Credential presence, per route.** Each check reports presence only and never proves the key works.

- **SDK and application code** read `STRADDLE_API_KEY` from the process environment, so the presence line above is the check.
- **CLI.** `straddle auth status --agent` reads only the CLI's local configuration and sends no request. It reports `authenticated` and a `source` (the environment variable or saved CLI auth) without the value. Saved CLI auth is a valid credential for CLI rows.
- **API MCP.** The key lives in the client's secret input, where Integrate cannot see it. Ask the developer whether they set it, and never ask for the value. When they confirm, a permitted authenticated read can then show whether it works.
- When a check cannot run, for example because the CLI is not installed, ask the developer to confirm presence, and record the answer as `developer-confirmed, not verified`. Record `unknown` when there is no answer.

Record, for each route the plan's writes use:

- **configured:** the environment is explicitly Sandbox, and that route's credential is present or developer-confirmed.
- **configuration error:** the environment is not explicit or not Sandbox, or that route has no credential or an unknown one. Name exactly what is missing.

A configuration error does not stop code changes to approved files, because those send no request. It does stop every Straddle request on the affected routes later in the run: no SDK call, CLI command without `--dry-run`, or `execute-request`. Say so now, in one sentence, so the developer can fix it in their own shell while the code work proceeds.

For a SaaS or marketplace plan, also record the acting accounts the plan names (A and B), or that they do not exist yet.

**Summary for step 2:** plan state, integration type, SDK, notification path, the approved file list, the planned Sandbox writes, the configuration result, and the acting accounts.
