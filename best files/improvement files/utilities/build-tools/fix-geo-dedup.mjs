#!/usr/bin/env node
// Remove duplicate features by properties.slug from suburbs_enriched.geojson
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';

const ROOT = process.argv.includes('--root') ? path.resolve(process.argv[process.argv.indexOf('--root')+1]) : process.cwd();
const FILE = path.join(ROOT, 'src', 'data', 'suburbs_enriched.geojson');

function must(c, m){ if(!c) throw new Error(m); }

async function main(){
  must(fs.existsSync(FILE), `[dedup] File not found: ${FILE}`);
  const src = await fsp.readFile(FILE, 'utf8');
  let json;
  try { json = JSON.parse(src); } catch (e) { throw new Error(`[dedup] Invalid JSON: ${e.message}`); }
  must(json && json.type === 'FeatureCollection' && Array.isArray(json.features), '[dedup] Not a FeatureCollection');
  const seen = new Set();
  const out = [];
  let dupes = 0, missing = 0;
  for (const f of json.features){
    const slug = String((f.properties && f.properties.slug) || '').trim().toLowerCase();
    if (!slug){ missing++; continue; }
    if (seen.has(slug)) { dupes++; continue; }
    seen.add(slug); out.push(f);
  }
  const next = { ...json, features: out };
  const txt = JSON.stringify(next, null, 0);
  await fsp.writeFile(FILE, txt, 'utf8');
  console.log(`[dedup] features: ${json.features.length} -> ${out.length}; removed dupes=${dupes}, missingSlug=${missing}`);
}

main().catch(e => { console.error(e.message); process.exit(1); });
 
