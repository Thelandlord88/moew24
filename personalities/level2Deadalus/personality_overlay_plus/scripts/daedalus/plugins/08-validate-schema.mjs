import { mkdir, writeFile } from 'node:fs/promises';

function isObj(x){ return x && typeof x === 'object' && !Array.isArray(x); }
function required(obj, path, errors, key){
  const ok = obj && obj[key] !== undefined && obj[key] !== null && (typeof obj[key] !== 'string' || obj[key].length > 0);
  if (!ok) errors.push(`${path}.${key} missing`);
}
function hasType(obj, path, errors, type){
  if (!(obj && (obj['@type'] === type))) errors.push(`${path} must have @type=${type}`);
}

export default {
  id: '08-validate-schema',
  async afterAll(ctx) {
    const errors = [];
    const warnings = [];
    const report = [];

    const allPlaces = new Set();
    // Compute known place IDs
    for (const t of ctx.targets) {
      const pid = `${ctx.config.siteUrl}/areas/${t.suburb}#place`;
      allPlaces.add(pid);
    }
    const datasetId = `${ctx.config.siteUrl}/api/agents/graph.json#dataset`;

    const entries = Object.entries(ctx.jsonld || {});
    for (const [key, blocks] of entries) {
      const pageErrs = [];
      const where = `jsonld[${key}]`;
      if (!isObj(blocks)) { errors.push(`${where} not an object`); continue; }

      const { localBusiness, cleaningService, place, dataset } = blocks;
      if (!localBusiness || !cleaningService || !place || !dataset) {
        errors.push(`${where} missing one or more required blocks (LocalBusiness, Service, Place, Dataset)`);
        continue;
      }

      // Basic shape checks
      hasType(localBusiness, `${where}.localBusiness`, pageErrs, 'LocalBusiness');
      hasType(cleaningService, `${where}.cleaningService`, pageErrs, 'Service');
      hasType(place, `${where}.place`, pageErrs, 'Place');
      hasType(dataset, `${where}.dataset`, pageErrs, 'Dataset');

      required(place, `${where}.place`, pageErrs, '@id');
      required(place, `${where}.place`, pageErrs, 'url');
      required(dataset, `${where}.dataset`, pageErrs, 'distribution');

      // Neighbor valueReference checks
      const ap = Array.isArray(place.additionalProperty) ? place.additionalProperty : [];
      const neighborRefs = ap.filter(p => p?.valueReference?.['@id']).map(p => p.valueReference['@id']);
      for (const id of neighborRefs) {
        if (!allPlaces.has(id)) {
          pageErrs.push(`${where}.place.additionalProperty.valueReference @id not found in known places: ${id}`);
        }
      }

      // subjectOf consistency
      if (place.subjectOf?.['@id'] && place.subjectOf['@id'] !== datasetId) {
        pageErrs.push(`${where}.place.subjectOf should point to ${datasetId}`);
      }
      if (cleaningService.subjectOf?.['@id'] && cleaningService.subjectOf['@id'] !== datasetId) {
        pageErrs.push(`${where}.cleaningService.subjectOf should point to ${datasetId}`);
      }
      if (localBusiness.subjectOf?.['@id'] && localBusiness.subjectOf['@id'] !== datasetId) {
        pageErrs.push(`${where}.localBusiness.subjectOf should point to ${datasetId}`);
      }

      // Dataset downloads sanity
      const dist = Array.isArray(dataset.distribution) ? dataset.distribution : [];
      const need = new Set(['/api/agents/graph.json','/api/agents/index.json','/api/agents/clusters.json']);
      for (const d of dist) {
        if (d?.contentUrl && typeof d.contentUrl === 'string') {
          for (const n of Array.from(need)) {
            if (d.contentUrl.endsWith(n)) need.delete(n);
          }
        }
      }
      if (need.size > 0) {
        pageErrs.push(`${where}.dataset.distribution missing: ${Array.from(need).join(', ')}`);
      }

      report.push({ key, errors: pageErrs });
      if (pageErrs.length) errors.push(...pageErrs);
    }

    await mkdir('__reports/daedalus', { recursive: true });
    await writeFile('__reports/daedalus/schema.validation.json', JSON.stringify({ errors, warnings, report }, null, 2));

    if (errors.length) {
      throw new Error(`Schema validation failed: ${errors.length} errors. See __reports/daedalus/schema.validation.json`);
    }
  }
};
