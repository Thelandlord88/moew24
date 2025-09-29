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

export default {
  id: '05-internal-links',
  async beforeAll(ctx) {
    // Prepare caches and defaults
    ctx._neighborsMap = Object.create(null);
    ctx._inboundCounts = Object.create(null);
    const adj = ctx.datasets.adj || {};
    // Degrees for hub damping
    const degrees = Object.fromEntries(Object.entries(adj).map(([k,v]) => [k, Array.isArray(v) ? v.length : 0]));
    const maxDeg = Math.max(1, ...Object.values(degrees));
    ctx._hub = { degrees, maxDeg };
    // Cluster mapping
    const clusters = ctx.datasets.clusters || {};
    ctx._clusterOf = clusters.clusterOf || {};
  },
  async eachNode(ctx, node) {
    const { service, suburb } = node;
    const policies = ctx.config.policies || {};
    const scoring = policies.scoring || {};
    // Overrides via CLI args
    const argMax = ctx.args.neighborsMax != null ? Number(ctx.args.neighborsMax) : undefined;
    const argMin = ctx.args.neighborsMin != null ? Number(ctx.args.neighborsMin) : undefined;
    const argCap = ctx.args.cap != null ? Number(ctx.args.cap) : undefined;
    const argRecip = (ctx.args.reciprocity === true || ctx.args.reciprocity === 'true');
    const strict = (ctx.args.strict === true || ctx.args.strict === 'true');

    let max = argMax ?? (policies.neighborsMax ?? 6);
    let min = argMin ?? (policies.neighborsMin ?? Math.min(3, max));
    let cap = argCap ?? (policies.globalInboundCap ?? Infinity);
    let enforceReciprocity = argRecip || (policies.enforceReciprocity ?? false);
    if (strict) {
      enforceReciprocity = true;
      max = Math.max(3, Math.min(max, 5));
      min = Math.min(min, max);
      if (!Number.isFinite(cap)) cap = Math.max(1, Math.floor(max * 1.5));
    }

    const w = {
      weightCluster: scoring.weightCluster ?? 1.0,
      weightDistance: scoring.weightDistance ?? 1.0,
      weightReciprocalEdge: scoring.weightReciprocalEdge ?? 0.5,
      weightHubDamping: scoring.weightHubDamping ?? 0.5,
      distanceScaleKm: scoring.distanceScaleKm ?? 10
    };

    const adj = ctx.datasets.adj || {};
    const meta = ctx.datasets.meta || {};
    const clusterOf = ctx._clusterOf || {};
    const neighborsRaw = Array.isArray(adj[suburb]) ? adj[suburb] : [];

    // Build candidate scores
    const deg = (s) => ctx._hub.degrees[s] ?? 0;
    const maxDeg = ctx._hub.maxDeg || 1;
    const aCoord = meta[suburb]?.coordinates;

    const scored = neighborsRaw.map(n => {
      const sameCluster = (clusterOf[suburb] || '') === (clusterOf[n] || '');
      const reciprocal = Array.isArray(adj[n]) && adj[n].includes(suburb);
      const bCoord = meta[n]?.coordinates;
      const dKm = haversineKm(aCoord, bCoord);
      const distScore = (dKm == null) ? 0 : Math.max(0, 1 - (dKm / Math.max(1, w.distanceScaleKm)));
      const hubScore = - (deg(n) / Math.max(1, maxDeg));
      const score = (w.weightCluster * (sameCluster ? 1 : 0))
        + (w.weightReciprocalEdge * (reciprocal ? 1 : 0))
        + (w.weightDistance * distScore)
        + (w.weightHubDamping * hubScore);
      return { n, score, sameCluster, reciprocal, dKm, hub: deg(n) };
    }).filter(c => (enforceReciprocity ? c.reciprocal : true));

    scored.sort((a,b) => b.score - a.score);

    // Select neighbors honoring inbound caps first pass
    const selected = [];
    for (const c of scored) {
      if (selected.length >= max) break;
      const inbound = ctx._inboundCounts[c.n] || 0;
      if (inbound >= cap) continue;
      selected.push(c.n);
      ctx._inboundCounts[c.n] = inbound + 1;
    }

    // If we didn't hit min, try to relax inbound cap but keep order
    if (selected.length < min) {
      for (const c of scored) {
        if (selected.length >= min) break;
        if (!selected.includes(c.n)) selected.push(c.n);
      }
    }

    const neighbors = selected.slice(0, max);
    ctx.reports.links.push({ service, suburb, neighbors });
    ctx._neighborsMap[`${service}/${suburb}`] = neighbors;
  }
};
