import { log } from '../util/log.mjs';

function clusterId(ctx, suburb) {
  const cl = ctx.datasets.clusters.clusterOf?.[suburb];
  return cl ? `${ctx.config.siteUrl}/areas/${cl}#place` : undefined;
}
function placeId(ctx, suburb) {
  return `${ctx.config.siteUrl}/areas/${suburb}#place`;
}
function canonicalUrl(ctx, service, suburb) {
  return `${ctx.config.siteUrl}/services/${service}/${suburb}/`;
}
function datasetId(ctx) {
  return `${ctx.config.siteUrl}/api/agents/graph.json#dataset`;
}
function dataDownloads(ctx) {
  const base = `${ctx.config.siteUrl}/api/agents`;
  return [
    { '@type': 'DataDownload', encodingFormat: 'application/json', contentUrl: `${base}/graph.json` },
    { '@type': 'DataDownload', encodingFormat: 'application/json', contentUrl: `${base}/index.json` },
    { '@type': 'DataDownload', encodingFormat: 'application/json', contentUrl: `${base}/clusters.json` }
  ];
}

export default {
  id: '03-emit-jsonld',
  async eachNode(ctx, { service, suburb }) {
    const svc = ctx.config.services.find(s => s.id === service) || { name: service };
    const sMeta = ctx.datasets.meta[suburb] || {};
    const features = (sMeta.uniqueFeatures || []).map(f => ({ '@type': 'LocationFeatureSpecification', name: f, value: true }));
    const extraProps = []
      .concat(sMeta.startingPrice != null ? [{ '@type': 'PropertyValue', name: 'Starting price', value: `$${sMeta.startingPrice}` }] : [])
      .concat(sMeta.guarantee ? [{ '@type': 'PropertyValue', name: 'Guarantee', value: sMeta.guarantee }] : [])
      .concat(sMeta.population ? [{ '@type': 'PropertyValue', name: 'Population', value: String(sMeta.population) }] : [])
      .concat(sMeta.cbdConvenience ? [{ '@type': 'PropertyValue', name: 'CBD location convenience', value: sMeta.cbdConvenience }] : [])
      .concat(sMeta.highRiseExpertise ? [{ '@type': 'PropertyValue', name: 'High-rise apartment expertise', value: sMeta.highRiseExpertise }] : []);

    // Neighbor relations using valueReference to Place @id
    const neighborProps = (ctx.datasets.adj[suburb] || []).map(n => ({
      '@type': 'PropertyValue',
      name: 'Adjacent to',
      valueReference: { '@id': placeId(ctx, n) }
    }));

    const clusterPlaceId = clusterId(ctx, suburb);

    const place = {
      '@context': 'https://schema.org',
      '@type': 'Place',
      '@id': placeId(ctx, suburb),
      url: canonicalUrl(ctx, service, suburb),
      mainEntityOfPage: canonicalUrl(ctx, service, suburb),
      name: sMeta.name || suburb,
      address: { '@type': 'PostalAddress', addressLocality: sMeta.name || suburb, addressRegion: sMeta.region, postalCode: sMeta.postcode, addressCountry: 'AU' },
      geo: sMeta.coordinates && { '@type': 'GeoCoordinates', latitude: sMeta.coordinates.lat, longitude: sMeta.coordinates.lng },
      containedInPlace: clusterPlaceId ? { '@id': clusterPlaceId } : undefined,
      sameAs: sMeta.sameAs || [],
      additionalProperty: [...extraProps, ...neighborProps].filter(Boolean),
      subjectOf: { '@id': datasetId(ctx) }
    };

    const dataset = {
      '@context': 'https://schema.org', '@type': 'Dataset', '@id': datasetId(ctx),
      name: 'Queensland Suburb Adjacency Graph',
      description: 'Graph of suburbs, clusters, distances, and adjacency used to power localized routing and SEO.',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      keywords: ['suburbs','adjacency','queensland','distances','clusters'],
      distribution: dataDownloads(ctx)
    };

    const cleaningService = {
      '@context': 'https://schema.org', '@type': 'Service',
      name: `${svc.name} in ${sMeta.name || suburb}`,
      url: canonicalUrl(ctx, service, suburb),
      areaServed: { '@id': place['@id'] },
      additionalProperty: features.map(f => ({ '@type': 'PropertyValue', name: f.name, value: 'true' })),
      mainEntityOfPage: canonicalUrl(ctx, service, suburb),
      subjectOf: { '@id': datasetId(ctx) }
    };

    const localBusiness = {
      '@context': 'https://schema.org', '@type': 'LocalBusiness',
      name: ctx.config.business?.name || 'One N Done Bond Clean',
      url: canonicalUrl(ctx, service, suburb),
      areaServed: { '@id': place['@id'] },
      amenityFeature: features,
      additionalProperty: extraProps,
      subjectOf: { '@id': datasetId(ctx) }
    };

    if (sMeta.aggregateRating && typeof sMeta.aggregateRating.ratingValue !== 'undefined') {
      localBusiness.aggregateRating = {
        '@type': 'AggregateRating',
        ratingValue: String(sMeta.aggregateRating.ratingValue),
        reviewCount: String(sMeta.aggregateRating.reviewCount || 0)
      };
    }

    ctx.jsonld ||= {};
    ctx.jsonld[`${service}/${suburb}`] = { localBusiness, cleaningService, place, dataset };
    log.info(`JSON-LD v4 ready → ${service}/${suburb}`);
  }
};
