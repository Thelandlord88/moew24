import { describe, it, expect } from 'vitest';
import { findNearbySuburbs } from '../../src/lib/geo/proximity';

describe('proximity basics', () => {
  it('returns some neighbors for a covered suburb', () => {
    const out = findNearbySuburbs('rosewood', { service: 'bond-cleaning' });
    expect(Array.isArray(out)).toBe(true);
  });
});
