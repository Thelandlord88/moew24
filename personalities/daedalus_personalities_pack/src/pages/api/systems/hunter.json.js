// Auto-exposed system personality
import { readFile } from 'node:fs/promises';
export async function GET() {
  const data = JSON.parse(await readFile(new URL('../../../../profiles/hunter.json', import.meta.url), 'utf8'));
  return new Response(JSON.stringify(data, null, 2), { headers: { 'content-type': 'application/json; charset=utf-8' } });
}
