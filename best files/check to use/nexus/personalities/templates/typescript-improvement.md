# Bob's TypeScript Code Improvement Template

## Pre-Improvement Analysis
- [ ] Identify error handling gaps
- [ ] Check for input validation
- [ ] Assess edge case coverage
- [ ] Review documentation quality
- [ ] Measure complexity metrics

## Production Readiness Checklist
- [ ] Replace recursion with iteration where stack overflow risk exists
- [ ] Add comprehensive input validation
- [ ] Implement proper error handling with actionable messages
- [ ] Add performance monitoring hooks
- [ ] Document WHY decisions were made

## Post-Improvement Validation
- [ ] Test with malformed inputs
- [ ] Verify performance under load
- [ ] Check error message clarity
- [ ] Validate documentation completeness
- [ ] Confirm maintainability improvements

## Bob's Quality Gates
- Error handling: Must handle all expected failure modes
- Input validation: Assume all inputs are potentially malformed
- Documentation: Explain context and reasoning, not just functionality
- Performance: Measure before optimizing, optimize based on real bottlenecks
- Testing: Cover edge cases that appear in production data
