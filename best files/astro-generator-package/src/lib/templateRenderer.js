// src/lib/templateRenderer.js
import { suburbProvider } from './suburbProvider.js';

/**
 * Runtime template processing for dynamic content
 * Processes template placeholders like {{templateType:service:suburb}}
 */
export class TemplateRenderer {
    constructor() {
        this.cache = new Map();
        this.debugMode = process.env.NODE_ENV === 'development';
    }

    /**
     * Render all template placeholders in content
     * @param {string} content - Content with template placeholders
     * @param {Object} context - Additional context data
     * @returns {Promise<string>} - Rendered content
     */
    async renderTemplates(content, context = {}) {
        if (!content || typeof content !== 'string') {
            return content;
        }

        let renderedContent = content;

        // Process different template types
        renderedContent = await this.processFAQTemplates(renderedContent, context);
        renderedContent = await this.processCardTitleTemplates(renderedContent, context);
        renderedContent = await this.processMetaDescriptionTemplates(renderedContent, context);
        renderedContent = await this.processPageTitleTemplates(renderedContent, context);
        renderedContent = await this.processCustomTemplates(renderedContent, context);

        return renderedContent;
    }

    /**
     * Process FAQ answer templates: {{faqAnswer:service:suburb}}
     */
    async processFAQTemplates(content, context) {
        const faqPattern = /\{\{faqAnswer:([^:]+):([^}]+)\}\}/g;
        
        return await this.processTemplatePattern(content, faqPattern, async (service, suburbSlug) => {
            const suburbData = await suburbProvider.getSuburbData(suburbSlug);
            return suburbProvider.getContentTemplate('faqAnswer', suburbData, service);
        });
    }

    /**
     * Process card title templates: {{cardTitle:service:suburb}}
     */
    async processCardTitleTemplates(content, context) {
        const cardPattern = /\{\{cardTitle:([^:]+):([^}]+)\}\}/g;
        
        return await this.processTemplatePattern(content, cardPattern, async (service, suburbSlug) => {
            const suburbData = await suburbProvider.getSuburbData(suburbSlug);
            return suburbProvider.getContentTemplate('cardTitle', suburbData, service);
        });
    }

    /**
     * Process meta description templates: {{metaDescription:service:suburb}}
     */
    async processMetaDescriptionTemplates(content, context) {
        const metaPattern = /\{\{metaDescription:([^:]+):([^}]+)\}\}/g;
        
        return await this.processTemplatePattern(content, metaPattern, async (service, suburbSlug) => {
            const suburbData = await suburbProvider.getSuburbData(suburbSlug);
            return suburbProvider.getContentTemplate('metaDescription', suburbData, service);
        });
    }

    /**
     * Process page title templates: {{pageTitle:service:suburb}}
     */
    async processPageTitleTemplates(content, context) {
        const titlePattern = /\{\{pageTitle:([^:]+):([^}]+)\}\}/g;
        
        return await this.processTemplatePattern(content, titlePattern, async (service, suburbSlug) => {
            const suburbData = await suburbProvider.getSuburbData(suburbSlug);
            return suburbProvider.getContentTemplate('pageTitle', suburbData, service);
        });
    }

    /**
     * Process custom templates: {{customType:service:suburb}}
     */
    async processCustomTemplates(content, context) {
        const customPattern = /\{\{([^:]+):([^:]+):([^}]+)\}\}/g;
        
        return await this.processTemplatePattern(content, customPattern, async (templateType, service, suburbSlug) => {
            // Skip already processed templates
            const processedTypes = ['faqAnswer', 'cardTitle', 'metaDescription', 'pageTitle'];
            if (processedTypes.includes(templateType)) {
                return `{{${templateType}:${service}:${suburbSlug}}}`;
            }

            const suburbData = await suburbProvider.getSuburbData(suburbSlug);
            return suburbProvider.getContentTemplate(templateType, suburbData, service);
        });
    }

    /**
     * Generic template pattern processor with caching
     */
    async processTemplatePattern(content, pattern, processor) {
        const matches = Array.from(content.matchAll(pattern));
        
        for (const match of matches) {
            const fullMatch = match[0];
            const args = match.slice(1);
            
            // Create cache key
            const cacheKey = `${args.join(':')}-${fullMatch}`;
            
            let replacement;
            if (this.cache.has(cacheKey)) {
                replacement = this.cache.get(cacheKey);
            } else {
                try {
                    replacement = await processor(...args);
                    this.cache.set(cacheKey, replacement);
                } catch (error) {
                    console.error(`Template processing error for ${fullMatch}:`, error);
                    replacement = fullMatch; // Keep original if error
                }
            }
            
            content = content.replace(fullMatch, replacement);
        }
        
        return content;
    }

    /**
     * Batch process multiple content strings
     * @param {Array<string>} contents - Array of content strings
     * @param {Object} context - Shared context
     * @returns {Promise<Array<string>>} - Array of rendered content
     */
    async renderTemplatesBatch(contents, context = {}) {
        return Promise.all(contents.map(content => this.renderTemplates(content, context)));
    }

    /**
     * Validate template syntax in content
     * @param {string} content - Content to validate
     * @returns {Array} - Array of validation issues
     */
    validateTemplates(content) {
        const issues = [];
        
        // Check for malformed templates
        const malformedPattern = /\{\{[^}]*$/g;
        const malformedMatches = content.match(malformedPattern);
        if (malformedMatches) {
            issues.push({
                type: 'malformed',
                matches: malformedMatches,
                message: 'Incomplete template tags found'
            });
        }

        // Check for unknown template types
        const templatePattern = /\{\{([^:]+):[^}]+\}\}/g;
        const knownTypes = ['faqAnswer', 'cardTitle', 'metaDescription', 'pageTitle'];
        const unknownTypes = [];
        
        let match;
        while ((match = templatePattern.exec(content)) !== null) {
            const templateType = match[1];
            if (!knownTypes.includes(templateType) && !unknownTypes.includes(templateType)) {
                unknownTypes.push(templateType);
            }
        }
        
        if (unknownTypes.length > 0) {
            issues.push({
                type: 'unknown_template_type',
                templates: unknownTypes,
                message: `Unknown template types: ${unknownTypes.join(', ')}`
            });
        }

        return issues;
    }

    /**
     * Clear template cache
     */
    clearCache() {
        this.cache.clear();
    }

    /**
     * Get cache statistics
     */
    getCacheStats() {
        return {
            size: this.cache.size,
            keys: Array.from(this.cache.keys()).slice(0, 10) // First 10 keys for debugging
        };
    }
}

// Export singleton instance
export const templateRenderer = new TemplateRenderer();

// Convenience function for simple usage
export async function renderTemplates(content, context = {}) {
    return await templateRenderer.renderTemplates(content, context);
}
