import fs from 'node:fs';
import { execSync } from 'node:child_process';
import { describe, it, expect } from 'vitest';

describe('geo markdown reporter', () => {
  it('generates markdown file with badges', () => {
    execSync('node scripts/geo/metrics.mjs');
    execSync('node scripts/geo/doctor.mjs');
    execSync('node scripts/geo/diff.mjs');
    execSync('node scripts/geo/report-md.mjs');
    const md = fs.readFileSync('__ai/geo-report.md','utf8');
    expect(md).toMatch(/Geo Report/);
    expect(md).toMatch(/Components/);
    expect(md).toMatch(/Symmetry/);
  });
});