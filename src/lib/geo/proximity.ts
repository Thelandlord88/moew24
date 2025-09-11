import { findSuburbBySlug, getAllSuburbs } from '@/lib/suburbs';
type NearbyItem = { slug: string; name: string };
type ProximityFile = { nearby: Record<string, NearbyItem[]> };
type AdjacencyFile = Record<string, string[]>;
type GeoCfg = { nearby?: { limit?: number }, adjacencyBoost?: number, clusterBoost?: number, biasKm?: number, crossClusterPenalty?: number };
const proxMods = import.meta.glob('/src/data/proximity.json', { eager: true, import: 'default' }) as Record<string, ProximityFile | undefined>;
const adjMods  = import.meta.glob('/src/data/areas.adj.json', { eager: true, import: 'default' }) as Record<string, AdjacencyFile | undefined>;
const cfgMods  = import.meta.glob('/src/data/geo.config.json', { eager: true, import: 'default' }) as Record<string, GeoCfg | undefined>;
const PROX = Object.values(proxMods)[0] ?? { nearby: {} };
const ADJ  = Object.values(adjMods)[0]  ?? {};
const CFG  = Object.values(cfgMods)[0]  ?? {};
const LIMIT = Math.max(1, Number(CFG?.nearby?.limit ?? 6));
const W = { adjacency: Number(CFG?.adjacencyBoost ?? 24), cluster: Number(CFG?.clusterBoost ?? 200), biasKm: Number(CFG?.biasKm ?? 12), crossPenalty: Number(CFG?.crossClusterPenalty ?? 200) };
function haversineKm(a:{lat:number,lng:number}, b:{lat:number,lng:number}){const toRad=(x:number)=>x*Math.PI/180,R=6371;const dLat=toRad(b.lat-a.lat),dLng=toRad(b.lng-a.lng);const s=Math.sin(dLat/2)**2+Math.cos(toRad(a.lat))*Math.cos(toRad(b.lat))*Math.sin(dLng/2)**2;return 2*R*Math.asin(Math.sqrt(s));}
export function findNearbySuburbs(sourceSlug: string, opts?: { limit?: number }) {
  const limit = Math.max(1, opts?.limit ?? LIMIT);
  const src = findSuburbBySlug(sourceSlug); if (!src) return [];
  const pre = PROX.nearby?.[sourceSlug] || []; if (pre.length) return pre.slice(0, limit);
  const seed = (ADJ[sourceSlug] || []).map(slug => findSuburbBySlug(slug)).filter(Boolean).map(s=>({slug:s!.slug,name:s!.name}));
  if (seed.length >= limit) return seed.slice(0, limit);
  const pool = getAllSuburbs().filter(s => s.slug !== sourceSlug);
  const withScore = pool.map(s => {
    let score = 0; const sameCluster = src.cluster && s.cluster && src.cluster === s.cluster;
    if ((ADJ[sourceSlug] || []).includes(s.slug)) score += W.adjacency;
    score += sameCluster ? W.cluster : -W.crossPenalty;
    if (typeof src.lat==='number'&&typeof src.lng==='number'&&typeof s.lat==='number'&&typeof s.lng==='number'){ const km=haversineKm({lat:src.lat!,lng:src.lng!},{lat:s.lat!,lng:s.lng!}); score += -W.biasKm*km; }
    return { s, score };
  }).sort((a,b)=> b.score - a.score);
  const uniq = new Map<string, NearbyItem>();
  for (const { s } of [ ...seed.map(x=>({ s: x })), ...withScore ]) {
    const slug = (s as any).slug, name = (s as any).name; if (!slug || uniq.has(slug)) continue; uniq.set(slug, { slug, name }); if (uniq.size >= limit) break;
  }
  return Array.from(uniq.values()).slice(0, limit);
}
