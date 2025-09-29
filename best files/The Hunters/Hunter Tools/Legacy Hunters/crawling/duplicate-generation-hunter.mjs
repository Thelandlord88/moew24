#!/usr/bin/env node
/**
 * Duplicate Generation Hunter - Find why suburbs are built twice
 * 
 * This hunter will:
 * 1. Analyze the exact build output structure
 * 2. Identify duplicate URL patterns
 * 3. Find which pages are generating the same suburbs
 * 4. Recommend fixes for the duplication
 */

import fs from 'node:fs';
import path from 'node:path';

console.log('🔍 DUPLICATE GENERATION HUNTER');
console.log('==============================');
console.log('');

const ANALYSIS = {
  urlPatterns: {},
  duplicates: [],
  pageGenerators: [],
  recommendations: []
};

// 1. Analyze exact build structure
console.log('📁 ANALYZING BUILD STRUCTURE');
console.log('============================');

const distDir = 'dist';
const allPages = [];

function scanBuildOutput(dir, basePath = '') {
  if (!fs.existsSync(dir)) return;
  
  const items = fs.readdirSync(dir, { withFileTypes: true });
  
  for (const item of items) {
    const fullPath = path.join(dir, item.name);
    const urlPath = basePath + '/' + item.name;
    
    if (item.isDirectory()) {
      scanBuildOutput(fullPath, urlPath);
    } else if (item.name === 'index.html') {
      const pageUrl = basePath || '/';
      allPages.push({
        url: pageUrl,
        path: fullPath,
        isSuburbPage: isSuburbPage(pageUrl)
      });
    }
  }
}

function isSuburbPage(url) {
  // Check if URL matches suburb page patterns
  const patterns = [
    /^\/areas\/[^\/]+\/[^\/]+\/?$/,           // /areas/cluster/suburb/
    /^\/areas\/[^\/]+\/[^\/]+\/bond-cleaning\/?$/,  // /areas/cluster/suburb/bond-cleaning/
    /^\/bond-cleaning\/[^\/]+\/?$/,          // /bond-cleaning/suburb/
    /^\/services\/[^\/]+\/[^\/]+\/?$/        // /services/service/suburb/
  ];
  
  return patterns.some(pattern => pattern.test(url));
}

if (fs.existsSync(distDir)) {
  scanBuildOutput(distDir);
  
  console.log(`📊 Total pages found: ${allPages.length}`);
  
  const suburbPages = allPages.filter(p => p.isSuburbPage);
  console.log(`🏘️  Suburb pages: ${suburbPages.length}`);
  
  // Group by URL patterns
  const urlPatterns = {};
  suburbPages.forEach(page => {
    const pattern = categorizeUrlPattern(page.url);
    if (!urlPatterns[pattern]) urlPatterns[pattern] = [];
    urlPatterns[pattern].push(page);
  });
  
  console.log('');
  console.log('📋 SUBURB PAGES BY PATTERN:');
  Object.entries(urlPatterns).forEach(([pattern, pages]) => {
    console.log(`  ${pattern.padEnd(40)} → ${pages.length.toString().padStart(3)} pages`);
  });
  
  ANALYSIS.urlPatterns = urlPatterns;
} else {
  console.log('❌ No dist directory found');
}

function categorizeUrlPattern(url) {
  if (url.match(/^\/areas\/[^\/]+\/[^\/]+\/bond-cleaning\/?$/)) {
    return 'areas/cluster/suburb/bond-cleaning';
  }
  if (url.match(/^\/areas\/[^\/]+\/[^\/]+\/?$/)) {
    return 'areas/cluster/suburb';
  }
  if (url.match(/^\/bond-cleaning\/[^\/]+\/?$/)) {
    return 'bond-cleaning/suburb';
  }
  if (url.match(/^\/services\/[^\/]+\/[^\/]+\/?$/)) {
    return 'services/service/suburb';
  }
  return 'other';
}

console.log('');

// 2. Find which Astro files generate these pages
console.log('🔍 ANALYZING PAGE GENERATORS');
console.log('============================');

const pageFiles = [];

