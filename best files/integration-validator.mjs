#!/usr/bin/env node

/**
 * 🔧 SYSTEM INTEGRATION VALIDATOR
 * Hunter + Daedalus Final Integration Test
 *
 * Tests compatibility between migrated data and existing Astro system
 */

import fs from 'fs';
import path from 'path';

const colors = {
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  purple: '\x1b[35m',
  cyan: '\x1b[36m',
  reset: '\x1b[0m'
};

function log(color, message) {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function main() {
  log('blue', '🔧 SYSTEM INTEGRATION VALIDATOR');
  log('blue', '='.repeat(35));
  
  log('purple', '🔍 HUNTER: System integrity checks...');
  
  // Check all critical files exist
  const criticalFiles = [
    'what we\'ve done/src/data/areas.clusters.json',
    'what we\'ve done/src/data/suburbs.meta.json', 
    'what we\'ve done/src/data/areas.adj.json',
    'daedalus.config.json'
  ];
  
  let allFilesExist = true;
  criticalFiles.forEach(file => {
    if (fs.existsSync(file)) {
      const stats = fs.statSync(file);
      log('green', `✅ ${file} (${stats.size} bytes)`);
    } else {
      log('red', `❌ Missing: ${file}`);
      allFilesExist = false;
    }
  });
  
  if (!allFilesExist) {
    log('red', '❌ Critical files missing - integration incomplete');
    process.exit(1);
  }
  
  log('cyan', '🏛️ DAEDALUS: Architecture compatibility analysis...');
  
  // Load and validate data structures
  const clustersData = JSON.parse(fs.readFileSync('what we\'ve done/src/data/areas.clusters.json', 'utf8'));
  const suburbsMeta = JSON.parse(fs.readFileSync('what we\'ve done/src/data/suburbs.meta.json', 'utf8'));
  const adjacencyData = JSON.parse(fs.readFileSync('what we\'ve done/src/data/areas.adj.json', 'utf8'));
  const daedalusConfig = JSON.parse(fs.readFileSync('daedalus.config.json', 'utf8'));
  
  const clusterCount = Object.keys(clustersData).length;
  const suburbCount = Object.keys(suburbsMeta).length;
  const adjacencyCount = Object.keys(adjacencyData).length;
  const serviceCount = daedalusConfig.services?.length || 0;
  
  log('green', `✅ Data structures loaded:`);
  log('cyan', `   • ${clusterCount} clusters`);
  log('cyan', `   • ${suburbCount} suburbs`);
  log('cyan', `   • ${adjacencyCount} adjacency relationships`);
  log('cyan', `   • ${serviceCount} services configured`);
  
  // Calculate theoretical page generation potential
  const theoreticalPages = suburbCount * serviceCount;
  log('blue', `📊 Theoretical page generation: ${theoreticalPages} pages`);
  
  // Hunter: Data consistency validation
  log('purple', '🔍 HUNTER: Cross-referential data validation...');
  
  let inconsistencies = 0;
  
  // Check that all suburbs in clusters exist in meta
  Object.values(clustersData).forEach(cluster => {
    cluster.suburbs?.forEach(suburb => {
      if (!suburbsMeta[suburb.slug]) {
        log('yellow', `⚠️ Suburb ${suburb.slug} in cluster but not in meta`);
        inconsistencies++;
      }
    });
  });
  
  // Check that all suburbs in meta belong to a cluster
  Object.keys(suburbsMeta).forEach(suburbSlug => {
    const suburb = suburbsMeta[suburbSlug];
    if (!clustersData[suburb.cluster]) {
      log('yellow', `⚠️ Suburb ${suburbSlug} references non-existent cluster ${suburb.cluster}`);
      inconsistencies++;
    }
  });
  
  if (inconsistencies === 0) {
    log('green', '✅ Data consistency validation passed');
  } else {
    log('yellow', `⚠️ Found ${inconsistencies} data inconsistencies`);
  }
  
  // Daedalus: System readiness assessment
  log('cyan', '🏛️ DAEDALUS: System readiness assessment...');
  
  const readinessChecks = {
    'Data Migration': clusterCount > 0 && suburbCount > 0,
    'Configuration Valid': daedalusConfig.name && daedalusConfig.services,
    'File Paths Correct': daedalusConfig.geo?.clustersFile && fs.existsSync(daedalusConfig.geo.clustersFile),
    'Geographic Coverage': suburbCount >= 300, // Brisbane metro area
    'Service Portfolio': serviceCount >= 4
  };
  
  let readyForProduction = true;
  Object.entries(readinessChecks).forEach(([check, passed]) => {
    if (passed) {
      log('green', `✅ ${check}`);
    } else {
      log('red', `❌ ${check}`);
      readyForProduction = false;
    }
  });
  
  // Final integration status
  log('blue', '\n📋 INTEGRATION STATUS REPORT:');
  
  if (readyForProduction && inconsistencies === 0) {
    log('green', '🎉 SYSTEM INTEGRATION SUCCESSFUL!');
    log('green', '✅ Ready for production deployment');
    log('cyan', `💡 Potential: ${theoreticalPages} geo-optimized pages`);
  } else if (inconsistencies > 0 && readyForProduction) {
    log('yellow', '⚠️ INTEGRATION COMPLETED WITH WARNINGS');
    log('yellow', '🔧 Minor data inconsistencies detected but system functional');
  } else {
    log('red', '❌ INTEGRATION INCOMPLETE');
    log('red', '🚫 Not ready for production deployment');
  }
  
  // Generate final integration report
  const integrationReport = {
    timestamp: new Date().toISOString(),
    status: readyForProduction && inconsistencies === 0 ? 'success' : 'warning',
    metrics: {
      clusters: clusterCount,
      suburbs: suburbCount,
      services: serviceCount,
      theoreticalPages: theoreticalPages,
      inconsistencies: inconsistencies
    },
    readinessChecks: readinessChecks
  };
  
  fs.writeFileSync('_integration_report.json', JSON.stringify(integrationReport, null, 2));
  log('blue', '📊 Integration report saved to _integration_report.json');
}

main();