import fs from "node:fs";
import { expect, test } from "vitest";

function stripVolatile(x:any){ const c=JSON.parse(JSON.stringify(x));
  if (c?.meta){ delete c.meta.generatedAt; c.meta.timings = {}; }
  return c;
}

test("metrics stable", () => {
  const j = JSON.parse(fs.readFileSync("__reports/geo-metrics.json","utf8"));
  expect(stripVolatile(j)).toMatchSnapshot();
});

test("doctor stable", () => {
  const j = JSON.parse(fs.readFileSync("__reports/geo-doctor.json","utf8"));
  expect(stripVolatile(j)).toMatchSnapshot();
});
