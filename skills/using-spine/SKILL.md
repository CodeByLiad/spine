---
name: using-spine
description: Use at the start of any coding task — establishes the Spine governing rules, the skill index, and the auto-trigger discipline.
---

# Using Spine

## Governing rules (override everything below on conflict)
1. AI drafts, humans decide — and the human must be capable of verifying.
2. **Code is the source of truth.** Specs gate the build; they do not replace the running artifact.
3. A gate that depends on willpower is not a gate. Enforce in tooling, or assume it gets skipped.
4. Smaller and more often beats bigger and later.
5. Isolation is blind to everything above the task — pin cross-cutting context (the `.spine/config.md` contract) before task one.

## How to use skills
If there is even a 1% chance a skill applies, invoke it before responding. One skill owns each stage:

| Stage | Skill | Human gate |
|---|---|---|
| FRAME | `framing` | approve design (no code before) |
| PLAN | `writing-plans` | approve plan |
| ISOLATE | `using-git-worktrees` | clean baseline verified |
| BUILD | `subagent-driven-dev` + `test-driven-development` | per-task review loop |
| DEBUG | `systematic-debugging` | root-cause before fix |
| REVIEW | `requesting-code-review` | resolve findings |
| FINISH | `finishing-a-branch` | pick merge/PR/keep/discard |

Do NOT use any `brainstorming` skill — `framing` owns alignment in Spine.

## Two human gates, ask the user
Run autonomously between gates. Stop and ask the user at: design approval, finish path, sensitive ops (auth, payments, schema, data migration — never autonomous), `BLOCKED`, genuine ambiguity.
