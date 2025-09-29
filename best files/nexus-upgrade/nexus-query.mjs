#!/usr/bin/env node
import process from 'node:process';

const port = Number.parseInt(process.env.NEXUS_PORT ?? '45075', 10);
const connectionTimeoutMs = Number.parseInt(process.env.NEXUS_CONNECT_TIMEOUT_MS ?? '3000', 10);
const requestTimeoutMs = Number.parseInt(process.env.NEXUS_REQUEST_TIMEOUT_MS ?? '12000', 10);
const totalTimeoutMs = connectionTimeoutMs + requestTimeoutMs;
const personalityName = process.env.NEXUS_PERSONALITY ?? 'daedalus';
const request = process.argv.slice(2).join(' ').trim();

if (!request) {
  console.error('Usage: node scripts/nexus-query.mjs "<message>"');
  process.exit(1);
}

const controller = new AbortController();
const startTime = Date.now();
let abortedByConnectTimeout = false;

const connectionTimer = setTimeout(() => {
  abortedByConnectTimeout = true;
  controller.abort();
}, connectionTimeoutMs);

const totalTimer = setTimeout(() => {
  controller.abort();
}, totalTimeoutMs);

const safeRequest = request.length > 4000 ? `${request.slice(0, 4000)}… (truncated)` : request;
const preview = request.length > 120 ? `${request.slice(0, 120)}…` : request;

console.log(`🧠 Sending to NEXUS on port ${port}: "${preview}"`);

try {
  const response = await fetch(`http://127.0.0.1:${port}/enhance`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    signal: controller.signal,
    body: JSON.stringify({
      personalityName,
      request: safeRequest,
    }),
  });

  clearTimeout(connectionTimer);

  if (!response.ok) {
    throw new Error(`Nexus returned HTTP ${response.status}`);
  }

  const json = await response.json();
  console.log(JSON.stringify(json, null, 2));
} catch (error) {
  const elapsed = Date.now() - startTime;
  if (error.name === 'AbortError') {
    if (abortedByConnectTimeout || elapsed <= connectionTimeoutMs + 50) {
      console.error(`⏳ Connection timeout after ${connectionTimeoutMs}ms — NEXUS runtime may not be running on port ${port}.`);
      console.error('   Start it with: node nexus/nexus-runtime.mjs');
    } else {
      console.error(`⏰ Request timed out after ${totalTimeoutMs}ms waiting for NEXUS to respond.`);
    }
  } else {
    const code = error?.cause?.code ?? error.code;
    if (code === 'ECONNREFUSED') {
      console.error(`❌ Connection refused on port ${port} — NEXUS runtime is not running.`);
      console.error('   Start it with: node nexus/nexus-runtime.mjs');
    } else if (code === 'ENOTFOUND') {
      console.error('❌ Unable to resolve localhost — check your network configuration.');
    } else {
      console.error('Failed to reach NEXUS:', error.message ?? error);
    }
  }
  process.exitCode = 1;
} finally {
  clearTimeout(connectionTimer);
  clearTimeout(totalTimer);
}
