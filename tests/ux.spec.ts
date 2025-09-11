import { test, expect } from '@playwright/test';
import fs from 'node:fs';
function smoke(){ try{ return JSON.parse(fs.readFileSync('tmp/smoke-paths.json','utf8')).paths || []; }catch{ return ['/']; } }
for (const url of smoke().slice(0, 12)) {
  test(`CTA visible (mobile) ${url}`, async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    const res = await page.goto(url, { waitUntil: 'domcontentloaded' });
    expect(res?.status()).toBeLessThan(400);
    const cta = page.locator('a:has-text("Quote"), a:has-text("Book"), button:has-text("Quote"), button:has-text("Book")').first();
    await expect(cta).toBeVisible();
    const box = await cta.boundingBox();
    expect((box?.y ?? 1e6)).toBeLessThan(900);
  });
}
