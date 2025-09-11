#!/usr/bin/env node
/**
 * Flexible Repo Doctor – Common‑Ground Scanner & Fixer
 * ----------------------------------------------------
 * Purpose: Find cross‑cutting patterns behind your current error set and
 *          steer fixes that unblock multiple issues at once. Optionally auto‑fix.
 *
 * Usage:
 *   node scripts/flexible-repo-doctor.mjs           # scan only
 *   node scripts/flexible-repo-doctor.mjs --fix     # apply safe fixes
 *   node scripts/flexible-repo-doctor.mjs --json    # machine‑readable report
 *   node scripts/flexible-repo-doctor.mjs --fix --json > report.json
 *
 * What it targets (common ground heuristics):
 *  A) JSON‑LD scripts missing `is:inline` in .astro
 *  B) Illegal re‑export syntax like:  export '.../Component.astro';
 *  C) FAQ shape drift (q/a vs question/answer) + missing normalizer
 *  D) Slug/text helpers scattered/missing (slugify, normSlug, unslugToName)
 *  E) Stray `server:defer` attribute on HTML nodes in .astro files
 *  F) `.ts` extension imports within pages that trigger tsconfig errors
 *  G) DevDeps required by tests but missing (e.g. @axe-core/playwright, postcss-selector-parser)
 *
 * Notes:
 * - Fixes are conservative (idempotent). We only modify when risk is low.
 * - For higher‑risk items, we emit an actionable suggestion and codeframe.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const cwd = process.cwd();

const args = new Set(process.argv.slice(2));
const APPLY_FIXES = args.has('--fix');
const OUTPUT_JSON = args.has('--json');

/** Small helpers */
const read = (p) => fs.readFileSync(p, 'utf8');
const write = (p, s) => fs.writeFileSync(p, s);
const exists = (p) => fs.existsSync(p);
const rel = (p) => path.relative(cwd, p).replace(/\\/g, '/');

function* walk(dir, filter = () => true) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) {
      // skip common heavy dirs
      if (/^(node_modules|.git|dist|.astro|.next|coverage)$/i.test(e.name)) continue;
      yield* walk(full, filter);
    } else if (e.isFile()) {
      if (filter(full)) yield full;
    }
  }
}

/** Report scaffold */
const report = {
  meta: {
    cwd,
    applyFixes: APPLY_FIXES,
    ts: new Date().toISOString(),
  },
  findings: [],
  summary: {},
  suggestions: [],
};

function addFinding(kind, file, message, details = {}) {
  report.findings.push({ kind, file: rel(file), message, ...details });
}
function addSuggestion(title, steps) {
  report.suggestions.push({ title, steps });
}

/** Detector A: JSON‑LD <script> missing is:inline */
function detectorJsonLdInline(file, src) {
  const rx = /<script(?![^>]*\bis:inline\b)[^>]*\btype\s*=\s*"application\/ld\+json"/gi;
  const hits = [...src.matchAll(rx)];
  if (!hits.length) return 0;
  if (APPLY_FIXES) {
    const fixed = src.replace(rx, (m) => m.replace('<script', '<script is:inline'));
    if (fixed !== src) write(file, fixed);
  }
  for (const h of hits) addFinding('jsonld_is_inline', file, 'JSON‑LD script missing is:inline');
  return hits.length;
}

/** Detector B: illegal re‑export syntax */
function detectorIllegalReExport(file, src) {
  const rx = /^\s*export\s+['"][^'"]+['"];\s*$/gm;
  const hits = [...src.matchAll(rx)];
  if (!hits.length) return 0;
  // We cannot auto‑fix safely without symbol names; emit guidance.
  for (const h of hits) addFinding('illegal_reexport', file, `Illegal re‑export: ${h[0].trim()}`);
  addSuggestion('Fix illegal re‑exports', [
    'Replace lines like:  export "…/Component.astro";  with  export { default as Name } from "…/Component.astro";',
    'Choose a stable exported symbol name (e.g., Component filename).',
  ]);
  return hits.length;
}

