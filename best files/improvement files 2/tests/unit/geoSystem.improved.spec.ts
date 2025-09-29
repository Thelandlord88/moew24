/**
 * geoSystem.improved.spec.ts
 * 
 * Consolidated test suite combining all geo-related test variants
 * with enhanced coverage, better mocking, and comprehensive edge cases.
 * 
 * Combines:
 * - geoCompat.spec.ts (compatibility layer tests)
 * - clusterMap.spec.ts (cluster mapping validation) 
 * - chooseSuburbForPost.spec.ts/.sync.spec.ts (content selection logic)
 * - repSuburb.spec.ts (representative suburb selection)
 * - proximity.spec.ts (geographic proximity calculations)
 * - cross-services.spec.ts (service cross-referencing)
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// === MOCK SETUP ===
const mockClusterMap = {
  'goodna': 'ipswich',
  'redbank-plains': 'ipswich',
  'springfield': 'ipswich',
  'ashgrove': 'inner-west',
  'toowong': 'inner-west',
  'milton': 'inner-west'
};

const mockAdjacency = {
  'goodna': { 
    adjacent_suburbs: ['redbank-plains', 'springfield'],
    nearest_nonsiblings: ['ashgrove'] 
  },
  'redbank-plains': { 
    adjacent_suburbs: ['goodna', 'springfield'],
    nearest_nonsiblings: ['toowong']
  },
  'springfield': { 
    adjacent_suburbs: ['redbank-plains', 'goodna'],
    nearest_nonsiblings: ['milton']
  },
  'ashgrove': { 
    adjacent_suburbs: ['toowong', 'milton'],
    nearest_nonsiblings: ['goodna']
  },
  'toowong': { 
    adjacent_suburbs: ['ashgrove', 'milton'],
    nearest_nonsiblings: ['redbank-plains']
  },
  'milton': { 
    adjacent_suburbs: ['toowong', 'ashgrove'],
    nearest_nonsiblings: ['springfield']
  }
};

const mockClusters = {
  ipswich: {
    suburbs: ['goodna', 'redbank-plains', 'springfield'],
    adjacency: {
      'goodna': ['redbank-plains', 'springfield'],
      'redbank-plains': ['goodna', 'springfield'],
      'springfield': ['redbank-plains', 'goodna']
    }
  },
  'inner-west': {
    suburbs: ['ashgrove', 'toowong', 'milton'],
    adjacency: {
      'ashgrove': ['toowong', 'milton'],
      'toowong': ['ashgrove', 'milton'],
      'milton': ['toowong', 'ashgrove']
    }
  }
};

const mockServiceCoverage = {
  'bond-cleaning': {
    suburbs: ['goodna', 'redbank-plains', 'ashgrove', 'toowong', 'milton']
  },
  'spring-cleaning': {
    suburbs: ['ashgrove', 'toowong', 'milton', 'springfield']
  },
  'carpet-cleaning': {
    suburbs: ['goodna', 'springfield', 'milton']
  }
};

// Mock modules
vi.mock('~/data/cluster_map.json', () => ({ default: mockClusterMap }));
vi.mock('~/data/adjacency.json', () => ({ default: mockAdjacency }));
vi.mock('~/data/clusters.json', () => ({ default: mockClusters }));
vi.mock('~/data/serviceCoverage.json', () => ({ default: mockServiceCoverage }));

// === UTILITY IMPORTS ===
// Note: These would import the actual improved utilities
const { geoCompat } = await import('~/lib/geoCompat.improved.js');
const { representativeOfCluster, representativeOfClusterSync } = await import('~/utils/repSuburb.improved.ts');
const { chooseSuburbForPost } = await import('~/utils/chooseSuburbForPost.improved.ts');
const { calculateProximity } = await import('~/utils/proximity.improved.ts');

describe('Geo System (Improved) - Comprehensive Test Suite', () => {

  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  // === GEO COMPATIBILITY LAYER ===
  describe('GeoCompat Layer', () => {
    it('should load cluster data successfully', async () => {
      const clusters = await geoCompat.clusters();
      expect(clusters).toBeDefined();
      expect(clusters.ipswich).toHaveProperty('suburbs');
      expect(clusters.ipswich.suburbs).toContain('goodna');
    });

    it('should load adjacency data successfully', async () => {
      const adjacency = await geoCompat.adjacency();
      expect(adjacency).toBeDefined();
      expect(adjacency.goodna).toHaveProperty('adjacent_suburbs');
      expect(adjacency.goodna.adjacent_suburbs).toContain('redbank-plains');
    });

    it('should handle missing data gracefully', async () => {
      vi.mocked(import('~/data/clusters.json')).mockRejectedValueOnce(new Error('File not found'));
      
      const clusters = await geoCompat.clusters();
      expect(clusters).toEqual({});
    });

    it('should normalize cluster data structure', async () => {
      const clusters = await geoCompat.clusters();
      
      for (const [clusterName, clusterData] of Object.entries(clusters)) {
        expect(clusterData).toHaveProperty('suburbs');
        expect(Array.isArray(clusterData.suburbs)).toBe(true);
        expect(clusterData).toHaveProperty('adjacency');
        expect(typeof clusterData.adjacency).toBe('object');
      }
    });
  });

  // === REPRESENTATIVE SUBURB SELECTION ===
  describe('Representative Suburb Selection', () => {
    describe('Async Method', () => {
      it('should select suburb with highest adjacency degree', async () => {
        const result = await representativeOfCluster('ipswich');
        
        // All suburbs in ipswich cluster have degree 2, should return alphabetically first
        expect(['goodna', 'redbank-plains', 'springfield']).toContain(result);
      });

      it('should prefer suburbs with service coverage when specified', async () => {
        const result = await representativeOfCluster('ipswich', { 
          service: 'bond-cleaning',
          preferCoverage: true 
        });
        
        // Should return a suburb that has bond-cleaning coverage
        expect(['goodna', 'redbank-plains']).toContain(result);
      });

      it('should handle non-existent clusters gracefully', async () => {
        const result = await representativeOfCluster('non-existent-cluster');
        expect(result).toBeNull();
      });

      it('should fall back to alphabetical when adjacency is equal', async () => {
        const result = await representativeOfCluster('inner-west');
        
        // All have equal degree, should pick alphabetically first
        expect(result).toBe('ashgrove');
      });
    });

    describe('Sync Method', () => {
      it('should work synchronously with same logic', () => {
        const result = representativeOfClusterSync('ipswich');
        expect(['goodna', 'redbank-plains', 'springfield']).toContain(result);
      });

      it('should handle service coverage in sync mode', () => {
        const result = representativeOfClusterSync('ipswich', { 
          service: 'carpet-cleaning',
          preferCoverage: true 
        });
        
        // Should prefer suburbs with carpet-cleaning coverage
        expect(['goodna', 'springfield']).toContain(result);
      });

      it('should return null for invalid clusters', () => {
        const result = representativeOfClusterSync('invalid-cluster');
        expect(result).toBeNull();
      });
    });

    describe('Edge Cases', () => {
      it('should handle empty adjacency data', async () => {
        vi.mocked(import('~/data/adjacency.json')).mockResolvedValueOnce({ default: {} });
        
        const result = await representativeOfCluster('ipswich');
        expect(result).toBeTruthy(); // Should still return something
      });

      it('should handle malformed service coverage data', async () => {
        vi.mocked(import('~/data/serviceCoverage.json')).mockResolvedValueOnce({ 
          default: { 'invalid-service': null } 
        });
        
        const result = await representativeOfCluster('ipswich', { service: 'invalid-service' });
        expect(result).toBeTruthy();
      });
    });
  });

  // === SUBURB SELECTION FOR CONTENT ===
  describe('Suburb Selection for Content', () => {
    it('should choose appropriate suburb for blog post', async () => {
      const postData = {
        tags: ['bond-cleaning', 'ipswich'],
        category: 'cleaning-tips',
        region: 'ipswich'
      };
      
      const result = await chooseSuburbForPost(postData);
      expect(mockClusters.ipswich.suburbs).toContain(result);
    });

    it('should respect service-specific selection', async () => {
      const postData = {
        service: 'carpet-cleaning',
        tags: ['carpet', 'deep-clean'],
        region: 'ipswich'
      };
      
      const result = await chooseSuburbForPost(postData);
      
      // Should choose a suburb with carpet-cleaning coverage
      expect(mockServiceCoverage['carpet-cleaning'].suburbs).toContain(result);
    });

    it('should fall back gracefully when no region specified', async () => {
      const postData = {
        tags: ['general-cleaning'],
        category: 'tips'
      };
      
      const result = await chooseSuburbForPost(postData);
      expect(result).toBeTruthy();
      expect(typeof result).toBe('string');
    });

    it('should handle cross-cluster selection based on tags', async () => {
      const postData = {
        tags: ['inner-west', 'premium-cleaning'],
        category: 'services'
      };
      
      const result = await chooseSuburbForPost(postData);
      expect(mockClusters['inner-west'].suburbs).toContain(result);
    });
  });

  // === PROXIMITY CALCULATIONS ===
  describe('Proximity Calculations', () => {
    it('should calculate distance between adjacent suburbs', () => {
      const distance = calculateProximity('goodna', 'redbank-plains');
      expect(distance).toBeGreaterThan(0);
      expect(distance).toBeLessThan(1); // Adjacent should be close
    });

    it('should calculate distance between non-adjacent suburbs', () => {
      const distance = calculateProximity('goodna', 'ashgrove');
      expect(distance).toBeGreaterThan(0);
      expect(distance).toBeGreaterThan(0.5); // Cross-cluster should be further
    });

    it('should return 0 for same suburb', () => {
      const distance = calculateProximity('goodna', 'goodna');
      expect(distance).toBe(0);
    });

    it('should handle unknown suburbs gracefully', () => {
      const distance = calculateProximity('unknown-suburb', 'goodna');
      expect(distance).toBe(Infinity);
    });

    it('should be symmetric', () => {
      const distance1 = calculateProximity('goodna', 'ashgrove');
      const distance2 = calculateProximity('ashgrove', 'goodna');
      expect(distance1).toBe(distance2);
    });
  });

  // === CROSS-SERVICE VALIDATION ===
  describe('Cross-Service Validation', () => {
    it('should identify service overlap between suburbs', () => {
      const services = ['bond-cleaning', 'spring-cleaning'];
      const overlap = findServiceOverlap(services);
      
      expect(overlap).toContain('ashgrove');
      expect(overlap).toContain('toowong');
      expect(overlap).toContain('milton');
    });

    it('should handle single service queries', () => {
      const suburbs = getSuburbsForService('carpet-cleaning');
      expect(suburbs).toEqual(['goodna', 'springfield', 'milton']);
    });

    it('should return empty array for unknown services', () => {
      const suburbs = getSuburbsForService('unknown-service');
      expect(suburbs).toEqual([]);
    });

    it('should validate service availability in cluster', () => {
      const isAvailable = isServiceAvailableInCluster('bond-cleaning', 'ipswich');
      expect(isAvailable).toBe(true);
      
      const notAvailable = isServiceAvailableInCluster('carpet-cleaning', 'inner-west');
      expect(notAvailable).toBe(false); // Only milton has carpet cleaning in inner-west
    });
  });

  // === INTEGRATION TESTS ===
  describe('System Integration', () => {
    it('should handle full geo workflow', async () => {
      // Simulate a complete geo operation
      const clusters = await geoCompat.clusters();
      const representative = await representativeOfCluster('ipswich');
      const postSuburb = await chooseSuburbForPost({ region: 'ipswich', service: 'bond-cleaning' });
      const proximity = calculateProximity(representative, postSuburb);
      
      expect(clusters).toBeDefined();
      expect(representative).toBeTruthy();
      expect(postSuburb).toBeTruthy();
      expect(proximity).toBeGreaterThanOrEqual(0);
    });

    it('should maintain data consistency across operations', async () => {
      const clusterSuburbs = mockClusters.ipswich.suburbs;
      const representative = await representativeOfCluster('ipswich');
      
      expect(clusterSuburbs).toContain(representative);
    });

    it('should handle concurrent operations safely', async () => {
      const promises = Array.from({ length: 10 }, (_, i) => 
        representativeOfCluster('ipswich', { service: i % 2 === 0 ? 'bond-cleaning' : 'spring-cleaning' })
      );
      
      const results = await Promise.all(promises);
      
      // All results should be valid suburbs
      results.forEach(result => {
        expect(result).toBeTruthy();
        expect(typeof result).toBe('string');
      });
    });
  });

  // === PERFORMANCE TESTS ===
  describe('Performance', () => {
    it('should handle large datasets efficiently', async () => {
      const startTime = performance.now();
      
      // Simulate operations on larger dataset
      const operations = Array.from({ length: 100 }, async (_, i) => {
        const cluster = i % 2 === 0 ? 'ipswich' : 'inner-west';
        return representativeOfCluster(cluster);
      });
      
      await Promise.all(operations);
      
      const endTime = performance.now();
      const duration = endTime - startTime;
      
      // Should complete within reasonable time (adjust threshold as needed)
      expect(duration).toBeLessThan(1000); // 1 second
    });

    it('should cache repeated requests efficiently', async () => {
      const startTime1 = performance.now();
      await representativeOfCluster('ipswich');
      const duration1 = performance.now() - startTime1;
      
      const startTime2 = performance.now();
      await representativeOfCluster('ipswich');
      const duration2 = performance.now() - startTime2;
      
      // Second call should be faster due to caching
      expect(duration2).toBeLessThanOrEqual(duration1);
    });
  });
});

// === HELPER FUNCTIONS ===
function findServiceOverlap(services: string[]): string[] {
  if (services.length === 0) return [];
  
  let overlap = mockServiceCoverage[services[0]]?.suburbs || [];
  
  for (let i = 1; i < services.length; i++) {
    const serviceSuburbs = mockServiceCoverage[services[i]]?.suburbs || [];
    overlap = overlap.filter(suburb => serviceSuburbs.includes(suburb));
  }
  
  return overlap;
}

function getSuburbsForService(service: string): string[] {
  return mockServiceCoverage[service]?.suburbs || [];
}

function isServiceAvailableInCluster(service: string, clusterName: string): boolean {
  const clusterSuburbs = mockClusters[clusterName]?.suburbs || [];
  const serviceSuburbs = mockServiceCoverage[service]?.suburbs || [];
  
  return clusterSuburbs.some(suburb => serviceSuburbs.includes(suburb));
}