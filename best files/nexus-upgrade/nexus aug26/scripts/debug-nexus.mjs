#!/usr/bin/env node
import { exec as execCallback } from 'node:child_process';
import { promisify } from 'node:util';

const exec = promisify(execCallback);
const port = Number.parseInt(process.env.NEXUS_PORT ?? '45075', 10);
const host = process.env.NEXUS_HOST ?? '127.0.0.1';

const info = {
  processRunning: false,
  processOutput: '',
  statusOk: false,if i want to run a command in terminal to talk or check on nexus while you are working/talking to nexus like a status or a "push"
  
  also at one point 
  statusError: null,
  status: null,
};

async function checkProcess() {
  try {
    const { stdout } = await exec("ps -A -o pid,cmd | grep nexus-runtime.mjs | grep -v grep");
    if (stdout.trim()) {
      info.processRunning = true;
      info.processOutput = stdout.trim();
    }
  } catch {
    // ps exits with 1 when no matches; ignore
  }
}

async function checkStatus() {
  try {
    const response = await fetch(`http://${host}:${port}/status`, {
      signal: AbortSignal.timeout(3000),
    });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    const json = await response.json();
    info.statusOk = true;
    info.status = json;
  } catch (error) {
    info.statusError = error;
  }
}

function printReport() {
  console.log('🔍 NEXUS Runtime Diagnostics');
  console.log('────────────────────────────');
  console.log(`Port: ${port}`);
  console.log(`Host: ${host}`);
  console.log('');

  if (info.processRunning) {
    console.log('✅ Process: running');
    console.log(info.processOutput.split('\n').map((line) => `   ${line.trim()}`).join('\n'));
  } else {
    console.log('❌ Process: not running');
    console.log('   Start it with: node nexus/nexus-runtime.mjs');
  }
  console.log('');

  if (info.statusOk) {
    console.log('✅ Status endpoint reachable');
    const { initialized, patternsLoaded, enhancementsPerformed, breakthroughs, uptimeMs } = info.status;
    console.log(`   initialized: ${initialized}`);
    console.log(`   patternsLoaded: ${patternsLoaded}`);
    console.log(`   enhancementsPerformed: ${enhancementsPerformed}`);
    console.log(`   breakthroughs: ${breakthroughs}`);
    console.log(`   uptimeMs: ${uptimeMs}`);
  } else {
    console.log('❌ Status endpoint unreachable');
    if (info.statusError) {
      console.log(`   Reason: ${info.statusError.message ?? info.statusError}`);
    }
    console.log('   Try restarting the runtime.');
  }
  console.log('');

  if (info.status?.recentEvents?.length) {
    console.log('Recent events:');
    for (const evt of info.status.recentEvents.slice(-5)) {
      console.log(`   • ${evt.timestamp} – ${evt.personality}`);
    }
    console.log('');
  }

  if (info.status?.breakthroughMoments?.length) {
    console.log('Breakthroughs (latest):');
    const latest = info.status.breakthroughMoments.slice(-3);
    for (const moment of latest) {
      console.log(`   • ${moment.timestamp} – significance ${moment.significance}`);
    }
    console.log('');
  }
}

(async () => {
  await Promise.allSettled([checkProcess(), checkStatus()]);
  printReport();
})();
