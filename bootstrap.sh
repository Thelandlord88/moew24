#!/usr/bin/env bash
# upstream bootstrapper for One N Done (Astro 5)
# Usage: bash bootstrap.sh --force
set -euo pipefail

# ========== 0) CONSENT + IDEMPOTENCY (must be first) ==========
FORCE=0
for arg in "$@"; do [ "$arg" = "--force" ] && FORCE=1; done

CHECK_FILES=(
  "package.json"
  "astro.config.mjs"
  "src/layouts/BaseLayout.astro"
  "src/styles/global.css"
)
EXISTING=(); for f in "${CHECK_FILES[@]}"; do [ -f "$f" ] && EXISTING+=("$f"); done
if [ ${#EXISTING[@]} -gt 0 ] && [ "$FORCE" -ne 1 ]; then
  echo "⚠️  Found existing scaffold files:"
  printf ' - %s\n' "${EXISTING[@]}"
  echo "Re-run with --force to overwrite."
  exit 0
fi

# ========== 1) SCAFFOLD FS ==========
mkdir -p src/{components,content/{posts},data,layouts,lib/{geo,seo},pages/{blog,services,suburbs},styles} \
         scripts/{geo,seo,invariants} __ai tmp public tests netlify/functions

# ========== 2) package.json (merge or create) ==========
if [ ! -f package.json ]; then
  cat > package.json <<'JSON'
{ "name": "onedone-app", "private": true, "version": "0.0.0", "type": "module", "scripts": {} }
JSON
fi

node - <<'NODE'
const fs = require('fs');
const P = 'package.json';
const j = JSON.parse(fs.readFileSync(P,'utf8'));

j.type ||= 'module';
j.scripts ||= {};
Object.assign(j.scripts, {
  dev: "astro dev",
  build: "astro build",
  preview: "astro preview",
  "content:check": "astro check --content",
  "geo:doctor": "node scripts/geo/geo-doctor.mjs",
  "geo:doctor:strict": "node scripts/geo/geo-doctor.mjs --strict",
  "seo:report": "node scripts/seo/report-hardcoded-seo.mjs",
  "inv:anchors": "node scripts/invariants/anchor-linter.mjs",
  "inv:lockstep": "node scripts/invariants/schema-lockstep.mjs",
  "inv:no-ua": "node scripts/invariants/no-ua-dom.mjs",
  "inv:no-hidden": "node scripts/invariants/no-hidden-keywords.mjs",
  "inv:sitemap": "node scripts/invariants/sitemap-check.mjs",
  "inv:similar": "node scripts/invariants/similarity-check.mjs",
  "guard:all": "npm run geo:doctor:strict && npm run build && npm run seo:report && npm run inv:anchors && npm run inv:lockstep && npm run inv:no-ua && npm run inv:no-hidden && npm run inv:sitemap && npm run inv:similar",
  "test:geo": "playwright test src/tests/geo.smoke.spec.ts"
});

j.dependencies ||= {};
j.devDependencies ||= {};
// Core versions kept aligned with upstream script
j.dependencies.astro = j.dependencies.astro || "^5.0.0";
j.devDependencies.typescript = j.devDependencies.typescript || "^5.6.0";
j.devDependencies["@types/node"] = j.devDependencies["@types/node"] || "^20.14.0";
j.dependencies["@astrojs/rss"] = j.dependencies["@astrojs/rss"] || "^4.0.0";

j.devDependencies.postcss = j.devDependencies.postcss || "^8.4.39";
j.devDependencies.tailwindcss = j.devDependencies.tailwindcss || "^4.0.0";
j.devDependencies["@tailwindcss/postcss"] = j.devDependencies["@tailwindcss/postcss"] || "^4.0.0";

j.devDependencies["happy-dom"] = j.devDependencies["happy-dom"] || "^14.11.0";
j.devDependencies["@playwright/test"] = j.devDependencies["@playwright/test"] || "^1.46.0";
j.devDependencies["zod"] = j.devDependencies["zod"] || "^3.23.8";

fs.writeFileSync(P, JSON.stringify(j,null,2));
NODE

# ========== 3) Astro + Tailwind ==========
cat > astro.config.mjs <<'CFG'
import { defineConfig } from 'astro/config';
export default defineConfig({
  site: 'https://onendonebondclean.com.au',
  server: { port: 4321 },
  vite: {
    resolve: { alias: { '@': '/src' } },
    css: { postcss: { plugins: [require('@tailwindcss/postcss')] } },
  },
});
CFG

cat > postcss.config.cjs <<'POSTCSS'
module.exports = { plugins: [require('@tailwindcss/postcss')] };
POSTCSS

cat > src/styles/global.css <<'CSS'
@import "tailwindcss";
:root { --brand: #0a2a58; }
html { scroll-behavior: smooth; }
a { text-underline-offset: 2px; }
CSS

# ========== 4) Base layout with LocalBusiness JSON-LD (XSS-safe) ==========
cat > src/layouts/BaseLayout.astro <<'ASTRO'
---
import "@/styles/global.css";
interface Props { title: string; description?: string; canonical?: string; }
const { title, description = "", canonical = "/" } = Astro.props;
const site = Astro.site?.toString().replace(/\/$/, "") || "";
const canonicalAbs = canonical.startsWith('http') ? canonical : `${site}${canonical}`;
const businessMods = import.meta.glob('/src/data/business.json', { eager: true, import: 'default' }) as Record<string, any>;
const business = Object.values(businessMods)[0] ?? null;
const businessLD = business ? {
  "@context":"https://schema.org","@type":"LocalBusiness","@id":`${site}#business`,
  name: business.name, url: business.url || site, telephone: business.telephone, email: business.email,
  address: business.address && {"@type":"PostalAddress", ...business.address}
} : null;
function safeJsonLd(o:any){ return JSON.stringify(o).replace(/</g,"\\u003c").replace(/-->/g,"\\u002d\\u002d>"); }
---
<!doctype html>
<html lang="en-AU">
  <head>
    <meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{title}</title>
    {description && <meta name="description" content={description} />}
    <link rel="canonical" href={canonicalAbs} />
    <meta name="theme-color" content="#0a2a58" />
    {businessLD && <script type="application/ld+json" set:html={safeJsonLd(businessLD)} />}
  </head>
  <body class="min-h-screen bg-white text-slate-900">
    <header class="border-b">
      <nav class="max-w-6xl mx-auto px-4 py-3 flex items-center justify-between">
        <a href="/" class="font-extrabold tracking-tight" style="color:var(--brand)">One N Done</a>
        <ul class="flex gap-4 text-sm">
          <li><a class="hover:underline" href="/blog/">Blog</a></li>
          <li><a class="hover:underline" href="/suburbs/">Suburbs</a></li>
          <li><a class="hover:underline" href="/services/">Services</a></li>
          <li><a class="hover:underline" href="/quote/">Quote</a></li>
        </ul>
      </nav>
    </header>
    <main class="max-w-6xl mx-auto px-4 py-8"><slot /></main>
    <footer class="border-t"><div class="max-w-6xl mx-auto px-4 py-6 text-sm text-slate-600">
      © {new Date().getFullYear()} One N Done Bond Clean
    </div></footer>
  </body>
</html>
ASTRO

# ========== 5) Content Collections (strict) ==========
cat > src/content/config.ts <<'TS'
import { defineCollection, z } from 'astro:content';

export const ALLOWED_CATEGORIES = [
  "checklists","guides","tips","how-to","case-studies","client-stories",
  "bond-back","end-of-lease","inspections","agent-requirements","pricing",
  "diy-vs-pro","appliance-cleaning","room-by-room","real-estate"
] as const;

export const ALLOWED_TAGS = [
  "bond-cleaning","real-estate","inspection","checklist","steam-cleaning",
  "carpet-cleaning","stain-removal","success-stories","testimonials","eco-friendly",
  "end-of-lease","agent-requirements","pricing","diy-vs-pro"
] as const;

export const ALLOWED_REGIONS = ["brisbane", "ipswich", "logan"] as const;

const posts = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string().min(4),
    description: z.string().min(10),
    publishDate: z.string().transform((s)=>new Date(s)),
    categories: z.array(z.enum(ALLOWED_CATEGORIES)).nonempty(),
    tags: z.array(z.enum(ALLOWED_TAGS)).default([]),
    region: z.enum(ALLOWED_REGIONS),
    author: z.string().default('One N Done Bond Clean'),
    draft: z.boolean().default(false)
  })
});
export const collections = { posts };
TS

