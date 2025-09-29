import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

function isoDate() { return new Date().toISOString(); }
function chunk(arr, size){ const out=[]; for(let i=0;i<arr.length;i+=size) out.push(arr.slice(i,i+size)); return out; }

export default {
  id: '07-sitemap-robots',
  async afterAll(ctx) {
    const site = (ctx.config?.siteUrl || '').replace(/\/+$/,'');
    const sitemapCfg = ctx.config?.sitemaps || {};
    const robotsCfg = ctx.config?.robots || {};
    const partSize = Number(sitemapCfg.partitionSize ?? 5000);
    const outPath = sitemapCfg.path || 'public';

    const urls = ctx.targets.map(({service, suburb}) => ({
      loc: `${site}/services/${service}/${suburb}/`,
      lastmod: isoDate(),
      changefreq: 'weekly',
      priority: (service === 'bond-cleaning' ? '0.9' : '0.7')
    }));

    const parts = chunk(urls, partSize);
    const indexEntries = [];
    await mkdir(outPath, { recursive: true });

    for (let i=0; i<parts.length; i++) {
      const items = parts[i];
      const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${items.map(u => `  <url>
    <loc>${u.loc}</loc>
    <lastmod>${u.lastmod}</lastmod>
    <changefreq>${u.changefreq}</changefreq>
    <priority>${u.priority}</priority>
  </url>`).join('\n')}
</urlset>
`;
      const fname = `sitemap-daedalus-${i+1}.xml`;
      await writeFile(path.join(outPath, fname), xml, 'utf8');
      indexEntries.push(`${site}/${fname}`);
    }

    const indexXml = `<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${indexEntries.map(loc => `  <sitemap><loc>${loc}</loc><lastmod>${isoDate()}</lastmod></sitemap>`).join('\n')}
</sitemapindex>
`;
    await writeFile(path.join(outPath, 'sitemap.xml'), indexXml, 'utf8');

    const lines = [];
    lines.push(`User-agent: ${robotsCfg.userAgent || '*'}`);
    // Allow API for agents and keep any user-provided disallows
    lines.push('Allow: /api/agents/');
    for (const p of (robotsCfg.disallow || [])) lines.push(`Disallow: ${p}`);
    lines.push('');
    lines.push(`Sitemap: ${site}/sitemap.xml`);
    // Surface dataset endpoints (non-standard, but helpful hints for custom agents)
    lines.push(`# Dataset endpoints for agents`);
    lines.push(`# ${site}/api/agents/index.json`);
    lines.push(`# ${site}/api/agents/graph.json`);
    lines.push(`# ${site}/api/agents/clusters.json`);
    lines.push('');
    await writeFile(path.join(outPath, 'robots.txt'), lines.join('\n'), 'utf8');
  }
};
