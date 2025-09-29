import fs from 'node:fs';
import { fileURLToPath } from 'node:url';

const readJson = (relativePath) => {
  const fileUrl = new URL(relativePath, import.meta.url);
  const filePath = fileURLToPath(fileUrl);
  const content = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(content);
};

const suburbs = readJson('../src/data/suburbs.json');
const services = readJson('../src/data/services.json');

function validateSuburb(entry, index, names, slugs) {
  if (typeof entry.name !== 'string' || !entry.name.trim()) {
    return `Entry ${index} missing valid name`;
  }
  if (typeof entry.slug !== 'string' || !entry.slug.trim()) {
    return `Entry ${index} missing valid slug`;
  }
  // Skip postcode validation since our data structure doesn't include postcodes
  // if (!/^\d{4}$/.test(entry.postcode)) {
  //   return `Entry ${index} has invalid postcode`;
  // }
  if (!Array.isArray(entry.landmarks)) {
    return `Entry ${index} has invalid landmarks (must be array)`;
  }
  if (!entry.coords || typeof entry.coords.lat !== 'number' || typeof entry.coords.lng !== 'number') {
    return `Entry ${index} has invalid coords`;
  }
  if (names.has(entry.name)) {
    return `Duplicate name: ${entry.name}`;
  }
  if (slugs.has(entry.slug)) {
    return `Duplicate slug: ${entry.slug}`;
  }
  names.add(entry.name);
  slugs.add(entry.slug);
  return null;
}

const names = new Set();
const slugs = new Set();
const errors = [];
errors.push(...suburbs
  .map((s, i) => validateSuburb(s, i, names, slugs))
  .filter(Boolean));

function validateService(entry, index, slugs) {
  if (typeof entry.slug !== 'string' || !entry.slug.trim()) {
    return `Service ${index} missing valid slug`;
  }
  const label = typeof entry.title === 'string' ? entry.title : entry.name;
  if (typeof label !== 'string' || !label.trim()) {
    return `Service ${index} missing display name`;
  }
  if (slugs.has(entry.slug)) {
    return `Duplicate service slug: ${entry.slug}`;
  }
  slugs.add(entry.slug);
  // Optional: validate faqs
  if (entry.faqs && (!Array.isArray(entry.faqs) || !entry.faqs.every(f => f.q && f.a))) {
    return `Service ${index} has invalid faqs array`;
  }
  return null;
}

const serviceSlugs = new Set();
errors.push(...services
  .map((svc, i) => validateService(svc, i, serviceSlugs))
  .filter(Boolean));

if (errors.length) {
  console.error('Data validation failed:\n' + errors.join('\n'));
  process.exit(1);
} else {
  console.log('Data validation passed');
}
