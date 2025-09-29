// src/lib/astroPropsGenerator.js
import { suburbProvider } from './suburbProvider.js';

export const astroPropsGenerator = {
    async generateServicePaths() {
        const services = await suburbProvider.getAllServices();
        const suburbs = await suburbProvider.loadSuburbs();
        
        const paths = [];
        
        for (const service of services) {
            for (const suburb of suburbs) {
                // Only generate paths for suburbs that have this service
                const serviceSuburbs = await suburbProvider.getSuburbsForService(service);
                if (serviceSuburbs.includes(suburb)) {
                    paths.push({
                        params: { service, suburb },
                        props: await suburbProvider.generateAstroProps(service, suburb)
                    });
                }
            }
        }
        
        return paths;
    },
    
    async generateAreaPaths() {
        const clusters = await suburbProvider.loadClusters();
        const suburbs = await suburbProvider.loadSuburbs();
        
        const paths = [];
        
        for (const cluster of clusters.clusters || []) {
            for (const suburb of cluster.suburbs || []) {
                if (suburbs.includes(suburb)) {
                    const suburbData = await suburbProvider.getSuburbData(suburb);
                    paths.push({
                        params: { cluster: cluster.slug, suburb },
                        props: {
                            title: `Cleaning Services in ${suburbData.name} | Company Name`,
                            metaDescription: `Quality cleaning services in ${suburbData.name}. Serving the ${cluster.name} area with professional, reliable service.`,
                            suburb: suburbData,
                            cluster: cluster,
                            services: await suburbProvider.getAllServices()
                        }
                    });
                }
            }
        }
        
        return paths;
    },

    async generateDashboardProps() {
        const suburbs = await suburbProvider.loadSuburbs();
        const services = await suburbProvider.getAllServices();
        
        return {
            totalSuburbs: suburbs.length,
            totalServices: services.length,
            totalPages: suburbs.length * services.length,
            lastUpdated: new Date().toISOString(),
            coverage: {
                suburbs: suburbs.slice(0, 10), // Sample suburbs for dashboard
                services: services
            }
        };
    }
};