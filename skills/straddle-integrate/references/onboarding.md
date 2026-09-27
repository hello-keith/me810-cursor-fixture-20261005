# Platform onboarding

SaaS and marketplace platforms onboard embedded accounts in two separate ways. Keep them apart in code, previews, and evidence.

## Fast Sandbox bootstrap through the API

This path is for tests. After the preview is approved, create or reuse the organization and accounts A and B with the SDK or CLI ([execution-routes.md](execution-routes.md)). Each one gets a stable, non-sensitive external ID, for example `acme-kit-<run>-org`, `acme-kit-<run>-acct-a`, and `acme-kit-<run>-acct-b`.

1. Look up each external ID exactly (`GET /v1/organizations` or `GET /v1/accounts` with `external_id`). Reuse a single exact match. Stop and ask when there is more than one match. Create only the ones that are missing.
2. When the organization is new, create the accounts with `organization_id` set to the `data.id` from the organization create response.
3. Record the account IDs from the create responses, and use those IDs as accounts A and B.

Until Onboarding V2, API-created accounts satisfy the platform acceptance step. The form-created account proof is deferred.

## Customer-facing hosted iframe

The customer-facing path is Straddle's hosted onboarding form in an iframe. A person fills in the form. The platform's code does not complete it.

- Build the iframe `src` from the current hosted onboarding guide. At the time of writing it is `https://go.straddle.com/account?...&embed=1&platform.id=<platform id>&env=sandbox&external.id=<your account external ID>`, loaded by the guide's `https://forms.straddle.com/embed.js` script. Check the guide before copying parameters.
- `env=sandbox` for integration work. Production needs the developer's own separate decision.
- An external ID is required by this kit, even though the guide marks it optional, because it is how the platform finds the account later. It is `external.id` in the guide's URL parameters and `externalId` in the build plan. Generate it server-side, store it with the platform's own record, and never put a secret or personal data in it.
- The platform ID comes from configuration, not source code.
- Do not use the React embed wrapper or copy `straddleio/embed` into the repository. It returns with Onboarding V2.

## Resolving the onboarded account

The form does not call back into the page, so never add an `onComplete` handler or wait on the iframe in code or CI. Resolve the account in one of these ways:

- **Selected notification path.** Handle the account event from the webhook, FIFO, or polling endpoint the plan chose, and match it to your record by the account's `external_id`.
- **Exact external-ID lookup.** An authenticated `GET /v1/accounts?external_id=<id>` read, run once when the person reports they finished or when the platform needs the status. Reject zero or several matches.
- **Dashboard email.** A human confirmation that the account exists. Code never depends on it.

Loop-reading the account until its status changes is not a notification model.
