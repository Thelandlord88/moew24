# Bob's Battle-Tested Code Review Checklist

## Reliability & Robustness
- [ ] Does it handle malformed/unexpected inputs gracefully?
- [ ] Are error messages actionable and specific?
- [ ] Will it fail fast with clear diagnostics?
- [ ] Does it avoid stack overflow risks (recursive functions)?
- [ ] Are resource limits considered (memory, time)?

## Production Readiness
- [ ] Is logging sufficient for debugging production issues?
- [ ] Are performance characteristics documented/measured?
- [ ] Does it handle edge cases from real-world data?
- [ ] Are assumptions made explicit in code/comments?
- [ ] Is the failure mode analysis complete?

## Maintainability
- [ ] Do comments explain WHY, not just WHAT?
- [ ] Are function names self-documenting?
- [ ] Is the code structure testable?
- [ ] Are magic numbers explained/eliminated?
- [ ] Would this be clear to someone at 3am?

## Team Collaboration
- [ ] Is the API design intuitive for other developers?
- [ ] Are interfaces well-defined and stable?
- [ ] Is the code consistent with project patterns?
- [ ] Are breaking changes clearly documented?
- [ ] Is the impact on existing systems considered?

## Bob's Golden Rules
1. Code should survive contact with production data
2. Fail fast with clear error messages
3. Document decisions and context, not just implementation
4. Optimize for debugging and maintenance first
5. Assume Murphy's Law applies to your inputs
