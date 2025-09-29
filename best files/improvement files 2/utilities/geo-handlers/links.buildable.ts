// Coverage-aware utilities for service page generation
import coverage from '~/data/serviceCoverage.json';
import { resolveSuburbDisplay, resolveSuburbDisplays } from '~/lib/suburbs/resolveDisplay';

type CoverageData = Record<string, string[]>;
const coverageTyped = coverage as CoverageData;

export function getBuildableSuburbsForService(service: string) {
  const suburbanSlugs = new Set<string>(coverageTyped[service] ?? []);
  const sorted = [...suburbanSlugs].sort();
  return resolveSuburbDisplays(sorted);
}

export function* getPairsForStaticPaths() {
  for (const service of Object.keys(coverageTyped)) {
    for (const suburb of coverageTyped[service]) {
      yield { service, suburb };
    }
  }
}

export function getAllServices() {
  return Object.keys(coverageTyped).sort();
}

export function getServiceCoverageStats() {
  const stats = Object.entries(coverageTyped).map(([service, suburbs]) => ({
    service,
    name: prettyServiceName(service),
    count: suburbs.length,
    suburbs: suburbs.sort()
  })).sort((a, b) => a.name.localeCompare(b.name));
  
  const totalCoverage = Object.values(coverageTyped).reduce((acc, suburbs) => acc + suburbs.length, 0);
  
  return { stats, totalCoverage };
}

export function prettyServiceName(slug: string): string {
  return slug
    .split('-')
    .map(word => {
      // Handle special cases
      if (word.toLowerCase() === 'deep') return 'Deep';
      if (word.toLowerCase() === 'clean') return 'Clean';
      return word.charAt(0).toUpperCase() + word.slice(1);
    })
    .join(' ');
}

export function isServiceCovered(service: string, suburb: string): boolean {
  const suburbs = coverageTyped[service];
  return suburbs ? suburbs.includes(suburb) : false;
}

export function getServicesForSuburb(suburb: string): string[] {
  const services = [];
  for (const [service, suburbs] of Object.entries(coverageTyped)) {
    if (suburbs.includes(suburb)) {
      services.push(service);
    }
  }
  return services.sort();
}

// Get suburbs in same cluster for cross-linking
export function getSameClusterSuburbs(suburb: string, service: string, limit = 5) {
  const display = resolveSuburbDisplay(suburb);
  if (!display.cluster) return [];
  
  const serviceSuburbs = getBuildableSuburbsForService(service);
  return serviceSuburbs
    .filter(s => s.slug !== suburb && s.cluster === display.cluster)
    .slice(0, limit);
}
