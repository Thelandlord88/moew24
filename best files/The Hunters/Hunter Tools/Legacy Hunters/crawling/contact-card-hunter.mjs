#!/usr/bin/env node
/**
 * Contact Card Hunter - Find and Remove Specific Contact Card
 * 
 * This hunter will:
 * 1. Search for the specific contact card HTML structure
 * 2. Identify which files contain it
 * 3. Create removal scripts
 * 4. Generate a report
 */

import fs from 'node:fs';
import path from 'node:path';

console.log('🎯 CONTACT CARD HUNTER');
console.log('======================');
console.log('');

const ANALYSIS = {
  searchPattern: 'group w-full max-w-4xl grid grid-cols-1 md:grid-cols-[2fr,3fr] bg-white rounded-2xl',
  filesFound: [],
  occurrences: [],
  removalPlan: []
};

// The specific pattern to search for
const CONTACT_CARD_PATTERN = /class="group w-full max-w-4xl grid grid-cols-1 md:grid-cols-\[2fr,3fr\] bg-white rounded-2xl shadow-lg border border-slate-200 overflow-hidden/;

console.log('🔍 SEARCHING FOR CONTACT CARD PATTERN');
console.log('====================================');
console.log('Pattern: class="group w-full max-w-4xl grid grid-cols-1 md:grid-cols-[2fr,3fr]..."');
console.log('');

// 1. Search through all relevant files
function searchForContactCard(dir, basePath = '') {
  if (!fs.existsSync(dir)) return;
  
  const items = fs.readdirSync(dir, { withFileTypes: true });
  
  for (const item of items) {
    const fullPath = path.join(dir, item.name);
    const relativePath = basePath + '/' + item.name;
    
    if (item.isDirectory()) {
      // Skip node_modules, .git, dist, etc.
      if (!item.name.startsWith('.') && 
          !['node_modules', 'dist', '__tmp', '__archive'].includes(item.name)) {
        searchForContactCard(fullPath, relativePath);
      }
    } else if (item.name.endsWith('.astro') || 
               item.name.endsWith('.html') || 
               item.name.endsWith('.jsx') || 
               item.name.endsWith('.tsx') || 
               item.name.endsWith('.vue')) {
      
      try {
        const content = fs.readFileSync(fullPath, 'utf8');
        
        // Check for the specific pattern
        if (CONTACT_CARD_PATTERN.test(content)) {
          ANALYSIS.filesFound.push(fullPath);
          
          // Find all occurrences and their context
          const lines = content.split('\n');
          lines.forEach((line, index) => {
            if (CONTACT_CARD_PATTERN.test(line)) {
              ANALYSIS.occurrences.push({
                file: fullPath,
                lineNumber: index + 1,
                line: line.trim(),
                context: getContext(lines, index, 5)
              });
            }
          });
        }
        
        // Also check for other contact card indicators
        const indicators = [
          'One N Done</h3>',
          'Bond Cleaning Experts</p>',
          '0405 779 420',
          'info@onendonebondclean.com.au',
          'OneNDoneBondClean'
        ];
        
        let hasMultipleIndicators = 0;
        indicators.forEach(indicator => {
          if (content.includes(indicator)) hasMultipleIndicators++;
        });
        
        if (hasMultipleIndicators >= 3 && !ANALYSIS.filesFound.includes(fullPath)) {
          console.log(`📋 Potential contact card in: ${fullPath} (${hasMultipleIndicators}/5 indicators)`);
        }
        
      } catch (err) {
        // Skip files that can't be read
      }
    }
  }
}

function getContext(lines, lineIndex, contextSize) {
  const start = Math.max(0, lineIndex - contextSize);
  const end = Math.min(lines.length, lineIndex + contextSize + 1);
  
  return {
    start: start + 1,
    end: end,
    lines: lines.slice(start, end)
  };
}

// Search in key directories
const searchDirs = ['src', 'public'];
searchDirs.forEach(dir => {
  console.log(`Searching in ${dir}/...`);
  searchForContactCard(dir);
});

console.log('');

// 2. Report findings
console.log('📊 SEARCH RESULTS');
console.log('=================');

