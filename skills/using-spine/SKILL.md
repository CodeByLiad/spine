---
name: using-spine
description: Use at the start of any coding task — establishes the Spine governing rules, the skill index, the auto-trigger discipline, and the bounded fallback for locating hook scripts when $CLAUDE_PLUGIN_ROOT is unset.
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
match=""; count=0
for d in ~/.claude/plugins/cache/*/spine/*/; do
  [ -f "${d}.orphaned_at" ] && continue
  [ -f "${d}hooks/<script>" ] || continue
  match="${d}hooks/<script>"; count=$((count + 1))
done
[ "$count" -eq 1 ] && printf '%s' "$match"
```

Do NOT shorten this to `ls .../hooks/<script> | head -1` — a machine with more than one
Spine version cached (the normal case after any update) has multiple matches, `ls` sorts
them alphabetically, and `head -1` silently picks the *oldest* one, which the harness may
already have marked orphaned (`.orphaned_at` present in that version's cache directory) —
running a superseded hook script against the current `.spine/config.md` is exactly the
kind of unverified-contract failure Gate C exists to catch, just relocated one level down.

**This refuses to guess under ambiguity rather than trying to resolve it — same principle
as `merge-gate` denying an unresolvable chained target instead of picking one.** Skipping
`.orphaned_at` directories handles the common case (one stale version, one active one), but
two states are genuinely unresolvable from inside a plain shell with no way to ask the
harness which version *this session* is bound to: (a) more than one non-orphaned version
present (right after an update, before the harness's own orphaning sweep runs), and (b)
every version present is marked orphaned, yet an already-running session's real
`$CLAUDE_PLUGIN_ROOT` may still validly point at one of them. Guessing wrong in either case
means silently running a different version's hook logic than the one the rest of the
session's state assumes — worse than admitting the fallback couldn't resolve it. So the
loop only emits a path when exactly one non-orphaned candidate exists; any other count
(zero or more than one) intentionally produces no output.

This is bounded to the one directory any Spine install actually lives in — it is not a
fallback license to widen the search if it comes up empty; if it does (whether from no
match or genuine ambiguity), report BLOCKED with what was tried rather than escalating to a
broader filesystem scan (`find /`, `dir C:\ /s`, or similar). A whole-disk search is slow,
forces a permission prompt, and — from a subagent — repeats on every fresh dispatch since
nothing carries the result forward. (On Windows Git Bash, `~` resolves the same way as
Unix/macOS.)
