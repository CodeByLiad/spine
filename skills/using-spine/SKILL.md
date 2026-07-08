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
| QA | `browser-qa` (user-facing work; mandatory dual-product pass for Mode B) | confirm flows pass live |
| FINISH | `finishing-a-branch` | pick merge/PR/keep/discard |

Do NOT use any `brainstorming` skill — `framing` owns alignment in Spine.

## Two human gates, ask the user
Run autonomously between gates. Stop and ask the user at: design approval, finish path, sensitive ops (auth, payments, schema, data migration — never autonomous), `BLOCKED`, genuine ambiguity.

## Resolving hook scripts when `$CLAUDE_PLUGIN_ROOT` is unset
Any skill that shells out to a hook (`config-hash.sh`, `review-receipt.sh`, `qa-receipt.sh`,
`classify-task.sh`) normally does so via `$CLAUDE_PLUGIN_ROOT/hooks/<script>`. That variable
is reliably set inside the plugin's own PreToolUse/SessionStart hook invocations, but is
**not** reliably inherited by an ordinary Bash tool call — this is true for subagents AND for
the controller's own shell; do not assume the controller has it just because it's the main
session. If it's empty, resolve it with exactly this bounded check, never anything wider:

```
ls ~/.claude/plugins/cache/*/spine/*/hooks/<script> 2>/dev/null | head -1
```

(On Windows Git Bash, `~` resolves the same way.) This is bounded to the one directory any
Spine install actually lives in — it is not a fallback license to widen the search if it
comes up empty; if it does, report BLOCKED with what was tried rather than escalating to a
broader filesystem scan (`find /`, `dir C:\ /s`, or similar). A whole-disk search is slow,
forces a permission prompt, and — from a subagent — repeats on every fresh dispatch since
nothing carries the result forward.
