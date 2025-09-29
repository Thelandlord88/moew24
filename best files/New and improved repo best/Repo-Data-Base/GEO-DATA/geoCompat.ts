/**
 * Geo Compatibility Layer
 * Unified API for all geographic data access
 * Single source of truth with validation
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import type { 
  AreasClusters, 
  Adjacency, 
  GeoJSON, 
  GeoConfig, 
  Suburb, 
  Cluster 
} from './schemas.js';
import { 
  validateAreas, 
  validateAdjacency, 
  validateGeoJSON, 
  validateGeoConfig 
} from './schemas.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Data file paths - More robust path resolution for build environments
function getProjectRoot(): string {
  // Try to find the project root by looking for geo.config.json
  let currentDir = __dirname;
  for (let i = 0; i < 10; i++) { // Prevent infinite loop
    const configPath = path.join(currentDir, 'geo.config.json');
    if (fs.existsSync(configPath)) {
      return currentDir;
    }
    const parentDir = path.dirname(currentDir);
    if (parentDir === currentDir) break; // Reached filesystem root
    currentDir = parentDir;
  }
  
  // Fallback: assume we're in src/lib and go up two levels
  return path.resolve(__dirname, '../..');
}

const PROJECT_ROOT = getProjectRoot();
const DATA_DIR = path.join(PROJECT_ROOT, 'src/data');

const PATHS = {
  areas: path.join(DATA_DIR, 'areas.clusters.json'),
  adjacency: path.join(DATA_DIR, 'areas.adj.json'),
  geojson: path.join(DATA_DIR, 'suburbs_enriched.geojson'),
  config: path.join(PROJECT_ROOT, 'geo.config.json')
};

// Cache for loaded data
let _areasCache: AreasClusters | null = null;
let _adjacencyCache: Adjacency | null = null;
let _geojsonCache: GeoJSON | null = null;
let _configCache: GeoConfig | null = null;

/**
 * Load and validate JSON file
 */
