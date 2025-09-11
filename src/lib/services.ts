export type ServiceId = 'bathroom-deep-clean' | 'spring-clean';
export interface ServiceDef { slug: ServiceId; title: string; description: string; checklist: string[]; ctaLabel: string; }
export const SERVICES: ServiceDef[] = [
  { slug: 'bathroom-deep-clean', title: 'Bathroom Deep Clean', description: 'Reset showers, glass, grout, and fixtures to inspection-ready condition.', ctaLabel: 'Book a Bathroom Deep Clean', checklist: [
    'Shower glass & screen de-scaled and polished',
    'Tiles & grout lines scrubbed; corners detailed',
    'Toilet incl. hinges, base & cistern wiped',
    'Vanity, taps & mirror polished (no streaks)',
    'Exhaust vents dusted; light fittings wiped',
    'Floors vacuumed & mopped (edges/corners)'
  ]},
  { slug: 'spring-clean', title: 'Spring Clean', description: 'Whole-home reset: dusting, kitchen/bath refresh, and floors.', ctaLabel: 'Get a Spring Clean Quote', checklist: [
    'High/low dust: skirting, sills, ledges, fans (reachable)',
    'Switches, power points, and handles wiped',
    'Kitchen benches & fronts wiped; splashback de-greased',
    'Bathrooms refreshed (fixtures & glass)',
    'Windows (reachable) and mirrors polished',
    'Floors vacuumed & mopped'
  ]}
];
export function findService(slug: string){ return SERVICES.find(s => s.slug === slug) ?? null; }
export function otherServices(current: ServiceId){ return SERVICES.filter(s => s.slug !== current); }
