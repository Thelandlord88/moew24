#!/usr/bin/env node

// scripts/migrate-content-templates.mjs
/**
 * Content Migration Script
 * Migrates hardcoded suburb references to dynamic templates
 */

import { readFileSync, writeFileSync, readdirSync, existsSync } from 'node:fs';
import { join, extname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = join(__filename, '..');

const ROOT = join(__dirname, '..');
const SRC_DIR = join(ROOT, 'src');

// Import SuburbProvider for dynamic data
import { suburbProvider } from '../src/lib/suburbProvider.js';

// Services to process
const SERVICES = ['bond-cleaning', 'spring-cleaning', 'bathroom-deep-clean'];

// Migration patterns
const MIGRATION_PATTERNS = {
    // FAQ answers
    faqAnswers: {
        pattern: /Most smaller ([A-Z][a-z\s]+) (bond cleaning|spring cleaning|bathroom deep cleaning) jobs take [\d–-]+ hours[^.]*\./gi,
        replacement: (match, suburbName, serviceName) => {
            const serviceSlug = serviceName.toLowerCase().replace(/\s+/g, '-');
            const suburbSlug = suburbName.toLowerCase().replace(/\s+/g, '-');
            return `{{faqAnswer:${serviceSlug}:${suburbSlug}}}`;
        }
    },
    
    // Card titles
    cardTitles: {
        pattern: /(Bond Cleaning|Spring Cleaning|Bathroom Deep Cleaning) in ([A-Z][a-z\s]+)/g,
        replacement: (match, serviceName, suburbName) => {
            const serviceSlug = serviceName.toLowerCase().replace(/\s+/g, '-');
            const suburbSlug = suburbName.toLowerCase().replace(/\s+/g, '-');
            return `{{cardTitle:${serviceSlug}:${suburbSlug}}}`;
        }
    },
    
    // Meta descriptions
    metaDescriptions: {
        pattern: /Professional (bond cleaning|spring cleaning|bathroom deep cleaning) services in ([A-Z][a-z\s]+)\.[^.]*\./g,
        replacement: (match, serviceName, suburbName) => {
            const serviceSlug = serviceName.toLowerCase().replace(/\s+/g, '-');
            const suburbSlug = suburbName.toLowerCase().replace(/\s+/g, '-');
            return `{{metaDescription:${serviceSlug}:${suburbSlug}}}`;
        }
    },
    
    // Page titles
    pageTitles: {
        pattern: /(Bond Cleaning|Spring Cleaning|Bathroom Deep Cleaning) in ([A-Z][a-z\s]+) \| [^|]+/g,
        replacement: (match, serviceName, suburbName) => {
            const serviceSlug = serviceName.toLowerCase().replace(/\s+/g, '-');
            const suburbSlug = suburbName.toLowerCase().replace(/\s+/g, '-');
            return `{{pageTitle:${serviceSlug}:${suburbSlug}}}`;
        }
    }
};

// Specific suburb name mappings for better recognition
const SUBURB_MAPPINGS = {
    'Redbank Plains': 'redbank-plains',
    'St Lucia': 'st-lucia',
    'Mount Ommaney': 'mount-ommaney',
    'Eight Mile Plains': 'eight-mile-plains'
};

async function migrateContentTemplates() {
    console.log('🔄 Migrating hardcoded content to dynamic templates...');
    
    // Get all suburbs for validation
    const allSuburbs = await suburbProvider.loadSuburbs();
    console.log(`   Found ${allSuburbs.length} suburbs in data`);
    
    let filesProcessed = 0;
    let totalReplacements = 0;
    let skippedFiles = 0;
    
    // Process all content files
    const contentFiles = await findContentFiles(SRC_DIR);
    console.log(`   Found ${contentFiles.length} files to process`);
    
    const migrationReport = {
        filesProcessed: [],
        replacements: {},
        errors: [],
        skipped: []
    };
    
    for (const filePath of contentFiles) {
        try {
            let content = readFileSync(filePath, 'utf-8');
            const originalContent = content;
            const relativePath = relative(SRC_DIR, filePath);
            
            // Skip files that already use templates or are auto-generated
            if (shouldSkipFile(content, relativePath)) {
                skippedFiles++;
                migrationReport.skipped.push({
                    file: relativePath,
                    reason: 'Already contains templates or is auto-generated'
                });
                continue;
            }
            
            let fileReplacements = 0;
            
            // Apply each migration pattern
            for (const [patternName, config] of Object.entries(MIGRATION_PATTERNS)) {
                const matches = Array.from(content.matchAll(config.pattern));
                
                for (const match of matches) {
                    const replacement = config.replacement(match[0], match[1], match[2]);
                    
                    // Validate that the suburb exists in our data
                    const suburbSlug = replacement.match(/:([^}]+)\}\}$/)?.[1];
                    if (suburbSlug && !allSuburbs.includes(suburbSlug)) {
                        console.warn(`   ⚠️  Unknown suburb: ${suburbSlug} in ${relativePath}`);
                        continue;
                    }
                    
                    content = content.replace(match[0], replacement);
                    fileReplacements++;
                    totalReplacements++;
                    
                    if (!migrationReport.replacements[patternName]) {
                        migrationReport.replacements[patternName] = 0;
                    }
                    migrationReport.replacements[patternName]++;
                }
            }
            
            // Write changes if any replacements were made
            if (content !== originalContent) {
                // Create backup
                const backupPath = `${filePath}.backup.${Date.now()}`;
                writeFileSync(backupPath, originalContent);
                
                writeFileSync(filePath, content);
                filesProcessed++;
                
                migrationReport.filesProcessed.push({
                    file: relativePath,
                    replacements: fileReplacements,
                    backup: relative(ROOT, backupPath)
                });
                
                console.log(`   ✅ Updated: ${relativePath} (${fileReplacements} replacements)`);
            }
            
        } catch (error) {
            const relativePath = relative(SRC_DIR, filePath);
            migrationReport.errors.push({
                file: relativePath,
                error: error.message
            });
            console.error(`   ❌ Error processing ${relativePath}:`, error.message);
        }
    }
    
    // Generate migration report
    const reportPath = join(ROOT, '__reports', 'content-migration-report.json');
    await ensureDirectoryExists(join(ROOT, '__reports'));
    writeFileSync(reportPath, JSON.stringify(migrationReport, null, 2));
    
    console.log(`\n✅ Migration complete!`);
    console.log(`   Files processed: ${filesProcessed}`);
    console.log(`   Files skipped: ${skippedFiles}`);
    console.log(`   Total replacements: ${totalReplacements}`);
    console.log(`   Report saved: ${relative(ROOT, reportPath)}`);
    
    // Show replacement breakdown
    if (Object.keys(migrationReport.replacements).length > 0) {
        console.log('\n📊 Replacement breakdown:');
        for (const [type, count] of Object.entries(migrationReport.replacements)) {
            console.log(`   ${type}: ${count} replacements`);
        }
    }
    
    return migrationReport;
}

