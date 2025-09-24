// src/lib/theme/serviceThemes.ts
import type { ServiceTheme } from './tokens';

export const serviceThemes: Record<string, ServiceTheme> = {
  'bond-cleaning': {
    brand: { primary: '#0ea5e9', onPrimary: 'white' },
    accent: { a: '#34d399', b: '#60a5fa' }
  },
  'spring-cleaning': {
    brand: { primary: '#16a34a', onPrimary: 'white' },
    accent: { a: '#22d3ee', b: '#a78bfa' }
  },
  'bathroom-deep-clean': {
    brand: { primary: '#9333ea', onPrimary: 'white' },
    accent: { a: '#f59e0b', b: '#06b6d4' }
  }
};
