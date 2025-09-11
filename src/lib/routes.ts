/**
 * Centralized route helpers - Single source of truth for URLs
 * Replaces scattered hardcoded paths with maintainable functions
 */

export const blogRoutes = {
  /**
   * Blog index page
   */
  index: () => '/blog/',
  
  /**
   * Individual blog post
   */
  post: (slug: string) => `/blog/${slug}/`,
  
  /**
   * Blog RSS feed
   */
  rss: () => '/blog/rss.xml',
  
  /**
   * Blog category page (if needed later)
   */
  category: (category: string) => `/blog/category/${category}/`,
  
  /**
   * Blog tag page (if needed later) 
   */
  tag: (tag: string) => `/blog/tag/${tag}/`
};

export const serviceRoutes = {
  /**
   * Services index
   */
  index: () => '/services/',
  
  /**
   * Service in specific suburb
   */
  serviceSuburb: (service: string, suburb: string) => `/services/${service}/${suburb}/`
};

export const suburbRoutes = {
  /**
   * Suburbs index
   */
  index: () => '/suburbs/',
  
  /**
   * Individual suburb page
   */
  suburb: (slug: string) => `/suburbs/${slug}/`
};

export const siteRoutes = {
  /**
   * Homepage
   */
  home: () => '/',
  
  /**
   * Quote/contact page
   */
  quote: () => '/quote/',
  
  /**
   * Sitemap
   */
  sitemap: () => '/sitemap.xml'
};

// Convenience re-exports
export const routes = {
  blog: blogRoutes,
  services: serviceRoutes,
  suburbs: suburbRoutes,
  site: siteRoutes
};
