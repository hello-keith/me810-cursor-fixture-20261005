// TypeScript reference runner for the shared account-scope corpus.
//
// Every vector goes through accountScopeHeaders (the application preflight)
// and then the published @straddlecom/straddle client, whose real fetch-based
// request layer talks to a loopback HTTP server that records each request. No
// Straddle API, credential or network beyond 127.0.0.1 is involved.
//
//   node runner.ts [--vectors vectors.json]
//
// Exits 0 when every vector and scenario matches, 1 with one line per failing
// vector or scenario step otherwise.
import { readFileSync } from 'node:fs';
import { createServer, type IncomingHttpHeaders } from 'node:http';
import type { AddressInfo } from 'node:net';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';
import StraddleAPI from '@straddlecom/straddle';
import {
  ACCOUNT_HEADER,
  AccountScopeError,
  accountScopeHeaders,
  type IntegrationType,
  type Operation,
  type ScopeHeaders,
} from './account-scope.ts';

export const SDK_PACKAGE = '@straddlecom/straddle';
export const SDK_VERSION = '1.0.4';

interface Expectation {
  outcome: 'request' | 'local_rejection';
  header?: 'present' | 'absent';
  value?: string;
  reason?: 'required' | 'forbidden';
  outbound_requests: number;
}

interface Vector {
  id: string;
  integration_type: IntegrationType;
  operation: string;
  policy: string;
  acting_account: { selected: string | null; explicit: string | null };
  expected: Expectation;
}

type Step =
  | { action: 'select'; account?: string }
  | { action: 'call'; operation: string; explicit?: string; expected: Expectation };

interface Caller {
  name: string;
  credential: string;
  selected: string | null;
  expected: Expectation;
}

interface Scenario {
  id: string;
  kind: 'sequence' | 'concurrent';
  integration_type: IntegrationType;
  steps?: Step[];
  operation?: string;
  calls_per_caller?: number;
  min_in_flight?: number;
  callers?: Caller[];
}

export interface Corpus {
  schema_version: number;
  header: string;
  accounts: { A: string; B: string };
  contract: { contract_version: string; registry_ref: string; published_sha256: string };
  operations: (Operation & { resource: string; accepts_account_header: boolean })[];
  vectors: Vector[];
  scenarios: Scenario[];
}

interface RecordedRequest {
  method: string;
  path: string;
  headers: IncomingHttpHeaders;
}

// Synthetic path identifier; the loopback server never interprets it.
const RESOURCE_ID = '00000000-0000-4000-8000-0000000000f1';

// Params come from the corpus at runtime, so they are deliberately untyped;
// the resource and method names are still checked by the compiler.
type Params = any;
type Invoke = (client: StraddleAPI, params: Params) => Promise<unknown>;

const authorizationProof = new File(['%PDF-1.4 synthetic fixture'], 'authorization.pdf', { type: 'application/pdf' });

