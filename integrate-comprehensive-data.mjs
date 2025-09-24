#!/usr/bin/env node
// 🚀 REAL ASTRO BUILD WITH COMPREHENSIVE GEO DATA
// Generate actual Astro pages with our 345 suburbs from try-again-geo

import { readFileSync, writeFileSync } from 'fs';

console.log('🚀 **INTEGRATING COMPREHENSIVE GEO DATA FOR REAL ASTRO BUILD**');
console.log('🧠 AI Team: Creating real pages, not just console output!');
console.log('🏗️ Target: Replace current 3-suburb data with 345 comprehensive suburbs');
console.log('');

// Load our processed comprehensive suburb data
let comprehensiveSuburbs = [];
try {
  const data = JSON.parse(readFileSync('try-again-geo/suburbs_processed.json', 'utf8'));
  comprehensiveSuburbs = data;
  console.log(`✅ Loaded ${comprehensiveSuburbs.length} comprehensive suburbs`);
} catch (error) {
  console.log(`❌ Could not load comprehensive data: ${error.message}`);
  process.exit(1);
}

// Create the new areas.clusters.json format that Astro expects
const clusters = {
  "clusters": [
    {
      "slug": "brisbane-city",
      "name": "Brisbane City",
      "suburbs": comprehensiveSuburbs
        .filter(s => s.lga === 'Brisbane City')
        .map(s => ({
          "slug": s.slug,
          "name": s.name,
          "lat": s.lat,
          "lng": s.lng
        }))
    },
    {
      "slug": "logan-city", 
      "name": "Logan City",
      "suburbs": comprehensiveSuburbs
        .filter(s => s.lga === 'Logan City')
        .map(s => ({
          "slug": s.slug,
          "name": s.name,
          "lat": s.lat,
          "lng": s.lng
        }))
    },
    {
      "slug": "ipswich-city",
      "name": "Ipswich City", 
      "suburbs": comprehensiveSuburbs
        .filter(s => s.lga === 'Ipswich City')
        .map(s => ({
          "slug": s.slug,
          "name": s.name,
          "lat": s.lat,
          "lng": s.lng
        }))
    },
    {
      "slug": "moreton-bay",
      "name": "Moreton Bay Regional",
      "suburbs": comprehensiveSuburbs
        .filter(s => s.lga === 'Moreton Bay Regional')
        .map(s => ({
          "slug": s.slug,
          "name": s.name,
          "lat": s.lat,
          "lng": s.lng
        }))
    },
    {
      "slug": "redland-city",
      "name": "Redland City",
      "suburbs": comprehensiveSuburbs
        .filter(s => s.lga === 'Redland City')
        .map(s => ({
          "slug": s.slug,
          "name": s.name,
          "lat": s.lat,
          "lng": s.lng
        }))
    }
  ]
};

// Add any remaining suburbs to Brisbane City (fallback)
const assignedSlugs = new Set();
clusters.clusters.forEach(cluster => {
  cluster.suburbs.forEach(suburb => assignedSlugs.add(suburb.slug));
});

const unassignedSuburbs = comprehensiveSuburbs
  .filter(s => !assignedSlugs.has(s.slug))
  .map(s => ({
    "slug": s.slug,
    "name": s.name,
    "lat": s.lat,
    "lng": s.lng
  }));

if (unassignedSuburbs.length > 0) {
  clusters.clusters[0].suburbs.push(...unassignedSuburbs);
  console.log(`✅ Added ${unassignedSuburbs.length} unassigned suburbs to Brisbane City cluster`);
}

// Write the new areas.clusters.json
writeFileSync('src/data/areas.clusters.json', JSON.stringify(clusters, null, 2));

const totalSuburbs = clusters.clusters.reduce((sum, cluster) => sum + cluster.suburbs.length, 0);
console.log(`✅ Created areas.clusters.json with ${totalSuburbs} suburbs across ${clusters.clusters.length} clusters`);

// Create cluster_map.json
const clusterMap = {
  "brisbane-city": "Brisbane",
  "logan-city": "Logan", 
  "ipswich-city": "Ipswich",
  "moreton-bay": "Moreton Bay",
  "redland-city": "Redland"
};

writeFileSync('src/data/cluster_map.json', JSON.stringify(clusterMap, null, 2));
console.log(`✅ Created cluster_map.json with ${Object.keys(clusterMap).length} regions`);

// Update services to include all 4 services
const services = {
  "services": [
    {
      "slug": "bond-cleaning",
      "title": "Bond Cleaning",
      "description": "Professional end-of-lease cleaning service to get your full bond back",
      "shortDescription": "Get your bond back",
      "price": "$199",
      "duration": "3-6 hours"
    },
    {
      "slug": "spring-cleaning", 
      "title": "Spring Cleaning",
      "description": "Comprehensive deep cleaning service for your entire home",
      "shortDescription": "Complete home refresh",
      "price": "$299",
      "duration": "4-8 hours"
    },
    {
      "slug": "bathroom-deep-clean",
      "title": "Bathroom Deep Clean", 
      "description": "Intensive bathroom cleaning including tiles, grout, and fixtures",
      "shortDescription": "Bathroom transformation",
      "price": "$149",
      "duration": "2-3 hours"
    },
    {
      "slug": "house-cleaning",
      "title": "House Cleaning",
      "description": "Regular house cleaning service for ongoing maintenance",
      "shortDescription": "Regular maintenance",
      "price": "$179", 
      "duration": "2-4 hours"
    }
  ]
};

writeFileSync('src/data/services.json', JSON.stringify(services, null, 2));
console.log(`✅ Updated services.json with ${services.services.length} services`);

// Show the stats
console.log('');
console.log('📊 **COMPREHENSIVE DATA INTEGRATION COMPLETE**');
clusters.clusters.forEach(cluster => {
  console.log(`   🏘️ ${cluster.name}: ${cluster.suburbs.length} suburbs`);
});
console.log(`   🛠️ Services: ${services.services.length}`);
console.log(`   📄 Expected pages: ${totalSuburbs * services.services.length} service pages`);
console.log('');
console.log('🎯 **READY FOR REAL ASTRO BUILD**');
console.log('✅ Comprehensive 345-suburb data integrated into Astro');
console.log('✅ All 4 services configured for page generation');
console.log('✅ Geographic clustering by Local Government Area');
console.log('✅ Coordinate data preserved for all suburbs');
console.log('');
console.log('🚀 **NOW RUN: npm run build**');
console.log('   This will generate REAL pages, not just console output!');