# ========== 6) Blog pages ==========
cat > src/lib/blog.ts <<'TS'
import { getCollection, type CollectionEntry } from 'astro:content';
export async function getAllPosts(): Promise<CollectionEntry<'posts'>[]> {
  const all = await getCollection('posts', p => !p.data.draft);
  return all.sort((a,b) => +b.data.publishDate - +a.data.publishDate);
}
export function paginate<T>(items: T[], pageSize = 12) {
  const total = Math.ceil(items.length / pageSize);
  return (page = 1) => ({ page, pageSize, total, items: items.slice((page-1)*pageSize, (page)*pageSize) });
}
TS

cat > src/pages/blog/index.astro <<'ASTRO'
---
import BaseLayout from "@/layouts/BaseLayout.astro";
import { getAllPosts, paginate } from "@/lib/blog";
const posts = await getAllPosts();
const pager = paginate(posts, 12)(1);
const canonical = "/blog/";
---
<BaseLayout title="Blog | One N Done" description="Guides, checklists and tips for end-of-lease and spring cleaning." canonical={canonical}>
  <h1 class="text-3xl font-extrabold mb-4">Blog</h1>
  <ul class="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
    {pager.items.map(({ slug, data }) => (
      <li class="border rounded-lg p-4 hover:shadow-sm transition">
        <a class="text-lg font-semibold hover:text-sky-700" href={`/blog/${slug}/`}>{data.title}</a>
        <p class="text-sm text-slate-600 mt-1">{data.description}</p>
        <p class="mt-2 text-xs text-slate-500">{new Date(data.publishDate).toLocaleDateString('en-AU')}</p>
      </li>
    ))}
  </ul>
</BaseLayout>
ASTRO

cat > src/pages/blog/[slug].astro <<'ASTRO'
---
import BaseLayout from "@/layouts/BaseLayout.astro";
import { getEntryBySlug } from 'astro:content';
const { slug } = Astro.params;
const post = await getEntryBySlug('posts', slug!);
if (!post) { Astro.response.status = 404; }
const title = post ? `${post.data.title} | Blog` : 'Not found';
const canonical = post ? `/blog/${post.slug}/` : '/blog/';
function safeJsonLd(o:any){ return JSON.stringify(o).replace(/</g,"\\u003c"); }
const articleLD = post && {
  "@context":"https://schema.org","@type":"Article",
  headline: post.data.title, datePublished: post.data.publishDate,
  author: { "@type":"Organization", name: post.data.author }
};
---
<BaseLayout title={title} description={post?.data.description} canonical={canonical}>
  {post ? (
    <>
      <h1 class="text-3xl md:text-4xl font-extrabold mb-3">{post.data.title}</h1>
      <p class="text-slate-600 mb-6">{post.data.description}</p>
      <article class="prose max-w-none">
        <Content />
      </article>
      <script type="application/ld+json" set:html={safeJsonLd(articleLD)} />
    </>
  ) : <p>Not found.</p>}
</BaseLayout>
ASTRO

cat > src/pages/blog/rss.xml.ts <<'TS'
import rss from '@astrojs/rss';
import { getAllPosts } from '@/lib/blog';
export async function GET(context) {
  const site = context.site?.toString().replace(/\/$/, '') || '';
  const posts = await getAllPosts();
  return rss({
    title: 'One N Done — Blog',
    description: 'Guides, checklists and tips for bond cleaning.',
    site,
    items: posts.slice(0, 50).map(p => ({
      link: `/blog/${p.slug}/`,
      title: p.data.title,
      description: p.data.description,
      pubDate: p.data.publishDate
    })),
  });
}
TS

# ========== 7) Geo core (SSR-safe loaders, proximity) ==========
cat > src/lib/suburbs.ts <<'TS'
type ClusterRec = { slug: string; name: string; suburbs: { slug: string; name: string; lat?: number; lng?: number }[] };
type ClustersFile = { clusters: ClusterRec[] };
const clustersMods = import.meta.glob('/src/data/areas.clusters.json', { eager: true, import: 'default' }) as Record<string, ClustersFile | undefined>;
const clusterMapMods = import.meta.glob('/src/data/cluster_map.json', { eager: true, import: 'default' }) as Record<string, Record<string,string> | undefined>;
const CLUSTERS: ClustersFile = Object.values(clustersMods)[0] ?? { clusters: [] };
const CLUSTER_TO_REGION: Record<string,string> = Object.values(clusterMapMods)[0] ?? {};
const SUBURB_TO_CLUSTER = (() => { const m = new Map<string,string>(); for (const c of CLUSTERS.clusters) for (const s of c.suburbs) m.set(s.slug, c.slug); return m; })();
export type Suburb = { slug: string; name: string; lat?: number; lng?: number; cluster?: string; region?: string };
export function getAllSuburbs(): Suburb[] {
  const out: Suburb[] = []; for (const c of CLUSTERS.clusters) { const region = CLUSTER_TO_REGION[c.slug];
    for (const s of c.suburbs) out.push({ ...s, cluster: c.slug, region }); } return out;
}
export function findSuburbBySlug(slug: string): Suburb | null {
  const cl = SUBURB_TO_CLUSTER.get(slug); if (!cl) return null;
  const cluster = CLUSTERS.clusters.find(c => c.slug === cl); const rec = cluster?.suburbs.find(s => s.slug === slug);
  if (!rec) return null; const region = CLUSTER_TO_REGION[cluster!.slug]; return { ...rec, cluster: cluster!.slug, region };
}
TS