// One binding per contract operation ID. Other SDK runners keep the same keys.
export const bindings: Record<string, Invoke> = {
  getAccountSettings: (c, p) => c.accountSettings.retrieve(RESOURCE_ID, p),
  listAccounts: (c, p) => c.accounts.list(p),
  createAccount: (c, p) => c.accounts.create(p),
  getAccount: (c, p) => c.accounts.retrieve(RESOURCE_ID, p),
  updateAccount: (c, p) => c.accounts.update(RESOURCE_ID, p),
  listCapabilityRequests: (c, p) => c.capabilityRequests.list(RESOURCE_ID, p),
  createCapabilityRequest: (c, p) => c.capabilityRequests.create(RESOURCE_ID, p),
  onboardAccount: (c, p) => c.accounts.onboard(RESOURCE_ID, p),
  simulateAccountOnboarding: (c, p) => c.accounts.simulateOnboarding(RESOURCE_ID, p),
  createBankAccountPaykey: (c, p) => c.bridge.createBankAccountPaykey(p),
  createBridgeToken: (c, p) => c.bridge.createToken(p),
  createPlaidPaykey: (c, p) => c.bridge.createPlaidPaykey(p),
  createQuilttPaykey: (c, p) => c.bridge.createQuilttPaykey(p),
  createCharge: (c, p) => c.charges.create(p),
  getCharge: (c, p) => c.charges.retrieve(RESOURCE_ID, p),
  updateCharge: (c, p) => c.charges.update(RESOURCE_ID, p),
  uploadChargeAuthorizationProof: (c, p) => c.charges.uploadAuthorizationProof(RESOURCE_ID, { ...p, File: authorizationProof }),
  cancelCharge: (c, p) => c.charges.cancel(RESOURCE_ID, p),
  holdCharge: (c, p) => c.charges.hold(RESOURCE_ID, p),
  refundCharge: (c, p) => c.charges.refund(RESOURCE_ID, p),
  releaseCharge: (c, p) => c.charges.release(RESOURCE_ID, p),
  resubmitCharge: (c, p) => c.charges.resubmit(RESOURCE_ID, p),
  getUnmaskedCharge: (c, p) => c.charges.listUnmasked(RESOURCE_ID, p),
  listCustomers: (c, p) => c.customers.list(p),
  createCustomer: (c, p) => c.customers.create(p),
  deleteCustomer: (c, p) => c.customers.delete(RESOURCE_ID, p),
  getCustomer: (c, p) => c.customers.retrieve(RESOURCE_ID, p),
  updateCustomer: (c, p) => c.customers.update(RESOURCE_ID, p),
  refreshCustomerReview: (c, p) => c.customers.refreshReview(RESOURCE_ID, p),
  getCustomerReview: (c, p) => c.customers.review.list(RESOURCE_ID, p),
  setCustomerVerificationDecision: (c, p) => c.customers.review.setVerificationDecision(RESOURCE_ID, p),
  getUnmaskedCustomer: (c, p) => c.customers.listUnmasked(RESOURCE_ID, p),
  listFundingEventPayments: (c, p) => c.fundingEvents.listPayments(RESOURCE_ID, p),
  listFundingEvents: (c, p) => c.fundingEvents.list(p),
  simulateFundingEvent: (c, p) => c.fundingEvents.simulate(p),
  getFundingEvent: (c, p) => c.fundingEvents.retrieve(RESOURCE_ID, p),
  listLinkedBankAccounts: (c, p) => c.linkedBankAccounts.list(p),
  createLinkedBankAccount: (c, p) => c.linkedBankAccounts.create(p),
  getLinkedBankAccount: (c, p) => c.linkedBankAccounts.retrieve(RESOURCE_ID, p),
  updateLinkedBankAccount: (c, p) => c.linkedBankAccounts.update(RESOURCE_ID, p),
  cancelLinkedBankAccount: (c, p) => c.linkedBankAccounts.cancel(RESOURCE_ID, p),
  getUnmaskedLinkedBankAccount: (c, p) => c.linkedBankAccounts.listUnmasked(RESOURCE_ID, p),
  listOrganizations: (c, p) => c.organizations.list(p),
  createOrganization: (c, p) => c.organizations.create(p),
  getOrganization: (c, p) => c.organizations.retrieve(RESOURCE_ID, p),
  listPaykeys: (c, p) => c.paykeys.list(p),
  getPaykey: (c, p) => c.paykeys.retrieve(RESOURCE_ID, p),
  cancelPaykey: (c, p) => c.paykeys.cancel(RESOURCE_ID, p),
  refreshPaykeyBalance: (c, p) => c.paykeys.refreshBalance(RESOURCE_ID, p),
  refreshPaykeyReview: (c, p) => c.paykeys.refreshReview(RESOURCE_ID, p),
  revealPaykey: (c, p) => c.paykeys.reveal(RESOURCE_ID, p),
  getPaykeyReview: (c, p) => c.paykeys.review.list(RESOURCE_ID, p),
  setPaykeyVerificationDecision: (c, p) => c.paykeys.review.setVerificationDecision(RESOURCE_ID, p),
  unblockPaykey: (c, p) => c.paykeys.unblock(RESOURCE_ID, p),
  getUnmaskedPaykey: (c, p) => c.paykeys.listUnmasked(RESOURCE_ID, p),
  listPayments: (c, p) => c.payments.list(p),
  createPayout: (c, p) => c.payouts.create(p),
  getPayout: (c, p) => c.payouts.retrieve(RESOURCE_ID, p),
  updatePayout: (c, p) => c.payouts.update(RESOURCE_ID, p),
  uploadPayoutAuthorizationProof: (c, p) => c.payouts.uploadAuthorizationProof(RESOURCE_ID, { ...p, File: authorizationProof }),
  cancelPayout: (c, p) => c.payouts.cancel(RESOURCE_ID, p),
  holdPayout: (c, p) => c.payouts.hold(RESOURCE_ID, p),
  releasePayout: (c, p) => c.payouts.release(RESOURCE_ID, p),
  resubmitPayout: (c, p) => c.payouts.resubmit(RESOURCE_ID, p),
  getUnmaskedPayout: (c, p) => c.payouts.listUnmasked(RESOURCE_ID, p),
  listRepresentatives: (c, p) => c.representatives.list(p),
  createRepresentative: (c, p) => c.representatives.create(p),
  getRepresentative: (c, p) => c.representatives.retrieve(RESOURCE_ID, p),
  updateRepresentative: (c, p) => c.representatives.update(RESOURCE_ID, p),
  getUnmaskedRepresentative: (c, p) => c.representatives.listUnmasked(RESOURCE_ID, p),
};

