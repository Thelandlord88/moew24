import crypto from "node:crypto";

export function stableGraphHash(adj: Record<string,string[]>) {
  const sorted = Object.keys(adj).sort()
    .map(k => [k, [...(adj[k]||[])].sort()]);
  return crypto.createHash("sha256").update(JSON.stringify(sorted)).digest("hex");
}
