// 🎭 Theme Provider - Combines service and suburb themes dynamically
// This creates the final theme object used by components

import * as tokens from './designTokens.js';
import { serviceThemes } from './serviceThemes.js';
import { suburbThemes } from './suburbThemes.js';

export function createTheme(serviceSlug, suburbSlug) {
  // Get base tokens
  const base = { ...tokens };
  
  // Get service-specific theme
  const serviceTheme = serviceThemes[serviceSlug] || {};
  
  // Get suburb-specific theme  
  const suburbTheme = suburbThemes[suburbSlug] || {};
  
  // Merge themes (suburb overrides service, which overrides base)
  const theme = {
    ...base,
    
    // Service theming takes precedence for functional colors
    primaryColor: serviceTheme.primaryColor || base.colors.primary,
    secondaryColor: serviceTheme.secondaryColor || base.colors.secondary,
    serviceAccent: serviceTheme.accentColor || base.colors.accent,
    
    // Suburb theming for local customization
    suburbAccent: suburbTheme.accentColor || serviceTheme.accentColor || base.colors.accent,
    bannerImage: suburbTheme.bannerImage || '/images/default-banner.jpg',
    bgPattern: suburbTheme.bgPattern || 'none',
    
    // Combined data for components
    service: serviceTheme,
    suburb: suburbTheme,
    
    // CSS variables for Tailwind arbitrary values
    cssVars: {
      '--primary-color': serviceTheme.primaryColor || base.colors.primary,
      '--secondary-color': serviceTheme.secondaryColor || base.colors.secondary,
      '--accent-color': suburbTheme.accentColor || serviceTheme.accentColor || base.colors.accent,
      '--text-color': serviceTheme.textColor || base.colors.text,
      '--service-accent': serviceTheme.accentColor || base.colors.accent,
      '--suburb-accent': suburbTheme.accentColor || base.colors.accent
    }
  };
  
  return theme;
}

// Helper to generate CSS variable style string
export function getThemeStyles(theme) {
  return Object.entries(theme.cssVars)
    .map(([key, value]) => `${key}: ${value}`)
    .join('; ');
}

// Helper to get adjacent suburbs for navigation
export function getAdjacentSuburbs(suburbSlug) {
  const suburbTheme = suburbThemes[suburbSlug];
  return suburbTheme?.adjacentSuburbs || [];
}

// Helper to get all available services
export function getAvailableServices() {
  return Object.keys(serviceThemes);
}

// Helper to get service by slug
export function getService(serviceSlug) {
  return serviceThemes[serviceSlug];
}

// Helper to get suburb by slug  
export function getSuburb(suburbSlug) {
  return suburbThemes[suburbSlug];
}