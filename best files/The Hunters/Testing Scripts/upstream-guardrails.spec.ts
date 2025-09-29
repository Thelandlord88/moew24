import { test, expect } from '@playwright/test';
import fs from 'fs';
import path from 'path';

test.describe('Upstream Guardrails - Prevent Regression Classes', () => {
  
  test('no duplicate top-level keys in astro.config.mjs', async () => {
    const configPath = path.join(process.cwd(), 'astro.config.mjs');
    const configContent = fs.readFileSync(configPath, 'utf-8');
    
    // Extract all top-level keys from the config object
    const keyMatches = configContent.match(/^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:/gm);
    
    if (keyMatches) {
      const keys = keyMatches.map(match => match.match(/([a-zA-Z_][a-zA-Z0-9_]*)/)?.[1]).filter(Boolean);
      const duplicates = keys.filter((key, index) => keys.indexOf(key) !== index);
      
      if (duplicates.length > 0) {
        throw new Error(`Duplicate top-level keys found in astro.config.mjs: ${duplicates.join(', ')}`);
      }
    }
  });

  test('no gtag calls in client bundles', async () => {
    const srcDir = path.join(process.cwd(), 'src');
    
    // Recursively find all .astro, .ts, .js files in src/
    function findFiles(dir: string, pattern: RegExp): string[] {
      const files: string[] = [];
      const entries = fs.readdirSync(dir, { withFileTypes: true });
      
      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
          files.push(...findFiles(fullPath, pattern));
        } else if (pattern.test(entry.name)) {
          files.push(fullPath);
        }
      }
      return files;
    }
    
    const sourceFiles = findFiles(srcDir, /\.(astro|ts|js|jsx|tsx)$/);
    const gtagViolations: string[] = [];
    
    for (const file of sourceFiles) {
      const content = fs.readFileSync(file, 'utf-8');
      if (content.includes('gtag(')) {
        gtagViolations.push(file);
      }
    }
    
    if (gtagViolations.length > 0) {
      throw new Error(`gtag() calls found in source files (use analytics shim instead): ${gtagViolations.join(', ')}`);
    }
  });

  test('all NAP data comes from business.json source', async () => {
    const businessDataPath = path.join(process.cwd(), 'src/data/business.json');
    expect(fs.existsSync(businessDataPath)).toBeTruthy();
    
    const businessData = JSON.parse(fs.readFileSync(businessDataPath, 'utf-8'));
    
    // Verify required NAP fields exist
    expect(businessData.name).toBeTruthy();
    expect(businessData.telephone).toBeTruthy();
    expect(businessData.email).toBeTruthy();
    expect(businessData.address).toBeTruthy();
    expect(businessData.address.addressLocality).toBeTruthy();
    
    // Check that NAP data doesn't appear hardcoded in other files
    const srcDir = path.join(process.cwd(), 'src');
    const sourceFiles = fs.readdirSync(srcDir, { recursive: true })
      .filter(file => typeof file === 'string' && file.endsWith('.astro'))
      .map(file => path.join(srcDir, file as string));
    
    const hardcodedNAP: string[] = [];
    const phonePattern = /\+61[\s-]?[0-9][\s-]?[0-9]{4}[\s-]?[0-9]{4}/;
    
    for (const file of sourceFiles) {
      if (fs.existsSync(file)) {
        const content = fs.readFileSync(file, 'utf-8');
        
        // Skip files that import from business.json or jsonld.ts (these are allowed)
        if (content.includes('from "@/data/business.json"') || 
            content.includes('from "@/lib/seo/jsonld"')) {
          continue;
        }
        
        // Check for hardcoded phone numbers
        if (phonePattern.test(content)) {
          hardcodedNAP.push(`${file}: hardcoded phone number found`);
        }
      }
    }
    
    if (hardcodedNAP.length > 0) {
      throw new Error(`Hardcoded NAP data found (should use business.json): ${hardcodedNAP.join(', ')}`);
    }
  });

  test('quote flow smoke test with analytics shim', async ({ page }) => {
    let analyticsEventsFired = 0;
    
    // Intercept the analytics endpoint
    await page.route('/api/e', route => {
      analyticsEventsFired++;
      route.fulfill({ status: 200, body: 'OK' });
    });
    
    // Go to quote page - should fire page_view
    await page.goto('/quote/');
    await page.waitForTimeout(100); // Brief wait for analytics
    
    expect(analyticsEventsFired).toBeGreaterThan(0);
    
    // Fill and submit form
    await page.fill('#name', 'Test User');
    await page.fill('#phone', '0400123456');
    await page.selectOption('#property-type', '2-bed-unit');
    await page.fill('#suburb', 'Brisbane');
    
    const initialEvents = analyticsEventsFired;
    await page.click('button[type="submit"]');
    
    // Should fire lead_submit event
    await page.waitForTimeout(100);
    expect(analyticsEventsFired).toBeGreaterThan(initialEvents);
    
    // Should redirect to thank you page and fire conversion event
    await page.waitForURL('**/quote/thank-you/**', { timeout: 5000 });
    const finalEvents = analyticsEventsFired;
    expect(finalEvents).toBeGreaterThan(initialEvents + 1);
  });
});
