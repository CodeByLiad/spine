# Spine Phase 1 — Walking Skeleton Acceptance (ported build)

**Date:** 2026-07-01
**Build:** v0.1.3, ported byte-identical from `D:\Project\AI Agents\spine@746366c` (that build's own Phase 1 gates 3/4/5 previously ran PASS live — see `docs/My-observe.md`). This repo is a fresh git history at the new standalone location `D:\Project\Plugins\Spine Plugin`.

## Port integrity — PASS

| Check | Result |
|---|---|
| Every tracked file's git blob hash matches the source repo at commit `746366c` (byte-identical, incl. line endings / exec bits) | PASS |
| No leaked absolute source-repo paths (`AI Agents`) inside functional code (skills/agents/hooks/commands/templates/.claude-plugin) | PASS (only in docs prose — README/PHASE1-LIVE-GATES install paths updated to the new location; `My-observe.md` left as an unedited historical transcript) |

## Static acceptance checks — 7/7 PASS

| Check | Result |
|---|---|
| Plugin tree complete (manifests, hooks, 10 skills, 4 agents, 3 commands, templates) | PASS |
| `plugin.json` / `marketplace.json` / `hooks/hooks.json` valid JSON | PASS |
| All 10 skills have `name:` + `description:` frontmatter | PASS |
| Exactly one FRAME owner (`framing`), no `frame`/`brainstorming` skill present | PASS |
| `hooks/session-start/bootstrap.sh` emits `SPINE ACTIVE` marker | PASS |
| No functional `superpowers:` skill-refs or `.superpowers/` path-refs in skills/agents/hooks/commands/templates | PASS (2 prose-only mentions remain by design: bootstrap explicitly tells the agent not to use Superpowers' `brainstorming`; `finishing-a-branch` notes legacy-worktree-path ownership) |
| Controller-owns-ledger rule present in `subagent-driven-dev` | PASS |

Skills present: config-contract, finishing-a-branch, framing, requesting-code-review,
subagent-driven-dev, systematic-debugging, test-driven-development,
using-git-worktrees, using-spine, writing-plans.

## Hook mechanics — direct simulation (frame-gate.sh exercised outside a live session)

`hooks/pre-tool-use/frame-gate.sh` is a pure shell script keyed off `$CLAUDE_PLUGIN_ROOT` + JSON on stdin, so its logic was exercised directly against a scratch git repo — independent of plugin installation. All PASS:

| Gate | Result |
|---|---|
| Gate A: code write with no `.spine/` present → DENY (exit 2), correct message, branch name resolved | PASS |
| Side effect of Gate A: skeleton (`context.md`, `danger-paths`, `progress.md`) auto-scaffolded by the hook's own `cp`; `config.md`/`frame-approved` correctly absent | PASS |
| Gate B: `frame-approved` present but `config.md` absent → DENY (exit 2), correct message | PASS |
| Gate B does NOT auto-create `config.md` (gate stays meaningful) | PASS |
| Gate C: both markers present → ALLOW (exit 0), no deadlock | PASS |
| Non-code file (e.g. `README.md`) always allowed, even with no `.spine/` at all | PASS |
| Any write under `.spine/` itself always allowed (no self-deadlock) | PASS |
| Branch scoping: approval recorded for `feature-x` does NOT unlock a write on `master` — re-denies correctly | PASS |
| Structural no-prompt-storm: skeleton files are written by the hook's own `cp`, never via an agent Write tool call — cannot raise a permission prompt regardless of edit mode (byte-identical to the build that measured 0 prompts live) | PASS by construction |
| Gate 4e (semantic mismatch): fed a deliberately contradictory `.spine/config.md` (declares "client-only, no backend" while also pinning a **production** Supabase DB, with no corresponding boot-time connectivity assertion) and applied the `config-contract` skill's assertion step — flagged on 3 independent grounds (internal contradiction, production-as-default-target, missing startup assertion for the pinned DB) | PASS |

## What still requires a live, installed session (cannot be driven from here)

These need the actual Claude Code plugin manager, which is operator-only (interactive UI, not tool-callable by an agent):

1. **Install** — `/plugin marketplace add D:\Project\Plugins\Spine Plugin` then `/plugin install spine`; restart.
2. **Disable Superpowers first** (`/plugin` → manage → disable `superpowers`) — it clashes (duplicate bootstrap + `brainstorming` auto-fires).
3. **Gate 2 (bootstrap presence)** — confirm a fresh session's start context literally contains `SPINE ACTIVE`.
4. **Gate 3 (live auto-trigger)** — send `build a react todo list` in that fresh session; confirm `framing` (not `brainstorming`) is what actually fires, its body injects (HARD-GATE + checklist), and it grills one question at a time.

Every mechanism these 4 gates exercise has already been verified above at the content/logic level, against a build byte-identical to one whose live gates already passed (Superpowers disabled). What's left is confirming the *harness* wires it up the same way from this new install location. Follow `docs/PHASE1-LIVE-GATES.md` (paths updated for this location) and record results back into this file.

**Phase 1 status: everything automatable from outside a live session is 100% green (7/7 static + 10/10 hook-mechanics checks). The 4 interactive gates above are the one remaining step, and per this project's own established methodology they are operator-only — not something a subagent can drive.**
