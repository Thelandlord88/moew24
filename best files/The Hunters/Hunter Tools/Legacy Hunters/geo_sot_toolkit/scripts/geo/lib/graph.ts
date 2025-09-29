export function normalizeAdjacency(raw: Record<string, string[]>) {
  // Lowercase slugs, remove self-loops, dedupe and sort
  const keys = new Set<string>(Object.keys(raw).map(k => k.toLowerCase()));
  const adj: Record<string, string[]> = {};
  // Ensure every referenced node exists
  for (const [k, vs] of Object.entries(raw)) {
    const key = k.toLowerCase();
    keys.add(key);
    for (const v of vs) keys.add(v.toLowerCase());
  }
  for (const k of keys) adj[k] = [];
  for (const [k, vs] of Object.entries(raw)) {
    const u = k.toLowerCase();
    const next = new Set<string>();
    for (const v0 of vs) {
      const v = v0.toLowerCase();
      if (v === u) continue; // drop self-loop
      next.add(v);
    }
    adj[u] = Array.from(next).sort();
  }
  return adj;
}

export function connectedComponents(adj: Record<string,string[]>): string[][] {
  const nodes = Object.keys(adj).sort();
  const seen = new Set<string>(), comps: string[][] = [];
  for (const s of nodes) if (!seen.has(s)) {
    const stack=[s], comp:string[]=[]; seen.add(s);
    while (stack.length) {
      const u = stack.pop()!; comp.push(u);
      for (const v of adj[u]) if (!seen.has(v)) { seen.add(v); stack.push(v); }
    }
    comps.push(comp.sort());
  }
  return comps.sort((a,b)=>b.length-a.length);
}

export function degreeStats(adj: Record<string,string[]>) {
  const degs = Object.values(adj).map(v => v.length).sort((a,b)=>a-b);
  const n = degs.length || 1;
  const q = (p:number) => degs[Math.min(n-1, Math.floor(p*(n-1)))];
  const mean = degs.reduce((a,b)=>a+b,0)/(n||1);
  return { min: degs[0] ?? 0, median: q(0.5), max: degs[n-1] ?? 0, mean, p90: q(0.9) };
}

export function undirectedEdgeCount(adj: Record<string,string[]>) {
  let count = 0;
  const seen = new Set<string>();
  for (const u of Object.keys(adj)) {
    for (const v of adj[u]) {
      if (u === v) continue;
      const key = u < v ? `${u}|${v}` : `${v}|${u}`;
      if (!seen.has(key)) { seen.add(key); count++; }
    }
  }
  return count;
}

export function asymPairs(adj: Record<string,string[]>) {
  const out: Array<[string,string]> = [];
  for (const [u, vs] of Object.entries(adj)) {
    for (const v of vs) if (!adj[v]?.includes(u) && u !== v) out.push([u, v]);
  }
  return out.sort((a,b)=>a[0]===b[0]?a[1].localeCompare(b[1]):a[0].localeCompare(b[0]));
}
