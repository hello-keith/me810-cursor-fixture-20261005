---
expect:
  xScalarDocumentId: "5ca1ab1e-0000-4000-8000-000000000001"
  xScalarOperationId: "5ca1ab1e-0000-4000-9000-000000000017"
  method: GET
  serverBaseUrl: https://sandbox.straddle.com
  path: ["/v1/payments?external_id=order-a-0002"]
  headers:
    Straddle-Account-Id: "11111111-1111-4111-8111-111111111111"
---

Synthetic offline fixture: no Straddle request was sent.
HTTP 200
{"data":[],"response_type":"array","meta":{"api_request_id":"00000000-0000-4000-8000-0000000000a2","api_request_timestamp":"2026-01-15T12:00:00Z","total_items":0,"page_number":1,"page_size":100,"max_page_size":1000,"sort_by":"created_at","sort_order":"desc","total_pages":0}}
