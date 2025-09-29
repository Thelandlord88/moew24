import { log } from '../util/log.mjs';

export default {
  id: '02-derive-graph',
  async beforeAll(ctx) {
    const adj = ctx.datasets.adj || {};
    const issues = [];
    for (const a of Object.keys(adj)) {
      const list = Array.isArray(adj[a]) ? adj[a] : [];
      for (const b of list) {
        if (!Array.isArray(adj[b]) || !adj[b].includes(a)) {
          issues.push({ type: 'nonreciprocal', a, b });
        }
      }
      if (!list.length) issues.push({ type: 'island', a });
    }
    ctx.reports.issues.push(...issues);
    ctx.reports.metrics.nonreciprocal = issues.filter(i => i.type==='nonreciprocal').length;
    ctx.reports.metrics.islands = issues.filter(i => i.type==='island').length;
    log.info(`Graph hygiene → nonreciprocal=${ctx.reports.metrics.nonreciprocal}, islands=${ctx.reports.metrics.islands}`);
  }
};
