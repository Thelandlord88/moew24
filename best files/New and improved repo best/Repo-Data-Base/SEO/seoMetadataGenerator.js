// 🎯 Enhanced SEO Metadata Generator
// Creates comprehensive SEO packages for each service+suburb combination

import { createTheme, getAdjacentSuburbs } from './themeProvider.js';

export function generateSEOMetadata(serviceSlug, suburbSlug) {
  const theme = createTheme(serviceSlug, suburbSlug);
  const service = theme.service;
  const suburb = theme.suburb;
  const adjacentSuburbs = getAdjacentSuburbs(suburbSlug);
  
  // Core SEO data
  const title = `${service.name} in ${suburb.name} | OneDone Cleaning`;
  const description = `Professional ${service.name.toLowerCase()} in ${suburb.name}. ${service.description}. ${service.tagline}. Call 1300 ONEDONE.`;
  const keywords = [
    service.name.toLowerCase(),
    suburb.name.toLowerCase(),
    `${service.name.toLowerCase()} ${suburb.name.toLowerCase()}`,
    'professional cleaning',
    'cleaning service',
    suburb.region,
    suburb.postcode,
    ...adjacentSuburbs.map(s => s.replace('-', ' '))
  ].join(', ');

  // URLs and canonical
  const url = `https://onedonecleaning.com.au/services/${serviceSlug}/${suburbSlug}`;
  const canonical = url;
  
  // Open Graph data
  const ogTitle = `${service.name} ${suburb.name} | ${service.priceRange}`;
  const ogDescription = `${service.tagline} in ${suburb.name}. ${service.features.slice(0, 3).join('. ')}.`;
  const ogImage = `https://onedonecleaning.com.au/images/og/${serviceSlug}-${suburbSlug}.jpg`;
  
  return {
    // Basic SEO
    title,
    description,
    keywords,
    canonical,
    url,
    
    // Geographic targeting
    geoRegion: `AU-QLD`,
    geoPlacename: `${suburb.name}, ${suburb.region}, Queensland, Australia`,
    geoPosition: `${suburb.coordinates.lat};${suburb.coordinates.lng}`,
    
    // Open Graph
    og: {
      title: ogTitle,
      description: ogDescription,
      image: ogImage,
      url: url,
      type: 'business.business',
      siteName: 'OneDone Cleaning',
      locale: 'en_AU'
    },
    
    // Twitter Cards
    twitter: {
      card: 'summary_large_image',
      title: ogTitle,
      description: ogDescription,
      image: ogImage,
      site: '@onedonecleaning',
      creator: '@onedonecleaning'
    },
    
    // Service-specific meta
    servicePrice: service.priceRange,
    serviceArea: suburb.name,
    businessHours: 'Mo-Fr 07:00-19:00',
    telephone: '1300663366',
    
    // Local SEO
    locality: suburb.name,
    region: suburb.region,
    postalCode: suburb.postcode,
    country: 'Australia'
  };
}

export function generateLocalBusinessSchema(serviceSlug, suburbSlug) {
  const theme = createTheme(serviceSlug, suburbSlug);
  const service = theme.service;
  const suburb = theme.suburb;
  
  return {
    "@context": "https://schema.org",
    "@type": "LocalBusiness",
    "@id": `https://onedonecleaning.com.au/services/${serviceSlug}/${suburbSlug}#business`,
    "name": `OneDone Cleaning - ${service.name} ${suburb.name}`,
    "description": `Professional ${service.name.toLowerCase()} services in ${suburb.name}. ${service.description}`,
    "url": `https://onedonecleaning.com.au/services/${serviceSlug}/${suburbSlug}`,
    "telephone": "1300663366",
    "email": "hello@onedonecleaning.com.au",
    "priceRange": service.priceRange,
    
    // Address & Location
    "address": {
      "@type": "PostalAddress",
      "addressLocality": suburb.name,
      "addressRegion": suburb.region,
      "postalCode": suburb.postcode,
      "addressCountry": "AU"
    },
    "geo": {
      "@type": "GeoCoordinates",
      "latitude": suburb.coordinates.lat,
      "longitude": suburb.coordinates.lng
    },
    
    // Business Details
    "openingHours": "Mo-Fr 07:00-19:00",
    "areaServed": {
      "@type": "City",
      "name": suburb.name
    },
    
    // Services Offered
    "hasOfferCatalog": {
      "@type": "OfferCatalog",
      "name": `${service.name} Services`,
      "itemListElement": service.features.map((feature, index) => ({
        "@type": "Offer",
        "itemOffered": {
          "@type": "Service", 
          "name": feature,
          "provider": {
            "@type": "LocalBusiness",
            "name": "OneDone Cleaning"
          }
        }
      }))
    },
    
    // Reviews & Ratings
    "aggregateRating": {
      "@type": "AggregateRating",
      "ratingValue": "4.9",
      "reviewCount": "347",
      "bestRating": "5",
      "worstRating": "1"
    },
    
    // Business Images
    "image": [
      `https://onedonecleaning.com.au/images/services/${serviceSlug}-hero.jpg`,
      `https://onedonecleaning.com.au/images/locations/${suburbSlug}-service.jpg`,
      `https://onedonecleaning.com.au/images/team/cleaning-team.jpg`
    ],
    
    // Same As (Social Profiles)
    "sameAs": [
      "https://www.facebook.com/onedonecleaning",
      "https://www.instagram.com/onedonecleaning", 
      "https://www.linkedin.com/company/onedonecleaning"
    ]
  };
}

