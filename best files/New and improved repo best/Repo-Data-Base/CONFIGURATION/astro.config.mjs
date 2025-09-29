import { defineConfig } from 'astro/config';
import { fileURLToPath } from 'url';

export default defineConfig({
  site: 'https://onedone.com.au', // Production URL - one source of truth
  output: 'static',
  build: {
    format: 'directory'
  },
  integrations: [
    // Tailwind v4 is provided via PostCSS plugin (@tailwindcss/postcss). No Astro tailwind integration needed.
  ],
  vite: {
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url))
      }
    },
    server: {
      fs: {
        strict: false
      }
    }
  }
});
