# Daedalus — Level 4 (Schema-Forward Crawl Accelerator)

Double-down on **schema-as-crawl-engine**:
- Rich JSON-LD (LocalBusiness, Service, Place, Dataset with DataDownload)
- Master index `/service-areas/` (`CollectionPage` + `ItemList` of clusters)
- Machine-readable `/api/agents/` endpoints (index, graph, clusters)
- Robots tuned to **allow** `/api/agents/` and surface dataset links

## Apply
```bash
unzip daedalus_level4_schema.zip -d .
node scripts/daedalus/cli.mjs build
```
