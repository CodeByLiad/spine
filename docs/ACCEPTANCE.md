# Spine Phase 1 — Walking Skeleton Acceptance

**Date:** 2026-06-29
**Build:** commits db27fca .. 49b3125 (9 task commits)

## Automatable checks (run by the controller) — PASS

| Check | Result |
|---|---|
| Plugin tree complete (manifests, hooks, 10 skills, 4 agents, 3 commands, templates) | PASS |
| `plugin.json` / `marketplace.json` / `hooks/hooks.json` valid JSON | PASS |
| All 10 skills have `name:` + `description:` frontmatter | PASS |
| Exactly one FRAME owner (`frame`), no `brainstorming` skill present | PASS |
| `hooks/session-start/bootstrap.sh` emits `SPINE ACTIVE` marker | PASS |
| Engine skills re-pointed: no `superpowers:` refs, no `.superpowers/` paths | PASS |
| Controller-owns-ledger rule present in `subagent-driven-dev` | PASS |

Skills present: config-contract, finishing-a-branch, frame, requesting-code-review,
subagent-driven-dev, systematic-debugging, test-driven-development,
using-git-worktrees, using-spine, writing-plans.

## Whole-branch final review (opus, read-only) — PASS after fixes

Final review verdict: Plan+Spec **PASS**, Quality **CHANGES-NEEDED** → 2 Important + 4 Minor findings, all fixed in commit `5e0ccda` and re-verified clean:
- CRLF shell scripts normalized to LF + `.gitattributes` pinning `eol=lf` (was breaking the shebang on non-Windows).
- The four `spine-*` agents wired into the engine dispatch (were orphaned).
- Dangling `verification-before-completion` reference removed; stale `brainstorming` prose, stale finish announce name, and `HEAD~1` example all fixed.

Re-review (static, deterministic): 0 CR bytes in scripts; spine-* agents referenced (2/2/1/3); 0 dangling/stale refs; JSON valid; sole FRAME owner; bootstrap emits marker. **Quality gate PASS.**

## ⚠️ Precondition for the interactive gates — disable Superpowers first

Spine and the installed **Superpowers** plugin clash: two session-start bootstraps, duplicate skill names, and Superpowers' `brainstorming` still auto-fires — which invalidates gate 3 below. Before running the gates: `/plugin` → manage → **disable `superpowers`** (leave `caveman`, comms-only). Disable (don't uninstall) until Spine's bootstrap is confirmed firing; then uninstall Superpowers permanently.

## Interactive gates (require a fresh Claude Code session with the plugin installed, Superpowers disabled) — PENDING

These cannot be driven by a subagent; the user runs them:

1. **Install:** `/plugin marketplace add D:\Project\AI Agents\spine` then `/plugin install spine`; restart. Expected: installs without manifest error.
2. **Bootstrap present:** new session's start context contains `SPINE ACTIVE`.
3. **v1 gate (one FRAME fires):** send `build a react todo list`. Expected: `frame` auto-fires and HARD-GATES before any code; **no** `brainstorming` fires; exactly one alignment skill engages.
4. **Config-contract gate:** in a throwaway repo with a deliberately wrong `.spine/config.md` DB/project, start a build. Expected: `config-contract` flags the mismatch before task one.

**Phase 1 is PASS only when checks 1–4 above are confirmed in a live session.**
Record results here after running them.
