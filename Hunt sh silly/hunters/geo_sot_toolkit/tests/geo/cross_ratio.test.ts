import { test, expect } from "vitest";
import fc from "fast-check";
import { normalizeAdjacency } from "../../scripts/geo/lib/graph.js";
import { crossClusterRatio } from "../../scripts/geo/lib/crossCluster.js";

function makeDeterministicMap(keys: string[]) {
  // Map by simple parity of char codes for determinism
  const m: Record<string,string> = {};
  for (const k of keys) {
    const sum = Array.from(k).reduce((a,c)=>a+c.charCodeAt(0),0);
    m[k.toLowerCase()] = (sum % 2 === 0) ? "a" : "b";
  }
  return m;
}

test("cross_cluster_ratio stays within [0,1]", () => {
  fc.assert(fc.property(fc.dictionary(fc.string(), fc.array(fc.string())), (raw) => {
    const adj = normalizeAdjacency(raw as any);
    const keys = Object.keys(adj);
    const cmap = makeDeterministicMap(keys);
    const x = crossClusterRatio(adj, cmap);
    expect(x.ratio).toBeGreaterThanOrEqual(0);
    expect(x.ratio).toBeLessThanOrEqual(1);
  }));
});
