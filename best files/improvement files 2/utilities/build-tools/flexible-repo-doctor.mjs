#!/usr/bin/env node
/**
 * Flexible Repo Doctor — Phase 2
 *
 * Modes:
 *  - scan (default): detect legacy imports/usage and print a summary
 *  - --fix: apply safe fixes (tsconfig path remaps)
 *  - --compat: bootstrap compat layer files (stubs) in src/_compat/**
 *  - --json: output machine-readable JSON summary (to stdout)
 *  - --with-tsc: also run `tsc --noEmit` and correlate basic buckets (best-effort)
 *
 * No external installs; uses built-in modules.
 */
import fs from 'node:fs';
import path from 'node:path';
import child_process from 'node:child_process';

const ROOT = process.cwd();
const SRC = path.join(ROOT, 'src');

const ARGS = new Set(process.argv.slice(2));
const WANT_JSON = ARGS.has('--json');
const DO_FIX = ARGS.has('--fix') || ARGS.has('-f');
const DO_COMPAT = ARGS.has('--compat');
const WITH_TSC = ARGS.has('--with-tsc');

const LEGACY_IMPORTS = [
  '~/lib/clusters',
  '~/utils/internalLinks',
  '~/utils/services',
  '~/lib/geo/proximity',
  '~/lib/schema/builders',
];

