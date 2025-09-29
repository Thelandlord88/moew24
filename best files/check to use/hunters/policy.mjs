#!/usr/bin/env node
/**
 * scripts/thinker/policy.mjs — Evaluate strict + warn invariants across module reports.
 * Exits 1 in --strict if any strict invariant fails.
 */
import fs from "node:fs"; import path from "node:path";

const POLICY = JSON.parse(fs.readFileSync("hunters/policy.json","utf8"));
const RPT_DIR = "__reports/hunt";
const STRICT = process.argv.includes("--strict");
const EXPLAIN = process.argv.includes("--explain");
const STRICT_KEYS = process.argv.includes("--strict-keys");
const FAIL_WARN = process.argv.includes("--fail-warn");
const ONLY_NEW = process.argv.includes("--only-new");

const reports = {};
if (fs.existsSync(RPT_DIR)) {
  for (const f of fs.readdirSync(RPT_DIR)) {
    if (!f.endsWith(".json")) continue;
    const name = f.replace(/\.json$/,"");
  try { reports[name] = JSON.parse(fs.readFileSync(path.join(RPT_DIR,f),"utf8")); } catch { /* ignore malformed report */ }
  }
}

function get(pathExpr, hard = false) {
  // pathExpr: "module.key1.key2"
  const [mod, ...rest] = pathExpr.split(".");
  if (!reports[mod]) {
    if (hard) throw new Error(`[policy] module not found: ${mod}`);
    return undefined;
  }
  let cur = reports[mod];
  for (const k of rest) {
    if (!cur || typeof cur !== 'object' || !(k in cur)) {
      if (hard) throw new Error(`[policy] path missing: ${pathExpr} (stopped at '${k}')`);
      return undefined;
    }
    cur = cur[k];
  }
  return cur;
}

// --- Tokenization & Parsing (supports (), &&, ||, ??, contains, matches, exists) ---
function lex(expr){
  const tokens=[]; let cur=''; let inS=false,inD=false;
  const push=()=>{ if(cur.trim()) tokens.push(cur.trim()); cur=''; };
  for(let i=0;i<expr.length;i++){
    const c=expr[i];
    if(c==='"' && !inS){ inD=!inD; cur+=c; continue; }
    if(c==="'" && !inD){ inS=!inS; cur+=c; continue; }
    if(inS||inD){ cur+=c; continue; }
    if(/\s/.test(c)){ push(); continue; }
    if(c==='('||c===')'){ push(); tokens.push(c); continue; }
    if(expr.startsWith('&&',i)||expr.startsWith('||',i)||expr.startsWith('??',i)){
      push(); tokens.push(expr.substr(i,2)); i++; continue;
    }
    cur+=c;
  }
  push();
  return tokens;
}

let TOKENS; let POS;
function peek(){ return TOKENS[POS]; }
function next(){ return TOKENS[POS++]; }
function parseExpression(str){ TOKENS=lex(str); POS=0; return parseOr(); }
function parseOr(){ let node=parseAnd(); while(peek()==='||'){ next(); node={ type:'or', left:node, right:parseAnd() }; } return node; }
function parseAnd(){ let node=parsePrimary(); while(peek()==='&&'){ next(); node={ type:'and', left:node, right:parsePrimary() }; } return node; }
function parsePrimary(){
  if(peek()==='('){ next(); const inner=parseOr(); if(peek()!==')') throw new Error('missing )'); next(); return inner; }
  return parseSimple();
}
function parseSimple(){
  // Forms: exists path  | left [?? fallback] op right
  const start=peek();
  if(start==='exists'){ next(); const p=next(); return { type:'exists', path:p }; }
  const left=next();
  let fallback=null;
  if(peek()==='??'){ next(); fallback=next(); }
  const op=next();
  const rightTokens=[];
  while(peek() && !['&&','||',')'].includes(peek())) rightTokens.push(next());
  const right=rightTokens.join(' ');
  return { type:'simple', left, fallback, op, right };
}