function shouldSkipFile(content, filePath) {
    // Skip files that already contain template syntax
    if (content.includes('{{') && content.includes('}}')) {
        return true;
    }
    
    // Skip files that import suburbProvider (likely already migrated)
    if (content.includes('suburbProvider') || content.includes('astroPropsGenerator')) {
        return true;
    }
    
    // Skip specific directories and file types
    const skipPatterns = [
        /node_modules/,
        /\.git/,
        /dist/,
        /__reports/,
        /scripts/,
        /\.backup\./,
        /demo-/,
        /test/,
        /spec/
    ];
    
    return skipPatterns.some(pattern => pattern.test(filePath));
}

async function findContentFiles(dir) {
    let files = [];
    
    if (!existsSync(dir)) {
        return files;
    }
    
    const items = readdirSync(dir, { withFileTypes: true });
    
    for (const item of items) {
        const fullPath = join(dir, item.name);
        
        if (item.isDirectory()) {
            // Skip certain directories
            if (!['node_modules', 'dist', '.git', '.astro'].includes(item.name)) {
                files = files.concat(await findContentFiles(fullPath));
            }
        } else if (['.astro', '.js', '.ts', '.json', '.md', '.mdx'].includes(extname(item.name))) {
            files.push(fullPath);
        }
    }
    
    return files;
}

async function ensureDirectoryExists(dir) {
    try {
        await import('node:fs/promises').then(fs => fs.mkdir(dir, { recursive: true }));
    } catch (error) {
        // Directory might already exist
    }
}

async function validateMigration() {
    console.log('🔍 Validating migration...');
    
    const contentFiles = await findContentFiles(SRC_DIR);
    let hardcodedCount = 0;
    let templateCount = 0;
    let filesWithIssues = [];
    
    const problemPatterns = [
        /Most smaller (Ipswich|Kenmore|Toowong|Springfield) (bond cleaning|spring cleaning|bathroom deep cleaning)/gi,
        /(Bond Cleaning|Spring Cleaning|Bathroom Deep Cleaning) in (Ipswich|Kenmore|Toowong|Springfield)/g,
        /Professional (bond cleaning|spring cleaning|bathroom deep cleaning) services in (Ipswich|Kenmore|Toowong|Springfield)/gi
    ];
    
    for (const filePath of contentFiles) {
        const content = readFileSync(filePath, 'utf-8');
        const relativePath = relative(SRC_DIR, filePath);
        
        // Skip files we don't want to check
        if (shouldSkipFile(content, relativePath)) {
            continue;
        }
        
        // Count templates
        const templates = content.match(/\{\{[^}]+\}\}/g) || [];
        templateCount += templates.length;
        
        // Check for remaining hardcoded content
        for (const pattern of problemPatterns) {
            const matches = content.match(pattern) || [];
            if (matches.length > 0) {
                hardcodedCount += matches.length;
                if (!filesWithIssues.includes(relativePath)) {
                    filesWithIssues.push(relativePath);
                }
            }
        }
    }
    
    console.log(`\n📊 Validation Results:`);
    console.log(`   Template placeholders found: ${templateCount}`);
    console.log(`   Hardcoded references remaining: ${hardcodedCount}`);
    console.log(`   Files with issues: ${filesWithIssues.length}`);
    
    if (filesWithIssues.length > 0) {
        console.log('\n⚠️  Files with remaining hardcoded content:');
        filesWithIssues.forEach(file => console.log(`   - ${file}`));
    }
    
    return {
        templateCount,
        hardcodedCount,
        filesWithIssues,
        success: hardcodedCount === 0
    };
}

// Export functions for testing
export { migrateContentTemplates, validateMigration };

// Run if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
    const command = process.argv[2];
    
    if (command === 'validate') {
        validateMigration().catch(console.error);
    } else {
        migrateContentTemplates()
            .then(() => validateMigration())
            .catch(console.error);
    }
}
