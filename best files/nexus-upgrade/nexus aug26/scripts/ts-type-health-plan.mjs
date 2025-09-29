#!/usr/bin/env node
import { existsSync } from "node:fs";
import { mkdir, writeFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, "..");
process.chdir(ROOT);

const REPORT_DIR = process.env.REPORT_DIR || "__reports/hunt";
await mkdir(REPORT_DIR, { recursive: true });
const RAW_JSON_PATH = path.join(REPORT_DIR, "typescript.diagnostics.raw.json");

const TYPESCRIPT_VERSION = "5.9.2";

let command = "";
let args = [];
let usedLocalTsc = false;

const localTscPath = path.join(ROOT, "node_modules", ".bin", process.platform === "win32" ? "tsc.cmd" : "tsc");
if (existsSync(localTscPath)) {
  command = localTscPath;
  args = ["--noEmit", "--pretty", "false"];
  usedLocalTsc = true;
} else {
  command = "npx";
  args = ["--yes", "--package", `typescript@${TYPESCRIPT_VERSION}`, "tsc", "--noEmit", "--pretty", "false"];
}

const run = spawnSync(command, args, {
  cwd: ROOT,
  encoding: "utf8",
  env: {
    ...process.env,
    FORCE_COLOR: "0",
  },
});

const stdout = run.stdout || "";
const stderr = run.stderr || "";
const combined = `${stdout}\n${stderr}`.trim();

const errorLines = combined
  .split(/\r?\n/)
  .filter((line) => /error TS\d+:/.test(line));

const warningLines = combined
  .split(/\r?\n/)
  .filter((line) => /warning TS\d+:/.test(line));

const remediationPlan = [];
if (!combined) {
  remediationPlan.push("TypeScript produced no output. Verify project includes TypeScript sources and configuration.");
}
if (run.error) {
  remediationPlan.push(`Failed to run ${command}: ${run.error.message}`);
}
if (errorLines.length > 0) {
  remediationPlan.push("Resolve TypeScript errors reported in diagnostics output.");
}
if (!usedLocalTsc) {
  remediationPlan.push("Install repository dependencies (npm install) to use the local TypeScript compiler.");
}

const summary = {
  timestamp: new Date().toISOString(),
  command: [command, ...args],
  usedLocalTsc,
  exit_code: typeof run.status === "number" ? run.status : null,
  errors: errorLines.length,
  warnings: warningLines.length,
  remediation_plan: remediationPlan,
  output_preview: combined.split(/\r?\n/).slice(0, 200),
};

await writeFile(RAW_JSON_PATH, JSON.stringify({
  timestamp: summary.timestamp,
  summary: {
    exit_code: summary.exit_code,
    errors: summary.errors,
    warnings: summary.warnings,
  },
  remediation_plan: summary.remediation_plan,
  command: summary.command,
  usedLocalTsc: summary.usedLocalTsc,
  output_preview: summary.output_preview,
}, null, 2));

if (combined) {
  console.log(combined);
}

process.exit(typeof run.status === "number" ? run.status : 0);
