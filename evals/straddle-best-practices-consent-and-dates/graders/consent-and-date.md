---
type: llm
---

PASS if the reply says `consent_type` `internet` (a WEB authorization), says to keep the authorization record (consent text, time, IP address, customer) for the life of the recurring authorization and after it ends, so it can be uploaded as proof of authorization in a dispute, and says `payment_date` must be the US Eastern calendar date, because at 9 PM Eastern the UTC date is already tomorrow and the charge would wait a day.
FAIL if the reply picks `signed` for the checkbox, keeps the UTC date, or omits keeping the authorization.
