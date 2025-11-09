# Working Agreement

These guardrails limit any automation or assistant acting on this repository.

## Commit & Push
- Do **not** create commits or push branches unless the user explicitly asks for it **and** the latest build/tests have been confirmed to pass (or the user waives that requirement).

## Code Organization
- Keep each file scoped to a single type or protocol.
- Target roughly 250 lines per type file; split things up when approaching that size.
- Keep individual methods to about 25 lines to preserve readability. Extract helpers when they grow beyond that.

Check with the user before doing anything that might violate or stretch these rules.
