#!/usr/bin/env node
/**
 * Run all generators defined in scripts/generated.map.json
 * - De-duplicates identical gen commands
 * - Runs sequentially (fail-fast)
 * Usage: node scripts/run-generators.mjs [--map=path]
 */
import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const argv = process.argv.slice(2);
const mapArg = argv.find(a => a.startsWith("--map="));
const MAP_PATH = mapArg ? mapArg.split("=")[1] : "scripts/generated.map.json";

function readMap(p) {
  if (!fs.existsSync(p)) {
    console.error(`❌ Map file not found: ${p}`);
    process.exit(1);
  }
  try {
    const raw = fs.readFileSync(p, "utf8");
    return JSON.parse(raw);
  } catch (e) {
    console.error(`❌ Failed to parse map JSON: ${p}`);
    console.error(e.message);
    process.exit(1);
  }
}

const spec = readMap(MAP_PATH);
const cmds = Array.from(new Set((spec.rules || []).map(r => r.gen).filter(Boolean)));

if (!cmds.length) {
  console.log("Nothing to generate (no rules or gens).");
  process.exit(0);
}

for (const cmd of cmds) {
  console.log("▶", cmd);
  try {
    execSync(cmd, { stdio: "inherit", env: process.env });
  } catch (e) {
    console.error("❌ Generator failed:", cmd);
    process.exit(1);
  }
}
console.log("✅ All generators completed.");
