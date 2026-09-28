# Other providers and hand-rolled ACH

Use this for any processor not listed, and for applications that build NACHA files themselves and upload them to a bank.

## Find it

`nacha`, `ach`, `routing_number`, `account_number`, fixed-width record builders (records starting `101`, `5`, `6`, `8`, `9`), SFTP or bank-portal uploads, return-file and NOC-file parsers, SEC code constants, and the processor's own host names.

## Questions to answer with the developer

- Which flows exist: debits, credits, refunds, prenotes, micro-deposits.
- How the app learns outcomes: return files, NOC files, a processor callback, or polling.
- Which statuses the app stores and what each means.
- Where authorizations are kept and whose name they carry.
- Whether a bank or processor relationship moves with the change (it usually does not).

## Map

Map each described flow onto charges, payouts, paykeys, and a notification endpoint, and each stored status onto the Straddle vocabulary in [../providers.md](../providers.md). File generation, SFTP upload, and return-file parsing stay in place behind the switch for payments still on the old path.

## Never moves

Stored bank details, generated files, and payment history.

## Pitfalls

- Hand-rolled return parsing often keys on R-codes and file positions; Straddle delivers returns as events with return codes on the payment.
- Balanced files (offsetting entries) belong to file-based origination. Straddle payments settle through funding events, so the plan drops the offset logic for Straddle-path payments only after confirming this in the Straddle docs.
