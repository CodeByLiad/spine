# .spine/config.md — pinned cross-cutting context (asserted before task one)
- Stack:            <!-- e.g. Next.js + TypeScript + Postgres -->
- Test runner:      <!-- e.g. vitest -->
- DB / project / env: <!-- EXACT project ref, not "the dev one" -->
- Auth context:     <!-- JWT issuer / identity source -->
- Conventions:      <!-- naming, folder layout, architectural invariants -->
- Boot assertion:   <!-- startup check that fails loudly on wrong DB/env; on pass, config-contract records .spine/config-asserted (frame-gate Gate C blocks code writes until it matches) -->
