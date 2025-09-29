import { mkdir, writeFile } from 'node:fs/promises';

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

function gini(values){
  const arr = values.map(v => Number(v) || 0).filter(v => v>=0).sort((a,b)=>a-b);
  const n = arr.length;
  if (!n) return 0;
  const sum = arr.reduce((a,b)=>a+b,0);
  if (sum === 0) return 0;
  let cum = 0, area = 0;
  for (let i=0;i<n;i++){
    cum += arr[i];
    area += cum;
  }
  return (n + 1 - 2*area/sum) / n;
}

function mean(values){
  const arr = values.map(Number).filter(v => Number.isFinite(v));
  if (!arr.length) return 0;
  return arr.reduce((a,b)=>a+b,0)/arr.length;
}
function stddev(values){
  const m = mean(values);
  const arr = values.map(Number).filter(v => Number.isFinite(v));
  if (!arr.length) return 0;
  const v = mean(arr.map(x => (x-m)*(x-m)));
  return Math.sqrt(v);
}

export default {
  id: '08-optimize-links',
  async afterAll(ctx) {
    const links = ctx.reports.links || [];
    const adj = ctx.datasets.adj || {};
    const meta = ctx.datasets.meta || {};
    const clusters = ctx.datasets.clusters || {};
    const clusterOf = clusters.clusterOf || {};
    const policies = ctx.config.policies || {};
    const scoring = policies.scoring || {};
    // CLI overrides
    const argMax = ctx.args.neighborsMax != null ? Number(ctx.args.neighborsMax) : undefined;
    const argMin = ctx.args.neighborsMin != null ? Number(ctx.args.neighborsMin) : undefined;
    const argCap = ctx.args.cap != null ? Number(ctx.args.cap) : undefined;
    const argRecip = (ctx.args.reciprocity === true || ctx.args.reciprocity === 'true');
    const strict = (ctx.args.strict === true || ctx.args.strict === 'true');

    let enforceReciprocity = argRecip || (policies.enforceReciprocity ?? false);
    let maxPerList = argMax ?? (policies.neighborsMax ?? 6);
    let minPerList = argMin ?? (policies.neighborsMin ?? Math.min(3, maxPerList));
    if (strict) {
      enforceReciprocity = true;
      maxPerList = Math.max(3, Math.min(maxPerList, 5));
      minPerList = Math.min(minPerList, maxPerList);
    }

    const weights = {
      weightCluster: scoring.weightCluster ?? 1.0,
      weightDistance: scoring.weightDistance ?? 1.0,
      weightReciprocalEdge: scoring.weightReciprocalEdge ?? 0.5,
      weightHubDamping: scoring.weightHubDamping ?? 0.5,
      distanceScaleKm: scoring.distanceScaleKm ?? 10
    };

    // Build inbound counts
    const inbound = {};
    for (const { neighbors=[] } of links) {
      for (const n of neighbors) inbound[n] = (inbound[n] || 0) + 1;
    }
    const inboundVals = Object.values(inbound);
    const baseMetrics = {
      totalLinks: inboundVals.reduce((a,b)=>a+b,0),
      gini: Number(gini(inboundVals).toFixed(4))
    };

    // Determine a dynamic cap if not configured
    let cap = argCap ?? policies.globalInboundCap;
    if (!Number.isFinite(cap)) {
      const m = mean(inboundVals);
      const sd = stddev(inboundVals);
      cap = Math.ceil(m + sd) || maxPerList; // reasonable dynamic cap
    }

    // Helper scoring for candidates from a given suburb
    function scoreCandidates(from) {
      const fromCoord = meta[from]?.coordinates;
      const neighborsRaw = Array.isArray(adj[from]) ? adj[from] : [];
      const degree = (s) => (Array.isArray(adj[s]) ? adj[s].length : 0);
      const maxDeg = Math.max(1, ...Object.keys(adj).map(k => degree(k)));
      return neighborsRaw.map(n => {
        const sameCluster = (clusterOf[from] || '') === (clusterOf[n] || '');
        const reciprocal = Array.isArray(adj[n]) && adj[n].includes(from);
        const bCoord = meta[n]?.coordinates;
        const dKm = haversineKm(fromCoord, bCoord);
        const distScore = (dKm == null) ? 0 : Math.max(0, 1 - (dKm / Math.max(1, weights.distanceScaleKm)));
        const hubScore = - (degree(n) / Math.max(1, maxDeg));
        const score = (weights.weightCluster * (sameCluster ? 1 : 0))
          + (weights.weightReciprocalEdge * (reciprocal ? 1 : 0))
          + (weights.weightDistance * distScore)
          + (weights.weightHubDamping * hubScore);
        return { n, score, reciprocal };
      }).filter(c => (enforceReciprocity ? c.reciprocal : true))
        .sort((a,b) => b.score - a.score)
        .map(c => c.n);
    }

    // Build quick lookup
    const byKey = new Map();
    for (const rec of links) byKey.set(`${rec.service}/${rec.suburb}`, rec);

    // Identify over-subscribed targets
    const overTargets = Object.keys(inbound).filter(k => inbound[k] > cap).sort((a,b) => inbound[b]-inbound[a]);
  const substitutions = [];
  const removals = [];

    for (const target of overTargets) {
      // Find all sources linking to this target, ordered by how many options they likely have (more options first)
      const sources = links
        .filter(r => r.neighbors?.includes(target))
        .map(r => ({ key: `${r.service}/${r.suburb}`, service: r.service, suburb: r.suburb, neighbors: r.neighbors }))
        .sort((a,b) => (adj[b.suburb]?.length || 0) - (adj[a.suburb]?.length || 0));

      for (const s of sources) {
        if (inbound[target] <= cap) break;
        // Candidate replacement list for source suburb
        const candidates = scoreCandidates(s.suburb);
        const current = new Set(s.neighbors);
        let replacement = null;
        for (const c of candidates) {
          if (c === target) continue;
          if (current.has(c)) continue;
          if ((inbound[c] || 0) >= cap) continue;
          replacement = c; break;
        }
        const idx = s.neighbors.indexOf(target);
        if (!replacement) {
          // If we cannot find a replacement and list is longer than min, drop the over-cap link
          if (idx >= 0 && s.neighbors.length > minPerList) {
            s.neighbors.splice(idx, 1);
            inbound[target] -= 1;
            const rec = byKey.get(s.key);
            if (rec) rec.neighbors = s.neighbors.slice(0, maxPerList);
            if (ctx._neighborsMap) ctx._neighborsMap[s.key] = rec.neighbors;
            removals.push({ source: s.suburb, service: s.service, removed: target, reason: 'over-cap-no-replacement' });
          }
          continue;
        }
        // Apply replacement
        if (idx >= 0) {
          s.neighbors[idx] = replacement;
          // Update data structures
          inbound[target] -= 1;
          inbound[replacement] = (inbound[replacement] || 0) + 1;
          const rec = byKey.get(s.key);
          if (rec) rec.neighbors = s.neighbors.slice(0, maxPerList);
          if (ctx._neighborsMap) ctx._neighborsMap[s.key] = rec.neighbors;
          substitutions.push({ source: s.suburb, service: s.service, from: target, to: replacement });
        }
      }
    }

    const afterVals = Object.values(inbound);
    const afterMetrics = {
      totalLinks: afterVals.reduce((a,b)=>a+b,0),
      gini: Number(gini(afterVals).toFixed(4))
    };

    await mkdir('__reports/daedalus', { recursive: true });
    const report = {
      generatedAt: new Date().toISOString(),
      policyCapUsed: cap,
      substitutionsCount: substitutions.length,
      removalsCount: removals.length,
      metrics: { before: baseMetrics, after: afterMetrics },
      substitutions,
      removals
    };
    await writeFile('__reports/daedalus/link-optimization.json', JSON.stringify(report, null, 2));

    // Push summary metrics
    ctx.reports.metrics.inboundGiniBefore = baseMetrics.gini;
    ctx.reports.metrics.inboundGiniAfter = afterMetrics.gini;
    ctx.reports.metrics.linkSubstitutions = substitutions.length;
    ctx.reports.metrics.linkRemovals = removals.length;
  }
};