function scanForPageGenerators(dir) {
  if (!fs.existsSync(dir)) return;
  
  const items = fs.readdirSync(dir, { withFileTypes: true });
  
  for (const item of items) {
    const fullPath = path.join(dir, item.name);
    
    if (item.isDirectory()) {
      scanForPageGenerators(fullPath);
    } else if (item.name.endsWith('.astro')) {
      const content = fs.readFileSync(fullPath, 'utf8');
      
      if (content.includes('getStaticPaths')) {
        const urlPattern = getUrlPatternFromFile(fullPath);
        pageFiles.push({
          file: fullPath,
          urlPattern: urlPattern,
          hasSuburbLogic: content.includes('suburb'),
          hasClusterLogic: content.includes('cluster'),
          hasGetStaticPaths: true
        });
      }
    }
  }
}

function getUrlPatternFromFile(filePath) {
  // Convert file path to URL pattern
  let urlPattern = filePath
    .replace('src/pages', '')
    .replace('.astro', '')
    .replace(/\[([^\]]+)\]/g, ':$1');
  
  if (urlPattern.endsWith('/index')) {
    urlPattern = urlPattern.replace('/index', '');
  }
  
  return urlPattern || '/';
}

scanForPageGenerators('src/pages');

console.log('📄 PAGE GENERATOR FILES:');
pageFiles.forEach(file => {
  console.log(`  ${file.urlPattern.padEnd(40)} → ${file.file}`);
  console.log(`     Suburbs: ${file.hasSuburbLogic ? '✅' : '❌'} | Clusters: ${file.hasClusterLogic ? '✅' : '❌'}`);
});

ANALYSIS.pageGenerators = pageFiles;

console.log('');

// 3. Check for duplicate patterns
console.log('⚠️  CHECKING FOR DUPLICATE PATTERNS');
console.log('===================================');

const potentialDuplicates = [];

// Check if we have both old and new URL structures
const hasOldBondCleaning = ANALYSIS.urlPatterns['bond-cleaning/suburb'] && 
                          ANALYSIS.urlPatterns['bond-cleaning/suburb'].length > 0;
const hasNewBondCleaning = ANALYSIS.urlPatterns['areas/cluster/suburb/bond-cleaning'] && 
                          ANALYSIS.urlPatterns['areas/cluster/suburb/bond-cleaning'].length > 0;

if (hasOldBondCleaning && hasNewBondCleaning) {
  potentialDuplicates.push({
    issue: 'Duplicate bond-cleaning URLs',
    oldPattern: 'bond-cleaning/suburb',
    newPattern: 'areas/cluster/suburb/bond-cleaning',
    oldCount: ANALYSIS.urlPatterns['bond-cleaning/suburb'].length,
    newCount: ANALYSIS.urlPatterns['areas/cluster/suburb/bond-cleaning'].length
  });
}

// Check for other service duplicates
const hasOldServices = ANALYSIS.urlPatterns['services/service/suburb'] && 
                      ANALYSIS.urlPatterns['services/service/suburb'].length > 0;
const hasNewServices = ANALYSIS.urlPatterns['areas/cluster/suburb'] && 
                      ANALYSIS.urlPatterns['areas/cluster/suburb'].length > 0;

if (hasOldServices && hasNewServices) {
  potentialDuplicates.push({
    issue: 'Duplicate service URLs', 
    oldPattern: 'services/service/suburb',
    newPattern: 'areas/cluster/suburb',
    oldCount: ANALYSIS.urlPatterns['services/service/suburb'].length,
    newCount: ANALYSIS.urlPatterns['areas/cluster/suburb'].length
  });
}

if (potentialDuplicates.length > 0) {
  console.log('🚨 DUPLICATE PATTERNS FOUND:');
  potentialDuplicates.forEach((dup, index) => {
    console.log(`${index + 1}. ${dup.issue}`);
    console.log(`   Old: ${dup.oldPattern} (${dup.oldCount} pages)`);
    console.log(`   New: ${dup.newPattern} (${dup.newCount} pages)`);
  });
} else {
  console.log('✅ No obvious duplicate patterns found');
}

ANALYSIS.duplicates = potentialDuplicates;

console.log('');

// 4. Check for legacy page files
console.log('🗂️  CHECKING FOR LEGACY PAGE FILES');
console.log('==================================');

const legacyFiles = [];
const modernFiles = [];

pageFiles.forEach(file => {
  if (file.urlPattern.includes('/bond-cleaning/:suburb') || 
      file.urlPattern.includes('/services/')) {
    legacyFiles.push(file);
  } else if (file.urlPattern.includes('/areas/')) {
    modernFiles.push(file);
  }
});

