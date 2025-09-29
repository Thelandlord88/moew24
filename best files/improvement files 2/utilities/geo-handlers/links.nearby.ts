// Same-cluster fallback implementation for nearby service lookups
import adjacency from '~/data/adjacency.json';
import { inSameCluster } from './knownSuburbs';

interface ServiceCoverageChecker {
  isServiceCovered(service: string, suburb: string): boolean;
}

interface AdjacencyData {
  adjacent_suburbs: string[];
  nearest_nonsiblings?: string[];
}

export async function pickNearbyCoveredInSameCluster(
  service: string, 
  suburb: string,
  checker: ServiceCoverageChecker
): Promise<{ suburb: string; distance: number } | null> {
  const seen = new Set<string>([suburb]);
  const queue: Array<{ suburb: string; distance: number }> = [];
  
  // Initialize queue with direct neighbors
  const suburbData = (adjacency as Record<string, AdjacencyData>)[suburb];
  const neighbors = suburbData?.adjacent_suburbs || [];
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
    const currentData = (adjacency as Record<string, AdjacencyData>)[current.suburb];
    const currentNeighbors = currentData?.adjacent_suburbs || [];
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
  
  const suburbData = (adjacency as Record<string, AdjacencyData>)[suburb];
  const neighbors = suburbData?.adjacent_suburbs || [];
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

    const currentData = (adjacency as Record<string, AdjacencyData>)[current.suburb];
    const currentNeighbors = currentData?.adjacent_suburbs || [];
    currentNeighbors.forEach(neighbor => {
      if (!seen.has(neighbor)) {
        queue.push({ suburb: neighbor, distance: current.distance + 1 });
      }
    });
  }

  return null;
}
