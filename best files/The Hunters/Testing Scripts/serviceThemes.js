// 🏢 Service Themes - Unique branding for each cleaning service
// Each service gets its own color scheme and visual identity

import { colors } from './designTokens.js';

export const serviceThemes = {
  "bond-cleaning": {
    name: "Bond Cleaning",
    primaryColor: "#0ea5e9",      // Professional sky blue
    secondaryColor: "#0284c7",     // Darker blue
    accentColor: "#38bdf8",        // Light blue accent
    textColor: "#0c4a6e",          // Dark blue text
    bgGradient: "from-sky-50 to-blue-50",
    icon: "🏠",
    tagline: "Get your bond back, guaranteed",
    description: "Professional end-of-lease cleaning with 100% bond back guarantee",
    features: [
      "100% Bond Back Guarantee",
      "Comprehensive checklist cleaning", 
      "Professional carpet steam cleaning",
      "Oven and kitchen deep clean",
      "Bathroom sanitization",
      "Window cleaning included"
    ],
    priceRange: "From $299"
  },
  
  "house-cleaning": {
    name: "House Cleaning", 
    primaryColor: "#16a34a",       // Fresh green
    secondaryColor: "#15803d",     // Darker green
    accentColor: "#22c55e",        // Bright green accent
    textColor: "#14532d",          // Dark green text
    bgGradient: "from-green-50 to-emerald-50",
    icon: "✨",
    tagline: "Keep your home spotless",
    description: "Regular house cleaning services for a consistently clean home",
    features: [
      "Weekly, fortnightly, or monthly service",
      "Fully insured and bonded cleaners",
      "Eco-friendly cleaning products", 
      "Customizable cleaning checklist",
      "Satisfaction guarantee",
      "Same cleaner every visit"
    ],
    priceRange: "From $199"
  },
  
  "carpet-cleaning": {
    name: "Carpet Cleaning",
    primaryColor: "#9333ea",       // Rich purple
    secondaryColor: "#7c3aed",     // Darker purple  
    accentColor: "#a855f7",        // Light purple accent
    textColor: "#581c87",          // Dark purple text
    bgGradient: "from-purple-50 to-violet-50",
    icon: "🧽",
    tagline: "Deep clean for healthier carpets",
    description: "Professional carpet steam cleaning for fresher, healthier homes",
    features: [
      "Hot water extraction method",
      "Pet odor and stain removal",
      "Eco-friendly cleaning solutions",
      "Fast drying technology", 
      "Furniture moving included",
      "Satisfaction guarantee"
    ],
    priceRange: "From $149"
  },
  
  "oven-cleaning": {
    name: "Oven Cleaning",
    primaryColor: "#ea580c",       // Warm orange
    secondaryColor: "#dc2626",     // Red-orange
    accentColor: "#fb923c",        // Light orange accent
    textColor: "#9a3412",          // Dark orange text
    bgGradient: "from-orange-50 to-red-50",
    icon: "🔥",
    tagline: "Sparkling clean ovens, every time",
    description: "Deep oven cleaning using specialized techniques and products",
    features: [
      "Complete oven disassembly",
      "Non-toxic cleaning products",
      "Range hood cleaning included",
      "Cooktop and grill cleaning",
      "Same-day service available", 
      "100% satisfaction guarantee"
    ],
    priceRange: "From $89"
  }
};