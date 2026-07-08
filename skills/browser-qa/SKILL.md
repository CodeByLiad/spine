---
name: browser-qa
description: Use before finishing any user-facing change - opens the real running app, clicks through the affected flow, verifies by observation not inspection, and generates a regression test. Mandatory dual-product pass for every Mode-B cross-product connection.
---

# Browser QA — prove it in a real running app

Purpose: prove stateful, user-visible behavior actually works in a live running
app — not by reading the code and asserting it looks right.

## When to use

- Any user-facing change, before finishing the branch (UI, user-visible API
  behavior, anything a human will click or see).
- **Mandatory for every Mode-B task** (per `classify-task.sh` /
  `subagent-driven-dev`'s Task Classification) — see "Dual-product QA" below.
  A single-product pass does not satisfy a Mode-B task.
- Skip for pure backend/library work with no user-visible surface,
  config-only changes, docs.

## Tooling (tool-agnostic by design)

Spine ships no fixed browser-automation stack — use whatever this session or
project actually has: a Playwright MCP, a Chrome DevTools MCP, a "Claude in
Chrome"-style tool, the project's own preview/dev-server tooling, or a
headless-browser CLI. If nothing is available, **say so explicitly** rather
than silently skipping QA — a real gap you name is better than a silent one.

## Steps

1. **Start or locate the real running app.** Ask the user how to run it if
   not obvious from the repo — `.spine/config.md`'s stack/boot-assertion
   fields are a good starting point.
2. **Open the affected flow and drive it the way a real user would** — click,
   type, navigate. Do not just read the component/route source and assert it
   "looks right."
3. **Verify by observation**: screenshot, DOM/accessibility snapshot,
   console/network inspection — whatever the tool provides — not by
   re-reading the diff.
4. **Re-verify any fix in the same session.** If something's broken, after
   the fix lands, drive the SAME flow again and confirm it actually works
   live — not just that the code changed.
5. **Generate a regression test from what you just verified manually**,
   where practical — it converts a one-time manual check into a durable one
   the ordinary test suite covers next time.
6. **Record the pass:**
   `sh "$CLAUDE_PLUGIN_ROOT/hooks/qa-receipt.sh" pass "<one-line flow description>"`
   — writes `.spine/qa-receipt` (branch tip + verdict + flows verified). If
   `$CLAUDE_PLUGIN_ROOT` is empty in your shell, use `using-spine`'s bounded hook-path
   fallback rather than guessing.

## Dual-product QA (Mode B, mandatory)

For every Mode-B task, the flow must be exercised across BOTH connected
products/modules in the SAME QA session — not one pass per product done
separately. This catches exactly what unit tests on a cross-product helper
miss: "product A shows the update, product B still shows stale state." A
single-product QA pass on a Mode-B task does not satisfy this requirement —
if you could only verify one side (e.g. the other product isn't runnable in
this environment), say so explicitly in your report rather than silently
calling it done.

## Honest limitation

This is process discipline, not a code-enforced gate like Gate D. Spine rule
#3 says a gate that depends on willpower is not a gate — this one currently
is one, because "did a real browser session happen" has no mechanical proof
the way "does a file's hash match" does. `finishing-a-branch` surfaces a
missing or stale `.spine/qa-receipt` as a note for user-facing work, never a
hard block. Treat that as a known gap, not a false sense of enforcement —
the same honesty the design docs apply to this graft ("visibility is not a
fix, but it beats invisibility").
