Offline eval fixture of the intended search-only Docs MCP, not proof that ME-809 passed.

Receiving webhooks: Straddle signs each delivery with webhook-id, webhook-timestamp, and webhook-signature headers and a whsec_ secret. Verify the raw body, return 2xx promptly, and deduplicate by webhook-id. A polling endpoint returns messages with an offset per consumer ID.
