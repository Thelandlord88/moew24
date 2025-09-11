import rss from '@astrojs/rss';
import { getAllPosts } from '@/lib/blog';
export async function GET(context) {
  const site = context.site?.toString().replace(/\/$/, '') || '';
  const posts = await getAllPosts();
  return rss({
    title: 'One N Done — Blog',
    description: 'Guides, checklists and tips for bond cleaning.',
    site,
    items: posts.slice(0, 50).map(p => ({
      link: `/blog/${p.slug}/`,
      title: p.data.title,
      description: p.data.description,
      pubDate: p.data.publishDate
    })),
  });
}
