#!/usr/bin/env node
/**
 * Geo Suburbs Implementation Hunter - Complete Analysis
 * 
 * This hunter will:
 * 1. Analyze the clusters.json and count expected suburbs
 * 2. Find all files involved in suburb page generation
 * 3. Check for duplicate generation systems
 * 4. Identify geo coordinate implementation status
 * 5. Generate a comprehensive report for full geo implementation
 */

import fs from 'node:fs';
import path from 'node:path';

console.log('🌍 GEO SUBURBS IMPLEMENTATION HUNTER');
console.log('===================================');
console.log('');

const ANALYSIS = {
  expectedSuburbs: {},
  totalSuburbs: 0,
  generationSystems: [],
  geoFiles: [],
  duplicateSystems: [],
  missingImplementations: [],
  recommendations: []
};

// 1. Analyze the source of truth - clusters.json
console.log('📊 ANALYZING CLUSTERS.JSON (SOURCE OF TRUTH)');
console.log('===========================================');

const clustersPath = 'src/data/clusters.json';
if (fs.existsSync(clustersPath)) {
  const clustersData = JSON.parse(fs.readFileSync(clustersPath, 'utf8'));
  
  for (const [cluster, suburbs] of Object.entries(clustersData)) {
    ANALYSIS.expectedSuburbs[cluster] = suburbs.length;
    ANALYSIS.totalSuburbs += suburbs.length;
    console.log(`${cluster.padEnd(12)} → ${suburbs.length.toString().padStart(3)} suburbs`);
  }
  
  console.log('─'.repeat(30));
  console.log(`TOTAL EXPECTED → ${ANALYSIS.totalSuburbs.toString().padStart(3)} suburbs`);
} else {
  console.log('❌ clusters.json not found!');
  ANALYSIS.missingImplementations.push('clusters.json source file missing');
}

console.log('');

// 2. Find all page generation systems
console.log('🔍 FINDING PAGE GENERATION SYSTEMS');
console.log('==================================');

const pageGenerationFiles = [];

// Check src/pages for dynamic routes
function scanPagesForSuburbGeneration(dir, prefix = '') {
  if (!fs.existsSync(dir)) return;
  
  const items = fs.readdirSync(dir, { withFileTypes: true });
  for (const item of items) {
    const fullPath = path.join(dir, item.name);
    const urlPath = prefix + item.name;
    
    if (item.isDirectory()) {
      scanPagesForSuburbGeneration(fullPath, urlPath + '/');
    } else if (item.name.endsWith('.astro')) {
      const content = fs.readFileSync(fullPath, 'utf8');
      
      // Check if file has getStaticPaths and references suburbs
      if (content.includes('getStaticPaths') && 
          (content.includes('suburb') || content.includes('cluster'))) {
        pageGenerationFiles.push({
          file: fullPath,
          urlPattern: prefix + item.name.replace('.astro', ''),
          type: 'page-generation',
          hasGetStaticPaths: true,
          referencesSuburbs: content.includes('suburb'),
          referencesClusters: content.includes('cluster')
        });
      }
    }
  }
}

scanPagesForSuburbGeneration('src/pages', '/');

console.log('📄 PAGE GENERATION FILES:');
pageGenerationFiles.forEach(file => {
  console.log(`  ${file.urlPattern.padEnd(40)} → ${file.file}`);
  console.log(`     Suburbs: ${file.referencesSuburbs ? '✅' : '❌'} | Clusters: ${file.referencesClusters ? '✅' : '❌'}`);
});

ANALYSIS.generationSystems.push(...pageGenerationFiles);

console.log('');

// 3. Find geo-related files
console.log('🗺️  FINDING GEO-RELATED FILES');
console.log('=============================');

const geoPatterns = [
  'scripts/geo/**/*.{mjs,ts,js}',
  'src/utils/geo*.{ts,js}',
  'src/lib/*cluster*.{ts,js}',
  'src/data/*geo*.json',
  'src/data/*cluster*.json',
  'src/data/*suburb*.json'
];

function findGeoFiles() {
  const geoFiles = [];
  
  // Find all geo-related files
  const searchDirs = [
    'scripts/geo',
    'src/utils',
    'src/lib',
    'src/data',
    'src/content/suburbs'
  ];
  
  searchDirs.forEach(dir => {
    if (fs.existsSync(dir)) {
      const files = fs.readdirSync(dir, { recursive: true });
      files.forEach(file => {
        if (typeof file === 'string') {
          const fullPath = path.join(dir, file);
          if (fs.statSync(fullPath).isFile() && 
              (file.includes('geo') || file.includes('cluster') || file.includes('suburb'))) {
            geoFiles.push({
              file: fullPath,
              type: determineGeoFileType(fullPath, file),
              size: fs.statSync(fullPath).size
            });
          }
        }
      });
    }
  });
  
  return geoFiles;
}