/** Detector C: FAQ shape drift & normalizer presence */
function detectorFaqShape(file, src) {
  // Heuristics: code reading q.q/q.a OR question/answer in same repo.
  const readsQA = /(\bq\s*\.\s*q\b|\bq\s*\.\s*a\b)/.test(src);
  const readsQuestionAnswer = /(\bquestion\s*[:\.]|\banswer\s*[:\.])/.test(src);
  if (!(readsQA || readsQuestionAnswer)) return 0;
  const utilPath = path.join(cwd, 'src/utils/text.ts');
  const typesPath = path.join(cwd, 'src/types/content.ts');

  // Check for normalizer existence
  let hasNormalizer = false;
  if (exists(typesPath)) {
    const tsrc = read(typesPath);
    hasNormalizer = /export\s+function\s+normalizeFaq\s*\(/.test(tsrc);
  }
  if (!hasNormalizer) {
    addFinding('faq_normalizer_missing', file, 'FAQ normalizer not found (normalizeFaq)');
    if (APPLY_FIXES) {
      // Create types/content.ts with normalizer only if file does not exist
      let payload = '';
      if (exists(typesPath)) {
        // append
        payload = read(typesPath);
        if (!/export\s+type\s+FaqQA\b/.test(payload)) {
          payload += `\nexport type FaqQA = { q: string; a: string };\n`;
        }
        payload += `\nexport function normalizeFaq(items: any): FaqQA[] {\n  if (!Array.isArray(items)) return [];\n  return items\n    .map((it: any) => {\n      if (it && typeof it.q === 'string' && typeof it.a === 'string') return it as FaqQA;\n      if (it && typeof it.question === 'string' && typeof it.answer === 'string') {\n        return { q: it.question, a: it.answer } as FaqQA;\n      }\n      return null;\n    })\n    .filter(Boolean) as FaqQA[];\n}\n`;
      } else {
        // create new file
        fs.mkdirSync(path.dirname(typesPath), { recursive: true });
        payload = `export type FaqQA = { q: string; a: string };\nexport function normalizeFaq(items: any): FaqQA[] {\n  if (!Array.isArray(items)) return [];\n  return items\n    .map((it: any) => {\n      if (it && typeof it.q === 'string' && typeof it.a === 'string') return it as FaqQA;\n      if (it && typeof it.question === 'string' && typeof it.answer === 'string') {\n        return { q: it.question, a: it.answer } as FaqQA;\n      }\n      return null;\n    })\n    .filter(Boolean) as FaqQA[];\n}\n`;
      }
      write(typesPath, payload);
    }
  }
  addSuggestion('Normalize FAQ once, render from normalized list', [
    'Import normalizeFaq from src/types/content.ts and wrap all topic.faq access',
    'Avoid direct q.q/q.a property access in templates',
  ]);
  return 1;
}

/** Detector D: slug/text helpers presence */
function detectorTextUtils() {
  const utilPath = path.join(cwd, 'src/utils/text.ts');
  if (exists(utilPath)) {
    const s = read(utilPath);
    const ok = /slugify\s*=|export\s+const\s+slugify/.test(s) && /unslugToName/.test(s);
    if (!ok) addFinding('text_utils_incomplete', utilPath, 'text utils present but missing slugify/unslugToName');
    return ok ? 0 : 1;
  }
  addFinding('text_utils_missing', utilPath, 'src/utils/text.ts does not exist');
  if (APPLY_FIXES) {
    fs.mkdirSync(path.dirname(utilPath), { recursive: true });
    write(utilPath, `export const slugify = (s: string) => String(s||'').normalize('NFKD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-+|-+$/g,'');\nexport const normSlug = (s: string) => slugify(s);\nexport const unslugToName = (s: string) => String(s||'').replace(/[-_]+/g,' ').replace(/\b\w/g, m => m.toUpperCase());\n`);
  }
  addSuggestion('Centralize slug/text helpers', [
    'Use src/utils/text.ts as single source for slugify/normSlug/unslugToName',
    'Normalize at I/O boundaries, compare on normalized forms internally',
  ]);
  return 1;
}

/** Detector E: stray server:defer on HTML nodes */
function detectorServerDefer(file, src) {
  // If server:defer appears in a non‑component tag (no angle after tagname), flag it.
  const rx = /<([a-z][a-z0-9-]*)\b[^>]*\bserver:defer\b/gi; // matches lowercase html tags
  const hits = [...src.matchAll(rx)];
  if (!hits.length) return 0;
  if (APPLY_FIXES) {
    const fixed = src.replace(/\s+server:defer\b/g, '');
    if (fixed !== src) write(file, fixed);
  }
  for (const h of hits) addFinding('server_defer_html', file, `server:defer on <${h[1]}>`);
  addSuggestion('Remove server:defer from HTML nodes', [
    'Use client:* directives when mounting components (e.g., client:idle)',
    'server:defer is not a valid HTML attribute',
  ]);
  return hits.length;
}

/** Detector F: .ts extension imports in pages */
function detectorTsExtImports(file, src) {
  if (!/\.(astro|tsx?)$/.test(file)) return 0;
  const rx = /\bimport\s+[^;]*from\s+["'][^"']+\.ts["'];/g;
  const hits = [...src.matchAll(rx)];
  if (!hits.length) return 0;
  for (const h of hits) addFinding('ts_extension_import', file, `Import with .ts extension: ${h[0].trim()}`);
  addSuggestion('Avoid .ts suffix in imports from pages', [
    'Use extensionless imports or enable allowImportingTsExtensions in tsconfig',
  ]);
  return hits.length;
}

/** Detector G: devDeps required by tests */
function detectorDevDeps() {
  const pkgPath = path.join(cwd, 'package.json');
  if (!exists(pkgPath)) return 0;
  const pkg = JSON.parse(read(pkgPath));
  const dev = new Set(Object.keys(pkg.devDependencies || {}));
  const need = [
    { name: '@axe-core/playwright', why: 'used by tests/e2e/a11y.spec.ts' },
    { name: 'postcss-selector-parser', why: 'used by tools/css-diff.ts' },
  ];
  let missing = 0;
  for (const { name, why } of need) {
    if (!dev.has(name)) {
      missing++;
      addFinding('devdep_missing', pkgPath, `${name} missing (${why})`);
    }
  }
  if (missing && APPLY_FIXES) {
    // non‑destructive: just add to pkg.json; leave install to the user/CI
    const ensure = (obj, k, v) => (obj[k] = obj[k] || v, obj);
    ensure(pkg, 'devDependencies', {});
    for (const { name } of need) pkg.devDependencies[name] = pkg.devDependencies[name] || 'latest';
    write(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
  }
  if (missing) {
    addSuggestion('Install missing devDependencies for tests', [
      'npm i -D @axe-core/playwright postcss-selector-parser',
    ]);
  }
  return missing;
}

/** Execute scan */
let counts = {
  jsonld_inline: 0,
  illegal_reexport: 0,
  faq_shape: 0,
  text_utils: 0,
  server_defer: 0,
  ts_ext_imports: 0,
  devdeps: 0,
};

for (const file of walk(cwd, (f) => /\.(astro|ts|tsx|js|mjs)$/.test(f))) {
  const src = read(file);
  if (file.endsWith('.astro')) {
    counts.jsonld_inline += detectorJsonLdInline(file, src);
    counts.server_defer += detectorServerDefer(file, src);
  }
  counts.illegal_reexport += detectorIllegalReExport(file, src);
  counts.faq_shape += detectorFaqShape(file, src);
  counts.ts_ext_imports += detectorTsExtImports(file, src);
}

counts.text_utils += detectorTextUtils();
counts.devdeps += detectorDevDeps();

report.summary = counts;

/** Output */
if (OUTPUT_JSON) {
  process.stdout.write(JSON.stringify(report, null, 2) + '\n');
} else {
  const lines = [];
  lines.push('Flexible Repo Doctor — results');
  lines.push('='.repeat(40));
  lines.push(`Directory : ${cwd}`);
  lines.push(`Fix mode  : ${APPLY_FIXES ? 'ON (safe fixes applied)' : 'OFF (scan only)'}`);
  lines.push('');
  lines.push('Summary:');
  for (const [k, v] of Object.entries(counts)) lines.push(`  - ${k}: ${v}`);
  lines.push('');
  if (report.findings.length) {
    lines.push('Findings:');
    for (const f of report.findings) lines.push(`  [${f.kind}] ${f.file} — ${f.message}`);
  } else {
    lines.push('No findings.');
  }
  lines.push('');
  if (report.suggestions.length) {
    lines.push('Suggestions:');
    for (const s of report.suggestions) {
      lines.push(`• ${s.title}`);
      for (const step of s.steps) lines.push(`  - ${step}`);
    }
  }
  process.stdout.write(lines.join('\n') + '\n');
}
