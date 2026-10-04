# Step 3: Choices only the developer can make

Print this marker once now, before any tool call, including a follow-up Read or reading the next step file:

```text
STRADDLE_PROGRESS {"skill":"straddle-get-started","step":"03-choices"}
```

- **Needs:** step 1 and step 2 summaries.
- **Tools:** AskUserQuestion when the client has it, otherwise ask in chat. Read for follow-up evidence. No writes.
- **Next:** [04-route.md](04-route.md).

Ask every choice that is still `unanswered`, one short question each, with the repository hint shown beside it so the developer can confirm or correct it. Offer only real options.

A choice the developer already stated is answered. Record it with source `developer`, give its Straddle meaning in one line if that helps, and do not ask it again. Ask about it only when repository evidence contradicts it, and then show that evidence.

1. **Product.** Pay by Bank charges, payouts, platform onboarding of businesses, or a combination.
2. **Integration model.** Direct account (one business moving its own money), SaaS platform (your clients own their customers), or marketplace (the platform owns customers and pays sellers). Explain the consequence in one line each: a direct account never sends `Straddle-Account-Id`; SaaS and marketplace act for an explicitly selected embedded account on some operations. Do not pick one because the code mentions "sellers" or "tenants". When the developer already named a model, record it with its one-line consequence and move on. Do not list the other models or ask the developer to confirm it.
3. **SDK.** Offer the published SDK for each language the repository actually uses, from the Current versions table in [straddle-best-practices](../../straddle-best-practices/SKILL.md) (TypeScript, Python, Go, Ruby, C#). When the lockfile pins a retired release, say which and offer the current one.
4. **Notification path.** The webhook endpoint (public HTTPS handler, one event per request) is the default; offer it first. A FIFO endpoint or a polling endpoint fits only the cases [notifications.md](../../straddle-best-practices/references/notifications.md) names. Dashboard email is a human confirmation, not one of these options, and looping on resource reads is never offered.

When an answer isn't available in this turn, because you asked in chat or the client can't ask at all, don't stop here to wait. Record each unanswered choice as `open`, then continue to step 4 and step 5 and end with the `needs_input` report and `STRADDLE_HANDOFF` before yielding. Don't guess the answers, start the next skill, install anything, or write files.

**Summary for step 4:** each choice with its source (`developer` or `open`).