function determineGeoFileType(fullPath, filename) {
  if (fullPath.includes('scripts/geo')) return 'geo-script';
  if (fullPath.includes('src/utils')) return 'geo-utility';
  if (fullPath.includes('src/lib')) return 'geo-library';
  if (fullPath.includes('src/data')) return 'geo-data';
  if (fullPath.includes('src/content')) return 'content-collection';
  return 'other';
}

const geoFiles = findGeoFiles();
console.log('📁 GEO-RELATED FILES:');
const filesByType = {};
geoFiles.forEach(file => {
  if (!filesByType[file.type]) filesByType[file.type] = [];
  filesByType[file.type].push(file);
});

Object.entries(filesByType).forEach(([type, files]) => {
  console.log(`  ${type.toUpperCase()}:`);
  files.forEach(file => {
    console.log(`    ${file.file} (${(file.size / 1024).toFixed(1)}KB)`);
  });
});

ANALYSIS.geoFiles = geoFiles;

console.log('');

// 4. Check for coordinate implementation
console.log('📍 CHECKING GEO COORDINATES IMPLEMENTATION');
console.log('==========================================');

const coordFiles = geoFiles.filter(f => 
  f.file.includes('coord') || 
  f.file.includes('lat') || 
  f.file.includes('lng') || 
  f.file.includes('geo')
);

console.log('📍 COORDINATE-RELATED FILES:');
coordFiles.forEach(file => {
  const content = fs.readFileSync(file.file, 'utf8');
  const hasLat = content.includes('lat') || content.includes('latitude');
  const hasLng = content.includes('lng') || content.includes('longitude');
  
  console.log(`  ${file.file}`);
  console.log(`    Lat: ${hasLat ? '✅' : '❌'} | Lng: ${hasLng ? '✅' : '❌'}`);
});

console.log('');

// 5. Check for duplicate systems
console.log('🔄 CHECKING FOR DUPLICATE GENERATION SYSTEMS');
console.log('=============================================');

// Look for different ways suburbs might be generated
const generationMethods = [];

// Method 1: Direct clusters.json usage
geoFiles.forEach(file => {
  const content = fs.readFileSync(file.file, 'utf8');
  if (content.includes('clusters.json') || content.includes('getClustersSync')) {
    generationMethods.push({
      method: 'clusters-json-based',
      file: file.file,
      priority: 'modern'
    });
  }
});

// Method 2: Legacy suburb files
const legacySuburbFiles = geoFiles.filter(f => 
  f.file.includes('suburb') && 
  !f.file.includes('clusters') &&
  f.file.endsWith('.json')
);

if (legacySuburbFiles.length > 0) {
  generationMethods.push({
    method: 'legacy-suburb-files',
    files: legacySuburbFiles.map(f => f.file),
    priority: 'legacy'
  });
}

console.log('📋 GENERATION METHODS FOUND:');
generationMethods.forEach((method, index) => {
  console.log(`  ${index + 1}. ${method.method.toUpperCase()} (${method.priority})`);
  if (method.file) {
    console.log(`     File: ${method.file}`);
  }
  if (method.files) {
    console.log(`     Files: ${method.files.length} files`);
    method.files.slice(0, 3).forEach(f => console.log(`       - ${f}`));
    if (method.files.length > 3) {
      console.log(`       ... and ${method.files.length - 3} more`);
    }
  }
});

ANALYSIS.generationSystems = generationMethods;

console.log('');

// 6. Analyze current build output
console.log('🏗️  ANALYZING CURRENT BUILD OUTPUT');
console.log('==================================');

const distDir = 'dist';
let builtSuburbs = 0;
let builtStructure = {};

if (fs.existsSync(distDir)) {
  // Count built suburb pages
  function countBuiltPages(dir, structure = {}) {
    if (!fs.existsSync(dir)) return structure;
    
    const items = fs.readdirSync(dir, { withFileTypes: true });
    items.forEach(item => {
      if (item.isDirectory()) {
        const subPath = path.join(dir, item.name);
        if (dir.includes('/areas/') && !item.name.includes('bond-cleaning')) {
          // This looks like a cluster/suburb structure
          const relativePath = path.relative(distDir, subPath);
          const pathParts = relativePath.split('/');
          
          if (pathParts.length >= 3 && pathParts[0] === 'areas') {
            const cluster = pathParts[1];
            const suburb = pathParts[2];
            
            if (!structure[cluster]) structure[cluster] = [];
            structure[cluster].push(suburb);
            builtSuburbs++;
          }
        }
        countBuiltPages(subPath, structure);
      }
    });
    return structure;
  }
  
  builtStructure = countBuiltPages(distDir);
  
  console.log('📊 BUILT SUBURBS BY CLUSTER:');
  Object.entries(builtStructure).forEach(([cluster, suburbs]) => {
    const expected = ANALYSIS.expectedSuburbs[cluster] || 0;
    const actual = suburbs.length;
    const status = actual === expected ? '✅' : actual > expected ? '⚠️' : '❌';
    
    console.log(`  ${cluster.padEnd(12)} → ${actual.toString().padStart(3)}/${expected.toString().padStart(3)} suburbs ${status}`);
  });
  
  console.log('─'.repeat(40));
  console.log(`TOTAL BUILT     → ${builtSuburbs.toString().padStart(3)}/${ANALYSIS.totalSuburbs} suburbs`);
} else {
  console.log('❌ No dist directory found - run build first');
}

