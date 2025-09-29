#!/usr/bin/env node

/**
 * Content Quality Guardian - SEO, Accessibility & Content Quality Enforcement
 * 
 * Comprehensive content quality checking that integrates with the Quality Gate system.
 * Provides deep analysis of SEO optimization, WCAG 2.1 AA accessibility compliance,
 * and content quality metrics with actionable recommendations.
 * 
 * Features:
 * - SEO scoring (meta tags, structured data, internal linking)
 * - WCAG 2.1 AA accessibility compliance checking
 * - Content quality analysis (readability, freshness, optimization)
 * - Integration with existing performance guardian
 * - Smart budgets and graduated enforcement
 */

import { readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { join, extname, basename, dirname } from 'node:path';
import { globby } from 'globby';
import { fileURLToPath } from 'node:url';
import { JSDOM } from 'jsdom';

const PROJECT_ROOT = '/workspaces/Augest25';
const DIST_DIR = join(PROJECT_ROOT, 'dist');

// Content Quality Budgets - aligned with business needs
const CONTENT_QUALITY_BUDGETS = {
  seo: {
    minScore: 85,           // SEO score threshold
    maxMissingMeta: 2,      // Missing meta tags allowed
    minInternalLinks: 1,    // Minimum internal links per page
    maxTitleLength: 60,     // SEO-optimal title length
    maxDescLength: 160,     // SEO-optimal description length
  },
  accessibility: {
    minScore: 90,           // WCAG 2.1 AA compliance target
    maxContrastIssues: 0,   // Zero tolerance for contrast issues
    maxMissingAlt: 0,       // All images must have alt text
    maxHeadingGaps: 1,      // Allow minor heading hierarchy issues
  },
  content: {
    minReadabilityScore: 60,  // Flesch Reading Ease minimum
    maxStaleContentDays: 365, // Content freshness threshold
    minWordCount: 150,        // Minimum content length
    maxDuplicatePercent: 15,  // Duplicate content threshold
  },
  performance: {
    maxImagesSizeKB: 500,     // Total images per page
    maxCSSSelectors: 1000,    // CSS complexity limit
    maxDOMNodes: 1500,        // DOM complexity limit
  }
};

/**
 * Main Content Quality Guardian runner
 */
async function runContentQualityGuardian(options = {}) {
  const { mode = 'warning', target = 'all', fix = false } = options;
  
  console.log('🎯 Content Quality Guardian - Comprehensive Analysis\n');
  console.log(`Mode: ${mode} | Target: ${target} | Auto-fix: ${fix}\n`);
  
  // Discover all HTML pages in dist
  const htmlFiles = await globby(['**/*.html'], { 
    cwd: DIST_DIR,
    absolute: true 
  });
  
  if (htmlFiles.length === 0) {
    console.log('⚠️  No built HTML files found. Run build first.\n');
    return { success: false, error: 'No HTML files found' };
  }
  
  console.log(`🔍 Analyzing ${htmlFiles.length} pages...\n`);
  
  const results = {
    pages: [],
    summary: {
      totalPages: htmlFiles.length,
      passedSEO: 0,
      passedA11y: 0,
      passedContent: 0,
      passedPerformance: 0,
      totalIssues: 0,
      criticalIssues: 0,
    },
    budgetViolations: [],
    recommendations: new Set(),
    fixes: []
  };
  
  // Analyze each page
  for (const filePath of htmlFiles) {
    try {
      const pageResult = await analyzePageQuality(filePath, { mode, fix });
      results.pages.push(pageResult);
      
      // Update summary stats
      if (pageResult.seo.score >= CONTENT_QUALITY_BUDGETS.seo.minScore) results.summary.passedSEO++;
      if (pageResult.accessibility.score >= CONTENT_QUALITY_BUDGETS.accessibility.minScore) results.summary.passedA11y++;
      if (pageResult.content.score >= CONTENT_QUALITY_BUDGETS.content.minReadabilityScore) results.summary.passedContent++;
      if (pageResult.performance.passed) results.summary.passedPerformance++;
      
      results.summary.totalIssues += pageResult.totalIssues;
      results.summary.criticalIssues += pageResult.criticalIssues;
      
      // Collect violations and recommendations
      pageResult.budgetViolations.forEach(v => results.budgetViolations.push(v));
      pageResult.recommendations.forEach(r => results.recommendations.add(r));
      if (pageResult.fixes) results.fixes.push(...pageResult.fixes);
      
    } catch (error) {
      console.error(`❌ Error analyzing ${filePath}:`, error.message);
    }
  }
  
  // Generate comprehensive report
  const reportResult = generateContentQualityReport(results, mode);
  
  // Save results for quality gate integration
  await saveContentQualityBaseline(results);
  
  return reportResult;
}

/**
 * Analyze a single page for all content quality metrics
 */
async function analyzePageQuality(filePath, options = {}) {
  const { mode, fix } = options;
  const html = readFileSync(filePath, 'utf-8');
  const dom = new JSDOM(html);
  const document = dom.window.document;
  
  const pageName = filePath.replace(DIST_DIR, '').replace('/index.html', '') || '/';
  
  console.log(`   📄 ${pageName}`);
  
  const pageResult = {
    page: pageName,
    filePath,
    seo: await analyzeSEOQuality(document, html, pageName),
    accessibility: await analyzeAccessibilityQuality(document, html, pageName),
    content: await analyzeContentQuality(document, html, pageName),
    performance: await analyzeContentPerformance(document, html, pageName),
    timestamp: new Date().toISOString(),
    totalIssues: 0,
    criticalIssues: 0,
    budgetViolations: [],
    recommendations: new Set(),
    fixes: []
  };
  
  // Calculate total issues and violations
  pageResult.totalIssues = 
    pageResult.seo.issues.length + 
    pageResult.accessibility.issues.length + 
    pageResult.content.issues.length + 
    pageResult.performance.issues.length;
    
  pageResult.criticalIssues = 
    pageResult.seo.issues.filter(i => i.severity === 'critical').length +
    pageResult.accessibility.issues.filter(i => i.severity === 'critical').length +
    pageResult.content.issues.filter(i => i.severity === 'critical').length +
    pageResult.performance.issues.filter(i => i.severity === 'critical').length;
  
  // Check budget violations
  pageResult.budgetViolations = checkContentQualityBudgets(pageResult, pageName);
  
  // Generate recommendations
  pageResult.recommendations = generatePageRecommendations(pageResult);
  
  // Apply auto-fixes if requested
  if (fix) {
    pageResult.fixes = await applyContentQualityFixes(pageResult, filePath);
  }
  
  return pageResult;
}

/**
 * SEO Quality Analysis - comprehensive SEO scoring
 */
async function analyzeSEOQuality(document, html, pageName) {
  const seoResult = {
    score: 0,
    grade: 'F',
    issues: [],
    metrics: {},
    details: {}
  };
  
  // Meta tag analysis
  const title = document.querySelector('title')?.textContent || '';
  const metaDesc = document.querySelector('meta[name="description"]')?.getAttribute('content') || '';
  const canonical = document.querySelector('link[rel="canonical"]')?.getAttribute('href') || '';
  const robots = document.querySelector('meta[name="robots"]')?.getAttribute('content') || '';
  
  seoResult.metrics = {
    titleLength: title.length,
    descriptionLength: metaDesc.length,
    hasCanonical: !!canonical,
    hasRobots: !!robots,
    hasH1: document.querySelectorAll('h1').length,
    internalLinks: document.querySelectorAll('a[href^="/"], a[href*="' + process.env.SITE_URL + '"]').length,
    externalLinks: document.querySelectorAll('a[href^="http"]:not([href*="' + process.env.SITE_URL + '"])').length,
    images: document.querySelectorAll('img').length,
    imagesWithAlt: document.querySelectorAll('img[alt]').length,
    structuredData: (html.match(/application\/ld\+json/g) || []).length,
  };
  
  let seoScore = 0;
  
  // Title optimization (20 points)
  if (!title) {
    seoResult.issues.push({ 
      type: 'seo', 
      severity: 'critical', 
      message: 'Missing page title',
      recommendation: 'Add a descriptive <title> tag'
    });
  } else if (title.length < 10) {
    seoResult.issues.push({ 
      type: 'seo', 
      severity: 'warning', 
      message: `Title too short (${title.length} chars)`,
      recommendation: 'Expand title to 30-60 characters'
    });
    seoScore += 10;
  } else if (title.length > 60) {
    seoResult.issues.push({ 
      type: 'seo', 
      severity: 'warning', 
      message: `Title too long (${title.length} chars)`,
      recommendation: 'Shorten title to under 60 characters'
    });
    seoScore += 15;
  } else {
    seoScore += 20;
  }
  
  // Meta description (20 points)
  if (!metaDesc) {
    seoResult.issues.push({ 
      type: 'seo', 
      severity: 'critical', 
      message: 'Missing meta description',
      recommendation: 'Add meta description (120-160 chars)'
    });
  } else if (metaDesc.length < 120) {
    seoResult.issues.push({ 
      type: 'seo', 
      severity: 'warning', 
      message: `Description too short (${metaDesc.length} chars)`,
      recommendation: 'Expand description to 120-160 characters'
    });
    seoScore += 10;
  } else if (metaDesc.length > 160) {
    seoResult.issues.push({ 
      type: 'seo', 
      severity: 'warning', 
      message: `Description too long (${metaDesc.length} chars)`,
      recommendation: 'Shorten description to under 160 characters'
    });
    seoScore += 15;
  } else {
    seoScore += 20;
  }
  
  // Heading structure (15 points)
  const headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
  const h1Count = document.querySelectorAll('h1').length;
  
  if (h1Count === 0) {
    seoResult.issues.push({ 
      type: 'seo', 
      severity: 'critical', 
      message: 'Missing H1 heading',
      recommendation: 'Add one H1 heading per page'
    });
  } else if (h1Count > 1) {
    seoResult.issues.push({ 
      type: 'seo', 
      severity: 'warning', 
      message: `Multiple H1 headings (${h1Count})`,
      recommendation: 'Use only one H1 per page'
    });
    seoScore += 10;
  } else {
    seoScore += 15;
  }
  
  // Structured data (15 points)
  if (seoResult.metrics.structuredData === 0) {
    seoResult.issues.push({ 
      type: 'seo', 
      severity: 'warning', 
      message: 'No structured data found',
      recommendation: 'Add JSON-LD structured data for rich snippets'
    });
  } else {
    seoScore += 15;
  }
  
  // Internal linking (10 points)
  if (seoResult.metrics.internalLinks < CONTENT_QUALITY_BUDGETS.seo.minInternalLinks) {
    seoResult.issues.push({ 
      type: 'seo', 
      severity: 'warning', 
      message: 'Insufficient internal linking',
      recommendation: 'Add more internal links to related content'
    });
    seoScore += 5;
  } else {
    seoScore += 10;
  }
  
  // Technical SEO (20 points)
  if (!canonical) {
    seoResult.issues.push({ 
      type: 'seo', 
      severity: 'warning', 
      message: 'Missing canonical URL',
      recommendation: 'Add canonical link to prevent duplicate content'
    });
  } else {
    seoScore += 10;
  }
  
  if (!robots) {
    seoResult.issues.push({ 
      type: 'seo', 
      severity: 'info', 
      message: 'Missing robots meta tag',
      recommendation: 'Add robots meta for indexing control'
    });
  } else {
    seoScore += 10;
  }
  
  seoResult.score = Math.min(100, seoScore);
  seoResult.grade = getSEOGrade(seoResult.score);
  seoResult.details = {
    title,
    metaDesc,
    canonical,
    robots,
    headingStructure: Array.from(headings).map(h => h.tagName),
  };
  
  return seoResult;
}

/**
 * Accessibility Quality Analysis - WCAG 2.1 AA compliance
 */
async function analyzeAccessibilityQuality(document, html, pageName) {
  const a11yResult = {
    score: 0,
    grade: 'F',
    issues: [],
    metrics: {},
    wcagViolations: []
  };
  
  let a11yScore = 0;
  const totalChecks = 10;
  
  // 1. Images with alt text (WCAG 1.1.1)
  const images = document.querySelectorAll('img');
  const imagesWithoutAlt = Array.from(images).filter(img => !img.hasAttribute('alt') || !img.getAttribute('alt').trim());
  
  if (imagesWithoutAlt.length === 0 && images.length > 0) {
    a11yScore += 10;
  } else if (imagesWithoutAlt.length > 0) {
    a11yResult.issues.push({
      type: 'accessibility',
      severity: 'critical',
      message: `${imagesWithoutAlt.length} images missing alt text`,
      recommendation: 'Add descriptive alt text to all images',
      wcag: '1.1.1'
    });
    a11yResult.wcagViolations.push('1.1.1');
  }
  
  // 2. Heading hierarchy (WCAG 1.3.1)
  const headings = Array.from(document.querySelectorAll('h1, h2, h3, h4, h5, h6'));
  let headingScore = 0;
  let previousLevel = 0;
  
  for (const heading of headings) {
    const level = parseInt(heading.tagName.charAt(1));
    if (level - previousLevel > 1 && previousLevel > 0) {
      a11yResult.issues.push({
        type: 'accessibility',
        severity: 'warning',
        message: `Heading hierarchy skip from H${previousLevel} to H${level}`,
        recommendation: 'Use sequential heading levels (H1 → H2 → H3)',
        wcag: '1.3.1'
      });
    }
    previousLevel = level;
  }
  
  if (a11yResult.issues.filter(i => i.wcag === '1.3.1').length === 0) {
    a11yScore += 10;
  } else {
    a11yScore += 5;
  }
  
  // 3. Form labels (WCAG 1.3.1, 4.1.2)
  const inputs = document.querySelectorAll('input:not([type="hidden"]), textarea, select');
  const inputsWithoutLabels = Array.from(inputs).filter(input => {
    const id = input.getAttribute('id');
    const hasLabel = id && document.querySelector(`label[for="${id}"]`);
    const hasAriaLabel = input.hasAttribute('aria-label') || input.hasAttribute('aria-labelledby');
    return !hasLabel && !hasAriaLabel;
  });
  
  if (inputsWithoutLabels.length === 0) {
    a11yScore += 10;
  } else {
    a11yResult.issues.push({
      type: 'accessibility',
      severity: 'critical',
      message: `${inputsWithoutLabels.length} form inputs missing labels`,
      recommendation: 'Add label or aria-label to all form inputs',
      wcag: '1.3.1, 4.1.2'
    });
  }
  
  // 4. Semantic HTML (WCAG 1.3.1)
  const hasMain = document.querySelector('main') !== null;
  const hasNav = document.querySelector('nav') !== null;
  const hasSemantic = hasMain && hasNav;
  
  if (hasSemantic) {
    a11yScore += 10;
  } else {
    a11yResult.issues.push({
      type: 'accessibility',
      severity: 'warning',
      message: 'Missing semantic HTML landmarks',
      recommendation: 'Use <main>, <nav>, <header>, <footer> elements',
      wcag: '1.3.1'
    });
    a11yScore += 5;
  }
  
  // 5. Links with descriptive text (WCAG 2.4.4)
  const vagueLinks = Array.from(document.querySelectorAll('a')).filter(link => {
    const text = link.textContent.trim().toLowerCase();
    return ['click here', 'read more', 'more', 'here', 'link'].includes(text);
  });
  
  if (vagueLinks.length === 0) {
    a11yScore += 10;
  } else {
    a11yResult.issues.push({
      type: 'accessibility',
      severity: 'warning',
      message: `${vagueLinks.length} links with vague text`,
      recommendation: 'Use descriptive link text instead of "click here"',
      wcag: '2.4.4'
    });
    a11yScore += 5;
  }
  
  // 6. Color contrast (simulated check - WCAG 1.4.3)
  // Note: Full color contrast checking requires actual color computation
  const hasColorOnlyContent = html.includes('style="color:') && !html.includes('text-decoration');
  if (hasColorOnlyContent) {
    a11yResult.issues.push({
      type: 'accessibility',
      severity: 'warning',
      message: 'Potential color-only information conveying',
      recommendation: 'Ensure information is not conveyed by color alone',
      wcag: '1.4.3'
    });
    a11yScore += 5;
  } else {
    a11yScore += 10;
  }
  
  // 7. Focus management (WCAG 2.4.7)
  const focusableElements = document.querySelectorAll('a, button, input, select, textarea, [tabindex]');
  const negativTabIndex = Array.from(focusableElements).filter(el => 
    el.getAttribute('tabindex') === '-1' && !['button', 'a'].includes(el.tagName.toLowerCase())
  );
  
  if (negativTabIndex.length === 0) {
    a11yScore += 10;
  } else {
    a11yResult.issues.push({
      type: 'accessibility',
      severity: 'warning',
      message: 'Potentially problematic focus management',
      recommendation: 'Review tabindex usage and focus indicators',
      wcag: '2.4.7'
    });
    a11yScore += 5;
  }
  
  // 8. ARIA usage (WCAG 4.1.2)
  const ariaElements = document.querySelectorAll('[aria-label], [aria-labelledby], [aria-describedby], [role]');
  const hasARIA = ariaElements.length > 0;
  
  if (hasARIA) {
    a11yScore += 10;
  } else {
    a11yResult.issues.push({
      type: 'accessibility',
      severity: 'info',
      message: 'No ARIA attributes found',
      recommendation: 'Consider adding ARIA labels for enhanced accessibility',
      wcag: '4.1.2'
    });
    a11yScore += 7;
  }
  
  // 9. Page language (WCAG 3.1.1)
  const htmlLang = document.documentElement.getAttribute('lang');
  if (htmlLang) {
    a11yScore += 10;
  } else {
    a11yResult.issues.push({
      type: 'accessibility',
      severity: 'warning',
      message: 'Missing page language declaration',
      recommendation: 'Add lang attribute to <html> element',
      wcag: '3.1.1'
    });
  }
  
  // 10. Keyboard navigation (WCAG 2.1.1)
  const keyboardTraps = document.querySelectorAll('[tabindex]:not([tabindex="-1"]):not([tabindex="0"])');
  if (keyboardTraps.length === 0) {
    a11yScore += 10;
  } else {
    a11yResult.issues.push({
      type: 'accessibility',
      severity: 'warning',
      message: 'Potential keyboard navigation issues',
      recommendation: 'Use tabindex="0" or natural tab order',
      wcag: '2.1.1'
    });
    a11yScore += 5;
  }
  
  a11yResult.score = Math.round((a11yScore / (totalChecks * 10)) * 100);
  a11yResult.grade = getAccessibilityGrade(a11yResult.score);
  a11yResult.metrics = {
    totalImages: images.length,
    imagesWithAlt: images.length - imagesWithoutAlt.length,
    totalInputs: inputs.length,
    inputsWithLabels: inputs.length - inputsWithoutLabels.length,
    headingLevels: headings.map(h => h.tagName),
    wcagViolations: [...new Set(a11yResult.wcagViolations)]
  };
  
  return a11yResult;
}

/**
 * Content Quality Analysis - readability, freshness, optimization
 */
async function analyzeContentQuality(document, html, pageName) {
  const contentResult = {
    score: 0,
    grade: 'F',
    issues: [],
    metrics: {},
    readability: {}
  };
  
  // Extract main content
  const mainContent = document.querySelector('main, article, .content, #content') || document.body;
  const textContent = mainContent.textContent || '';
  const words = textContent.trim().split(/\s+/).filter(word => word.length > 0);
  const sentences = textContent.split(/[.!?]+/).filter(s => s.trim().length > 0);
  const paragraphs = textContent.split(/\n\n+/).filter(p => p.trim().length > 0);
  
  // Word count analysis
  contentResult.metrics.wordCount = words.length;
  contentResult.metrics.sentenceCount = sentences.length;
  contentResult.metrics.paragraphCount = paragraphs.length;
  
  let contentScore = 0;
  
  // 1. Content length (20 points)
  if (words.length < CONTENT_QUALITY_BUDGETS.content.minWordCount) {
    contentResult.issues.push({
      type: 'content',
      severity: 'warning',
      message: `Content too short (${words.length} words)`,
      recommendation: `Expand content to at least ${CONTENT_QUALITY_BUDGETS.content.minWordCount} words`
    });
    contentScore += 5;
  } else if (words.length < 300) {
    contentScore += 15;
  } else {
    contentScore += 20;
  }
  
  // 2. Readability score (25 points) - Flesch Reading Ease
  const readabilityScore = calculateFleschReadingEase(words.length, sentences.length, countSyllables(textContent));
  contentResult.readability = {
    fleschScore: readabilityScore,
    level: getReadabilityLevel(readabilityScore),
    avgWordsPerSentence: sentences.length > 0 ? Math.round(words.length / sentences.length) : 0,
    avgSyllablesPerWord: words.length > 0 ? countSyllables(textContent) / words.length : 0
  };
  
  if (readabilityScore >= CONTENT_QUALITY_BUDGETS.content.minReadabilityScore) {
    contentScore += 25;
  } else {
    contentResult.issues.push({
      type: 'content',
      severity: 'warning',
      message: `Low readability score (${readabilityScore.toFixed(1)})`,
      recommendation: 'Use shorter sentences and simpler words'
    });
    contentScore += Math.round(readabilityScore / 4);
  }
  
  // 3. Content structure (20 points)
  const hasHeadings = document.querySelectorAll('h2, h3').length > 0;
  const hasList = document.querySelectorAll('ul, ol').length > 0;
  const hasImages = document.querySelectorAll('img').length > 0;
  
  let structureScore = 0;
  if (hasHeadings) structureScore += 8;
  if (hasList) structureScore += 6;
  if (hasImages) structureScore += 6;
  
  if (structureScore < 15) {
    contentResult.issues.push({
      type: 'content',
      severity: 'info',
      message: 'Content lacks structure elements',
      recommendation: 'Add headings, lists, or images to improve readability'
    });
  }
  contentScore += structureScore;
  
  // 4. Content freshness (15 points)
  const lastModified = getLastModifiedDate(document, html);
  const daysSinceUpdate = lastModified ? Math.floor((Date.now() - lastModified.getTime()) / (1000 * 60 * 60 * 24)) : 999;
  
  if (daysSinceUpdate > CONTENT_QUALITY_BUDGETS.content.maxStaleContentDays) {
    contentResult.issues.push({
      type: 'content',
      severity: 'info',
      message: `Content may be stale (${daysSinceUpdate} days old)`,
      recommendation: 'Review and update content regularly'
    });
    contentScore += 5;
  } else if (daysSinceUpdate > 180) {
    contentScore += 10;
  } else {
    contentScore += 15;
  }
  
  // 5. Link quality (20 points)
  const links = document.querySelectorAll('a[href]');
  const internalLinks = Array.from(links).filter(link => {
    const href = link.getAttribute('href');
    return href && (href.startsWith('/') || href.includes(process.env.SITE_URL || 'localhost'));
  });
  const externalLinks = Array.from(links).filter(link => {
    const href = link.getAttribute('href');
    return href && href.startsWith('http') && !href.includes(process.env.SITE_URL || 'localhost');
  });
  
  contentResult.metrics.totalLinks = links.length;
  contentResult.metrics.internalLinks = internalLinks.length;
  contentResult.metrics.externalLinks = externalLinks.length;
  
  if (internalLinks.length >= 1 && externalLinks.length >= 1) {
    contentScore += 20;
  } else if (internalLinks.length >= 1 || externalLinks.length >= 1) {
    contentScore += 15;
  } else {
    contentResult.issues.push({
      type: 'content',
      severity: 'info',
      message: 'No internal or external links found',
      recommendation: 'Add relevant internal and external links'
    });
    contentScore += 5;
  }
  
  contentResult.score = Math.min(100, contentScore);
  contentResult.grade = getContentGrade(contentResult.score);
  contentResult.metrics.lastModified = lastModified;
  contentResult.metrics.daysSinceUpdate = daysSinceUpdate;
  
  return contentResult;
}

/**
 * Content Performance Analysis - loading speed, resource optimization
 */
async function analyzeContentPerformance(document, html, pageName) {
  const perfResult = {
    passed: true,
    score: 0,
    issues: [],
    metrics: {}
  };
  
  // Image performance
  const images = document.querySelectorAll('img');
  const totalImages = images.length;
  const lazyImages = Array.from(images).filter(img => img.hasAttribute('loading')).length;
  const optimizedImages = Array.from(images).filter(img => {
    const src = img.getAttribute('src') || '';
    return src.includes('.webp') || src.includes('/_astro/') || src.includes('?w=');
  }).length;
  
  perfResult.metrics.totalImages = totalImages;
  perfResult.metrics.lazyImages = lazyImages;
  perfResult.metrics.optimizedImages = optimizedImages;
  
  // CSS complexity
  const styleSheets = document.querySelectorAll('link[rel="stylesheet"], style');
  const inlineStyles = document.querySelectorAll('[style]').length;
  
  perfResult.metrics.styleSheets = styleSheets.length;
  perfResult.metrics.inlineStyles = inlineStyles;
  
  // DOM complexity
  const totalElements = document.querySelectorAll('*').length;
  const nestingDepth = calculateMaxNestingDepth(document.body);
  
  perfResult.metrics.totalElements = totalElements;
  perfResult.metrics.nestingDepth = nestingDepth;
  
  let perfScore = 100;
  
  // Check against performance budgets
  if (totalImages > 10) {
    perfResult.issues.push({
      type: 'performance',
      severity: 'warning',
      message: `High image count (${totalImages})`,
      recommendation: 'Consider lazy loading or image optimization'
    });
    perfScore -= 10;
  }
  
  if (inlineStyles > 5) {
    perfResult.issues.push({
      type: 'performance',
      severity: 'warning',
      message: `Excessive inline styles (${inlineStyles})`,
      recommendation: 'Move styles to CSS files'
    });
    perfScore -= 10;
  }
  
  if (totalElements > CONTENT_QUALITY_BUDGETS.performance.maxDOMNodes) {
    perfResult.issues.push({
      type: 'performance',
      severity: 'warning',
      message: `High DOM complexity (${totalElements} elements)`,
      recommendation: 'Simplify page structure'
    });
    perfScore -= 15;
  }
  
  if (nestingDepth > 12) {
    perfResult.issues.push({
      type: 'performance',
      severity: 'info',
      message: `Deep DOM nesting (${nestingDepth} levels)`,
      recommendation: 'Reduce nesting depth for better performance'
    });
    perfScore -= 5;
  }
  
  perfResult.score = Math.max(0, perfScore);
  perfResult.passed = perfResult.score >= 80;
  
  return perfResult;
}

/**
 * Helper functions for content analysis
 */

function getSEOGrade(score) {
  if (score >= 90) return 'A';
  if (score >= 80) return 'B';
  if (score >= 70) return 'C';
  if (score >= 60) return 'D';
  return 'F';
}

function getAccessibilityGrade(score) {
  if (score >= 95) return 'A';
  if (score >= 85) return 'B';
  if (score >= 75) return 'C';
  if (score >= 65) return 'D';
  return 'F';
}

function getContentGrade(score) {
  if (score >= 85) return 'A';
  if (score >= 75) return 'B';
  if (score >= 65) return 'C';
  if (score >= 55) return 'D';
  return 'F';
}

function calculateFleschReadingEase(wordCount, sentenceCount, syllableCount) {
  if (sentenceCount === 0 || wordCount === 0) return 0;
  return 206.835 - (1.015 * (wordCount / sentenceCount)) - (84.6 * (syllableCount / wordCount));
}

function countSyllables(text) {
  // Simple syllable counting algorithm
  const words = text.toLowerCase().match(/[a-z]+/g) || [];
  return words.reduce((total, word) => {
    let syllables = word.match(/[aeiouy]+/g) || [];
    if (word.endsWith('e')) syllables.pop();
    return total + Math.max(1, syllables.length);
  }, 0);
}

function getReadabilityLevel(score) {
  if (score >= 90) return 'Very Easy';
  if (score >= 80) return 'Easy';
  if (score >= 70) return 'Fairly Easy';
  if (score >= 60) return 'Standard';
  if (score >= 50) return 'Fairly Difficult';
  if (score >= 30) return 'Difficult';
  return 'Very Difficult';
}

function getLastModifiedDate(document, html) {
  // Try to find last modified date from various sources
  const metaModified = document.querySelector('meta[name="modified"], meta[property="article:modified_time"]');
  if (metaModified) {
    const date = new Date(metaModified.getAttribute('content'));
    if (!isNaN(date.getTime())) return date;
  }
  
  // Look for date in structured data
  const jsonLdScripts = document.querySelectorAll('script[type="application/ld+json"]');
  for (const script of jsonLdScripts) {
    try {
      const data = JSON.parse(script.textContent);
      if (data.dateModified) {
        const date = new Date(data.dateModified);
        if (!isNaN(date.getTime())) return date;
      }
    } catch (e) {
      // Skip invalid JSON-LD
    }
  }
  
  return null;
}

function calculateMaxNestingDepth(element, depth = 0) {
  if (!element.children.length) return depth;
  return Math.max(...Array.from(element.children).map(child => 
    calculateMaxNestingDepth(child, depth + 1)
  ));
}

/**
 * Check content quality budget violations
 */
function checkContentQualityBudgets(pageResult, pageName) {
  const violations = [];
  
  // SEO budget violations
  if (pageResult.seo.score < CONTENT_QUALITY_BUDGETS.seo.minScore) {
    violations.push({
      type: 'seo_score',
      page: pageName,
      current: pageResult.seo.score,
      budget: CONTENT_QUALITY_BUDGETS.seo.minScore,
      severity: 'warning'
    });
  }
  
  // Accessibility budget violations
  if (pageResult.accessibility.score < CONTENT_QUALITY_BUDGETS.accessibility.minScore) {
    violations.push({
      type: 'accessibility_score',
      page: pageName,
      current: pageResult.accessibility.score,
      budget: CONTENT_QUALITY_BUDGETS.accessibility.minScore,
      severity: 'critical'
    });
  }
  
  // Content quality violations
  if (pageResult.content.score < CONTENT_QUALITY_BUDGETS.content.minReadabilityScore) {
    violations.push({
      type: 'content_readability',
      page: pageName,
      current: pageResult.content.score,
      budget: CONTENT_QUALITY_BUDGETS.content.minReadabilityScore,
      severity: 'info'
    });
  }
  
  return violations;
}

/**
 * Generate page-specific recommendations
 */
function generatePageRecommendations(pageResult) {
  const recommendations = new Set();
  
  // SEO recommendations
  if (pageResult.seo.score < 80) {
    recommendations.add('Optimize meta tags and title for better SEO');
  }
  if (pageResult.seo.metrics.internalLinks < 2) {
    recommendations.add('Add more internal links to improve site structure');
  }
  
  // Accessibility recommendations
  if (pageResult.accessibility.score < 90) {
    recommendations.add('Fix accessibility issues for WCAG 2.1 AA compliance');
  }
  
  // Content recommendations
  if (pageResult.content.readability.fleschScore < 60) {
    recommendations.add('Improve readability with shorter sentences and simpler words');
  }
  if (pageResult.content.metrics.wordCount < 300) {
    recommendations.add('Expand content for better search engine visibility');
  }
  
  return recommendations;
}

/**
 * Auto-fix capabilities for common content quality issues
 */
async function applyContentQualityFixes(pageResult, filePath) {
  const fixes = [];
  
  // Note: Auto-fixes would modify the HTML files
  // For now, we'll just return suggested fixes
  
  if (pageResult.seo.issues.some(i => i.message.includes('Missing meta description'))) {
    fixes.push({
      type: 'suggestion',
      action: 'Add meta description tag',
      code: '<meta name="description" content="[AI-generated description based on content]">'
    });
  }
  
  if (pageResult.accessibility.issues.some(i => i.message.includes('images missing alt text'))) {
    fixes.push({
      type: 'suggestion',
      action: 'Add alt text to images',
      note: 'AI can generate descriptive alt text based on image context'
    });
  }
  
  return fixes;
}

/**
 * Generate comprehensive content quality report
 */
function generateContentQualityReport(results, mode) {
  const { pages, summary, budgetViolations, recommendations } = results;
  
  console.log('\n🎯 CONTENT QUALITY GUARDIAN REPORT\n');
  console.log('=' .repeat(50));
  
  // Overall summary
  console.log('\n📊 OVERALL SUMMARY');
  console.log(`   Total Pages: ${summary.totalPages}`);
  console.log(`   SEO Passed: ${summary.passedSEO}/${summary.totalPages} (${Math.round(summary.passedSEO/summary.totalPages*100)}%)`);
  console.log(`   A11y Passed: ${summary.passedA11y}/${summary.totalPages} (${Math.round(summary.passedA11y/summary.totalPages*100)}%)`);
  console.log(`   Content Passed: ${summary.passedContent}/${summary.totalPages} (${Math.round(summary.passedContent/summary.totalPages*100)}%)`);
  console.log(`   Performance Passed: ${summary.passedPerformance}/${summary.totalPages} (${Math.round(summary.passedPerformance/summary.totalPages*100)}%)`);
  console.log(`   Total Issues: ${summary.totalIssues} (${summary.criticalIssues} critical)`);
  
  // Budget violations
  if (budgetViolations.length > 0) {
    console.log('\n⚠️  BUDGET VIOLATIONS');
    budgetViolations.forEach(violation => {
      console.log(`   ${violation.type}: ${violation.page} (${violation.current} < ${violation.budget})`);
    });
  }
  
  // Top recommendations
  if (recommendations.size > 0) {
    console.log('\n💡 TOP RECOMMENDATIONS');
    Array.from(recommendations).slice(0, 5).forEach(rec => {
      console.log(`   • ${rec}`);
    });
  }
  
  // Page details
  console.log('\n📄 PAGE DETAILS');
  pages.forEach(page => {
    const issues = page.totalIssues;
    const status = issues === 0 ? '✅' : page.criticalIssues > 0 ? '❌' : '⚠️';
    console.log(`   ${status} ${page.page} - SEO:${page.seo.grade} A11y:${page.accessibility.grade} Content:${page.content.grade} (${issues} issues)`);
  });
  
  // Determine exit status
  const criticalViolations = budgetViolations.filter(v => v.severity === 'critical').length;
  const shouldFail = mode === 'strict' && (criticalViolations > 0 || summary.criticalIssues > 0);
  
  if (shouldFail) {
    console.log('\n❌ CONTENT QUALITY CHECK FAILED');
    console.log('   Critical issues must be resolved before proceeding.');
    return { success: false, results };
  } else {
    console.log('\n✅ CONTENT QUALITY CHECK PASSED');
    if (summary.totalIssues > 0) {
      console.log(`   ${summary.totalIssues} non-critical issues found for improvement.`);
    }
    return { success: true, results };
  }
}

/**
 * Save content quality baseline for quality gate integration
 */
async function saveContentQualityBaseline(results) {
  const baseline = {
    timestamp: new Date().toISOString(),
    summary: results.summary,
    budgetViolations: results.budgetViolations.length,
    averageScores: {
      seo: Math.round(results.pages.reduce((sum, p) => sum + p.seo.score, 0) / results.pages.length),
      accessibility: Math.round(results.pages.reduce((sum, p) => sum + p.accessibility.score, 0) / results.pages.length),
      content: Math.round(results.pages.reduce((sum, p) => sum + p.content.score, 0) / results.pages.length),
      performance: Math.round(results.pages.reduce((sum, p) => sum + p.performance.score, 0) / results.pages.length)
    }
  };
  
  try {
    writeFileSync(
      join(PROJECT_ROOT, '.content-quality-baseline.json'),
      JSON.stringify(baseline, null, 2)
    );
    
    // Append to history for trending
    const historyEntry = JSON.stringify(baseline) + '\n';
    writeFileSync(
      join(PROJECT_ROOT, '.content-quality-history.ndjson'),
      historyEntry,
      { flag: 'a' }
    );
  } catch (error) {
    console.warn('⚠️  Could not save content quality baseline:', error.message);
  }
}

// CLI interface
if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  const options = {
    mode: args.includes('--strict') ? 'strict' : args.includes('--soft') ? 'soft' : 'warning',
    target: args.find(arg => arg.startsWith('--target='))?.split('=')[1] || 'all',
    fix: args.includes('--fix')
  };
  
  const result = await runContentQualityGuardian(options);
  
  if (!result.success && process.env.CI === 'true') {
    process.exit(1);
  }
}

export { 
  runContentQualityGuardian,
  analyzePageQuality,
  analyzeSEOQuality,
  analyzeAccessibilityQuality,
  analyzeContentQuality,
  CONTENT_QUALITY_BUDGETS
};