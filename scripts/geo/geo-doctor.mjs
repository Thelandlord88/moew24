#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path';
const DATA='src/data', OUT='__ai', TMP='tmp';
const p=(f)=>path.join(DATA,f);
const files={clusters:p('areas.clusters.json'), clusterMap:p('cluster_map.json'), adj:p('areas.adj.json'), prox:p('proximity.json'), cfg:p('geo.config.json')};
const read=(file,def)=>{try{if(!fs.existsSync(file))return{ok:false,err:'ENOENT',data:def};const r=fs.readFileSync(file,'utf8');return{ok:true,err:null,data:JSON.parse(r)}}catch(e){return{ok:false,err:String(e),data:def}}}
const clusters=read(files.clusters,{clusters:[]}), cmap=read(files.clusterMap,{}), adj=read(files.adj,{}), prox=read(files.prox,{nearby:{}}), cfg=read(files.cfg,{});
const issues={missing:[],schema:[],ref:[],warn:[],policy:[]}; const isStr=x=>typeof x==='string'&&x.trim(); const isNum=x=>typeof x==='number'&&Number.isFinite(x);
const clusterSlugs=[]; const subIndex=new Map(); const seenNames=new Set();

if(!clusters.ok) issues.missing.push(`Missing ${files.clusters}: ${clusters.err}`);
else if(!Array.isArray(clusters.data?.clusters)) issues.schema.push(`${files.clusters} must be {clusters:[]}`);
else for(const c of clusters.data.clusters){
  if(!isStr(c?.slug)) issues.schema.push(`Cluster missing slug`);
  else clusterSlugs.push(c.slug);
  if(!Array.isArray(c?.suburbs)) { issues.schema.push(`Cluster ${c?.slug} suburbs[] missing`); continue; }
  for(const s of c.suburbs){
    if(!isStr(s?.slug)) issues.schema.push(`Suburb in ${c?.slug} missing slug`);
    if(!isStr(s?.name)) issues.schema.push(`Suburb ${s?.slug} missing name`);
    if(subIndex.has(s.slug)) issues.schema.push(`Duplicate suburb slug "${s.slug}"`);
    if(seenNames.has(s.name?.toLowerCase())) issues.warn.push(`Duplicate suburb name "${s.name}"`);
    subIndex.set(s.slug,{name:s.name,lat:s.lat,lng:s.lng,cluster:c.slug});
    seenNames.add(s.name?.toLowerCase());
  }
}

if(cmap.ok) for(const k of Object.keys(cmap.data||{})) if(!clusterSlugs.includes(k)) issues.ref.push(`cluster_map references unknown cluster "${k}"`);
else issues.warn.push('cluster_map.json missing — region will be undefined');

if(adj.ok) for(const [src,list] of Object.entries(adj.data||{})){
  if(!subIndex.has(src)) issues.ref.push(`adjacency source "${src}" not in clusters`);
  if(!Array.isArray(list)) { issues.schema.push(`adjacency["${src}"] must be array`); continue; }
  for(const dst of list){ if(src===dst) issues.schema.push(`adjacency "${src}" contains self`); if(!subIndex.has(dst)) issues.ref.push(`adjacency "${src}" -> "${dst}" not in clusters`); }
}

if(prox.ok){ const n=prox.data?.nearby||{}; for(const [src,arr] of Object.entries(n)){
  if(!subIndex.has(src)) { issues.ref.push(`proximity source "${src}" not in clusters`); continue; }
  if(!Array.isArray(arr)) { issues.schema.push(`proximity["${src}"] must be array`); continue; }
  const seen=new Set();
  for(const it of arr){ if(!isStr(it?.slug)) issues.schema.push(`proximity["${src}"] item missing slug`);
    if(it?.slug===src) issues.schema.push(`proximity["${src}"] contains self`);
    if(seen.has(it?.slug)) issues.schema.push(`proximity["${src}"] duplicate "${it?.slug}"`);
    seen.add(it?.slug); if(it?.slug && !subIndex.has(it.slug)) issues.ref.push(`proximity["${src}"] -> "${it.slug}" not in clusters`);
  }
}}

let missLatLng=0,bad=0,zero=0; for(const [slug,r] of subIndex){ if(!isNum(r.lat)||!isNum(r.lng)) missLatLng++; else if(r.lat===0&&r.lng===0) zero++; else if(r.lat<-90||r.lat>90||r.lng<-180||r.lng>180) bad++; }
if(missLatLng) issues.warn.push(`${missLatLng} suburbs missing lat/lng`);
if(zero) issues.schema.push(`${zero} suburbs have lat/lng == 0 (placeholder)`);
if(bad) issues.schema.push(`${bad} suburbs with out-of-range coordinates`);

// Policy invariants: caps and consistency will be validated post-build; here we emit smoke paths
const first=[...subIndex.keys()].slice(0,6);
const paths=['/suburbs/','/services/', ...first.map(s=>`/suburbs/${s}/`), ...first.flatMap(s=>[`/services/spring-clean/${s}/`,`/services/bathroom-deep-clean/${s}/`])];
fs.mkdirSync(TMP,{recursive:true}); fs.writeFileSync(path.join(TMP,'smoke-paths.json'), JSON.stringify({paths},null,2));

const report={ timestamp:new Date().toISOString(), files:{...files}, counts:{clusters:clusterSlugs.length, suburbs:subIndex.size, adjacency: Object.keys(adj.data||{}).length, proximity: Object.keys(prox.data?.nearby||{}).length}, issues };
fs.mkdirSync(OUT,{recursive:true}); fs.writeFileSync(path.join(OUT,'geo-report.json'), JSON.stringify(report,null,2));
fs.writeFileSync(path.join(OUT,'geo-report.txt'), `Geo Doctor
Time: ${report.timestamp}
clusters: ${report.counts.clusters}
suburbs: ${report.counts.suburbs}
adjacency sources: ${report.counts.adjacency}
proximity sources: ${report.counts.proximity}

missing: ${issues.missing.length}
schema: ${issues.schema.length}
referential: ${issues.ref.length}
warnings: ${issues.warn.length}

Top messages:
${[...issues.missing,...issues.schema,...issues.ref,...issues.warn].slice(0,20).map(s=>' - '+s).join('\n')||' (none)'}
`);
const STRICT = process.argv.includes('--strict') || process.env.CI;
const fatal = [];
if(!clusters.ok) fatal.push('clusters missing/invalid');
if(issues.schema.length) fatal.push('schema errors');
if(issues.ref.length) fatal.push('referential errors');
if(STRICT && fatal.length){ console.error('[geo-doctor] FAIL:', fatal.join(', ')); process.exit(1); }
console.log('[geo-doctor] OK — see __ai/geo-report.* and tmp/smoke-paths.json');
