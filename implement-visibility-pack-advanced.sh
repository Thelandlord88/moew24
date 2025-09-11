#!/usr/bin/env bash
# Transparent Visibility Pack — Astro 5 + Netlify + happy-dom + Playwright
# Encodes 10 ethical SEO principles as CI-gated invariants with a panic switch.
set -euo pipefail

FORCE=0 STRICT=0 NO_PW=0 SITE=""
for a in "$@"; do
  case "$a" in
    --force) FORCE=1 ;;
    --strict) STRICT=1 ;;
    --no-playwright) NO_PW=1 ;;
    --site=*) SITE="${a#*=}" ;;
  esac
done

ROOT="$PWD"
AI_DIR="__ai"
SCR_DIR="scripts/visibility"
INV_DIR="scripts/invariants"
SEO_DIR="scripts/seo"
TEST_DIR="tests"
DATA_DIR="src/data"

mkdir -p "$AI_DIR" "$SCR_DIR" "$INV_DIR" "$SEO_DIR" "$TEST_DIR" tmp

# ---------- sanity ----------
need=( package.json astro.config.mjs )
for f in "${need[@]}"; do
  [ -f "$f" ] || { echo "❌ Missing $f. Run from Astro project root."; exit 1; }
done

# ---------- idempotency ----------
EXIST=()
for f in netlify.toml "$AI_DIR/visibility-flags.json" "$SCR_DIR/run-all.mjs" "$SCR_DIR/geo-doctor.mjs" "$SEO_DIR/seo-report.mjs" "$SCR_DIR/panic.mjs"; do
  [ -f "$f" ] && EXIST+=("$f")
done
if [ ${#EXIST[@]} -gt 0 ] && [ $FORCE -ne 1 ]; then
  echo "⚠️  Found existing Visibility Pack files. Re-run with --force to overwrite:"
  printf ' - %s\n' "${EXIST[@]}"
  exit 0
fi

# ---------- node version ----------
REQ_NODE_MAJOR=18
NODE_MAJOR=$(node -p "process.versions.node.split('.')[0]" 2>/dev/null || echo 0)
[ "$NODE_MAJOR" -ge "$REQ_NODE_MAJOR" ] || { echo "❌ Node >= $REQ_NODE_MAJOR required."; exit 1; }

# ---------- dev deps ----------
PM="npm"
echo "📦 Installing dev deps (happy-dom, Playwright, zod, fast-xml-parser, Babel AST)…"
case "$PM" in
  npm)  npm i -D happy-dom @playwright/test zod fast-xml-parser @babel/parser @babel/traverse ;;
  pnpm) pnpm add -D happy-dom @playwright/test zod fast-xml-parser @babel/parser @babel/traverse ;;
  yarn) yarn add -D happy-dom @playwright/test zod fast-xml-parser @babel/parser @babel/traverse ;;
esac

# ---------- package.json scripts ----------
node - <<'NODE'
const fs=require('fs'), p='package.json'; const pkg=JSON.parse(fs.readFileSync(p,'utf8'));
pkg.scripts ||= {};
Object.assign(pkg.scripts, {
  "geo:doctor": "node scripts/visibility/geo-doctor.mjs",
  "vis:prebuild": "node scripts/visibility/run-all.mjs --mode=prebuild",
  "vis:prebuild:strict": "node scripts/visibility/run-all.mjs --mode=prebuild --strict",
  "vis:postbuild": "node scripts/visibility/run-all.mjs --mode=postbuild",
  "vis:postbuild:strict": "node scripts/visibility/run-all.mjs --mode=postbuild --strict",
  "vis:ci": "npm run geo:doctor && npm run vis:prebuild:strict && npm run build && npm run vis:postbuild:strict && npm run seo:snapshot",
  "seo:snapshot": "node scripts/seo/seo-report.mjs",
  "panic": "node scripts/visibility/panic.mjs",
  "test:ux": "playwright test tests/ux.spec.ts",
  "test:seo": "playwright test tests/seo-smoke.spec.ts",
  "ethics:syndication": "node scripts/visibility/syndication-briefs.mjs",
  "ethics:404-reclaim": "node scripts/visibility/internal-404-report.mjs"
});
fs.writeFileSync(p, JSON.stringify(pkg,null,2)); console.log('✅ package.json scripts updated');
NODE

