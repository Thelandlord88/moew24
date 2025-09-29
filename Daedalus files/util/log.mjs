export const log = {
  info: (m) => console.log(`\x1b[36mℹ️  ${m}\x1b[0m`),
  warn: (m) => console.warn(`\x1b[33m⚠️  ${m}\x1b[0m`),
  error: (m) => console.error(`\x1b[31m❌ ${m}\x1b[0m`),
  success: (m) => console.log(`\x1b[32m✅ ${m}\x1b[0m`),
};
