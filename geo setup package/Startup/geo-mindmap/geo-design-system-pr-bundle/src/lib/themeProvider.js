// src/lib/themeProvider.js
import { getSuburbTheme } from './suburbThemes.js';
import { getServiceTheme } from './serviceThemes.js';

export class ThemeProvider {
  constructor(suburbSlug, serviceSlug) {
    this.suburbSlug = suburbSlug;
    this.serviceSlug = serviceSlug;
    this.suburbTheme = getSuburbTheme(suburbSlug);
    this.serviceTheme = getServiceTheme(serviceSlug);
  }

  // Classes that use Tailwind arbitrary values bound to CSS variables.
  // We set the CSS variables via style="" on the element.
  getButtonTheme(variant = 'primary') {
    const themes = {
      primary: {
        classes: 'text-white bg-[var(--btn-bg)] hover:bg-[var(--btn-hover)] border border-[var(--btn-border)]',
        style: `--btn-bg:${this.serviceTheme.color};--btn-hover:${this.serviceTheme.colorHover};--btn-border:${this.serviceTheme.color};`
      },
      secondary: {
        classes: 'text-gray-900 bg-[var(--btn-bg)] hover:bg-[var(--btn-hover)] border border-[var(--btn-border)]',
        style: `--btn-bg:${this.suburbTheme.secondary};--btn-hover:${this.suburbTheme.primaryHover};--btn-border:${this.suburbTheme.primary};`
      },
      gradient: {
        classes: `${this.suburbTheme.gradient} text-white hover:opacity-90 border-0`,
        style: ''
      }
    };
    return themes[variant] || themes.primary;
  }

  getSuburbButtonConfig(buttonType = 'quote') {
    const special = {
      ipswich: {
        'bond-cleaning': { text: `${this.suburbTheme.buttonPrefix}Premium Bond Cleaning Quote${this.suburbTheme.buttonSuffix}`, size: 'large', variant: 'gradient' }
      },
      toowong: {
        'spring-cleaning': { text: `${this.suburbTheme.buttonPrefix}Eco-Friendly Spring Cleaning${this.suburbTheme.buttonSuffix}`, size: 'large', variant: 'gradient' }
      },
      kenmore: {
        'bathroom-deep-clean': { text: `${this.suburbTheme.buttonPrefix}Luxury Bathroom Cleaning${this.suburbTheme.buttonSuffix}`, size: 'large', variant: 'gradient' }
      }
    };
    if (special[this.suburbSlug] && special[this.suburbSlug][this.serviceSlug]) {
      return special[this.suburbSlug][this.serviceSlug];
    }
    const defaults = {
      quote: { text: `Get Your Free ${this.serviceTheme.name} Quote`, size: 'medium', variant: 'primary' },
      learn: { text: `Learn More About ${this.serviceTheme.name}`, size: 'medium', variant: 'secondary' },
      book:  { text: `Book ${this.serviceTheme.name} Now`, size: 'medium', variant: 'primary' }
    };
    return defaults[buttonType] || defaults.quote;
  }

  getSizeClasses(size = 'medium') {
    const sizes = { small:'px-3 py-1 text-sm', medium:'px-4 py-2', large:'px-6 py-3 text-lg', xl:'px-8 py-4 text-xl' };
    return sizes[size] || sizes.medium;
  }
}

export function createTheme(suburbSlug, serviceSlug) {
  return new ThemeProvider(suburbSlug, serviceSlug);
}
