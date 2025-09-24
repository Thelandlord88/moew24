import { readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { log } from '../util/log.mjs';

function safeJson(pathStr, required=true) {
  if (!existsSync(pathStr)) {
    if (required) throw new Error(`Required file not found: ${pathStr}`);
    return null;
  }
  return JSON.parse(require('node:fs').readFileSync(pathStr, 'utf8'));
}

export async function createContext({ args = {} }) {
  const root = process.cwd();
  const cfgPath = path.join(root, 'daedalus.config.json');
  const config = JSON.parse(await readFile(cfgPath, 'utf8'));

  const clusters = safeJson('src/data/areas.clusters.json', true);
  const adj = safeJson('src/data/areas.adj.json', true);
  const meta = safeJson('src/data/suburbs.meta.json', false) || {};

  // Determine suburb keys
  const suburbKeys = clusters.suburbs ? Object.keys(clusters.suburbs) : Object.keys(clusters);
  const clusterOf = clusters.clusterOf || {};

  // Build targets (service × suburb)
  const targets = [];
  for (const svc of config.services) {
    for (const suburb of suburbKeys) {
      if (args.only) {
        const [svcSlug, subSlug] = String(args.only).split('/');
        if (!(svcSlug === svc.id && subSlug === suburb)) continue;
      }
      if (args.cluster && clusterOf[suburb] !== args.cluster) continue;
      targets.push({ service: svc.id, suburb });
    }
  }

  if (!targets.length) {
    log.warn('No targets matched your filters.');
  }

  const datasets = { clusters, adj, meta, services: config.services };
  const reports = { issues: [], metrics: {}, links: [] };

  return { root, config, datasets, targets, reports, args };
}
