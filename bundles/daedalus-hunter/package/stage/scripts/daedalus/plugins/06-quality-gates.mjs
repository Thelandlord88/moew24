import { writeFile, mkdir } from 'node:fs/promises';

export default {
  id: '06-quality-gates',
  async afterAll(ctx) {
    await mkdir('__reports/daedalus', { recursive: true });
    await writeFile('__reports/daedalus/issues.json', JSON.stringify(ctx.reports.issues, null, 2));
    await writeFile('__reports/daedalus/links.json', JSON.stringify(ctx.reports.links, null, 2));
    await writeFile('__reports/daedalus/metrics.json', JSON.stringify(ctx.reports.metrics, null, 2));
  }
};
