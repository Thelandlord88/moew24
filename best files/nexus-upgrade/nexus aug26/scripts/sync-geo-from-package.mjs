#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const pkgRoot = path.join(root, 'geo-structure-package');

function readJson(...segments) {
  const filePath = path.join(...segments);
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function writeJson(filePath, data) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n');
  console.log(`✅ wrote ${path.relative(root, filePath)}`);
}

function buildSuburbMap(geojson) {
  const map = new Map();
  for (const feature of geojson.features ?? []) {
    if (!feature?.properties?.slug) continue;
    map.set(feature.properties.slug, feature.properties);
  }
  return map;
}

function loadExistingSuburbs() {
  const file = path.join(root, 'src/data/suburbs.json');
  if (!fs.existsSync(file)) return new Map();
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  return new Map(data.map((entry) => [entry.slug, entry]));
}

function main() {
  const clusterDoc = readJson(pkgRoot, 'src/data/areas.clusters.json');
  const adjacencyDoc = readJson(pkgRoot, 'src/data/adjacency.json');
  const aliasesDoc = readJson(pkgRoot, 'src/data/suburbs.aliases.json');
  const coordsDoc = readJson(pkgRoot, 'src/data/suburbs.coords.json');
  const indexDoc = readJson(pkgRoot, 'src/data/suburbs.index.json');
  const metaDoc = readJson(pkgRoot, 'src/data/suburbs.meta.json');
  const registryDoc = readJson(pkgRoot, 'src/data/suburbs.registry.json');
  const geojson = readJson(pkgRoot, 'suburbs.geojson');
  const geoProps = buildSuburbMap(geojson);
  const existingSuburbs = loadExistingSuburbs();

  const existingClustersPath = path.join(root, 'src/content/areas.clusters.json');
  const clusterNameOverrides = new Map();
  const existingAssignments = new Map();
  if (fs.existsSync(existingClustersPath)) {
    const existingClusters = JSON.parse(fs.readFileSync(existingClustersPath, 'utf8'));
    for (const cluster of existingClusters.clusters ?? []) {
      clusterNameOverrides.set(cluster.slug, cluster.name);
      for (const slug of cluster.suburbs ?? []) {
        existingAssignments.set(slug, cluster.slug);
      }
    }
  }

  const docClusterNames = new Map();
  for (const cluster of clusterDoc.clusters ?? []) {
    docClusterNames.set(cluster.slug, cluster.name);
  }

  const clusterBuckets = new Map();
  function ensureBucket(slug) {
    if (!clusterBuckets.has(slug)) {
      const name = clusterNameOverrides.get(slug) ?? docClusterNames.get(slug) ?? slug.replace(/-/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
      clusterBuckets.set(slug, { slug, name, suburbs: new Set() });
    }
    return clusterBuckets.get(slug);
  }

  const suburbClusterMap = new Map();
  for (const cluster of clusterDoc.clusters ?? []) {
    ensureBucket(cluster.slug);
    for (const slug of cluster.suburbs ?? []) {
      if (!slug || slug === 'moreton-bay') continue;
      const targetClusterSlug = existingAssignments.get(slug) ?? cluster.slug;
      const bucket = ensureBucket(targetClusterSlug);
      bucket.suburbs.add(slug);
      suburbClusterMap.set(slug, targetClusterSlug);
    }
  }

  const clusters = Array.from(clusterBuckets.values())
    .map(({ slug, name, suburbs }) => ({ slug, name, suburbs: Array.from(suburbs).sort((a, b) => a.localeCompare(b)) }))
    .filter((cluster) => cluster.suburbs.length > 0)
    .sort((a, b) => a.slug.localeCompare(b.slug));

  const registryStates = registryDoc.suburbs ?? {};
  const tierMap = metaDoc.nodes ?? {};

  const suburbEntries = [];
  for (const [slug, clusterSlug] of suburbClusterMap.entries()) {
    const props = geoProps.get(slug) ?? {};
    const coords = coordsDoc[slug] ?? {};
    const index = indexDoc[slug] ?? {};
    const existing = existingSuburbs.get(slug) ?? {};

    const centroidLat = coords.lat ?? props.centroid?.lat ?? existing.coords?.lat;
    const centroidLng = coords.lng ?? props.centroid?.lon ?? existing.coords?.lng;
    const labelLat = props.label_point?.lat ?? existing.labelCoords?.lat ?? centroidLat;
    const labelLng = props.label_point?.lon ?? existing.labelCoords?.lng ?? centroidLng;

    const entry = {
      name: props.name_official ?? index.name ?? existing.name ?? slug.replace(/-/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase()),
      slug,
      cluster: clusterSlug,
      lga: index.lga ?? existing.lga ?? null,
      state: props.state ?? existing.state ?? 'QLD',
      coords: centroidLat != null && centroidLng != null
        ? { lat: Number.parseFloat(Number(centroidLat).toFixed(6)), lng: Number.parseFloat(Number(centroidLng).toFixed(6)) }
        : existing.coords,
      labelCoords: labelLat != null && labelLng != null
        ? { lat: Number.parseFloat(Number(labelLat).toFixed(6)), lng: Number.parseFloat(Number(labelLng).toFixed(6)) }
        : existing.labelCoords,
      distanceToBneCbdKm: index.distance_to_bne_cbd_km ?? existing.distanceToBneCbdKm ?? null,
      landmarks: existing.landmarks ?? [],
    };

    if (entry.distanceToBneCbdKm != null) {
      entry.distanceToBneCbdKm = Number.parseFloat(entry.distanceToBneCbdKm.toFixed(3));
    }

    if (!entry.lga) delete entry.lga;
    if (!entry.distanceToBneCbdKm && entry.distanceToBneCbdKm !== 0) delete entry.distanceToBneCbdKm;

    const tierInfo = tierMap[slug];
    const registryInfo = registryStates[slug];
    if (tierInfo || registryInfo) {
      entry.meta = {
        ...(tierInfo ? { tier: tierInfo.tier } : {}),
        ...(registryInfo ? { state: registryInfo.state, tier: registryInfo.tier ?? tierInfo?.tier, since: registryInfo.since, deprecatedSince: registryInfo.deprecatedSince } : {}),
      };
      if (!entry.meta.state) delete entry.meta.state;
      if (!entry.meta.since) delete entry.meta.since;
      if (!entry.meta.deprecatedSince) delete entry.meta.deprecatedSince;
      if (!entry.meta.tier) delete entry.meta.tier;
      if (!Object.keys(entry.meta).length) delete entry.meta;
    }

    if (!entry.coords) delete entry.coords;
    if (!entry.labelCoords) delete entry.labelCoords;

    suburbEntries.push(entry);
  }

  suburbEntries.sort((a, b) => a.name.localeCompare(b.name));

  const adjacency = {};
  for (const [slug, neighbors] of Object.entries(adjacencyDoc)) {
    if (!suburbClusterMap.has(slug)) continue;
    const list = Array.isArray(neighbors) ? neighbors : neighbors?.adjacent_suburbs;
    const filtered = (list ?? []).filter((n) => n && n !== slug && suburbClusterMap.has(n));
    filtered.sort((a, b) => a.localeCompare(b));
    adjacency[slug] = { adjacent_suburbs: filtered };
  }

  const filteredAliases = {};
  for (const [alias, canonical] of Object.entries(aliasesDoc)) {
    if (!canonical || !suburbClusterMap.has(canonical)) continue;
    if (canonical === 'moreton-bay') continue;
    filteredAliases[alias] = canonical;
  }

  writeJson(path.join(root, 'src/content/areas.clusters.json'), { clusters });
  writeJson(path.join(root, 'src/data/suburbs.json'), suburbEntries);
  writeJson(path.join(root, 'src/data/adjacency.json'), adjacency);
  writeJson(path.join(root, 'src/data/suburbs.aliases.json'), filteredAliases);
}

main();
