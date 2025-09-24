#!/usr/bin/env node
/**
 * CSS Usage Auditor — Tailwind‑aware, Astro‑friendly (fast + deep modes)
 *
 * What it does
 *  - Extracts custom class selectors from your CSS (robust PostCSS parser if available, regex fallback otherwise)
 *  - Scans source files (.astro/.html/.js/.jsx/.ts/.tsx/.mjs) for class usage
 *  - Understands Tailwind shapes (variants, arbitrary values, prefix, safelist) when possible
 *  - Optional AST pass (--deep) to recover classes from JSX/TSX expressions and helpers (clsx/classnames/cva/tv/twMerge/twJoin)
 *  - Classifies tokens:
 *      • unusedCustom: defined in CSS but never used
 *      • missingDefinitions: semantic-looking tokens (by prefix) used but not defined
 *      • suspiciousTokens: tokens that are not Tailwind, not semantic, and not defined
 *  - Writes JSON + Markdown reports to __reports/ (customizable via --outDir)
 *  - Optional SARIF output and CI thresholds via --fail-on
 *
 * Usage
 *    node scripts/css-audit.mjs [--deep] [--config scripts/css-audit.config.json] \
 *         [--sarif __reports/css-usage-report.sarif] [--fail-on "suspicious>0,missingDefinitions>0,unusedCustom>50"] \
 *         [--outDir __reports] [--no-md]
 */

import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';

const ROOT = process.cwd();

// ------------------------- CLI ARGS -------------------------
const args = process.argv.slice(2);
function hasFlag(name) { return args.includes(name); }
function getFlag(name, def = undefined) {
  const i = args.findIndex(a => a === name);
  if (i >= 0 && i + 1 < args.length) return args[i + 1];
  return def;
}

const DEEP_MODE = hasFlag('--deep');
const CONFIG_PATH = path.resolve(ROOT, getFlag('--config', 'scripts/css-audit.config.json'));
const OUT_DIR = path.resolve(ROOT, getFlag('--outDir', '__reports'));
const WRITE_MD = !hasFlag('--no-md');
const SARIF_PATH = getFlag('--sarif', null);
const FAIL_ON = parseFailOn(getFlag('--fail-on', ''));

// ------------------------- DEFAULT CONFIG -------------------------
const DEFAULT_CONFIG = {
  srcGlobs: ['src/**/*.{astro,html,js,jsx,ts,tsx,mjs}'],
  cssGlobs: ['src/**/*.css'],
  semanticPrefixes: ['btn','badge','label','card','nav','pill','chip','link-brand','text-brand','bg-brand','ring-brand','bar-brand','prose-custom','focus-ring'],
  allowlist: ['grecaptcha-badge','third-party-widget-*'],
  denylist: [],
  helperFunctions: ['clsx','classnames','twJoin','twMerge','cva','tv','cx'],
  ciThresholds: { suspicious: 0, missingDefinitions: 0, unusedCustom: 9999 },
};

// ------------------------- UTILITIES -------------------------
function parseFailOn(spec) {
  if (!spec) return null;
  const out = {};
  spec.split(',').map(s => s.trim()).filter(Boolean).forEach(pair => {
    const m = pair.match(/^(suspicious|missingDefinitions|unusedCustom)\s*>\s*(\d+)$/);
    if (m) out[m[1]] = Number(m[2]);
  });
  return Object.keys(out).length ? out : null;
}

function hashStrings(strings) {
  const h = crypto.createHash('sha256');
  for (const s of strings) h.update(String(s));
  return `sha256-${h.digest('base64url')}`;
}

function uniq(arr) { return Array.from(new Set(arr)); }

function globToRegex(glob) {
  // Very small glob -> regex (supports **, *, ?, character classes)
  let re = glob
    .replace(/[.+^${}()|\\]/g, '\\$&')
    .replace(/\*\*/g, '(?:.*)')
    .replace(/\*/g, '[^/]*')
    .replace(/\?/g, '.');
  return new RegExp('^' + re + '$');
}