cat > src/lib/geo/proximity.ts <<'TS'
import { findSuburbBySlug, getAllSuburbs } from '@/lib/suburbs';
type NearbyItem = { slug: string; name: string };
type ProximityFile = { nearby: Record<string, NearbyItem[]> };
type AdjacencyFile = Record<string, string[]>;
type GeoCfg = { nearby?: { limit?: number }, adjacencyBoost?: number, clusterBoost?: number, biasKm?: number, crossClusterPenalty?: number };
const proxMods = import.meta.glob('/src/data/proximity.json', { eager: true, import: 'default' }) as Record<string, ProximityFile | undefined>;
const adjMods  = import.meta.glob('/src/data/areas.adj.json', { eager: true, import: 'default' }) as Record<string, AdjacencyFile | undefined>;
const cfgMods  = import.meta.glob('/src/data/geo.config.json', { eager: true, import: 'default' }) as Record<string, GeoCfg | undefined>;
const PROX = Object.values(proxMods)[0] ?? { nearby: {} };
const ADJ  = Object.values(adjMods)[0]  ?? {};
const CFG  = Object.values(cfgMods)[0]  ?? {};
const LIMIT = Math.max(1, Number(CFG?.nearby?.limit ?? 6));
const W = { adjacency: Number(CFG?.adjacencyBoost ?? 24), cluster: Number(CFG?.clusterBoost ?? 200), biasKm: Number(CFG?.biasKm ?? 12), crossPenalty: Number(CFG?.crossClusterPenalty ?? 200) };
function haversineKm(a:{lat:number,lng:number}, b:{lat:number,lng:number}){const toRad=(x:number)=>x*Math.PI/180,R=6371;const dLat=toRad(b.lat-a.lat),dLng=toRad(b.lng-a.lng);const s=Math.sin(dLat/2)**2+Math.cos(toRad(a.lat))*Math.cos(toRad(b.lat))*Math.sin(dLng/2)**2;return 2*R*Math.asin(Math.sqrt(s));}
export function findNearbySuburbs(sourceSlug: string, opts?: { limit?: number }) {
  const limit = Math.max(1, opts?.limit ?? LIMIT);
  const src = findSuburbBySlug(sourceSlug); if (!src) return [];
  const pre = PROX.nearby?.[sourceSlug] || []; if (pre.length) return pre.slice(0, limit);
  const seed = (ADJ[sourceSlug] || []).map(slug => findSuburbBySlug(slug)).filter(Boolean).map(s=>({slug:s!.slug,name:s!.name}));
  if (seed.length >= limit) return seed.slice(0, limit);
  const pool = getAllSuburbs().filter(s => s.slug !== sourceSlug);
  const withScore = pool.map(s => {
    let score = 0; const sameCluster = src.cluster && s.cluster && src.cluster === s.cluster;
    if ((ADJ[sourceSlug] || []).includes(s.slug)) score += W.adjacency;
    score += sameCluster ? W.cluster : -W.crossPenalty;
    if (typeof src.lat==='number'&&typeof src.lng==='number'&&typeof s.lat==='number'&&typeof s.lng==='number'){ const km=haversineKm({lat:src.lat!,lng:src.lng!},{lat:s.lat!,lng:s.lng!}); score += -W.biasKm*km; }
    return { s, score };
  }).sort((a,b)=> b.score - a.score);
  const uniq = new Map<string, NearbyItem>();
  for (const { s } of [ ...seed.map(x=>({ s: x })), ...withScore ]) {
    const slug = (s as any).slug, name = (s as any).name; if (!slug || uniq.has(slug)) continue; uniq.set(slug, { slug, name }); if (uniq.size >= limit) break;
  }
  return Array.from(uniq.values()).slice(0, limit);
}
TS

# ========== 8) Components (Nearby, caps respected) ==========
cat > src/components/NearbySuburbs.astro <<'ASTRO'
---
import { findNearbySuburbs } from '@/lib/geo/proximity';
import { findSuburbBySlug } from '@/lib/suburbs';
interface Props { suburbSlug: string; title?: string; limit?: number; }
const { suburbSlug, title = 'Nearby suburbs we cover', limit = 6 } = Astro.props as Props;
const src = findSuburbBySlug(suburbSlug);
const items = findNearbySuburbs(suburbSlug, { limit }).map((s, i) => ({ ...s, position: i+1, href: `/suburbs/${s.slug}/` }));
const ld = { "@context":"https://schema.org","@type":"ItemList", itemListElement: items.map(it => ({"@type":"ListItem", position: it.position, url: it.href, name: `Bond cleaning in ${it.name}`})) };
function safeJsonLd(o:any){ return JSON.stringify(o).replace(/</g,"\\u003c"); }
---
{items.length > 0 && (
<section aria-labelledby="nearby-heading" class="mt-8" data-invariant="nearby">
  <h2 id="nearby-heading" class="text-xl font-semibold">{title}</h2>
  <ul class="mt-3 grid gap-2 sm:grid-cols-2" data-role="nearby-ui">
    {items.map(it => (<li><a href={it.href} class="underline hover:no-underline" data-href={it.href}>{it.name}</a></li>))}
  </ul>
  <script type="application/ld+json" set:html={safeJsonLd(ld)} data-role="nearby-ld" />
</section>
)}
ASTRO

# ========== 9) Services registry & pages ==========
cat > src/lib/services.ts <<'TS'
export type ServiceId = 'bathroom-deep-clean' | 'spring-clean';
export interface ServiceDef { slug: ServiceId; title: string; description: string; checklist: string[]; ctaLabel: string; }
export const SERVICES: ServiceDef[] = [
  { slug: 'bathroom-deep-clean', title: 'Bathroom Deep Clean', description: 'Reset showers, glass, grout, and fixtures to inspection-ready condition.', ctaLabel: 'Book a Bathroom Deep Clean', checklist: [
    'Shower glass & screen de-scaled and polished',
    'Tiles & grout lines scrubbed; corners detailed',
    'Toilet incl. hinges, base & cistern wiped',
    'Vanity, taps & mirror polished (no streaks)',
    'Exhaust vents dusted; light fittings wiped',
    'Floors vacuumed & mopped (edges/corners)'
  ]},
  { slug: 'spring-clean', title: 'Spring Clean', description: 'Whole-home reset: dusting, kitchen/bath refresh, and floors.', ctaLabel: 'Get a Spring Clean Quote', checklist: [
    'High/low dust: skirting, sills, ledges, fans (reachable)',
    'Switches, power points, and handles wiped',
    'Kitchen benches & fronts wiped; splashback de-greased',
    'Bathrooms refreshed (fixtures & glass)',
    'Windows (reachable) and mirrors polished',
    'Floors vacuumed & mopped'
  ]}
];
export function findService(slug: string){ return SERVICES.find(s => s.slug === slug) ?? null; }
export function otherServices(current: ServiceId){ return SERVICES.filter(s => s.slug !== current); }
TS

cat > src/pages/services/index.astro <<'ASTRO'
---
import BaseLayout from '@/layouts/BaseLayout.astro';
import { SERVICES } from '@/lib/services';
import { getAllSuburbs } from '@/lib/suburbs';
const canonical = '/services/';
const sampleSuburb = getAllSuburbs()[0]?.slug;
---
<BaseLayout title="Services | One N Done Bond Clean" description="Bathroom Deep Clean and Spring Clean across Brisbane, Ipswich and Logan." canonical={canonical}>
  <h1 class="text-3xl font-extrabold mb-4">Services</h1>
  <ul class="grid gap-4 sm:grid-cols-2">
    {SERVICES.map(s => (
      <li class="border rounded p-4">
        <h2 class="text-xl font-bold">{s.title}</h2>
        <p class="text-slate-600 mt-1">{s.description}</p>
        {sampleSuburb
          ? <p class="mt-2 text-sm"><a class="underline hover:text-sky-700" href={`/services/${s.slug}/${sampleSuburb}/`}>Browse in a suburb →</a></p>
          : <p class="mt-2 text-sm text-slate-500">Add suburb data to enable per-suburb pages.</p>}
      </li>
    ))}
  </ul>
