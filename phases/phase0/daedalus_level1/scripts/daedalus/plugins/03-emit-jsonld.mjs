import { log } from '../util/log.mjs';

export default {
  id: '03-emit-jsonld',
  async eachNode(ctx, { service, suburb }) {
    const svc = ctx.config.services.find(s => s.id === service) || { name: service };
    const sMeta = ctx.datasets.meta[suburb] || {};
    const features = (sMeta.uniqueFeatures || []).map(f => ({ '@type': 'LocationFeatureSpecification', name: f, value: true }));
    const extraProps = []
      .concat(sMeta.startingPrice != null ? [{ '@type': 'PropertyValue', name: 'Starting price', value: `$${sMeta.startingPrice}` }] : [])
      .concat(sMeta.guarantee ? [{ '@type': 'PropertyValue', name: 'Guarantee', value: sMeta.guarantee }] : [])
      .concat(sMeta.population ? [{ '@type': 'PropertyValue', name: 'Population', value: String(sMeta.population) }] : []);

    const place = {
      '@context': 'https://schema.org', '@type': 'Place',
      '@id': `${ctx.config.siteUrl}/areas/${suburb}#place`,
      name: sMeta.name || suburb,
      address: {
        '@type': 'PostalAddress',
        addressLocality: sMeta.name || suburb,
        addressRegion: sMeta.region,
        postalCode: sMeta.postcode,
        addressCountry: 'AU'
      },
      geo: sMeta.coordinates && { '@type': 'GeoCoordinates', latitude: sMeta.coordinates.lat, longitude: sMeta.coordinates.lng },
      sameAs: sMeta.sameAs || [],
      additionalProperty: extraProps
    };

    const dataset = {
      '@context': 'https://schema.org',
      '@type': 'Dataset',
      '@id': `${ctx.config.siteUrl}/api/agents/suburbs.json#dataset`,
      name: 'Queensland Suburb Adjacency Graph',
      description: 'Graph of suburbs, clusters, distances, and adjacency used to power localized routing and SEO.',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      keywords: ['suburbs','adjacency','queensland','distances','clusters']
    };

    const cleaningService = {
      '@context': 'https://schema.org',
      '@type': 'Service',
      name: `${svc.name} in ${sMeta.name || suburb}`,
      areaServed: place,
      additionalProperty: features.map(f => ({ '@type': 'PropertyValue', name: f.name, value: 'true' }))
    };

    const localBusiness = {
      '@context': 'https://schema.org',
      '@type': 'LocalBusiness',
      name: ctx.config.business?.name || 'One N Done Bond Clean',
      areaServed: place,
      amenityFeature: features,
      additionalProperty: extraProps
    };

    ctx.jsonld ||= {};
    ctx.jsonld[`${service}/${suburb}`] = { localBusiness, cleaningService, place, dataset };
    log.info(`JSON-LD ready → ${service}/${suburb}`);
  }
};
