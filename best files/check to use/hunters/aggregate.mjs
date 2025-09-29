#!/usr/bin/env node
/**
 * scripts/thinker/aggregate.mjs — Reads __reports/hunt/*.json + var/hunt-events.ndjson
 * → Writes __ai/thinker/master-insights.json and DO_NEXT.md (ranked agenda).
 */
import fs from "node:fs"; import path from "node:path";

const CFG = JSON.parse(fs.readFileSync("__ai/thinker/config.json","utf8"));
const RPT_DIR = "__reports/hunt";
const TRACE = "var/hunt-events.ndjson";
const OUT_DIR = "__ai/thinker";
fs.mkdirSync(OUT_DIR, { recursive: true });

const reports = fs.existsSync(RPT_DIR)
  ? fs.readdirSync(RPT_DIR).filter(f=>f.endsWith(".json")).map(f=>({ name:f.replace(/\.json$/,""), data: JSON.parse(fs.readFileSync(path.join(RPT_DIR,f),"utf8")) }))
  : [];

const traces = fs.existsSync(TRACE)
  ? fs.readFileSync(TRACE,"utf8").trim().split("\n").map(l=>{try{return JSON.parse(l)}catch{return null}}).filter(Boolean)
  : [];

const feat = r => ({ sev:r.status==="critical"?2:r.status==="warn"?1:0, rec:r.issues||0, br:r.affected_files||0, ttf:r.eta_minutes||15, unl:(r.unlocks||[]).length });
const N = x => Math.log(1+Math.max(0,x));
const score = f => CFG.weights.severity*f.sev + CFG.weights.recurrence*N(f.rec) + CFG.weights.blast*N(f.br) + CFG.weights.timeToFix*N(f.ttf) + CFG.weights.unlocks*f.unl;

const agenda = reports.flatMap(({name, data}) => {
  const r = data;
  const f = feat(r);
  const s = score(f);
  if (!Array.isArray(r.actions) || r.actions.length===0) return [];
  if (s < (CFG.thresholds.recommend||2)) return [];
  return [{
    module: r.module || name,
    status: r.status,
    score: +s.toFixed(2),
    evidence: { issues: r.issues||0, counts: r.counts||{}, eta: r.eta_minutes||null, unlocks: r.unlocks||[] },
    actions: r.actions.slice(0,6),
    proofs: r.policy_invariants||[]
  }];
}).sort((a,b)=>b.score-a.score).slice(0, CFG.thresholds.maxAgenda||12);

const hotMap = {}; for (const t of traces) if (t.op==="open_file" && t.data?.path) hotMap[t.data.path]=(hotMap[t.data.path]||0)+1;
const hotFiles = Object.entries(hotMap).sort((a,b)=>b[1]-a[1]).slice(0, CFG.hotFilesTopN).map(([path,count])=>({path,count}));

const memoryFile = CFG.memoryFile || path.join(OUT_DIR,"memory.json");
let memory = fs.existsSync(memoryFile) ? JSON.parse(fs.readFileSync(memoryFile,"utf8")) : { plays:{} };

// Learn: boost plays that repeatedly turned critical→pass.
for (const { module, status, evidence } of agenda) {
  const key = `${module}`;
  const prev = memory.plays[key]?.lastStatus || null;
  if (prev && prev==="critical" && status !== "critical") {
    memory.plays[key] = { success_count: (memory.plays[key]?.success_count||0) + 1, lastStatus: status };
  } else {
    memory.plays[key] = { success_count: (memory.plays[key]?.success_count||0), lastStatus: status };
  }
}
fs.writeFileSync(memoryFile, JSON.stringify(memory,null,2));

const INSIGHTS = { t: new Date().toISOString(), agenda, hotFiles, modules: reports.map(r=>r.name) };
fs.writeFileSync(path.join(OUT_DIR,"master-insights.json"), JSON.stringify(INSIGHTS,null,2));

// Render DO_NEXT.md
const lines = [];
lines.push("# Hunter Thinker — Do‑Next Agenda\n");
agenda.forEach((a,i)=>{
  lines.push(`## ${i+1}. ${a.module}  —  ${a.status.toUpperCase()}  (score ${a.score})`);
  lines.push("");
  lines.push("**Evidence**");
  lines.push("```json"); lines.push(JSON.stringify(a.evidence,null,2)); lines.push("```");
  if (a.actions?.length) { lines.push("**Actions**"); a.actions.forEach(x=>lines.push(`- ${x}`)); }
  if (a.proofs?.length)  { lines.push("**Proof invariants**"); a.proofs.forEach(x=>lines.push(`- \`${x}\``)); }
  lines.push("");
});
if (hotFiles.length) {
  lines.push("## Hot files (focus areas)");
  hotFiles.forEach(h=>lines.push(`- ${h.path}  (${h.count})`));
}
fs.writeFileSync(path.join(OUT_DIR,"DO_NEXT.md"), lines.join("\n"));

console.log("[thinker] wrote __ai/thinker/master-insights.json and DO_NEXT.md");
