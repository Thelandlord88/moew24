// 🎨 Design Tokens - Base styling foundation
// This provides the core design system values used across all components

export const colors = {
  // Primary brand colors
  primary: "#1e3a8a",      // Deep blue
  secondary: "#9333ea",    // Purple
  accent: "#22c55e",       // Green
  neutral: "#64748b",      // Slate gray
  
  // Semantic colors
  success: "#16a34a",      // Green
  warning: "#eab308",      // Yellow
  error: "#dc2626",        // Red
  info: "#0ea5e9",         // Sky blue
  
  // Surface colors
  background: "#ffffff",
  surface: "#f8fafc",
  border: "#e2e8f0",
  text: "#1e293b",
  textSecondary: "#64748b"
};

export const spacing = {
  xs: "4px",
  sm: "8px",
  md: "16px",
  lg: "24px",
  xl: "32px",
  "2xl": "48px",
  "3xl": "64px",
  "4xl": "96px"
};

export const typography = {
  fontFamily: {
    sans: ['Inter', 'system-ui', 'sans-serif'],
    display: ['Inter', 'system-ui', 'sans-serif']
  },
  fontSize: {
    xs: "12px",
    sm: "14px",
    base: "16px",
    lg: "18px",
    xl: "20px",
    "2xl": "24px",
    "3xl": "30px",
    "4xl": "36px",
    "5xl": "48px"
  },
  fontWeight: {
    normal: "400",
    medium: "500",
    semibold: "600",
    bold: "700"
  }
};

export const borderRadius = {
  none: "0",
  sm: "4px",
  md: "8px",
  lg: "12px",
  xl: "16px",
  "2xl": "24px",
  full: "9999px"
};

export const shadows = {
  sm: "0 1px 2px 0 rgb(0 0 0 / 0.05)",
  md: "0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)",
  lg: "0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)",
  xl: "0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)"
};