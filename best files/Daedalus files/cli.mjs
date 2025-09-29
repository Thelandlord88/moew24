#!/usr/bin/env node
import { createContext } from './core/context.mjs';
import { loadPipeline, runPipeline } from './core/pipeline.mjs';
import { loadPlugins } from './core/plugins.mjs';
import { log } from './util/log.mjs';

function parseArgs(argv) {
  const out = { _: [] };
  for (const a of argv.slice(2)) {
    if (a.startsWith('--')) {
      const [k,v]=a.replace(/^--/,'').split('=');
      out[k]= v===undefined ? true : v;
    } else {
      out._.push(a);
    }
  }
  return out;
}

const args = parseArgs(process.argv);
const cmd = args._[0] || 'plan';

(async () => {
  try {
    const ctx = await createContext({ args });
    const pipeline = await loadPipeline('geo-build');
    await loadPlugins(ctx, pipeline.steps);
    await runPipeline(ctx, pipeline, { mode: cmd });
    log.success(`${cmd.toUpperCase()} complete`);
  } catch (e) {
    log.error(e && (e.stack || e.message) || String(e));
    process.exit(1);
  }
})();
