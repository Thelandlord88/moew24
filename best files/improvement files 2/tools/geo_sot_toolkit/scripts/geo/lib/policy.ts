import { z } from "zod";

export const Policy = z.object({
  fairness: z.object({
    maxPromotedShareWarn: z.number().min(0).max(1),
    maxPromotedShareFail: z.number().min(0).max(1),
    maxPromotedCrossClusterRatio: z.number().min(0).max(1)
  }),
  graph: z.object({
    minLargestComponentRatio: z.number().min(0).max(1),
    maxIsolates: z.number().int().min(0),
    minMeanDegree: z.number().min(0)
  })
});
export type TPolicy = z.infer<typeof Policy>;

export function parseJsonc(jsonc: string) {
  const stripped = jsonc.replace(/\/\/.*$/gm, "").replace(/\/\*[\s\S]*?\*\//g, "");
  return JSON.parse(stripped);
}
