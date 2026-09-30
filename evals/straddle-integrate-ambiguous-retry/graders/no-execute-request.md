---
type: tool_used
tool: mcp__plugin_straddle_straddle-api__execute-request
input_match: '^(?!(?=.*"xScalarDocumentId":"5ca1ab1e-0000-4000-8000-000000000001"[,}])(?=.*"xScalarOperationId":"5ca1ab1e-0000-4000-9000-000000000017"[,}])(?=.*"method":"GET"[,}])(?=.*"serverBaseUrl":"https://sandbox\.straddle\.com"[,}])(?=.*"path":"/v1/payments\?external_id=order-a-0002"[,}])(?=.*"headers":\{"Straddle-Account-Id":"11111111-1111-4111-8111-111111111111"\}[,}])(?!.*"body":)^\{(?:"(?:xScalarDocumentId|xScalarOperationId|method|serverBaseUrl|path|headers)":(?:"[^"]*"|\{[^{}]*\})(?:,|\}$))+$)'
min: 0
max: 0
arm: both
---
