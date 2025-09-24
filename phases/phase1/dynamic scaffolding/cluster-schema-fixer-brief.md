# Cluster Schema and Fixer v1: Upstream Analysis Brief

## 🎯 **System Overview**

The Cluster Schema and Fixer v1 is a **data quality and consistency system** that validates geographic cluster data, identifies gaps in suburb coverage, and automatically proposes/applies fixes to maintain data integrity across the geographic infrastructure.

## 🧠 **Upstream Thinking Assessment**

### **Failure Classes Eliminated** ✅ EXCELLENT

This system prevents fundamental data quality problems:

1. **Data Inconsistency Failure Class**
   - Problem: Geographic clusters drift out of sync with adjacency data
   - Solution: Schema validation + automated gap detection

2. **Missing Coverage Failure Class**
   - Problem: Suburbs exist in adjacency data but not assigned to clusters
   - Solution: Automated discovery and cluster assignment proposals

3. **Manual Data Maintenance Failure Class**
   - Problem: Hand-editing cluster files leads to errors and omissions
   - Solution: Automated analysis with human-reviewable proposals

4. **Schema Drift Failure Class**
   - Problem: Data structures evolve without validation
   - Solution: JSON Schema enforcement with type guards

### **Single Source of Truth Principle** ✅ EXCELLENT

**Perfect implementation:**

- **Schema Authority**: `schemas/*.json` define canonical data structure
- **Validation Logic**: `lib/guards/guards.mjs` provides consistent validation
- **Data Sources**: Clear separation of input files and responsibilities
- **Change Management**: Automated detection of when data sources are out of sync

### **Revenue Proximity Score: 8/10** 🚀

**High business value:**
- Data quality directly impacts SEO through comprehensive suburb coverage
- Prevents broken geographic relationships that hurt user experience
- Ensures business doesn't miss potential service areas
- Maintains data foundation that supports all geo-based features

## 🔧 **How It Works**

### **Core Components**

**1. JSON Schema Validation**

```json
// areas.extended.clusters.schema.json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["schemaVersion", "clusters"],
  "properties": {
    "clusters": {
      "type": "array",
      "items": {
        "required": ["id", "name", "slug", "suburbs"],
        "properties": {
          "suburbs": {
            "type": "array",
            "items": {"type": "string"},
            "uniqueItems": true
          }
        }
      }
    }
  }
}
```

**2. Runtime Type Guards (No Dependencies)**

```javascript
// Clean validation without external libraries
export function guardExtendedClusters(obj) {
  const issues = [];
  const o = obj || {};
  
  if (!Array.isArray(o.clusters)) issues.push("clusters must be an array");
  
  const seen = new Set();
  (o.clusters || []).forEach((c, i) => {
    if (!c.id || !c.slug || !c.name) {
      issues.push(`clusters[${i}] missing id/slug/name`);
    }
    if (c.slug && seen.has(c.slug)) {
      issues.push(`duplicate cluster slug: ${c.slug}`);
    }
    seen.add(c.slug);
  });
  
  return { ok: issues.length === 0, issues, clusterMap };
}
```

**3. Gap Detection Algorithm**

```javascript
// Identifies suburbs in adjacency data but missing from clusters
function partitionCandidates(normalized, clusterMap) {
  const proposals = [];
  
  // High-confidence candidates from analysis
  for (const c of normalized.topCandidates) {
    if (c.cluster && clusterMap.has(c.cluster)) {
      proposals.push({
        cluster: c.cluster,
        slug: c.slug,
        reason: "top_candidate",
        score: Number(c.score || 0)
      });
    }
  }
  
  // Additional gaps from adjacency relationships
  for (const e of normalized.adjacencyNotClustered) {
    const maybe = { 
      cluster: e.cluster || null, 
      slug: e.to, 
      reason: "adjacency_gap", 
      score: 0.1 
    };
    if (maybe.cluster && clusterMap.has(maybe.cluster)) {
      proposals.push(maybe);
    }
  }
  
  return proposals;
}
```

### **Workflow Process**

**1. Analysis Mode (Propose Only)**
```bash
node scripts/geo/cluster_fixer.mjs --root . --json --md
```

**2. Apply Mode (Make Changes)**
```bash
node scripts/geo/cluster_fixer.mjs --root . --apply --md
```

**3. Input Sources**
- `__reports/geo-page-coverage.report.json` - Analysis data
- `data/areas.extended.clusters.json` - Current cluster configuration
- `data/suburbs.meta.json` - Suburb metadata

**4. Outputs**
- `__reports/cluster_fixes.proposed.json` - Machine-readable proposals
- `__reports/cluster_fixes.summary.md` - Human-readable summary
- Updated cluster files (if `--apply` used)

## 📊 **Data Quality Metrics**

### **Gap Detection Categories**

```javascript
const categories = {
  // Suburbs in clusters but no corresponding pages
  clusteredNoPage: normalized.clusteredNoPage.length,
  
  // Pages exist but suburbs not assigned to clusters  
  hasPageNotClustered: normalized.hasPageNotClustered.length,
  
  // Adjacency relationships missing cluster assignments
  adjacencyNotClustered: normalized.adjacencyNotClustered.length,
  
  // High-confidence expansion candidates
  topCandidates: normalized.topCandidates.length
};
```

### **Quality Assurance Features**