async function listFilesFromGlobs(globs, { cwd = ROOT } = {}) {
  // Prefer fast-glob if present
  try {
    const fg = (await import('fast-glob')).default;
    return await fg(globs, { cwd, dot: false, onlyFiles: true, unique: true, ignore: ['**/node_modules/**','**/.git/**','**/__reports/**'] });
  } catch {
    // Fallback: walk + filter
    const patterns = globs.map(globToRegex);
    const files = [];
    function walk(dir) {
      const entries = fs.readdirSync(dir, { withFileTypes: true });
      for (const e of entries) {
        if (e.name.startsWith('.') || e.name === 'node_modules' || e.name === '__reports__' || e.name === '.git') continue;
        const full = path.join(dir, e.name);
        if (e.isDirectory()) walk(full);
        else {
          const rel = path.relative(cwd, full).replace(/\\/g, '/');
          if (patterns.some(r => r.test(rel))) files.push(rel);
        }
      }
    }
    walk(cwd);
    return files;
  }
}

async function pathExists(p) { try { await fsp.access(p); return true; } catch { return false; } }

function readJSONSafe(p, fallback = null) {
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); }
  catch { return fallback; }
}

function writeJSON(p, obj) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(obj, null, 2), 'utf8');
}

function writeText(p, text) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, text, 'utf8');
}

// ------------------------- LOAD CONFIG -------------------------
async function loadConfig() {
  let fileCfg = {};
  if (await pathExists(CONFIG_PATH)) {
    try {
      const raw = await fsp.readFile(CONFIG_PATH, 'utf8');
      fileCfg = JSON.parse(raw);
    } catch (e) {
      console.warn('[css-audit] WARN: Could not parse config at', CONFIG_PATH, e.message);
    }
  }
  return { ...DEFAULT_CONFIG, ...fileCfg };
}

// ------------------------- CSS SELECTOR EXTRACTION -------------------------
async function getCustomSelectors(cssGlobs) {
  const cssFiles = await listFilesFromGlobs(cssGlobs);
  const set = new Set();
  const filesAbs = cssFiles.map(p => path.resolve(ROOT, p));

  // Prefer PostCSS + selector parser if available
  let postcss = null; let selectorParser = null;
  try {
    postcss = (await import('postcss')).default;
    selectorParser = (await import('postcss-selector-parser')).default;
  } catch { /* noop */ }

  if (postcss && selectorParser) {
    for (const abs of filesAbs) {
      const css = await fsp.readFile(abs, 'utf8');
      try {
        const root = postcss.parse(css);
        root.walkRules(rule => {
          try {
            selectorParser(selectors => {
              selectors.walkClasses(c => {
                const name = String(c.value || '').trim();
                if (!name || /^\d/.test(name)) return; // skip numeric-leading
                set.add(name);
              });
            }).processSync(rule.selector);
          } catch { /* skip invalid selector */ }
        });
      } catch { /* skip broken css */ }
    }
  } else {
    // Fallback regex (best-effort)
    const regex = /(^|[\s>{;,])\.([a-zA-Z0-9_\\:-]+)/g;
    for (const abs of filesAbs) {
      const css = await fsp.readFile(abs, 'utf8');
      let m; while ((m = regex.exec(css))) {
        let name = m[2].replace(/\\:/g, ':');
        name = name.split('::')[0];
        if (/(:(hover|focus-visible|disabled|active|visited)|:not\()/.test(name)) continue;
        if (['dark','hover','focus','active'].includes(name)) continue;
        if (/^\d/.test(name)) continue;
        set.add(name);
      }
    }
  }

  return { cssFiles, customSet: set };
}

// ------------------------- TOKEN EXTRACTION (FAST REGEX) -------------------------
const ATTR_REGEX = /\bclass(?:Name)?\s*=\s*(?:"([^"]*)"|'([^']*)'|`([^`]*)`)/gms;
const CLASSLIST_REGEX = /\bclass:list\s*=\s*\{([\s\S]*?)\}/gm; // Astro class:list={...}
const HELPERS_REGEX = /\b(?:clsx|classnames|twJoin|twMerge|cva|tv|cx)\s*\(([^)]*)\)/gms;
const QUOTED_STRINGS = /"([^"]+)"|'([^']+)'|`([^`]+)`/g;

