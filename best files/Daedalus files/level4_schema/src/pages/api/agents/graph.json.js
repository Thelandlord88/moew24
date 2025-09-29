// src/pages/api/agents/graph.json.js
import { readFile } from 'node:fs/promises';

export async function GET() {
  const clusters = JSON.parse(await readFile(new URL('../../data/areas.clusters.json', import.meta.url), 'utf8'));
  const adj = JSON.parse(await readFile(new URL('../../data/areas.adj.json', import.meta.url), 'utf8'));
  let meta = {};
  try {
    meta = JSON.parse(await readFile(new URL('../../data/suburbs.meta.json', import.meta.url), 'utf8'));
  } catch {}
  const payload = {
    clusters,
    adj,
    metaSummary: Object.keys(meta).length ? { suburbsWithMeta: Object.keys(meta).length } : undefined,
    generatedAt: new Date().toISOString()
  };
  return new Response(JSON.stringify(payload, null, 2), {
    headers: { 'content-type': 'application/json; charset=utf-8' }
  });
}
