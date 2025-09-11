import { getAllSuburbs } from '@/lib/suburbs';
import { SERVICES } from '@/lib/services';
import { routes } from '@/lib/routes';
export async function GET({ site }) {
  const base = site?.toString().replace(/\/$/, '') || '';
  const urls: string[] = [
    routes.site.home(), routes.blog.index(), routes.blog.rss(), routes.suburbs.index(), routes.services.index()
  ];
  for (const s of getAllSuburbs()) {
    urls.push(routes.suburbs.suburb(s.slug));
    for (const svc of SERVICES) urls.push(routes.services.serviceSuburb(svc.slug, s.slug));
  }
  const body = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n` +
    urls.map(u=>`  <url><loc>${base}${u}</loc></url>`).join('\n') + '\n</urlset>\n';
  return new Response(body, { headers: { 'Content-Type': 'application/xml' } });
}
