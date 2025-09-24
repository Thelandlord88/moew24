#!/usr/bin/env node
// thinker/index.mjs — Read all module JSON + var/hunt-events.ndjson → write a ranked agenda.
import fs from "node:fs";
import path from "node:path";

const REPORT_DIR = "__reports/hunt";
const OUT_DIR = "__ai/thinker";
const TRACE_FILE = "var/hunt-events.ndjson";
const POLICY_FILE = path.join(OUT_DIR, "thinker-policy.json");

fs.mkdirSync(OUT_DIR, { recursive: true });

// Tunable policy (no code edits needed)
const policy = fs.existsSync(POLICY_FILE)
  ? JSON.parse(fs.readFileSync(POLICY_FILE, "utf8"))
  : {
      weights: { severity: 3.0, recurrence: 1.6, blastRadius: 1.4, timeToFix: -0.8, unlocks: 1.2 },
      thresholds: { recommend: 2.0, critical: 4.0 },
      caps: { maxAgendaItems: 8 }
    };

// Load module reports, skipping master.json
let reports = [];
try {
  reports = fs
    .readdirSync(REPORT_DIR)
    .filter((f) => f.endsWith(".json") && f !== "master.json")
    .map((f) => {
      const body = JSON.parse(fs.readFileSync(path.join(REPORT_DIR, f), "utf8"));
      return { name: f.replace(/\.json$/, ""), ...body };
    });
} catch (e) {
  // no reports yet; proceed
  reports = [];
}

// Optional traces
const traces = fs.existsSync(TRACE_FILE)
  ? fs
      .readFileSync(TRACE_FILE, "utf8")
      .trim()
      .split("\n")
      .filter(Boolean)
      .map((l) => {
        try {
          return JSON.parse(l);
        } catch {
          return null;
        }
      })
      .filter(Boolean)
  : [];

const N = (x) => Math.log(1 + Math.max(0, x));
const score = (r) => {
  const sev = r.status === "critical" ? 2 : r.status === "warn" ? 1 : 0;
  const w = policy.weights;
  return (
    w.severity * sev +
    w.recurrence * N(r.issues || 0) +
    w.blastRadius * N(r.affected_files || 0) +
    w.timeToFix * N(r.eta_minutes || 10) +
    w.unlocks * ((r.unlocks && r.unlocks.length) || 0)
  );
};

const agenda = reports
  .filter((r) => Array.isArray(r.actions) && r.actions.length)
  .map((r) => ({
    module: r.module || r.name,
    status: r.status,
    score: +score(r).toFixed(2),
    actions: r.actions.slice(0, 5),
    proof: r.policy_invariants || [],
    why: [
      r.status === "critical" ? "severity:2" : null,
      r.issues ? `recurrence:${r.issues}` : null,
      r.affected_files ? `blast:${r.affected_files}` : null,
      r.unlocks?.length ? `unlocks:${r.unlocks.length}` : null
    ]
      .filter(Boolean)
      .join(" ")
  }))
  .sort((a, b) => b.score - a.score)
  .slice(0, policy.caps.maxAgendaItems);

// Trace-derived "hot files"
const hot = {};
for (const t of traces) {
  if (t.op === "open_file" && t.data?.path) hot[t.data.path] = (hot[t.data.path] || 0) + 1;
}

const out = {
  schemaVersion: 1,
  t: new Date().toISOString(),
  agenda,
  hotFiles: Object.entries(hot)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([path, count]) => ({ path, count })),
  notes: ["Prefer class-eliminating fixes; pair each with a proof-invariant and a sibling sweep."]
};

fs.writeFileSync(path.join(OUT_DIR, "master-insights.json"), JSON.stringify(out, null, 2));
console.log(`[thinker] wrote ${path.join(OUT_DIR, "master-insights.json")} with ${agenda.length} items`);