function extractTokensFast(source) {
  const tokens = new Set();
  const add = s => {
    if (!s) return;
    for (const t of s.split(/\s+/)) addToken(tokens, t);
  };

  // class / className attributes
  let m; while ((m = ATTR_REGEX.exec(source))) {
    add(m[1] || m[2] || m[3] || '');
  }
  // Astro class:list keys
  while ((m = CLASSLIST_REGEX.exec(source))) {
    const body = m[1] || '';
    let q; while ((q = QUOTED_STRINGS.exec(body))) {
      add(q[1] || q[2] || q[3] || '');
    }
    // object keys like { btn: isPrimary }
    const identKeys = body.match(/(?<=\{|,|\s)([A-Za-z_][\w:-]*)(?=\s*:)/g) || [];
    for (const k of identKeys) add(k);
  }
  // helper calls — extract quoted strings only (ignore expressions)
  while ((m = HELPERS_REGEX.exec(source))) {
    const body = m[1] || '';
    let q; while ((q = QUOTED_STRINGS.exec(body))) add(q[1] || q[2] || q[3] || '');
  }

  return tokens;
}

function addToken(set, raw) {
  if (!raw) return;
  if (raw.includes('{') || raw.includes('}') || raw.includes('${')) return; // ignore dynamic chunks here; AST will recover in deep mode
  const clean = raw.replace(/[^\w:!\-\[\]\/.%()#]/g, '');
  if (!clean) return;
  const trimmed = clean.replace(/:+$/, '');
  if (/^\d+$/.test(trimmed)) return;
  set.add(trimmed);
}

// ------------------------- TOKEN EXTRACTION (AST DEEP) -------------------------
async function extractTokensDeep(code, ext) {
  // Only attempt deep parse for JS/TS/JSX/TSX/MJS
  if (!/(?:\.m?js|\.jsx|\.tsx?|)$/i.test(ext)) return new Set();
  let parser, traverse;
  try {
    parser = (await import('@babel/parser')).parse;
    traverse = (await import('@babel/traverse')).default;
  } catch {
    return new Set();
  }
  const plugins = ['jsx','typescript'];
  let ast;
  try {
    ast = parser(code, { sourceType: 'module', plugins });
  } catch {
    return new Set();
  }
  const out = new Set();

  function addStr(s) { if (s) s.split(/\s+/).forEach(t => addToken(out, t)); }

  function harvestStrings(node, bag) {
    if (!node) return;
    switch (node.type) {
      case 'StringLiteral': bag.push(node.value); break;
      case 'TemplateLiteral': node.quasis.forEach(q => bag.push(q.value.cooked ?? q.value.raw ?? '')); break;
      case 'ArrayExpression': node.elements.forEach(el => harvestStrings(el, bag)); break;
      case 'ObjectExpression':
        node.properties.forEach(p => {
          if (p.type === 'ObjectProperty') {
            if (p.key.type === 'StringLiteral') bag.push(p.key.value);
            if (p.key.type === 'Identifier') bag.push(p.key.name);
            harvestStrings(p.value, bag);
          }
        });
        break;
      case 'ConditionalExpression':
        harvestStrings(node.consequent, bag);
        harvestStrings(node.alternate, bag);
        break;
      case 'LogicalExpression':
        harvestStrings(node.left, bag);
        harvestStrings(node.right, bag);
        break;
      case 'CallExpression':
        {
          const callee = node.callee.type === 'Identifier' ? node.callee.name : '';
          if (['clsx','classnames','twJoin','twMerge','cva','tv','cx'].includes(callee)) {
            node.arguments.forEach(arg => harvestStrings(arg, bag));
          }
        }
        break;
    }
  }

  traverse(ast, {
    JSXAttribute(path) {
      const name = path.node.name?.name;
      if (name !== 'class' && name !== 'className') return;
      const v = path.node.value;
      if (!v) return;
      if (v.type === 'StringLiteral') addStr(v.value);
      else if (v.type === 'JSXExpressionContainer') {
        const bag = [];
        harvestStrings(v.expression, bag);
        bag.forEach(addStr);
      }
    }
  });

  return out;
}

// ------------------------- TAILWIND AWARENESS -------------------------
async function loadTailwindContext() {
  let resolveConfig = null;
  try { resolveConfig = (await import('tailwindcss/resolveConfig.js')).default; }
  catch { /* optional */ }
  let userCfg = null; let tw = null;
  // try common config filenames
  const candidates = ['tailwind.config.ts','tailwind.config.js','tailwind.config.cjs'];
  for (const f of candidates) {
    const p = path.join(ROOT, f);
    if (fs.existsSync(p)) {
      try {
        const mod = await import(pathToFileUrl(p));
        userCfg = mod.default ?? mod;
        break;
      } catch { /* ignore */ }
    }
  }
  if (resolveConfig && userCfg) {
    try { tw = resolveConfig(userCfg); } catch { tw = null; }
  }
  return {
    prefix: tw?.prefix ?? '',
    screens: Object.keys(tw?.theme?.screens ?? {}),
    safelist: (userCfg?.safelist && Array.isArray(userCfg.safelist)) ? userCfg.safelist : [],
  };
}

function pathToFileUrl(p) {
  const { pathToFileURL } = requireLike('node:url') || { pathToFileURL: (x)=>({ href: 'file://' + x }) };
  return pathToFileURL(p).href;
}

function requireLike(spec) { try { return require(spec); } catch { return null; } }

function looksTailwind(token, twCtx) {
  // Strip leading ! important marker
  let raw = token.replace(/^!/, '');
  // Handle configured prefix (e.g., tw-bg-red-500)
  const prefix = twCtx?.prefix || '';
  if (prefix && raw.startsWith(prefix)) raw = raw.slice(prefix.length);

  const parts = raw.split(':');
  raw = parts[parts.length - 1];
  if (/^content-/.test(raw)) return true;

  // Arbitrary values with brackets — allow nested, slashes, spaces underscores
  const arb = /-\[[^\]]+\]$/;

  // Common utility families (not exhaustive)
  const base = /^-?(?:p|m|mx|my|mt|mb|ml|mr|px|py|pt|pr|pb|pl|gap|space|flex|grid|col|row|text|bg|font|leading|tracking|shadow|ring|rounded|border|w|h|min|max|size|aspect|items|justify|content|place|object|overflow|z|top|left|right|bottom|inset|translate|scale|rotate|skew|origin|transition|duration|delay|ease|animate|cursor|select|align|list|decoration|underline|line|sr-only|not-sr-only|prose|opacity|from|to|via|divide|backdrop|grayscale|pointer-events|scroll|shrink|grow|basis|isolate|isolation|order|outline|filter|backdrop-blur|blur|contrast|brightness|saturate|sepia|hue-rotate|drop-shadow|will-change|whitespace|break|hyphens|tabular-nums|subpixel-antialiased|antialiased|place-self|place-items|place-content|auto-cols|auto-rows|grid-cols|grid-rows|col-start|col-end|row-start|row-end|justify-self|content-)(?:[-/\[].+)?$/;

  if (base.test(raw) || arb.test(raw)) return true;
  // gradient helpers
  if (/^(?:bg-gradient-to-[trbl]{1,2}|from-|via-|to-)/.test(raw)) return true;
  // container & prose scopes
  if (/(^|:)(group|container|not-prose|prose(?:-[a-z]+)?)$/.test(raw)) return true;

  // data/aria variants are handled before the tail via parts; treat them acceptable
  // e.g., data-[state=open]:bg-... or aria-selected:bg-...
  if (parts.some(v => /^data-\[[^\]]+\]$/.test(v) || /^aria-[a-z-]+$/.test(v))) return true;

  return false;
}

function looksSemantic(token, cfg) {
  return cfg.semanticPrefixes.some(pre => token === pre || token.startsWith(pre + '-'));
}

function isAllowlisted(token, cfg) {
  return cfg.allowlist.some(rule => rule.endsWith('*') ? token.startsWith(rule.slice(0, -1)) : token === rule);
}

// ------------------------- OCCURRENCES MAP -------------------------
function createOccurrences() {
  const map = new Map();
  return {
    add(token, file, line = null, column = null, context = null) {
      if (!map.has(token)) map.set(token, []);
      map.get(token).push({ file, line, column, context });
    },
    get(token) { return map.get(token) || []; },
    toJSON() {
      const obj = {};
      for (const [k, v] of map.entries()) obj[k] = v;
      return obj;
    }
  };
}

// ------------------------- MAIN -------------------------
(async function main() {
  const cfg = await loadConfig();
  const srcFiles = await listFilesFromGlobs(cfg.srcGlobs);
  const { cssFiles, customSet } = await getCustomSelectors(cfg.cssGlobs);
  const twCtx = await loadTailwindContext();

  const usedTokens = new Set();
  const occ = createOccurrences();

  // Read all sources
  await Promise.all(srcFiles.map(async rel => {
    const abs = path.resolve(ROOT, rel);
    let code = '';
    try { code = await fsp.readFile(abs, 'utf8'); }
    catch { return; }

    // Fast regex scanning
    const fast = extractTokensFast(code);
    fast.forEach(t => { usedTokens.add(t); occ.add(t, rel); });

    // Deep AST scanning (optional)
    if (DEEP_MODE) {
      const ext = path.extname(rel).toLowerCase();
      const deep = await extractTokensDeep(code, ext);
      deep.forEach(t => { usedTokens.add(t); occ.add(t, rel); });
    }
  }));

  // Tailwind safelist should not be flagged
  for (const t of twCtx.safelist || []) usedTokens.add(String(t));

  // Classify
  const tokensArray = Array.from(usedTokens);
  const suspiciousTokens = [];
  const missingDefinitions = [];

  for (const t of tokensArray) {
    if (isAllowlisted(t, cfg)) continue;
    const isCustom = customSet.has(t);
    const isSemantic = looksSemantic(t, cfg);
    const isTW = looksTailwind(t, twCtx);

    if (isSemantic && !isCustom) missingDefinitions.push(t);
    else if (!isCustom && !isTW && !isSemantic) suspiciousTokens.push(t);
  }

  const unusedCustom = Array.from(customSet).filter(c => !usedTokens.has(c));

  // Sort for stable output
  suspiciousTokens.sort();
  missingDefinitions.sort();
  unusedCustom.sort();

  // Compose report
  const timestamp = new Date().toISOString();
  const inputHash = hashStrings([
    JSON.stringify(cfg),
    JSON.stringify(srcFiles),
    JSON.stringify(cssFiles)
  ]);

  const report = {
    schemaVersion: 2,
    timestamp,
    input: {
      srcFiles: srcFiles.length,
      cssFiles,
      tailwind: { prefix: twCtx.prefix, screens: twCtx.screens, safelistCount: twCtx.safelist.length },
      hash: inputHash
    },
    counts: {
      customDefined: customSet.size,
      tokensUsed: usedTokens.size,
      unusedCustom: unusedCustom.length,
      missingDefinitions: missingDefinitions.length,
      suspiciousTokens: suspiciousTokens.length
    },
    unusedCustom,
    missingDefinitions,
    suspiciousTokens,
    occurrences: occ.toJSON()
  };

  fs.mkdirSync(OUT_DIR, { recursive: true });
  const OUT_JSON = path.join(OUT_DIR, 'css-usage-report.json');
  writeJSON(OUT_JSON, report);

  if (WRITE_MD) {
    const md = renderMarkdown(report);
    writeText(path.join(OUT_DIR, 'css-usage-report.md'), md);
  }

  if (SARIF_PATH) {
    const sarif = toSarif(report);
    writeJSON(SARIF_PATH, sarif);
  }

  // Console summary
  console.log('[css-audit] wrote', OUT_JSON, WRITE_MD ? 'and markdown' : '', SARIF_PATH ? 'and SARIF' : '');
  console.table(report.counts);

  // CI gating
  const thresholds = FAIL_ON || cfg.ciThresholds || {};
  let failing = false;
  const breaches = [];
  for (const [k, v] of Object.entries({
    suspicious: report.counts.suspiciousTokens,
    missingDefinitions: report.counts.missingDefinitions,
    unusedCustom: report.counts.unusedCustom
  })) {
    const lim = thresholds[k];
    if (typeof lim === 'number' && v > lim) { failing = true; breaches.push(`${k}=${v} > ${lim}`); }
  }
  if (failing) {
    console.error('[css-audit] FAIL:', breaches.join('; '));
    process.exit(2);
  }
})().catch(err => {
  console.error('[css-audit] Unhandled error:', err?.stack || err);
  process.exit(1);
});

// ------------------------- RENDERERS -------------------------
function renderMarkdown(r) {
  const lines = [];
  lines.push('# CSS Usage Report', '', `Generated: ${r.timestamp}`, '');

  lines.push('## Summary', '', '| Metric | Count |', '| ------ | -----:|');
  lines.push(`| Custom selectors defined | ${r.counts.customDefined} |`);
  lines.push(`| Tokens used (unique) | ${r.counts.tokensUsed} |`);
  lines.push(`| Unused custom selectors | ${r.counts.unusedCustom} |`);
  lines.push(`| Missing semantic definitions | ${r.counts.missingDefinitions} |`);
  lines.push(`| Suspicious tokens | ${r.counts.suspiciousTokens} |`, '');

  lines.push('## Missing Definitions', '');
  if (r.missingDefinitions.length) {
    r.missingDefinitions.slice(0, 500).forEach(tok => {
      const samples = r.occurrences?.[tok]?.slice(0, 3) || [];
      const where = samples.map(s => `- ${s.file}${s.line ? `:${s.line}` : ''}`).join('\n');
      lines.push(`- \\`${tok}\\``);
      if (where) lines.push(where);
    });
  } else {
    lines.push('_None_');
  }
  lines.push('');

  lines.push('## Suspicious Tokens', '');
  if (r.suspiciousTokens.length) {
    r.suspiciousTokens.slice(0, 500).forEach(tok => {
      const samples = r.occurrences?.[tok]?.slice(0, 3) || [];
      const where = samples.map(s => `- ${s.file}${s.line ? `:${s.line}` : ''}`).join('\n');
      lines.push(`- \\`${tok}\\``);
      if (where) lines.push(where);
    });
  } else {
    lines.push('_None_');
  }
  lines.push('');

  lines.push('## Unused Custom Selectors', '');
  if (r.unusedCustom.length) {
    r.unusedCustom.slice(0, 1000).forEach(c => lines.push('- `' + c + '`'));
  } else {
    lines.push('_None_');
  }

  return lines.join('\n');
}

function toSarif(r) {
  const results = [];
  const rules = [];
  const make = (id, level, message, tokens) => {
    for (const t of tokens) {
      const occs = r.occurrences?.[t] || [{}];
      const first = occs[0] || {};
      results.push({
        ruleId: id,
        level,
        message: { text: `${message}: ${t}` },
        locations: [{
          physicalLocation: {
            artifactLocation: { uri: first.file || 'unknown' },
            region: { startLine: first.line || 1, startColumn: first.column || 1 }
          }
        }]
      });
    }
    rules.push({ id, name: id, shortDescription: { text: message } });
  };

  make('missing-def', 'warning', 'Missing semantic definition', r.missingDefinitions);
  make('suspicious-token', 'error', 'Suspicious class token', r.suspiciousTokens);
  make('unused-custom', 'note', 'Unused custom selector', r.unusedCustom);

  return {
    $schema: 'https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0.json',
    version: '2.1.0',
    runs: [{
      tool: { driver: { name: 'css-usage-auditor', rules } },
      results
    }]
  };
}
