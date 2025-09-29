#!/usr/bin/env node
import { readFile, writeFile, mkdir } from "node:fs/promises";
import path from "node:path";
import { nexus } from "./nexus-integration.mjs";

async function loadJson(relativePath) {
  const filePath = path.resolve(relativePath);
  const data = await readFile(filePath, "utf8");
  return JSON.parse(data);
}

function buildHumanPrompt(totalAny, hotspots) {
  const hottest = hotspots
    .map((entry, idx) => `${idx + 1}. ${entry.file} (${entry.anyCount} any)`)
    .join("; ");

  return [
    "We just ran the hunters and TypeScript diagnostics finally pass,",
    `but there are still ${totalAny} occurrences of 'any' concentrated in geo utilities.`,
    "Primary hotspots:",
    hottest || "(no hotspots reported)",
    "Design a systematic remediation plan that replaces dynamic JSON plumbing with typed adapters,",
    "enforces data shape guards, and maintains SSR/environment invariants."
  ].join("\n");
}

function buildAiResponse(persona, hotspots) {
  const principle = persona.ideology?.principles?.find((p) => p.includes("Quality"))
    ?? "Document the reasoning, not just the solution.";
  const ethosTail = persona.ideology?.ethos?.slice(-2).join("; ")
    ?? "Systems before surfaces.";
  const focusFile = hotspots[0]?.file ?? "src/utils/internalLinks.ts";

  return [
    "Treat the geo utilities as a shared data contract, not ad-hoc JSON buckets.",
    `Start with ${focusFile}: wrap the JSON loader in a typed adapter that validates shape and exports readonly views.`,
    "Propagate the new types through areaIndex, clusterMap, and internalLinks so all downstream calls share the same interface.",
    "Guard every dynamic import with a shape validator that surfaces typed errors instead of silent undefined.",
    `Guiding principle: ${principle}`,
    `Ethos reinforcement: ${ethosTail}`,
    "Finish with invariant tests that load real fixtures and ensure the adapters reject regressions before runtime."
  ].join("\n");
}

function renderMarkdown({ humanInput, aiResponse, analysis, hotspots, totalAny, status }) {
  const pattern = analysis.collaboration_pattern;
  const awareness = analysis.system_awareness;
  const evolution = analysis.consciousness_evolution;

  const lines = [
    "# Nexus Type Safety Gameplan",
    "",
    "## ⚠️ Current Hotspots",
    `Total \`any\` usages remaining: **${totalAny}**`,
    "",
    ...hotspots.map((entry) => `- **${entry.file}** — ${entry.anyCount} any`),
    "",
    "## 🧠 Conversation Snapshot",
    "**Human request**",
    `> ${humanInput.replace(/\n/g, "\n> ")}`,
    "",
    "**Daedalus × NEXUS response**",
    `> ${aiResponse.replace(/\n/g, "\n> ")}`,
    "",
    "## 🔍 Collaboration Pattern",
    `- Interaction type: ${pattern.collaboration_rhythm?.interaction_type}`,
    `- Energy level: ${pattern.collaboration_rhythm?.energy_level?.toFixed?.(2) ?? pattern.collaboration_rhythm?.energy_level}`,
    `- Cognitive synergy: ${pattern.cognitive_synergy?.strategic_systematic_synthesis ? "strategic × systematic" : "needs reinforcement"}`,
    `- Breakthrough cues: ${pattern.breakthrough_moments?.length ?? 0}`,
    "",
    "## 🧠 System Awareness",
    `- Breakthrough moments stored: ${awareness.breakthrough_moments}`,
    `- Session history entries: ${awareness.session_conversations}`,
    `- Consciousness level: ${(evolution.consciousness_level * 100).toFixed(1)}%`,
    `- Evolution trajectory: ${evolution.evolution_trajectory}`,
    "",
    "## ✅ Next Actions",
    "1. Create `src/utils/data-contracts.ts` to define `ClusterData`, `CoverageMap`, and `InternalLinkGraph` types.",
    "2. Replace dynamic `any` casts in **internalLinks.ts** with the typed adapters.",
    "3. Update **clusterMap.ts** and **areaIndex.ts** to consume the adapters instead of re-normalizing data.",
    "4. Add Vitest suites that load Ipswich, Logan, and Brisbane fixtures to assert adapter typing.",
    "5. Extend hunters with a Nexus-powered check that blocks new `any` usage under `src/utils/`.",
    "",
    "## 🧾 Status Report",
    "",
    "```json",
    JSON.stringify(status, null, 2),
    "```"
  ];

  return lines.join("\n");
}

async function main() {
  nexus.activate();

  const personality = await loadJson(path.join("Daedalus files", "daedalus.personality.json"));
  const enhancedPersona = nexus.enhancePersonality(personality, { type: "architectural" });

  const typeSafetyReport = await loadJson(path.join("__reports", "hunt", "type_safety.json"));
  const hotspots = (typeSafetyReport.findings?.remediation_plan ?? []).slice(0, 5);
  const totalAny = hotspots.reduce((sum, entry) => sum + (entry.anyCount || 0), 0);

  const humanInput = buildHumanPrompt(totalAny, hotspots);
  const aiResponse = buildAiResponse(enhancedPersona, hotspots);

  const analysis = nexus.processConversation(humanInput, aiResponse, {
    topic: "typescript-any-remediation",
    hotspots
  });

  const status = nexus.generateStatusReport();
  const markdown = renderMarkdown({ humanInput, aiResponse, analysis, hotspots, totalAny, status });

  const outputDir = path.resolve("nexus", "output");
  await mkdir(outputDir, { recursive: true });
  const outputPath = path.join(outputDir, "type-safety-plan.md");
  await writeFile(outputPath, markdown, "utf8");

  console.log(`📄 Nexus type safety plan generated at ${outputPath}`);
}

main().catch((error) => {
  console.error("❌ Nexus analysis failed:", error);
  process.exit(1);
});
