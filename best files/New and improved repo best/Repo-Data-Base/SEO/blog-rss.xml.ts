import { allPosts, buildRss } from "../../lib/blog";

export async function GET({ site }) {
  const posts = await allPosts();
  const items = posts.slice(0, 50).map((p) => ({
    title: p.data.title,
    link: new URL(`/blog/${p.slug}/`, site!).toString(),
    description: p.data.description,
    pubDate: p.data.publishDate
  }));
  const body = buildRss({
    site: new URL("/blog/", site!).toString(),
    title: "One N Done Blog",
    description: "Bond cleaning tips, guides & checklists",
    items
  });

  return new Response(body, {
    headers: { "Content-Type": "application/rss+xml; charset=utf-8" }
  });
}
