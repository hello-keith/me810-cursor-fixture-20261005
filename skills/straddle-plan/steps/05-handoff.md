# Step 5: Handoff

- **Needs:** step 4 summary.
- **Tools:** none.
- **Next:** the developer reviews the plan. When the status is `draft` and they explicitly approve it, [06-show-me.md](06-show-me.md) records the approval and shows the plan on that later turn, then Integrate runs it. A `blocked` plan goes back to its unresolved decisions first.

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-plan","step":"05-handoff"}
```

Tell the developer, briefly:

- the integration shape (type, products, SDK and version, notification path)
- the files the approved implementation would change
- the future Sandbox writes and their executing tools
- unresolved decisions that block implementation
- the verification commands

State that approving the plan permits only the listed code changes. Each Sandbox write still needs its own preview and approval when Integrate or Test runs it.

End with:

```markdown
## Verify before merging

- [ ] Every SDK method in the plan exists in the installed SDK version.
- [ ] The account-scope table matches the integration type.
- [ ] The notification path is a webhook, FIFO, or polling endpoint.
- [ ] No planned write of the fourteen excluded operations uses the API MCP.
- [ ] No secret appears in the plan.
```

Then print on one line:

```text
STRADDLE_HANDOFF {"skill":"straddle-plan","status":"<draft|blocked>","report":"<one-paragraph summary including the plan path>"}
```

**Summary for step 6:** the plan path and the handoff status.