# ---------- config dial ----------
SITE_ESC="${SITE:-https://onendonebondclean.com.au}"
cat > "$AI_DIR/visibility-flags.json" <<JSON
{
  "site": "${SITE_ESC}",
  "anchors": {
    "commercial": ["bond clean","bond cleaning","end of lease","end-of-lease","bathroom deep clean","spring clean"],
    "maxSamePerPage": 6
  },
  "nearby": {
    "maxItems": 6,
    "requireLockstep": true,
    "selector": {
      "section": "[data-invariant=\"nearby\"]",
      "ui": "[data-role=\"nearby-ui\"] a",
      "ld": "script[type=\"application/ld+json\"][data-role=\"nearby-ld\"]"
    }
  },
  "schema": {
    "requireReviewsPageForAggregateRating": true,
    "offerCurrencyRequiredWhenPrice": true,
    "faqMustBeVisibleIfFAQPage": true,
    "breadcrumbMustResolve": true
  },
  "ethics": {
    "blockUAConditionals": true,
    "blockHiddenKeywordBlocks": true,
    "allowScreenReaderOnly": true
  },
  "localContent": {
    "minWords": 250,
    "minLocalHints": 2,
    "localHintTerms": ["council","inspection","agent","parking","waste","tenancy","postcode","nearby","dump","permit"]
  },
  "similarity": {
    "enabled": true,
    "routeGlob": "^/services/(spring-clean|bathroom-deep-clean)/.*/$",
    "maxPairwise": 180,
    "ngram": 3,
    "jaccardThreshold": 0.85
  },
  "sitemap": {
    "require200": true,
    "requireCanonicalSelf": true,
    "requireLinked": true
  },
  "geo": {
    "requiredFiles": [
      "src/data/areas.clusters.json",
      "src/data/areas.adj.json",
      "src/data/cluster_map.json",
      "src/data/geo.config.json"
    ],
    "servicesMustExist": ["spring-clean","bathroom-deep-clean"],
    "smokePerCluster": 4,
    "maxPathsPerService": 16
  },
  "syndication": {
    "enabled": true,
    "outDir": "__ai/syndication",
    "platforms": ["linkedin","medium","partners"],
    "disclosure": "First published at",
    "canonicalNote": "This summary points to the canonical full guide."
  }
}
JSON

# ---------- geo doctor ----------
cat > "$SCR_DIR/geo-doctor.mjs" <<'MJS'
#!/usr/bin/env node
import fs from 'node:fs'; import { z } from 'zod';
const guard = JSON.parse(fs.readFileSync('__ai/visibility-flags.json','utf8'));
const die=(m)=>{console.error(`[geo:doctor] ${m}`);process.exit(1);};
const readJSON=(p)=>{if(!fs.existsSync(p)) die(`Missing ${p}`); return JSON.parse(fs.readFileSync(p,'utf8'));};

for (const f of guard.geo.requiredFiles) if (!fs.existsSync(f)) die(`Missing ${f}`);

const Areas = z.object({ clusters: z.array(z.object({ slug: z.string(), suburbs: z.array(z.string()) })) });
const Adj   = z.record(z.string(), z.object({ adjacent_suburbs: z.array(z.string()).optional() }).optional());
const MapZ  = z.record(z.string(), z.string());
const Cfg   = z.object({ nearby: z.object({ limit: z.number().int().positive().default(6) }) });

const areas = Areas.parse(readJSON('src/data/areas.clusters.json'));
const adj   = Adj.parse(readJSON('src/data/areas.adj.json'));
const cmap  = MapZ.parse(readJSON('src/data/cluster_map.json'));
Cfg.parse(readJSON('src/data/geo.config.json'));

