# Spine

Spine is a complete software development methodology for Claude Code, built on a
context-isolated subagent engine with disciplines enforced in tooling, not willpower.

## Quickstart

Give your agent Spine: [Claude Code](#install).

## How it works

It starts the moment you ask for anything that touches code. Spine's bootstrap fires at
session start, and the `framing` skill hard-gates before a single line is written — it
doesn't jump into code, it grills you one question at a time, tags each with its own honest
confidence (0–100%), asks the lowest-confidence ones first, and stops once the design is
~95% settled. Everything above that gets stated as an assumption instead of spending a
question on it.

Once you approve the design, your agent writes a plan explicit enough for a skilled
engineer with no context and questionable taste to follow — exact interfaces, TDD from the
start, one task per reviewable unit.

Say go, and a **controller** takes over: dispatching a fresh, isolated subagent per task,
reviewing each one's spec compliance and code quality before moving on, and never trusting
a subagent's own report over the actual diff. It runs for hours without stopping unless it
hits a real blocker. When every task is done, one more subagent reviews the *entire* branch
on the most capable model available — the only backstop that catches what per-task review
structurally can't.

None of this is advisory. A design that isn't approved, a config contract that isn't pinned
and asserted, a merge without a passing review on record — all three are blocked at the tool
level, not just written down somewhere. A gate that depends on someone remembering it isn't
a gate.

## Install

```
/plugin marketplace add mdliad-se/spine
/plugin install spine
```
Restart the session. (Private repo — installers need access granted on `mdliad-se/spine`.)

**Local development** (working on Spine itself, no GitHub round-trip):
```
/plugin marketplace add /path/to/Spine Plugin
/plugin install spine
```

> **Conflict:** Spine absorbs Superpowers — running both clashes (duplicate bootstraps,
> duplicate skill names, Superpowers' `brainstorming` still auto-firing alongside Spine's
> `framing`). Disable `superpowers` before using Spine (`/plugin` → manage → disable).

## The Basic Workflow

1. **framing** — Fires before any code. Grills one confidence-tagged question at a time,
   pins the `.spine/config.md` cross-cutting contract, hard-gates on your approval.
2. **using-git-worktrees** — Fires after approval. Isolated workspace on a new branch,
   clean-baseline verified, FRAME approval carried forward correctly.
3. **writing-plans** — Fires with an approved design. Bite-sized tasks, exact interfaces,
   seam vocabulary (humans own the interface, the AI fills the implementation).
4. **subagent-driven-dev** + **test-driven-development** — Fires with a plan. Fresh
   `spine-implementer` per task (RED→GREEN→REFACTOR), then `spine-task-reviewer` (tests
   first, two verdicts, findings tagged `[LOGIC]`/`[STYLE]`), then `spine-fix` for findings.
5. **requesting-code-review** — Fires once, after all tasks. One `spine-final-reviewer`
   over the whole branch, most capable model — the only cross-task backstop.
6. **browser-qa** — Fires for user-facing work. Drive the real running app, verify by
   observation, record a receipt. Mandatory dual-product pass for cross-cutting work.
7. **finishing-a-branch** — Fires when everything's clean. Verifies the suite, presents
   merge/PR/keep/discard — merge/push is blocked without a matching review receipt.

**The agent checks for relevant skills before responding to anything.** Mandatory, not
suggested — that's `using-spine`'s own governing rule.

## What's Inside

### Skills Library

**Alignment** — `framing` (confidence-tagged grilling, domain glossary, hard design gate)

**Planning** — `writing-plans` (seam vocabulary, durable interfaces), `config-contract`
(pins and asserts cross-cutting context before task one)

**Isolation** — `using-git-worktrees` (worktree or in-place branch, FRAME-approval
carry-forward, clean-baseline precondition)

**Building** — `subagent-driven-dev` (the engine — fresh subagent per task, two-stage
review, task classifier), `test-driven-development` (RED-GREEN-REFACTOR, no exceptions)

**Debugging** — `systematic-debugging` (root-cause before fix)

**Review** — `requesting-code-review` (whole-branch final pass, tests-read-first,
"do not trust the report")

**QA** — `browser-qa` (real-app verification, dual-product for cross-cutting work)

**Finishing** — `finishing-a-branch` (test verification, shipping discipline, capability
and QA checks, compound/retro)

**Meta** — `using-spine` (governing rules, skill index, named gates, hook-path fallback)

### Agents

`spine-implementer` · `spine-task-reviewer` · `spine-fix` · `spine-final-reviewer` — each
dispatched fresh, fed only what it needs as files, never inheriting session history.

### Named Gates (enforcement, not suggestion)

| Gate | Blocks |
|---|---|
| **Frame Gate** | code writes until FRAME is approved for this branch |
| **Config Gate** | code writes until `.spine/config.md` exists |
| **Assert Gate** | code writes until the config contract is asserted |
| **Review Gate** | `git merge`/`git push` until a passing whole-branch review matches the current tip |
| **Boundary Gate** | writes crossing a configured import-boundary rule |

Each name matches the exact wording in that gate's own deny message — if you got blocked,
this table tells you what you saw.

## Philosophy

- **AI drafts, humans decide** — and the human must be capable of verifying, not just
  nominally accountable.
- **A gate that depends on willpower is not a gate.** Enforce in tooling, or assume it
  gets skipped under deadline.
- **Code is the source of truth.** Specs gate the build; they don't replace what runs.
- **Smaller and more often beats bigger and later.**
- **Isolation is blind above the task.** Pin cross-cutting context before task one —
  a subagent fed only its brief cannot see it's pointed at the wrong place.

## Provenance

Spine is built by merging Superpowers (the context-isolation engine) with mattpocock/skills
(the FRAME alignment stage) and the *ideas* of ECC, gstack, and agent-skills — those three
contribute no copied files, only concepts reimplemented as Spine's own tooling. Full
design rationale: `The Spine — End-to-End Engineering Process.md`.

## Status

Phase 1 (walking skeleton) and Phase 2 (enforcement) closed, live-confirmed across 9 test
rounds. Phase 3 (grafts — confidence-tagged grilling, capability tracking, browser QA)
complete. First full PLAN→BUILD→REVIEW→FINISH cycle completed and independently verified.
Full version history, every bug found and fixed, and what's still unproven: see
`PHASE1-3-ACCEPTANCE.md`.

## License

MIT. Internal bOnline tooling.