export interface Loopback {
  baseURL: string;
  requests: RecordedRequest[];
  maxInFlight: number;
  resetInFlight(): void;
  setResponseDelayMs(ms: number): void;
  close(): Promise<void>;
}

// Records each request when it arrives, then answers 200 after an optional
// delay so concurrent scenarios genuinely overlap on the wire.
export async function startLoopback(): Promise<Loopback> {
  const requests: RecordedRequest[] = [];
  let inFlight = 0;
  let responseDelayMs = 0;
  const state = { maxInFlight: 0 };
  const server = createServer((req, res) => {
    requests.push({ method: req.method ?? '', path: new URL(req.url ?? '/', 'http://loopback').pathname, headers: req.headers });
    inFlight += 1;
    state.maxInFlight = Math.max(state.maxInFlight, inFlight);
    req.resume();
    req.on('end', () => {
      setTimeout(() => {
        res.writeHead(200, { 'content-type': 'application/json' });
        res.end('{"data":{},"meta":{"api_request_id":"loopback"},"response_type":"object"}');
        inFlight -= 1;
      }, responseDelayMs);
    });
  });
  await new Promise<void>((done) => server.listen(0, '127.0.0.1', done));
  const { port } = server.address() as AddressInfo;
  return {
    baseURL: `http://127.0.0.1:${port}`,
    requests,
    get maxInFlight() {
      return state.maxInFlight;
    },
    resetInFlight() {
      state.maxInFlight = 0;
    },
    setResponseDelayMs(ms: number) {
      responseDelayMs = ms;
    },
    close: () => new Promise<void>((done, fail) => server.close((error) => (error ? fail(error) : done()))),
  };
}

export function sdkClient(loopback: Loopback, credential: string): StraddleAPI {
  // Every option that could reach a real host or hide a duplicate request is explicit.
  return new StraddleAPI({ bearer: credential, baseURL: loopback.baseURL, maxRetries: 0, timeout: 5_000, logLevel: 'off' });
}

function describe(expected: Expectation): string {
  if (expected.outcome === 'local_rejection') return `local rejection (${expected.reason}) with 0 outbound requests`;
  return expected.header === 'present'
    ? `1 request with ${ACCOUNT_HEADER}: ${expected.value}`
    : `1 request without ${ACCOUNT_HEADER}`;
}

type Observed = { outcome: 'request' } | { outcome: 'local_rejection'; reason: string } | { outcome: 'error'; message: string };