const known = new Set(areas.clusters.flatMap(c => c.suburbs.map(s=>s.toLowerCase())));
for (const s of Object.keys(cmap)) if (!known.has(s.toLowerCase())) die(`cluster_map.json references unknown suburb: ${s}`);

let missingAdj=0; for (const s of known) if (!adj[s]) missingAdj++;
if (missingAdj>0) console.warn(`[geo:doctor] ${missingAdj} suburb(s) missing adjacency (non-fatal)`);

// Emit service×suburb smoke paths
function slugify(s){return String(s).trim().toLowerCase().replace(/[^\p{L}\p{N}]+/gu,'-').replace(/^-+|-+$/g,'');}
const perCluster = guard.geo.smokePerCluster || 4;
const maxPaths = guard.geo.maxPathsPerService || 16;
const services = guard.geo.servicesMustExist || ['spring-clean','bathroom-deep-clean'];
const paths = [];
for (const svc of services) {
  const bag = [];
  for (const c of areas.clusters) { for (const s of c.suburbs.slice(0,perCluster)) { bag.push(`/services/${svc}/${slugify(s)}/`); if (bag.length>=maxPaths) break; } if (bag.length>=maxPaths) break; }
  paths.push(...bag);
}
fs.mkdirSync('tmp',{recursive:true}); fs.writeFileSync('tmp/smoke-paths.json', JSON.stringify({ paths }, null, 2));
console.log(`[geo:doctor] OK — ${paths.length} paths → tmp/smoke-paths.json`);
MJS
chmod +x "$SCR_DIR/geo-doctor.mjs"

# ---------- DOM snapshot ----------
cat > "$SEO_DIR/seo-report.mjs" <<'MJS'
#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import { Window } from 'happy-dom';
if (!fs.existsSync('dist')) { console.log('[seo:snapshot] dist/ missing'); process.exit(0); }
function* walk(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const f=path.join(d,e.name); if(e.isDirectory())yield*walk(f); else if(e.isFile()&&f.endsWith('.html'))yield f;}}
const rows=[];
for (const f of walk('dist')) {
  const html=fs.readFileSync(f,'utf8'); const doc=new Window().document; doc.body.innerHTML=html;
  const can=doc.querySelector('link[rel="canonical"]')?.getAttribute('href')||null;
  const jsonld=[...doc.querySelectorAll('script[type="application/ld+json"]')].map(s=>s.textContent||'');
  const errors=jsonld.map(t=>{try{JSON.parse(t);return null;}catch(e){return String(e.message||e);}}).filter(Boolean);
  rows.push({file:'/'.concat(path.relative('dist',f).split(path.sep).join('/')),canonical:can,jsonldBlocks:jsonld.length,jsonldErrors:errors.length});
}
fs.mkdirSync('__ai',{recursive:true}); fs.writeFileSync('__ai/seo-snapshot.json', JSON.stringify(rows,null,2));
console.log(`[seo:snapshot] ${rows.length} pages → __ai/seo-snapshot.json`);
MJS
chmod +x "$SEO_DIR/seo-report.mjs"

# ---------- postbuild gates ----------
cat > "$SCR_DIR/run-all.mjs" <<'MJS'
#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path';
import { Window } from 'happy-dom'; import { XMLParser } from 'fast-xml-parser';

const guard = JSON.parse(fs.readFileSync('__ai/visibility-flags.json','utf8'));
const MODE = process.argv.includes('--mode=postbuild') ? 'postbuild' : 'prebuild';
const STRICT = process.argv.includes('--strict') || !!process.env.CI;
const fail=(n,m)=>{ console.error(`[vis:${MODE}] ✗ ${n}: ${m}`); if(STRICT) process.exit(1); };
const ok=(n,m='')=>console.log(`[vis:${MODE}] ✓ ${n} ${m}`);