</BaseLayout>
ASTRO

mkdir -p src/pages/services/[service]
cat > src/pages/services/[service]/[suburb].astro <<'ASTRO'
---
import BaseLayout from '@/layouts/BaseLayout.astro';
import { findService, otherServices, type ServiceId } from '@/lib/services';
import { findSuburbBySlug, getAllSuburbs } from '@/lib/suburbs';
import NearbySuburbs from '@/components/NearbySuburbs.astro';

export const prerender = true;
export const trailingSlash = 'always';

export async function getStaticPaths() {
  const subs = getAllSuburbs().map(s => s.slug);
  const services: ServiceId[] = ['bathroom-deep-clean','spring-clean'];
  const paths = [];
  for (const suburb of subs) for (const service of services) paths.push({ params: { service, suburb } });
  return paths;
}

const { service: serviceSlug = '', suburb: suburbSlug = '' } = Astro.params;
const svc = findService(serviceSlug); const sub = findSuburbBySlug(suburbSlug);
const ok = Boolean(svc && sub);
const canonical = ok ? `/services/${svc!.slug}/${sub!.slug}/` : '/services/';
const site = Astro.site?.toString().replace(/\/$/, '') || '';
let title = 'Not found', description = 'Page not found.';
if (ok) { title = `${svc!.title} in ${sub!.name} | One N Done Bond Clean`; description = `${svc!.description} — Servicing ${sub!.name} and nearby areas.`; }
const ld = ok && {
  "@context":"https://schema.org","@type":"Service","@id":`${site}${canonical}#service`,
  name: `${svc!.title} in ${sub!.name}`, serviceType: svc!.title,
  areaServed: { "@type":"City", name: sub!.name, containedInPlace: { "@type":"AdministrativeArea", name: sub!.region || 'QLD' } },
  provider: { "@type":"LocalBusiness", "@id": `${site}#business` },
  offers: { "@type":"Offer", priceCurrency:"AUD", availability:"https://schema.org/InStock", url: `${site}${canonical}` }
};
function safeJsonLd(o:any){ return JSON.stringify(o).replace(/</g,"\\u003c"); }
---
<BaseLayout title={title} description={description} canonical={canonical}>
  {ok ? (
    <>
      <header class="mb-8">
        <h1 class="text-4xl font-extrabold tracking-tight">{svc!.title} <span class="text-sky-700">in {sub!.name}</span></h1>
        <p class="mt-3 text-slate-700 max-w-2xl">{svc!.description}</p>
        <div class="mt-6">
          <a href="/quote/" class="inline-flex items-center gap-3 bg-sky-700 text-white font-bold py-3 px-6 rounded-full shadow hover:bg-sky-800">
            {svc!.ctaLabel}
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
          </a>
        </div>
      </header>

      <section class="mb-10">
        <h2 class="text-2xl font-bold mb-4">What's included</h2>
        <ul class="grid sm:grid-cols-2 gap-3">
          {svc!.checklist.map(item => (
            <li class="flex items-start gap-2">
              <span class="mt-1 w-2 h-2 rounded-full bg-sky-600"></span>
              <span>{item}</span>
            </li>
          ))}
        </ul>
      </section>

      <section class="mb-8">
        <h2 class="text-xl font-semibold mb-3">More in {sub!.name}</h2>
        <ul class="flex flex-wrap gap-3 text-sm">
          {otherServices(svc!.slug).map(o => (
            <li><a class="px-3 py-1 rounded-full border hover:bg-slate-50" href={`/services/${o.slug}/${sub!.slug}/`}>{o.title}</a></li>
          ))}
          <li><a class="px-3 py-1 rounded-full border hover:bg-slate-50" href={`/suburbs/${sub!.slug}/`}>Suburb page</a></li>
          <li><a class="px-3 py-1 rounded-full border hover:bg-slate-50" href="/blog/">Local guides</a></li>
        </ul>
      </section>

      <NearbySuburbs suburbSlug={sub!.slug} title="Other nearby areas" />
      <script type="application/ld+json" set:html={safeJsonLd(ld)} />
    </>
  ) : (
    <>
      {Astro.response.status = 404}
      <h1 class="text-3xl font-extrabold mb-2">Page not found</h1>
      <p class="text-slate-700 mb-6">We couldn't find that service/suburb combination.</p>
      <a class="underline" href="/services/">Browse services</a>
    </>
  )}
</BaseLayout>
ASTRO

# ========== 10) Suburb pages ==========
cat > src/pages/suburbs/index.astro <<'ASTRO'
---
import BaseLayout from '@/layouts/BaseLayout.astro';
import { getAllSuburbs } from '@/lib/suburbs';
const list = getAllSuburbs();
const byRegion = new Map<string, typeof list>();
for (const s of list) { const k = s.region ?? 'unknown'; byRegion.set(k, [ ...(byRegion.get(k)||[]), s ]); }
const canonical = '/suburbs/';
---
<BaseLayout title="Suburbs | One N Done Bond Clean" description="Browse suburbs we write about and service." canonical={canonical}>
  <h1 class="text-3xl font-extrabold mb-6">Suburbs</h1>
  {Array.from(byRegion.entries()).map(([region, subs]) => (
    <section class="mb-8">
      <h2 class="text-xl font-bold mb-3">{region[0]?.toUpperCase()}{region.slice(1)}</h2>
      <ul class="flex flex-wrap gap-3">
        {subs.map(s => (<li><a class="px-3 py-1 rounded-full border hover:bg-slate-50" href={`/suburbs/${s.slug}/`}>{s.name}</a></li>))}
      </ul>
    </section>
  ))}
</BaseLayout>
ASTRO

cat > src/pages/suburbs/[suburb].astro <<'ASTRO'
---
import BaseLayout from '@/layouts/BaseLayout.astro';
import { findSuburbBySlug } from '@/lib/suburbs';
import NearbySuburbs from '@/components/NearbySuburbs.astro';
import { getAllPosts } from '@/lib/blog';

export async function getStaticPaths() {
  const mods = import.meta.glob('/src/data/areas.clusters.json', { eager: true, import: 'default' }) as Record<string, { clusters: { suburbs: { slug: string }[] }[] } | undefined>;
  const data = Object.values(mods)[0];
  const slugs = data ? data.clusters.flatMap(c => c.suburbs.map(s => s.slug)) : [];
  return slugs.map(suburb => ({ params: { suburb } }));
}

const { suburb: slug } = Astro.params;
const sub = findSuburbBySlug(slug);
if (!sub) Astro.response.status = 404;

const posts = await getAllPosts();
const related = posts.filter(p => p.data.region === sub?.region).slice(0, 9);