if (ANALYSIS.filesFound.length > 0) {
  console.log(`🎯 Found contact card in ${ANALYSIS.filesFound.length} file(s):`);
  
  ANALYSIS.filesFound.forEach(file => {
    console.log(`  📄 ${file}`);
  });
  
  console.log('');
  console.log('📍 OCCURRENCE DETAILS:');
  
  ANALYSIS.occurrences.forEach((occurrence, index) => {
    console.log(`${index + 1}. File: ${occurrence.file}`);
    console.log(`   Line: ${occurrence.lineNumber}`);
    console.log(`   Context (lines ${occurrence.context.start}-${occurrence.context.end}):`);
    occurrence.context.lines.forEach((line, idx) => {
      const lineNum = occurrence.context.start + idx;
      const marker = lineNum === occurrence.lineNumber ? '👉' : '  ';
      console.log(`   ${marker} ${lineNum.toString().padStart(3)}: ${line}`);
    });
    console.log('');
  });
} else {
  console.log('✅ No contact card found with the exact pattern');
}

console.log('');

// 3. Create removal plan
console.log('🛠️  CREATING REMOVAL PLAN');
console.log('=========================');

if (ANALYSIS.occurrences.length > 0) {
  ANALYSIS.occurrences.forEach((occurrence, index) => {
    const removalPlan = {
      file: occurrence.file,
      action: 'Remove contact card HTML block',
      lineNumber: occurrence.lineNumber,
      strategy: 'Find opening <article> and remove until closing </article>'
    };
    
    ANALYSIS.removalPlan.push(removalPlan);
    
    console.log(`${index + 1}. ${occurrence.file}`);
    console.log(`   Action: ${removalPlan.action}`);
    console.log(`   Line: ${occurrence.lineNumber}`);
    console.log(`   Strategy: ${removalPlan.strategy}`);
  });
  
  // Create removal script
  console.log('');
  console.log('📜 CREATING REMOVAL SCRIPT');
  
  const script = `#!/usr/bin/env node
/**
 * Contact Card Remover - Auto-generated removal script
 */

import fs from 'node:fs';

console.log('🗑️  Removing contact card from files...');

${ANALYSIS.occurrences.map((occ, index) => `
// Remove from: ${occ.file}
const content${index} = fs.readFileSync('${occ.file}', 'utf8');
const updated${index} = removeContactCard(content${index});
fs.writeFileSync('${occ.file}', updated${index});
console.log('✅ Removed contact card from ${occ.file}');
`).join('')}

function removeContactCard(content) {
  // Remove the specific contact card pattern
  const pattern = /<article class="group w-full max-w-4xl[^>]*>.*?<\\/article>/gms;
  return content.replace(pattern, '<!-- Contact card removed -->');
}

console.log('🎉 Contact card removal complete!');
`;
  
  fs.writeFileSync('scripts/remove-contact-card.mjs', script);
  fs.chmodSync('scripts/remove-contact-card.mjs', '755');
  
  console.log('📜 Created removal script: scripts/remove-contact-card.mjs');
  console.log('   Run: node scripts/remove-contact-card.mjs');
  
} else {
  console.log('✅ No removal needed - contact card not found');
}

console.log('');

// 4. Save analysis report
const report = {
  timestamp: new Date().toISOString(),
  searchPattern: ANALYSIS.searchPattern,
  summary: {
    filesSearched: 'src/, public/',
    filesFound: ANALYSIS.filesFound.length,
    occurrences: ANALYSIS.occurrences.length,
    removalPlanCreated: ANALYSIS.removalPlan.length > 0
  },
  filesFound: ANALYSIS.filesFound,
  occurrences: ANALYSIS.occurrences.map(occ => ({
    file: occ.file,
    lineNumber: occ.lineNumber,
    line: occ.line
  })),
  removalPlan: ANALYSIS.removalPlan
};

fs.mkdirSync('__reports', { recursive: true });
fs.writeFileSync('__reports/contact-card-analysis.json', JSON.stringify(report, null, 2));

console.log('📊 ANALYSIS SUMMARY');
console.log('==================');
console.log(`Files found: ${ANALYSIS.filesFound.length}`);
console.log(`Occurrences: ${ANALYSIS.occurrences.length}`);
console.log(`Removal plan: ${ANALYSIS.removalPlan.length > 0 ? 'Created' : 'Not needed'}`);
console.log('');
console.log('📋 Full report saved to: __reports/contact-card-analysis.json');