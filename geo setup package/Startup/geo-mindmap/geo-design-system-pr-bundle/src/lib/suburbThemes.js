// src/lib/suburbThemes.js
import { colors } from './designTokens.js';

export const suburbThemes = {
  'ipswich': {
    primary: colors.danger[500],
    primaryHover: colors.danger[600],
    secondary: colors.danger[50],
    gradient: 'bg-gradient-to-r from-red-500 to-orange-500',
    icon: '🔥', buttonPrefix: '🔥 ', buttonSuffix: ' 🔥'
  },
  'toowong': {
    primary: colors.success[500],
    primaryHover: colors.success[600],
    secondary: colors.success[50],
    gradient: 'bg-gradient-to-r from-green-500 to-teal-500',
    icon: '🌸', buttonPrefix: '🌸 ', buttonSuffix: ' 🌸'
  },
  'kenmore': {
    primary: colors.warning[500],
    primaryHover: colors.warning[600],
    secondary: colors.warning[50],
    gradient: 'bg-gradient-to-r from-yellow-500 to-orange-500',
    icon: '☀️', buttonPrefix: '☀️ ', buttonSuffix: ' ☀️'
  },
  'st-lucia': {
    primary: colors.primary[500],
    primaryHover: colors.primary[600],
    secondary: colors.primary[100],
    gradient: 'bg-gradient-to-r from-blue-500 to-purple-500',
    icon: '🎓', buttonPrefix: '🎓 ', buttonSuffix: ' 🎓'
  },
  'indooroopilly': {
    primary: colors.warning[500],
    primaryHover: colors.warning[600],
    secondary: colors.warning[50],
    gradient: 'bg-gradient-to-r from-yellow-500 to-amber-500',
    icon: '🛍️', buttonPrefix: '🛍️ ', buttonSuffix: ' 🛍️'
  },
  default: {
    primary: colors.primary[500],
    primaryHover: colors.primary[600],
    secondary: colors.primary[100],
    gradient: 'bg-gradient-to-r from-blue-500 to-cyan-500',
    icon: '📍', buttonPrefix: '', buttonSuffix: ''
  }
};

export function getSuburbTheme(suburbSlug) {
  return suburbThemes[suburbSlug] || suburbThemes.default;
}
