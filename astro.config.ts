import netlify from '@astrojs/netlify';
import { defineConfig } from 'astro/config';
import tailwind from '@tailwindcss/vite';

export default defineConfig({
  adapter: netlify(),
  output: 'hybrid',
  site: import.meta.env.SITE_URL || 'https://example.com',
  vite: {
    plugins: [tailwind()],
  },
});
