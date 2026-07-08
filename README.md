# Spine

**The company coding agent, as one standalone Claude Code plugin.** One install, zero dependency.

Spine is a context-isolated subagent engine with enforced disciplines, packaged as a single plugin. A **controller** runs the build autonomously between two human gates, dispatching fresh isolated subagents (implementer, reviewer, fix, final reviewer) fed inputs as files. It codes anything — software, websites, any stack.

It is built by merging upstream source from five frameworks into one coherent bundle: Superpowers (the engine), mattpocock/skills (the FRAME alignment stage), and the ideas of ECC, gstack, and agent-skills — none of those three contribute copied files.

## Status

**v0.4.10 — Phase 1 + Phase 2 closed (live-confirmed, 9 rounds). Phase 3 complete (3 of 3 parts) + 5 graft gaps closed + real bugs fixed from actual usage, adversarially reviewed by `spine-final-reviewer` itself (dogfooded on this exact fix, four rounds running) + first fully completed real build cycle.**

v0.4.9's own review (same dogfood pattern as the fallback chain) found the fix itself had 3 more real defects, fixed in v0.4.10: the worktree copy-forward recipe copied from a bare relative path *after* `cd "$path"` had already changed what that path resolved to, so the copy silently did nothing (verified fixed by testing the corrected recipe end-to-end — all 5 files land correctly, `config-hash` validates identically in the new location); the carry-forward list was missing `danger-paths` and, more seriously, `import-boundaries` — the latter has no scaffold logic of its own and fails open on a missing file, so every new worktree was silently running with the Boundary Gate fully disabled; and the shell-discipline guidance told a Bash-only-toolset agent to reach a "different tool call" for PowerShell, which doesn't match `spine-implementer`'s actual declared tools — reworded to describe it as the harness routing one shell command to either git-bash or PowerShell, identifiable by the command's own displayed label.

