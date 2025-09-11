import { getAllSuburbs } from '@/lib/suburbs';
import { SERVICES } from '@/lib/services';
export async function GET({ site }) {
  const base = site?.toString().replace(/\/$/, '') || '';
  const urls: string[] = [
    '/', '/blog/', '/blog/rss.xml', '/suburbs/', '/services/'
  ];
  for (const s of getAllSuburbs()) {
    urls.push(`/suburbs/${s.slug}/`);
    for (const svc of SERVICES) urls.push(`/services/${svc.slug}/${s.slug}/`);
  }
  const body = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n` +
    urls.map(u=>`  <url><loc>${base}${u}</loc></url>`).join('\n') + '\n</urlset>\n';
  return new Response(body, { headers: { 'Content-Type': 'application/xml' } });
}
