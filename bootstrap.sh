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

# (Remaining content omitted for brevity in this patch. See provided script for full scaffold.)