**First real PLAN→BUILD→REVIEW→FINISH cycle carried all the way to a merged, independently-verified result** (a Python string-case CLI, greenfield): 3 tasks built and reviewed clean, the final whole-branch review caught a genuine `[LOGIC]` bug (acronym+digit splitting) that no per-task review saw, one fix subagent resolved it, re-review passed clean, Gate D (Review Gate) receipt recorded, merged to `main`. The user independently re-verified the result (test suite, the specific bug's fix, git history, the actual diff) rather than trusting the ship report — first genuine end-to-end proof the build engine works, not just that its gates fire.

That run surfaced 3 more real gaps, all fixed in v0.4.9: **(1)** `frame-approved` isn't carried forward when ISOLATE creates a new branch/worktree off an already-approved one (v0.4.6 only self-heals the unborn-`HEAD` case) — now an explicit documented step in `using-git-worktrees` for both the same-directory and new-worktree cases (the latter copies `.spine/config.md`+`config-asserted` forward too, since the hash check is content-based, not path-based). **(2)** `using-spine`'s bounded `$CLAUDE_PLUGIN_ROOT`-unset fallback only covered `hooks/<script>`, not `skills/<skill>/scripts/<script>` (`task-brief`, `review-package`) — hit on nearly every task, always falling back to a hardcoded dev-only path — now the same fallback recipe covers both. **(3)** implementer subagents mixed Bash/cmd.exe/PowerShell syntax inconsistently across tool calls on Windows (a `cd /d` attempt and a bash-`&&`-in-PowerShell attempt both failed to parse) — now explicit shell-discipline guidance in `spine-implementer` and its dispatch template.

Also added: **named gates** — Frame/Config/Assert/Review/Boundary — matching the exact wording each hook's own deny message already uses, documented in `using-spine` so a denied user can look up what they saw on screen instead of translating a bare letter (Gate A-D still work as an alias, not replaced).

Prior chain (v0.4.4-0.4.8): a second RealCycle attempt showed `framing` correctly checking `$CLAUDE_PLUGIN_ROOT` before recording the config-hash assertion — but the variable was empty in the *controller's own shell too*, not just a subagent's, disproving v0.4.5's own assumption that the controller reliably has it. v0.4.6 centralized a bounded fallback in `using-spine`; its own review caught a real bug (`ls .../hooks/<script> | head -1` picks the oldest cached version alphabetically, possibly already-orphaned, not the active one) and two unguarded invocation points. v0.4.7 fixed both — skip any `.orphaned_at`-marked cache directory instead of trusting sort order — but that review then found the fix itself only handles the common case: a machine could have more than one *non*-orphaned version present (right after an update), or every version present marked orphaned while an already-running session's real root still validly points at one of them (both states verified as real, not hypothetical, against this machine's own cache). v0.4.8 stops trying to guess in either case: the fallback now only emits a path when exactly one non-orphaned candidate exists, and produces nothing otherwise — routing straight into the existing "report BLOCKED, don't guess" instruction, the same fail-closed-under-ambiguity principle `merge-gate` already uses for unresolvable chained targets.

First real PLAN→BUILD→REVIEW→FINISH attempt (not a scripted gate check) found two connected bugs in the FRAME stage: `framing`'s checklist never instructed actually writing `.spine/frame-approved` after the user approved — so a real approval happened but Gate A still denied the first implementer dispatch. And `framing` wrote `config.md` but never ran config-contract's own assertion before build started, so Gate C was still open too — the implementer hit that deny and, lacking `$CLAUDE_PLUGIN_ROOT` of its own, resorted to a whole-filesystem `find /` to locate the hook script, repeating on every fresh dispatch and forcing a permission prompt each time (v0.4.4).

Once Spine's own hooks went live against this repo, `git push` on that very fix got blocked by Gate D — no receipt existed yet. Rather than self-certifying, dispatched a real `spine-final-reviewer` against the diff, which found the v0.4.4 fix was itself incomplete: the frame-approved marker would go stale again the moment the first commit landed (branch flips from git's `HEAD` sentinel to its real name) with nothing to re-record it, reproducing the exact bug it fixed; the implementer-side escalation rule only triggered on messages naming a script, but none of the real deny text does; and `framing`'s Gate C fix collapsed "run the assertion" into "record the hash," letting the check pass without the assertion ever happening. v0.4.5 moves the HEAD-to-real-branch case into `frame-gate.sh` itself (a gate depending on a skill remembering to re-record isn't a gate — rule 3), broadens the escalation trigger to any gate deny, and makes the real assertion explicit before the hash. Verified directly: self-heal fires on a real first commit, a genuine switch to a different unapproved branch still denies.

Live round 8 (v0.4.2) confirmed both new graft-gap closures live and found one real bug beyond the checklist: `merge-gate`'s per-segment tokenizer word-splits on raw whitespace with no quote awareness, so `git -C "<path with spaces>" merge <ref>` split the quoted path into several tokens, mis-identified a path fragment as the git subcommand, and let the merge run un-gated (the `-C` redirect-deny path never triggered). Only a problem for repos whose path contains spaces (common on Windows, e.g. anything under `Program Files`-style trees) — fixed in v0.4.3 by collapsing spaces inside quoted spans to a placeholder byte before tokenizing (pure text scan, no `eval`, no code execution), so a quoted argument counts as one token regardless of embedded spaces. Verified against the exact reported case plus the full 10-case regression suite (spaceless `-C`, plain deny/allow/stale, chained-non-first-subcommand, text-mention-only, command-substitution, unrelated-chained, env-prefixed) — all still correct.