function loadAndValidate<T>(
  filePath: string, 
  validator: (data: unknown) => T,
  cacheName: string
): T {
  try {
    if (!fs.existsSync(filePath)) {
      throw new Error(`Data file not found: ${filePath}`);
    }
    
    const content = fs.readFileSync(filePath, 'utf8');
    const data = JSON.parse(content);
    const validated = validator(data);
    
    console.info(`✅ Loaded and validated ${cacheName}`);
    return validated;
    
  } catch (error) {
    console.error(`❌ Failed to load ${cacheName}:`, error);
    throw new Error(`Failed to load ${cacheName}: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}

/**
 * Get enriched clusters with coordinates
 */
export function enrichedClusters(): Cluster[] {
  if (!_areasCache) {
    _areasCache = loadAndValidate(PATHS.areas, validateAreas, 'areas.clusters.json');
  }
  return _areasCache.clusters;
}

/**
 * Get adjacency relationships
 */
export function adjacency(): Adjacency {
  if (!_adjacencyCache) {
    _adjacencyCache = loadAndValidate(PATHS.adjacency, validateAdjacency, 'areas.adj.json');
  }
  return _adjacencyCache;
}

/**
 * Get GeoJSON feature collection
 */
export function geoJSON(): GeoJSON {
  if (!_geojsonCache) {
    _geojsonCache = loadAndValidate(PATHS.geojson, validateGeoJSON, 'suburbs_enriched.geojson');
  }
  return _geojsonCache;
}

/**
 * Get configuration
 */
export function geoConfig(): GeoConfig {
  if (!_configCache) {
    _configCache = loadAndValidate(PATHS.config, validateGeoConfig, 'geo.config.json');
  }
  return _configCache;
}

/**
 * Get all suburbs with coordinates from clusters
 */
export function suburbCoordinates(): Map<string, { lat: number; lng: number; name: string; cluster: string }> {
  const clusters = enrichedClusters();
  const coordinates = new Map();
  
  for (const cluster of clusters) {
    for (const suburb of cluster.suburbs) {
      coordinates.set(suburb.slug, {
        lat: suburb.lat,
        lng: suburb.lng,
        name: suburb.name,
        cluster: cluster.slug
      });
    }
  }
  
  return coordinates;
}

/**
 * Get all suburb slugs
 */
export function allSuburbSlugs(): string[] {
  const clusters = enrichedClusters();
  const slugs: string[] = [];
  
  for (const cluster of clusters) {
    for (const suburb of cluster.suburbs) {
      slugs.push(suburb.slug);
    }
  }
  
  return slugs.sort();
}

/**
 * Get suburb by slug
 */
export function getSuburb(slug: string): (Suburb & { cluster: string }) | null {
  const clusters = enrichedClusters();
  
  for (const cluster of clusters) {
    const suburb = cluster.suburbs.find(s => s.slug === slug);
    if (suburb) {
      return { ...suburb, cluster: cluster.slug };
    }
  }
  
  return null;
}

/**
 * Get cluster by slug
 */
export function getCluster(slug: string): Cluster | null {
  const clusters = enrichedClusters();
  return clusters.find(c => c.slug === slug) || null;
}

/**
 * Get adjacent suburbs for a given suburb
 */
export function getAdjacentSuburbs(suburbSlug: string): string[] {
  const adj = adjacency();
  return adj[suburbSlug] || [];
}

/**
 * Check if two suburbs are adjacent
 */
export function areAdjacent(suburb1: string, suburb2: string): boolean {
  const adj = adjacency();
  return adj[suburb1]?.includes(suburb2) || false;
}

/**
 * Get all suburbs in a cluster
 */
export function getSuburbsInCluster(clusterSlug: string): Suburb[] {
  const cluster = getCluster(clusterSlug);
  return cluster ? cluster.suburbs : [];
}

/**
 * Get cluster name for a suburb
 */
export function getClusterForSuburb(suburbSlug: string): string | null {
  const clusters = enrichedClusters();
  
  for (const cluster of clusters) {
    if (cluster.suburbs.some(s => s.slug === suburbSlug)) {
      return cluster.slug;
    }
  }
  
  return null;
}

/**
 * Data integrity check - validates all relationships
 */
export function validateDataIntegrity(): {
  valid: boolean;
  errors: string[];
  warnings: string[];
} {
  const errors: string[] = [];
  const warnings: string[] = [];
  
  try {
    // Load all data to trigger validation
    const clusters = enrichedClusters();
    const adj = adjacency();
    const geo = geoJSON();
    
    // Validate config exists (throws if invalid)
    geoConfig();
    
    // Check for orphan suburbs in adjacency
    const clusterSuburbs = new Set<string>();
    clusters.forEach(cluster => {
      cluster.suburbs.forEach(suburb => {
        clusterSuburbs.add(suburb.slug);
      });
    });
    
    // Check adjacency references
    for (const [suburb, neighbors] of Object.entries(adj)) {
      if (!clusterSuburbs.has(suburb)) {
        warnings.push(`Adjacency references unknown suburb: ${suburb}`);
      }
      
      for (const neighbor of neighbors) {
        if (!clusterSuburbs.has(neighbor)) {
          warnings.push(`Adjacency references unknown neighbor: ${neighbor} for ${suburb}`);
        }
        
        // Check for asymmetric relationships
        if (!adj[neighbor]?.includes(suburb)) {
          warnings.push(`Asymmetric adjacency: ${suburb} -> ${neighbor}`);
        }
      }
    }
    
    // Check coordinate coverage
    const geoSuburbs = new Set(geo.features.map(f => f.properties.suburb));
    for (const suburb of clusterSuburbs) {
      if (!geoSuburbs.has(suburb)) {
        warnings.push(`Missing GeoJSON data for suburb: ${suburb}`);
      }
    }
    
    console.info(`✅ Data integrity check completed: ${errors.length} errors, ${warnings.length} warnings`);
    
  } catch (error) {
    errors.push(`Data validation failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
  
  return {
    valid: errors.length === 0,
    errors,
    warnings
  };
}

/**
 * Clear all caches - useful for testing
 */
export function clearCaches(): void {
  _areasCache = null;
  _adjacencyCache = null;
  _geojsonCache = null;
  _configCache = null;
}

/**
 * Get data file statistics
 */
export function getDataStats(): {
  clusters: number;
  suburbs: number;
  adjacencyPairs: number;
  geoFeatures: number;
} {
  const clusters = enrichedClusters();
  const adj = adjacency();
  const geo = geoJSON();
  
  const suburbCount = clusters.reduce((sum, cluster) => sum + cluster.suburbs.length, 0);
  const adjacencyPairs = Object.values(adj).reduce((sum, neighbors) => sum + neighbors.length, 0);
  
  return {
    clusters: clusters.length,
    suburbs: suburbCount,
    adjacencyPairs,
    geoFeatures: geo.features.length
  };
}