export function generateServiceSchema(serviceSlug, suburbSlug) {
  const theme = createTheme(serviceSlug, suburbSlug);
  const service = theme.service;
  const suburb = theme.suburb;
  
  return {
    "@context": "https://schema.org",
    "@type": "Service",
    "@id": `https://onedonecleaning.com.au/services/${serviceSlug}/${suburbSlug}#service`,
    "name": `${service.name} in ${suburb.name}`,
    "description": service.description,
    "provider": {
      "@type": "LocalBusiness",
      "name": "OneDone Cleaning",
      "telephone": "1300663366",
      "url": "https://onedonecleaning.com.au"
    },
    "areaServed": {
      "@type": "City", 
      "name": suburb.name,
      "containedInPlace": {
        "@type": "State",
        "name": "Queensland"
      }
    },
    "offers": {
      "@type": "Offer",
      "price": service.priceRange,
      "priceCurrency": "AUD",
      "availability": "https://schema.org/InStock",
      "validFrom": "2025-01-01",
      "priceValidUntil": "2025-12-31"
    },
    "serviceType": service.name,
    "serviceArea": {
      "@type": "GeoCircle", 
      "geoMidpoint": {
        "@type": "GeoCoordinates",
        "latitude": suburb.coordinates.lat,
        "longitude": suburb.coordinates.lng
      },
      "geoRadius": "10000"
    }
  };
}

export function generateFAQSchema(serviceSlug, suburbSlug) {
  const theme = createTheme(serviceSlug, suburbSlug);
  const service = theme.service;
  const suburb = theme.suburb;
  
  return {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    "mainEntity": [
      {
        "@type": "Question",
        "name": `How much does ${service.name.toLowerCase()} cost in ${suburb.name}?`,
        "acceptedAnswer": {
          "@type": "Answer",
          "text": `${service.name} in ${suburb.name} starts from ${service.priceRange}. Final pricing depends on property size and specific requirements. Get a free quote by calling 1300 ONEDONE.`
        }
      },
      {
        "@type": "Question", 
        "name": `Do you provide ${service.name.toLowerCase()} services in ${suburb.name}?`,
        "acceptedAnswer": {
          "@type": "Answer",
          "text": `Yes, we provide professional ${service.name.toLowerCase()} throughout ${suburb.name} and surrounding areas in ${suburb.region}. We're fully insured and guarantee our work.`
        }
      },
      {
        "@type": "Question",
        "name": `What's included in your ${service.name.toLowerCase()} service?`,
        "acceptedAnswer": {
          "@type": "Answer", 
          "text": `Our ${service.name.toLowerCase()} includes: ${service.features.slice(0, 4).join(', ')}. We follow a comprehensive checklist to ensure thorough cleaning.`
        }
      },
      {
        "@type": "Question",
        "name": `How do I book ${service.name.toLowerCase()} in ${suburb.name}?`,
        "acceptedAnswer": {
          "@type": "Answer",
          "text": `Booking ${service.name.toLowerCase()} in ${suburb.name} is easy. Call 1300 ONEDONE for an instant quote, or visit our website to book online. We offer flexible scheduling to suit your needs.`
        }
      }
    ]
  };
}

export function generateBreadcrumbSchema(serviceSlug, suburbSlug) {
  const theme = createTheme(serviceSlug, suburbSlug);
  const service = theme.service;
  const suburb = theme.suburb;
  
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    "itemListElement": [
      {
        "@type": "ListItem",
        "position": 1,
        "name": "Home",
        "item": "https://onedonecleaning.com.au"
      },
      {
        "@type": "ListItem", 
        "position": 2,
        "name": "Services",
        "item": "https://onedonecleaning.com.au/services"
      },
      {
        "@type": "ListItem",
        "position": 3, 
        "name": service.name,
        "item": `https://onedonecleaning.com.au/services/${serviceSlug}`
      },
      {
        "@type": "ListItem",
        "position": 4,
        "name": `${service.name} in ${suburb.name}`,
        "item": `https://onedonecleaning.com.au/services/${serviceSlug}/${suburbSlug}`
      }
    ]
  };
}