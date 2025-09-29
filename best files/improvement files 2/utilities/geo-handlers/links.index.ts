// Unified linking facade - single entry point for all link operations
// Keep your existing imports internally
import { getKnownSuburbSlugs, findClusterSlugForSuburb, inSameCluster } from './knownSuburbs';
import { pickNearbyCoveredInSameCluster, pickNearbyCoveredInSameClusterSync } from './nearby';
import crossServiceMap from '~/data/crossServiceMap.json';
import coverageJson from '~/data/serviceCoverage.json';

export { getKnownSuburbSlugs, findClusterSlugForSuburb, inSameCluster };
export { pickNearbyCoveredInSameCluster, pickNearbyCoveredInSameClusterSync };

// Coverage
import coverage from '~/data/serviceCoverage.json';

export function isServiceCovered(service: string, suburb: string): boolean {
  const svc = (coverage as Record<string, string[]>)[service] || [];
  return svc.includes(suburb);
}

// Local guides (singular + plural)
// TEMP back-compat: pull a couple of helpers from legacy internalLinks until full removal.
// (These are only used during migration; once all callers moved we can inline and delete import.)
import { getLocalBlogLink as _getLocalBlogLink, getRelatedServiceLinks as _legacyGetRelated, unslugToName as _unslugToName } from '~/utils/internalLinks';

/** Singular, canonical: returns a single href or null */
export function getLocalGuidesLink(suburb: string): string | null {
  const href = _getLocalBlogLink(suburb);
  return href || null; // never undefined
}

/** Plural convenience: always returns an array (0 or 1 for now) */
export function getLocalGuidesLinks(suburb: string): string[] {
  const one = getLocalGuidesLink(suburb);
  return one ? [one] : [];
}

// Types for cross-service items
export interface LinkItem { 
  href: string; 
  title?: string; 
  label?: string; 
  ariaLabel?: string; 
}

export interface CrossServiceItem extends LinkItem {
  service: string; 
  suburb: string; 
  here: boolean; 
  nearby: boolean; 
  cluster: string;
}

// Utility to normalize legacy call-sites
export function asArray<T>(v: T | T[] | null | undefined): T[] {
  if (v == null) return [];
  return Array.isArray(v) ? v : [v];
}

// ---------- Service href helper ----------
export function toServiceHref(service: string, suburb: string): string {
  return `/services/${service}/${suburb}/`;
}

// ---------- Cross-service items (runtime parity with precomputed map) ----------
// We derive items for the “other services” navigation. Precomputed map is shape:
// { [suburbSlug]: { [currentService]: [ { label, href, here, data:{ service, suburb } } ] } }
// This accessor flattens for a given suburb across ALL services (excluding bond-cleaning itself by default)

type PreItem = { label: string; href: string; here: boolean; data: { service: string; suburb: string; source?: string } };
type PreMap = Record<string, Record<string, PreItem[]>>;
const PRE: PreMap = crossServiceMap as any;

// List of ancillary services we promote alongside bond cleaning (extend as needed)
const CROSS_SERVICES = ['spring-cleaning', 'bathroom-deep-clean'];

export function getCrossServiceItemsForSuburb(suburb: string, opts?: { currentService?: string }): CrossServiceItem[] {
  const current = opts?.currentService ?? 'bond-cleaning';
  const cluster = findClusterSlugForSuburb(suburb) || 'unknown';
  const out: CrossServiceItem[] = [];

  for (const svc of CROSS_SERVICES) {
    if (svc === current) continue;
    // If precomputed map has an entry keyed by suburb+current pick from there to stay deterministic.
    const pre = PRE[suburb]?.[current];
    let preMatch: PreItem | null = null;
    if (Array.isArray(pre)) {
      preMatch = pre.find(i => i.data?.service === svc) || null;
    }
    if (preMatch) {
      out.push({
        service: svc,
        suburb: preMatch.data.suburb,
        href: preMatch.href,
        label: preMatch.label,
        title: preMatch.label,
        here: preMatch.here,
        nearby: !preMatch.here,
        cluster
      });
      continue;
    }
    // Fallback: compute on the fly using coverage + BFS same-cluster policy
    const covered = isServiceCovered(svc, suburb);
    if (covered) {
      const label = humaniseService(svc);
      out.push({ service: svc, suburb, href: toServiceHref(svc, suburb), label, title: label, here: true, nearby: false, cluster });
    } else {
      const bfs = pickNearbyCoveredInSameClusterSync(svc, suburb, coverageJson as any);
      if (bfs) {
        const label = humaniseService(svc) + ' (nearby)';
        out.push({ service: svc, suburb: bfs.suburb, href: toServiceHref(svc, bfs.suburb), label, title: label, here: false, nearby: true, cluster });
      }
    }
  }
  return out;
}

function humaniseService(slug: string): string {
  switch (slug) {
    case 'spring-cleaning': return 'Spring Cleaning';
    case 'bathroom-deep-clean': return 'Bathroom Deep Clean';
    case 'bond-cleaning': return 'Bond Cleaning';
    default: return slug.replace(/-/g, ' ').replace(/\b\w/g, m => m.toUpperCase());
  }
}

// ---------- Related service links (back-compat) ----------
export function getRelatedServiceLinks(...args: any[]) {
  return (_legacyGetRelated as any)(...args);
}

export function unslugToName(slug: string) { return _unslugToName(slug); }

// Simple service cards (used by ServiceNav / older pages). This is intentionally light; pages can map CrossServiceItem themselves if they need richer content.
export interface ServiceCard { title: string; href: string; desc: string; attrs: Record<string,string>; }
export function toServiceCards(suburb: string, opts?: { currentService?: string }): ServiceCard[] {
  return getCrossServiceItemsForSuburb(suburb, opts).map(it => ({
    title: it.label || humaniseService(it.service),
    href: it.href,
    desc: it.here ? 'Available in your suburb' : 'Nearby area coverage',
    attrs: { 'data-service': it.service, 'data-nearby': String(it.nearby) }
  }));
}
