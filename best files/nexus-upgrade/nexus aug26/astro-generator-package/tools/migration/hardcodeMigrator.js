// Hardcode Migration System
// NEXUS Hardcode Detective Innovation

import fs from 'node:fs';
import path from 'node:path';
import { glob } from 'glob';

export class HardcodeMigrator {
    constructor() {
        this.findings = [];
        this.migrations = [];
        this.patterns = new Map();
        this.setupPatterns();
    }
    
    setupPatterns() {
        // Hardcoded string patterns
        this.patterns.set('longStrings', {
            regex: /"[^"]{20,}"/g,
            type: 'string_literal',
            severity: 'medium'
        });
        
        // Hardcoded URLs
        this.patterns.set('urls', {
            regex: /https?:\/\/[^\s"']+/g,
            type: 'url',
            severity: 'high'
        });
        
        // Magic numbers
        this.patterns.set('magicNumbers', {
            regex: /\b\d{3,}\b/g,
            type: 'number',
            severity: 'medium'
        });
        
        // Hardcoded colors
        this.patterns.set('colors', {
            regex: /#[0-9a-fA-F]{3,6}/g,
            type: 'color',
            severity: 'high'
        });
        
        // Hardcoded dimensions
        this.patterns.set('dimensions', {
            regex: /\d+px|\d+rem|\d+em/g,
            type: 'dimension',
            severity: 'medium'
        });
    }
    
    async scanForHardcodes(directory) {
        console.log(`🔍 Scanning ${directory} for hardcodes...`);
        
        const files = await glob('**/*.{js,ts,astro,css,scss}', {
            cwd: directory,
            ignore: ['node_modules/**', 'dist/**']
        });
        
        for (const file of files) {
            await this.scanFile(path.join(directory, file));
        }
        
        return this.generateReport();
    }
    
    async scanFile(filePath) {
        try {
            const content = fs.readFileSync(filePath, 'utf-8');
            const lines = content.split('\n');
            
            for (const [patternName, pattern] of this.patterns) {
                let match;
                while ((match = pattern.regex.exec(content)) !== null) {
                    const lineNumber = this.getLineNumber(content, match.index);
                    
                    this.findings.push({
                        file: filePath,
                        line: lineNumber,
                        column: match.index - this.getLineStart(content, match.index),
                        type: pattern.type,
                        severity: pattern.severity,
                        value: match[0],
                        context: lines[lineNumber - 1]?.trim(),
                        pattern: patternName
                    });
                }
            }
        } catch (error) {
            console.error(`Error scanning ${filePath}:`, error.message);
        }
    }
    
    generateMigrationPlan() {
        console.log('📋 Generating migration plan...');
        
        const grouped = this.groupFindingsByType();
        const plan = [];
        
        for (const [type, findings] of Object.entries(grouped)) {
            plan.push({
                type,
                priority: this.getPriority(type),
                findings: findings.length,
                migrations: this.generateMigrationsForType(type, findings)
            });
        }
        
        return plan.sort((a, b) => b.priority - a.priority);
    }
    
    generateMigrationsForType(type, findings) {
        const migrations = [];
        
        switch (type) {
            case 'color':
                migrations.push({
                    action: 'create_color_tokens',
                    description: 'Extract colors to design token system',
                    files: [...new Set(findings.map(f => f.file))],
                    automation: true
                });
                break;
                
            case 'dimension':
                migrations.push({
                    action: 'create_spacing_tokens', 
                    description: 'Replace dimensions with spacing tokens',
                    files: [...new Set(findings.map(f => f.file))],
                    automation: true
                });
                break;
                
            case 'string_literal':
                migrations.push({
                    action: 'externalize_content',
                    description: 'Move strings to content management system',
                    files: [...new Set(findings.map(f => f.file))],
                    automation: false
                });
                break;
                
            case 'url':
                migrations.push({
                    action: 'externalize_config',
                    description: 'Move URLs to environment configuration',
                    files: [...new Set(findings.map(f => f.file))],
                    automation: true
                });
                break;
        }
        
        return migrations;
    }
    
    async executeMigration(migrationPlan) {
        console.log('🚀 Executing migration plan...');
        
        for (const typeGroup of migrationPlan) {
            console.log(`\n📦 Processing ${typeGroup.type} migrations...`);
            
            for (const migration of typeGroup.migrations) {
                if (migration.automation) {
                    await this.executeAutomatedMigration(migration, typeGroup.findings);
                } else {
                    this.generateManualMigrationGuide(migration, typeGroup.findings);
                }
            }
        }
    }
    
    async executeAutomatedMigration(migration, findings) {
        console.log(`  ⚙️  Automated: ${migration.description}`);
        
        switch (migration.action) {
            case 'create_color_tokens':
                await this.createColorTokens(findings);
                break;
            case 'create_spacing_tokens':
                await this.createSpacingTokens(findings);
                break;
            case 'externalize_config':
                await this.externalizeConfig(findings);
                break;
        }
    }
    
    generateReport() {
        const report = {
            summary: {
                totalFindings: this.findings.length,
                files: [...new Set(this.findings.map(f => f.file))].length,
                types: [...new Set(this.findings.map(f => f.type))]
            },
            findings: this.findings,
            migrationPlan: this.generateMigrationPlan()
        };
        
        return report;
    }
    
    // Utility methods
    getLineNumber(content, index) {
        return content.substring(0, index).split('\n').length;
    }
    
    getLineStart(content, index) {
        const beforeIndex = content.substring(0, index);
        const lastNewline = beforeIndex.lastIndexOf('\n');
        return lastNewline === -1 ? 0 : lastNewline + 1;
    }
    
    groupFindingsByType() {
        return this.findings.reduce((acc, finding) => {
            if (!acc[finding.type]) acc[finding.type] = [];
            acc[finding.type].push(finding);
            return acc;
        }, {});
    }
    
    getPriority(type) {
        const priorities = {
            'url': 5,
            'color': 4,
            'dimension': 3,
            'string_literal': 2,
            'number': 1
        };
        return priorities[type] || 0;
    }
}
