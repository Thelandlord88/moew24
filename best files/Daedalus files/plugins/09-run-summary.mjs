import { mkdir, writeFile } from 'node:fs/promises';

export default {
  id: '09-run-summary',
  async afterAll(ctx) {
    const pages = ctx.reports.pages || [];
    const links = ctx.reports.links || [];
    const metrics = ctx.reports.metrics || {};
    const issues = ctx.reports.issues || [];

    const totalPages = pages.length;
    const totalLinks = links.reduce((a,r) => a + (r.neighbors?.length || 0), 0);
    const uniqueTargets = new Set();
    for (const r of links) for (const n of r.neighbors || []) uniqueTargets.add(n);

    const summary = {
      generatedAt: new Date().toISOString(),
      mode: ctx.args?.mode || 'build',
      totals: { pages: totalPages, linkEdges: totalLinks, uniqueLinkTargets: uniqueTargets.size },
      metrics,
      issues: { count: issues.length, sample: issues.slice(0, 20) },
      pages: pages.slice(0, 100) // include first 100 pages for quick visibility
    };

    await mkdir('__reports/daedalus', { recursive: true });
    await writeFile('__reports/daedalus/summary.json', JSON.stringify(summary, null, 2));

    // Also generate a small text summary for quick glance
    const lines = [];
    lines.push(`# Daedalus Run Summary`);
    lines.push(`Generated: ${summary.generatedAt}`);
    lines.push(`Pages: ${totalPages}`);
    lines.push(`Links: ${totalLinks} edges across ${uniqueTargets.size} unique targets`);
    if (metrics.inboundGiniBefore != null && metrics.inboundGiniAfter != null) {
      lines.push(`Inbound Gini: ${metrics.inboundGiniBefore} → ${metrics.inboundGiniAfter}`);
    }
    lines.push(`Issues: ${issues.length}`);
    if (summary.pages.length) {
      lines.push('');
      lines.push(`First ${summary.pages.length} pages:`);
      for (const p of summary.pages) {
        lines.push(`- ${p.path} (neighbors: ${p.neighbors})`);
      }
    }
    await writeFile('__reports/daedalus/summary.txt', lines.join('\n'));
  }
};
