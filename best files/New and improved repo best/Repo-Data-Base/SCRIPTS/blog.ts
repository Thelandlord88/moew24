import { getCollection, type CollectionEntry } from "astro:content";
import { ALLOWED_CATEGORIES, ALLOWED_REGIONS } from "../content/config";

export type Post = CollectionEntry<"posts">;

export const POSTS_PER_PAGE = 12;

export async function allPosts() {
  const posts = await getCollection("posts", ({ data }) => data.draft !== true);
  return posts
    .sort((a, b) => +b.data.publishDate - +a.data.publishDate);
}

export function paginate<T>(items: T[], page: number, perPage = POSTS_PER_PAGE) {
  const total = items.length;
  const lastPage = Math.max(1, Math.ceil(total / perPage));
  const currentPage = Math.min(Math.max(1, page), lastPage);
  const start = (currentPage - 1) * perPage;
  const end = start + perPage;
  return {
    page: currentPage,
    perPage,
    total,
    lastPage,
    data: items.slice(start, end)
  };
}

export function slugify(s: string) {
  return s
    .toLowerCase()
    .replace(/&/g, "and")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
}

export function toCategoryPath(category: string) {
  return `/blog/category/${slugify(category)}/`;
}
export function toTagPath(tag: string) {
  return `/blog/tag/${slugify(tag)}/`;
}
export function toRegionPath(region: string) {
  return `/blog/region/${slugify(region)}/`;
}

export function uniqueCategories(posts: Post[]) {
  const set = new Set<string>();
  for (const p of posts) for (const c of p.data.categories) set.add(c);
  return [...set];
}
export function uniqueTags(posts: Post[]) {
  const set = new Set<string>();
  for (const p of posts) for (const t of p.data.tags) set.add(t);
  return [...set];
}
export function uniqueRegions(posts: Post[]) {
  const set = new Set<string>();
  for (const p of posts) if (p.data.region) set.add(p.data.region);
  return [...set] as typeof ALLOWED_REGIONS[number][];
}

export function filterByCategory(posts: Post[], category: string) {
  return posts.filter((p) => p.data.categories.includes(category as any));
}
export function filterByTag(posts: Post[], tag: string) {
  return posts.filter((p) => p.data.tags.includes(tag as any));
}
export function filterByRegion(posts: Post[], region: string) {
  return posts.filter((p) => p.data.region === region);
}

// RSS helpers
export function iso(d: Date) {
  return d.toISOString();
}
export function rssEscape(s: string) {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

/**
 * Build an RSS 2.0 feed from a list of posts.
 */
export function buildRss({
  site,
  title,
  description,
  items
}: {
  site: string;
  title: string;
  description: string;
  items: Array<{
    title: string;
    link: string;
    description?: string;
    pubDate: Date;
    guid?: string;
  }>;
}) {
  const out = `<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
  <title>${rssEscape(title)}</title>
  <link>${site}</link>
  <description>${rssEscape(description)}</description>
  <lastBuildDate>${iso(new Date())}</lastBuildDate>
  ${items
    .map(
      (it) => `
  <item>
    <title>${rssEscape(it.title)}</title>
    <link>${it.link}</link>
    <guid>${it.guid ?? it.link}</guid>
    <pubDate>${it.pubDate.toUTCString()}</pubDate>
    ${it.description ? `<description>${rssEscape(it.description)}</description>` : ""}
  </item>`
    )
    .join("\n")}
</channel>
</rss>`;
  return out.trim();
}
