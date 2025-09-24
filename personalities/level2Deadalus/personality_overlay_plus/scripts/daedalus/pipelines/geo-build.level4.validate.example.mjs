// Example pipeline with schema validation
export default {
  id: 'geo-build/level-4+validate',
  steps: [
    '01-load-geo',
    '02-derive-graph',
    '05-internal-links',
    '03-emit-jsonld',
    '04-write-pages',
    '08-validate-schema',
    '06-quality-gates',
    '07-sitemap-robots'
  ]
};
