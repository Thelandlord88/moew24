// Canonical geo facade - single source of truth for all geo operations
// This replaces scattered geo logic with a unified, well-tested API

import clusters from '~/content/areas.clusters.json';

type ClusterData = {
  slug: string;
  name: string;
  suburbs: string[];
  aliases?: Record<string, string>;
};

type SuburbInfo = {
  slug: string;
  name: string;
  cluster: string;
};

// Precomputed maps for O(1) lookups
const clusterMap = new Map<string, ClusterData>();
const aliasMap = new Map<string, string>(); // alias -> canonical slug
const suburbToCluster = new Map<string, string>(); // suburb -> cluster slug

// Initialize maps
function initializeMaps() {
  const data = clusters as any;
  
  for (const cluster of data.clusters || []) {
    clusterMap.set(cluster.slug, cluster);
    
    // Add identity mapping
    aliasMap.set(cluster.slug, cluster.slug);
    
    // Add aliases
    if (cluster.aliases) {
      for (const [alias, _displayName] of Object.entries(cluster.aliases)) {
        aliasMap.set(slugify(alias), cluster.slug);
      }
    }
    
    // Map suburbs to cluster
    for (const suburb of cluster.suburbs || []) {
      suburbToCluster.set(slugify(suburb), cluster.slug);
    }
  }
}

function slugify(text: string): string {
  return text.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
}

// Initialize on module load
initializeMaps();

/**
 * Normalize cluster input (alias or slug) to canonical cluster slug
 */
export function normalizeClusterSlug(input: string): string | null {
  if (!input) return null;
  const normalized = slugify(input);
  return aliasMap.get(normalized) || null;
}

/**
 * Normalize suburb name to standardized slug format
 */
export function normalizeSuburbSlug(input: string): string {
  if (!input) return '';
  return slugify(input);
}

/**
 * Get all clusters with their metadata
 */
export function getClusters(): ClusterData[] {
  return Array.from(clusterMap.values()).sort((a, b) => a.name.localeCompare(b.name));
}

/**
 * Get cluster information by slug or alias
 */
export function getCluster(input: string): ClusterData | null {
  const canonical = normalizeClusterSlug(input);
  return canonical ? clusterMap.get(canonical) || null : null;
}

/**
 * Get all suburbs for a given cluster (by slug or alias)
 */
export function getSuburbsForCluster(clusterInput: string): string[] {
  const cluster = getCluster(clusterInput);
  return cluster ? cluster.suburbs.slice().sort() : [];
}

/**
 * Get cluster for a given suburb
 */
export function getClusterForSuburb(suburbInput: string): string | null {
  const suburbSlug = normalizeSuburbSlug(suburbInput);
  return suburbToCluster.get(suburbSlug) || null;
}

/**
 * Get nearby suburbs in the same cluster
 */
export function getNearbyInSameCluster(suburbInput: string, limit = 5): SuburbInfo[] {
  const cluster = getClusterForSuburb(suburbInput);
  if (!cluster) return [];
  
  const clusterData = clusterMap.get(cluster);
  if (!clusterData) return [];
  
  const currentSuburb = normalizeSuburbSlug(suburbInput);
  
  return clusterData.suburbs
    .filter(suburb => normalizeSuburbSlug(suburb) !== currentSuburb)
    .slice(0, limit)
    .map(suburb => ({
      slug: normalizeSuburbSlug(suburb),
      name: suburb,
      cluster
    }));
}

/**
 * Check if a suburb exists in our data
 */
export function isKnownSuburb(suburbInput: string): boolean {
  const suburbSlug = normalizeSuburbSlug(suburbInput);
  return suburbToCluster.has(suburbSlug);
}

/**
 * Check if a cluster exists (by slug or alias)
 */
export function isKnownCluster(clusterInput: string): boolean {
  return normalizeClusterSlug(clusterInput) !== null;
}

/**
 * Get all known suburb slugs
 */
export function getAllSuburbSlugs(): string[] {
  return Array.from(suburbToCluster.keys()).sort();
}

/**
 * Get suburb information with cluster context
 */
export function getSuburbInfo(suburbInput: string): SuburbInfo | null {
  const suburbSlug = normalizeSuburbSlug(suburbInput);
  const cluster = suburbToCluster.get(suburbSlug);
  
  if (!cluster) return null;
  
  // Find the original suburb name from the cluster data
  const clusterData = clusterMap.get(cluster);
  const originalName = clusterData?.suburbs.find(s => normalizeSuburbSlug(s) === suburbSlug);
  
  return {
    slug: suburbSlug,
    name: originalName || suburbInput,
    cluster
  };
}

// Legacy compatibility exports
export const listClusters = getClusters; // For geoHandler.js compatibility
export const resolveClusterSlug = normalizeClusterSlug; // For existing callers
