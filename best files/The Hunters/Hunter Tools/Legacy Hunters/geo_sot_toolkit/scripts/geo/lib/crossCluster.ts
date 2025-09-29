export function mapNodeToCluster(
  clusters: { slug: string; suburbs: { slug: string }[] }[]
) {
  const m: Record<string,string> = {};
  for (const c of clusters) for (const s of c.suburbs)
    m[s.slug.toLowerCase()] = c.slug.toLowerCase();
  return m;
}

export function crossClusterRatio(
  adj: Record<string,string[]>,
  nodeToCluster: Record<string,string>
) {
  let cross=0, total=0;
  const keys = Object.keys(adj).sort();
  for (const u of keys) for (const v of adj[u]) if (u < v) {
    total++;
    if (nodeToCluster[u] && nodeToCluster[v] && nodeToCluster[u] !== nodeToCluster[v]) cross++;
  }
  return { crossEdges: cross, totalEdges: total, ratio: total ? cross/total : 0 };
}
