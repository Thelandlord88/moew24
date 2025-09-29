// Design Token System
// NEXUS CSS Architect Enhancement

export const DesignTokens = {
    // Color system with semantic meanings
    colors: {
        brand: {
            primary: '#2563eb',
            secondary: '#64748b', 
            accent: '#f59e0b'
        },
        
        // Service-specific theming
        services: {
            'bond-cleaning': {
                primary: '#10b981',
                secondary: '#065f46',
                light: '#d1fae5'
            },
            'carpet-cleaning': {
                primary: '#f59e0b', 
                secondary: '#92400e',
                light: '#fef3c7'
            },
            'pest-control': {
                primary: '#dc2626',
                secondary: '#991b1b', 
                light: '#fee2e2'
            }
        },
        
        // Semantic colors
        semantic: {
            success: '#10b981',
            warning: '#f59e0b',
            error: '#ef4444',
            info: '#3b82f6'
        },
        
        // Neutral palette
        neutral: {
            50: '#f8fafc',
            100: '#f1f5f9', 
            200: '#e2e8f0',
            300: '#cbd5e1',
            400: '#94a3b8',
            500: '#64748b',
            600: '#475569',
            700: '#334155',
            800: '#1e293b',
            900: '#0f172a'
        }
    },
    
    // Typography scale
    typography: {
        fontFamily: {
            sans: ['Inter', 'system-ui', 'sans-serif'],
            serif: ['Georgia', 'serif'],
            mono: ['JetBrains Mono', 'monospace']
        },
        
        fontSize: {
            xs: ['0.75rem', { lineHeight: '1rem' }],
            sm: ['0.875rem', { lineHeight: '1.25rem' }],
            base: ['1rem', { lineHeight: '1.5rem' }],
            lg: ['1.125rem', { lineHeight: '1.75rem' }],
            xl: ['1.25rem', { lineHeight: '1.75rem' }],
            '2xl': ['1.5rem', { lineHeight: '2rem' }],
            '3xl': ['1.875rem', { lineHeight: '2.25rem' }],
            '4xl': ['2.25rem', { lineHeight: '2.5rem' }]
        },
        
        fontWeight: {
            normal: '400',
            medium: '500', 
            semibold: '600',
            bold: '700'
        }
    },
    
    // Spacing scale (8px base)
    spacing: {
        0: '0',
        1: '0.25rem',   // 4px
        2: '0.5rem',    // 8px
        3: '0.75rem',   // 12px
        4: '1rem',      // 16px
        5: '1.25rem',   // 20px
        6: '1.5rem',    // 24px
        8: '2rem',      // 32px
        10: '2.5rem',   // 40px
        12: '3rem',     // 48px
        16: '4rem',     // 64px
        20: '5rem',     // 80px
        24: '6rem'      // 96px
    },
    
    // Component tokens
    components: {
        button: {
            padding: {
                sm: '0.5rem 1rem',
                md: '0.75rem 1.5rem',
                lg: '1rem 2rem'
            },
            borderRadius: '0.375rem',
            fontSize: {
                sm: '0.875rem',
                md: '1rem', 
                lg: '1.125rem'
            }
        },
        
        card: {
            padding: '1.5rem',
            borderRadius: '0.5rem',
            shadow: '0 1px 3px 0 rgb(0 0 0 / 0.1)',
            border: '1px solid rgb(226 232 240)'
        }
    },
    
    // Responsive breakpoints
    screens: {
        sm: '640px',
        md: '768px', 
        lg: '1024px',
        xl: '1280px',
        '2xl': '1536px'
    }
};

// Token utilities for component generation
export class TokenProcessor {
    static generateCSS(tokens) {
        let css = ':root {\n';
        
        // Generate CSS custom properties
        for (const [category, values] of Object.entries(tokens)) {
            if (typeof values === 'object' && values !== null) {
                css += this.processTokenCategory(category, values, '  ');
            }
        }
        
        css += '}\n';
        return css;
    }
    
    static processTokenCategory(category, values, indent = '') {
        let css = '';
        
        for (const [key, value] of Object.entries(values)) {
            if (typeof value === 'object' && value !== null) {
                css += this.processTokenCategory(`${category}-${key}`, value, indent);
            } else {
                css += `${indent}--${category}-${key}: ${value};\n`;
            }
        }
        
        return css;
    }
    
    static getToken(path, tokens = DesignTokens) {
        return path.split('.').reduce((obj, key) => obj?.[key], tokens);
    }
    
    static generateServiceTheme(service) {
        const serviceColors = DesignTokens.colors.services[service];
        if (!serviceColors) return {};
        
        return {
            [`--service-primary`]: serviceColors.primary,
            [`--service-secondary`]: serviceColors.secondary,
            [`--service-light`]: serviceColors.light
        };
    }
}
