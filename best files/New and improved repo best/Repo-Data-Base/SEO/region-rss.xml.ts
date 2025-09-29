import { allPosts, filterByRegion, buildRss } from "../../../../lib/blog";

export async function getStaticPaths() {
  const posts = await allPosts();
  const regions = new Set<string>();
  posts.forEach(p => { if (p.data.region) regions.add(p.data.region); });
  return [...regions].map((r) => ({ params: { region: r } }));
}

export async function GET({ site, params }) {
  const region = params.region!;
  const posts = filterByRegion(await allPosts(), region);
  const items = posts.slice(0, 50).map((p) => ({
    title: p.data.title,
    link: new URL(`/blog/${p.slug}/`, site!).toString(),
    description: p.data.description,
    pubDate: p.data.publishDate
  }));
  const body = buildRss({
    site: new URL(`/blog/region/${region}/`, site!).toString(),
    title: `Region: ${region}`,
    description: `Articles for ${region}`,
    items
  });
  return new Response(body, { headers: { "Content-Type": "application/rss+xml; charset=utf-8" } });
}