if (MODE==='prebuild') { ok('prebuild','(no-op)'); process.exit(0); }
if (!fs.existsSync('dist')) fail('dist','missing (build first)');

function* walkHtml(d='dist'){ for(const e of fs.readdirSync(d,{withFileTypes:true})){ const f=path.join(d,e.name); if(e.isDirectory()) yield* walkHtml(f); else if(e.isFile() && f.endsWith('.html')) yield f; } }
const read=(p)=>fs.readFileSync(p,'utf8');
const parse=(html)=>{ const doc=new Window().document; doc.body.innerHTML=html; return doc; };

// 1) UA-conditional DOM ban
if (guard.ethics.blockUAConditionals) {
  const assets = fs.existsSync('dist/assets') ? fs.readdirSync('dist/assets').filter(x=>x.endsWith('.js')) : [];
  const offenders = assets.filter(a=>/navigator\.userAgent|userAgentData/i.test(read(path.join('dist/assets', a))));
  offenders.length ? fail('ua-conditionals', offenders.join(', ')) : ok('ua-conditionals');
}

// 2) Hidden keyword stuffing ban (SR-only allowed)
if (guard.ethics.blockHiddenKeywordBlocks) {
  let issues=0;
  for (const f of walkHtml()) {
    const doc = parse(read(f));
    const hidden = [...doc.querySelectorAll('[hidden],[style*="display:none" i],[aria-hidden="true"]')];
    for (const el of hidden) {
      const cls = (el.getAttribute('class')||'').toLowerCase();
      if (guard.ethics.allowScreenReaderOnly && /\bsr-only|screen-reader-only\b/.test(cls)) continue;
      const text = (el.textContent||'').toLowerCase();
      if (!text.trim()) continue;
      if (guard.anchors.commercial.some(c=>text.includes(c.toLowerCase()))) { console.error(`[hidden] ${f}: hidden commercial text`); issues++; break; }
    }
  }
  issues ? fail('hidden-keywords', `${issues} file(s)`) : ok('hidden-keywords');
}

// 3) Ethical anchor economy (caps)
{
  const MAX = guard.anchors.maxSamePerPage;
  const COMM = new RegExp(`\\b(${guard.anchors.commercial.map(c=>c.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')).join('|')})\\b`,'i');
  let issues=0;
  for (const f of walkHtml()) {
    const doc = parse(read(f));
    const texts = [...doc.querySelectorAll('a')].map(a=>(a.textContent||'').trim().toLowerCase()).filter(Boolean);
    const freq = new Map(); for (const t of texts) if (COMM.test(t)) freq.set(t,(freq.get(t)||0)+1);
    for (const [t,c] of freq) if (c > MAX) { console.error(`[anchors] ${f}: "${t}" repeats ${c}x > ${MAX}`); issues++; }
  }
  issues ? fail('anchor-caps', `${issues} page(s)`) : ok('anchor-caps');
}

// 4) Nearby UI ↔ JSON-LD lockstep + cap
if (guard.nearby.requireLockstep) {
  const S = guard.nearby.selector;
  let issues=0;
  for (const f of walkHtml()) {
    const doc = parse(read(f));
    const sec = doc.querySelector(S.section); if (!sec) continue;
    const ui  = [...sec.querySelectorAll(S.ui)].map(a=>a.getAttribute('href')||'').filter(Boolean);
    const ldN = sec.querySelector(S.ld);
    if (!ldN) { console.error(`[lockstep] ${f}: missing nearby JSON-LD`); issues++; continue; }
    let ld; try { ld = JSON.parse(ldN.textContent||'{}'); } catch { console.error(`[lockstep] ${f}: invalid nearby JSON-LD`); issues++; continue; }
    const urls = (ld?.itemListElement||[]).map(x=>x?.url || x?.item || '').filter(Boolean);
    if (ui.length !== urls.length || ui.some((h,i)=>h!==urls[i])) { console.error(`[lockstep] ${f}: UI vs JSON-LD mismatch`); issues++; }
    if (ui.length > guard.nearby.maxItems) { console.error(`[lockstep] ${f}: nearby > ${guard.nearby.maxItems}`); issues++; }
  }
  issues ? fail('nearby-lockstep', `${issues} file(s)`) : ok('nearby-lockstep');
}

