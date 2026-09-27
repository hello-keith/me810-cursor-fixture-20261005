// Regenerates vectors.json from a clean straddle-cli checkout, or with --check
// proves the committed file is exactly what that checkout produces.
//
//   node derive.ts --cli ../../../straddle-cli [--check]
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { parseArgs } from 'node:util';

const here = import.meta.dirname;
const vectorsPath = join(here, 'vectors.json');

const { values } = parseArgs({ options: { cli: { type: 'string' }, check: { type: 'boolean', default: false } } });
if (!values.cli) {
  console.error('usage: node derive.ts --cli <straddle-cli checkout> [--check]');
  process.exit(2);
}
const cli = resolve(values.cli);

const git = (...args: string[]) => execFileSync('git', ['-C', cli, ...args], { encoding: 'utf8' }).trim();
if (git('status', '--porcelain') !== '') {
  console.error(`${cli} has uncommitted changes; derive from a clean commit so provenance is exact`);
  process.exit(1);
}
const commit = git('rev-parse', 'HEAD');

const scratch = mkdtempSync(join(tmpdir(), 'account-scope-derive-'));
try {
  const overlay = join(scratch, 'overlay.json');
  const out = join(scratch, 'vectors.json');
  writeFileSync(
    overlay,
    JSON.stringify({
      Replace: {
        [join(cli, 'internal/straddleacct/zz_account_scope_corpus_test.go')]: join(here, 'derive/export_corpus_test.go'),
      },
    }),
  );
  execFileSync(
    'go',
    ['test', '-overlay', overlay, '-count=1', '-run', '^TestExportAccountScopeCorpus$', './internal/straddleacct'],
    {
      cwd: cli,
      stdio: ['ignore', 'inherit', 'inherit'],
      env: { ...process.env, ACCOUNT_SCOPE_CORPUS_OUT: out, ACCOUNT_SCOPE_CLI_COMMIT: commit },
    },
  );
  const generated = readFileSync(out, 'utf8');
  if (values.check) {
    if (readFileSync(vectorsPath, 'utf8') !== generated) {
      console.error(`vectors.json differs from straddle-cli ${commit}; run node derive.ts --cli ${values.cli}`);
      process.exit(1);
    }
    console.log(`vectors.json matches straddle-cli ${commit}`);
  } else {
    writeFileSync(vectorsPath, generated);
    console.log(`wrote vectors.json from straddle-cli ${commit}`);
  }
} finally {
  rmSync(scratch, { recursive: true, force: true });
}
