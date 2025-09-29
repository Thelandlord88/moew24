// src/lib/seoSchemaIntegration.js
/**
 * SEO Schema Integration Bridge
 * Connects new SuburbProvider system with existing seoSchema.js functions
 */

import { suburbProvider } from './suburbProvider.js';
import { 
    localBusinessNode,
    serviceAndOfferNodes,
    suburbServiceGraph,
    faqPageNode,
    breadcrumbList,
    aggregateRatingNode,
    reviewNodes,
    titleCase,
    slugify
} from './seoSchema.js';

/**
 * Enhanced wrapper for localBusinessNode using SuburbProvider data
 */
export async function enhancedLocalBusinessNode({
    service,
    suburbSlug,
    customData = {}
} = {}) {
    const suburbData = await suburbProvider.getSuburbData(suburbSlug);
    const urlPath = `/services/${service}/${suburbSlug}/`;
    
    return localBusinessNode({
        suburb: suburbData.name,
        region: 'QLD',
        country: 'AU',
        postcode: suburbData.postcode,
        urlPath: urlPath,
        ...customData
    });
}

/**
 * Enhanced service graph with automatic geographic context
 */
export async function enhancedSuburbServiceGraph({
    service = 'bond-cleaning',
    suburbSlug,
    faq = [],
    priceFrom,
    includeReviews = false,
    reviews = []
} = {}) {
    const suburbData = await suburbProvider.getSuburbData(suburbSlug);
    const cluster = await suburbProvider.getClusterForSuburb(suburbSlug);
    const adjacentSuburbs = await suburbProvider.getAdjacentSuburbs(suburbSlug);
    
    // Enhanced breadcrumbs with cluster context
    const crumbs = [
        { name: 'Home', path: '/' },
        { name: titleCase(service), path: `/services/${service}/` }
    ];
    
    // Add cluster breadcrumb if available
    if (cluster) {
        crumbs.push({ 
            name: cluster.name, 
            path: `/areas/${cluster.slug}/` 
        });
    }
    
    crumbs.push({ 
        name: suburbData.name, 
        path: `/services/${service}/${suburbSlug}/` 
    });

    // Enhanced FAQ with geographic context
    const enhancedFaq = faq.map(item => ({
        ...item,
        answer: item.answer?.replace(/\{suburb\}/g, suburbData.name)
                             ?.replace(/\{service\}/g, titleCase(service))
    }));

    // Add automatic geographic FAQ if none provided
    if (enhancedFaq.length === 0) {
        enhancedFaq.push({
            question: `How long does ${titleCase(service)} take in ${suburbData.name}?`,
            answer: suburbProvider.getContentTemplate('faqAnswer', suburbData, service)
        });
        
        if (adjacentSuburbs.length > 0) {
            enhancedFaq.push({
                question: `Do you service areas near ${suburbData.name}?`,
                answer: `Yes! We also service ${adjacentSuburbs.slice(0, 3).map(slug => 
                    slug.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
                ).join(', ')} and surrounding areas.`
            });
        }
    }

    // Generate base schema
    let schema = suburbServiceGraph({
        service,
        suburb: suburbData.name,
        faq: enhancedFaq,
        priceFrom,
        crumbs
    });

    // Add enhanced geographic data
    const businessNode = schema.find(node => node['@type'] === 'LocalBusiness');
    if (businessNode && suburbData.lat && suburbData.lng) {
        businessNode.geo = {
            '@type': 'GeoCoordinates',
            latitude: suburbData.lat,
            longitude: suburbData.lng
        };
        
        // Add service area
        businessNode.areaServed = [
            { '@type': 'City', name: suburbData.name },
            ...adjacentSuburbs.slice(0, 5).map(slug => ({
                '@type': 'City',
                name: slug.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
            }))
        ];
    }

    // Add reviews if requested
    if (includeReviews && reviews.length > 0) {
        const aggregateRating = aggregateRatingNode({
            service,
            suburb: suburbData.name,
            reviews
        });
        
        const reviewList = reviewNodes({
            service,
            suburb: suburbData.name,
            reviews,
            limit: 5
        });
        
        if (aggregateRating) {
            schema.push(aggregateRating);
        }
        
        schema.push(...reviewList);
    }

    return schema;
}

/**
 * Convert SuburbProvider data to legacy seoSchema format
 */
export function convertSuburbDataToSeoFormat(suburbData) {
    return {
        suburb: suburbData.name,
        region: 'QLD',
        country: 'AU',
        postcode: suburbData.postcode,
        coordinates: {
            lat: suburbData.lat,
            lng: suburbData.lng
        }
    };
}

/**
 * Generate comprehensive SEO schema for service pages
 */
