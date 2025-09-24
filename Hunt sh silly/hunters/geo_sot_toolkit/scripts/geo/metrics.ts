#!/usr/bin/env node
import { performance } from "node:perf_hooks";
import { loadGeoRuntime } from "./lib/loader.js";
import { normalizeAdjacency, degreeStats, undirectedEdgeCount } from "./lib/graph.js";
import { stableGraphHash } from "./lib/stableHash.js";
import { MetricsReport } from "./lib/reports.js";
import { parseArgs } from "./lib/args.js";
import { makeLogger } from "./lib/logger.js";
import { writeJSONPretty } from "./lib/fs-io.js";
import { stableReport } from "./lib/stableReport.js";
import { METRICS_JSON } from "./lib/paths.js";

(async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log("Usage: metrics.ts [--json] [--out <file>] [--quiet] [--profile]");
    process.exit(0);
  }
  const log = makeLogger(args.quiet);
  const t0 = performance.now();

  const { rt } = await loadGeoRuntime();
  const clusters = await Promise.resolve(rt.clusters());
  const rawAdj = await Promise.resolve(rt.adjacency());
  const adj = normalizeAdjacency(rawAdj);
  const hash = stableGraphHash(adj);
  const t1 = performance.now();

  const directed = Object.values(adj).reduce((a, v) => a + v.length, 0);
  const undirected = undirectedEdgeCount(adj);
  const deg = degreeStats(adj);

  let report = {
    schemaVersion: 1 as const,
    clusters: clusters.length,
    suburbs: Object.keys(adj).length,
    edges: { directed, undirected, cross_cluster_ratio: 0 },
    degree: deg,
    meta: {
      generatedAt: new Date().toISOString(),
      toolVersion: "metrics/1",
      inputHashes: { graph: hash },
      timings: { load: t1 - t0, total: performance.now() - t0 },
    }
  };

  report = stableReport(report);
  const parsed = MetricsReport.parse(report);
  const outFile = args.out || METRICS_JSON;

  if (args.json) writeJSONPretty(outFile, parsed);
  else log.info(`clusters=${parsed.clusters} suburbs=${parsed.suburbs} undirected=${parsed.edges.undirected}`);
})().catch(e => { console.error("[metrics] fatal:", e); process.exit(1); });
