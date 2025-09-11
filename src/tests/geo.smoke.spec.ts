import { test, expect } from '@playwright/test';
import fs from 'node:fs';
import { routes } from '@/lib/routes';
function paths(){ try{ const j=JSON.parse(fs.readFileSync('tmp/smoke-paths.json','utf8')); return Array.isArray(j.paths)? j.paths : [routes.suburbs.index(),routes.services.index()]; } catch { return [routes.suburbs.index(),routes.services.index()]; } }
for(const p of paths()){
  test(`responds ${p}`, async ({ page }) => {
    const r = await page.goto(p); expect(r?.status()).toBeLessThan(400);
    const body = await page.textContent('body'); expect(body||'').not.toMatch(/undefined|not found/i);
  });
}
for(const p of paths().filter(x=>/\/suburbs\/[^/]+\/$/.test(x) || /\/services\/(spring-clean|bathroom-deep-clean)\/[^/]+\/$/.test(x)).slice(0,6)){
  test(`json-ld present ${p}`, async ({ page }) => {
    await page.goto(p);
    const n = await page.locator('script[type="application/ld+json"]').count();
    expect(n).toBeGreaterThan(0);
  });
}
