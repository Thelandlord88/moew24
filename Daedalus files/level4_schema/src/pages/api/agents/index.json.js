// src/pages/api/agents/index.json.js
import { readFile } from 'node:fs/promises';

export async function GET() {
  const site = (import.meta.env.SITE || 'https://example.com').replace(/\/+$/,'');
  const cfg = JSON.parse(await readFile(new URL('../../../daedalus.config.json', import.meta.url), 'utf8'));
  const clusters = JSON.parse(await readFile(new URL('../../data/areas.clusters.json', import.meta.url), 'utf8'));
  const suburbKeys = clusters.suburbs ? Object.keys(clusters.suburbs) : Object.keys(clusters);
  const items = [];
  for (const svc of cfg.services) {
    for (const s of suburbKeys) {
      items.push({
        service: svc.id,
        suburb: s,
        url: `${site}/services/${svc.id}/${s}/`,
        placeId: `${site}/areas/${s}#place`
      });
    }
  }
  return new Response(JSON.stringify({ count: items.length, items }, null, 2), {
    headers: { 'content-type': 'application/json; charset=utf-8' }
  });
}
