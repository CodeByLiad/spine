---
name: framing
description: Use before any creative or build work — aligns on intent, scope, and design before code. Grills one question at a time, each confidence-tagged (0–100%, lowest first, until ~95% overall), gives a recommended answer per question, self-answers from the codebase, and HARD-GATES on design approval. Spine's single alignment stage (replaces brainstorming).
---

# Frame — align before any code

<HARD-GATE>
Do NOT write code, scaffold, or take any implementation action until you have presented a design and the user has approved it. Applies to every project regardless of perceived simplicity. The ONLY skill you invoke after the FRAME stage is `writing-plans`.
</HARD-GATE>

## Anti-pattern: "this is too simple to need a design"
Every task runs FRAME — a todo list, a one-function utility, a config tweak. "Simple" is where unexamined assumptions waste the most work. The design can be short, but you MUST present it and get approval.

## Checklist
You MUST create a task (todo) for each item below and complete them in order. Do not collapse or skip.

1. **Explore project context** — files, docs, recent commits, `.spine/context.md` glossary if present.
2. **Config contract (hard sub-gate — config.md is a FRAME deliverable, not deferred to build).** If no `.spine/config.md` exists, create it here by grilling the user, then `Write` `.spine/config.md` directly with the answers — do NOT shell `find`/`cp` and do NOT read the plugin's templates (the hook handles the rest of the skeleton for you; searching for templates just spawns permission prompts). Write exactly this shape, filled in:
   ```markdown
   # .spine/config.md — pinned cross-cutting context (asserted before task one)
   - Stack:            <!-- grilled -->
   - Test runner:      <!-- grilled -->
   - DB / project / env: <!-- EXACT project ref, not "the dev one" -->
   - Auth context:     <!-- identity source -->
   - Conventions:      <!-- naming, folder layout, invariants -->
   - Boot assertion:   <!-- startup check that fails loudly on wrong DB/env -->
   ```
   The rest of the `.spine/` skeleton (`context.md`, `danger-paths`, `progress.md`) is auto-scaffolded silently by the `pre-tool-use/frame-gate` hook — do NOT create those yourself. Enforced in tooling: the hook DENIES every code write until `.spine/config.md` exists. Create it now; do not wait for the deny.

   **Immediately after writing config.md, close Gate C too — don't leave this for build time.** Run the `config-contract` skill's own assertion + hash-recording step now:
   `sh "$CLAUDE_PLUGIN_ROOT/hooks/config-hash.sh" .spine/config.md > .spine/config-asserted`
   If you skip this here, the first implementer subagent dispatched in BUILD hits Gate C's deny instead of you — and a subagent has no reliable way to locate `$CLAUDE_PLUGIN_ROOT` on its own (it is not inherited from the controller's session), so it either stalls or, worse, tries an expensive/dangerous whole-filesystem search to find the hook script itself. Closing Gate C here, while you still have the correct plugin root, prevents that entirely.
3. **Grill — one question per message, confidence-tagged (Phase 3).** Ask exactly ONE question, then STOP and wait for the answer before the next. For each question give: your own recommended answer + reasoning, and a **confidence number (0–100%)** — how sure you are that recommendation is right without the user's input. Prefer multiple-choice. Self-answer from the codebase rather than asking whenever you can.
   - **Order by confidence, lowest first.** The lowest-confidence open decision is where a question earns the most — ask it before higher-confidence ones.
   - **Run until overall design confidence reaches ~95%**, not a fixed question count. If every remaining open decision is already ≥90% confident, stop grilling and state those as assumptions in the design (step 7) instead of spending a question on them — the number is what tells you (and the user) where NOT to spend a question.
   - A confidence number is your own honest estimate, not a formality — do not pad it to justify skipping a question you're actually unsure about.
4. **Force scope boundaries** — in-scope AND explicit out-of-scope.
5. **Challenge overloaded terms** against `.spine/context.md`; update the glossary the moment a term resolves (terms only, no implementation detail).
6. **Propose 2–3 approaches** with trade-offs and a recommendation.
7. **Present the design** in sections scaled to complexity; get approval per section.
8. **Write the design doc** to `docs/spine/specs/YYYY-MM-DD-<topic>-design.md`.
9. **Self-review the spec** (placeholders, contradictions, scope, ambiguity); fix inline.
10. **Ask the user to review the written spec. On approval, record it, then invoke `writing-plans`.**
   Approval is not real until it's on disk — Gate A reads the marker file, not your memory
   of the conversation. Record it in the SAME turn as the approval:
   `echo "$(git rev-parse --abbrev-ref HEAD)" > .spine/frame-approved`
   If there are no commits yet, `git rev-parse --abbrev-ref HEAD` resolves to the literal
   string `HEAD` — that's fine, Gate A compares against whatever the branch name resolves
   to at write time and at check time. If a commit lands later and the branch gets a real
   name, `frame-approved` must be re-recorded against the new name or Gate A will re-deny
   with a stale marker (same idea as Gate C's stale-hash re-deny — do not treat this as a
   bug if it happens, re-record and move on).

Steps 1–2 run autonomously (no questions to the user). The first time you stop for the user is step 3's grill. That is the intended hand-off point.
