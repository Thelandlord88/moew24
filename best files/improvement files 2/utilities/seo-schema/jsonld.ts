import businessData from "@/data/business.json";

export function getLocalBusinessLD() {
  return {
    "@context": "https://schema.org",
    "@type": "LocalBusiness",
    "@id": `${businessData.url}#business`,
    "name": businessData.name,
    "legalName": businessData.legalName,
    "description": businessData.description,
    "url": businessData.url,
    "telephone": businessData.telephone,
    "email": businessData.email,
    "address": {
      "@type": "PostalAddress",
      "streetAddress": businessData.address.streetAddress,
      "addressLocality": businessData.address.addressLocality,
      "addressRegion": businessData.address.addressRegion,
      "postalCode": businessData.address.postalCode,
      "addressCountry": businessData.address.addressCountry
    },
    "geo": {
      "@type": "GeoCoordinates",
      "latitude": businessData.geo.latitude,
      "longitude": businessData.geo.longitude
    },
    "openingHours": businessData.openingHours,
    "areaServed": businessData.serviceArea.map(area => ({
      "@type": "City",
      "name": area.name,
      "containedIn": area.containedIn
    })),
    "priceRange": businessData.priceRange,
    "paymentAccepted": businessData.paymentAccepted,
    "sameAs": businessData.sameAs,
    "hasOfferCatalog": {
      "@type": "OfferCatalog",
      "name": businessData.hasOfferCatalog.name,
      "itemListElement": businessData.hasOfferCatalog.itemListElement.map((item, index) => ({
        "@type": "Offer",
        "position": index + 1,
        "itemOffered": {
          "@type": "Service",
          "name": item.name,
          "priceRange": item.price
        }
      }))
    }
  };
}

export function getServiceLD(serviceName: string, serviceDescription: string, serviceArea?: string) {
  const service = businessData.services.find(s => s.name === serviceName);
  
  return {
    "@context": "https://schema.org",
    "@type": "Service",
    "@id": `${businessData.url}/services/${serviceName.toLowerCase().replace(/\s+/g, '-')}#service`,
    "name": serviceName,
    "description": serviceDescription,
    "serviceType": service?.serviceType || serviceName,
    "provider": {
      "@type": "LocalBusiness",
      "@id": `${businessData.url}#business`,
      "name": businessData.name,
      "telephone": businessData.telephone,
      "email": businessData.email
    },
    "areaServed": serviceArea ? {
      "@type": "City",
      "name": serviceArea,
      "containedIn": "Queensland, Australia"
    } : businessData.serviceArea.map(area => ({
      "@type": "City", 
      "name": area.name,
      "containedIn": area.containedIn
    })),
    "offers": {
      "@type": "Offer",
      "priceRange": businessData.priceRange,
      "availability": "https://schema.org/InStock",
      "validFrom": new Date().toISOString().split('T')[0]
    }
  };
}

export function getBreadcrumbLD(items: Array<{name: string, url: string}>) {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    "itemListElement": items.map((item, index) => ({
      "@type": "ListItem",
      "position": index + 1,
      "name": item.name,
      "item": item.url
    }))
  };
}

// Validation helper - ensures NAP consistency
export function validateNAPConsistency(pageNAP: {name?: string, address?: string, phone?: string}) {
  const errors: string[] = [];
  
  if (pageNAP.name && pageNAP.name !== businessData.name) {
    errors.push(`Name mismatch: ${pageNAP.name} vs ${businessData.name}`);
  }
  
  if (pageNAP.phone && pageNAP.phone !== businessData.telephone) {
    errors.push(`Phone mismatch: ${pageNAP.phone} vs ${businessData.telephone}`);
  }
  
  if (pageNAP.address && !pageNAP.address.includes(businessData.address.addressLocality)) {
    errors.push(`Address locality missing: ${pageNAP.address}`);
  }
  
  return errors;
}

export { businessData };
