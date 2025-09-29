# Geo System Inconsistency Technical Debrief

**Date**: September 22, 2025  
**Investigator**: System Analysis  
**Status**: 🚨 Critical Architectural Inconsistency Detected  
**Severity**: High - Data integrity and system coherence compromised

---

## 🚨 Executive Summary

A critical inconsistency has been identified in the geo system where multiple conflicting suburb counts exist across different system components. This creates potential data integrity issues, user confusion, and maintenance complexity.

**Core Issue**: System references 345 suburbs in some components, 121 in others, and 120 in service coverage, with no clear reconciliation.

---

## 📊 Inconsistency Mapping

### **System Component Analysis**

| Component | Suburb Count | Source | Purpose |
|-----------|--------------|--------|---------|
| **Adjacency System** | 345 | `src/data/adjacency.json` | Geographic relationships |
| **Registry System** | 121 | `src/data/suburbs.registry.json` | Operational suburbs |
| **Service Coverage** | 120 | `src/data/serviceCoverage.json` | Actual service areas |
| **Geo Reports** | 345 | `__reports/geo-*.json` | System metrics |
| **Build Output** | 120 x 3 = 360 | Static page generation | Live service pages |

### **Data Source Verification**

```bash
# Adjacency system
jq 'keys | length' src/data/adjacency.json
# Output: 345

# Registry system  
jq '.suburbs | keys | length' src/data/suburbs.registry.json
# Output: 121

# Service coverage
jq '.["bond-cleaning"] | length' src/data/serviceCoverage.json
# Output: 120

# Build verification
find dist -name "*.html" -path "*/services/*" | wc -l
# Output: 360 (120 suburbs × 3 services)
```

---

## 🔍 Conflict Analysis

### **1. Registry vs Service Coverage Mismatch**

**Issue**: Registry has 121 suburbs, service coverage has 120
- **Registry suburbs**: 121 entries in `suburbs.registry.json`
- **Service coverage**: 120 suburbs per service
- **Missing suburb**: `chuwar-test-old` (status: "deprecated" since 2025-09-10)

**Root Cause**: Deprecated suburb still exists in registry but correctly excluded from service coverage

**Potential Impact**:
- Registry cleanup needed to remove deprecated entries
- State management process unclear
- Test data polluting production registry

### **2. Adjacency vs Registry Mismatch**

**Issue**: Adjacency system references 345 suburbs, registry only has 121
- **Adjacency scope**: 345 total suburbs (includes all QLD suburbs?)
- **Registry scope**: 121 operational suburbs  
- **Orphaned suburbs**: 225 suburbs exist in adjacency but not in operational registry

**Root Cause**: Adjacency system includes broader geographic scope than operational capacity

**Potential Impact**:
- "Nearby areas" suggestions may link to non-existent pages
- SEO and linking strategies may reference unavailable suburbs
- User confusion when clicking on adjacent area suggestions

### **3. Build System Integrity**

**Issue**: Static site generation only creates pages for service coverage suburbs (120)
- **Generated pages**: Based on `serviceCoverage.json` (120 suburbs)
- **Registry suburbs**: 121 suburbs marked as "published" or "staged"
- **Adjacency references**: 345 total suburbs

**Potential Impact**:
- Dead links to suburbs that exist in registry but not in service coverage
- 404 errors for users navigating from adjacency suggestions
- SEO penalties for broken internal linking

---

## 🔧 Technical Architecture Issues

### **1. Data Source Hierarchy Unclear**

**Problem**: No clear single source of truth for suburb data
```
adjacency.json (345) ←→ suburbs.registry.json (121) ←→ serviceCoverage.json (120)
```

**Questions**:
- Which system is authoritative?
- How do systems sync with each other?
- What happens when they're out of sync?

### **2. State Management Inconsistency**

**Registry States**:
```json
{
  "redbank-plains": { "state": "published" },
  "ripley": { "state": "staged" }
}
```

**Service Coverage**: No state concept, binary inclusion

**Issue**: A suburb can be "published" in registry but missing from service coverage

### **3. Build Process Dependencies**

**Current Flow**:
```
serviceCoverage.json → getStaticPaths() → Generated Pages
```

**Missing Links**:
- Registry state not consulted during build
- Adjacency data not validated against generated pages
- No sync verification between data sources

---

## 📋 System Component Detailed Analysis

### **Adjacency System (`src/data/adjacency.json`)**
- **Purpose**: Geographic relationship mapping
- **Scope**: 345 suburbs (full regional coverage)
- **Usage**: "Nearby areas" suggestions, SEO linking
- **Problem**: References suburbs that don't exist in other systems

