// src/lib/serviceThemes.js
import { colors } from './designTokens.js';

export const serviceThemes = {
  'bond-cleaning': {
    name: 'Bond Cleaning',
    color: colors.danger[500],
    colorHover: colors.danger[600],
    backgroundColor: colors.danger[50],
    gradient: 'bg-gradient-to-r from-red-500 to-pink-500',
    icon: '🏠',
    description: 'Get your full bond back with our thorough cleaning service.'
  },
  'spring-cleaning': {
    name: 'Spring Cleaning',
    color: colors.success[500],
    colorHover: colors.success[600],
    backgroundColor: colors.success[50],
    gradient: 'bg-gradient-to-r from-green-500 to-emerald-500',
    icon: '🌿',
    description: 'Deep clean your home to welcome the new season.'
  },
  'bathroom-deep-clean': {
    name: 'Bathroom Deep Cleaning',
    color: colors.primary[500],
    colorHover: colors.primary[600],
    backgroundColor: colors.primary[50],
    gradient: 'bg-gradient-to-r from-blue-500 to-indigo-500',
    icon: '🚿',
    description: 'Eliminate mold and grime with our intensive bathroom cleaning.'
  },
  default: {
    name: 'Service',
    color: colors.primary[500],
    colorHover: colors.primary[600],
    backgroundColor: colors.primary[50],
    gradient: 'bg-gradient-to-r from-blue-500 to-cyan-500',
    icon: '✨',
    description: 'Professional cleaning services for your home.'
  }
};

export function getServiceTheme(serviceSlug) {
  return serviceThemes[serviceSlug] || serviceThemes.default;
}
