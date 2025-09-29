// src/utils/geoHandler.ts
import {
  getClustersSync,
  listSuburbsForClusterSyncAsObjects,
  resolveClusterSlug,
  findClusterBySuburb,
  CANONICAL_CLUSTERS,
} from '~/lib/clusters';

export {
  getClustersSync,
  listSuburbsForClusterSyncAsObjects,
  resolveClusterSlug,
  findClusterBySuburb,
  CANONICAL_CLUSTERS,
};

// Legacy compatibility:
export const listClusters = () => getClustersSync(); // returns objects [{slug,name,suburbCount}]
export const listSuburbsForCluster = (cluster: string) =>
  listSuburbsForClusterSyncAsObjects(cluster); // returns objects [{slug,name}]
