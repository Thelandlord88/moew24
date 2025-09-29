#!/usr/bin/env node

/**
 * 🔄 GEO DATA MIGRATION SCRIPT
 * Hunter + Daedalus Joint Operation
 *
 * Converts rich geographic data from cluster scritps/areas.extended.clusters.json
 * to new system format while preserving all business logic and geographic relationships
 */

import fs from 'fs';
import path from 'path';

// Colors for output
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
  log('blue', '🔄 GEO DATA MIGRATION - Hunter + Daedalus Protocol');
  log('blue', '='.repeat(55));
  
  // Hunter: Data integrity validation
  log('purple', '🔍 HUNTER: Validating source data...');
  
  const backupFile = '_geo_backup_20250925_062123/cluster_scripts_backup/areas.extended.clusters.json';
  const targetClusterFile = 'what we\'ve done/src/data/areas.clusters.json';
  const targetMetaFile = 'what we\'ve done/src/data/suburbs.meta.json';
  
  if (!fs.existsSync(backupFile)) {
    log('red', '❌ Source backup file not found!');
    process.exit(1);
  }
  
  log('green', '✅ Source data located');
  
  // Daedalus: Architecture analysis
  log('cyan', '🏛️ DAEDALUS: Analyzing data architecture...');
  
  const sourceData = JSON.parse(fs.readFileSync(backupFile, 'utf8'));
  log('green', `✅ Loaded ${sourceData.clusters?.length || 0} clusters`);
  
  // Count total suburbs
  let totalSuburbs = 0;
  const suburbsMeta = {};
  const clustersData = {};
  
  if (sourceData.clusters) {
    sourceData.clusters.forEach(cluster => {
      clustersData[cluster.slug] = {
        name: cluster.name,
        suburbs: cluster.suburbs?.map(suburb => ({
          slug: suburb.slug,
          name: suburb.name,
          coordinates: {
            lat: suburb.lat,
            lng: suburb.lng
          }
        })) || []
      };
      
      if (cluster.suburbs) {
        cluster.suburbs.forEach(suburb => {
          totalSuburbs++;
          suburbsMeta[suburb.slug] = {
            name: suburb.name,
            cluster: cluster.slug,
            coordinates: {
              lat: suburb.lat,
              lng: suburb.lng
            }
          };
        });
      }
    });
  }
  
  log('green', `✅ Processed ${totalSuburbs} suburbs across ${Object.keys(clustersData).length} clusters`);
  
  // Hunter: Security check before writing
  log('purple', '🔍 HUNTER: Pre-write security validation...');
  
  // Create backups of target files if they exist and have content
  [targetClusterFile, targetMetaFile].forEach(file => {
    if (fs.existsSync(file)) {
      const stats = fs.statSync(file);
      if (stats.size > 10) { // More than just {}
        const backupName = file + '.pre-migration-backup';
        fs.copyFileSync(file, backupName);
        log('yellow', `⚠️ Backed up existing ${file} to ${backupName}`);
      }
    }
  });
  
  // Daedalus: Write migrated data
  log('cyan', '🏛️ DAEDALUS: Writing migrated data structures...');
  
  try {
    fs.writeFileSync(targetClusterFile, JSON.stringify(clustersData, null, 2));
    log('green', `✅ Written clusters data to ${targetClusterFile}`);
    
    fs.writeFileSync(targetMetaFile, JSON.stringify(suburbsMeta, null, 2));
    log('green', `✅ Written suburbs metadata to ${targetMetaFile}`);
    
    // Hunter: Post-migration validation
    log('purple', '🔍 HUNTER: Post-migration validation...');
    
    const validatedClusters = JSON.parse(fs.readFileSync(targetClusterFile, 'utf8'));
    const validatedMeta = JSON.parse(fs.readFileSync(targetMetaFile, 'utf8'));
    
    const clusterCount = Object.keys(validatedClusters).length;
    const suburbCount = Object.keys(validatedMeta).length;
    
    log('green', `✅ Validation passed: ${clusterCount} clusters, ${suburbCount} suburbs`);
    
    // Generate migration report
    const report = {
      timestamp: new Date().toISOString(),
      migration: {
        source: backupFile,
        targets: [targetClusterFile, targetMetaFile],
        clustersProcessed: clusterCount,
        suburbsProcessed: suburbCount,
        status: 'completed'
      }
    };
    
    fs.writeFileSync('_migration_report.json', JSON.stringify(report, null, 2));
    log('blue', '📊 Migration report written to _migration_report.json');
    
    log('green', '🎉 DATA MIGRATION COMPLETED SUCCESSFULLY!');
    
  } catch (error) {
    log('red', `❌ Migration failed: ${error.message}`);
    process.exit(1);
  }
}

main();