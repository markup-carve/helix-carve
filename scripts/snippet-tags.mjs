import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, unlinkSync, rmdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const dir = mkdtempSync(join(tmpdir(), 'carve-snippet-tags-'));
const sample = join(dir, 'snippet.crv');
const query = resolve(dirname(fileURLToPath(import.meta.url)), '../runtime/queries/carve/tags.scm');
writeFileSync(sample, '{$ver}: 0.2.3\n\nUse {{ $ver }}.\n');

try {
  const cli = (process.env.TS_CLI ?? 'tree-sitter').split(' ').filter(Boolean);
  const config = process.env.TS_CONFIG_PATH ? ['--scope', 'text.carve', '--config-path', process.env.TS_CONFIG_PATH] : [];
  const result = spawnSync(cli[0], [...cli.slice(1), 'query', ...config, '--captures', query, sample], {
    cwd: process.env.TS_CWD || process.cwd(), encoding: 'utf8',
  });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /definition\.constant, start: \(0, 0\)/);
  assert.match(result.stdout, /reference\.class, start: \(2, 4\)/);
  assert.equal((result.stdout.match(/ - name, .*text: `ver`/g) ?? []).length, 2);
  console.log('snippet definition and use tags passed');
} finally {
  unlinkSync(sample);
  rmdirSync(dir);
}
