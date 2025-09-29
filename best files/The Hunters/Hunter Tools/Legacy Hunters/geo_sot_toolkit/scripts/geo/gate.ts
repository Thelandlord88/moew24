#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { DoctorReport } from "./lib/reports.js";
import { Policy, parseJsonc } from "./lib/policy.js";
import { parseArgs } from "./lib/args.js";
import { DOCTOR_JSON } from "./lib/paths.js";

const args = parseArgs(process.argv.slice(2));

function readJson(p: string) { return JSON.parse(readFileSync(p, "utf8")); }

try {
  // Read JSONC policy with comments
  const policy = Policy.parse(parseJsonc(readFileSync("geo.linking.config.jsonc","utf8")));
  // Explicitly read the doctor report from the canonical path
  const rep = DoctorReport.parse(readJson(DOCTOR_JSON));

  let fail=false, warn=false;
  const isolates = rep.degrees.histogram["0"] ?? 0;

  if (rep.largest_component_ratio < policy.graph.minLargestComponentRatio) fail = true;
  if (isolates > policy.graph.maxIsolates) fail = true;
  if (rep.degrees.mean < policy.graph.minMeanDegree) warn = true;

  const promotedShare = 0; // TODO: wire your promotion metric
  if (promotedShare > policy.fairness.maxPromotedShareFail) fail = true;
  else if (promotedShare > policy.fairness.maxPromotedShareWarn) warn = true;
  if (rep.cross_cluster_ratio > policy.fairness.maxPromotedCrossClusterRatio) fail = true;

  if (fail) { console.error("[gate] FAIL"); process.exit(1); }
  if (warn && args.strict) { console.error("[gate] WARN (strict)"); process.exit(2); }
  if (warn) console.warn("[gate] WARN");
  process.exit(0);
} catch (e) {
  console.error("[gate] FAIL (invalid policy/report):", e);
  process.exit(3);
}
