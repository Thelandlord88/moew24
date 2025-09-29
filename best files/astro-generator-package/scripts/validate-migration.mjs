#!/usr/bin/env node

// scripts/validate-migration.mjs
/**
 * Migration Validation Script
 * Validates that hardcoded dependencies have been eliminated
 */

import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join, extname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = join(__filename, '..');

const ROOT = join(__dirname, '..');
const SRC_DIR = join(ROOT, 'src');

// Import for dynamic data
import { suburbProvider } from '../src/lib/suburbProvider.js';

// Test suburbs for validation
const TEST_SUBURBS = [
    'ipswich', 'kenmore', 'toowong', 'springfield', 'redbank-plains',
    'brookwater', 'st-lucia', 'indooroopilly', 'goodna', 'camira'
];

// Test services
const TEST_SERVICES = ['bond-cleaning', 'spring-cleaning', 'bathroom-deep-clean'];

async function validateMigration() {
    console.log('✅ Starting comprehensive migration validation...');
    
    const validation = {
        timestamp: new Date().toISOString(),
        tests: {},
        summary: {
            totalTests: 0,
            passed: 0,
            failed: 0,
            warnings: 0
        },
        details: {
            hardcodedReferences: [],
            templateCoverage: {},
            systemIntegrity: {},
            performance: {}
        }
    };
    
    // Test 1: Check for hardcoded suburb references
    console.log('\n🔍 Test 1: Scanning for hardcoded suburb references...');
    validation.tests.hardcodedReferences = await testHardcodedReferences();
    validation.summary.totalTests++;
    
    // Test 2: Validate template system
    console.log('\n🧪 Test 2: Testing template system functionality...');
    validation.tests.templateSystem = await testTemplateSystem();
    validation.summary.totalTests++;
    
    // Test 3: Validate Astro props generation
    console.log('\n🚀 Test 3: Testing Astro props generation...');
    validation.tests.astroPropsGeneration = await testAstroPropsGeneration();
    validation.summary.totalTests++;
    
    // Test 4: Check SEO schema integration
    console.log('\n📊 Test 4: Testing SEO schema integration...');
    validation.tests.seoIntegration = await testSEOIntegration();
    validation.summary.totalTests++;
    
    // Test 5: Performance benchmarks
    console.log('\n⚡ Test 5: Running performance benchmarks...');
    validation.tests.performance = await testPerformance();
    validation.summary.totalTests++;
    
    // Calculate summary
    for (const test of Object.values(validation.tests)) {
        if (test.status === 'pass') validation.summary.passed++;
        else if (test.status === 'fail') validation.summary.failed++;
        else if (test.status === 'warning') validation.summary.warnings++;
    }
    
    // Save detailed report
    const reportPath = join(ROOT, '__reports', 'migration-validation-report.json');
    writeFileSync(reportPath, JSON.stringify(validation, null, 2));
    
    // Print summary
    printValidationSummary(validation);
    
    return validation;
}

async function testHardcodedReferences() {
    const test = {
        name: 'Hardcoded References Check',
        status: 'pass',
        issues: [],
        details: {}
    };
    
    const contentFiles = await findContentFiles(SRC_DIR);
    let totalHardcoded = 0;
    
    // Patterns to detect hardcoded suburbs
    const hardcodedPatterns = [
        /Most smaller (Ipswich|Kenmore|Toowong|Springfield|Redbank Plains) (bond cleaning|spring cleaning|bathroom deep cleaning)/gi,
        /(Bond Cleaning|Spring Cleaning|Bathroom Deep Cleaning) in (Ipswich|Kenmore|Toowong|Springfield)/g,
        /Professional.*?services in (Ipswich|Kenmore|Toowong|Springfield)\./gi,
        /"cluster"\s*:\s*"(ipswich|kenmore|toowong|springfield)"/gi,
        /"suburb"\s*:\s*"(ipswich|kenmore|toowong|springfield)"/gi
    ];
    
    for (const filePath of contentFiles) {
        const content = readFileSync(filePath, 'utf-8');
        const relativePath = relative(SRC_DIR, filePath);
        
        // Skip files that should contain hardcoded references
        if (shouldSkipValidation(content, relativePath)) {
            continue;
        }
        
        for (const pattern of hardcodedPatterns) {
            const matches = Array.from(content.matchAll(pattern));
            if (matches.length > 0) {
                totalHardcoded += matches.length;
                test.issues.push({
                    file: relativePath,
                    matches: matches.map(m => m[0]),
                    pattern: pattern.source
                });
            }
        }
    }
    
    test.details.totalHardcodedReferences = totalHardcoded;
    test.details.filesScanned = contentFiles.length;
    
    if (totalHardcoded > 0) {
        test.status = 'fail';
        test.message = `Found ${totalHardcoded} hardcoded suburb references in ${test.issues.length} files`;
    } else {
        test.message = 'No hardcoded suburb references found';
    }
    
    return test;
}

