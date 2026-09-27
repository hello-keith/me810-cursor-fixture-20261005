# Step 1: Begin

- **Needs:** the developer's request and `straddle-integration-plan.md` at the repository root.
- **Tools:** Read, Glob, Grep; Bash only for the presence checks below and `straddle --version`. No writes, and no Straddle request.
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

## Configuration

Check presence only. Never print, echo, or read a value, and never open `.env*` or CLI config files to find one.

```bash
test -n "$STRADDLE_API_KEY" && echo "STRADDLE_API_KEY present" || echo "STRADDLE_API_KEY missing"
printf 'STRADDLE_ENVIRONMENT=%s\n' "${STRADDLE_ENVIRONMENT:-<unset>}"
test -n "$STRADDLE_BASE_URL" && echo "STRADDLE_BASE_URL set" || echo "STRADDLE_BASE_URL unset"
```

With the CLI installed, `straddle --version` and `straddle doctor --agent` add detail. Read `doctor`'s `env_vars`, `auth`, and, when present, `runtime_context`, not its exit code. `doctor` reports that a key is present, not that it works.

Record one of:

- **configured:** key present and the environment explicitly Sandbox (`STRADDLE_ENVIRONMENT=sandbox`, or a `STRADDLE_BASE_URL` of `https://sandbox.straddle.com`).
- **configuration error:** key missing, environment unset, or environment not Sandbox. Name exactly what is missing.

A configuration error does not stop code changes to approved files, because those send no request. It does stop every Straddle request later in the run: no SDK call, CLI command without `--dry-run`, or `execute-request`. Say so now, in one sentence, so the developer can fix it in their own shell while the code work proceeds.

For a SaaS or marketplace plan, also record the acting accounts the plan names (A and B), or that they do not exist yet.

**Summary for step 2:** plan state, integration type, SDK, notification path, the approved file list, the planned Sandbox writes, the configuration result, and the acting accounts.