console.log('📄 LEGACY PAGE FILES:');
legacyFiles.forEach(file => {
  console.log(`  ${file.file}`);
  console.log(`    Pattern: ${file.urlPattern}`);
});

console.log('');
console.log('📄 MODERN PAGE FILES:');
modernFiles.forEach(file => {
  console.log(`  ${file.file}`);
  console.log(`    Pattern: ${file.urlPattern}`);
});

console.log('');

// 5. Generate specific recommendations
console.log('💡 SPECIFIC RECOMMENDATIONS');
console.log('===========================');

const recommendations = [];

if (potentialDuplicates.length > 0) {
  recommendations.push({
    priority: 'HIGH',
    action: 'Remove duplicate page generation',
    details: 'Delete legacy page files that generate the same content as new files',
    files: legacyFiles.map(f => f.file)
  });
}

if (legacyFiles.length > 0) {
  recommendations.push({
    priority: 'MEDIUM', 
    action: 'Archive legacy page structure',
    details: 'Move old page files to archive or delete them',
    files: legacyFiles.map(f => f.file)
  });
}

const expectedSuburbs = 346;
const actualSuburbs = allPages.filter(p => p.isSuburbPage).length;
if (actualSuburbs !== expectedSuburbs) {
  recommendations.push({
    priority: 'HIGH',
    action: 'Fix suburb count mismatch',
    details: `Expected ${expectedSuburbs} suburb pages, found ${actualSuburbs}`,
    ratio: `${actualSuburbs / expectedSuburbs}x`
  });
}

recommendations.forEach((rec, index) => {
  console.log(`${index + 1}. [${rec.priority}] ${rec.action}`);
  console.log(`   ${rec.details}`);
  if (rec.files) {
    console.log(`   Files: ${rec.files.length} files`);
    rec.files.forEach(f => console.log(`     - ${f}`));
  }
  if (rec.ratio) {
    console.log(`   Ratio: ${rec.ratio}`);
  }
});

ANALYSIS.recommendations = recommendations;

console.log('');

// 6. Create removal script
console.log('🛠️  GENERATING REMOVAL SCRIPT');
console.log('=============================');

if (legacyFiles.length > 0) {
  const removalScript = legacyFiles.map(file => `rm "${file.file}"`).join('\n');
  
  fs.writeFileSync('scripts/remove-duplicate-pages.sh', `#!/bin/bash
# Remove duplicate/legacy page files
# Generated by duplicate-generation-hunter.mjs

echo "🗑️  Removing duplicate page files..."

${removalScript}

echo "✅ Duplicate page files removed"
echo "🔄 Run 'npm run build' to verify the fix"
`);
  
  fs.chmodSync('scripts/remove-duplicate-pages.sh', '755');
  
  console.log('📜 Created removal script: scripts/remove-duplicate-pages.sh');
  console.log('   Run: bash scripts/remove-duplicate-pages.sh');
} else {
  console.log('✅ No legacy files to remove');
}

console.log('');

// 7. Save analysis
const report = {
  timestamp: new Date().toISOString(),
  summary: {
    totalPages: allPages.length,
    suburbPages: allPages.filter(p => p.isSuburbPage).length,
    expectedSuburbs: 346,
    duplicatesFound: potentialDuplicates.length,
    legacyFiles: legacyFiles.length,
    modernFiles: modernFiles.length
  },
  urlPatterns: Object.fromEntries(
    Object.entries(ANALYSIS.urlPatterns).map(([key, pages]) => [key, pages.length])
  ),
  duplicates: potentialDuplicates,
  pageGenerators: pageFiles,
  recommendations: recommendations
};

fs.mkdirSync('__reports', { recursive: true });
fs.writeFileSync('__reports/duplicate-generation-analysis.json', JSON.stringify(report, null, 2));

console.log('📊 ANALYSIS SUMMARY');
console.log('==================');
console.log(`Total pages: ${allPages.length}`);
console.log(`Suburb pages: ${allPages.filter(p => p.isSuburbPage).length}`);
console.log(`Expected: 346 suburbs`);
console.log(`Duplicates: ${potentialDuplicates.length}`);
console.log(`Legacy files: ${legacyFiles.length}`);
console.log(`Recommendations: ${recommendations.length}`);
console.log('');
console.log('📋 Full report saved to: __reports/duplicate-generation-analysis.json');