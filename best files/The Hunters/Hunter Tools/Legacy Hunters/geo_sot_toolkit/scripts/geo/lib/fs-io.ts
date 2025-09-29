import { mkdirSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

export function writeJSONPretty(path: string, data: unknown) {
  mkdirSync(dirname(path), { recursive: true });
  const text = JSON.stringify(data, null, 2).replace(/\r\n/g, "\n") + "\n";
  // Best-effort atomic: write tmp then final
  writeFileSync(path + ".tmp", text, { encoding: "utf8", mode: 0o644 });
  writeFileSync(path, text, { encoding: "utf8", mode: 0o644 });
}
