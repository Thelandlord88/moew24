#!/usr/bin/env node
// Quick analysis script to check cluster geographic consistency

import fs from 'node:fs';
import { fileURLToPath } from 'node:url';

const readJson = (relativePath) => {
  const fileUrl = new URL(relativePath, import.meta.url);
  const filePath = fileURLToPath(fileUrl);
  const content = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(content);
};

const suburbs = readJson('../src/data/suburbs.json');

// Brisbane CBD coordinates for reference
const BRISBANE_CBD = { lat: -27.4698, lng: 153.0251 };

// Calculate distance between two coordinates (rough)
function distance(lat1, lng1, lat2, lng2) {
  const R = 6371; // Earth's radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI/180) * Math.cos(lat2 * Math.PI/180) *
    Math.sin(dLng/2) * Math.sin(dLng/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

// Analyze clusters
const clusterStats = {};
const potentialMisassignments = [];

suburbs.forEach(suburb => {
  if (!clusterStats[suburb.cluster]) {
    clusterStats[suburb.cluster] = {
      count: 0,
      avgDistance: 0,
      minLat: Infinity,
      maxLat: -Infinity,
      minLng: Infinity,
      maxLng: -Infinity,
      suburbs: []
    };
  }
  
  const stats = clusterStats[suburb.cluster];
  stats.count++;
  stats.suburbs.push(suburb.name);
  
  // Update bounds
  stats.minLat = Math.min(stats.minLat, suburb.coords.lat);
  stats.maxLat = Math.max(stats.maxLat, suburb.coords.lat);
  stats.minLng = Math.min(stats.minLng, suburb.coords.lng);
  stats.maxLng = Math.max(stats.maxLng, suburb.coords.lng);
  
  // Calculate distance from Brisbane CBD
  const distFromBrisbane = distance(
    BRISBANE_CBD.lat, BRISBANE_CBD.lng,
    suburb.coords.lat, suburb.coords.lng
  );
  
  // Check for potential misassignments
  if (suburb.cluster === 'brisbane' && distFromBrisbane > 50) {
    potentialMisassignments.push({
      suburb: suburb.name,
      cluster: suburb.cluster,
      distance: distFromBrisbane.toFixed(1),
      coords: suburb.coords
    });
  } else if (suburb.cluster === 'logan' && distFromBrisbane < 15) {
    potentialMisassignments.push({
      suburb: suburb.name,
      cluster: suburb.cluster,
      distance: distFromBrisbane.toFixed(1),
      coords: suburb.coords
    });
  } else if (suburb.cluster === 'ipswich' && suburb.coords.lng > 153.1) {
    potentialMisassignments.push({
      suburb: suburb.name,
      cluster: suburb.cluster,
      distance: distFromBrisbane.toFixed(1),
      coords: suburb.coords,
      issue: 'Too far east for Ipswich'
    });
  }
});

console.log('🌍 CLUSTER ANALYSIS RESULTS:\n');

Object.entries(clusterStats).forEach(([cluster, stats]) => {
  console.log(`📍 ${cluster.toUpperCase()} CLUSTER:`);
  console.log(`   Suburbs: ${stats.count}`);
  console.log(`   Lat range: ${stats.minLat.toFixed(3)} to ${stats.maxLat.toFixed(3)}`);
  console.log(`   Lng range: ${stats.minLng.toFixed(3)} to ${stats.maxLng.toFixed(3)}`);
  console.log(`   Sample suburbs: ${stats.suburbs.slice(0, 5).join(', ')}${stats.suburbs.length > 5 ? '...' : ''}`);
  console.log('');
});

if (potentialMisassignments.length > 0) {
  console.log('⚠️ POTENTIAL CLUSTER MISASSIGNMENTS:');
  potentialMisassignments.forEach(item => {
    console.log(`   ${item.suburb} (${item.cluster}) - ${item.distance}km from Brisbane CBD`);
    if (item.issue) console.log(`      Issue: ${item.issue}`);
  });
  console.log('');
}

// Check if all suburbs in areas.clusters.json exist in suburbs.json
const areasData = readJson('../src/content/areas.clusters.json');

const suburbSlugs = new Set(suburbs.map(s => s.slug));
const missingInData = [];
const missingInClusters = [];

areasData.clusters.forEach(cluster => {
  cluster.suburbs.forEach(suburbSlug => {
    if (!suburbSlugs.has(suburbSlug)) {
      missingInData.push(`${suburbSlug} (${cluster.slug})`);
    }
  });
});

// Check reverse - suburbs in data but not in cluster definitions
const clusterSuburbs = new Set();
areasData.clusters.forEach(cluster => {
  cluster.suburbs.forEach(slug => clusterSuburbs.add(slug));
});

suburbs.forEach(suburb => {
  if (!clusterSuburbs.has(suburb.slug)) {
    missingInClusters.push(`${suburb.slug} (${suburb.cluster})`);
  }
});

if (missingInData.length > 0) {
  console.log('❌ SUBURBS IN CLUSTERS BUT MISSING FROM DATA:');
  missingInData.slice(0, 10).forEach(item => console.log(`   ${item}`));
  if (missingInData.length > 10) console.log(`   ... and ${missingInData.length - 10} more`);
  console.log('');
}

if (missingInClusters.length > 0) {
  console.log('❌ SUBURBS IN DATA BUT MISSING FROM CLUSTER DEFINITIONS:');
  missingInClusters.slice(0, 10).forEach(item => console.log(`   ${item}`));
  if (missingInClusters.length > 10) console.log(`   ... and ${missingInClusters.length - 10} more`);
  console.log('');
}

console.log('✅ Analysis complete!');
console.log(`📊 Total suburbs analyzed: ${suburbs.length}`);
console.log(`📊 Clusters found: ${Object.keys(clusterStats).length}`);
console.log(`📊 Potential issues: ${potentialMisassignments.length + missingInData.length + missingInClusters.length}`);
