/**
 * Geo Data Validation Schemas
 * Type-safe validation for all geographic data using Zod
 */

import { z } from 'zod';

// Individual suburb schema
export const SuburbSchema = z.object({
  slug: z.string().regex(/^[a-z0-9-]+$/, 'Suburb slug must be lowercase with hyphens only'),
  name: z.string().min(1, 'Suburb name is required'),
  lat: z.number().min(-90).max(90, 'Latitude must be between -90 and 90'),
  lng: z.number().min(-180).max(180, 'Longitude must be between -180 and 180')
});

// Cluster schema with suburbs
export const ClusterSchema = z.object({
  slug: z.string().regex(/^[a-z0-9-]+$/, 'Cluster slug must be lowercase with hyphens only'),
  name: z.string().min(1, 'Cluster name is required'),
  suburbs: z.array(SuburbSchema).min(1, 'Cluster must have at least one suburb')
});

// Root areas.clusters.json schema
export const AreasClusterSchema = z.object({
  clusters: z.array(ClusterSchema).min(1, 'Must have at least one cluster')
});

// Adjacency relationships schema
export const AdjacencySchema = z.record(
  z.string().regex(/^[a-z0-9-]+$/, 'Suburb key must be lowercase with hyphens'),
  z.array(z.string().regex(/^[a-z0-9-]+$/, 'Adjacent suburb must be lowercase with hyphens'))
    .min(1, 'Each suburb must have at least one adjacent suburb')
);

// GeoJSON feature properties
export const GeoFeaturePropertiesSchema = z.object({
  name: z.string().min(1),
  name_official: z.string().min(1).optional(),
  suburb: z.string().regex(/^[a-z0-9-]+$/),
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180)
});

// GeoJSON point geometry
export const GeoPointGeometrySchema = z.object({
  type: z.literal('Point'),
  coordinates: z.tuple([
    z.number().min(-180).max(180), // longitude first in GeoJSON
    z.number().min(-90).max(90)     // latitude second
  ])
});

// GeoJSON feature
export const GeoFeatureSchema = z.object({
  type: z.literal('Feature'),
  properties: GeoFeaturePropertiesSchema,
  geometry: GeoPointGeometrySchema
});

// Complete GeoJSON schema
export const GeoJSONSchema = z.object({
  type: z.literal('FeatureCollection'),
  features: z.array(GeoFeatureSchema).min(1, 'Must have at least one feature')
});

// Geo configuration schema (matches our JSON schema)
export const GeoConfigSchema = z.object({
  site: z.string().url('Site must be a valid URL'),
  brand: z.string().min(1, 'Brand name is required'),
  services: z.array(z.string().regex(/^[a-z-]+$/, 'Service must be lowercase with hyphens')),
  proximity: z.object({
    biasKm: z.number().min(1, 'Bias must be at least 1km'),
    clusterBoost: z.number().min(1, 'Cluster boost must be at least 1'),
    crossPenalty: z.number().min(0, 'Cross penalty must be non-negative')
  }).optional()
});

// Type exports for use throughout the application
export type Suburb = z.infer<typeof SuburbSchema>;
export type Cluster = z.infer<typeof ClusterSchema>;
export type AreasClusters = z.infer<typeof AreasClusterSchema>;
export type Adjacency = z.infer<typeof AdjacencySchema>;
export type GeoFeature = z.infer<typeof GeoFeatureSchema>;
export type GeoJSON = z.infer<typeof GeoJSONSchema>;
export type GeoConfig = z.infer<typeof GeoConfigSchema>;

// Validation helper functions
export function validateAreas(data: unknown): AreasClusters {
  return AreasClusterSchema.parse(data);
}

export function validateAdjacency(data: unknown): Adjacency {
  return AdjacencySchema.parse(data);
}

export function validateGeoJSON(data: unknown): GeoJSON {
  return GeoJSONSchema.parse(data);
}

export function validateGeoConfig(data: unknown): GeoConfig {
  return GeoConfigSchema.parse(data);
}

// Utility for safe validation with error details
export function safeValidate<T>(
  schema: z.ZodSchema<T>, 
  data: unknown
): { success: true; data: T } | { success: false; errors: string[] } {
  const result = schema.safeParse(data);
  
  if (result.success) {
    return { success: true, data: result.data };
  }
  
  return {
    success: false,
    errors: result.error.errors.map(err => 
      `${err.path.join('.')}: ${err.message}`
    )
  };
}