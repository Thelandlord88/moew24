#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path';
import { Window } from 'happy-dom'; import { XMLParser } from 'fast-xml-parser';

const guard = JSON.parse(fs.readFileSync('__ai/visibility-flags.json','utf8'));
const MODE = process.argv.includes('--mode=postbuild') ? 'postbuild' : 'prebuild';
const STRICT = process.argv.includes('--strict') || !!process.env.CI;
const fail=(n,m)=>{ console.error(`[vis:${MODE}] ✗ ${n}: ${m}`); if(STRICT) process.exit(1); };
const ok=(n,m='')=>console.log(`[vis:${MODE}] ✓ ${n} ${m}`);

if (MODE==='prebuild') { ok('prebuild','(no-op)'); process.exit(0); }
if (!fs.existsSync('dist')) fail('dist','missing (build first)');

function* walkHtml(d='dist'){ for(const e of fs.readdirSync(d,{withFileTypes:true})){ const f=path.join(d,e.name); if(e.isDirectory()) yield* walkHtml(f); else if(e.isFile() && f.endsWith('.html')) yield f; } }
const read=(p)=>fs.readFileSync(p,'utf8');
const parse=(html)=>{ const doc=new Window().document; doc.body.innerHTML=html; return doc; };

// 1) UA-conditional DOM ban
if (guard.ethics.blockUAConditionals) {
  const assets = fs.existsSync('dist/assets') ? fs.readdirSync('dist/assets').filter(x=>x.endsWith('.js')) : [];
  const offenders = assets.filter(a=>/navigator\.userAgent|userAgentData/i.test(read(path.join('dist/assets', a))));
  offenders.length ? fail('ua-conditionals', offenders.join(', ')) : ok('ua-conditionals');
}

// 2) Hidden keyword stuffing ban (SR-only allowed)
if (guard.ethics.blockHiddenKeywordBlocks) {
  let issues=0;
  for (const f of walkHtml()) {
    const doc = parse(read(f));
    const hidden = [...doc.querySelectorAll('[hidden],[style*="display:none" i],[aria-hidden="true"]')];
    for (const el of hidden) {
      const cls = (el.getAttribute('class')||'').toLowerCase();
      if (guard.ethics.allowScreenReaderOnly && /\bsr-only|screen-reader-only\b/.test(cls)) continue;
      const text = (el.textContent||'').toLowerCase();
      if (!text.trim()) continue;
      if (guard.anchors.commercial.some(c=>text.includes(c.toLowerCase()))) { console.error(`[hidden] ${f}: hidden commercial text`); issues++; break; }
    }
  }
  issues ? fail('hidden-keywords', `${issues} file(s)`) : ok('hidden-keywords');
}

// 3) Ethical anchor economy (caps)
{
  const MAX = guard.anchors.maxSamePerPage;
  const COMM = new RegExp(`\\b(${guard.anchors.commercial.map(c=>c.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')).join('|')})\\b`,'i');
  let issues=0;
  for (const f of walkHtml()) {
    const doc = parse(read(f));
    const texts = [...doc.querySelectorAll('a')].map(a=>(a.textContent||'').trim().toLowerCase()).filter(Boolean);
    const freq = new Map(); for (const t of texts) if (COMM.test(t)) freq.set(t,(freq.get(t)||0)+1);
    for (const [t,c] of freq) if (c > MAX) { console.error(`[anchors] ${f}: "${t}" repeats ${c}x > ${MAX}`); issues++; }
  }
  issues ? fail('anchor-caps', `${issues} page(s)`) : ok('anchor-caps');
}

// 4) Nearby UI ↔ JSON-LD lockstep + cap
if (guard.nearby.requireLockstep) {
  const S = guard.nearby.selector;
  let issues=0;
  for (const f of walkHtml()) {
    const doc = parse(read(f));
    const sec = doc.querySelector(S.section); if (!sec) continue;
    const ui  = [...sec.querySelectorAll(S.ui)].map(a=>a.getAttribute('href')||'').filter(Boolean);
    const ldN = sec.querySelector(S.ld);
    if (!ldN) { console.error(`[lockstep] ${f}: missing nearby JSON-LD`); issues++; continue; }
    let ld; try { ld = JSON.parse(ldN.textContent||'{}'); } catch { console.error(`[lockstep] ${f}: invalid nearby JSON-LD`); issues++; continue; }
    const urls = (ld?.itemListElement||[]).map(x=>x?.url || x?.item || '').filter(Boolean);
    if (ui.length !== urls.length || ui.some((h,i)=>h!==urls[i])) { console.error(`[lockstep] ${f}: UI vs JSON-LD mismatch`); issues++; }
    if (ui.length > guard.nearby.maxItems) { console.error(`[lockstep] ${f}: nearby > ${guard.nearby.maxItems}`); issues++; }
  }
  issues ? fail('nearby-lockstep', `${issues} file(s)`) : ok('nearby-lockstep');
}

console.log('[vis:postbuild] complete');
