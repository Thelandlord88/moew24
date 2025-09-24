// src/lib/theme/tokens.ts
export type ThemeTokens = {
  brand: {
    primary: string;
    onPrimary: string;
  };
  surface: {
    base: string;
    raised: string;
    on: string;
    border: string;
  };
  accent: {
    a: string;
    b: string;
  };
};

export type ServiceTheme = Partial<ThemeTokens> & { id?: string };
export type SuburbTheme = Partial<ThemeTokens> & { id?: string };

const DEFAULT_TOKENS: ThemeTokens = {
  brand: { primary: '#0ea5e9', onPrimary: 'white' },
  surface: { base: 'white', raised: '#0b1220', on: '#0b1220', border: 'rgba(2,6,23,.08)' },
  accent: { a: '#22c55e', b: '#a855f7' },
};

function deepMerge<T>(a: Partial<T>, b: Partial<T>): T {
  const out: any = { ...(a as any) };
  for (const k of Object.keys(b || {})) {
    const v = (b as any)[k];
    if (v && typeof v === 'object' && !Array.isArray(v)) {
      out[k] = deepMerge((out[k] || {}), v);
    } else if (v !== undefined) {
      out[k] = v;
    }
  }
  return out as T;
}

export function tokensToCssVars(t: ThemeTokens) {
  return {
    '--brand-primary': t.brand.primary,
    '--brand-onPrimary': t.brand.onPrimary,
    '--surface-base': t.surface.base,
    '--surface-raised': t.surface.raised,
    '--surface-on': t.surface.on,
    '--surface-border': t.surface.border,
    '--accent-a': t.accent.a,
    '--accent-b': t.accent.b,
  };
}

export function mergeThemeTokens(
  serviceTheme: ServiceTheme | undefined,
  suburbTheme: SuburbTheme | undefined
): ThemeTokens {
  return deepMerge<ThemeTokens>(DEFAULT_TOKENS, deepMerge<ThemeTokens>(serviceTheme || {}, suburbTheme || {}));
}
