import { test, expect } from '@playwright/test';

test('blog index renders & links', async ({ page }) => {
  await page.goto('/blog/');
  await expect(page.getByRole('heading', { level: 1, name: 'Blog' })).toBeVisible();
  
  // Check that at least one post card exists
  const postLinks = page.locator('article a');
  await expect(postLinks.first()).toHaveAttribute('href', /\/blog\/.+\/$/);
});

test('post page renders JSON-LD', async ({ page }) => {
  await page.goto('/blog/bond-cleaning-checklist/');
  
  // Check page loads
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
  
  // Check JSON-LD structured data exists
  const ldScript = page.locator('script[type="application/ld+json"]').first();
  const ldContent = await ldScript.textContent();
  expect(ldContent).toContain('"@type":"BlogPosting"');
});

test('rss feed is valid', async ({ page }) => {
  const response = await page.request.get('/blog/rss.xml');
  expect(response.ok()).toBeTruthy();
  
  const text = await response.text();
  expect(text).toContain('<rss');
  expect(text).toContain('<item>');
  expect(text).toContain('<title>');
});

test('category page renders with content', async ({ page }) => {
  await page.goto('/blog/category/checklists/');
  
  // Check category page loads
  await expect(page.getByRole('heading', { name: /Category: checklists/i })).toBeVisible();
  
  // Should have some posts or a "no posts" message
  const hasContent = await page.locator('article').count() > 0;
  const hasNoPostsMessage = await page.locator('text=No posts found').count() > 0;
  expect(hasContent || hasNoPostsMessage).toBeTruthy();
});

test('topics hub renders all taxonomies', async ({ page }) => {
  await page.goto('/blog/topics/');
  
  await expect(page.getByRole('heading', { level: 1, name: 'Topics' })).toBeVisible();
  await expect(page.getByRole('heading', { level: 2, name: 'Categories' })).toBeVisible();
  await expect(page.getByRole('heading', { level: 2, name: 'Tags' })).toBeVisible();
  await expect(page.getByRole('heading', { level: 2, name: 'Regions' })).toBeVisible();
  
  // Should have at least one link in each section
  const categoryLinks = page.locator('section:has(h2:text("Categories")) a');
  await expect(categoryLinks.first()).toBeVisible();
});

test('sitemap.xml generates correctly', async ({ page }) => {
  const response = await page.request.get('/sitemap.xml');
  expect(response.ok()).toBeTruthy();
  
  const text = await response.text();
  expect(text).toContain('<urlset');
  expect(text).toContain('<loc>');
  expect(text).toContain('/blog/');
});
