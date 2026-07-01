=== SPINE PHASE 1 TEST REPORT ===

report_type: auto

build_under_test: 0.1.2 (framing-rename fix)

date: 2026-07-01

session: fresh-restart (yes — SPINE ACTIVE bootstrap present at session start)

superpowers_disabled: yes (no `brainstorming` skill in available-skills list; `framing` present instead; none fired)

previous_install_refreshed: unconfirmed-from-session (inferred yes — bootstrap says `framing` owns alignment, the 0.1.2 rename; operator-side `/plugin` version listing NOT inspectable from session)

git_repo_in_workdir: yes (`git rev-parse --is-inside-work-tree` = true)

  

OVERALL: PASS

  

gate_1_install:      PASS | version_shown: inferred 0.1.2 (not directly inspected; `framing` rename present in bootstrap, which is the 0.1.2 change) | observed: Spine active and operational; using-spine + framing skills resolved and their bodies loaded; no manifest/JSON/duplicate-hook error seen. Operator-side `/plugin` listing NOT inspected from session. | symptom_if_fail: none

  

gate_2_bootstrap:    PASS | spine_active_present: yes | framing_owns_alignment: yes | observed: session-start <system-reminder> contained "SPINE ACTIVE. You are running the Spine coding process." plus the stage-ownership table (FRAME → `framing`) and the line "Do NOT use Superpowers `brainstorming` — `framing` owns alignment." No stale "frame owns alignment" text. | symptom_if_fail: none

  

gate_3_one_frame:    PASS | skill_that_fired: framing (correct; using-spine also fired first per bootstrap, as expected) | resolved_to_command: no | frame_body_injected: yes | grilled_one_at_a_time: yes | brainstorming_fired: no | code_before_approval: no | spec_path_correct: yes | symptom_if_fail: none | observed: `Skill(spine:framing)` returned "Launching skill: spine:framing" AND the SKILL.md body injected — HARD-GATE block plus numbered Checklist steps 1-10 appeared in context. This is the fix confirmed working: contrast phase1 (0.1.1) where `Skill(spine:frame)` resolved to the command redirect and the body did NOT inject. Grill ran strictly one-question-per-message (Q1 stack → Q2 persistence → Q3 features → Q4 styling → Q5 theme), each with a recommended answer, stopping for input each time. Spec written to `docs/spine/specs/2026-07-01-react-todo-list-design.md` (correct path). FRAME steps 1-2 (explore + scaffold `.spine/`) ran with no permission prompts.

  

gate_4_config_gate:  PASS | config_md_created_in_frame: yes | gate_a_deny_seen: no | gate_b_deny_seen: no | code_write_allowed_with_both: no | mismatch_flagged_before_task1: yes | observed: During FRAME, config contract was grilled (stack/test-runner/persistence/styling/theme) and `.spine/config.md` written before approval. config.md was then hand-edited to a deliberately-wrong stack (`notejs + React 18 + TypeScript`). On "continue the build", the mismatch was flagged BEFORE any task was dispatched — caught both that `notejs` is not a real stack and that it contradicts the approved Vite design, refused to proceed, and offered restore-vs-reframe. The pure-hook mechanical denies (frame-gate Gate A "FRAME not approved", Gate B "config.md missing", allow-with-both) were NOT exercised — no code write to src/ was attempted, so the hook teeth were not driven. | symptom_if_fail: hook deny mechanics not driven (not a behavior failure — 4b assertion path passed cleanly)

  

notes: The framing skill BODY injected this time — the previously-failing item (gate 3 body injection) is now a clean PASS. `Skill(spine:framing)` resolved to the SKILL (not a command redirect); no redirect loop. No permission prompt fired during FRAME steps 1-2 (plugin-cache template reads and Writes to `.spine/**` and `docs/spine/specs/**` were silent), confirming pre-allow settings. Spec written to `docs/spine/specs/` as expected. Gate 4a mechanical hook teeth (Gate A/B mechanical denies) again not exercised because the build never reached a src/ write — same coverage gap as the 0.1.1 round; would need a forced src/ write with config absent to drive it. Surprising/positive: the 0.1.1 injection bug is gone — the frame→framing rename removed the command shadowing, and the body now loads reliably.

---

**CORRECTION (appended 2026-07-01, post-fix — supersedes the "no permission prompt" claims above):**
The statement that FRAME steps 1–2 fired no permission prompts ("plugin-cache template reads and Writes to `.spine/**` and `docs/spine/specs/**` were silent, confirming pre-allow settings") was INACCURATE as a fresh-install claim. Those writes were silent only because the test machine's global `~/.claude/settings.json` carried `Read/Write/Edit(.spine/**)` allow rules (since removed). A true fresh install has no such rules — **a plugin cannot self-grant write permissions** (confirmed via docs) — so the agent-driven scaffold prompted once per file/read on a clean machine (see `My-observe.md`).
FIX shipped after this run: the `.spine/` skeleton (`context.md`, `danger-paths`, `progress.md`) is now scaffolded inside the `pre-tool-use/frame-gate` hook (hook writes run trusted = no prompt). `config.md` and the spec doc remain agent writes and still prompt once each by design (= Superpowers parity). The `framing`/`config-contract` skills no longer shell `find`/`cp` or read plugin templates. See memory `spine-scaffold-via-hook`.

=== END REPORT ===