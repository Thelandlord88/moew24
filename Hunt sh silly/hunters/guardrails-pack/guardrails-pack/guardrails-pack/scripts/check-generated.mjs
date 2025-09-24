#!/usr/bin/env node
/**
 * Guardrail: block manual edits to generated JSON and verify outputs are fresh,
 * driven by scripts/generated.map.json.
 *
 * - Fails commit if a generated file is staged but none of its sources are.
 * - Re-runs generators and fails if diffs appear.
 *
 * Usage:
 *   node scripts/check-generated.mjs [--map=path] [--skip-gen]
 */
import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const argv = process.argv.slice(2);
const mapArg = argv.find(a => a.startsWith("--map="));
const MAP_PATH = mapArg ? mapArg.split("=")[1] : "scripts/generated.map.json";
const SKIP_GEN = argv.includes("--skip-gen");

function readMap(p) {
  if (!fs.existsSync(p)) {
    console.error(`❌ Map file not found: ${p}`);
    process.exit(1);
  }
  try {
    const raw = fs.readFileSync(p, "utf8");
    const parsed = JSON.parse(raw);
    if (!parsed.rules || !Array.isArray(parsed.rules)) {
      throw new Error("Map JSON must contain an array 'rules'.");
    }
    return parsed;
  } catch (e) {
    console.error(`❌ Failed to parse map JSON: ${p}`);
    console.error(e.message);
    process.exit(1);
  }
}

function git(cmd) {
  return execSync(`git ${cmd}`, { encoding: "utf8" }).trim();
}

function getStaged() {
  const out = git("diff --name-only --cached");
  return new Set(out.split("\n").filter(Boolean));
}

function isDir(p) {
  try {
    return fs.existsSync(p) && fs.statSync(p).isDirectory();
  } catch { return false; }
}

function pathChanged(set, pathOrDir) {
  if (isDir(pathOrDir)) {
    const prefix = pathOrDir.replace(/\/$/, "") + "/";
    for (const p of set) if (p.startsWith(prefix)) return true;
    return false;
  }
  return set.has(pathOrDir);
}

const spec = readMap(MAP_PATH);
const staged = getStaged();

// 1) Block manual edits: output changed but no inputs changed
const offenders = [];
for (const r of spec.rules) {
  const outChanged = pathChanged(staged, r.output);
  const anyInputChanged = (r.inputs || []).some((inp) => pathChanged(staged, inp));
  if (outChanged && !anyInputChanged) offenders.push(r.output);
}

if (offenders.length) {
  console.error("❌ Do not hand-edit generated files:");
  for (const f of offenders) console.error("   -", f);
  console.error("\nEdit sources or generator logic, then re-run gens. Aborting commit.");
  process.exit(1);
}

// 2) Freshness check: re-run gens and ensure no diffs
if (!SKIP_GEN) {
  const cmds = Array.from(new Set((spec.rules || []).map(r => r.gen).filter(Boolean)));
  for (const cmd of cmds) {
    try {
      console.log("▶", cmd);
      execSync(cmd, { stdio: "inherit", env: process.env });
    } catch (e) {
      console.error("❌ Generator failed:", cmd);
      process.exit(1);
    }
  }
} else {
  console.log("⏭  Skipping generator re-run (--skip-gen).");
}

// After regeneration, see if these files differ vs index
const outs = (spec.rules || []).map(r => r.output);
if (outs.length) {
  const diff = git(`diff --name-only -- ${outs.map(o => `'${o.replace(/'/g, "'\''")}'`).join(" ")}`);
  if (diff) {
    console.error("❌ Generated files are out of date:");
    console.error(diff.split("\n").map(s => "   - " + s).join("\n"));
    console.error("\nCommit the updated outputs (or run: npm run gen:all) and try again.");
    process.exit(1);
  }
}

console.log("✅ Generated files are fresh and guarded.");
process.exit(0);
