---
name: Review skill requires one subagent per review area
description: Code reviews must launch exactly 11 parallel subagents, one per review area — never bundle multiple areas into fewer agents
type: feedback
---

The review skill specifies 11 review areas that MUST each get their own dedicated subagent. Do NOT bundle multiple areas into fewer agents to save time or context.

**Why:** Bundled agents produce shallow coverage — they focus on their first assigned area and give cursory treatment to the rest. The user caught this when only 2 agents covered 8 areas, leaving regression risk, performance, and maintainability completely unreviewed.

**How to apply:** When running `/review`, always launch 11 parallel agents — one per area:
1. functional correctness
2. security
3. edge cases
4. authorization and authentication
5. input validation
6. error handling
7. data corruption risk
8. concurrency and race conditions
9. regression risk
10. performance
11. maintainability

Each agent prompt must name exactly ONE area. Never combine.