const PATTERNS = {
  proximity: /\b(findNearbySuburbs|rankNearby|nearbyCovered)\b/g,
  faqRaw: /topic\.faq\s*\.(map|filter)/g,
  viewTransitions: /\bViewTransitions\b/g,
  tsImportWithExt: /from\s+['"][^'"]+\.ts['"]/g,
  domTyping: /\.(key|dataset|value|pointerId)\b/g,
  imageProps: /\b(formats|preload|fetchpriority)\s*=\s*[{"']/g,
};

function readText(fp) {
  try { return fs.readFileSync(fp, 'utf8'); } catch { return null; }
}

function listFiles(dir, exts = ['.ts', '.tsx', '.js', '.mjs', '.astro']) {
  const out = [];
  function walk(d) {
    for (const name of fs.readdirSync(d, { withFileTypes: true })) {
      if (name.isDirectory()) {
        if (name.name === 'node_modules' || name.name === 'dist' || name.name === '.astro') continue;
        walk(path.join(d, name.name));
      } else {
        const ext = path.extname(name.name);
        if (exts.includes(ext)) out.push(path.join(d, name.name));
      }
    }
  }
  walk(dir);
  return out;
}

function scan() {
  const files = listFiles(SRC);
  const results = {
    filesScanned: files.length,
    legacyImports: {},
    detectors: {
      proximity: [], faqRaw: [], viewTransitions: [], tsImportWithExt: [], domTyping: [], imageProps: [],
    },
  };
  for (const f of files) {
    const txt = readText(f);
    if (!txt) continue;
    for (const mod of LEGACY_IMPORTS) {
      if (txt.includes(mod)) {
        results.legacyImports[mod] ||= [];
        results.legacyImports[mod].push(path.relative(ROOT, f));
      }
    }
    for (const [k, rx] of Object.entries(PATTERNS)) {
      if (rx.test(txt)) {
        results.detectors[k].push(path.relative(ROOT, f));
      }
    }
  }
  return results;
}

function stripJsonComments(s) {
  return s.replace(/\/\/.*$/mg, '').replace(/\/\*[\s\S]*?\*\//g, '');
}

function ensureCompatPaths(tsconfigPath) {
  const raw = readText(tsconfigPath);
  if (!raw) throw new Error('tsconfig.json not found');
  const data = JSON.parse(stripJsonComments(raw));
  const paths = data.compilerOptions?.paths || (data.compilerOptions.paths = {});
  const deltas = [];
  const add = (from, to) => {
    if (!paths[from]) { paths[from] = [to]; deltas.push({ from, to }); }
  };
  add('~/lib/clusters', 'src/_compat/lib/clusters');
  add('~/utils/internalLinks', 'src/_compat/utils/internalLinks');
  add('~/utils/services', 'src/_compat/utils/services');
  add('~/lib/geo/proximity', 'src/_compat/lib/geo/proximity');
  add('~/lib/schema/builders', 'src/_compat/lib/schema/builders');
  if (deltas.length) {
    fs.writeFileSync(tsconfigPath, JSON.stringify(data, null, 2) + '\n');
  }
  return deltas;
}

function writeFileOnce(fp, content) {
  if (fs.existsSync(fp)) return false;
  fs.mkdirSync(path.dirname(fp), { recursive: true });
  fs.writeFileSync(fp, content);
  return true;
}

function bootstrapCompat() {
  const created = [];
  const banner = (name) => `/**\n * Compat shim for ${name}.\n * Temporary bridge—replace with real implementation.\n */\n`;

  // clusters
  created.push(writeFileOnce(
    path.join(SRC, '_compat/lib/clusters/index.ts'),
    banner('~/lib/clusters') + `
import areas from '@/content/areas.clusters.json';
import coverage from '@/data/serviceCoverage.json';

export type SuburbItem = { slug: string; name: string; cluster?: string };
type AreasDoc = { clusters: { slug: string; name: string; suburbs: string[] }[] };
const A = (areas as AreasDoc);

export const CANONICAL_CLUSTERS = Array.isArray(A?.clusters) ? A.clusters.map(c => c.slug) : ['ipswich','brisbane','logan'];

export function unslugToName(slug: string): string {
  return String(slug || '').replace(/[-_]+/g, ' ').replace(/\b\w/g, (m) => m.toUpperCase()).trim();
}

export function findClusterBySuburb(suburbSlug: string): string | null {
  for (const c of A.clusters || []) { if (c.suburbs?.some(s => s.toLowerCase() === suburbSlug.toLowerCase())) return c.slug; }
  return null;
}

export function getClusterForSuburbSync(suburbSlug: string) { return findClusterBySuburb(suburbSlug); }

export function listSuburbsForClusterSync(clusterSlug: string): string[] {
  const c = (A.clusters || []).find(c => c.slug === clusterSlug);
  return c?.suburbs?.map(s => s.toLowerCase()) || [];
}

export function findSuburbBySlug(slug: string): SuburbItem | null {
  const cl = findClusterBySuburb(slug);
  if (!cl) return null;
  return { slug, name: unslugToName(slug), cluster: cl };
}

export function getNearbySuburbs(suburbSlug: string, limit = 6): SuburbItem[] {
  const cl = findClusterBySuburb(suburbSlug);
  if (!cl) return [];
  return listSuburbsForClusterSync(cl)
    .filter(s => s !== suburbSlug)
    .slice(0, Math.max(0, limit))
    .map(s => ({ slug: s, name: unslugToName(s), cluster: cl }));
}

export function isCovered(service: string, suburb: string): boolean {
  const map = (coverage as Record<string, string[]>)[service] || [];
  return map.includes(suburb);
}
`
  ));

  // utils/internalLinks
  created.push(writeFileOnce(
    path.join(SRC, '_compat/utils/internalLinks/index.ts'),
    banner('~/utils/internalLinks') + `
import { unslugToName } from '@/_compat/lib/clusters';

export function getServiceLink(service: string, suburb: { slug?: string } | string): string {
  const sub = typeof suburb === 'string' ? suburb : (suburb?.slug || '');
  return "/services/" + service + "/" + sub + "/";
}

export function getLocalBlogLink(_suburb: string): string | null { return null; }
export function getRelatedServiceLinks(): Array<{ href: string; label: string }> { return []; }
export { unslugToName };
`
  ));

  // utils/services
  created.push(writeFileOnce(
    path.join(SRC, '_compat/utils/services/index.ts'),
    banner('~/utils/services') + `
import services from '@/data/services.json';

export type ServiceSlug = string;
export const SERVICES: Record<string, { key: string; name: string; summary?: string }> = Object.fromEntries(
  (services as any[]).map(s => [s.slug, { key: s.slug, name: s.title, summary: s.description }])
);

export const CROSS_SERVICES_FOR: Record<string, ServiceSlug[]> = {
  'bond-cleaning': ['spring-cleaning', 'bathroom-deep-clean'],
  'spring-cleaning': ['bond-cleaning', 'bathroom-deep-clean'],
  'bathroom-deep-clean': ['bond-cleaning', 'spring-cleaning']
};
`
  ));

  // lib/geo/proximity
  created.push(writeFileOnce(
    path.join(SRC, '_compat/lib/geo/proximity/index.ts'),
    banner('~/lib/geo/proximity') + `
import { getNearbySuburbs as _nearby } from '@/_compat/lib/clusters';

export function findNearbySuburbs(suburbSlug: string, opts: { limit?: number } = {}) {
  const limit = typeof opts.limit === 'number' ? opts.limit : 6;
  return _nearby(suburbSlug, limit);
}
`
  ));

  // lib/schema/builders
  created.push(writeFileOnce(
    path.join(SRC, '_compat/lib/schema/builders/index.ts'),
    banner('~/lib/schema/builders') + `
export function buildLocalBusiness(data: any) { return { '@type': 'LocalBusiness', ...data }; }
export function buildWebPage(data: any) { return { '@type': 'WebPage', ...data }; }
export function buildBreadcrumb(items: any[]) { return { '@type': 'BreadcrumbList', itemListElement: items }; }
export function buildFaq(items: Array<{ q: string; a: string }>) {
  return { '@type': 'FAQPage', mainEntity: items.map(i => ({ '@type': 'Question', name: i.q, acceptedAnswer: { '@type': 'Answer', text: i.a } })) };
}
`
  ));

  return created.filter(Boolean);
}

function runTsc() {
  try {
    const out = child_process.execSync('npx tsc --noEmit', { cwd: ROOT, stdio: 'pipe' }).toString();
    return { ok: true, out };
  } catch (e) {
    const out = e.stdout?.toString?.() || '';
    const err = e.stderr?.toString?.() || '';
    return { ok: false, out: out || err };
  }
}

// Main
const summary = scan();

let changedPaths = [];
if (DO_FIX) {
  const deltas = ensureCompatPaths(path.join(ROOT, 'tsconfig.json'));
  if (deltas.length) changedPaths.push('tsconfig.json');
}
if (DO_COMPAT) {
  const created = bootstrapCompat();
  changedPaths.push(...created);
}

let tsc = null;
if (WITH_TSC) tsc = runTsc();

if (WANT_JSON) {
  console.log(JSON.stringify({ summary, changedPaths, tsc }, null, 2));
} else {
  console.log('\nFlexible Repo Doctor — Phase 2');
  console.log('Files scanned:', summary.filesScanned);
  const mods = Object.entries(summary.legacyImports);
  if (mods.length) {
    console.log('\nLegacy imports detected:');
    for (const [m, files] of mods) console.log(`  - ${m}: ${files.length} file(s)`);
  } else {
    console.log('\nNo legacy imports detected.');
  }
  console.log('\nDetectors:');
  for (const [k, arr] of Object.entries(summary.detectors)) console.log(`  - ${k}: ${arr.length}`);
  if (changedPaths.length) {
    console.log('\nApplied changes:');
    for (const p of changedPaths) console.log('  -', path.relative(ROOT, p));
  }
  if (tsc) console.log(`\nTypeScript check: ${tsc.ok ? 'OK' : 'Has diagnostics'}`);
  console.log('\nHints: Run with --fix --compat to add path remaps and compat shims. Add --json for CI report.');
}
