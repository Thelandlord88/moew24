// Replace your pipeline file or add '07-sitemap-robots' as a final step
export default {
  id: 'geo-build/level-3',
  steps: [
    '01-load-geo',
    '02-derive-graph',
    '05-internal-links',
    '03-emit-jsonld',
    '04-write-pages',
    '06-quality-gates',
    '07-sitemap-robots'
  ]
};
