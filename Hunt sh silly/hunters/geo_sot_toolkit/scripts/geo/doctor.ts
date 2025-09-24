#!/usr/bin/env node
import { performance } from "node:perf_hooks";
import { loadGeoRuntime } from "./lib/loader.js";
import { normalizeAdjacency, connectedComponents, degreeStats, asymPairs } from "./lib/graph.js";
import { mapNodeToCluster, crossClusterRatio } from "./lib/crossCluster.js";
import { stableGraphHash } from "./lib/stableHash.js";
import { DoctorReport } from "./lib/reports.js";
import { parseArgs } from "./lib/args.js";
import { makeLogger } from "./lib/logger.js";
import { writeJSONPretty } from "./lib/fs-io.js";
import { stableReport } from "./lib/stableReport.js";
import { DOCTOR_JSON } from "./lib/paths.js";

function degreeHistogram(adj: Record<string,string[]>) {
  const hist: Record<string, number> = {};
  for (const v of Object.values(adj)) {
    const d = v.length.toString();
    hist[d] = (hist[d] || 0) + 1;
  }
  return Object.fromEntries(Object.entries(hist).sort((a,b)=>Number(a[0])-Number(b[0])));
}

(async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log("Usage: doctor.ts [--json] [--out <file>] [--quiet] [--profile]");
    process.exit(0);
  }
  const log = makeLogger(args.quiet);
  const t0 = performance.now();

  const { rt, runtimeFallback } = await loadGeoRuntime();
  const rawAdj = await Promise.resolve(rt.adjacency());
  const clusters = await Promise.resolve(rt.clusters());
  const adj = normalizeAdjacency(rawAdj);

  const comps = connectedComponents(adj);
  const nodes = Object.keys(adj).length || 1;
  const lcr = Math.max(0, ...comps.map(c => c.length)) / nodes;
  const deg = degreeStats(adj);
  const asym = asymPairs(adj);
  const cMap = mapNodeToCluster(clusters);
  const x = crossClusterRatio(adj, cMap);
  const hash = stableGraphHash(adj);

  let rep = {
    schemaVersion: 1 as const,
    nodes,
    components: comps.length,
    largest_component_ratio: lcr,
    degrees: { ...deg, histogram: degreeHistogram(adj) },
    cross_cluster_ratio: x.ratio,
    asym_pairs: asym,
    self_loops: 0,
    meta: {
      generatedAt: new Date().toISOString(),
      runtimeFallback,
      toolVersion: "doctor/1",
      inputHashes: { graph: hash },
      timings: { total: performance.now() - t0 }
    }
  };

  rep = stableReport(rep);
  const out = DoctorReport.parse(rep);
  const outFile = args.out || DOCTOR_JSON;

  if (args.json) writeJSONPretty(outFile, out);
  else log.info(`components=${out.components} lcr=${out.largest_component_ratio.toFixed(3)} cross=${out.cross_cluster_ratio.toFixed(3)}`);
})().catch(e => { console.error("[doctor] fatal:", e); process.exit(1); });