### **Registry System (`src/data/suburbs.registry.json`)**
- **Purpose**: Operational suburb management with state tracking
- **Scope**: 121 suburbs with publication states
- **Usage**: Content management, editorial workflow
- **Problem**: Not connected to build process

### **Service Coverage (`src/data/serviceCoverage.json`)**
- **Purpose**: Define which suburbs get service pages
- **Scope**: 120 suburbs per service
- **Usage**: Static site generation via `getStaticPaths()`
- **Problem**: Missing 1 suburb vs registry, disconnected from adjacency

---

## 🚧 Immediate Issues Requiring Resolution

### **1. Missing Suburb Analysis**

**RESOLVED**: The missing suburb has been identified:

```bash
# Missing suburb: chuwar-test-old
jq -r '.suburbs."chuwar-test-old"' suburbs.registry.json
# Result: {"state": "deprecated", "tier": "core", "deprecatedSince": "2025-09-10T00:00:00.000Z"}
```

**Finding**: The suburb `chuwar-test-old` is marked as "deprecated" in the registry but still counted in the total. Service coverage correctly excludes deprecated suburbs.

### **2. Orphaned Adjacency References**

**CRITICAL**: 225 suburbs exist in adjacency but not in registry:

```bash
# Count of orphaned adjacency suburbs
comm -23 <(jq -r 'keys[]' adjacency.json | sort) \
         <(jq -r '.suburbs | keys[]' suburbs.registry.json | sort) | wc -l
# Result: 225 orphaned suburbs
```

**Impact**: Adjacency system suggests "nearby areas" that don't exist in the operational system, creating potential 404 errors.

### **3. Build Validation**
- Verify all service coverage suburbs generate pages
- Check for 404s when following adjacency suggestions
- Validate internal link integrity

---

## ⚠️ Risk Assessment

### **High Risk Issues**

1. **User Experience Degradation**
   - Broken links from adjacency suggestions
   - 404 errors on expected suburb pages
   - Inconsistent navigation experience

2. **SEO Impact**
   - Internal linking to non-existent pages
   - Crawl waste on broken adjacency links
   - Inconsistent site structure signals

3. **Data Integrity**
   - No single source of truth
   - Systems can drift independently
   - Manual sync required between systems

### **Medium Risk Issues**

1. **Development Complexity**
   - Multiple systems to maintain
   - Unclear data flow dependencies
   - Testing complexity across systems

2. **Content Management**
   - Editorial confusion about suburb availability
   - State management disconnected from build
   - Manual verification required

---

## 🔍 Required Investigation Steps

### **1. Data Reconciliation Audit**
```bash
# Generate comprehensive suburb mapping
npm run geo:audit:suburbs

# Identify exact mismatches
npm run geo:diff:systems

# Validate build output against all systems
npm run geo:validate:build
```

### **2. System Dependency Mapping**
- Document which components read from which data sources
- Identify all places where suburb lists are used
- Map the complete data flow

### **3. User Journey Impact Analysis**
- Test adjacency link navigation
- Verify all suburb selector options work
- Check for dead ends in user flow

---

## 🛠️ Technical Recommendations

### **1. Immediate Fixes Required**

1. **Identify Missing Suburb**: Determine which suburb is in registry (121) but not service coverage (120)
2. **Adjacency Validation**: Implement checks to ensure adjacency only references valid suburbs
3. **Build Verification**: Add validation step to prevent generating links to non-existent pages

### **2. Architecture Improvements Needed**

1. **Single Source of Truth**: Designate one system as authoritative
2. **Sync Mechanisms**: Implement automatic sync between systems
3. **Validation Pipeline**: Add pre-build validation of data consistency

### **3. Long-term Solutions**

1. **Unified Geo API**: Create single interface that reconciles all data sources
2. **State Management**: Implement proper state machine for suburb lifecycle
3. **Build Guards**: Prevent builds when data sources are inconsistent

---

## 📝 Next Actions Required

1. **Immediate**: Run data reconciliation audit to identify exact mismatches
2. **Short-term**: Fix the 1-suburb gap between registry and service coverage
3. **Medium-term**: Implement validation pipeline to prevent future inconsistencies
4. **Long-term**: Redesign geo architecture with clear data hierarchy

---

## 🚨 Critical Questions Requiring Answers

1. **Which system should be authoritative?** (345, 121, or 120 suburbs)
2. **What is the intended scope?** (Regional coverage vs operational capacity)
3. **How should systems sync?** (Manual, automatic, or build-time)
4. **What is the missing suburb?** (Registry 121 vs Coverage 120)
5. **Should adjacency be filtered?** (Only reference operational suburbs)

This inconsistency represents a critical architectural debt that must be resolved to ensure system integrity and user experience.
