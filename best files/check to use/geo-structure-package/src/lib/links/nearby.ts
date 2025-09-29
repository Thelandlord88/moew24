// Same-cluster fallback implementation for nearby service lookups
import adjacency from '~/data/adjacency.json';
import { inSameCluster } from './knownSuburbs';

interface ServiceCoverageChecker {
  isServiceCovered(service: string, suburb: string): boolean;
}

// Adjacency file stores either string[] or objects with adjacent_suburbs[] (legacy dual shape)
type RawAdjEntry = string[] | { adjacent_suburbs?: string[], nearest_nonsiblings?: string[] };
function neighborsOf(slug: string): string[] {
  const entry = (adjacency as Record<string, RawAdjEntry>)[slug];
  if (!entry) return [];
  if (Array.isArray(entry)) return entry;
  return entry.adjacent_suburbs || [];
}

export async function pickNearbyCoveredInSameCluster(
  service: string, 
  suburb: string,
  checker: ServiceCoverageChecker
): Promise<{ suburb: string; distance: number } | null> {
  const seen = new Set<string>([suburb]);
  const queue: Array<{ suburb: string; distance: number }> = [];
  
  // Initialize queue with direct neighbors
  const neighbors = neighborsOf(suburb);
  neighbors.forEach(neighbor => {
    if (!seen.has(neighbor)) {
      queue.push({ suburb: neighbor, distance: 1 });
    }
  });

  while (queue.length > 0) {
    const current = queue.shift()!;
    if (seen.has(current.suburb)) continue;
    seen.add(current.suburb);

    // Enforce same-cluster policy
    if (!inSameCluster(suburb, current.suburb)) continue;
    
    // Check if this suburb has coverage for the service
    if (checker.isServiceCovered(service, current.suburb)) {
      return current;
    }

    // BFS expansion: add neighbors of current suburb
  const currentNeighbors = neighborsOf(current.suburb);
    currentNeighbors.forEach(neighbor => {
      if (!seen.has(neighbor)) {
        queue.push({ suburb: neighbor, distance: current.distance + 1 });
      }
    });
  }

  return null;
}

// Synchronous version for cases where we have the coverage data pre-loaded
export function pickNearbyCoveredInSameClusterSync(
  service: string,
  suburb: string,
  coverageMap: Record<string, string[]>
): { suburb: string; distance: number } | null {
  const checker = {
    isServiceCovered: (svc: string, sub: string) => {
      const covered = coverageMap[svc] || [];
      return covered.includes(sub);
    }
  };

  // Convert async to sync by using a simple implementation
  const seen = new Set<string>([suburb]);
  const queue: Array<{ suburb: string; distance: number }> = [];
  
  const neighbors = neighborsOf(suburb);
  neighbors.forEach(neighbor => {
    if (!seen.has(neighbor)) {
      queue.push({ suburb: neighbor, distance: 1 });
    }
  });

  while (queue.length > 0) {
    const current = queue.shift()!;
    if (seen.has(current.suburb)) continue;
    seen.add(current.suburb);

    if (!inSameCluster(suburb, current.suburb)) continue;
    
    if (checker.isServiceCovered(service, current.suburb)) {
      return current;
    }

  const currentNeighbors = neighborsOf(current.suburb);
    currentNeighbors.forEach(neighbor => {
      if (!seen.has(neighbor)) {
        queue.push({ suburb: neighbor, distance: current.distance + 1 });
      }
    });
  }

  return null;
}