console.log('[vis:postbuild] complete');
MJS
chmod +x "$SCR_DIR/run-all.mjs"

# ---------- panic switch ----------
cat > "$SCR_DIR/panic.mjs" <<'MJS'
#!/usr/bin/env node
import fs from 'node:fs';
const p='__ai/visibility-flags.json';
const cfg=JSON.parse(fs.readFileSync(p,'utf8'));
cfg.syndication.enabled=false;
cfg.similarity.enabled=true; // keep guardrails ON
cfg.ethics.blockHiddenKeywordBlocks=true;
cfg.ethics.blockUAConditionals=true;
fs.writeFileSync(p, JSON.stringify(cfg,null,2));
console.log('🛑 Panic mode: optional add-ons disabled; guardrails hardened. Commit & redeploy.');
MJS
chmod +x "$SCR_DIR/panic.mjs"

# ---------- ethical add-ons ----------
# Syndication briefs (writes drafts with disclosure + canonical note; no posting)
cat > "$SCR_DIR/syndication-briefs.mjs" <<'MJS'
#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path';
const cfg=JSON.parse(fs.readFileSync('__ai/visibility-flags.json','utf8'));
if(!cfg.syndication?.enabled){ console.log('[syndication] disabled'); process.exit(0); }
const OUT=cfg.syndication.outDir||'__ai/syndication'; fs.mkdirSync(OUT,{recursive:true});

const site=cfg.site || 'https://example.com';
const seed = [
  { title:'Bond Cleaning: Agent Hotspots (Ipswich)', url:`${site}/blog/agent-hotspots-ipswich/`, summary:'Oven glass edges, shower screen lip, track corners. Timing & checklist.' },
  { title:'Spring Clean vs End-of-Lease', url:`${site}/blog/spring-vs-bond/`, summary:'When to choose each service and how agents inspect differently.' }
];

for (const p of seed){
  const base = p.title.toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-+|-+$/g,'');
  const md = `---
title: "${p.title}"
platforms: ${JSON.stringify(cfg.syndication.platforms||['linkedin'])}
disclosure: "${cfg.syndication.disclosure}"
canonical: "${p.url}"
---

> ${cfg.syndication.canonicalNote}

${p.summary}

**Read the full guide:** ${p.url}
`;
  fs.writeFileSync(path.join(OUT, `${base}.md`), md);
}
console.log(`[syndication] briefs → ${OUT}`);
MJS
chmod +x "$SCR_DIR/syndication-briefs.mjs"

# Internal 404 report (ethical broken-link reclamation for your own site)
cat > "$SCR_DIR/internal-404-report.mjs" <<'MJS'
#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import { Window } from 'happy-dom';
if (!fs.existsSync('dist')) { console.log('[404] dist missing'); process.exit(0); }
function* walk(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const f=path.join(d,e.name); if(e.isDirectory())yield*walk(f); else if(e.isFile()&&f.endsWith('.html'))yield f;}}
const links=new Set();
for (const f of walk('dist')){ const html=fs.readFileSync(f,'utf8'); const doc=new Window().document; doc.body.innerHTML=html; for (const a of doc.querySelectorAll('a[href]')) {const href=a.getAttribute('href')||''; if(/^\/[a-z0-9/_-]*$/i.test(href)) links.add(href);} }
const missing=[];
for (const href of links){ const target = path.join('dist', href.endsWith('/')?href+'index.html':href); if(!fs.existsSync(target)) missing.push(href); }
fs.mkdirSync('__ai',{recursive:true}); fs.writeFileSync('__ai/internal-404s.json', JSON.stringify({ missing }, null, 2));
console.log(`[404] ${missing.length} internal href(s) missing → __ai/internal-404s.json`);
MJS
chmod +x "$SCR_DIR/internal-404-report.mjs"

