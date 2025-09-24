#!/usr/bin/env node
/**
 * Enhanced Sitemap Generator
 * Generates geo-aware sitemap with priority based on geographic data and content relationships
 */

import fs from 'fs';
import path from 'path';

// Simple geo data loading (avoiding Astro imports)
const DATA_DIR = path.resolve(process.cwd(), 'src/data');
const CONFIG_PATH = path.resolve(process.cwd(), 'geo.config.json');
const CONTENT_DIR = path.resolve(process.cwd(), 'src/content/posts');

function loadGeoData() {
  const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
  const clusters = JSON.parse(fs.readFileSync(path.join(DATA_DIR, 'areas.clusters.json'), 'utf8')).clusters;
  
  return { config, clusters };
}

function loadBlogPosts() {
  if (!fs.existsSync(CONTENT_DIR)) return [];
  
  const posts = [];
  const files = fs.readdirSync(CONTENT_DIR);
  
  for (const file of files) {
    if (file.endsWith('.md')) {
      const content = fs.readFileSync(path.join(CONTENT_DIR, file), 'utf8');
      const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
      
      if (frontmatterMatch) {
        try {
          // Simple YAML parsing for common fields
          const frontmatter = frontmatterMatch[1];
          const titleMatch = frontmatter.match(/title:\s*["']?(.*?)["']?\s*$/m);
          const publishDateMatch = frontmatter.match(/publishDate:\s*["']?(.*?)["']?\s*$/m);
          const draftMatch = frontmatter.match(/draft:\s*(true|false)/m);
          
          if (titleMatch && publishDateMatch) {
            const slug = file.replace('.md', '');
            const isDraft = draftMatch && draftMatch[1] === 'true';
            
            if (!isDraft) {
              posts.push({
                slug,
                title: titleMatch[1],
                publishDate: new Date(publishDateMatch[1])
              });
            }
          }
        } catch (error) {
          console.warn(`Could not parse frontmatter for ${file}:`, error.message);
        }
      }
    }
  }
  
  return posts;
}

// Sitemap configuration
const SITEMAP_CONFIG = {
  baseUrl: 'https://onedone.com.au',
  defaultChangefreq: 'weekly',
  defaultPriority: 0.5,
  priorities: {
    // Static pages
    homepage: 1.0,
    quote: 0.9,
    
    // Blog system
    blogIndex: 0.8,
    blogPost: 0.7,
    blogCategory: 0.6,
    blogTag: 0.5,
    blogRegion: 0.6,
    
    // Service pages
    serviceIndex: 0.8,
    serviceMain: 0.9,      // /services/bond-cleaning/
    serviceLocation: 0.95, // /services/bond-cleaning/brisbane/
    
    // Location pages
    suburbMain: 0.8,       // /suburbs/brisbane/
    
    // Utility pages
    sitemap: 0.3,
    robots: 0.1
  },
  changefreq: {
    static: 'monthly',
    blog: 'weekly',
    service: 'monthly',
    location: 'monthly'
  }
};

/**
 * Calculate dynamic priority based on content and geo data
 */
function calculatePriority(pageType, context = {}) {
  const { 
    suburb = null, 
    service = null, 
    postData = null,
    adjacentCount = 0,
    serviceCount = 0 
  } = context;
  
  let basePriority = SITEMAP_CONFIG.priorities[pageType] || SITEMAP_CONFIG.defaultPriority;
  
  // Boost for high-traffic areas (Brisbane gets higher priority)
  if (suburb) {
    if (suburb.includes('brisbane') || suburb.includes('city')) {
      basePriority += 0.1;
    }
    
    // Boost for well-connected suburbs (more adjacent areas)
    if (adjacentCount > 5) {
      basePriority += 0.05;
    }
  }
  
  // Boost for primary services
  if (service) {
    if (service === 'bond-cleaning') {
      basePriority += 0.1;  // Primary service
    } else if (service === 'carpet-cleaning') {
      basePriority += 0.05; // Secondary service
    }
  }
  
  // Boost for recent blog posts
  if (postData && postData.publishDate) {
    const monthsOld = (new Date() - postData.publishDate) / (1000 * 60 * 60 * 24 * 30);
    if (monthsOld < 3) {
      basePriority += 0.1;  // Recent content
    } else if (monthsOld < 6) {
      basePriority += 0.05; // Semi-recent content
    }
  }
  
  // Ensure priority stays within bounds
  return Math.min(1.0, Math.max(0.1, basePriority));
}

/**
 * Generate sitemap entry
 */
function createSitemapEntry(url, lastmod, changefreq, priority) {
  return {
    url: url.startsWith('http') ? url : `${SITEMAP_CONFIG.baseUrl}${url}`,
    lastmod: lastmod.toISOString().split('T')[0], // YYYY-MM-DD format
    changefreq,
    priority: priority.toFixed(1)
  };
}

/**
 * Generate comprehensive sitemap data
 */
async function generateSitemapData() {
  console.log('🗺️  Generating geo-aware sitemap...');
  
  const { config, clusters } = loadGeoData();
  const allPosts = loadBlogPosts();
  
  const sitemapEntries = [];
  const currentDate = new Date();
  
  // Static pages
  sitemapEntries.push(
    createSitemapEntry('/', currentDate, SITEMAP_CONFIG.changefreq.static, SITEMAP_CONFIG.priorities.homepage),
    createSitemapEntry('/quote', currentDate, SITEMAP_CONFIG.changefreq.static, SITEMAP_CONFIG.priorities.quote),
    createSitemapEntry('/blog', currentDate, SITEMAP_CONFIG.changefreq.blog, SITEMAP_CONFIG.priorities.blogIndex),
    createSitemapEntry('/blog/topics', currentDate, SITEMAP_CONFIG.changefreq.blog, 0.6)
  );
  
  // Blog posts
  const publishedPosts = allPosts.filter(post => post.title && post.publishDate);
  for (const post of publishedPosts) {
    const priority = calculatePriority('blogPost', { postData: { publishDate: post.publishDate } });
    const lastmod = post.publishDate;
    
    sitemapEntries.push(
      createSitemapEntry(`/blog/${post.slug}`, lastmod, SITEMAP_CONFIG.changefreq.blog, priority)
    );
  }
  
  // Service pages
  for (const service of config.services) {
    const priority = calculatePriority('serviceMain', { service });
    sitemapEntries.push(
      createSitemapEntry(`/services/${service}`, currentDate, SITEMAP_CONFIG.changefreq.service, priority)
    );
  }
  
  // Service + location pages (high-value combinations)
  for (const service of config.services) {
    for (const cluster of clusters) {
      // Include all major suburbs for bond-cleaning, sample others
      const suburbsToInclude = service === 'bond-cleaning' 
        ? cluster.suburbs 
        : cluster.suburbs.slice(0, 5); // Sample for other services
      
      for (const suburb of suburbsToInclude) {
        const priority = calculatePriority('serviceLocation', { 
          service, 
          suburb: suburb.slug 
        });
        
        sitemapEntries.push(
          createSitemapEntry(
            `/services/${service}/${suburb.slug}`, 
            currentDate, 
            SITEMAP_CONFIG.changefreq.service, 
            priority
          )
        );
      }
    }
  }
  
  // Suburb overview pages (major suburbs)
  for (const cluster of clusters) {
    for (const suburb of cluster.suburbs.slice(0, 10)) { // Top 10 per cluster
      const priority = calculatePriority('suburbMain', { 
        suburb: suburb.slug 
      });
      
      sitemapEntries.push(
        createSitemapEntry(
          `/suburbs/${suburb.slug}`, 
          currentDate, 
          SITEMAP_CONFIG.changefreq.location, 
          priority
        )
      );
    }
  }
  
  // Utility pages
  sitemapEntries.push(
    createSitemapEntry('/sitemap.xml', currentDate, 'weekly', SITEMAP_CONFIG.priorities.sitemap),
    createSitemapEntry('/robots.txt', currentDate, 'monthly', SITEMAP_CONFIG.priorities.robots)
  );
  
  // Sort by priority (highest first)
  sitemapEntries.sort((a, b) => parseFloat(b.priority) - parseFloat(a.priority));
  
  console.log(`✅ Generated ${sitemapEntries.length} sitemap entries`);
  console.log(`📊 Priority distribution:`);
  console.log(`   1.0: ${sitemapEntries.filter(e => e.priority === '1.0').length}`);
  console.log(`   0.9+: ${sitemapEntries.filter(e => parseFloat(e.priority) >= 0.9).length}`);
  console.log(`   0.8+: ${sitemapEntries.filter(e => parseFloat(e.priority) >= 0.8).length}`);
  console.log(`   0.7+: ${sitemapEntries.filter(e => parseFloat(e.priority) >= 0.7).length}`);
  
  return {
    entries: sitemapEntries,
    stats: {
      total: sitemapEntries.length,
      generated: currentDate.toISOString(),
      blogPosts: publishedPosts.length,
      services: config.services.length,
      suburbs: clusters.reduce((sum, cluster) => sum + cluster.suburbs.length, 0)
    }
  };
}

/**
 * Generate XML sitemap
 */
function generateXMLSitemap(sitemapData) {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${sitemapData.entries.map(entry => `  <url>
    <loc>${entry.url}</loc>
    <lastmod>${entry.lastmod}</lastmod>
    <changefreq>${entry.changefreq}</changefreq>
    <priority>${entry.priority}</priority>
  </url>`).join('\n')}
</urlset>`;
  
  return xml;
}

/**
 * Export sitemap data and XML
 */
async function exportSitemapData() {
  const sitemapData = await generateSitemapData();
  
  // Export JSON data for analysis
  const jsonPath = path.resolve(process.cwd(), 'src/data/sitemap-data.json');
  fs.writeFileSync(jsonPath, JSON.stringify(sitemapData, null, 2));
  
  // Export XML sitemap 
  const xmlPath = path.resolve(process.cwd(), 'public/sitemap-enhanced.xml');
  const xmlContent = generateXMLSitemap(sitemapData);
  fs.writeFileSync(xmlPath, xmlContent);
  
  console.log(`📄 Sitemap data exported to: ${jsonPath}`);
  console.log(`🌐 XML sitemap exported to: ${xmlPath}`);
  console.log(`🔗 View at: ${SITEMAP_CONFIG.baseUrl}/sitemap-enhanced.xml`);
  
  return sitemapData;
}

// Main execution
if (import.meta.url === `file://${process.argv[1]}`) {
  exportSitemapData().catch(console.error);
}

export { 
  generateSitemapData, 
  generateXMLSitemap, 
  exportSitemapData,
  calculatePriority 
};