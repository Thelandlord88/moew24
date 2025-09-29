// src/lib/suburbProvider.js
import fs from 'node:fs';
import path from 'node:path';

const DATA_DIR = path.join(process.cwd(), 'src/data');

class SuburbProvider {
    constructor() {
        this.suburbs = null;
        this.adjacency = null;
        this.coverage = null;
        this.coords = null;
        this.clusters = null;
        this.templates = null;
    }
    
    // Core Data Loading
    async loadSuburbs() {
        if (!this.suburbs) {
            const adjacencyPath = path.join(DATA_DIR, 'adjacency.json');
            const adjacency = JSON.parse(fs.readFileSync(adjacencyPath, 'utf-8'));
            
            // Extract all unique suburbs from adjacency data
            this.suburbs = [...new Set(Object.keys(adjacency).flatMap(key => [key, ...adjacency[key]]))];
        }
        return this.suburbs;
    }
    
    async loadServiceCoverage() {
        if (!this.coverage) {
            const coveragePath = path.join(DATA_DIR, 'serviceCoverage.json');
            this.coverage = JSON.parse(fs.readFileSync(coveragePath, 'utf-8'));
        }
        return this.coverage;
    }
    
    async loadClusters() {
        if (!this.clusters) {
            const clustersPath = path.join(DATA_DIR, 'areas.clusters.json');
            this.clusters = JSON.parse(fs.readFileSync(clustersPath, 'utf-8'));
        }
        return this.clusters;
    }
    
    async loadCoordinates() {
        if (!this.coords) {
            const coordsPath = path.join(DATA_DIR, 'suburbs.coords.json');
            this.coords = JSON.parse(fs.readFileSync(coordsPath, 'utf-8'));
        }
        return this.coords;
    }
    
    // Service and Suburb Queries
    async getSuburbsForService(service) {
        const coverage = await this.loadServiceCoverage();
        return coverage[service] || [];
    }
    
    async getAllServices() {
        const coverage = await this.loadServiceCoverage();
        return Object.keys(coverage);
    }
    
    async getAdjacentSuburbs(suburb) {
        if (!this.adjacency) {
            const adjacencyPath = path.join(DATA_DIR, 'adjacency.json');
            this.adjacency = JSON.parse(fs.readFileSync(adjacencyPath, 'utf-8'));
        }
        return this.adjacency[suburb] || [];
    }
    
    async getSuburbData(slug) {
        const coords = await this.loadCoordinates();
        const coordData = coords[slug] || {};
        
        return {
            name: slug.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase()),
            slug: slug,
            cluster: 'brisbane-city',
            lat: coordData.lat,
            lng: coordData.lng,
            postcode: coordData.postcode || "4000"
        };
    }
    
    async getClusterForSuburb(suburbSlug) {
        const clusters = await this.loadClusters();
        for (const cluster of clusters.clusters || []) {
            if (cluster.suburbs?.includes(suburbSlug)) {
                return cluster;
            }
        }
        return null;
    }
    
    // Content Template System
    getContentTemplate(templateType, suburbData, serviceData = null) {
        const templates = {
            faqAnswer: (suburb, service) => {
                const serviceLabels = {
                    'bond-cleaning': 'bond cleaning',
                    'spring-cleaning': 'spring cleaning',
                    'bathroom-deep-clean': 'bathroom deep cleaning'
                };
                
                const serviceLabel = serviceLabels[service] || service.replace('-', ' ');
                return `Most smaller ${suburb.name} ${serviceLabel} jobs take 3–6 hours depending on property size and condition.`;
            },
            cardTitle: (suburb, service) => {
                const serviceLabels = {
                    'bond-cleaning': 'Bond Cleaning',
                    'spring-cleaning': 'Spring Cleaning',
                    'bathroom-deep-clean': 'Bathroom Deep Cleaning'
                };
                
                const serviceLabel = serviceLabels[service] || service.split('-').map(word => 
                    word.charAt(0).toUpperCase() + word.slice(1)
                ).join(' ');
                
                return `${serviceLabel} in ${suburb.name}`;
            },
            metaDescription: (suburb, service) => {
                const serviceLabels = {
                    'bond-cleaning': 'bond cleaning',
                    'spring-cleaning': 'spring cleaning',
                    'bathroom-deep-clean': 'bathroom deep cleaning'
                };
                
                const serviceLabel = serviceLabels[service] || service.replace('-', ' ');
                return `Professional ${serviceLabel} services in ${suburb.name}. Quality, reliable, and affordable. Get your free quote today!`;
            },
            pageTitle: (suburb, service) => {
                const serviceLabels = {
                    'bond-cleaning': 'Bond Cleaning',
                    'spring-cleaning': 'Spring Cleaning',
                    'bathroom-deep-clean': 'Bathroom Deep Cleaning'
                };
                
                const serviceLabel = serviceLabels[service] || service.split('-').map(word => 
                    word.charAt(0).toUpperCase() + word.slice(1)
                ).join(' ');
                
                return `${serviceLabel} in ${suburb.name} | Company Name`;
            }
        };
        
        return templates[templateType] ? templates[templateType](suburbData, serviceData) : '';
    }
    
    // Astro Props Generator
    async generateAstroProps(service, suburbSlug) {
        const suburbData = await this.getSuburbData(suburbSlug);
        const cluster = await this.getClusterForSuburb(suburbSlug);
        const adjacentSuburbs = await this.getAdjacentSuburbs(suburbSlug);
        const services = await this.getAllServices();
        
        return {
            // Basic page props
            title: this.getContentTemplate('pageTitle', suburbData, service),
            metaDescription: this.getContentTemplate('metaDescription', suburbData, service),
            suburb: suburbData,
            service: service,
            cluster: cluster,
            
            // Navigation props
            availableServices: services.filter(s => s !== service),
            adjacentSuburbs: adjacentSuburbs.slice(0, 6).map(slug => ({
                slug: slug,
                name: this.getSuburbData(slug).name
            })),
            
            // SEO props
            structuredData: {
                "@context": "https://schema.org",
                "@type": "LocalBusiness",
                "name": this.getContentTemplate('pageTitle', suburbData, service),
                "description": this.getContentTemplate('metaDescription', suburbData, service),
                "address": {
                    "@type": "PostalAddress",
                    "addressLocality": suburbData.name,
                    "addressRegion": "QLD",
                    "postalCode": suburbData.postcode || "4000",
                    "addressCountry": "AU"
                },
                "geo": {
                    "@type": "GeoCoordinates",
                    "latitude": suburbData.lat,
                    "longitude": suburbData.lng
                },
                "openingHoursSpecification": [{
                    "@type": "OpeningHoursSpecification",
                    "dayOfWeek": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
                    "opens": "08:00",
                    "closes": "18:00"
                }],
                "telephone": "+61 7 1234 5678",
                "url": `https://yoursite.com/services/${service}/${suburbSlug}/`
            }
        };
    }
}

export const suburbProvider = new SuburbProvider();
