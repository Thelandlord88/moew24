import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

export default {
  id: '04-write-pages',
  async eachNode(ctx, { service, suburb }) {
    const outDir = ctx.args.outDir || `src/pages/services/${service}/${suburb}`;
    await mkdir(outDir, { recursive: true });
    const jsonld = ctx.jsonld?.[`${service}/${suburb}`] || {};
    const max = ctx.config.policies?.neighborsMax ?? 6;
    const neighbors = (ctx.datasets.adj[suburb] || []).slice(0, max);

    const page = `---
import PageLayout from '../../../../layouts/PageLayout.astro';
import Card from '../../../../components/ui/Card.astro';
import Accordion from '../../../../components/ui/Accordion.astro';
import Badge from '../../../../components/ui/Badge.astro';
import NearbyGrid from '../../../../components/ui/NearbyGrid.astro';
import { mergeThemeTokens } from '../../../../lib/theme/tokens';
import { serviceThemes } from '../../../../lib/theme/serviceThemes';
import { suburbThemes } from '../../../../lib/theme/suburbThemes';

const jsonld = ${JSON.stringify(jsonld, null, 2)};
const neighbors = ${JSON.stringify(neighbors, null, 2)};
const serviceSlug = '${service}';
const suburbSlug = '${suburb}';

function titleCase(s) { return s.replace(/-/g, ' ').replace(/\\b\\w/g, (c) => c.toUpperCase()); }

const theme = mergeThemeTokens(serviceThemes[serviceSlug], suburbThemes[suburbSlug]);

const pageTitle = \`\${titleCase(serviceSlug)} in \${titleCase(suburbSlug)}\`;
const subtitle = 'Professional, agent-ready results backed by a bond return guarantee.';
---

<PageLayout title={pageTitle} subtitle={subtitle} theme={theme} jsonld={jsonld}>
  <section class="mt-8 grid md:grid-cols-3 gap-6">
    <Card title="Why choose us">
      <ul class="list-disc list-inside space-y-1">
        <li>Thorough end-to-end checklist</li>
        <li>Real estate agent expectations hardened from experience</li>
        <li>Eco-friendly, pet-safe products</li>
      </ul>
    </Card>
    <Card title="What’s included">
      <ul class="list-disc list-inside space-y-1">
        <li>Kitchen: oven, rangehood, cupboards, splashback</li>
        <li>Bathrooms: tiles, glass, grout, fixtures</li>
        <li>Rooms: skirting, fans, tracks, windows (where safe)</li>
      </ul>
    </Card>
    <Card title="Agent-ready promise">
      <div class="space-y-2">
        <p class="opacity-85">If your agent flags anything within 72 hours, we’ll return and remedy promptly.</p>
        <Badge label="72‑hour bond-back" />
      </div>
    </Card>
  </section>

  <section class="mt-12">
    <Accordion items={[
      { heading: 'How long does a typical bond clean take?', content: 'Most jobs complete the same day, with start times tailored to access.' },
      { heading: 'Do you bring all equipment?', content: 'Yes — commercial vacuums, eco products, and safety gear.' },
      { heading: 'Do you guarantee acceptance by the agent?', content: 'We follow agent-standard checklists and return for any reasonable rectifications reported within 72 hours.' }
    ]} />
  </section>

  <NearbyGrid service={serviceSlug} neighbors={neighbors} />
</PageLayout>
`;

    await writeFile(path.join(outDir, 'index.astro'), page, 'utf8');
  }
};
