---
type: llm
focus: { source: file, path: app/main.py }
---

You see only app/main.py. PASS if all hold: it imports the blueprint from `app/webhooks.py` (for example `from app.webhooks import ...` or `from .webhooks import ...`) and calls `app.register_blueprint` with it, where any `url_prefix` written in this file is `/webhooks/straddle` or a leading part of it; and nothing in this file reads, parses or replaces the request body before the view runs in a way that changes the bytes `request.get_data()` returns, and when it enables CSRF protection the blueprint is exempt.
FAIL if the blueprint isn't imported or registered, is registered under a different prefix, or this file alters the request body or applies CSRF protection to the webhook route.
