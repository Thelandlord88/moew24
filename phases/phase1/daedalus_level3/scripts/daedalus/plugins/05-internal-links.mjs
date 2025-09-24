import { mkdir, writeFile } from 'node:fs/promises';

function haversineKm(a, b) {
  if (!a || !b) return null;
  const toRad = (d) => d * Math.PI / 180;
  const R = 6371;
  const dLat = toRad((b.lat - a.lat));
  const dLon = toRad((b.lng - a.lng));
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const sinDLat = Math.sin(dLat/2);
  const sinDLon = Math.sin(dLon/2);
  const h = sinDLat*sinDLat + Math.cos(lat1)*Math.cos(lat2)*sinDLon*sinDLon;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
}

function titleCase(slug) {
  return String(slug).replace(/-/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
}

/**
 * Internal-link policy engine
 * - Scores candidates for each page using config weights
 * - Plans links globally to respect inbound caps & fairness
 * - Optionally enforces reciprocity
 */
export default {
  id: '05-internal-links',
  async beforeAll(ctx) {
    const cfg = ctx.config?.policies || {};
    const adj = ctx.datasets.adj || {};
    const clusters = ctx.datasets.clusters || {};
    const meta = ctx.datasets.meta || {};

    const W = {
      weightCluster: Number(cfg.scoring?.weightCluster ?? 1.0),
      weightDistance: Number(cfg.scoring?.weightDistance ?? 1.0),
      distanceScaleKm: Number(cfg.scoring?.distanceScaleKm ?? 10),
      weightReciprocalEdge: Number(cfg.scoring?.weightReciprocalEdge ?? 0.5),
      weightHubDamping: Number(cfg.scoring?.weightHubDamping ?? 0.5),
    };

    const neighborsMax = Number(cfg.neighborsMax ?? 6);
    const neighborsMin = Number(cfg.neighborsMin ?? Math.min(3, neighborsMax));
    const inboundCap = Number(cfg.globalInboundCap ?? Infinity);
    const enforceReciprocity = Boolean(cfg.enforceReciprocity ?? cfg.linkReciprocity ?? false);

    // Prepare degree map for hub damping
    const degree = Object.fromEntries(Object.keys(adj).map(k => [k, (adj[k] || []).length]));

    // Helper: score a neighbor candidate
    function scoreCandidate(suburb, cand) {
      const sameCluster = clusters.clusterOf ? (clusters.clusterOf[suburb] === clusters.clusterOf[cand]) : false;
      const a = meta[suburb]?.coordinates;
      const b = meta[cand]?.coordinates;
      const dist = (a && b) ? haversineKm(a, b) : null;
      const distTerm = dist == null ? 0 : 1 / (1 + (dist / Math.max(1, W.distanceScaleKm)));
      const reciprocalEdge = (adj[cand] || []).includes(suburb);
      const hubTerm = 1 / (1 + (degree[cand] || 0)); // damp high-degree nodes

      let s = 0;
      s += W.weightCluster * (sameCluster ? 1 : 0);
      s += W.weightDistance * distTerm;
      s += W.weightReciprocalEdge * (reciprocalEdge ? 1 : 0);
      s += W.weightHubDamping * hubTerm;
      return Number(s.toFixed(6));
    }

    // Compute raw scored candidates per page
    const plan = {};
    for (const t of ctx.targets) {
      const s = t.suburb;
      const nbrs = (adj[s] || []);
      const scored = nbrs.map(n => ({
        n,
        score: scoreCandidate(s, n)
      }));
      scored.sort((a,b) => b.score - a.score || a.n.localeCompare(b.n));
      plan[`${t.service}/${s}`] = scored;
    }

    // Global selection with inbound caps and fairness
    const inboundCount = {};
    const selected = {}; // key -> array of picked neighbor slugs
    const scoredOut = {}; // key -> {neighbor, score}[] final
    const keys = Object.keys(plan).sort(); // stable

    // Round-robin selection up to neighborsMax
    let addedAny = true;
    for (let round = 0; round < neighborsMax && addedAny; round++) {
      addedAny = false;
      for (const key of keys) {
        const picks = selected[key] || (selected[key] = []);
        if (picks.length >= neighborsMax) continue;

        const candidates = plan[key];
        let chosen = null;
        for (const cand of candidates) {
          if (picks.includes(cand.n)) continue;
          const capOK = (inboundCount[cand.n] || 0) < inboundCap;
          if (!capOK) continue;
          chosen = cand;
          break;
        }
        if (chosen) {
          picks.push(chosen.n);
          inboundCount[chosen.n] = (inboundCount[chosen.n] || 0) + 1;
          (scoredOut[key] || (scoredOut[key] = [])).push({ neighbor: chosen.n, score: chosen.score });
          addedAny = true;
        }
      }
    }

    // Ensure minimum neighbors if possible
    for (const key of keys) {
      const picks = selected[key] || (selected[key] = []);
      if (picks.length >= neighborsMin) continue;
      const candidates = plan[key];
      for (const cand of candidates) {
        if (picks.includes(cand.n)) continue;
        const capOK = (inboundCount[cand.n] || 0) < inboundCap;
        if (!capOK) continue;
        picks.push(cand.n);
        inboundCount[cand.n] = (inboundCount[cand.n] || 0) + 1;
        (scoredOut[key] || (scoredOut[key] = [])).push({ neighbor: cand.n, score: cand.score });
        if (picks.length >= neighborsMin) break;
      }
    }

    // Optional reciprocity enforcement: if A->B selected and B can fit A, add
    if (enforceReciprocity) {
      const pairs = [];
      for (const key of keys) {
        const picks = selected[key] || [];
        for (const n of picks) {
          const [svc, s] = key.split('/');
          const revKey = `${svc}/${n}`;
          pairs.push([key, revKey, s, n]);
        }
      }
      for (const [key, revKey, s, n] of pairs) {
        const revPicks = selected[revKey] || (selected[revKey] = []);
        if (revPicks.includes(s)) continue;
        if ((revPicks.length) >= neighborsMax) continue;
        const capOK = (inboundCount[s] || 0) < inboundCap;
        if (!capOK) continue;

        // Add reciprocal with its own score
        const scoreEntry = (plan[revKey] || []).find(e => e.n === s);
        const sc = scoreEntry ? scoreEntry.score : 0;
        revPicks.push(s);
        inboundCount[s] = (inboundCount[s] || 0) + 1;
        (scoredOut[revKey] || (scoredOut[revKey] = [])).push({ neighbor: s, score: sc });
      }
    }

    // Persist plan into context
    ctx._linkPlan = selected;
    ctx._linkPlanScored = scoredOut;
  },

  async eachNode(ctx, node) {
    const { service, suburb } = node;
    const key = `${service}/${suburb}`;
    const neighbors = (ctx._linkPlan?.[key] || []).slice();
    const details = (ctx._linkPlanScored?.[key] || []).slice();
    ctx.reports.links.push({ service, suburb, neighbors });
    // Attach detailed scores for reporting
    ctx.reports.linksScored = ctx.reports.linksScored || [];
    ctx.reports.linksScored.push({ key, details });
  },

  async afterAll(ctx) {
    await mkdir('__reports/daedalus', { recursive: true });
    await writeFile('__reports/daedalus/links.scored.json', JSON.stringify(ctx.reports.linksScored || [], null, 2));
  }
};
