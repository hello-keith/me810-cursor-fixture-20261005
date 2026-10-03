---
description: "A guest-checkout shop with no customer accounts: Plan's identity-mapping question maps a user ID the app holds to one Straddle customer and stores the customer id, because a customer's email is unique on the account. It never recommends a new customer per checkout, or a customer keyed on an email typed at checkout with no app user behind it."
tags: [plan, decisions, interview, identity]
max_turns: 30
allowed_tools: [Read, Glob, Grep, Skill, AskUserQuestion, Write, Edit]
---

Plan our Straddle integration for this repo. We're one coffee roaster selling on our own site, so it's a direct integration, Pay by Bank charges only. Shoppers check out as guests: there are no customer accounts or logins, just name, email, and phone on the checkout form.