console.log('');

// 7. Generate recommendations
console.log('💡 IMPLEMENTATION RECOMMENDATIONS');
console.log('=================================');

const recommendations = [];

// Check if we have the right number of suburbs
if (builtSuburbs !== ANALYSIS.totalSuburbs) {
  recommendations.push({
    priority: 'HIGH',
    issue: `Suburb count mismatch: built ${builtSuburbs}, expected ${ANALYSIS.totalSuburbs}`,
    action: 'Review getStaticPaths implementation in page generation files'
  });
}

// Check for duplicate generation systems
if (generationMethods.length > 1) {
  recommendations.push({
    priority: 'MEDIUM',
    issue: `Multiple generation systems found: ${generationMethods.length} different methods`,
    action: 'Consolidate to single modern clusters.json-based system'
  });
}

// Check for missing geo coordinates
const hasCoordImplementation = coordFiles.length > 0;
if (!hasCoordImplementation) {
  recommendations.push({
    priority: 'HIGH',
    issue: 'No geo coordinates implementation found',
    action: 'Implement coordinate system for all suburbs'
  });
}

// Check for legacy files
if (legacySuburbFiles.length > 0) {
  recommendations.push({
    priority: 'LOW',
    issue: `${legacySuburbFiles.length} legacy suburb files found`,
    action: 'Archive or remove legacy files after confirming modern system works'
  });
}

recommendations.forEach((rec, index) => {
  console.log(`${index + 1}. [${rec.priority}] ${rec.issue}`);
  console.log(`   → ${rec.action}`);
});

ANALYSIS.recommendations = recommendations;

console.log('');

// 8. Generate detailed implementation plan
console.log('📋 IMPLEMENTATION PLAN');
console.log('======================');

const plan = [
  {
    phase: 'AUDIT',
    tasks: [
      'Verify all suburbs from clusters.json are being generated',
      'Identify and remove duplicate generation systems',
      'Document current geo coordinate implementation status'
    ]
  },
  {
    phase: 'COORDINATE_INTEGRATION',
    tasks: [
      'Implement coordinate data structure for all suburbs',
      'Create utility functions for geo calculations',
      'Add coordinate validation to build process'
    ]
  },
  {
    phase: 'OPTIMIZATION',
    tasks: [
      'Consolidate to single suburb generation system',
      'Remove legacy suburb files',
      'Implement geo-based features (distance, mapping, etc.)'
    ]
  }
];

plan.forEach(phase => {
  console.log(`${phase.phase}:`);
  phase.tasks.forEach(task => {
    console.log(`  • ${task}`);
  });
});

console.log('');

// 9. Save comprehensive report
const report = {
  timestamp: new Date().toISOString(),
  summary: {
    expectedSuburbs: ANALYSIS.totalSuburbs,
    builtSuburbs: builtSuburbs,
    status: builtSuburbs === ANALYSIS.totalSuburbs ? 'COMPLETE' : 'INCOMPLETE',
    generationSystems: generationMethods.length,
    geoFilesFound: geoFiles.length,
    recommendationsCount: recommendations.length
  },
  expectedSuburbs: ANALYSIS.expectedSuburbs,
  builtStructure: builtStructure,
  generationSystems: generationMethods,
  geoFiles: geoFiles.map(f => ({ ...f, content: 'truncated' })), // Don't include full content
  recommendations: recommendations,
  implementationPlan: plan
};

fs.mkdirSync('__reports', { recursive: true });
fs.writeFileSync('__reports/geo-suburbs-implementation-analysis.json', JSON.stringify(report, null, 2));

console.log('📊 ANALYSIS COMPLETE');
console.log('==================');
console.log(`Expected suburbs: ${ANALYSIS.totalSuburbs}`);
console.log(`Built suburbs: ${builtSuburbs}`);
console.log(`Status: ${builtSuburbs === ANALYSIS.totalSuburbs ? 'COMPLETE ✅' : 'INCOMPLETE ❌'}`);
console.log(`Generation systems: ${generationMethods.length}`);
console.log(`Recommendations: ${recommendations.length}`);
console.log('');
console.log('📋 Full report saved to: __reports/geo-suburbs-implementation-analysis.json');