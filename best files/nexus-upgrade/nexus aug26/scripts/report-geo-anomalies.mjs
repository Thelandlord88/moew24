#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const ROOT = process.cwd();
const DATA_DIR = path.join(ROOT, 'src', 'data');
const CONTENT_DIR = path.join(ROOT, 'src', 'content');

const readJson = (filePath) => {
  const raw = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(raw);
};

const normalize = (value) => {
  if (typeof value !== 'string') return '';
  const trimmed = value.trim();
  if (!trimmed) return '';
  return trimmed
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-');
};

const toSlugSet = (values = []) => {
  const set = new Set();
  for (const value of values) {
    const slug = normalize(value);
    if (slug) set.add(slug);
  }
  return set;
};

function loadClusters() {
  const clusters = readJson(path.join(CONTENT_DIR, 'areas.clusters.json'));
  const clusterMap = new Map();
  for (const [key, descriptor] of Object.entries(clusters)) {
    if (Array.isArray(descriptor)) {
      clusterMap.set(normalize(key), toSlugSet(descriptor));
    } else if (descriptor && typeof descriptor === 'object' && Array.isArray(descriptor.suburbs)) {
      clusterMap.set(normalize(key), toSlugSet(descriptor.suburbs));
    }
  }
  return clusterMap;
}

function loadCoverage() {
  const coverage = readJson(path.join(DATA_DIR, 'serviceCoverage.json'));
  const map = new Map();
  for (const [service, suburbs] of Object.entries(coverage)) {
    map.set(normalize(service), Array.from(toSlugSet(suburbs)));
  }
  return map;
}

function loadAdjacency() {
  return readJson(path.join(DATA_DIR, 'adjacency.json'));
}

function loadKnownSuburbs() {
  const suburbs = readJson(path.join(DATA_DIR, 'suburbs.json'));
  const set = new Set();
  for (const entry of suburbs) {
    if (!entry || typeof entry !== 'object') continue;
    set.add(normalize(entry.slug || entry.name));
  }
  return set;
}

function invertClusters(clusterMap) {
  const map = new Map();
  for (const [cluster, suburbs] of clusterMap.entries()) {
    for (const suburb of suburbs) {
      if (!suburb) continue;
      map.set(suburb, cluster);
    }
  }
  return map;
}

function analyse() {
  const clusters = loadClusters();
  const coverage = loadCoverage();
  const adjacency = loadAdjacency();
  const knownSuburbs = loadKnownSuburbs();
  const suburbToCluster = invertClusters(clusters);

  const issues = {
    missingCluster: [],
    missingCoverageEntry: [],
    weakAdjacency: [],
  };

  for (const [service, suburbs] of coverage.entries()) {
    for (const suburb of suburbs) {
      if (!suburbToCluster.has(suburb)) {
        issues.missingCluster.push({ service, suburb });
      }
      if (!knownSuburbs.has(suburb)) {
        issues.missingCoverageEntry.push({ service, suburb });
      }
      const node = adjacency[suburb];
      const adjCount = Array.isArray(node?.adjacent_suburbs) ? node.adjacent_suburbs.length : 0;
      if (!node || adjCount < 2) {
        issues.weakAdjacency.push({ suburb, neighbours: node?.adjacent_suburbs || [] });
      }
    }
  }

  return {
    summary: {
      servicesAnalysed: coverage.size,
      totalSuburbs: new Set(Array.from(coverage.values()).flat()).size,
      clusters: clusters.size,
    },
    issues,
  };
}

function formatIssueList(label, items, formatter) {
  if (!items.length) return `${label}: ✅ none`;
  const lines = items
    .slice(0, 10)
    .map((item) => `  - ${formatter(item)}`)
    .join('\n');
  const more = items.length > 10 ? `  … ${items.length - 10} more` : '';
  return `${label}: ⚠️ ${items.length}\n${lines}${more ? `\n${more}` : ''}`;
}

function main() {
  const report = analyse();
  console.log('🗺️  GEO ANOMALY REPORT');
  console.log(`   Services analysed: ${report.summary.servicesAnalysed}`);
  console.log(`   Unique suburbs:   ${report.summary.totalSuburbs}`);
  console.log(`   Cluster groups:   ${report.summary.clusters}`);
  console.log();

  console.log(
    formatIssueList(
      'Suburbs missing cluster assignment',
      report.issues.missingCluster,
      (item) => `${item.suburb} (service: ${item.service})`
    )
  );
  console.log();

  console.log(
    formatIssueList(
      'Suburbs missing metadata entry',
      report.issues.missingCoverageEntry,
      (item) => `${item.suburb} (service: ${item.service})`
    )
  );
  console.log();

  console.log(
    formatIssueList(
      'Suburbs with weak adjacency (<2 neighbours)',
      report.issues.weakAdjacency,
      (item) => `${item.suburb} (${item.neighbours.length} neighbours)`
    )
  );

  if (report.issues.missingCoverageEntry.length) {
    console.log('   ℹ️  Metadata gaps detected — recommended to enrich src/data/suburbs.json incrementally.');
  }

  const hasIssues =
    report.issues.missingCluster.length ||
    report.issues.weakAdjacency.length;

  process.exitCode = hasIssues ? 1 : 0;
}

main();
