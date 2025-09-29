// Component Factory System
// NEXUS Astro Component Architect Innovation

import { PropSchema } from '../validation/propSchema.js';
import { TokenProcessor, DesignTokens } from '../../config/tokens/designTokens.js';

export class ComponentFactory {
    constructor() {
        this.templates = new Map();
        this.schemas = new Map();
        this.generators = new Map();
    }
    
    // Register template with schema
    registerTemplate(name, template, schema) {
        this.templates.set(name, template);
        this.schemas.set(name, schema);
    }
    
    // Register component generator
    registerGenerator(type, generator) {
        this.generators.set(type, generator);
    }
    
    // Generate component from schema and data
    async generateComponent(templateName, props, options = {}) {
        const template = this.templates.get(templateName);
        const schema = this.schemas.get(templateName);
        
        if (!template || !schema) {
            throw new Error(`Template or schema not found: ${templateName}`);
        }
        
        // Validate and enhance props
        const validation = schema.validate(props);
        if (!validation.isValid) {
            throw new Error(`Prop validation failed: ${validation.errors.join(', ')}`);
        }
        
        const enhancedProps = validation.props;
        
        // Process template with enhanced props
        const processedTemplate = await this.processTemplate(
            template, 
            enhancedProps, 
            options
        );
        
        return {
            component: processedTemplate,
            props: enhancedProps,
            metadata: {
                templateName,
                generatedAt: new Date().toISOString(),
                validation: validation
            }
        };
    }
    
    // Advanced template processing
    async processTemplate(template, props, options) {
        let processed = template;
        
        // Replace prop placeholders
        processed = this.replacePropPlaceholders(processed, props);
        
        // Inject design tokens
        if (options.injectTokens !== false) {
            processed = this.injectDesignTokens(processed, props);
        }
        
        // Process conditional content
        processed = this.processConditionals(processed, props);
        
        // Generate service-specific theming
        if (props.service) {
            processed = this.injectServiceTheme(processed, props.service);
        }
        
        return processed;
    }
    
    // Replace {{prop}} placeholders with actual values
    replacePropPlaceholders(template, props) {
        return template.replace(/\{\{(\w+(?:\.\w+)*)\}\}/g, (match, path) => {
            const value = this.getNestedProp(props, path);
            return value !== undefined ? value : match;
        });
    }
    
    // Inject design tokens as CSS custom properties
    injectDesignTokens(template, props) {
        const tokenCSS = TokenProcessor.generateCSS(DesignTokens);
        
        return template.replace(
            '<style>',
            `<style>\n${tokenCSS}`
        );
    }
    
    // Process {#if condition} blocks
    processConditionals(template, props) {
        return template.replace(
            /\{#if\s+([^}]+)\}(.*?)\{\/if\}/gs,
            (match, condition, content) => {
                try {
                    // Simple condition evaluation (extend as needed)
                    const conditionResult = this.evaluateCondition(condition, props);
                    return conditionResult ? content : '';
                } catch (error) {
                    console.warn(`Failed to evaluate condition: ${condition}`, error);
                    return match;
                }
            }
        );
    }
    
    // Inject service-specific theming
    injectServiceTheme(template, service) {
        const serviceTheme = TokenProcessor.generateServiceTheme(service);
        const themeCSS = Object.entries(serviceTheme)
            .map(([key, value]) => `${key}: ${value};`)
            .join('\n  ');
            
        return template.replace(
            ':root {',
            `:root {\n  ${themeCSS}`
        );
    }
    
    // Utility methods
    getNestedProp(obj, path) {
        return path.split('.').reduce((current, key) => current?.[key], obj);
    }
    
    evaluateCondition(condition, props) {
        // Simple condition evaluator - extend for complex logic
        const cleanCondition = condition.trim();
        
        // Handle property existence: props.someProperty
        if (cleanCondition.startsWith('props.')) {
            const propPath = cleanCondition.slice(6);
            return Boolean(this.getNestedProp(props, propPath));
        }
        
        // Handle equality: props.service === 'bond-cleaning'
        const equalityMatch = cleanCondition.match(/props\.(\w+(?:\.\w+)*)\s*===\s*['"]([^'"]+)['"]/);
        if (equalityMatch) {
            const [, propPath, expectedValue] = equalityMatch;
            const actualValue = this.getNestedProp(props, propPath);
            return actualValue === expectedValue;
        }
        
        return false;
    }
}

// Pre-configured factory with standard templates
export const StandardComponentFactory = new ComponentFactory();

// Register service page template
StandardComponentFactory.registerTemplate(
    'servicePage',
    `---
// Generated Service Page
export const getStaticPaths = async () => {
    return {{staticPaths}};
};

const { service, suburb, pageTitle, metaDescription, canonicalUrl, breadcrumbs } = Astro.props;
---

<html lang="en">
<head>
    <title>{pageTitle}</title>
    <meta name="description" content={metaDescription} />
    <link rel="canonical" href={canonicalUrl} />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>

<body>
    <header class="service-header">
        <nav class="breadcrumbs">
            {breadcrumbs.map(crumb => (
                <a href={crumb.url}>{crumb.name}</a>
            ))}
        </nav>
    </header>
    
    <main class="service-main">
        <section class="hero-section">
            <h1 class="service-title">{{pageTitle}}</h1>
            <p class="service-description">{{metaDescription}}</p>
            
            {#if props.coordinates}
            <div class="location-info">
                <p>Service area coordinates: {{coordinates.lat}}, {{coordinates.lng}}</p>
            </div>
            {/if}
        </section>
        
        <section class="service-content">
            <!-- Dynamic content based on service type -->
            {#if props.service === 'bond-cleaning'}
            <div class="bond-cleaning-specific">
                <h2>Professional Bond Cleaning</h2>
                <p>Comprehensive end-of-lease cleaning services.</p>
            </div>
            {/if}
            
            {#if props.service === 'carpet-cleaning'}
            <div class="carpet-cleaning-specific">
                <h2>Expert Carpet Cleaning</h2>
                <p>Deep carpet cleaning with advanced techniques.</p>
            </div>
            {/if}
        </section>
    </main>
</body>

<style>
    .service-header {
        background: var(--service-primary);
        color: white;
        padding: var(--spacing-4);
    }
    
    .service-title {
        font-size: var(--fontSize-3xl);
        font-weight: var(--fontWeight-bold);
        margin-bottom: var(--spacing-4);
    }
    
    .service-main {
        padding: var(--spacing-6);
        max-width: 1200px;
        margin: 0 auto;
    }
    
    .hero-section {
        text-align: center;
        margin-bottom: var(--spacing-8);
    }
    
    .breadcrumbs a {
        color: var(--service-secondary);
        text-decoration: none;
        margin-right: var(--spacing-2);
    }
    
    .breadcrumbs a:hover {
        color: var(--service-light);
    }
</style>
</html>`,
    StandardComponentFactory.schemas.get('servicePage') // Will be set separately
);
