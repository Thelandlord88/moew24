import { runStep } from './plugins.mjs';
import graph from '../pipelines/geo-build.mjs';

export async function loadPipeline() { return graph; }

export async function runPipeline(ctx, pipeline, { mode='plan' } = {}) {
  // Choose step subset per mode
  const full = pipeline.steps;
  let steps = full;
  if (mode === 'plan' || mode === 'graph') {
    steps = full.filter(id => ['01-load-geo','02-derive-graph','05-internal-links','06-quality-gates'].includes(id));
  }
  for (const step of steps) {
    await runStep(ctx, step, { mode });
  }
}
