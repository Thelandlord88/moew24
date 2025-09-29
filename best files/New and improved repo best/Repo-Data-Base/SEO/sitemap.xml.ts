import { allPosts, uniqueCategories, uniqueTags, uniqueRegions } from "@/lib/blog";
import type { APIRoute } from "astro";

export const GET: APIRoute = async ({ site }) => {
  const posts = await allPosts();
  const urls = new Set<string>();

  const add = (path: string) => urls.add(new URL(path, site!).toString());

  // Index
  add("/blog/");

  // Posts
  posts.forEach((p) => add(`/blog/${p.slug}/`));

  // Category/tag/region hubs (only if content exists)
  uniqueCategories(posts).forEach((c) => add(`/blog/category/${c}/`));
  uniqueTags(posts).forEach((t) => add(`/blog/tag/${t}/`));
  uniqueRegions(posts).forEach((r) => add(`/blog/region/${r}/`));

  const body = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  ${[...urls].map((u) => `<url><loc>${u}</loc></url>`).join("")}
</urlset>`;

  return new Response(body, { headers: { "Content-Type": "application/xml" } });
};
