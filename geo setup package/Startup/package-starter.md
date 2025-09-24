sweet — here’s a complete, lean SSG skeleton with Biome + Prettier(astro), Playwright (+axe), Vitest, Tailwind v4, PSI perf budgets (LHCI removed), and a couple of health/preinstall scripts. Drop these files in as-is.

# package.json

```json
{
  "name": "one-n-done-site",
  "version": "0.3.0",
  "description": "One N Done Bond Clean — Astro + Tailwind v4, TypeScript, Playwright, Vitest, Biome",
  "private": true,
  "type": "module",
  "engines": { "node": ">=20.3.0 <21 || >=22" },
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "astro preview --port 4322 --host",
    "check": "astro check && tsc --noEmit",
    "lint": "biome lint .",
    "format": "biome format --write . && prettier -w \"src/**/*.astro\"",
    "format:check": "biome format --verify . && prettier -c \"src/**/*.astro\"",
    "test": "vitest run",
    "test:e2e": "playwright test",
    "a11y": "playwright test -g \"@a11y\"",
    "perf:psi": "node scripts/perf/psi.mjs",
    "health": "bash scripts/health.sh",
    "prepare": "husky",
    "postinstall": "npx --yes playwright install || true"
  },
  "dependencies": {
    "sanitize-html": "^2.17.0",
    "zod": "^3.25.76"
  },
  "devDependencies": {
    "@astrojs/check": "^0.9.4",
    "@axe-core/playwright": "^4.10.2",
    "@biomejs/biome": "^1.9.4",
    "@playwright/test": "^1.49.1",
    "@tailwindcss/vite": "^4.0.0",
    "astro": "^5.13.4",
    "dotenv": "^17.2.1",
    "globby": "^14.0.2",
    "husky": "^9.1.7",
    "micromatch": "^4.0.8",
    "node-html-parser": "^7.0.1",
    "openai": "^4.57.0",
    "prettier": "^3.6.2",
    "prettier-plugin-astro": "^0.14.1",
    "stylelint": "^16.23.1",
    "stylelint-config-standard": "^39.0.0",
    "tailwindcss": "^4.1.12",
    "tsconfig-paths": "^4.2.0",
    "tsx": "^4.20.5",
    "typescript": "^5.9.2",
    "vitest": "^2.1.9",
    "wait-on": "^7.0.1",
    "serve": "^14.2.1"
  }
}
```

# astro.config.mjs

```js
import { defineConfig } from "astro/config";
import tailwind from "@tailwindcss/vite";

export default defineConfig({
  output: "static", // pure SSG
  vite: {
    plugins: [tailwind()],
  },
});
```

# tsconfig.json

```json
{
  "extends": "astro/tsconfigs/strict",
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "types": ["vite/client", "astro/client"],
    "baseUrl": ".",
    "paths": {
      "~/*": ["src/*"]
    }
  },
  "include": ["src", "tests", "scripts", "playwright.config.ts"]
}
```

# .biome.json

```json
{
  "$schema": "https://biomejs.dev/schemas/1.9.4/schema.json",
  "files": {
    "ignore": ["dist", "node_modules", "**/*.astro"]
  },
  "formatter": { "enabled": true },
  "linter": {
    "enabled": true,
    "rules": { "recommended": true }
  }
}
```

# .prettierrc

```json
{
  "plugins": ["prettier-plugin-astro"]
}
```

# .gitignore

```
node_modules
dist
.husky/_/*
.vscode
.DS_Store
coverage
playwright-report
test-results
__snapshots__
.env
```

# scripts/health.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "▶ Checking Node..."
node -v || { echo "❌ Node not found"; exit 1; }

echo "▶ Checking ripgrep (rg)..."
if ! command -v rg >/dev/null 2>&1; then
  echo "❌ ripgrep (rg) not found."
  echo "Install via:"
  echo "  macOS:  brew install ripgrep"
  echo "  Ubuntu: sudo apt-get update && sudo apt-get install ripgrep"
  echo "  Arch:   sudo pacman -S ripgrep"
  echo "  Win:    winget install BurntSushi.ripgrep  # or choco/scoop"
  exit 1
else
  echo "✅ rg: $(rg --version | head -n1)"
fi

echo "✅ Health OK"
```

# scripts/preinstall-all.sh

```bash
#!/usr/bin/env bash
# Installs deps, Playwright browsers, and runs health checks.
set -euo pipefail

echo "▶ Node version:"
node -v

if [ -f package-lock.json ]; then
  echo "▶ Installing via npm ci..."
  npm ci
else
  echo "▶ Installing via npm i..."
  npm i
fi

echo "▶ Installing Playwright browsers..."
npx playwright install || true

echo "▶ Running health checks..."
bash scripts/health.sh

echo "✅ Preinstall complete."
```

# scripts/perf/budgets.json

```json
{
  "urls": [
    "https://example.com/",
    "https://example.com/areas/ipswich/springfield-lakes/"
  ],
  "budgets": {
    "performanceMin": 0.92,
    "lcpMs": 2300,
    "cls": 0.1,
    "inpMs": 200,
    "tbtMs": 200
  }
}
```

# scripts/perf/psi.mjs

```js
import fs from "node:fs";

const API = "https://www.googleapis.com/pagespeedonline/v5/runPagespeed";
const KEY = process.env.PSI_API_KEY || "";

const cfg = JSON.parse(fs.readFileSync("scripts/perf/budgets.json", "utf8"));

