/**
 * NEXUS + Hunter Integration Audit Script
 * 
 * Demonstrates the combined power of trait composition, runtime enhancement,
 * and forensic evidence verification for comprehensive component audit.
 */

import path from 'node:path';
import { fileURLToPath } from 'node:url';
import fs from 'node:fs/promises';
import chalk from 'chalk';

// Direct TS import paths since we're running with tsx
import { nexus } from './src/components/header/NEXUS.engine.ts';
import { HunterAuditAgent } from './src/components/header/Hunter.auditAgent.ts';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function runComponentAudit() {
  console.log(chalk.blue('🧠 NEXUS + Hunter Integrated Audit System'));
  console.log(chalk.blue('=========================================\n'));

  // Create target component scope
  const componentPath = path.join(__dirname, 'src/components/header/Header.astro');
  const testPath = path.join(__dirname, 'src/components/header/Header.test.ts');
  const configPath = path.join(__dirname, 'src/components/header/theme.css');
  
  // Check if files exist first
  console.log(chalk.gray('📂 Checking audit scope files...'));
  try {
    await fs.access(componentPath);
    await fs.access(testPath);
    await fs.access(configPath);
  } catch (err) {
    console.error(chalk.red('❌ File access error:'), err.message);
    process.exit(1);
  }

  // Audit scope with files for forensic analysis
  const auditScope = {
    codeFiles: [componentPath],
    testFiles: [testPath],
    configFiles: [configPath],
    dependencies: [],
    buildOutputs: []
  };

  try {
    // Create a hunter audit agent with the NEXUS integration
    const hunterAgent = new HunterAuditAgent(nexus);
    console.log(chalk.gray('📊 Creating forensic audit agent...'));
    
    // Execute comprehensive audit (combines policy + NEXUS enhancement)
    console.log(chalk.gray('🔍 Executing forensic audit with trait composition...'));
    const auditResults = await hunterAgent.executeComprehensiveAudit(auditScope);
    
    // Show key findings
    printResults(auditResults);
    
  } catch (error) {
    console.error(chalk.red('❌ Audit failed:'), error);
    process.exit(1);
  }
}

function printResults(results) {
  console.log(chalk.green('\n✅ NEXUS + Hunter Audit Complete'));
  console.log(chalk.green('===============================\n'));
  
  // Runtime source (NEXUS enhanced vs local)
  console.log(chalk.yellow('🔌 Runtime Source:'), chalk.cyan(results.runtimeSource));
  
  // Traits used in analysis
  console.log(chalk.yellow('🧠 Traits Composition:'));
  if (results.traitsUsed && results.traitsUsed.length) {
    results.traitsUsed.forEach(trait => {
      console.log(chalk.cyan(`  • ${trait}`));
    });
  } else {
    console.log(chalk.gray('  No specific traits reported'));
  }

  // Production readiness assessment
  console.log(chalk.yellow('\n🚀 Production Readiness:'), 
    results.productionReady ? chalk.green('✅ APPROVED') : chalk.red('❌ NOT APPROVED'));
  
  // Summary of findings by severity
  console.log(chalk.yellow('\n📊 Evidence Summary:'));
  console.log(chalk.red(`  • Critical: ${results.summary.critical}`));
  console.log(chalk.magenta(`  • High: ${results.summary.high}`));
  console.log(chalk.yellow(`  • Medium: ${results.summary.medium}`));
  console.log(chalk.blue(`  • Low: ${results.summary.low}`));

  // Sample findings (first 2)
  if (results.findings && results.findings.length) {
    console.log(chalk.yellow('\n🔍 Sample Evidence:'));
    results.findings.slice(0, 2).forEach((finding, i) => {
      console.log(chalk.white(`  [${finding.severity.toUpperCase()}] ${finding.description}`));
      if (finding.evidence && finding.evidence.length) {
        console.log(chalk.gray(`    Evidence: ${finding.evidence[0]}`));
      }
      console.log(chalk.gray(`    Impact: ${finding.impact}`));
      console.log('');
    });
    console.log(chalk.gray(`  ... and ${results.findings.length - 2} more findings`));
  }
  
  // NEXUS enhanced insights
  if (results.enhancedInsights) {
    console.log(chalk.yellow('\n⚡ NEXUS Enhanced Insight:'));
    console.log(chalk.gray(`  ${results.enhancedInsights.slice(0, 150)}...`));
  }
  
  // Production recommendations
  if (results.recommendations && results.recommendations.length) {
    console.log(chalk.yellow('\n🛠️ Top Recommendations:'));
    results.recommendations.slice(0, 3).forEach(rec => {
      console.log(chalk.white(`  • ${rec}`));
    });
  }
}

// Execute audit
runComponentAudit();
