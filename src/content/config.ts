import { defineCollection, z } from 'astro:content';

export const ALLOWED_CATEGORIES = [
  "checklists","guides","tips","how-to","case-studies","client-stories",
  "bond-back","end-of-lease","inspections","agent-requirements","pricing",
  "diy-vs-pro","appliance-cleaning","room-by-room","real-estate"
] as const;

export const ALLOWED_TAGS = [
  "bond-cleaning","real-estate","inspection","checklist","steam-cleaning",
  "carpet-cleaning","stain-removal","success-stories","testimonials","eco-friendly",
  "end-of-lease","agent-requirements","pricing","diy-vs-pro"
] as const;

export const ALLOWED_REGIONS = ["brisbane", "ipswich", "logan"] as const;

const posts = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string().min(4),
    description: z.string().min(10),
    publishDate: z.string().transform((s)=>new Date(s)),
    categories: z.array(z.enum(ALLOWED_CATEGORIES)).nonempty(),
    tags: z.array(z.enum(ALLOWED_TAGS)).default([]),
    region: z.enum(ALLOWED_REGIONS),
    author: z.string().default('One N Done Bond Clean'),
    draft: z.boolean().default(false)
  })
});
export const collections = { posts };