async function testTemplateSystem() {
    const test = {
        name: 'Template System Functionality',
        status: 'pass',
        issues: [],
        details: {}
    };
    
    try {
        let totalTemplatesGenerated = 0;
        const templateTypes = ['faqAnswer', 'cardTitle', 'metaDescription', 'pageTitle'];
        
        // Test template generation for sample suburbs
        for (const suburb of TEST_SUBURBS.slice(0, 3)) {
            for (const service of TEST_SERVICES) {
                try {
                    const suburbData = await suburbProvider.getSuburbData(suburb);
                    
                    for (const templateType of templateTypes) {
                        const result = suburbProvider.getContentTemplate(templateType, suburbData, service);
                        
                        if (!result || result.trim() === '') {
                            test.issues.push({
                                type: 'empty_template',
                                suburb,
                                service,
                                templateType
                            });
                        } else {
                            totalTemplatesGenerated++;
                        }
                    }
                } catch (error) {
                    test.issues.push({
                        type: 'generation_error',
                        suburb,
                        service,
                        error: error.message
                    });
                }
            }
        }
        
        test.details.templatesGenerated = totalTemplatesGenerated;
        test.details.expectedTemplates = TEST_SUBURBS.slice(0, 3).length * TEST_SERVICES.length * templateTypes.length;
        
        if (test.issues.length > 0) {
            test.status = 'warning';
            test.message = `Template generation completed with ${test.issues.length} issues`;
        } else {
            test.message = `All ${totalTemplatesGenerated} templates generated successfully`;
        }
        
    } catch (error) {
        test.status = 'fail';
        test.message = `Template system test failed: ${error.message}`;
        test.error = error.message;
    }
    
    return test;
}

async function testAstroPropsGeneration() {
    const test = {
        name: 'Astro Props Generation',
        status: 'pass',
        issues: [],
        details: {}
    };
    
    try {
        // Import AstroPropsGenerator
        const { astroPropsGenerator } = await import('../src/lib/astroPropsGenerator.js');
        
        // Test service paths generation
        const servicePaths = await astroPropsGenerator.generateServicePaths();
        test.details.servicePathsGenerated = servicePaths.length;
        
        // Validate a few sample paths
        const samplePaths = servicePaths.slice(0, 5);
        for (const path of samplePaths) {
            const { params, props } = path;
            
            // Validate required props
            const requiredProps = ['title', 'metaDescription', 'suburb', 'service'];
            for (const prop of requiredProps) {
                if (!props[prop]) {
                    test.issues.push({
                        type: 'missing_prop',
                        path: `${params.service}/${params.suburb}`,
                        missingProp: prop
                    });
                }
            }
            
            // Validate structured data
            if (!props.structuredData || !props.structuredData['@type']) {
                test.issues.push({
                    type: 'invalid_structured_data',
                    path: `${params.service}/${params.suburb}`
                });
            }
        }
        
        // Test dashboard props
        const dashboardProps = await astroPropsGenerator.generateDashboardProps();
        test.details.dashboardGenerated = !!dashboardProps.totalSuburbs;
        
        if (test.issues.length > 0) {
            test.status = 'warning';
            test.message = `Astro props generation completed with ${test.issues.length} issues`;
        } else {
            test.message = `Generated ${servicePaths.length} service paths successfully`;
        }
        
    } catch (error) {
        test.status = 'fail';
        test.message = `Astro props generation failed: ${error.message}`;
        test.error = error.message;
    }
    
    return test;
}

async function testSEOIntegration() {
    const test = {
        name: 'SEO Schema Integration',
        status: 'pass',
        issues: [],
        details: {}
    };
    
    try {
        // Test SEO schema generation
        const { enhancedSuburbServiceGraph } = await import('../src/lib/seoSchemaIntegration.js');
        
        const testSuburb = TEST_SUBURBS[0];
        const testService = TEST_SERVICES[0];
        
        const schema = await enhancedSuburbServiceGraph({
            service: testService,
            suburbSlug: testSuburb
        });
        
        test.details.schemaNodesGenerated = schema.length;
        
        // Validate schema structure
        const requiredTypes = ['LocalBusiness', 'Service', 'Offer'];
        for (const requiredType of requiredTypes) {
            const hasType = schema.some(node => node['@type'] === requiredType);
            if (!hasType) {
                test.issues.push({
                    type: 'missing_schema_type',
                    missingType: requiredType
                });
            }
        }
        
        // Check for geographic data
        const businessNode = schema.find(node => node['@type'] === 'LocalBusiness');
        if (businessNode && (!businessNode.geo || !businessNode.geo.latitude)) {
            test.issues.push({
                type: 'missing_geographic_data',
                node: 'LocalBusiness'
            });
        }
        
        if (test.issues.length > 0) {
            test.status = 'warning';
            test.message = `SEO integration completed with ${test.issues.length} issues`;
        } else {
            test.message = 'SEO schema integration working correctly';
        }
        
    } catch (error) {
        test.status = 'fail';
        test.message = `SEO integration test failed: ${error.message}`;
        test.error = error.message;
    }
    
    return test;
}

