# Step 3: Choices only the developer can make

- **Needs:** step 1 and step 2 summaries.
- **Tools:** AskUserQuestion when the client has it, otherwise ask in chat. Read for follow-up evidence. No writes.
- **Next:** [04-route.md](04-route.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-get-started","step":"03-choices"}
```

Ask every choice that is still `unanswered`, one short question each, with the repository hint shown beside it so the developer can confirm or correct it. Offer only real options.

1. **Product.** Pay by Bank charges, payouts, platform onboarding of businesses, or a combination.
2. **Integration model.** Direct account (one business moving its own money), SaaS platform (your clients own their customers), or marketplace (the platform owns customers and pays sellers). Explain the consequence in one line each: a direct account never sends `Straddle-Account-Id`; SaaS and marketplace act for an explicitly selected embedded account on some operations. Do not pick one because the code mentions "sellers" or "tenants".
3. **SDK.** Offer the published SDKs for the languages the repository actually uses: TypeScript `@straddlecom/straddle`, Go `github.com/straddle-build/straddle-go`, Ruby `straddle`, C# `Straddle`. When the only application language is Python, say that no published Scalar Python SDK exists yet and that this blocks SDK selection; do not offer `pip install straddle`.
4. **Notification path.** Webhook endpoint (public HTTPS handler), FIFO endpoint (strict order), or polling endpoint (no public URL needed). Dashboard email is a human confirmation, not one of these options, and looping on resource reads is never offered.

If the client cannot ask interactively (a non-interactive run), list the open questions in the report, set the handoff status to `needs_input`, and do not answer them yourself.

**Summary for step 4:** each choice with its source (`developer` or `open`).
