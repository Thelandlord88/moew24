import { test, expect } from "vitest";
import fc from "fast-check";
import { normalizeAdjacency, undirectedEdgeCount } from "../../scripts/geo/lib/graph.js";

test("normalize removes self-loops", () => {
  fc.assert(fc.property(fc.dictionary(fc.string(), fc.array(fc.string())), (raw) => {
    for (const k of Object.keys(raw)) raw[k] = [...raw[k], k];
    const adj = normalizeAdjacency(raw as any);
    for (const [u, vs] of Object.entries(adj)) expect(vs).not.toContain(u);
  }));
});

test("undirected edge count ≤ sum(deg)/2", () => {
  fc.assert(fc.property(fc.dictionary(fc.string(), fc.array(fc.string())), (raw) => {
    const adj = normalizeAdjacency(raw as any);
    const edges = undirectedEdgeCount(adj);
    const sumDeg = Object.values(adj).reduce((a,v)=>a+v.length, 0);
    expect(edges).toBeLessThanOrEqual(sumDeg/2 + 1e-6);
  }));
});
