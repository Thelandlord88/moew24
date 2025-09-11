import { test, expect } from '@playwright/test';
test('canonical self present on home', async ({ page }) => {
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  const href = await page.getAttribute('link[rel="canonical"]','href');
  expect(href).toMatch(/^https?:\/\/.+/);
});
test('images have width/height', async ({ page }) => {
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  const bad = await page.$$eval('img', imgs => imgs.filter(i=>!i.getAttribute('width')||!i.getAttribute('height')).length);
  expect(bad).toBe(0);
});
