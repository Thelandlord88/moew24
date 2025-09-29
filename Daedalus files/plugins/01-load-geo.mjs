import { log } from '../util/log.mjs';

export default {
  id: '01-load-geo',
  async beforeAll(ctx) {
    const clusters = ctx.datasets.clusters;
    const totalSubs = clusters.suburbs ? Object.keys(clusters.suburbs).length : Object.keys(clusters).length;
    log.info(`Loaded datasets: suburbs=${totalSubs}, services=${ctx.config.services.length}`);
    ctx.reports.metrics.totalSuburbs = totalSubs;
    ctx.reports.metrics.totalServices = ctx.config.services.length;
  }
};