// Runs one preflight + SDK call and returns every mismatch against `expected`.
async function check(
  loopback: Loopback,
  client: StraddleAPI,
  integration: IntegrationType,
  operation: Operation,
  account: { selected?: string | undefined; explicit?: string | undefined },
  expected: Expectation,
  extraParams: Record<string, string> = {},
): Promise<string[]> {
  const before = loopback.requests.length;
  let observed: Observed;
  try {
    const headers: ScopeHeaders = accountScopeHeaders(integration, operation, account);
    const invoke = bindings[operation.id];
    if (!invoke) return [`no SDK binding for operation ${operation.id}`];
    await invoke(client, { ...headers, ...extraParams });
    observed = { outcome: 'request' };
  } catch (error) {
    observed =
      error instanceof AccountScopeError
        ? { outcome: 'local_rejection', reason: error.reason }
        : { outcome: 'error', message: error instanceof Error ? error.message : String(error) };
  }
  const sent = loopback.requests.slice(before);
  const problems: string[] = [];
  if (observed.outcome === 'error') problems.push(`SDK call failed: ${observed.message}`);
  if (sent.length !== expected.outbound_requests) {
    problems.push(`expected ${expected.outbound_requests} outbound request(s), observed ${sent.length}`);
  }
  if (expected.outcome === 'local_rejection') {
    if (observed.outcome !== 'local_rejection') problems.push('expected a local rejection, but the preflight allowed the call');
    else if (observed.reason !== expected.reason) problems.push(`expected rejection reason ${expected.reason}, observed ${observed.reason}`);
    return problems;
  }
  if (observed.outcome === 'local_rejection') {
    problems.push(`preflight rejected the call locally (${observed.reason})`);
    return problems;
  }
  const request = sent[0];
  if (!request) return problems;
  const pathPattern = new RegExp(`^${operation.path.replace(/\{[^}]+\}/g, '[^/]+')}$`);
  if (request.method !== operation.method || !pathPattern.test(request.path)) {
    problems.push(`SDK sent ${request.method} ${request.path}, not ${operation.method} ${operation.path}`);
  }
  const actual = request.headers[ACCOUNT_HEADER.toLowerCase()];
  if (expected.header === 'absent' && actual !== undefined) problems.push(`${ACCOUNT_HEADER} was sent as ${JSON.stringify(actual)}`);
  if (expected.header === 'present' && actual !== expected.value) {
    problems.push(actual === undefined ? `${ACCOUNT_HEADER} was absent` : `${ACCOUNT_HEADER} was ${JSON.stringify(actual)}`);
  }
  return problems;
}

async function runScenario(
  loopback: Loopback,
  scenario: Scenario,
  operations: Map<string, Operation>,
  report: (id: string, problems: string[], context: string) => void,
): Promise<void> {
  const integration = scenario.integration_type;
  if (scenario.kind === 'sequence') {
    const client = sdkClient(loopback, 'fixture-credential-x');
    let selected: string | undefined;
    for (const [index, step] of (scenario.steps ?? []).entries()) {
      if (step.action === 'select') {
        selected = step.account;
        continue;
      }
      const operation = operations.get(step.operation);
      const id = `${scenario.id}#${index}`;
      if (!operation) {
        report(id, [`unknown operation ${step.operation}`], integration);
        continue;
      }
      const problems = await check(loopback, client, integration, operation, { selected, explicit: step.explicit }, step.expected);
      report(id, problems, `${integration} ${operation.id}; expected ${describe(step.expected)}`);
    }
    return;
  }

  const operation = operations.get(scenario.operation ?? '');
  const callers = scenario.callers ?? [];
  const calls = scenario.calls_per_caller ?? 0;
  if (!operation || callers.length === 0 || calls === 0) {
    report(scenario.id, ['concurrent scenario is missing operation, callers or calls_per_caller'], integration);
    return;
  }
  const clients = new Map<string, StraddleAPI>();
  for (const caller of callers) {
    if (!clients.has(caller.credential)) clients.set(caller.credential, sdkClient(loopback, caller.credential));
  }
  const before = loopback.requests.length;
  loopback.resetInFlight();
  loopback.setResponseDelayMs(25);
  const rejections = new Map<string, number>(callers.map((caller) => [caller.name, 0]));
  const pending: Promise<void>[] = [];
  for (let n = 0; n < calls; n += 1) {
    for (const caller of callers) {
      const client = clients.get(caller.credential) as StraddleAPI;
      pending.push(
        (async () => {
          try {
            const headers = accountScopeHeaders(integration, operation, { selected: caller.selected ?? undefined });
            await (bindings[operation.id] as Invoke)(client, { ...headers, 'Request-Id': `${caller.name}-${n}` });
          } catch (error) {
            if (!(error instanceof AccountScopeError)) throw error;
            rejections.set(caller.name, (rejections.get(caller.name) ?? 0) + 1);
          }
        })(),
      );
    }
  }
  const settled = await Promise.allSettled(pending);
  loopback.setResponseDelayMs(0);
  const failures = settled.flatMap((result) => (result.status === 'rejected' ? [String(result.reason)] : []));
  if (failures.length > 0) report(scenario.id, failures.map((failure) => `SDK call failed: ${failure}`), integration);

  const sent = loopback.requests.slice(before);
  if (loopback.maxInFlight < (scenario.min_in_flight ?? 1)) {
    report(scenario.id, [`only ${loopback.maxInFlight} request(s) were in flight at once, want ${scenario.min_in_flight}`], integration);
  }
  for (const caller of callers) {
    const mine = sent.filter((request) => String(request.headers['request-id']).startsWith(`${caller.name}-`));
    const problems: string[] = [];
    const wantRequests = caller.expected.outbound_requests * calls;
    if (mine.length !== wantRequests) problems.push(`expected ${wantRequests} outbound request(s), observed ${mine.length}`);
    const wantRejections = caller.expected.outcome === 'local_rejection' ? calls : 0;
    if (rejections.get(caller.name) !== wantRejections) {
      problems.push(`expected ${wantRejections} local rejection(s), observed ${rejections.get(caller.name)}`);
    }
    for (const request of mine) {
      const actual = request.headers[ACCOUNT_HEADER.toLowerCase()];
      const want = caller.expected.header === 'present' ? caller.expected.value : undefined;
      if (actual !== want) problems.push(`${request.headers['request-id']} carried ${ACCOUNT_HEADER} ${JSON.stringify(actual)}, want ${JSON.stringify(want)}`);
      if (request.headers.authorization !== `Bearer ${caller.credential}`) {
        problems.push(`${request.headers['request-id']} carried another caller's credential`);
      }
    }
    report(`${scenario.id}/${caller.name}`, problems, `${integration} ${operation.id} x${calls}; expected ${describe(caller.expected)} each`);
  }
}

