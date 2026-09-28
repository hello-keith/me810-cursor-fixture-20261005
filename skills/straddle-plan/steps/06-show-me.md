# Step 6: Show the approved plan

- **Needs:** the step 5 handoff, then the developer's explicit approval of the current `straddle-integration-plan.md` in their own message, such as "approved" or "the plan looks right".
- **Tools:** Read for `straddle-integration-plan.md` and [show-me.md](../references/show-me.md). Write only for `straddle-plan-visual.html` at the repository root, and only when an HTML view is warranted.
- **Next:** Integrate runs the approved plan.

Run this step only after that approval. Silence, a question, a request for changes, or approval of an earlier version is not approval. Never assume or infer it, and never approve for the developer. If the developer asks for changes instead, go back to [03-write-plan.md](03-write-plan.md) and run steps 3 to 5 again. If they don't approve, this step doesn't run and nothing is shown.

Print this once, right after reading this file and before any other tool call:

```text
STRADDLE_PROGRESS {"skill":"straddle-plan","step":"06-show-me"}
```

Read the plan once, then follow [show-me.md](../references/show-me.md) to help the developer see the approved plan. Pick the smallest view that makes it clear, such as a Mermaid sequence of customer, Bridge and paykey, charge or payout, and the chosen notification path, or a `diff` file tree of the planned changes. Show only what the plan already says, and don't add operations, files, or decisions.

- Put diagrams and code sketches inline in your reply. Don't edit the approved plan file, because changing it after approval would need a new approval.
- Write `straddle-plan-visual.html` only when the point is too dense for Mermaid, and write nothing else. Keep it to one self-contained file with no scripts, fonts, or styles loaded from the network. It must not contain a key, token, paykey value, or `.env` content. Don't run a command to open it. Give the path and say it hasn't been visually checked. This replaces the reference's instruction to open the file.
- Run no command, and make no MCP call or API request. Don't read `.env*`, credential stores, or private keys, and don't change application code.

Say that this view doesn't change the plan and authorizes nothing new. Approving the plan still permits only its listed code changes, and each Sandbox write still needs its own preview and approval when Integrate or Test runs it.

**Summary:** the views shown, and the path of `straddle-plan-visual.html` if one was written.
