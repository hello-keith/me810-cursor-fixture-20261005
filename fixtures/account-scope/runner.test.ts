import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { AccountScopeError, accountScopeHeaders } from './account-scope.ts';
import { type Corpus, sdkClient, startLoopback } from './runner.ts';

const here = import.meta.dirname;
const corpus = JSON.parse(readFileSync(join(here, 'vectors.json'), 'utf8')) as Corpus;

// Runs the real runner CLI against a corpus in which one vector's expectation
// has been corrupted, so the failure must come from observed SDK traffic.
function runWithCorruptedVector(id: string, expected: Corpus['vectors'][number]['expected']) {
  const vector = corpus.vectors.find((candidate) => candidate.id === id);
  assert.ok(vector, `corpus has no vector ${id}`);
  const corrupted = { ...corpus, vectors: corpus.vectors.map((candidate) => (candidate.id === id ? { ...candidate, expected } : candidate)) };
  const dir = mkdtempSync(join(tmpdir(), 'account-scope-negative-'));
  try {
    const path = join(dir, 'vectors.json');
    writeFileSync(path, JSON.stringify(corrupted));
    return spawnSync(process.execPath, [join(here, 'runner.ts'), '--vectors', path], { encoding: 'utf8' });
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test('the published SDK passes the full corpus through the reference preflight', () => {
  const run = spawnSync(process.execPath, [join(here, 'runner.ts')], { encoding: 'utf8' });
  assert.equal(run.status, 0, run.stderr);
  assert.match(run.stdout, /^PASS 840 vectors and 9 scenarios: @straddlecom\/straddle 1\.0\.4 against contract 1\.0\.4 /);
});

test('a wrong acting-account value fails the run and names the vector', () => {
  const { A } = corpus.accounts;
  // The per-call account B overrides selected account A, so the SDK really sends B.
  const run = runWithCorruptedVector('marketplace.createCharge.selected-a-explicit-b', {
    outcome: 'request',
    header: 'present',
    value: A,
    outbound_requests: 1,
  });
  assert.equal(run.status, 1);
  assert.match(run.stderr, /FAIL marketplace\.createCharge\.selected-a-explicit-b \[marketplace POST \/v1\/charges policy=require;/);
  assert.match(run.stderr, /Straddle-Account-Id was "00000000-0000-4000-8000-00000000000b"/);
  assert.match(run.stderr, /^1 failure\(s\)/m);
});

test('an outbound request where missing scope must stop the call fails the run', () => {
  // getCharge is allow-scoped for SaaS, so without an account the SDK really
  // sends one unscoped request; the corrupted vector claims zero.
  const run = runWithCorruptedVector('saas.getCharge.no-account', {
    outcome: 'local_rejection',
    reason: 'required',
    outbound_requests: 0,
  });
  assert.equal(run.status, 1);
  assert.match(run.stderr, /FAIL saas\.getCharge\.no-account \[saas GET \/v1\/charges\/\{id\} policy=allow;[^\n]*\]: expected 0 outbound request\(s\), observed 1/);
});

test('the SDK transport sends an unscoped charge; only the preflight stops it', async () => {
  const loopback = await startLoopback();
  try {
    const client = sdkClient(loopback, 'fixture-credential-x');
    const createCharge = corpus.operations.find((operation) => operation.id === 'createCharge');
    assert.ok(createCharge);

    // Body fields are irrelevant here: the SDK does not validate them at runtime.
    await client.charges.create({} as never);
    assert.equal(loopback.requests.length, 1);
    assert.equal(loopback.requests[0]?.headers['straddle-account-id'], undefined);

    assert.throws(
      () => accountScopeHeaders('marketplace', createCharge, {}),
      (error) => error instanceof AccountScopeError && error.reason === 'required',
    );
    assert.equal(loopback.requests.length, 1);
  } finally {
    await loopback.close();
  }
});
