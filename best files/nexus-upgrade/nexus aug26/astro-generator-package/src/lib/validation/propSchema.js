// Advanced Prop Validation System
// NEXUS Astro Component Architect Enhancement

export class PropSchema {
    constructor(schema) {
        this.schema = schema;
        this.validators = new Map();
        this.computedProps = new Map();
        this.setupValidators();
    }
    
    setupValidators() {
        // Built-in validators
        this.validators.set('string', (value, constraints) => {
            if (typeof value !== 'string') return false;
            if (constraints.minLength && value.length < constraints.minLength) return false;
            if (constraints.maxLength && value.length > constraints.maxLength) return false;
            if (constraints.pattern && !constraints.pattern.test(value)) return false;
            if (constraints.enum && !constraints.enum.includes(value)) return false;
            return true;
        });
        
        this.validators.set('number', (value, constraints) => {
            if (typeof value !== 'number') return false;
            if (constraints.min && value < constraints.min) return false;
            if (constraints.max && value > constraints.max) return false;
            return true;
        });
    }
    
    validate(props) {
        const errors = [];
        const warnings = [];
        
        // Validate required props
        for (const [key, definition] of Object.entries(this.schema.properties)) {
            if (definition.required && !(key in props)) {
                errors.push(`Missing required prop: ${key}`);
                continue;
            }
            
            if (key in props) {
                const validator = this.validators.get(definition.type);
                if (validator && !validator(props[key], definition)) {
                    errors.push(`Invalid prop ${key}: ${props[key]}`);
                }
            }
        }
        
        // Generate computed props
        const computedProps = this.generateComputedProps(props);
        
        return {
            isValid: errors.length === 0,
            errors,
            warnings,
            props: { ...props, ...computedProps }
        };
    }
    
    generateComputedProps(baseProps) {
        const computed = {};
        
        for (const [key, generator] of Object.entries(this.schema.computed || {})) {
            try {
                computed[key] = generator(baseProps);
            } catch (error) {
                console.warn(`Failed to compute ${key}:`, error.message);
            }
        }
        
        return computed;
    }
}

// Service Page Schema Example
export const ServicePageSchema = new PropSchema({
    properties: {
        service: {
            type: 'string',
            required: true,
            enum: ['bond-cleaning', 'carpet-cleaning', 'pest-control'],
            description: 'Service type identifier'
        },
        suburb: {
            type: 'string', 
            required: true,
            pattern: /^[a-z-]+$/,
            minLength: 2,
            maxLength: 50,
            description: 'Suburb name in kebab-case'
        },
        coordinates: {
            type: 'object',
            properties: {
                lat: { type: 'number', min: -90, max: 90 },
                lng: { type: 'number', min: -180, max: 180 }
            }
        }
    },
    
    computed: {
        // Auto-generate SEO-optimized title
        pageTitle: (props) => {
            const serviceNames = {
                'bond-cleaning': 'Bond Cleaning',
                'carpet-cleaning': 'Carpet Cleaning', 
                'pest-control': 'Pest Control'
            };
            const suburbName = props.suburb.split('-').map(
                word => word.charAt(0).toUpperCase() + word.slice(1)
            ).join(' ');
            
            return `${serviceNames[props.service]} in ${suburbName} | Professional Services`;
        },
        
        // Generate canonical URL
        canonicalUrl: (props) => `/services/${props.service}/${props.suburb}/`,
        
        // Create breadcrumb structure
        breadcrumbs: (props) => [
            { name: 'Home', url: '/' },
            { name: 'Services', url: '/services/' },
            { name: props.service.replace('-', ' '), url: `/services/${props.service}/` },
            { name: props.suburb.replace('-', ' '), url: `/services/${props.service}/${props.suburb}/` }
        ],
        
        // Generate meta description
        metaDescription: (props) => {
            const suburbName = props.suburb.replace('-', ' ');
            return `Professional ${props.service.replace('-', ' ')} services in ${suburbName}. Book online for fast, reliable service with satisfaction guarantee.`;
        }
    }
});