export interface RunResult {
  vectors: number;
  scenarios: number;
  failures: string[];
}

export async function runCorpus(corpus: Corpus): Promise<RunResult> {
  const failures: string[] = [];
  const report = (id: string, problems: string[], context: string) => {
    for (const problem of problems) failures.push(`FAIL ${id} [${context}]: ${problem}`);
  };

  if (corpus.schema_version !== 1) failures.push(`FAIL corpus: unsupported schema_version ${corpus.schema_version}`);
  if (corpus.header !== ACCOUNT_HEADER) failures.push(`FAIL corpus: header is ${corpus.header}, runner checks ${ACCOUNT_HEADER}`);
  const operations = new Map(corpus.operations.map((operation) => [operation.id, operation]));
  for (const id of operations.keys()) if (!bindings[id]) failures.push(`FAIL corpus: operation ${id} has no SDK binding`);
  for (const id of Object.keys(bindings)) if (!operations.has(id)) failures.push(`FAIL corpus: SDK binding ${id} is not a corpus operation`);
  if (failures.length > 0) return { vectors: 0, scenarios: 0, failures };

  const loopback = await startLoopback();
  try {
    const client = sdkClient(loopback, 'fixture-credential-x');
    for (const vector of corpus.vectors) {
      const operation = operations.get(vector.operation);
      if (!operation) {
        report(vector.id, [`unknown operation ${vector.operation}`], vector.integration_type);
        continue;
      }
      const account = {
        selected: vector.acting_account.selected ?? undefined,
        explicit: vector.acting_account.explicit ?? undefined,
      };
      const problems = await check(loopback, client, vector.integration_type, operation, account, vector.expected);
      report(
        vector.id,
        problems,
        `${vector.integration_type} ${operation.method} ${operation.path} policy=${vector.policy}; expected ${describe(vector.expected)}`,
      );
    }
    for (const scenario of corpus.scenarios) await runScenario(loopback, scenario, operations, report);
  } finally {
    await loopback.close();
  }
  return { vectors: corpus.vectors.length, scenarios: corpus.scenarios.length, failures };
}

async function main(): Promise<number> {
  const { values } = parseArgs({ options: { vectors: { type: 'string', default: join(import.meta.dirname, 'vectors.json') } } });
  const manifest = join(import.meta.dirname, 'node_modules', SDK_PACKAGE, 'package.json');
  const installed = (JSON.parse(readFileSync(manifest, 'utf8')) as { version: string }).version;
  if (installed !== SDK_VERSION) {
    console.error(`FAIL sdk: installed ${SDK_PACKAGE} ${installed}, runner is qualified for ${SDK_VERSION}`);
    return 1;
  }
  const corpus = JSON.parse(readFileSync(resolve(values.vectors), 'utf8')) as Corpus;
  const result = await runCorpus(corpus);
  const subject = `${SDK_PACKAGE} ${installed} against contract ${corpus.contract.contract_version} (${corpus.contract.published_sha256})`;
  if (result.failures.length > 0) {
    for (const failure of result.failures) console.error(failure);
    console.error(`${result.failures.length} failure(s) running ${subject}`);
    return 1;
  }
  console.log(`PASS ${result.vectors} vectors and ${result.scenarios} scenarios: ${subject}`);
  return 0;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  process.exitCode = await main();
}
