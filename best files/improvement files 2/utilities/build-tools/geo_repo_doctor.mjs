#!/usr/bin/env node
// geo:doctor – validation (symmetry, cross-cluster edges, coordinate coverage, components, optional autofix)
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { primeGeoCompat, enrichedClusters, adjacency } from '../../src/lib/geoCompat.runtime.js';
import fsSync from 'node:fs';
import { performance } from 'node:perf_hooks';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function run(){
  const t0 = performance.now();
  await primeGeoCompat();
  const clusters = enrichedClusters();
  const adj = adjacency();
  const suburbToCluster=new Map(); const suburbHasCoords=new Map();
  for (const c of clusters) for (const s of (c.suburbs||[])) { const slug=String(s.slug).toLowerCase(); suburbToCluster.set(slug,c.slug); suburbHasCoords.set(slug, Number.isFinite(s.lat)&&Number.isFinite(s.lng)); }
  const suburbSet=new Set(suburbToCluster.keys());
  let directed=0, asym=0, cross=0; const seen=new Set();
  const undirectedKey=(a,b)=>{ const A=a.toLowerCase(),B=b.toLowerCase(); return A<B?`${A}|${B}`:`${B}|${A}`; };
  for (const [a,listRaw] of Object.entries(adj)) { const A=a.toLowerCase(); const list=Array.isArray(listRaw)?listRaw:[]; for (const b of list){ const B=String(b).toLowerCase(); directed++; const back=(adj[B]||[]).map(x=>String(x).toLowerCase()); if(!back.includes(A)) asym++; if(suburbSet.has(A)&&suburbSet.has(B)){ const k=undirectedKey(A,B); if(!seen.has(k)){ seen.add(k); if(suburbToCluster.get(A)!==suburbToCluster.get(B)) cross++; } } } }
  const undirectedEdgeCount=Math.round(directed/2);
  let withCoords=0; for(const s of suburbSet) if(suburbHasCoords.get(s)) withCoords++;
  const coordsPct=suburbSet.size? +(withCoords/suburbSet.size*100).toFixed(2):0;
  // Components (build undirected projection to avoid false splits with asymmetric edges)
  const nodes=new Set(Object.keys(adj)); for(const c of clusters) for(const s of (c.suburbs||[])) nodes.add(String(s.slug).toLowerCase());
  const undirectedMap=new Map();
  for (const n of nodes) undirectedMap.set(n, new Set());
  for (const [a,list] of Object.entries(adj)) {
    const A=a.toLowerCase(); if(!undirectedMap.has(A)) undirectedMap.set(A,new Set());
    for (const b of (list||[])) { const B=String(b).toLowerCase(); if(!undirectedMap.has(B)) undirectedMap.set(B,new Set()); undirectedMap.get(A).add(B); undirectedMap.get(B).add(A); }
  }
  const visited=new Set(); const comps=[]; for (const n of undirectedMap.keys()) { if(visited.has(n)) continue; const stack=[n]; const comp=[]; visited.add(n); while(stack.length){ const cur=stack.pop(); comp.push(cur); for (const m of undirectedMap.get(cur)||[]) if(!visited.has(m)){ visited.add(m); stack.push(m);} } comps.push(comp); }
  comps.sort((a,b)=> b.length-a.length); const largest=comps[0]?.length||0;
  const smallest = comps
    .slice() // copy
    .sort((a,b)=> a.length-b.length)
    .filter(c=>c.length<=20)
    .slice(0,5)
    .map(c=>({ size:c.length, nodes:c }));
  // Per-cluster coverage
  const coverageByCluster={};
  for (const c of clusters) {
    const subs=c.suburbs||[]; const total=subs.length||0; const good=subs.filter(s=>Number.isFinite(s.lat)&&Number.isFinite(s.lng)).length; coverageByCluster[c.slug]= total? +(good/total).toFixed(4):0;
  }
  // Hierarchical roll-up (optional)
  let hierarchyRollup=null;
  try {
    if(fsSync.existsSync('src/data/areas.hierarchical.clusters.json')){
      const raw=JSON.parse(await fs.readFile('src/data/areas.hierarchical.clusters.json','utf8'));
      // Compute coverage recursively: leaf coverage already in coverageByCluster; roll parents as weighted average
      const coverageMap = {...coverageByCluster};
      function compute(node){
        if(node.suburbs){ // leaf cluster
          const slug=node.slug; return coverageMap[slug] ?? 0; }
        if(node.children){
          let total=0, acc=0;
            for(const ch of node.children){
              const leafCov=compute(ch);
              // estimate weight by suburb count (leaf) else treat each child equally if missing
              const weight = (ch.suburbs? ch.suburbs.length: 1) || 1;
              acc += leafCov * weight; total += weight;
            }
          const cov = total? +(acc/total).toFixed(4):0;
          coverageMap[node.slug]=cov; return cov;
        }
        return 0;
      }
      for(const top of raw) compute(top);
      hierarchyRollup=coverageMap;
    }
  } catch {}
  const report={ clusters:clusters.length, suburbs:suburbSet.size, edges:{ directed, undirected: undirectedEdgeCount }, asymmetry_edges:asym, cross_cluster_edges:cross, coords_coverage_pct:coordsPct, coverage_by_cluster: coverageByCluster, cluster_coverage: coverageByCluster, hierarchy_rollup: hierarchyRollup, graph_components:{ count:comps.length, largest_size:largest, largest_ratio: nodes.size? +(largest/nodes.size).toFixed(3):1, smallest }, meta:{ timings:{} } };
  // Autofix symmetry optional
  if(process.env.GEO_AUTOFIX_SYMMETRY==='1' && report.asymmetry_edges>0){ let added=0; const fixed=JSON.parse(JSON.stringify(adj)); for(const [a,list] of Object.entries(adj)){ const clean=Array.from(new Set((list||[]).filter(x=> x && x!==a))); fixed[a]=clean; for(const b of clean){ if(!fixed[b]) continue; if(b===a) continue; if(!fixed[b].includes(a)){ fixed[b].push(a); added++; } } }
    for (const k of Object.keys(fixed)) fixed[k]=Array.from(new Set((fixed[k]||[]).filter(x=>x!==k))).sort();
    report.autofix={ enabled:true, added_edges:added, output:'__reports/geo-adjacency.symmetric.json' }; const symOut=path.resolve(__dirname,'../../__reports/geo-adjacency.symmetric.json'); await fs.writeFile(symOut, JSON.stringify(fixed,null,2)); }
  else if(process.env.GEO_AUTOFIX_SYMMETRY==='1'){ report.autofix={ enabled:true, added_edges:0 }; } else { report.autofix={ enabled:false }; }
  const parseInf=(v)=>{ if(v===undefined||v===null) return Infinity; const s=String(v).trim().toLowerCase(); if(['infinity','inf','∞'].includes(s)) return Infinity; const n=Number(v); return Number.isFinite(n)? n : Infinity; };
  const thresholds={
    minClusters:Number(process.env.GEO_MIN_CLUSTERS??1),
    requireSymmetry:(process.env.GEO_REQUIRE_SYMMETRY??'true')==='true',
    minCoordsPct:Number(process.env.GEO_MIN_COORDS_PCT??80),
    maxCrossClusterEdges: parseInf(process.env.GEO_MAX_CROSS_CLUSTER_EDGES),
    maxComponents: parseInf(process.env.GEO_MAX_COMPONENTS)
  };
  let ok=true; const failures=[];
  if(report.clusters < thresholds.minClusters){ ok=false; failures.push(`clusters=${report.clusters} < ${thresholds.minClusters}`); }
  if(thresholds.requireSymmetry && report.asymmetry_edges>0){ ok=false; failures.push(`asymmetry_edges=${report.asymmetry_edges}`); }
  if(report.coords_coverage_pct < thresholds.minCoordsPct){ ok=false; failures.push(`coords_coverage_pct=${report.coords_coverage_pct}% < ${thresholds.minCoordsPct}%`); }
  if(Number.isFinite(thresholds.maxCrossClusterEdges) && report.cross_cluster_edges > thresholds.maxCrossClusterEdges){ ok=false; failures.push(`cross_cluster_edges=${report.cross_cluster_edges} > ${thresholds.maxCrossClusterEdges}`); }
  if(Number.isFinite(thresholds.maxComponents) && report.graph_components.count > thresholds.maxComponents){ ok=false; failures.push(`graph_components.count=${report.graph_components.count} > ${thresholds.maxComponents}`); }
  const serInf=v=> v===Infinity? 'Infinity': v;
  const thresholdsOut={ ...thresholds, maxCrossClusterEdges: serInf(thresholds.maxCrossClusterEdges), maxComponents: serInf(thresholds.maxComponents) };
  const tEnd = performance.now();
  report.meta.timings.doctor_ms = +(tEnd - t0).toFixed(1);
  const outFile=path.resolve(__dirname,'../../__reports/geo-doctor.json'); await fs.mkdir(path.dirname(outFile),{recursive:true}); await fs.writeFile(outFile, JSON.stringify({ report, thresholds: thresholdsOut, ok, failures }, null,2));
  console.log('[geo:doctor] wrote', outFile);
  if(!ok){ console.error('[geo:doctor] FAIL', failures.join('; ')); process.exit(1);} console.log('[geo:doctor] OK');
}
run().catch(e=>{ console.error('[geo:doctor] ERROR', e); process.exit(1); });
