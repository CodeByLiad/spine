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
2. **Config contract (hard sub-gate — config.md is a FRAME deliverable, not deferred to build).** If no `.spine/config.md` exists, resolve each field below, then `Write` `.spine/config.md` directly — do NOT shell `find`/`cp` and do NOT read the plugin's templates (the hook handles the rest of the skeleton for you; searching for templates just spawns permission prompts).

   **Resolving each field — use the user's own request first, ask second, never silently assume:**
   - If the user's request already states a field exactly (they said "React" — that answers Stack's framework), use it as given; no question needed for that specific part.
   - For anything the request leaves open, check: is this a choice among two or more commonly-used alternatives (a language, a framework variant, a build tool, a test runner, whether to persist data at all, which DB)? **If yes, this is a real open decision and must be asked — it is NOT eligible for step 3's high-confidence skip, no matter how standard one option is.** "Most people pick Vite" is not the same as "there is only one sane choice here" — the user might have a real reason to want something else, and defaults you never confirmed are exactly the kind of unexamined assumption FRAME exists to catch (see the anti-pattern note above). Reserve the confidence-skip for things where genuinely only one answer fits given what's already established (e.g., matching a lint config or naming convention already visible in the codebase).
   - These become the FIRST questions asked, using step 3's exact mechanism (one at a time, confidence-tagged, lowest-confidence first) — config-field questions are not a separate, quieter round; they're the start of the same grill, just gated to happen before config.md is written since Gate C needs it closed early.

   Once every field is answered or given, write exactly this shape:
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

   **Immediately after writing config.md, close Gate C too — don't leave this for build time.** First perform the actual assertion `config-contract` describes: either the boot-assertion check named in config.md's own "Boot assertion" field (run it, confirm it fails loudly on the wrong target), or — where nothing mechanical is possible — get the named human to explicitly confirm the seam. Only once that real check has happened, record it:
   `sh "$CLAUDE_PLUGIN_ROOT/hooks/config-hash.sh" .spine/config.md > .spine/config-asserted`
   If `$CLAUDE_PLUGIN_ROOT` is empty in your own shell (it often is — this is not reliably
   inherited by an ordinary Bash call even in the controller's own session, not just a
   subagent's), resolve it per `using-spine`'s bounded fallback rather than improvising a
   search of your own. Running only the hash command without the assertion behind it just
   makes Gate C's check pass on paper — the contract was never actually verified, which is
   the exact failure config-contract exists to catch. If you skip this here, the first
   implementer subagent dispatched in BUILD hits Gate C's deny instead of you — and a
   subagent has even less to work with than you do, so it stalls or improvises its own
   search. Closing Gate C here prevents that entirely. If config.md changes later (grilling
   in step 3 surfaces a correction), re-run the assertion and re-record before BUILD starts
   — a changed contract with a stale hash is exactly what Gate C is designed to catch.
3. **Grill — one question per message, confidence-tagged (Phase 3).** Ask exactly ONE question, then STOP and wait for the answer before the next. For each question give: your own recommended answer + reasoning, and a **confidence number (0–100%)** — how sure you are that recommendation is right without the user's input. Prefer multiple-choice. Self-answer from the codebase rather than asking whenever you can.
   - **Order by confidence, lowest first.** The lowest-confidence open decision is where a question earns the most — ask it before higher-confidence ones.
   - **Run until overall design confidence reaches ~95%**, not a fixed question count. If every remaining open decision is already ≥90% confident, stop grilling and state those as assumptions in the design (step 7) instead of spending a question on them — the number is what tells you (and the user) where NOT to spend a question.
   - A confidence number is your own honest estimate, not a formality — do not pad it to justify skipping a question you're actually unsure about.
   - **A choice among two or more commonly-used alternatives is not a ≥90% item, ever**, regardless of how standard one option is — same rule as step 2's config fields. "Everyone does it this way" describes a popular default, not an inferable fact about what THIS user wants. Reserve high confidence for things with genuinely one sane answer given what's already established, not for the most common choice among several reasonable ones.
4. **Force scope boundaries** — in-scope AND explicit out-of-scope.
5. **Challenge overloaded terms** against `.spine/context.md`; update the glossary the moment a term resolves (terms only, no implementation detail).
6. **Propose 2–3 approaches** with trade-offs and a recommendation.
7. **Present the design** in sections scaled to complexity; get approval per section.
8. **Write the design doc** to `docs/spine/specs/YYYY-MM-DD-<topic>-design.md`.
9. **Self-review the spec** (placeholders, contradictions, scope, ambiguity); fix inline.
10. **Ask the user to review the written spec. On approval, record the approval, then invoke `writing-plans`.**
    Approval is not real until it's on disk — Gate A reads the marker file, not your memory
    of the conversation. Record it in the SAME turn as the approval:
    `echo "$(git rev-parse --abbrev-ref HEAD)" > .spine/frame-approved`
    If there are no commits yet, this resolves to the literal string `HEAD` — that's expected
    and fine; the hook itself re-stamps the marker automatically the moment a real branch name
    exists (a first commit landing is not a re-approval event, so this needs no action from
    you). What DOES need a fresh approval: switching to a genuinely different branch after the
    fact, or restarting FRAME with a changed design — those are real re-approval events, not
    the same automatic case.

Step 1 always runs autonomously. Step 2 also runs autonomously ONLY when the user's own
request plus what step 1 found already answers every config field with certainty — that's
rare for anything beyond a trivial script. The first time you stop for the user is whenever
the first genuinely open decision surfaces, which is very often inside step 2 itself (stack/
persistence/test-runner choices), not always step 3. Do not let "steps 1–2 are autonomous"
become an excuse to silently assume a multi-option field just because asking would mean
stopping earlier than expected.
