type ClusterRec = { slug: string; name: string; suburbs: { slug: string; name: string; lat?: number; lng?: number }[] };
type ClustersFile = { clusters: ClusterRec[] };
const clustersMods = import.meta.glob('/src/data/areas.clusters.json', { eager: true, import: 'default' }) as Record<string, ClustersFile | undefined>;
const clusterMapMods = import.meta.glob('/src/data/cluster_map.json', { eager: true, import: 'default' }) as Record<string, Record<string,string> | undefined>;
const CLUSTERS: ClustersFile = Object.values(clustersMods)[0] ?? { clusters: [] };
const CLUSTER_TO_REGION: Record<string,string> = Object.values(clusterMapMods)[0] ?? {};
const SUBURB_TO_CLUSTER = (() => { const m = new Map<string,string>(); for (const c of CLUSTERS.clusters) for (const s of c.suburbs) m.set(s.slug, c.slug); return m; })();
export type Suburb = { slug: string; name: string; lat?: number; lng?: number; cluster?: string; region?: string };
export function getAllSuburbs(): Suburb[] {
  const out: Suburb[] = []; for (const c of CLUSTERS.clusters) { const region = CLUSTER_TO_REGION[c.slug];
    for (const s of c.suburbs) out.push({ ...s, cluster: c.slug, region }); } return out;
}
export function findSuburbBySlug(slug: string): Suburb | null {
  const cl = SUBURB_TO_CLUSTER.get(slug); if (!cl) return null;
  const cluster = CLUSTERS.clusters.find(c => c.slug === cl); const rec = cluster?.suburbs.find(s => s.slug === slug);
  if (!rec) return null; const region = CLUSTER_TO_REGION[cluster!.slug]; return { ...rec, cluster: cluster!.slug, region };
}