const run = async () => {
  let failed = 0;
  for (const url of cfg.urls) {
    const params = new URLSearchParams({ url, strategy: "mobile" });
    if (KEY) params.set("key", KEY);
    ["performance", "accessibility", "best-practices", "seo"].forEach((c) =>
      params.append("category", c)
    );

    const res = await fetch(`${API}?${params.toString()}`);
    if (!res.ok) {
      console.error("❌ PSI error", url, res.status, await res.text().catch(()=> ""));
      failed++;
      continue;
    }
    const json = await res.json();
    const lr = json.lighthouseResult;
    if (!lr) {
      console.error("❌ PSI malformed response", url);
      failed++;
      continue;
    }

    const score = lr.categories.performance.score; // 0..1
    const audits = lr.audits;
    const ms = (id) => audits[id]?.numericValue ?? NaN;

    const lcp = ms("largest-contentful-paint"); // ms
    const cls = audits["cumulative-layout-shift"]?.numericValue ?? NaN;
    const inp = ms("interaction-to-next-paint"); // ms
    const tbt = ms("total-blocking-time"); // ms

    const { performanceMin, lcpMs, cls: clsMax, inpMs, tbtMs } = cfg.budgets;
    const bad = [];
    if (score < performanceMin) bad.push(`perf ${score}`);
    if (lcp > lcpMs) bad.push(`LCP ${lcp}ms`);
    if (cls > clsMax) bad.push(`CLS ${cls}`);
    if (inp > inpMs) bad.push(`INP ${inp}ms`);
    if (tbt > tbtMs) bad.push(`TBT ${tbt}ms`);

    if (bad.length) {
      failed++;
      console.error(`❌ ${url} failed: ${bad.join(", ")}`);
    } else {
      console.log(
        `✅ ${url} OK (perf ${score}, LCP ${Math.round(lcp)}ms, CLS ${cls}, INP ${Math.round(
          inp
        )}ms, TBT ${Math.round(tbt)}ms)`
      );
    }
  }
  if (failed) process.exit(1);
};

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
```

# playwright.config.ts

```ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "tests",
  reporter: [["list"], ["html", { outputFolder: "playwright-report", open: "never" }]],
  use: {
    baseURL: "http://localhost:4322",
    trace: "on-first-retry"
  },
  projects: [
    { name: "Desktop Chrome", use: { ...devices["Desktop Chrome"] } }
  ],
  webServer: {
    command: "npm run preview",
    url: "http://localhost:4322",
    reuseExistingServer: !process.env.CI,
    timeout: 60_000
  }
});
```

# tests/a11y.spec.ts

```ts
import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

test.describe("@a11y home", () => {
  test("has no critical violations", async ({ page }) => {
    await page.goto("/");
    const results = await new AxeBuilder({ page }).analyze();
    const critical = results.violations.filter((v) => v.impact === "critical");
    expect(critical, JSON.stringify(critical, null, 2)).toEqual([]);
  });
});
```

# vitest.config.ts

```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["tests/unit/**/*.test.ts"]
  }
});
```

# stylelint.config.cjs (optional; drop if you don’t write CSS files)

```js
module.exports = {
  extends: ["stylelint-config-standard"],
  rules: {}
};
```

# src/styles/global.css

```css
@import "tailwindcss";
```

# src/pages/index.astro

```astro
---
import "../styles/global.css";
const title = "One N Done Bond Clean";
---
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>{title}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
  </head>
  <body class="min-h-screen bg-white text-slate-900">
    <main class="mx-auto max-w-3xl p-6">
      <h1 class="text-3xl font-bold">Hello 👋</h1>
      <p class="mt-4">Astro + Tailwind v4 + Biome + Vitest + Playwright.</p>
    </main>
  </body>
</html>
```

# src/pages/areas/\[lga]/\[suburb]/index.astro (SSG dynamic route example)

```astro
---
import "~/styles/global.css";
import { getAllSuburbs } from "~/lib/data/suburbs";

export async function getStaticPaths() {
  const rows = await getAllSuburbs(); // TODO: wire to your CSV/GeoJSON registry
  return rows.map((r) => ({
    params: { lga: r.lgaSlug, suburb: r.suburbSlug },
    props: r
  }));
}

const { name, lgaName } = Astro.props as { name: string; lgaName: string };
---
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>{name} — {lgaName}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
  </head>
  <body class="min-h-screen bg-white text-slate-900">
    <main class="mx-auto max-w-3xl p-6">
      <h1 class="text-3xl font-bold">{name}</h1>
      <p class="mt-4">Within {lgaName}.</p>
    </main>
  </body>
</html>
```

# src/lib/data/suburbs.ts

```ts
export interface SuburbRow {
  lgaSlug: string;
  suburbSlug: string;
  name: string;
  lgaName: string;
}

/**
 * Replace with your real loader (CSV/GeoJSON/DB).
 * Returning an empty array is valid; it just builds no dynamic pages.
 */
export async function getAllSuburbs(): Promise<SuburbRow[]> {
  return [];
}
```

# .husky/pre-commit

```bash
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

echo "▶ biome lint"
npx biome lint .

echo "▶ format check + astro format"
npx biome format --verify .
npx prettier -c "src/**/*.astro"

echo "▶ types"
npm run -s check
```

# .env.example

```
# Optional: PageSpeed Insights key for more stable PSI quotas
PSI_API_KEY=
```

---

## how to use

1. `bash scripts/preinstall-all.sh`
2. `npm run dev` → [http://localhost:4322](http://localhost:4322)
3. `npm run test:e2e` (starts preview automatically)
4. `npm run a11y` (axe-tagged Playwright tests)
5. `npm run perf:psi` (PSI budgets)
6. `npm run health` (rg check)

