export default {
  id: 'geo-build/level-1',
  steps: [
    '01-load-geo',
    '02-derive-graph',
    '07-auto-fix-graph',
    '05-internal-links',
    '08-optimize-links',
    '03-emit-jsonld',
    '04-write-pages',
    '06-quality-gates',
    '09-run-summary'
  ]
};
