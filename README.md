# Spine

**The company coding agent, as one standalone Claude Code plugin.** One install, zero dependency.

Spine is a context-isolated subagent engine with enforced disciplines, packaged as a single plugin. A **controller** runs the build autonomously between two human gates, dispatching fresh isolated subagents (implementer, reviewer, fix, final reviewer) fed inputs as files. It codes anything — software, websites, any stack.

It is built by merging upstream source from five frameworks into one coherent bundle: Superpowers (the engine), mattpocock/skills (the FRAME alignment stage), and the ideas of ECC, gstack, and agent-skills — none of those three contribute copied files.

## Status

**v0.3.0 — Phase 1 + Phase 2 closed (live-confirmed, 3 rounds). Phase 3 in progress (1 of 3 parts done).**

**Phase 1** (the walking skeleton): FRAME → plan → worktree → build loop → whole-branch review → finish, with a per-repo `.spine/` config, a boot assertion, and a hash-bound config-assertion gate (Gate C).

**Phase 2** (enforcement) adds three mechanisms on top of Phase 1:
- **Gate D** (`merge-gate`) — `git merge`/`git push` blocked until a passing whole-branch review is recorded for the integrated branch's tip (`.spine/review-receipt`). Requires a review before *every* merge, not just danger-path-triggered ones. Segment-based command parsing closes chaining bypasses (`git merge x; echo y`, `git branch x; git merge y`) without false-positiving on unrelated commands that merely mention "git"/"merge" as text.
- **Task classifier** (`classify-task.sh`) — advisory Mode A/B scoring: files-touched against `.spine/danger-paths` (mechanical) plus new-contract/ambiguity (judgment, per `subagent-driven-dev`). Mode B tasks get wide context and no fast-path; every task still goes through Gate D regardless of mode.
- **Golden-rule import-boundary guard** (`boundary-gate`) — a write matching a `.spine/import-boundaries` rule is blocked if its new content contains that rule's forbidden reference. Generalizes "an app's routes/services must not import another product's schema" for a repo with no fixed notion of "product."

**Phase 1 + 2 status:** three live test rounds (v0.2.0 found 2 real defects → v0.2.1 fixed them, found a broader variant of one → v0.2.2 fixed that cleanly) — all gates PASS live, no known open defects. Full history in the acceptance records (kept outside the plugin tree).

**Phase 3** (grafts) — three parts, built one at a time:
- ✅ **Confidence-tagged grilling** — `framing`'s grill now tags each question with the agent's honest 0–100% confidence in its own recommendation, asks lowest-confidence items first, and stops once overall design confidence reaches ~95% (remaining high-confidence items become stated assumptions instead of spent questions).
- ⬜ Capability tracking (review-correction depth — skill-atrophy early warning) — not started.
- ⬜ Browser QA (gstack-style, Playwright/Chrome DevTools MCP) — not started.

Phase 4 (multi-harness: Cursor, Antigravity) remains a separate, unbuilt plan.

## Install (local)

```
/plugin marketplace add D:\Project\Plugins\Spine Plugin
/plugin install spine
```
Restart the session.

> ### ⚠️ Conflict: disable Superpowers before testing Spine
> Spine **absorbs** Superpowers — running both at once clashes (two session-start bootstraps, duplicate skill names, and Superpowers' `brainstorming` still auto-fires, which invalidates Spine's "exactly one FRAME skill" gate). Before testing or using Spine:
> 1. `/plugin` → manage → **disable `superpowers`**
> 2. Leave `caveman` enabled if you use it (comms-only, no clash).
> Once Spine is validated, uninstall Superpowers permanently — Spine is the sole engine.

## Live acceptance gates (run after disabling Superpowers)

**Phase 1:**
1. **Install** cleanly (no manifest error).
2. **Bootstrap present** — the session-start context contains `SPINE ACTIVE`.
3. **v1 gate** — send `build a react todo list`; `framing` auto-fires and HARD-GATES before any code; exactly one alignment skill fires; no `brainstorming`.
4. **Config-contract gate (A/B/C)** — in a repo with a deliberately wrong `.spine/config.md` DB/project, the build flags the mismatch before task one; a stale config-hash re-blocks after the file changes.

Already confirmed PASS on this content via prior automated + manual test sessions (repo shipped plugin-only; acceptance records are kept outside the plugin tree).

**Phase 2:**
5. **Gate D** — `git merge`/`git push` denied without a matching `.spine/review-receipt`; allowed once the controller records one after a clean final review; re-denied if commits land after the receipt (stale tip).
6. **Task classifier** — a task touching a `.spine/danger-paths` glob classifies Mode B; one that doesn't classifies Mode A.
7. **Boundary guard** — a write matching a `.spine/import-boundaries` rule with the forbidden reference in its new content is denied; the same write without the reference, or to a non-matching path, is allowed.

Phase 2 mechanisms verified directly against the hook scripts (not yet re-run as live in-session gates from this install path).

## Layout

```
.claude-plugin/   plugin.json + marketplace.json
hooks/            session-start bootstrap, frame-gate (A/B/C), merge-gate (D),
                  boundary-gate (golden-rule), classify-task.sh, config-hash.sh,
                  review-receipt.sh, run-hook.cmd
skills/           10 skills — using-spine, framing, writing-plans, using-git-worktrees,
                  subagent-driven-dev, test-driven-development, systematic-debugging,
                  requesting-code-review, finishing-a-branch, config-contract
agents/           spine-implementer, spine-task-reviewer, spine-fix, spine-final-reviewer
commands/         /spine:frame, /spine:build, /spine:finish
templates/.spine/ per-repo scaffold (config, danger-paths, import-boundaries, context, progress ledger)
```

## How it works (the loop)

1. **FRAME** — grill one question at a time, each confidence-tagged (0–100%, lowest first, until ~95% overall), pin the `.spine/config.md` contract, HARD-GATE on design approval.
2. **PLAN** — decompose into bite-sized, individually testable tasks; classify each Mode A/B (Phase 2).
3. **BUILD** — controller dispatches a fresh `spine-implementer` per task (TDD: RED→GREEN→REFACTOR; wide context for Mode B), then a `spine-task-reviewer` (tests first, two verdicts, "do not trust the report"), then `spine-fix` for findings. The **controller** owns the `.spine/progress.md` ledger, never the subagent. Writes crossing a configured import boundary are blocked outright.
4. **REVIEW** — one `spine-final-reviewer` over the whole branch on the most capable model; on a clean pass the controller records `.spine/review-receipt`.
5. **FINISH** — verify the suite, then merge / PR / keep / discard — merge/push is blocked (Gate D) without a matching, current receipt. Data migrations are never autonomous.

## License

MIT. Internal bOnline tooling.