export async function generateServicePageSchema({
    service,
    suburbSlug,
    customFaq = [],
    priceFrom,
    reviews = [],
    includeReviews = true,
    additionalServices = []
} = {}) {
    // Get enhanced base schema
    const baseSchema = await enhancedSuburbServiceGraph({
        service,
        suburbSlug,
        faq: customFaq,
        priceFrom,
        includeReviews,
        reviews
    });

    // Add additional service offerings if provided
    if (additionalServices.length > 0) {
        const suburbData = await suburbProvider.getSuburbData(suburbSlug);
        
        for (const additionalService of additionalServices) {
            const additionalNodes = serviceAndOfferNodes({
                service: additionalService,
                suburb: suburbData.name,
                priceFrom: additionalService.priceFrom
            });
            
            baseSchema.push(...additionalNodes);
        }
    }

    return baseSchema;
}

/**
 * Generate area page schema with cluster context
 */
export async function generateAreaPageSchema({
    clusterSlug,
    suburbSlug,
    services = []
} = {}) {
    const suburbData = await suburbProvider.getSuburbData(suburbSlug);
    const cluster = await suburbProvider.getClusterForSuburb(suburbSlug);
    const adjacentSuburbs = await suburbProvider.getAdjacentSuburbs(suburbSlug);
    
    const urlPath = `/areas/${clusterSlug}/${suburbSlug}/`;
    
    // Base local business with area context
    const businessNode = await enhancedLocalBusinessNode({
        service: 'cleaning-services',
        suburbSlug,
        customData: {
            name: `One N Done Bond Clean — ${cluster?.name || suburbData.name} Area`,
            urlPath
        }
    });

    // Collection page for the area
    const collectionNode = {
        '@type': 'CollectionPage',
        '@id': `${urlPath}#collection`,
        name: `Cleaning Services in ${suburbData.name}`,
        url: urlPath,
        isPartOf: cluster ? {
            '@type': 'CollectionPage',
            name: `${cluster.name} Area Services`,
            url: `/areas/${clusterSlug}/`
        } : undefined
    };

    // Breadcrumb navigation
    const breadcrumbs = breadcrumbList({
        crumbs: [
            { name: 'Home', path: '/' },
            { name: 'Areas', path: '/areas/' },
            { name: cluster?.name || 'Brisbane', path: `/areas/${clusterSlug}/` },
            { name: suburbData.name, path: urlPath }
        ],
        urlPath
    });

    let schema = [businessNode, collectionNode, breadcrumbs];

    // Add service offerings
    for (const service of services) {
        const serviceNodes = serviceAndOfferNodes({
            service,
            suburb: suburbData.name
        });
        schema.push(...serviceNodes);
    }

    return schema.filter(Boolean);
}

/**
 * Auto-generate FAQ based on suburb and service
 */
export async function generateAutoFAQ(service, suburbSlug, additionalQuestions = []) {
    const suburbData = await suburbProvider.getSuburbData(suburbSlug);
    const adjacentSuburbs = await suburbProvider.getAdjacentSuburbs(suburbSlug);
    
    const autoFAQ = [
        {
            question: `How long does ${titleCase(service)} take in ${suburbData.name}?`,
            answer: suburbProvider.getContentTemplate('faqAnswer', suburbData, service)
        },
        {
            question: `Do you provide ${titleCase(service)} in ${suburbData.name}?`,
            answer: `Yes! We provide professional ${service.replace('-', ' ')} services throughout ${suburbData.name} and surrounding areas.`
        }
    ];

    if (adjacentSuburbs.length > 0) {
        autoFAQ.push({
            question: `What areas near ${suburbData.name} do you service?`,
            answer: `We service ${adjacentSuburbs.slice(0, 4).map(slug => 
                slug.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
            ).join(', ')} and other nearby suburbs in the ${suburbData.name} area.`
        });
    }

    if (suburbData.postcode) {
        autoFAQ.push({
            question: `Do you service the ${suburbData.postcode} postcode area?`,
            answer: `Absolutely! ${suburbData.name} (${suburbData.postcode}) is within our primary service area.`
        });
    }

    return [...autoFAQ, ...additionalQuestions];
}

/**
 * Validate schema output
 */
export function validateSchemaOutput(schema) {
    const validation = {
        isValid: true,
        errors: [],
        warnings: []
    };

    if (!Array.isArray(schema)) {
        validation.isValid = false;
        validation.errors.push('Schema must be an array');
        return validation;
    }

    for (const [index, node] of schema.entries()) {
        if (!node['@type']) {
            validation.errors.push(`Node ${index} missing @type`);
            validation.isValid = false;
        }

        if (!node['@id']) {
            validation.warnings.push(`Node ${index} missing @id (recommended for SEO)`);
        }
    }

    return validation;
}
