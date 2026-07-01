---
name: config-contract
description: Use before task one of any build. Pins cross-cutting context (DB/project/env, auth, conventions) into .spine/config.md and asserts it. No task is dispatched until the assertion passes. Closes isolation's blind spot — a build pointed at the wrong place that passes every per-task gate.
---

# Config contract

Isolation is blind to "are we pointed at the right place." Per-task gates verify each task is locally correct; none owns the whole-build view.

## Steps
1. If `.spine/config.md` is absent, create it by grilling the user and `Write` it directly with the answers (fields: Stack, Test runner, DB/project/env, Auth context, Conventions, Boot assertion). Do NOT shell `find`/`cp` or read plugin templates — the rest of `.spine/` (`context.md`, `danger-paths`, `progress.md`) is auto-scaffolded silently by the `pre-tool-use/frame-gate` hook.
2. Pin: which DB/project/env, which auth context, the global conventions and invariants.
3. **Assert it.** Wherever mechanically possible, turn the contract into a startup check that fails loudly if violated (app refuses to boot / test baseline fails if connected to the wrong project). A prose-only contract is advisory = skipped.
4. No build task is dispatched until this assertion passes (or, where it cannot be asserted mechanically, a named human explicitly confirms the seam).
