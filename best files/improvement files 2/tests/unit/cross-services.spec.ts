import { describe, it, expect } from 'vitest';
import { isCovered } from '../../src/lib/clusters';

describe('coverage gating', () => {
  it('bathroom & spring are listed in same suburb when covered', () => {
    expect(isCovered('bathroom-deep-clean', 'ipswich')).toBe(true);
    expect(isCovered('spring-cleaning', 'ipswich')).toBe(true);
  });
});
