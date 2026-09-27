// Reference application preflight for Straddle-Account-Id.
//
// The generated SDK is only a transport: every header-capable method sends
// Straddle-Account-Id exactly when the caller passes it and never knows the
// platform's integration type. Deciding whether an operation must, may, or must
// not carry an acting account is application policy (build plan section 6), so
// an application needs this small boundary in front of the SDK. It mirrors the
// straddle-cli internal/straddleacct Classify and Resolve rules and is checked
// against vectors.json, which is generated from that CLI code; it is not a
// second source of policy.

export const ACCOUNT_HEADER = 'Straddle-Account-Id';

export type IntegrationType = 'direct' | 'saas' | 'marketplace';
export type ScopeDecision = 'forbid' | 'require' | 'allow';
export type ScopeHeaders = { 'Straddle-Account-Id'?: string };

export interface Operation {
  id: string;
  method: string;
  path: string;
}

// `selected` is the session's current acting account. `explicit` is a per-call
// override that wins whenever it is supplied, matching the CLI's --account flag.
export interface ActingAccount {
  selected?: string | undefined;
  explicit?: string | undefined;
}

export class AccountScopeError extends Error {
  readonly reason: 'required' | 'forbidden';
  readonly operation: string;

  constructor(reason: 'required' | 'forbidden', operation: Operation) {
    super(
      reason === 'required'
        ? `${operation.id} acts on behalf of an embedded account; select an acting account before calling it`
        : `${operation.id} does not act on behalf of an embedded account; remove the explicit acting account`,
    );
    this.name = 'AccountScopeError';
    this.reason = reason;
    this.operation = operation.id;
  }
}

// Resources whose operations declare Straddle-Account-Id in contract 1.0.4.
// Organization and account-management resources are absent, so they always
// omit the header.
const headerCapableResources: Record<string, true> = {
  bridge: true,
  charges: true,
  customers: true,
  funding_event_payments: true,
  funding_events: true,
  paykeys: true,
  payments: true,
  payouts: true,
};

// A marketplace owns its customers and their paykeys; they are never scoped to
// an embedded account.
const marketplacePlatformResources: Record<string, true> = { customers: true, paykeys: true, bridge: true };

// A SaaS platform must attribute creation of these resources to an account.
const saasCreateScopedResources: Record<string, true> = {
  charges: true,
  payouts: true,
  customers: true,
  paykeys: true,
  bridge: true,
};

function resourceOf(path: string): string {
  const segments = path.split('/').filter(Boolean);
  const version = segments.indexOf('v1');
  return version >= 0 ? (segments[version + 1] ?? '') : '';
}

export function accountScopeDecision(integration: IntegrationType, operation: Operation): ScopeDecision {
  const resource = resourceOf(operation.path);
  if (headerCapableResources[resource] !== true) return 'forbid';
  const isPost = operation.method.toUpperCase() === 'POST';
  switch (integration) {
    case 'direct':
      return 'forbid';
    case 'marketplace':
      if (marketplacePlatformResources[resource] === true) return 'forbid';
      return isPost && (resource === 'charges' || resource === 'payouts') ? 'require' : 'allow';
    case 'saas':
      return isPost && saasCreateScopedResources[resource] === true ? 'require' : 'allow';
    default:
      throw new TypeError(`unknown integration type ${JSON.stringify(integration)}`);
  }
}

// Returns the header params to spread into the SDK call, or throws
// AccountScopeError before any request exists.
export function accountScopeHeaders(
  integration: IntegrationType,
  operation: Operation,
  account: ActingAccount,
): ScopeHeaders {
  const decision = accountScopeDecision(integration, operation);
  const effective = account.explicit !== undefined ? account.explicit : account.selected;
  if (decision === 'forbid') {
    if (account.explicit) throw new AccountScopeError('forbidden', operation);
    return {};
  }
  if (!effective) {
    if (decision === 'require') throw new AccountScopeError('required', operation);
    return {};
  }
  return { [ACCOUNT_HEADER]: effective };
}
