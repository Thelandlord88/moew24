import { defineConfig } from '@playwright/test';
export default defineConfig({
  retries: 2,
  forbidOnly: !!process.env.CI,
  reporter: process.env.CI ? 'github' : [['list']],
  use: { trace: 'retain-on-failure' }
});