function coalesceValue(raw){
  if(/^".*"$/.test(raw) || /^'.*'$/.test(raw)) return raw.slice(1,-1);
  if(/^\d+(\.\d+)?$/.test(raw)) return Number(raw);
  if(raw==='true'||raw==='false') return raw==='true';
  return get(raw, STRICT_KEYS);
}
function evalSimpleNode(node){
  if(node.type==='exists') {
    const val = get(node.path, false);
    const ok = val !== undefined; const explain=`exists ${node.path} -> ${ok?'PASS':'FAIL'}`;
    if(EXPLAIN) console.log('[explain]', explain);
    return { ok, detail: JSON.stringify({ exists:val!==undefined }), explain };
  }
  let leftVal;
  try { leftVal = get(node.left, STRICT_KEYS); } catch(e){ return { ok:false, detail:e.message, explain:'lhs-missing'}; }
  if(leftVal===undefined && node.fallback){
    try { leftVal = coalesceValue(node.fallback); } catch { leftVal = undefined; }
  }
  if(node.left && !node.left.endsWith('.length') && Array.isArray(leftVal) && ['>','<','>=','<=','==','!='].includes(node.op)) leftVal = leftVal.length;
  const rightVal = coalesceValue(node.right);
  let ok=true, err='';
  if(node.op==='contains') {
    if(Array.isArray(leftVal)) ok= leftVal.includes(rightVal); else if(typeof leftVal==='string') ok= leftVal.includes(String(rightVal)); else ok=false;
  } else if(node.op==='matches') {
    try { const re=new RegExp(String(rightVal)); ok= typeof leftVal==='string' && re.test(leftVal); } catch { ok=false; err='bad-regex'; }
  } else if(['==','!=','>','<','>=','<='].includes(node.op)) {
    switch(node.op){
      case '==': ok=(leftVal===rightVal); break;
      case '!=': ok=(leftVal!==rightVal); break;
      case '>': ok=(Number(leftVal) > Number(rightVal)); break;
      case '<': ok=(Number(leftVal) < Number(rightVal)); break;
      case '>=': ok=(Number(leftVal) >= Number(rightVal)); break;
      case '<=': ok=(Number(leftVal) <= Number(rightVal)); break;
    }
  } else { ok=false; err='unsupported-operator'; }
  const explain=`${node.left}${node.fallback?' ?? '+node.fallback:''} ${node.op} ${node.right} -> ${leftVal} ${node.op} ${rightVal} => ${ok?'PASS':'FAIL'}${err?' ('+err+')':''}`;
  if(EXPLAIN) console.log('[explain]', explain);
  return { ok, detail: JSON.stringify({ left:leftVal, op:node.op, right:rightVal }), explain };
}

function evalAst(ast){
  if(ast.type==='or') { const l=evalAst(ast.left); const r=evalAst(ast.right); return { ok:(l.ok||r.ok), detail:'', explain:`(${l.explain}) OR (${r.explain})` }; }
  if(ast.type==='and') { const l=evalAst(ast.left); const r=evalAst(ast.right); return { ok:(l.ok&&r.ok), detail:'', explain:`(${l.explain}) AND (${r.explain})` }; }
  return evalSimpleNode(ast);
}
function evalExpr(expr){
  let ast;
  try { ast = parseExpression(expr); } catch(e){ return { ok:false, detail:e.message, explain:'parse-error'}; }
  const res = evalAst(ast);
  return { ok:res.ok, detail:res.detail||'{}', explain:res.explain };
}

// Load last verdict for diff if available
let lastVerdict={};
try { lastVerdict = JSON.parse(fs.readFileSync("__ai/thinker/verdict.last.json","utf8")); } catch { /* no previous verdict */ }

function wasFail(prev, type, inv){ return Array.isArray(prev?.[type+"_fails"]) && prev[type+"_fails"].some(f=>f.inv===inv); }

const fails = [];
for (const inv of POLICY.strict_invariants||[]) {
  const { ok, detail } = evalExpr(inv);
  if (EXPLAIN) continue;
  if (!ok) {
    if(!ONLY_NEW || !wasFail(lastVerdict,'strict',inv)) fails.push({ type:'strict', inv, detail, new: !wasFail(lastVerdict,'strict',inv) });
  }
}
const warns = [];
for (const inv of POLICY.warn_invariants||[]) {
  const { ok, detail } = evalExpr(inv);
  if (EXPLAIN) continue;
  if (!ok) {
    if(!ONLY_NEW || !wasFail(lastVerdict,'warn',inv)) warns.push({ type:'warn', inv, detail, new: !wasFail(lastVerdict,'warn',inv) });
  }
}

// Attempt to load Thinker agenda for linking
let thinkerAgenda=[];
try {
  const mi = JSON.parse(fs.readFileSync("__ai/thinker/master-insights.json","utf8"));
  if(Array.isArray(mi.agenda)) thinkerAgenda = mi.agenda;
} catch { /* no master-insights yet */ }

