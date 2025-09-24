import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

function titleCase(slug) {
  return String(slug).replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

export default {
  id: '04-write-pages',
  async eachNode(ctx, { service, suburb }) {
    const outDir = ctx.args.outDir || `src/pages/services/${service}/${suburb}`;
    await mkdir(outDir, { recursive: true });
    const jsonld = ctx.jsonld?.[`${service}/${suburb}`] || {};
    const max = ctx.config.policies?.neighborsMax ?? 6;
    const neighbors = (ctx.datasets.adj[suburb] || []).slice(0, max);

    const astro = `---
const jsonld = ${JSON.stringify(jsonld, null, 2)};
const neighbors = ${JSON.stringify(neighbors, null, 2)};
const serviceSlug = '${service}';
const suburbSlug = '${suburb}';
---

<!-- Compose your design‑system components here -->

<script type="application/ld+json">{JSON.stringify(jsonld.localBusiness)}</script>
<script type="application/ld+json">{JSON.stringify(jsonld.cleaningService)}</script>
<script type="application/ld+json">{JSON.stringify(jsonld.place)}</script>
<script type="application/ld+json">{JSON.stringify(jsonld.dataset)}</script>

<section class="py-8">
  <h1 class="text-3xl font-bold">{titleCase(serviceSlug)} in {titleCase(suburbSlug)}</h1>
  <p class="mt-2 opacity-80">Professional, agent-ready results backed by a bond return guarantee.</p>
</section>

{neighbors?.length ? (
  <section class="mt-12">
    <h2 class="text-xl font-semibold">Nearby areas</h2>
    <ul class="grid sm:grid-cols-2 md:grid-cols-3 gap-3 mt-4">
      {neighbors.map(n => (<li><a href={\`/services/${service}/${'${'}n{'}'}/\`}>{titleCase(n)}</a></li>))}
    </ul>
  </section>
) : null}
`;

    await writeFile(path.join(outDir, 'index.astro'), astro, 'utf8');
  }
};