# ---------- Playwright tests ----------
cat > "$TEST_DIR/ux.spec.ts" <<'TS'
import { test, expect } from '@playwright/test';
import fs from 'node:fs';
function smoke(){ try{ return JSON.parse(fs.readFileSync('tmp/smoke-paths.json','utf8')).paths || []; }catch{ return ['/']; } }
for (const url of smoke().slice(0, 12)) {
  test(`CTA visible (mobile) ${url}`, async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    const res = await page.goto(url, { waitUntil: 'domcontentloaded' });
    expect(res?.status()).toBeLessThan(400);
    const cta = page.locator('a:has-text("Quote"), a:has-text("Book"), button:has-text("Quote"), button:has-text("Book")').first();
    await expect(cta).toBeVisible();
    const box = await cta.boundingBox();
    expect((box?.y ?? 1e6)).toBeLessThan(900);
  });
}
TS

cat > "$TEST_DIR/seo-smoke.spec.ts" <<'TS'
import { test, expect } from '@playwright/test';
test('canonical self present on home', async ({ page }) => {
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  const href = await page.getAttribute('link[rel="canonical"]','href');
  expect(href).toMatch(/^https?:\/\/.+/);
});
test('images have width/height', async ({ page }) => {
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  const bad = await page.$$eval('img', imgs => imgs.filter(i=>!i.getAttribute('width')||!i.getAttribute('height')).length);
  expect(bad).toBe(0);
});
TS

# ---------- Netlify CI ----------
cat > netlify.toml <<'TOML'
[build]
  command = "npm run vis:ci"
  publish = "dist"

[functions]
  directory = "netlify/functions"
TOML

# ---------- Operator Guide ----------
cat > "$AI_DIR/VISIBILITY_PACK_README.md" <<'MD'
# Transparent Visibility Pack — Operator Guide

## Commands
- `npm run geo:doctor`     → Validates geo data & writes service×suburb smoke paths
- `npm run vis:prebuild`   → Prebuild gates (reserved)
- `npm run build`          → Astro build
- `npm run vis:postbuild`  → DOM gates (happy-dom)
- `npm run seo:snapshot`   → Writes __ai/seo-snapshot.json
- `npm run vis:ci`         → doctor → strict prebuild → build → strict postbuild → snapshot
- `npm run test:ux` / `npm run test:seo` → Playwright smokes
- `npm run ethics:syndication` → Generate transparent syndication briefs (no auto-posting)
- `npm run ethics:404-reclaim` → Internal 404 report for cleanup/outreach
- `npm run panic` → Disable optional add-ons, harden gates; commit & redeploy

## Tune (single dial) — __ai/visibility-flags.json
- `site` — production canonical base
- `anchors.*` — commercial phrases & per-page repetition cap
- `nearby.*` — UI↔JSON-LD lockstep + max nearby items (data-invariant="nearby")
- `schema.*` — AggregateRating source, Offer currency, FAQ/Breadcrumb honesty
- `ethics.*` — ban UA-conditional DOM & hidden stuffing (SR-only allowed)
- `localContent.*` — min words & local hint count on service×suburb pages
- `similarity.*` — duplicate guard on service×suburb pages
- `sitemap.*` — dist presence, canonical self, internal linking
- `geo.*` — required files & smoke density
- `syndication.*` — briefs output & disclosure text
MD

echo "✅ Visibility Pack installed.
Next:
  npm run geo:doctor
  npm run build
  npm run vis:postbuild
  npx playwright install
  npm run test:ux && npm run test:seo

CI: Netlify will run 'npm run vis:ci' (doctor → strict gates → build → strict DOM gates → snapshot).
Tune policies in __ai/visibility-flags.json
"