An audit against the stage-by-stage base/graft table (the design doc's own summary of what each stage should carry) found 3 real gaps that had been missed while building the hook-backed mechanisms: `writing-plans` never actually used mattpocock's seam/deep-module vocabulary (the word "seam" appeared, but not the practice); both reviewer prompts checked tests but never read them *first* (agent-skills' specific graft); `finishing-a-branch` never mentioned shipping discipline (feature flags, incremental rollout, reversible-by-default). All three closed in v0.4.1 — prose/skill changes, not hook-testable; correctness means "does a real review/plan/finish actually follow this," which needs a live session to confirm, same as the other prose-only grafts.

A second audit against the full process-doc corpus (COMPOUND stage, clean-baseline precondition) found 2 more gaps, closed in v0.4.2: the COMPOUND stage's retro + doc-sync habit (§9 of the process doc) was never built — only capability tracking, its third item, existed — now added to `finishing-a-branch` as an informational check; and `using-git-worktrees`' Step 3 verified tests pass but never checked `git status --porcelain` was clean before starting autonomous work, so a dirty starting tree could silently make later per-task commits unrollbackable — now checked explicitly before the baseline test run.

**Phase 1** (the walking skeleton): FRAME → plan → worktree → build loop → whole-branch review → finish, with a per-repo `.spine/` config, a boot assertion, and a hash-bound config-assertion gate (Gate C).

**Phase 2** (enforcement) adds three mechanisms on top of Phase 1:
- **Gate D** (`merge-gate`) — `git merge`/`git push` blocked until a passing whole-branch review is recorded for the integrated branch's tip (`.spine/review-receipt`). Requires a review before *every* merge, not just danger-path-triggered ones. Segment-based command parsing closes chaining bypasses (`git merge x; echo y`, `git branch x; git merge y`) without false-positiving on unrelated commands that merely mention "git"/"merge" as text.
- **Task classifier** (`classify-task.sh`) — advisory Mode A/B scoring: files-touched against `.spine/danger-paths` (mechanical) plus new-contract/ambiguity (judgment, per `subagent-driven-dev`). Mode B tasks get wide context and no fast-path; every task still goes through Gate D regardless of mode.
- **Golden-rule import-boundary guard** (`boundary-gate`) — a write matching a `.spine/import-boundaries` rule is blocked if its new content contains that rule's forbidden reference (JSON-unescaped before matching, so quoted references match real quoted imports). Generalizes "an app's routes/services must not import another product's schema" for a repo with no fixed notion of "product."

**Phase 1 + 2 status:** six live test rounds (v0.2.0 found 2 real defects → v0.2.1 fixed them, found a broader variant of one → v0.2.2 fixed that cleanly → v0.3.0 clean, Phase 3 part 1 added → v0.3.1 found a boundary-guard quote bug → v0.3.2 fixed, confirmed live) — all gates PASS live, no known open defects. Full history in the acceptance records (kept outside the plugin tree).

**Phase 3** (grafts) — all three parts built, one at a time:
- ✅ **Confidence-tagged grilling** — `framing`'s grill tags each question with the agent's honest 0–100% confidence in its own recommendation, asks lowest-confidence items first, and stops once overall design confidence reaches ~95% (remaining high-confidence items become stated assumptions instead of spent questions). Live-confirmed, 2 rounds.
- ✅ **Capability tracking** — both reviewer prompts (`task-reviewer-prompt.md`, `code-reviewer.md`) tag every finding **[LOGIC]** (real correctness bug) or **[STYLE]** (taste/naming/formatting — behaves correctly either way). The controller appends one line per task and per final review to `.spine/capability-log.md` (`logic=N style=N verdict=...`) — pure visibility, never a gate. `finishing-a-branch` surfaces a run of style-only entries as a one-line note (never blocks). Live-confirmed, 2 rounds.
- ✅ **Browser QA** (`browser-qa`, gstack-derived idea, tool-agnostic) — before finishing user-facing work, open the real running app, drive the flow, verify by observation, generate a regression test, record `.spine/qa-receipt`. **Mandatory dual-product pass for every Mode-B task** — a single-product QA pass does not satisfy Mode B. Honestly documented as process discipline, not a code-enforced gate: there's no mechanical way to prove a real browser session happened the way Gate D proves a hash match. `finishing-a-branch` surfaces a missing/stale receipt as a note, never a block. Not yet live-tested (needs a real running app + browser-automation tool in the test session).

Phase 4 (multi-harness: Cursor, Antigravity) remains a separate, unbuilt plan.

## Install

```
/plugin marketplace add mdliad-se/spine
/plugin install spine
```
Restart the session. (Private repo — installers need access granted on `mdliad-se/spine`.)

**Local development install** (working on Spine itself, no GitHub round-trip):
```
/plugin marketplace add D:\Project\Plugins\Spine Plugin
/plugin install spine
```

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
5. **Gate D** — `git merge`/`git push` denied without a matching `.spine/review-receipt`; allowed once the controller records one after a clean final review; re-denied if commits land after the receipt (stale tip); denied outright on a redirect flag or a chained/obscured merge/push, regardless of which git subcommand comes first.
6. **Task classifier** — a task touching a `.spine/danger-paths` glob classifies Mode B; one that doesn't classifies Mode A.
7. **Boundary guard** — a write matching a `.spine/import-boundaries` rule with the forbidden reference in its new content is denied; the same write without the reference, or to a non-matching path, is allowed.

Live-confirmed across 4 rounds (see acceptance records) — Gate D's chaining fix and both round-3/4 regressions specifically re-verified live, not just via hook simulation.

**Phase 3:**
8. **Confidence-tagged grilling** — the first grill question carries a real 0–100% confidence number; open decisions are ranked lowest-confidence-first; anything ≥~90% becomes a stated assumption instead of a spent question. Live-confirmed.
9. **Capability tracking** — reviewer findings are tagged [LOGIC]/[STYLE]; the controller appends a tally line to `.spine/capability-log.md` per task and per final review; `finishing-a-branch` surfaces a one-line note if a branch's entries are style-only. Live-confirmed.
10. **Browser QA** — `browser-qa` records `.spine/qa-receipt` after a real-app pass; `finishing-a-branch` notes a missing/stale receipt for user-facing or Mode-B work. Not yet live-tested.

## Layout

```
.claude-plugin/   plugin.json + marketplace.json
hooks/            session-start bootstrap, frame-gate (A/B/C), merge-gate (D),
                  boundary-gate (golden-rule), classify-task.sh, config-hash.sh,
                  review-receipt.sh, qa-receipt.sh, run-hook.cmd
skills/           11 skills — using-spine, framing, writing-plans, using-git-worktrees,
                  subagent-driven-dev, test-driven-development, systematic-debugging,
                  requesting-code-review, browser-qa, finishing-a-branch, config-contract
agents/           spine-implementer, spine-task-reviewer, spine-fix, spine-final-reviewer
commands/         /spine:frame, /spine:build, /spine:finish
templates/.spine/ per-repo scaffold (config, danger-paths, import-boundaries,
                  context, progress ledger, capability-log)
```

## How it works (the loop)

1. **FRAME** — grill one question at a time, each confidence-tagged (0–100%, lowest first, until ~95% overall), pin the `.spine/config.md` contract, HARD-GATE on design approval.
2. **PLAN** — decompose into bite-sized, individually testable tasks; classify each Mode A/B (Phase 2).
3. **BUILD** — controller dispatches a fresh `spine-implementer` per task (TDD: RED→GREEN→REFACTOR; wide context for Mode B), then a `spine-task-reviewer` (tests first, two verdicts, findings tagged [LOGIC]/[STYLE], "do not trust the report"), then `spine-fix` for findings. The **controller** owns the `.spine/progress.md` ledger and the `.spine/capability-log.md` tally, never the subagent. Writes crossing a configured import boundary are blocked outright.
4. **REVIEW** — one `spine-final-reviewer` over the whole branch on the most capable model, findings tagged [LOGIC]/[STYLE]; on a clean pass the controller records `.spine/review-receipt` and the capability-log entry.
5. **QA** — for user-facing work (mandatory dual-product for Mode B), `browser-qa` drives the real running app and records `.spine/qa-receipt`. Process discipline, not a code-enforced gate — honestly documented as such.
6. **FINISH** — verify the suite, then merge / PR / keep / discard — merge/push is blocked (Gate D) without a matching, current receipt; a missing/stale QA receipt surfaces as a note. Data migrations are never autonomous.

## License

MIT. Internal bOnline tooling.
