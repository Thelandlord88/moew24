#!/usr/bin/env node
import fs from "node:fs"; import path from "node:path";
const base = process.env.GEO_BASE_DIR ? path.resolve(process.env.GEO_BASE_DIR) : process.cwd();
const P = { suburbs: path.join(base,"src/data/suburbs_enriched.geojson"), adjacency: path.join(base,"src/data/adjacency.json"), clusters: path.join(base,"src/data/clusters.json") };
const argv=process.argv.slice(2);
let FAIL_DUPLICATES=process.env.FAIL_DUPLICATES==="1";
let FAIL_MISSING_CLUSTERS=process.env.FAIL_MISSING_CLUSTERS==="1";
let FAIL_ORPHANS = Number.isFinite(+process.env.FAIL_ORPHANS)?+process.env.FAIL_ORPHANS:NaN;
for(const a of argv){ if(a==="--fail-duplicates") FAIL_DUPLICATES=true; if(a==="--fail-missing-clusters") FAIL_MISSING_CLUSTERS=true; if(a.startsWith("--fail-orphans=")) FAIL_ORPHANS=+a.split("=")[1]; }
const read=p=>JSON.parse(fs.readFileSync(p,"utf8"));
const geo=read(P.suburbs), adj=read(P.adjacency), clusters=read(P.clusters);
const norm=s=>(s||"").toString().trim().toLowerCase();
const geoNames=(geo.features||[]).map(f=>f.properties?.name_official||f.properties?.name||f.properties?.suburb||"").filter(Boolean).map(String);
const raw=new Map(); for(const n of geoNames) raw.set(norm(n),n);
let reciprocityErrors=0, orphans=0, centroidMissing=0;
for(const f of (geo.features||[])){ const k=Object.keys(f.properties||{}); const hasLat=k.includes("centroid_lat")||k.includes("lat")||k.includes("centroidLat"); const hasLon=k.includes("centroid_lon")||k.includes("lon")||k.includes("centroidLon"); if(!(hasLat&&hasLon)) centroidMissing++; }
const adjN={}; for(const [k,v] of Object.entries(adj)) adjN[norm(k)]=Array.isArray(v)?v.map(norm):[];
for(const [s,ns] of Object.entries(adjN)){ if(ns.length===0) orphans++; for(const n of ns){ const back=adjN[n]||[]; if(!back.includes(s)){ reciprocityErrors++; const sR=raw.get(s)||s, nR=raw.get(n)||n; console.error(`[doctor] Missing reciprocity: ${sR} -> ${nR} but not ${nR} -> ${sR}`); } } }
const clN={}; for(const [c,arr] of Object.entries(clusters)) clN[norm(c)]=(Array.isArray(arr)?arr:[]).map(norm);
const clustered=new Set(Object.values(clN).flat());
const missing=[...raw.keys()].filter(n=>!clustered.has(n));
const seen=new Map(); for(const [c,arr] of Object.entries(clN)){ for(const n of arr){ const L=seen.get(n)||[]; L.push(c); seen.set(n,L); } }
const dups=[...seen.entries()].filter(([,L])=>L.length>1);
console.log(`[doctor] OK: features=${geo.features.length}, clusters=${Object.keys(clusters).length}, reciprocityErrors=${reciprocityErrors}, orphans=${orphans}, centroidMissing=${centroidMissing}, duplicates=${dups.length}, missingCluster=${missing.length}`);
try{ const J=process.env.GEO_REPORT_JSON, M=process.env.GEO_REPORT_MD; if(J||M){ const rep={ summary:{features:geo.features.length,clusters:Object.keys(clusters).length,reciprocityErrors,orphans,centroidMissing,duplicates:dups.length,missingCluster:missing.length}, duplicates: dups.slice(0,200).map(([n,L])=>({suburb:raw.get(n)||n,clusters:L})), missingCluster: missing.map(n=>raw.get(n)||n)}; if(J) fs.writeFileSync(J, JSON.stringify(rep,null,2)); if(M){ let md=`# Doctor Report\nfeatures: ${rep.summary.features}\nclusters: ${rep.summary.clusters}\nreciprocityErrors: ${rep.summary.reciprocityErrors}\norphans: ${rep.summary.orphans}\ncentroidMissing: ${rep.summary.centroidMissing}\nduplicates: ${rep.summary.duplicates}\nmissingCluster: ${rep.summary.missingCluster}\n`; if(rep.duplicates.length){ md+=`\n**Duplicates (first 200):**\n- `+rep.duplicates.map(d=>`${d.suburb} -> [${d.clusters.join(', ')}]`).join("\n- "); } fs.writeFileSync(M, md+"\n"); } } }catch{}
if(reciprocityErrors>0) process.exit(1);
if(!Number.isNaN(FAIL_ORPHANS)&&orphans>FAIL_ORPHANS) process.exit(2);
if(FAIL_DUPLICATES&&dups.length>0) process.exit(3);
if(FAIL_MISSING_CLUSTERS&&missing.length>0) process.exit(4);