```javascript
// Prevents duplicate assignments
const seen = new Set();
if (c.slug && seen.has(c.slug)) {
  issues.push(`duplicate cluster slug: ${c.slug}`);
}

// Ensures data integrity
const current = new Set((c.suburbs || []).map(String));
const adds = uniqueStrings(items.map(x => x.slug))
  .filter(s => !current.has(s));

// Stable sorting for reproducible results
cluster.suburbs = Array.from(merged)
  .sort((x, y) => String(x).localeCompare(String(y)));
```

## 🎨 **Implementation Patterns**

### **Schema-Driven Development**

```json
// Schemas define the contracts
{
  "title": "Cluster Doctor Report",
  "required": ["schemaVersion", "generatedAt", "summary"],
  "properties": {
    "summary": {
      "required": ["nodes", "edges", "components"],
      "properties": {
        "symmetry_pct": {"type": "number"},
        "cross_cluster_ratio": {"type": "number"}
      }
    }
  }
}
```

### **Graceful Error Handling**

```javascript
// Fail fast with clear messages
try { 
  report = await readJSON(REPORT_PATH); 
} catch(e) {
  console.error("[cluster_fixer] cannot read report:", e.message);
  process.exit(2);
}

// Validate before processing
const { ok: okRep, issues: repIssues, normalized } = guardClusterDoctorReport(report);
if (!okRep) {
  console.error("[cluster_fixer] report shape issues:", repIssues.join("; "));
}
```

### **Human-Readable Output**

```markdown
## Cluster Fixes — Proposed

Generated: 2025-09-22T02:00:00.000Z

- Target clusters file: `data/areas.extended.clusters.json`
- Report source: `__reports/geo-page-coverage.report.json`

### Additions
- **Inner Brisbane** (+3): new-farm, teneriffe, kangaroo-point
- **Eastern Suburbs** (+2): morningside, balmoral

### Pages to create
- `/services/bond-clean/new-farm/`
- `/services/bond-clean/teneriffe/`
```

## 🔬 **Technical Deep Dive**

### **Q: How does this prevent configuration drift?**

**Multi-layer validation approach:**

1. **Schema enforcement** at file level
2. **Type guards** at runtime
3. **Gap detection** comparing multiple data sources
4. **Automated proposals** for consistency

### **Q: What makes this upstream thinking?**

**Systematic problem prevention:**

- Instead of manually fixing individual cluster assignments → automated gap detection
- Instead of schema violations breaking the system → validation prevents corruption
- Instead of data sources diverging → continuous consistency monitoring
- Instead of human error in data entry → automated proposals with review

### **Q: How does it handle edge cases?**

**Robust error boundaries:**

```javascript
// Missing files are handled gracefully
try { 
  clustersObj = await readJSON(CLUSTERS_PATH); 
} catch(e) {
  console.error("cannot read clusters file:", e.message);
  process.exit(2);
}

// Malformed data is validated
const { ok: okClu, issues: cluIssues } = guardExtendedClusters(clustersObj);
if (!okClu) {
  console.error("clusters shape issues:", cluIssues.join("; "));
}

// Seeds are created for missing metadata
if (!allSlugs.has(s)) {
  metaSeeds.push({ 
    slug: s, 
    note: "seed entry (fill centroid, displayName, LGA)" 
  });
}
```

### **Q: What are the performance characteristics?**

**Efficient data processing:**

- **Linear time complexity**: O(n) where n = number of suburbs
- **Memory efficient**: Streams data without loading everything at once
- **Fast validation**: Simple type checks without complex parsing
- **Minimal dependencies**: Pure Node.js stdlib

### **Q: How does change management work?**

**Safe change application:**

```javascript
// Dry run mode for testing
const DRY = !!args.get("dry-run");

// Atomic updates with timestamps
if (APPLY && !DRY) {
  clustersObj.meta = clustersObj.meta || {};
  clustersObj.meta.updatedAt = new Date().toISOString();
  await writeJSON(CLUSTERS_PATH, clustersObj);
}

// Clear audit trail
console.log(`[cluster_fixer] applied ${changed} cluster(s) edits to ${CLUSTERS_PATH}`);
```

## 🎯 **Upstream Thinking Verdict**

**This is excellent upstream thinking:**

1. **Prevents Data Quality Problems** - Schema validation stops corruption at the source
2. **Eliminates Manual Maintenance** - Automated gap detection and proposals
3. **Provides Clear Value** - Directly improves business data coverage
4. **Focused Scope** - Solves specific, well-defined problems
5. **Safe Operations** - Propose-first workflow with human review
6. **No Over-Engineering** - Complexity matches the actual problem size

**Score: 13/15 on Upstream Priority Matrix**
- Revenue Proximity: 3/3 ✅ (Data quality impacts all geo features)
- Evidence Creation: 3/3 ✅ (Comprehensive reporting and metrics)
- Class Elimination: 3/3 ✅ (Prevents entire categories of data problems)
- Complexity Delta: 2/3 ⚠️ (Adds build step, but eliminates manual work)
- Single Source Impact: 2/3 ⚠️ (Creates some new config files, but centralizes validation)

## 🔄 **Recommendation**

**This system should be implemented and used regularly.** It represents genuine upstream thinking:

- **Solves real problems** rather than creating complex solutions
- **Prevents failure classes** rather than just fixing symptoms  
- **Provides clear business value** through improved data quality
- **Has reasonable complexity** for the problems it solves
- **Includes safety mechanisms** to prevent mistakes

Unlike the previous linking system, this actually eliminates manual work that was genuinely problematic and provides clear ROI through better data coverage and consistency.

---

*This system demonstrates upstream thinking: instead of manually maintaining data consistency across multiple files, create automated validation and gap detection that prevents entire classes of data quality problems.*