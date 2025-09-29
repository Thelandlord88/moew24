import { allPosts, filterByTag, buildRss } from "../../../../lib/blog";

export async function getStaticPaths() {
  const posts = await allPosts();
  const tags = new Set<string>();
  posts.forEach(p => p.data.tags.forEach(t => tags.add(t)));
  return [...tags].map((t) => ({ params: { tag: t } }));
}

export async function GET({ site, params }) {
  const tag = params.tag!;
  const posts = filterByTag(await allPosts(), tag);
  const items = posts.slice(0, 50).map((p) => ({
    title: p.data.title,
    link: new URL(`/blog/${p.slug}/`, site!).toString(),
    description: p.data.description,
    pubDate: p.data.publishDate
  }));
  const body = buildRss({
    site: new URL(`/blog/tag/${tag}/`, site!).toString(),
    title: `Tag: ${tag}`,
    description: `Articles tagged ${tag}`,
    items
  });
  return new Response(body, { headers: { "Content-Type": "application/rss+xml; charset=utf-8" } });
}
