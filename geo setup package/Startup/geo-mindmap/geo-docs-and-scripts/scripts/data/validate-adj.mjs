#!/usr/bin/env node
import fs from "node:fs/promises";

const adjPath = "src/data/areas.adj.json";
const clustersPath = "src/data/areas.clusters.json";

const readJSON = async (p) => JSON.parse(await fs.readFile(p, "utf8"));

(async () => {
  const [adj, clusters] = await Promise.all([readJSON(adjPath), readJSON(clustersPath)]);

  const ids = new Set(Object.keys(clusters));
  const adjIds = Object.keys(adj);
  if (!adjIds.length) {
    console.error("❌ areas.adj.json has no nodes.");
    process.exit(1);
  }

  let unknownNodes = 0, unknownEdges = 0, selfLoops = 0, asym = 0;

  for (const id of adjIds) {
    if (!ids.has(id)) unknownNodes++;
    const nbrs = Array.isArray(adj[id]) ? adj[id] : [];
    for (const n of nbrs) {
      if (!ids.has(n)) unknownEdges++;
      if (n === id) selfLoops++;
      const back = (adj[n] || []);
      if (!back.includes(id)) asym++;
    }
  }

  if (unknownNodes) console.error(`❌ ${unknownNodes} node(s) not in clusters.`);
  if (unknownEdges) console.error(`❌ ${unknownEdges} edge endpoint(s) not in clusters.`);
  if (selfLoops) console.error(`❌ ${selfLoops} self-loop(s) present.`);
  if (asym) console.error(`❌ ${asym} asymmetric edge(s) detected.`);

  if (unknownNodes || unknownEdges || selfLoops || asym) process.exit(1);

  console.log(`✅ adjacency valid: ${adjIds.length} nodes`);
})();
