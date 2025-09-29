import { defineCollection, z } from "astro:content";

/**
 * Geo-aware content collections with suburb-level targeting
 * Integrates with geo data layer for dynamic service+location content
 */

// Import geo configuration for validation
import { geoConfig } from '../lib/geoCompat.ts';

// Load services from geo config
const config = geoConfig();

/**
 * Authoritative enumerations — update these to match your live taxonomy.
 * IMPORTANT: Blog routes are generated *only* from posts that use values in these sets.
 */
export const ALLOWED_CATEGORIES = [
  "checklists",
  "guides", 
  "tips",
  "how-to",
  "case-studies",
  "client-stories", 
  "success-stories",
  "testimonials",
  "bond-back",
  "end-of-lease",
  "inspections",
  "agent-requirements",
  "eco-friendly",
  "stain-removal",
  "carpet-cleaning", 
  "steam-cleaning",
  "moving-out",
  "quick-clean",
  "maintenance",
  "standards",
  "pricing",
  "diy-vs-pro",
  "before-after", 
  "room-by-room",
  "appliance-cleaning",
  "pet-friendly",
  "product-tools",
  "safety",
  "real-estate"
] as const;

export const ALLOWED_TAGS = [
  "bond-cleaning",
  "bond-return",
  "checklist",
  "cleaning-tips",
  "customer-reviews",
  "eco-friendly",
  "end-of-lease",
  "environmental",
  "green-cleaning",
  "inspection",
  "inspections",
  "maintenance",
  "moving-out",
  "non-toxic",
  "quick-clean",
  "real-estate",
  "rental-maintenance",
  "rental",
  "stain-removal",
  "standards",
  "steam-cleaning",
  "success-stories",
  "testimonials",
  "carpet-cleaning",
  "agent-requirements",
  "logan-area",
  "diy-vs-pro",
  "oven-cleaning",
  "appliance-cleaning",
  "timeline",
  "cost-analysis",
  "budget"
] as const;

export const ALLOWED_REGIONS = [
  "brisbane",
  "ipswich", 
  "logan"
] as const;

// Services from geo config
// Services from geo config
export const ALLOWED_SERVICES = config.services;

const postSchema = z.object({
  title: z.string().min(3),
  description: z.string().min(10),
  publishDate: z.string().transform((s: string) => new Date(s)),
  updatedDate: z.string().optional().transform((s?: string) => (s ? new Date(s) : undefined)),
  heroImage: z.string().optional(),
  // zero or more categories from the allowed set:
  categories: z.array(z.enum(ALLOWED_CATEGORIES)).default([]),
  // zero or more tags from the allowed set:
  tags: z.array(z.enum(ALLOWED_TAGS)).default([]),
  // optional region targeting:
  region: z.enum(ALLOWED_REGIONS).optional(),
  // NEW: service targeting for geo-aware content
  service: z.enum(ALLOWED_SERVICES as [string, ...string[]]).optional(),
  // NEW: suburb-level targeting (validated against geo data)
  suburbs: z.array(z.string().regex(/^[a-z0-9-]+$/)).default([]),
  // optional canonical override (absolute URL)
  canonical: z.string().url().optional(),
  // optional author
  author: z.string().default("One N Done Bond Clean"),
  // optional draft flag
  draft: z.boolean().default(false),
  // NEW: SEO enhancements
  seo: z.object({
    noindex: z.boolean().default(false),
    priority: z.number().min(0).max(1).default(0.7),
    changefreq: z.enum(['always', 'hourly', 'daily', 'weekly', 'monthly', 'yearly', 'never']).default('weekly')
  }).optional()
});

const posts = defineCollection({
  type: "content",
  schema: postSchema
});

export const collections = { posts };
