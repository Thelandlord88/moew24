// 🗺️ Suburb Themes - Location-specific customizations
// Each suburb can have unique styling, images, or highlights

import { colors } from './designTokens.js';

export const suburbThemes = {
  "brisbane-city": {
    name: "Brisbane City",
    region: "brisbane",
    postcode: "4000",
    description: "The heart of Brisbane with vibrant city life and commercial activity",
    population: 12000,
    coordinates: { lat: -27.4698, lng: 153.0251 },
    
    // Visual customization
    accentColor: "#0ea5e9",        // City blue
    bannerImage: "/images/banners/brisbane-city.jpg",
    bgPattern: "city-skyline",
    
    // Local highlights
    highlights: [
      "Central business district location",
      "High-rise apartment specialist", 
      "Premium office cleaning",
      "24/7 emergency service available"
    ],
    
    // Nearby suburbs for navigation
    adjacentSuburbs: ["south-brisbane", "west-end", "fortitude-valley"]
  },
  
  "springfield-lakes": {
    name: "Springfield Lakes",
    region: "ipswich", 
    postcode: "4300",
    description: "Family-friendly master-planned community with lakes and parks",
    population: 8500,
    coordinates: { lat: -27.6661, lng: 152.9208 },
    
    // Visual customization  
    accentColor: "#14b8a6",        // Teal for lakes
    bannerImage: "/images/banners/springfield-lakes.jpg",
    bgPattern: "water-ripples",
    
    // Local highlights
    highlights: [
      "Family home specialist",
      "Lake-view property expertise",
      "School holiday specials",
      "Community-focused service"
    ],
    
    // Nearby suburbs
    adjacentSuburbs: ["springfield", "camira", "brookwater"]
  },
  
  "ipswich": {
    name: "Ipswich",
    region: "ipswich",
    postcode: "4305", 
    description: "Historic city with heritage buildings and growing residential areas",
    population: 15000,
    coordinates: { lat: -27.6171, lng: 152.7636 },
    
    // Visual customization
    accentColor: "#9333ea",        // Heritage purple
    bannerImage: "/images/banners/ipswich.jpg", 
    bgPattern: "heritage-pattern",
    
    // Local highlights
    highlights: [
      "Heritage building specialist",
      "Established community trust",
      "Traditional cleaning methods",
      "Local family business"
    ],
    
    // Nearby suburbs
    adjacentSuburbs: ["booval", "bundamba", "raceview"]
  },
  
  "logan-central": {
    name: "Logan Central",
    region: "logan",
    postcode: "4114",
    description: "Major commercial and transport hub for the Logan region", 
    population: 12500,
    coordinates: { lat: -27.6389, lng: 153.1094 },
    
    // Visual customization
    accentColor: "#16a34a",        // Growth green
    bannerImage: "/images/banners/logan-central.jpg",
    bgPattern: "transport-lines",
    
    // Local highlights  
    highlights: [
      "Transport hub convenience",
      "Commercial cleaning expertise",
      "Multicultural community focus",
      "Flexible scheduling"
    ],
    
    // Nearby suburbs
    adjacentSuburbs: ["woodridge", "slacks-creek", "kingston"]
  },
  
  "west-end": {
    name: "West End",
    region: "brisbane", 
    postcode: "4101",
    description: "Trendy inner-city suburb known for its multicultural community",
    population: 10000,
    coordinates: { lat: -27.4845, lng: 153.0074 },
    
    // Visual customization
    accentColor: "#ec4899",        // Trendy pink
    bannerImage: "/images/banners/west-end.jpg",
    bgPattern: "artistic-brush",
    
    // Local highlights
    highlights: [
      "Trendy apartment cleaning",
      "Eco-conscious products",
      "Artistic community focus", 
      "Weekend availability"
    ],
    
    // Nearby suburbs
    adjacentSuburbs: ["south-brisbane", "highgate-hill", "brisbane-city"]
  }
};