async function testPerformance() {
    const test = {
        name: 'Performance Benchmarks',
        status: 'pass',
        issues: [],
        details: {
            benchmarks: {}
        }
    };
    
    try {
        // Benchmark suburb data loading
        const startSuburbs = Date.now();
        const suburbs = await suburbProvider.loadSuburbs();
        const suburbsTime = Date.now() - startSuburbs;
        
        test.details.benchmarks.suburbsLoading = {
            count: suburbs.length,
            timeMs: suburbsTime,
            avgPerSuburb: suburbsTime / suburbs.length
        };
        
        // Benchmark template generation
        const startTemplates = Date.now();
        const testSuburb = await suburbProvider.getSuburbData(TEST_SUBURBS[0]);
        const testTemplate = suburbProvider.getContentTemplate('faqAnswer', testSuburb, TEST_SERVICES[0]);
        const templatesTime = Date.now() - startTemplates;
        
        test.details.benchmarks.templateGeneration = {
            timeMs: templatesTime,
            templateLength: testTemplate.length
        };
        
        // Performance thresholds
        if (suburbsTime > 1000) { // 1 second
            test.issues.push({
                type: 'slow_suburb_loading',
                timeMs: suburbsTime,
                threshold: 1000
            });
        }
        
        if (templatesTime > 100) { // 100ms
            test.issues.push({
                type: 'slow_template_generation',
                timeMs: templatesTime,
                threshold: 100
            });
        }
        
        if (test.issues.length > 0) {
            test.status = 'warning';
            test.message = `Performance benchmarks completed with ${test.issues.length} warnings`;
        } else {
            test.message = 'All performance benchmarks within acceptable limits';
        }
        
    } catch (error) {
        test.status = 'fail';
        test.message = `Performance testing failed: ${error.message}`;
        test.error = error.message;
    }
    
    return test;
}

function shouldSkipValidation(content, filePath) {
    // Skip files that should legitimately contain hardcoded references
    const skipPatterns = [
        /data\//,           // Data files
        /demo-/,            // Demo files
        /test/,             // Test files
        /\.backup\./,       // Backup files
        /__reports/,        // Report files
        /migration/,        // Migration scripts
        /validate/          // Validation scripts
    ];
    
    return skipPatterns.some(pattern => pattern.test(filePath));
}

async function findContentFiles(dir) {
    let files = [];
    const items = readdirSync(dir, { withFileTypes: true });
    
    for (const item of items) {
        const fullPath = join(dir, item.name);
        
        if (item.isDirectory()) {
            if (!['node_modules', 'dist', '.git', '.astro'].includes(item.name)) {
                files = files.concat(await findContentFiles(fullPath));
            }
        } else if (['.astro', '.js', '.ts', '.json', '.md', '.mdx'].includes(extname(item.name))) {
            files.push(fullPath);
        }
    }
    
    return files;
}

function printValidationSummary(validation) {
    console.log('\n' + '='.repeat(60));
    console.log('🎯 MIGRATION VALIDATION SUMMARY');
    console.log('='.repeat(60));
    
    console.log(`\n📊 Overall Results:`);
    console.log(`   Total Tests: ${validation.summary.totalTests}`);
    console.log(`   ✅ Passed: ${validation.summary.passed}`);
    console.log(`   ⚠️  Warnings: ${validation.summary.warnings}`);
    console.log(`   ❌ Failed: ${validation.summary.failed}`);
    
    const overallStatus = validation.summary.failed > 0 ? '❌ FAILED' :
                         validation.summary.warnings > 0 ? '⚠️  WARNINGS' : '✅ PASSED';
    
    console.log(`\n🏆 Migration Status: ${overallStatus}`);
    
    // Print individual test results
    console.log('\n📋 Test Details:');
    for (const [testName, test] of Object.entries(validation.tests)) {
        const statusIcon = test.status === 'pass' ? '✅' :
                          test.status === 'warning' ? '⚠️' : '❌';
        console.log(`   ${statusIcon} ${test.name}: ${test.message}`);
    }
    
    // Migration readiness assessment
    console.log('\n' + '='.repeat(60));
    if (validation.summary.failed === 0) {
        console.log('🚀 MIGRATION IS READY FOR PRODUCTION!');
        console.log('\nYour 121→345 suburb expansion can proceed safely.');
        if (validation.summary.warnings > 0) {
            console.log('⚠️  Address warnings for optimal performance.');
        }
    } else {
        console.log('🔧 MIGRATION REQUIRES FIXES BEFORE PRODUCTION');
        console.log('\nResolve failed tests before proceeding with expansion.');
    }
    console.log('='.repeat(60));
}

// Export for testing
export { validateMigration };

// Run if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
    validateMigration()
        .then(validation => {
            process.exit(validation.summary.failed > 0 ? 1 : 0);
        })
        .catch(error => {
            console.error('❌ Validation failed:', error);
            process.exit(1);
        });
}
