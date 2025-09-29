import { writeFile, mkdir } from 'node:fs/promises';

function toRad(d){ return d * Math.PI / 180; }
function haversineKm(a, b){
  if (!a || !b) return null;
  const R = 6371;
  const dLat = toRad((b.lat ?? b.latitude) - (a.lat ?? a.latitude));
  const dLon = toRad((b.lng ?? b.lon ?? b.longitude) - (a.lng ?? a.lon ?? a.longitude));
  const lat1 = toRad(a.lat ?? a.latitude), lat2 = toRad(b.lat ?? b.latitude);
  const s1 = Math.sin(dLat/2), s2 = Math.sin(dLon/2);
  const h = s1*s1 + Math.cos(lat1)*Math.cos(lat2)*s2*s2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
}

function clone(x){ return JSON.parse(JSON.stringify(x)); }

export default {
  id: '07-auto-fix-graph',
  async afterAll(ctx) {
    const adj = clone(ctx.datasets.adj || {});
    const meta = ctx.datasets.meta || {};
    const clusters = ctx.datasets.clusters || {};
    const clusterOf = clusters.clusterOf || {};

    const issues = Array.isArray(ctx.reports.issues) ? ctx.reports.issues : [];
    const changes = [];

    // Build full set of suburbs
    const suburbs = Array.from(new Set([
      ...Object.keys(adj),
      ...Object.keys(meta || {}),
      ...(clusters.suburbs ? Object.keys(clusters.suburbs) : Object.keys(clusters || {}))
    ]));

    // Ensure adjacency arrays exist
    for (const s of suburbs) {
      if (!Array.isArray(adj[s])) adj[s] = [];
    }

    // Helper to add edge if missing
    function addEdge(a, b, kind){
      if (a === b) return false;
      const list = adj[a] || (adj[a] = []);
      if (!list.includes(b)) {
        list.push(b);
        changes.push({ type: kind, a, b });
        return true;
      }
      return false;
    }

    // 1) Fix non-reciprocal edges by adding the missing back edge
    for (const it of issues) {
      if (it.type === 'nonreciprocal' && it.a && it.b) {
        addEdge(it.b, it.a, 'reciprocityAdded');
      }
    }

    // 2) Link islands: connect to a sensible neighbor
    const byCluster = {};
    for (const s of suburbs) {
      const c = clusterOf[s] || '__none__';
      (byCluster[c] ||= []).push(s);
    }
    for (const it of issues) {
      if (it.type !== 'island' || !it.a) continue;
      const a = it.a;
      // Choose neighbor: prefer same cluster nearest by coordinates; else nearest overall; else skip
      const candPool = byCluster[clusterOf[a] || '__none__'] || suburbs;
      const aCoord = meta[a]?.coordinates;
      let best = null; let bestD = Infinity;
      for (const n of candPool) {
        if (n === a) continue;
        const bCoord = meta[n]?.coordinates;
        const d = haversineKm(aCoord, bCoord);
        if (d == null) continue;
        if (d < bestD) { best = n; bestD = d; }
      }
      if (!best) {
        // Fallback: any non-empty adjacency node
        best = suburbs.find(n => n !== a && Array.isArray(adj[n]) && adj[n].length > 0);
      }
      if (best) {
        const added1 = addEdge(a, best, 'linkedIsland');
        const added2 = addEdge(best, a, 'reciprocityAdded');
        if (!added1 && !added2) {
          // Already linked; record as no-op to acknowledge
          changes.push({ type: 'islandAlreadyLinked', a, b: best });
        }
      } else {
        changes.push({ type: 'islandUnfixable', a });
      }
    }

    // Sort and dedupe adjacency lists
    for (const k of Object.keys(adj)) {
      adj[k] = Array.from(new Set(adj[k])).sort();
    }

    // Write updated adjacency file
    await writeFile('src/data/areas.adj.json', JSON.stringify(adj, null, 2));

    // Report
    const report = {
      generatedAt: new Date().toISOString(),
      summary: {
        reciprocityAdded: changes.filter(c => c.type==='reciprocityAdded').length,
        islandsLinked: changes.filter(c => c.type==='linkedIsland').length,
        alreadyLinked: changes.filter(c => c.type==='islandAlreadyLinked').length,
        unfixable: changes.filter(c => c.type==='islandUnfixable').length
      },
      changes
    };
    await mkdir('__reports/daedalus', { recursive: true });
    await writeFile('__reports/daedalus/auto-fix.json', JSON.stringify(report, null, 2));

    // Update metrics
    ctx.reports.metrics.fixedNonreciprocal = report.summary.reciprocityAdded;
    ctx.reports.metrics.linkedIslands = report.summary.islandsLinked;

    // Replace in-memory adjacency for downstream steps
    ctx.datasets.adj = adj;
  }
};
