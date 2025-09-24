#!/usr/bin/env node
/**
 * FINAL GEO IMPLEMENTATION REPORT
 * 
 * Complete analysis and recommendations for the geo system
 */

import fs from 'node:fs';

console.log('🌍 FINAL GEO IMPLEMENTATION REPORT');
console.log('==================================');
console.log('Generated:', new Date().toISOString());
console.log('');

// Read key data files
const clustersData = JSON.parse(fs.readFileSync('src/data/clusters.json', 'utf8'));
const coordsData = JSON.parse(fs.readFileSync('src/data/suburbs.coords.json', 'utf8'));

console.log('📊 SUBURBAN INFRASTRUCTURE ANALYSIS');
console.log('===================================');

let totalExpected = 0;
Object.entries(clustersData).forEach(([cluster, suburbs]) => {
  totalExpected += suburbs.length;
  console.log(`${cluster.toUpperCase().padEnd(10)} → ${suburbs.length.toString().padStart(3)} suburbs`);
});

console.log('─'.repeat(25));
console.log(`TOTAL       → ${totalExpected.toString().padStart(3)} suburbs`);
console.log('');

console.log('🗺️  GEO COORDINATES ANALYSIS');
console.log('============================');

const coordSuburbs = Object.keys(coordsData);
const hasCoords = coordSuburbs.length;
const allSuburbs = Object.values(clustersData).flat();

console.log(`Coordinates available: ${hasCoords} suburbs`);
console.log(`Expected suburbs: ${allSuburbs.length} suburbs`);
console.log(`Coverage: ${((hasCoords / allSuburbs.length) * 100).toFixed(1)}%`);

// Check which suburbs have coordinates
const missingCoords = allSuburbs.filter(suburb => !coordsData[suburb]);
const extraCoords = coordSuburbs.filter(suburb => !allSuburbs.includes(suburb));

if (missingCoords.length > 0) {
  console.log('');
  console.log(`⚠️  Missing coordinates for ${missingCoords.length} suburbs:`);
  missingCoords.slice(0, 10).forEach(suburb => console.log(`   - ${suburb}`));
  if (missingCoords.length > 10) {
    console.log(`   ... and ${missingCoords.length - 10} more`);
  }
}

if (extraCoords.length > 0) {
  console.log('');
  console.log(`📍 Extra coordinates for ${extraCoords.length} suburbs not in clusters:`);
  extraCoords.slice(0, 10).forEach(suburb => console.log(`   - ${suburb}`));
  if (extraCoords.length > 10) {
    console.log(`   ... and ${extraCoords.length - 10} more`);
  }
}

console.log('');

console.log('🏗️  BUILD OUTPUT VERIFICATION');
console.log('=============================');

// Count actual built pages (if dist exists)
let builtPages = 0;
if (fs.existsSync('dist/areas')) {
  function countPages(dir) {
    let count = 0;
    try {
      const items = fs.readdirSync(dir, { withFileTypes: true });
      items.forEach(item => {
        if (item.isDirectory()) {
          count += countPages(`${dir}/${item.name}`);
        } else if (item.name === 'index.html') {
          count++;
        }
      });
    } catch (err) {
      // Skip directories that can't be read
    }
    return count;
  }
  
  builtPages = countPages('dist/areas');
}

console.log(`Built pages: ${builtPages}`);
console.log(`Expected pages: ${totalExpected * 2} (2 per suburb)`);
console.log(`Status: ${builtPages === totalExpected * 2 ? '✅ CORRECT' : '⚠️  MISMATCH'}`);

console.log('');

console.log('🎯 CONTACT CARD REMOVAL STATUS');
console.log('==============================');

// Check if contact card still exists
let contactCardExists = false;
try {
  const contactSectionContent = fs.readFileSync('src/components/sections/ContactSection.astro', 'utf8');
  contactCardExists = contactSectionContent.includes('group w-full max-w-4xl grid grid-cols-1 md:grid-cols-[2fr,3fr]');
} catch (err) {
  // File doesn't exist or can't be read
}

console.log(`Contact card present: ${contactCardExists ? '⚠️  YES (needs removal)' : '✅ NO'}`);

