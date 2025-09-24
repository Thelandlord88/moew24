import path from 'node:path';

export async function loadPlugins(ctx, steps) {
  ctx._plugins = [];
  for (const step of steps) {
    const modPath = path.join(process.cwd(), `scripts/daedalus/plugins/${step}.mjs`);
    const mod = await import(modPath);
    const plugin = mod.default || mod;
    plugin.id ||= step;
    ctx._plugins.push(plugin);
    if (plugin.init) await plugin.init(ctx);
  }
}

export async function runStep(ctx, step, opts) {
  const plugin = ctx._plugins.find(p => p.id.includes(step));
  if (!plugin) throw new Error(`Missing plugin ${step}`);
  if (plugin.beforeAll) await plugin.beforeAll(ctx, opts);
  if (plugin.eachNode) {
    for (const node of ctx.targets) {
      await plugin.eachNode(ctx, node, opts);
    }
  }
  if (plugin.afterAll) await plugin.afterAll(ctx, opts);
}
