import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/postcss';

export default defineConfig({
  site: 'https://onendonebondclean.com.au',
  server: { port: 4321 },
  vite: {
    resolve: { alias: { '@': '/src' } },
    css: { postcss: { plugins: [tailwindcss] } },
  },
});