if (contactCardExists) {
  console.log('Action required: Run node scripts/remove-contact-card.mjs');
}

console.log('');

console.log('📋 IMPLEMENTATION STATUS');
console.log('========================');

const status = {
  suburbsConfigured: '✅ COMPLETE',
  coordinatesAvailable: hasCoords === allSuburbs.length ? '✅ COMPLETE' : '⚠️  PARTIAL',
  pageGeneration: builtPages === totalExpected * 2 ? '✅ COMPLETE' : '⚠️  NEEDS_CHECK',
  contactCardRemoval: !contactCardExists ? '✅ COMPLETE' : '⚠️  PENDING',
  geoIntegration: '⚠️  PARTIAL (utilities present, integration needed)'
};

Object.entries(status).forEach(([component, status]) => {
  console.log(`${component.padEnd(20)} → ${status}`);
});

console.log('');

console.log('🚀 NEXT ACTIONS REQUIRED');
console.log('========================');

const actions = [];

if (contactCardExists) {
  actions.push({
    priority: 'HIGH',
    action: 'Remove contact card',
    command: 'node scripts/remove-contact-card.mjs'
  });
}

if (missingCoords.length > 0) {
  actions.push({
    priority: 'MEDIUM',
    action: `Add coordinates for ${missingCoords.length} missing suburbs`,
    command: 'Update src/data/suburbs.coords.json'
  });
}

actions.push({
  priority: 'MEDIUM',
  action: 'Integrate coordinates into page generation',
  command: 'Update getStaticPaths in suburb pages to include coordinates'
});

actions.push({
  priority: 'LOW',
  action: 'Implement geo-based features',
  command: 'Add distance calculations, maps, nearby suburbs, etc.'
});

if (actions.length > 0) {
  actions.forEach((action, index) => {
    console.log(`${index + 1}. [${action.priority}] ${action.action}`);
    console.log(`   Command: ${action.command}`);
  });
} else {
  console.log('✅ No immediate actions required');
}

console.log('');

console.log('💡 RECOMMENDATIONS');
console.log('==================');

console.log('1. IMMEDIATE (Contact Card):');
console.log('   • Run removal script to clean up UI');
console.log('');

console.log('2. SHORT TERM (Geo Integration):');
console.log('   • Pass coordinates to suburb pages in getStaticPaths');
console.log('   • Add coordinate validation to build process');
console.log('   • Implement nearby suburbs functionality');
console.log('');

console.log('3. LONG TERM (Geo Features):');
console.log('   • Add interactive maps');
console.log('   • Calculate service area coverage');
console.log('   • Implement distance-based routing');
console.log('   • Add geo-based SEO optimizations');

console.log('');

// Save comprehensive report
const report = {
  timestamp: new Date().toISOString(),
  summary: {
    totalSuburbs: totalExpected,
    coordinateCoverage: `${((hasCoords / allSuburbs.length) * 100).toFixed(1)}%`,
    builtPages: builtPages,
    expectedPages: totalExpected * 2,
    contactCardExists: contactCardExists,
    status: Object.entries(status).every(([k,v]) => v.includes('COMPLETE')) ? 'READY' : 'IN_PROGRESS'
  },
  clusters: Object.fromEntries(
    Object.entries(clustersData).map(([k,v]) => [k, v.length])
  ),
  coordinates: {
    available: hasCoords,
    missing: missingCoords.length,
    extra: extraCoords.length,
    coverage: ((hasCoords / allSuburbs.length) * 100).toFixed(1) + '%'
  },
  actions: actions,
  missingCoordinates: missingCoords,
  extraCoordinates: extraCoords
};

fs.mkdirSync('__reports', { recursive: true });
fs.writeFileSync('__reports/final-geo-implementation-report.json', JSON.stringify(report, null, 2));

console.log('📊 ANALYSIS COMPLETE');
console.log('===================');
console.log(`Overall Status: ${report.summary.status}`);
console.log(`Coordinate Coverage: ${report.coordinates.coverage}`);
console.log(`Actions Required: ${actions.length}`);
console.log('');
console.log('📋 Full report saved to: __reports/final-geo-implementation-report.json');