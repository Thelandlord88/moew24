export function roundFloat(n: number, p = 6) {
  const m = 10 ** p; return Math.round(n * m) / m;
}
export function stableReport<T extends Record<string, any>>(r: T): T {
  function walk(v: any): any {
    if (typeof v === "number") return Number.isFinite(v) ? roundFloat(v) : v;
    if (Array.isArray(v)) return v.map(walk);
    if (v && typeof v === "object") {
      const out: Record<string, any> = {};
      for (const k of Object.keys(v).sort()) out[k] = walk(v[k]);
      return out;
    }
    return v;
  }
  return walk(r);
}
