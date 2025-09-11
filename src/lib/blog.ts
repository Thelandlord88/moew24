import { getCollection, type CollectionEntry } from 'astro:content';
export async function getAllPosts(): Promise<CollectionEntry<'posts'>[]> {
  const all = await getCollection('posts', p => !p.data.draft);
  return all.sort((a,b) => +b.data.publishDate - +a.data.publishDate);
}
export function paginate<T>(items: T[], pageSize = 12) {
  const total = Math.ceil(items.length / pageSize);
  return (page = 1) => ({ page, pageSize, total, items: items.slice((page-1)*pageSize, (page)*pageSize) });
}