const title = sub ? `Bond Cleaning in ${sub.name} | One N Done` : 'Not found';
const description = sub ? `Pricing, tips and guides for ${sub.name} and surrounding areas.` : '';
const canonical = sub ? `/suburbs/${sub.slug}/` : '/suburbs/';
const ld = sub && {
  "@context": "https://schema.org","@type": "Service",
  name: `Bond Cleaning in ${sub.name}`,
  areaServed: { "@type": "City", name: sub.name, containedInPlace: { "@type": "AdministrativeArea", name: sub.region ?? '' } },
  provider: { "@type": "LocalBusiness", "@id": (Astro.site?.toString().replace(/\/$/, '') || '') + "#business" }
};
function safeJsonLd(o:any){ return JSON.stringify(o).replace(/</g,"\\u003c"); }
---
<BaseLayout title={title} description={description} canonical={canonical}>
  {sub ? (
    <>
      <h1 class="text-3xl md:text-4xl font-extrabold mb-2">Bond Cleaning in {sub.name}</h1>
      <p class="text-slate-700 mb-6">Serving {sub.name}{sub.region ? ` (${sub.region})` : ''} and nearby suburbs.</p>

      <section class="mb-8">
        <h2 class="text-xl font-semibold mb-3">Popular services in {sub.name}</h2>
        <ul class="flex flex-wrap gap-3 text-sm">
          <li><a class="px-3 py-1 rounded-full border hover:bg-slate-50" href={`/services/bathroom-deep-clean/${sub.slug}/`}>Bathroom Deep Clean</a></li>
          <li><a class="px-3 py-1 rounded-full border hover:bg-slate-50" href={`/services/spring-clean/${sub.slug}/`}>Spring Clean</a></li>
        </ul>
      </section>

      <NearbySuburbs suburbSlug={sub.slug} title="Other nearby areas" />

      {related.length > 0 && (
        <section class="mt-10">
          <h2 class="text-xl font-bold mb-3">Recent articles for {sub.region}</h2>
          <ul class="grid gap-4 md:grid-cols-2">
            {related.map((p) => (
              <li class="border rounded p-4 hover:shadow-sm transition">
                <a href={`/blog/${p.slug}/`} class="text-lg font-semibold hover:text-sky-700">{p.data.title}</a>
                <p class="text-slate-600 mt-1">{p.data.description}</p>
              </li>
            ))}
          </ul>
        </section>
      )}

      <script type="application/ld+json" set:html={safeJsonLd(ld)} />
    </>
  ) : <p>Suburb not found.</p>}
</BaseLayout>
ASTRO

