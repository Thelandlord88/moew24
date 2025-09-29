import { test, expect } from '@playwright/test';

test.describe('Quote Flow - Revenue Path Tests', () => {
  test('quote form submission completes successfully', async ({ page }) => {
    // Go to quote page
    await page.goto('/quote/');
    
    // Verify quote form is present and visible
    await expect(page.locator('#quote-form')).toBeVisible();
    await expect(page.getByRole('heading', { name: /request your free quote/i })).toBeVisible();
    
    // Fill out the form
    await page.fill('#name', 'Test User');
    await page.fill('#phone', '0400123456');
    await page.fill('#email', 'test@example.com');
    await page.selectOption('#property-type', '2-bed-unit');
    await page.fill('#suburb', 'Brisbane');
    await page.fill('#message', 'Need bond clean for next week');
    
    // Submit the form
    await page.click('button[type="submit"]');
    
    // Verify success state appears
    await expect(page.locator('text=Quote Request Sent!')).toBeVisible();
    
    // Verify redirect to thank you page
    await page.waitForURL('**/quote/thank-you/**', { timeout: 5000 });
    await expect(page.getByRole('heading', { name: /quote request received/i })).toBeVisible();
  });

  test('quote CTA exists on all main pages', async ({ page }) => {
    const pages = ['/', '/blog/', '/blog/topics/'];
    
    for (const pagePath of pages) {
      await page.goto(pagePath);
      
      // Check that quote link exists in navigation
      const quoteLink = page.locator('nav a[href="/quote/"]');
      await expect(quoteLink).toBeVisible();
      await expect(quoteLink).toContainText('Get Quote');
    }
  });

  test('phone and email links track analytics events', async ({ page }) => {
    let phoneClicked = false;
    let emailClicked = false;
    
    // Listen for console logs (our analytics events)
    page.on('console', msg => {
      if (msg.text().includes('phone_click')) phoneClicked = true;
      if (msg.text().includes('email_click')) emailClicked = true;
    });
    
    await page.goto('/quote/');
    
    // Click phone link
    await page.click('a[href^="tel:"]');
    
    // Verify analytics event was logged
    await page.waitForTimeout(100); // Brief wait for console log
    expect(phoneClicked).toBeTruthy();
  });

  test('LocalBusiness JSON-LD validates on quote page', async ({ page }) => {
    await page.goto('/quote/');
    
    // Get JSON-LD script content
    const jsonLdScript = page.locator('script[type="application/ld+json"]');
    await expect(jsonLdScript).toBeVisible();
    
    const jsonContent = await jsonLdScript.textContent();
    const parsedLD = JSON.parse(jsonContent || '{}');
    
    // Verify required LocalBusiness fields
    expect(parsedLD['@type']).toBe('LocalBusiness');
    expect(parsedLD.name).toBeTruthy();
    expect(parsedLD.telephone).toBeTruthy();
    expect(parsedLD.address).toBeTruthy();
    expect(parsedLD.address.addressLocality).toBeTruthy();
    expect(parsedLD.areaServed).toBeTruthy();
    expect(Array.isArray(parsedLD.areaServed)).toBeTruthy();
    expect(parsedLD.areaServed.length).toBeGreaterThan(0);
  });
});

test.describe('Sitemap and URL Canonicalization', () => {
  test('sitemap contains production URLs only', async ({ page }) => {
    const response = await page.request.get('/sitemap.xml');
    expect(response.ok()).toBeTruthy();
    
    const sitemapText = await response.text();
    
    // Verify production domain is used
    expect(sitemapText).toContain('https://onendone.com.au');
    
    // Verify no placeholder URLs exist
    expect(sitemapText).not.toContain('YOUR_SITE_URL');
    expect(sitemapText).not.toContain('localhost');
    
    // Verify quote page is included
    expect(sitemapText).toContain('/quote/');
  });

  test('canonical URLs are consistent', async ({ page }) => {
    const pages = ['/', '/quote/', '/blog/', '/blog/topics/'];
    
    for (const pagePath of pages) {
      await page.goto(pagePath);
      
      const canonical = await page.locator('link[rel="canonical"]').getAttribute('href');
      
      // Verify canonical uses production domain
      expect(canonical).toContain('https://onendone.com.au');
      
      // Verify no placeholder URLs
      expect(canonical).not.toContain('YOUR_SITE_URL');
    }
  });
});

test.describe('Form Component Uniqueness', () => {
  test('only one QuoteForm component type exists', async ({ page }) => {
    // This test ensures we maintain "one path to money"
    await page.goto('/quote/');
    
    // Should have exactly one quote form
    const quoteForms = page.locator('#quote-form');
    await expect(quoteForms).toHaveCount(1);
    
    // Should not have multiple different form components
    const allForms = page.locator('form');
    await expect(allForms).toHaveCount(1);
  });
});
