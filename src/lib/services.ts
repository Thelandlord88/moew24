export type ServiceId = 'bathroom-deep-clean' | 'spring-clean' | 'bond-cleaning' | 'house-cleaning';
export interface ServiceDef { slug: ServiceId; title: string; description: string; checklist: string[]; ctaLabel: string; }
export const SERVICES: ServiceDef[] = [
  { slug: 'bond-cleaning', title: 'Bond Cleaning', description: 'Professional end-of-lease cleaning service to get your full bond back.', ctaLabel: 'Book Bond Cleaning', checklist: [
    'Complete property deep clean to real estate standards',
    'Kitchen: oven, stovetop, rangehood, cupboards inside/out',
    'Bathrooms: tiles, grout, fixtures, exhaust fans',
    'All rooms: walls, skirting, windows, light fittings',
    'Carpets professionally cleaned (if required)',
    'Final inspection quality guarantee'
  ]},
  { slug: 'spring-clean', title: 'Spring Clean', description: 'Comprehensive deep cleaning service for your entire home.', ctaLabel: 'Get a Spring Clean Quote', checklist: [
    'High/low dust: skirting, sills, ledges, fans (reachable)',
    'Switches, power points, and handles wiped',
    'Kitchen benches & fronts wiped; splashback de-greased',
    'Bathrooms refreshed (fixtures & glass)',
    'Windows (reachable) and mirrors polished',
    'Floors vacuumed & mopped'
  ]},
  { slug: 'bathroom-deep-clean', title: 'Bathroom Deep Clean', description: 'Intensive bathroom cleaning including tiles, grout, and fixtures.', ctaLabel: 'Book a Bathroom Deep Clean', checklist: [
    'Shower glass & screen de-scaled and polished',
    'Tiles & grout lines scrubbed; corners detailed',
    'Toilet incl. hinges, base & cistern wiped',
    'Vanity, taps & mirror polished (no streaks)',
    'Exhaust vents dusted; light fittings wiped',
    'Floors vacuumed & mopped (edges/corners)'
  ]},
  { slug: 'house-cleaning', title: 'House Cleaning', description: 'Regular house cleaning service for ongoing maintenance.', ctaLabel: 'Book House Cleaning', checklist: [
    'Dusting all surfaces, furniture, and fixtures',
    'Kitchen cleaning: benches, appliances, sink',
    'Bathroom cleaning: toilet, shower, vanity',
    'Bedroom cleaning: making beds, tidying',
    'Living areas: vacuuming, mopping floors',
    'Trash removal and basic organization'
  ]}
];
export function findService(slug: string){ return SERVICES.find(s => s.slug === slug) ?? null; }
export function otherServices(current: ServiceId){ return SERVICES.filter(s => s.slug !== current); }
