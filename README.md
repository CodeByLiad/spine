# Spine

**The company coding agent, as one standalone Claude Code plugin.** One install, zero dependency.

Spine is a context-isolated subagent engine with enforced disciplines, packaged as a single plugin. A **controller** runs the build autonomously between two human gates, dispatching fresh isolated subagents (implementer, reviewer, fix, final reviewer) fed inputs as files. It codes anything — software, websites, any stack.

It is built by merging upstream source from five frameworks into one coherent bundle: Superpowers (the engine), mattpocock/skills (the FRAME alignment stage), and the ideas of ECC, gstack, and agent-skills — none of those three contribute copied files.

## Status

**v0.1.5 — Phase 1 complete.** The full chain runs: FRAME → plan → worktree → build loop → whole-branch review → finish, with a per-repo `.spine/` config, a boot assertion, and a hash-bound config-assertion gate (Gate C). Static acceptance, a whole-branch review, and the live in-session gates all **PASS** — confirmed by both an automated and a manual test session (Gate A branch-scoping, Gate B config-present, Gate C assert-on-hash, silent scaffold, one-FRAME grill).

Phases 2 (enforcement: classifier + forced-review hook), 3 (grafts: confidence-tagged grilling, browser QA, capability tracking), and 4 (multi-harness: Cursor, Antigravity) are separate plans, built after Phase 1 passes live.

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

1. **Install** cleanly (no manifest error).
2. **Bootstrap present** — the session-start context contains `SPINE ACTIVE`.
3. **v1 gate** — send `build a react todo list`; `framing` auto-fires and HARD-GATES before any code; exactly one alignment skill fires; no `brainstorming`.
4. **Config-contract gate** — in a repo with a deliberately wrong `.spine/config.md` DB/project, the build flags the mismatch before task one.

Already confirmed PASS on this content via prior automated + manual test sessions (repo shipped plugin-only; acceptance records are kept outside the plugin tree).

## Layout

```
.claude-plugin/   plugin.json + marketplace.json
hooks/            single session-start bootstrap (run-hook.cmd + bootstrap.sh)
skills/           10 skills — using-spine, framing, writing-plans, using-git-worktrees,
                  subagent-driven-dev, test-driven-development, systematic-debugging,
                  requesting-code-review, finishing-a-branch, config-contract
agents/           spine-implementer, spine-task-reviewer, spine-fix, spine-final-reviewer
commands/         /spine:frame, /spine:build, /spine:finish
templates/.spine/ per-repo config scaffold (config, danger-paths, context, progress ledger)
```

## How it works (the loop)

1. **FRAME** — grill one question at a time, pin the `.spine/config.md` contract, HARD-GATE on design approval.
2. **PLAN** — decompose into bite-sized, individually testable tasks.
3. **BUILD** — controller dispatches a fresh `spine-implementer` per task (TDD: RED→GREEN→REFACTOR), then a `spine-task-reviewer` (tests first, two verdicts, "do not trust the report"), then `spine-fix` for findings. The **controller** owns the `.spine/progress.md` ledger, never the subagent.
4. **REVIEW** — one `spine-final-reviewer` over the whole branch on the most capable model.
5. **FINISH** — verify the suite, then merge / PR / keep / discard. Data migrations are never autonomous.

## License

MIT. Internal bOnline tooling.
