// src/lib/theme/tokens.ts
/**
 * Advanced Design System Tokens
 * Location-aware theming with service-specific color schemes
 */

export interface ThemeTokens {
  brand: {
    primary: string;
    secondary: string;
    accent: string;
    onPrimary: string;
    onSecondary: string;
  };
  surface: {
    base: string;
    elevated: string;
    raised: string;
    interactive: string;
    on: string;
    onVariant: string;
    border: string;
    borderLight: string;
  };
  semantic: {
    success: string;
    warning: string;
    error: string;
    info: string;
    onSuccess: string;
    onWarning: string;
    onError: string;
    onInfo: string;
  };
  typography: {
    heading: string;
    body: string;
    caption: string;
    label: string;
  };
  spacing: {
    xs: string;
    sm: string;
    md: string;
    lg: string;
    xl: string;
    xxl: string;
  };
  shadows: {
    sm: string;
    md: string;
    lg: string;
    xl: string;
  };
  transitions: {
    fast: string;
    medium: string;
    slow: string;
  };
}

// Service-specific color schemes
export const serviceThemes: Record<string, Partial<ThemeTokens>> = {
  'bond-cleaning': {
    brand: {
      primary: '#0369a1', // Strong blue for trust/reliability
      secondary: '#0284c7',
      accent: '#22d3ee',
      onPrimary: '#ffffff',
      onSecondary: '#ffffff',
    },
    semantic: {
      success: '#059669',
      warning: '#d97706',
      error: '#dc2626',
      info: '#2563eb',
      onSuccess: '#ffffff',
      onWarning: '#ffffff',
      onError: '#ffffff',
      onInfo: '#ffffff',
    }
  },
  'spring-clean': {
    brand: {
      primary: '#059669', // Fresh green for renewal
      secondary: '#10b981',
      accent: '#34d399',
      onPrimary: '#ffffff',
      onSecondary: '#ffffff',
    }
  },
  'bathroom-deep-clean': {
    brand: {
      primary: '#7c3aed', // Purple for premium/deep clean
      secondary: '#8b5cf6',
      accent: '#a78bfa',
      onPrimary: '#ffffff',
      onSecondary: '#ffffff',
    }
  },
  'house-cleaning': {
    brand: {
      primary: '#ea580c', // Warm orange for home/comfort
      secondary: '#f97316',
      accent: '#fb923c',
      onPrimary: '#ffffff',
      onSecondary: '#ffffff',
    }
  }
};

// Base theme tokens
export const baseTheme: ThemeTokens = {
  brand: {
    primary: '#0369a1',
    secondary: '#0284c7',
    accent: '#22d3ee',
    onPrimary: '#ffffff',
    onSecondary: '#ffffff',
  },
  surface: {
    base: '#ffffff',
    elevated: '#f8fafc',
    raised: '#f1f5f9',
    interactive: '#e2e8f0',
    on: '#0f172a',
    onVariant: '#475569',
    border: '#e2e8f0',
    borderLight: '#f1f5f9',
  },
  semantic: {
    success: '#059669',
    warning: '#d97706',
    error: '#dc2626',
    info: '#2563eb',
    onSuccess: '#ffffff',
    onWarning: '#ffffff',
    onError: '#ffffff',
    onInfo: '#ffffff',
  },
  typography: {
    heading: '#0f172a',
    body: '#334155',
    caption: '#64748b',
    label: '#475569',
  },
  spacing: {
    xs: '0.25rem',
    sm: '0.5rem',
    md: '1rem',
    lg: '1.5rem',
    xl: '2rem',
    xxl: '3rem',
  },
  shadows: {
    sm: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
    md: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)',
    lg: '0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)',
    xl: '0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)',
  },
  transitions: {
    fast: '150ms cubic-bezier(0.4, 0, 0.2, 1)',
    medium: '300ms cubic-bezier(0.4, 0, 0.2, 1)',
    slow: '500ms cubic-bezier(0.4, 0, 0.2, 1)',
  },
};

// Location-based theme modifiers (deep partial)
type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};

export const locationThemes: Record<string, DeepPartial<ThemeTokens>> = {
  'brisbane-city': {
    brand: {
      accent: '#3b82f6', // Corporate blue
    }
  },
  'logan-city': {
    brand: {
      accent: '#10b981', // Growth green
    }
  },
  'ipswich-city': {
    brand: {
      accent: '#f59e0b', // Heritage gold
    }
  }
};

/**
 * Create theme tokens for specific service and location
 */
export function createTheme(service?: string, location?: string): ThemeTokens {
  let theme = { ...baseTheme };
  
  // Apply service-specific theming
  if (service && serviceThemes[service]) {
    theme = mergeThemes(theme, serviceThemes[service]);
  }
  
  // Apply location-specific theming
  if (location && locationThemes[location]) {
    theme = deepMergeThemes(theme, locationThemes[location]);
  }
  
  return theme;
}

function mergeThemes(base: ThemeTokens, override: Partial<ThemeTokens>): ThemeTokens {
  return {
    ...base,
    brand: { ...base.brand, ...override.brand },
    surface: { ...base.surface, ...override.surface },
    semantic: { ...base.semantic, ...override.semantic },
    typography: { ...base.typography, ...override.typography },
    spacing: { ...base.spacing, ...override.spacing },
    shadows: { ...base.shadows, ...override.shadows },
    transitions: { ...base.transitions, ...override.transitions },
  };
}

function deepMergeThemes(base: ThemeTokens, override: DeepPartial<ThemeTokens>): ThemeTokens {
  return {
    ...base,
    brand: { ...base.brand, ...override.brand },
    surface: { ...base.surface, ...override.surface },
    semantic: { ...base.semantic, ...override.semantic },
    typography: { ...base.typography, ...override.typography },
    spacing: { ...base.spacing, ...override.spacing },
    shadows: { ...base.shadows, ...override.shadows },
    transitions: { ...base.transitions, ...override.transitions },
  };
}
