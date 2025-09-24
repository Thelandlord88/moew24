export default {
  id: '05-internal-links',
  async eachNode(ctx, node) {
    const { service, suburb } = node;
    const max = ctx.config.policies?.neighborsMax ?? 6;
    const neighbors = (ctx.datasets.adj[suburb] || []).slice(0, max);
    ctx.reports.links.push({ service, suburb, neighbors });
  }
};