function relatedAction(inv){
  const mod = inv.split(/\.|\s/)[0];
  const item = thinkerAgenda.find(a=> a.module===mod || a.path===mod || a.id===mod);
  if(!item) return null;
  const action = item.actions?.[0] || item.action || item.recommendation || 'See agenda';
  return { module: item.module||mod, score: item.score||item.priority||0, action };
}

const fixed_strict = (lastVerdict.strict_fails||[]).filter(f=> !fails.some(n=>n.inv===f.inv));
const fixed_warn = (lastVerdict.warn_fails||[]).filter(f=> !warns.some(n=>n.inv===f.inv));
const verdict = { strict_fails:fails, warn_fails:warns, modules:Object.keys(reports), summary:{ strict_fail_count:fails.length, warn_fail_count:warns.length, total_modules:Object.keys(reports).length, pass:fails.length===0, new_strict: fails.filter(f=>f.new).length, new_warn: warns.filter(f=>f.new).length, fixed_strict: fixed_strict.length, fixed_warn: fixed_warn.length }, agenda_linked: thinkerAgenda.length>0 };
fs.writeFileSync("__ai/thinker/verdict.json", JSON.stringify(verdict,null,2));
// Store copy for next diff
try { fs.writeFileSync("__ai/thinker/verdict.last.json", JSON.stringify(verdict,null,2)); } catch { /* ignore write issues */ }
// Human-friendly markdown summary
try {
  const md = [];
  md.push(`# 📜 Policy Verdict — ${new Date().toISOString()}`);
  md.push("");
  if (verdict.summary.pass) {
    md.push(`✅ **PASS** — All strict invariants satisfied`);
  } else {
    md.push(`❌ **FAIL** — ${verdict.summary.strict_fail_count} strict invariant(s) violated`);
  }
  if (verdict.warn_fails.length) md.push(`⚠️ ${verdict.warn_fails.length} warning issue(s)`); else md.push(`✅ No warnings`);
  md.push("");
  if(verdict.summary.new_strict) md.push(`🆕 New strict failures: ${verdict.summary.new_strict}`);
  if(verdict.summary.fixed_strict) md.push(`✅ Fixed strict since last run: ${verdict.summary.fixed_strict}`);
  md.push(`## ❌ Strict Failures (${verdict.strict_fails.length})`);
  if (!verdict.strict_fails.length) md.push(`_None_`); else {
    for (const f of verdict.strict_fails) {
  md.push(`- \`${f.inv}\`${f.new?' **(NEW)**':''} → ${f.detail}`);
      const rel = relatedAction(f.inv);
      if(rel) md.push(`  - ➡️ **Action:** ${rel.action} (score ${rel.score})`);
    }
  }
  md.push("");
  if(verdict.summary.new_warn) md.push(`🆕 New warnings: ${verdict.summary.new_warn}`);
  if(verdict.summary.fixed_warn) md.push(`✅ Fixed warnings since last run: ${verdict.summary.fixed_warn}`);
  md.push(`## ⚠️ Warnings (${verdict.warn_fails.length})`);
  if (!verdict.warn_fails.length) md.push(`_None_`); else {
    for (const f of verdict.warn_fails) {
  md.push(`- \`${f.inv}\`${f.new?' **(NEW)**':''} → ${f.detail}`);
      const rel = relatedAction(f.inv);
      if(rel) md.push(`  - ➡️ **Action:** ${rel.action} (score ${rel.score})`);
    }
  }
  md.push("");
  md.push(`## 📊 Summary`);
  md.push(`- Modules evaluated: ${verdict.summary.total_modules}`);
  md.push(`- Strict failures: ${verdict.summary.strict_fail_count}`);
  md.push(`- Warning failures: ${verdict.summary.warn_fail_count}`);
  md.push(`- Overall pass: ${verdict.summary.pass ? "✅ Yes" : "❌ No"}`);
  fs.writeFileSync("__ai/thinker/verdict.md", md.join("\n")+"\n");
} catch (e) {
  console.error('[policy] Failed to write verdict.md', e);
}
console.log("[policy] modules:", verdict.modules.join(", "));
if (EXPLAIN) {
  console.log("[policy] EXPLAIN MODE ONLY — no verdict enforcement");
  process.exit(0);
}
if (fails.length) {
  console.error("[policy] STRICT FAILS:", fails);
  if (STRICT) process.exit(1);
} else {
  console.log("[policy] strict OK");
}
if (warns.length) {
  console.warn("[policy] WARNINGS:", warns);
  if(FAIL_WARN) process.exit(1);
}