# ========== 11) Sitemap ==========
cat > src/pages/sitemap.xml.ts <<'TS'
import { getAllSuburbs } from '@/lib/suburbs';
import { SERVICES } from '@/lib/services';
export async function GET({ site }) {
  const base = site?.toString().replace(/\/$/, '') || '';
  const urls: string[] = [
    '/', '/blog/', '/blog/rss.xml', '/suburbs/', '/services/'
  ];
  for (const s of getAllSuburbs()) {
    urls.push(`/suburbs/${s.slug}/`);
    for (const svc of SERVICES) urls.push(`/services/${svc.slug}/${s.slug}/`);
  }
  const body = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n` +
    urls.map(u=>`  <url><loc>${base}${u}</loc></url>`).join('\n') + '\n</urlset>\n';
  return new Response(body, { headers: { 'Content-Type': 'application/xml' } });
}
TS

# ========== 12) Geo Doctor ==========
cat > scripts/geo/geo-doctor.mjs <<'JS'
#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path';
const DATA='src/data', OUT='__ai', TMP='tmp';
const p=(f)=>path.join(DATA,f);
const files={clusters:p('areas.clusters.json'), clusterMap:p('cluster_map.json'), adj:p('areas.adj.json'), prox:p('proximity.json'), cfg:p('geo.config.json')};
const read=(file,def)=>{try{if(!fs.existsSync(file))return{ok:false,err:'ENOENT',data:def};const r=fs.readFileSync(file,'utf8');return{ok:true,err:null,data:JSON.parse(r)}}catch(e){return{ok:false,err:String(e),data:def}}}
const clusters=read(files.clusters,{clusters:[]}), cmap=read(files.clusterMap,{}), adj=read(files.adj,{}), prox=read(files.prox,{nearby:{}}), cfg=read(files.cfg,{});
const issues={missing:[],schema:[],ref:[],warn:[],policy:[]}; const isStr=x=>typeof x==='string'&&x.trim(); const isNum=x=>typeof x==='number'&&Number.isFinite(x);
const clusterSlugs=[]; const subIndex=new Map(); const seenNames=new Set();

if(!clusters.ok) issues.missing.push(`Missing ${files.clusters}: ${clusters.err}`);
else if(!Array.isArray(clusters.data?.clusters)) issues.schema.push(`${files.clusters} must be {clusters:[]}`);
else for(const c of clusters.data.clusters){
  if(!isStr(c?.slug)) issues.schema.push(`Cluster missing slug`);
  else clusterSlugs.push(c.slug);
  if(!Array.isArray(c?.suburbs)) { issues.schema.push(`Cluster ${c?.slug} suburbs[] missing`); continue; }
  for(const s of c.suburbs){
    if(!isStr(s?.slug)) issues.schema.push(`Suburb in ${c?.slug} missing slug`);
    if(!isStr(s?.name)) issues.schema.push(`Suburb ${s?.slug} missing name`);
    if(subIndex.has(s.slug)) issues.schema.push(`Duplicate suburb slug "${s.slug}"`);
    if(seenNames.has(s.name?.toLowerCase())) issues.warn.push(`Duplicate suburb name "${s.name}"`);
    subIndex.set(s.slug,{name:s.name,lat:s.lat,lng:s.lng,cluster:c.slug});
    seenNames.add(s.name?.toLowerCase());
  }
}

if(cmap.ok) for(const k of Object.keys(cmap.data||{})) if(!clusterSlugs.includes(k)) issues.ref.push(`cluster_map references unknown cluster "${k}"`);
else issues.warn.push('cluster_map.json missing — region will be undefined');

if(adj.ok) for(const [src,list] of Object.entries(adj.data||{})){
  if(!subIndex.has(src)) issues.ref.push(`adjacency source "${src}" not in clusters`);
  if(!Array.isArray(list)) { issues.schema.push(`adjacency["${src}"] must be array`); continue; }
  for(const dst of list){ if(src===dst) issues.schema.push(`adjacency "${src}" contains self`); if(!subIndex.has(dst)) issues.ref.push(`adjacency "${src}" -> "${dst}" not in clusters`); }
}

if(prox.ok){ const n=prox.data?.nearby||{}; for(const [src,arr] of Object.entries(n)){
  if(!subIndex.has(src)) { issues.ref.push(`proximity source "${src}" not in clusters`); continue; }
  if(!Array.isArray(arr)) { issues.schema.push(`proximity["${src}"] must be array`); continue; }
  const seen=new Set();
  for(const it of arr){ if(!isStr(it?.slug)) issues.schema.push(`proximity["${src}"] item missing slug`);
    if(it?.slug===src) issues.schema.push(`proximity["${src}"] contains self`);
    if(seen.has(it?.slug)) issues.schema.push(`proximity["${src}"] duplicate "${it?.slug}"`);
    seen.add(it?.slug); if(it?.slug && !subIndex.has(it.slug)) issues.ref.push(`proximity["${src}"] -> "${it.slug}" not in clusters`);
  }
}}

let missLatLng=0,bad=0,zero=0; for(const [slug,r] of subIndex){ if(!isNum(r.lat)||!isNum(r.lng)) missLatLng++; else if(r.lat===0&&r.lng===0) zero++; else if(r.lat<-90||r.lat>90||r.lng<-180||r.lng>180) bad++; }
if(missLatLng) issues.warn.push(`${missLatLng} suburbs missing lat/lng`);
if(zero) issues.schema.push(`${zero} suburbs have lat/lng == 0 (placeholder)`);
if(bad) issues.schema.push(`${bad} suburbs with out-of-range coordinates`);

// Policy invariants: caps and consistency will be validated post-build; here we emit smoke paths
const first=[...subIndex.keys()].slice(0,6);
const paths=['/suburbs/','/services/', ...first.map(s=>`/suburbs/${s}/`), ...first.flatMap(s=>[`/services/spring-clean/${s}/`,`/services/bathroom-deep-clean/${s}/`])];
fs.mkdirSync(TMP,{recursive:true}); fs.writeFileSync(path.join(TMP,'smoke-paths.json'), JSON.stringify({paths},null,2));

const report={ timestamp:new Date().toISOString(), files:{...files}, counts:{clusters:clusterSlugs.length, suburbs:subIndex.size, adjacency: Object.keys(adj.data||{}).length, proximity: Object.keys(prox.data?.nearby||{}).length}, issues };
fs.mkdirSync(OUT,{recursive:true}); fs.writeFileSync(path.join(OUT,'geo-report.json'), JSON.stringify(report,null,2));
fs.writeFileSync(path.join(OUT,'geo-report.txt'), `Geo Doctor
Time: ${report.timestamp}
clusters: ${report.counts.clusters}
suburbs: ${report.counts.suburbs}
adjacency sources: ${report.counts.adjacency}
proximity sources: ${report.counts.proximity}

missing: ${issues.missing.length}
schema: ${issues.schema.length}
referential: ${issues.ref.length}
warnings: ${issues.warn.length}

Top messages:
${[...issues.missing,...issues.schema,...issues.ref,...issues.warn].slice(0,20).map(s=>' - '+s).join('\n')||' (none)'}
`);
const STRICT = process.argv.includes('--strict') || process.env.CI;
const fatal = [];
if(!clusters.ok) fatal.push('clusters missing/invalid');
if(issues.schema.length) fatal.push('schema errors');
if(issues.ref.length) fatal.push('referential errors');
if(STRICT && fatal.length){ console.error('[geo-doctor] FAIL:', fatal.join(', ')); process.exit(1); }
console.log('[geo-doctor] OK — see __ai/geo-report.* and tmp/smoke-paths.json');
JS
chmod +x scripts/geo/geo-doctor.mjs

# ========== 13) SEO DOM scanner (happy-dom) ==========
cat > scripts/seo/report-hardcoded-seo.mjs <<'MJS'
#!/usr/bin/env node
import fs from "node:fs"; import path from "node:path"; import { Window } from "happy-dom";
const DIST="dist", OUT="__ai"; if (!fs.existsSync(DIST)) { console.log("[seo] dist/ not found; run build."); process.exit(0); }
function* walk(dir){ for(const e of fs.readdirSync(dir,{withFileTypes:true})){ const full=path.join(dir,e.name); if(e.isDirectory()) yield* walk(full); else if(e.isFile()&&e.name.endsWith(".html")) yield full; } }
const pages=[]; for(const file of walk(DIST)){ const html=fs.readFileSync(file,"utf8"); const win=new Window(); const doc=win.document; doc.body.innerHTML=html;
  const canonical=doc.querySelector('link[rel="canonical"]')?.getAttribute('href') || null;
  const ld=[...doc.querySelectorAll('script[type="application/ld+json"]')].map(s=>s.textContent||'').map(t=>{try{return JSON.parse(t);}catch(e){return {__parseError:String(e.message||e), raw:t.slice(0,500)};}});
  const rel="/"+path.relative(DIST,file).split(path.sep).join("/");
  pages.push({ page:rel, canonical, jsonld: ld });
}
fs.mkdirSync(OUT,{recursive:true}); fs.writeFileSync(path.join(OUT,"hardcoded-seo.json"), JSON.stringify(pages,null,2));
const summary={ pages:pages.length, withoutCanonical: pages.filter(p=>!p.canonical).length, jsonldBlocks: pages.reduce((n,p)=>n+p.jsonld.length,0), jsonldErrors: pages.reduce((n,p)=> n+ p.jsonld.filter(x=>x.__parseError).length,0) };
fs.writeFileSync(path.join(OUT,"hardcoded-seo-summary.json"), JSON.stringify(summary,null,2));
console.log(`[seo] pages=${summary.pages} canonicals-missing=${summary.withoutCanonical} jsonld-errors=${summary.jsonldErrors}`);
process.exit(0);
MJS
chmod +x scripts/seo/report-hardcoded-seo.mjs

# ========== 14) Transparent Lift Pack — invariants ==========
# 14.1 Anchor diversity & caps
cat > scripts/invariants/anchor-linter.mjs <<'JS'
#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import { Window } from 'happy-dom';
const DIST='dist'; if(!fs.existsSync(DIST)) { console.log('[inv:anchors] dist/ missing'); process.exit(0); }
const MAX_COMMERCIAL_REPEAT = 3; // same anchor text cap per page
const COMMERCIAL_WORDS = /(bond|clean|quote|bathroom|spring|service)/i;

function* walk(dir){ for(const e of fs.readdirSync(dir,{withFileTypes:true})){ const full=path.join(dir,e.name); if(e.isDirectory()) yield* walk(full); else if(e.isFile()&&e.name.endsWith('.html')) yield full; } }
let issues=0;
for(const file of walk(DIST)){
  const html=fs.readFileSync(file,'utf8'); const win=new Window(); const doc=win.document; doc.body.innerHTML=html;
  const anchors=[...doc.querySelectorAll('a')].map(a=>({ text:(a.textContent||'').trim().toLowerCase(), href:a.getAttribute('href')||'' }));
  const freq=new Map(); for(const a of anchors){ if(COMMERCIAL_WORDS.test(a.text)) freq.set(a.text, (freq.get(a.text)||0)+1); }
  for(const [text,count] of freq){ if(count>MAX_COMMERCIAL_REPEAT){ console.error(`[inv:anchors] ${file}: anchor "${text}" repeats ${count}x`); issues++; } }
}
if(issues){ process.exit(1); }
console.log('[inv:anchors] OK');
JS
chmod +x scripts/invariants/anchor-linter.mjs

# 14.2 Schema↔UI lockstep for NearbySuburbs (ItemList vs visible list)
cat > scripts/invariants/schema-lockstep.mjs <<'JS'
#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import { Window } from 'happy-dom';
const DIST='dist'; if(!fs.existsSync(DIST)) { console.log('[inv:lockstep] dist/ missing'); process.exit(0); }
function* walk(dir){ for(const e of fs.readdirSync(dir,{withFileTypes:true})){ const full=path.join(dir,e.name); if(e.isDirectory()) yield* walk(full); else if(e.isFile()&&e.name.endsWith('.html')) yield full; } }
let issues=0;
for(const file of walk(DIST)){
  const html=fs.readFileSync(file,'utf8'); const win=new Window(); const doc=win.document; doc.body.innerHTML=html;
  const section=doc.querySelector('[data-invariant="nearby"]'); if(!section) continue;
  const ui=[...section.querySelectorAll('[data-role="nearby-ui"] a')].map(a=>a.getAttribute('href')).filter(Boolean);
  const ldNode=section.querySelector('script[type="application/ld+json"][data-role="nearby-ld"]');
  if(!ldNode){ console.error(`[inv:lockstep] ${file}: missing nearby JSON-LD`); issues++; continue; }
  let ld; try{ ld=JSON.parse(ldNode.textContent||'{}'); }catch{ console.error(`[inv:lockstep] ${file}: invalid nearby JSON-LD`); issues++; continue; }
  const ldUrls=(ld?.itemListElement||[]).map((x)=>x?.url).filter(Boolean);
  if(ldUrls.length!==ui.length || ldUrls.some((u,i)=>u!==ui[i])){ console.error(`[inv:lockstep] ${file}: nearby UI and JSON-LD differ`); issues++; }
  if(ui.length>6){ console.error(`[inv:lockstep] ${file}: nearby list exceeds cap (6)`); issues++; }
}
if(issues){ process.exit(1); }
console.log('[inv:lockstep] OK');
JS
chmod +x scripts/invariants/schema-lockstep.mjs

# 14.3 No UA-based DOM differences (grep bundles for navigator.userAgent)
cat > scripts/invariants/no-ua-dom.mjs <<'JS'
#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path';
const DIST='dist'; if(!fs.existsSync(DIST)) { console.log('[inv:no-ua] dist/ missing'); process.exit(0); }
function* walk(dir){ for(const e of fs.readdirSync(dir,{withFileTypes:true})){ const full=path.join(dir,e.name); if(e.isDirectory()) yield* walk(full); else if(e.isFile()&&(e.name.endsWith('.js')||e.name.endsWith('.mjs'))) yield full; } }
let issues=0;
for(const file of walk(DIST)){ const s=fs.readFileSync(file,'utf8'); if(/navigator\.userAgent/.test(s)) { console.error(`[inv:no-ua] ${file}: found navigator.userAgent`); issues++; } }
if(issues) process.exit(1); console.log('[inv:no-ua] OK');
JS
chmod +x scripts/invariants/no-ua-dom.mjs

# 14.4 No hidden keyword stuffing in content zones
cat > scripts/invariants/no-hidden-keywords.mjs <<'JS'
#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import { Window } from 'happy-dom';
const DIST='dist'; if(!fs.existsSync(DIST)) { console.log('[inv:no-hidden] dist/ missing'); process.exit(0); }
const KEYWORDS=/\b(bond|clean|spring|bathroom|end[- ]?of[- ]?lease)\b/i;
function* walk(dir){ for(const e of fs.readdirSync(dir,{withFileTypes:true})){ const full=path.join(dir,e.name); if(e.isDirectory()) yield* walk(full); else if(e.isFile()&&e.name.endsWith('.html')) yield full; } }
let issues=0;
for(const file of walk(DIST)){
  const html=fs.readFileSync(file,'utf8'); const win=new Window(); const doc=win.document; doc.body.innerHTML=html;
  const suspects=[...doc.querySelectorAll('[style*="display:none" i], [aria-hidden="true"]')];
  for(const el of suspects){ const t=(el.textContent||'').trim(); if(t && KEYWORDS.test(t)){ console.error(`[inv:no-hidden] ${file}: hidden keyword content detected`); issues++; } }
}
if(issues) process.exit(1); console.log('[inv:no-hidden] OK');
JS
chmod +x scripts/invariants/no-hidden-keywords.mjs

# 14.5 Sitemap invariants (200 + self-canonical + internal link presence)
cat > scripts/invariants/sitemap-check.mjs <<'JS'
#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import { Window } from 'happy-dom';
const DIST='dist'; if(!fs.existsSync(DIST)) { console.log('[inv:sitemap] dist/ missing'); process.exit(0); }
const sm = path.join(DIST,'sitemap.xml'); if(!fs.existsSync(sm)) { console.log('[inv:sitemap] sitemap.xml missing (page-based sitemap)'); process.exit(0); }
const xml=fs.readFileSync(sm,'utf8');
const urls=[...xml.matchAll(/<loc>([^<]+)<\/loc>/g)].map(m=>m[1]);
let issues=0;
for(const u of urls){
  const rel = u.replace(/^https?:\/\/[^/]+/,''); const f = path.join(DIST, rel.replace(/\/$/,'/index.html'));
  if(!fs.existsSync(f)) { console.error(`[inv:sitemap] ${u}: not found in dist`); issues++; continue; }
  const html=fs.readFileSync(f,'utf8'); const win=new Window(); const doc=win.document; doc.body.innerHTML=html;
  const can=doc.querySelector('link[rel="canonical"]')?.getAttribute('href')||''; if(can!==u) { console.error(`[inv:sitemap] ${u}: canonical mismatch (${can})`); issues++; }
  const anchors=[...doc.querySelectorAll('a[href]')].map(a=>a.getAttribute('href')); if(anchors.length===0) { console.error(`[inv:sitemap] ${u}: page not in internal link graph (no anchors)`); issues++; }
}
if(issues) process.exit(1); console.log('[inv:sitemap] OK');
JS
chmod +x scripts/invariants/sitemap-check.mjs

# 14.6 Similarity (doorway risk) — basic Jaccard on visible text
cat > scripts/invariants/similarity-check.mjs <<'JS'
#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import { Window } from 'happy-dom';
const DIST='dist'; if(!fs.existsSync(DIST)) { console.log('[inv:similar] dist/ missing'); process.exit(0); }
const THRESH=0.85; // block if > 85% similar
function* walk(dir){ for(const e of fs.readdirSync(dir,{withFileTypes:true})){ const full=path.join(dir,e.name); if(e.isDirectory()) yield* walk(full); else if(e.isFile()&&e.name.endsWith('.html')) yield full; } }
const svcPages=[...walk(DIST)].filter(f=>/\/services\/(spring-clean|bathroom-deep-clean)\/[^/]+\/index\.html$/.test(f));
function textOf(f){ const html=fs.readFileSync(f,'utf8'); const win=new Window(); const doc=win.document; doc.body.innerHTML=html;
  // strip nav/footer
  const main = doc.querySelector('main') || doc.body; const t=(main.textContent||'').replace(/\s+/g,' ').toLowerCase();
  const tokens=new Set(t.split(/\W+/).filter(Boolean)); return tokens;
}
function jacc(a,b){ const A=textOf(a), B=textOf(b); const inter=[...A].filter(x=>B.has(x)).length; const union=new Set([...A,...B]).size; return union? inter/union : 0; }
let issues=0; for(let i=0;i<svcPages.length;i++){ for(let j=i+1;j<svcPages.length;j++){ const s=jacc(svcPages[i], svcPages[j]); if(s>THRESH){ console.error(`[inv:similar] High similarity (${(s*100).toFixed(1)}%) between:\n  - ${svcPages[i]}\n  - ${svcPages[j]}`); issues++; } } }
if(issues) process.exit(1); console.log('[inv:similar] OK');
JS
chmod +x scripts/invariants/similarity-check.mjs

# ========== 15) Playwright smoke (uses tmp/smoke-paths.json) ==========
cat > src/tests/geo.smoke.spec.ts <<'TS'
import { test, expect } from '@playwright/test';
import fs from 'node:fs';
function paths(){ try{ const j=JSON.parse(fs.readFileSync('tmp/smoke-paths.json','utf8')); return Array.isArray(j.paths)? j.paths : ['/suburbs/','/services/']; } catch { return ['/suburbs/','/services/']; } }
for(const p of paths()){
  test(`responds ${p}`, async ({ page }) => {
    const r = await page.goto(p); expect(r?.status()).toBeLessThan(400);
    const body = await page.textContent('body'); expect(body||'').not.toMatch(/undefined|not found/i);
  });
}
for(const p of paths().filter(x=>/\/suburbs\/[^/]+\/$/.test(x) || /\/services\/(spring-clean|bathroom-deep-clean)\/[^/]+\/$/.test(x)).slice(0,6)){
  test(`json-ld present ${p}`, async ({ page }) => {
    await page.goto(p);
    const n = await page.locator('script[type="application/ld+json"]').count();
    expect(n).toBeGreaterThan(0);
  });
}
TS

# ========== 16) Netlify headers + analytics stub ==========
cat > public/_headers <<'H'
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=()
H

cat > netlify/functions/analytics.js <<'JS'
exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') return { statusCode: 405, body: 'Method Not Allowed' };
  // minimal privacy-first ledger: count only event type + path (no PII)
  const { eventType, path } = JSON.parse(event.body||'{}');
  console.log(JSON.stringify({ t: Date.now(), eventType, path }));
  return { statusCode: 204, body: '' };
};
JS

cat > netlify.toml <<'TOML'
[build]
  command = "npm run guard:all"
  publish = "dist"
[functions]
  directory = "netlify/functions"
[[redirects]]
  from = "/api/analytics"
  to = "/.netlify/functions/analytics"
  status = 200
TOML

# ========== 17) Starter content & required data ==========
cat > src/content/posts/bond-cleaning-checklist.md <<'MD'
---
title: "Bond Cleaning Checklist: Agent-Ready Essentials"
description: "A practical checklist the agent actually checks — glass edges, tracks, skirtings and more."
publishDate: "2025-09-07"
categories: ["checklists","bond-back"]
tags: ["bond-cleaning","checklist","inspection"]
region: "ipswich"
author: "One N Done Bond Clean"
draft: false
---
## Kitchen
- Oven: racks, trays, glass edges
- Cooktop & splashback
- Drawers & doors inside/out

## Bathrooms
- Shower glass & tracks
- Vanity & mirror
- Toilet base & cistern
MD

cat > src/data/geo.config.json <<'JSON'
{
  "nearby": { "limit": 6 },
  "adjacencyBoost": 24,
  "clusterBoost": 200,
  "biasKm": 12,
  "crossClusterPenalty": 200,
  "regions": ["brisbane", "ipswich", "logan"]
}
JSON

cat > src/data/areas.clusters.json <<'JSON'
{
  "clusters": [
    {
      "slug": "ipswich",
      "name": "Ipswich",
      "suburbs": [
        { "slug": "springfield-lakes", "name": "Springfield Lakes", "lat": -27.656, "lng": 152.916 },
        { "slug": "brookwater", "name": "Brookwater", "lat": -27.64, "lng": 152.92 }
      ]
    }
  ]
}
JSON

cat > src/data/cluster_map.json <<'JSON'
{ "ipswich": "ipswich" }
JSON

cat > src/data/areas.adj.json <<'JSON'
{
  "springfield-lakes": ["brookwater"],
  "brookwater": ["springfield-lakes"]
}
JSON

cat > src/data/proximity.json <<'JSON'
{
  "nearby": {
    "springfield-lakes": [ { "slug": "brookwater", "name": "Brookwater" } ]
  }
}
JSON

cat > src/data/business.json <<'JSON'
{
  "name": "One N Done Bond Clean",
  "url": "https://onendonebondclean.com.au",
  "telephone": "+61 7 3000 0000",
  "email": "quotes@onendone.com.au",
  "address": {
    "streetAddress": "123 Clean Street",
    "addressLocality": "Brisbane",
    "addressRegion": "QLD",
    "postalCode": "4000",
    "addressCountry": "AU"
  }
}
JSON

# ========== 18) Playwright config ==========
cat > playwright.config.ts <<'P'
import { defineConfig } from '@playwright/test';
export default defineConfig({
  retries: 2,
  forbidOnly: !!process.env.CI,
  reporter: process.env.CI ? 'github' : [['list']],
  use: { trace: 'retain-on-failure' }
});
P

# ========== 19) README + OWNER TODO ==========
cat > README.md <<'MD'
# One N Done — Upstream Blog + Geo Suburbs

A production-ready Astro 5 system with:
- Tailwind v4 via `@tailwindcss/postcss`
- Geo suburb architecture (clusters, adjacency, proximity)
- Per-suburb service pages for **Bathroom Deep Clean** and **Spring Clean**
- LocalBusiness / Service JSON-LD, canonical URLs, sitemap
- Transparent Lift Pack guardrails (anchor diversity, schema↔UI lockstep, no hidden keywords, no UA DOM)
- Geo Doctor + SEO DOM scanner (happy-dom) + Playwright smoke

## Quick Start
```bash
npm install
npx playwright install
npm run geo:doctor
npm run dev
# build + audit
npm run build
npm run seo:report
npm run inv:anchors && npm run inv:lockstep && npm run inv:no-ua && npm run inv:no-hidden && npm run inv:sitemap && npm run inv:similar
````

## Owner must supply / maintain

* `src/data/areas.clusters.json`  → clusters + suburbs with **lat/lng per suburb**
* `src/data/cluster_map.json`     → cluster → region mapping (e.g., brisbane/ipswich/logan)
* `src/data/areas.adj.json`       → adjacency per suburb (improves nearby quality)
* `src/data/proximity.json`       → curated nearby lists (optional; overrides)
* `src/data/geo.config.json`      → ranking weights & nearby limit; regions list
* `src/data/business.json`        → NAP for LocalBusiness JSON-LD
* `src/content/posts/*.md`        → blog posts with `region ∈ {brisbane, ipswich, logan}`

### File shapes

* **areas.clusters.json**

```json
{ "clusters":[{ "slug":"brisbane","name":"Brisbane","suburbs":[
  {"slug":"annerley","name":"Annerley","lat":-27.51,"lng":153.03}
]}]}
```

* **cluster\_map.json**

```json
{ "brisbane":"brisbane","ipswich":"ipswich","logan":"logan" }
```

* **areas.adj.json**

```json
{ "annerley":["woolloongabba","fairfield"] }
```

* **proximity.json**

```json
{ "nearby": { "annerley":[{"slug":"fairfield","name":"Fairfield"}] } }
```

## CI guardrail

Use `npm run guard:all` to validate geo + build + SEO + invariants in one shot (configured as Netlify build command).
MD

# ========== 20) Dependency install hint ==========

PKG_MGR="npm"; command -v pnpm >/dev/null 2>&1 && PKG_MGR="pnpm"
echo "
✅ Bootstrap complete.

Next:

1. ${PKG_MGR} install
2. npx playwright install
3. npm run geo:doctor            # advisory
   npm run geo:doctor:strict     # fail on errors
4. npm run dev
5. npm run build && npm run seo:report
6. npm run guard:all             # full invariant sweep
   "

