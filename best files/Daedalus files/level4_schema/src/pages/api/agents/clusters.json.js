// src/pages/api/agents/clusters.json.js
import { readFile } from 'node:fs/promises';

export async function GET() {
  const site = (import.meta.env.SITE || 'https://example.com').replace(/\/+$/,'');
  const clusters = JSON.parse(await readFile(new URL('../../data/areas.clusters.json', import.meta.url), 'utf8'));
  const clusterOf = clusters.clusterOf || {};
  const suburbs = clusters.suburbs ? Object.keys(clusters.suburbs) : Object.keys(clusters);
  const map = {};
  for (const s of suburbs) {
    const cid = clusterOf[s] || 'default';
    (map[cid] ||= []).push(s);
  }
  for (const cid of Object.keys(map)) map[cid].sort();

  const items = Object.entries(map).sort(([a],[b]) => a.localeCompare(b)).map(([cid, subs]) => ({
    cluster: cid,
    placeId: `${site}/areas/${cid}#place`,
    suburbs: subs
  }));

  return new Response(JSON.stringify({ clusters: items }, null, 2), {
    headers: { 'content-type': 'application/json; charset=utf-8' }
  });
}
