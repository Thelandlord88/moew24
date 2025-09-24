import { z } from "zod";

export const DegreeStats = z.object({
  min: z.number().nonnegative(),
  median: z.number().nonnegative(),
  max: z.number().nonnegative(),
  mean: z.number().nonnegative(),
  p90: z.number().nonnegative(),
});

export const DegreeHistogram = z.record(z.string(), z.number().int().nonnegative());

export const MetricsReport = z.object({
  schemaVersion: z.literal(1),
  clusters: z.number().int().nonnegative(),
  suburbs: z.number().int().nonnegative(),
  edges: z.object({
    directed: z.number().int().nonnegative(),
    undirected: z.number().int().nonnegative(),
    cross_cluster_ratio: z.number().min(0).max(1)
  }),
  degree: DegreeStats,
  meta: z.object({
    generatedAt: z.string(),
    toolVersion: z.string(),
    inputHashes: z.object({ graph: z.string() }),
    timings: z.object({ load: z.number().optional(), total: z.number() })
  })
});

export type TMetricsReport = z.infer<typeof MetricsReport>;

export const DoctorReport = z.object({
  schemaVersion: z.literal(1),
  nodes: z.number().int().nonnegative(),
  components: z.number().int().nonnegative(),
  largest_component_ratio: z.number().min(0).max(1),
  degrees: DegreeStats.extend({ histogram: DegreeHistogram }),
  cross_cluster_ratio: z.number().min(0).max(1),
  asym_pairs: z.array(z.tuple([z.string(), z.string()])),
  self_loops: z.number().int().nonnegative(),
  meta: z.object({
    generatedAt: z.string(),
    runtimeFallback: z.boolean().optional(),
    toolVersion: z.string(),
    inputHashes: z.object({ graph: z.string() }),
    timings: z.object({ total: z.number() })
  })
});

export type TDoctorReport = z.infer<typeof DoctorReport>;
